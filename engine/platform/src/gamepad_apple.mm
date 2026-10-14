// macOS / iOS gamepads through the GameController framework (extended gamepads: Xbox, PlayStation, MFi...).
// UNTESTED: written without an Apple toolchain on the development machine. Pad i is the i-th entry of
// [GCController controllers]; controllers without an extended profile are skipped.
#import <GameController/GameController.h>

#include "fa/platform/gamepad.h"

namespace fa {

void poll_gamepads(Input& in) {
    NSArray<GCController*>* controllers = [GCController controllers];
    int slot = 0;
    for (GCController* c in controllers) {
        GCExtendedGamepad* g = c.extendedGamepad;
        if (g == nil) continue;
        if (slot >= kMaxGamepads) break;
        const int i = slot++;
        in.on_gamepad_connected(i, true);
        in.on_gamepad_button(i, GamepadButton::A, g.buttonA.isPressed);
        in.on_gamepad_button(i, GamepadButton::B, g.buttonB.isPressed);
        in.on_gamepad_button(i, GamepadButton::X, g.buttonX.isPressed);
        in.on_gamepad_button(i, GamepadButton::Y, g.buttonY.isPressed);
        in.on_gamepad_button(i, GamepadButton::LeftShoulder, g.leftShoulder.isPressed);
        in.on_gamepad_button(i, GamepadButton::RightShoulder, g.rightShoulder.isPressed);
        in.on_gamepad_button(i, GamepadButton::DpadLeft, g.dpad.left.isPressed);
        in.on_gamepad_button(i, GamepadButton::DpadRight, g.dpad.right.isPressed);
        in.on_gamepad_button(i, GamepadButton::DpadUp, g.dpad.up.isPressed);
        in.on_gamepad_button(i, GamepadButton::DpadDown, g.dpad.down.isPressed);
        if (@available(macOS 10.14.1, iOS 12.1, *)) {
            in.on_gamepad_button(i, GamepadButton::LeftThumb, g.leftThumbstickButton.isPressed);
            in.on_gamepad_button(i, GamepadButton::RightThumb, g.rightThumbstickButton.isPressed);
        }
        if (@available(macOS 10.15, iOS 13.0, *)) {
            in.on_gamepad_button(i, GamepadButton::Start, g.buttonMenu.isPressed);
            if (g.buttonOptions != nil) in.on_gamepad_button(i, GamepadButton::Back, g.buttonOptions.isPressed);
        }
        if (@available(macOS 11.0, iOS 14.0, *)) {
            if (g.buttonHome != nil) in.on_gamepad_button(i, GamepadButton::Guide, g.buttonHome.isPressed);
        }
        in.on_gamepad_axis(i, GamepadAxis::LeftX, g.leftThumbstick.xAxis.value);  // GameController's +Y is up
        in.on_gamepad_axis(i, GamepadAxis::LeftY, g.leftThumbstick.yAxis.value);
        in.on_gamepad_axis(i, GamepadAxis::RightX, g.rightThumbstick.xAxis.value);
        in.on_gamepad_axis(i, GamepadAxis::RightY, g.rightThumbstick.yAxis.value);
        in.on_gamepad_axis(i, GamepadAxis::LeftTrigger, g.leftTrigger.value);
        in.on_gamepad_axis(i, GamepadAxis::RightTrigger, g.rightTrigger.value);
    }
    for (int i = slot; i < kMaxGamepads; ++i) in.on_gamepad_connected(i, false);
}

}  // namespace fa
