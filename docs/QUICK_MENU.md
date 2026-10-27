# Selector rápido (cruceta arriba/abajo) — cómo funciona (2026-10-05)

Visto en vivo en una partida de historia (Santi abriendo, recorriendo y confirmando el selector), con
`tools/menu_watch.py` (bytes que cambian + botones) y puntos de vigilancia de gdb.

## Cadena de llamada
1. **Controlador de pausa** `0x1413b0cb0` (cada frame, hilo "Updating"), estructura `0x141e3a8b8`:
   `+0x00` estado (0 jugando, 1 abriendo, 3 abierto, 4/6 cerrando), `+0x04` tipo (0 nada, 1 pausa, 2 selector).
   Lee los botones recién pulsados del P1 en `0x142235888` (ranura de mando 0, `+0x08`).
2. Jugando (tipo 0): **arriba** (bit 1) → `0x1413afe20` (¿se puede abrir? actor del jugador válido, sin evento) →
   `0x1413b0200`; **abajo** (bit 2) → `0x1413afe20` → `0x1413b0140`. Los dos ponen tipo 2, estado 1, limpian los
   cursores y fijan la fila inicial: arriba → fila **2 (armas)**, abajo → fila **3 (objetos)**; luego
   `0x1413d0f20` prepara las listas.
3. Con tipo 2/3, el despachador `0x1413f4a90` arranca la tarea del menú `0x1413d0c30`: estado del selector = 1,
   interfaz con `0x1414e0150`, globales de pausa (`0x141e3a8c2/c3` = 1, `0x14211e753` = 1, fondo desenfocado).
   `0x1413d0b80` pone el cursor de cada fila sobre lo equipado.
4. Navegación dentro de la tarea; **A** → estado 2 (`0x1413d0ef3`) y aplica la elección; **A/B** cierran
   (rama `0x1413b0ec3` del controlador: tipo 0, `0x1414691a0(6)`, `0x1413b1300`).

## Variables del selector (`0x14215b740`…)
| Dirección | Qué |
|---|---|
| `0x14215b750` | estado: 0 cerrado, 1 navegando, 2 confirmando (A) |
| `0x14215b754` (`b758` copia) | fila: 0 ninpo, 1 proyectiles, 2 armas, 3 objetos; 4 al cerrar |
| `0x14215b760` / `764` / `768` / `76c` | cursor de la fila 0 / 1 / 2 / 3 |
| `0x14215b770` | cambia al confirmar (1/2) |

## Inventario (`0x14215ac00`)
- Armas: ids u16 desde `+0x00` (p. ej. 0x07, 0x18, 0x14, 0x0c, 0x21, 0x11, 0x12, 0x13, 0x15), cuántas en
  `+0x80` (u16), estado por entrada desde `+0x82`: 1 bloqueada, 2 disponible, **3 equipada**.
- Proyectiles: cuántos en `+0x188`, estados desde `+0x18a`. Ninpo: estados desde `+0x4a2`.
- Objetos (fila 3), mismo formato que las demás filas: ids u16 desde `0x14215af18` (0x08, 0x09, 0x4e, 0x74),
  cuántos en `0x14215af98` (`+0x80`), estados desde `0x14215af9a` (`+0x82`) y **cantidad de cada objeto desde
  `0x14215afda` (`+0xc2`)**. Comprobado: el selector mostraba 2 → 1 y `0x14215afda` pasó de 2 a 1 al usar el
  objeto 0x08, que curó 945 de 3150 (30 %) en el mismo frame que A. Otra lista en `0x14215b018…` (0x09, 0x08, 0x06, 0x52, 0x92, 0x53; cuántos en
  `0x14215b0a0`, estados desde `0x14215b0a2`); al usar una curación su orden cambió (último usado delante).
- Al abrir el selector (`0x1413d0f20`) las listas se reconstruyen y reordenan (lo equipado primero).

## Pendiente
- La función que aplica el objeto (curación y resta de la cantidad): poner un punto de vigilancia de escritura
  en `0x14215afda + índice` y usar otra curación.
- Dónde se aplica el arma elegida al personaje (el cambio de modelo/moveset tras A).

## Misiones en Equipo (mapeo 2026-10-05)
Objetivo: cambiar de arma, proyectil o ninpo dentro de la misión sin volver a la selección de personaje.

### Qué lo impide
- El controlador de pausa `0x1413b0cb0` solo atiende la cruceta si pasan varias comprobaciones (`0x1413b0d2f…`):
  `0x1435ffebc <= 0`, `0x14211e5f4 == 3`, `0x14211e5ff == 0`, **`0x14211e5cf != 1`**, **`0x14211e5cd != 1`**, y
  `+0x08` de la estructura (copia de `0x1421229c3`) a 0. En Misiones en Equipo **solo falla `0x14211e5cf = 1`**
  (byte de modo Misiones en Equipo; `0x14211e5cd = 1` es Carrera Ninja). El resto (`0x1413afe20`: actor del P1
  vivo, sin pausa ni evento, `0x142daabbe = 1`, `0x14211e76c = 0xffff`…) se cumple.
