# FASE 13 — Cadena de control de locomoción (input / AI → movimiento)

Estado: 2026-09-08, tras `bdc52f4`. **Solo lectura / observación.** Sin escrituras
de memoria del juego, sin repetir teleport, sin modificar `+0x4B80`/`+0x4BC0`/
`char+0x30`/AI_PARTNER, sin hooks de gameplay, sin networking, sin cambios en
`core.dll`/EXE/Proton/sysctl. `gdb` solo con watchpoints de solo observación +
`detach`. Proceso vivo tras la sesión (PID 14042), hook Sigma2 re-verificado.

## 0. Punto de partida (Fase 12)

`object + 0x4B80` = `CANONICAL_POSITION_RUNTIME_VERIFIED`. W1 (`0x141BB90`)
integra `object+0x4B80 += movement_delta`; el `movement_delta` lo construye la
actualización per-actor `0x14249A0` como `movement_vector * scale`, con clamp de
velocidad. `+0x4BC0` = velocity. Objetivo Fase 13: encontrar de dónde sale
`movement_vector` — la cadena input/controller → velocity → locomotion → `+0x4B80`.

## 1. Reconstrucción de la cadena W1 (estático, volcado `.text` de la Fase 11)

`0x14249A0` (≈21 KB, `.pdata` `0x14249A0`–`0x1429E38`) es una **máquina de estados
per-actor**:
- Al entrar: `[rsp+0x50]` (vector de movimiento local) se **pone a cero**
  (`0x1424A19` `xorps xmm0,xmm0; movdqa [rsp+0x50],xmm0`).
- Despacho por **jump table** (RVA `0x1429C28` offsets, `0x1429D58` índices)
  indexado por `character[group]+0x04` (el **state code de locomoción**).
- El handler de "moviéndose" acumula términos en `[rsp+0x50]` (dirección×magnitud,
  incluyendo términos de homing relativos a `target+0x4B80`), luego:
  - **speed-clamp** a `0x1469F60()*const`. `0x1469F60` devuelve un `int32` de un
    **global de config** (`.data`, con guard de init perezoso) → es un **máximo por
    frame global**, no per-actor (walk vs run va en la magnitud del vector de
    input, no en el cap).
  - copia el vector clampeado a `[rbp-0x50]` (`call 0x6FB20`, copia de 16 B).
  - **W1 `0x141BB90`** @ `0x1429B92`: `object+0x4B80 += [rbp-0x50]`.
- `character[group]+0x3F0` se lee dentro del handler para un **check de ángulo/giro**
  (`0x6FF70` = producto escalar; `char+0x3F0` = `(0,1,0)` constante en reposo — un
  eje de referencia, **no** el vector de movimiento).

`0x1420F60` (dispatcher, `.pdata` `0x1420F60`–`0x14215C3`) resuelve
`&game_object[edx]` (`module_base+0x3195300`, `edx*0x30`), lo publica en un global
y llama `0x14249A0` @ `0x14211C5`.

## 2. `character[group] + 0x20 .. +0x4C` — bloque de comando de movimiento

Diferencia estructural IDLE vs MOVE (`tools/locomotion_probe.py`, capturas
`LOCO_IDLE` / `LOCO_MOVE_A` (fwd) / `LOCO_MOVE_B` (lateral)):

| offset | contenido | IDLE | MOVE_A (fwd) | MOVE_B (lateral) | rol |
|---|---|---|---|---|---|
| `char + 0x04` (byte) | **state code de locomoción** | `0x00` | `0x06→0x26→0x28→0x2A` | `0x0A→0x06→0x26` | **animación: idle / start / walk / run** (§7) |
| `char + 0x24` (float) | parámetro de locomoción del estado actual | `~0.88` (decae) | `~0.83` | `~0.86` | escrito por `0xF1ECA0` desde una **tabla de params** `r15 + anim_id*0x40 + 0x1BA0`; **NO** es magnitud de stick |
| `char + 0x30` (float4) | **vector de dirección de movimiento (suavizado)** | `(0,0,0,0)` | `(0.047, 0, -0.006, 0.968)` | `(-0.013, 0, 0.028, 0.998)` | **cero en reposo; específico de dirección al moverse; presente e idéntico en LOCAL_PLAYER y AI_PARTNER** |
| `char + 0x4C` (float) | flag/peso "input este frame" | `0.0` | `1.0` (player mientras hay input) | `0.0` | — |

`char+0x30` de Momiji: `(0,0,0,0)` en IDLE **y** en MOVE_B (no se movió);
`(-0.0096, 0.0003, 0.0321, 0.9992)` en MOVE_A (siguió a Ryu). ⇒ `char+0x30` es
el **comando de movimiento per-actor**, no-cero solo cuando el actor se mueve de
verdad, para jugador local **y** para IA.

