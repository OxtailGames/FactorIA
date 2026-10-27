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

std::uint8_t modifier_from_name(std::string_view name) {
    const std::string l = to_lower(trim(name));
    if (l == "shift") return modifier::Shift;
    if (l == "ctrl" || l == "control") return modifier::Ctrl;
    if (l == "alt") return modifier::Alt;
    if (l == "super" || l == "cmd" || l == "command" || l == "win") return modifier::Super;
    return 0;
}

const char* modifier_name(std::uint8_t bit) {
    switch (bit) {
        case modifier::Shift: return "Shift";
        case modifier::Ctrl: return "Ctrl";
        case modifier::Alt: return "Alt";
        case modifier::Super: return "Super";
    }
    return "";
}

Key modifier_key(std::uint8_t bit, bool right) {
    switch (bit) {
        case modifier::Shift: return right ? Key::RightShift : Key::LeftShift;
        case modifier::Ctrl: return right ? Key::RightControl : Key::LeftControl;
        case modifier::Alt: return right ? Key::RightAlt : Key::LeftAlt;
        case modifier::Super: return right ? Key::RightSuper : Key::LeftSuper;
    }
    return Key::Unknown;
}

namespace {
// The order a chord prints its modifiers in.
constexpr std::uint8_t kModifierOrder[4] = {modifier::Ctrl, modifier::Alt, modifier::Shift, modifier::Super};
std::pair<Key, Key> modifier_keys(std::uint8_t bit) {
    switch (bit) {
        case modifier::Shift: return {Key::LeftShift, Key::RightShift};
        case modifier::Ctrl: return {Key::LeftControl, Key::RightControl};
        case modifier::Alt: return {Key::LeftAlt, Key::RightAlt};
        default: return {Key::LeftSuper, Key::RightSuper};
    }
}
bool is_modifier_key(size_t k) {
    return k == size_t(Key::LeftShift) || k == size_t(Key::RightShift) || k == size_t(Key::LeftControl) ||
           k == size_t(Key::RightControl) || k == size_t(Key::LeftAlt) || k == size_t(Key::RightAlt) ||
           k == size_t(Key::LeftSuper) || k == size_t(Key::RightSuper);
}
std::string modifier_prefix(std::uint8_t mods) {
    std::string out;
    for (std::uint8_t bit : kModifierOrder)
        if (mods & bit) out += std::string(modifier_name(bit)) + "+";
    return out;
}
}  // namespace

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
    consumedActions_.clear();
    consumedBindings_.clear();
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
        mark_modifiers_used();
        if (is_modifier_key(i)) modKeyUsed_[i] = false;
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
        mark_modifiers_used();
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

// Something was pressed while modifier keys are held: they are part of a chord, not a binding of their own. A modifier
// pressed while another is held makes both part of one (a chord of modifiers is not offered alone).
void Input::mark_modifiers_used() {
    for (size_t k = 1; k < size_t(Key::Count); ++k)
        if (is_modifier_key(k) && keys_[k]) modKeyUsed_[k] = true;
}

std::uint8_t Input::modifiers_down() const {
    View all;
    all.keyboard = true;
    return mods_held(false, all);
}

bool Input::modifier_pressed(std::uint8_t bit) const {
    return key_pressed(modifier_key(bit, false)) || key_pressed(modifier_key(bit, true));
}
bool Input::modifier_released(std::uint8_t bit) const {
    return key_released(modifier_key(bit, false)) || key_released(modifier_key(bit, true));
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
    for (PlayerState& player : players_) player = PlayerState{};  // no devices, no rebinds (the schemes are the project's)
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
    modKeyUsed_.fill(true);  // the focus loss is not a modifier tap
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
    for (std::uint8_t bit : kModifierOrder) names.emplace_back(modifier_name(bit));
    for (const auto& p : pad_binding_names()) names.push_back(p.name);
    return names;
}

}  // namespace

std::uint8_t Input::mods_held(bool previous, const View& view) const {
    if (!view.keyboard) return 0;
    const auto& keys = previous ? prevKeys_ : keys_;
    auto down = [&](Key k) { return keys[size_t(k)] && (!view.keySet || (*view.keySet)[size_t(k)]); };
    std::uint8_t held = 0;
    for (std::uint8_t bit : kModifierOrder) {
        const auto [l, r] = modifier_keys(bit);
        if (down(l) || down(r)) held |= bit;
    }
    return held;
}

bool Input::same_input(const Binding& a, const Binding& b) {
    if (a.kind != b.kind) return false;
    switch (a.kind) {
        case Binding::Kind::Key: return a.key == b.key;
        case Binding::Kind::Mouse: return a.mouse == b.mouse;
        case Binding::Kind::Mod: return a.modBit == b.modBit;
        case Binding::Kind::Touch: return true;
        default: return false;
    }
}

bool Input::in_key_set(const Binding& b, const KeySet& set) {
    auto side = [&](std::uint8_t bit) {
        const auto [l, r] = modifier_keys(bit);
        return set[size_t(l)] || set[size_t(r)];
    };
    for (std::uint8_t bit : kModifierOrder)
        if ((b.mods & bit) && !side(bit)) return false;
    if (b.kind == Binding::Kind::Mod) return side(b.modBit);
    return b.kind != Binding::Kind::Key || set[size_t(b.key)];
}

bool Input::shadowed(const Binding& b, bool previous, const View& view) const {
    if (b.kind == Binding::Kind::PadButton || b.kind == Binding::Kind::PadAxis) return false;
    const std::uint8_t held = mods_held(previous, view);
    auto scan = [&](const std::vector<Binding>& list) {
        for (const Binding& c : list)  // the same input with more modifiers, all of them held
            if (c.mods != b.mods && (c.mods & b.mods) == b.mods && !(c.mods & ~held) && same_input(b, c)) return true;
        return false;
    };
    for (const auto& [name, list] : actions_) {
        if (view.player < 0) {
            if (scan(list)) return true;
        } else if (const auto* own = player_list(view.player, Family::Keys, name)) {
            if (scan(*own)) return true;
        }
    }
    return false;
}

