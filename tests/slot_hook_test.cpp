#include "core/slot_hook.hpp"
#include <cassert>
#include <iostream>
#include <type_traits>

struct Sigma2 { bool result; int calls = 0; };
using F = bool (*)(Sigma2*);
bool original(Sigma2* self) { ++self->calls; return self->result; }
bool callback(Sigma2*) { return false; }
bool other(Sigma2*) { return true; }

struct FakeOps {
  using Protection = unsigned;
  static inline uintptr_t value;
  static inline unsigned protection, writes, protects, pins, restores;
  static inline bool readable, pin_ok, writable_ok, race_on_write, race_on_cas;
  static inline unsigned fail_restore_count;
  static inline void (*during_write)();
  static void reset() {
    value = reinterpret_cast<uintptr_t>(original);
    protection = 2; writes = protects = pins = restores = 0;
    readable = pin_ok = writable_ok = true;
    race_on_write = race_on_cas = false; fail_restore_count = 0;
    during_write = nullptr;
  }
  static bool load(uintptr_t, uintptr_t& out) { out=value; return readable; }
  static bool pin(F) { ++pins; return pin_ok; }
  static bool writable(uintptr_t, Protection& old) {
    ++protects;
    if (!writable_ok) return false;
    old=protection; protection=4;
    if (race_on_write) value=reinterpret_cast<uintptr_t>(other);
    if (during_write) during_write();
    return true;
  }
  static bool protect(uintptr_t, Protection old) {
    ++restores;
    if (fail_restore_count) { --fail_restore_count; return false; }
    protection=old; return true;
  }
  static uintptr_t exchange_if(uintptr_t, uintptr_t expected, uintptr_t desired) {
    assert(protection==4);
    if (race_on_cas) { value=reinterpret_cast<uintptr_t>(other); race_on_cas=false; }
    auto previous=value;
    if (value==expected) { value=desired; ++writes; }
    return previous;
  }
};
using Hook = nm::SlotHook<F, FakeOps>;
using R = Hook::Result;
static_assert(std::is_same_v<decltype(Hook{}.original()), F>);
constexpr uintptr_t slot = 0x1000; // Fake slot token, never dereferenced.
Hook* active;
bool forward(Sigma2* self) { return active->original()(self); }
void reenter() {
  assert(active->install(slot,original,callback)==R::busy);
  assert(active->restore()==R::busy);
}
int main() {
  {
    FakeOps::reset(); Hook h; active=&h;
    assert(h.install(slot,original,forward)==R::installed);
    assert(h.original()==original && FakeOps::protection==2);
    Sigma2 a{true}, b{false};
    const auto installed=reinterpret_cast<F>(FakeOps::value);
    assert(installed(&a)); assert(!installed(&b)); assert(a.calls==1 && b.calls==1);
    assert(h.install(slot,original,forward)==R::already_attempted);
    assert(FakeOps::writes==1);
    assert(h.restore()==R::restored && FakeOps::protection==2);
    assert(FakeOps::value==reinterpret_cast<uintptr_t>(original));
    assert(installed(&a)); // Already-fetched callback remains valid after restore.
    assert(h.restore()==R::inactive);
  }
  {
    FakeOps::reset(); Hook h; FakeOps::value=reinterpret_cast<uintptr_t>(other);
    assert(h.install(slot,original,callback)==R::mismatch);
    assert(!FakeOps::writes && !FakeOps::protects && !FakeOps::pins);
  }
  {
    FakeOps::reset(); Hook h; FakeOps::readable=false;
    assert(h.install(slot,original,callback)==R::unreadable);
    assert(!FakeOps::protects && !FakeOps::writes);
  }
  {
    FakeOps::reset(); Hook h;
    assert(h.install(slot+1,original,callback)==R::invalid);
    assert(!FakeOps::protects);
  }
  {
    FakeOps::reset(); Hook h; FakeOps::pin_ok=false;
    assert(h.install(slot,original,callback)==R::pin_failed);
    assert(!FakeOps::protects && !FakeOps::writes);
  }
  {
    FakeOps::reset(); Hook h; FakeOps::writable_ok=false;
    assert(h.install(slot,original,callback)==R::protect_failed);
    assert(!FakeOps::writes && FakeOps::protection==2);
  }
  {
    FakeOps::reset(); Hook h; FakeOps::race_on_write=true;
    assert(h.install(slot,original,callback)==R::changed_by_other);
    assert(!FakeOps::writes && FakeOps::protection==2);
    assert(FakeOps::value==reinterpret_cast<uintptr_t>(other));
  }
  {
    FakeOps::reset(); Hook h; assert(h.install(slot,original,callback)==R::installed);
    FakeOps::value=reinterpret_cast<uintptr_t>(other); unsigned n=FakeOps::protects;
    assert(h.restore()==R::changed_by_other);
    assert(FakeOps::protects==n && FakeOps::value==reinterpret_cast<uintptr_t>(other));
  }
  {
    FakeOps::reset(); Hook h; assert(h.install(slot,original,callback)==R::installed);
    FakeOps::race_on_cas=true;
    assert(h.restore()==R::changed_by_other);
    assert(FakeOps::value==reinterpret_cast<uintptr_t>(other) && FakeOps::protection==2);
  }
  {
    FakeOps::reset(); Hook h; FakeOps::fail_restore_count=1;
    assert(h.install(slot,original,callback)==R::protection_restore_failed);
    assert(FakeOps::value==reinterpret_cast<uintptr_t>(original));
    assert(FakeOps::protection==2 && FakeOps::writes==2);
  }
  {
    FakeOps::reset(); Hook h; FakeOps::fail_restore_count=2;
    assert(h.install(slot,original,callback)==R::protection_restore_failed);
    assert(FakeOps::value==reinterpret_cast<uintptr_t>(original) && FakeOps::protection==4);
    assert(h.restore()==R::inactive && FakeOps::protection==2); // Retry protection only.
  }
  {
    FakeOps::reset(); Hook h; assert(h.install(slot,original,callback)==R::installed);
    FakeOps::fail_restore_count=1;
    assert(h.restore()==R::protection_restore_failed);
    assert(h.original()==original);
    assert(h.restore()==R::inactive && FakeOps::protection==2);
  }
  {
    FakeOps::reset(); Hook h; active=&h; FakeOps::during_write=reenter;
    assert(h.install(slot,original,callback)==R::installed);
    FakeOps::during_write=nullptr;
    assert(h.restore()==R::restored);
  }
  std::cout << "PASS: 13 scenarios (bool forwarding, guards, duplicate/reentry, CAS races, protection failures, restore)\n";
}
