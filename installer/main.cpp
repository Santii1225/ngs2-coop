// NGS2 Co-op installer (Windows and Linux).
//
// One program for both systems: it finds NINJA GAIDEN Σ2 in the Steam libraries, copies the mod (NM Plugins +
// NGS2Coop.dll) into the game's folder and, on Linux, adds the launch option Proton needs
// (WINEDLLOVERRIDES=dbghelp=n,b %command%). It also uninstalls. The mod's files travel inside the executable:
// tools/make_installers.sh appends them after the program, followed by an index and a trailer:
//   [program][file data...][index: "path\tsize\toffset\n"...][u64 index size]["NGS2COOP"]
//
// Usage: double-click (a menu asks what to do), or
//   ngs2coop-setup [--install | --uninstall] [--game-dir DIR] [--yes]
#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <memory>
#include <optional>
#include <sstream>
#include <string>
#include <vector>

#ifdef _WIN32
#include <windows.h>
#include <shellapi.h>
#else
#include <dirent.h>
#include <spawn.h>
#include <sys/wait.h>
#include <unistd.h>
extern char** environ;
#endif

namespace fs = std::filesystem;

constexpr const char* kAppId = "1580790";
constexpr const char* kGameExe = "NINJA GAIDEN SIGMA2.exe";
constexpr const char* kVersion = "1.2";
constexpr const char* kManifest = "plugin/ngs2coop-installed.txt";  // what the installer wrote, for uninstalling
constexpr const char* kBackupSuffix = ".ngs2coop-backup";             // a file the install replaced
constexpr const char* kOverride = "WINEDLLOVERRIDES=dbghelp=n,b";
constexpr char kMagic[8] = {'N', 'G', 'S', '2', 'C', 'O', 'O', 'P'};

bool assume_yes = false;
bool custom_steam_root = false;  // --steam-root (tests): leave the running Steam alone

// ---- Text and paths --------------------------------------------------------------------------------------

fs::path from_utf8(const std::string& s) {
#ifdef _WIN32
  const int n = MultiByteToWideChar(CP_UTF8, 0, s.c_str(), -1, nullptr, 0);
  std::wstring w(n > 0 ? n - 1 : 0, L'\0');
  if (n > 1) MultiByteToWideChar(CP_UTF8, 0, s.c_str(), -1, w.data(), n);
  return fs::path(w);
#else
  return fs::path(s);
#endif
}

std::string to_utf8(const fs::path& p) {
#ifdef _WIN32
  const std::wstring w = p.wstring();
  const int n = WideCharToMultiByte(CP_UTF8, 0, w.c_str(), -1, nullptr, 0, nullptr, nullptr);
  std::string s(n > 0 ? n - 1 : 0, '\0');
  if (n > 1) WideCharToMultiByte(CP_UTF8, 0, w.c_str(), -1, s.data(), n, nullptr, nullptr);
  return s;
#else
  return p.string();
#endif
}

void say(const std::string& s) { std::cout << s << std::endl; }

std::string ask(const std::string& prompt) {
  std::cout << prompt << std::flush;
  std::string line;
  if (!std::getline(std::cin, line)) return "";
  while (!line.empty() && (line.back() == '\r' || line.back() == '\n' || line.back() == ' ')) line.pop_back();
  return line;
}

bool confirm(const std::string& prompt) {
  if (assume_yes) return true;
  const std::string a = ask(prompt + " [S/n]: ");
  return a.empty() || a[0] == 's' || a[0] == 'S' || a[0] == 'y' || a[0] == 'Y';
}

std::optional<std::string> read_text(const fs::path& p) {
  std::ifstream f(p, std::ios::binary);
  if (!f) return std::nullopt;
  std::ostringstream ss;
  ss << f.rdbuf();
  return ss.str();
}

bool write_text(const fs::path& p, const std::string& s) {
  std::ofstream f(p, std::ios::binary | std::ios::trunc);
  f << s;
  return static_cast<bool>(f);
}

// ---- The payload appended to this executable -------------------------------------------------------------

struct Entry {
  std::string path;  // relative to the game folder, '/' separated
  uint64_t size, offset;
};

fs::path self_path() {
#ifdef _WIN32
  std::wstring buf(32768, L'\0');
  const DWORD n = GetModuleFileNameW(nullptr, buf.data(), static_cast<DWORD>(buf.size()));
  buf.resize(n);
  return fs::path(buf);
#else
  return fs::read_symlink("/proc/self/exe");
#endif
}

