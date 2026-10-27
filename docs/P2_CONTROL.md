# FASE 17 — Control del compañero IA como Jugador 2 (2026-10-02/03)

**Resultado: PASS.** El personaje del compañero en Misiones en Equipo se controla
con un segundo mando, de forma independiente al del jugador 1. Se mueve con la
locomoción y las animaciones nativas (caminar/correr), ataca (X/Y) y salta (A).
No hacen falta hooks: basta con **dos bytes** que el motor ya usa para ese fin.

Sesión autónoma (el usuario autorizó control total: lanzar el juego, entrar a
menús, escribir memoria). Evidencia: `docs/research/p2_control/`.

## 1. El mecanismo (restos del co-op online de la versión PS3)

El motor conserva el concepto de "jugador 1 / jugador 2":

| dirección (módulo base `0x140000000`) | contenido | valor en Team Mission |
|---|---|---|
| `0x14211e760` (byte[2]) | **jugador → índice de actor** en `game_object` | `[0, 4]` (P1 = Ryu, P2 = compañero) |
| `0x14211e754` (byte[2]) | **jugador → ranura de mando** (`f(player)` en `0x140f8bd40`) | `[0, 0]` (¡los dos leen la ranura 0!) |
| `0x142235880 + k*0x38` | estado de mando por ranura `k` (stick L en `+0x18/+0x1C`, floats −1..1) | ranura 0 = mando 1, ranura 1 = mando 2 |
| `character[group] + 0x00` | **puerto de mando que lee el personaje** (0..3); `4` = ningún puerto → cerebro IA | Ryu `0x00`, compañero `0x04` |

**Corrección a fases 9–15:** `character[group]+0x00` NO es una "clase
local/IA" ni un discriminador semántico: es el **número de puerto de mando**.
`0x04` funciona como "IA" solo porque no existe el puerto 4.

Bucle de asignación de puertos (`0x140f7f6e0`, bucle en `0x140f7f748`, `r14d = 0..3`):

```
for port in 0..3:
    if numPlayers > 1:
        if char[actor(P1)].port == port: pad = pads[f(0)]      ; f = 0x140f8bd40 -> byte[0x14211e754 + player]
        elif char[actor(P2)].port == port: pad = pads[f(1)]
        else: pad = default_pad[port]
    call 0x140f6b380(port_state[port] (stride 0x1CC), pad, ...)   ; copia stick/botones al estado del puerto
```

Los personajes leen el estado de su puerto (`char+0x00`). Con el puerto ≥ 4 el
personaje queda en manos de la IA.

## 2. Receta para controlar al compañero

```
partner_char = 0x142F78B10 + group(game_object[byte 0x14211e761]) * 0x1240
byte[partner_char + 0x00] = 1     ; el compañero lee el puerto 1  (IA desconectada al instante)
byte[0x14211e755]         = 1     ; el jugador 2 usa la ranura de mando 1 (segundo mando)
```

Revertir: `partner_char+0x00 = 4`, `0x14211e755 = 0` → la IA retoma el control en
el siguiente frame (verificado varias veces, sin crash).

Persistencia: escritos una sola vez y muestreados cada 5 ms durante 6 s, el motor
no los toca durante la misión. Hay que reaplicarlos al cargar o reintentar la misión.

## 3. Pruebas (`tools/exp_indep.py`, enemigos neutralizados)

Para eliminar el ruido del combate (derribos, agarres), los enemigos se asignan
al **puerto 3**, sin mando (`tools/freeze_enemies.py`): con el mismo mecanismo
su IA se desconecta y se quedan quietos. Así Ryu queda inmóvil sin input
(Δ = 0,00 durante segundos).

Con `padmap[1] = 1` y el compañero en el puerto 1 (pasada limpia):

| prueba | compañero | Ryu |
|---|---|---|
| sin input | 0,00 | 0,00 |
| stick del mando 1 | **0,00** | **3,38** |
| stick del mando 2 | **5,00** | **0,00** |
| mando 1 izquierda + mando 2 derecha | 5,43 (−Z) | 5,41 (−X) — direcciones independientes |
| botón X / Y del mando 2 | estado `0x0b` (ataque con embestida) | — |
| botón A del mando 2 | estado `0x55`, Y 5,22 → 7,52 (salto) | — |

