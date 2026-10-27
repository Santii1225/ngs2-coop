#!/usr/bin/env python3
"""Lab: keep the AI partner (player 2) bound to controller port 1 / pad slot 1 until killed.
  p2bind.py [seconds]
"""
import ngs2mem as n, time, sys, signal
m = n.Mem()
dur = float(sys.argv[1]) if len(sys.argv) > 1 else 60
stop = False
def on_sig(*_):
    global stop; stop = True
signal.signal(signal.SIGTERM, on_sig); signal.signal(signal.SIGINT, on_sig)
PADMAP = 0x14211e754; PLAYER_ACTOR = 0x14211e760
t0 = time.time(); last = None
try:
    while not stop and time.time() - t0 < dur:
        a = m.read(PLAYER_ACTOR, 2)[1]
        c = m.char(m.group(a))
        m.write(PADMAP + 1, b'\x01')
        m.write(c + n.C_CLASS, b'\x01')
        last = c
        time.sleep(0.02)
finally:
    m.write(PADMAP + 1, b'\x00')
    if last: m.write(last + n.C_CLASS, b'\x04')
    print('p2bind restored', flush=True)
