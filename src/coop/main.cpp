/*
 * NGS2Coop: second local player for Team Missions (docs/P2_CONTROL.md).
 *
 * character[group]+0x00 is the controller port an actor reads (0..3, 4 = AI brain).
 * Player 2 (actor byte[0x14211e761], the Team Mission partner) joins by pressing BACK: the
 * partner is bound to port 1 and player 2 is mapped to the pad that pressed it. If that pad
 * sits in slot 0 (a streamed pad created before the game started takes slot 0), the mod swaps
 * the contents of slot 0 and the other pad's slot after every pad update, so the whole game
 * (player 1, pause menu, menus) sees the other pad as slot 0.
 * Pressing BACK again hands the partner back to the AI. Only static image data is touched.
 */
#define WIN32_LEAN_AND_MEAN
#include "core/sigma2_hook.hpp"
#include "overlay.hpp"
#include "split.hpp"
#include "gametext.hpp"
#include "quickmenu.hpp"
#include <windows.h>
#include <cstdarg>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <cwchar>
#include <initializer_list>

namespace {
constexpr uintptr_t kNumPlayers = 0x211e5cc;   // byte: 2 in Team Missions, 1 in the menus
constexpr uintptr_t kPlayerActor = 0x211e760;  // byte[2]: player -> game_object index (0xff = none)
constexpr uintptr_t kPlayerPad = 0x211e754;    // byte[2]: player -> pad slot (read by 0x140f8bd40)
constexpr uintptr_t kPads = 0x2235880;         // pad state per slot, stride 0x38
constexpr uintptr_t kPadStride = 0x38;
constexpr uintptr_t kGameObjects = 0x3195300;  // 160 x 0x30
constexpr uintptr_t kCharacters = 0x2f78b10;   // stride 0x1240
constexpr uint8_t kAiPort = 4;
constexpr uint8_t kP2Port = 1;
constexpr uint32_t kBack = 0x200;
constexpr uint32_t kLB = 0x1000, kRB = 0x2000;
constexpr uint32_t kLS = 0x400, kRS = 0x800;  // stick clicks: both at once switch the split-screen layout
constexpr uintptr_t kMenuScreen = 0x21544fa;  // byte: 0 main menu, 8 mode, 6 mission select, 5 characters
constexpr uint8_t kScreenCharacters = 5;
constexpr uint8_t kScreenPlaying = 74;
constexpr uintptr_t kPausedFlag = 0x1e3a8c2;  // byte: 1 while the pause menu is open  // in a mission (it changes as soon as the results screen starts)
constexpr uintptr_t kCharColumn = 0x1e65458;  // byte: active column on the character screen (0 player, 1 partner)
constexpr uintptr_t kCharCursor = 0x215b6a6;  // byte: row cursor on the character screen, column * 5 + row
constexpr uint8_t kScreenMissions = 6;
constexpr uintptr_t kMissionCol = 0x1e654c0, kMissionRow = 0x1e654c4;  // mission-select cursor (0..4, 0..1)
constexpr uint32_t kUp = 0x1, kDown = 0x2, kLeft = 0x4, kRight = 0x8, kA = 0x10, kB = 0x20, kY = 0x80;

uintptr_t base;
wchar_t log_path[MAX_PATH];

void log(const char* fmt, ...) {
  FILE* f = _wfopen(log_path, L"a");
  if (!f) return;
  SYSTEMTIME t;
  GetLocalTime(&t);
  fprintf(f, "%02u:%02u:%02u.%03u ", t.wHour, t.wMinute, t.wSecond, t.wMilliseconds);
  va_list ap;
  va_start(ap, fmt);
  vfprintf(f, fmt, ap);
  va_end(ap);
  fputc('\n', f);
  fclose(f);
}

template<class T> volatile T& at(uintptr_t rva) { return *reinterpret_cast<volatile T*>(base + rva); }

struct Pad {
  uint32_t held;
  bool connected;
};

// Pad slots as the game filled them (after the slot swap, before the shared-menu copy), captured
// by the pad update hook; read live from the game when the hook is not installed.
volatile uint32_t snap_held[4];
volatile uint8_t snap_connected[4];
volatile bool snap_valid = false;

Pad pad(uint8_t slot) {
  if (snap_valid) return {snap_held[slot], snap_connected[slot] != 0};
  const uintptr_t p = kPads + slot * kPadStride;
  return {at<uint32_t>(p), at<uint8_t>(p + 0x0e) != 0};
}

wchar_t name_p1[64] = L"Jugador 1", name_p2[64] = L"Jugador 2";

// ---- player names for the overlay ----------------------------------------------------------------
void plugin_file(wchar_t* out, const wchar_t* name) {
  lstrcpyW(out, log_path);
  wchar_t* s = wcsrchr(out, L'\\');
  if (s) lstrcpyW(s + 1, name);
}

// Player 1: the Steam persona name of the account running the game.
void steam_name(wchar_t* out, int n) {
  lstrcpynW(out, L"Jugador 1", n);
  HMODULE m = GetModuleHandleW(L"steam_api64.dll");
  if (!m) return;
  using FriendsFn = void* (*)();
  using NameFn = const char* (*)(void*);
  auto friends = reinterpret_cast<FriendsFn>(reinterpret_cast<void*>(GetProcAddress(m, "SteamAPI_SteamFriends_v017")));
  auto name = reinterpret_cast<NameFn>(reinterpret_cast<void*>(GetProcAddress(m, "SteamAPI_ISteamFriends_GetPersonaName")));
  void* f = friends ? friends() : nullptr;
  const char* utf8 = f && name ? name(f) : nullptr;
  if (utf8 && *utf8) MultiByteToWideChar(CP_UTF8, 0, utf8, -1, out, n);
}

// Player 2: the name in plugin/ngs2coop-p2name.txt, if any (a second pad has no account name).
void p2_name(wchar_t* out, int n) {
  lstrcpynW(out, L"Jugador 2", n);
  wchar_t path[MAX_PATH];
  plugin_file(path, L"ngs2coop-p2name.txt");
  FILE* f = _wfopen(path, L"rb");
  if (!f) return;
  char buf[128] = {};
  const size_t len = fread(buf, 1, sizeof(buf) - 1, f);
  fclose(f);
  buf[len] = 0;
  for (char* c = buf; *c; ++c)
    if (*c == '\r' || *c == '\n') *c = 0;
  if (buf[0]) MultiByteToWideChar(CP_UTF8, 0, buf, -1, out, n);
}

// Partner character for player 2, or 0 when no valid Team Mission partner exists.
uintptr_t partner_character() {
  if (at<uint8_t>(kNumPlayers) < 2) return 0;
  const uint8_t a0 = at<uint8_t>(kPlayerActor), a1 = at<uint8_t>(kPlayerActor + 1);
  if (a1 >= 0xa0 || a1 == a0) return 0;
  const uintptr_t entry = kGameObjects + a1 * 0x30;
  if (!at<uint64_t>(entry) || at<uint8_t>(entry + 0x1a)) return 0;
  const uint8_t group = at<uint8_t>(entry + 0x1f);
  if (group >= 0x20) return 0;
  return kCharacters + group * 0x1240;
}

// Background input: the game stops collecting pad samples when it is told it lost activation.
// Swallow the deactivation messages so both players keep control while another window
// (e.g. a terminal) has the focus. Disable by creating plugin/ngs2coop-nobg.txt.
WNDPROC original_wndproc;

LRESULT CALLBACK wndproc_hook(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
  switch (msg) {
  case WM_ACTIVATEAPP:
    if (!wp) return 0;
    break;
  case WM_ACTIVATE:
    if (LOWORD(wp) == WA_INACTIVE) return 0;
    break;
  case WM_KILLFOCUS:
    return 0;
  }
  return CallWindowProcW(original_wndproc, hwnd, msg, wp, lp);
}

BOOL CALLBACK find_game_window(HWND hwnd, LPARAM out) {
  DWORD pid;
  GetWindowThreadProcessId(hwnd, &pid);
  if (pid == GetCurrentProcessId() && IsWindowVisible(hwnd) && !GetWindow(hwnd, GW_OWNER)) {
    RECT r;
    if (GetClientRect(hwnd, &r) && r.right >= 640) {
      *reinterpret_cast<HWND*>(out) = hwnd;
      return FALSE;
    }
  }
  return TRUE;
}

void install_background_input() {
  wchar_t off[MAX_PATH];
  lstrcpyW(off, log_path);
  wchar_t* s = wcsrchr(off, L'\\');
  if (s) lstrcpyW(s + 1, L"ngs2coop-nobg.txt");
  if (GetFileAttributesW(off) != INVALID_FILE_ATTRIBUTES) {
    log("background input disabled (ngs2coop-nobg.txt)");
    return;
  }
  HWND hwnd = nullptr;
  for (int i = 0; i < 300 && !hwnd; ++i) {
    EnumWindows(find_game_window, reinterpret_cast<LPARAM>(&hwnd));
    if (!hwnd) Sleep(100);
  }
  if (!hwnd) {
    log("background input: game window not found");
    return;
  }
  original_wndproc = reinterpret_cast<WNDPROC>(
      SetWindowLongPtrW(hwnd, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(wndproc_hook)));
  log(original_wndproc ? "background input enabled (deactivation messages swallowed)"
                       : "background input: subclass failed");
}

// Shared menus: in menus (fewer than 2 players) the game only listens to pad slot 0. After the
// per-frame pad update (0x141466030) copy the most recently used pad into slot 0, so any
// connected controller can drive the menus (player 2 picks the partner column with RB).
constexpr uintptr_t kPadUpdate = 0x1466030;
constexpr uint8_t kPadUpdateHead[17] = {0x4c, 0x8b, 0xdc, 0x55, 0x53, 0x57, 0x49, 0x8d, 0x6b,
                                        0xb8, 0x48, 0x81, 0xec, 0x30, 0x01, 0x00, 0x00};
using PadUpdateFn = uint64_t (*)(uint64_t, uint64_t, uint64_t, uint64_t);
PadUpdateFn pad_update_original;
int menu_owner = 0;
volatile LONG swap_slot = 0;  // > 0: pad slot whose contents trade places with slot 0 every frame
volatile LONG p2_pad = -1;    // player 2's pad slot (after the swap), -1 = not joined

// Notices go through the game's own text (gametext): the help line at the bottom of the menus. The floating
// overlay is only drawn when plugin/ngs2coop-overlay.txt exists (debugging).
bool use_overlay = false;
void notify(const wchar_t* text) {
  gametext::message(text);
  if (use_overlay) overlay::toast(text);
}
void status_line(const wchar_t* text) {
  gametext::line(text);
  if (use_overlay) overlay::status(text);
}

bool pad_active(uint8_t slot) {
  const uintptr_t p = kPads + slot * kPadStride;
  if (!at<uint8_t>(p + 0x0e)) return false;
  const float lx = at<float>(p + 0x18), ly = at<float>(p + 0x1c);
  return at<uint32_t>(p) != 0 || lx > 0.35f || lx < -0.35f || ly > 0.35f || ly < -0.35f;
}

// Pad slot layout (stride 0x38): +0x00 held, +0x04 held last frame, +0x08 newly pressed,
// +0x10/+0x14 further press/repeat masks, +0x0e connected, +0x18/+0x1c left stick.
constexpr uintptr_t kPressMasks[] = {0x00, 0x08, 0x10, 0x14};
uint8_t physical[4 * kPadStride];  // the update's own output, before the swap/copy/inject below
bool physical_valid = false;
int inject_wait = 0;               // frames before another column-switch press may be injected
uint32_t replay[4] = {};           // press masks muted while switching column, replayed after it
int replay_owner = -1;

void copy_slots(volatile uint8_t* dst, const volatile uint8_t* src) {
  for (uintptr_t i = 0; i < 4 * kPadStride; ++i) dst[i] = src[i];
}

// One-frame press of `buttons` in slot 0 (everything else released).
void inject_slot0(volatile uint8_t* pads, uint32_t buttons) {
  for (uintptr_t i = 0; i < kPadStride; ++i)
    if (i != 0x0e) pads[i] = 0;
  for (uintptr_t m : kPressMasks) at<uint32_t>(kPads + m) = buttons;
}

// Dual mission pick (player 2 joined, mission-select screen). Player 1 drives the game's cursor; player 2
// has a marker of their own: d-pad within the page, LB/RB to change page (Acolyte, Warrior, Mentor, Master
// Ninja), A to lock, B to unlock. Player 1's A is held back until player 2 has locked a mission (player 1's
// B then unlocks instead of leaving the screen). With both locked: the same mission goes ahead; different
// ones are settled by a coin flip, and if player 2 wins the mod walks the game's cursor there (LB/RB, d-pad)
// and presses A. The game's page and cursor bytes are only read.
constexpr uintptr_t kMissionPage = 0x215b810;  // byte: page of the mission grid (0..3)
constexpr int kPages = 4;
constexpr int kPageRows[kPages] = {2, 2, 1, 1};  // 5 missions per row
const wchar_t* const kPageNames[kPages] = {L"Acólito", L"Guerrero", L"Mentor", L"Maestro Ninja"};

struct Choice {
  int page = 0, col = 0, row = 0;
  bool operator==(const Choice& o) const { return page == o.page && col == o.col && row == o.row; }
};
struct MissionPick {
  bool active = false, p2_locked = false, p1_locked = false, driving = false, confirmed = false;
  Choice p2, p1, target;
  int wait = 0, steps = 0;
} pick;
uint32_t rng_state = 0;

void update_marker(int shown_page) {
  if (pick.p2.page != shown_page || pick.p1_locked || pick.p2_locked) {
    wchar_t s[192];
    swprintf(s, 192, L"%ls: %ls %d%ls%ls", name_p2, kPageNames[pick.p2.page], pick.p2.row * 5 + pick.p2.col + 1,
             pick.p2_locked ? L" (lista)" : L"", pick.p1_locked ? L"  -  P1 esperando" : L"");
    status_line(s);
  } else {
    status_line(nullptr);
  }
}

// The mission grid as both players see it, drawn by the game. The menus build, every frame, a linked list of
// sprite entries (0x80 bytes: +0x08 next, +0x10 kind 0x0a = sprite, +0x18 sprite id, +0x30 scale, +0x40 x/y in
// 1280x720 units, +0x50 colour RGBA) in one of two buffers; the renderer draws the finished one. The list ends
// with the grid cursor: a frame (scale 1) and a pulsing glow (scale 0.9) right after it. Each cell is a
// background, the mission picture and, once cleared, a karma emblem; the cell under the cursor uses another
// background, scale 1 and full brightness instead of scale 0.9 and 0.7.
// The edits run on the render thread at Present, when the list for the next frame is complete (the update
// thread still rewrites the list it is building, which made earlier edits there flicker). Player 2 browsing:
// copies of the frame and glow tinted red on their cell, whose picture is raised like the cursor's. A locked
// pick: a dimmed frame shrunk to the cell's resting size, no glow, the picture back at rest; for player 1 the
// game's own cursor is then hidden.
constexpr uintptr_t kSpriteLists[2] = {0x2ee8000, 0x2f19000};  // the two list buffers (searched 0xa000 bytes each)
constexpr size_t kSpriteListSpan = 0xa000;
constexpr float kGridX0 = 531, kGridY0 = 241, kGridDX = 126, kGridDY = 76;
constexpr float kRestX = 26, kRestY = 30, kRaisedX = 20, kRaisedY = 25;  // picture offset in its cell
constexpr float kEmblemDX = 28, kRaisedEmblemDX = 30;                     // emblem right of the picture
constexpr float kRestScale = 0.899993896484375f, kRestLight = 0.69921875f;  // the game's own (rounded) values
inline bool approx(float a, float b) { return a > b - 0.01f && a < b + 0.01f; }

struct GridView {  // written by the update thread (mission pick), read at Present
  volatile bool active = false;
  volatile int page = 0, cursor_col = 0, cursor_row = 0;
  volatile bool p1_locked = false, p2_visible = false, p2_locked = false;
  volatile int p1_col = 0, p1_row = 0, p2_col = 0, p2_row = 0;
  volatile bool p1_visible = false;
} grid_view;

alignas(16) uint8_t grid_chain[2][4][0x80];  // our entries per list buffer: P2 frame, P2 glow, P1 locked frame

struct Entry {
  uintptr_t a;
  uint8_t* p() const { return reinterpret_cast<uint8_t*>(a); }
  float& f(int off) const { return *reinterpret_cast<float*>(a + off); }
  uint64_t& next() const { return *reinterpret_cast<uint64_t*>(a + 0x08); }
  uint16_t& id() const { return *reinterpret_cast<uint16_t*>(a + 0x18); }
};

// Entries of a cell whose picture sits at `px, py` (resting or raised): background + picture, and the emblem.
void restyle_cell(uintptr_t lo, int col, int row, bool raise, uint16_t raised_bg, uint16_t rest_bg) {
  const float ox = kGridX0 + kGridDX * col, oy = kGridY0 + kGridDY * row;
  for (uintptr_t a = lo; a + 0x80 <= lo + kSpriteListSpan; a += 0x10) {
    const Entry e{a};
    if (e.p()[0x10] != 0x0a || e.f(0x5c) <= 0) continue;
    const float x = e.f(0x40), y = e.f(0x44);
    const bool at_rest = y == oy + kRestY && (x == ox + kRestX || x == ox + kRestX + kEmblemDX);
    const bool raised = y == oy + kRaisedY && (x == ox + kRaisedX || x == ox + kRaisedX + kRaisedEmblemDX);
    if (!at_rest && !raised) continue;
    const bool emblem = x == ox + kRestX + kEmblemDX || x == ox + kRaisedX + kRaisedEmblemDX;
    if (raise == raised) continue;
    e.f(0x40) = raise ? ox + kRaisedX + (emblem ? kRaisedEmblemDX : 0) : ox + kRestX + (emblem ? kEmblemDX : 0);
    e.f(0x44) = oy + (raise ? kRaisedY : kRestY);
    e.f(0x30) = e.f(0x34) = raise ? 1.0f : kRestScale;
    const bool background = e.p()[0x1a] == 0xb6 && !emblem;
    if (background) {
      if (raise ? e.id() == rest_bg : e.id() == raised_bg) e.id() = raise ? raised_bg : rest_bg;
    } else {
      e.f(0x50) = e.f(0x54) = e.f(0x58) = raise ? 1.0f : kRestLight;
      if (raise) e.f(0x5c) = 1.0f;  // a picture fading back to rest is partly transparent
    }
  }
}

uint8_t tmpl_frame[0x80], tmpl_glow[0x80];  // the cursor's entries at rest (kept while it slides)
bool have_frame = false, have_glow = false;
uintptr_t last_tail[2];

bool our_entry(int b, uint64_t p) {
  for (int i = 0; i < 4; ++i)
    if (p == reinterpret_cast<uint64_t>(grid_chain[b][i])) return true;
  return false;
}

void edit_grid_buffer(int b) {
  const uintptr_t lo = base + kSpriteLists[b], hi = lo + kSpriteListSpan;
  const GridView& v = grid_view;
  const float cx = kGridX0 + kGridDX * v.cursor_col, cy = kGridY0 + kGridDY * v.cursor_row;
  // The game's cursor: frame entries (scale 1) at the cursor's cell; the glow follows a frame in its list.
  uintptr_t frames[4];
  int nframes = 0;
  uintptr_t glow = 0;
  for (uintptr_t a = lo; a + 0x80 <= hi && nframes < 4; a += 0x10) {
    const Entry e{a};
    if (e.p()[0x10] != 0x0a || e.f(0x30) != 1.0f || e.f(0x40) != cx || e.f(0x44) != cy || e.p()[0x1a] == 0xb7) continue;
    frames[nframes++] = a;
  }
  for (int i = 0; i < nframes && !glow; ++i) {
    const uint64_t nx = Entry{frames[i]}.next();
    if (nx >= lo && nx + 0x80 <= hi) {
      const Entry g{static_cast<uintptr_t>(nx)};
      if (g.p()[0x10] == 0x0a && g.f(0x30) < 0.999f && g.f(0x30) > 0.5f) glow = nx;
    }
  }
  if (nframes && !v.p1_locked) {
    memcpy(tmpl_frame, reinterpret_cast<void*>(frames[0]), 0x80);
    have_frame = true;
    if (glow) {
      memcpy(tmpl_glow, reinterpret_cast<void*>(glow), 0x80);
      have_glow = true;
    }
  }
  if (!have_frame) return;
  // Our entries go right before the cursor's frame (the renderer stops at a list's last entry, often the
  // frame itself): the pointer that leads to the frame now leads to our chain, which ends at the frame. While
  // the cursor slides between cells the frame keeps its address, so the last one found is reused.
  uintptr_t anchor = nframes ? frames[0] : 0;
  if (!anchor && last_tail[b]) {
    const Entry t{last_tail[b]};
    if (t.p()[0x10] == 0x0a && t.f(0x30) == 1.0f && memcmp(t.p() + 0x18, tmpl_frame + 0x18, 2) == 0) anchor = last_tail[b];
  }
  if (!anchor) return;
  last_tail[b] = anchor;
  volatile uint64_t* slot = nullptr;
  for (uintptr_t a = lo; a + 8 <= hi; a += 8) {
    volatile uint64_t* q = reinterpret_cast<volatile uint64_t*>(a);
    if (*q == anchor) { slot = q; break; }
    if (our_entry(b, *q)) {  // already pointing at our chain from an earlier frame
      slot = q;
      break;
    }
  }
  if (!slot) return;
  // Background ids: raised at the game cursor's cell, resting at another cell.
  uint16_t raised_bg = 0, rest_bg = 0;
  for (uintptr_t a = lo; a + 0x80 <= hi; a += 0x10) {
    const Entry e{a};
    if (e.p()[0x10] != 0x0a || e.p()[0x1a] != 0xb6 || e.f(0x5c) <= 0) continue;
    if (e.f(0x40) == cx + kRaisedX && e.f(0x44) == cy + kRaisedY) raised_bg = e.id();
  }
  {  // resting background: the id most cells at rest use
    uint16_t ids[16] = {};
    int counts[16] = {};
    for (uintptr_t a = lo; a + 0x80 <= hi; a += 0x10) {
      const Entry e{a};
      if (e.p()[0x10] != 0x0a || e.p()[0x1a] != 0xb6 || e.f(0x5c) <= 0 || !approx(e.f(0x30), kRestScale) || e.f(0x50) != 1.0f) continue;
      const float rx = e.f(0x40) - kGridX0 - kRestX, ry = e.f(0x44) - kGridY0 - kRestY;
      if (rx < 0 || ry < 0 || rx > 4 * kGridDX + 1 || ry > kGridDY + 1) continue;
      for (int i = 0; i < 16; ++i)
        if (!counts[i] || ids[i] == e.id()) { ids[i] = e.id(); ++counts[i]; break; }
    }
    int best = 0;
    for (int i = 0; i < 16; ++i) if (counts[i] > best) { best = counts[i]; rest_bg = ids[i]; }
  }
  int n = 0;
  auto add = [&](const uint8_t* tmpl, int col, int row, float dx, float dy, float scale, float r, float g, float bl) {
    uint8_t* e = grid_chain[b][n++];
    memcpy(e, tmpl, 0x80);
    float* f = reinterpret_cast<float*>(e);
    f[0x40 / 4] = kGridX0 + kGridDX * col + dx;
    f[0x44 / 4] = kGridY0 + kGridDY * row + dy;
    f[0x30 / 4] = f[0x34 / 4] = scale;
    f[0x50 / 4] *= r;
    f[0x54 / 4] *= g;
    f[0x58 / 4] *= bl;
    f[0x5c / 4] = f[0x5c / 4] > 0 ? f[0x5c / 4] : (tmpl == tmpl_frame ? 1.0f : 0.0f);
  };
  const float* tf = reinterpret_cast<const float*>(tmpl_frame);
  const float* tg = reinterpret_cast<const float*>(tmpl_glow);
  const float lock_dx = kRestX - kRaisedX * kRestScale, lock_dy = kRestY - kRaisedY * kRestScale;
  if (v.p1_locked) {  // player 1 has picked: hide the game's cursor, put that picture back at rest
    for (int i = 0; i < nframes; ++i) Entry{frames[i]}.f(0x5c) = 0;
    if (glow) Entry{glow}.f(0x5c) = 0;
    if (raised_bg && rest_bg) restyle_cell(lo, v.cursor_col, v.cursor_row, false, raised_bg, rest_bg);
    if (v.p1_visible) add(tmpl_frame, v.p1_col, v.p1_row, lock_dx, lock_dy, kRestScale, 0.7f, 0.7f, 0.7f);
  }
  if (v.p2_visible) {
    if (v.p2_locked) {
      add(tmpl_frame, v.p2_col, v.p2_row, lock_dx, lock_dy, kRestScale, 0.85f, 0.1f, 0.1f);
    } else {
      add(tmpl_frame, v.p2_col, v.p2_row, 0, 0, 1.0f, 1.0f, 0.15f, 0.15f);
      if (have_glow && glow)
        add(tmpl_glow, v.p2_col, v.p2_row, tg[0x40 / 4] - tf[0x40 / 4], tg[0x44 / 4] - tf[0x44 / 4], Entry{glow}.f(0x30), 1.0f, 0.2f, 0.2f);
      if (raised_bg && rest_bg) restyle_cell(lo, v.p2_col, v.p2_row, true, raised_bg, rest_bg);
    }
  }
  // Glow animation follows the game's live glow (alpha and scale pulse).
  if (glow && n) {
    for (int i = 0; i < n; ++i) {
      float* f = reinterpret_cast<float*>(grid_chain[b][i]);
      if (memcmp(grid_chain[b][i] + 0x18, tmpl_glow + 0x18, 2) == 0 && f[0x30 / 4] != 1.0f && f[0x30 / 4] != kRestScale)
        f[0x5c / 4] = Entry{glow}.f(0x5c);
    }
  }
  uint64_t next = anchor;
  for (int i = n - 1; i >= 0; --i) {
    *reinterpret_cast<uint64_t*>(grid_chain[b][i] + 0x08) = next;
    next = reinterpret_cast<uint64_t>(grid_chain[b][i]);
  }
  *slot = next;
}

// Hook at the end of the per-frame loop that lets every menu screen build its sprite list (0x141508520):
// at 0x141508539 the lists of this frame are complete and the renderer has not read them yet.
constexpr uintptr_t kUiBuilt = 0x1508539;
constexpr uint8_t kUiBuiltHead[16] = {0x48, 0x63, 0x05, 0x0c, 0x60, 0xca, 0x00,  // movsxd rax, [rip+0xca600c]
                                      0x48, 0x8d, 0x0c, 0x80,                    // lea rcx, [rax+rax*4]
                                      0x41, 0x83, 0x24, 0xcc, 0xfb};             // and dword [r12+rcx*8], -5

// Character screen visuals, edited in the finished sprite list. The column the game is not editing is drawn
// at half brightness (0.5, or 0.25 for some icons): it is drawn at full brightness again, since both players
// edit at once. The ready bands reuse the selected-row backgrounds (sprite 0x9d, blue, and 0x9c, red): full
// column width under each player's costume row, bright once that player is ready, a faint grey bar until then.
constexpr float kColumnSplitX = 640;
volatile LONG chars_ready_mask = 0;  // bit 0 player 1 ready, bit 1 player 2 ready
volatile LONG chars_on = 0;
volatile LONG char_rows[2] = {0, 0};  // each player's row in their column (0 character .. 4 costume)
// The unselected arrows either side of each row: their x per column (the sprite id changes as they animate)
// and the rows' y.
constexpr float kRowArrowX[2][4] = {{160, 230, 445, 453}, {773, 843, 988, 1058}};
constexpr float kRowArrowY[5] = {207, 272, 358, 444, 527};
bool row_arrow(float x, int col) {
  for (float ax : kRowArrowX[col])
    if (x == ax) return true;
  return false;
}
alignas(16) uint8_t char_chain[2][4][0x80];  // per list buffer: two layers per player

bool arrow_x(float x, int col) {  // the selection arrows either side of a row
  const float off = col ? 613.0f : 0.0f;
  return (x >= 150 + off && x <= 235 + off) || (x >= 440 + off && x <= 460 + off);
}

void edit_char_buffer(int b) {
  const uintptr_t lo = base + kSpriteLists[b], hi = lo + kSpriteListSpan;
  const int active = at<uint8_t>(kCharColumn) ? 1 : 0;
  uintptr_t banner[2] = {0, 0};  // 0xa0 (left, blue) and 0x9f (right, red) at the name row
  uintptr_t buttons = 0;         // the "Confirm / Back" prompts, drawn last
  for (uintptr_t a = lo; a + 0x80 <= hi; a += 0x10) {
    const Entry e{a};
    if (e.p()[0x10] != 0x0a || e.f(0x5c) <= 0) continue;
    if (e.p()[0x1a] == 0x0b && e.f(0x44) > 600 && !buttons) buttons = a;
    if (e.p()[0x1a] != 0x9f) continue;
    const float x = e.f(0x40), y = e.f(0x44);
    if (y == 484.0f && e.id() == 0x9d) banner[0] = a;  // the costume row's backgrounds: blue left, red right
    if (y == 484.0f && e.id() == 0x9c) banner[1] = a;
    const int col = x < kColumnSplitX ? 0 : 1;
    if (col != active && y > 200 && y < 560) {
      if (approx(e.f(0x50), 0.5f) && e.f(0x5c) == 1.0f) e.f(0x50) = e.f(0x54) = e.f(0x58) = 1.0f;
      else if (approx(e.f(0x50), 0.25f)) e.f(0x50) = e.f(0x54) = e.f(0x58) = 0.5f;
    }
    // The column the game is not editing shows no cursor: light that player's row arrows in their colour, so
    // both players always see where they are.
    const LONG crow = char_rows[col];
    if (col != active && crow >= 0 && crow < 5 && y == kRowArrowY[crow] &&
        row_arrow(x, col) && approx(e.f(0x50), 0.5f)) {
      e.f(0x50) = col ? 1.0f : 0.35f;
      e.f(0x54) = col ? 0.3f : 0.6f;
      e.f(0x58) = col ? 0.3f : 1.0f;
      e.f(0x5c) = 1.0f;
    }
    // The selected row's arrows (full brightness): blue for player 1, red for player 2.
    if (y > 200 && y < 560 && arrow_x(x, col) && e.f(0x50) == 1.0f && e.f(0x5c) == 1.0f) {
      e.f(0x50) = col ? 1.0f : 0.35f;
      e.f(0x54) = col ? 0.3f : 0.6f;
      e.f(0x58) = col ? 0.3f : 1.0f;
    }
  }
  if (!banner[0] || !banner[1] || !buttons) return;
  volatile uint64_t* slot = nullptr;
  for (uintptr_t a = lo; a + 8 <= hi && !slot; a += 8) {
    volatile uint64_t* q = reinterpret_cast<volatile uint64_t*>(a);
    if (*q == buttons || *q == reinterpret_cast<uint64_t>(char_chain[b][0])) slot = q;
  }
  if (!slot) return;
  const LONG ready = chars_ready_mask;
  for (int i = 0; i < 4; ++i) {  // entries 0, 1: player 1; 2, 3: player 2 (the second layer doubles the glow)
    const int p = i / 2;
    uint8_t* e = char_chain[b][i];
    memcpy(e, reinterpret_cast<void*>(banner[p]), 0x80);
    float* f = reinterpret_cast<float*>(e);
    f[0x34 / 4] = 0.65f;
    f[0x44 / 4] = 548.0f;
    if (ready & (1 << p)) {  // the player's colour, brighter than the game's own row highlight
      f[0x50 / 4] = p ? 1.0f : 0.45f;
      f[0x54 / 4] = p ? 0.35f : 0.7f;
      f[0x58 / 4] = p ? 0.35f : 1.0f;
      f[0x5c / 4] = 1.0f;
    } else {  // not ready: one faint grey bar
      f[0x50 / 4] = f[0x54 / 4] = f[0x58 / 4] = 0.3f;
      f[0x5c / 4] = i % 2 ? 0.0f : 0.35f;
    }
    *reinterpret_cast<uint64_t*>(e + 0x08) =
        i < 3 ? reinterpret_cast<uint64_t>(char_chain[b][i + 1]) : static_cast<uint64_t>(buttons);
  }
  *slot = reinterpret_cast<uint64_t>(char_chain[b][0]);
}

// The screen byte stays at 6 after other menus too (load game, then the main menu and the team mode select;
// seen 2026-10-28: player 1's A was held back there for a mission pick nobody could see). The mission screen is
// also told by the grid cursor's frame (scale 1, on the game cursor's cell) in this frame's sprite lists.
volatile ULONGLONG grid_seen = 0;

bool grid_cursor_drawn() {
  const float cx = kGridX0 + kGridDX * at<uint8_t>(kMissionCol), cy = kGridY0 + kGridDY * at<uint8_t>(kMissionRow);
  for (int b = 0; b < 2; ++b) {
    const uintptr_t lo = base + kSpriteLists[b];
    for (uintptr_t a = lo; a + 0x80 <= lo + kSpriteListSpan; a += 0x10) {
      const Entry e{a};
      if (e.p()[0x10] == 0x0a && e.f(0x30) == 1.0f && e.f(0x40) == cx && e.f(0x44) == cy && e.p()[0x1a] != 0xb7) return true;
    }
  }
  return false;
}

void ui_built() {
  const uint8_t screen = at<uint8_t>(kMenuScreen);
  if (screen == kScreenMissions && grid_cursor_drawn()) grid_seen = GetTickCount64();
  if (screen == kScreenCharacters && chars_on) {
    for (int b = 0; b < 2; ++b) edit_char_buffer(b);
    return;
  }
  if (!grid_view.active || screen != kScreenMissions) return;
  for (int b = 0; b < 2; ++b) edit_grid_buffer(b);
}

bool install_ui_hook() {
  auto* target = reinterpret_cast<uint8_t*>(base + kUiBuilt);
  if (memcmp(target, kUiBuiltHead, sizeof(kUiBuiltHead))) {
    log("menus: unexpected bytes at the UI build loop, player 2 grid off");
    return false;
  }
  auto* t = static_cast<uint8_t*>(VirtualAlloc(nullptr, 256, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE));
  if (!t) return false;
  uint8_t* p = t;
  auto emit = [&](std::initializer_list<uint8_t> bytes) { for (uint8_t b : bytes) *p++ = b; };
  auto emit64 = [&](uint64_t v) { memcpy(p, &v, 8); p += 8; };
  emit({0x55, 0x48, 0x89, 0xe5});                                            // push rbp; mov rbp, rsp
  emit({0x50, 0x51, 0x52, 0x41, 0x50, 0x41, 0x51, 0x41, 0x52, 0x41, 0x53});  // push rax rcx rdx r8-r11
  emit({0x48, 0x83, 0xe4, 0xf0, 0x48, 0x81, 0xec, 0x80, 0x00, 0x00, 0x00});  // and rsp, -16; sub rsp, 0x80
  for (uint8_t i = 0; i < 6; ++i) emit({0xf3, 0x0f, 0x7f, static_cast<uint8_t>(0x44 | (i << 3)), 0x24, static_cast<uint8_t>(0x20 + i * 0x10)});
  emit({0x48, 0xb8});
  emit64(reinterpret_cast<uint64_t>(&ui_built));                             // mov rax, ui_built
  emit({0xff, 0xd0});                                                        // call rax
  for (uint8_t i = 0; i < 6; ++i) emit({0xf3, 0x0f, 0x6f, static_cast<uint8_t>(0x44 | (i << 3)), 0x24, static_cast<uint8_t>(0x20 + i * 0x10)});
  emit({0x48, 0x8d, 0x65, 0xc8});                                            // lea rsp, [rbp-0x38]
  emit({0x41, 0x5b, 0x41, 0x5a, 0x41, 0x59, 0x41, 0x58, 0x5a, 0x59, 0x58, 0x5d});  // pop r11..rax, rbp
  // the 16 bytes we replaced, with the RIP-relative load made absolute
  int32_t disp;
  memcpy(&disp, target + 3, 4);
  emit({0x48, 0xb8});
  emit64(reinterpret_cast<uint64_t>(target + 7) + disp);                     // mov rax, &dword
  emit({0x48, 0x63, 0x00});                                                  // movsxd rax, [rax]
  emit({0x48, 0x8d, 0x0c, 0x80, 0x41, 0x83, 0x24, 0xcc, 0xfb});
  emit({0xff, 0x25, 0x00, 0x00, 0x00, 0x00});
  emit64(reinterpret_cast<uint64_t>(target + 16));                           // jmp back
  FlushInstructionCache(GetCurrentProcess(), t, p - t);
  DWORD old;
  if (!VirtualProtect(target, 16, PAGE_EXECUTE_READWRITE, &old)) return false;
  *reinterpret_cast<volatile uint16_t*>(target) = 0xfeeb;  // park the update thread while patching
  FlushInstructionCache(GetCurrentProcess(), target, 2);
  uint8_t patch[16];
  patch[0] = 0xff; patch[1] = 0x25; memset(patch + 2, 0, 4);
  const uint64_t to = reinterpret_cast<uint64_t>(t);
  memcpy(patch + 6, &to, 8);
  patch[14] = patch[15] = 0x90;
  memcpy(target + 2, patch + 2, sizeof(patch) - 2);
  FlushInstructionCache(GetCurrentProcess(), target, sizeof(patch));
  *reinterpret_cast<volatile uint16_t*>(target) = *reinterpret_cast<uint16_t*>(patch);
  FlushInstructionCache(GetCurrentProcess(), target, 2);
  VirtualProtect(target, 16, old, &old);
  log("menus: UI build hook installed (player 2's grid drawn by the game)");
  return true;
}

void publish_grid(int page, const Choice& game) {
  GridView& v = grid_view;
  v.page = page;
  v.cursor_col = game.col;
  v.cursor_row = game.row;
  v.p1_locked = pick.p1_locked;
  v.p1_visible = pick.p1_locked && pick.p1.page == page;
  v.p1_col = pick.p1.col;
  v.p1_row = pick.p1.row;
  v.p2_visible = pick.p2.page == page;
  v.p2_locked = pick.p2_locked;
  v.p2_col = pick.p2.col;
  v.p2_row = pick.p2.row;
  v.active = true;
}

// The cursor slides between cells for a few frames (no frame on any cell): a second of grace.
bool on_mission_screen() { return at<uint8_t>(kMenuScreen) == kScreenMissions && GetTickCount64() - grid_seen < 1000; }

// Returns true while it owns slot 0 (the shared-menu copy must not run).
bool mission_pick_frame(volatile uint8_t* pads) {
  const LONG p2 = p2_pad;
  if (p2 <= 0 || !on_mission_screen()) {
    if (pick.active) {
      pick = MissionPick{};
      if (use_overlay) overlay::mission_marker(-1, 0, nullptr);
      status_line(nullptr);
    }
    grid_view.active = false;
    return false;
  }
  const int page = at<uint8_t>(kMissionPage) % kPages;
  const Choice game{page, at<uint8_t>(kMissionCol), at<uint8_t>(kMissionRow)};
  if (!pick.active) {
    pick = MissionPick{};
    pick.active = true;
    pick.p2 = game;
    update_marker(page);
    wchar_t msg[160];
    swprintf(msg, 160, L"%ls: elige tu misión (cruceta, LB/RB, A)", name_p2);
    notify(msg);
  }
  if (pick.driving) {  // walking the game's cursor to the winning mission
    if (pick.wait > 0) {
      --pick.wait;
      inject_slot0(pads, 0);
      return true;
    }
    const Choice& t = pick.target;
    if (game == t) {
      if (!pick.confirmed) {
        inject_slot0(pads, kA);
        pick.confirmed = true;
        pick.wait = 30;
      } else {
        pick.driving = false;
      }
      return true;
    }
    if (++pick.steps > 40) {  // the cursor did not follow: give control back
      log("mission pick: cursor did not reach %d/%d,%d (at %d/%d,%d)", t.page, t.col, t.row, game.page, game.col, game.row);
      pick.driving = false;
      return true;
    }
    uint32_t press;
    if (game.page != t.page) press = ((t.page - game.page + kPages) % kPages) <= kPages / 2 ? kRB : kLB;
    else press = game.col < t.col ? kRight : game.col > t.col ? kLeft : game.row < t.row ? kDown : kUp;
    inject_slot0(pads, press);
    pick.wait = (press == kRB || press == kLB) ? 12 : 6;
    return true;
  }
  // Player 2's marker.
  const uint32_t p2press = at<uint32_t>(kPads + p2 * kPadStride + 8);
  if (!pick.p2_locked) {
    Choice& c = pick.p2;
    if (p2press & kRB) { c.page = (c.page + 1) % kPages; c.row = c.row < kPageRows[c.page] ? c.row : 0; }
    if (p2press & kLB) { c.page = (c.page + kPages - 1) % kPages; c.row = c.row < kPageRows[c.page] ? c.row : 0; }
    if ((p2press & kLeft) && c.col > 0) --c.col;
    if ((p2press & kRight) && c.col < 4) ++c.col;
    if ((p2press & kUp) && c.row > 0) --c.row;
    if ((p2press & kDown) && c.row < kPageRows[c.page] - 1) ++c.row;
    if (p2press & kA) {
      pick.p2_locked = true;
      wchar_t msg[160];
      swprintf(msg, 160, L"%ls eligió %ls %d", name_p2, kPageNames[c.page], c.row * 5 + c.col + 1);
      notify(msg);
    }
  } else if (p2press & kB) {
    pick.p2_locked = false;
  }
  // Player 1: A locks (held back from the game until player 2 is ready), B unlocks. While locked, player 1's
  // cursor stays put and the shown page follows player 2.
  const uint32_t p1press = at<uint32_t>(kPads + 8);
  if (pick.p1_locked && !(p1press & kB)) {
    if (pick.wait > 0) --pick.wait;
    uint32_t press = 0;
    if (!pick.p2_locked && pick.p2.page != page && pick.wait == 0) {
      press = ((pick.p2.page - page + kPages) % kPages) <= kPages / 2 ? kRB : kLB;
      pick.wait = 12;
    }
    inject_slot0(pads, press);
  } else if (p1press & kA) {
    pick.p1 = game;
    pick.p1_locked = true;
    inject_slot0(pads, 0);
    if (!pick.p2_locked) {
      wchar_t msg[160];
      swprintf(msg, 160, L"Esperando a que %ls elija su misión", name_p2);
      notify(msg);
    }
  } else if ((p1press & kB) && pick.p1_locked) {
    pick.p1_locked = false;
    inject_slot0(pads, 0);
  }
  if (pick.p1_locked && pick.p2_locked) {  // both ready: go
    pick.p1_locked = false;
    pick.target = pick.p1;
    if (!(pick.p1 == pick.p2)) {
      if (!rng_state) rng_state = static_cast<uint32_t>(GetTickCount64()) | 1;
      rng_state ^= rng_state << 13; rng_state ^= rng_state >> 17; rng_state ^= rng_state << 5;
      const bool p2_wins = rng_state & 1;
      if (p2_wins) pick.target = pick.p2;
      wchar_t msg[160];
      swprintf(msg, 160, L"Misión elegida al azar: la de %ls", p2_wins ? name_p2 : name_p1);
      notify(msg);
      log("mission pick: P1 %d/%d,%d vs P2 %d/%d,%d -> %s", pick.p1.page, pick.p1.col, pick.p1.row, pick.p2.page,
          pick.p2.col, pick.p2.row, p2_wins ? "P2" : "P1");
    }
    pick.driving = true;
    pick.confirmed = false;
    pick.steps = 0;
    pick.wait = 3;
    inject_slot0(pads, 0);
  }
  update_marker(page);
  publish_grid(page, game);
  return true;
}

// Sound listener in split screen. The camera pick copies the camera of the frame being built into globals at
// 0x142ff1940 (+0x10 eye, +0x20 target, +0x30 up) and some 215 places read them. With the view alternating
// every frame, the sound code (block 0x1414b3000..0x1414d1000: distance attenuation and panning per object,
// listener frame from eye/target/up) heard from a different camera every frame, which made the sound
// stutter. Its 14 reads are redirected to a copy that only follows player 1's camera.
struct SoundRead {
  uint32_t rva;       // instruction
  uint8_t disp_off;   // offset of its disp32
  uint8_t size;       // instruction length
  uint32_t target;    // global it reads (rva)
};
constexpr SoundRead kSoundReads[] = {
    {0x14b3ca6, 3, 7, 0x2ff1950}, {0x14b3d49, 3, 7, 0x2ff1960}, {0x14bbc8c, 3, 7, 0x2ff1950},
    {0x14bbca4, 3, 7, 0x2ff1950}, {0x14ccd0d, 3, 7, 0x2ff1970}, {0x14ccf90, 3, 7, 0x2ff1970},
    {0x14ccfb0, 3, 7, 0x2ff1960}, {0x14cd0bd, 3, 7, 0x2ff1950}, {0x14cd14e, 3, 7, 0x2ff1950},
    {0x14cd26c, 3, 7, 0x2ff1950}, {0x14cd285, 3, 7, 0x2ff1950}, {0x14cdafb, 3, 7, 0x2ff1970},
    {0x14cde12, 3, 7, 0x2ff1950}, {0x14d0616, 3, 7, 0x2ff1950},
};
constexpr uintptr_t kCameraGlobals = 0x2ff1940, kViewIndex = 0x2ff2778;
uint8_t* sound_camera = nullptr;  // 0x40 bytes within +-2 GB of the image

bool install_sound_listener() {
  // Relative to the image: Windows loads it with ASLR (e.g. 0x7ff6........), Wine at 0x140000000.
  for (uintptr_t a = base + 0x7300000; a < base + 0x30000000 && !sound_camera; a += 0x100000)
    sound_camera = static_cast<uint8_t*>(VirtualAlloc(reinterpret_cast<void*>(a), 0x1000, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE));
  if (!sound_camera) {
    log("sound: no memory near the image, listener left as is");
    return false;
  }
  memcpy(sound_camera, reinterpret_cast<void*>(base + kCameraGlobals), 0x40);
  for (const SoundRead& r : kSoundReads) {  // check every instruction first
    const uintptr_t ins = base + r.rva, next = ins + r.size;
    int32_t disp;
    memcpy(&disp, reinterpret_cast<void*>(ins + r.disp_off), 4);
    if (next + disp != base + r.target) {
      log("sound: unexpected instruction at %p, listener left as is", reinterpret_cast<void*>(ins));
      return false;
    }
    const int64_t d = reinterpret_cast<int64_t>(sound_camera) - static_cast<int64_t>(next);
    if (d < INT32_MIN + 0x40 || d > INT32_MAX - 0x40) {
      log("sound: copy at %p out of rel32 reach, listener left as is", sound_camera);
      return false;
    }
  }
  for (const SoundRead& r : kSoundReads) {
    const uintptr_t ins = base + r.rva, next = ins + r.size;
    const int64_t d = reinterpret_cast<int64_t>(sound_camera + (r.target - kCameraGlobals)) - static_cast<int64_t>(next);
    const int32_t disp = static_cast<int32_t>(d);
    DWORD old;
    VirtualProtect(reinterpret_cast<void*>(ins), r.size, PAGE_EXECUTE_READWRITE, &old);
    InterlockedExchange(reinterpret_cast<volatile LONG*>(ins + r.disp_off), disp);
    VirtualProtect(reinterpret_cast<void*>(ins), r.size, old, &old);
  }
  FlushInstructionCache(GetCurrentProcess(), reinterpret_cast<void*>(base + 0x14b3000), 0x1e000);
  log("sound: listener follows player 1's camera (%zu reads redirected)", sizeof(kSoundReads) / sizeof(kSoundReads[0]));
  return true;
}

// Pad update hook (end of the update frame): the globals hold this frame's camera.
void update_sound_camera(bool split_on) {
  if (!sound_camera) return;
  if (split_on && at<int32_t>(kViewIndex) != 0) return;  // player 2's frame: keep player 1's camera
  memcpy(sound_camera, reinterpret_cast<const void*>(base + kCameraGlobals), 0x40);
}

// Character screen (player 2 joined): both columns at once. The game edits one column at a time (byte
// 0x141e65458) with the pad in slot 0; each frame the mod points the game at the column of whoever pressed
// something and hands it that player's pad. The row cursor (0x14215b6a6, column * 5 + row) is what the game
// actually edits: it goes along to that player's own row of their column (the column byte alone only sets the
// cursor's bounds; entering the screen from a mission's pause left both pads on player 1's column). A marks a player ready (B undoes it); with both ready the mod
// presses A for them. The other column is no longer drawn dimmed, and two ready boxes made of the game's
// own costume-row backgrounds (blue: player 1, red: player 2) sit at the bottom right (edit_char_buffer).
struct CharSelect {
  bool active = false, ready[2] = {false, false};
  int turn = 0, confirm_wait = 0;
  uint8_t row[2] = {0, 0};  // each player's row in their column
  uint32_t pend[2][4] = {};  // press/repeat masks not yet handed to the game (kPressMasks order; [0] unused)
} chars;

void point_char_screen(int column) {
  const uint8_t cur = at<uint8_t>(kCharCursor);
  if (cur < 10) chars.row[cur / 5] = cur % 5;
  if (cur / 5 != column) at<uint8_t>(kCharCursor) = static_cast<uint8_t>(column * 5 + chars.row[column]);
  at<uint8_t>(kCharColumn) = static_cast<uint8_t>(column);
}

bool char_select_frame(volatile uint8_t* pads, int p2) {
  if (p2 <= 0 || at<uint8_t>(kMenuScreen) != kScreenCharacters) {
    if (chars.active) chars = CharSelect{};
    chars_on = 0;
    return false;
  }
  if (!chars.active) {
    chars = CharSelect{};
    chars.active = true;
  }
  chars_on = 1;
  uint8_t slot[2][kPadStride];
  for (uintptr_t i = 0; i < kPadStride; ++i) {
    slot[0][i] = pads[i];
    slot[1][i] = pads[p2 * kPadStride + i];
  }
  auto mask = [&](int p, uintptr_t off) -> uint32_t& { return *reinterpret_cast<uint32_t*>(slot[p] + off); };
  bool acts[2];
  for (int p = 0; p < 2; ++p) {
    const uint32_t pressed = mask(p, 0x08);
    if ((pressed & kA) && !chars.ready[p]) chars.ready[p] = true;
    else if ((pressed & kB) && chars.ready[p]) {
      chars.ready[p] = false;
      for (uintptr_t m : kPressMasks) mask(p, m) &= ~kB;
    }
    for (uintptr_t m : kPressMasks) mask(p, m) &= ~(kA | kLB | kRB);
    // A press of the player the game is not serving this frame waits for their next turn instead of being lost.
    acts[p] = false;
    for (int k = 1; k < 4; ++k) {
      chars.pend[p][k] = chars.ready[p] ? 0 : chars.pend[p][k] | mask(p, kPressMasks[k]);
      if (chars.pend[p][k]) acts[p] = true;
    }
  }
  chars_ready_mask = (chars.ready[0] ? 1 : 0) | (chars.ready[1] ? 2 : 0);
  if (const uint8_t cur = at<uint8_t>(kCharCursor); cur < 10) chars.row[cur / 5] = cur % 5;
  char_rows[0] = chars.row[0];
  char_rows[1] = chars.row[1];
  if (chars.ready[0] && chars.ready[1]) {  // both ready: confirm once
    if (chars.confirm_wait == 0) {
      point_char_screen(0);
      inject_slot0(pads, kA);
      chars.confirm_wait = 30;
      log("character select: both players ready");
    } else {
      --chars.confirm_wait;
      inject_slot0(pads, 0);
    }
    return true;
  }
  int actor = -1;
  if (acts[0] && acts[1]) actor = chars.turn ^= 1;
  else if (acts[0]) actor = 0;
  else if (acts[1]) actor = 1;
  if (actor < 0) {
    inject_slot0(pads, 0);
    return true;
  }
  point_char_screen(actor);
  for (uintptr_t i = 0; i < kPadStride; ++i)
    if (i != 0x0e) pads[i] = slot[actor][i];
  for (int k = 1; k < 4; ++k) {
    at<uint32_t>(kPads + kPressMasks[k]) |= chars.pend[actor][k];
    chars.pend[actor][k] = 0;
  }
  return true;
}

uint64_t pad_update_hook(uint64_t a, uint64_t b, uint64_t c, uint64_t d) {
  volatile uint8_t* pads = &at<uint8_t>(kPads);
  // The update derives "held last frame" and the press masks from the slot contents, so hand it
  // back its own previous output; otherwise the swap would diff one pad against another.
  if (physical_valid) copy_slots(pads, physical);
  const uint64_t r = pad_update_original(a, b, c, d);
  copy_slots(physical, pads);
  physical_valid = true;
  update_sound_camera(split::running());
  split::update_frame();
  if (const LONG k = swap_slot; k > 0 && k < 4) {
    volatile uint8_t* s0 = pads;
    volatile uint8_t* sk = pads + k * kPadStride;
    for (uintptr_t i = 0; i < kPadStride; ++i) {
      const uint8_t t = s0[i];
      s0[i] = sk[i];
      sk[i] = t;
    }
  }
  for (uint8_t k = 0; k < 4; ++k) {
    snap_held[k] = at<uint32_t>(kPads + k * kPadStride);
    snap_connected[k] = at<uint8_t>(kPads + k * kPadStride + 0x0e);
  }
  snap_valid = true;
  quickmenu::frame(pads, p2_pad > 0 ? static_cast<int>(p2_pad) : -1, kPadStride);
  if (at<uint8_t>(kNumPlayers) >= 2) {  // in a Team Mission: each player keeps their own pad
    menu_owner = 0;
    return r;
  }
  if (char_select_frame(pads, p2_pad)) {
    menu_owner = 0;
    return r;
  }
  if (mission_pick_frame(pads)) {
    menu_owner = 0;
    return r;
  }
  if (pad_active(0)) menu_owner = 0;
  for (uint8_t k = 1; k < 4; ++k)
    if (pad_active(k)) menu_owner = k;
  if (menu_owner > 0)
    for (uintptr_t i = 0; i < kPadStride; ++i) pads[i] = pads[menu_owner * kPadStride + i];
  // Exclusive columns: once player 2 has joined, on the character screen each player drives only
  // their own column (player 1 JUGADOR/LB, player 2 COMPAÑERO/RB). The game has a single cursor, so
  // a pad that acts while the other column is active is muted and sends one press of its shoulder.
  if (inject_wait > 0) --inject_wait;
  const LONG p2 = p2_pad;
  if (p2 > 0 && at<uint8_t>(kMenuScreen) == kScreenCharacters) {
    const bool is_p2 = menu_owner == p2;
    const uint32_t own = is_p2 ? kRB : kLB, other = is_p2 ? kLB : kRB;
    for (uintptr_t m : kPressMasks) at<uint32_t>(kPads + m) = at<uint32_t>(kPads + m) & ~other;
    if (pad_active(0) && at<uint8_t>(kCharColumn) != (is_p2 ? 1 : 0)) {
      if (replay_owner != menu_owner) {
        for (uint32_t& v : replay) v = 0;
        replay_owner = menu_owner;
      }
      for (int i = 1; i < 4; ++i) replay[i] |= at<uint32_t>(kPads + kPressMasks[i]);
      for (uintptr_t i = 0; i < kPadStride; ++i)
        if (i != 0x0e) pads[i] = 0;
      if (inject_wait == 0) {
        for (uintptr_t m : kPressMasks) at<uint32_t>(kPads + m) = own;
        inject_wait = 15;
      }
    } else if (replay_owner == menu_owner) {  // column switched: deliver the muted presses
      for (int i = 1; i < 4; ++i) at<uint32_t>(kPads + kPressMasks[i]) = at<uint32_t>(kPads + kPressMasks[i]) | replay[i];
      replay_owner = -1;
    }
  } else {
    replay_owner = -1;
  }
  return r;
}

bool install_shared_menus() {
  uint8_t* target = reinterpret_cast<uint8_t*>(base + kPadUpdate);
  for (size_t i = 0; i < sizeof(kPadUpdateHead); ++i)
    if (target[i] != kPadUpdateHead[i]) {
      log("shared menus: unexpected bytes at pad update, not hooked");
      return false;
    }
  // Trampoline: original 17 bytes + jmp [rip] back to target+17.
  auto* tramp = static_cast<uint8_t*>(VirtualAlloc(nullptr, 64, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE));
  if (!tramp) return false;
  memcpy(tramp, kPadUpdateHead, sizeof(kPadUpdateHead));
  uint8_t* j = tramp + sizeof(kPadUpdateHead);
  j[0] = 0xff; j[1] = 0x25; memset(j + 2, 0, 4);
  const uint64_t back = reinterpret_cast<uint64_t>(target + sizeof(kPadUpdateHead));
  memcpy(j + 6, &back, 8);
  pad_update_original = reinterpret_cast<PadUpdateFn>(tramp);
  // Patch: park callers on a 2-byte self-jump, write the 14-byte absolute jmp, then release.
  DWORD old;
  if (!VirtualProtect(target, sizeof(kPadUpdateHead), PAGE_EXECUTE_READWRITE, &old)) return false;
  *reinterpret_cast<volatile uint16_t*>(target) = 0xfeeb;
  FlushInstructionCache(GetCurrentProcess(), target, 2);
  uint8_t patch[17];
  patch[0] = 0xff; patch[1] = 0x25; memset(patch + 2, 0, 4);
  const uint64_t to = reinterpret_cast<uint64_t>(&pad_update_hook);
  memcpy(patch + 6, &to, 8);
  patch[14] = patch[15] = patch[16] = 0x90;
  memcpy(target + 2, patch + 2, sizeof(patch) - 2);
  FlushInstructionCache(GetCurrentProcess(), target, sizeof(patch));
  *reinterpret_cast<volatile uint16_t*>(target) = *reinterpret_cast<uint16_t*>(patch);
  FlushInstructionCache(GetCurrentProcess(), target, 2);
  VirtualProtect(target, sizeof(kPadUpdateHead), old, &old);
  log("shared menus enabled: any controller can drive the menus (last used wins)");
  return true;
}

DWORD WINAPI worker(LPVOID) {
  Sleep(2000);
  if (!nm::sigma2_image_matches(base)) {
    log("version guard FAIL: unsupported executable, coop disabled");
    return 0;
  }
  log("NGS2Coop loaded: press BACK on a second controller to take over the partner");
  install_background_input();
  {
    wchar_t dir[MAX_PATH];
    plugin_file(dir, L"");
    split::init(base, dir, log);
    gametext::init(base, log);
  }
  const bool can_swap = install_shared_menus();
  install_ui_hook();
  install_sound_listener();
  quickmenu::init(base, log);
  wchar_t on[MAX_PATH];
  plugin_file(on, L"ngs2coop-overlay.txt");
  // Hook Present after ngs2lab (3 s) so its captures include the overlay. The hook also drives split screen, so it
  // is always installed; the overlay only gets text (and so only draws) in debugging.
  Sleep(2500);
  if (overlay::install(log)) use_overlay = GetFileAttributesW(on) != INVALID_FILE_ATTRIBUTES;
  wchar_t* const p1 = name_p1;
  wchar_t* const p2 = name_p2;
  wchar_t msg[256];
  steam_name(p1, 64);
  log("player 1 name from Steam: %ls", p1);
  bool was_connected[4] = {true, true, true, true};  // no "pad connected" notice for pads present at start
  bool was_in_mission = false;
  bool startup_hint = true;  // "press BACK" notice for the first 10 s (so whoever installs the mod sees it works)
  const ULONGLONG hint_start = GetTickCount64();
  gametext::startup(L"Co-op: el jugador 2 puede unirse pulsando BACK en su mando.");
  bool bound = false;
  int p2_slot = -1;           // pad slot of player 2, -1 = not joined (partner on AI)
  bool back_was_down[4] = {};
  bool sticks_were_down = false;
  ULONGLONG last_toggle = 0;  // debounce: touch/streamed buttons can double-fire
  uintptr_t last_char = 0;
  // Test sessions: plugin/ngs2coop-test-swap.txt holding a slot number makes that pad slot 0 (player 1),
  // e.g. a virtual pad while a physical one took slot 0 first.
  wchar_t test_swap_path[MAX_PATH];
  plugin_file(test_swap_path, L"ngs2coop-test-swap.txt");
  ULONGLONG test_swap_check = 0;
  for (;;) {
    Sleep(4);
    gametext::tick();
    if (GetTickCount64() - test_swap_check > 1000) {
      test_swap_check = GetTickCount64();
      if (FILE* f = _wfopen(test_swap_path, L"r")) {
        int k = 0;
        if (fscanf(f, "%d", &k) == 1 && k > 0 && k < 4 && swap_slot != k && pad(0).connected && pad(static_cast<uint8_t>(k)).connected) {
          swap_slot = k;
          log("test: pad slot %d swapped into slot 0", k);
        }
        fclose(f);
      }
    }
    // BACK on any connected pad joins (or, on player 2's pad, leaves). A press seen on two slots
    // at once is one physical pad exposed twice (e.g. Steam's virtual copy): ignore it.
    bool back_now[4];
    int backs = 0;
    for (int k = 0; k < 4; ++k) {
      const Pad pk = pad(k);
      back_now[k] = pk.connected && (pk.held & kBack);
      backs += back_now[k];
    }
    for (int k = 0; k < 4; ++k) {
      const bool edge = back_now[k] && !back_was_down[k];
      back_was_down[k] = back_now[k];
      if (!edge || backs > 1) continue;
      if (GetTickCount64() - last_toggle < 1000) continue;
      last_toggle = GetTickCount64();
      if (p2_slot == k) {
        p2_slot = -1;
        log("player 2 left (partner back to AI)");
        swprintf(msg, 256, L"%ls ha salido: el compañero vuelve a la IA", p2);
        notify(msg);
        continue;
      }
      if (p2_slot >= 0) continue;
      if (k != 0) {
        p2_slot = k;
        log("player 2 joined from pad slot %d", k);
        p2_name(p2, 64);
        swprintf(msg, 256, L"%ls se ha unido a la partida", p2);
        notify(msg);
        continue;
      }
      // BACK on slot 0: that pad becomes player 2 by trading slots with another connected pad
      // (pressing it again later on the new slot 0 trades back). The swap outlives leaving, so
      // player 1 keeps their pad when the partner returns to the AI.
      int other = -1;
      for (int j = 1; j < 4 && other < 0; ++j)
        if (pad(static_cast<uint8_t>(j)).connected) other = j;
      if (other < 0 || !can_swap) continue;
      const LONG cur = swap_slot;
      swap_slot = cur == other ? 0 : other;
      p2_slot = other;
      log("player 2 joined from pad slot 0 (now slot %d; slot swap %s)", other, swap_slot ? "on" : "off");
      p2_name(p2, 64);
      swprintf(msg, 256, L"%ls se ha unido a la partida", p2);
      notify(msg);
      for (bool& w : back_was_down) w = true;  // the presser's BACK shows up on the new slot
      break;
    }
    if (p2_slot >= 0 && !pad(static_cast<uint8_t>(p2_slot)).connected) {
      p2_slot = -1;
      log("player 2 pad disconnected (partner back to AI)");
      swprintf(msg, 256, L"Mando de %ls desconectado: el compañero vuelve a la IA", p2);
      notify(msg);
    }
    if (const LONG k = swap_slot; k > 0 && !(pad(0).connected && pad(static_cast<uint8_t>(k)).connected)) {
      swap_slot = 0;
      log("pad disconnected: slot swap off");
    }
    const bool joined = p2_slot >= 0;
    p2_pad = p2_slot;

    // Split screen while player 2 plays a Team Mission; L3 + R3 on either pad switches the layout.
    // The player count stays at 2 for ~20 s of results screens after a mission: also require the in-mission screen.
    // The pause menu changes the screen byte (5, 4) too, so a pause inside the mission keeps it on.
    const bool playing_together = joined && at<uint8_t>(kNumPlayers) >= 2 &&
                                  (at<uint8_t>(kMenuScreen) == kScreenPlaying || at<uint8_t>(kPausedFlag) != 0);
    split::set_active(playing_together);
    split::set_joined(joined);
    {
      bool sticks = false;
      for (int k = 0; k < 4; ++k) {
        const Pad pk = pad(static_cast<uint8_t>(k));
        sticks |= pk.connected && (pk.held & (kLS | kRS)) == (kLS | kRS);
      }
      if (sticks && !sticks_were_down && playing_together) {
        swprintf(msg, 256, L"Vista: %ls  (L3 + R3 para cambiar)", split::cycle());
        notify(msg);
      }
      sticks_were_down = sticks;
    }

    // Notices (drawn by the game, see gametext): a newly connected pad, mission start, names in the menus.
    {
      int pads = 0;
      bool fresh = false;
      for (int k = 0; k < 4; ++k) {
        const bool c = pad(static_cast<uint8_t>(k)).connected;
        pads += c;
        if (c && !was_connected[k] && k != 0) fresh = true;
        was_connected[k] = c;
      }
      const bool in_mission = at<uint8_t>(kNumPlayers) >= 2;
      if (!joined && pads >= 2 && (fresh || (in_mission && !was_in_mission)))
        notify(L"Jugador 2: pulsa BACK para unirte");
      was_in_mission = in_mission;
      const bool char_screen = !in_mission && at<uint8_t>(kMenuScreen) == kScreenCharacters;
      if (use_overlay) overlay::column_names(joined && char_screen ? p1 : nullptr, p2);
      // While the game starts, the autosave notice carries a "press BACK" line (so whoever installs the mod
      // sees it works); it goes once player 2 joins or after the first minute and a half.
      if (startup_hint && (joined || GetTickCount64() - hint_start > 90000)) {
        startup_hint = false;
        gametext::startup(nullptr);
      }
      if (use_overlay) overlay::notice(startup_hint && GetTickCount64() - hint_start < 10000 ? L"Jugador 2: pulsa BACK para unirte" : nullptr);
      const bool mission_screen = !in_mission && on_mission_screen();
      if (joined && mission_screen) {
        // the dual mission pick owns the line here
      } else if (joined && char_screen) {
        const LONG ready = chars_ready_mask;
        swprintf(msg, 256, L"P1 %ls: %ls  -  P2 %ls: %ls  -  @[pad:Decide] Listo", p1,
                 ready & 1 ? L"LISTO" : L"eligiendo", p2, ready & 2 ? L"LISTO" : L"eligiendo");
        status_line(msg);
      } else if (joined && !in_mission) {
        swprintf(msg, 256, L"P1 %ls  -  P2 %ls", p1, p2);
        status_line(msg);
      } else if (!joined && !in_mission && pads >= 2) {
        status_line(L"Jugador 2: pulsa BACK para unirte");
      } else {
        status_line(nullptr);
      }
    }

    const uintptr_t ch = partner_character();
    if (ch != last_char) {
      if (ch) log("partner character at %p", reinterpret_cast<void*>(base + ch));
      last_char = ch;
      bound = false;
    }
    if (!ch) continue;
    volatile uint8_t& port = at<uint8_t>(ch);
    if (joined) {
      if (at<uint8_t>(kPlayerPad + 1) != p2_slot) at<uint8_t>(kPlayerPad + 1) = static_cast<uint8_t>(p2_slot);
      if (port == kAiPort) {
        port = kP2Port;
        bound = true;
        log("partner bound to port %u (player 2)", kP2Port);
      }
    } else if (bound) {
      if (port == kP2Port) port = kAiPort;
      at<uint8_t>(kPlayerPad + 1) = 0;
      bound = false;
      log("partner returned to AI");
    }
  }
}
} // namespace

extern "C" BOOL WINAPI DllMain(HINSTANCE module, DWORD reason, LPVOID) {
  if (reason == DLL_PROCESS_ATTACH) {
    DisableThreadLibraryCalls(module);
    base = reinterpret_cast<uintptr_t>(GetModuleHandleW(nullptr));
    GetModuleFileNameW(module, log_path, MAX_PATH);
    wchar_t* s = wcsrchr(log_path, L'\\');
    if (s) lstrcpyW(s + 1, L"ngs2coop.log");
    const HANDLE t = CreateThread(nullptr, 0, worker, nullptr, 0, nullptr);
    if (t) CloseHandle(t);
  }
  return TRUE;
}
