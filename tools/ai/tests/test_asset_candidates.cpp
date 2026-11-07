// Asset candidates (docs/ASSETS.md, "Candidates"): assets.generate_image {count} makes N pictures for one slot and one review sheet,
// assets.pick keeps the one the person chose. The fake provider stands for a real one; the user folder is a scratch folder.
#include <filesystem>
#include <fstream>

#include "asset_test.h"
#include "fa/ai/asset_cost.h"
#include "fa/core/fs.h"
#include "fa/tooling/feedback_share.h"
#include "fa/tooling/review.h"

using namespace fa;
using namespace fa::ai;
using namespace fa::ai::test;
namespace fsys = std::filesystem;

namespace {

bool has(const std::string& text, const std::string& part) { return text.find(part) != std::string::npos; }

Json candidate_args(const std::string& slot, int count) {
    return {{"prompt", "a red potion bottle"}, {"path", slot}, {"width", 16}, {"height", 16}, {"count", count}};
}

// A fake provider with a price table: 0.30 a picture.
Json paid_config(const std::string& limits) {
    return Json::parse(R"({"providers":{"paid":{"type":"fake","assetPricing":{"image":0.30,"checked":"2026-11-06","source":"https://example.com/prices"}}},
               "assets":{"image":{"provider":"paid"}},"limits":)" + limits + "}");
}

}  // namespace

TEST_CASE("assets.generate_image count 3: three candidate files with their own seeds and provenance, one review sheet with the meta") {
    Game game(fake_config());
    const Json r = game.ok("assets.generate_image", [] {
        Json a = candidate_args("assets/items/potion.png", 3);
        a["seed"] = 100;
        return a;
    }());
    CHECK(r["slot"] == "assets/items/potion.png");
    CHECK(r["count"] == 3);
    REQUIRE(r["candidates"].size() == 3);
    for (int i = 0; i < 3; ++i) {
        const Json& c = r["candidates"][std::size_t(i)];
        const std::string path = "assets/items/potion.candidate-" + std::to_string(i + 1) + ".png";
        CHECK(c["n"] == i + 1);
        CHECK(c["path"] == path);
        CHECK(c["seed"] == 100 + i);  // seed, seed+1, seed+2
        CHECK(game.exists(path));
        const Json prov = game.provenance(path);
        CHECK(prov["origin"] == "generated");
        CHECK(prov["seed"] == 100 + i);
        CHECK(prov["candidate"]["slot"] == "assets/items/potion.png");
        CHECK(prov["candidate"]["n"] == i + 1);
    }
    CHECK_FALSE(game.exists("assets/items/potion.png"));  // the slot waits for the pick
    CHECK(game.file("assets/items/potion.candidate-1.png") != game.file("assets/items/potion.candidate-2.png"));

    const std::string sheet = r["sheet"].get<std::string>();
    CHECK(sheet == "sheet-0001");
    REQUIRE(r.contains("$image"));
    CHECK(has(r["$image"]["path"].get<std::string>(), "sheet.png"));
    REQUIRE(r["nextSteps"].is_array());
    CHECK(has(r["nextSteps"][0].get<std::string>(), "ONE number"));
    CHECK(has(r["nextSteps"][1].get<std::string>(), "assets.pick"));

    const Json manifest = Json::parse(game.file(".factoria/review/" + sheet + "/manifest.json"));
    CHECK(manifest["dropDir"] == ".factoria/assets/candidates");
    CHECK(manifest["label"] == "a red potion bottle");
    const Json& meta = manifest["meta"];
    CHECK(meta["kind"] == "assetCandidates");
    CHECK(meta["slot"] == "assets/items/potion.png");
    CHECK(meta["command"] == "assets.generate_image");
    CHECK(meta["count"] == 3);
    CHECK(meta["candidates"].size() == 3);
    REQUIRE(manifest["items"].size() == 3);
    for (const Json& item : manifest["items"]) CHECK(item["candidate"] == true);
    CHECK(manifest["items"][1]["label"] == "seed 101");

    // Without a seed the candidates still differ, and the same prompt gives the same seeds again.
    const Json again = game.ok("assets.generate_image", candidate_args("assets/items/gem.png", 2));
    const Json twice = game.ok("assets.generate_image", candidate_args("assets/items/gem2.png", 2));
    CHECK(again["candidates"][0]["seed"] != again["candidates"][1]["seed"]);
    CHECK(again["candidates"][0]["seed"] == twice["candidates"][0]["seed"]);

    // count 1 is the old call: the slot itself, no sheet
    const Json one = game.ok("assets.generate_image", candidate_args("assets/items/one.png", 1));
    CHECK(one["path"] == "assets/items/one.png");
    CHECK_FALSE(one.contains("sheet"));
    CHECK(game.exists("assets/items/one.png"));
}

