// The engine developer's side of feedback sharing: pull (paging, cursor, merge, --full), classification, quarantine, bans,
// delete, stats and `fixed`. The server and the model are fakes: nothing here touches the network or an AI.
#include <doctest.h>

#include <filesystem>
#include <fstream>
#include <sstream>

#include "feedback_admin.h"
#include "fa/cli/cli.h"
#include "fa/core/fs.h"
#include "fa/core/json.h"

using namespace fa;
using namespace fa::cli;
namespace stdfs = std::filesystem;

namespace {

struct Run {
    int code;
    std::string out, err;
};
Run run(std::vector<std::string> args) {
    std::ostringstream out, err;
    std::istringstream in;
    int code = cli_main(args, out, err, in);
    return {code, out.str(), err.str()};
}

std::string slurp(const stdfs::path& p) {
    std::ifstream in(p, std::ios::binary);
    return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
}
void spit(const stdfs::path& p, const std::string& s) {
    stdfs::create_directories(p.parent_path());
    std::ofstream(p, std::ios::binary) << s;
}
Json slurp_json(const stdfs::path& p) { return Json::parse(slurp(p)); }

const std::string kKeyA = "aaaaaaaaaaaaaaaa";       // the server's keys are exactly 16 characters
const std::string kKeyB = "bbbbbbbbbbbbbbbb";

Json report(const std::string& shareId, const std::string& installKey, const std::string& title, int occurrences = 1,
            const std::string& trust = "anonymous") {
    return Json::object({{"shareId", shareId}, {"installKey", installKey}, {"reporterKey", trust == "verified" ? Json("rrrrrrrrrrrrrrrr") : Json(nullptr)},
                         {"trust", trust}, {"receivedAt", "2026-10-20T10:00:00Z"}, {"occurrences", occurrences}, {"engineVersion", "0.10.0"},
                         {"platform", "macos"}, {"category", "physics"}, {"severity", "major"}, {"effort", "small"}, {"title", title},
                         {"missing", "The engine lacks " + title}, {"suggestion", "Add it"}, {"workaround", ""}, {"reporterKind", "ai"},
                         {"reviewed", false}});
}

// A fake feedback server: reports in arrival order, cursors "c<N>", every request recorded.
struct FakeServer {
    std::vector<Json> reports;
    std::vector<ai::HttpRequest> requests;
    std::map<std::string, ai::HttpResponse> fixed;  // "METHOD path-prefix" -> canned answer, wins over the logic below
    Json bans = Json::array();

    ai::HttpResponse json(int status, const Json& body) {
        ai::HttpResponse r;
        r.status = status;
        r.body = body.dump();
        return r;
    }
    ai::HttpResponse handle(const ai::HttpRequest& req) {
        requests.push_back(req);
        for (const auto& [k, v] : fixed)
            if ((req.method + " " + req.url).find(k) != std::string::npos) return v;
        const std::size_t q = req.url.find("/v1/");
        const std::string path = req.url.substr(q);
        if (path.rfind("/v1/admin/reports?", 0) == 0) {
            std::size_t after = 0, limit = 500;
            if (auto s = path.find("since=c"); s != std::string::npos) after = std::stoul(path.substr(s + 7));
            if (auto l = path.find("limit="); l != std::string::npos) limit = std::stoul(path.substr(l + 6));
            Json page = Json::array();
            std::size_t last = after;
            for (std::size_t i = after; i < reports.size() && page.size() < limit; ++i) {
                page.push_back(reports[i]);
                last = i + 1;
            }
            return json(200, Json::object({{"ok", true}, {"reports", page}, {"next", last == 0 ? Json(nullptr) : Json("c" + std::to_string(last))}}));
        }
        if (path == "/v1/admin/bans") return json(200, Json::object({{"ok", true}, {"bans", bans}}));
        if (path == "/v1/admin/ban") return json(200, Json::object({{"ok", true}, {"banned", Json::object({{"kind", "install"}, {"key", "x"}})}, {"purged", 2}}));
        if (path == "/v1/admin/unban") return json(200, Json::object({{"ok", true}, {"removed", true}}));
        if (path.rfind("/v1/admin/reports/", 0) == 0) return json(200, Json::object({{"ok", true}, {"deleted", path.substr(18)}}));
        if (path == "/v1/admin/stats")
            return json(200, Json::object({{"ok", true}, {"totals", Json::object({{"reports", 7}, {"installations", 3}, {"bans", 1}})},
                                          {"days", Json::array({Json::object({{"day", "2026-10-31"}, {"accepted", 2}, {"rejected", 1}, {"rejections", Json::object({{"too_short", 1}})}}),
                                                                Json::object({{"day", "2026-10-30"}, {"accepted", 0}})})}}));
        return json(404, Json::object({{"ok", false}, {"error", Json::object({{"code", "not_found"}, {"message", path + " is not an endpoint."}, {"hint", "x"}})}}));
    }
    std::string last_path() const { return requests.empty() ? std::string() : requests.back().url.substr(requests.back().url.find("/v1/")); }
};

// The process-wide environment of the commands, pointed at a temp dir and a fake server for one test.
struct Fixture {
    stdfs::path dir;
    FakeServer server;
    std::string adminFile, inbox;
    int modelCalls = 0;
    std::map<std::string, std::string> env;

