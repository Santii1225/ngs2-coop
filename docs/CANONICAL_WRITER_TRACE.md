# FASE 12 — Trazado del writer de `object + 0x4B80` (posición canónica)

Estado: 2026-09-07, tras `8940a58`. **Solo lectura / observación.** Sin escrituras
de memoria del juego, sin modificar `+0x4B80` / `+0x2B0` / AI_PARTNER, sin hooks de
gameplay, sin networking, sin cambios en `core.dll` / EXE / Proton / sysctl. Se
usó `gdb` con **hardware write-watchpoints** de solo observación y `detach` al
final. Proceso vivo tras la sesión (PID 14042, `starttime` 105, TracerPid 0), hook
Sigma2 re-verificado.

## 0. Punto de partida (Fase 11)

`object + 0x2B0` (posición observable) se re-deriva cada frame de **`object +
0x4B80`** vía `0xF7BB70` → `0xF8E420` → escritura `0x1353E37`. `object + 0x4B80` =
`CANONICAL_POSITION_STRONG_CANDIDATE`, con `+0x4BC0` = velocity y `+0x4BD0` =
centro de cápsula. Falta: **capturar el writer de `+0x4B80` durante movimiento
real** y determinar si es locomotion/physics o otra copia.

## 1. Proceso

PID 14042 (mismo de la Fase 11, sin reiniciar). Module base `0x140000000`. core
`0x6ffff9830000`. EXE/core SHA256 OK. Hook slot OK. Team Mission Ryu + IA Momiji.

| actor | resolver | `object` | `+0x4B80` abs (esta sesión) |
|---|---|---|---|
| LOCAL_PLAYER | `game_object[0]` | RVA `0x3197100` (`0x143197100`) | `0x14319bc80` |
| AI_PARTNER | `game_object[4]` (Momiji, id 221) | RVA `0x319cdb0` (`0x14319cdb0`) | `0x1431a1930` |

En reposo, para ambos: `+0x4B80 == +0x2B0` (posición), `+0x4BC0 == (0,0,0)`,
`+0x4BD0 ≈ (x, y+1.09, z, 1)` (cápsula). `+0x4B80` bit-estable con el actor quieto.

## 2. Captura dinámica (hardware write-watchpoint, solo observación)

3 sesiones `gdb -batch`, `set can-use-hw-watchpoints 1`, `watch *(...)` (write) sobre
`+0x4B80` (8 bytes X+Y) y `+0x4B88` (4 bytes Z), `commands`/`cont`, `detach` tras
N hits, `handle SIG* nostop noprint pass`. `info watchpoints` confirmó **`hw
watchpoint`** en las 3 sesiones. El juego corre a velocidad completa mientras no
haya escritura (en reposo no dispara — igual que `+0x2B0`).

Nota: un `watch` (write) sobre esta dirección **sí dispara** de forma fiable en
movimiento; lo que la Fase 10/11 documentó como poco fiable era el `watch` de
**cambio de valor** en reposo. Aquí no hay escrituras en reposo, así que el 0-hits
en reposo es correcto, no un fallo.

| sesión | watch | hits | resultado |
|---|---|---|---|
| MOVE 1 (LOCAL_PLAYER) | `P+0x4B80` XY, `P+0x4B88` Z | 40 | X −94.4968 → −95.1013, `+0x4BC0` Z 0.0016→0.38 (rampa) |
| MOVE 2 (LOCAL_PLAYER, otra dirección) | idem | 50 | X −94.5402 → −95.3566, `+0x4BC0` Z 0.0056→0.3756 |
| AI_PARTNER (Momiji, movimiento autónomo) | `AI+0x4B80` XY, `AI+0x4B88` Z | 40 | X −107.89 → −108.02, Z 71.14 → 71.35, `+0x4BC0` (0.0022,0,0)→(0.045,0,−0.826) |

Todos los hits en el **thread `14115` "Updating"**.

## 3. Writers de `object + 0x4B80` (RVA de esta build `a66daf…`)

### Writer W1 — locomotion `pos += delta`  (LOCAL_PLAYER **y** AI_PARTNER)

