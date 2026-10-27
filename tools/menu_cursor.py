#!/usr/bin/env python3
"""Main-menu cursor from a shot.sh capture: prints the highlighted row (0 = NUEVA PARTIDA .. 6 = SALIR)
-1 if none stands out, -2 if the menu is not on screen, -3 on the title screen ("PULSA EL BOTÓN START"), -4 on the autosave notice.  menu_cursor.py [shot.png]"""
import sys
from PIL import Image
im = Image.open(sys.argv[1] if len(sys.argv) > 1 else '/tmp/ngs2coop/shot.png').convert('L')
rows = [360, 383, 407, 430, 453, 478, 502]     # text centre lines at the 960x600 shot size
score = []
for y in rows:
    px = sorted(im.crop((380, y - 7, 580, y + 7)).tobytes())
    score.append(sum(px[-300:]) / 300)          # brightest text pixels in the row
text = sum(1 for v in im.crop((320, 225, 640, 350)).tobytes() if v > 150)
if text > 1500 and score[0] < 70 and score[6] < 70:   # autosave notice: a block of text mid-screen
    print(-4); sys.exit()
if min(score[0], score[6]) < 70:              # NUEVA PARTIDA / SALIR rows missing
    print(-3 if score[3] > 150 and max(score[0], score[6]) < 70 else -2); sys.exit()
best = max(range(7), key=lambda i: score[i])
others = sorted(score)[-2]
print(best if score[best] - others > 12 else -1)
