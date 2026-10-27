# FASE 11 — Traza de la sincronización de transform en runtime

Estado: 2026-09-07, tras `a184179`. **Solo lectura / análisis.** Sin escrituras de
memoria del juego, sin teleport, sin tocar AI_PARTNER, sin hooks nuevos, sin
cambios en `core.dll` / EXE / Proton / sysctl. Se usó `gdb` con watchpoints de
hardware de **solo lectura** (`awatch`) y `detach` al final (igual que la Fase 10);
el proceso siguió normal, `starttime` sin cambios, hook Sigma2 vivo antes y después.

## 0. Objetivo

Seguir hacia atrás la cadena que cada frame termina escribiendo la posición
observable `object + 0x2B0`, hasta encontrar el estado autoritativo
(movement / physics / root-motion / controller / transform canónico).

## 1. Proceso runtime de esta sesión

| | |
|---|---|
| PID | 14042 (≠ 29318 / 16942 / 12404 / … de sesiones previas) |
| `comm` / TracerPid | `NINJA GAIDEN SI` / 0 |
| process starttime (clk) | 105 · proceso creado 2026-09-07 16:50:20 −06:00 |
| Module base | `0x140000000` (delta ASLR 0, determinista bajo este Proton) |
| core.dll base | `0x6ffff9830000` |
| EXE SHA256 | `a66daf011d22dd6fd6676e0b8ccc68e85448d4570bbac635e25adc1f2d06ffef` ✓ |
| core SHA256 | `ca2849b56c3543351f8a56556e80424cc42cdd685ac8a962543384f726e1db1d` ✓ |
| Hook continuity gate | `u64[base+0x18F9518] == core_base+0x16F2` ✓ (hook 151ea14 vivo) |
| LOCAL_PLAYER | `game_object[0]` → obj RVA `0x3197100`, grp 0, obj_id 0 (resolver RUNTIME VERIFIED) |
| AI_PARTNER | `game_object[4]` → obj RVA `0x319cdb0`, grp 1, obj_id 221 (Momiji; obj_id sigue siendo contador de spawn) |
| Escenario | Team Mission, Ryu + IA Momiji |

## 2. Volcado del `.text` inicializado en runtime

El `.text` del EXE en disco es ciphertext (SteamDRM `.bind`; ver
`RUNTIME_ANALYSIS.md`). Se volcó de memoria con `tools/runtime_text_dump.py`
(read-only, `O_RDONLY` + `pread`):

| sección | RVA | virtual size | runtime VA | SHA256 (imagen ensamblada) | holes |
|---|---|---|---|---|---|
| `.text` | `0x1000` | `0x179C2E0` | `0x140001000`–`0x14179D2E0` | `193894e5311dd6e5452aa9e9940d28bdf1b1e007927991cd72f598f0790bfec5` | 0 (63 segmentos r-x) |
| `.bind` | `0x7294000` | `0x39098` | `0x147294000`–… | `f05ac5e03462a41c9a8aac76b94581c213bc74a339763f0f970b39e2dc4f4a02` | 0 |
| `.rdata` | `0x179E000` | `0x4AC47A` | — | `b5952cc0fd313ca1f2cdaa8db65d90ee7a84bc745a2e2a53693a42d7ad0d62e3` | 0 |
| `.pdata` | `0x6E94000` | `0x133248` | — | `c99da4118a8b18371dff4ca08f09bd37552451e21fdedbedcc5d444a3e35e509` | 0 |

PE `TimeDateStamp` 2021-07-08 09:16:09 UTC (`0x60E6C259` = 1625735769).
`.pdata` = 104838 `RUNTIME_FUNCTION` entries.

Verificación de integridad: `dis 0x1462a00` reproduce byte-a-byte el prólogo
documentado de la función Sigma2 (`mov rax,rsp; push rdi; sub rsp,0x120; …; call
0x1341a90; test al,al`); `func 0x1462a00` = `begin=0x1462a00 end=0x1462cf7
unwind=0x1c13db8`, idéntico al `.pdata` estático.

