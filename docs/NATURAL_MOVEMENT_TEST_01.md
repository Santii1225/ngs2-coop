# NATURAL MOVEMENT TEST 01 — FASE 16

**Resultado: PARTIAL.** El raw command humano inyectado en `object+0x4B90`
propagó a `object+0x5000` y al filtro EMA `character[group]+0x30`, pero
`character[group]+0x04` **no entró en un estado de locomoción**, así que
`0x14249A0` no integró el delta: sin velocity, sin animación, sin desplazamiento.
Ryu no se movió (confirmado por el usuario). Sin crash, sin teleport, sin
anomalía; `object+0x4B90` restaurado EXACT; AI_PARTNER intacto.

Fecha: 2026-09-07 (sesión), tras `0140ebf`. Primer experimento **con escritura**
desde MVP 2B. Autorizado por el usuario: un único test de movimiento natural
sobre LOCAL_PLAYER.

## Alcance / restricciones respetadas

- **Único campo escrito:** `LOCAL_PLAYER object + 0x4B90` (16 bytes, el raw
  movement command). Nunca `object+0x4B80`, `char+0x30`, velocity, rotación,
  cámara, AI_PARTNER ni ningún otro campo/actor. Nunca ataque/salto/esquiva.
- Standalone: solo `/proc/<pid>/mem`. Sin `core.dll`, sin hook, sin `ptrace`,
  sin `VirtualProtect`, sin hooks permanentes nuevos. Sin networking. Sin
  `git push`.
- **`object+0x4B80` NO se restauró** (por diseño: si Ryu hubiera caminado, su
  nueva posición debía quedarse). Como no se movió, posición final == inicial.

## Herramienta

`tools/raw_command_movement_test.py` — fail-closed, dry-run por defecto.

- `--capture` (read-only): muestrea `object+0x4B90 / +0x5000 / +0x4B80 / +0x2B0 /
  +0x4BC0`, `char+0x30`, `char+0x04` a ~60 Hz y elige un raw command
  representativo de la fase de caminar.
- dry-run: resuelve + todos los gates + `LOCAL_PLAYER_STABLE` + velocity ≈ 0 +
  raw command idle + `char+0x30` decaído + `char+0x04` idle; backup de los 16
  bytes idle de `object+0x4B90`.
- `--armed --confirm "AUTORIZO NATURAL MOVEMENT TEST 01"`: revalida todos los
  gates, reescribe los 16 bytes capturados en `object+0x4B90` cada ~8 ms
  (~125 Hz) durante ≤ 2.0 s, muestrea el downstream read-only, para de escribir,
  restaura `object+0x4B90` a idle, observa ~1.8 s de decaimiento.
- Failsafe (aborta + para de escribir + restaura `+0x4B90`, sin compensar
  posición): PID/starttime cambia, proceso desaparece, NaN/Inf en `+0x4B80`,
  Y salta > 0.5, salto instantáneo de posición > 5 u, `+0x4B90` inaccesible.

## 1 — Comando humano capturado (no inventado)

Dos intentos de captura (el 1º falló por timing: la ventana de 20 s se cerró
antes de que el usuario moviera; 1200 muestras todas idle). El 2º (ventana 30 s)
capturó un tramo real de locomoción de ~2 s:

- `char+0x04` durante el tramo: `0x00` → `0x06` (start, 17) → `0x26` (walk, 39)
  → `0x28` (walk→run, 44) → `0x2A` (run/parada, 22).
- velocity pico `|object+0x4BC0|` = 3.35.
- El raw command `object+0x4B90` es un **delta de dirección por frame** (|xz| en
  la banda 0.035–0.10 según el estado), `w = 1.0` mientras hay comando.

**Muestra elegida** (mediana de las muestras rectas en estado `0x26` = caminar,
`|raw.z| < 0.0015`): sample i=1691, t≈28.18 s, `char+0x04 = 0x26`, `|vel| = 0.77`.

| | valor |
|---|---|
| `object+0x4B90` | `(-0.068983, 0.000632, -0.001078, 1.000000)` |
| bytes (LE) | `1c 47 8d bd  8b a4 25 3a  b0 45 8d ba  00 00 80 3f` |
| `|xz|` | 0.068992 |
| `char+0x30` en esa muestra | `(-0.06287, 0.00058, -0.00100, 0.99982)` |

Evidencia: `docs/research/locomotion/natural_movement_test_01/capture_fwd2/`
(`capture.json` recortado a la ventana de movimiento, `chosen_raw_command.bin`).

## 2 — Gates (todos PASS antes de escribir)

