# Team Mission — clasificación de actores (Fase 8)

Estado: 2026-09-06, HEAD `e41c66b`. Continuación **solo lectura**. Sin escrituras de memoria, teleport, cambios de posición/rotación, input injection, HP, networking, hooks nuevos, ni cambios en `core.dll` / Proton / EXE / sysctl. Hitos previos intactos: MVP 0 PASS, hook Sigma2 151ea14, Player resolver + XYZ + rotación RUNTIME VERIFIED (ver [PLAYER_RESEARCH.md](PLAYER_RESEARCH.md)).

## 1. Metodología de estabilidad — `LOCAL_PLAYER_STABLE`

**`LOCAL_PLAYER_IDLE` ≠ `GAME_WORLD_IDLE`.** El personaje local puede moverse sin input del usuario (golpes, knockback, empujones, animaciones forzadas, enemigos, caídas, física). En Team Missions el compañero IA sigue actuando aunque el jugador local esté totalmente quieto: camina, corre, persigue, ataca, esquiva, gira, recibe golpes. Por tanto una captura IDLE válida **ya no exige** que todo el escenario esté inmóvil.

### `LOCAL_PLAYER_STABLE`

La posición XYZ del objeto del personaje controlado (`game_object` entrada 0 → `object + 0x2B0`) permanece dentro de una tolerancia pequeña durante `N` muestras consecutivas a intervalo fijo. Mientras tanto `AI_PARTNER`, `ENEMIES` y `OTHER_ACTORS` pueden seguir moviéndose — eso **no** invalida la captura.

Condición (todas):
- por eje horizontal (X y Z): `max - min` de la ventana ≤ `horizontal_tolerance`;
- eje vertical (Y): `max - min` ≤ `vertical_tolerance`;
- desplazamiento primera→última muestra ≤ `horizontal_tolerance` (horizontal) y `vertical_tolerance` (vertical).

### `UNSTABLE_LOCAL_PLAYER`

El objeto local cambia por encima de la tolerancia. La causa **no se atribuye automáticamente a input del usuario**: puede ser input, knockback, golpe, caída, animación forzada o desplazamiento físico. Requiere reintento o descartar la captura.

### Parámetros cuantitativos

| Parámetro | Valor | Justificación |
|---|---|---|
| `sample_count` | 10 | suficiente para filtrar jitter de 1 frame y ver deriva lenta |
| `sample_interval` | 0.5 s | ventana de 4.5 s; el compañero IA se mueve de forma continua, no hace falta más |
| `horizontal_tolerance` | 0.05 u | en reposo verificado el triple es **bit-idéntico** (rango 0.0) en 12+ muestras; la deriva mínima de un «idle no real» observada fue ~0.1 u/s. 0.05 ≈ 10× ULP float32 a magnitudes del área jugable y muy por debajo de locomoción/knockback |
| `vertical_tolerance` | 0.05 u | Y se mantuvo estable (~1e-6 de rango) incluso durante deriva horizontal; 0.05 da margen para micro-asentamiento de física sin aceptar una caída |

Unidad: 1 u del mundo del juego (escala física exacta no medida; ~metros por el orden de magnitud de las coordenadas).

Herramienta: `tools/actor_classifier.py` (solo lectura). Calcula `LOCAL_PLAYER_STABLE` para la entrada 0 y clasifica el resto.

## 2. Tabla de la `game_object` table (recordatorio)

- Root del resolver: `module_base + 0x3195300`, stride `0x30`, hasta 160 entradas.
- Por entrada: puntero al objeto en `+0` (también `+8`/`+0x10`), `obj_id` en `+0x18`, byte `group` en `+0x1F`, metadatos `+0x18..+0x20`.
- `object + 0x2B0` = posición world (X, Y, Z) — RUNTIME VERIFIED para la entrada 0. Para otras entradas es **candidato** hasta correlacionar movimiento.
- Rotación por **grupo**: `module_base + 0x2F78B10 + group*0x1240 + 0x80` (matriz 3×3, filas right/up/forward). Varias entradas pueden compartir `group`.
- Muchas entradas tienen `object + 0x2B0` = `(0,0,0)` — objetos no espaciales (managers/spawners/armas sin colocar) o cuyo layout no pone posición ahí. Se marcan aparte, no como enemigos.

## 3. Clasificaciones provisionales

`LOCAL_PLAYER` · `AI_PARTNER_CANDIDATE` · `ENEMY_CANDIDATE` · `OTHER_ACTOR_CANDIDATE` · `UNKNOWN`.

Heurística de `actor_classifier.py` (provisional, no intuición):
- entrada 0 → `LOCAL_PLAYER` (resolver ya RUNTIME VERIFIED);
- posición ≈ (0,0,0) → `OTHER_ACTOR_CANDIDATE` (no espacial);
- posición ≈ idéntica a la del jugador en todas las muestras → `OTHER_ACTOR_CANDIDATE` (sub-objeto co-localizado);
- se mueve por encima de tolerancia y dist. media al jugador < 25 u → `AI_PARTNER_CANDIDATE`;
- se mueve y está más lejos → `ENEMY_CANDIDATE`;
- estático y no en origen → `ENEMY_CANDIDATE` (enemigo en espera);
- resto → `UNKNOWN`.

Un `AI_PARTNER_CANDIDATE` sólido debería además: estructura/transform similar al Player, posición física plausible, cercanía razonable, movimiento continuo tipo personaje, XYZ distinto del local, persistencia en varias muestras, y **cambiar XYZ en coherencia con el movimiento visible del aliado** en capturas A/B/C. Sin esa correlación reproducible: máximo `STRONG CANDIDATE`, nunca `RUNTIME VERIFIED`.

