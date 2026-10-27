#define WIN32_LEAN_AND_MEAN
#include "overlay.hpp"
#include "split.hpp"
#include <windows.h>
#include <d3d11_1.h>
#include <d3dcompiler.h>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <cwchar>
#include <vector>

namespace overlay {
namespace {
void log_nothing(const char*, ...) {}
void (*log)(const char*, ...) = log_nothing;

// ---- text shared with the worker thread -------------------------------------------------------
CRITICAL_SECTION text_lock;
bool text_ready = false;  // text_lock initialised (install() was called)
wchar_t toast_text[256];
wchar_t notice_text[256];  // persistent top-centre message, hidden while a toast shows
wchar_t status_text[256];
wchar_t left_text[64], right_text[64], marker_text[64];
int marker_col = -1, marker_row = 0;
unsigned toast_gen = 0, notice_gen = 0, status_gen = 0, columns_gen = 0, marker_gen = 0;
ULONGLONG toast_start = 0;
constexpr ULONGLONG kToastMs = 4500, kFadeInMs = 250, kFadeOutMs = 700;

// ---- GPU objects (Present thread only) ---------------------------------------------------------
struct Element {
  ID3D11ShaderResourceView* srv = nullptr;
  int w = 0, h = 0, font_px = 0;
  unsigned gen = ~0u;
  void release() {
    if (srv) srv->Release();
    srv = nullptr;
    w = h = 0;
  }
};

using PresentFn = HRESULT(STDMETHODCALLTYPE*)(IDXGISwapChain*, UINT, UINT);
PresentFn original_present;
void (*volatile frame_callback)() = nullptr;
bool ready = false, disabled = false;
ID3D11Device* device;
ID3DDeviceContextState* state;
ID3D11VertexShader* vs;
ID3D11PixelShader* ps;
ID3D11Buffer* cbuf;
ID3D11BlendState* blend;
ID3D11SamplerState* sampler;
ID3D11RasterizerState* raster;
Element toast_el, notice_el, status_el, left_el, right_el, marker_el;

const char kShader[] = R"(
cbuffer C : register(b0) { float4 rect; float4 alpha; };
struct V { float4 pos : SV_Position; float2 uv : TEXCOORD0; };
V vs_main(uint id : SV_VertexID) {
  float2 t = float2(id & 1, id >> 1);
  V o; o.pos = float4(lerp(rect.xy, rect.zw, t), 0, 1); o.uv = t; return o;
}
Texture2D tex : register(t0); SamplerState smp : register(s0);
float4 ps_main(V i) : SV_Target { return tex.Sample(smp, i.uv) * alpha.x; }
)";

struct CBuf {
  float rect[4];   // NDC: x0, y0 (top left), x1, y1 (bottom right)
  float alpha[4];
};

// Rounded panel + white antialiased text, premultiplied BGRA.
bool rasterize(const wchar_t* text, int font_px, std::vector<uint32_t>& px, int& w, int& h) {
  HDC dc = CreateCompatibleDC(nullptr);
  if (!dc) return false;
  HFONT font = CreateFontW(-font_px, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_TT_PRECIS,
                           CLIP_DEFAULT_PRECIS, ANTIALIASED_QUALITY, DEFAULT_PITCH, L"Georgia");
  HGDIOBJ old_font = SelectObject(dc, font);
  SIZE sz{};
  GetTextExtentPoint32W(dc, text, static_cast<int>(wcslen(text)), &sz);
  const int pad_x = font_px, pad_y = font_px * 9 / 20;
  w = sz.cx + 2 * pad_x;
  h = sz.cy + 2 * pad_y;
  BITMAPINFO bi{};
  bi.bmiHeader.biSize = sizeof(bi.bmiHeader);
  bi.bmiHeader.biWidth = w;
  bi.bmiHeader.biHeight = -h;  // top-down
  bi.bmiHeader.biPlanes = 1;
  bi.bmiHeader.biBitCount = 32;
  void* bits = nullptr;
  HBITMAP bmp = CreateDIBSection(dc, &bi, DIB_RGB_COLORS, &bits, nullptr, 0);
  if (!bmp) {
    SelectObject(dc, old_font);
    DeleteObject(font);
    DeleteDC(dc);
    return false;
  }
  HGDIOBJ old_bmp = SelectObject(dc, bmp);
  memset(bits, 0, static_cast<size_t>(w) * h * 4);
  SetBkMode(dc, TRANSPARENT);
  SetTextColor(dc, RGB(255, 255, 255));
  TextOutW(dc, pad_x, pad_y, text, static_cast<int>(wcslen(text)));
  GdiFlush();

  px.resize(static_cast<size_t>(w) * h);
  const auto* src = static_cast<const uint32_t*>(bits);
  const float r = h * 0.5f, bw = font_px > 24 ? 2.0f : 1.5f;
  const float hx = w * 0.5f, hy = h * 0.5f;
  for (int y = 0; y < h; ++y)
    for (int x = 0; x < w; ++x) {
      // signed distance to the rounded rectangle (pill), for antialiased edge and border
      const float qx = std::fabs(x + 0.5f - hx) - (hx - r), qy = std::fabs(y + 0.5f - hy) - (hy - r);
      const float ox = qx > 0 ? qx : 0, oy = qy > 0 ? qy : 0;
      const float d = std::sqrt(ox * ox + oy * oy) + (qx > qy ? (qx < 0 ? qx : 0) : (qy < 0 ? qy : 0)) - r;
      auto cover = [](float v) { return v < 0 ? 0.0f : v > 1 ? 1.0f : v; };
      const float inside = cover(0.5f - d), border = inside - cover(0.5f - (d + bw));
      // panel: dark blue-black at 75 %, border: the game's menu cyan
      float a = inside * 0.75f, cr = 10 * a, cg = 14 * a, cb = 24 * a;
      const float ba = border * 0.9f;
      cr = 60 * ba + cr * (1 - ba); cg = 170 * ba + cg * (1 - ba); cb = 255 * ba + cb * (1 - ba); a = ba + a * (1 - ba);
      const uint32_t s = src[y * w + x];
      const uint32_t m = ((s >> 16) & 0xff) > ((s >> 8) & 0xff) ? (s >> 16) & 0xff : (s >> 8) & 0xff;
      const float t = (m > (s & 0xff) ? m : s & 0xff) / 255.0f;
      cr = 255 * t + cr * (1 - t); cg = 255 * t + cg * (1 - t); cb = 255 * t + cb * (1 - t); a = t + a * (1 - t);
      px[y * w + x] = (static_cast<uint32_t>(a * 255 + 0.5f) << 24) | (static_cast<uint32_t>(cr + 0.5f) << 16) |
                      (static_cast<uint32_t>(cg + 0.5f) << 8) | static_cast<uint32_t>(cb + 0.5f);
    }
  SelectObject(dc, old_bmp);
  DeleteObject(bmp);
  SelectObject(dc, old_font);
  DeleteObject(font);
  DeleteDC(dc);
  return true;
}

void rebuild(Element& el, const wchar_t* text, unsigned gen, int font_px) {
  if (el.gen == gen && el.font_px == font_px) return;
  el.release();
  el.gen = gen;
  el.font_px = font_px;
  if (!text[0]) return;
  std::vector<uint32_t> px;
  int w, h;
  if (!rasterize(text, font_px, px, w, h)) return;
  D3D11_TEXTURE2D_DESC td{};
  td.Width = w;
  td.Height = h;
  td.MipLevels = td.ArraySize = 1;
  td.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
  td.SampleDesc.Count = 1;
  td.Usage = D3D11_USAGE_IMMUTABLE;
  td.BindFlags = D3D11_BIND_SHADER_RESOURCE;
  D3D11_SUBRESOURCE_DATA init{px.data(), static_cast<UINT>(w * 4), 0};
  ID3D11Texture2D* tex = nullptr;
  if (FAILED(device->CreateTexture2D(&td, &init, &tex))) return;
  device->CreateShaderResourceView(tex, nullptr, &el.srv);
  tex->Release();
  el.w = w;
  el.h = h;
}

bool init(IDXGISwapChain* sc) {
  if (FAILED(sc->GetDevice(__uuidof(ID3D11Device), reinterpret_cast<void**>(&device)))) return false;
  ID3D11Device1* dev1 = nullptr;
  if (FAILED(device->QueryInterface(__uuidof(ID3D11Device1), reinterpret_cast<void**>(&dev1)))) {
    log("overlay: no ID3D11Device1");
    return false;
  }
  const D3D_FEATURE_LEVEL level = device->GetFeatureLevel();
  HRESULT hr = dev1->CreateDeviceContextState(0, &level, 1, D3D11_SDK_VERSION, __uuidof(ID3D11Device1), nullptr, &state);
  dev1->Release();
  if (FAILED(hr)) {
    log("overlay: CreateDeviceContextState failed %08lx", hr);
    return false;
  }
  HMODULE dc = LoadLibraryW(L"d3dcompiler_47.dll");
  auto compile = dc ? reinterpret_cast<pD3DCompile>(reinterpret_cast<void*>(GetProcAddress(dc, "D3DCompile"))) : nullptr;
  if (!compile) {
    log("overlay: d3dcompiler_47 unavailable");
    return false;
  }
  ID3DBlob *vsb = nullptr, *psb = nullptr, *err = nullptr;
  if (FAILED(compile(kShader, sizeof(kShader) - 1, "overlay", nullptr, nullptr, "vs_main", "vs_4_0", 0, 0, &vsb, &err)) ||
      FAILED(compile(kShader, sizeof(kShader) - 1, "overlay", nullptr, nullptr, "ps_main", "ps_4_0", 0, 0, &psb, &err))) {
    log("overlay: shader compile failed: %s", err ? static_cast<const char*>(err->GetBufferPointer()) : "?");
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
  auto& rt = bl.RenderTarget[0];
  rt.BlendEnable = TRUE;
  rt.SrcBlend = rt.SrcBlendAlpha = D3D11_BLEND_ONE;  // premultiplied alpha
  rt.DestBlend = rt.DestBlendAlpha = D3D11_BLEND_INV_SRC_ALPHA;
  rt.BlendOp = rt.BlendOpAlpha = D3D11_BLEND_OP_ADD;
  rt.RenderTargetWriteMask = D3D11_COLOR_WRITE_ENABLE_ALL;
  device->CreateBlendState(&bl, &blend);
  D3D11_SAMPLER_DESC sd{};
  sd.Filter = D3D11_FILTER_MIN_MAG_MIP_POINT;  // drawn 1:1 in pixels
  sd.AddressU = sd.AddressV = sd.AddressW = D3D11_TEXTURE_ADDRESS_CLAMP;
  sd.MaxLOD = D3D11_FLOAT32_MAX;
  device->CreateSamplerState(&sd, &sampler);
  D3D11_RASTERIZER_DESC rd{};
  rd.FillMode = D3D11_FILL_SOLID;
  rd.CullMode = D3D11_CULL_NONE;
  device->CreateRasterizerState(&rd, &raster);
  if (!vs || !ps || !cbuf || !blend || !sampler || !raster) {
    log("overlay: resource creation failed");
    return false;
  }
  log("overlay: ready (feature level %x)", level);
  return true;
}

void draw(ID3D11DeviceContext* ctx, const Element& el, int x, int y, int W, int H, float alpha) {
  if (!el.srv || alpha <= 0) return;
  CBuf cb{{2.0f * x / W - 1, 1 - 2.0f * y / H, 2.0f * (x + el.w) / W - 1, 1 - 2.0f * (y + el.h) / H}, {alpha, 0, 0, 0}};
  ctx->UpdateSubresource(cbuf, 0, nullptr, &cb, 0, 0);
  ctx->PSSetShaderResources(0, 1, &el.srv);
  ctx->Draw(4, 0);
}

void render(IDXGISwapChain* sc) {
  if (disabled) return;
  if (!ready) {
    ready = init(sc);
    if (!ready) {
      disabled = true;
      return;
    }
  }
  wchar_t toast_copy[256], notice_copy[256], status_copy[256], left_copy[64], right_copy[64], marker_copy[64];
  unsigned tg, ng, sg, cg, mg;
  int mcol, mrow;
  ULONGLONG start;
  EnterCriticalSection(&text_lock);
  wcscpy(toast_copy, toast_text);
  wcscpy(notice_copy, notice_text);
  ng = notice_gen;
  wcscpy(status_copy, status_text);
  tg = toast_gen;
  sg = status_gen;
  wcscpy(left_copy, left_text);
  wcscpy(right_copy, right_text);
  cg = columns_gen;
  wcscpy(marker_copy, marker_text);
  mg = marker_gen;
  mcol = marker_col;
  mrow = marker_row;
  start = toast_start;
  LeaveCriticalSection(&text_lock);

  const ULONGLONG age = GetTickCount64() - start;
  float toast_alpha = 0;
  if (toast_copy[0] && age < kToastMs)
    toast_alpha = age < kFadeInMs ? static_cast<float>(age) / kFadeInMs
                : age > kToastMs - kFadeOutMs ? static_cast<float>(kToastMs - age) / kFadeOutMs : 1.0f;
  if (toast_alpha <= 0 && !notice_copy[0] && !status_copy[0] && !left_copy[0] && mcol < 0) return;

  ID3D11Texture2D* bb = nullptr;
  if (FAILED(sc->GetBuffer(0, __uuidof(ID3D11Texture2D), reinterpret_cast<void**>(&bb)))) return;
  D3D11_TEXTURE2D_DESC bd;
  bb->GetDesc(&bd);
  const int W = static_cast<int>(bd.Width), H = static_cast<int>(bd.Height);
  rebuild(toast_el, toast_copy, tg, H * 32 / 1000);
  rebuild(notice_el, notice_copy, ng, H * 32 / 1000);
  rebuild(status_el, status_copy, sg, H * 22 / 1000);
  rebuild(left_el, left_copy, cg, H * 22 / 1000);
  rebuild(right_el, right_copy, cg, H * 22 / 1000);
  rebuild(marker_el, mcol >= 0 ? marker_copy : L"", mg, H * 20 / 1000);
  ID3D11RenderTargetView* rtv = nullptr;
  if (FAILED(device->CreateRenderTargetView(bb, nullptr, &rtv))) {
    bb->Release();
    return;
  }
  ID3D11DeviceContext* ctx = nullptr;
  device->GetImmediateContext(&ctx);
  ID3D11DeviceContext1* ctx1 = nullptr;
  if (SUCCEEDED(ctx->QueryInterface(__uuidof(ID3D11DeviceContext1), reinterpret_cast<void**>(&ctx1)))) {
    ID3DDeviceContextState* prev = nullptr;
    ctx1->SwapDeviceContextState(state, &prev);
    D3D11_VIEWPORT vp{0, 0, static_cast<float>(W), static_cast<float>(H), 0, 1};
    ctx->RSSetViewports(1, &vp);
    ctx->RSSetState(raster);
    ctx->OMSetRenderTargets(1, &rtv, nullptr);
    ctx->OMSetBlendState(blend, nullptr, 0xffffffff);
    ctx->IASetInputLayout(nullptr);
    ctx->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP);
    ctx->VSSetShader(vs, nullptr, 0);
    ctx->PSSetShader(ps, nullptr, 0);
    ctx->VSSetConstantBuffers(0, 1, &cbuf);
    ctx->PSSetConstantBuffers(0, 1, &cbuf);
    ctx->PSSetSamplers(0, 1, &sampler);
    draw(ctx, toast_el, (W - toast_el.w) / 2, H * 3 / 100, W, H, toast_alpha);  // top band: free in menus and HUD
    if (toast_alpha < 1) draw(ctx, notice_el, (W - notice_el.w) / 2, H * 3 / 100, W, H, 1.0f - toast_alpha);
    draw(ctx, status_el, W - status_el.w - H * 3 / 100, H * 3 / 100, W, H, 1.0f);
    // centred over the headers (JUGADOR at 28.4 %, COMPAÑERO at 71.6 % of the width; just above them, 23.7 % of the height)
    draw(ctx, left_el, W * 284 / 1000 - left_el.w / 2, H * 237 / 1000 - left_el.h / 2, W, H, 1.0f);
    draw(ctx, right_el, W * 716 / 1000 - right_el.w / 2, H * 237 / 1000 - right_el.h / 2, W, H, 1.0f);
    if (mcol >= 0) {  // mission grid: cell centres at x = 461 + 94.75*col, y = 257 + 56*row (of 960x600)
      const int cx = static_cast<int>(W * (461 + 94.75f * mcol) / 960), top = H * (257 + 56 * mrow - 29) / 600;
      draw(ctx, marker_el, cx - marker_el.w / 2, top - marker_el.h / 2, W, H, 1.0f);
    }
    ID3D11ShaderResourceView* none = nullptr;
    ctx->PSSetShaderResources(0, 1, &none);
    ctx1->SwapDeviceContextState(prev, nullptr);
    if (prev) prev->Release();
    ctx1->Release();
  }
  ctx->Release();
  rtv->Release();
  bb->Release();
}

HRESULT STDMETHODCALLTYPE present_hook(IDXGISwapChain* sc, UINT sync, UINT flags) {
  if (!(flags & DXGI_PRESENT_TEST)) {
    if (split::present(sc)) {
      if (auto cb = frame_callback) cb();
      render(sc);
    }
  }
  return original_present(sc, sync, flags);
}
} // namespace

