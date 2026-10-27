#!/usr/bin/env python3
"""Mission-select grid cursor from a shot.sh capture (960x600): prints the index 0..9 of the
highlighted cell (row-major, 5 per row) or -1."""
import sys
from PIL import Image
im = Image.open(sys.argv[1] if len(sys.argv) > 1 else '/tmp/ngs2coop/shot.png').convert('RGB')
xs, ys = [461, 556, 650, 745, 840], [257, 313]
score = []
for y in ys:
    for x in xs:
        n = 0
        pts = [(px, py) for px in range(x - 44, x + 44, 2) for py in range(y - 31, y - 24)]      # top edge
        pts += [(px, py) for py in range(y - 20, y + 20, 2) for px in (*range(x - 55, x - 47), *range(x + 47, x + 55))]  # sides
        for px, py in pts:
            r, g, b = im.getpixel((px, py))
            n += b > 160 and g > 110 and b - r > 30    # the cyan highlight frame
        score.append(n)
best = max(range(10), key=lambda i: score[i])
print(best if score[best] > 20 and score[best] > 2 * sorted(score)[-2] else -1)
