// Shared by the UI tests: a world, an Input with the default ui_* actions and a UiSystem.
#pragma once

#include <doctest.h>

#include <string>
#include <vector>

#include "fa/ui/ui.h"

namespace fa_ui_test {
using namespace fa;

// A world with the default ui_* actions, a UiSystem and helpers to build widgets and press things. The design size is
// 320 x 180; widgets use pivot [0, 1] so their position is their top-left corner.
struct Ui {
    World w;
    Input in;
    UiSystem ui;
    Vec2 design{320, 180};
    float dt = 1.0f / 64.0f;  // exactly representable: repeat timings do not depend on rounding

    Ui() {
        ensure_builtin_components();
        in.set_actions(ui_with_default_actions(Json::object()));
    }

    template <class T>
    Entity add(const char* id, Vec2 pos, Vec2 size, Entity parent = kNullEntity) {
        Entity e = w.create(id, id);
        if (parent) w.set_parent(e, parent);
        w.get<Transform>(e)->position = {pos.x, pos.y, 0};
        T& c = w.add<T>(e);
        c.size = size;
        c.pivot = {0, 1};
        return e;
    }
    Entity button(const char* id, Vec2 pos, Vec2 size = {80, 20}, Entity parent = kNullEntity) {
        return add<Button>(id, pos, size, parent);
    }
    Rect rect(Entity e) { return *ui_rect(w, e, design); }

    void frame(int n = 1) {
        for (int i = 0; i < n; ++i) {
            ui.update(w, in, design, dt, {});
            in.begin_frame();
        }
    }
    // The ui.* events since the last call, as "name:id" or "name:id=value".
    std::vector<std::string> events() {
        std::vector<std::string> out;
        for (const GameEvent& e : w.events().game) {
            std::string s = e.name + ":" + (e.data["id"].is_null() ? std::string("null") : e.data["id"].get<std::string>());
            if (e.data.contains("value")) s += "=" + e.data["value"].dump();
            CHECK((e.source == kNullEntity) == e.data["id"].is_null());
            out.push_back(s);
        }
        w.events().game.clear();
        return out;
    }
    // Presses a key / pad button / mouse button for one frame and releases it for another.
    void tap_key(Key k) {
        in.on_key(k, true);
        frame();
        in.on_key(k, false);
        frame();
    }
    void tap_pad(GamepadButton b) {
        in.on_gamepad_button(0, b, true);
        frame();
        in.on_gamepad_button(0, b, false);
        frame();
    }
    void click(Vec2 p) {
        in.on_mouse_move(p);
        in.on_mouse_button(MouseButton::Left, true);
        frame();
        in.on_mouse_button(MouseButton::Left, false);
        frame();
    }
};

using V = std::vector<std::string>;

}  // namespace fa_ui_test