- Quitando ese salto (`0x1413b0d5c`, `0f 84 1b 02 00 00` → nop de 6 bytes) el selector se abre en la misión con el
  equipo elegido (arma nivel 4, arco, ninpo) y se puede navegar y cerrar con normalidad.

### De dónde salen las listas
- `0x1413d0f20` vacía las filas y llama a `0x1413f1f30(0x14215ac00, 1)`, que copia el **inventario 0**
  (`0x1435c3c94`, 128 entradas de 4 bytes: id u16, cantidad u8, u8) y clasifica cada id con la base de datos de
  objetos `[0x141e37af0]` (etiquetas `0x21` categoría, `0x24`, `0x26` objetos ligados). Equipado = id igual a
  `objeto+0x5ae6` del P1 (fila de armas). Inventarios: hasta 0xa0, de 0x340 bytes; el 0 es `0x1435c3c94`.
- En Misiones en Equipo el inventario solo tiene el equipo de la selección de personaje: p. ej. Ryu
  `0x7` (arma), `0x93` (arco), `0x6`, `0x94` (flechas), `0x5`, `0x153` (ninpo), `0x0`.
- Se vacía al entrar en la selección de personaje y se rellena al cargar la misión: `0x1415dd080` (preparación del
  jugador) recorre las 8 ranuras de equipo `objeto+0x5ae6` (arma, proyectil, …) → `0x1415d1ed0(entrada, ranura, id)`
  (escribe la ranura y añade los objetos ligados, p. ej. flechas del arco) → `0x1415d16f0(id, inventario)` (lo da si
  no lo tiene, cantidad inicial de la tabla por personaje `0x141828648`) → `0x141378d10(?, id, cantidad,
  inventario)` (sumar/restar objetos). Lo que se escriba en el inventario antes de cargar se pierde.

### Estado al 2026-10-05 (noche) — RESUMEN PARA RETOMAR

**Hecho y comprobado**
- Bloqueo: solo el byte `0x14211e5cf = 1` impide la cruceta en Misiones en Equipo (salto en `0x1413b0d5c`).
  Quitándolo, el selector se abre, navega y cierra bien.
- El selector cambia de verdad el equipo: `0x1413cfdf0` (aplicar) → `0x141630290(tipo, id)` (pide el cambio,
  `0x1415d1ed0` escribe `objeto+0x5ae6+ranura*2` y añade objetos ligados) y espera con `0x14162fe40` (encola
  recursos con `0x1415ebda0`/`0x1415eaf10` en el gestor `0x1421434b0`; 32 entradas de carga en `0x1421452ac`,
  stride `0x788`, estado 3 = cargada). Ambas usan el jugador `[0x14211e757]`.
- Ryu lleva y usa el arma nueva (modelo visible, golpes cuentan) con las 9 armas probadas.
- Tablas de la selección de personajes (columna del P1 en `0x14215b6a0`, sigue válida en la misión):
  `+0x00` personaje (0 = Ryu), `+0x06` fila, `+0x08` índice de arma, `+0x09` índice de proyectil,
  `+0x18` u16 armas desbloqueadas (bit i = entrada i de la lista), `+0x1a` proyectiles, ninpo en `0x14215b6bc+pj`.
  Ryu: armas `0x141803060` (u32 ×`[0x141803030]` = 11): `01 18 15 13 14 12 11 0c 21 07 cc`; en la partida de
  Santi máscara `0x07f6` (bloqueadas `0x01` y `0x13`). Proyectiles `0x93` (+flechas `0x94`) y `0x151` (+`0x152`).
  Ninpo `0x141803008`: `06 52 53 92`. Categorías en la base de objetos (etiqueta `0x21`, byte 1): 1 arma,
  2 proyectil, 3 ninpo, 6 objetos.
- Inventario de la misión: se rellena durante la carga con `0x1415d16f0(id, inventario)`; lo que se añade ahí
  sobrevive y aparece en el selector.

**El problema sin resolver: congelamiento**
- Tras cambiar a un equipo que no se eligió en la selección de personajes, el juego deja de dibujar a los pocos
  segundos (a veces en el primer cambio, a veces tras 5–6). Pasa **también sin el mod** (`NGS2Coop.dll` quitada) y
  **con o sin precarga** del inventario durante la carga. Las rondas buenas fueron suerte (no hay patrón fiable:
  ni P2 unido, ni enemigos congelados, ni compañero caído lo evitan de forma comprobada).
- Cambiar a un arma que sí cargó la misión (la del compañero, p. ej. `0xcc`) aguantó 60 s con combate: sigue
  siendo la pista más fuerte de que el problema es el arma no cargada desde el inicio.
