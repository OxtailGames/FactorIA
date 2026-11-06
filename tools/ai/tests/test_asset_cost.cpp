// What paid asset generation costs and who says yes (docs/AI_COSTS.md, "Asset generation"): the price tables of the providers
// (assetPricing), the estimate of a call, the limits per run and per day (the day's total is shared between processes through a file under
// the user folder's lock), the approval above askAboveUsd, and the estimate in every result. A "fake" provider with a price table of its own
// stands for a paid one, so nothing here touches the network or the real ~/.factoria.
#include <atomic>
#include <ctime>
#include <functional>
#include <fstream>
#include <thread>

#include "asset_test.h"
#include "fa/ai/asset_cost.h"
#include "fa/ai/session.h"
#include "fa/tooling/asset_import.h"
#include "fa/tooling/feedback_share.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;
namespace fsys = std::filesystem;

namespace {

bool has(const std::string& text, const std::string& part) { return text.find(part) != std::string::npos; }

// The user folder in a temp dir (never the real ~/.factoria) and a fixed clock, for the life of the object.
struct Home {
    TempDir dir;
    ScopedShareEnv scoped;
    static ShareEnv make(const std::string& home, double waitSec, std::function<std::int64_t()> now = {}) {
        ShareEnv env;
        env.env = [home](const std::string& name) -> std::string { return name == "HOME" || name == "USERPROFILE" || name == "APPDATA" ? home : ""; };
        env.now = std::move(now);  // empty = the system clock
        env.lockWaitSec = waitSec;
        env.lockStaleSec = 600.0;
        return env;
    }
    explicit Home(double waitSec = 2.0) : scoped(make(dir.str(), waitSec)) {}
    fsys::path spend_file() const { return fsys::path(asset_spend_path()); }
    // Another program holds the lock of the user folder.
    void hold_lock() const {
        fsys::create_directories(fsys::path(share_env().config_dir()));
        std::ofstream(fsys::path(share_env().config_dir()) / kFeedbackShareLockFile, std::ios::binary) << "alive";
    }
    void release_lock() const { fsys::remove(fsys::path(share_env().config_dir()) / kFeedbackShareLockFile); }
};

// A fake provider "paid" with a price table: 0.30 a picture, 0.10 a second of sound, 0.50 per 1000 characters of voice, 1.00 a model.
Json paid_config(const std::string& limits = "{}") {
    return Json::parse(R"({"providers":{"paid":{"type":"fake","assetPricing":{"image":0.30,"soundPerSecond":0.10,"musicPerSecond":0.01,
                "voicePer1000Chars":0.50,"model3d":1.00,"checked":"2026-11-06","source":"https://example.com/prices"}}},
               "assets":{"image":{"provider":"paid"},"sound":{"provider":"paid"},"music":{"provider":"paid"},
                         "voice":{"provider":"paid"},"model3d":{"provider":"paid"}},
               "limits":)" + limits + "}");
}

Json image_args(const std::string& path) { return {{"prompt", "a gem"}, {"path", path}, {"width", 16}, {"height", 16}}; }

}  // namespace

// ------------------------------------------------------------------------------------------------------------------ the price tables

TEST_CASE("assetPricing: the table parses, a number is the price of any size, and it round trips through config_to_json") {
    const AiConfig cfg = config_from(R"({"providers":{"p":{"type":"fake","assetPricing":{
        "image":{"1024x1024":{"low":0.011,"high":0.167},"1536x1024":0.25},"voicePer1000Chars":0.2,"soundPerSecond":0.05,
        "checked":"2026-11-06","source":"https://example.com","note":"a note","unverified":["voice"]}}}})");
    const ProviderConfig& p = *cfg.provider("p");
    CHECK(p.assetPricing.image.at("1024x1024").at("high") == doctest::Approx(0.167));
    CHECK(p.assetPricing.image.at("1536x1024").at("default") == doctest::Approx(0.25));
    CHECK(*p.assetPricing.voicePer1000Chars == doctest::Approx(0.2));
    CHECK_FALSE(p.assetPricing.model3d.has_value());
    CHECK(p.assetPricing.checked == "2026-11-06");
    REQUIRE(p.assetPricing.unverified.size() == 1);
    CHECK(p.assetPricing.unverified[0] == "voice");

    const Json out = config_to_json(cfg);
    const Json& pricing = out["providers"]["p"]["assetPricing"];
    CHECK(pricing["image"]["1024x1024"]["high"] == doctest::Approx(0.167));
    CHECK(pricing["voicePer1000Chars"] == doctest::Approx(0.2));
    const AiConfig again = config_from(out);
    CHECK(config_to_json(again) == out);
}

TEST_CASE("assetPricing: a wrong table is an error with the JSON pointer") {
    auto cfg = parse_config(Json::parse(R"({"providers":{"p":{"type":"fake","assetPricing":{"soundPerSecond":-1}}}})"), "test");
    REQUIRE_FALSE(cfg.ok());
    CHECK(has(cfg.error().message, "/providers/p/assetPricing/soundPerSecond"));
    auto typo = parse_config(Json::parse(R"({"providers":{"p":{"type":"fake","assetPricing":{"soundPerSec":0.1}}}})"), "test");
    REQUIRE_FALSE(typo.ok());
    CHECK(has(typo.error().to_string(), "soundPerSecond"));  // did you mean
}

TEST_CASE("assetPricing: the built-in presets carry a price list with the day it was checked and where it is published") {
    const AiConfig cfg = default_config();
    for (const char* name : {"openai", "elevenlabs", "meshy"}) {
        INFO(name);
        const ProviderConfig* p = cfg.provider(name);
        REQUIRE(p);
        CHECK_FALSE(p->assetPricing.empty());
        CHECK_FALSE(p->assetPricing.checked.empty());
        CHECK(p->assetPricing.source.rfind("https://", 0) == 0);
    }
    // a figure the engine could not read off a published price is marked, not presented as fact
    CHECK_FALSE(cfg.provider("meshy")->assetPricing.unverified.empty());
    CHECK(cfg.provider("fake")->assetPricing.empty());
    CHECK(cfg.limits.askAboveUsd == doctest::Approx(0.50));
    CHECK(cfg.limits.maxAssetCostPerRunUsd == 0);
    CHECK(cfg.limits.maxAssetCostPerDayUsd == 0);
}

