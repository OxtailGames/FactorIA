// Physical gamepads. Windowed runs only: fa::run_app() calls poll_gamepads() once per frame, before the game update
// (and not while the window is unfocused). Headless runs, tests and replays never poll; they feed Input directly
// (Input::on_gamepad_*), so they stay deterministic.
//
// Backends:
//   Windows  XInput (xinput1_4.dll, loaded at run time: Xbox-style pads, 4 slots).
//   Linux    the kernel joystick API (/dev/input/js0..3). The raw button and axis numbers differ from pad to pad, so
//            each pad is looked up by its ids (bus, vendor, product, version) in SDL GameControllerDB mapping lines
//            (fa/platform/gamepad_mapping.h), best source first: the SDL_GAMECONTROLLERCONFIG environment variable
//            (newline separated lines), a gamecontrollerdb.txt in the project folder, the built-in database (the Linux
//            lines of SDL_GameControllerDB, embedded in the binary), and the Xbox (xpad) layout for a pad none lists.
//   macOS/iOS  the GameController framework (extended gamepads).
//   Android  key and motion events of the NativeActivity input queue, taken through sokol_app's native event hook
//            (android_gamepad_event below). An unplugged pad is noticed, and Z/RZ told apart as stick or triggers,
//            by asking android.view.InputDevice through JNI about every 2 s (see gamepad_android.cpp).
//   web      the browser Gamepad API (gamepad_web.cpp): pads with the "standard" mapping, which every current browser gives
//            Xbox, PlayStation, Switch Pro and Steam Deck pads. Like everywhere, a pad is hidden until a button is pressed.
// Rumble. Input holds what the game asked for and what the motors should do now (Input::rumble, fa/platform/input.h);
// apply_gamepad_rumble() below copies it to the hardware once per frame through two small hooks that each platform
// backend defines in its gamepad_<platform> file, so a new backend (Linux evdev, Android, Apple, Windows HID pads) adds
// code to ITS file and touches nothing shared:
//   gamepad_backend_rumble_support(slot)  can the pad in `slot` rumble, and if not, why (a sentence that says what to do
//                                         or which backend will add it). Asked every frame for each connected pad: cheap.
//   gamepad_backend_rumble(slot, low, high, seconds)  starts the motors (each 0..1) for `seconds`, replacing what played;
//                                         seconds 0 with both strengths 0 stops them. The engine clock ends every rumble
//                                         with an explicit stop, so a backend whose hardware has no duration (XInput) just
//                                         sets the motors, and one that has (the web, evdev effects) may pass `seconds` on
//                                         as a safety net. Returns false when the hardware refused (logged once).
// Today: Windows XInput and Chrome-based browsers can rumble; every other backend answers "no" with its reason.
// Windowed runs only, like poll_gamepads(): headless runs and tests have no hardware and read Input instead.
//
// Slots that have no pad are probed only every couple of seconds, so unplugged slots cost nothing. A pad that stays
// plugged in survives the window losing focus: Input::release_all() disconnects it, and the next poll connects it
// again with its current state.
#pragma once

#include <cstdint>
#include <string>

#include "fa/platform/input.h"

namespace fa {

// Reads every attached pad and feeds the state to `input`: connect/disconnect, buttons and axes (+Y up, triggers 0..1).
void poll_gamepads(Input& input);

// What a backend says about the motors of one pad.
struct GamepadRumbleSupport {
    bool can = false;
    std::string why;  // when !can: what is missing and what to do ("" when can)
};
// The per-platform hooks (see above). Defined by gamepad_<platform> or, for a platform with no pad code, by gamepad.cpp.
GamepadRumbleSupport gamepad_backend_rumble_support(int slot);
bool gamepad_backend_rumble(int slot, float low, float high, float seconds);

// Copies Input's rumble to the hardware: tells Input which connected pads can rumble, starts the motors of a pad whose
// request is new, stops those whose request ended, was replaced by a stop or whose pad went away. Call it once per frame
// after the game ran, and right after a stop (focus lost, quit). Main thread only. It uses the platform hooks above.
void apply_gamepad_rumble(Input& input);

// The same logic against any hardware (the platform hooks are one implementation; the tests use a fake one).
class GamepadRumbleSink {
public:
    virtual ~GamepadRumbleSink() = default;
    virtual GamepadRumbleSupport support(int slot) = 0;
    virtual bool play(int slot, float low, float high, float seconds) = 0;  // seconds 0 and no strength: stop
};
// What was last told to the hardware of each slot, so a motor is started only for a new request and stopped once.
class GamepadRumbleSync {
public:
    void apply(Input& input, GamepadRumbleSink& sink);

private:
    struct Sent {
        bool on = false;
        std::uint32_t serial = 0;
    };
    Sent sent_[kMaxGamepads];
};

#if defined(__ANDROID__)
// sapp_desc.android.native_event_cb, installed by to_sapp_desc(): remembers the gamepad key and joystick events of the
// NativeActivity's input queue (poll_gamepads() reports them) and returns true for them, so sokol_app and Android
// do not also treat them as touches or as system keys (BUTTON_B as Back). `nativeEvent` is an AInputEvent*.
bool android_gamepad_event(const void* nativeEvent);
#endif

}  // namespace fa
