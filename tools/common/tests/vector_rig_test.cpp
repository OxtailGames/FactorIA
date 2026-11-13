// vector.to_rig (docs/VECTOR.md, "Characters in parts"): a crafted SVG character becomes an atlas, joints and a Bone2D prefab whose
// rest pose is the SVG, and running it again updates the prefab in place.
#include <doctest.h>

#include <cmath>
#include <filesystem>

#include "asset_test_helpers.h"

using namespace fa;
using namespace fa::testing;

namespace {

// 200 x 300 drawing, one unit per pixel. The head carries a <head-pivot> marker, the lower arm hangs from the upper arm by its name,
// everything else is left to the defaults.
const char* kHero = R"(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 300" width="200" height="300">
  <g id="leg_r"><rect x="95" y="180" width="22" height="100" fill="#335"/></g>
  <g id="leg_l"><rect x="70" y="180" width="22" height="100" fill="#446"/></g>
  <g id="arm_upper_r"><rect x="128" y="85" width="18" height="50" rx="8" fill="#c96"/></g>
  <g id="arm_lower_r"><rect x="128" y="125" width="16" height="50" rx="7" fill="#eb8"/></g>
  <g id="torso"><rect x="68" y="80" width="64" height="110" rx="10" fill="#a33"/>
    <g id="head"><circle cx="100" cy="50" r="28" fill="#fc9"/><circle id="head-pivot" cx="100" cy="76" r="2" fill="red"/></g>
  </g>
  <g id="arm_upper_l"><rect x="54" y="85" width="18" height="50" rx="8" fill="#c96"/></g>
  <g id="arm_lower_l"><rect x="55" y="125" width="16" height="50" rx="7" fill="#eb8"/></g>
</svg>)";

Json part_of(const Json& result, const std::string& name) {
    for (const Json& p : result["parts"])
        if (p["name"] == name) return p;
    FAIL("no part " << name << " in " << result["parts"].dump());
    return {};
}

const Json* entity_named(const Json& node, const std::string& name) {
    if (node.value("name", std::string()) == name) return &node;
    if (node.contains("children"))
        for (const Json& c : node["children"])
            if (const Json* f = entity_named(c, name)) return f;
    return nullptr;
}

Json read_prefab(const AssetsProject& p, const std::string& rel = "prefabs/hero.prefab.json") {
    return parse_json(read_all(p.file(rel)), rel).value();
}

bool contains(const std::string& t, const std::string& n) { return t.find(n) != std::string::npos; }

std::string error_of(const CommandResult& r) {
    return r.error["message"].get<std::string>() + " " + r.error.value("hint", std::string());
}

struct Hero {
    AssetsProject p;
    Json r;
    explicit Hero(Json extra = Json::object(), const char* svg = kHero) {
        write_all(p.file("assets/art/hero.svg"), svg);
        Json args = {{"source", "assets/art/hero.svg"}, {"pixelsPerUnit", 4}};
        for (auto it = extra.begin(); it != extra.end(); ++it) args[it.key()] = it.value();
        r = p.ok("vector.to_rig", args);
    }
};

}  // namespace

