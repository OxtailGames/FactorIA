// The window title and the Export window's logic (export_job.h): which platforms it offers, the options a button
// exports with, each row's check (fa::plan_export) and the export on its worker thread (fa::export_project).
// GPU-free: a scaffolded project in a temporary folder and a stand-in player, like the export tests of fa_test_tooling.
#include <algorithm>
#include <chrono>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <thread>

#include "doctest.h"
#include "editor_internal.h"

using namespace fa;
using namespace fa::editor;
namespace stdfs = std::filesystem;

namespace {

struct TempProject {
    stdfs::path root, dir;
    explicit TempProject(const std::string& name) {
        root = fs::make_temp_dir("fa_editor_export_" + name);
        ScaffoldOptions so;
        so.name = "Export Test";
        so.id = "com.example.exporttest";
        auto r = create_project((root / "game").string(), "2d-empty", so);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        dir = stdfs::weakly_canonical(r->dir);
    }
    ~TempProject() {
        std::error_code ec;
        stdfs::remove_all(root, ec);
    }
    std::string player() const {  // a stand-in factoria_player: the export only copies it
        const stdfs::path p = root / "players" / "factoria_player";
        stdfs::create_directories(p.parent_path());
        std::ofstream(p, std::ios::binary) << "#!/bin/sh\nexit 0\n";
        return p.string();
    }
};

bool same_path(const std::string& a, const stdfs::path& b) {
    std::error_code ec;
    return stdfs::weakly_canonical(a, ec) == stdfs::weakly_canonical(b, ec);
}

const std::string kHost = normalize_export_platform("");
const std::string kOtherDesktop = kHost == "windows" ? "linux" : "windows";

}  // namespace

TEST_CASE("window title: the engine version, then the open project") {
    CHECK(editor_window_title("0.1.3", "Space Dodge") == "FactorIA 0.1.3 \xE2\x80\x94 Space Dodge");
    CHECK(editor_window_title("0.1.3", "") == "FactorIA 0.1.3");  // the Open or create a project dialog
    // The same version `factoria version` prints: the CMake project(VERSION).
    CHECK(editor_window_title(FA_ENGINE_VERSION, "") == std::string("FactorIA ") + FA_ENGINE_VERSION);
    CHECK(std::string(FA_ENGINE_VERSION).find('.') != std::string::npos);
}

TEST_CASE("export window: a button per platform, desktop first") {
    const auto& t = export_targets();
    REQUIRE(t.size() == 5);
    std::vector<std::string> names;
    for (const ExportTarget& e : t) names.push_back(e.platform);
    CHECK(names == std::vector<std::string>{"windows", "macos", "linux", "android", "ios"});
    for (const ExportTarget& e : t) {
        CHECK(normalize_export_platform(e.platform) == e.platform);  // a name export_project knows
        CHECK(e.mobile == (std::string(e.platform) == "android" || std::string(e.platform) == "ios"));
        CHECK_FALSE(export_target_note(e).empty());
    }
    CHECK(std::string(find_export_target("Win")->label) == "Windows");
    CHECK(find_export_target("amiga") == nullptr);
    CHECK(export_target_note(*find_export_target("ios")).find("Xcode") != std::string::npos);

    // Android's note says what the project's format builds.
    const ExportTarget& android = *find_export_target("android");
    CHECK(export_target_note(android, "apk").find("APK") != std::string::npos);
    CHECK(export_target_note(android).find("APK") != std::string::npos);  // no format: the default one
    CHECK(export_target_note(android, "aab").find("bundle") != std::string::npos);
    CHECK(export_target_note(android, "gradle").find("nothing is built") != std::string::npos);
    CHECK(export_format_label("apk") == "APK");
    CHECK(export_format_label("aab") == "AAB");
    CHECK(export_format_label("gradle") == "Gradle project");
    CHECK(export_format_label("").empty());
    CHECK(export_format_label("zip").empty());

    // Only another OS's desktop export needs a player chosen by hand.
    CHECK_FALSE(export_needs_player(kHost));
    CHECK(export_needs_player(kOtherDesktop));
    CHECK_FALSE(export_needs_player("android"));
    CHECK_FALSE(export_needs_player("ios"));
}

TEST_CASE("export window: the options a button exports with") {
    const std::string project = (stdfs::temp_directory_path() / "my-game").generic_string();
    ExportSettings s;
    ExportOptions o = export_options(project, "macos", s);
    CHECK(o.projectDir == project);
    CHECK(o.platform == "macos");
    CHECK(o.outDir == project + "/build/export");  // the default, spelled out so the window can show it
    CHECK(export_parent_dir(project, s) == o.outDir);
    CHECK_FALSE(o.release);
    CHECK(o.playerBinary.empty());
    CHECK(o.engineRoot.empty());
    CHECK(o.mobileDir.empty());

    s.outDir = "dist";  // relative: to the project
    s.release = true;
    s.players["windows"] = "/downloads/factoria-windows/factoria_player.exe";
    CHECK(export_options(project, "macos", s).outDir == project + "/dist");
    CHECK(export_options(project, "macos", s).release);
    CHECK(export_options(project, "macos", s).playerBinary.empty());  // the Windows player is only for Windows
    CHECK(export_options(project, "Win", s).playerBinary == s.players["windows"]);

    const std::string elsewhere = (stdfs::temp_directory_path() / "exports").generic_string();
    s.outDir = elsewhere;  // absolute: as chosen
    CHECK(export_options(project, "linux", s).outDir == elsewhere);
}

