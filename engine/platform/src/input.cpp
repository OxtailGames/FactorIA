#include "fa/platform/input.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <format>

#include "fa/core/strings.h"
#include "fa/core/utf8.h"

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

namespace {
const char* const kPadTypeNames[] = {"generic", "xbox", "playstation", "nintendo", "steamdeck"};
const char* const kDeviceNames[] = {"keyboard", "mouse", "gamepad", "touch"};
}  // namespace

const char* gamepad_type_name(GamepadType t) { return size_t(t) < std::size(kPadTypeNames) ? kPadTypeNames[size_t(t)] : "generic"; }
bool gamepad_type_from_name(std::string_view name, GamepadType& out) {
    for (size_t i = 0; i < std::size(kPadTypeNames); ++i)
        if (iequals(kPadTypeNames[i], trim(name))) { out = GamepadType(i); return true; }
    return false;
}
std::vector<std::string> gamepad_type_names() { return {std::begin(kPadTypeNames), std::end(kPadTypeNames)}; }
const char* input_device_name(InputDevice d) { return size_t(d) < std::size(kDeviceNames) ? kDeviceNames[size_t(d)] : "keyboard"; }

GamepadType gamepad_type_from_ids(std::uint16_t vendorId, std::string_view name) {
    switch (vendorId) {
        case 0x045e: return GamepadType::Xbox;         // Microsoft
        case 0x054c: return GamepadType::PlayStation;  // Sony
        case 0x057e: return GamepadType::Nintendo;
        case 0x28de: return GamepadType::SteamDeck;    // Valve
        default: break;
    }
    const std::string n = to_lower(name);
    auto has = [&](std::initializer_list<const char*> words) {
        for (const char* w : words)
            if (n.find(w) != std::string::npos) return true;
        return false;
    };
    if (has({"xbox", "xinput"})) return GamepadType::Xbox;
    if (has({"playstation", "dualshock", "dualsense", "ps4", "ps5"})) return GamepadType::PlayStation;
    if (has({"nintendo", "switch", "joy-con"})) return GamepadType::Nintendo;
    if (has({"steam"})) return GamepadType::SteamDeck;
    return GamepadType::Generic;
}

std::string make_gamepad_id(std::uint16_t vendor, std::uint16_t product, std::string_view name, std::string_view unique) {
    std::string id = std::format("{:04x}:{:04x}:{}", vendor, product, name);
    if (!unique.empty()) {
        id += '#';
        id += unique;
    }
    return id;
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
    backEdge_ = false;
    pasteEdge_ = false;
}

void Input::vibrate(float seconds) {
    if (vibrations_.size() < 256) vibrations_.push_back(seconds);  // nobody plays them in a headless run: keep the log short
}

void Input::on_key(Key key, bool down) {
    if (InputObserver* o = tap(); o && key != Key::Unknown) o->observe_key(key, down);
    size_t i = size_t(key);
    if (key == Key::Unknown || i >= size_t(Key::Count)) return;
    if (down && !keys_[i]) {
        keyPressedEdge_[i] = true;
        lastDevice_ = InputDevice::Keyboard;
    }
    if (!down && keys_[i]) keyReleasedEdge_[i] = true;
    keys_[i] = down;
}

void Input::on_mouse_move(Vec2 designPos) {
    if (InputObserver* o = tap()) o->observe_mouse_move(designPos);
    if (designPos != mouse_) lastDevice_ = InputDevice::Mouse;
    mouseDelta_ += designPos - mouse_;
    mouse_ = designPos;
}

void Input::on_mouse_delta(Vec2 delta) {
    if (delta != Vec2{}) lastDevice_ = InputDevice::Mouse;
    mouseDelta_ += delta;
}

void Input::on_mouse_button(MouseButton b, bool down) {
    if (InputObserver* o = tap()) o->observe_mouse_button(b, down);
    size_t i = size_t(b);
    if (i >= size_t(MouseButton::Count)) return;
    if (down && !mouse_buttons_[i]) {
        mousePressedEdge_[i] = true;
        lastDevice_ = InputDevice::Mouse;
    }
    if (!down && mouse_buttons_[i]) mouseReleasedEdge_[i] = true;
    mouse_buttons_[i] = down;
}