Con `padmap[1] = 0` (el valor por defecto), el puerto 1 recibe el mando 1: **los
dos personajes copian el mismo stick** (5,94 / 5,95). De ahí que haga falta la
segunda escritura.

Estados de locomoción observados bajo control del mando 2: `0x26` (caminar),
`0x2a` (correr/parar). La animación es nativa y el desplazamiento lo integra el
motor (sin teleport). Esto supera el resultado PARTIAL de la Fase 16: en vez de
inyectar el comando crudo (`object+0x4B90`), se le da al personaje un **mando real**.

## 3b. El mod: `NGS2Coop.dll` (in-process, `src/coop/main.cpp`)

Sustituye al antiguo stub `NGS2Coop.dll` (respaldado en
`backups/pre-p2-coop-20261003/`). Un hilo propio (cada 4 ms; la función Sigma2
de `core.dll` no corre en cada frame: 0 llamadas en 20 s):

- **El jugador 2 se une o sale pulsando BACK** en el mando de la ranura 1 (flanco de subida de
  `buttons & 0x200`, solo si la ranura está conectada: byte `+0x0E != 0`).
- Al unirse: `padmap[1] = 1` y, si el compañero está en `port == 4` (IA), lo pone en 1.
  Al salir: `port = 4` y `padmap[1] = 0` (vuelve la IA).
- Guardas: `numPlayers (0x14211e5cc) >= 2` (2 en Misiones en Equipo; 1 en menús),
  `actor(P2) < 0xA0` y distinto del de P1 (`0xFF` en menús), entrada de
  `game_object` no vacía, `group < 0x20`. Solo toca datos estáticos de la imagen (no
  dereferencia el heap). Comprobación de versión con `sigma2_image_matches` (si falla, se desactiva).
- Al reintentar o cambiar de misión, el juego vuelve a poner el compañero en 4 y
  resetea `padmap`. El mod lo detecta y lo reasigna solo (verificado).
- Log: `plugin/ngs2coop.log`.

Botones (u32 en `pad+0x00`): UP 0x1, DOWN 0x2, LEFT 0x4, RIGHT 0x8, A 0x10, B 0x20,
X 0x40, Y 0x80, BACK 0x200, LS 0x400, RS 0x800, LB 0x1000, RB 0x2000. Stick L =
floats en `+0x18/+0x1C`.

Validación del mod sin ninguna escritura externa de binding (`tools/exp_mod.py`,
solo mandos virtuales + lecturas), en **dos Misiones en Equipo distintas**
(Acólito 01 de noche con Rachel + Ryu, y una misión de día con Ryu + Ryu; en la
segunda el compañero era el actor **4**; en la primera, el actor **3** →
por eso el mod usa la tabla `0x14211e760` y no un índice fijo):

| prueba | P1 | P2 (compañero) |
|---|---|---|
| reposo | 0,00 | 0,00 |
| solo mando 1 | 3,87 / 2,42 | **0,00** / **0,00** |
| solo mando 2 | **0,00** / **0,05** | 4,39 / 1,51 |
| los dos a la vez | 4,97 / 2,51 | 3,86 / 4,10 |

BACK para salir → la IA retoma el control (estado `0x6f`, se mueve sola); BACK otra
vez → se reasigna. Reintentar la misión → reasignación automática.
Evidencia: `docs/research/p2_control/mod_validation_run2.txt`,
`demo_grid.png` (Rachel P1 + Ryu P2: juntos / P2 corre / P2 ataca / P1 izquierda + P2 salta).

Para jugar: conectar **los dos mandos antes de arrancar el juego**, entrar en
Misiones en Equipo y pulsar BACK en el segundo mando.

## 5. Herramientas nuevas (`tools/`)

