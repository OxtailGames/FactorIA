// The HID pads with a driver of their own (fa/platform/gamepad_hid_drivers.h): every output report byte by byte over USB
// and Bluetooth (CRCs computed apart, with zlib), the full input reports on sample bytes, the Switch Pro's set-up, the HD
// rumble encoding and the drivers make_hid_pad_driver() returns. No device here: these are the bytes gamepad_win32.cpp
// moves.
#include <doctest.h>

#include <cmath>
#include <cstdint>
#include <limits>
#include <optional>
#include <string_view>
#include <vector>

#include "fa/platform/gamepad_hid_drivers.h"

using namespace fa;

namespace {

using Bytes = std::vector<std::uint8_t>;

Bytes zeros(size_t n) { return Bytes(n, 0); }

std::uint32_t crc_at(const Bytes& r, size_t at) {
    return std::uint32_t(r[at]) | (std::uint32_t(r[at + 1]) << 8) | (std::uint32_t(r[at + 2]) << 16) |
           (std::uint32_t(r[at + 3]) << 24);
}

bool button(const GamepadState& s, GamepadButton b) { return s.buttons[size_t(b)]; }
float axis(const GamepadState& s, GamepadAxis a) { return s.axes[size_t(a)]; }

}  // namespace

TEST_CASE("CRC-32: the standard check value, chaining, and the PlayStation seed") {
    const std::string_view text = "123456789";
    const Bytes check(text.begin(), text.end());
    CHECK(hid_crc32(check) == 0xCBF43926u);
    CHECK(hid_crc32({}) == 0u);
    const Bytes head(check.begin(), check.begin() + 4), tail(check.begin() + 4, check.end());
    CHECK(hid_crc32(tail, hid_crc32(head)) == 0xCBF43926u);
    Bytes seeded = {0xA2};
    seeded.insert(seeded.end(), check.begin(), check.end());
    CHECK(playstation_bt_crc(kPsOutputCrcSeed, check) == hid_crc32(seeded));
}

TEST_CASE("motor bytes: 0..1 rounded to 0..255, clamped, NaN and 0 stop") {
    CHECK(rumble_motor_byte(0.0f) == 0);
    CHECK(rumble_motor_byte(-1.0f) == 0);
    CHECK(rumble_motor_byte(std::numeric_limits<float>::quiet_NaN()) == 0);
    CHECK(rumble_motor_byte(0.25f) == 64);
    CHECK(rumble_motor_byte(0.5f) == 128);
    CHECK(rumble_motor_byte(0.75f) == 191);
    CHECK(rumble_motor_byte(1.0f) == 255);
    CHECK(rumble_motor_byte(7.0f) == 255);
    CHECK(rumble_motor_byte(0.001f) == 0);  // below half a step: off
}

TEST_CASE("output reports are fitted to the device's output report length") {
    const Bytes r = {0x02, 0x03, 0x00, 0x40, 0x00};
    CHECK(*fit_hid_output_report(r, 5) == r);
    CHECK(*fit_hid_output_report(r, 7) == Bytes{0x02, 0x03, 0x00, 0x40, 0x00, 0x00, 0x00});
    CHECK(*fit_hid_output_report(r, 4) == Bytes{0x02, 0x03, 0x00, 0x40});  // a zero tail is trimmed
    CHECK_FALSE(fit_hid_output_report(r, 3).has_value());                 // 0x40 would be cut
    CHECK_FALSE(fit_hid_output_report(r, 0).has_value());                 // the device has no output report
    // The real cases: a DualSense's 63-byte USB report on a device that declares 64, a Switch Pro's 49-byte Bluetooth
    // report on one that declares 48 (the rumble data ends at byte 9).
    CHECK(fit_hid_output_report(build_dualsense_rumble_report(1, 1, HidTransport::Usb, 0, false), 64)->size() == 64);
    CHECK(fit_hid_output_report(build_switch_rumble_report(1, 1, HidTransport::Bluetooth, 0), 48)->size() == 48);
}

TEST_CASE("the transport comes from the device path: the Bluetooth HID services, any case") {
    CHECK(hid_transport_from_path(
              R"(\\?\HID#{00001124-0000-1000-8000-00805f9b34fb}_VID&0002054c_PID&0ce6#9&2a3e&0&0000#{4d1e55b2})") ==
          HidTransport::Bluetooth);
    CHECK(hid_transport_from_path(R"(\\?\hid#{00001812-0000-1000-8000-00805F9B34FB}&dev&vid_057e&pid_2009#a&1)") ==
          HidTransport::Bluetooth);
    CHECK(hid_transport_from_path(
              R"(\\?\HID#VID_054C&PID_09CC&MI_03#8&1b0e0b1&0&0000#{4d1e55b2-f16f-11cf-88cb-001111000030})") ==
          HidTransport::Usb);
    CHECK(hid_transport_from_path("") == HidTransport::Usb);
    CHECK(hid_transport_from_path("00001124-0000-1000-8000-00805f9b34f") == HidTransport::Usb);  // one digit short
}