- Estado del cuelgue: el bucle principal (hilo con `0x140b5c8b9` → `0x14146293d` → `0x1414622c0`) espera con
  límite de tiempo en `0x140c14990(0x146496ad0)` y vuelve a esperar mientras `[rbx+0x158]`; los hilos de trabajo
  (`0x1416de509`) y las fibras están ociosos; el gestor de carga tiene todo en estado 3. No se encontró qué espera.

**Herramientas nuevas**
- `ngs2lab.dll`: comando `stacks` (`echo stacks > plugin/lab_cmd.txt`) → pila real de cada hilo en `lab.log`
  (contexto con `GetThreadContext`, sirve aunque el hilo esté en otra fibra). Instalado.
- Rama `wip/quick-menu`: `src/coop/quickmenu.cpp` (desbloqueo solo con cruceta arriba en Misiones en Equipo +
  precarga del equipo desbloqueado de Ryu en `0x1415d16f0`). **No instalado**: el `NGS2Coop.dll` del juego es el
  anterior (copia en `~/Backups/ngs2-coop/pre-quickmenu-20261005/`).
- Scripts de laboratorio en `/tmp/ngs2coop/` (se pierden al reiniciar): `to_mission.sh` (menú nuevo de 9
  opciones), `pick.py ID`, `stress.sh`, `inject_on_load.py`. `freeze_enemies.py` y el cambio de arma a la vez
  parecían relacionados con cuelgues: no usarlo en estas pruebas.

**Falta (en orden)**
1. Encontrar qué espera el juego al congelarse: qué marca `[rbx+0x158]` en `0x1414627d3`/`0x1414622c0` y quién
   la limpia; comparar un cambio de arma en historia (que nunca cuelga) con uno en Misiones en Equipo.
2. Según eso: cargar de verdad los recursos del arma nueva antes de aplicarla, o precargar todas como hace la
   historia (buscar dónde decide la carga del capítulo qué armas cargar).
3. Con eso estable: instalar `quickmenu`, probar con la IA y con el P2 unido, y una misión completa.
4. Jugador 2: abrir el selector con su mando y para su actor (inventario e índices propios).
5. Volver a la menú principal con cuidado: con la partida nueva hay 9 opciones (MISIONES EN EQUIPO es la 5.ª);
   nunca pulsar A a ciegas (abrió "Cargar partida" una vez).

### 2026-10-09 — precarga de recursos durante la carga (no basta)
- El cambio de equipo en caliente (`0x14162fe40`) reinicia el lote de carga global `0x1421434b0` con
  `0x1413c1c40` (borra sus 255 peticiones), pide el arma con `0x1415ebda0(id)` (→ `0x1413c18f0(lote, 2, id)` y
  sus objetos ligados, atributo `0x26`) y `0x1415eaf10(id)`, y procesa con `0x1413c07b0(lote, 0xfffe, 1, 0, 0)`.
  Ese mismo lote lo usa la descarga por zona `0x1415d30f0`, de ahí la sospecha de choque con las oleadas.
- Prueba: el gancho de `0x1415d16f0` llama además `0x1415ebda0`/`0x1415eaf10` para las 17 piezas desbloqueadas
  durante la carga de la misión (sin reiniciar el lote). La misión carga bien, pero el juego **se congeló igual**
  en el 2.º cambio (`0x0c` → `0x21`, Acólito 01, compañero IA), ~30 s después, con las 32 entradas de carga en
  estado 3.
- Pilas en el cuelgue (`stacks`): el hilo principal espera la señal de frame `0x146496ad0` dentro de
  `0x1414622c0` (bucle `while [rbx+0x158]` en `0x14146291c`). La señal la da la actualización del juego
  `0x141463a30` (llamada desde `0x141464ce9`; pone `[0x146496b69] = 1` y avisa en `0x141463eb7`). Ningún hilo
  muestra `0x141463a30` en su pila: la actualización está parada en una fibra. Los hilos de trabajo
  (`0x1413abc20`, espera de 1000 ms) están ociosos.
- Siguiente: enumerar las fibras del planificador de trabajos y ver dónde está suspendida la de
  `0x141463a30`; o evitar la carga en caliente limitando el selector a lo que la misión ya cargó.
- 2ª prueba (misma noche): congelado tras el 2.º cambio (`0x07`→`0x0c`→`0x21`). La pila del hilo de actualización
  (región `0x58562000-0x58660000`, base `0x140ee91d9` → `0x140dac691` → `0x140c12d4d` → `0x1414626f2` →
  `0x141464ee3` → `0x141463fbf`) solo deja restos viejos por debajo; buscar el RSP guardado de la fibra no dio un
  resultado claro. `0x141463fbf` es el bucle de temporizadores de mando (`0x142235a80`, stride 0x28) que llama a
  una importación con el identificador `+0x08`. Pendiente: `gdb` con `thread apply all bt` para ver RSP reales.