TEST_CASE("assetPricing: a provider of ai.json that sets only its pricing keeps the built-in provider's other fields") {
    const AiConfig cfg = config_from(R"({"providers":{"openai":{"assetPricing":{"image":{"default":0.5}}}}})");
    const ProviderConfig* p = cfg.provider("openai");
    REQUIRE(p);
    CHECK(p->kind == ProviderKind::OpenAICompatible);
    CHECK(p->assetPricing.image.at("default").at("default") == doctest::Approx(0.5));  // replaced as a whole
}

// ---------------------------------------------------------------------------------------------------------------------- the estimate

TEST_CASE("estimate_asset_cost: by kind, with the count of results, rounded") {
    const AiConfig cfg = config_from(paid_config());
    const ProviderConfig& paid = *cfg.provider("paid");
    AssetRequest image;
    image.kind = MediaKind::Image;
    image.width = image.height = 64;
    AssetEstimate e = estimate_asset_cost(paid, image);
    REQUIRE(e.usd.has_value());
    CHECK(*e.usd == doctest::Approx(0.30));
    CHECK_FALSE(e.free);
    CHECK(e.checked == "2026-11-06");
    CHECK(e.source == "https://example.com/prices");
    // a count: M66.3 asks for several candidates
    CHECK(*estimate_asset_cost(paid, image, 4).usd == doctest::Approx(1.20));
    CHECK(estimate_asset_cost(paid, image, 4).count == 4);
    CHECK(has(estimate_asset_cost(paid, image, 4).basis, "4 x"));

    AssetRequest voice;
    voice.kind = MediaKind::Voice;
    voice.prompt = std::string(2000, 'a');
    CHECK(*estimate_asset_cost(paid, voice).usd == doctest::Approx(1.00));
    voice.prompt = "ñ";  // a character is not a byte
    CHECK(*estimate_asset_cost(paid, voice).usd == doctest::Approx(0.0005));

    AssetRequest sound;
    sound.kind = MediaKind::Sound;
    sound.seconds = 3;
    CHECK(*estimate_asset_cost(paid, sound).usd == doctest::Approx(0.30));
    sound.seconds = 0;  // the provider chooses: 10 s are assumed and the basis says so
    e = estimate_asset_cost(paid, sound);
    CHECK(*e.usd == doctest::Approx(1.0));
    CHECK(has(e.basis, "assumed"));

    AssetRequest model;
    model.kind = MediaKind::Model3d;
    CHECK(*estimate_asset_cost(paid, model).usd == doctest::Approx(1.00));
}

TEST_CASE("estimate_asset_cost: OpenAI is priced at the size it draws, the quality asked for, and an unknown quality never lowers the price") {
    const AiConfig cfg = default_config();
    const ProviderConfig& openai = *cfg.provider("openai");
    AssetRequest r;
    r.kind = MediaKind::Image;
    r.width = r.height = 32;  // drawn at 1024x1024 whatever the file ends up
    const double square = *estimate_asset_cost(openai, r).usd;
    r.width = 300;
    r.height = 100;
    const double wide = *estimate_asset_cost(openai, r).usd;
    CHECK(wide > square);
    r.width = r.height = 32;
    r.quality = "low";
    const double low = *estimate_asset_cost(openai, r).usd;
    CHECK(low < square);
    r.quality = "bogus";
    CHECK(*estimate_asset_cost(openai, r).usd >= square);
}

TEST_CASE("estimate_asset_cost: the fake provider and local programs are free, an unknown price is not zero") {
    const AiConfig cfg = config_from(R"({"providers":{"mytool":{"type":"asset-command","command":"python","argv":["gen.py","{output}"]},
        "remote":{"type":"openai-compatible","baseUrl":"https://api.example.com/v1"},
        "local":{"type":"openai-compatible","baseUrl":"http://localhost:1234/v1"}}})");
    AssetRequest r;
    r.kind = MediaKind::Image;
    r.width = r.height = 64;
    AssetEstimate fake = estimate_asset_cost(*cfg.provider("fake"), r);
    CHECK(fake.free);
    CHECK(fake.usd.value_or(-1) == 0);
    CHECK(estimate_asset_cost(*cfg.provider("mytool"), r).free);
    CHECK(estimate_asset_cost(*cfg.provider("local"), r).free);
    AssetEstimate remote = estimate_asset_cost(*cfg.provider("remote"), r);
    CHECK_FALSE(remote.free);
    CHECK_FALSE(remote.usd.has_value());
    CHECK_FALSE(remote.verified);
    CHECK(has(remote.basis, "assetPricing"));
    const Json j = estimate_to_json(remote);
    CHECK(j["estimatedCostUsd"].is_null());
    CHECK(j["costIsEstimate"] == true);
}

TEST_CASE("format_usd: at least two decimals, at most four") {
    CHECK(format_usd(0.5) == "$0.50");
    CHECK(format_usd(0.167) == "$0.167");
    CHECK(format_usd(12.4) == "$12.40");
    CHECK(format_usd(0.0005) == "$0.0005");
    CHECK(format_usd(0) == "$0.00");
}

// ------------------------------------------------------------------------------------------------------- results carry the estimate

