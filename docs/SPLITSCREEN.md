# Pantalla dividida y dos monitores (2026-10-04)

Módulo `src/coop/split.cpp`. Activo mientras el jugador 2 está unido y en una Misión en Equipo.

## Cómo funciona
- **Cámara alterna:** el motor tiene una cámara por jugador (CAMERA_RESEARCH.md). En cada frame del juego,
  desde el gancho de mandos (hilo "Updating"), el mod alterna `[0x142ff2778]` (0 ↔ 1). Cada jugador se ve a
  30 fps. El juego sigue a 60. Orden medido de un frame: cámara → actualización del HUD (indicador 0, 1) →
  dibujo del HUD → mandos.
- **Escena sin HUD:** el juego dibuja la escena a 3840x2160, la compone en un objetivo final de 4K (1.ᵉʳ draw)
  y encima dibuja el HUD (resto de draws). Luego lo escala al backbuffer. El mod engancha el contexto D3D11
  (Draw*, OMSetRenderTargets, OMSetBlendState). Al 2.º draw del objetivo final copia la escena a `scene[v]` y
  desvía el HUD a `hud[v]`, una textura transparente. Fuerza el alfa como cobertura y conserva el alfa en las
  mezclas aditivas (si no, salen cuadros negros).
- **Qué cámara es cada frame (exacto):** la actualización llena el paquete de frame `[0x142ff2750]` (dos paquetes
  en `0x142ff20d0`, stride 0x360; ojo de la cámara elegida en +0x40) y el render dibuja el otro
  (`0x141440260`: paquete = índice xor 1). Al terminar cada frame de actualización el mod etiqueta el paquete
  con su vista y copia su ojo. Al empezar cada frame de render (primer OMSetRenderTargets tras Present) busca
  la etiqueta del paquete que se dibuja y comprueba el ojo bit a bit.
  - Antes se comparaba el ojo de render (`0x141e65c80+0x260`) con las cámaras. Falla en algunos escenarios
    (p. ej. Acólito 02 o el desierto): el render ajusta ese ojo o lo deja congelado con el de la misión
    anterior, y todas las imágenes iban a la misma vista. Se conserva solo como respaldo y para comparar.
- **HUD por jugador:** indicadores en `0x141ecbb20` (P1) y `0x141ecc9d0` (P2), +0x00 = entrada del jugador.
  El del P2 se actualiza siempre, pero está cerrado (`+0xe98 = 4`, escala `+0x230`, desplazamiento `+0x2c0`
  = (-16, 17)). El mod lo abre en la posición del P1 y engancha el dibujo del indicador `0x14153aa80`: en cada
  frame solo se dibuja el del jugador de esa cámara. Al salir se restaura.
  (Intercambiar punteros no sirve: las barras animadas acaban mostrando la media.)
- **Pausa:** byte `0x141e3a8c2 = 1`. Se dibujan las vistas sin HUD reducido y el menú a tamaño completo.

## Modos (L3 + R3 a la vez en cualquier mando los recorre; se guarda en `plugin/ngs2coop-split.txt`)
- `vertical`: lado a lado. `horizontal`: arriba/abajo. Cada vista es el centro de la imagen del juego recortado
  a su forma (mismo zoom, menos campo de visión). El HUD de cada jugador va al 59 % del tamaño original: su
  mitad de arriba pegada arriba y la de abajo pegada abajo, recortado a su vista.
- `dual`: el P1 en el monitor del juego y el P2 en una ventana sin bordes propia, en el otro monitor
  (cadena de intercambio del mismo dispositivo, sin robar el foco).
- `auto` (por defecto): `dual` si hay 2 monitores, si no `vertical`. Los monitores se reexaminan cada 2 s.
- Líneas `ignore AnchoxAlto` en el mismo archivo: monitores que no se usan (Wine llama a todos "Generic
  Non-PnP Monitor", así que se distinguen por tamaño, en píxeles del juego). El P2 va al monitor válido más
  cercano al del juego. Ejemplo: una tablet como pantalla virtual de KDE (2960x1848) se ignora con
  `ignore 2960x1848`.

## Pruebas (laptop, 2026-10-04)
- 60 fps con la pantalla dividida y con dos monitores, en la RTX 4060. 1 o 2 repeticiones de cámara cada 1200 frames.
- HUD: las barras cuadran con la vida real de cada jugador (P1 100 %, P2 10 %).
- Al salir el P2: vista 0, indicador del P2 cerrado (4), ventana oculta.
- Prueba real (2026-10-04, 7 misiones, dos monitores): el método antiguo falló en 4 de 7 misiones. Con el
  etiquetado, en Acólito 02: 0 frames sin etiqueta y 2 repeticiones en 1200.
- Fin de misión: el número de jugadores sigue en 2 unos 20 s de pantalla de resultados. Ahora la pantalla
  dividida exige además la pantalla de misión (`[0x1421544fa] = 74`).
- Ojo: si el juego arranca antes de que despierte el HDMI (dGPU), sale a 1024x768 y ~24 fps. Reiniciarlo.

## HUD de cada jugador (2026-10-11)
- El indicador del P2 se abre con la función del juego (`0x14153a850`, estado 1 y plantilla completa
  `0x141821480`) y se cierra con `0x14153a800`; solo cambiar el estado lo dejaba con la plantilla compacta del
  compañero (`0x141821670`, barra de vida fina).
- Caras: dos objetos (`0x141ed9340` P1 delante, `0x141ed9b00` P2 detrás, dibujo `0x141539600`). En los frames del P2
  intercambian todo menos su posición, así que el P2 ve su personaje delante y el tinte rojo de «caído» va con el
  personaje caído. El id de sprite de la cara es el personaje (Ryu 0, Momiji 2, Rachel 3).
- `tools/play.sh [SALIDA]`: el juego vuelve solo a su monitor si se pone a pantalla completa; el script lo deja sin
  bordes a tamaño completo en la salida pedida (cargando cada script de KWin con un nombre nuevo).

## Pendiente
- En algunos escenarios (Acólito 02) ~1 de cada 9 frames no pasa por la captura (≈27 fps por vista en vez de 30).
- Combate muy intenso: el juego repite o salta frames de lógica (3–16 % de cámaras repetidas en la prueba).
- Probarlo con dos mandos físicos y a ojo (parpadeo/efectos temporales a 30 fps por vista).
