#include "fa/core/fs.h"

#include <algorithm>
#include <atomic>
#include <cctype>
#include <chrono>
#include <cstdint>
#include <cstdlib>
#include <exception>
#include <fstream>
#include <iterator>
#include <map>
#include <mutex>
#include <optional>
#include <string>
#include <system_error>
#include <thread>
#include <type_traits>
#include <unordered_map>

#ifdef _WIN32
#include <process.h>
#else
#include <unistd.h>
#endif
#ifdef __APPLE__
#include <TargetConditionals.h>
#endif

#include "fa/core/load_trace.h"
#include "fa/core/pack.h"
#include "fa/core/strings.h"
#include "fa/core/utf8.h"
#include "fs_internal.h"

namespace stdfs = std::filesystem;

namespace fa::fs {
namespace {

struct FsState {
    std::mutex mutex;
    stdfs::path root;
    stdfs::path userDir;
    bool rootSet = false;
    bool userDirSet = false;
    stdfs::path cacheDir;
    bool cacheDirSet = false;
    stdfs::path exportDir;
    bool exportDirSet = false;
    std::shared_ptr<const PackReader> pack;  // mount_pack
    struct Warm {
        std::shared_ptr<const std::vector<std::uint8_t>> bytes;  // shared with the FileViews read_view gave out
        std::int64_t modified = 0;
    };
    std::map<std::string, Warm> warm;  // warm(): files read ahead of time, keyed by normalized path
    std::uint64_t diskReads = 0;
};

FsState& state() {
    static FsState s;
    return s;
}

// The mounted pack when `normalized` (already normalized) is a project-relative path it answers for, else null.
std::shared_ptr<const PackReader> pack_for(const std::string& normalized) {
    if (is_absolute(normalized)) return nullptr;
    std::lock_guard<std::mutex> lock(state().mutex);
    return state().pack;
}

// ---- Windows file rules (docs: fs.h, "Windows file rules") ----------------------------------------------------------
// -1: not decided yet (read the environment on first use), 0: off, 1: on. Windows is always "on" and emulates nothing.
std::atomic<int> g_emulate{-1};

bool env_flag(const char* name, bool& value) {
    const char* v = std::getenv(name);
    if (!v || !*v) return false;
    std::string s = to_lower(v);
    value = !(s == "0" || s == "false" || s == "off" || s == "no");
    return true;
}

// True when this process emulates the Windows rules (never on Windows itself). One relaxed atomic load once decided.
inline bool emulating() {
#ifdef _WIN32
    return false;
#else
    int v = g_emulate.load(std::memory_order_relaxed);
    if (v >= 0) return v == 1;
    bool on = false;
    if (!env_flag("FA_FS_WINDOWS_RULES", on)) env_flag("FA_FS_WINDOWS_RULES_DEFAULT", on);
    int expected = -1;
    g_emulate.compare_exchange_strong(expected, on ? 1 : 0);  // a set_windows_rules that raced us wins
    return g_emulate.load(std::memory_order_relaxed) == 1;
#endif
}

// The files open for reading through ReadStream or a fa::PackReader, by registry key. Only used while emulating.
struct Holders {
    int all = 0;       // every open handle: a replace (MoveFileExW onto the file) fails while there is one
    int noDelete = 0;  // the handles that do not let others delete the file (a std::ifstream, a mapped pack): a delete fails
    std::uint64_t generation = 0;  // which file at that path the handles are open on (forget_deleted)
};
struct OpenFiles {
    std::mutex mutex;
    std::unordered_map<std::string, Holders> counts;
    std::uint64_t lastGeneration = 0;
};
OpenFiles& open_files() {
    static OpenFiles o;
    return o;
}

// Windows paths are case-insensitive: so is the key. Symlinks and relative forms are resolved so that two spellings of
// one file meet.
std::string registry_key(const stdfs::path& p) {
    std::error_code ec;
    stdfs::path abs = stdfs::absolute(p, ec);
    if (ec) abs = p;
    stdfs::path canon = stdfs::weakly_canonical(abs, ec);
    std::string key = (ec ? abs.lexically_normal() : canon).generic_string();
    for (char& c : key) c = char(std::tolower(static_cast<unsigned char>(c)));
    return key;
}

class RulesCategory : public std::error_category {
public:
    const char* name() const noexcept override { return "windows-file-rules"; }
    std::string message(int) const override {
        return "The process cannot access the file because it is being used by another process (Windows file rules)";
    }
};
const RulesCategory& rules_category() {
    static const RulesCategory c;
    return c;
}
constexpr int kErrorSharingViolation = 32;  // ERROR_SHARING_VIOLATION

enum class Change { Delete, Replace };
// The error a Windows delete or replace of `p` gives while the process holds it open, or of a folder with such a file
// inside it; empty when nothing holds it or the rules are not emulated. A delete fails only for a handle that did not
// share delete (a std::ifstream, a mapped pack); MSVC's remove deletes a file open with FILE_SHARE_DELETE (an unmapped
// pack) at once, with POSIX semantics. A replace (MoveFileExW onto the file) fails for any open handle.
std::error_code open_conflict(const stdfs::path& p, Change change) {
    if (!emulating()) return {};
    OpenFiles& o = open_files();
    std::lock_guard<std::mutex> lock(o.mutex);
    if (o.counts.empty()) return {};
    auto blocks = [change](const Holders& h) { return change == Change::Replace ? h.all > 0 : h.noDelete > 0; };
    const std::string key = registry_key(p);
    if (auto it = o.counts.find(key); it != o.counts.end() && blocks(it->second)) return {kErrorSharingViolation, rules_category()};
    const std::string below = key + "/";
    for (const auto& [openKey, h] : o.counts)
        if (openKey.compare(0, below.size(), below) == 0 && blocks(h)) return {kErrorSharingViolation, rules_category()};
    return {};
}

// A delete that went through with handles open on the file (all of them shared delete: an unmapped pack) leaves those
// handles on a file that has no name any more, as MSVC's remove does with POSIX semantics: the path is free for a new
// file, which they do not hold. Forget them; their unregister finds another generation (or none) and does nothing.
void forget_deleted(const stdfs::path& p) {
    if (!emulating()) return;
    OpenFiles& o = open_files();
    std::lock_guard<std::mutex> lock(o.mutex);
    if (o.counts.empty()) return;
    const std::string key = registry_key(p);
    const std::string below = key + "/";
    for (auto it = o.counts.begin(); it != o.counts.end();) {
        const bool under = it->first == key || it->first.compare(0, below.size(), below) == 0;
        it = under && it->second.noDelete <= 0 ? o.counts.erase(it) : std::next(it);
    }
}

// The registration of one more handle on `key` (the lock held): the token register_open_file returns.
std::string add_holder(OpenFiles& o, const std::string& key, bool sharesDelete) {
    Holders& h = o.counts[key];
    if (h.all <= 0) h.generation = ++o.lastGeneration;
    ++h.all;
    if (!sharesDelete) ++h.noDelete;
    return key + '\n' + std::to_string(h.generation);
}

void retry_pause(int attempt) { std::this_thread::sleep_for(std::chrono::milliseconds(attempt < 10 ? 1 : 10)); }

bool use_assets(const std::string& normalized) {
#ifdef __ANDROID__
    return !is_absolute(normalized);
#else
    (void)normalized;
    return false;
#endif
}

std::string to_generic(const stdfs::path& p) { return p.generic_string(); }

Error not_found_error(std::string_view requested, const stdfs::path& resolved) {
    std::string hint = is_absolute(requested) ? "No file exists at that absolute path."
                                              : "Paths are relative to the project root (" + to_generic(project_root()) + ").";
    // Suggest a similarly named file from the same directory.
    std::error_code ec;
    stdfs::path dir = resolved.parent_path();
    if (stdfs::is_directory(dir, ec)) {
        std::vector<std::string> names;
        for (auto& entry : stdfs::directory_iterator(dir, ec)) names.push_back(entry.path().filename().string());
        std::sort(names.begin(), names.end());
        std::string match = closest_match(resolved.filename().string(), names);
        if (!match.empty()) hint = "Did you mean '" + to_generic(stdfs::path(std::string(parent(requested))) / match) + "'? " + hint;
    } else {
        hint += " The directory '" + to_generic(dir) + "' does not exist.";
    }
    return make_error("File not found: '" + std::string(requested) + "'", hint);
}

}  // namespace

Result<void> mount_pack(const stdfs::path& packFile) {
    auto opened = PackReader::open(packFile);
    if (!opened.ok()) return opened.error();
    std::lock_guard<std::mutex> lock(state().mutex);
    state().pack = std::move(opened.value());
    return {};
}

void unmount_pack() {
    std::lock_guard<std::mutex> lock(state().mutex);
    state().pack.reset();
}

bool pack_mounted() {
    std::lock_guard<std::mutex> lock(state().mutex);
    return state().pack != nullptr;
}

void set_project_root(const stdfs::path& root) {
    std::error_code ec;
    stdfs::path abs = stdfs::absolute(root, ec).lexically_normal();
    std::lock_guard<std::mutex> lock(state().mutex);
    state().root = abs;
    state().rootSet = true;
}

const stdfs::path& project_root() {
    FsState& s = state();
    std::lock_guard<std::mutex> lock(s.mutex);
    if (!s.rootSet) {
        std::error_code ec;
        s.root = stdfs::current_path(ec);
        s.rootSet = true;
    }
    return s.root;
}

#if !defined(__EMSCRIPTEN__)
void user_dir_changed() {}  // the web build has its own (fs_web.cpp)
void flush_user_dir() {}
#endif

void set_user_dir(const stdfs::path& dir) {
    std::lock_guard<std::mutex> lock(state().mutex);
    state().userDir = dir;
    state().userDirSet = true;
}

void set_cache_dir(const stdfs::path& dir) {
    std::lock_guard<std::mutex> lock(state().mutex);
    state().cacheDir = dir;
    state().cacheDirSet = true;
}

namespace {
// The environment variable `name` as a path ("" when unset or empty). Windows reads the wide form: the narrow one is the ANSI code page.
stdfs::path env_path(const char* name, [[maybe_unused]] const wchar_t* wideName) {
#ifdef _WIN32
    if (const wchar_t* v = _wgetenv(wideName); v && *v) return stdfs::path(std::wstring(v));
    return {};
#else
    const char* v = std::getenv(name);
    return v && *v ? stdfs::path(v) : stdfs::path();
#endif
}
}  // namespace

void reset_cache_dir() {
    std::lock_guard<std::mutex> lock(state().mutex);
    state().cacheDir.clear();
    state().cacheDirSet = false;
}

void set_export_dir(const stdfs::path& dir) {
    std::lock_guard<std::mutex> lock(state().mutex);
    state().exportDir = dir;
    state().exportDirSet = !dir.empty();
}

stdfs::path export_dir() {
    stdfs::path configured;
    {
        std::lock_guard<std::mutex> lock(state().mutex);
        if (state().exportDirSet) configured = state().exportDir;
    }
    if (!configured.empty()) return configured;
    return project_root() / "build" / "export";  // project_root() takes the lock itself
}

stdfs::path cache_dir() {
    FsState& s = state();
    std::lock_guard<std::mutex> lock(s.mutex);
    if (!s.cacheDirSet) {
        s.cacheDirSet = true;
        stdfs::path dir = env_path("FA_CACHE_DIR", L"FA_CACHE_DIR");
#if defined(_WIN32)
        if (dir.empty()) {
            const stdfs::path base = env_path("LOCALAPPDATA", L"LOCALAPPDATA");
            if (!base.empty()) dir = base / "FactorIA" / "Cache";
        }
#elif defined(__EMSCRIPTEN__) || defined(__ANDROID__) || (defined(__APPLE__) && TARGET_OS_IPHONE)
        // The web has no disk; a phone's player names its cache folder (set_cache_dir) once it knows the app's storage.
#elif defined(__APPLE__)
        if (dir.empty()) {
            const stdfs::path home = env_path("HOME", L"HOME");
            if (!home.empty()) dir = home / "Library" / "Caches" / "FactorIA";
        }
#else
        if (dir.empty()) {
            const stdfs::path xdg = env_path("XDG_CACHE_HOME", L"XDG_CACHE_HOME");
            const stdfs::path home = env_path("HOME", L"HOME");
            if (!xdg.empty()) dir = xdg / "factoria";
            else if (!home.empty()) dir = home / ".cache" / "factoria";
        }
#endif
        s.cacheDir = dir;
    }
    return s.cacheDir;
}

stdfs::path make_temp_dir(std::string_view prefix) {
    static std::atomic<unsigned> counter{0};
#ifdef _WIN32
    const long long pid = _getpid();
#else
    const long long pid = static_cast<long long>(::getpid());
#endif
    stdfs::path dir = stdfs::temp_directory_path() /
                      (std::string(prefix) + "_" + std::to_string(pid) + "_" + std::to_string(counter++));
    std::error_code ec;
    remove_tree(dir, ec);  // a leftover of an earlier process that had the same id
    stdfs::create_directories(dir, ec);
    return dir;
}

const stdfs::path& user_dir() {
    const stdfs::path& root = project_root();
    FsState& s = state();
    std::lock_guard<std::mutex> lock(s.mutex);
    if (!s.userDirSet) {
        s.userDir = root / ".factoria" / "save";
        s.userDirSet = true;
    }
    return s.userDir;
}

bool is_absolute(std::string_view path) {
    if (path.empty()) return false;
    if (path[0] == '/' || path[0] == '\\') return true;
    return path.size() >= 2 && std::isalpha(static_cast<unsigned char>(path[0])) && path[1] == ':';
}

Result<std::string> normalize_checked(std::string_view path) {
    std::string p = replace_all(std::string(path), "\\", "/");
    bool absolute = is_absolute(p);
    std::string prefix;
    if (absolute) {
        // Keep "C:" or the leading "/" (or "//" of UNC paths) out of the segment walk.
        if (p.size() >= 2 && p[1] == ':') { prefix = p.substr(0, 2) + "/"; p = p.substr(2); }
        else prefix = "/";
    }
    std::vector<std::string> out;
    for (const std::string& seg : split(p, '/')) {
        if (seg == ".") continue;
        if (seg == "..") {
            if (!out.empty() && out.back() != "..") { out.pop_back(); continue; }
            if (absolute) continue;  // ".." at the filesystem root stays at the root
            return make_error("Path '" + std::string(path) + "' escapes the project root",
                              "Project-relative paths must stay inside the project (e.g. 'assets/player.png'). "
                              "Use an absolute path if you really mean a file outside the project.");
        }
        out.push_back(seg);
    }
    return prefix + fa::join(out, "/");
}

std::string normalize(std::string_view path) {
    auto r = normalize_checked(path);
    return r ? r.value() : std::string();
}

std::filesystem::path path_from_utf8(std::string_view text) {
#ifdef _WIN32
    // Text that is not UTF-8 came from path::string() or generic_string(), which give the ANSI code page: read it the same
    // way. MSVC's path(u8string) throws on it ("No mapping for the Unicode character..."), and many callers still pass that
    // form. An ANSI name that is also valid UTF-8 needs two or more accented letters in a row that spell a UTF-8 sequence
    // ("Ã©"): such a folder name is read as UTF-8.
    if (!fa::is_valid_utf8(text)) return stdfs::path(std::string(text));
#endif
    return stdfs::path(std::u8string(reinterpret_cast<const char8_t*>(text.data()), text.size()));
}

stdfs::path resolve(std::string_view path) {
    auto n = normalize_checked(path);
    if (!n) return {};
    // The text is UTF-8 (path_to_utf8 made it): stdfs::path(std::string) would read it in the ANSI code page on Windows and
    // put a file of a folder with an accent somewhere else ("juego-AdriÃ ").
    if (is_absolute(n.value())) return path_from_utf8(n.value());
    return project_root() / path_from_utf8(n.value());
}

std::string path_to_utf8(const stdfs::path& p) {
#ifdef _WIN32
    // A Windows name may hold a lone surrogate, which is not text: generic_u8string throws for it. This function answers
    // from Result-returning code, so it never throws; a lone surrogate becomes U+FFFD.
    try {
        const std::u8string u = p.generic_u8string();
        return std::string(reinterpret_cast<const char*>(u.data()), u.size());
    } catch (const std::exception&) {
        const std::wstring w = p.generic_wstring();
        std::string out;
        for (std::size_t i = 0; i < w.size(); ++i) {
            char32_t c = static_cast<char32_t>(w[i]);
            if (c >= 0xD800 && c <= 0xDBFF && i + 1 < w.size() && w[i + 1] >= 0xDC00 && w[i + 1] <= 0xDFFF) {
                c = 0x10000 + ((c - 0xD800) << 10) + (static_cast<char32_t>(w[i + 1]) - 0xDC00);
                ++i;
            } else if (c >= 0xD800 && c <= 0xDFFF) {
                c = 0xFFFD;
            }
            utf8_append(out, c);
        }
        return out;
    }
#else
    const std::u8string u = p.generic_u8string();
    return std::string(reinterpret_cast<const char*>(u.data()), u.size());
#endif
}

#ifdef _WIN32
namespace {
// The \\?\ form of an absolute, normalized path (\\?\UNC\ for \\server\share\...).
stdfs::path extended_path(const stdfs::path& abs) {
    const std::wstring& a = abs.native();
    if (a.rfind(LR"(\\?\)", 0) == 0) return abs;
    if (a.rfind(LR"(\\)", 0) == 0) return stdfs::path(LR"(\\?\UNC\)" + a.substr(2));
    return stdfs::path(LR"(\\?\)" + a);
}
}  // namespace
#endif

stdfs::path os_path(const stdfs::path& p) {
#ifdef _WIN32
    // CreateDirectoryW refuses 248 characters or more and the other calls MAX_PATH (260) unless long paths are enabled
    // both in the registry and in the program's manifest; the \\?\ prefix (absolute, backslashes, no . or ..) works always.
    constexpr std::size_t kLimit = 248;
    const std::wstring& given = p.native();
    if (given.rfind(LR"(\\?\)", 0) == 0 || (!p.is_relative() && given.size() < kLimit)) return p;
    std::error_code ec;
    const stdfs::path abs = stdfs::absolute(p, ec).lexically_normal();
    if (ec || abs.native().size() < kLimit) return p;
    return extended_path(abs);
#else
    return p;
#endif
}

std::uintmax_t remove_tree(const stdfs::path& dir, std::error_code& ec) {
    if (emulating() && open_conflict(dir, Change::Delete)) {
        // Windows deletes what it can and leaves the open files (and the folders around them), then reports the failure.
        std::error_code lec;
        std::vector<stdfs::path> files, dirs;
        for (auto it = stdfs::recursive_directory_iterator(dir, lec); !lec && it != stdfs::recursive_directory_iterator(); it.increment(lec))
            (it->is_directory(lec) && !it->is_symlink(lec) ? dirs : files).push_back(it->path());
        std::uintmax_t removed = 0;
        for (const stdfs::path& f : files) {
            std::error_code rec;
            if (!open_conflict(f, Change::Delete) && stdfs::remove(f, rec)) {
                ++removed;
                forget_deleted(f);
            }
        }
        for (auto it = dirs.rbegin(); it != dirs.rend(); ++it) {
            std::error_code rec;
            if (!open_conflict(*it, Change::Delete) && stdfs::remove(*it, rec)) ++removed;
        }
        ec = open_conflict(dir, Change::Delete);
        return removed;
    }
#ifdef _WIN32
    std::error_code aec;
    stdfs::path abs = stdfs::absolute(dir, aec).lexically_normal();
    if (!aec && !abs.has_filename() && abs.has_relative_path()) abs = abs.parent_path();  // a trailing separator
    if (!aec) {
        const stdfs::path target = extended_path(abs);
        std::uintmax_t removed = stdfs::remove_all(target, ec);
        if (ec == std::errc::permission_denied) {
            // A read-only file (copy_file keeps the attribute: a previous export of a read-only player) refuses a
            // delete with ERROR_ACCESS_DENIED: drop the attribute of what is left and try once more.
            std::error_code wec;
            for (auto it = stdfs::recursive_directory_iterator(target, wec); !wec && it != stdfs::recursive_directory_iterator();
                 it.increment(wec)) {
                std::error_code pec;
                if (!it->is_symlink(pec) && it->is_regular_file(pec))
                    stdfs::permissions(it->path(), stdfs::perms::owner_write, stdfs::perm_options::add, pec);
            }
            ec.clear();
            removed = stdfs::remove_all(target, ec);  // the first call's count is -1 on an error, like this one's
        }
        return removed;
    }
#endif
    const std::uintmax_t removed = stdfs::remove_all(dir, ec);
    if (!ec) forget_deleted(dir);  // the emulation: what was open with delete shared went with it
    return removed;
}

bool file_in_use(const stdfs::path& file, bool* markLost) {
    if (markLost) *markLost = false;
    if (open_conflict(file, Change::Delete)) return true;  // the emulation
#ifdef _WIN32
    // A scanner or indexer that opened the file a moment ago lets go within milliseconds (as replace_file waits for):
    // only a file still held after about a second is in use. A running game holds its files for as long as it runs.
    for (int i = 0; i < 100; ++i) {
        const detail::Held held = detail::held_open(file);
        if (held == detail::Held::MarkLost) {
            if (markLost) *markLost = true;
            return true;
        }
        if (held == detail::Held::No) return false;
        retry_pause(i);
    }
    return true;
#else
    return false;  // POSIX deletes and replaces open files
#endif
}

stdfs::path find_file_in_use(const stdfs::path& dir, const std::function<bool(const stdfs::path&, bool)>& which,
                             std::size_t maxFiles, bool* markLost) {
    if (markLost) *markLost = false;
#ifndef _WIN32
    if (!emulating()) return {};  // POSIX deletes and replaces open files
#endif
    std::error_code ec;
    const stdfs::path root = os_path(dir);
    const auto status = stdfs::symlink_status(root, ec);
    if (ec || !stdfs::exists(status)) return {};
    if (!stdfs::is_directory(status)) return file_in_use(dir, markLost) ? dir : stdfs::path();
    std::size_t looked = 0;
    for (auto it = stdfs::recursive_directory_iterator(root, stdfs::directory_options::skip_permission_denied, ec);
         !ec && it != stdfs::recursive_directory_iterator() && looked < maxFiles; it.increment(ec)) {
        std::error_code tec;
        if (it->is_symlink(tec)) continue;
        const bool folder = it->is_directory(tec);
        const stdfs::path rel = it->path().lexically_relative(root);
        if (which && !which(rel, folder)) {
            if (folder) it.disable_recursion_pending();
            continue;
        }
        if (folder) continue;
        ++looked;
        if (file_in_use(it->path(), markLost)) return dir / rel;
    }
    return {};
}

// ---- Windows file rules: public part -----------------------------------------------------------------------------
bool windows_rules() {
#ifdef _WIN32
    return true;
#else
    return emulating();
#endif
}

void set_windows_rules(bool on) {
#ifndef _WIN32
    g_emulate.store(on ? 1 : 0);
#else
    (void)on;
#endif
}

bool is_sharing_violation(const std::error_code& ec) {
    if (!ec) return false;
    if (ec.category() == rules_category()) return true;
#ifdef _WIN32
    const int code = ec.value();  // ERROR_ACCESS_DENIED, ERROR_SHARING_VIOLATION, ERROR_LOCK_VIOLATION, ERROR_USER_MAPPED_FILE
    return code == 5 || code == 32 || code == 33 || code == 1224;
#else
    return false;
#endif
}

namespace detail {
std::string register_open_file(const stdfs::path& file, bool sharesDelete) {
    if (!emulating()) return {};
    const std::string key = registry_key(file);
    OpenFiles& o = open_files();
    std::lock_guard<std::mutex> lock(o.mutex);
    return add_holder(o, key, sharesDelete);
}

void unregister_open_file(const std::string& token, bool sharesDelete) {
    if (token.empty()) return;
    const std::size_t cut = token.rfind('\n');
    if (cut == std::string::npos) return;
    const std::string key = token.substr(0, cut);
    const std::string generation = token.substr(cut + 1);
    OpenFiles& o = open_files();
    std::lock_guard<std::mutex> lock(o.mutex);
    auto it = o.counts.find(key);
    // Gone or another generation: the file was deleted under the handle (forget_deleted), which held nothing since.
    if (it == o.counts.end() || std::to_string(it->second.generation) != generation) return;
    --it->second.all;
    if (!sharesDelete) --it->second.noDelete;
    if (it->second.all <= 0) o.counts.erase(it);
}
}  // namespace detail

ReadStream::ReadStream(const stdfs::path& file, std::ios_base::openmode mode) { open(file, mode); }

ReadStream::~ReadStream() {
    std::ifstream::close();  // let go of the file before the registry says so
    unregister();
}

void ReadStream::open(const stdfs::path& file, std::ios_base::openmode mode) {
    close();
    // Registered before the open, so the file is never open and unknown to the registry at once.
    if (emulating()) {
        const std::string key = registry_key(file);
        OpenFiles& o = open_files();
        std::lock_guard<std::mutex> lock(o.mutex);
        // A std::ifstream does not share delete (MSVC opens it with _SH_DENYNO: read and write only).
        registered_ = add_holder(o, key, /*sharesDelete=*/false);
    }
    std::ifstream::open(file, mode);
    if (!std::ifstream::is_open()) unregister();
}

void ReadStream::close() {
    std::ifstream::close();
    unregister();
}

void ReadStream::unregister() {
    if (registered_.empty()) return;
    detail::unregister_open_file(registered_, /*sharesDelete=*/false);
    registered_.clear();
}

void replace_file(const stdfs::path& from, const stdfs::path& to, std::error_code& ec) {
    auto attempt = [&] {
        ec = open_conflict(from, Change::Replace);
        if (!ec) ec = open_conflict(to, Change::Replace);
        if (!ec) stdfs::rename(from, to, ec);
    };
    std::error_code ignored;
    const bool toIsDir = stdfs::is_directory(to, ignored);  // renaming onto a folder never works: do not wait for it
    attempt();
    // Windows refuses to replace a file that is open somewhere else (a reader without FILE_SHARE_DELETE, as every
    // std::ifstream is: another thread polling the file, an antivirus scan). Such readers let go within milliseconds:
    // try again for up to about a second before giving up, or a write racing a read is lost.
    for (int i = 0; ec && !toIsDir && is_sharing_violation(ec) && i < 100; ++i) {
        retry_pause(i);
        attempt();
    }
}

bool remove_file(const stdfs::path& file, std::error_code& ec) {
    bool removed = false;
    auto attempt = [&] {
        ec = open_conflict(file, Change::Delete);
        removed = ec ? false : stdfs::remove(file, ec);
        if (removed) forget_deleted(file);
    };
    attempt();
    for (int i = 0; ec && is_sharing_violation(ec) && i < 100; ++i) {
        retry_pause(i);
        attempt();
    }
    return removed;
}

namespace {
bool is_same_or_below(std::string_view path, std::string_view folder) {
    return path == folder || (path.size() > folder.size() && path.substr(0, folder.size()) == folder && path[folder.size()] == '/');
}
}  // namespace

bool is_scratch_path(std::string_view relativePath) { return is_same_or_below(relativePath, kScratchDir); }

bool is_managed_path(std::string_view relativePath) {
    if (is_scratch_path(relativePath)) return false;
    return is_same_or_below(relativePath, ".factoria") || is_same_or_below(relativePath, ".git");
}

Result<void> check_writable(std::string_view path) {
    auto n = normalize_checked(path);
    if (!n) return n.error();
    std::string rel = n.value();
    if (is_absolute(rel)) {
        // Only an absolute path that lands inside the project can be judged by its project-relative form.
        stdfs::path r = stdfs::path(rel).lexically_relative(project_root());
        std::string g = r.generic_string();
        if (r.empty() || g == ".." || g.rfind("../", 0) == 0) return {};
        rel = g;
    }
    if (!is_managed_path(rel)) return {};
    return make_error("'" + std::string(path) + "' is inside " + (is_same_or_below(rel, ".factoria") ? ".factoria/" : "the version-control folder") +
                          ", which is managed by the engine and its tools",
                      std::string("Write scratch files to '") + kScratchDir + "/' (commands may create and delete files there), "
                      "or to a normal project folder such as scenes/ or assets/.");
}

// ---- resolve_for_write: the one place where a path a caller gives to a command that writes is confined ------------------
namespace {

#if defined(_WIN32) || (defined(__APPLE__) && !TARGET_OS_IPHONE)
constexpr bool kCaseInsensitiveVolumes = true;  // the default volumes of Windows and macOS ignore case
#else
constexpr bool kCaseInsensitiveVolumes = false;
#endif

// A simple case fold: ASCII, Latin-1, Latin Extended-A, Greek and Cyrillic, which covers the names of game folders.
char32_t fold_code_point(char32_t c) {
    if (c >= 'A' && c <= 'Z') return c + 32;
    if (c < 0xC0) return c;
    if (c <= 0xDE) return c == 0xD7 ? c : c + 32;
    if (c >= 0x100 && c <= 0x17F) {
        if (c == 0x130 || c == 0x131 || c == 0x138 || c == 0x149 || c == 0x178 || c == 0x17F) return c;
        const bool evenUpper = (c >= 0x100 && c <= 0x137) || (c >= 0x14A && c <= 0x177);
        const bool oddUpper = (c >= 0x139 && c <= 0x148) || (c >= 0x179 && c <= 0x17E);
        if (evenUpper && (c & 1) == 0) return c + 1;
        if (oddUpper && (c & 1) == 1) return c + 1;
        return c;
    }
    if (c >= 0x391 && c <= 0x3A9 && c != 0x3A2) return c + 32;
    if (c >= 0x410 && c <= 0x42F) return c + 32;
    if (c >= 0x400 && c <= 0x40F) return c + 80;
    return c;
}

// UTF-8 text, decoded and case-folded (the comparison of names on Windows and macOS).
std::u32string name_key(const std::string& utf8) {
    std::u32string out = utf8_decode(utf8);
    for (char32_t& c : out) c = fold_code_point(c);
    return out;
}

// What a path element is compared by. Where volumes ignore case: its text, decoded and folded. Where they do not (Linux): its
// bytes as they are, one code each, because a name need not be UTF-8 and decoding would turn every invalid byte into the
// same U+FFFD (so two different folders would compare equal).
std::u32string element_key(const stdfs::path& part) {
    if constexpr (kCaseInsensitiveVolumes) {
        return name_key(path_to_utf8(part));
    } else {
        std::u32string out;
        for (const auto ch : part.native())
            out.push_back(static_cast<char32_t>(static_cast<std::make_unsigned_t<std::decay_t<decltype(ch)>>>(ch)));
        return out;
    }
}

std::vector<std::u32string> element_keys(const stdfs::path& p) {
    std::vector<std::u32string> keys;
    for (const stdfs::path& part : p) {
        std::u32string key = element_key(part);
        if (!key.empty()) keys.push_back(std::move(key));
    }
    return keys;
}

// A symbolic link, or on MSVC a junction (a directory link that is_symlink does not report).
bool is_link_status(const stdfs::file_status& st) {
#ifdef _MSC_VER
    if (st.type() == stdfs::file_type::junction) return true;
#endif
    return stdfs::is_symlink(st);
}

// True when `p` is `root` or below it, element by element (so "/a/bc" is not under "/a/b"). `rootElements` receives how many
// elements of `p` the root takes.
bool is_under_root(const stdfs::path& root, const stdfs::path& p, std::size_t* rootElements = nullptr) {
    const auto r = element_keys(root);
    const auto q = element_keys(p);
    if (rootElements) *rootElements = r.size();
    if (q.size() < r.size()) return false;
    return std::equal(r.begin(), r.end(), q.begin());
}

// The path without the \\?\ (or \\?\UNC\) prefix that weakly_canonical and os_path may give a long Windows path.
stdfs::path plain_path(const stdfs::path& p) {
#ifdef _WIN32
    const std::wstring& n = p.native();
    if (n.rfind(LR"(\\?\UNC\)", 0) == 0) return stdfs::path(L"\\\\" + n.substr(8));
    if (n.rfind(LR"(\\?\)", 0) == 0 && n.size() > 6 && n[5] == L':') return stdfs::path(n.substr(4));
#endif
    return p;
}

// Absolute and canonical (symlinks of the existing part resolved), without the \\?\ prefix. `ec` is set when it cannot be done.
stdfs::path canonical_of(const stdfs::path& p, std::error_code& ec) {
    stdfs::path abs = stdfs::absolute(os_path(p), ec);
    if (ec) return {};
    return plain_path(stdfs::weakly_canonical(os_path(abs), ec));
}

enum class PathForm { Relative, Rooted, Drive, DriveRelative, Unc, LongPath, DevicePath, Home };

// `g` has forward slashes only.
PathForm classify_path(const std::string& g) {
    if (g.empty()) return PathForm::Relative;
    if (g[0] == '~') return PathForm::Home;
    if (g.compare(0, 4, "//?/") == 0) return PathForm::LongPath;
    if (g.compare(0, 4, "//./") == 0) return PathForm::DevicePath;
    if (g.compare(0, 2, "//") == 0) return PathForm::Unc;
    if (g[0] == '/') return PathForm::Rooted;
    if (g.size() >= 2 && g[1] == ':') return g.size() >= 3 && g[2] == '/' ? PathForm::Drive : PathForm::DriveRelative;
    return PathForm::Relative;
}

const char* form_name(PathForm f) {
    switch (f) {
        case PathForm::Relative: return "a relative path";
        case PathForm::Rooted: return "an absolute path";
        case PathForm::Drive: return "an absolute Windows path with a drive letter";
        case PathForm::DriveRelative: return "a drive-relative Windows path (C:name)";
        case PathForm::Unc: return "a network (UNC) path";
        case PathForm::LongPath: return "a Windows long path (\\\\?\\)";
        case PathForm::DevicePath: return "a Windows device path (\\\\.\\)";
        case PathForm::Home: return "a path starting with ~";
    }
    return "a path";
}

const char* root_label(WriteRoot r) {
    switch (r) {
        case WriteRoot::Project: return "project folder";
        case WriteRoot::Save: return "save folder";
        case WriteRoot::Export: return "export folder";
    }
    return "folder";
}

Error write_error(const char* code, const std::string& message, const std::string& hint) {
    return Error{message + " (code: " + code + ")", hint};
}

stdfs::path write_root_dir(WriteRoot r) {
    switch (r) {
        case WriteRoot::Project: return project_root();
        case WriteRoot::Save: return user_dir();
        case WriteRoot::Export: return export_dir();
    }
    return project_root();
}

// The error for a path inside a managed folder of the project (the version-control folder, `.factoria/` except its scratch
// folder), or nullopt. `canon` is canonical and below `projectCanon`, whose `projectCount` elements it starts with.
std::optional<Error> managed_denial(const stdfs::path& projectCanon, const stdfs::path& canon, std::size_t projectCount) {
    std::string rel;
    std::size_t index = 0;
    for (const stdfs::path& part : canon) {
        const std::string t = path_to_utf8(part);
        if (t.empty() || index++ < projectCount) continue;
        rel += (rel.empty() ? "" : "/") + t;
    }
    if (rel.empty()) return std::nullopt;
    // Judged with case folded on every platform: a Linux folder can sit on a volume that ignores case (WSL's /mnt/c, ext4
    // casefold, SMB), where ".GIT" is the version-control folder too.
    std::string folded;
    for (char32_t c : name_key(rel)) utf8_append(folded, c);
    if (auto w = check_writable(folded); !w.ok())
        return write_error("managed_path_denied",
                           replace_all(w.error().message, folded, rel) + " (the project folder is " + path_to_utf8(projectCanon) + ")",
                           w.error().hint);
    return std::nullopt;
}

// Why a name cannot be part of a path that is written into a project, or empty. A project must stay portable: Windows cannot
// create a file named like a device (CON, NUL, COM1... with or without an extension) or ending in a dot or a space, and strips
// that dot or space, so the file would land under another name. Refused on every platform.
std::string unportable_name(const std::string& seg) {
    if (seg.empty()) return {};
    if (seg.back() == '.' || seg.back() == ' ') return "ends in a '" + std::string(1, seg.back()) + "'";
    std::string stem = to_lower(seg.substr(0, seg.find('.')));
    while (!stem.empty() && stem.back() == ' ') stem.pop_back();
    static const char* const devices[] = {"con", "prn", "aux", "nul"};
    for (const char* d : devices)
        if (stem == d) return "is the name of a Windows device";
    if (stem.size() == 4 && (stem.compare(0, 3, "com") == 0 || stem.compare(0, 3, "lpt") == 0) && stem[3] >= '1' && stem[3] <= '9')
        return "is the name of a Windows device";
    return {};
}

}  // namespace

std::string_view path_error_code(const Error& error) {
    const std::string& m = error.message;
    constexpr std::string_view tag = " (code: ";
    const std::size_t at = m.rfind(tag);
    if (at == std::string::npos || m.back() != ')') return {};
    return std::string_view(m).substr(at + tag.size(), m.size() - at - tag.size() - 1);
}

Result<stdfs::path> resolve_for_write_in(const stdfs::path& rootDir, WriteRoot root, std::string_view path, bool allowAnywhere,
                                         ManagedFolders managed) {
    const std::string given(path);
    if (given.find('\0') != std::string::npos)
        return write_error("invalid_path", "The path '" + replace_all(given, std::string(1, '\0'), "\\0") + "' contains a NUL character",
                           "A path is text without NUL characters; check where the path was built.");
    const std::string label = root_label(root);
    std::string g = replace_all(given, "\\", "/");
    if (g.empty()) g = ".";

    std::error_code ec;
    const stdfs::path rootCanon = canonical_of(rootDir, ec);
    if (ec) {
        return write_error("path_unresolvable", "Cannot resolve the " + label + " '" + path_to_utf8(rootDir) + "': " + ec.message(),
                           "Check that the folder is reachable.");
    }
    const std::string rootText = path_to_utf8(rootCanon);
    const std::string where = " (" + label + ": " + rootText + ")";

    PathForm form = classify_path(g);
    if (form != PathForm::Relative && !allowAnywhere) {
        std::string hint = "Give a path relative to the " + label + " (" + rootText + "), such as \"" +
                           (root == WriteRoot::Project ? "assets/out.png" : "out.png") +
                           "\". An absolute path is only accepted from a caller that may write anywhere, such as the command line.";
        // An absolute path that points into the folder: say its relative spelling.
#ifdef _WIN32
        if (form == PathForm::Rooted || form == PathForm::Drive) {
#else
        if (form == PathForm::Rooted) {
#endif
            std::error_code aec;
            const stdfs::path abs = canonical_of(path_from_utf8(g), aec);
            std::size_t n = 0;
            if (!aec && is_under_root(rootCanon, abs, &n) && n < element_keys(abs).size()) {
                std::string rel;
                std::size_t i = 0;
                for (const stdfs::path& part : abs) {
                    const std::string t = path_to_utf8(part);
                    if (t.empty() || i++ < n) continue;
                    rel += (rel.empty() ? "" : "/") + t;
                }
                hint = "This path is inside the " + label + "; write it relative to it: \"" + rel + "\".";
            }
        }
        return write_error("absolute_path_denied",
                           "Path '" + given + "' is " + form_name(form) + ", which this command does not accept" + where,
                           hint);
    }

    // ---- relative: confined to the root -------------------------------------------------------------------------------
    if (form == PathForm::Relative) {
        std::vector<std::string> out;
        for (const std::string& seg : split(g, '/')) {
            if (seg == ".") continue;
            if (seg == "..") {
                if (!out.empty()) { out.pop_back(); continue; }
                return write_error("path_outside_root", "Path '" + given + "' is " + form_name(form) + " that escapes the " + label + where,
                                   "Remove the leading \"..\" segments: the path must stay inside the " + label +
                                   " (\"a/../b\" is fine, \"../b\" is not).");
            }
            out.push_back(seg);
        }
        // What is left of "a/../C:/x" must not name a drive, and on Windows no segment may hold a ':' (a drive, or an
        // alternate data stream "name:stream"): the path would leave the root or write somewhere that is not a file.
        for (std::size_t i = 0; i < out.size(); ++i) {
            const std::string& seg = out[i];
            const bool drive = i == 0 && seg.size() >= 2 && seg[1] == ':' && std::isalpha(static_cast<unsigned char>(seg[0]));
            bool colon = false;
#ifdef _WIN32
            colon = seg.find(':') != std::string::npos;
#endif
            if (drive || colon)
                return write_error("invalid_path", "Path '" + given + "' has the segment '" + seg + "', which names a drive or a stream" + where,
                                   "Remove the ':' from the name: a relative path is a list of folder and file names.");
            if (std::string why = unportable_name(seg); !why.empty())
                return write_error("invalid_path", "Path '" + given + "' has the name '" + seg + "', which " + why + where,
                                   "Rename it: the project has to work on Windows too (no CON, PRN, AUX, NUL, COM1-9, LPT1-9, and no name ending in a dot or a space).");
        }
        stdfs::path full = rootCanon;
        if (!out.empty()) full /= path_from_utf8(fa::join(out, "/"));
        stdfs::path canon = canonical_of(full, ec);
        if (ec) return write_error("path_unresolvable", "Cannot resolve path '" + given + "': " + ec.message(), "Check the path for invalid characters.");
        std::size_t rootCount = 0;
        if (!is_under_root(rootCanon, canon, &rootCount)) {
            return write_error("path_outside_root", "Path '" + given + "' resolves outside the " + label + " (a symbolic link leads out of it?)" + where,
                               "Only files physically inside the " + label + " can be written; remove or replace the link.");
        }
        // The managed folders of the project, judged on the canonical path (so a link into them counts).
        if (root == WriteRoot::Project && managed == ManagedFolders::Refuse) {
            if (auto denied = managed_denial(rootCanon, canon, rootCount)) return *denied;
        }
        // A symbolic link that points nowhere is not resolved by weakly_canonical, but writing through it would create the
        // file at its target: refuse every link left in the part below the root.
        stdfs::path walk = rootCanon;
        std::size_t index = 0;
        for (const stdfs::path& part : canon) {
            if (part.empty() || index++ < rootCount) continue;
            walk /= part;
            std::error_code sec;
            if (is_link_status(stdfs::symlink_status(os_path(walk), sec)))
                return write_error("path_outside_root", "Path '" + given + "' goes through a symbolic link that points nowhere" + where,
                                   "Delete the broken link '" + path_to_utf8(walk) + "' or write to another path.");
        }
        return canon;
    }

    // ---- absolute, from a caller that may write anywhere ----------------------------------------------------------------
    if (form == PathForm::Home) {
#ifdef _WIN32
        const stdfs::path home = env_path("USERPROFILE", L"USERPROFILE");
#else
        const stdfs::path home = env_path("HOME", L"HOME");
#endif
        if (!(g.size() == 1 || g[1] == '/'))
            return write_error("invalid_path", "Path '" + given + "' uses the ~user form, which is not supported",
                               "Write ~/name for your own home folder, or the full path.");
        if (home.empty())
            return write_error("path_unresolvable", "Path '" + given + "' starts with ~ but this process has no home folder",
                               "Write the full absolute path.");
        g = path_to_utf8(home) + g.substr(1);
        form = classify_path(g);
        if (form == PathForm::Relative || form == PathForm::Home)
            return write_error("path_unresolvable", "The home folder of this process is not an absolute path", "Write the full absolute path.");
    }
    if (form == PathForm::DriveRelative)
        return write_error("invalid_path", "Path '" + given + "' is " + form_name(form) + ", which depends on the current folder of that drive",
                           "Write the drive's full path, such as C:\\folder\\name.");
    if (form == PathForm::DevicePath)
        return write_error("invalid_path", "Path '" + given + "' is " + form_name(form) + ", which is not a file location",
                           "Write a normal path to a folder, such as C:\\folder\\name.");
    std::size_t keep = 0;  // path segments that belong to the root and no ".." may remove (server and share of a UNC path)
    std::string prefix;
    std::string body;
    if (form == PathForm::LongPath) {
        const std::string rest = g.substr(4);
        if (rest.compare(0, 4, "UNC/") == 0) { g = "//" + rest.substr(4); form = PathForm::Unc; }
        else if (rest.size() >= 3 && rest[1] == ':' && rest[2] == '/') { g = rest; form = PathForm::Drive; }
        else
            return write_error("invalid_path", "Path '" + given + "' is a Windows long path that names no drive or share",
                               "Write \\\\?\\C:\\folder\\name or an ordinary path.");
    }
#ifdef _WIN32
    if (form == PathForm::Unc) {
        // \\server\share needs both names: without a share it is not a place a file can be written to.
        const std::vector<std::string> names = split(g.substr(2), '/');
        if (names.size() < 2 || names[0].empty() || names[1].empty() || names[0] == "." || names[0] == ".." || names[1] == "." || names[1] == "..")
            return write_error("invalid_path", "Path '" + given + "' is a network (UNC) path without a share",
                               "Write \\\\server\\share\\folder\\name.");
        prefix = "//"; body = g.substr(2); keep = 2;
    }
    else if (form == PathForm::Drive) { prefix = g.substr(0, 2) + "/"; body = g.substr(2); }
    else { prefix = "/"; body = g; }
#else
    if (form == PathForm::Drive || form == PathForm::Unc)
        return write_error("invalid_path", "Path '" + given + "' is " + form_name(form) + ", which this system does not have",
                           "Write a path that starts with /.");
    prefix = "/";
    body = g;
#endif
    std::vector<std::string> out;
    for (const std::string& seg : split(body, '/')) {
        if (seg == ".") continue;
        if (seg == "..") {
            if (out.size() > keep) out.pop_back();  // ".." at the top stays there
            continue;
        }
        out.push_back(seg);
    }
    const stdfs::path canon = canonical_of(path_from_utf8(prefix + fa::join(out, "/")), ec);
    if (ec) return write_error("path_unresolvable", "Cannot resolve path '" + given + "': " + ec.message(), "Check the path for invalid characters.");

    // The managed folders of the project (the version-control folder and `.factoria/` except its scratch folder) stay closed
    // even to this caller. The save and export folders are exempt when they are inside them: they are what this call is for.
    if (managed == ManagedFolders::Refuse) {
        const stdfs::path projectCanon = root == WriteRoot::Project ? rootCanon : canonical_of(project_root(), ec);
        std::size_t projectCount = 0;
        if (!ec && is_under_root(projectCanon, canon, &projectCount) && (root == WriteRoot::Project || !is_under_root(rootCanon, canon))) {
            if (auto denied = managed_denial(projectCanon, canon, projectCount)) return *denied;
        }
    }
    return canon;
}

Result<stdfs::path> resolve_for_write(std::string_view path, WriteRoot root, bool allowAnywhere, ManagedFolders managed) {
    return resolve_for_write_in(write_root_dir(root), root, path, allowAnywhere, managed);
}

namespace {
Result<std::vector<std::uint8_t>> read_bytes_source(std::string_view path);
}

Result<std::vector<std::uint8_t>> read_bytes(std::string_view path) {
    auto n = normalize_checked(path);
    if (!n) return n.error();
    {
        std::unique_lock<std::mutex> lock(state().mutex);
        auto it = state().warm.find(n.value());
        if (it != state().warm.end()) {
            const std::int64_t warmModified = it->second.modified;
            std::vector<std::uint8_t> copy = *it->second.bytes;
            lock.unlock();
            // A file that changed on disk since it was read ahead is read again (hot reload, a tool that rewrote it).
            if (modified_time(n.value()) == warmModified) {
                if (!is_absolute(n.value())) LoadTrace::file_used(n.value());  // read ahead, used now (fa/core/load_trace.h)
                return copy;
            }
            lock.lock();
            state().warm.erase(n.value());
        }
    }
    {
        std::lock_guard<std::mutex> lock(state().mutex);
        state().diskReads++;
    }
    return read_bytes_source(path);
}

namespace {
std::string text_of(const std::vector<std::uint8_t>& b) {
    std::size_t skip = (b.size() >= 3 && b[0] == 0xEF && b[1] == 0xBB && b[2] == 0xBF) ? 3 : 0;  // UTF-8 BOM
    return std::string(reinterpret_cast<const char*>(b.data()) + skip, b.size() - skip);
}
}  // namespace

Result<void> warm(std::string_view path, std::string* text, std::uint64_t* size) {
    auto n = normalize_checked(path);
    if (!n) return n.error();
    // modified_time takes the fs mutex itself (pack_for): never call it while holding the lock.
    const std::int64_t modified = modified_time(n.value());
    {
        std::lock_guard<std::mutex> lock(state().mutex);
        auto it = state().warm.find(n.value());
        if (it != state().warm.end() && it->second.modified == modified) {
            if (text) *text = text_of(*it->second.bytes);
            if (size) *size = it->second.bytes->size();
            return {};
        }
    }
    {
        std::lock_guard<std::mutex> lock(state().mutex);
        state().diskReads++;
    }
    auto bytes = read_bytes_source(path);
    if (!bytes) return bytes.error();
    if (text) *text = text_of(bytes.value());
    if (size) *size = bytes.value().size();
    std::lock_guard<std::mutex> lock(state().mutex);
    state().warm[n.value()] = FsState::Warm{std::make_shared<const std::vector<std::uint8_t>>(std::move(bytes.value())), modified};
    return {};
}

bool is_warm(std::string_view path) {
    auto n = normalize_checked(path);
    if (!n) return false;
    std::lock_guard<std::mutex> lock(state().mutex);
    return state().warm.count(n.value()) > 0;
}

void unwarm(std::string_view path) {
    auto n = normalize_checked(path);
    if (!n) return;
    std::lock_guard<std::mutex> lock(state().mutex);
    state().warm.erase(n.value());
}

void unwarm_all() {
    std::lock_guard<std::mutex> lock(state().mutex);
    state().warm.clear();
}

std::uint64_t warm_bytes() {
    std::lock_guard<std::mutex> lock(state().mutex);
    std::uint64_t total = 0;
    for (const auto& [path, w] : state().warm) total += w.bytes->size();
    return total;
}

std::uint64_t disk_reads() {
    std::lock_guard<std::mutex> lock(state().mutex);
    return state().diskReads;
}

namespace {
Result<std::vector<std::uint8_t>> read_bytes_untraced(std::string_view path);

// A project-relative file read for the load trace (fa/core/load_trace.h); absolute paths are tools' files, not the game's.
void trace_read(const std::string& normalized, std::uint64_t bytes, std::int64_t startNs) {
    if (is_absolute(normalized)) return;
    std::uint64_t stored = bytes;
    bool fromPack = false;
    if (auto pack = pack_for(normalized)) {
        fromPack = true;
        const std::int64_t s = pack->stored_size_of(normalized);
        stored = s >= 0 ? std::uint64_t(s) : bytes;
    }
    LoadTrace::file_read(normalized, bytes, stored, fromPack, LoadTrace::now_ns() - startNs);
}

Result<std::vector<std::uint8_t>> read_bytes_source(std::string_view path) {
    if (!LoadTrace::any()) return read_bytes_untraced(path);
    const std::int64_t start = LoadTrace::now_ns();
    auto r = read_bytes_untraced(path);
    if (r.ok()) trace_read(normalize(path), r.value().size(), start);
    return r;
}

Result<std::vector<std::uint8_t>> read_bytes_untraced(std::string_view path) {
    auto n = normalize_checked(path);
    if (!n) return n.error();
    if (auto pack = pack_for(n.value())) {
        if (!pack->contains(n.value()) && !pack->is_directory(n.value())) return pack->not_found(path, n.value());
        return pack->read(n.value());  // a directory gets its own error from the pack
    }
    if (use_assets(n.value())) {
#ifdef __ANDROID__
        std::vector<std::uint8_t> data;
        if (detail::android_read(n.value(), data)) return data;
        return make_error("Asset not found in the APK: '" + n.value() + "'",
                          "Assets are packaged from the project folder at export time; re-export after adding files.");
#endif
    }
    stdfs::path full = resolve(path);
    const stdfs::path osFull = os_path(full);
    std::error_code ec;
    if (!stdfs::is_regular_file(osFull, ec)) {
        if (stdfs::is_directory(osFull, ec))
            return make_error("'" + std::string(path) + "' is a directory, not a file", "Use fs.list to see its contents.");
        return not_found_error(path, full);
    }
    ReadStream in(osFull, std::ios::binary);
    if (!in) return make_error("Cannot open '" + to_generic(full) + "' for reading", "Check file permissions.");
    in.seekg(0, std::ios::end);
    std::streamoff size = in.tellg();
    in.seekg(0, std::ios::beg);
    std::vector<std::uint8_t> data(size > 0 ? std::size_t(size) : 0);
    if (!data.empty()) in.read(reinterpret_cast<char*>(data.data()), size);
    if (!in && !data.empty()) return make_error("Failed while reading '" + to_generic(full) + "'");
    return data;
}
}  // namespace

FileView::FileView(std::vector<std::uint8_t> bytes) {
    auto owned = std::make_shared<const std::vector<std::uint8_t>>(std::move(bytes));
    data_ = owned->data();
    size_ = owned->size();
    owner_ = std::move(owned);
}

FileView::FileView(std::shared_ptr<const void> owner, const std::uint8_t* data, std::size_t size, bool mapped)
    : owner_(std::move(owner)), data_(data), size_(size), mapped_(mapped) {}

std::string_view FileView::text() const {
    const std::size_t skip = (size_ >= 3 && data_[0] == 0xEF && data_[1] == 0xBB && data_[2] == 0xBF) ? 3 : 0;  // UTF-8 BOM
    return size_ == 0 ? std::string_view() : std::string_view(reinterpret_cast<const char*>(data_) + skip, size_ - skip);
}

Result<FileView> read_view(std::string_view path) {
    auto n = normalize_checked(path);
    if (!n) return n.error();
    {
        std::unique_lock<std::mutex> lock(state().mutex);
        auto it = state().warm.find(n.value());
        if (it != state().warm.end()) {
            const std::int64_t warmModified = it->second.modified;
            std::shared_ptr<const std::vector<std::uint8_t>> shared = it->second.bytes;
            lock.unlock();
            if (modified_time(n.value()) == warmModified) {
                if (!is_absolute(n.value())) LoadTrace::file_used(n.value());  // read ahead, used now (fa/core/load_trace.h)
                return FileView(shared, shared->data(), shared->size(), true);
            }
            lock.lock();
            state().warm.erase(n.value());
        }
    }
    {
        std::lock_guard<std::mutex> lock(state().mutex);
        state().diskReads++;
    }
    const bool tracing = LoadTrace::any();
    const std::int64_t start = tracing ? LoadTrace::now_ns() : 0;
    if (auto pack = pack_for(n.value())) {
        if (!pack->contains(n.value()) && !pack->is_directory(n.value())) return pack->not_found(path, n.value());
        auto v = pack->view(n.value());
        if (tracing && v.ok()) trace_read(n.value(), v.value().size(), start);
        return v;
    }
#ifdef __ANDROID__
    if (use_assets(n.value())) {
        std::shared_ptr<const void> owner;
        const std::uint8_t* data = nullptr;
        std::size_t size = 0;
        if (detail::android_view(n.value(), owner, data, size)) {
            if (tracing) trace_read(n.value(), size, start);
            return FileView(std::move(owner), data, size, true);
        }
    }
#endif
    auto bytes = read_bytes_source(path);  // traces itself
    if (!bytes) return bytes.error();
    return FileView(std::move(bytes.value()));
}

Result<std::string> read_text(std::string_view path) {
    auto bytes = read_bytes(path);
    if (!bytes) return bytes.error();
    return text_of(bytes.value());
}

Result<void> write_bytes(std::string_view path, const void* data, std::size_t size) {
    auto n = normalize_checked(path);
    if (!n) return n.error();
    stdfs::path full = resolve(path);
    std::error_code ec;
    if (full.has_parent_path()) stdfs::create_directories(os_path(full.parent_path()), ec);
    if (ec) {
        return make_error("Cannot create directory '" + to_generic(full.parent_path()) + "': " + ec.message(),
                          "Check permissions; on mobile the project folder is read-only (write to fs::user_dir()).");
    }
    // Atomic: the bytes go to a temporary file next to the target, which then replaces it (rename replaces an existing
    // file on Windows and POSIX). A crash, a full disk or a reader never sees a half-written file, and on any failure the
    // original stays as it was. The ".fa-tmp" suffix matches no extension anything watches or lists.
    if (stdfs::is_symlink(os_path(full), ec)) {  // write through the link, as an in-place write would
        stdfs::path target = stdfs::canonical(os_path(full), ec);
        if (!ec) full = target;
    }
    static std::atomic<unsigned> counter{0};
#ifdef _WIN32
    const long long pid = _getpid();
#else
    const long long pid = static_cast<long long>(::getpid());
#endif
    stdfs::path tmp = full;
    tmp += ".fa-tmp" + std::to_string(pid) + "_" + std::to_string(counter++);
    const stdfs::path osFull = os_path(full), osTmp = os_path(tmp);
    {
        std::ofstream out(osTmp, std::ios::binary | std::ios::trunc);
        if (!out) {
            return make_error("Cannot open '" + to_generic(tmp) + "' for writing",
                              "Check permissions; on mobile the project folder is read-only (write to fs::user_dir()).");
        }
        if (size) out.write(static_cast<const char*>(data), std::streamsize(size));
        out.close();
        if (!out) {
            stdfs::remove(osTmp, ec);
            return make_error("Failed while writing '" + to_generic(full) + "'", "Is the disk full?");
        }
    }
    auto existing = stdfs::status(osFull, ec);  // keep the mode (executable bit, read-only) of the file being replaced
    if (stdfs::is_regular_file(existing)) stdfs::permissions(osTmp, existing.permissions(), ec);
    replace_file(osTmp, osFull, ec);  // waits for readers of the target (Windows rules)
    if (ec) {
        std::error_code ignored;
        stdfs::remove(osTmp, ignored);
        return make_error("Cannot replace '" + to_generic(full) + "': " + ec.message(),
                          "Is it a folder, read-only, or open in another program? The original file was left untouched.");
    }
    return {};
}

Result<void> write_text(std::string_view path, std::string_view text) {
    return write_bytes(path, text.data(), text.size());
}

bool exists(std::string_view path) {
    auto n = normalize_checked(path);
    if (!n) return false;
    if (auto pack = pack_for(n.value())) return pack->contains(n.value()) || pack->is_directory(n.value());
    if (use_assets(n.value())) {
#ifdef __ANDROID__
        return detail::android_exists(n.value());
#endif
    }
    std::error_code ec;
    return stdfs::exists(os_path(resolve(path)), ec);
}

bool is_directory(std::string_view path) {
    auto n = normalize_checked(path);
    if (!n) return false;
    if (auto pack = pack_for(n.value())) return pack->is_directory(n.value());
    if (use_assets(n.value())) {
#ifdef __ANDROID__
        return detail::android_is_directory(n.value());
#endif
    }
    std::error_code ec;
    return stdfs::is_directory(os_path(resolve(path)), ec);
}

std::int64_t file_size(std::string_view path) {
    auto n = normalize_checked(path);
    if (!n) return -1;
    if (auto pack = pack_for(n.value())) return pack->size_of(n.value());
    if (use_assets(n.value())) {
#ifdef __ANDROID__
        std::vector<std::uint8_t> data;  // an APK asset has no cheaper size query here
        return detail::android_read(n.value(), data) ? std::int64_t(data.size()) : -1;
#endif
    }
    std::error_code ec;
    const stdfs::path full = os_path(resolve(path));
    if (!stdfs::is_regular_file(full, ec)) return -1;
    const auto size = stdfs::file_size(full, ec);
    return ec ? -1 : std::int64_t(size);
}

std::int64_t file_time_ns(stdfs::file_time_type time) {
    using namespace std::chrono;
    using Clock = stdfs::file_time_type::clock;
#if defined(_MSC_VER)
    return duration_cast<nanoseconds>(time.time_since_epoch() - seconds(11644473600)).count();  // FILETIME counts from 1601
#else
    if constexpr (requires { Clock::to_sys(time); })
        return duration_cast<nanoseconds>(Clock::to_sys(time).time_since_epoch()).count();
    else
        return duration_cast<nanoseconds>(time.time_since_epoch()).count();
#endif
}

std::int64_t host_modified_time(const stdfs::path& file) {
    std::error_code ec;
    const auto t = stdfs::last_write_time(os_path(file), ec);
    if (ec) return -1;
    std::int64_t ns = file_time_ns(t);
    // Windows rule: a file's time moves in steps of 1/64 s (fs.h).
    if (emulating()) ns -= ((ns % kWindowsTimeStepNs) + kWindowsTimeStepNs) % kWindowsTimeStepNs;
    return ns;
}

std::int64_t modified_time(std::string_view path) {
    auto n = normalize_checked(path);
    if (!n) return -1;
    if (auto pack = pack_for(n.value())) return pack->contains(n.value()) || pack->is_directory(n.value()) ? pack->modified_time() : -1;
    if (use_assets(n.value())) return -1;
    return host_modified_time(resolve(path));
}

std::vector<std::string> list(std::string_view dir, bool recursive, std::string_view ext) {
    std::vector<std::string> out;
    auto n = normalize_checked(dir);
    if (!n) return out;
    std::string prefix = n.value();
    std::string wantExt = to_lower(ext);
    if (!wantExt.empty() && wantExt[0] != '.') wantExt.insert(0, ".");
    auto accept = [&](const std::string& p) { return wantExt.empty() || extension(p) == wantExt; };

    if (auto pack = pack_for(prefix)) {
        for (std::string& p : pack->list(prefix, recursive))
            if (accept(p)) out.push_back(std::move(p));
        return out;  // the pack's index is already sorted
    }
    if (use_assets(prefix)) {
#ifdef __ANDROID__
        for (std::string& p : detail::android_list(prefix, recursive))
            if (accept(p)) out.push_back(std::move(p));
        std::sort(out.begin(), out.end());
        return out;
#endif
    }
    stdfs::path base = resolve(dir);
    std::error_code ec;
    if (!stdfs::is_directory(base, ec)) return out;
    auto add = [&](const stdfs::directory_entry& entry) {
        std::error_code e2;
        if (!entry.is_regular_file(e2)) return;
        std::string rel = to_generic(entry.path().lexically_relative(base));
        std::string full = prefix.empty() ? rel : (prefix.back() == '/' ? prefix + rel : prefix + "/" + rel);
        if (accept(full)) out.push_back(std::move(full));
    };
    if (recursive) {
        for (auto it = stdfs::recursive_directory_iterator(base, stdfs::directory_options::skip_permission_denied, ec);
             it != stdfs::recursive_directory_iterator(); it.increment(ec)) {
            if (ec) break;
            add(*it);
        }
    } else {
        for (auto it = stdfs::directory_iterator(base, ec); it != stdfs::directory_iterator(); it.increment(ec)) {
            if (ec) break;
            add(*it);
        }
    }
    std::sort(out.begin(), out.end());
    return out;
}

std::string filename(std::string_view path) {
    std::size_t slash = path.find_last_of("/\\");
    return std::string(slash == std::string_view::npos ? path : path.substr(slash + 1));
}

std::string extension(std::string_view path) {
    std::string name = filename(path);
    std::size_t dot = name.find_last_of('.');
    if (dot == std::string::npos || dot == 0) return {};
    return to_lower(name.substr(dot));
}

std::string stem(std::string_view path) {
    std::string name = filename(path);
    std::size_t dot = name.find_last_of('.');
    if (dot == std::string::npos || dot == 0) return name;
    return name.substr(0, dot);
}

std::string parent(std::string_view path) {
    std::size_t slash = path.find_last_of("/\\");
    if (slash == std::string_view::npos) return {};
    if (slash == 0) return "/";
    return std::string(path.substr(0, slash));
}

std::string join(std::string_view a, std::string_view b) {
    if (a.empty()) return std::string(b);
    if (b.empty()) return std::string(a);
    if (is_absolute(b)) return std::string(b);
    while (!b.empty() && b.front() == '/') b.remove_prefix(1);
    if (a.back() == '/') return std::string(a) + std::string(b);
    return std::string(a) + "/" + std::string(b);
}

// ---------------------------------------------------------------- Watcher
int Watcher::watch(std::string path, Callback onChange) {
    std::int64_t mtime = modified_time(path);
    int id = nextId_++;
    entries_.push_back(Entry{id, std::move(path), mtime, std::move(onChange)});
    return id;
}

void Watcher::unwatch(int id) {
    entries_.erase(std::remove_if(entries_.begin(), entries_.end(), [&](const Entry& e) { return e.id == id; }),
                   entries_.end());
}

void Watcher::poll() {
    // Collect first: callbacks may watch/unwatch and invalidate iterators.
    std::vector<int> changed;
    for (Entry& e : entries_) {
        std::int64_t t = modified_time(e.path);
        if (t != e.mtime) {
            e.mtime = t;
            changed.push_back(e.id);
        }
    }
    for (int id : changed) {
        auto it = std::find_if(entries_.begin(), entries_.end(), [&](const Entry& e) { return e.id == id; });
        if (it == entries_.end()) continue;
        std::string path = it->path;
        Callback cb = it->cb;
        if (cb) cb(path);
    }
}

#ifndef __ANDROID__
void set_android_asset_manager(void*) {}
#endif

}  // namespace fa::fs
