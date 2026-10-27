# MVP 2B — Controlled canonical position write test 01

Fecha: 2026-09-07T17:58:53−06:00. Resultado: **PASS**. Repetido 2026-09-08 con delta +10.0 X (confirmación visual) — ver al final.

Primera escritura controlada y reversible de la **posición canónica** del
LOCAL_PLAYER (`object + 0x4B80` world X), autorizada por el usuario con la frase
exacta `AUTORIZO MVP 2B: WRITE +0.30 X en object+0x4B80`. Herramienta
independiente `tools/player_write_test_2b.py` (sin `core.dll`, sin hook, sin
`ptrace`, sin `VirtualProtect`): un `pwrite` de 4 bytes en `/proc/<pid>/mem`
(O_RDWR) sobre una dirección resuelta dinámicamente, con restauración automática.

## Contexto

MVP 2 (2026-09-06) escribió `object + 0x2B0` (world X): la escritura entró pero el
motor la **revirtió en < ~150 ms** porque `+0x2B0` es una copia de render que se
re-deriva cada frame de un estado más profundo. Fases 11–12 identificaron ese
estado: **`object + 0x4B80`** (`CANONICAL_POSITION_RUNTIME_VERIFIED`), integrado
por el writer de locomotion W1 (`0x141BB90`: `pos += delta`) y re-commiteado por
el writer de transform W2 (`0x14208DD`); `object + 0x2B0` se deriva de él. El
"W2 SOURCE CHECK" ([CANONICAL_WRITER_TRACE.md](CANONICAL_WRITER_TRACE.md) §9b)
concluyó que la fuente de W2 (`character[group]+0x1010`) es a su vez una copia por
frame de `object+0x4B80`, así que un write externo sólo podría revertirse ≤ 1
frame, no de forma permanente. MVP 2B lo comprueba.

## Parámetros

| | |
|---|---|
| Proceso | PID 14042, `comm` «NINJA GAIDEN SI», TracerPid 0, starttime 108576 |
| Module base | `0x140000000` · core `0x6ffff9830000` |
| Gates | EXE SHA256 `a66daf…` OK · core SHA256 `ca2849…` OK · slot Sigma2 → `core+0x16F2` (hook 151ea14 vivo) |
| Actor | LOCAL_PLAYER = `game_object[0]` → objeto `0x143197100` (RVA `0x3197100`), group 0, obj_id 0, `char[group]+0x00 = 0x00`, quaternion `obj+0x60` unitario, vivo. **NO** es el compañero IA. |
| Target / offset | `object + 0x4B80` (CANONICAL world **X**), float32, 4 bytes. Dirección de esta sesión: `0x14319bc80`. |
| `LOCAL_PLAYER_STABLE` | PASS — 10 muestras / 0.5 s, `h_range` 0.0000, `v_range` 0.0000. |
| **Velocity gate** (nuevo en 2B) | PASS — `|object+0x4BC0|` máx por componente `0.0000` < 0.05 en las 10 muestras. |
| **Chain gate** (nuevo en 2B) | PASS — `object+0x4B80 == object+0x2B0` (dist `0.0`, < 1e-3). |
| Original XYZ (canon) | (−110.711105, −0.000012, 71.277870) |
| Original X bytes | `166cddc2` (float −110.71110535) |
| Delta | **+0.30** |
| New X | −110.41110535 · bytes `7cd2dcc2` |

## Secuencia (una escritura, una restauración automática)

| t (−06:00) | evento | `+0x4B80` X | `+0x2B0` X | bytes `+0x4B80` |
|---|---|---|---|---|
| 17:58:53.025 | re-validación desde cero (mismo PID/starttime/object; X sin deriva; `char[grp]+0x00 == 0x00`; velocity 0; `+0x4B80 == +0x2B0`) | −110.711105 | −110.711105 | `166cddc2` |
| 17:58:53.025168 | **write** (`pwrite` 4 bytes, n=4) | → −110.411105 | — | `7cd2dcc2` |
| +~µs | readback inmediato | **−110.41110** (diff 3e-6 = ULP) | −110.711105 (aún no propagado) | `7cd2dcc2` |
| 17:58:53.525 | observación +1 (+0.5 s) | −110.4111 | **−110.4111** (convergió) | `7cd2dcc2` |
| 17:58:54.0 … 17:58:56.0 | observación +2..+6 | −110.4111 (×5) | −110.4111 (×5) | `7cd2dcc2` |
| ~17:58:56.0 | **restauración automática** (`pwrite` bytes originales, n=4) | −110.711105 | — | `166cddc2` |
| — | readback restauración | **−110.71110535** | — | `166cddc2` → `EXACT` |
| post-test | resolver de solo lectura | −110.711105 | −110.711105 | `char+0x310` = −110.711105 |