bool read_payload(std::vector<Entry>& entries, std::ifstream& in) {
  in.open(self_path(), std::ios::binary);
  if (!in) return false;
  in.seekg(0, std::ios::end);
  const auto end = static_cast<uint64_t>(in.tellg());
  if (end < 16) return false;
  char magic[8];
  uint64_t index_size = 0;
  in.seekg(static_cast<std::streamoff>(end - 16));
  in.read(reinterpret_cast<char*>(&index_size), 8);
  in.read(magic, 8);
  if (memcmp(magic, kMagic, 8) || index_size == 0 || index_size > end - 16) return false;
  std::string index(index_size, '\0');
  in.seekg(static_cast<std::streamoff>(end - 16 - index_size));
  in.read(index.data(), static_cast<std::streamsize>(index_size));
  std::istringstream lines(index);
  std::string line;
  while (std::getline(lines, line)) {
    std::istringstream cols(line);
    Entry e{};
    if (std::getline(cols, e.path, '\t') && (cols >> e.size >> e.offset)) entries.push_back(e);
  }
  return !entries.empty();
}

bool extract(std::ifstream& in, const Entry& e, const fs::path& to) {
  std::vector<char> data(e.size);
  in.clear();
  in.seekg(static_cast<std::streamoff>(e.offset));
  in.read(data.data(), static_cast<std::streamsize>(e.size));
  if (!in) return false;
  const fs::path tmp = to.string() + ".tmp";
  {
    std::ofstream out(tmp, std::ios::binary | std::ios::trunc);
    out.write(data.data(), static_cast<std::streamsize>(data.size()));
    if (!out) return false;
  }
  std::error_code ec;
  fs::rename(tmp, to, ec);
  if (ec) {
    fs::remove(tmp, ec);
    return false;
  }
  return true;
}

// ---- Valve KeyValues text (libraryfolders.vdf, appmanifest, localconfig.vdf) -------------------------------

struct Node {
  std::string key, value;
  bool block = false;
  std::vector<std::unique_ptr<Node>> children;
  Node* child(const std::string& k) {
    for (auto& c : children)
      if (c->block && strcasecmp_like(c->key, k)) return c.get();
    return nullptr;
  }
  Node* value_node(const std::string& k) {
    for (auto& c : children)
      if (!c->block && strcasecmp_like(c->key, k)) return c.get();
    return nullptr;
  }
  Node* ensure_block(const std::string& k) {
    if (Node* c = child(k)) return c;
    children.push_back(std::make_unique<Node>());
    children.back()->key = k;
    children.back()->block = true;
    return children.back().get();
  }
  static bool strcasecmp_like(const std::string& a, const std::string& b) {
    if (a.size() != b.size()) return false;
    for (size_t i = 0; i < a.size(); ++i)
      if (tolower(static_cast<unsigned char>(a[i])) != tolower(static_cast<unsigned char>(b[i]))) return false;
    return true;
  }
};

class VdfReader {
 public:
  explicit VdfReader(const std::string& s) : s_(s) {}
  bool parse(Node& root) { return parse_block(root, true) && !failed_; }

 private:
  const std::string& s_;
  size_t i_ = 0;
  bool failed_ = false;
  void skip() {
    for (;;) {
      while (i_ < s_.size() && isspace(static_cast<unsigned char>(s_[i_]))) ++i_;
      if (i_ + 1 < s_.size() && s_[i_] == '/' && s_[i_ + 1] == '/') {
        while (i_ < s_.size() && s_[i_] != '\n') ++i_;
        continue;
      }
      return;
    }
  }
  bool token(std::string& out, char& kind) {  // kind: '"' string, '{', '}', 0 end
    skip();
    if (i_ >= s_.size()) return kind = 0, true;
    const char c = s_[i_];
    if (c == '{' || c == '}') return ++i_, kind = c, true;
    out.clear();
    kind = '"';
    if (c == '"') {
      ++i_;
      while (i_ < s_.size() && s_[i_] != '"') {
        if (s_[i_] == '\\' && i_ + 1 < s_.size()) {
          const char n = s_[i_ + 1];
          out += n == 'n' ? '\n' : n == 't' ? '\t' : n;
          i_ += 2;
        } else {
          out += s_[i_++];
        }
      }
      if (i_ >= s_.size()) return false;
      ++i_;
      return true;
    }
    while (i_ < s_.size() && !isspace(static_cast<unsigned char>(s_[i_])) && s_[i_] != '{' && s_[i_] != '}') out += s_[i_++];
    return true;
  }
  bool parse_block(Node& node, bool top) {
    for (;;) {
      std::string key;
      char kind;
      if (!token(key, kind)) return failed_ = true, false;
      if (kind == 0) return top;
      if (kind == '}') return !top;
      if (kind == '{') return failed_ = true, false;
      std::string value;
      char vkind;
      if (!token(value, vkind) || vkind == 0 || vkind == '}') return failed_ = true, false;
      auto child = std::make_unique<Node>();
      child->key = key;
      if (vkind == '{') {
        child->block = true;
        if (!parse_block(*child, false)) return false;
      } else {
        child->value = value;
      }
      node.children.push_back(std::move(child));
    }
  }
};

