# MVP 2 — plan de la primera escritura controlada de posición (SOLO DISEÑO)

Estado: 2026-09-06, HEAD tras Fase 9. **Este documento es únicamente el diseño del experimento. NO se ejecuta ninguna escritura en esta fase.** No hay hook nuevo, no se modifica `core.dll`, no se toca el compañero IA, no hay teleport, no hay networking, no se modifica Y, no se modifica rotación.

## 0. Por qué se considera «Ready»

Checklist de §14 del plan de Fase 9:

| Requisito | Estado | Evidencia |
|---|---|---|
| LOCAL_PLAYER RUNTIME VERIFIED | ✅ | Fase 6/7; re-resuelto desde cero tras reinicio completo (Fase 9, PID 29318) |
| XYZ RUNTIME VERIFIED | ✅ | Fase 7: `object+0x2B0/+0x2B4/+0x2B8` = world X/Y/Z, right-handed Y-up |
| resolver reproducible | ✅ | reinicio de posición (Fase 6) + reinicio de actores (Fase 9) + 3 Team Missions |
| protocolo `LOCAL_PLAYER_STABLE` | ✅ | Fase 8: 10 muestras / 0.5 s / tol. horiz. 0.05 u / tol. vert. 0.05 u |
| dirección exacta obtenida dinámicamente | ✅ | `tools/player_resolver.py` la deriva de `/proc/<pid>/maps` + tabla `game_object`, sin direcciones absolutas fijas |
| game version / core gates | ✅ | SHA256 EXE `a66daf…`, SHA256 core `ca2849…`, slot Sigma2 → `core+0x16F2` (hook 151ea14 vivo) |
| backup / rollback diseñado | ✅ | este documento, §5–§7 |
| distinguir LOCAL_PLAYER de AI_PARTNER | ✅ | `char[group]+0x00 == 0x00` (local) vs `0x04` (IA/enemigos) + `game_object` index 0 + layout de personaje vivo. `CONTROL_DISCRIMINATOR_CANDIDATE`, reproducido en 3 Team Missions + reinicio |

No requeridos por §14 y que siguen abiertos: **pitch/roll = NOT VERIFIED** (nunca ejercitados; el yaw/matriz sí es RUNTIME VERIFIED), **character ID = CANDIDATE** (`char[group]+0x16`: Ryu `0x4e`, Ayane `0xb6`; 2 puntos, baja confianza; `obj_id` sigue REJECTED). Ninguno bloquea una escritura de UN eje horizontal.

**READY FOR MVP 2 CONTROLLED POSITION WRITE: YES.**

## 1. Objetivo del experimento

Demostrar, de forma mínima y reversible, que escribir `object + 0x2B0` (world X del jugador local) mueve al personaje de forma coherente y que la restauración devuelve el estado original — sin usar hooks, sin tocar el core, sin afectar al compañero IA ni la física vertical.

Alcance: **una** ejecución controlada, con el usuario presente confirmando cada paso, `LOCAL_PLAYER_STABLE` antes de escribir, y restauración inmediata.

## 2. Target

| Campo | Valor |
|---|---|
| Actor | LOCAL_PLAYER = `game_object[0]` (`module_base + 0x3195300` → entrada 0 → objeto), validado además por `char[group 0]+0x00 == 0x00` y layout de personaje vivo |
| Dirección | `object + 0x2B0` (world **X** / componente C0), 4 bytes, float32, alineado a 4 |
| NO tocar | `+0x2B4` (Y, riesgo suelo/física) · `+0x2B8` (Z) · matriz de rotación `char[group]+0x80` · cualquier entrada ≠ 0 · el objeto del compañero IA |

Todas las direcciones se resuelven **en el momento** para el PID vivo; nunca se reutiliza una dirección de una sesión anterior.

## 3. Delta propuesto

- **+0.30 unidades** sobre C0/X (un solo eje horizontal).
- Justificación de la escala: la deriva de un «idle real» observada es < 0.07 u; la tolerancia `LOCAL_PLAYER_STABLE` es 0.05 u; un paso deliberado del jugador son ~8–40 u. 0.30 u es claramente visible/medible, muy por debajo de un paso (no pelea con la física de locomoción) y lo bastante pequeño para que, si la colisión/física del juego lo reajusta, sea un resultado informativo y no un riesgo de crash.
- Dirección: `+` arbitraria; el signo se fija antes de ejecutar.
- Rango absoluto tras el delta debe seguir siendo finito y `|valor| < 1e6` (sanity check, §5).

## 4. Mecanismo (fuera del core)

