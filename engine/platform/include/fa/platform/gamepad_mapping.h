// Gamepad mappings: the raw numbers a device reports (button 3, axis 5, hat 0) -> FactorIA's Xbox-style pad.
//
// The Linux joystick API gives each pad's buttons and axes NUMBERS whose meaning depends on the pad (an Xbox pad's
// button 2 is X, a DualShock's button 2 is Triangle), so Linux needs a table per pad. The table format is the de-facto
// standard one of SDL's GameControllerDB (https://github.com/mdqinc/SDL_GameControllerDB), so lines found there, or
// printed by SDL tools, work as they are:
//
//   <guid>,<name>,<element>:<source>,<element>:<source>,...,platform:Linux,
//   030000004c050000cc09000011810000,PS4 Controller,a:b0,b:b1,x:b3,y:b2,back:b8,guide:b10,start:b9,
//       leftstick:b11,rightstick:b12,leftshoulder:b4,rightshoulder:b5,dpup:h0.1,dpdown:h0.4,dpleft:h0.8,
//       dpright:h0.2,leftx:a0,lefty:a1,rightx:a3,righty:a4,lefttrigger:a2,righttrigger:a5,platform:Linux,
//   (one line; wrapped here)
//
// guid   32 hex digits. On Linux: bus, crc (ignored), vendor, 0, product, 0, version, 0, each a little-endian
//        16-bit number (see gamepad_guid()).
// element  a b x y back start guide leftshoulder rightshoulder leftstick rightstick dpup dpdown dpleft dpright
//        (buttons; a is the bottom face button, b right, x left, y top, whatever the pad prints on them),
//        leftx lefty rightx righty (sticks, SDL's +Y is DOWN), lefttrigger righttrigger.
// source b<N>   raw button N.
//        a<N>   raw axis N, full range. "+a<N>" only its positive half, "-a<N>" only its negative half (both
//               stretched to the element's full range), "a<N>~" or "+a<N>~" inverted.
//        h<N>.<M>  hat N, direction mask M (1 up, 2 right, 4 down, 8 left). Buttons only.
// Other SDL fields (misc1, paddle1..4, touchpad, crc, hint, sdk...) are accepted and ignored; "platform:" lines for
// another OS are skipped by parse_gamepad_mappings().
//
// Deliberate cuts (an SDL line that needs them is reported, not half-applied): sticks read axes only (not buttons or
// hats, i.e. no "-leftx:b13" digital sticks), triggers read axes or buttons (not hats).
//
// Where a Linux pad's mapping comes from, best first (select_gamepad_mapping()):
//   1. the SDL_GAMECONTROLLERCONFIG environment variable (newline separated lines, the SDL standard),
//   2. a `gamecontrollerdb.txt` next to the game's factoria.json (kGamepadUserDbFile; one line per pad, `#` comments),
//   3. the built-in database: SDL_GameControllerDB's Linux lines (external/sdl_gamecontrollerdb/, embedded in the
//      binary) plus a few hand-written lines for the kernel drivers of the DualShock 4, DualSense and Switch Pro,
//   4. the Xbox (xpad) layout.
//
// Everything here is platform-neutral so every OS unit-tests it; only gamepad_linux.cpp talks to the kernel.
#pragma once

#include <array>
#include <bitset>
#include <cstdint>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/types.h"
#include "fa/platform/input.h"

namespace fa {

// The logical state of one pad, in FactorIA's terms: sticks -1..1 with +Y UP, triggers 0..1.
struct GamepadState {
    std::array<bool, size_t(GamepadButton::Count)> buttons{};
    std::array<float, size_t(GamepadAxis::Count)> axes{};

