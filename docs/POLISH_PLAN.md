# Plan de pulido (pedido por Santi, 2026-10-03) — HECHO el 2026-10-03 (ver P2_CONTROL.md §15–16)

1. **Capa propia (overlay) sobre el juego** (hook de `Present`, p. ej. Dear ImGui):
   - "Jugadores: Santi" (nombre de Steam del P1 vía `SteamFriends()->GetPersonaName()`).
   - Aviso "X se ha unido a tu partida" al pulsar BACK el P2.
   - Nombre del P2: un segundo mando no trae cuenta de Steam; «Jugador 2» o un nombre que él escriba.
2. **Selector de personajes con columnas exclusivas:** nombre de cada jugador sobre "JUGADOR"/"COMPAÑERO"
   (en el overlay). El mando 1 solo maneja la columna izquierda y el mando 2 solo la derecha (el mod fuerza la
   columna activa según quién toque su mando). Límite: el juego tiene un solo cursor (por turnos, no a la vez).
3. **Elección doble de misión:** segundo recuadro para el P2 (overlay + su propio cursor); al confirmar,
   el mod elige al azar una de las dos y la escribe en la variable de misión del juego. Requiere investigar el
   menú de selección de misión. Es lo más difícil.
(Normal/Práctica: ya resuelto con los menús compartidos, porque los dos ven la misma pantalla.)