TEST_CASE("assets.generate_*: every result carries estimatedCostUsd, labelled an estimate, and the fake provider is free") {
    Home home;
    Game free(fake_config());
    Json r = free.ok("assets.generate_image", image_args("assets/a.png"));
    CHECK(r["estimatedCostUsd"] == 0);
    CHECK(r["costIsEstimate"] == true);
    CHECK(r["cost"]["free"] == true);

    Game game(config_from(paid_config(R"({"askAboveUsd":5})")));
    r = game.ok("assets.generate_image", image_args("assets/a.png"));
    CHECK(r["estimatedCostUsd"] == doctest::Approx(0.30));
    CHECK(r["costIsEstimate"] == true);
    CHECK(r["cost"]["priceChecked"] == "2026-11-06");
    CHECK(r["cost"]["priceSource"] == "https://example.com/prices");
    CHECK(has(r["cost"]["basis"].get<std::string>(), "$0.30"));
    CHECK(r["cost"]["spentThisRunUsd"] == doctest::Approx(0.30));
    CHECK(r["cost"]["spentTodayUsd"] == doctest::Approx(0.30));

    r = game.ok("assets.generate_sound", {{"prompt", "a coin"}, {"path", "assets/c.wav"}, {"seconds", 2}});
    CHECK(r["estimatedCostUsd"] == doctest::Approx(0.20));
    r = game.ok("assets.generate_voice", {{"text", std::string(100, 'x')}, {"path", "assets/v.wav"}});
    CHECK(r["estimatedCostUsd"] == doctest::Approx(0.05));
    CHECK(r["cost"]["spentThisRunUsd"] == doctest::Approx(0.30 + 0.20 + 0.05));
    // a silent placeholder voice calls no provider and costs nothing: no estimate to report
    r = game.ok("assets.generate_voice", {{"text", "hello"}, {"path", "assets/s.wav"}, {"silent", true}});
    CHECK_FALSE(r.contains("estimatedCostUsd"));
}

TEST_CASE("assets.generate_*: the command documentation tells an AI to ask the user and never to approve by itself") {
    Game game(fake_config());
    for (const char* name : {"assets.generate_image", "assets.generate_sprite_sheet", "assets.generate_sound", "assets.generate_music",
                             "assets.generate_voice", "assets.generate_model", "image.inpaint", "image.generate_layer"}) {
        INFO(name);
        const CommandInfo* info = game.registry.info(name);
        REQUIRE(info);
        CHECK(has(info->description, "approved:true"));
        CHECK(has(info->description, "never set approved:true on its own"));
        CHECK(has(info->description, "estimate"));
        REQUIRE(info->inputSchema["properties"].contains("approved"));
        CHECK(has(info->inputSchema["properties"]["approved"]["description"].get<std::string>(), "USER said yes"));
    }
}

// ------------------------------------------------------------------------------------------------------------------------ the limits

TEST_CASE("limits.maxAssetCostUsd.perRun: the call that would pass it is refused before the provider, with the numbers and how to raise it") {
    Home home;
    Game game(config_from(paid_config(R"({"maxAssetCostUsd":{"perRun":0.80},"askAboveUsd":5})")));
    AssetRunScope run("chat-a");
    asset_run_begin("chat-a");
    game.ok("assets.generate_image", image_args("assets/a.png"));
    game.ok("assets.generate_image", image_args("assets/b.png"));
    CHECK(asset_run_spent("chat-a") == doctest::Approx(0.60));
    auto refused = game.call("assets.generate_image", image_args("assets/c.png"));
    REQUIRE_FALSE(refused.ok);
    CHECK(refused.error["code"] == "asset_cost_limit");
    const std::string msg = refused.error["message"].get<std::string>();
    CHECK(has(msg, "limits.maxAssetCostUsd.perRun"));
    CHECK(has(msg, "$0.80"));  // the limit
    CHECK(has(msg, "$0.60"));  // already spent
    CHECK(has(msg, "$0.30"));  // this call
    CHECK(has(refused.error["hint"].get<std::string>(), "AI Settings"));
    CHECK(has(refused.error["hint"].get<std::string>(), "Do not raise a limit yourself"));
    CHECK(refused.error["data"]["limit"] == "perRun");
    CHECK_FALSE(game.exists("assets/c.png"));
    CHECK(asset_run_spent("chat-a") == doctest::Approx(0.60));  // a refusal counts nothing
    // another run starts from zero
    asset_run_begin("chat-a");
    game.ok("assets.generate_image", image_args("assets/c.png"));
}

TEST_CASE("limits.maxAssetCostUsd.perDay: the day's total is shared by every process through a file, and a day later starts again") {
    std::int64_t now = static_cast<std::int64_t>(std::time(nullptr));
    TempDir homeDir;
    ScopedShareEnv scoped(Home::make(homeDir.str(), 2.0, [&now] { return now; }));
    const AiConfig cfg = config_from(paid_config(R"({"maxAssetCostUsd":{"perDay":0.80},"askAboveUsd":5})"));
    Game editor(cfg);  // one program...
    editor.ok("assets.generate_image", image_args("assets/a.png"));
    // ...and another one on the same project that never saw the first: its own registry and run ledger
    CommandRegistry terminal;
    {
        AiCommandOptions opt;
        opt.loadConfig = [cfg] { return Result<AiConfig>(cfg); };
        opt.projectDir = [&editor] { return editor.dir.str(); };
        register_ai_commands(terminal, std::move(opt));
    }
    auto second = terminal.call("assets.generate_image", image_args("assets/b.png"));
    REQUIRE_MESSAGE(second.ok, second.error.dump());
    CHECK(*asset_spent_today(editor.dir.str()) == doctest::Approx(0.60));
    auto refused = terminal.call("assets.generate_image", image_args("assets/c.png"));
    REQUIRE_FALSE(refused.ok);
    CHECK(refused.error["code"] == "asset_cost_limit");
    CHECK(has(refused.error["message"].get<std::string>(), "limits.maxAssetCostUsd.perDay"));
    CHECK(has(refused.error["message"].get<std::string>(), "$0.60"));
    CHECK(has(refused.error["message"].get<std::string>(), "across every editor"));
    CHECK(refused.error["data"]["limit"] == "perDay");
    CHECK_FALSE(editor.exists("assets/c.png"));

    // the file holds the totals by day and project, readable JSON
    const Json file = Json::parse(read_file(asset_spend_path()));
    CHECK(file["format"] == "factoria.asset-spend/1");
    REQUIRE(file["days"].is_object());
    CHECK(file["days"].size() == 1);

    // tomorrow the total starts again (the clock is the share environment's)
    now += 26 * 3600;
    auto tomorrow = terminal.call("assets.generate_image", image_args("assets/c.png"));
    REQUIRE_MESSAGE(tomorrow.ok, tomorrow.error.dump());
    CHECK(*asset_spent_today(editor.dir.str()) == doctest::Approx(0.30));
    CHECK(Json::parse(read_file(asset_spend_path()))["days"].size() == 2);
}

