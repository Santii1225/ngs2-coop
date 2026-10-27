#!/usr/bin/env python3
"""Phase 11 - read-only dump of the runtime-initialized executable sections.

The Sigma2 EXE on disk is SteamDRM-protected: its .text bytes on disk are
ciphertext (see docs/RUNTIME_ANALYSIS.md "Disco frente a memoria"). To analyse
the real instructions we must copy the section out of the live process AFTER the
DRM stub has decrypted it in place.

This tool:
  - validates exactly one "NINJA GAIDEN SI" process, TracerPid 0,
    EXE + plugin/core.dll sha256, and the Sigma2 hook-slot continuity gate;
  - for each requested PE section (default: .text and .bind), walks the r-xp
    mappings that intersect the section's VA range, preads each, and assembles a
    flat image the size of the section's VirtualSize, zero-filling unmapped
    holes and recording exactly which byte ranges are real;
  - writes the images plus a manifest with runtime base, RVA range, virtual
    size, per-mapping permissions, PE timestamp and SHA256 of every artifact.

STRICTLY READ-ONLY: open(/proc/<pid>/mem, O_RDONLY) + os.pread only. No writes,
no ptrace/attach, no input injection. Nothing about the game is modified.
"""
import argparse
import hashlib
import json
import os
import struct
import sys
from datetime import datetime, timezone
from pathlib import Path

GAME_HASH = 'a66daf011d22dd6fd6676e0b8ccc68e85448d4570bbac635e25adc1f2d06ffef'
CORE_HASH = 'ca2849b56c3543351f8a56556e80424cc42cdd685ac8a962543384f726e1db1d'
SLOT_RVA = 0x18F9518
CORE_CALLBACK_OFF = 0x16F2

# PE section table of this exact build (llvm-readobj, verified on disk EXE).
SECTIONS = {
    '.text': dict(rva=0x1000,     vsize=0x179C2E0),
    '.bind': dict(rva=0x7294000,  vsize=0x39098),
    '.rdata': dict(rva=0x179E000, vsize=0x4AC47A),
    '.pdata': dict(rva=0x6E94000, vsize=0x133248),
}
PE_TIMESTAMP = 0x60E6C259  # 2021-07-08 09:16:09 UTC


def find_pids():
    hits = []
    for e in Path('/proc').iterdir():
        if e.name.isdigit():
            try:
                if (e / 'comm').read_text().strip() == 'NINJA GAIDEN SI':
                    hits.append(int(e.name))
            except OSError:
                pass
    return hits


def parse_maps(pid):
    maps = []
    for line in Path(f'/proc/{pid}/maps').read_text().splitlines():
        parts = line.split(maxsplit=5)
        lo, hi = (int(v, 16) for v in parts[0].split('-'))
        maps.append(dict(lo=lo, hi=hi, perms=parts[1],
                         off=int(parts[2], 16),
                         path=parts[5] if len(parts) > 5 else ''))
    return maps