TEST_CASE("vector.to_rig: parts, hierarchy, pivots and bone lengths of a crafted character") {
    Hero h;
    CHECK(h.r["parts"].size() == 8);
    CHECK(h.r["layout"] == "atlas");
    CHECK(h.r["status"] == "created");
    // hierarchy: nesting (head in torso), names (lower arm under upper arm), then the loose body parts under the torso
    CHECK(part_of(h.r, "head")["parent"] == "torso");
    CHECK(part_of(h.r, "head")["parentFrom"] == "nesting");
    CHECK(part_of(h.r, "arm_lower_l")["parent"] == "arm_upper_l");
    CHECK(part_of(h.r, "arm_lower_l")["parentFrom"] == "name");
    CHECK(part_of(h.r, "arm_upper_r")["parent"] == "torso");
    CHECK(part_of(h.r, "leg_l")["parent"] == "torso");
    CHECK(part_of(h.r, "torso")["parent"].is_null());
    // pivots: the marker wins; the rest are guessed and say so
    const Json head = part_of(h.r, "head");
    CHECK(head["pivotFrom"] == "marker");
    CHECK(std::abs(head["pivot"][0].get<double>() - 100) < 0.01);
    CHECK(std::abs(head["pivot"][1].get<double>() - 76) < 0.01);
    CHECK(part_of(h.r, "torso")["pivotFrom"] == "default");
    CHECK(part_of(h.r, "arm_lower_r")["pivotFrom"] == "overlap");
    const Json lower = part_of(
        h.r, "arm_lower_r");  // overlaps the upper arm from y 125 down: its joint is its top end, on its own axis
    CHECK(std::abs(lower["pivot"][0].get<double>() - 136) < 0.01);
    CHECK(std::abs(lower["pivot"][1].get<double>() - 125) < 0.01);
    CHECK(part_of(h.r, "leg_l")["pivot"][1] == 180);
    CHECK(has_warning(h.r, "were guessed"));
    CHECK(h.r["restPose"]["matches"] == true);
    CHECK(h.r["restPose"]["differingPixels"] == 0);

    // the prefab: Sprite + Bone2D per part, positions local to the parent, y up
    const Json prefab = read_prefab(h.p);
    CHECK(prefab["format"] == "factoria.prefab/1");
    const Json* torso = entity_named(prefab["entity"], "torso");
    const Json* headE = entity_named(prefab["entity"], "head");
    REQUIRE(torso);
    REQUIRE(headE);
    const Json& hs = (*headE)["components"]["Sprite"];
    CHECK(hs["texture"] == "assets/art/hero_parts.png");
    CHECK(hs["region"].size() == 4);
    CHECK(hs["pixelArt"] == false);
    // the head joint (y 76) is 4 drawing units above the torso's joint (its top centre, y 80); y points up in the prefab: 1 world unit
    const double headY = (*headE)["components"]["Transform"]["position"][1].get<double>();
    const double torsoY = (*torso)["components"]["Transform"]["position"][1].get<double>();
    CHECK(torsoY > 0);
    CHECK(std::abs(headY - (80 - 76) / 4.0) < 0.01);
    // bone length: from the joint to the farthest child joint (in world units)
    const Json upper = (*entity_named(prefab["entity"], "arm_upper_l"))["components"]["Bone2D"];
    const Json lowerL = part_of(h.r, "arm_lower_l");
    const Json upperL = part_of(h.r, "arm_upper_l");
    const double dx = lowerL["position"][0].get<double>() - upperL["position"][0].get<double>();
    const double dy = lowerL["position"][1].get<double>() - upperL["position"][1].get<double>();
    CHECK(std::abs(upper["length"].get<double>() - std::sqrt(dx * dx + dy * dy)) < 0.001);
    CHECK(upper["length"].get<double>() > 0);
    // draw order follows the SVG: the legs behind the torso, the head above it
    const int legLayer = (*entity_named(prefab["entity"], "leg_r"))["components"]["Sprite"]["layer"].get<int>();
    const int torsoLayer = (*torso)["components"]["Sprite"]["layer"].get<int>();
    const int headLayer = hs["layer"].get<int>();
    CHECK(legLayer < torsoLayer);
    CHECK(torsoLayer < headLayer);
    // the atlas and its provenance
    REQUIRE(h.p.exists("assets/art/hero_parts.png"));
    const Json entry = h.p.manifest()["assets"]["assets/art/hero_parts.png"];
    CHECK(entry["provenance"]["recipe"]["command"] == "vector.to_rig");
    CHECK(entry["provenance"]["recipe"]["inputs"][0]["path"] == "assets/art/hero.svg");
}

TEST_CASE("vector.to_rig: the rest pose is the SVG, pixel for pixel, and the side-by-side picture is returned") {
    Hero h;
    CHECK(h.r["restPose"]["maxDifference"].get<int>() <= h.r["restPose"]["tolerance"].get<int>());
    REQUIRE(h.r.contains("$image"));
    const Image side = read_png(std::filesystem::path(h.r["$image"]["path"].get<std::string>()));
    CHECK(side.width > 2 * 100);
    // layout "files": a picture per part, same match
    Hero f(Json{{"layout", "files"}});
    CHECK(f.r["restPose"]["matches"] == true);
    CHECK(f.p.exists("assets/art/hero_parts/head.png"));
    CHECK(part_of(f.r, "head").contains("file"));
    const Json filesPrefab = read_prefab(f.p);
    const Json* e = entity_named(filesPrefab["entity"], "head");
    REQUIRE(e);
    CHECK((*e)["components"]["Sprite"]["texture"] == "assets/art/hero_parts/head.png");
    CHECK_FALSE((*e)["components"]["Sprite"].contains("region"));
}