TEST_CASE("limits.maxAssetCostUsd.perDay: the total is per project") {
    Home home;
    const AiConfig cfg = config_from(paid_config(R"({"maxAssetCostUsd":{"perDay":0.40},"askAboveUsd":5})"));
    Game a(cfg), b(cfg);
    a.ok("assets.generate_image", image_args("assets/a.png"));
    b.ok("assets.generate_image", image_args("assets/a.png"));  // another project has its own day
    CHECK_FALSE(a.call("assets.generate_image", image_args("assets/b.png")).ok);
}

TEST_CASE("limits: a lock that cannot be taken is reported and changes nothing when a per-day limit is set; without one the call goes on with a warning") {
    Home home(0.2);
    home.hold_lock();
    {
        Game limited(config_from(paid_config(R"({"maxAssetCostUsd":{"perDay":5},"askAboveUsd":5})")));
        AssetRunScope run("lock-run");
        asset_run_begin("lock-run");
        auto r = limited.call("assets.generate_image", image_args("assets/a.png"));
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "asset_cost_unavailable");
        CHECK(has(r.error["message"].get<std::string>(), "lock"));
        CHECK_FALSE(limited.exists("assets/a.png"));
        CHECK(asset_run_spent("lock-run") == 0);  // not half applied
        CHECK_FALSE(fsys::exists(home.spend_file()));
    }
    {
        Game unlimited(config_from(paid_config(R"({"askAboveUsd":5})")));
        auto r = unlimited.call("assets.generate_image", image_args("assets/a.png"));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        REQUIRE(r.result.contains("warnings"));
        CHECK(has(r.result["warnings"].dump(), "was not recorded"));
        CHECK_FALSE(fsys::exists(home.spend_file()));
    }
    home.release_lock();
    Game after(config_from(paid_config(R"({"maxAssetCostUsd":{"perDay":5},"askAboveUsd":5})")));
    after.ok("assets.generate_image", image_args("assets/a.png"));
    CHECK(fsys::exists(home.spend_file()));
}

TEST_CASE("limits: a damaged day file stops a per-day limit instead of being counted as zero") {
    Home home;
    fsys::create_directories(home.spend_file().parent_path());
    std::ofstream(home.spend_file(), std::ios::binary) << "{ not json";
    Game game(config_from(paid_config(R"({"maxAssetCostUsd":{"perDay":5},"askAboveUsd":5})")));
    auto r = game.call("assets.generate_image", image_args("assets/a.png"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "asset_cost_unavailable");
    CHECK(has(r.error["message"].get<std::string>(), "asset-spend.json"));
    CHECK_FALSE(game.exists("assets/a.png"));
}

TEST_CASE("limits: with a limit set, a price that is not known is refused; without one it asks") {
    Home home;
    auto remote = [](const std::string& limits) {
        return Json::parse(R"({"providers":{"remote":{"type":"openai-compatible","baseUrl":"https://api.example.com/v1","apiKeyEnv":"X_KEY"}},
            "assets":{"image":{"provider":"remote"}},"limits":)" + limits + "}");
    };
    {
        Game limited(config_from(remote(R"({"maxAssetCostUsd":{"perRun":1}})")));
        auto r = limited.call("assets.generate_image", image_args("assets/a.png"));
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "asset_cost_unknown");
        CHECK(has(r.error["message"].get<std::string>(), "price is not known"));
        CHECK(has(r.error["hint"].get<std::string>(), "assetPricing"));
    }
    {
        Game unlimited(config_from(remote("{}")));
        auto r = unlimited.call("assets.generate_image", image_args("assets/a.png"));
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK(r.result["needsApproval"] == true);  // an unknown price always asks
        CHECK(r.result["plan"]["estimatedCostUsd"].is_null());
        CHECK_FALSE(unlimited.exists("assets/a.png"));
    }
}

// ---------------------------------------------------------------------------------------------------------------------- the approval

TEST_CASE("approval: a call above askAboveUsd returns needsApproval with the plan and makes nothing; approved:true makes it") {
    Home home;
    Game game(config_from(paid_config(R"({"askAboveUsd":0.50})")));
    // at or under the threshold: no question
    game.ok("assets.generate_image", image_args("assets/a.png"));
    // $1.00 of voice is above it
    const Json args = {{"text", std::string(2000, 'a')}, {"path", "assets/v.wav"}};
    auto r = game.call("assets.generate_voice", args);
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["needsApproval"] == true);
    CHECK(r.result["generated"] == false);
    const Json& plan = r.result["plan"];
    CHECK(plan["command"] == "assets.generate_voice");
    CHECK(plan["kind"] == "voice");
    CHECK(plan["provider"] == "paid");
    CHECK(plan["count"] == 1);
    CHECK(plan["estimatedCostUsd"] == doctest::Approx(1.0));
    CHECK(plan["priceChecked"] == "2026-11-06");
    CHECK(has(plan["what"].get<std::string>(), "assets/v.wav"));
    CHECK(has(r.result["next"].get<std::string>(), "approved:true"));
    CHECK(has(r.result["next"].get<std::string>(), "Never set approved:true on your own"));
    CHECK_FALSE(game.exists("assets/v.wav"));
    CHECK(*asset_spent_today(game.dir.str()) == doctest::Approx(0.30));  // asking counts nothing

    Json approved = args;
    approved["approved"] = true;
    r = game.call("assets.generate_voice", approved);
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK_FALSE(r.result.contains("needsApproval"));
    CHECK(r.result["estimatedCostUsd"] == doctest::Approx(1.0));
    CHECK(game.exists("assets/v.wav"));
}