## 4. Tabla de actores (se rellena con evidencia de Team Mission)

| Actor Role | Table Entry | Object Resolver | Position Offsets | Rotation | Group | Obj ID | Evidence | Status |
|---|---|---|---|---|---|---|---|---|
| LOCAL_PLAYER | `game_object[0]` | `module_base + 0x3195300` → entrada 0 → objeto | `object + 0x2B0/+0x2B4/+0x2B8` | `char[group]+0x80` matriz 3×3 | 0 | 0 | reinicio + 2ª misión; XYZ y yaw correlacionados con input | **RUNTIME VERIFIED** |
| AI_PARTNER | — | — | — | — | — | — | pendiente Team Mission | CANDIDATE (sin datos) |
| ENEMY | — | — | — | — | — | — | pendiente Team Mission | CANDIDATE (sin datos) |
| OTHER_ACTOR | varias entradas con pos (0,0,0) | idem | n/a | n/a | varios | varios | no espaciales (managers/spawners) | CANDIDATE |

## 4b. Capturas Team Mission — TEAM_ACTORS_A / B (PID 16942)

Team Mission con Ryu + compañero IA + enemigos. `LOCAL_PLAYER_STABLE = True` en A y B (entrada 0 `h_range 0.0`), con combate activo alrededor → el protocolo funciona con el mundo en movimiento.

Entre A y B: el usuario dejó a Ryu sin input; el compañero IA terminó sus combates y quedó quieto (respuesta «IA CAMBIO DE POSICION FINALIZO SUS COMBATES ESTA QUIETO IGUAL QUE RYU»).

| entry | obj_rva | grp | obj_id | A → B (Δ, |horiz|) | char+0x210 | char[grp]+0 | lectura |
|---|---|---|---|---|---|---|---|
| 0 | 0x3197100 | 0 | 0 | (59.63,5.22,-135.99) → (59.59,5.22,-136.01)  |0.05| | 0 | **0** | **LOCAL_PLAYER** (RUNTIME VERIFIED) |
| **4** | **0x319cdb0** | **1** | **219** | (65.71,5.22,-128.99) → (63.92,5.22,-134.16)  |5.47| | **0** (vivo) | 4 | **AI_PARTNER_CANDIDATE (STRONG)** |
| 1 | 0x3250700 | 0 | 1 | sin cambio (83.91,8.31,-130.79), estático, elevado, dist 25 | 0 | 0 | OTHER_ACTOR_CANDIDATE: placeholder de grupo-jugador; bloque de objeto casi todo ceros, sin transform vivo. NO es el compañero |
| 9 | 0x31a2a60 | 2 | 4 | movió |10.2|, ahora quieto cerca de Ryu | **4** (muerto) | 4 | ENEMY_CANDIDATE (derrotado) |
| 14 | 0x31bf9d0 | 7 | 4 | movió |8.2| | **4** | 4 | ENEMY_CANDIDATE (derrotado) |
| 18 | 0x31b9d20 | 6 | 4 | movió |9.4| | **4** | 4 | ENEMY_CANDIDATE (derrotado) |
| 11 | 0x31a8710 | 3 | 4 | casi estático, dist 46, Y≈9.5 (repisa) | 0 (vivo) | 4 | ENEMY_CANDIDATE (vivo, repisa) |
| 15,20,21 | — | — | 42/8/42 | A tenían posición elevada → B en (0,0,0) | — | — | enemigos **eliminados** (pasaron a no-espacial) |
| 22,23 | 0x329fbc0 / 0x329a120 | 14 / 13 | 41 / 23 | sin cambio, dist ~25, Y≈9 (repisa) | 0 | 4 | ENEMY_CANDIDATE (vivo, repisa) |
| 2,3,5,6,7,8,10,12,13,16,17,19,24 | — | varios | varios | pos (0,0,0) constante | — | — | OTHER_ACTOR_CANDIDATE (managers/spawners; `obj_id` cambió respecto a la misión en solitario → dependen de la misión) |

**Discriminadores observados:**
- `char[group]+0x00` byte: `0` para el grupo del jugador (grupo 0: entradas 0/1/7), `4` para todos los demás grupos. Separa **jugador-equipo vs no-jugador**, no compañero vs enemigo.
- `char[group]+0x210` (byte «dead» legacy, se compara con 4 en rutina de cadáveres): `4` en las entradas derrotadas (9/14/18), `0` en vivos. Es **por grupo**, se contamina si un grupo comparte entradas con un cadáver.
- **Estructura del bloque de objeto**: la entrada 4 tiene el MISMO layout que el jugador (quaternion en `obj+0x60`, datos en `obj+0x70/+0x80`, cabecera de enteros cortos en `obj+0x90`); los enemigos `id 4` tienen cabecera distinta (`9898` en `char+0x04`, `0202` en `char+0x10`) y layout de objeto más pobre. → la entrada 4 es **estructuralmente un personaje jugable**, no un enemigo.
- `obj_id`: jugador `0`; compañero candidato `219` (único en la misión); enemigos `4/41/23/...`.
- `group`: jugador `0`; compañero candidato `1` en esta misión.

## 4c. TEAM_ACTORS_C — el jugador se desplaza, ¿quién le sigue?

