// The bot hook (game.autoplay / game.phase, the JS side is in factoria.js): the calls the play.auto driver makes.
#include <algorithm>

#include "fa/core/fs.h"
#include "script_internal.h"

namespace fa {

using Impl = ScriptSystem::Impl;

namespace {
constexpr const char* kAutoplayModule = "scripts/autoplay.js";
}

std::uint64_t ScriptSystem::error_events() const { return impl_->errorEvents; }
std::uint64_t ScriptSystem::watchdog_cut_count() const { return impl_->cutCount; }
const std::vector<ScriptWatchdogCut>& ScriptSystem::watchdog_cuts() const { return impl_->cuts; }

std::string ScriptSystem::autoplay_begin(bool useHook, bool* hookFound) {
    Impl& I = *impl_;
    if (hookFound) *hookFound = false;
    I.autoplayOn = true;
    I.autoplayHook = false;
    I.autoplayPhases.clear();
    if (!I.initialized) return "the scripts are not running";
    if (!useHook) return {};
    if (fs::exists(kAutoplayModule)) {
        auto ns = I.import_module(kAutoplayModule);
        if (!ns.ok()) return ns.error().message;
        JS_FreeValue(I.ctx, ns.value());
        I.run_jobs();
    }
    JSValue fn = JS_GetPropertyStr(I.ctx, I.hooks.get(), "autoplayHas");
    JSValue r = I.call("game.autoplay", "", fn, I.hooks.get(), {});
    I.autoplayHook = JS_ToBool(I.ctx, r) > 0;
    JS_FreeValue(I.ctx, r);
    JS_FreeValue(I.ctx, fn);
    if (hookFound) *hookFound = I.autoplayHook;
    return {};
}

void ScriptSystem::autoplay_end() {
    impl_->autoplayOn = false;
    impl_->autoplayHook = false;
    impl_->autoplayPhases.clear();
}

ScriptSystem::AutoplayAnswer ScriptSystem::autoplay_step(const Json& state) {
    Impl& I = *impl_;
    AutoplayAnswer out;
    if (!I.initialized || !I.autoplayOn || !I.autoplayHook) return out;
    out.called = true;
    JSValue arg = I.from_json(state);
    JSValue fn = JS_GetPropertyStr(I.ctx, I.hooks.get(), "autoplayStep");
    bool failed = false;
    JSValue r = I.call("game.autoplay", "", fn, I.hooks.get(), {arg}, &failed);
    JS_FreeValue(I.ctx, arg);
    JS_FreeValue(I.ctx, fn);
    if (failed) {
        out.failed = true;
        JS_FreeValue(I.ctx, r);
        return out;
    }
    const Json j = I.to_json(r);
    JS_FreeValue(I.ctx, r);
    I.run_jobs();
    if (!j.is_object()) return out;
    if (j.contains("actions") && j["actions"].is_array())
        for (const Json& a : j["actions"])
            if (a.is_string()) out.actions.push_back(a.get<std::string>());
    out.end = j.value("end", std::string());
    if (j.contains("score") && j["score"].is_number()) {
        out.hasScore = true;
        out.score = j["score"].get<double>();
    }
    out.note = j.value("note", std::string());
    return out;
}

std::vector<ScriptSystem::AutoplayPhase> ScriptSystem::autoplay_take_phases() {
    std::vector<AutoplayPhase> out;
    out.swap(impl_->autoplayPhases);
    return out;
}

}  // namespace fa