### 2026-10-09 — recorrido de las 10 misiones de Acólito (DLL con precarga, compañero IA, bot peleando)
| Misión | Resultado | Armas (orden de cambios) |
|---|---|---|
| 1 | bien | 0x07 > 0x0c > 0x21 > 0x07 |
| 2 | congelado tras el 3.er cambio | 0x07 > 0x07 > 0x0c > 0x21 |
| 3 | congelado tras el 2.º | 0x07 > 0x0c > 0x21 |
| 4 | congelado tras el 2.º | 0x07 > 0x0c > 0x21 |
| 5 | congelado tras el 2.º | 0x07 > 0x07 > 0x18 |
| 6 | congelado tras el 1.º | 0x07 > ? |
| 7 | bien (la misión terminó) | 0x07 > 0x0c > 0x07 |
| 8 | congelado tras el 3.º | 0x07 > 0x0c > 0x07 > ? |
| 9 | bien | 0x07 > 0x0c > 0x07 > 0x21 > 0x21 |
| 10 | bien | 0x07 > 0x0c > 0x07 > 0x21 > 0x07 |
- 6 de 10 misiones se congelan con 3–4 cambios. No depende de un arma concreta: 0x21 congeló 4 veces pero aguantó
  >1 min en la 9; 0x0c y 0x18 también aparecen antes de un cuelgue. Parece una probabilidad por cambio.
- Nombres (orden de la etiqueta `0x25`, byte 5, = lista de Récords Ninja): 0x01 Espada del Dragón, 0x07 Báculo
  Lunar, 0x0c Garras del halcón, 0x21 Garra del Dragón y Colmillo del Tigre (objeto ligado 0x15a), 0x11 Kusari-gama,
  0x12 Guadaña del Eclipse, 0x13 Tonfa, 0xcc Cuchillas gemelas vigoorianas, 0x14 Colmillo de Enma.
- El selector en misión solo ofrece 3 armas (0x07, 0x0c, 0x21, más 0x18 en Acólito 05).
- Herramientas: `/tmp/ngs2coop/bot/sweep_qm.sh` (navegación con detección del cursor del menú principal en la
  captura y comprobación de pantalla 8 antes del 2.º A; el menú gira e ignora botones al principio y una vez abrió
  "Cargar partida"), `coop_bot.py` (bot de combate con modo dios), `itemdb.py` (etiquetas de la base de objetos).

### 2026-10-09 noche — CAUSA DEL CUELGUE ENCONTRADA
Herramientas: `ngs2lab.dll` ahora registra excepciones (manejador vectorizado → `EXC ...` en `lab.log`, con pila);
registros de Windows reales de cada hilo de Wine leyendo su marco de llamada al sistema (firma `cs = 0x33`).
1. El hilo de actualización (tid 552, pila base `0x140ee91d9`) recorre la tabla de tareas `0x142235a80`
   (stride 0x28: estado, contador, fibra, función) y salta a cada fibra con `SwitchToFiber` en `0x141463fb9`.
2. Tras un cambio de arma, la tarea `0x141419040` (fibra 11) lee datos del compañero (actor 4) mediante
   `0x14140a650` → `0x14140a450` (tabla de recursos por jugador `0x1435c3b80`, 0x340 por jugador) y
   `0x14140a1f0` lee un puntero relativo que vale 0 → **acceso a 0 en `0x14140a227`** (otras veces en
   `0x141405533`). La excepción mata el hilo de actualización (congelado: el hilo principal espera para siempre la
   señal de frame `0x146496ad0`) o el proceso entero (el juego se cierra).
3. El dato vacío es el **paquete del arma del compañero** (Báculo Lunar `0x07` + `0x05`, recursos `0xc4b`/`0xc43`),
   compartido con el arma con la que empezó el P1. El cambio de equipo lanza una tarea de carga
   (`0x1413ce590` → fibra → `0x1413c5de0` → bucle `0x1413c5fb0`) que, para hacer sitio al arma nueva, **descarga
   los paquetes que ocupan la zona de memoria de destino** (`[rdi-0x10, rdi-8)` frente a `r9..r8`) con
   `0x1413c2c70` = `0x1413c2950` (libera todos los objetos que usan el paquete, caller `0x1413c2c0e`) +
   `0x1413bbd10` (libera la memoria). Si esa zona contiene el paquete del compañero, se lo lleva aunque esté
   equipado. Depende de dónde caiga el arma nueva: por eso parece aleatorio, y por eso pasa también sin el mod.
4. Intentos: pedir lo equipado en el lote (`0x1415eaf10` envuelto) no cambia la descarga; saltarse solo
   `0x1413c2950` deja el paquete vivo pero su memoria se reutiliza → excepciones en el dibujo (`+0xa1c2b`,
   `+0xbc8c67`, hilo 424). Ambos desactivados/descartados.