Copias de `char+0x30`: `char+0xFB0` (fn `0xF33D97`-region), `obj+0x4BA0`/`+0x4BA8`
(un 2D `(dir_x, dir_z)` world-space que rotó ~90° entre MOVE_A y MOVE_B),
`char+0x680`/`+0x688`.

## 3. `object + 0x4BC0` (velocity) — resultado DERIVADO, no entrada

Burst durante MOVE_A: `|+0x4BC0|` sube `0.32 → 2.71` de forma **gradual** (~0.06/frame,
ease-in de ~0.5 s) y cae a ~0 al soltar; para Momiji en crucero es estable ~1.5.
`+0x4BC0` **retrasa** al comando de dirección `char+0x30` (que ya está suavizado).
Writers (Fase 12 + `0x14218C0`/`0x14219A0`): copian un campo per-actor / leen
`manager+0x7D0` → `object+0x4BC0`. ⇒ **respuesta B) del plan §2: `+0x4BC0` es
velocity real suavizada, publicada para animación/cámara — NO la entrada de la
integración de locomoción.** La entrada de W1 es `char+0x30` (dirección) +
`char+0x24` (params).

## 4. Writer de `character[group] + 0x30` (capturado en movimiento)

Hardware write-watchpoint sobre `char[0]+0x30` (Ryu), 44 hits durante movimiento,
**todos en pc `0xF25059`**, thread `14115 "Updating"`:

- Instrucción: `0xF25054  movdqu xmmword ptr [rcx + 0x30], xmm3` (`rcx =
  character[0]`).
- Función: **`0xF24F4A`–`0xF25349`** (`.pdata`, unwind `0x1B91118`). Cuerpo
  relevante:
  ```
  0xF24FA0  call 0xF1ECA0                     ; escribe char+0x20 params (tabla de anim)
  0xF24FD2  movups xmm3, [rcx + 0x30]         ; xmm3 = char+0x30 del frame anterior
  0xF24FD6  mulps  xmm3, [rip+0x9F0653]       ; xmm3 *= vec constante (factor de decaimiento)
  0xF24FE1  rax = tabla_base[rip+0x20815D8] + (contador[rip+0x11F97B9] + 0x4FF)*0x10   ; muestra de entrada
  0xF25001  addss xmm4, [rax]  ; +4 ; +8 ; +0xC   ; xmm(dir) = decayed_old + input_sample  (por componente)
  0xF2504C  mulps xmm3, [rip+0x9EFF02]         ; * vec constante (peso / normalización)
  0xF25054  movdqu [rcx + 0x30], xmm3          ; char+0x30 = (char+0x30_old*decay + sample)*weight
  ```
- Es un **filtro paso-bajo / media móvil exponencial** de una muestra de entrada
  por frame. La 4ª componente (`w`) hace ease-in observado `0.25 → 0.44 → 0.58 →
  0.68 → … → 0.987 → 0.9998` durante la aceleración (arranque de caminar).
- La muestra viene de una **tabla/ring indexado por un contador de frame** global
  (`[rip+0x11F97B9]` cursor, `[rip+0x20815D8]` base, entradas de `0x10` bytes).
  La aritmética RVA exacta de esos globales **no se confirmó** (los valores leídos
  no encajaron limpiamente); pendiente de precisar.
- Stack: `[+0x88]=0xF7FC8E [+0xC8]=0xF8044A [+0xF8]=0xF8C429 [+0x128]=0x1462167
  [+0x180]=0x1462160` → cadena `0xF7Fxxx`/`0xF80xxx`/`0xF8Cxxx` → dispatch
  "Updating" `0x1462160`. Es la pasada de **actualización de personaje**, no la de
  poll de input crudo (esa muestra ya está en la tabla).

`char[0]+0x24` (params) también se escribe cada frame en reposo (pc `0xF1ED89`
`movdqa [r14+0x20], xmm0`, `r14 = character[0]`, valor = fila de tabla
`r15 + anim_id*0x40 + 0x1BA0`) — confirma que `+0x24` es un **parámetro de
animación**, no input.

## 5. Orden temporal (§6)

```
dispositivo de input  ──┐
                        ▼  [poll -> muestra por frame en tabla/ring, cursor global]
                   input sample stream
                        ▼  [0xF24F4A: EMA  char+0x30 = char+0x30_old*decay + sample*weight]
        character[group] + 0x30   (comando de dirección suavizado, float4; w ease 0→1)   ◄── CONVERGENCIA
        character[group] + 0x04   (state code: idle/start/walk/run  →  ANIMACIÓN)
        character[group] + 0x24   (params de locomoción del estado, desde tabla de anim)
                        ▼  [0x14249A0 handler: delta = f(char+0x30, params), speed-clamp a 0x1469F60()*const]
        W1  0x141BB90 :  object+0x4B80 += delta
                        ▼  [derivado]
        object + 0x4BC0  velocity (suavizada, publicada para animación/cámara)
                        ▼
        object + 0x2B0 / ~14 copias de render   (Fase 11)
```

