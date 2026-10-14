#include "fa/platform/input.h"

#include <algorithm>
#include <cctype>
#include <cmath>
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
const char* const kPadButtonNames[] = {"A", "B", "X", "Y", "Start", "Back", "Guide", "DpadLeft", "DpadRight", "DpadUp",
                                       "DpadDown", "LeftShoulder", "RightShoulder", "LeftThumb", "RightThumb"};
const char* const kPadAxisNames[] = {"LeftX", "LeftY", "RightX", "RightY", "LeftTrigger", "RightTrigger"};
static_assert(std::size(kPadButtonNames) == size_t(GamepadButton::Count), "kPadButtonNames out of sync");
static_assert(std::size(kPadAxisNames) == size_t(GamepadAxis::Count), "kPadAxisNames out of sync");

// Every gamepad binding spelling ("GamepadA", "GamepadLeftStickUp", "GamepadRightTrigger"...) and what it reads.
struct PadBindingName {
    std::string name;
    bool isAxis;
    GamepadButton button;
    GamepadAxis axis;
    int sign;  // the direction of `axis` that counts (triggers: +1)
};
const std::vector<PadBindingName>& pad_binding_names() {
    static const std::vector<PadBindingName> table = [] {
        std::vector<PadBindingName> t;
        for (size_t i = 0; i < size_t(GamepadButton::Count); ++i)
            t.push_back({std::string("Gamepad") + kPadButtonNames[i], false, GamepadButton(i), GamepadAxis::LeftX, 1});
        for (const char* side : {"Left", "Right"}) {
            GamepadAxis x = std::string_view(side) == "Left" ? GamepadAxis::LeftX : GamepadAxis::RightX;
            GamepadAxis y = GamepadAxis(size_t(x) + 1);
            std::string base = std::string("Gamepad") + side + "Stick";
            t.push_back({base + "Left", true, GamepadButton::A, x, -1});
            t.push_back({base + "Right", true, GamepadButton::A, x, 1});
            t.push_back({base + "Up", true, GamepadButton::A, y, 1});
            t.push_back({base + "Down", true, GamepadButton::A, y, -1});
        }
        t.push_back({"GamepadLeftTrigger", true, GamepadButton::A, GamepadAxis::LeftTrigger, 1});
        t.push_back({"GamepadRightTrigger", true, GamepadButton::A, GamepadAxis::RightTrigger, 1});
        return t;
    }();
    return table;
}

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

const char* gamepad_button_name(GamepadButton b) { return size_t(b) < size_t(GamepadButton::Count) ? kPadButtonNames[size_t(b)] : "Unknown"; }
const char* gamepad_axis_name(GamepadAxis a) { return size_t(a) < size_t(GamepadAxis::Count) ? kPadAxisNames[size_t(a)] : "Unknown"; }

bool gamepad_button_from_name(std::string_view name, GamepadButton& out) {
    for (size_t i = 0; i < size_t(GamepadButton::Count); ++i)
        if (iequals(kPadButtonNames[i], trim(name))) { out = GamepadButton(i); return true; }
    return false;
}

bool gamepad_axis_from_name(std::string_view name, GamepadAxis& out) {
    for (size_t i = 0; i < size_t(GamepadAxis::Count); ++i)
        if (iequals(kPadAxisNames[i], trim(name))) { out = GamepadAxis(i); return true; }
    return false;
}

std::vector<std::string> gamepad_button_names() { return {std::begin(kPadButtonNames), std::end(kPadButtonNames)}; }
std::vector<std::string> gamepad_axis_names() { return {std::begin(kPadAxisNames), std::end(kPadAxisNames)}; }

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
    for (Pad& pad : pads_) {
        pad.prevButtons = pad.buttons;
        pad.prevAxes = pad.axes;
        pad.pressedEdge.fill(false);
        pad.releasedEdge.fill(false);
    }
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

