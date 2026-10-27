# MVP 2 — Controlled position write test 01

Fecha: 2026-09-06T20:44:40−06:00. Resultado: **PARTIAL**.

Primera escritura controlada y reversible de una coordenada del LOCAL_PLAYER. Autorizada por el usuario con la frase exacta `AUTORIZO WRITE +0.30 X`, tras `ZONA ESTABLE PARA MVP2`. Herramienta independiente `tools/player_write_test.py` (sin core.dll, sin hook, sin `ptrace`, sin `VirtualProtect`): un `pwrite` de 4 bytes en `/proc/<pid>/mem` (O_RDWR) sobre una dirección resuelta dinámicamente, con restauración automática.

## Parámetros

| | |
|---|---|
| Proceso | PID 29318, `comm` «NINJA GAIDEN SI», TracerPid 0, starttime 920438 |
| Module base | `0x140000000` (delta ASLR 0) · core `0x6ffff9830000` |
| Gates | EXE SHA256 `a66daf…` OK · core SHA256 `ca2849…` OK · slot Sigma2 → `core+0x16F2` (hook 151ea14 vivo) |
| Actor | LOCAL_PLAYER = `game_object[0]` → objeto `0x143197100` (RVA `0x3197100`), group 0, obj_id 0, `char[group]+0x00 = 0x00`, quaternion `obj+0x60` unitario, vivo. **NO** es el compañero IA. |
| Target / offset | `object + 0x2B0` (world **X** / C0), float32, 4 bytes. Dirección de ejemplo de esta sesión: `0x1431973b0`. |
| `LOCAL_PLAYER_STABLE` | PASS — 10 muestras / 0.5 s, `h_range` 0.0000, `v_range` 0.0000; corroboración `character+0x310` coherente. |
| Original XYZ | (67.845779, 5.219999, −95.821899) |
| Original X bytes | `0ab18742` (float 67.84577942) |
| Delta | **+0.30** |
| New X | 68.14577942 · bytes `a44a8842` |

## Secuencia (una escritura, una restauración)

| t (−06:00) | evento | X | bytes |
|---|---|---|---|
| 20:44:40.500278 | re-validación desde cero (mismo PID/starttime/object; X sin deriva; `char[grp]+0x00 == 0x00`) | 67.845779 | `0ab18742` |
| 20:44:40.500384 | **write** (`pwrite` 4 bytes, n=4) | → 68.145779 | `a44a8842` |
| 20:44:40.500402 | readback inmediato (+18 µs) | **68.14578** | `a44a8842` |
| 20:44:40.650620 | observación +1 (+150 ms) | 67.845779 | `0ab18742` |
| 20:44:40.800 … 41.251 | observación +2..+5 | 67.845779 (×4) | `0ab18742` |
| 20:44:41.256568 | **restauración automática** (`pwrite` bytes originales, n=4) | 67.845779 | `0ab18742` |
| — | readback restauración | **67.84577942** | `0ab18742` → `EXACT` |

## Engine behavior

`REVERTED toward original (engine overwrote)`. La escritura **entró** en memoria (readback inmediato = valor pedido, diff 3e-6 = ULP float). En la primera muestra de observación (~150 ms después) `object+0x2B0` ya contenía el valor original. Duración efectiva de la modificación: **entre 18 µs y ~150 ms** (uno o pocos frames como máximo). `object+0x2B0` se comporta como **copia de lectura / cara al render, NO autoritativa**: el motor re-deriva X desde un estado canónico más profundo cada tick.

Y (`+0x2B4`) = `5.2199993` y Z (`+0x2B8`) = `−95.8218994` **constantes** en las 5 muestras de observación → sin efecto lateral vertical ni en Z. El mirror/copia visual no se escribió.

## Rollback

`attempted: True` · `n: 4` · `readback_bytes: 0ab18742` · `readback_x: 67.84577942` · **`result: EXACT`**. (El motor ya había restaurado el valor por su cuenta antes de la restauración; la restauración explícita escribió los bytes originales de forma segura y se verificó exacta.)

