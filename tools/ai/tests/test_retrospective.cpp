// The retrospective (fa/ai/retrospective.h): the mechanical pass over hand-made transcripts, the fast-role call with the fake provider
// (never a real model), the gate that every entry goes through, project facts, the busy guard and the automatic run after a long run.
#include <atomic>
#include <chrono>
#include <memory>
#include <set>
#include <thread>

#include "fa/ai/commands.h"
#include "fa/ai/retrospective.h"
#include "fa/ai/savers.h"
#include "fa/core/date.h"
#include "fa/tooling/feedback.h"
#include "fa/tooling/feedback_share.h"
#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;
namespace fsys = std::filesystem;

namespace {

constexpr std::int64_t kT0 = 1'793'000'000'000;  // ms: 2026-10-26

bool has(const std::string& text, const std::string& part) { return text.find(part) != std::string::npos; }

// One step of a built-in agent transcript: a model turn with one tool call.
struct Step {
    std::string command;        // "scene.load" runs through tool_call; a name without a dot ("Read") is a tool of its own
    Json args = Json::object();
    std::string code;           // an error code: the call failed with it
    int ms = 40;                // how long the tool took
    std::size_t bytes = 0;      // the full size of the result (0 = small)
    int seconds = 60;           // how long the step took
    std::uint64_t tokens = 5000;
};

std::string transcript(std::int64_t t0, const std::vector<Step>& steps) {
    std::string out = Json::object({{"kind", "start"}, {"t", iso_utc_ms(t0)}}).dump() + "\n";
    std::int64_t t = t0;
    int n = 0;
    for (const Step& s : steps) {
        const std::string id = "tu" + std::to_string(++n);
        const bool wrapped = s.command.find('.') != std::string::npos;
        Json call = wrapped ? Json::object({{"type", "tool_use"}, {"id", id}, {"name", "tool_call"},
                                            {"input", Json::object({{"command", s.command}, {"arguments", s.args}})}})
                            : Json::object({{"type", "tool_use"}, {"id", id}, {"name", s.command}, {"input", s.args}});
        out += Json::object({{"kind", "assistant"}, {"t", iso_utc_ms(t + s.seconds * 1000 - 1)},
                             {"usage", Json::object({{"inputTokens", s.tokens - 500}, {"outputTokens", 500}})},
                             {"costUsd", 0.05}, {"content", Json::array({call})}}).dump() + "\n";
        t += s.seconds * 1000;
        Json result = Json::object({{"toolUseId", id}, {"isError", !s.code.empty()}, {"ms", s.ms},
                                    {"content", s.code.empty() ? std::string("ok") : "{\"code\":\"" + s.code + "\",\"message\":\"no\"}"}});
        if (s.bytes) result["bytes"] = s.bytes;
        out += Json::object({{"kind", "tool_results"}, {"t", iso_utc_ms(t)}, {"results", Json::array({result})}}).dump() + "\n";
    }
    return out;
}

std::vector<Step> repeat(int n, const Step& s) { return std::vector<Step>(static_cast<std::size_t>(n), s); }
void append(std::vector<Step>& a, const std::vector<Step>& b) { a.insert(a.end(), b.begin(), b.end()); }

EfficiencySession session_of(const std::string& id, const std::vector<Step>& steps, std::int64_t t0 = kT0) {
    return read_efficiency_session(transcript(t0, steps), id);
}

const RetroCandidate* find(const std::vector<RetroCandidate>& list, const std::string& id) {
    for (const RetroCandidate& c : list)
        if (c.id == id) return &c;
    return nullptr;
}

std::vector<Step> failing_run() {
    std::vector<Step> steps = repeat(4, {"scene.inspect"});
    append(steps, repeat(20, {"scene.load", Json::object({{"scene", "main"}}), "not_found"}));
    append(steps, repeat(4, {"scene.inspect"}));
    return steps;
}

std::string entry_json(const std::string& candidate, const std::string& title, const std::string& fixType = "guide") {
    return Json::object({{"candidate", candidate}, {"category", "scene"}, {"title", title},
                         {"suggestion", "A topic guide that explains " + title + " step by step"},
                         {"waste", "Working out the order of the calls took many steps of trial and error"}, {"fixType", fixType},
                         {"appliesTo", "every-game"}, {"saveShare", 0.9}, {"saveWhy", "the guide gives the calls in order"},
                         {"whyNotCheaper", ""}, {"searched", Json::array()}, {"factLine", ""}}).dump();
}
std::string answer(const std::vector<std::string>& entries, const std::string& facts = "[]") {
    std::string list;
    for (const std::string& e : entries) list += (list.empty() ? "" : ",") + e;
    return "{\"entries\":[" + list + "],\"facts\":" + facts + "}";
}

struct Fixture {
    TempDir proj, home;
    CommandRegistry registry = make_registry();
    std::shared_ptr<FakeProvider> provider = std::make_shared<FakeProvider>();
    AiConfig cfg = default_config();
    std::unique_ptr<ScopedShareEnv> scoped;