| herramienta | qué hace |
|---|---|
| `vpad.py`, `vpad2.sh` | mandos virtuales Xbox 360 vía uinput, controlados por FIFO (`tap`, `hold`, `stick`, `axis`, `key`) |
| `game.sh` | lanzar/detener/enfocar el juego (Steam + script de KWin) |
| `shot.sh` + `src/lab` (`ngs2lab.dll`) | captura del backbuffer desde dentro del juego (hook de `IDXGISwapChain::Present`) |
| `ngs2mem.py` | lectura/escritura de `/proc/<pid>/mem` + layout de actores |
| `ndis.py` | desensamblado de la memoria viva (capstone en `~/.cache/ngs2-venv`) |
| `gdbwatch.py` | watchpoints de hardware con gdb (pc, registros, direcciones de retorno), con detach automático |
| `p2bind.py` | mantiene al compañero en el puerto 1 / ranura 1 (lab) |
| `freeze_enemies.py` | asigna los enemigos al puerto 3 (IA desconectada) para pruebas limpias |
| `exp_indep.py` | pruebas de independencia A–E |

## 6. Incidencias del entorno

- **Pantalla negra en NVIDIA: RESUELTO (2026-10-03).** Causa: con las dos GPU visibles
  (Intel + RTX 4060) el juego crea dos dispositivos D3D11 y el trabajo se reparte entre
  adaptadores. El HUD de DXVK sí se veía (60 fps en la 4060), pero todo lo que dibujaba el
  juego llegaba en negro. Descartado: NVAPI/hideNvidiaGpu, GPL, descriptor heap/buffer,
  unified image layouts, DXVK 3.1.1 de Proton Experimental. **Solución por juego:**
  `dxvk.conf` en la carpeta del juego con `dxvk.deviceFilter = NVIDIA` (copia en
  `config/dxvk.conf`). Se eliminó el `user_settings.py` global de Proton 11.0 (el
  apaño con la iGPU). Resultado en misión: 60 fps estables (tope del juego), GPU al ~21 %,
  sin polígonos estirados en las capturas (los artefactos venían de la iGPU Intel/Mesa).
  Banco de pruebas: `tools/gpu_test.sh`. Nota: usar la dGPU con el cargador conectado
  (historial de congelamientos en batería del G16).
- Si el juego arranca minimizado (porque KWin le roba el foco), se queda en negro:
  `tools/game.sh start` lo enfoca durante 20 s.
- **Los mandos virtuales tienen que existir antes de arrancar el juego**: si se
  reconecta un mando con la partida en marcha, el juego no lo vuelve a detectar.

## 7. Prueba local con teclado + un solo mando (2026-10-03)

- `NGS2Coop.dll` ahora deja unirse al jugador 2 desde **cualquier** ranura 0–3 que no sea
  la del jugador 1 (`padmap[0]`), y guarda esa ranura en `padmap[1]`. Ignora los BACK que
  también aparezcan en la ranura del jugador 1 (mandos duplicados por Steam Input). Regresión
  con mandos virtuales: BACK del P1 ignorado, BACK del P2 → `joined from pad slot 1`;
  P2 5,86 / P1 0,00.
- `tools/kbpad.py`: el teclado Logitech G515 pasa a ser un mando Xbox 360 virtual (captura
  exclusiva). `tools/play_kbd_p2.sh` lo arranca antes que el juego.
- Permiso: `tools/udev/70-ngs2-kbpad.rules` (`TAG+="uaccess"` solo para el G515) en
  `/etc/udev/rules.d/`. kbpad no se pudo probar antes de instalar la regla.
- Validado con el teclado G515 (2026-10-03). Steam Input coloca los mandos con identidad
  Xbox 360 **por delante** del Elite 2 real (y los menús solo leen la ranura 0). Por eso `kbpad.py`
  se presenta como **Xbox One S (045e:02ea)**: así queda Elite = ranura 0 (P1) y teclado = ranura 1 (P2).
  Con identidad genérica (no Xbox) el juego (XInput) no lo detecta. En misión, con el usuario
  jugando con el Elite: Tab → `player 2 joined from pad slot 1`; W/D/S → el compañero se mueve
  4,76 / 4,37 / 4,92 (estado `0x2a`). Antes, con los papeles invertidos (teclado en la ranura 0),
  el cruce entre mandos fue 0,00 en 10/10 pruebas (`keyboard_slot2_test.txt`).

