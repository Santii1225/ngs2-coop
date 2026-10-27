#pragma once

#include "slot_hook.hpp"
#include <windows.h>
#include <limits>

namespace nm {
static_assert(sizeof(uintptr_t) == 8, "Sigma2 requires Windows x64");
inline constexpr uintptr_t sigma2_function_rva = 0x1462a00;
inline constexpr uintptr_t sigma2_slot_rva = 0x18f9518;

struct WindowsSlotOps {
  using Protection = DWORD;
  static bool load(uintptr_t slot, uintptr_t& value) noexcept {
    SIZE_T read = 0;
    return ReadProcessMemory(GetCurrentProcess(), reinterpret_cast<void*>(slot),
                             &value, sizeof(value), &read) && read == sizeof(value);
  }
  template<class F> static bool pin(F callback) noexcept {
    HMODULE module;
    // Prevent FreeLibrary/unload races, including callbacks fetched before restore.
    return GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                             GET_MODULE_HANDLE_EX_FLAG_PIN,
                             reinterpret_cast<LPCSTR>(callback), &module) != FALSE;
  }
  static bool writable(uintptr_t slot, Protection& old) noexcept {
    return VirtualProtect(reinterpret_cast<void*>(slot), sizeof(uintptr_t),
                          PAGE_READWRITE, &old) != FALSE;
  }
  static bool protect(uintptr_t slot, Protection old) noexcept {
    DWORD ignored;
    return VirtualProtect(reinterpret_cast<void*>(slot), sizeof(uintptr_t), old, &ignored) != FALSE;
  }
  static uintptr_t exchange_if(uintptr_t slot, uintptr_t expected, uintptr_t desired) noexcept {
    return reinterpret_cast<uintptr_t>(InterlockedCompareExchangePointer(
      reinterpret_cast<void* volatile*>(slot), reinterpret_cast<void*>(desired),
      reinterpret_cast<void*>(expected)));
  }
};

// Structural build guard, NOT a cryptographic identity check. All reads are checked.
inline bool sigma2_image_matches(uintptr_t base) noexcept {
  if (!base || base > std::numeric_limits<uintptr_t>::max() - 0x72ce000) return false;
  IMAGE_DOS_HEADER dos{};
  IMAGE_NT_HEADERS64 nt{};
  SIZE_T read = 0;
  if (!ReadProcessMemory(GetCurrentProcess(), reinterpret_cast<void*>(base), &dos,
                         sizeof(dos), &read) || read != sizeof(dos) ||
      dos.e_magic != IMAGE_DOS_SIGNATURE || dos.e_lfanew < 0 || dos.e_lfanew > 0x100000)
    return false;
  if (!ReadProcessMemory(GetCurrentProcess(), reinterpret_cast<void*>(base + dos.e_lfanew),
                         &nt, sizeof(nt), &read) || read != sizeof(nt)) return false;
  return nt.Signature == IMAGE_NT_SIGNATURE &&
         nt.FileHeader.Machine == IMAGE_FILE_MACHINE_AMD64 &&
         nt.FileHeader.TimeDateStamp == 1625735769 &&
         nt.FileHeader.SizeOfOptionalHeader >= sizeof(IMAGE_OPTIONAL_HEADER64) &&
         nt.OptionalHeader.Magic == IMAGE_NT_OPTIONAL_HDR64_MAGIC &&
         nt.OptionalHeader.SizeOfCode == 0x179c400 &&
         nt.OptionalHeader.SizeOfImage == 0x72ce000;
}
} // namespace nm
