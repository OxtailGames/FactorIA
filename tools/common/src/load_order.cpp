// The first-use order of a project's files (fa/tooling/load_order.h).
#include "fa/tooling/load_order.h"

#include <condition_variable>
#include <deque>
#include <mutex>
#include <thread>
#include <unordered_map>
#include <unordered_set>
#include <utility>

#include "fa/core/fs.h"
#include "fa/core/json.h"
#include "fa/core/log.h"
#include "fa/tooling/feedback_share.h"

namespace fa {

namespace stdfs = std::filesystem;

namespace {

stdfs::path cache_dir(const stdfs::path& projectDir) { return projectDir / ".factoria" / "cache"; }

// A project-relative path the engine reads: no absolute path, no "..", no backslash.
bool usable_path(const std::string& p) {
    if (p.empty() || p.size() > 4096 || p[0] == '/' || p.find('\\') != std::string::npos || (p.size() > 1 && p[1] == ':')) return false;
    std::size_t start = 0;
    while (start <= p.size()) {
        const std::size_t slash = std::min(p.find('/', start), p.size());
        if (p.compare(start, slash - start, "..") == 0 && slash - start == 2) return false;
        start = slash + 1;
    }
    return true;
}

Json to_json(const LoadOrder& order) {
    Json scenes = Json::array();
    for (const SceneFiles& s : order) scenes.push_back(Json::object({{"scene", s.scene}, {"files", s.files}}));
    return Json::object({{"format", kLoadOrderFormat}, {"scenes", std::move(scenes)}});
}

}  // namespace

stdfs::path load_order_file(const stdfs::path& projectDir) { return cache_dir(projectDir) / "load-order.json"; }

LoadOrder merge_load_order(LoadOrder recorded, const LoadOrder& seen, LoadOrderMerge* stats) {
    std::size_t total = 0;
    std::unordered_map<std::string, std::size_t> sceneAt;
    std::vector<std::unordered_set<std::string>> filesOf(recorded.size());
    for (std::size_t i = 0; i < recorded.size(); ++i) {
        sceneAt.emplace(recorded[i].scene, i);
        filesOf[i].insert(recorded[i].files.begin(), recorded[i].files.end());
        total += recorded[i].files.size();
    }
    std::size_t added = 0;
    for (const SceneFiles& s : seen) {
        if (s.scene.empty()) continue;
        auto it = sceneAt.find(s.scene);
        if (it == sceneAt.end()) {
            if (recorded.size() >= kLoadOrderMaxScenes) continue;
            it = sceneAt.emplace(s.scene, recorded.size()).first;
            recorded.push_back(SceneFiles{s.scene, {}});
            filesOf.emplace_back();
        }
        for (const std::string& f : s.files) {
            if (total >= kLoadOrderMaxFiles) break;
            if (!usable_path(f) || !filesOf[it->second].insert(f).second) continue;
            recorded[it->second].files.push_back(f);
            ++total;
            ++added;
        }
    }
    if (stats) *stats = LoadOrderMerge{recorded.size(), total, added};
    return recorded;
}

Result<LoadOrder> read_load_order(const stdfs::path& projectDir) {
    const stdfs::path file = load_order_file(projectDir);
    std::error_code ec;
    if (!stdfs::exists(fs::os_path(file), ec)) return LoadOrder{};
    const std::string where = fs::path_to_utf8(file);
    auto text = fs::read_text(where);
    if (!text.ok()) return text.error();
    auto parsed = parse_json(text.value(), where);
    if (!parsed.ok()) return parsed.error();
    const Json& j = parsed.value();
    const std::string fix = "It is a cache the play sessions write: delete it and play the game again (the editor's Play, factoria run or "
                            "play.auto) to record the order anew.";
    if (!j.is_object() || j.value("format", std::string()) != kLoadOrderFormat)
        return make_error(where + ": not a load order (\"format\" must be \"" + std::string(kLoadOrderFormat) + "\")", fix);
    auto sc = j.find("scenes");
    if (sc == j.end() || !sc->is_array()) return make_error(where + "#/scenes: expected an array of {scene, files}", fix);
    LoadOrder out;
    for (std::size_t i = 0; i < sc->size() && out.size() < kLoadOrderMaxScenes; ++i) {
        const Json& e = (*sc)[i];
        const std::string ptr = where + "#/scenes/" + std::to_string(i);
        if (!e.is_object()) return make_error(ptr + ": expected an object {scene, files}", fix);
        auto name = e.find("scene");
        auto files = e.find("files");
        if (name == e.end() || !name->is_string()) return make_error(ptr + "/scene: expected the scene's path as a string", fix);
        if (files == e.end() || !files->is_array()) return make_error(ptr + "/files: expected an array of paths", fix);
        SceneFiles s{name->get<std::string>(), {}};
        for (std::size_t k = 0; k < files->size(); ++k) {
            if (!(*files)[k].is_string())
                return make_error(ptr + "/files/" + std::to_string(k) + ": expected a project-relative path as a string", fix);
            s.files.push_back((*files)[k].get<std::string>());
        }
        out.push_back(std::move(s));
    }
    return merge_load_order({}, out);  // drops duplicates and unusable paths, applies the caps
}

namespace {

Result<LoadOrderMerge> record_with(const ShareEnv& env, const stdfs::path& projectDir, const LoadOrder& seen) {
    const stdfs::path dir = cache_dir(projectDir);
    ShareLock lock(env, dir);
    if (!lock.held()) {
        const std::string why = lock.error().empty() ? std::string("the lock is busy") : lock.error();
        return make_error("The load order of " + fs::path_to_utf8(projectDir) + " was not recorded: " + why,
                          lock.unwritable() ? "The project's .factoria/cache folder cannot be written: check its permissions. The order is a "
                                              "cache only, so the export packs by path until a session records it."
                                            : "Another FactorIA program is writing it now; the next play session records the order again.");
    }
    LoadOrder recorded;
    if (auto r = read_load_order(projectDir); r.ok()) {
        recorded = std::move(r.value());
    } else {
        FA_WARN("loadorder", "{} - it is replaced by the order of this session", r.error().message);
    }
    LoadOrderMerge stats;
    const LoadOrder merged = merge_load_order(std::move(recorded), seen, &stats);
    if (stats.added == 0) return stats;  // nothing new: the file stays as it is
    const std::string text = dump_json(to_json(merged)) + "\n";
    if (auto w = fs::write_bytes(fs::path_to_utf8(load_order_file(projectDir)), text.data(), text.size()); !w.ok())
        return make_error("The load order of " + fs::path_to_utf8(projectDir) + " was not recorded: " + w.error().message, w.error().hint);
    return stats;
}

void record_logged(const ShareEnv& env, const stdfs::path& projectDir, const LoadOrder& seen) {
    if (seen.empty()) return;
    if (auto r = record_with(env, projectDir, seen); !r.ok()) FA_WARN("loadorder", "{} ({})", r.error().message, r.error().hint);
}

}  // namespace

Result<LoadOrderMerge> record_load_order(const stdfs::path& projectDir, const LoadOrder& seen) {
    return record_with(share_env(), projectDir, seen);
}

void record_load_order_logged(const stdfs::path& projectDir, const LoadOrder& seen) { record_logged(share_env(), projectDir, seen); }

namespace {

// One writer thread for the whole process. The ShareEnv is copied when a write is queued: the thread never touches the
// global one, which other threads may replace (ScopedShareEnv) or the process may be destroying.
struct AsyncWriter {
    struct Job {
        stdfs::path dir;
        LoadOrder order;
        ShareEnv env;
    };
    std::mutex mutex;
    std::condition_variable wake, done;
    std::deque<Job> jobs;
    std::uint64_t queued = 0, finished = 0;
    bool stop = false;
    std::thread thread;

