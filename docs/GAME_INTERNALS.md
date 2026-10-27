# NINJA GAIDEN Σ2 (Master Collection, Steam) — mapa del juego

Referencia de todo lo descifrado (2026-09 a 2026-10). Ejecutable `NINJA GAIDEN SIGMA2.exe`, base de imagen
`0x140000000` (sin ASLR observado), x64, D3D11 (DXVK en Proton). Todas las direcciones son absolutas con esa
base; en el código del mod se usan como RVA (`dirección − 0x140000000`). Detalle de cada tema en el documento
enlazado.

## Hilos
| Hilo | Qué hace |
|---|---|
| `Updating` | Lógica del juego por frame (60 Hz): mandos, actores, IA, cámara, construcción de la interfaz y del HUD, sonido 3D. |
| `Rendering` | Dibuja el frame que preparó la actualización (doble búfer de paquetes de frame) y llama a `Present`. |
| (Wine) | XInput, audio XAudio2 (`xaudio2_7.dll`). |

Orden dentro de un frame de actualización (medido): elección de cámara → actualización del HUD (indicador 0, 1)
→ dibujo del HUD → bucle de interfaz (`0x141508520`) → mandos (`0x141466030`).

## Bucle principal y menús
| Qué | Dirección | Notas |
|---|---|---|
| Pantalla de menú | byte `0x1421544fa` | 0 título/menú principal/carga · 8 modo · 20/13/2 transiciones · 6 selector de misiones · 5 personajes (y pausa) · 4 pausa · 74 en misión · 3/63/8 resultados |
| Pausa | byte `0x141e3a8c2` | 1 con el menú de pausa abierto |
| Jugadores | byte `0x14211e5cc` | 2 en Misiones en Equipo (sigue en 2 ~20 s de resultados), 1 en el resto |
| Bucle de interfaz | `0x141508520` | llama al método 4 de cada pantalla activa; al terminar (`0x141508539`) las listas de sprites del frame están completas (gancho del mod) |
| Selector de misiones | página `0x14215b810`, cursor `0x141e654c0`/`0x141e654c4` | ver [MENUS.md](MENUS.md) |
| Selector de personajes | columna activa `0x141e65458` (= `+8` del objeto de pantalla `0x141e65450`); cursor de fila `0x14215b6a6` = columna × 5 + fila (lo que se edita de verdad); estado por columna `0x14215b6a0` / `0x14215b6c0` (0x20 bytes) | la columna sola solo fija los límites del cursor: hay que mover también el cursor |

## Interfaz: listas de sprites
Los menús y el HUD 2D construyen cada frame una **lista enlazada de sprites** en uno de dos búferes
(`0x142ee8000`, `0x142f19000`; el render dibuja el otro). Entrada de 0x80 bytes: `+0x08` siguiente, `+0x10`
tipo (0x0a sprite), `+0x18` id de sprite, `+0x1a` paquete (0x9f personajes, 0xb6/0xb7 misiones, 0x0b
botones…), `+0x30` escala x/y, `+0x40` posición x/y (1280x720), `+0x50` color RGBA. El render recorre
`0x1416840aa` → `0x140dcbff0`. Añadir, mover o teñir entradas es la forma de dibujar **con los recursos del
juego** (recuadro rojo del P2, recuadros de listo).

## Jugadores, actores y control
| Qué | Dirección | Notas |
|---|---|---|
| Tabla de objetos | `0x143195300`, 160 × 0x30 | `+0x00` puntero al objeto, `+0x18` tipo, `+0x1a` 0xff = libre/cadáver liberado, `+0x1d` índice, `+0x1e` padre, `+0x1f` grupo |
| Tabla de personajes | `0x142f78b10`, stride 0x1240 | `+0x00` **puerto de mando** (0–3; 4 = IA), `+0x04` estado, `+0x12` acción, `+0x16` movimiento anterior, `+0x30` dirección, `+0x80` orientación 4x4, `+0x1199` muerte procesada |
| Jugador → actor | `0x14211e760` (2 bytes) | Misión en Equipo: `[0, 4]` |
| Jugador → ranura de mando | `0x14211e754` (2 bytes) | el P2 usa `0x14211e755` |
| Ranuras de mando | `0x142235880 + k·0x38` | `+0x00` pulsado, `+0x08` nuevo, `+0x10/+0x14` repetición, `+0x0e` conectado, `+0x18/+0x1c` stick izquierdo |
| Actualización de mandos | `0x141466030` | gancho del mod (menús compartidos, intercambio de ranuras, selectores) |
| Objeto | `+0x4b80` posición, `+0x5ab4` vida máx., `+0x5ab6` vida, `+0x5ac8` vida por partes, `+0x5b30` movimiento, `+0x4bcc` frame del movimiento | |
| Daño | `0x14148def0(objetivo, atacante, parte, factor)` | |
| Muerte | `0x140f34740` | comprueba vida 0, marca `char+0x1199`, da Karma (`0x141636af0`); Karma total `0x141ea00a8` |
| Poner movimiento | `0x140f89f20(entrada, id)` | anima de verdad (escribir el id no basta) |
Botones: ARRIBA 0x1, ABAJO 0x2, IZQ 0x4, DER 0x8, A 0x10, B 0x20, X 0x40, Y 0x80, BACK 0x200, L3 0x400,
R3 0x800, LB 0x1000, RB 0x2000. Más en [P2_CONTROL.md](P2_CONTROL.md).

