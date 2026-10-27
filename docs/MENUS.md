# Menús co-op y archivos del juego (2026-10-05)

## Avisos dentro del juego (sin capa flotante)
- Función de textos del juego `0x1416374f0(idioma, id)` (idioma 5 = español; `id = categoría << 16 | índice`),
  llamada desde ~400 sitios. `src/coop/gametext.cpp` la engancha (trampolín de 15 bytes).
- Líneas de ayuda de los menús: `0x880005` selector de misiones ("Elige la misión que quieres intentar."),
  `0x890008` configuración de personajes ("Por favor elige a un personaje."), `0x890001` modo de equipo. La de
  personajes se pide una sola vez al entrar y el juego guarda el puntero: por eso el mod devuelve siempre un búfer
  propio por línea y lo reescribe en el sitio (`gametext::tick()` en el bucle del mod); el juego dibuja en cada
  frame lo que contenga. Sin aviso del mod, el búfer lleva el texto original.
- Avisos: `gametext::message(texto, ms)` (4 s; unirse/salir, elección de misión, sorteo) y `gametext::line()`
  (fijo: página/estado del P2 en misiones; "P1 … (azul) - P2 … (rojo) - Ⓐ Listo" en personajes; "Jugador 2:
  pulsa BACK para unirte" en los menús con dos mandos y sin P2). Las etiquetas `@[pad:Decide]` funcionan.
- Al arrancar: `0x8007a` (aviso de autoguardado) lleva una línea más: "Co-op: el jugador 2 puede unirse pulsando
  BACK en su mando." hasta que el P2 se une o pasa minuto y medio.
- Dentro de la misión no hay línea de ayuda: los avisos de unirse/salir solo van al registro. Pendiente: el
  sistema de banners (categoría 9 del paquete LANG, p. ej. 9/31 "¡Tu compañero cayó!") no pasa por
  `0x1416374f0` al mostrarse; buscar su función para avisos en misión.
- La capa flotante (`overlay.cpp`) solo recibe texto si existe `plugin/ngs2coop-overlay.txt`; su gancho de
  Present se instala siempre porque también mueve la pantalla dividida.

## Selector de misiones (pantalla 6)
- Páginas (LB/RB): byte `0x14215b810` (0 Acólito, 1 Guerrero, 2 Mentor, 3 Maestro Ninja); 5 misiones por fila,
  2 filas en las dos primeras y 1 en las otras dos. Cursor del juego: `0x141e654c0` columna, `0x141e654c4` fila
  (estructura de rejilla en `0x141e654b0`, controlador genérico con métodos virtuales, `0x1413e67xx`).
- El P2 tiene su propia elección: cruceta dentro de la página, LB/RB para cambiar de página, A confirma y
  B deshace. El A del P1 no llega al juego hasta que el P2 ha confirmado (B del P1 deshace su elección). Con los
  dos listos: misma misión → adelante; distintas → sorteo; si gana el P2, el mod lleva el cursor del juego a su
  misión (LB/RB y cruceta inyectados) y pulsa A.

## Recuadro rojo del P2, dibujado por el juego
- Los menús construyen en cada frame una **lista enlazada de sprites** en uno de dos búferes (uno por frame;
  el render dibuja el otro): `0x142ee8000` y `0x142f19000`. Entrada de 0x80 bytes: `+0x08` siguiente,
  `+0x10` tipo (0x0a = sprite), `+0x18` id de sprite, `+0x30` escala, `+0x40` x/y (unidades 1280x720),
  `+0x50` color RGBA. El render las dibuja desde `0x1416840aa` (callback `0x140dcbff0`).
- El recuadro del cursor son 2 capas (marco y brillo; id 0x53 + página) en x = 531 + 126·col, y = 241 + 76·fila.
- El mod (hilo de actualización, gancho de mandos) copia esas entradas, las mueve a la casilla del P2, pone el
  color en rojo (1, 0.12, 0.12) y las enlaza justo después de las originales. El motor las dibuja con su propio
  sprite y animación. Se comprobó que el render respeta el color de la entrada.

## Archivos del juego (`databin`)
- `databin/databin` (4 GB): cabecera de 0x20 bytes; sección de tabla en 0x20 (`+0x00` número de entradas = 7698,
  punteros u32 relativos a 0x20 en `+0x10`); entrada de 24 bytes: posición i64 (relativa a 0x20 + tamaño de
  sección = 0x441e0), tamaño descomprimido, tamaño comprimido, u32, u16, u8, u8 tipo. Un bloque zlib por entrada.
- `tools/databin_tool.py list|extract DIR [índices]` extrae (8,8 GB descomprimidos). Tipos: `TMC` (modelos),
  `sprp` (sprpack: TTDM, texinfo, spripack de sprites, anmpack), `TDP4…` (texturas), `LANG`, `XWSF`…
- Para sustituir un archivo del juego no hace falta reconstruir el databin: el cargador NM Plugins carga
  `mods/NNNNN.dat` (descomprimido) en lugar de la entrada N.
