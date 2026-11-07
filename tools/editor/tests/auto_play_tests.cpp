// Play > Let the AI Play: the arguments and the outcome of a play.auto child process (auto_play_job.h), the job on its worker thread
// (a stand-in `factoria` script or .cmd file) and the Play sessions list (play_sessions_model.h). GPU-free.
#include <chrono>
#include <cmath>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <thread>

#include "auto_play_job.h"
#include "doctest.h"
#include "fa/core/fs.h"
#include "play_sessions_model.h"

using namespace fa;
using namespace fa::editor;
namespace stdfs = std::filesystem;

namespace {

ProcessResult exited(int code = 0, const std::string& err = "") {
    ProcessResult r;
    r.exitCode = code;
    r.stderrText = err;
    return r;
}

void set_env(const char* name, const char* value) {
#if defined(_WIN32)
    _putenv_s(name, value ? value : "");
#else
    if (value) setenv(name, value, 1);
    else unsetenv(name);
#endif
}

// FA_FACTORIA_EXE is a native string, as getenv gives it (the ANSI code page on Windows); UTF-8 is only for the process boundary.
void set_exe(const stdfs::path& file) { set_env("FA_FACTORIA_EXE", file.string().c_str()); }

}  // namespace

TEST_CASE("auto_play_args: the seconds are clamped to the window's range and the pictures follow the box") {
    AutoPlayRequest r;
    r.seconds = 1;
    CHECK(auto_play_args(r)["seconds"].get<double>() == kAutoPlayMinSeconds);
    r.seconds = 1e9;
    CHECK(auto_play_args(r)["seconds"].get<double>() == kAutoPlayMaxSeconds);
    r.seconds = std::nan("");
    CHECK(auto_play_args(r)["seconds"].get<double>() == kAutoPlayDefaultSeconds);
    r.seconds = 42;
    r.screenshots = false;
    const Json a = auto_play_args(r);
    CHECK(a["seconds"].get<double>() == 42);
    CHECK(a["screenshots"] == false);
}

TEST_CASE("auto_play_outcome: a result, a command error, garbage, a cancel and a timeout") {
    const AutoPlayOutcome ok = auto_play_outcome(
        exited(), R"({"session":"20260101-000000-auto","ended":"timeout","endedWhy":"time","problems":[{"n":1},{"n":2}],"phases":[{"name":"a"}]})");
    CHECK(ok.ok);
    CHECK(ok.session == "20260101-000000-auto");
    CHECK(ok.ended == "timeout");
    CHECK(ok.problems == 2);
    CHECK(ok.phases == 1);
    CHECK(auto_play_summary(ok).find("2 problems") != std::string::npos);

    const AutoPlayOutcome err = auto_play_outcome(exited(1), R"({"ok":false,"error":{"code":"x","message":"No scene.","hint":"Add one."}})");
    CHECK_FALSE(err.ok);
    CHECK(err.error == "No scene.");
    CHECK(err.hint == "Add one.");
    CHECK(auto_play_summary(err).find("No scene.") != std::string::npos);

    const AutoPlayOutcome junk = auto_play_outcome(exited(3, "boom: it crashed"), "not json");
    CHECK_FALSE(junk.ok);
    CHECK(junk.error.find("boom: it crashed") != std::string::npos);  // the child's own words reach the person
    CHECK_FALSE(junk.hint.empty());

    const AutoPlayOutcome noName = auto_play_outcome(exited(), R"({"ended":"won"})");
    CHECK_FALSE(noName.ok);

    ProcessResult c;
    c.cancelled = true;
    const AutoPlayOutcome cancelled = auto_play_outcome(c, "");
    CHECK(cancelled.cancelled);
    CHECK_FALSE(cancelled.ok);
    CHECK(auto_play_summary(cancelled).find("cancelled") != std::string::npos);

    ProcessResult t;
    t.timedOut = true;
    const AutoPlayOutcome timed = auto_play_outcome(t, "");
    CHECK_FALSE(timed.ok);
    CHECK_FALSE(timed.cancelled);
    CHECK_FALSE(timed.hint.empty());
}