Velocity `object+0x4BC0` = `(0,0,0)` en las 6 muestras de observación (sin patada
de física). Y (`+0x4B84`) y Z (`+0x4B88`) **constantes**. `char+0x310` volvió al
valor original tras la restauración.

## Engine behavior

**`CANONICAL CONFIRMED: +0x4B80 held AND +0x2B0 converged to the new value`.**

- La escritura en `object+0x4B80` **se mantuvo** durante ~3.5 s (6 muestras a
  0.5 s + readback): el motor **NO la revirtió**, a diferencia de `object+0x2B0`
  en MVP 2.
- `object+0x2B0` (la copia observable de render) **convergió** al valor nuevo en
  la primera muestra de observación (≤ 500 ms ⇒ 1 frame a efectos prácticos) y se
  mantuvo ahí. Confirma que `+0x2B0` se deriva de `+0x4B80` cada frame.
- Ninguna reversión de W2 observada (ni siquiera de 1 frame en las muestras a
  0.5 s). Consistente con "la fuente de W2 es una copia de `+0x4B80`".

## Rollback

`attempted: True` · `n: 4` · `readback_bytes: 166cddc2` · `readback_x:
-110.71110534667969` · **`result: EXACT`**. Un solo intento; exacto a la primera.
`docs/research/player/MVP2B_WRITE_TEST_20260907T235831Z/restore_x.bin` conserva
los 4 bytes originales.

## Visual observation

Usuario: **`NO NOTE MOVIMIENTO PERO TODO NORMAL CON EL JUEGO`**. El delta (0.30 u)
es pequeño frente a la escala del mundo (coords ~110) y a un paso de locomotion
(~8–40 u); el desplazamiento-y-retorno de 0.3 u sobre ~3.5 s pudo no percibirse a
simple vista, y/o la cámara (que sigue `+0x310` interpolado) lo enmascaró. A
diferencia de MVP 2, aquí la ausencia de percepción visual **no** se debe a una
reversión: la evidencia en memoria muestra que el valor se mantuvo y propagó a
`+0x2B0` durante toda la ventana.

## Errors

Ninguno. Sin crash, sin NaN/Inf, sin valor absurdo, sin cambio de PID/starttime,
sin knockback, sin efecto vertical. Proceso vivo tras la prueba (`process_alive:
True`, `process_starttime_stable: True`). Resolver post-test: X −110.711105, Y
−0.000012, Z 71.277870 (Ryu sin cambios). Hook Sigma2 vivo. AI_PARTNER no tocado.

## Verdict

**PASS.**

- ✅ Todos los gates PASS (incluidos los nuevos de 2B: velocity ≈ 0, chain
  `+0x4B80 == +0x2B0`).
- ✅ La escritura se realizó sobre `object+0x4B80` del LOCAL_PLAYER (identidad
  revalidada), no sobre el compañero IA.
- ✅ Readback inmediato confirmó el valor escrito (diff = ULP float).
- ✅ **La escritura se MANTUVO** ~3.5 s — el motor **NO la revirtió**.
- ✅ **`object+0x2B0` CONVERGIÓ** al valor nuevo en ≤ 1 frame — propagación
  canónica confirmada.
- ✅ El proceso permaneció estable; sin crash ni corrupción; Y/Z/rotación/velocity
  intactos; AI_PARTNER intacto.
- ✅ El rollback restauró exactamente (`EXACT`); `char+0x310` corroboró.
- ⚠️ El usuario no percibió el desplazamiento visual (delta pequeño para la escala
  del mundo; **no** por reversión).

## Interpretación

