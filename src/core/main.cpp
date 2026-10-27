/*
 * NINJA GAIDEN Master Collection NM Plugin by Nozomi Miyamori
 * is marked with CC0 1.0. This file is a part of NINJA GAIDEN
 * Master Collection NM Plugin.
 */
#define WIN32_LEAN_AND_MEAN
#include "sigma2_hook.hpp"
#include <strsafe.h>

namespace {
using namespace nm;
struct Sigma2;
bool Sigma2_vfunction1(Sigma2*);
using Sigma2Hook = SlotHook<bool (*)(Sigma2*), WindowsSlotOps>;
constinit Sigma2Hook sigma2_hook;
constinit std::atomic_flag initialization_started = ATOMIC_FLAG_INIT;
constinit std::atomic_flag invocation_logged = ATOMIC_FLAG_INIT;
// Published before the slot CAS; never closed while callbacks can run.
constinit std::atomic<HANDLE> log_file{nullptr};
SRWLOCK log_lock = SRWLOCK_INIT;

void log_message(const char* message) noexcept {
  const DWORD saved_error = GetLastError();
  AcquireSRWLockExclusive(&log_lock);
  const HANDLE file = log_file.load(std::memory_order_acquire);
  if (file) {
    DWORD written;
    if (!WriteFile(file, message, static_cast<DWORD>(lstrlenA(message)), &written, nullptr))
      OutputDebugStringA("NGS2Coop: log write failed\n");
  }
  ReleaseSRWLockExclusive(&log_lock);
  OutputDebugStringA(message);
  SetLastError(saved_error);
}

bool open_log(HMODULE module) noexcept {
  WCHAR path[MAX_PATH];
  const DWORD length = GetModuleFileNameW(module, path, MAX_PATH);
  if (!length || length >= MAX_PATH) return false;
  DWORD name = length;
  while (name && path[name - 1] != L'\\') --name;
  if (!name) return false;
  SYSTEMTIME time;
  GetSystemTime(&time);
  if (FAILED(StringCchPrintfW(path + name, MAX_PATH - name,
      L"ngs2coop-core-%04u%02u%02u-%02u%02u%02u-%03u-%lu.log",
      time.wYear, time.wMonth, time.wDay, time.wHour, time.wMinute,
      time.wSecond, time.wMilliseconds, GetCurrentProcessId()))) return false;
  // Never overwrite a previous run's evidence. Local to plugin/, independent of CWD.
  const HANDLE file = CreateFileW(path, GENERIC_WRITE, FILE_SHARE_READ, nullptr, CREATE_NEW,
                                  FILE_ATTRIBUTE_NORMAL | FILE_FLAG_WRITE_THROUGH, nullptr);
  if (file != INVALID_HANDLE_VALUE) log_file.store(file, std::memory_order_release);
  return file != INVALID_HANDLE_VALUE;
}

bool Sigma2_vfunction1(Sigma2* self) {
  const bool first = !invocation_logged.test_and_set(std::memory_order_relaxed);
  if (first) log_message("NGS2Coop: Sigma2 hook invoked\n");
  const bool result = sigma2_hook.original()(self);
  if (first) log_message(result
      ? "NGS2Coop: Sigma2 original returned bool=true; forwarding unchanged\n"
      : "NGS2Coop: Sigma2 original returned bool=false; forwarding unchanged\n");
  return result;
}

DWORD WINAPI initialize(LPVOID parameter) noexcept {
  if (initialization_started.test_and_set(std::memory_order_acq_rel)) return 0;
  // Historical loader retains its LoadLibrary reference for the whole process.
  // Pin before publishing any callback, including for the worker's lifetime.
  HMODULE pinned;
  if (!GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_PIN,
                         reinterpret_cast<LPCWSTR>(parameter), &pinned)) {
    OutputDebugStringA("NGS2Coop: core plugin initialization refused: pin failed\n");
    return 0;
  }
  if (!open_log(pinned)) {
    OutputDebugStringA("NGS2Coop: core plugin initialization refused: cannot create log\n");
    return 0; // This controlled test requires persistent evidence before patching.
  }
  log_message("NGS2Coop: core plugin loaded\n");
  log_message("NGS2Coop: initialization starting\n");
  const auto base = reinterpret_cast<uintptr_t>(GetModuleHandleW(nullptr));
  char message[256];
  StringCbPrintfA(message, sizeof(message), "NGS2Coop: module base = %p\n", reinterpret_cast<void*>(base));
  log_message(message);
  if (!sigma2_image_matches(base)) {
    log_message("NGS2Coop: version guard FAIL: unsupported image; no hook installed\n");
    return 0;
  }
  const auto slot = base + sigma2_slot_rva;
  const auto expected = base + sigma2_function_rva;
  StringCbPrintfA(message, sizeof(message),
      "NGS2Coop: Sigma2 slot = %p (RVA 0x18F9518)\nNGS2Coop: expected target = %p\n",
      reinterpret_cast<void*>(slot), reinterpret_cast<void*>(expected));
  log_message(message);
  uintptr_t current;
  if (!WindowsSlotOps::load(slot, current)) {
    log_message("NGS2Coop: version guard FAIL: slot unreadable; no hook installed\n");
    return 0;
  }
  StringCbPrintfA(message, sizeof(message), "NGS2Coop: Sigma2 slot current target = %p\n",
                  reinterpret_cast<void*>(current));
  log_message(message);
  if (current != expected) {
    log_message("NGS2Coop: version guard FAIL: target mismatch; no hook installed\n");
    return 0;
  }
  log_message("NGS2Coop: version guard PASS (image and target; CAS rechecks target)\n");
  const auto result = sigma2_hook.install(slot, reinterpret_cast<bool (*)(Sigma2*)>(expected),
                                         Sigma2_vfunction1);
  if (result == Sigma2Hook::Result::installed) {
    log_message("NGS2Coop: Sigma2 hook installed\n");
  } else {
    StringCbPrintfA(message, sizeof(message), "NGS2Coop: Sigma2 hook installation refused (result=%u)\n",
                    static_cast<unsigned>(result));
    log_message(message);
    if (result == Sigma2Hook::Result::protection_restore_failed)
      log_message("NGS2Coop: protection restore failed; conditional rollback attempted\n");
  }
  return 0;
}
} // namespace

extern "C" BOOL WINAPI DllMain(HINSTANCE module, DWORD reason, LPVOID) {
  if (reason == DLL_PROCESS_ATTACH) {
    DisableThreadLibraryCalls(module);
    // No wait, logging, module lookup, patching or plugin loading under loader lock.
    // Thread entry executes after loader notifications; scheduling before the game's
    // first Sigma2 call is NOT guaranteed. Never manually invoke the game function.
    const HANDLE thread = CreateThread(nullptr, 0, initialize, module, 0, nullptr);
    if (!thread) return FALSE;
    CloseHandle(thread);
  }
  return TRUE;
}

// Outside DllMain only. Module/log remain resident for already-fetched callbacks.
extern "C" __declspec(dllexport) BOOL NMRestoreSigma2Hook() {
  const auto result = sigma2_hook.restore();
  // Avoid logger access before initialization has published the callback.
  OutputDebugStringA("NGS2Coop: explicit Sigma2 restore requested\n");
  return result == Sigma2Hook::Result::restored || result == Sigma2Hook::Result::inactive;
}
