#!/bin/bash
# mission_pick_test.sh [rounds]  -- from the mission-select screen (player 2 joined): P2 marks cell (3,1)
# (Acólito 09) and locks it, P1 confirms cell (0,0) (Acólito 01); the mission shown on the character
# screen tells which pick won. Then B back to mission select and repeat.
T=$(dirname "$(realpath "$0")"); cd "$T"
LOG="$HOME/.local/share/Steam/steamapps/common/[NINJA GAIDEN Master Collection] NINJA GAIDEN Σ２/plugin/ngs2coop.log"
for r in $(seq ${1:-4}); do
  for i in 1 2 3 4; do ./pad.sh p1 tap LEFT 100; sleep 0.4; done; ./pad.sh p1 tap UP 100; sleep 0.5   # P1 -> (0,0)
  for mv in RIGHT RIGHT RIGHT DOWN; do ./pad.sh r tap $mv 100; sleep 0.4; done
  ./pad.sh r tap A 100; sleep 0.8
  ./shot.sh /tmp/ngs2coop/pick_$r.png >/dev/null
  ./pad.sh p1 tap A 100; sleep 4
  ./shot.sh /tmp/ngs2coop/pick_${r}_chars.png >/dev/null
  echo "round $r: $(tail -1 "$LOG")"
  ./pad.sh p1 tap B 100; sleep 3
done
