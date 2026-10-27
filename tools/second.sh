#!/bin/bash
# second.sh [VAR=value ...]  -- start a second copy of the game alongside the Steam one, inside the same
# Steam Linux Runtime container but with its own Wine prefix (../compat-p2, a copy of compatdata/1580790);
# sharing the prefix kills the first copy. Environment: Steam's launch env captured in
# config/steam_launch_env.txt (from the reaper process of a Steam launch).
T=$(dirname "$(realpath "$0")")
GDIR="$HOME/.local/share/Steam/steamapps/common/[NINJA GAIDEN Master Collection] NINJA GAIDEN Σ２"
P2="$(realpath "$T/../../compat-p2")"
mapfile -t ENVV < "$T/../config/steam_launch_env.txt"
# a wineserver left over from a killed copy makes the next launch wait forever
WINEPREFIX="$P2/pfx" "$HOME/.local/share/Steam/steamapps/common/Proton 11.0/files/bin/wineserver" -k 2>/dev/null; sleep 2
cd "$GDIR"
env -i "${ENVV[@]}" STEAM_COMPAT_DATA_PATH="$P2" "$@" \
  setsid nohup "$HOME/.local/share/Steam/steamapps/common/SteamLinuxRuntime_4/_v2-entry-point" --verb=waitforexitandrun -- \
  "$HOME/.local/share/Steam/steamapps/common/Proton 11.0/proton" waitforexitandrun "$GDIR/NINJA GAIDEN SIGMA2.exe" \
  > /tmp/ngs2coop/second.log 2>&1 &
echo $! > /tmp/ngs2coop/second.pid
