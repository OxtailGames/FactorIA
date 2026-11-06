// Efficiency feedback after the report: what an entry sends (measured numbers and fix type, engine terms only), how the developer's side
// ranks many installations' entries by what a fix would save, and what a fix leaves on the entry (docs/ENGINE_FEEDBACK.md, "Efficiency
// feedback" and "Triage loop"). Fixtures only: a fake transport, a temp config folder, no network.
#include <doctest.h>

#include <thread>

#include <filesystem>
#include <string>

#include "fa/core/date.h"
#include "fa/tooling/efficiency.h"
#include "fa/tooling/feedback.h"
#include "fa/tooling/feedback_share.h"
#include "fa_test_paths.h"  // FA_REPO_ROOT
#include "test_helpers.h"

using namespace fa;

namespace {

constexpr std::int64_t kT0 = 1'800'000'000'000;  // ms: 2027-01-15

std::string at(std::int64_t secondsAfterStart) { return iso_utc_ms(kT0 + secondsAfterStart * 1000); }

// A built-in transcript of `n` steps, one minute each, 5000 tokens and $0.05 a step.
std::string builtin_session(int n) {
    std::string out = Json::object({{"kind", "start"}, {"t", at(0)}}).dump() + "\n";
    for (int i = 1; i <= n; ++i) {
        const std::string id = "tu" + std::to_string(i);
        Json input = Json::object({{"command", "scene.inspect"}, {"arguments", Json::object({{"entity", "player"}})}});
        Json content = Json::array({Json::object({{"type", "tool_use"}, {"id", id}, {"name", "tool_call"}, {"input", input}})});
        out += Json::object({{"kind", "assistant"}, {"t", at(60 * i - 1)},
                             {"usage", Json::object({{"inputTokens", 4500}, {"outputTokens", 500}})}, {"costUsd", 0.05}, {"content", content}}).dump() + "\n";
        Json result = Json::object({{"toolUseId", id}, {"isError", false}, {"ms", 40}, {"content", "ok"}});
        out += Json::object({{"kind", "tool_results"}, {"t", at(60 * i)}, {"results", Json::array({result})}}).dump() + "\n";
    }
    return out;
}

const char* kSession = "20270115-153012-orchestrator";

// A project called "Lantern Keep" (its names must never leave) with one transcript, a fake transport and a config folder.
struct Game {
    testing::TempDir dir;
    testing::TempDir home;
    ShareEnv env;
    std::vector<HttpRequest> requests;
    std::int64_t clock = 1'800'000'000;
    Game() {
        const std::string h = home.str();
        env.env = [h](const std::string& name) -> std::string { return name == "HOME" || name == "USERPROFILE" || name == "APPDATA" ? h : ""; };
        env.now = [this] { return clock; };
        env.sleep = [](double) {};
        env.makeUuid = [] { return std::string("11111111-2222-4333-8444-555555555555"); };
        env.defaultEndpoint = "https://feedback.example.test";
        env.platform = "linux";
        env.engineVersion = "9.9.9";
        env.transport = [this](const HttpRequest& r) {
            requests.push_back(r);
            HttpResponse out;
            out.ok = true;
            out.status = 200;
            Json body = Json::parse(r.body);
            Json results = Json::array();
            for (const Json& e : body["entries"]) results.push_back(Json::object({{"localId", e["localId"]}, {"status", "accepted"}, {"shareId", "r_1"}}));
            out.body = Json::object({{"ok", true}, {"results", results}}).dump();
            return out;
        };
        testing::write_all(dir.path / "factoria.json", R"({"name":"Lantern Keep","id":"com.acme.lanternkeep","version":"0.1.0","mainScene":"scenes/crypt.scene.json"})");
        testing::write_all(dir.path / "scenes" / "crypt.scene.json", R"({"entities":[{"name":"Sir Aldric","components":{"Transform":{}}}]})");
        testing::write_all(dir.path / ".factoria" / "ai" / "sessions" / (std::string(kSession) + ".jsonl"), builtin_session(80));
    }
    Json report(int from, int to, const std::string& waste = "Working out the order of the flux calibration calls took forty steps of trial") {
        Json evidence = Json::array({Json::object({{"session", kSession}, {"fromStep", from}, {"toStep", to}})});
        return Json::object({{"kind", "efficiency"}, {"category", "scene"}, {"title", "Quantum flux calibration routine"}, {"waste", waste},
                             {"suggestion", "A topic guide that lists the three calibration calls in order"}, {"fixType", "guide"},
                             {"appliesTo", "every-game"}, {"evidence", evidence},
                             {"expectedSaving", Json::object({{"share", 0.5}, {"why", "the guide gives the calls in order"}})}});
    }
    std::string file() const { return (dir.path / "ENGINE_FEEDBACK.json").string(); }
};

EfficiencyMeasure measure(int steps, double minutes, std::uint64_t tokens, double usd) {
    EfficiencyMeasure m;
    m.steps = steps;
    m.toolCalls = steps / 2;
    m.minutes = minutes;
    m.tokens = tokens;
    m.costUsd = usd;
    return m;
}

EfficiencyVoice voice(const std::string& project, const std::string& trust, const EfficiencyMeasure& saving, int occurrences = 1) {
    EfficiencyVoice v;
    v.project = project;
    v.id = "FB-0001";
    v.shareId = "r_" + project;
    v.trust = trust;
    v.occurrences = occurrences;
    v.measured = saving;
    v.saving = saving;
    return v;
}

EfficiencyGroup group(const std::string& title, const std::string& fixType, std::vector<EfficiencyVoice> voices) {
    EfficiencyGroup g;
    g.title = title;
    g.category = "scene";
    g.fixType = fixType;
    g.appliesTo = "every-game";
    g.voices = std::move(voices);
    return g;
}

}  // namespace