    explicit Fixture(bool configured = true) {
        dir = fs::make_temp_dir("fa_feedback_admin");
        env["FACTORIA_AI_CONFIG"] = (dir / "cfg" / "ai.json").string();
        adminFile = (dir / "cfg" / "feedback-admin.json").string();
        inbox = (dir / "cfg" / "feedback-inbox").string();
        if (configured) spit(adminFile, R"({"endpoint": "https://feedback.example.test/", "adminToken": "tok-secret", "other": 1})");
        FeedbackAdminEnv& e = feedback_admin_env();
        e = FeedbackAdminEnv{};
        e.env = [this](const std::string& n) { auto it = env.find(n); return it == env.end() ? std::string() : it->second; };
        e.transport = [this](const ai::HttpRequest& r) { return server.handle(r); };
        e.today = [] { return std::string("2026-10-31"); };
    }
    ~Fixture() {
        feedback_admin_env() = FeedbackAdminEnv{};
        std::error_code ec;
        stdfs::remove_all(dir, ec);
    }
    // Pull with the AI turned off unless a model was set.
    Run pull(std::vector<std::string> extra = {}) {
        std::vector<std::string> a = {"feedback", "pull", "--out", inbox};
        a.insert(a.end(), extra.begin(), extra.end());
        return run(a);
    }
    std::string cursor() const { return slurp_json(adminFile).value("cursor", std::string()); }
    Json entries_of(const std::string& key) const { return slurp_json(stdfs::path(inbox) / key / "ENGINE_FEEDBACK.json")["entries"]; }
    void model_says(const std::string& verdict, const std::string& which = {}) {
        feedback_admin_env().model = [this, verdict, which](const std::string&, const std::string& user) -> Result<std::string> {
            ++modelCalls;
            Json out = Json::array();
            std::size_t pos = 0;
            while ((pos = user.find("\"id\": \"", pos)) != std::string::npos) {
                pos += 7;
                std::string id = user.substr(pos, user.find('"', pos) - pos);
                out.push_back(Json::object({{"id", id}, {"verdict", which.empty() || which == id ? verdict : "valid"}, {"reason", "because " + id}}));
            }
            return "Here you go:\n" + out.dump();
        };
    }
};

}  // namespace

TEST_CASE("feedback pull: pages through the server, writes one file per installation, saves the cursor last") {
    Fixture f;
    f.server.reports = {report("r_1", kKeyA, "No one-way platforms"), report("r_2", kKeyB, "Audio cannot loop", 3, "verified"),
                        report("r_3", kKeyA, "Tilemap collisions are slow"), report("r_4", kKeyA, "Particles cannot collide"),
                        report("r_5", kKeyB, "Sprites flicker")};
    PullOptions po;
    po.out = f.inbox;
    po.outExplicit = true;
    po.classify = ClassifyMode::Off;
    po.pageSize = 2;
    auto r = feedback_pull(po, feedback_admin_env());
    REQUIRE(r.ok());
    CHECK(r->fetched == 5);
    CHECK(r->pages == 3);
    CHECK(r->added == 5);
    CHECK(r->classification.find("skipped") != std::string::npos);
    CHECK(r->installations.size() == 2);
    // Paging: limit on every request, the cursor of the previous answer in the next one.
    REQUIRE(f.server.requests.size() == 3);
    CHECK(f.server.requests[0].url == "https://feedback.example.test/v1/admin/reports?limit=2");
    CHECK(f.server.requests[1].url.find("since=c2") != std::string::npos);
    CHECK(f.server.requests[2].url.find("since=c4") != std::string::npos);
    CHECK(f.server.requests[0].headers[0].second == "Bearer tok-secret");

    Json a = f.entries_of(kKeyA), b = f.entries_of(kKeyB);
    REQUIRE(a.size() == 3);
    REQUIRE(b.size() == 2);
    CHECK(slurp_json(stdfs::path(f.inbox) / kKeyA / "ENGINE_FEEDBACK.json")["project"] == "install-" + kKeyA);
    CHECK(a[0]["id"] == "FB-0001");
    CHECK(a[0]["workaround"] == "(not shared)");
    CHECK(a[0]["remote"]["shareId"] == "r_1");
    CHECK(a[0]["remote"]["installKey"] == kKeyA);
    CHECK(a[0]["remote"]["trust"] == "anonymous");
    CHECK(b[0]["remote"]["trust"] == "verified");
    CHECK(b[0]["remote"]["reporterKey"] == "rrrrrrrrrrrrrrrr");  // what `feedback ban --reporter` takes
    CHECK(b[0]["occurrences"] == 3);
    CHECK(b[0]["date"] == "2026-10-20");

    // The cursor is saved, and the rest of feedback-admin.json is kept.
    CHECK(f.cursor() == "c5");
    Json adminFile = slurp_json(f.adminFile);
    CHECK(adminFile["adminToken"] == "tok-secret");
    CHECK(adminFile["other"] == 1);

    // Second pull: only what is new, no duplicates.
    f.server.requests.clear();
    f.server.reports.push_back(report("r_6", kKeyA, "Camera shake is missing"));
    auto again = f.pull({"--no-classify"});
    CHECK(again.code == 0);
    REQUIRE(f.server.requests.size() == 1);
    CHECK(f.server.requests[0].url.find("since=c5") != std::string::npos);
    CHECK(f.entries_of(kKeyA).size() == 4);
    CHECK(f.entries_of(kKeyA)[3]["id"] == "FB-0004");
    CHECK(f.entries_of(kKeyB).size() == 2);
    CHECK(f.cursor() == "c6");

    // Nothing new: nothing changes, the cursor stays.
    auto none = f.pull({"--no-classify"});
    CHECK(none.code == 0);
    CHECK(none.out.find("0 new") != std::string::npos);
    CHECK(f.entries_of(kKeyA).size() == 4);
    CHECK(f.cursor() == "c6");
}

TEST_CASE("feedback pull: a known report is recognised by its shareId; --full updates its occurrences") {
    Fixture f;
    f.server.reports = {report("r_1", kKeyA, "No one-way platforms", 1)};
    CHECK(f.pull({"--no-classify"}).code == 0);
    REQUIRE(f.entries_of(kKeyA).size() == 1);

    // The server merged a new report into r_1: same place in the order, more occurrences.
    f.server.reports[0]["occurrences"] = 4;
    auto incremental = f.pull({"--no-classify"});
    CHECK(f.entries_of(kKeyA)[0]["occurrences"] == 1);
    CHECK(incremental.out.find("pull --full") != std::string::npos);  // told where to see counts

    f.server.requests.clear();
    auto full = f.pull({"--no-classify", "--full"});
    CHECK(full.code == 0);
    REQUIRE(f.server.requests.size() >= 1);
    CHECK(f.server.requests[0].url.find("since=") == std::string::npos);  // the saved cursor is ignored
    CHECK(full.out.find("1 with more occurrences") != std::string::npos);
    Json entries = f.entries_of(kKeyA);
    REQUIRE(entries.size() == 1);  // never duplicated
    CHECK(entries[0]["occurrences"] == 4);
}

TEST_CASE("feedback pull: a failure while writing leaves the cursor where it was") {
    Fixture f;
    f.server.reports = {report("r_1", kKeyA, "No one-way platforms")};
    spit(stdfs::path(f.inbox) / kKeyA, "a file where the installation's folder should be");
    auto r = f.pull({"--no-classify"});
    CHECK(r.code == 1);
    CHECK(r.err.find("cursor was not moved") != std::string::npos);
    CHECK(f.cursor().empty());
    // Once the folder can be written the same pull works.
    stdfs::remove(stdfs::path(f.inbox) / kKeyA);
    CHECK(f.pull({"--no-classify"}).code == 0);
    CHECK(f.cursor() == "c1");
}

TEST_CASE("feedback pull: unreadable reports are skipped with a warning, the rest is pulled") {
    Fixture f;
    Json bad = report("r_2", kKeyA, "ok title");
    bad["installKey"] = "../../etc";
    f.server.reports = {bad, report("r_3", kKeyA, "A fine report")};
    auto r = f.pull({"--no-classify"});
    CHECK(r.code == 0);
    CHECK(r.err.find("warning") != std::string::npos);
    CHECK(r.err.find("r_2") != std::string::npos);
    CHECK(f.entries_of(kKeyA).size() == 1);
}

TEST_CASE("feedback pull: null optional fields from the server read as absent") {
    Fixture f;
    Json r = report("r_1", kKeyA, "No one-way platforms");
    r["effort"] = nullptr;
    r["suggestion"] = nullptr;
    r["engineVersion"] = nullptr;
    f.server.reports = {r};
    auto res = f.pull({"--no-classify"});
    CHECK(res.code == 0);
    Json e = f.entries_of(kKeyA);
    REQUIRE(e.size() == 1);
    CHECK_FALSE(e[0].contains("effort"));
    CHECK_FALSE(e[0]["remote"].contains("reporterKey"));  // anonymous: the server sends null
    CHECK(e[0]["title"] == "No one-way platforms");
}

TEST_CASE("feedback pull: never writes inside a git checkout unless --out names it") {
    Fixture f;
    f.server.reports = {report("r_1", kKeyA, "No one-way platforms")};
    // The default inbox is next to ai.json: put ai.json inside a checkout.
    stdfs::create_directories(f.dir / "repo" / ".git");
    f.env["FACTORIA_AI_CONFIG"] = (f.dir / "repo" / "cfg" / "ai.json").string();
    spit(f.dir / "repo" / "cfg" / "feedback-admin.json", slurp(f.adminFile));
    auto refused = run({"feedback", "pull", "--no-classify"});
    CHECK(refused.code == 1);
    CHECK(refused.err.find("git checkout") != std::string::npos);
    CHECK(refused.err.find("--out") != std::string::npos);
    CHECK(f.server.requests.empty());  // refused before any request
    CHECK_FALSE(stdfs::exists(f.dir / "repo" / "cfg" / "feedback-inbox"));
    // A folder named explicitly is the user's decision.
    auto accepted = run({"feedback", "pull", "--no-classify", "--out", (f.dir / "repo" / "my-inbox").string()});
    CHECK(accepted.code == 0);
    CHECK(stdfs::exists(f.dir / "repo" / "my-inbox" / kKeyA / "ENGINE_FEEDBACK.json"));
    // Outside a checkout the default inbox is used.
    f.env["FACTORIA_AI_CONFIG"] = (f.dir / "cfg" / "ai.json").string();
    auto normal = run({"feedback", "pull", "--no-classify"});
    CHECK(normal.code == 0);
    CHECK(stdfs::exists(stdfs::path(f.inbox) / kKeyA / "ENGINE_FEEDBACK.json"));
}

TEST_CASE("feedback pull: without feedback-admin.json it points at deploy.sh") {
    Fixture f(false);
    for (const auto& args : std::vector<std::vector<std::string>>{{"feedback", "pull"}, {"feedback", "stats"}, {"feedback", "bans"}}) {
        auto r = run(args);
        CHECK(r.code == 1);
        CHECK(r.err.find("tools/feedback-server/deploy.sh") != std::string::npos);
    }
    spit(f.adminFile, R"({"endpoint": "https://x.example.test"})");
    auto noToken = run({"feedback", "stats"});
    CHECK(noToken.code == 1);
    CHECK(noToken.err.find("adminToken") != std::string::npos);
    CHECK(noToken.err.find("deploy.sh") != std::string::npos);
    CHECK(noToken.err.find("tok-secret") == std::string::npos);
}

TEST_CASE("feedback pull: contradictory flags are a usage error") {
    Fixture f;
    CHECK(f.pull({"--classify", "--no-classify"}).code == 2);
}

TEST_CASE("feedback pull: classification sorts valid, doubtful and junk; junk goes to the quarantine") {
    Fixture f;
    f.server.reports = {report("r_1", kKeyA, "No one-way platforms"), report("r_2", kKeyA, "Buy cheap watches now"), report("r_3", kKeyB, "Maybe the audio is quiet")};
    feedback_admin_env().model = [&](const std::string& system, const std::string& user) -> Result<std::string> {
        ++f.modelCalls;
        CHECK(system.find("untrusted") != std::string::npos);  // the reports are data, not instructions
        CHECK(user.find("r_2") != std::string::npos);
        return std::string(R"(```json
[{"id": "r_1", "verdict": "valid", "reason": "clear gap"},
 {"id": "r_2", "verdict": "junk", "reason": "spam"},
 {"id": "r_3", "verdict": "doubtful", "reason": "vague"}]
```)");
    };
    auto r = f.pull({"--classify"});
    CHECK(r.code == 0);
    CHECK(f.modelCalls == 1);
    CHECK(r.out.find("1 valid, 1 doubtful, 1 junk") != std::string::npos);
    CHECK(f.entries_of(kKeyA).size() == 1);
    CHECK(f.entries_of(kKeyA)[0]["remote"]["shareId"] == "r_1");
    Json b = f.entries_of(kKeyB);
    REQUIRE(b.size() == 1);
    CHECK(b[0]["notes"][0].get<std::string>().find("doubtful: vague") != std::string::npos);
    Json q = slurp_json(stdfs::path(f.inbox) / "quarantine" / "quarantine.json");
    CHECK(q["format"] == "factoria.feedback-quarantine/1");
    REQUIRE(q["items"].size() == 1);
    CHECK(q["items"][0]["shareId"] == "r_2");
    CHECK(q["items"][0]["reason"] == "spam");
    CHECK(q["items"][0]["entry"]["title"] == "Buy cheap watches now");

    // Pulling everything again does not bring the junk back, nor judge anything twice.
    f.modelCalls = 0;
    auto full = f.pull({"--classify", "--full"});
    CHECK(full.code == 0);
    CHECK(f.modelCalls == 0);
    CHECK(f.entries_of(kKeyA).size() == 1);

    // The collect command does not mistake the quarantine for a project.
    auto collect = run({"feedback", "collect", f.inbox, "--format", "json"});
    CHECK(collect.code == 0);
    CHECK(collect.out.find("No one-way platforms") != std::string::npos);
    CHECK(collect.out.find("Buy cheap watches") == std::string::npos);
}

TEST_CASE("feedback pull: batches of ten, and a failing model leaves the reports in, unjudged") {
    Fixture f;
    for (int i = 0; i < 23; ++i) f.server.reports.push_back(report("r_" + std::to_string(i + 1), kKeyA, "Gap number " + std::to_string(i)));
    f.model_says("valid");
    CHECK(f.pull({"--classify"}).code == 0);
    CHECK(f.modelCalls == 3);
    CHECK(f.entries_of(kKeyA).size() == 23);

    Fixture g;
    g.server.reports = {report("r_1", kKeyA, "No one-way platforms")};
    feedback_admin_env().model = [](const std::string&, const std::string&) -> Result<std::string> { return make_error("rate limited", "wait"); };
    auto r = g.pull({"--classify"});
    CHECK(r.code == 0);
    CHECK(r.err.find("Classification stopped: rate limited") != std::string::npos);
    CHECK(r.out.find("1 not judged") != std::string::npos);
    CHECK(g.entries_of(kKeyA).size() == 1);
    CHECK(g.cursor() == "c1");

    Fixture h;
    h.server.reports = {report("r_1", kKeyA, "No one-way platforms")};
    feedback_admin_env().model = [](const std::string&, const std::string&) -> Result<std::string> { return std::string("I cannot do that."); };
    auto garbage = h.pull({"--classify"});
    CHECK(garbage.code == 0);
    CHECK(garbage.err.find("did not answer with a JSON array") != std::string::npos);
    CHECK(h.entries_of(kKeyA).size() == 1);
}

TEST_CASE("feedback pull: classification needs an AI only when asked for") {
    Fixture f;
    f.server.reports = {report("r_1", kKeyA, "No one-way platforms")};
    // The "fast" role uses OpenAI and there is no key: no AI.
    spit(f.dir / "cfg" / "ai.json", R"({"roles": {"fast": {"provider": "openai", "model": "gpt-5-mini"}}})");
    auto forced = f.pull({"--classify"});
    CHECK(forced.code == 1);
    CHECK(forced.err.find("OPENAI_API_KEY") != std::string::npos);
    CHECK(f.server.requests.empty());  // refused before downloading
    auto automatic = f.pull();
    CHECK(automatic.code == 0);
    CHECK(automatic.out.find("skipped, no AI configured") != std::string::npos);
    CHECK(f.entries_of(kKeyA).size() == 1);
}

TEST_CASE("feedback pull: the model of the fast role is built from ai.json (API provider, injected transport)") {
    Fixture f;
    spit(f.dir / "cfg" / "ai.json", R"({"roles": {"fast": {"provider": "openai", "model": "gpt-5-mini"}}})");
    f.env["OPENAI_API_KEY"] = "sk-test-0123456789abcdef";
    std::vector<ai::HttpRequest> modelRequests;
    feedback_admin_env().transport = [&](const ai::HttpRequest& req) -> ai::HttpResponse {
        if (req.url.find("feedback.example.test") != std::string::npos) return f.server.handle(req);
        modelRequests.push_back(req);
        ai::HttpResponse r;
        r.status = 200;
        r.body = Json::object({{"id", "x"}, {"model", "gpt-5-mini"},
                               {"choices", Json::array({Json::object({{"index", 0}, {"finish_reason", "stop"},
                                                                       {"message", Json::object({{"role", "assistant"},
                                                                                                 {"content", R"([{"id": "r_1", "verdict": "junk", "reason": "test text"}])"}})}})})},
                               {"usage", Json::object({{"prompt_tokens", 10}, {"completion_tokens", 5}, {"total_tokens", 15}})}})
                     .dump();
        return r;
    };
    f.server.reports = {report("r_1", kKeyA, "asdf asdf asdf")};
    auto r = f.pull({"--classify"});
    CHECK(r.code == 0);
    REQUIRE(modelRequests.size() == 1);
    CHECK(modelRequests[0].url.find("api.openai.com") != std::string::npos);
    CHECK(modelRequests[0].body.find("gpt-5-mini") != std::string::npos);
    CHECK(modelRequests[0].body.find("asdf asdf asdf") != std::string::npos);
    CHECK(r.out.find("1 junk") != std::string::npos);
    CHECK(f.server.requests.size() == 1);  // the report requests went to the feedback server only
}

TEST_CASE("feedback quarantine: list, restore and clear") {
    Fixture f;
    f.server.reports = {report("r_1", kKeyA, "No one-way platforms"), report("r_2", kKeyA, "Buy cheap watches now"), report("r_3", kKeyB, "lorem ipsum dolor")};
    f.model_says("junk", "r_2");
    feedback_admin_env().model = [](const std::string&, const std::string&) -> Result<std::string> {
        return std::string(R"([{"id":"r_1","verdict":"valid","reason":"ok"},{"id":"r_2","verdict":"junk","reason":"spam"},{"id":"r_3","verdict":"junk","reason":"filler"}])");
    };
    REQUIRE(f.pull({"--classify"}).code == 0);

    auto list = run({"feedback", "quarantine", "--out", f.inbox});
    CHECK(list.code == 0);
    CHECK(list.out.find("r_2") != std::string::npos);
    CHECK(list.out.find("spam") != std::string::npos);
    CHECK(list.out.find("r_3") != std::string::npos);
    auto asJson = run({"feedback", "quarantine", "list", "--out", f.inbox, "--json"});
    CHECK(Json::parse(asJson.out).size() == 2);

    auto restore = run({"feedback", "quarantine", "restore", "r_2", "--out", f.inbox});
    CHECK(restore.code == 0);
    Json a = f.entries_of(kKeyA);
    REQUIRE(a.size() == 2);
    CHECK(a[1]["id"] == "FB-0002");
    CHECK(a[1]["remote"]["shareId"] == "r_2");
    CHECK(a[1]["notes"][0].get<std::string>().find("restored from the quarantine") != std::string::npos);
    CHECK(run({"feedback", "quarantine", "--out", f.inbox, "--json"}).out.find("r_2") == std::string::npos);

    auto missing = run({"feedback", "quarantine", "restore", "r_9", "--out", f.inbox});
    CHECK(missing.code == 1);
    CHECK(missing.err.find("r_9") != std::string::npos);
    CHECK(run({"feedback", "quarantine", "restore", "--out", f.inbox}).code == 2);
    CHECK(run({"feedback", "quarantine", "empty", "--out", f.inbox}).code == 2);

    auto clear = run({"feedback", "quarantine", "clear", "--out", f.inbox});
    CHECK(clear.code == 0);
    CHECK(clear.out.find("Cleared 1") != std::string::npos);
    CHECK(run({"feedback", "quarantine", "--out", f.inbox}).out.find("empty") != std::string::npos);
}

TEST_CASE("feedback ban, unban, bans, delete and stats talk to the admin API") {
    Fixture f;
    f.server.bans = Json::array({Json::object({{"kind", "install"}, {"key", kKeyB}, {"reason", "spam"}, {"createdAt", "2026-10-30T00:00:00Z"}})});

    auto ban = run({"feedback", "ban", kKeyA, "--install", "--purge", "--reason", "spam wave", "--out", f.inbox});
    CHECK(ban.code == 0);
    REQUIRE(f.server.requests.size() == 1);
    CHECK(f.server.requests[0].method == "POST");
    CHECK(f.server.last_path() == "/v1/admin/ban");
    Json body = Json::parse(f.server.requests[0].body);
    CHECK(body["installKey"] == kKeyA);
    CHECK(body["reason"] == "spam wave");
    CHECK(body["purge"] == true);
    CHECK(ban.out.find("purged") != std::string::npos);
    CHECK(ban.out.find("unban") != std::string::npos);

    auto reporter = run({"feedback", "ban", "install:" + kKeyB, "--out", f.inbox});
    CHECK(reporter.code == 0);
    Json b2 = Json::parse(f.server.requests.back().body);
    CHECK(b2["installKey"] == kKeyB);
    CHECK_FALSE(b2.contains("purge"));
    CHECK(b2["reason"].get<std::string>().size() > 3);  // the server requires one

    auto rep = run({"feedback", "ban", kKeyA, "--reporter", "--out", f.inbox});
    CHECK(rep.code == 0);
    CHECK(Json::parse(f.server.requests.back().body).contains("reporterKey"));

    auto unban = run({"feedback", "unban", kKeyA, "--install", "--out", f.inbox});
    CHECK(unban.code == 0);
    CHECK(f.server.last_path() == "/v1/admin/unban");
    CHECK(Json::parse(f.server.requests.back().body)["installKey"] == kKeyA);

    auto bans = run({"feedback", "bans"});
    CHECK(bans.code == 0);
    CHECK(bans.out.find(kKeyB) != std::string::npos);
    CHECK(bans.out.find("spam") != std::string::npos);
    CHECK(bans.out.find("tok-secret") == std::string::npos);

    auto del = run({"feedback", "delete", "r_8f3k2m"});
    CHECK(del.code == 0);
    CHECK(f.server.requests.back().method == "DELETE");
    CHECK(f.server.last_path() == "/v1/admin/reports/r_8f3k2m");
    CHECK(run({"feedback", "delete", "../x"}).code == 2);

    auto stats = run({"feedback", "stats"});
    CHECK(stats.code == 0);
    CHECK(stats.out.find("reports: 7") != std::string::npos);
    CHECK(stats.out.find("2026-10-31  accepted 2, merged 0, rejected 1") != std::string::npos);
    CHECK(stats.out.find("too_short 1") != std::string::npos);
    CHECK(stats.out.find("2026-10-30") == std::string::npos);  // days without activity are left out
    CHECK(Json::parse(run({"feedback", "stats", "--json"}).out)["totals"]["installations"] == 3);

    f.server.fixed["/v1/admin/unban"] = f.server.json(200, Json::object({{"ok", true}, {"removed", false}}));
    CHECK(run({"feedback", "unban", kKeyA, "--install", "--out", f.inbox}).out.find("was not banned") != std::string::npos);
}

TEST_CASE("feedback ban: a key that could be an installKey or a reporterKey teaches; a shareId or an inbox folder decides") {
    Fixture f;
    f.server.reports = {report("r_1", kKeyA, "No one-way platforms")};
    REQUIRE(f.pull({"--no-classify"}).code == 0);
    f.server.requests.clear();

    auto ambiguous = run({"feedback", "ban", "cccccccccccccccc", "--out", f.inbox});
    CHECK(ambiguous.code == 2);
    CHECK(ambiguous.err.find("--install") != std::string::npos);
    CHECK(ambiguous.err.find("--reporter") != std::string::npos);
    CHECK(f.server.requests.empty());
    CHECK(run({"feedback", "ban", kKeyA, "--install", "--reporter", "--out", f.inbox}).code == 2);
    auto tooShort = run({"feedback", "ban", "abc", "--install", "--out", f.inbox});
    CHECK(tooShort.code == 2);
    CHECK(tooShort.err.find("16 characters") != std::string::npos);
    CHECK(run({"feedback", "ban", "--out", f.inbox}).code == 2);

    // The shareId of a pulled report stands for its installation.
    auto byShareId = run({"feedback", "ban", "r_1", "--out", f.inbox});
    CHECK(byShareId.code == 0);
    CHECK(Json::parse(f.server.requests.back().body)["installKey"] == kKeyA);
    // So does the folder of the inbox.
    auto byFolder = run({"feedback", "ban", kKeyA, "--out", f.inbox});
    CHECK(byFolder.code == 0);
    CHECK(Json::parse(f.server.requests.back().body)["installKey"] == kKeyA);

    auto key = resolve_ban_key("reporter:" + kKeyB, KeyKind::Unknown, f.inbox);
    REQUIRE(key.ok());
    CHECK(key->first == KeyKind::Reporter);
}

TEST_CASE("feedback delete --local also removes the pulled copy") {
    Fixture f;
    f.server.reports = {report("r_1", kKeyA, "No one-way platforms"), report("r_2", kKeyA, "Audio cannot loop")};
    REQUIRE(f.pull({"--no-classify"}).code == 0);
    auto r = run({"feedback", "delete", "r_1", "--local", "--out", f.inbox});
    CHECK(r.code == 0);
    CHECK(r.out.find("removed 1 local entry") != std::string::npos);
    Json entries = f.entries_of(kKeyA);
    REQUIRE(entries.size() == 1);
    CHECK(entries[0]["remote"]["shareId"] == "r_2");
}

TEST_CASE("feedback admin: every kind of server answer is explained") {
    struct Case {
        int status;
        std::string body;
        std::string expect;   // in the error text
        std::string expect2;  // also
    };
    auto err = [](const std::string& code, const std::string& message, const std::string& hint) {
        return Json::object({{"ok", false}, {"error", Json::object({{"code", code}, {"message", message}, {"hint", hint}})}}).dump();
    };
    const std::vector<Case> cases = {
        {401, err("unauthorized", "The admin token is missing or wrong.", "Send Authorization."), "The admin token is missing or wrong.", "deploy.sh"},
        {403, err("banned", "banned", "no"), "refused the admin token", "ADMIN_TOKEN"},
        {503, err("not_configured", "The server has no ADMIN_TOKEN.", "Run deploy."), "no admin token yet", "deploy.sh"},
        {404, err("not_found", "No report r_9.", "Deleted already."), "No report r_9.", "Deleted already."},
        {404, "<html>Not found</html>", "does not look like the feedback server", "endpoint"},
        {400, err("invalid_cursor", "since is not a cursor.", "Pass next."), "since is not a cursor.", "Pass next."},
        {400, err("invalid_request", "limit must be an integer.", "Use limit=500."), "limit must be an integer.", "Use limit=500."},
        {405, err("method_not_allowed", "no POST", "Use GET."), "no POST", "Use GET."},
        {413, err("too_large", "too big", "smaller"), "too big for the server", "bug"},
        {429, err("rate_limited", "slow down", "later"), "rate limiting", "midnight UTC"},
        {500, "oops", "feedback server failed", "wrangler tail"},
        {502, err("github_unavailable", "gh down", "retry"), "gh down", "Try again"},
        {200, "<html>privacy page</html>", "does not look like the feedback server", "endpoint"},
        {200, err("weird", "something", "else"), "something", "else"},
    };
    for (const auto& c : cases) {
        Fixture f;
        ai::HttpResponse r;
        r.status = c.status;
        r.body = c.body;
        if (c.status == 429) r.headers["retry-after"] = "120";
        f.server.fixed["/v1/admin/stats"] = r;
        auto res = run({"feedback", "stats"});
        CAPTURE(c.status);
        CAPTURE(c.body);
        CHECK(res.code == 1);
        CHECK(res.err.find(c.expect) != std::string::npos);
        CHECK(res.err.find(c.expect2) != std::string::npos);
        CHECK(res.err.find("hint:") != std::string::npos);
        CHECK(res.err.find("tok-secret") == std::string::npos);
    }
    {
        Fixture f;
        f.server.fixed["/v1/admin/stats"].status = 0;
        f.server.fixed["/v1/admin/stats"].error = "Could not resolve host";
        auto res = run({"feedback", "stats"});
        CHECK(res.code == 1);
        CHECK(res.err.find("Cannot reach the feedback server") != std::string::npos);
        CHECK(res.err.find("Could not resolve host") != std::string::npos);
    }
    {
        Fixture f;
        ai::HttpResponse r;
        r.status = 429;
        r.headers["retry-after"] = "120";
        r.body = err("rate_limited", "slow", "later");
        f.server.fixed["/v1/admin/stats"] = r;
        CHECK(run({"feedback", "stats"}).err.find("retry in 120 s") != std::string::npos);
    }
    {
        // A pull that fails keeps everything as it was and says the cursor did not move.
        Fixture f;
        f.server.reports = {report("r_1", kKeyA, "No one-way platforms")};
        f.server.fixed["since=c1"] = f.server.json(500, Json::object());
        f.server.reports.push_back(report("r_2", kKeyA, "Second"));
        PullOptions po;
        po.out = f.inbox;
        po.outExplicit = true;
        po.classify = ClassifyMode::Off;
        po.pageSize = 1;
        auto r = feedback_pull(po, feedback_admin_env());
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find("page 2") != std::string::npos);
        CHECK(r.error().hint.find("Nothing was written") != std::string::npos);
        CHECK_FALSE(stdfs::exists(stdfs::path(f.inbox) / kKeyA));
        CHECK(f.cursor().empty());
    }
    {
        // A cursor the server does not know points at --full.
        Fixture f;
        spit(f.adminFile, R"({"endpoint": "https://feedback.example.test", "adminToken": "t", "cursor": "stale"})");
        ai::HttpResponse r;
        r.status = 400;
        r.body = err("invalid_cursor", "since is not a cursor this server gave.", "Leave since out.");
        f.server.fixed["since=stale"] = r;
        auto res = f.pull({"--no-classify"});
        CHECK(res.code == 1);
        CHECK(res.err.find("pull --full") != std::string::npos);
        f.server.reports = {report("r_1", kKeyA, "No one-way platforms")};
        CHECK(f.pull({"--no-classify", "--full"}).code == 0);
        CHECK(f.cursor() == "c1");
    }
}

TEST_CASE("feedback fixed: add and list through the CLI, and the offer after `update --status fixed-in-engine`") {
    Fixture f;
    const std::string file = (f.dir / "feedback" / "fixed.json").string();
    auto none = run({"feedback", "fixed", "list", "--file", file});
    CHECK(none.code == 1);
    CHECK(none.err.find("fixed add") != std::string::npos);

    auto add = run({"feedback", "fixed", "add", "--category", "physics", "--title", "No one-way platforms", "--title", "One-way platforms missing",
                    "--version", "0.11.0", "--note", "Collider2D.oneWay", "--file", file});
    CHECK(add.code == 0);
    CHECK(add.out.find("Created") != std::string::npos);
    Json doc = slurp_json(file);
    CHECK(doc["format"] == "factoria.feedback-fixed/1");
    CHECK(doc["fixes"][0]["titles"].size() == 2);
    CHECK(doc["fixes"][0]["fixedIn"] == "0.11.0");

    auto list = run({"feedback", "fixed", "list", "--file", file});
    CHECK(list.code == 0);
    CHECK(list.out.find("0.11.0  [physics]  No one-way platforms | One-way platforms missing  - Collider2D.oneWay") != std::string::npos);
    CHECK(Json::parse(run({"feedback", "fixed", "list", "--file", file, "--json"}).out)["fixes"].size() == 1);

    CHECK(run({"feedback", "fixed", "add", "--category", "physics", "--version", "0.11.0", "--file", file}).code == 2);  // no --title
    auto badCat = run({"feedback", "fixed", "add", "--category", "phisics", "--title", "x gap", "--version", "0.11.0", "--file", file});
    CHECK(badCat.code == 1);
    CHECK(badCat.err.find("physics") != std::string::npos);
    CHECK(slurp_json(file)["fixes"].size() == 1);

    // Closing a pulled entry as fixed offers the command that records the fix; a project's own entry does not.
    f.server.reports = {report("r_1", kKeyA, "No one-way platforms")};
    REQUIRE(f.pull({"--no-classify"}).code == 0);
    auto update = run({"feedback", "update", (stdfs::path(f.inbox) / kKeyA).string(), "FB-0001", "--status", "fixed-in-engine"});
    CHECK(update.code == 0);
    CHECK(update.out.find("factoria feedback fixed add --category physics --title \"No one-way platforms\" --version") != std::string::npos);
    auto wontfix = run({"feedback", "update", (stdfs::path(f.inbox) / kKeyA).string(), "FB-0001", "--status", "wont-fix"});
    CHECK(wontfix.out.find("fixed add") == std::string::npos);

    Json local = Json::object({{"title", "t"}, {"category", "physics"}});
    CHECK(fixed_add_offer(local).empty());
}