Clasificación de candidatos:
| campo | clase |
|---|---|
| tabla/ring de muestras de entrada (`[rip+0x20815D8]`, cursor `[rip+0x11F97B9]`) | **INPUT_SOURCE** (dirección RVA sin confirmar) |
| `character[group] + 0x30` | **MOVEMENT_CONTROLLER / desired-direction (suavizada)** — punto de convergencia |
| `character[group] + 0x04` | **MOVEMENT_STATE / animation selector** |
| `character[group] + 0x24` | parámetro de locomoción (tabla de animación) |
| `object + 0x4BC0` | **DERIVED_VELOCITY** (velocity real suavizada) |
| `object + 0x4B90` | residual/delta por frame pequeño (sigue la dirección) |
| `character[group] + 0x3F0` | eje de referencia `(0,1,0)` para check de ángulo — no locomoción |

## 6. Animación (§7)

**`character[group] + 0x04` = la señal que diferencia quieto / caminando /
corriendo.** Valores observados: `0x00` idle; `0x06` start/transición; `0x0A`
lateral start; `0x26` (38) walk; `0x28` (40) walk→run; `0x2A` (42) run; `0x48`
(72) run de la IA. Es un enum **compartido** LOCAL_PLAYER / AI_PARTNER, y es el
selector de la jump table de `0x14249A0`. Un jugador remoto que solo escriba
`object+0x4B80` (teleport) dejaría `char+0x04 = 0` → sin animación de locomoción
(exactamente lo que el usuario observó en MVP 2B +10.0). Para movimiento natural
hay que alimentar `char+0x30` (dirección) para que la máquina de estados ponga
`char+0x04` en el estado de walk/run y `0x14249A0` integre el delta.

## 7. AI_PARTNER (§8–§9)

- `game_object[4]` (Momiji): **mismo layout** `char[group]+0x30` / `+0x04` /
  `+0x24`. `char[1]+0x30` = `(0,0,0,0)` cuando no se mueve; no-cero cuando siguió
  a Ryu (MOVE_A). `char+0x04` recorre el **mismo enum** (incl. `0x48` run de IA).
- **No se capturó el writer de `char[1]+0x30`** (Momiji se movió poco bajo el
  watchpoint). El ring de input (`[rip+0x20815D8]`) es un **global único** → es la
  historia de input del **jugador local**; la IA no lo usa: su cerebro debe
  escribir `char[4]+0x30` (o su filtro) por otra ruta.
- **Punto de convergencia = `character[group] + 0x30`**: `0x14249A0` (+ el clamp +
  W1) lo consume **igual** para cualquier actor, sea la fuente input local o
  cerebro de IA. `character[group] + 0x04` (state code) y `+0x24` (params) son
  igualmente compartidos.

`REMOTE_CONTROL_INJECTION_CANDIDATE = character[group] + 0x30`
(+ mantener/permitir que `character[group] + 0x04` evolucione a los estados de
locomoción). **STRONG CANDIDATE**, no RUNTIME VERIFIED: falta capturar el writer
de la IA sobre `char+0x30` para probar que ambas rutas convergen ahí, y precisar
si escribir `char+0x30` directamente basta o hay que alimentar la muestra de
input aguas arriba (el filtro EMA `0xF24F4A` podría amortiguar una inyección
directa en `char+0x30` hacia 0 en pocos frames, igual que `0xF33D97`/W2 con
`+0x4B80`).

## 8. Caracterización del comando de movimiento (§10)

| propiedad | valor |
|---|---|
| representation | **float4** en `character[group]+0x30`; x/z = dirección horizontal, y≈0, w = factor de blend/confianza (ease 0→1) |
| idle value | `(0, 0, 0, 0)` |
| forward value (MOVE_A) | `(0.047, 0, -0.006, 0.968)` → estable `(0.054, 0, -0.011, 1.0)` |
| sideways value (MOVE_B) | `(-0.013, 0, 0.028, 0.998)` → `(-0.098, 0, 0.007, 1.0)` |
| magnitud | ~unitaria una vez `w→1` (x²+z²+w²≈1); la "velocidad" (walk/run) la fija `char+0x04`/params, no la longitud |
| lifetime | **per-frame**, suavizado (EMA); persiste con decaimiento tras soltar el control (`w` vuelve hacia 0) |
| escritor | `0xF25054` (`movdqu [char+0x30], xmm3`) en `0xF24F4A`, hilo "Updating" |

## 9. `=== NEXT EXPERIMENT PLAN ===` (solo diseño — NO ejecutar)

Objetivo futuro: **movimiento natural del LOCAL_PLAYER** (Ryu camina/corre con
animación), **sin teleport**.

