// Linux gamepads through the kernel joystick API: /dev/input/js0..3 is pad 0..3. The kernel reports raw button and axis
// NUMBERS and their meaning depends on the pad (an Xbox pad's button 2 is X, a DualShock's is Triangle), so each pad is
// identified by its input ids (/sys/class/input/jsN/device/id/*) and name and translated through a mapping line in the
// SDL GameControllerDB format: the SDL_GAMECONTROLLERCONFIG environment variable, then the project's
// gamecontrollerdb.txt, then the built-in database (SDL_GameControllerDB's Linux lines), then the xpad (Xbox) layout.
// The parsing, the lookup and the translation are platform-neutral and unit tested (gamepad_mapping.cpp); this file
// only talks to the kernel. UNTESTED on hardware: written without a Linux machine at hand.
//
// Each open pad keeps a mirror of the device (GamepadMapper), because the joystick API only reports CHANGES. After the
// window loses focus Input::release_all() disconnects every pad and nothing is polled; the kernel keeps queueing the
// pad's events meanwhile (and re-sends its whole state if the queue overflowed), so the first poll after focus returns
// drains them into the mirror and feeds the mirror's complete state, which connects the pad again. A pad that is still
// plugged in therefore comes back connected and correct without having to move first.
//
// Rumble goes through the SAME physical pad's evdev node, /dev/input/eventN (the joystick API has no output): the node is
// found in /sys/class/input/jsN/device/ and opened O_RDWR the first time the engine asks whether the pad can rumble. One
// FF_RUMBLE effect is uploaded per pad (EVIOCSFF: strong = low, weak = high) and played by writing an EV_FF event; the next
// request updates the same effect id. Everything runs on the main thread inside poll/apply (a few ioctl/write calls on a
// non-blocking descriptor, no waiting). The pad's events are never read from that descriptor: the kernel's per-client
// buffer drops the oldest ones by itself. UNTESTED on hardware, like the rest of this file.
#include <fcntl.h>
#include <linux/input.h>
#include <linux/joystick.h>
#include <sys/ioctl.h>
#include <unistd.h>

#include <algorithm>
#include <cerrno>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <optional>
#include <span>
#include <string>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/platform/gamepad.h"
#include "fa/platform/gamepad_mapping.h"
#include "fa/platform/gamepad_rumble_map.h"