En C el usuario **movió a Ryu** ~43 u: B (59.6, 5.22, -136.0) → C (99.4, 5.22, -120.2), y respondió «IA MOVIMIENTO 2 me siguió y atacó a un enemigo». Comparación **por dirección de objeto** (`obj_rva`, estable en esta sesión; el índice de tabla NO):

| obj_rva | id | A pos | B pos | C pos | B→C | dist a Ryu (C) | lectura |
|---|---|---|---|---|---|---|---|
| **0x319cdb0** | **219** | (65.7,5.2,-129) | (63.9,5.2,-134) | **(89.4,6.3,-122)** | **28 u** | 10.3 | **AI_PARTNER** — presente en A/B/C, **siguió el desplazamiento deliberado de Ryu** hacia la zona nueva, vivo |
| 0x326cc20 | 41 | — | — | (88.6,5.8,-122) | (nuevo) | 11.0 | enemigo que la IA ataca en la zona nueva (co-localizado con la IA); `char+0x210 = 4` |
| 0x31a8710 | 4 | (101,9.5,-116) | (101,9.5,-116) | (98.6,9.4,-115) | 2.7 u | 7.7 | enemigo estático en repisa (Y≈9.4); Ryu se acercó |
| 0x31b9d20 | 4 | (69.5,5.2,-129) | (60.9,5.2,-133) | (60.9,5.2,-133) | **0 u** | 40.5 | cadáver dejado en la zona anterior (`char+0x210 = 4`, quat objeto = 0,0,0,0) |
| 0x31bf9d0 | 4 | (65.2,5.2,-129) | (59.3,5.6,-135) | (59.3,5.6,-135) | **0 u** | 42.7 | cadáver dejado atrás |
| 0x31a2a60 | 4 | (61.4,5.2,-125) | (64.8,5.2,-135) | — | (slot reciclado) | — | enemigo eliminado; su slot pasó a 0x326cc20 |
| 0x3250700 | 1 | (83.9,8.3,-131) | idéntico | idéntico | 0 u | 19.0 | marcador fijo del grupo-jugador (bloque de objeto vacío) — NO actor |
| 0x329a120 / 0x329fbc0 | 23 / 41 | idénticos A/B/C, Y≈9, dist ~21–24 | — | — | 0 u | ~22 | enemigos en repisa, nunca enganchados |

**Discriminador estructural clave — «live playable-character layout»:** solo la entrada del jugador y la del compañero IA tienen `obj+0x60` = quaternion unitario (|q|≈1) **y** `obj+0x90` = cabecera de enteros cortos poblada. Los enemigos «logic entry» tienen ese bloque **todo a ceros**; los cadáveres tienen el quaternion **a ceros (|q|=0)**. `tools/actor_classifier.py` lo comprueba (`live` = Y/n) y en TEAM_ACTORS_C marca exactamente **2** actores `live` = jugador (entrada 0) + compañero (obj 0x319cdb0).

**AVISO de metodología:** dentro de una misma misión, `entry index` y `group` **se reciclan** (p. ej. el índice 9 pasó de `obj 0x31a2a60 / id 4 / grp 2` a `obj 0x326cc20 / id 41 / grp 5`; `char[group]+0x210` se contamina cuando un grupo comparte slot con un cadáver o un manager). Un resolver del compañero **no puede** ser «entrada N»: debe ser por propiedad (objeto con layout de personaje vivo, `group ≠ group_jugador`, vivo, cercano).

## 4d. Discriminadores LOCAL_PLAYER vs AI_PARTNER

| Señal | LOCAL_PLAYER | AI_PARTNER (esta misión) | Enemigos |
|---|---|---|---|
| `game_object` index | 0 (siempre primera) | ≠ 0 | ≠ 0 |
| `group` (byte +0x1F) | 0 | 1 | 2,3,5,6,7,13,14,... |
| `char[group]+0x00` | **0x00** | 0x04 | 0x04 |
| `char[group]+0x04..0x06` | `0000` | `0909` | `9898` / `c2c2` / `ffff` |
| `obj+0x60` quaternion | unitario | **unitario** | ceros (logic) o 0,0,0,0 (muerto) |
| `obj+0x90` header | poblado | **poblado** | ceros |
| `obj_id` | 0 | 219 (`CHARACTER_ID_CANDIDATE`) | 4 / 41 / 23 |
| `char[group]+0x210` (dead) | 0 | 0 | 4 si derrotado |
| movimiento | sigue el input del usuario | autónomo; **sigue al jugador** | autónomo / independiente |

Discriminador local-vs-IA más limpio: **`game_object` index 0 + `group == group_jugador` + `char[group]+0x00 == 0x00`** ⟹ LOCAL_PLAYER. Un objeto con layout de personaje vivo pero `group != group_jugador` y `char[group]+0x00 == 0x04` ⟹ AI_PARTNER. Un `control flags` / `input owner` explícito **no** se ha aislado todavía; los candidatos anteriores son la mejor discriminación reproducible por ahora.

`CHARACTER_ID_CANDIDATE`: `game_object[entry].obj_id` — jugador `0`, este compañero IA `219`. Sin reproducir con otro personaje; podría ser id de tipo/modelo, no necesariamente «Ryu/Ayane/...».

## 4e. Tabla de actores (rellenada)