TEST_CASE("assets.generate_image count: out of range is refused with the pointer; existing candidates are refused before anything is made") {
    Game game(fake_config());
    for (int bad : {0, 5}) {
        auto r = game.call("assets.generate_image", candidate_args("assets/a.png", bad));
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "invalid_arguments");
        CHECK(has(r.error.dump(), "/count"));
    }
    CHECK_FALSE(game.exists("assets/a.candidate-1.png"));

    game.put("assets/a.candidate-2.png", png_bytes(4, 4, 1, 2, 3));
    auto r = game.call("assets.generate_image", candidate_args("assets/a.png", 3));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "exists");
    CHECK(has(r.error["message"].get<std::string>(), "assets/a.candidate-2.png"));
    CHECK_FALSE(game.exists("assets/a.candidate-1.png"));  // nothing made
    CHECK_FALSE(game.exists(".factoria/review/sheet-0001"));

    // overwrite makes them again; a slot that exists needs overwrite too
    Json args = candidate_args("assets/a.png", 3);
    args["overwrite"] = true;
    game.ok("assets.generate_image", args);
    CHECK(game.file("assets/a.candidate-2.png") != png_bytes(4, 4, 1, 2, 3));

    game.put("assets/b.png", png_bytes(4, 4, 1, 2, 3));
    r = game.call("assets.generate_image", candidate_args("assets/b.png", 2));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "exists");

    // the wrong extension is refused before anything is made
    r = game.call("assets.generate_image", candidate_args("assets/c.jpg", 2));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "wrong_extension");
}

TEST_CASE("assets.generate_image count 3: the estimate covers the three candidates, and there is one approval for the batch") {
    Game game(config_from(paid_config(R"({"askAboveUsd":0.50})")));
    // one call of 0.30 is under the threshold, three are not: needsApproval for all three, before any provider call
    auto r = game.call("assets.generate_image", candidate_args("assets/p.png", 3));
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["needsApproval"] == true);
    CHECK(r.result["plan"]["count"] == 3);
    CHECK(r.result["plan"]["estimatedCostUsd"] == doctest::Approx(0.90));
    CHECK(has(r.result["plan"]["what"].get<std::string>(), "3 candidate"));
    CHECK_FALSE(game.exists("assets/p.candidate-1.png"));

    // the editor's approver is asked once for the whole batch, with the total
    AssetRunScope run("candidates-run");
    asset_run_begin("candidates-run");
    std::vector<Json> asked;
    ScopedAssetApprover approver([&](const AssetApprovalRequest& req) {
        asked.push_back(req.plan);
        return AssetDecision::Approve;
    });
    const Json made = game.ok("assets.generate_image", candidate_args("assets/p.png", 3));
    REQUIRE(asked.size() == 1);
    CHECK(asked[0]["count"] == 3);
    CHECK(asked[0]["estimatedCostUsd"] == doctest::Approx(0.90));
    CHECK(made["estimatedCostUsd"] == doctest::Approx(0.90));
    CHECK(asset_run_spent("candidates-run") == doctest::Approx(0.90));
    CHECK(game.exists("assets/p.candidate-3.png"));

    // a run limit below the batch stops it before the first candidate
    asset_run_begin("candidates-run");
    Game limited(config_from(paid_config(R"({"maxAssetCostUsd":{"perRun":0.50},"askAboveUsd":5})")));
    AssetRunScope limitedRun("limited-run");
    asset_run_begin("limited-run");
    auto refused = limited.call("assets.generate_image", candidate_args("assets/q.png", 2));
    REQUIRE_FALSE(refused.ok);
    CHECK(refused.error["code"] == "asset_cost_limit");
    CHECK_FALSE(limited.exists("assets/q.candidate-1.png"));
}

