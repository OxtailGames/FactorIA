// Feedback sharing, client side (fa/tooling/feedback_share.h): sanitizer, settings, outbox, payload, server answers, modes.
// Nothing here reaches the network or the real user config: a fake transport and a temp config folder.
#include <doctest.h>

#include <map>

#include "fa/core/strings.h"
#include "fa/tooling/feedback.h"
#include "fa/tooling/feedback_share.h"
#include "test_helpers.h"

using namespace fa;

namespace {

HttpResponse reply(int status, const Json& body, std::vector<std::pair<std::string, std::string>> headers = {}) {
    HttpResponse r;
    r.ok = true;
    r.status = status;
    r.body = body.dump();
    r.headers = std::move(headers);
    return r;
}
HttpResponse transport_failure(const std::string& why = "could not connect") {
    HttpResponse r;
    r.ok = false;
    r.error = why;
    return r;
}

// A user config folder in a temp dir, a clock you move, and a transport that records requests and answers from a script.
struct Share {
    testing::TempDir dir;
    std::int64_t clock = 1'800'000'000;  // 2027-01-15
    std::vector<HttpRequest> requests;
    std::vector<HttpResponse> script;  // answered in order; the last one repeats
    std::vector<double> sleeps;
    ShareEnv env;

    Share() {
        const std::string home = dir.sub("home");
        env.env = [home](const std::string& name) -> std::string { return name == "HOME" || name == "USERPROFILE" || name == "APPDATA" ? home : ""; };
        env.now = [this] { return clock; };
        env.sleep = [this](double s) { sleeps.push_back(s); clock += static_cast<std::int64_t>(s); };
        env.makeUuid = [] { return std::string("11111111-2222-4333-8444-555555555555"); };
        env.defaultEndpoint = "https://feedback.example.test";
        env.githubClientId = "client-id-1";
        env.platform = "linux";
        env.engineVersion = "9.9.9";
        env.transport = [this](const HttpRequest& r) {
            requests.push_back(r);
            if (script.empty()) return transport_failure("no answer scripted");
            HttpResponse out = script.front();
            if (script.size() > 1) script.erase(script.begin());
            return out;
        };
    }
    void mode(ShareMode m) { REQUIRE(set_share_mode(env, m).ok()); }

    // A project with a feedback file holding one entry (FB-0001) that has a share.
    std::string project() {
        const std::string p = dir.sub("game");
        testing::write_all(p + "/factoria.json", R"({"name":"Lantern Keep","id":"com.acme.lanternkeep","version":"0.1.0","mainScene":"scenes/crypt_level.scene.json"})");
        testing::write_all(p + "/scenes/crypt_level.scene.json",
                           R"({"entities":[{"name":"Sir Aldric","components":{"Transform":{}}},{"name":"Gloomfang","components":{"Transform":{}}}]})");
        return p;
    }
    std::string feedback_file(const std::string& proj, const Json& share = Json(), const std::string& title = "No one-way platforms") {
        const std::string file = proj + "/ENGINE_FEEDBACK.json";
        Json doc = create_empty_feedback("Lantern Keep", "9.9.9");
        FeedbackInput in;
        in.category = "physics";
        in.severity = "major";
        in.title = title;
        in.missing = "Collider2D has no one-way option";
        in.workaround = "scripts/aldric_jump.js toggles the collider";
        in.share = share.is_null() ? good_share() : share;
        in.reviewed = true;
        in.reporter = Json::object({{"kind", "ai"}});
        auto r = add_feedback_entry(doc, in);
        REQUIRE(r.ok());
        REQUIRE(save_feedback(file, doc).ok());
        return file;
    }
    static Json good_share() {
        return Json::parse(R"({"title":"No one-way platforms","missing":"Collider2D has no one-way option, so a body cannot pass up through a platform and land on it.","suggestion":"Add Collider2D.oneWay (bool).","workaround":"A script disables the collider while the body moves up."})");
    }
    Json answer_ok(const std::vector<std::pair<std::string, std::string>>& results) {  // {localId, status}
        Json arr = Json::array();
        int n = 0;
        for (const auto& [id, st] : results) {
            Json r = Json::object({{"localId", id}, {"status", st}});
            if (st == "accepted" || st == "merged") r["shareId"] = "r_" + std::to_string(++n);
            if (st == "rejected") {
                r["code"] = "too_short";
                r["reason"] = "missing needs at least 20 characters";
            }
            arr.push_back(r);
        }
        return Json::object({{"ok", true}, {"results", arr}});
    }
};

EngineNames engine_names() { return collect_engine_names(); }

std::string clean(const std::string& text, const ProjectNames& project = {}) {
    std::vector<Removal> removed;
    return sanitize_text("missing", text, engine_names(), project, removed);
}

}  // namespace

// ------------------------------------------------------------------------------------------------------------------ sanitizer

TEST_CASE("share sanitizer: paths, file names, URLs and e-mail addresses come out") {
    std::vector<Removal> removed;
    const std::string out = sanitize_text("missing", "See scripts/aldric_jump.js and C:\\Users\\ana\\game\\a.png or https://example.com/x, mail ana@example.com about it.",
                                          engine_names(), {}, removed);
    CHECK(out.find("scripts") == std::string::npos);
    CHECK(out.find("aldric") == std::string::npos);
    CHECK(out.find("example") == std::string::npos);
    CHECK(out.find("ana") == std::string::npos);
    CHECK(out.find("about it") != std::string::npos);
    std::set<std::string> kinds;
    for (const Removal& r : removed) kinds.insert(r.kind);
    CHECK(kinds.count("path"));
    CHECK(kinds.count("url"));
    CHECK(kinds.count("email"));
}