bool install(void (*logger)(const char*, ...)) {
  log = logger;
  InitializeCriticalSection(&text_lock);
  text_ready = true;
  HINSTANCE self = GetModuleHandleW(nullptr);
  WNDCLASSW wc{};
  wc.lpfnWndProc = DefWindowProcW;
  wc.hInstance = self;
  wc.lpszClassName = L"ngs2coop_overlay_dummy";
  RegisterClassW(&wc);
  HWND hwnd = CreateWindowW(wc.lpszClassName, L"", WS_OVERLAPPEDWINDOW, 0, 0, 64, 64, nullptr, nullptr, self, nullptr);
  DXGI_SWAP_CHAIN_DESC sd{};
  sd.BufferCount = 1;
  sd.BufferDesc.Width = sd.BufferDesc.Height = 64;
  sd.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
  sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
  sd.OutputWindow = hwnd;
  sd.SampleDesc.Count = 1;
  sd.Windowed = TRUE;
  IDXGISwapChain* sc = nullptr;
  ID3D11Device* dev = nullptr;
  ID3D11DeviceContext* ctx = nullptr;
  const HRESULT hr = D3D11CreateDeviceAndSwapChain(nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, 0, nullptr, 0,
                                                   D3D11_SDK_VERSION, &sd, &sc, &dev, nullptr, &ctx);
  if (FAILED(hr)) {
    log("overlay: dummy device failed %08lx", hr);
    DestroyWindow(hwnd);
    return false;
  }
  // The vtable is shared with the game's swap chain; other plugins (ngs2lab) may hook the same slot,
  // so swap it atomically and chain to whatever was there.
  void** slot = &(*reinterpret_cast<void***>(sc))[8];
  DWORD old;
  VirtualProtect(slot, sizeof(void*), PAGE_READWRITE, &old);
  void* prev;
  do {
    prev = *slot;
    original_present = reinterpret_cast<PresentFn>(prev);
  } while (InterlockedCompareExchangePointer(slot, reinterpret_cast<void*>(&present_hook), prev) != prev);
  VirtualProtect(slot, sizeof(void*), old, &old);
  sc->Release();
  ctx->Release();
  dev->Release();
  DestroyWindow(hwnd);
  log("overlay: Present hooked");
  return true;
}

