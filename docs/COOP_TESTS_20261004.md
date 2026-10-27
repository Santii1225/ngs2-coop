# Pruebas reales de co-op local (2026-10-04)

Dos sesiones de juego real con dos mandos físicos. Distribución: el P1 en la pantalla de la laptop, el P2 en la
TV de la izquierda (modo un monitor por jugador) y una tablet como 3.ª pantalla virtual, ignorada por el mod
(`ignore 2960x1848` en `ngs2coop-split.txt`). Vigilancia con `tools/coop_monitor.py`, solo lectura.

## Sesión 1 (7 misiones, ~30 min), versión anterior del mod
- Lo que funcionó: unión del P2 en cada misión, elección doble de misión (4 sorteos), modo dos monitores,
  pausa a tamaño completo, 60 fps estables, GPU holgada (media 52 %, máx. 54 °C), memoria estable (~1,6 GB).
- **Fallo 1: cámaras mezcladas en 4 de 7 misiones.** El ojo de render (`0x141e65c80+0x260`) en algunos escenarios
  (Acólito 02, el del desierto) está ajustado o se queda congelado con el de la misión anterior → todas las
  imágenes iban a la misma vista: una pantalla parpadeaba y la otra se quedaba congelada.
  **Arreglado (a959001):** etiquetas por paquete de frame (ver SPLITSCREEN.md).
- **Fallo 2: ~20 s de pantalla dividida sobre los resultados.** El número de jugadores sigue en 2 al terminar la
  misión. **Arreglado:** además se exige la pantalla 74 (en misión).
- Microtirones en combate intenso: 3–16 % de cámaras repetidas (el juego repite o salta frames de lógica).
- CPU: media 85 °C, picos de 100 °C; el envío VNC a la tablet (krfb) gastaba ~20 % de CPU.

## Sesión 2 (5 misiones), con los arreglos
- Cámaras: 0 frames sin etiqueta, ≤3 repeticiones por cada 1200 frames, 60 fps. Fin de misión: la pantalla
  dividida se apaga en el mismo segundo.
- Oleadas: 4 misiones completas sin problemas (cada oleada salió en 1–6 s).
- **OBS capturando la pantalla del juego** (4 capturas de KWin, una del escritorio entero de 4760 px): el juego
  pasa de 60 a 32–43 fps y las vistas pierden fluidez (15–23 % de cámaras repetidas). Para grabar: capturar
  una sola pantalla.

## Atasco de oleadas (sin resolver)
Visto en la 5.ª misión (escenario de jungla, enemigos tipo 0x1c y 0x79). Datos en
`docs/research/coop_tests_20261004/stall_213421_objects.json`; oleada sana de referencia en
`healthy_wave_212205_objects.json`.

- Último enemigo derrotado → 4 s después el juego recarga la vida de los dos jugadores (como al terminar una
  zona) → la misión nunca pasa a resultados ni salen más enemigos (pantalla 74, sin pausa, >35 s).
- En la tabla de objetos, 10 de 11 enemigos muertos están liberados (`entrada+0x1a = 0xff`); **uno no**:
  `[17]` tipo 0x1c (vida máx. 3000), grupo 10, `+0x1a = 0x00`, vida 0, estado `char+0x04 = 152`, murió apartado
  del grupo (191,0, 21,4, -184,6 frente a ~186, -170). Su muerte nunca terminó de procesarse y la misión espera.
- No se llegó a leer su animación/estado interno: se reintentó la misión antes.
- Siguientes pasos:
  1. Repetir con `coop_monitor.py`: a los 12 s sin enemigos lee 10 veces en 5 s motion `obj+0x5b30`, frame
     `obj+0x4bcc`, `char+0x04/+0x12/+0x16`, muerte procesada `char+0x1199`, `obj+0x5b54/56/57` y posición.
  2. Saber si es del juego o del mod: ¿quién lo mató (P1/P2)? ¿pasa con el compañero en IA (sin unir al P2)?
     Ruta de muerte conocida: `0x140f34740` (comprueba vida 0, marca `char+0x1199`, da Karma).
  3. Si el mod influye: candidatos son el compañero en el puerto 1 y la alternancia de cámara (`0x142ff2778`).

