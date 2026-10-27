# Cierre del co-op en Misiones en Equipo — lo que falta (2026-10-11)

Alcance: co-op local a dos jugadores **solo en Misiones en Equipo** (pantalla dividida / un monitor por jugador,
selector rápido para los dos).

Base: rama `wip/p1-nopause` (selector sin pausa para P1 y P2, indicador del P2 con la plantilla del juego,
caras intercambiadas en la vista del P2). Prueba real del 2026-10-11 21:00–22:33 (P1 en la laptop, P2 en la TV,
mandos físicos): registros en `~/Backups/ngs2-coop/play-20261011/logs` (fuera del repo).

## A. Cuelgues y bloqueos (prioridad máxima)

### A1. Arma compartida → objeto liberado → cuelgue — HECHO (2026-10-11)
- Visto 2 veces. El P1 cambió a 0x21, que ya llevaba el P2 (el paquete solo estaba cargado en las zonas del P2);
  cuando el P2 soltó 0x21, la descarga liberó también el objeto del P1 → cuelgue 35 s después en `0x1413961c8`
  (lectura de 0). Al revés con 0x12 (P2 cogió la del P1, el P1 la soltó) → cuelgue en `0x14140a227`.
- La lógica de «ceder zonas» (`sweep_hook`, `class_used_by`) no detecta este caso.
- Arreglo: el selector rechaza un arma o proyectil que el compañero lleva equipado en ese momento (`change_hook`
  devuelve «hecho» sin cambiar; registro «refused»). Los ninpo no se rechazan (no tienen objeto propio). La
  selección de personajes sí puede repetir piezas (el juego las carga por separado).

### A2. Bucle del Arco de perdición de demonio (0x151) — HECHO (2026-10-11)
- Si el P2 elige 0x151 en la pantalla de personajes, a veces un cambio de arma del P2 deja el cierre del cambio
  (`0x14162fe40`) creyendo que el proyectil no está cargado: barre y recarga la clase de proyectiles
  (`0x60402008`) sin fin («0xffff -> 0xffff»), liberando el 0x151 equipado. El P2 queda bloqueado.
- Salir de la misión desde la pausa lo corta sin daños. Forzar el fin del cierre lo corta pero el juego cae 5 s
  después (`0x14140a6ae`): no sirve como arreglo.
- Condición: el P1 con otro personaje (Rachel) y el P2 con Ryu + 0x151 (el P2 pasa a ser el actor 2/3). Con Ryu en
  el P1 no pasa.
- Causa: el cierre `0x14162fe40` vuelve a comprobar TODAS las piezas equipadas (pide sus recursos y procesa el lote
  con `0x1413c07b0`). Al 0x151 del P2 le faltan recursos auxiliares (0xd25, 0xd27, 0x127a, 0xd28, 0x1c57, 0xd29;
  en sus zonas solo están 0x1279, 0xd26, 0x368) que ninguna recarga trae (con Ryu en el P1 están en las zonas del
  P1) → «no cargado» → barre y recarga la clase de proyectiles cada frame.
- Arreglo: durante una sesión el cierre solo comprueba la pieza que se cambia (`finalize_request` anota la pieza en
  `0x14162ff64`; `finalize_process` en `0x14162ff80` da por buenas las demás). Probado: P1 Rachel + P2 Ryu/0x151,
  6 cambios del P2 (armas, 0x151↔0x93) sin bucle, el arco conserva su objeto, disparos sin excepciones; 40 cambios
  aleatorios con Ryu/Ryu sin regresiones. Registro de peticiones de carga opcional para diagnóstico: crear
  `plugin/ngs2coop-trace-loads.txt` antes de arrancar.

### A3. Juego congelado tras un cambio (byte `0x14211e753`) — HECHO (2026-10-11)
- Tras algunos cambios el juego deja `0x14211e753 = 1` («mundo detenido» del controlador de pausa); el índice de
  paquetes de frame `0x142ff2750` deja de alternar (`0x141446ee5`) y la imagen se congela / la pantalla
  dividida sale en franjas. Pausar y reanudar lo arregla (el controlador de pausa lo limpia).