void notice(const wchar_t* text) {
  if (!text_ready) return;
  const wchar_t* t = text ? text : L"";
  EnterCriticalSection(&text_lock);
  if (wcscmp(notice_text, t)) {
    lstrcpynW(notice_text, t, 256);
    ++notice_gen;
  }
  LeaveCriticalSection(&text_lock);
}

void on_frame(void (*fn)()) { frame_callback = fn; }

void toast(const wchar_t* text) {
  if (!text_ready) return;
  EnterCriticalSection(&text_lock);
  lstrcpynW(toast_text, text ? text : L"", 256);
  ++toast_gen;
  toast_start = GetTickCount64();
  LeaveCriticalSection(&text_lock);
}

void column_names(const wchar_t* left, const wchar_t* right) {
  if (!text_ready) return;
  const wchar_t* l = left && right ? left : L"";
  const wchar_t* r = left && right ? right : L"";
  EnterCriticalSection(&text_lock);
  if (wcscmp(left_text, l) || wcscmp(right_text, r)) {
    lstrcpynW(left_text, l, 64);
    lstrcpynW(right_text, r, 64);
    ++columns_gen;
  }
  LeaveCriticalSection(&text_lock);
}

void mission_marker(int col, int row, const wchar_t* text) {
  if (!text_ready) return;
  const wchar_t* t = col >= 0 && text ? text : L"";
  EnterCriticalSection(&text_lock);
  if (marker_col != col || marker_row != row || wcscmp(marker_text, t)) {
    marker_col = col;
    marker_row = row;
    lstrcpynW(marker_text, t, 64);
    ++marker_gen;
  }
  LeaveCriticalSection(&text_lock);
}

void status(const wchar_t* text) {
  if (!text_ready) return;
  const wchar_t* t = text ? text : L"";
  EnterCriticalSection(&text_lock);
  if (wcscmp(status_text, t)) {
    lstrcpynW(status_text, t, 256);
    ++status_gen;
  }
  LeaveCriticalSection(&text_lock);
}
} // namespace overlay