    Fixture() {
        ShareEnv env;
        const std::string h = home.str();
        env.env = [h](const std::string& name) -> std::string { return name == "HOME" || name == "USERPROFILE" || name == "APPDATA" ? h : ""; };
        scoped = std::make_unique<ScopedShareEnv>(env);
        cfg.sourcePath = (home.path / "ai.json").string();
        AiCommandOptions o;
        o.loadConfig = [this]() -> Result<AiConfig> { return cfg; };
        o.projectDir = [this] { return proj.str(); };
        o.providerFactory = [this](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> {
            return std::static_pointer_cast<ChatProvider>(provider);
        };
        register_ai_commands(registry, o);
    }
    void session(const std::string& id, const std::vector<Step>& steps, std::int64_t t0 = kT0) {
        fsys::create_directories(proj.path / ".factoria" / "ai" / "sessions");
        std::ofstream(proj.path / ".factoria" / "ai" / "sessions" / (id + ".jsonl"), std::ios::binary) << transcript(t0, steps);
    }
    std::string feedback_file() const { return (proj.path / "ENGINE_FEEDBACK.json").string(); }
    Json entries() {
        auto doc = load_feedback(feedback_file());
        return doc.ok() ? (*doc)["entries"] : Json::array();
    }
    CommandResult retro(Json args = Json::object()) { return registry.call("ai.retrospective", args); }
};

}  // namespace

TEST_CASE("retrospective: a command that fails with the same code again and again is a candidate, with measured spans") {
    const EfficiencySession s = session_of("s1", failing_run());
    const auto found = find_retro_candidates({s});
    const RetroCandidate* c = find(found, "failure:scene.load:not_found");
    REQUIRE(c);
    CHECK(c->pattern == "failure");
    CHECK(c->count == 20);
    REQUIRE(c->spans.size() == 1);
    CHECK(c->spans[0].session == "s1");
    CHECK(c->spans[0].fromStep == 5);
    CHECK(c->spans[0].toStep == 24);
    CHECK(c->measured.steps == 20);
    CHECK(c->measured.minutes == doctest::Approx(20.0));
    CHECK(c->maxShare == doctest::Approx(0.9));
    CHECK(c->potential.minutes == doctest::Approx(18.0));
    CHECK(c->suggestedFix == "doc");
    CHECK_FALSE(c->summary.empty());
    // No clock, no model: the same transcripts always give the same candidates and numbers.
    CHECK(find_retro_candidates({session_of("s1", failing_run())})[0].to_json() == found[0].to_json());
}

TEST_CASE("retrospective: an efficient run, a few failures and small waste are not candidates") {
    std::vector<Step> steps = repeat(40, {"scene.inspect"});
    steps[5] = {"scene.load", Json::object(), "not_found"};
    steps[6] = {"scene.load", Json::object(), "not_found"};  // two failures: under the minimum of three
    CHECK(find_retro_candidates({session_of("s1", steps)}).empty());
    // Three failures in a short run: under the smallest saving that justifies any fix (10 minutes or 100k tokens)
    std::vector<Step> small = repeat(3, {"scene.load", Json::object(), "not_found"});
    CHECK(find_retro_candidates({session_of("s2", small)}).empty());
}

TEST_CASE("retrospective: the same doc read again and again, screenshots in a row, long waits, big results and loops") {
    std::vector<Step> rereads = repeat(30, {"docs.read", Json::object({{"topic", "NAVIGATION.md"}})});
    std::vector<Step> shots = repeat(30, {"game.screenshot"});
    std::vector<Step> waits = repeat(10, {"project.build", Json::object(), "", 100000, 0, 120});
    std::vector<Step> big;
    for (int i = 0; i < 2; ++i) {
        big.push_back({"scene.dump", Json::object(), "", 40, 400 * 1024, 60, 150000});
        big.push_back({"scene.inspect", Json::object(), "", 40, 0, 60, 150000});
    }
    std::vector<Step> loop;
    for (int i = 0; i < 15; ++i) {
        loop.push_back({"scene.inspect"});
        loop.push_back({"scene.set_field"});
    }
    const auto found = find_retro_candidates({session_of("a", rereads), session_of("b", shots, kT0 + 86400000), session_of("c", waits, kT0 + 2 * 86400000),
                                               session_of("d", big, kT0 + 3 * 86400000), session_of("e", loop, kT0 + 4 * 86400000)});
    const RetroCandidate* reread = find(found, "reread:docs.read:NAVIGATION.md");
    REQUIRE(reread);
    CHECK(reread->count == 30);
    CHECK_FALSE(reread->projectOnly);
    const RetroCandidate* screenshots = find(found, "screenshots");
    REQUIRE(screenshots);
    CHECK(screenshots->count == 30);
    CHECK(screenshots->spans[0].session == "b");
    const RetroCandidate* wait = find(found, "long_wait:project.build");
    REQUIRE(wait);
    CHECK(wait->count == 10);
    const RetroCandidate* result = find(found, "big_result:scene.dump");
    REQUIRE(result);
    CHECK(result->suggestedFix == "commandOption");
    CHECK(has(result->summary, "scene.dump"));
    const RetroCandidate* looped = find(found, "loop:scene");
    REQUIRE(looped);
    CHECK(looped->pattern == "loop");
    // ranked by what a fix would save, the largest first
    for (std::size_t i = 1; i < found.size(); ++i)
        CHECK(found[i - 1].potential.tokens + 5000.0 * found[i - 1].potential.minutes >= found[i].potential.tokens + 5000.0 * found[i].potential.minutes);
}

TEST_CASE("retrospective: a file of the project read again and again is a project-only candidate") {
    const auto found = find_retro_candidates({session_of("s1", repeat(30, {"Read", Json::object({{"file_path", "design/levels.md"}})}))});
    const RetroCandidate* c = find(found, "reread:Read:design/levels.md");
    REQUIRE(c);
    CHECK(c->projectOnly);
    CHECK(c->appliesTo == "this-game");
}

TEST_CASE("retrospective: a workaround ENGINE_FEEDBACK already records, called again and again") {
    std::vector<Step> steps = repeat(30, {"scene.nudge"});
    Json entries = Json::array({Json::object({{"id", "FB-0001"}, {"status", "open"}, {"title", "No smooth move"},
                                              {"missing", "There is no way to move an entity smoothly"},
                                              {"workaround", "A script calls scene.nudge every frame"}})});
    const auto found = find_retro_candidates({session_of("s1", steps)}, entries);
    const RetroCandidate* c = find(found, "workaround:FB-0001:scene.nudge");
    REQUIRE(c);
    CHECK(c->relatedEntry == "FB-0001");
}

TEST_CASE("retrospective: retrospective_due needs the switch and one of the two thresholds") {
    Savers sv;
    CHECK_FALSE(retrospective_due(sv, 1000, 100.0));  // off by default: it costs a model call nobody asked for
    sv.retrospective = true;
    CHECK_FALSE(retrospective_due(sv, 149, 2.99));
    CHECK(retrospective_due(sv, 150, 0));
    CHECK(retrospective_due(sv, 3, 3.0));
}

TEST_CASE("ai.retrospective: candidatesOnly runs no model and files nothing") {
    Fixture f;
    f.session("20261026-100000-orchestrator", failing_run());
    auto r = f.retro(Json::object({{"candidatesOnly", true}}));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    REQUIRE(r.result["candidates"].size() >= 1);
    CHECK(r.result["candidates"][0]["id"] == "failure:scene.load:not_found");
    CHECK(r.result["filed"].empty());
    CHECK(r.result["model"].is_null());
    CHECK(f.provider->calls == 0);
    CHECK(f.provider->requests.empty());
    CHECK_FALSE(fsys::exists(f.feedback_file()));
    CHECK(r.result["sessions"].size() == 1);
    CHECK(r.result["sessions"][0]["steps"] == 28);
}

TEST_CASE("ai.retrospective: the fast role writes the entry, the gate files it with measured numbers, a second run finds nothing new") {
    Fixture f;
    f.session("20261026-100000-orchestrator", failing_run());
    f.provider->script = {text_response(answer({entry_json("c1", "Quantum flux calibration order")}))};
    auto r = f.retro();
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    REQUIRE(f.provider->requests.size() == 1);
    const ChatRequest& req = f.provider->requests[0];
    CHECK(req.tools.empty());  // one short call, no tools
    REQUIRE(req.messages.size() == 1);
    CHECK(has(req.messages[0].text, "scene.load"));
    CHECK(has(req.messages[0].text, "c1"));
    CHECK(has(req.messages[0].text, "maxShare"));
    CHECK(r.result["model"]["role"] == "fast");
    REQUIRE(r.result["filed"].size() == 1);
    CHECK(r.result["filed"][0]["id"] == "FB-0001");
    CHECK(r.result["filed"][0]["measured"]["steps"] == 20);
    CHECK(r.result["usage"]["inputTokens"] == 100);
    CHECK(has(r.result["note"].get<std::string>(), "1 efficiency entry filed"));
    const Json entries = f.entries();
    REQUIRE(entries.size() == 1);
    CHECK(entries[0]["kind"] == "efficiency");
    CHECK(entries[0]["reporter"]["kind"] == "ai");
    CHECK(entries[0]["evidence"][0]["session"] == "20261026-100000-orchestrator");
    CHECK(entries[0]["evidence"][0]["fromStep"] == 5);
    CHECK(entries[0]["evidence"][0]["toStep"] == 24);
    CHECK(entries[0]["saving"]["minutes"].get<double>() == doctest::Approx(18.0));
    for (const auto& err : validate_feedback(*load_feedback(f.feedback_file()))) CHECK_MESSAGE(false, err.to_string());

    // The evidence is held by an open entry: nothing is asked again.
    auto again = f.retro();
    REQUIRE_MESSAGE(again.ok, again.error.dump());
    CHECK(f.provider->requests.size() == 1);
    CHECK(again.result["alreadyFiled"] == 1);
    CHECK(again.result["candidates"].empty());
    CHECK(has(again.result["note"].get<std::string>(), "already in efficiency entries"));
    CHECK(f.entries().size() == 1);
}

TEST_CASE("ai.retrospective: what the gate refuses comes back with its reason and nothing is filed") {
    Fixture f;
    f.session("20261026-100000-orchestrator", failing_run());
    f.provider->script = {text_response(answer({entry_json("c1", "Quantum flux calibration order", "newCommand")}))};  // no whyNotCheaper
    auto r = f.retro();
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["filed"].empty());
    REQUIRE(r.result["dropped"].size() == 1);
    CHECK(r.result["dropped"][0]["code"] == "not_cheapest");
    CHECK_FALSE(r.result["dropped"][0]["reason"].get<std::string>().empty());
    CHECK_FALSE(fsys::exists(f.feedback_file()));
}

