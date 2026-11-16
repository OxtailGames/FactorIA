// macOS / iOS gamepads through the GameController framework (extended gamepads: Xbox, PlayStation, MFi...).
// A pad keeps its slot while it stays connected: a new pad takes the slot it had before when that is free (else the first free one), an unplugged pad frees its own
// (the others keep their numbers), like the Android and Linux backends. Controllers without an extended profile are
// skipped. The framework names the buttons by position (buttonA is the bottom face button on every pad), which is the
// engine's convention, so there is no mapping table.
//
// Rumble is GCController.haptics (macOS 11, iOS 14) with CoreHaptics: a pad with left and right handle localities gets one
// CHHapticEngine on each (low on the left, high on the right), any other pad one engine on the default locality that plays
// the stronger of the two. The engines are created the first time a request comes, kept per controller, and released when
// the pad's slot is freed. Everything runs on the main thread (apply_gamepad_rumble, once per frame); starting a player
// does not wait for the hardware. UNTESTED with a real pad: the mapping is unit-tested (gamepad_rumble_map.h).
#import <CoreHaptics/CoreHaptics.h>
#import <GameController/GameController.h>

#include <algorithm>
#include <string>

#include "fa/core/log.h"
#include "fa/platform/gamepad.h"
#include "fa/platform/gamepad_rumble_map.h"

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

// The motors of the pad in a slot: up to two engines with the player that plays now on each.
struct Haptics {
    GCController* controller = nil;  // the pad these engines belong to
    bool made = false;               // the engines were asked for (they may have failed: then `why` says so)
    std::string why;                 // not empty: this pad cannot rumble, and why
    bool split = false;
    CHHapticEngine* engine[2] = {nil, nil};
    id<CHHapticPatternPlayer> player[2] = {nil, nil};
};
Haptics g_haptics[kMaxGamepads];

void stop_players(Haptics& h) {
    for (int i = 0; i < 2; ++i) {
        if (h.player[i] == nil) continue;
        NSError* error = nil;
        [h.player[i] stopAtTime:CHHapticTimeImmediate error:&error];  // an error: it was over already
        h.player[i] = nil;
    }
}

// Stops an engine (the system also frees it when the object goes away; stopping tells the pad's motors to let go now).
void stop_engine(CHHapticEngine* engine) {
    [engine stopWithCompletionHandler:^(NSError*) {
    }];
}

// The pad's slot was freed (or the pad is a different one): stop and drop the engines.
void release_haptics(int slot) {
    Haptics& h = g_haptics[slot];
    stop_players(h);
    for (int i = 0; i < 2; ++i) {
        if (h.engine[i] == nil) continue;
        stop_engine(h.engine[i]);
        h.engine[i] = nil;
    }
    h = Haptics{};
}

// Says what a CoreHaptics call answered, for the first few failures only (a pad that refuses does it at every request).
void log_haptics_error(const char* what, NSError* error) {
    static int logged = 0;
    if (logged >= 5) return;
    ++logged;
    FA_INFO("gamepad", "pad rumble: {} failed: {}", what,
            error ? error.localizedDescription.UTF8String : "no error given");
}

// Creates the engines for the pad (once). `h.why` is left empty when at least one exists.
API_AVAILABLE(macos(11.0), ios(14.0))
void make_engines(Haptics& h, GCController* c) {
    h.made = true;
    GCDeviceHaptics* haptics = c.haptics;
    if (haptics == nil) {
        h.why = "this controller has no haptics (GCController.haptics is nil); rumble needs a pad with motors that "
                "macOS or iOS can drive (Xbox One/Series, DualShock 4, DualSense)";
        return;
    }
    NSSet<GCHapticsLocality>* localities = haptics.supportedLocalities;
    const bool left = [localities containsObject:GCHapticsLocalityLeftHandle];
    const bool right = [localities containsObject:GCHapticsLocalityRightHandle];
    auto make = [&](GCHapticsLocality locality) -> CHHapticEngine* {
        CHHapticEngine* engine = [haptics createEngineWithLocality:locality];
        if (engine == nil) return nil;
        engine.playsHapticsOnly = YES;
        engine.autoShutdownEnabled = YES;  // the system stops an idle engine (power); start_player starts it again
        NSError* error = nil;
        if (![engine startAndReturnError:&error]) {
            FA_INFO("gamepad", "cannot start the haptic engine of '{}': {}", describe(c),
                    error ? error.localizedDescription.UTF8String : "unknown error");
            return nil;
        }
        return engine;
    };
    if (left && right) {
        h.engine[0] = make(GCHapticsLocalityLeftHandle);
        h.engine[1] = make(GCHapticsLocalityRightHandle);
        h.split = h.engine[0] != nil && h.engine[1] != nil;
        if (!h.split) {  // one handle failed: use the default engine instead, and let go of the one that started
            for (int i = 0; i < 2; ++i) {
                if (h.engine[i] != nil) stop_engine(h.engine[i]);
                h.engine[i] = nil;
            }
        }
    }
    if (!h.split) h.engine[0] = make(GCHapticsLocalityDefault);
    if (h.engine[0] == nil)
        h.why = "the system did not give this controller a haptic engine (CHHapticEngine): another app may hold its "
                "haptics, or the pad has none over this connection (Bluetooth haptics need macOS 11 / iOS 14 and a "
                "supported pad)";
}

