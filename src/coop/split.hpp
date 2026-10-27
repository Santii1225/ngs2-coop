#pragma once
// Split screen for the local co-op (docs/SPLITSCREEN.md). The engine keeps one camera per player
// (docs/CAMERA_RESEARCH.md); while player 2 is in a Team Mission the mod alternates the rendered view
// every frame, keeps each player's last image (copied just before the HUD is drawn; the HUD goes to a
// texture of its own) and composes them: side by side, one above the other, or one per monitor
// (player 2 full screen on a window of its own on the other monitor).
#include <cstdint>
#include <dxgi.h>

namespace split {
enum Mode : int { Auto = 0, Vertical = 1, Horizontal = 2, Dual = 3 };

void init(uintptr_t image_base, const wchar_t* plugin_dir, void (*log)(const char*, ...));
// From the overlay's Present hook, before the overlay draws (render thread). Returns false for a
// swap chain the overlay must leave alone (split's own window on the second monitor).
bool present(IDXGISwapChain* sc);
// From the mod's worker: whether player 2 is playing a Team Mission right now.
void set_active(bool on);
// From the mod's worker: whether player 2 is in at all (menus included). With two monitors their window opens
// right away and mirrors the game until the split views start.
void set_joined(bool on);
// Once per game frame, on the update thread (pad update hook): alternates the camera to render.
void update_frame();
// Whether the view alternates right now (split screen or two monitors in use).
bool running();
// Next layout (vertical -> horizontal -> two monitors, when there are two). Returns its name.
const wchar_t* cycle();
// Layout in use right now (Auto resolved), and its name.
Mode mode();
const wchar_t* mode_name(Mode m);
} // namespace split