void Input::on_mouse_wheel(float dy) {
    if (dy != 0.0f) lastDevice_ = InputDevice::Mouse;
    wheel_ += dy;
}

// The first finger also drives the mouse (position + left button) until it lifts, so mouse-based UI and scripts work on
// touch devices unchanged. It lives here, not in the platform event handler, so every feed (a device, game.touch in
// tests) behaves the same.
void Input::on_touch_begin(std::uint64_t id, Vec2 designPos) {
    if (InputObserver* o = tap()) o->observe_touch_begin(id, designPos);
    ObserverMute mute(*this);
    if (touch_control_of(id)) return on_touch_move(id, designPos);  // duplicate begin of a finger a control holds
    for (auto it = touchControls_.rbegin(); it != touchControls_.rend(); ++it) {  // the later control wins an overlap
        if (it->down || !it->rect.contains(designPos)) continue;
        it->down = true;
        it->finger = id;
        lastDevice_ = InputDevice::Touch;
        return on_touch_move(id, designPos);
    }
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
    lastDevice_ = InputDevice::Touch;  // after the mouse mirror above
}

void Input::on_touch_move(std::uint64_t id, Vec2 designPos) {
    if (InputObserver* o = tap()) o->observe_touch_move(id, designPos);
    ObserverMute mute(*this);
    if (TouchControl* c = touch_control_of(id)) {
        if (c->stick) {
            const float radius = std::max(1.0f, std::min(c->rect.w, c->rect.h) * 0.5f);
            Vec2 v = (designPos - c->rect.center()) / radius;
            v.y = -v.y;  // stick +Y is up, the screen's is down
            const float len = std::sqrt(v.x * v.x + v.y * v.y);
            c->value = len > 1.0f ? v / len : v;
        }
        lastDevice_ = InputDevice::Touch;
        return update_touch_pad();
    }
    for (auto& t : touches_)
        if (t.id == id) {
            t.position = designPos;
            if (primaryTouchDown_ && primaryTouchId_ == id) on_mouse_move(designPos);
            lastDevice_ = InputDevice::Touch;
        }
}

void Input::on_touch_end(std::uint64_t id) {
    if (InputObserver* o = tap()) o->observe_touch_end(id);
    ObserverMute mute(*this);
    if (TouchControl* c = touch_control_of(id)) {
        c->down = false;
        c->value = {};
        lastDevice_ = InputDevice::Touch;
        return update_touch_pad();
    }
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
    lastDevice_ = InputDevice::Touch;
}

Input::TouchControl* Input::touch_control_of(std::uint64_t finger) {
    for (TouchControl& c : touchControls_)
        if (c.down && c.finger == finger) return &c;
    return nullptr;
}

void Input::set_touch_controls(std::vector<TouchControl> controls) {
    for (TouchControl& c : controls) {
        c.down = false;
        c.value = {};
        for (const TouchControl& old : touchControls_)
            if (old.id == c.id && old.down) {
                c.down = true;
                c.finger = old.finger;
                c.value = c.stick == old.stick ? old.value : Vec2{};
            }
    }
    touchControls_ = std::move(controls);
    update_touch_pad();
}

// Edges like a real pad's: a button that went down or up since begin_frame() keeps its edge.
void Input::update_touch_pad() {
    Pad& pad = pads_[kMaxGamepads];
    std::array<bool, size_t(GamepadButton::Count)> buttons{};
    pad.axes.fill(0.0f);
    for (const TouchControl& c : touchControls_) {
        if (!c.down) continue;
        if (!c.stick) {
            buttons[size_t(c.button)] = true;
            continue;
        }
        const size_t x = size_t(c.rightStick ? GamepadAxis::RightX : GamepadAxis::LeftX);
        pad.axes[x] = c.value.x;
        pad.axes[x + 1] = c.value.y;
    }
    for (size_t i = 0; i < buttons.size(); ++i) {
        if (buttons[i] && !pad.buttons[i]) pad.pressedEdge[i] = true;
        if (!buttons[i] && pad.buttons[i]) pad.releasedEdge[i] = true;
    }
    pad.buttons = buttons;
}