Artefacto: `docs/research/runtime_text/20260907T1650Z_pid14042/` (`.bin`
git-ignored; `dump_manifest.json` con toda la procedencia y hashes).
Herramienta de análisis offline: `tools/rt_image.py` (capstone en venv aparte).

## 3. Los tres "writers" de la Fase 10, reclasificados con evidencia runtime

`awatch` de solo lectura sobre el dword X en `object+0x2B0` (`0x1431973b0`),
45 hits con Ryu quieto → patrón determinista de 3 accesos por frame:

| RVA | instrucción real | qué hace realmente | ¿escribe `+0x2B0`? |
|---|---|---|---|
| **`0x8C7B4`** | `movdqa [rax+K],xmm` / `movaps xmm,[rax+rdx+K]` (cuerpo memcpy SSE desenrollado) | copia genérica de bloque `obj+0x2a1 → obj+0xae1` y `→ obj+0x1321` (rellena los *mirrors* `+0xAF0` / `+0x1330`). `rdx = src-dst = -0x840 / -0x1080`. | **NO** — solo lee `+0x2B0` |
| **`0xEAD02E`** | `rep movsb` (cola de `memcpy`/`memmove` CRT; entrada real `0xEAD040`) | snapshot del objeto (`rcx ≈ 0x5cb0` bytes) `obj → 0x1433c3xxx` (buffer externo). `rsi ≈ obj+0x2c0`, `rdi = 0x1433c3xxx`. | **NO** — solo lee |
| **`0x1353E41`** | `movdqa [r8+rax*8+0x260],xmm0` | la instrucción **anterior**, `0x1353E37 : movdqa [r8+rax*8+0x250], xmm6` con `r8 = obj+0x60`, `rax = 0`, **ESCRIBE `obj+0x2B0` = `xmm6`**. `xmm6` = out-param de `0xf8e420`. | **SÍ** — este es el writer real |

→ La Fase 10 clasificó los tres como "memcpy genérico". Corrección: `0x8C7B4` y
`0xEAD02E` sí son copia genérica (mirror / snapshot-out y solo **leen** `+0x2B0`);
`0x1353E41` pertenece a una rutina **específica** de sync de transform por actor y
la instrucción real de escritura es `0x1353E37`.

Evidencia: `docs/research/transform_sync/awatch_obj_2B0.txt`.

## 4. La cadena de escritura de `object + 0x2B0` (per-frame, hilo "Updating")

Reconstruida con el `.text` runtime + retornos capturados en la pila en cada
`awatch` stop:

```
[dispatcher de update]  0x1462160:  sub rsp,0x28 ; call qword [rcx+0x10] ; ...
      rcx = [rip+0xdd3cf9]  (objeto global de sistema; call indirecto slot +0x10)
   -> ...
   -> 0x136CBC0   (driver multi-pass de actualización por frame)
        0x136CE0C  call 0x1355B40
        0x136CE11  call 0x1354390        <-- bucle de update de transform por actor
        0x136CE16  call 0x136C450
   -> 0x1354390   for idx in game_object[0 .. 0xA0]  (stride 0x30; r15 = base tabla 0x3195300):
        gate: [rec+0x1a] != 0xff ; [flags[idx] & 2] == 0 ; [[rec]+0x5B56] == 0
        call 0x1350100(rcx = rec)
        (2º bucle, por actor válido)
        call 0x1353780(rdx = rec, cl = idx)
        call 0x1353F10(rdx = rec, cl = idx)
        call 0x1353D00(rdx = rec, cl = idx)   <-- ESCRIBE object+0x2B0
        (3er bucle: obj_pos - ref_pos  ->  tabla de referencia [rip+0x23150c6], stride 0x60)
   -> 0x1353D00(rdx = game_object_record, ecx = index):
        rbx = rec ;  rsi = [rec] = object ptr
        gate: [rec+0x1a]==0 ; [rec+0x1e] vs tabla [rip+0xae4cc5]
        call 0x1350220(rec)                 -> test al
        call 0xF8E280(rec)                  -> deriva character[group], gate char[grp]+0x0B != 0x77
        lea r8=[rsp+0x40] r9=[rsp+0x50] rdx=[rsp+0x98] [rsp+0x20]=&[rsp+0xa0] [rsp+0x28]=rec
        call 0xF7BB70(...)   ->  tail-call  0xF8E420(rec, &outV6, &outV0, ...)
        xmm6 = [rsp+0x40] (= outV6) ;  xmm0 = [rsp+0x50] (= outV0)
        0x1353E37:  movdqa [obj+0x60 + 0x250], xmm6   ==>  object+0x2B0 = xmm6
        0x1353E41:  movdqa [obj+0x60 + 0x260], xmm0   ==>  object+0x2C0 = xmm0
        0x1353E52:  movdqa [obj+0x1930], xmm6
        0x1353E5A:  movdqa [obj+0x1940], xmm0
```