TEST_CASE("share sanitizer: a bare file name goes, an engine member with a dot stays") {
    CHECK(clean("The player.js script and hero.png both fail.").find(".js") == std::string::npos);
    CHECK(clean("The player.js script and hero.png both fail.").find(".png") == std::string::npos);
    const std::string kept = clean("Collider2D.oneWay would help, and Body.mat is not a file; also the command scene.spawn.");
    CHECK(kept.find("Collider2D.oneWay") != std::string::npos);
    CHECK(kept.find("scene.spawn") != std::string::npos);
    CHECK(clean("Use and/or a 16/9 ratio.").find("and/or") != std::string::npos);
}

TEST_CASE("share sanitizer: quoted text goes unless it names the engine") {
    std::vector<Removal> removed;
    const std::string out = sanitize_text("missing",
        "The line \"Welcome to Ashfall\" and 'secret level' show, but `Collider2D` and \"scene.spawn\" and \u00abForgotten Crypt\u00bb differ.",
        engine_names(), {}, removed);
    CHECK(out.find("Ashfall") == std::string::npos);
    CHECK(out.find("secret level") == std::string::npos);
    CHECK(out.find("Forgotten") == std::string::npos);
    CHECK(out.find("`Collider2D`") != std::string::npos);
    CHECK(out.find("\"scene.spawn\"") != std::string::npos);
    int quotes = 0;
    for (const Removal& r : removed) quotes += r.kind == "quote";
    CHECK(quotes == 3);
    CHECK(clean("It doesn't work and the player's score isn't kept.").find("doesn't") != std::string::npos);
}

TEST_CASE("share sanitizer: the project's own names are removed, the engine's are kept") {
    Share s;
    const ProjectNames project = collect_project_names(s.project());
    auto has = [&](const char* n) { return std::find(project.names.begin(), project.names.end(), n) != project.names.end(); };
    CHECK(has("Lantern Keep"));
    CHECK(has("Sir Aldric"));
    CHECK(has("Gloomfang"));
    CHECK(has("crypt_level"));
    const std::string out = clean("In Lantern Keep, Sir Aldric and gloomfang walk on crypt level floors; Transform and Collider2D stay.", project);
    CHECK(out.find("Lantern") == std::string::npos);
    CHECK(out.find("Aldric") == std::string::npos);
    CHECK(out.find("loomfang") == std::string::npos);
    CHECK(out.find("Transform") != std::string::npos);
    CHECK(out.find("Collider2D") != std::string::npos);
    CHECK(clean("The Player has a Transform", project).find("Player") != std::string::npos);  // too generic to be a secret
}

TEST_CASE("share sanitizer: control characters and long runs") {
    std::vector<Removal> removed;
    const std::string out = sanitize_text("missing", std::string("a\x01" "b\xE2\x80\x8B" "c wwwwwwwwwwwwwwww end\nnext"), engine_names(), {}, removed);
    CHECK(out == "abc www end next");
    std::set<std::string> kinds;
    for (const Removal& r : removed) kinds.insert(r.kind);
    CHECK(kinds.count("control"));
    CHECK(kinds.count("repeat"));
}

TEST_CASE("share sanitizer: sanitizing is deterministic and tidy") {
    const std::string a = clean("Needs (see \"Secret\") , a one-way option at ../x/y.js now.");
    CHECK(a == clean("Needs (see \"Secret\") , a one-way option at ../x/y.js now."));
    CHECK(a.find("()") == std::string::npos);
    CHECK(a.find("  ") == std::string::npos);
    CHECK(a.find(" ,") == std::string::npos);
}

TEST_CASE("share sanitizer: share_sanitize checks the limits after cleaning") {
    const EngineNames engine = engine_names();
    auto run = [&](const char* title, const char* missing) {
        return sanitize_share(Json::object({{"title", title}, {"missing", missing}}), engine, {});
    };
    SUBCASE("a good share passes unchanged") {
        const SanitizedShare ok = sanitize_share(Share::good_share(), engine, {});
        CHECK(ok.ok);
        CHECK(ok.title == "No one-way platforms");
        CHECK(ok.removed.empty());
        CHECK(ok.fields()["suggestion"] == "Add Collider2D.oneWay (bool).");
    }
    SUBCASE("too short after cleaning") {
        const SanitizedShare r = run("No one-way platforms", "Fix \"the Emberfall secret ending\" at scripts/boss/ending_cutscene.js please");
        CHECK_FALSE(r.ok);
        CHECK(r.reason().find("too short after cleaning") != std::string::npos);
        CHECK(r.reason().find("quote") != std::string::npos);
    }
    SUBCASE("title too short, too long, missing 4 words, not text") {
        CHECK_FALSE(run("Short", "Collider2D has no one-way option for bodies").ok);
        CHECK_FALSE(run(std::string(121, 'a').c_str(), "Collider2D has no one-way option for bodies").ok);
        CHECK_FALSE(run("No one-way platforms", "Collider2D_has_no_one_way_option").ok);
        CHECK_FALSE(run("No one-way platforms", "12345 67890 12345 67890 12345 67890").ok);
        CHECK_FALSE(sanitize_share(Json::object({{"title", "No one-way platforms"}}), engine, {}).ok);
        CHECK_FALSE(sanitize_share(Json::array(), engine, {}).ok);
    }
    SUBCASE("a field over its maximum is rejected") {
        Json j = Share::good_share();
        j["suggestion"].clear();
        for (int i = 0; i < 400; ++i) j["suggestion"] = j["suggestion"].get<std::string>() + "ab cd ";
        CHECK_FALSE(sanitize_share(j, engine, {}).ok);
    }
}

TEST_CASE("share sanitizer: the engine's names come from the registries and the published API") {
    CommandRegistry registry;
    register_feedback_commands(registry, ".");
    const EngineNames names = collect_engine_names(&registry);
    CHECK(names.has("Collider2D"));
    CHECK_FALSE(names.has("hoverMode"));
    CHECK(names.has("feedback.report"));
    CHECK(names.has("scene.spawn"));  // from the published command list even without that registry
    CHECK(names.token_ok("Collider2D.hoverMode"));  // a proposed member of an engine type
    CHECK_FALSE(names.token_ok("Aldric.js"));
}

