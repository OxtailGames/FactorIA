// fa/scene/camera_mask.h: the rule behind Camera.showTags / hideTags.
#include <doctest.h>

#include "fa/scene/camera_mask.h"
#include "fa/scene/components.h"
#include "fa/scene/serialize.h"
#include "fa/scene/world.h"

using namespace fa;

namespace {
Entity make(World& w, const char* id, std::vector<std::string> tags = {}, Entity parent = kNullEntity) {
    Entity e = w.create(id, id);
    w.info(e).tags = std::move(tags);
    if (parent != kNullEntity) w.set_parent(e, parent);
    return e;
}
}  // namespace

TEST_CASE("camera mask: empty lists draw everything") {
    World w;
    Entity a = make(w, "a", {"x"});
    Entity b = make(w, "b");
    CameraMask m;
    CHECK(m.empty());
    CHECK(m.draws(w, a));
    CHECK(m.draws(w, b));
    CHECK(m.draws(w, kNullEntity));
}

TEST_CASE("camera mask: showTags keeps entities with the tag, on themselves or on an ancestor") {
    World w;
    Entity page = make(w, "page", {"page"});
    Entity leaf = make(w, "leaf", {}, page);
    Entity deep = make(w, "deep", {}, leaf);
    Entity other = make(w, "other", {"ui"});
    Entity none = make(w, "none");
    CameraMask m({"page"}, {});
    CHECK_FALSE(m.empty());
    CHECK(m.draws(w, page));
    CHECK(m.draws(w, leaf));
    CHECK(m.draws(w, deep));
    CHECK_FALSE(m.draws(w, other));
    CHECK_FALSE(m.draws(w, none));
}

TEST_CASE("camera mask: hideTags drops entities with the tag or under one that has it") {
    World w;
    Entity ui = make(w, "ui", {"ui"});
    Entity button = make(w, "button", {}, ui);
    Entity world = make(w, "world");
    CameraMask m({}, {"ui"});
    CHECK_FALSE(m.draws(w, ui));
    CHECK_FALSE(m.draws(w, button));
    CHECK(m.draws(w, world));
}

TEST_CASE("camera mask: hideTags wins over showTags, also through ancestors") {
    World w;
    Entity book = make(w, "book", {"book"});
    Entity cover = make(w, "cover", {"secret"}, book);
    Entity inner = make(w, "inner", {}, cover);
    Entity page = make(w, "page", {}, book);
    CameraMask m({"book"}, {"secret"});
    CHECK(m.draws(w, book));
    CHECK(m.draws(w, page));
    CHECK_FALSE(m.draws(w, cover));
    CHECK_FALSE(m.draws(w, inner));
    // The same tag in both lists draws nothing that carries it.
    CameraMask both({"book"}, {"book"});
    CHECK_FALSE(both.draws(w, book));
    CHECK_FALSE(both.draws(w, page));
}

TEST_CASE("camera mask: built from the Camera component; anything that is not a tag name is ignored") {
    World w;
    Entity tagged = make(w, "tagged", {"a"});
    Entity untagged = make(w, "untagged");
    Entity cam = make(w, "cam");
    Camera& c = w.add<Camera>(cam);
    c.showTags = Json::array({"a", 5, "", "a"});
    CameraMask m = CameraMask::of(w, cam);
    CHECK(m.show() == std::vector<std::string>{"a"});
    CHECK(m.draws(w, tagged));
    CHECK_FALSE(m.draws(w, untagged));
    CHECK(CameraMask::of(w, tagged).empty());  // not a Camera: draws everything
    CHECK(CameraMask::of(w, kNullEntity).empty());
}

TEST_CASE("camera mask: a malformed list is described") {
    CHECK(camera_tags_problem(Json::array({"a", "b"}), "showTags").empty());
    CHECK(camera_tags_problem(Json::array(), "hideTags").empty());
    CHECK(camera_tags_problem(Json("a"), "showTags").find("Camera.showTags must be an array") != std::string::npos);
    CHECK(camera_tags_problem(Json::array({"a", 3}), "hideTags").find("hideTags[1]") != std::string::npos);
    CHECK(camera_tags_problem(Json::array({""}), "showTags").find("empty string") != std::string::npos);
}

TEST_CASE("camera mask: showTags and hideTags survive a scene round trip and the loader rejects nothing valid") {
    World w;
    Entity cam = make(w, "cam");
    Camera& c = w.add<Camera>(cam);
    c.showTags = Json::array({"page_left"});
    c.hideTags = Json::array({"ui", "debug"});
    const Json saved = save_scene(w);
    REQUIRE(saved["entities"].size() == 1);
    CHECK(saved["entities"][0]["components"]["Camera"]["showTags"] == Json::array({"page_left"}));
    CHECK(saved["entities"][0]["components"]["Camera"]["hideTags"] == Json::array({"ui", "debug"}));
    World w2;
    LoadReport lr = load_scene(w2, saved, "test");
    CHECK(lr.ok());
    const Camera* c2 = w2.get<Camera>(w2.find("cam"));
    REQUIRE(c2 != nullptr);
    CHECK(c2->showTags == c.showTags);
    CHECK(c2->hideTags == c.hideTags);
    // Empty lists are the default and are not written.
    World w3;
    w3.add<Camera>(make(w3, "plain"));
    CHECK_FALSE(save_scene(w3)["entities"][0]["components"]["Camera"].contains("showTags"));
}
