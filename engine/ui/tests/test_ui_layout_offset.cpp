// The layout places a child with World::ui_layout_offset and leaves Transform.position to the author (ui_rect.h,
// "Where a laid-out child is").
#include <doctest.h>

#include <cmath>
#include <string>

#include "fa/scene/serialize.h"
#include "fa/scene/ui_rect.h"
#include "fa/ui/ui.h"
#include "ui_fixture.h"

using namespace fa;

namespace {
using fa_ui_test::Ui;

struct Column {
    Entity panel, a, b;
};

// A column panel at (100, 50), padding 10, spacing 10, children aligned to the start: a at (110, 60), b at (110, 90).
Column column(Ui& t) {
    Column c;
    c.panel = t.add<Panel>("p", {100, 50}, {200, 150});
    Panel& p = *t.w.get<Panel>(c.panel);
    p.layout = UiLayout::Column;
    p.spacing = 10;
    p.padding = {10, 10, 10, 10};
    p.align = UiAlign::Start;
    c.a = t.button("a", {0, 0}, {100, 20}, c.panel);
    c.b = t.button("b", {0, 0}, {60, 30}, c.panel);
    return c;
}

Vec3 position(Ui& t, Entity e) { return std::as_const(t.w).get<Transform>(e)->position; }
}  // namespace

TEST_CASE("ui layout offset: the layout never writes Transform.position, however many frames run") {
    Ui t;
    const Column c = column(t);
    const Vec3 before = position(t, c.a);
    for (int i = 0; i < 200; ++i) t.ui.layout(t.w, t.design, {});
    CHECK(t.rect(c.a) == Rect{110, 60, 100, 20});
    CHECK(t.rect(c.b) == Rect{110, 90, 60, 30});
    CHECK(position(t, c.a) == before);  // bit for bit: not a drifting sum of deltas
    CHECK(position(t, c.b) == Vec3{0, 0, 0});
    CHECK(t.w.ui_layout_offset(c.a).x == doctest::Approx(10));
    CHECK(t.w.ui_layout_offset(c.b).y == doctest::Approx(40));
    // the panel itself is not laid out by anyone: no offset
    CHECK(t.w.ui_layout_offset(c.panel).x == 0.0f);
    // the world matrix of the child holds the placement; Transform.position does not
    CHECK(t.w.world_matrix(c.b).translation().y == doctest::Approx(90));
    CHECK(t.w.world_position(c.b).x == doctest::Approx(110));
}

TEST_CASE("ui layout offset: a position nudges the child from its slot, and the layout does not fight a script") {
    Ui t;
    const Column c = column(t);
    t.ui.layout(t.w, t.design, {});
    t.w.get<Transform>(c.b)->position = {7, -4, 0};  // a script (or the inspector) writes the author's offset
    for (int i = 0; i < 5; ++i) t.ui.layout(t.w, t.design, {});
    CHECK(t.rect(c.b) == Rect{117, 86, 60, 30});  // slot (110, 90) + (7, -4)
    CHECK(position(t, c.b) == Vec3{7, -4, 0});
    CHECK(t.rect(c.a) == Rect{110, 60, 100, 20});  // the sibling does not move
    // the layout offset is the slot relative to the panel (100, 50), whatever the nudge is
    CHECK(t.w.ui_layout_offset(c.b).x == doctest::Approx(10));
    CHECK(t.w.ui_layout_offset(c.b).y == doctest::Approx(40));
    t.w.get<Transform>(c.b)->position = {0, 0, 0};
    t.ui.layout(t.w, t.design, {});
    CHECK(t.rect(c.b) == Rect{110, 90, 60, 30});
}

