#!/bin/bash
# place.sh PID OUTPUT  -- move the game window of PID to monitor OUTPUT (e.g. HDMI-A-3), fullscreen
cat > /tmp/ngs2coop/place.js <<J
var out = null;
for (const s of workspace.screens) if (s.name == "$2") out = s;
for (const w of workspace.windowList()) {
  if (w.pid != $1 || !(w.caption||"").includes("NINJA") || !out) continue;
  w.fullScreen = false;
  workspace.sendClientToScreen(w, out);
  w.frameGeometry = {x: out.geometry.x, y: out.geometry.y, width: out.geometry.width, height: out.geometry.height};
  w.fullScreen = true;
  print("NGS2PLACE " + w.pid + " -> " + out.name + " " + w.frameGeometry.x + "," + w.frameGeometry.y + " " + w.frameGeometry.width + "x" + w.frameGeometry.height);
}
J
id=$(qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript /tmp/ngs2coop/place.js ngs2place_$RANDOM)
qdbus6 org.kde.KWin /Scripting/Script$id org.kde.kwin.Script.run >/dev/null; sleep 0.5
journalctl --user --since -10s -o cat | grep NGS2PLACE | tail -1
