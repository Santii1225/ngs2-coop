#!/usr/bin/env python3
"""mission_sweep.py OUTDIR [first last] -- play every Team Mission briefly with two players (virtual pads).
Start on the mission select (Normal) with player 2 joined (split_test.sh missions). For each mission: both
players move to the cell and lock it, both confirm the character screen, then the mission runs ~35 s with
both players walking and attacking; the result (players, partner port, split screen, camera stats, enemies,
crash) goes to OUTDIR/sweep.tsv with a screenshot, and the pause menu leads back to the mission select."""
import os, sys, time, subprocess, struct
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ngs2mem

T = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
GD = os.path.expanduser('~/.local/share/Steam/steamapps/common/[NINJA GAIDEN Master Collection] NINJA GAIDEN Σ２/plugin')
PAGES = [(0, 2), (1, 2), (2, 1), (3, 1)]  # page, rows (5 per row)
MISSIONS = [(p, c, r) for p, rows in PAGES for r in range(rows) for c in range(5)]
first, last = (int(sys.argv[2]), int(sys.argv[3])) if len(sys.argv) > 3 else (0, len(MISSIONS) - 1)
NAMES = ['Acólito', 'Guerrero', 'Mentor', 'Maestro Ninja']


def pad(who, *cmd, wait=0.35):
    subprocess.run([T + '/pad.sh', who, *cmd])
    time.sleep(wait)


def mem():
    return ngs2mem.Mem()


def screen(m):
    return m.u8(0x1421544fa)


def log_size():
    return os.path.getsize(os.path.join(GD, 'ngs2coop.log'))


def log_tail(pos):
    with open(os.path.join(GD, 'ngs2coop.log'), 'rb') as f:
        f.seek(pos)
        return [l.decode(errors='replace').rstrip() for l in f]


def enemies(m):
    alive = 0
    a0, a1 = m.u8(0x14211e760), m.u8(0x14211e761)
    for i in range(160):
        e = 0x143195300 + i * 0x30
        o = m.u64(e)
        if not o or i in (a0, a1) or m.u8(e + 0x1a): continue
        try:
            mx, hp = m.u16(o + 0x5ab4), m.u16(o + 0x5ab6)
        except OSError:
            continue
        if 0 < mx < 60000 and hp > 0: alive += 1
    return alive


def go_to(m, page, col, row):
    """Move the game's cursor and player 2's marker to the cell (both start where the game's cursor is)."""
    for _ in range(8):
        cp = m.u8(0x14215b810) % 4
        if cp == page: break
        pad('p1', 'tap', 'RB', wait=0.15); pad('p2', 'tap', 'RB', wait=0.9)
    for _ in range(12):
        cc, cr = m.u8(0x141e654c0), m.u8(0x141e654c4)
        if (cc, cr) == (col, row): break
        k = 'RIGHT' if cc < col else 'LEFT' if cc > col else 'DOWN' if cr < row else 'UP'
        pad('p1', 'tap', k, wait=0.15); pad('p2', 'tap', k, wait=0.45)
    return (m.u8(0x14215b810) % 4, m.u8(0x141e654c0), m.u8(0x141e654c4)) == (page, col, row)


def back_to_missions(m):
    for attempt in range(3):
        if screen(m) == 6: return True
        if screen(m) == 74:
            pad('p1', 'tap', 'START', wait=2.5)
            pad('p1', 'tap', 'DOWN', '150', wait=1.0); pad('p1', 'tap', 'DOWN', '150', wait=1.0)
            pad('p1', 'tap', 'A', '150', wait=3.0)
            if screen(m) != 6: pad('p1', 'tap', 'A', wait=1.5)  # possible confirmation
        else:
            pad('p1', 'tap', 'A', wait=1.5)
        for _ in range(20):
            if screen(m) == 6: return True
            time.sleep(0.5)
    return screen(m) == 6


res = open(os.path.join(OUT, 'sweep.tsv'), 'a')
res.write('n\tmission\tstarted\tplayers\tport\tsplit\tcam_untagged\tcam_repeat\tenemies_seen\tnotes\n')
m = mem()
for n in range(first, last + 1):
    page, col, row = MISSIONS[n]
    name = f'{NAMES[page]} {row * 5 + col + 1:02d}'
    notes = []
    try:
        if os.path.exists('/proc/%d' % m.pid) is False: m = mem()
        if screen(m) != 6 and not back_to_missions(m):
            notes.append('not on mission select'); raise RuntimeError
        if not go_to(m, page, col, row):
            notes.append('cursor did not reach'); raise RuntimeError
        since = log_size()
        pad('p2', 'tap', 'A', wait=0.6); pad('p1', 'tap', 'A', wait=3.5)
        if screen(m) != 5:
            notes.append(f'no character screen (screen {screen(m)}): locked?')
            res.write(f'{n}\t{name}\tno\t\t\t\t\t\t\t{"; ".join(notes)}\n'); res.flush()
            if screen(m) != 6: back_to_missions(m)
            continue
        pad('p1', 'tap', 'A', wait=0.6); pad('p2', 'tap', 'A', wait=1.0)
        t0 = time.time(); started = False
        while time.time() - t0 < 40:
            if m.u8(0x14211e5cc) >= 2 and screen(m) == 74: started = True; break
            time.sleep(0.5)
        seen = 0; players = port = 0
        if started:
            time.sleep(3)
            for k in range(6):
                pad('p1', 'stick', 'L', '0.6', '1', '1500', wait=0.1)
                pad('p2', 'stick', 'L', '-0.6', '1', '1500', wait=0.1)
                pad('p1', 'tap', 'X', wait=0.1); pad('p2', 'tap', 'X', wait=0.3)
                seen = max(seen, enemies(m))
            players = m.u8(0x14211e5cc)
            a1 = m.u8(0x14211e761)
            port = m.u8(m.char(m.group(a1))) if a1 < 0xa0 else -1
            subprocess.run([T + '/shot.sh', os.path.join(OUT, f'{n:02d}.png')], capture_output=True)
        lines = log_tail(since)
        split = any('split: on' in l for l in lines)
        offs = sum('split: off' in l for l in lines)
        if offs > 1: notes.append(f'split turned off {offs} times')
        stats = [l for l in lines if 'eye disagreed' in l and '(60.0 fps)' in l or 'eye disagreed' in l and 'fps)' in l]
        unt = rep = ''
        if stats:
            import re
            u = [int(re.search(r'(\d+) untagged', l)[1]) for l in stats]
            r = [int(re.search(r'(\d+) same view', l)[1]) for l in stats]
            unt, rep = max(u), max(r)
        for l in lines:
            if any(w in l for w in ('unexpected', 'failed', 'did not reach', 'error')):
                notes.append(l[13:90])
        res.write(f'{n}\t{name}\t{"yes" if started else "no"}\t{players}\t{port}\t{split}\t{unt}\t{rep}\t{seen}\t{"; ".join(notes)[:300]}\n')
        res.flush()
        back_to_missions(m)
    except RuntimeError:
        res.write(f'{n}\t{name}\terror\t\t\t\t\t\t\t{"; ".join(notes)}\n'); res.flush()
        back_to_missions(m)
    except Exception as ex:
        res.write(f'{n}\t{name}\texception\t\t\t\t\t\t\t{ex!r}\n'); res.flush()
        time.sleep(3)
        try: m = mem()
        except SystemExit: break
print('done')