| Actor Role | Table Entry | Object Resolver | Position Offsets | Rotation | Group | Obj ID | Evidence | Status |
|---|---|---|---|---|---|---|---|---|
| LOCAL_PLAYER | `game_object[0]` (índice fijo) | `module_base + 0x3195300` → entrada 0 → objeto | `object + 0x2B0/+0x2B4/+0x2B8` | `char[group]+0x80` matriz 3×3 | 0 | 0 | reinicio + 2ª misión; XYZ/yaw correlacionados con input; `char[0]+0x00 = 0x00` | **RUNTIME VERIFIED** |
| AI_PARTNER | por propiedad (NO índice fijo): objeto con layout de personaje vivo, `group ≠ 0`, `char[grp]+0x210 ≠ 4`, cercano al jugador | mismo esquema que LOCAL_PLAYER con ese objeto | `object + 0x2B0/+0x2B4/+0x2B8` | `char[group]+0x80` | 1 (esta misión, **no estable**) | 219 (esta misión) | presente en A/B/C; siguió el desplazamiento deliberado de Ryu (28 u) hacia la zona nueva; layout de objeto = el del jugador; vivo | **STRONG CANDIDATE** |
| ENEMY (vivo) | varias | mismo esquema | `object + 0x2B0` (a veces vía la entrada «logic»; el objeto puede tener transform a ceros) | `char[group]+0x80` por grupo | ≠ 0 | 4 / 41 / 23 | movimiento autónomo independiente; layout de objeto a ceros; `char[grp]+0x04 = 9898/...` | CANDIDATE |
| ENEMY (derrotado) | varias | idem | idem (posición congelada) | idem | ≠ 0 | 4 | `char[group]+0x210 = 4`; `obj+0x60` quaternion = (0,0,0,0); posición congelada tras morir | CANDIDATE |
| OTHER_ACTOR | muchas con pos (0,0,0); `game_object[?]` id 1 grp 0 estático | idem | n/a | n/a | varios | varios | managers/spawners; `obj_id` depende de la misión; marcador fijo del grupo-jugador con bloque de objeto vacío | CANDIDATE |

## 4f. Segunda Team Mission — TEAM_ACTORS_D (compañero = Ayane)

Otra Team Mission distinta, mismo proceso PID 16942 (sin reiniciar el juego). Región de mapa muy distinta (Y ≈ −0.95, negativo). `LOCAL_PLAYER_STABLE = True` con combate activo.

| | mission C (compañero de Ryu) | mission D (Ayane) |
|---|---|---|
| LOCAL_PLAYER | `game_object[0]`, obj `0x3197100`, id 0, grp 0, `char[0]+0x00 = 0x00`, `char[0][4:6] = 0000` | **idéntico** |
| AI_PARTNER | `game_object[4]`, obj **`0x319cdb0`**, id **219**, grp 1, `char[1]+0x00 = 0x04`, `char[1][4:6] = 0909`, vivo, layout de personaje vivo | `game_object[4]`, obj **`0x319cdb0`** (misma RVA), id **220**, grp 1, `char[1]+0x00 = 0x04`, `char[1][4:6] = 0000`, vivo, layout de personaje vivo, dist ~4–8 de Ryu, movimiento autónomo |
| enemigos | `char[grp][4:6] = 9898 / c2c2 / ffff`; layout de objeto a ceros | igual (`9898` en el enemigo `id 8` que dio falso positivo de «live» al atacar; excluido por `char[grp][4:6]`) |

**Confirmado en 2 misiones:**
- `game_object[0]` = LOCAL_PLAYER; `game_object[4]` / objeto en **RVA `0x319cdb0`** = AI_PARTNER. Los índices 0 y 4 fueron estables entre misiones (los índices altos SÍ se reciclan). Falta un **reinicio del juego** para confirmar que el índice 4 no depende del roster.
- Discriminador enemigo vs personaje jugable: `char[group][4:6] ∈ {9898, c2c2, ffff}` ⇒ enemigo; `char[group][4:6] ∉` ese conjunto **y** layout de objeto vivo **y** `group ≠ 0` ⇒ AI_PARTNER; `group == 0` **y** `char[0][0] == 0x00` ⇒ LOCAL_PLAYER.
- `obj_id`: jugador `0`; compañero `219` (mission C) → `220` (mission D, Ayane). **Incrementa entre misiones ⇒ es un contador de spawn/alloc, NO una id de personaje.** `CHARACTER_ID_CANDIDATE` vía `obj_id`: **REJECTED**. La id real del personaje (Ryu/Ayane/Momiji/Rachel) sigue sin localizarse.
- XYZ resolver robusto en rangos de coordenadas muy distintos (Y ≈ 5.2 / 1.2 / −0.95 en tres misiones).

`tools/actor_classifier.py` con la heurística endurecida marca en mission D exactamente **1** AI_PARTNER (entry 4 / obj `0x319cdb0` / Ayane) y **0** falsos positivos.

## 4g. Tabla de actores (final de Fase 8)

