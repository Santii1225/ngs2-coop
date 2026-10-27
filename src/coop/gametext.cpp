#include "gametext.hpp"
#include <windows.h>
#include <cstring>
#include <cstdio>
#include <cwchar>

namespace gametext {
namespace {
void log_nothing(const char*, ...) {}
void (*log)(const char*, ...) = log_nothing;

constexpr uintptr_t kGetString = 0x16374f0;
// mov [rsp+0x10], rbx; push rsi; sub rsp, 0x20; cmp ecx, 0xa; mov ebx, edx  (15 bytes, no RIP-relative operand)
constexpr uint8_t kHead[15] = {0x48, 0x89, 0x5c, 0x24, 0x10, 0x56, 0x48, 0x83, 0xec, 0x20, 0x83, 0xf9, 0x0a, 0x8b, 0xda};

using GetStringFn = const wchar_t* (*)(uint32_t, uint32_t);
GetStringFn original;
uintptr_t image;

// Help lines at the bottom of the menus: mission select, character screen, team mode select, chapter screen, load game.
constexpr uint32_t kHelpLines[] = {0x880005, 0x890008, 0x890001, 0x10076, 0x10056};
constexpr uint32_t kAutosaveNotice = 0x8007a;

// Texts are written by the worker thread and read by the game's threads: each update goes to the next of a ring
// of buffers and only then is published, so a reader never sees a half-written string.
struct Text {
  wchar_t buf[8][320];
  volatile LONG cur = -1;
  void set(const wchar_t* t) {
    if (!t || !*t) { cur = -1; return; }
    const LONG next = (cur + 1) & 7;
    lstrcpynW(buf[next], t, 320);
    cur = next;
  }
  const wchar_t* get() const { const LONG c = cur; return c < 0 ? nullptr : buf[c]; }
} msg, persistent, extra, joined;
volatile ULONGLONG msg_until = 0;

// Some screens (character setup) ask for their help line once and keep the pointer, so each help line is served
// from a buffer of ours that compose() rewrites in place: the game draws whatever it holds on the next frame.
// The game's own text is copied too: tick() runs on the worker thread and the game frees its string tables when it
// loads a mission, so a kept pointer would be read after it is gone (crash in wcscmp, seen 2026-10-10).
struct HelpLine {
  bool has_original = false;
  wchar_t original[320] = {};
  wchar_t buf[320] = {};
} help[sizeof(kHelpLines) / sizeof(kHelpLines[0])];

void compose(HelpLine& h) {
  const wchar_t* want = h.has_original ? h.original : nullptr;
  if (const wchar_t* m = msg.get(); m && GetTickCount64() < msg_until) want = m;
  else if (const wchar_t* p = persistent.get()) want = p;
  if (!want || !wcscmp(want, h.buf)) return;
  // Shorter text first gets its terminator, so a reader mid-copy never runs past the end.
  size_t n = wcslen(want);
  if (n > 319) n = 319;
  h.buf[n] = 0;
  for (size_t i = 0; i < n; ++i) h.buf[i] = want[i];
}

// The scrolling banner of mission hints (0x1414d9bd0(id, keep): looks the text up and keeps the pointer while it
// builds and scrolls the words). The mod shows it with the id of "your partner is down" (0x12001f) and serves
// its own text for that one lookup.
// 0x1414d9ba0 closes it (state 0x141e8c650 -> 4); [0x141e8c888] = the text it shows. Ours closes after 4 s,
// unless the game has put up another one.
constexpr uintptr_t kBanner = 0x14d9bd0, kBannerClose = 0x14d9ba0, kBannerShown = 0x1e8c888;
constexpr uint32_t kBannerId = 0x12001f;
using BannerFn = void (*)(uint32_t, uint8_t);
wchar_t banner_text[2][160];
int banner_slot = 0;
const wchar_t* banner_override = nullptr;
ULONGLONG banner_until = 0;

const wchar_t* hook(uint32_t lang, uint32_t id) {
  if (banner_override && id == kBannerId) return banner_override;
  const wchar_t* text = original(lang, id);
  for (size_t i = 0; i < sizeof(kHelpLines) / sizeof(kHelpLines[0]); ++i) {
    if (id != kHelpLines[i] || !text) continue;
    if (wcsncmp(text, help[i].original, 319)) lstrcpynW(help[i].original, text, 320);
    help[i].has_original = true;
    compose(help[i]);
    return help[i].buf;
  }
  if (id == kAutosaveNotice && text) {
    if (const wchar_t* e = extra.get()) {
      wchar_t both[320];
      _snwprintf(both, 320, L"%ls\n%ls", text, e);
      both[319] = 0;
      joined.set(both);
      return joined.get();
    }
  }
  return text;
}
} // namespace

void message(const wchar_t* text, unsigned ms) {
  msg.set(text);
  msg_until = GetTickCount64() + ms;
}
void line(const wchar_t* text) { persistent.set(text); }
void banner(const wchar_t* text) {
  if (!original || !text) return;
  banner_slot ^= 1;  // the game may still hold the previous one
  lstrcpynW(banner_text[banner_slot], text, 160);
  banner_override = banner_text[banner_slot];
  reinterpret_cast<BannerFn>(image + kBanner)(kBannerId, 0);
  banner_override = nullptr;
  banner_until = GetTickCount64() + 4000;
}

void banner_tick() {
  if (!banner_until || GetTickCount64() < banner_until) return;
  banner_until = 0;
  const auto shown = *reinterpret_cast<const wchar_t* volatile*>(image + kBannerShown);
  if (shown == banner_text[0] || shown == banner_text[1]) reinterpret_cast<void (*)()>(image + kBannerClose)();
}

void tick() {
  for (HelpLine& h : help)
    if (h.has_original) compose(h);
}
void startup(const wchar_t* text) { extra.set(text); }

bool init(uintptr_t base, void (*log_fn)(const char*, ...)) {
  log = log_fn;
  image = base;
  auto* target = reinterpret_cast<uint8_t*>(base + kGetString);
  if (memcmp(target, kHead, sizeof(kHead))) {
    log("gametext: unexpected bytes at the text lookup, not hooked");
    return false;
  }
  auto* tramp = static_cast<uint8_t*>(VirtualAlloc(nullptr, 64, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE));
  if (!tramp) return false;
  memcpy(tramp, kHead, sizeof(kHead));
  uint8_t* j = tramp + sizeof(kHead);
  j[0] = 0xff; j[1] = 0x25; memset(j + 2, 0, 4);
  const uint64_t back = reinterpret_cast<uint64_t>(target + sizeof(kHead));
  memcpy(j + 6, &back, 8);
  original = reinterpret_cast<GetStringFn>(tramp);
  // Park callers on a 2-byte self-jump, write the 14-byte absolute jmp, then release.
  DWORD old;
  if (!VirtualProtect(target, sizeof(kHead), PAGE_EXECUTE_READWRITE, &old)) return false;
  *reinterpret_cast<volatile uint16_t*>(target) = 0xfeeb;
  FlushInstructionCache(GetCurrentProcess(), target, 2);
  uint8_t patch[15];
  patch[0] = 0xff; patch[1] = 0x25; memset(patch + 2, 0, 4);
  const uint64_t to = reinterpret_cast<uint64_t>(&hook);
  memcpy(patch + 6, &to, 8);
  patch[14] = 0x90;
  memcpy(target + 2, patch + 2, sizeof(patch) - 2);
  FlushInstructionCache(GetCurrentProcess(), target, sizeof(patch));
  *reinterpret_cast<volatile uint16_t*>(target) = *reinterpret_cast<uint16_t*>(patch);
  FlushInstructionCache(GetCurrentProcess(), target, 2);
  VirtualProtect(target, sizeof(kHead), old, &old);
  log("gametext: text lookup hooked (notices on the menu help lines)");
  return true;
}
} // namespace gametext