TEST_CASE("approval: a limit still holds for an approved call") {
    Home home;
    Game game(config_from(paid_config(R"({"maxAssetCostUsd":{"perRun":0.5},"askAboveUsd":0.1})")));
    AssetRunScope run("approved-run");
    asset_run_begin("approved-run");
    auto r = game.call("assets.generate_voice", {{"text", std::string(2000, 'a')}, {"path", "assets/v.wav"}, {"approved", true}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "asset_cost_limit");
}

TEST_CASE("approval: the fake provider and local programs never ask, even with askAboveUsd 0") {
    Home home;
    Game game(config_from(R"({"limits":{"askAboveUsd":0},"providers":{"mytool":{"type":"asset-command","command":"python","argv":["g.py","{output}"]}},
                              "assets":{"image":{"provider":"fake"},"sound":{"provider":"fake"},"music":{"provider":"fake"},
                                        "voice":{"provider":"fake"},"model3d":{"provider":"fake"}}})"));
    auto r = game.call("assets.generate_image", image_args("assets/a.png"));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK_FALSE(r.result.contains("needsApproval"));
    CHECK(game.exists("assets/a.png"));
}

TEST_CASE("approval: with an approver installed (the editor) the call waits for the answer instead of returning needsApproval") {
    Home home;
    Game game(config_from(paid_config(R"({"askAboveUsd":0.10})")));
    AssetRunScope run("editor-chat");
    asset_run_begin("editor-chat");

    std::vector<Json> asked;
    std::string runKeyAsked;
    AssetDecision answer = AssetDecision::Approve;
    ScopedAssetApprover approver([&](const AssetApprovalRequest& req) {
        asked.push_back(req.plan);
        runKeyAsked = req.runKey;
        return answer;
    });
    game.ok("assets.generate_image", image_args("assets/a.png"));
    REQUIRE(asked.size() == 1);
    CHECK(runKeyAsked == "editor-chat");
    CHECK(asked[0]["estimatedCostUsd"] == doctest::Approx(0.30));
    CHECK(game.exists("assets/a.png"));

    // Cancel: nothing is made or counted, and the error tells the AI not to ask again
    answer = AssetDecision::Cancel;
    auto declined = game.call("assets.generate_image", image_args("assets/b.png"));
    REQUIRE_FALSE(declined.ok);
    CHECK(declined.error["code"] == "asset_declined");
    CHECK(has(declined.error["hint"].get<std::string>(), "Do not ask for the same thing again"));
    CHECK_FALSE(game.exists("assets/b.png"));
    CHECK(asset_run_spent("editor-chat") == doctest::Approx(0.30));

    // Approve all for this run: the next calls do not ask, and a new run asks again
    answer = AssetDecision::ApproveAll;
    game.ok("assets.generate_image", image_args("assets/c.png"));
    CHECK(asked.size() == 3);
    game.ok("assets.generate_image", image_args("assets/d.png"));
    CHECK(asked.size() == 3);
    CHECK(asset_run_approves_all("editor-chat"));
    asset_run_begin("editor-chat");
    CHECK_FALSE(asset_run_approves_all("editor-chat"));
    game.ok("assets.generate_image", image_args("assets/e.png"));
    CHECK(asked.size() == 4);
}

TEST_CASE("approval: the approver of a registry (AiCommandOptions::assetApprover) is asked only by that registry's calls") {
    Home home;
    const AiConfig cfg = config_from(paid_config(R"({"askAboveUsd":0.10})"));
    int asked = 0;
    CommandRegistry withApprover, without;
    TempDir dir;
    for (CommandRegistry* reg : {&withApprover, &without}) {
        AiCommandOptions opt;
        opt.loadConfig = [cfg] { return Result<AiConfig>(cfg); };
        opt.projectDir = [&dir] { return dir.str(); };
        opt.assetRunKey = "chat-x";
        if (reg == &withApprover) opt.assetApprover = [&asked](const AssetApprovalRequest& req) {
            ++asked;
            CHECK(req.runKey == "chat-x");
            return AssetDecision::Approve;
        };
        register_ai_commands(*reg, std::move(opt));
    }
    auto yes = withApprover.call("assets.generate_image", image_args("assets/a.png"));
    REQUIRE_MESSAGE(yes.ok, yes.error.dump());
    CHECK(asked == 1);
    CHECK_FALSE(yes.result.contains("needsApproval"));
    auto no = without.call("assets.generate_image", image_args("assets/b.png"));
    REQUIRE_MESSAGE(no.ok, no.error.dump());
    CHECK(asked == 1);
    CHECK(no.result["needsApproval"] == true);  // no one to ask: the AI asks its user
    CHECK(asset_run_key().empty());             // the scope ended with the call
}

TEST_CASE("approval: an approver that waits on another thread does not hold the lock of the user folder or the run's ledger") {
    Home home;
    Game game(config_from(paid_config(R"({"askAboveUsd":0.10,"maxAssetCostUsd":{"perDay":5}})")));
    std::atomic<bool> waiting{false}, release{false};
    ScopedAssetApprover approver([&](const AssetApprovalRequest&) {
        waiting = true;
        while (!release) std::this_thread::sleep_for(std::chrono::milliseconds(2));
        return AssetDecision::Approve;
    });
    std::thread worker([&] {
        AssetRunScope run("slow-chat");
        game.ok("assets.generate_image", image_args("assets/a.png"));
    });
    while (!waiting) std::this_thread::sleep_for(std::chrono::milliseconds(2));
    // while the person thinks, other callers read and write the same state
    CHECK(asset_run_spent("slow-chat") == 0);
    CHECK(asset_spent_today(game.dir.str()).has_value());
    {
        ShareLock lock(share_env());
        CHECK(lock.held());
    }
    release = true;
    worker.join();
    CHECK(asset_run_spent("slow-chat") == doctest::Approx(0.30));
}

// ----------------------------------------------------------------------------------------------------------------------------- guard

TEST_CASE("AssetCostGuard: a call that fails gives its money back, one that succeeds keeps it") {
    Home home;
    const AiConfig cfg = config_from(paid_config(R"({"askAboveUsd":5})"));
    AssetCall call;
    call.command = "assets.generate_image";
    call.projectDir = home.dir.str();
    call.provider = "paid";
    AssetRequest request;
    request.kind = MediaKind::Image;
    request.width = request.height = 8;
    call.estimate = estimate_asset_cost(*cfg.provider("paid"), request, 2);
    AssetRunScope run("guard-run");
    asset_run_begin("guard-run");
    {
        AssetCostGuard guard = AssetCostGuard::begin(cfg.limits, call, false);
        REQUIRE(guard.go());
        CHECK(asset_run_spent("guard-run") == doctest::Approx(0.60));
        CHECK(*asset_spent_today(home.dir.str()) == doctest::Approx(0.60));
    }  // not committed: the provider failed
    CHECK(asset_run_spent("guard-run") == doctest::Approx(0.0));
    CHECK(*asset_spent_today(home.dir.str()) == doctest::Approx(0.0));
    {
        AssetCostGuard guard = AssetCostGuard::begin(cfg.limits, call, false);
        guard.commit();
    }
    CHECK(asset_run_spent("guard-run") == doctest::Approx(0.60));
    CHECK(*asset_spent_today(home.dir.str()) == doctest::Approx(0.60));
}

// ------------------------------------------------------------------------------------------------ approved cannot bypass the card

TEST_CASE("approval: with an approver installed the approved argument is ignored, the person's answer decides") {
    Home home;
    Game game(config_from(paid_config(R"({"askAboveUsd":0.10})")));
    AssetRunScope run("card-chat");
    asset_run_begin("card-chat");
    int asked = 0;
    AssetDecision answer = AssetDecision::Cancel;
    ScopedAssetApprover approver([&](const AssetApprovalRequest&) {
        ++asked;
        return answer;
    });
    Json args = image_args("assets/a.png");
    args["approved"] = true;  // what an AI could pass to skip the question
    auto declined = game.call("assets.generate_image", args);
    REQUIRE_FALSE(declined.ok);
    CHECK(declined.error["code"] == "asset_declined");
    CHECK(asked == 1);
    CHECK_FALSE(game.exists("assets/a.png"));
    CHECK(asset_run_spent("card-chat") == 0);

    answer = AssetDecision::Approve;
    auto yes = game.call("assets.generate_image", args);
    REQUIRE_MESSAGE(yes.ok, yes.error.dump());
    CHECK(asked == 2);
    CHECK(game.exists("assets/a.png"));
    CHECK(has(yes.result["warnings"].dump(), "approved argument was ignored"));
}

TEST_CASE("approval: AssetCall::userApproved is the host's own yes and counts whatever approver there is") {
    Home home;
    const AiConfig cfg = config_from(paid_config(R"({"askAboveUsd":0.10})"));
    AssetCall call;
    call.command = "image.generate_layer";
    call.projectDir = home.dir.str();
    call.provider = "paid";
    AssetRequest request;
    request.kind = MediaKind::Image;
    request.width = request.height = 8;
    call.estimate = estimate_asset_cost(*cfg.provider("paid"), request, 1);
    AssetRunScope run("panel");
    asset_run_begin("panel");
    int asked = 0;
    ScopedAssetApprover approver([&](const AssetApprovalRequest&) {
        ++asked;
        return AssetDecision::Cancel;
    });
    CHECK_THROWS_AS(AssetCostGuard::begin(cfg.limits, call, true), CommandError);  // the argument: ignored, the approver says no
    CHECK(asked == 1);
    call.userApproved = true;
    AssetCostGuard guard = AssetCostGuard::begin(cfg.limits, call, false);
    CHECK(guard.go());
    CHECK(asked == 1);  // nobody was asked: the person already pressed the button
    guard.commit();
}

TEST_CASE("approval: a run that is stopped while the card waits gets cancelled, not declined, and nothing is counted") {
    Home home;
    Game game(config_from(paid_config(R"({"askAboveUsd":0.10})")));
    AssetRunScope run("stop-chat");
    asset_run_begin("stop-chat");
    ScopedAssetApprover approver([](const AssetApprovalRequest&) { return AssetDecision::Stopped; });
    auto r = game.call("assets.generate_image", image_args("assets/a.png"));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "cancelled");
    CHECK(has(r.error["message"].get<std::string>(), "stopped"));
    CHECK_FALSE(game.exists("assets/a.png"));
    CHECK(asset_run_spent("stop-chat") == 0);
    CHECK(*asset_spent_today(game.dir.str()) == 0);
}

