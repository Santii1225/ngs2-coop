# FASE 14 — Fuente cruda del comando de movimiento por actor

Estado: 2026-09-08, tras `3518715`. **Solo lectura / observación.** Sin escrituras
de memoria del juego, sin desactivar IA, sin inyectar input, sin networking, sin
hooks nuevos, sin cambios en `core.dll`/EXE/Proton/sysctl. `gdb` solo con hardware
watchpoints de observación + `detach`. Proceso vivo tras la sesión (PID 14042),
hook Sigma2 re-verificado.

## 0. Punto de partida (Fase 13c)

`object + 0x5000` (float4) = comando de dirección per-actor; `0xFF282A` (writer
`0xFF2E0B`, bucle per-actor) lo copia de **`object + ~0x5C06`** al `+0x5000`. La
divergencia input-local vs cerebro-IA está aguas arriba, sin identificar.

## 1. Offset exacto de la fuente que `0xFF282A` copia a `object+0x5000`

`0xFF282A` construye offsets negativos `const - rdi` en slots de pila. Para la
carga de `xmm0 → object+0x5000` (`0xFF2DF2  movaps xmm0, [rbx + rcx]`,
`0xFF2E0B  movdqa [rsi + rax*8], xmm0`):

- `rsi = object` · `rax = (rdi + 0x4FF) * 2 = 0xA00` (`rdi = 1` para Ryu **y**
  Momiji) ⇒ destino `object + 0xA00*8 = object + 0x5000`.
- `rbx = object + 0x5C06` · `rcx = [rsp+0x130] = (0xFFFFFFFFFFFFEF8B) - rdi =
  -0x1076` ⇒ fuente `object + 0x5C06 - 0x1076 = **object + 0x4B90**`.
- (`0xFF2DEC` en paralelo: `object + 0x4FE0 = object + 0x4B80` — mirror de la
  posición canónica, confirma el patrón.)

⇒ **`RAW_COMMAND_OFFSET = 0x4B90`**:
```
raw_command = *(float4*)(object + 0x4B90)
```
Bloque de estado de movimiento: `+0x4B80` posición · **`+0x4B90` comando crudo** ·
`+0x4BA0` facing (2D world) · `+0x4BC0` velocity · `+0x4BD0` cápsula.
`(0,0,0,0)` en reposo para LOCAL_PLAYER y AI_PARTNER; escrito por frame durante el
movimiento. `object + 0x5000` va **1 frame por detrás** de `object + 0x4B90`
(confirmado en el trace).

## 2. Writer de `object + 0x4B90` (LOCAL_PLAYER, capturado)

Hardware write-watchpoint sobre `RYU object+0x4B90`, 50 hits durante movimiento
con input humano, **todos en pc `0x14210A8`** (RVA), hilo `14115 "Updating"`.

- Instrucción: `0x14210A0  movdqu xmmword ptr [rax + 0x4B90], xmm4` (`rax =
  0x143197100` = obj de Ryu, de `[rip+0x4FD061C]`).
- Función: **`0x1420F60`–`0x14215C3`** (`.pdata`, unwind `0x1C0F554`) — **cuerpo
  del bucle per-actor** de movimiento. Caller `0x142C499` (en `0x142C460`) en un
  bucle `for edx = 0 .. 0xA0 { call 0x1420F60(edx) }`. Call stack:
  `[+0x38]=0x14142C49E  [+0x68]=0x141462167  [+0xC0]=0x141462160` (dispatch
  "Updating").
- Lógica de `0x1420F60(edx)`:
  ```
  rax = &game_object[edx] (module_base+0x3195300 + edx*0x30)
  [rip+0x4FD06F5] = rax        ; global: game_object record actual
  [rip+0x4FD06DE] = edx        ; global: índice de actor actual
  rdx = [rax] = object ptr ;  [rip+0x4FD06E4] = rdx
  rcx = character[group]   ;  [rip+0x4FD06BF] = rcx
  if  byte[object + 0x5B56] == 0:
        movdqu [object + 0x4B90], 0     ;  RAW_COMMAND = (0,0,0,0)   -> ret   (SIN COMANDO)
  else:
        [module_base + 0x63F16B0] = 0            ; limpia el scratch global del comando
        call 0x14203E0                            ; <<< PRODUCTOR DEL COMANDO (rellena 0x63F16B0)
        xmm2 = [module_base + 0x63F16B0]          ; lee el comando producido
        xmm4 = xmm2 + character[group][0xFA0 .. 0xFAC]   ; + término aditivo per-actor
        movdqu [object + 0x4B90], xmm4            ; RAW_COMMAND = comando + char[grp]+0xFA0
  ```
- `xmm4` (valor observado): `(0.0006, 0, -0.0032, 1.0)` → `(0.0376, 0, 0.0124,
  1.0)` → `(0.0388, 0, 0.0099, 1.0)` — dirección float4 con `w = 1.0`, cambia por
  frame.

**Writer source:** `object + 0x4B90 = [module_base + 0x63F16B0] +
character[group][0xFA0]`. `[0x63F16B0]` = scratch global (float4) que `0x14203E0`
rellena por actor; `character[group] + 0xFA0` = término aditivo per-actor
(`(0,0,0,0)` para Ryu y Momiji en reposo — no se escribió en el watchpoint de
`char+0xFA0`; posible aim-assist / nudge, sin uso en este escenario).

