#pragma once
#include <cstdint>
// Quick selector (D-pad up) inside Team Missions: change weapon, projectile and ninpo mid-mission
// (docs/QUICK_MENU.md, "Misiones en Equipo").
namespace quickmenu {
bool init(uintptr_t base, void (*log)(const char*, ...));
// Each player's selector (D-pad up on their pad, Ryu only; the game's window on their view, no pause): call once
// per game frame from the pad update hook (update thread) with the pad slots, player 2's slot (< 0 when not in)
// and the slot stride.
void frame(volatile uint8_t* pads, int p2_slot, uintptr_t pad_stride);
} // namespace quickmenu
