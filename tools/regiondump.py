#!/usr/bin/env python3
"""regiondump.py OUT.pkl -- dump the game's global regions around the player/menu/input state (for story vs team diffs)."""
import sys, os, pickle
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ngs2mem
R = [(0x14211d000, 0x142122000), (0x142fa4000, 0x142fa9000), (0x142150000, 0x142160000), (0x141e30000, 0x141e70000),
     (0x142f78b10, 0x142f78b10 + 0x1240 * 2), (0x142fe5f10, 0x142fe5f10 + 0x16a0 * 2), (0x146ac0000, 0x146ae8000)]
m = ngs2mem.Mem()
pickle.dump({lo: m.read(lo, hi - lo) for lo, hi in R}, open(sys.argv[1], 'wb'))
