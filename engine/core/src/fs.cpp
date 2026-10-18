#include "fa/core/fs.h"

#include <algorithm>
#include <atomic>
#include <cctype>
#include <fstream>
#include <mutex>
#include <system_error>

#ifdef _WIN32
#include <process.h>
#else
#include <unistd.h>
#endif

#include "fa/core/pack.h"
#include "fa/core/strings.h"
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
    std::shared_ptr<const PackReader> pack;  // mount_pack
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
#endif

void set_user_dir(const stdfs::path& dir) {
    std::lock_guard<std::mutex> lock(state().mutex);
    state().userDir = dir;
    state().userDirSet = true;
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
    stdfs::remove_all(dir, ec);  // a leftover of an earlier process that had the same id
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

stdfs::path resolve(std::string_view path) {
    auto n = normalize_checked(path);
    if (!n) return {};
    if (is_absolute(n.value())) return stdfs::path(n.value());
    return project_root() / n.value();
}

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
    const std::wstring& a = abs.native();
    if (a.rfind(LR"(\\)", 0) == 0) return stdfs::path(LR"(\\?\UNC\)" + a.substr(2));  // \\server\share\...
    return stdfs::path(LR"(\\?\)" + a);
#else
    return p;
#endif
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

Result<std::vector<std::uint8_t>> read_bytes(std::string_view path) {
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
    std::ifstream in(osFull, std::ios::binary);
    if (!in) return make_error("Cannot open '" + to_generic(full) + "' for reading", "Check file permissions.");
    in.seekg(0, std::ios::end);
    std::streamoff size = in.tellg();
    in.seekg(0, std::ios::beg);
    std::vector<std::uint8_t> data(size > 0 ? std::size_t(size) : 0);
    if (!data.empty()) in.read(reinterpret_cast<char*>(data.data()), size);
    if (!in && !data.empty()) return make_error("Failed while reading '" + to_generic(full) + "'");
    return data;
}

Result<std::string> read_text(std::string_view path) {
    auto bytes = read_bytes(path);
    if (!bytes) return bytes.error();
    const auto& b = bytes.value();
    std::size_t skip = (b.size() >= 3 && b[0] == 0xEF && b[1] == 0xBB && b[2] == 0xBF) ? 3 : 0;  // UTF-8 BOM
    return std::string(reinterpret_cast<const char*>(b.data()) + skip, b.size() - skip);
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
    stdfs::rename(osTmp, osFull, ec);
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

std::int64_t modified_time(std::string_view path) {
    auto n = normalize_checked(path);
    if (!n) return -1;
    if (auto pack = pack_for(n.value())) return pack->contains(n.value()) || pack->is_directory(n.value()) ? pack->modified_time() : -1;
    if (use_assets(n.value())) return -1;
    std::error_code ec;
    auto t = stdfs::last_write_time(os_path(resolve(path)), ec);
    if (ec) return -1;
    return std::int64_t(t.time_since_epoch().count());
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
