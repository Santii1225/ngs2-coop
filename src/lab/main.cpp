/*
 * ngs2lab: in-process test harness for unattended development sessions.
 *  - Present hook: dumps the backbuffer to plugin/lab_shot.bmp on request.
 *  - Command file plugin/lab_cmd.txt polled by a worker thread.
 */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <tlhelp32.h>
#include <d3d11.h>
#include <dxgi.h>
#include <atomic>
#include <cstdio>
#include <cstring>
#include <cwchar>
#include <cstdarg>
#include <cstdint>

namespace {
HMODULE self;
wchar_t dir[MAX_PATH];
std::atomic<int> shot_requested{0};
std::atomic<uint64_t> frame_count{0};
using PresentFn = HRESULT(STDMETHODCALLTYPE*)(IDXGISwapChain*, UINT, UINT);
PresentFn original_present;

// NGS2LAB_SUFFIX keeps a second game copy's command/shot files apart from the first's.
void path_in_dir(wchar_t* out, const wchar_t* name) {
  lstrcpyW(out, dir);
  lstrcatW(out, name);
  wchar_t suffix[32] = {};
  if (!GetEnvironmentVariableW(L"NGS2LAB_SUFFIX", suffix, 32) || !suffix[0]) return;
  wchar_t* dot = wcsrchr(out, L'.');
  wchar_t ext[16] = {};
  if (dot) { lstrcpynW(ext, dot, 16); *dot = 0; }
  lstrcatW(out, suffix);
  lstrcatW(out, ext);
}

void lab_log(const char* fmt, ...) {
  wchar_t p[MAX_PATH];
  path_in_dir(p, L"lab.log");
  FILE* f = _wfopen(p, L"a");
  if (!f) return;
  va_list ap;
  va_start(ap, fmt);
  vfprintf(f, fmt, ap);
  va_end(ap);
  fputc('\n', f);
  fclose(f);
}

void dump_backbuffer(IDXGISwapChain* sc) {
  ID3D11Texture2D* bb = nullptr;
  if (FAILED(sc->GetBuffer(0, __uuidof(ID3D11Texture2D), reinterpret_cast<void**>(&bb)))) {
    lab_log("shot: GetBuffer failed");
    return;
  }
  ID3D11Device* dev = nullptr;
  bb->GetDevice(&dev);
  ID3D11DeviceContext* ctx = nullptr;
  dev->GetImmediateContext(&ctx);
  D3D11_TEXTURE2D_DESC d;
  bb->GetDesc(&d);
  D3D11_TEXTURE2D_DESC sd = d;
  sd.Usage = D3D11_USAGE_STAGING;
  sd.BindFlags = 0;
  sd.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
  sd.MiscFlags = 0;
  sd.SampleDesc.Count = 1;
  sd.SampleDesc.Quality = 0;
  ID3D11Texture2D* st = nullptr;
  if (SUCCEEDED(dev->CreateTexture2D(&sd, nullptr, &st))) {
    if (d.SampleDesc.Count > 1) ctx->ResolveSubresource(st, 0, bb, 0, d.Format);
    else ctx->CopyResource(st, bb);
    D3D11_MAPPED_SUBRESOURCE m;
    if (SUCCEEDED(ctx->Map(st, 0, D3D11_MAP_READ, 0, &m))) {
      wchar_t p[MAX_PATH], tmp[MAX_PATH];
      path_in_dir(p, L"lab_shot.bmp");
      path_in_dir(tmp, L"lab_shot.tmp");
      FILE* f = _wfopen(tmp, L"wb");
      if (f) {
        const int w = d.Width, h = d.Height;
        const bool bgr = d.Format == DXGI_FORMAT_B8G8R8A8_UNORM || d.Format == DXGI_FORMAT_B8G8R8A8_UNORM_SRGB;
        BITMAPFILEHEADER fh{};
        BITMAPINFOHEADER ih{};
        fh.bfType = 0x4D42;
        fh.bfOffBits = sizeof(fh) + sizeof(ih);
        fh.bfSize = fh.bfOffBits + w * h * 4;
        ih.biSize = sizeof(ih);
        ih.biWidth = w;
        ih.biHeight = -h;
        ih.biPlanes = 1;
        ih.biBitCount = 32;
        fwrite(&fh, sizeof(fh), 1, f);
        fwrite(&ih, sizeof(ih), 1, f);
        uint8_t* row = new uint8_t[w * 4];
        for (int y = 0; y < h; ++y) {
          const uint8_t* src = static_cast<const uint8_t*>(m.pData) + y * m.RowPitch;
          for (int x = 0; x < w; ++x) {
            const uint8_t* s = src + x * 4;
            uint8_t* o = row + x * 4;
            if (bgr) { o[0] = s[0]; o[1] = s[1]; o[2] = s[2]; }
            else { o[0] = s[2]; o[1] = s[1]; o[2] = s[0]; }
            o[3] = 255;
          }
          fwrite(row, 1, w * 4, f);
        }
        delete[] row;
        fclose(f);
        MoveFileExW(tmp, p, MOVEFILE_REPLACE_EXISTING);
        lab_log("shot: %dx%d fmt=%d frame=%llu", w, h, d.Format, (unsigned long long)frame_count.load());
      }
      ctx->Unmap(st, 0);
    }
    st->Release();
  } else {
    lab_log("shot: CreateTexture2D failed fmt=%d", d.Format);
  }
  ctx->Release();
  dev->Release();
  bb->Release();
}

HRESULT STDMETHODCALLTYPE present_hook(IDXGISwapChain* sc, UINT sync, UINT flags) {
  frame_count.fetch_add(1, std::memory_order_relaxed);
  if (shot_requested.exchange(0)) dump_backbuffer(sc);
  return original_present(sc, sync, flags);
}

bool hook_present() {
  WNDCLASSA wc{};
  wc.lpfnWndProc = DefWindowProcA;
  wc.hInstance = self;
  wc.lpszClassName = "ngs2lab_dummy";
  RegisterClassA(&wc);
  HWND hwnd = CreateWindowA("ngs2lab_dummy", "", WS_OVERLAPPEDWINDOW, 0, 0, 64, 64, nullptr, nullptr, self, nullptr);
  DXGI_SWAP_CHAIN_DESC sd{};
  sd.BufferCount = 1;
  sd.BufferDesc.Width = 64;
  sd.BufferDesc.Height = 64;
  sd.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
  sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
  sd.OutputWindow = hwnd;
  sd.SampleDesc.Count = 1;
  sd.Windowed = TRUE;
  IDXGISwapChain* sc = nullptr;
  ID3D11Device* dev = nullptr;
  ID3D11DeviceContext* ctx = nullptr;
  HRESULT hr = D3D11CreateDeviceAndSwapChain(nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, 0, nullptr, 0,
                                             D3D11_SDK_VERSION, &sd, &sc, &dev, nullptr, &ctx);
  if (FAILED(hr)) {
    lab_log("hook: dummy device failed hr=%08lx", hr);
    DestroyWindow(hwnd);
    return false;
  }
  void** vtbl = *reinterpret_cast<void***>(sc);
  DWORD old;
  VirtualProtect(&vtbl[8], sizeof(void*), PAGE_READWRITE, &old);
  original_present = reinterpret_cast<PresentFn>(vtbl[8]);
  vtbl[8] = reinterpret_cast<void*>(&present_hook);
  VirtualProtect(&vtbl[8], sizeof(void*), old, &old);
  lab_log("hook: Present vtable=%p original=%p", vtbl, original_present);
  sc->Release();
  ctx->Release();
  dev->Release();
  DestroyWindow(hwnd);
  return true;
}

// XInput view from inside the process (what Wine reports, independent of the game's cache).
void xinput_report() {
  struct State { DWORD packet; WORD buttons; BYTE lt, rt; SHORT lx, ly, rx, ry; };
  using GetStateFn = DWORD(WINAPI*)(DWORD, State*);
  HMODULE x = GetModuleHandleA("xinput1_3.dll");
  if (!x) x = LoadLibraryA("xinput1_3.dll");
  auto get = x ? reinterpret_cast<GetStateFn>(GetProcAddress(x, "XInputGetState")) : nullptr;
  if (!get) { lab_log("xinput: XInputGetState unavailable"); return; }
  for (DWORD i = 0; i < 4; ++i) {
    State st{};
    const DWORD r = get(i, &st);
    lab_log("xinput slot %lu: %s buttons=%04x lx=%d ly=%d", i, r == 0 ? "CONNECTED" : "absent",
            st.buttons, st.lx, st.ly);
  }
}

// "stacks": every thread's real context (rip/rsp, also when it runs a fiber or waits in a syscall) and the
// return addresses on its stack that follow a call, as module+offset. Logged to lab.log.
const char* module_of(uint64_t a, uint64_t* off) {
  static char name[MAX_PATH];
  HMODULE m = nullptr;
  if (!GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                          reinterpret_cast<LPCSTR>(a), &m) || !m)
    return nullptr;
  char full[MAX_PATH];
  if (!GetModuleFileNameA(m, full, MAX_PATH)) return nullptr;
  const char* s = strrchr(full, '\\');
  lstrcpynA(name, s ? s + 1 : full, MAX_PATH);
  *off = a - reinterpret_cast<uint64_t>(m);
  return name;
}

