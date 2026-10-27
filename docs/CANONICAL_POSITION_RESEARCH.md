# Canonical player position — Fase 10

Estado: 2026-09-06, tras `787a0fd`. **Solo lectura / análisis.** Sin escritura de posición, sin teleport tests, sin tocar AI_PARTNER, sin HP/input/networking/hooks nuevos, sin cambios en `core.dll` / EXE / Proton.

## 0. Contexto

MVP 2 WRITE TEST 01 = PARTIAL: una escritura de 4 bytes en `object+0x2B0` (world X, +0.30 u) **entró** en memoria pero el motor la **revirtió en < ~150 ms**. `object+0x2B0/+0x2B4/+0x2B8` es RUNTIME VERIFIED **como posición observable** (Fase 7), pero **no es la posición autoritativa/canónica**. Fase 10 busca desde dónde el motor la re-deriva cada frame.

## 1. Evidencia de por qué `object+0x2B0` no es autoritativo

| Sonda (solo lectura) | Resultado |
|---|---|
| MVP 2 write | +0.30 en X revertido por el motor en < ~150 ms |
| gdb `watch` (cambio de valor) en `object+0x2B0`, Ryu quieto | **0 hits en 30 s** → cada frame se escribe el **mismo** valor |
| gdb `awatch` (acceso lectura+escritura) | hits constantes desde **3 sitios de `.text`**, y los 3 son **rutinas genéricas de copia de bloque** (`memmove`/`memcpy`: `movaps`/`movdqa`/`movq` en bucle). RVA `0x8C7B4` (memcpy inline) confirmado como *toucher* por frame; también RVA `0x1353E41` y RVA `0xEAD02E` |
| Hilo | **«Updating»** (hilo de update del juego, nombre del LWP) |
| `disassemble <rango>` en esos RVAs | gdb devuelve vacío repetidamente (secciones protegidas SteamDRM/`.bind`); `x/i` puntual sí funciona |
| hbreak condicional en el memcpy para capturar la fuente | 0 de 2000 hits cumplieron la condición de dirección → memcpy demasiado genérico/caliente |

**Conclusión:** cada frame el motor **copia un bloque de transform dentro de `object`** (RVA `0x3197100`). `object+0x2B0` es una **copia de trabajo / snapshot por frame**. **NO existe** una instrucción dedicada `movss [object+0x2B0], xmm` de actualización de posición; es una copia de struct completa. La **fuente canónica de esa copia no se aisló** con las herramientas de solo lectura disponibles (`/proc/<pid>/mem` + gdb en batch).

## 2. Mapa de copias de posición (tabla requerida)

Verificado con `LOCAL_PLAYER_STABLE` (base) y un desplazamiento controlado de **1.3543 u** (`tools/position_sources_probe.py`).

