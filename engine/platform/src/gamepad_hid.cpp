// Windows HID gamepads, the platform-neutral half (see fa/platform/gamepad_hid.h). No Windows header here: the tests run it
// on every OS; gamepad_win32.cpp is the OS glue.
#include "fa/platform/gamepad_hid.h"

#include <algorithm>
#include <cctype>
#include <utility>

namespace fa {

// ---------------------------------------------------------------------------
// Layout
// ---------------------------------------------------------------------------
namespace {

// DirectInput's axis order (DIJOFS_X .. DIJOFS_RZ, then the sliders): the rank of a Generic Desktop usage, -1 for one that
// is not an axis.
int axis_rank(std::uint16_t usage) {
    if (usage >= kHidUsageX && usage <= kHidUsageRz) return usage - kHidUsageX;
    if (usage >= kHidUsageSlider && usage <= kHidUsageWheel) return 6;  // sliders after the six axes, in usage order
    return -1;
}

constexpr size_t kMaxSliders = 2;  // DIJOYSTATE2 has two

HidLayoutValue layout_value(const HidValueCap& cap, std::uint16_t usage) {
    return {usage, cap.bitSize, cap.logicalMin, cap.logicalMax};
}

}  // namespace

HidLayout make_hid_layout(std::span<const HidButtonCap> buttons, std::span<const HidValueCap> values) {
    HidLayout layout;
    for (const HidButtonCap& cap : buttons) {
        if (cap.usagePage != kHidPageButton || cap.usageMax < cap.usageMin) continue;
        for (unsigned u = cap.usageMin; u <= cap.usageMax && layout.buttons.size() < 4096; ++u)
            layout.buttons.push_back(std::uint16_t(u));
    }
    std::sort(layout.buttons.begin(), layout.buttons.end());
    layout.buttons.erase(std::unique(layout.buttons.begin(), layout.buttons.end()), layout.buttons.end());
    if (layout.buttons.size() > size_t(kGamepadMaxRawButtons)) layout.buttons.resize(size_t(kGamepadMaxRawButtons));

    std::vector<HidLayoutValue> axes;
    for (const HidValueCap& cap : values) {
        // An array of values (one usage, several counts) is not an axis; a value wider than 32 bits is not read either.
        if (cap.usagePage != kHidPageGenericDesktop || cap.usageMax < cap.usageMin || cap.bitSize == 0 ||
            cap.bitSize > 32 || (cap.usageMin == cap.usageMax && cap.reportCount > 1))
            continue;
        for (unsigned u = cap.usageMin; u <= cap.usageMax; ++u) {
            const std::uint16_t usage = std::uint16_t(u);
            const auto known = [&](const std::vector<HidLayoutValue>& list) {
                return std::any_of(list.begin(), list.end(), [&](const HidLayoutValue& v) { return v.usage == usage; });
            };
            if (usage == kHidUsageHatSwitch) {
                if (layout.hats.empty()) layout.hats.push_back(layout_value(cap, usage));
            } else if (axis_rank(usage) >= 0 && !known(axes)) {
                axes.push_back(layout_value(cap, usage));
            }
        }
    }
    std::stable_sort(axes.begin(), axes.end(), [](const HidLayoutValue& a, const HidLayoutValue& b) {
        return axis_rank(a.usage) != axis_rank(b.usage) ? axis_rank(a.usage) < axis_rank(b.usage) : a.usage < b.usage;
    });
    size_t sliders = 0;
    for (const HidLayoutValue& a : axes) {
        if (axis_rank(a.usage) == 6 && ++sliders > kMaxSliders) continue;
        if (layout.axes.size() < size_t(kGamepadMaxRawAxes)) layout.axes.push_back(a);
    }
    return layout;
}

// ---------------------------------------------------------------------------
// Values
// ---------------------------------------------------------------------------
namespace {

struct Range {
    std::int64_t value = 0, min = 0, max = 0;
};

// The raw bits and the logical range as signed 64-bit numbers (see hid_axis_value()).
Range read_range(std::uint32_t raw, const HidLayoutValue& v) {
    const unsigned bits = std::clamp<unsigned>(v.bitSize, 1u, 32u);
    const std::uint64_t mask = bits >= 32 ? 0xffffffffull : ((1ull << bits) - 1ull);
    const std::uint64_t value = std::uint64_t(raw) & mask;
    Range r{std::int64_t(value), v.logicalMin, v.logicalMax};
    if (r.max < r.min) {  // an unsigned maximum written as a negative number: read the range as unsigned
        r.min = std::int64_t(std::uint64_t(std::uint32_t(v.logicalMin)) & mask);
        r.max = std::int64_t(std::uint64_t(std::uint32_t(v.logicalMax)) & mask);
    } else if (r.min < 0 && (value >> (bits - 1)) != 0) {
        r.value = std::int64_t(value) - std::int64_t(mask) - 1;  // sign-extend from `bits` bits
    }
    return r;
}

}  // namespace

float hid_axis_value(std::uint32_t raw, const HidLayoutValue& v) {
    const Range r = read_range(raw, v);
    if (r.max <= r.min) return 0.0f;
    const double t = double(std::clamp(r.value, r.min, r.max) - r.min) / double(r.max - r.min);
    return std::clamp(float(t * 2.0 - 1.0), -1.0f, 1.0f);
}

int hid_hat_mask(std::uint32_t raw, const HidLayoutValue& v) {
    static constexpr int kEight[8] = {1, 1 | 2, 2, 2 | 4, 4, 4 | 8, 8, 8 | 1};
    static constexpr int kFour[4] = {1, 2, 4, 8};
    const Range r = read_range(raw, v);
    const std::int64_t positions = r.max - r.min + 1, i = r.value - r.min;
    if (i < 0) return 0;
    if (positions == 4 && i < 4) return kFour[i];
    if (positions >= 8 && i < 8) return kEight[i];
    return 0;  // the null state (out of range): centred
}

void apply_hid_report(const HidLayout& layout, const HidReport& report, GamepadMapper& mapper) {
    if (report.hasButtons) {
        std::array<bool, size_t(kGamepadMaxRawButtons)> down{};
        for (std::uint16_t usage : report.pressed) {
            const auto it = std::lower_bound(layout.buttons.begin(), layout.buttons.end(), usage);
            if (it != layout.buttons.end() && *it == usage) down[size_t(it - layout.buttons.begin())] = true;
        }
        for (size_t i = 0; i < layout.buttons.size(); ++i) mapper.set_button(int(i), down[i]);
    }
    for (const HidValue& value : report.values) {
        for (size_t i = 0; i < layout.axes.size(); ++i)
            if (layout.axes[i].usage == value.usage) mapper.set_axis(int(i), hid_axis_value(value.raw, layout.axes[i]));
        for (size_t i = 0; i < layout.hats.size(); ++i)
            if (layout.hats[i].usage == value.usage) mapper.set_hat(int(i), hid_hat_mask(value.raw, layout.hats[i]));
    }
}

// ---------------------------------------------------------------------------
// Identity and the default mapping
// ---------------------------------------------------------------------------
GamepadIdentity windows_hid_identity(std::uint16_t vendor, std::uint16_t product, std::string name) {
    GamepadIdentity id;
    id.bus = kHidBusUsb;  // what SDL's DirectInput driver writes for every pad, Bluetooth ones too
    id.vendor = vendor;
    id.product = product;
    id.version = 0;  // likewise: no platform:Windows line carries a version
    id.name = std::move(name);
    return id;
}

GamepadMapping default_hid_gamepad_mapping(const HidLayout& layout) {
    GamepadMapping m;
    m.guid = "00000000000000000000000000000000";
    m.name = "Generic HID gamepad (default layout)";
    auto button = [&](GamepadButton b, size_t raw) {
        if (raw < layout.buttons.size()) m.buttons[size_t(b)] = {GamepadSource::Kind::Button, std::uint8_t(raw)};
    };
    auto axis_index = [&](std::uint16_t usage) -> int {
        for (size_t i = 0; i < layout.axes.size(); ++i)
            if (layout.axes[i].usage == usage) return int(i);
        return -1;
    };
    auto axis = [&](GamepadAxis a, int raw) {
        if (raw >= 0) m.axes[size_t(a)] = {GamepadSource::Kind::Axis, std::uint8_t(raw)};
    };
    button(GamepadButton::A, 0);
    button(GamepadButton::B, 1);
    button(GamepadButton::X, 2);
    button(GamepadButton::Y, 3);
    button(GamepadButton::LeftShoulder, 4);
    button(GamepadButton::RightShoulder, 5);
    button(GamepadButton::Back, 8);
    button(GamepadButton::Start, 9);
    button(GamepadButton::LeftThumb, 10);
    button(GamepadButton::RightThumb, 11);
    button(GamepadButton::Guide, 12);

    axis(GamepadAxis::LeftX, axis_index(kHidUsageX));
    axis(GamepadAxis::LeftY, axis_index(kHidUsageY));
    const int z = axis_index(kHidUsageZ), rz = axis_index(kHidUsageRz);
    const int rx = axis_index(kHidUsageRx), ry = axis_index(kHidUsageRy);
    int leftTrigger = -1, rightTrigger = -1;
    if (z >= 0 && rz >= 0) {
        axis(GamepadAxis::RightX, z);
        axis(GamepadAxis::RightY, rz);
        leftTrigger = rx;
        rightTrigger = ry;
    } else if (rx >= 0 && ry >= 0) {
        axis(GamepadAxis::RightX, rx);
        axis(GamepadAxis::RightY, ry);
        leftTrigger = z;
        rightTrigger = rz;
    }
    if (leftTrigger >= 0 && rightTrigger >= 0) {  // an analog trigger rests at the axis minimum: full range -> 0..1
        axis(GamepadAxis::LeftTrigger, leftTrigger);
        axis(GamepadAxis::RightTrigger, rightTrigger);
    } else if (layout.buttons.size() > 7) {
        m.axes[size_t(GamepadAxis::LeftTrigger)] = {GamepadSource::Kind::Button, 6};
        m.axes[size_t(GamepadAxis::RightTrigger)] = {GamepadSource::Kind::Button, 7};
    }
    if (!layout.hats.empty()) {
        m.buttons[size_t(GamepadButton::DpadUp)] = {GamepadSource::Kind::Hat, 0, 1};
        m.buttons[size_t(GamepadButton::DpadRight)] = {GamepadSource::Kind::Hat, 0, 2};
        m.buttons[size_t(GamepadButton::DpadDown)] = {GamepadSource::Kind::Hat, 0, 4};
        m.buttons[size_t(GamepadButton::DpadLeft)] = {GamepadSource::Kind::Hat, 0, 8};
    }
    return m;
}

bool hid_path_is_xinput(std::string_view devicePath) {
    for (size_t i = 0; i + 3 <= devicePath.size(); ++i)
        if (std::toupper(static_cast<unsigned char>(devicePath[i])) == 'I' &&
            std::toupper(static_cast<unsigned char>(devicePath[i + 1])) == 'G' && devicePath[i + 2] == '_')
            return true;
    return false;
}

HidTransport hid_transport_from_path(std::string_view devicePath) {
    // The Bluetooth HID service classes (classic, then Low Energy's HID over GATT) in the paths the Bluetooth stacks give.
    static constexpr std::string_view kServices[] = {"00001124-0000-1000-8000-00805f9b34fb",
                                                     "00001812-0000-1000-8000-00805f9b34fb"};
    for (std::string_view service : kServices)
        for (size_t i = 0; i + service.size() <= devicePath.size(); ++i) {
            size_t k = 0;
            while (k < service.size() && std::tolower(static_cast<unsigned char>(devicePath[i + k])) == service[k]) ++k;
            if (k == service.size()) return HidTransport::Bluetooth;
        }
    return HidTransport::Usb;
}

// ---------------------------------------------------------------------------
// Slots and probes
// ---------------------------------------------------------------------------
void GamepadSlotTable::add(Key key) {
    if (slot_of(key) >= 0 || std::find(waiting_.begin(), waiting_.end(), key) != waiting_.end()) return;
    waiting_.push_back(key);
}

void GamepadSlotTable::remove(Key key) {
    waiting_.erase(std::remove(waiting_.begin(), waiting_.end(), key), waiting_.end());
    const int slot = slot_of(key);
    if (slot < 0) return;
    owners_[size_t(slot)].reset();
    ++generations_[size_t(slot)];
}

int GamepadSlotTable::assign(const std::function<int(const Key&, std::span<const bool>)>& prefer) {
    int given = 0;
    while (!waiting_.empty()) {
        std::array<bool, kMaxGamepads> occupied{};
        int lowest = -1;
        for (int i = 0; i < kMaxGamepads; ++i) {
            occupied[size_t(i)] = owners_[size_t(i)].has_value();
            if (lowest < 0 && !occupied[size_t(i)]) lowest = i;
        }
        if (lowest < 0) break;  // every index taken: the rest keep waiting
        const Key key = waiting_.front();
        int slot = prefer ? prefer(key, std::span<const bool>(occupied)) : lowest;
        if (slot < 0 || slot >= kMaxGamepads || occupied[size_t(slot)]) slot = lowest;
        owners_[size_t(slot)] = key;
        ++generations_[size_t(slot)];
        waiting_.erase(waiting_.begin());
        ++given;
    }
    return given;
}

int GamepadSlotTable::slot_of(const Key& key) const {
    for (int i = 0; i < kMaxGamepads; ++i)
        if (owners_[size_t(i)] == key) return i;
    return -1;
}

std::optional<GamepadSlotTable::Key> GamepadSlotTable::owner(int slot) const {
    if (slot < 0 || slot >= kMaxGamepads) return std::nullopt;
    return owners_[size_t(slot)];
}

std::uint32_t GamepadSlotTable::generation(int slot) const {
    return slot < 0 || slot >= kMaxGamepads ? 0u : generations_[size_t(slot)];
}

void GamepadProbeSchedule::notify() { notified_ = true; }

bool GamepadProbeSchedule::tick(std::uint64_t nowMs) {
    if (notified_) {
        notified_ = false;
        started_ = true;
        burstEndMs_ = nowMs + kBurstMs;
        lastMs_ = nowMs;
        return true;
    }
    if (!started_ || nowMs < lastMs_) {
        started_ = true;
        lastMs_ = nowMs;
        return true;
    }
    const std::uint64_t every = nowMs < burstEndMs_ ? kBurstEveryMs : kIdleMs;
    if (nowMs - lastMs_ < every) return false;
    lastMs_ = nowMs;
    return true;
}

}  // namespace fa
