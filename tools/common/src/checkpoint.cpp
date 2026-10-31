#include "fa/tooling/checkpoint.h"

#include <algorithm>
#include <chrono>
#include <ctime>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <map>
#include <mutex>
#include <set>

#include "fa/core/fs.h"
#include "fa/core/hash.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa {

namespace stdfs = std::filesystem;
using tooling_detail::arg_string;

namespace {

std::mutex g_mutex;  // the editor thread and an MCP call can both reach a checkpoint

constexpr const char* kCheckpointDir = ".factoria/checkpoints";
constexpr std::int64_t kSettleNs = 2'000'000'000;  // a file changed less than 2 s before it was hashed is hashed again

struct Entry {
    std::string hash;
    std::uint64_t size = 0;
};
using FileMap = std::map<std::string, Entry>;  // project-relative path -> content

struct CacheEntry {
    std::uint64_t size = 0;
    std::int64_t mtime = 0;
    std::string hash;
    bool settled = false;  // the mtime was old enough when hashed to trust size+mtime as "unchanged"
};

struct Manifest {
    CheckpointInfo info;
    std::int64_t seq = 0;
    FileMap files;
};

stdfs::path root_dir(const std::string& projectDir) { return stdfs::absolute(projectDir).lexically_normal(); }
stdfs::path store_dir(const std::string& projectDir) { return root_dir(projectDir) / kCheckpointDir; }
stdfs::path object_path(const stdfs::path& store, const std::string& hash) {
    return store / "objects" / hash.substr(0, 2) / hash;
}

// Same folders as scene.format / project.validate: hidden folders, node_modules and a top-level build/.
bool skipped_dir(const std::string& name, bool topLevel) {
    return name == "node_modules" || (topLevel && name == "build") || (!name.empty() && name[0] == '.');
}

// Writes through a temp file in the same folder + rename, so a crash never leaves half a file.
bool write_atomic(const stdfs::path& target, const void* data, std::size_t size, std::string* err) {
    std::error_code ec;
    stdfs::create_directories(target.parent_path(), ec);
    const stdfs::path tmp = target.parent_path() / (target.filename().string() + ".fa-tmp");
    // A stream opened with the path itself, not .string(): on Windows that would go through the ANSI code page.
    std::ofstream out(fs::os_path(tmp), std::ios::binary | std::ios::trunc);
    if (!out) {
        if (err) *err = "cannot write " + tmp.generic_string();
        return false;
    }
    if (size) out.write(static_cast<const char*>(data), static_cast<std::streamsize>(size));
    out.close();
    if (!out) {
        stdfs::remove(tmp, ec);
        if (err) *err = "cannot write " + tmp.generic_string() + " (disk full?)";
        return false;
    }
    stdfs::rename(tmp, target, ec);
    if (ec) {
        stdfs::remove(tmp, ec);
        if (err) *err = "cannot replace " + target.generic_string() + ": " + ec.message();
        return false;
    }
    return true;
}

bool read_bytes(const stdfs::path& p, std::string& out) {
    std::ifstream in(fs::os_path(p), std::ios::binary);
    if (!in) return false;
    out.assign(std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>());
    return !in.bad();
}

std::int64_t mtime_ns(const stdfs::path& p, std::error_code& ec) {
    return std::chrono::duration_cast<std::chrono::nanoseconds>(stdfs::last_write_time(p, ec).time_since_epoch()).count();
}

std::int64_t now_ns() {
    return std::chrono::duration_cast<std::chrono::nanoseconds>(stdfs::file_time_type::clock::now().time_since_epoch()).count();
}

// ---- stat cache --------------------------------------------------------------------------------------------------

std::map<std::string, CacheEntry> load_cache(const stdfs::path& store) {
    std::map<std::string, CacheEntry> out;
    auto text = tooling_detail::read_file(store / "stat-cache.json");
    if (!text) return out;
    Json j = Json::parse(*text, nullptr, false);
    if (!j.is_object()) return out;
    for (auto it = j.begin(); it != j.end(); ++it) {
        const Json& v = it.value();
        if (!v.is_object() || !v.contains("hash") || !v["hash"].is_string()) continue;
        CacheEntry e;
        e.size = v.value("size", std::uint64_t{0});
        e.mtime = v.value("mtime", std::int64_t{0});
        e.hash = v["hash"].get<std::string>();
        e.settled = v.value("settled", false);
        out[it.key()] = e;
    }
    return out;
}

void save_cache(const stdfs::path& store, const std::map<std::string, CacheEntry>& cache) {
    Json j = Json::object();
    for (const auto& [path, e] : cache)
        j[path] = Json::object({{"size", e.size}, {"mtime", e.mtime}, {"hash", e.hash}, {"settled", e.settled}});
    const std::string text = j.dump();
    write_atomic(store / "stat-cache.json", text.data(), text.size(), nullptr);
}

// ---- scanning the project -----------------------------------------------------------------------------------------

struct Scan {
    FileMap files;
    int hashed = 0;
    std::uint64_t bytesStored = 0;
    std::string error;
};

// Hashes every file of the project (using the stat cache) and, when `store` is true, copies the contents that
// objects/ does not hold yet.
Scan scan_project(const std::string& projectDir, bool store) {
    Scan scan;
    const stdfs::path root = root_dir(projectDir);
    const stdfs::path storeRoot = store_dir(projectDir);
    std::map<std::string, CacheEntry> cache = load_cache(storeRoot);
    std::map<std::string, CacheEntry> fresh;
    std::error_code ec;
    for (stdfs::recursive_directory_iterator it(root, ec), end; !ec && it != end; it.increment(ec)) {
        const stdfs::path& full = it->path();
        const std::string name = full.filename().string();
        std::error_code ec2;
        if (it->is_directory(ec2)) {
            const bool top = full.parent_path() == root;
            if (skipped_dir(name, top)) it.disable_recursion_pending();
            continue;
        }
        if (!it->is_regular_file(ec2)) continue;
        const std::string rel = stdfs::relative(full, root, ec2).generic_string();
        const std::uint64_t size = stdfs::file_size(full, ec2);
        if (ec2) continue;
        const std::int64_t mt = mtime_ns(full, ec2);
        if (ec2) continue;

        CacheEntry entry;
        std::string content;
        bool haveContent = false;
        auto cached = cache.find(rel);
        if (cached != cache.end() && cached->second.settled && cached->second.size == size && cached->second.mtime == mt) {
            entry = cached->second;
        } else {
            if (!read_bytes(full, content)) {
                scan.error = "cannot read '" + rel + "'";
                return scan;
            }
            haveContent = true;
            ++scan.hashed;
            entry.size = content.size();
            entry.mtime = mt;
            entry.hash = sha256_hex(content);
            entry.settled = now_ns() - mt > kSettleNs;
        }
        if (store && !stdfs::exists(object_path(storeRoot, entry.hash), ec2)) {
            if (!haveContent) {  // the cache said unchanged, but the object is gone: trust the bytes, not the cache
                if (!read_bytes(full, content)) {
                    scan.error = "cannot read '" + rel + "'";
                    return scan;
                }
                entry.hash = sha256_hex(content);
                entry.size = content.size();
                entry.settled = false;
                ++scan.hashed;
            }
            std::string err;
            if (!write_atomic(object_path(storeRoot, entry.hash), content.data(), content.size(), &err)) {
                scan.error = err;
                return scan;
            }
            scan.bytesStored += content.size();
        }
        fresh[rel] = entry;
        scan.files[rel] = {entry.hash, entry.size};
    }
    if (ec && scan.error.empty()) scan.error = "cannot list '" + root.generic_string() + "': " + ec.message();
    if (scan.error.empty()) save_cache(storeRoot, fresh);
    return scan;
}

// ---- manifests ----------------------------------------------------------------------------------------------------

Json manifest_json(const Manifest& m) {
    Json files = Json::object();
    for (const auto& [path, e] : m.files) files[path] = Json::object({{"hash", e.hash}, {"size", e.size}});
    return Json::object({{"id", m.info.id}, {"label", m.info.label}, {"created", m.info.created}, {"seq", m.seq}, {"files", files}});
}

bool load_manifest(const stdfs::path& file, Manifest& m) {
    auto text = tooling_detail::read_file(file);
    if (!text) return false;
    Json j = Json::parse(*text, nullptr, false);
    if (!j.is_object() || !j.contains("id") || !j["id"].is_string() || !j.contains("files") || !j["files"].is_object()) return false;
    m.info.id = j["id"].get<std::string>();
    m.info.label = j.value("label", std::string());
    m.info.created = j.value("created", std::int64_t{0});
    m.seq = j.value("seq", std::int64_t{0});
    m.files.clear();
    for (auto it = j["files"].begin(); it != j["files"].end(); ++it) {
        if (!it.value().is_object() || !it.value().contains("hash") || !it.value()["hash"].is_string()) continue;
        m.files[it.key()] = {it.value()["hash"].get<std::string>(), it.value().value("size", std::uint64_t{0})};
    }
    m.info.files = static_cast<int>(m.files.size());
    m.info.bytes = 0;
    for (const auto& [p, e] : m.files) m.info.bytes += e.size;
    return true;
}

std::vector<Manifest> load_all(const std::string& projectDir) {  // newest first
    std::vector<Manifest> out;
    std::error_code ec;
    for (stdfs::directory_iterator it(store_dir(projectDir), ec), end; !ec && it != end; it.increment(ec)) {
        if (it->path().extension() != ".json" || it->path().filename() == "stat-cache.json") continue;
        Manifest m;
        if (load_manifest(it->path(), m)) out.push_back(std::move(m));
    }
    std::sort(out.begin(), out.end(), [](const Manifest& a, const Manifest& b) {
        if (a.info.created != b.info.created) return a.info.created > b.info.created;
        return a.seq > b.seq;
    });
    return out;
}

// Keeps the newest kCheckpointLimit manifests (and `keepId`), then deletes the objects no manifest uses.
void prune(const std::string& projectDir, const std::string& keepId) {
    const stdfs::path store = store_dir(projectDir);
    std::error_code ec;
    int kept = 0;
    std::set<std::string> used;
    for (const Manifest& m : load_all(projectDir)) {
        if (kept < kCheckpointLimit || m.info.id == keepId) {
            ++kept;
            for (const auto& [p, e] : m.files) used.insert(e.hash);
        } else {
            stdfs::remove(store / (m.info.id + ".json"), ec);
        }
    }
    std::vector<stdfs::path> doomed;
    for (stdfs::recursive_directory_iterator it(store / "objects", ec), end; !ec && it != end; it.increment(ec)) {
        std::error_code ec2;
        if (it->is_regular_file(ec2) && !used.count(it->path().filename().string())) doomed.push_back(it->path());
    }
    for (const stdfs::path& p : doomed) stdfs::remove(p, ec);
    std::vector<stdfs::path> folders;
    for (stdfs::directory_iterator it(store / "objects", ec), end; !ec && it != end; it.increment(ec)) {
        std::error_code ec2;
        if (it->is_directory(ec2) && stdfs::is_empty(it->path(), ec2)) folders.push_back(it->path());
    }
    for (const stdfs::path& p : folders) stdfs::remove(p, ec);
}

std::string make_id(std::int64_t created, std::int64_t seq) {
    std::time_t t = static_cast<std::time_t>(created);
    std::tm tm{};
#if defined(_WIN32)
    gmtime_s(&tm, &t);
#else
    gmtime_r(&t, &tm);
#endif
    char buf[32];
    std::strftime(buf, sizeof buf, "%Y%m%d-%H%M%S", &tm);
    // The sequence number keeps ids unique even when several are made in one second and when old ones were pruned
    // (a chat that remembers an id must never find another checkpoint behind it).
    return std::string(buf) + "-" + std::to_string(seq);
}

CheckpointDiff diff_maps(const FileMap& then, const FileMap& now) {
    CheckpointDiff d;
    for (const auto& [path, e] : now) {
        auto it = then.find(path);
        if (it == then.end()) d.added.push_back(path);
        else if (it->second.hash != e.hash) d.modified.push_back(path);
    }
    for (const auto& [path, e] : then)
        if (!now.count(path)) d.deleted.push_back(path);
    return d;  // std::map iterates sorted
}

Error unknown_id(const std::string& projectDir, const std::string& id) {
    std::vector<std::string> ids;
    for (const Manifest& m : load_all(projectDir)) ids.push_back(m.info.id);
    if (ids.empty())
        return {"No checkpoint '" + id + "': this project has none yet.",
                "Make one with checkpoint.create (the editor makes one before every AI run)."};
    return {"No checkpoint '" + id + "'." + " " + did_you_mean(id, ids), "checkpoint.list shows the checkpoints that exist."};
}

bool find_manifest(const std::string& projectDir, const std::string& id, Manifest& out) {
    for (Manifest& m : load_all(projectDir))
        if (m.info.id == id) {
            out = std::move(m);
            return true;
        }
    return false;
}

Result<CheckpointCreated> create_locked(const std::string& projectDir, const std::string& label,
                                        const std::string& protectId = {}) {
    std::error_code ec;
    if (!stdfs::is_directory(root_dir(projectDir), ec))
        return Error{"Project folder '" + projectDir + "' does not exist.", "Pass the folder of a FactorIA project."};
    stdfs::create_directories(store_dir(projectDir) / "objects", ec);
    Scan scan = scan_project(projectDir, true);
    if (!scan.error.empty())
        return Error{"Cannot make a checkpoint: " + scan.error + ".", "Close whatever holds the file open and try again."};
    const std::vector<Manifest> existing = load_all(projectDir);
    Manifest m;
    m.info.created = std::chrono::duration_cast<std::chrono::seconds>(std::chrono::system_clock::now().time_since_epoch()).count();
    m.info.label = label;
    m.seq = existing.empty() ? 1 : std::max_element(existing.begin(), existing.end(), [](const Manifest& a, const Manifest& b) {
                                      return a.seq < b.seq;
                                  })->seq + 1;
    m.info.id = make_id(m.info.created, m.seq);
    m.files = std::move(scan.files);
    m.info.files = static_cast<int>(m.files.size());
    for (const auto& [p, e] : m.files) m.info.bytes += e.size;
    const std::string text = manifest_json(m).dump(2);
    std::string err;
    if (!write_atomic(store_dir(projectDir) / (m.info.id + ".json"), text.data(), text.size(), &err))
        return Error{"Cannot save the checkpoint: " + err + ".", "Check the disk space and the permissions of .factoria/checkpoints."};
    prune(projectDir, protectId);
    return CheckpointCreated{m.info, scan.bytesStored, scan.hashed};
}

bool safe_rel(const std::string& rel) {
    if (rel.empty() || fs::is_absolute(rel)) return false;
    const std::string n = fs::normalize(rel);
    return !n.empty() && n == rel;
}

}  // namespace