bool after_call(uint64_t a) {
  MEMORY_BASIC_INFORMATION mi;
  if (!VirtualQuery(reinterpret_cast<void*>(a - 7), &mi, sizeof(mi)) || mi.State != MEM_COMMIT ||
      !(mi.Protect & (PAGE_EXECUTE | PAGE_EXECUTE_READ | PAGE_EXECUTE_READWRITE | PAGE_EXECUTE_WRITECOPY)))
    return false;
  const auto* p = reinterpret_cast<const uint8_t*>(a);
  return p[-5] == 0xe8 || (p[-6] == 0xff && (p[-5] & 0x38) == 0x10) || (p[-2] == 0xff && (p[-1] & 0xf8) == 0xd0) ||
         (p[-3] == 0xff && (p[-2] & 0x38) == 0x10) || (p[-7] == 0xff && (p[-6] & 0x38) == 0x10) ||
         (p[-3] == 0x41 && p[-2] == 0xff);
}

void stacks_report() {
  using QueryFn = LONG(NTAPI*)(HANDLE, int, void*, ULONG, ULONG*);
  auto query = reinterpret_cast<QueryFn>(GetProcAddress(GetModuleHandleA("ntdll.dll"), "NtQueryInformationThread"));
  const DWORD me = GetCurrentThreadId(), pid = GetCurrentProcessId();
  HANDLE snap = CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0);
  THREADENTRY32 te{};
  te.dwSize = sizeof(te);
  for (BOOL ok = Thread32First(snap, &te); ok; ok = Thread32Next(snap, &te)) {
    if (te.th32OwnerProcessID != pid || te.th32ThreadID == me) continue;
    HANDLE h = OpenThread(THREAD_ALL_ACCESS, FALSE, te.th32ThreadID);
    if (!h) continue;
    struct { LONG status; void* teb; void* pid; void* tid; ULONG_PTR mask; LONG prio, base; } tbi{};
    query(h, 0, &tbi, sizeof(tbi), nullptr);
    SuspendThread(h);
    CONTEXT c{};
    c.ContextFlags = CONTEXT_CONTROL | CONTEXT_INTEGER;
    if (GetThreadContext(h, &c)) {
      char out[4096];
      int n = 0;
      uint64_t off = 0;
      const char* rm = module_of(c.Rip, &off);
      n += snprintf(out + n, sizeof(out) - n, "tid %lu rip %s+%llx rsp %llx:", te.th32ThreadID, rm ? rm : "?",
                    static_cast<unsigned long long>(off), static_cast<unsigned long long>(c.Rsp));
      // Stack: from rsp up to whichever reservation holds it (fibers have their own).
      MEMORY_BASIC_INFORMATION mi;
      uint64_t top = c.Rsp + 0x10000;
      if (VirtualQuery(reinterpret_cast<void*>(c.Rsp), &mi, sizeof(mi)))
        top = reinterpret_cast<uint64_t>(mi.BaseAddress) + mi.RegionSize;
      int frames = 0;
      for (uint64_t a = c.Rsp; a + 8 <= top && frames < 40 && n < 3900; a += 8) {
        const uint64_t v = *reinterpret_cast<const uint64_t*>(a);
        if (v < 0x10000 || !after_call(v)) continue;
        const char* m = module_of(v, &off);
        if (!m) continue;
        n += snprintf(out + n, sizeof(out) - n, " %s+%llx", m, static_cast<unsigned long long>(off));
        ++frames;
      }
      lab_log("%s", out);
    }
    ResumeThread(h);
    CloseHandle(h);
    (void)tbi;
  }
  CloseHandle(snap);
  lab_log("stacks: done");
}