## Cámaras
| Qué | Dirección | Notas |
|---|---|---|
| Gestor | `[0x142ff2758]` = `0x142fe5f10`, 8 ranuras × 0x16a0 | `+0x80` ojo, `+0x90` objetivo, `+0x1c0` vista, `+0x200` proyección, `+0x15b0` activa |
| Vista que se dibuja | int `0x142ff2778` | 0 = P1, 1 = P2 |
| Globales de la cámara del frame | `0x142ff1940` (+0x10 ojo, +0x20 objetivo, +0x30 arriba) | ~215 lecturas; el sonido 3D lee 14 de ellas (`0x1414b3000..0x1414d1000`) |
| Paquetes de frame | `0x142ff20d0`, 2 × 0x360, índice `0x142ff2750` | el render dibuja el índice xor 1; ojo en `+0x40` |
| Cámara del render | `0x141e65c80` (+0x260 ojo) | se ajusta o se queda congelada en algunos escenarios: no sirve para saber la vista |
Detalle en [CAMERA_RESEARCH.md](CAMERA_RESEARCH.md) y [SPLITSCREEN.md](SPLITSCREEN.md).

## HUD
- Indicadores de jugador (retrato, vida, ki, ninpo): `0x141ecbb20` (P1) y `0x141ecc9d0` (P2), `+0x00` entrada
  del jugador, `+0xe98` estado (1 abierto, 4 cerrado), `+0x230` escala, `+0x2c0` desplazamiento; dibujo
  `0x14153aa80`; el HUD está en `0x141ecbb10` (`0x140cd1540` dibuja ambos).
- El HUD se dibuja sobre la escena en el objetivo final de 4K (3840x2160); algunos avisos (compañero caído,
  jefes) dibujan primero una forma solo en alfa y luego pintan a través de ella.

## Textos
`LANG` (entrada 8 = español, 2533 cadenas, UTF-16LE): CTGPACK de 19 categorías → STRPACK con tabla de
cadenas. Marcas: `@[color:…]`, `@[pad:ActJump]` (icono de botón), `@[arg:1]`. Categoría 9 = avisos tipo
banner (9/31 "¡Tu compañero cayó!…"). Volcado: `tools/lang_dump.py` → `docs/research/game/lang_es.tsv`.

## Archivos (`databin`)
Formato y extracción en [MENUS.md](MENUS.md) (`tools/databin_tool.py`). 7698 entradas zlib; tipos:
`TMC` modelos (MdlGeo/ObjGeo), `chr_` datos de personaje, `sprp` sprites de interfaz (spripack + anmpack +
TTDM), `TDP4`/`tdpa` y "bin" con marca `0x01234567` en +8 → texturas, `XWSF` sonido (450 MB), `STAG`
escenarios, `rtm_` luces, `itm_` objetos, `LANG` textos; tipos 28–30 = rutas a vídeos y sonido externo.
Sustituir la entrada N: `mods/NNNNN.dat` (cargador NM Plugins).

## Sonido
XAudio2 2.7. El código de sonido 3D (atenuación, paneo, oyente) lee la cámara del frame en `0x142ff1940`; en
pantalla dividida el mod lo apunta a una copia que solo sigue la cámara del P1 (si no, el sonido se
entrecorta al alternar cámaras cada frame).

## Guardado
`Documents/KoeiTecmo/NINJAGAIDENSIGMA2/<steamid>/`: `STORYSAV` (historia), `CHAPSSAVE` (capítulos),
`SYSTEMSAVE` (progreso global, misiones), `USER_SETTING/WINSTATE.DAT`.

## Selector rápido (cruceta) e inventario
Controlador de pausa `0x1413b0cb0` (estructura `0x141e3a8b8`): arriba → `0x1413b0200` (fila armas), abajo →
`0x1413b0140` (fila objetos); tarea del menú `0x1413d0c30`. Variables en `0x14215b750…`, inventario por filas en
`0x14215ac00` (armas), proyectiles, ninpo y objetos (`0x14215af18`, cantidades en `+0xc2`). Detalle en
[QUICK_MENU.md](QUICK_MENU.md).

## Pendiente de descifrar
- Función que muestra los avisos tipo banner (categoría 9) con un id: permitiría avisos propios con el estilo
  del juego (el mod ya puede escribir cadenas en un LANG modificado).