// ---------------------------------------------------------------------------
// DualShock 4
// ---------------------------------------------------------------------------
TEST_CASE("DualShock 4 rumble: USB report 0x05 and Bluetooth report 0x11 with its CRC, byte by byte") {
    Bytes usb = zeros(32);
    usb[0] = 0x05;
    usb[1] = 0x01;
    usb[4] = 128;  // light motor = high 0.5
    usb[5] = 255;  // heavy motor = low 1.0
    CHECK(build_ds4_rumble_report(1.0f, 0.5f, HidTransport::Usb) == usb);

    Bytes bt = zeros(78);
    bt[0] = 0x11;
    bt[1] = 0xC4;
    bt[3] = 0x01;
    bt[6] = 128;
    bt[7] = 255;
    bt[74] = 0x19;  // zlib.crc32(b"\xa2" + bytes[0..74)) = 0x3a16be19, little-endian
    bt[75] = 0xbe;
    bt[76] = 0x16;
    bt[77] = 0x3a;
    CHECK(build_ds4_rumble_report(1.0f, 0.5f, HidTransport::Bluetooth) == bt);

    // Stop: both motors 0 (the valid flag stays, or the pad would ignore the report).
    const Bytes stop = build_ds4_rumble_report(0, 0, HidTransport::Bluetooth);
    CHECK(stop[3] == 0x01);
    CHECK(stop[6] == 0);
    CHECK(stop[7] == 0);
    CHECK(crc_at(stop, 74) == 0x89fe8937u);
    const Bytes usbStop = build_ds4_rumble_report(0, 0, HidTransport::Usb);
    CHECK(usbStop[1] == 0x01);
    CHECK(usbStop[4] == 0);
    CHECK(usbStop[5] == 0);
}

TEST_CASE("DualShock 4 input: the USB report 0x01 and the Bluetooth report 0x11") {
    Bytes usb = zeros(64);
    usb[0] = 0x01;
    usb[1] = 0x00;  // LX full left
    usb[2] = 0xFF;  // LY full down
    usb[3] = 0x80;  // RX centred
    usb[4] = 0x80;  // RY centred
    usb[5] = 0x22;  // hat 2 (right), Cross
    usb[6] = 0x31;  // L1, Share, Options
    usb[7] = 0x01;  // PS
    usb[8] = 255;   // L2
    usb[9] = 0;     // R2
    GamepadState s;
    REQUIRE(decode_ds4_report(usb, s));
    CHECK(axis(s, GamepadAxis::LeftX) == doctest::Approx(-1.0f));
    CHECK(axis(s, GamepadAxis::LeftY) == doctest::Approx(-1.0f));  // +Y up
    CHECK(axis(s, GamepadAxis::RightX) == doctest::Approx(0.0f));
    CHECK(axis(s, GamepadAxis::LeftTrigger) == doctest::Approx(1.0f));
    CHECK(axis(s, GamepadAxis::RightTrigger) == doctest::Approx(0.0f));
    CHECK(button(s, GamepadButton::A));
    CHECK_FALSE(button(s, GamepadButton::B));
    CHECK(button(s, GamepadButton::DpadRight));
    CHECK_FALSE(button(s, GamepadButton::DpadUp));
    CHECK(button(s, GamepadButton::LeftShoulder));
    CHECK(button(s, GamepadButton::Back));
    CHECK(button(s, GamepadButton::Start));
    CHECK(button(s, GamepadButton::Guide));
    CHECK_FALSE(button(s, GamepadButton::LeftThumb));

    Bytes bt = zeros(78);
    bt[0] = 0x11;
    bt[1] = 0xC0;   // carries input
    bt[3] = 0xFF;   // LX full right
    bt[4] = 0x00;   // LY full up
    bt[5] = 0x80;
    bt[6] = 0x80;
    bt[7] = 0x87;   // hat 7 (up-left), Triangle
    bt[8] = 0xC2;   // R1, L3, R3
    bt[11] = 128;   // R2 half
    GamepadState b;
    REQUIRE(decode_ds4_report(bt, b));
    CHECK(axis(b, GamepadAxis::LeftX) == doctest::Approx(1.0f));
    CHECK(axis(b, GamepadAxis::LeftY) == doctest::Approx(1.0f));
    CHECK(button(b, GamepadButton::Y));
    CHECK(button(b, GamepadButton::DpadUp));
    CHECK(button(b, GamepadButton::DpadLeft));
    CHECK_FALSE(button(b, GamepadButton::DpadRight));
    CHECK(button(b, GamepadButton::RightShoulder));
    CHECK(button(b, GamepadButton::LeftThumb));
    CHECK(button(b, GamepadButton::RightThumb));
    CHECK(axis(b, GamepadAxis::RightTrigger) == doctest::Approx(128.0f / 255.0f));

    bt[1] = 0x00;  // no input in it
    GamepadState untouched;
    CHECK_FALSE(decode_ds4_report(bt, untouched));
    CHECK_FALSE(decode_ds4_report(Bytes{0x01, 0x80, 0x80}, untouched));  // too short
    CHECK_FALSE(decode_ds4_report(Bytes{0x05, 0, 0, 0, 0, 0, 0, 0, 0, 0}, untouched));
    CHECK_FALSE(decode_ds4_report({}, untouched));
    CHECK_FALSE(untouched.buttons[0]);
}