| gate | valor |
|---|---|
| proceso único `NINJA GAIDEN SI` | PID 14042 |
| TracerPid | 0 |
| starttime estable | 108576 (antes, durante y después) |
| SHA256 EXE / core.dll | OK |
| hook Sigma2 (slot `module_base+0x18F9518` == `core_base+0x16F2`) | PASS |
| LOCAL_PLAYER | `game_object[0]` · object `0x143197100` (RVA `0x3197100`) · group 0 · obj_id 0 |
| `char[0]+0x00` | `0x00` (input local) |
| AI_PARTNER seleccionado | NO |
| `object+0x5B56` (enable del comando) | `0x01` |
| `LOCAL_PLAYER_STABLE` | PASS (h_range 0.0000, v_range 0.0000 sobre 8 muestras) |
| velocity `|object+0x4BC0|` | 0.0000 (< 0.06) |
| raw command `object+0x4B90` | `(0,0,0,0)` idle |
| `char+0x30` | `(0,0,0,0)` decaído |
| `char+0x04` | `0x00` idle |
| `object+0x4B80` vs `object+0x2B0` | coherentes (chain dist 0) |
| posición canónica de partida | `(-106.0163, 0.0000, 24.1052)` |

## 3 — Inyección

- 192 writes de 16 bytes en `object+0x4B90` (`0x14319bc90`) durante ~2.0 s
  (~96 Hz efectivos; el motor reescribe el campo cada frame vía `0x14210A0`).
- Muestreo read-only cada ~6 writes (~48 ms): 32 muestras.
- Sin abort, sin failsafe disparado.

## 4 — Propagación observada

```
 t     raw+0x4B90(x,z)     +0x5000(x,z)      char+0x30(x,z)     char+0x04   |vel|   canon+0x4B80
 0.10  (-0.0690,-0.0011)   (-0.0690,-0.0011) (-0.0598,-0.0009)  0x00        0.000   (-106.016, 0.000, 24.105)
 0.48  ( 0.0000, 0.0000)   (-0.0690,-0.0011) (-0.0613,-0.0010)  0x00        0.000   (-106.016, 0.000, 24.105)
 1.00  ( 0.0000, 0.0000)   (-0.0690,-0.0011) (-0.0593,-0.0009)  0x00        0.000   (-106.016, 0.000, 24.105)
 1.55  ( 0.0000, 0.0000)   (-0.0690,-0.0011) (-0.0593,-0.0009)  0x00        0.000   (-106.016, 0.000, 24.105)
 1.98  ( 0.0000, 0.0000)   (-0.0690,-0.0011) (-0.0676,-0.0011)  0x00        0.000   (-106.016, 0.000, 24.105)
```

| señal | respuesta |
|---|---|
| `object+0x4B90` (inyección) | **vista** — aparece `(-0.0690, -0.0011, ...)` en las muestras donde el write cayó entre dos frames; en el resto `(0,0,0,0)` porque `0x14210A0` re-zeroea el campo cada frame (Ryu sin input real ⇒ `g_scratch = 0`) — carrera esperada, el write a 125 Hz gana varias veces por frame |
| `object+0x5000` | **respondió** — mantuvo `(-0.0690, -0.0011, ...)` casi toda la ventana (`0xFF282A` lo latchea desde `object+0x4B90`; solo un frame a `(0,0,0,0)` en t≈1.17) |
| `char+0x30` (EMA `0xF24F4A`) | **respondió** — convergió y osciló en `(-0.059 … -0.068, -0.001)`, siguiendo a `object+0x5000` exactamente como predice el modelo EMA |
| `char+0x04` (state de locomoción) | **`0x00` (idle) TODO el tiempo** — NO entró en `0x06/0x26/...` |
| `object+0x4BC0` (velocity) | 0.000 — sin cambio |
| `object+0x4B80` (posición canónica) | **sin cambio** `(-106.016, 0.000, 24.105)` en las 32 muestras |
| `object+0x2B0` (render) | sin cambio |

## 5 — Stop / decaimiento

- Se dejó de escribir. `object+0x4B90` restaurado a `00…00` → **EXACT**.
- 12 muestras / 1.8 s tras el stop: `object+0x5000` → `(0,0,0,0)`, `char+0x30` →
  0, velocity → 0, `char+0x04` → `0x00`. Decaimiento limpio.
- `object+0x4B80` **no restaurado** — pero nunca cambió, así que posición final =
  `(-106.0163, 0.0000, 24.1052)` = inicial (displacement total 0.0).

## 6 — Failsafe / salud