- Herramienta futura independiente `tools/player_write_test.py` (aún no creada): abre `/proc/<pid>/mem` con `O_RDWR`, hace **un** `pwrite` de 4 bytes en `object + 0x2B0`. Sin `ptrace`, sin suspender el proceso, sin hook, sin tocar `core.dll` ni `plugin/`.
- Lectura y escritura de 4 bytes alineados = atómica a efectos prácticos en x86-64 para un float alineado; no se requiere CAS. No se escribe mientras el juego pueda estar a mitad de un tick que reubique al jugador (se elige una ventana `LOCAL_PLAYER_STABLE`).
- El core validado (hook Sigma2 151ea14) permanece intacto y solo se usa como **gate de continuidad** (comprobar que el slot sigue apuntando a `core+0x16F2` antes de escribir).

## 5. Precondiciones y guards (todas obligatorias antes de escribir)

1. **Proceso**: exactamente un `comm == "NINJA GAIDEN SI"`; `TracerPid == 0`; leer PID y `starttime`.
2. **Identidad de binarios**: SHA256 del EXE mapeado == `a66daf011d22dd6fd6676e0b8ccc68e85448d4570bbac635e25adc1f2d06ffef`; SHA256 de `plugin/core.dll` == `ca2849b56c3543351f8a56556e80424cc42cdd685ac8a962543384f726e1db1d`. Mismatch ⇒ abortar sin escribir.
3. **Hook vivo**: `u64[module_base + 0x18F9518] == core_base + 0x16F2`. Mismatch ⇒ abortar.
4. **Resolver**: `object = u64[module_base + 0x3195300 + 0]`; `group = u8[+0x1F]`; comprobar `object` legible para al menos `+0x400`.
5. **Identidad de actor local**: `char[group]+0x00 == 0x00` **y** layout de personaje vivo (`obj+0x60` quaternion con `|q| ∈ [0.9,1.1]` **y** `obj+0x90` header no-cero). Si no se cumple ⇒ abortar (no estamos ante el jugador local).
6. **`LOCAL_PLAYER_STABLE`**: 10 muestras a 0.5 s de `object+0x2B0`; `max−min` por eje horizontal ≤ 0.05 u y vertical ≤ 0.05 u; desplazamiento primera→última ≤ 0.05 u. Si `UNSTABLE_LOCAL_PLAYER` ⇒ NO escribir, reintentar más tarde.
7. **Range check del valor actual**: `X`, `Y`, `Z` finitos y `|componente| < 1e6`; `Y` dentro de ±0.05 u de la media de la ventana (el jugador no está cayendo).
8. **Confirmación humana** explícita inmediatamente antes de la escritura.

## 6. Backup / log

- Antes de escribir: guardar `original_bytes` (los 4 bytes crudos de `object+0x2B0`), `original_float`, `object` (RVA + dirección absoluta de ejemplo), `module_base`, PID, `starttime`, hora ISO, hashes de los gates, y el resultado completo de `LOCAL_PLAYER_STABLE`, en `docs/research/player/MVP2_WRITE_TEST_<timestamp>.json` **y** en un archivo aparte `*.bak` con los 4 bytes.
- Log append-only de cada paso (leer / guardar / gates / escribir / observar / restaurar / verificar) con timestamps.
- Nada se instala en el juego; el backup es local al repo.

## 7. Secuencia del experimento (a ejecutar SOLO con autorización futura)

1. Resolver LOCAL_PLAYER (§5.4–5.5).
2. Esperar `LOCAL_PLAYER_STABLE` (§5.6).
3. Leer y guardar XYZ original + 4 bytes crudos (§6).
4. Verificar todos los guards (§5).
5. Pedir confirmación humana.
6. `pwrite` de 4 bytes: `object+0x2B0 = original_float + 0.30`. Un solo write.
7. Observación acotada: durante ≤ 3 s, leer `object+0x2B0` a 0.5 s; registrar el valor efectivo (el juego puede aceptar, clamplear o reajustar), la Y (debe permanecer ≈ original ±0.1 u), y pedir al usuario que confirme si Ryu se desplazó ~0.3 u en una dirección horizontal y si todo sigue estable (sin crash, sin caída, sin ragdoll).
8. **Restaurar**: `pwrite` de los 4 bytes originales guardados en `object+0x2B0`.
9. Verificar restauración: releer `object+0x2B0`; debe volver a `original_float` (o a un valor dentro de 0.05 u si la física ya movió al jugador). Registrar `char+0x310` como corroboración.
10. Pedir al usuario confirmación de que Ryu está de vuelta en su sitio y el juego sigue normal.

## 8. Timeout / manejo de fallos

