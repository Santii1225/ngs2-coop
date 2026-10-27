#!/bin/bash
# pad.sh p1|p2 CMD...  -- send a vpad.py command to the player 1 (p1) or player 2 (p2) virtual pad
mkdir -p /tmp/ngs2coop
T=$(dirname "$(realpath "$0")"); case "$1" in p1) F=vpad.fifo;; p2) F=vpad2.fifo;; esac; shift
VPAD_FIFO=/tmp/ngs2coop/$F exec python3 $T/vpad.py "$@"