`0x1353D00` tiene 5 call-sites en 4 funciones (`0x1351310`, `0x13514A0`,
`0x1354390` ×2, `0x15D84B0`); la ruta per-frame del jugador es la de `0x1354390`
(retorno `0x135447F` capturado en la pila del `awatch` de `+0x2B0`, hits 3/6/9/…).

### `0xF7BB70` — decisión de LOD / prioridad (lee la fuente de posición)

```
rbx = game_object record  (6º arg en pila) ;  rdi = [rbx] = object
rbp = character[group] = module_base + 0x2F78B10 + group*0x1240
gate: [rdi+0x5B6D] ; [rbp+7]==1 ; global [rip+0x123293F]==0xD (modo)
movups xmm6, [rdi + 0x4B80]                 ; <<< LEE object+0x4B80  (posición fuente)
xmm7 = xmm6.y - [rbp+0x10E4]                ; - character[group]+0x10E4
xmm8 = xmm6.x - [rbp+0x10E0]                ; - character[group]+0x10E0   (posición de referencia)
xmm6 = xmm6.z - [rbp+0x10E8]                ; - character[group]+0x10E8
dist2 = Σ  ;  comiss [rip+0x98B66C], dist2 ; jae (cerca -> salta)
(lejos) movups xmm0..3, [rdi+0x1AB0/0x1AC0/0x1AD0/0x1AE0]  ; matriz 3x3+fila de object
        call 0x6EF50  ; ... métrica de tamaño en pantalla ; ajusta [rbp+0x74]
tail:  mov r8=r15, r9=r14, rdx=r12, [rsp+0x20]=[rsp+0x110], [rsp+0x28]=rbx
       call 0xF8E420   ; <<< productor incondicional de los vectores
```

### `0xF8E420` — productor de los vectores escritos en `object+0x2B0`

Despacha sobre el **byte de tipo de actor** `character[group]+0x04` (códigos
`0xC6 0xC7 0xC8 0xC9 0xCA` = 5 tipos), llama `0xF8CED0` y **`0xF7B430`** (construcción
del transform), hace math con vectores constantes (`[rip+0x98753C]` × `[rip+0x204FE6E]`).
3 call-sites: `0xF24650`, `0xF318A0`, `0xF7BD86` (este último es la cola de `0xF7BB70`).

**Conclusión de la sección:** `object+0x2B0` (y sus ~14 copias observables) se
**re-deriva cada frame** por `0x1353D00` a partir de **`object+0x4B80`** (posición)
transformada respecto a **`character[group]+0x10E0`** (referencia), por
`0xF7BB70` → `0xF8E420` → `0xF7B430`. No es un `memcpy` plano: es una
re-derivación por-actor dentro del bucle de update `0x1354390`.

## 5. `object + 0x4B80` — bloque de estado de movimiento (CANONICAL POSITION — STRONG CANDIDATE)

`scandisp 0x4b80` sobre el `.text` runtime: **66** referencias, de ellas solo **4
sitios de escritura** `mov[..] [reg+0x4b80], xmm`:

