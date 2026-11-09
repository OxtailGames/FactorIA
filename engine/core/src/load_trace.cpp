#include "fa/core/load_trace.h"

#include <algorithm>
#include <chrono>
#include <cmath>

namespace fa {
namespace {

// Every live trace. A read is recorded in each (usually there is none or one).
std::mutex& traces_mutex() {
    static std::mutex m;
    return m;
}
std::vector<LoadTrace*>& traces() {
    static std::vector<LoadTrace*> t;
    return t;
}

thread_local LoadTrace::Owner t_owner = LoadTrace::kNoOwner;
thread_local std::uint64_t t_aheadTag = 0;                   // ReadingFor(owner, tag): reading ahead for that load
thread_local std::vector<std::string>* t_collector = nullptr;  // FileCollector

void collect(std::string_view path) {
    if (!t_collector) return;
    for (const std::string& f : *t_collector)
        if (f == path) return;
    t_collector->emplace_back(path);
}
std::atomic<LoadTrace::Owner> g_nextOwner{1};
thread_local std::int64_t t_readNs = 0;
thread_local std::uint64_t t_readBytes = 0;

double round_ms(std::int64_t ns) { return std::round(double(ns) / 1e5) / 10.0; }  // 0.1 ms

}  // namespace

std::atomic<int> LoadTrace::activeCount_{0};

std::int64_t LoadTrace::now_ns() {
    return std::chrono::duration_cast<std::chrono::nanoseconds>(std::chrono::steady_clock::now().time_since_epoch()).count();
}

std::int64_t LoadTrace::thread_read_ns() { return t_readNs; }

LoadTrace::Owner LoadTrace::current_owner() { return t_owner; }
LoadTrace::Owner LoadTrace::new_owner() { return g_nextOwner.fetch_add(1, std::memory_order_relaxed); }

LoadTrace::ReadingFor::ReadingFor(Owner owner, std::uint64_t aheadTag) : previous_(t_owner), previousTag_(t_aheadTag) {
    t_owner = owner;
    t_aheadTag = aheadTag;
}
LoadTrace::ReadingFor::~ReadingFor() {
    t_owner = previous_;
    t_aheadTag = previousTag_;
}
std::uint64_t LoadTrace::current_ahead_tag() { return t_aheadTag; }

LoadTrace::FileCollector::FileCollector(std::vector<std::string>* out) : previous_(t_collector) {
    t_collector = any() ? out : nullptr;
}
LoadTrace::FileCollector::~FileCollector() { t_collector = previous_; }

LoadTrace::LoadTrace(Owner owner) : owner_(owner), startNs_(now_ns()) {
    std::lock_guard<std::mutex> lock(traces_mutex());
    traces().push_back(this);
    activeCount_.fetch_add(1, std::memory_order_relaxed);
}

LoadTrace::~LoadTrace() {
    std::lock_guard<std::mutex> lock(traces_mutex());
    auto& t = traces();
    t.erase(std::remove(t.begin(), t.end(), this), t.end());
    activeCount_.fetch_sub(1, std::memory_order_relaxed);
}

void LoadTrace::file_read(std::string_view path, std::uint64_t bytes, std::uint64_t storedBytes, bool fromPack, std::int64_t readNs) {
    if (!any()) return;
    t_readNs += readNs;
    t_readBytes += bytes;
    collect(path);
    std::lock_guard<std::mutex> lock(traces_mutex());
    for (LoadTrace* t : traces())
        if (t->records(t_owner)) t->record_file(path, bytes, storedBytes, fromPack, t_aheadTag);
}

void LoadTrace::file_used(std::string_view path) {
    if (!any()) return;
    collect(path);
    if (t_aheadTag != 0) return;  // reading ahead: the file is not used yet
    std::lock_guard<std::mutex> lock(traces_mutex());
    for (LoadTrace* t : traces())
        if (t->records(t_owner)) t->record_use(path);
}

void LoadTrace::asset_loaded(std::string_view kind, std::string_view path, std::uint64_t bytes, std::int64_t totalNs, std::int64_t readNs) {
    std::lock_guard<std::mutex> lock(traces_mutex());
    for (LoadTrace* t : traces())
        if (t->records(t_owner)) t->record_asset(kind, path, bytes, totalNs, readNs);
}

void LoadTrace::scene_requested(std::string scene, std::uint64_t tag) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (tag == 0 || loads_.size() >= kMaxScenes) return;
    SceneLoad l{std::move(scene), now_ns(), -1, 0, 0};
    l.tag = tag;
    l.started = false;
    loads_.push_back(std::move(l));
}