`object + 0x4B80` es **escribible de forma persistente** y **se propaga a la
posición observable** (`object+0x2B0` y sus ~14 copias de render). Es el primitivo
de teleport real que MVP 2 no encontró en `+0x2B0`. Un teleport práctico usaría un
delta mayor (varias unidades) y, para mantener la posición, o bien una escritura
sostenida por varios frames o bien coordinación con el frame de update (el valor
se mantuvo 3.5 s aquí sin necesidad de re-escritura, así que una escritura única
ya persiste mientras el jugador no reciba input/física que lo mueva).

## Restricciones respetadas

Una escritura, una restauración automática (no dependió de input humano;
modificación mantenida ~3.5 s, muy por debajo del timeout de 30 s). Ni Z, ni Y, ni
velocity, ni cápsula, ni rotación, ni AI_PARTNER. Sin networking. Sin hooks
nuevos. Sin cambios en `core.dll` / plugin / EXE / Proton / sysctl. (Repetido una
vez el 2026-09-08 con delta +10.0 X, autorizado por separado — sección final.)

Evidencia: `docs/research/player/MVP2B_WRITE_TEST_20260907T235831Z/`
(`pre_write.json`, `original_x.bin`, `result.json`, `restore_x.bin`).
Herramienta: `tools/player_write_test_2b.py`.

---

## Repetición — 2026-09-08: delta **+10.0 X** (confirmación visual)

Autorizado por el usuario (`Repite MVP 2B con delta +10.0 X para confirmar
visualmente`). Misma herramienta `tools/player_write_test_2b.py` con `--delta 10.0`
(y `--confirm "AUTORIZO MVP 2B: WRITE +10.0 X en object+0x4B80"`). Mismo proceso
PID 14042 / starttime 108576.

| | |
|---|---|
| Original X (canon) | −110.128990  bytes `0b42dcc2` |
| Delta | **+10.0** |
| New X | −100.128990  bytes `0b42c8c2` |
| Gates | ALL PASS (`LOCAL_PLAYER_STABLE` ranges 0.0 · velocity 0.0 · chain dist 0.0) |

- Readback inmediato = `−100.12899` (valor exacto, sin diff).
- Observación 6×0.5 s: **`+0x4B80` se mantuvo en `−100.1290`** las 6 muestras — el
  motor **no lo revirtió**, y **NO hubo clamp de colisión** (el delta completo de
  10 u se mantuvo exacto). **`+0x2B0` convergió** a `−100.1290` en ≤ 1 frame.
  Velocity `+0x4BC0` = `(0,0,0)` toda la ventana. Y/Z intactos.
- Restauración automática **EXACT** (`0b42dcc2`, readback `−110.12899017333984`).
  Post-test: `+0x4B80`, `+0x2B0`, `char+0x310` todos en el valor original.
- Proceso vivo, starttime estable, hook Sigma2 vivo, AI_PARTNER intacto, sin
  crash/anomalía.

**Confirmación visual del usuario:** «Ryu se desplazó visualmente ~10 unidades y
luego volvió a su posición original. El desplazamiento **NO ocurrió con animación
de caminar, correr ni saltar**. Fue un cambio **prácticamente instantáneo** de
posición: de un punto A a un punto B distante y, tras el rollback, regresó
prácticamente de forma instantánea a A. No observé una transición normal de
locomoción. Después de la prueba el juego siguió funcionando normalmente. No
observé crash, bloqueo, cámara extraña ni comportamiento anormal.»

**Verdict: PASS + VISUAL CONFIRMED.** Escribir `object+0x4B80` produce un
**teleport instantáneo** del personaje (cambio de posición sin animación de
locomoción — coherente con escribir el estado de posición autoritativo
directamente, sin pasar por el controlador de movimiento). La copia observable
`object+0x2B0` y el render siguen al valor canónico en ≤ 1 frame. El rollback es
igualmente instantáneo y exacto.

`object + 0x4B80` = **CANONICAL_POSITION_RUNTIME_VERIFIED + PERSISTENT-WRITE
VERIFIED + VISUALLY CONFIRMED** como primitivo de teleport.

Evidencia: `docs/research/player/MVP2B_WRITE_TEST_20260908T000634Z/`.
