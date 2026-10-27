# runtime_text/ — runtime-initialized executable section dumps

The Sigma2 EXE on disk is SteamDRM-protected: its `.text` bytes on disk are
ciphertext (see `docs/RUNTIME_ANALYSIS.md`, "Disco frente a memoria"). To analyse
real instructions we copy the sections out of the live process after the DRM
stub has decrypted them in place.

`*.bin` files are **git-ignored** (large, derivative). Each dump dir keeps
`dump_manifest.json` with: PID, process starttime, module base, EXE/core SHA256,
Sigma2 hook-slot continuity value, PE timestamp, and for every section the RVA
range, virtual size, the exact r-x/r-- segment map, and the SHA256 of the
assembled image and of each real segment.

## Regenerate

    python3 tools/runtime_text_dump.py --out-dir docs/research/runtime_text/<new> \
        --sections .text .bind .rdata .pdata

Read-only: `open(/proc/<pid>/mem, O_RDONLY)` + `pread`. No writes, no ptrace.

## Analyse offline

    tools/rt_image.py --dump <dir> dis   <RVA> [LEN]   # capstone disassembly
    tools/rt_image.py --dump <dir> func  <RVA>         # .pdata RUNTIME_FUNCTION
    tools/rt_image.py --dump <dir> xref  <RVA>         # E8/E9 rel32 callers
    tools/rt_image.py --dump <dir> callers <RVA>       # callers grouped by func
    tools/rt_image.py --dump <dir> scandisp <disp>...  # stores/loads by displacement

capstone lives in a throwaway venv (not a repo dep):
`python3 -m venv v && v/bin/pip install capstone`.

## Dumps

| dir | PID | base | .text SHA256 |
|---|---|---|---|
| 20260907T1650Z_pid14042 | 14042 | 0x140000000 | 193894e5311dd6e5452aa9e9940d28bdf1b1e007927991cd72f598f0790bfec5 |