5. Tabla de paquetes cargados: registros en `0x142153ca0`, stride 0x40, 0x180 entradas (`+0x00/+0x08` zona de
   memoria, `+0x10` descriptor (máscara `+0x14`), `+0x32` id de recurso, `+0x38` cargado). Volcado al empezar
   Acólito 03: `docs/research/quickmenu_packs_start_acolyte03.txt`.
**Arreglo pendiente:** que las armas seleccionables estén cargadas desde la carga de la misión (cambiar a un arma
ya cargada nunca cuelga), o reservar la zona del paquete del compañero para que el cargador no la elija.

### 2026-10-10 madrugada — ARREGLO
- La precarga de todas las armas no es posible: el espacio de paquetes de armas de la misión solo cabe el equipo
  elegido (`0x1413c07b0` devuelve 0 = no pudo cargar; 1 = todo cargado). El cambio carga el arma nueva en el
  hueco de la anterior; si el compañero eligió la misma pieza, el juego cargó un solo paquete para los dos y el
  cambio se lo quita al compañero.
- Arreglo (`change_hook`, en la llamada del selector `0x1413cfec1` → `0x141630290`): en Misiones en Equipo se
  rechaza un cambio que suelta una pieza (misma categoría: etiqueta `0x21` byte 1) que el otro jugador también
  lleva; se devuelve 1 sin llamar al juego y el selector se cierra sin cambios.
- Pruebas: equipo igual (los dos con 0x07) → 6 cambios rechazados, sin cuelgue. Compañero con 0xcc/0x151 →
  Acólito 03 (6 cambios), 05 (3, misión terminada), 06 (6) sin cuelgue; antes se colgaban casi siempre.
- Pendiente: avisar en pantalla cuando se rechaza; probar el resto de misiones y con el P2 humano; quitar los
  registros de diagnóstico (liberaciones) cuando esté estable.

### 2026-10-10 mediodía — cambios libres, niveles al máximo, solo Ryu (sin commit todavía)
Pedido de Santi tras probar el rechazo: poder cambiar siempre (también desde/hacia lo que lleva el compañero),
selector solo para Ryu (P1 y P2) y el equipo extra al nivel máximo, no al 1.

**Cómo carga el juego el equipo (visto en vivo con la tabla de paquetes `0x142153ca0`)**
- Descriptores `0x141e37a70` (0x60 × 0x20: +0 inicio, +8 fin, +0x10 tamaño, +0x14 máscara, +0x1c tipo). Cada
  ranura usa una clase (tabla `0x141914bb0`: ranura → índice; arma 47 `0x60400804`, proyectil 50 `0x60400808`,
  ninpo 53 `0x60400810`). Cada clase tiene dos zonas: `máscara|1` (CPU) y `máscara|2` (GPU). El P1 usa
  `0x604008xx` y el P2/compañero `0x604020xx` (índice + 17), con el mismo tamaño.
- `0x141630290` (cambio): quita la ranura (`0x1415d1b00`, libera el objeto del jugador por etiqueta), escribe el
  id, borra la marca «conservar» (+0x39) de todos los paquetes de la clase, encola el barrido `0x1413ce590`
  (descarga los paquetes sin marca y libera los objetos que los usan) y la carga `0x1413ce6f0`, que llena las
  zonas **desde su inicio** (sin mirar lo que haya). Siempre usa los descriptores del P1, también para el P2.
- Si los dos eligen lo mismo en la selección, el juego carga una sola copia en las zonas del P1 y las del
  compañero quedan vacías: soltar esa pieza descargaba la del compañero (el cuelgue). Elegir en partida la pieza
  del otro carga una copia propia.
- Intentos descartados: conservar los paquetes y cargar encima (la carga empieza en el inicio de la zona y pisa lo
  conservado → excepción al dibujar en `0x1413f6ffa`); mover el inicio de la zona detrás de lo conservado (copias
  duplicadas, zonas desbordadas sobre la vecina).

**Arreglo (`quickmenu.cpp`, ganchos en `0x1413cfec1` (aplicar), `0x1416304e7` (barrido) y `0x14163050d` (carga))**
- Cada clase tiene dueño: el P1 empieza en las zonas `0x604008xx`. Si al cambiar las zonas del que cambia
  contienen algo que el otro aún tiene equipado (un objeto suyo apunta a ellas, o la pieza soltada es suya y sus
  zonas de la clase están vacías: caso ninpo, que no tiene objeto), se le ceden tal cual y el que cambia pasa a las
  zonas del otro (vacías). Barrido y carga van siempre a las zonas del que cambia; las marcas que el juego borró en
  la clase del P1 se restauran. Se reinicia al cargar cada misión.