- Causa: la actualización de equipo `0x1415da010` detiene el mundo (grupo de tareas 3 con `0x141468f00` y el
  byte) si el contador de pausa es > 0 o si `0x141e3a8c0` (+0x08 del controlador de pausa) vale 1; durante una
  sesión del selector ese +0x08 puede estar a 1 sin pausa. Deshacer la parada a mitad del cambio dejaba el arma
  nueva sin objeto (visto en pruebas).
- Arreglo: durante una sesión, la comprobación de `0x141e3a8c0` en `0x1415da08a` se salta (stub
  `install_stop_guard`): solo una pausa real detiene el mundo. Red de seguridad: si tras cerrar la sesión el byte
  sigue a 1 sin pausa 10 frames, se levanta como hace el controlador (`0x141468d90(3)`).
- Prueba: 80 cambios aleatorios P1/P2 sin paradas ni armas sin objeto.

## B. Visuales

### B1. Retícula de apuntado del P2 — HECHO (2026-10-24)
- La mira (círculo azul al apuntar con arco o proyectil, LT) es un módulo del HUD: instancia `0x141e92f40`, vtable
  `0x1418fd5d0` ([3] actualización `0x140c62590`, [4] dibujo `0x140c62870`), 0x130 bytes (sprite en +0x10 con su
  instancia en +0x100, +0x120 objeto de puntería, +0x12c jugador, +0x12d dibujar). Lista de módulos abiertos del HUD
  `0x146798170` ({índice, módulo}, cuenta `0x146798330`; actualiza `0x1415070e0`, dibuja `0x141506e00`); abrir
  `0x14150d470(índice)`, cerrar `0x14150d580`. El juego solo la abre (índice 2) cuando apunta el jugador local
  `[0x14211e757]` (objeto de puntería `[0x1435c3bc0 + jugador*0x340]`) y la actualización leía ese byte: la del P1
  salía en las dos vistas y el P2 nunca tenía.
- Arreglo (split.cpp): la actualización lee el jugador del módulo (+0x12c, `0x140c625b1`); el dibujo del módulo del
  P1 se salta los frames del P2; con la pantalla dividida el mod mete en la lista un segundo módulo (índice 0x4d)
  ligado al P2, con su propia instancia de sprite y dibujado solo en los frames del P2. Al salir el P2 se cierra y se
  quita. (Intercambiar el estado de un solo módulo colgó el juego: bucle en la lista de dibujo `0x141690170`.)
- Cortada y pequeña: el HUD reducido va en dos mitades (arriba / abajo) y la mira, en el centro, quedaba partida.
  Ahora el recuadro central del HUD (u 0,40–0,60, v 0,32–0,68) se dibuja al 100 % en el centro de cada vista, donde
  apunta la cámara.
- Probado: P1 apunta → solo en su vista, entera y centrada; P2 apunta → la suya en su vista; los dos → cada uno la
  suya; 90 ciclos alternos sin cuelgues; BACK quita y vuelve a poner la del P2.

### B2. Aviso de compañero caído — HECHO (2026-10-11)
- Cuando el P2 cae, en la vista del P1 se marca en rojo bien al P2. En la vista del P2 el marcador (punto rojo /
  icono que parpadea) señala al P1. Debe señalar siempre al personaje que está en el suelo, en las dos vistas.
- Causa: las caras de arriba son dos objetos (`0x141ed9340` P1 delante, `0x141ed9b00` P2 detrás); el tinte rojo
  y el parpadeo de «caído» van en el objeto del P2 (color por elemento en `+0xc0`…, banderas en `+0x7a8`), y la
  vista del P2 solo intercambiaba el id de sprite (la cara), así que el rojo quedaba en la cara del P1.