void LoadTrace::load_cancelled(std::uint64_t tag) {
    std::lock_guard<std::mutex> lock(mutex_);
    for (SceneLoad& l : loads_)
        if (tag != 0 && l.tag == tag && !l.started) l.cancelled = true;
}

LoadTrace::SceneLoad* LoadTrace::open_load() {
    for (auto it = loads_.rbegin(); it != loads_.rend(); ++it)
        if (it->started) return it->endNs < 0 ? &*it : nullptr;
    return nullptr;
}

void LoadTrace::scene_started(std::string scene, std::uint64_t tag) {
    std::lock_guard<std::mutex> lock(mutex_);
    SceneLoad* requested = nullptr;
    for (SceneLoad& l : loads_)
        if (tag != 0 && l.tag == tag && !l.started && !l.cancelled) requested = &l;
    if (requested) {
        requested->started = true;
        requested->readyNs = now_ns();
        // Its entry moves to the end: the reads from now on are the started scene's (open_load()).
        SceneLoad moved = std::move(*requested);
        loads_.erase(loads_.begin() + (requested - loads_.data()));
        loads_.push_back(std::move(moved));
    } else if (loads_.size() < kMaxScenes) {
        loads_.push_back(SceneLoad{scene, now_ns(), -1, 0, 0});
    }
    // A scene loaded again keeps its place (scenes stay in first-loaded order); its new files are appended to it.
    auto it = std::find_if(order_.begin(), order_.end(), [&](const SceneFiles& s) { return s.scene == scene; });
    if (it == order_.end()) {
        order_.push_back(SceneFiles{std::move(scene), {}});
        it = order_.end() - 1;
    }
    current_ = std::size_t(it - order_.begin());
}

void LoadTrace::frame_ended() {
    const std::int64_t now = now_ns();
    std::lock_guard<std::mutex> lock(mutex_);
    if (firstFrameNs_ < 0) firstFrameNs_ = now;
    for (SceneLoad& l : loads_)
        if (l.endNs < 0 && l.started) l.endNs = now;
}

void LoadTrace::record_file(std::string_view path, std::uint64_t bytes, std::uint64_t storedBytes, bool fromPack, std::uint64_t aheadTag) {
    std::lock_guard<std::mutex> lock(mutex_);
    ++reads_;
    bytes_ += bytes;
    if (fromPack) {
        ++packReads_;
        packStored_ += storedBytes;
    }
    if (aheadTag != 0) {  // read ahead: counts in its background scene load (if it is one), enters the order when used
        for (SceneLoad& l : loads_)
            if (l.tag == aheadTag && !l.cancelled && (!l.started || l.endNs < 0)) {
                l.files++;
                l.bytes += bytes;
            }
        return;
    }
    if (SceneLoad* l = open_load()) {
        l->files++;
        l->bytes += bytes;
    }
    record_use_locked(path);
}

void LoadTrace::record_use(std::string_view path) {
    std::lock_guard<std::mutex> lock(mutex_);
    record_use_locked(path);
}

void LoadTrace::record_use_locked(std::string_view path) {
    if (seen_.size() >= kMaxFiles) return;
    std::string p(path);
    if (!seen_.insert(p).second) return;
    if (order_.empty()) {  // read before the first scene: the start-up group
        order_.push_back(SceneFiles{kStartupScene, {}});
        current_ = 0;
    }
    order_[current_].files.push_back(std::move(p));
}

