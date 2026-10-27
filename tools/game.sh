#!/bin/bash
# game.sh start|stop|restart|focus|pid  -- unattended game control (Steam appid 1580790)
mkdir -p /tmp/ngs2coop
GD="$HOME/.local/share/Steam/steamapps/common/[NINJA GAIDEN Master Collection] NINJA GAIDEN Σ２"
JS=/tmp/ngs2coop/ngs2_focus.js
pid() { ps -eo pid,comm | awk '/NINJA GAIDEN/{print $1; exit}'; }
focus() {
  cat > $JS <<'J'
for (const w of workspace.windowList()) { if ((w.caption||"").includes("NINJA")) { w.minimized = false; workspace.activeWindow = w; print("NGS2FOCUS ok"); } }
J
  local name=ngs2focus_$RANDOM id
  id=$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript $JS $name)
  qdbus6 org.kde.KWin /Scripting/Script$id org.kde.kwin.Script.run >/dev/null 2>&1
  sleep 0.3
  qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript $name >/dev/null
}
stop() { local p=$(pid); [ -n "$p" ] && kill $p; for i in $(seq 30); do [ -z "$(pid)" ] && break; sleep 1; done
  for i in $(seq 15); do pgrep -f "Proton 11.0/files/(lib/wine/../../)?bin/wineserver" >/dev/null || break; sleep 1; done
  pgrep -f "Proton 11.0/files/(lib/wine/../../)?bin/wineserver" >/dev/null && kill_launch; sleep 1; }
# The game's wineserver must be gone before the next launch, or Proton waits on it forever.
WS() { WINEPREFIX="$HOME/.local/share/Steam/steamapps/compatdata/1580790/pfx" "$HOME/.local/share/Steam/steamapps/common/Proton 11.0/files/bin/wineserver" "$@"; }
kill_launch() { for p in $(pgrep -f "AppId=1580790"); do kill $p 2>/dev/null; done; sleep 2; WS -k 2>/dev/null; sleep 2; }
start() {
  for try in 1 2; do
    setsid nohup steam "steam://rungameid/1580790" >/dev/null 2>&1 &
    for i in $(seq 90); do [ -n "$(pid)" ] && break; sleep 1; done
    [ -n "$(pid)" ] && break
    echo "launch hung, retrying"; kill_launch
  done
  for i in $(seq 20); do focus; sleep 1; done
  echo "pid $(pid)"
}
case "$1" in
  start) start;; stop) stop;; restart) stop; start;; focus) focus;; pid) pid;;
esac