std::string vdf_escape(const std::string& s) {
  std::string o;
  for (char c : s) {
    if (c == '"' || c == '\\') o += '\\';
    o += c;
  }
  return o;
}

void vdf_write(const Node& node, std::string& out, int depth) {
  for (const auto& c : node.children) {
    out.append(depth, '\t');
    out += '"' + vdf_escape(c->key) + '"';
    if (c->block) {
      out += '\n';
      out.append(depth, '\t');
      out += "{\n";
      vdf_write(*c, out, depth + 1);
      out.append(depth, '\t');
      out += "}\n";
    } else {
      out += "\t\t\"" + vdf_escape(c->value) + "\"\n";
    }
  }
}

std::optional<Node> load_vdf(const fs::path& p) {
  const auto text = read_text(p);
  if (!text) return std::nullopt;
  Node root;
  root.block = true;
  if (!VdfReader(*text).parse(root)) return std::nullopt;
  return root;
}

// ---- Finding Steam and the game ---------------------------------------------------------------------------

std::vector<fs::path> steam_roots() {
  std::vector<fs::path> roots;
#ifdef _WIN32
  wchar_t buf[MAX_PATH];
  DWORD size = sizeof(buf);
  if (RegGetValueW(HKEY_CURRENT_USER, L"Software\\Valve\\Steam", L"SteamPath", RRF_RT_REG_SZ, nullptr, buf, &size) == ERROR_SUCCESS)
    roots.emplace_back(buf);
  size = sizeof(buf);
  if (RegGetValueW(HKEY_LOCAL_MACHINE, L"SOFTWARE\\WOW6432Node\\Valve\\Steam", L"InstallPath", RRF_RT_REG_SZ, nullptr, buf, &size) == ERROR_SUCCESS)
    roots.emplace_back(buf);
  roots.emplace_back(L"C:\\Program Files (x86)\\Steam");
  roots.emplace_back(L"C:\\Program Files\\Steam");
#else
  const char* home = getenv("HOME");
  const std::string h = home ? home : "";
  for (const char* rel : {"/.local/share/Steam", "/.steam/steam", "/.steam/root", "/.steam/debian-installation",
                          "/.var/app/com.valvesoftware.Steam/.local/share/Steam", "/snap/steam/common/.local/share/Steam"})
    roots.emplace_back(h + rel);
#endif
  std::vector<fs::path> unique;
  for (auto& r : roots) {
    std::error_code ec;
    if (!fs::is_directory(r / "steamapps", ec)) continue;
    const fs::path canon = fs::weakly_canonical(r, ec);
    if (std::find(unique.begin(), unique.end(), canon) == unique.end()) unique.push_back(canon);
  }
  return unique;
}

std::vector<fs::path> libraries(const fs::path& root) {
  std::vector<fs::path> libs{root};
  if (auto vdf = load_vdf(root / "steamapps" / "libraryfolders.vdf")) {
    if (Node* folders = vdf->child("libraryfolders"))
      for (auto& lib : folders->children)
        if (lib->block)
          if (Node* p = lib->value_node("path")) libs.push_back(from_utf8(p->value));
  }
  return libs;
}

