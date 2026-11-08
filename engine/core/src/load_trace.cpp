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

LoadTrace::ReadingFor::ReadingFor(Owner owner) : previous_(t_owner) { t_owner = owner; }
LoadTrace::ReadingFor::~ReadingFor() { t_owner = previous_; }

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
    std::lock_guard<std::mutex> lock(traces_mutex());
    for (LoadTrace* t : traces())
        if (t->records(t_owner)) t->record_file(path, bytes, storedBytes, fromPack);
}

void LoadTrace::asset_loaded(std::string_view kind, std::string_view path, std::uint64_t bytes, std::int64_t totalNs, std::int64_t readNs) {
    std::lock_guard<std::mutex> lock(traces_mutex());
    for (LoadTrace* t : traces())
        if (t->records(t_owner)) t->record_asset(kind, path, bytes, totalNs, readNs);
}

void LoadTrace::scene_started(std::string scene) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (loads_.size() < kMaxScenes) loads_.push_back(SceneLoad{scene, now_ns(), -1, 0, 0});
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
        if (l.endNs < 0) l.endNs = now;
}

void LoadTrace::record_file(std::string_view path, std::uint64_t bytes, std::uint64_t storedBytes, bool fromPack) {
    std::lock_guard<std::mutex> lock(mutex_);
    ++reads_;
    bytes_ += bytes;
    if (fromPack) {
        ++packReads_;
        packStored_ += storedBytes;
    }
    if (!loads_.empty() && loads_.back().endNs < 0) {
        loads_.back().files++;
        loads_.back().bytes += bytes;
    }
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
    for (const SceneLoad& l : loads_)
        scenes.push_back(Json::object({{"scene", l.scene},
                                       {"loadMs", l.endNs < 0 ? Json() : Json(round_ms(l.endNs - l.startNs))},
                                       {"files", l.files},
                                       {"bytes", l.bytes}}));
    j["scenes"] = std::move(scenes);
    Json slow = Json::array();
    for (const Asset& a : slowest_)
        slow.push_back(Json::object({{"kind", a.kind}, {"path", a.path}, {"bytes", a.bytes}, {"readMs", round_ms(a.readNs)}, {"decodeMs", round_ms(a.decodeNs)}}));
    j["slowestAssets"] = std::move(slow);
    j["reads"] = Json::object({{"count", reads_}, {"bytes", bytes_}, {"fromPack", packReads_}, {"packStoredBytes", packStored_}});
    j["note"] = "Times are this machine's, rounded to 0.1 ms: compare runs on one machine, never pass or fail on them. A scene's "
                "loadMs runs from the start of its load to the end of the first frame after it.";
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