| RVA store | función (fragmento `.pdata`) | forma |
|---|---|---|
| `0xF819DA` | `0xF8190E` | `movdqa [rbx+0x4B80], xmm1` — precedido de `addss [rbx+0x4BC0/4BC4/4BC8], xmm` (**integra velocidad**), aplica matriz `rbx+0x1AB0`, `call 0x6FDE0` (mul de matriz), `call 0xF88110` |
| `0xF81A20` | `0xF81A16` | `movss [rbx+0x4B80/4B84/4B88], xmm` — escritura escalar (X/Y/Z) desde locales |
| `0xF8A8EC` | `0xF8A8C0` | `movdqa [rax+0x4B80], xmm0` con `xmm0 = [r8]` (**pos pasada como puntero-arg**) y `[rax+0x1AB0..0x1AE0] = [r9..r9+0x30]` (matriz 4x4 arg). `rax = [tabla[cx]]`. Primitiva "aplicar transform a actor(cx)". |
| `0x147BD31` | `0x147BBDF` | `movss [rax+0x4B80], xmm0` — construcción con constantes identidad (`0x3F800000`), init/spawn placement |

El resto son lecturas: **decenas de `subss xmm, [reg+0x4b80]`** entre actores
distintos (`0xF8FCC0`, `0x1420F60`, `0x14230B0`, `0xF90AFD`, …) = math de
distancia / posición relativa inter-actor; `movaps [rcx+0x4b80]` copiado a
`character[group]+0x1010` (fn `0xF33D97`, junto a `object+0x1AB0` → `char+0x1020`).

`awatch` de solo lectura sobre `object+0x4B80` (44 hits, Ryu quieto): **todos
lecturas** (`movaps xmm,[…+0x4b80]`, `movups xmm0,[rdi]`), ninguna escritura —
igual que `+0x2B0`, el motor **no reescribe `+0x4B80` cuando la velocidad es 0**.
El writer (`0xF8190E`) solo corre en movimiento.

### Layout del bloque `object + 0x4B80 .. 0x4BEF`

| offset | contenido | evidencia |
|---|---|---|
| `object + 0x4B80` | **posición mundo (X,Y,Z,0)** — fuente que alimenta `object+0x2B0` | leída por `0xF7BB70`; se movió 14.55 u en lockstep con `+0x2B0` (r=1.0) |
| `object + 0x4BC0` | **vector de velocidad / movimiento (X,Y,Z)** | `(0,0,0)` en reposo (Ryu y Momiji); `(0,0,1.985)` caminando en −Z; `addss [+0x4BC0], xmm` en `0xF8190E` (integración) |
| `object + 0x4BD0` | **centro de cápsula de colisión (X,Y,Z,1)** | X/Z ≈ posición, Y ≈ posición.Y + ~1.10; jitter ~0.03 en reposo (asentamiento de física) |

## 6. Traza temporal (Fase §8–§9)

`tools/canonical_trace_probe.py` (read-only, 60 Hz), LOCAL_PLAYER + AI_PARTNER:

### IDLE (`TRACE_IDLE_01.json`)

`canon_4B80` == `obs_2B0` == `copy_2E0` == `mirror_1930` == `char_10E0` ==
`char_1010`, **bit-idénticos y estáticos**. `vel_4BC0` = `(0,0,0)`.
`interp_310` / `hist_340` / `hist_370` congelados en posiciones anteriores.

### MOVE (`TRACE_MOVE_01.json`) — Ryu se desplazó ~14.5 u, Momiji lo siguió ~8.5 u

| campo (entry 0 / Ryu) | disp | first → last |
|---|---|---|
| `canon_4B80` | **14.5484** | (-94.94,-0.0,70.42) → (-102.30,-0.0,57.87) |
| `obs_2B0` | **14.5484** | idéntico |
| `copy_2E0` / `mirror_1930` / `char_10E0` | 14.5484 | idéntico |
| `interp_310` / `hist_340` | 2.81 | **lag** (interpolada / historial) |
| `hist_370` | 0.0 | congelado (más antiguo) |
| `vel_4BC0` | rango 3.20 | (0,0,0.15) → **(0,0,1.985)** |
| `capsule_4BD0` | 14.33 | sigue a la posición (Y ≈ +1.08 offset) |
| **xcorr `canon_4B80` vs `obs_2B0`** | **best_lag = 0, r = 1.0000** | (lockstep; el orden intra-frame lo demuestra el RE: `0xF7BB70` LEE `+0x4B80` antes de que `0x1353E37` escriba `+0x2B0`) |

