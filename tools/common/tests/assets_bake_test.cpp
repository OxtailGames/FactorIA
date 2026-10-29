// assets.bake_sheet: an entity the engine draws, played in a private world and baked into a sprite sheet. The bake draws with
// the GPU of the machine, so these tests skip (with a message) where the engine finds no graphics device.
#include <doctest.h>

#include <filesystem>
#include <string>

#include "asset_test_helpers.h"
#include "fa/core/asset_manifest.h"
#include "fa/scene/components.h"
#include "fa/scene/sprite_animator.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/tooling.h"

using namespace fa;
using namespace fa::testing;
namespace stdfs = std::filesystem;

namespace {

struct BakeProject {
    TempDir tmp;
    std::string dir;
    CommandRegistry reg;
    BakeProject() {
        dir = tmp.str();
        auto made = create_project(dir, "2d-empty");
        REQUIRE_MESSAGE(made.ok(), "create_project failed");
        register_tooling_commands(reg, dir);
    }
    stdfs::path file(const std::string& rel) const { return stdfs::path(dir) / rel; }
    void put(const std::string& rel, const std::string& text) {
        stdfs::create_directories(file(rel).parent_path());
        write_all(file(rel), text);
    }
    Json manifest() const { return parse_json(read_all(file("assets.json")), "assets.json").value(); }
};

// Set when the machine has no graphics device: the test then returns early.
bool no_gpu(const CommandResult& r) {
    if (r.ok || r.error.value("code", std::string()) != "no_gpu") return false;
    MESSAGE("skipped: no graphics device on this machine (" << r.error.value("message", std::string()) << ")");
    return true;
}

std::string message(const CommandResult& r) { return r.error.value("message", std::string()) + " " + r.error.value("hint", std::string()); }

const char* kCirclePrefab = R"({"format":"factoria.prefab/1","entity":{"id":"orb","components":{
  "Transform":{},"Shape2D":{"shape":"circle","size":[20,20],"color":[1,0.5,0,1]},
  "Script":{"path":"scripts/pulse.js"}}}})";

const char* kPulseScript = R"(import { Behaviour, tween } from "factoria";
export default class Pulse extends Behaviour {
  onStart() { this.tween(this.entity.transform.scale, { x: 3, y: 3 }, { duration: 1 }); }
})";

const char* kBurstPrefab = R"({"format":"factoria.prefab/1","entity":{"id":"burst","components":{
  "Transform":{},"ParticleEmitter":{"emitting":false,"burst":60,"lifetime":1,"lifetimeVariance":0,"speed":200,"speedVariance":0,
    "spread":180,"gravity":[0,0,0],"startSize":6,"endSize":6,"startColor":[1,1,1,1],"endColor":[1,1,1,1]}}}})";

// An entity with a small fixed dot and a method that sends out a burst of particles.
const char* kBoomPrefab = R"({"format":"factoria.prefab/1","entity":{"id":"boom","components":{
  "Transform":{},"Shape2D":{"shape":"circle","size":[8,8]},
  "ParticleEmitter":{"emitting":false,"burst":0,"lifetime":1,"lifetimeVariance":0,"speed":150,"speedVariance":0,"spread":180,
    "gravity":[0,0,0],"startSize":6,"endSize":6,"startColor":[1,1,1,1],"endColor":[1,1,1,1]},
  "Script":{"path":"scripts/boom.js"}}}})";

const char* kBoomScript = R"(import { Behaviour } from "factoria";
export default class Boom extends Behaviour {
  explode(n) { this.entity.emitBurst(n || 40); }
})";

int opaque_pixels(const Image& img, int x0, int y0, int w, int h) {
    int n = 0;
    for (int y = y0; y < y0 + h; ++y)
        for (int x = x0; x < x0 + w; ++x) n += get(img, x, y).a > 0 ? 1 : 0;
    return n;
}

}  // namespace

