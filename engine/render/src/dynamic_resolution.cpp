#include "fa/render/dynamic_resolution.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <string>
#include <vector>

#include "fa/core/strings.h"

namespace fa::render {

namespace {

double round_to(double v, double scale) { return std::round(v * scale) / scale; }

std::string num(double v) {
    char buf[32];
    std::snprintf(buf, sizeof(buf), "%.3g", v);
    return buf;
}

// The controller's constants (docs/UPSCALING.md, "Dynamic resolution"). Seconds unless noted.
constexpr double kTau = 0.30;      // smoothing time of the measured frame time
constexpr double kDownHold = 0.5;  // the least time between a change and a change down
constexpr double kUpHold = 1.5;    // ... and a change up
constexpr double kDownPersist =
    0.3;  // the smoothed time stays over the band this long before a change down (a one-frame hitch is no cause)
constexpr double kUpPersist = 1.0;                          // ... and under it this long before a change up
constexpr int kMaxDownSteps = kDynamicResolutionSteps / 4;  // a quarter of the range per change
constexpr int kMaxUpSteps = kDynamicResolutionSteps / 8;    // an eighth
constexpr double kProbeFirst = 3.0;                         // quiet time before the first try up (interval measure)
constexpr double kProbeMax = 48.0;
constexpr double kProbeFailWindow = 3.0;  // a drop this soon after a try up means the try failed
constexpr double kProbeKeep = 10.0;       // a try up that holds this long resets the wait
constexpr double kCeilingLife =
    60.0;  // a step whose try failed is not tried again for this long when the wait was 3 s (more with a longer wait)

}  // namespace

Json dynamic_resolution_to_json(const DynamicResolutionSettings& s) {
    Json j = Json::object();
    j["enabled"] = s.enabled;
    j["targetMs"] = round_to(s.targetMs, 1000.0);
    j["minScale"] = round_to(double(s.minScale), 1000.0);
    j["maxScale"] = round_to(double(s.maxScale), 1000.0);
    return j;
}

Result<DynamicResolutionSettings> parse_dynamic_resolution_settings(const Json& j, std::string_view where,
                                                                    const DynamicResolutionSettings& base) {
    if (!j.is_object())
        return make_error(std::string(where) +
                              ": expected an object like {\"enabled\": true, \"targetMs\": 16.7, \"minScale\": 0.6, "
                              "\"maxScale\": 1}, got " +
                              describe_json_value(j),
                          "Every key is optional: enabled, targetMs, minScale, maxScale.");
    static const std::vector<std::string> keys = {"enabled", "targetMs", "minScale", "maxScale"};
    for (auto e = j.begin(); e != j.end(); ++e)
        if (std::find(keys.begin(), keys.end(), e.key()) == keys.end())
            return make_error(std::string(where) + "/" + e.key() + ": '" + e.key() +
                                  "' is not a dynamic resolution setting",
                              did_you_mean(e.key(), keys));
    DynamicResolutionSettings s = base;
    if (auto it = j.find("enabled"); it != j.end()) {
        if (!it->is_boolean())
            return make_error(std::string(where) + "/enabled: expected true or false, got " + describe_json_value(*it),
                              "true turns the controller on; false (the default) draws at the fixed render scale.");
        s.enabled = it->get<bool>();
    }
    if (auto it = j.find("targetMs"); it != j.end() && it->is_null()) {
        s.targetMs = 0.0;  // null: unset, follow the display
    } else if (it != j.end()) {
        const std::string ptr = std::string(where) + "/targetMs";
        if (!it->is_number())
            return make_error(
                ptr + ": expected a number of milliseconds, got " + describe_json_value(*it),
                "Use 33.3 for 30 fps, 16.7 for 60 fps, 8.3 for 120 fps, or 0 to follow the display's refresh rate.");
        const double d = it->get<double>();
        if (!(d == 0.0 || (d >= kDynamicTargetMinMs && d <= kDynamicTargetMaxMs)))
            return make_error(
                ptr + ": " + describe_json_value(*it) + " is outside 4..100 ms (and not 0)",
                "Use 33.3 for 30 fps, 16.7 for 60 fps, 8.3 for 120 fps, or 0 to follow the display's refresh rate.");
        s.targetMs = d;
    }
    auto read_scale = [&](const char* key, float& out) -> Result<void> {
        auto it = j.find(key);
        if (it == j.end()) return Result<void>();
        const std::string ptr = std::string(where) + "/" + key;
        if (!it->is_number())
            return make_error(ptr + ": expected a number from 0.25 to 1, got " + describe_json_value(*it),
                              "A scale is the share of the base render size's width and height: 1 is the full size, "
                              "0.5 a quarter of the pixels.");
        const double d = it->get<double>();
        if (!(d >= double(kDynamicScaleFloor) && d <= double(kDynamicScaleCeiling)))
            return make_error(ptr + ": " + describe_json_value(*it) + " is outside 0.25..1",
                              "Use a number from 0.25 (the renderer's floor) to 1 (the full size).");
        out = float(d);
        return Result<void>();
    };
    if (Result<void> r = read_scale("minScale", s.minScale); !r.ok()) return r.error();
    if (Result<void> r = read_scale("maxScale", s.maxScale); !r.ok()) return r.error();
    if (s.minScale > s.maxScale) {
        const bool minGiven = j.contains("minScale");
        const std::string a = std::string(where) + "/minScale", b = std::string(where) + "/maxScale";
        return make_error(
            (minGiven ? a : b) + ": minScale " + num(double(s.minScale)) + " is above maxScale " +
                num(double(s.maxScale)),
            "The controller moves between the two: set minScale at or below maxScale (for example 0.6 and 1).");
    }
    return s;
}

double dynamic_target_ms(const DynamicResolutionSettings& s, double refreshHz) {
    if (s.targetMs > 0.0) return s.targetMs;
    const double hz = refreshHz >= 20.0 && refreshHz <= 1000.0 ? refreshHz : kDynamicDefaultRefreshHz;
    return 1000.0 / hz;
}

// ------------------------------------------------------------------------------------------- the refresh rate estimate --

void RefreshRateEstimator::reset() { *this = RefreshRateEstimator{}; }

bool RefreshRateEstimator::add(double intervalMs) {
    if (done_) return false;
    ++frames_;
    if (frames_ > kSkipFrames && intervalMs > 0.0 && intervalMs <= kMaxSampleMs) samples_[count_++] = intervalMs;
    if (count_ < kSamples && frames_ < kMaxFrames) return false;
    done_ = true;
    if (count_ == kSamples) {
        double sorted[kSamples];
        std::copy(samples_, samples_ + kSamples, sorted);
        std::sort(sorted, sorted + kSamples);
        const double median = (sorted[kSamples / 2 - 1] + sorted[kSamples / 2]) / 2.0;
        const double hz = 1000.0 / median;
        hz_ = hz >= 20.0 && hz <= 1000.0 ? hz : 0.0;
    }
    return true;
}

// ------------------------------------------------------------------------------------------------------------ the controller --

float DynamicResolutionController::scale_of(int step) const {
    if (step >= kSteps) return s_.maxScale;
    if (step <= 0) return s_.minScale;
    return s_.minScale + (s_.maxScale - s_.minScale) * float(step) / float(kSteps);
}

float DynamicResolutionController::scale() const { return s_.enabled ? scale_of(step_) : 1.0f; }

void DynamicResolutionController::reset() {
    step_ = kSteps;
    ema_ = 0.0;
    seeded_ = false;
    sinceChange_ = 0.0;
    quiet_ = 0.0;
    over_ = 0.0;
    under_ = 0.0;
    probeWait_ = kProbeFirst;
    lastWasProbe_ = false;
    probeCeiling_ = kSteps + 1;
    ceilingAge_ = 0.0;
    ceilingLife_ = kCeilingLife;
    changes_ = 0;
}

void DynamicResolutionController::configure(const DynamicResolutionSettings& s) {
    const bool sameRange = s.minScale == s_.minScale && s.maxScale == s_.maxScale;
    s_ = s;
    if (!sameRange || !s.enabled) reset();
}

bool DynamicResolutionController::update(double sampleMs, double elapsedMs, double targetMs, bool exact) {
    if (!s_.enabled || !(targetMs > 0.0)) return false;
    const double dt = std::isfinite(elapsedMs) && elapsedMs > 0.0 ? elapsedMs / 1000.0 : 0.0;
    sinceChange_ += dt;
    if (probeCeiling_ <= kSteps && (ceilingAge_ += dt) >= ceilingLife_) probeCeiling_ = kSteps + 1;
    if (std::isfinite(sampleMs) && sampleMs >= 0.0) {
        if (!seeded_) {
            ema_ = sampleMs;
            seeded_ = true;
        } else {
            ema_ += (1.0 - std::exp(-dt / kTau)) * (sampleMs - ema_);
        }
    }
    if (!seeded_ || !(s_.maxScale - s_.minScale > 1e-4f)) return false;

    // The band, as shares of the target, and where a move aims (the middle of it, so the new scale is not at an edge). A GPU time is
    // exact: a frame also needs the CPU and the present, so it must stay a little under the target.
    const double low = exact ? 0.80 : 0.90, high = exact ? 0.95 : 1.08, aim = exact ? 0.875 : 0.97;
    const double stepSize = double(s_.maxScale - s_.minScale) / double(kSteps);
    const double now = double(scale_of(step_));

    auto step_for = [&](double wantedScale) {  // the largest step whose scale does not pass `wantedScale`
        return int(std::floor((wantedScale - double(s_.minScale)) / stepSize + 1e-6));
    };
    auto apply = [&](int newStep, bool probe) {
        const double before = double(scale_of(step_)), after = double(scale_of(newStep));
        const bool failedProbe = !probe && lastWasProbe_ && sinceChange_ < kProbeFailWindow && newStep < step_;
        if (failedProbe) {
            probeCeiling_ =
                step_;  // the step that failed: no try reaches it again for a while, so the scale settles under it
            ceilingAge_ = 0.0;
        }
        step_ = newStep;
        ++changes_;
        sinceChange_ = 0.0;
        quiet_ = 0.0;
        over_ = 0.0;
        under_ = 0.0;
        lastWasProbe_ = probe;
        if (failedProbe) {
            probeWait_ = std::min(probeWait_ * 2.0, kProbeMax);
            ceilingLife_ = kCeilingLife * probeWait_ / kProbeFirst;  // twice as long at each failure in a row
        }
        // The cost follows the picture's area: what was measured at the old scale predicts the new one, so the next frames start from it.
        if (!probe && before > 0.0) ema_ *= (after * after) / (before * before);
    };

    if (ema_ > high * targetMs) {
        quiet_ = 0.0;
        under_ = 0.0;
        over_ += dt;
        if (step_ > 0 && sinceChange_ >= kDownHold && over_ >= kDownPersist) {
            const double wanted = now * std::sqrt(aim * targetMs / ema_);
            const int to = std::clamp(std::min(step_for(wanted), step_ - 1), std::max(step_ - kMaxDownSteps, 0), step_);
            if (to < step_) {
                apply(to, false);
                return true;
            }
        }
        return false;
    }
    if (ema_ < low * targetMs) {
        over_ = 0.0;
        under_ += dt;
        if (step_ < kSteps && sinceChange_ >= kUpHold && under_ >= kUpPersist) {
            const double wanted = now * std::sqrt(aim * targetMs / std::max(ema_, 1e-3));
            const int to = std::min({step_for(wanted), step_ + kMaxUpSteps, kSteps});
            if (to > step_) {
                if (lastWasProbe_ && sinceChange_ >= kProbeKeep) probeWait_ = kProbeFirst;
                apply(to, false);
                return true;
            }
        }
        return false;
    }
    over_ = 0.0;
    under_ = 0.0;
    // Inside the band. With the GPU time there is nothing to learn here. With the time between frames the headroom is hidden (vsync pins it at
    // the refresh rate), so after a quiet time the controller tries one step up.
    if (lastWasProbe_ && sinceChange_ >= kProbeKeep) {
        probeWait_ = kProbeFirst;  // the try held: the next one need not wait long
        lastWasProbe_ = false;
    }
    if (!exact && step_ + 1 < std::min(kSteps + 1, probeCeiling_)) {
        quiet_ += dt;
        if (quiet_ >= probeWait_ && sinceChange_ >= kUpHold) {
            apply(step_ + 1, true);
            return true;
        }
    }
    return false;
}

}  // namespace fa::render