Result<CheckpointCreated> checkpoint_create(const std::string& projectDir, const std::string& label) {
    std::lock_guard<std::mutex> lock(g_mutex);
    return create_locked(projectDir, label);
}

std::vector<CheckpointInfo> checkpoint_list(const std::string& projectDir) {
    std::lock_guard<std::mutex> lock(g_mutex);
    std::vector<CheckpointInfo> out;
    for (const Manifest& m : load_all(projectDir)) out.push_back(m.info);
    return out;
}

Result<CheckpointDiff> checkpoint_diff(const std::string& projectDir, const std::string& id) {
    std::lock_guard<std::mutex> lock(g_mutex);
    Manifest m;
    if (!find_manifest(projectDir, id, m)) return unknown_id(projectDir, id);
    Scan scan = scan_project(projectDir, false);
    if (!scan.error.empty()) return Error{"Cannot compare with the checkpoint: " + scan.error + ".", "Close whatever holds the file open and try again."};
    return diff_maps(m.files, scan.files);
}

namespace {
Error unknown_path(const std::string& id, const std::string& path, const FileMap& files) {
    std::vector<std::string> names;
    for (const auto& [p, e] : files) names.push_back(p);
    return {"Checkpoint '" + id + "' holds no file '" + path + "'. " + did_you_mean(path, names),
            "Paths are relative to the project folder with forward slashes, e.g. scripts/player.js. checkpoint.diff {id} lists what changed since."};
}
}  // namespace

