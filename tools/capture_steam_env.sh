#!/bin/bash
# capture_steam_env.sh -- with the game started from Steam, save Steam's launch environment (from its reaper
# process) to config/steam_launch_env.txt for tools/second.sh. Session tokens are dropped. Not in git.
T=$(dirname "$(realpath "$0")")
for p in $(pgrep -x reaper); do
  tr '\0' ' ' < /proc/$p/cmdline | grep -q "AppId=1580790" || continue
  tr '\0' '\n' < /proc/$p/environ | grep -E '^[A-Za-z_][A-Za-z0-9_]*=' \
    | grep -vE '^(STEAMVIDEOTOKEN|[A-Z_]*TOKEN[A-Z_]*)=' > "$T/../config/steam_launch_env.txt"
  wc -l < "$T/../config/steam_launch_env.txt"; exit 0
done
echo "start the game from Steam first"; exit 1