- **PC de la escritura: RVA `0x141BBC1`** (`movss dword ptr [rax], xmm1`), reportado
  por gdb en `0x141BBC5` (instrucción siguiente).
- **Función: `0x141BB90`–`0x141BBF2`** (leaf, sin `.pdata`; llamada directa). Cuerpo:
  ```
  0x141BB90  movss xmm1,[rdx]              ; rdx -> delta vector (4 floats)
  0x141BB94  ucomiss xmm1,xmm1 ; jp/jne ret   (guard NaN en delta.x/.y/.z)
  0x141BBB3  mov rax,[rcx+0x10]            ; rcx = handle ;  [rcx+0x10] = object ptr
  0x141BBB7  add rax,0x4B80               ; rax = object + 0x4B80
  0x141BBBD  addss xmm1,[rax]             ; xmm1 = delta.x + pos.x
  0x141BBC1  movss [rax],xmm1             ;  pos.x += delta.x     <-- WRITE (X)
  0x141BBC5  ...  [rax+4] += [rdx+4]      ;  pos.y += delta.y
  0x141BBD4  ...  [rax+8] += [rdx+8]      ;  pos.z += delta.z
  0x141BBE3  ...  [rax+0xC] += [rdx+0xC]  ;  4º componente
  0x141BBF2  ret
  ```
  Es una **primitiva dedicada `object_position += delta4`**, con guard NaN. NO es
  `memcpy` (adiciones float escalares componente a componente).
- **Registros en el hit** (idénticos en MOVE 1, MOVE 2 y AI):
  `rax = object+0x4B80` · `rbx = object` · `r9 = object` · `rdx = 0x5cb2fbc0`
  (buffer de pila con el delta) · `r11 = 0x141E38710` (= `module_base +
  0x1E38710` = `object_data_offset_table`) · `rcx = 0x1463F1690` (handle) ·
  `xmm6 = 0.5` (factor de escala) · `xmm1` = nuevo valor.
- **Source operand:** `[rdx]` = delta vector, construido por el caller.
- **Caller (retorno `[rsp+0] = 0x1429B97`):** función **`0x14249A0`–`0x1429E38`**
  (≈ 21 KB — actualización per-actor grande), en el call-site `0x1429B92`:
  ```
  0x1429B60  mulps xmm1,xmm6              ; movimiento * escala
  0x1429B63  movss [rsp+0x50],xmm1        ; delta construido en [rsp+0x50..]
  0x1429B6F  mulss xmm0,xmm6
  0x1429B79  lea rdx,[rsp+0x50]
  0x1429B82  call 0x6FB20                 ; copia 16B del delta -> [rbp-0x50]
  0x1429B87  lea rdx,[rbp-0x50]
  0x1429B8B  lea rcx,[rip+0x4FC7AFE]      ; rcx = handle global del jugador
  0x1429B92  call 0x141BB90              ; object+0x4B80 += delta
  ```
  ⇒ **`object+0x4B80 += (movement_vector * scale)`** — integración de posición por
  frame. `0x6FB20` es un copiador de 16 bytes (`*rcx = *rdx`), no una rotación.
- **Dispatcher: `0x1420F60`–`0x14215C3`** llama `0x14249A0` @ `0x14211C5`. `0x1420F60`
  toma `edx` = índice de actor, resuelve `&game_object[edx]` (`lea rax,[rip+…] →
  module_base+0x3195300`, `edx*0x30`, comprueba `+0x1a`/`+0x1f`), lo guarda en un
  global (`[rip+0x4FD06F5]`) y llama la actualización. ⇒ es el **bucle/dispatcher
  de actualización de movimiento por entrada de `game_object`**.
- Callers de `0x141BB90` en total: **10 sitios en 8 funciones**, todas en el cluster
  `0x1420F60`–`0x1429E38` (subsistema de movimiento).

### Writer W2 — commit de transform (vector completo)  (LOCAL_PLAYER **y** AI_PARTNER)