Result<std::string> checkpoint_read(const std::string& projectDir, const std::string& id, const std::string& path) {
    std::lock_guard<std::mutex> lock(g_mutex);
    Manifest m;
    if (!find_manifest(projectDir, id, m)) return unknown_id(projectDir, id);
    auto it = m.files.find(path);
    if (it == m.files.end()) return unknown_path(id, path, m.files);
    std::string bytes;
    if (!read_bytes(object_path(store_dir(projectDir), it->second.hash), bytes))
        return Error{"Checkpoint '" + id + "' is damaged: the saved content of '" + path + "' is missing from .factoria/checkpoints/objects.",
                     "Read the file from a different checkpoint (checkpoint.list)."};
    return bytes;
}

Result<std::vector<std::string>> checkpoint_files(const std::string& projectDir, const std::string& id) {
    std::lock_guard<std::mutex> lock(g_mutex);
    Manifest m;
    if (!find_manifest(projectDir, id, m)) return unknown_id(projectDir, id);
    std::vector<std::string> out;
    for (const auto& [p, e] : m.files) out.push_back(p);
    return out;
}

Result<CheckpointRestored> checkpoint_restore(const std::string& projectDir, const std::string& id,
                                              const std::optional<std::vector<std::string>>& only) {
    std::lock_guard<std::mutex> lock(g_mutex);
    Manifest target;
    if (!find_manifest(projectDir, id, target)) return unknown_id(projectDir, id);
    const stdfs::path root = root_dir(projectDir);
    const stdfs::path store = store_dir(projectDir);
    std::error_code ec;

    // Every object the restore needs must be there before anything on disk changes.
    Scan before = scan_project(projectDir, false);
    if (!before.error.empty()) return Error{"Cannot restore: " + before.error + ".", "Close whatever holds the file open and try again."};
    CheckpointDiff changes = diff_maps(target.files, before.files);
    if (only) {
        const std::set<std::string> wanted(only->begin(), only->end());
        for (std::vector<std::string>* list : {&changes.modified, &changes.added, &changes.deleted})
            std::erase_if(*list, [&](const std::string& rel) { return !wanted.contains(rel); });
    }
    std::vector<std::string> toWrite = changes.modified;
    toWrite.insert(toWrite.end(), changes.deleted.begin(), changes.deleted.end());
    for (const std::string& rel : toWrite) {
        if (!safe_rel(rel))
            return Error{"Checkpoint '" + id + "' lists the path '" + rel + "', which is not inside the project.",
                         "The manifest in .factoria/checkpoints was edited; delete it."};
        if (!stdfs::exists(object_path(store, target.files[rel].hash), ec))
            return Error{"Checkpoint '" + id + "' is damaged: the saved content of '" + rel + "' is missing from .factoria/checkpoints/objects.",
                         "Nothing was changed. Restore a different checkpoint (checkpoint.list)."};
    }

    // The automatic checkpoint that lets the user take this restore back.
    auto safety = create_locked(projectDir, "Before restoring " + target.info.label, id);
    if (!safety.ok()) return safety.error();

    for (const std::string& rel : toWrite) {
        std::string bytes;
        if (!read_bytes(object_path(store, target.files[rel].hash), bytes))
            return Error{"Cannot read the saved content of '" + rel + "'.", "Restore the safety checkpoint '" + safety.value().info.id + "' to undo the partial restore."};
        std::string err;
        if (!write_atomic(root / rel, bytes.data(), bytes.size(), &err))
            return Error{"Cannot restore '" + rel + "': " + err + ".", "Close whatever holds the file open and try again; the safety checkpoint '" +
                                                                         safety.value().info.id + "' holds the state before this restore."};
    }
    for (const std::string& rel : changes.added) {
        if (!safe_rel(rel)) continue;
        stdfs::remove(root / rel, ec);
        // Folders the AI made and that are empty now go with their files.
        for (stdfs::path dir = (root / rel).parent_path(); dir != root && dir.has_parent_path(); dir = dir.parent_path()) {
            if (!stdfs::is_empty(dir, ec) || ec) break;
            stdfs::remove(dir, ec);
        }
    }
    // The restore changed files; refresh the stat cache so a diff right after is exact.
    scan_project(projectDir, false);
    prune(projectDir, id);
    return CheckpointRestored{std::move(changes), safety.value().info.id};
}