TEST_CASE("efficiency share: the entry sends numbers and the fix type, never the game's names or the session ids") {
    Game g;
    ScopedShareEnv scoped(g.env);
    REQUIRE(set_share_mode(g.env, ShareMode::Always).ok());
    CommandRegistry registry;
    register_feedback_commands(registry, g.dir.str());
    auto r = registry.call("feedback.report", g.report(1, 40, "Sir Aldric in Lantern Keep needed forty steps to order the flux calibration calls of scenes/crypt.scene.json"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());

    CHECK(r.result["share"]["status"] == "sent");  // mode "always": the report is sent at once
    REQUIRE(g.requests.size() == 1);
    const Json body = Json::parse(g.requests[0].body);
    REQUIRE(body["entries"].size() == 1);
    const Json& e = body["entries"][0];
    REQUIRE(e.contains("efficiency"));
    const Json& block = e["efficiency"];
    CHECK(block["fixType"] == "guide");
    CHECK(block["appliesTo"] == "every-game");
    CHECK(block["measured"]["steps"] == 40);
    CHECK(block["measured"]["tokens"] == 200000);
    CHECK(block["saving"]["tokens"] == 100000);
    CHECK(block["expectedShare"] == 0.5);
    CHECK(block["spans"] == 1);
    CHECK_FALSE(block.contains("evidence"));
    CHECK_FALSE(block.contains("session"));
    const std::string text = g.requests[0].body;
    for (const char* leak : {"Lantern", "Aldric", kSession, "crypt", "20270115", "orchestrator", "waste", "evidence"})
        CHECK_MESSAGE(text.find(leak) == std::string::npos, leak);
    // The text that goes is the waste, cleaned like a gap.
    CHECK(e["missing"].get<std::string>().find("flux calibration") != std::string::npos);
}

TEST_CASE("efficiency share: this-game entries and entries without numbers send no block") {
    Json entry = Json::parse(R"({"id":"FB-0001","kind":"efficiency","fixType":"doc","appliesTo":"this-game",
        "measured":{"steps":10},"saving":{"steps":5}})");
    CHECK(efficiency_share_block(entry).is_null());
    entry["appliesTo"] = "every-game";
    CHECK(efficiency_share_block(entry).is_object());
    entry.erase("measured");
    CHECK(efficiency_share_block(entry).is_null());
    CHECK(efficiency_share_block(Json::parse(R"({"kind":"gap","fixType":"doc"})")).is_null());
}