TEST_CASE("assets.bake_sheet: a Shape2D with a tween bakes the same pixels twice, and records its sheet, provenance and recipe") {
    BakeProject p;
    p.put("prefabs/orb.prefab.json", kCirclePrefab);
    p.put("scripts/pulse.js", kPulseScript);
    const Json args = Json{{"path", "assets/fx/orb.png"}, {"prefab", "prefabs/orb.prefab.json"}, {"frames", 8}, {"fps", 8}};
    CommandResult a = p.reg.call("assets.bake_sheet", args);
    if (no_gpu(a)) return;
    REQUIRE_MESSAGE(a.ok, a.error.dump());
    const std::string first = read_all(p.file("assets/fx/orb.png"));
    CHECK(a.result["frames"] == 8);
    CHECK(a.result["$image"]["mimeType"] == "image/png");
    CHECK_FALSE(has_warning(a.result, "identical"));  // the tween makes the circle grow

    Json again = args;
    again["overwrite"] = true;
    CommandResult b = p.reg.call("assets.bake_sheet", again);
    REQUIRE_MESSAGE(b.ok, b.error.dump());
    CHECK(read_all(p.file("assets/fx/orb.png")) == first);  // fixed step, seeded world: the same pixels

    // The circle grows from a diameter of 20 to 60 over a second: the last frame is bigger than the first.
    const Image img = read_png(p.file("assets/fx/orb.png"));
    const int fw = a.result["frameWidth"].get<int>(), fh = a.result["frameHeight"].get<int>();
    CHECK(fw >= 20);
    const int pitchX = fw + 2, pitchY = fh + 2;
    const int cols = a.result["columns"].get<int>();
    const int firstArea = opaque_pixels(img, 1, 1, fw, fh);
    const int lastIndex = 7;
    const int lastArea = opaque_pixels(img, 1 + (lastIndex % cols) * pitchX, 1 + (lastIndex / cols) * pitchY, fw, fh);
    CHECK(lastArea > firstArea * 2);

    const Json m = p.manifest();
    const Json& e = m["assets"]["assets/fx/orb.png"];
    CHECK(e["sheet"]["frames"] == 8);
    CHECK(e["sheet"]["padding"] == 1);
    CHECK(e["sheet"]["frameWidth"] == fw);
    REQUIRE(e["sheet"]["pivot"].is_array());
    CHECK(e["provenance"]["origin"] == "generated");
    CHECK(e["provenance"]["ai"] == false);
    REQUIRE(e["provenance"].contains("recipe"));
    CHECK(e["provenance"]["recipe"]["command"] == "assets.bake_sheet");
    CHECK(e["provenance"]["recipe"]["args"]["prefab"] == "prefabs/orb.prefab.json");
    CHECK(e["provenance"]["recipe"]["args"]["seed"] == 1);
    bool hasPrefabInput = false, hasScriptInput = false;
    for (const Json& in : e["provenance"]["recipe"]["inputs"]) {
        hasPrefabInput = hasPrefabInput || in["path"] == "prefabs/orb.prefab.json";
        hasScriptInput = hasScriptInput || in["path"] == "scripts/pulse.js";
    }
    CHECK(hasPrefabInput);
    CHECK(hasScriptInput);
    CHECK_FALSE(stdfs::exists(p.file(".factoria/tmp/bake_sheet.scene.json")));  // the temporary scene is gone
}