std::optional<fs::path> find_game(fs::path* steam_root) {
  for (const auto& root : steam_roots()) {
    for (const auto& lib : libraries(root)) {
      const fs::path manifest = lib / "steamapps" / (std::string("appmanifest_") + kAppId + ".acf");
      auto acf = load_vdf(manifest);
      if (!acf) continue;
      Node* state = acf->child("AppState");
      Node* dir = state ? state->value_node("installdir") : nullptr;
      if (!dir) continue;
      const fs::path game = lib / "steamapps" / "common" / from_utf8(dir->value);
      std::error_code ec;
      if (fs::exists(game / kGameExe, ec)) {
        if (steam_root) *steam_root = root;
        return game;
      }
    }
  }
  return std::nullopt;
}

// ---- Linux: the launch option Proton needs to load the mod ------------------------------------------------

#ifndef _WIN32
bool steam_running() {
  DIR* d = opendir("/proc");
  if (!d) return false;
  bool found = false;
  while (dirent* e = readdir(d)) {
    if (!isdigit(static_cast<unsigned char>(e->d_name[0]))) continue;
    const auto comm = read_text(fs::path("/proc") / e->d_name / "comm");
    if (!comm) continue;
    const std::string c = comm->substr(0, comm->find('\n'));
    if (c == "steam" || c == "steamwebhelper") {
      found = true;
      break;
    }
  }
  closedir(d);
  return found;
}

int run(const std::vector<std::string>& args) {
  std::vector<char*> argv;
  for (auto& a : args) argv.push_back(const_cast<char*>(a.c_str()));
  argv.push_back(nullptr);
  pid_t pid;
  if (posix_spawnp(&pid, argv[0], nullptr, nullptr, argv.data(), environ) != 0) return -1;
  int status = 0;
  waitpid(pid, &status, 0);
  return WIFEXITED(status) ? WEXITSTATUS(status) : -1;
}

bool close_steam(const fs::path& steam_root) {
  if (custom_steam_root || !steam_running()) return true;
  say("Steam está abierto: hay que cerrarlo para guardar la opción de lanzamiento.");
  say("Steam is running: it has to be closed to save the launch option.");
  if (!confirm("¿Cerrar Steam ahora? / Close Steam now?")) return false;
  const bool flatpak = to_utf8(steam_root).find("com.valvesoftware.Steam") != std::string::npos;
  if (flatpak) run({"flatpak", "run", "com.valvesoftware.Steam", "-shutdown"});
  else run({"steam", "-shutdown"});
  for (int i = 0; i < 60 && steam_running(); ++i) sleep(1);
  if (steam_running()) {
    say("Steam no se cerró. Ciérralo tú (menú Steam > Salir) y vuelve a abrir el instalador.");
    say("Steam did not close. Quit it (Steam menu > Exit) and run the installer again.");
    return false;
  }
  return true;
}

// LaunchOptions of the game in every Steam account on this computer (userdata/<id>/config/localconfig.vdf).
int set_launch_options(const fs::path& steam_root, bool add, bool dry_run = false) {
  int changed = 0;
  std::error_code ec;
  for (const auto& user : fs::directory_iterator(steam_root / "userdata", ec)) {
    const fs::path cfg = user.path() / "config" / "localconfig.vdf";
    auto root = load_vdf(cfg);
    if (!root) continue;
    Node* store = root->child("UserLocalConfigStore");
    if (!store) continue;
    Node* app = store->ensure_block("Software")->ensure_block("Valve")->ensure_block("Steam")->ensure_block("apps")->ensure_block(kAppId);
    Node* opt = app->value_node("LaunchOptions");
    std::string cur = opt ? opt->value : "";
    std::string next = cur;
    const size_t at = cur.find(kOverride);
    if (add && at == std::string::npos) {
      if (cur.find("%command%") != std::string::npos) next = std::string(kOverride) + " " + cur;
      else next = std::string(kOverride) + " %command%" + (cur.empty() ? "" : " " + cur);
    } else if (!add && at != std::string::npos) {
      next.erase(at, strlen(kOverride));
      for (size_t sp; (sp = next.find("  ")) != std::string::npos;) next.erase(sp, 1);
      while (!next.empty() && next.front() == ' ') next.erase(next.begin());
      if (next == "%command%") next.clear();
    }
    if (next == cur) continue;
    if (dry_run) {
      ++changed;
      continue;
    }
    if (!opt) {
      app->children.push_back(std::make_unique<Node>());
      opt = app->children.back().get();
      opt->key = "LaunchOptions";
    }
    opt->value = next;
    fs::copy_file(cfg, cfg.string() + ".ngs2coop-backup", fs::copy_options::overwrite_existing, ec);
    std::string out;
    vdf_write(*root, out, 0);
    if (write_text(cfg, out)) ++changed;
  }
  return changed;
}
#endif