// The first finger also drives the mouse (position + left button) until it lifts, so mouse-based UI and scripts work on
// touch devices unchanged. It lives here, not in the platform event handler, so every feed (a device, game.touch in
// tests) behaves the same.
void Input::on_touch_begin(std::uint64_t id, Vec2 designPos) {
    for (auto& t : touches_) {
        if (t.id == id) {  // duplicate begin: treat as move
            on_touch_move(id, designPos);
            return;
        }
    }
    touches_.push_back(Touch{id, designPos, true});
    if (!touchDown_) touchPressedEdge_ = true;
    touchDown_ = true;
    if (!primaryTouchDown_) {
        primaryTouchDown_ = true;
        primaryTouchId_ = id;
        on_mouse_move(designPos);
        on_mouse_button(MouseButton::Left, true);
    }
}

void Input::on_touch_move(std::uint64_t id, Vec2 designPos) {
    for (auto& t : touches_)
        if (t.id == id) {
            t.position = designPos;
            if (primaryTouchDown_ && primaryTouchId_ == id) on_mouse_move(designPos);
        }
}

void Input::on_touch_end(std::uint64_t id) {
    auto it = std::find_if(touches_.begin(), touches_.end(), [&](const Touch& t) { return t.id == id; });
    if (it == touches_.end()) return;
    Vec2 last = it->position;
    touches_.erase(it);
    if (touches_.empty() && touchDown_) {
        touchDown_ = false;
        touchReleasedEdge_ = true;
    }
    if (primaryTouchDown_ && primaryTouchId_ == id) {
        primaryTouchDown_ = false;
        on_mouse_move(last);
        on_mouse_button(MouseButton::Left, false);
    }
}

void Input::on_text(std::uint32_t codepoint) { text_.push_back(char32_t(codepoint)); }

void Input::on_gamepad_connected(int index, bool connected) {
    if (index < 0 || index >= kMaxGamepads) return;
    Pad& pad = pads_[size_t(index)];
    pad.connected = connected;
    if (connected) return;
    for (size_t i = 0; i < pad.buttons.size(); ++i) {
        if (pad.buttons[i]) pad.releasedEdge[i] = true;
        pad.buttons[i] = false;
    }
    pad.axes.fill(0.0f);
}

void Input::on_gamepad_button(int index, GamepadButton button, bool down) {
    if (index < 0 || index >= kMaxGamepads || size_t(button) >= size_t(GamepadButton::Count)) return;
    Pad& pad = pads_[size_t(index)];
    pad.connected = true;
    size_t i = size_t(button);
    if (down && !pad.buttons[i]) pad.pressedEdge[i] = true;
    if (!down && pad.buttons[i]) pad.releasedEdge[i] = true;
    pad.buttons[i] = down;
}

void Input::on_gamepad_axis(int index, GamepadAxis axis, float value) {
    if (index < 0 || index >= kMaxGamepads || size_t(axis) >= size_t(GamepadAxis::Count)) return;
    Pad& pad = pads_[size_t(index)];
    pad.connected = true;
    bool trigger = axis == GamepadAxis::LeftTrigger || axis == GamepadAxis::RightTrigger;
    if (!(value == value)) value = 0.0f;  // NaN from a broken driver or script
    pad.axes[size_t(axis)] = std::clamp(value, trigger ? 0.0f : -1.0f, 1.0f);
}

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
    primaryTouchDown_ = false;  // its mouse button was released above
    for (int i = 0; i < kMaxGamepads; ++i) on_gamepad_connected(i, false);
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