| campo | valor |
|---|---|
| Target | `character[group] + 0x30` (float4 dirección) del LOCAL_PLAYER, resuelto desde cero. Posiblemente también permitir/observar `character[group]+0x04`. |
| Desired test | escribir una dirección unitaria pequeña (p. ej. `(0, 0, 1, 1)` = "adelante local") en `char+0x30` durante N frames consecutivos (el filtro EMA exige varios frames), en `LOCAL_PLAYER_STABLE` con `+0x4BC0 ≈ 0`, sin input humano simultáneo. |
| Expected | `char+0x04` pasa a un estado de walk (`0x06`→`0x26`); `0x14249A0` integra `object+0x4B80 += dir*params` con clamp; **Ryu camina con animación normal**; `+0x4BC0` sube gradualmente; al dejar de escribir, `char+0x30` decae y Ryu se detiene. |
| Teleport expected | **NO** (delta por frame acotado por el speed-clamp `0x1469F60()`). |
| Guards | proceso único / TracerPid 0 · SHA256 EXE+core · slot Sigma2 · resolver LOCAL_PLAYER + `char[group]+0x00 == 0x00` · `LOCAL_PLAYER_STABLE` + `|+0x4BC0| < 0.05` · sin input humano · backup de `char+0x30` (16 B) · escritura **repetida por ≤ ~30 frames** con restauración (poner `char+0x30` a `(0,0,0,0)` y soltar) · ventana total ≤ 5 s · abortar si Y se mueve > 0.1 o el proceso cambia. |
| Rollback | escribir `(0,0,0,0)` en `char+0x30`; verificar que `char+0x04` vuelve a `0` y Ryu se detiene; restaurar los 16 B originales. |
| Execution authorized | **NO.** |

Antes de ese experimento conviene: (a) capturar el writer de `char[1]+0x30` con
Momiji en movimiento para confirmar la convergencia IA↔input; (b) precisar la
tabla/ring de input (`[rip+0x20815D8]`); (c) confirmar si el filtro EMA
`0xF24F4A` sobrescribe una inyección directa en `char+0x30`.

## 10. Herramientas / evidencia

- `tools/locomotion_probe.py` (solo lectura): snapshot de `character[group]` +
  ventana de `object`, burst de state/velocity/pos, `--compare`.
- `docs/research/locomotion/`: `LOCO_IDLE.json`, `LOCO_MOVE_A.json`,
  `LOCO_MOVE_B.json` (pre/post + globals; burst recortado),
  `watch_char30_dir_moving.txt` (44 hits del writer `0xF25059`),
  `watch_char24_speed_idle.txt`, `awatch_char_movecmd_idle.txt`,
  `wp_char30_dir.gdb`.
- Análisis offline con el volcado `.text` de la Fase 11
  (`docs/research/runtime_text/20260907T1650Z_pid14042/`) + `tools/rt_image.py`.

## 11. Restricciones respetadas

Sin escrituras en memoria del juego. `char+0x30`/`+0x04`/`+0x24`/`+0x4B80`/
`+0x4BC0` y AI_PARTNER solo leídos/observados. Sin hooks nuevos. Sin networking.
Sin cambios en EXE / `core.dll` / Proton / sysctl. `gdb` solo con watchpoints de
observación + `detach`; proceso vivo, hook Sigma2 re-verificado. Sin `git push`.

---

## 12. FASE 13b — writer del comando de movimiento del AI_PARTNER (capturado)

Autorizado por el usuario: **solo captura read-only** del writer de `char[1]+0x30`
mientras Momiji se mueve. Hardware write-watchpoints sobre `char[1]+0x30` (XY) y
`+0x38` (ZW), 46 hits mientras Momiji seguía a Ryu.

AI_PARTNER re-resuelto desde cero: `game_object[4]` → obj RVA `0x319cdb0`, grp 1,
id 221, `char[1]` RVA `0x2F79D50` (`char[1]+0x30` abs `0x142F79D80`).

**Writer capturado — IDÉNTICO al del LOCAL_PLAYER:**

| | LOCAL_PLAYER (Fase 13) | AI_PARTNER (Fase 13b) |
|---|---|---|
| writer RVA | `0xF25054` (`movdqu [rcx+0x30], xmm3`) | **`0xF25054`** (misma instrucción) |
| función | `0xF24F4A`–`0xF25349` | **`0xF24F4A`** (misma) |
| thread | `14115 "Updating"` | **`14115 "Updating"`** |
| call stack | `[+0x88]=0xF7FC8E [+0xC8]=0xF8044A [+0xF8]=0xF8C429 [+0x128]=0x1462167 [+0x180]=0x1462160` | **byte-idéntica** |
| `rcx` (destino) | `character[0]` (`0x142F78B10`) | `character[1]` (`0x142F79D50`) |
| `rdi` (índice de actor) | `0` | `4` |
| `r14` | `0x143195300` (`&game_object[0]`) | `0x1431953C0` (`&game_object[4]`) |
| filtro | EMA `char+0x30 = old*decay + sample*weight` | **misma fórmula, misma curva** (`w` ease-in `0.25→1.0`) |
| state code `char+0x04` | `0x06→0x26→0x28→0x2A` | **`0x06→0x26→0x28`** (mismo enum) |