// ----------------------------------------------------------------------------------------------- a batch cut into small calls

TEST_CASE("approval: calls under askAboveUsd that add up above it are asked about (no approver: needsApproval), and a yes starts the count again") {
    Home home;
    Game game(config_from(paid_config(R"({"askAboveUsd":0.50})")));
    AssetRunScope run("batch");
    asset_run_begin("batch");
    // 3 x $0.30: the first is under 0.50, the second takes the unapproved total to 0.60
    game.ok("assets.generate_image", image_args("assets/a.png"));
    CHECK(asset_run_unapproved("batch") == doctest::Approx(0.30));
    auto second = game.call("assets.generate_image", image_args("assets/b.png"));
    REQUIRE_MESSAGE(second.ok, second.error.dump());
    CHECK(second.result["needsApproval"] == true);
    CHECK(second.result["plan"]["earlierUnapprovedUsd"] == doctest::Approx(0.30));
    CHECK(has(second.result["message"].get<std::string>(), "$0.30"));
    CHECK_FALSE(game.exists("assets/b.png"));
    CHECK(asset_run_spent("batch") == doctest::Approx(0.30));  // asking counts nothing
    // the user said yes: it goes, and the count starts from zero
    Json yes = image_args("assets/b.png");
    yes["approved"] = true;
    game.ok("assets.generate_image", yes);
    CHECK(asset_run_unapproved("batch") == 0);
    game.ok("assets.generate_image", image_args("assets/c.png"));  // 0.30 again: no question
    CHECK(game.exists("assets/c.png"));
    CHECK(asset_run_spent("batch") == doctest::Approx(0.90));
}

