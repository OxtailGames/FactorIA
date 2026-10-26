// http.fetch in fa_services: the "network" section of factoria.json, the URL policy, the checks of prepare(), how the dispatcher
// routes the request (fake, http backend, a client that cannot run) and what the fake answers. The system HTTP clients and the
// runtime's HttpBackend are tested in engine/platform and engine/runtime.
#include <doctest.h>

#include <functional>

#include "fa/services/fake_platform.h"
#include "fa/services/network.h"
#include "fa/services/platform.h"

using namespace fa;

namespace {

bool has(const std::string& text, const char* part) { return text.find(part) != std::string::npos; }

NetworkPolicy policy(const char* hostsJson) {
    auto n = load_network(Json::parse(std::string("{\"hosts\":") + hostsJson + "}"));
    REQUIRE_MESSAGE(n.ok(), n.error().to_string());
    return n.value();
}

// A PlatformServices with the fake backend and a declared host list.
struct Game {
    PlatformServices ps;
    explicit Game(const char* hosts = R"(["api.example.com","*.cdn.example.com","localhost"])") {
        ps.set_backend(std::make_unique<FakeBackend>());
        ps.set_network(policy(hosts));
    }
    FakeBackend& fake() { return *ps.fake(); }
    std::string mistake(const Json& args) {
        auto r = ps.start("http.fetch", args);
        REQUIRE_FALSE(r.ok());
        return r.error().message + " | " + r.error().hint;
    }
    PlatformAnswer answer(const Json& args) {
        auto r = ps.start("http.fetch", args);
        REQUIRE_MESSAGE(r.ok(), r.error().to_string());
        REQUIRE(r->answer.has_value());
        return *r->answer;
    }
};

// Answers http.fetch the way the runtime's HttpBackend does, from this thread or later; counts what it got.
class FakeClient final : public PlatformBackend {
public:
    std::vector<Json> requests;
    PlatformSink kept;
    std::uint64_t waiting = 0;
    bool answerAtOnce = true;
    std::string name() const override { return "testclient"; }
    std::vector<std::string> services() const override { return {"http"}; }
    void attach(const PlatformSink& sink) override { kept = sink; }
    void request(std::uint64_t id, const std::string& method, const Json& args, const PlatformSink& sink) override {
        REQUIRE(method == "http.fetch");
        requests.push_back(args);
        if (answerAtOnce) sink.complete(id, Json::object({{"status", 204}, {"headers", Json::object()}, {"text", ""}}));
        else waiting = id;
    }
};

}  // namespace

// --------------------------------------------------------------------------------------------------- the section ----
TEST_CASE("network: a section lists hosts; wildcards cover subdomains but not the domain itself") {
    NetworkPolicy p = policy(R"(["API.Example.com","*.cdn.example.com","localhost"])");
    CHECK(p.declared());
    CHECK(p.allows("api.example.com"));  // entries are lower-cased
    CHECK(p.allows("a.cdn.example.com"));
    CHECK(p.allows("a.b.cdn.example.com"));
    CHECK_FALSE(p.allows("cdn.example.com"));
    CHECK_FALSE(p.allows("evilcdn.example.com"));
    CHECK_FALSE(p.allows("example.com"));
    CHECK_FALSE(p.allows("api.example.com.evil.org"));
    CHECK(NetworkPolicy::is_loopback("localhost"));
    CHECK(NetworkPolicy::is_loopback("127.0.0.1"));
    CHECK(NetworkPolicy::is_loopback("::1"));
    CHECK_FALSE(NetworkPolicy::is_loopback("127.example.com"));
    CHECK_FALSE(NetworkPolicy::is_loopback("10.0.0.1"));
    CHECK_FALSE(NetworkPolicy().declared());
}

