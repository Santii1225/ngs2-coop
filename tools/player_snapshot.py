#!/usr/bin/env python3
"""Bounded research capture, NOT a verified Player resolver. Only O_RDONLY/pread.
Run after manual idle/movement confirmation. No attach, writes, or inputs.
"""
import argparse, hashlib, json, os, struct, time
from pathlib import Path
from datetime import datetime

GAME_HASH = 'a66daf011d22dd6fd6676e0b8ccc68e85448d4570bbac635e25adc1f2d06ffef'
CORE_HASH = 'ca2849b56c3543351f8a56556e80424cc42cdd685ac8a962543384f726e1db1d'
LIMIT = 256 * 1024

def capture(pid, output):
    output = Path(output)
    if output.exists(): raise RuntimeError('Refusing to overwrite snapshot')
    proc = Path('/proc') / str(pid)
    maps_text = (proc / 'maps').read_text()
    maps = []
    for line in maps_text.splitlines():
        parts = line.split(maxsplit=5)
        lo, hi = (int(v, 16) for v in parts[0].split('-'))
        maps.append((lo, hi, parts[1], int(parts[2], 16), parts[5] if len(parts)>5 else ''))
    exe = next(m for m in maps if m[3] == 0 and m[4].endswith('/NINJA GAIDEN SIGMA2.exe'))
    core = next(m for m in maps if m[3] == 0 and m[4].endswith('/plugin/core.dll'))
    for m, expected in [(exe,GAME_HASH),(core,CORE_HASH)]:
        if hashlib.sha256(Path(m[4]).read_bytes()).hexdigest() != expected:
            raise RuntimeError('Unexpected binary identity')
    base = exe[0]
    start_stat = (proc/'stat').read_text()
    fd = os.open(proc/'mem', os.O_RDONLY)
    try:
        def readable(addr, size):
            end = addr + size
            for lo, hi, perms, *_ in maps:
                if lo <= addr < hi and 'r' in perms:
                    addr = min(end, hi)
                    if addr == end: return True
            return False
        scout_bytes = 0
        def read(addr, size):
            if not readable(addr, size): raise RuntimeError(f'Unreadable range {addr:#x}+{size:#x}')
            data = os.pread(fd,size,addr)
            if len(data)!=size: raise RuntimeError('Short read')
            return data
        slot = struct.unpack('<Q',read(base+0x18f9518,8))[0]; scout_bytes += 8
        if slot != core[0]+0x16f2: raise RuntimeError('Validated core callback not in slot')
        table=read(base+0x3195300,160*0x30); scout_bytes += len(table)
        ranges=[dict(label='sigma2',address=base+0x1e66d00,size=0x160),
                dict(label='sigma2_global',address=base+0x1e66e60,size=8),
                dict(label='object_table',address=base+0x3195300,size=len(table)),
                dict(label='offset_table',address=base+0x1e38710,size=66*32)]
        objects=[]; groups=set(); addresses=set(); rejected=[]
        for i in range(160):
            rec=table[i*48:(i+1)*48]; pointers=struct.unpack_from('<3Q',rec)
            if not any(pointers): continue
            group=rec[31]
            objects.append(dict(index=i,pointers=[hex(v) for v in pointers],metadata=rec[24:32].hex(),group=group))
            if group < 64: groups.add(group)
            for field,addr in enumerate(pointers):
                if not addr or addr in addresses:continue
                addresses.add(addr)
                if readable(addr,0x1000):
                    ranges.append(dict(label=f'object_{i}_ptr{field}',address=addr,size=0x1000,source=hex(base+0x3195300+i*48+field*8)))
                else:rejected.append(dict(index=i,pointer=hex(addr),reason='not readable for 0x1000'))
        for group in sorted(groups):
            addr=base+0x2f78b10+group*0x1240
            if readable(addr,0x1240):ranges.append(dict(label=f'character_group_{group}',address=addr,size=0x1240))
        sigma=read(base+0x1e66d00,0x160);scout_bytes+=len(sigma)
        addr=struct.unpack_from('<Q',sigma,0x150)[0]
        if addr and readable(addr,0x200):ranges.append(dict(label='sigma2_plus150_target',address=addr,size=0x200,source=hex(base+0x1e66d00+0x150)))
        per_sample=sum(r['size'] for r in ranges)
        if per_sample>LIMIT:raise RuntimeError(f'Budget exceeded: {per_sample}, refine before reading')
        output.mkdir(parents=True)
        info=dict(captured=datetime.now().astimezone().isoformat(),pid=pid,proc_stat=start_stat,module_base=hex(base),core_base=hex(core[0]),slot_target=hex(slot),per_sample_bytes=per_sample,scout_bytes=scout_bytes,objects=objects,rejected=rejected,samples=[],status='CANDIDATE capture; not verified Player',ranges=ranges)
        for sample in range(2):
            entry=dict(time=datetime.now().astimezone().isoformat(),files=[])
            for r in ranges:
                data=read(r['address'],r['size']);name=f'{sample}_{r["label"]}.bin'
                (output/name).write_bytes(data)
                entry['files'].append(dict(file=name,sha256=hashlib.sha256(data).hexdigest()))
            info['samples'].append(entry)
            if sample==0:time.sleep(2)
        end_stat=(proc/'stat').read_text()
        if end_stat.rsplit(')',1)[1].split()[19]!=start_stat.rsplit(')',1)[1].split()[19]:raise RuntimeError('Process changed')
        logs=list(Path(core[4]).parent.glob('ngs2coop-core-*.log'))
        if logs:
            log=max(logs,key=lambda p:p.stat().st_mtime)
            (output/'core.log').write_bytes(log.read_bytes());info['core_log_source']=str(log)
        (output/'mappings.txt').write_text('\n'.join(line for line in maps_text.splitlines() if str(Path(exe[4]).parent) in line)+'\n')
        (output/'snapshot.json').write_text(json.dumps(info,indent=2)+'\n')
        print(json.dumps({k:info[k] for k in ['pid','module_base','core_base','slot_target','per_sample_bytes','scout_bytes']},indent=2))
    finally:os.close(fd)

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('pid',type=int);p.add_argument('output');a=p.parse_args();capture(a.pid,a.output)