TEST_CASE("approval: with an approver, small calls add up to a card; Approve resets the count, Approve all stops the questions for the run") {
    Home home;
    Game game(config_from(paid_config(R"({"askAboveUsd":0.50})")));
    AssetRunScope run("batch-card");
    asset_run_begin("batch-card");
    std::vector<Json> asked;
    AssetDecision answer = AssetDecision::Approve;
    ScopedAssetApprover approver([&](const AssetApprovalRequest& req) {
        asked.push_back(req.plan);
        return answer;
    });
    game.ok("assets.generate_image", image_args("assets/a.png"));
    CHECK(asked.empty());
    game.ok("assets.generate_image", image_args("assets/b.png"));  // 0.30 + 0.30 > 0.50
    REQUIRE(asked.size() == 1);
    CHECK(asked[0]["earlierUnapprovedUsd"] == doctest::Approx(0.30));
    game.ok("assets.generate_image", image_args("assets/c.png"));  // after the yes: 0.30 alone
    CHECK(asked.size() == 1);
    answer = AssetDecision::ApproveAll;
    game.ok("assets.generate_image", image_args("assets/d.png"));  // 0.60 again: asks, and the answer turns the questions off
    CHECK(asked.size() == 2);
    game.ok("assets.generate_image", image_args("assets/e.png"));
    game.ok("assets.generate_image", image_args("assets/f.png"));
    CHECK(asked.size() == 2);
    CHECK(asset_run_spent("batch-card") == doctest::Approx(1.80));
}

TEST_CASE("approval: a call that fails gives back its part of the unapproved count too") {
    Home home;
    const AiConfig cfg = config_from(paid_config(R"({"askAboveUsd":0.50})"));
    AssetCall call;
    call.command = "assets.generate_image";
    call.projectDir = home.dir.str();
    call.provider = "paid";
    AssetRequest request;
    request.kind = MediaKind::Image;
    request.width = request.height = 8;
    call.estimate = estimate_asset_cost(*cfg.provider("paid"), request, 1);
    AssetRunScope run("refund-run");
    asset_run_begin("refund-run");
    {
        AssetCostGuard guard = AssetCostGuard::begin(cfg.limits, call, false);
        REQUIRE(guard.go());
        CHECK(asset_run_unapproved("refund-run") == doctest::Approx(0.30));
    }  // the provider failed
    CHECK(asset_run_unapproved("refund-run") == 0);
    CHECK(asset_run_spent("refund-run") == 0);
}

// ------------------------------------------------------------------------------------------------------------ the day total

TEST_CASE("day total: a refund after midnight goes back to the day the money was counted on") {
    std::int64_t now = 1800000000;
    TempDir homeDir;
    ScopedShareEnv scoped(Home::make(homeDir.str(), 2.0, [&now] { return now; }));
    const AiConfig cfg = config_from(paid_config(R"({"askAboveUsd":5,"maxAssetCostUsd":{"perDay":5}})"));
    AssetCall call;
    call.command = "assets.generate_image";
    call.projectDir = homeDir.str();
    call.provider = "paid";
    AssetRequest request;
    request.kind = MediaKind::Image;
    request.width = request.height = 8;
    call.estimate = estimate_asset_cost(*cfg.provider("paid"), request, 1);
    AssetRunScope run("midnight");
    asset_run_begin("midnight");
    {
        AssetCostGuard guard = AssetCostGuard::begin(cfg.limits, call, false);
        REQUIRE(guard.go());
        now += 26 * 3600;  // the provider took until the next day and failed
    }
    const Json file = Json::parse(read_file(asset_spend_path()));
    REQUIRE(file["days"].size() == 1);
    double total = 0;
    for (const auto& [date, projects] : file["days"].items())
        for (const auto& [project, entry] : projects.items()) total += entry["usd"].get<double>();
    CHECK(total == doctest::Approx(0.0));  // the first day was given back, not the new one (which would go below zero)
    CHECK(*asset_spent_today(homeDir.str()) == doctest::Approx(0.0));
}

TEST_CASE("day total: a file with another shape is reported as unreadable, with where, and nothing is changed") {
    Home home;
    const std::vector<std::string> bad = {R"([1,2])", R"({"days":[]})", R"({"days":{"2027-01-15":5}})",
                                          R"({"days":{"2027-01-15":{"p":{"usd":"a lot"}}}})"};
    for (const std::string& text : bad) {
        fsys::create_directories(home.spend_file().parent_path());
        std::ofstream(home.spend_file(), std::ios::binary) << text;
        Game game(config_from(paid_config(R"({"maxAssetCostUsd":{"perDay":5},"askAboveUsd":5})")));
        auto r = game.call("assets.generate_image", image_args("assets/a.png"));
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "asset_cost_unavailable");
        CHECK(has(r.error["message"].get<std::string>(), "shape"));
        CHECK_FALSE(game.exists("assets/a.png"));
        CHECK(read_file(asset_spend_path()) == text);
        CHECK_FALSE(asset_spent_today(game.dir.str()).has_value());
    }
}

TEST_CASE("day total: a user folder with accents in its name works") {
    TempDir base;
    const fsys::path folder = fsys::path(base.str()) / fsys::path(u8"carpeta áé ñ");
    fsys::create_directories(folder);
    const std::u8string utf8 = folder.u8string();   // (never .string(): on Windows that goes through the ANSI code page)
    const std::string home(reinterpret_cast<const char*>(utf8.data()), utf8.size());
    ScopedShareEnv scoped(Home::make(home, 2.0));
    Game game(config_from(paid_config(R"({"askAboveUsd":5,"maxAssetCostUsd":{"perDay":5}})")));
    game.ok("assets.generate_image", image_args("assets/a.png"));
    CHECK(fsys::exists(fsys::path(base.str()) / fsys::path(u8"carpeta áé ñ") / ".factoria" / "asset-spend.json"));
    CHECK(*asset_spent_today(game.dir.str()) == doctest::Approx(0.30));
}

