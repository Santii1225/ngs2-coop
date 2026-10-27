#!/bin/bash
# ktap.sh KEY [KEY...] -- focus the game, inject Logitech key presses (kbpad must be running)
T=$(dirname "$(realpath "$0")")
for k in "$@"; do $T/game.sh focus; python3 $T/kbinject.py $k 100; sleep 0.6; done
