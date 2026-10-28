#define WIN32_LEAN_AND_MEAN
#include "split.hpp"
#include "overlay.hpp"
#include <windows.h>
#include <d3d11_1.h>
#include <d3dcompiler.h>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <initializer_list>

namespace split {
namespace {
void log_nothing(const char*, ...) {}
void (*log)(const char*, ...) = log_nothing;
uintptr_t base;
wchar_t trace_flag[MAX_PATH], config_path[MAX_PATH];

template<class T> volatile T& at(uintptr_t rva) { return *reinterpret_cast<volatile T*>(base + rva); }

// ---- camera state (docs/CAMERA_RESEARCH.md) ------------------------------------------------------
constexpr uintptr_t kView = 0x2ff2778;         // int: which camera slot the renderer uses (0 = player 1)
constexpr uintptr_t kCameraMgrPtr = 0x2ff2758;  // [0x142ff1890 + 0xec8]: camera manager, 8 slots
constexpr uintptr_t kCameraStride = 0x16a0, kCameraEye = 0x80;
constexpr uintptr_t kRenderEye = 0x1e65c80 + 0x260;  // the renderer's camera for the frame being drawn
constexpr uintptr_t kPaused = 0x1e3a8c2;              // byte: 1 while the pause menu is open
// Frame packets: the update thread fills packet [kPacketIdx] with the chosen camera (eye at +0x40) and the
// renderer draws the other one (0x141440260: packet = idx ^ 1). The mod tags each packet with its view
// when the update thread finishes a frame, and the renderer's frame looks up the tag of the packet it draws,
// checking that the eye still matches bit for bit. (The renderer's own eye, kRenderEye, is adjusted in
// some stages and stops matching either camera there.)
constexpr uintptr_t kPacketIdx = 0x2ff2750, kPackets = 0x2ff20d0, kPacketStride = 0x360, kPacketEye = 0x40;
struct PacketTag {
  volatile LONG view;
  volatile uint32_t eye[3];
};
PacketTag tags[2] = {{-1, {}}, {-1, {}}};

void tag_packet(int32_t view) {
  const uint32_t idx = at<uint32_t>(kPacketIdx) & 1;
  const uintptr_t eye = kPackets + idx * kPacketStride + kPacketEye;
  tags[idx].view = -1;
  for (int i = 0; i < 3; ++i) tags[idx].eye[i] = at<uint32_t>(eye + i * 4);
  tags[idx].view = view;
}

int tagged_view() {
  const uint32_t idx = (at<uint32_t>(kPacketIdx) & 1) ^ 1;
  const uintptr_t eye = kPackets + idx * kPacketStride + kPacketEye;
  const LONG v = tags[idx].view;
  for (int i = 0; i < 3; ++i)
    if (tags[idx].eye[i] != at<uint32_t>(eye + i * 4)) return -1;
  return v;
}

// Player gauges of the HUD (portrait, health, ki, ninpo), docs/SPLITSCREEN.md. The game keeps one per
// player and updates both every frame; player 2's is closed (state +0xe98 = 4) and, open, sits on top of
// player 1's, 16 px left and 17 px down. In split screen the mod opens it at player 1's position and lets
// each frame draw only the gauge of the player whose camera it renders. Opening and closing go through the
// game's own functions: each state has its own layout ([+0xe90]: open 0x141821480, closed 0x141821670, the
// partner's compact one with a thin health bar), and they rebuild the gauge's elements (0x14153bbd0) for it.
constexpr uintptr_t kGameObjects = 0x3195300, kPlayerActor = 0x211e760;
constexpr uintptr_t kGauge[2] = {0x1ecbb20, 0x1ecc9d0};  // +0x00: game_object entry of its player
constexpr uintptr_t kGaugeState = 0xe98, kGaugeScale = 0x230, kGaugeOffset = 0x2c0;
constexpr uintptr_t kGaugeDraw = 0x153aa80;
constexpr uint8_t kGaugeDrawHead[15] = {0x48, 0x8b, 0xc4, 0x55, 0x48, 0x8d, 0x68, 0xa1, 0x48, 0x81, 0xec, 0xd0, 0x00, 0x00, 0x00};
constexpr uintptr_t kGaugeOpen = 0x153a850, kGaugeClose = 0x153a800;  // (gauge): state 1 / 4 with its layout
using GaugeDrawFn = void (*)(uintptr_t);
GaugeDrawFn gauge_draw_original;
volatile bool gauge_split = false;  // update thread: player 2's gauge is open, one gauge per frame
uint32_t saved_state;
uint64_t saved_scale, saved_offset;

bool gauges_match() {
  const uint8_t a0 = at<uint8_t>(kPlayerActor), a1 = at<uint8_t>(kPlayerActor + 1);
  return a0 < 0xa0 && a1 < 0xa0 && at<uint64_t>(kGauge[0]) == base + kGameObjects + a0 * 0x30 &&
         at<uint64_t>(kGauge[1]) == base + kGameObjects + a1 * 0x30;
}

void build_p2_ninpo(bool open);  // ninpo icons, below

void open_p2_gauge(bool on) {
  const uintptr_t g = kGauge[1];
  if (on) {
    saved_state = at<uint32_t>(g + kGaugeState);
    saved_scale = at<uint64_t>(g + kGaugeScale);
    saved_offset = at<uint64_t>(g + kGaugeOffset);
    reinterpret_cast<GaugeDrawFn>(base + kGaugeOpen)(base + g);
    at<uint64_t>(g + kGaugeScale) = 0;
    at<uint64_t>(g + kGaugeOffset) = 0;
  } else {
    if (saved_state == 4) reinterpret_cast<GaugeDrawFn>(base + kGaugeClose)(base + g);
    else at<uint32_t>(g + kGaugeState) = saved_state;
    at<uint64_t>(g + kGaugeScale) = saved_scale;
    at<uint64_t>(g + kGaugeOffset) = saved_offset;
  }
  build_p2_ninpo(on);
  gauge_split = on;
}

// The HUD is built on the update thread after the camera pick and before the pad update, so the view
// variable holds the camera of the frame being built.
void gauge_draw_hook(uintptr_t gauge) {
  if (gauge_split) {
    const int view = at<int32_t>(kView) ? 1 : 0;
    if (gauge == base + kGauge[view ^ 1]) return;
  }
  gauge_draw_original(gauge);
}

// Copies `len` bytes of a function's head to a trampoline that jumps back after them, then points the head at
// `to` (callers parked on a 2-byte self-jump while the 14-byte absolute jmp is written, as main.cpp does).
uintptr_t hook_head(uintptr_t target_addr, const uint8_t* head, size_t len, uintptr_t to) {
  auto* target = reinterpret_cast<uint8_t*>(target_addr);
  if (len < 14 || memcmp(target, head, len)) return 0;
  auto* tramp = static_cast<uint8_t*>(VirtualAlloc(nullptr, 64, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE));
  if (!tramp) return 0;
  memcpy(tramp, head, len);
  uint8_t* j = tramp + len;
  j[0] = 0xff; j[1] = 0x25; memset(j + 2, 0, 4);
  const uint64_t back = reinterpret_cast<uint64_t>(target + len);
  memcpy(j + 6, &back, 8);
  DWORD old;
  if (!VirtualProtect(target, len, PAGE_EXECUTE_READWRITE, &old)) return 0;
  *reinterpret_cast<volatile uint16_t*>(target) = 0xfeeb;
  FlushInstructionCache(GetCurrentProcess(), target, 2);
  uint8_t patch[32];
  patch[0] = 0xff; patch[1] = 0x25; memset(patch + 2, 0, 4);
  const uint64_t dest = to;
  memcpy(patch + 6, &dest, 8);
  memset(patch + 14, 0x90, len - 14);
  memcpy(target + 2, patch + 2, len - 2);
  FlushInstructionCache(GetCurrentProcess(), target, len);
  *reinterpret_cast<volatile uint16_t*>(target) = *reinterpret_cast<uint16_t*>(patch);
  FlushInstructionCache(GetCurrentProcess(), target, 2);
  VirtualProtect(target, len, old, &old);
  return reinterpret_cast<uintptr_t>(tramp);
}

bool install_gauge_hook() {
  const uintptr_t tramp = hook_head(base + kGaugeDraw, kGaugeDrawHead, sizeof(kGaugeDrawHead),
                                    reinterpret_cast<uintptr_t>(&gauge_draw_hook));
  if (!tramp) {
    log("split: unexpected bytes at the gauge draw, player 2 HUD off");
    return false;
  }
  gauge_draw_original = reinterpret_cast<GaugeDrawFn>(tramp);
  return true;
}

// The ninpo icons under the gauges: one object per player (0x141ecdac0 player 1's, 0x141ed24f0 player 2's; +0x4a18
// = game_object entry of its player, +0x4a20 = layout), built by 0x141538a10(icons, entry, open) from that player's
// ninpo (+0x5ada current, +0x5ad8 max, 200 per icon) and drawn every frame by 0x1415387e0 from the HUD draw
// (calls at 0x140cd16ae / 0x140cd16bb, tail jump at 0x140cd16db). The HUD builds player 2's closed, so player 2's
// view showed player 1's icons. In split screen player 2's is rebuilt open (same layout, so the same place) and each
// frame draws only the icons of the player whose camera it renders.
constexpr uintptr_t kNinpoIcons[2] = {0x1ecdac0, 0x1ed24f0};
constexpr uintptr_t kNinpoEntry = 0x4a18, kNinpoLayout = 0x4a20, kNinpoOpenLayout = 0x1821510;
constexpr uintptr_t kNinpoBuild = 0x1538a10, kNinpoDraw = 0x15387e0;
constexpr uintptr_t kNinpoDrawSites[3] = {0xcd16ae, 0xcd16bb, 0xcd16db};
using NinpoBuildFn = void (*)(uintptr_t, uintptr_t, bool);
bool ninpo_hooked = false;

void build_p2_ninpo(bool open) {
  const uintptr_t icons = base + kNinpoIcons[1];
  const uintptr_t entry = at<uint64_t>(kNinpoIcons[1] + kNinpoEntry);
  if (ninpo_hooked && entry) reinterpret_cast<NinpoBuildFn>(base + kNinpoBuild)(icons, entry, open);
}

void ninpo_draw_hook(uintptr_t icons) {
  if (gauge_split) {
    const int view = at<int32_t>(kView) ? 1 : 0;
    if (icons == base + kNinpoIcons[view ^ 1]) return;
  }
  reinterpret_cast<GaugeDrawFn>(base + kNinpoDraw)(icons);
}

bool install_ninpo_hook() {
  for (uintptr_t site : kNinpoDrawSites) {
    const auto* c = reinterpret_cast<const uint8_t*>(base + site);
    int32_t rel;
    memcpy(&rel, c + 1, 4);
    if ((c[0] != 0xe8 && c[0] != 0xe9) || base + site + 5 + rel != base + kNinpoDraw) {
      log("split: unexpected bytes at the ninpo icons draw, player 2's view shows player 1's ninpo");
      return false;
    }
  }
  uint8_t* stub = nullptr;  // a 14-byte absolute jump within rel32 reach of the image
  for (uintptr_t a = base + 0x7300000; !stub && a < base + 0x30000000; a += 0x100000)
    stub = static_cast<uint8_t*>(VirtualAlloc(reinterpret_cast<void*>(a), 0x1000, MEM_RESERVE | MEM_COMMIT, PAGE_EXECUTE_READWRITE));
  if (!stub) return false;
  stub[0] = 0xff; stub[1] = 0x25; memset(stub + 2, 0, 4);
  const uint64_t to = reinterpret_cast<uint64_t>(&ninpo_draw_hook);
  memcpy(stub + 6, &to, 8);
  FlushInstructionCache(GetCurrentProcess(), stub, 14);
  for (uintptr_t site : kNinpoDrawSites) {  // calls and the tail jump keep their opcode, only the target moves
    auto* c = reinterpret_cast<uint8_t*>(base + site);
    const int32_t rel = static_cast<int32_t>(reinterpret_cast<int64_t>(stub) - static_cast<int64_t>(base + site + 5));
    DWORD old;
    VirtualProtect(c, 5, PAGE_EXECUTE_READWRITE, &old);
    memcpy(c + 1, &rel, 4);
    VirtualProtect(c, 5, old, &old);
    FlushInstructionCache(GetCurrentProcess(), c, 5);
  }
  return true;
}

// The faces above the gauges: two objects drawn every frame (0x141539600, from the HUD draw 0x140cd1540), each
// tied to a player ([+0x7a0] = game_object entry): player 1's in front, player 2's behind it, 88 px left. A face
// object holds its character (sprite id at +0x00 and +0x230), its tint and blink when that player is down (colour
// per element at +0xc0.., +0x1d0.., +0x2f0..; flags at +0x7a8) and its place (offsets at +0x50, +0x160, +0x280,
// +0x790). On player 2's frames the two objects trade everything but their place while they draw, so player 2
// sees their own character in front, player 1's behind, and the red "partner down" tint on whoever is down.
constexpr uintptr_t kFaces[2] = {0x1ed9340, 0x1ed9b00};  // player 1's, player 2's
constexpr uintptr_t kFaceSize = 0x7c0;
constexpr uintptr_t kFacePlace[4] = {0x50, 0x160, 0x280, 0x790};  // 8 bytes each, kept
constexpr uintptr_t kFaceEntry = 0x7a0;
constexpr uintptr_t kFaceDraw = 0x1539600;
constexpr uint8_t kFaceDrawHead[20] = {0x48, 0x89, 0x5c, 0x24, 0x08, 0x57, 0x48, 0x83, 0xec, 0x30,
                                       0x48, 0x8b, 0xd9, 0x48, 0x81, 0xc1, 0x40, 0x02, 0x00, 0x00};
GaugeDrawFn face_draw_original;

void swap_faces() {
  for (uintptr_t f = 0; f < kFaceSize; f += 8) {
    bool place = false;
    for (uintptr_t k : kFacePlace) place |= f == k;
    if (place) continue;
    const uint64_t t = at<uint64_t>(kFaces[0] + f);
    at<uint64_t>(kFaces[0] + f) = at<uint64_t>(kFaces[1] + f);
    at<uint64_t>(kFaces[1] + f) = t;
  }
}

void face_draw_hook(uintptr_t face) {
  const uint8_t a0 = at<uint8_t>(kPlayerActor), a1 = at<uint8_t>(kPlayerActor + 1);
  const bool swap = gauge_split && at<int32_t>(kView) != 0 && a0 < 0xa0 && a1 < 0xa0 &&
                    at<uint64_t>(kFaces[0] + kFaceEntry) == base + kGameObjects + a0 * 0x30 &&
                    at<uint64_t>(kFaces[1] + kFaceEntry) == base + kGameObjects + a1 * 0x30;
  if (swap) swap_faces();
  face_draw_original(face);
  if (swap) swap_faces();
}

bool install_face_hook() {
  const uintptr_t tramp = hook_head(base + kFaceDraw, kFaceDrawHead, sizeof(kFaceDrawHead),
                                    reinterpret_cast<uintptr_t>(&face_draw_hook));
  if (!tramp) {
    log("split: unexpected bytes at the face draw, faces not swapped for player 2");
    return false;
  }
  face_draw_original = reinterpret_cast<GaugeDrawFn>(tramp);
  return true;
}

// The aim reticle (bow / projectiles, hold LT): a HUD module (instance 0x141e92f40, vtable 0x1418fd5d0: [1] build,
// [2] close, [3] update 0x140c62590, [4] draw 0x140c62870; 0x130 bytes: +0x08/+0x09/+0x0a open/updated/drawn flags,
// a sprite at +0x10, +0x120 the player's aim object, +0x12c its player, +0x12d drawn). The HUD keeps the open modules
// in a list (0x146798170, 16-byte entries {index, module}, count at 0x146798330; each frame 0x1415070e0 updates them
// and 0x141506e00 draws them). The game has one reticle, opened (index 2) only while the local player
// [0x14211e757] aims ([0x1435c3bc0 + player*0x340] = their aim object), and its update read that byte: player 1's
// reticle showed on both views and player 2 never had one. Now the update reads the module's own player (+0x12c, the
// movzx at 0x140c625b1); player 1's draws only on player 1's frames; and in split screen the mod keeps a second
// module, bound to player 2 and drawn only on their frames, in the list under index 0x4d (one the game never opens).
// (Swapping one module's state between players broke the sprite draw list: endless loop at 0x141690170. The sprite
// holds a pointer to its instance at +0xf0; the second module starts without one and gets its own.)
constexpr uintptr_t kReticle = 0x1e92f40, kReticleVtable = 0x18fd5d0, kReticleSize = 0x130;
constexpr uintptr_t kReticlePlayerRead = 0xc625b1, kReticleSetAnim = 0xc628c0;
constexpr uint8_t kReticlePlayerReadBytes[7] = {0x0f, 0xb6, 0x15, 0x9f, 0xc1, 0x4b, 0x01};
constexpr uint8_t kReticlePlayerReadFix[7] = {0x0f, 0xb6, 0x91, 0x2c, 0x01, 0x00, 0x00};  // movzx edx, [rcx+0x12c]
constexpr uintptr_t kHudActive = 0x6798170, kHudActiveCount = 0x6798330, kHudActiveMax = 0x1c;
constexpr int32_t kP2ReticleIndex = 0x4d;
constexpr uintptr_t kPlayerSet = 0x35c3e94, kReticleAnims = 0x1815a28;  // set index per player; 12 bytes of anims per set
GaugeDrawFn reticle_draw_original;
uint64_t p2_reticle_vtable[8];
uint8_t* p2_reticle = nullptr;  // 0x130 bytes, 16-aligned
bool p2_reticle_listed = false;

void reticle_draw_hook(uintptr_t module) {  // player 1's module: not on player 2's frames
  if (gauge_split && at<int32_t>(kView)) return;
  reticle_draw_original(module);
}
void p2_reticle_draw(uintptr_t module) {  // the mod's module: only on player 2's frames
  if (gauge_split && at<int32_t>(kView)) reticle_draw_original(module);
}

int find_hud_entry(uint64_t module) {
  const uint64_t n = at<uint64_t>(kHudActiveCount);
  for (uint64_t i = 0; i < n && i < kHudActiveMax; ++i)
    if (at<uint64_t>(kHudActive + i * 16 + 8) == module) return static_cast<int>(i);
  return -1;
}

void reticle_frame_end() {  // update thread, after the frame's HUD draw
  if (!p2_reticle) return;
  const uint64_t mine = reinterpret_cast<uint64_t>(p2_reticle);
  if (p2_reticle_listed && find_hud_entry(mine) < 0) p2_reticle_listed = false;  // the game cleared the list
  const bool want = gauge_split && at<uint8_t>(0x21544fa) == 74;
  if (want && !p2_reticle_listed) {
    const uint64_t n = at<uint64_t>(kHudActiveCount);
    if (n >= kHudActiveMax) return;
    memcpy(p2_reticle, reinterpret_cast<const void*>(base + kReticle), kReticleSize);
    *reinterpret_cast<uint64_t*>(p2_reticle) = reinterpret_cast<uint64_t>(p2_reticle_vtable);
    p2_reticle[0x08] = 0;  // as the HUD's open does: +0x08 0, +0x09 1, +0x0a 1
    p2_reticle[0x09] = 1;
    p2_reticle[0x0a] = 1;
    memset(p2_reticle + 0x100, 0, 8);  // the sprite's instance (+0xf0 of the sprite): its own, from the anim below
    memset(p2_reticle + 0x120, 0, 8);
    p2_reticle[0x12c] = 1;
    p2_reticle[0x12d] = 0;
    const int32_t set = at<int32_t>(kPlayerSet + 0x340);
    reinterpret_cast<void (*)(uintptr_t, uint32_t)>(base + kReticleSetAnim)(mine, at<uint32_t>(kReticleAnims + set * 12));
    at<int32_t>(kHudActive + n * 16) = kP2ReticleIndex;
    at<uint64_t>(kHudActive + n * 16 + 8) = mine;
    at<uint64_t>(kHudActiveCount) = n + 1;
    p2_reticle_listed = true;
  } else if (!want && p2_reticle_listed) {
    const int i = find_hud_entry(mine);
    const uint64_t n = at<uint64_t>(kHudActiveCount);
    if (i >= 0) {
      p2_reticle[0x08] = 0;  // closed as the HUD does (+0x08 0, then [2]): the sprite gives its instance back
      reinterpret_cast<GaugeDrawFn>(p2_reticle_vtable[2])(mine);
      for (uint64_t k = i; k + 1 < n; ++k) {
        at<uint64_t>(kHudActive + k * 16) = at<uint64_t>(kHudActive + (k + 1) * 16);
        at<uint64_t>(kHudActive + k * 16 + 8) = at<uint64_t>(kHudActive + (k + 1) * 16 + 8);
      }
      at<uint64_t>(kHudActiveCount) = n - 1;
    }
    p2_reticle_listed = false;
  }
}

bool install_reticle_hook() {
  auto* read = reinterpret_cast<uint8_t*>(base + kReticlePlayerRead);
  auto* vt = reinterpret_cast<uint64_t*>(base + kReticleVtable);
  if (memcmp(read, kReticlePlayerReadBytes, sizeof(kReticlePlayerReadBytes)) || vt[3] != base + 0xc62590 ||
      vt[4] != base + 0xc62870) {
    log("split: unexpected bytes at the aim reticle, player 2 has no reticle of their own");
    return false;
  }
  p2_reticle = static_cast<uint8_t*>(VirtualAlloc(nullptr, 0x1000, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE));
  if (!p2_reticle) return false;
  reticle_draw_original = reinterpret_cast<GaugeDrawFn>(vt[4]);
  memcpy(p2_reticle_vtable, vt, sizeof(p2_reticle_vtable));
  p2_reticle_vtable[4] = reinterpret_cast<uint64_t>(&p2_reticle_draw);
  DWORD old;
  VirtualProtect(read, sizeof(kReticlePlayerReadFix), PAGE_EXECUTE_READWRITE, &old);
  memcpy(read, kReticlePlayerReadFix, sizeof(kReticlePlayerReadFix));
  VirtualProtect(read, sizeof(kReticlePlayerReadFix), old, &old);
  FlushInstructionCache(GetCurrentProcess(), read, sizeof(kReticlePlayerReadFix));
  VirtualProtect(vt + 4, 8, PAGE_READWRITE, &old);
  vt[4] = reinterpret_cast<uint64_t>(&reticle_draw_hook);
  VirtualProtect(vt + 4, 8, old, &old);
  return true;
}

bool gauge_hooked = false;

volatile LONG want_active = 0;
volatile LONG p2_joined = 0;  // player 2 is in (menus included): their monitor shows the game from then on
volatile LONG user_mode = Auto;  // Auto, Vertical, Horizontal or Dual (as chosen; Dual needs 2 monitors)
volatile LONG monitors = 1;  // usable monitors (ignored ones left out)
// Monitors the mod never uses, by size in the game's pixels (`ignore WxH` lines in ngs2coop-split.txt),
// e.g. a tablet shown as a virtual display. Wine names every monitor "Generic Non-PnP Monitor".
struct Size {
  LONG w, h;
};
Size ignored[8];
int ignored_count = 0;

// Which camera the frame being rendered uses: the renderer's eye matches one camera slot's eye in x/z
// (its height differs). -1 when the two cameras are too close to tell (their images look alike then).
int classify_view() {
  const uint64_t mgr = at<uint64_t>(kCameraMgrPtr);
  if (mgr < 0x140000000ull) return -1;
  const volatile float* r = &at<float>(kRenderEye);
  const auto* c0 = reinterpret_cast<const volatile float*>(mgr + kCameraEye);
  const auto* c1 = reinterpret_cast<const volatile float*>(mgr + kCameraStride + kCameraEye);
  const float d0 = (r[0] - c0[0]) * (r[0] - c0[0]) + (r[2] - c0[2]) * (r[2] - c0[2]);
  const float d1 = (r[0] - c1[0]) * (r[0] - c1[0]) + (r[2] - c1[2]) * (r[2] - c1[2]);
  const float sep = (c0[0] - c1[0]) * (c0[0] - c1[0]) + (c0[2] - c1[2]) * (c0[2] - c1[2]);
  if (!(sep > 0.04f)) return -1;  // cameras within 0.2 units
  static int dbg = 0;
  if (dbg < 40 && GetFileAttributesW(trace_flag) != INVALID_FILE_ATTRIBUTES) {
    ++dbg;
    log("split: classify view=%d d0=%.3f d1=%.3f sep=%.2f", at<int32_t>(kView), d0, d1, sep);
  }
  return d0 <= d1 ? 0 : 1;
}

// ---- GPU resources --------------------------------------------------------------------------------
struct Target {
  ID3D11Texture2D* tex = nullptr;
  ID3D11ShaderResourceView* srv = nullptr;
  ID3D11RenderTargetView* rtv = nullptr;  // mip 0
  UINT w = 0, h = 0;
  bool valid = false, dirty = false;
  void release() {
    if (srv) srv->Release();
    if (rtv) rtv->Release();
    if (tex) tex->Release();
    *this = Target{};
  }
};

ID3D11Device* device;
ID3D11DeviceContext* immediate;
ID3DDeviceContextState* state;
ID3D11VertexShader* vs;
ID3D11PixelShader* ps;
ID3D11Buffer* cbuf;
ID3D11BlendState *blend_opaque, *blend_premul;
ID3D11SamplerState* sampler;
ID3D11RasterizerState* raster;
bool gpu_ready = false, gpu_failed = false;
Target scene[2], hud[2];  // each player's last image without HUD, and their HUD
Target mirror;            // outside the split views (menus): the game's image, shown on player 2's monitor

constexpr float kSplitHud = 0.59f;  // HUD size in split screen (of its size on the full screen)

const char kShader[] = R"(
cbuffer C : register(b0) { float4 rect; float4 uv; float4 color; float4 mode; };
struct V { float4 pos : SV_Position; float2 uv : TEXCOORD0; };
V vs_main(uint id : SV_VertexID) {
  float2 t = float2(id & 1, id >> 1);
  V o; o.pos = float4(lerp(rect.xy, rect.zw, t), 0, 1); o.uv = lerp(uv.xy, uv.zw, t); return o;
}
Texture2D tex : register(t0); SamplerState smp : register(s0);
float4 ps_main(V i) : SV_Target {
  if (mode.x > 0.5) return color;
  float4 c = tex.Sample(smp, i.uv);
  if (mode.y > 0.5) c.a = 1;
  return c;
}
)";

struct CBuf {
  float rect[4];  // NDC: x0, y0 (top left), x1, y1 (bottom right)
  float uv[4];
  float color[4];
  float mode[4];  // x: solid colour, y: opaque
};

DXGI_FORMAT view_format(DXGI_FORMAT f) {
  switch (f) {
  case DXGI_FORMAT_B8G8R8A8_TYPELESS:
  case DXGI_FORMAT_B8G8R8A8_UNORM_SRGB: return DXGI_FORMAT_B8G8R8A8_UNORM;
  case DXGI_FORMAT_R8G8B8A8_TYPELESS:
  case DXGI_FORMAT_R8G8B8A8_UNORM_SRGB: return DXGI_FORMAT_R8G8B8A8_UNORM;
  case DXGI_FORMAT_R10G10B10A2_TYPELESS: return DXGI_FORMAT_R10G10B10A2_UNORM;
  case DXGI_FORMAT_R16G16B16A16_TYPELESS: return DXGI_FORMAT_R16G16B16A16_FLOAT;
  default: return f;
  }
}

bool make_target(Target& t, const D3D11_TEXTURE2D_DESC& src) {
  t.release();
  D3D11_TEXTURE2D_DESC d = src;
  d.MipLevels = 0;  // full chain: the images are drawn at a fraction of their size
  d.ArraySize = 1;
  d.SampleDesc.Count = 1;
  d.SampleDesc.Quality = 0;
  d.Usage = D3D11_USAGE_DEFAULT;
  d.BindFlags = D3D11_BIND_SHADER_RESOURCE | D3D11_BIND_RENDER_TARGET;
  d.CPUAccessFlags = 0;
  d.MiscFlags = D3D11_RESOURCE_MISC_GENERATE_MIPS;
  if (FAILED(device->CreateTexture2D(&d, nullptr, &t.tex))) return false;
  const DXGI_FORMAT vf = view_format(src.Format);
  D3D11_SHADER_RESOURCE_VIEW_DESC sd{};
  sd.Format = vf;
  sd.ViewDimension = D3D11_SRV_DIMENSION_TEXTURE2D;
  sd.Texture2D.MipLevels = static_cast<UINT>(-1);
  D3D11_RENDER_TARGET_VIEW_DESC rd{};
  rd.Format = vf;
  rd.ViewDimension = D3D11_RTV_DIMENSION_TEXTURE2D;
  if (FAILED(device->CreateShaderResourceView(t.tex, &sd, &t.srv)) || FAILED(device->CreateRenderTargetView(t.tex, &rd, &t.rtv))) {
    t.release();
    return false;
  }
  t.w = src.Width;
  t.h = src.Height;
  return true;
}

bool gpu_init() {
  ID3D11Device1* dev1 = nullptr;
  if (FAILED(device->QueryInterface(__uuidof(ID3D11Device1), reinterpret_cast<void**>(&dev1)))) return false;
  const D3D_FEATURE_LEVEL level = device->GetFeatureLevel();
  const HRESULT hr = dev1->CreateDeviceContextState(0, &level, 1, D3D11_SDK_VERSION, __uuidof(ID3D11Device1), nullptr, &state);
  dev1->Release();
  if (FAILED(hr)) return false;
  HMODULE dc = LoadLibraryW(L"d3dcompiler_47.dll");
  auto compile = dc ? reinterpret_cast<pD3DCompile>(reinterpret_cast<void*>(GetProcAddress(dc, "D3DCompile"))) : nullptr;
  if (!compile) return false;
  ID3DBlob *vsb = nullptr, *psb = nullptr, *err = nullptr;
  if (FAILED(compile(kShader, sizeof(kShader) - 1, "split", nullptr, nullptr, "vs_main", "vs_4_0", 0, 0, &vsb, &err)) ||
      FAILED(compile(kShader, sizeof(kShader) - 1, "split", nullptr, nullptr, "ps_main", "ps_4_0", 0, 0, &psb, &err))) {
    log("split: shader compile failed: %s", err ? static_cast<const char*>(err->GetBufferPointer()) : "?");
    return false;
  }
  device->CreateVertexShader(vsb->GetBufferPointer(), vsb->GetBufferSize(), nullptr, &vs);
  device->CreatePixelShader(psb->GetBufferPointer(), psb->GetBufferSize(), nullptr, &ps);
  vsb->Release();
  psb->Release();
  D3D11_BUFFER_DESC bd{};
  bd.ByteWidth = sizeof(CBuf);
  bd.Usage = D3D11_USAGE_DEFAULT;
  bd.BindFlags = D3D11_BIND_CONSTANT_BUFFER;
  device->CreateBuffer(&bd, nullptr, &cbuf);
  D3D11_BLEND_DESC bl{};
  bl.RenderTarget[0].RenderTargetWriteMask = D3D11_COLOR_WRITE_ENABLE_ALL;
  device->CreateBlendState(&bl, &blend_opaque);
  auto& rt = bl.RenderTarget[0];
  rt.BlendEnable = TRUE;
  rt.SrcBlend = rt.SrcBlendAlpha = D3D11_BLEND_ONE;
  rt.DestBlend = rt.DestBlendAlpha = D3D11_BLEND_INV_SRC_ALPHA;
  rt.BlendOp = rt.BlendOpAlpha = D3D11_BLEND_OP_ADD;
  device->CreateBlendState(&bl, &blend_premul);
  D3D11_SAMPLER_DESC sd{};
  sd.Filter = D3D11_FILTER_MIN_MAG_MIP_LINEAR;
  sd.AddressU = sd.AddressV = sd.AddressW = D3D11_TEXTURE_ADDRESS_CLAMP;
  sd.MaxLOD = D3D11_FLOAT32_MAX;
  device->CreateSamplerState(&sd, &sampler);
  D3D11_RASTERIZER_DESC rd{};
  rd.FillMode = D3D11_FILL_SOLID;
  rd.CullMode = D3D11_CULL_NONE;
  rd.ScissorEnable = TRUE;  // each view clips to its own region
  device->CreateRasterizerState(&rd, &raster);
  return vs && ps && cbuf && blend_opaque && blend_premul && sampler && raster;
}

// ---- immediate context hooks (the vtable is shared by every DXVK immediate context) ---------------
using DrawIndexedFn = void(STDMETHODCALLTYPE*)(ID3D11DeviceContext*, UINT, UINT, INT);
using DrawFn = void(STDMETHODCALLTYPE*)(ID3D11DeviceContext*, UINT, UINT);
using DrawIndexedInstancedFn = void(STDMETHODCALLTYPE*)(ID3D11DeviceContext*, UINT, UINT, UINT, INT, UINT);
using DrawInstancedFn = void(STDMETHODCALLTYPE*)(ID3D11DeviceContext*, UINT, UINT, UINT, UINT);
using SetRTFn = void(STDMETHODCALLTYPE*)(ID3D11DeviceContext*, UINT, ID3D11RenderTargetView* const*, ID3D11DepthStencilView*);
using SetBlendFn = void(STDMETHODCALLTYPE*)(ID3D11DeviceContext*, ID3D11BlendState*, const FLOAT[4], UINT);
using ClearRTFn = void(STDMETHODCALLTYPE*)(ID3D11DeviceContext*, ID3D11RenderTargetView*, const FLOAT[4]);
DrawIndexedFn o_draw_indexed;
DrawFn o_draw;
DrawIndexedInstancedFn o_draw_indexed_instanced;
DrawInstancedFn o_draw_instanced;
SetRTFn o_set_rt;
SetBlendFn o_set_blend;
ClearRTFn o_clear_rt;

bool hooked = false;
bool own_calls = false;  // our own draws (composition): hooks pass them through untouched

// Per frame, render thread only.
ID3D11Resource* backbuffer = nullptr;  // no reference held
ID3D11Resource* cur_rt = nullptr;      // as the game bound it
ID3D11Resource* last_drawn_rt = nullptr;
ID3D11Resource* final_rt = nullptr;    // the render target drawn right before the back buffer: scene + HUD
DXGI_FORMAT final_fmt = DXGI_FORMAT_UNKNOWN;
D3D11_TEXTURE2D_DESC final_desc{};
unsigned final_draws = 0;
bool hud_phase = false, captured = false, frame_active = false;
int frame_view = 0, last_view = 1;

// Blend states of the HUD with alpha accumulated as coverage (src ONE, dst INV_SRC_ALPHA), so the HUD
// texture ends up premultiplied over transparent black.
struct BlendVariant {
  ID3D11BlendState* game;
  ID3D11BlendState* ours;
};
BlendVariant variants[64];
int variant_count = 0;
ID3D11BlendState* cur_blend = nullptr;
FLOAT cur_blend_factor[4] = {1, 1, 1, 1};
UINT cur_blend_mask = 0xffffffff;

ID3D11BlendState* hud_blend(ID3D11BlendState* game) {
  for (int i = 0; i < variant_count; ++i)
    if (variants[i].game == game) return variants[i].ours;
  D3D11_BLEND_DESC d{};
  if (game) {
    game->GetDesc(&d);
  } else {
    d.RenderTarget[0].RenderTargetWriteMask = D3D11_COLOR_WRITE_ENABLE_ALL;
  }
  auto& rt = d.RenderTarget[0];
  const UINT8 game_mask = rt.RenderTargetWriteMask;
  // Draws that write alpha only (the banners' shape pass, e.g. "your partner is down") have no visible effect
  // in the game, whose final alpha is never shown; here alpha is the HUD's coverage, so they are dropped
  // (written in colour they showed as a light blue box). Blended draws write all channels (coverage);
  // unblended ones keep the game's mask.
  if (!(game_mask & 7)) rt.RenderTargetWriteMask = 0;
  else rt.RenderTargetWriteMask = rt.BlendEnable ? static_cast<UINT8>(D3D11_COLOR_WRITE_ENABLE_ALL) : game_mask;
  if (rt.BlendEnable && rt.DestBlend == D3D11_BLEND_ONE) {  // additive (glows): adds light, no coverage
    rt.SrcBlendAlpha = D3D11_BLEND_ZERO;
    rt.DestBlendAlpha = D3D11_BLEND_ONE;
    rt.BlendOpAlpha = D3D11_BLEND_OP_ADD;
  } else if (rt.BlendEnable) {
    rt.SrcBlendAlpha = D3D11_BLEND_ONE;
    rt.DestBlendAlpha = D3D11_BLEND_INV_SRC_ALPHA;
    rt.BlendOpAlpha = D3D11_BLEND_OP_ADD;
  }
  d.IndependentBlendEnable = FALSE;
  ID3D11BlendState* ours = nullptr;
  if (FAILED(device->CreateBlendState(&d, &ours))) return game;
  log("split: HUD blend %d: enable %d src %d dst %d op %d alpha %d/%d mask %x", variant_count, rt.BlendEnable, rt.SrcBlend,
      rt.DestBlend, rt.BlendOp, rt.SrcBlendAlpha, rt.DestBlendAlpha, game_mask);
  if (variant_count < 64) {
    if (game) game->AddRef();
    variants[variant_count++] = {game, ours};
  }
  return ours;
}

// Camera of the frame being captured: the packet tag read when the frame started; without one, the old
// guess from the renderer's eye; when that cannot tell either, assume alternation.
unsigned stat_frames = 0, stat_guess = 0, stat_repeat = 0, stat_untagged = 0, stat_disagree = 0;
ULONGLONG stat_start = 0;
bool need_tag = false;  // set at Present: look up the packet tag at the next frame's first render target
int frame_tag = -1;

void pick_view() {
  const int guess = classify_view();
  int v = frame_tag;
  frame_tag = -1;
  if (v < 0) {
    ++stat_untagged;
    v = guess;
  } else if (guess >= 0 && guess != v) {
    ++stat_disagree;
  }
  if (v < 0) {
    v = last_view ^ 1;
    ++stat_guess;
  }
  if (at<uint8_t>(kPaused)) {  // paused: one camera, nothing to count
    last_view = frame_view = v;
    return;
  }
  if (v == last_view) ++stat_repeat;
  last_view = frame_view = v;
  if (++stat_frames == 1200) {
    const ULONGLONG now = GetTickCount64();
    log("split: %u frames in %llu ms (%.1f fps), %u untagged, %u guessed, %u same view twice, %u eye disagreed",
        stat_frames, now - stat_start, stat_frames * 1000.0 / static_cast<double>(now - stat_start), stat_untagged,
        stat_guess, stat_repeat, stat_disagree);
    stat_frames = stat_guess = stat_repeat = stat_untagged = stat_disagree = 0;
    stat_start = now;
  }
}

void begin_hud(ID3D11DeviceContext* c) {
  pick_view();
  if (!scene[frame_view].tex || scene[frame_view].w != final_desc.Width || scene[frame_view].h != final_desc.Height) {
    for (Target* t : {&scene[0], &scene[1], &hud[0], &hud[1]})
      if (!make_target(*t, final_desc)) {
        log("split: texture creation failed (%ux%u fmt %u)", final_desc.Width, final_desc.Height, final_desc.Format);
        gpu_failed = true;
        return;
      }
    log("split: textures %ux%u fmt %u", final_desc.Width, final_desc.Height, final_desc.Format);
  }
  Target& s = scene[frame_view];
  c->CopySubresourceRegion(s.tex, 0, 0, 0, 0, final_rt, 0, nullptr);
  s.valid = s.dirty = true;
  captured = true;
  // From here on the HUD goes to its own texture.
  ID3D11DepthStencilView* dsv = nullptr;
  c->OMGetRenderTargets(0, nullptr, &dsv);
  const FLOAT clear[4] = {0, 0, 0, 0};
  o_clear_rt(c, hud[frame_view].rtv, clear);
  o_set_rt(c, 1, &hud[frame_view].rtv, dsv);
  if (dsv) dsv->Release();
  o_set_blend(c, hud_blend(cur_blend), cur_blend_factor, cur_blend_mask);
  hud[frame_view].valid = hud[frame_view].dirty = true;
  hud_phase = true;
}

// Where the HUD starts on the final target: the scene is composed by a full-screen triangle (3 vertices), the HUD
// by quads. The HUD starts at the first other draw after that triangle (the second draw used to be taken blindly,
// and a frame with an extra draw before the triangle sent the scene into the HUD texture: the split views showed
// bands of other images for a moment after a weapon change). Without any triangle, the second draw as before.
bool scene_drawn = false;
bool scene_pass = false;  // the current draw goes to the scene copy (after_draw puts the HUD target back)
unsigned odd_frames = 0;
// Draw trace (diagnostics, plugin/ngs2coop-trace-draws.txt): per frame, the draws and render target switches.
bool trace_draws = false;
char trace_line[1400];
int trace_len = 0;
void trace_add(const char* fmt, UINT a, UINT b) {
  if (!trace_draws || trace_len > 1300) return;
  trace_len += snprintf(trace_line + trace_len, sizeof(trace_line) - trace_len, fmt, a, b);
}
void before_draw(ID3D11DeviceContext* c, UINT n) {
  if (own_calls) return;
  if (cur_rt == backbuffer && last_drawn_rt && last_drawn_rt != backbuffer && last_drawn_rt != final_rt) {
    ID3D11Texture2D* t = nullptr;
    if (SUCCEEDED(last_drawn_rt->QueryInterface(__uuidof(ID3D11Texture2D), reinterpret_cast<void**>(&t)))) {
      t->GetDesc(&final_desc);
      t->Release();
      final_rt = last_drawn_rt;
      final_fmt = DXGI_FORMAT_UNKNOWN;
      log("split: final target %p %ux%u fmt %u", static_cast<void*>(final_rt), final_desc.Width, final_desc.Height, final_desc.Format);
    }
  }
  if (cur_rt) last_drawn_rt = cur_rt;
  if (trace_draws && cur_rt == final_rt) trace_add(hud_phase ? " H%u" : " F%u", n, 0);
  // A full-screen triangle during the HUD is an effect over the scene (seen for ~0.7 s around a weapon change):
  // it goes onto this view's scene copy with the game's blending, not into the HUD texture (where it put the whole
  // scene, shown as bands of other images in the split views).
  if (frame_active && hud_phase && cur_rt == final_rt && n == 3 && scene[frame_view].rtv) {
    ID3D11DepthStencilView* dsv = nullptr;
    c->OMGetRenderTargets(0, nullptr, &dsv);
    o_set_rt(c, 1, &scene[frame_view].rtv, dsv);
    if (dsv) dsv->Release();
    o_set_blend(c, cur_blend, cur_blend_factor, cur_blend_mask);
    scene[frame_view].dirty = true;
    scene_pass = true;
    return;
  }
  if (!frame_active || gpu_failed || cur_rt != final_rt || !final_rt || hud_phase) return;
  ++final_draws;
  if (n == 3) {
    scene_drawn = true;
    return;
  }
  if (scene_drawn || final_draws == 2) {
    if (!scene_drawn || final_draws != 2) {
      if (odd_frames++ < 20) log("split: HUD starts at draw %u of the final target (scene triangle %s)", final_draws, scene_drawn ? "seen" : "not seen");
    }
    begin_hud(c);
  }
}

void STDMETHODCALLTYPE h_set_rt(ID3D11DeviceContext* c, UINT n, ID3D11RenderTargetView* const* rtv, ID3D11DepthStencilView* dsv) {
  if (!own_calls && need_tag) {  // the frame's first render target: the renderer has picked its packet
    need_tag = false;
    frame_tag = tagged_view();
  }
  if (!own_calls) {
    ID3D11Resource* r = nullptr;
    if (n && rtv && rtv[0]) {
      rtv[0]->GetResource(&r);
      r->Release();
      if (r == final_rt && final_fmt == DXGI_FORMAT_UNKNOWN) {
        D3D11_RENDER_TARGET_VIEW_DESC d;
        rtv[0]->GetDesc(&d);
        final_fmt = d.Format;
      }
    }
    if (trace_draws && r != cur_rt && (r == final_rt || cur_rt == final_rt)) trace_add(r == final_rt ? " [in]" : " [out]", 0, 0);
    cur_rt = r;
    if (hud_phase) {
      if (r == final_rt && n == 1) {
        o_set_rt(c, 1, &hud[frame_view].rtv, dsv);
        return;
      }
      hud_phase = false;
      o_set_blend(c, cur_blend, cur_blend_factor, cur_blend_mask);
    }
  }
  o_set_rt(c, n, rtv, dsv);
}
void STDMETHODCALLTYPE h_set_blend(ID3D11DeviceContext* c, ID3D11BlendState* b, const FLOAT f[4], UINT mask) {
  if (!own_calls) {
    cur_blend = b;
    if (f) memcpy(cur_blend_factor, f, sizeof(cur_blend_factor));
    else for (FLOAT& v : cur_blend_factor) v = 1;
    cur_blend_mask = mask;
    if (hud_phase) {
      o_set_blend(c, hud_blend(b), f, mask);
      return;
    }
  }
  o_set_blend(c, b, f, mask);
}
void STDMETHODCALLTYPE h_clear_rt(ID3D11DeviceContext* c, ID3D11RenderTargetView* v, const FLOAT col[4]) {
  o_clear_rt(c, v, col);
}
void after_draw(ID3D11DeviceContext* c) {
  if (!scene_pass) return;
  scene_pass = false;
  ID3D11DepthStencilView* dsv = nullptr;
  c->OMGetRenderTargets(0, nullptr, &dsv);
  o_set_rt(c, 1, &hud[frame_view].rtv, dsv);
  if (dsv) dsv->Release();
  o_set_blend(c, hud_blend(cur_blend), cur_blend_factor, cur_blend_mask);
}

void STDMETHODCALLTYPE h_draw_indexed(ID3D11DeviceContext* c, UINT n, UINT s, INT b) {
  before_draw(c, n);
  o_draw_indexed(c, n, s, b);
  after_draw(c);
}
void STDMETHODCALLTYPE h_draw(ID3D11DeviceContext* c, UINT n, UINT s) {
  before_draw(c, n);
  o_draw(c, n, s);
  after_draw(c);
}
void STDMETHODCALLTYPE h_draw_indexed_instanced(ID3D11DeviceContext* c, UINT n, UINT i, UINT s, INT b, UINT si) {
  before_draw(c, n);
  o_draw_indexed_instanced(c, n, i, s, b, si);
  after_draw(c);
}
void STDMETHODCALLTYPE h_draw_instanced(ID3D11DeviceContext* c, UINT n, UINT i, UINT s, UINT si) {
  before_draw(c, n);
  o_draw_instanced(c, n, i, s, si);
  after_draw(c);
}

template<class F> void patch(void** vt, int idx, F hook, F& orig) {
  DWORD old;
  VirtualProtect(&vt[idx], sizeof(void*), PAGE_READWRITE, &old);
  orig = reinterpret_cast<F>(vt[idx]);
  vt[idx] = reinterpret_cast<void*>(hook);
  VirtualProtect(&vt[idx], sizeof(void*), old, &old);
}

// Windows' own d3d11.dll keeps the immediate context's vtable inside the object (heap) and keeps rewriting its
// entries: most state calls switch Draw* (and ClearRenderTargetView) between a "validate, then draw" variant and a
// fast one, so a hook written into it is gone after the next state change. DXVK's vtable is static and is patched
// as is. On the native runtime the object gets a vtable of our own instead: every entry is a stub that jumps through
// d3d11's live entry, except the hooked ones, whose originals are those same stubs (always d3d11's current choice).
ID3D11DeviceContext* own_ctx = nullptr;
void** own_vt = nullptr;
constexpr int kVtSlots = 256;  // ID3D11DeviceContext4 has ~150 methods

void* live_stubs(void** live) {
  auto* code = static_cast<uint8_t*>(VirtualAlloc(nullptr, kVtSlots * 16, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE));
  if (!code) return nullptr;
  for (int i = 0; i < kVtSlots; ++i) {
    uint8_t* s = code + i * 16;
    const uint64_t entry = reinterpret_cast<uint64_t>(&live[i]);
    s[0] = 0x48; s[1] = 0xb8; memcpy(s + 2, &entry, 8);  // mov rax, &live[i]
    s[10] = 0xff; s[11] = 0x20;                           // jmp [rax]
    s[12] = s[13] = s[14] = s[15] = 0xcc;
  }
  DWORD old;
  VirtualProtect(code, kVtSlots * 16, PAGE_EXECUTE_READ, &old);
  FlushInstructionCache(GetCurrentProcess(), code, kVtSlots * 16);
  return code;
}

template<class F> void own_entry(int idx, F hook, F& orig, uint8_t* stubs) {
  orig = reinterpret_cast<F>(stubs + idx * 16);
  own_vt[idx] = reinterpret_cast<void*>(hook);
}

void hook_context(ID3D11DeviceContext* ctx) {
  void** vt = *reinterpret_cast<void***>(ctx);
  MEMORY_BASIC_INFORMATION mi{};
  const bool in_object = VirtualQuery(vt, &mi, sizeof(mi)) && mi.Type == MEM_PRIVATE;
  uint8_t* stubs = in_object ? static_cast<uint8_t*>(live_stubs(vt)) : nullptr;
  own_vt = stubs ? static_cast<void**>(VirtualAlloc(nullptr, kVtSlots * sizeof(void*), MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE)) : nullptr;
  if (!own_vt) {
    patch(vt, 12, &h_draw_indexed, o_draw_indexed);
    patch(vt, 13, &h_draw, o_draw);
    patch(vt, 20, &h_draw_indexed_instanced, o_draw_indexed_instanced);
    patch(vt, 21, &h_draw_instanced, o_draw_instanced);
    patch(vt, 33, &h_set_rt, o_set_rt);
    patch(vt, 35, &h_set_blend, o_set_blend);
    patch(vt, 50, &h_clear_rt, o_clear_rt);
    return;
  }
  for (int i = 0; i < kVtSlots; ++i) own_vt[i] = stubs + i * 16;
  own_entry(12, &h_draw_indexed, o_draw_indexed, stubs);
  own_entry(13, &h_draw, o_draw, stubs);
  own_entry(20, &h_draw_indexed_instanced, o_draw_indexed_instanced, stubs);
  own_entry(21, &h_draw_instanced, o_draw_instanced, stubs);
  own_entry(33, &h_set_rt, o_set_rt, stubs);
  own_entry(35, &h_set_blend, o_set_blend, stubs);
  own_entry(50, &h_clear_rt, o_clear_rt, stubs);
  own_ctx = ctx;
  InterlockedExchangePointer(reinterpret_cast<void* volatile*>(ctx), own_vt);
  log("split: native d3d11 context (vtable in the object, rewritten as it runs): hooked through a vtable of our own");
}

// d3d11 could point the object back at its own table: checked every frame.
void keep_own_vtable() {
  if (!own_ctx || *reinterpret_cast<void***>(own_ctx) == own_vt) return;
  InterlockedExchangePointer(reinterpret_cast<void* volatile*>(own_ctx), own_vt);
  static int told = 0;
  if (told++ < 5) log("split: d3d11 restored the context's vtable, ours put back");
}

// ---- second monitor: a borderless window of our own showing player 2 ------------------------------
HWND p2_window = nullptr;
RECT p2_rect{};          // where it goes (virtual screen coordinates)
volatile LONG p2_shown = 0;
IDXGISwapChain* p2_chain = nullptr;
UINT p2_w = 0, p2_h = 0;
bool presenting_p2 = false;
constexpr UINT kMsgShow = WM_APP + 1, kMsgHide = WM_APP + 2;

LRESULT CALLBACK p2_wndproc(HWND h, UINT msg, WPARAM wp, LPARAM lp) {
  switch (msg) {
  case WM_MOUSEACTIVATE: return MA_NOACTIVATE;
  case WM_ERASEBKGND: return 1;
  case WM_CLOSE: return 0;
  case kMsgShow:
    SetWindowPos(h, HWND_TOPMOST, p2_rect.left, p2_rect.top, p2_rect.right - p2_rect.left, p2_rect.bottom - p2_rect.top,
                 SWP_NOACTIVATE | SWP_SHOWWINDOW);
    return 0;
  case kMsgHide:
    ShowWindow(h, SW_HIDE);
    return 0;
  }
  return DefWindowProcW(h, msg, wp, lp);
}

DWORD WINAPI p2_window_thread(LPVOID) {
  WNDCLASSW wc{};
  wc.lpfnWndProc = p2_wndproc;
  wc.hInstance = GetModuleHandleW(nullptr);
  wc.hCursor = nullptr;
  wc.hbrBackground = static_cast<HBRUSH>(GetStockObject(BLACK_BRUSH));
  wc.lpszClassName = L"ngs2coop_player2";
  RegisterClassW(&wc);
  HWND h = CreateWindowExW(WS_EX_NOACTIVATE | WS_EX_TOOLWINDOW, wc.lpszClassName, L"NINJA GAIDEN Σ2 - Jugador 2", WS_POPUP,
                           0, 0, 640, 360, nullptr, nullptr, wc.hInstance, nullptr);
  if (!h) {
    log("split: second-monitor window failed (%lu)", GetLastError());
    return 0;
  }
  p2_window = h;
  MSG m;
  while (GetMessageW(&m, nullptr, 0, 0) > 0) {
    TranslateMessage(&m);
    DispatchMessageW(&m);
  }
  return 0;
}

struct MonitorScan {
  HMONITOR game;
  int count;
  RECT other;
  bool found;
  bool verbose;
  LONG gap;
};

// Player 2's monitor: the usable one closest to the game's (the one beside it), not one further away.
BOOL CALLBACK monitor_cb(HMONITOR m, HDC, LPRECT r, LPARAM p) {
  auto* s = reinterpret_cast<MonitorScan*>(p);
  bool skip = false;
  for (int i = 0; i < ignored_count; ++i)
    skip |= r->right - r->left == ignored[i].w && r->bottom - r->top == ignored[i].h;
  if (s->verbose) {
    MONITORINFOEXW mi{};
    mi.cbSize = sizeof(mi);
    GetMonitorInfoW(m, &mi);
    log("split: monitor %ls %ld,%ld %ldx%ld%s", mi.szDevice, r->left, r->top, r->right - r->left, r->bottom - r->top,
        m == s->game ? " (game)" : skip ? " (ignored)" : "");
  }
  if (skip && m != s->game) return TRUE;
  ++s->count;
  if (m == s->game) return TRUE;
  RECT g{};
  MONITORINFO gi{};
  gi.cbSize = sizeof(gi);
  if (s->game && GetMonitorInfoW(s->game, &gi)) g = gi.rcMonitor;
  const LONG dx = r->left > g.right ? r->left - g.right : g.left > r->right ? g.left - r->right : 0;
  const LONG dy = r->top > g.bottom ? r->top - g.bottom : g.top > r->bottom ? g.top - r->bottom : 0;
  const LONG gap = dx + dy;
  if (!s->found || gap < s->gap) {
    s->other = *r;
    s->gap = gap;
    s->found = true;
  }
  return TRUE;
}

HWND game_window = nullptr;

void scan_monitors() {
  MonitorScan s{game_window ? MonitorFromWindow(game_window, MONITOR_DEFAULTTOPRIMARY) : nullptr, 0, {}, false, false, 0};
  EnumDisplayMonitors(nullptr, nullptr, monitor_cb, reinterpret_cast<LPARAM>(&s));
  const LONG before = monitors;
  monitors = s.count;
  if (s.found) p2_rect = s.other;
  if (before != s.count) {
    log("split: %d monitor(s)%s", s.count, s.found ? "" : " (no second one)");
    s = MonitorScan{s.game, 0, {}, false, true, 0};
    EnumDisplayMonitors(nullptr, nullptr, monitor_cb, reinterpret_cast<LPARAM>(&s));
  }
}

void show_p2_window(bool on) {
  if (on && !p2_window) {
    const HANDLE t = CreateThread(nullptr, 0, p2_window_thread, nullptr, 0, nullptr);
    if (t) CloseHandle(t);
    return;  // shown on a later frame, once the window exists
  }
  if (!p2_window || (on ? 1 : 0) == p2_shown) return;
  p2_shown = on;
  PostMessageW(p2_window, on ? kMsgShow : kMsgHide, 0, 0);
  log(on ? "split: player 2 window on the second monitor (%ld,%ld %ldx%ld)" : "split: player 2 window hidden", p2_rect.left,
      p2_rect.top, p2_rect.right - p2_rect.left, p2_rect.bottom - p2_rect.top);
}

bool ensure_p2_chain() {
  const UINT w = static_cast<UINT>(p2_rect.right - p2_rect.left), h = static_cast<UINT>(p2_rect.bottom - p2_rect.top);
  if (!p2_window || !w || !h) return false;
  if (p2_chain && (w != p2_w || h != p2_h)) {
    p2_chain->Release();
    p2_chain = nullptr;
  }
  if (p2_chain) return true;
  IDXGIDevice* dxgi = nullptr;
  IDXGIAdapter* adapter = nullptr;
  IDXGIFactory* factory = nullptr;
  if (SUCCEEDED(device->QueryInterface(__uuidof(IDXGIDevice), reinterpret_cast<void**>(&dxgi))) &&
      SUCCEEDED(dxgi->GetAdapter(&adapter)) && SUCCEEDED(adapter->GetParent(__uuidof(IDXGIFactory), reinterpret_cast<void**>(&factory)))) {
    DXGI_SWAP_CHAIN_DESC sd{};
    sd.BufferCount = 2;
    sd.BufferDesc.Width = w;
    sd.BufferDesc.Height = h;
    sd.BufferDesc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
    sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    sd.OutputWindow = p2_window;
    sd.SampleDesc.Count = 1;
    sd.Windowed = TRUE;
    sd.SwapEffect = DXGI_SWAP_EFFECT_FLIP_DISCARD;
    const HRESULT hr = factory->CreateSwapChain(device, &sd, &p2_chain);
    if (FAILED(hr)) log("split: second swap chain failed %08lx", hr);
    else {
      factory->MakeWindowAssociation(p2_window, DXGI_MWA_NO_ALT_ENTER);
      p2_w = w;
      p2_h = h;
      log("split: second swap chain %ux%u", w, h);
    }
  }
  if (factory) factory->Release();
  if (adapter) adapter->Release();
  if (dxgi) dxgi->Release();
  return p2_chain != nullptr;
}

// ---- composition ------------------------------------------------------------------------------------
void quad(ID3D11DeviceContext* c, float x0, float y0, float x1, float y1, int W, int H, ID3D11ShaderResourceView* srv,
          const float uv[4], const float* color, bool opaque) {
  CBuf cb{{2.0f * x0 / W - 1, 1 - 2.0f * y0 / H, 2.0f * x1 / W - 1, 1 - 2.0f * y1 / H},
          {uv[0], uv[1], uv[2], uv[3]},
          {color ? color[0] : 0, color ? color[1] : 0, color ? color[2] : 0, color ? color[3] : 0},
          {color ? 1.0f : 0.0f, opaque ? 1.0f : 0.0f, 0, 0}};
  c->UpdateSubresource(cbuf, 0, nullptr, &cb, 0, 0);
  c->PSSetShaderResources(0, 1, &srv);
  c->Draw(4, 0);
}

// One player's view in the region (x0, y0)-(x1, y1) of a W x H target: the centre of their image cut to
// the region's shape (same zoom as the game, less field of view), then their HUD at `hud_scale`.
void draw_view(ID3D11DeviceContext* c, int player, float x0, float y0, float x1, float y1, int W, int H, float hud_scale) {
  const Target& s = scene[player].valid ? scene[player] : scene[player ^ 1];
  const float rw = x1 - x0, rh = y1 - y0;
  const float src_aspect = static_cast<float>(s.w) / static_cast<float>(s.h), aspect = rw / rh;
  float uw = 1, vh = 1;
  if (aspect < src_aspect) uw = aspect / src_aspect;
  else vh = src_aspect / aspect;
  const float uv[4] = {0.5f - uw / 2, 0.5f - vh / 2, 0.5f + uw / 2, 0.5f + vh / 2};
  const D3D11_RECT clip{static_cast<LONG>(x0), static_cast<LONG>(y0), static_cast<LONG>(x1), static_cast<LONG>(y1)};
  c->RSSetScissorRects(1, &clip);
  c->OMSetBlendState(blend_opaque, nullptr, 0xffffffff);
  quad(c, x0, y0, x1, y1, W, H, s.srv, uv, nullptr, true);
  const Target& h = hud[player];
  if (!h.valid || hud_scale <= 0) return;
  c->OMSetBlendState(blend_premul, nullptr, 0xffffffff);
  // The HUD canvas is laid out for the game's full screen: `hud_scale` of the target's size. Its top half
  // hugs the region's top edge and its bottom half the bottom edge (messages, boss gauge); left-aligned.
  const float fw = static_cast<float>(W), fh = static_cast<float>(H);
  const float cw = (fh * src_aspect < fw ? fh * src_aspect : fw) * hud_scale, ch = cw / src_aspect;
  if (hud_scale >= 1) {  // full size: centred like the image
    const float cx = x0 + (rw - cw) / 2, cy = y0 + (rh - ch) / 2;
    const float full[4] = {0, 0, 1, 1};
    quad(c, cx, cy, cx + cw, cy + ch, W, H, h.srv, full, nullptr, false);
    return;
  }
  // The middle of the canvas (the aim reticle, centred messages) is left out of the halves and drawn full size
  // at the region's centre, where the camera aims: the halves cut the reticle in two and shrank it.
  constexpr float bu0 = 0.40f, bu1 = 0.60f, bv0 = 0.32f, bv1 = 0.68f;
  auto top_part = [&](float u0, float v0, float u1, float v1) {
    const float uv2[4] = {u0, v0, u1, v1};
    quad(c, x0 + u0 * cw, y0 + v0 * ch, x0 + u1 * cw, y0 + v1 * ch, W, H, h.srv, uv2, nullptr, false);
  };
  auto bottom_part = [&](float u0, float v0, float u1, float v1) {
    const float uv2[4] = {u0, v0, u1, v1};
    quad(c, x0 + u0 * cw, y1 - ch + v0 * ch, x0 + u1 * cw, y1 - ch + v1 * ch, W, H, h.srv, uv2, nullptr, false);
  };
  top_part(0, 0, 1, bv0);
  top_part(0, bv0, bu0, 0.5f);
  top_part(bu1, bv0, 1, 0.5f);
  bottom_part(0, bv1, 1, 1);
  bottom_part(0, 0.5f, bu0, bv1);
  bottom_part(bu1, 0.5f, 1, bv1);
  const float full_w = cw / hud_scale, full_h = ch / hud_scale;
  const float mx = x0 + rw / 2, my = y0 + rh / 2;
  const float mid[4] = {bu0, bv0, bu1, bv1};
  quad(c, mx - (0.5f - bu0) * full_w, my - (0.5f - bv0) * full_h, mx + (bu1 - 0.5f) * full_w, my + (bv1 - 0.5f) * full_h,
       W, H, h.srv, mid, nullptr, false);
}

// Player 2's monitor outside the split views: the game's own image, fitted (letterboxed) to the window.
void draw_mirror(ID3D11DeviceContext* c, ID3D11Texture2D* tex) {
  D3D11_TEXTURE2D_DESC bd;
  tex->GetDesc(&bd);
  const int W = static_cast<int>(bd.Width), H = static_cast<int>(bd.Height);
  const float fw = static_cast<float>(W), fh = static_cast<float>(H);
  ID3D11RenderTargetView* rtv = nullptr;
  if (FAILED(device->CreateRenderTargetView(tex, nullptr, &rtv))) return;
  D3D11_VIEWPORT vp{0, 0, fw, fh, 0, 1};
  c->RSSetViewports(1, &vp);
  c->RSSetState(raster);
  c->OMSetRenderTargets(1, &rtv, nullptr);
  c->IASetInputLayout(nullptr);
  c->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP);
  c->VSSetShader(vs, nullptr, 0);
  c->PSSetShader(ps, nullptr, 0);
  c->VSSetConstantBuffers(0, 1, &cbuf);
  c->PSSetConstantBuffers(0, 1, &cbuf);
  c->PSSetSamplers(0, 1, &sampler);
  const D3D11_RECT all{0, 0, W, H};
  c->RSSetScissorRects(1, &all);
  c->OMSetBlendState(blend_opaque, nullptr, 0xffffffff);
  const float full[4] = {0, 0, 1, 1};
  const float black[4] = {0, 0, 0, 1};
  quad(c, 0, 0, fw, fh, W, H, nullptr, full, black, true);
  const float aspect = static_cast<float>(mirror.w) / static_cast<float>(mirror.h);
  const float cw = fh * aspect < fw ? fh * aspect : fw, ch = cw / aspect;
  quad(c, (fw - cw) / 2, (fh - ch) / 2, (fw + cw) / 2, (fh + ch) / 2, W, H, mirror.srv, full, nullptr, true);
  ID3D11ShaderResourceView* none = nullptr;
  c->PSSetShaderResources(0, 1, &none);
  rtv->Release();
}

