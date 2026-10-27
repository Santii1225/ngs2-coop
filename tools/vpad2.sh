#!/bin/bash
# send commands to the second virtual pad (player 2)
VPAD_FIFO=/tmp/ngs2coop/vpad2.fifo exec python3 "$(dirname "$0")/vpad.py" "$@"
