#!/bin/bash
# play.sh [OUTPUT] -- start the game for two-player play: the game window goes borderless and full size on OUTPUT
# (default eDP-1, the laptop panel); with two monitors the mod opens player 2's window on the other one.
# The game snaps back to its own monitor when made full screen, so the window is sized to the output instead.
# KWin refuses to load a script file twice, so every run uses a new file name and unloads it.
T=$(dirname "$(realpath "$0")"); OUT=${1:-eDP-1}
mkdir -p /tmp/ngs2coop
"$T/game.sh" start | tail -1
place() {
  local n=ngs2play_$RANDOM$RANDOM f
  f=/tmp/ngs2coop/$n.js
  cat > "$f" <<J
var out = null;
for (const s of workspace.screens) if (s.name == "$OUT") out = s;
for (const w of workspace.windowList()) {
  if (w.caption != "NINJA GAIDEN Σ2" || !out) continue;
  w.fullScreen = false;
  workspace.sendClientToScreen(w, out);
  w.noBorder = true;
  w.frameGeometry = {x: out.geometry.x, y: out.geometry.y, width: out.geometry.width, height: out.geometry.height};
  print("NGS2PLAY " + w.output.name + " " + w.frameGeometry.width + "x" + w.frameGeometry.height);
}
J
  local id
  id=$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript "$f" "$n")
  qdbus6 org.kde.KWin /Scripting/Script$id org.kde.kwin.Script.run >/dev/null 2>&1
  sleep 1
  qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "$n" >/dev/null 2>&1
  rm -f "$f"
}
# The game moves its window while it starts: place it a few times.
for i in 1 2 3 4; do sleep 3; place; done
journalctl --user --since -20s -o cat | grep NGS2PLAY | tail -1