TEST_CASE("ai.retrospective: at most three entries, candidates the model skips or invents are dropped") {
    Fixture f;
    f.session("20261026-100000-a", failing_run());
    f.session("20261026-110000-b", repeat(30, {"docs.read", Json::object({{"topic", "NAVIGATION.md"}})}), kT0 + 3600000);
    f.session("20261026-120000-c", repeat(30, {"game.screenshot"}), kT0 + 2 * 3600000);
    f.session("20261026-130000-d", repeat(10, {"project.build", Json::object(), "", 100000, 0, 120}), kT0 + 3 * 3600000);
    auto cands = f.retro(Json::object({{"candidatesOnly", true}}));
    REQUIRE(cands.ok);
    REQUIRE(cands.result["candidates"].size() == 4);
    f.provider->script = {text_response(answer({entry_json("c1", "Quantum flux calibration order"), entry_json("c2", "Zephyr lattice rebuild sequence"),
                                                entry_json("c3", "Obsidian ferry scheduling rule"), entry_json("c4", "Marble orbit alignment steps"),
                                                entry_json("c9", "Nothing here")}))};
    auto r = f.retro();
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["filed"].size() == 3);
    CHECK(f.entries().size() == 3);
    bool over = false, unknown = false;
    for (const Json& d : r.result["dropped"]) {
        over = over || d["code"] == "over_limit";
        unknown = unknown || d["code"] == "unknown_candidate";
    }
    CHECK(over);
    CHECK(unknown);
}

