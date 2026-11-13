// One source of truth for what the recipe commands write: every command that records a provenance.recipe is run once in a scratch
// project, and the assets.json it wrote must pass schemas/assets.schema.json (project.validate checks it). A recipe command that writes a
// provenance kind the schema does not know fails here. The commands are found in the sources too, so a new one has to be added to the
// list below (or to kNeedsOwnSetup with the reason) before the suite passes.
#include <doctest.h>

#include <format>
#include <map>
#include <regex>
#include <set>

#include "asset_test_helpers.h"
#include "audio_test_wav.h"
#include "fa/tooling/validate.h"
#include "fa_test_paths.h"

using namespace fa;
using namespace fa::testing;

namespace {

// Recipe commands this test does not run, and why.
const std::set<std::string> kNeedsOwnSetup = {
    "assets.bake_sheet",  // renders a prefab: needs a GPU (assets_recipe_test.cpp skips without one)
};

const char* kSvg = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64' width='64' height='64'><rect x='0' "
                   "y='0' width='32' height='32' fill='#ff0000'/></svg>";
const char* kBlip = R"({"format": "factoria.sfx/1", "doc": "test blip", "length": 0.15, "layers": [
    {"oscillators": [{"wave": "square", "duty": 0.25}], "pitch": {"note": "A4"}, "amp": {"attack": 0.002, "decay": 0.1, "sustain": 0}}]})";
const char* kDoor =
    R"({"format": "factoria.audio/1", "doc": "test door", "source": "assets/raw/door.wav", "steps": [{"type": "trim", "start": 0.2, "end": 0.8}]})";
const char* kCoin = "export default function frame({progress, params}) {\n"
                    "  const w = Math.abs(Math.cos(progress * Math.PI * 2)) * 30 + 6;\n"
                    "  return `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><ellipse cx='50' cy='50' "
                    "rx='${w}' ry='30' fill='#e8c66a'/></svg>`;\n"
                    "}\n";
const char* kHeroSvg = R"(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
  <g id="leg_l"><rect x="75" y="150" width="20" height="45" fill="#336"/></g>
  <g id="leg_r"><rect x="105" y="150" width="20" height="45" fill="#336"/></g>
  <g id="torso"><rect x="68" y="80" width="64" height="75" rx="10" fill="#a33"/>
    <g id="head"><circle cx="100" cy="50" r="28" fill="#fc9"/></g></g>
</svg>)";

// A person of height proportional to `k` (the same layout as anim3d_test.cpp's).
std::string person(double k) {
    auto n = [&](double v) { return std::format("{:.4f}", v * k); };
    return "{\"format\":\"factoria.model/1\",\"nodes\":[" + std::string("{\"op\":\"box\",\"size\":[") + n(0.36) + "," +
           n(0.2) + "," + n(0.2) + "],\"position\":[0," + n(0.95) + ",0],\"part\":\"pelvis\"}," +
           "{\"op\":\"box\",\"size\":[" + n(0.4) + "," + n(0.5) + "," + n(0.22) + "],\"position\":[0," + n(1.3) +
           ",0],\"part\":\"torso\"}," + "{\"op\":\"box\",\"size\":[" + n(0.1) + "," + n(0.1) + "," + n(0.1) +
           "],\"position\":[0," + n(1.6) + ",0],\"part\":\"neck\"}," + "{\"op\":\"box\",\"size\":[" + n(0.22) + "," +
           n(0.25) + "," + n(0.22) + "],\"position\":[0," + n(1.77) + "," + n(0.02) + "],\"part\":\"head\"}," +
           "{\"op\":\"box\",\"size\":[" + n(0.7) + "," + n(0.1) + "," + n(0.1) + "],\"position\":[" + n(0.55) + "," +
           n(1.5) + ",0],\"part\":\"arm_l\"}," + "{\"op\":\"box\",\"size\":[" + n(0.7) + "," + n(0.1) + "," + n(0.1) +
           "],\"position\":[" + n(-0.55) + "," + n(1.5) + ",0],\"part\":\"arm_r\"}," + "{\"op\":\"box\",\"size\":[" +
           n(0.14) + "," + n(0.9) + "," + n(0.14) + "],\"position\":[" + n(0.11) + "," + n(0.45) +
           ",0],\"part\":\"leg_l\"}," + "{\"op\":\"box\",\"size\":[" + n(0.14) + "," + n(0.9) + "," + n(0.14) +
           "],\"position\":[" + n(-0.11) + "," + n(0.45) + ",0],\"part\":\"leg_r\"}]}";
}