## 3. `0x14203E0` — productor del comando (divergencia input↔IA)

`.pdata` `0x14203E0`–`0x142040A` (primer chunk; función encadenada mayor). Head:

```
r9 = [rip+0x4FD12B0]                 ; MANAGER de input/comando
bl = byte[r9 + 0x12] ;  dl = byte[r9 + 0xF8A]       ; códigos de acción/eje
if bl == 0xFF:  rax=[rip+0x4FD1271]; cl = byte[rax + 0x5B80]; ...; bl = byte[r9+0x13]
if dl == 0xFF:  ...                 byte[r9 + 0xF85]; ...      dl = byte[r9+0x13]
if byte[r9 + 0xC] != 0:  bl = 0xFF  ; (¿modo bloqueado?)
... jump-table (cmp [rip+..], eax; jg) ...
r9 = [rip+0x4FD1215]
ax = word[r9 + 0x1FA]               ; state code, comparado con umbral global
rcx = [rip+0x4FD11DF] ;  al = byte[rcx + 0x5B6D]   ; gate del object (mismo que 0xF7BB70, Fase 11)
cmp byte[r9 + 7], 1
```

`[rip+0x4FD12B0]` / `[rip+0x4FD1215]` / `[rip+0x4FD11DF]` = **manager(s) de
comando/input**, con campos byte `+0x12`/`+0x13`/`+0xF8A`/`+0xF85` (códigos de
acción/eje mapeados; `0xFF` = sin asignar) y gates de object `+0x5B56`/`+0x5B6D`/
`+0x5B80`.

`0x14203E0` → … → **`0x1420833`** (`movdqa [rip+0x4FD0E7D], xmm0` → escribe
`[module_base + 0x63F16B0]`; RVA de la escritura confirmada por watchpoint: stack
`[+0x158]=0x1421037` = justo tras `call 0x14203E0` en `0x1420F60`). `0x1420833`
está en la función `0x142015B`–`0x142099E` (región de transform-commit de la
Fase 12); `xmm0` = un vector recompuesto `(-0.0000, 0, -0.0003, 1.0)`.

**La divergencia input local (Ryu) vs cerebro de IA (Momiji) está DENTRO de
`0x14203E0`** — no se aisló la rama exacta (input device vs AI brain) en esta
sesión. `0x14203E0` es el **`RAW_COMMAND_PRODUCER`**.

## 4. AI_PARTNER

`0x1420F60` se llama en el **mismo bucle** `for edx = 0 .. 0xA0` para **todos los
actores** (incl. Momiji, edx 4). Por tanto el writer de `object+0x4B90` de Momiji
es el **mismo** `0x14210A0` / `0x1420F60` / `0x14203E0`. El watchpoint sobre
`MOMIJI object+0x4B90` **no disparó** en la sesión combinada — Ryu llenó el
`MAX=50` primero (edx 0 va antes que edx 4 en cada frame). Estructuralmente:
mismo código, gate `object+0x5B56`, productor `0x14203E0`. **Falta una captura
Momiji-only para confirmarlo en runtime.**

## 5. Comparación LOCAL vs IA

```
LOCAL_PLAYER (Ryu)                        AI_PARTNER (Momiji)
  input device / poll                       AI brain / controller
        │                                          │
        └────────►  0x14203E0  ◄──────────────────┘   (RAW_COMMAND_PRODUCER; divergencia interna sin aislar)
                       │  escribe [module_base + 0x63F16B0]  (scratch global, per-actor)
                       ▼
        object + 0x4B90 = [0x63F16B0] + character[group][0xFA0]     (writer 0x14210A0 en 0x1420F60, per-actor)  ◄── CONVERGENCIA
                       ▼  0xFF282A @ 0xFF2E0B (siguiente frame)
        object + 0x5000
                       ▼  0xF24F4A EMA
        character[group] + 0x30
                       ▼  0x14249A0 → speed-clamp 0x1469F60() → W1 0x141BB90
        object + 0x4B80   (CANONICAL_POSITION_RUNTIME_VERIFIED)
```

- **Divergence point:** dentro de `0x14203E0` (productor del comando). No aislado
  (input device vs AI brain).
- **Convergence point:** **`object + 0x4B90`** (RAW_COMMAND per-actor), escrito por
  el writer compartido `0x14210A0` en el bucle per-actor `0x1420F60`. Desde ahí
  hacia abajo (`0xFF282A` → `object+0x5000` → EMA → `char+0x30` → `0x14249A0` →
  W1) es **código compartido y RUNTIME VERIFIED** (Fases 12/13).

## 6. Representación del raw command

| propiedad | valor |
|---|---|
| representation | **float4** en `object + 0x4B90` (y en el scratch `[0x63F16B0]`) |
| idle | `(0, 0, 0, 0)` (campo no escrito; `0x1420F60` lo pone a 0 si `object+0x5B56` == 0) |
| forward / side | `(dx, ~0, dz, 1.0)` — x/z = delta de dirección por frame, `w = 1.0` = comando activo; el signo de x/z sigue la dirección |
| magnitude | pequeña por componente (delta por frame antes del EMA/clamp) |
| active flag | `w` (componente 4) = `1.0` cuando hay comando |
| frequency | 1×/actor/frame (hilo "Updating") |
| lifetime | per-frame; `0xFF282A` lo copia a `object+0x5000` al frame siguiente; no persiste solo |
| **misma representación antes de `object+0x5000`** | **YES** — `object+0x4B90` y `object+0x5000` tienen el mismo layout float4; `object+0x5000` = copia de `object+0x4B90` |