`0xF24F4A` se llama **una vez por actor por frame** (índice del actor en `rdi`/`r14`).
Lee el **sample de comando de movimiento per-actor** y lo filtra hacia
`character[group]+0x30`.

### Punto de convergencia REAL: `object + 0x5000`

En `0xF24FE1`: `rax = [module_base+0x2FA65C0] + (idx+0x4FF)*0x10`, que resuelve a
**`object + 0x5000`** para el actor en curso (verificado: Ryu sample @
`0x14319C100` = `obj 0x143197100 + 0x5000`; Momiji sample @ `0x1431A1DB0` =
`obj 0x14319CDB0 + 0x5000`). `object+0x5000` (float4) = `(0,0,0,0)` en reposo
para ambos.

```
local input polling  ──┐
                       ▼  [escribe object+0x5000  = comando de dirección per-frame]
AI brain (Momiji)   ──┘
                       ▼  [0xF24F4A: EMA  char[group]+0x30 = char+0x30_old*decay + [object+0x5000]*weight]
        character[group] + 0x30
                       ▼  [0x14249A0 -> speed-clamp -> W1 0x141BB90]
        object + 0x4B80
```

**`object + 0x5000`** es la **primera representación común** entre la ruta de
input local y la ruta del cerebro de IA. Desde ahí (`0xF24F4A` → `char+0x30` →
`0x14249A0` → W1) el camino es **100 % compartido** (mismo código, mismo thread,
misma pila, capturado en vivo para los dos actores).

`REMOTE_CONTROL_INJECTION_CANDIDATE` (revisado):
- **`object + 0x5000`** (float4, comando de dirección per-frame) — el punto donde
  input local y cerebro de IA convergen; escribir aquí alimentaría el EMA de forma
  natural (como el stick / la IA).
- `character[group] + 0x30` (dirección suavizada) — alternativa aguas abajo, pero
  el EMA la re-deriva de `object+0x5000` cada frame, así que una escritura directa
  se amortiguaría en pocos frames.

### Estado del punto de convergencia

`character[group]+0x30` como **ruta de locomoción compartida** LOCAL_PLAYER /
AI_PARTNER: **RUNTIME VERIFIED** — mismo writer (`0xF25054` / `0xF24F4A`), mismo
thread, misma pila, mismo EMA, mismo enum de state, capturado en vivo para ambos.

`object + 0x5000` como **punto de convergencia input↔IA**: **STRONG CANDIDATE**
(la fórmula resuelve a `obj+0x5000` y es `(0,0,0,0)` en reposo para ambos; falta
capturar en vivo el writer de `object+0x5000` — el poll de input / el cerebro de
IA — para marcarlo RUNTIME VERIFIED; no se hizo por acotar la sesión y no escribir).

`REMOTE_CONTROL_INJECTION_CANDIDATE = object + 0x5000` (float4). **NO escrito.**

Evidencia: `docs/research/locomotion/watch_ai_char30_moving.txt` (46 hits),
`wp_ai_char30.gdb`.


## FASE 13c — fuente de `object+0x5000` (2026-09-08)

Detalle: **[REMOTE_CONTROL_INJECTION_RESEARCH.md](REMOTE_CONTROL_INJECTION_RESEARCH.md)**. Solo observación (write-watchpoints + `detach`).

- **Writer de `object+0x5000` = `0xFF2E0B` en `0xFF282A`** (bucle per-actor sobre `game_object` table, `lea rcx,[r14+0x3195326]`), hilo "Updating". **Idéntico para LOCAL_PLAYER y AI_PARTNER** (46 hits cada uno; solo cambia `rsi` = obj del actor). Call stack byte-idéntica.
- `object+0x5000 = *(float4*)(object + 0x5C06 + off_tabla)` — `0xFF282A` copia desde el **área de comando crudo per-actor `object + ~0x5C06`** a `object + 0x5000`. La divergencia **input local (Ryu) vs cerebro de IA (Momiji)** está aguas arriba, en quién rellena `object + ~0x5C00` — **NO capturado**.
- Representación: float4, `(0,0,0,0)` en reposo (campo no escrito), `(dir_x, ~0, dir_z, w=1)` al moverse; **mismo formato ambos actores**.
- `REMOTE_CONTROL_INJECTION` = **STRONG CANDIDATE**: nivel de inyección preferido = `object + ~0x5C00` (comando crudo) o re-escritura per-frame de `object+0x5000`; `char+0x30` directo lo amortigua el EMA. Player 2 remoto sobre Ryu no requiere tocar la IA; sobre Momiji sí (neutralizar el cerebro que escribe su `object + ~0x5C00`). Experimento de movimiento natural: solo diseñado, NO ejecutado, NO autorizado.