TEST_CASE("DualShock 4 driver: rumble at once over USB; over Bluetooth it reads feature 0x02 first, once") {
    auto usb = make_hid_pad_driver(kHidVendorSony, kHidProductDualShock4v2, HidTransport::Usb);
    REQUIRE(usb);
    CHECK(usb->rumble_support().can);
    CHECK(usb->rumble_support().why.empty());
    CHECK_FALSE(usb->next_request(0).has_value());
    CHECK(usb->setup_done());
    CHECK(usb->rumble_refresh_ms() == 0);
    CHECK(usb->rumble_report(1.0f, 0.5f) == build_ds4_rumble_report(1.0f, 0.5f, HidTransport::Usb));

    auto bt = make_hid_pad_driver(kHidVendorSony, kHidProductDualShock4, HidTransport::Bluetooth);
    REQUIRE(bt);
    const std::optional<HidPadRequest> feature = bt->next_request(0);
    REQUIRE(feature.has_value());
    CHECK(feature->kind == HidPadRequest::Kind::GetFeature);
    CHECK(feature->bytes.size() == kDs4FeatureCalibrationSize);
    CHECK(feature->bytes[0] == kDs4FeatureCalibration);
    bt->request_done(false, {});  // a failure: the simple report still works, rumble too
    CHECK_FALSE(bt->next_request(1000).has_value());
    CHECK(bt->setup_done());
    CHECK(bt->rumble_report(0, 0) == build_ds4_rumble_report(0, 0, HidTransport::Bluetooth));

    // The wireless adapter is a USB pad whatever the path says.
    auto adapter = make_hid_pad_driver(kHidVendorSony, kHidProductDualShock4Adapter, HidTransport::Bluetooth);
    REQUIRE(adapter);
    CHECK(adapter->transport() == HidTransport::Usb);
}

TEST_CASE("DualShock 4 driver: a report 0x11 means Bluetooth, and is the driver's even without input") {
    auto d = make_hid_pad_driver(kHidVendorSony, kHidProductDualShock4, HidTransport::Usb);
    REQUIRE(d);
    GamepadState s;
    Bytes report = zeros(78);
    report[0] = 0x11;
    CHECK(d->read_report(report, s));
    CHECK(d->transport() == HidTransport::Bluetooth);
    CHECK(d->rumble_report(0.5f, 0.5f).size() == 78);
    REQUIRE(d->next_request(0).has_value());  // the full report's feature read, now that it is Bluetooth

    GamepadState g;
    CHECK_FALSE(d->read_report(Bytes{0x05, 1, 2}, g));  // not a DualShock 4 report: the generic path's
}