- Arreglo (split.cpp `swap_faces`): en los frames del P2 los dos objetos intercambian todo menos su posición
  (`+0x50`, `+0x160`, `+0x280`, `+0x790`). Probado con Rachel (P1) y Momiji (P2): el rojo marca a Momiji en las
  dos vistas (detrás en la del P1, delante en la del P2). El id de sprite de la cara es el personaje (Ryu 0,
  Momiji 2, Rachel 3).

### B3. Menores — en parte HECHO (2026-10-12)
- Estadística «eye disagreed» de la pantalla dividida a ~600/1200 en modo dual: solo diagnóstico (las
  etiquetas mandan), revisar o quitar.
- Al principio de la sesión el P2 entró y salió varias veces seguidas con BACK: ya hay 1 s mínimo entre cambios
  y los intervalos vistos (1,5–8 s) parecen pulsaciones reales; sin cambios.
- HECHO: `tools/play.sh [SALIDA]` abre el juego sin bordes a tamaño completo en la salida (laptop por defecto).

## C. Limpieza para el cierre — en parte HECHO (2026-10-12)
- HECHO: código muerto quitado (precarga, «mantener equipado», «no descargar paquetes»); registros de diagnóstico
  solo con `plugin/ngs2coop-trace-loads.txt`; compila sin avisos.
- HECHO: QUICK_MENU.md, SPLITSCREEN.md, README (EN/ES), STATUS.md con el estado final (versión 1.1, 2026-10-27).
- Unir la rama en `main` cuando todo esté probado (subir a GitHub solo con el visto bueno de Santi).

## Orden de trabajo
1. A3 (congelamiento) — sencillo y quita la mayoría de las molestias.
2. A1 (arma compartida) — evita los cuelgues vistos.
3. B1 (retícula) y B2 (compañero caído).
4. A2 (bucle del 0x151) — el más difícil.
5. B3 y C.
Cada arreglo se prueba en la TV con mandos virtuales (`go.sh`, `stress.py`) antes de pasar al siguiente.

## Segunda ronda (2026-10-12)
- **Moverse y cubrirse con la ventana abierta** (petición de Santi): el selector solo recibe cruceta, A y B; el
  personaje conserva sticks, gatillos, LB/RB (andar, guardia, cámara). Además las variables del selector
  (`0x14215b750/754/758`) solo valen «abierto» dentro de la fibra del selector: el código de juego las leía y le
  quitaba el control al personaje.
- **«Tirón» visual al cambiar de arma**: no era la lógica (los frames siguen a 16,6 ms) sino la pantalla dividida.
  Unos 0,7 s alrededor del cambio el juego pinta un efecto a pantalla completa (triángulo de 3 vértices) durante el
  HUD; el mod lo metía en la textura del HUD (franjas con otras imágenes). Ahora va a la copia de escena de esa
  vista (`before_draw`/`after_draw` en split.cpp), y el HUD empieza tras el triángulo de la escena.
- **Prueba por misiones** (`mtest.py`): 8 misiones de 4 páginas, P1 Rachel/Ayane/Momiji, P2 Ryu (actor 2 o 3),
  48 cambios del P2: peor hueco entre frames 31 ms, ninguno > 40 ms, sin paradas, sin bucles, armas con objeto.
  P1 solo (P2 fuera): ventana en su pantalla, cambio correcto.
- Traza de draws opcional: `plugin/ngs2coop-trace-draws.txt`.

## Tercera ronda (2026-10-12): misiones 08–10 con combate real
Prueba nueva (`ptest.py`, fuera del repo): enemigos activos, los dos jugadores andan, atacan y se cubren sin parar
mientras cambian de arma (el P1 solo si es Ryu: los demás personajes no tienen selector). Acólito 08–10 y Guerrero
08–10, P1 Ryu/Rachel/Ayane/Momiji, P2 Ryu. Con combate salieron tres fallos que con los enemigos congelados no se
veían:
- **Parada al cerrar la ventana**: las últimas cargas del cambio terminan unos frames después de cerrar y la
  actualización de equipo paraba el mundo (la red de seguridad lo levantaba: tirón de 0,2–0,3 s). Ahora la
  protección de la sesión sigue 2 s después de cerrar.