| Actor Role | Table Entry | Object Resolver | Position Offsets | Rotation | Group | Obj ID | Evidence | Status |
|---|---|---|---|---|---|---|---|---|
| LOCAL_PLAYER | `game_object[0]` | `module_base + 0x3195300` → entrada 0 → objeto | `object + 0x2B0/+0x2B4/+0x2B8` (X/Y/Z) | `char[group]+0x80` matriz 3×3 | 0 | 0 | reinicio + 3 misiones; XYZ/yaw ↔ input; `char[0]+0x00 = 0x00`, `char[0][4:6] = 0000` | **RUNTIME VERIFIED** |
| AI_PARTNER | `game_object[4]` **o** por propiedad: objeto con layout de personaje vivo + `group ≠ 0` + `char[grp][4:6] ∉ {9898,c2c2,ffff}` + `char[grp]+0x210 ≠ 4` + `char[grp]+0x00 = 0x04` | mismo esquema con ese objeto (RVA `0x319cdb0` de ejemplo en esta sesión) | `object + 0x2B0/+0x2B4/+0x2B8` | `char[group]+0x80` | 1 (3 Team Missions + reinicio; base determinista) | 219 / 220 (contador de spawn, NO id de personaje) | **3 Team Missions + reinicio completo**; siguió el desplazamiento deliberado de Ryu (28 u mission C; convergió sobre la posición nueva de Ryu tras reinicio, dist 2.55 u); layout de objeto = el del jugador; vivo; `char[grp][4:6] ∉` firma enemiga; 2 correlaciones de movimiento post-reinicio | **RUNTIME VERIFIED** (rol; ver caveats §4h) |
| ENEMY | por propiedad | mismo esquema | `object + 0x2B0` (transform del objeto puede estar a ceros; el bloque «logic» no lleva pose) | `char[group]+0x80` por grupo | ≠ 0 | 4 / 41 / 23 / 8 / 42 | movimiento autónomo independiente; `char[grp][4:6] ∈ {9898,c2c2,ffff}`; layout de objeto a ceros | CANDIDATE |
| ENEMY (derrotado) | por propiedad | idem, posición congelada | idem | idem | ≠ 0 | 4 | `char[group]+0x210 = 4`; `obj+0x60` quaternion = (0,0,0,0) | CANDIDATE |
| OTHER_ACTOR | muchas entradas | idem | pos (0,0,0) / estática | n/a | varios | dependen de la misión | managers/spawners; marcador fijo del grupo-jugador (`id 1`, bloque de objeto vacío) | CANDIDATE |

## 5. Pendiente

- **Reinicio del juego** para confirmar que `game_object[4]` = AI_PARTNER no depende del roster / no es coincidencia de «slot aún no reciclado» en esta sesión. Solo entonces AI_PARTNER podría pasar a `RUNTIME VERIFIED`.
- Segunda correlación de seguimiento con el compañero (mission D solo tuvo una captura con Ryu quieto).
- Localizar la **id real de personaje** (Ryu/Ayane/Momiji/Rachel): `obj_id` está descartado (contador de spawn, 219→220). Buscar en `char[group]` un campo que difiera entre el compañero de Ryu (mission C) y Ayane (mission D) y que no sea posición/rotación/estado.
- `input owner` / `control flag` explícito: no aislado. Mejor discriminación reproducible por ahora: `game_object[0]` + `char[0][0]==0x00` (local) vs layout de objeto vivo + `group≠0` + `char[grp][4:6]∉{9898,c2c2,ffff}` (IA).

Sin direcciones absolutas como offsets permanentes: siempre RVA module-relative + índice de tabla + offset de struct + pointer chain; las direcciones concretas (`0x319cdb0`, etc.) son sólo ejemplos de sesión.

## 6. Condición para MVP 2

| Requisito | Estado |
|---|---|
| LOCAL_PLAYER resolver RUNTIME VERIFIED | ✅ (Fase 6/7) |
| Posición XYZ RUNTIME VERIFIED | ✅ (Fase 7; X/Y/Z, right-handed Y-up) |
| Rotación RUNTIME VERIFIED | ✅ (Fase 7; yaw; pitch/roll sin ejercitar) |
| `LOCAL_PLAYER_STABLE` protocol | ✅ (Fase 8; 10 muestras / 0.5 s / 0.05 u) |
| AI_PARTNER identificado o strong candidate | ✅ STRONG CANDIDATE (`game_object[4]` / layout vivo; 2 Team Missions) |
| Evidencia de diferencia local vs IA | ✅ (índice 0 + `char[0][0]==0x00` vs layout vivo + `group≠0` + `char[grp][4:6]∉` firma enemiga) |
| Otra misión/contexto probado | ✅ (2 misiones en solitario + 2 Team Missions) |

**READY FOR CONTROLLED WRITE TEST: NO.** Falta: reinicio que confirme el slot del compañero, pitch/roll de la matriz, e id real de personaje. La escritura de memoria NO se realiza en esta fase.

## 4h. FASE 9 — Actor restart validation (arranque completo nuevo)

Juego cerrado normalmente (PID 16942 ausente, `actor_restart_shutdown.json`) y **relanzado**. Nueva sesión: **PID 29318**, "Misión Acólito 01", compañero IA = **Ayane**. Solo lectura. Gates desde cero: SHA256 EXE `a66daf…` OK, SHA256 core `ca2849…` OK, slot Sigma2 → `core+0x16F2` (hook 151ea14 **vivo tras reinicio**). Base de módulo `0x140000000` (delta ASLR 0 — **determinista bajo este Proton**).

### LOCAL_PLAYER — RUNTIME VERIFIED (re-resuelto desde cero)
`game_object[0]` → objeto RVA `0x3197100`, group 0, obj_id 0. Identificación **estructural**, no «es la entrada 0»: es la **única** entrada `game_object` con layout de personaje vivo **y** `char[group]+0x00 == 0x00`. Posición (88.22, 8.00, −130.37) (región de mapa nueva). Rotación `char[0]+0x80` matriz válida (det +1). `LOCAL_PLAYER_STABLE = True` con combate activo.

