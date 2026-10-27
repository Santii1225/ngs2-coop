#!/usr/bin/env python3
"""Keyboard -> virtual Xbox 360 pad (player 2 for local testing).

Grabs the keyboard exclusively (its keys stop reaching the desktop/game) and drives a
virtual pad. Start it BEFORE the game: controllers hot-plugged later are not detected.

  kbpad.py [keyboard-name-substring]     (default: "G515")

  WASD           left stick (movement)      arrows      right stick (camera)
  Space  = A (jump)      J = X (attack)     K = Y (strong attack)   L = B (projectile)
  U = LB   O = RB   Q = LT   E = RT   1/2/3/4 = d-pad up/down/left/right
  Tab = BACK (join/leave as player 2)   Enter = START   LeftShift = LS   RightShift = RS
  ScrollLock / Pause = release/re-grab keyboard     Ctrl+Esc = quit
"""
import sys, select
from evdev import InputDevice, UInput, ecodes as e, AbsInfo, list_devices

name = sys.argv[1] if len(sys.argv) > 1 else 'G515'
kbds = [d for d in map(InputDevice, list_devices())
        if name.lower() in d.name.lower() and e.KEY_A in d.capabilities().get(e.EV_KEY, [])]
if not kbds:
    sys.exit(f'no keyboard matching "{name}"')

BTN = {e.KEY_SPACE: e.BTN_SOUTH, e.KEY_L: e.BTN_EAST, e.KEY_J: e.BTN_NORTH, e.KEY_K: e.BTN_WEST,
       e.KEY_U: e.BTN_TL, e.KEY_O: e.BTN_TR, e.KEY_TAB: e.BTN_SELECT, e.KEY_ENTER: e.BTN_START,
       e.KEY_LEFTSHIFT: e.BTN_THUMBL, e.KEY_RIGHTSHIFT: e.BTN_THUMBR}
TRIG = {e.KEY_Q: e.ABS_Z, e.KEY_E: e.ABS_RZ}
HAT = {e.KEY_1: (e.ABS_HAT0Y, -1), e.KEY_2: (e.ABS_HAT0Y, 1), e.KEY_3: (e.ABS_HAT0X, -1), e.KEY_4: (e.ABS_HAT0X, 1)}
LSTICK = {e.KEY_W: (0, -1), e.KEY_S: (0, 1), e.KEY_A: (-1, 0), e.KEY_D: (1, 0)}
RSTICK = {e.KEY_UP: (0, -1), e.KEY_DOWN: (0, 1), e.KEY_LEFT: (-1, 0), e.KEY_RIGHT: (1, 0)}

stick = AbsInfo(0, -32768, 32767, 16, 128, 0)
caps = {e.EV_KEY: list(set(BTN.values()) | {e.BTN_MODE}),
        e.EV_ABS: [(e.ABS_X, stick), (e.ABS_Y, stick), (e.ABS_RX, stick), (e.ABS_RY, stick),
                   (e.ABS_Z, AbsInfo(0, 0, 255, 0, 0, 0)), (e.ABS_RZ, AbsInfo(0, 0, 255, 0, 0, 0)),
                   (e.ABS_HAT0X, AbsInfo(0, -1, 1, 0, 0, 0)), (e.ABS_HAT0Y, AbsInfo(0, -1, 1, 0, 0, 0))]}
import os
# Identity of the virtual pad. Steam Input orders XInput slots by device type; an Xbox 360
# identity lands BEFORE a real Xbox One/Elite pad (slot 0 = player 1 in menus).
IDS = {'x360': ('Microsoft X-Box 360 pad', 0x028e), 'xones': ('Microsoft X-Box One S pad', 0x02ea)}
pad_name, pad_pid = IDS[os.environ.get('KBPAD_ID', 'xones')]
pad = UInput(caps, name=pad_name, vendor=0x045e, product=pad_pid, version=0x408, bustype=e.BUS_USB)

held = set()
grabbed = False


def grab(on):
    global grabbed
    for k in kbds:
        try:
            k.grab() if on else k.ungrab()
        except OSError:
            pass
    grabbed = on
    print('keyboard', 'CAPTURED (acts as player-2 pad)' if on else 'RELEASED (normal typing)', flush=True)


def stick_axes(table, ax, ay):
    x = sum(v[0] for k, v in table.items() if k in held)
    y = sum(v[1] for k, v in table.items() if k in held)
    n = (x * x + y * y) ** 0.5 or 1
    pad.write(e.EV_ABS, ax, int(32767 * x / n)); pad.write(e.EV_ABS, ay, int(32767 * y / n))


print(f'virtual pad ready; keyboard: {", ".join(k.path + " " + k.name for k in kbds)}', flush=True)
grab(True)
fds = {k.fd: k for k in kbds}
try:
    while True:
        r, _, _ = select.select(fds, [], [])
        for fd in r:
            for ev in fds[fd].read():
                if ev.type != e.EV_KEY or ev.value == 2:
                    continue
                down = ev.value == 1
                (held.add if down else held.discard)(ev.code)
                if down and ev.code == e.KEY_ESC and ({e.KEY_LEFTCTRL, e.KEY_RIGHTCTRL} & held):
                    raise KeyboardInterrupt
                if down and ev.code in (e.KEY_SCROLLLOCK, e.KEY_PAUSE):
                    grab(not grabbed); continue
                if not grabbed:
                    continue
                if ev.code in BTN:
                    pad.write(e.EV_KEY, BTN[ev.code], int(down))
                elif ev.code in TRIG:
                    pad.write(e.EV_ABS, TRIG[ev.code], 255 if down else 0)
                elif ev.code in HAT:
                    ax, v = HAT[ev.code]; pad.write(e.EV_ABS, ax, v if down else 0)
                elif ev.code in LSTICK:
                    stick_axes(LSTICK, e.ABS_X, e.ABS_Y)
                elif ev.code in RSTICK:
                    stick_axes(RSTICK, e.ABS_RX, e.ABS_RY)
                else:
                    continue
                pad.syn()
except KeyboardInterrupt:
    pass
finally:
    grab(False)
    pad.close()
    print('kbpad stopped', flush=True)