- Solo Ryu: la compuerta de la cruceta mira el personaje (byte 0 de la columna) del jugador `[0x14211e757]`:
  columna P1 `0x14215b6a0`, P2 `0x14215b6c0`.
- Niveles: nivel = min(byte 3 de la entrada del inventario + base, tope) (`0x14137a250`; etiqueta 0x24 de la
  base de objetos: +6 base, +7 tope). Las piezas que añade el mod llevan byte 3 = tope (casi todas → NIVEL 3;
  Báculo Lunar y Cuchillas vigoorianas tienen nivel fijo 4). Inventario por jugador `0x1435c3c94 + j*0x340`.

**Prueba (Acólito 01, mando virtual, compañero IA)**: los dos con el mismo equipo → 11 cambios de arma (incluidas
idas y vueltas a la del compañero), 4 de proyectil y 7 de ninpo, sin excepciones; zonas con un solo juego cada
una; 1 min de combate a 60 fps. Compañero Rachel → cambios en las zonas propias, las de Rachel intactas. Rachel
como P1 → el selector no se abre; START sigue funcionando. Sin probar: el P2 humano usando el selector.

### 2026-10-10 tarde — selector propio del P2 (sin commit)
- **El P2 cambia de equipo con su mando, a la vez que el P1**: cruceta arriba abre un panel del mod en su vista
  (`quickmenu.cpp` `p2_frame`, dibujo en `split.cpp` con las píldoras de texto de `overlay::render_text`), sin
  pausa: ↑↓ fila (arma/proyectil/ninpo), ←→ pieza, A equipar, B cerrar. Mientras está abierto, su mando no llega
  al juego. Solo con Ryu (columna `0x14215b6c0`). Nombres: categoría 10 de los textos; 0x14/0x15/0x18 no se
  distinguieron por el modelo (Colmillo de Enma / Cuchilla del Archidemonio / Verdadera Espada del Dragón,
  dudosos). Proyectiles: la categoría 2 incluye la munición (0x94, 0x152, 0x00: etiqueta 0x21 byte 2 = 4), fuera.
- **Aplicar el cambio para el P2**: `0x141630290` cede a la planificación de tareas a mitad (SwitchToFiber), así
  que corre en una tarea propia: tabla de 24 tareas `0x142235a80` (stride 0x28: +0 estado 1 = ejecutar, |8 =
  terminada; +4 frames de espera; +8 fibra), tarea actual `[0x1421ae54c]`, fibra principal `[0x142235e40]`; la
  ranura 23 no la usa el juego. La tarea pone `[0x14211e757] = 1` mientras llama al cambio y al cierre
  `0x14162fe40` (1 mientras carga).
- Arreglos para el P2: el cierre guardaba el recurso de la ranura en la tabla del P1 (`0x1416300c7`, ahora
  `0x1435c3b80 + jugador*0x340 + ranura*8`); su barrido/carga (`0x141630026/0x14163002e`) pasan por los mismos
  ganchos de zonas; la tarea 11 (`0x141419040`) lee la tabla del P2 cada frame y fallaba en `0x14140a6ae` con el
  paquete viejo ya liberado (el selector del juego lo evita porque pausa): se la detiene (espera 0x7fffffff) desde
  el barrido hasta el final del cambio (~0,4 s). Con el selector del P1 abierto, el cambio del P2 espera, y la
  compuerta del P1 no abre mientras corre el del P2.
- Prueba (Acólito 01, dos mandos virtuales, pantalla doble TV/laptop): P2 16 cambios (todas las armas, ambos
  proyectiles, 4 ninpo) exactos; 6 pares de cambios P1+P2 a la vez exactos; 0 excepciones; zonas con un solo
  juego cada una; 1 min de combate a 60 fps. Sin probar en vivo: P2 con otro personaje (la selección de personajes
  a dos desde la pausa mueve la columna del P1 con los dos mandos: fallo aparte, anotado).

### Pantalla del P2 (mismo día)
- Borrosa y con imagen fantasma: el **anti-aliasing temporal** del juego mezcla cada imagen con la anterior, que
  con la alternancia de cámaras es la del otro jugador; y la resolución estaba en 1280x720 (estirada a la ventana
  1920x1200). Opciones del juego cambiadas (guardadas en el perfil): Anti-aliasing **No**, Resolución **1920x1080**.
- La ventana del P2 se abre en cuanto se une (no al empezar la misión) y, fuera de las vistas divididas, muestra
  la imagen del juego (`split::set_joined`, `draw_mirror`).

### Pendiente (prueba real de Santi, 2026-10-10 14:15) — retomar aquí
1. **Bucle al cambiar el P2 en una segunda misión**: tras terminar una misión y empezar otra, el primer cambio de
   arma del P2 (0x18 → 0x14) dejó al cierre `0x14162fe40` creyendo que su proyectil (0x151) no estaba cargado:
   barrió y recargó la clase de proyectiles del P2 81 veces en 30 s (registro «player 2 change 0xffff -> 0xffff
   (slot 255) in pools 0x60402008»). La tarea del mod se rindió a los 30 s, soltó la tarea 11 y el juego cayó
   en `0x14140a227` (lectura de 0). Sin reproducir todavía.