TEST_CASE("ai.retrospective: a lesson about this game alone becomes a project-fact proposal, not engine feedback") {
    Fixture f;
    f.session("20261026-100000-orchestrator", repeat(30, {"Read", Json::object({{"file_path", "design/levels.md"}})}));
    f.provider->script = {text_response(answer({}, R"([{"candidate":"c1","line":"design/levels.md holds the level plan: read it once."}])"))};
    auto r = f.retro();
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["filed"].empty());
    REQUIRE(r.result["facts"].size() == 1);
    CHECK_FALSE(fsys::exists(f.feedback_file()));
    CHECK_FALSE(fsys::exists(f.proj.path / "AGENTS.md"));  // nothing is written there until the user accepts
    auto state = f.registry.call("ai.savers");
    REQUIRE(state.ok);
    REQUIRE(state.result["proposals"]["facts"].size() == 1);
    CHECK(has(state.result["proposals"]["facts"][0]["line"].get<std::string>(), "design/levels.md"));
    // With the facts saver off the proposal is not made.
    f.cfg.savers.projectFacts = false;
    f.provider->script = {text_response(answer({}, R"([{"candidate":"c1","line":"another line"}])"))};
    auto off = f.retro();
    REQUIRE(off.ok);
    CHECK(off.result["facts"].empty());
}

TEST_CASE("ai.retrospective: since and sessions pick the transcripts; mistakes teach") {
    Fixture f;
    f.session("20261001-100000-orchestrator", failing_run(), kT0 - 25 * 86400000LL);
    f.session("20261026-100000-orchestrator", failing_run());
    auto since = f.retro(Json::object({{"since", "2026-10-20"}, {"candidatesOnly", true}}));
    REQUIRE_MESSAGE(since.ok, since.error.dump());
    REQUIRE(since.result["sessions"].size() == 1);
    CHECK(since.result["sessions"][0]["id"] == "20261026-100000-orchestrator");
    auto named = f.retro(Json::object({{"sessions", Json::array({"20261001-100000-orchestrator"})}, {"candidatesOnly", true}}));
    REQUIRE(named.ok);
    CHECK(named.result["sessions"][0]["id"] == "20261001-100000-orchestrator");
    auto badDate = f.retro(Json::object({{"since", "last week"}}));
    REQUIRE_FALSE(badDate.ok);
    CHECK(badDate.error["code"] == "invalid_arguments");
    CHECK(has(badDate.error["message"].get<std::string>(), "since"));
    CHECK_FALSE(badDate.error["hint"].get<std::string>().empty());
    auto missing = f.retro(Json::object({{"sessions", Json::array({"20261026-100000-orchestrater"})}}));
    REQUIRE_FALSE(missing.ok);
    CHECK(has(missing.error.dump(), "20261026-100000-orchestrator"));  // did you mean
    auto notAName = f.retro(Json::object({{"sessions", Json::array({7})}}));
    REQUIRE_FALSE(notAName.ok);
    CHECK(has(notAName.error["message"].get<std::string>(), "/sessions"));
}

TEST_CASE("ai.retrospective: a transcript that is too big is left out with its reason, the others are read") {
    Fixture f;
    f.session("20261026-100000-orchestrator", failing_run());
    f.session("20261026-110000-orchestrator", failing_run());
    // A 3 MB transcript against a per-transcript limit of 2 MB (the real limit is 64 MB: the test lowers it instead of writing that much).
    const fsys::path huge = f.proj.path / ".factoria" / "ai" / "sessions" / "20261026-120000-orchestrator.jsonl";
    fsys::create_directories(huge.parent_path());
    std::error_code ec;
    {
        std::ofstream out(huge, std::ios::binary);
        out << std::string(3u * 1024 * 1024, ' ');
    }
    RetrospectiveOptions ro;
    ro.candidatesOnly = true;
    ro.maxTranscriptBytes = 2u * 1024 * 1024;
    auto r = run_retrospective(f.cfg, ro, f.proj.str());
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : r.error().message));
    CHECK(r->sessions.size() == 2);
    REQUIRE(r->skipped.size() == 1);
    CHECK(r->skipped[0]["id"] == "20261026-120000-orchestrator");
    CHECK(has(r->skipped[0]["reason"].get<std::string>(), "MB"));
    CHECK(has(r->to_json().value("note", std::string()), "1 transcript(s) were not read"));  // the note of the answer lists them
    // Named on purpose, it is an error that says why instead of a silent skip.
    RetrospectiveOptions named = ro;
    named.sessions = {"20261026-120000-orchestrator"};
    auto refused = run_retrospective(f.cfg, named, f.proj.str());
    REQUIRE_FALSE(refused.ok());
    CHECK(has(refused.error().message, "MB"));
    fsys::remove(huge, ec);
}