// ------------------------------------------------------------------------------------------------------------------ settings

TEST_CASE("share settings: unset by default, installId is a UUID v4, unknown keys survive") {
    Share s;
    ShareSettings st = load_share_settings(s.env);
    CHECK(st.mode == ShareMode::Unset);
    CHECK(st.installId.empty());
    CHECK(st.path == s.dir.sub("home/.factoria/feedback-sharing.json"));

    auto id = ensure_install_id(s.env);
    REQUIRE(id.ok());
    CHECK(id.value() == "11111111-2222-4333-8444-555555555555");
    CHECK(ensure_install_id(s.env).value() == id.value());  // created once

    s.mode(ShareMode::Ask);
    Json raw = parse_json(testing::read_all(st.path), "x").value();
    raw["futureKey"] = 7;
    testing::write_all(st.path, raw.dump());
    s.mode(ShareMode::Always);
    st = load_share_settings(s.env);
    CHECK(st.mode == ShareMode::Always);
    CHECK(st.installId == id.value());
    CHECK(st.raw["futureKey"] == 7);
}

TEST_CASE("share settings: the real random UUID is a v4 and different each time") {
    const std::string a = random_uuid_v4(), b = random_uuid_v4();
    CHECK(is_uuid_v4(a));
    CHECK(is_uuid_v4(b));
    CHECK(a != b);
    CHECK_FALSE(is_uuid_v4("not-a-uuid"));
    CHECK_FALSE(is_uuid_v4("11111111-2222-1333-8444-555555555555"));  // version 1
}

TEST_CASE("share settings: a broken file reads as unset with a warning; the mode names parse") {
    Share s;
    testing::write_all(share_settings_path(s.env), "{ not json");
    ShareSettings st = load_share_settings(s.env);
    CHECK(st.mode == ShareMode::Unset);
    CHECK_FALSE(st.warning.empty());
    testing::write_all(share_settings_path(s.env), R"({"mode":"sometimes"})");
    CHECK(load_share_settings(s.env).warning.find("sometimes") != std::string::npos);
    CHECK(parse_share_mode("ASK") == ShareMode::Ask);
    CHECK_FALSE(parse_share_mode("maybe").has_value());
    CHECK(std::string(share_mode_name(ShareMode::Never)) == "never");
}

TEST_CASE("share settings: the endpoint override wins and loses its trailing slash; empty means unavailable") {
    Share s;
    ShareSettings st = load_share_settings(s.env);
    CHECK(share_endpoint(s.env, st) == "https://feedback.example.test");
    st.endpoint = "http://localhost:8787/";
    CHECK(share_endpoint(s.env, st) == "http://localhost:8787");
    s.env.defaultEndpoint.clear();
    st.endpoint.clear();
    CHECK(share_endpoint(s.env, st).empty());
    CHECK(share_unavailable_message().find("FA_FEEDBACK_URL") != std::string::npos);
}

TEST_CASE("share settings: the config folder follows FACTORIA_AI_CONFIG like ai.json") {
    UserConfigEnv env = [](const std::string& n) -> std::string { return n == "FACTORIA_AI_CONFIG" ? "/tmp/x/ai.json" : ""; };
    CHECK(user_config_dir(env) == "/tmp/x");
}

// ------------------------------------------------------------------------------------------------------------------- outbox

TEST_CASE("share outbox: backoff is 1 minute, 10 minutes, 1 hour, then daily") {
    CHECK(backoff_seconds(1) == 60);
    CHECK(backoff_seconds(2) == 600);
    CHECK(backoff_seconds(3) == 3600);
    CHECK(backoff_seconds(4) == 86400);
    CHECK(backoff_seconds(40) == 86400);
}

TEST_CASE("share outbox: saved and loaded as it was") {
    Share s;
    Outbox box = load_outbox(s.env);
    CHECK(box.items.empty());
    OutboxItem it;
    it.file = "/p/ENGINE_FEEDBACK.json";
    it.localId = "FB-0001";
    it.key = it.file + "#" + it.localId;
    it.state = OutboxState::Waiting;
    it.entry = Json::object({{"localId", "FB-0001"}});
    it.attempts = 2;
    it.queuedAt = 5;
    it.nextAttempt = 99;
    it.lastError = "boom";
    box.items.push_back(it);
    box.lastSend = Json::object({{"outcome", "failed"}});
    REQUIRE(save_outbox(s.env, box).ok());
    const Outbox back = load_outbox(s.env);
    REQUIRE(back.items.size() == 1);
    CHECK(back.items[0].key == it.key);
    CHECK(back.items[0].state == OutboxState::Waiting);
    CHECK(back.items[0].attempts == 2);
    CHECK(back.items[0].nextAttempt == 99);
    CHECK(back.items[0].lastError == "boom");
    CHECK(back.lastSend["outcome"] == "failed");
    testing::write_all(box.path, "garbage");
    CHECK(load_outbox(s.env).items.empty());  // an unreadable outbox starts empty
}

// ------------------------------------------------------------------------------------------------------------------ payload

TEST_CASE("share payload: exactly the fields of the contract, nothing from the local entry") {
    Share s;
    const std::string proj = s.project();
    const std::string file = s.feedback_file(proj);
    const Json doc = load_feedback(file).value();
    const Json& local = doc["entries"][0];
    const SanitizedShare clean = sanitize_share(local["share"], engine_names(), collect_project_names(proj));
    REQUIRE(clean.ok);
    const Json entry = build_share_entry(local, clean);
    CHECK(entry == Json::parse(R"({"localId":"FB-0001","category":"physics","severity":"major",
        "title":"No one-way platforms",
        "missing":"Collider2D has no one-way option, so a body cannot pass up through a platform and land on it.",
        "suggestion":"Add Collider2D.oneWay (bool).","workaround":"A script disables the collider while the body moves up.",
        "reporterKind":"ai","reviewed":true})"));
    const Json payload = build_share_payload(s.env, {entry});
    CHECK(payload["format"] == "factoria.feedback-share/1");
    CHECK(payload["engineVersion"] == "9.9.9");
    CHECK(payload["platform"] == "linux");
    CHECK(payload["entries"].size() == 1);
    const std::string text = payload.dump();
    CHECK(text.find("aldric") == std::string::npos);  // the local workaround never goes
    CHECK(text.find("Lantern") == std::string::npos);
}