TEST_CASE("ui layout offset: setting the world position of a laid-out child sets the author offset around the slot") {
    Ui t;
    const Column c = column(t);
    t.ui.layout(t.w, t.design, {});
    t.w.set_world_position(c.b, {120, 100, 0});  // 10 right and 10 below the slot
    CHECK(position(t, c.b) == Vec3{10, 10, 0});
    t.ui.layout(t.w, t.design, {});
    CHECK(t.rect(c.b) == Rect{120, 100, 60, 30});
}

TEST_CASE("ui layout offset: a child that is no longer laid out, or is destroyed, loses its offset") {
    Ui t;
    const Column c = column(t);
    t.ui.layout(t.w, t.design, {});
    REQUIRE(t.w.ui_layout_offset_entities().size() == 2);
    t.w.get<Panel>(c.panel)->layout = UiLayout::None;
    t.ui.layout(t.w, t.design, {});
    CHECK(t.w.ui_layout_offset_entities().empty());
    CHECK(t.rect(c.a) == Rect{100, 50, 100, 20});  // its own position (0) under the panel
    t.w.get<Panel>(c.panel)->layout = UiLayout::Column;
    t.ui.layout(t.w, t.design, {});
    CHECK(t.rect(c.a) == Rect{110, 60, 100, 20});
    t.w.destroy(c.a);
    t.w.flush();
    t.ui.layout(t.w, t.design, {});
    CHECK(t.w.ui_layout_offset_entities().size() == 1);
    CHECK(t.rect(c.b) == Rect{110, 60, 60, 30});  // b moved up into the first slot
    t.w.clear();
    CHECK(t.w.ui_layout_offset_entities().empty());
}

TEST_CASE("ui layout offset: nested panels and a ScrollList place by offset too") {
    Ui t;
    const Entity outer = t.add<Panel>("outer", {0, 0}, {300, 170});
    Panel& o = *t.w.get<Panel>(outer);
    o.layout = UiLayout::Column;
    o.padding = {10, 10, 10, 10};
    o.spacing = 10;
    o.align = UiAlign::Start;
    const Entity inner = t.add<Panel>("inner", {0, 0}, {100, 40}, outer);
    Panel& i = *t.w.get<Panel>(inner);
    i.layout = UiLayout::Row;
    i.padding = {5, 5, 5, 5};
    i.spacing = 5;
    i.align = UiAlign::Start;
    const Entity x = t.button("x", {0, 0}, {30, 20}, inner);
    const Entity y = t.button("y", {0, 0}, {30, 20}, inner);
    const Entity list = t.add<ScrollList>("list", {0, 0}, {200, 60}, outer);
    const Entity row = t.button("row", {0, 0}, {100, 20}, list);
    t.ui.layout(t.w, t.design, {});
    t.ui.layout(t.w, t.design, {});
    CHECK(t.rect(inner) == Rect{10, 10, 100, 40});
    CHECK(t.rect(x) == Rect{15, 15, 30, 20});
    CHECK(t.rect(y) == Rect{50, 15, 30, 20});
    CHECK(t.rect(list) == Rect{10, 60, 200, 60});
    CHECK(t.rect(row).y >= t.rect(list).y);
    CHECK(t.rect(row).y < t.rect(list).y + t.rect(list).h);
    for (const Entity e : {inner, x, y, list, row}) CHECK(position(t, e) == Vec3{0, 0, 0});
}