## 7. Punto de inyección remota (§9 — solo análisis)

| nivel | locomoción natural | animación | EMA | carrera | IA sobrescribe | networking | ¿desactivar IA? |
|---|---|---|---|---|---|---|---|
| **A) raw command source (`0x14203E0` / `[0x63F16B0]`)** | ✅ ideal | ✅ (`char+0x04` evoluciona) | pasa por el EMA (natural) | alta (per-frame) | sí — `0x14203E0` lo re-produce cada frame | requiere hook de `0x14203E0` o un flag | Ryu: no; Momiji: sí |
| **B) `object + 0x4B90` reescrito cada frame** | ✅ (es el RAW_COMMAND) | ✅ | pasa por el EMA | media — `0x1420F60` lo re-escribe cada frame; escribir **después** de `0x1420F60` | `0x1420F60` lo re-escribe con `[0x63F16B0]` cada frame | escritura per-frame simple | Ryu: no (si `object+0x5B56`==0, `0x1420F60` escribe `(0,0,0,0)` → tu valor sobrevive re-escribiéndolo); Momiji: sí |
| **C) `char[group] + 0x30` tras el EMA** | ✅ | ✅ | el EMA lo re-deriva de `object+0x5000` → amortiguado a 0 en pocos frames | — | — | — | — |

**`REMOTE_PLAYER_CONTROL_POINT` (candidato): `object + 0x4B90`** reescrito cada
frame **después** de `0x1420F60` (o, mejor, un hook que sustituya `0x14203E0` / lo
que rellene `[0x63F16B0]` para el actor controlado). Ventajas: es el RAW_COMMAND
per-actor, downstream 100 % compartido y verificado, produce locomoción +
animación naturales, delta acotado por el speed-clamp (sin teleport).

## 8. Control mode / IA (§10)

| campo | LOCAL_PLAYER | AI_PARTNER | nota |
|---|---|---|---|
| `char[group] + 0x00` | `0x00` | `0x04` | `CONTROL_DISCRIMINATOR_CANDIDATE` (Fase 9) — local vs IA/enemigo |
| `game_object` rec `+0x1D` | `0x00` | `0x04` | idem |
| `object + 0x98` | `0x02` | `0x04` | idem |
| `object + 0x5B56` | gate de "hay comando este frame" en `0x1420F60` | idem | si 0 ⇒ `object+0x4B90 = 0` |
| `object + 0x5B6D` / `+0x5B80` | gates en `0x14203E0` | idem | modo / estado |
| `[rip+0x4FD12B0] + 0xC` (manager byte) | `0x14203E0`: si != 0 ⇒ `bl = 0xFF` (¿bloqueo de input?) | — | **`CONTROL_MODE_CANDIDATE`** — un byte en el manager de comando que anula la lectura de input |

Para un futuro Player 2:
- **Player 2 = Ryu remoto**: sustituir/bloquear el poll de input local dentro de
  `0x14203E0` (o poner el `CONTROL_MODE_CANDIDATE` byte para que `0x14203E0` no lea
  input) y escribir el comando del remoto en `object+0x4B90` (o `[0x63F16B0]`)
  cada frame. **No** hay que tocar la IA.
- **Player 2 = Momiji remoto**: neutralizar la rama de IA dentro de `0x14203E0`
  para Momiji (hook de la generación del comando, o un flag per-actor) y escribir
  el comando del remoto. La carrera `AI brain vs remote` se resuelve en el orden
  intra-frame o suprimiendo la rama de IA.

## 9. Criterio (§12)

| requisito | estado |
|---|---|
| representación entendida | ✅ float4, `(0,0,0,0)` idle, `(dx,~0,dz,w=1)` activo; misma antes de `object+0x5000` |
| writer del raw command LOCAL_PLAYER capturado | ✅ `0x14210A0` en `0x1420F60` (`object+0x4B90 = [0x63F16B0] + char[grp]+0xFA0`) |
| writer del raw command AI_PARTNER capturado | ⚠️ **no en runtime** (mismo código estructural; Ryu llenó el MAX; falta captura Momiji-only) |
| ambos usan la misma ruta tras RAW_COMMAND | ✅ RUNTIME VERIFIED (`object+0x4B90` → `0xFF282A` → `object+0x5000` → `0xF24F4A` → `char+0x30` → `0x14249A0` → W1) |
| se conoce quién genera el comando de IA | ❌ **no** — la rama de IA dentro de `0x14203E0` no se aisló |
| resoluble dinámicamente para ambos | ✅ `game_object[idx] → object + 0x4B90` |

**`REMOTE_CONTROL_INJECTION` status: `STRONG CANDIDATE`.**
(Falta: capturar en runtime el writer de `object+0x4B90` de Momiji; aislar la rama
input vs IA dentro de `0x14203E0`; confirmar el `CONTROL_MODE_CANDIDATE`.)

