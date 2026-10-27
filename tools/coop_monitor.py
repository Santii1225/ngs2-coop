#!/usr/bin/env python3
"""coop_monitor.py [OUTDIR] -- real co-op test monitor (read only): game state and enemies every second
(state.csv, events.log), system load every 5 s (system.csv), a screenshot every 30 s (shots/).
Stall detector: in a mission, unpaused, 12 s without live enemies -> snapshot of the object table and of
every dead-but-active enemy (snaps/*.json + .png). Touch OUTDIR/SNAP for a manual snapshot, OUTDIR/STOP to end.
"""
import os, sys, time, struct, subprocess, json, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ngs2mem
D = sys.argv[1] if len(sys.argv) > 1 else '/tmp/ngs2coop/coop_monitor'
os.makedirs(os.path.join(D, 'shots'), exist_ok=True); os.makedirs(os.path.join(D, 'snaps'), exist_ok=True)
STOP = os.path.join(D, 'STOP')
TOOLS = os.path.dirname(os.path.abspath(__file__))
state = open(os.path.join(D, 'state.csv'), 'a')
sysf = open(os.path.join(D, 'system.csv'), 'a')
events = open(os.path.join(D, 'events.log'), 'a')
state.write('time,pid,players,view,paused,menu,p1_actor,p2_actor,p2_padmap,partner_port,hp1,max1,hp2,max2,gauge2_state,karma,objs,enemies_alive,enemy_types\n')
objf = open(os.path.join(D, 'objects.log'), 'a')
stall_since = None; last_alive = None; snap_n = 0

def table(m, a0, a1):
    rows = []
    for i in range(160):
        e = 0x143195300 + i * 0x30
        ptr = m.u64(e)
        if not ptr: continue
        typ = m.u16(e + 0x18); flag = m.u8(e + 0x1a); par = m.u8(e + 0x1e); grp = m.u8(e + 0x1f)
        hp = mx = -1; pos = (0, 0, 0)
        try:
            hp = m.u16(ptr + 0x5ab6); mx = m.u16(ptr + 0x5ab4); pos = m.f3(ptr + 0x4b80)
        except Exception: pass
        port = state_c = -1
        if grp < 0x20:
            c = m.char(grp); port = m.u8(c); state_c = m.u8(c + 4)
        rows.append(dict(i=i, type=typ, flag=flag, parent=par, group=grp, hp=hp, max=mx, pos=pos, port=port, cstate=state_c, player=i in (a0, a1)))
    return rows

def stuck_detail(m, rows):
    # dead (hp 0) enemies whose entry is still active: sample their internals 10 times over 5 s
    out = []
    targets = [r for r in rows if not r['player'] and r['flag'] == 0 and r['max'] > 0 and r['hp'] == 0]
    for k in range(10):
        for r in targets:
            try:
                e = 0x143195300 + r['i'] * 0x30; o = m.u64(e); g = m.u8(e + 0x1f); c = m.char(g)
                out.append(dict(t=k, i=r['i'], flag=m.u8(e + 0x1a), hp=m.u16(o + 0x5ab6), hpcopy=m.u16(o + 0x5b06),
                    port=m.u8(c), state=m.u8(c + 4), action=m.u16(c + 0x12), prev=m.u16(c + 0x16), dead=m.u8(c + 0x1199),
                    motion=m.u32(o + 0x5b30), frame=round(struct.unpack('<f', m.read(o + 0x4bcc, 4))[0], 2),
                    b54=m.u8(o + 0x5b54), b56=m.u8(o + 0x5b56), b57=m.u8(o + 0x5b57), pos=[round(x, 2) for x in m.f3(o + 0x4b80)]))
            except Exception as ex:
                out.append(dict(t=k, i=r['i'], error=repr(ex)))
        time.sleep(0.5)
    return out

def snapshot(m, tag, rows, extra):
    global snap_n
    snap_n += 1
    fn = os.path.join(D, 'snaps', time.strftime('%H%M%S') + f'_{tag}.json')
    json.dump(dict(time=time.strftime('%H:%M:%S'), tag=tag, extra=extra, objects=rows), open(fn, 'w'), indent=1)
    subprocess.run([TOOLS + '/shot.sh', fn.replace('.json', '.png')], capture_output=True, timeout=15)
    return fn

sysf.write('time,gpu_util,gpu_temp,gpu_power,gpu_clock,gpu_mem,cpu_temp,game_cpu,game_rss_mb\n')
def ev(msg):
    events.write(time.strftime('%H:%M:%S ') + msg + '\n'); events.flush()
