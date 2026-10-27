#pragma once
#include <cstdint>
// The game's text lookup (0x1416374f0: language, id -> UTF-16 string from the LANG packs) hooked so the mod's
// notices are drawn by the game itself, with its font and style, instead of a floating overlay: they take the
// place of the help line at the bottom of the menus (mission select, character screen, team mode select) and,
// at startup, are appended to the game's autosave notice. id = category << 16 | index; language 5 = Spanish.
namespace gametext {
bool init(uintptr_t base, void (*log)(const char*, ...));
// Shown for ms milliseconds on the menus' help line (replaces the previous message).
void message(const wchar_t* text, unsigned ms = 4000);
// Persistent help-line text, under messages; nullptr or "" clears it.
void line(const wchar_t* text);
// Call often (every frame or so): rewrites the help lines the game already holds.
void tick();
// Extra line under the startup autosave notice; nullptr or "" clears it.
void startup(const wchar_t* text);
// In a mission: the game's scrolling banner at the bottom of the screen (the one of "your partner is down"),
// with this text. Game thread only.
void banner(const wchar_t* text);
// Game thread, every frame: closes the mod's banner after 4 s.
void banner_tick();
} // namespace gametext