AI_PARTNER (entry 4 / Momiji): arquitectura **idéntica** — `canon_4B80` ==
`obs_2B0`, se movió 8.47 u en lockstep, `vel_4BC0` `(0,0,0)` → `(-0.01,0,2.006)`.

Clasificación §9:
- `object+0x4B80` → **LEADS_RENDER_COPY / SAME_UPDATE** (misma-frame, aguas arriba; alimenta al writer).
- `object+0x2B0` y las ~14 copias → RENDER/OBSERVABLE COPY.
- `object+0x310` (+ `+0x340`) → INTERPOLATED / LAGS_RENDER_COPY.
- `object+0x370` → HISTORICAL.
- `object+0x4BC0` → estado de movimiento (velocity), no una copia de posición.

## 7. Criterios `CANONICAL_POSITION_STRONG_CANDIDATE` (§15)

| criterio | estado |
|---|---|
| estructura fuente identificable | ✅ `object + 0x4B80` (bloque de movimiento `+0x4B80/+0x4BC0/+0x4BD0`), resoluble desde el resolver existente |
| sigue al LOCAL_PLAYER | ✅ 14.55 u en lockstep en el trace de movimiento |
| distinta de las copias observables | ⚠️ **parcial** — numéricamente igual a `+0x2B0` en cualquier instante; distinta en **rol** (es la entrada leída por el writer, no una salida) y en vecindad (`+0x4BC0` velocity, `+0x4BD0` cápsula) |
| alimenta directa o indirectamente al writer | ✅ `0xF7BB70` la lee → `0xF8E420` produce el valor de `+0x2B0` |
| temporalidad coherente | ✅ misma-frame aguas arriba (RE); lockstep wall-clock (r=1.0, lag 0) |
| caller/source pointer demostrado | ✅ cadena `0x1462160 → 0x136CBC0 → 0x1354390 → 0x1353D00 → 0x1353E37`; lectura fuente `0xF7BB70: movups xmm6,[rdi+0x4B80]` |
| persiste durante varios movimientos | ⚠️ **1 movimiento** esta sesión (14.5 u) + IA (8.5 u); el plan pedía "varios" |
| arquitectura equivalente para AI_PARTNER | ✅ `game_object[4]` (Momiji): `+0x4B80/+0x4BC0/+0x4BD0` idénticos, lockstep |
| puede resolverse dinámicamente | ✅ `resolver → object + 0x4B80` |

**Veredicto: `object + 0x4B80` = `CANONICAL_POSITION_STRONG_CANDIDATE`.**
Confianza: **MEDIA-ALTA**.

Caveats honestos:
1. El **writer** de `+0x4B80` se identificó **estáticamente** (`0xF8190E` y familia: integra `+0x4BC0` velocity, aplica la matriz `+0x1AB0`, escribe `+0x4B80`) pero **no se capturó vivo** (solo ocurre en movimiento; con `awatch` el juego va a ~1 fps y no se pudo mover de forma controlada bajo el debugger).
2. No se ha demostrado que `+0x4B80` **no** sea a su vez derivado de algo más profundo (estado del controller en `character[group]`, root-motion de animación). La evidencia (integración de `+0x4BC0`) apunta a que `+0x4B80` + `+0x4BC0` **son** el estado de movimiento, pero falta confirmarlo.
3. Numéricamente `+0x4B80` == `+0x2B0` en reposo y en movimiento, así que la prueba definitiva ("¿una escritura en `+0x4B80` persiste donde `+0x2B0` fue revertida en <150 ms?") **no** se ha hecho — es exactamente MVP 2b, fuera del alcance de esta fase.

## 8. Hilo "Updating"