bool Input::command_chord_down() const {
    return key_down(Key::LeftControl) || key_down(Key::RightControl) || key_down(Key::LeftSuper) || key_down(Key::RightSuper);
}
bool Input::paste_pressed() const { return pasteEdge_ || (!pasteFromEvents_ && key_pressed(Key::V) && command_chord_down()); }
bool Input::copy_pressed() const { return key_pressed(Key::C) && command_chord_down(); }

void Input::on_text(std::uint32_t codepoint) { text_.push_back(char32_t(codepoint)); }

std::string Input::text_utf8() const {
    std::string utf8;
    for (char32_t c : text_) utf8_append(utf8, c);
    return utf8;
}

void Input::mark_connected(int index) {
    Pad& pad = pads_[size_t(index)];
    pad.connected = true;
    if (pad.announced) return;
    pad.announced = true;
    if (pad.info.id.empty()) {  // nobody said who this is (a test, a replay, a backend without ids)
        pad.info.name = "Gamepad";
        pad.info.id = make_gamepad_id(0, 0, pad.info.name, "slot " + std::to_string(index));
        pad.info.type = pad.type;
    }
    auto& memory = padSlotMemory_;
    std::erase_if(memory, [&](const auto& e) { return e.first == pad.info.id; });
    memory.emplace_back(pad.info.id, index);
    if (memory.size() > 16) memory.erase(memory.begin());
    if (padEvents_.size() >= 64) padEvents_.erase(padEvents_.begin());
    padEvents_.push_back(GamepadEvent{true, index, pad.info});
}

void Input::on_gamepad_connected(int index, bool connected) {
    if (InputObserver* o = tap()) o->observe_gamepad_connected(index, connected);
    if (index < 0 || index >= kMaxGamepads) return;
    Pad& pad = pads_[size_t(index)];
    if (connected) {
        mark_connected(index);
        return;
    }
    release_pad(index);
    if (pad.announced) {
        pad.announced = false;
        if (padEvents_.size() >= 64) padEvents_.erase(padEvents_.begin());
        padEvents_.push_back(GamepadEvent{false, index, pad.info});
    }
}

void Input::release_pad(int index) {
    Pad& pad = pads_[size_t(index)];
    pad.connected = false;
    for (size_t i = 0; i < pad.buttons.size(); ++i) {
        if (pad.buttons[i]) pad.releasedEdge[i] = true;
        pad.buttons[i] = false;
    }
    pad.axes.fill(0.0f);
}

void Input::set_gamepad_info(int index, GamepadInfo info) {
    if (index < 0 || index >= kMaxGamepads) return;
    Pad& pad = pads_[size_t(index)];
    if (info.id.empty()) info.id = make_gamepad_id(info.vendor, info.product, info.name.empty() ? "Gamepad" : info.name, "slot " + std::to_string(index));
    if (info.name.empty()) info.name = "Gamepad";
    pad.type = info.type;
    pad.info = std::move(info);
}

const GamepadInfo& Input::gamepad_info(int index) const {
    static const GamepadInfo none;
    return index >= 0 && index < kMaxGamepads ? pads_[size_t(index)].info : none;
}

int Input::choose_gamepad_slot(std::string_view id, std::span<const bool> occupied) const {
    auto free = [&](int i) { return i >= 0 && i < kMaxGamepads && (size_t(i) >= occupied.size() || !occupied[size_t(i)]); };
    for (const auto& [rememberedId, slot] : padSlotMemory_)
        if (rememberedId == id && free(slot)) return slot;
    for (int i = 0; i < kMaxGamepads; ++i)
        if (free(i)) return i;
    return -1;
}

std::vector<GamepadEvent> Input::take_gamepad_events() { return std::exchange(padEvents_, {}); }

