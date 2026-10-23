#include "preload.h"

#include <algorithm>
#include <chrono>
#include <set>

#include "fa/core/fs.h"
#include "fa/core/strings.h"

namespace fa {
namespace {

bool is_binary_asset(const std::string& ext) {
    static const char* const kExt[] = {".png", ".jpg", ".jpeg", ".bmp", ".tga", ".gif", ".gltf", ".glb", ".obj", ".wav",
                                       ".ogg", ".mp3", ".qoa", ".ttf", ".otf", ".mp4", ".bin"};
    return std::find(std::begin(kExt), std::end(kExt), ext) != std::end(kExt);
}

bool is_script(const std::string& ext) { return ext == ".js" || ext == ".mjs"; }

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

bool is_json_asset(const std::string& path) { return ends_with(path, ".prefab.json") || ends_with(path, ".material.json"); }

// Every string in `j` that names a project file worth reading ahead.
void collect_strings(const Json& j, std::vector<std::string>& out) {
    if (j.is_string()) out.push_back(j.get<std::string>());
    else if (j.is_array() || j.is_object())
        for (const Json& v : j) collect_strings(v, out);
}

std::string project_path(const std::string& s) {
    if (s.empty() || s.size() > 260 || fs::is_absolute(s)) return {};
    if (s.find("://") != std::string::npos || starts_with(s, "data:")) return {};
    return fs::normalize(s);
}

}  // namespace

Result<int> Preloader::start_scene(const std::string& pathIn) {
    auto n = fs::normalize_checked(pathIn);
    if (!n) return n.error();
    const std::string path = n.value();
    if (!fs::exists(path)) {
        std::vector<std::string> scenes = fs::list("scenes", true, ".json");
        return make_error("scene.preload: scene '" + pathIn + "' does not exist. " + did_you_mean(path, scenes),
                          "Pass the project-relative path of a scene file, e.g. scene.preload(\"scenes/level1.scene.json\").");
    }
    Job job;
    job.id = nextId_++;
    job.isScene = true;
    job.roots = {path};
    jobs_.push_back(std::move(job));
    return jobs_.back().id;
}

Result<int> Preloader::start_assets(const std::vector<std::string>& paths) {
    Job job;
    for (const std::string& p : paths) {
        auto n = fs::normalize_checked(p);
        if (!n) return n.error();
        if (!fs::exists(n.value())) {
            std::vector<std::string> files = fs::list("assets", true);
            return make_error("assets.preload: file '" + p + "' does not exist. " + did_you_mean(n.value(), files),
                              "Pass project-relative paths such as [\"assets/hero.glb\", \"assets/theme.ogg\"].");
        }
        if (fs::is_directory(n.value()))
            return make_error("assets.preload: '" + p + "' is a folder, not a file", "List the files: fs.list in a tool, or name each one.");
        job.roots.push_back(n.value());
    }
    job.id = nextId_++;
    jobs_.push_back(std::move(job));
    return jobs_.back().id;
}

bool Preloader::release(int id) {
    if (auto k = kept_.find(id); k != kept_.end()) {
        for (const std::string& f : k->second.files) fs::unwarm(f);
        kept_.erase(k);
        return true;
    }
    for (auto it = jobs_.begin(); it != jobs_.end(); ++it) {
        if (it->id != id) continue;
        for (const std::string& f : it->warmed) fs::unwarm(f);
        jobs_.erase(it);
        return true;
    }
    return false;
}

void Preloader::scene_loaded() {
    for (auto it = kept_.begin(); it != kept_.end();) {
        if (++it->second.loads >= 2) {
            for (const std::string& f : it->second.files) fs::unwarm(f);
            it = kept_.erase(it);
        } else {
            ++it;
        }
    }
}

void Preloader::reset() {
    jobs_.clear();
    kept_.clear();
    fs::unwarm_all();
}

void Preloader::scan(Job& job) {
    std::set<std::string> seen;
    std::vector<std::string> binaries;
    // Reads `path` now (the scan is one unit) and returns its text.
    auto read = [&](const std::string& path, std::string& text) {
        std::uint64_t size = 0;
        auto r = fs::warm(path, &text, &size);
        if (!r) {
            job.error = r.error().message;
            job.hint = r.error().hint;
            return false;
        }
        job.warmed.push_back(path);
        job.bytes += size;
        return true;
    };
    std::vector<std::string> pending;  // JSON files and models whose references are still to be found
    auto consider = [&](const std::string& raw, bool force) {
        const std::string p = project_path(raw);
        if (p.empty() || seen.count(p)) return;
        const std::string ext = to_lower(fs::extension(p));
        const bool json = is_json_asset(p);
        if (!force && !json && !is_binary_asset(ext) && !is_script(ext)) return;
        if (!fs::exists(p) || fs::is_directory(p)) return;
        seen.insert(p);
        if (json || ext == ".gltf" || is_script(ext)) pending.push_back(p);
        else binaries.push_back(p);
    };
    for (const std::string& root : job.roots) {
        if (job.isScene) {
            seen.insert(root);
            pending.push_back(root);
        } else {
            consider(root, true);
        }
    }
    for (std::size_t i = 0; i < pending.size() && job.error.empty(); ++i) {
        const std::string path = pending[i];
        std::string text;
        if (!read(path, text)) return;
        if (is_script(to_lower(fs::extension(path)))) {  // a behaviour: its imports and the files its strings name
            std::vector<std::string> literals;
            collect_literals(text, literals);
            const std::string dir = fs::parent(path);
            for (const std::string& lit : literals) {
                if (starts_with(lit, "./") || starts_with(lit, "../")) consider(dir.empty() ? lit : fs::join(dir, lit), is_script(to_lower(fs::extension(lit))) || ends_with(lit, ".json"));
                else consider(lit, false);
            }
            continue;
        }
        auto parsed = parse_json(text, path);
        if (!parsed) {
            if (job.isScene && i == 0) {  // the scene itself: the loader would fail the same way
                job.error = parsed.error().message;
                job.hint = parsed.error().hint;
            }
            continue;  // a model or material that is not JSON-parsable is the renderer's to report
        }
        if (to_lower(fs::extension(path)) == ".gltf") {  // buffers and images are relative to the model's folder
            const std::string dir = fs::parent(path);
            std::vector<std::string> uris;
            for (const char* key : {"buffers", "images"})
                if (parsed->contains(key) && (*parsed)[key].is_array())
                    for (const Json& e : (*parsed)[key])
                        if (e.is_object() && e.contains("uri") && e["uri"].is_string()) uris.push_back(e["uri"].get<std::string>());
            for (const std::string& u : uris) consider(dir.empty() ? u : fs::join(dir, u), true);
        } else {
            std::vector<std::string> strings;
            collect_strings(*parsed, strings);
            for (const std::string& s : strings) consider(s, false);
        }
    }
    if (!job.error.empty()) return;
    for (const std::string& b : binaries) job.queue.push_back(b);
    job.total = 1 + int(job.queue.size());
}

bool Preloader::run_unit(Job& job) {
    if (!job.error.empty()) return false;
    if (!job.scanned) {
        job.scanned = true;
        scan(job);
        job.done = job.error.empty() ? 1 : 0;
        return true;
    }
    if (job.next >= job.queue.size()) return false;
    const std::string& file = job.queue[job.next++];
    std::uint64_t size = 0;
    auto r = fs::warm(file, nullptr, &size);
    if (!r) {
        job.error = r.error().message;
        job.hint = r.error().hint;
        return true;
    }
    job.warmed.push_back(file);
    job.bytes += size;
    job.done++;
    return true;
}

std::vector<Preloader::Update> Preloader::tick(double budgetMs) {
    std::vector<Update> updates;
    if (jobs_.empty()) return updates;
    using Clock = std::chrono::steady_clock;
    const auto start = Clock::now();
    auto finished = [](const Job& job) { return !job.error.empty() || (job.scanned && job.next >= job.queue.size()); };
    std::set<int> touched;
    // Oldest job first, round after round. Fixed budget: kFixedUnitsPerFrame units in total per frame.
    bool stop = false;
    int units = 0;
    while (!stop) {
        bool worked = false;
        for (Job& job : jobs_) {
            if (finished(job)) continue;
            if (run_unit(job)) touched.insert(job.id);
            worked = true;
            ++units;
            if (budgetMs <= 0 ? units >= kFixedUnitsPerFrame
                              : std::chrono::duration<double, std::milli>(Clock::now() - start).count() >= budgetMs) {
                stop = true;
                break;
            }
        }
        if (!worked) stop = true;
    }
    for (auto it = jobs_.begin(); it != jobs_.end();) {
        Job& job = *it;
        const bool isDone = finished(job);
        if (touched.count(job.id)) {
            Update u;
            u.id = job.id;
            u.done = job.done;
            u.total = job.total;
            u.bytes = job.bytes;
            u.error = job.error;
            u.hint = job.hint;
            u.finished = isDone;
            updates.push_back(u);
        }
        if (isDone) {
            if (!job.error.empty()) for (const std::string& f : job.warmed) fs::unwarm(f);
            else kept_[job.id].files = std::move(job.warmed);  // stays warm for the load that comes
            it = jobs_.erase(it);
        } else {
            ++it;
        }
    }
    return updates;
}

}  // namespace fa
