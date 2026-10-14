// Physical gamepads. Windowed runs only: fa::run_app() calls poll_gamepads() once per frame, before the game update
// (and not while the window is unfocused). Headless runs, tests and replays never poll; they feed Input directly
// (Input::on_gamepad_*), so they stay deterministic.
//
// Backends: Windows XInput (xinput1_4.dll, loaded at run time: Xbox-style pads, 4 slots), Linux joystick API
// (/dev/input/js0..3, the Xbox layout of the xpad driver; other pads can map differently), Apple GameController
// framework (extended gamepads). Android and web have no backend yet: poll_gamepads() does nothing there.
// Slots that have no pad are probed only every couple of seconds, so unplugged slots cost nothing.
#pragma once

#include "fa/platform/input.h"

namespace fa {

// Reads every attached pad and feeds the state to `input`: connect/disconnect, buttons and axes (+Y up, triggers 0..1).
void poll_gamepads(Input& input);

}  // namespace fa