TEST_CASE("assets.bake_sheet: antialiased edges have the colour of the shape, no dark fringe") {
    BakeProject p;
    p.put("prefabs/disc.prefab.json", R"({"format":"factoria.prefab/1","entity":{"id":"disc","components":{
        "Transform":{},"Shape2D":{"shape":"circle","size":[24,24],"color":[1,0.5,0,0.8]}}}})");
    CommandResult r = p.reg.call("assets.bake_sheet", Json{{"path", "assets/fx/disc.png"}, {"prefab", "prefabs/disc.prefab.json"}, {"frames", 1}, {"scale", 4.7}});
    if (no_gpu(r)) return;
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const Image img = read_png(p.file("assets/fx/disc.png"));
    int seen = 0, partial = 0;
    for (int y = 0; y < img.height; ++y)
        for (int x = 0; x < img.width; ++x) {
            const Rgba c = get(img, x, y);
            if (c.a == 0) continue;
            ++seen;
            if (c.a < 255) ++partial;
            // orange (255, 128, 0) at every alpha: the rounding of the GPU's premultiplied bytes leaves a few levels of error
            CHECK_MESSAGE(c.r >= 240, "pixel " << x << "," << y << " a=" << int(c.a) << " r=" << int(c.r));
            CHECK_MESSAGE(c.g >= 110, "pixel " << x << "," << y << " a=" << int(c.a) << " g=" << int(c.g));
            CHECK_MESSAGE(c.g <= 146, "pixel " << x << "," << y << " a=" << int(c.a) << " g=" << int(c.g));
            CHECK_MESSAGE(c.b <= 14, "pixel " << x << "," << y << " a=" << int(c.a) << " b=" << int(c.b));
        }
    CHECK(seen > 1000);
    CHECK(partial > 20);  // there is an antialiased edge to look at
    // the alpha of the body is the colour's alpha
    CHECK(std::abs(int(get(img, img.width / 2, img.height / 2).a) - 204) <= 3);
}

TEST_CASE("assets.bake_sheet: the cell covers the whole burst of particles, and the origin is the same pixel in every frame") {
    BakeProject p;
    p.put("prefabs/burst.prefab.json", kBurstPrefab);
    CommandResult r = p.reg.call("assets.bake_sheet",
                                 Json{{"path", "assets/fx/burst.png"}, {"prefab", "prefabs/burst.prefab.json"}, {"frames", 8}, {"fps", 8}, {"columns", 4}, {"margin", 3}, {"padding", 0}});
    if (no_gpu(r)) return;
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    const Image img = read_png(p.file("assets/fx/burst.png"));
    const int fw = r.result["frameWidth"].get<int>(), fh = r.result["frameHeight"].get<int>();
    REQUIRE(img.width == 4 * fw);
    REQUIRE(img.height == 2 * fh);
    // the particles fly 200 units a second for up to a second: the frame is far bigger than a particle
    CHECK(fw > 250);
    CHECK(fh > 250);
    // no frame draws within `margin` of the edge of its cell: nothing is cut off
    int touched = 0, grew = 0;
    for (int f = 0; f < 8; ++f) {
        const int cx = (f % 4) * fw, cy = (f / 4) * fh;
        for (int y = 0; y < fh; ++y)
            for (int x = 0; x < fw; ++x)
                if ((x < 3 || y < 3 || x >= fw - 3 || y >= fh - 3) && get(img, cx + x, cy + y).a > 0) ++touched;
        grew += opaque_pixels(img, cx, cy, fw, fh) > 0 ? 1 : 0;
    }
    CHECK(touched == 0);
    CHECK(grew == 8);
    // the sheet records the pivot: the origin is at the centre of a symmetric burst
    CHECK(r.result["pivot"][0].get<double>() == doctest::Approx(0.5).epsilon(0.05));
    CHECK(r.result["pivot"][1].get<double>() == doctest::Approx(0.5).epsilon(0.05));
}

