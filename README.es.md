# NGS2 Co-op

[English](README.md) · **Español**

**Versión 1.2** · [Nexus Mods](https://www.nexusmods.com/ninjagaidenmastercollection/mods/549) · [Tráiler (YouTube)](https://youtu.be/VQ-9o8vhL5I)

Mod de co-op local para **NINJA GAIDEN Σ2** (NINJA GAIDEN: Master Collection, Steam). En las Misiones en
Equipo un segundo jugador controla al compañero de la IA con su propio mando, y cada jugador tiene su propia
cámara: pantalla dividida en un monitor o un monitor por jugador.

Basado en [NM Plugins](https://github.com/nm004/ngs2-nm-plugin) de Nozomi Miyamori (cargador de plugins,
efectos de desmembramiento y correcciones). El README original se conserva en
[docs/NM_PLUGINS_README.md](docs/NM_PLUGINS_README.md).

## Funciones

- **El jugador 2 se une con BACK** desde cualquier mando conectado y controla al compañero de la Misión en
  Equipo (movimiento, ataques, saltos, ninpo: los controles del propio juego). BACK otra vez lo devuelve a la IA.
- **Mandos conectados en caliente:** funcionan; el mando que pulsa BACK pasa a ser el jugador 2.
- **Menús compartidos:** cualquier mando maneja los menús. En la pantalla de personajes cada jugador elige su
  columna. En el selector de misiones el jugador 2 tiene un **recuadro rojo dibujado por el propio juego**, cambia
  de página con LB/RB y el jugador 1 no puede avanzar hasta que el 2 elija (si no coinciden, se sortea).
- **Pantalla de personajes para dos:** los dos jugadores preparan su personaje a la vez, cada uno con su cursor
  siempre visible (azul el jugador 1, rojo el jugador 2). A marca al jugador como listo (B lo deshace): se
  enciende una banda de su color bajo su columna y la línea de ayuda dice quién está listo; con los dos listos
  empieza la misión.
- **Avisos en pantalla:** "pulsa BACK para unirte" al arrancar el juego; los nombres, cuando el jugador 2 está unido.
- **Pantalla dividida** mientras juega el jugador 2:
  - *Vertical* (lado a lado) u *horizontal* (arriba y abajo); las vistas nunca se mezclan.
  - *Un monitor por jugador*: el jugador 1 en el monitor del juego y el jugador 2 a pantalla completa en el otro.
  - Detección automática: dos monitores → uno por jugador; un monitor → pantalla dividida.
  - **L3 + R3** (pulsar los dos sticks) en cualquier mando cambia el modo; la elección se recuerda.
  - Cada jugador ve **su propio HUD** (retrato, vida, ki, ninpo), reducido en pantalla dividida.
  - El menú de pausa se ve a tamaño completo.
- **Selector rápido en Misiones en Equipo** (cruceta arriba, si el jugador lleva a Ryu): cambia de arma,
  proyectil o ninpo en plena misión, con todas las armas desbloqueadas a su nivel máximo. El jugador 1 tiene el
  selector del juego de siempre (pausa la partida); el jugador 2 tiene **la misma ventana, dibujada por el juego
  en su propia vista y sin pausar**.
- **Orbes repartidos en Misiones en Equipo**: los dos jugadores empiezan con los cinco ninpo llenos; la esencia va
  al jugador más cercano y absorberla con el ataque cargado toma como máximo lo que le falta al ataque (2, 1 en el
  primer nivel, ninguna con la carga completa); los orbes azules y rojos van al más cercano, nunca a quien se cubre.

Cada vista se dibuja a 30 fps (el juego alterna las dos cámaras en sus frames de 60 fps).

## Estado

- Co-op local y pantalla dividida: funcionan, probados en Linux (Proton) con una RTX 4060, incluida una partida
  de una hora en Misiones en Equipo con dos mandos físicos (un monitor por jugador) sin ningún cuelgue.
- Windows nativo (1.2): funciona, probado en Windows 11 con dos mandos (un jugador físico y mandos virtuales con
  ViGEmBus): unirse con BACK, menús compartidos, elección de misión y pantalla de personajes para dos, pantalla
  dividida (vertical y horizontal, con el HUD de cada jugador), selector rápido del jugador 2 y pausa; 60 fps y
  sin cierres. También un monitor por jugador (con dos monitores; antes cerraba el juego al entrar el jugador 2
  con el overlay de Steam activo). La 1.1 se cerraba allí en la primera pantalla y
  la pantalla dividida mostraba una sola vista; ver [docs/STATUS.md](docs/STATUS.md).
- Pendiente: la misma arma o proyectil para los dos en el selector rápido (de momento se rechaza, ver abajo);
  pantallas de fin de misión y de muerte en pantalla dividida.

## Instalación

Descarga el instalador de tu sistema desde la [última versión](../../releases/latest) (también en
[Nexus Mods](https://www.nexusmods.com/ninjagaidenmastercollection/mods/549)) y ábrelo. Busca el juego en
tus bibliotecas de Steam, copia el mod (con NM Plugins incluido) en la carpeta del juego y, en Linux, añade la
opción de lanzamiento que necesita Proton. Ábrelo otra vez para actualizar o desinstalar.

- **Windows:** `NGS2-Coop-1.2-Windows.exe`, doble clic.
- **Linux / Steam Deck (modo escritorio):** `NGS2-Coop-1.2-Linux`. Permite que se ejecute (clic derecho >
  Propiedades > «Permitir ejecutar como programa», o `chmod +x NGS2-Coop-1.2-Linux`) y dale doble clic. Si Steam
  está abierto, ofrece cerrarlo para que se guarde la opción de lanzamiento.

Si no encuentra el juego, el instalador pide su carpeta. Opciones para scripts:
`--install`, `--uninstall`, `--game-dir CARPETA`, `--yes`.

Instalación manual: copia NM Plugins ([docs/NM_PLUGINS_README.md](docs/NM_PLUGINS_README.md)) y `NGS2Coop.dll` en
la carpeta `plugin/` del juego y, en Linux, pon en las opciones de lanzamiento `WINEDLLOVERRIDES=dbghelp=n,b %command%`.
Para compilar los instaladores: `tools/make_installers.sh` en Linux (CMake + MinGW-w64 + g++), o
`tools/make_installers.ps1 -MinGW <bin de MinGW-w64> -Zig <zig.exe>` en Windows (Zig compila el de Linux); los dos
toman los archivos de NM Plugins de `dist/`.

## Controles y ajustes

| Acción | Botón |
|---|---|
| El jugador 2 se une / sale | BACK |
| Siguiente modo de pantalla dividida | L3 + R3 |
| Selector rápido (arma / proyectil / ninpo, solo Ryu, Misiones en Equipo; se puede seguir moviendo y cubriendo) | Cruceta arriba; B cierra |

Archivos en la carpeta `plugin/` del juego:

- `ngs2coop-split.txt`: primera línea `auto` (por defecto), `vertical`, `horizontal` o `dual`. Las líneas
  opcionales `ignore AnchoxAlto` descartan los monitores de ese tamaño, por ejemplo una tablet usada como
  pantalla virtual (`ignore 2960x1848`). En modo dual el jugador 2 va al monitor válido más cercano al del juego.
- Los avisos los dibuja el propio juego: en la línea de ayuda de la parte inferior de los menús (selector de
  misiones, configuración de personajes, modo de equipo) y, al arrancar, bajo el aviso de autoguardado.
  `ngs2coop-overlay.txt`: créalo para ver además la antigua capa flotante (depuración).
- `ngs2coop.log`: registro del mod.
- `ngs2coop-trace-loads.txt`: créalo para registrar liberaciones de equipo y peticiones de carga (depuración).

En el selector rápido no se puede elegir un arma o proyectil que el compañero lleve equipado en ese momento (las
dos copias compartirían un paquete y, al soltar una, se liberaban las dos).

En Linux con KDE, `tools/play.sh [SALIDA]` abre el juego sin bordes y a tamaño completo en esa salida (por defecto
`eDP-1`); con dos monitores la ventana del jugador 2 se abre en el otro.

## Documentación

- [docs/P2_CONTROL.md](docs/P2_CONTROL.md): cómo controla el jugador 2 al compañero y los menús.
- [docs/SPLITSCREEN.md](docs/SPLITSCREEN.md): pantalla dividida y HUD por jugador.
- [docs/MENUS.md](docs/MENUS.md): menús co-op, el recuadro rojo y el archivo `databin` del juego.
- [docs/QUICK_MENU.md](docs/QUICK_MENU.md): el selector rápido de los dos jugadores.
- [docs/CIERRE_COOP.md](docs/CIERRE_COOP.md): plan y estado del cierre del co-op en Misiones en Equipo.
- [docs/CAMERA_RESEARCH.md](docs/CAMERA_RESEARCH.md): las cámaras por jugador del motor.

## Licencia

Código fuente bajo CC0 (como el NM Plugins original). NINJA GAIDEN es una marca de KOEI TECMO; este proyecto
no está afiliado a ellos.
