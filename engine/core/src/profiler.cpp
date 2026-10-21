#include "fa/core/profiler.h"

#include <algorithm>
#include <cmath>

namespace fa {

const char* prof_system_name(ProfSystem s) {
    static const char* names[kProfSystemCount] = {"platform",      "physics", "scriptsFixedUpdate", "animation",
                                                  "scriptsEvents", "ui",      "scriptsUpdate",      "audio",
                                                  "scriptsLateUpdate", "localization", "render",     "endOfFrame"};
    const int i = int(s);
    return i >= 0 && i < kProfSystemCount ? names[i] : "unknown";
}

Profiler& Profiler::get() {
    static Profiler p;
    return p;
}

void Profiler::set_enabled(bool on) {
    if (on == flag_) return;
    flag_ = on;
    cur_ = ProfFrame{};
    last_ = ProfFrame{};
    index_.clear();
    slots_.clear();
    childMs_ = 0;
    frames_ = 0;
    t0_ = 0;
}

void Profiler::begin_frame() {
    if (!flag_) return;
    childMs_ = 0;  // cur_, index_ and slots_ are empty: set_enabled and end_frame leave them so
    t0_ = now_ms();
}

void Profiler::end_frame() {
    if (!flag_) return;
    cur_.totalMs = now_ms() - t0_;
    cur_.classes = std::move(slots_);
    slots_.clear();
    index_.clear();
    std::sort(cur_.classes.begin(), cur_.classes.end(), [](const ProfClassSample& a, const ProfClassSample& b) {
        return a.ms != b.ms ? a.ms > b.ms : a.className < b.className;
    });
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
    for (int i = 0; i < kProfSystemCount; ++i) systems_[std::size_t(i)].add(f.systemMs[std::size_t(i)]);
    for (const ProfClassSample& c : f.classes) {
        ClassAcc& a = classes_[c.path + "\n" + c.className];
        a.className = c.className;
        a.path = c.path;
        a.sumMs += c.ms;
        a.maxMs = std::max(a.maxMs, c.ms);
        a.calls += std::uint64_t(c.calls);
    }
}

void ProfileSummary::add_gpu_ms(double ms) { gpu_.add(ms); }

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
    memPeak_.entities = std::max(memPeak_.entities, m.entities);
}

namespace {
double r3(double v) { return std::round(v * 1000.0) / 1000.0; }
double mb(std::uint64_t b) { return std::round(double(b) / (1024.0 * 1024.0) * 100.0) / 100.0; }
Json mem_json(const ProfMemory& m) {
    return Json::object({{"processMB", mb(m.processBytes)}, {"jsHeapMB", mb(m.jsHeapBytes)}, {"textureMB", mb(m.textureBytes)},
                         {"audioDecodedMB", mb(m.audioDecodedBytes)}, {"entities", m.entities}});
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
        sys[prof_system_name(ProfSystem(i))] = Json::object({{"avgMs", r3(a.sum / n)}, {"p95Ms", r3(a.p95())}, {"maxMs", r3(a.max)}});
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
        cls.push_back(Json::object({{"class", c.className}, {"path", c.path}, {"avgMs", r3(c.sumMs / n)}, {"maxMs", r3(c.maxMs)},
                                    {"callsPerFrame", r3(double(c.calls) / n)}}));
    }
    out["behaviours"] = cls;
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
        gpu["reason"] = gpuSupported_ ? "no GPU time came back (results arrive a few frames late: the run was too short or drew nothing)"
                                      : gpuReason_;
    }
    out["gpu"] = gpu;
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