| | |
|---|---|
| abort | ninguno |
| crash / cuelgue | no |
| proceso vivo tras el test | sí (PID 14042) |
| starttime estable | sí (108576) |
| NaN/Inf | no |
| teleport | no |
| knockback | no |
| Y desplazado | no (Δ 0) |
| AI_PARTNER | **intacto** — `ai object+0x4B90 = (0,0,0,0)` post-test |
| hook Sigma2 | PASS (re-verificado) |
| observación visual del usuario | **D) RYU NO SE MOVIÓ** |

## 7 — Interpretación

**`char+0x04` es la pieza que falta.** La cadena
`object+0x4B90 → object+0x5000 → EMA char+0x30` quedó **RUNTIME VERIFIED por
inyección directa** (no solo por observación). Pero `0x14249A0` (la máquina de
estados que integra el delta y llama a W1 `0x141BB90`) está keyed en
`character[group]+0x04`; con `char+0x04 = 0x00` (idle) su handler pone el delta a
cero y nunca llama a W1 ⇒ sin integración de posición, sin velocity, sin
animación.

Esto **confirma el caveat C** anticipado en la Fase 15
(`REMOTE_CONTROL_INJECTION_RESEARCH.md` §15.9 / `RAW_MOVEMENT_COMMAND_RESEARCH.md`
§15.11): reescribir solo el raw command **no** basta para locomoción natural.
También es coherente con MVP 2B (+10.0 X): escribir posición sin tocar `char+0x04`
= sin animación.

`char+0x04` lo produce la máquina de animación compartida (`0xF1ECA0` y la capa
`0xF31D8D` / `0xF7BDE0`) a partir del **estado deseado / action code**
`character[group]+0x12` — NO a partir de la magnitud de `char+0x30`. Para
movimiento natural hay que alimentar también ese nivel (inyección **nivel A/B**,
no C):

- **B**: hook de `0x14203E0` (o del store `0x142082B` a `g_scratch`) para el
  actor controlado — produce el raw command *y* deja que el resto del update
  per-actor (incluido lo que engancha `char+0x04`) corra con ese comando.
- **A**: alimentar el estado deseado / `char+0x12` además del raw command.

## 8 — Estado

| | |
|---|---|
| **Resultado** | **PARTIAL** |
| raw command inyectado | ✅ |
| `object+0x5000` responde | ✅ |
| EMA `char+0x30` responde | ✅ |
| `char+0x04` entra en locomoción | ❌ |
| velocity sube | ❌ |
| posición canónica progresa | ❌ (progression = NONE, Δ 0.000) |
| animación normal | ❌ (Ryu no se movió) |
| se detiene normal al cesar | ✅ (decaimiento limpio) |
| juego estable | ✅ |
| teleport | ✅ NO |
| `REMOTE_PLAYER_CONTROL_POINT` | **STRONG CANDIDATE** (sin cambio) — nivel C descartado como suficiente por sí solo; el punto de control válido para locomoción natural es **nivel B** (hook `0x14203E0`), pendiente de probar |

**Cadena `object+0x4B90 → object+0x5000 → EMA char+0x30`: RUNTIME VERIFIED
por inyección.** El gap para locomoción natural = `char+0x04` (estado
deseado / action code `char+0x12`).

## 9 — Siguiente paso seguro (NO ejecutado, NO autorizado)

Diseñar NATURAL MOVEMENT TEST 02 = **nivel B**: hook read-through de `0x14203E0`
para LOCAL_PLAYER que sustituya el comando producido en `g_scratch`
(`module_base+0x63F16B0`) por el comando remoto capturado, dejando correr el
resto del update per-actor (para que `char+0x04` enganche walk de forma natural).
Alternativa mínima: probar si escribir *también* `character[group]+0x12` (action
code capturado, p.ej. el `entry[7]` que corresponde a walk) junto con el raw
command hace que `0x14249A0` integre. Requiere identificar el valor de
`char+0x12` durante el walk capturado (dato disponible en `capture_fwd2`:
`char+0x12` durante `char+0x04 = 0x26`).

**NO probar** backward/left/right/run/AI_PARTNER/attack/jump. Una sola ejecución
por autorización.

## 10 — Evidencia

`docs/research/locomotion/natural_movement_test_01/`
- `capture_fwd2/capture.json` (recortado a la ventana de movimiento),
  `capture_fwd2/chosen_raw_command.bin`
- `run01/pre_write.json` (gates + backup), `run01/idle_raw_4b90.bin`,
  `run01/inject_command.bin`, `run01/restore_raw_4b90.bin`,
  `run01/result.json` (observación completa + decay + post-test + análisis)
- `tools/raw_command_movement_test.py`
