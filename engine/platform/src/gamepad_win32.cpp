// Windows gamepads: XInput for Xbox-style pads, Raw Input + HID for every other pad (DualShock 4, DualSense, Switch Pro,
// generic USB pads). Only the OS glue lives here; what is decided about a HID pad (its layout, its reports, its GUID and
// mapping, which engine index each device holds, when to probe XInput) is platform-neutral and unit-tested on every OS
// (fa/platform/gamepad_hid.h).
//
// Why Raw Input + hid.dll (and not DirectInput, Windows.Gaming.Input or a read thread per device):
//   - Raw Input delivers each pad's input reports as WM_INPUT messages and its arrival and removal as
//     WM_INPUT_DEVICE_CHANGE (RIDEV_DEVNOTIFY): hot-plug comes from the OS, nothing scans for devices every frame, and
//     nothing reads a device handle (ReadFile on a HID handle would need a thread or overlapped I/O per pad); only the
//     pads with a driver keep one open, to write to them (below).
//   - hid.dll's HidP_* functions read a report through the device's own descriptor (its "preparsed data"), which gives the
//     DirectInput numbering SDL_GameControllerDB's platform:Windows lines were written for (see gamepad_hid.h).
//   - DirectInput is COM and deprecated; Windows.Gaming.Input is WinRT, needs a focused CoreWindow-style app for some pads
//     and hides the raw numbering the database needs.
//   hid.dll and the XInput DLL are loaded at run time (no import library, no new link dependency), from System32 only
//   (LOAD_LIBRARY_SEARCH_SYSTEM32: a DLL of that name next to the game is never picked up).
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
//
// Writing (the set-up and rumble of the pads with a driver: DualShock 4, DualSense, Switch Pro; gamepad_hid_drivers.h).
// Raw Input only reads, so each of those pads also gets a file handle of its own, opened for writing only
// (GENERIC_WRITE: the reports come from Raw Input, and the feature reads are IOCTL_HID_GET_FEATURE, FILE_ANY_ACCESS,
// which any handle may send) and shared with every other program (FILE_SHARE_READ | FILE_SHARE_WRITE), with
// FILE_FLAG_OVERLAPPED. Every write and feature read is overlapped I/O started on the main thread, at most one in
// flight per pad; the rumble wanted meanwhile waits in one slot that the next request replaces (coalesced: only the
// latest strengths are ever sent), and the driver's set-up requests go first, in order. Why overlapped I/O and not a
// writer thread per pad: a HID write takes a few milliseconds over Bluetooth and nothing here needs to wait for it, so
// a thread would add locks, a queue and a join at shutdown (where a write to a pad that is going away can hang) for no
// gain; with overlapped I/O the main thread only checks HasOverlappedIoCompleted, never waits. The checks run in
// poll_gamepads(), in gamepad_backend_rumble() and on a 10 ms timer of the message-only window while anything is
// pending, because poll_gamepads() stops while the game window is unfocused and the stop sent at focus loss must still
// leave. A pad that disappears mid-write: its I/O is cancelled (CancelIoEx), its handle closed, and the OVERLAPPED with
// its buffer kept until the OS has finished with them. A write that fails is tried again (kWriteTries in a row,
// kWriteRetryMs apart); only an error that says the device is gone, or the last try, ends the pad's rumble.
//
// At exit (std::atexit, registered when the backend starts), within kExitBudgetMs for every pad together: the XInput
// motors that were set are zeroed, every HID write in flight is waited for, a HID pad still playing gets its stop, and
// the driver's exit report goes out (the Switch Pro back to its simple report; over USB that is not verified on a real pad).
// On an unhandled exception (an access violation...) a filter, chained to the one before it, zeroes the XInput motors (from a
// thread made for it beforehand, waited for at most kCrashStopWaitMs: the crashing thread may hold any lock); the HID pads
// are left alone there, their writes need the backend's state, which a crash may have left half-changed. A PlayStation pad
// then keeps shaking; a Switch Pro stops by itself about 50 ms later (its rumble needs the report repeated,
// kSwitchRumbleRefreshMs). What does not go through that filter leaves the XInput motors on too: abort() (an assert, a
// noexcept violation, std::terminate), an invalid-parameter or pure-virtual-call handler (crash_win32.cpp ends the process
// there without exit hooks), a hang, a debugger that stops the game or a killed process; they stay until the pad is
// switched off or another program sets them.
#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
// After windows.h: hidsdi.h (which includes hidpi.h and defines NTSTATUS when no DDK header did) needs its types.
#include <hidsdi.h>
#include <xinput.h>