## 8. Mandos conectados en caliente (2026-10-03)

- **La conexión en caliente funciona** a nivel de XInput y del juego (comprobado con `ngs2lab.dll`:
  `tools/lab.sh xinput` llama a `XInputGetState` desde dentro del proceso). La conclusión anterior
  ("el juego no detecta mandos conectados tarde") era errónea: en aquella prueba el juego no
  tenía el foco, y sin foco no lee los mandos.
- **El problema real era Steam Input**: Steam envuelve los mandos en dispositivos virtuales
  (`28de:11ff`) y Proton asigna las ranuras XInput según `virtualgamepadinfo.txt`. Al conectar
  un mando, Steam **reordena** (el Elite pasaba al final), y el mando nuevo se quedaba la ranura 0
  y con ella el control del P1. Poner `UseSteamControllerConfig = 0` en localconfig no tuvo efecto (se revirtió).
- **Solución**, en las opciones de lanzamiento del juego en Steam:
  `SDL_GAMECONTROLLER_IGNORE_DEVICES=0x28de/0x11ff SteamVirtualGamepadInfo= SteamVirtualGamepadInfo_Proton= PROTON_LOG=1 WINEDLLOVERRIDES=dbghelp=n,b %command%`
  (backup de localconfig: `localconfig.vdf.bak-ngs2-20261003`). Wine lee los mandos reales directamente:
  Elite en la ranura 0, los nuevos **se añaden** (1, 2…). Al desconectar, la ranura queda libre y el resto
  no se mueve; al reconectar, el mando vuelve a la misma ranura.
- Prueba con el mod (`hotplug_test.txt`): mando conectado con la misión en marcha → BACK →
  `player 2 joined` → P2 se mueve 4,74 y P1 0,00; mando 1 → P1 1,40 / 2,17, P2 0,00.
- Notas: (1) el índice interno del juego no tiene por qué coincidir con la ranura XInput (en la prueba,
  XInput 2 = juego 1); el mod usa el del juego. (2) Al **arrancar**, el orden lo decide la
  enumeración de Wine: un mando creado antes que el juego puede quedarse la ranura 0. (3) Con este cambio, Steam Input
  (remapeos de Steam) no se aplica a este juego.

## 11. Menús compartidos: el P2 elige al compañero (2026-10-03)

- Los menús (título, menú principal, selección de misión, **configuración de personajes**, y la pausa fuera
  de misión) solo leen la **ranura de mando 0** del juego, no `padmap[0]` (en cambio, dentro de la misión el
  personaje del P1 sí sigue `padmap[0]`). Los lectores directos de los botones crudos son solo la rutina de
  actualización de mandos `0x141466030` (61 llamadas/s, una por frame), su copia de frame anterior
  (`0x141633ec7` → `0x142ee73c0`) y el mod.
- `NGS2Coop.dll` intercepta `0x141466030` (gancho inline de 14 bytes con trampolín de los 17 bytes originales,
  todos independientes de la posición y comprobados antes de parchear; el parcheo en caliente aparca a los
  llamantes con `EB FE` mientras escribe). Tras cada actualización, **si `numPlayers < 2` (menús)**, copia la
  ranura del último mando con actividad (botones o stick > 0,35) sobre la ranura 0. Con 2 jugadores (misión)
  no hace nada.
- Resultado (`shared_menu_steps.png`): un mando conectado en caliente (ranura 3) pulsó START en el título y
  navegó hasta una misión él solo. En la configuración de personajes: P2 → RB (columna del compañero) →
  derecha cambia al compañero (Ayane→Momiji→Ryu→Rachel); P1 → LB → derecha cambia al jugador (Momiji→Ryu).
- Uso: en la pantalla de personajes, el P2 pulsa **RB** y elige personaje/arma/ninpo/traje; el P1 pulsa
  **LB** para su columna. Cualquiera de los dos puede confirmar con A.
- ⚠️ No desconectar mandos virtuales con el juego abierto (fallo de XInput de Wine).

## 14. El mando que pulsa BACK es el jugador 2 (intercambio de ranuras)