// --------------------------------------------------------------------------------------------------------- modes and the queue

TEST_CASE("share queue: unset and never send nothing; never marks the entry skipped") {
    Share s;
    const std::string proj = s.project();
    const std::string file = s.feedback_file(proj);
    auto q = share_queue(s.env, file, proj, engine_names());
    REQUIRE(q.ok());
    CHECK(q->skipped == 1);
    CHECK(load_feedback(file).value()["entries"][0].contains("shared") == false);  // unset: left as it is
    s.mode(ShareMode::Never);
    q = share_queue(s.env, file, proj, engine_names());
    CHECK(load_feedback(file).value()["entries"][0]["shared"]["status"] == "skipped");
    CHECK(load_outbox(s.env).items.empty());
    const FlushResult f = share_flush(s.env);
    CHECK(f.outcome == "off");
    CHECK(s.requests.empty());
}

TEST_CASE("share queue: always queues, writes shared pending, and an entry is in the outbox once") {
    Share s;
    const std::string proj = s.project();
    const std::string file = s.feedback_file(proj);
    s.mode(ShareMode::Always);
    for (int i = 0; i < 2; ++i) {
        auto q = share_queue(s.env, file, proj, engine_names());
        REQUIRE(q.ok());
        CHECK(q->queued == 1);
    }
    const Outbox box = load_outbox(s.env);
    REQUIRE(box.items.size() == 1);
    CHECK(box.items[0].state == OutboxState::Queued);
    CHECK(box.items[0].entry["title"] == "No one-way platforms");
    CHECK(load_feedback(file).value()["entries"][0]["shared"]["status"] == "pending");
    CHECK(s.requests.empty());  // queuing sends nothing
}

TEST_CASE("share queue: an entry whose share is refused by the sanitizer is marked rejected and not queued") {
    Share s;
    const std::string proj = s.project();
    const std::string file = s.feedback_file(proj, Json::parse(R"({"title":"The ending of Lantern Keep","missing":"\"Sir Aldric\" scripts/ending.js crypt_level \"Gloomfang\""})"), "Ending problem here");
    s.mode(ShareMode::Always);
    auto q = share_queue(s.env, file, proj, engine_names());
    REQUIRE(q.ok());
    CHECK(q->rejected == 1);
    CHECK(load_outbox(s.env).items.empty());
    const Json shared = load_feedback(file).value()["entries"][0]["shared"];
    CHECK(shared["status"] == "rejected");
    CHECK(shared["reason"].get<std::string>().find("too short") != std::string::npos);
    // a rejected entry is not offered again
    CHECK_FALSE(entry_is_shareable(load_feedback(file).value()["entries"][0]));
}

TEST_CASE("share queue: ask waits for the user; confirm and drop") {
    Share s;
    const std::string proj = s.project();
    const std::string file = s.feedback_file(proj);
    s.mode(ShareMode::Ask);
    auto q = share_queue(s.env, file, proj, engine_names());
    REQUIRE(q.ok());
    CHECK(q->waiting == 1);
    CHECK(share_has_due(s.env) == false);
    s.script = {reply(200, s.answer_ok({{"FB-0001", "accepted"}}))};
    CHECK(share_flush(s.env).requests == 0);  // nothing confirmed: nothing sent
    CHECK(s.requests.empty());
    const auto waiting = share_waiting(s.env);
    REQUIRE(waiting.size() == 1);
    CHECK(waiting[0].localId == "FB-0001");
    SUBCASE("confirm sends") {
        CHECK(share_confirm(s.env, {waiting[0].key}) == 1);
        CHECK(share_has_due(s.env));
        const FlushResult f = share_flush(s.env);
        CHECK(f.sent == 1);
        CHECK(load_feedback(file).value()["entries"][0]["shared"]["status"] == "sent");
    }
    SUBCASE("drop marks skipped and never sends") {
        CHECK(share_drop(s.env, {waiting[0].key}) == 1);
        CHECK(load_outbox(s.env).items.empty());
        CHECK(load_feedback(file).value()["entries"][0]["shared"]["status"] == "skipped");
        CHECK(share_flush(s.env).requests == 0);
    }
}

TEST_CASE("share mode: never empties the outbox; always promotes what waited") {
    Share s;
    const std::string proj = s.project();
    const std::string file = s.feedback_file(proj);
    s.mode(ShareMode::Ask);
    REQUIRE(share_queue(s.env, file, proj, engine_names()).ok());
    s.mode(ShareMode::Always);
    CHECK(load_outbox(s.env).items[0].state == OutboxState::Queued);
    s.mode(ShareMode::Never);
    CHECK(load_outbox(s.env).items.empty());
    CHECK(load_feedback(file).value()["entries"][0]["shared"]["status"] == "skipped");
    s.mode(ShareMode::Always);  // turning it back on offers the skipped entry again
    auto q = share_queue(s.env, file, proj, engine_names());
    CHECK(q->queued == 1);
}

// ----------------------------------------------------------------------------------------------------------- the server answers

namespace {
struct Queued {
    Share s;
    std::string proj, file;
    Queued() {
        proj = s.project();
        file = s.feedback_file(proj);
        s.mode(ShareMode::Always);
        REQUIRE(share_queue(s.env, file, proj, engine_names()).ok());
    }
    Json shared() { return load_feedback(file).value()["entries"][0]["shared"]; }
};
}  // namespace

