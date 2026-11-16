// The HID pads with a driver of their own (fa/platform/gamepad_hid_drivers.h): their byte layouts, their set-up and the
// drivers make_hid_pad_driver() returns. No Windows header: the tests run it on every OS; gamepad_win32.cpp moves the bytes.
#include "fa/platform/gamepad_hid_drivers.h"

#include <algorithm>
#include <cmath>
#include <memory>
#include <utility>

namespace fa {

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------
namespace {

constexpr std::array<std::uint32_t, 256> make_crc_table() {
    std::array<std::uint32_t, 256> t{};
    for (std::uint32_t i = 0; i < 256; ++i) {
        std::uint32_t c = i;
        for (int k = 0; k < 8; ++k) c = (c & 1u) != 0 ? 0xEDB88320u ^ (c >> 1) : c >> 1;
        t[i] = c;
    }
    return t;
}
constexpr std::array<std::uint32_t, 256> kCrcTable = make_crc_table();

void put_le32(std::vector<std::uint8_t>& r, size_t at, std::uint32_t v) {
    for (size_t i = 0; i < 4; ++i) r[at + i] = std::uint8_t((v >> (8 * i)) & 0xffu);
}

// The CRC of a PlayStation Bluetooth report, written into its last 4 bytes.
void seal_playstation_bt(std::vector<std::uint8_t>& r) {
    const size_t body = r.size() - 4;
    put_le32(r, body, playstation_bt_crc(kPsOutputCrcSeed, std::span<const std::uint8_t>(r.data(), body)));
}

void set_button(GamepadState& s, GamepadButton b, bool down) { s.buttons[size_t(b)] = down; }
void set_axis(GamepadState& s, GamepadAxis a, float v) { s.axes[size_t(a)] = v; }

// A PlayStation stick byte (0..255, centre 128) as -1..1.
float stick_byte(std::uint8_t v) { return std::clamp((float(v) - 128.0f) / 127.0f, -1.0f, 1.0f); }

// A hat value (0 up, clockwise, 8 or more centred) onto the four D-pad buttons.
void set_hat(GamepadState& s, unsigned hat) {
    static constexpr std::uint8_t kMask[8] = {1, 1 | 2, 2, 2 | 4, 4, 4 | 8, 8, 8 | 1};  // 1 up, 2 right, 4 down, 8 left
    const unsigned m = hat < 8 ? kMask[hat] : 0u;
    set_button(s, GamepadButton::DpadUp, (m & 1u) != 0);
    set_button(s, GamepadButton::DpadRight, (m & 2u) != 0);
    set_button(s, GamepadButton::DpadDown, (m & 4u) != 0);
    set_button(s, GamepadButton::DpadLeft, (m & 8u) != 0);
}

// The sticks and buttons both PlayStation pads share: p[0..3] the sticks, then the three button bytes b0 b1 b2.
void decode_playstation(const std::uint8_t* p, std::uint8_t b0, std::uint8_t b1, std::uint8_t b2, GamepadState& s) {
    set_axis(s, GamepadAxis::LeftX, stick_byte(p[0]));
    set_axis(s, GamepadAxis::LeftY, -stick_byte(p[1]));  // the pad's +Y is down
    set_axis(s, GamepadAxis::RightX, stick_byte(p[2]));
    set_axis(s, GamepadAxis::RightY, -stick_byte(p[3]));
    set_hat(s, b0 & 0x0fu);
    set_button(s, GamepadButton::X, (b0 & 0x10u) != 0);  // Square
    set_button(s, GamepadButton::A, (b0 & 0x20u) != 0);  // Cross
    set_button(s, GamepadButton::B, (b0 & 0x40u) != 0);  // Circle
    set_button(s, GamepadButton::Y, (b0 & 0x80u) != 0);  // Triangle
    set_button(s, GamepadButton::LeftShoulder, (b1 & 0x01u) != 0);
    set_button(s, GamepadButton::RightShoulder, (b1 & 0x02u) != 0);
    set_button(s, GamepadButton::Back, (b1 & 0x10u) != 0);   // Share / Create
    set_button(s, GamepadButton::Start, (b1 & 0x20u) != 0);  // Options
    set_button(s, GamepadButton::LeftThumb, (b1 & 0x40u) != 0);
    set_button(s, GamepadButton::RightThumb, (b1 & 0x80u) != 0);
    set_button(s, GamepadButton::Guide, (b2 & 0x01u) != 0);  // PS
}

std::vector<std::uint8_t> feature_request(std::uint8_t id, size_t size) {
    std::vector<std::uint8_t> b(size, 0);
    b[0] = id;
    return b;
}

}  // namespace

std::uint32_t hid_crc32(std::span<const std::uint8_t> data, std::uint32_t crc) {
    crc = ~crc;
    for (std::uint8_t byte : data) crc = kCrcTable[(crc ^ byte) & 0xffu] ^ (crc >> 8);
    return ~crc;
}

std::uint32_t playstation_bt_crc(std::uint8_t seed, std::span<const std::uint8_t> reportWithoutCrc) {
    const std::uint8_t header[1] = {seed};
    return hid_crc32(reportWithoutCrc, hid_crc32(header));
}

std::uint8_t rumble_motor_byte(float strength) {
    if (!(strength > 0.0f)) return 0;  // also NaN
    if (strength >= 1.0f) return 255;
    return std::uint8_t(strength * 255.0f + 0.5f);
}

std::optional<std::vector<std::uint8_t>> fit_hid_output_report(std::span<const std::uint8_t> report, size_t length) {
    if (length == 0) return std::nullopt;
    if (report.size() > length &&
        std::any_of(report.begin() + std::ptrdiff_t(length), report.end(), [](std::uint8_t b) { return b != 0; }))
        return std::nullopt;
    std::vector<std::uint8_t> out(report.begin(), report.begin() + std::ptrdiff_t(std::min(length, report.size())));
    out.resize(length, 0);
    return out;
}

// ---------------------------------------------------------------------------
// DualShock 4
// ---------------------------------------------------------------------------
bool decode_ds4_report(std::span<const std::uint8_t> report, GamepadState& state) {
    size_t at = 0;
    if (!report.empty() && report[0] == 0x01)
        at = 1;
    else if (report.size() >= 2 && report[0] == 0x11 && (report[1] & 0x80u) != 0)
        at = 3;
    else
        return false;
    if (report.size() < at + 9) return false;
    const std::uint8_t* p = report.data() + at;
    decode_playstation(p, p[4], p[5], p[6], state);
    set_axis(state, GamepadAxis::LeftTrigger, float(p[7]) / 255.0f);
    set_axis(state, GamepadAxis::RightTrigger, float(p[8]) / 255.0f);
    return true;
}

std::vector<std::uint8_t> build_ds4_rumble_report(float low, float high, HidTransport transport) {
    if (transport == HidTransport::Usb) {
        std::vector<std::uint8_t> r(32, 0);
        r[0] = 0x05;
        r[1] = 0x01;  // valid: the motors only
        r[4] = rumble_motor_byte(high);
        r[5] = rumble_motor_byte(low);
        return r;
    }
    std::vector<std::uint8_t> r(78, 0);
    r[0] = 0x11;
    r[1] = 0xC4;  // HID data (0x80), CRC (0x40), report every 4 ms
    r[3] = 0x01;  // valid: the motors only
    r[6] = rumble_motor_byte(high);
    r[7] = rumble_motor_byte(low);
    seal_playstation_bt(r);
    return r;
}

// ---------------------------------------------------------------------------
// DualSense
// ---------------------------------------------------------------------------
bool decode_dualsense_report(std::span<const std::uint8_t> report, HidTransport transport, GamepadState& state) {
    size_t at = 0;
    if (!report.empty() && report[0] == 0x01 && transport == HidTransport::Usb)
        at = 1;
    else if (!report.empty() && report[0] == 0x31)
        at = 2;
    else
        return false;
    if (report.size() < at + 10) return false;
    const std::uint8_t* p = report.data() + at;
    decode_playstation(p, p[7], p[8], p[9], state);
    set_axis(state, GamepadAxis::LeftTrigger, float(p[4]) / 255.0f);
    set_axis(state, GamepadAxis::RightTrigger, float(p[5]) / 255.0f);
    return true;
}

std::vector<std::uint8_t> build_dualsense_rumble_report(float low, float high, HidTransport transport, std::uint8_t seq,
                                                        bool vibrationV2) {
    const bool bt = transport == HidTransport::Bluetooth;
    std::vector<std::uint8_t> r(bt ? 78 : 63, 0);
    size_t common = 1;
    if (bt) {
        r[0] = 0x31;
        r[1] = std::uint8_t((seq & 0x0fu) << 4);  // the sequence number in the high nibble, tag 0 in the low one
        r[2] = 0x10;                              // the tag the pad wants
        common = 3;
    } else {
        r[0] = 0x02;
    }
    r[common + 0] = vibrationV2 ? 0x02 : 0x03;  // haptics select (0x02), plus compatible vibration v1 (0x01)
    r[common + 2] = rumble_motor_byte(high);
    r[common + 3] = rumble_motor_byte(low);
    if (vibrationV2) r[common + 38] = 0x04;  // valid flag 2: compatible vibration v2
    if (bt) seal_playstation_bt(r);
    return r;
}

std::optional<std::uint16_t> dualsense_update_version(std::span<const std::uint8_t> firmwareReport) {
    if (firmwareReport.size() < 46 || firmwareReport[0] != kDualSenseFeatureFirmware) return std::nullopt;
    return std::uint16_t(firmwareReport[44] | (firmwareReport[45] << 8));
}

// ---------------------------------------------------------------------------
// Switch Pro
// ---------------------------------------------------------------------------
namespace {

float switch_stick(unsigned raw) {
    return std::clamp(float(int(raw) - kSwitchStickCentre) / float(kSwitchStickRange), -1.0f, 1.0f);
}

constexpr std::uint8_t kSwitchNeutralRumble[4] = {0x00, 0x01, 0x40, 0x40};

size_t switch_packet_size(HidTransport transport) { return transport == HidTransport::Usb ? 64 : 49; }

}  // namespace

bool decode_switch_pro_report(std::span<const std::uint8_t> report, GamepadState& state) {
    if (report.size() < 12) return false;
    if (report[0] != 0x21 && (report[0] < 0x30 || report[0] > 0x33)) return false;
    const std::uint8_t right = report[3], shared = report[4], left = report[5];
    set_button(state, GamepadButton::A, (right & 0x04u) != 0);  // printed B, the bottom one
    set_button(state, GamepadButton::B, (right & 0x08u) != 0);  // printed A, the right one
    set_button(state, GamepadButton::X, (right & 0x01u) != 0);  // printed Y, the left one
    set_button(state, GamepadButton::Y, (right & 0x02u) != 0);  // printed X, the top one
    set_button(state, GamepadButton::RightShoulder, (right & 0x40u) != 0);
    set_axis(state, GamepadAxis::RightTrigger, (right & 0x80u) != 0 ? 1.0f : 0.0f);  // ZR
    set_button(state, GamepadButton::Back, (shared & 0x01u) != 0);                   // Minus
    set_button(state, GamepadButton::Start, (shared & 0x02u) != 0);                  // Plus
    set_button(state, GamepadButton::RightThumb, (shared & 0x04u) != 0);
    set_button(state, GamepadButton::LeftThumb, (shared & 0x08u) != 0);
    set_button(state, GamepadButton::Guide, (shared & 0x10u) != 0);  // Home
    set_button(state, GamepadButton::DpadDown, (left & 0x01u) != 0);
    set_button(state, GamepadButton::DpadUp, (left & 0x02u) != 0);
    set_button(state, GamepadButton::DpadRight, (left & 0x04u) != 0);
    set_button(state, GamepadButton::DpadLeft, (left & 0x08u) != 0);
    set_button(state, GamepadButton::LeftShoulder, (left & 0x40u) != 0);
    set_axis(state, GamepadAxis::LeftTrigger, (left & 0x80u) != 0 ? 1.0f : 0.0f);  // ZL
    const unsigned lx = report[6] | ((report[7] & 0x0fu) << 8), ly = (report[7] >> 4) | (unsigned(report[8]) << 4);
    const unsigned rx = report[9] | ((report[10] & 0x0fu) << 8), ry = (report[10] >> 4) | (unsigned(report[11]) << 4);
    set_axis(state, GamepadAxis::LeftX, switch_stick(lx));
    set_axis(state, GamepadAxis::LeftY, switch_stick(ly));  // the pad's +Y is up already
    set_axis(state, GamepadAxis::RightX, switch_stick(rx));
    set_axis(state, GamepadAxis::RightY, switch_stick(ry));
    return true;
}

// The amplitude codes follow the notes' encoding: above amplitude 0.23, code = log2(a * 8.7) * 32; from 0.12 to 0.23,
// code = log2(a * 17) * 16; below that the notes' table is close to a straight line through 0, here a * 137 (which meets
// the middle formula at 0.12). Rounded to the nearest code; a strength above 0 gets at least code 1.
std::uint8_t switch_rumble_amplitude(float strength) {
    if (!(strength > 0.0f)) return 0;  // also NaN
    const double a = std::min(double(strength), 1.0);
    double code = 0.0;
    if (a > 0.23)
        code = std::log2(a * 8.7) * 32.0;
    else if (a > 0.12)
        code = std::log2(a * 17.0) * 16.0;
    else
        code = a * 137.0;
    return std::uint8_t(std::clamp(std::lround(code), 1L, 100L));
}

std::array<std::uint8_t, 4> switch_hd_rumble(float low, float high) {
    constexpr unsigned kHighFrequency = 0x100;  // 320 Hz: 10 * 2^((0x60 + code / 4) / 32)
    constexpr unsigned kLowFrequency = 0x40;    // 160 Hz: 10 * 2^((0x40 + code) / 32)
    const unsigned highCode = switch_rumble_amplitude(high), lowCode = switch_rumble_amplitude(low);
    const unsigned highAmp = highCode * 2;  // 0..200, even
    const unsigned lowAmp =
        ((lowCode & 1u) != 0 ? 0x8000u : 0u) | (lowCode / 2 + 0x40);  // 9 bits: the half step on top
    return {std::uint8_t(kHighFrequency & 0xffu), std::uint8_t(highAmp | ((kHighFrequency >> 8) & 0x01u)),
            std::uint8_t(kLowFrequency | ((lowAmp >> 8) & 0x80u)), std::uint8_t(lowAmp & 0xffu)};
}

std::vector<std::uint8_t> build_switch_rumble_report(float low, float high, HidTransport transport, std::uint8_t seq) {
    std::vector<std::uint8_t> r(switch_packet_size(transport), 0);
    r[0] = 0x10;
    r[1] = std::uint8_t(seq & 0x0fu);
    const std::array<std::uint8_t, 4> d = switch_hd_rumble(low, high);
    std::copy(d.begin(), d.end(), r.begin() + 2);
    std::copy(d.begin(), d.end(), r.begin() + 6);
    return r;
}

std::vector<std::uint8_t> build_switch_subcommand(std::uint8_t seq, HidTransport transport, std::uint8_t subcommand,
                                                  std::span<const std::uint8_t> args) {
    std::vector<std::uint8_t> r(switch_packet_size(transport), 0);
    r[0] = 0x01;
    r[1] = std::uint8_t(seq & 0x0fu);
    std::copy(std::begin(kSwitchNeutralRumble), std::end(kSwitchNeutralRumble), r.begin() + 2);
    std::copy(std::begin(kSwitchNeutralRumble), std::end(kSwitchNeutralRumble), r.begin() + 6);
    r[10] = subcommand;
    const size_t n = std::min(args.size(), r.size() - 11);
    std::copy(args.begin(), args.begin() + std::ptrdiff_t(n), r.begin() + 11);
    return r;
}

std::vector<std::uint8_t> build_switch_usb_command(std::uint8_t command) {
    std::vector<std::uint8_t> r(64, 0);
    r[0] = 0x80;
    r[1] = command;
    return r;
}

// ---------------------------------------------------------------------------
// The drivers
// ---------------------------------------------------------------------------
namespace {

class Ds4Driver final : public HidPadDriver {
public:
    explicit Ds4Driver(HidTransport transport) : transport_(transport) {}