    // Gives all of it to `input` as pad `index`. That also (re)connects the pad, which is what lets a backend that
    // keeps its own mirror of the device recover after Input::release_all() (focus lost) without waiting for the
    // device to send another event.
    void feed(Input& input, int index) const;
};

// Where a logical button or axis reads from. kind == None: unbound (never pressed / at rest).
struct GamepadSource {
    enum class Kind : std::uint8_t { None, Button, Axis, Hat };
    Kind kind = Kind::None;
    std::uint8_t index = 0;    // raw button, axis or hat number
    std::uint8_t hatMask = 0;  // Hat: 1 up, 2 right, 4 down, 8 left
    float inMin = -1.0f;       // Axis: the raw value (-1..1) that maps to the element's minimum ...
    float inMax = 1.0f;        // ... and to its maximum. Half axes: 0..1 or 0..-1; inverted: swapped.
};

inline constexpr int kGamepadMaxRawButtons = 256;  // js_event.number is a byte
inline constexpr int kGamepadMaxRawAxes = 64;      // the kernel's ABS_CNT
inline constexpr int kGamepadMaxRawHats = 4;       // ABS_HAT0X..ABS_HAT3Y

struct GamepadMapping {
    std::string guid;  // 32 lower-case hex digits
    std::string name;
    std::array<GamepadSource, size_t(GamepadButton::Count)> buttons{};
    std::array<GamepadSource, size_t(GamepadAxis::Count)> axes{};  // axes[LeftY] is in SDL's +Y-down convention
};

// One mapping line. The error says what is wrong with the line and shows the format.
Result<GamepadMapping> parse_gamepad_mapping(std::string_view line);

struct GamepadMappingSet {
    std::vector<GamepadMapping> mappings;
    std::vector<std::string> problems;  // one teaching message per rejected line, with its line number
};
// Several lines (the SDL_GAMECONTROLLERCONFIG variable, a database file). `origin` names the text in the messages.
// Blank lines, '#' comments and lines whose platform: field is not `platform` (case-insensitive; pass "Linux") are
// skipped; a line without a platform: field is kept. Good lines survive bad ones.
GamepadMappingSet parse_gamepad_mappings(std::string_view text, std::string_view origin, std::string_view platform);

// Raw device events -> logical state, through one mapping. Feed it what the device reports (in any order, on any
// schedule) and ask state() whenever you want to hand it to Input.
class GamepadMapper {
public:
    explicit GamepadMapper(GamepadMapping mapping);

    void set_button(int raw, bool down);
    void set_axis(int raw, float value);  // -1..1 as the device reports it (for a Y axis +1 is down)
    void set_hat(int hat, int mask);      // SDL direction bits
    // The joystick API reports a hat as two axes, -1..1: horizontal -1 left / +1 right, vertical -1 up / +1 down.
    void set_hat_axis(int hat, bool vertical, float value);

    GamepadState state() const;
    const GamepadMapping& mapping() const { return mapping_; }

private:
    // 0..1: how far the source is "on". Negative: an axis the device never reported (a mapping can name an axis the
    // pad does not have), which leaves its element at rest instead of at the middle of the range.
    float read(const GamepadSource& s) const;

