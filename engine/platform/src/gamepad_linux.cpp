// Linux gamepads through the kernel joystick API: /dev/input/js0..3 is pad 0..3. UNTESTED: written without a Linux
// machine at hand. The button and axis numbers are the ones the xpad driver (Xbox 360/One and compatible pads) gives;
// pads with another layout (PlayStation, Switch, generic HID) report other numbers and map to the wrong buttons.
#include <fcntl.h>
#include <unistd.h>

#include <algorithm>
#include <cerrno>
#include <cstdint>
#include <cstdio>
#include <iterator>

#include "fa/platform/gamepad.h"

namespace fa {

namespace {

// struct js_event of <linux/joystick.h>, spelled out so the kernel header is not needed.
struct JsEvent {
    std::uint32_t time;
    std::int16_t value;
    std::uint8_t type;
    std::uint8_t number;
};
static_assert(sizeof(JsEvent) == 8, "js_event is 8 bytes");
constexpr std::uint8_t kJsButton = 0x01, kJsAxis = 0x02, kJsInit = 0x80;  // kJsInit: the initial state sent on open

struct Slot {
    int fd = -1;
};
Slot g_slots[kMaxGamepads];

void apply(Input& in, int pad, const JsEvent& e) {
    const std::uint8_t type = std::uint8_t(e.type & ~kJsInit);
    if (type == kJsButton) {
        static const GamepadButton buttons[] = {
            GamepadButton::A, GamepadButton::B, GamepadButton::X, GamepadButton::Y, GamepadButton::LeftShoulder,
            GamepadButton::RightShoulder, GamepadButton::Back, GamepadButton::Start, GamepadButton::Guide,
            GamepadButton::LeftThumb, GamepadButton::RightThumb};
        if (size_t(e.number) < std::size(buttons)) in.on_gamepad_button(pad, buttons[e.number], e.value != 0);
    } else if (type == kJsAxis) {
        const float v = std::clamp(float(e.value) / 32767.0f, -1.0f, 1.0f);
        switch (e.number) {  // the joystick API's +Y is down; Input's is up
            case 0: in.on_gamepad_axis(pad, GamepadAxis::LeftX, v); break;
            case 1: in.on_gamepad_axis(pad, GamepadAxis::LeftY, -v); break;
            case 2: in.on_gamepad_axis(pad, GamepadAxis::LeftTrigger, (v + 1.0f) * 0.5f); break;  // -1 released .. 1 pulled
            case 3: in.on_gamepad_axis(pad, GamepadAxis::RightX, v); break;
            case 4: in.on_gamepad_axis(pad, GamepadAxis::RightY, -v); break;
            case 5: in.on_gamepad_axis(pad, GamepadAxis::RightTrigger, (v + 1.0f) * 0.5f); break;
            case 6:  // the D-pad is a hat: two axes
                in.on_gamepad_button(pad, GamepadButton::DpadLeft, v < -0.5f);
                in.on_gamepad_button(pad, GamepadButton::DpadRight, v > 0.5f);
                break;
            case 7:
                in.on_gamepad_button(pad, GamepadButton::DpadUp, v < -0.5f);
                in.on_gamepad_button(pad, GamepadButton::DpadDown, v > 0.5f);
                break;
            default: break;
        }
    }
}

}  // namespace

void poll_gamepads(Input& in) {
    static unsigned frame = 0;
    const bool rescan = (frame++ % 120) == 0;  // hot-plug: look for new pads about every 2 s (at 60 fps)
    for (int i = 0; i < kMaxGamepads; ++i) {
        int& fd = g_slots[i].fd;
        if (fd < 0) {
            if (!rescan) continue;
            char path[32];
            std::snprintf(path, sizeof(path), "/dev/input/js%d", i);
            fd = open(path, O_RDONLY | O_NONBLOCK | O_CLOEXEC);
            if (fd < 0) continue;
            in.on_gamepad_connected(i, true);
        }
        for (;;) {
            JsEvent e;
            ssize_t n = read(fd, &e, sizeof(e));
            if (n == ssize_t(sizeof(e))) {
                apply(in, i, e);
            } else if (n < 0 && errno == EINTR) {
                continue;
            } else if (n < 0 && errno == EAGAIN) {
                break;  // everything pending is read
            } else {  // unplugged (ENODEV) or a broken read
                close(fd);
                fd = -1;
                in.on_gamepad_connected(i, false);
                break;
            }
        }
    }
}

}  // namespace fa
