// macOS / iOS gamepads through the GameController framework (extended gamepads: Xbox, PlayStation, MFi...).
// A pad keeps its slot while it stays connected: a new pad takes the first free slot, an unplugged pad frees its own
// (the others keep their numbers), like the Android and Linux backends. Controllers without an extended profile are
// skipped. The framework names the buttons by position (buttonA is the bottom face button on every pad), which is the
// engine's convention, so there is no mapping table.
#import <GameController/GameController.h>

#include <string>

#include "fa/core/log.h"
#include "fa/platform/gamepad.h"

namespace fa {
namespace {

GCController* g_slots[kMaxGamepads];  // ARC: strong references, nil = free slot

std::string describe(GCController* c) {
    std::string name = c.vendorName ? c.vendorName.UTF8String : "unnamed controller";
    if (@available(macOS 10.15, iOS 13.0, *)) {
        if (c.productCategory) name += std::string(" (") + c.productCategory.UTF8String + ")";
    }
    return name;
}

// The family shown on the pad's buttons, from the framework's names (it gives no vendor id): "DualSense", "DualShock 4",
// "Xbox One"... UNTESTED without a Mac.
GamepadType type_of(GCController* c) {
    std::string name = c.vendorName ? c.vendorName.UTF8String : "";
    if (@available(macOS 10.15, iOS 13.0, *)) {
        if (c.productCategory) name += std::string(" ") + c.productCategory.UTF8String;
    }
    return gamepad_type_from_ids(0, name);
}

void feed(Input& in, int i, GCController* c) {
    GCExtendedGamepad* g = c.extendedGamepad;
    in.on_gamepad_connected(i, true);
    in.set_gamepad_type(i, type_of(c));
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
    in.on_gamepad_axis(i, GamepadAxis::LeftX, g.leftThumbstick.xAxis.value);  // GameController's +Y is up too
    in.on_gamepad_axis(i, GamepadAxis::LeftY, g.leftThumbstick.yAxis.value);
    in.on_gamepad_axis(i, GamepadAxis::RightX, g.rightThumbstick.xAxis.value);
    in.on_gamepad_axis(i, GamepadAxis::RightY, g.rightThumbstick.yAxis.value);
    in.on_gamepad_axis(i, GamepadAxis::LeftTrigger, g.leftTrigger.value);
    in.on_gamepad_axis(i, GamepadAxis::RightTrigger, g.rightTrigger.value);
}

}  // namespace

void poll_gamepads(Input& in) {
    NSMutableArray<GCController*>* pads = [NSMutableArray array];
    for (GCController* c in [GCController controllers])
        if (c.extendedGamepad != nil) [pads addObject:c];

    // Free the slots of pads that are gone.
    for (int i = 0; i < kMaxGamepads; ++i) {
        if (g_slots[i] == nil || [pads containsObject:g_slots[i]]) continue;
        FA_INFO("gamepad", "pad {} disconnected: {}", i, describe(g_slots[i]));
        g_slots[i] = nil;
    }
    // New pads take the first free slot.
    for (GCController* c in pads) {
        bool known = false;
        for (int i = 0; i < kMaxGamepads && !known; ++i) known = g_slots[i] == c;
        if (known) continue;
        int free = -1;
        for (int i = 0; i < kMaxGamepads && free < 0; ++i)
            if (g_slots[i] == nil) free = i;
        if (free < 0) break;  // four pads already
        g_slots[free] = c;
        FA_INFO("gamepad", "pad {} connected: {}", free, describe(c));
    }
    for (int i = 0; i < kMaxGamepads; ++i) {
        if (g_slots[i] != nil) feed(in, i, g_slots[i]);
        else in.on_gamepad_connected(i, false);
    }
}

}  // namespace fa