// Draws into `tex` (W x H): Vertical / Horizontal = both players, else `player` full screen. Paused: the
// views without their HUDs and the latest HUD (the pause menu) full size on top.
void compose(ID3D11DeviceContext* c, ID3D11Texture2D* tex, Mode m, int player, bool paused) {
  D3D11_TEXTURE2D_DESC bd;
  tex->GetDesc(&bd);
  const int W = static_cast<int>(bd.Width), H = static_cast<int>(bd.Height);
  const float fw = static_cast<float>(W), fh = static_cast<float>(H);
  ID3D11RenderTargetView* rtv = nullptr;
  if (FAILED(device->CreateRenderTargetView(tex, nullptr, &rtv))) return;
  D3D11_VIEWPORT vp{0, 0, fw, fh, 0, 1};
  c->RSSetViewports(1, &vp);
  c->RSSetState(raster);
  c->OMSetRenderTargets(1, &rtv, nullptr);
  c->IASetInputLayout(nullptr);
  c->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP);
  c->VSSetShader(vs, nullptr, 0);
  c->PSSetShader(ps, nullptr, 0);
  c->VSSetConstantBuffers(0, 1, &cbuf);
  c->PSSetConstantBuffers(0, 1, &cbuf);
  c->PSSetSamplers(0, 1, &sampler);
  const float full[4] = {0, 0, 1, 1};
  const float line[4] = {0.02f, 0.02f, 0.03f, 1};
  const float t = fh / 400.0f + 1;  // half the divider's thickness
  const float hud_scale = paused ? 0.0f : kSplitHud;
  const D3D11_RECT all{0, 0, W, H};
  if (m == Vertical) {
    draw_view(c, 0, 0, 0, fw / 2, fh, W, H, hud_scale);
    draw_view(c, 1, fw / 2, 0, fw, fh, W, H, hud_scale);
    c->RSSetScissorRects(1, &all);
    c->OMSetBlendState(blend_opaque, nullptr, 0xffffffff);
    quad(c, fw / 2 - t, 0, fw / 2 + t, fh, W, H, nullptr, full, line, true);
  } else if (m == Horizontal) {
    draw_view(c, 0, 0, 0, fw, fh / 2, W, H, hud_scale);
    draw_view(c, 1, 0, fh / 2, fw, fh, W, H, hud_scale);
    c->RSSetScissorRects(1, &all);
    c->OMSetBlendState(blend_opaque, nullptr, 0xffffffff);
    quad(c, 0, fh / 2 - t, fw, fh / 2 + t, W, H, nullptr, full, line, true);
  } else {
    draw_view(c, player, 0, 0, fw, fh, W, H, paused ? 0.0f : 1.0f);
    c->RSSetScissorRects(1, &all);
  }
  if (paused && hud[last_view].valid) {
    const Target& s = scene[0];
    const float aspect = static_cast<float>(s.w) / static_cast<float>(s.h);
    const float cw = fh * aspect < fw ? fh * aspect : fw, ch = cw / aspect;
    c->OMSetBlendState(blend_premul, nullptr, 0xffffffff);
    quad(c, (fw - cw) / 2, (fh - ch) / 2, (fw + cw) / 2, (fh + ch) / 2, W, H, hud[last_view].srv, full, nullptr, false);
  }
  ID3D11ShaderResourceView* none = nullptr;
  c->PSSetShaderResources(0, 1, &none);
  rtv->Release();
}