- **Ventana total del experimento** ≤ 30 s desde el primer write. Si a los 30 s no se ha restaurado por cualquier motivo ⇒ intentar la restauración una vez más y, si falla, registrar `RESTORE FAILED`, avisar al usuario y pedir cierre normal del juego (la posición no persiste entre misiones/arranques; un cierre normal la descarta).
- **Write falla** (`pwrite` corto / `EIO` / rango no escribible): abortar, no reintentar, registrar; el estado del juego no se ha tocado.
- **`object` deja de ser legible / `starttime` cambia** entre resolver y escribir: abortar (el proceso cambió).
- **Crash / cuelgue del juego tras el write**: no reintentar nada; registrar el estado, la evidencia y los hashes; el usuario reinicia; la posición no persiste.
- **Y se mueve > 0.1 u tras el write** (indicio de interacción con suelo/física): restaurar inmediatamente y marcar el experimento como `PARTIAL — vertical side-effect`.
- **`UNSTABLE_LOCAL_PLAYER` reaparece durante la observación**: restaurar inmediatamente.
- Nunca se escribe una segunda vez sin volver a pasar todos los guards.

## 9. Qué NO incluye este MVP 2

- No se escribe Y ni Z.
- No se escribe la rotación.
- No se toca `game_object[4]` (compañero IA) ni ninguna otra entrada.
- No teleport (delta grande), no input injection, no HP, no networking, no hook nuevo, no cambios en `core.dll` / Proton / EXE.
- No se afirma nada sobre persistencia entre misiones ni entre arranques.

## 10. Criterio de éxito del futuro MVP 2

- [ ] Todos los guards PASS.
- [ ] `LOCAL_PLAYER_STABLE` antes de escribir.
- [ ] El write de 4 bytes se aplica sin crash.
- [ ] El usuario confirma un desplazamiento horizontal pequeño y coherente de Ryu.
- [ ] Y permanece dentro de ±0.1 u (sin efecto vertical).
- [ ] La restauración devuelve `object+0x2B0` a su valor original.
- [ ] El usuario confirma que Ryu vuelve a su sitio y el juego sigue normal.
- [ ] El compañero IA no se ve afectado.

Si todo se cumple: `object+0x2B0` (world X) sería **WRITE-VERIFIED** para un delta pequeño y reversible. Solo entonces se plantearía escalar (otro eje, deltas mayores, o el compañero) en una fase posterior.

**Execution authorized: NO — PLAN ONLY.**

---

## EJECUTADO — 2026-09-06: resultado PARTIAL

El experimento de §7 se ejecutó una vez, autorizado por el usuario (`ZONA ESTABLE PARA MVP2` → `AUTORIZO WRITE +0.30 X`). Herramienta: `tools/player_write_test.py`. Detalle completo en [MVP2_WRITE_TEST_01.md](MVP2_WRITE_TEST_01.md).

- Todos los gates PASS · `LOCAL_PLAYER_STABLE` PASS · un `pwrite` de 4 bytes en `object+0x2B0` (X `67.845779` → `68.145779`).
- Readback inmediato = valor escrito (la escritura entró). A los ~150 ms `object+0x2B0` ya contenía el valor original: **el motor lo sobrescribe cada tick desde un estado canónico**.
- Restauración automática `EXACT`. Sin crash. Y/Z/rotación/mirror/AI_PARTNER no tocados. Usuario: `NO NOTE MOVIMIENTO`.
- **Verdict: PARTIAL.** `object+0x2B0` = copia de lectura, no escribible de forma persistente. Siguiente objetivo (fase posterior, no ahora): localizar el estado autoritativo de posición.

No se repite el experimento. No se intenta otra escritura.

---

## MVP 2B — WRITE PLAN (SOLO DISEÑO — NO EJECUTADO)

Estado: 2026-09-07, tras Fase 11 ([TRANSFORM_SYNC_RESEARCH.md](TRANSFORM_SYNC_RESEARCH.md)).
**Este apartado es únicamente el diseño. NO se ejecuta ninguna escritura en la
Fase 11.** Sin hook nuevo, sin tocar `core.dll`/EXE/Proton, sin AI_PARTNER, sin
teleport, sin networking, sin modificar Y/Z/rotación.

### Por qué ahora hay un target

MVP 2 demostró que `object+0x2B0` (world X) es una **copia de lectura**: el motor
la revierte en <~150 ms porque cada frame la **re-deriva** de un estado más
profundo. La Fase 11 localizó ese estado:

- `object+0x2B0` se escribe en `0x1353E37` (`movdqa [obj+0x60+0x250], xmm6`),
  dentro de `0x1353D00`, en el bucle per-frame `0x1354390` del hilo «Updating».