// A continuous haptic event of this strength and length, started on `engine`.
API_AVAILABLE(macos(11.0), ios(14.0))
id<CHHapticPatternPlayer> start_player(CHHapticEngine* engine, float intensity, float seconds) {
    CHHapticEventParameter* strength =
        [[CHHapticEventParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticIntensity value:intensity];
    CHHapticEvent* event = [[CHHapticEvent alloc] initWithEventType:CHHapticEventTypeHapticContinuous
                                                         parameters:@[ strength ]
                                                       relativeTime:0
                                                           duration:seconds];
    NSError* error = nil;
    CHHapticPattern* pattern = [[CHHapticPattern alloc] initWithEvents:@[ event ] parameters:@[] error:&error];
    if (pattern == nil) {
        log_haptics_error("making the haptic pattern", error);
        return nil;
    }
    if (![engine startAndReturnError:&error]) {  // a no-op when it runs; restarts one the system stopped
        log_haptics_error("starting the haptic engine", error);
        return nil;
    }
    id<CHHapticPatternPlayer> player = [engine createPlayerWithPattern:pattern error:&error];
    if (player == nil) {
        log_haptics_error("making the haptic player", error);
        return nil;
    }
    if (![player startAtTime:CHHapticTimeImmediate error:&error]) {
        log_haptics_error("starting the haptic player", error);
        return nil;
    }
    return player;
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

// GameController gives a name (vendorName, productCategory) and no USB ids or serial number: the id is the name, so two
// pads of one model share an id and take the slots in plugging order.
GamepadInfo info_of(GCController* c) {
    GamepadInfo info;
    info.name = describe(c);
    info.type = type_of(c);
    info.id = make_gamepad_id(0, 0, info.name, "");
    return info;
}

void feed(Input& in, int i, GCController* c) {
    GCExtendedGamepad* g = c.extendedGamepad;
    in.set_gamepad_info(i, info_of(c));
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
        release_haptics(i);
        g_slots[i] = nil;
    }
    // New pads take the first free slot.
    for (GCController* c in pads) {
        bool known = false;
        for (int i = 0; i < kMaxGamepads && !known; ++i) known = g_slots[i] == c;
        if (known) continue;
        bool occupied[kMaxGamepads];
        for (int i = 0; i < kMaxGamepads; ++i) occupied[i] = g_slots[i] != nil;
        const int free = in.choose_gamepad_slot(info_of(c).id, occupied);  // its old slot when that is free
        if (free < 0) break;  // four pads already
        release_haptics(free);
        g_slots[free] = c;
        FA_INFO("gamepad", "pad {} connected: {}", free, describe(c));
    }
    for (int i = 0; i < kMaxGamepads; ++i) {
        if (g_slots[i] != nil) feed(in, i, g_slots[i]);
        else in.on_gamepad_connected(i, false);
    }
}

GamepadRumbleSupport gamepad_backend_rumble_support(int slot) {
    if (slot < 0 || slot >= kMaxGamepads || g_slots[slot] == nil) return {false, "there is no pad in this slot"};
    if (@available(macOS 11.0, iOS 14.0, *)) {
        GCController* c = g_slots[slot];
        // Cheap and answered every frame: only the haptics object is looked at; the engines are made by the first
        // request, and an engine that cannot be made turns this answer into "no" with the reason.
        if (g_haptics[slot].made && g_haptics[slot].controller == c && !g_haptics[slot].why.empty())
            return {false, g_haptics[slot].why};
        if (c.haptics == nil)
            return {false, "this controller has no haptics (GCController.haptics is nil); rumble needs a pad with "
                           "motors that macOS or iOS can drive (Xbox One/Series, DualShock 4, DualSense)"};
        return {true, {}};
    }
    return {false, "pad rumble needs macOS 11 or iOS 14 (GCController.haptics)"};
}

bool gamepad_backend_rumble(int slot, float low, float high, float seconds) {
    if (slot < 0 || slot >= kMaxGamepads || g_slots[slot] == nil) return false;
    if (@available(macOS 11.0, iOS 14.0, *)) {
        GCController* c = g_slots[slot];
        Haptics& h = g_haptics[slot];
        if (h.controller != c) {  // first request for this pad
            release_haptics(slot);
            h.controller = c;
        }
        if (seconds <= 0.0f && low <= 0.0f && high <= 0.0f) {  // stop
            stop_players(h);
            return true;
        }
        if (!h.made) make_engines(h, c);
        if (h.engine[0] == nil) return false;
        const AppleRumble m = apple_rumble(low, high, seconds, h.split, h.split);
        stop_players(h);  // a new request replaces the one playing
        bool ok = true;
        const float level[2] = {m.left, m.right};
        for (int i = 0; i < (m.split ? 2 : 1); ++i) {
            if (level[i] <= 0.0f) continue;
            h.player[i] = start_player(h.engine[i], level[i], m.seconds);
            ok = ok && h.player[i] != nil;
        }
        return ok;
    }
    return false;
}

}  // namespace fa