TEST_CASE("export window: each row says what an export writes, or why it cannot run here") {
    TempProject p("rows");
    ExportSettings s;
    s.outDir = (p.root / "out").string();
    s.players[kHost] = p.player();  // this machine's player, without depending on a built factoria_player

    ExportStatus host = check_export(export_options(p.dir.string(), kHost, s));
    REQUIRE_MESSAGE(host.ready, host.error);
    CHECK(same_path(host.plan.outputDir, p.root / "out" / ("export-test-" + kHost)));
    CHECK(same_path(host.plan.player, s.players[kHost]));
    CHECK_FALSE(stdfs::exists(p.root / "out"));  // a check writes nothing

    // Another OS without a player built there: the engine's teaching error, and the window offers Choose player...
    ExportStatus other = check_export(export_options(p.dir.string(), kOtherDesktop, s));
    CHECK_FALSE(other.ready);
    CHECK(other.error.find("cannot export for " + kOtherDesktop) != std::string::npos);
    CHECK_FALSE(other.hint.empty());
    CHECK(export_error_text(other.error).rfind("cannot export", 0) == 0);  // shown without the "export: " prefix
    s.players[kOtherDesktop] = p.player();
    CHECK(check_export(export_options(p.dir.string(), kOtherDesktop, s)).ready);

    // Mobile needs a reverse-DNS id: a project without one says so before anything is written.
    std::string json;
    {
        std::ifstream in(p.dir / "factoria.json", std::ios::binary);
        json.assign(std::istreambuf_iterator<char>(in), {});
    }
    const auto pos = json.find("com.example.exporttest");
    REQUIRE(pos != std::string::npos);
    json.replace(pos, 22, "exporttest");
    std::ofstream(p.dir / "factoria.json", std::ios::binary) << json;
    ExportStatus android = check_export(export_options(p.dir.string(), "android", s));
    CHECK_FALSE(android.ready);
    CHECK(android.error.find("reverse-DNS") != std::string::npos);
    CHECK_FALSE(android.hint.empty());
}