void Input::on_gamepad_button(int index, GamepadButton button, bool down) {
    if (InputObserver* o = tap()) o->observe_gamepad_button(index, button, down);
    if (index < 0 || index >= kMaxGamepads || size_t(button) >= size_t(GamepadButton::Count)) return;
    Pad& pad = pads_[size_t(index)];
    mark_connected(index);
    size_t i = size_t(button);
    if (down && !pad.buttons[i]) {
        pad.pressedEdge[i] = true;
        lastDevice_ = InputDevice::Gamepad;
    }
    if (!down && pad.buttons[i]) pad.releasedEdge[i] = true;
    pad.buttons[i] = down;
}

void Input::on_gamepad_axis(int index, GamepadAxis axis, float value) {
    if (InputObserver* o = tap()) o->observe_gamepad_axis(index, axis, value);
    if (index < 0 || index >= kMaxGamepads || size_t(axis) >= size_t(GamepadAxis::Count)) return;
    Pad& pad = pads_[size_t(index)];
    mark_connected(index);
    bool trigger = axis == GamepadAxis::LeftTrigger || axis == GamepadAxis::RightTrigger;
    if (!(value == value)) value = 0.0f;  // NaN from a broken driver or script
    value = std::clamp(value, trigger ? 0.0f : -1.0f, 1.0f);
    // A poll feeds the same value every frame: only a CHANGE past the deadzone is the player touching the pad.
    if (value != pad.axes[size_t(axis)] && std::fabs(value) > deadzone_) lastDevice_ = InputDevice::Gamepad;
    pad.axes[size_t(axis)] = value;
}

void Input::set_gamepad_type(int index, GamepadType type) {
    if (index < 0 || index >= kMaxGamepads) return;
    pads_[size_t(index)].type = type;
    pads_[size_t(index)].info.type = type;
}

GamepadType Input::gamepad_type(int index) const {
    return gamepad_connected(index) ? pads_[size_t(index)].type : GamepadType::Generic;
}

void Input::reset_options() {
    reset_bindings();
    mouseVisible_ = true;
    mouseLocked_ = keyboardShown_ = platformKeyboard_ = false;
    backEdge_ = false;
    vibrations_.clear();
    lastDevice_ = InputDevice::Keyboard;
    for (Pad& pad : pads_) {
        pad.type = GamepadType::Generic;
        pad.info = {};
        pad.announced = false;  // a new test starts with no pad announced, whatever the last one left plugged in
    }
    padEvents_.clear();
    padSlotMemory_.clear();
}