// First-chance exceptions (the quick-menu hang/crash): code, where, the faulting address for access violations,
// the registers and the return addresses on the stack. Thread naming and debug-print exceptions are skipped.
std::atomic<int> exceptions_logged{0};
LONG CALLBACK exception_logger(EXCEPTION_POINTERS* ep) {
  const DWORD code = ep->ExceptionRecord->ExceptionCode;
  if (code == 0x406d1388 || code == 0x40010006 || code == 0x4001000a || code == 0xe06d7363 + 1) return EXCEPTION_CONTINUE_SEARCH;
  if (exceptions_logged.fetch_add(1) >= 40) return EXCEPTION_CONTINUE_SEARCH;
  const CONTEXT* c = ep->ContextRecord;
  char out[4096];
  int n = 0;
  uint64_t off = 0;
  const char* rm = module_of(c->Rip, &off);
  SYSTEMTIME st;
  GetLocalTime(&st);
  n += snprintf(out + n, sizeof(out) - n, "%02d:%02d:%02d EXC %08lx tid %lu at %s+%llx", st.wHour, st.wMinute, st.wSecond, code, GetCurrentThreadId(), rm ? rm : "?",
                static_cast<unsigned long long>(off));
  if (code == EXCEPTION_ACCESS_VIOLATION && ep->ExceptionRecord->NumberParameters >= 2)
    n += snprintf(out + n, sizeof(out) - n, " (%s %llx)", ep->ExceptionRecord->ExceptionInformation[0] ? "write" : "read",
                  static_cast<unsigned long long>(ep->ExceptionRecord->ExceptionInformation[1]));
  n += snprintf(out + n, sizeof(out) - n, " rax=%llx rbx=%llx rcx=%llx rdx=%llx rsi=%llx rdi=%llx r8=%llx r9=%llx rsp=%llx stack:",
                c->Rax, c->Rbx, c->Rcx, c->Rdx, c->Rsi, c->Rdi, c->R8, c->R9, c->Rsp);
  MEMORY_BASIC_INFORMATION mi;
  uint64_t top = c->Rsp + 0x8000;
  if (VirtualQuery(reinterpret_cast<void*>(c->Rsp), &mi, sizeof(mi)))
    top = reinterpret_cast<uint64_t>(mi.BaseAddress) + mi.RegionSize;
  int frames = 0;
  for (uint64_t a = c->Rsp; a + 8 <= top && frames < 30 && n < 3900; a += 8) {
    const uint64_t v = *reinterpret_cast<const uint64_t*>(a);
    if (v < 0x10000 || !after_call(v)) continue;
    const char* m = module_of(v, &off);
    if (!m) continue;
    n += snprintf(out + n, sizeof(out) - n, " %s+%llx", m, static_cast<unsigned long long>(off));
    ++frames;
  }
  lab_log("%s", out);
  return EXCEPTION_CONTINUE_SEARCH;
}