// ---------------------------------------------------------------------------
// DualSense
// ---------------------------------------------------------------------------
TEST_CASE("DualSense rumble: USB report 0x02 and Bluetooth report 0x31 with its sequence and CRC, v1 and v2") {
    Bytes usb = zeros(63);
    usb[0] = 0x02;
    usb[1] = 0x03;  // compatible vibration, haptics select
    usb[3] = 191;   // light motor = high 0.75
    usb[4] = 64;    // heavy motor = low 0.25
    CHECK(build_dualsense_rumble_report(0.25f, 0.75f, HidTransport::Usb, 9, false) == usb);
    Bytes usb2 = usb;
    usb2[1] = 0x02;
    usb2[39] = 0x04;  // valid flag 2: compatible vibration v2
    CHECK(build_dualsense_rumble_report(0.25f, 0.75f, HidTransport::Usb, 9, true) == usb2);

    Bytes bt = zeros(78);
    bt[0] = 0x31;
    bt[1] = 0x30;  // sequence 3
    bt[2] = 0x10;
    bt[3] = 0x03;
    bt[5] = 191;
    bt[6] = 64;
    bt[74] = 0xfc;  // zlib.crc32(b"\xa2" + bytes[0..74)) = 0x1cf444fc
    bt[75] = 0x44;
    bt[76] = 0xf4;
    bt[77] = 0x1c;
    CHECK(build_dualsense_rumble_report(0.25f, 0.75f, HidTransport::Bluetooth, 3, false) == bt);

    const Bytes bt2 = build_dualsense_rumble_report(0.25f, 0.75f, HidTransport::Bluetooth, 3, true);
    CHECK(bt2[3] == 0x02);
    CHECK(bt2[41] == 0x04);
    CHECK(crc_at(bt2, 74) == 0x1d07d9d8u);

    CHECK(build_dualsense_rumble_report(0, 0, HidTransport::Bluetooth, 0, false)[1] == 0x00);
    CHECK(crc_at(build_dualsense_rumble_report(0, 0, HidTransport::Bluetooth, 0, false), 74) == 0x962e64ccu);
    CHECK(build_dualsense_rumble_report(0, 0, HidTransport::Bluetooth, 17, false)[1] == 0x10);  // 17 & 15 = 1
}

TEST_CASE("DualSense input: USB report 0x01 and Bluetooth report 0x31; Bluetooth's simple 0x01 is not decoded") {
    Bytes usb = zeros(64);
    usb[0] = 0x01;
    usb[1] = 0x80;
    usb[2] = 0x80;
    usb[3] = 0xFF;  // RX full right
    usb[4] = 0xFF;  // RY full down
    usb[5] = 64;    // L2
    usb[6] = 255;   // R2
    usb[7] = 0x5a;  // a counter
    usb[8] = 0x54;  // hat 4 (down), Square, Circle
    usb[9] = 0x0A;  // R1, R2 (digital: the analog value is what the engine reads)
    usb[10] = 0x01; // PS
    GamepadState s;
    REQUIRE(decode_dualsense_report(usb, HidTransport::Usb, s));
    CHECK(axis(s, GamepadAxis::RightX) == doctest::Approx(1.0f));
    CHECK(axis(s, GamepadAxis::RightY) == doctest::Approx(-1.0f));
    CHECK(axis(s, GamepadAxis::LeftX) == doctest::Approx(0.0f));
    CHECK(axis(s, GamepadAxis::LeftTrigger) == doctest::Approx(64.0f / 255.0f));
    CHECK(axis(s, GamepadAxis::RightTrigger) == doctest::Approx(1.0f));
    CHECK(button(s, GamepadButton::DpadDown));
    CHECK(button(s, GamepadButton::X));
    CHECK(button(s, GamepadButton::B));
    CHECK_FALSE(button(s, GamepadButton::A));
    CHECK(button(s, GamepadButton::RightShoulder));
    CHECK(button(s, GamepadButton::Guide));

    GamepadState untouched;
    CHECK_FALSE(decode_dualsense_report(usb, HidTransport::Bluetooth, untouched));  // the simple report

    Bytes bt = zeros(78);
    bt[0] = 0x31;
    bt[1] = 0x01;
    bt[2] = 0x80;
    bt[3] = 0x80;
    bt[4] = 0x80;
    bt[5] = 0x80;
    bt[9] = 0x18;  // hat 8 (centred), Square
    bt[10] = 0x20; // Options
    GamepadState b;
    REQUIRE(decode_dualsense_report(bt, HidTransport::Bluetooth, b));
    CHECK(button(b, GamepadButton::X));
    CHECK(button(b, GamepadButton::Start));
    CHECK_FALSE(button(b, GamepadButton::DpadUp));
    CHECK_FALSE(button(b, GamepadButton::DpadLeft));
    CHECK(axis(b, GamepadAxis::LeftX) == doctest::Approx(0.0f));

    CHECK_FALSE(decode_dualsense_report(Bytes{0x31, 0, 0x80}, HidTransport::Bluetooth, untouched));
    CHECK_FALSE(untouched.buttons[0]);
}

TEST_CASE("DualSense firmware report: the update version picks the vibration") {
    Bytes fw = zeros(64);
    fw[0] = kDualSenseFeatureFirmware;
    fw[44] = 0x15;
    fw[45] = 0x02;
    CHECK(dualsense_update_version(fw) == std::optional<std::uint16_t>(0x0215));
    fw[0] = 0x05;
    CHECK_FALSE(dualsense_update_version(fw).has_value());
    CHECK_FALSE(dualsense_update_version(Bytes{0x20, 0, 0}).has_value());
}