TEST_CASE("share flush: the request has the headers, the endpoint and the body of the contract") {
    Queued q;
    q.s.script = {reply(200, q.s.answer_ok({{"FB-0001", "accepted"}}))};
    REQUIRE(share_flush(q.s.env).sent == 1);
    REQUIRE(q.s.requests.size() == 1);
    const HttpRequest& r = q.s.requests[0];
    CHECK(r.method == "POST");
    CHECK(r.url == "https://feedback.example.test/v1/reports");
    auto header = [&](const std::string& n) { for (auto& [k, v] : r.headers) if (k == n) return v; return std::string("<none>"); };
    CHECK(header("X-Factoria-Install") == "11111111-2222-4333-8444-555555555555");
    CHECK(header("Authorization") == "<none>");  // anonymous
    CHECK(header("Content-Type") == "application/json");
    const Json body = parse_json(r.body, "body").value();
    CHECK(body["format"] == "factoria.feedback-share/1");
    CHECK(body["entries"][0]["localId"] == "FB-0001");
    CHECK(r.body.size() < 64 * 1024);
}

TEST_CASE("share flush: signed in, the credential is sent as a bearer token") {
    Queued q;
    ShareSettings st = load_share_settings(q.s.env);
    st.credential = "cred.sig";
    REQUIRE(save_share_settings(q.s.env, st).ok());
    q.s.script = {reply(200, q.s.answer_ok({{"FB-0001", "accepted"}}))};
    share_flush(q.s.env);
    bool found = false;
    for (auto& [k, v] : q.s.requests[0].headers) found = found || (k == "Authorization" && v == "Bearer cred.sig");
    CHECK(found);
}

TEST_CASE("share flush: accepted and merged entries leave the outbox and are marked sent with their shareId") {
    Queued q;
    q.s.script = {reply(200, q.s.answer_ok({{"FB-0001", "accepted"}}))};
    const FlushResult f = share_flush(q.s.env);
    CHECK(f.outcome == "sent");
    CHECK(f.sent == 1);
    CHECK(load_outbox(q.s.env).items.empty());
    CHECK(q.shared()["status"] == "sent");
    CHECK(q.shared()["shareId"] == "r_1");
    CHECK(q.shared()["date"] == "2027-01-15");
    // merged
    Queued m;
    m.s.script = {reply(200, m.s.answer_ok({{"FB-0001", "merged"}}))};
    const FlushResult g = share_flush(m.s.env);
    CHECK(g.merged == 1);
    CHECK(m.shared()["status"] == "sent");
}

TEST_CASE("share flush: a rejected entry keeps the server's code and reason and is not retried") {
    Queued q;
    q.s.script = {reply(200, q.s.answer_ok({{"FB-0001", "rejected"}}))};
    const FlushResult f = share_flush(q.s.env);
    CHECK(f.rejected == 1);
    CHECK(f.sent == 0);
    CHECK(load_outbox(q.s.env).items.empty());
    CHECK(q.shared()["status"] == "rejected");
    CHECK(q.shared()["reason"] == "too_short: missing needs at least 20 characters");
    CHECK_FALSE(entry_is_shareable(load_feedback(q.file).value()["entries"][0]));
}

TEST_CASE("share flush: 429 waits for Retry-After and backs off") {
    Queued q;
    q.s.script = {reply(429, Json::object({{"ok", false}, {"error", Json::object({{"code", "rate_limited"}, {"message", "slow down"}})}}),
                        {{"retry-after", "7200"}})};
    const FlushResult f = share_flush(q.s.env);
    CHECK(f.outcome == "rate_limited");
    CHECK(f.retryLater == 1);
    const Outbox box = load_outbox(q.s.env);
    REQUIRE(box.items.size() == 1);
    CHECK(box.items[0].attempts == 1);
    CHECK(box.items[0].nextAttempt == q.s.clock + 7200);
    CHECK(q.shared()["status"] == "pending");
    // not due until then; one request in total
    CHECK(share_has_due(q.s.env) == false);
    CHECK(share_flush(q.s.env).requests == 0);
    q.s.clock += 7200;
    CHECK(share_has_due(q.s.env));
}

TEST_CASE("share flush: 403 banned refuses the entries without detail and stops retrying them") {
    Queued q;
    q.s.script = {reply(403, Json::object({{"ok", false}, {"error", Json::object({{"code", "banned"}, {"message", "no"}})}}))};
    const FlushResult f = share_flush(q.s.env);
    CHECK(f.outcome == "banned");
    CHECK(load_outbox(q.s.env).items.empty());
    CHECK(q.shared()["status"] == "rejected");
}

TEST_CASE("share flush: a transport failure keeps the entry and backs off 1 min, 10 min, 1 h, then daily") {
    Queued q;
    q.s.script = {transport_failure("could not connect")};
    const std::int64_t expected[] = {60, 600, 3600, 86400, 86400};
    for (int i = 0; i < 5; ++i) {
        const std::int64_t start = q.s.clock;
        const FlushResult f = share_flush(q.s.env);
        CHECK(f.outcome == "failed");
        CHECK(f.retryLater == 1);
        const Outbox box = load_outbox(q.s.env);
        REQUIRE(box.items.size() == 1);
        CHECK(box.items[0].attempts == i + 1);
        CHECK(box.items[0].nextAttempt == start + expected[i]);
        CHECK(box.items[0].lastError == "could not connect");
        CHECK(share_flush(q.s.env).requests == 0);  // still backing off
        q.s.clock = box.items[0].nextAttempt;
    }
    CHECK(q.shared()["status"] == "pending");
    // when the server is back, the next attempt delivers
    q.s.script = {reply(200, q.s.answer_ok({{"FB-0001", "accepted"}}))};
    CHECK(share_flush(q.s.env).sent == 1);
}

