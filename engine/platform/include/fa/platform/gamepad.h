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
//   web      none yet: poll_gamepads() does nothing.
// Slots that have no pad are probed only every couple of seconds, so unplugged slots cost nothing. A pad that stays
// plugged in survives the window losing focus: Input::release_all() disconnects it, and the next poll connects it
// again with its current state.
#pragma once

#include "fa/platform/input.h"

namespace fa {

// Reads every attached pad and feeds the state to `input`: connect/disconnect, buttons and axes (+Y up, triggers 0..1).
void poll_gamepads(Input& input);

#if defined(__ANDROID__)
// sapp_desc.android.native_event_cb, installed by to_sapp_desc(): remembers the gamepad key and joystick events of the
// NativeActivity's input queue (poll_gamepads() reports them) and returns true for them, so sokol_app and Android
// do not also treat them as touches or as system keys (BUTTON_B as Back). `nativeEvent` is an AInputEvent*.
bool android_gamepad_event(const void* nativeEvent);
#endif

}  // namespace fa
