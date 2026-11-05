// assets.review: the vision review the AI can call on its own pictures (fake model: nothing reaches a network).
#include <doctest.h>

#include "fa/ai/commands.h"
#include "fa/ai/text_model.h"
#include "fa/core/image.h"
#include "test_common.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;

namespace {

void write_png(const std::filesystem::path& p, int w, int h, std::uint8_t r) {
    Image img;
    img.width = w;
    img.height = h;
    img.rgba.assign(std::size_t(w) * h * 4, 255);
    for (std::size_t i = 0; i < img.rgba.size(); i += 4) img.rgba[i] = r;
    const auto png = encode_png(img);
    std::filesystem::create_directories(p.parent_path());
    std::ofstream(p, std::ios::binary).write(reinterpret_cast<const char*>(png.data()), std::streamsize(png.size()));
}

const char* kGood = R"({"verdict":"fix","summary":"The outline is thicker than the references.","fixes":[{"what":"Thin the outline to 1 px","where":"assets/knight.png, the whole silhouette","command":"assets.generate_image {\"path\":\"assets/knight.png\",\"overwrite\":true}"},{"what":"Use the palette","where":"assets/knight.png","command":"style.palette in assets.json"},{"what":"Do magic","where":"x","command":"assets.make_it_pretty {}"}]})";

struct Fixture {
    TempDir dir;
    CommandRegistry registry = make_registry();
    std::shared_ptr<FakeProvider> provider = std::make_shared<FakeProvider>();
    AiConfig cfg = default_config();
    int checkCalls = 0;
    std::string checkVerdict = "warn";
    Json checkArgs;

    Fixture() {
        write_png(dir.path / "assets/knight.png", 16, 16, 40);
        write_png(dir.path / "assets/orc.png", 16, 16, 90);
        write_png(dir.path / "art/ref.png", 16, 16, 200);
        write_png(dir.path / ".factoria/screenshots/check.png", 32, 32, 10);
        std::ofstream(dir.path / "assets.json") << R"({"style":{"prompt":"chunky pixel knights","references":["art/ref.png","art/missing.png"],"outline":{"color":"#000000","width":1}}})";
        CommandInfo check;
        check.name = "assets.check_art";
        check.category = "assets";
        check.summary = "fake";
        check.inputSchema = Json::parse(R"({"type":"object","properties":{"paths":{"type":"array"}}})");
        registry.add(check, [this](const Json& args) {
            ++checkCalls;
            checkArgs = args;
            return Json::object({{"verdict", checkVerdict},
                                 {"counts", Json::object({{"ok", 3}, {"warn", 1}, {"fail", checkVerdict == "fail" ? 1 : 0}})},
                                 {"assets", Json::array({Json::object({{"path", "assets/knight.png"}, {"verdict", checkVerdict},
                                     {"rules", Json::array({Json::object({{"rule", "outline.width"}, {"value", 2.4}, {"threshold", 1.0}, {"verdict", "warn"},
                                                                          {"hint", "Set the outline to 1 px"}})})}})})},
                                 {"$image", Json::object({{"path", (dir.path / ".factoria/screenshots/check.png").string()}, {"mimeType", "image/png"}})}});
        });
        AiCommandOptions opt;
        opt.loadConfig = [this] { return Result<AiConfig>(cfg); };
        opt.projectDir = [this] { return dir.str(); };
        opt.providerFactory = [this](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> {
            return std::static_pointer_cast<ChatProvider>(provider);
        };
        register_ai_commands(registry, opt);
    }
};

}  // namespace