- **PC de la escritura: RVA `0x14208DD`** (`movdqu xmmword ptr [rax + 0x4B80], xmm0`),
  reportado en `0x14208E5`.
- **Función: `0x1420841`–`0x142099E`** (`.pdata`, unwind `0x1C0F4EC`). Cuerpo relevante:
  ```
  0x14208BC  call 0x6FDE0                 ; operación de matriz 4x4
  0x14208C1  movaps xmm0,[rsp+0x40]       ; resultado del transform
  0x14208CD  shufps xmm0,xmm0,0x93
  0x14208D5  movss xmm0,xmm6 ; shufps xmm0,xmm0,0x39   ; inyecta w=1.0 y recompone
  0x14208DD  movdqu [rax+0x4B80],xmm0     ; rax = [rip+0x4FD0DD3] (puntero GLOBAL al
                                          ;  objeto del jugador activo) -> WRITE (X,Y,Z,1)
  0x1420905  movups xmm0,[rax+0x4B80]     ; re-lee +0x4B80
  0x1420911  subss xmm0,[rip+0x4FD0DD7]   ; - constante (origen/referencia)
  ```
- **Registros:** `rax = object` · `xmm0 = (x, y, z, 1.0)` (posición con w) ·
  `xmm6 = (1,1,1,1)`.
- **Source operand:** `xmm0` = resultado de `call 0x6FDE0` (transform de matriz).
- **Caller:** `0x1420841` no tiene callers directos (fragmento alcanzado por
  fall-through); la pila muestra `[+0x1C8]=0x1462167 [+0x220]=0x1462160` = el
  **stub de dispatch del hilo "Updating"** (Fase 11).
- Interpretación: recompone la posición desde un transform de matriz cada frame
  (probable ajuste de suelo / colisión / snap tras la integración de W1).

### Writers adicionales SOLO vistos en el AI_PARTNER

- **RVA `0x1353A5C`** (`movdqu [rax], xmm0`) y **`0x1353EF9`** (`movdqa [rax], xmm6`),
  en el cluster `0x1353xxx` = la **misma familia de transform-sync per-actor** que
  escribe `+0x2B0` (Fase 11: `0x1353D00` / `0x1353E37`). Pila:
  `[+0x88]=0x135447F [+0x188]=0x136CE16` y `[+0x68]=0x1353EF9 [+0xF8]=0x1354467
  [+0x1F8]=0x136CE16` → vía `0x1354390` / `0x136CBC0` (bucle per-actor de
  "Updating").
- En las 2 capturas de movimiento del LOCAL_PLAYER **estos no dispararon**: el
  `+0x4B80` del jugador local lo escribió solo W1 (locomotion `+=`) y W2 (commit).
  Para el compañero IA, la ruta de transform-sync **también** toca `+0x4B80`
  (probablemente porque su posición se deriva de un objetivo/ruta calculada además
  de la locomotion). **Ambos actores comparten W1 y W2.**

## 4. Clasificación de cada write

| writer | tipo | ¿copia del mismo object? |
|---|---|---|
| W1 `0x141BB90` (`pos += delta`) | **write directo de locomoción** — integración `pos += movement*scale`, guard NaN | NO — modifica el valor autoritativo, no lo copia |
| W2 `0x14208DD` (`movdqu` = transform) | **write de transform/física** — resultado de matriz `0x6FDE0`, recompuesto, luego `- origen`; probable ajuste de suelo/colisión | NO — es un valor calculado, no un `memcpy` |
| `0x1353A5C` / `0x1353EF9` (solo AI) | transform-sync per-actor (misma familia que `+0x2B0`) | NO — accumula (`addps`) y transforma |
| `0x8C7B4` / `0xEAD02E` (Fase 11) | generic memcpy — **solo leen `+0x2B0`**, no tocan `+0x4B80` | n/a |

**Ningún writer de `+0x4B80` es `memcpy`/`memmove` ni una copia de render/interp.**
Todos son código dedicado de posición: integración de locomotion + commit de
transform.

## 5. Relación con `+0x4BC0` (velocity)