// ---- Install / uninstall ----------------------------------------------------------------------------------

std::vector<std::string> read_manifest(const fs::path& game) {
  std::vector<std::string> files;
  if (auto text = read_text(game / kManifest)) {
    std::istringstream lines(*text);
    std::string line;
    while (std::getline(lines, line))
      if (!line.empty() && line[0] != '#') files.push_back(line);
  }
  return files;
}

bool install(const fs::path& game, const fs::path& steam_root) {
  std::vector<Entry> entries;
  std::ifstream in;
  if (!read_payload(entries, in)) {
    say("Error: este instalador está dañado (no trae los archivos del mod). / The installer is damaged.");
    return false;
  }
  std::error_code ec;
  fs::create_directories(game / "plugin", ec);
  const auto previous = read_manifest(game);
  std::string manifest = std::string("# NGS2 Co-op ") + kVersion + "\n";
  for (const auto& e : entries) {
    const fs::path to = game / from_utf8(e.path);
    fs::create_directories(to.parent_path(), ec);
    // A file of someone else's (another mod's dbghelp.dll...) is kept aside once and restored on uninstall.
    const bool ours = std::find(previous.begin(), previous.end(), e.path) != previous.end();
    if (!ours && fs::exists(to, ec) && !fs::exists(to.string() + kBackupSuffix, ec))
      fs::copy_file(to, to.string() + kBackupSuffix, ec);
    if (!extract(in, e, to)) {
      say("Error al escribir / Could not write: " + to_utf8(to));
      say("¿Está el juego abierto? Ciérralo y vuelve a intentarlo. / Is the game running? Close it and retry.");
      return false;
    }
    say("  + " + e.path);
    manifest += e.path + "\n";
  }
  for (const auto& old : previous)  // files of an older version that this one no longer has
    if (std::none_of(entries.begin(), entries.end(), [&](const Entry& e) { return e.path == old; }))
      fs::remove(game / from_utf8(old), ec);
  write_text(game / kManifest, manifest);
#ifndef _WIN32
  if (set_launch_options(steam_root, true, true) == 0) {
    say("La opción de lanzamiento ya estaba puesta. / The launch option was already set.");
  } else if (close_steam(steam_root) && set_launch_options(steam_root, true) > 0) {
    say("Opción de lanzamiento añadida / Launch option added: " + std::string(kOverride) + " %command%");
  } else {
    say("");
    say("Falta un paso: en Steam, clic derecho en el juego > Propiedades > Opciones de lanzamiento, escribe:");
    say("One step left: in Steam, right-click the game > Properties > Launch options, type:");
    say(std::string("    ") + kOverride + " %command%");
  }
#else
  (void)steam_root;
#endif
  return true;
}

bool uninstall(const fs::path& game, const fs::path& steam_root) {
  const auto files = read_manifest(game);
  if (files.empty()) {
    say("El mod no está instalado en esta carpeta. / The mod is not installed in this folder.");
    return false;
  }
  std::error_code ec;
  for (const auto& rel : files) {
    const fs::path p = game / from_utf8(rel);
    fs::remove(p, ec);
    const fs::path backup = p.string() + kBackupSuffix;
    if (fs::exists(backup, ec)) fs::rename(backup, p, ec);
    say("  - " + rel);
  }
  fs::remove(game / kManifest, ec);
#ifndef _WIN32
  if (set_launch_options(steam_root, false, true) > 0 && close_steam(steam_root) && set_launch_options(steam_root, false) > 0)
    say("Opción de lanzamiento quitada. / Launch option removed.");
#else
  (void)steam_root;
#endif
  return true;
}

// ---- Entry point --------------------------------------------------------------------------------------------

