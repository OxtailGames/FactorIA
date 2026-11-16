// Windows gamepads: XInput for Xbox-style pads, Raw Input + HID for every other pad (DualShock 4, DualSense, Switch Pro,
// generic USB pads). Only the OS glue lives here; what is decided about a HID pad (its layout, its reports, its GUID and
// mapping, which engine index each device holds, when to probe XInput) is platform-neutral and unit-tested on every OS
// (fa/platform/gamepad_hid.h).
//
// Why Raw Input + hid.dll (and not DirectInput, Windows.Gaming.Input or a read thread per device):
//   - Raw Input delivers each pad's input reports as WM_INPUT messages and its arrival and removal as
//     WM_INPUT_DEVICE_CHANGE (RIDEV_DEVNOTIFY): hot-plug comes from the OS, nothing scans for devices every frame, and
//     no device handle stays open (ReadFile on a HID handle would need a thread or overlapped I/O per pad).
//   - hid.dll's HidP_* functions read a report through the device's own descriptor (its "preparsed data"), which gives the
//     DirectInput numbering SDL_GameControllerDB's platform:Windows lines were written for (see gamepad_hid.h).
//   - DirectInput is COM and deprecated; Windows.Gaming.Input is WinRT, needs a focused CoreWindow-style app for some pads
//     and hides the raw numbering the database needs.
//   hid.dll and the XInput DLL are loaded at run time (no import library, no new link dependency).
//
// Threads: none. The messages go to a message-only window of our own, created on the thread that calls
// poll_gamepads() (the main thread, fa::run_app). sokol_app's message loop (PeekMessageW for every window of the thread)
// dispatches them while the frame pumps messages, and poll_gamepads() pumps this window's own queue too, so a loop that
// does not pump (the editor's, a test's) still reads the pads. Every read therefore happens on the main thread: the window
// procedure updates each pad's mirror, and poll_gamepads() feeds the mirrors to Input. RIDEV_INPUTSINK keeps the reports
// coming while the window is in the background (a message-only window is never in the foreground), as XInput does;
// poll_gamepads() itself is not called while the game window is unfocused.
//
// XInput pads also show up as HID devices whose path carries "IG_": those are skipped (hid_path_is_xinput), XInput reads
// them. Their arrival and removal still matter: they tell when to probe the XInput slots (GamepadProbeSchedule).
#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
// After windows.h: hidsdi.h (which includes hidpi.h and defines NTSTATUS when no DDK header did) needs its types.
#include <hidsdi.h>
#include <xinput.h>

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <cwchar>
#include <iterator>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "fa/platform/gamepad.h"
#include "fa/platform/gamepad_hid.h"
#include "fa/platform/gamepad_mapping.h"