TEST_CASE("ai.retrospective: the order of the candidates and the spans does not depend on the order of the transcripts") {
    // Two patterns that cost exactly the same: they are told apart by id, whatever order the sessions come in.
    const EfficiencySession a = session_of("20261026-100000-orchestrator", repeat(20, {"scene.load", Json::object({{"scene", "main"}}), "not_found"}));
    const EfficiencySession b = session_of("20261026-110000-orchestrator", repeat(20, {"scene.save", Json::object({{"scene", "main"}}), "not_found"}));
    const auto forward = find_retro_candidates({a, b}, Json::array());
    const auto backward = find_retro_candidates({b, a}, Json::array());
    REQUIRE(forward.size() == 2);
    REQUIRE(backward.size() == 2);
    for (std::size_t i = 0; i < 2; ++i) CHECK(forward[i].id == backward[i].id);
    CHECK(forward[0].potential.to_json() == forward[1].potential.to_json());
    CHECK(forward[0].id < forward[1].id);  // equal cost: by id
}

TEST_CASE("ai.retrospective: idPrefix with a dash keeps a run's own transcripts, not those of a run begun in the same second") {
    Fixture f;
    f.session("20261026-100000-orchestrator", failing_run());
    f.session("20261026-100000-2-orchestrator", failing_run());
    f.session("20261026-100000-orchestrator-1", failing_run());  // a delegate of the first run
    f.session("20261026-1000007-orchestrator", failing_run());
    RetrospectiveOptions ro;
    ro.candidatesOnly = true;
    ro.idPrefix = "20261026-100000-";
    auto r = run_retrospective(f.cfg, ro, f.proj.str());
    REQUIRE(r.ok());
    std::set<std::string> ids;
    for (const Json& s : r->sessions) ids.insert(s["id"].get<std::string>());
    CHECK(ids == std::set<std::string>{"20261026-100000-orchestrator", "20261026-100000-orchestrator-1"});
}

TEST_CASE("ai.retrospective: no transcripts, or nothing wasted, says so and asks no model") {
    Fixture f;
    auto none = f.retro();
    REQUIRE_MESSAGE(none.ok, none.error.dump());
    CHECK(none.result["sessions"].empty());
    CHECK(has(none.result["note"].get<std::string>(), "No transcript"));
    f.session("20261026-100000-orchestrator", repeat(40, {"scene.inspect"}));
    auto fine = f.retro();
    REQUIRE(fine.ok);
    CHECK(fine.result["candidates"].empty());
    CHECK(f.provider->calls == 0);
}

TEST_CASE("ai.retrospective: the model failing or answering with something else keeps the candidates and files nothing") {
    Fixture f;
    f.session("20261026-100000-orchestrator", failing_run());
    f.provider->script = {text_response("I could not decide.")};
    auto r = f.retro();
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["candidates"].size() >= 1);
    CHECK(r.result["filed"].empty());
    CHECK(has(r.result["note"].get<std::string>(), "JSON"));
    f.provider->script.clear();
    f.provider->calls = 0;  // the script is exhausted: the provider answers with an error
    auto err = f.retro();
    REQUIRE(err.ok);
    CHECK(has(err.result["note"].get<std::string>(), "did not answer"));
    CHECK_FALSE(fsys::exists(f.feedback_file()));
}

namespace {
// A provider that waits for its answer until the cancel flag it was given is set (a stuck connection): it gives up after a long time,
// so a retrospective that does not pass the flag on fails the test instead of hanging it.
class WaitingProvider : public FakeProvider {
public:
    Result<ChatResponse> chat(const ChatRequest&, const ChatHooks&, const CancelFlag* cancel) override {
        sawFlag = cancel != nullptr;
        entered = true;
        for (int i = 0; i < 2000 && !is_cancelled(cancel); ++i) std::this_thread::sleep_for(std::chrono::milliseconds(5));
        return is_cancelled(cancel) ? make_error("cancelled") : make_error("gave up waiting");
    }
    std::atomic<bool> entered{false};
    bool sawFlag = false;
};
}  // namespace

TEST_CASE("ai.retrospective: Stop reaches the model call, which returns at once and files nothing") {
    Fixture f;
    f.session("20261026-100000-orchestrator", failing_run());
    auto waiting = std::make_shared<WaitingProvider>();
    CancelFlag stop{false};
    RetrospectiveOptions ro;
    ro.cancel = &stop;
    ro.providerFactory = [&](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> { return std::static_pointer_cast<ChatProvider>(waiting); };
    // Bounded: a run that never reaches the model call still gets its Stop (and fails the checks below) instead of hanging the test.
    std::thread stopper([&] {
        for (int i = 0; i < 6000 && !waiting->entered; ++i) std::this_thread::sleep_for(std::chrono::milliseconds(1));
        stop = true;
    });
    const auto began = std::chrono::steady_clock::now();
    auto r = run_retrospective(f.cfg, ro, f.proj.str());
    stopper.join();
    const auto waited = std::chrono::steady_clock::now() - began;
    // A stopped retrospective is cancelled, not "finished with a note": the caller (the CLI, the panel) shows that it was stopped.
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.rfind("cancelled", 0) == 0);
    CHECK(waiting->sawFlag);
    CHECK(waited < std::chrono::seconds(8));  // the provider's own give-up is 10 s
    CHECK_FALSE(fsys::exists(f.feedback_file()));
}