// ---- commands ----------------------------------------------------------------------------------------------------

namespace {

Json info_json(const CheckpointInfo& i) {
    return Json::object({{"id", i.id}, {"label", i.label}, {"created", i.created}, {"files", i.files}, {"bytes", i.bytes}});
}

Json diff_json(const CheckpointDiff& d) {
    return Json::object({{"modified", d.modified}, {"added", d.added}, {"deleted", d.deleted}});
}

constexpr std::size_t kReadInlineLimit = 256 * 1024;  // bytes of a file checkpoint.read returns inline

// Text: no NUL byte and valid UTF-8 (a JSON string must hold only that).
bool is_text(const std::string& b) {
    std::size_t i = 0;
    const std::size_t n = b.size();
    while (i < n) {
        const unsigned char c = static_cast<unsigned char>(b[i]);
        if (c == 0) return false;
        std::size_t len = c < 0x80 ? 1 : (c >> 5) == 6 ? 2 : (c >> 4) == 14 ? 3 : (c >> 3) == 30 ? 4 : 0;
        if (len == 0 || i + len > n) return false;
        for (std::size_t k = 1; k < len; ++k)
            if ((static_cast<unsigned char>(b[i + k]) & 0xC0) != 0x80) return false;
        i += len;
    }
    return true;
}

[[noreturn]] void fail(const Error& e, const char* code = "failed") { throw CommandError(code, e.message, e.hint); }

}  // namespace