TEST_CASE("AssetCostGuard::commit_part keeps the share of what was made and gives the rest back") {
    Game game(config_from(paid_config(R"({"askAboveUsd":5})")));
    AssetRunScope run("part-run");
    asset_run_begin("part-run");
    AiConfig cfg = config_from(paid_config(R"({"askAboveUsd":5})"));
    AssetRequest req;
    req.kind = MediaKind::Image;
    req.width = 16;
    req.height = 16;
    AssetCall call;
    call.command = "assets.generate_image";
    call.what = "test";
    call.projectDir = game.dir.str();
    call.provider = "paid";
    call.kind = MediaKind::Image;
    call.estimate = estimate_asset_cost(*cfg.provider("paid"), req, 4);
    {
        AssetCostGuard guard = AssetCostGuard::begin(cfg.limits, call, false);
        REQUIRE(guard.go());
        CHECK(asset_run_spent("part-run") == doctest::Approx(1.20));
        CHECK(guard.commit_part(1, 4) == doctest::Approx(0.30));
    }
    CHECK(asset_run_spent("part-run") == doctest::Approx(0.30));
    {
        AssetCostGuard guard = AssetCostGuard::begin(cfg.limits, call, false);
        REQUIRE(guard.go());
        CHECK(guard.commit_part(0, 4) == doctest::Approx(0.0));
    }
    CHECK(asset_run_spent("part-run") == doctest::Approx(0.30));
}

TEST_CASE("assets.generate_image count: a provider failure part way says what was made and what it cost, and keeps it") {
    Wire wire;
    wire.replies = {Wire::reply(200, fixture("openai_image.json")), Wire::reply(401, fixture("openai_error_401.json"))};
    Game game(config_from(R"({"assets":{"image":{"provider":"openai"}},"limits":{"askAboveUsd":100}})"),
              wire.runtime({{"OPENAI_API_KEY", "sk-test-0123456789abcdef"}}));
    auto r = game.call("assets.generate_image", candidate_args("assets/m.png", 3));
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "generation_failed");
    const std::string message = r.error["message"].get<std::string>();
    CHECK(has(message, "candidate 2 of 3"));
    CHECK(has(message, "assets/m.candidate-1.png"));
    CHECK(has(message, "Estimated cost of what was made"));
    REQUIRE(r.error.contains("data"));
    CHECK(r.error["data"]["written"] == Json::array({"assets/m.candidate-1.png"}));
    CHECK(r.error["data"]["failedCandidate"] == 2);
    CHECK(game.exists("assets/m.candidate-1.png"));
    CHECK(game.provenance("assets/m.candidate-1.png")["candidate"]["n"] == 1);
    CHECK_FALSE(game.exists("assets/m.candidate-2.png"));
    CHECK_FALSE(game.exists(".factoria/review/sheet-0001"));  // no sheet for a batch that failed
    CHECK(wire.requests.size() == 2);                         // it stopped at the failure
}

