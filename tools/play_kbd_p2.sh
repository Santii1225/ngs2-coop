#!/bin/bash
# Local coop test: Logitech keyboard = virtual pad (player 2), real controller = player 1.
# Starts the keyboard pad BEFORE the game (the game ignores controllers plugged in later).
T=$(dirname "$(realpath "$0")"); R=/tmp/ngs2coop; mkdir -p $R
[ -f $R/kbpad.pid ] && kill $(cat $R/kbpad.pid) 2>/dev/null
setsid nohup python3 $T/kbpad.py G515 > $R/kbpad.log 2>&1 & echo $! > $R/kbpad.pid
sleep 2; cat $R/kbpad.log
grep -q "CAPTURED" $R/kbpad.log || { echo "kbpad failed (keyboard permission? see tools/udev)"; exit 1; }
$T/game.sh start
echo "Ctrl+Esc on the Logitech keyboard stops the keyboard pad; ScrollLock releases/captures it."