namespace {
// A provider that tries to start a retrospective from inside the model call of one.
class NestingProvider : public FakeProvider {
public:
    Result<ChatResponse> chat(const ChatRequest& req, const ChatHooks& hooks, const CancelFlag* cancel) override {
        if (nested) nestedReply = nested();
        return FakeProvider::chat(req, hooks, cancel);
    }
    std::function<CommandResult()> nested;
    CommandResult nestedReply;
};
}  // namespace

TEST_CASE("ai.retrospective: never inside another retrospective") {
    Fixture f;
    auto nesting = std::make_shared<NestingProvider>();
    nesting->nested = [&] { return f.retro(Json::object({{"candidatesOnly", true}})); };
    nesting->script = {text_response(answer({}))};
    f.provider = nesting;
    f.session("20261026-100000-orchestrator", failing_run());
    CHECK_FALSE(retrospective_running_here());
    auto r = f.retro();
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    REQUIRE_FALSE(nesting->nestedReply.ok);
    CHECK(nesting->nestedReply.error["code"] == "busy");
    CHECK_FALSE(retrospective_running_here());
    CHECK(f.retro(Json::object({{"candidatesOnly", true}})).ok);  // free again afterwards
}

namespace {
// A run of the built-in loop whose first step fails three times with 150k tokens: long enough for the automatic retrospective.
struct AutoFixture : Fixture {
    ToolCall failing(const std::string& id) {
        ToolCall c;
        c.id = id;
        c.name = "project_validate";
        return c;
    }
    ChatResponse heavy_step() {
        ChatResponse r = tool_response({failing("a"), failing("b"), failing("c")});
        r.usage.inputTokens = 150000;
        r.usage.outputTokens = 500;
        return r;
    }
    std::vector<AgentEvent> events;
    SessionResult run() {
        SessionOptions so;
        so.projectDir = proj.str();
        so.env = fake_env({{"HOME", home.str()}});
        so.extensionsTrustPath = (home.path / "ai-trust.json").string();
        AgentSession s(registry, cfg, so);
        s.set_provider_factory([this](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> {
            return std::static_pointer_cast<ChatProvider>(provider);
        });
        s.set_event_handler([this](const AgentEvent& e) { events.push_back(e); });
        return s.run("go");
    }
    bool said(const std::string& part) const {
        for (const auto& e : events)
            if (e.type == AgentEvent::Type::Info && has(e.text, part)) return true;
        return false;
    }
};
}  // namespace

TEST_CASE("savers.retrospective: off by default, a long run does not start one") {
    AutoFixture f;
    f.cfg.savers.retrospectiveSteps = 2;
    f.provider->script = {f.heavy_step(), text_response("done")};
    auto r = f.run();
    REQUIRE(r.ok);
    CHECK(f.provider->calls == 2);
    CHECK_FALSE(fsys::exists(f.feedback_file()));
}

TEST_CASE("savers.retrospective: a run over the threshold gets one retrospective whose cost is added to the run") {
    AutoFixture f;
    f.cfg.savers.retrospective = true;
    f.cfg.savers.retrospectiveSteps = 2;
    f.provider->script = {f.heavy_step(), text_response("done"), text_response(answer({entry_json("c1", "Quantum flux calibration order")}))};
    auto r = f.run();
    REQUIRE_MESSAGE(r.ok, r.error);
    REQUIRE(f.provider->calls == 3);  // the two steps of the run and one retrospective call
    CHECK(f.provider->requests[2].tools.empty());
    CHECK(r.usage.inputTokens == 150000 + 100 + 100);  // the retrospective's tokens are the run's
    CHECK(f.said("Retrospective: 1 efficiency entry filed"));
    const Json entries = f.entries();
    REQUIRE(entries.size() == 1);
    CHECK(entries[0]["kind"] == "efficiency");
    CHECK(has(entries[0]["evidence"][0]["session"].get<std::string>(), "-orchestrator"));
}

TEST_CASE("savers.retrospective: a run under both thresholds starts none") {
    AutoFixture f;
    f.cfg.savers.retrospective = true;  // defaults: 150 steps or $3
    f.provider->script = {f.heavy_step(), text_response("done")};
    REQUIRE(f.run().ok);
    CHECK(f.provider->calls == 2);
}

// ---------------------------------------------------------------------------------------------------- did the fix work?

namespace {

constexpr std::int64_t kDay = 86'400'000;  // ms

// An efficiency entry the engine fixed in `fixedIn` on 2026-10-27: its pattern and what one occurrence cost before (20 steps, 20 minutes,
// 100000 tokens).
Json fixed_entry(const std::string& id = "FB-0001", const std::string& fixedIn = "0.17.2") {
    return Json::parse(R"({"id":")" + id + R"(","kind":"efficiency","status":"fixed-in-engine","pattern":"failure:scene.load:not_found",
        "fixedIn":")" + fixedIn + R"(","fixedAt":"2026-10-27","fixBaseline":{"spans":1,"steps":20,"minutes":20,"tokens":100000}})");
}

std::vector<Step> failing_run_of(int failures) {
    std::vector<Step> steps = repeat(4, {"scene.inspect"});
    append(steps, repeat(failures, {"scene.load", Json::object({{"scene", "main"}}), "not_found"}));
    append(steps, repeat(4, {"scene.inspect"}));
    return steps;
}

}  // namespace

