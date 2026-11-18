// Transient screen effects (screen_fx.h): the options, the live state and its clock. The drawing is fa_render's (post_fx.cpp).
#include "fa/scene/screen_fx.h"

#include <algorithm>
#include <cmath>
#include <format>

#include "fa/scene/components.h"
#include "fa/scene/feel.h"
#include "fa/scene/world.h"

namespace fa {

namespace {

bool finite(float v) { return std::isfinite(v); }

Result<void> bad(ScreenFxKind kind, const std::string& what, const std::string& hint = {}) {
    return make_error(std::format("{}: {}", screen_fx_action_name(kind), what), hint);
}

// The ramp a heat haze fades in and out with at its ends.
constexpr float kHazeRamp = 0.15f;

}  // namespace

std::string_view screen_fx_action_name(ScreenFxKind kind) {
    switch (kind) {
        case ScreenFxKind::Shockwave: return "shockwave";
        case ScreenFxKind::HeatHaze: return "heatHaze";
        case ScreenFxKind::RadialBlur: return "radialBlur";
        case ScreenFxKind::Flash: return "screenFlash";
        case ScreenFxKind::Fade: return "fade";
    }
    return "shockwave";
}

bool screen_fx_kind_from_action(std::string_view name, ScreenFxKind& out) {
    for (int i = 0; i < kScreenFxKindCount; ++i)
        if (screen_fx_action_name(ScreenFxKind(i)) == name) {
            out = ScreenFxKind(i);
            return true;
        }
    return false;
}

ScreenFxOptions screen_fx_defaults(ScreenFxKind kind) {
    ScreenFxOptions o;
    o.kind = kind;
    switch (kind) {
        case ScreenFxKind::Shockwave: break;  // the member defaults are the shockwave's
        case ScreenFxKind::HeatHaze:
            o.duration = 2.0f;
            o.strength = 0.004f;
            break;
        case ScreenFxKind::RadialBlur: o.duration = 0.35f; break;
        case ScreenFxKind::Flash:
            o.duration = 0.15f;
            o.strength = 1.0f;
            break;
        case ScreenFxKind::Fade:
            o.duration = 0.5f;
            o.color = Color{0, 0, 0, 1};
            break;
    }
    return o;
}

Result<void> screen_fx_check(const ScreenFxOptions& o) {
    const ScreenFxKind k = o.kind;
    auto range = [&](const char* name, float v, float lo, float hi, const char* hint = "") -> Result<void> {
        if (!finite(v) || v < lo || v > hi)
            return bad(k, std::format("{} must be a number from {} to {}, got {}", name, lo, hi, v), hint);
        return {};
    };
    if (k == ScreenFxKind::Fade) {
        if (auto r = range("duration", o.duration, 0.0f, 600.0f, "Seconds; 0 is instant."); !r.ok()) return r;
    } else {
        const float hi = k == ScreenFxKind::HeatHaze ? 600.0f : 60.0f;
        const float lo = k == ScreenFxKind::Shockwave || k == ScreenFxKind::HeatHaze ? 0.05f : 0.01f;
        if (auto r = range("duration", o.duration, lo, hi, "Seconds, not milliseconds."); !r.ok()) return r;
    }
    if (o.atWorld) {
        if (!finite(o.world.x) || !finite(o.world.y) || !finite(o.world.z))
            return bad(k, "world must be a point [x, y] or [x, y, z] of finite numbers");
    } else if (!finite(o.screen.x) || !finite(o.screen.y) || std::fabs(o.screen.x) > 10.0f ||
               std::fabs(o.screen.y) > 10.0f) {
        return bad(k, "screen must be [x, y], fractions of the camera's rectangle (0.5, 0.5 is the middle)",
                   "A point outside 0..1 is allowed (a centre off the screen) but not further than 10.");
    }
    switch (k) {
        case ScreenFxKind::Shockwave:
            if (auto r = range("strength", o.strength, 0.0f, 0.5f,
                               "A fraction of the picture's height; 0.04 is a clear ring.");
                !r.ok())
                return r;
            if (auto r = range("radius", o.radius, 0.01f, 4.0f, "A fraction of the picture's height."); !r.ok())
                return r;
            return range("width", o.width, 0.005f, 2.0f, "A fraction of the picture's height.");
        case ScreenFxKind::HeatHaze:
            if (auto r = range("strength", o.strength, 0.0f, 0.1f,
                               "A fraction of the picture's height; 0.004 is a gentle shimmer.");
                !r.ok())
                return r;
            if (auto r = range("frequency", o.frequency, 0.5f, 200.0f, "Ripples per picture height."); !r.ok())
                return r;
            if (auto r = range("speed", o.speed, 0.0f, 20.0f, "Cycles per second."); !r.ok()) return r;
            for (float v : o.region)
                if (!finite(v)) return bad(k, "region must be [x, y, w, h], four finite numbers");
            if (o.region[2] <= 0.0f || o.region[3] <= 0.0f)
                return bad(k, "region must have a width and a height above 0",
                           "[x, y, w, h] as fractions of the camera's rectangle; [0, 0, 1, 1] is all of it.");
            return {};
        case ScreenFxKind::RadialBlur:
            if (auto r = range("intensity", o.intensity, 0.0f, 1.0f); !r.ok()) return r;
            if (o.samples < 4 || o.samples > 32)
                return bad(k, std::format("samples must be from 4 to 32, got {}", o.samples));
            return {};
        case ScreenFxKind::Flash: return range("strength", o.strength, 0.0f, 1.0f);
        case ScreenFxKind::Fade: return {};
    }
    return {};
}

float screen_fx_progress(const ScreenFx& fx) {
    return fx.o.duration > 0.0f ? std::clamp(fx.elapsed / fx.o.duration, 0.0f, 1.0f) : 1.0f;
}

float screen_fx_ring_radius(const ScreenFx& fx) {
    const float p = screen_fx_progress(fx);
    return fx.o.radius * p * (2.0f - p);
}

float screen_fx_envelope(const ScreenFx& fx) {
    const float p = screen_fx_progress(fx);
    switch (fx.o.kind) {
        case ScreenFxKind::Shockwave: return 1.0f - p;
        case ScreenFxKind::RadialBlur: return (1.0f - p) * (1.0f - p);
        case ScreenFxKind::HeatHaze:
            return std::clamp(std::min(fx.elapsed, fx.o.duration - fx.elapsed) / kHazeRamp, 0.0f, 1.0f);
        default: return 1.0f;
    }
}

float screen_fx_alpha(const ScreenFx& fx) {
    const float p = screen_fx_progress(fx);
    if (fx.o.kind == ScreenFxKind::Flash) {
        if (fx.elapsed >= fx.o.duration) return 0.0f;
        return fx.o.fade ? fx.o.strength * (1.0f - p) : fx.o.strength;
    }
    if (fx.o.kind == ScreenFxKind::Fade) return fx.fromAlpha + (fx.toAlpha - fx.fromAlpha) * p;
    return 0.0f;
}

bool screen_fx_done(const ScreenFx& fx) {
    if (fx.o.kind == ScreenFxKind::Fade && fx.toAlpha > 0.0f) return false;  // held until a fade in or a cancel
    return fx.elapsed >= fx.o.duration;
}

Result<void> screen_fx_start(World& w, Entity camera, const ScreenFxOptions& options) {
    if (!camera.is_null()) {
        if (!w.alive(camera))
            return bad(options.kind, std::format("camera entity {} does not exist", camera.index),
                       "Pass a live camera entity, or none for every camera: a script's handle dies with its entity.");
        if (!w.has<Camera>(camera))
            return bad(options.kind, std::format("entity '{}' has no Camera", w.id_of(camera)),
                       "Name a camera, or leave `camera` out to draw the effect on every camera.");
    }
    if (auto r = screen_fx_check(options); !r.ok()) return r;
    FeelState& fs = w.feel();
    ScreenFxState& st = fs.screenFx;
    ScreenFx fx;
    fx.o = options;
    fx.camera = camera;
    fx.serial = st.started++;
    ScreenFxOptions& o = fx.o;
    // Accessibility (feel.h): the motion effects shrink with reduce motion, a flash never strobes with reduced effects.
    if (fs.reduce_motion()) {
        if (o.kind == ScreenFxKind::Shockwave || o.kind == ScreenFxKind::HeatHaze) o.strength *= kReduceMotionShake;
        if (o.kind == ScreenFxKind::RadialBlur) o.intensity *= kReduceMotionShake;
    }
    if (o.kind == ScreenFxKind::Flash && fs.reduced_effects()) {
        o.strength = std::min(o.strength, kReducedEffectsFlash);
        o.fade = true;
    }
    if (o.kind == ScreenFxKind::Fade) {
        // A fade replaces the camera's own fade and goes on from the opacity that one had reached.
        bool had = false;
        float current = 0.0f;
        for (auto it = st.live.begin(); it != st.live.end(); ++it)
            if (it->o.kind == ScreenFxKind::Fade && it->camera == camera) {
                current = screen_fx_alpha(*it);
                had = true;
                st.live.erase(it);
                break;
            }
        fx.fromAlpha = had ? current : (o.fadeIn ? 1.0f : 0.0f);
        fx.toAlpha = o.fadeIn ? 0.0f : 1.0f;
        if (fx.toAlpha == 0.0f && fx.fromAlpha == 0.0f) return {};  // nothing to fade in from
    }
    // Bounded: the oldest effect that is not a held fade makes room (else the oldest), so a call never fails.
    while (st.live.size() >= kMaxScreenFx) {
        auto victim = std::find_if(st.live.begin(), st.live.end(), [](const ScreenFx& e) {
            return !(e.o.kind == ScreenFxKind::Fade && e.toAlpha > 0.0f);
        });
        st.live.erase(victim == st.live.end() ? st.live.begin() : victim);
    }
    st.live.push_back(fx);
    if (o.kind == ScreenFxKind::Fade && o.duration <= 0.0f && screen_fx_done(st.live.back())) st.live.pop_back();
    return {};
}

void screen_fx_update(World& w, float dt) {
    ScreenFxState& st = w.feel().screenFx;
    if (st.live.empty()) return;
    const float step = std::max(0.0f, dt);
    for (ScreenFx& fx : st.live) {
        fx.elapsed += step;
        if (fx.o.kind == ScreenFxKind::Fade && fx.toAlpha > 0.0f) fx.elapsed = std::min(fx.elapsed, fx.o.duration);
    }
    // An effect of a camera that no longer exists is never drawn: a held fade would stay in the list for ever.
    st.live.erase(
        std::remove_if(st.live.begin(), st.live.end(),
                       [&](const ScreenFx& e) { return screen_fx_done(e) || (e.camera && !w.alive(e.camera)); }),
        st.live.end());
}

void screen_fx_cancel(World& w, Entity camera) {
    ScreenFxState& st = w.feel().screenFx;
    if (camera.is_null()) {
        st.live.clear();
        return;
    }
    st.live.erase(std::remove_if(st.live.begin(), st.live.end(), [&](const ScreenFx& e) { return e.camera == camera; }),
                  st.live.end());
}

Json screen_fx_json(const World& w) {
    Json list = Json::array();
    for (const ScreenFx& fx : w.feel().screenFx.live) {
        Json o = Json::object();
        o["kind"] = std::string(screen_fx_action_name(fx.o.kind));
        o["camera"] = fx.camera.is_null() || !w.alive(fx.camera) ? Json(nullptr) : Json(w.id_of(fx.camera));
        o["elapsed"] = fx.elapsed;
        o["duration"] = fx.o.duration;
        if (fx.o.kind == ScreenFxKind::Flash || fx.o.kind == ScreenFxKind::Fade) o["alpha"] = screen_fx_alpha(fx);
        if (fx.o.kind == ScreenFxKind::Fade) o["held"] = fx.toAlpha > 0.0f && fx.elapsed >= fx.o.duration;
        list.push_back(std::move(o));
    }
    return list;
}

}  // namespace fa