TEST_CASE("assets.pick: the chosen candidate becomes the slot with its provenance, the others move to the candidates folder") {
    Game game(config_from(paid_config(R"({"askAboveUsd":5})")));
    Json args = candidate_args("assets/items/potion.png", 3);
    args["seed"] = 7;
    const Json made = game.ok("assets.generate_image", args);
    const std::string sheet = made["sheet"].get<std::string>();
    const std::string second = game.file("assets/items/potion.candidate-2.png");

    const Json r = game.ok("assets.pick", {{"slot", "assets/items/potion.png"}, {"n", 2}, {"note", "the clearest"}});
    CHECK(r["slot"] == "assets/items/potion.png");
    CHECK(r["sheet"] == sheet);
    CHECK(r["n"] == 2);
    CHECK(r["candidate"] == "assets/items/potion.candidate-2.png");
    CHECK(r["replaced"] == false);
    CHECK(game.file("assets/items/potion.png") == second);
    CHECK_FALSE(game.exists("assets/items/potion.candidate-2.png"));
    CHECK_FALSE(game.exists("assets/items/potion.candidate-1.png"));
    CHECK_FALSE(game.exists("assets/items/potion.candidate-3.png"));
    const std::string drop = ".factoria/assets/candidates/" + sheet + "/";
    CHECK(game.exists(drop + "01_potion.candidate-1.png"));
    CHECK(game.exists(drop + "03_potion.candidate-3.png"));
    REQUIRE(r["dropped"].size() == 2);

    const Json assetsJson = game.manifest()["assets"];
    CHECK_FALSE(assetsJson.contains("assets/items/potion.candidate-1.png"));
    CHECK_FALSE(assetsJson.contains("assets/items/potion.candidate-2.png"));
    CHECK_FALSE(assetsJson.contains("assets/items/potion.candidate-3.png"));
    const Json prov = assetsJson["assets/items/potion.png"]["provenance"];
    CHECK(prov["origin"] == "generated");
    CHECK(prov["provider"] == "paid");
    CHECK(prov["seed"] == 8);
    CHECK(has(prov["prompt"].get<std::string>(), "a red potion bottle"));
    CHECK_FALSE(prov.contains("candidate"));
    CHECK(prov["candidates"]["sheet"] == sheet);
    CHECK(prov["candidates"]["picked"] == 2);
    CHECK(prov["candidates"]["count"] == 3);
    CHECK(prov["candidates"]["estimatedCostUsd"] == doctest::Approx(0.90));
    CHECK(prov["candidates"]["costIsEstimate"] == true);
    for (const Json& w : r["warnings"]) CHECK_FALSE(has(w.get<std::string>(), "still lists"));

    const Json manifest = Json::parse(game.file(".factoria/review/" + sheet + "/manifest.json"));
    CHECK(manifest["picked"]["n"] == 2);
    CHECK(manifest["picked"]["note"] == "the clearest");

    // Picking again: already_picked, and the hint says how to choose again
    auto again = game.call("assets.pick", {{"slot", "assets/items/potion.png"}, {"n", 1}});
    REQUIRE_FALSE(again.ok);
    CHECK(again.error["code"] == "already_picked");
    CHECK(has(again.error["hint"].get<std::string>(), "count"));
    auto bySheet = game.call("assets.pick", {{"slot", "assets/items/potion.png"}, {"n", 1}, {"sheet", sheet}});
    REQUIRE_FALSE(bySheet.ok);
    CHECK(bySheet.error["code"] == "already_picked");

    // review.cleanup deletes the dropped candidates 7 days later (the same cleaner as every sheet)
    ShareEnv later = scratch_home_env(game.home.str());
    later.now = [] { return std::int64_t(1800000000) + 8 * 86400; };
    ScopedShareEnv scoped(later);
    const ReviewOutcome cleaned = review_cleanup(game.dir.str(), {});
    REQUIRE_MESSAGE(cleaned.ok, cleaned.message);
    CHECK_FALSE(game.exists(drop + "01_potion.candidate-1.png"));
    CHECK_FALSE(game.exists(drop + "03_potion.candidate-3.png"));
    CHECK(game.exists("assets/items/potion.png"));
}

