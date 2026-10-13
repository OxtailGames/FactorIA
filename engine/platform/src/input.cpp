#include "fa/platform/input.h"

#include <algorithm>
#include <cctype>
#include <format>

#include "fa/core/strings.h"

namespace fa {

// ---------------------------------------------------------------------------
// Key names
// ---------------------------------------------------------------------------
namespace {

struct KeyNames {
    std::array<std::string, size_t(Key::Count)> names;
    std::vector<std::string> all;  // every accepted spelling, for suggestions
    KeyNames() {
        auto set = [&](Key k, const char* n) { names[size_t(k)] = n; };
        for (int i = 0; i < 26; ++i) names[size_t(Key::A) + i] = std::string(1, char('A' + i));
        for (int i = 0; i < 10; ++i) names[size_t(Key::Num0) + i] = std::string(1, char('0' + i));
        set(Key::Space, "Space"); set(Key::Enter, "Enter"); set(Key::Escape, "Escape"); set(Key::Tab, "Tab");
        set(Key::Backspace, "Backspace"); set(Key::Insert, "Insert"); set(Key::Delete, "Delete");
        set(Key::Left, "Left"); set(Key::Right, "Right"); set(Key::Up, "Up"); set(Key::Down, "Down");
        set(Key::PageUp, "PageUp"); set(Key::PageDown, "PageDown"); set(Key::Home, "Home"); set(Key::End, "End");
        set(Key::LeftShift, "LeftShift"); set(Key::RightShift, "RightShift");
        set(Key::LeftControl, "LeftControl"); set(Key::RightControl, "RightControl");
        set(Key::LeftAlt, "LeftAlt"); set(Key::RightAlt, "RightAlt");
        set(Key::LeftSuper, "LeftSuper"); set(Key::RightSuper, "RightSuper");
        for (int i = 0; i < 12; ++i) names[size_t(Key::F1) + i] = "F" + std::to_string(i + 1);
        set(Key::Minus, "Minus"); set(Key::Equal, "Equal"); set(Key::LeftBracket, "LeftBracket");
        set(Key::RightBracket, "RightBracket"); set(Key::Backslash, "Backslash"); set(Key::Semicolon, "Semicolon");
        set(Key::Apostrophe, "Apostrophe"); set(Key::Comma, "Comma"); set(Key::Period, "Period");
        set(Key::Slash, "Slash"); set(Key::GraveAccent, "GraveAccent");
        set(Key::Unknown, "Unknown");
        for (size_t i = 1; i < size_t(Key::Count); ++i) all.push_back(names[i]);
    }
};
const KeyNames& key_names() {
    static const KeyNames k;
    return k;
}

const char* const kMouseNames[3] = {"MouseLeft", "MouseRight", "MouseMiddle"};
const char* const kGamepadNames[] = {
    "GamepadA", "GamepadB", "GamepadX", "GamepadY", "GamepadStart", "GamepadBack",
    "GamepadDpadLeft", "GamepadDpadRight", "GamepadDpadUp", "GamepadDpadDown",
    "GamepadLeftShoulder", "GamepadRightShoulder", "GamepadLeftStickLeft", "GamepadLeftStickRight",
    "GamepadLeftStickUp", "GamepadLeftStickDown"};

// Alternative spellings accepted for keys.
Key key_alias(std::string_view lower) {
    struct Alias { const char* name; Key key; };
    static const Alias aliases[] = {
        {"esc", Key::Escape}, {"return", Key::Enter}, {"del", Key::Delete}, {"ins", Key::Insert},
        {"pgup", Key::PageUp}, {"pgdn", Key::PageDown}, {"pagedn", Key::PageDown}, {"spacebar", Key::Space},
        {"lshift", Key::LeftShift}, {"rshift", Key::RightShift}, {"lctrl", Key::LeftControl},
        {"rctrl", Key::RightControl}, {"lalt", Key::LeftAlt}, {"ralt", Key::RightAlt},
        {"leftctrl", Key::LeftControl}, {"rightctrl", Key::RightControl},
        {"num0", Key::Num0}, {"num1", Key::Num1}, {"num2", Key::Num2}, {"num3", Key::Num3}, {"num4", Key::Num4},
        {"num5", Key::Num5}, {"num6", Key::Num6}, {"num7", Key::Num7}, {"num8", Key::Num8}, {"num9", Key::Num9},
        {"arrowleft", Key::Left}, {"arrowright", Key::Right}, {"arrowup", Key::Up}, {"arrowdown", Key::Down},
        {"backquote", Key::GraveAccent}, {"grave", Key::GraveAccent}, {"quote", Key::Apostrophe},
    };
    for (const auto& a : aliases)
        if (lower == a.name) return a.key;
    return Key::Unknown;
}

}  // namespace

const char* key_name(Key k) {
    size_t i = size_t(k);
    if (i >= size_t(Key::Count)) return "Unknown";
    return key_names().names[i].c_str();
}

Key key_from_name(std::string_view name) {
    const auto& kn = key_names();
    for (size_t i = 1; i < size_t(Key::Count); ++i)
        if (iequals(kn.names[i], name)) return Key(i);
    return key_alias(to_lower(name));
}

// ---------------------------------------------------------------------------
// Frame lifecycle + event feed
// ---------------------------------------------------------------------------
void Input::begin_frame() {
    prevKeys_ = keys_;
    prevMouse_ = mouse_buttons_;
    keyPressedEdge_.fill(false);
    keyReleasedEdge_.fill(false);
    mousePressedEdge_.fill(false);
    mouseReleasedEdge_.fill(false);
    prevTouchDown_ = touchDown_;
    touchPressedEdge_ = touchReleasedEdge_ = false;
    for (auto& t : touches_) t.pressedThisFrame = false;
    prevOverrides_ = overrides_;
    overridePressedEdge_.clear();
    overrideReleasedEdge_.clear();
    mouseDelta_ = {};
    wheel_ = 0.0f;
    text_.clear();
}

void Input::on_key(Key key, bool down) {
    size_t i = size_t(key);
    if (key == Key::Unknown || i >= size_t(Key::Count)) return;
    if (down && !keys_[i]) keyPressedEdge_[i] = true;
    if (!down && keys_[i]) keyReleasedEdge_[i] = true;
    keys_[i] = down;
}

void Input::on_mouse_move(Vec2 designPos) {
    mouseDelta_ += designPos - mouse_;
    mouse_ = designPos;
}

void Input::on_mouse_button(MouseButton b, bool down) {
    size_t i = size_t(b);
    if (i >= size_t(MouseButton::Count)) return;
    if (down && !mouse_buttons_[i]) mousePressedEdge_[i] = true;
    if (!down && mouse_buttons_[i]) mouseReleasedEdge_[i] = true;
    mouse_buttons_[i] = down;
}

void Input::on_mouse_wheel(float dy) { wheel_ += dy; }

void Input::on_touch_begin(std::uint64_t id, Vec2 designPos) {
    for (auto& t : touches_) {
        if (t.id == id) {  // duplicate begin: treat as move
            t.position = designPos;
            return;
        }
    }
    touches_.push_back(Touch{id, designPos, true});
    if (!touchDown_) touchPressedEdge_ = true;
    touchDown_ = true;
}

void Input::on_touch_move(std::uint64_t id, Vec2 designPos) {
    for (auto& t : touches_)
        if (t.id == id) t.position = designPos;
}

void Input::on_touch_end(std::uint64_t id) {
    auto it = std::find_if(touches_.begin(), touches_.end(), [&](const Touch& t) { return t.id == id; });
    if (it == touches_.end()) return;
    touches_.erase(it);
    if (touches_.empty() && touchDown_) {
        touchDown_ = false;
        touchReleasedEdge_ = true;
    }
}

void Input::on_text(std::uint32_t codepoint) { text_.push_back(char32_t(codepoint)); }

void Input::release_all() {
    for (size_t i = 0; i < keys_.size(); ++i) {
        if (keys_[i]) keyReleasedEdge_[i] = true;
        keys_[i] = false;
    }
    for (size_t i = 0; i < mouse_buttons_.size(); ++i) {
        if (mouse_buttons_[i]) mouseReleasedEdge_[i] = true;
        mouse_buttons_[i] = false;
    }
    if (touchDown_) touchReleasedEdge_ = true;
    touches_.clear();
    touchDown_ = false;
}

// ---------------------------------------------------------------------------
// Raw queries
// ---------------------------------------------------------------------------
bool Input::key_down(Key k) const { return size_t(k) < keys_.size() && keys_[size_t(k)]; }
bool Input::key_pressed(Key k) const { return size_t(k) < keys_.size() && keyPressedEdge_[size_t(k)]; }
bool Input::key_released(Key k) const { return size_t(k) < keys_.size() && keyReleasedEdge_[size_t(k)]; }
bool Input::mouse_down(MouseButton b) const { return size_t(b) < mouse_buttons_.size() && mouse_buttons_[size_t(b)]; }
bool Input::mouse_pressed(MouseButton b) const { return size_t(b) < mouse_buttons_.size() && mousePressedEdge_[size_t(b)]; }
bool Input::mouse_released(MouseButton b) const { return size_t(b) < mouse_buttons_.size() && mouseReleasedEdge_[size_t(b)]; }

// ---------------------------------------------------------------------------
// Actions
// ---------------------------------------------------------------------------
namespace {

std::vector<std::string> all_binding_names() {
    std::vector<std::string> names = key_names().all;
    for (const char* n : kMouseNames) names.emplace_back(n);
    names.emplace_back("Touch");
    for (const char* n : kGamepadNames) names.emplace_back(n);
    return names;
}

}  // namespace

bool Input::binding_down(const Binding& b) const {
    switch (b.kind) {
        case Binding::Kind::Key: return key_down(b.key);
        case Binding::Kind::Mouse: return mouse_down(b.mouse);
        case Binding::Kind::Touch: return touchDown_;
        case Binding::Kind::Gamepad: return false;
    }
    return false;
}

bool Input::binding_was_down(const Binding& b) const {
    switch (b.kind) {
        case Binding::Kind::Key: return size_t(b.key) < prevKeys_.size() && prevKeys_[size_t(b.key)];
        case Binding::Kind::Mouse: return prevMouse_[size_t(b.mouse)];
        case Binding::Kind::Touch: return prevTouchDown_;
        case Binding::Kind::Gamepad: return false;
    }
    return false;
}

namespace {
// Parses one binding name; returns false if unknown.
bool parse_binding(std::string_view name, Key& key, MouseButton& mouse, int& kind) {
    // kind: 0 key, 1 mouse, 2 touch, 3 gamepad
    std::string lower = to_lower(trim(name));
    if (lower == "touch") { kind = 2; return true; }
    for (int i = 0; i < 3; ++i)
        if (lower == to_lower(kMouseNames[i])) { kind = 1; mouse = MouseButton(i); return true; }
    if (lower.rfind("gamepad", 0) == 0) { kind = 3; return true; }  // accepted, never down for now
    Key k = key_from_name(trim(name));
    if (k != Key::Unknown) { kind = 0; key = k; return true; }
    return false;
}
}  // namespace

void Input::bind(std::string_view action, std::string_view binding) {
    Binding b;
    Key k = Key::Unknown;
    MouseButton m = MouseButton::Left;
    int kind = 0;
    if (!parse_binding(binding, k, m, kind)) return;
    b.kind = Binding::Kind(kind);
    b.key = k;
    b.mouse = m;
    actions_[std::string(action)].push_back(b);
}

std::vector<std::string> Input::set_actions(const Json& actions) {
    std::vector<std::string> problems;
    actions_.clear();
    if (actions.is_null()) return problems;
    if (!actions.is_object()) {
        problems.push_back(std::format(
            "input.actions must be an object mapping action names to binding lists, e.g. "
            "{{\"jump\": [\"Space\", \"W\"]}}; got {}", describe_json_value(actions)));
        return problems;
    }
    const auto candidates = all_binding_names();
    for (auto it = actions.begin(); it != actions.end(); ++it) {
        const std::string& name = it.key();
        const Json& list = it.value();
        std::vector<Binding>& out = actions_[name];  // even an empty list declares the action
        auto add = [&](const Json& item) {
            if (!item.is_string()) {
                problems.push_back(std::format("input.actions.{}: binding must be a string such as \"Space\", got {}",
                                               name, describe_json_value(item)));
                return;
            }
            Key k = Key::Unknown;
            MouseButton m = MouseButton::Left;
            int kind = 0;
            std::string text = item.get<std::string>();
            if (!parse_binding(text, k, m, kind)) {
                problems.push_back(std::format("input.actions.{}: unknown binding '{}'. {}", name, text,
                                               did_you_mean(text, candidates)));
                return;
            }
            Binding b;
            b.kind = Binding::Kind(kind);
            b.key = k;
            b.mouse = m;
            out.push_back(b);
        };
        if (list.is_array()) {
            for (const auto& item : list) add(item);
        } else if (list.is_string()) {
            add(list);
        } else {
            problems.push_back(std::format("input.actions.{}: expected an array of binding names, got {}", name,
                                           describe_json_value(list)));
        }
    }
    return problems;
}

std::vector<std::string> Input::action_names() const {
    std::vector<std::string> names;
    names.reserve(actions_.size());
    for (const auto& [k, v] : actions_) names.push_back(k);
    std::sort(names.begin(), names.end());
    return names;
}

bool Input::has_action(std::string_view action) const { return actions_.count(std::string(action)) != 0; }

bool Input::action_down(std::string_view action) const {
    std::string key(action);
    if (overrides_.count(key)) return true;
    auto it = actions_.find(key);
    if (it == actions_.end()) return false;
    for (const auto& b : it->second)
        if (binding_down(b)) return true;
    return false;
}

bool Input::action_pressed(std::string_view action) const {
    std::string name(action);
    bool wasDown = prevOverrides_.count(name) != 0;
    bool edge = overridePressedEdge_.count(name) != 0;
    auto it = actions_.find(name);
    if (it != actions_.end()) {
        for (const auto& b : it->second) {
            if (binding_was_down(b)) wasDown = true;
            switch (b.kind) {
                case Binding::Kind::Key: edge = edge || key_pressed(b.key); break;
                case Binding::Kind::Mouse: edge = edge || mouse_pressed(b.mouse); break;
                case Binding::Kind::Touch: edge = edge || touchPressedEdge_; break;
                case Binding::Kind::Gamepad: break;
            }
        }
    }
    return edge && !wasDown;
}

bool Input::action_released(std::string_view action) const {
    std::string name(action);
    if (action_down(action)) return false;
    bool wasDown = prevOverrides_.count(name) != 0;
    bool edge = overrideReleasedEdge_.count(name) != 0;
    auto it = actions_.find(name);
    if (it != actions_.end()) {
        for (const auto& b : it->second) {
            if (binding_was_down(b)) wasDown = true;
            switch (b.kind) {
                case Binding::Kind::Key: edge = edge || key_released(b.key); break;
                case Binding::Kind::Mouse: edge = edge || mouse_released(b.mouse); break;
                case Binding::Kind::Touch: edge = edge || touchReleasedEdge_; break;
                case Binding::Kind::Gamepad: break;
            }
        }
    }
    return wasDown || edge;
}

float Input::axis(std::string_view negative, std::string_view positive) const {
    return (action_down(positive) ? 1.0f : 0.0f) - (action_down(negative) ? 1.0f : 0.0f);
}

Vec2 Input::vector(std::string_view left, std::string_view right, std::string_view down, std::string_view up) const {
    Vec2 v{axis(left, right), axis(down, up)};
    float len = length(v);
    if (len > 1.0f) v = v / len;
    return v;
}

void Input::set_action_override(std::string_view action, bool down) {
    std::string name(action);
    bool was = overrides_.count(name) != 0;
    if (down) {
        if (!was) overridePressedEdge_[name] = true;
        overrides_[name] = true;
    } else if (was) {
        overrides_.erase(name);
        overrideReleasedEdge_[name] = true;
    }
}

void Input::clear_action_overrides() {
    for (const auto& [name, v] : overrides_) overrideReleasedEdge_[name] = true;
    overrides_.clear();
}

Json Input::snapshot() const {
    Json j = Json::object();
    Json keys = Json::array();
    for (size_t i = 1; i < size_t(Key::Count); ++i)
        if (keys_[i]) keys.push_back(key_name(Key(i)));
    j["keysDown"] = keys;
    Json buttons = Json::array();
    for (int i = 0; i < 3; ++i)
        if (mouse_buttons_[i]) buttons.push_back(kMouseNames[i]);
    j["mouse"] = {{"position", to_json(mouse_)}, {"delta", to_json(mouseDelta_)}, {"wheel", wheel_},
                  {"buttonsDown", buttons}};
    Json touches = Json::array();
    for (const auto& t : touches_)
        touches.push_back({{"id", t.id}, {"position", to_json(t.position)}, {"pressedThisFrame", t.pressedThisFrame}});
    j["touches"] = touches;
    Json actionsDown = Json::array();
    for (const auto& name : action_names())
        if (action_down(name)) actionsDown.push_back(name);
    for (const auto& [name, v] : overrides_)
        if (!has_action(name)) actionsDown.push_back(name);
    j["actionsDown"] = actionsDown;
    if (!text_.empty()) {
        std::string utf8;
        for (char32_t c : text_) {
            if (c < 0x80) utf8 += char(c);
            else if (c < 0x800) { utf8 += char(0xC0 | (c >> 6)); utf8 += char(0x80 | (c & 0x3F)); }
            else if (c < 0x10000) { utf8 += char(0xE0 | (c >> 12)); utf8 += char(0x80 | ((c >> 6) & 0x3F)); utf8 += char(0x80 | (c & 0x3F)); }
            else { utf8 += char(0xF0 | (c >> 18)); utf8 += char(0x80 | ((c >> 12) & 0x3F)); utf8 += char(0x80 | ((c >> 6) & 0x3F)); utf8 += char(0x80 | (c & 0x3F)); }
        }
        j["text"] = utf8;
    }
    return j;
}

}  // namespace fa