| Structure | Offset | Representation | Relation to observable XYZ | Temporal behavior | Writer evidence | Status |
|---|---|---|---|---|---|---|
| object (RVA 0x3197100) | +0x2B0 | float3 (X,Y,Z) | = XYZ observable | sigue al jugador EXACTO; idéntico al resto en reposo; **revertido en <150 ms** tras escribir | escrito por copia de bloque por frame (RVA 0x8C7B4 etc.), hilo «Updating» | RENDER/OBSERVABLE COPY |
| object | +0x2E0, +0xAF0, +0xB20, +0x1330, +0x1360, +0x1930 | float3 | = +0x2B0 (byte-idénticos en reposo) | siguen al jugador EXACTO (Δ 1.3543 u) | mismas copias de bloque | RENDER/OBSERVABLE COPY |
| object | +0x310 (y variantes transitorias +0xB50, +0x1390 justo tras moverse) | float3 | ≈ XYZ pero **con lag** | retrasa durante el movimiento, se pone al día en reposo | — | INTERPOLATED POSITION |
| object | +0x340 | float3 | posición **anterior** | no cambia al moverse; sostiene la posición previa | — | HISTORICAL/PREVIOUS POSITION |
| object | +0x370 | float3 | posición **anterior a la anterior** | igual, más antigua | — | HISTORICAL/PREVIOUS POSITION |
| character[group] (RVA 0x2F78B10 + grp*0x1240) | +0x310, +0xFE0, +0x1010, +0x10E0, +0x1120, +0x1160, +0x1170 | float3 | = XYZ observable | siguen al jugador EXACTO (Δ 1.3543 u); byte-idénticos en reposo | copia de bloque por frame | RENDER/OBSERVABLE COPY |
| AI_PARTNER object (game_object[4]) | +0x2B0, +0x2E0, +0xAF0, +0xB20, +0x1330, +0x1360, +0x1930 | float3 | XYZ del compañero | equivalente estructural al LOCAL_PLAYER (no escrito) | — | RENDER/OBSERVABLE COPY (equivalente) |
| AI_PARTNER character[group] | +0x310, +0x950, +0xFE0, +0x1010, +0x10E0, +0x1120, +0x1160, +0x1170 | float3 | XYZ del compañero | equivalente estructural (no escrito) | — | RENDER/OBSERVABLE COPY (equivalente) |
| **canonical position** | **desconocido** | — | alimenta las copias de arriba cada frame | precede a `object+0x2B0` (se copia dentro cada frame) | copia de bloque por frame; fuente sin aislar | **UNKNOWN — no localizado** |

## 3. Otros hallazgos

- **`object` es datos estáticos autocontenidos**: sin puntero a un cuerpo de física en heap en `object[0..0x2000]`. Los "punteros a heap" del escaneo eran floats (1.0f, etc.) mal interpretados.
- **Sin candidato de velocidad limpio**: en reposo no hay float3 ≈ (0,0,0) evidente cerca de la posición; los "float3 pequeños" son fragmentos de la matriz de rotación o lecturas desalineadas.
- **Root motion / animación**: NGS puede derivar la posición canónica de locomoción/animación cada frame en registros antes de la copia de bloque; encaja con "no hay struct canónica localizable en reposo" y con "escritura del mismo valor cada frame en reposo".
- **AI_PARTNER equivalente**: misma arquitectura de copias (7 en object + 7-8 en character). Relevante para multiplayer: si se localiza la canónica del LOCAL_PLAYER, habrá una equivalente para el compañero. **No se escribió el compañero.**
- **Limitación de herramientas**: en este binario Wine/Proton + SteamDRM, gdb `awatch`/`hbreak` disparan pero `watch` (cambio de valor) no dispara de forma fiable; `disassemble` de rango devuelve vacío en las secciones protegidas. Aislar la fuente del memcpy requeriría un enfoque que estas herramientas no dieron limpiamente.

## 4. Clasificación por candidato (§12 del plan)

| Campo | Clasificación |
|---|---|
| object +0x2B0/+0x2E0/+0xAF0/+0xB20/+0x1330/+0x1360/+0x1930 | RENDER/OBSERVABLE COPY |
| character[grp] +0x310/+0xFE0/+0x1010/+0x10E0/+0x1120/+0x1160/+0x1170 | RENDER/OBSERVABLE COPY |
| object +0x310 (+ transitorios +0xB50/+0x1390) | INTERPOLATED POSITION |
| object +0x340, +0x370 | HISTORICAL/PREVIOUS POSITION |
| velocidad | UNKNOWN (no aislada) |
| física / rigidbody | UNKNOWN (sin evidencia de estructura de física que alimente la posición) |
| **canonical position** | **UNKNOWN — no localizado** |

Ningún candidato marcado `CANONICAL_POSITION_STRONG_CANDIDATE`. Confianza en posición canónica: **LOW**.

## 5. Herramientas nuevas (solo lectura)

