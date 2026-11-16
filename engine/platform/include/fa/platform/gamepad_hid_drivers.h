// The protocols of the HID pads that have a driver of their own on Windows (HidPadDriver, gamepad_hid.h): the DualShock 4,
// the DualSense (and Edge) and the Switch Pro. Their full input reports are vendor-defined bytes the generic descriptor
// path cannot read, and their motors are driven by output reports of their own. Everything here is bytes in, bytes out
// (no Windows header), so every OS unit-tests it (engine/platform/tests/gamepad_hid_drivers_tests.cpp); gamepad_win32.cpp
// only opens the device and moves the bytes.
//
// The layouts come from the Linux kernel drivers (hid-playstation, hid-nintendo), SDL's HIDAPI drivers and dekuNukem's
// Nintendo_Switch_Reverse_Engineering notes. Not yet checked against a physical pad by FactorIA.
//
// Report sizes. A builder returns the report as the protocol defines it; Windows wants every write to be exactly the
// device's longest output report (HIDP_CAPS.OutputReportByteLength), which fit_hid_output_report() pads or trims.
#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <vector>

#include "fa/platform/gamepad_hid.h"
#include "fa/platform/gamepad_mapping.h"

namespace fa {

inline constexpr std::uint16_t kHidVendorSony = 0x054c;
inline constexpr std::uint16_t kHidVendorNintendo = 0x057e;
inline constexpr std::uint16_t kHidProductDualShock4 = 0x05c4;
inline constexpr std::uint16_t kHidProductDualShock4v2 = 0x09cc;
inline constexpr std::uint16_t kHidProductDualShock4Adapter = 0x0ba0;  // Sony's USB wireless adapter: a USB DualShock 4
inline constexpr std::uint16_t kHidProductDualSense = 0x0ce6;
inline constexpr std::uint16_t kHidProductDualSenseEdge = 0x0df2;
inline constexpr std::uint16_t kHidProductSwitchPro = 0x2009;

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------
// CRC-32 as zlib computes it (IEEE 802.3, reflected polynomial 0xEDB88320, initial and final XOR 0xFFFFFFFF). `crc`
// chains: hid_crc32(b, hid_crc32(a)) is the CRC of a followed by b. hid_crc32("123456789") is 0xCBF43926.
std::uint32_t hid_crc32(std::span<const std::uint8_t> data, std::uint32_t crc = 0);
// A PlayStation pad's Bluetooth reports end with a little-endian CRC-32 of the Bluetooth HID header byte (the seed: 0xA2
// for an output report the host sends, 0xA1 for an input report) followed by the report without its last 4 bytes.
inline constexpr std::uint8_t kPsOutputCrcSeed = 0xA2;
inline constexpr std::uint8_t kPsInputCrcSeed = 0xA1;
std::uint32_t playstation_bt_crc(std::uint8_t seed, std::span<const std::uint8_t> reportWithoutCrc);
// The full Bluetooth input reports (DualShock 4 0x11, DualSense 0x31) are 78 bytes: the CRC (seed 0xA1) of bytes 0..73
// in bytes 74..77. Windows hands a report over in a buffer as long as the device's longest input report, so the CRC
// stays at byte 74 whatever the length. True when `report` is at least 78 bytes long and that CRC does not match (a
// report damaged on the radio link: the decoders drop it); a shorter report has no CRC to check.
inline constexpr size_t kPsBtInputReportSize = 78;
bool playstation_bt_input_crc_bad(std::span<const std::uint8_t> report);

// A rumble strength (0..1, clamped; NaN is 0) as a motor byte 0..255, rounded to the nearest.
std::uint8_t rumble_motor_byte(float strength);

// `report` sized to exactly `length` bytes (the device's OutputReportByteLength): zeros added, or zero bytes trimmed from
// the end. Empty when trimming would cut a byte that is not zero (the report does not fit the device), or `length` is 0.
std::optional<std::vector<std::uint8_t>> fit_hid_output_report(std::span<const std::uint8_t> report, size_t length);

// ---------------------------------------------------------------------------
// DualShock 4
// ---------------------------------------------------------------------------
// Input. Report 0x01 (USB, the wireless adapter, and Bluetooth before the full report is on) holds the state at byte 1;
// report 0x11 (Bluetooth, full) holds it at byte 3 when byte 1 has the 0x80 flag (the report carries input). From there:
// LX LY RX RY (0..255, centre 128, +Y down), the hat (low nibble: 0 up, clockwise, 8 centred) with Square 0x10, Cross
// 0x20, Circle 0x40, Triangle 0x80; L1 0x01, R1 0x02, L2 0x04, R2 0x08, Share 0x10, Options 0x20, L3 0x40, R3 0x80; PS
// 0x01 (touchpad click 0x02, not mapped); then the analog L2 and R2 (0..255).
// Engine buttons by position: Cross A, Circle B, Square X, Triangle Y; Share Back, Options Start, PS Guide.
// False (state untouched) for another report, one too short, or a report 0x11 whose CRC is bad
// (playstation_bt_input_crc_bad).
bool decode_ds4_report(std::span<const std::uint8_t> report, GamepadState& state);
// Output. USB report 0x05, 32 bytes: [1] = 0x01 (only the motors are valid: the light bar keeps its colour), [4] the
// light (high) motor, [5] the heavy (low) motor. Bluetooth report 0x11, 78 bytes: [1] = 0xC4 (HID data, CRC, a 4 ms
// report interval), [3] = 0x01, [6] the light motor, [7] the heavy motor, [74..77] the CRC (seed 0xA2). A DualShock 4
// sends report 0x11 over Bluetooth once it got one.
std::vector<std::uint8_t> build_ds4_rumble_report(float low, float high, HidTransport transport);
// The feature report whose reading turns the Bluetooth full input report (0x11) on: 0x02, 37 bytes.
inline constexpr std::uint8_t kDs4FeatureCalibration = 0x02;
inline constexpr size_t kDs4FeatureCalibrationSize = 37;

// ---------------------------------------------------------------------------
// DualSense
// ---------------------------------------------------------------------------
// Input. Report 0x01 over USB holds the state at byte 1; report 0x31 (Bluetooth, full) at byte 2. From there: LX LY RX
// RY (as the DualShock 4), the analog L2 and R2, a counter, then the hat and face buttons, L1 R1 L2 R2 Create Options L3
// R3, and PS 0x01 (touchpad 0x02, mic 0x04, the Edge's paddles and Fn buttons above: not mapped) in the DualShock 4's bit
// order. Over Bluetooth report 0x01 is the simple report (another layout): not decoded here, the generic path reads it.
// False (state untouched) for another report, one too short, report 0x01 when `transport` is Bluetooth, or a report 0x31
// whose CRC is bad (playstation_bt_input_crc_bad).
bool decode_dualsense_report(std::span<const std::uint8_t> report, HidTransport transport, GamepadState& state);
// Output. USB report 0x02, 63 bytes; Bluetooth report 0x31, 78 bytes: [1] the sequence tag (`seq` & 15 in the high
// nibble), [2] the tag 0x10, and the common part from [3] (USB: from [1]) whose first bytes are the valid flags 0 and 1,
// the light (high) motor, then the heavy (low) motor; the CRC (seed 0xA2) in [74..77]. The rumble is the "compatible
// vibration" the DualSense emulates with its haptic actuators: valid flag 0 = 0x03 (compatible vibration, haptics
// select); with `vibrationV2` (firmware 2.21 and later, and every Edge: the improved emulation) flag 0 = 0x02 and valid flag
// 2 (common byte 38) = 0x04 instead. Nothing else is valid, so the lights are left alone.
std::vector<std::uint8_t> build_dualsense_rumble_report(float low, float high, HidTransport transport, std::uint8_t seq,
                                                        bool vibrationV2);
// The feature report whose reading turns the Bluetooth full input report (0x31) on: 0x05, 41 bytes.
inline constexpr std::uint8_t kDualSenseFeatureCalibration = 0x05;
inline constexpr size_t kDualSenseFeatureCalibrationSize = 41;
// The firmware report (0x20, 64 bytes): its "update version" (little-endian at bytes 44 and 45) says which vibration the
// pad has. 0x0215 (2.21) and later: vibration v2.
inline constexpr std::uint8_t kDualSenseFeatureFirmware = 0x20;
inline constexpr size_t kDualSenseFeatureFirmwareSize = 64;
std::optional<std::uint16_t> dualsense_update_version(std::span<const std::uint8_t> firmwareReport);
inline constexpr std::uint16_t kDualSenseVibrationV2Version = 0x0215;

// ---------------------------------------------------------------------------
// Switch Pro
// ---------------------------------------------------------------------------
// Input. Report 0x30 (the full report the set-up turns on; 0x31..0x33 and the subcommand replies 0x21 begin the same):
// [3] Y 0x01, X 0x02, B 0x04, A 0x08, R 0x40, ZR 0x80; [4] Minus 0x01, Plus 0x02, R stick 0x04, L stick 0x08, Home 0x10
// (Capture 0x20: not mapped); [5] Down 0x01, Up 0x02, Right 0x04, Left 0x08, L 0x40, ZL 0x80; [6..8] and [9..11] the
// left and right stick, two 12-bit values each (X in the low 12 bits, +Y up). Without the pad's factory calibration (in its
// SPI flash, not read) a stick is read around kSwitchStickCentre with kSwitchStickRange to each side, clamped. ZL and ZR
// have no analog travel: 0 or 1. Engine buttons by position: the bottom button (printed B) is A, the right one (A) is B,
// the left one (Y) is X, the top one (X) is Y; Minus Back, Plus Start, Home Guide. False (state untouched) for another
// report or one too short; report 0x3F (the simple report before the set-up) is left to the generic path.
bool decode_switch_pro_report(std::span<const std::uint8_t> report, GamepadState& state);
inline constexpr int kSwitchStickCentre = 2048;
inline constexpr int kSwitchStickRange = 1400;  // below most pads' real travel, so a full push reads 1

// HD rumble. Each of the two actuators plays a high band and a low band, 4 bytes per actuator: [0] the high frequency's
// low 8 bits, [1] the high band's amplitude (even) with the high frequency's bit 8, [2] the low frequency (7 bits) with
// the top bit of the low band's amplitude, [3] the low band's amplitude. The engine plays fixed frequencies, the pad's
// own resting ones: the low band at 160 Hz (code 0x40) carries `low`, the high band at 320 Hz (code 0x100) carries
// `high`, the same on both actuators (the left and right grips feel alike, as two XInput motors do not, but a strength
// asked for one motor is then never lost). An amplitude is an encoded level 0..100 (switch_rumble_amplitude); 100 is
// amplitude 1.0, the strongest level the notes call safe. Both 0 give the neutral 00 01 40 40.
std::uint8_t switch_rumble_amplitude(float strength);  // 0..1 (clamped) as a linear amplitude -> its code 0..100
std::array<std::uint8_t, 4> switch_hd_rumble(float low, float high);
// Output report 0x10 (rumble only): [1] the packet counter (`seq` & 15), [2..5] the left actuator, [6..9] the right one.
// 64 bytes over USB, 49 over Bluetooth (zeros after the rumble data).
std::vector<std::uint8_t> build_switch_rumble_report(float low, float high, HidTransport transport, std::uint8_t seq);
// Output report 0x01 (a subcommand): [1] the packet counter, [2..9] neutral rumble, [10] the subcommand, [11..] its
// arguments. 64 bytes over USB, 49 over Bluetooth. The pad answers with input report 0x21: [13] the acknowledgement (0x80
// bit set: done), [14] the subcommand.
std::vector<std::uint8_t> build_switch_subcommand(std::uint8_t seq, HidTransport transport, std::uint8_t subcommand,
                                                  std::span<const std::uint8_t> args);
// Output report 0x80 (USB only, 64 bytes): [1] a command for the pad's USB bridge. It answers 0x81 with the command at
// [1], except for 0x04.
std::vector<std::uint8_t> build_switch_usb_command(std::uint8_t command);
inline constexpr std::uint8_t kSwitchUsbHandshake = 0x02, kSwitchUsbBaud3M = 0x03, kSwitchUsbForceHid = 0x04;
inline constexpr std::uint8_t kSwitchSubcommandInputMode = 0x03, kSwitchInputModeFull = 0x30,
                              kSwitchInputModeSimple = 0x3F;
inline constexpr std::uint8_t kSwitchSubcommandVibration = 0x48;

// The set-up steps of the Switch Pro, in order: over USB the bridge's handshake (handshake, 3 Mbit, handshake, then
// "HID only, no timeout", which keeps the pad talking HID over USB), then on both transports subcommand 0x03 0x30 (the
// full report) and 0x48 0x01 (vibration on). Each step but "no timeout" waits for its reply, is sent again when none came
// within kSwitchReplyTimeoutMs, and is skipped after kSwitchStepTries tries.
inline constexpr unsigned kSwitchReplyTimeoutMs = 300;
inline constexpr unsigned kSwitchStepTries = 3;
// How often the motors' report is repeated while they run: the pad stops them by itself when the reports stop coming.
inline constexpr unsigned kSwitchRumbleRefreshMs = 50;
// At exit (HidPadDriver::exit_report), once the full report was asked for: subcommand 0x03 0x3F, the simple report a
// Bluetooth pad starts in and its descriptor declares, so a program that reads the pad after the game (an old DirectInput
// game, a generic HID reader) gets reports it understands.

}  // namespace fa
