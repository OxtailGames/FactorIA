// "gamepad" and "touch" members of an input replay frame (--input) and of the game.input command.
#include <algorithm>

#include "engine_impl.h"
#include "fa/core/strings.h"

namespace fa {

namespace {

void apply_one_gamepad(Input& in, const Json& g, std::vector<std::string>& problems) {
    auto note = [&](const std::string& m) { problems.push_back("gamepad: " + m); };
    if (!g.is_object()) {
        note("expected an object like {\"index\": 0, \"buttons\": {\"A\": true}, \"axes\": {\"LeftX\": -1}}, got " +
             describe_json_value(g));
        return;
    }
    static const std::vector<std::string> known = {"index", "connected", "buttons", "axes"};
    for (auto it = g.begin(); it != g.end(); ++it)
        if (std::find(known.begin(), known.end(), it.key()) == known.end())
            note("unknown field '" + it.key() + "' (ignored). " + did_you_mean(it.key(), known) +
                 " A gamepad takes index, connected, buttons and axes.");
    int index = 0;
    if (g.contains("index")) {
        const Json& i = g["index"];
        if (!i.is_number_integer() || i.get<long long>() < 0 || i.get<long long>() >= kMaxGamepads) {
            note("index must be an integer from 0 to " + std::to_string(kMaxGamepads - 1) + ", got " + describe_json_value(i));
            return;
        }
        index = i.get<int>();
    }
    if (g.contains("connected")) {
        if (g["connected"].is_boolean()) in.on_gamepad_connected(index, g["connected"].get<bool>());
        else note("connected must be true or false, got " + describe_json_value(g["connected"]));
    }
    if (g.contains("buttons")) {
        if (!g["buttons"].is_object()) {
            note("buttons must be an object like {\"A\": true, \"DpadLeft\": false}, got " + describe_json_value(g["buttons"]));
        } else {
            for (auto it = g["buttons"].begin(); it != g["buttons"].end(); ++it) {
                GamepadButton b{};
                if (!gamepad_button_from_name(it.key(), b)) {
                    note("unknown button '" + it.key() + "' (ignored). " + did_you_mean(it.key(), gamepad_button_names()));
                } else if (it->is_boolean()) {
                    in.on_gamepad_button(index, b, it->get<bool>());
                } else {
                    note("button '" + it.key() + "' must be true (down) or false (up), got " + describe_json_value(*it));
                }
            }
        }
    }
    if (g.contains("axes")) {
        if (!g["axes"].is_object()) {
            note("axes must be an object like {\"LeftX\": -1, \"RightTrigger\": 0.5}, got " + describe_json_value(g["axes"]));
        } else {
            for (auto it = g["axes"].begin(); it != g["axes"].end(); ++it) {
                GamepadAxis a{};
                if (!gamepad_axis_from_name(it.key(), a))
                    note("unknown axis '" + it.key() + "' (ignored). " + did_you_mean(it.key(), gamepad_axis_names()));
                else if (it->is_number())
                    in.on_gamepad_axis(index, a, it->get<float>());
                else
                    note("axis '" + it.key() + "' must be a number (-1..1, triggers 0..1), got " + describe_json_value(*it));
            }
        }
    }
}

void apply_one_touch(Input& in, const Json& t, std::vector<std::string>& problems) {
    auto note = [&](const std::string& m) { problems.push_back("touch: " + m); };
    if (!t.is_object()) {
        note("expected an object like {\"id\": 1, \"position\": [640, 360], \"down\": true}, got " + describe_json_value(t));
        return;
    }
    static const std::vector<std::string> known = {"id", "position", "down"};
    for (auto it = t.begin(); it != t.end(); ++it)
        if (std::find(known.begin(), known.end(), it.key()) == known.end())
            note("unknown field '" + it.key() + "' (ignored). " + did_you_mean(it.key(), known) +
                 " A touch takes id, position and down.");
    std::uint64_t id = 1;
    if (t.contains("id")) {
        if (!t["id"].is_number_integer() || t["id"].get<long long>() < 0) {
            note("id must be a non-negative integer, got " + describe_json_value(t["id"]));
            return;
        }
        id = t["id"].get<std::uint64_t>();
    }
    bool down = true;
    if (t.contains("down")) {
        if (!t["down"].is_boolean()) {
            note("down must be true or false, got " + describe_json_value(t["down"]));
            return;
        }
        down = t["down"].get<bool>();
    }
    const auto& fingers = in.touches();
    const bool known_id = std::any_of(fingers.begin(), fingers.end(), [&](const Touch& f) { return f.id == id; });
    Vec2 p;
    const bool hasPos = t.contains("position");
    if (hasPos) {
        std::string err;
        if (!json_to(t["position"], p, &err)) {
            note("position: " + err);
            return;
        }
    } else if (down && !known_id) {
        note("position is required to put a finger down, e.g. {\"id\": " + std::to_string(id) + ", \"position\": [640, 360]}.");
        return;
    }
    if (!down) {  // lift where it was (or where `position` says); an unknown id is a no-op
        if (hasPos && known_id) in.on_touch_move(id, p);
        in.on_touch_end(id);
    } else if (known_id) {
        if (hasPos) in.on_touch_move(id, p);
    } else {
        in.on_touch_begin(id, p);
    }
}

template <class F>
void each_object_or_array(const Json& v, F&& f) {
    if (v.is_array()) {
        for (const Json& item : v) f(item);
    } else {
        f(v);
    }
}

}  // namespace

void apply_gamepad_json(Input& input, const Json& value, std::vector<std::string>& problems) {
    each_object_or_array(value, [&](const Json& g) { apply_one_gamepad(input, g, problems); });
}

void apply_touch_json(Input& input, const Json& value, std::vector<std::string>& problems) {
    each_object_or_array(value, [&](const Json& t) { apply_one_touch(input, t, problems); });
}

}  // namespace fa