- `tools/position_sources_probe.py`: resuelve LOCAL_PLAYER desde cero, mapea todas las copias float3 ≈ XYZ en `object`/`character`, busca candidatos de velocidad, hace un burst de alta frecuencia (120 lecturas/2 s de todos los offsets conocidos) y compara base↔movido (`--compare`) para separar copias que siguen al jugador de las stale/interpoladas. Sin escrituras.
- Scripts gdb de watchpoint/breakpoint de solo lectura en `/tmp/ngs2coop/*.gdb` (efímeros): `watch`/`awatch`/`hbreak` sobre `object+0x2B0`; NO modifican memoria del juego; `detach` al final; el juego siguió normal.

## 6. `Ready for MVP 2b controlled canonical write`: **NO**

No hay candidato canónico fuerte al que apuntar. La escritura de posición **no** se reintenta en esta fase.

### Siguiente paso (fase posterior; no ahora)

1. RE estática más profunda de la función de sincronización de transform del hilo «Updating»: seguir de dónde sale el puntero/registro fuente del memcpy (RVA `0x8C7B4` / `0x1353E41` / `0xEAD02E`), con volcado del `.text` inicializado ya en memoria y desensamblado offline (evitando la limitación de `disassemble` de gdb).
2. Alternativa: un **hook temporizado por frame** que se ejecute justo después de la copia de transform y escriba la posición ahí — pero eso es un **hook nuevo**, fuera del alcance de las fases de solo lectura; requeriría su propio diseño y autorización.
3. Alternativa de bajo riesgo para una prueba futura: write-probe de cada una de las ~14 copias + un test de **override sostenido a alta frecuencia** (escribir el valor cada frame) para ver si alguna copia "gana" — solo diseño, no en esta fase.

## 7. `=== MVP 2B PLAN ===`

No aplica en esta fase: **no existe candidato canónico fuerte**, así que no se diseña MVP 2b. Cuando exista (tras el paso 1 o 2 de §6), MVP 2b sería otra escritura mínima y reversible con los **mismos guards, backup y rollback** que `tools/player_write_test.py` (MVP 2), aplicada al campo canónico, y **no ejecutada** hasta autorización explícita.

**Execution authorized: NO — no hay plan de escritura porque no hay target canónico.**

---

## 8. FASE 11 (2026-09-07, PID 14042) — fuente autoritativa localizada

Detalle completo: [TRANSFORM_SYNC_RESEARCH.md](TRANSFORM_SYNC_RESEARCH.md).
Solo lectura (volcado del `.text` runtime + `awatch` de gdb + `detach`).

**Corrección de la §1 / §4 de este documento:** de los tres RVA de la Fase 10,
`0x8C7B4` y `0xEAD02E` **solo leen** `object+0x2B0` (rellenan mirrors `+0xAF0`/`+0x1330`
y hacen un snapshot-out `obj → 0x1433c3xxx`); el writer real es la instrucción
**`0x1353E37`** (`movdqa [obj+0x60+0x250], xmm6`), en un fragmento de la rutina
específica de sync de transform por actor `0x1353D00`. NO es memcpy genérico.

**Cadena per-frame (hilo "Updating"):**
`0x1462160` (dispatch `call [rcx+0x10]`) → `0x136CBC0` → `0x1354390` (bucle sobre
`game_object[0..0xA0]`) → `0x1353D00(rec, idx)` → `call 0xF7BB70` → `call 0xF8E420`
→ `xmm6` → `0x1353E37` escribe `object+0x2B0`.

**`0xF7BB70` LEE `object + 0x4B80`** (posición) y `character[group]+0x10E0`
(referencia) para producir el valor de `+0x2B0`.

**`CANONICAL_POSITION_STRONG_CANDIDATE = object + 0x4B80`** (confianza MEDIA-ALTA):
- bloque de estado de movimiento: `+0x4B80` posición · `+0x4BC0` **velocity**
  (`(0,0,0)` en reposo, `(0,0,1.985)` caminando) · `+0x4BD0` centro de cápsula.