TEST_CASE("ui layout offset: rotation and scale of 6e compose with the offset in layout space") {
    Ui t;
    const Entity p = t.add<Panel>("p", {100, 50}, {100, 100});
    Panel& panel = *t.w.get<Panel>(p);
    panel.layout = UiLayout::Column;
    panel.padding = {10, 10, 10, 10};
    panel.align = UiAlign::Start;
    panel.pivot = {0, 1};
    const Entity c = t.button("c", {0, 0}, {20, 20}, p);
    t.w.get<Transform>(p)->rotation = {0, 0, 90};
    t.frame(2);
    // layout space: the slot is (110, 60) .. (130, 80); a quarter turn clockwise about (100, 50) puts it at
    // x 70..90, y 60..80
    const Rect r = *ui_rect(t.w, c, t.design);
    CHECK(r.x == doctest::Approx(70.0f).epsilon(0.001));
    CHECK(r.y == doctest::Approx(60.0f).epsilon(0.001));
    CHECK(position(t, c) == Vec3{0, 0, 0});
    CHECK(position(t, p) == Vec3{100, 50, 0});
    CHECK(*ui_layout_rect(t.w, c, t.design) == Rect{110, 60, 20, 20});
    CHECK(ui_layout_translation(t.w, c).x == doctest::Approx(110));
    // the author's offset is added in layout space, before the panel's turn: 10 right in layout space is 10 down on
    // screen
    t.w.get<Transform>(c)->position = {10, 0, 0};
    t.frame(2);
    const Rect nudged = *ui_rect(t.w, c, t.design);
    CHECK(nudged.x == doctest::Approx(70.0f).epsilon(0.001));
    CHECK(nudged.y == doctest::Approx(70.0f).epsilon(0.001));
    // the child's own scale makes room for it (6e) and the slot is still its top-left
    t.w.get<Transform>(c)->position = {0, 0, 0};
    t.w.get<Transform>(p)->rotation = {0, 0, 0};
    t.w.get<Button>(c)->pivot = {0, 1};
    t.w.get<Transform>(c)->scale = {2, 2, 1};
    t.frame(2);
    CHECK(*ui_footprint_rect(t.w, c, t.design) == Rect{110, 60, 40, 40});
    CHECK(position(t, c) == Vec3{0, 0, 0});
}

TEST_CASE("ui layout offset: a right-to-left panel and a mirrored screen place by offset, and the position nudges the "
          "mirror image") {
    Ui t;
    const Column c = column(t);
    t.w.get<Panel>(c.panel)->direction = UiDirection::Rtl;
    t.w.set_ui_mirror_rtl(false);
    t.frame(2);
    // inner box x 110..290: the first child's right edge is at 290
    CHECK(t.rect(c.a).x == doctest::Approx(190));
    CHECK(t.rect(c.b).x == doctest::Approx(230));
    CHECK(position(t, c.a) == Vec3{0, 0, 0});

    // the mirrored screen (ui.mirrorRtl): the panel's own anchor, pivot and position flip, and so does the nudge
    Ui m;
    const Column d = column(m);
    m.w.get<Panel>(d.panel)->direction = UiDirection::Ltr;
    m.w.set_rtl(true);
    m.w.set_ui_mirror_rtl(true);
    m.frame(3);
    const Rect slot = m.rect(d.b);
    CHECK(position(m, d.b) == Vec3{0, 0, 0});
    for (int i = 0; i < 100; ++i) m.ui.layout(m.w, m.design, {});
    CHECK(m.rect(d.b) == slot);  // stable: no drift, and the position is still the author's
    CHECK(position(m, d.b) == Vec3{0, 0, 0});
    m.w.get<Transform>(d.b)->position = {8, 0, 0};
    m.frame(2);
    CHECK(m.rect(d.b).x == doctest::Approx(slot.x - 8));  // a mirrored position moves the other way
    CHECK(m.rect(d.b).y == doctest::Approx(slot.y));
}

