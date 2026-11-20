// Autotest section L4: the Lightmap panel (View > Lightmap, lightmap_panel.cpp). It opens the panel from the menu, clicks Start on a scene
// with nothing to light (a teaching error and no job), adds a floor, a box and a baked sun, starts a bake too big to finish and cancels it
// (nothing is written), then bakes a small one to the end: the panel shows its pages and sets SceneSettings.lightmaps as one undo step, which
// Undo takes back. The bakes run on the engine's job threads; every wait is a condition with a 60 s safety net, never a frame count.
#include <filesystem>
#include <memory>

#include "autotest_common.h"
#include "editor_internal.h"

namespace fa::editor {

using namespace at_support;

void Editor::at_section_L4(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    auto depth0 = std::make_shared<std::size_t>(0);
    auto manifest = std::make_shared<std::string>();
    step(2, [this, project_file, depth0, manifest] {
        stop();
        showLightmap_ = false;
        lightmap_ = LightmapUi{};
        *depth0 = undo_depth();
        *manifest = project_file("scenes/main.lightmap.json");
        std::error_code ec;
        std::filesystem::remove(std::filesystem::path(*manifest), ec);
    });
    click("menu:view");
    step(3, [] {});
    click("menu:lightmap");
    step(4, [this] {
        at_check(showLightmap_, "View > Lightmap shows the Lightmap panel");
        pendingFocus_ = "Lightmap";
    });
    step(4, [this] {
        at_check(at_visible("lm:start") && at_visible("lm:tpm"), "the panel lists the options and a Start button");
        at_check(at_enabled("lm:start") && !at_enabled("lm:cancel"), "Start is enabled and Cancel is not while nothing runs");
        pendingFocus_ = "Lightmap";
    });

    // The fixture scene is 2D: there is nothing to light, and the panel says what to add instead of starting a job.
    click("lm:start");
    step(4, [this, depth0] {
        at_check(lightmap_.job.empty() && lightmap_.state.empty(), "Start on a scene with no 3D mesh starts no job");
        at_check(lightmap_.error.find("no mesh") != std::string::npos,
                 "...and the panel says why: " + lightmap_.error);
        at_check(!lightmap_.hint.empty() && at_visible("lm:error"), "...with a hint, drawn in the panel");
        at_check(undo_depth() == *depth0, "...and changes nothing");
        pendingFocus_ = "Lightmap";
    });

    // A floor, a box and a baked sun; options far too heavy to finish, so Cancel has something to stop.
    step(2, [this] {
        const char* ents[] = {
            R"({"id":"lm_floor","name":"Floor","components":{"Transform":{"position":[0,-0.1,0],"scale":[4,0.2,4]},"MeshRenderer":{"mesh":"cube","color":"#808080"}}})",
            R"({"id":"lm_box","name":"Box","components":{"Transform":{"position":[0,0.5,0]},"MeshRenderer":{"mesh":"cube","color":"#808080"}}})",
            R"({"id":"lm_sun","name":"Sun","components":{"Transform":{"rotation":[-45,0,0]},"Light":{"type":"directional","intensity":1,"mode":"baked"}}})"};
        for (const char* e : ents) {
            const CommandResult r = engine_->commands().call("scene.spawn", Json::parse(e));
            at_check(r.ok, "the autotest adds an entity for the bake: " + r.error.dump());
        }
        lightmap_.texelsPerMeter = 256;
        lightmap_.samples = 4096;
        lightmap_.shadowSamples = 64;
        lightmap_.pageSizeIndex = 3;
        pendingFocus_ = "Lightmap";
    });
    click("lm:start");
    step(8, [this] {
        at_check(lightmap_.state == "running" && !lightmap_.job.empty(), "Start begins a job (state: " + lightmap_.state + ", error: " + lightmap_.error + ")");
        at_check(at_visible("lm:progress"), "...with a progress bar");
        at_check(!at_enabled("lm:start") && at_enabled("lm:cancel"), "...Start is disabled while it runs and Cancel is enabled");
        pendingFocus_ = "Lightmap";
    });
    snap("editor_lightmap.png");
    click("lm:cancel");
    step(1, [this] {
        atWaitCount_ = 0;
        atWaitWhat_ = "the cancelled bake to end";
        atWaitUntil_ = [this] { return lightmap_.state != "running"; };
    });
    step(4, [this, depth0, manifest] {
        at_check(lightmap_.state == "cancelled", "Cancel ends the job as cancelled (state: " + lightmap_.state + ")");
        at_check(!lightmap_.error.empty() && at_visible("lm:error"), "...and the panel says so");
        at_check(!std::filesystem::exists(std::filesystem::path(*manifest)), "...and no manifest was written");
        at_check(world().settings().lightmaps.empty() && undo_depth() == *depth0,
                 "...and the scene settings did not change");
        at_check(at_enabled("lm:start") && !at_enabled("lm:cancel"), "...and Start is enabled again");
        pendingFocus_ = "Lightmap";
    });

    // A small bake to the end.
    step(2, [this] {
        lightmap_.texelsPerMeter = 8;
        lightmap_.samples = 16;
        lightmap_.shadowSamples = 4;
        lightmap_.pageSizeIndex = 1;
        pendingFocus_ = "Lightmap";
    });
    click("lm:start");
    step(1, [this] {
        atWaitCount_ = 0;
        atWaitWhat_ = "the bake to finish";
        atWaitUntil_ = [this] { return lightmap_.state != "running"; };
    });
    step(4, [this, depth0, manifest] {
        at_check(lightmap_.state == "done", "the bake finishes (state: " + lightmap_.state + ", error: " + lightmap_.error + ")");
        at_check(at_visible("lm:summary"), "...and the panel lists its pages and texels");
        at_check(std::filesystem::exists(std::filesystem::path(*manifest)), "...and the manifest is written");
        at_check(world().settings().lightmaps == "scenes/main.lightmap.json",
                 "...and SceneSettings.lightmaps names it (" + world().settings().lightmaps + ")");
        at_check(undo_depth() == *depth0 + 1, "...as one undo step");
        pendingFocus_ = "Lightmap";
    });
    step(3, [this] { undo(); });
    step(3, [this, depth0] {
        at_check(world().settings().lightmaps.empty() && undo_depth() == *depth0, "Undo takes SceneSettings.lightmaps back");
        showLightmap_ = false;
    });
    step(3, [this] { at_check(!at_visible("lm:start"), "closing the panel removes it"); });
}

}  // namespace fa::editor