TEST_CASE("share flush: 500, a non-JSON answer and a missing result are retried; a 400 is refused with the server's message") {
    {
        Queued q;
        q.s.script = {reply(500, Json::object())};
        CHECK(share_flush(q.s.env).retryLater == 1);
    }
    {
        Queued q;
        HttpResponse r;
        r.ok = true;
        r.status = 200;
        r.body = "<html>";
        q.s.script = {r};
        CHECK(share_flush(q.s.env).retryLater == 1);
    }
    {
        Queued q;
        q.s.script = {reply(200, q.s.answer_ok({{"FB-0099", "accepted"}}))};
        CHECK(share_flush(q.s.env).retryLater == 1);
        CHECK(load_outbox(q.s.env).items.size() == 1);
    }
    {
        Queued q;
        q.s.script = {reply(400, Json::object({{"ok", false}, {"error", Json::object({{"code", "bad_request"}, {"message", "unknown format"}})}}))};
        const FlushResult f = share_flush(q.s.env);
        CHECK(f.rejected == 1);
        CHECK(q.shared()["reason"] == "unknown format");
    }
}

TEST_CASE("share flush: at most 20 entries per request") {
    Share s;
    const std::string proj = s.project();
    Json doc = create_empty_feedback("g", "9.9.9");
    const char* topics[25] = {"gradient fills", "tilemap collisions", "bone attachments", "shadow cascades", "audio ducking",
                              "gamepad rumble", "text outlines", "particle trails", "scene streaming", "path smoothing",
                              "ragdoll joints", "decal projection", "cloth simulation", "voice chat", "save encryption",
                              "camera shake", "water reflections", "inventory grids", "dialogue trees", "terrain brushes",
                              "network replay", "sprite atlases", "light cookies", "rope physics", "mesh decimation"};
    const auto& cats = feedback_categories();
    for (int i = 0; i < 25; ++i) {
        FeedbackInput in;
        in.category = cats[std::size_t(i) % cats.size()];
        in.severity = "minor";
        in.title = std::string("No built-in ") + topics[i];
        in.missing = std::string("The engine has no ") + topics[i] + " feature";
        in.workaround = "wrote a script by hand";
        in.share = Json::object({{"title", std::string("No built-in ") + topics[i]},
                                 {"missing", std::string("The engine has no ") + topics[i] + " feature, so every game builds it again."}});
        auto added = add_feedback_entry(doc, in);
        REQUIRE(added.ok());
        REQUIRE_FALSE(added->merged);
    }
    const std::string file = proj + "/ENGINE_FEEDBACK.json";
    REQUIRE(save_feedback(file, doc).ok());
    s.mode(ShareMode::Always);
    auto q = share_queue(s.env, file, proj, engine_names());
    REQUIRE(q.ok());
    REQUIRE(q->queued + q->rejected == 25);
    const int queued = q->queued;
    auto answer = [&](const HttpRequest& r) {
        Json body = parse_json(r.body, "b").value();
        std::vector<std::pair<std::string, std::string>> results;
        for (const Json& e : body["entries"]) results.push_back({e["localId"].get<std::string>(), "accepted"});
        return reply(200, s.answer_ok(results));
    };
    s.env.transport = [&](const HttpRequest& r) { s.requests.push_back(r); return answer(r); };
    FlushOptions all;
    all.oneBatch = false;
    const FlushResult f = share_flush(s.env, all);
    CHECK(f.sent == queued);
    CHECK(s.requests.size() == std::size_t((queued + 19) / 20));
    for (const HttpRequest& r : s.requests) CHECK(parse_json(r.body, "b").value()["entries"].size() <= 20);
    CHECK(load_outbox(s.env).items.empty());
}

TEST_CASE("share flush: unavailable without an endpoint") {
    Queued q;
    q.s.env.defaultEndpoint.clear();
    const FlushResult f = share_flush(q.s.env);
    CHECK(f.outcome == "unavailable");
    CHECK(f.message.find("FA_FEEDBACK_URL") != std::string::npos);
    CHECK(q.s.requests.empty());
}

// ------------------------------------------------------------------------------------------------- feedback.report and commands