TEST_CASE("DualSense driver: over USB it reads the firmware, then rumbles with the vibration it has") {
    auto newer = make_hid_pad_driver(kHidVendorSony, kHidProductDualSense, HidTransport::Usb);
    REQUIRE(newer);
    CHECK_FALSE(newer->setup_done());
    std::optional<HidPadRequest> rq = newer->next_request(0);
    REQUIRE(rq.has_value());
    CHECK(rq->kind == HidPadRequest::Kind::GetFeature);
    CHECK(rq->bytes.size() == kDualSenseFeatureFirmwareSize);
    CHECK(rq->bytes[0] == kDualSenseFeatureFirmware);
    CHECK_FALSE(newer->next_request(1).has_value());  // one at a time: waiting for the answer
    Bytes fw = zeros(64);
    fw[0] = kDualSenseFeatureFirmware;
    fw[44] = 0x30;
    fw[45] = 0x02;  // 0x0230
    newer->request_done(true, fw);
    CHECK(newer->setup_done());
    CHECK_FALSE(newer->next_request(2).has_value());
    CHECK(newer->rumble_report(0.25f, 0.75f) == build_dualsense_rumble_report(0.25f, 0.75f, HidTransport::Usb, 0, true));

    auto older = make_hid_pad_driver(kHidVendorSony, kHidProductDualSense, HidTransport::Usb);
    REQUIRE(older->next_request(0).has_value());
    fw[44] = 0x14;  // 0x0214
    older->request_done(true, fw);
    CHECK(older->rumble_report(1, 0) == build_dualsense_rumble_report(1, 0, HidTransport::Usb, 0, false));

    // The pad went away during the read (the OS failed it): the set-up ends, with the vibration every firmware has.
    auto lost = make_hid_pad_driver(kHidVendorSony, kHidProductDualSense, HidTransport::Usb);
    REQUIRE(lost->next_request(0).has_value());
    lost->request_done(false, {});
    CHECK(lost->setup_done());
    CHECK_FALSE(lost->next_request(1).has_value());
    CHECK(lost->rumble_report(1, 1)[1] == 0x03);
}

TEST_CASE("DualSense driver: over Bluetooth feature 0x05 then the firmware, and the sequence advances per report") {
    auto d = make_hid_pad_driver(kHidVendorSony, kHidProductDualSense, HidTransport::Bluetooth);
    REQUIRE(d);
    std::optional<HidPadRequest> first = d->next_request(0);
    REQUIRE(first.has_value());
    CHECK(first->bytes[0] == kDualSenseFeatureCalibration);
    CHECK(first->bytes.size() == kDualSenseFeatureCalibrationSize);
    d->request_done(true, first->bytes);
    std::optional<HidPadRequest> second = d->next_request(1);
    REQUIRE(second.has_value());
    CHECK(second->bytes[0] == kDualSenseFeatureFirmware);
    d->request_done(false, {});
    CHECK(d->setup_done());
    CHECK(d->rumble_report(0, 0)[1] == 0x00);
    CHECK(d->rumble_report(0, 0)[1] == 0x10);
    CHECK(d->rumble_report(0.5f, 0.5f) == build_dualsense_rumble_report(0.5f, 0.5f, HidTransport::Bluetooth, 2, false));

    // The Edge has vibration v2 always: no firmware read over USB.
    auto edge = make_hid_pad_driver(kHidVendorSony, kHidProductDualSenseEdge, HidTransport::Usb);
    REQUIRE(edge);
    CHECK(edge->setup_done());
    CHECK_FALSE(edge->next_request(0).has_value());
    CHECK(edge->rumble_report(1, 1) == build_dualsense_rumble_report(1, 1, HidTransport::Usb, 0, true));

    // A report 0x31 says Bluetooth whatever the path said.
    auto guessed = make_hid_pad_driver(kHidVendorSony, kHidProductDualSenseEdge, HidTransport::Usb);
    GamepadState s;
    CHECK(guessed->read_report(Bytes{0x31, 0x00}, s));  // too short to decode, still the driver's
    CHECK(guessed->transport() == HidTransport::Bluetooth);
}