**Confianza: ALTA** para "`object + 0x4B90` es el RAW_COMMAND per-actor y la ruta
downstream es compartida y verificada"; **MEDIA** para "el productor `0x14203E0`
ramifica internamente input vs IA" (rama no aislada).

## 10. `=== NEXT EXPERIMENT PLAN ===` (solo diseño — NO ejecutar, NO autorizado)

| campo | valor |
|---|---|
| Target actor | **LOCAL_PLAYER (Ryu) primero** |
| Injection level | `object + 0x4B90` (float4) reescrito **cada frame** en una ventana corta (bucle a ~60 Hz o hook), **después** de `0x1420F60`. Segunda opción: sustituir lo que `0x14203E0` escribe en `[module_base + 0x63F16B0]`. |
| Valor | dirección unitaria pequeña con `w = 1.0`, p. ej. `(0, 0, 1, 1)` = "adelante local" |
| Precondiciones | `LOCAL_PLAYER_STABLE` · `|object+0x4BC0| < 0.05` · sin input humano · backup de `object+0x4B90` (16 B) |
| Expected | `char+0x04` → walk (`0x06`→`0x26`); `char+0x30` sube por el EMA; `0x14249A0` integra con speed-clamp; **Ryu camina/corre con animación normal**; al parar la re-escritura, `object+0x4B90` vuelve a `(0,0,0,0)`, el EMA decae y Ryu se detiene |
| Teleport | **NO** (delta por frame acotado por `0x1469F60()`) |
| Execution authorized | **NO** |

Antes: captura Momiji-only del writer de `object+0x4B90`; aislar la rama input/IA
de `0x14203E0`; confirmar `CONTROL_MODE_CANDIDATE` (`[rip+0x4FD12B0]+0xC`).

## 11. Evidencia

- `docs/research/locomotion/watch_ryu_obj4B90_moving.txt` (50 hits del writer
  `0x14210A0`), `watch_gcmd_63F16B0.txt` (writers del scratch global),
  `watch_charFA0_none.txt` (0 hits — `char+0xFA0` no se escribe en este escenario),
  `wp_4b90.gdb`, `wp_g5b0.gdb`.
- Análisis offline: volcado `.text` de la Fase 11 + `tools/rt_image.py`.

## 12. Restricciones respetadas

Sin escrituras en memoria del juego. `object+0x4B90` / `object+0x5000` /
`char+0x30` / `[0x63F16B0]` / AI_PARTNER solo observados. IA no desactivada. Input
no inyectado. Sin hooks nuevos. Sin networking. Sin cambios en EXE / `core.dll` /
Proton / sysctl. `gdb` solo con watchpoints de observación + `detach`; proceso
vivo, hook Sigma2 re-verificado. Sin `git push`.

---

# FASE 15 — AI_PARTNER raw command confirmado + divergencia de control (2026-09-08)

Estado: tras `2a748c9`. **Solo lectura / observación.** Hardware watchpoints de
observación + `detach`; análisis offline con el volcado `.text` de la Fase 11.
Sin escrituras de memoria del juego, sin desactivar IA, sin inyectar input, sin
hooks nuevos, sin networking, sin cambios en EXE/`core.dll`/Proton. Proceso vivo
(PID 14042, `starttime` 108576, TracerPid 0), hook Sigma2 re-verificado.

## 15.0 Actores revalidados desde cero

| | LOCAL_PLAYER | AI_PARTNER |
|---|---|---|
| game_object index | 0 | 4 |
| object | `0x143197100` (RVA `0x3197100`) | `0x14319cdb0` (RVA `0x319cdb0`) |
| group / obj_id | 0 / 0 | 1 / 221 |
| char block | `0x142f78b10` | `0x142f79d50` |
| `char+0x00` (clase) | `0x00` (input local) | `0x04` (IA) |
| `object+0x4B90` en reposo | `(0,0,0,0)` | `(0,0,0,0)` |

## 15.1 Writer de `object+0x4B90` del AI_PARTNER — CAPTURADO

Watchpoint WRITE de observación sobre `MOMIJI object+0x4B90` (`0x1431a1940`),
Ryu quieto, Momiji autónoma: **40 hits, TODOS Momiji**, TODOS `pc = 0x1414210A8`
(RVA `0x14210A8`; store en RVA `0x14210A0`), thread `14115 "Updating"`.

| campo | LOCAL_PLAYER (Fase 14) | AI_PARTNER (Fase 15) |
|---|---|---|
| writer RVA | `0x14210A0`  `movdqu [rax+0x4B90], xmm4` | **`0x14210A0`** (idéntico; bytes `F3 0F 7F A0 90 4B 00 00`) |
| función | `0x1420F60`–`0x14215C3` (bucle per-actor) | **`0x1420F60`** (idéntica) |
| caller | `0x142C499` en `0x142C460` | **idéntico** |
| thread | `14115 "Updating"` | **`14115 "Updating"`** |
| call stack | `[+0x38]=0x14142C49E [+0x68]=0x141462167 [+0xC0]=0x141462160` | **byte-idéntica** |
| `rax`/`rcx` | obj de Ryu | obj de Momiji (`0x14319cdb0`) |
| `rbx` (índice de actor) | — | **`0x4`** (índice de game_object de Momiji) |
| `r9` | char[0] | **char[1]** (`0x142f79d50`) |
| fuente | `xmm4 = [module_base+0x63F16B0] + char[group][0xFA0]` | **idéntica** — verificado hit a hit: `xmm4 == [g_scratch]`, `char[1]+0xFA0 = (0,0,0,0)` |
| `object+0x5000` | 1 frame por detrás de `object+0x4B90` | **1 frame por detrás** (verificado en la secuencia de hits) |
| `char+0x04` durante | `0x06→0x26` (start→walk) | **`0x06` (16 hits) → `0x26` (24 hits)** (mismo enum) |
| valores `xmm4` | dir float4, `w=1.0` | dir float4, `w=1.0` (p.ej. `(-0.050,0.0001,0.079,1.0)`) |