TEST_CASE("feedback.report: share and reviewed are stored; the answer tells what sharing did") {
    Share s;
    ScopedShareEnv scoped(s.env);
    const std::string proj = s.project();
    CommandRegistry registry;
    register_feedback_commands(registry, proj);
    Json args = Json::object({{"category", "physics"}, {"severity", "major"}, {"title", "No one-way platforms"},
                              {"missing", "Collider2D has no one-way option"}, {"workaround", "toggled a collider in a script"},
                              {"share", Share::good_share()}, {"reviewed", true}});
    SUBCASE("unset: recorded, and the answer says how the USER turns sharing on") {
        auto r = registry.call("feedback.report", args);
        REQUIRE(r.ok);
        CHECK(r.result["share"]["status"] == "not_set_up");
        const std::string msg = r.result["share"]["message"];
        CHECK(msg.find("factoria feedback sharing") != std::string::npos);
        CHECK(msg.find("Only the user") != std::string::npos);
        const Json e = load_feedback(proj + "/ENGINE_FEEDBACK.json").value()["entries"][0];
        CHECK(e["share"]["title"] == "No one-way platforms");
        CHECK(e["reviewed"] == true);
        CHECK(s.requests.empty());
        CHECK(load_share_settings(s.env).mode == ShareMode::Unset);  // the command did not change it
    }
    SUBCASE("always: queued and sent at once (one short attempt)") {
        s.mode(ShareMode::Always);
        s.script = {reply(200, s.answer_ok({{"FB-0001", "accepted"}}))};
        auto r = registry.call("feedback.report", args);
        REQUIRE(r.ok);
        CHECK(r.result["share"]["status"] == "sent");
        REQUIRE(s.requests.size() == 1);
        CHECK(s.requests[0].timeoutSec <= 3.0);
        CHECK(load_feedback(proj + "/ENGINE_FEEDBACK.json").value()["entries"][0]["shared"]["status"] == "sent");
    }
    SUBCASE("always, server down: the report still succeeds and the entry stays queued") {
        s.mode(ShareMode::Always);
        s.script = {transport_failure()};
        auto r = registry.call("feedback.report", args);
        REQUIRE(r.ok);
        CHECK(r.result["share"]["status"] == "queued");
        CHECK(r.result["id"] == "FB-0001");
        CHECK(load_outbox(s.env).items.size() == 1);
        // a second report inside the backoff window does not attempt another send
        Json other = args;
        other["category"] = "audio";
        other["title"] = "No positional audio falloff curve";
        other["share"]["title"] = "No positional audio falloff curve";
        CHECK(registry.call("feedback.report", other).ok);
        CHECK(s.requests.size() == 1);
        CHECK(load_outbox(s.env).items.size() == 2);
    }
    SUBCASE("ask: waits for confirmation") {
        s.mode(ShareMode::Ask);
        auto r = registry.call("feedback.report", args);
        REQUIRE(r.ok);
        CHECK(r.result["share"]["status"] == "waiting");
        CHECK(s.requests.empty());
    }
    SUBCASE("never: nothing is sent") {
        s.mode(ShareMode::Never);
        auto r = registry.call("feedback.report", args);
        REQUIRE(r.ok);
        CHECK(r.result["share"]["status"] == "off");
        CHECK(s.requests.empty());
    }
    SUBCASE("a share that fails the sanitizer is reported, never thrown") {
        s.mode(ShareMode::Always);
        args["share"] = Json::object({{"title", "Ashfall ending cutscene"}, {"missing", "\"The Ashfall ending cutscene\" in scripts/ending.js is missing"}});
        auto r = registry.call("feedback.report", args);
        REQUIRE(r.ok);
        CHECK(r.result["share"]["status"] == "rejected");
        CHECK(s.requests.empty());
    }
    SUBCASE("a malformed share is left out and explained, the entry is recorded") {
        args["share"] = Json::object({{"title", "x"}, {"missing", "short"}});
        auto r = registry.call("feedback.report", args);
        REQUIRE(r.ok);
        CHECK(r.result["share"]["status"] == "invalid");
        CHECK(load_feedback(proj + "/ENGINE_FEEDBACK.json").value()["entries"][0].contains("share") == false);
        CHECK(validate_feedback(load_feedback(proj + "/ENGINE_FEEDBACK.json").value()).empty());
    }
    SUBCASE("unavailable build: every sharing answer says so") {
        s.env.defaultEndpoint.clear();
        ScopedShareEnv inner(s.env);
        auto r = registry.call("feedback.report", args);
        REQUIRE(r.ok);
        CHECK(r.result["share"]["status"] == "unavailable");
        CHECK(registry.call("feedback.share_status", Json::object()).result["available"] == false);
    }
    SUBCASE("without share nothing about sharing is added") {
        args.erase("share");
        auto r = registry.call("feedback.report", args);
        REQUIRE(r.ok);
        CHECK_FALSE(r.result.contains("share"));
    }
}

TEST_CASE("feedback.report: merging keeps the longer share and reviewed") {
    Json doc = create_empty_feedback("g");
    FeedbackInput a;
    a.category = "physics";
    a.severity = "major";
    a.title = "No one-way platforms";
    a.missing = "Collider2D has no one-way option";
    a.workaround = "script";
    a.share = Share::good_share();
    a.reviewed = false;
    REQUIRE(add_feedback_entry(doc, a).ok());
    FeedbackInput b = a;
    b.share = Json::object({{"title", "No one-way platforms"}, {"missing", "Collider2D has no one-way option for bodies."}});
    b.reviewed = true;
    auto r = add_feedback_entry(doc, b);
    REQUIRE(r.ok());
    CHECK(r->merged);
    CHECK(doc["entries"][0]["share"] == Share::good_share());  // the shorter one does not replace it
    CHECK(doc["entries"][0]["reviewed"] == true);
    FeedbackInput c = a;
    c.share = Share::good_share();
    c.share["suggestion"] = "Add Collider2D.oneWay (bool) with a direction (up, down, left or right).";
    REQUIRE(add_feedback_entry(doc, c).ok());
    CHECK(doc["entries"][0]["share"]["suggestion"].get<std::string>().find("direction") != std::string::npos);
    CHECK(validate_feedback(doc).empty());
}

TEST_CASE("feedback share commands: preview, status and share") {
    Share s;
    ScopedShareEnv scoped(s.env);
    const std::string proj = s.project();
    s.feedback_file(proj);
    CommandRegistry registry;
    register_feedback_commands(registry, proj);
    for (const char* name : {"feedback.share_preview", "feedback.share_status", "feedback.share", "feedback.check_fixed"})
        CHECK(registry.has(name));
    for (const char* name : {"feedback.set_mode", "feedback.sharing", "feedback.share_mode"}) CHECK_FALSE(registry.has(name));

    auto pv = registry.call("feedback.share_preview", Json::object());
    REQUIRE(pv.ok);
    REQUIRE(pv.result["entries"].size() == 1);
    CHECK(pv.result["entries"][0]["ok"] == true);
    CHECK(pv.result["entries"][0]["sent"]["title"] == "No one-way platforms");
    CHECK(s.requests.empty());

    auto st = registry.call("feedback.share_status", Json::object());
    REQUIRE(st.ok);
    CHECK(st.result["mode"] == "unset");
    CHECK(st.result["available"] == true);
    CHECK(st.result["signedIn"] == false);
    CHECK(st.result.contains("howToTurnOn"));

    auto off = registry.call("feedback.share", Json::object());
    REQUIRE(off.ok);
    CHECK(off.result["outcome"] == "off");
    CHECK(s.requests.empty());

    s.mode(ShareMode::Always);
    s.script = {reply(200, s.answer_ok({{"FB-0001", "accepted"}}))};
    auto sent = registry.call("feedback.share", Json::object());
    REQUIRE(sent.ok);
    CHECK(sent.result["outcome"] == "sent");
    CHECK(sent.result["sent"] == 1);
    CHECK(registry.call("feedback.share_status", Json::object()).result["lastSend"]["outcome"] == "sent");
}

