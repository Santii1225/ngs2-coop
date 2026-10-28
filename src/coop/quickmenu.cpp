#include "quickmenu.hpp"
#include "gametext.hpp"
#include <windows.h>
#include <cstdio>
#include <cmath>
#include <cstring>
#include <initializer_list>

// Quick selector in Team Missions (docs/QUICK_MENU.md).
//
// The pause controller 0x1413b0cb0 skips the D-pad (and everything else) while the Team Missions byte
// 0x14211e5cf is 1, so the game never opens its selector there. The mod opens it itself:
//  1. Each player's D-pad up runs the game's selector on a task of the mod, without the pause controller: no
//     pause, and the window is drawn on that player's view only (see "The selector, per player" below).
//  2. Preload: a mission only loads the equipment picked on the character screen. Changing to anything else
//     loads it on the fly and the game hangs a few seconds later. The player's inventory (0) is filled by the
//     player setup 0x1415dd080 through 0x1415d16f0(id, inventory) while the mission loads; adding the other
//     unlocked weapons, projectiles and ninpo there gets them loaded with the mission, as in story mode.
namespace quickmenu {
namespace {
void log_nothing(const char*, ...) {}
void (*log)(const char*, ...) = log_nothing;
uintptr_t image;
template<class T> volatile T& at(uintptr_t off) { return *reinterpret_cast<volatile T*>(image + off); }

constexpr uintptr_t kTeamMode = 0x211e5cf;   // byte: 1 in Team Missions

constexpr uintptr_t kGive = 0x15d16f0;       // give(id, inventory): adds the item unless already owned
constexpr uint8_t kGiveHead[15] = {0x48, 0x89, 0x5c, 0x24, 0x18, 0x57, 0x48, 0x83, 0xec, 0x20, 0x8b, 0xfa, 0x0f, 0xb7, 0xd9};

// Character screen, player 1's column (it keeps its values during the mission): +0x00 character (0 = Ryu),
// +0x18 u16 unlocked weapons (bit i = entry i of the weapon list), +0x1a unlocked projectiles, ninpo mask per
// character at +0x1c.
constexpr uintptr_t kP1Column = 0x215b6a0;
constexpr uintptr_t kColumnStride = 0x20;          // player 2's column follows
constexpr uintptr_t kRyuWeapons = 0x1803060, kRyuWeaponCount = 0x1803030;  // u32 ids / count per character
constexpr uintptr_t kRyuNinpo = 0x1803008;                                  // u32 ids
constexpr uint16_t kRyuProjectiles[2][2] = {{0x93, 0x94}, {0x151, 0x152}}; // projectile, item it brings
constexpr int kRyuNinpoCount = 4;
constexpr uintptr_t kRequestResources = 0x15ebda0;  // (id): adds the item and its linked items to the load batch
constexpr uintptr_t kRequestLinked = 0x15eaf10;     // (id): second request used by the equipment change
constexpr uintptr_t kInventory0 = 0x35c3c94;  // 128 entries: u16 id, u8 count, u8
constexpr uintptr_t kInventoryStride = 0x340;  // one inventory per player
constexpr int kInventorySlots = 128, kFirstExtraSlot = 20;

void clear_class_owners();

// Item database [0x141e37af0]: per item a list of (tag, value) pairs ending with a tag >= 0x3f; the value is an
// offset (x2, signed) into the database. Tag 0x24 (upgrades): +6 base level, +7 top level. The level the game
// gives a weapon or ninpo (0x14137a250) is min(inventory byte 3 + base, top), counted from 0 ("NIVEL 1").
constexpr uintptr_t kItemDb = 0x1e37af0;
const volatile uint8_t* item_tag(uint16_t id, uint32_t want) {
  const uintptr_t db = at<uintptr_t>(kItemDb);
  if (!db) return nullptr;
  const int32_t table = *reinterpret_cast<volatile int32_t*>(db + 0xc);
  const uintptr_t entry = db + *reinterpret_cast<volatile int32_t*>(db + table + id * 4);
  for (int k = 0; k < 40; ++k) {
    const uint32_t tag = *reinterpret_cast<volatile uint32_t*>(entry + k * 8);
    if (tag >= 0x3f) break;
    if (tag == want) {
      const int32_t v = static_cast<int32_t>(*reinterpret_cast<volatile uint32_t*>(entry + k * 8 + 4) << 1) >> 1;
      return reinterpret_cast<const volatile uint8_t*>(db + v);
    }
  }
  return nullptr;
}
// Inventory byte 3 that gives the item its top level (the extra equipment used to come in at level 1).
uint8_t max_level(uint16_t id) {
  const volatile uint8_t* up = item_tag(id, 0x24);
  return up ? up[7] : 0;
}

using GiveFn = void (*)(uint32_t, int32_t);
GiveFn give_original;
volatile LONG giving = 0;

void give_hook(uint32_t id, int32_t inventory) {
  give_original(id, inventory);
  if (at<uint8_t>(kTeamMode) == 1 && at<uint8_t>(0x21544fa) != 74) clear_class_owners();  // kScreen: a mission loads
  // Inventory i belongs to player i + 1, whose picks are in column i of the character screen.
  if (inventory < 0 || inventory > 1 || at<uint8_t>(kTeamMode) != 1) return;
  const uintptr_t column = kP1Column + inventory * kColumnStride;
  if (at<uint8_t>(column) != 0) return;  // only Ryu has more equipment to pick
  if (InterlockedExchange(&giving, 1)) return;  // our own calls below
  const uintptr_t inv = kInventory0 + inventory * kInventoryStride;
  const uint16_t weapons = at<uint16_t>(column + 0x18);
  const uint8_t projectiles = at<uint8_t>(column + 0x1a), ninpo = at<uint8_t>(column + 0x1c);
  // Same as tested by hand: plain entries (id, count 1) after the slots the loader is filling; the game packs
  // them behind the picked equipment on its next inventory update.
  uint16_t ids[32];
  int k = 0;
  const int count = at<int32_t>(kRyuWeaponCount);
  for (int i = 0; i < count && i < 16; ++i)
    if (weapons & (1u << i)) ids[k++] = at<uint32_t>(kRyuWeapons + i * 4) & 0xffff;
  for (int i = 0; i < 2; ++i)
    if (projectiles & (1u << i)) ids[k++] = kRyuProjectiles[i][0], ids[k++] = kRyuProjectiles[i][1];
  for (int i = 0; i < kRyuNinpoCount; ++i)
    if (ninpo & (1u << i)) ids[k++] = at<uint32_t>(kRyuNinpo + i * 4) & 0xffff;
  int n = 0, slot = kFirstExtraSlot;
  for (int i = 0; i < k && slot < kInventorySlots; ++i) {
    bool have = false;
    for (int j = 0; j < kInventorySlots && !have; ++j)
      have = at<uint8_t>(inv + j * 4 + 2) && at<uint16_t>(inv + j * 4) == ids[i];
    if (have) continue;
    at<uint16_t>(inv + slot * 4) = ids[i];
    at<uint8_t>(inv + slot * 4 + 2) = 1;
    at<uint8_t>(inv + slot * 4 + 3) = max_level(ids[i]);
    ++slot, ++n;
  }
  // The packs are not preloaded: the mission's weapon pack space only fits the picked equipment (a load of the
  // extra weapons fails, 0x1413c07b0 -> 0). A change loads the new pack over the old one; see change_hook.
  static ULONGLONG last = 0;
  if (GetTickCount64() - last > 5000) log("quick menu: Ryu's unlocked equipment added to player %d's inventory (%d items)", inventory + 1, n);
  last = GetTickCount64();
  InterlockedExchange(&giving, 0);
}

// Writes `len` bytes over live code: park callers on a 2-byte self-jump, write the tail, then the head.
void write_code(uint8_t* target, const uint8_t* bytes, size_t len) {
  DWORD old;
  VirtualProtect(target, len, PAGE_EXECUTE_READWRITE, &old);
  *reinterpret_cast<volatile uint16_t*>(target) = 0xfeeb;
  FlushInstructionCache(GetCurrentProcess(), target, 2);
  memcpy(target + 2, bytes + 2, len - 2);
  FlushInstructionCache(GetCurrentProcess(), target, len);
  *reinterpret_cast<volatile uint16_t*>(target) = *reinterpret_cast<const uint16_t*>(bytes);
  FlushInstructionCache(GetCurrentProcess(), target, 2);
  VirtualProtect(target, len, old, &old);
}

// Within rel32 reach of the image, relative to its base: Windows loads it with ASLR, Wine at 0x140000000.
uint8_t* alloc_near() {
  for (uintptr_t a = image + 0x7300000; a < image + 0x30000000; a += 0x100000)
    if (auto* p = static_cast<uint8_t*>(VirtualAlloc(reinterpret_cast<void*>(a), 0x1000, MEM_RESERVE | MEM_COMMIT, PAGE_EXECUTE_READWRITE)))
      return p;
  return nullptr;
}

bool install_give(uint8_t* tramp) {
  auto* target = reinterpret_cast<uint8_t*>(image + kGive);
  if (memcmp(target, kGiveHead, sizeof(kGiveHead))) {
    log("quick menu: unexpected bytes at the item give, equipment not preloaded");
    return false;
  }
  memcpy(tramp, kGiveHead, sizeof(kGiveHead));
  uint8_t* j = tramp + sizeof(kGiveHead);
  j[0] = 0xff; j[1] = 0x25; memset(j + 2, 0, 4);
  const uint64_t back = reinterpret_cast<uint64_t>(target + sizeof(kGiveHead));
  memcpy(j + 6, &back, 8);
  FlushInstructionCache(GetCurrentProcess(), tramp, 64);
  give_original = reinterpret_cast<GiveFn>(tramp);
  uint8_t patch[15];
  patch[0] = 0xff; patch[1] = 0x25; memset(patch + 2, 0, 4);
  const uint64_t to = reinterpret_cast<uint64_t>(&give_hook);
  memcpy(patch + 6, &to, 8);
  patch[14] = 0x90;
  write_code(target, patch, sizeof(patch));
  return true;
}
// Diagnostics for the hang: a weapon change sometimes frees the partner's weapon object while the partner still
// has it equipped; a task then reads its emptied data (null read at 0x14140a227) and the update thread dies.
// Log every release of a type-2 object (weapons, projectiles) that a player actor still has equipped, with the
// game code that asked for it.
constexpr uintptr_t kObjects = 0x3195300;    // 160 entries of 0x30: +0 object, +0x18 id, +0x1a kind, +0x1b tag
constexpr uintptr_t kPlayerActor = 0x211e760; // u8 per player: entry index
constexpr uintptr_t kRelease2 = 0x1376c20;   // (entry): frees a type-2 entry
constexpr uintptr_t kDispatch2 = 0x15d8e50;  // (index, entry, flag): type-2 branch of the release dispatcher
constexpr uint8_t kRelease2Head[14] = {0x40, 0x53, 0x48, 0x83, 0xec, 0x20, 0x48, 0x8b, 0xd9, 0xe8, 0x42, 0xc2, 0xeb, 0xff};
constexpr uint8_t kDispatch2Head[15] = {0x48, 0x89, 0x5c, 0x24, 0x08, 0x48, 0x89, 0x74, 0x24, 0x10, 0x57, 0x48, 0x83, 0xec, 0x50};

void check_release(uintptr_t entry, const char* path, void* caller) {
  if (at<uint8_t>(entry - image + 0x1a) != 2) return;
  const uint16_t id = at<uint16_t>(entry - image + 0x18);
  const uint8_t tag = at<uint8_t>(entry - image + 0x1b);
  for (int p = 0; p < 2; ++p) {
    const uint8_t a = at<uint8_t>(kPlayerActor + p);
    if (a >= 160) continue;
    const uintptr_t obj = at<uintptr_t>(kObjects + a * 0x30);
    if (!obj) continue;
    for (int s = 0; s < 8; ++s)
      if (*reinterpret_cast<volatile uint16_t*>(obj + 0x5ae6 + s * 2) == id &&
          *reinterpret_cast<volatile uint8_t*>(obj + 0x5b60 + s) == tag) {
        void* frames[16];
        const USHORT n = RtlCaptureStackBackTrace(0, 16, frames, nullptr);
        char chain[400];
        int k = 0;
        for (USHORT f = 0; f < n && k < 380; ++f) {
          const uintptr_t v = reinterpret_cast<uintptr_t>(frames[f]);
          if (v >= image && v < image + 0x2000000) k += snprintf(chain + k, sizeof(chain) - k, " +%llx", static_cast<unsigned long long>(v - image));
        }
        chain[k] = 0;
        log("quick menu: %s frees item %#x (tag %#x) still equipped by player %d (actor %d, slot %d), caller +%#llx, stack%s",
            path, id, tag, p + 1, a, s, static_cast<unsigned long long>(reinterpret_cast<uintptr_t>(caller) - image), chain);
      }
  }
}

using Release2Fn = void (*)(uintptr_t);
using Dispatch2Fn = void (*)(uint32_t, uintptr_t, uint32_t);
Release2Fn release2_original;
Dispatch2Fn dispatch2_original;
void release2_hook(uintptr_t entry) {
  check_release(entry, "release", __builtin_return_address(0));
  release2_original(entry);
}
void dispatch2_hook(uint32_t index, uintptr_t entry, uint32_t flag) {
  check_release(entry, "dispatch", __builtin_return_address(0));
  dispatch2_original(index, entry, flag);
}

void abs_jump(uint8_t* p, uint64_t to) {
  p[0] = 0xff; p[1] = 0x25; memset(p + 2, 0, 4);
  memcpy(p + 6, &to, 8);
}

using RequestFn = void (*)(uint32_t);

constexpr uintptr_t kDescOffsets = 0x1e38f30;    // per entry kind: offset of the resource descriptor in the object (-1 none)
constexpr uintptr_t kScreen = 0x21544fa;         // 74 = in a mission

// Trace of load requests (resource id, caller) in Team Missions, to see which packs the mission load asks for.
constexpr uintptr_t kAddRequest = 0x13c1bb0;  // (batch, resource id, ?, flag)
constexpr uint8_t kAddRequestHead[17] = {0x48, 0x89, 0x5c, 0x24, 0x08, 0x45, 0x32, 0xdb, 0xb8, 0xff, 0xff, 0x00, 0x00, 0x41, 0x0f, 0xb6, 0xd9};
using AddRequestFn = void (*)(uintptr_t, uint32_t, uint32_t, uint32_t);
AddRequestFn add_request_original;
volatile LONG requests_logged = 0;
void add_request_hook(uintptr_t batch, uint32_t res, uint32_t a, uint32_t flag) {
  if (at<uint8_t>(kTeamMode) == 1 && (at<uint8_t>(kScreen) == 74 || InterlockedIncrement(&requests_logged) < 800))
    log("quick menu: load request res %#x flag %u batch %#llx (%u queued) screen %u caller +%#llx", res & 0xffff, flag & 0xff,
        static_cast<unsigned long long>(batch), *reinterpret_cast<volatile uint8_t*>(batch + 0x721), at<uint8_t>(kScreen),
        static_cast<unsigned long long>(reinterpret_cast<uintptr_t>(__builtin_return_address(0)) - image));
  add_request_original(batch, res, a, flag);
}
bool install_request_trace(uint8_t* tramp) {
  auto* target = reinterpret_cast<uint8_t*>(image + kAddRequest);
  if (memcmp(target, kAddRequestHead, sizeof(kAddRequestHead))) return false;
  memcpy(tramp, kAddRequestHead, sizeof(kAddRequestHead));
  abs_jump(tramp + sizeof(kAddRequestHead), image + kAddRequest + sizeof(kAddRequestHead));
  FlushInstructionCache(GetCurrentProcess(), tramp, 64);
  add_request_original = reinterpret_cast<AddRequestFn>(tramp);
  uint8_t patch[17];
  abs_jump(patch, reinterpret_cast<uint64_t>(&add_request_hook));
  patch[14] = patch[15] = patch[16] = 0x90;
  write_code(target, patch, sizeof(patch));
  return true;
}

constexpr uintptr_t kProcessBatch = 0x13c07b0;   // (batch, ...): load what the batch requests; 1 when all loaded
using ProcessFn = uint8_t (*)(uintptr_t, uint32_t, uint32_t, uintptr_t, uintptr_t);

constexpr uintptr_t kMenuPlayer = 0x211e757;   // player whose equipment the change applies to
uintptr_t actor_object(int player) {
  const uint8_t a = at<uint8_t>(kPlayerActor + player);
  if (a >= 160 || at<uint8_t>(kObjects + a * 0x30 + 0x1a) != 0) return 0;
  return at<uintptr_t>(kObjects + a * 0x30);
}

// THE FIX. An equipment change (0x141630290(slot, id), player [0x14211e757]) unequips the slot, writes the new id,
// clears the "keep" flag (+0x39) of every loaded pack of the slot's class (descriptor mask match), queues the sweep
// job 0x1413ce590 that unloads every pack of the class still without it (freeing every object using them), then
// queues the load job 0x1413ce6f0 that fills the class's memory pools (mask | 1, mask | 2) from their start.
// Each player has its own pools per class (player 1: masks 0x604008xx, player 2/partner: 0x604020xx), but:
//  - when both picked the same item on the character screen the game loaded it once, in player 1's pools, so
//    player 1 dropping it unloaded the partner's copy too (null read at 0x14140a227 -> hang or crash);
//  - the change always uses player 1's descriptors, even for player 2.
// Fix: each class has an owner pair. A change sweeps and loads the pools of the class the changing player owns.
// When those pools also hold an item the other player still has equipped, the pools are handed over to the other
// player as they are (nothing unloaded) and the changing player moves to the other player's pools, which are then
// empty: one item set per pool, as the game expects, and nothing else to keep track of.
constexpr uintptr_t kSweepCall = 0x16304e7;    // in 0x141630290: call 0x1413ce590(class descriptor)
constexpr uintptr_t kLoadCall = 0x163050d;     // in 0x141630290: call 0x1413ce6f0(class descriptor)
constexpr uintptr_t kSweep = 0x13ce590;
constexpr uintptr_t kLoad = 0x13ce6f0;
constexpr uintptr_t kPacks = 0x2153ca0;        // 0x180 records of 0x40: +0x00 start, +0x08 end, +0x10 descriptor,
constexpr int kPackCount = 0x180;              // +0x32 resource id, +0x38 loaded, +0x39 keep
constexpr uintptr_t kDescriptors = 0x1e37a70;  // 0x60 x 0x20: +0x00 start, +0x08 end, +0x10 size, +0x14 mask, +0x1c kind
constexpr int kDescriptorCount = 0x60;
constexpr uint32_t kPlayer1Bit = 0x800, kPlayer2Bit = 0x2000;
constexpr uintptr_t kSlotTable = 0x35c3b80;   // per player (0x340): one resource pointer per equipment slot
using DescFn = uint32_t (*)(uintptr_t);

volatile uint8_t swapped[8];   // per class (mask bit 0x04/0x08/0x10/0x20 -> index): player 1 uses player 2's pools
struct PendingChange { uint8_t player, slot; uint16_t old_item, new_item; bool valid; } pending;
volatile uint16_t session_item = 0xffff;  // item the open selector session changed to (0xffff: none)
volatile LONG busy = 0;          // a selector session is open (one window for everyone: one at a time)

// The change's finishing step (0x14162fe40) re-checks every equipped item: it requests the item's resources and
// processes the batch (0x1413c07b0); when that says "not loaded" it sweeps and reloads the item's class and checks
// again next frame. Some items never pass while the world runs with two players: with player 1 on another
// character (Rachel), player 2's Arco de perdición (0x151) lacks auxiliary resources (0xd25, 0xd28, 0x1c57...)
// that no reload brings, so changing player 2's weapon looped forever ("0xffff -> 0xffff") and freed the bow.
// During a session only the item being changed is checked; the others stay as they were before the change.
constexpr uintptr_t kFinalizeRequestCall = 0x162ff64;  // call 0x1415eaf10(item)
constexpr uintptr_t kFinalizeProcessCall = 0x162ff80;  // call 0x1413c07b0(batch, 0xfffe, 1, 0, 0)
volatile uint16_t checked_item = 0xffff;
void finalize_request(uint32_t id) {
  checked_item = static_cast<uint16_t>(id);
  reinterpret_cast<RequestFn>(image + kRequestLinked)(id);
}
uint8_t finalize_process(uintptr_t batch, uint32_t a, uint32_t b, uintptr_t c, uintptr_t d) {
  if (busy && at<uint8_t>(kTeamMode) == 1 && at<uint8_t>(kScreen) == 74 && session_item != 0xffff && checked_item != session_item) return 1;
  return reinterpret_cast<ProcessFn>(image + kProcessBatch)(batch, a, b, c, d);
}
uintptr_t load_descriptor;     // the class the sweep chose, for the load that follows

int class_index(uint32_t mask) {
  for (int i = 0; i < 8; ++i) if ((mask & 0xff) == (4u << i)) return i;
  return -1;
}
uint32_t pack_mask(int r) {
  const uintptr_t desc = at<uintptr_t>(kPacks + r * 0x40 + 0x10);
  return desc ? *reinterpret_cast<volatile uint32_t*>(desc + 0x14) : 0;
}
bool in_class(int r, uint32_t mask) { return at<uint8_t>(kPacks + r * 0x40 + 0x38) && (pack_mask(r) & mask) == mask; }
uintptr_t find_descriptor(uint32_t mask) {
  for (int i = 0; i < kDescriptorCount; ++i)
    if (at<uint32_t>(kDescriptors + i * 0x20 + 0x14) == mask) return image + kDescriptors + i * 0x20;
  return 0;
}
bool has_equipped(int player, uint16_t id) {
  const uintptr_t obj = actor_object(player);
  if (!obj || id == 0xffff) return false;
  for (int s = 0; s < 8; ++s)
    if (*reinterpret_cast<volatile uint16_t*>(obj + 0x5ae6 + s * 2) == id) return true;
  return false;
}
bool active() { return at<uint8_t>(kTeamMode) == 1 && at<uint8_t>(kScreen) == 74; }

// Does a pack of the class hold an item `player` has equipped? (Objects point at their main pack: desc + 0x20.)
bool class_used_by(uint32_t mask, int player) {
  const uint8_t a = at<uint8_t>(kPlayerActor + player);
  if (a >= 160) return false;
  const uintptr_t obj = at<uintptr_t>(kObjects + a * 0x30);
  if (!obj) return false;
  for (int i = 0; i < 160; ++i) {
    const uint8_t kind = at<uint8_t>(kObjects + i * 0x30 + 0x1a);
    if (kind != 2) continue;
    const uint16_t id = at<uint16_t>(kObjects + i * 0x30 + 0x18);
    const uint8_t tag = at<uint8_t>(kObjects + i * 0x30 + 0x1b);
    bool equipped = false;
    for (int s = 0; s < 8 && !equipped; ++s)
      equipped = *reinterpret_cast<volatile uint16_t*>(obj + 0x5ae6 + s * 2) == id && *reinterpret_cast<volatile uint8_t*>(obj + 0x5b60 + s) == tag;
    if (!equipped) continue;
    const int64_t off = at<int64_t>(kDescOffsets + kind * 8);
    const uintptr_t item = at<uintptr_t>(kObjects + i * 0x30);
    if (off == -1 || !item) continue;
    const uintptr_t desc = *reinterpret_cast<volatile uintptr_t*>(item + off);
    const uintptr_t pk = desc ? *reinterpret_cast<volatile uintptr_t*>(desc + 0x20) : 0;
    for (int r = 0; r < kPackCount && pk; ++r)
      if (at<uintptr_t>(kPacks + r * 0x40) == pk && in_class(r, mask)) return true;
  }
  return false;
}

// A player's slot resources (table 0x1435c3b80 + 0x340 per player, one pointer per equipment slot) point into
// the packs the sweep frees until the finishing step stores the new ones. Their only reader, 0x14140a450 (called
// from 0x14140a650 by gameplay task 11 for the actor in [0x14219bf5d]), would read the freed data (faults at
// 0x14140a6ae, 0x14140a227); the game's own selector avoids it by pausing. While a change runs, that read returns
// nothing for the changing player's actor; the caller handles a null resource.
// (Holding task 11 instead stops the ground checks of both players: player 2 rose into the air, player 1 sank.)
constexpr uintptr_t kSlotResRead = 0x140a450, kSlotResReadCall = 0x140a67e;
constexpr uintptr_t kCurrentActor = 0x219bf5d;   // byte: object entry the gameplay task is updating
volatile LONG res_guard_actor = -1;
using SlotResFn = uintptr_t (*)(uintptr_t, uintptr_t, uintptr_t);
uintptr_t slot_res_hook(uintptr_t a, uintptr_t b, uintptr_t c) {
  if (res_guard_actor >= 0 && at<uint8_t>(kCurrentActor) == res_guard_actor) return 0;
  return reinterpret_cast<SlotResFn>(image + kSlotResRead)(a, b, c);
}

uint32_t sweep_hook(uintptr_t descriptor) {
  load_descriptor = descriptor;
  const uint32_t p1_mask = *reinterpret_cast<volatile uint32_t*>(descriptor + 0x14);
  const int ci = class_index(p1_mask);
  if (!active() || !(p1_mask & kPlayer1Bit) || ci < 0) return reinterpret_cast<DescFn>(image + kSweep)(descriptor);
  const uint8_t player = at<uint8_t>(kMenuPlayer) == 1 ? 1 : 0;
  const uint32_t p2_mask = (p1_mask & ~kPlayer1Bit) | kPlayer2Bit;
  auto owned_mask = [&](int pl) { return (pl == 1) != (swapped[ci] != 0) ? p2_mask : p1_mask; };
  uint32_t mask = owned_mask(player);
  // The other player uses these pools when one of their equipped objects points into them (weapons, projectiles),
  // or when the dropped item is theirs too and their own pools of the class are empty (ninpo have no object: the
  // game finds their packs by resource id when they are cast).
  bool their_pools_empty = true;
  for (int r = 0; r < kPackCount && their_pools_empty; ++r) their_pools_empty = !in_class(r, owned_mask(1 - player));
  const bool handed_over = class_used_by(mask, 1 - player) ||
                           (pending.valid && their_pools_empty && has_equipped(1 - player, pending.old_item));
  if (handed_over) {
    swapped[ci] = !swapped[ci];
    mask = owned_mask(player);
  }
  const uintptr_t desc = find_descriptor(mask);
  if (!desc) return reinterpret_cast<DescFn>(image + kSweep)(descriptor);
  if (mask != p1_mask) {
    // The game cleared player 1's class: give it back, clear the class being changed instead.
    for (int r = 0; r < kPackCount; ++r) {
      if (in_class(r, p1_mask)) at<uint8_t>(kPacks + r * 0x40 + 0x39) = 1;
      if (in_class(r, mask)) at<uint8_t>(kPacks + r * 0x40 + 0x39) = 0;
    }
  }
  load_descriptor = desc;
  InterlockedExchange(&res_guard_actor, at<uint8_t>(kPlayerActor + player));  // released when the session ends
  log("quick menu: player %d change %#x -> %#x (slot %u) in pools %#x%s", player + 1, pending.valid ? pending.old_item : 0xffff,
      pending.valid ? pending.new_item : 0xffff, pending.valid ? pending.slot : 0xff, mask,
      handed_over ? " (the other player still uses the old pools: handed over)" : "");
  pending.valid = false;
  return reinterpret_cast<DescFn>(image + kSweep)(desc);
}

void clear_class_owners() {
  for (volatile uint8_t& c : swapped) c = 0;
}

uint32_t load_hook(uintptr_t descriptor) {
  const uintptr_t desc = load_descriptor ? load_descriptor : descriptor;
  load_descriptor = 0;
  return reinterpret_cast<DescFn>(image + kLoad)(desc);
}

// Selector apply (0x1413cfec1 -> 0x141630290(slot, id)): note what the change replaces for the hooks above.
constexpr uintptr_t kChangeCall = 0x13cfec1;
constexpr uintptr_t kRequestChange = 0x1630290;
using ChangeFn = uint8_t (*)(uint32_t, uint32_t);
// A weapon or projectile the partner has equipped is refused (reported as done, nothing changes). The second copy would share the
// partner's pack, and when either player later drops the item the pack is unloaded with both objects (the other
// player's weapon freed while equipped: crashes at 0x1413961c8 / 0x14140a227 in the play test of 2026-10-11).
// Equal picks on the character screen are fine: the mission loads each player's copy on its own.
volatile LONG refused_notice = 0;  // player (1/2) whose change was refused, shown by frame() on the game's banner
uint8_t change_hook(uint32_t slot, uint32_t id) {
  const uint8_t player = at<uint8_t>(kMenuPlayer);
  session_item = static_cast<uint16_t>(id);  // also when refused: the finishing step then checks nothing else
  const uintptr_t partner = player < 2 ? actor_object(1 - player) : 0;
  bool shared = false;
  for (int k = 0; k < 2 && partner; ++k)  // weapon and projectile (ninpo have no object of their own)
    shared |= *reinterpret_cast<volatile uint16_t*>(partner + 0x5ae6 + k * 2) == static_cast<uint16_t>(id);
  if (active() && shared) {
    log("quick menu: player %d change to %#x refused, the partner has it equipped", player + 1, id & 0xffff);
    refused_notice = player + 1;
    return 1;
  }
  const uintptr_t obj = player < 2 ? actor_object(player) : 0;
  const uintptr_t slots = obj ? obj + 0x5ae6 : 0;
  if (slots && (slot & 0xff) < 8)
    pending = {player, static_cast<uint8_t>(slot), *reinterpret_cast<volatile uint16_t*>(slots + (slot & 0xff) * 2),
               static_cast<uint16_t>(id), true};
  return reinterpret_cast<ChangeFn>(image + kRequestChange)(slot, id);
}

bool calls_to(uintptr_t site, uintptr_t expected) {
  auto* call = reinterpret_cast<uint8_t*>(image + site);
  int32_t rel;
  memcpy(&rel, call + 1, 4);
  return call[0] == 0xe8 && image + site + 5 + rel == image + expected;
}

bool patch_call(uintptr_t site, uintptr_t expected, uint8_t* stub, uint64_t to) {
  auto* call = reinterpret_cast<uint8_t*>(image + site);
  int32_t rel;
  memcpy(&rel, call + 1, 4);
  if (call[0] != 0xe8 || image + site + 5 + rel != image + expected) return false;
  abs_jump(stub, to);
  FlushInstructionCache(GetCurrentProcess(), stub, 14);
  uint8_t patch[5] = {0xe8};
  const int32_t d = static_cast<int32_t>(reinterpret_cast<int64_t>(stub) - static_cast<int64_t>(image + site + 5));
  memcpy(patch + 1, &d, 4);
  write_code(call, patch, 5);
  return true;
}

bool install_shared_pack_fix(uint8_t* stubs) {
  if (!calls_to(kChangeCall, kRequestChange) || !calls_to(kSweepCall, kSweep) || !calls_to(kLoadCall, kLoad)) {
    log("quick menu: unexpected bytes at the equipment change, shared packs not protected");
    return false;
  }
  patch_call(kChangeCall, kRequestChange, stubs, reinterpret_cast<uint64_t>(&change_hook));
  patch_call(kSweepCall, kSweep, stubs + 0x10, reinterpret_cast<uint64_t>(&sweep_hook));
  patch_call(kLoadCall, kLoad, stubs + 0x20, reinterpret_cast<uint64_t>(&load_hook));
  return true;
}

bool install_release_logs(uint8_t* tramp) {
  auto* r2 = reinterpret_cast<uint8_t*>(image + kRelease2);
  auto* d2 = reinterpret_cast<uint8_t*>(image + kDispatch2);
  if (memcmp(r2, kRelease2Head, sizeof(kRelease2Head)) || memcmp(d2, kDispatch2Head, sizeof(kDispatch2Head))) {
    log("quick menu: unexpected bytes at the item release, no release log");
    return false;
  }
  // release: push rbx; sub rsp,0x20; mov rbx,rcx; then the call (rel32, rebuilt as mov rax,imm64; call rax).
  uint8_t* p = tramp;
  memcpy(p, kRelease2Head, 9); p += 9;
  const uint64_t callee = image + kRelease2 + 14 + static_cast<int32_t>(0xffebc242);
  p[0] = 0x48; p[1] = 0xb8; memcpy(p + 2, &callee, 8); p[10] = 0xff; p[11] = 0xd0; p += 12;
  abs_jump(p, image + kRelease2 + 14); p += 14;
  release2_original = reinterpret_cast<Release2Fn>(tramp);
  // dispatch: plain prologue.
  uint8_t* q = tramp + 64;
  memcpy(q, kDispatch2Head, sizeof(kDispatch2Head));
  abs_jump(q + sizeof(kDispatch2Head), image + kDispatch2 + sizeof(kDispatch2Head));
  dispatch2_original = reinterpret_cast<Dispatch2Fn>(q);
  FlushInstructionCache(GetCurrentProcess(), tramp, 128);
  uint8_t patch[15];
  abs_jump(patch, reinterpret_cast<uint64_t>(&release2_hook));
  write_code(r2, patch, 14);
  abs_jump(patch, reinterpret_cast<uint64_t>(&dispatch2_hook));
  patch[14] = 0x90;
  write_code(d2, patch, 15);
  return true;
}

// ---- The selector, per player: the game's own window ----------------------------------------------
// The game's selector (pause controller 0x1413b0200 -> prepare 0x1413d0f20, then the pause task runs the selector
// loop 0x1413d0c30 until the row [0x14215b754] is 4) reads the pad slot in [0x14211e754] (player 1's) and applies
// to player [0x14211e757], with the game paused. The mod runs the same prepare and loop on a game task of its
// own, without the pause controller (so nothing pauses): while that task's fiber runs, the selector reads the
// player's pad slot (D-pad, A and B only) and applies to that player. Everywhere else that slot lacks the D-pad and
// face buttons, so their character can still walk, guard and turn the camera. (A spare slot instead brings up the game's "connect a controller" notice: the menus check their pad is
// connected.) The swap follows the fiber: the game's SwitchToFiber import is wrapped, so the rest of the game
// never sees it. The window is one widget for everyone (0x146839440): one session at a time, drawn on that
// player's view only.
// Scheduler: 24 tasks at 0x142235a80 (stride 0x28: +0 state (1 = run, |8 = finished), +4 frames to wait,
// +8 fiber); the current one in [0x1421ae54c]; a task yields by setting its wait and switching to the main
// fiber [0x142235e40]. Slot 23 is unused by the game.
constexpr uintptr_t kTasks = 0x2235a80, kMainFiber = 0x2235e40;
constexpr int kOurTask = 23;
constexpr uintptr_t kFinalizeSweepCall = 0x1630026, kFinalizeLoadCall = 0x163002e;
constexpr uintptr_t kSlotResStore = 0x16300c7;      // mov [rdi + rsi*8 + 0x35c3b80], rax: player 1's table only
constexpr uint8_t kSlotResStoreBytes[8] = {0x48, 0x89, 0x84, 0xf7, 0x80, 0x3b, 0x5c, 0x03};
constexpr uintptr_t kSelectorState = 0x215b750;    // game selector: 1 browsing, 2 applying
constexpr uintptr_t kSelectorRow = 0x215b754;      // 0 ninpo, 1 projectiles, 2 weapons, 3 items, 4 closed
constexpr uintptr_t kSelectorRow2 = 0x215b758;
constexpr uintptr_t kSelectorCursors = 0x215b760;  // 4 x int
constexpr uintptr_t kPauseType = 0x1e3a8bc;         // pause controller +0x04: 0 nothing, 1 pause, 2 selector
constexpr uintptr_t kPaused = 0x1e3a8c2;            // byte: pause count
constexpr uintptr_t kMenuPad = 0x211e754;          // byte: pad slot the menus read (player 1's)
constexpr uintptr_t kPrepare = 0x13d0f20, kSelectorLoop = 0x13d0c30;
constexpr uintptr_t kWidgetAnim = 0x15549c0;       // (?, kind): 1 close, 2 open, 3-7 slides
constexpr uintptr_t kSwitchToFiberImport = 0x179e240;
constexpr uintptr_t kWidgetDrawSlot = 0x1900980;   // vtable 0x141900960 + 0x20: the window's draw (0x141556600)
constexpr uintptr_t kView = 0x2ff2778;             // camera of the frame being built (split.cpp alternates it)
using VoidFn = void (*)();
using AnimFn = void (*)(uintptr_t, uint32_t);
using FiberFn = void(WINAPI*)(void*);

volatile uint8_t* session_flag = nullptr;  // in the stub page: 1 while a selector session runs and 2 s after (install_stop_guard)
FiberFn game_switch = nullptr;    // the game's SwitchToFiber before our wrapper
void* volatile sel_fiber = nullptr;
volatile uint8_t sel_player = 0;  // whose session (0 = player 1)
volatile uint8_t sel_slot = 0;    // their pad slot
constexpr uintptr_t kPads = 0x2235880, kPadStride = 0x38;
uint8_t pad_real[kPadStride];     // their pad this frame (their slot itself is blanked)
uint8_t pad_blank[kPadStride];
uint8_t saved_menu_pad = 0;
// Screen blur (0x141334670): requested state [0x142122974] (1 fade in, 4 fade out), current [0x142122970]
// (0 none), byte [0x14211e77b] = new request. The selector loop asks for the blur as it starts, and for its end
// when an item is picked; it would blur both views, so both requests are withdrawn before the blur sees them.
constexpr uintptr_t kBlurTarget = 0x2122974, kBlurState = 0x2122970, kBlurNew = 0x211e77b;
volatile bool unblur_pending = false;

// The selector's own variables (state 0x14215b750, rows 0x14215b754/758) are read by the gameplay code too: while
// they say "open" the character takes no input (in the game's flow the selector pauses anyway). They only read
// "open" on the selector's fiber; everywhere else they read closed (0, 4, 4) and the real values wait in sel_vars.
constexpr uintptr_t kSelectorVars[3] = {0x215b750, 0x215b754, 0x215b758};
constexpr uint32_t kSelectorClosed[3] = {0, 4, 4};
volatile uint32_t sel_vars[3];
volatile bool sel_vars_held = false;

void sel_enter() {
  if (sel_vars_held)
    for (int i = 0; i < 3; ++i) at<uint32_t>(kSelectorVars[i]) = sel_vars[i];
  sel_vars_held = false;
  saved_menu_pad = at<uint8_t>(kMenuPad);
  at<uint8_t>(kMenuPad) = sel_slot;
  at<uint8_t>(kMenuPlayer) = sel_player;
  volatile uint8_t* pd = &at<uint8_t>(kPads + sel_slot * kPadStride);
  for (uintptr_t i = 0; i < kPadStride; ++i) pad_blank[i] = pd[i], pd[i] = pad_real[i];
}
void sel_leave() {
  if (unblur_pending) {
    unblur_pending = false;
    if (at<uint32_t>(kBlurTarget) == 1 && at<uint32_t>(kBlurState) == 0) {
      at<uint32_t>(kBlurTarget) = 0;
      at<uint8_t>(kBlurNew) = 0;
    }
  }
  volatile uint8_t* pd = &at<uint8_t>(kPads + sel_slot * kPadStride);
  for (uintptr_t i = 0; i < kPadStride; ++i) pd[i] = pad_blank[i];
  for (int i = 0; i < 3; ++i) {
    sel_vars[i] = at<uint32_t>(kSelectorVars[i]);
    at<uint32_t>(kSelectorVars[i]) = kSelectorClosed[i];
  }
  sel_vars_held = true;
  at<uint8_t>(kMenuPad) = saved_menu_pad;
  at<uint8_t>(kMenuPlayer) = 0;
}
void WINAPI switch_hook(void* to) {
  if (sel_fiber && GetCurrentFiber() == sel_fiber) {
    sel_leave();
    game_switch(to);
    sel_enter();
  } else {
    game_switch(to);
  }
}

void task_yield(int frames) {
  volatile uint32_t* t = reinterpret_cast<volatile uint32_t*>(image + kTasks + kOurTask * 0x28);
  t[0] &= ~4u;
  t[1] = static_cast<uint32_t>(frames);
  game_switch(*reinterpret_cast<void* volatile*>(image + kMainFiber));
}

void swap_inventories() {
  volatile uint32_t* a = &at<uint32_t>(kInventory0);
  volatile uint32_t* b = &at<uint32_t>(kInventory0 + kInventoryStride);
  for (int k = 0; k < kInventorySlots; ++k) {
    const uint32_t t = a[k];
    a[k] = b[k];
    b[k] = t;
  }
}

void CALLBACK selector_task(void*) {
  // Never alongside the pause menu: it uses the same game state.
  while (at<uint32_t>(kPauseType) != 0) task_yield(1);
  sel_enter();
  // As the pause controller opens the weapons row (0x1413b0200).
  at<uint64_t>(kSelectorCursors) = 0;
  at<uint64_t>(kSelectorCursors + 8) = 0;
  at<uint32_t>(kSelectorState) = 0;
  at<uint32_t>(kSelectorRow2) = 2;
  at<uint32_t>(kSelectorRow) = 2;
  log("quick menu: player %u selector open (pad slot %u)", sel_player + 1, sel_slot);
  // The rows are built from player 1's inventory and marked equipped from the first object entry (0x1413f1f30:
  // inventory 0, [0x143195300] + 0x5ae6): player 2's inventory and object stand in for the call (it does not
  // yield, so no other game code sees the swap).
  if (sel_player == 1) {
    const uintptr_t p2_obj = actor_object(1);
    const uintptr_t first_obj = at<uintptr_t>(kObjects);
    swap_inventories();
    if (p2_obj) at<uintptr_t>(kObjects) = p2_obj;
    reinterpret_cast<VoidFn>(image + kPrepare)();
    at<uintptr_t>(kObjects) = first_obj;
    swap_inventories();
  } else {
    reinterpret_cast<VoidFn>(image + kPrepare)();
  }
  unblur_pending = true;
  reinterpret_cast<VoidFn>(image + kSelectorLoop)();
  if (at<uint32_t>(kBlurTarget) == 4 && at<uint32_t>(kBlurState) == 0) {
    at<uint32_t>(kBlurTarget) = 0;
    at<uint8_t>(kBlurNew) = 0;
  }
  reinterpret_cast<AnimFn>(image + kWidgetAnim)(0, 1);  // close
  sel_leave();
  InterlockedExchange(&res_guard_actor, -1);
  log("quick menu: player %u selector closed", sel_player + 1);
  sel_fiber = nullptr;
  session_item = 0xffff;
  // session_flag stays up for the watch after the session (frame()): the change's last loads finish a few frames
  // after the window closes and the equipment update would stop the world then.
  InterlockedExchange(&busy, 0);
  volatile uint32_t* t = reinterpret_cast<volatile uint32_t*>(image + kTasks + kOurTask * 0x28);
  t[0] |= 8u;  // finished: the scheduler deletes the fiber
  for (;;) game_switch(*reinterpret_cast<void* volatile*>(image + kMainFiber));
}

bool start_selector(uint8_t player, uint8_t slot) {
  volatile uint32_t* t = reinterpret_cast<volatile uint32_t*>(image + kTasks + kOurTask * 0x28);
  if (!game_switch || busy || t[0] != 0 || *reinterpret_cast<void* volatile*>(image + kTasks + kOurTask * 0x28 + 8)) return false;
  if (at<uint32_t>(kPauseType) != 0 || at<uint8_t>(kPaused) != 0) return false;
  void* fiber = CreateFiber(0x40000, selector_task, nullptr);
  if (!fiber) return false;
  sel_player = player;
  sel_slot = slot;
  InterlockedExchange(&busy, 1);
  if (session_flag) *session_flag = 1;
  sel_fiber = fiber;
  *reinterpret_cast<void* volatile*>(image + kTasks + kOurTask * 0x28 + 8) = fiber;
  t[1] = 1;
  t[0] = 1;  // runs from the scheduler's next pass
  return true;
}

// The window's draw (vtable slot of the widget, update thread, after the camera pick): during a session, only on
// frames of that player's view (with one view only, the view is always 0).
using DrawFn = void (*)(uintptr_t);
DrawFn widget_draw_original = nullptr;
void widget_draw_hook(uintptr_t widget) {
  if (busy && (at<int32_t>(kView) ? 1 : 0) != sel_player) return;
  widget_draw_original(widget);
}

bool install_window() {
  auto* imp = reinterpret_cast<FiberFn volatile*>(image + kSwitchToFiberImport);
  auto* slot = reinterpret_cast<DrawFn volatile*>(image + kWidgetDrawSlot);
  if (!*imp || reinterpret_cast<uintptr_t>(*slot) != image + 0x1556600) return false;
  DWORD old;
  game_switch = *imp;
  VirtualProtect(const_cast<FiberFn*>(imp), 8, PAGE_READWRITE, &old);
  *imp = &switch_hook;
  VirtualProtect(const_cast<FiberFn*>(imp), 8, old, &old);
  widget_draw_original = *slot;
  VirtualProtect(const_cast<DrawFn*>(slot), 8, PAGE_READWRITE, &old);
  *slot = &widget_draw_hook;
  VirtualProtect(const_cast<DrawFn*>(slot), 8, old, &old);
  return true;
}

// The game's change finishing step stores the new item's resource in player 1's table whatever the player.
bool install_slot_store_fix(uint8_t* stub) {
  auto* target = reinterpret_cast<uint8_t*>(image + kSlotResStore);
  if (memcmp(target, kSlotResStoreBytes, sizeof(kSlotResStoreBytes))) return false;
  uint8_t* p = stub;
  auto emit = [&](std::initializer_list<uint8_t> b) { for (uint8_t x : b) *p++ = x; };
  auto rel32 = [&](uintptr_t to, int tail) { const int32_t d = static_cast<int32_t>(static_cast<int64_t>(to) - reinterpret_cast<int64_t>(p + 4 + tail)); memcpy(p, &d, 4); p += 4; };
  emit({0x51});                                         // push rcx
  emit({0x0f, 0xb6, 0x0d}); rel32(image + kMenuPlayer, 0); // movzx ecx, byte [menu player]
  emit({0x83, 0xe1, 0x01});                             // and ecx, 1
  emit({0x69, 0xc9, 0x40, 0x03, 0x00, 0x00});           // imul ecx, ecx, 0x340
  emit({0x48, 0x01, 0xf9});                             // add rcx, rdi (image base)
  emit({0x48, 0x89, 0x84, 0xf1, 0x80, 0x3b, 0x5c, 0x03}); // mov [rcx + rsi*8 + 0x35c3b80], rax
  emit({0x59});                                         // pop rcx
  emit({0xe9}); rel32(image + kSlotResStore + 8, 0);    // jmp back
  FlushInstructionCache(GetCurrentProcess(), stub, p - stub);
  uint8_t patch[8] = {0xe9, 0, 0, 0, 0, 0x90, 0x90, 0x90};
  const int32_t d = static_cast<int32_t>(reinterpret_cast<int64_t>(stub) - static_cast<int64_t>(image + kSlotResStore + 5));
  memcpy(patch + 1, &d, 4);
  write_code(target, patch, sizeof(patch));
  return true;
}

// A change can leave the world stopped: the equipment update 0x1415da010 stops the gameplay tasks (task group 3,
// 0x141468f00) and sets the world-stop byte 0x14211e753 when it believes the game is paused. While the change runs
// that stop is part of it (undoing it then left the new weapon without its object); the pause controller lifts it
// when a pause ends (0x1413b1117: byte to 0, 0x141468d90(3)), but the selector no longer pauses, so it could stay
// (the image froze and the split views broke). After a session closes, a world stop without a pause that lasts 10
// frames is lifted the same way (watched for 2 s).
constexpr uintptr_t kWorldStop = 0x211e753;
constexpr uintptr_t kPauseCtrl = 0x1e3a8b8;          // pause controller: +0x0a world stop wanted, +0x0b applied
constexpr uintptr_t kResumeTasks = 0x1468d90;        // (group)
using GroupFn = void (*)(uint32_t);
int world_watch = 0, world_stopped = 0, world_loading = 0;
bool freeze_traced = false;
// Diagnostics (plugin/ngs2coop-trace-loads.txt): who calls the world stop 0x1415da0c0 (cinematics, events, ...).
constexpr uintptr_t kWorldFreeze = 0x15da0c0;
constexpr uint8_t kWorldFreezeHead[7] = {0x4c, 0x8b, 0x05, 0x29, 0x17, 0x23, 0x00};  // mov r8, [rip+0x231729]
volatile uint64_t freeze_trace[2] = {0, 0};  // last caller, calls
uint64_t freeze_seen = 0;
bool install_freeze_trace(uint8_t* stub) {
  auto* target = reinterpret_cast<uint8_t*>(image + kWorldFreeze);
  if (memcmp(target, kWorldFreezeHead, sizeof(kWorldFreezeHead))) return false;
  uint8_t* p = stub;
  auto emit = [&](std::initializer_list<uint8_t> b) { for (uint8_t x : b) *p++ = x; };
  auto imm64 = [&](uint64_t v) { memcpy(p, &v, 8); p += 8; };
  emit({0x51, 0x50});                                    // push rcx; push rax
  emit({0x48, 0x8b, 0x44, 0x24, 0x10});                  // mov rax, [rsp+0x10] (return address)
  emit({0x48, 0xb9}); imm64(reinterpret_cast<uint64_t>(&freeze_trace[0]));  // mov rcx, &freeze_trace
  emit({0x48, 0x89, 0x01});                              // mov [rcx], rax
  emit({0xf0, 0x48, 0xff, 0x41, 0x08});                  // lock inc qword [rcx+8]
  emit({0x58, 0x59});                                    // pop rax; pop rcx
  emit({0x49, 0xb8}); imm64(image + kWorldFreeze + 7 + 0x231729);  // mov r8, &qword
  emit({0x4d, 0x8b, 0x00});                              // mov r8, [r8]
  emit({0xe9});
  const int32_t back = static_cast<int32_t>(static_cast<int64_t>(image + kWorldFreeze + 7) - reinterpret_cast<int64_t>(p + 4));
  memcpy(p, &back, 4); p += 4;
  FlushInstructionCache(GetCurrentProcess(), stub, p - stub);
  uint8_t patch[7] = {0xe9, 0, 0, 0, 0, 0x90, 0x90};
  const int32_t d = static_cast<int32_t>(reinterpret_cast<int64_t>(stub) - static_cast<int64_t>(image + kWorldFreeze + 5));
  memcpy(patch + 1, &d, 4);
  write_code(target, patch, sizeof(patch));
  return true;
}
// The same for the task group stop 0x141468f00(group) that a world stop ends in.
constexpr uintptr_t kSuspendTasks = 0x1468f00;
constexpr uint8_t kSuspendHead[10] = {0x48, 0x63, 0xc1, 0x4c, 0x8d, 0x0d, 0xf6, 0x70, 0xb9, 0xfe};
volatile uint64_t suspend_trace[3] = {0, 0, 0};  // last caller, calls, group
uint64_t suspend_seen = 0;
bool install_suspend_trace(uint8_t* stub) {
  auto* target = reinterpret_cast<uint8_t*>(image + kSuspendTasks);
  if (memcmp(target, kSuspendHead, sizeof(kSuspendHead))) return false;
  uint8_t* p = stub;
  auto emit = [&](std::initializer_list<uint8_t> b) { for (uint8_t x : b) *p++ = x; };
  auto imm64 = [&](uint64_t v) { memcpy(p, &v, 8); p += 8; };
  emit({0x51, 0x50});                                    // push rcx; push rax
  emit({0x48, 0x8b, 0x44, 0x24, 0x10});                  // mov rax, [rsp+0x10]
  emit({0x50});                                          // push rax (return address)
  emit({0x48, 0xb8}); imm64(reinterpret_cast<uint64_t>(&suspend_trace[0]));  // mov rax, &suspend_trace
  emit({0x48, 0x89, 0x48, 0x10});                        // mov [rax+0x10], rcx (group)
  emit({0x59});                                          // pop rcx (return address)
  emit({0x48, 0x89, 0x08});                              // mov [rax], rcx
  emit({0xf0, 0x48, 0xff, 0x40, 0x08});                  // lock inc qword [rax+8]
  emit({0x58, 0x59});                                    // pop rax; pop rcx
  emit({0x48, 0x63, 0xc1});                              // movsxd rax, ecx
  emit({0x49, 0xb9}); imm64(image);                      // mov r9, image base (was lea r9, [rip - 0x1468f0a])
  emit({0xe9});
  const int32_t back = static_cast<int32_t>(static_cast<int64_t>(image + kSuspendTasks + 10) - reinterpret_cast<int64_t>(p + 4));
  memcpy(p, &back, 4); p += 4;
  FlushInstructionCache(GetCurrentProcess(), stub, p - stub);
  uint8_t patch[10] = {0xe9, 0, 0, 0, 0, 0x90, 0x90, 0x90, 0x90, 0x90};
  const int32_t d = static_cast<int32_t>(reinterpret_cast<int64_t>(stub) - static_cast<int64_t>(image + kSuspendTasks + 5));
  memcpy(patch + 1, &d, 4);
  write_code(target, patch, sizeof(patch));
  return true;
}
void log_freezes() {
  const uint64_t ns = suspend_trace[1];
  if (ns != suspend_seen) {
    log("quick menu: task group %llu stopped by %p (%llu calls)%s world stop %u", static_cast<unsigned long long>(suspend_trace[2]),
        reinterpret_cast<void*>(suspend_trace[0]), static_cast<unsigned long long>(ns - suspend_seen),
        busy ? " in a session" : world_watch > 0 ? " after a session" : "", at<uint8_t>(kWorldStop));
    suspend_seen = ns;
  }
  const uint64_t n = freeze_trace[1];
  if (n == freeze_seen) return;
  log("quick menu: world stop by %p (%llu calls)%s", reinterpret_cast<void*>(freeze_trace[0]), static_cast<unsigned long long>(n - freeze_seen),
      busy ? " in a session" : world_watch > 0 ? " after a session" : "");
  freeze_seen = n;
}


// A load the game waits for with the world stopped (0x141635130: an object whose resource is not in yet stops the
// world, waits on 0x1413cece0 and resumes it itself); lifting the stop then left the new weapon without its object.
// 0x1413cece0: the 32 loaders (stride 0x788) are idle when their state is 3.
constexpr uintptr_t kLoaders = 0x21452ac, kLoaderStride = 0x788;
constexpr int kLoaderCount = 32;
bool loads_busy() {
  for (int i = 0; i < kLoaderCount; ++i)
    if (at<uint32_t>(kLoaders + i * kLoaderStride) != 3) return true;
  return false;
}
void watch_world_stop() {
  if (!at<uint8_t>(kWorldStop) || at<uint8_t>(kPaused) || at<uint32_t>(kPauseType) || at<uint8_t>(kPauseCtrl + 0x0a)) {
    world_stopped = world_loading = 0;
    return;
  }
  if (world_loading < 300 && loads_busy()) {
    ++world_loading;  // the game resumes the world when its load is in (5 s at most)
    world_stopped = 0;
    if (world_watch < 2) world_watch = 2;
    return;
  }
  if (++world_stopped < 10) return;
  world_stopped = world_loading = 0;
  at<uint8_t>(kWorldStop) = 0;
  reinterpret_cast<GroupFn>(image + kResumeTasks)(3);
  log("quick menu: world stop left by an equipment change lifted");
}

// An object whose resource is not in yet (0x141635130) stops the world, waits for the loaders and resumes it. Run
// from a gameplay task (a change made without the pause, the new weapon's object) the stop suspends that task too:
// it never resumes the world (the safety net then lifted it with the object half made). While a session runs and
// for the watch after it, that stop and its resume are skipped: the wait for the loaders still runs.
constexpr uintptr_t kLoadStopCall = 0x16351d3, kLoadResumeCall = 0x16351f1, kWorldResume = 0x15da010;
volatile bool load_stop_skipped = false;
void load_stop_hook() {
  if (session_flag && *session_flag) {
    load_stop_skipped = true;
    return;
  }
  reinterpret_cast<VoidFn>(image + kWorldFreeze)();
}
void load_resume_hook() {
  if (load_stop_skipped) {
    load_stop_skipped = false;
    return;
  }
  reinterpret_cast<VoidFn>(image + kWorldResume)();
}

// A change finished while the character is busy (attacking) can create the new weapon's object but leave the
// player's slot tag at 0xff (0x14137bce7: the slot is tagged before the item's resource resolves, and nothing tags
// it again). The object is there and works, but the slot no longer names it: the release and class checks (here
// and in the game) then miss a weapon in use. After a session, an equipped weapon or projectile tagged 0xff whose
// object exists for that player gets the object's tag.
void repair_slot_tags() {
  for (int p = 0; p < 2; ++p) {
    const uint8_t a = at<uint8_t>(kPlayerActor + p);
    if (a >= 160) continue;
    const uintptr_t obj = at<uintptr_t>(kObjects + a * 0x30);
    if (!obj) continue;
    for (int s = 0; s < 2; ++s) {
      const uint16_t id = *reinterpret_cast<volatile uint16_t*>(obj + 0x5ae6 + s * 2);
      volatile uint8_t* tag = reinterpret_cast<volatile uint8_t*>(obj + 0x5b60 + s);
      if (id == 0xffff || *tag != 0xff) continue;
      for (int i = 0; i < 160; ++i) {
        const uintptr_t e = kObjects + i * 0x30;
        if (at<uint8_t>(e + 0x1a) != 2 || at<uint16_t>(e + 0x18) != id || at<uint8_t>(e + 0x1e) != a || !at<uintptr_t>(e)) continue;
        *tag = at<uint8_t>(e + 0x1b);
        log("quick menu: player %d's item %#x (slot %d) tagged %#x again, as its object", p + 1, id, s, *tag);
        break;
      }
    }
  }
}

// The cause, cut at the root: 0x1415da010 stops the world when the pause count is above 0 or when the pause
// controller's +0x08 (0x141e3a8c0) is 1 at that moment; during a selector session that second flag can be stale
// (the session does not pause). While a session runs only a real pause stops the world there: the check at
// 0x1415da08a (cmp byte [0x141e3a8c0], 1; jne 0x1415da0b2) goes through a stub that skips it.
constexpr uintptr_t kStopCheck = 0x15da08a, kStopCheckNext = 0x15da093, kStopSkip = 0x15da0b2, kCtrlMenuFlag = 0x1e3a8c0;
constexpr uint8_t kStopCheckBytes[9] = {0x80, 0x3d, 0x2f, 0x08, 0x86, 0x00, 0x01, 0x75, 0x1f};
bool install_stop_guard(uint8_t* stub, uint8_t* flag) {
  auto* target = reinterpret_cast<uint8_t*>(image + kStopCheck);
  if (memcmp(target, kStopCheckBytes, sizeof(kStopCheckBytes))) return false;
  uint8_t* p = stub;
  auto rel = [&](uintptr_t to, int tail) { const int32_t d = static_cast<int32_t>(static_cast<int64_t>(to) - reinterpret_cast<int64_t>(p + 4 + tail)); memcpy(p, &d, 4); p += 4; };
  auto emit = [&](std::initializer_list<uint8_t> b) { for (uint8_t x : b) *p++ = x; };
  emit({0x80, 0x3d}); rel(reinterpret_cast<uintptr_t>(flag), 1); emit({0x00});  // cmp byte [session], 0
  emit({0x0f, 0x85}); rel(image + kStopSkip, 0);                              // jne skip (no world stop)
  emit({0x80, 0x3d}); rel(image + kCtrlMenuFlag, 1); emit({0x01});             // cmp byte [0x141e3a8c0], 1
  emit({0x0f, 0x85}); rel(image + kStopSkip, 0);                              // jne skip
  emit({0xe9}); rel(image + kStopCheckNext, 0);                               // jmp: stop the world
  FlushInstructionCache(GetCurrentProcess(), stub, p - stub);
  uint8_t patch[7] = {0xe9, 0, 0, 0, 0, 0x90, 0x90};
  const int32_t d = static_cast<int32_t>(reinterpret_cast<int64_t>(stub) - static_cast<int64_t>(image + kStopCheck + 5));
  memcpy(patch + 1, &d, 4);
  write_code(target, patch, sizeof(patch));
  session_flag = flag;
  return true;
}

// Pad slot layout (0x38 bytes): u32 button masks at +0x00 (held), +0x04, +0x08 (new), +0x10/+0x14 (repeat): D-pad
// 0x1-0x8, A/B/X/Y 0x10-0x80, START 0x100, BACK 0x200, L3/R3 0x400/0x800, LB/RB 0x1000/0x2000, LT/RT 0x4000/0x8000,
// left / right stick directions 0xf0000 / 0xf00000; sticks as floats from +0x18.
constexpr uintptr_t kButtonMasks[] = {0x00, 0x04, 0x08, 0x10, 0x14};
constexpr uintptr_t kSticks = 0x18;
constexpr uint32_t kSelectorButtons = 0x3f;  // D-pad, A, B
constexpr uint32_t kFaceButtons = 0xff;      // D-pad, A, B, X, Y: kept from the character while a selector is open

struct PlayerPad {
  uint32_t prev_held = 0;
  uint32_t swallow = 0;  // buttons held when the selector closed: kept from the game until released (A = jump)
} ppad[2];
bool was_open = false;
} // namespace

// Pad update hook (update thread), after the game read the pads. `p2_slot` < 0: player 2 not in.
// Reviving a downed partner (mash B) gives back health up to the player's recoverable health (+0x5ab8, what hits
// took away is lost), so after a beating they stood up with a sliver and fell again within seconds (play test of
// 2026-10-12). A player who goes from 0 to some health gets at least half of their max (+0x5ab4) back.
uint16_t last_health[2];
void revive_boost() {
  if (!active()) { last_health[0] = last_health[1] = 0xffff; return; }
  for (int p = 0; p < 2; ++p) {
    const uintptr_t obj = actor_object(p);
    if (!obj) continue;
    auto& cur = *reinterpret_cast<volatile uint16_t*>(obj + 0x5ab6);
    auto& rec = *reinterpret_cast<volatile uint16_t*>(obj + 0x5ab8);
    const uint16_t max = *reinterpret_cast<volatile uint16_t*>(obj + 0x5ab4), half = max / 2;
    const uint16_t now = cur;
    if (last_health[p] == 0 && now > 0 && now < half && max < 60000) {
      rec = rec > half ? rec : half;
      cur = half;
      log("team missions: player %d revived with %u of %u health, raised to %u", p + 1, now, max, half);
    }
    last_health[p] = cur;
  }
}

void track_charge();  // essence orbs, below
extern volatile uint8_t guard_held[2];      // players holding guard, for the blue/red orbs (below)
constexpr uint32_t kGuardButton = 0x8000;  // RT in the pad slot's held mask

void frame(volatile uint8_t* pads, int p2_slot, uintptr_t pad_stride) {
  track_charge();
  revive_boost();
  gametext::banner_tick();
  if (const LONG p = InterlockedExchange(&refused_notice, 0); p && active())
    gametext::banner(p == 1 ? L"Jugador 1: tu compañero ya lleva esa arma, elige otra."
                            : L"Jugador 2: tu compañero ya lleva esa arma, elige otra.");
  const int slots[2] = {at<uint8_t>(kMenuPad), p2_slot};  // outside the selector fiber [0x14211e754] is player 1's
  for (int p = 0; p < 2; ++p)
    guard_held[p] = slots[p] >= 0 && slots[p] < 4 &&
                    (*reinterpret_cast<volatile uint32_t*>(pads + slots[p] * pad_stride) & kGuardButton);
  bool allowed[2];
  for (int p = 0; p < 2; ++p)
    allowed[p] = slots[p] >= 0 && slots[p] < 4 && (p == 0 || slots[1] != slots[0]) && active() &&
                 at<uint8_t>(kP1Column + p * kColumnStride) == 0 && actor_object(p);
  if (busy && sel_fiber && !allowed[sel_player] && sel_vars_held) sel_vars[1] = 4;  // left / mission over: close
  constexpr uint32_t kUp = 0x1, kB = 0x20;
  if (freeze_traced) log_freezes();
  if (busy) world_watch = 120;
  else if (world_watch > 0) {
    if (--world_watch == 0 && session_flag) *session_flag = 0;
    watch_world_stop();
    if (world_watch < 90 && !at<uint8_t>(kWorldStop)) repair_slot_tags();  // from half a second after the session
  }
  if (busy) {
    const int p = sel_player;
    if (slots[p] < 0 || slots[p] >= 4) return;
    volatile uint8_t* pd = pads + slots[p] * pad_stride;
    const uint32_t held = *reinterpret_cast<volatile uint32_t*>(pd);
    const uint32_t pressed = held & ~ppad[p].prev_held;
    ppad[p].prev_held = held;
    // B closes, as the pause controller does in the game's own flow (row 4 ends the selector loop), unless an
    // item is being applied.
    if ((pressed & kB) && sel_vars_held && sel_vars[0] != 2) sel_vars[1] = 4;
    // The selector (on its fiber) gets the D-pad, A and B only (the menus also read the sticks' direction bits as
    // a D-pad); the character keeps everything else: walking, guarding, the camera, LB/RB and the triggers.
    for (uintptr_t i = 0; i < pad_stride && i < sizeof(pad_real); ++i) pad_real[i] = pd[i];
    for (uintptr_t m : kButtonMasks) {
      *reinterpret_cast<uint32_t*>(pad_real + m) &= kSelectorButtons;
      *reinterpret_cast<volatile uint32_t*>(pd + m) &= ~kFaceButtons;
    }
    for (uintptr_t i = kSticks; i < pad_stride && i < sizeof(pad_real); ++i) pad_real[i] = 0;
    was_open = true;
    return;
  }
  if (was_open) {
    was_open = false;
    const int p = sel_player;
    if (slots[p] >= 0 && slots[p] < 4) ppad[p].swallow = *reinterpret_cast<volatile uint32_t*>(pads + slots[p] * pad_stride) & kFaceButtons;
  }
  for (int p = 0; p < 2; ++p) {
    if (slots[p] < 0 || slots[p] >= 4) { ppad[p].swallow = 0; continue; }
    volatile uint8_t* pd = pads + slots[p] * pad_stride;
    const uint32_t held = *reinterpret_cast<volatile uint32_t*>(pd);
    const uint32_t pressed = held & ~ppad[p].prev_held;
    ppad[p].prev_held = held;
    if (allowed[p] && (pressed & kUp) && !busy) {
      for (uintptr_t i = 0; i < pad_stride && i < sizeof(pad_real); ++i) pad_real[i] = pd[i];
      if (start_selector(static_cast<uint8_t>(p), static_cast<uint8_t>(slots[p]))) log("quick menu: player %d opens the selector", p + 1);
    }
    ppad[p].swallow &= held & kFaceButtons;
    if (ppad[p].swallow)
      for (uintptr_t m : kButtonMasks) *reinterpret_cast<volatile uint32_t*>(pd + m) &= ~ppad[p].swallow;
  }
}

// The resource loader thread runs load jobs (vtable 0x1418ef730, run 0x140b9d2a0: +0x10 destination, +0x18 resource
// id) through 0x1413ad110(loader, id, destination), which reads the compressed data and inflates it at the
// destination. Twice in the play test of 2026-10-12 a job came with destination ~0 (no room found), after player 1
// went 0x21 -> 0xc: zlib wrote at 0xffffffffffffffff (exe+0xe4db31) and the game closed. Such a job is skipped and
// logged with the last jobs before it, to find who asks for it.
constexpr uintptr_t kJobLoadCall = 0xb9d2d5, kJobLoad = 0x13ad110;
using JobLoadFn = void (*)(uintptr_t, uint32_t, uintptr_t);
struct JobRecord { uint32_t id; uintptr_t dest; DWORD tick; };
JobRecord recent_jobs[16];
volatile LONG job_count = 0;
bool trace_jobs = false;
void job_load_hook(uintptr_t loader, uint32_t id, uintptr_t dest) {
  const LONG n = InterlockedIncrement(&job_count);
  recent_jobs[n & 15] = {id, dest, GetTickCount()};
  if (trace_jobs && active()) log("quick menu: load job res %#x at %#llx", id, static_cast<unsigned long long>(dest));
  if (dest + 1 <= 1) {
    log("quick menu: load job for res %#x has no destination (%#llx): skipped instead of crashing; last jobs:", id,
        static_cast<unsigned long long>(dest));
    for (LONG k = n - 15; k < n; ++k)
      if (k > 0) {
        const JobRecord& r = recent_jobs[k & 15];
        log("quick menu:   res %#x at %#llx (%lu ms before)", r.id, static_cast<unsigned long long>(r.dest), GetTickCount() - r.tick);
      }
    return;
  }
  reinterpret_cast<JobLoadFn>(image + kJobLoad)(loader, id, dest);
}

// Team Missions start with the five ninpo full (Santi's request). The mission load 0x1415dd080 copies the mission's
// ninpo into a template player (0x146ae8880: +0x5ad8 max, +0x5ada current, 200 per icon) and 0x1415d9560 (called at
// 0x1415dd7db once per player) puts it in the player's object. The HUD builds the icons' gold bases from the max
// right after the load (0x140cd0860), so it has to be 1000 before that call, not later.
constexpr uintptr_t kNinpoSetupCall = 0x15dd7db, kNinpoSetup = 0x15d9560;
using NinpoSetupFn = void (*)(uint32_t, uintptr_t, uintptr_t, uintptr_t);
void ninpo_setup_hook(uint32_t player, uintptr_t a, uintptr_t tmpl, uintptr_t b) {
  if (at<uint8_t>(kTeamMode) == 1 && tmpl) {
    *reinterpret_cast<volatile uint16_t*>(tmpl + 0x5ad8) = 1000;
    *reinterpret_cast<volatile uint16_t*>(tmpl + 0x5ada) = 1000;
  }
  reinterpret_cast<NinpoSetupFn>(image + kNinpoSetup)(player, a, tmpl, b);
}

// Essence orbs (pool 0x1465cae90, 64 x 0x110: +0x0c state, +0x50 position, +0xe4 player they fly to) went to the
// wrong player with two (docs/CIERRE_COOP.md D4):
//  - Absorbing (0x141490d00, a move with property 5) took every orb on the floor, wherever it was; the distances
//    were only compared when both players absorbed at once. The pick at 0x141491064 (test esi,esi; js assign;
//    movups xmm6,[r10+0x50]) goes through a stub: the absorbing player (r11d) takes the orb (r10) unless another
//    player still in the fight is nearer; that one keeps it on the floor, to absorb it or get it at the wave's end.
//  - At a wave's end (0x141491b90) the orb went to the farther player: seta at 0x141491d37 (P2 when its distance
//    is above P1's; the orb update 0x141493076 compares the other way round). It becomes setb.
constexpr uintptr_t kAbsorbPick = 0x1491064, kAbsorbTake = 0x14910e0, kAbsorbNext = 0x1491197;
constexpr uint8_t kAbsorbPickBytes[9] = {0x85, 0xf6, 0x78, 0x78, 0x41, 0x0f, 0x10, 0x72, 0x50};
constexpr uintptr_t kWaveEndPick = 0x1491d37;
constexpr uint8_t kWaveEndPickBytes[3] = {0x0f, 0x97, 0xc0}, kWaveEndPickFix[3] = {0x0f, 0x92, 0xc0};
// Blue (health) and red (ki) orbs fly to a player within 10 units that needs them, the nearer one when both do
// (0x141492d00). In Team Missions the check at 0x141492edc (movzx eax, [0x14211e757]; cmp edi, eax; jne skip) left
// only player 1, so player 2 never got them. It goes through a
// stub instead: a player holding guard (RT) picks up nothing, and while the nearer player guards the orb waits
// (Santi's request); then the game's own type check (blue/red only) and distances.
constexpr uintptr_t kPickupOwner = 0x1492edc, kPickupNext = 0x1492eeb, kPickupSkip = 0x149302a;
constexpr uint8_t kPickupOwnerBytes[15] = {0x0f, 0xb6, 0x05, 0x74, 0xb8, 0xc8, 0x00, 0x3b, 0xf8, 0x0f, 0x85, 0x3f, 0x01, 0x00, 0x00};
volatile uint8_t guard_held[2];
constexpr uintptr_t kPlayerPos = 0x1494310, kPlayerOut = 0x14943e0, kPlayerCount = 0x211e5cc;
using PlayerPosFn = const float* (*)(float*, uint32_t);  // copies the player's position to the buffer
using PlayerOutFn = bool (*)(uint32_t);                  // true: down or out of the fight (no orbs)
bool trace_orbs = false;

// The charged attack (hold Y) has two levels: blue ~0.9 s after its absorbing move starts, red when the move
// changes (Ryu with the Dragon Sword: 0x44d, then 0x450 absorbing, 0x452 at red ~1.65 s later). Each essence orb
// absorbed raises it one level at once, so absorbing takes at most what the attack still needs (Santi's request):
// 2 orbs from the start, 1 at blue, none at red. The level itself was not found in memory; it is followed here
// from the move: 0x140f8de90(entry) = the current move absorbs (property 5), 0x141005d60(entry) = current move.
constexpr uintptr_t kMoveAbsorbs = 0xf8de90, kCurrentMove = 0x1005d60;
constexpr DWORD kChargeBlueMs = 900, kChargeRedMs = 1700;
using EntryFn = uint32_t (*)(uintptr_t);
struct Charge { bool on, red; DWORD start; uint16_t move; int taken; };
Charge charge[2];
uintptr_t player_entry(uint32_t p) { return image + kObjects + at<uint8_t>(kPlayerActor + p) * 0x30; }
void test_orb_drops();
void track_charge() {
  test_orb_drops();
  if (at<uint8_t>(kTeamMode) != 1 || at<uint8_t>(0x21544fa) != 74) { charge[0] = charge[1] = {}; return; }
  for (uint32_t p = 0; p < 2 && p < at<uint8_t>(kPlayerCount); ++p) {
    const uintptr_t e = player_entry(p);
    Charge& c = charge[p];
    if (!at<uintptr_t>(e - image) || !reinterpret_cast<EntryFn>(image + kMoveAbsorbs)(e)) { c = {}; continue; }
    const uint16_t move = static_cast<uint16_t>(reinterpret_cast<EntryFn>(image + kCurrentMove)(e));
    if (!c.on) c = {true, false, GetTickCount(), move, 0};
    else if (move != c.move) c.red = true;
  }
}
int charge_level(uint32_t p) {
  const Charge& c = charge[p];
  if (!c.on) return 0;
  const DWORD t = GetTickCount() - c.start;
  const int natural = c.red || t >= kChargeRedMs ? 2 : t >= kChargeBlueMs ? 1 : 0;
  return natural + c.taken < 2 ? natural + c.taken : 2;
}

// Tests only (diagnostics on): plugin/ngs2coop-orbs.txt = "type count amount player dx dz" drops orbs (type 0 blue,
// 1 red, 2 essence) next to that player through the game's drop 0x141490110(pool, 0, &pos, amount, type, 1, 0),
// then the file is deleted.
constexpr uintptr_t kOrbPool = 0x65cae90, kOrbDrop = 0x1490110;
using OrbDropFn = void (*)(uintptr_t, uintptr_t, const float*, uint32_t, uint32_t, uint32_t, uint8_t);
void test_orb_drops() {
  static int wait = 0;
  if (!trace_orbs || ++wait < 20) return;
  wait = 0;
  if (FILE* b = fopen("plugin\\ngs2coop-banner.txt", "r")) {  // banner test: the file's first line
    char line[160] = {};
    fgets(line, sizeof(line), b);
    fclose(b);
    DeleteFileA("plugin\\ngs2coop-banner.txt");
    wchar_t w[160];
    MultiByteToWideChar(CP_UTF8, 0, line, -1, w, 160);
    for (wchar_t* c = w; *c; ++c) if (*c == L'\n' || *c == L'\r') *c = 0;
    if (at<uint8_t>(0x21544fa) == 74) gametext::banner(w);
  }
  FILE* f = fopen("plugin\\ngs2coop-orbs.txt", "r");
  if (!f) return;
  unsigned type = 2, count = 1, amount = 50, player = 0;
  float dx = 0, dz = 0;
  const int n = fscanf(f, "%u %u %u %u %f %f", &type, &count, &amount, &player, &dx, &dz);
  fclose(f);
  DeleteFileA("plugin\\ngs2coop-orbs.txt");
  if (n < 1 || type > 2 || player > 1 || at<uint8_t>(kTeamMode) != 1 || at<uint8_t>(0x21544fa) != 74) return;
  for (unsigned k = 0; k < count && k < 8; ++k) {
    alignas(16) float pos[4];
    reinterpret_cast<PlayerPosFn>(image + kPlayerPos)(pos, player);
    pos[0] += dx + 0.6f * k; pos[2] += dz; pos[1] += 0.5f;
    reinterpret_cast<OrbDropFn>(image + kOrbDrop)(image + kOrbPool, 0, pos, amount, type, 1, 0);
  }
  log("essence: test drop of %u orbs of type %u (%u each) next to player %u", count, type, amount, player + 1);
}

float orb_distance(uintptr_t orb, uint32_t p) {
  alignas(16) float buf[4];
  const float* v = reinterpret_cast<PlayerPosFn>(image + kPlayerPos)(buf, p);
  const auto* o = reinterpret_cast<const volatile float*>(orb + 0x50);
  const float dx = v[0] - o[0], dy = v[1] - o[1], dz = v[2] - o[2];
  return dx * dx + dy * dy + dz * dz;
}
bool pickup_blocked(uint32_t player, uintptr_t orb) {
  if (player >= 2) return false;
  if (guard_held[player]) return true;
  const uint32_t other = 1 - player;
  if (other >= at<uint8_t>(kPlayerCount) || !guard_held[other] || reinterpret_cast<PlayerOutFn>(image + kPlayerOut)(other))
    return false;
  const float theirs = orb_distance(orb, other);
  return theirs < 100.f && theirs < orb_distance(orb, player);
}

// Absorber 2 of the scan is "any character in an absorbing move" (the first one found, [pool+0x8850] = its entry):
// with a player absorbing it is that same player, so it gets the same rules.
bool absorb_takes(uintptr_t orb, uint32_t player) {
  const uint8_t n = at<uint8_t>(kPlayerCount);
  if (at<uint8_t>(kTeamMode) != 1) return true;
  if (player == 2) {
    const uintptr_t e = at<uintptr_t>(kOrbPool + 0x8850);
    for (uint32_t p = 0; p < 2 && p < n; ++p)
      if (e && e == player_entry(p)) player = p;
    if (player == 2) return true;
  }
  if (player >= n || player >= 2) return true;
  Charge& c = charge[player];
  if (!c.on) {  // the scan can run before this frame's track_charge saw the move
    const uintptr_t e = player_entry(player);
    c = {true, false, GetTickCount(), static_cast<uint16_t>(reinterpret_cast<EntryFn>(image + kCurrentMove)(e)), 0};
  }
  if (charge_level(player) >= 2) {
    if (trace_orbs) log("essence: player %u absorbs orb %#llx: the attack is fully charged -> left", player + 1, static_cast<unsigned long long>(orb));
    return false;
  }
  if (n < 2) { ++charge[player].taken; return true; }
  const auto* o = reinterpret_cast<const volatile float*>(orb + 0x50);
  auto dist = [&](uint32_t p) {
    alignas(16) float buf[4];
    const float* v = reinterpret_cast<PlayerPosFn>(image + kPlayerPos)(buf, p);
    const float dx = v[0] - o[0], dy = v[1] - o[1], dz = v[2] - o[2];
    return dx * dx + dy * dy + dz * dz;
  };
  const float mine = dist(player);
  bool take = true;
  for (uint32_t p = 0; p < n; ++p) {
    const bool out = reinterpret_cast<PlayerOutFn>(image + kPlayerOut)(p);
    if (p != player && !out && dist(p) < mine) take = false;
    if (trace_orbs && p != player)
      log("essence: player %u absorbs orb %#llx: own distance %.1f, player %u %.1f%s -> %s", player + 1,
          static_cast<unsigned long long>(orb), std::sqrt(mine), p + 1, std::sqrt(dist(p)), out ? " (out)" : "",
          take ? "taken" : "left");
  }
  if (take) ++charge[player].taken;
  return take;
}
bool install_essence_fix(uint8_t* stub) {
  auto* pick = reinterpret_cast<uint8_t*>(image + kAbsorbPick);
  auto* wave = reinterpret_cast<uint8_t*>(image + kWaveEndPick);
  if (memcmp(pick, kAbsorbPickBytes, sizeof(kAbsorbPickBytes)) || memcmp(wave, kWaveEndPickBytes, 3)) return false;
  uint8_t* p = stub;
  auto rel = [&](uintptr_t to) { const int32_t d = static_cast<int32_t>(static_cast<int64_t>(to) - reinterpret_cast<int64_t>(p + 4)); memcpy(p, &d, 4); p += 4; };
  auto emit = [&](std::initializer_list<uint8_t> b) { for (uint8_t x : b) *p++ = x; };
  emit({0x50, 0x51, 0x52, 0x41, 0x50, 0x41, 0x51, 0x41, 0x52, 0x41, 0x53});  // push rax, rcx, rdx, r8-r11
  emit({0x48, 0x83, 0xec, 0x28});                                            // sub rsp, 0x28
  emit({0x4c, 0x89, 0xd1});                                                  // mov rcx, r10 (orb)
  emit({0x44, 0x89, 0xda});                                                  // mov edx, r11d (player)
  emit({0x48, 0xb8});                                                        // mov rax, absorb_takes
  const uint64_t fn = reinterpret_cast<uint64_t>(&absorb_takes);
  memcpy(p, &fn, 8); p += 8;
  emit({0xff, 0xd0});                                                        // call rax
  emit({0x48, 0x83, 0xc4, 0x28});                                            // add rsp, 0x28
  emit({0x84, 0xc0});                                                        // test al, al
  emit({0x41, 0x5b, 0x41, 0x5a, 0x41, 0x59, 0x41, 0x58, 0x5a, 0x59, 0x58});  // pop r11-r8, rdx, rcx, rax
  emit({0x0f, 0x85}); rel(image + kAbsorbTake);                              // jne: the orb flies to the player
  emit({0xe9}); rel(image + kAbsorbNext);                                    // jmp: next orb
  FlushInstructionCache(GetCurrentProcess(), stub, p - stub);
  uint8_t patch[9] = {0xe9, 0, 0, 0, 0, 0x90, 0x90, 0x90, 0x90};
  const int32_t d = static_cast<int32_t>(reinterpret_cast<int64_t>(stub) - static_cast<int64_t>(image + kAbsorbPick + 5));
  memcpy(patch + 1, &d, 4);
  write_code(pick, patch, sizeof(patch));
  write_code(wave, kWaveEndPickFix, sizeof(kWaveEndPickFix));
  auto* owner = reinterpret_cast<uint8_t*>(image + kPickupOwner);
  if (memcmp(owner, kPickupOwnerBytes, sizeof(kPickupOwnerBytes))) {
    log("team missions: unexpected bytes at the blue/red orb pickup, only player 1 picks them up");
    return true;
  }
  uint8_t* const q = p;  // second stub, right after the first
  emit({0x50, 0x51, 0x52, 0x41, 0x50, 0x41, 0x51, 0x41, 0x52, 0x41, 0x53});  // push rax, rcx, rdx, r8-r11
  emit({0x48, 0x83, 0xec, 0x38});                                            // sub rsp, 0x38
  emit({0xf3, 0x0f, 0x7f, 0x5c, 0x24, 0x20});                                // movdqu [rsp+0x20], xmm3 (radius)
  emit({0x89, 0xf9});                                                        // mov ecx, edi (player)
  emit({0x48, 0x89, 0xda});                                                  // mov rdx, rbx (orb)
  emit({0x48, 0xb8});                                                        // mov rax, pickup_blocked
  const uint64_t blocked = reinterpret_cast<uint64_t>(&pickup_blocked);
  memcpy(p, &blocked, 8); p += 8;
  emit({0xff, 0xd0});                                                        // call rax
  emit({0xf3, 0x0f, 0x6f, 0x5c, 0x24, 0x20});                                // movdqu xmm3, [rsp+0x20]
  emit({0x48, 0x83, 0xc4, 0x38});                                            // add rsp, 0x38
  emit({0x84, 0xc0});                                                        // test al, al
  emit({0x41, 0x5b, 0x41, 0x5a, 0x41, 0x59, 0x41, 0x58, 0x5a, 0x59, 0x58});  // pop r11-r8, rdx, rcx, rax
  emit({0x0f, 0x85}); rel(image + kPickupSkip);                              // jne: not this player
  emit({0xe9}); rel(image + kPickupNext);                                    // jmp: the type check
  FlushInstructionCache(GetCurrentProcess(), q, p - q);
  uint8_t jump[15] = {0xe9, 0, 0, 0, 0, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90, 0x90};
  const int32_t dj = static_cast<int32_t>(reinterpret_cast<int64_t>(q) - static_cast<int64_t>(image + kPickupOwner + 5));
  memcpy(jump + 1, &dj, 4);
  write_code(owner, jump, sizeof(jump));
  return true;
}

bool init(uintptr_t base, void (*log_fn)(const char*, ...)) {
  log = log_fn;
  image = base;
  uint8_t* mem = alloc_near();
  if (!mem) {
    log("quick menu: no memory near the image, not enabled");
    return false;
  }
  if (!install_give(mem + 0x100)) return false;
  // Diagnostics, off unless plugin/ngs2coop-trace-loads.txt exists: releases of items a player still has equipped
  // (normal at a mission's end) and the load requests.
  const bool trace = GetFileAttributesA("plugin\\ngs2coop-trace-loads.txt") != INVALID_FILE_ATTRIBUTES;
  if (trace) install_release_logs(mem + 0x200);
  if (install_shared_pack_fix(mem + 0x400)) log("quick menu: a change away from an item the other player shares keeps it loaded");
  if (patch_call(kFinalizeSweepCall, kSweep, mem + 0x440, reinterpret_cast<uint64_t>(&sweep_hook)) &&
      patch_call(kFinalizeLoadCall, kLoad, mem + 0x460, reinterpret_cast<uint64_t>(&load_hook)) &&
      install_slot_store_fix(mem + 0x480) &&
      patch_call(kSlotResReadCall, kSlotResRead, mem + 0x4c0, reinterpret_cast<uint64_t>(&slot_res_hook)) &&
      patch_call(kFinalizeRequestCall, kRequestLinked, mem + 0x4e0, reinterpret_cast<uint64_t>(&finalize_request)) &&
      patch_call(kFinalizeProcessCall, kProcessBatch, mem + 0x500, reinterpret_cast<uint64_t>(&finalize_process)) &&
      install_window()) {
    log("quick menu: D-pad up opens the game's selector on the player's own view, without pausing (Team Missions)");
  } else {
    log("quick menu: unexpected bytes at the change finishing step, selector off");
    return false;
  }
  if (trace && install_request_trace(mem + 0x680)) log("quick menu: load request trace on (diagnostics)");
  if (trace && install_freeze_trace(mem + 0x800)) {
    freeze_traced = true;
    log("quick menu: world stop trace on (diagnostics)%s", install_suspend_trace(mem + 0x880) ? ", task group stops too" : "");
  }
  if (install_stop_guard(mem + 0x600, mem + 0x7f0)) log("quick menu: equipment changes in a selector session never stop the world");
  else log("quick menu: unexpected bytes at the world-stop check, not guarded");
  if (calls_to(kLoadStopCall, kWorldFreeze) && calls_to(kLoadResumeCall, kWorldResume) &&
      patch_call(kLoadStopCall, kWorldFreeze, mem + 0x900, reinterpret_cast<uint64_t>(&load_stop_hook)) &&
      patch_call(kLoadResumeCall, kWorldResume, mem + 0x920, reinterpret_cast<uint64_t>(&load_resume_hook)))
    log("quick menu: an object waiting for its load does not stop the world in a session");
  else log("quick menu: unexpected bytes at the object load wait, not guarded");
  trace_jobs = trace;
  if (patch_call(kJobLoadCall, kJobLoad, mem + 0x940, reinterpret_cast<uint64_t>(&job_load_hook)))
    log("quick menu: a load job without a destination is skipped and logged");
  else log("quick menu: unexpected bytes at the load job, not guarded");
  if (patch_call(kNinpoSetupCall, kNinpoSetup, mem + 0x960, reinterpret_cast<uint64_t>(&ninpo_setup_hook)))
    log("team missions: both players start with five full ninpo");
  else log("team missions: unexpected bytes at the ninpo setup, ninpo as the mission sets them");
  trace_orbs = trace;
  if (install_essence_fix(mem + 0x980)) log("team missions: essence, blue and red orbs go to the nearer player");
  else log("team missions: unexpected bytes at the essence orbs, orbs as the game gives them");
  return true;
}
} // namespace quickmenu