TEST_CASE("efficiency share: an entry hit again is sent again, and the server's numbers are clamped by the engine on the way back") {
    Game g;
    ScopedShareEnv scoped(g.env);
    REQUIRE(set_share_mode(g.env, ShareMode::Always).ok());
    CommandRegistry registry;
    register_feedback_commands(registry, g.dir.str());
    REQUIRE(registry.call("feedback.report", g.report(1, 40)).ok);
    REQUIRE(g.requests.size() == 1);
    REQUIRE(registry.call("feedback.report", g.report(41, 80)).ok);  // other steps of the same waste: merged, 2 occurrences
    const Json doc = load_feedback(g.file()).value();
    CHECK(doc["entries"][0]["occurrences"] == 2);
    REQUIRE(g.requests.size() == 2);  // the merge sent the entry again with its new numbers
    // The second send carries the cumulative numbers (two spans, 80 steps).
    const Json second = Json::parse(g.requests[1].body)["entries"][0]["efficiency"];
    CHECK(second["measured"]["steps"] == 80);
    CHECK(second["spans"] == 2);

    // A block from a server is read through efficiency_clean_block: unknown values and absurd numbers do not get in.
    CHECK(efficiency_clean_block(Json::parse(R"({"fixType":"nope","appliesTo":"every-game","measured":{},"saving":{}})")).is_null());
    const Json odd = efficiency_clean_block(Json::parse(R"({"fixType":"doc","appliesTo":"genre","measured":{"steps":1e30,"minutes":-4,"tokens":1e30},
        "saving":{"costUsd":1e30},"expectedShare":7,"spans":900,"afterFix":"0.17.0"})"));
    REQUIRE(odd.is_object());
    CHECK(odd["measured"]["steps"].get<double>() <= 4'000'000.0);
    CHECK(odd["measured"]["minutes"] == 0);
    CHECK(odd["measured"]["tokens"].get<double>() <= 1.0e12);
    CHECK(odd["saving"]["costUsd"].get<double>() <= 1.0e6);
    CHECK(odd["expectedShare"] == 1);
    CHECK(odd["spans"] == 200);
    CHECK(odd["afterFix"] == "0.17.0");
    CHECK_FALSE(efficiency_clean_block(Json::parse(R"({"fixType":"doc","appliesTo":"genre","measured":{},"saving":{},"afterFix":"0.1 0; rm"})")).contains("afterFix"));
}