bool Input::gamepad_connected(int index) const { return index >= 0 && index < kMaxGamepads && pads_[size_t(index)].connected; }
bool Input::gamepad_down(int index, GamepadButton b) const {
    return gamepad_connected(index) && size_t(b) < size_t(GamepadButton::Count) && pads_[size_t(index)].buttons[size_t(b)];
}
bool Input::gamepad_pressed(int index, GamepadButton b) const {
    return gamepad_connected(index) && size_t(b) < size_t(GamepadButton::Count) && pads_[size_t(index)].pressedEdge[size_t(b)];
}
bool Input::gamepad_released(int index, GamepadButton b) const {
    return index >= 0 && index < kMaxGamepads && size_t(b) < size_t(GamepadButton::Count) &&
           pads_[size_t(index)].releasedEdge[size_t(b)];  // also on the frame the pad was unplugged
}
float Input::gamepad_raw_axis(int index, GamepadAxis a) const {
    return gamepad_connected(index) && size_t(a) < size_t(GamepadAxis::Count) ? pads_[size_t(index)].axes[size_t(a)] : 0.0f;
}
float Input::gamepad_axis(int index, GamepadAxis a) const {
    return gamepad_connected(index) && size_t(a) < size_t(GamepadAxis::Count) ? pad_axis(pads_[size_t(index)], a, false) : 0.0f;
}
void Input::set_gamepad_deadzone(float deadzone) { deadzone_ = std::clamp(deadzone, 0.0f, 0.95f); }

// Sticks: radial deadzone on the (x, y) pair, the rest rescaled to 0..1 along the same direction. Triggers: linear.
float Input::pad_axis(const Pad& pad, GamepadAxis a, bool previous) const {
    const auto& ax = previous ? pad.prevAxes : pad.axes;
    const float dz = deadzone_;
    if (a == GamepadAxis::LeftTrigger || a == GamepadAxis::RightTrigger) {
        float t = ax[size_t(a)];
        return t <= dz ? 0.0f : std::min(1.0f, (t - dz) / (1.0f - dz));
    }
    const size_t xi = (a == GamepadAxis::LeftX || a == GamepadAxis::LeftY) ? size_t(GamepadAxis::LeftX) : size_t(GamepadAxis::RightX);
    const float x = ax[xi], y = ax[xi + 1];
    const float mag = std::sqrt(x * x + y * y);
    if (mag <= dz) return 0.0f;
    const float scale = std::min(1.0f, (mag - dz) / (1.0f - dz)) / mag;
    return (size_t(a) == xi ? x : y) * scale;
}

// ---------------------------------------------------------------------------
// Actions
// ---------------------------------------------------------------------------
namespace {

std::vector<std::string> all_binding_names() {
    std::vector<std::string> names = key_names().all;
    for (const char* n : kMouseNames) names.emplace_back(n);
    names.emplace_back("Touch");
    for (const auto& p : pad_binding_names()) names.push_back(p.name);
    return names;
}

}  // namespace

float Input::binding_value(const Binding& b, bool previous) const {
    switch (b.kind) {
        case Binding::Kind::Key: return (previous ? prevKeys_ : keys_)[size_t(b.key)] ? 1.0f : 0.0f;
        case Binding::Kind::Mouse: return (previous ? prevMouse_ : mouse_buttons_)[size_t(b.mouse)] ? 1.0f : 0.0f;
        case Binding::Kind::Touch: return (previous ? prevTouchDown_ : touchDown_) ? 1.0f : 0.0f;
        case Binding::Kind::PadButton:
            for (const Pad& pad : pads_)  // a disconnected pad has nothing down
                if ((previous ? pad.prevButtons : pad.buttons)[size_t(b.button)]) return 1.0f;
            return 0.0f;
        case Binding::Kind::PadAxis: {
            float v = 0.0f;
            for (const Pad& pad : pads_) v = std::max(v, float(b.sign) * pad_axis(pad, b.axis, previous));
            return v;
        }
    }
    return 0.0f;
}

// Parses one binding name; returns false if unknown.
bool Input::parse_binding(std::string_view name, Binding& out) {
    std::string_view text = trim(name);
    std::string lower = to_lower(text);
    out = Binding{};
    if (lower == "touch") { out.kind = Binding::Kind::Touch; return true; }
    for (int i = 0; i < 3; ++i)
        if (lower == to_lower(kMouseNames[i])) { out.kind = Binding::Kind::Mouse; out.mouse = MouseButton(i); return true; }
    if (starts_with(lower, "gamepad")) {
        for (const auto& p : pad_binding_names()) {
            if (!iequals(p.name, text)) continue;
            out.kind = p.isAxis ? Binding::Kind::PadAxis : Binding::Kind::PadButton;
            out.button = p.button;
            out.axis = p.axis;
            out.sign = p.sign;
            return true;
        }
        return false;
    }
    Key k = key_from_name(text);
    if (k == Key::Unknown) return false;
    out.kind = Binding::Kind::Key;
    out.key = k;
    return true;
}

