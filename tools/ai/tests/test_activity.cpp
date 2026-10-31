
#include <filesystem>
#include <fstream>

#include "fa/ai/activity.h"
#include "test_common.h"

using namespace fa;
using namespace fa::ai;

namespace {
ProcessEntry proc(long long pid, double cpu, const char* name = "claude") { return {pid, 1, name, cpu}; }
}  // namespace

TEST_CASE("activity: CpuSampler measures the CPU use between samples") {
    CpuSampler s;
    CHECK(s.percent() == -1);  // no samples
    s.add(0, {proc(10, 5.0)});
    CHECK(s.percent() == -1);  // one sample
    s.add(1, {proc(10, 5.5)});
    CHECK(s.percent() == -1);  // too close together to say anything
    s.add(10, {proc(10, 9.5)});
    CHECK(s.percent() == doctest::Approx(45.0));  // 4.5 s of CPU in 10 s
    // A process that appears counts with all its CPU time; one that vanishes counts for nothing.
    s.add(20, {proc(11, 3.0, "cmake")});
    CHECK(s.percent() > 0);
    CpuSampler unknown;
    unknown.add(0, {proc(10, -1)});
    unknown.add(10, {proc(10, -1)});
    CHECK(unknown.percent() == -1);  // the OS did not say
}

TEST_CASE("activity: CpuSampler forgets samples older than its window") {
    CpuSampler s(30);
    for (int t = 0; t <= 100; t += 10) s.add(t, {proc(10, t * 0.1)});
    CHECK(s.span() <= 40);
    CHECK(s.percent() == doctest::Approx(10.0));
}

TEST_CASE("activity: the verdict says still working while a tool burns CPU") {
    ActivityInput in;
    in.runSeconds = 600;
    in.idleSeconds = 200;
    in.tool = "running Bash (cmake --build)";
    in.toolSeconds = 240;
    in.trackedProcess = true;
    in.roots = 1;
    in.processes = {proc(10, 20), proc(11, 80, "cmake")};
    in.cpuPercent = 85;
    in.cpuWindowSeconds = 30;
    in.changesWithinSeconds = 120;
    ActivityVerdict v = judge_activity(in);
    CHECK_FALSE(v.stuck);
    CHECK(v.summary.rfind("Still working: running Bash (cmake --build) for 4 min", 0) == 0);
    CHECK(v.summary.find("CPU 85%") != std::string::npos);
    CHECK(v.summary.find("1 child process") != std::string::npos);
    CHECK(v.details.size() >= 5);
}

TEST_CASE("activity: the verdict says stuck for a live but idle process with no tool") {
    ActivityInput in;
    in.runSeconds = 900;
    in.idleSeconds = 360;
    in.trackedProcess = true;
    in.roots = 1;
    in.processes = {proc(10, 20)};
    in.cpuPercent = 0;
    in.cpuWindowSeconds = 60;
    in.changesWithinSeconds = 120;
    ActivityVerdict v = judge_activity(in);
    CHECK(v.stuck);
    CHECK_FALSE(v.processGone);
    CHECK(v.summary.rfind("Looks stuck: process alive but idle (0% CPU) for 6 min, no tool in flight", 0) == 0);
    // Files changing in the project mean the agent (or its tool) is writing: not stuck.
    in.changes.count = 3;
    in.changes.newest = "scripts/a.js";
    in.changes.newestAgoSeconds = 20;
    CHECK_FALSE(judge_activity(in).stuck);
}

TEST_CASE("activity: a gone process, no process to inspect, and unknown CPU degrade gracefully") {
    ActivityInput gone;
    gone.trackedProcess = true;
    gone.idleSeconds = 100;
    gone.roots = 1;
    ActivityVerdict v = judge_activity(gone);
    CHECK(v.processGone);
    CHECK(v.stuck);
    CHECK(v.summary.find("process is gone") != std::string::npos);

    ActivityInput api;  // an API provider: nothing to look at
    api.idleSeconds = 200;
    v = judge_activity(api);
    CHECK_FALSE(v.processGone);
    CHECK(v.summary.find("Cannot look inside") != std::string::npos);

    ActivityInput nocpu;
    nocpu.trackedProcess = true;
    nocpu.roots = 1;
    nocpu.processes = {proc(10, -1)};
    nocpu.idleSeconds = 500;
    nocpu.cpuPercent = -1;
    v = judge_activity(nocpu);
    CHECK(v.stuck);  // alive, nothing says it works
    bool saidUnknown = false;
    for (const auto& d : v.details) saidUnknown = saidUnknown || d.find("not known") != std::string::npos;
    CHECK(saidUnknown);
}

TEST_CASE("activity: format_duration") {
    CHECK(format_duration(35) == "35 s");
    CHECK(format_duration(240) == "4 min");
    CHECK(format_duration(3900) == "1 h 05 min");
    CHECK(format_duration(-3) == "0 s");
}

TEST_CASE("activity: recent_file_changes finds fresh files and skips .git") {
    namespace sfs = std::filesystem;
    const sfs::path dir = sfs::temp_directory_path() / "fa_activity_test";
    sfs::remove_all(dir);
    sfs::create_directories(dir / "scripts");
    sfs::create_directories(dir / ".git");
    std::ofstream(dir / "scripts" / "a.js") << "x";
    std::ofstream(dir / ".git" / "HEAD") << "x";
    std::ofstream(dir / "old.txt") << "x";
    sfs::last_write_time(dir / "old.txt", sfs::file_time_type::clock::now() - std::chrono::hours(2));
    RecentChanges c = recent_file_changes(dir.string(), 120);
    CHECK(c.count == 1);
    CHECK(c.newest == "scripts/a.js");
    CHECK(c.newestAgoSeconds >= 0);
    CHECK(c.complete);
    CHECK(recent_file_changes((dir / "missing").string(), 120).count == 0);
    CHECK(recent_file_changes(dir.string(), 120, 1).complete == false);  // gave up
    sfs::remove_all(dir);
}
