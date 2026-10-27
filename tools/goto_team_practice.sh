#!/bin/bash
# From the title screen (after a fresh start) into Team Missions > Practice > Acolyte 01.
# P1 = Rachel, partner = Ryu (default roster after one RIGHT on the player column).
T=$(dirname "$(realpath "$0")"); V="python3 $T/vpad.py"
$V tap A; sleep 4          # autosave notice
$V tap START; sleep 4      # title -> main menu
for i in 1 2 3 4 5 6 7; do $V tap UP; sleep 0.4; done   # clamp cursor to the top (Nueva partida)
$V tap DOWN; sleep 0.7                           # Misiones en equipo (greyed Cargar partida is skipped)
$V tap A; sleep 2.5
$V tap DOWN; sleep 0.7; $V tap A; sleep 2.5      # Práctica
$V tap A; sleep 2.5                              # Acólito 01
$V tap RIGHT; sleep 1                            # player 1 -> Rachel
for i in 1 2 3 4 5 6 7 8; do $V tap A; sleep 0.7; done
sleep 5
