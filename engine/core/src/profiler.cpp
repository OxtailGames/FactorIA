#include "fa/core/profiler.h"

#include <algorithm>
#include <cmath>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/jobs.h"

namespace fa {

const char* prof_system_name(ProfSystem s) {
    static const char* names[kProfSystemCount] = {
        "platform",      "physics", "scriptsFixedUpdate", "animation",    "scriptsEvents", "ui",
        "scriptsUpdate", "audio",   "scriptsLateUpdate",  "localization", "render",        "endOfFrame"};
    const int i = int(s);
    return i >= 0 && i < kProfSystemCount ? names[i] : "unknown";
}

Profiler& Profiler::get() {
    static Profiler p;
    return p;
}

void Profiler::set_enabled(bool on) {
    if (on == flag_.load(std::memory_order_relaxed)) return;
    flag_.store(on, std::memory_order_relaxed);
    {
        std::lock_guard<std::mutex> lk(jobsMu_);
        jobLanes_.clear();
    }
    cur_ = ProfFrame{};
    last_ = ProfFrame{};
    index_.clear();
    slots_.clear();
    zoneIndex_.clear();
    zoneSlots_.clear();
    budgetSlots_.clear();
    childMs_ = 0;
    frames_ = 0;
    t0_ = 0;
}

void Profiler::begin_frame() {
    if (!on()) return;
    childMs_ = 0;  // cur_, index_ and slots_ are empty: set_enabled and end_frame leave them so
    t0_ = now_ms();
}

void Profiler::end_frame() {
    if (!on()) return;
    cur_.totalMs = now_ms() - t0_;
    std::vector<ProfLane> recorded;
    {
        std::lock_guard<std::mutex> lk(jobsMu_);
        recorded.swap(jobLanes_);
    }
    const int poolLanes = jobs::lane_count();
    for (int lane = 0; lane < jobs::kMaxLanes; ++lane) {
        const bool has = std::size_t(lane) < recorded.size() && recorded[std::size_t(lane)].jobs > 0;
        if (lane >= poolLanes && !has)
            continue;  // every thread of the pool, idle or not; others only when they ran jobs
        ProfLane l = has ? std::move(recorded[std::size_t(lane)]) : ProfLane{};
        l.name = jobs::lane_name(lane);
        std::sort(l.samples.begin(), l.samples.end(), [](const ProfJobSample& a, const ProfJobSample& b) {
            return a.ms != b.ms ? a.ms > b.ms : a.name < b.name;
        });
        cur_.lanes.push_back(std::move(l));
    }
    cur_.classes = std::move(slots_);
    slots_.clear();
    index_.clear();
    std::sort(cur_.classes.begin(), cur_.classes.end(), [](const ProfClassSample& a, const ProfClassSample& b) {
        return a.ms != b.ms ? a.ms > b.ms : a.className < b.className;
    });
    cur_.zones = std::move(zoneSlots_);
    zoneSlots_.clear();
    zoneIndex_.clear();
    std::sort(cur_.zones.begin(), cur_.zones.end(), [](const ProfZoneSample& a, const ProfZoneSample& b) {
        return a.ms != b.ms ? a.ms > b.ms : a.name < b.name;
    });
    cur_.overBudget = std::move(budgetSlots_);
    budgetSlots_.clear();
    std::sort(cur_.overBudget.begin(), cur_.overBudget.end(),
              [](const ProfBudgetSample& a, const ProfBudgetSample& b) { return a.name < b.name; });
    last_ = std::move(cur_);
    cur_ = ProfFrame{};
    ++frames_;
}

void Profiler::add_behaviour(const std::string& className, const std::string& path, double ms) {
    static thread_local std::string key;
    key.assign(path);
    key.push_back('\n');
    key.append(className);
    auto it = index_.find(key);
    if (it == index_.end()) {
        it = index_.emplace(key, slots_.size()).first;
        ProfClassSample s;
        s.className = className;
        s.path = path;
        slots_.push_back(std::move(s));
    }
    ProfClassSample& s = slots_[it->second];
    s.ms += std::max(0.0, ms);
    ++s.calls;
}

void Profiler::add_zone(std::string_view name, double ms) {
    const std::string key(name);
    auto it = zoneIndex_.find(key);
    if (it == zoneIndex_.end()) {
        it = zoneIndex_.emplace(key, zoneSlots_.size()).first;
        ProfZoneSample z;
        z.name = key;
        zoneSlots_.push_back(std::move(z));
    }
    ProfZoneSample& z = zoneSlots_[it->second];
    z.ms += std::max(0.0, ms);
    ++z.calls;
}

void Profiler::add_over_budget(std::string_view name, double ms, double limitMs) {
    for (ProfBudgetSample& b : budgetSlots_) {
        if (b.name == name) {
            b.ms = std::max(b.ms, ms);
            b.limitMs = limitMs;
            return;
        }
    }
    budgetSlots_.push_back(ProfBudgetSample{std::string(name), std::max(0.0, ms), limitMs});
}

void Profiler::add_job(int lane, std::string_view name, double ms, int count) {
    if (lane < 0 || lane >= jobs::kMaxLanes) lane = jobs::lane_other();
    count = std::max(count, 0);
    std::lock_guard<std::mutex> lk(jobsMu_);
    if (jobLanes_.size() <= std::size_t(lane)) jobLanes_.resize(std::size_t(lane) + 1);
    ProfLane& l = jobLanes_[std::size_t(lane)];
    ms = std::max(0.0, ms);
    l.jobMs += ms;
    l.jobs += count;
    for (ProfJobSample& j : l.samples) {
        if (j.name == name) {
            j.ms += ms;
            j.count += count;
            return;
        }
    }
    l.samples.push_back(ProfJobSample{std::string(name), ms, count});
}

// ---------------------------------------------------------------------------------------------------------------- summary
void ProfileSummary::Acc::add(double v) {
    ++n;
    sum += v;
    max = std::max(max, v);
    if (window.size() < kMaxWindow) {
        window.push_back(float(v));
    } else {
        window[head] = float(v);
        head = (head + 1) % kMaxWindow;
    }
}

double ProfileSummary::Acc::p95() const {
    if (window.empty()) return 0;
    std::vector<float> v = window;
    std::sort(v.begin(), v.end());
    return v[std::size_t(std::ceil(0.95 * double(v.size()))) - 1];
}

void ProfileSummary::add_frame(const ProfFrame& f) {
    ++frames_;
    frame_.add(f.totalMs);
    if (f.latencyMs >= 0) latency_.add(f.latencyMs);
    for (int i = 0; i < kProfSystemCount; ++i) systems_[std::size_t(i)].add(f.systemMs[std::size_t(i)]);
    for (const ProfClassSample& c : f.classes) {
        ClassAcc& a = classes_[c.path + "\n" + c.className];
        a.className = c.className;
        a.path = c.path;
        a.sumMs += c.ms;
        a.maxMs = std::max(a.maxMs, c.ms);
        a.calls += std::uint64_t(c.calls);
    }
    for (const ProfZoneSample& z : f.zones) {
        ZoneAcc& a = zones_[z.name];
        a.sumMs += z.ms;
        a.maxMs = std::max(a.maxMs, z.ms);
        a.calls += std::uint64_t(z.calls);
    }
    for (const ProfBudgetSample& b : f.overBudget) {
        BudgetAcc& a = budgets_[b.name];
        a.limitMs = b.limitMs;
        a.maxMs = std::max(a.maxMs, b.ms);
        ++a.frames;
    }
    for (const ProfLane& l : f.lanes) {
        auto it = std::find_if(lanes_.begin(), lanes_.end(), [&](const LaneAcc& a) { return a.name == l.name; });
        if (it == lanes_.end()) {
            lanes_.push_back(LaneAcc{});
            it = lanes_.end() - 1;
            it->name = l.name;
        }
        it->sumMs += l.jobMs;
        it->maxMs = std::max(it->maxMs, l.jobMs);
        it->jobs += std::uint64_t(l.jobs);
        for (const ProfJobSample& j : l.samples) {
            JobAcc& a = it->byName[j.name];
            a.sumMs += j.ms;
            a.maxMs = std::max(a.maxMs, j.ms);
            a.count += std::uint64_t(j.count);
        }
    }
}

void ProfileSummary::add_gpu_ms(double ms) { gpu_.add(ms); }

void ProfileSummary::set_latency_status(const std::string& driver, const std::string& reason) {
    latencyDriver_ = driver;
    latencyReason_ = reason;
}

void ProfileSummary::set_frame_generation(const Json& readout) { frameGeneration_ = readout; }

void ProfileSummary::set_gpu_status(bool supported, const std::string& reason) {
    gpuSupported_ = supported;
    gpuReason_ = reason;
}

void ProfileSummary::add_memory(const ProfMemory& m) {
    if (!haveMemory_) {
        memStart_ = m;
        memPeak_ = m;
        haveMemory_ = true;
    }
    memEnd_ = m;
    memPeak_.processBytes = std::max({memPeak_.processBytes, m.processBytes, m.peakProcessBytes});
    memPeak_.jsHeapBytes = std::max(memPeak_.jsHeapBytes, m.jsHeapBytes);
    memPeak_.textureBytes = std::max(memPeak_.textureBytes, m.textureBytes);
    memPeak_.audioDecodedBytes = std::max(memPeak_.audioDecodedBytes, m.audioDecodedBytes);
    memPeak_.musicBytes = std::max(memPeak_.musicBytes, m.musicBytes);
    memPeak_.entities = std::max(memPeak_.entities, m.entities);
}

namespace {
double r3(double v) { return std::round(v * 1000.0) / 1000.0; }
double r1(double v) { return std::round(v * 10.0) / 10.0; }
double mb(std::uint64_t b) { return std::round(double(b) / (1024.0 * 1024.0) * 100.0) / 100.0; }
Json mem_json(const ProfMemory& m) {
    return Json::object({{"processMB", mb(m.processBytes)},
                         {"jsHeapMB", mb(m.jsHeapBytes)},
                         {"textureMB", mb(m.textureBytes)},
                         {"audioDecodedMB", mb(m.audioDecodedBytes)},
                         {"musicMB", mb(m.musicBytes)},
                         {"entities", m.entities}});
}
}  // namespace

Json ProfileSummary::to_json() const {
    Json out = Json::object();
    const double n = double(std::max(1, frames_));
    out["frames"] = frames_;
    out["clock"] = "wall";
    out["frameMs"] = Json::object({{"avg", r3(frame_.sum / n)}, {"p95", r3(frame_.p95())}, {"max", r3(frame_.max)}});
    Json sys = Json::object();
    for (int i = 0; i < kProfSystemCount; ++i) {
        const Acc& a = systems_[std::size_t(i)];
        sys[prof_system_name(ProfSystem(i))] =
            Json::object({{"avgMs", r3(a.sum / n)}, {"p95Ms", r3(a.p95())}, {"maxMs", r3(a.max)}});
    }
    out["systems"] = sys;
    std::vector<const ClassAcc*> list;
    for (const auto& kv : classes_) list.push_back(&kv.second);
    std::sort(list.begin(), list.end(), [](const ClassAcc* a, const ClassAcc* b) {
        if (a->sumMs != b->sumMs) return a->sumMs > b->sumMs;
        return a->className != b->className ? a->className < b->className : a->path < b->path;
    });
    Json cls = Json::array();
    for (std::size_t i = 0; i < list.size() && i < kMaxClasses; ++i) {
        const ClassAcc& c = *list[i];
        cls.push_back(Json::object({{"class", c.className},
                                    {"path", c.path},
                                    {"avgMs", r3(c.sumMs / n)},
                                    {"maxMs", r3(c.maxMs)},
                                    {"callsPerFrame", r3(double(c.calls) / n)}}));
    }
    out["behaviours"] = cls;
    std::vector<std::pair<const std::string*, const ZoneAcc*>> zoneList;
    for (const auto& kv : zones_) zoneList.emplace_back(&kv.first, &kv.second);
    std::sort(zoneList.begin(), zoneList.end(), [](const auto& a, const auto& b) {
        return a.second->sumMs != b.second->sumMs ? a.second->sumMs > b.second->sumMs : *a.first < *b.first;
    });
    Json zones = Json::array();
    for (std::size_t i = 0; i < zoneList.size() && i < kMaxZones; ++i)
        zones.push_back(Json::object({{"name", *zoneList[i].first},
                                      {"avgMs", r3(zoneList[i].second->sumMs / n)},
                                      {"maxMs", r3(zoneList[i].second->maxMs)},
                                      {"callsPerFrame", r3(double(zoneList[i].second->calls) / n)}}));
    out["zones"] = zones;
    std::vector<std::pair<const std::string*, const BudgetAcc*>> budgetList;
    for (const auto& kv : budgets_) budgetList.emplace_back(&kv.first, &kv.second);
    std::sort(budgetList.begin(), budgetList.end(), [](const auto& a, const auto& b) { return *a.first < *b.first; });
    Json over = Json::array();
    for (const auto& b : budgetList)
        over.push_back(Json::object({{"name", *b.first},
                                     {"limitMs", r3(b.second->limitMs)},
                                     {"frames", b.second->frames},
                                     {"maxMs", r3(b.second->maxMs)}}));
    out["overBudget"] = over;
    Json threads = Json::array();
    for (const LaneAcc& l : lanes_) {
        std::vector<std::pair<const std::string*, const JobAcc*>> names;
        for (const auto& kv : l.byName) names.emplace_back(&kv.first, &kv.second);
        std::sort(names.begin(), names.end(), [](const auto& a, const auto& b) {
            return a.second->sumMs != b.second->sumMs ? a.second->sumMs > b.second->sumMs : *a.first < *b.first;
        });
        Json laneJobs = Json::array();
        for (std::size_t i = 0; i < names.size() && i < kMaxLaneJobs; ++i)
            laneJobs.push_back(Json::object({{"name", *names[i].first},
                                             {"avgMs", r3(names[i].second->sumMs / n)},
                                             {"maxMs", r3(names[i].second->maxMs)},
                                             {"callsPerFrame", r3(double(names[i].second->count) / n)}}));
        const double busy = frame_.sum > 0 ? std::min(100.0, l.sumMs / frame_.sum * 100.0) : 0.0;
        threads.push_back(Json::object({{"name", l.name},
                                        {"jobMsAvg", r3(l.sumMs / n)},
                                        {"jobMsMax", r3(l.maxMs)},
                                        {"busyPct", r1(busy)},
                                        {"jobsPerFrame", r3(double(l.jobs) / n)},
                                        {"jobs", laneJobs}}));
    }
    out["threads"] = threads;
    Json gpu = Json::object();
    if (gpu_.n > 0) {
        gpu["avgMs"] = r3(gpu_.sum / double(gpu_.n));
        gpu["p95Ms"] = r3(gpu_.p95());
        gpu["maxMs"] = r3(gpu_.max);
        gpu["samples"] = gpu_.n;
        gpu["reason"] = nullptr;
    } else {
        gpu["avgMs"] = nullptr;
        gpu["p95Ms"] = nullptr;
        gpu["maxMs"] = nullptr;
        gpu["samples"] = 0;
        gpu["reason"] =
            gpuSupported_
                ? "no GPU time came back (results arrive a few frames late: the run was too short or drew nothing)"
                : gpuReason_;
    }
    out["gpu"] = gpu;
    // The input-to-present time (M78, docs/LATENCY.md): the span from the input sample to the end of the present call, per frame.
    Json latency = Json::object();
    latency["driver"] = latencyDriver_;
    if (latency_.n > 0) {
        latency["avgMs"] = r3(latency_.sum / double(latency_.n));
        latency["p95Ms"] = r3(latency_.p95());
        latency["maxMs"] = r3(latency_.max);
        latency["samples"] = latency_.n;
        latency["reason"] = nullptr;
    } else {
        latency["avgMs"] = nullptr;
        latency["p95Ms"] = nullptr;
        latency["maxMs"] = nullptr;
        latency["samples"] = 0;
        latency["reason"] = latencyReason_;
    }
    out["latency"] = latency;
    // Frame generation (M78, docs/FRAME_GENERATION.md): what the provider did while this was measured.
    if (frameGeneration_.is_object()) {
        out["frameGeneration"] = frameGeneration_;
    } else {
        Json fg = Json::object();
        fg["provider"] = "none";
        fg["state"] = "off";
        fg["generating"] = false;
        fg["baseFps"] = 0.0;
        fg["presentedFps"] = 0.0;
        fg["renderedFrames"] = 0;
        fg["generatedFrames"] = 0;
        fg["reason"] = "the frame generation was not measured";
        out["frameGeneration"] = fg;
    }
    Json mem = Json::object();
    if (haveMemory_) {
        mem["start"] = mem_json(memStart_);
        mem["end"] = mem_json(memEnd_);
        mem["peak"] = mem_json(memPeak_);
    }
    out["memory"] = mem;
    return out;
}

}  // namespace fa