- En reposo `+0x4BC0 == (0,0,0)` para LOCAL_PLAYER y AI_PARTNER.
- Durante movimiento: crece de forma monótona con la aceleración (MOVE 1: Z-slot
  0.0016 → 0.38; MOVE 2: 0.0056 → 0.3756) y **se resetea a 0 en los límites de
  frame** (se ve el 0 en algunos hits `W_XY`) → comportamiento de acumulador de
  delta por tick que se consume en la posición.
- Dirección coherente: el compañero IA se movió en diagonal y su `+0x4BC0` tuvo
  componentes X y Z no nulos `(0.045, 0, −0.826)`.
- **Writers de `+0x4BC0`** (`scandisp 0x4bc0`): `0xF8190E` (Fase 11 — **escribe
  `+0x4B80` Y `+0x4BC0` en la misma función**), `0x14218C0` (`movdqa [rax+0x4BC0],
  xmm0`), `0x14219A0` (`movss [rax+0x4BC0], xmm0`). Los tres en el mismo subsistema
  `0x142xxxx` / `0xF81xxx` y usan el **mismo puntero global al objeto del jugador**
  (`[rip+0x4FCFD83]` etc.) que W2. ⇒ posición y velocity son actualizadas por el
  **mismo subsistema de movimiento**.

## 6. Relación con `+0x4BD0` (centro de cápsula de colisión)

- `+0x4BD0 ≈ (pos.x, pos.y + ~1.05..1.09, pos.z, 1.0)` en reposo, ambos actores.
- Durante movimiento se desplaza junto a `+0x4B80` (misma dirección, misma
  magnitud) con la Y ~1.0..1.10 por encima. Es el **centro geométrico de la
  cápsula del actor** (posición del pie + media altura). No se reconstruyó el
  sistema de colisión.

## 7. `object + 0x4B80` — ¿es otra copia?  → **NO**

- Escrito por `pos += delta` (W1): no se `+=` una copia, se `+=` el valor
  autoritativo.
- Escrito por un resultado de transform de matriz (W2), no por `memcpy`.
- `+0x4BC0` (velocity) y `+0x4BD0` (cápsula) adyacentes, actualizados por el mismo
  subsistema; `0xF8190E` escribe posición y velocity juntas.
- Alimenta `object + 0x2B0` (Fase 11) — que sí es copia de render (`+0x2B0` va un
  frame por detrás de `+0x4B80` en los datos del watchpoint).
- Arquitectura idéntica y **mismos writers** (`0x141BB90`, `0x14208DD`) capturados
  en vivo para el AI_PARTNER.

## 8. Criterio `CANONICAL_POSITION_RUNTIME_VERIFIED` (§12)

| criterio | estado |
|---|---|
| sigue world XYZ | ✅ 2 movimientos LOCAL_PLAYER + movimiento autónomo AI_PARTNER |
| alimenta `object+0x2B0` | ✅ Fase 11 (`0xF7BB70` lo lee) + aquí (`+0x2B0` va 1 frame por detrás) |
| writer identificado durante movimiento | ✅ W1 `0x141BB90` + W2 `0x14208DD`, thread "Updating", 130 hits |
| writer pertenece a movement/physics/controller | ✅ W1 = `pos += movement*scale` desde `0x14249A0` (update per-actor) dispatcheado por índice de `game_object`; W2 = commit de transform; subsistema comparte velocity `+0x4BC0` |
| no es otra copia render/interpolada | ✅ float `addss`/`movss` + `movdqu` de transform; sin `memcpy`/`memmove`; guard NaN |
| relación coherente con `+0x4BC0` velocity | ✅ ~0 en reposo, rampa en aceleración, reset por frame, dirección coherente, writers compartidos |
| repetición en dos movimientos | ✅ instrucciones/función/thread/cadena idénticas en MOVE 1 y MOVE 2 |
| arquitectura equivalente en AI_PARTNER | ✅ mismos writers `0x141BB90` / `0x14208DD` capturados en vivo sobre `game_object[4]` |
| puede resolverse dinámicamente | ✅ `resolver → object + 0x4B80` |