⇒ **`RAW_COMMAND_SHARED_WRITER = RUNTIME VERIFIED`.** Momiji usa exactamente
`0x14210A0` / `0x1420F60` / `call 0x14203E0` / `g_scratch 0x63F16B0`, mismo layout
`object+0x4B90`, mismo downstream.

## 15.2 `0x14203E0` — es un chunk de una función per-actor GENÉRICA

`0x14203E0` (`.pdata` `0x14203E0`–`0x142040A`) es un chunk de una función
encadenada mayor `~0x142015B`–`0x1420BF9` (unwind `0x1C0F424`..`0x1C0F510`
consecutivos). Punto de entrada real = `0x14203E0` (único call site: `0x1421032`
en `0x1420F60`).

**Sus punteros base son globales de bucle per-actor** (fijados por `0x1420F60`
antes del `call`), NO managers de input singleton:

| global (RIP-rel dentro de `0x14203E0`) | RVA | rol (fijado por `0x1420F60`) |
|---|---|---|
| `[rip+0x4FD12B0]` (→ `r9`) | **`0x63F16A8`** | `G_CHARACTER` = `character[group]` del actor en curso |
| `[rip+0x4FD11DF]` / `[rip+0x4FD1271]` (→ `rcx`/`rax`) | **`0x63F16A0`** | `G_OBJECT` = `object` del actor en curso |
| `[rip+0x4FD1215]` (→ `r9` recargado) | `0x63F16A8` | `G_CHARACTER` |
| `[rip+0x4FD112C]` | `0x63F1698` | `G_GO_REC` = `&game_object[idx]` |
| `[rip+0x4FD0ED6]` / `[rip+0x4FD0E9E]` / `[rip+0x4FD0DD3]` | `0x63F16A8` / `0x63F16A0` | `G_CHARACTER` / `G_OBJECT` |
| `[rip+0x4FD0E7D]` (store del comando) | **`0x63F16B0`** | scratch del comando (`= g_scratch`) |

Cluster de globales de bucle fijados por `0x1420F60`:
`0x63F1690` `G_ACTOR_INDEX` (edx) · `0x63F1698` `G_GO_REC` · `0x63F16A0`
`G_OBJECT` · `0x63F16A8` `G_CHARACTER` · `0x63F16B0` `g_scratch` (comando
producido) · `0x63F16F0` `G_POS_COPY` (`object+0x4B80` snapshot).

**Corrección a la Fase 14:** `[rip+0x4FD12B0]` NO es un "manager de input"
separado — es `G_CHARACTER`. Los bytes `[r9+0x12]` `[r9+0x13]` `[r9+0x0C]`
`[r9+0xF8A]` `[r9+0xF85]` `[r9+0xF83]` `[r9+0x1FA]` son campos de
`character[group]` (per-actor).

### Lógica relevante de `0x14203E0`

```
r9  = character[group]                         ; G_CHARACTER
ebx = char[group]+0x12                         ; ACTION CODE primario  (0xFF = ninguno)
edx = char[group]+0xF8A
if ebx == 0xFF and (object+0x5B80 in {1,2}):  ebx = char[group]+0x13    ; fallback
if edx == 0xFF and (char[group]+0xF85 in {1,2}):  edx = char[group]+0x13
if ebx == 0xFF and edx != 0xFF:  ebx = edx
0x142046B  cmp byte [char[group]+0x0C], 0
0x1420475  cmovne ebx, 0xFF                     ; <<< si char[group]+0x0C != 0  ->  ebx = 0xFF (fuerza "sin acción")
...
0x14204B2  cmp ebx, 0xFF
0x14204B4  je 0x142097E                         ; <<< si ACTION CODE == 0xFF  ->  salta TODO el build del comando
                                                ;     (g_scratch queda 0  ->  object+0x4B90 = (0,0,0,0))
xmm6 = *(float4*)(object + ebx*0x40 + 0x1BA0)   ; fila de params de la acción (misma tabla que 0xF1ECA0)
... steering relativo a char[group]+0x1180 (vía call 0x142B380) ...
... transforma a mundo por la matriz char[group]+0x1010..+0x1050 (call 0x6FDE0) ...
0x142082B  movdqa [rip+0x4FD0E7D], xmm0         ; g_scratch (0x63F16B0) = comando de movimiento en mundo
0x14208DD  movdqu [G_OBJECT + 0x4B80], xmm0     ; == W2 (Fase 12): commit de object+0x4B80  (misma función)
0x1420967  char[group]+0x420 += delta           ; acumulador per-actor
```