LONG frames = 0;

Mode resolve(LONG chosen, LONG mons) {
  if (chosen == Dual || chosen == Auto) return mons >= 2 ? Dual : Vertical;
  return static_cast<Mode>(chosen);
}

// ngs2coop-split.txt: the layout on the first line (auto, vertical, horizontal, dual), then optional
// `ignore WxH` lines. Saving keeps the ignore lines.
void save_mode() {
  FILE* f = _wfopen(config_path, L"w");
  if (!f) return;
  const LONG m = user_mode;
  fputs(m == Vertical ? "vertical\n" : m == Horizontal ? "horizontal\n" : m == Dual ? "dual\n" : "auto\n", f);
  for (int i = 0; i < ignored_count; ++i) fprintf(f, "ignore %ldx%ld\n", ignored[i].w, ignored[i].h);
  fclose(f);
}

void load_mode() {
  FILE* f = _wfopen(config_path, L"r");
  if (!f) return;
  char buf[64] = {};
  if (fgets(buf, sizeof(buf), f)) {
    if (!strncmp(buf, "vertical", 8)) user_mode = Vertical;
    else if (!strncmp(buf, "horizontal", 10)) user_mode = Horizontal;
    else if (!strncmp(buf, "dual", 4)) user_mode = Dual;
    else user_mode = Auto;
  }
  long w, h;
  while (fgets(buf, sizeof(buf), f))
    if (ignored_count < 8 && sscanf(buf, "ignore %ldx%ld", &w, &h) == 2) {
      ignored[ignored_count++] = {w, h};
      log("split: ignoring %ldx%ld monitors", w, h);
    }
  fclose(f);
}
} // namespace

