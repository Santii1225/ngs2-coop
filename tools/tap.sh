#!/bin/bash
# tap.sh BTN [BTN...]  -- focus the game, then tap buttons on virtual pad 1 (0.6 s apart)
T=$(dirname "$(realpath "$0")")
for b in "$@"; do $T/game.sh focus; python3 $T/vpad.py tap $b; sleep 0.6; done
