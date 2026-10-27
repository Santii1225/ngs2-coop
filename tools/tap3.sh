#!/bin/bash
# tap3.sh BTN... -- focus game, tap buttons on virtual pad 3
T=$(dirname "$(realpath "$0")")
for b in "$@"; do $T/game.sh focus; $T/vpad3.sh tap $b 100; sleep 0.6; done