void init(uintptr_t image_base, const wchar_t* plugin_dir, void (*logger)(const char*, ...)) {
  base = image_base;
  log = logger;
  lstrcpyW(trace_flag, plugin_dir);
  lstrcatW(trace_flag, L"ngs2coop-trace.txt");
  lstrcpyW(config_path, plugin_dir);
  lstrcatW(config_path, L"ngs2coop-split.txt");
  load_mode();
  gauge_hooked = install_gauge_hook();
  ninpo_hooked = gauge_hooked && install_ninpo_hook();
  install_face_hook();
  if (gauge_hooked) install_reticle_hook();
  log("split: layout %ls", mode_name(static_cast<Mode>(static_cast<LONG>(user_mode))));
}

void set_active(bool on) { want_active = on; }
void set_joined(bool on) { p2_joined = on; }

bool running() { return want_active && !gpu_failed; }

void update_frame() {
  if (!want_active || gpu_failed) {
    if (gauge_split) open_p2_gauge(false);
    reticle_frame_end();
    return;
  }
  const int32_t view = at<int32_t>(kView);
  tag_packet(view);  // the packet this frame filled holds this view's camera
  at<int32_t>(kView) = view ^ 1;  // alternate the camera the game renders
  if (!gauge_hooked) return;
  const bool match = gauges_match();
  if (gauge_split && !match) open_p2_gauge(false);
  else if (!gauge_split && match) open_p2_gauge(true);
  else if (gauge_split && (at<uint32_t>(kGauge[1] + kGaugeState) == 3 || at<uint32_t>(kGauge[1] + kGaugeState) == 4)) {
    // the game closed it (mission restart)
    reinterpret_cast<GaugeDrawFn>(base + kGaugeOpen)(base + kGauge[1]);
    at<uint64_t>(kGauge[1] + kGaugeScale) = 0;
    at<uint64_t>(kGauge[1] + kGaugeOffset) = 0;
  }
  if (gauge_split && at<uint64_t>(kNinpoIcons[1] + kNinpoLayout) != base + kNinpoOpenLayout) build_p2_ninpo(true);
  reticle_frame_end();
}

