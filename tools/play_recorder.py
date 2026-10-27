#!/usr/bin/env python3
"""play_recorder.py [OUTDIR] -- records a solo play session, read only, for analysis (play_report.py).
player.csv at 20 Hz: time, screen, paused, position, health, character state / action, pad buttons and left stick.
enemies.csv at 4 Hz: live enemies, their total health, the nearest one's distance and health.
events.log: damage taken, enemies defeated, screen changes, deaths. A screenshot every 20 s (shots/).
Touch OUTDIR/STOP to end."""
import os, sys, time, struct, subprocess
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ngs2mem

D = sys.argv[1] if len(sys.argv) > 1 else time.strftime('/tmp/ngs2coop/play_%Y%m%d_%H%M')
os.makedirs(os.path.join(D, 'shots'), exist_ok=True)
STOP = os.path.join(D, 'STOP')
TOOLS = os.path.dirname(os.path.abspath(__file__))
OBJ = 0x143195300
pf = open(os.path.join(D, 'player.csv'), 'w', buffering=1)
pf.write('t,screen,paused,x,y,z,hp,maxhp,state,action,held,lx,ly\n')
ef = open(os.path.join(D, 'enemies.csv'), 'w', buffering=1)
ef.write('t,alive,total_hp,nearest,nearest_hp\n')
ev = open(os.path.join(D, 'events.log'), 'w')


def log(t, msg):
    ev.write(f'{t:9.2f} {msg}\n')
    ev.flush()


m = ngs2mem.Mem()
t0 = time.time()
last_hp = None
last_screen = None
enemy_hp = {}
next_enemy = 0.0
next_shot = 0.0
while not os.path.exists(STOP):
    t = time.time() - t0
    try:
        screen = m.u8(0x1421544fa)
        paused = m.u8(0x141e3a8c2)
        a0 = m.u8(0x14211e760)
        pos = (0.0, 0.0, 0.0); hp = mx = -1; state = action = -1
        if a0 < 0xa0 and m.u8(OBJ + a0 * 0x30 + 0x1a) == 0 and m.u64(OBJ + a0 * 0x30):
            o = m.u64(OBJ + a0 * 0x30)
            pos = m.f3(o + 0x4b80); hp = m.u16(o + 0x5ab6); mx = m.u16(o + 0x5ab4)
            g = m.u8(OBJ + a0 * 0x30 + 0x1f)
            if g < 0x20:
                c = 0x142f78b10 + g * 0x1240
                state = m.u8(c + 4); action = m.u16(c + 0x12)
        pad = m.read(0x142235880, 0x38)
        held = struct.unpack_from('<I', pad, 0)[0]
        lx, ly = struct.unpack_from('<2f', pad, 0x18)
        pf.write(f'{t:.2f},{screen},{paused},{pos[0]:.2f},{pos[1]:.2f},{pos[2]:.2f},{hp},{mx},{state},{action},{held},{lx:.2f},{ly:.2f}\n')
        if screen != last_screen:
            log(t, f'screen {last_screen} -> {screen}')
            last_screen = screen
        if last_hp is not None and hp >= 0 and last_hp >= 0:
            if hp < last_hp:
                log(t, f'damage {last_hp - hp} (hp {hp}/{mx})')
                if hp == 0:
                    log(t, 'player down')
            elif hp > last_hp:
                log(t, f'heal {hp - last_hp} (hp {hp}/{mx})')
        last_hp = hp
        if t >= next_enemy:
            next_enemy = t + 0.25
            alive = 0; total = 0; nearest = 1e9; nearest_hp = -1; seen = set()
            for i in range(160):
                if i == a0:
                    continue
                e = OBJ + i * 0x30
                p = m.u64(e)
                if not p or m.u8(e + 0x1a) != 0:
                    continue
                emx = m.u16(p + 0x5ab4)
                if emx == 0 or emx > 60000:
                    continue
                ehp = m.u16(p + 0x5ab6)
                key = (i, emx)
                seen.add(key)
                prev = enemy_hp.get(key)
                if prev is not None and prev > 0 and ehp == 0:
                    log(t, f'enemy {i} defeated (max {emx})')
                enemy_hp[key] = ehp
                if ehp > 0:
                    alive += 1; total += ehp
                    q = m.f3(p + 0x4b80)
                    d = ((q[0] - pos[0]) ** 2 + (q[2] - pos[2]) ** 2) ** 0.5
                    if d < nearest:
                        nearest, nearest_hp = d, ehp
            for k in list(enemy_hp):
                if k not in seen:
                    del enemy_hp[k]
            ef.write(f'{t:.2f},{alive},{total},{nearest if nearest < 1e9 else -1:.2f},{nearest_hp}\n')
        if t >= next_shot:
            next_shot = t + 20
            subprocess.Popen([TOOLS + '/shot.sh', os.path.join(D, 'shots', f'{int(t):05d}.png')],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except (OSError, struct.error):
        time.sleep(1)  # game closed or restarting
        try:
            m = ngs2mem.Mem()
        except Exception:
            pass
    time.sleep(0.05)
log(time.time() - t0, 'stop')
