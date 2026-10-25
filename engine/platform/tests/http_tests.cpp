// The system HTTP clients (fa/platform/http.h) against a server on 127.0.0.1 started by the test (http_test_server.h): no test
// here reaches another machine. The Windows and Apple clients run in their own platform's build; the libcurl client runs
// wherever libcurl is installed (it is skipped, not failed, when it is not: the player never links it).
#include <doctest.h>

#include <chrono>
#include <future>
#include <optional>

#include "fa/core/json.h"
#include "fa/platform/http.h"
#include "http_test_server.h"

using namespace fa;
using namespace fa::test;

namespace {

// Sends one request and waits for its answer (the client answers on any thread, once).
HttpResponse fetch(HttpClient& client, HttpRequest request) {
    auto promise = std::make_shared<std::promise<HttpResponse>>();
    auto future = promise->get_future();
    client.send(std::move(request), [promise](HttpResponse r) { promise->set_value(std::move(r)); });
    if (future.wait_for(std::chrono::seconds(30)) != std::future_status::ready) {
        HttpResponse timeout;
        timeout.error = "the test gave up waiting for the client";
        return timeout;
    }
    return future.get();
}

HttpRequest get(const std::string& url, double timeout = 10.0) {
    HttpRequest r;
    r.url = url;
    r.timeoutSec = timeout;
    return r;
}

std::optional<std::string> header(const HttpResponse& r, const std::string& name) {
    std::string joined;
    bool found = false;
    for (const auto& [k, v] : r.headers) {
        if (k != name) continue;
        joined += (found ? ", " : "") + v;
        found = true;
    }
    if (!found) return std::nullopt;
    return joined;
}

void run_suite(HttpClient& client) {
    HttpTestServer server;
    REQUIRE(server.ok());

    SUBCASE("GET: status, body and lower-case headers") {
        HttpResponse r = fetch(client, get(server.url("/hello")));
        INFO(r.error);
        REQUIRE(r.ok);
        CHECK(r.status == 200);
        CHECK(r.body == "hello");
        CHECK(header(r, "x-test") == "yes");
        REQUIRE(header(r, "set-cookie").has_value());
        CHECK(header(r, "set-cookie")->find("a=1") != std::string::npos);
        for (const auto& [k, v] : r.headers)
            for (char c : k) CHECK(!(c >= 'A' && c <= 'Z'));
    }

    SUBCASE("POST: the body and the headers arrive as sent") {
        HttpRequest q;
        q.method = "POST";
        q.url = server.url("/echo?x=1");
        q.headers = {{"Content-Type", "application/json"}, {"X-Game-Key", "k-42"}};
        q.body = R"({"score":10})";
        q.timeoutSec = 10;
        HttpResponse r = fetch(client, q);
        INFO(r.error);
        REQUIRE(r.ok);
        CHECK(r.status == 200);
        const Json echo = Json::parse(r.body);
        CHECK(echo["method"] == "POST");
        CHECK(echo["path"] == "/echo?x=1");
        CHECK(echo["body"] == R"({"score":10})");
        CHECK(echo["headers"]["x-game-key"] == "k-42");
        CHECK(echo["headers"]["content-type"] == "application/json");
    }

    SUBCASE("PUT, PATCH and DELETE send their own method") {
        for (const char* method : {"PUT", "PATCH", "DELETE"}) {
            HttpRequest q;
            q.method = method;
            q.url = server.url("/echo");
            q.timeoutSec = 10;
            if (std::string(method) != "DELETE") q.body = "payload";
            HttpResponse r = fetch(client, q);
            INFO(method << ": " << r.error);
            REQUIRE(r.ok);
            const Json echo = Json::parse(r.body);
            CHECK(echo["method"] == method);
            CHECK(echo["body"] == (std::string(method) == "DELETE" ? "" : "payload"));
        }
    }

    SUBCASE("HEAD: status and headers, no body") {
        HttpRequest q = get(server.url("/hello"));
        q.method = "HEAD";
        HttpResponse r = fetch(client, q);
        INFO(r.error);
        REQUIRE(r.ok);
        CHECK(r.status == 200);
        CHECK(r.body.empty());
    }

    SUBCASE("an error status is a completed request") {
        HttpResponse r = fetch(client, get(server.url("/status/404")));
        REQUIRE(r.ok);
        CHECK(r.status == 404);
        CHECK(r.body == "status 404");
        r = fetch(client, get(server.url("/status/503")));
        REQUIRE(r.ok);
        CHECK(r.status == 503);
    }

    SUBCASE("a chunked answer is put together") {
        HttpResponse r = fetch(client, get(server.url("/chunked")));
        INFO(r.error);
        REQUIRE(r.ok);
        CHECK(r.body == "abcdef");
    }

    SUBCASE("a redirect to plain http:// is refused") {
        HttpResponse r = fetch(client, get(server.url("/redirect-http")));
        CHECK_FALSE(r.ok);
        CHECK(r.error.find("not https://") != std::string::npos);
        CHECK_FALSE(r.hint.empty());
    }

    SUBCASE("an answer over maxResponseBytes is an error, not a truncated text") {
        HttpRequest q = get(server.url("/big"));
        q.maxResponseBytes = 1000;
        HttpResponse r = fetch(client, q);
        CHECK_FALSE(r.ok);
        CHECK(r.error.find("longer than") != std::string::npos);
        // Under the cap it is all there.
        q.maxResponseBytes = 300000;
        r = fetch(client, q);
        REQUIRE(r.ok);
        CHECK(r.body.size() == 200000);
    }

    SUBCASE("a request that takes longer than the timeout reports timedOut") {
        const auto start = std::chrono::steady_clock::now();
        HttpResponse r = fetch(client, get(server.url("/slow"), 0.3));
        const double seconds = std::chrono::duration<double>(std::chrono::steady_clock::now() - start).count();
        CHECK_FALSE(r.ok);
        CHECK(r.timedOut);
        CHECK(r.error.find("timed out") != std::string::npos);
        CHECK(seconds < 1.4);
    }

    SUBCASE("a response that is not UTF-8 reaches the caller as bytes (the runtime sanitizes it)") {
        HttpResponse r = fetch(client, get(server.url("/binary")));
        REQUIRE(r.ok);
        CHECK(r.body == std::string("a\xFF" "b"));
    }

    SUBCASE("a refused connection is an error with a hint") {
        int closedPort = 0;
        {
            HttpTestServer gone;
            REQUIRE(gone.ok());
            closedPort = gone.port();
        }
        HttpResponse r = fetch(client, get("http://127.0.0.1:" + std::to_string(closedPort) + "/", 5.0));
        CHECK_FALSE(r.ok);
        CHECK(r.error.find("127.0.0.1") != std::string::npos);
        CHECK_FALSE(r.hint.empty());
    }

    SUBCASE("a URL that is not http(s) is an error, not a crash") {
        HttpResponse r = fetch(client, get("ftp://127.0.0.1/x"));
        CHECK_FALSE(r.ok);
        CHECK_FALSE(r.error.empty());
        r = fetch(client, get("not a url"));
        CHECK_FALSE(r.ok);
    }

    SUBCASE("several requests at once each get their own answer") {
        std::vector<std::shared_ptr<std::promise<HttpResponse>>> promises;
        std::vector<std::future<HttpResponse>> futures;
        for (int i = 0; i < 6; ++i) {
            auto p = std::make_shared<std::promise<HttpResponse>>();
            futures.push_back(p->get_future());
            promises.push_back(p);
            client.send(get(server.url("/status/" + std::to_string(200 + i))), [p](HttpResponse r) { p->set_value(std::move(r)); });
        }
        for (int i = 0; i < 6; ++i) {
            REQUIRE(futures[static_cast<std::size_t>(i)].wait_for(std::chrono::seconds(30)) == std::future_status::ready);
            const HttpResponse r = futures[static_cast<std::size_t>(i)].get();
            REQUIRE(r.ok);
            CHECK(r.status == 200 + i);
        }
    }
}

}  // namespace

TEST_CASE("http: the system client of this platform") {
    std::unique_ptr<HttpClient> client = make_system_http_client();
    REQUIRE(client);
    if (!client->available()) {
        MESSAGE("not available here: " << client->unavailable_reason());
        return;
    }
    run_suite(*client);
}

#if !defined(_WIN32) && !defined(__EMSCRIPTEN__)
TEST_CASE("http: the libcurl client loaded with dlopen") {
    std::unique_ptr<HttpClient> client = make_curl_http_client();
    REQUIRE(client);
    CHECK(client->name() == "curl");
    if (!client->available()) {
        MESSAGE("libcurl is not installed here, skipped: " << client->unavailable_reason());
        return;
    }
    run_suite(*client);
}

TEST_CASE("http: a client that is not available answers every request with the reason") {
    // Whatever this machine has, an unavailable client must still answer (exactly once) instead of dropping the request.
    std::unique_ptr<HttpClient> client = make_curl_http_client();
    if (client->available()) return;
    HttpResponse r = fetch(*client, get("https://example.invalid/"));
    CHECK_FALSE(r.ok);
    CHECK(r.error.find("libcurl") != std::string::npos);
}
#endif
