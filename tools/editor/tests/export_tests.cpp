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
    CHECK(export_target_note(*find_export_target("android")).find("Gradle") != std::string::npos);
    CHECK(export_target_note(*find_export_target("ios")).find("Xcode") != std::string::npos);

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
