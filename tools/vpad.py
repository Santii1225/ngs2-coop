#!/usr/bin/env python3
"""Virtual Xbox 360 pad + keyboard (uinput) driven by a FIFO, for unattended test runs.

  vpad.py daemon            # creates devices, reads commands from FIFO
  vpad.py <cmd> [...]       # sends commands to the running daemon

Commands (one per line):
  tap BTN [ms]      press+release (BTN: A B X Y LB RB BACK START LS RS UP DOWN LEFT RIGHT)
  hold BTN ms
  combo BTN+BTN [ms] several buttons at once
  stick L|R x y ms  x,y in [-1,1] (y=+1 is up), held for ms then centered
  axis L|R x y      set stick and leave it there (axis L 0 0 to center)
  trig L|R v ms
  key NAME [ms]     keyboard key (evdev name without KEY_, e.g. ENTER, ESC, W)
  sleep ms
"""
import os, sys, time

FIFO = os.environ.get('VPAD_FIFO', '/tmp/ngs2coop/vpad.fifo')

def daemon():
    from evdev import UInput, ecodes as e, AbsInfo
    btn = {'A': e.BTN_SOUTH, 'B': e.BTN_EAST, 'X': e.BTN_NORTH, 'Y': e.BTN_WEST,
           'LB': e.BTN_TL, 'RB': e.BTN_TR, 'BACK': e.BTN_SELECT, 'START': e.BTN_START,
           'GUIDE': e.BTN_MODE, 'LS': e.BTN_THUMBL, 'RS': e.BTN_THUMBR}
    stick = AbsInfo(0, -32768, 32767, 16, 128, 0)
    trig = AbsInfo(0, 0, 255, 0, 0, 0)
    hat = AbsInfo(0, -1, 1, 0, 0, 0)
    caps = {e.EV_KEY: list(btn.values()),
            e.EV_ABS: [(e.ABS_X, stick), (e.ABS_Y, stick), (e.ABS_RX, stick), (e.ABS_RY, stick),
                       (e.ABS_Z, trig), (e.ABS_RZ, trig), (e.ABS_HAT0X, hat), (e.ABS_HAT0Y, hat)]}
    ids = {'x360': ('Microsoft X-Box 360 pad', 0x045e, 0x028e, 0x110),
           'xones': ('Microsoft X-Box One S pad', 0x045e, 0x02ea, 0x408)}
    pname, pvid, ppid, pver = ids[os.environ.get('VPAD_ID', 'x360')]
    pad = UInput(caps, name=pname, vendor=pvid, product=ppid, version=pver, bustype=e.BUS_USB)
    kbd = UInput({e.EV_KEY: [v for k, v in e.ecodes.items() if k.startswith('KEY_') and v < 0x100]},
                 name='vpad keyboard')
    hats = {'UP': (e.ABS_HAT0Y, -1), 'DOWN': (e.ABS_HAT0Y, 1), 'LEFT': (e.ABS_HAT0X, -1), 'RIGHT': (e.ABS_HAT0X, 1)}

    def press(name, down):
        if name in hats:
            ax, v = hats[name]
            pad.write(e.EV_ABS, ax, v if down else 0)
        else:
            pad.write(e.EV_KEY, btn[name], 1 if down else 0)
        pad.syn()

    if os.path.exists(FIFO): os.unlink(FIFO)
    os.mkfifo(FIFO)
    print('vpad ready', pad.device.path if hasattr(pad, 'device') else '', flush=True)
    while True:
        with open(FIFO) as f:
            for line in f:
                p = line.split()
                if not p: continue
                try:
                    c = p[0]
                    if c == 'tap':
                        press(p[1], True); time.sleep(int(p[2]) / 1000 if len(p) > 2 else 0.08); press(p[1], False)
                    elif c == 'combo':  # combo A+B [ms]: several buttons at once
                        names = p[1].split('+')
                        for n in names: press(n, True)
                        time.sleep(int(p[2]) / 1000 if len(p) > 2 else 0.15)
                        for n in names: press(n, False)
                    elif c == 'hold':
                        press(p[1], True); time.sleep(int(p[2]) / 1000); press(p[1], False)
                    elif c == 'stick':
                        ax = (e.ABS_X, e.ABS_Y) if p[1] == 'L' else (e.ABS_RX, e.ABS_RY)
                        x, y = float(p[2]), float(p[3])
                        pad.write(e.EV_ABS, ax[0], int(x * 32767)); pad.write(e.EV_ABS, ax[1], int(-y * 32767)); pad.syn()
                        time.sleep(int(p[4]) / 1000)
                        pad.write(e.EV_ABS, ax[0], 0); pad.write(e.EV_ABS, ax[1], 0); pad.syn()
                    elif c == 'axis':
                        ax = (e.ABS_X, e.ABS_Y) if p[1] == 'L' else (e.ABS_RX, e.ABS_RY)
                        pad.write(e.EV_ABS, ax[0], int(float(p[2]) * 32767)); pad.write(e.EV_ABS, ax[1], int(-float(p[3]) * 32767)); pad.syn()
                    elif c == 'trig':
                        ax = e.ABS_Z if p[1] == 'L' else e.ABS_RZ
                        pad.write(e.EV_ABS, ax, int(float(p[2]) * 255)); pad.syn()
                        time.sleep(int(p[3]) / 1000); pad.write(e.EV_ABS, ax, 0); pad.syn()
                    elif c == 'key':
                        k = e.ecodes['KEY_' + p[1].upper()]
                        kbd.write(e.EV_KEY, k, 1); kbd.syn(); time.sleep(int(p[2]) / 1000 if len(p) > 2 else 0.08)
                        kbd.write(e.EV_KEY, k, 0); kbd.syn()
                    elif c == 'sleep':
                        time.sleep(int(p[1]) / 1000)
                    print('ok', line.strip(), flush=True)
                except Exception as ex:
                    print('err', line.strip(), ex, flush=True)

if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == 'daemon':
        daemon()
    else:
        with open(FIFO, 'w') as f:  # noqa
            f.write(' '.join(sys.argv[1:]).replace(';', '\n') + '\n')