- **Objeto esperando su carga** (`0x141635130`): si el recurso del arma nueva no está, el juego para el mundo,
  espera a los cargadores y lo reanuda; desde una tarea de juego la parada la suspende también a ella y el mundo no
  se reanudaba (visto hasta 11 s). En una sesión (y 2 s después) esa parada y su reanudación se saltan
  (`load_stop_hook`/`load_resume_hook`); la red de seguridad además no levanta una parada mientras hay cargas en
  curso (`loads_busy`, máx. 5 s).
- **Arma sin etiqueta**: al terminar un cambio con el personaje atacando, el objeto del arma nueva se crea pero la
  ranura del jugador queda con etiqueta 0xff (`0x14137bce7`), y las comprobaciones de «arma en uso» (del mod y del
  juego) dejan de verla. Medio segundo después de la sesión, un arma o proyectil con etiqueta 0xff cuyo objeto
  existe para ese jugador recibe la etiqueta del objeto (`repair_slot_tags`).
- Resultado final (8 misiones, ~75 cambios de P1 y P2 en pelea): ninguna arma sin objeto, ninguna parada
  atascada, sin bucles; huecos de frame ≤ 30 ms salvo la animación del propio juego cuando cae un jugador.
- **Del juego, no del mod**: al caer un jugador el juego se detiene ~2,5 s (pergamino de «compañero caído»), y con
  el compañero caído START no abre la pausa. El arco de Momiji (0x14b) no tiene objeto propio.
- Traza opcional ampliada (`plugin/ngs2coop-trace-loads.txt`): quién para el mundo (`0x1415da0c0`) y quién
  detiene grupos de tareas (`0x141468f00`).

## Cuarta ronda (2026-10-12 noche): pendiente — partida real y peticiones nuevas
Partida real de Santi (19:10–21:11, ~40 misiones, P1 en la laptop, P2 en la TV) vigilada solo leyendo memoria.
Sin código nuevo todavía: la DLL instalada sigue siendo `26f27f1`.

### D1. Cierre al cambiar 0x21 → 0xc — PROTEGIDO, causa sin reproducir (2026-10-24)
- Visto 2 veces, idéntico: excepción en `exe+0xe4db31` (descompresor zlib, `inflate_fast`) escribiendo en
  `0xffffffffffffffff`: el destino de la descompresión es nulo. Hilo del cargador de recursos (pila `0x1413ad270`,
  `0x1413abd96`, `0x140b9ce07`). Mismos registros las dos veces (`rsi=0x143732def`, `r9=0x143734fe8`): mismo
  recurso.
- Las dos veces el P1 (Ryu) pasó de 0x21 (Garra del Dragón y Colmillo del Tigre) a 0xc (Garras del halcón),
  clase `0x60400804`. 1.º: cierre en el mismo instante del cambio. 2.º: 28 s después, sin cambio en curso y sin
  `repair_slot_tags` → la reparación de etiqueta no es la causa.
- (2026-10-12) Siguiente: reproducir con mandos virtuales (P1 Ryu, 0x21 → 0xc) y vigilar las zonas de `0x60400804`.
- 2026-10-24: el destino no es nulo sino `~0` («sin sitio»): zlib escribe en `destino − 1 + 1` → `r8 = -1`. Cadena:
  trabajo de carga (vtable `0x1418ef730`, ejecución `0x140b9d2a0`: `+0x10` destino, `+0x18` id de recurso) →
  `0x1413ad110(cargador, id, destino)` → lectura + `0x140b9cd10` (inflado en el destino). Los paquetes de clase toman
  el destino del inicio de la zona (`0x1413ce6f0`: `[desc]`, uno de los 32 cargadores `0x1421452ac`, `+0x728`).
