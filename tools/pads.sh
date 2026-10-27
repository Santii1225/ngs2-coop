#!/bin/bash
# pads.sh start|stop -- two virtual Xbox 360 pads (slot 0 = player 1, slot 1 = player 2).
# Start them BEFORE the game: the game does not pick up controllers hot-plugged later.
T=$(dirname "$(realpath "$0")"); R=/tmp/ngs2coop; mkdir -p $R
stop() { for f in $R/vpad1.pid $R/vpad2.pid; do [ -f $f ] && kill $(cat $f) 2>/dev/null; rm -f $f; done; sleep 0.5; }
start() {
  stop
  VPAD_FIFO=$R/vpad.fifo setsid nohup python3 $T/vpad.py daemon > $R/vpad.log 2>&1 & echo $! > $R/vpad1.pid
  sleep 1.5
  VPAD_FIFO=$R/vpad2.fifo setsid nohup python3 $T/vpad.py daemon > $R/vpad2.log 2>&1 & echo $! > $R/vpad2.pid
  sleep 1.5; cat $R/vpad.log $R/vpad2.log
}
$1
