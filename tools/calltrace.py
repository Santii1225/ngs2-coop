#!/usr/bin/env python3
"""calltrace.py FUNC CHAR SECONDS OUT -- gdb: log every call of FUNC made while the current character
([0x142fa65c8]) is CHAR: caller, rcx, edx, r8d and the returned eax (via a temporary breakpoint at the return
address). Breakpoints never stop the game for long (Python stop() returns False)."""
import sys, os, subprocess, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ngs2mem
func, char, secs, out = int(sys.argv[1], 0), int(sys.argv[2], 0), int(sys.argv[3]), sys.argv[4]
pid = ngs2mem.pid()
script = f'''set pagination off
set confirm off
handle SIGUSR1 SIGUSR2 nostop noprint pass
attach {pid}
python
import gdb
log = open("{out}", "w")
def u(e): return int(gdb.parse_and_eval(e)) & 0xffffffffffffffff
class Ret(gdb.Breakpoint):
    def __init__(self, addr, info):
        super().__init__("*%#x" % addr, internal=True, temporary=True)
        self.info = info
    def stop(self):
        log.write("%s -> %#x\\n" % (self.info, u("$rax") & 0xffffffff)); return False
class Entry(gdb.Breakpoint):
    def stop(self):
        if u("*(unsigned long long*)0x142fa65c8") != {char:#x}: return False
        ret = u("*(unsigned long long*)$rsp")
        Ret(ret, "from %#x rcx=%#x edx=%#x r8=%#x" % (ret, u("$rcx"), u("$rdx") & 0xffffffff, u("$r8") & 0xffffffff))
        return False
Entry("*{func:#x}", internal=True)
end
shell sleep 0
'''
script += f'''python
import threading, time
def stopper():
    time.sleep({secs}); gdb.post_event(lambda: gdb.execute("interrupt"))
threading.Thread(target=stopper, daemon=True).start()
end
continue
python
log.close()
end
detach
quit
'''
with tempfile.NamedTemporaryFile('w', suffix='.gdb', delete=False) as f:
    f.write(script)
subprocess.run(['timeout', '-s', 'INT', str(secs + 90), 'gdb', '-q', '-batch', '-x', f.name], capture_output=True)
os.unlink(f.name)
subprocess.run(['kill', '-CONT', str(pid)])
