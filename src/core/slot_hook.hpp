#pragma once

#include <atomic>
#include <cstdint>

namespace nm {

// Ops supplies read-only load, page protection, pointer CAS and module pinning.
// No destructor unhooks: callbacks may already have been fetched by another thread.
// The callback module and original pointer must remain valid until process exit.
template<class Function, class Ops>
class SlotHook {
public:
  enum class Result {
    installed, restored, inactive, busy, already_attempted, mismatch,
    unreadable, invalid, pin_failed, protect_failed, protection_restore_failed,
    changed_by_other
  };

  Result install(uintptr_t slot, Function expected, Function replacement) noexcept {
    Guard guard{lock_};
    if (!guard.acquired) return Result::busy;
    if (attempted_) return Result::already_attempted;
    attempted_ = true;
    if (!slot || slot % alignof(uintptr_t) || !expected || !replacement || expected == replacement)
      return Result::invalid;
    uintptr_t value;
    if (!Ops::load(slot, value)) return Result::unreadable;
    const auto expected_bits = reinterpret_cast<uintptr_t>(expected);
    if (value != expected_bits) return Result::mismatch; // No protection/write/pin yet.
    if (!Ops::pin(replacement)) return Result::pin_failed;

    slot_ = slot;
    replacement_ = reinterpret_cast<uintptr_t>(replacement);
    original_.store(expected, std::memory_order_release); // Before publishing callback.
    if (!Ops::writable(slot_, protection_)) return Result::protect_failed;
    protection_pending_ = true;
    const auto previous = Ops::exchange_if(slot_, expected_bits, replacement_);
    installed_ = previous == expected_bits;
    if (!Ops::protect(slot_, protection_)) {
      // Still writable: roll back only our own pointer. Never overwrite a third party.
      if (installed_)
        Ops::exchange_if(slot_, replacement_, expected_bits);
      installed_ = false;
      protection_pending_ = !Ops::protect(slot_, protection_);
      return Result::protection_restore_failed;
    }
    protection_pending_ = false;
    return installed_ ? Result::installed : Result::changed_by_other;
  }

  Result restore() noexcept {
    Guard guard{lock_};
    if (!guard.acquired) return Result::busy;
    // Retry a failed protection restore without guessing the original protection.
    if (protection_pending_) {
      if (!Ops::protect(slot_, protection_)) return Result::protection_restore_failed;
      protection_pending_ = false;
    }
    if (!installed_) return Result::inactive;
    uintptr_t current;
    if (!Ops::load(slot_, current)) return Result::unreadable;
    if (current != replacement_) {
      installed_ = false;
      return Result::changed_by_other; // Not even a VirtualProtect on this path.
    }
    if (!Ops::writable(slot_, protection_)) return Result::protect_failed;
    protection_pending_ = true;
    const auto previous = Ops::exchange_if(slot_, replacement_,
                         reinterpret_cast<uintptr_t>(original_.load(std::memory_order_acquire)));
    installed_ = false;
    if (!Ops::protect(slot_, protection_)) return Result::protection_restore_failed;
    protection_pending_ = false;
    return previous == replacement_ ? Result::restored : Result::changed_by_other;
  }

  // Safe even for an in-flight callback after restore. Never cleared on restore.
  Function original() const noexcept { return original_.load(std::memory_order_acquire); }

private:
  struct Guard {
    std::atomic_flag& flag;
    bool acquired;
    explicit Guard(std::atomic_flag& f) : flag(f), acquired(!f.test_and_set(std::memory_order_acquire)) {}
    ~Guard() { if (acquired) flag.clear(std::memory_order_release); }
  };
  std::atomic_flag lock_ = ATOMIC_FLAG_INIT;
  std::atomic<Function> original_{nullptr};
  uintptr_t slot_{};
  uintptr_t replacement_{};
  typename Ops::Protection protection_{};
  bool attempted_{};
  bool installed_{};
  bool protection_pending_{};
};

} // namespace nm