    ~AsyncWriter() {
        {
            std::lock_guard<std::mutex> lock(mutex);
            stop = true;
        }
        wake.notify_all();
        if (thread.joinable()) thread.join();
    }
    void push(Job job) {
        std::lock_guard<std::mutex> lock(mutex);
        jobs.push_back(std::move(job));
        ++queued;
        if (!thread.joinable()) thread = std::thread([this] { run(); });
        wake.notify_one();
    }
    void run() {
        std::unique_lock<std::mutex> lock(mutex);
        for (;;) {
            wake.wait(lock, [&] { return stop || !jobs.empty(); });
            if (jobs.empty()) return;  // stopping, and nothing left
            Job job = std::move(jobs.front());
            jobs.pop_front();
            lock.unlock();
            record_logged(job.env, job.dir, job.order);
            lock.lock();
            ++finished;
            done.notify_all();
        }
    }
    void wait() {
        std::unique_lock<std::mutex> lock(mutex);
        const std::uint64_t target = queued;
        done.wait(lock, [&] { return finished >= target; });
    }
};

AsyncWriter& async_writer() {
    static AsyncWriter writer;
    return writer;
}

}  // namespace

void record_load_order_async(stdfs::path projectDir, LoadOrder seen) {
    if (seen.empty()) return;
    async_writer().push(AsyncWriter::Job{std::move(projectDir), std::move(seen), share_env()});
}

void wait_load_order_writes() { async_writer().wait(); }

PackOrder pack_order(const LoadOrder& recorded, std::string_view mainScene, const std::vector<std::string>& shipped) {
    const std::unordered_set<std::string> ships(shipped.begin(), shipped.end());
    std::unordered_set<std::string> placed;
    PackOrder out;
    auto take = [&](const SceneFiles& s) {
        const std::size_t before = out.files.size();
        // The scene file itself first: it is the first thing its load reads.
        if (ships.count(s.scene) && placed.insert(s.scene).second) out.files.push_back(s.scene);
        for (const std::string& f : s.files)
            if (ships.count(f) && placed.insert(f).second) out.files.push_back(f);
        if (out.files.size() > before) ++out.scenes;
    };
    for (const SceneFiles& s : recorded)
        if (s.scene == mainScene) take(s);
    for (const SceneFiles& s : recorded)
        if (s.scene != mainScene) take(s);
    return out;
}

}  // namespace fa
