// provenance.recipe and assets.regenerate: every offline maker records how to make its file again, regenerate re-runs that through
// the command registry (stale detection, order, what changed), and project.validate warns about stale assets and missing inputs.
#include <doctest.h>

#include <set>

#include "asset_test_helpers.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"

using namespace fa;
using namespace fa::testing;

namespace {

const char* kSvg =
    "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64' width='64' height='64'>"
    "<rect x='0' y='0' width='32' height='32' fill='#ff0000'/><circle cx='44' cy='44' r='12' fill='#0000ff'/></svg>";
const char* kSvgEdited =
    "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64' width='64' height='64'>"
    "<rect x='0' y='0' width='64' height='32' fill='#00ff00'/></svg>";

Json recipe_of_asset(const AssetsProject& p, const std::string& rel) {
    const Json m = p.manifest();
    REQUIRE_MESSAGE(m["assets"].contains(rel), rel);
    REQUIRE_MESSAGE(m["assets"][rel]["provenance"].contains("recipe"), rel);
    return m["assets"][rel]["provenance"]["recipe"];
}

// Spoils the file, regenerates it from its recipe and checks the bytes are back.
void regenerates_same_bytes(const AssetsProject& p, const std::string& rel) {
    const std::string original = read_all(p.file(rel));
    REQUIRE_FALSE(original.empty());
    write_all(p.file(rel), "spoiled");
    const Json r = p.ok("assets.regenerate", {{"path", rel}});
    CHECK_MESSAGE(read_all(p.file(rel)) == original, rel);
    CHECK(r["count"] == 1);
    CHECK(r["regenerated"][0]["changes"][rel]["result"] == "bytes changed");  // "spoiled" is not even a picture
}

// Writes a provenance record the way assets.set_provenance would (that command lives in fa_ai, not in the tooling tests).
void set_provenance(const AssetsProject& p, const std::string& rel, const Json& fields) {
    Json m = std::filesystem::exists(p.file("assets.json")) ? p.manifest() : Json{{"format", "factoria.assets/1"}, {"assets", Json::object()}};
    Json& prov = m["assets"][rel]["provenance"];
    if (!prov.is_object()) prov = Json{{"date", "2026-10-29"}};
    for (const auto& [k, v] : fields.items()) prov[k] = v;
    write_all(p.file("assets.json"), m.dump(2));
}

const ValidationIssue* issue_with(const std::vector<ValidationIssue>& list, const std::string& needle) {
    for (const ValidationIssue& i : list)
        if (i.message.find(needle) != std::string::npos) return &i;
    return nullptr;
}

}  // namespace

TEST_CASE("recipes: rasterize_svg records its source with a hash, an explicit seed and project paths") {
    AssetsProject p;
    write_all(p.file("assets/art/coin.svg"), kSvg);
    p.ok("assets.rasterize_svg", {{"path", "assets/art/./coin.png"}, {"source", "assets/art/coin.svg"}, {"width", 64}, {"style", "paper"}});
    const Json recipe = recipe_of_asset(p, "assets/art/coin.png");
    CHECK(recipe["command"] == "assets.rasterize_svg");
    CHECK(recipe["args"]["path"] == "assets/art/coin.png");
    CHECK(recipe["args"]["seed"] == 0);  // explicit even though the caller left it out
    CHECK_FALSE(recipe["args"].contains("overwrite"));
    REQUIRE(recipe["inputs"].size() == 1);
    CHECK(recipe["inputs"][0]["path"] == "assets/art/coin.svg");
    CHECK(recipe["inputs"][0]["sha256"].get<std::string>().size() == 64);
    regenerates_same_bytes(p, "assets/art/coin.png");
}