`0x1462160` es un **stub de dispatch** (`call qword [rcx+0x10]`, relleno `int3`,
cola `jmp qword [rip+…]`): el bucle principal del sistema de update invoca un
vfunc (`[global+0x10]`, `global = [rip+0xDD3CF9]`) que alcanza `0x136CBC0`. Este
llama en secuencia varios pases por frame (`0x1355B40`, **`0x1354390`**,
`0x136C450`, …). El camino
`estado de movimiento (0x4B80/0x4BC0) → 0x1354390 → 0x1353D00 → 0x2B0 observable`
queda establecido; no se reconstruyó el game-loop completo (no era necesario).

`0x14625C0` / `0xC12D40` (visto en la pila del snapshot-out `0xEAD02E`) es otra
rama del tick del frame — coincide con la nota de `RUNTIME_ANALYSIS.md` de que la
función Sigma2 "prepara una llamada con callback 0xc12d90".

## 9. XREFs / signatures (sin marcar estables)

| función | RVA (esta build) | `.pdata` | rol |
|---|---|---|---|
| writer de `object+0x2B0` | store en `0x1353E37`; fragmento `[0x1353D92, 0x1353E84]` (unwind `0x1C02714`) | chunk encadenado | escribe `+0x2B0 = xmm6` |
| per-actor transform sync | `0x1353D00` (`[0x1353D00,0x1353D92]` unwind `0x1C02708` + fragmento anterior) | — | `(rec, idx)` → llama `0xF7BB70` y escribe |
| per-frame actor loop | `0x1354390`–`0x13545F3` (unwind `0x1C027C8`) | sí | itera `game_object[0..0xA0]` |
| update multi-pass driver | `0x136CBC0`–`0x136D05B` (unwind `0x1C03964`) | sí | llama `0x1354390` @ `0x136CE11` |
| LOD/priority + fuente | `0xF7BB70`–`0xF7BC13` (unwind `0x1B970AC`) | sí | lee `object+0x4B80`, `character[grp]+0x10E0` |
| productor de vectores | `0xF8E420`–`0xF8E85F` (unwind `0x1B98B20`) | sí | despacha por `char[grp]+0x04` (0xC6..0xCA), llama `0xF7B430` |
| gate character[group] | `0xF8E280`–`0xF8E379` (unwind `0x1B98B14`) | sí | deriva `char[grp]`, gate `char[grp]+0x0B != 0x77` |
| integrador de posición | `0xF8190E` (fragmento, unwind `0x1B97808`) | chunk | `addss [obj+0x4BC0]` + matriz `obj+0x1AB0` → `movdqa [obj+0x4B80]` |
| aplicar-transform primitivo | `0xF8A8C0`–`0xF8A943` (unwind `0x1B986FC`) | sí | `(cx, dx, r8=&pos, r9=&mat)` → escribe `obj+0x4B80` + `obj+0x1AB0` |
| dispatcher de update | `0x1462160`–`0x146218F` (unwind `0x1C13C38`) | sí | `call [rcx+0x10]` (vtable slot +0x10) |

Todas son RVA module-relative de **esta build** (`a66daf…`); no se han validado
como firmas estables entre versiones.

## 10. Diseño del siguiente experimento (NO ejecutado — MVP 2b)

Ver `docs/MVP2_WRITE_PLAN.md` §"MVP 2B". Resumen: escritura mínima y reversible de
`object + 0x4B80` (world X, +0.30 u) en una ventana `LOCAL_PLAYER_STABLE`, con
`object + 0x4BC0` (velocity) ≈ 0, mismos guards/backup/rollback que
`tools/player_write_test.py`. Hipótesis: al ser `+0x2B0` re-derivado de `+0x4B80`
cada frame, una escritura en `+0x4B80` (con velocity 0) debería **persistir** más
de un frame, a diferencia de la escritura en `+0x2B0` de MVP 2 (revertida en
<150 ms). **Execution authorized: NO.**

## 11. Herramientas nuevas (solo lectura)

- `tools/runtime_text_dump.py` — vuelca secciones ejecutables inicializadas del
  proceso vivo (`O_RDONLY`+`pread`), con manifest (base, RVA, perms, timestamp,
  SHA256 por segmento) y zero-fill de holes. Valida PID único / TracerPid 0 /
  SHA256 EXE+core / continuidad del slot Sigma2.
