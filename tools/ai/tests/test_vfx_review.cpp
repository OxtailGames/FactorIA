// vfx.review: the vision review the AI can call on its own effect (fake model and fake engine commands: nothing reaches a network or a GPU).
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

const char* kReply = R"({"verdict":"fix","summary":"It reads, but the smoke lingers.","checklist":[{"item":"readability","grade":"ok","note":"clear silhouette"},{"item":"timing","grade":"weak","note":"the tail lasts 1.2 s"}],"fixes":[{"what":"Shorten the smoke","where":"/parts/0/emitter/lifetime","command":"vfx.edit {\"path\":\"assets/vfx/hit.vfx.json\",\"op\":\"set\",\"pointer\":\"/parts/0/emitter/lifetime\",\"value\":0.5}"},{"what":"Do magic","where":"x","command":"vfx.make_it_pretty {}"}]})";

struct Fixture {
    TempDir dir;
    CommandRegistry registry = make_registry();
    std::shared_ptr<FakeProvider> provider = std::make_shared<FakeProvider>();
    AiConfig cfg = default_config();
    int budgetCalls = 0, filmCalls = 0;
    bool findings = false;
    bool filmFails = false;
    bool temporary = true;
    Json budgetArgs, filmArgs;

    Fixture() {
        std::filesystem::create_directories(dir.path / "assets/vfx");
        std::ofstream(dir.path / "assets/vfx/hit.vfx.json") << R"({"format":"factoria.vfx/1","parts":[{"type":"emitter","name":"smoke","emitter":{"burst":8,"lifetime":1.2}}]})";
        write_png(dir.path / ".factoria/screenshots/strip.png", 64, 32, 90);
        CommandInfo budget;
        budget.name = "vfx.budget";
        budget.category = "game";
        budget.summary = "fake";
        budget.inputSchema = Json::parse(R"({"type":"object","properties":{"path":{"type":"string"},"preset":{"type":"string"}}})");
        registry.add(budget, [this](const Json& args) {
            ++budgetCalls;
            budgetArgs = args;
            Json f = findings ? Json::array({Json::object({{"kind", "particles"}, {"pointer", "/parts/0/emitter/maxParticles"}, {"message", "900 particles"},
                                                           {"hint", "Lower it"}, {"fix", Json::object({{"command", "vfx.edit"}})}})})
                              : Json::array();
            return Json::object({{"path", "assets/vfx/hit.vfx.json"}, {"preset", "phone"}, {"peakParticles", findings ? 900 : 8}, {"peakOverdraw", 0.25},
                                 {"timeline", Json::array({Json::object({{"t", 0.0}})})}, {"limits", Json::object()}, {"findings", f}, {"ok", !findings}});
        });
        CommandInfo film;
        film.name = "vfx.filmstrip";
        film.category = "game";
        film.summary = "fake";
        film.inputSchema = Json::parse(R"({"type":"object","properties":{"effect":{"type":"string"},"position":{"type":"array"},"frames":{"type":"integer"},"path":{"type":"string"}}})");
        registry.add(film, [this](const Json& args) -> Json {
            ++filmCalls;
            filmArgs = args;
            if (filmFails) throw CommandError("unavailable", "No renderer: the engine runs with graphics=false.", "vfx.filmstrip needs graphics.");
            Json image = Json::object({{"path", (dir.path / ".factoria/screenshots/strip.png").string()}, {"mimeType", "image/png"}});
            if (temporary) image["temporary"] = true;
            return Json::object({{"columns", 4}, {"rows", 3}, {"tileWidth", 16}, {"tileHeight", 16}, {"zoom", 1.0}, {"frames", Json::array({Json::object({{"index", 0}, {"t", 0.017}})})},
                                 {"$image", image}});
        });
        CommandInfo edit;
        edit.name = "vfx.edit";
        edit.category = "game";
        edit.summary = "fake";
        edit.inputSchema = Json::parse(R"({"type":"object"})");
        registry.add(edit, [](const Json&) { return Json::object(); });
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

TEST_CASE("vfx.review: the model gets the document, the budget numbers and the filmstrip; the reply is parsed") {
    Fixture f;
    f.provider->script = {text_response(std::string("Here:\n```json\n") + kReply + "\n```")};
    auto r = f.registry.call("vfx.review", Json::parse(R"({"effect":"assets/vfx/hit.vfx.json","position":[10,20],"frames":8,"focus":"does it read on the dark floor?"})"));
    INFO(r.error.dump());
    REQUIRE(r.ok);
    CHECK(f.budgetCalls == 1);
    CHECK(f.filmCalls == 1);
    CHECK(f.budgetArgs["path"] == "assets/vfx/hit.vfx.json");
    CHECK(f.filmArgs["effect"] == "assets/vfx/hit.vfx.json");
    CHECK(f.filmArgs["frames"] == 8);
    CHECK(f.filmArgs["position"][0] == 10);

    REQUIRE(f.provider->requests.size() == 1);
    const ChatRequest& req = f.provider->requests[0];
    CHECK(req.tools.empty());
    REQUIRE(req.messages.size() == 1);
    const Message& m = req.messages[0];
    CHECK(m.text.find("\"lifetime\":1.2") != std::string::npos);  // the document
    CHECK(m.text.find("peakParticles") != std::string::npos);      // the numbers
    CHECK(m.text.find("does it read on the dark floor?") != std::string::npos);
    REQUIRE(m.images.size() == 1);
    CHECK(m.images[0].mediaType == "image/png");
    for (const char* word : {"readability", "timing", "palette", "overdraw", "vfx.edit"}) CHECK(req.system.find(word) != std::string::npos);

    CHECK(r.result["verdict"] == "fix");
    CHECK(r.result["summary"] == "It reads, but the smoke lingers.");
    CHECK(r.result["checklist"].size() == 2);
    CHECK(r.result["checklist"][1]["grade"] == "weak");
    REQUIRE(r.result["fixes"].size() == 2);
    CHECK(r.result["fixes"][0]["where"] == "/parts/0/emitter/lifetime");
    CHECK(r.result["budget"]["peakParticles"] == 8);
    CHECK_FALSE(r.result["budget"].contains("timeline"));
    CHECK(r.result["filmstrip"]["columns"] == 4);
    CHECK(r.result["role"] == "fast");
    // the invented command is a warning, the real one is not
    const std::string warnings = r.result["warnings"].dump();
    CHECK(warnings.find("vfx.make_it_pretty") != std::string::npos);
    CHECK(warnings.find("vfx.edit {") == std::string::npos);
    // a temporary picture does not stay behind
    CHECK_FALSE(std::filesystem::exists(f.dir.path / ".factoria/screenshots/strip.png"));
}

TEST_CASE("vfx.review: a kept picture stays, and `good` is not accepted over a budget finding") {
    Fixture f;
    f.findings = true;
    f.temporary = false;
    f.provider->script = {text_response(R"({"verdict":"good","summary":"Fine.","fixes":[]})")};
    auto r = f.registry.call("vfx.review", Json::parse(R"({"effect":"assets/vfx/hit.vfx.json","picturePath":"out/strip.png"})"));
    REQUIRE(r.ok);
    CHECK(f.filmArgs["path"] == "out/strip.png");
    CHECK(r.result["verdict"] == "fix");
    CHECK(r.result["warnings"].dump().find("budget") != std::string::npos);
    CHECK(std::filesystem::exists(f.dir.path / ".factoria/screenshots/strip.png"));
}

TEST_CASE("vfx.review: errors teach and name what works without") {
    {
        Fixture f;
        f.cfg.roles["fast"].provider = "nobody";
        auto r = f.registry.call("vfx.review", Json::object({{"effect", "assets/vfx/hit.vfx.json"}}));
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "no_model");
        CHECK(r.error["hint"].get<std::string>().find("vfx.budget") != std::string::npos);
        CHECK(f.budgetCalls == 0);
        CHECK(f.filmCalls == 0);
    }
    {
        Fixture f;
        f.filmFails = true;
        auto r = f.registry.call("vfx.review", Json::object({{"effect", "assets/vfx/hit.vfx.json"}}));
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "film_failed");
        CHECK(r.error["message"].get<std::string>().find("graphics") != std::string::npos);
        CHECK(r.error["hint"].get<std::string>().find("vfx.budget") != std::string::npos);
        CHECK(f.provider->requests.empty());
    }
    {
        Fixture f;
        f.provider->script = {text_response("Looks nice!")};
        auto r = f.registry.call("vfx.review", Json::object({{"effect", "assets/vfx/hit.vfx.json"}}));
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "review_failed");
        CHECK_FALSE(r.error["hint"].get<std::string>().empty());
        CHECK_FALSE(std::filesystem::exists(f.dir.path / ".factoria/screenshots/strip.png"));  // cleaned up on the error path too
    }
    Fixture f;
    CHECK_FALSE(f.registry.call("vfx.review", Json::object()).ok);
}
