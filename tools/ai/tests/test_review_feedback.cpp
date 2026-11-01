// ai.review_feedback: the AI check of a feedback entry's `share` text (fake model: nothing is ever sent anywhere).
#include <doctest.h>

#include "fa/ai/commands.h"
#include "fa/tooling/feedback.h"
#include "fa/tooling/feedback_share.h"
#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;

namespace {

const char* kGoodShare = R"({"title":"No one-way platforms","missing":"Collider2D has no oneWay option, so a body cannot pass up through a platform and land on it.","suggestion":"Add Collider2D.oneWay (bool)."})";

struct Fixture {
    TempDir dir;
    CommandRegistry registry = make_registry();
    std::shared_ptr<FakeProvider> provider = std::make_shared<FakeProvider>();
    std::string file;
    AiConfig cfg = default_config();
    int factoryCalls = 0;

    explicit Fixture(const std::string& shareText = kGoodShare, bool withShare = true) {
        file = (dir.path / "ENGINE_FEEDBACK.json").string();
        Json doc = create_empty_feedback("Dungeon of Ash");
        for (int i = 0; i < 2; ++i) {
            FeedbackInput in;
            in.category = "physics";
            in.severity = "major";
            in.title = i == 0 ? "Knight cannot jump through ledges" : "Particles cannot use sprite sheets";
            in.missing = "The knight needs to pass up through the ledges of the crypt.";
            in.workaround = "A script switches the collider off while the knight rises.";
            if (i == 0 && withShare) in.share = Json::parse(shareText);
            REQUIRE(add_feedback_entry(doc, in).ok());
        }
        REQUIRE(save_feedback(file, doc).ok());
        AiCommandOptions opt;
        opt.loadConfig = [this] { return Result<AiConfig>(cfg); };
        opt.projectDir = [this] { return dir.str(); };
        opt.providerFactory = [this](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> {
            ++factoryCalls;
            return std::static_pointer_cast<ChatProvider>(provider);
        };
        register_ai_commands(registry, opt);
    }
    Json entry(const std::string& id = "FB-0001") {
        auto doc = load_feedback(file);
        REQUIRE(doc.ok());
        for (const auto& e : (*doc)["entries"])
            if (e["id"] == id) return e;
        return Json();
    }
};

const char* kAllOk = R"({"real":{"ok":true,"why":""},"aboutEngine":{"ok":true,"why":""},"notPossibleYet":{"ok":true,"why":"","use":""},"share":null,"fix":""})";

}  // namespace

TEST_CASE("ai.review_feedback: a good share text passes, the entry becomes reviewed, nothing else changes") {
    Fixture f;
    f.provider->script = {text_response(kAllOk)};
    auto r = f.registry.call("ai.review_feedback", Json::object({{"id", "FB-0001"}}));
    REQUIRE(r.ok);
    CHECK(r.result["pass"] == true);
    CHECK(r.result["reviewed"] == true);
    CHECK(r.result["rewritten"] == false);
    CHECK(r.result["role"] == "fast");  // the cheapest role
    CHECK(f.entry()["reviewed"] == true);
    CHECK(f.entry()["share"] == Json::parse(kGoodShare));
    CHECK_FALSE(f.entry().contains("shared"));  // reviewing queues nothing and sends nothing
    CHECK_FALSE(f.entry("FB-0002").contains("reviewed"));

    // The model was asked with the share text and the engine's commands, with no tools.
    REQUIRE(f.provider->requests.size() == 1);
    const ChatRequest& req = f.provider->requests[0];
    CHECK(req.tools.empty());
    REQUIRE(req.messages.size() == 1);
    CHECK(req.messages[0].text.find("No one-way platforms") != std::string::npos);
    CHECK(req.messages[0].text.find("scene: list_entities") != std::string::npos);
    CHECK(req.system.find("notPossibleYet") != std::string::npos);
}

TEST_CASE("ai.review_feedback: a rewrite of share is stored when the model gives a better one, and the model's JSON may be wrapped in prose") {
    Fixture f(R"({"title":"Knight cannot jump through ledges","missing":"The knight needs to pass up through ledges in the crypt level."})");
    const std::string reply =
        "Here is my verdict:\n```json\n"
        R"({"real":{"ok":true},"aboutEngine":{"ok":true},"notPossibleYet":{"ok":true},)"
        R"("share":{"title":"No one-way platforms","missing":"Collider2D has no oneWay option, so a body cannot pass up through a platform.","suggestion":"Add Collider2D.oneWay (bool)."},"fix":""})"
        "\n```";
    f.provider->script = {text_response(reply)};
    auto r = f.registry.call("ai.review_feedback", Json::object({{"id", "FB-0001"}}));
    REQUIRE(r.ok);
    CHECK(r.result["pass"] == true);
    CHECK(r.result["rewritten"] == true);
    CHECK(r.result["share"]["title"] == "No one-way platforms");
    Json e = f.entry();
    CHECK(e["share"]["title"] == "No one-way platforms");
    CHECK(e["share"]["suggestion"] == "Add Collider2D.oneWay (bool).");
    CHECK(e["reviewed"] == true);
    // The author's own words are still there.
    CHECK(e["title"] == "Knight cannot jump through ledges");
}

TEST_CASE("ai.review_feedback: a failed check explains why and suggests a fix, and changes nothing") {
    Fixture f;
    f.provider->script = {text_response(
        R"({"real":{"ok":true},"aboutEngine":{"ok":true},"notPossibleYet":{"ok":false,"why":"Collider2D.layer and the collision matrix already do this.","use":"physics.set_layer_matrix"},)"
        R"("share":null,"fix":"Use the layer matrix instead of reporting a gap."})")};
    auto r = f.registry.call("ai.review_feedback", Json::object({{"id", "FB-0001"}}));
    REQUIRE(r.ok);
    CHECK(r.result["pass"] == false);
    CHECK(r.result["reviewed"] == false);
    REQUIRE(r.result["reasons"].size() == 1);
    const std::string reason = r.result["reasons"][0].get<std::string>();
    CHECK(reason.find("Already possible") != std::string::npos);
    CHECK(reason.find("physics.set_layer_matrix") != std::string::npos);
    CHECK(r.result["fix"] == "Use the layer matrix instead of reporting a gap.");
    CHECK(r.result["checks"]["notPossibleYet"]["ok"] == false);
    CHECK_FALSE(f.entry().contains("reviewed"));
    CHECK(f.entry()["share"] == Json::parse(kGoodShare));
}

TEST_CASE("ai.review_feedback: not real and not about the engine are separate reasons; a missing check counts as failed") {
    Fixture f;
    f.provider->script = {text_response(R"({"real":{"ok":false,"why":"The docs list Collider2D.oneWay."},"notPossibleYet":{"ok":true}})")};
    auto r = f.registry.call("ai.review_feedback", Json::object({{"id", "FB-0001"}}));
    REQUIRE(r.ok);
    CHECK(r.result["pass"] == false);
    CHECK(r.result["reasons"].size() == 2);  // not real, and the model said nothing about aboutEngine
    CHECK(r.result["fix"].get<std::string>().size() > 20);  // a fix is always given
}

TEST_CASE("ai.review_feedback: the sanitizer decides too, whatever the model says") {
    Fixture f(R"({"title":"see 'Dungeon of Ash'","missing":"'the knight' must pass up through 'crypt ledges' in 'level 3'"})");
    f.provider->script = {text_response(kAllOk)};
    auto r = f.registry.call("ai.review_feedback", Json::object({{"id", "FB-0001"}}));
    REQUIRE(r.ok);
    CHECK(r.result["pass"] == false);
    CHECK(r.result["checks"]["sanitizer"]["ok"] == false);
    CHECK_FALSE(f.entry().contains("reviewed"));
}

TEST_CASE("ai.review_feedback: a rewrite the sanitizer refuses is not stored") {
    Fixture f;
    f.provider->script = {text_response(
        R"({"real":{"ok":true},"aboutEngine":{"ok":true},"notPossibleYet":{"ok":true},"share":{"title":"see 'Dungeon of Ash'","missing":"'the knight' passes 'crypt ledges' in 'level 3'"}})")};
    auto r = f.registry.call("ai.review_feedback", Json::object({{"id", "FB-0001"}}));
    REQUIRE(r.ok);
    CHECK(r.result["rewritten"] == false);
    CHECK(f.entry()["share"] == Json::parse(kGoodShare));  // the original stands (it passes)
    CHECK(r.result["pass"] == true);
    CHECK(r.result["reasons"].size() == 1);                 // and the refused rewrite is explained
}

TEST_CASE("ai.review_feedback: errors teach: unknown id (did you mean), no share, no JSON, no model") {
    {
        Fixture f;
        auto r = f.registry.call("ai.review_feedback", Json::object({{"id", "FB-001"}}));
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "not_found");
        CHECK(r.error["message"].get<std::string>().find("FB-0001") != std::string::npos);
        CHECK(f.factoryCalls == 0);  // no model call for an entry that is not there
    }
    {
        Fixture f;
        auto r = f.registry.call("ai.review_feedback", Json::object({{"id", "FB-0002"}}));
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "no_share");
        CHECK(r.error["hint"].get<std::string>().find("share") != std::string::npos);
        CHECK(f.factoryCalls == 0);
    }
    {
        Fixture f;
        f.provider->script = {text_response("I think it is fine.")};
        auto r = f.registry.call("ai.review_feedback", Json::object({{"id", "FB-0001"}}));
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "review_failed");
        CHECK_FALSE(f.entry().contains("reviewed"));
    }
    {
        Fixture f;  // the fake provider has no script: its error reaches the caller
        auto r = f.registry.call("ai.review_feedback", Json::object({{"id", "FB-0001"}}));
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "review_failed");
    }
}

TEST_CASE("ai.review_feedback: the fast role answers, the orchestrator when fast is off; the sharing mode is never touched") {
    Fixture f;
    f.cfg.roles["fast"].enabled = false;
    f.provider->script = {text_response(kAllOk)};
    ShareEnv env;
    env.env = [&](const std::string& n) { return n == "FACTORIA_AI_CONFIG" ? (f.dir.path / "ai.json").string() : std::string(); };
    env.transport = [](const fa::HttpRequest&) -> fa::HttpResponse {
        FAIL("ai.review_feedback must not reach the network");
        return {};
    };
    ScopedShareEnv scoped(env);
    auto r = f.registry.call("ai.review_feedback", Json::object({{"id", "FB-0001"}}));
    REQUIRE(r.ok);
    CHECK(r.result["role"] == "orchestrator");
    CHECK(load_share_settings(share_env()).mode == ShareMode::Unset);
    CHECK(load_outbox(share_env()).items.empty());
}

TEST_CASE("ai.review_feedback is a tool of the agent, the other ai.* commands are not") {
    CHECK_FALSE(is_agent_tool_excluded("ai.review_feedback"));
    CHECK(is_agent_tool_excluded("ai.run"));
    CHECK(is_agent_tool_excluded("ai.review"));
}
