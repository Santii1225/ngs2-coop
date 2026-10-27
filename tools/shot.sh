#!/bin/bash
# shot.sh [out.png] -- in-game backbuffer capture via ngs2lab (half size PNG)
mkdir -p /tmp/ngs2coop
GD="$HOME/.local/share/Steam/steamapps/common/[NINJA GAIDEN Master Collection] NINJA GAIDEN Σ２/plugin"
OUT=${1:-/tmp/ngs2coop/shot.png}
S=${NGS2LAB_SUFFIX:-}   # optional suffix of the lab files
rm -f "$GD/lab_shot$S.bmp"; echo shot > "$GD/lab_cmd$S.txt"
for i in $(seq 50); do [ -f "$GD/lab_shot$S.bmp" ] && break; sleep 0.1; done
[ -f "$GD/lab_shot$S.bmp" ] || { echo "no shot (game not presenting?)"; exit 1; }
python3 -c "
from PIL import Image; im=Image.open('$GD/lab_shot$S.bmp').convert('RGB'); im.resize((im.size[0]//2,im.size[1]//2)).save('$OUT'); print('$OUT', im.getextrema())"