bool Input::is_binding_name(std::string_view name) {
    Binding b;
    return parse_binding(name, b);
}

std::vector<std::string> Input::binding_names() { return all_binding_names(); }

void Input::bind(std::string_view action, std::string_view binding) {
    Binding b;
    if (parse_binding(binding, b)) actions_[std::string(action)].push_back(b);
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
            Binding b;
            std::string text = item.get<std::string>();
            if (!parse_binding(text, b)) {
                problems.push_back(std::format("input.actions.{}: unknown binding '{}'. {}", name, text,
                                               did_you_mean(text, candidates)));
                return;
            }
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

float Input::action_value(std::string_view action) const {
    std::string key(action);
    if (overrides_.count(key)) return 1.0f;
    auto it = actions_.find(key);
    if (it == actions_.end()) return 0.0f;
    float v = 0.0f;
    for (const auto& b : it->second) v = std::max(v, binding_value(b, false));
    return v;
}

bool Input::action_down(std::string_view action) const { return action_value(action) >= kActionDownThreshold; }

bool Input::action_pressed(std::string_view action) const {
    std::string name(action);
    bool wasDown = prevOverrides_.count(name) != 0;
    bool edge = overridePressedEdge_.count(name) != 0;
    auto it = actions_.find(name);
    if (it != actions_.end()) {
        for (const auto& b : it->second) {
            if (binding_value(b, true) >= kActionDownThreshold) wasDown = true;
            switch (b.kind) {
                case Binding::Kind::Key: edge = edge || key_pressed(b.key); break;
                case Binding::Kind::Mouse: edge = edge || mouse_pressed(b.mouse); break;
                case Binding::Kind::Touch: edge = edge || touchPressedEdge_; break;
                case Binding::Kind::PadButton:
                    for (int i = 0; i < kMaxGamepads; ++i) edge = edge || gamepad_pressed(i, b.button);
                    break;
                // An analog value has no event, only a level: it is a press when it is up now and was not at frame start.
                case Binding::Kind::PadAxis: edge = edge || binding_value(b, false) >= kActionDownThreshold; break;
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
            if (binding_value(b, true) >= kActionDownThreshold) wasDown = true;
            switch (b.kind) {
                case Binding::Kind::Key: edge = edge || key_released(b.key); break;
                case Binding::Kind::Mouse: edge = edge || mouse_released(b.mouse); break;
                case Binding::Kind::Touch: edge = edge || touchReleasedEdge_; break;
                case Binding::Kind::PadButton:
                    for (int i = 0; i < kMaxGamepads; ++i) edge = edge || gamepad_released(i, b.button);
                    break;
                case Binding::Kind::PadAxis: break;  // was down and is not now: wasDown covers it
            }
        }
    }
    return wasDown || edge;
}

float Input::axis(std::string_view negative, std::string_view positive) const {
    return action_value(positive) - action_value(negative);
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
    Json pads = Json::array();  // only connected pads, so a game without a gamepad dumps what it always did
    for (int i = 0; i < kMaxGamepads; ++i) {
        if (!pads_[size_t(i)].connected) continue;
        Json down = Json::array(), axes = Json::object();
        for (size_t b = 0; b < size_t(GamepadButton::Count); ++b)
            if (pads_[size_t(i)].buttons[b]) down.push_back(kPadButtonNames[b]);
        for (size_t a = 0; a < size_t(GamepadAxis::Count); ++a)
            if (pads_[size_t(i)].axes[a] != 0.0f) axes[kPadAxisNames[a]] = pads_[size_t(i)].axes[a];
        pads.push_back({{"index", i}, {"buttonsDown", down}, {"axes", axes}});
    }
    if (!pads.empty()) j["gamepads"] = pads;
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