// --------------------------------------------------------------------------------------------------------- GitHub device flow

TEST_CASE("share sign-in: the device flow, the exchange, and sign-out") {
    Share s;
    std::vector<std::string> calls;
    s.env.transport = [&](const HttpRequest& r) {
        s.requests.push_back(r);
        if (r.url == "https://github.com/login/device/code")
            return reply(200, Json::object({{"device_code", "dc-1"}, {"user_code", "ABCD-1234"}, {"verification_uri", "https://github.com/login/device"},
                                            {"expires_in", 900}, {"interval", 5}}));
        if (r.url == "https://github.com/login/oauth/access_token") {
            static int polls = 0;
            ++polls;
            if (polls == 1) return reply(200, Json::object({{"error", "authorization_pending"}}));
            if (polls == 2) return reply(200, Json::object({{"error", "slow_down"}}));
            return reply(200, Json::object({{"access_token", "gho_secret"}, {"token_type", "bearer"}}));
        }
        if (r.url == "https://feedback.example.test/v1/auth/github")
            return reply(200, Json::object({{"ok", true}, {"credential", "payload.signature"}, {"login", "octocat"}}));
        return transport_failure("unexpected " + r.url);
    };
    DeviceCode shown;
    auto r = github_sign_in(s.env, [&](const DeviceCode& c) { shown = c; });
    REQUIRE(r.ok());
    CHECK(shown.userCode == "ABCD-1234");
    CHECK(r->login == "octocat");
    // requests: device code (no scope), three polls, the exchange
    REQUIRE(s.requests.size() == 5);
    CHECK(s.requests[0].body == "client_id=client-id-1");
    CHECK(s.requests[0].body.find("scope") == std::string::npos);
    auto header = [](const HttpRequest& q, const std::string& n) { for (auto& [k, v] : q.headers) if (k == n) return v; return std::string(); };
    CHECK(header(s.requests[0], "Accept") == "application/json");
    CHECK(s.requests[1].body.find("grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Adevice_code") != std::string::npos);
    CHECK(s.requests[1].body.find("device_code=dc-1") != std::string::npos);
    CHECK(s.requests[4].url == "https://feedback.example.test/v1/auth/github");
    CHECK(Json::parse(s.requests[4].body)["githubToken"] == "gho_secret");
    // polling waited the interval, and 5 s longer after slow_down
    REQUIRE(s.sleeps.size() == 3);
    CHECK(s.sleeps[0] == 5);
    CHECK(s.sleeps[1] == 5);
    CHECK(s.sleeps[2] == 10);
    // stored: credential and login, never the GitHub token
    const ShareSettings st = load_share_settings(s.env);
    CHECK(st.credential == "payload.signature");
    CHECK(st.login == "octocat");
    CHECK(testing::read_all(st.path).find("gho_secret") == std::string::npos);
    REQUIRE(share_sign_out(s.env).ok());
    const ShareSettings out = load_share_settings(s.env);
    CHECK(out.credential.empty());
    CHECK(out.login.empty());
    CHECK(out.installId == st.installId);
}

TEST_CASE("share sign-in: refusal, expiry, no client id, an unreachable server") {
    Share s;
    auto device = [&] { return reply(200, Json::object({{"device_code", "dc"}, {"user_code", "U"}, {"expires_in", 20}, {"interval", 5}})); };
    SUBCASE("access_denied") {
        s.env.transport = [&](const HttpRequest& r) { return r.url.find("device/code") != std::string::npos ? device() : reply(200, Json::object({{"error", "access_denied"}})); };
        auto r = github_sign_in(s.env, nullptr);
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find("refused") != std::string::npos);
    }
    SUBCASE("expired_token") {
        s.env.transport = [&](const HttpRequest& r) { return r.url.find("device/code") != std::string::npos ? device() : reply(200, Json::object({{"error", "expired_token"}})); };
        CHECK(github_sign_in(s.env, nullptr).error().message.find("expired") != std::string::npos);
    }
    SUBCASE("never authorized: stops when the code's lifetime is over") {
        s.env.transport = [&](const HttpRequest& r) { return r.url.find("device/code") != std::string::npos ? device() : reply(200, Json::object({{"error", "authorization_pending"}})); };
        auto r = github_sign_in(s.env, nullptr);
        REQUIRE_FALSE(r.ok());
        CHECK(s.sleeps.size() <= 5);
    }
    SUBCASE("cancelled between polls") {
        s.env.transport = [&](const HttpRequest& r) { return r.url.find("device/code") != std::string::npos ? device() : reply(200, Json::object({{"error", "authorization_pending"}})); };
        CHECK_FALSE(github_sign_in(s.env, nullptr, [] { return true; }).ok());
    }
    SUBCASE("no client id in this build") {
        s.env.githubClientId.clear();
        auto r = github_sign_in(s.env, nullptr);
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find("not available") != std::string::npos);
        CHECK(r.error().hint.find("FA_FEEDBACK_GITHUB_CLIENT_ID") != std::string::npos);
        CHECK(s.requests.empty());
    }
    SUBCASE("github unreachable") {
        s.env.transport = [&](const HttpRequest&) { return transport_failure("no route"); };
        CHECK(github_sign_in(s.env, nullptr).error().message.find("no route") != std::string::npos);
    }
    SUBCASE("the feedback server refuses the token") {
        s.env.transport = [&](const HttpRequest& r) {
            if (r.url.find("device/code") != std::string::npos) return device();
            if (r.url.find("access_token") != std::string::npos) return reply(200, Json::object({{"access_token", "t"}}));
            return reply(401, Json::object({{"ok", false}, {"error", Json::object({{"code", "invalid_token"}, {"message", "GitHub did not accept the token"}})}}));
        };
        auto r = github_sign_in(s.env, nullptr);
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find("GitHub did not accept") != std::string::npos);
        CHECK(load_share_settings(s.env).credential.empty());
    }
}