⇒ **`0x14203E0` NO ramifica por "local vs IA".** Es código genérico per-actor que
lee los *action codes* de `character[group]+0x12/+0x13`. La única branch que
cambia el origen del comando es un **control-lock**: `char[group]+0x0C != 0` ⇒
sin acción. En reposo `char+0x0C = 0x00` para Ryu **y** Momiji (no es el
discriminador local/IA). El discriminador de clase sigue siendo
`char[group]+0x00` (`0x00`/`0x04`), que `0x14203E0` **no** lee.

## 15.3 Writer de los action codes `character[group]+0x12` — también COMPARTIDO

Watchpoint WRITE de observación sobre `RYU char0+0x10` **y** `MOMIJI char1+0x10`
(cubre `+0x12/+0x13/+0x16`), Ryu con input + Momiji autónoma: **60 hits**, 3 RVAs
escritoras, **todas compartidas Ryu/Momiji, call stacks byte-idénticas**:

| writer RVA | función | hits (Ryu/Momiji) | qué escribe | fuente del valor |
|---|---|---|---|---|
| `0xF1ED0F` | `0xF1ECA0`–`0xF1ED99` (updater de acción/animación per-actor) | 1 / 2 | `char[group]+0x12` (byte) = ACTION CODE | `rax = call 0xF88C40(...)` (lookup en tabla de descriptores de acción); `char+0x12 = rax ? rax[7] : 0xFF` |
| `0xF24BF7` | `0xF24BD9`–`0xF24D33` | 27 / 18 | `char[group]+0x10` (byte, contador saturante `min(x+1,0xFF)`) y `char+0x10 = char+0xF89` (cond.) | contador de frames per-actor |
| `0xF2480C` | `0xF247EA`–`0xF24BD9` | 4 / 7 | `char[group]+0x16` (word) | `*(word*)(G_OBJECT_glob + 0x5B3A)` (copia de `object+0x5B3A`) |

Call stack (idéntica Ryu/Momiji), de arriba a abajo:
`0x1462167` (dispatch "Updating") → `0xF8C429` → `0xF8044A` → `0xF7FC93` →
**`0xF252FD` (dentro de `0xF24F4A` = la función del EMA de `char+0x30`)** →
`0xF31F33`/`0xF31ACF` (en `0xF31D8D`–`0xF324E5`) → `0xF7BEB2` (en
`0xF7BDE0`–`0xF7BE85`) → `0xF24BB6` → `0xF1ECA0`.

⇒ El *action code* `char[group]+0x12` que alimenta `0x14203E0` lo produce el
**updater de animación compartido `0xF1ECA0`** (dentro del mismo árbol
`0xF24F4A` que corre el EMA), vía el lookup genérico `0xF88C40`
(`0xF88C40` tiene 41 call sites en 35 funciones — utilidad de tabla de acciones,
stride 4, busca `byte==6`, indexa por parámetro).

## 15.4 Divergencia local vs IA — DÓNDE ESTÁ (y dónde NO)

- **NO existe** en la ruta del comando de movimiento una branch
  `if local_player { input } else { AI }`. Toda la cadena
  `0xF1ECA0` → `0x14203E0` → `0x1420F60` → `object+0x4B90` → `0xFF282A` →
  `object+0x5000` → EMA `0xF24F4A` → `char+0x30` → `0x14249A0` → W1 es **código
  compartido genérico per-actor**, verificado en runtime para Ryu y Momiji.
- La divergencia está **en la capa de comportamiento/estado deseado** que rellena
  los campos de intención de `character[group]` (`+0x12/+0x13` y el estado que
  usa la clave del lookup `0xF88C40`), **aguas arriba de `0xF1ECA0`**:
  - **LOCAL_PLAYER**: el mapeo de input físico → estado deseado del personaje.
  - **AI_PARTNER**: el árbol de comportamiento / steering de la IA → estado
    deseado. En la call stack de Momiji aparece la región `0xF31D8D`–`0xF324E5`
    y `0xF7BDE0`–`0xF7BE85` (candidatas a esa capa) — **NO reconstruidas**
    (fuera de alcance: "no reconstruyas toda la IA").
- Discriminador de clase de actor: **`character[group]+0x00`** (`0x00` local /
  `0x04` IA), `game_object` rec `+0x1D` / `+0x1A`. Confirmado idéntico salvo ese
  byte entre Ryu y Momiji en todos los dumps de esta fase.

## 15.5 Clasificación de candidatos (§5)