float Input::binding_value_in(const Binding& b, bool previous, const View& view) const {
    const float v = binding_raw(b, previous, view);
    if (v >= kActionDownThreshold && shadowed(b, previous, view)) return 0.0f;
    return v;
}

float Input::binding_raw(const Binding& b, bool previous, const View& view) const {
    auto pads = [&](auto&& each) {  // the pads this view reads (a disconnected pad has nothing down and its axes at 0)
        if (view.anyPad) {
            for (const Pad& pad : pads_) each(pad);
        } else if (view.pad >= 0 && view.pad < kMaxGamepads) {
            each(pads_[size_t(view.pad)]);
        }
    };
    switch (b.kind) {
        case Binding::Kind::Key:
            if (!view.keyboard || (view.keySet && !(*view.keySet)[size_t(b.key)])) return 0.0f;
            if (b.mods & ~mods_held(previous, view)) return 0.0f;
            return (previous ? prevKeys_ : keys_)[size_t(b.key)] ? 1.0f : 0.0f;
        case Binding::Kind::Mod:
            if (b.mods & ~mods_held(previous, view)) return 0.0f;
            return (mods_held(previous, view) & b.modBit) ? 1.0f : 0.0f;
        case Binding::Kind::Mouse:
            if (!view.pointer || (b.mods & ~mods_held(previous, view))) return 0.0f;
            return (previous ? prevMouse_ : mouse_buttons_)[size_t(b.mouse)] ? 1.0f : 0.0f;
        case Binding::Kind::Touch:
            if (!view.pointer || (b.mods & ~mods_held(previous, view))) return 0.0f;
            return (previous ? prevTouchDown_ : touchDown_) ? 1.0f : 0.0f;
        case Binding::Kind::PadButton: {
            float v = 0.0f;
            pads([&](const Pad& pad) {
                if ((previous ? pad.prevButtons : pad.buttons)[size_t(b.button)]) v = 1.0f;
            });
            return v;
        }
        case Binding::Kind::PadAxis: {
            float v = 0.0f;
            pads([&](const Pad& pad) { v = std::max(v, float(b.sign) * pad_axis(pad, b.axis, previous)); });
            return v;
        }
    }
    return 0.0f;
}

float Input::binding_value(const Binding& b, bool previous) const {
    View all;
    all.anyPad = all.pointer = all.keyboard = true;
    return binding_value_in(b, previous, all);
}

bool Input::was_down_in(const std::vector<Binding>& list, const View& view) const {
    for (const Binding& b : list)
        if (binding_value_in(b, true, view) >= kActionDownThreshold) return true;
    return false;
}

bool Input::main_edge(const Binding& b, const View& view, bool released) const {
    auto key = [&](Key k) {
        if (!view.keyboard || (view.keySet && !(*view.keySet)[size_t(k)])) return false;
        return released ? key_released(k) : key_pressed(k);
    };
    switch (b.kind) {
        case Binding::Kind::Key: return key(b.key);
        case Binding::Kind::Mod: {
            const auto [l, r] = modifier_keys(b.modBit);
            return key(l) || key(r);
        }
        case Binding::Kind::Mouse: return view.pointer && (released ? mouse_released(b.mouse) : mouse_pressed(b.mouse));
        case Binding::Kind::Touch: return view.pointer && (released ? touchReleasedEdge_ : touchPressedEdge_);
        default: return false;
    }
}

bool Input::edge_in(const std::vector<Binding>& list, const View& view, bool released) const {
    auto pads = [&](auto&& each) {
        if (view.anyPad) {
            for (const Pad& pad : pads_) each(pad);
        } else if (view.pad >= 0 && view.pad < kMaxGamepads) {
            each(pads_[size_t(view.pad)]);
        }
    };
    bool edge = false;
    for (const Binding& b : list) {
        switch (b.kind) {
            case Binding::Kind::PadButton:  // the touch pad too, for the global view
                pads([&](const Pad& pad) { edge = edge || (released ? pad.releasedEdge : pad.pressedEdge)[size_t(b.button)]; });
                break;
            // An analog value has no event, only a level: it is a press when it is up now and was not at frame start (the
            // caller checks the second half); a release is "was down and is not now", which was_down_in covers.
            case Binding::Kind::PadAxis:
                if (!released) edge = edge || binding_value_in(b, false, view) >= kActionDownThreshold;
                break;
            default: {  // keys, modifiers, mouse buttons and touch, plain or in a chord
                bool e = main_edge(b, view, released);
                if (e && b.mods) {  // a release counts when the chord's modifiers were held at either end of the frame
                    const bool held = !(b.mods & ~mods_held(false, view)) || (released && !(b.mods & ~mods_held(true, view)));
                    e = held;
                }
                if (e && (shadowed(b, false, view) || (released && shadowed(b, true, view)))) e = false;
                // A chord also starts when its modifier arrives after its input (Z held, then Ctrl).
                if (!e && b.mods && !released)
                    e = binding_value_in(b, false, view) >= kActionDownThreshold &&
                        binding_value_in(b, true, view) < kActionDownThreshold;
                edge = edge || e;
                break;
            }
        }
    }
    return edge;
}

// Parses one binding name: an input, or modifiers joined to it by '+'. Returns false if unknown.
bool Input::parse_binding(std::string_view name, Binding& out) {
    const std::string_view text = trim(name);
    out = Binding{};
    if (text.find('+') == std::string_view::npos) return parse_single_binding(text, out);
    const std::vector<std::string> parts = split(text, '+', false);
    if (parts.size() < 2) return false;
    std::uint8_t mods = 0;
    for (size_t i = 0; i + 1 < parts.size(); ++i) {
        const std::uint8_t bit = modifier_from_name(parts[i]);
        if (!bit || (mods & bit)) return false;
        mods |= bit;
    }
    Binding main;
    if (!parse_single_binding(parts.back(), main)) return false;
    if (main.kind == Binding::Kind::PadButton || main.kind == Binding::Kind::PadAxis) return false;
    if (main.kind == Binding::Kind::Mod && (mods & main.modBit)) return false;
    main.mods = mods;
    out = main;
    return true;
}

