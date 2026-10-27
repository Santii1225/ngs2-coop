# Cámara del jugador 2 — investigación (2026-10-03)

## Hallazgo: el motor ya tiene una cámara por jugador

Resto del co-op online de PS3 (cada consola mostraba la cámara de su jugador). En una Misión en Equipo hay
**dos cámaras activas**, cada una sigue a su personaje y responde al stick derecho de su mando.

| Qué | Dirección | Notas |
|---|---|---|
| Gestor de cámaras | `0x142fe5f10` (= `[0x142ff1890 + 0xec8]`) | 8 ranuras, stride `0x16a0` |
| Ranura activa | `+0x15b0` (byte) | 0 y 1 activas en Misión en Equipo |
| Ojo / objetivo | `+0x80` / `+0x90` (float4) | coordenadas de juego (objetivo ≈ personaje + 0,9 en Y) |
| Vista / proyección | `+0x1c0` / `+0x200` (4x4) | |
| Actualización | bucle de 8 ranuras `0x140fd6727` → `0x140fcec70` | hilo "Updating", cada frame |
| Selección | `0x140fd674a`: `idx = [0x142ff2768 + vista*4]`, `vista = [0x142ff2778]` | tabla = `[0, 1, …]` |
| Copia a la cámara de render | `0x140fd2ea0(0x142ff1890, idx)` | globales `0x142ff1950` ojo, `0x142ff1960` objetivo |
| Paquete por frame (doble búfer) | `0x142ff1890 + 0x840.. + n*0x360` | escrito en `0x140fd6828..` |
| Cámara del render | `0x141e65c80` (+0x260 ojo, +0x270 objetivo) | escrita en `0x141440230`, hilo "Rendering" |

Pruebas (lab, reversibles):
- `[0x142ff2778] = 1` → el juego dibuja la escena desde la cámara del compañero (detrás de él). El HUD sigue
  siendo el del P1. Devuelto a 0.
- Stick derecho del P2 (con el P2 unido): solo gira la cámara 1 (yaw 177,7° → 126,8°; la 0 sin cambios).
  Stick derecho del P1: solo la cámara 0.

## Opciones para mostrarla

1. **Pantalla dividida alternando frames** (viable con lo conocido): el mod alterna la vista 0/1 en cada
   frame de juego; el gancho de `Present` guarda cada imagen en su textura y compone las dos mitades. Mismo
   coste de GPU; cada vista a 30 fps. Riesgos: efectos temporales del motor (desenfoque de movimiento, etc.)
   mezclando cámaras, recorte de cada vista (la proyección está pensada para pantalla completa; se puede
   ajustar el aspecto en `+0x200`), HUD solo del P1.
2. **Pantalla dividida real (dos renders por frame)**: 60 fps por vista, ~2× GPU (sobra: el juego va al ~21 %
   de la RTX 4060). Requiere encontrar la función de render por frame y hacer que se ejecute dos veces con cada
   paquete de cámara. Más ingeniería inversa; viable de probar sobre la opción 1.
3. **Ventana pequeña (PiP)**: igual que 1 o 2, con la vista 1 reducida en una esquina.
4. **Botón para cambiar de cámara**: trivial (un entero), pero solo una vista a la vez.