- Zonas de armas fijas y holgadas (CPU `0x880800`, ~`0x228000` usados): no es desbordamiento.
- Protección (`quickmenu.cpp` `job_load_hook`, llamada `0x140b9d2d5`): un trabajo con destino `0` o `~0` se salta y
  se registra («load job for res … has no destination») con los 15 anteriores. Con
  `plugin/ngs2coop-trace-loads.txt` se registran todos los trabajos en misión.
- Pruebas en monitor virtual (sin TV): Acólito 01, P1 0xc → 0x21 → 0xc ×5 atacando 40 s tras cada cambio; luego
  `ptest.py` (enemigos activos, P1 y P2 cambiando al azar) en Acólito 01–05, 07, 08, 10 y Guerrero 01–03: 82 cambios
  (7 de 0x21 → 0xc), 852 trabajos de carga, 0 sin destino, 0 excepciones. No se reproduce.
- Las dos veces fue la misma misión (reintento) y el mismo recurso: puede ser un recurso de esa misión y no del arma.
  Siguiente: partida real con esta DLL; si salta la protección, el registro dice qué recurso era.

### D2. 5 ninpo llenos al empezar (petición de Santi) — HECHO (2026-10-24)
- Ninpo en el objeto del jugador: `+0x5ad8` máximo, `+0x5ada` actual; 200 por icono (Misiones en Equipo: 600/400).
- La carga de Misiones en Equipo `0x1415dd080` copia el ninpo de la misión (orden 0x87000004 del guion, o la tabla
  en la otra rama) a los globales `0x146aee358/35a`; `0x1415d9560` (llamada en `0x1415dd7db`, una vez por jugador)
  los pone en el objeto (`0x1415d9a90`).
- Plan: stub en la llamada de `0x1415dd7db` que, con `0x14211e5cf == 1`, ponga 1000/1000 en los globales antes de
  llamar a `0x1415d9560`.
- Bases doradas de los iconos: objeto `0x141ed6f20` (= HUD `0x141ecbb10 + 0xb410`), solo del P1, se construye una
  vez en `0x140cd0860` desde el máximo (subirlo después da iconos 4 y 5 sin base). Por eso el ninpo tiene que valer
  1000 antes del montaje del HUD `0x140cd0d00` (que va justo después de la carga).
- Hecho (`quickmenu.cpp` `ninpo_setup_hook`): en Misiones en Equipo la plantilla `0x146ae8880` (`r8` de la llamada)
  recibe 1000/1000 antes de `0x1415d9560`. Probado: P1 y P2 1000/1000, cinco iconos con base dorada en la vista del P1
  (la del P2 aún muestra los del P1: D3).

### D3. Los ninpo del P2 en su vista — HECHO (2026-10-24)
- Objetos de iconos: P1 `0x141ecdac0`, P2 `0x141ed24f0` (`+0x4a00` cuántos, `+0x4a10` actual, `+0x4a12` máximo,
  `+0x4a18` entrada del jugador, `+0x4a20` disposición: abierta `0x141821510`, cerrada `0x141821440`; `+0x4a28`
  estado). Los construye `0x141538a10(iconos, entrada, abierto)` desde el ninpo del jugador; el HUD (`0x140cd0ec5`)
  hace el del P1 abierto y el del P2 cerrado. Dibujo `0x1415387e0` desde `0x140cd16ae`, `0x140cd16bb` y el salto
  final `0x140cd16db`.
- Arreglo (split.cpp): con la pantalla dividida el del P2 se reconstruye abierto (misma disposición → mismo sitio) y
  se reabre si el juego lo cierra; las tres llamadas al dibujo pasan por un gancho que en cada vista dibuja solo los
  iconos de ese jugador. Al salir el P2 (BACK) se vuelve a cerrar.
- Probado: P2 con 400 → su vista 2 llenos y la del P1 5; P1 con 600 y P2 lleno → 3 y 5; BACK cierra, volver a
  entrar los reabre; sin reconstrucciones por fotograma.