TEST_CASE("recipes: an SVG given as text regenerates too (the text is in the args, no input)") {
    AssetsProject p;
    p.ok("assets.rasterize_svg", {{"path", "assets/art/inline.png"}, {"svg", kSvg}, {"style", "watercolor"}, {"seed", 7}});
    const Json recipe = recipe_of_asset(p, "assets/art/inline.png");
    CHECK_FALSE(recipe.contains("inputs"));
    CHECK(recipe["args"]["seed"] == 7);
    regenerates_same_bytes(p, "assets/art/inline.png");
}

TEST_CASE("recipes: draw_icon, generate_texture, synth_sound and generate_loop regenerate their own bytes") {
    AssetsProject p;
    p.ok("assets.draw_icon", Json::parse(R"({"background":{"shape":"rounded","color":"#223355"},"layers":[{"type":"circle","x":50,"y":50,"radius":30,"fill":"#ffcc44"}]})"));
    // the icon and its Android foreground are one call: the recipe is the same and records the paths the call chose
    const Json icon = recipe_of_asset(p, "assets/icon.png");
    CHECK(icon["args"]["path"] == "assets/icon.png");
    CHECK(icon["args"]["foreground"] == "assets/icon_fg.png");
    CHECK(recipe_of_asset(p, "assets/icon_fg.png") == icon);
    regenerates_same_bytes(p, "assets/icon.png");

    p.ok("assets.generate_texture", {{"path", "assets/tex/paper.png"}, {"preset", "paper"}, {"width", 64}, {"height", 64}, {"normalMap", true}});
    CHECK(recipe_of_asset(p, "assets/tex/paper.png")["args"]["seed"] == 0);
    regenerates_same_bytes(p, "assets/tex/paper.png");
    regenerates_same_bytes(p, "assets/tex/paper_n.png");

    p.ok("assets.synth_sound", {{"path", "assets/audio/coin.wav"}, {"preset", "coin"}});
    const Json sound = recipe_of_asset(p, "assets/audio/coin.wav");
    CHECK(sound["args"]["seconds"].is_number());  // the preset's length, made explicit
    regenerates_same_bytes(p, "assets/audio/coin.wav");

    p.ok("assets.generate_loop", {{"path", "assets/audio/wind.wav"}, {"kind", "noise"}, {"seconds", 2}, {"color", "pink"}});
    CHECK(recipe_of_asset(p, "assets/audio/wind.wav")["args"]["sampleRate"] == 22050);
    regenerates_same_bytes(p, "assets/audio/wind.wav");
    p.ok("assets.generate_loop", {{"path", "assets/audio/wind.ogg"}, {"kind", "noise"}, {"seconds", 2}, {"seed", 3}});
    regenerates_same_bytes(p, "assets/audio/wind.ogg");
}

TEST_CASE("recipes: draw_capsules records the key art and the logo, and its files regenerate") {
    AssetsProject p;
    write_png(p.file("store/keyart.png"), make_image(1920, 1080, {120, 20, 20, 255}));
    write_png(p.file("assets/logo.png"), make_image(200, 80, {255, 255, 255, 255}));
    p.ok("assets.draw_capsules", {{"keyArt", "store/keyart.png"}, {"logo", {{"image", "assets/logo.png"}}}, {"stores", {"itch"}}, {"name", "Demo Game"}});
    std::string any;
    const Json manifest = p.manifest();
    for (const auto& [rel, entry] : manifest["assets"].items())
        if (rel.rfind("store/capsules/itch/", 0) == 0) any = rel;
    REQUIRE_MESSAGE(!any.empty(), p.manifest().dump());
    const Json recipe = recipe_of_asset(p, any);
    CHECK(recipe["command"] == "assets.draw_capsules");
    CHECK(recipe["args"]["name"] == "demo-game");  // the name the file names were made from
    std::set<std::string> inputs;
    for (const Json& in : recipe["inputs"]) inputs.insert(in["path"].get<std::string>());
    CHECK(inputs == std::set<std::string>{"store/keyart.png", "assets/logo.png"});
    regenerates_same_bytes(p, any);
}

TEST_CASE("recipes: pack_atlas records its frames, and the atlas regenerates") {
    AssetsProject p;
    write_png(p.file("art/a.png"), make_image(8, 8, {255, 0, 0, 255}));
    write_png(p.file("art/b.png"), make_image(12, 6, {0, 255, 0, 255}));
    p.ok("assets.pack_atlas", {{"folder", "art"}, {"out", "assets/atlas.png"}, {"table", "data/atlas.json"}});
    const Json recipe = recipe_of_asset(p, "assets/atlas.png");
    CHECK(recipe["command"] == "assets.pack_atlas");
    CHECK(recipe["inputs"].size() == 2);
    const std::string table = read_all(p.file("data/atlas.json"));
    regenerates_same_bytes(p, "assets/atlas.png");
    CHECK(read_all(p.file("data/atlas.json")) == table);
}

TEST_CASE("recipes: slice_sheet records the source it was cut from; a sheet cut in place or from an unrecorded image has none") {
    AssetsProject p;
    // a 2x1 grid picture whose cells hold a shape each, made by rasterize_svg (so it has a provenance record)
    p.ok("assets.rasterize_svg", {{"path", "assets/raw.png"}, {"svg", kSvg}, {"width", 64}, {"ai", false}});
    const Json r = p.ok("assets.slice_sheet", {{"path", "assets/raw.png"}, {"columns", 2}, {"rows", 1}, {"out", "assets/raw_grid.png"}});
    CHECK(r["written"] == true);
    const Json recipe = recipe_of_asset(p, "assets/raw_grid.png");
    CHECK(recipe["command"] == "assets.slice_sheet");
    CHECK(recipe["inputs"][0]["path"] == "assets/raw.png");
    // the source's own recipe stays the source's
    CHECK(recipe_of_asset(p, "assets/raw.png")["command"] == "assets.rasterize_svg");
    regenerates_same_bytes(p, "assets/raw_grid.png");
    CHECK(p.manifest()["assets"]["assets/raw_grid.png"]["sheet"]["columns"] == 2);

    // grid mode with no new file: only the `sheet` is recorded, the image keeps the recipe it had
    p.ok("assets.slice_sheet", {{"path", "assets/raw.png"}, {"columns", 2}, {"rows", 1}});
    CHECK(recipe_of_asset(p, "assets/raw.png")["command"] == "assets.rasterize_svg");

    // an image with no provenance: the sheet gets none and no recipe, and the result says why
    write_png(p.file("assets/plain.png"), make_image(32, 16, {9, 9, 9, 255}));
    const CommandResult plain = p.call("assets.slice_sheet", {{"path", "assets/plain.png"}, {"columns", 2}, {"out", "assets/plain_sheet.png"}});
    REQUIRE(plain.ok);
    CHECK(has_warning(plain.result, "no provenance record"));
    CHECK_FALSE(p.manifest()["assets"]["assets/plain_sheet.png"].contains("provenance"));

    // output over its own input: the source is gone, so no recipe (and the result says so)
    const CommandResult inPlace = p.call("assets.slice_sheet", {{"path", "assets/raw_grid.png"}, {"columns", 2}, {"out", "assets/raw_grid.png"}});
    REQUIRE(inPlace.ok);
    CHECK(has_warning(inPlace.result, "no recipe was recorded"));
    CHECK_FALSE(p.manifest()["assets"]["assets/raw_grid.png"]["provenance"].contains("recipe"));
}

TEST_CASE("assets.regenerate: stale detection, order of dependent assets, and what changed") {
    AssetsProject p;
    write_all(p.file("assets/art/coin.svg"), kSvg);
    p.ok("assets.rasterize_svg", {{"path", "assets/art/coin.png"}, {"source", "assets/art/coin.svg"}, {"width", 64}, {"ai", false}});
    p.ok("assets.slice_sheet", {{"path", "assets/art/coin.png"}, {"columns", 2}, {"rows", 2}, {"out", "assets/art/coin_sheet.png"}});

    Json none = p.ok("assets.regenerate", {{"stale", true}});
    CHECK(none["count"] == 0);
    CHECK(none["skipped"].size() == 2);

    write_all(p.file("assets/art/coin.svg"), kSvgEdited);
    const Json plan = p.ok("assets.regenerate", {{"stale", true}, {"dryRun", true}});
    CHECK(plan["dryRun"] == true);
    REQUIRE(plan["wouldRun"].size() == 1);  // the sheet's input (the picture) has not changed yet
    CHECK(plan["wouldRun"][0]["command"] == "assets.rasterize_svg");
    CHECK(plan["wouldRun"][0]["changedInputs"][0] == "assets/art/coin.svg");
    CHECK(read_all(p.file("assets/art/coin.svg")) == kSvgEdited);  // dryRun changes nothing

    const Image before = read_png(p.file("assets/art/coin.png"));
    const Json r = p.ok("assets.regenerate", {{"stale", true}});
    REQUIRE(r["count"] == 2);  // the picture, then the sheet cut from it (stale only once the picture was made again)
    CHECK(r["regenerated"][0]["command"] == "assets.rasterize_svg");
    CHECK(r["regenerated"][0]["changes"]["assets/art/coin.png"]["result"] == "pixels changed");
    CHECK(r["regenerated"][1]["command"] == "assets.slice_sheet");
    CHECK(r["regenerated"][1]["changes"]["assets/art/coin_sheet.png"]["result"] == "pixels changed");
    CHECK(read_png(p.file("assets/art/coin.png")).rgba != before.rgba);
    CHECK(read_png(p.file("assets/art/coin_sheet.png")).rgba == read_png(p.file("assets/art/coin.png")).rgba);
    CHECK(p.ok("assets.regenerate", {{"stale", true}})["count"] == 0);

    // one path: runs even when up to date, and says "unchanged"
    const Json again = p.ok("assets.regenerate", {{"path", "assets/art/coin.png"}});
    CHECK(again["regenerated"][0]["changes"]["assets/art/coin.png"]["result"] == "unchanged");
    CHECK(p.ok("assets.regenerate", {{"all", true}})["count"] == 2);
}

TEST_CASE("assets.regenerate: what a person recorded in the provenance survives, and a sliced-in-place grid is kept") {
    AssetsProject p;
    p.ok("assets.rasterize_svg", {{"path", "assets/art/coin.png"}, {"svg", kSvg}, {"width", 64}});
    set_provenance(p, "assets/art/coin.png", {{"origin", "original"}, {"author", "Ana"}, {"license", "CC-BY-4.0"}});
    p.ok("assets.slice_sheet", {{"path", "assets/art/coin.png"}, {"columns", 2}, {"rows", 2}});
    p.ok("assets.regenerate", {{"path", "assets/art/coin.png"}});
    const Json entry = p.manifest()["assets"]["assets/art/coin.png"];
    CHECK(entry["provenance"]["author"] == "Ana");
    CHECK(entry["provenance"]["license"] == "CC-BY-4.0");
    CHECK(entry["provenance"].contains("recipe"));
    CHECK(entry["sheet"]["columns"] == 2);
}

TEST_CASE("assets.regenerate: errors say what to do") {
    AssetsProject p;
    write_all(p.file("assets/art/coin.svg"), kSvg);
    p.ok("assets.rasterize_svg", {{"path", "assets/art/coin.png"}, {"source", "assets/art/coin.svg"}});

    // a missing input
    std::filesystem::remove(p.file("assets/art/coin.svg"));
    CommandResult r = p.call("assets.regenerate", {{"path", "assets/art/coin.png"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "missing_input");
    CHECK(r.error["message"].get<std::string>().find("assets/art/coin.svg") != std::string::npos);
    const Json bulk = p.ok("assets.regenerate", {{"all", true}});
    CHECK(bulk["failed"].size() == 1);
    CHECK(bulk["count"] == 0);

    // an asset a provider made
    write_png(p.file("assets/ai.png"), make_image(8, 8, {1, 2, 3, 255}));
    set_provenance(p, "assets/ai.png", {{"origin", "generated"}, {"ai", true}, {"provider", "openai"}, {"model", "gpt-image-1"}});
    r = p.call("assets.regenerate", {{"path", "assets/ai.png"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "not_regenerable");
    CHECK(r.error["message"].get<std::string>().find("cost money") != std::string::npos);

    // imported, unknown, no path
    write_png(p.file("assets/imp.png"), make_image(8, 8, {1, 2, 3, 255}));
    set_provenance(p, "assets/imp.png", {{"origin", "imported"}});
    CHECK(p.call("assets.regenerate", {{"path", "assets/imp.png"}}).error["code"] == "not_regenerable");
    CHECK(p.call("assets.regenerate", {{"path", "assets/nothing.png"}}).error["code"] == "not_found");
    CHECK(p.call("assets.regenerate", Json::object()).error["code"] == "invalid_argument");
    CHECK(p.call("assets.regenerate", {{"all", true}, {"stale", true}}).error["code"] == "invalid_argument");
}

TEST_CASE("assets.regenerate: only asset makers run, whatever a hand-edited recipe names") {
    AssetsProject p;
    p.ok("assets.rasterize_svg", {{"path", "assets/art/coin.png"}, {"svg", kSvg}});
    Json m = p.manifest();
    m["assets"]["assets/art/coin.png"]["provenance"]["recipe"]["command"] = "project.validate";
    write_all(p.file("assets.json"), m.dump(2));
    CommandResult r = p.call("assets.regenerate", {{"path", "assets/art/coin.png"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["code"] == "unknown_command");
    m["assets"]["assets/art/coin.png"]["provenance"]["recipe"]["command"] = "assets.rasterise_svg";
    write_all(p.file("assets.json"), m.dump(2));
    r = p.call("assets.regenerate", {{"path", "assets/art/coin.png"}});
    REQUIRE_FALSE(r.ok);
    CHECK(r.error["hint"].get<std::string>().find("assets.rasterize_svg") != std::string::npos);
}

TEST_CASE("recipes: project.validate warns about stale assets and missing inputs, with the regenerate command") {
    TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const std::string dir = tmp.sub("game");
    CommandRegistry registry;
    register_asset_commands(registry, dir);
    write_all(std::filesystem::path(dir) / "assets/art/coin.svg", kSvg);
    REQUIRE(registry.call("assets.rasterize_svg", {{"path", "assets/art/coin.png"}, {"source", "assets/art/coin.svg"}}).ok);
    CHECK(issue_with(validate_project(dir).warnings, "stale") == nullptr);

    write_all(std::filesystem::path(dir) / "assets/art/coin.svg", kSvgEdited);
    const ValidationReport stale = validate_project(dir);
    const ValidationIssue* s = issue_with(stale.warnings, "'assets/art/coin.png' is stale");
    REQUIRE(s != nullptr);
    CHECK(s->file == "assets.json");
    CHECK(s->pointer == "/assets/assets~1art~1coin.png/provenance/recipe");
    CHECK(s->hint.find("factoria call assets.regenerate '{\"path\":\"assets/art/coin.png\"}'") != std::string::npos);

    std::filesystem::remove(std::filesystem::path(dir) / "assets/art/coin.svg");
    const ValidationReport missing = validate_project(dir);
    const ValidationIssue* m = issue_with(missing.warnings, "no longer exists");
    REQUIRE(m != nullptr);
    CHECK(m->message.find("assets/art/coin.svg") != std::string::npos);
    CHECK_FALSE(m->hint.empty());
}

TEST_CASE("recipes: assets.animate_svg regenerates its own sheet byte for byte, goes stale with its module, and validate says so") {
    TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const std::string dir = tmp.sub("game");
    CommandRegistry registry;
    register_asset_commands(registry, dir);
    const std::filesystem::path root(dir);
    const char* module =
        "export default function frame({progress}) {\n"
        "  const w = Math.abs(Math.cos(progress * Math.PI * 2)) * 30 + 6;\n"
        "  return `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><ellipse cx='50' cy='50' rx='${w}' ry='30' fill='#e8c66a'/></svg>`;\n"
        "}\n";
    write_all(root / "art/coin.anim.js", module);
    const CommandResult made = registry.call("assets.animate_svg", {{"path", "assets/art/coin.png"}, {"source", "art/coin.anim.js"}, {"frames", 4},
                                                                      {"fps", 8}, {"frameWidth", 32}, {"frameHeight", 32}});
    REQUIRE_MESSAGE(made.ok, made.error.dump());
    CHECK(made.result["nextSteps"].dump().find("assets.regenerate") != std::string::npos);
    const std::string original = read_all(root / "assets/art/coin.png");
    write_all(root / "assets/art/coin.png", "spoiled");
    const CommandResult r = registry.call("assets.regenerate", {{"path", "assets/art/coin.png"}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(read_all(root / "assets/art/coin.png") == original);

    CHECK(issue_with(validate_project(dir).warnings, "stale") == nullptr);
    write_all(root / "art/coin.anim.js", std::string(module) + "// edited\n");  // the module is saved
    const ValidationReport report = validate_project(dir);
    const ValidationIssue* s = issue_with(report.warnings, "'assets/art/coin.png' is stale");
    REQUIRE(s != nullptr);
    CHECK(s->hint.find("assets.regenerate") != std::string::npos);
    CHECK(registry.call("assets.regenerate", {{"stale", true}}).result["count"] == 1);
    CHECK(issue_with(validate_project(dir).warnings, "stale") == nullptr);
}

TEST_CASE("recipes: assets.bake_sheet regenerates through the registry, and goes stale with its prefab (skipped without a GPU)") {
    TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const std::string dir = tmp.sub("game");
    CommandRegistry registry;
    register_asset_commands(registry, dir);
    const std::filesystem::path root(dir);
    const char* prefab = R"({"format":"factoria.prefab/1","entity":{"id":"orb","components":{
      "Transform":{},"Shape2D":{"shape":"circle","size":[20,20],"color":[1,0.5,0,1]}}}})";
    write_all(root / "prefabs/orb.prefab.json", prefab);
    const CommandResult made = registry.call("assets.bake_sheet", {{"path", "assets/fx/orb.png"}, {"prefab", "prefabs/orb.prefab.json"}, {"frames", 2}, {"fps", 4}});
    if (!made.ok && made.error.value("code", std::string()) == "no_gpu") {
        MESSAGE("skipped: no graphics device on this machine");
        return;
    }
    REQUIRE_MESSAGE(made.ok, made.error.dump());
    const std::string original = read_all(root / "assets/fx/orb.png");
    write_all(root / "assets/fx/orb.png", "spoiled");
    const CommandResult r = registry.call("assets.regenerate", {{"path", "assets/fx/orb.png"}});
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(read_all(root / "assets/fx/orb.png") == original);

    write_all(root / "prefabs/orb.prefab.json", std::string(R"({"format":"factoria.prefab/1","entity":{"id":"orb","components":{
      "Transform":{},"Shape2D":{"shape":"circle","size":[30,30],"color":[0,1,0,1]}}}})"));
    const ValidationReport report = validate_project(dir);
    const ValidationIssue* s = issue_with(report.warnings, "'assets/fx/orb.png' is stale");
    REQUIRE(s != nullptr);
    CHECK(registry.call("assets.regenerate", {{"stale", true}}).result["count"] == 1);
    CHECK(read_all(root / "assets/fx/orb.png") != original);
}