TEST_CASE("vector.to_rig: pivots from the argument, the data-pivot attribute and angle limits") {
    std::string svg = kHero;
    const std::string from = "<g id=\"arm_upper_l\">";
    svg.replace(svg.find(from), from.size(),
                "<g id=\"arm_upper_l\" data-pivot=\"63 87\" data-min-angle=\"-45\" data-max-angle=\"120\">");
    Hero h(Json{{"pivots", {{"leg_l", {81, 182}}}}}, svg.c_str());
    CHECK(part_of(h.r, "arm_upper_l")["pivotFrom"] == "data-pivot");
    CHECK(part_of(h.r, "arm_upper_l")["pivot"][0] == 63);
    CHECK(part_of(h.r, "leg_l")["pivotFrom"] == "pivots");
    const Json prefab = read_prefab(h.p);
    const Json b = (*entity_named(prefab["entity"], "arm_upper_l"))["components"]["Bone2D"];
    CHECK(b["minAngle"] == -45);
    CHECK(b["maxAngle"] == 120);
    // the Sprite pivot is the joint in 0..1, y up: (63 - 54 + 2) / (18 + 4) across and (87 - 85 + 2) of 54 down from the top
    const Json s = (*entity_named(prefab["entity"], "arm_upper_l"))["components"]["Sprite"];
    CHECK(std::abs(s["pivot"][0].get<double>() - 0.5) < 0.001);
    CHECK(std::abs(s["pivot"][1].get<double>() - (1.0 - 4.0 / 54.0)) < 0.001);
    CHECK(h.r["restPose"]["matches"] == true);
}

TEST_CASE("vector.to_rig: running it again keeps names and additions, reports renamed or removed parts, and prune "
          "removes them") {
    Hero h;
    // the user adds an Animator on the root and a collider-like extra child under a part
    Json prefab = read_prefab(h.p);
    prefab["entity"]["components"]["Animator"] =
        Json{{"clips", {{"wave", "anim/hero_wave.anim.json"}}}, {"clip", "wave"}};
    for (Json& c : prefab["entity"]["children"]) {
        if (c["name"] == "torso")
            c["children"].push_back(
                Json{{"name", "hitbox"}, {"components", {{"Transform", {{"position", {0, 5, 0}}}}}}});
    }
    write_all(h.p.file("prefabs/hero.prefab.json"), prefab.dump(2));
    const Json first = h.r;
    write_all(h.p.file("assets/art/hero.svg"), kHero);
    const Json again = h.p.ok("vector.to_rig", Json{{"source", "assets/art/hero.svg"}, {"pixelsPerUnit", 4}});
    CHECK(again["status"] == "updated");
    CHECK(again["removed"].empty());
    CHECK(again["added"].empty());
    CHECK(again["parts"] == first["parts"]);
    const Json after = read_prefab(h.p);
    CHECK(after["entity"]["components"].contains("Animator"));
    CHECK(entity_named(after["entity"], "hitbox") != nullptr);
    // same bytes for the atlas: stable
    const std::string atlas1 = read_all(h.p.file("assets/art/hero_parts.png"));
    h.p.ok("vector.to_rig", Json{{"source", "assets/art/hero.svg"}, {"pixelsPerUnit", 4}});
    CHECK(read_all(h.p.file("assets/art/hero_parts.png")) == atlas1);

    // rename a part in the SVG: the old one is reported (with a suggestion), still in the prefab
    std::string svg = kHero;
    svg.replace(svg.find("id=\"leg_r\""), 10, "id=\"leg_right\"");
    write_all(h.p.file("assets/art/hero.svg"), svg);
    write_all(
        h.p.file("anim/hero_wave.anim.json"),
        R"({"format":"factoria.anim/1","duration":1,"tracks":[{"path":"torso/leg_r","component":"Transform","field":"rotation.z","keys":[{"t":0,"value":0},{"t":1,"value":10}]}]})");
    const Json renamed = h.p.ok("vector.to_rig", Json{{"source", "assets/art/hero.svg"}, {"pixelsPerUnit", 4}});
    CHECK(renamed["removed"] == Json::array({"leg_r"}));
    CHECK(renamed["added"] == Json::array({"leg_right"}));
    CHECK(has_warning(renamed, "not in the SVG any more: leg_r"));
    CHECK(has_warning(renamed, "anim/hero_wave.anim.json (leg_r)"));
    CHECK(entity_named(read_prefab(h.p)["entity"], "leg_r") != nullptr);
    CHECK(entity_named(read_prefab(h.p)["entity"], "leg_l") != nullptr);

    const Json pruned =
        h.p.ok("vector.to_rig", Json{{"source", "assets/art/hero.svg"}, {"pixelsPerUnit", 4}, {"prune", true}});
    CHECK(entity_named(read_prefab(h.p)["entity"], "leg_r") == nullptr);
    CHECK(entity_named(read_prefab(h.p)["entity"], "leg_right") != nullptr);
    CHECK(entity_named(read_prefab(h.p)["entity"], "hitbox") != nullptr);
}

