#!/bin/bash
# nav_team.sh PAD [SUFFIX] -- from the autosave notice to Team Missions > Practice > Acolyte 01 (default
# roster), driving pad PAD (p1|p2) and reading the screen (optional lab file SUFFIX).
T=$(dirname "$(realpath "$0")"); P="$T/pad.sh $1"; export NGS2LAB_SUFFIX=$2
SHOT=/tmp/ngs2coop/nav$2.png
for i in $(seq 60); do "$T/shot.sh" $SHOT >/dev/null; c=$(python3 "$T/menu_cursor.py" $SHOT); [ "$c" = 2 ] && break
  if [ "$c" = -4 ]; then $P tap A 120; sleep 3; elif [ "$c" = -3 ]; then $P tap START 120; sleep 3; elif [ "$c" = -2 ]; then sleep 1; elif [ "$c" -lt 2 ]; then $P tap DOWN 120; sleep 1; else $P tap UP 120; sleep 1; fi; done
[ "$c" = 2 ] || { echo "nav$2: main menu not found"; exit 1; }
$P tap A; sleep 3; $P tap DOWN 120; sleep 1; $P tap A; sleep 3; $P tap A; sleep 3
for i in 1 2 3 4 5 6 7 8; do $P tap A; sleep 0.8; done
echo "nav$2: confirmed"