// ------------------------------------------------------------------------------------------------------------------------- the image tools

TEST_CASE("image.generate_layer: dryRun reports the estimate, a paid call asks, and approved:true makes the layer") {
    Home home;
    Game game(config_from(paid_config(R"({"askAboveUsd":0.10})")));
    fa::register_asset_commands(game.registry, game.dir.str());
    game.ok("image.create", {{"path", "assets/art/hero.image.json"}, {"width", 16}, {"height", 16},
                             {"layers", Json::array({{{"kind", "fill"}, {"name", "sky"}, {"color", "#406080"}}})}});
    const Json args = {{"path", "assets/art/hero.image.json"}, {"prompt", "a brass key"}};
    Json dry = args;
    dry["dryRun"] = true;
    const Json d = game.ok("image.generate_layer", dry);
    CHECK(d["estimate"]["estimatedCostUsd"] == doctest::Approx(0.30));
    CHECK(d["estimate"]["costIsEstimate"] == true);
    CHECK(d["sent"] == false);
    CHECK_FALSE(fsys::exists(home.spend_file()));  // a dry run counts nothing

    auto asked = game.call("image.generate_layer", args);
    REQUIRE_MESSAGE(asked.ok, asked.error.dump());
    CHECK(asked.result["needsApproval"] == true);
    CHECK(asked.result["plan"]["command"] == "image.generate_layer");

    Json yes = args;
    yes["approved"] = true;
    const Json done = game.ok("image.generate_layer", yes);
    CHECK(done["estimatedCostUsd"] == doctest::Approx(0.30));
    CHECK(done["estimate"]["estimatedCostUsd"] == doctest::Approx(0.30));
}

// ------------------------------------------------------------------------------------------------------------------ the run's total

TEST_CASE("session: the estimated asset cost of the tool calls is summed into the result and the Done event, apart from the model's cost") {
    CommandRegistry registry = make_registry();
    CommandInfo gen;
    gen.name = "assets.generate_image";
    gen.summary = "Stands for a paid generating command.";
    registry.add(gen, [](const Json&) { return Json::object({{"ok", true}, {"estimatedCostUsd", 0.3}, {"costIsEstimate", true}}); });
    auto provider = std::make_shared<FakeProvider>();
    ToolCall a, b;
    a.id = "t1";
    b.id = "t2";
    a.name = b.name = "assets_generate_image";
    a.input = b.input = Json::object();
    provider->script = {tool_response({a, b}), text_response("done")};
    TempDir dir;
    SessionOptions so;
    so.projectDir = dir.str();
    AiConfig cfg = default_config();
    AgentSession session(registry, cfg, so);
    session.set_provider_factory([&](const ProviderConfig&) -> Result<std::shared_ptr<ChatProvider>> {
        return std::static_pointer_cast<ChatProvider>(provider);
    });
    double doneCost = -1;
    session.set_event_handler([&](const AgentEvent& e) {
        if (e.type == AgentEvent::Type::Done) doneCost = e.assetCostUsd;
    });
    const SessionResult r = session.run("make two pictures");
    REQUIRE_MESSAGE(r.ok, r.error);
    CHECK(r.assetCostUsd == doctest::Approx(0.6));
    CHECK(doneCost == doctest::Approx(0.6));
    CHECK(r.to_json()["assetCostUsd"] == doctest::Approx(0.6));
}

// --------------------------------------------------------------------------------------------------------- the limits in the files

TEST_CASE("save_asset_limits: writes only the limits keys, keeps the rest of the file, and the defaults remove their keys") {
    TempDir dir;
    const std::string path = (dir.path / "ai.json").string();
    {
        std::ofstream(dir.path / "ai.json", std::ios::binary) << R"({"limits":{"maxTurns":30},"roles":{"worker":{"model":"sonnet"}}})";
    }
    Limits l;
    l.maxAssetCostPerRunUsd = 2.5;
    l.maxAssetCostPerDayUsd = 10;
    l.askAboveUsd = 1;
    REQUIRE(save_asset_limits(l, path));
    Json file = Json::parse(read_file(path));
    CHECK(file["limits"]["maxTurns"] == 30);
    CHECK(file["limits"]["maxAssetCostUsd"]["perRun"] == 2.5);
    CHECK(file["limits"]["maxAssetCostUsd"]["perDay"] == 10);
    CHECK(file["limits"]["askAboveUsd"] == 1);
    CHECK(file["roles"]["worker"]["model"] == "sonnet");
    auto back = load_config(path, [](const std::string&) { return std::string(); });
    REQUIRE(back);
    CHECK(back->limits.maxAssetCostPerRunUsd == doctest::Approx(2.5));
    CHECK(back->limits.askAboveUsd == doctest::Approx(1));

    l = Limits{};  // no limits and the default question threshold: the keys go away
    REQUIRE(save_asset_limits(l, path));
    file = Json::parse(read_file(path));
    CHECK(file["limits"]["maxTurns"] == 30);
    CHECK_FALSE(file["limits"].contains("maxAssetCostUsd"));
    CHECK_FALSE(file["limits"].contains("askAboveUsd"));

    l.maxAssetCostPerDayUsd = -1;  // not saved: a message that says what is allowed
    auto bad = save_asset_limits(l, path);
    REQUIRE_FALSE(bad);
    CHECK(has(bad.error().message, "perDay"));
    CHECK(Json::parse(read_file(path))["limits"]["maxTurns"] == 30);
}

TEST_CASE("assetPricing: a limit that is not a number or is negative is an error with the pointer") {
    auto neg = parse_config(Json::parse(R"({"limits":{"maxAssetCostUsd":{"perRun":-1}}})"), "test");
    REQUIRE_FALSE(neg.ok());
    CHECK(has(neg.error().message, "/limits/maxAssetCostUsd/perRun"));
    auto typo = parse_config(Json::parse(R"({"limits":{"maxAssetCostUsd":{"perDays":1}}})"), "test");
    REQUIRE_FALSE(typo.ok());
    CHECK(has(typo.error().to_string(), "perDay"));
}
