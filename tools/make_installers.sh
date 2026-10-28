#!/bin/bash
# make_installers.sh -- build the mod and the two installers (Windows .exe and Linux) into release/.
# The installers carry the files they copy into the game folder:
#   dbghelp.dll, plugin/{nmloader,nmsteam-bugfixes,nmcombat,nmeffect}.dll  from the NM Plugins release (dist/)
#   plugin/core.dll and the MinGW runtime DLLs                             from dist/plugin/
#   plugin/NGS2Coop.dll                                                    built here
# dist/ (not in git): unpack the NM Plugins release there (dbghelp.dll and plugin/).
set -e
R=$(cd "$(dirname "$0")/.." && pwd)
B=$R/build-codex
OUT=$R/release
cmake --build "$B" --target coop >/dev/null
mkdir -p "$OUT"
PAY=$(mktemp -d)
trap 'rm -rf "$PAY"' EXIT
mkdir -p "$PAY/plugin"
cp "$R/dist/dbghelp.dll" "$PAY/"
for f in nmloader nmsteam-bugfixes nmcombat nmeffect core libgcc_s_seh-1 libstdc++-6 libwinpthread-1; do
  cp "$R/dist/plugin/$f.dll" "$PAY/plugin/"
done
cp "$B/NGS2Coop.dll" "$PAY/plugin/"

x86_64-w64-mingw32-g++ -std=c++17 -O2 -static -s -Wall -o "$PAY/setup.exe" "$R/installer/main.cpp" -lshell32 2>&1 | grep -v "^$" || true
g++ -std=c++17 -O2 -static -s -Wall -o "$PAY/setup" "$R/installer/main.cpp"

# Append the files, their index and the trailer: [u64 index size]["NGS2COOP"].
python3 - "$PAY" "$OUT" <<'EOF'
import os, struct, sys
pay, out = sys.argv[1], sys.argv[2]
files = ['dbghelp.dll'] + ['plugin/' + f for f in sorted(os.listdir(os.path.join(pay, 'plugin')))]
for exe, name in (('setup.exe', 'NGS2-Coop-1.2-Windows.exe'), ('setup', 'NGS2-Coop-1.2-Linux')):
    with open(os.path.join(pay, exe), 'rb') as f: data = bytearray(f.read())
    index = ''
    for rel in files:
        with open(os.path.join(pay, rel), 'rb') as f: blob = f.read()
        index += '%s\t%d\t%d\n' % (rel, len(blob), len(data))
        data += blob
    idx = index.encode()
    data += idx + struct.pack('<Q', len(idx)) + b'NGS2COOP'
    path = os.path.join(out, name)
    with open(path, 'wb') as f: f.write(data)
    os.chmod(path, 0o755)
    print(path, len(data) // 1024, 'KiB')
EOF
