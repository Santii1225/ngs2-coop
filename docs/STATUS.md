> **2026-10-28 — arreglo para Windows nativo.** La 1.1 se cerraba al arrancar en Windows 11 (0xc0000005 en
> `0x14cd0bd`, y una vez ejecución en memoria sin módulo). `install_sound_listener` (`src/coop/main.cpp`) y
> `alloc_near` (`src/coop/quickmenu.cpp`) reservaban en `0x147000000..0x170000000` suponiendo la imagen en
> `0x140000000`: así la carga Wine, pero Windows aplica ASLR (`DllCharacteristics 0x8160`, base observada
> `0x7FF668BB0000`) y los disp32/rel32 se truncaban. Ahora buscan en `base + 0x7300000 .. base + 0x30000000`
> (`SizeOfImage = 0x72CE000`), como `split.cpp`; el oyente de sonido además comprueba el alcance rel32.
> Compilado con WinLibs MinGW-w64 16.2 en Windows. Pendiente: probarlo en partida en Windows y nueva versión de los instaladores.

> **2026-10-27 — versión 1.1 (rama `main`).** Co-op local en Misiones en Equipo cerrado y unido en `main`: partida
> real de una hora con dos mandos físicos (laptop + TV) sin cuelgues ni volcados. Desde el 2026-10-12: cuelgue
> 0x21 → 0xc (D1), cinco ninpo llenos para los dos, iconos de ninpo y retícula de apuntado del P2 en su vista,
> esencia y orbes al jugador más cercano, aviso de arma rechazada y revivir con al menos media vida; pantalla de
> personajes para dos (cursor de cada jugador siempre visible, pulsaciones simultáneas sin perderse, bandas de
> «listo»). Pendiente: la misma arma para los dos en el selector rápido (E1, investigación en
> [CIERRE_COOP.md](CIERRE_COOP.md) «Quinta ronda»), pantallas de fin de misión y de muerte en pantalla dividida.

> **2026-10-12 — cierre del co-op en Misiones en Equipo (rama `wip/p1-nopause`).** Selector rápido para los dos
> jugadores con la ventana del juego, cada uno en su vista y sin pausa. Arreglados los fallos de la prueba real del
> 2026-10-11: arma compartida (cuelgue), parada del mundo tras un cambio (imagen congelada), bucle del Arco de
> perdición con Rachel como P1, barra de vida del P2, caras y aviso de compañero caído en la vista del P2. Pendiente:
> retícula de apuntado del P2 y unir la rama en `main`. Plan y estado en [CIERRE_COOP.md](CIERRE_COOP.md).

> **2026-10-05 — menús co-op.** Aviso "pulsa BACK" al arrancar; nombres solo con el P2 unido. Selector de misiones
> con elección propia del P2 (LB/RB, recuadro rojo dibujado por el juego en su lista de sprites) y el P1 esperando
> al P2. Formato del `databin` descifrado y extractor en `tools/databin_tool.py`. Ver [MENUS.md](MENUS.md).
> Pendiente: atasco de oleadas ([COOP_TESTS_20261004.md](COOP_TESTS_20261004.md)).

> **2026-10-04 21:40 — pruebas reales de co-op local.** Pantalla dividida / dos monitores probada en 12 misiones
> reales. Arreglados: cámaras mezcladas en algunos escenarios (etiquetas por paquete de frame) y la pantalla dividida
> sobre los resultados. Sin resolver: **atasco de oleadas** (un enemigo muerto que nunca se libera y la misión no
> termina). Detalle y siguientes pasos en [COOP_TESTS_20261004.md](COOP_TESTS_20261004.md); monitor en
> `tools/coop_monitor.py`.

> **2026-10-03 21:10 — pulido completo.** El mando que pulsa BACK es el jugador 2 aunque esté en la ranura 0
> (intercambio de ranuras; corregidas pulsaciones fantasma), unirse desde los menús, capa propia con nombres y
> avisos, columnas exclusivas en personajes y elección doble de misión con sorteo. Mandos en caliente, menús
> compartidos, juego en la RTX 4060. Ver [P2_CONTROL.md](P2_CONTROL.md) §14–16.

> **Hito vigente: FASE 17 — P2 CONTROL PASS (2026-10-03).** El compañero IA de las Misiones en Equipo se controla con un segundo mando, de forma independiente y con locomoción, ataques y saltos nativos. Bastan dos bytes: `character[partner]+0x00 = 1` (puerto de mando) y `0x14211e755 = 1` (jugador 2 → ranura de mando 1). [Detalle](P2_CONTROL.md).

> **Hito previo: INGAME_TEST_01 PASS (2026-09-06).** Core cargado, guard/hook/callback/original bool=true observados; menú y misión completados por usuario, salida normal y proceso terminado verificados. Alcance: una ejecución controlada. [Reporte final](INGAME_TEST_01.md). Los apartados previos conservan la historia del proyecto.

---

# CHECKPOINT — 2026-10-03 (FASE 17 — CONTROL DEL COMPAÑERO COMO JUGADOR 2)

| Ítem | Estado |
|---|---|
| **Resultado** | **PASS**: mando 2 → solo se mueve el compañero (5,00 u, Ryu 0,00); mando 1 → solo Ryu (3,38 u, compañero 0,00); los dos a la vez → direcciones independientes. X/Y = ataque (`0x0b`), A = salto (+2,3 u en Y). |
| **Mecanismo** | `character[group]+0x00` = **puerto de mando** (0..3; 4 = IA), NO una "clase". Bucle de puertos `0x140f7f748`; jugador→actor `0x14211e760` = `[0,4]`; jugador→ranura de mando `0x14211e754` (`f()` = `0x140f8bd40`); ranuras de mando `0x142235880 + k*0x38`. |
| **Corrección** | Fases 9–16 llamaban a `char+0x00` "CONTROL_DISCRIMINATOR / clase local-IA". Es el puerto de mando. La "rama local↔IA" de la Fase 15 está en la asignación de puertos, no en la ruta de movimiento. |
| **Neutralizar enemigos (lab)** | Asignarlos al puerto 3 (sin mando) desconecta su IA → pruebas sin ruido de combate. |
| **Entorno** | El driver NVIDIA 615 deja negro el juego en DXVK. Solución temporal: `user_settings.py` de Proton 11.0 con `DXVK_FILTER_DEVICE_NAME=Intel` (iGPU). |
| **Mod** | `NGS2Coop.dll` (`src/coop/main.cpp`): BACK en el mando 2 = el jugador 2 se une o sale. Reasigna solo tras reintentar o cambiar de misión. Validado en 2 Misiones en Equipo distintas sin escrituras externas. |
| **Siguiente** | Probarlo con dos mandos físicos. Después, la red: input del mando remoto → ranura de mando 1 (`0x142235880 + 0x38`) en el host; decidir el modelo (host autoritativo + stream, o lockstep). |


# CHECKPOINT — 2026-09-07 (fin de sesión, FASE 16 — NATURAL MOVEMENT TEST 01)

**HEAD tras `test: execute first controlled raw-command movement injection` — árbol limpio — sin push.** Juego dejado abierto por el usuario (PID 14042, `starttime` 108576, sin reiniciar). **Primer experimento con escritura desde MVP 2B**, autorizado (un único test de movimiento natural sobre LOCAL_PLAYER). Herramienta standalone `tools/raw_command_movement_test.py` (solo `/proc/<pid>/mem`, fail-closed). **Solo se escribió `LOCAL_PLAYER object+0x4B90` (16 bytes); `object+0x4B80` NO se restauró (no hizo falta); AI_PARTNER intacto; sin hooks, sin networking, sin `git push`.** Proceso vivo tras el test, hook Sigma2 re-verificado.

| Ítem | Estado |
|---|---|
| **Resultado** | **PARTIAL** — el raw command inyectado propagó por `object+0x4B90 → object+0x5000 → EMA `char+0x30``, pero `char+0x04` no entró en locomoción ⇒ `0x14249A0` no integró ⇒ sin velocity, sin animación, **sin desplazamiento** (`object+0x4B80` Δ 0.000). Usuario: **"RYU NO SE MOVIÓ"**. |
| **Comando capturado** | humano real, caminar recto (`char+0x04 = 0x26`): `object+0x4B90 = (-0.068983, 0.000632, -0.001078, 1.0)`, bytes `1c478dbd8ba4253ab0458dba0000803f`, `|xz| = 0.069`. |
| **Inyección** | 192 writes de 16 B en `object+0x4B90` (`0x14319bc90`) a ~96–125 Hz durante ~2.0 s. Sin abort, sin failsafe. |
| **`object+0x4B90 → object+0x5000` (0xFF282A)** | **RUNTIME VERIFIED por inyección** — `object+0x5000` latcheó `(-0.069,-0.0011)` casi toda la ventana. |
| **`object+0x5000 → EMA char+0x30` (0xF24F4A)** | **RUNTIME VERIFIED por inyección** — `char+0x30` convergió a `(-0.059…-0.068,-0.001)`. |
| **Gap identificado** | **`char+0x04`** (state de locomoción). Se mantuvo `0x00` idle. `0x14249A0` está keyed en `char+0x04`, no en la magnitud de `char+0x30`. Confirma el **caveat C** de la Fase 15. |
| **Origen de `char+0x04`** | máquina de animación compartida (`0xF1ECA0` / capa `0xF31D8D`–`0xF324E5` / `0xF7BDE0`) desde el **estado deseado / action code `character[group]+0x12`** (Fase 15), NO desde `char+0x30`. |
| **Restauración** | `object+0x4B90` → **EXACT** (`00…00`). Decaimiento post-stop limpio (`+0x5000`/`char+0x30`/velocity/`char+0x04` → idle en ~1.8 s). |
| **`REMOTE_PLAYER_CONTROL_POINT`** | **STRONG CANDIDATE** (sin cambio). **Nivel C (solo raw command) DESCARTADO** como suficiente. Punto de control válido para locomoción natural = **nivel B** (hook `0x14203E0` / store `0x142082B` a `g_scratch`), o nivel A (raw command + `char+0x12` / estado deseado). |
| **Failsafe / salud** | sin crash, sin teleport, sin knockback, Y Δ 0, AI_PARTNER `object+0x4B90 = (0,0,0,0)` post-test, proceso vivo, starttime estable, hook PASS. |

Detalle: **[NATURAL_MOVEMENT_TEST_01.md](NATURAL_MOVEMENT_TEST_01.md)**.

### Artefactos Fase 16 (NO borrar)
- `tools/raw_command_movement_test.py` (fail-closed; `--capture` / dry-run / `--armed`).
- `docs/research/locomotion/natural_movement_test_01/`: `capture_fwd2/capture.json` (+`chosen_raw_command.bin`), `run01/pre_write.json`, `run01/idle_raw_4b90.bin`, `run01/inject_command.bin`, `run01/restore_raw_4b90.bin`, `run01/result.json`.

### SIGUIENTE PASO EXACTO (próxima sesión)
- **NO ejecutar** NATURAL MOVEMENT TEST 02 sin autorización explícita.
- Diseño: **nivel B** — hook read-through de `0x14203E0` para LOCAL_PLAYER que sustituya `g_scratch` (`module_base+0x63F16B0`) por el comando remoto, dejando correr el resto del update per-actor para que `char+0x04` enganche walk. Alternativa mínima: escribir *también* `character[group]+0x12` (action code de walk) junto con el raw command y ver si `0x14249A0` integra.
- NO probar backward/left/right/run/AI_PARTNER/attack/jump. No networking. No push.

---

# CHECKPOINT — 2026-09-08 (fin de sesión, FASE 15)

**HEAD tras `research: confirm AI raw command path and controller divergence` — árbol limpio — sin push.** Juego dejado abierto por el usuario (PID 14042, `starttime` 108576, sin reiniciar). Solo lectura/observación: hardware watchpoints de gdb + `detach` + análisis offline con el volcado `.text` de la Fase 11. **Sin memoria del juego escrita, sin modificar `object+0x4B90`/`+0x5000`/`char+0x12`/`char+0x30`/`g_scratch`/AI_PARTNER, sin desactivar IA, sin inyectar input, sin hooks nuevos, sin networking, sin cambios en `core.dll`/EXE/Proton/sysctl.** Proceso vivo tras la sesión, hook Sigma2 re-verificado.

