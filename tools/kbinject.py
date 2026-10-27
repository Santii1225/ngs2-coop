#!/usr/bin/env python3
"""Test helper: inject key presses into the Logitech keyboard's evdev node (reaches kbpad's grab).
  kbinject.py KEY[,KEY...] ms     e.g.  kbinject.py W 1200   |   kbinject.py W,D 800   |  kbinject.py TAB 100
"""
import os, sys, struct, time
from evdev import InputDevice, list_devices, ecodes as e
dev = next(d for d in map(InputDevice, list_devices()) if 'G515' in d.name and e.KEY_A in d.capabilities().get(e.EV_KEY, []))
fd = os.open(dev.path, os.O_WRONLY)
def ev(t, c, v): os.write(fd, struct.pack('llHHi', 0, 0, t, c, v))
keys = [e.ecodes['KEY_' + k.upper()] for k in sys.argv[1].split(',')]
for k in keys: ev(e.EV_KEY, k, 1)
ev(e.EV_SYN, 0, 0)
time.sleep(int(sys.argv[2]) / 1000 if len(sys.argv) > 2 else 0.1)
for k in keys: ev(e.EV_KEY, k, 0)
ev(e.EV_SYN, 0, 0)