#include <algorithm>
#include <array>
#include <atomic>
#include <cmath>
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
#include "fa/platform/gamepad_hid_drivers.h"
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
    for (const wchar_t* dll : {L"xinput1_4.dll", L"xinput9_1_0.dll"})
        if (HMODULE m = LoadLibraryExW(dll, nullptr, LOAD_LIBRARY_SEARCH_SYSTEM32)) {
            api.getState = reinterpret_cast<GetStateFn>(reinterpret_cast<void*>(GetProcAddress(m, "XInputGetState")));
            if (!api.getState) {
                FreeLibrary(m);  // not the XInput we know: try the next one
                continue;
            }
            api.setState = reinterpret_cast<SetStateFn>(reinterpret_cast<void*>(GetProcAddress(m, "XInputSetState")));
            return api;
        }
    return api;
}

const XInputApi& xinput() {
    static const XInputApi api = load_xinput();
    return api;
}

// The XInput user indices whose motors may be running (set before a strength other than 0 is sent, cleared by a stop
// that succeeded), for the stop at exit and on a crash. Atomic: the crash stop runs on a thread of its own.
std::atomic<bool> g_xinputBuzzing[kMaxGamepads];

// Zeroes the motors of every XInput pad that may be running. A flag is only ever set after xinput() was loaded with
// its XInputSetState, so this never loads anything.
void stop_xinput_motors() {
    for (int i = 0; i < kMaxGamepads; ++i)
        if (g_xinputBuzzing[i].exchange(false)) {
            XINPUT_VIBRATION off{};
            xinput().setState(DWORD(i), &off);
        }
}

// The XInput stop on a crash. The crashing thread may hold any lock (the heap's, the loader's, XInput's own), so the
// stop runs on a thread made beforehand (when an XInput motor first starts), which the filter wakes and waits for at most
// kCrashStopWaitMs: a stop that cannot run in that time is given up and the crash goes on (to the filter that was there
// before, the crash reporter's).
constexpr DWORD kCrashStopWaitMs = 200;
std::atomic<HANDLE> g_crashWake{nullptr};  // set once the thread runs: the filter signals it
HANDLE g_crashDone = nullptr;              // the thread signals it once the motors are stopped
// The filter before ours. Written once after ours is installed and read by the filter, which may run on any thread.
std::atomic<LPTOP_LEVEL_EXCEPTION_FILTER> g_previousFilter{nullptr};
std::atomic<bool> g_crashSeen{
    false};  // a second crash (in another thread, or in the filter after ours) goes straight on

DWORD WINAPI crash_stop_thread(LPVOID) {
    WaitForSingleObject(g_crashWake.load(), INFINITE);
    stop_xinput_motors();
    SetEvent(g_crashDone);
    return 0;
}

LONG WINAPI on_unhandled_exception(EXCEPTION_POINTERS* e) {
    if (const HANDLE wake = g_crashWake.load(); wake && !g_crashSeen.exchange(true)) {
        SetEvent(wake);
        WaitForSingleObject(g_crashDone, kCrashStopWaitMs);
    }
    const LPTOP_LEVEL_EXCEPTION_FILTER previous = g_previousFilter.load();
    return previous ? previous(e) : EXCEPTION_CONTINUE_SEARCH;
}