### AI_PARTNER — RUNTIME VERIFIED (rol)
`game_object[4]` → objeto RVA `0x319cdb0`, group 1, obj_id 220. `live_char_layout = True`, `char+0x210 = 0` (vivo), `char[grp][4:6]` = `0909`/`2828` (∉ firma enemiga en las 3 capturas). Clasificador: 1 solo AI_PARTNER, 0 falsos positivos.

| | ACTOR_RESTART_AI_A | _B | _C |
|---|---|---|---|
| LOCAL_PLAYER pos | (88.22, 8.0, −130.37) | (88.05, 8.0, −130.78) | (97.23, 5.22, −117.03) |
| LOCAL_PLAYER_STABLE | True | **False** (deriva 0.067) | True (reubicado) |
| AI candidate pos | (88.07, 6.29, −122.36) | (97.96, 8.0, −126.73) | (99.77, 5.22, −116.78) |
| AI move (xz) | — | **10.8 u** | **10.1 u** |
| AI dist a Ryu | 8.2 | 14.3 | **3.9** (converge sobre la posición nueva de Ryu, dist 2.55) |

**Correlación B**: la IA se movió ~10.8 u mientras el jugador local se movió ~0.4 u. **Correlación C**: la IA se movió ~10.1 u y **convergió sobre la nueva posición del jugador** (comportamiento de seguimiento). Criterios §8 del plan de Fase 9: los 11 se cumplen (nuevo PID, resolución desde cero, dirección re-obtenida, estructura de personaje, discriminador no-enemigo, transform válido, movimiento autónomo, correlación B, correlación C, LOCAL_PLAYER distinguible, consistente con las 2 Team Missions previas).

**Caveats (documentados, no invalidan):**
1. Base de módulo determinista (delta ASLR 0 en ambas sesiones) ⇒ la identidad de RVA se espera; **no se probó resiliencia a aleatorización de direcciones**. Lo demostrado es la re-resolución del **rol** + los discriminadores estructurales a través de un reinicio real.
2. LOCAL_PLAYER no estuvo perfectamente inmóvil en B (0.067 u) y se reubicó ~16.8 u en B→C; la señal de la IA (10–11 u por paso + convergencia sobre el jugador) domina el ruido local.

`AI_PARTNER = RUNTIME VERIFIED` para «existe un actor de compañero IA resoluble, estructuralmente distinto de enemigos y del jugador local, que sigue al aliado». El resolver es `game_object[4]` **o** la búsqueda por propiedad (ambos funcionaron). `game_object[4]` sostuvo el compañero en **3 Team Missions + un reinicio**; un roster/modo distinto podría diferir (sin probar).

### CONTROL_DISCRIMINATOR_CANDIDATE

Diff estructural LOCAL (Ryu, grp 0) vs AI (Ayane, grp 1):

| Señal | LOCAL | AI_PARTNER | ENEMIES |
|---|---|---|---|
| `char[group] + 0x00` | **0x00** | 0x04 | 0x04 |
| `game_object` rec + 0x1D | 0x00 | 0x04 | — |
| `object + 0x98` (byte) | 0x02 | 0x04 | — |

`char[group]+0x00 == 0x00` ⟺ el jugador controlado por input local (`0x04` = compañero IA o enemigo). Reproducido en 3 Team Missions + 2 en solitario + reinicio. Sin prueba semántica de que sea literalmente un «input owner flag» vs un marcador de team-0. → **CONTROL_DISCRIMINATOR_CANDIDATE**.

### CHARACTER_ID_CANDIDATE (baja confianza)

`obj_id` sigue **REJECTED** (contador de spawn). Campos que varían entre Ryu y Ayane: `char[group]+0x16` byte (Ryu `0x4e`, Ayane `0xb6`); `char[group]+0x1e8/+0x1ec` ≈ 4530/4565 (Ryu) vs ≈ 4271/4342 (Ayane) — plausiblemente HP máx por personaje; `obj+0x9f/+0xa3` byte `0x09` (Ryu) vs `0x0a` (Ayane). Solo 2 puntos de datos; ningún puntero a definición de personaje en `char[group]` primeros 0x400. `CHARACTER_ID_CANDIDATE = char[group]+0x16`, **baja confianza**. No se bloquea el proyecto por esto.

### PITCH / ROLL

`char[group]+0x80` row1 (up) ≈ (0, 1, ~0) en todas las capturas; ninguna situación de salto/caída/rampa medida limpiamente. **PITCH/ROLL = NOT VERIFIED.** El yaw / la matriz siguen RUNTIME VERIFIED.

Evidencia: `docs/research/player/{actor_restart_shutdown.json, ACTOR_RESTART_LOCAL.json, ACTOR_RESTART_AI_A/B/C.json, actor_restart_validation.json}`.

### Decisión MVP 2

Checklist de §14 cumplido (LOCAL_PLAYER + XYZ RUNTIME VERIFIED, resolver reproducible, `LOCAL_PLAYER_STABLE`, dirección dinámica, gates, backup/rollback diseñado en [MVP2_WRITE_PLAN.md](MVP2_WRITE_PLAN.md), discriminación local-vs-IA). **READY FOR MVP 2 CONTROLLED POSITION WRITE: YES**, con `pitch/roll = NOT VERIFIED` y `character ID = CANDIDATE` (§14 dice que no son obligatorios). El experimento está **solo diseñado**, no ejecutado.

## 4i. FASE 11 — AI_PARTNER en la arquitectura de transform (PID 14042, 2026-09-07)

