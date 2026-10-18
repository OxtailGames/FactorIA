// Android keys: the Back button and keyboards (android_keys.h), and the Back / vibration state of Input. The JNI glue
// that feeds them (mobile_android.cpp) is only compiled on Android; the decisions are tested here, on every OS.
#include <doctest.h>

#include "fa/platform/android_keys.h"
#include "fa/platform/input.h"

using namespace fa;

TEST_CASE("android keycodes map to engine keys") {
    CHECK(android_key_to_key(29) == Key::A);        // KEYCODE_A
    CHECK(android_key_to_key(54) == Key::Z);        // KEYCODE_Z
    CHECK(android_key_to_key(7) == Key::Num0);      // KEYCODE_0
    CHECK(android_key_to_key(16) == Key::Num9);
    CHECK(android_key_to_key(144) == Key::Num0);    // KEYCODE_NUMPAD_0, like sokol_app on desktop
    CHECK(android_key_to_key(62) == Key::Space);
    CHECK(android_key_to_key(66) == Key::Enter);
    CHECK(android_key_to_key(67) == Key::Backspace);  // KEYCODE_DEL deletes backwards
    CHECK(android_key_to_key(112) == Key::Delete);    // KEYCODE_FORWARD_DEL
    CHECK(android_key_to_key(111) == Key::Escape);
    CHECK(android_key_to_key(21) == Key::Left);
    CHECK(android_key_to_key(131) == Key::F1);
    CHECK(android_key_to_key(142) == Key::F12);
    CHECK(android_key_to_key(kAndroidKeyBack) == Key::Unknown);  // Back is an event of its own, not a key
    CHECK(android_key_to_key(24) == Key::Unknown);               // KEYCODE_VOLUME_UP is the system's
    CHECK(android_key_to_key(96) == Key::Unknown);               // KEYCODE_BUTTON_A is a gamepad's
}

TEST_CASE("only keys that can type are asked for a character") {
    for (int code : {7, 16, 29, 54, 55, 56, 62, 68, 69, 73, 76, 77, 81, 144, 153, 158}) CHECK(AndroidKeys::may_type(code));
    for (int code : {4, 19, 22, 24, 57, 59, 61, 66, 67, 82, 96, 111, 112, 122, 131}) CHECK_FALSE(AndroidKeys::may_type(code));
}

TEST_CASE("Back is consumed and arrives as one edge per press") {
    AndroidKeys keys;
    Input in;
    CHECK(keys.on_key(kAndroidKeyBack, true, 0, false));   // the press: consumed, so Android does not leave the app
    CHECK(keys.on_key(kAndroidKeyBack, false, 0, false));  // the lift is consumed too, and is not a second press
    CHECK_FALSE(in.back_pressed());                        // nothing reaches Input before feed()
    keys.feed(in);
    CHECK(in.back_pressed());
    in.begin_frame();
    CHECK_FALSE(in.back_pressed());  // an edge: gone with the frame
    keys.feed(in);
    CHECK_FALSE(in.back_pressed());  // and fed once

    keys.on_key(kAndroidKeyBack, true, 0, false);
    keys.on_key(kAndroidKeyBack, true, 0, true);  // a held button repeats: still one press
    keys.on_key(kAndroidKeyBack, false, 0, false);
    keys.on_key(kAndroidKeyBack, true, 0, false);  // pressed again before the frame
    keys.feed(in);
    CHECK(in.back_pressed());
}

TEST_CASE("a keyboard types characters and key edges, in order") {
    AndroidKeys keys;
    Input in;
    in.begin_frame();
    CHECK(keys.on_key(33, true, 'e', false));   // KEYCODE_E
    CHECK(keys.on_key(33, false, 0, false));
    CHECK(keys.on_key(33, true, 'E', false));   // with shift held: the glue asked Java with the meta state
    CHECK(keys.on_key(67, true, 0, false));     // Backspace types nothing
    CHECK(keys.on_key(62, true, ' ', false));   // Space is a key and a character
    keys.feed(in);
    CHECK(in.text_utf8() == "eE ");
    CHECK(in.key_down(Key::Space));
    CHECK(in.key_pressed(Key::Backspace));
    CHECK(in.key_pressed(Key::E));
}

TEST_CASE("a held key repeats its character but not its edge") {
    AndroidKeys keys;
    Input in;
    in.begin_frame();
    keys.on_key(29, true, 'a', false);
    in.begin_frame();
    keys.feed(in);
    in.begin_frame();
    keys.on_key(29, true, 'a', true);  // auto-repeat
    keys.on_key(29, true, 'a', true);
    keys.feed(in);
    CHECK(in.text_utf8() == "aa");
    CHECK_FALSE(in.key_pressed(Key::A));
}

TEST_CASE("keys that mean nothing here are left to the system") {
    AndroidKeys keys;
    Input in;
    CHECK_FALSE(keys.on_key(24, true, 0, false));    // volume up
    CHECK_FALSE(keys.on_key(25, false, 0, false));   // volume down
    CHECK_FALSE(keys.on_key(96, true, 0, false));    // a gamepad button that reached here
    CHECK(keys.on_key(19, true, 0, false));          // an arrow key is ours
    // A key of no known name that types a character is still consumed and typed (an accented key of a national layout).
    CHECK(keys.on_key(9999, true, 0x00E9, false));
    // A control character is never text.
    CHECK_FALSE(keys.on_key(9999, true, 10, false));
    in.begin_frame();
    keys.feed(in);
    CHECK(in.text_utf8() == "\xC3\xA9");
    CHECK(in.key_down(Key::Up));
}

TEST_CASE("Input records Back and vibration requests; reset_options clears them") {
    Input in;
    in.begin_frame();
    CHECK_FALSE(in.back_pressed());
    in.on_back();
    CHECK(in.back_pressed());
    in.begin_frame();
    CHECK_FALSE(in.back_pressed());

    in.vibrate(0.05f);
    in.vibrate(0.4f);
    REQUIRE(in.vibrations().size() == 2);
    CHECK(in.vibrations()[0] == doctest::Approx(0.05f));
    CHECK(in.vibrations()[1] == doctest::Approx(0.4f));
    in.reset_options();
    CHECK(in.vibrations().empty());

    in.vibrate(0.1f);
    in.clear_vibrations();  // what a window does after playing them
    CHECK(in.vibrations().empty());
    for (int i = 0; i < 1000; ++i) in.vibrate(0.01f);
    CHECK(in.vibrations().size() == 256);  // nobody plays them in a headless run: the log stays short
}