TEST_CASE("efficiency rank: ordered by the total saving, each with its verdict and a ready reason") {
    // A doc fix wanted by two installations, a command that saves a lot, and an engine change that saves little.
    const Json ranked = rank_efficiency({
        group("Flux calibration order", "doc", {voice("install-a", "verified", measure(40, 10.04, 200000, 0.5)), voice("install-b", "anonymous", measure(40, 10, 200000, 0.5))}),
        group("Scene load retries", "newCommand", {voice("install-a", "verified", measure(200, 1000, 3000000, 30))}),
        group("Physics layer lookup", "engineChange", {voice("install-c", "verified", measure(40, 60, 300000, 3))}),
    });
    REQUIRE(ranked.size() == 3);
    CHECK(ranked[0]["rank"] == 1);
    CHECK(ranked[0]["title"] == "Scene load retries");
    CHECK(ranked[0]["verdict"]["code"] == "command-worth-it");
    CHECK(ranked[0]["verdict"]["text"] == "command: worth it");
    CHECK(ranked[1]["title"] == "Physics layer lookup");
    CHECK(ranked[1]["verdict"]["code"] == "engine-below-threshold");
    const std::string text = ranked[1]["verdict"]["text"].get<std::string>();
    CHECK(text.find("below threshold") != std::string::npos);
    CHECK(text.find("$1000") != std::string::npos);
    CHECK(text.find("20 hours") != std::string::npos);
    CHECK(ranked[2]["verdict"]["code"] == "doc-now");
    CHECK(ranked[2]["verdict"]["text"] == "doc now");
    // An installation counts once (trust-weighted: verified 1, anonymous 0.5), and the numbers are rounded.
    CHECK(ranked[2]["installations"] == 2);
    CHECK(ranked[2]["verifiedInstallations"] == 1);
    CHECK(ranked[2]["total"]["minutes"] == 15.0);  // 10.04 + 10 x 0.5, to 0.1 minute
    CHECK(ranked[2]["total"]["tokens"] == 300000);
    CHECK(ranked[2]["fixCost"]["hours"] == 0.5);
    CHECK(ranked[1]["fixCost"]["usd"] == 1000);
    // A ready reason only where the verdict says "do not build this": doc now and below threshold. A command that is worth it is not refused.
    for (const Json& g : ranked) {
        const std::string code = g["verdict"]["code"].get<std::string>();
        for (const Json& e : g["entries"]) {
            if (code == "doc-now" || code == "engine-below-threshold") {
                REQUIRE(e.contains("rejectReason"));
                const std::string reason = e["rejectReason"].get<std::string>();
                CHECK(reason.size() >= 20);
                CHECK(reason.size() <= 500);
            } else {
                CHECK_FALSE(e.contains("rejectReason"));
            }
        }
    }
    // Deterministic: the same groups in another order give the same answer, and ties break by title.
    const Json again = rank_efficiency({
        group("Physics layer lookup", "engineChange", {voice("install-c", "verified", measure(40, 60, 300000, 3))}),
        group("Scene load retries", "newCommand", {voice("install-a", "verified", measure(200, 1000, 3000000, 30))}),
        group("Flux calibration order", "doc", {voice("install-b", "anonymous", measure(40, 10, 200000, 0.5)), voice("install-a", "verified", measure(40, 10.04, 200000, 0.5))}),
    });
    CHECK(again == ranked);
    const Json tie = rank_efficiency({group("B title", "doc", {voice("x", "verified", measure(1, 5, 1000, 0))}),
                                      group("A title", "doc", {voice("y", "verified", measure(1, 5, 1000, 0))})});
    CHECK(tie[0]["title"] == "A title");
}

TEST_CASE("efficiency rank: the fix costs are the ones docs/ENGINE_FEEDBACK.md states") {
    const std::string doc = testing::read_text(std::filesystem::path(FA_REPO_ROOT) / "docs" / "ENGINE_FEEDBACK.md");
    REQUIRE_FALSE(doc.empty());
    const std::string sentence = "(doc 0.5, guide 2, example 4, command option 4, new command 16;";
    CHECK_MESSAGE(doc.find(sentence) != std::string::npos, "docs/ENGINE_FEEDBACK.md must state: " << sentence);
    CHECK(efficiency_fix_cost_hours("doc") == 0.5);
    CHECK(efficiency_fix_cost_hours("guide") == 2.0);
    CHECK(efficiency_fix_cost_hours("example") == 4.0);
    CHECK(efficiency_fix_cost_hours("commandOption") == 4.0);
    CHECK(efficiency_fix_cost_hours("newCommand") == 16.0);
}

TEST_CASE("efficiency rank: a verdict text rounds its hours down, so a short saving never reads as the bar") {
    // 3 hours 57 minutes against the 4 hours of a command option: "3.9", not "4.0".
    const Json v = rank_efficiency({group("Option", "commandOption", {voice("a", "verified", measure(10, 237.5, 1000, 0))})})[0]["verdict"];
    CHECK(v["code"] == "command-not-yet");
    CHECK(v["text"].get<std::string>().find("3.9 of the 4.0 hours") != std::string::npos);
}

