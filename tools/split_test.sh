#!/bin/bash
# split_test.sh [nodeploy|nav|missions]  (missions: stop at the Normal mission select, player 2 joined) -- restart the game with the freshly built NGS2Coop.dll and walk into
mkdir -p /tmp/ngs2coop
# Team Missions > Practice > Acolyte 01 with two virtual pads; player 2 joins with BACK.
T=$(dirname "$(realpath "$0")"); R=$(dirname "$T")
GD="$HOME/.local/share/Steam/steamapps/common/[NINJA GAIDEN Master Collection] NINJA GAIDEN Σ２/plugin"
SHOT=/tmp/ngs2coop/split_nav.png
if [ "$1" != nav ] && [ "$1" != missions-nav ]; then
  "$T/game.sh" stop
  [ "$1" = nodeploy ] || cp "$R/build-codex/NGS2Coop.dll" "$GD/NGS2Coop.dll"
  "$T/pads.sh" start >/dev/null 2>&1
  "$T/game.sh" start | tail -1
fi
P() { "$T/pad.sh" p1 "$@"; }
cursor() { "$T/shot.sh" $SHOT >/dev/null 2>&1 || { echo -2; return; }
  python3 -c "
from PIL import Image; im=Image.open('$SHOT'); h=round(960*im.size[1]/im.size[0]); c=Image.new('RGB',(960,600)); c.paste(im.resize((960,h)),(0,(600-h)//2)); c.save('$SHOT')"; python3 "$T/menu_cursor.py" $SHOT; }
for i in $(seq 60); do c=$(cursor); [ "$c" = 2 ] && break
  "$T/game.sh" focus
  if [ "$c" = -4 ]; then P tap A 120; sleep 3; elif [ "$c" = -3 ]; then P tap START 120; sleep 3
  elif [ "$c" = -2 ]; then sleep 2; elif [ "$c" = -1 ]; then P tap DOWN 120; sleep 1; elif [ "$c" -lt 2 ]; then P tap DOWN 120; sleep 1; else P tap UP 120; sleep 1; fi; done
[ "$c" = 2 ] || { echo "main menu not found"; exit 1; }
if [ "$1" = missions ]; then
  "$T/pad.sh" p2 tap BACK; sleep 1.5; P tap A; sleep 3; P tap A; sleep 3
  tail -3 "$GD/ngs2coop.log"; exit 0
fi
P tap A; sleep 3; P tap DOWN 120; sleep 1; P tap A; sleep 3; P tap A; sleep 3
for i in 1 2 3 4 5 6 7 8; do P tap A; sleep 0.8; done
sleep 12
"$T/pad.sh" p2 tap BACK; sleep 1.5
tail -3 "$GD/ngs2coop.log"