- El valor (`xmm6`) lo produce `0xF8E420`, llamado vía `0xF7BB70`, que **lee
  `object + 0x4B80`** (posición) y `character[group]+0x10E0` (referencia).
- `object + 0x4B80` es el `CANONICAL_POSITION_STRONG_CANDIDATE`: bloque de estado
  de movimiento `+0x4B80` posición / `+0x4BC0` **velocity** / `+0x4BD0` cápsula;
  se mueve en lockstep con `+0x2B0` pero **aguas arriba en la misma frame**;
  layout equivalente en `game_object[4]` (AI_PARTNER).

**FASE 12 ([CANONICAL_WRITER_TRACE.md](CANONICAL_WRITER_TRACE.md)) elevó `object + 0x4B80`
a `CANONICAL_POSITION_RUNTIME_VERIFIED`** (confianza ALTA): hardware
write-watchpoints capturaron sus writers durante 2 movimientos del LOCAL_PLAYER y
el movimiento autónomo del AI_PARTNER (130 hits, thread "Updating"):
- **W1 `0x141BB90`**: `object+0x4B80 += (movement_vector * scale)` — integración de
  locomotion (primitiva leaf con guard NaN), desde el update per-actor `0x14249A0`,
  dispatcher `0x1420F60` que indexa `game_object`.
- **W2 `0x14208DD`**: `movdqu [obj+0x4B80], transform_result` (matriz `0x6FDE0`, w=1) —
  commit de transform / probable snap de suelo-colisión.
- Ninguno es `memcpy`. `+0x4BC0` velocity = `(0,0,0)` en reposo, rampa con la
  aceleración, reset por frame. LOCAL_PLAYER y AI_PARTNER **comparten W1 y W2**.

Caveat que MVP 2B ha de tener en cuenta: `+0x4B80` recibe **2 escrituras por
frame** (W1 integración + W2 commit). Si W2 recompone desde una matriz cuyo input
es independiente de `+0x4B80`, una escritura en `+0x4B80` podría ser sobrescrita
por W2 en el mismo frame — igual que le pasó a `+0x2B0` en MVP 2, pero un frame
después. El experimento sigue siendo informativo en los tres resultados posibles.

### `=== MVP 2B WRITE PLAN ===`

| campo | valor |
|---|---|
| **Target** | LOCAL_PLAYER = `game_object[0]` → `object + 0x4B80` (world **X** / C0), 4 bytes float32, alineado a 4. |
| **Resolver** | `tools/player_write_test.py` extendido: misma cadena `module_base + 0x3195300` → entrada 0 → `object`; nuevo offset `POS_OFF = 0x4B80` (en vez de `0x2B0`). Dirección resuelta **en el momento**, nunca reutilizada. |
| **Position offset** | `object + 0x4B80` (X). **NO** tocar `+0x4B84` (Y), `+0x4B88` (Z), `+0x4BC0..+0x4BCF` (velocity), `+0x4BD0` (cápsula), `+0x2B0`, matriz `+0x1AB0` / `char[grp]+0x80`, ni `game_object[4]`. |
| **Proposed delta** | **+0.30 u** sobre X (un solo eje horizontal). Igual escala que MVP 2 (visible, muy por debajo de un paso, sin pelear con locomoción). |
| **Expected engine behavior** | Hipótesis: como `+0x2B0` se re-deriva de `+0x4B80` cada frame, y con `+0x4BC0` (velocity) ≈ 0 el integrador `0xF8190E` no debería sobrescribir `+0x4B80`, la escritura **persiste** ≥ varios frames y `object+0x2B0` (+ las ~14 copias observables) **converge** al nuevo valor en 1 frame. Resultados alternativos informativos: (a) revertida como `+0x2B0` ⇒ `+0x4B80` tampoco es canónico, hay algo más profundo; (b) clampeada por colisión ⇒ `+0x4B80` es canónico y la física actúa después. |
| **Guards** (todas obligatorias, además de las de MVP 2 §5) | proceso único `NINJA GAIDEN SI` / TracerPid 0; SHA256 EXE `a66daf…` + core `ca2849…`; slot Sigma2 `== core+0x16F2`; resolver LOCAL_PLAYER + `char[group]+0x00 == 0x00` + layout de personaje vivo; `LOCAL_PLAYER_STABLE` (10×/0.5 s, tol 0.05 u); **además**: `object+0x4BC0` (velocity) con `|componente| < 0.05` en las 10 muestras (jugador realmente quieto, no solo `+0x2B0` estable); `object+0x4B80 == object+0x2B0` a <1e-3 antes de escribir (coherencia de la cadena); `Y` de `+0x4B84` finita y estable ±0.05. Confirmación humana explícita inmediatamente antes. |
| **Rollback** | backup de los 4 bytes crudos de `object+0x4B80` + `object+0x2B0` (corroboración) en `docs/research/player/MVP2B_WRITE_TEST_<ts>.json` + `.bak`. Observación acotada ≤ 3 s @ 0.5 s de `+0x4B80`, `+0x2B0`, `+0x4BC0`, `Y`. Restauración automática: `pwrite` de los 4 bytes originales en `object+0x4B80`. Verificación: releer `+0x4B80` y `+0x2B0`. Ventana total ≤ 30 s; si no se restaura ⇒ `RESTORE FAILED`, avisar, pedir cierre normal (la posición no persiste entre misiones/arranques). Nunca una segunda escritura sin repasar todos los guards. |
| **Mecanismo** | `pwrite` de 4 bytes en `/proc/<pid>/mem` (O_RDWR), sin `ptrace`, sin suspender, sin hook, sin `VirtualProtect`, sin tocar `core.dll`. |
| **Execution authorized** | **NO.** |