TEST_CASE("efficiency share: an efficiency entry that has no block to send is never shareable") {
    Game g;
    ScopedShareEnv scoped(g.env);
    CommandRegistry registry;
    register_feedback_commands(registry, g.dir.str());
    REQUIRE(registry.call("feedback.report", g.report(1, 40)).ok);
    Json entry = load_feedback(g.file()).value()["entries"][0];
    CHECK(entry_is_shareable(entry));
    Json unknownFix = entry;
    unknownFix["fixType"] = "teleport";
    CHECK_FALSE(entry_is_shareable(unknownFix));
    Json thisGame = entry;
    thisGame["appliesTo"] = "this-game";
    CHECK_FALSE(entry_is_shareable(thisGame));  // it stays on this machine, however it was marked
    Json noNumbers = entry;
    noNumbers.erase("measured");
    CHECK_FALSE(entry_is_shareable(noNumbers));
}

TEST_CASE("feedback file lock: the user's folder first, the project's own when the user's cannot be written, and an error that names both") {
    Game g;
    ShareEnv env = g.env;
    env.lockWaitSec = 0.2;
    env.lockStaleSec = 600.0;
    ScopedShareEnv scoped(env);
    const std::filesystem::path projectLock = g.dir.path / ".factoria" / kFeedbackShareLockFile;
    {
        FeedbackFileLock lock(env, g.file());
        REQUIRE_MESSAGE(lock.held(), lock.error());
        CHECK_FALSE(lock.in_project_folder());
    }
    // The user's folder cannot be made (a file is in its place): the report is still written, under a lock in the project's folder.
    std::error_code removeEc;
    std::filesystem::remove_all(env.config_dir(), removeEc);  // the first lock made it
    testing::write_all(env.config_dir(), "this is a file, not a folder");
    REQUIRE(std::filesystem::is_regular_file(env.config_dir()));
    {
        FeedbackFileLock lock(env, g.file());
        REQUIRE_MESSAGE(lock.held(), lock.error());
        CHECK(lock.in_project_folder());
        CHECK(std::filesystem::exists(projectLock));  // held for the span of the object
    }
    CHECK_FALSE(std::filesystem::exists(projectLock));
    CommandRegistry registry;
    register_feedback_commands(registry, g.dir.str());
    const Json gap = Json::object({{"category", "scene"}, {"severity", "minor"}, {"title", "Zorblax wibble gauge is missing"},
                                   {"missing", "The engine has no zorblax wibble gauge for the quuxel pipeline"},
                                   {"workaround", "I counted the quuxel frames by hand"}});
    auto done = registry.call("feedback.report", gap);
    REQUIRE_MESSAGE(done.ok, done.error.dump());
    CHECK(load_feedback(g.file()).value()["entries"].size() == 1);

    // A project lock that is busy is a wait that ends (not a silent write), and neither folder works: the error names them.
    testing::write_all(projectLock, "alive");
    {
        FeedbackFileLock busy(env, g.file());
        CHECK_FALSE(busy.held());
        CHECK(busy.error().find("Another FactorIA process") != std::string::npos);
    }
    std::error_code ec;
    std::filesystem::remove(projectLock, ec);
    std::filesystem::remove_all(g.dir.path / ".factoria", ec);
    testing::write_all(g.dir.path / ".factoria", "this is a file too");
    FeedbackFileLock neither(env, g.file());
    CHECK_FALSE(neither.held());
    CHECK(neither.error().find(env.config_dir()) != std::string::npos);
    CHECK(neither.error().find("project's own folder") != std::string::npos);
}

