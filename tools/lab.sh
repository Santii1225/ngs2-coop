#!/bin/bash
# lab.sh CMD -- send a command to ngs2lab.dll inside the game and print the new log lines
L="$HOME/.local/share/Steam/steamapps/common/[NINJA GAIDEN Master Collection] NINJA GAIDEN Σ２/plugin"
n=$(wc -l < "$L/lab.log" 2>/dev/null || echo 0); echo "$*" > "$L/lab_cmd.txt"; sleep 0.5; tail -n +$((n+1)) "$L/lab.log"