2. **P1 con Momiji + P2 con Ryu**: al cambiar de arma el P2, el P1 se hundió en el suelo y el P2 salió volando;
   el juego se cayó. Sospecha: el reparto de zonas asume que el P1 es Ryu.
3. **El P2 sale volando al cambiar de arma** (también con los dos Ryu): sospecha, la tarea 11 detenida durante el
   cambio y luego soltada de golpe.
4. **Petición de Santi**: el P2 debe tener la misma ventana de selección que el juego (iconos, NIVEL), exclusiva
   suya, en lugar del panel de texto del mod.

### 2026-10-11 madrugada — arreglos 2 y 3
- **Volar / hundirse (2 y 3)**: la causa era detener la tarea 11 durante el cambio del P2: esa tarea hace las
  comprobaciones de suelo de los dos jugadores (medido: la altura del P2 subió de 5,2 a 15,3 mientras estaba
  detenida). Ya no se detiene. En su lugar, el único lector de la tabla de recursos por ranura, `0x14140a450`
  (llamado solo desde `0x14140a67e`, que admite un resultado nulo), devuelve 0 para el actor del P2
  (`[0x14219bf5d]` = actor en curso) mientras dura su cambio (`slot_res_hook`, `p2_res_guard`).
- Prueba: P1 Momiji + P2 Ryu, 9 cambios de arma del P2 con los dos caminando: alturas normales, 0 excepciones.
  Zonas: Momiji en `0x604008xx`, Ryu (P2) en `0x604020xx` (el reparto por jugador es correcto).
- La A que cierra el panel del P2 llegaba al juego como salto: los botones pulsados al cerrar se ocultan hasta
  soltarlos (`p2m.swallow`). Sin probar en vivo.
- Segunda misión (Acólito 02 tras «Seleccionar misión»), P2 con 0x93 al empezar: 6 cambios (arma, 0x151, ninpo,
  vuelta) sin bucle ni excepciones. **El bucle (1) sigue sin reproducir**: según el registro del 10-10, en esa
  misión el P2 eligió **0x18 y 0x151 en la pantalla de personajes**; el cierre dio el proyectil por no cargado,
  barrió su clase (liberando el 0x151 aún equipado) y recargó sin éxito. Siguiente paso: arrancar con el P2
  eligiendo 0x151 en la selección (`go.sh` del scratchpad con `P2TAPS="DOWN RIGHT"`) y cambiar su arma.
- **Ventana del juego para el P2 (4)**: la tarea del selector `0x1413d0c30` lee el mando del índice en el byte
  `0x14211e754` (`0x1413e6f90(ctx, índice)`, mandos `0x142235880 + i*0x38`) y aplica a `[0x14211e757]`, así que
  puede abrirse la ventana real manejada por el mando del P2. Así pausa el juego y se ve en las dos pantallas;
  que salga solo en la del P2 y sin pausa exige mucho más. **Preguntar a Santi qué prefiere.**
- Fallo aparte visto otra vez: al volver a la selección de personajes desde la pausa, el mando del P2 mueve la
  columna del P1.

### 2026-10-11 tarde — el P2 usa la ventana del juego, solo en su vista y sin pausa
Santi eligió la opción difícil: la misma ventana del juego (iconos, NIVEL), exclusiva del P2 y sin pausar.
Se descartó dibujarla con texturas propias (`05073.sprp` + `05074.bin`, 120 DDS en L8: hacía falta reconstruir
recortes y animaciones) y se reutiliza el selector del juego entero:
- **La ventana** es un único widget (`0x146839440`, vtable `0x141900960`; estado `+0x10`: 1 abierta, 3 cerrada;
  elementos cada `0x220`). Se dibuja en cada frame aunque esté cerrada (alfa 0) desde el bucle de interfaz,
  método 4 = `0x141556600` (entrada de vtable `0x141900980`). Animaciones `0x1415549c0(?, tipo)`: 1 cerrar,
  2 abrir, 3–7 deslizar/elegir.
- **Abrir** (como `0x1413b0200`): cursores `0x14215b760..76c` a 0, `[0x14215b750]=0`, `[0x14215b758]=2`,
  fila `[0x14215b754]=2` (armas; 0 ninpo, 1 proyectiles, 3 objetos, 4 = cerrado), preparación `0x1413d0f20`
  (filas en `0x14215ac00`, 0x108 por fila: ids u16, cuántos `+0x80`, estado `+0x82` (3 = equipado); animación
  de abrir) y bucle `0x1413d0c30`, que termina con la fila en 4. En el juego el bucle lo ejecuta la tarea 6
  (`0x1413f4a90`) cuando el tipo de pausa `[0x141e3a8bc]` vale 2 o 3; la pausa la pone aparte el controlador
  (`0x1413b13b0`, contador `0x141e3a8c2`). La B la gestiona el controlador (mando 0), no el bucle.
