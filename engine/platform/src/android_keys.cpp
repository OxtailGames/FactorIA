#include "fa/platform/android_keys.h"

namespace fa {

Key android_key_to_key(int code) {
    if (code >= kAndroidKeyA && code <= kAndroidKeyZ) return Key(int(Key::A) + (code - kAndroidKeyA));
    if (code >= kAndroidKey0 && code <= kAndroidKey9) return Key(int(Key::Num0) + (code - kAndroidKey0));
    if (code >= 144 && code <= 153) return Key(int(Key::Num0) + (code - 144));  // NUMPAD_0..9, like sokol_app on desktop
    if (code >= 131 && code <= 142) return Key(int(Key::F1) + (code - 131));    // F1..F12
    switch (code) {
        case 62: return Key::Space;
        case 66: case 160: return Key::Enter;  // ENTER, NUMPAD_ENTER
        case 111: return Key::Escape;
        case 61: return Key::Tab;
        case 67: return Key::Backspace;  // KEYCODE_DEL is the key that deletes backwards
        case 112: return Key::Delete;    // FORWARD_DEL
        case 124: return Key::Insert;
        case 21: return Key::Left;
        case 22: return Key::Right;
        case 19: return Key::Up;
        case 20: return Key::Down;
        case 92: return Key::PageUp;
        case 93: return Key::PageDown;
        case 122: return Key::Home;  // MOVE_HOME
        case 123: return Key::End;   // MOVE_END
        case 59: return Key::LeftShift;
        case 60: return Key::RightShift;
        case 113: return Key::LeftControl;
        case 114: return Key::RightControl;
        case 57: return Key::LeftAlt;
        case 58: return Key::RightAlt;
        case 117: return Key::LeftSuper;
        case 118: return Key::RightSuper;
        case 69: case 156: return Key::Minus;            // MINUS, NUMPAD_SUBTRACT
        case 70: case 161: case 157: return Key::Equal;  // EQUALS, NUMPAD_EQUALS, NUMPAD_ADD
        case 71: return Key::LeftBracket;
        case 72: return Key::RightBracket;
        case 73: return Key::Backslash;
        case 74: return Key::Semicolon;
        case 75: return Key::Apostrophe;
        case 55: return Key::Comma;
        case 56: case 158: return Key::Period;  // PERIOD, NUMPAD_DOT
        case 76: case 154: return Key::Slash;   // SLASH, NUMPAD_DIVIDE
        case 68: return Key::GraveAccent;
        default: return Key::Unknown;
    }
}

bool AndroidKeys::may_type(int code) {
    return (code >= 7 && code <= 18) ||     // 0..9, *, #
           (code >= 29 && code <= 56) ||    // A..Z, comma, period
           code == 62 ||                    // space
           (code >= 68 && code <= 77) ||    // ` - = [ ] \ ; ' / @
           code == 81 ||                    // +
           (code >= 144 && code <= 159) ||  // numeric keypad: digits, / * - + . ,
           code == 161;                     // keypad =
}

bool AndroidKeys::on_key(int code, bool down, std::uint32_t unicode, bool repeat) {
    if (code == kAndroidKeyBack) {
        if (down && !repeat) items_.push_back({Item::Kind::Back});  // the lift of the button is consumed too, and ignored
        return true;
    }
    const Key key = android_key_to_key(code);
    const bool types = down && unicode >= 32 && unicode != 127;
    if (key == Key::Unknown && !types) return false;
    // A held key repeats: Input ignores the repeated edge, but the repeated character is typed again, like on a desktop.
    if (key != Key::Unknown && !(down && repeat)) items_.push_back({Item::Kind::Key, key, down, 0});
    if (types) items_.push_back({Item::Kind::Text, Key::Unknown, true, unicode});
    return true;
}

void AndroidKeys::feed(Input& input) {
    for (const Item& item : items_) {
        switch (item.kind) {
            case Item::Kind::Key: input.on_key(item.key, item.down); break;
            case Item::Kind::Text: input.on_text(item.codepoint); break;
            case Item::Kind::Back: input.on_back(); break;
        }
    }
    items_.clear();
}

}  // namespace fa