TEST_CASE("fix check: the same pattern after the fix is compared with what it cost before") {
    const Json entries = Json::array({fixed_entry()});
    const std::int64_t after = kT0 + 2 * kDay;  // 2026-10-28
    SUBCASE("no run since the fix: waiting") {
        const auto checks = check_efficiency_fixes({session_of("20261026-100000-orchestrator", failing_run())}, entries, "0.17.2");
        REQUIRE(checks.size() == 1);
        CHECK(checks[0].result == "waiting");
        CHECK(checks[0].sessionsAfter == 0);
    }
    SUBCASE("the pattern is not found any more: gone") {
        const auto checks = check_efficiency_fixes({session_of("20261028-100000-orchestrator", repeat(30, {"scene.inspect"}), after)}, entries, "0.17.2");
        REQUIRE(checks.size() == 1);
        CHECK(checks[0].result == "gone");
        CHECK(checks[0].sessionsAfter == 1);
        CHECK(checks[0].ratio == 0);
        CHECK(has(checks[0].text, "it worked"));
    }
    SUBCASE("it costs the same: no_change; about half: partial; a lot less: worked") {
        auto result = [&](int failures) {
            const auto c = check_efficiency_fixes({session_of("20261028-100000-orchestrator", failing_run_of(failures), after)}, entries, "0.17.2");
            REQUIRE(c.size() == 1);
            return c[0];
        };
        const FixCheck same = result(20);
        CHECK(same.result == "no_change");
        CHECK(same.ratio == doctest::Approx(1.0).epsilon(0.05));
        CHECK(same.spansAfter == 1);
        CHECK(has(same.text, "No change"));
        const FixCheck half = result(14);
        CHECK(half.result == "partial");
        CHECK(half.ratio > 0.5);
        CHECK(half.ratio <= 0.8);
        const FixCheck better = result(6);
        CHECK(better.result == "worked");
        CHECK(better.ratio <= 0.5);
        CHECK(better.after["steps"] == 6);
    }
    SUBCASE("runs from before the fix do not count") {
        const auto checks = check_efficiency_fixes({session_of("20261026-100000-orchestrator", failing_run()),
                                                    session_of("20261028-100000-orchestrator", repeat(30, {"scene.inspect"}), after)}, entries, "0.17.2");
        REQUIRE(checks.size() == 1);
        CHECK(checks[0].result == "gone");
        CHECK(checks[0].sessionsAfter == 1);
    }
    SUBCASE("a game on an older engine is not checked, and an entry without a pattern or baseline is left out") {
        const std::vector<EfficiencySession> s = {session_of("20261028-100000-orchestrator", failing_run(), after)};
        CHECK(check_efficiency_fixes(s, entries, "0.17.1").empty());
        CHECK(check_efficiency_fixes(s, entries, "0.17.2-rc1").size() == 1);
        CHECK(check_efficiency_fixes(s, entries, "0.18.0").size() == 1);
        Json noPattern = fixed_entry();
        noPattern.erase("pattern");
        Json noBase = fixed_entry("FB-0002");
        noBase.erase("fixBaseline");
        Json open = fixed_entry("FB-0003");
        open["status"] = "open";
        CHECK(check_efficiency_fixes(s, Json::array({noPattern, noBase, open}), "0.17.2").empty());
    }
    SUBCASE("ordered by entry id, the same input gives the same answer") {
        const std::vector<EfficiencySession> s = {session_of("20261028-100000-orchestrator", failing_run(), after)};
        const Json both = Json::array({fixed_entry("FB-0009"), fixed_entry("FB-0002")});
        const auto a = check_efficiency_fixes(s, both, "0.17.2");
        const auto b = check_efficiency_fixes(s, both, "0.17.2");
        REQUIRE(a.size() == 2);
        CHECK(a[0].entry == "FB-0002");
        CHECK(a[0].to_json() == b[0].to_json());
    }
}

TEST_CASE("ai.retrospective: a fix that saved nothing shows in the next retrospective, is recorded on the entry and the pattern is filed again with afterFix") {
    Fixture f;
    f.session("20261026-100000-orchestrator", failing_run());
    f.provider->script = {text_response(answer({entry_json("c1", "Quantum flux calibration order")}))};
    REQUIRE(f.retro().ok);
    REQUIRE(f.entries().size() == 1);
    CHECK(f.entries()[0]["pattern"] == "failure:scene.load:not_found");  // kept for the check, never shared

    // The engine developer fixed it in 0.1.0, which every build is at least (the day is set by hand: the test does not read the clock).
    REQUIRE(update_feedback_file(f.feedback_file(), "FB-0001", "fixed-in-engine", "FactorIA 0.1.0").ok());
    Json doc = *load_feedback(f.feedback_file());
    CHECK(doc["entries"][0]["fixBaseline"]["steps"] == 20);
    doc["entries"][0]["fixedAt"] = "2026-10-27";
    REQUIRE(save_feedback(f.feedback_file(), doc).ok());

    // Two days later the game did the same again.
    f.session("20261028-100000-orchestrator", failing_run(), kT0 + 2 * kDay);
    f.provider->script = {text_response(answer({entry_json("c1", "Quantum flux calibration order")}))};
    f.provider->calls = 0;
    auto r = f.retro(Json::object({{"since", "2026-10-26"}}));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    REQUIRE(r.result["fixChecks"].size() == 1);
    CHECK(r.result["fixChecks"][0]["result"] == "no_change");
    CHECK(r.result["fixChecks"][0]["entry"] == "FB-0001");
    const Json entries = f.entries();
    REQUIRE(entries.size() >= 1);
    CHECK(entries[0]["fixCheck"]["result"] == "no_change");
    CHECK(entries[0]["fixCheck"]["ratio"].get<double>() > 0.8);
    bool refiled = false;
    for (const Json& e : entries)
        if (e.value("afterFix", std::string()) == "0.1.0") refiled = true;
    CHECK_MESSAGE(refiled, r.result.dump(1));
}