| Ítem | Estado |
|---|---|
| **Writer de `object+0x4B90` del AI_PARTNER** | **RUNTIME VERIFIED** — watchpoint sobre `MOMIJI object+0x4B90`: 40/40 hits en `0x14210A0` (`movdqu [rax+0x4B90], xmm4`), fn `0x1420F60`, thread "Updating", **call stack byte-idéntica a Ryu**, `rbx = 4` (índice de actor), `r9 = char[1]`, `xmm4 = [module_base+0x63F16B0] + char[1]+0xFA0` (fórmula idéntica), `object+0x5000` 1 frame por detrás, `char[1]+0x04` `0x06→0x26`. |
| **`RAW_COMMAND_SHARED_WRITER`** | **RUNTIME VERIFIED** — Ryu y Momiji usan exactamente `0x14210A0` / `0x1420F60` / `call 0x14203E0` / `g_scratch 0x63F16B0`, mismo layout `object+0x4B90`, mismo downstream (`0xFF282A` → `object+0x5000` → EMA `0xF24F4A` → `char+0x30` → `0x14249A0` → W1). |
| **`0x14203E0` (RAW_COMMAND_PRODUCER)** | chunk de una función per-actor **genérica** (`~0x142015B–0x1420BF9`). Punteros base = globales de bucle per-actor fijados por `0x1420F60`: **`[rip+0x4FD12B0] = G_CHARACTER` (`0x63F16A8`)** (corrección Fase 14: NO es un "manager de input"), `[rip+0x4FD11DF]/4FD1271 = G_OBJECT` (`0x63F16A0`), `[rip+0x4FD112C] = G_GO_REC` (`0x63F1698`), store del comando `[rip+0x4FD0E7D] = g_scratch` (`0x63F16B0`). W2 (`0x14208DD`, commit de `object+0x4B80`) está DENTRO de esta función. |
| **Branch local↔IA dentro de `0x14203E0`** | **NO existe.** Única branch relevante: `0x142046B cmp byte [char[group]+0x0C], 0 ; 0x1420475 cmovne ebx, 0xFF` = **control-lock** (`!=0` ⇒ sin acción). `char+0x0C = 0x00` para Ryu **y** Momiji (no es el discriminador). |
| **Writer de los action codes `char[group]+0x12`** | también **COMPARTIDO** — watchpoint sobre `char0+0x10`/`char1+0x10` (60 hits): 3 RVAs (`0xF1ED0F` en `0xF1ECA0`; `0xF24BF7`; `0xF2480C`), todas compartidas Ryu/Momiji, call stacks byte-idénticas. `char[group]+0x12 = call 0xF88C40(...) ? result[7] : 0xFF` (lookup genérico en tabla de acciones). `0xF1ECA0` corre dentro del árbol `0xF24F4A` (el del EMA). |
| **Divergencia local↔IA** | **NO está en la ruta del comando de movimiento** (toda `0xF1ECA0 → 0x14203E0 → 0x1420F60 → object+0x4B90 → … → W1` es código compartido genérico per-actor, RUNTIME VERIFIED ambos). Está en la **capa de comportamiento / estado deseado** aguas arriba de `0xF1ECA0` — para Momiji: región `0xF31D8D–0xF324E5` / `0xF7BDE0–0xF7BE85` (call stack, **no reconstruida**); para Ryu: traductor input físico → estado deseado (**no localizado**). Discriminador de clase = `character[group]+0x00` (`0x00` local / `0x04` IA). |
| **Clasificación** | `char[group]+0x00`, `char[group]+0x0C`, `object+0x5B56` = **CONTROL_MODE_CANDIDATE**. `[rip+0x4FD12B0]/4FD1215/4FD11DF/4FD112C` = **REJECTED** (son `G_CHARACTER`/`G_OBJECT`/`G_GO_REC`). Índice de actor (`rbx=4`, `G_ACTOR_INDEX 0x63F1690`) = **REJECTED** (var de bucle). `0xF31D8D`/`0xF7BDE0` = **AI_CONTROLLER_CANDIDATE**. Traductor de input de Ryu = **LOCAL_INPUT_OWNER_CANDIDATE** (sin dirección). |
| **`AI_COMMAND_SOURCE`** | **STRONG CANDIDATE** — entra por `char[1]+0x12/+0x13` + estado deseado; capa de comportamiento identificada en la pila, no reconstruida. |
| **`PREFERRED_REMOTE_CONTROL_LEVEL`** | **C** (reescribir `object+0x4B90` cada frame tras `0x14210A0`: el más simple, downstream 100 % compartido y verificado, network-friendly), con **B** (hook de `0x14203E0` / `g_scratch`) como opción "más correcta". **Caveat C** (como MVP 2B): si el motor no lleva `char[group]+0x04` a walk, `0x14249A0` no integra el delta ⇒ posición sin animación. |
| **`REMOTE_PLAYER_CONTROL_POINT`** | **STRONG CANDIDATE** (no RUNTIME VERIFIED: falta la branch local↔IA y la fuente de IA reconstruida). Confianza: ALTA en "`object+0x4B90` raw command compartido + downstream verificado ambos actores"; MEDIA en "reescribir sólo el raw command produce locomoción natural completa". |
| **Test de movimiento natural** | **solo diseñado** ([RAW_MOVEMENT_COMMAND_RESEARCH.md](RAW_MOVEMENT_COMMAND_RESEARCH.md) §15.11): nivel C sobre Ryu, medir si `char+0x04` engancha walk; escalar a B/A si no. **Execution authorized: NO.** No ejecutado. |

Detalle: **[RAW_MOVEMENT_COMMAND_RESEARCH.md](RAW_MOVEMENT_COMMAND_RESEARCH.md) §15** · [REMOTE_CONTROL_INJECTION_RESEARCH.md](REMOTE_CONTROL_INJECTION_RESEARCH.md).

### Cadena completa (Fases 11–15)
```
[Ryu] input físico → estado deseado        [Momiji] árbol de comportamiento IA (0xF31D8D / 0xF7BDE0) → estado deseado
        └──────────────  (convergen aquí)  ──────────────┘
                   ▼  0xF1ECA0 (updater de acción/animación per-actor, COMPARTIDO) → char[group]+0x12 (action code) vía lookup 0xF88C40
                   ▼  0x14203E0 (RAW_COMMAND_PRODUCER, genérico per-actor; W2 0x14208DD dentro) → g_scratch [module_base+0x63F16B0]
                   ▼  0x14210A0 en bucle per-actor 0x1420F60:  object+0x4B90 = g_scratch + char[group]+0xFA0   ◄── RAW_COMMAND per-actor
                   ▼  0xFF282A (frame+1)  →  object+0x5000
                   ▼  EMA 0xF24F4A  →  char[group]+0x30 (dir suavizada) ; char+0x04 (state → animación)
                   ▼  0x14249A0 (build delta, speed-clamp 0x1469F60())
                   ▼  W1 0x141BB90:  object+0x4B80 += delta   (CANONICAL_POSITION_RUNTIME_VERIFIED)
                   ▼  object+0x4BC0 velocity (derivada) ; object+0x2B0 + ~14 copias de render
```

### Artefactos Fase 15 (NO borrar)
- `docs/research/locomotion/`: `watch_momiji_obj4B90_moving.txt` (40 hits del writer `0x14210A0` del AI_PARTNER), `watch_char12_action_moving.txt` (60 hits; writers de `char[group]+0x10..0x17`), `wp_4b90_momiji.gdb`, `wp_char12.gdb`.
- `docs/RAW_MOVEMENT_COMMAND_RESEARCH.md` §15.

### SIGUIENTE PASO EXACTO (próxima sesión)
- **NO ejecutar** el test de movimiento natural sin autorización explícita.
- Si se autoriza: nivel C sobre Ryu (`object+0x4B90` sostenido per-frame), **medir** si `char[0]+0x04` pasa a walk y si `char+0x30`/velocity rampan; si no engancha, escalar a nivel B (hook `0x14203E0` / `g_scratch`).
- Opcional para cerrar la branch local↔IA: reconstruir la capa `0xF31D8D`–`0xF324E5` / `0xF7BDE0` (comportamiento/estado deseado) y el traductor de input de Ryu.
- No escribir memoria. No desactivar IA. No networking. No push.

---

# CHECKPOINT — 2026-09-08 (fin de sesión, FASE 14)

**HEAD tras `research: trace raw local and AI movement command producers` — árbol limpio — sin push.** Juego dejado abierto por el usuario (PID 14042, sin reiniciar). Solo lectura/observación: hardware watchpoints de gdb + `detach` + análisis offline con el volcado `.text` de la Fase 11. **Sin memoria del juego escrita, sin modificar `object+0x4B90`/`+0x5000`/`char+0x30`/`char+0xFA0`/`[0x63F16B0]`/AI_PARTNER, sin desactivar IA, sin inyectar input, sin hooks nuevos, sin networking, sin cambios en `core.dll`/EXE/Proton/sysctl.** Proceso vivo tras la sesión, hook Sigma2 re-verificado.

| Ítem | Estado |
|---|---|
| **Área de comando crudo per-actor** | **`object + 0x4B90` (float4)** — pinneado con exactitud (era "`object + ~0x5C00 + K`" en la Fase 13c). `0xFF282A` copia `object+0x4B90 → object+0x5000` con offset exacto `0x5C06 - 0x1076` (`rdi = 1` para Ryu y Momiji). `object+0x5000` va **1 frame por detrás** de `object+0x4B90`. `(0,0,0,0)` en reposo ambos actores. |
| **Writer de `object + 0x4B90`** (LOCAL_PLAYER, capturado) | **`0x14210A0`** (`movdqu [obj+0x4B90], xmm4`) en el **bucle per-actor `0x1420F60`–`0x14215C3`**, hilo "Updating" (50 hits, todos Ryu). Caller `0x142C499` en `0x142C460` (`for edx = 0 .. 0xA0`). Lógica: `object+0x4B90 = [module_base+0x63F16B0] + character[group][0xFA0]`; si `byte[object+0x5B56] == 0` ⇒ `object+0x4B90 = (0,0,0,0)`. |
| **`[module_base + 0x63F16B0]`** | scratch global float4 del comando; `0x1420F60` lo pone a 0 (`0x142101B`) y luego `call 0x14203E0` (`0x1421032`) lo rellena por actor. Watchpoint: 46 hits/idle, 2 writers alternando (`0x142101B` el zero, `0x142082B` dentro del árbol de `0x14203E0`). |
| **`character[group] + 0xFA0`** | término aditivo per-actor; **`(0,0,0,0)` para Ryu y Momiji** — watchpoint WRITE: **0 hits** durante movimiento (no se usa en este escenario; posible aim-assist / nudge). |
| **`0x14203E0`** (RAW_COMMAND_PRODUCER) | productor del comando per-actor. Head: lee manager de input `[rip+0x4FD12B0]` (campos byte `+0x12`/`+0x13`/`+0xF8A`/`+0xF85`, `0xFF` = sin asignar; gate `+0xC` = `CONTROL_MODE_CANDIDATE`), managers `[rip+0x4FD1215]` (`word +0x1FA` state) y `[rip+0x4FD11DF]` (gate object `+0x5B6D`). **La rama exacta input-device vs AI-brain DENTRO de `0x14203E0` NO se aisló.** |
| **Divergencia / convergencia** | divergencia = dentro de `0x14203E0` (sin aislar). Convergencia = **`object + 0x4B90`** (writer compartido `0x14210A0` en el bucle per-actor). De ahí abajo (`0xFF282A` → `object+0x5000` → EMA `0xF24F4A` → `char+0x30` → `0x14249A0` → W1 `0x141BB90`) = código compartido RUNTIME VERIFIED (Fases 12/13). |
| **`REMOTE_CONTROL_INJECTION` status** | **STRONG CANDIDATE** — RAW_COMMAND (`object+0x4B90`) + su writer LOCAL_PLAYER capturados; downstream compartido verificado. Falta: writer de `object+0x4B90` de Momiji en runtime; aislar la rama input↔IA de `0x14203E0`; confirmar `CONTROL_MODE_CANDIDATE` (`[rip+0x4FD12B0]+0xC`). |
| **`REMOTE_PLAYER_CONTROL_POINT` (candidato)** | **`object + 0x4B90`** reescrito cada frame **después** de `0x1420F60` (o hook de `0x14203E0` / `0x1420833`). Downstream 100 % compartido, produce locomoción + animación naturales, delta acotado por el speed-clamp (sin teleport). **NO escrito.** |
| **Momiji `object + 0x4B90`** | writer no capturado en runtime (el bucle `0x1420F60` recorre todos los actores; Ryu, edx 0, llenó el `MAX=50` antes que edx 4). Estructuralmente el mismo `0x14210A0`. |
| **Siguiente experimento** | **Solo diseñado** ([RAW_MOVEMENT_COMMAND_RESEARCH.md](RAW_MOVEMENT_COMMAND_RESEARCH.md) §10): reescribir `object+0x4B90` con dir unitaria + `w=1` cada frame en `LOCAL_PLAYER_STABLE` → Ryu debería caminar con animación normal. **Execution authorized: NO.** No ejecutado. |