TEST_CASE("assets.review: the model gets the check's numbers, the style rules and the pictures; the reply is parsed") {
    Fixture f;
    f.provider->script = {text_response(std::string("Here you go:\n```json\n") + kGood + "\n```")};
    auto r = f.registry.call("assets.review", Json::object({{"path", "assets/knight.png"}, {"focus", "does the outline match?"}}));
    INFO(r.error.dump());
    REQUIRE(r.ok);
    CHECK(f.checkCalls == 1);
    CHECK(f.checkArgs["paths"][0] == "assets/knight.png");

    REQUIRE(f.provider->requests.size() == 1);
    const ChatRequest& req = f.provider->requests[0];
    CHECK(req.tools.empty());
    REQUIRE(req.messages.size() == 1);
    const Message& m = req.messages[0];
    // grounding: the check's numbers, the style rules, the focus
    CHECK(m.text.find("outline.width") != std::string::npos);
    CHECK(m.text.find("2.4") != std::string::npos);
    CHECK(m.text.find("Set the outline to 1 px") != std::string::npos);
    CHECK(m.text.find("chunky pixel knights") != std::string::npos);
    CHECK(m.text.find("art/ref.png") != std::string::npos);
    CHECK(m.text.find("does the outline match?") != std::string::npos);
    // images: the reference that exists, the picture, the annotated picture (the missing reference is a warning)
    CHECK(m.images.size() == 3);
    for (const auto& img : m.images) {
        CHECK(img.mediaType == "image/png");
        CHECK_FALSE(img.base64.empty());
    }
    CHECK(req.system.find("fixes") != std::string::npos);

    CHECK(r.result["verdict"] == "fix");
    CHECK(r.result["summary"] == "The outline is thicker than the references.");
    REQUIRE(r.result["fixes"].size() == 3);
    CHECK(r.result["fixes"][0]["what"] == "Thin the outline to 1 px");
    CHECK(r.result["fixes"][0]["where"].get<std::string>().find("knight") != std::string::npos);
    CHECK(r.result["checkArt"]["verdict"] == "warn");
    CHECK(r.result["role"] == "fast");
    CHECK(r.result["model"].is_string());
    CHECK(r.result["nextSteps"].is_array());
    // warnings: the missing reference, and the fix that names a command this engine does not have; the real ones are not flagged
    std::string warnings = r.result["warnings"].dump();
    CHECK(warnings.find("art/missing.png") != std::string::npos);
    CHECK(warnings.find("assets.make_it_pretty") != std::string::npos);
    CHECK(warnings.find("style.palette") == std::string::npos);
    CHECK(warnings.find("assets.generate_image {") == std::string::npos);
}

TEST_CASE("assets.review: several pictures, and a `good` verdict is not accepted over a check that fails") {
    Fixture f;
    f.checkVerdict = "fail";
    f.provider->script = {text_response(R"({"verdict":"good","summary":"Fine.","fixes":[]})")};
    auto r = f.registry.call("assets.review", Json::object({{"paths", Json::array({"assets/knight.png", "assets/orc.png"})}}));
    REQUIRE(r.ok);
    CHECK(f.provider->requests[0].messages[0].images.size() == 4);  // reference, two pictures, annotated
    CHECK(r.result["verdict"] == "fix");
    CHECK(r.result["warnings"].dump().find("fail") != std::string::npos);
}

TEST_CASE("assets.review: a malformed reply gives a teaching error") {
    Fixture f;
    f.provider->script = {text_response("It looks nice to me!")};
    auto r = f.registry.call("assets.review", Json::object({{"path", "assets/knight.png"}}));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "review_failed");
    CHECK(r.error["message"].get<std::string>().find("verdict") != std::string::npos);
    CHECK_FALSE(r.error["hint"].get<std::string>().empty());

    Fixture g;
    g.provider->script = {text_response(R"({"verdict":"amazing","fixes":[]})")};
    auto r2 = g.registry.call("assets.review", Json::object({{"path", "assets/knight.png"}}));
    REQUIRE_FALSE(r2.ok);
    CHECK(r2.error["code"] == "review_failed");
}