#ifndef _WIN32
// Opened by double-click (no terminal): reopen inside one so the questions can be answered.
void reopen_in_terminal(char** argv) {
  if (isatty(0) || getenv("NGS2COOP_IN_TERMINAL")) return;
  setenv("NGS2COOP_IN_TERMINAL", "1", 1);
  const std::string self = to_utf8(self_path());
  const std::vector<std::vector<std::string>> terms = {
      {"konsole", "-e"}, {"gnome-terminal", "--"}, {"kgx", "--"}, {"xfce4-terminal", "-x"}, {"mate-terminal", "-x"},
      {"tilix", "-e"},   {"kitty"},                {"alacritty", "-e"}, {"foot"},           {"wezterm", "start", "--"},
      {"xterm", "-e"},   {"x-terminal-emulator", "-e"}};
  for (const auto& t : terms) {
    std::vector<std::string> args = t;
    args.push_back(self);
    for (int i = 1; argv[i]; ++i) args.push_back(argv[i]);
    std::vector<char*> cargs;
    for (auto& a : args) cargs.push_back(const_cast<char*>(a.c_str()));
    cargs.push_back(nullptr);
    pid_t pid;
    if (posix_spawnp(&pid, cargs[0], nullptr, nullptr, cargs.data(), environ) == 0) exit(0);
  }
}
#endif

int main(int argc, char** argv) {
#ifdef _WIN32
  SetConsoleOutputCP(CP_UTF8);
  SetConsoleCP(CP_UTF8);
#else
  reopen_in_terminal(argv);
#endif
  std::vector<std::string> args;
#ifdef _WIN32
  // argv is in the ANSI code page there: take the UTF-16 command line (folder names like "Σ２").
  int wargc = 0;
  if (LPWSTR* wargv = CommandLineToArgvW(GetCommandLineW(), &wargc)) {
    for (int i = 0; i < wargc; ++i) args.push_back(to_utf8(fs::path(wargv[i])));
    LocalFree(wargv);
  }
#else
  for (int i = 0; i < argc; ++i) args.emplace_back(argv[i]);
#endif
  std::string mode;
  std::optional<fs::path> game_arg, steam_arg;
  for (size_t i = 1; i < args.size(); ++i) {
    const std::string& a = args[i];
    if (a == "--install") mode = "install";
    else if (a == "--uninstall") mode = "uninstall";
    else if (a == "--yes" || a == "-y") assume_yes = true;
    else if (a == "--game-dir" && i + 1 < args.size()) game_arg = from_utf8(args[++i]);
    else if (a == "--steam-root" && i + 1 < args.size()) steam_arg = from_utf8(args[++i]);
  }
  say(std::string("=== NGS2 Co-op ") + kVersion + " — NINJA GAIDEN Σ2 ===");
  say("Co-op local para las Misiones en Equipo / Local co-op for Team Missions");
  say("");
  fs::path steam_root;
  std::optional<fs::path> game = game_arg ? game_arg : find_game(&steam_root);
  if (game_arg) {
    const auto roots = steam_roots();
    if (!roots.empty()) steam_root = roots.front();
  }
  if (steam_arg) {
    steam_root = *steam_arg;
    custom_steam_root = true;
  }
  while (!game || !fs::exists(*game / kGameExe)) {
    say("No encontré el juego. / Could not find the game.");
    if (assume_yes) return 1;
    const std::string typed = ask("Escribe la carpeta del juego (o Enter para salir) / Type the game folder (Enter quits): ");
    if (typed.empty()) return 1;
    std::string t = typed;
    if (t.size() >= 2 && (t.front() == '"' || t.front() == '\'') && t.back() == t.front()) t = t.substr(1, t.size() - 2);
    game = from_utf8(t);
  }
  say("Juego / Game: " + to_utf8(*game));
  const bool installed = !read_manifest(*game).empty();
  if (mode.empty()) {
    say("");
    say(installed ? "1) Actualizar / Update" : "1) Instalar / Install");
    say("2) Desinstalar / Uninstall");
    say("3) Salir / Quit");
    const std::string c = ask("> ");
    mode = c == "1" ? "install" : c == "2" ? "uninstall" : "";
  }
  bool ok = false;
  if (mode == "install") {
    ok = install(*game, steam_root);
    if (ok) {
      say("");
      say("¡Listo! Abre el juego desde Steam. En Misiones en Equipo el jugador 2 se une pulsando BACK en su mando.");
      say("Done! Start the game from Steam. In Team Missions player 2 joins by pressing BACK on their controller.");
    }
  } else if (mode == "uninstall") {
    ok = uninstall(*game, steam_root);
    if (ok) say("Mod desinstalado. / Mod uninstalled.");
  }
  if (!assume_yes) ask("\nPulsa Enter para salir / Press Enter to exit");
  return ok || mode.empty() ? 0 : 1;
}