TEST_CASE("feedback file lock: a process that can write the user's folder and one that cannot exclude each other through the project's lock") {
    Game g;
    ShareEnv env = g.env;
    env.lockWaitSec = 0.2;
    env.lockStaleSec = 600.0;
    ScopedShareEnv scoped(env);
    // The other program (a thread: the locks are per thread) has a home that cannot be written: a file stands where its folder would be.
    testing::TempDir sandboxHome;
    const std::filesystem::path blocker = sandboxHome.path / "home-is-a-file";
    testing::write_all(blocker, "x");
    const std::string blockerText = blocker.string();
    ShareEnv sandboxed = env;
    sandboxed.env = [blockerText](const std::string& name) -> std::string { return name == "HOME" || name == "USERPROFILE" || name == "APPDATA" ? blockerText : ""; };
    auto sandbox_tries = [&] {
        bool held = false;
        std::string error;
        std::thread([&] {
            FeedbackFileLock lock(sandboxed, g.file());
            held = lock.held();
            error = lock.error();
        }).join();
        return std::make_pair(held, error);
    };
    {
        FeedbackFileLock outside(env, g.file());
        REQUIRE_MESSAGE(outside.held(), outside.error());
        CHECK_FALSE(outside.in_project_folder());
        const auto [held, error] = sandbox_tries();
        CHECK_FALSE(held);  // it waited for the project's lock, which the first one holds as well
        CHECK(error.find("Another FactorIA process") != std::string::npos);
    }
    const auto [heldAfter, errorAfter] = sandbox_tries();
    CHECK_MESSAGE(heldAfter, errorAfter);
    // The other way round: the sandboxed one holds the project's lock, the one with a writable home waits for it too.
    {
        FeedbackFileLock inside(sandboxed, g.file());
        REQUIRE_MESSAGE(inside.held(), inside.error());
        CHECK(inside.in_project_folder());
        bool held = true;
        std::thread([&] { held = FeedbackFileLock(env, g.file()).held(); }).join();
        CHECK_FALSE(held);
    }
    // Locks of two folders in one thread do not wait for themselves, and are both released.
    {
        FeedbackFileLock outer(env, g.file());
        FeedbackFileLock inner(env, g.file());
        CHECK(outer.held());
        CHECK(inner.held());
    }
    CHECK_FALSE(std::filesystem::exists(g.dir.path / ".factoria" / kFeedbackShareLockFile));
    CHECK_FALSE(std::filesystem::exists(std::filesystem::path(env.config_dir()) / kFeedbackShareLockFile));
}

TEST_CASE("record_fix_check: takes the lock of the feedback files, so a report written at the same time is not undone") {
    Game g;
    ShareEnv busy = g.env;
    busy.lockWaitSec = 0.2;
    busy.lockStaleSec = 600.0;
    ScopedShareEnv scoped(busy);
    std::error_code ec;
    std::filesystem::create_directories(busy.config_dir(), ec);
    const std::string lockPath = (std::filesystem::path(busy.config_dir()) / kFeedbackShareLockFile).string();
    testing::write_all(lockPath, "alive");
    auto blocked = record_fix_check(g.file(), "FB-0001", Json::object());
    REQUIRE_FALSE(blocked.ok());
    CHECK(blocked.error().message.find("Another FactorIA process") != std::string::npos);
    std::filesystem::remove(lockPath, ec);
    auto free = record_fix_check(g.file(), "FB-0001", Json::object());  // no such file: the lock was taken, the entry is what is missing
    REQUIRE_FALSE(free.ok());
    CHECK(free.error().message.find("No feedback entry") != std::string::npos);
    CHECK_FALSE(std::filesystem::exists(lockPath));  // released
}