TEST_CASE("assets.pick: a slot with no candidates is not_found with a suggestion; a sheet of another slot is refused") {
    Game game(fake_config());
    const Json made = game.ok("assets.generate_image", candidate_args("assets/items/potion.png", 2));
    auto r = game.call("assets.pick", {{"slot", "assets/items/potoin.png"}, {"n", 1}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "not_found");
    CHECK(has(r.error["message"].get<std::string>(), "/slot"));
    CHECK(has(r.error["message"].get<std::string>(), "assets/items/potion.png"));  // did you mean

    game.ok("assets.generate_image", candidate_args("assets/items/sword.png", 2));
    r = game.call("assets.pick", {{"slot", "assets/items/sword.png"}, {"n", 1}, {"sheet", made["sheet"]}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "invalid_argument");
    CHECK(has(r.error["message"].get<std::string>(), "/sheet"));
    CHECK(game.exists("assets/items/sword.candidate-1.png"));

    // a slot outside assets/
    r = game.call("assets.pick", {{"slot", "outside.png"}, {"n", 1}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "invalid_path");
    CHECK(has(r.error["message"].get<std::string>(), "/slot"));

    // case does not matter for the slot (Windows and macOS paths)
    const Json picked = game.ok("assets.pick", {{"slot", "assets/items/Sword.png"}, {"n", 2}});
    CHECK(picked["slot"] == "assets/items/sword.png");  // the sheet's spelling, so the file is the same on every system
    CHECK(game.exists("assets/items/sword.png"));
}

TEST_CASE("assets.pick: a move that fails puts everything back (the chosen file is open elsewhere)") {
    Game game(fake_config());
    game.ok("assets.generate_image", candidate_args("assets/hero.png", 3));
    const Json before = game.manifest();
    const bool rulesBefore = fs::windows_rules();
    fs::set_windows_rules(true);
    {
        fs::ReadStream open(game.dir.path / "assets/hero.candidate-2.png", std::ios::binary);  // a viewer holds the chosen file
        REQUIRE(open.is_open());
        auto r = game.call("assets.pick", {{"slot", "assets/hero.png"}, {"n", 2}});
        REQUIRE_FALSE(r.ok);
        CHECK(r.error["code"] == "busy");
        CHECK(has(r.error["message"].get<std::string>(), "put back"));
    }
    fs::set_windows_rules(rulesBefore);
    for (int i = 1; i <= 3; ++i) CHECK(game.exists("assets/hero.candidate-" + std::to_string(i) + ".png"));
    CHECK_FALSE(game.exists("assets/hero.png"));
    CHECK(game.manifest() == before);
    CHECK(Json::parse(game.file(".factoria/review/sheet-0001/manifest.json")).value("picked", Json(nullptr)).is_null());

    // once the file is free the same pick works
    game.ok("assets.pick", {{"slot", "assets/hero.png"}, {"n", 2}});
    CHECK(game.exists("assets/hero.png"));
}

TEST_CASE("assets.pick: an existing slot needs overwrite and is kept in the drop folder") {
    Game game(fake_config());
    Json args = candidate_args("assets/tile.png", 2);
    game.ok("assets.generate_image", args);
    const std::string old = png_bytes(4, 4, 9, 9, 9);
    game.put("assets/tile.png", old);
    auto r = game.call("assets.pick", {{"slot", "assets/tile.png"}, {"n", 1}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "exists");
    CHECK(game.exists("assets/tile.candidate-1.png"));
    CHECK(game.exists("assets/tile.candidate-2.png"));

    const Json picked = game.ok("assets.pick", {{"slot", "assets/tile.png"}, {"n", 1}, {"overwrite", true}});
    CHECK(picked["replaced"] == true);
    CHECK(picked["oldFile"] == ".factoria/assets/candidates/sheet-0001/00_tile.png");
    CHECK(game.file(".factoria/assets/candidates/sheet-0001/00_tile.png") == old);
    CHECK(game.file("assets/tile.png") != old);

    // the old file is deleted with the dropped candidate 7 days later
    ShareEnv later = scratch_home_env(game.home.str());
    later.now = [] { return std::int64_t(1800000000) + 8 * 86400; };
    ScopedShareEnv scoped(later);
    REQUIRE(review_cleanup(game.dir.str(), {}).ok);
    CHECK_FALSE(game.exists(".factoria/assets/candidates/sheet-0001/00_tile.png"));
    CHECK_FALSE(game.exists(".factoria/assets/candidates/sheet-0001/02_tile.candidate-2.png"));
}

TEST_CASE("assets.generate_image count and assets.pick in a project folder with accents") {
    TempDir root;
    TempDir home;
    ScopedShareEnv scoped(scratch_home_env(home.str()));
    const fsys::path project = root.path / fsys::path(u8"juego ñandú é");
    fsys::create_directories(project);
    const std::string projectDir = project.string();  // the native narrow form, as the CLI and the editor pass it
    asset_run_begin("");
    CommandRegistry registry;
    AiCommandOptions opt;
    const AiConfig cfg = fake_config();
    opt.loadConfig = [cfg] { return Result<AiConfig>(cfg); };
    opt.projectDir = [projectDir] { return projectDir; };
    register_ai_commands(registry, std::move(opt));

    // The asset names stay ASCII: project-relative names go through fa::fs, whose Windows form of a non-ASCII name is another matter.
    auto made = registry.call("assets.generate_image", candidate_args("assets/hero.png", 2));
    REQUIRE_MESSAGE(made.ok, made.error.dump());
    CHECK(fsys::exists(project / "assets/hero.candidate-1.png"));
    CHECK(fsys::exists(project / ".factoria/review/sheet-0001/sheet.png"));
    auto picked = registry.call("assets.pick", {{"slot", "assets/hero.png"}, {"n", 1}});
    REQUIRE_MESSAGE(picked.ok, picked.error.dump());
    CHECK(fsys::exists(project / "assets/hero.png"));
    CHECK(fsys::exists(project / ".factoria/assets/candidates/sheet-0001/02_hero.candidate-2.png"));
    CHECK_FALSE(fsys::exists(project / "assets/hero.candidate-2.png"));
    CHECK(Json::parse(read_file((project / "assets.json").string()))["assets"]["assets/hero.png"]["provenance"]["candidates"]["picked"] == 1);
}