TEST_CASE("ui layout offset: the scene file holds the author's position only, and a loaded scene lays out the same") {
    Ui t;
    const Column c = column(t);
    t.w.get<Transform>(c.b)->position = {3, 0, 0};
    t.frame(3);
    const Json saved = save_scene(t.w);
    const std::string text = saved.dump();
    CHECK(text.find("layoutOffset") == std::string::npos);
    const Json& entities = saved["entities"];
    REQUIRE(entities.size() == 1);
    const Json& kids = entities[0]["children"];
    REQUIRE(kids.size() == 2);
    // a is in its slot and its Transform is the default, so it is not written at all; b holds only the author's 3
    CHECK_FALSE(kids[0]["components"].contains("Transform"));
    REQUIRE(kids[1]["components"].contains("Transform"));
    const Json& posB = kids[1]["components"]["Transform"]["position"];
    CHECK(posB[0].get<float>() == 3.0f);
    CHECK(posB[1].get<float>() == 0.0f);

    Ui u;
    REQUIRE(load_scene(u.w, saved, "test").ok());
    u.frame(3);
    CHECK(u.rect(u.w.find_by_id("a")) == Rect{110, 60, 100, 20});
    CHECK(u.rect(u.w.find_by_id("b")) == Rect{113, 90, 60, 30});
    CHECK(save_scene(u.w) == saved);  // saving again does not bake what the layout did
}

TEST_CASE("ui layout offset: a scene saved before 0.30 (positions baked by the layout) is migrated by "
          "reset_baked_positions") {
    Json old;
    {
        // What the old engine saved: the column of `column()` with every child's position holding the delta it was
        // moved by.
        Ui t;
        const Column c = column(t);
        t.frame(2);
        t.w.get<Transform>(c.a)->position = {t.w.ui_layout_offset(c.a).x, t.w.ui_layout_offset(c.a).y, 0};
        t.w.get<Transform>(c.b)->position = {t.w.ui_layout_offset(c.b).x, t.w.ui_layout_offset(c.b).y, 0};
        old = save_scene(t.w);
    }
    Ui u;
    REQUIRE(load_scene(u.w, old, "old").ok());
    const Entity a = u.w.find_by_id("a"), b = u.w.find_by_id("b");
    u.frame(3);
    CHECK(u.rect(a).x == doctest::Approx(120));  // the slot (110) plus the baked position (10)
    const Vec3 baked = position(u, a);
    CHECK(u.ui.reset_baked_positions(u.w, true) == std::vector<std::string>{"a", "b"});  // a dry run only lists them
    CHECK(position(u, a) == baked);
    const std::vector<std::string> ids = u.ui.reset_baked_positions(u.w);
    CHECK(ids == std::vector<std::string>{"a", "b"});
    CHECK(position(u, a) == Vec3{0, 0, 0});
    u.frame(3);
    CHECK(u.rect(a) == Rect{110, 60, 100, 20});
    CHECK(u.rect(b) == Rect{110, 90, 60, 30});
    CHECK(u.ui.reset_baked_positions(u.w).empty());  // nothing left to migrate
    // a position the author chose is not touched
    u.w.get<Transform>(b)->position = {3, 2, 0};
    CHECK(u.ui.reset_baked_positions(u.w).empty());
    CHECK(position(u, b) == Vec3{3, 2, 0});
}

TEST_CASE(
    "ui layout offset: set_parent keepWorld out of a Panel keeps the world place at once and after the next layout") {
    Ui t;
    const Column c = column(t);
    t.ui.layout(t.w, t.design, {});
    const Vec3 before = t.w.world_position(c.b);  // (110, 90): the slot
    REQUIRE(before.x == doctest::Approx(110));
    REQUIRE(before.y == doctest::Approx(90));
    const Entity plain = t.w.create("plain", "plain");
    t.w.get<Transform>(plain)->position = {300, 10, 0};
    t.w.set_parent(c.b, plain, true);
    // the placement belonged to the old parent: the offset is gone, the whole place is in Transform.position
    CHECK(t.w.ui_layout_offset(c.b).x == 0.0f);
    CHECK(t.w.world_position(c.b).x == doctest::Approx(before.x));
    CHECK(t.w.world_position(c.b).y == doctest::Approx(before.y));
    CHECK(position(t, c.b).x == doctest::Approx(-190));
    CHECK(position(t, c.b).y == doctest::Approx(80));
    for (int i = 0; i < 3; ++i) t.ui.layout(t.w, t.design, {});
    CHECK(t.w.world_position(c.b).x == doctest::Approx(before.x));  // nobody places it: it does not jump
    CHECK(t.w.world_position(c.b).y == doctest::Approx(before.y));
    CHECK(t.w.ui_layout_offset_entities().size() == 1);  // only a is still laid out

    // without keepWorld the position stays the author's offset and the old placement is dropped too
    Ui u;
    const Column d = column(u);
    u.ui.layout(u.w, u.design, {});
    const Entity free = u.w.create("free", "free");
    u.w.get<Transform>(free)->position = {300, 10, 0};
    u.w.set_parent(d.b, free);
    CHECK(u.w.ui_layout_offset(d.b).x == 0.0f);
    CHECK(u.w.world_position(d.b).x == doctest::Approx(300));
    CHECK(position(u, d.b) == Vec3{0, 0, 0});
}