    bool read_report(std::span<const std::uint8_t> report, GamepadState& state) override {
        if (report.empty()) return false;
        if (report[0] == 0x11) {  // only Bluetooth sends it; one that carries no input is still ours
            transport_ = HidTransport::Bluetooth;
            decode_ds4_report(report, state);
            return true;
        }
        return decode_ds4_report(report, state);  // report 0x01: the same layout over USB and Bluetooth
    }
    GamepadRumbleSupport rumble_support() const override { return {true, {}}; }
    std::optional<HidPadRequest> next_request(std::uint64_t) override {
        if (transport_ != HidTransport::Bluetooth || asked_) return std::nullopt;
        asked_ = true;  // reading it turns report 0x11 on; a failure leaves the simple report, which still works
        return HidPadRequest{HidPadRequest::Kind::GetFeature,
                             feature_request(kDs4FeatureCalibration, kDs4FeatureCalibrationSize)};
    }
    std::vector<std::uint8_t> rumble_report(float low, float high) override {
        return build_ds4_rumble_report(low, high, transport_);
    }
    HidTransport transport() const override { return transport_; }

private:
    HidTransport transport_;
    bool asked_ = false;
};

class DualSenseDriver final : public HidPadDriver {
public:
    DualSenseDriver(HidTransport transport, bool edge) : transport_(transport), v2_(edge), askFirmware_(!edge) {}