- alimenta al writer de `+0x2B0`; se mueve en lockstep con `+0x2B0` (r=1.0) pero
  aguas arriba en la misma frame (RE: se lee antes de escribir `+0x2B0`).
- `game_object[4]` (AI_PARTNER, Momiji) tiene el **mismo layout** `+0x4B80/+0x4BC0/+0x4BD0`.
- solo 4 sitios de escritura de `[reg+0x4b80]`; el principal (`0xF8190E`) integra
  `+0x4BC0` velocity + matriz `+0x1AB0` → `+0x4B80` (paso de movimiento/física).

Caveats: writer de `+0x4B80` identificado **estático**, no capturado vivo (solo
corre en movimiento); no se ha probado que `+0x4B80` no derive de algo aún más
profundo; la prueba definitiva (¿escritura persistente?) es MVP 2b, no ejecutada.

**Ready for MVP 2b controlled canonical write: sí para DISEÑO** (ver
`MVP2_WRITE_PLAN.md` §MVP 2B). **Execution authorized: NO.**

---

## 9. FASE 12 (2026-09-07, PID 14042) — `object+0x4B80` = CANONICAL_POSITION_RUNTIME_VERIFIED

Detalle: [CANONICAL_WRITER_TRACE.md](CANONICAL_WRITER_TRACE.md). Hardware write-watchpoints
de solo observación + `detach`. 130 hits en el thread "Updating" (2 movimientos del
LOCAL_PLAYER + AI_PARTNER autónomo).

**Writer de `object+0x4B80` capturado en movimiento** — dos rutas, ninguna `memcpy`:
- **W1 `0x141BB90`**: `object+0x4B80 += (movement_vector * scale)` (primitiva leaf,
  guard NaN). Caller `0x14249A0` (update per-actor ≈21 KB) @ `0x1429B92`;
  dispatcher `0x1420F60` (indexa `game_object`). Integración de locomotion.
- **W2 `0x14208DD`**: `movdqu [obj+0x4B80], transform_result` (resultado de matriz
  `0x6FDE0`, w=1). Commit de transform (probable snap de suelo/colisión).
- LOCAL_PLAYER y AI_PARTNER comparten W1 y W2 (capturados en vivo para ambos).

`+0x4BC0` velocity: `(0,0,0)` en reposo, rampa con aceleración, reset por frame,
dirección coherente; writers en el mismo subsistema (`0xF8190E` escribe posición+velocity).

**Los 9 criterios §12 del plan cumplidos** ⇒ **`object + 0x4B80` =
`CANONICAL_POSITION_RUNTIME_VERIFIED`**, confianza **ALTA**. Caveats: 2 escrituras/frame
(W1 integración + W2 commit de transform); no se descartó que el input de W2 venga de
`character[group]`; prueba definitiva = MVP 2B (diseñada, NO ejecutada, ver
[MVP2_WRITE_PLAN.md](MVP2_WRITE_PLAN.md) §MVP 2B). **Execution authorized: NO.**


## MVP 2B EJECUTADO — PASS (2026-09-07)

`object+0x4B80` escrito una vez (`+0.30` X, `tools/player_write_test_2b.py`, autorizado por el usuario). **La escritura se mantuvo ~3.5 s** (el motor NO la revirtió) y **`object+0x2B0` convergió** al valor nuevo en ≤ 1 frame; restauración `EXACT`; sin crash; Y/Z/velocity/rotación/AI_PARTNER intactos. Usuario: `NO NOTE MOVIMIENTO PERO TODO NORMAL` (delta pequeño para la escala del mundo, no reversión). ⇒ `object+0x4B80` es **escribible de forma persistente y propaga** — primitivo de teleport real. Detalle: [MVP2B_WRITE_TEST_01.md](MVP2B_WRITE_TEST_01.md).