**Veredicto: `object + 0x4B80` = `CANONICAL_POSITION_RUNTIME_VERIFIED`.**
Confianza: **ALTA**.

Caveats documentados (no invalidan):
1. `+0x4B80` recibe **dos** escrituras por frame: la integración W1 (`+= delta`)
   **y** el commit de transform W2 (`movdqu`). W2 recompone desde una matriz —
   podría introducir ajuste de suelo/colisión. No se ha demostrado que el input
   de la matriz de W2 no provenga de un estado aún más profundo en
   `character[group]`; la integración W1 sí escribe directo sin intermediario.
2. Para el AI_PARTNER, la familia de transform-sync `0x1353xxx` también escribe
   `+0x4B80`; para el LOCAL_PLAYER en movimiento no se observó. Ambos comparten W1/W2.
3. La prueba definitiva ("¿una escritura en `+0x4B80` con velocity 0 persiste y
   propaga a `+0x2B0` y mueve a Ryu?") es **MVP 2B** — diseñada, no ejecutada.

## 9. Herramientas / evidencia

- `docs/research/transform_sync/watch_4B80_move1.txt` (LOCAL_PLAYER movimiento 1, 40 hits).
- `docs/research/transform_sync/watch_4B80_move2_player.txt` (LOCAL_PLAYER movimiento 2, 50 hits).
- `docs/research/transform_sync/watch_4B80_ai_partner.txt` (AI_PARTNER autónomo, 40 hits).
- `docs/research/transform_sync/scan_4bc0.txt` (writers de velocity).
- `docs/research/transform_sync/wp4b80b.gdb`, `wp4b80c.gdb`, `wpai.gdb` (scripts read-only).
- Análisis offline con el volcado `.text` de la Fase 11
  (`docs/research/runtime_text/20260907T1650Z_pid14042/`) + `tools/rt_image.py`.

## 9b. W2 SOURCE CHECK (2026-09-07, solo análisis del volcado existente)

Duda cerrada: **de dónde viene el valor que W2 (`0x14208DD`) escribe en
`object+0x4B80`.**

- **`0x1420841` es un fragmento encadenado** de una función mayor (`.pdata`
  `0x142015B`…`0x142099E`, unwind consecutivo). El `r9` que usa W2
  (`[r9+0x1010]…[r9+0x1050]`) se fija en `0x14207CB` = `mov r9,[rip+0x4FD0ED6]`
  = **puntero global a `character[group]`**.
- **La matriz de W2 = `character[group] + 0x1010..+0x1050`** (4×4): fila de
  traslación `+0x1010`, filas de rotación `+0x1020/+0x1030/+0x1040`, `+0x1050`.
- **`0xF33D97` refresca esa matriz desde el `object`** (confirmado en el volcado):
  ```
  0xF33F6E  movaps xmm0,[rcx+0x4B80]      ; rcx = object
  0xF33F75  movdqa [rdx+0x1010],xmm0      ; character[grp]+0x1010 = object+0x4B80   (traslación)
  0xF33F7D  movaps xmm0,[rcx+0x1AB0] ; movaps [rdx+0x1020],xmm0   ; rotación = object+0x1AB0
  ...       +0x1030 ← object+0x1AC0 ; +0x1040 ← object+0x1AD0 ; +0x1050 ← object+0x1AE0
  ```
  `scandisp 0x1010`: no hay otro writer xmm de `[reg+0x1010]` (solo un `mov
  [rbx+0x1010],eax` de otra struct). La traslación de la matriz de W2 **es una
  copia por frame de `object+0x4B80`**; la rotación es copia de `object+0x1AB0`
  (que a su vez es copia de `char+0x80`, Fase 7).
- **`0x6FDE0`** es `out = Matrix4 × vec` puro (sin lecturas de memoria salvo sus
  args). El `vec` de W2 (`xmm6`) se construye en la función padre
  (`0x1420703`: `movups xmm6,xmm1; shufps; movss xmm6,xmm0; shufps`) a partir de
  math de posición relativa que resta `character[group]+0x1184/+0x1188/+0x118C`
  (`0x14205F1`…). No es un estado independiente de animación/física localizado;
  es aritmética de locomotion sobre campos de `character[group]`.

**Orden lógico por frame (hilo "Updating"):**
1. **W1** `0x141BB90`: `object+0x4B80 += movement_delta`.
2. **`0xF33D97`**: `character[group]+0x1010 ← object+0x4B80` (traslación),
   `+0x1020..+0x1050 ← object+0x1AB0..+0x1AE0` (rotación).
3. **W2** `0x14208DD`: `object+0x4B80 ← M(character[group]+0x1010) × vec` —
   re-expresa la posición a través de la matriz del personaje.
4. **`0x1353D00`** (`0xF7BB70`→`0xF8E420`→`0x1353E37`): `object+0x2B0 ← f(object+0x4B80, …)`.

El orden intra-frame de 2↔3 no está probado; la evidencia runtime (aceleración
suave, `object+0x4B80` tras W1+W2 = integración de W1) muestra que **el efecto
neto de W2 sobre el estado estable es identidad** — no introduce un valor
distinto ni revierte a uno viejo durante el movimiento continuo.

**¿Puede W2 sobrescribir un write externo a `+0x4B80` con un valor más viejo?**
→ **POSIBLE solo transitorio (≤ 1 frame), NO permanente.** La matriz de W2
(`char+0x1010`) es ella misma una copia por frame de `object+0x4B80` hecha por
`0xF33D97`; un write externo se copia a `char+0x1010` y W2 lo re-escribe. Es
distinto de MVP 2 (`object+0x2B0`), donde la fuente `object+0x4B80` **nunca** se
modificaba y el motor revertía de forma permanente. El único riesgo de reversión
es de 1 frame si W2 corre antes de `0xF33D97` en el frame del write; después
`0xF33D97` toma el valor nuevo y W2 lo propaga.

**Riesgo residual:** (a) parpadeo de 1 frame; (b) `xmm6` incorpora
`character[group]+0x1184` — si ese campo fuera un ancla independiente (punto de
contacto de colisión / objetivo de animación) el resultado de W2 tendría una
componente independiente del write; el estado estable runtime argumenta que la
aritmética se cancela y reproduce la traslación; (c) los flags
`object+0x5B75/+0x5B77` gate de W2 y la math de velocidad de la función padre —
un empujón de +0.30 u en suelo plano con velocity 0 es muy improbable que active
corrección de colisión.

**MVP 2B risk: LOW-MEDIUM.** El write a `object+0x4B80` debería persistir (la
fuente de W2 no es un estado independiente, es una copia de `+0x4B80`) y
propagarse a `object+0x2B0` y la posición visible. La ventana de observación
corta del diseño de MVP 2B (§7) ya absorbe el posible transitorio de 1 frame.

## 10. Restricciones respetadas

Sin escrituras en memoria del juego. `+0x4B80` / `+0x2B0` / AI_PARTNER solo leídos.
Sin hooks nuevos. Sin networking. Sin cambios en EXE / `core.dll` / Proton / sysctl.
`gdb` solo con hardware write-watchpoints de observación + `detach`; proceso vivo,
`starttime` estable, hook Sigma2 re-verificado. Sin `git push`.


## MVP 2B EJECUTADO — PASS (2026-09-07)

`object+0x4B80` escrito una vez (`+0.30` X, `tools/player_write_test_2b.py`, autorizado por el usuario). **La escritura se mantuvo ~3.5 s** (el motor NO la revirtió) y **`object+0x2B0` convergió** al valor nuevo en ≤ 1 frame; restauración `EXACT`; sin crash; Y/Z/velocity/rotación/AI_PARTNER intactos. Usuario: `NO NOTE MOVIMIENTO PERO TODO NORMAL` (delta pequeño para la escala del mundo, no reversión). ⇒ `object+0x4B80` es **escribible de forma persistente y propaga** — primitivo de teleport real. Detalle: [MVP2B_WRITE_TEST_01.md](MVP2B_WRITE_TEST_01.md).