namespace fa {

namespace {

// ---------------------------------------------------------------------------
// XInput
// ---------------------------------------------------------------------------
using GetStateFn = DWORD(WINAPI*)(DWORD, XINPUT_STATE*);
using SetStateFn = DWORD(WINAPI*)(DWORD, XINPUT_VIBRATION*);

struct XInputApi {
    GetStateFn getState = nullptr;
    SetStateFn setState = nullptr;  // every XInput DLL has it; nullptr only if the export is somehow missing
};

XInputApi load_xinput() {
    XInputApi api;
    for (const char* dll : {"xinput1_4.dll", "xinput9_1_0.dll"})
        if (HMODULE m = LoadLibraryA(dll)) {
            api.getState = reinterpret_cast<GetStateFn>(reinterpret_cast<void*>(GetProcAddress(m, "XInputGetState")));
            if (!api.getState) continue;
            api.setState = reinterpret_cast<SetStateFn>(reinterpret_cast<void*>(GetProcAddress(m, "XInputSetState")));
            return api;
        }
    return api;
}

const XInputApi& xinput() {
    static const XInputApi api = load_xinput();
    return api;
}

float thumb(SHORT v) { return std::clamp(float(v) / 32767.0f, -1.0f, 1.0f); }

// XInput tells nothing about the pad (no name, no ids, no serial): it is "an Xbox pad in XInput user index i", and the
// id says so (the same id as before HID pads existed, so a game's memory of who held which pad still matches).
GamepadInfo xinput_info(int user) {
    GamepadInfo info;
    info.name = "Xbox controller (XInput)";
    info.vendor = 0x045e;           // Microsoft: what XInput pads present as; the product is unknown
    info.type = GamepadType::Xbox;  // XInput only serves Xbox-style pads
    info.id = make_gamepad_id(info.vendor, 0, "XInput controller", "xinput" + std::to_string(user));
    return info;
}

GamepadState xinput_state(const XINPUT_GAMEPAD& g) {
    GamepadState s;
    const struct {
        WORD mask;
        GamepadButton button;
    } map[] = {{XINPUT_GAMEPAD_A, GamepadButton::A},
               {XINPUT_GAMEPAD_B, GamepadButton::B},
               {XINPUT_GAMEPAD_X, GamepadButton::X},
               {XINPUT_GAMEPAD_Y, GamepadButton::Y},
               {XINPUT_GAMEPAD_START, GamepadButton::Start},
               {XINPUT_GAMEPAD_BACK, GamepadButton::Back},
               {XINPUT_GAMEPAD_DPAD_LEFT, GamepadButton::DpadLeft},
               {XINPUT_GAMEPAD_DPAD_RIGHT, GamepadButton::DpadRight},
               {XINPUT_GAMEPAD_DPAD_UP, GamepadButton::DpadUp},
               {XINPUT_GAMEPAD_DPAD_DOWN, GamepadButton::DpadDown},
               {XINPUT_GAMEPAD_LEFT_SHOULDER, GamepadButton::LeftShoulder},
               {XINPUT_GAMEPAD_RIGHT_SHOULDER, GamepadButton::RightShoulder},
               {XINPUT_GAMEPAD_LEFT_THUMB, GamepadButton::LeftThumb},
               {XINPUT_GAMEPAD_RIGHT_THUMB, GamepadButton::RightThumb}};
    for (const auto& m : map) s.buttons[size_t(m.button)] = (g.wButtons & m.mask) != 0;
    s.axes[size_t(GamepadAxis::LeftX)] = thumb(g.sThumbLX);
    s.axes[size_t(GamepadAxis::LeftY)] = thumb(g.sThumbLY);  // XInput's +Y is up already
    s.axes[size_t(GamepadAxis::RightX)] = thumb(g.sThumbRX);
    s.axes[size_t(GamepadAxis::RightY)] = thumb(g.sThumbRY);
    s.axes[size_t(GamepadAxis::LeftTrigger)] = float(g.bLeftTrigger) / 255.0f;
    s.axes[size_t(GamepadAxis::RightTrigger)] = float(g.bRightTrigger) / 255.0f;
    return s;
}

// ---------------------------------------------------------------------------
// hid.dll
// ---------------------------------------------------------------------------
// The exact types of the SDK's declarations (decltype: no signature written twice). HidP_GetButtonCaps and
// HidP_GetValueCaps are macros over the "Specific" functions, so those are the ones loaded.
struct HidApi {
    decltype(&::HidP_GetCaps) getCaps = nullptr;
    decltype(&::HidP_GetSpecificButtonCaps) getButtonCaps = nullptr;
    decltype(&::HidP_GetSpecificValueCaps) getValueCaps = nullptr;
    decltype(&::HidP_GetUsages) getUsages = nullptr;
    decltype(&::HidP_GetUsageValue) getUsageValue = nullptr;
    decltype(&::HidP_MaxUsageListLength) maxUsageListLength = nullptr;
    decltype(&::HidD_GetProductString) getProductString = nullptr;
    decltype(&::HidD_GetSerialNumberString) getSerialNumberString = nullptr;
    bool ok() const {
        return getCaps && getButtonCaps && getValueCaps && getUsages && getUsageValue && maxUsageListLength &&
               getProductString && getSerialNumberString;
    }
};

template <typename Fn>
void load_proc(HMODULE m, const char* name, Fn& out) {
    out = reinterpret_cast<Fn>(reinterpret_cast<void*>(GetProcAddress(m, name)));
}

HidApi load_hid() {
    HidApi api;
    HMODULE m = LoadLibraryW(L"hid.dll");  // kept loaded for the process, like the XInput DLL
    if (!m) return api;
    load_proc(m, "HidP_GetCaps", api.getCaps);
    load_proc(m, "HidP_GetSpecificButtonCaps", api.getButtonCaps);
    load_proc(m, "HidP_GetSpecificValueCaps", api.getValueCaps);
    load_proc(m, "HidP_GetUsages", api.getUsages);
    load_proc(m, "HidP_GetUsageValue", api.getUsageValue);
    load_proc(m, "HidP_MaxUsageListLength", api.maxUsageListLength);
    load_proc(m, "HidD_GetProductString", api.getProductString);
    load_proc(m, "HidD_GetSerialNumberString", api.getSerialNumberString);
    return api;
}

std::string utf8(const wchar_t* s, size_t len) {
    std::string out;
    if (len == 0 || len > 4096) return out;
    const int n = WideCharToMultiByte(CP_UTF8, 0, s, int(len), nullptr, 0, nullptr, nullptr);
    if (n <= 0) return out;
    out.resize(size_t(n));
    WideCharToMultiByte(CP_UTF8, 0, s, int(len), out.data(), n, nullptr, nullptr);
    return out;
}

// ---------------------------------------------------------------------------
// The backend
// ---------------------------------------------------------------------------
struct HidPad {
    HANDLE handle = nullptr;  // the Raw Input device handle: not a file handle, nothing to close
    std::vector<std::uint8_t>
        preparsed;  // RIDI_PREPARSEDDATA, ours (no HidD_FreePreparsedData: hid.dll did not allocate it)
    HidLayout layout;
    std::optional<GamepadMapper> mapper;
    GamepadInfo info;
    std::unique_ptr<HidPadDriver> driver;  // nullptr: the generic parser (every pad today)
    GamepadState driverState;              // what the driver read, when it reads the reports
    bool driverRead = false;
    ULONG usageCapacity = 0;  // HidP_MaxUsageListLength of the button page
    PHIDP_PREPARSED_DATA data() { return reinterpret_cast<PHIDP_PREPARSED_DATA>(preparsed.data()); }
};

using SlotKey = GamepadSlotTable::Key;

struct UserMappings {
    std::vector<GamepadMapping> env, file;
};

struct Backend {
    HWND hwnd = nullptr;
    HidApi hid;
    std::vector<std::unique_ptr<HidPad>> pads;
    GamepadSlotTable slots;
    GamepadProbeSchedule probes;
    bool xinputOn[kMaxGamepads] = {};
    XINPUT_GAMEPAD xinputPad[kMaxGamepads] = {};
    // What poll_gamepads() fed: slot i was fed the device of slot generation fedGen[i].
    bool fed[kMaxGamepads] = {};
    std::uint32_t fedGen[kMaxGamepads] = {};
    // Scratch, reused for every report (up to 1000 a second per pad).
    std::vector<std::uint64_t> raw;  // 8-byte aligned, like RAWINPUT needs
    std::vector<USAGE> usages;
    HidReport report;
    std::optional<UserMappings> user;
};

Backend* g_backend = nullptr;  // created on the first poll, lives for the process (as the window and the DLLs do)

// The user's own mapping lines, read when the first HID pad appears: the SDL_GAMECONTROLLERCONFIG environment variable
// and the project's gamecontrollerdb.txt (their platform:Windows lines). Bad lines are reported and skipped.
const UserMappings& user_mappings(Backend& b) {
    if (b.user) return *b.user;
    UserMappings& u = b.user.emplace();
    auto load = [](std::string_view text, std::string_view origin, std::vector<GamepadMapping>& out) {
        GamepadMappingSet set = parse_gamepad_mappings(text, origin, "Windows");
        for (const std::string& problem : set.problems) FA_WARN("gamepad", "{}", problem);
        out = std::move(set.mappings);
    };
    // _wgetenv: the variable as Windows stores it (UTF-16), not through the ANSI code page.
    if (const wchar_t* env = _wgetenv(L"SDL_GAMECONTROLLERCONFIG"); env && *env)
        load(utf8(env, wcslen(env)), "SDL_GAMECONTROLLERCONFIG", u.env);
    if (fs::exists(kGamepadUserDbFile)) {
        Result<std::string> text = fs::read_text(kGamepadUserDbFile);
        if (text)
            load(*text, kGamepadUserDbFile, u.file);
        else
            FA_WARN("gamepad", "Cannot read {}: {}", kGamepadUserDbFile, text.error().message);
    }
    return u;
}

HidPad* find_pad(Backend& b, HANDLE device) {
    for (const std::unique_ptr<HidPad>& p : b.pads)
        if (p->handle == device) return p.get();
    return nullptr;
}

SlotKey hid_key(HANDLE device) { return {GamepadSlotTable::Source::Hid, std::uint64_t(std::uintptr_t(device))}; }

// The device path (for the IG_ test and to open the device for its strings); empty on failure.
std::wstring device_path(HANDLE device) {
    UINT chars = 0;
    if (GetRawInputDeviceInfoW(device, RIDI_DEVICENAME, nullptr, &chars) != 0 || chars == 0 || chars > 4096) return {};
    std::wstring path(size_t(chars), L'\0');
    const UINT got = GetRawInputDeviceInfoW(device, RIDI_DEVICENAME, path.data(), &chars);
    if (got == UINT(-1) || got == 0) return {};
    path.resize(wcsnlen(path.c_str(), path.size()));
    return path;
}

// The product name and serial number. The device is opened without access rights (0): enough for these queries, allowed
// for pads another process holds, and closed at once.
void read_strings(const HidApi& hid, const std::wstring& path, std::string& name, std::string& serial) {
    HANDLE f = CreateFileW(path.c_str(), 0, FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr, OPEN_EXISTING, 0, nullptr);
    if (f == INVALID_HANDLE_VALUE) return;
    wchar_t buf[128] = {};
    const ULONG bytes = ULONG(sizeof(buf) - sizeof(wchar_t));  // the last character stays 0
    if (hid.getProductString(f, buf, bytes)) name = utf8(buf, wcsnlen(buf, 127));
    std::fill(std::begin(buf), std::end(buf), L'\0');
    if (hid.getSerialNumberString(f, buf, bytes)) serial = utf8(buf, wcsnlen(buf, 127));
    CloseHandle(f);
}

// The mapping of a new pad, said in the log like the Linux backend does.
GamepadMapping choose_mapping(Backend& b, const GamepadIdentity& id, const HidLayout& layout) {
    const UserMappings& user = user_mappings(b);
    std::vector<std::string> problems;
    std::optional<GamepadMapping> found =
        find_gamepad_mapping(user.env, user.file, id, builtin_windows_gamepad_database(), &problems);
    for (const std::string& problem : problems) FA_WARN("gamepad", "{}", problem);
    if (found) {
        FA_INFO("gamepad", "HID pad '{}' (GUID {}) uses the mapping '{}'.", id.name, gamepad_guid(id), found->name);
        return std::move(*found);
    }
    FA_INFO("gamepad",
            "HID pad '{}' (GUID {}) has no mapping: using a default layout built from its report descriptor. If its "
            "buttons are wrong, add a platform:Windows line for this GUID to SDL_GAMECONTROLLERCONFIG or to {} in the "
            "game's folder.",
            id.name, gamepad_guid(id), kGamepadUserDbFile);
    return default_hid_gamepad_mapping(layout);
}

// A HID device appeared (an arrival notification, or the list taken when Raw Input was registered).
void on_arrival(Backend& b, HANDLE device) {
    if (!b.hid.ok() || find_pad(b, device)) return;
    RID_DEVICE_INFO info{};
    info.cbSize = sizeof(info);
    UINT size = sizeof(info);
    if (GetRawInputDeviceInfoW(device, RIDI_DEVICEINFO, &info, &size) == UINT(-1) || info.dwType != RIM_TYPEHID) return;
    const RID_DEVICE_INFO_HID& hidInfo = info.hid;  // the member dwType names
    if (hidInfo.usUsagePage != kHidPageGenericDesktop ||
        (hidInfo.usUsage != kHidUsageJoystick && hidInfo.usUsage != kHidUsageGamepad))
        return;
    const std::wstring path = device_path(device);
    if (path.empty()) return;
    std::string ascii(path.size(), '?');  // device paths are ASCII; anything else cannot be "IG_" anyway
    for (size_t i = 0; i < path.size(); ++i)
        if (path[i] < 0x80) ascii[i] = char(path[i]);
    if (hid_path_is_xinput(ascii)) {
        b.probes.notify();  // an XInput pad: XInput reads it, and may take it in a moment
        return;
    }

    auto pad = std::make_unique<HidPad>();
    pad->handle = device;
    UINT bytes = 0;
    if (GetRawInputDeviceInfoW(device, RIDI_PREPARSEDDATA, nullptr, &bytes) != 0 || bytes == 0 || bytes > (1u << 20))
        return;
    pad->preparsed.resize(size_t(bytes));
    if (GetRawInputDeviceInfoW(device, RIDI_PREPARSEDDATA, pad->preparsed.data(), &bytes) == UINT(-1)) return;

    HIDP_CAPS caps{};
    if (b.hid.getCaps(pad->data(), &caps) != HIDP_STATUS_SUCCESS) return;
    std::vector<HIDP_BUTTON_CAPS> buttonCaps(caps.NumberInputButtonCaps);
    std::vector<HIDP_VALUE_CAPS> valueCaps(caps.NumberInputValueCaps);
    USHORT nButtons = caps.NumberInputButtonCaps, nValues = caps.NumberInputValueCaps;
    if (nButtons &&
        b.hid.getButtonCaps(HidP_Input, 0, 0, 0, buttonCaps.data(), &nButtons, pad->data()) != HIDP_STATUS_SUCCESS)
        nButtons = 0;
    if (nValues &&
        b.hid.getValueCaps(HidP_Input, 0, 0, 0, valueCaps.data(), &nValues, pad->data()) != HIDP_STATUS_SUCCESS)
        nValues = 0;
    std::vector<HidButtonCap> buttons;
    for (size_t i = 0; i < std::min<size_t>(nButtons, buttonCaps.size()); ++i) {
        const HIDP_BUTTON_CAPS& c = buttonCaps[i];
        HidButtonCap cap;
        cap.usagePage = c.UsagePage;
        if (c.IsRange) {  // read only the member of the union that IsRange names
            cap.usageMin = c.Range.UsageMin;
            cap.usageMax = c.Range.UsageMax;
        } else {
            cap.usageMin = cap.usageMax = c.NotRange.Usage;
        }
        buttons.push_back(cap);
    }
    std::vector<HidValueCap> values;
    for (size_t i = 0; i < std::min<size_t>(nValues, valueCaps.size()); ++i) {
        const HIDP_VALUE_CAPS& c = valueCaps[i];
        HidValueCap cap;
        cap.usagePage = c.UsagePage;
        if (c.IsRange) {
            cap.usageMin = c.Range.UsageMin;
            cap.usageMax = c.Range.UsageMax;
        } else {
            cap.usageMin = cap.usageMax = c.NotRange.Usage;
        }
        cap.bitSize = c.BitSize;
        cap.reportCount = c.ReportCount;
        cap.logicalMin = std::int32_t(c.LogicalMin);
        cap.logicalMax = std::int32_t(c.LogicalMax);
        values.push_back(cap);
    }
    pad->layout = make_hid_layout(buttons, values);
    if (pad->layout.empty()) return;  // a "joystick" with no input we can read
    pad->usageCapacity = b.hid.maxUsageListLength(HidP_Input, kHidPageButton, pad->data());

    const std::uint16_t vendor = std::uint16_t(hidInfo.dwVendorId & 0xffffu);
    const std::uint16_t product = std::uint16_t(hidInfo.dwProductId & 0xffffu);
    std::string name, serial;
    read_strings(b.hid, path, name, serial);
    const GamepadIdentity id = windows_hid_identity(vendor, product, name);
    pad->mapper.emplace(choose_mapping(b, id, pad->layout));
    pad->driver = make_hid_pad_driver(vendor, product);
    pad->info.name = name.empty() ? "Gamepad" : name;
    pad->info.vendor = vendor;
    pad->info.product = product;
    pad->info.type = gamepad_type_from_ids(vendor, name);
    // The serial is a Bluetooth pad's address and many USB pads have none: two such pads of one model share an id.
    pad->info.id = make_gamepad_id(vendor, product, pad->info.name, serial);

    b.slots.add(hid_key(device));
    b.pads.push_back(std::move(pad));
}

void on_removal(Backend& b, HANDLE device) {
    const auto it = std::find_if(b.pads.begin(), b.pads.end(),
                                 [&](const std::unique_ptr<HidPad>& p) { return p->handle == device; });
    if (it == b.pads.end()) {
        b.probes.notify();  // not ours: maybe an XInput pad leaving
        return;
    }
    b.slots.remove(hid_key(device));
    b.pads.erase(it);
}

// One report of `pad`: the driver first, then the generic parser.
void read_report(Backend& b, HidPad& pad, std::uint8_t* bytes, ULONG length) {
    if (pad.driver && pad.driver->read_report(std::span<const std::uint8_t>(bytes, length), pad.driverState)) {
        pad.driverRead = true;
        return;
    }
    PCHAR report = reinterpret_cast<PCHAR>(bytes);
    HidReport& r = b.report;
    r.clear();
    if (pad.usageCapacity > 0) {
        if (b.usages.size() < pad.usageCapacity) b.usages.resize(pad.usageCapacity);
        ULONG count = pad.usageCapacity;
        // Not SUCCESS (HIDP_STATUS_INCOMPATIBLE_REPORT_ID): the buttons are in another report and keep their state.
        if (b.hid.getUsages(HidP_Input, kHidPageButton, 0, b.usages.data(), &count, pad.data(), report, length) ==
            HIDP_STATUS_SUCCESS) {
            r.hasButtons = true;
            r.pressed.assign(b.usages.begin(), b.usages.begin() + std::ptrdiff_t(std::min(count, pad.usageCapacity)));
        }
    }
    auto read_value = [&](const HidLayoutValue& v) {
        ULONG value = 0;
        if (b.hid.getUsageValue(HidP_Input, kHidPageGenericDesktop, 0, v.usage, &value, pad.data(), report, length) ==
            HIDP_STATUS_SUCCESS)
            r.values.push_back({v.usage, std::uint32_t(value)});
    };
    for (const HidLayoutValue& v : pad.layout.axes) read_value(v);
    for (const HidLayoutValue& v : pad.layout.hats) read_value(v);
    pad.driverRead = false;
    apply_hid_report(pad.layout, r, *pad.mapper);
}

void on_input(Backend& b, HRAWINPUT input) {
    UINT size = 0;
    if (GetRawInputData(input, RID_INPUT, nullptr, &size, sizeof(RAWINPUTHEADER)) != 0 ||
        size < sizeof(RAWINPUTHEADER) || size > (1u << 20))
        return;
    const size_t words = (size_t(size) + sizeof(std::uint64_t) - 1) / sizeof(std::uint64_t);
    if (b.raw.size() < words) b.raw.resize(words);
    UINT got = size;
    if (GetRawInputData(input, RID_INPUT, b.raw.data(), &got, sizeof(RAWINPUTHEADER)) == UINT(-1) || got > size) return;
    const RAWINPUT* ri = reinterpret_cast<const RAWINPUT*>(b.raw.data());
    if (ri->header.dwType != RIM_TYPEHID) return;
    HidPad* pad = find_pad(b, ri->header.hDevice);
    if (!pad || !pad->mapper) return;
    // The reports follow RAWHID's header in OUR buffer: they are indexed from the buffer, never past bRawData[1].
    const RAWHID& hid = ri->data.hid;  // the member dwType names
    const std::uint64_t each = hid.dwSizeHid, count = hid.dwCount;
    const std::uint64_t start = offsetof(RAWINPUT, data.hid.bRawData);
    if (each == 0 || each > got || count > got || start + each * count > std::uint64_t(got))
        return;  // 64-bit: no overflow
    std::uint8_t* base = reinterpret_cast<std::uint8_t*>(b.raw.data()) + size_t(start);
    for (std::uint64_t i = 0; i < count; ++i) read_report(b, *pad, base + size_t(i * each), ULONG(each));
}

LRESULT CALLBACK window_proc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    Backend* b = g_backend;
    if (b && hwnd == b->hwnd) {
        if (msg == WM_INPUT) {
            on_input(*b, reinterpret_cast<HRAWINPUT>(lParam));
            return DefWindowProcW(hwnd, msg, wParam, lParam);  // lets Raw Input free the message's data
        }
        if (msg == WM_INPUT_DEVICE_CHANGE) {
            const HANDLE device = reinterpret_cast<HANDLE>(lParam);
            if (wParam == GIDC_ARRIVAL)
                on_arrival(*b, device);
            else if (wParam == GIDC_REMOVAL)
                on_removal(*b, device);
            return 0;
        }
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

// The window, the Raw Input registration and the pads already plugged in. Failures are logged once and leave XInput
// working on its own.
void start(Backend& b) {
    b.hid = load_hid();
    if (!b.hid.ok()) {
        FA_WARN("gamepad", "hid.dll could not be loaded: only XInput (Xbox) pads will be read.");
        return;
    }
    const HINSTANCE instance = GetModuleHandleW(nullptr);
    WNDCLASSEXW wc{};
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = window_proc;
    wc.hInstance = instance;
    wc.lpszClassName = L"FactorIA.Gamepads";
    if (!RegisterClassExW(&wc) && GetLastError() != ERROR_CLASS_ALREADY_EXISTS) {
        FA_WARN("gamepad", "Cannot register the gamepad window class (error {}): only XInput pads will be read.",
                GetLastError());
        return;
    }
    // Message-only (HWND_MESSAGE): never shown, gets no broadcast; destroyed by Windows when the process ends.
    b.hwnd = CreateWindowExW(0, wc.lpszClassName, L"", 0, 0, 0, 0, 0, HWND_MESSAGE, nullptr, instance, nullptr);
    if (!b.hwnd) {
        FA_WARN("gamepad", "Cannot create the gamepad window (error {}): only XInput pads will be read.",
                GetLastError());
        return;
    }
    RAWINPUTDEVICE rid[2] = {};
    const USHORT usages[2] = {kHidUsageJoystick, kHidUsageGamepad};
    for (size_t i = 0; i < 2; ++i) {
        rid[i].usUsagePage = kHidPageGenericDesktop;
        rid[i].usUsage = usages[i];
        rid[i].dwFlags = RIDEV_DEVNOTIFY | RIDEV_INPUTSINK;
        rid[i].hwndTarget = b.hwnd;
    }
    if (!RegisterRawInputDevices(rid, 2, sizeof(RAWINPUTDEVICE))) {
        FA_WARN("gamepad", "Cannot register for gamepad Raw Input (error {}): only XInput pads will be read.",
                GetLastError());
        return;
    }
    // The pads plugged in before the registration (an arrival message for one of them, should it come too, changes
    // nothing: on_arrival() knows the handle).
    UINT n = 0;
    if (GetRawInputDeviceList(nullptr, &n, sizeof(RAWINPUTDEVICELIST)) != 0 || n == 0 || n > 4096) return;
    std::vector<RAWINPUTDEVICELIST> list(n);
    const UINT got = GetRawInputDeviceList(list.data(), &n, sizeof(RAWINPUTDEVICELIST));
    if (got == UINT(-1)) return;
    for (UINT i = 0; i < std::min<UINT>(got, UINT(list.size())); ++i)
        if (list[i].dwType == RIM_TYPEHID) on_arrival(b, list[i].hDevice);
}

Backend& backend() {
    if (!g_backend) {
        g_backend = new Backend();  // lives for the process: the window procedure may run until the last message
        start(*g_backend);
    }
    return *g_backend;
}

std::string id_of(Backend& b, const SlotKey& key) {
    if (key.source == GamepadSlotTable::Source::XInput) return xinput_info(int(key.id)).id;
    for (const std::unique_ptr<HidPad>& p : b.pads)
        if (hid_key(p->handle) == key) return p->info.id;
    return {};
}

}  // namespace

void poll_gamepads(Input& in) {
    Backend& b = backend();
    if (b.hwnd) {  // the messages a loop that does not pump this thread's queue left behind
        MSG msg;
        while (PeekMessageW(&msg, b.hwnd, 0, 0, PM_REMOVE)) DispatchMessageW(&msg);
    }

    // XInput: the pads it holds are read every poll; its empty user indices only when the schedule says so.
    if (const GetStateFn get_state = xinput().getState) {
        const bool probe = b.probes.tick();
        for (int i = 0; i < kMaxGamepads; ++i) {
            if (!b.xinputOn[i] && !probe) continue;
            XINPUT_STATE st{};
            const bool ok = get_state(DWORD(i), &st) == ERROR_SUCCESS;
            const SlotKey key{GamepadSlotTable::Source::XInput, std::uint64_t(i)};
            if (ok && !b.xinputOn[i]) b.slots.add(key);
            if (!ok && b.xinputOn[i]) b.slots.remove(key);
            b.xinputOn[i] = ok;
            if (ok) b.xinputPad[i] = st.Gamepad;
        }
    }

    if (b.slots.has_waiting())
        b.slots.assign([&](const SlotKey& key, std::span<const bool> occupied) {
            return in.choose_gamepad_slot(id_of(b, key), occupied);
        });

    for (int s = 0; s < kMaxGamepads; ++s) {
        const std::uint32_t gen = b.slots.generation(s);
        if (gen != b.fedGen[s]) {  // the device this slot was fed left (another may have taken the slot since)
            if (b.fed[s]) in.on_gamepad_connected(s, false);
            b.fed[s] = false;
            b.fedGen[s] = gen;
        }
        const std::optional<SlotKey> owner = b.slots.owner(s);
        if (!owner) continue;
        if (owner->source == GamepadSlotTable::Source::XInput) {
            const int user = int(owner->id);
            in.set_gamepad_info(s, xinput_info(user));  // before the feed, which connects the pad
            xinput_state(b.xinputPad[user]).feed(in, s);
        } else {
            HidPad* pad = find_pad(b, reinterpret_cast<HANDLE>(std::uintptr_t(owner->id)));
            if (!pad) continue;
            in.set_gamepad_info(s, pad->info);
            (pad->driverRead ? pad->driverState : pad->mapper->state()).feed(in, s);
        }
        b.fed[s] = true;  // every poll: also reconnects the pad after a focus loss
    }
}

GamepadRumbleSupport gamepad_backend_rumble_support(int slot) {
    const std::optional<SlotKey> owner = g_backend ? g_backend->slots.owner(slot) : std::nullopt;
    if (!owner) return {false, "there is no pad in this slot"};
    if (owner->source == GamepadSlotTable::Source::Hid) {
        HidPad* pad = find_pad(*g_backend, reinterpret_cast<HANDLE>(std::uintptr_t(owner->id)));
        if (pad && pad->driver) return pad->driver->rumble_support();
        return {false, kHidRumbleWhy};
    }
    if (!xinput().setState)
        return {false, "this Windows has no XInputSetState (xinput1_4.dll or xinput9_1_0.dll could not be loaded)"};
    // XInput does not say whether a pad has motors (a wireless adapter's pad may not): it is asked to.
    return {true, {}};
}

// XInput motors are 0..65535: the left one is the heavy, low-frequency motor and the right one the light, high-frequency
// one. XInput has no duration: the motors keep going until they are set to 0, which the engine does when the request's
// time is up (and at pause, focus loss, scene change and quit). HID pads cannot rumble yet (kHidRumbleWhy): M98.5b2 adds
// the output reports of their drivers here.
bool gamepad_backend_rumble(int slot, float low, float high, float) {
    const std::optional<SlotKey> owner = g_backend ? g_backend->slots.owner(slot) : std::nullopt;
    const SetStateFn set_state = xinput().setState;
    if (!owner || owner->source != GamepadSlotTable::Source::XInput || !set_state) return false;
    auto motor = [](float v) { return WORD(std::clamp(v, 0.0f, 1.0f) * 65535.0f + 0.5f); };
    XINPUT_VIBRATION vib{};
    vib.wLeftMotorSpeed = motor(low);
    vib.wRightMotorSpeed = motor(high);
    return set_state(DWORD(owner->id), &vib) == ERROR_SUCCESS;
}

}  // namespace fa