    bool read_report(std::span<const std::uint8_t> report, GamepadState& state) override {
        if (report.empty()) return false;
        if (report[0] == 0x31) {  // only Bluetooth sends it
            transport_ = HidTransport::Bluetooth;
            decode_dualsense_report(report, transport_, state);
            return true;
        }
        return decode_dualsense_report(report, transport_, state);
    }
    GamepadRumbleSupport rumble_support() const override { return {true, {}}; }
    std::optional<HidPadRequest> next_request(std::uint64_t) override {
        if (pending_ != Pending::None) return std::nullopt;
        if (transport_ == HidTransport::Bluetooth && !calibrationAsked_) {
            calibrationAsked_ = true;  // reading it turns report 0x31 on
            pending_ = Pending::Calibration;
            return HidPadRequest{HidPadRequest::Kind::GetFeature,
                                 feature_request(kDualSenseFeatureCalibration, kDualSenseFeatureCalibrationSize)};
        }
        if (askFirmware_ && !firmwareAsked_) {
            firmwareAsked_ = true;
            pending_ = Pending::Firmware;
            return HidPadRequest{HidPadRequest::Kind::GetFeature,
                                 feature_request(kDualSenseFeatureFirmware, kDualSenseFeatureFirmwareSize)};
        }
        return std::nullopt;
    }
    void request_done(bool ok, std::span<const std::uint8_t> reply) override {
        if (pending_ == Pending::Firmware) {
            firmwareAnswered_ = true;
            const std::optional<std::uint16_t> version = ok ? dualsense_update_version(reply) : std::nullopt;
            if (version && *version >= kDualSenseVibrationV2Version)
                v2_ = true;  // else (or unknown): v1, which all have
        }
        pending_ = Pending::None;
    }
    bool setup_done() const override { return !askFirmware_ || firmwareAnswered_; }
    std::vector<std::uint8_t> rumble_report(float low, float high) override {
        return build_dualsense_rumble_report(low, high, transport_, seq_++, v2_);
    }
    HidTransport transport() const override { return transport_; }

private:
    enum class Pending : std::uint8_t { None, Calibration, Firmware };
    HidTransport transport_;
    bool v2_;
    bool askFirmware_;
    bool calibrationAsked_ = false, firmwareAsked_ = false, firmwareAnswered_ = false;
    Pending pending_ = Pending::None;
    std::uint8_t seq_ = 0;
};

class SwitchProDriver final : public HidPadDriver {
public:
    explicit SwitchProDriver(HidTransport transport) : transport_(transport) {
        if (transport == HidTransport::Usb) {
            steps_.push_back({kSwitchUsbHandshake, 0, 0, true});
            steps_.push_back({kSwitchUsbBaud3M, 0, 0, true});
            steps_.push_back({kSwitchUsbHandshake, 0, 0, true});
            steps_.push_back({kSwitchUsbForceHid, 0, 0, false});  // no reply: done once written
        }
        steps_.push_back({0, kSwitchSubcommandInputMode, kSwitchInputModeFull, true});
        steps_.push_back({0, kSwitchSubcommandVibration, 0x01, true});
    }