- `tools/rt_image.py` — análisis offline del volcado (capstone): `dis`, `bytes`,
  `func` (.pdata `RUNTIME_FUNCTION`), `funcs`, `xref` (E8/E9 rel32), `callers`
  (agrupado por función), `scandisp` (stores/loads por displacement). No toca el
  proceso.
- `tools/canonical_trace_probe.py` — traza temporal read-only de
  `object+0x4B80/+0x4BC0/+0x4BD0/+0x2B0/+0x2E0/+0x310/+0x340/+0x370/+0x1930` y
  `character[grp]+0x10E0/+0x1010/+0x310` para LOCAL_PLAYER y AI_PARTNER; burst a
  60 Hz, `--wait-move` (espera a que se mueva), xcorr canon-vs-obs.

## 12. Evidencia

- `docs/research/runtime_text/20260907T1650Z_pid14042/dump_manifest.json` (bins git-ignored).
- `docs/research/transform_sync/`:
  `awatch_obj_2B0.txt` (writer + los 3 accesos por frame),
  `awatch_obj_4B80_char_10E0.txt`, `awatch_obj_4B80_4BC8.txt` (todo lecturas),
  `scan_2b0_2e0_310.txt`, `scan_4b80.txt` (barridos de displacement),
  `TRACE_IDLE_01.json`, `TRACE_MOVE_01.json` (análisis; `frames` recortado),
  `wp*.gdb` (scripts de watchpoint read-only).

## 13. Restricciones respetadas

Sin escrituras en memoria del juego. Sin teleport. AI_PARTNER solo leído. Sin
hooks nuevos. Sin networking. Sin cambios en EXE / `core.dll` / Proton / sysctl.
`gdb` usado solo con `awatch` (hardware, solo lectura) + `detach`; el proceso
siguió vivo, `starttime` estable, hook Sigma2 re-verificado. Sin `git push`.

---

## 14. FASE 12 (2026-09-07, PID 14042) — writer de `object+0x4B80` capturado en movimiento

Detalle completo: **[CANONICAL_WRITER_TRACE.md](CANONICAL_WRITER_TRACE.md)**. Solo
observación: hardware write-watchpoints de gdb + `detach`. 3 capturas (2 movimientos
del LOCAL_PLAYER + 1 del AI_PARTNER autónomo), 130 hits, todos en el thread **`14115`
"Updating"**. Proceso vivo tras la sesión, hook Sigma2 re-verificado.

**Dos writers de `object+0x4B80`, ninguno `memcpy`:**

- **W1 — locomotion `pos += delta`**: instrucción `0x141BBC1` (`movss [rax],xmm1`
  tras `addss xmm1,[rax]`), función leaf **`0x141BB90`** (`object+0x4B80 +=
  delta4`, con guard NaN). Caller: **`0x14249A0`** (≈21 KB, update per-actor) @
  `0x1429B92`, que construye el delta como `movement_vector * scale` (`xmm6`=0.5) y
  llama la primitiva. Dispatcher **`0x1420F60`** (resuelve `&game_object[edx]`,
  10 callers de `0x141BB90` en el cluster `0x1420F60`–`0x1429E38`).
- **W2 — commit de transform**: instrucción `0x14208DD` (`movdqu [rax+0x4B80],
  xmm0`), función **`0x1420841`**; `xmm0` = resultado de `call 0x6FDE0` (matriz),
  recompuesto con w=1.0; `rax` = puntero global al objeto del jugador activo
  (`[rip+0x4FD0DD3]`). Pila → dispatch "Updating" `0x1462160`.
- Solo en AI_PARTNER: la familia transform-sync `0x1353xxx` (`0x1353A5C`,
  `0x1353EF9`) también escribe `+0x4B80`. LOCAL_PLAYER y AI_PARTNER **comparten
  W1 y W2** (capturados en vivo para ambos).

**`+0x4BC0` (velocity)**: `(0,0,0)` en reposo (ambos actores); rampa monótona con
la aceleración; reset por frame; dirección coherente (AI diagonal → X y Z no
nulos). Writers de `+0x4BC0` (`0xF8190E`, `0x14218C0`, `0x14219A0`) en el mismo
subsistema y con el mismo puntero global; `0xF8190E` escribe posición **y**
velocity juntas.