Detalle: **[RAW_MOVEMENT_COMMAND_RESEARCH.md](RAW_MOVEMENT_COMMAND_RESEARCH.md)** · [REMOTE_CONTROL_INJECTION_RESEARCH.md](REMOTE_CONTROL_INJECTION_RESEARCH.md).

### Cadena completa (Fases 11–14)
```
[Ryu] poll de input          [Momiji] AI brain
        └────►  0x14203E0  ◄────┘   RAW_COMMAND_PRODUCER (rama input↔IA interna, sin aislar)
                   │  escribe [module_base + 0x63F16B0]  (scratch global float4, per-actor)
                   ▼
        object + 0x4B90 = [0x63F16B0] + character[group][0xFA0]   ◄── CONVERGENCIA (RAW_COMMAND per-actor)
                   │   writer 0x14210A0 en bucle per-actor 0x1420F60 ; gate object+0x5B56
                   ▼  0xFF282A (frame+1)
        object + 0x5000  (copia; (0,0,0,0) idle, dir+w=1 activo)
                   ▼  0xF24F4A (EMA)  ──►  character[group]+0x30 (dir suavizada) ; char+0x04 (state → animación)
                   ▼  0x14249A0 (build delta, speed-clamp 0x1469F60())
                   ▼  W1 0x141BB90:  object+0x4B80 += delta   (CANONICAL_POSITION_RUNTIME_VERIFIED)
                   ▼  object+0x4BC0 velocity (derivada) ; object+0x2B0 + ~14 copias de render
```

### Artefactos Fase 14 (NO borrar)
- `docs/research/locomotion/`: `watch_ryu_obj4B90_moving.txt` (50 hits del writer `0x14210A0`), `watch_gcmd_63F16B0.txt` (writers de `[0x63F16B0]`), `watch_charFA0_none.txt` (0 hits), `wp_4b90.gdb`, `wp_g5b0.gdb`.
- `docs/RAW_MOVEMENT_COMMAND_RESEARCH.md`.

### SIGUIENTE PASO EXACTO (próxima sesión)
- **NO ejecutar** el experimento de movimiento natural sin autorización explícita.
- Antes: (a) capturar en runtime el writer de `object+0x4B90` de Momiji (watchpoint Momiji-only); (b) aislar la rama input-device vs AI-brain dentro de `0x14203E0`; (c) confirmar el `CONTROL_MODE_CANDIDATE` (`[rip+0x4FD12B0]+0xC`).
- No escribir memoria. No desactivar IA. No networking. No push.

---

# CHECKPOINT — 2026-09-08 (fin de sesión, FASE 13)

**HEAD tras `research: trace local and AI locomotion control paths` — árbol limpio — sin push.** Juego dejado abierto por el usuario (PID 14042, sin reiniciar). Solo lectura/observación: `tools/locomotion_probe.py` + hardware watchpoints de gdb + `detach`, análisis offline con el volcado `.text` de la Fase 11. **Sin memoria del juego escrita, sin modificar `char+0x30`/`+0x04`/`+0x24`/`+0x4B80`/`+0x4BC0`/AI_PARTNER, sin hooks nuevos, sin networking, sin cambios en `core.dll`/EXE/Proton/sysctl.** Proceso vivo tras la sesión, hook Sigma2 re-verificado.

| Ítem | Estado |
|---|---|
| **Comando de dirección de movimiento** | **`character[group] + 0x30` (float4)** — `(0,0,0,0)` en reposo, específico de dirección al moverse, **mismo layout para LOCAL_PLAYER y AI_PARTNER**. `0x14249A0` lo consume para construir el delta de W1 (`object+0x4B80 +=`). |
| **Ruta de locomoción compartida** | **RUNTIME VERIFIED** — el writer de `char[group]+0x30` es **`0xF25054` en `0xF24F4A`** (filtro EMA), hilo "Updating", **capturado en vivo con instrucción/función/pila/EMA/enum-de-state IDÉNTICOS para LOCAL_PLAYER y AI_PARTNER** (46 hits sobre `char[1]+0x30` de Momiji). `0xF24F4A` corre 1×/actor/frame. |
| **Punto de convergencia input↔IA** | **`object + 0x5000` (float4)** — escrito por **`0xFF2E0B` en `0xFF282A`** (bucle per-actor sobre la `game_object` table), hilo "Updating", **capturado en vivo con instrucción/función/pila IDÉNTICAS para LOCAL_PLAYER y AI_PARTNER** (`rsi` = obj de Ryu vs obj de Momiji). El EMA `0xF24F4A` lo filtra hacia `char+0x30`. `(0,0,0,0)` en reposo (no se escribe), `(dir_x,~0,dir_z,w=1)` al moverse; **formato idéntico ambos actores**. |
| **Fuente de `object + 0x5000`** | `0xFF282A` copia un lote de campos desde **`object + ~0x5C06`** (área de comando crudo per-actor) a `object + 0x5000`. La divergencia input-local vs cerebro-IA está **aguas arriba** (quién rellena `object + ~0x5C00`) — **NO capturado**. |
| **`REMOTE_CONTROL_INJECTION` status** | **STRONG CANDIDATE** — writer de `object+0x5000` verificado para ambos actores + locomoción downstream compartida (RUNTIME VERIFIED); falta identificar el generador del comando de IA y el writer/layout de `object + ~0x5C00`. Detalle: [REMOTE_CONTROL_INJECTION_RESEARCH.md](REMOTE_CONTROL_INJECTION_RESEARCH.md). |
| **`REMOTE_CONTROL_INJECTION_CANDIDATE`** | **`object + 0x5000`** (comando de dirección per-frame; alimenta el EMA como el stick/la IA). Alternativa aguas abajo: `character[group]+0x30` (pero el EMA la re-deriva de `object+0x5000` cada frame). **NO escrito.** |
| **Selector de animación** | **`character[group] + 0x04` (byte)** = state code de locomoción: `0x00` idle, `0x06` start, `0x0A` lateral, `0x26/0x28/0x2A` walk/run, `0x48` run de IA. Es el selector de la jump table de `0x14249A0`. Enum compartido. Un teleport puro deja `char+0x04 = 0` → sin animación (lo observado en MVP 2B +10.0). |
| **`char + 0x24`** | parámetro de locomoción del estado (tabla de animación, writer `0xF1ECA0`) — **no** magnitud de stick. |
| **`object + 0x4BC0` (velocity)** | **resultado DERIVADO** — velocity real suavizada (ease-in ~0.5 s), publicada para animación/cámara. **NO** es la entrada de la integración de locomoción (esa es `char+0x30` + params). |
| **Writer de `char+0x30`** | pc `0xF25054` (`movdqu [char+0x30], xmm3`) en fn `0xF24F4A`, hilo "Updating" — **filtro EMA**: `char+0x30 = char+0x30_old*decay + input_sample*weight`; la `w` hace ease-in `0.25→1.0` al acelerar. Muestra desde una tabla/ring indexada por contador de frame global (`[rip+0x20815D8]` base — RVA exacta sin confirmar). |
| **`REMOTE_CONTROL_INJECTION_CANDIDATE`** | **`character[group] + 0x30` — STRONG CANDIDATE** (no RUNTIME VERIFIED: falta capturar el writer de la IA y confirmar si escribir `char+0x30` directamente basta o el EMA lo amortigua). |
| **Siguiente experimento** | **Solo diseñado** ([LOCOMOTION_CONTROLLER_RESEARCH.md](LOCOMOTION_CONTROLLER_RESEARCH.md) §9): escribir una dirección unitaria en `char+0x30` durante ~N frames en `LOCAL_PLAYER_STABLE` → Ryu debería **caminar con animación** (sin teleport). **Execution authorized: NO.** No ejecutado. |

Detalle: **[LOCOMOTION_CONTROLLER_RESEARCH.md](LOCOMOTION_CONTROLLER_RESEARCH.md)**.

### Cadena completa (Fases 11–13)
```
input device  ──►  tabla/ring de muestras de input (contador de frame global)
              ──►  0xF24F4A (EMA)  ──►  character[group]+0x30  (dir suavizada)  ◄── CONVERGENCIA (IA escribe aquí por otra ruta)
                                        character[group]+0x04  (state code → animación)
                                        character[group]+0x24  (params de anim)
              ──►  0x14249A0 (build delta = f(char+0x30, params), speed-clamp 0x1469F60())
              ──►  W1 0x141BB90:  object+0x4B80 += delta   (CANONICAL_POSITION_RUNTIME_VERIFIED)
              ──►  object+0x4BC0 velocity (derivada) ; object+0x2B0 + ~14 copias de render
```

### Artefactos Fase 13 (NO borrar)
- `tools/locomotion_probe.py` (solo lectura).
- `docs/research/locomotion/`: `LOCO_IDLE.json`, `LOCO_MOVE_A.json`, `LOCO_MOVE_B.json`, `watch_char30_dir_moving.txt` (44 hits del writer `0xF25059`), `watch_char24_speed_idle.txt`, `awatch_char_movecmd_idle.txt`, `wp_char30_dir.gdb`.
- `docs/LOCOMOTION_CONTROLLER_RESEARCH.md`.

### SIGUIENTE PASO EXACTO (próxima sesión)
- **NO ejecutar** el experimento de movimiento natural sin autorización explícita.
- Antes: (a) capturar el writer de `char[1]+0x30` con Momiji en movimiento (convergencia IA↔input); (b) precisar la tabla/ring de input (`[rip+0x20815D8]`); (c) confirmar si el EMA `0xF24F4A` sobrescribe una inyección directa en `char+0x30`.
- No escribir memoria. No networking. No push.

---

# CHECKPOINT — 2026-09-07 (fin de sesión, FASE 12)

**HEAD tras `research: identify canonical player position writer` — árbol limpio — sin push.** Juego dejado abierto por el usuario (PID 14042, `starttime` 105, sin reiniciar desde la Fase 11). Solo observación: hardware **write-watchpoints** de gdb + `detach`, análisis offline con el volcado `.text` de la Fase 11. **Sin memoria del juego escrita, sin modificar `+0x4B80`/`+0x2B0`/AI_PARTNER, sin hooks nuevos, sin networking, sin cambios en `core.dll`/EXE/Proton/sysctl.** Proceso vivo tras la sesión, hook Sigma2 re-verificado.