### Qué NO incluye MVP 2B

No se escribe Y ni Z ni velocity ni cápsula ni rotación. No se toca `game_object[4]`
ni ninguna otra entrada. No teleport (delta grande), no input injection, no HP, no
networking, no hook nuevo, no cambios en `core.dll`/Proton/EXE. No se afirma nada
sobre persistencia entre misiones/arranques.

**Execution authorized: NO — PLAN ONLY.**

---

## EJECUTADO — 2026-09-07: MVP 2B resultado **PASS**

El experimento de §MVP 2B se ejecutó una vez, autorizado por el usuario
(`AUTORIZO MVP 2B: WRITE +0.30 X en object+0x4B80`). Herramienta:
`tools/player_write_test_2b.py` (dry-run + `--armed`). Detalle completo en
[MVP2B_WRITE_TEST_01.md](MVP2B_WRITE_TEST_01.md).

- Todos los gates PASS, incluidos los nuevos: `LOCAL_PLAYER_STABLE` (10×/0.5 s,
  ranges 0.0), **velocity `|object+0x4BC0|` máx 0.0 < 0.05**, **chain
  `object+0x4B80 == object+0x2B0` (dist 0)**.
- Un `pwrite` de 4 bytes en `object+0x4B80` (X `-110.711105` → `-110.411105`,
  bytes `166cddc2` → `7cd2dcc2`). Readback inmediato = valor escrito (diff = ULP).
- **La escritura se MANTUVO ~3.5 s** (6 muestras / 0.5 s): el motor **NO la
  revirtió**, a diferencia de `object+0x2B0` en MVP 2.
- **`object+0x2B0` (copia observable) CONVERGIÓ** al valor nuevo en ≤ 1 frame y se
  mantuvo. Propagación canónica confirmada. Velocity 0 en toda la ventana; Y/Z
  intactos; AI_PARTNER intacto.
- Restauración automática **EXACT** (`166cddc2`, readback `-110.71110535`);
  `char+0x310` corroboró. Proceso vivo, starttime estable, hook Sigma2 vivo.
- Usuario: `NO NOTE MOVIMIENTO PERO TODO NORMAL CON EL JUEGO` — el delta de 0.3 u
  es pequeño para la escala del mundo (~110); la ausencia de percepción visual
  **no** se debe a reversión (la evidencia en memoria muestra que el valor
  persistió y propagó).

**Verdict: PASS.** `object+0x4B80` es **escribible de forma persistente** y
**propaga a la posición observable** — el primitivo de teleport real que
`object+0x2B0` (MVP 2) no era.

No se repite el experimento. No se intenta otro delta / Z / Y / velocity /
rotación / AI_PARTNER. Sin networking.

### Repetición autorizada — 2026-09-08: delta +10.0 X (confirmación visual)

`tools/player_write_test_2b.py --delta 10.0`. Mismos gates PASS. `object+0x4B80` X
`-110.128990` → `-100.128990`; **se mantuvo** las 6 muestras (sin reversión, sin
clamp de colisión — 10 u exactos); `+0x2B0` convergió; restauración `EXACT`.
**Confirmación visual del usuario:** Ryu se desplazó ~10 u de forma
**prácticamente instantánea, sin animación de caminar/correr/saltar**, y volvió
igual de instantáneo tras el rollback; juego normal, sin crash. ⇒ escribir
`object+0x4B80` es un **teleport** (bypass del controlador de locomoción).
Detalle: [MVP2B_WRITE_TEST_01.md](MVP2B_WRITE_TEST_01.md).