    bool read_report(std::span<const std::uint8_t> report, GamepadState& state) override {
        if (report.empty()) return false;
        const Step* waiting = step_ < steps_.size() && sent_ ? &steps_[step_] : nullptr;
        if (report[0] == 0x81) {  // the USB bridge's reply: no input in it
            if (waiting && waiting->usbCommand != 0 && report.size() >= 2 && report[1] == waiting->usbCommand)
                replied_ = true;
            return true;
        }
        if (report[0] == 0x21 && waiting && waiting->subcommand != 0 && report.size() >= 15 &&
            report[14] == waiting->subcommand)
            replied_ = true;  // acknowledged or not, the pad answered: the next step goes
        return decode_switch_pro_report(report, state);
    }
    GamepadRumbleSupport rumble_support() const override { return {true, {}}; }
    std::optional<HidPadRequest> next_request(std::uint64_t nowMs) override {
        while (step_ < steps_.size()) {
            const Step& st = steps_[step_];
            if (!sent_) {
                sent_ = true;
                written_ = false;
                replied_ = false;
                sentAt_ = nowMs;
                ++tries_;
                if (st.usbCommand != 0)
                    return HidPadRequest{HidPadRequest::Kind::Write, build_switch_usb_command(st.usbCommand)};
                const std::uint8_t args[1] = {st.arg};
                return HidPadRequest{HidPadRequest::Kind::Write,
                                     build_switch_subcommand(counter_++, transport_, st.subcommand, args)};
            }
            if (!written_) return std::nullopt;  // the OS is still sending it
            if (!st.waitReply || replied_) {
                advance();
                continue;
            }
            if (nowMs < sentAt_ + kSwitchReplyTimeoutMs) return std::nullopt;
            if (tries_ < kSwitchStepTries) {
                sent_ = false;  // send it again
                continue;
            }
            advance();  // no reply after every try: go on without it (the pad may still work, e.g. a clone)
        }
        return std::nullopt;
    }
    void request_done(bool, std::span<const std::uint8_t>) override { written_ = true; }
    bool setup_done() const override { return step_ >= steps_.size(); }
    std::vector<std::uint8_t> rumble_report(float low, float high) override {
        return build_switch_rumble_report(low, high, transport_, counter_++);
    }
    unsigned rumble_refresh_ms() const override { return kSwitchRumbleRefreshMs; }
    HidTransport transport() const override { return transport_; }

private:
    struct Step {
        std::uint8_t usbCommand = 0;  // a 0x80 command, or 0 for a subcommand
        std::uint8_t subcommand = 0, arg = 0;
        bool waitReply = true;
    };
    void advance() {
        ++step_;
        sent_ = written_ = replied_ = false;
        tries_ = 0;
    }

    HidTransport transport_;
    std::vector<Step> steps_;
    size_t step_ = 0;
    bool sent_ = false, written_ = false, replied_ = false;
    unsigned tries_ = 0;
    std::uint64_t sentAt_ = 0;
    std::uint8_t counter_ = 0;  // the packet counter (low 4 bits) of subcommands and rumble reports alike
};

}  // namespace

std::unique_ptr<HidPadDriver> make_hid_pad_driver(std::uint16_t vendor, std::uint16_t product, HidTransport transport) {
    if (vendor == kHidVendorSony) {
        switch (product) {
            case kHidProductDualShock4:
            case kHidProductDualShock4v2: return std::make_unique<Ds4Driver>(transport);
            case kHidProductDualShock4Adapter: return std::make_unique<Ds4Driver>(HidTransport::Usb);  // always USB
            case kHidProductDualSense: return std::make_unique<DualSenseDriver>(transport, false);
            case kHidProductDualSenseEdge: return std::make_unique<DualSenseDriver>(transport, true);
            default: break;
        }
    }
    if (vendor == kHidVendorNintendo && product == kHidProductSwitchPro)
        return std::make_unique<SwitchProDriver>(transport);
    return nullptr;
}

}  // namespace fa
