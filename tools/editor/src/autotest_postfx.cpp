// Autotest section G2: the Post-processing panel (View > Post-processing, postfx_panel.cpp). It opens the panel from the menu, reads the
// stack it shows, toggles the A/B switch (the renderer's bypass, no data change), applies two looks with their buttons (one undo step
// each, through postprocess.apply_preset), edits a field through the panel's own path (postprocess.set), undoes every one of them, and
// closes the panel with the A/B switch still on (the picture must get its stack back).
#include <cmath>
#include <memory>

#include "autotest_common.h"
#include "editor_internal.h"
#include "fa/render/renderer.h"
#include "fa/scene/postprocess.h"

namespace fa::editor {

using namespace at_support;

namespace {

// The effect `name` in the resolved stack the panel shows; nullptr when the panel has no report.
const Json* shown_effect(const Json& report, const std::string& name) {
    if (!report.is_object() || !report.contains("resolved")) return nullptr;
    for (const Json& e : report["resolved"]["effects"])
        if (e.value("name", std::string()) == name) return &e;
    return nullptr;
}

// The panel disables the switch of an effect when render.supports lists it and says it is not supported (planned, or no GPU feature
// for it here), whatever the reason: the same condition as the panel's.
bool switch_blocked(const Json& support, const std::string& effect) {
    if (!support.is_object() || !support.contains("features")) return false;
    for (const Json& f : support["features"])
        if (f.value("name", std::string()) == effect) return !f.value("supported", false);
    return false;
}

}  // namespace

void Editor::at_section_G2(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    auto depth0 = std::make_shared<std::size_t>(0);
    auto hadPost = std::make_shared<bool>(false);
    step(2, [this, depth0, hadPost] {
        const Entity cam = world().find_by_id("camera");
        *hadPost = !cam.is_null() && world().get<PostProcess>(cam) != nullptr;
        *depth0 = undo_depth();
    });
    click("menu:view");
    step(3, [] {});
    click("menu:postfx");
    step(4, [this] {
        at_check(showPostFx_, "View > Post-processing shows the Post-processing panel");
        pendingFocus_ = "Post-processing";
    });
    step(4, [this] {
        const Json& r = postFx_.report;
        at_check(r.is_object() && r.value("id", std::string()) == "camera",
                 "the panel shows the stack of the main camera (the id the answer names)");
        const Json* first = shown_effect(r, "ssao");
        const Json* last = shown_effect(r, "colorFilter");
        at_check(first && last && r["resolved"]["effects"].size() == std::size_t(kPostEffectCount),
                 "the panel lists every effect, from ssao to colorFilter, in the order they run");
        at_check(postFx_.support.is_object() && postFx_.support.contains("features"),
                 "...with what the renderer draws of each (render.supports)");
        const bool blocked = switch_blocked(postFx_.support, "ssao");
        at_check(at_visible("postfx:on:ssao") && at_enabled("postfx:on:ssao") == !blocked,
                 "an effect the renderer does not draw has a disabled switch, one it draws an enabled one");
        at_check(at_enabled("postfx:on:bloom") == !switch_blocked(postFx_.support, "bloom"),
                 "...and the switch of bloom follows what the renderer says of bloom");
        at_check(at_visible("postfx:preset:cinematic") && at_visible("postfx:preset:neutral"),
                 "the look buttons are listed (cinematic, neutral...)");
        pendingFocus_ = "Post-processing";
    });

    // A/B: the renderer stops drawing the stack, nothing in the scene changes, no undo step.
    click("postfx:ab");
    step(3, [this, depth0] {
        at_check(postFx_.compare && engine_->renderer() && engine_->renderer()->post_bypass(),
                 "the A/B switch turns the renderer's post-processing off");
        at_check(undo_depth() == *depth0, "...and writes no data: no undo step");
        pendingFocus_ = "Post-processing";
    });
    click("postfx:ab");
    step(3, [this] {
        at_check(!postFx_.compare && engine_->renderer() && !engine_->renderer()->post_bypass(),
                 "a second click gives the picture its stack back");
        pendingFocus_ = "Post-processing";
    });

    // A look: one button, one undo step; neutral clears it again.
    click("postfx:preset:cinematic");
    step(4, [this, depth0] {
        const Entity cam = world().find_by_id("camera");
        const PostProcess* p = cam.is_null() ? nullptr : world().get<PostProcess>(cam);
        at_check(postFx_.error.empty(), "the cinematic look applied without an error: " + postFx_.error);
        at_check(p && p->bloomEnabled && p->tonemapEnabled && p->vignetteEnabled,
                 "the cinematic look switched bloom, tonemap and vignette on in the camera's own PostProcess");
        at_check(undo_depth() == *depth0 + 1, "...as one undo step");
        const Json* bloom = shown_effect(postFx_.report, "bloom");
        at_check(bloom && bloom->value("enabled", false), "the panel now lists bloom as running");
        pendingFocus_ = "Post-processing";
    });
    snap("editor_postfx.png");
    click("postfx:preset:neutral");
    step(4, [this, depth0] {
        const Entity cam = world().find_by_id("camera");
        const PostProcess* p = cam.is_null() ? nullptr : world().get<PostProcess>(cam);
        at_check(p && !p->bloomEnabled && !p->tonemapEnabled && !p->vignetteEnabled,
                 "the neutral look switches every effect off again");
        at_check(undo_depth() == *depth0 + 2, "...as a second undo step");
        // The panel's field path: postprocess.set through edit_command.
        at_check(postfx_edit(Json::object({{"bloomEnabled", true}, {"bloomIntensity", 0.9}})),
                 "an edit from the panel (postprocess.set) is accepted: " + postFx_.error);
    });
    step(3, [this, depth0] {
        const Entity cam = world().find_by_id("camera");
        const PostProcess* p = cam.is_null() ? nullptr : world().get<PostProcess>(cam);
        at_check(p && p->bloomEnabled && std::fabs(p->bloomIntensity - 0.9f) < 0.001f,
                 "...and writes the fields it was given");
        at_check(undo_depth() == *depth0 + 3, "...as one undo step");
        undo();
        undo();
        undo();
    });
    step(3, [this, depth0, hadPost] {
        const Entity cam = world().find_by_id("camera");
        const PostProcess* p = cam.is_null() ? nullptr : world().get<PostProcess>(cam);
        at_check(undo_depth() == *depth0, "three undos take the three steps back");
        at_check((p != nullptr) == *hadPost && (!p || (!p->bloomEnabled && !p->tonemapEnabled)),
                 "...and the camera is as it was before the panel: no stack");
        pendingFocus_ = "Post-processing";
    });

    // Closing the panel with A/B on gives the picture its stack back.
    click("postfx:ab");
    step(3, [this] {
        at_check(engine_->renderer() && engine_->renderer()->post_bypass(), "A/B on again before the panel closes");
        showPostFx_ = false;
    });
    step(3, [this] {
        at_check(engine_->renderer() && !engine_->renderer()->post_bypass() && !postFx_.compare,
                 "closing the panel turns the renderer's post-processing back on");
    });
}

}  // namespace fa::editor
