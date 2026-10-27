#!/usr/bin/env python3
"""Minimal /proc/<pid>/mem helpers for NGS2 lab sessions (offsets: docs/OFFSETS.md, STATUS.md)."""
import os, struct, subprocess

BASE = 0x140000000            # image base (no ASLR observed)
TABLE_RVA = 0x3195300         # game_object table, 160 x 0x30
TABLE_STRIDE = 0x30
OBJ_PTR_OFF = 0x00
GROUP_OFF = 0x1F
CHAR_TABLE_RVA = 0x2F78B10    # character[group], stride 0x1240
CHAR_STRIDE = 0x1240

# object offsets
O_POS_OBS = 0x2B0
O_CANON = 0x4B80
O_RAW = 0x4B90
O_VEL = 0x4BC0
O_CMD = 0x5000
O_CMD_EN = 0x5B56
# character offsets
C_CLASS = 0x00   # 0x00 local input / 0x04 AI
C_STATE = 0x04
C_LOCK = 0x0C
C_ACTION = 0x12
C_DIR = 0x30
C_ROT = 0x80
C_POS = 0x310


def pid():
    out = subprocess.run(['ps', '-eo', 'pid,comm'], capture_output=True, text=True).stdout
    for l in out.splitlines():
        if 'NINJA GAIDEN' in l:
            return int(l.split()[0])
    raise SystemExit('game not running')


class Mem:
    def __init__(self, p=None):
        self.pid = p or pid()
        self.fd = os.open(f'/proc/{self.pid}/mem', os.O_RDWR)

    def read(self, a, n):
        return os.pread(self.fd, n, a)

    def write(self, a, b):
        return os.pwrite(self.fd, b, a)

    def u8(self, a): return self.read(a, 1)[0]
    def u16(self, a): return struct.unpack('<H', self.read(a, 2))[0]
    def u32(self, a): return struct.unpack('<I', self.read(a, 4))[0]
    def u64(self, a): return struct.unpack('<Q', self.read(a, 8))[0]
    def f4(self, a): return struct.unpack('<4f', self.read(a, 16))
    def f3(self, a): return struct.unpack('<3f', self.read(a, 12))

    def entry(self, i):
        return BASE + TABLE_RVA + i * TABLE_STRIDE

    def obj(self, i):
        return self.u64(self.entry(i) + OBJ_PTR_OFF)

    def group(self, i):
        return self.u8(self.entry(i) + GROUP_OFF)

    def player_actor(self, player):
        """game_object index of player 0/1 (byte table at 0x14211e760; Team Mission partner = player 1)."""
        return self.read(0x14211e760 + player, 1)[0]

    def char(self, g):
        return BASE + CHAR_TABLE_RVA + g * CHAR_STRIDE

    def actor(self, i):
        o = self.obj(i); g = self.group(i); c = self.char(g)
        return o, g, c

    def summary(self, i):
        o, g, c = self.actor(i)
        return (f'[{i}] obj={o:#x} grp={g} class={self.u8(c+C_CLASS):#04x} state={self.u8(c+C_STATE):#04x} '
                f'lock={self.u8(c+C_LOCK):#04x} act={self.u8(c+C_ACTION):#04x}/{self.u8(c+C_ACTION+1):#04x} '
                f'canon=({",".join(f"{v:.2f}" for v in self.f3(o+O_CANON))}) raw={tuple(round(v,3) for v in self.f4(o+O_RAW))} '
                f'en={self.u8(o+O_CMD_EN)}')


if __name__ == '__main__':
    m = Mem()
    for p in (0, 1):
        print('P%d' % (p + 1), m.summary(m.player_actor(p)))