## FASE 14 — fuente cruda del comando de movimiento por actor (2026-09-08)

Detalle: **[RAW_MOVEMENT_COMMAND_RESEARCH.md](RAW_MOVEMENT_COMMAND_RESEARCH.md)**. Solo observación (hardware watchpoints + `detach`).

- **El "área de comando crudo per-actor" de la Fase 13c queda pinneada a `object + 0x4B90`** (float4, en el bloque de estado de movimiento: `+0x4B80` posición · **`+0x4B90` comando crudo** · `+0x4BA0` facing · `+0x4BC0` velocity · `+0x4BD0` cápsula). `0xFF282A` copia `object+0x4B90 → object+0x5000` con offset exacto `0x5C06 - 0x1076` (`rdi = 1` para Ryu **y** Momiji). `object+0x5000` va **1 frame por detrás** de `object+0x4B90`. `(0,0,0,0)` en reposo ambos actores.
- **Writer de `object+0x4B90` (LOCAL_PLAYER, capturado):** `0x14210A0` (`movdqu [rax+0x4B90], xmm4`, `rax` = object) en el **bucle per-actor `0x1420F60`–`0x14215C3`**, hilo "Updating" — 50 hits, todos Ryu. Caller `0x142C499` en `0x142C460` (`for edx = 0 .. 0xA0 { call 0x1420F60(edx) }`). Lógica de `0x1420F60`:
  ```
  rax = &game_object[edx] ;  rdx = object ;  rcx = character[group]
  if byte[object + 0x5B56] == 0:  movdqu [object+0x4B90], 0   ; sin comando -> ret
  else:  [module_base+0x63F16B0] = 0 ; call 0x14203E0 ; xmm4 = [0x63F16B0] + character[group][0xFA0]
         movdqu [object+0x4B90], xmm4
  ```
- `[module_base + 0x63F16B0]` = **scratch global float4** del comando; `0x14203E0` lo rellena por actor (`0x1420F60` lo pone a 0 en `0x142101B` y llama `0x14203E0` en `0x1421032`). Watchpoint sobre `[0x63F16B0]`: 46 hits/idle, 2 writers alternando — `0x142101B` (el zero) y `0x142082B` (dentro del árbol de `0x14203E0`, fn `0x142015B`–`0x142099E`).
- `character[group] + 0xFA0` = término aditivo per-actor; **`(0,0,0,0)` para Ryu y Momiji** — watchpoint WRITE: **0 hits** durante movimiento (no se usa en este escenario; posible aim-assist / nudge).
- **`0x14203E0` = RAW_COMMAND_PRODUCER.** Head: lee manager de input `[rip+0x4FD12B0]` (campos byte `+0x12`/`+0x13`/`+0xF8A`/`+0xF85`, `0xFF` = sin asignar; gate `+0xC` → si `!= 0` fuerza `bl = 0xFF`, posible bloqueo de input = **`CONTROL_MODE_CANDIDATE`**), managers `[rip+0x4FD1215]` (`word +0x1FA` = state) y `[rip+0x4FD11DF]` (gate object `+0x5B6D`, el mismo que `0xF7BB70`), jump-table interna. **La rama exacta input-device (Ryu) vs AI-brain (Momiji) DENTRO de `0x14203E0` NO se aisló.**
- **AI_PARTNER:** `0x1420F60` se ejecuta en el **mismo bucle** `for edx = 0 .. 0xA0` para **todos** los actores ⇒ el writer de `object+0x4B90` de Momiji es el mismo `0x14210A0` / `0x1420F60` / `0x14203E0`. El watchpoint combinado no disparó en la dirección de Momiji (Ryu, edx 0, llenó el `MAX=50` antes que edx 4). **Falta captura Momiji-only en runtime.**
- **Divergencia** = dentro de `0x14203E0` (sin aislar). **Convergencia** = `object + 0x4B90` (writer compartido `0x14210A0`). De ahí abajo (`0xFF282A` → `object+0x5000` → EMA `0xF24F4A` → `char+0x30` → `0x14249A0` → W1) = código compartido RUNTIME VERIFIED.
- Representación del raw command: **float4**, `(0,0,0,0)` idle, `(dx, ~0, dz, w=1)` activo (`w` = comando activo); mismo layout `object+0x4B90` == `object+0x5000`; 1×/actor/frame; per-frame (no persiste solo).
- **`REMOTE_PLAYER_CONTROL_POINT` (candidato): `object + 0x4B90`** reescrito cada frame **después** de `0x1420F60`, o hook de `0x14203E0` / del escritor `0x1420833` de `[0x63F16B0]`. Downstream 100 % compartido y verificado, produce locomoción + animación naturales, delta acotado por el speed-clamp (sin teleport). `char+0x30` directo lo amortigua el EMA. Player 2 remoto sobre Ryu = bloquear el poll de input (hook de `0x14203E0` o el `CONTROL_MODE_CANDIDATE`); sobre Momiji = neutralizar la rama de IA dentro de `0x14203E0`.
- `REMOTE_CONTROL_INJECTION` = **STRONG CANDIDATE**. Falta: writer de `object+0x4B90` de Momiji en runtime; aislar la rama input↔IA de `0x14203E0`; confirmar `CONTROL_MODE_CANDIDATE`. Experimento de movimiento natural: solo diseñado, NO ejecutado, NO autorizado.
- Evidencia: `docs/research/locomotion/watch_ryu_obj4B90_moving.txt` (50 hits), `watch_gcmd_63F16B0.txt`, `watch_charFA0_none.txt` (0 hits), `wp_4b90.gdb`, `wp_g5b0.gdb`.