| Ítem | Estado |
|---|---|
| **`object + 0x4B80`** | **`CANONICAL_POSITION_RUNTIME_VERIFIED`** (confianza **ALTA**). Los 9 criterios §12 del plan cumplidos. |
| **Writer W1** (locomotion) | `0x141BB90` — primitiva leaf `object+0x4B80 += delta4` (guard NaN). Caller `0x14249A0` (update per-actor ≈21 KB) @ `0x1429B92`: construye `delta = movement_vector * scale`. Dispatcher `0x1420F60` (indexa `game_object[edx]`). Thread "Updating". |
| **Writer W2** (commit de transform) | `0x14208DD` — `movdqu [obj+0x4B80], xmm0` con `xmm0` = resultado de `call 0x6FDE0` (matriz), w=1. Función `0x1420841`. Probable snap de suelo/colisión. |
| **Ninguno es `memcpy`** | W1 = `addss`/`movss` escalar; W2 = `movdqu` de transform. `0x8C7B4`/`0xEAD02E` (Fase 11) **solo leen** `+0x2B0`, no tocan `+0x4B80`. |
| **`+0x4BC0` velocity** | `(0,0,0)` en reposo (Ryu y Momiji); rampa monótona con la aceleración; reset por frame; dirección coherente. Writers `0xF8190E`/`0x14218C0`/`0x14219A0` en el mismo subsistema (`0xF8190E` escribe posición **y** velocity). |
| **AI_PARTNER** | `game_object[4]` (Momiji): **mismos writers W1 y W2** capturados en vivo durante movimiento autónomo. La familia transform-sync `0x1353xxx` también toca su `+0x4B80`. |
| **Repetición** | 2 movimientos del LOCAL_PLAYER (direcciones distintas) + AI autónomo = 130 hits, todos thread "Updating", writers/función/cadena idénticos. |
| **MVP 2B** | **EJECUTADO — PASS** (2026-09-07, autorizado por el usuario). `tools/player_write_test_2b.py`: un `pwrite` de 4 bytes en `object+0x4B80` (X `-110.711105` → `-110.411105`). **La escritura se MANTUVO ~3.5 s** (el motor NO la revirtió, a diferencia de `object+0x2B0` en MVP 2) y **`object+0x2B0` CONVERGIÓ** al valor nuevo en ≤ 1 frame. Restauración `EXACT`, sin crash, Y/Z/velocity/rotación/AI_PARTNER intactos. Usuario: `NO NOTE MOVIMIENTO PERO TODO NORMAL` (delta 0.3 u pequeño para la escala ~110; **no** por reversión). Detalle: [MVP2B_WRITE_TEST_01.md](MVP2B_WRITE_TEST_01.md). |
| **`object + 0x4B80` como target de escritura** | **PERSISTENT-WRITE VERIFIED + VISUALLY CONFIRMED** — repetido 2026-09-08 con delta **+10.0 X**: Ryu se desplazó visualmente ~10 u de forma **instantánea (sin animación de locomoción)**, `+0x2B0` y el render siguieron en ≤ 1 frame, rollback igual de instantáneo y `EXACT`. Es el primitivo de teleport real que `object+0x2B0` (MVP 2) no era. |

Detalle: **[CANONICAL_WRITER_TRACE.md](CANONICAL_WRITER_TRACE.md)** · [TRANSFORM_SYNC_RESEARCH.md](TRANSFORM_SYNC_RESEARCH.md).

### Caveats (documentados, no invalidan)
1. `+0x4B80` recibe **2 escrituras/frame**: integración W1 (`+= delta`) **y** commit de transform W2 (`movdqu`). **W2 SOURCE CHECK (cerrado, ver [CANONICAL_WRITER_TRACE.md](CANONICAL_WRITER_TRACE.md) §9b):** la matriz de W2 = `character[group]+0x1010..+0x1050`, cuya traslación es una **copia por frame de `object+0x4B80`** (vía `0xF33D97`) y rotación copia de `object+0x1AB0`. Es un **round-trip circular**, no un estado independiente. Un write externo a `+0x4B80` (Ryu quieto) puede ser revertido por W2 **como mucho 1 frame** (si W2 corre antes de `0xF33D97`), no de forma permanente — a diferencia de `object+0x2B0` en MVP 2. Riesgo MVP 2B: **LOW-MEDIUM**.
2. Para el AI_PARTNER la familia `0x1353xxx` (transform-sync, la misma que escribe `+0x2B0`) también escribe `+0x4B80`; para el LOCAL_PLAYER en movimiento no se observó. Ambos comparten W1/W2.
3. La prueba definitiva de persistencia (¿escritura en `+0x4B80` con velocity 0 propaga a `+0x2B0` y mueve a Ryu?) es MVP 2B — **NO ejecutada**.

### Artefactos Fase 12 (NO borrar)
- `docs/research/transform_sync/`: `watch_4B80_move1.txt`, `watch_4B80_move2_player.txt`, `watch_4B80_ai_partner.txt`, `scan_4bc0.txt`, `wp4b80b.gdb`, `wp4b80c.gdb`, `wpai.gdb`.
- `docs/CANONICAL_WRITER_TRACE.md`.

### SIGUIENTE PASO EXACTO (próxima sesión)
- MVP 2B ya ejecutado (PASS). `object+0x4B80` = posición canónica escribible/persistente.
- Cualquier siguiente escritura (delta mayor, Z, teleport real, o el compañero IA) es fase posterior y requiere **autorización explícita** del usuario. Sin escrituras por defecto.
- Herramienta `tools/player_write_test_2b.py` conservada (dry-run + `--armed --confirm`); no re-ejecutar sin autorización.
- No networking. No push.

---

# CHECKPOINT — 2026-09-07 (fin de sesión, FASE 11)

**HEAD tras `research: trace runtime transform synchronization path` — árbol limpio — sin push.** Juego dejado abierto por el usuario (PID 14042). Solo lectura: volcado del `.text` inicializado en runtime + desensamblado offline (capstone) + `awatch` de gdb read-only con `detach` + traza temporal read-only. **Sin memoria del juego escrita, sin hooks nuevos, sin cambios en `core.dll`/EXE/Proton/sysctl. Sin networking.** Proceso vivo tras la sesión, `starttime` estable, hook Sigma2 re-verificado.

| Ítem | Estado |
|---|---|
| **Writer real de `object+0x2B0`** | Instrucción **`0x1353E37`** (`movdqa [obj+0x60+0x250], xmm6`), en la rutina per-actor `0x1353D00`, bucle per-frame `0x1354390` (hilo «Updating»). Los RVA `0x8C7B4`/`0xEAD02E` de la Fase 10 **solo LEEN** `+0x2B0` (mirrors + snapshot-out); **no** son el writer. |
| **Cadena per-frame** | `0x1462160` (dispatch `call [rcx+0x10]`) → `0x136CBC0` → `0x1354390` (bucle `game_object[0..0xA0]`) → `0x1353D00(rec,idx)` → `call 0xF7BB70` → `call 0xF8E420` → `xmm6` → `0x1353E37`. |
| **Fuente leída por el writer** | `0xF7BB70` lee **`object + 0x4B80`** (posición) y `character[group]+0x10E0` (referencia) para producir el valor de `+0x2B0`. |
| **`CANONICAL_POSITION_STRONG_CANDIDATE`** | **`object + 0x4B80`** (confianza MEDIA-ALTA). Bloque de estado de movimiento: `+0x4B80` posición · `+0x4BC0` **velocity** (`(0,0,0)` reposo, `(0,0,1.985)` caminando) · `+0x4BD0` centro de cápsula. Lockstep con `+0x2B0` (xcorr r=1.0) pero aguas arriba en la misma frame. 4 sitios de escritura de `[reg+0x4b80]`; el principal `0xF8190E` integra `+0x4BC0` velocity + matriz `+0x1AB0` → `+0x4B80`. Writer identificado **estático**, no capturado vivo (solo corre en movimiento). |
| **AI_PARTNER** | `game_object[4]` (Momiji, obj_id 221 — sigue siendo contador de spawn). Layout `+0x4B80/+0x4BC0/+0x4BD0` **idéntico** al LOCAL_PLAYER; se movió 8.47 u en lockstep mientras Ryu se movía 14.55 u. |
| **MVP 2b** | **Solo diseñado** ([MVP2_WRITE_PLAN.md](MVP2_WRITE_PLAN.md) §MVP 2B): escritura mínima reversible de `object+0x4B80` X `+0.30`, con guard extra de `object+0x4BC0` (velocity) ≈ 0. **Execution authorized: NO.** No ejecutado. |

Detalle completo: **[TRANSFORM_SYNC_RESEARCH.md](TRANSFORM_SYNC_RESEARCH.md)**.

### Artefactos Fase 11 (NO borrar)
- `tools/runtime_text_dump.py`, `tools/rt_image.py`, `tools/canonical_trace_probe.py` (todas solo lectura).
- `docs/research/runtime_text/20260907T1650Z_pid14042/dump_manifest.json` (`.bin` git-ignored; regenerable con `runtime_text_dump.py`, verificable por SHA256 del manifest).
- `docs/research/transform_sync/`: `awatch_obj_2B0.txt`, `awatch_obj_4B80_char_10E0.txt`, `awatch_obj_4B80_4BC8.txt`, `scan_2b0_2e0_310.txt`, `scan_4b80.txt`, `TRACE_IDLE_01.json`, `TRACE_MOVE_01.json`, `wp*.gdb`.

### SIGUIENTE PASO EXACTO (próxima sesión)
- **NO ejecutar MVP 2B** sin autorización explícita del usuario. El plan está en `MVP2_WRITE_PLAN.md` §MVP 2B.
- Antes de MVP 2B convendría: (a) capturar **vivo** el writer de `object+0x4B80` (watchpoint durante movimiento — requiere coordinación con el usuario), (b) confirmar que `+0x4B80` no deriva de un estado aún más profundo en `character[group]` (controller / root-motion de animación), (c) repetir la correlación de movimiento **varias veces** (esta sesión solo 1).
- No repetir la escritura de `object+0x2B0`. No networking. No push.

---

# CHECKPOINT — 2026-09-06 (fin de sesión)

**HEAD `c8d5a12` — árbol limpio — sin push (19 commits por delante de `origin/main`).** Juego cerrado. Sin memoria escrita, sin hooks nuevos, sin cambios en `core.dll`/EXE/Proton en esta sesión salvo lo indicado.

| Ítem | Estado |
|---|---|
| **MVP 0** | **PASS** — dbghelp histórico como loader, `plugin/core.dll` carga, version guard PASS, hook Sigma2 instalado (slot RVA 0x18F9518 → función RVA 0x1462A00), callback invocado, original llamado, retorno bool preservado, menú/misión/cierre estables. [INGAME_TEST_01.md](INGAME_TEST_01.md). Hook re-verificado vivo tras cada reinicio de las fases siguientes. |
| **MVP 1** | **PASS** — Player resolver + posición XYZ + rotación yaw RUNTIME VERIFIED (Fases 6–7); reproducido tras reinicio de proceso y en varias misiones. |
| **LOCAL_PLAYER** | **RUNTIME VERIFIED** — `game_object[0]` (`module_base + 0x3195300` → entrada 0 → objeto). Identificación estructural: única entrada con layout de personaje vivo **y** `char[group]+0x00 == 0x00`. Re-resuelto desde cero tras arranque completo nuevo (Fase 9). |
| **AI_PARTNER** | **RUNTIME VERIFIED (rol)** — `game_object[4]` **o** por propiedad (layout de personaje vivo + `group ≠ 0` + `char[grp][4:6] ∉ {9898,c2c2,ffff}` + `char[grp]+0x210 ≠ 4`). 3 Team Missions (compañero de Ryu + Ayane ×2) + arranque completo nuevo; 2 correlaciones de movimiento post-reinicio (siguió el desplazamiento deliberado del jugador). `obj_id` es contador de spawn, **NO** id de personaje. Base de módulo determinista bajo este Proton (sin ASLR): lo demostrado es la re-resolución del **rol** + discriminadores estructurales. |
| **Position observable** | `object + 0x2B0/+0x2B4/+0x2B8` = world **X / Y / Z**, sistema right-handed, Y-up. **RUNTIME VERIFIED para LECTURA** (Fase 7). Rotación = matriz 3×3 en `char[group]+0x80` (yaw RUNTIME VERIFIED; pitch/roll NOT VERIFIED). |
| **MVP 2 WRITE TEST 01** | **PARTIAL** — 2026-09-06. Escritura única y reversible de `+0.30` en X (`object+0x2B0`), autorizada por el usuario, con `tools/player_write_test.py` (independiente del core; sin hook/ptrace/VirtualProtect). Detalle: [MVP2_WRITE_TEST_01.md](MVP2_WRITE_TEST_01.md). |
| **MVP 2b** | **NO autorizado, NO listo** — no hay `CANONICAL_POSITION_STRONG_CANDIDATE`. |