### D4. Esencia y orbes para el P2 (petición de Santi) — HECHO (2026-10-24)
- Orbes en `0x1465cae90` (64 × 0x110; es el gestor: `+0x8800` lista activa, `+0x883c` marca de absorción por
  absorbente, `+0x8850` entrada del «absorbente 2»): `+0x00` tipo (0 azul/vida, 1 rojo/ki, 2 esencia), `+0x04`
  cantidad, `+0x0c` estado, `+0x50` posición, `+0xe4` destino, `+0xf4` pausado. Entrega `0x141492a10` →
  `0x14148b2e0(jugador, cantidad, tipo)`.
- Absorción con Y cargado (`0x141490d00`): quien absorbe se llevaba TODOS los orbes del suelo. Ahora (stub en
  `0x141491064`) se lleva solo los que tiene más cerca que el compañero (un compañero caído no cuenta) y como
  máximo lo que le falta al ataque: 2 al empezar, 1 en azul, 0 en rojo. El «absorbente 2» del escaneo es el primer
  personaje en movimiento de absorción (= el mismo jugador) y se trata igual. El nivel no está en memoria (no se
  encontró en el personaje ni en `.data`): se sigue por el movimiento (`0x140f8de90` absorbe, `0x141005d60`
  movimiento): azul a los 0,9 s, rojo al cambiar de movimiento (Ryu/Espada del Dragón `0x44d` → `0x450` → `0x452`)
  o a los 1,7 s; cada orbe tomado sube un nivel.
- Fin de oleada (`0x141491b90`): elegía al más lejano (`seta` en `0x141491d37`, la actualización `0x141493076`
  compara al revés) → `setb`. Sin probar en vivo (no hubo fin de oleada en las pruebas).
- Orbes azules/rojos (`0x141492d00`): en Misiones en Equipo solo podía recogerlos el jugador de `0x14211e757` (P1).
  Stub en `0x141492edc`: los dos pueden (radio 10, el más cercano, como ya hacía el juego); con RT pulsado no recoge
  nada, y si el más cercano está en guardia el orbe espera hasta que la suelte.
- Probado con la descarga de prueba del mod (`plugin/ngs2coop-orbs.txt` = «tipo cantidad valor jugador dx dz», solo
  con diagnóstico): 3 orbes al empezar → 2 tomados; en azul → 1; en rojo → 0; P2 encima y P1 absorbe → se quedan, P2
  absorbe → 2; azul con P2 más cerca → P2, con P1 más cerca → P1, P2 en guardia → espera y va al P2 al soltar.
- Pendiente en partida real: fin de oleada, otras armas/personajes (los tiempos de azul/rojo pueden variar), orbes
  rojos.

### D5. Menores vistos en la partida — HECHO salvo los tirones (2026-10-24)
- HECHO: rechazo de arma que lleva el compañero → aviso en el pergamino de pistas del juego («Jugador N: tu compañero
  ya lleva esa arma, elige otra.», 4 s). gametext::banner: `0x1414d9bd0(0x12001f, 0)` (el id de «Tu compañero cayó»,
  idioma 5, cuyo texto sirve el gancho de textos solo para esa llamada), se cierra con `0x1414d9ba0` si sigue siendo
  el nuestro (`[0x141e8c888]`). Prueba con diagnóstico: `plugin/ngs2coop-banner.txt`.
- HECHO: al revivir (mantener/pulsar B junto al caído) el juego devuelve la vida hasta la recuperable `+0x5ab8`
  (tras una paliza, casi nada). El mod sube a la mitad del máximo a quien pasa de 0 a algo de vida.
- Explicado: las misiones que terminaban al caer el P2 con el P1 en pie. Del juego: un jugador caído al que los
  enemigos siguen golpeando muere y la misión se pierde (probado: con enemigos encima terminó a los 26 s; sin
  enemigos, 45 s caído sin terminar). Pasaba seguido por la cadena caer → revivir con poca vida → caer, ya arreglada.