// The errors project.validate finds in assets.json (the schema check) after the command named `what`.
void check_manifest(const AssetsProject& p, const std::string& what) {
    for (const ValidationIssue& e : validate_project(p.dir).errors)
        if (e.file == "assets.json")
            FAIL_CHECK(what << " wrote an assets.json that breaks schemas/assets.schema.json: " << e.to_string());
}

void run(const AssetsProject& p, const std::string& command, const Json& args) {
    INFO("command " << command);
    p.ok(command, args);
    check_manifest(p, command);
}

// Files that call make_recipe with a command that is a parameter, not a literal or a constant, and why that is fine here.
const std::set<std::string> kVariableCommandFiles = {
    "assets_anim3d.cpp",  // made_clip_provenance forwards its `command` parameter; its callers pass literals, which are found below
};

// Function-local constants passed as the command of a recipe ("file:name" -> command); the scan only resolves constants at file scope.
const std::map<std::string, std::string> kLocalCommandConstants = {
    {"assets_audio.cpp:cmd", "assets.generate_loop"},
};

// The recipe commands named in the sources: the second argument of every make_recipe(projectDir, X, ...) and made_clip_provenance(projectDir, X, ...)
// call, X being a string literal or a name set to one in the same file (`constexpr const char* kCommand = "x.y"`). An argument of any other
// shape (a variable) fails unless its file is in kVariableCommandFiles, so a recipe command cannot be missed by the scan.
std::set<std::string> recipe_commands_in_sources() {
    namespace stdfs = std::filesystem;
    std::set<std::string> found;
    const std::regex call(R"re((?:make_recipe|made_clip_provenance)\(\s*projectDir,\s*("[a-z0-9_.]+"|\w+)\s*,)re");
    for (const char* dir : {"tools/common/src", "tools/ai/src"}) {
        for (const auto& entry : stdfs::directory_iterator(stdfs::path(FA_REPO_ROOT) / dir)) {
            if (entry.path().extension() != ".cpp") continue;
            const std::string text = read_all(entry.path());
            if (text.find("make_recipe(") == std::string::npos &&
                text.find("made_clip_provenance(") == std::string::npos)
                continue;
            for (std::sregex_iterator it(text.begin(), text.end(), call), end; it != end; ++it) {
                const std::string arg = (*it)[1];
                if (arg.front() == '"') {
                    found.insert(arg.substr(1, arg.size() - 2));
                    continue;
                }
                // a constant at file scope (column 0: `constexpr const char* kCommand = "x.y";`), not a local of a function
                const std::regex named("(?:^|\n)(?:static )?(?:constexpr|const)[^\\n=(]*\\b" + arg +
                                       R"re(\s*=\s*"([a-z0-9_.]+)")re");
                std::set<std::string> values;
                for (std::sregex_iterator nit(text.begin(), text.end(), named), nend; nit != nend; ++nit)
                    values.insert((*nit)[1]);
                const auto local = kLocalCommandConstants.find(entry.path().filename().string() + ":" + arg);
                if (values.size() == 1)
                    found.insert(*values.begin());
                else if (values.size() > 1)
                    FAIL_CHECK(entry.path().filename().string()
                               << ": `" << arg
                               << "` is set to several commands at file scope, so the scan cannot tell which "
                                  "make_recipe uses: give each call a literal");
                else if (local != kLocalCommandConstants.end())
                    found.insert(local->second);
                else if (!kVariableCommandFiles.count(entry.path().filename().string()))
                    FAIL_CHECK(
                        entry.path().filename().string()
                        << " passes `" << arg
                        << "` as the command of a recipe, which is not a literal or a constant at file scope: use one, "
                           "list it in kLocalCommandConstants, or add the file to kVariableCommandFiles");
            }
        }
    }
    return found;
}

}  // namespace