TEST_CASE("ui layout offset: set_parent keepWorld into a Panel that lays out lands the child in its slot, rotation and "
          "scale kept") {
    Ui t;
    const Column c = column(t);
    const Entity q = t.add<Panel>("q", {10, 100}, {200, 100});
    Panel& qp = *t.w.get<Panel>(q);
    qp.layout = UiLayout::Column;
    qp.padding = {10, 10, 10, 10};
    qp.align = UiAlign::Start;
    t.ui.layout(t.w, t.design, {});
    t.w.get<Transform>(c.b)->rotation = {0, 0, 30};
    t.w.set_parent(c.b, q, true);
    // The position it had relative to the old parent means nothing under a parent that places its children: 0 = in the slot.
    CHECK(position(t, c.b) == Vec3{0, 0, 0});
    CHECK(t.w.get<Transform>(c.b)->rotation.z == doctest::Approx(30));
    for (int i = 0; i < 3; ++i) t.ui.layout(t.w, t.design, {});
    CHECK(*ui_layout_rect(t.w, c.b, t.design) == Rect{20, 110, 60, 30});  // q's top-left + padding
    CHECK(t.rect(c.a) == Rect{110, 60, 100, 20});                         // a, alone in its Panel, is in its slot
    // A Panel without a layout does not place its children: the child keeps its world place.
    Ui u;
    const Column d = column(u);
    const Entity none = u.add<Panel>("none", {10, 100}, {200, 100});
    u.ui.layout(u.w, u.design, {});
    u.w.set_parent(d.b, none, true);
    CHECK(position(u, d.b).x == doctest::Approx(100));  // 110 - 10
    CHECK(position(u, d.b).y == doctest::Approx(-10));  // 90 - 100
    CHECK(u.w.world_position(d.b).x == doctest::Approx(110));
}

TEST_CASE("ui layout offset: reordering the children of a Panel with set_parent keepWorld does not nudge anything") {
    Ui t;
    const Column c = column(t);
    t.ui.layout(t.w, t.design, {});
    t.w.set_parent(c.b, c.panel, true, 0);  // b first: the same parent, a new index
    CHECK(position(t, c.b) == Vec3{0, 0, 0});
    CHECK(position(t, c.a) == Vec3{0, 0, 0});
    CHECK(t.w.ui_layout_offset_entities().size() == 2);  // the placement is untouched
    for (int i = 0; i < 3; ++i) t.ui.layout(t.w, t.design, {});
    CHECK(position(t, c.b) == Vec3{0, 0, 0});
    CHECK(t.rect(c.b) == Rect{110, 60, 60, 30});
    CHECK(t.rect(c.a) == Rect{110, 100, 100, 20});  // 60 + 30 + spacing 10
    t.w.set_parent(c.a, c.panel, true, 0);          // and back
    t.ui.layout(t.w, t.design, {});
    CHECK(position(t, c.a) == Vec3{0, 0, 0});
    CHECK(t.rect(c.a) == Rect{110, 60, 100, 20});
    CHECK(t.rect(c.b) == Rect{110, 90, 60, 30});
}