void Input::release_all() {
    if (InputObserver* o = tap()) o->observe_release_all();
    ObserverMute mute(*this);
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
    for (int i = 0; i < kMaxGamepads; ++i) release_pad(i);  // not announced: the pad is still plugged in
    for (TouchControl& c : touchControls_) {
        c.down = false;
        c.value = {};
    }
    update_touch_pad();
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

std::vector<Input::Binding> Input::parse_binding_list(const std::string& action, const Json& list,
                                                      const std::vector<std::string>& candidates,
                                                      std::vector<std::string>& problems) const {
    std::vector<Binding> out;
    auto add = [&](const Json& item) {
        if (!item.is_string()) {
            problems.push_back(std::format("input.actions.{}: binding must be a string such as \"Space\", got {}", action,
                                           describe_json_value(item)));
            return;
        }
        Binding b;
        std::string text = item.get<std::string>();
        if (!parse_binding(text, b)) {
            problems.push_back(std::format("input.actions.{}: unknown binding '{}'. {}", action, text,
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
        problems.push_back(std::format("input.actions.{}: expected an array of binding names, got {}", action,
                                       describe_json_value(list)));
    }
    return out;
}

std::vector<std::string> Input::set_actions(const Json& actions) {
    std::vector<std::string> problems;
    actions_.clear();
    projectActions_ = actions;
    if (actions.is_null()) return problems;
    if (!actions.is_object()) {
        problems.push_back(std::format(
            "input.actions must be an object mapping action names to binding lists, e.g. "
            "{{\"jump\": [\"Space\", \"W\"]}}; got {}", describe_json_value(actions)));
        return problems;
    }
    const auto candidates = all_binding_names();
    for (auto it = actions.begin(); it != actions.end(); ++it)  // even an empty list declares the action
        actions_[it.key()] = parse_binding_list(it.key(), it.value(), candidates, problems);
    return problems;
}

std::string Input::binding_name(const Binding& b) {
    switch (b.kind) {
        case Binding::Kind::Key: return key_name(b.key);
        case Binding::Kind::Mouse: return kMouseNames[size_t(b.mouse)];
        case Binding::Kind::Touch: return "Touch";
        case Binding::Kind::PadButton: return std::string("Gamepad") + kPadButtonNames[size_t(b.button)];
        case Binding::Kind::PadAxis:
            for (const auto& p : pad_binding_names())
                if (p.isAxis && p.axis == b.axis && p.sign == b.sign) return p.name;
    }
    return "";
}

namespace {
// "Unknown input action 'x'. Did you mean ...? Valid: ..." for the rebinding functions.
std::string unknown_action_message(std::string_view what, std::string_view action, const std::vector<std::string>& names) {
    return std::format("{}: unknown input action '{}'. {}", what, action,
                       names.empty() ? std::string("No actions are defined; add them to factoria.json under input.actions.")
                                     : did_you_mean(action, names));
}
}  // namespace

std::vector<std::string> Input::rebind(std::string_view action, const std::vector<std::string>& bindings) {
    std::vector<std::string> problems;
    auto it = actions_.find(std::string(action));
    if (it == actions_.end()) {
        problems.push_back(unknown_action_message("input.rebind", action, action_names()));
        return problems;
    }
    const auto candidates = all_binding_names();
    std::vector<Binding> parsed;
    for (const std::string& text : bindings) {
        Binding b;
        if (parse_binding(text, b)) parsed.push_back(b);
        else problems.push_back(std::format("input.rebind('{}'): unknown binding '{}'. {}", action, text, did_you_mean(text, candidates)));
    }
    if (problems.empty()) it->second = std::move(parsed);
    return problems;
}

std::vector<std::string> Input::bindings(std::string_view action) const {
    std::vector<std::string> out;
    auto it = actions_.find(std::string(action));
    if (it != actions_.end())
        for (const Binding& b : it->second) out.push_back(binding_name(b));
    return out;
}

std::vector<std::string> Input::reset_bindings(std::string_view action) {
    if (action.empty()) return projectActions_.is_null() ? std::vector<std::string>{} : set_actions(projectActions_);
    std::vector<std::string> problems;
    const std::string name(action);
    if (!actions_.count(name)) {
        problems.push_back(unknown_action_message("input.resetBindings", action, action_names()));
        return problems;
    }
    if (projectActions_.is_object() && projectActions_.contains(name))
        actions_[name] = parse_binding_list(name, projectActions_[name], all_binding_names(), problems);
    else
        actions_.erase(name);  // made by bind(), not declared by the project
    return problems;
}

// ---------------------------------------------------------------------------
// Last input and button names
// ---------------------------------------------------------------------------
std::string Input::last_pressed() const {
    for (size_t i = 1; i < size_t(Key::Count); ++i)
        if (keyPressedEdge_[i]) return key_name(Key(i));
    if (touchPressedEdge_) return "Touch";
    for (size_t i = 0; i < size_t(MouseButton::Count); ++i)
        if (mousePressedEdge_[i]) return kMouseNames[i];
    for (const Pad& pad : pads_)
        for (size_t i = 0; i < size_t(GamepadButton::Count); ++i)
            if (pad.pressedEdge[i]) return std::string("Gamepad") + kPadButtonNames[i];
    for (const auto& p : pad_binding_names()) {
        if (!p.isAxis) continue;
        for (const Pad& pad : pads_)
            if (float(p.sign) * pad_axis(pad, p.axis, false) >= kActionDownThreshold &&
                float(p.sign) * pad_axis(pad, p.axis, true) < kActionDownThreshold)
                return p.name;
    }
    return "";
}

namespace {
// What each family prints on a pad's buttons, in GamepadButton order (A B X Y Start Back Guide DpadLeft DpadRight DpadUp
// DpadDown LeftShoulder RightShoulder LeftThumb RightThumb). Our buttons are positions (A = bottom, B = right, X = left,
// Y = top), so a Nintendo pad, which letters its buttons by name, has B at the bottom and A at the right.
const char* const kPadLabels[5][size_t(GamepadButton::Count)] = {
    // Generic: the Xbox names
    {"A", "B", "X", "Y", "Menu", "View", "Guide", "D-Pad Left", "D-Pad Right", "D-Pad Up", "D-Pad Down", "LB", "RB", "LS", "RS"},
    // Xbox
    {"A", "B", "X", "Y", "Menu", "View", "Xbox", "D-Pad Left", "D-Pad Right", "D-Pad Up", "D-Pad Down", "LB", "RB", "LS", "RS"},
    // PlayStation
    {"Cross", "Circle", "Square", "Triangle", "Options", "Create", "PS", "D-Pad Left", "D-Pad Right", "D-Pad Up",
     "D-Pad Down", "L1", "R1", "L3", "R3"},
    // Nintendo
    {"B", "A", "Y", "X", "+", "-", "Home", "D-Pad Left", "D-Pad Right", "D-Pad Up", "D-Pad Down", "L", "R", "LS", "RS"},
    // Steam Deck
    {"A", "B", "X", "Y", "Menu", "View", "Steam", "D-Pad Left", "D-Pad Right", "D-Pad Up", "D-Pad Down", "L1", "R1", "L3", "R3"},
};
const char* const kTriggerLabels[5][2] = {{"LT", "RT"}, {"LT", "RT"}, {"L2", "R2"}, {"ZL", "ZR"}, {"L2", "R2"}};
}  // namespace

std::string Input::binding_label(std::string_view binding, GamepadType type) {
    Binding b;
    if (!parse_binding(binding, b)) return "";
    const size_t t = size_t(type) < 5 ? size_t(type) : 0;
    switch (b.kind) {
        case Binding::Kind::Key: return key_name(b.key);
        case Binding::Kind::Mouse:
            return std::string(b.mouse == MouseButton::Left ? "Left" : b.mouse == MouseButton::Right ? "Right" : "Middle") + " Click";
        case Binding::Kind::Touch: return "Touch";
        case Binding::Kind::PadButton: return kPadLabels[t][size_t(b.button)];
        case Binding::Kind::PadAxis: {
            if (b.axis == GamepadAxis::LeftTrigger || b.axis == GamepadAxis::RightTrigger)
                return kTriggerLabels[t][b.axis == GamepadAxis::RightTrigger ? 1 : 0];
            const bool left = b.axis == GamepadAxis::LeftX || b.axis == GamepadAxis::LeftY;
            const bool horizontal = b.axis == GamepadAxis::LeftX || b.axis == GamepadAxis::RightX;
            return std::string(left ? "Left" : "Right") + " Stick " +
                   (horizontal ? (b.sign < 0 ? "Left" : "Right") : (b.sign > 0 ? "Up" : "Down"));
        }
    }
    return "";
}

std::string Input::button_name(std::string_view bindingOrAction, int pad) const {
    const GamepadType type = gamepad_type(pad);
    auto it = actions_.find(std::string(bindingOrAction));
    if (it == actions_.end()) return binding_label(bindingOrAction, type);
    const bool wantPad = lastDevice_ == InputDevice::Gamepad;
    const Binding* pick = nullptr;
    for (const Binding& b : it->second) {
        const bool isPad = b.kind == Binding::Kind::PadButton || b.kind == Binding::Kind::PadAxis;
        if (isPad == wantPad) { pick = &b; break; }
        if (!pick) pick = &b;  // fallback: the first binding of any kind
    }
    return pick ? binding_label(binding_name(*pick), type) : "";
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
                    for (const Pad& pad : pads_) edge = edge || pad.pressedEdge[size_t(b.button)];  // the touch pad too
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
                    for (const Pad& pad : pads_) edge = edge || pad.releasedEdge[size_t(b.button)];
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
    if (!text_.empty()) j["text"] = text_utf8();
    return j;
}

}  // namespace fa