## FASE 15 — AI raw command confirmado + divergencia de control (2026-09-08)

Detalle: **[RAW_MOVEMENT_COMMAND_RESEARCH.md](RAW_MOVEMENT_COMMAND_RESEARCH.md)** §15. Solo observación (hardware watchpoints + `detach`).

- **`RAW_COMMAND_SHARED_WRITER = RUNTIME VERIFIED.`** Watchpoint sobre `MOMIJI object+0x4B90`: 40/40 hits en `0x14210A0` (`movdqu [rax+0x4B90], xmm4`), fn `0x1420F60`, thread "Updating", call stack byte-idéntica a Ryu, `rbx = 4` (índice de actor), `r9 = char[1]`, `xmm4 = [module_base+0x63F16B0] + char[1]+0xFA0` (fórmula idéntica), `object+0x5000` 1 frame por detrás, `char[1]+0x04` `0x06→0x26`.
- **`0x14203E0` es un chunk de una función per-actor GENÉRICA** (`~0x142015B–0x1420BF9`, encadenada). Sus punteros base son globales de bucle per-actor fijados por `0x1420F60`: `[rip+0x4FD12B0] = G_CHARACTER` (`0x63F16A8`), `[rip+0x4FD11DF]/4FD1271 = G_OBJECT` (`0x63F16A0`), `[rip+0x4FD112C] = G_GO_REC` (`0x63F1698`), store del comando `[rip+0x4FD0E7D] = g_scratch` (`0x63F16B0`). **Corrección Fase 14:** `[rip+0x4FD12B0]` NO es un "manager de input" — es `character[group]`; los bytes `[r9+0x12]`/`[r9+0x13]`/`[r9+0x0C]`/`[r9+0xF8A]`/`[r9+0xF85]` son campos de `character[group]`.
- `0x14203E0` lee el **action code** `char[group]+0x12` (fallback `+0x13`), y **NO ramifica por local/IA**. Única branch relevante: `0x142046B cmp byte [char[group]+0x0C], 0 ; 0x1420475 cmovne ebx, 0xFF` = **control-lock** (`!=0` ⇒ sin acción ⇒ `0x14204B4 je` ⇒ `g_scratch=0` ⇒ `object+0x4B90=(0,0,0,0)`). `char+0x0C = 0x00` para Ryu **y** Momiji (no es el discriminador). W2 (`0x14208DD`, commit de `object+0x4B80`, Fase 12) está DENTRO de esta misma función.
- **El writer de los action codes `char[group]+0x12` también es COMPARTIDO**: watchpoint sobre `char0+0x10`/`char1+0x10` (60 hits) → 3 RVAs (`0xF1ED0F` en `0xF1ECA0`; `0xF24BF7`; `0xF2480C`), **todas compartidas Ryu/Momiji, call stacks byte-idénticas**. `char[group]+0x12 = call 0xF88C40(...) ? result[7] : 0xFF` (lookup genérico en tabla de descriptores de acción; 41 call sites). `0xF1ECA0` corre dentro del árbol `0xF24F4A` (el del EMA de `char+0x30`).
- **La divergencia local↔IA NO está en la ruta del comando de movimiento** — toda `0xF1ECA0 → 0x14203E0 → 0x1420F60 → object+0x4B90 → 0xFF282A → object+0x5000 → EMA → char+0x30 → 0x14249A0 → W1` es código compartido genérico per-actor, RUNTIME VERIFIED para ambos. La divergencia está en la **capa de comportamiento / estado deseado** aguas arriba de `0xF1ECA0` (para Momiji: región `0xF31D8D–0xF324E5` / `0xF7BDE0–0xF7BE85` en la call stack — **no reconstruida**; para Ryu: el traductor input físico → estado deseado — **no localizado**). Discriminador de clase = `character[group]+0x00` (`0x00` local / `0x04` IA).
- **Clasificación:** `character[group]+0x00`, `character[group]+0x0C`, `object+0x5B56` = **CONTROL_MODE_CANDIDATE**. `[rip+0x4FD12B0]/4FD1215/4FD11DF/4FD112C` = **REJECTED** (son `G_CHARACTER`/`G_OBJECT`/`G_GO_REC`). Índice de actor (`rbx=4`, `G_ACTOR_INDEX 0x63F1690`) = **REJECTED** (var de bucle). Región `0xF31D8D`/`0xF7BDE0` = **AI_CONTROLLER_CANDIDATE**. Traductor de input de Ryu = **LOCAL_INPUT_OWNER_CANDIDATE** (sin dirección).
- **`AI_COMMAND_SOURCE_STRONG_CANDIDATE`** — entra por `char[1]+0x12/+0x13` + estado deseado; capa de comportamiento identificada en la pila, no reconstruida.
- **`PREFERRED_REMOTE_CONTROL_LEVEL = C`** (reescribir `object+0x4B90` cada frame tras `0x14210A0`: el más simple, downstream 100 % compartido y verificado, network-friendly), con **B** (hook de `0x14203E0` / `g_scratch`) como opción "más correcta". **Caveat C** (como MVP 2B): si el motor no lleva `char[group]+0x04` a walk, `0x14249A0` no integra el delta ⇒ posición sin animación; el test debe medirlo y escalar a B/A si hace falta.
- **`REMOTE_PLAYER_CONTROL_POINT = STRONG CANDIDATE`** (no RUNTIME VERIFIED: falta la branch local↔IA y la fuente de IA reconstruida). Confianza: ALTA en "`object+0x4B90` raw command compartido + downstream verificado ambos actores"; MEDIA en "reescribir sólo el raw command produce locomoción natural completa".
- Test de movimiento natural: **sólo diseñado** (RAW_MOVEMENT_COMMAND_RESEARCH.md §15.11), Execution authorized = **NO**.
- Evidencia: `docs/research/locomotion/watch_momiji_obj4B90_moving.txt` (40 hits), `watch_char12_action_moving.txt` (60 hits), `wp_4b90_momiji.gdb`, `wp_char12.gdb`.


