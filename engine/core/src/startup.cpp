#include "fa/core/startup.h"

#include <algorithm>
#include <chrono>
#include <cmath>

#include "fa/core/fs.h"
#include "fa/core/perf.h"

namespace fa {

namespace {
using Clock = std::chrono::steady_clock;
// Set while this library is initialized, i.e. at the start of the process.
const Clock::time_point g_processStart = Clock::now();
double round1(double v) { return std::round(v * 10.0) / 10.0; }
}  // namespace

double StartupTimeline::process_ms_now() {
    return std::chrono::duration<double, std::milli>(Clock::now() - g_processStart).count();
}

const char* StartupTimeline::name(Mark m) {
    switch (m) {
        case Mark::WindowReady: return "windowReady";
        case Mark::FirstPresent: return "firstPresent";
        case Mark::InitBegin: return "initBegin";
        case Mark::InitEnd: return "initEnd";
        case Mark::WarmEnd: return "warmEnd";
        case Mark::FirstGameFrame: return "firstGameFrame";
        case Mark::Count: break;
    }
    return "?";
}

void StartupTimeline::mark(Mark m) {
    if (m == Mark::Count) return;
    const double wall = process_ms_now();
    const double cpu = process_cpu_seconds() * 1000.0;
    const std::uint64_t reads = fs::disk_reads();
    std::lock_guard<std::mutex> lock(mutex_);
    Slot& s = slots_[std::size_t(m)];
    if (s.set) return;
    s = Slot{true, wall, cpu, reads};
    order_.push_back(m);
}

bool StartupTimeline::has(Mark m) const {
    std::lock_guard<std::mutex> lock(mutex_);
    return m != Mark::Count && slots_[std::size_t(m)].set;
}
double StartupTimeline::wall_ms(Mark m) const {
    std::lock_guard<std::mutex> lock(mutex_);
    return m != Mark::Count && slots_[std::size_t(m)].set ? slots_[std::size_t(m)].wallMs : -1.0;
}
double StartupTimeline::cpu_ms(Mark m) const {
    std::lock_guard<std::mutex> lock(mutex_);
    return m != Mark::Count && slots_[std::size_t(m)].set ? slots_[std::size_t(m)].cpuMs : -1.0;
}
std::uint64_t StartupTimeline::disk_reads(Mark m) const {
    std::lock_guard<std::mutex> lock(mutex_);
    return m != Mark::Count && slots_[std::size_t(m)].set ? slots_[std::size_t(m)].reads : 0;
}
std::vector<StartupTimeline::Mark> StartupTimeline::order() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return order_;
}

double StartupTimeline::startup_cpu_ms() const {
    const double a = cpu_ms(Mark::InitBegin), b = cpu_ms(Mark::FirstGameFrame);
    return a < 0 || b < 0 ? -1.0 : std::max(0.0, b - a);
}

Json StartupTimeline::to_json() const {
    auto ms_or_null = [&](Mark m) { return has(m) ? Json(round1(wall_ms(m))) : Json(nullptr); };
    auto span_or_null = [&](Mark a, Mark b) {
        return has(a) && has(b) ? Json(round1(std::max(0.0, wall_ms(b) - wall_ms(a)))) : Json(nullptr);
    };
    Json j = Json::object();
    j["firstPresentMs"] = ms_or_null(Mark::FirstPresent);
    j["firstGameFrameMs"] = ms_or_null(Mark::FirstGameFrame);
    j["windowReadyMs"] = ms_or_null(Mark::WindowReady);
    j["initMs"] = span_or_null(Mark::InitBegin, Mark::InitEnd);
    j["warmupMs"] = span_or_null(Mark::InitEnd, Mark::WarmEnd);
    const double cpu = startup_cpu_ms();
    j["startupCpuMs"] = cpu < 0 ? Json(nullptr) : Json(round1(cpu));
    j["diskReadsAtFirstPresent"] = has(Mark::FirstPresent) ? Json(disk_reads(Mark::FirstPresent)) : Json(nullptr);
    j["diskReadsAtFirstGameFrame"] = has(Mark::FirstGameFrame) ? Json(disk_reads(Mark::FirstGameFrame)) : Json(nullptr);
    Json order = Json::array();
    for (Mark m : this->order()) order.push_back(name(m));
    j["order"] = std::move(order);
    return j;
}

}  // namespace fa
