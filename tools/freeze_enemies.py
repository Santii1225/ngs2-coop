#!/usr/bin/env python3
"""Lab helper: disconnect enemy AI by binding every non-player actor to an empty controller port.

character[group]+0x00 is the controller port the actor reads (0..3); 4 = no port -> AI brain.
Binding enemies to port 3 (no pad connected) leaves them idle. Restores on SIGTERM/SIGINT/timeout.
  freeze_enemies.py [seconds] [port]
"""
import ngs2mem as n, time, sys, signal

m = n.Mem()
dur = float(sys.argv[1]) if len(sys.argv) > 1 else 30
port = int(sys.argv[2]) if len(sys.argv) > 2 else 3
saved = {}
stop = False


def on_sig(*_):
    global stop
    stop = True


signal.signal(signal.SIGTERM, on_sig)
signal.signal(signal.SIGINT, on_sig)
t0 = time.time()
try:
    while not stop and time.time() - t0 < dur:
        players = set(m.read(0x14211e760, 2))
        pgroups = {m.group(i) for i in players}
        for i in range(0xA0):
            if i in players or m.obj(i) == 0:
                continue
            g = m.group(i)
            if g >= 0x20 or g in pgroups:
                continue
            c = m.char(g)
            if g not in saved:
                saved[g] = m.u8(c + n.C_CLASS)
            m.write(c + n.C_CLASS, bytes([port]))
        time.sleep(0.02)
finally:
    for g, v in saved.items():
        m.write(m.char(g) + n.C_CLASS, bytes([v]))
    print('groups bound to port', port, 'then restored:', sorted(saved), flush=True)