### Resultado de MVP 2 (explícito)
- La escritura `+0.30 X` **entró correctamente** en memoria; readback inmediato = valor pedido (diff 3e-6 = ULP float).
- **Rollback EXACT** — los 4 bytes originales restaurados y verificados.
- **Sin crash**, sin NaN/Inf, proceso vivo, starttime estable, hook Sigma2 vivo.
- **AI_PARTNER intacto**; Y, Z, rotación y el mirror visual **no escritos**.
- El motor **restauró el valor original en < ~150 ms** (uno o pocos frames).
- ⇒ `object+0x2B0` es una **copia observable / render, NO autoritativa**. Usuario: `NO NOTE MOVIMIENTO`.

### Canonical position research (Fase 10 — explícito)
- **La posición canónica/autoritativa NO se localizó.**
- **Confianza actual: LOW.**
- Copias de posición encontradas y clasificadas:
  - **RENDER/OBSERVABLE COPY**: `object` +0x2B0/+0x2E0/+0xAF0/+0xB20/+0x1330/+0x1360/+0x1930 y `character[grp]` +0x310/+0xFE0/+0x1010/+0x10E0/+0x1120/+0x1160/+0x1170 (siguen al jugador EXACTO; idénticas en reposo).
  - **INTERPOLATED POSITION**: `object+0x310` (+ transitorios +0xB50/+0x1390).
  - **HISTORICAL/PREVIOUS POSITION**: `object+0x340`, `object+0x370` (ring).
- **Writer observado**: rutinas genéricas `memcpy`/`memmove` (RVA `0x8C7B4` confirmada; también `0x1353E41`, `0xEAD02E`), hilo **«Updating»**. No hay instrucción dedicada de actualización de posición.
- **No existe todavía `CANONICAL_POSITION_STRONG_CANDIDATE`.**
- AI_PARTNER tiene la **misma arquitectura de copias** (relevante para multiplayer; no escrito).
- Detalle: [CANONICAL_POSITION_RESEARCH.md](CANONICAL_POSITION_RESEARCH.md).

### SIGUIENTE PASO EXACTO (próxima sesión)

**FASE SIGUIENTE — localizar la fuente autoritativa de posición.**

- **Prioridad 1**: obtener/analizar el `.text` **inicializado en runtime** (volcado en memoria del juego, ya descifrado por SteamDRM) y estudiar **offline** la función de actualización/sincronización de transform del hilo **«Updating»** que alimenta las copias de posición. Objetivo: **seguir hacia atrás** la procedencia de los valores que terminan en las copias observables XYZ (registro/puntero fuente de las rutinas `memcpy`/`memmove` en RVA `0x8C7B4` / `0x1353E41` / `0xEAD02E`). Evita la limitación de `disassemble` de gdb desensamblando el volcado con otra herramienta.
- **Alternativa posterior, solo si el análisis anterior no es suficiente**: diseñar un **hook temporal de observación por frame** para registrar la fuente del transform. **Ese hook todavía NO está autorizado para ejecutarse.**
- **NO repetir escrituras sobre `object+0x2B0`.** No reintentar MVP 2. MVP 2b solo tras un candidato canónico fuerte, con los mismos guards/backup/rollback de `tools/player_write_test.py` y autorización explícita.

### Herramientas y evidencia a conservar (NO borrar)
- `tools/`: `player_resolver.py`, `player_transform_probe.py`, `player_stability_probe.py`, `analyze_transform.py`, `actor_classifier.py`, `player_write_test.py`, `position_sources_probe.py`.
- `docs/research/player/` completo: `PLAYER_SCAN_*`, `PLAYER_SCAN_RESTART_*`, `AXIS_TEST_*`, `ROTATION_TEST_*`, `OTHER_MISSION_IDLE/`, `TEAM_ACTORS_*.json`, `ACTOR_RESTART_*`, `restart_validation.json`, `transform_characterization.json`, `restart_shutdown.json`, `actor_restart_shutdown.json`, `actor_restart_validation.json`, `MVP2_WRITE_TEST_20260907T024348Z/`, `CANONICAL_POSITION/`.
- `docs/`: `STATUS.md`, `PLAYER_RESEARCH.md`, `TEAM_MISSION_RESEARCH.md`, `CANONICAL_POSITION_RESEARCH.md`, `MVP2_WRITE_PLAN.md`, `MVP2_WRITE_TEST_01.md`, `OFFSETS.md`, `RESEARCH.md`, `RUNTIME_ANALYSIS.md`, `INGAME_TEST_01.md`.

---

# Estado — 2026-09-06

## FUNCIONA
- Git inicial limpio: main = origin/main = 903474923020b99ce7209ccc7cca7324015722d4 (12.7). Reflog: solo clon; no commits locales anteriores. Esto no reconstruye sesiones ausentes.
- Toolchain local: CMake 4.4.3, Ninja 1.13.2, MinGW GCC/G++ 16.2.0. Proyecto C++20, sin submódulos ni dependencias descargadas por CMake.
- build/ válido como configuración Windows/Unix Makefiles, pero incompleto: solo nmsteam-bugfixes.dll. Conservado, SHA256 6b35d5d6d1561194488b3a5f04ec78f7691c08787f7774f91e5aa963c2a1dfbe.
- build-codex/ compila los cinco targets después de cuatro correcciones. Logs en evidence/.
- dist/ contiene dbghelp.dll, plugin/{nmloader,nmeffect,nmcombat,nmsteam-bugfixes}.dll y tres runtimes MinGW. Arquitectura AMD64 PE32+, imports/exports y hashes en BINARY_REPORT.md.
- MVP 0 HISTÓRICO: ../steam-1580790-working.log registra dbghelp nativo (línea 888) y los cinco plugins existentes (3981–3987, incluido NGS2Coop). ngs2coop.log en el juego contiene DLL_PROCESS_ATTACH. Esto prueba carga anterior, no gameplay estable ni estas nuevas DLL.

## EN INVESTIGACIÓN
- MVP 0 de compilación local: NO validado en runtime.
- Hook nuevo de core 12.7: VFPHook sobre RVA 0x1462a00 situado en .text, no en una tabla identificada. Requiere desensamblado en memoria tras inicialización y confirmación de ABI. No convertir automáticamente en inline hook.
- Parcheo sin comprobación de versión/bytes; SizeOfCode del loader solo discrimina variantes históricas.
- Instalación activa identificada por libraryfolders, appmanifest y ruta del log, ver RESEARCH.md.
- Distribución experimental local; falta validación de carga/CRT y datos visuales 04413.dat mencionados por effect.

## NO FUNCIONA
- Código original 12.7 no compila íntegro: constructor/asignación prohibidos de VFPHook; Patch de 35 frente a 16 elementos; base_of_image eliminado; ImageId/image_id eliminados.
- No hay networking, lectura de posición del jugador, input remoto ni control de compañero implementados aquí.
- No está demostrada la equivalencia de los binarios instalados con estas fuentes.

## SIGUIENTE PASO
- Verificar la intención y ABI del hook de core contra el ejecutable cargado y comparar con el dbghelp instalado antes de reemplazarlo.
- Añadir validación de identidad y bytes antes de cualquier patch; revisar lifecycle/concurrencia de SimpleInlineHook.
- Solo después, prueba controlada con backup e inventario de modificaciones. MVP 1 empieza por observación de posición, sin escrituras.

## Cambios de este hito
- core: puntero a VFPHook creado en pre_init, siguiendo el patrón existente de otros módulos.
- combat: tipo de 16 elementos consistente y dos punteros independientes para Story/Chapter Challenge.
- effect/dismember.hpp: base_address reemplaza nombre obsoleto.
- loader: recupera localmente discriminador SizeOfCode de 12.6, conservando ramas NGS1/NGS2 AE/JP; no promete soporte del core para ellas.
- Sin nuevos offsets, cambios al juego, prefix, Steam ni configuraciones globales. No se lanzó el juego.

## Reproducir
```bash
cmake -S . -B build-codex -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++
cmake --build build-codex -j"$(nproc)"
cmake --install build-codex --prefix "$PWD/dist"
cp /usr/x86_64-w64-mingw32/bin/{libstdc++-6,libgcc_s_seh-1,libwinpthread-1}.dll dist/
```
Usar estos destinos solo para esta carpeta experimental; nunca apuntar --prefix al juego.
CMAKE_C_COMPILER no se usa porque LANGUAGES es CXX. Avisos CMP0177 de CMake no impiden configurar. No se afirma reproducibilidad bit a bit (timestamps PE).

## Hito análisis 0x1462A00 — 2026-09-06

FUNCIONA: análisis PE y .pdata reproducible con tools/analyze_hook_pe.py; LLVM confirma función [0x1462a00,0x1462cf7). RTTI Sigma2 y slot .rdata 0x18f9518 apuntando a ella identificados estáticamente. Históricos dbghelp y bugfixes inspeccionados sin escrituras.

EN INVESTIGACIÓN: ABI y propósito funcional; .text en disco no presenta instrucciones inicializadas fiables. No hay proceso de juego activo para lectura de memoria. Hipótesis fuertemente respaldada: el autor pasó RVA de función donde VFPHook espera RVA de slot.

NO FUNCIONA: no se puede validar void(Sigma2*) ni una firma de código usando el desensamblado protegido. Las nuevas DLL siguen sin instalarse.

SIGUIENTE PASO: captura de solo lectura de función/vftable y callers después de inicialización normal, sin tocar hooks existentes; verificar ABI antes de cualquier modificación. En esta fase solo se añadieron documentación y herramienta de análisis. No se ejecutó el juego, no se recompiló ni se hizo push.

## Hito actual: RUNTIME VERIFIED — 2026-09-06

FUNCIONA: lectura de PID 51579 con permisos existentes; módulo/base/slot/RTTI/instancia comprobados. Bytes inicializados y caller conservados. Base real=0x140000000, delta=0. Segunda lectura coincide.

EN INVESTIGACIÓN: propósito semántico exacto, temporalidad de instalación futura y coordinación de threads/lifetime. Firma mínima probable bool(Sigma2*); retorno booleano AL necesario confirmado por caller.

NO FUNCIONA: código actual usa RVA de función como slot y declara void en lugar de preservar retorno: CASE C. No se ha aplicado corrección ni probado un nuevo hook.

SIGUIENTE PASO: revisar diseño de slot replacement en RUNTIME_ANALYSIS.md antes de fase de implementación autorizada. No reinvocar inicialización manualmente. Ninguna DLL instalada, memoria escrita, proceso detenido/reiniciado ni política de seguridad alterada. Hallazgos estáticos anteriores siguen STATIC ONLY; los nuevos bytes/punteros son RUNTIME VERIFIED, sin traza de ejecución.

## Hito actual: corrección CASE C — BUILD/HARNESS VERIFIED

FUNCIONA
- Hook Sigma2 corregido: slot 0x18f9518, target esperado 0x1462a00, base dinámica, firma bool(Sigma2*) y retorno original preservado.
- Guard de cabecera/puntero, CAS x64, protección restaurada, pin del módulo y restore explícito condicionado; harness 13 escenarios con ASan/UBSan pasa.
- Compilación completa y auditoría estricta de warnings de core pasan. dist es staging; core SHA256 0154a3861b09d896dc47cd712654bfc6cd99e56d351b629e6c7eabaa98cb7a0f.

EN INVESTIGACIÓN
- Nueva DLL no ejecutada en juego. Falta validar orden de inicialización real, WinAPI de protección/pin, carga de plugins y runtime MinGW. Guard no criptográfico.
- Pin implica módulo residente hasta salida; restore no descarga plugins ni otros hooks. Bootstrap legacy de SetCurrentDirectoryW sigue con su implementación anterior.