namespace fa {

namespace {

// The force-feedback side of a pad: the evdev node, opened on first use, and the one rumble effect uploaded to it.
struct Rumble {
    bool probed = false;
    bool can = false;
    std::string why;    // when !can
    int fd = -1;        // /dev/input/eventN, O_RDWR
    int effectId = -1;  // the uploaded FF_RUMBLE effect, -1 = none yet
    bool playing = false;
};

struct Slot {
    int fd = -1;
    Rumble rumble;
    std::optional<GamepadMapper> mapper;  // present while the pad is open
    GamepadInfo info;                     // id, name, ids and the family (from the vendor id and name)
    std::vector<EvdevAxisRoute> routes;   // raw axis number -> mapping axis or hat
};
Slot g_slots[kMaxGamepads];

// The user's own mapping lines, read once (when the first pad is opened): the SDL_GAMECONTROLLERCONFIG environment
// variable (newline-separated lines) and the project's gamecontrollerdb.txt. Bad lines are reported and skipped.
struct UserMappings {
    std::vector<GamepadMapping> env, file;
};
const UserMappings& user_mappings() {
    static const UserMappings mappings = [] {
        UserMappings u;
        auto load = [](std::string_view text, std::string_view origin, std::vector<GamepadMapping>& out) {
            GamepadMappingSet set = parse_gamepad_mappings(text, origin, "Linux");
            for (const std::string& problem : set.problems) FA_WARN("gamepad", "{}", problem);
            out = std::move(set.mappings);
        };
        if (const char* env = std::getenv("SDL_GAMECONTROLLERCONFIG"); env && *env)
            load(env, "SDL_GAMECONTROLLERCONFIG", u.env);
        if (fs::exists(kGamepadUserDbFile)) {
            Result<std::string> text = fs::read_text(kGamepadUserDbFile);
            if (text)
                load(*text, kGamepadUserDbFile, u.file);
            else
                FA_WARN("gamepad", "Cannot read {}: {}", kGamepadUserDbFile, text.error().message);
        }
        return u;
    }();
    return mappings;
}

std::string read_line(const std::string& path) {  // "" when the file is missing
    std::ifstream f(path);
    std::string line;
    std::getline(f, line);
    return line;
}

unsigned read_hex(const std::string& path) {  // the id files hold one hex number, such as "054c"
    std::ifstream f(path);
    unsigned v = 0;
    f >> std::hex >> v;
    return v;
}

// SDL's newer tools put a CRC of the pad's name in bytes 2-3 of the GUID; the lookup ignores it, so does the comparison.
std::string guid_without_crc(std::string guid) {
    if (guid.size() == 32) guid.replace(4, 4, "0000");
    return guid;
}

bool open_pad(int index, Slot& s) {
    char path[32];
    std::snprintf(path, sizeof(path), "/dev/input/js%d", index);
    const int fd = open(path, O_RDONLY | O_NONBLOCK | O_CLOEXEC);
    if (fd < 0) return false;

    GamepadIdentity id;
    char name[128] = {};
    if (ioctl(fd, JSIOCGNAME(sizeof(name)), name) >= 0) id.name = name;
    const std::string ids = "/sys/class/input/js" + std::to_string(index) + "/device/id/";
    id.bus = std::uint16_t(read_hex(ids + "bustype"));
    id.vendor = std::uint16_t(read_hex(ids + "vendor"));
    id.product = std::uint16_t(read_hex(ids + "product"));
    id.version = std::uint16_t(read_hex(ids + "version"));

    // The evdev ABS_ code behind each raw axis: it tells the D-pad hat (two axes) from the real axes.
    std::uint8_t axisCount = 0;
    std::uint8_t absCodes[ABS_CNT] = {};
    if (ioctl(fd, JSIOCGAXES, &axisCount) < 0) axisCount = 0;
    const int axes = std::min<int>(axisCount, ABS_CNT);
    if (ioctl(fd, JSIOCGAXMAP, absCodes) < 0)  // very old kernels: assume the xpad numbering (X Y Z RX RY RZ, hat 0)
        for (int i = 0; i < axes; ++i) absCodes[i] = std::uint8_t(i < 6 ? i : 0x10 + (i - 6));  // 0x10 = ABS_HAT0X
    s.routes = route_evdev_axes(std::span<const std::uint8_t>(absCodes, size_t(axes)));

    const UserMappings& user = user_mappings();
    std::vector<std::string> problems;
    GamepadMapping mapping = select_gamepad_mapping(user.env, user.file, id, &problems);
    for (const std::string& problem : problems) FA_WARN("gamepad", "{}", problem);
    if (mapping.guid == fallback_gamepad_mapping().guid)
        FA_INFO("gamepad",
                "pad {} ('{}', GUID {}) has no mapping: using the Xbox (xpad) layout. If its buttons are wrong, "
                "add a line for this GUID to SDL_GAMECONTROLLERCONFIG or to {} in the game's folder.",
                index, id.name, gamepad_guid(id), kGamepadUserDbFile);
    else if (guid_without_crc(mapping.guid) == gamepad_guid(id))
        FA_INFO("gamepad", "pad {} ('{}', GUID {}) uses the mapping '{}'.", index, id.name, gamepad_guid(id),
                mapping.name);
    else  // matched by vendor and product only: say so, it is the likely culprit when the buttons come out wrong
        FA_INFO("gamepad",
                "pad {} ('{}', GUID {}) uses the mapping '{}', which is listed for another bus or version of "
                "this pad (GUID {}). If its buttons are wrong, add a line for this GUID to "
                "SDL_GAMECONTROLLERCONFIG or to {} in the game's folder.",
                index, id.name, gamepad_guid(id), mapping.name, mapping.guid, kGamepadUserDbFile);
    s.mapper.emplace(std::move(mapping));
    // The kernel's "uniq" is the pad's serial number (a Bluetooth pad's address); many USB pads have none, and then two pads of
    // one model share an id. The slot is the kernel's jsN number, so a pad that is replugged takes the slot the kernel gives it
    // (usually the one it had, when that is free); the id is what tells it is the same pad.
    s.info.name = id.name.empty() ? "Gamepad" : id.name;
    s.info.vendor = id.vendor;
    s.info.product = id.product;
    s.info.type = gamepad_type_from_ids(id.vendor, id.name);
    s.info.id = make_gamepad_id(id.vendor, id.product, s.info.name, read_line(ids + "../uniq"));
    s.fd = fd;
    return true;
}

// ---- rumble --------------------------------------------------------------------------------------------------------

std::string event_node(int index) {  // "/dev/input/eventN" of the pad jsN, "" when sysfs does not show it
    namespace stdfs = std::filesystem;
    std::error_code ec;
    const stdfs::path dir = "/sys/class/input/js" + std::to_string(index) + "/device";
    for (stdfs::directory_iterator it(dir, ec), end; !ec && it != end; it.increment(ec)) {
        const std::string name = it->path().filename().string();  // ASCII: the kernel's own names
        if (name.size() > 5 && name.compare(0, 5, "event") == 0 &&
            name.find_first_not_of("0123456789", 5) == std::string::npos)
            return "/dev/input/" + name;
    }
    return {};
}

bool test_bit(const unsigned char* bits, size_t size, unsigned bit) {
    return bit / 8 < size && (bits[bit / 8] >> (bit % 8) & 1) != 0;
}

// Opens the pad's event node and asks whether it can play FF_RUMBLE. Once per plugged pad (the result stays until the pad is
// closed): the answer is read every frame.
void probe_rumble(int index, Slot& s) {
    Rumble& r = s.rumble;
    r.probed = true;
    const std::string node = event_node(index);
    if (node.empty()) {
        r.why = "the kernel does not list an event device (/dev/input/eventN) for this pad under /sys/class/input/js" +
                std::to_string(index) + "/device, and rumble goes through it";
        return;
    }
    const int fd = open(node.c_str(), O_RDWR | O_NONBLOCK | O_CLOEXEC);
    if (fd < 0) {
        const int err = errno;
        r.why = "cannot open " + node + " for writing (" + std::strerror(err) + ")";
        if (err == EACCES || err == EPERM)
            r.why +=
                ": rumble needs write access to it. Add the user to the 'input' group (sudo usermod -aG input $USER, "
                "then log in again) or a udev rule such as KERNEL==\"event*\", SUBSYSTEM==\"input\", "
                "TAG+=\"uaccess\" (a file in /etc/udev/rules.d/, then udevadm control --reload and replug the pad)";
        return;
    }
    unsigned char ff[(FF_MAX + 7) / 8 + 1] = {};
    if (ioctl(fd, EVIOCGBIT(EV_FF, sizeof(ff)), ff) < 0 || !test_bit(ff, sizeof(ff), FF_RUMBLE)) {
        r.why = "this pad's driver offers no rumble effect (" + node + " has no FF_RUMBLE force feedback)";
        close(fd);
        return;
    }
    r.fd = fd;
    r.can = true;
}

// Erases the effect (the kernel also does it when the descriptor closes) and closes the node. Called when the pad goes.
void close_rumble(Slot& s) {
    Rumble& r = s.rumble;
    if (r.fd >= 0) {
        if (r.effectId >= 0) ioctl(r.fd, EVIOCRMFF, r.effectId);
        close(r.fd);
    }
    r = Rumble{};
}

bool write_ff(int fd, int code, int value) {  // EV_FF: value 1 plays effect `code`, 0 stops it
    input_event ev = {};
    ev.type = EV_FF;
    ev.code = std::uint16_t(code);
    ev.value = value;
    for (;;) {
        const ssize_t n = write(fd, &ev, sizeof(ev));
        if (n == ssize_t(sizeof(ev))) return true;
        if (n < 0 && errno == EINTR) continue;
        return false;  // EAGAIN (the kernel's queue is full), ENODEV (unplugged), ...
    }
}

void apply(Slot& s, const js_event& e) {
    const std::uint8_t type = std::uint8_t(e.type & ~JS_EVENT_INIT);  // INIT: the state sent when the device is opened
    if (type == JS_EVENT_BUTTON) {
        s.mapper->set_button(e.number, e.value != 0);
    } else if (type == JS_EVENT_AXIS && e.number < s.routes.size()) {
        const float v = std::clamp(float(e.value) / 32767.0f, -1.0f, 1.0f);
        const EvdevAxisRoute& r = s.routes[e.number];
        switch (r.kind) {
            case EvdevAxisRoute::Kind::Axis: s.mapper->set_axis(r.index, v); break;
            case EvdevAxisRoute::Kind::HatX: s.mapper->set_hat_axis(r.index, false, v); break;
            case EvdevAxisRoute::Kind::HatY: s.mapper->set_hat_axis(r.index, true, v); break;
            case EvdevAxisRoute::Kind::Unused: break;
        }
    }
}

}  // namespace

void poll_gamepads(Input& in) {
    static unsigned frame = 0;
    const bool rescan = (frame++ % 120) == 0;  // hot-plug: look for new pads about every 2 s (at 60 fps)
    for (int i = 0; i < kMaxGamepads; ++i) {
        Slot& s = g_slots[i];
        if (s.fd < 0 && (!rescan || !open_pad(i, s))) continue;
        bool alive = true;
        for (;;) {
            js_event e;
            const ssize_t n = read(s.fd, &e, sizeof(e));
            if (n == ssize_t(sizeof(e))) {
                apply(s, e);
            } else if (n < 0 && errno == EINTR) {
                continue;
            } else if (n < 0 && errno == EAGAIN) {
                break;  // everything pending is read
            } else {    // unplugged (ENODEV) or a broken read
                alive = false;
                break;
            }
        }
        if (!alive) {
            close_rumble(s);
            close(s.fd);
            s.fd = -1;
            s.mapper.reset();
            s.routes.clear();
            in.on_gamepad_connected(i, false);
            continue;
        }
        in.set_gamepad_info(i, s.info);  // before the feed, which connects the pad
        s.mapper->state().feed(in, i);   // all of it, every poll: also reconnects the pad after a focus loss
    }
}

GamepadRumbleSupport gamepad_backend_rumble_support(int slot) {
    if (slot < 0 || slot >= kMaxGamepads || g_slots[slot].fd < 0) return {false, "there is no pad in this slot"};
    Slot& s = g_slots[slot];
    if (!s.rumble.probed) probe_rumble(slot, s);
    return {s.rumble.can, s.rumble.can ? std::string() : s.rumble.why};
}

bool gamepad_backend_rumble(int slot, float low, float high, float seconds) {
    if (slot < 0 || slot >= kMaxGamepads) return false;
    Rumble& r = g_slots[slot].rumble;
    if (!r.can || r.fd < 0) return false;
    if (seconds <= 0.0f && low <= 0.0f && high <= 0.0f) {  // stop
        if (!r.playing || r.effectId < 0) return true;
        r.playing = false;
        return write_ff(r.fd, r.effectId, 0);
    }
    const EvdevRumble m = evdev_rumble(low, high, seconds);
    ff_effect effect = {};
    effect.type = FF_RUMBLE;
    effect.id = std::int16_t(r.effectId);  // -1 uploads a new effect; the id of the last one updates it in place
    effect.replay.length = m.lengthMs;     // a request longer than 65.5 s is cut: the engine's stop ends it anyway
    effect.u.rumble.strong_magnitude = m.strong;
    effect.u.rumble.weak_magnitude = m.weak;
    if (ioctl(r.fd, EVIOCSFF, &effect) < 0) {
        if (r.effectId < 0) return false;
        effect.id = -1;  // the old id is not known to the kernel any more (the device was re-registered): upload anew
        if (ioctl(r.fd, EVIOCSFF, &effect) < 0) return false;
    }
    r.effectId = effect.id;  // the kernel picked it
    r.playing = write_ff(r.fd, r.effectId, 1);
    return r.playing;
}

}  // namespace fa