m = None; last = {}; t_sys = 0; t_shot = 0; prev_cpu = None
ev('monitor started')
while not os.path.exists(STOP):
    now = time.time()
    try:
        if m is None:
            m = ngs2mem.Mem(); ev(f'game found pid {m.pid}')
        if not os.path.exists(f'/proc/{m.pid}'):
            ev(f'GAME PROCESS GONE pid {m.pid}'); m = None; time.sleep(2); continue
        players = m.u8(0x14211e5cc); view = m.u32(0x142ff2778); paused = m.u8(0x141e3a8c2); menu = m.u8(0x1421544fa)
        a0 = m.u8(0x14211e760); a1 = m.u8(0x14211e761); pm1 = m.u8(0x14211e755)
        hp1 = mx1 = hp2 = mx2 = port = -1
        if a0 < 0xa0:
            o = m.obj(a0)
            if o: hp1, mx1 = m.u16(o + 0x5ab6), m.u16(o + 0x5ab4)
        if a1 < 0xa0 and a1 != a0:
            o = m.obj(a1)
            if o: hp2, mx2 = m.u16(o + 0x5ab6), m.u16(o + 0x5ab4)
            port = m.u8(m.char(m.group(a1)))
        g2 = m.u32(0x141ecc9d0 + 0xe98); karma = m.u32(0x141ea00a8)
        rows = table(m, a0, a1)
        enemies = [r for r in rows if not r['player'] and r['flag'] == 0 and r['max'] > 0 and r['max'] < 60000 and r['hp'] > 0]
        types = collections.Counter(r['type'] for r in enemies)
        alive = len(enemies)
        row = [time.strftime('%H:%M:%S'), m.pid, players, view, paused, menu, a0, a1, pm1, port, hp1, mx1, hp2, mx2, g2, karma, len(rows), alive, '|'.join(f'{t:#x}x{n}' for t, n in sorted(types.items()))]
        in_mission = players >= 2 and menu == 74
        if in_mission and last_alive is not None and (alive == 0) != (last_alive == 0):
            ev(f'enemigos vivos: {last_alive} -> {alive}')
        last_alive = alive if in_mission else None
        if in_mission and not paused and alive == 0:
            stall_since = stall_since or now
            if now - stall_since >= 12 and not getattr(snapshot, 'done', False):
                fn = snapshot(m, 'sin_enemigos_20s', rows, dict(karma=karma, hp1=hp1, hp2=hp2, stuck=stuck_detail(m, rows)))
                ev(f'POSIBLE ATASCO: 20 s sin enemigos vivos en mision; foto {os.path.basename(fn)}')
                snapshot.done = True
        else:
            stall_since = None
            if alive > 0: snapshot.done = False
        if os.path.exists(os.path.join(D, 'SNAP')):
            os.remove(os.path.join(D, 'SNAP'))
            fn = snapshot(m, 'manual', rows, dict(karma=karma, hp1=hp1, hp2=hp2, stuck=stuck_detail(m, rows)))
            ev(f'foto manual {os.path.basename(fn)}')
        state.write(','.join(map(str, row)) + '\n'); state.flush()
        cur = dict(players=players, paused=paused, menu=menu, port=port, p2_down=hp2 == 0)
        for k, v in cur.items():
            if k in last and last[k] != v: ev(f'{k}: {last[k]} -> {v}')
        last = cur
    except SystemExit:  # game not running yet
        m = None; time.sleep(2); continue
    except Exception as e:
        ev(f'sample error: {e!r}'); m = None; time.sleep(2)
    if now - t_sys >= 5:
        t_sys = now
        try:
            g = subprocess.run(['nvidia-smi', '--query-gpu=utilization.gpu,temperature.gpu,power.draw,clocks.gr,memory.used',
                                '--format=csv,noheader,nounits'], capture_output=True, text=True, timeout=5).stdout.strip().replace(' ', '')
        except Exception: g = ',,,,'
        cpu_t = ''
        try:
            for z in os.listdir('/sys/class/thermal'):
                if z.startswith('thermal_zone') and open(f'/sys/class/thermal/{z}/type').read().strip() in ('x86_pkg_temp',):
                    cpu_t = str(int(open(f'/sys/class/thermal/{z}/temp').read()) // 1000)
        except Exception: pass
        gcpu = grss = ''
        if m is not None:
            try:
                st = open(f'/proc/{m.pid}/stat').read().split(')')[1].split()
                ticks = int(st[11]) + int(st[12])
                if prev_cpu: gcpu = f'{(ticks - prev_cpu[0]) / os.sysconf("SC_CLK_TCK") / (now - prev_cpu[1]) * 100:.0f}'
                prev_cpu = (ticks, now)
                for l in open(f'/proc/{m.pid}/status'):
                    if l.startswith('VmRSS'): grss = str(int(l.split()[1]) // 1024)
            except Exception: pass
        sysf.write(f"{time.strftime('%H:%M:%S')},{g},{cpu_t},{gcpu},{grss}\n"); sysf.flush()
    if m is not None and now - t_shot >= 30:
        t_shot = now
        out = os.path.join(D, 'shots', time.strftime('%H%M%S') + '.png')
        subprocess.run([TOOLS + '/shot.sh', out], capture_output=True, timeout=15)
    time.sleep(1)
ev('monitor stopped')
