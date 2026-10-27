#!/usr/bin/env python3
"""Read-only PE64 inspection. Outputs JSON; raw xrefs are candidates, not code proof."""
import argparse, datetime, hashlib, json, struct
from pathlib import Path

class PE:
    def __init__(self, path):
        self.path = Path(path)
        self.b = self.path.read_bytes()
        assert self.b[:2] == b'MZ'
        pe = self.u32(60)
        assert self.b[pe:pe+4] == b'PE\0\0'
        self.opt = pe + 24
        assert self.u16(self.opt) == 0x20b, 'PE32+ required'
        self.base = self.u64(self.opt+24)
        self.sections = []
        for i in range(self.u16(pe+6)):
            o = self.opt + self.u16(pe+20) + i*40
            vs, va, rs, rp = struct.unpack_from('<IIII', self.b, o+8)
            self.sections.append(dict(name=self.b[o:o+8].rstrip(b'\0').decode(), rva=va,
                                      virtual_size=vs, raw_size=rs, raw_offset=rp,
                                      virtual_end=va+vs, flags=self.u32(o+36)))
        self.info = dict(path=str(self.path.resolve()), size=len(self.b), sha256=hashlib.sha256(self.b).hexdigest(),
                         timestamp=self.u32(pe+8), timestamp_utc=str(datetime.datetime.fromtimestamp(self.u32(pe+8),datetime.timezone.utc)),
                         machine=hex(self.u16(pe+4)), imagebase=hex(self.base), entry_rva=hex(self.u32(self.opt+16)),
                         size_of_image=hex(self.u32(self.opt+56)), sections=self.sections)
    def u16(self,o): return struct.unpack_from('<H', self.b,o)[0]
    def u32(self,o): return struct.unpack_from('<I', self.b,o)[0]
    def u64(self,o): return struct.unpack_from('<Q', self.b,o)[0]
    def section(self,rva):
        return next((s for s in self.sections if s['rva'] <= rva < s['virtual_end']),None)
    def offset(self,rva):
        for s in self.sections:
            if s['rva'] <= rva < s['rva']+s['raw_size']:
                return s['raw_offset']+rva-s['rva']
        raise ValueError(f'RVA {rva:x} not file backed')
    def directory(self,i): return struct.unpack_from('<II',self.b,self.opt+112+i*8)
    def functions(self):
        r,n = self.directory(3)
        o = self.offset(r)
        return [struct.unpack_from('<III',self.b,o+i) for i in range(0,n-11,12)]
    def relocations(self):
        r,n = self.directory(5)
        if not r: return set()
        o,end = self.offset(r),self.offset(r)+n
        result=set()
        while o+8<=end:
            page,size=struct.unpack_from('<II',self.b,o)
            if size<8 or o+size>end: break
            for q in range(o+8,o+size,2):
                v=self.u16(q)
                if v>>12==10: result.add(page+(v&4095))
            o+=size
        return result

def analyze(path,target):
    p=PE(path); out=p.info
    out['target'] = dict(rva=hex(target),preferred_va=hex(p.base+target),section=p.section(target))
    off=p.offset(target); out['target']['file_offset']=hex(off)
    out['target']['bytes']=p.b[off:off+32].hex(' ')
    fs=p.functions(); matches=[f for f in fs if f[0]<=target<f[1]]
    out['runtime_functions'] = []
    for begin,end,unwind in matches:
        o=p.offset(unwind); v,prolog,count,frame=struct.unpack_from('BBBB',p.b,o)
        out['runtime_functions'].append(dict(begin=hex(begin),end=hex(end),unwind=hex(unwind),version=v&7,flags=v>>3,
            prolog_size=prolog,code_count=count,frame_register=frame&15,frame_offset=frame>>4,
            unwind_bytes=p.b[o:o+4+((count+1)//2)*4+12].hex(' ')))
    targets={target,*(f[0] for f in matches)}; relocs=p.relocations(); refs=[]; raw=[]
    for s in p.sections:
        b=p.b[s['raw_offset']:s['raw_offset']+s['raw_size']]
        for t in targets:
            for kind,needle in [('VA64',struct.pack('<Q',p.base+t)),('RVA32',struct.pack('<I',t))]:
                start=0
                while (j:=b.find(needle,start))>=0:
                    r=s['rva']+j
                    refs.append(dict(kind=kind,source_rva=hex(r),section=s['name'],target=hex(t),dir64_relocation=r in relocs))
                    start=j+1
        if s['flags']&0x20000000:
            for j in range(len(b)-4):
                if b[j] in (0xe8,0xe9):
                    dest=s['rva']+j+5+struct.unpack_from('<i',b,j+1)[0]
                    if dest in targets: raw.append(dict(source=hex(s['rva']+j),target=hex(dest),opcode=hex(b[j])))
    out['pointer_candidates']=refs; out['raw_rel32_candidates_not_validated']=raw
    return out
if __name__=='__main__':
    a=argparse.ArgumentParser(); a.add_argument('exe'); a.add_argument('--rva',type=lambda x:int(x,0),default=0x1462a00)
    args=a.parse_args(); print(json.dumps(analyze(args.exe,args.rva),indent=2))
