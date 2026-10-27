#!/bin/bash
VPAD_FIFO=/tmp/ngs2coop/vpad3.fifo exec python3 "$(dirname "$0")/vpad.py" "$@"
