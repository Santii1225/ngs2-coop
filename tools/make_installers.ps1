# make_installers.ps1 -- Windows counterpart of make_installers.sh: builds NGS2Coop.dll and the two installers
# (Windows .exe and Linux) into release/, with no Linux machine needed.
#   -MinGW DIR   bin folder of a MinGW-w64 toolchain (g++.exe), e.g. WinLibs; default: g++ on PATH
#   -Zig EXE     zig.exe, which builds the Linux installer (static, musl); default: zig on PATH
# The installers carry the same files as make_installers.sh: dbghelp.dll and plugin/ from dist/ (not in git: unpack
# the NM Plugins release there, or a previous installer's payload), plus plugin/NGS2Coop.dll built here.
param([string]$MinGW = "", [string]$Zig = "zig")
$ErrorActionPreference = "Stop"
$R = Split-Path -Parent $PSScriptRoot
$Version = ([regex]'kVersion = "([^"]+)"').Match((Get-Content -Raw "$R\installer\main.cpp")).Groups[1].Value
$gpp = if ($MinGW) { Join-Path $MinGW "g++.exe" } else { "g++" }
$B = "$R\build-win"; $OUT = "$R\release"; $PAY = "$B\payload"
foreach ($d in $B, $OUT, $PAY, "$PAY\plugin") { New-Item -ItemType Directory -Force $d | Out-Null }

function Build([string]$what, [string[]]$cmd) {
  & $cmd[0] $cmd[1..($cmd.Count - 1)]
  if ($LASTEXITCODE -ne 0) { throw "$what failed" }
}
if ($MinGW) { $env:PATH = "$MinGW;$env:PATH" }  # cc1plus and the linker live next to g++
$coop = "main", "overlay", "split", "gametext", "quickmenu" | ForEach-Object { "$R\src\coop\$_.cpp" }
Build "NGS2Coop.dll" (@($gpp, "-std=c++20", "-O2", "-Wall", "-Wextra", "-shared", "-I", "$R\src") + $coop +
  @("-o", "$B\NGS2Coop.dll", "-ld3d11", "-ldxgi", "-lgdi32", "-lws2_32", "-static", "-static-libgcc", "-static-libstdc++"))
Build "setup.exe" @($gpp, "-std=c++17", "-O2", "-static", "-s", "-Wall", "-o", "$B\setup.exe", "$R\installer\main.cpp", "-lshell32")
Build "setup (Linux)" @($Zig, "c++", "-target", "x86_64-linux-musl", "-std=c++17", "-O2", "-static", "-s", "-o", "$B\setup", "$R\installer\main.cpp")

Copy-Item "$R\dist\dbghelp.dll" "$PAY\"
foreach ($f in "nmloader", "nmsteam-bugfixes", "nmcombat", "nmeffect", "core", "libgcc_s_seh-1", "libstdc++-6", "libwinpthread-1") {
  Copy-Item "$R\dist\plugin\$f.dll" "$PAY\plugin\"
}
Copy-Item "$B\NGS2Coop.dll" "$PAY\plugin\"

# Append the files, their index and the trailer: [u64 index size]["NGS2COOP"] (same order as make_installers.sh).
[string[]]$names = Get-ChildItem "$PAY\plugin" | ForEach-Object Name
[Array]::Sort($names, [StringComparer]::Ordinal)
$files = @("dbghelp.dll") + ($names | ForEach-Object { "plugin/$_" })
foreach ($pair in @(@("setup.exe", "NGS2-Coop-$Version-Windows.exe"), @("setup", "NGS2-Coop-$Version-Linux"))) {
  $data = New-Object System.Collections.Generic.List[byte]
  $data.AddRange([IO.File]::ReadAllBytes("$B\$($pair[0])"))
  $index = ""
  foreach ($rel in $files) {
    $blob = [IO.File]::ReadAllBytes((Join-Path $PAY $rel))
    $index += "$rel`t$($blob.Length)`t$($data.Count)`n"
    $data.AddRange($blob)
  }
  $idx = [Text.Encoding]::UTF8.GetBytes($index)
  $data.AddRange($idx)
  $data.AddRange([BitConverter]::GetBytes([uint64]$idx.Length))
  $data.AddRange([Text.Encoding]::ASCII.GetBytes("NGS2COOP"))
  [IO.File]::WriteAllBytes("$OUT\$($pair[1])", $data.ToArray())
  "{0}  {1} KiB" -f "$OUT\$($pair[1])", [int]($data.Count / 1024)
}