void register_checkpoint_commands(CommandRegistry& registry, const std::string& projectDir) {
    {
        CommandInfo c;
        c.name = "checkpoint.create";
        c.category = "project";
        c.readOnly = false;
        c.summary = "Save a checkpoint: a snapshot of every file of the project that checkpoint.restore can put back.";
        c.description =
            "Copies the project's files into .factoria/checkpoints (content-addressed: a file that did not change since an earlier checkpoint is not copied again, so the second checkpoint of a project is cheap). "
            "Includes scripts, scenes, tests and assets; skips folders starting with '.', node_modules and a top-level build/. Keeps the newest " + std::to_string(kCheckpointLimit) +
            " checkpoints. The editor makes one before every AI run (the Revert button of the AI Assistant), so call this yourself only before a risky change the user did not ask the editor to track. "
            "Returns {id, label, created (epoch seconds), files, bytes (size of the files), bytesStored (newly copied), filesHashed}. Example: {\"label\":\"before the refactor\"}.";
        c.inputSchema = Json::parse(R"({"type":"object","properties":{
            "label":{"type":"string","description":"A short name shown by checkpoint.list and the editor, e.g. \"before the refactor\"."}}})");
        registry.add(c, [projectDir](const Json& a) {
            auto r = checkpoint_create(projectDir, arg_string(a, "label", false, "Checkpoint"));
            if (!r.ok()) fail(r.error());
            Json j = info_json(r.value().info);
            j["bytesStored"] = r.value().bytesStored;
            j["filesHashed"] = r.value().filesHashed;
            return j;
        });
    }
    {
        CommandInfo c;
        c.name = "checkpoint.list";
        c.category = "project";
        c.readOnly = true;
        c.summary = "List the project's checkpoints, newest first.";
        c.description = "Returns {checkpoints: [{id, label, created (epoch seconds), files, bytes}], limit}. Only the newest `limit` checkpoints are kept.";
        registry.add(c, [projectDir](const Json&) {
            Json list = Json::array();
            for (const CheckpointInfo& i : checkpoint_list(projectDir)) list.push_back(info_json(i));
            return Json::object({{"checkpoints", list}, {"limit", kCheckpointLimit}});
        });
    }
    {
        CommandInfo c;
        c.name = "checkpoint.diff";
        c.category = "project";
        c.readOnly = true;
        c.summary = "Show which files changed since a checkpoint (modified, added, deleted).";
        c.description = "Compares the files now with checkpoint `id`. Returns {modified, added, deleted} (project-relative paths) and counts. Changes nothing. Example: {\"id\":\"20261022-153012-7\"}.";
        c.inputSchema = Json::parse(R"({"type":"object","required":["id"],"properties":{"id":{"type":"string","description":"A checkpoint id from checkpoint.list."}}})");
        registry.add(c, [projectDir](const Json& a) {
            auto r = checkpoint_diff(projectDir, arg_string(a, "id", true));
            if (!r.ok()) fail(r.error(), "not_found");
            Json j = diff_json(r.value());
            j["changed"] = r.value().modified.size() + r.value().added.size() + r.value().deleted.size();
            return j;
        });
    }
    {
        CommandInfo c;
        c.name = "checkpoint.read";
        c.category = "project";
        c.readOnly = false;  // with `out` it writes a file
        c.summary = "Read one file as it was at a checkpoint (text inline; a binary as base64 or into a file) without restoring anything.";
        c.description =
            "Returns the content `path` (project-relative, forward slashes) had at checkpoint `id`, so you can compare or copy one old file without checkpoint.restore touching the rest of the project. "
            "Text (valid UTF-8, no NUL bytes) comes back in `text` when it is at most " + std::to_string(kReadInlineLimit) + " bytes. "
            "A binary comes back as `base64` when it is at most " + std::to_string(kReadInlineLimit) + " bytes. "
            "Anything bigger, and any file when you pass `out`, is written to the project-relative path `out` instead (the folders are created, an existing file there is overwritten) and only {path, size, binary, out} is returned. "
            "`out` stays inside the project and cannot start with '.' folders or go through '..' (not into .factoria). "
            "Errors: an unknown id or a path the checkpoint does not hold fails with a \"did you mean\". "
            "Returns {id, path, size, binary, text | base64 | out}. Example: {\"id\":\"20261022-153012-7\",\"path\":\"scripts/player.js\"}.";
        c.inputSchema = Json::parse(R"({"type":"object","required":["id","path"],"properties":{
            "id":{"type":"string","description":"A checkpoint id from checkpoint.list."},
            "path":{"type":"string","description":"File to read, relative to the project folder, forward slashes: scripts/player.js."},
            "out":{"type":"string","description":"Write the file here (project-relative path) instead of returning its content; needed for files over the inline limit."}}})");
        registry.add(c, [projectDir](const Json& a) {
            const std::string id = arg_string(a, "id", true), path = arg_string(a, "path", true), out = arg_string(a, "out", false);
            if (!out.empty() && (!safe_rel(out) || out.rfind('.', 0) == 0 || out.find("/.") != std::string::npos))
                throw CommandError("invalid_argument", "`out` '" + out + "' is not a usable project-relative path.",
                                   "Use a path like exports/old_player.js: relative, forward slashes, no '..', no folder starting with '.'.");
            auto r = checkpoint_read(projectDir, id, path);
            if (!r.ok()) fail(r.error(), "not_found");
            const std::string& bytes = r.value();
            const bool binary = !is_text(bytes);
            Json j = Json::object({{"id", id}, {"path", path}, {"size", bytes.size()}, {"binary", binary}});
            if (!out.empty() || bytes.size() > kReadInlineLimit) {
                if (out.empty())
                    throw CommandError("too_large", "'" + path + "' is " + std::to_string(bytes.size()) + " bytes, over the inline limit of " + std::to_string(kReadInlineLimit) + ".",
                                       "Pass `out` (a project-relative path) and the file is written there.");
                std::string err;
                if (!write_atomic(root_dir(projectDir) / out, bytes.data(), bytes.size(), &err))
                    throw CommandError("failed", "Cannot write '" + out + "': " + err + ".", "Check the path and the permissions.");
                j["out"] = out;
            } else if (binary) {
                j["base64"] = base64_encode(bytes.data(), bytes.size());
            } else {
                j["text"] = bytes;
            }
            return j;
        });
    }
    {
        CommandInfo c;
        c.name = "checkpoint.restore";
        c.category = "project";
        c.readOnly = false;
        c.summary = "Put the project's files back as they were at a checkpoint (the user's Revert); ask the user before calling it.";
        c.description =
            "Writes back the files that were modified or deleted since checkpoint `id` and deletes the files added since (anything the user edited by hand in those files is lost). "
            "First it saves an automatic checkpoint \"Before restoring <label>\" and returns its id as safetyCheckpointId: restoring that one takes this restore back. "
            "Files are written through a temp file and a rename, so a crash never leaves half a file. This does NOT reload the scene open in the editor (the editor's Revert button does). "
            "With `paths` only those files are put back as the checkpoint had them (a file the checkpoint holds is written back, a file the checkpoint does not hold is deleted) and every other file of the project stays untouched; the same safety checkpoint is made first. "
            "A path that is neither in the checkpoint nor in the project fails with a \"did you mean\" before anything changes; a listed file that already equals the checkpoint is left alone. "
            "Returns {modified, added, deleted (what was done), safetyCheckpointId}. Examples: {\"id\":\"20261022-153012-7\"}, {\"id\":\"20261022-153012-7\",\"paths\":[\"scripts/player.js\"]}.";
        c.inputSchema = Json::parse(R"({"type":"object","required":["id"],"properties":{
            "id":{"type":"string","description":"A checkpoint id from checkpoint.list."},
            "paths":{"type":"array","items":{"type":"string"},"description":"Restore only these files (project-relative, forward slashes); the rest of the project is not touched."}}})");
        registry.add(c, [projectDir](const Json& a) {
            const std::string id = arg_string(a, "id", true);
            std::optional<std::vector<std::string>> only;
            if (a.contains("paths")) {
                if (!a["paths"].is_array() || a["paths"].empty())
                    throw CommandError("invalid_argument", "`paths` must be a non-empty array of project-relative file paths.",
                                       "Leave `paths` out to restore the whole project, or list files: [\"scripts/player.js\"].");
                auto files = checkpoint_files(projectDir, id);
                if (!files.ok()) fail(files.error(), "not_found");
                std::vector<std::string> list;
                for (const Json& p : a["paths"]) {
                    if (!p.is_string())
                        throw CommandError("invalid_argument", "`paths` must hold strings.", "Example: [\"scripts/player.js\"].");
                    const std::string path = p.get<std::string>();
                    const bool inCheckpoint = std::binary_search(files.value().begin(), files.value().end(), path);
                    std::error_code ec;
                    if (!safe_rel(path) || (!inCheckpoint && !stdfs::is_regular_file(root_dir(projectDir) / path, ec))) {
                        std::vector<std::string> near = files.value();
                        throw CommandError("not_found", "Neither checkpoint '" + id + "' nor the project holds a file '" + path + "'. " + did_you_mean(path, near),
                                           "Paths are relative to the project folder with forward slashes, e.g. scripts/player.js. checkpoint.diff {id} lists what changed.");
                    }
                    list.push_back(path);
                }
                only = std::move(list);
            }
            auto r = checkpoint_restore(projectDir, id, only);
            if (!r.ok()) fail(r.error(), "failed");
            Json j = diff_json(r.value().changes);
            j["safetyCheckpointId"] = r.value().safetyId;
            return j;
        });
    }
}

}  // namespace fa