TEST_CASE("network: every problem of the section says where it is and how to fix it") {
    auto problems = [](const char* json) { return parse_network(Json::parse(json)); };
    {
        NetworkParse n = problems(R"({"hosts": ["https://api.example.com/x"]})");
        REQUIRE_FALSE(n.ok());
        CHECK(n.issues[0].pointer == "/network/hosts/0");
        CHECK(has(n.issues[0].message, "is a URL, not a host"));
        CHECK(has(n.issues[0].hint, "api.example.com"));
    }
    CHECK(has(problems(R"({"hosts": ["api.example.com:8443"]})").issues[0].message, "has a port"));
    CHECK(has(problems(R"({"hosts": ["*.com"]})").issues[0].message, "not a valid wildcard"));
    CHECK(has(problems(R"({"hosts": ["a*b.com"]})").issues[0].message, "wrong place"));
    CHECK(has(problems(R"({"hosts": ["user@example.com"]})").issues[0].message, "user name"));
    CHECK(has(problems(R"({"hosts": [3]})").issues[0].message, "must be a host name string"));
    CHECK(has(problems(R"({"hosts": []})").issues[0].message, "is empty"));
    CHECK(has(problems(R"({"purpose": "x"})").issues[0].message, "missing"));
    CHECK(has(problems(R"({"hosts": "api.example.com"})").issues[0].message, "must be a list"));
    CHECK(has(problems(R"([])").issues[0].message, "expected an object"));
    {
        // A typo is a warning with a suggestion, the host list still counts.
        NetworkParse n = problems(R"({"host": ["x.com"], "hosts": ["api.example.com"], "purpose": "scores"})");
        CHECK(n.ok());
        REQUIRE(n.issues.size() == 1);
        CHECK(n.issues[0].warning);
        CHECK(has(n.issues[0].hint, "hosts"));
        CHECK(n.policy.hosts == std::vector<std::string>{"api.example.com"});
    }
    {
        // Hosts without a purpose: a warning that points at the privacy notice.
        NetworkParse n = problems(R"({"hosts": ["api.example.com"]})");
        CHECK(n.ok());
        REQUIRE(n.issues.size() == 1);
        CHECK(n.issues[0].pointer == "/network/purpose");
        CHECK(n.issues[0].warning);
    }
    CHECK(parse_network(Json()).issues.empty());  // no section: no network, nothing to say
    CHECK_FALSE(load_network(Json::parse(R"({"hosts": [3]})")).ok());
    CHECK(has(load_network(Json::parse(R"({"hosts": [3]})")).error().to_string(), "factoria.json#/network/hosts/0"));
}

// ------------------------------------------------------------------------------------------------------ the URL ----
TEST_CASE("network: URLs are taken apart and checked against the policy") {
    NetworkPolicy p = policy(R"(["api.example.com","*.cdn.example.com","localhost","127.0.0.1"])");
    auto ok = check_http_url("HTTPS://API.Example.com/a/b?x=1#frag", p);
    REQUIRE_MESSAGE(ok.ok(), ok.error().to_string());
    CHECK(ok->scheme == "https");
    CHECK(ok->host == "api.example.com");
    CHECK(ok->url == "https://api.example.com/a/b?x=1");  // lower-case host, no fragment
    CHECK(check_http_url("https://api.example.com", p)->url == "https://api.example.com/");
    CHECK(check_http_url("https://api.example.com:8443/", p)->port == 8443);
    CHECK(check_http_url("https://a.cdn.example.com/x.json", p).ok());
    CHECK(check_http_url("http://localhost:8080/x", p).ok());      // loopback may use http
    CHECK(check_http_url("http://127.0.0.1:8080/x", p).ok());

    auto message = [&](const char* url) {
        auto r = check_http_url(url, p);
        REQUIRE_FALSE(r.ok());
        return r.error().message + " | " + r.error().hint;
    };
    CHECK(has(message("http://api.example.com/x"), "plain http://"));         // http to a real host
    CHECK(has(message("http://api.example.com/x"), "https://api.example.com"));
    CHECK(has(message("https://other.example.com/x"), "not declared"));
    CHECK(has(message("https://api.example.co/x"), "Did you mean"));          // near miss
    CHECK(has(message("https://cdn.example.com/x"), "not declared"));         // the wildcard does not cover the domain
    CHECK(has(message("ftp://api.example.com/x"), "only speaks https"));
    CHECK(has(message("https://user:pw@api.example.com/x"), "user name or password"));
    CHECK(has(message("api.example.com/x"), "not absolute"));
    CHECK(has(message("https://api.example.com/a b"), "space"));
    CHECK(has(message("https://api.example.com:99999/"), "not 1 to 65535"));
    CHECK(has(message("https:///x"), "no host"));
    CHECK(has(message(""), "empty"));
    // A host that is not declared stays refused even over the loopback exception.
    CHECK(has(message("http://127.0.0.2/x"), "not declared"));
    CHECK_FALSE(check_http_url("https://api.example.com/", NetworkPolicy()).ok());
    CHECK(has(check_http_url("https://api.example.com/", NetworkPolicy()).error().message, "declares no network hosts"));
}

// ------------------------------------------------------------------------------------------------------ prepare ----
TEST_CASE("http.fetch: the call is checked before anything is sent") {
    Game g;
    CHECK(has(g.mistake(Json::object()), "url"));
    CHECK(has(g.mistake(Json::parse(R"({"url":"https://other.example.com/"})")), "not declared"));
    CHECK(has(g.mistake(Json::parse(R"({"url":"https://api.example.com/","method":"POSTT"})")), "did you mean \"POST\""));
    CHECK(has(g.mistake(Json::parse(R"({"url":"https://api.example.com/","method":"TRACE"})")), "GET, HEAD, POST, PUT, PATCH or DELETE"));
    CHECK(has(g.mistake(Json::parse(R"({"url":"https://api.example.com/","method":7})")), "must be a string"));
    CHECK(has(g.mistake(Json::parse(R"({"url":"https://api.example.com/","body":"x"})")), "cannot have a body"));
    CHECK(has(g.mistake(Json::parse(R"({"url":"https://api.example.com/","method":"POST","body":5})")), "\"body\" must be a string"));
    CHECK(has(g.mistake(Json::parse(R"({"url":"https://api.example.com/","headers":[]})")), "must be an object"));
    CHECK(has(g.mistake(Json::parse(R"({"url":"https://api.example.com/","headers":{"X-A":1}})")), "must be a string"));
    CHECK(has(g.mistake(Json::parse(R"({"url":"https://api.example.com/","headers":{"Host":"evil.com"}})")), "set by the system"));
    CHECK(has(g.mistake(Json::parse(R"({"url":"https://api.example.com/","headers":{"Sec-Fetch-Mode":"x"}})")), "set by the system"));
    CHECK(has(g.mistake(Json::parse(R"({"url":"https://api.example.com/","headers":{"X-A":"1","x-a":"2"}})")), "twice"));
    CHECK(has(g.mistake(Json::parse(R"({"url":"https://api.example.com/","headers":{"X-A":"a\nb"}})")), "line break"));
    CHECK(has(g.mistake(Json::parse(R"({"url":"https://api.example.com/","headers":{"bad name":"a"}})")), "not valid"));
    CHECK(has(g.mistake(Json::parse(R"({"url":"https://api.example.com/","timeout":0})")), "above 0 and at most 120"));
    CHECK(has(g.mistake(Json::parse(R"({"url":"https://api.example.com/","timeout":500})")), "above 0 and at most 120"));
    CHECK(has(g.mistake(Json::parse(R"({"url":"https://api.example.com/","timeout":"x"})")), "above 0 and at most 120"));
    Json big = Json::object({{"url", "https://api.example.com/"}, {"method", "POST"}, {"body", std::string(1024 * 1024 + 1, 'x')}});
    CHECK(has(g.mistake(big), "the most is 1048576"));
}

TEST_CASE("http.fetch: what the backend receives is shaped") {
    PlatformServices ps;
    ps.set_network(policy(R"(["api.example.com"])"));
    auto client = std::make_unique<FakeClient>();
    FakeClient* c = client.get();
    ps.set_backend(std::make_unique<FakeBackend>());
    ps.set_http_backend(std::move(client));
    auto r = ps.start("http.fetch", Json::parse(R"({"url":"HTTPS://Api.Example.com","method":"post","body":"{}","headers":{"Content-Type":"application/json"},"timeout":30})"));
    REQUIRE_MESSAGE(r.ok(), r.error().to_string());
    REQUIRE(c->requests.size() == 1);
    const Json& got = c->requests[0];
    CHECK(got["url"] == "https://api.example.com/");
    CHECK(got["host"] == "api.example.com");
    CHECK(got["method"] == "POST");
    CHECK(got["body"] == "{}");
    CHECK(got["headers"]["Content-Type"] == "application/json");
    CHECK(got["timeout"] == 30.0);
    // A request without options: GET, no headers, 15 seconds, no body.
    REQUIRE(ps.start("http.fetch", Json::parse(R"({"url":"https://api.example.com/x"})")).ok());
    const Json& plain = c->requests[1];
    CHECK(plain["method"] == "GET");
    CHECK(plain["headers"].empty());
    CHECK(plain["timeout"] == 15.0);
    CHECK_FALSE(plain.contains("body"));
}

// ------------------------------------------------------------------------------------------------------ routing ----
TEST_CASE("http.fetch: the fake answers only what a test scripted and never reaches the network") {
    Game g;
    CHECK(g.ps.has_service("http"));
    CHECK(g.ps.info()["httpBackend"] == "fake");
    CHECK(g.ps.info()["networkHosts"] == Json::parse(R"(["api.example.com","*.cdn.example.com","localhost"])"));
    const Json call = Json::parse(R"({"url":"https://api.example.com/scores"})");

    PlatformAnswer none = g.answer(call);  // nothing scripted
    CHECK_FALSE(none.ok);
    CHECK(none.error.code == "network");
    CHECK(has(none.error.message, "never reaches the network"));
    CHECK(has(none.error.hint, "game.platform.respond"));

    REQUIRE(g.fake().respond("http.fetch", Json::parse(R"({"status":201,"json":{"id":7},"headers":{"X-Rate":"5"}})")).ok());
    PlatformAnswer made = g.answer(call);
    REQUIRE(made.ok);
    CHECK(made.result["status"] == 201);
    CHECK(Json::parse(made.result["text"].get<std::string>()) == Json::parse(R"({"id":7})"));
    CHECK(made.result["headers"]["x-rate"] == "5");  // lower-cased
    CHECK(made.result["headers"]["content-type"] == "application/json");
    CHECK_FALSE(made.result.contains("json"));

    REQUIRE(g.fake().respond("http.fetch", Json::parse(R"({"status":404})")).ok());
    PlatformAnswer missing = g.answer(call);  // defaults fill in
    CHECK(missing.result == Json::parse(R"({"status":404,"headers":{},"text":""})"));

    REQUIRE(g.fake().respond("http.fetch", Json::parse(R"({"error":"network","message":"offline"})")).ok());
    PlatformAnswer offline = g.answer(call);
    CHECK_FALSE(offline.ok);
    CHECK(offline.error.code == "network");
    CHECK(offline.error.message == "offline");

    REQUIRE(g.fake().respond("http.fetch", Json::parse(R"({"result":{"status":200,"headers":{},"text":"hi"}})")).ok());
    CHECK(g.answer(call).result["text"] == "hi");

    // A result that is not shaped like a response is a failure, not something to hand to the game.
    REQUIRE(g.fake().respond("http.fetch", Json::parse(R"({"result":{"status":"ok"}})")).ok());
    PlatformAnswer garbled = g.answer(call);
    CHECK_FALSE(garbled.ok);
    CHECK(garbled.error.code == "failed");
    CHECK(has(garbled.error.message, "without {status, headers, text}"));

    // The request log has the call, and signing out does not matter: http.fetch is no store call.
    g.fake().set_signed_in(false);
    REQUIRE(g.fake().respond("http.fetch", Json::parse(R"({"status":200})")).ok());
    CHECK(g.answer(call).ok);
}

TEST_CASE("http.fetch: an http backend answers instead of the fake, and a client that cannot run says why") {
    PlatformServices ps;
    ps.set_network(policy(R"(["api.example.com"])"));
    ps.set_backend(std::make_unique<FakeBackend>());
    auto client = std::make_unique<FakeClient>();
    FakeClient* c = client.get();
    ps.set_http_backend(std::move(client), "the test client");
    CHECK(ps.info()["httpBackend"] == "testclient");
    CHECK(ps.has_service("http"));
    auto r = ps.start("http.fetch", Json::parse(R"({"url":"https://api.example.com/"})"));
    REQUIRE(r.ok());
    REQUIRE(r->answer.has_value());
    CHECK(r->answer->result["status"] == 204);
    CHECK(c->requests.size() == 1);

    // Answered later, from another frame: the request waits in `pending`.
    c->answerAtOnce = false;
    auto later = ps.start("http.fetch", Json::parse(R"({"url":"https://api.example.com/"})"));
    REQUIRE(later.ok());
    CHECK_FALSE(later->answer.has_value());
    CHECK(ps.pending() == 1);
    c->kept.complete(c->waiting, Json::object({{"status", 200}, {"headers", Json::object()}, {"text", "later"}}));
    auto answers = ps.take_answers();
    REQUIRE(answers.size() == 1);
    CHECK(answers[0].result["text"] == "later");

    // The store backend being replaced keeps the http backend.
    ps.set_backend(std::make_unique<FakeBackend>());
    CHECK(ps.info()["httpBackend"] == "testclient");

    // A client that cannot run: no "http" service, and the request is answered "unavailable" with the reason, not by the fake.
    class Broken final : public PlatformBackend {
    public:
        std::string name() const override { return "broken"; }
        std::vector<std::string> services() const override { return {}; }
        void request(std::uint64_t, const std::string&, const Json&, const PlatformSink&) override { FAIL("must not be asked"); }
    };
    ps.set_http_backend(std::make_unique<Broken>(), "no libcurl here");
    CHECK_FALSE(ps.has_service("http"));
    auto refused = ps.start("http.fetch", Json::parse(R"({"url":"https://api.example.com/"})"));
    REQUIRE(refused.ok());
    REQUIRE(refused->answer.has_value());
    CHECK(refused->answer->error.code == "unavailable");
    CHECK(has(refused->answer->error.message, "no libcurl here"));
    CHECK(has(refused->answer->error.hint, "platform.has(\"http\")"));

    // Without it the fake serves http again.
    ps.set_http_backend(nullptr);
    CHECK(ps.has_service("http"));
    CHECK(ps.info()["httpBackend"] == "fake");
}

TEST_CASE("http.fetch: a game without declared hosts cannot fetch, and a store without http does not matter") {
    PlatformServices ps;
    ps.set_backend(std::make_unique<FakeBackend>());
    auto r = ps.start("http.fetch", Json::parse(R"({"url":"https://api.example.com/"})"));
    REQUIRE_FALSE(r.ok());
    CHECK(has(r.error().message, "declares no network hosts"));
    CHECK(has(r.error().hint, "\"network\""));
    // With the backend "none" (a game without a store) the fake offers nothing, http included.
    ps.set_network(policy(R"(["api.example.com"])"));
    ps.fake()->set_none(true);
    ps.refresh_backend();
    CHECK_FALSE(ps.has_service("http"));
    auto none = ps.start("http.fetch", Json::parse(R"({"url":"https://api.example.com/"})"));
    REQUIRE(none.ok());
    CHECK(none->answer->error.code == "unavailable");
}

TEST_CASE("http.fetch: plugin backends cannot offer the http service and the list of store services stays as it was") {
    const auto all = platform_services_all();
    CHECK(std::find(all.begin(), all.end(), "http") == all.end());
    CHECK(all.size() == 10);  // the store services (remotePlay included); "http" is not one of them
}

// ------------------------------------------------------------------------------------------------- the http log ----
TEST_CASE("http.fetch: the http log hands answers over in request order, with the frame of the request") {
    PlatformServices ps;
    ps.set_network(policy(R"(["api.example.com"])"));
    ps.set_backend(std::make_unique<FakeBackend>());
    auto client = std::make_unique<FakeClient>();
    FakeClient* c = client.get();
    c->answerAtOnce = false;
    ps.set_http_backend(std::move(client));
    std::uint64_t frame = 3;
    ps.set_frame_clock(&frame);
    ps.log_http(true);
    const Json call = Json::parse(R"({"url":"https://api.example.com/"})");

    auto first = ps.start("http.fetch", call);
    REQUIRE(first.ok());
    const std::uint64_t firstId = c->waiting;
    frame = 5;
    auto second = ps.start("http.fetch", call);
    REQUIRE(second.ok());
    const std::uint64_t secondId = c->waiting;

    // The second answer comes first: it waits for the first.
    c->kept.complete(secondId, Json::object({{"status", 200}, {"headers", Json::object()}, {"text", "two"}}));
    CHECK(ps.take_http_log().empty());
    c->kept.fail(firstId, {"network", "timed out", "retry"});
    auto log = ps.take_http_log();
    REQUIRE(log.size() == 2);
    CHECK(log[0].frame == 3);
    CHECK(log[0].answer == Json::parse(R"({"error":"network","message":"timed out","hint":"retry"})"));
    CHECK(log[1].frame == 5);
    CHECK(log[1].answer["result"]["text"] == "two");
    CHECK(ps.take_http_log().empty());

    // The entries are what FakeBackend::respond takes: replaying them gives the same answers.
    FakeBackend replay;
    for (const HttpLogEntry& e : log) CHECK(replay.respond("http.fetch", e.answer).ok());
}

TEST_CASE("analytics and remoteConfig sections: the endpoint must be https and its host declared") {
    const NetworkPolicy net = policy(R"(["stats.example.com"])");
    auto a = parse_analytics(Json::parse(R"({"endpoint":"https://stats.example.com/e","batch":10,"flushSeconds":15})"), net);
    CHECK(a.ok());
    CHECK(a.settings.configured);
    CHECK(a.settings.batch == 10);
    CHECK(a.settings.flushSeconds == 15);

    auto none = parse_analytics(Json(), net);
    CHECK(none.ok());
    CHECK_FALSE(none.settings.configured);

    auto host = parse_analytics(Json::parse(R"({"endpoint":"https://other.example.com/e"})"), net);
    REQUIRE_FALSE(host.ok());
    CHECK(has(host.issues[0].pointer, "/endpoint"));
    CHECK(has(host.issues[0].message, "network"));

    CHECK_FALSE(parse_analytics(Json::parse(R"({"endpoint":"http://stats.example.com/e"})"), net).ok());

    auto typo = parse_analytics(Json::parse(R"({"endpoint":"https://stats.example.com/e","batchh":3})"), net);
    REQUIRE_FALSE(typo.ok());
    CHECK(has(typo.issues[0].message, "batch"));

    CHECK_FALSE(parse_analytics(Json::parse(R"({"endpoint":"https://stats.example.com/e","batch":0})"), net).ok());
    CHECK_FALSE(parse_analytics(Json::parse(R"({"endpoint":"https://stats.example.com/e","batch":101})"), net).ok());
    CHECK_FALSE(parse_analytics(Json::parse(R"({"endpoint":"https://stats.example.com/e","flushSeconds":0})"), net).ok());
    CHECK_FALSE(parse_analytics(Json::parse(R"({"endpoint":"https://stats.example.com/e","consentFromAds":"yes"})"), net).ok());
    CHECK_FALSE(parse_analytics(Json::parse(R"({"batch":3})"), net).ok());  // no endpoint

    auto r = parse_remote_config(Json::parse(R"({"url":"https://stats.example.com/cfg.json","timeoutSeconds":2})"), net);
    CHECK(r.ok());
    CHECK(r.settings.timeoutSeconds == 2);
    CHECK_FALSE(parse_remote_config(Json::parse(R"({"url":"https://stats.example.com/cfg.json","timeoutSeconds":31})"), net).ok());
    CHECK_FALSE(parse_remote_config(Json::parse(R"({"url":"https://nope.example.com/cfg.json"})"), net).ok());
}