TEST_CASE("auto_play_executable: FA_FACTORIA_EXE wins and must name a file") {
    const stdfs::path dir = fs::make_temp_dir("fa_auto_play_exe");
    const stdfs::path file = dir / stdfs::path(u8"factoría-herramienta");  // an accent: UTF-8 all the way, never the ANSI code page
    { std::ofstream(file, std::ios::binary) << "x"; }
    set_exe(file);
    CHECK(fs::path_from_utf8(auto_play_executable()) == file);
    set_exe(dir / "missing");
    CHECK(auto_play_executable().empty());  // a wrong override is not silently replaced by another program
    set_env("FA_FACTORIA_EXE", nullptr);
    std::error_code ec;
    stdfs::remove_all(dir, ec);
}

TEST_CASE("AutoPlayJob: no factoria is an outcome that says what is missing, not a crash") {
    const stdfs::path dir = fs::make_temp_dir("fa_auto_play_none");
    set_exe(dir / "missing");
    AutoPlayJob job;
    AutoPlayRequest req;
    req.projectDir = dir;
    CHECK(job.start(req));
    auto out = job.take_result();
    REQUIRE(out.has_value());
    CHECK_FALSE(out->ok);
    CHECK_FALSE(out->cancelled);
    CHECK(out->error.find("not found") != std::string::npos);
    CHECK_FALSE(out->hint.empty());
    CHECK_FALSE(job.running());
    CHECK_FALSE(job.take_result().has_value());  // once
    set_env("FA_FACTORIA_EXE", nullptr);
    std::error_code ec;
    stdfs::remove_all(dir, ec);
}