// ---------------------------------------------------------------------------
// Switch Pro
// ---------------------------------------------------------------------------
TEST_CASE("Switch Pro HD rumble: amplitude codes, fixed frequencies, neutral at 0") {
    CHECK(switch_rumble_amplitude(0.0f) == 0);
    CHECK(switch_rumble_amplitude(-0.5f) == 0);
    CHECK(switch_rumble_amplitude(std::numeric_limits<float>::quiet_NaN()) == 0);
    CHECK(switch_rumble_amplitude(0.001f) == 1);  // above 0: at least the weakest level
    CHECK(switch_rumble_amplitude(0.05f) == 7);
    CHECK(switch_rumble_amplitude(0.1f) == 14);
    CHECK(switch_rumble_amplitude(0.15f) == 22);
    CHECK(switch_rumble_amplitude(0.2f) == 28);
    CHECK(switch_rumble_amplitude(0.25f) == 36);
    CHECK(switch_rumble_amplitude(0.5f) == 68);
    CHECK(switch_rumble_amplitude(0.75f) == 87);
    CHECK(switch_rumble_amplitude(1.0f) == 100);
    CHECK(switch_rumble_amplitude(2.0f) == 100);
    for (int i = 1; i <= 100; ++i)  // monotonic
        CHECK(switch_rumble_amplitude(float(i) / 100.0f) >= switch_rumble_amplitude(float(i - 1) / 100.0f));

    using Hd = std::array<std::uint8_t, 4>;
    CHECK(switch_hd_rumble(0, 0) == Hd{0x00, 0x01, 0x40, 0x40});   // neutral: 320 Hz and 160 Hz, both silent
    CHECK(switch_hd_rumble(1, 1) == Hd{0x00, 0xC9, 0x40, 0x72});   // code 100 on both bands
    CHECK(switch_hd_rumble(1, 0) == Hd{0x00, 0x01, 0x40, 0x72});
    CHECK(switch_hd_rumble(0, 1) == Hd{0x00, 0xC9, 0x40, 0x40});
    CHECK(switch_hd_rumble(0.5f, 0.25f) == Hd{0x00, 0x49, 0x40, 0x62});  // low code 68, high code 36
    CHECK(switch_hd_rumble(0.1f, 0) == Hd{0x00, 0x01, 0x40, 0x47});      // low code 14
    CHECK(switch_hd_rumble(0.05f, 0) == Hd{0x00, 0x01, 0xC0, 0x43});     // low code 7: odd, the half step in [2]
}

TEST_CASE("Switch Pro output: rumble 0x10, subcommand 0x01 and the USB command 0x80, byte by byte") {
    Bytes rumble = zeros(64);
    rumble[0] = 0x10;
    rumble[1] = 0x0B;
    const std::uint8_t hd[4] = {0x00, 0x49, 0x40, 0x62};
    for (int i = 0; i < 4; ++i) rumble[size_t(2 + i)] = rumble[size_t(6 + i)] = hd[i];
    CHECK(build_switch_rumble_report(0.5f, 0.25f, HidTransport::Usb, 0x1B) == rumble);  // counter & 15
    Bytes rumbleBt(rumble.begin(), rumble.begin() + 49);
    CHECK(build_switch_rumble_report(0.5f, 0.25f, HidTransport::Bluetooth, 0x0B) == rumbleBt);
    const Bytes stop = build_switch_rumble_report(0, 0, HidTransport::Usb, 0);
    CHECK(Bytes(stop.begin() + 2, stop.begin() + 10) == Bytes{0x00, 0x01, 0x40, 0x40, 0x00, 0x01, 0x40, 0x40});

    Bytes sub = zeros(49);
    sub[0] = 0x01;
    sub[1] = 0x02;
    const std::uint8_t neutral[8] = {0x00, 0x01, 0x40, 0x40, 0x00, 0x01, 0x40, 0x40};
    for (int i = 0; i < 8; ++i) sub[size_t(2 + i)] = neutral[i];
    sub[10] = 0x03;
    sub[11] = 0x30;
    const std::uint8_t full[1] = {kSwitchInputModeFull};
    CHECK(build_switch_subcommand(2, HidTransport::Bluetooth, kSwitchSubcommandInputMode, full) == sub);
    CHECK(build_switch_subcommand(2, HidTransport::Usb, kSwitchSubcommandInputMode, full).size() == 64);

    Bytes usb = zeros(64);
    usb[0] = 0x80;
    usb[1] = 0x02;
    CHECK(build_switch_usb_command(kSwitchUsbHandshake) == usb);
}