Detalle en [TRANSFORM_SYNC_RESEARCH.md](TRANSFORM_SYNC_RESEARCH.md). Team Mission Ryu + Momiji; solo lectura.

- `game_object[4]` (obj RVA `0x319cdb0`, grp 1, **obj_id 221** — sigue siendo contador de spawn: 219→220→221 en 4 misiones) = AI_PARTNER, confirmado por posición y seguimiento del jugador (Momiji se movió 8.47 u en lockstep mientras Ryu se movía 14.55 u).
- **Arquitectura de posición idéntica al LOCAL_PLAYER**: `object+0x4B80` (posición fuente / `CANONICAL_POSITION_STRONG_CANDIDATE`), `object+0x4BC0` (velocity — `(0,0,0)` en reposo, `(-0.01,0,2.006)` caminando), `object+0x4BD0` (centro de cápsula). Mismos discriminadores `char[grp]+0x00 == 0x04`.
- Implicación co-op: la fuente de posición del compañero es `game_object[4] → object + 0x4B80`, con el mismo bloque de movimiento que Ryu → un futuro replicador de posición puede tratar LOCAL y PARTNER con el mismo esquema.
- El `--roles` de `actor_classifier.py` marcó Momiji como `ENEMY_CANDIDATE` en esta sesión (heurística de cabecera enemiga stale para Momiji); no afecta a la identificación por posición/seguimiento/`game_object[4]`.


## FASE 13 — cadena de control de locomoción (2026-09-08, PID 14042)

Detalle: **[LOCOMOTION_CONTROLLER_RESEARCH.md](LOCOMOTION_CONTROLLER_RESEARCH.md)**. Solo lectura/observación (probe + write-watchpoints + `detach`). Proceso vivo tras la sesión, hook Sigma2 re-verificado.

- **`character[group] + 0x30` (float4)** = **comando de dirección de movimiento (suavizado)**: `(0,0,0,0)` en reposo, específico de dirección al moverse, **idéntico para LOCAL_PLAYER y AI_PARTNER** (Momiji: no-cero solo cuando siguió a Ryu). Es lo que `0x14249A0` consume para construir el delta de W1 (`object+0x4B80 +=`). ⇒ **`REMOTE_CONTROL_INJECTION_CANDIDATE` (STRONG CANDIDATE)** — punto de convergencia input-local / cerebro-IA.
- **`character[group] + 0x04` (byte)** = **state code de locomoción / selector de animación**: `0x00` idle, `0x06` start, `0x0A` lateral, `0x26/0x28/0x2A` walk/run, `0x48` run de IA. Enum compartido; es el selector de la jump table de `0x14249A0`. Un teleport puro (solo `+0x4B80`) deja `char+0x04 = 0` → sin animación (lo observado en MVP 2B +10.0).
- **`character[group] + 0x24`** = parámetro de locomoción del estado (tabla de animación, escrito por `0xF1ECA0`), **no** magnitud de stick.
- **`object + 0x4BC0` (velocity)** = **resultado DERIVADO** (velocity real suavizada, ease-in ~0.5 s, publicada para animación/cámara) — **no** la entrada de la integración de locomoción.
- **Writer de `char+0x30`**: pc `0xF25054` (`movdqu [char+0x30], xmm3`) en fn `0xF24F4A`, hilo "Updating" — un **filtro EMA**: `char+0x30 = char+0x30_old*decay + input_sample*weight` (la `w` hace ease-in `0.25→1.0` al acelerar). La muestra viene de una tabla/ring indexada por un contador de frame global (`[rip+0x20815D8]` base — RVA exacta sin confirmar).
- Siguiente experimento (**solo diseño, NO ejecutado, NO autorizado**): escribir una dirección unitaria en `char+0x30` durante ~N frames (el EMA exige varios) en `LOCAL_PLAYER_STABLE` → Ryu debería **caminar con animación** (sin teleport, delta acotado por el speed-clamp `0x1469F60()`).


## FASE 13c — fuente de `object+0x5000` (2026-09-08)

Detalle: **[REMOTE_CONTROL_INJECTION_RESEARCH.md](REMOTE_CONTROL_INJECTION_RESEARCH.md)**. Solo observación (write-watchpoints + `detach`).

- **Writer de `object+0x5000` = `0xFF2E0B` en `0xFF282A`** (bucle per-actor sobre `game_object` table, `lea rcx,[r14+0x3195326]`), hilo "Updating". **Idéntico para LOCAL_PLAYER y AI_PARTNER** (46 hits cada uno; solo cambia `rsi` = obj del actor). Call stack byte-idéntica.
- `object+0x5000 = *(float4*)(object + 0x5C06 + off_tabla)` — `0xFF282A` copia desde el **área de comando crudo per-actor `object + ~0x5C06`** a `object + 0x5000`. La divergencia **input local (Ryu) vs cerebro de IA (Momiji)** está aguas arriba, en quién rellena `object + ~0x5C00` — **NO capturado**.
- Representación: float4, `(0,0,0,0)` en reposo (campo no escrito), `(dir_x, ~0, dir_z, w=1)` al moverse; **mismo formato ambos actores**.
- `REMOTE_CONTROL_INJECTION` = **STRONG CANDIDATE**: nivel de inyección preferido = `object + ~0x5C00` (comando crudo) o re-escritura per-frame de `object+0x5000`; `char+0x30` directo lo amortigua el EMA. Player 2 remoto sobre Ryu no requiere tocar la IA; sobre Momiji sí (neutralizar el cerebro que escribe su `object + ~0x5C00`). Experimento de movimiento natural: solo diseñado, NO ejecutado, NO autorizado.


