// The runtime's http backend (make_http_backend) with a scripted HttpClient instead of the system's: how a response becomes the
// answer scripts get, how a failed request is rejected, the limit of requests in flight and a client that cannot run. The
// real clients are tested in engine/platform (against a server on 127.0.0.1), the dispatcher in engine/services.
#include <doctest.h>

#include <deque>

#include "fa/platform/http.h"
#include "fa/runtime/platform_backend.h"
#include "fa/services/fake_platform.h"
#include "fa/services/network.h"
#include "fa/services/platform.h"

using namespace fa;

namespace {

bool has(const std::string& text, const char* part) { return text.find(part) != std::string::npos; }

// A client that keeps every request and its `done` until the test answers it.
class ScriptedClient final : public HttpClient {
public:
    struct Shared {
        std::vector<HttpRequest> requests;
        std::deque<HttpDone> waiting;
        bool available = true;
    };
    explicit ScriptedClient(std::shared_ptr<Shared> s) : shared_(std::move(s)) {}
    std::string name() const override { return "scripted"; }
    bool available() const override { return shared_->available; }
    std::string unavailable_reason() const override { return "the scripted client is switched off"; }
    void send(HttpRequest request, HttpDone done) override {
        shared_->requests.push_back(std::move(request));
        shared_->waiting.push_back(std::move(done));
    }

private:
    std::shared_ptr<Shared> shared_;
};

struct Rig {
    std::shared_ptr<ScriptedClient::Shared> client = std::make_shared<ScriptedClient::Shared>();
    PlatformServices ps;
    explicit Rig(bool available = true) {
        client->available = available;
        auto n = load_network(Json::parse(R"({"hosts":["api.example.com"],"purpose":"test"})"));
        REQUIRE(n.ok());
        ps.set_network(n.value());
        ps.set_backend(std::make_unique<FakeBackend>());
        // The engine passes the client's own reason as the "why" of a client that cannot run.
        ps.set_http_backend(make_http_backend(std::make_unique<ScriptedClient>(client)),
                            available ? "scripted" : "the scripted client is switched off");
    }
    Result<PlatformServices::StartInfo> fetch(const char* extra = "") {
        return ps.start("http.fetch", Json::parse(std::string(R"({"url":"https://api.example.com/x")") + extra + "}"));
    }
    void answer(HttpResponse r) {
        REQUIRE_FALSE(client->waiting.empty());
        HttpDone done = std::move(client->waiting.front());
        client->waiting.pop_front();
        done(std::move(r));
    }
};

}  // namespace

TEST_CASE("http backend: a response becomes {status, headers, text}; repeated headers are joined and the text is valid UTF-8") {
    Rig rig;
    auto r = rig.fetch(R"(,"method":"POST","body":"{}","headers":{"X-Key":"k"},"timeout":3)");
    REQUIRE(r.ok());
    CHECK_FALSE(r->answer.has_value());
    REQUIRE(rig.client->requests.size() == 1);
    const HttpRequest& sent = rig.client->requests[0];
    CHECK(sent.method == "POST");
    CHECK(sent.url == "https://api.example.com/x");
    CHECK(sent.body == "{}");
    CHECK(sent.timeoutSec == 3.0);
    REQUIRE(sent.headers.size() == 1);
    CHECK(sent.headers[0].first == "X-Key");

    HttpResponse response;
    response.ok = true;
    response.status = 201;
    response.headers = {{"content-type", "text/plain"}, {"set-cookie", "a=1"}, {"set-cookie", "b=2"}, {"x-bad", "a\xFF" "b"}};
    response.body = std::string("caf\xC3\xA9 \xFF\xFE end");
    rig.answer(response);
    auto answers = rig.ps.take_answers();
    REQUIRE(answers.size() == 1);
    REQUIRE(answers[0].ok);
    const Json& result = answers[0].result;
    CHECK(result["status"] == 201);
    CHECK(result["headers"]["content-type"] == "text/plain");
    CHECK(result["headers"]["set-cookie"] == "a=1, b=2");
    CHECK(result["headers"]["x-bad"] == "a\xEF\xBF\xBD" "b");
    CHECK(result["text"] == "caf\xC3\xA9 \xEF\xBF\xBD\xEF\xBF\xBD end");
}

TEST_CASE("http backend: a request that did not complete is rejected with code network, its reason and its hint") {
    Rig rig;
    REQUIRE(rig.fetch().ok());
    HttpResponse failed;
    failed.error = "could not connect to api.example.com";
    failed.hint = "The server may be down.";
    rig.answer(failed);
    auto answers = rig.ps.take_answers();
    REQUIRE(answers.size() == 1);
    CHECK_FALSE(answers[0].ok);
    CHECK(answers[0].error.code == "network");
    CHECK(has(answers[0].error.message, "could not connect to api.example.com"));
    CHECK(answers[0].error.hint == "The server may be down.");

    // An HTTP error status is a completed request, not a failure.
    REQUIRE(rig.fetch().ok());
    HttpResponse notFound;
    notFound.ok = true;
    notFound.status = 404;
    rig.answer(notFound);
    answers = rig.ps.take_answers();
    REQUIRE(answers.size() == 1);
    CHECK(answers[0].ok);
    CHECK(answers[0].result["status"] == 404);
    CHECK(answers[0].result["text"] == "");
}

TEST_CASE("http backend: at most eight requests in flight, and a finished one frees its place") {
    Rig rig;
    for (int i = 0; i < 8; ++i) REQUIRE(rig.fetch().ok());
    CHECK(rig.client->requests.size() == 8);
    auto ninth = rig.fetch();
    REQUIRE(ninth.ok());
    REQUIRE(ninth->answer.has_value());
    CHECK(ninth->answer->error.code == "failed");
    CHECK(has(ninth->answer->error.message, "8 requests in flight"));
    CHECK(rig.client->requests.size() == 8);  // it never reached the client

    HttpResponse done;
    done.ok = true;
    done.status = 200;
    rig.answer(done);
    auto tenth = rig.fetch();
    REQUIRE(tenth.ok());
    CHECK_FALSE(tenth->answer.has_value());
    CHECK(rig.client->requests.size() == 9);
}

TEST_CASE("http backend: a client that cannot run offers no service and answers unavailable with its reason") {
    Rig rig(false);
    CHECK_FALSE(rig.ps.has_service("http"));
    auto r = rig.fetch();
    REQUIRE(r.ok());
    REQUIRE(r->answer.has_value());
    CHECK(r->answer->error.code == "unavailable");
    CHECK(has(r->answer->error.message, "the scripted client is switched off"));
    CHECK(rig.client->requests.empty());
}