// Makes the crash-stop thread and installs the filter, the first time an XInput motor starts (main thread only). A
// failure only means no stop on a crash: the stop at exit does not need it.
void arm_crash_stop() {
    static bool armed = false;
    if (armed) return;
    armed = true;
    const HANDLE wake = CreateEventW(nullptr, TRUE, FALSE, nullptr);
    g_crashDone = CreateEventW(nullptr, TRUE, FALSE, nullptr);
    if (!wake || !g_crashDone) return;
    g_crashWake.store(wake);  // before the thread starts: it waits on it
    const HANDLE thread =
        CreateThread(nullptr, 64 * 1024, crash_stop_thread, nullptr, STACK_SIZE_PARAM_IS_A_RESERVATION, nullptr);
    if (!thread) {
        g_crashWake.store(nullptr);
        return;
    }
    CloseHandle(thread);  // it ends with the process (or after a crash stop)
    g_previousFilter.store(SetUnhandledExceptionFilter(on_unhandled_exception));
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
    // Kept loaded for the process, like the XInput DLL.
    HMODULE m = LoadLibraryExW(L"hid.dll", nullptr, LOAD_LIBRARY_SEARCH_SYSTEM32);
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
// IOCTL_HID_GET_FEATURE, what HidD_GetFeature sends (hidclass.h, a driver-kit header): CTL_CODE(FILE_DEVICE_KEYBOARD,
// 100, METHOD_OUT_DIRECT, FILE_ANY_ACCESS). HidD_GetFeature itself is synchronous, which an overlapped handle does not
// allow, so the request goes through DeviceIoControl with an OVERLAPPED, as hidapi does.
constexpr DWORD kIoctlHidGetFeature = 0x000B0192;
constexpr UINT_PTR kServiceTimer = 1;  // the message-only window's timer that checks the pads' writes
constexpr UINT kServiceTimerMs = 10;   // USER_TIMER_MINIMUM
constexpr DWORD kExitBudgetMs = 100;   // at exit: the longest every pad's waits may hold the process, all together
constexpr int kWriteTries = 5;         // a write that fails this many times in a row ends the pad's rumble
constexpr std::uint64_t kWriteRetryMs = 100;  // the wait after a failed write before the next one

// One overlapped I/O on a pad's file handle: the OS writes into `ov` and `buffer` until it completes, so this stays alive
// (moved to Backend::retired when the pad goes) until HasOverlappedIoCompleted says so.
struct HidIo {
    enum class Kind : std::uint8_t { None, Request, Rumble };
    OVERLAPPED ov{};
    HANDLE event = nullptr;  // manual-reset, signalled at completion
    std::vector<std::uint8_t> buffer;
    Kind kind = Kind::None;  // None: nothing in flight
    bool feature = false;    // a feature read (IOCTL_HID_GET_FEATURE), not a write
    HidIo() = default;
    HidIo(const HidIo&) = delete;
    HidIo& operator=(const HidIo&) = delete;
    ~HidIo() {
        if (event) CloseHandle(event);
    }
    bool busy() const { return kind != Kind::None; }
};

// The writing half of a pad with a driver.
struct HidWriter {
    HANDLE file = INVALID_HANDLE_VALUE;
    std::unique_ptr<HidIo> io;                    // set while the file is open
    USHORT outputBytes = 0;                       // HIDP_CAPS.OutputReportByteLength: every write is exactly this long
    USHORT featureBytes = 0;                      // HIDP_CAPS.FeatureReportByteLength
    std::string why;                              // set when the pad cannot rumble (the open or a write failed)
    std::optional<std::array<float, 2>> pending;  // the strengths to send next (low, high); replaced by newer ones
    float low = 0.0f, high = 0.0f;                // what the motors were last sent
    bool motorsOn = false;
    std::uint64_t lastRumbleMs = 0;
    int failures = 0;             // writes that failed in a row (0 after one that succeeded)
    std::uint64_t retryAtMs = 0;  // while failures > 0: no write starts before this time
    bool open() const { return file != INVALID_HANDLE_VALUE; }
};

struct HidPad {
    HANDLE handle = nullptr;  // the Raw Input device handle: not a file handle, nothing to close
    std::vector<std::uint8_t>
        preparsed;  // RIDI_PREPARSEDDATA, ours (no HidD_FreePreparsedData: hid.dll did not allocate it)
    HidLayout layout;
    std::optional<GamepadMapper> mapper;
    GamepadInfo info;
    std::unique_ptr<HidPadDriver> driver;  // nullptr: the generic parser, and no rumble
    GamepadState driverState;              // what the driver read, when it reads the reports
    bool driverRead = false;
    ULONG usageCapacity = 0;  // HidP_MaxUsageListLength of the button page
    HidWriter writer;         // open only for a pad with a driver
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
    // Writes of pads that went away while the OS still owned their OVERLAPPED; freed once complete.
    std::vector<std::unique_ptr<HidIo>> retired;
    // HID devices whose arrival failed for a reason that may pass (Raw Input not ready with their data yet): tried again
    // when the probe schedule says so. `warned`: those already said once in the log.
    std::vector<HANDLE> retry, warned;
    bool timerOn = false;  // kServiceTimer is running
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

// ---------------------------------------------------------------------------
// Writing to a pad with a driver (see the top of the file)
// ---------------------------------------------------------------------------
std::uint64_t now_ms() { return std::uint64_t(GetTickCount64()); }

// A Windows error as the log and canRumble say it: the number and, for the ones a pad gives, what it means.
std::string win_error(DWORD e) {
    const char* what = "";
    switch (e) {
        case ERROR_ACCESS_DENIED: what = "access denied"; break;
        case ERROR_SHARING_VIOLATION: what = "the device is in use by another program"; break;
        case ERROR_FILE_NOT_FOUND:
        case ERROR_PATH_NOT_FOUND: what = "the device is gone"; break;
        case ERROR_DEVICE_NOT_CONNECTED: what = "the device is not connected"; break;
        case ERROR_GEN_FAILURE: what = "the device did not accept the report"; break;
        case ERROR_INVALID_PARAMETER: what = "the device refused the report"; break;
        case ERROR_INVALID_FUNCTION: what = "the device does not take output reports"; break;
        case ERROR_BAD_COMMAND: what = "the device does not take the report (it may be gone)"; break;
        default: break;
    }
    return "error " + std::to_string(e) + (*what ? std::string(": ") + what : std::string());
}

// The write errors after which no write to this handle can succeed: the device or the handle is gone, or the device
// takes no output report at all. Any other (a Bluetooth pad out of range for a moment, a busy radio, a report the pad
// did not take this time) is tried again.
bool write_error_final(DWORD e) {
    switch (e) {
        case ERROR_DEVICE_NOT_CONNECTED:
        case ERROR_DEV_NOT_EXIST:
        case ERROR_NO_SUCH_DEVICE:
        case ERROR_FILE_NOT_FOUND:
        case ERROR_PATH_NOT_FOUND:
        case ERROR_INVALID_HANDLE:
        case ERROR_BAD_COMMAND:
        case ERROR_INVALID_FUNCTION: return true;
        default: return false;
    }
}

// Closes the pad's file handle. An I/O still in flight is cancelled and kept alive in Backend::retired until the OS has
// finished with its OVERLAPPED and buffer.
void close_writer(Backend& b, HidPad& pad) {
    HidWriter& w = pad.writer;
    if (!w.open()) return;
    if (w.io && w.io->busy()) {
        CancelIoEx(w.file, nullptr);
        b.retired.push_back(std::move(w.io));
    }
    CloseHandle(w.file);
    w.file = INVALID_HANDLE_VALUE;
    w.io.reset();
    w.pending.reset();
    w.motorsOn = false;
}

// The pad cannot rumble any more: said once in the log and by canRumble; the handle is closed. Plugging the pad in
// again gives it a new Raw Input handle, so a new writer.
void fail_writer(Backend& b, HidPad& pad, std::string why) {
    FA_WARN("gamepad", "HID pad '{}': {}.", pad.info.name, why);
    pad.writer.why = std::move(why);
    close_writer(b, pad);
}

std::string write_failed(DWORD e, int failures) {
    const std::string times = write_error_final(e) ? std::string() : " " + std::to_string(failures) + " times in a row";
    return "sending a report to this pad failed" + times + " (" + win_error(e) +
           "), so it cannot rumble; plug the pad in again";
}

// A write failed with `e`. An error of write_error_final() ends the pad's rumble at once; any other is given kWriteTries
// tries in a row, kWriteRetryMs apart. `rumble`: the strengths that failed, sent again unless newer ones wait. Returns
// whether the pad can still rumble.
bool write_failed_again(Backend& b, HidPad& pad, DWORD e, std::uint64_t now,
                        std::optional<std::array<float, 2>> rumble) {
    HidWriter& w = pad.writer;
    ++w.failures;
    if (write_error_final(e) || w.failures >= kWriteTries) {
        fail_writer(b, pad, write_failed(e, w.failures));
        return false;
    }
    w.retryAtMs = now + kWriteRetryMs;
    if (rumble) {
        if (!w.pending) w.pending = rumble;
        w.motorsOn = true;  // what the motors do is unknown now: a later stop, and the one at exit, are sent anyway
    }
    return true;
}

std::string report_too_long(size_t want, USHORT has) {
    return "this pad's output report is " + std::to_string(has) + " bytes, shorter than the " + std::to_string(want) +
           " its rumble report needs (a clone that is not quite the original?), so it cannot rumble";
}

// Opens the pad for writing (a pad with a driver, when it appears). A failure leaves the pad readable (Raw Input does
// not need this handle) and says why it cannot rumble.
void open_writer(HidPad& pad, const std::wstring& path, const HIDP_CAPS& caps) {
    HidWriter& w = pad.writer;
    w.outputBytes = caps.OutputReportByteLength;
    w.featureBytes = caps.FeatureReportByteLength;
    // Writing only: the input comes from Raw Input, and the feature reads (IOCTL_HID_GET_FEATURE) need no access right.
    HANDLE f = CreateFileW(path.c_str(), GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr, OPEN_EXISTING,
                           FILE_FLAG_OVERLAPPED, nullptr);
    if (f == INVALID_HANDLE_VALUE) {
        const DWORD e = GetLastError();
        w.why = "the engine cannot open this pad for writing (" + win_error(e) + ")";
        if (e == ERROR_ACCESS_DENIED || e == ERROR_SHARING_VIOLATION)
            w.why +=
                ": another program holds it exclusively (DS4Windows or HidHide in exclusive mode, another remapper). "
                "Close that program or turn its exclusive mode off, then plug the pad in again";
        else
            w.why += "; plug the pad in again";
        FA_WARN("gamepad", "HID pad '{}': {}. It is still read, without rumble.", pad.info.name, w.why);
        return;
    }
    auto io = std::make_unique<HidIo>();
    io->event = CreateEventW(nullptr, TRUE, FALSE, nullptr);
    if (!io->event) {
        const DWORD e = GetLastError();
        CloseHandle(f);
        w.why = "the engine could not create an event to write to this pad (" + win_error(e) + ")";
        FA_WARN("gamepad", "HID pad '{}': {}.", pad.info.name, w.why);
        return;
    }
    w.file = f;
    w.io = std::move(io);
}

// Starts one overlapped write (or feature read) of `bytes`. 0: started (or already done; the completion is picked up
// by the next check); else the Windows error.
DWORD start_io(HidPad& pad, HidIo::Kind kind, bool feature, std::vector<std::uint8_t> bytes) {
    HidWriter& w = pad.writer;
    HidIo& io = *w.io;
    io.buffer = std::move(bytes);
    if (feature && io.buffer.size() < w.featureBytes) io.buffer.resize(w.featureBytes, 0);
    io.ov = OVERLAPPED{};
    ResetEvent(io.event);
    io.ov.hEvent = io.event;
    const DWORD size = DWORD(io.buffer.size());
    // The feature read passes the buffer both ways: its first byte names the report, the reply overwrites it.
    const BOOL done = feature ? DeviceIoControl(w.file, kIoctlHidGetFeature, io.buffer.data(), size, io.buffer.data(),
                                                size, nullptr, &io.ov)
                              : WriteFile(w.file, io.buffer.data(), size, nullptr, &io.ov);
    if (!done) {
        const DWORD e = GetLastError();
        if (e != ERROR_IO_PENDING) return e;
    }
    io.kind = kind;
    io.feature = feature;
    return 0;
}

// The device's write length for `report`, or nothing (fail_writer said why).
std::optional<std::vector<std::uint8_t>> fitted(Backend& b, HidPad& pad, const std::vector<std::uint8_t>& report) {
    std::optional<std::vector<std::uint8_t>> out = fit_hid_output_report(report, pad.writer.outputBytes);
    if (!out) fail_writer(b, pad, report_too_long(report.size(), pad.writer.outputBytes));
    return out;
}

// Moves one pad's writing on, never waiting: picks up the I/O that completed, then starts the next one (the driver's
// set-up first, then the latest rumble, then the Switch Pro's refresh of running motors).
void service_pad(Backend& b, HidPad& pad, std::uint64_t now) {
    HidWriter& w = pad.writer;
    if (!pad.driver || !w.open()) return;
    HidIo& io = *w.io;
    if (io.busy()) {
        if (!HasOverlappedIoCompleted(&io.ov)) return;
        DWORD got = 0;
        const bool ok = GetOverlappedResult(w.file, &io.ov, &got, FALSE) != FALSE;
        const DWORD e = ok ? 0 : GetLastError();
        const HidIo::Kind kind = io.kind;
        const bool feature = io.feature;
        io.kind = HidIo::Kind::None;
        // A feature read's reply is the whole buffer (DeviceIoControl counts the bytes after the report id).
        if (kind == HidIo::Kind::Request)
            pad.driver->request_done(ok,
                                     ok ? std::span<const std::uint8_t>(io.buffer) : std::span<const std::uint8_t>());
        // A feature read that fails leaves the driver on its fallback; a write that fails is tried again (the driver
        // sends a set-up step again itself, a rumble goes back to `pending`).
        if (!feature && ok) w.failures = 0;
        if (!feature && !ok && e != ERROR_OPERATION_ABORTED) {
            const std::optional<std::array<float, 2>> sent =
                kind == HidIo::Kind::Rumble ? std::optional<std::array<float, 2>>(std::array<float, 2>{w.low, w.high})
                                            : std::nullopt;
            if (!write_failed_again(b, pad, e, now, sent)) return;
        }
    }
    if (w.failures > 0 && now < w.retryAtMs) return;  // a failed write: the next one waits a moment
    if (std::optional<HidPadRequest> rq = pad.driver->next_request(now)) {
        const bool feature = rq->kind == HidPadRequest::Kind::GetFeature;
        std::vector<std::uint8_t> bytes = std::move(rq->bytes);
        if (!feature) {
            std::optional<std::vector<std::uint8_t>> sized = fitted(b, pad, bytes);
            if (!sized) return;
            bytes = std::move(*sized);
        }
        if (const DWORD e = start_io(pad, HidIo::Kind::Request, feature, std::move(bytes))) {
            pad.driver->request_done(false, {});
            if (!feature) write_failed_again(b, pad, e, now, std::nullopt);
        }
        return;
    }
    if (!pad.driver->setup_done()) return;
    std::optional<std::array<float, 2>> send = w.pending;
    const unsigned refresh = pad.driver->rumble_refresh_ms();
    if (!send && w.motorsOn && refresh > 0 && now - w.lastRumbleMs >= refresh)
        send = std::array<float, 2>{w.low, w.high};
    if (!send) return;
    w.pending.reset();
    std::optional<std::vector<std::uint8_t>> sized = fitted(b, pad, pad.driver->rumble_report((*send)[0], (*send)[1]));
    if (!sized) return;
    if (const DWORD e = start_io(pad, HidIo::Kind::Rumble, false, std::move(*sized))) {
        write_failed_again(b, pad, e, now, send);
        return;
    }
    w.low = (*send)[0];
    w.high = (*send)[1];
    w.motorsOn = w.low > 0.0f || w.high > 0.0f;
    w.lastRumbleMs = now;
}

// Whether some pad's writing still needs checking without a poll: an I/O in flight, a rumble waiting, the set-up
// waiting for a reply or a time-out, motors that need their refresh, a failed write to try again, or a retired I/O not
// complete yet.
bool needs_service(const Backend& b) {
    if (!b.retired.empty()) return true;
    for (const std::unique_ptr<HidPad>& p : b.pads) {
        const HidWriter& w = p->writer;
        if (!p->driver || !w.open()) continue;
        if (w.io->busy() || w.pending || !p->driver->setup_done() || w.failures > 0 ||
            (w.motorsOn && p->driver->rumble_refresh_ms() > 0))
            return true;
    }
    return false;
}

void update_timer(Backend& b) {
    if (!b.hwnd) return;
    const bool want = needs_service(b);
    if (want && !b.timerOn) b.timerOn = SetTimer(b.hwnd, kServiceTimer, kServiceTimerMs, nullptr) != 0;
    if (!want && b.timerOn) {
        KillTimer(b.hwnd, kServiceTimer);
        b.timerOn = false;
    }
}

void service_all(Backend& b) {
    std::erase_if(b.retired, [](const std::unique_ptr<HidIo>& io) { return HasOverlappedIoCompleted(&io->ov); });
    const std::uint64_t now = now_ms();
    for (size_t i = 0; i < b.pads.size(); ++i) service_pad(b, *b.pads[i], now);
    update_timer(b);
}

// At exit: waits, until `deadline`, for every pad's I/O in flight (a set-up step or a rumble); one that completed frees
// the pad for the next write. Nothing is told to the driver: it is exit.
void exit_wait(Backend& b, std::uint64_t deadline) {
    for (const std::unique_ptr<HidPad>& p : b.pads) {
        HidWriter& w = p->writer;
        if (!p->driver || !w.open() || !w.io->busy()) continue;
        const std::uint64_t now = now_ms();
        if (now < deadline) WaitForSingleObject(w.io->event, DWORD(deadline - now));
        if (HasOverlappedIoCompleted(&w.io->ov)) w.io->kind = HidIo::Kind::None;
    }
}

// At exit (std::atexit), within kExitBudgetMs for every pad together: every write in flight is waited for, a pad whose
// motors run gets the stop, and then the driver's exit report (the Switch Pro back to its simple report). The engine
// already asked for the stop when it shut down, but a write in flight may have kept it waiting. A pad whose write does
// not complete in time is left as it is. No logging: the log may be gone by now.
void flush_at_exit(Backend& b) {
    const std::uint64_t deadline = now_ms() + kExitBudgetMs;
    exit_wait(b, deadline);
    for (const std::unique_ptr<HidPad>& p : b.pads) {
        HidWriter& w = p->writer;
        // motorsOn: the last strengths sent (or being sent) are not 0. A rumble still waiting is dropped: it is exit.
        if (!p->driver || !w.open() || w.io->busy() || !w.motorsOn || !p->driver->setup_done()) continue;
        std::optional<std::vector<std::uint8_t>> stop =
            fit_hid_output_report(p->driver->rumble_report(0.0f, 0.0f), w.outputBytes);
        if (stop && start_io(*p, HidIo::Kind::Rumble, false, std::move(*stop)) == 0) w.motorsOn = false;
    }
    exit_wait(b, deadline);
    for (const std::unique_ptr<HidPad>& p : b.pads) {
        HidWriter& w = p->writer;
        if (!p->driver || !w.open() || w.io->busy()) continue;
        const std::optional<std::vector<std::uint8_t>> report = p->driver->exit_report();
        if (!report) continue;
        std::optional<std::vector<std::uint8_t>> sized = fit_hid_output_report(*report, w.outputBytes);
        if (sized) start_io(*p, HidIo::Kind::Request, false, std::move(*sized));
    }
    exit_wait(b, deadline);
}

// The std::atexit hook, registered when the backend starts: the XInput motors first (no wait), then the HID pads.
void stop_motors_at_exit() {
    stop_xinput_motors();
    if (Backend* b = g_backend) flush_at_exit(*b);
}

// What on_arrival() made of a device: a pad (Done), not a pad of ours (Skip), or not readable yet (Retry).
enum class Arrival : std::uint8_t { Done, Skip, Retry };

// A HID device appeared (an arrival notification, the list taken when Raw Input was registered, or a retry).
Arrival add_device(Backend& b, HANDLE device) {
    if (!b.hid.ok() || find_pad(b, device)) return Arrival::Skip;
    RID_DEVICE_INFO info{};
    info.cbSize = sizeof(info);
    UINT size = sizeof(info);
    if (GetRawInputDeviceInfoW(device, RIDI_DEVICEINFO, &info, &size) == UINT(-1) || info.dwType != RIM_TYPEHID)
        return Arrival::Skip;
    const RID_DEVICE_INFO_HID& hidInfo = info.hid;  // the member dwType names
    if (hidInfo.usUsagePage != kHidPageGenericDesktop ||
        (hidInfo.usUsage != kHidUsageJoystick && hidInfo.usUsage != kHidUsageGamepad))
        return Arrival::Skip;
    const std::wstring path = device_path(device);
    if (path.empty()) return Arrival::Retry;
    std::string ascii(path.size(), '?');  // device paths are ASCII; anything else cannot be "IG_" anyway
    for (size_t i = 0; i < path.size(); ++i)
        if (path[i] < 0x80) ascii[i] = char(path[i]);
    if (hid_path_is_xinput(ascii)) {
        b.probes.notify();  // an XInput pad: XInput reads it, and may take it in a moment
        return Arrival::Skip;
    }

    auto pad = std::make_unique<HidPad>();
    pad->handle = device;
    UINT bytes = 0;
    if (GetRawInputDeviceInfoW(device, RIDI_PREPARSEDDATA, nullptr, &bytes) != 0 || bytes == 0 || bytes > (1u << 20))
        return Arrival::Retry;
    pad->preparsed.resize(size_t(bytes));
    if (GetRawInputDeviceInfoW(device, RIDI_PREPARSEDDATA, pad->preparsed.data(), &bytes) == UINT(-1))
        return Arrival::Retry;

    HIDP_CAPS caps{};
    if (b.hid.getCaps(pad->data(), &caps) != HIDP_STATUS_SUCCESS) return Arrival::Retry;
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
    const std::uint16_t vendor = std::uint16_t(hidInfo.dwVendorId & 0xffffu);
    const std::uint16_t product = std::uint16_t(hidInfo.dwProductId & 0xffffu);
    pad->driver = make_hid_pad_driver(vendor, product, hid_transport_from_path(ascii));
    pad->layout = make_hid_layout(buttons, values);
    // A "joystick" with no input we can read. A pad with a driver may declare its full reports as vendor-defined bytes
    // only: the driver reads those.
    if (pad->layout.empty() && !pad->driver) return Arrival::Skip;
    pad->usageCapacity = b.hid.maxUsageListLength(HidP_Input, kHidPageButton, pad->data());

    std::string name, serial;
    read_strings(b.hid, path, name, serial);
    const GamepadIdentity id = windows_hid_identity(vendor, product, name);
    pad->mapper.emplace(choose_mapping(b, id, pad->layout));
    pad->info.name = name.empty() ? "Gamepad" : name;
    pad->info.vendor = vendor;
    pad->info.product = product;
    pad->info.type = gamepad_type_from_ids(vendor, name);
    // The serial is a Bluetooth pad's address and many USB pads have none: two such pads of one model share an id.
    pad->info.id = make_gamepad_id(vendor, product, pad->info.name, serial);
    if (pad->driver) open_writer(*pad, path, caps);

    b.slots.add(hid_key(device));
    b.pads.push_back(std::move(pad));
    return Arrival::Done;
}

void forget_retry(Backend& b, HANDLE device) {
    std::erase(b.retry, device);
    std::erase(b.warned, device);
}

void on_arrival(Backend& b, HANDLE device) {
    if (add_device(b, device) != Arrival::Retry) {
        forget_retry(b, device);
        return;
    }
    if (std::find(b.retry.begin(), b.retry.end(), device) == b.retry.end()) b.retry.push_back(device);
    if (std::find(b.warned.begin(), b.warned.end(), device) != b.warned.end()) return;
    b.warned.push_back(device);
    FA_WARN("gamepad",
            "A HID gamepad could not be read yet (Windows did not give its description); trying again in a moment.");
    // The first time only: a burst of probes, which the retries ride on. Later retries follow the schedule's slow rate.
    b.probes.notify();
}

void on_removal(Backend& b, HANDLE device) {
    forget_retry(b, device);
    const auto it = std::find_if(b.pads.begin(), b.pads.end(),
                                 [&](const std::unique_ptr<HidPad>& p) { return p->handle == device; });
    if (it == b.pads.end()) {
        b.probes.notify();  // not ours: maybe an XInput pad leaving
        return;
    }
    close_writer(b, **it);
    b.slots.remove(hid_key(device));
    b.pads.erase(it);
    update_timer(b);
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
        if (msg == WM_TIMER && wParam == kServiceTimer) {
            service_all(*b);  // also while the game window is unfocused and poll_gamepads() does not run
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
        g_backend = new Backend();         // lives for the process: the window procedure may run until the last message
        std::atexit(stop_motors_at_exit);  // once: g_backend is never reset
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

    // The probe schedule: XInput's empty user indices, and the HID devices whose arrival is to be tried again.
    const bool probe = b.probes.tick(now_ms());
    if (probe && !b.retry.empty()) {
        const std::vector<HANDLE> again = b.retry;  // on_arrival() edits the list
        for (HANDLE device : again) on_arrival(b, device);
    }

    // XInput: the pads it holds are read every poll; its empty user indices only when the schedule says so.
    if (const GetStateFn get_state = xinput().getState) {
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

    service_all(b);  // the HID pads' set-up and rumble writes move on
}

GamepadRumbleSupport gamepad_backend_rumble_support(int slot) {
    const std::optional<SlotKey> owner = g_backend ? g_backend->slots.owner(slot) : std::nullopt;
    if (!owner) return {false, "there is no pad in this slot"};
    if (owner->source == GamepadSlotTable::Source::Hid) {
        HidPad* pad = find_pad(*g_backend, reinterpret_cast<HANDLE>(std::uintptr_t(owner->id)));
        if (!pad || !pad->driver) return {false, kHidRumbleWhy};
        if (!pad->writer.open()) return {false, pad->writer.why};
        return pad->driver->rumble_support();
    }
    if (!xinput().setState)
        return {false, "this Windows has no XInputSetState (xinput1_4.dll or xinput9_1_0.dll could not be loaded)"};
    // XInput does not say whether a pad has motors (a wireless adapter's pad may not): it is asked to.
    return {true, {}};
}

// XInput motors are 0..65535: the left one is the heavy, low-frequency motor and the right one the light, high-frequency
// one. XInput has no duration: the motors keep going until they are set to 0, which the engine does when the request's
// time is up (and at pause, focus loss, scene change and quit). The HID pads with a driver work the same way: the
// strengths wait in the pad's pending slot and leave as the driver's output report as soon as no other write is in
// flight (the Switch Pro's report is repeated while its motors run, since that pad stops them by itself otherwise).
bool gamepad_backend_rumble(int slot, float low, float high, float) {
    const std::optional<SlotKey> owner = g_backend ? g_backend->slots.owner(slot) : std::nullopt;
    if (!owner) return false;
    if (owner->source == GamepadSlotTable::Source::Hid) {
        Backend& b = *g_backend;
        HidPad* pad = find_pad(b, reinterpret_cast<HANDLE>(std::uintptr_t(owner->id)));
        if (!pad || !pad->driver || !pad->writer.open()) return false;
        HidWriter& w = pad->writer;
        const float l = std::clamp(std::isnan(low) ? 0.0f : low, 0.0f, 1.0f);
        const float h = std::clamp(std::isnan(high) ? 0.0f : high, 0.0f, 1.0f);
        if (l <= 0.0f && h <= 0.0f && !w.motorsOn)
            w.pending.reset();  // a stop, and nothing plays: a rumble still waiting is dropped, nothing is sent
        else
            w.pending = std::array<float, 2>{l, h};
        service_pad(b, *pad, now_ms());
        update_timer(b);
        return pad->writer.open();  // false when this very write failed (fail_writer logged why)
    }
    const SetStateFn set_state = xinput().setState;
    if (!set_state) return false;
    auto motor = [](float v) { return WORD(std::clamp(v, 0.0f, 1.0f) * 65535.0f + 0.5f); };
    XINPUT_VIBRATION vib{};
    vib.wLeftMotorSpeed = motor(low);
    vib.wRightMotorSpeed = motor(high);
    const int user = int(owner->id);  // an XInput user index, 0..3
    if (user < 0 || user >= kMaxGamepads) return false;
    const bool on = vib.wLeftMotorSpeed != 0 || vib.wRightMotorSpeed != 0;
    if (on) {  // before the call: a crash right after it still stops the motors
        g_xinputBuzzing[user].store(true);
        arm_crash_stop();
    }
    const bool ok = set_state(DWORD(user), &vib) == ERROR_SUCCESS;
    if (ok && !on) g_xinputBuzzing[user].store(false);
    return ok;
}

}  // namespace fa
