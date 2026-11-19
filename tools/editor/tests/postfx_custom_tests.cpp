// The pure edits of PostProcess.customPasses behind the Post-processing panel (postfx_custom.h), and the same edits through
// postprocess.set: each is one call, one undo step.
#include "doctest.h"

#include <algorithm>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/render/post_custom.h"
#include "postfx_custom.h"

using namespace fa;
using namespace fa::editor;

TEST_CASE("postfx custom passes: add, move, remove and set return the whole new array") {
    Json list = Json::array();
    list = custom_pass_add(list, "materials/a.material.json");
    list = custom_pass_add(list, "materials/b.material.json");
    list = custom_pass_add(list, "materials/c.material.json");
    REQUIRE(list.size() == 3);
    CHECK(list[0]["material"] == "materials/a.material.json");
    CHECK(list[0]["position"] == "before:tonemap");
    CHECK(list[0]["enabled"] == true);

    // Reorder: down, then up, stopping at the ends.
    Json moved = custom_pass_move(list, 0, 1);
    CHECK(moved[0]["material"] == "materials/b.material.json");
    CHECK(moved[1]["material"] == "materials/a.material.json");
    CHECK(custom_pass_move(list, 0, -1) == list);
    CHECK(custom_pass_move(list, 2, 1) == list);
    CHECK(custom_pass_move(list, 7, 1) == list);
    CHECK(custom_pass_move(list, 1, 0) == list);
    CHECK(custom_pass_move(moved, 1, -1)[0]["material"] == "materials/a.material.json");

    // Remove.
    const Json fewer = custom_pass_remove(list, 1);
    REQUIRE(fewer.size() == 2);
    CHECK(fewer[1]["material"] == "materials/c.material.json");
    CHECK(custom_pass_remove(list, 9) == list);

    // Set and reset a key; a new material drops the old one's params.
    Json e = custom_pass_set(list, 1, "position", "after:bloom");
    CHECK(e[1]["position"] == "after:bloom");
    CHECK(custom_pass_set(e, 1, "position", Json())[1].contains("position") == false);
    e = custom_pass_set(e, 1, "enabled", false);
    CHECK(e[1]["enabled"] == false);
    e = custom_pass_set_param(e, 1, "amount", 0.5);
    CHECK(e[1]["materialParams"]["amount"] == 0.5);
    e = custom_pass_set(e, 1, "material", "materials/d.material.json");
    CHECK(e[1]["material"] == "materials/d.material.json");
    CHECK(e[1].contains("materialParams") == false);
}

TEST_CASE("postfx custom passes: a param override is set and reset, and an empty materialParams is dropped") {
    Json list = custom_pass_add(Json::array(), "materials/a.material.json");
    list = custom_pass_set_param(list, 0, "amount", 0.25);
    list = custom_pass_set_param(list, 0, "tint", Json::parse("[1,0,0,1]"));
    CHECK(list[0]["materialParams"].size() == 2);
    list = custom_pass_set_param(list, 0, "amount", Json());
    CHECK(list[0]["materialParams"].contains("amount") == false);
    CHECK(list[0]["materialParams"].contains("tint"));
    list = custom_pass_set_param(list, 0, "tint", Json());
    CHECK(list[0].contains("materialParams") == false);
    // Not an array, out of range: nothing breaks.
    CHECK(custom_pass_add(Json(), "m").size() == 1);
    CHECK(custom_pass_set_param(list, 5, "x", 1) == list);
    CHECK(custom_pass_remove(Json(), 0).size() == 0);
}

TEST_CASE("postfx custom passes: the label is the name, else the file name of the material") {
    CHECK(custom_pass_label(Json::parse(R"({"material":"materials/glow.material.json"})")) == "glow");
    CHECK(custom_pass_label(Json::parse(R"({"material":"a/b/x.material.json","name":"My pass"})")) == "My pass");
    CHECK(custom_pass_label(Json::parse(R"({"enabled":true})")) == "(no material)");
    CHECK(custom_pass_label(Json()) == "(no material)");
}

TEST_CASE("postfx custom passes: the Position combo offers the places between the screen effects, and each is a valid "
          "position") {
    const std::vector<std::string> names = render::custom_post_position_names();
    for (const char* wanted :
         {"before:tonemap", "after:tonemap", "after:colorGrading", "after:vignette", "after:sharpen", "after:outline",
          "after:posterize", "after:filmGrain", "before:colorFilter"})
        CHECK(std::find(names.begin(), names.end(), wanted) != names.end());
    Json list = custom_pass_add(Json::array(), "materials/a.material.json");
    for (const std::string& name : names) {
        INFO(name);
        const Json set = custom_pass_set(list, 0, "position", name);
        auto parsed = render::parse_custom_post_pass(set[0], "/customPasses/0");
        CHECK(parsed.ok());
    }
}