| campo / puntero | clase | nota |
|---|---|---|
| `character[group] + 0x00` (`0x00`/`0x04`) | **CONTROL_MODE_CANDIDATE** | discriminador de clase local/IA (Fase 9); `0x14203E0` no lo lee, pero es la marca conocida |
| `character[group] + 0x0C` (byte) | **CONTROL_MODE_CANDIDATE** | control-lock: `!= 0` ⇒ `ebx = 0xFF` dentro de `0x14203E0` (sin acción). `0x00` para ambos en reposo (no es local/IA) |
| `object + 0x5B56` (byte) | **CONTROL_MODE_CANDIDATE** | enable del comando en `0x1420F60`: `0` ⇒ `object+0x4B90 = (0,0,0,0)`. `01` para ambos |
| `character[group] + 0x12` / `+0x13` | representación de intención compartida | writer `0xF1ED0F` (`0xF1ECA0`) vía lookup `0xF88C40`; input e IA ya fusionados aquí |
| `[rip+0x4FD12B0]` / `4FD1215` / `4FD11DF` / `4FD112C` | **REJECTED** (como "manager de input") | son `G_CHARACTER` / `G_OBJECT` / `G_GO_REC` — globales de bucle per-actor fijados por `0x1420F60` |
| `G_ACTOR_INDEX` `0x63F1690` (`rbx=4` para Momiji en `0x14210A0`) | **REJECTED** (como control-mode) | variable de iteración del bucle per-actor (0..0xA0) |
| `object + 0x5B6D` / `+0x5B80` / `+0x5B77` / `+0x5B75` | per-actor gates de `0x14203E0` (ruta W2/commit) | `00` para ambos; no son discriminadores local/IA |
| capa `0xF31D8D`–`0xF324E5` / `0xF7BDE0`–`0xF7BE85` (call stack de Momiji) | **AI_CONTROLLER_CANDIDATE** | región de comportamiento/estado deseado de la IA — NO reconstruida |
| mapeo de input físico (aguas arriba de `0xF1ECA0` para Ryu) | **LOCAL_INPUT_OWNER_CANDIDATE** | NO localizado esta sesión |

## 15.6 Branch concreta demostrada (§6)

| campo | valor |
|---|---|
| RVA | `0x142046B` (`cmp byte [rcx+0x0C], 0`, `rcx = character[group]`) + `0x1420475` (`cmovne ebx, edi` con `edi = 0xFF`) |
| condición | `character[group]+0x0C != 0` ⇒ `ebx (action code) = 0xFF` |
| efecto | fuerza "sin acción" ⇒ `0x14204B4 je 0x142097E` salta el build ⇒ `g_scratch = 0` ⇒ `object+0x4B90 = (0,0,0,0)` |
| valor en Ryu | `char0+0x0C = 0x00` (rama no tomada) |
| valor en Momiji | `char1+0x0C = 0x00` (rama no tomada) |
| interpretación | **control-lock de movimiento per-actor** (p.ej. cutscene / stagger / diálogo), NO el discriminador local↔IA |

**No se encontró una branch `if local_player use_input else use_AI`** en la ruta
del comando de movimiento (las dos rutas convergen por encima de `0xF1ECA0`).

## 15.7 LOCAL input source (§7)

No localizada esta sesión. El *action code* de Ryu (`char0+0x12`) sale del
updater compartido `0xF1ECA0` → lookup `0xF88C40`, keyed en el estado deseado del
personaje; quién traduce input físico → estado deseado está aguas arriba de
`0xF1ECA0` (región `0xF31D8D` / `0xF7BDE0` en la pila, no reconstruida).
`LOCAL_INPUT_OWNER_CANDIDATE` = ese traductor (sin dirección).

## 15.8 AI command source (§8)

`AI_COMMAND_SOURCE_STRONG_CANDIDATE`: el comando de Momiji entra en la tubería
compartida por `character[1]+0x12/+0x13` (action codes) + el estado deseado que
consume `0xF1ECA0`/`0xF88C40`. La capa de comportamiento/steering que fija ese
estado está en la región `0xF31D8D`–`0xF324E5` / `0xF7BDE0`–`0xF7BE85` (presente
en la call stack de Momiji) — **no reconstruida** (fuera de alcance). Lo que sí
está **RUNTIME VERIFIED**: desde `char[1]+0x12` hacia abajo
(`0x14203E0` → `g_scratch` → `object+0x4B90` → … → W1) el mecanismo de Momiji es
byte-idéntico al de Ryu.

## 15.9 Punto de control remoto (§9)

| nivel | qué | naturalidad | animación | smoothing | carrera con IA | robustez | distinguir actor | networking |
|---|---|---|---|---|---|---|---|---|
| **A** — reemplazar la fuente antes de `0x14203E0` (campos de intención `char+0x12/+0x13` + estado deseado) | máxima | sí (el estado deseado dispara la anim) | pasa por el EMA | hay que suprimir el writer de IA | baja (varios campos, timing) | `game_object[idx]` | serializar intención (varios campos) |
| **B** — hook de `0x14203E0` para el actor: sustituir `g_scratch` (`0x63F16B0`) tras `0x142082B` | alta | sí, si el estado deseado también refleja "moviéndose" | pasa por el EMA | el output de la IA a `g_scratch` se sobrescribe antes de que `0x1420F60` lo lea | media (1 chokepoint) | `game_object[idx]` | 1 float4 mundo/actor/tick |
| **C** — reescribir `object+0x4B90` cada frame **después** de `0x14210A0` | alta | **por confirmar**: si `char+0x04` no pasa a walk, sería drift de posición sin anim (como MVP 2B) | pasa por el EMA (`object+0x5000` ← `object+0x4B90` → EMA → `char+0x30`) | tu escritura post-`0x1420F60` gana sobre la IA | **alta** (1 write de 16 B/actor/frame) | `game_object[idx] → object+0x4B90` | **1 float4 + magnitud/actor/tick** |