namespace {
// A stand-in `factoria`: a shell script (POSIX) or a .cmd file (Windows, run through cmd.exe like any .cmd). `posix` and `windows` are
// what it does. The Windows lines use only characters a .cmd argument may hold (run_process refuses % & | < > ^ in one).
stdfs::path stand_in(const stdfs::path& dir, const std::string& posix, const std::string& windows) {
#if defined(_WIN32)
    const stdfs::path file = dir / "factoria.cmd";
    {
        std::ofstream f(file, std::ios::binary);
        f << "@echo off\r\n" << windows << "\r\n";
    }
    (void)posix;
#else
    const stdfs::path file = dir / "factoria";
    {
        std::ofstream f(file, std::ios::binary);
        f << "#!/bin/sh\n" << posix << "\n";
    }  // closed before it runs
    stdfs::permissions(file, stdfs::perms::owner_all, stdfs::perm_options::add);
    (void)windows;
#endif
    return file;
}
// A stand-in that does not end for a minute: the bot of a long run.
stdfs::path sleeper(const stdfs::path& dir) { return stand_in(dir, "sleep 60", "ping -n 60 127.0.0.1 >nul"); }
bool wait_done(AutoPlayJob& job, double seconds) {
    const auto start = std::chrono::steady_clock::now();
    while (job.running()) {
        if (std::chrono::duration<double>(std::chrono::steady_clock::now() - start).count() > seconds) return false;
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
    return true;
}
const char* kAnswer = R"({"session":"20260101-000000-auto","ended":"won","problems":[],"phases":[]})";
}  // namespace

TEST_CASE("AutoPlayJob: a child that answers, one that fails and one that is cancelled") {
    const stdfs::path dir = fs::make_temp_dir("fa_auto_play_job");
    AutoPlayRequest req;
    req.projectDir = dir;
    req.seconds = 7;
    AutoPlayJob job;

    // Answers: the arguments reach it and its stderr line is the progress line.
    set_exe(stand_in(dir, std::string("echo \"playing\" >&2\n") + "echo \"$@\" > args.txt\n" + "echo '" + kAnswer + "'",
                     std::string("@echo playing 1>&2\r\n") + "@echo %* > args.txt\r\n" + "@echo " + kAnswer));
    REQUIRE(job.start(req));
    REQUIRE(wait_done(job, 60));
    auto out = job.take_result();
    REQUIRE(out.has_value());
    CHECK(out->ok);
    CHECK(out->session == "20260101-000000-auto");
    CHECK(out->ended == "won");
    std::ifstream args(dir / "args.txt");
    std::string line;
    std::getline(args, line);
    CHECK(line.find("--no-graphics") != std::string::npos);
    CHECK(line.find("play.auto") != std::string::npos);
#if !defined(_WIN32)
    CHECK(line.find("\"seconds\":7") != std::string::npos);  // cmd.exe shows the quotes of an argument escaped
#endif
    CHECK(job.progress_line().find("playing") == 0);

    // Fails with a command error.
    set_exe(stand_in(dir, "echo '{\"ok\":false,\"error\":{\"message\":\"No scene.\",\"hint\":\"Add one.\"}}'\nexit 1",
                     "@echo {\"ok\":false,\"error\":{\"message\":\"No scene.\",\"hint\":\"Add one.\"}}\r\n@exit /b 1"));
    REQUIRE(job.start(req));
    REQUIRE(wait_done(job, 60));
    out = job.take_result();
    REQUIRE(out.has_value());
    CHECK_FALSE(out->ok);
    CHECK(out->error == "No scene.");

    // Cancel: the child sleeps for a minute; cancel() ends it within seconds and the outcome says cancelled.
    set_exe(sleeper(dir));
    REQUIRE(job.start(req));
    CHECK(job.running());
    CHECK_FALSE(job.start(req));  // one run at a time
    std::this_thread::sleep_for(std::chrono::milliseconds(300));
    job.cancel();
    CHECK(job.cancelling());
    REQUIRE(wait_done(job, 30));
    out = job.take_result();
    REQUIRE(out.has_value());
    CHECK(out->cancelled);
    CHECK_FALSE(out->ok);

    set_env("FA_FACTORIA_EXE", nullptr);
    std::error_code ec;
    stdfs::remove_all(dir, ec);
}

TEST_CASE("AutoPlayJob: a project folder with accents reaches the child as UTF-8 (it starts there)") {
    const stdfs::path base = fs::make_temp_dir("fa_auto_play_accent");
    const stdfs::path project = base / stdfs::path(u8"proyecto-José ñandú");
    std::error_code ec;
    stdfs::create_directories(project, ec);
    REQUIRE(stdfs::is_directory(project));
    const stdfs::path tool = base / "tool";
    stdfs::create_directories(tool, ec);
    // The stand-in writes a file in its working directory: it exists in the project folder only if the child started there, which a
    // working directory handed over as ANSI bytes (invalid UTF-8) cannot do on Windows.
    set_exe(stand_in(tool, std::string("echo here > cwd.txt\n") + "echo '" + kAnswer + "'",
                     std::string("@echo here > cwd.txt\r\n") + "@echo " + kAnswer));
    AutoPlayJob job;
    AutoPlayRequest req;
    req.projectDir = project;
    REQUIRE(job.start(req));
    REQUIRE(wait_done(job, 60));
    auto out = job.take_result();
    REQUIRE(out.has_value());
    CHECK_MESSAGE(out->ok, out->error);
    CHECK(stdfs::exists(project / "cwd.txt"));
    set_env("FA_FACTORIA_EXE", nullptr);
    stdfs::remove_all(base, ec);
}

TEST_CASE("play sessions model: rows, labels and which session Attach picks") {
    const Json person = parse_json(R"({"scene":"scenes/a.scene.json","durationSec":12.4,"marks":[{"n":1},{"n":2}],"logs":[{}]})", "t").value();
    const Json bot = parse_json(R"({"source":"auto","scene":"scenes/a.scene.json","durationSec":60,"ended":"stuck","marks":[{"n":1}],"logs":[]})", "t").value();
    const PlaySessionRow p = play_session_row("20260102-000000", person);
    const PlaySessionRow b = play_session_row("20260103-000000-auto", bot);
    CHECK_FALSE(p.isAuto);
    CHECK(p.marks == 2);
    CHECK(p.logs == 1);
    CHECK(b.isAuto);
    CHECK(b.ended == "stuck");
    CHECK(play_session_label(b).find("AI") != std::string::npos);
    CHECK(play_session_label(b).find("stuck, 1 problem") != std::string::npos);
    CHECK(play_session_label(p).find("you") != std::string::npos);
    CHECK(play_session_label(p).find("2 marks") != std::string::npos);
    CHECK_FALSE(play_session_row("x", Json::array()).error.empty());

    bool fellBack = true;
    // newest first: the bot's session is newer than the person's
    std::vector<PlaySessionRow> rows = {b, p};
    const PlaySessionRow* pick = session_to_attach(rows, fellBack);
    REQUIRE(pick);
    CHECK(pick->name == p.name);  // the person's, not the newest
    CHECK_FALSE(fellBack);
    rows = {b};
    pick = session_to_attach(rows, fellBack);
    REQUIRE(pick);
    CHECK(pick->name == b.name);
    CHECK(fellBack);  // the caller says it is the bot's
    rows.clear();
    CHECK(session_to_attach(rows, fellBack) == nullptr);

    for (const char* e : {"won", "lost", "timeout", "stuck", "broken", "quit", "aborted", ""})
        CHECK_FALSE(play_session_ended_words(e).empty());
}
