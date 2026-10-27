#!/usr/bin/env python3
"""Read only the EXE .text once to find direct branches and common RIP LEA/MOV.
No attach, writes, breakpoints, heap scan or memory dump. Raw hits need disassembly.
"""
import argparse,os,re,struct,json
from analyze_hook_pe import PE
p=argparse.ArgumentParser();p.add_argument('pid',type=int);p.add_argument('exe');p.add_argument('base',type=lambda s:int(s,0));a=p.parse_args()
pe=PE(a.exe);s=next(s for s in pe.sections if s['name']=='.text')
fd=os.open(f'/proc/{a.pid}/mem',os.O_RDONLY)
targets={a.base+0x1462a00,a.base+0x18f9518};hits=[];total=0
try:
 for start in range(0,s['virtual_size'],65536):
  size=min(65536+16,s['virtual_size']-start);b=os.pread(fd,size,a.base+s['rva']+start);total+=len(b)
  if len(b)!=size:raise OSError('short read')
  va=a.base+s['rva']+start
  for m in re.finditer(b'[\xe8\xe9]',b):
   j=m.start()
   if j>=65536 or j+5>len(b):continue
   t=va+j+5+struct.unpack_from('<i',b,j+1)[0]
   if t in targets:hits.append(dict(kind='raw rel32',source=hex(va+j),target=hex(t)))
  for m in re.finditer(b'[\x48\x4c][\x8d\x8b][\x05\x0d\x15\x1d\x25\x2d\x35\x3d]',b):
   j=m.start()
   if j>=65536 or j+7>len(b):continue
   t=va+j+7+struct.unpack_from('<i',b,j+3)[0]
   if t in targets:hits.append(dict(kind='raw RIP LEA/MOV',source=hex(va+j),target=hex(t)))
finally:os.close(fd)
print(json.dumps(dict(pid=a.pid,base=hex(a.base),bytes_read=total,scope='.text only; 64KiB blocks plus 16-byte overlap; hits not yet decoded',hits=hits),indent=2))