TEST_CASE("ai.retrospective: candidatesOnly checks the fixes but writes nothing") {
    Fixture f;
    Json doc = create_empty_feedback("g");
    doc["entries"] = Json::array({fixed_entry("FB-0001", "0.0.1")});
    doc["entries"][0].update(Json::parse(R"({"date":"2026-10-20","category":"scene","severity":"minor","title":"Flux calibration",
        "missing":"The order of the calls took many steps","workaround":"none","occurrences":1,"waste":"The order of the calls took many steps",
        "fixType":"guide","appliesTo":"every-game","measured":{"steps":20},"saving":{"steps":10},"expectedSaving":{"share":0.5,"why":"x"}})"));
    REQUIRE(save_feedback(f.feedback_file(), doc).ok());
    f.session("20261028-100000-orchestrator", failing_run(), kT0 + 2 * kDay);
    auto r = f.retro(Json::object({{"candidatesOnly", true}}));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    REQUIRE(r.result["fixChecks"].size() == 1);
    CHECK(r.result["fixChecks"][0]["result"] == "no_change");
    CHECK_FALSE(f.entries()[0].contains("fixCheck"));
    CHECK(f.provider->requests.empty());
}

// ------------------------------------------------------------------------ the fix checks are written under the feedback file's lock

namespace {
// A project whose feedback file has two entries the engine fixed (the same pattern, so one run after the fix checks both) and a run after
// the fix; the fix checks are about to be written on them.
struct FixCheckFixture : Fixture {
    ScopedShareEnv waits;
    static ShareEnv short_waits(const std::string& home, double waitSec) {
        ShareEnv env;
        env.env = [home](const std::string& name) -> std::string { return name == "HOME" || name == "USERPROFILE" || name == "APPDATA" ? home : ""; };
        env.lockWaitSec = waitSec;
        env.lockStaleSec = 600.0;
        return env;
    }
    explicit FixCheckFixture(double waitSec) : waits(short_waits(home.str(), waitSec)) {
        Json doc = create_empty_feedback("g");
        doc["entries"] = Json::array({fixed_entry("FB-0001"), fixed_entry("FB-0002")});
        REQUIRE(save_feedback(feedback_file(), doc).ok());
        session("20261028-100000-orchestrator", failing_run_of(20), kT0 + 2 * kDay);
        provider->script = {text_response(answer({}))};
    }
    fsys::path busy_lock() const { return proj.path / ".factoria" / kFeedbackShareLockFile; }
    void hold_busy_lock() const {
        fsys::create_directories(proj.path / ".factoria");
        std::ofstream(busy_lock(), std::ios::binary) << "alive";
    }
};
}  // namespace

TEST_CASE("ai.retrospective: a feedback file whose lock stays busy keeps the fix checks off the entries, says why, and stops trying") {
    FixCheckFixture f(0.2);
    f.hold_busy_lock();  // another program holds the project's lock for the whole test
    RetrospectiveOptions ro;
    ro.engineVersion = "0.17.2";
    ro.providerFactory = [&](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> { return std::static_pointer_cast<ChatProvider>(f.provider); };
    auto r = run_retrospective(f.cfg, ro, f.proj.str());
    REQUIRE_MESSAGE(r.ok(), (r.ok() ? std::string() : r.error().message));
    CHECK(r->fixChecks.size() == 2);                            // the checks are in the result whatever the file says
    CHECK(has(r->fixCheckProblem, "Another FactorIA process"));  // the lock's own words
    CHECK(has(r->to_json().dump(), "Another FactorIA process"));
    fsys::remove(f.busy_lock());
    const Json entries = f.entries();
    REQUIRE(entries.size() == 2);
    CHECK_FALSE(entries[0].contains("fixCheck"));
    CHECK_FALSE(entries[1].contains("fixCheck"));
}

TEST_CASE("ai.retrospective: Stop during the fix checks writes no more notes and returns cancelled") {
    FixCheckFixture f(5.0);
    f.hold_busy_lock();
    CancelFlag stop{false};
    RetrospectiveOptions ro;
    ro.engineVersion = "0.17.2";
    ro.cancel = &stop;
    ro.providerFactory = [&](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> { return std::static_pointer_cast<ChatProvider>(f.provider); };
    // Stop first, then the other program lets go: the retrospective gets the lock after it was asked to stop.
    std::thread stopper([&] {
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
        stop = true;
        std::error_code ec;
        fsys::remove(f.busy_lock(), ec);
    });
    auto r = run_retrospective(f.cfg, ro, f.proj.str());
    stopper.join();
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.rfind("cancelled", 0) == 0);
    const Json entries = f.entries();
    REQUIRE(entries.size() == 2);
    CHECK_FALSE(entries[1].contains("fixCheck"));  // nothing was written once Stop was set
}