void handle_command(char* line) {
  if (!strncmp(line, "shot", 4)) shot_requested = 1;
  else if (!strncmp(line, "xinput", 6)) xinput_report();
  else if (!strncmp(line, "stacks", 6)) stacks_report();
}

DWORD WINAPI worker(LPVOID) {
  Sleep(3000);
  hook_present();
  wchar_t p[MAX_PATH];
  path_in_dir(p, L"lab_cmd.txt");
  for (;;) {
    Sleep(30);
    FILE* f = _wfopen(p, L"r");
    if (!f) continue;
    char line[512];
    while (fgets(line, sizeof(line), f)) handle_command(line);
    fclose(f);
    DeleteFileW(p);
  }
}
} // namespace

extern "C" BOOL WINAPI DllMain(HINSTANCE module, DWORD reason, LPVOID) {
  if (reason == DLL_PROCESS_ATTACH) {
    DisableThreadLibraryCalls(module);
    self = module;
    GetModuleFileNameW(module, dir, MAX_PATH);
    wchar_t* s = wcsrchr(dir, L'\\');
    if (s) s[1] = 0;
    AddVectoredExceptionHandler(1, exception_logger);
    HANDLE t = CreateThread(nullptr, 0, worker, nullptr, 0, nullptr);
    if (t) CloseHandle(t);
  }
  return TRUE;
}