## Visual observation

Usuario: **`NO NOTE MOVIMIENTO`**. Coherente: la modificación persistió < 150 ms (pocos frames) y el delta (0.30 u) es pequeño; el motor la revirtió antes de que fuese perceptible.

## Errors

Ninguno. Sin crash, sin NaN/Inf, sin valor absurdo, sin cambio de PID/starttime, sin knockback. Proceso vivo tras la prueba (`process_alive: True`, `process_starttime_stable: True`). Resolver post-test: X 67.845779, Y 5.22, Z −95.82 (Ryu sin cambios). Hook Sigma2 vivo.

## Verdict

**PARTIAL.**

- ✅ La escritura se realizó sobre LOCAL_PLAYER (identidad revalidada), no sobre el compañero IA.
- ✅ Readback inmediato confirmó el valor escrito.
- ✅ El proceso permaneció estable; sin crash ni corrupción.
- ✅ El rollback restauró exactamente (`EXACT`).
- ✅ No se tocó AI_PARTNER, Y, Z, rotación ni el mirror visual.
- ⚠️ El motor sobrescribe `object+0x2B0` en < ~150 ms desde un estado canónico. → `object+0x2B0` **no es la posición autoritativa** para escritura; es una copia de lectura.
- Usuario no notó movimiento visual (esperable dada la duración y magnitud).

## Interpretation / siguiente objetivo

`object+0x2B0` está **RUNTIME VERIFIED como lectura** (Fase 7: XYZ, ejes, right-handed Y-up) pero **NO es escribible de forma persistente**: existe un estado canónico/autoritativo de posición del jugador que el motor propaga a `object+0x2B0` cada tick. Para un teleport real habría que:

- localizar el estado autoritativo (candidatos: el bloque `char[group]` — `char+0x310` también es copia; una estructura de física/rigidbody; un nodo raíz de esqueleto; o un puntero desde `object` a un transform «lógico»), o
- escribir en el momento correcto del frame (hook del tick de sync — fuera de alcance de esta fase, requeriría un hook nuevo), o
- escribir `object+0x2B0` de forma sostenida a alta frecuencia (no es un teleport limpio; descartado).

Esta prueba **no** intenta nada de lo anterior. Es evidencia de una sola escritura + restauración.

## Restricciones respetadas

Una escritura, una restauración. No se repitió con +0.5, ni Z, ni Y, ni rotación, ni AI_PARTNER. Sin networking. Sin hooks nuevos. Sin cambios en `core.dll` / plugin / EXE / Proton. Restauración automática (no dependió de input humano); modificación mantenida < 1 s.

Evidencia: `docs/research/player/MVP2_WRITE_TEST_20260907T024348Z/` (`pre_write.json`, `original_x.bin`, `result.json`, `restore_x.bin`).

---

## Seguimiento — Fase 10: `object+0x2B0` no es canónico (confirmado)

Investigación de solo lectura posterior ([CANONICAL_POSITION_RESEARCH.md](CANONICAL_POSITION_RESEARCH.md)): watchpoints de hardware read-only vía gdb muestran que `object+0x2B0` se escribe **cada frame por rutinas genéricas de copia de bloque** (`memcpy`/`memmove`, RVA 0x8C7B4 confirmado; también 0x1353E41, 0xEAD02E) en el hilo «Updating»; con Ryu quieto el watchpoint de cambio de valor no dispara (se escribe el mismo valor cada frame). No hay instrucción dedicada de actualización de posición. La fuente canónica **no se aisló** con las herramientas de solo lectura. Las ~14 copias de posición en `object`/`character` son todas RENDER/OBSERVABLE COPY; `object+0x310` es INTERPOLATED; `object+0x340/+0x370` son HISTORICAL. **Canonical position: no localizado. Ready for MVP 2b: NO.**