**`PREFERRED_REMOTE_CONTROL_LEVEL = C`** para una primera implementación (el más
simple, downstream 100 % compartido y verificado, trivial de resolver por actor,
network-friendly), con **B** como opción "más correcta" a largo plazo (deja que
la transform por matriz de mundo y el frame de referencia de `0x14203E0` operen
sobre el comando remoto). **Caveat de C** (heredado de MVP 2B): si el motor no
lleva `char[group]+0x04` a un estado de locomoción, `0x14249A0` (keyed en
`char+0x04`) no integra el delta y se obtendría movimiento de posición sin
animación. El test de movimiento natural (§11) debe **medir** si `char+0x04`
engancha walk; si no, escalar a B/A (alimentar también el estado deseado).

## 15.10 Criterio de éxito (§10)

| requisito | estado |
|---|---|
| Momiji usa `0x14210A0` | ✅ RUNTIME VERIFIED (40/40 hits) |
| Momiji recibe su raw command desde `0x14203E0` | ✅ RUNTIME VERIFIED (`g_scratch + char[1]+0xFA0`, fórmula idéntica) |
| mismo `object+0x4B90` layout | ✅ |
| downstream idéntico | ✅ RUNTIME VERIFIED (`0xFF282A` → `object+0x5000` → EMA → `char+0x30` → `0x14249A0` → W1) |
| branch local-vs-IA identificada | ❌ **NO** — las rutas convergen por encima de `0xF1ECA0`; sólo se halló un control-lock (`char+0x0C`), no un split local/IA |
| fuente AI al menos strong candidate | ⚠️ **STRONG CANDIDATE** — entra por `char[1]+0x12` + estado deseado; capa de comportamiento `0xF31D8D`/`0xF7BDE0` identificada en la pila, no reconstruida |

⇒ Falta la branch ⇒ **`REMOTE_PLAYER_CONTROL_POINT = STRONG CANDIDATE`**
(no RUNTIME VERIFIED). Confianza: **ALTA** en "`object+0x4B90` es el RAW_COMMAND
per-actor compartido y todo el downstream está verificado para ambos actores";
**MEDIA** en "reescribir sólo el raw command produce locomoción natural completa"
(caveat `char+0x04`); **MEDIA-BAJA** en la ubicación de la fuente de IA (región
conocida, no reconstruida).

## 15.11 Test de movimiento natural — SÓLO DISEÑO (Execution authorized = NO)

| campo | valor |
|---|---|
| Target actor | **LOCAL_PLAYER (Ryu)** primero |
| Nivel | **C**: reescribir `object+0x4B90` (float4) cada frame, **después** de `0x1420F60`, durante una ventana corta (bucle ~60 Hz; en el futuro, hook) |
| Valor | dir unitaria pequeña + `w = 1.0`, p.ej. `(0, 0, 1, 1)` = "adelante local" |
| Precondiciones | `LOCAL_PLAYER_STABLE` · `|object+0x4BC0| < 0.05` · sin input humano · backup de `object+0x4B90` (16 B) · guards proceso/SHA256/slot |
| Medición clave | ¿`char[0]+0x04` pasa a `0x06/0x26` (walk)? ¿`char+0x30` y `object+0x4BC0` rampan? |
| Éxito | Ryu camina con **animación normal**, velocity y locomoción normales; al parar, `object+0x4B90 → (0,0,0,0)`, EMA decae, Ryu se detiene. **NO teleport** (delta acotado por el speed-clamp `0x1469F60()`) |
| Si `char+0x04` NO engancha | escalar a nivel B (hook `0x14203E0` / `g_scratch`) o A (estado deseado + `char+0x12`) |
| Rollback | dejar de escribir; verificar `(0,0,0,0)` y `char+0x04 → 0`; restaurar 16 B; ventana ≤ 5 s; abortar si Y se mueve > 0.1 o cambia el proceso |
| Execution authorized | **NO** |

## 15.12 Evidencia

- `docs/research/locomotion/watch_momiji_obj4B90_moving.txt` (40 hits, writer
  `0x14210A0` del AI_PARTNER) · `wp_4b90_momiji.gdb`.
- `docs/research/locomotion/watch_char12_action_moving.txt` (60 hits; writers
  `0xF1ED0F` / `0xF24BF7` / `0xF2480C` de `char[group]+0x10..0x17`, compartidos
  Ryu/Momiji) · `wp_char12.gdb`.
- Análisis offline: volcado `.text` de la Fase 11
  (`docs/research/runtime_text/20260907T1650Z_pid14042/`) + `tools/rt_image.py`
  (`fn_14203e0.asm`, chunks `0x142076a`/`0x1420b9d`, `0xF1ECA0`, `0xF88C40`).

## 15.13 Restricciones respetadas

Sin escrituras en memoria del juego. `object+0x4B90` / `object+0x5000` /
`char+0x12` / `char+0x30` / `g_scratch` / AI_PARTNER sólo observados. IA no
desactivada. Input no inyectado. Sin hooks nuevos. Sin networking. Sin cambios en
EXE / `core.dll` / Proton / sysctl. `gdb` sólo con watchpoints de observación +
`detach`; proceso vivo (PID 14042, TracerPid 0), hook Sigma2 re-verificado. Sin
`git push`.


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