TEST_CASE("efficiency rank: a command is worth it when its total saving covers its cost, and not before") {
    // 4 hours is what a command option costs: 3.9 hours is not enough, 4.1 is.
    auto verdict = [](double minutes) {
        return rank_efficiency({group("Option", "commandOption", {voice("a", "verified", measure(10, minutes, 1000, 0))})})[0]["verdict"];
    };
    CHECK(verdict(234)["code"] == "command-not-yet");
    CHECK(verdict(246)["code"] == "command-worth-it");
    CHECK(verdict(234)["text"].get<std::string>().find("hours it costs") != std::string::npos);
}

TEST_CASE("efficiency rank: a fix that was shipped and did not help is named in the group") {
    EfficiencyVoice v = voice("install-a", "verified", measure(40, 10, 200000, 0.5));
    v.afterFix = "0.17.0";
    const Json ranked = rank_efficiency({group("Flux calibration order", "doc", {v})});
    REQUIRE(ranked.size() == 1);
    CHECK(ranked[0]["afterFix"] == Json::array({"0.17.0"}));
}

TEST_CASE("feedback update: a fix records the version and the day, and an efficiency entry what one occurrence cost before") {
    Game g;
    ScopedShareEnv scoped(g.env);
    CommandRegistry registry;
    register_feedback_commands(registry, g.dir.str());
    REQUIRE(registry.call("feedback.report", g.report(1, 40)).ok);
    REQUIRE(registry.call("feedback.report", g.report(41, 80)).ok);
    Json doc = load_feedback(g.file()).value();
    REQUIRE(doc["entries"].size() == 1);
    auto fixed = update_feedback_entry(doc, "FB-0001", "fixed-in-engine", "FactorIA 0.17.2", "", "engine");
    REQUIRE(fixed.ok());
    CHECK(fixed.value()["fixedIn"] == "0.17.2");
    CHECK(fixed.value()["fixedAt"].get<std::string>().size() == 10);
    // 80 steps over 2 spans: 40 steps, 5000 x 40 tokens, 40 minutes per occurrence.
    const Json& base = fixed.value()["fixBaseline"];
    CHECK(base["spans"] == 2);
    CHECK(base["steps"] == 40);
    CHECK(base["tokens"] == 200000);
    CHECK(base["minutes"] == 40);
    for (const auto& err : validate_feedback(doc)) CHECK_MESSAGE(false, err.to_string());
    // Reopening takes it all back.
    auto reopened = update_feedback_entry(doc, "FB-0001", "open", "", "", "user");
    REQUIRE(reopened.ok());
    for (const char* key : {"fixedIn", "fixedAt", "fixBaseline", "fixCheck"}) CHECK_FALSE(reopened.value().contains(key));
}

TEST_CASE("feedback update: a gap fixed in the engine records the version but no baseline; a text without a version records nothing") {
    Json doc = create_empty_feedback("game", "9.9.9");
    FeedbackInput in;
    in.category = "physics";
    in.severity = "major";
    in.title = "No one-way platforms";
    in.missing = "Collider2D has no one-way option";
    in.workaround = "a script toggles the collider";
    REQUIRE(add_feedback_entry(doc, in).ok());
    auto a = update_feedback_entry(doc, "FB-0001", "fixed-in-engine", "pull request 12", "", "user");
    REQUIRE(a.ok());
    CHECK_FALSE(a.value().contains("fixedIn"));
    auto b = update_feedback_entry(doc, "FB-0001", "fixed-in-engine", "FactorIA 0.17.2.", "", "user");
    REQUIRE(b.ok());
    CHECK(b.value()["fixedIn"] == "0.17.2");
    CHECK_FALSE(b.value().contains("fixBaseline"));
}