TEST_CASE("assets.bake_sheet: clips start through a call to the behaviour, each in a fresh world") {
    BakeProject p;
    p.put("prefabs/boom.prefab.json", kBoomPrefab);
    p.put("scripts/boom.js", kBoomScript);
    const Json clips = Json::array({Json{{"name", "idle"}, {"frames", 4}}, Json{{"name", "explode"}, {"call", "explode"}, {"args", Json::array({50})}, {"frames", 6}, {"loop", false}}});
    CommandResult r = p.reg.call("assets.bake_sheet", Json{{"path", "assets/fx/boom.png"}, {"prefab", "prefabs/boom.prefab.json"}, {"fps", 10}, {"clips", clips}, {"columns", 5}, {"padding", 0}});
    if (no_gpu(r)) return;
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["frames"] == 10);
    const Json& sheet = r.result["sheet"];
    REQUIRE(sheet["clips"].size() == 2);
    CHECK(sheet["clips"][0]["name"] == "idle");
    CHECK(sheet["clips"][0]["firstFrame"] == 0);
    CHECK(sheet["clips"][0]["lastFrame"] == 3);
    CHECK(sheet["clips"][1]["name"] == "explode");
    CHECK(sheet["clips"][1]["firstFrame"] == 4);
    CHECK(sheet["clips"][1]["lastFrame"] == 9);
    CHECK(sheet["clips"][1]["loop"] == false);
    CHECK(sheet["clips"][1]["fps"] == 10);
    // idle draws only the dot and never changes (it says so); explode draws many more pixels at its end
    CHECK(has_warning(r.result, "'idle'"));
    const Image img = read_png(p.file("assets/fx/boom.png"));
    const int fw = r.result["frameWidth"].get<int>(), fh = r.result["frameHeight"].get<int>();
    auto area = [&](int f) { return opaque_pixels(img, (f % 5) * fw, (f / 5) * fh, fw, fh); };
    CHECK(area(3) < 100);
    CHECK(area(9) > area(3) * 3);
    // the pivot is shared and recorded
    CHECK(r.result["sheet"]["pivot"].is_array());

    // a clip with a misspelled call: the error names the prefab, the clip, the method and the ones that exist
    const Json bad = Json::array({Json{{"name", "explode"}, {"call", "explod"}, {"frames", 2}}});
    CommandResult e = p.reg.call("assets.bake_sheet", Json{{"path", "assets/fx/bad.png"}, {"prefab", "prefabs/boom.prefab.json"}, {"clips", bad}});
    REQUIRE_FALSE(e.ok);
    CHECK(message(e).find("prefabs/boom.prefab.json") != std::string::npos);
    CHECK(message(e).find("explod") != std::string::npos);
    CHECK(message(e).find("explode") != std::string::npos);
    CHECK_FALSE(stdfs::exists(p.file("assets/fx/bad.png")));
}

TEST_CASE("assets.bake_sheet: a script that throws fails the bake and the error names the prefab and the script") {
    BakeProject p;
    p.put("prefabs/orb.prefab.json", kCirclePrefab);
    p.put("scripts/pulse.js", R"(import { Behaviour } from "factoria";
export default class Pulse extends Behaviour {
  onStart() { throw new Error("pulse exploded"); }
})");
    CommandResult r = p.reg.call("assets.bake_sheet", Json{{"path", "assets/fx/orb.png"}, {"prefab", "prefabs/orb.prefab.json"}});
    if (no_gpu(r)) return;
    REQUIRE_FALSE(r.ok);
    const std::string m = message(r);
    CHECK(m.find("prefabs/orb.prefab.json") != std::string::npos);
    CHECK(m.find("pulse exploded") != std::string::npos);
    CHECK(m.find("scripts/pulse.js") != std::string::npos);
    CHECK_FALSE(stdfs::exists(p.file("assets/fx/orb.png")));
}