- Problema encontrado: si el mando del P2 existe **antes** de arrancar el juego, puede ocupar la **ranura 0** (la
  del P1) y su BACK se ignoraba.
- Ahora, BACK en la ranura 0 convierte a ese mando en jugador 2: el gancho de `0x141466030` **intercambia el
  contenido** de la ranura 0 y la del otro mando tras cada actualización. Todo el juego (P1, pausa, menús) ve
  el mando restante como ranura 0. El intercambio sobrevive a salir (el P1 conserva su mando); pulsar BACK otra
  vez en la nueva ranura 0 lo deshace.
- **Bug corregido de paso:** el juego calcula "pulsado este frame" comparando cada ranura con su contenido del
  frame anterior. Al dejar la memoria intercambiada/copiada, comparaba un mando con otro (pulsaciones fantasma
  al mantener botones). El gancho guarda la salida original del juego y se la devuelve antes de cada
  actualización. Verificado: mantener X 1 s = 1 sola pulsación nueva en los dos mandos.
- Estructura de cada ranura (0x38 B): `+0x00` mantenidos, `+0x04` mantenidos del frame anterior, `+0x08`
  pulsados, `+0x10`/`+0x14` otras máscaras de pulsación/repetición, `+0x0e` conectado, `+0x18/+0x1c` stick
  izquierdo. Bits: arriba 0x1, abajo 0x2, izq. 0x4, der. 0x8, A 0x10, B 0x20, X 0x40, Y 0x80, START 0x100,
  BACK 0x200, LB 0x1000, RB 0x2000.
- El jugador 2 ya puede unirse también **desde los menús** (el BACK se lee antes de la copia de menús compartidos).

## 15. Capa propia (overlay)

- `src/coop/overlay.cpp`: gancho de `Present` (encadenado después de `ngs2lab`, para que `tools/shot.sh` la
  capture). Texto con GDI (Georgia) en una textura premultiplicada, dibujada con un shader compilado en tiempo
  de ejecución (`d3dcompiler_47` de Proton) dentro de un `ID3DDeviceContextState` propio: no toca el estado del
  juego. Se desactiva creando `plugin/ngs2coop-nooverlay.txt`.
- Contenido: aviso temporal arriba al centro ("X se ha unido a la partida", "X ha salido…", "Mando de X
  desconectado…", "Jugador 2: pulsa BACK para unirte"), insignia arriba a la derecha en los menús
  ("P1 <nombre de Steam> · P2 …"), nombres sobre JUGADOR/COMPAÑERO y marcador del P2 en la selección de misión.
- Nombres: P1 = nombre de Steam (`SteamAPI_SteamFriends_v017` → `GetPersonaName`). P2 = «Jugador 2» o el nombre
  escrito en `plugin/ngs2coop-p2name.txt`.

## 16. Columnas exclusivas y elección doble de misión

- Variables de menú (`.bss`): pantalla `0x1421544fa` (0 menú principal, 8 modo, 6 selección de misión,
  5 personajes, 74 en misión); columna activa de personajes `0x141e65458`; cursor de misión columna/fila
  `0x141e654c0`/`0x141e654c4`. Todas **solo se leen**: escribirlas desincroniza la lógica del resaltado (la
  columna escrita no cambia la columna real; el cursor escrito se mueve, pero A confirma la misión resaltada).
- **Personajes** (con P2 unido): el P1 solo maneja JUGADOR y el P2 solo COMPAÑERO. Si alguien toca su mando con
  la otra columna activa, el mod lo silencia, inyecta una pulsación de su LB/RB y reenvía después lo que pulsó
  (su primera pulsación ya cuenta). El LB/RB del otro se descarta.
- **Selección de misión** (con P2 unido): el P1 mueve el cursor del juego; el P2 mueve su marcador con la cruceta
  y lo fija con A (B lo suelta). Al confirmar el P1 una misión distinta, se sortea; si gana el P2, el mod retiene
  el A del P1, lleva el cursor a la casilla del P2 con pulsaciones inyectadas y pulsa A. Verificado en 4 rondas
  (3 P2, 1 P1). Límite: el marcador recorre la cuadrícula de 5×2 de la dificultad visible.
