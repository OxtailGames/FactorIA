// Android keys: what the NativeActivity input queue says about the Back button and about keyboards, hardware or on-screen.
//
// sokol_app turns neither into events on Android: it ends the app on Back and ignores every other key. mobile_android.cpp
// reads the AInputEvent and calls this class, which owns the decisions (which keycode is which Key, which key can type a
// character, what is consumed) and has no Android dependency, so every OS unit-tests it.
//
// The characters are the part the NDK cannot tell: AKeyEvent has no "unicode char". The glue asks the Java side
// (KeyEvent.getUnicodeChar, through JNI) only for the keys that can type (may_type below) and hands the answer in.
// Limits, on purpose: an IME that composes (CJK, emoji, a keyboard that commits whole words) sends text, not key events,
// and a NativeActivity cannot receive it; the characters are those of the key's own layout (Latin letters, digits,
// punctuation). Documented in docs/MOBILE.md.
#pragma once

#include <cstdint>
#include <vector>

#include "fa/platform/input.h"

namespace fa {

// Android key codes (android/keycodes.h), numeric so this compiles everywhere; mobile_android.cpp static_asserts the
// ones that matter against the NDK headers.
inline constexpr int kAndroidKeyBack = 4;
inline constexpr int kAndroidKey0 = 7, kAndroidKey9 = 16, kAndroidKeyA = 29, kAndroidKeyZ = 54;

// The Key an Android keycode is, Key::Unknown when it is none we know (volume, media, gamepad buttons...).
Key android_key_to_key(int androidKeyCode);

class AndroidKeys {
public:
    // True for keycodes that may type a character (letters, digits, punctuation, space, the numeric keypad): the glue asks
    // Java for the character of these only. Control keys (Enter, arrows, Backspace) and modifiers never type.
    static bool may_type(int androidKeyCode);

    // A key event of a keyboard source. `unicode`: the character the key types in its layout and meta state, 0 for none
    // (also when the glue did not ask). `repeat`: it is the auto-repeat of a key held down. Returns whether the event is
    // consumed (so Android does not handle it as well): Back, every key we know, every key that typed.
    bool on_key(int androidKeyCode, bool down, std::uint32_t unicode, bool repeat);

    // Feeds everything that came in since the last call to `input`, in order: key edges, typed characters, Back. Once per
    // frame, before the game runs.
    void feed(Input& input);

private:
    struct Item {
        enum class Kind : std::uint8_t { Key, Text, Back } kind;
        Key key = Key::Unknown;
        bool down = false;
        std::uint32_t codepoint = 0;
    };
    std::vector<Item> items_;
};

}  // namespace fa
