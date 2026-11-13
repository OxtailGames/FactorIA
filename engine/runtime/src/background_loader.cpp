#include "background_loader.h"

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cmath>
#include <mutex>
#include <utility>

#include "fa/audio/audio.h"
#include "fa/core/asset_manifest.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/strings.h"

namespace fa {

// What a queued item and the main thread share. The item marks when it starts and ends and lists the files it made warm,
// so the files of an item cancelled while the IO thread read it can be dropped once it ended (collect_orphans).
struct BackgroundLoader::Shared {
    std::mutex mu;
    bool cancelled = false, started = false, done = false;
    std::vector<std::string> warmed;  // files this item holds a reference to (warm_acquire), each once
    std::string readPath;             // the file the item read (a texture's twin, a sound's .qoa)
    std::uint64_t size = 0;
    bool readFailed = false;
    std::string error, hint;

    // False when the item was cancelled before it started: it does nothing then.
    bool begin() {
        std::lock_guard<std::mutex> lock(mu);
        if (cancelled) return false;
        started = true;
        return true;
    }
    void finish() {
        std::lock_guard<std::mutex> lock(mu);
        done = true;
    }
    bool is_cancelled() {
        std::lock_guard<std::mutex> lock(mu);
        return cancelled;
    }
    void add_warm(const std::string& path) {
        std::lock_guard<std::mutex> lock(mu);
        warmed.push_back(path);
    }
    void set_read(const std::string& path, std::uint64_t bytes) {
        std::lock_guard<std::mutex> lock(mu);
        readPath = path;
        size = bytes;
        warmed.push_back(path);
    }
    void set_failed(const Error& e) {
        std::lock_guard<std::mutex> lock(mu);
        readFailed = true;
        error = e.message;
        hint = e.hint;
    }
};

namespace {

// The references the loaders of every engine hold to warm files (background_loader.h): fs::unwarm runs when the last one
// goes. A reference is taken BEFORE the file is warmed, so another loader's release in between cannot drop it. Never
// destroyed: a loader may end after static destruction began.
struct WarmRegistry {
    std::mutex mu;
    std::map<std::string, int> refs;
};
WarmRegistry& warm_registry() {
    static WarmRegistry* r = new WarmRegistry();
    return *r;
}
void warm_acquire(const std::string& path) {
    WarmRegistry& r = warm_registry();
    std::lock_guard<std::mutex> lock(r.mu);
    ++r.refs[path];
}
void warm_release(const std::string& path) {
    WarmRegistry& r = warm_registry();
    std::lock_guard<std::mutex> lock(r.mu);
    auto it = r.refs.find(path);
    if (it == r.refs.end()) return;
    if (--it->second > 0) return;
    r.refs.erase(it);
    fs::unwarm(path);  // the last reference of any engine's loader
}

// Load-trace tags of background loads: process-wide, so two engines never share one.
std::atomic<std::uint64_t> g_nextTag{1};

bool is_sound(const std::string& ext) { return ext == ".wav" || ext == ".ogg" || ext == ".mp3" || ext == ".qoa"; }

bool is_binary_asset(const std::string& ext) {
    static const char* const kExt[] = {".png", ".jpg", ".jpeg", ".bmp", ".tga", ".gif", ".ktx2", ".gltf", ".glb",
                                       ".obj", ".wav", ".ogg",  ".mp3", ".qoa", ".ttf", ".otf",  ".mp4",  ".bin"};
    return std::find(std::begin(kExt), std::end(kExt), ext) != std::end(kExt);
}

bool is_script(const std::string& ext) { return ext == ".js" || ext == ".mjs"; }

bool is_json_asset(const std::string& path) {
    return ends_with(path, ".prefab.json") || ends_with(path, ".material.json");
}

// The string literals of a script (no escapes handled: file paths do not have them).
void collect_literals(const std::string& text, std::vector<std::string>& out) {
    for (std::size_t i = 0; i < text.size(); ++i) {
        const char q = text[i];
        if (q != '"' && q != '\'') continue;
        std::size_t j = i + 1;
        while (j < text.size() && text[j] != q && text[j] != '\n' && text[j] != '\\' && j - i < 240) ++j;
        if (j < text.size() && text[j] == q) {
            if (j > i + 1) out.push_back(text.substr(i + 1, j - i - 1));
            i = j;
        }
    }
}

// Every string in `j`: the candidates for project files worth reading ahead.
void collect_strings(const Json& j, std::vector<std::string>& out) {
    if (j.is_string())
        out.push_back(j.get<std::string>());
    else if (j.is_array() || j.is_object())
        for (const Json& v : j) collect_strings(v, out);
}

std::string project_path(const std::string& s) {
    if (s.empty() || s.size() > 260 || fs::is_absolute(s)) return {};
    if (s.find("://") != std::string::npos || starts_with(s, "data:")) return {};
    return fs::normalize(s);
}

// The file exists, or what an export made of it does (a texture packed into an atlas or given a KTX2 twin, a sound's
// QOA twin): the loaders read those instead.
bool file_or_twin_exists(const std::string& p, const std::string& ext) {
    if (fs::exists(p)) return !fs::is_directory(p);
    if (is_sound(ext) && ext != ".qoa") return fs::exists(p + ".qoa");
    if (Renderer::background_kind(p) == Renderer::BackgroundKind::Texture)
        return !assets::packed_texture(p).atlas.empty() || fs::exists(p + kTextureTwinExtension);
    return false;
}

struct ScanResult {
    std::vector<std::string> binaries;  // in the order they were found
    std::uint64_t bytes = 0;
    std::string error, hint;
};

// The scan of a job (a decode job, or the thread that takes it): reads the roots and the text files they point at, in
// breadth-first order, into the warm set, and lists the binary files. Touches nothing but fa::fs and the asset manifest.
ScanResult scan_files(const std::vector<std::string>& roots, bool isScene, BackgroundLoader::Shared& sh) {
    ScanResult out;
    std::set<std::string> seen;
    std::vector<std::string> pending;  // text files whose references are still to be found
    auto consider = [&](const std::string& raw, bool force) {
        const std::string p = project_path(raw);
        if (p.empty() || seen.count(p)) return;
        const std::string ext = to_lower(fs::extension(p));
        const bool json = is_json_asset(p);
        if (!force && !json && !is_binary_asset(ext) && !is_script(ext)) return;
        if (!file_or_twin_exists(p, ext)) return;
        seen.insert(p);
        if (json || ext == ".gltf" || is_script(ext)) pending.push_back(p);
        if (!json && !is_script(ext) && (ext == ".gltf" || is_binary_asset(ext) || force)) out.binaries.push_back(p);
    };
    for (const std::string& root : roots) {
        if (isScene) {
            seen.insert(root);
            pending.push_back(root);
        } else {
            consider(root, true);
        }
    }
    for (std::size_t i = 0; i < pending.size(); ++i) {
        if (sh.is_cancelled()) return out;  // the job was cancelled meanwhile: warm nothing more
        const std::string path = pending[i];
        std::string text;
        std::uint64_t size = 0;
        warm_acquire(path);
        if (auto r = fs::warm(path, &text, &size); !r) {
            warm_release(path);
            out.error = r.error().message;
            out.hint = r.error().hint;
            return out;
        }
        sh.add_warm(path);
        out.bytes += size;
        if (is_script(to_lower(fs::extension(path)))) {  // a behaviour: its imports and the files its strings name
            std::vector<std::string> literals;
            collect_literals(text, literals);
            const std::string dir = fs::parent(path);
            for (const std::string& lit : literals) {
                if (starts_with(lit, "./") || starts_with(lit, "../"))
                    consider(dir.empty() ? lit : fs::join(dir, lit),
                             is_script(to_lower(fs::extension(lit))) || ends_with(lit, ".json"));
                else
                    consider(lit, false);
            }
            continue;
        }
        auto parsed = parse_json(text, path);
        if (!parsed) {
            if (isScene && i == 0) {  // the scene itself: its load would fail the same way
                out.error = parsed.error().message;
                out.hint = parsed.error().hint;
                return out;
            }
            continue;  // a model or a material that is not JSON is its loader's to report, on first use
        }
        if (to_lower(fs::extension(path)) == ".gltf") {  // buffers and images are relative to the model's folder
            const std::string dir = fs::parent(path);
            std::vector<std::string> uris;
            for (const char* key : {"buffers", "images"})
                if (parsed->contains(key) && (*parsed)[key].is_array())
                    for (const Json& e : (*parsed)[key])
                        if (e.is_object() && e.contains("uri") && e["uri"].is_string())
                            uris.push_back(e["uri"].get<std::string>());
            for (const std::string& u : uris) consider(dir.empty() ? u : fs::join(dir, u), true);
        } else {
            std::vector<std::string> strings;
            collect_strings(*parsed, strings);
            for (const std::string& s : strings) consider(s, false);
        }
    }
    return out;
}

IoResult failure(std::string message, std::string hint = {}) {
    IoResult r;
    r.error = std::move(message);
    r.hint = std::move(hint);
    return r;
}

// Reads `path` (or the twin a sound's loader would read) into the warm set for `sh`.
Result<IoFile> warm_read(BackgroundLoader::Shared& sh, const std::string& path, bool soundTwin) {
    std::string file = path;
    if (soundTwin && !fs::exists(file) && fs::exists(file + ".qoa")) file += ".qoa";
    std::uint64_t size = 0;
    warm_acquire(file);
    if (auto w = fs::warm(file, nullptr, &size); !w) {
        warm_release(file);
        sh.set_failed(w.error());
        return w.error();
    }
    sh.set_read(file, size);
    return IoFile{file, {}};
}

const char* kind_name(BackgroundLoader::Kind k) {
    switch (k) {
        case BackgroundLoader::Kind::ScenePreload: return "scene.preload";
        case BackgroundLoader::Kind::Assets: return "assets.preload";
        case BackgroundLoader::Kind::SceneLoad: return "scene.load";
    }
    return "?";
}

}  // namespace

Json BackgroundLoader::Update::to_json() const {
    return Json::object({{"id", id},
                         {"done", done},
                         {"total", total},
                         {"bytes", bytes},
                         {"uploadedBytes", uploadedBytes},
                         {"finished", finished},
                         {"cancelled", cancelled},
                         {"error", error},
                         {"hint", hint}});
}

BackgroundLoader::BackgroundLoader(jobs::Owner* jobs, LoadTrace::Owner traceOwner)
    : io_(jobs, traceOwner), traceOwner_(traceOwner) {}

BackgroundLoader::~BackgroundLoader() {
    stop(nullptr);
    collect_orphans(true);  // the engine waited for its jobs: every item has ended
}

Result<int> BackgroundLoader::start(Kind kind, const std::vector<std::string>& paths, std::optional<Json> props,
                                    Origin origin, LoadTrace* trace) {
    const char* api = kind_name(kind);
    std::vector<std::string> roots;
    if (paths.empty())
        return make_error(std::string(api) + ": no file was given",
                          kind == Kind::Assets
                              ? "Pass project-relative paths such as [\"assets/hero.glb\", \"assets/theme.ogg\"]."
                              : "Pass the project-relative path of a scene file, e.g. \"scenes/level1.scene.json\".");
    for (const std::string& p : paths) {
        auto n = fs::normalize_checked(p);
        if (!n) return make_error(std::string(api) + ": " + n.error().message, n.error().hint);
        const std::string path = n.value();
        if (kind != Kind::Assets) {
            if (!fs::exists(path) || fs::is_directory(path)) {
                std::vector<std::string> scenes = fs::list("scenes", true, ".json");
                return make_error(std::string(api) + ": scene '" + p + "' does not exist. " +
                                      did_you_mean(path, scenes),
                                  std::string("Pass the project-relative path of a scene file, e.g. ") + api +
                                      "(\"scenes/level1.scene.json\").");
            }
        } else {
            const std::string ext = to_lower(fs::extension(path));
            if (fs::exists(path) && fs::is_directory(path))
                return make_error("assets.preload: '" + p + "' is a folder, not a file",
                                  "List the files: fs.list in a tool, or name each one.");
            if (!file_or_twin_exists(path, ext)) {
                // Suggestions from the folder it names first (assets/, sounds/, ...), or from assets/ for a bare name.
                const std::size_t slash = path.find('/');
                const std::string top = slash == std::string::npos ? std::string() : path.substr(0, slash);
                std::vector<std::string> files = fs::list(!top.empty() && fs::is_directory(top) ? top : "assets", true);
                return make_error("assets.preload: file '" + p + "' does not exist. " + did_you_mean(path, files),
                                  "Pass project-relative paths such as [\"assets/hero.glb\", \"assets/theme.ogg\"].");
            }
        }
        roots.push_back(path);
        if (kind != Kind::Assets) break;  // one scene
    }
    if (kind == Kind::SceneLoad) cancel_scene_loads(trace);  // the last request wins
    Job job;
    job.id = nextId_++;
    job.kind = kind;
    job.origin = origin;
    job.roots = std::move(roots);
    job.props = std::move(props);
    job.tag = g_nextTag.fetch_add(1, std::memory_order_relaxed);
    if (kind == Kind::SceneLoad && trace) trace->scene_requested(job.roots.front(), job.tag);
    submit_scan(job);
    jobs_.push_back(std::move(job));
    return jobs_.back().id;
}

void BackgroundLoader::submit_scan(Job& job) {
    auto sh = std::make_shared<Shared>();
    job.scanShared = sh;
    const std::vector<std::string> roots = job.roots;
    const bool isScene = job.kind != Kind::Assets;
    job.scanTicket = io_.submit([] { return Result<IoFile>(IoFile{}); },
                                [sh, roots, isScene](IoFile&) -> IoResult {
                                    if (!sh->begin()) return IoResult{false, true};
                                    auto res = std::make_shared<ScanResult>(scan_files(roots, isScene, *sh));
                                    sh->finish();
                                    IoResult r;
                                    r.ok = true;
                                    r.bytes = res->bytes;
                                    r.value = std::move(res);
                                    return r;
                                },
                                job.tag);
}

void BackgroundLoader::submit_units(Job& job, Renderer* renderer) {
    while (job.nextSubmit < job.units.size() && job.nextSubmit - job.nextTake < std::size_t(kMaxInFlight)) {
        Unit& u = job.units[job.nextSubmit++];
        if (u.trivial) continue;
        auto sh = std::make_shared<Shared>();
        u.shared = sh;
        const std::string path = u.path;
        IoRead read;
        IoDecode decode;
        switch (u.kind) {
            case UnitKind::Render: {
                Renderer::BackgroundWork w = renderer->background_work(path, u.renderKind);
                read = [sh, path, inner = std::move(w.read)]() -> Result<IoFile> {
                    if (!sh->begin()) return make_error("cancelled");
                    warm_acquire(path);  // the renderer warms the file before it reads it (or its twin: moved below)
                    Result<IoFile> f = inner();
                    if (f) {
                        const std::string& actual = f.value().path;
                        if (actual != path) {
                            warm_acquire(actual);
                            warm_release(path);
                        }
                        sh->set_read(actual, f.value().view.size());
                    } else {
                        warm_release(path);
                        sh->set_failed(f.error());
                    }
                    sh->finish();
                    return f;
                };
                decode = std::move(w.decode);
                break;
            }
            case UnitKind::Sound:
                read = [sh, path]() -> Result<IoFile> {
                    if (!sh->begin()) return make_error("cancelled");
                    auto f = warm_read(*sh, path, true);
                    sh->finish();
                    return f;
                };
                decode = [path](IoFile&) -> IoResult {
                    std::string error;
                    std::shared_ptr<const void> clip = Audio::decode_clip(path, &error);
                    if (!clip) return failure(error);
                    IoResult r;
                    r.ok = true;
                    r.value = std::const_pointer_cast<void>(clip);
                    return r;
                };
                break;
            case UnitKind::Warm:
                read = [sh, path]() -> Result<IoFile> {
                    if (!sh->begin()) return make_error("cancelled");
                    auto f = warm_read(*sh, path, false);
                    sh->finish();
                    return f;
                };
                break;
        }
        u.ticket = io_.submit(std::move(read), std::move(decode), job.tag);
    }
}

bool BackgroundLoader::front_ready(const Job& job) const {
    if (!job.scanned) return io_.ready(job.scanTicket);
    if (job.nextTake >= job.units.size()) return true;
    const Unit& u = job.units[job.nextTake];
    return u.trivial || io_.ready(u.ticket);
}

void BackgroundLoader::hold(Job& job, const std::string& path) {
    if (!job.warmed.insert(path).second)
        warm_release(path);  // the job holds this file already: one reference is enough
}

void BackgroundLoader::drop(const std::string& path) { warm_release(path); }

void BackgroundLoader::take_scan(Job& job, Renderer* renderer, Audio* audio) {
    IoResult r = io_.take(job.scanTicket);
    job.scanTicket = 0;
    job.scanned = true;
    std::vector<std::string> warmed;
    {
        std::lock_guard<std::mutex> lock(job.scanShared->mu);
        warmed = std::move(job.scanShared->warmed);
    }
    job.scanShared.reset();
    for (const std::string& f : warmed) hold(job, f);
    if (!r.ok || !r.value) {
        job.error = r.error.empty() ? "the scan of the files failed" : r.error;
        job.hint = r.hint;
        return;
    }
    const ScanResult& res = *std::static_pointer_cast<ScanResult>(r.value);
    job.bytes += res.bytes;
    if (!res.error.empty()) {
        job.error = res.error;
        job.hint = res.hint;
        return;
    }
    std::vector<Unit> models;
    for (const std::string& path : res.binaries) {
        Unit u;
        u.path = path;
        const std::string ext = to_lower(fs::extension(path));
        const Renderer::BackgroundKind rk = Renderer::background_kind(path);
        if (renderer && rk != Renderer::BackgroundKind::None) {
            u.kind = UnitKind::Render;
            u.renderKind = rk;
            u.trivial = renderer->background_cached(path, rk);
        } else if (audio && is_sound(ext)) {
            u.kind = UnitKind::Sound;
            u.trivial = audio->clip_loaded(path);
        }
        // Models after everything else: the textures they name are in the cache when they are uploaded.
        if (u.kind == UnitKind::Render && rk == Renderer::BackgroundKind::Model)
            models.push_back(std::move(u));
        else
            job.units.push_back(std::move(u));
    }
    for (Unit& m : models) job.units.push_back(std::move(m));
    job.total = 1 + int(job.units.size());
    job.done = 1;
}

void BackgroundLoader::run_unit(Job& job, Renderer* renderer, Audio* audio, std::uint64_t& uploaded) {
    if (!job.scanned) {
        take_scan(job, renderer, audio);
        return;
    }
    Unit& u = job.units[job.nextTake++];
    if (u.trivial) {
        job.done++;
        return;
    }
    IoResult r = io_.take(u.ticket);
    u.ticket = 0;
    std::vector<std::string> warmed;
    std::uint64_t size = 0;
    bool readFailed = false;
    std::string error, hint;
    {
        std::lock_guard<std::mutex> lock(u.shared->mu);
        warmed = std::move(u.shared->warmed);
        size = u.shared->size;
        readFailed = u.shared->readFailed;
        error = u.shared->error;
        hint = u.shared->hint;
    }
    u.shared.reset();
    for (const std::string& f : warmed) hold(job, f);
    if (readFailed) {  // the file was there when the job started: it went away, or cannot be read
        job.error = error;
        job.hint = hint;
        return;
    }
    job.bytes += std::max(size, r.bytes);
    bool adopted = false;
    if (r.ok && u.kind == UnitKind::Render && renderer) {
        // The upload may look up textures the model names: reads ahead, so they enter the load order on first use.
        const LoadTrace::ReadingFor reading(traceOwner_, job.tag);
        const std::uint64_t up = renderer->adopt_background(u.path, u.renderKind, r);
        job.uploaded += up;
        uploaded += up;
        adopted = renderer->background_cached(u.path, u.renderKind);
    } else if (r.ok && u.kind == UnitKind::Sound && audio) {
        audio->adopt_clip(u.path, std::static_pointer_cast<const void>(r.value), std::move(r.files));
        adopted = audio->clip_loaded(u.path);
    }
    // In a cache: its warm bytes are not needed any more. A file that failed to decode stays warm: its load on first use
    // reads it from memory and reports the problem as it always does.
    if (adopted)
        for (const std::string& f : warmed)
            if (job.warmed.erase(f)) drop(f);
    job.done++;
}

void BackgroundLoader::abandon(Job& job) {
    auto orphan = [&](std::shared_ptr<Shared>& sh, IoQueue::Ticket& ticket) {
        if (ticket) io_.cancel(ticket);
        ticket = 0;
        if (!sh) return;
        bool keep = false;
        std::vector<std::string> warmed;
        {
            std::lock_guard<std::mutex> lock(sh->mu);
            sh->cancelled = true;
            keep = sh->started && !sh->done;  // the IO thread or a decode is on it now
            if (sh->done) warmed = std::move(sh->warmed);
        }
        for (const std::string& f : warmed) warm_release(f);
        if (keep) orphans_.push_back(sh);
        sh.reset();
    };
    orphan(job.scanShared, job.scanTicket);
    for (Unit& u : job.units) orphan(u.shared, u.ticket);
    for (const std::string& f : job.warmed) drop(f);
    job.warmed.clear();
}

void BackgroundLoader::collect_orphans(bool all) {
    for (auto it = orphans_.begin(); it != orphans_.end();) {
        std::vector<std::string> warmed;
        bool done = false;
        {
            std::lock_guard<std::mutex> lock((*it)->mu);
            done = (*it)->done || all;
            if (done) warmed = std::move((*it)->warmed);
        }
        if (!done) {
            ++it;
            continue;
        }
        for (const std::string& f : warmed) warm_release(f);
        it = orphans_.erase(it);
    }
}

BackgroundLoader::Update BackgroundLoader::update_of(const Job& job) const {
    Update u;
    u.id = job.id;
    u.origin = job.origin;
    u.done = job.done;
    u.total = job.total;
    u.bytes = job.bytes;
    u.uploadedBytes = job.uploaded;
    u.finished = job.finished();
    u.cancelled = job.cancelled;
    u.error = job.error;
    u.hint = job.hint;
    return u;
}

Json BackgroundLoader::job_status(const Job& job) const {
    const char* state = job.cancelled        ? "cancelled"
                        : !job.error.empty() ? "failed"
                        : job.finished()     ? "done"
                        : job.scanned        ? "loading"
                                             : "scanning";
    Json paths = Json::array();
    for (const std::string& p : job.roots) paths.push_back(p);
    Json j = Json::object({{"id", job.id},
                           {"kind", kind_name(job.kind)},
                           {"paths", paths},
                           {"origin", job.origin == Origin::Script ? "script" : "tool"},
                           {"state", state},
                           {"progress", std::round(job.progress * 1000.0) / 1000.0},
                           {"items", Json::object({{"done", job.done}, {"total", job.total}})},
                           {"bytes", job.bytes},
                           {"uploadedBytes", job.uploaded}});
    if (!job.error.empty()) {
        j["error"] = job.error;
        j["hint"] = job.hint;
    }
    return j;
}

void BackgroundLoader::remember(const Job& job) {
    history_.push_back(job_status(job));
    if (history_.size() > kHistory) history_.erase(history_.begin());
}

bool BackgroundLoader::cancel(int id, LoadTrace* trace) {
    if (auto k = kept_.find(id); k != kept_.end()) {
        for (const std::string& f : k->second.files) drop(f);
        kept_.erase(k);
        return true;
    }
    for (auto it = jobs_.begin(); it != jobs_.end(); ++it) {
        if (it->id != id) continue;
        Job job = std::move(*it);
        jobs_.erase(it);
        abandon(job);
        job.cancelled = true;
        if (job.kind == Kind::SceneLoad && trace) trace->load_cancelled(job.tag);
        pending_.push_back(update_of(job));
        remember(job);
        return true;
    }
    return false;
}

int BackgroundLoader::cancel_scene_loads(LoadTrace* trace) {
    std::vector<int> ids;
    for (const Job& j : jobs_)
        if (j.kind == Kind::SceneLoad) ids.push_back(j.id);
    for (int id : ids) cancel(id, trace);
    return int(ids.size());
}

void BackgroundLoader::reset(LoadTrace* trace) {
    std::vector<int> ids;
    for (const Job& j : jobs_) ids.push_back(j.id);
    for (int id : ids) cancel(id, trace);
    pending_.clear();
    for (const auto& entry : kept_)
        for (const std::string& f : entry.second.files) drop(f);
    kept_.clear();
    history_.clear();
}

void BackgroundLoader::cancel_origin(Origin origin, LoadTrace* trace) {
    std::vector<int> ids;
    for (const Job& j : jobs_)
        if (j.origin == origin) ids.push_back(j.id);
    for (int id : ids) cancel(id, trace);
    pending_.erase(
        std::remove_if(pending_.begin(), pending_.end(), [&](const Update& u) { return u.origin == origin; }),
        pending_.end());
}

void BackgroundLoader::stop(LoadTrace* trace) {
    std::vector<int> ids;
    for (const Job& j : jobs_) ids.push_back(j.id);
    for (int id : ids) cancel(id, trace);
    pending_.clear();
    io_.cancel_all();  // the IO thread has let go of this engine's files
    for (const auto& entry : kept_)
        for (const std::string& f : entry.second.files) drop(f);
    kept_.clear();
    // The reads have ended; a scan (a decode job) may still run: the destructor, after the engine waited for its jobs,
    // drops what it warmed.
    collect_orphans(false);
}

void BackgroundLoader::scene_loaded() {
    for (auto it = kept_.begin(); it != kept_.end();) {
        if (++it->second.loads >= 2) {
            for (const std::string& f : it->second.files) drop(f);
            it = kept_.erase(it);
        } else {
            ++it;
        }
    }
}

BackgroundLoader::Frame BackgroundLoader::tick(Renderer* renderer, Audio* audio, const Budget& budget) {
    Frame frame;
    frame.updates = std::exchange(pending_, {});
    collect_orphans(false);
    if (jobs_.empty()) return frame;
    using Clock = std::chrono::steady_clock;
    const auto start = Clock::now();
    const std::uint64_t uploadCap =
        budget.uploadMB <= 0 ? 0 : std::uint64_t(std::min(budget.uploadMB, 1.0e6) * 1024.0 * 1024.0);
    auto spent = [&] {
        if (budget.exact) return frame.units >= budget.units;
        if (uploadCap > 0 && frame.uploadedBytes >= uploadCap) return true;
        return std::chrono::duration<double, std::milli>(Clock::now() - start).count() >= budget.ms;
    };
    std::set<int> touched;
    for (Job& job : jobs_)
        if (job.scanned) submit_units(job, renderer);
    // Round after round, one unit of each job in start order (see the top of background_loader.h).
    bool halt = budget.exact && budget.units <= 0;
    while (!halt) {
        bool worked = false;
        for (Job& job : jobs_) {
            if (job.finished()) continue;
            if (!budget.exact && io_.threaded() && !front_ready(job)) {  // never wait in a timed frame
                halt = true;
                break;
            }
            run_unit(job, renderer, audio, frame.uploadedBytes);
            if (job.scanned)
                submit_units(job, renderer);  // refill what the IO thread works on (all of it after the scan)
            touched.insert(job.id);
            worked = true;
            ++frame.units;
            if (spent()) {
                halt = true;
                break;
            }
        }
        if (!worked) halt = true;
    }
    for (auto it = jobs_.begin(); it != jobs_.end();) {
        Job& job = *it;
        if (job.total > 0) job.progress = std::max(job.progress, double(job.done) / double(job.total));
        const bool isDone = job.finished();
        if (isDone && job.error.empty()) job.progress = 1.0;
        if (touched.count(job.id)) frame.updates.push_back(update_of(job));
        if (!isDone) {
            ++it;
            continue;
        }
        if (!job.error.empty()) {
            abandon(job);
        } else {
            Kept& k = kept_[job.id];  // the files still warm stay for the load that comes
            for (const std::string& f : job.warmed) k.files.insert(f);
            job.warmed.clear();
            if (job.kind == Kind::SceneLoad)
                frame.scenes.push_back(SceneReady{job.id, job.roots.front(), job.props, job.tag, job.origin});
        }
        remember(job);
        it = jobs_.erase(it);
    }
    return frame;
}

Json BackgroundLoader::status(int id) const {
    for (const Job& j : jobs_)
        if (j.id == id) return job_status(j);
    for (auto it = history_.rbegin(); it != history_.rend(); ++it)
        if ((*it)["id"].get<int>() == id) return *it;
    return Json();
}

Json BackgroundLoader::status_all() const {
    Json list = Json::array();
    for (const Job& j : jobs_) list.push_back(job_status(j));
    for (auto it = history_.rbegin(); it != history_.rend(); ++it) list.push_back(*it);
    return Json::object({{"jobs", list}, {"threaded", io_.threaded()}, {"warmBytes", fs::warm_bytes()}});
}

}  // namespace fa