TEST_CASE("feedback: record_fix_check writes on a fixed entry, in the file or its archive, and only there") {
    Game g;
    ScopedShareEnv scoped(g.env);
    CommandRegistry registry;
    register_feedback_commands(registry, g.dir.str());
    REQUIRE(registry.call("feedback.report", g.report(1, 40)).ok);
    const Json check = Json::object({{"result", "worked"}, {"ratio", 0.25}});
    auto open = record_fix_check(g.file(), "FB-0001", check);
    REQUIRE_FALSE(open.ok());  // still open: no fix to check
    CHECK(open.error().message.find("not fixed") != std::string::npos);
    REQUIRE(update_feedback_file(g.file(), "FB-0001", "fixed-in-engine", "FactorIA 0.17.2").ok());
    REQUIRE(record_fix_check(g.file(), "FB-0001", check).ok());
    CHECK(load_feedback(g.file()).value()["entries"][0]["fixCheck"] == check);
    CHECK_FALSE(record_fix_check(g.file(), "FB-0099", check).ok());
    // Archived: the check goes to the archive.
    REQUIRE(registry.call("feedback.archive", Json::object()).ok);
    const Json newer = Json::object({{"result", "no_change"}, {"ratio", 1.0}});
    REQUIRE(record_fix_check(g.file(), "FB-0001", newer).ok());
    CHECK(load_feedback(feedback_archive_path(g.file())).value()["entries"][0]["fixCheck"] == newer);
}

TEST_CASE("feedback collect: efficiency entries are ranked apart from the gaps, by fix type and by installation") {
    testing::TempDir dir;
    auto write = [&](const std::string& project, const Json& entries) {
        Json doc = create_empty_feedback(project, "9.9.9");
        doc["entries"] = entries;
        REQUIRE(save_feedback((dir.path / project / "ENGINE_FEEDBACK.json").string(), doc).ok());
    };
    auto eff = [](const std::string& id, const std::string& fixType, const std::string& trust, double minutes) {
        return Json::parse(R"({"id":")" + id + R"(","date":"2027-01-15","category":"scene","severity":"minor","title":"Quantum flux calibration routine",
            "missing":"Working out the order of the flux calibration calls took many steps","workaround":"none: the work went on with it",
            "occurrences":1,"status":"open","kind":"efficiency","waste":"Working out the order of the flux calibration calls took many steps",
            "fixType":")" + fixType + R"(","appliesTo":"every-game","measured":{"steps":40,"minutes":)" + std::to_string(minutes * 2) + R"(,"tokens":200000},
            "saving":{"steps":20,"minutes":)" + std::to_string(minutes) + R"(,"tokens":100000},"expectedSaving":{"share":0.5,"why":"x"},
            "remote":{"shareId":"r_)" + id + R"(","installKey":"k","trust":")" + trust + R"("}})");
    };
    Json gap = Json::parse(R"({"id":"FB-0002","date":"2027-01-15","category":"scene","severity":"major","title":"Quantum flux calibration routine",
        "missing":"The flux calibration is missing","workaround":"a script","occurrences":1,"status":"open"})");
    write("install-a", Json::array({eff("FB-0001", "doc", "verified", 30), gap}));
    write("install-b", Json::array({eff("FB-0001", "doc", "anonymous", 30), eff("FB-0003", "newCommand", "verified", 5)}));
    auto rep = collect_feedback({dir.str()});
    REQUIRE(rep.ok());
    CHECK(rep->json["totalEntries"] == 4);
    REQUIRE(rep->json["clusters"].size() == 1);  // only the gap
    CHECK(rep->json["clusters"][0]["entries"][0]["id"] == "FB-0002");
    const Json& e = rep->json["efficiency"];
    REQUIRE(e.size() == 2);  // doc and newCommand never mix, even with the same title
    CHECK(e[0]["fixType"] == "doc");
    CHECK(e[0]["installations"] == 2);
    CHECK(e[0]["total"]["minutes"] == 45.0);  // 30 verified + 30 x 0.5 anonymous
    CHECK(e[1]["fixType"] == "newCommand");
    CHECK(e[1]["verdict"]["code"] == "command-not-yet");
    const std::string md = rep->markdown();
    CHECK(md.find("Efficiency") != std::string::npos);
    CHECK(md.find("doc now") != std::string::npos);
    CHECK(md.find("feedback reject") != std::string::npos);
}