Mode mode() { return resolve(user_mode, monitors); }

const wchar_t* mode_name(Mode m) {
  switch (m) {
  case Vertical: return L"pantalla dividida vertical";
  case Horizontal: return L"pantalla dividida horizontal";
  case Dual: return L"un monitor por jugador";
  default: return L"automática";
  }
}

const wchar_t* cycle() {
  const Mode cur = mode();
  Mode next = cur == Vertical ? Horizontal : cur == Horizontal ? (monitors >= 2 ? Dual : Vertical) : Vertical;
  user_mode = next;
  save_mode();
  log("split: layout -> %ls", mode_name(next));
  return mode_name(next);
}

bool present(IDXGISwapChain* sc) {
  if (presenting_p2) return false;
  ID3D11Texture2D* bb = nullptr;
  if (FAILED(sc->GetBuffer(0, __uuidof(ID3D11Texture2D), reinterpret_cast<void**>(&bb)))) return true;
  backbuffer = bb;
  if (!hooked) {
    bb->GetDevice(&device);
    device->GetImmediateContext(&immediate);
    hook_context(immediate);
    DXGI_SWAP_CHAIN_DESC d;
    if (SUCCEEDED(sc->GetDesc(&d))) game_window = d.OutputWindow;
    hooked = true;
    scan_monitors();
    log("split: context hooked");
  }
  if (frames++ % 120 == 0) scan_monitors();
  {
    static ULONGLONG t0 = 0;
    if (frames % 1800 == 1) {
      const ULONGLONG now = GetTickCount64();
      D3D11_TEXTURE2D_DESC d;
      bb->GetDesc(&d);
      if (t0) log("split: presents %.1f/s, back buffer %ux%u, split %s", 1800000.0 / static_cast<double>(now - t0), d.Width, d.Height,
                  frame_active ? "on" : "off");
      t0 = now;
    }
  }
  ID3D11DeviceContext* c = immediate;
  keep_own_vtable();

  // Frame that just finished.
  if (frame_active && !gpu_failed) {
    if (!captured && final_rt && final_draws >= 1 && scene[0].tex) {  // no HUD this frame
      pick_view();
      c->CopySubresourceRegion(scene[frame_view].tex, 0, 0, 0, 0, final_rt, 0, nullptr);
      scene[frame_view].valid = scene[frame_view].dirty = true;
      hud[frame_view].valid = false;
    }
    if (!gpu_ready) gpu_ready = gpu_init(), gpu_failed = !gpu_ready;
    if (gpu_ready && scene[0].tex) {
      own_calls = true;
      ID3D11DeviceContext1* c1 = nullptr;
      if (SUCCEEDED(c->QueryInterface(__uuidof(ID3D11DeviceContext1), reinterpret_cast<void**>(&c1)))) {
        ID3DDeviceContextState* prev = nullptr;
        c1->SwapDeviceContextState(state, &prev);
        for (Target* t : {&scene[0], &scene[1], &hud[0], &hud[1]})
          if (t->dirty) {
            c->GenerateMips(t->srv);
            t->dirty = false;
          }
        const Mode m = mode();
        const bool paused = at<uint8_t>(kPaused) != 0;
        compose(c, bb, m, 0, paused);
        if (m == Dual && p2_shown && ensure_p2_chain()) {
          ID3D11Texture2D* p2bb = nullptr;
          if (SUCCEEDED(p2_chain->GetBuffer(0, __uuidof(ID3D11Texture2D), reinterpret_cast<void**>(&p2bb)))) {
            compose(c, p2bb, Dual, 1, paused);
            p2bb->Release();
          }
        }
        c1->SwapDeviceContextState(prev, nullptr);
        if (prev) prev->Release();
        c1->Release();
        if (m == Dual && p2_shown && p2_chain) {
          presenting_p2 = true;
          p2_chain->Present(0, 0);
          presenting_p2 = false;
        }
      }
      own_calls = false;
    }
  }

  // Player 2 in but no split views (menus, loading, results): their monitor mirrors the game.
  if (!frame_active && p2_joined && mode() == Dual && p2_shown && !gpu_failed) {
    if (!gpu_ready) gpu_ready = gpu_init(), gpu_failed = !gpu_ready;
    D3D11_TEXTURE2D_DESC d;
    bb->GetDesc(&d);
    if (gpu_ready && (mirror.w != d.Width || mirror.h != d.Height || !mirror.tex)) {
      if (!make_target(mirror, d)) log("split: mirror texture failed (%ux%u fmt %u)", d.Width, d.Height, d.Format);
    }
    if (gpu_ready && mirror.tex && ensure_p2_chain()) {
      own_calls = true;
      c->CopySubresourceRegion(mirror.tex, 0, 0, 0, 0, bb, 0, nullptr);
      ID3D11DeviceContext1* c1 = nullptr;
      ID3D11Texture2D* p2bb = nullptr;
      if (SUCCEEDED(c->QueryInterface(__uuidof(ID3D11DeviceContext1), reinterpret_cast<void**>(&c1))) &&
          SUCCEEDED(p2_chain->GetBuffer(0, __uuidof(ID3D11Texture2D), reinterpret_cast<void**>(&p2bb)))) {
        ID3DDeviceContextState* prev = nullptr;
        c1->SwapDeviceContextState(state, &prev);
        c->GenerateMips(mirror.srv);
        draw_mirror(c, p2bb);
        c1->SwapDeviceContextState(prev, nullptr);
        if (prev) prev->Release();
        presenting_p2 = true;
        p2_chain->Present(0, 0);
        presenting_p2 = false;
      }
      if (p2bb) p2bb->Release();
      if (c1) c1->Release();
      own_calls = false;
    }
  }

  // Next frame.
  const bool active = want_active && !gpu_failed;
  if (active != frame_active) {
    log(active ? "split: on (%ls)" : "split: off", mode_name(mode()));
    if (!active) {
      at<int32_t>(kView) = 0;
      scene[0].valid = scene[1].valid = hud[0].valid = hud[1].valid = false;
    }
  }
  show_p2_window((active || p2_joined) && mode() == Dual);
  frame_active = active;
  if (trace_draws) log("split: frame view %d tag %d:%s", frame_view, frame_tag, trace_line);
  trace_len = 0;
  trace_line[0] = 0;
  {
    static unsigned check = 0;
    static wchar_t path[MAX_PATH];
    if (!path[0]) { lstrcpyW(path, trace_flag); lstrcpyW(path + lstrlenW(path) - 4, L"-draws.txt"); }
    if (++check % 30 == 0) trace_draws = GetFileAttributesW(path) != INVALID_FILE_ATTRIBUTES;
  }
  final_draws = 0;
  scene_drawn = false;
  hud_phase = captured = false;
  need_tag = frame_active;
  frame_tag = -1;
  bb->Release();
  return true;
}
} // namespace split