bool Input::parse_single_binding(std::string_view name, Binding& out) {
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
    if (std::uint8_t bit = modifier_from_name(text)) {
        out.kind = Binding::Kind::Mod;
        out.modBit = bit;
        return true;
    }
    Key k = key_from_name(text);
    if (k == Key::Unknown) return false;
    out.kind = Binding::Kind::Key;
    out.key = k;
    return true;
}

std::string Input::binding_problem(std::string_view name) {
    const std::string_view text = trim(name);
    const std::vector<std::string> names = all_binding_names();
    if (text.find('+') == std::string_view::npos) return did_you_mean(text, names);
    const std::vector<std::string> mods = {"Ctrl", "Shift", "Alt", "Super"};
    const std::string chordForm = "A chord is modifiers then ONE input joined by '+', e.g. \"Ctrl+Z\" or \"Shift+MouseLeft\".";
    const std::vector<std::string> parts = split(text, '+', false);
    std::vector<std::string> fixed;  // the chord with what could be mended
    std::string why;
    std::uint8_t seen = 0;
    for (size_t i = 0; i < parts.size() && why.empty(); ++i) {
        const std::string part(trim(parts[i]));
        const bool last = i + 1 == parts.size();
        if (part.empty()) {
            why = std::format("the chord has an empty part. {}", chordForm);
            break;
        }
        if (!last) {
            const std::uint8_t bit = modifier_from_name(part);
            if (bit && (seen & bit)) {
                why = std::format("the modifier '{}' appears twice", part);
            } else if (bit) {
                seen |= bit;
                fixed.push_back(part);
            } else {
                Binding side;
                if (parse_single_binding(part, side) && side.kind == Binding::Kind::Key && is_modifier_key(size_t(side.key))) {
                    const char* both = modifier_name(side.key == Key::LeftShift || side.key == Key::RightShift ? modifier::Shift
                                                     : side.key == Key::LeftControl || side.key == Key::RightControl ? modifier::Ctrl
                                                     : side.key == Key::LeftAlt || side.key == Key::RightAlt ? modifier::Alt
                                                                                                           : modifier::Super);
                    why = std::format("'{}' names one side's key; a modifier names both sides. Did you mean '{}'?", part, both);
                    fixed.push_back(both);
                } else {
                    const std::string best = closest_match(part, mods);
                    why = std::format("'{}' is not a modifier. {}", part, did_you_mean(part, mods));
                    fixed.push_back(best.empty() ? part : best);
                }
            }
        } else {
            Binding main;
            if (!parse_single_binding(part, main)) {
                why = std::format("'{}' is not an input. {}", part, did_you_mean(part, names));
                const std::string best = closest_match(part, names);
                fixed.push_back(best.empty() ? part : best);
            } else if (main.kind == Binding::Kind::PadButton || main.kind == Binding::Kind::PadAxis) {
                why = std::format("modifiers combine with keys, mouse buttons and Touch, not with the gamepad binding '{}'", part);
            } else if (main.kind == Binding::Kind::Mod && (seen & main.modBit)) {
                why = std::format("the modifier '{}' appears twice", part);
            } else {
                fixed.push_back(part);
            }
        }
    }
    if (why.empty()) why = "it is not a valid chord. " + chordForm;
    std::string out = std::format("{}.", why);
    if (fixed.size() == parts.size()) {
        const std::string joined = join(fixed, "+");
        if (iequals(joined, text) == false && is_binding_name(joined)) out += std::format(" Write it as \"{}\".", joined);
    }
    return out;
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
                                           binding_problem(text)));
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
    if (actions.is_null()) {
        rebuild_player_defaults();
        return problems;
    }
    if (!actions.is_object()) {
        problems.push_back(std::format(
            "input.actions must be an object mapping action names to binding lists, e.g. "
            "{{\"jump\": [\"Space\", \"W\"]}}; got {}", describe_json_value(actions)));
        rebuild_player_defaults();
        return problems;
    }
    const auto candidates = all_binding_names();
    for (auto it = actions.begin(); it != actions.end(); ++it)  // even an empty list declares the action
        actions_[it.key()] = parse_binding_list(it.key(), it.value(), candidates, problems);
    rebuild_player_defaults();
    return problems;
}