def sha(b):
    return hashlib.sha256(b).hexdigest()


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--out-dir', required=True, help='directory to create for the dump')
    ap.add_argument('--sections', nargs='+', default=['.text', '.bind'],
                    choices=sorted(SECTIONS), help='PE sections to dump')
    ap.add_argument('--pid', type=int, help='override PID (still validated)')
    a = ap.parse_args()

    pids = [a.pid] if a.pid else find_pids()
    if len(pids) != 1:
        print(f'ERROR: need exactly one game PID, found {pids}', file=sys.stderr)
        return 1
    pid = pids[0]

    st = Path(f'/proc/{pid}/status').read_text()
    tracer = next(l.split()[1] for l in st.splitlines() if l.startswith('TracerPid:'))
    if tracer != '0':
        print(f'ERROR: TracerPid={tracer} (a debugger is attached)', file=sys.stderr)
        return 1
    starttime = Path(f'/proc/{pid}/stat').read_text().split()[21]

    maps = parse_maps(pid)
    exe = next((m for m in maps if m['off'] == 0 and
                m['path'].endswith('/NINJA GAIDEN SIGMA2.exe')), None)
    core = next((m for m in maps if m['off'] == 0 and
                 m['path'].endswith('/plugin/core.dll')), None)
    if not exe or not core:
        print('ERROR: EXE or core.dll mapping not found', file=sys.stderr)
        return 1
    if sha(Path(exe['path']).read_bytes()) != GAME_HASH:
        print('ERROR: EXE sha256 mismatch', file=sys.stderr)
        return 1
    if sha(Path(core['path']).read_bytes()) != CORE_HASH:
        print('ERROR: core.dll sha256 mismatch', file=sys.stderr)
        return 1
    base = exe['lo']
    core_base = core['lo']

    fd = os.open(f'/proc/{pid}/mem', os.O_RDONLY)
    try:
        slot = struct.unpack('<Q', os.pread(fd, 8, base + SLOT_RVA))[0]
        if slot != core_base + CORE_CALLBACK_OFF:
            print(f'ERROR: Sigma2 hook slot mismatch: {slot:#x} != '
                  f'{core_base + CORE_CALLBACK_OFF:#x}', file=sys.stderr)
            return 1

        out = Path(a.out_dir)
        out.mkdir(parents=True, exist_ok=False)

        manifest = dict(
            tool='runtime_text_dump',
            captured=datetime.now(timezone.utc).astimezone().isoformat(),
            pid=pid, process_starttime=starttime,
            module_base=hex(base), core_base=hex(core_base),
            exe_path=exe['path'], core_path=core['path'],
            exe_sha256=GAME_HASH, core_sha256=CORE_HASH,
            hook_slot_rva=hex(SLOT_RVA), hook_slot_value=hex(slot),
            hook_slot_expected=hex(core_base + CORE_CALLBACK_OFF),
            pe_timestamp=PE_TIMESTAMP,
            pe_timestamp_utc=datetime.fromtimestamp(PE_TIMESTAMP, timezone.utc).isoformat(),
            sections=[],
        )

        for name in a.sections:
            sec = SECTIONS[name]
            sec_va = base + sec['rva']
            sec_end = sec_va + sec['vsize']
            buf = bytearray(sec['vsize'])
            covered = bytearray(sec['vsize'])  # 1 where real bytes were read
            segs = []
            for m in maps:
                if m['hi'] <= sec_va or m['lo'] >= sec_end or 'r' not in m['perms']:
                    continue
                lo = max(m['lo'], sec_va)
                hi = min(m['hi'], sec_end)
                data = os.pread(fd, hi - lo, lo)
                if len(data) != hi - lo:
                    raise RuntimeError(f'short read {lo:#x}+{hi - lo:#x}')
                o = lo - sec_va
                buf[o:o + len(data)] = data
                covered[o:o + len(data)] = b'\x01' * len(data)
                segs.append(dict(va_lo=hex(lo), va_hi=hex(hi),
                                 rva_lo=hex(lo - base), rva_hi=hex(hi - base),
                                 size=hi - lo, perms=m['perms'],
                                 sha256=sha(data)))
            # holes = maximal runs of covered==0
            holes = []
            i = 0
            while i < len(covered):
                if covered[i] == 0:
                    j = i
                    while j < len(covered) and covered[j] == 0:
                        j += 1
                    holes.append(dict(rva_lo=hex(base + sec['rva'] + i - base),
                                      rva_hi=hex(base + sec['rva'] + j - base),
                                      size=j - i))
                    i = j
                else:
                    i += 1
            real_bytes = sum(covered)
            fn = out / f'{name.strip(".")}_{sec["rva"]:#08x}_{sec["vsize"]:#x}.bin'
            fn.write_bytes(bytes(buf))
            manifest['sections'].append(dict(
                name=name, rva=hex(sec['rva']), virtual_size=hex(sec['vsize']),
                runtime_va_lo=hex(sec_va), runtime_va_hi=hex(sec_end),
                file=fn.name, file_sha256=sha(bytes(buf)),
                real_bytes=real_bytes, hole_bytes=sec['vsize'] - real_bytes,
                segments=segs, holes=holes))
            print(f'{name}: {real_bytes:#x}/{sec["vsize"]:#x} bytes real, '
                  f'{len(segs)} segs, {len(holes)} holes -> {fn.name}')

        (out / 'dump_manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
        print(f'manifest -> {out / "dump_manifest.json"}')
    finally:
        os.close(fd)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