## FASE 14 — fuente cruda del comando de movimiento por actor (2026-09-08)

Detalle: **[RAW_MOVEMENT_COMMAND_RESEARCH.md](RAW_MOVEMENT_COMMAND_RESEARCH.md)**. Solo observación (hardware watchpoints + `detach`).

- **El "área de comando crudo per-actor" queda pinneada a `object + 0x4B90`** (float4; bloque de estado de movimiento: `+0x4B80` posición · **`+0x4B90` comando crudo** · `+0x4BA0` facing · `+0x4BC0` velocity · `+0x4BD0` cápsula). `0xFF282A` copia `object+0x4B90 → object+0x5000` con offset **exacto** `0x5C06 - 0x1076` (`rdi = 1` para Ryu **y** Momiji). `object+0x5000` va **1 frame por detrás**. `(0,0,0,0)` en reposo ambos actores.
- **Writer de `object+0x4B90` (LOCAL_PLAYER, capturado):** `0x14210A0` (`movdqu [rax+0x4B90], xmm4`, `rax` = object) en el **bucle per-actor `0x1420F60`–`0x14215C3`**, hilo "Updating" — 50 hits, todos Ryu. Caller `0x142C499` en `0x142C460` (`for edx = 0 .. 0xA0 { call 0x1420F60(edx) }`). Lógica: si `byte[object+0x5B56] == 0` ⇒ `object+0x4B90 = (0,0,0,0)`; si no ⇒ `[module_base+0x63F16B0] = 0` (`0x142101B`), `call 0x14203E0` (`0x1421032`), `object+0x4B90 = [0x63F16B0] + character[group][0xFA0]`.
- `[module_base + 0x63F16B0]` = **scratch global float4** del comando; lo rellena `0x14203E0` por actor. Watchpoint: 46 hits/idle, 2 writers alternando — `0x142101B` (zero) y `0x142082B` (dentro del árbol de `0x14203E0`, fn `0x142015B`–`0x142099E`).
- `character[group] + 0xFA0` = término aditivo per-actor; **`(0,0,0,0)` para Ryu y Momiji** — watchpoint WRITE: **0 hits** durante movimiento (sin uso en este escenario; posible aim-assist / nudge).
- **`0x14203E0` = RAW_COMMAND_PRODUCER.** Head: manager de input `[rip+0x4FD12B0]` (bytes `+0x12`/`+0x13`/`+0xF8A`/`+0xF85`, `0xFF` = sin asignar; gate `+0xC` → si `!= 0` fuerza `bl = 0xFF` = **`CONTROL_MODE_CANDIDATE`**); managers `[rip+0x4FD1215]` (`word +0x1FA` state) y `[rip+0x4FD11DF]` (gate object `+0x5B6D`); jump-table interna. **La rama exacta input-device (Ryu) vs AI-brain (Momiji) DENTRO de `0x14203E0` NO se aisló.**
- **AI_PARTNER:** `0x1420F60` corre en el **mismo bucle** `for edx = 0 .. 0xA0` para **todos** los actores ⇒ el writer de `object+0x4B90` de Momiji es el mismo `0x14210A0` / `0x1420F60` / `0x14203E0`. El watchpoint combinado no disparó en la dirección de Momiji (Ryu, edx 0, llenó el `MAX=50` antes que edx 4). **Falta captura Momiji-only en runtime.**
- **Divergencia** = dentro de `0x14203E0` (sin aislar). **Convergencia** = `object + 0x4B90` (writer compartido `0x14210A0`). De ahí abajo (`0xFF282A` → `object+0x5000` → EMA `0xF24F4A` → `char+0x30` → `0x14249A0` → W1 `0x141BB90`) = código compartido RUNTIME VERIFIED (Fases 12/13).
- Representación del raw command: **float4**, `(0,0,0,0)` idle, `(dx, ~0, dz, w=1)` activo (`w` = comando activo); mismo layout `object+0x4B90` == `object+0x5000`; 1×/actor/frame; per-frame (no persiste solo).
- **`REMOTE_PLAYER_CONTROL_POINT` (candidato): `object + 0x4B90`** reescrito cada frame **después** de `0x1420F60`, o hook de `0x14203E0` / del escritor `0x1420833` de `[0x63F16B0]`. Downstream 100 % compartido y verificado, produce locomoción + animación naturales, delta acotado por el speed-clamp (sin teleport). `char+0x30` directo lo amortigua el EMA. Player 2 remoto sobre Ryu = bloquear el poll de input (hook de `0x14203E0` o el `CONTROL_MODE_CANDIDATE`); sobre Momiji = neutralizar la rama de IA dentro de `0x14203E0`.
- `REMOTE_CONTROL_INJECTION` = **STRONG CANDIDATE**. Falta: writer de `object+0x4B90` de Momiji en runtime; aislar la rama input↔IA de `0x14203E0`; confirmar `CONTROL_MODE_CANDIDATE` (`[rip+0x4FD12B0]+0xC`). Experimento de movimiento natural: solo diseñado, NO ejecutado, NO autorizado.
- Evidencia: `docs/research/locomotion/watch_ryu_obj4B90_moving.txt` (50 hits del writer `0x14210A0`), `watch_gcmd_63F16B0.txt` (writers de `[0x63F16B0]`), `watch_charFA0_none.txt` (0 hits), `wp_4b90.gdb`, `wp_g5b0.gdb`.


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