TEST_CASE("assets.bake_sheet: an entity of a scene, a fixed cell with a pivot, and a background") {
    BakeProject p;
    p.put("scenes/level.scene.json", R"({"format":"factoria.scene/1","entities":[
        {"id":"camera","components":{"Transform":{},"Camera":{}}},
        {"id":"holder","children":[{"id":"gem","components":{"Transform":{"position":[300,-200,0]},
            "Shape2D":{"shape":"diamond","size":[30,40],"color":[0.2,0.9,1,1]}}}]}]})");
    CommandResult r = p.reg.call("assets.bake_sheet", Json{{"path", "assets/fx/gem.png"}, {"scene", "scenes/level.scene.json"}, {"entity", "gem"}, {"frames", 2},
                                                           {"frameWidth", 64}, {"frameHeight", 64}, {"pivot", Json::array({0.5, 0.5})}, {"scale", 1}, {"background", "#102030"}});
    if (no_gpu(r)) return;
    REQUIRE_MESSAGE(r.ok, r.error.dump());
    CHECK(r.result["frameWidth"] == 64);
    CHECK(r.result["frameHeight"] == 64);
    CHECK(r.result["pivot"][0] == 0.5);
    CHECK(r.result["pivot"][1] == 0.5);
    CHECK(r.result["sheet"]["pivot"][1] == 0.5);
    CHECK(r.result["provenance"]["recipe"]["args"]["entity"] == "gem");
    const Image img = read_png(p.file("assets/fx/gem.png"));
    REQUIRE(img.width == 2 * (64 + 2));
    // the scene put the gem at (300, -200); the bake draws it at the origin, which lands at the pivot [0.5, 0.5] of the cell (32, 32)
    const Rgba centre = get(img, 1 + 32, 1 + 32);
    CHECK(centre.b > 200);
    CHECK(centre.r < 100);
    CHECK(get(img, 1 + 3, 1 + 3) == Rgba{16, 32, 48, 255});  // the background colour in a corner of the cell
    CHECK(get(img, 0, 0) == Rgba{16, 32, 48, 255});          // and in the gutter around it

    // the same gem does not fit a cell of 20 x 20 at scale 1: the error says what the cell needs
    CommandResult small = p.reg.call("assets.bake_sheet", Json{{"path", "assets/fx/gem2.png"}, {"scene", "scenes/level.scene.json"}, {"entity", "gem"},
                                                               {"frameWidth", 20}, {"frameHeight", 20}, {"scale", 1}});
    REQUIRE_FALSE(small.ok);
    CHECK(message(small).find("frameHeight") != std::string::npos);
    CHECK(message(small).find("scale") != std::string::npos);

    // without a scale the animation is scaled down to fit
    CommandResult fitted = p.reg.call("assets.bake_sheet", Json{{"path", "assets/fx/gem3.png"}, {"scene", "scenes/level.scene.json"}, {"entity", "gem"},
                                                                {"frameWidth", 20}, {"frameHeight", 20}});
    REQUIRE_MESSAGE(fitted.ok, fitted.error.dump());
    CHECK(fitted.result["frameWidth"] == 20);
    CHECK(fitted.result["scale"].get<double>() < 0.6);
    CHECK(fitted.result["scale"].get<double>() > 0.3);
}

TEST_CASE("assets.bake_sheet: arguments are checked with errors that teach (no GPU needed)") {
    BakeProject p;
    p.put("prefabs/orb.prefab.json", kCirclePrefab);
    p.put("scripts/pulse.js", kPulseScript);
    CommandResult unknown = p.reg.call("assets.bake_sheet", Json{{"path", "assets/fx/a.png"}, {"prefab", "prefabs/orb.prefab.json"}, {"frame", 4}});
    REQUIRE_FALSE(unknown.ok);
    CHECK(message(unknown).find("frames") != std::string::npos);  // did you mean
    CommandResult both = p.reg.call("assets.bake_sheet", Json{{"path", "assets/fx/a.png"}, {"prefab", "prefabs/orb.prefab.json"}, {"scene", "scenes/x.scene.json"}});
    REQUIRE_FALSE(both.ok);
    CommandResult noEntity = p.reg.call("assets.bake_sheet", Json{{"path", "assets/fx/a.png"}, {"scene", "scenes/x.scene.json"}});
    REQUIRE_FALSE(noEntity.ok);
    CHECK(message(noEntity).find("entity") != std::string::npos);
    CommandResult none = p.reg.call("assets.bake_sheet", Json{{"path", "assets/fx/a.png"}});
    REQUIRE_FALSE(none.ok);
    CommandResult notPng = p.reg.call("assets.bake_sheet", Json{{"path", "assets/fx/a.jpg"}, {"prefab", "prefabs/orb.prefab.json"}});
    REQUIRE_FALSE(notPng.ok);
    CHECK(message(notPng).find(".png") != std::string::npos);
    CommandResult missing = p.reg.call("assets.bake_sheet", Json{{"path", "assets/fx/a.png"}, {"prefab", "prefabs/nope.prefab.json"}});
    REQUIRE_FALSE(missing.ok);
    CHECK(message(missing).find("prefabs/nope.prefab.json") != std::string::npos);
    CommandResult fast = p.reg.call("assets.bake_sheet", Json{{"path", "assets/fx/a.png"}, {"prefab", "prefabs/orb.prefab.json"}, {"fps", 200}});
    if (no_gpu(fast)) return;
    REQUIRE_FALSE(fast.ok);
    CHECK(message(fast).find("fps") != std::string::npos);
    write_all(p.file("assets/fx/exists.png"), "x");
    CommandResult exists = p.reg.call("assets.bake_sheet", Json{{"path", "assets/fx/exists.png"}, {"prefab", "prefabs/orb.prefab.json"}});
    REQUIRE_FALSE(exists.ok);
    CHECK(message(exists).find("overwrite") != std::string::npos);
    CommandResult noId = p.reg.call("assets.bake_sheet", Json{{"path", "assets/fx/a.png"}, {"scene", "prefabs/orb.prefab.json"}, {"entity", "orb"}});
    REQUIRE_FALSE(noId.ok);
}