TEST_CASE("export window: a button press exports on a worker thread and reports the result") {
    TempProject p("run");
    ExportSettings s;
    s.outDir = (p.root / "out").string();
    s.players[kHost] = p.player();
    const ExportOptions o = export_options(p.dir.string(), kHost, s);
    const ExportStatus before = check_export(o);
    REQUIRE(before.ready);

    ExportJob job;
    CHECK_FALSE(job.take_result().has_value());  // nothing ran yet
    REQUIRE(job.start(o));
    CHECK(job.platform() == kHost);
    std::optional<ExportOutcome> done;
    for (int i = 0; i < 3000 && !done; ++i) {
        done = job.take_result();
        if (!done) std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
    REQUIRE(done.has_value());
    CHECK_FALSE(job.running());
    CHECK_FALSE(job.take_result().has_value());  // once
    REQUIRE_MESSAGE(done->ok, done->error);
    CHECK(done->platform == kHost);
    CHECK(done->report.outputDir == before.plan.outputDir);  // the folder the row announced
    CHECK(stdfs::exists(stdfs::path(done->report.outputDir) / done->report.notices));
    CHECK_FALSE(done->report.nextSteps.empty());
    CHECK(done->seconds >= 0);

    const std::string summary = export_summary(*done);
    CHECK(summary.find(find_export_target(kHost)->label) != std::string::npos);
    CHECK(summary.find(done->report.outputDir) != std::string::npos);
    const std::string text = export_report_text(*done);
    CHECK(text.find("Output folder: " + done->report.outputDir) != std::string::npos);
    for (const std::string& step : done->report.nextSteps) CHECK(text.find(step) != std::string::npos);

    // A failing export keeps the engine's message and hint.
    ExportOptions bad = o;
    bad.platform = kOtherDesktop;
    bad.playerBinary.clear();
    REQUIRE(job.start(bad));
    job.wait();
    std::optional<ExportOutcome> failed = job.take_result();
    REQUIRE(failed.has_value());
    CHECK_FALSE(failed->ok);
    CHECK(failed->error.find("cannot export for") != std::string::npos);
    CHECK_FALSE(failed->hint.empty());
    CHECK(export_summary(*failed).find("failed") != std::string::npos);
    CHECK(export_report_text(*failed).find("How to fix it: " + failed->hint) != std::string::npos);
}

TEST_CASE("export window: Android writes a Gradle project whose next steps say how to build it") {
    TempProject p("android");
    // The project's own format decides (ExportOptions::format stays empty): Gradle project only, so no Gradle build runs here.
    REQUIRE(save_android_format(p.dir.string(), "gradle").ok());
    ExportSettings s;
    s.outDir = (p.root / "out").string();
    const ExportOptions o = export_options(p.dir.string(), "android", s);
    const ExportStatus st = check_export(o);
    if (!st.ready) {  // no prebuilt players next to this binary and no engine checkout: the row says so
        CHECK_FALSE(st.hint.empty());
        return;
    }
    CHECK((st.plan.mode == "prebuilt" || st.plan.mode == "source"));
    const ExportOutcome out = run_export(o);
    REQUIRE_MESSAGE(out.ok, out.error);
    CHECK(out.report.mode == st.plan.mode);
    CHECK(stdfs::exists(stdfs::path(out.report.outputDir) / "settings.gradle"));
    bool gradle = false;
    for (const std::string& step : out.report.nextSteps) gradle = gradle || step.find("gradle") != std::string::npos;
    CHECK(gradle);
}

TEST_CASE("export window: the progress lines of a long step are kept for the window") {
    ExportJob job;
    CHECK(job.progress_line().empty());
    CHECK(job.recent_lines().empty());
    job.add_line("> Task :app:preBuild UP-TO-DATE\r\n");  // a Gradle line as the process reader hands it over
    job.add_line("");                                       // blank lines are not lines
    job.add_line("   ");
    job.add_line("  > Task :app:compileDebugKotlin  ");
    CHECK(job.progress_line() == "> Task :app:compileDebugKotlin");
    const std::vector<std::string> lines = job.recent_lines();
    REQUIRE(lines.size() == 2);
    CHECK(lines[0] == "> Task :app:preBuild UP-TO-DATE");
    CHECK(lines[1] == "> Task :app:compileDebugKotlin");

    // Only the last lines are kept, oldest first.
    for (size_t i = 0; i < ExportJob::kMaxLines + 50; ++i) job.add_line("line " + std::to_string(i));
    const std::vector<std::string> kept = job.recent_lines();
    REQUIRE(kept.size() == ExportJob::kMaxLines);
    CHECK(kept.back() == "line " + std::to_string(ExportJob::kMaxLines + 49));
    CHECK(kept.front() == "line 50");
    CHECK(job.progress_line() == kept.back());
}

TEST_CASE("export window: a new export starts with a clean log and no cancel request") {
    TempProject p("joblog");
    ExportSettings s;
    s.outDir = (p.root / "out").string();
    s.players[kHost] = p.player();
    ExportJob job;
    job.add_line("left over from an earlier export");
    job.cancel();  // pressed after the last export finished: must not stop the next one
    CHECK_FALSE(job.cancelling());  // nothing is running
    ExportOptions o = export_options(p.dir.string(), kHost, s);
    std::vector<std::string> seen;
    o.progress = [&](const std::string& line) { seen.push_back(line); };  // a caller's own callback still gets the lines
    REQUIRE(job.start(o));
    job.wait();
    const std::optional<ExportOutcome> done = job.take_result();
    REQUIRE(done.has_value());
    CHECK_MESSAGE(done->ok, done->error);
    CHECK_FALSE(done->cancelled);
    CHECK(job.recent_lines().empty());  // the old line is gone (a desktop export reports no lines)
}

TEST_CASE("export window: only an export that stopped because of Cancel is reported as cancelled") {
    TempProject p("cancel");
    ExportSettings s;
    s.outDir = (p.root / "out").string();
    ExportOptions bad = export_options(p.dir.string(), kOtherDesktop, s);  // fails: no player built for that OS
    CancelFlag flag{true};
    bad.cancel = &flag;
    const ExportOutcome out = run_export(bad);
    CHECK_FALSE(out.ok);
    CHECK_FALSE(out.cancelled);  // it failed for its own reason, which the window must show
    CHECK(export_summary(out).find("failed") != std::string::npos);

    ExportOutcome cancelled;
    cancelled.platform = "android";
    cancelled.cancelled = true;
    cancelled.error = "export: cancelled";
    CHECK(export_summary(cancelled) == "Export for Android cancelled");
    CHECK(export_report_text(cancelled).find("cancelled") != std::string::npos);
}

TEST_CASE("export window: the summary and the report name the format and the artifact") {
    ExportOutcome out;
    out.platform = "android";
    out.ok = true;
    out.report.outputDir = "/out/game-android";
    out.report.format = "apk";
    out.report.artifact = "/out/game-android/game-debug.apk";
    out.report.mode = "prebuilt";
    out.report.nextSteps = {"adb install -r game-debug.apk"};
    const std::string summary = export_summary(out);
    CHECK(summary.find("Android APK") != std::string::npos);
    CHECK(summary.find("/out/game-android") != std::string::npos);
    const std::string text = export_report_text(out);
    CHECK(text.find("Format: APK") != std::string::npos);
    CHECK(text.find("Artifact: /out/game-android/game-debug.apk") != std::string::npos);
    CHECK(text.find("1. adb install") != std::string::npos);

    out.report.format.clear();  // a desktop export has neither
    out.report.artifact.clear();
    CHECK(export_summary(out) == "Exported Android to /out/game-android");
    CHECK(export_report_text(out).find("Artifact") == std::string::npos);
    CHECK(export_report_text(out).find("Format") == std::string::npos);
}
