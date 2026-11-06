// Play > Let the AI Play: the arguments and the outcome of a play.auto child process (auto_play_job.h), the job on its worker thread
// (a stand-in `factoria` script, POSIX only) and the Play sessions list (play_sessions_model.h). GPU-free.
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
    set_env("FA_FACTORIA_EXE", fs::path_to_utf8(file).c_str());
    CHECK(fs::path_from_utf8(auto_play_executable()) == file);
    set_env("FA_FACTORIA_EXE", fs::path_to_utf8(dir / "missing").c_str());
    CHECK(auto_play_executable().empty());  // a wrong override is not silently replaced by another program
    set_env("FA_FACTORIA_EXE", nullptr);
    std::error_code ec;
    stdfs::remove_all(dir, ec);
}

TEST_CASE("AutoPlayJob: no factoria is an outcome that says what is missing, not a crash") {
    const stdfs::path dir = fs::make_temp_dir("fa_auto_play_none");
    set_env("FA_FACTORIA_EXE", fs::path_to_utf8(dir / "missing").c_str());
    AutoPlayJob job;
    AutoPlayRequest req;
    req.projectDir = fs::path_to_utf8(dir);
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

#if !defined(_WIN32)
namespace {
// A stand-in `factoria`: a shell script. `body` is what it does.
stdfs::path stand_in(const stdfs::path& dir, const std::string& body) {
    const stdfs::path file = dir / "factoria";
    {
        std::ofstream f(file, std::ios::binary);
        f << "#!/bin/sh\n" << body << "\n";
    }  // closed before it runs
    stdfs::permissions(file, stdfs::perms::owner_all, stdfs::perm_options::add);
    return file;
}
bool wait_done(AutoPlayJob& job, double seconds) {
    const auto start = std::chrono::steady_clock::now();
    while (job.running()) {
        if (std::chrono::duration<double>(std::chrono::steady_clock::now() - start).count() > seconds) return false;
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
    return true;
}
}  // namespace

TEST_CASE("AutoPlayJob: a child that answers, one that fails and one that is cancelled") {
    const stdfs::path dir = fs::make_temp_dir("fa_auto_play_job");
    AutoPlayRequest req;
    req.projectDir = fs::path_to_utf8(dir);
    req.seconds = 7;
    AutoPlayJob job;

    // Answers: the arguments reach it and its stderr line is the progress line.
    set_env("FA_FACTORIA_EXE", fs::path_to_utf8(stand_in(dir, "echo \"playing\" >&2\n"
                                                              "echo \"$@\" > args.txt\n"
                                                              "echo '{\"session\":\"20260101-000000-auto\",\"ended\":\"won\",\"problems\":[],\"phases\":[]}'")).c_str());
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
    CHECK(line.find("\"seconds\":7") != std::string::npos);
    CHECK(job.progress_line() == "playing");

    // Fails with a command error.
    set_env("FA_FACTORIA_EXE", fs::path_to_utf8(stand_in(dir, "echo '{\"ok\":false,\"error\":{\"message\":\"No scene.\",\"hint\":\"Add one.\"}}'\nexit 1")).c_str());
    REQUIRE(job.start(req));
    REQUIRE(wait_done(job, 60));
    out = job.take_result();
    REQUIRE(out.has_value());
    CHECK_FALSE(out->ok);
    CHECK(out->error == "No scene.");

    // Cancel: the child sleeps for a minute; cancel() ends it within seconds and the outcome says cancelled.
    set_env("FA_FACTORIA_EXE", fs::path_to_utf8(stand_in(dir, "sleep 60")).c_str());
    REQUIRE(job.start(req));
    CHECK(job.running());
    CHECK_FALSE(job.start(req));  // one run at a time
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
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
#endif

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
