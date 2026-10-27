#pragma once
// On-screen overlay for NGS2Coop: a toast (join/leave notices) and a status badge, drawn on top
// of the game's frame from a Present hook. Text is rendered with GDI into a texture and blended
// with a tiny shader inside a separate D3D11 device context state, so the game's state is untouched.

#include <cstdint>

namespace overlay {
// Hooks IDXGISwapChain::Present (shared vtable with the game's swap chain). Call once, from a thread.
bool install(void (*log)(const char*, ...));
// Called on the render thread at every Present, before the overlay draws.
void on_frame(void (*fn)());
// Shows text for a few seconds at the top centre of the screen (replaces the current toast).
void toast(const wchar_t* text);
// Persistent message at the top centre (behind toasts); empty or nullptr hides it.
void notice(const wchar_t* text);
// Persistent badge at the top right; empty or nullptr hides it.
void status(const wchar_t* text);
// Name tags over the character screen's JUGADOR / COMPAÑERO headers; nullptr hides them.
void column_names(const wchar_t* left, const wchar_t* right);
// Player 2's marker on the mission-select grid (col 0..4, row 0..1); col < 0 hides it.
void mission_marker(int col, int row, const wchar_t* text);
} // namespace overlay