    GamepadMapping mapping_;
    std::bitset<kGamepadMaxRawButtons> buttons_;
    std::array<float, kGamepadMaxRawAxes> axes_{};
    std::bitset<kGamepadMaxRawAxes> axisSeen_;
    std::array<std::uint8_t, kGamepadMaxRawHats> hats_{};
};

// What identifies a pad: the kernel's input ids (Linux: /sys/class/input/jsN/device/id/*) and its name.
struct GamepadIdentity {
    std::uint16_t bus = 0, vendor = 0, product = 0, version = 0;
    std::string name;
};
// The SDL GUID of a Linux pad: bus, crc (0), vendor, 0, product, 0, version, 0, little-endian 16-bit each.
std::string gamepad_guid(const GamepadIdentity& id);

// The mapping for a pad. Lines from `envLines` (SDL_GAMECONTROLLERCONFIG) win over `fileLines` (the user's
// gamecontrollerdb.txt), which win over the built-in database, which wins over the fallback. Inside one list a line that
// matches bus, vendor, product and version wins over one that matches vendor and product only (the later of equals
// wins); a better match in a lower list never beats a worse match in a higher one: the user's word is final.
// A built-in line that does not parse (see the cuts above) is skipped for the next candidate and its message is added to
// `problems`, when given.
GamepadMapping select_gamepad_mapping(std::span<const GamepadMapping> envLines, std::span<const GamepadMapping> fileLines,
                                      const GamepadIdentity& id, std::vector<std::string>* problems = nullptr);
// Same without a user file: `user` is the SDL_GAMECONTROLLERCONFIG lines.
GamepadMapping select_gamepad_mapping(std::span<const GamepadMapping> user, const GamepadIdentity& id);

// The user's mapping file, project-relative (fa::fs): <project>/gamecontrollerdb.txt, in the SDL GameControllerDB
// format. A game author ships it for the pads the players report; a player can drop one next to the game.
inline constexpr const char* kGamepadUserDbFile = "gamecontrollerdb.txt";

// A pile of mapping lines kept as TEXT: indexing reads only each line's GUID, and a line is parsed only when a pad asks
// for it, so a database of hundreds of lines costs one pass over the text, once, and one line parse per lookup.
class GamepadMappingDb {
public:
    // Indexes the lines of `text`, which must outlive the database (it is kept by reference). Blank lines, `#` comments
    // and lines whose GUID is not 32 hex digits or carries no vendor/product ids (SDL's name-made GUIDs, "xinput") can
    // never match a Linux pad and are skipped. Lines for another platform are NOT filtered: pass Linux lines.
    // `origin` names the text in messages and must outlive the database too. Later lines win ties.
    void add_text(std::string_view text, std::string_view origin);
    size_t size() const { return entries_.size(); }  // indexed lines

    // The best line for a pad (an exact bus + version match, else the last line with its vendor and product), parsed.
    // A candidate that fails to parse is skipped for the next one; each such failure is added to `problems` (with the
    // origin and line number), when given. Empty: no line matches.
    std::optional<GamepadMapping> find(const GamepadIdentity& id, std::vector<std::string>* problems = nullptr) const;

private:
    struct Entry {
        std::uint16_t bus = 0, vendor = 0, product = 0, version = 0;
        std::string_view line, origin;
        int lineNo = 0;
    };
    std::vector<Entry> entries_;
};

// The built-in database: the embedded Linux lines of SDL_GameControllerDB, then the hand-written lines of
// builtin_gamepad_mappings() (they come last, so they win a tie: they are what a DualShock 4, DualSense or Switch Pro
// on a version nobody listed gets). Indexed on first use.
const GamepadMappingDb& builtin_gamepad_database();
// The raw text of the embedded database (comment lines included), for tests and tools.
std::string_view embedded_gamepad_database_text();

// The hand-written lines of the built-in database, parsed: DualShock 4, DualSense and Switch Pro as the Linux kernel
// drivers (hid-sony, hid-playstation, hid-nintendo) number them. Derived from the drivers' key and axis lists with the
// joystick API's numbering rule, NOT verified on hardware; SDL_GameControllerDB lists the same layouts for the common
// versions. They stay as the answer for a version the database does not list.
std::span<const GamepadMapping> builtin_gamepad_mappings();
// For pads nothing else matches: the xpad driver's layout (Xbox 360/One, and the many pads that imitate them).
const GamepadMapping& fallback_gamepad_mapping();

// The joystick API numbers axes in evdev-code order and exposes a hat as two axes. The mapping format numbers hats
// separately and axes without them. This translates: pass the evdev ABS_ code of each raw axis (JSIOCGAXMAP).
struct EvdevAxisRoute {
    enum class Kind : std::uint8_t { Unused, Axis, HatX, HatY };
    Kind kind = Kind::Unused;
    std::uint8_t index = 0;  // mapping axis number, or hat number
};
std::vector<EvdevAxisRoute> route_evdev_axes(std::span<const std::uint8_t> absCodes);

}  // namespace fa