TEST_CASE("assets.review: no provider or no key is a teaching error before the check runs; no picture, too many pictures") {
    {
        Fixture f;
        f.cfg.roles["fast"].provider = "nobody";
        auto r = f.registry.call("assets.review", Json::object({{"path", "assets/knight.png"}}));
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "no_model");
        CHECK(r.error["message"].get<std::string>().find("nobody") != std::string::npos);
        CHECK(r.error["hint"].get<std::string>().find("assets.check_art") != std::string::npos);  // carry on with the numbers
        CHECK(f.checkCalls == 0);
    }
    {
        // No factory: the real provider needs a key, and the environment has none.
        Fixture f;
        AiCommandOptions opt;
        opt.loadConfig = [&] { return Result<AiConfig>(f.cfg); };
        opt.projectDir = [&] { return f.dir.str(); };
        opt.runtime.env = [](const std::string&) { return std::string(); };
        opt.runtime.antToken = [] { return std::string(); };  // an `ant` on the PATH (Apache Ant on CI runners) gives no token
        CommandRegistry reg = make_registry();
        register_ai_commands(reg, opt);
        f.cfg.roles["fast"].provider = "anthropic";
        auto r = reg.call("assets.review", Json::object({{"path", "assets/knight.png"}}));
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "no_model");
        CHECK(r.error["message"].get<std::string>().find("API key") != std::string::npos);
    }
    Fixture f;
    CHECK_FALSE(f.registry.call("assets.review", Json::object()).ok);
    auto many = f.registry.call("assets.review", Json::object({{"paths", Json::array({"a.png", "b.png", "c.png", "d.png", "e.png"})}}));
    REQUIRE_FALSE(many.ok);
    CHECK(many.error["code"] == "invalid_arguments");
    auto gone = f.registry.call("assets.review", Json::object({{"path", "assets/nope.png"}}));
    CHECK_FALSE(gone.ok);
}

TEST_CASE("make_vision_model: the pictures reach the provider on the user message; an asset-only provider is refused") {
    AiConfig cfg = default_config();
    auto provider = std::make_shared<FakeProvider>();
    provider->script = {text_response("ok")};
    TextModelOptions mo;
    mo.providerFactory = [&](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> { return std::static_pointer_cast<ChatProvider>(provider); };
    auto model = make_vision_model(cfg, mo);
    REQUIRE(model.ok());
    auto a = (*model)("sys", "look", {{"image/png", "QUJD"}});
    REQUIRE(a.ok());
    CHECK(*a == "ok");
    REQUIRE(provider->requests.size() == 1);
    CHECK(provider->requests[0].system == "sys");
    REQUIRE(provider->requests[0].messages[0].images.size() == 1);
    CHECK(provider->requests[0].messages[0].images[0].base64 == "QUJD");

    // the text model is the same thing with no pictures
    provider->script = {text_response("ok")};
    provider->calls = 0;
    auto text = make_text_model(cfg, mo);
    REQUIRE(text.ok());
    REQUIRE((*text)("s", "u").ok());
    CHECK(provider->requests.back().messages[0].images.empty());

    // a provider that rejects the pictures: the error says to pick a vision model
    provider->script.clear();
    class Rejecting : public ChatProvider {
    public:
        std::string name() const override { return "rejecting"; }
        Result<ChatResponse> chat(const ChatRequest&, const ChatHooks&, const CancelFlag*) override {
            return make_error("HTTP 400: this model does not support image input");
        }
    };
    mo.providerFactory = [](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> { return std::shared_ptr<ChatProvider>(std::make_shared<Rejecting>()); };
    auto rej = make_vision_model(cfg, mo);
    REQUIRE(rej.ok());
    auto err = (*rej)("s", "u", {{"image/png", "QUJD"}});
    REQUIRE_FALSE(err.ok());
    CHECK(err.error().hint.find("vision model") != std::string::npos);

    // asset-only providers
    cfg.providers["fakeassets"] = ProviderConfig{};
    cfg.providers["fakeassets"].name = "fakeassets";
    cfg.providers["fakeassets"].kind = ProviderKind::Fake;
    cfg.roles["fast"].provider = "fakeassets";
    TextModelOptions plain;
    auto refused = make_vision_model(cfg, plain);
    REQUIRE_FALSE(refused.ok());
    CHECK(refused.error().message.find("only makes assets") != std::string::npos);
}

TEST_CASE("assets.review is a tool of the agent") {
    CHECK_FALSE(is_agent_tool_excluded("assets.review"));
}