std::string Input::binding_name(const Binding& b) {
    switch (b.kind) {
        case Binding::Kind::Key: return modifier_prefix(b.mods) + key_name(b.key);
        case Binding::Kind::Mod: return modifier_prefix(b.mods) + modifier_name(b.modBit);
        case Binding::Kind::Mouse: return modifier_prefix(b.mods) + kMouseNames[size_t(b.mouse)];
        case Binding::Kind::Touch: return modifier_prefix(b.mods) + "Touch";
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
        else problems.push_back(std::format("input.rebind('{}'): unknown binding '{}'. {}", action, text, binding_problem(text)));
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
// The modifiers that were held around this frame's press, as "Ctrl+Shift+": held now, held at the start of the frame, or
// pressed and released within it, so a quick Ctrl+Z still reads as the chord.
std::string Input::chord_prefix(const View& view) const {
    std::uint8_t mods = 0;
    for (std::uint8_t bit : kModifierOrder) {
        const auto [l, r] = modifier_keys(bit);
        for (Key k : {l, r})
            if (view.keyboard && (!view.keySet || (*view.keySet)[size_t(k)]) &&
                (keys_[size_t(k)] || prevKeys_[size_t(k)] || keyPressedEdge_[size_t(k)] || keyReleasedEdge_[size_t(k)]))
                mods |= bit;
    }
    return modifier_prefix(mods);
}

// A modifier key let go without anything else pressed while it was held: the player meant the key itself.
std::string Input::lone_modifier_release(const View& view) const {
    if (!view.keyboard) return "";
    for (size_t i = 1; i < size_t(Key::Count); ++i)
        if (is_modifier_key(i) && keyReleasedEdge_[i] && !modKeyUsed_[i] && (!view.keySet || (*view.keySet)[i]))
            return key_name(Key(i));
    return "";
}

std::string Input::last_pressed() const {
    View all;
    all.anyPad = all.pointer = all.keyboard = true;
    for (size_t i = 1; i < size_t(Key::Count); ++i)
        if (keyPressedEdge_[i] && !is_modifier_key(i)) return chord_prefix(all) + key_name(Key(i));
    if (touchPressedEdge_) return chord_prefix(all) + "Touch";
    for (size_t i = 0; i < size_t(MouseButton::Count); ++i)
        if (mousePressedEdge_[i]) return chord_prefix(all) + kMouseNames[i];
    if (std::string lone = lone_modifier_release(all); !lone.empty()) return lone;
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
    const std::string prefix = modifier_prefix(b.mods);
    switch (b.kind) {
        case Binding::Kind::Key: return prefix + key_name(b.key);
        case Binding::Kind::Mod: return prefix + modifier_name(b.modBit);
        case Binding::Kind::Mouse:
            return prefix + std::string(b.mouse == MouseButton::Left ? "Left" : b.mouse == MouseButton::Right ? "Right" : "Middle") + " Click";
        case Binding::Kind::Touch: return prefix + "Touch";
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

bool Input::binding_typed(const Binding& b) const {
    if (!text_input_mode() || b.kind != Binding::Kind::Key) return false;
    if (b.mods & ~modifier::Shift) return false;  // Ctrl, Alt and Super chords are commands, not typing
    const Key k = b.key;
    return (k >= Key::A && k <= Key::Num9) || k == Key::Space || (k >= Key::Minus && k <= Key::GraveAccent);
}

bool Input::binding_consumed(const Binding& b) const {
    for (const Binding& c : consumedBindings_) {
        if (c.kind != b.kind) continue;
        switch (b.kind) {
            case Binding::Kind::PadButton:
                if (c.button == b.button) return true;
                break;
            case Binding::Kind::PadAxis:
                if (c.axis == b.axis && c.sign == b.sign) return true;
                break;
            default:
                if (same_input(c, b)) return true;
        }
    }
    return false;
}

std::vector<Input::Binding> Input::readable(const std::vector<Binding>& list, bool forPress) const {
    std::vector<Binding> out;
    out.reserve(list.size());
    for (const Binding& b : list)
        if (!binding_typed(b) && !(forPress && binding_consumed(b))) out.push_back(b);
    return out;
}

void Input::consume_action(std::string_view action) {
    auto it = actions_.find(std::string(action));
    if (it == actions_.end()) return;
    consumedActions_.emplace_back(action);
    // Only the bindings that went down this frame: a key that is merely held must not silence another action.
    View all;
    all.anyPad = all.pointer = all.keyboard = true;
    for (const Binding& b : it->second)
        if (edge_in({b}, all, false)) consumedBindings_.push_back(b);
}

float Input::action_value(std::string_view action) const {
    std::string key(action);
    if (overrides_.count(key)) return 1.0f;
    auto it = actions_.find(key);
    if (it == actions_.end()) return 0.0f;
    float v = 0.0f;
    for (const auto& b : it->second)
        if (!binding_typed(b)) v = std::max(v, binding_value(b, false));
    return v;
}

bool Input::action_down(std::string_view action) const { return action_value(action) >= kActionDownThreshold; }

bool Input::action_pressed(std::string_view action) const {
    std::string name(action);
    if (std::find(consumedActions_.begin(), consumedActions_.end(), name) != consumedActions_.end()) return false;
    bool wasDown = prevOverrides_.count(name) != 0;
    bool edge = overridePressedEdge_.count(name) != 0;
    auto it = actions_.find(name);
    if (it != actions_.end()) {
        View all;
        all.anyPad = all.pointer = all.keyboard = true;
        const std::vector<Binding> list = readable(it->second, true);
        wasDown = wasDown || was_down_in(list, all);
        edge = edge || edge_in(list, all, false);
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
        View all;
        all.anyPad = all.pointer = all.keyboard = true;
        const std::vector<Binding> list = readable(it->second, false);
        wasDown = wasDown || was_down_in(list, all);
        edge = edge || edge_in(list, all, true);
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
    Json players = Json::array();  // only players with a device, so a game without players dumps what it always did
    for (int p = 0; p < kMaxPlayers; ++p) {
        const PlayerDevice& d = players_[size_t(p)].device;
        if (d.pad < 0 && d.padId.empty() && d.keys.empty()) continue;
        Json down = Json::array();
        for (const auto& name : action_names())
            if (player_action_down(p, name)) down.push_back(name);
        Json entry = {{"player", p}, {"pad", player_pad(p)}, {"keys", d.keys}, {"actionsDown", down}};
        if (!d.padId.empty()) entry["padId"] = d.padId;
        players.push_back(entry);
    }
    if (!players.empty()) j["players"] = players;
    return j;
}

// ---------------------------------------------------------------------------
// Players: one device each, the project's actions read through it
// ---------------------------------------------------------------------------
namespace {

bool valid_player(int player) { return player >= 0 && player < kMaxPlayers; }

// The two halves of the keyboard: what a "left" player (WASD, Space) and a "right" player (arrows, Enter) own. Space is on
// the left and Enter on the right, so two players on one keyboard share neither.
const std::vector<Key>& left_half_keys() {
    static const std::vector<Key> keys = {Key::Num1, Key::Num2, Key::Num3, Key::Num4, Key::Num5, Key::Q, Key::W, Key::E,
        Key::R, Key::T, Key::A, Key::S, Key::D, Key::F, Key::G, Key::Z, Key::X, Key::C, Key::V, Key::B, Key::Tab,
        Key::LeftShift, Key::LeftControl, Key::LeftAlt, Key::GraveAccent, Key::Space};
    return keys;
}
const std::vector<Key>& right_half_keys() {
    static const std::vector<Key> keys = {Key::Num6, Key::Num7, Key::Num8, Key::Num9, Key::Num0, Key::Y, Key::U, Key::I,
        Key::O, Key::P, Key::H, Key::J, Key::K, Key::L, Key::N, Key::M, Key::Minus, Key::Equal, Key::LeftBracket,
        Key::RightBracket, Key::Backslash, Key::Semicolon, Key::Apostrophe, Key::Comma, Key::Period, Key::Slash,
        Key::Enter, Key::Backspace, Key::RightShift, Key::RightControl, Key::RightAlt, Key::Left, Key::Right, Key::Up,
        Key::Down, Key::Insert, Key::Delete, Key::Home, Key::End, Key::PageUp, Key::PageDown};
    return keys;
}

const char* const kBuiltinSchemes[] = {"all", "left", "right"};

}  // namespace

Input::Input() {
    KeyScheme all, left, right;
    for (size_t i = 1; i < size_t(Key::Count); ++i) all.keys[i] = true;
    for (Key k : left_half_keys()) left.keys[size_t(k)] = true;
    for (Key k : right_half_keys()) right.keys[size_t(k)] = true;
    all.builtin = left.builtin = right.builtin = true;
    schemes_["all"] = std::move(all);
    schemes_["left"] = std::move(left);
    schemes_["right"] = std::move(right);
}

bool Input::parse_family(std::string_view name, Family& out) {
    if (iequals(name, "keys")) { out = Family::Keys; return true; }
    if (iequals(name, "pad")) { out = Family::Pad; return true; }
    return false;
}

std::vector<std::string> Input::key_scheme_names() const {
    std::vector<std::string> names(std::begin(kBuiltinSchemes), std::end(kBuiltinSchemes));
    for (const auto& [name, scheme] : schemes_)
        if (!scheme.builtin) names.push_back(name);  // std::map: sorted
    return names;
}

std::vector<std::string> Input::key_scheme_keys(std::string_view name) const {
    std::vector<std::string> out;
    auto it = schemes_.find(std::string(name));
    if (it == schemes_.end()) return out;
    for (size_t i = 1; i < size_t(Key::Count); ++i)
        if (it->second.keys[i]) out.push_back(key_name(Key(i)));
    return out;
}

std::vector<std::string> Input::set_key_schemes(const Json& schemes) {
    std::vector<std::string> problems;
    for (auto it = schemes_.begin(); it != schemes_.end();) it = it->second.builtin ? std::next(it) : schemes_.erase(it);
    if (!schemes.is_null()) {
        if (!schemes.is_object()) {
            problems.push_back(std::format(
                "input.schemes must be an object mapping scheme names to key sets, e.g. {{\"arrows\": {{\"extends\": \"right\"}}}}; got {}",
                describe_json_value(schemes)));
        } else {
            const std::vector<std::string> keyCandidates = key_names().all;
            const std::vector<std::string> builtin(std::begin(kBuiltinSchemes), std::end(kBuiltinSchemes));
            for (auto it = schemes.begin(); it != schemes.end(); ++it) {
                const std::string& name = it.key();
                const std::string at = "input.schemes." + name;
                if (name.empty()) { problems.push_back("input.schemes: a scheme needs a name"); continue; }
                if (std::find(builtin.begin(), builtin.end(), name) != builtin.end()) {
                    problems.push_back(std::format("{}: '{}' is a built-in scheme ({}); pick another name, or use \"extends\": \"{}\" to start from it",
                                                   at, name, join(builtin, ", "), name));
                    continue;
                }
                Json spec = it.value();
                if (spec.is_array()) spec = Json::object({{"keys", spec}});
                if (!spec.is_object()) {
                    problems.push_back(std::format("{}: expected an object like {{\"extends\": \"left\", \"actions\": {{...}}}} or an array of key names, got {}",
                                                   at, describe_json_value(spec)));
                    continue;
                }
                const std::vector<std::string> fields = {"extends", "keys", "actions"};
                const size_t before = problems.size();
                for (auto f = spec.begin(); f != spec.end(); ++f)
                    if (std::find(fields.begin(), fields.end(), f.key()) == fields.end())
                        problems.push_back(std::format("{}: unknown field '{}'. {}", at, f.key(), did_you_mean(f.key(), fields)));
                KeyScheme scheme;
                auto add_key = [&](const Json& item, const std::string& where) {
                    const std::string text = item.is_string() ? item.get<std::string>() : std::string();
                    Key k = item.is_string() ? key_from_name(text) : Key::Unknown;
                    if (k == Key::Unknown)
                        problems.push_back(std::format("{}: {} is not a key name. {}", where,
                                                       item.is_string() ? "'" + text + "'" : describe_json_value(item),
                                                       did_you_mean(text, keyCandidates)));
                    else
                        scheme.keys[size_t(k)] = true;
                    return k;
                };
                if (spec.contains("extends")) {
                    const Json& e = spec["extends"];
                    auto base = e.is_string() ? schemes_.find(e.get<std::string>()) : schemes_.end();
                    if (base == schemes_.end() || !base->second.builtin)
                        problems.push_back(std::format("{}/extends: expected one of {}, got {}. {}", at, join(builtin, ", "),
                                                       describe_json_value(e),
                                                       e.is_string() ? did_you_mean(e.get<std::string>(), builtin) : std::string()));
                    else
                        for (size_t i = 0; i < scheme.keys.size(); ++i) scheme.keys[i] = scheme.keys[i] || base->second.keys[i];
                }
                if (spec.contains("keys")) {
                    if (!spec["keys"].is_array())
                        problems.push_back(std::format("{}/keys: expected an array of key names, got {}", at, describe_json_value(spec["keys"])));
                    else
                        for (const Json& k : spec["keys"]) add_key(k, at + "/keys");
                }
                if (spec.contains("actions")) {
                    const Json& acts = spec["actions"];
                    if (!acts.is_object()) {
                        problems.push_back(std::format("{}/actions: expected an object mapping action names to key lists, got {}", at, describe_json_value(acts)));
                    } else {
                        const std::vector<std::string> names = action_names();
                        for (auto a = acts.begin(); a != acts.end(); ++a) {
                            const std::string where = at + "/actions/" + a.key();
                            if (!projectActions_.is_object() || !projectActions_.contains(a.key())) {
                                problems.push_back(std::format("{}: unknown input action '{}'. {}", where, a.key(), did_you_mean(a.key(), names)));
                                continue;
                            }
                            if (!a.value().is_array()) {
                                problems.push_back(std::format("{}: expected an array of key names, got {}", where, describe_json_value(a.value())));
                                continue;
                            }
                            std::vector<Binding> list;
                            for (const Json& item : a.value()) {
                                Key k = add_key(item, where);
                                if (k == Key::Unknown) continue;
                                Binding b;
                                b.kind = Binding::Kind::Key;
                                b.key = k;
                                list.push_back(b);
                            }
                            scheme.actions[a.key()] = std::move(list);
                        }
                    }
                }
                bool any = false;
                for (bool k : scheme.keys) any = any || k;
                if (!any && problems.size() == before)
                    problems.push_back(std::format("{}: the scheme has no keys. Give \"extends\" (a built-in scheme) or \"keys\", e.g. {{\"keys\": [\"W\", \"A\", \"S\", \"D\"]}}", at));
                if (problems.size() == before) schemes_[name] = std::move(scheme);
            }
        }
    }
    rebuild_player_defaults();
    return problems;
}

void Input::rebuild_player_defaults() {
    padDefaults_.clear();
    keyDefaults_.clear();
    for (const auto& [name, scheme] : schemes_) keyDefaults_[name];  // a scheme with no actions still exists
    for (const auto& [action, all] : actions_) {
        if (!projectActions_.is_object() || !projectActions_.contains(action)) continue;  // made by bind(), not the project's
        std::vector<Binding> pad;
        for (const Binding& b : all)
            if (b.kind == Binding::Kind::PadButton || b.kind == Binding::Kind::PadAxis) pad.push_back(b);
        padDefaults_[action] = std::move(pad);
        for (const auto& [name, scheme] : schemes_) {
            auto own = scheme.actions.find(action);
            if (own != scheme.actions.end()) {
                keyDefaults_[name][action] = own->second;
                continue;
            }
            std::vector<Binding> keys;
            for (const Binding& b : all)
                if (is_key_family(b) && in_key_set(b, scheme.keys)) keys.push_back(b);
            keyDefaults_[name][action] = std::move(keys);
        }
    }
    for (PlayerState& player : players_) {  // a rebind of an action the project no longer has goes with it
        for (auto it = player.keysOverride.begin(); it != player.keysOverride.end();)
            it = padDefaults_.count(it->first) ? std::next(it) : player.keysOverride.erase(it);
        for (auto it = player.padOverride.begin(); it != player.padOverride.end();)
            it = padDefaults_.count(it->first) ? std::next(it) : player.padOverride.erase(it);
    }
}

std::vector<std::string> Input::use_player_device(int player, const PlayerDevice& device) {
    std::vector<std::string> problems;
    if (!valid_player(player)) {
        problems.push_back(std::format("input.player({}): players are numbered 0 to {}", player, kMaxPlayers - 1));
        return problems;
    }
    if (device.pad < -1 || device.pad >= kMaxGamepads)
        problems.push_back(std::format("input.player({}).use: pad must be a gamepad slot from 0 to {}, got {}", player,
                                       kMaxGamepads - 1, device.pad));
    if (device.pad >= 0 && !device.padId.empty())
        problems.push_back(std::format("input.player({}).use: give pad (a slot) or padId (a pad's stable id), not both", player));
    if (!device.keys.empty() && !schemes_.count(device.keys))
        problems.push_back(std::format("input.player({}).use: unknown key scheme '{}'. {}", player, device.keys,
                                       did_you_mean(device.keys, key_scheme_names())));
    if (problems.empty()) players_[size_t(player)].device = device;
    return problems;
}

const PlayerDevice& Input::player_device(int player) const {
    static const PlayerDevice none;
    return valid_player(player) ? players_[size_t(player)].device : none;
}

int Input::player_pad(int player) const {
    if (!valid_player(player)) return -1;
    const PlayerDevice& d = players_[size_t(player)].device;
    if (d.padId.empty()) return d.pad;
    for (int i = 0; i < kMaxGamepads; ++i)
        if (pads_[size_t(i)].connected && pads_[size_t(i)].info.id == d.padId) return i;
    return -1;
}

Input::View Input::player_view(int player) const {
    View view;
    if (!valid_player(player)) return view;
    view.player = player;
    const PlayerDevice& d = players_[size_t(player)].device;
    if (!d.keys.empty()) {
        auto it = schemes_.find(d.keys);
        if (it != schemes_.end()) {
            view.keyboard = true;
            view.keySet = &it->second.keys;
        }
    }
    view.pad = player_pad(player);
    return view;
}

bool Input::has_player_action(std::string_view action) const { return padDefaults_.count(std::string(action)) != 0; }

const std::vector<Input::Binding>* Input::player_list(int player, Family family, const std::string& action) const {
    if (!valid_player(player)) return nullptr;
    const PlayerState& state = players_[size_t(player)];
    if (family == Family::Pad) {
        if (auto o = state.padOverride.find(action); o != state.padOverride.end()) return &o->second;
        auto d = padDefaults_.find(action);
        return d == padDefaults_.end() ? nullptr : &d->second;
    }
    if (auto o = state.keysOverride.find(action); o != state.keysOverride.end()) return &o->second;
    auto table = keyDefaults_.find(state.device.keys.empty() ? std::string("all") : state.device.keys);
    if (table == keyDefaults_.end()) return nullptr;
    auto d = table->second.find(action);
    return d == table->second.end() ? nullptr : &d->second;
}

float Input::player_action_value(int player, std::string_view action) const {
    const std::string name(action);
    const View view = player_view(player);
    float v = 0.0f;
    for (Family f : {Family::Keys, Family::Pad})
        if (const auto* list = player_list(player, f, name))
            for (const Binding& b : *list) v = std::max(v, binding_value_in(b, false, view));
    return v;
}

bool Input::player_action_down(int player, std::string_view action) const {
    return player_action_value(player, action) >= kActionDownThreshold;
}

bool Input::player_action_pressed(int player, std::string_view action) const {
    const std::string name(action);
    const View view = player_view(player);
    bool wasDown = false, edge = false;
    for (Family f : {Family::Keys, Family::Pad})
        if (const auto* list = player_list(player, f, name)) {
            wasDown = wasDown || was_down_in(*list, view);
            edge = edge || edge_in(*list, view, false);
        }
    return edge && !wasDown;
}

bool Input::player_action_released(int player, std::string_view action) const {
    if (player_action_down(player, action)) return false;
    const std::string name(action);
    const View view = player_view(player);
    bool wasDown = false, edge = false;
    for (Family f : {Family::Keys, Family::Pad})
        if (const auto* list = player_list(player, f, name)) {
            wasDown = wasDown || was_down_in(*list, view);
            edge = edge || edge_in(*list, view, true);
        }
    return wasDown || edge;
}

float Input::player_axis(int player, std::string_view negative, std::string_view positive) const {
    return player_action_value(player, positive) - player_action_value(player, negative);
}

Vec2 Input::player_vector(int player, std::string_view left, std::string_view right, std::string_view down,
                          std::string_view up) const {
    Vec2 v{player_axis(player, left, right), player_axis(player, down, up)};
    float len = length(v);
    if (len > 1.0f) v = v / len;
    return v;
}

std::vector<std::string> Input::player_bindings(int player, std::string_view action, std::string_view family) const {
    std::vector<std::string> out;
    if (!valid_player(player)) return out;
    const std::string name(action);
    const PlayerDevice& d = players_[size_t(player)].device;
    std::vector<Family> families;
    if (Family f; !family.empty() && parse_family(family, f)) {
        families.push_back(f);
    } else if (family.empty()) {
        if (!d.keys.empty()) families.push_back(Family::Keys);
        if (d.pad >= 0 || !d.padId.empty()) families.push_back(Family::Pad);
    }
    const KeySet* set = nullptr;
    if (!d.keys.empty())
        if (auto it = schemes_.find(d.keys); it != schemes_.end()) set = &it->second.keys;
    for (Family f : families)
        if (const auto* list = player_list(player, f, name))
            for (const Binding& b : *list) {
                if (is_key_family(b) && set && !in_key_set(b, *set)) continue;
                out.push_back(binding_name(b));
            }
    return out;
}

std::vector<std::string> Input::player_rebind(int player, std::string_view action, const std::vector<std::string>& bindings,
                                              std::string_view family) {
    std::vector<std::string> problems;
    const std::string who = std::format("input.player({}).rebind('{}')", player, action);
    if (!valid_player(player)) {
        problems.push_back(std::format("input.player({}): players are numbered 0 to {}", player, kMaxPlayers - 1));
        return problems;
    }
    const std::string name(action);
    if (!has_player_action(action)) {
        problems.push_back(unknown_action_message("input.player().rebind", action, action_names()));
        return problems;
    }
    Family only = Family::Keys;
    const bool haveFamily = !family.empty();
    if (haveFamily && !parse_family(family, only)) {
        problems.push_back(std::format("{}: the family must be \"keys\" or \"pad\", got '{}'", who, family));
        return problems;
    }
    const PlayerState& state = players_[size_t(player)];
    const std::string schemeName = state.device.keys.empty() ? std::string("all") : state.device.keys;
    auto scheme = schemes_.find(schemeName);
    const auto candidates = all_binding_names();
    std::vector<Binding> keys, pad;
    for (const std::string& text : bindings) {
        Binding b;
        if (!parse_binding(text, b)) {
            problems.push_back(std::format("{}: unknown binding '{}'. {}", who, text, binding_problem(text)));
            continue;
        }
        const std::string canonical = binding_name(b);
        if (b.kind == Binding::Kind::Mouse || b.kind == Binding::Kind::Touch) {
            problems.push_back(std::format("{}: '{}' is the shared pointer, which players do not read; use the global input.* actions for the mouse and touch, "
                                           "or a key or a gamepad binding here", who, canonical));
            continue;
        }
        const bool isPad = b.kind == Binding::Kind::PadButton || b.kind == Binding::Kind::PadAxis;
        if (haveFamily && isPad != (only == Family::Pad)) {
            problems.push_back(std::format("{}: '{}' is a {} binding but the family is \"{}\"", who, canonical,
                                           isPad ? "gamepad" : "keyboard", family));
            continue;
        }
        if (!isPad && scheme != schemes_.end() && !in_key_set(b, scheme->second.keys)) {
            problems.push_back(std::format(
                "{}: '{}' is not a key of this player's scheme '{}'. Pick one of its keys (input.keySchemeKeys('{}')), or give the "
                "player another scheme with input.player({}).use({{keys: ...}}) first",
                who, canonical, schemeName, schemeName, player));
            continue;
        }
        (isPad ? pad : keys).push_back(b);
    }
    if (!problems.empty()) return problems;
    if (!haveFamily && !bindings.empty() && !keys.empty() && !pad.empty()) {
        problems.push_back(std::format("{}: the names mix keyboard and gamepad bindings; rebind one family at a time "
                                       "(pass \"keys\" or \"pad\" as the family)", who));
        return problems;
    }
    PlayerState& st = players_[size_t(player)];
    const bool replaceKeys = haveFamily ? only == Family::Keys : (bindings.empty() || !keys.empty());
    const bool replacePad = haveFamily ? only == Family::Pad : (bindings.empty() || !pad.empty());
    if (replaceKeys) st.keysOverride[name] = std::move(keys);
    if (replacePad) st.padOverride[name] = std::move(pad);
    return problems;
}

std::vector<std::string> Input::player_reset(int player, std::string_view action) {
    std::vector<std::string> problems;
    if (!valid_player(player)) {
        problems.push_back(std::format("input.player({}): players are numbered 0 to {}", player, kMaxPlayers - 1));
        return problems;
    }
    PlayerState& st = players_[size_t(player)];
    if (action.empty()) {
        st.keysOverride.clear();
        st.padOverride.clear();
        return problems;
    }
    if (!has_player_action(action)) {
        problems.push_back(unknown_action_message("input.player().reset", action, action_names()));
        return problems;
    }
    st.keysOverride.erase(std::string(action));
    st.padOverride.erase(std::string(action));
    return problems;
}

std::string Input::player_last_pressed(int player) const {
    const View view = player_view(player);
    if (view.keyboard) {
        for (size_t i = 1; i < size_t(Key::Count); ++i)
            if (keyPressedEdge_[i] && !is_modifier_key(i) && (!view.keySet || (*view.keySet)[i]))
                return chord_prefix(view) + key_name(Key(i));
        if (std::string lone = lone_modifier_release(view); !lone.empty()) return lone;
    }
    if (view.pad >= 0 && view.pad < kMaxGamepads) {
        const Pad& pad = pads_[size_t(view.pad)];
        for (size_t i = 0; i < size_t(GamepadButton::Count); ++i)
            if (pad.pressedEdge[i]) return std::string("Gamepad") + kPadButtonNames[i];
        for (const auto& p : pad_binding_names()) {
            if (!p.isAxis) continue;
            if (float(p.sign) * pad_axis(pad, p.axis, false) >= kActionDownThreshold &&
                float(p.sign) * pad_axis(pad, p.axis, true) < kActionDownThreshold)
                return p.name;
        }
    }
    return "";
}

Json Input::player_export(int player) const {
    Json out = Json::object();
    if (!valid_player(player)) return out;
    const PlayerState& st = players_[size_t(player)];
    for (Family f : {Family::Keys, Family::Pad}) {
        const ActionTable& table = f == Family::Keys ? st.keysOverride : st.padOverride;
        Json family = Json::object();
        for (const auto& [action, list] : table) {
            Json names = Json::array();
            for (const Binding& b : list) names.push_back(binding_name(b));
            family[action] = names;
        }
        if (!family.empty()) out[f == Family::Keys ? "keys" : "pad"] = family;
    }
    return out;
}

std::vector<std::string> Input::player_import(int player, const Json& data) {
    std::vector<std::string> problems;
    if (!valid_player(player)) {
        problems.push_back(std::format("input.player({}): players are numbered 0 to {}", player, kMaxPlayers - 1));
        return problems;
    }
    ActionTable keys, pad;
    if (!data.is_null()) {
        const std::string who = std::format("input.player({}).import", player);
        if (!data.is_object()) {
            problems.push_back(std::format("{}: expected {{\"keys\": {{...}}, \"pad\": {{...}}}} as input.player(i).export() gives, got {}",
                                           who, describe_json_value(data)));
            return problems;
        }
        const std::vector<std::string> fields = {"keys", "pad"};
        for (auto it = data.begin(); it != data.end(); ++it)
            if (std::find(fields.begin(), fields.end(), it.key()) == fields.end())
                problems.push_back(std::format("{}: unknown field '{}' skipped. {}", who, it.key(), did_you_mean(it.key(), fields)));
        for (Family f : {Family::Keys, Family::Pad}) {
            const char* fname = f == Family::Keys ? "keys" : "pad";
            if (!data.contains(fname)) continue;
            const Json& table = data[fname];
            if (!table.is_object()) {
                problems.push_back(std::format("{}: \"{}\" must map action names to binding lists, got {}", who, fname, describe_json_value(table)));
                continue;
            }
            for (auto it = table.begin(); it != table.end(); ++it) {
                const std::string where = std::format("{}: {}.{}", who, fname, it.key());
                if (!has_player_action(it.key())) {
                    problems.push_back(std::format("{}: the project has no such action, skipped. {}", where, did_you_mean(it.key(), action_names())));
                    continue;
                }
                if (!it.value().is_array()) {
                    problems.push_back(std::format("{}: expected an array of binding names, got {}, skipped", where, describe_json_value(it.value())));
                    continue;
                }
                std::vector<Binding> list;
                bool ok = true;
                for (const Json& item : it.value()) {
                    Binding b;
                    const bool parsed = item.is_string() && parse_binding(item.get<std::string>(), b);
                    const bool isPad = parsed && (b.kind == Binding::Kind::PadButton || b.kind == Binding::Kind::PadAxis);
                    const bool isKey = parsed && is_key_family(b);
                    if (!(f == Family::Pad ? isPad : isKey)) {
                        problems.push_back(std::format("{}: {} is not a {} binding, the action was skipped", where,
                                                       describe_json_value(item), f == Family::Pad ? "gamepad" : "key"));
                        ok = false;
                        break;
                    }
                    list.push_back(b);
                }
                if (ok) (f == Family::Keys ? keys : pad)[it.key()] = std::move(list);
            }
        }
    }
    players_[size_t(player)].keysOverride = std::move(keys);
    players_[size_t(player)].padOverride = std::move(pad);
    return problems;
}

}  // namespace fa