## FASE 16 — NATURAL MOVEMENT TEST 01 (2026-09-07)

Detalle: **[NATURAL_MOVEMENT_TEST_01.md](NATURAL_MOVEMENT_TEST_01.md)**. Primer experimento con escritura desde MVP 2B; autorizado (un único test sobre LOCAL_PLAYER). Herramienta `tools/raw_command_movement_test.py` (fail-closed). Solo se escribió `LOCAL_PLAYER object+0x4B90` (16 B); `object+0x4B80` NO se restauró (no hizo falta: no se movió). AI_PARTNER intacto. Sin crash, sin teleport, proceso estable, hook re-verificado. Sin `git push`.

- Comando humano REAL capturado (no inventado): sample de caminar recto (`char+0x04 = 0x26`), `object+0x4B90 = (-0.068983, 0.000632, -0.001078, 1.0)`, bytes `1c478dbd8ba4253ab0458dba0000803f`, `|xz| = 0.069`.
- Inyección: 192 writes de 16 B en `object+0x4B90` a ~96–125 Hz durante ~2.0 s, muestreo read-only del downstream.
- **Propagación (RUNTIME VERIFIED por inyección):** `object+0x4B90` → `object+0x5000` (latcheó `(-0.069,-0.0011)` casi toda la ventana vía `0xFF282A`) → EMA `0xF24F4A` → `char+0x30` (convergió a `(-0.059…-0.068,-0.001)`).
- **Gap:** `char+0x04` se mantuvo `0x00` (idle) TODO el tiempo ⇒ `0x14249A0` (keyed en `char+0x04`) no integró el delta ⇒ `object+0x4BC0` = 0, `object+0x4B80` sin cambio (Δ 0.000), sin animación. **Usuario: "RYU NO SE MOVIÓ".**
- **Resultado: PARTIAL.** Confirma el caveat C de la Fase 15: reescribir solo el raw command NO basta para locomoción natural. `char+0x04` lo produce la máquina de animación compartida (`0xF1ECA0` / capa `0xF31D8D`/`0xF7BDE0`) desde el **estado deseado / action code `char+0x12`**, NO desde la magnitud de `char+0x30`.
- Al cesar la inyección: `object+0x5000`/`char+0x30`/velocity/`char+0x04` decayeron a idle limpiamente; `object+0x4B90` restaurado EXACT.
- **`REMOTE_PLAYER_CONTROL_POINT` = STRONG CANDIDATE** (sin cambio). Nivel C (solo raw command) **descartado** como suficiente. El punto de control válido para locomoción natural = **nivel B** (hook `0x14203E0` / store `0x142082B` a `g_scratch`), o nivel A (alimentar también `char+0x12` / estado deseado). Pendiente de probar (NATURAL MOVEMENT TEST 02, no autorizado).
- Evidencia: `docs/research/locomotion/natural_movement_test_01/` (`capture_fwd2/`, `run01/pre_write.json`, `run01/result.json`).
