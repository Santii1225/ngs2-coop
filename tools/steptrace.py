#!/usr/bin/env python3
"""steptrace.py FUNC CHAR OUT [N] [EXTRA_GDB_CONDITION] -- gdb: stop at FUNC when the game's current character pointer ([0x142fa65c8]) is
CHAR, single-step up to N instructions until FUNC returns, write the executed PCs to OUT, detach."""
import sys, os, subprocess, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ngs2mem
func, char, out = int(sys.argv[1], 0), int(sys.argv[2], 0), sys.argv[3]
n = int(sys.argv[4]) if len(sys.argv) > 4 else 20000
extra = (' && ' + sys.argv[5]) if len(sys.argv) > 5 else ''
pid = ngs2mem.pid()
script = f'''set pagination off
set confirm off
handle SIGUSR1 SIGUSR2 nostop noprint pass
attach {pid}
break *{func:#x} if *(long long*)0x142fa65c8 == {char:#x}{extra}
continue
python
import gdb
rsp = int(gdb.parse_and_eval("$rsp")) & 0xffffffffffffffff
ret = int(gdb.parse_and_eval("*(unsigned long long*)$rsp")) & 0xffffffffffffffff
pcs = []
for i in range({n}):
    pc = int(gdb.parse_and_eval("$pc")) & 0xffffffffffffffff
    if pc == ret: break
    pcs.append(pc)
    gdb.execute("stepi", to_string=True)
open("{out}", "w").write("\\n".join("%#x" % p for p in pcs))
end
delete
detach
quit
'''
with tempfile.NamedTemporaryFile('w', suffix='.gdb', delete=False) as f:
    f.write(script)
subprocess.run(['timeout', '-s', 'INT', '240', 'gdb', '-q', '-batch', '-x', f.name], capture_output=True)
os.unlink(f.name)
subprocess.run(['kill', '-CONT', str(pid)])