NO FUNCIONA
- MVP 0 de la nueva compilación todavía NO demostrado. Los errores CASE C del código sí quedaron corregidos; no confundir compilación con validación in-game.

SIGUIENTE PASO
- Prueba controlada del core en una fase posterior. Este hito termina sin instalar DLL ni iniciar juego, tocar memoria del proceso, modificar Proton o hacer push.

Reproducir harness (nativo, sin Wine/Proton):
```bash
c++ -std=c++20 -Wall -Wextra -Werror -fsanitize=address,undefined -g -Isrc tests/slot_hook_test.cpp -o build-codex/slot_hook_test
./build-codex/slot_hook_test
x86_64-w64-mingw32-g++ -std=c++20 -Wall -Wextra -Wpedantic -Werror -Isrc -fsyntax-only src/core/main.cpp
cmake --build build-codex -j"$(nproc)"
cmake --install build-codex --prefix "$PWD/dist"
```

## Fase 5 — preflight INGAME_TEST_01: PARTIAL

HEAD inicial fe481da y hash del artefacto confirmados sin recompilar. El target core produce dbghelp.dll (238504 bytes), no un plugin core.dll independiente. Loader histórico confirmado: enumera plugin/*.dll desde check_dlls, después de su bootstrap SetCurrentDirectoryW. El core actual depende de interceptar esa llamada temprana; renombrarlo no valida su inicialización como plugin. Reemplazar dbghelp.dll está expresamente prohibido. Ningún archivo instalado ni juego iniciado; logging detallado/log-once pendiente hasta resolver integración. Tres runtimes MinGW requeridos, ninguno instalado. Backup preparado solo con registro de cero modificaciones. Guard/retorno conservados en código; no hay nueva evidencia runtime. Detalles, inventario y siguiente paso en [INGAME_TEST_01.md](INGAME_TEST_01.md).

## Fase 5 — core como plugin instalado, READY TO LAUNCH

Adaptación autorizada posterior al preflight bloqueado: core produce plugin/core.dll; elimina bootstrap proxy/patches .text y carga duplicada de plugins. DllMain programa un hilo sin esperar; inicialización fuera de loader lock con atomic_flag, log nuevo por ejecución y guard. SlotHook y sigma2_hook.hpp idénticos a fe481da. Callback conserva bool original y registra una sola invocación/retorno. Limitación: no se garantiza instalar antes del primer call Sigma2; debe comprobarse, sin reinvocar manualmente.

Build y auditoría estricta PASS; 13 escenarios con ASan/UBSan PASS. PE32+ AMD64. core SHA256 `ca2849b56c3543351f8a56556e80424cc42cdd685ac8a962543384f726e1db1d`. Se instalaron únicamente core.dll y libstdc++-6/libgcc_s_seh-1/libwinpthread-1 en plugin/. Linking dinámico conservado: SetDllDirectoryA del histórico incluye plugin/ en búsqueda; resolución Proton pendiente. Loader/EXE/plugins históricos conservan hashes. Backup `backups/pre-core-runtime-test-20260906-180142`, cuatro archivos nuevos, manifest sin originales reemplazados.

No se inició juego ni inspeccionó runtime. Resultado global PARTIAL, listo para pedir menú al usuario. Detalles, hashes, limitaciones y rollback en [INGAME_TEST_01.md](INGAME_TEST_01.md), apartado adaptación autorizada. Los apartados previos describen hitos históricos.

## INGAME_TEST_01 — menú verificado, misión pendiente

PID 8894 activo; usuario confirma menú. Core y tres runtimes cargados desde plugin/. Log de esta ejecución: base 0x140000000, slot 0x1418F9518, target observado=esperado 0x141462A00, guard PASS, installed, invoked y original retornó true. Retorno preservado por diseño/ASM; caller AL no muestreado. Errores Proton detectados tienen equivalentes históricos; sin crash nuevo identificado. Evidencia en evidence/ingame_test_01/menu/ y detalle en INGAME_TEST_01.md. Resultado PARTIAL: falta misión y salida normal. Ningún cambio de código/binarios ni escritura de memoria. Siguiente paso manual: misión 30–60 segundos y volver al menú.

## INGAME_TEST_01 — misión completada, salida pendiente

Usuario confirma misión terminada y regreso al menú. PID 8894 conserva starttime y sigue activo; core.log idéntico (460 bytes), sin errores nuevos del plugin. Proton añade 1188 mensajes HID TODO Process Report (21, 0) en proceso Wine 0094, distinto del juego 013c; ese mensaje exacto no consta en histórico, sin causalidad demostrada con core. Sin marcadores nuevos de crash/import_dll en captura. No rollback. Resultado PARTIAL: pedir cierre normal y verificar salida antes de PASS. Detalle/evidencia en INGAME_TEST_01.md y evidence/ingame_test_01/mission/.

## INGAME_TEST_01 final — PASS, 2026-09-06T18:23:14.042566-06:00

Usuario confirma cierre normal. PID 8894 ausente; ningún proceso NINJA encontrado. Log core idéntico (460 bytes), sin mensajes nuevos del plugin. RPC 0x6be/0x6ba y error de servicio 1726 al cierre en proceso Wine 0120, distinto del juego 013c, tienen equivalentes en histórico funcional. No crash atribuible al core observado; no atribuir ausencia universal de errores. Restore explícito no invocado: módulo pinned hasta salida, sin auto-restore en DllMain.

Criterios completos de la prueba satisfechos: carga, base/slot/target, guard, instalación, invocación, original true, retorno preservado por diseño/ASM, menú, misión y salida. Sin captura del exit code ni AL del caller; confirmación humana cubre gameplay/cierre. Cuatro archivos instalados y todos los binarios históricos conservan hashes. No rollback; no nuevas escrituras de instalación, código, memoria ni configuración. Evidencia final en evidence/ingame_test_01/shutdown/. Mantener hito; no iniciar otra fase ni push.

## Fase 6 — preparación Player/XYZ (sin validación runtime nueva)

Hito 151ea14 e INGAME_TEST_01 PASS preservados. Investigación separada en [PLAYER_RESEARCH.md](PLAYER_RESEARCH.md). Tablas legacy game_object RVA 0x3195300/stride 0x30 y character RVA 0x2f78b10/stride 0x1240, enlazadas en fuente por group +0x1f: candidatos, NO resolver Player confirmado. limb_data.location_vec pertenece a miembros separados; no es posición de Ryu demostrada. No cambios en hook/core/DLL ni nueva ejecución; esperando RYU QUIETO para snapshot A acotado. Player/XYZ solo serán RUNTIME VERIFIED tras A/B/C y reinicio. Sin commit de hipótesis.

### Player snapshot A (reposo) obtenido

PID 12404; EXE/base/core/slot activo verificados sin escrituras. PLAYER_SCAN_A_IDLE contiene dos muestras de 166760 bytes separadas por 2 s, tablas candidatas y bloques referenciados. Triples plausibles presentes en varios grupos; ningún Player/XYZ confirmado, falta movimiento B/C y reinicio. Herramienta player_snapshot.py es capturador acotado, NO resolver. Evidencia/método en PLAYER_RESEARCH.md. Sin commit de hipótesis ni cambios core.

### Player snapshot B (movimiento) obtenido

Mismo proceso, dos muestras quietas B. Candidato float3 object[0].ptr0+0x2b0 coincide con character group 0+0x310: A (65.1453,5.22,-109.8843) -> B (81.9927,6.4168,-92.9247), estable dentro de A y B. Es candidato, NO Player/XYZ RUNTIME VERIFIED; falta C y reinicio, ejes físicos sin asignar. Detalles en PLAYER_RESEARCH.md y AB_shortlist.json. Sin commit ni cambios core.

### Player snapshot C (más alto) obtenido

Triple candidato C=(109.80220032,7.99999952,-138.06065369), coincidente en object[0].ptr0+0x2b0 y character[group=0]+0x310, estable en pareja y tres lecturas pequeñas posteriores. Usuario confirma más altura: componente 1 compatible con vertical, aún sin aislamiento físico. A/B/C refuerzan candidato; resolver/Player/XYZ NO RUNTIME VERIFIED hasta nuevo arranque. Próxima interacción: cerrar normalmente y confirmar antes de pedir reinicio. Evidencia en PLAYER_RESEARCH.md, ABC_candidates.json y C_targeted_stability.json; sin commit/core changes.

### Player research — cierre para reinicio confirmado

Primera sesión A/B/C terminada normalmente según usuario; PID 12404 ausente, sin proceso NINJA activo. Resolver/XYZ siguen candidatos, pendientes de nuevo arranque. Evidencia restart_shutdown.json; sin memoria escrita, core modificado ni commit de hipótesis.

## MVP 1 CHECKPOINT — pausa solicitada, 2026-09-06

**RESTART VALIDATION — NOT COMPLETED.** No continuar runtime hasta que el usuario reanude. Sesión investigada: PID Linux 12404, terminada normalmente; ausencia comprobada antes de este checkpoint en restart_shutdown.json. No se inició juego ni se hizo investigación adicional al guardar.

### Candidato y método para reproducir

Base observada: 0x140000000. Tabla game_object candidata en module_base+0x3195300, stride legacy 0x30. Entrada 0 contiene puntero 0x143197100 en +0 (también +8/+0x10); group byte +0x1f = 0. Triple float32 contiguo candidato en object_pointer+0x2b0, dirección de ejemplo 0x1431973b0. Offsets provisionales de componentes: +0x2b0/+0x2b4/+0x2b8. NO son todavía ejes físicos XYZ confirmados.

Corroboración: character_candidate = module_base+0x2f78b10+group*0x1240, ejemplo 0x142f78b10. Triple coincidente en +0x310/+0x314/+0x318, dirección 0x142f78e20. Copias adicionales en object+0x2e0/+0xaf0/+0xb20 y character+0xfe0/+0x1010/+0x10e0/+0x1120/+0x1160. No se ha identificado cuál es autoritativa. No hay cadena directa Sigma2->Player demostrada; entrada/group 0 no generalizados a otros personajes o modos. Los bloques observados están en imagen del juego: no asumir heap ni exigir cambio de dirección en otro arranque.

| Snapshot | Componente 0 | Componente 1 | Componente 2 | Evidencia humana |
|---|---|---|---|---|
| PLAYER_SCAN_A_IDLE | 65.14528656 | 5.21999979 | -109.88428497 | RYU QUIETO |
| PLAYER_SCAN_B_MOVED | 81.99269867 | 6.41679859 | -92.92471313 | RYU MOVIDO |
| PLAYER_SCAN_C | 109.80220032 | 7.99999952 | -138.06065369 | RYU POSICIÓN C MAS ALTO |

A->B: delta (16.84741211,1.19679880,16.95957184). B->C cambia de dirección y componente 1 sube a ~8, compatible con altura sin aislamiento de eje. Triples idénticos en dos muestras de cada snapshot separadas 2 s y entre las representaciones object/character. C además tiene tres comprobaciones posteriores separadas 1 s (99 bytes totales), puntero/grupo/triples estables. Son muestras discretas, no traza continua ni medición física independiente. Otros objetos también cambian; 117 ventanas float A/B y 65 A/B/C incluyen ventanas solapadas y no equivalen a objetos únicos.

### Confirmado y pendiente

Confirmado en esta sesión: PID/base, identidad EXE/core, core cargado y hook activo; bytes/valores capturados, coincidencias entre bloques y estabilidad de muestras; usuario realizó dos desplazamientos y terminó más alto; proceso terminó. Hito hook 151ea14 / INGAME_TEST_01 PASS intacto.

**Player resolver, selección del jugador local, XYZ semánticos y layout siguen CANDIDATE.** No se marcan RUNTIME VERIFIED Player/XYZ hasta reproducir tras reinicio. Componente 1 es candidato vertical; yaw/rotación, movimiento e identidad no validados. No existe todavía herramienta final de resolver validado ni integración Player en core.

### Archivos conservados y reproducción

- tools/player_snapshot.py: capturador preparatorio solo O_RDONLY/pread, valida hashes/mappings/slot, límite 256 KiB por muestra, sin escrituras, attach ni inputs. No es resolver Player definitivo. Recibe PID y directorio NUEVO; descubre base/punteros de esa sesión. Para futura captura, después de confirmación humana: `python3 tools/player_snapshot.py <PID_NUEVO> docs/research/player/PLAYER_SCAN_RESTART_IDLE`. No reutilizar PID 12404 ni asumir base/objeto anterior.
- docs/research/player/PLAYER_SCAN_A_IDLE/, PLAYER_SCAN_B_MOVED/, PLAYER_SCAN_C/: binarios de rangos acotados, snapshot.json con direcciones/procedencia/horas/hashes, mappings y core.log. A incluye comparación quieta float y candidatos double.
- docs/research/player/AB_candidates.json, AB_shortlist.json, ABC_candidates.json, C_targeted_stability.json, restart_shutdown.json, rtti_candidates.json. Comparaciones generadas con Python ad hoc y filtros documentados arriba; no existe script independiente de comparación guardado. Los binarios y JSON permiten recalcularlas.
- docs/PLAYER_RESEARCH.md, STATUS.md, RESEARCH.md, OFFSETS.md: método, fuentes legacy, limitaciones y progreso.

Siguiente paso exacto tras reset: leer este checkpoint y comprobar Git; mantener core/hook/instalación intactos. Pedir al usuario iniciar normalmente desde Steam, entrar en misión con Ryu y quedar quieto; esperar «RYU QUIETO TRAS REINICIO». Solo entonces descubrir nuevo PID/base, capturar PLAYER_SCAN_RESTART_IDLE, resolver de nuevo desde tabla estática y corroborar triples/estabilidad. No asumir que ya abrió el juego. Pedir movimiento de confirmación si hace falta, antes de declarar resolver reproducido. No networking, teleport, HP/input/enemigos, Team Missions, cambios de Proton ni push.

## MVP 1 — RESTART VALIDATION COMPLETADA: Player resolver RUNTIME VERIFIED, 2026-09-06

Segunda sesión de juego (arranque nuevo, **PID 16942 ≠ 12404**). Solo lectura, sin attach/escrituras/inputs. Hook 151ea14 / INGAME_TEST_01 PASS intacto; core/DLL/loader/Proton sin tocar.

**FUNCIONA (RUNTIME VERIFIED en esta sesión)**
- Proceso reidentificado por `comm`/EXE; module base 0x140000000 (delta 0); core.dll base 0x6ffff9830000. Slot `base+0x18F9518` → `core_base+0x16F2`: hook validado vivo, gate PASS.
- Resolver desde cero: `root = module_base + 0x3195300` (tabla game_object) → entrada 0 QWORD = 0x143197100, group byte = 0 → objeto localizado automáticamente. `0x143197100` = `module_base + 0x3197100`: **datos estáticos del EXE, NO heap** (RVA dentro de SizeOfImage; mapping anón de la imagen). Redescubierto desde el root, no reutilizado.
- `position = f32x3[objeto + 0x2B0/+0x2B4/+0x2B8]`, corroborado por `module_base + 0x2F78B10 + group*0x1240 + 0x310`.
- PLAYER_SCAN_RESTART_MOVED: triple `(74.63035583, 5.21999931, -135.97770691)` bit-idéntico en 2 muestras snapshot + 8 lecturas probe/7 s en los 3 ejes; object == character exacto en las 10 lecturas. Estabilidad en reposo **limpia**.
- Movimiento IDLE→MOVED: delta (+4.24, ~0, -12.33), coherente en una dirección, Y constante en suelo plano. Y de sesión (5.2200) = Y de reposo de sesión A (5.21999979) a ~4 decimales.
- `Player resolver`: **RUNTIME VERIFIED**. `Position float3 +0x2B0/+0x2B4/+0x2B8`: **RUNTIME VERIFIED** como float3 ligado a posición (estable en reposo, se mueve con el jugador, corroborado en 2 tablas y 2 procesos).

**EN INVESTIGACIÓN / CANDIDATE**
- Semántica por eje: C1 = vertical (confirmado en sesión C); C0/C2 son el plano horizontal, sin asignar X/Z ni handedness.
- Generalidad: solo entrada 0 / group 0 / Ryu en solitario en esta misión. Sin probar otros personajes, misiones, Team Missions, ni "selección del jugador local". Cadena directa Sigma2→Player sin demostrar.
- PLAYER_SCAN_RESTART_IDLE mostró deriva C0/C2 mientras el usuario reportaba reposo: la causa **no** es atribuible a una sola fuente — pudo ser input, gameplay externo, enemigos, knockback, caída o física. La posición la demostró la ventana realmente estable (RESTART_MOVED, luego OTHER_MISSION en suelo firme). Criterio formalizado en Fase 8 como `LOCAL_PLAYER_STABLE`.
- Matiz: toda la cadena es module-relative y el delta ASLR fue 0 en ambas sesiones; el reinicio no venció aleatorización — demostró que la tabla estática sigue resolviendo, que la entrada 0 sigue siendo Ryu, que +0x2B0 se mantiene, que los valores están en el régimen esperado y que el hook se re-verifica vivo.

**Herramientas (solo lectura)**
- `tools/player_resolver.py`: descubre Player automáticamente, imprime PID / Module base / Player address / posición (C0/Y/C2) + corroboración. Valida SHA256 EXE/core y continuidad del slot antes de leer. Sin escritura de memoria, attach ni inputs.
- `tools/player_stability_probe.py`: sonda acotada (cientos de bytes) que re-lee el triple N veces revalidando base/slot.

**Confianza: MEDIA-ALTA.** MVP 1: **PASS** para el objetivo del checkpoint (resolver + float3 de posición reproducidos tras reinicio). Semántica de ejes y generalidad permanecen CANDIDATE. Evidencia: `docs/research/player/PLAYER_SCAN_RESTART_IDLE/`, `PLAYER_SCAN_RESTART_MOVED/`, `restart_validation.json`. Detalle en [PLAYER_RESEARCH.md](PLAYER_RESEARCH.md).

**SIGUIENTE PASO**: conservar este hito. No continuar automáticamente con MVP 2. Cualquier avance (ejes exactos, yaw/rotación, identidad del jugador local, otros personajes/misiones, integración en core) es fase posterior, solo lectura hasta nueva autorización. No networking, teleport, HP/input/enemigos, Team Missions, cambios de Proton ni push.

## FASE 7 — Semántica XYZ + rotación del Player: RUNTIME VERIFIED, 2026-09-06

Mismo proceso PID 16942 (sin reiniciar el juego). Solo lectura; sin escrituras/teleport/inputs/HP/hooks nuevos. Hook 151ea14 / INGAME_TEST_01 PASS y `core.dll` intactos.

**FUNCIONA (RUNTIME VERIFIED)**
- **Semántica de ejes**: `C0 (+0x2B0) = world X`, `C1 (+0x2B4) = world Y (arriba)`, `C2 (+0x2B8) = world Z`. Sistema **right-handed, Y-up**. Evidencia: pruebas AXIS_TEST + correlación con el vector forward de la matriz de rotación (row2 sigue la dirección de caminata a ~3° en 3 desplazamientos); row1 ≈ world +Y; `row0×row1 = row2`; base compartida posición/matriz. Confianza MEDIA-ALTA.
- **Rotación**: matriz de rotación 3×3 en `char+0x80` = `module_base + 0x2F78B10 + group*0x1240 + 0x80` (filas +0x80 right / +0x90 up / +0xA0 forward, 4 floats c/u). `det = +1` en 6 capturas, ortonormal. ROTATION_TEST A/B/C coherentes (Δyaw idéntico vía row0 y row2; giro rígido sobre vertical). Copias en `char+0x100/+0x67C/+0x1020/+0x1040/+0x10EC`. Solo yaw ejercitado; pitch/roll no.
- **Otra misión**: resolver desde cero en una 2ª misión → misma raíz `module_base + 0x3195300`, misma entrada 0 → `0x143197100`, mismos offsets, rotación encontrada igual (det +1, ortonormal). Posición bit-idéntica en 12 lecturas/11 s con Ryu en suelo firme. **El resolver NO es específico del escenario.**
- **Identidad**: el objeto **sigue al personaje controlado** (posición y facing siguen el input; no cámara/proxy — `obj+0x310` retrasa a `obj+0x2B0`, la líder). `obj+0x2B0` es la cabeza de una tabla-anillo de historial de posición (stride 0x30).

**CANDIDATE / pendiente**
- Identidad Ryu-vs-otros personajes: `game_object[0].obj_id = 0`, sin nombre/RTTI → requiere captura multi-personaje.
- Pitch/roll de la matriz (no ejercitados). Handedness right-handed Y-up: CANDIDATE→FUERTE (MEDIA-ALTA).
- Deriva vista en OTHER_MISSION antes de "RYU FIRME" = Ryu moviéndose de verdad, no fallo del resolver.

**Herramientas (solo lectura)**: `tools/player_resolver.py` ampliado → imprime PID, Module base, Player address, Position (C0/X, Y, C2/Z), Rotation (matriz + yaw), Character (obj_id/group). Nuevas: `tools/player_transform_probe.py`, `tools/analyze_transform.py`.

**Ready for MVP 2**: NO todavía — falta pitch/roll e identidad Ryu-vs-otros; MVP 2 (escritura) solo tras eso y con autorización explícita. Evidencia: `docs/research/player/{AXIS_TEST_*,ROTATION_TEST_*,OTHER_MISSION_IDLE}/`, `transform_characterization.json`. Detalle en [PLAYER_RESEARCH.md](PLAYER_RESEARCH.md). No continuar automáticamente con MVP 2. No push.

## FASE 8 — Robustez experimental y clasificación de actores (metodología), 2026-09-06

Solo lectura. Sin escrituras/teleport/rotación/input/HP/networking/hooks; `core.dll`/Proton/EXE intactos.

**Metodología corregida.** `LOCAL_PLAYER_IDLE` ≠ `GAME_WORLD_IDLE`: el personaje local puede moverse sin input (knockback, golpes, caídas, animación, física) y en Team Missions el compañero IA actúa aunque el jugador local esté quieto. Una captura IDLE válida **ya no exige** escenario inmóvil.

- `LOCAL_PLAYER_STABLE`: XYZ de `game_object[0] → object+0x2B0` dentro de tolerancia en N muestras; otros actores pueden moverse.
- `UNSTABLE_LOCAL_PLAYER`: el objeto local se mueve por encima de tolerancia; causa **no** atribuible a una sola fuente (input / knockback / golpe / caída / animación / física).
- Parámetros: `sample_count=10`, `sample_interval=0.5 s`, `horizontal_tolerance=0.05 u`, `vertical_tolerance=0.05 u` (justificación en [TEAM_MISSION_RESEARCH.md](TEAM_MISSION_RESEARCH.md)).
- Corregidas las frases previas que atribuían la deriva de RESTART_IDLE a «entrada del usuario» (PLAYER_RESEARCH.md, STATUS.md, RESEARCH.md, restart_validation.json).

**Herramienta nueva (solo lectura)**: `tools/actor_classifier.py` — observa un conjunto acotado de entradas de `game_object` table durante N muestras; por entrada: object rva, group, obj_id, meta, posición `+0x2B0`, movimiento (rango h/v), distancia al jugador, yaw del grupo; calcula `LOCAL_PLAYER_STABLE` y una clasificación provisional (`LOCAL_PLAYER` / `AI_PARTNER_CANDIDATE` / `ENEMY_CANDIDATE` / `OTHER_ACTOR_CANDIDATE` / `UNKNOWN`). Modo `--compare` para diferenciar capturas A/B/C. Sin dump masivo, sin escritura, sin attach.

**Dry-run** en la misión en solitario actual (PID 16942): entrada 0 = `LOCAL_PLAYER`, `LOCAL_PLAYER_STABLE = True` con 7 enemigos alrededor (idle en ese instante). Entradas con pos (0,0,0) → `OTHER_ACTOR_CANDIDATE`. Falta Team Mission para el `AI_PARTNER`.

**Pendiente**: capturas `TEAM_ACTORS_A/B/C` en Team Mission (jugador local + IA + enemigos), correlación visual del aliado, discriminador local-vs-IA, `CHARACTER_ID_CANDIDATE`, 2ª Team Mission. Detalle en [TEAM_MISSION_RESEARCH.md](TEAM_MISSION_RESEARCH.md). No escribir memoria. No continuar automáticamente con MVP 2.

## FASE 8 — resultado: compañero IA identificado (STRONG CANDIDATE), 2026-09-06

Solo lectura, sin escrituras. 2 Team Missions (compañero de Ryu, y Ayane) + capturas TEAM_ACTORS_A/B/C/D.

**FUNCIONA**
- `LOCAL_PLAYER_STABLE` funciona con combate activo (Ryu quieto, IA + enemigos moviéndose).
- **LOCAL_PLAYER** = `game_object[0]` (obj RVA 0x3197100, id 0, group 0, `char[0]+0x00 = 0x00`) — estable en 2 misiones en solitario + 2 Team Missions.
- **AI_PARTNER = STRONG CANDIDATE**: `game_object[4]` / objeto en RVA `0x319cdb0`. Presente en las 2 Team Missions (compañero de Ryu `obj_id 219`; Ayane `obj_id 220`). Siguió el desplazamiento deliberado de Ryu 28 u (TEAM_ACTORS_C). Layout de objeto = el del jugador (quat vivo en `obj+0x60`, cabecera poblada en `obj+0x90`); enemigos lo tienen a ceros; muertos con quaternion (0,0,0,0).
- **Discriminador enemigo vs personaje jugable**: `char[group][4:6] ∈ {9898, c2c2, ffff}` ⇒ enemigo; fuera de ese conjunto + layout vivo + `group ≠ 0` ⇒ AI_PARTNER; `group == 0` + `char[0][0] == 0x00` ⇒ LOCAL_PLAYER. `char[group]+0x210 = 4` ⇒ personaje derrotado.
- XYZ resolver robusto en Y ≈ 5.2 / 1.2 / −0.95 (tres misiones).

**CANDIDATE / pendiente**
- `game_object[4]` como slot del compañero: estable entre misiones de esta sesión, pero **sin reinicio del juego** no se puede descartar coincidencia de «slot no reciclado». → no `RUNTIME VERIFIED`.
- `obj_id` NO es id de personaje (219→220 entre misiones = contador de spawn). `CHARACTER_ID_CANDIDATE` vía obj_id: **REJECTED**. Id real Ryu/Ayane/… sin localizar.
- `input owner` / control flag explícito: no aislado.
- Dentro de una misión, los índices altos de `game_object` **se reciclan**; resolver por propiedad, no por «entrada N» (excepto 0 y 4, estables entre misiones).

**Herramienta**: `tools/actor_classifier.py --roles` (solo lectura) → LOCAL_PLAYER / AI_PARTNER / ENEMY / OTHER con object rva, posición, rotación (yaw), group, obj_id, discriminadores. En mission D marca exactamente 1 AI_PARTNER, 0 falsos positivos.

**READY FOR CONTROLLED WRITE TEST: NO.** Falta reinicio que confirme el slot del compañero, pitch/roll, e id de personaje. Detalle en [TEAM_MISSION_RESEARCH.md](TEAM_MISSION_RESEARCH.md). No escribir memoria. No continuar automáticamente con MVP 2.

## FASE 9 — Actor restart validation: AI_PARTNER RUNTIME VERIFIED, 2026-09-06

Arranque completamente nuevo (cerré PID 16942, relancé). **PID 29318**, "Misión Acólito 01", compañero IA = Ayane. Solo lectura, sin escrituras.

**FUNCIONA (tras reinicio completo)**
- Gates desde cero: SHA256 EXE/core OK, slot Sigma2 → `core+0x16F2` (hook 151ea14 vivo). Base `0x140000000` (delta ASLR 0, determinista).
- **LOCAL_PLAYER RUNTIME VERIFIED** re-resuelto desde cero: `game_object[0]` → objeto RVA `0x3197100`; identificación **estructural** (única entrada con layout de personaje vivo **y** `char[group]+0x00 == 0x00`), no «es la entrada 0». `LOCAL_PLAYER_STABLE` funciona con combate activo.
- **AI_PARTNER RUNTIME VERIFIED (rol)**: `game_object[4]` → objeto RVA `0x319cdb0` (o búsqueda por propiedad). 3ª Team Mission + reinicio. 2 correlaciones de movimiento post-reinicio: la IA se movió ~10.8 u (B) y ~10.1 u (C) mientras el jugador local ~estable, y en C **convergió sobre la posición nueva de Ryu** (dist 2.55). Los 11 criterios §8 cumplidos.
  - Caveats: base determinista (sin ASLR) ⇒ identidad de RVA esperada; lo demostrado es la re-resolución del **rol** + discriminadores estructurales tras un reinicio real. LOCAL_PLAYER no perfectamente inmóvil en B/C, pero la señal de la IA domina.
- **CONTROL_DISCRIMINATOR_CANDIDATE**: `char[group]+0x00 == 0x00` ⟺ jugador local; `0x04` = compañero IA o enemigo (también `game_object` rec +0x1D: 0x00 vs 0x04; `object+0x98` byte: 0x02 vs 0x04). Reproducido en 3 Team Missions + 2 solo + reinicio. Sin prueba semántica.

**CANDIDATE / NOT VERIFIED**
- `CHARACTER_ID_CANDIDATE = char[group]+0x16` (Ryu `0x4e`, Ayane `0xb6`), baja confianza (2 puntos). `obj_id` sigue REJECTED.
- **PITCH/ROLL = NOT VERIFIED** (row1/up ≈ (0,1,0) siempre; sin salto/caída/rampa medidos). Yaw/matriz siguen RUNTIME VERIFIED.
- `game_object[4]` como slot del compañero: 3 Team Missions + reinicio, pero un roster/modo distinto podría diferir (sin probar).

**Herramienta**: `tools/actor_classifier.py --roles` (solo lectura) añade `control discriminator candidate` y `char[grp][4:6]` a la salida; en la sesión post-reinicio marca 1 LOCAL_PLAYER + 1 AI_PARTNER, 0 falsos positivos.

**MVP 2**: checklist de §14 cumplido → **READY FOR MVP 2 CONTROLLED POSITION WRITE: YES** (con `pitch/roll = NOT VERIFIED` y `character ID = CANDIDATE`, no obligatorios). Experimento **solo diseñado** en [MVP2_WRITE_PLAN.md](docs/MVP2_WRITE_PLAN.md) — delta +0.30 u en `object+0x2B0` (world X), reversible, con guards/backup/rollback/timeout. **NO ejecutado.**

Evidencia: `docs/research/player/{actor_restart_shutdown.json, ACTOR_RESTART_LOCAL.json, ACTOR_RESTART_AI_A/B/C.json, actor_restart_validation.json}`. Detalle en [TEAM_MISSION_RESEARCH.md](TEAM_MISSION_RESEARCH.md) §4h. No escribir memoria. No ejecutar MVP 2.

## MVP 2 — primera escritura controlada de posición: PARTIAL, 2026-09-06

Autorizada por el usuario (`ZONA ESTABLE PARA MVP2` → `AUTORIZO WRITE +0.30 X`). Herramienta independiente `tools/player_write_test.py` (sin core.dll, sin hook, sin `ptrace`, sin `VirtualProtect`): un `pwrite` de 4 bytes en `/proc/29318/mem` O_RDWR sobre `object+0x2B0` (LOCAL_PLAYER world X), resuelto dinámicamente, con restauración automática.

**FUNCIONA**
- Todos los gates PASS (proceso único, TracerPid 0, SHA256 EXE/core, hook Sigma2 vivo, LOCAL_PLAYER resuelto y `char[group]+0x00 = 0x00`, vivo, XYZ finitos, corroboración coherente) + `LOCAL_PLAYER_STABLE` PASS (10×/0.5 s, tol. 0.05 u).
- Escritura única: X `67.845779` → `68.145779` (bytes `0ab18742` → `a44a8842`). Readback inmediato = valor escrito (diff 3e-6 = ULP).
- Restauración automática **EXACT** (`0ab18742`, readback exacto). Proceso vivo, starttime estable, hook vivo, sin crash/NaN/anomalía. Y/Z/rotación/mirror visual/AI_PARTNER **no tocados**. Usuario: `NO NOTE MOVIMIENTO`.

**HALLAZGO (PARTIAL)**
- El motor sobrescribe `object+0x2B0` en < ~150 ms (uno o pocos frames) desde un **estado autoritativo/canónico** más profundo. → `object+0x2B0` está RUNTIME VERIFIED **como lectura** (Fase 7) pero **NO es escribible de forma persistente**. Un teleport real requiere localizar el estado canónico (candidatos: física/rigidbody, nodo raíz de esqueleto, transform «lógico» vía puntero desde `object`) — fase posterior, no ahora.

Evidencia: `docs/research/player/MVP2_WRITE_TEST_20260907T024348Z/`. Detalle en [MVP2_WRITE_TEST_01.md](MVP2_WRITE_TEST_01.md). **No se repite la escritura. No se intenta Y/Z/rotación/AI_PARTNER. No networking.**

## FASE 10 — posición canónica: NO localizada, 2026-09-06 (PID 29318)

Solo lectura / análisis. Sin escritura de posición, sin tocar AI_PARTNER, sin hooks nuevos.

**FUNCIONA (evidencia nueva)**
- Confirmado con watchpoints de hardware read-only (gdb `awatch`/`hbreak`; proceso reanudado, sin escribir memoria del juego): `object+0x2B0` se escribe **cada frame por rutinas genéricas de copia de bloque** (RVA 0x8C7B4 memcpy inline confirmado; también 0x1353E41, 0xEAD02E), en el hilo **«Updating»**. Con Ryu quieto el watchpoint de cambio de valor NO dispara → se reescribe el **mismo** valor cada frame. NO hay instrucción dedicada `movss [obj+0x2B0],xmm`.
- Mapeadas todas las copias de posición y clasificadas: 7 en `object` (+0x2B0/+0x2E0/+0xAF0/+0xB20/+0x1330/+0x1360/+0x1930) y 7 en `character[grp]` (+0x310/+0xFE0/+0x1010/+0x10E0/+0x1120/+0x1160/+0x1170) = **RENDER/OBSERVABLE COPY** (siguen al jugador exacto, Δ 1.3543 u en un movimiento controlado); `object+0x310` = **INTERPOLATED** (lag en movimiento); `object+0x340/+0x370` = **HISTORICAL** (ring de posiciones anteriores).
- AI_PARTNER tiene la **misma arquitectura de copias** (equivalente para multiplayer). No se escribió.
- `object` es datos estáticos autocontenidos (sin puntero a cuerpo de física en heap). Sin candidato de velocidad limpio.

**NO FUNCIONA / pendiente**
- **La posición canónica/autoritativa NO se localizó.** Todas las copias halladas son observables/interp/historial. El valor autoritativo se copia dentro de `object` cada frame desde una fuente no alcanzable con `/proc/<pid>/mem` + gdb batch (probablemente derivada de locomoción/animación en registros, o en una struct alcanzada solo transitoriamente).
- Limitación: en este binario Wine/Proton+SteamDRM, gdb `watch` (cambio de valor) no dispara de forma fiable y `disassemble` de rango devuelve vacío en las secciones protegidas.

**Confianza posición canónica: LOW. Ready for MVP 2b controlled canonical write: NO.**

Herramienta nueva (solo lectura): `tools/position_sources_probe.py`. Evidencia: `docs/research/player/CANONICAL_POSITION/`. Detalle en [CANONICAL_POSITION_RESEARCH.md](CANONICAL_POSITION_RESEARCH.md). **No se reintenta la escritura de posición. No se crea hook nuevo. DETENER.**