TEST_CASE("assets.bake_sheet: a baked sheet is previewed by clip name and plays by clip name in a SpriteAnimator") {
    BakeProject p;
    p.put("prefabs/boom.prefab.json", kBoomPrefab);
    p.put("scripts/boom.js", kBoomScript);
    const Json clips = Json::array({Json{{"name", "idle"}, {"frames", 4}}, Json{{"name", "explode"}, {"call", "explode"}, {"args", Json::array({50})}, {"frames", 6}, {"loop", false}}});
    CommandResult r = p.reg.call("assets.bake_sheet", Json{{"path", "assets/fx/boom.png"}, {"prefab", "prefabs/boom.prefab.json"}, {"fps", 10}, {"clips", clips}, {"columns", 5}});
    if (no_gpu(r)) return;
    REQUIRE_MESSAGE(r.ok, r.error.dump());

    // preview_sheet reads the sheet entry the bake wrote: the clip's frames, the padding and the pivot
    CommandResult v = p.reg.call("assets.preview_sheet", Json{{"path", "assets/fx/boom.png"}, {"clip", "explode"}});
    REQUIRE_MESSAGE(v.ok, v.error.dump());
    CHECK(v.result["shownFrames"] == 6);
    CHECK(v.result["frames"].size() == 6);
    CHECK(v.result["frames"][0]["frame"] == 4);
    CHECK(v.result["pivot"].is_array());
    CommandResult bad = p.reg.call("assets.preview_sheet", Json{{"path", "assets/fx/boom.png"}, {"clip", "explod"}});
    REQUIRE_FALSE(bad.ok);
    CHECK(message(bad).find("idle, explode") != std::string::npos);
    CHECK(message(bad).find("explode") != std::string::npos);

    // a SpriteAnimator resolves the clip against the same entry
    auto sheet = assets::parse_sheet(p.manifest()["assets"]["assets/fx/boom.png"]["sheet"]);
    REQUIRE(sheet);
    SpriteAnimator a;
    a.clip = "explode";
    const SpriteAnimPlan plan = resolve_sprite_animator(a, "assets/fx/boom.png", sheet);
    CHECK(plan.error.empty());
    CHECK(plan.firstFrame == 4);
    CHECK(plan.lastFrame == 9);
    CHECK_FALSE(plan.loop);
    CHECK(plan.padding == r.result["sheet"].value("padding", 0));
    CHECK(plan.fromSheet);
    a.clip = "explod";
    CHECK(resolve_sprite_animator(a, "assets/fx/boom.png", sheet).error.find("explode") != std::string::npos);
}
