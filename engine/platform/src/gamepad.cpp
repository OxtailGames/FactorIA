// Windows, Linux, Apple, Android and the web have their own gamepad_<platform> file (see cmake/FactoriaHelpers.cmake).
// This file holds what every platform shares (apply_gamepad_rumble) and what is left for a platform with no pad code:
// no pad is ever reported.
#include "fa/platform/gamepad.h"

#include <utility>

#include "fa/core/log.h"

namespace fa {

void GamepadRumbleSync::apply(Input& in, GamepadRumbleSink& sink) {
    for (int slot = 0; slot < kMaxGamepads; ++slot) {
        if (in.gamepad_connected(slot)) {
            GamepadRumbleSupport s = sink.support(slot);
            in.set_gamepad_rumble_support(slot, s.can, std::move(s.why));
        }
        const RumbleState st = in.rumble_state(slot);
        Sent& sent = sent_[slot];
        if (st.active() && in.gamepad_can_rumble(slot)) {
            if (sent.on && sent.serial == st.serial) continue;  // still the request the motors are playing
            if (!sink.play(slot, st.low, st.high, st.remaining))
                FA_WARN("gamepad",
                        "pad {}: the system refused the rumble request (the pad may have just been unplugged)", slot);
            sent.on = true;
            sent.serial = st.serial;
        } else if (sent.on) {
            sink.play(slot, 0.0f, 0.0f, 0.0f);  // ended, replaced by a stop, or the pad is gone
            sent = {};
        }
    }
}

namespace {
struct PlatformSink final : GamepadRumbleSink {
    GamepadRumbleSupport support(int slot) override { return gamepad_backend_rumble_support(slot); }
    bool play(int slot, float low, float high, float seconds) override {
        return gamepad_backend_rumble(slot, low, high, seconds);
    }
};
}  // namespace

void apply_gamepad_rumble(Input& in) {
    static GamepadRumbleSync sync;
    PlatformSink sink;
    sync.apply(in, sink);
}

#if !defined(_WIN32) && !defined(__EMSCRIPTEN__)
// Backends that cannot drive the motors yet answer here, with the reason a game (or an AI) reads. A backend that gains
// rumble moves its pair of hooks into its own gamepad_<platform> file and removes its branch from this #if.
#if defined(__linux__)
#define FA_RUMBLE_WHY                                                                                                  \
    "pad rumble is not implemented on Linux yet (it needs the kernel's force-feedback interface, planned as M98.5c)"
#elif defined(__ANDROID__)
#define FA_RUMBLE_WHY "pad rumble is not implemented on Android yet (planned as M98.5c)"
#elif defined(__APPLE__)
#define FA_RUMBLE_WHY "pad rumble is not implemented on macOS and iOS yet (planned as M98.5c)"
#else
#define FA_RUMBLE_WHY "this platform has no gamepad backend, so no pad can rumble"
#endif
GamepadRumbleSupport gamepad_backend_rumble_support(int) { return {false, FA_RUMBLE_WHY}; }
bool gamepad_backend_rumble(int, float, float, float) { return false; }
#undef FA_RUMBLE_WHY
#endif

#if !defined(_WIN32) && !defined(__linux__) && !defined(__APPLE__) && !defined(__ANDROID__) && !defined(__EMSCRIPTEN__)
void poll_gamepads(Input&) {}
#endif

}  // namespace fa
