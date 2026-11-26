// Autotest section L4: the Lightmap panel (View > Lightmap, lightmap_panel.cpp). It opens the panel from the menu, clicks Start on a scene
// with nothing to light (a teaching error and no job), adds a floor, a box and a baked sun, starts a bake too big to finish and cancels it
// (nothing is written), then bakes a small one to the end with a LightProbeGroup: the panel shows its pages, its probes and sets SceneSettings.lightmaps as one undo step, which
// Undo takes back. Then the Device choice: an Auto bake and a GPU bake, which end done (the result names the device and where it ran) or, on a machine
// whose GPU cannot trace rays, as the fallback or the error that says why. The bakes run on the engine's job threads; every wait is a condition with a 60 s safety net, never a frame count.
#include <memory>
#include <system_error>

#include "autotest_common.h"
#include "editor_internal.h"
#include "fa/core/fs.h"

namespace fa::editor {

using namespace at_support;

namespace {

// The files of a bake of scenes/main.lightmap.json: the manifest and its pages. Paths go through fa::fs (UTF-8 in, never a narrow string).
void remove_lightmap_files(const std::string& projectDir) {
    for (const std::string& rel : fs::list("scenes", false)) {
        const std::string name = rel.substr(rel.find_last_of('/') == std::string::npos ? 0 : rel.find_last_of('/') + 1);
        if (name.rfind("main.lightmap.", 0) != 0) continue;
        std::error_code ec;
        fs::remove_file(fs::path_from_utf8(projectDir + "/" + rel), ec);
    }
}

bool manifest_exists() { return fs::exists("scenes/main.lightmap.json"); }

}  // namespace

void Editor::at_section_L4(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    auto depth0 = std::make_shared<std::size_t>(0);
    step(2, [this, depth0] {
        stop();
        showLightmap_ = false;
        lightmap_ = LightmapUi{};
        *depth0 = undo_depth();
        remove_lightmap_files(projectDir_);
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
        at_check(at_enabled("lm:start") && !at_enabled("lm:cancel"),
                 "Start is enabled and Cancel is not while nothing runs");
        pendingFocus_ = "Lightmap";
    });

    // The fixture scene is 2D: there is nothing to light, and the panel says what to add instead of starting a job.
    click("lm:start");
    step(4, [this, depth0] {
        at_check(lightmap_.job.empty() && lightmap_.state.empty(), "Start on a scene with no 3D mesh starts no job");
        at_check(lightmap_.error.find("nothing to bake") != std::string::npos,
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
        // About 1e6 texels and 3e9 rays: minutes of work on any machine, and ten times under the default maxRays (5e10), so the bake is
        // accepted, runs, and only Cancel ends it.
        lightmap_.texelsPerMeter = 128;
        lightmap_.samples = 1024;
        lightmap_.shadowSamples = 64;
        lightmap_.pageSizeIndex = 3;
        pendingFocus_ = "Lightmap";
    });
    click("lm:start");
    step(8, [this] {
        at_check(lightmap_.state == "running" && !lightmap_.job.empty(),
                 "Start begins a job (state: " + lightmap_.state + ", error: " + lightmap_.error + ")");
        at_check(at_visible("lm:progress"), "...with a progress bar");
        at_check(!at_enabled("lm:start") && at_enabled("lm:cancel"),
                 "...Start is disabled while it runs and Cancel is enabled");
        pendingFocus_ = "Lightmap";
    });
    snap("editor_lightmap.png");
    click("lm:cancel");
    step(1, [this] {
        atWaitCount_ = 0;
        atWaitWhat_ = "the cancelled bake to end";
        atWaitUntil_ = [this] { return lightmap_.state != "running"; };
    });
    step(4, [this, depth0] {
        at_check(lightmap_.state == "cancelled", "Cancel ends the job as cancelled, not failed (state: " +
                                                     lightmap_.state + ", error: " + lightmap_.error + ")");
        at_check(!lightmap_.error.empty() && at_visible("lm:error"), "...and the panel says so");
        at_check(!manifest_exists(), "...and no manifest was written");
        at_check(world().settings().lightmaps.empty() && undo_depth() == *depth0,
                 "...and the scene settings did not change");
        at_check(at_enabled("lm:start") && !at_enabled("lm:cancel"), "...and Start is enabled again");
        pendingFocus_ = "Lightmap";
    });

    // A small bake to the end.
    step(2, [this] {
        // A LightProbeGroup around the box: the bake adds the "probes" phase and writes the probe file next to the pages.
        const CommandResult pr = engine_->commands().call(
            "scene.spawn",
            Json::parse(
                R"({"id":"lm_probes","name":"Probes","components":{"Transform":{"position":[0,0,0]},"LightProbeGroup":{"size":[6,2,6],"spacing":3,"offset":[0,1,0]}}})"));
        at_check(pr.ok, "the autotest adds a LightProbeGroup: " + pr.error.dump());
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
    step(4, [this, depth0] {
        at_check(lightmap_.state == "done",
                 "the bake finishes (state: " + lightmap_.state + ", error: " + lightmap_.error + ")");
        at_check(at_visible("lm:summary"), "...and the panel lists its pages and texels");
        const Json probes =
            lightmap_.result.is_object() ? lightmap_.result.value("probes", Json::object()) : Json::object();
        at_check(probes.value("count", 0) > 0 && probes.value("invalid", -1) >= 0 && at_visible("lm:probes"),
                 "...and the probes of the LightProbeGroup, listed in the panel: " + probes.dump());
        at_check(fs::exists("scenes/main.lightmap.json") && !probes.value("file", std::string()).empty() &&
                     fs::exists(probes.value("file", std::string())),
                 "...and the probe file is written next to the manifest");
        at_check(manifest_exists(), "...and the manifest is written");
        at_check(world().settings().lightmaps == "scenes/main.lightmap.json",
                 "...and SceneSettings.lightmaps names it (" + world().settings().lightmaps + ")");
        at_check(undo_depth() == *depth0 + 1, "...as one undo step");
        pendingFocus_ = "Lightmap";
    });
    step(3, [this] { undo(); });
    step(3, [this, depth0] {
        at_check(world().settings().lightmaps.empty() && undo_depth() == *depth0,
                 "Undo takes SceneSettings.lightmaps back");
        remove_lightmap_files(projectDir_);
        pendingFocus_ = "Lightmap";
    });

    // The Device choice. The CPU bake above ran with the default (CPU) and says so; now Auto, then GPU. Whether this machine's GPU traces rays
    // (CI runners without ray queries do not) decides which device baked, never whether the panel works: Auto falls back to the CPU with the
    // reason, GPU fails with it. On a Mac the editor has a graphics context, so a GPU bake runs in a helper process (device.process).
    step(3, [this] {
        const Json dev =
            lightmap_.result.is_object() ? lightmap_.result.value("device", Json::object()) : Json::object();
        at_check(at_visible("lm:device") && at_enabled("lm:device"), "the panel has a Device choice");
        at_check(lightmap_.deviceIndex == 0 && dev.value("requested", std::string()) == "cpu" &&
                     dev.value("used", std::string()) == "cpu" && at_visible("lm:device_used"),
                 "...CPU by default: the CPU bake says it baked on the CPU: " + dev.dump());
        const CommandInfo* info = engine_->commands().info("lightmap.bake_start");
        at_check(info && info->inputSchema["properties"]["device"].value("description", std::string()).find("auto") !=
                             std::string::npos,
                 "...whose tooltip is the doc string of lightmap.bake_start's `device`");
        lightmap_.deviceIndex = 2;  // Auto
        pendingFocus_ = "Lightmap";
    });
    click("lm:start");
    step(1, [this] {
        atWaitCount_ = 0;
        atWaitWhat_ = "the Auto bake to finish";
        atWaitUntil_ = [this] { return lightmap_.state != "running"; };
    });
    step(4, [this, depth0] {
        at_check(lightmap_.state == "done",
                 "an Auto bake finishes (state: " + lightmap_.state + ", error: " + lightmap_.error + ")");
        const Json dev =
            lightmap_.result.is_object() ? lightmap_.result.value("device", Json::object()) : Json::object();
        const std::string used = dev.value("used", std::string());
        at_check(dev.value("requested", std::string()) == "auto" && (used == "gpu" || used == "cpu"),
                 "...and the result says what baked: " + dev.dump());
        at_check(used == "gpu" || !dev.value("note", std::string()).empty(),
                 "...a CPU fallback with the reason (" + dev.value("note", std::string()) + ")");
        at_check(dev.value("process", std::string()) == "here" || dev.value("process", std::string()) == "helper",
                 "...and where: " + dev.value("process", std::string()));
        at_check(at_visible("lm:device_used") && at_visible("lm:summary"), "...both listed in the panel");
        at_check(manifest_exists() && world().settings().lightmaps == "scenes/main.lightmap.json" &&
                     undo_depth() == *depth0 + 1,
                 "...and the scene uses it as one undo step");
        pendingFocus_ = "Lightmap";
    });
    step(3, [this] {
        undo();
        remove_lightmap_files(projectDir_);
        lightmap_.deviceIndex = 1;  // GPU
        pendingFocus_ = "Lightmap";
    });
    click("lm:start");
    step(1, [this] {
        atWaitCount_ = 0;
        atWaitWhat_ = "the GPU bake to end";
        atWaitUntil_ = [this] { return lightmap_.state != "running"; };
    });
    step(4, [this, depth0] {
        if (lightmap_.state == "done") {
            const Json dev = lightmap_.result.value("device", Json::object());
            at_check(dev.value("requested", std::string()) == "gpu" && !dev.value("name", std::string()).empty(),
                     "a GPU bake that ran says which GPU: " + dev.dump());
            at_check(at_visible("lm:device_used"), "...in the panel");
            undo();
        } else {
            // No GPU here that traces rays (or a helper that cannot start): the panel shows the engine's own error, with its hint.
            at_check(lightmap_.state == "failed" && lightmap_.error.find("gpu") != std::string::npos &&
                         !lightmap_.hint.empty() && at_visible("lm:error"),
                     "a GPU bake that cannot run fails with the reason and a hint (state: " + lightmap_.state +
                         ", error: " + lightmap_.error + ")");
            at_check(!manifest_exists() && world().settings().lightmaps.empty() && undo_depth() == *depth0,
                     "...and changes nothing");
        }
        lightmap_.deviceIndex = 0;
        pendingFocus_ = "Lightmap";
    });
    step(3, [this, depth0] {
        at_check(world().settings().lightmaps.empty() && undo_depth() == *depth0, "the scene is back as it was");
        showLightmap_ = false;
        remove_lightmap_files(projectDir_);
    });
    step(3, [this] { at_check(!at_visible("lm:start"), "closing the panel removes it"); });
}

}  // namespace fa::editor