TEST_CASE("every recipe command writes an assets.json that passes schemas/assets.schema.json") {
    AssetsProject p;
    write_all(p.file("assets/raw/door.wav"), sine_wav(1.0, -20.0));
    write_png(p.file("store/keyart.png"), make_image(1920, 1080, {120, 20, 20, 255}));
    write_png(p.file("art/a.png"), make_image(8, 8, {255, 0, 0, 255}));
    write_all(p.file("art/coin.anim.js"), kCoin);
    write_all(p.file("assets/models/hero.model.json"), person(1.0));
    write_all(p.file("assets/models/giant.model.json"), person(1.5));
    write_all(p.file("assets/art/hero.svg"), kHeroSvg);
    write_all(p.file("assets/audio/blip.sfx.json"), kBlip);
    write_all(p.file("assets/audio/door.audio.json"), kDoor);

    run(p, "assets.rasterize_svg", {{"path", "assets/raw.png"}, {"svg", kSvg}, {"width", 64}, {"ai", false}});
    run(p, "assets.slice_sheet",
        {{"path", "assets/raw.png"}, {"columns", 2}, {"rows", 1}, {"out", "assets/raw_grid.png"}});
    run(p, "assets.draw_icon",
        Json::parse(
            R"({"background":{"shape":"rounded","color":"#223355"},"layers":[{"type":"circle","x":50,"y":50,"radius":30,"fill":"#ffcc44"}]})"));
    run(p, "assets.generate_texture",
        {{"path", "assets/tex/paper.png"}, {"preset", "paper"}, {"width", 64}, {"height", 64}});
    run(p, "assets.synth_sound", {{"path", "assets/audio/coin.wav"}, {"preset", "coin"}});
    run(p, "assets.generate_loop", {{"path", "assets/audio/wind.wav"}, {"kind", "noise"}, {"seconds", 2}});
    run(p, "assets.draw_capsules", {{"keyArt", "store/keyart.png"}, {"stores", {"itch"}}, {"name", "Demo Game"}});
    run(p, "assets.pack_atlas", {{"folder", "art"}, {"out", "assets/atlas.png"}, {"table", "data/atlas.json"}});
    run(p, "assets.animate_svg",
        {{"path", "assets/art/coin.png"},
         {"source", "art/coin.anim.js"},
         {"frames", 4},
         {"fps", 10},
         {"frameWidth", 32},
         {"frameHeight", 32}});
    run(p, "audio.bake", {{"path", "assets/audio/door.audio.json"}});
    run(p, "sfx.render", {{"path", "assets/audio/blip.sfx.json"}, {"picture", false}});
    run(p, "music.create", {{"path", "assets/music/theme.song.json"}, {"picture", false}, {"arpeggio", false}});
    run(p, "music.preview", {{"path", "assets/music/theme.song.json"}, {"sampleRate", 22050}, {"picture", false}});
    run(p, "music.render", {{"path", "assets/music/theme.song.json"}, {"sampleRate", 22050}});
    run(p, "image.create",
        {{"path", "assets/src/sky.image.json"},
         {"width", 16},
         {"height", 16},
         {"background", "#203040"},
         {"output", "assets/art/sky.png"}});
    run(p, "image.tileset.build",
        {{"path", "assets/art/ground.image.json"},
         {"mode", "basic16"},
         {"tileWidth", 8},
         {"tileHeight", 8},
         {"parts",
          {{"inside", {{"color", "#00ff00"}}}, {"edge", {{"color", "#0000ff"}}}, {"corner", {{"color", "#ff0000"}}}}}});
    run(p, "model.create", {{"path", "assets/models/crate.model.json"}, {"nodes", Json::array({{{"op", "box"}}})}});
    run(p, "rig.create",
        {{"path", "assets/models/hero.rig.json"},
         {"model", "assets/models/hero.model.json"},
         {"template", "humanoid"}});
    run(p, "rig.create",
        {{"path", "assets/models/giant.rig.json"},
         {"model", "assets/models/giant.model.json"},
         {"template", "humanoid"}});
    run(p, "vector.to_rig", {{"source", "assets/art/hero.svg"}, {"pixelsPerUnit", 4}});
    run(p, "anim3d.generate",
        {{"rig", "assets/models/hero.rig.glb"}, {"kind", "walk"}, {"out", "anim/hero_walk.anim.json"}});
    run(p, "anim3d.retarget",
        {{"path", "anim/hero_walk.anim.json"},
         {"to", "assets/models/giant.rig.glb"},
         {"out", "anim/giant_walk.anim.json"}});
    run(p, "anim3d.create",
        {{"path", "anim/wave.anim.json"}, {"duration", 1.0}, {"rig", "assets/models/hero.rig.glb"}});

    // The commands this test ran are the ones whose recipes are in assets.json; every recipe command named in the sources must be one of them.
    std::set<std::string> ran;
    const Json manifest = p.manifest();
    for (const auto& [rel, entry] : manifest["assets"].items())
        if (entry.contains("provenance") && entry["provenance"].contains("recipe"))
            ran.insert(entry["provenance"]["recipe"]["command"].get<std::string>());
    const std::set<std::string> named = recipe_commands_in_sources();
    CHECK(named.count("anim3d.generate") == 1);  // the scan itself works
    for (const std::string& command : named) {
        if (kNeedsOwnSetup.count(command)) continue;
        CHECK_MESSAGE(ran.count(command),
                      command << " records a recipe but this test does not run it: add it to the list, so what it "
                                 "writes is checked against schemas/assets.schema.json");
    }
}