- **El mod** ejecuta preparación + bucle en su tarea 23, sin pasar por el controlador (nada se pausa). Mientras
  corre esa fibra (la importación `SwitchToFiber` `0x14179e240` está envuelta) el selector lee la ranura del P2
  (`[0x14211e754]`) con su mando real y aplica al jugador 2 (`[0x14211e757]=1`); fuera de ella la ranura del P2
  está en blanco (su personaje no se mueve) y todo vuelve a ser del P1. Una ranura libre en su lugar saca el
  aviso «Conecta un mando». B del P2 → fila 4. El dibujo del widget se omite en los frames de la vista del P1
  (`[0x142ff2778]==0`) mientras dura su turno.
- La preparación construye las filas con el **inventario 0** (`0x1413f1f30` copia `0x1435c3c94`) y marca lo
  equipado con el **objeto de la entrada 0** (`[0x143195300]+0x5ae6`): durante esa llamada (no cede el control)
  se cambian por el inventario y el objeto del P2.
- **Desenfoque**: objetivo `[0x142122974]` (1 entrar, 4 salir), actual `[0x142122970]` (0 nada), aviso
  `[0x14211e77b]`; procesador `0x141334670`. El bucle lo pide al empezar y al elegir; para el P2 se retiran
  las dos peticiones (si no, se desenfocan las dos vistas y se queda así).
- El cambio en sí pasa por `0x1413cfdf0` (cambio + cierre de carga `0x14162fe40`) dentro del bucle, con los
  arreglos de zonas y `p2_res_guard` de antes. Se eliminaron el panel de texto (split.cpp) y la tarea de cambio
  propia del P2.
- Pruebas (Acólito 01, pantalla dividida vertical en la TV): ventana solo en la vista del P2, sin desenfoque,
  el P1 se mueve mientras tanto; filas, B, A (arma/ninpo); el P1 no abre la suya mientras la del P2 está
  abierta; pausa del P1 con la del P2 abierta; «Volver a intentar» con la del P2 abierta (se cierra sola);
  cursor inicial en lo que lleva equipado cada uno; 60 cambios aleatorios P1/P2 seguidos (también la misma arma
  los dos) sin fallos (`stress.py`).
- Visto una vez y sin reproducir (con la versión que aún marcaba lo equipado del P1): tras un cambio del P2 de
  0x11 a 0x7 con el P1 también en 0x11, el registro avisó de que se liberaba el 0x11 del P1; poco después el
  selector del P1 quedó abierto sin pausa (controlador en 2/2, tarea 6 terminada) y la lógica parada.
- **Arreglado el fallo de columnas** (al llegar a la pantalla de personajes desde la pausa de una misión, el mando
  del P2 editaba la columna del P1): la pantalla edita la fila del cursor `0x14215b6a6` (columna × 5 + fila; las
  acciones pares van a la columna 0 y las impares a la 1, `0x1413edd30`) y el byte de columna `0x141e65458` solo
  fija sus límites (arriba/abajo `0x140bae4a0`/`0x140bae4d0`). `char_select_frame` ahora lleva el cursor a la fila
  del jugador en su columna (`point_char_screen`), recordando la fila de cada uno.
- **Bucle de la segunda misión (1)**: con el flujo nuevo no aparece. Acólito 02 tras «Seleccionar misión», el P2
  con 0xcc + 0x151 elegidos en la pantalla de personajes: 6 cambios del P2 (armas, 0x151 → 0x93) y 30 cambios
  aleatorios P1/P2 sin bucle ni excepciones.

### 2026-10-11 noche — los dos jugadores sin pausa y arreglos de la prueba real
Estado final del selector (detalle y pruebas en [CIERRE_COOP.md](CIERRE_COOP.md)):
- Cada jugador abre con la cruceta arriba la ventana del juego, solo en su vista y sin pausa (la misma sesión para
  P1 y P2, una a la vez; `frame()`, `selector_task`). La compuerta del controlador de pausa se quitó.
- Arma o proyectil que el compañero lleva equipado → cambio rechazado.
- Durante una sesión el mundo no se detiene (`install_stop_guard` en `0x1415da08a`) y una parada sobrante tras la
  sesión se levanta (`watch_world_stop`).
- El cierre del cambio solo comprueba la pieza cambiada (`finalize_request` / `finalize_process`).
- Con la ventana abierta el jugador sigue moviéndose y cubriéndose: el selector solo ve cruceta/A/B y sus variables
  de estado solo valen «abierto» dentro de su fibra (el juego quitaba el control al personaje).