TEST_CASE("Switch Pro input: the full report 0x30, positional buttons, 12-bit sticks") {
    Bytes r = zeros(64);
    r[0] = 0x30;
    r[3] = 0x84;  // printed B (bottom), ZR
    r[4] = 0x12;  // Plus, Home
    r[5] = 0x42;  // Up, L
    // Left stick (2048 + 1400, 2048): full right, centred. Right stick (2048 - 1400, 4095): full left, full up.
    r[6] = 0x78;
    r[7] = 0x0D;
    r[8] = 0x80;
    r[9] = 0x88;
    r[10] = 0xF2;
    r[11] = 0xFF;
    GamepadState s;
    REQUIRE(decode_switch_pro_report(r, s));
    CHECK(button(s, GamepadButton::A));
    CHECK_FALSE(button(s, GamepadButton::B));
    CHECK(axis(s, GamepadAxis::RightTrigger) == 1.0f);
    CHECK(axis(s, GamepadAxis::LeftTrigger) == 0.0f);
    CHECK(button(s, GamepadButton::Start));
    CHECK(button(s, GamepadButton::Guide));
    CHECK_FALSE(button(s, GamepadButton::Back));
    CHECK(button(s, GamepadButton::DpadUp));
    CHECK(button(s, GamepadButton::LeftShoulder));
    CHECK(axis(s, GamepadAxis::LeftX) == doctest::Approx(1.0f));
    CHECK(axis(s, GamepadAxis::LeftY) == doctest::Approx(0.0f));
    CHECK(axis(s, GamepadAxis::RightX) == doctest::Approx(-1.0f));
    CHECK(axis(s, GamepadAxis::RightY) == doctest::Approx(1.0f));  // clamped; +Y up as the pad sends it

    Bytes faces = zeros(12);
    faces[0] = 0x21;  // a subcommand reply carries the state too
    faces[3] = 0x0B;  // printed Y, X, A
    faces[4] = 0x0D;  // Minus, both stick clicks
    faces[5] = 0x8D;  // Down, Right, Left, ZL
    GamepadState f;
    REQUIRE(decode_switch_pro_report(faces, f));
    CHECK(button(f, GamepadButton::X));
    CHECK(button(f, GamepadButton::Y));
    CHECK(button(f, GamepadButton::B));
    CHECK_FALSE(button(f, GamepadButton::A));
    CHECK(button(f, GamepadButton::Back));
    CHECK(button(f, GamepadButton::LeftThumb));
    CHECK(button(f, GamepadButton::RightThumb));
    CHECK(button(f, GamepadButton::DpadDown));
    CHECK(button(f, GamepadButton::DpadRight));
    CHECK(button(f, GamepadButton::DpadLeft));
    CHECK(axis(f, GamepadAxis::LeftTrigger) == 1.0f);
    CHECK(axis(f, GamepadAxis::LeftX) == doctest::Approx(-1.0f));  // raw 0: clamped

    GamepadState untouched;
    CHECK_FALSE(decode_switch_pro_report(Bytes{0x3F, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, untouched));  // simple report
    CHECK_FALSE(decode_switch_pro_report(Bytes{0x30, 0, 0}, untouched));
    CHECK_FALSE(untouched.buttons[0]);
}

namespace {

Bytes reply_81(std::uint8_t command) { return Bytes{0x81, command, 0, 0}; }
Bytes reply_21(std::uint8_t subcommand) {
    Bytes r = zeros(49);
    r[0] = 0x21;
    r[13] = 0x80;
    r[14] = subcommand;
    return r;
}

}  // namespace

TEST_CASE("Switch Pro driver: the USB handshake, the subcommands, a reply that does not come") {
    auto d = make_hid_pad_driver(kHidVendorNintendo, kHidProductSwitchPro, HidTransport::Usb);
    REQUIRE(d);
    CHECK(d->rumble_support().can);
    CHECK(d->rumble_refresh_ms() == kSwitchRumbleRefreshMs);
    GamepadState s;

    // The USB bridge: 0x80 0x02, 0x80 0x03, 0x80 0x02, each waiting for its 0x81 reply, then 0x80 0x04 (no reply).
    const std::uint8_t commands[3] = {kSwitchUsbHandshake, kSwitchUsbBaud3M, kSwitchUsbHandshake};
    std::uint64_t now = 0;
    for (std::uint8_t command : commands) {
        CHECK_FALSE(d->setup_done());
        std::optional<HidPadRequest> rq = d->next_request(now);
        REQUIRE(rq.has_value());
        CHECK(rq->kind == HidPadRequest::Kind::Write);
        CHECK(rq->bytes == build_switch_usb_command(command));
        CHECK_FALSE(d->next_request(now).has_value());  // not written yet
        d->request_done(true, {});
        CHECK_FALSE(d->next_request(now + 10).has_value());  // waiting for the reply
        CHECK(d->read_report(reply_81(0x7f), s));             // another command's reply: still waiting
        CHECK_FALSE(d->next_request(now + 20).has_value());
        CHECK(d->read_report(reply_81(command), s));          // the driver's, with no input in it
        now += 30;
    }
    std::optional<HidPadRequest> forceHid = d->next_request(now);
    REQUIRE(forceHid.has_value());
    CHECK(forceHid->bytes == build_switch_usb_command(kSwitchUsbForceHid));
    d->request_done(true, {});

    // Subcommand 0x03 0x30: no reply within 300 ms, so it goes again with the next packet counter.
    const std::uint8_t full[1] = {kSwitchInputModeFull};
    std::optional<HidPadRequest> mode = d->next_request(now);
    REQUIRE(mode.has_value());
    CHECK(mode->bytes == build_switch_subcommand(0, HidTransport::Usb, kSwitchSubcommandInputMode, full));
    d->request_done(true, {});
    CHECK_FALSE(d->next_request(now + kSwitchReplyTimeoutMs - 1).has_value());
    now += kSwitchReplyTimeoutMs;
    std::optional<HidPadRequest> again = d->next_request(now);
    REQUIRE(again.has_value());
    CHECK(again->bytes == build_switch_subcommand(1, HidTransport::Usb, kSwitchSubcommandInputMode, full));
    d->request_done(true, {});
    CHECK(d->read_report(reply_21(kSwitchSubcommandVibration), s));  // not the reply it waits for
    CHECK_FALSE(d->next_request(now + 1).has_value());
    CHECK(d->read_report(reply_21(kSwitchSubcommandInputMode), s));

    // Subcommand 0x48 0x01: it never answers; tried kSwitchStepTries times, then skipped.
    const std::uint8_t on[1] = {0x01};
    for (unsigned attempt = 0; attempt < kSwitchStepTries; ++attempt) {
        std::optional<HidPadRequest> vib = d->next_request(now);
        REQUIRE(vib.has_value());
        CHECK(vib->bytes ==
              build_switch_subcommand(std::uint8_t(2 + attempt), HidTransport::Usb, kSwitchSubcommandVibration, on));
        d->request_done(true, {});
        CHECK_FALSE(d->setup_done());
        now += kSwitchReplyTimeoutMs;
    }
    CHECK_FALSE(d->next_request(now).has_value());
    CHECK(d->setup_done());
    // The packet counter goes on from the subcommands.
    CHECK(d->rumble_report(1, 1) == build_switch_rumble_report(1, 1, HidTransport::Usb, 5));
    CHECK(d->rumble_report(0, 0) == build_switch_rumble_report(0, 0, HidTransport::Usb, 6));
}

TEST_CASE("Switch Pro driver: over Bluetooth only the subcommands; failed writes do not stall the set-up") {
    auto d = make_hid_pad_driver(kHidVendorNintendo, kHidProductSwitchPro, HidTransport::Bluetooth);
    REQUIRE(d);
    GamepadState s;
    std::optional<HidPadRequest> mode = d->next_request(0);
    REQUIRE(mode.has_value());
    CHECK(mode->bytes.size() == 49);
    CHECK(mode->bytes[0] == 0x01);
    CHECK(mode->bytes[10] == kSwitchSubcommandInputMode);
    CHECK(mode->bytes[11] == kSwitchInputModeFull);
    d->request_done(true, {});
    CHECK(d->read_report(reply_21(kSwitchSubcommandInputMode), s));
    std::optional<HidPadRequest> vib = d->next_request(1);
    REQUIRE(vib.has_value());
    CHECK(vib->bytes[1] == 1);
    CHECK(vib->bytes[10] == kSwitchSubcommandVibration);
    CHECK(vib->bytes[11] == 0x01);
    d->request_done(true, {});
    CHECK(d->read_report(reply_21(kSwitchSubcommandVibration), s));
    CHECK_FALSE(d->next_request(2).has_value());
    CHECK(d->setup_done());
    CHECK(d->rumble_report(0.5f, 0.25f) == build_switch_rumble_report(0.5f, 0.25f, HidTransport::Bluetooth, 2));

    // A pad that went away: every write fails and nothing answers. The set-up still ends after its tries.
    auto lost = make_hid_pad_driver(kHidVendorNintendo, kHidProductSwitchPro, HidTransport::Bluetooth);
    std::uint64_t now = 0;
    int sent = 0;
    for (int guard = 0; guard < 100 && !lost->setup_done(); ++guard) {
        if (lost->next_request(now)) {
            ++sent;
            lost->request_done(false, {});
        }
        now += 100;
    }
    CHECK(lost->setup_done());
    CHECK(sent == int(2 * kSwitchStepTries));

    // The simple report is the generic path's.
    GamepadState g;
    CHECK_FALSE(d->read_report(Bytes{0x3F, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, g));
}