**`+0x4BD0` (cápsula)**: `(x, y+~1.05, z, 1)`; se desplaza junto a `+0x4B80`.

**Veredicto FASE 12: `object + 0x4B80` = `CANONICAL_POSITION_RUNTIME_VERIFIED`**
(los 9 criterios §12 del plan cumplidos). Confianza **ALTA**. Caveats: `+0x4B80`
recibe 2 escrituras/frame (integración W1 + commit de transform W2); no se
demostró que el input de la matriz de W2 no venga de algo más profundo en
`character[group]`; la prueba definitiva es MVP 2B (diseñada, no ejecutada).


## MVP 2B EJECUTADO — PASS (2026-09-07)

`object+0x4B80` escrito una vez (`+0.30` X, `tools/player_write_test_2b.py`, autorizado por el usuario). **La escritura se mantuvo ~3.5 s** (el motor NO la revirtió) y **`object+0x2B0` convergió** al valor nuevo en ≤ 1 frame; restauración `EXACT`; sin crash; Y/Z/velocity/rotación/AI_PARTNER intactos. Usuario: `NO NOTE MOVIMIENTO PERO TODO NORMAL` (delta pequeño para la escala del mundo, no reversión). ⇒ `object+0x4B80` es **escribible de forma persistente y propaga** — primitivo de teleport real. Detalle: [MVP2B_WRITE_TEST_01.md](MVP2B_WRITE_TEST_01.md).


## FASE 13 — cadena de control de locomoción (2026-09-08, PID 14042)

Detalle: **[LOCOMOTION_CONTROLLER_RESEARCH.md](LOCOMOTION_CONTROLLER_RESEARCH.md)**. Solo lectura/observación (probe + write-watchpoints + `detach`). Proceso vivo tras la sesión, hook Sigma2 re-verificado.

- **`character[group] + 0x30` (float4)** = **comando de dirección de movimiento (suavizado)**: `(0,0,0,0)` en reposo, específico de dirección al moverse, **idéntico para LOCAL_PLAYER y AI_PARTNER** (Momiji: no-cero solo cuando siguió a Ryu). Es lo que `0x14249A0` consume para construir el delta de W1 (`object+0x4B80 +=`). ⇒ **`REMOTE_CONTROL_INJECTION_CANDIDATE` (STRONG CANDIDATE)** — punto de convergencia input-local / cerebro-IA.
- **`character[group] + 0x04` (byte)** = **state code de locomoción / selector de animación**: `0x00` idle, `0x06` start, `0x0A` lateral, `0x26/0x28/0x2A` walk/run, `0x48` run de IA. Enum compartido; es el selector de la jump table de `0x14249A0`. Un teleport puro (solo `+0x4B80`) deja `char+0x04 = 0` → sin animación (lo observado en MVP 2B +10.0).
- **`character[group] + 0x24`** = parámetro de locomoción del estado (tabla de animación, escrito por `0xF1ECA0`), **no** magnitud de stick.
- **`object + 0x4BC0` (velocity)** = **resultado DERIVADO** (velocity real suavizada, ease-in ~0.5 s, publicada para animación/cámara) — **no** la entrada de la integración de locomoción.
- **Writer de `char+0x30`**: pc `0xF25054` (`movdqu [char+0x30], xmm3`) en fn `0xF24F4A`, hilo "Updating" — un **filtro EMA**: `char+0x30 = char+0x30_old*decay + input_sample*weight` (la `w` hace ease-in `0.25→1.0` al acelerar). La muestra viene de una tabla/ring indexada por un contador de frame global (`[rip+0x20815D8]` base — RVA exacta sin confirmar).
- Siguiente experimento (**solo diseño, NO ejecutado, NO autorizado**): escribir una dirección unitaria en `char+0x30` durante ~N frames (el EMA exige varios) en `LOCAL_PLAYER_STABLE` → Ryu debería **caminar con animación** (sin teleport, delta acotado por el speed-clamp `0x1469F60()`).