void LoadTrace::record_asset(std::string_view kind, std::string_view path, std::uint64_t bytes, std::int64_t totalNs, std::int64_t readNs) {
    const std::int64_t decodeNs = std::max<std::int64_t>(0, totalNs - readNs);
    std::lock_guard<std::mutex> lock(mutex_);
    if (slowest_.size() >= kMaxSlowest && decodeNs + readNs <= slowest_.back().decodeNs + slowest_.back().readNs) return;
    Asset a{std::string(kind), std::string(path), bytes, std::max<std::int64_t>(0, readNs), decodeNs};
    auto at = std::find_if(slowest_.begin(), slowest_.end(), [&](const Asset& s) { return s.decodeNs + s.readNs < a.decodeNs + a.readNs; });
    slowest_.insert(at, std::move(a));
    if (slowest_.size() > kMaxSlowest) slowest_.pop_back();
}

LoadOrder LoadTrace::order() const {
    std::lock_guard<std::mutex> lock(mutex_);
    LoadOrder out;
    for (const SceneFiles& s : order_)
        if (!s.files.empty()) out.push_back(s);
    return out;
}

Json LoadTrace::report() const {
    std::lock_guard<std::mutex> lock(mutex_);
    Json j = Json::object();
    j["timeToFirstFrameMs"] = firstFrameNs_ < 0 ? Json() : Json(round_ms(firstFrameNs_ - startNs_));
    Json scenes = Json::array();
    for (const SceneLoad& l : loads_) {
        Json e = Json::object({{"scene", l.scene},
                               {"loadMs", l.endNs < 0 ? Json() : Json(round_ms(l.endNs - l.startNs))},
                               {"files", l.files},
                               {"bytes", l.bytes}});
        if (l.tag != 0) {  // a background load (scene.load {async: true})
            e["async"] = true;
            e["readyMs"] = l.readyNs < 0 ? Json() : Json(round_ms(l.readyNs - l.startNs));
            if (l.cancelled) e["cancelled"] = true;
        }
        scenes.push_back(std::move(e));
    }
    j["scenes"] = std::move(scenes);
    Json slow = Json::array();
    for (const Asset& a : slowest_)
        slow.push_back(Json::object({{"kind", a.kind}, {"path", a.path}, {"bytes", a.bytes}, {"readMs", round_ms(a.readNs)}, {"decodeMs", round_ms(a.decodeNs)}}));
    j["slowestAssets"] = std::move(slow);
    j["reads"] = Json::object({{"count", reads_}, {"bytes", bytes_}, {"fromPack", packReads_}, {"packStoredBytes", packStored_}});
    j["note"] = "Times are this machine's, rounded to 0.1 ms: compare runs on one machine, never pass or fail on them. A scene's "
                "loadMs runs from the start of its load to the end of the first frame after it; for a background load "
                "(async) from the request, and its readyMs to the frame the scene started.";
    return j;
}

AssetLoadScope::AssetLoadScope(const char* kind, std::string_view path) : kind_(kind) {
    if (!LoadTrace::any()) return;
    path_.assign(path);
    startNs_ = LoadTrace::now_ns();
    readStartNs_ = t_readNs;
    readBytesStart_ = t_readBytes;
}

AssetLoadScope::~AssetLoadScope() {
    if (startNs_ < 0 || !LoadTrace::any()) return;
    const std::int64_t total = LoadTrace::now_ns() - startNs_;
    const std::uint64_t bytes = bytes_ ? bytes_ : t_readBytes - readBytesStart_;
    if (bytes == 0) return;  // read nothing (a built-in font, a primitive mesh, a missing file): not a file load
    LoadTrace::asset_loaded(kind_, path_, bytes, total, t_readNs - readStartNs_);
}

}  // namespace fa