- Sin cambios: dos tirones de ~0,9 s sin evento del mod (19:12:30, 19:25:34).
- Notas completas, registro de orbes y registros de los cierres (fuera del repo):
  `~/Backups/ngs2-coop/play-20261012-night/`.

## Quinta ronda (2026-10-26): partida real de 1 h grabada — todo bien; tres peticiones
Partida de Santi con dos mandos (laptop + TV, grabada en OBS): sin cuelgues, sin volcados, sin el cierre
`0x21 -> 0xc`. Peticiones:
- **E1. Misma arma para los dos.** Hoy el selector rechaza un arma o proyectil que lleva el compañero (A1). Santi
  quiere que los dos puedan llevar la misma. Hace falta que soltar el arma de un jugador no descargue el paquete
  mientras el otro la lleva (cuenta de usos por clase en la descarga), y quitar el rechazo.
- **E2. Selección de personajes simultánea.** Si el P1 está eligiendo equipo y el P2 toca su mando, el juego pasa
  a la columna del P2 y el P1 pierde la suya (el juego solo edita una columna a la vez; el mod alterna). Que los
  dos puedan editar a la vez sin quitarse el turno.
- **E3. Cuadros de «listo» (azul/rojo) poco visibles.** Hoy son los fondos de la fila de traje a escala 0.42 x 0.6
  abajo a la derecha, al 25 % hasta que el jugador está listo. Hacerlos claros: grandes, bajo la columna de cada
  jugador, con «LISTO» visible.
Orden: E3 → E2 → E1.
- E3 HECHO (2026-10-26): banda del color del jugador a todo lo ancho bajo su columna (fondo de fila 0x9d/0x9c,
  escala y 0.65, y = 548, dos capas) cuando está listo; barra gris tenue si no. La línea de ayuda dice
  «P1 nombre: LISTO / eligiendo - P2 nombre: …».
- E2 HECHO (2026-10-26): las pulsaciones del jugador al que el juego no atiende en ese frame esperan a su turno
  (`CharSelect::pend`) en vez de perderse; la columna que el juego no edita muestra el cursor de su jugador
  (flechas de su fila en su color, por posición: el id del sprite cambia con la animación). Probado con mandos
  virtuales: P1 mantiene derecha mientras P2 baja/sube filas, los dos cambios llegan.
- E1 EN CURSO (2026-10-26 noche). Reproducido el cuelgue de A1 con el rechazo quitado (`plugin/ngs2coop-allow-shared.txt`,
  código en `git stash`): P1 y P2 con 0x7 (compartida desde el inicio en las zonas del P1); P1 → 0xc (cede, va a
  las zonas del P2); P2 → 0xc: el juego reutiliza el paquete principal de 0xc del P1 (zonas B) pero carga los
  recursos de ranura del P2 (`0x1435c3b80 + 0x340·jugador`, p. ej. res 0x359) en sus propias zonas A → equipo
  partido entre A y B. P1 → 0x7: cede de nuevo (ve el paquete del P2 en B) y barre A, donde estaban los recursos
  de ranura del P2 → lectura de 0 en `0x14140a227`.
  Intentos descartados: (1) marcar como no cargados (+0x38 = 0) los paquetes del otro jugador durante el cambio:
  el cargador trata el registro como libre y lo reutiliza (arma del otro sin datos); (2) cambiar su id de recurso
  (+0x32): el P2 sí recibe una copia completa propia, pero al descargar un paquete el juego busca por id los
  objetos que lo usan y cae en `0x1413c2b1e` (lectura de 0x21).
  Idea siguiente: que el jugador que elige el arma del compañero «se una» a las zonas del compañero (las dos
  copias en un mismo juego de zonas, como al empezar la misión, donde el traspaso ya funciona): barrer solo sus
  zonas viejas y cargar en las del compañero, donde ya está todo; y decidir el traspaso mirando también los
  recursos de ranura, no solo el paquete principal de los objetos.