TEST_CASE("vector.to_rig: the rig is stale when the SVG changes, and assets.regenerate redraws it") {
    Hero h;
    const Json none = h.p.ok("assets.regenerate", Json{{"stale", true}});
    CHECK(none["count"] == 0);
    std::string svg = kHero;
    svg.replace(svg.find("#fc9"), 4, "#39c");
    write_all(h.p.file("assets/art/hero.svg"), svg);
    const Json plan = h.p.ok("assets.regenerate", Json{{"stale", true}, {"dryRun", true}});
    CHECK(plan["count"] == 1);
    const Json r = h.p.ok("assets.regenerate", Json{{"stale", true}});
    CHECK(r["count"] == 1);
    CHECK(h.p.ok("assets.regenerate", Json{{"stale", true}})["count"] == 0);
}

TEST_CASE("vector.to_rig: errors name the argument, the fix and the closest id") {
    AssetsProject p;
    write_all(p.file("assets/art/hero.svg"), kHero);
    CommandResult r =
        p.call("vector.to_rig", Json{{"source", "assets/art/hero.svg"}, {"parents", {{"hand_l", "arm_lower_l"}}}});
    REQUIRE_FALSE(r.ok);
    CHECK(contains(error_of(r), "/parents/hand_l"));
    r = p.call("vector.to_rig", Json{{"source", "assets/art/hero.svg"}, {"parents", {{"head", "arm_lower_lft"}}}});
    REQUIRE_FALSE(r.ok);
    CHECK(contains(error_of(r), "arm_lower_l"));
    r = p.call("vector.to_rig", Json{{"source", "assets/art/hero.svg"},
                                     {"parents", {{"torso", "head"}}}});  // head is inside torso: a cycle
    REQUIRE_FALSE(r.ok);
    CHECK(contains(error_of(r), "its own ancestor"));
    r = p.call("vector.to_rig", Json{{"source", "assets/art/hero.svg"}, {"layout", "atlass"}});
    REQUIRE_FALSE(r.ok);
    CHECK(contains(error_of(r), "/layout"));
    r = p.call("vector.to_rig", Json{{"source", "assets/art/missing.svg"}});
    REQUIRE_FALSE(r.ok);
    r = p.call("vector.to_rig", Json{{"source", "assets/art/hero.svg"}, {"pivots", {{"hed", {1, 2}}}}});
    REQUIRE_FALSE(r.ok);
    CHECK(contains(error_of(r), "head"));
    write_all(
        p.file("assets/art/flat.svg"),
        R"(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10"><rect id="g12" width="5" height="5"/></svg>)");
    r = p.call("vector.to_rig", Json{{"source", "assets/art/flat.svg"}});
    REQUIRE_FALSE(r.ok);
    CHECK(contains(error_of(r), "no group with an id"));
    // an existing picture that this command did not make is not replaced
    write_all(p.file("assets/art/hero_parts.png"), "not ours");
    r = p.call("vector.to_rig", Json{{"source", "assets/art/hero.svg"}});
    REQUIRE_FALSE(r.ok);
    CHECK(contains(error_of(r), "overwrite"));
    // nothing was written by the failed runs
    CHECK_FALSE(p.exists("prefabs/hero.prefab.json"));
}

TEST_CASE("vector.to_rig: dryRun writes nothing and a part drawn around another one warns") {
    AssetsProject p;
    write_all(p.file("assets/art/hero.svg"), kHero);
    const Json r = p.ok("vector.to_rig", Json{{"source", "assets/art/hero.svg"}, {"dryRun", true}});
    CHECK(r["dryRun"] == true);
    CHECK_FALSE(p.exists("prefabs/hero.prefab.json"));
    CHECK_FALSE(p.exists("assets/art/hero_parts.png"));
    // a shape outside every part is reported and not in the rig
    write_all(
        p.file("assets/art/loose.svg"),
        R"(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><g id="a"><rect width="30" height="30" fill="red"/></g><rect y="80" width="100" height="20" fill="green"/></svg>)");
    const Json l = p.ok("vector.to_rig", Json{{"source", "assets/art/loose.svg"}});
    CHECK(has_warning(l, "belong to no part"));
    CHECK(l["restPose"]["matches"] == false);
}
