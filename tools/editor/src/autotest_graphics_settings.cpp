// Autotest section Q4: the Graphics settings window (View > Graphics, graphics_settings_panel.cpp). It opens the window from
// the menu, picks an upscaler mode and a preset with real clicks on the combos (the popups' items), Saves, and checks
// factoria.json on disk (only the keys of the window change), a wrong value (set as a script would) that disables Save and
// is named with its pointer, and Revert. The Low latency group is driven on a fixed render.supports table: a mode the renderer cannot run is greyed out
// and refused, auto and its boost are saved as render.latency, off removes the key. The Frame generation group the same way: dlss and xess are
// greyed out and refused on the fixed table, fsr and its minimum base frame rate are saved as render.frameGeneration, the advice for a low-latency
// mode shows while none is set, off removes the key. The test project's factoria.json is put back at the end. Every wait counts frames.
#include <memory>

#include "autotest_common.h"
#include "editor_internal.h"
#include "fa/tooling/graphics_settings.h"

namespace fa::editor {

using namespace at_support;

void Editor::at_section_Q4(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    auto original = std::make_shared<std::string>();
    step(2, [this, project_file, original] {
        stop();
        *original = read_file(project_file("factoria.json"));
        showGraphics_ = false;
        graphicsDir_.clear();
    });
    click("menu:view");
    step(3, [] {});
    click("menu:graphics");
    step(5, [this] {
        at_check(showGraphics_, "View > Graphics shows the Graphics settings window");
        pendingFocus_ = "Graphics";
    });
    step(4, [this] {
        at_check(
            at_visible("gfx:preset") && at_visible("gfx:mode") && at_visible("gfx:quality") &&
                at_visible("gfx:sharpness") && at_visible("gfx:dynEnabled") && at_visible("gfx:dynTarget") &&
                at_visible("gfx:dynMin") && at_visible("gfx:dynMax"),
            "the window lists the preset, the upscaler's mode and quality, the sharpness and the dynamic resolution");
        at_check(!at_enabled("gfx:dynTarget") && !at_enabled("gfx:dynMin"),
                 "the dynamic resolution's target and range are greyed out while it is off");
        at_check(graphicsWork_ == GraphicsSettings{}, "a project with no render settings shows the defaults");
        at_check(!at_enabled("gfx:sharpness"), "the sharpness is greyed out while the mode is stretch");
        at_check(at_visible("gfx:save") && !at_enabled("gfx:save"), "Save waits until something changed");
        pendingFocus_ = "Graphics";
    });
    snap("editor_graphics_settings.png");

    // Mode: the real combo, then its item.
    click("gfx:mode");
    step(4, [this] {
        at_check(at_visible("gfx:mode:spatial") && at_visible("gfx:mode:metalfx"),
                 "the mode combo lists the engine's modes");
        at_check(at_visible("gfx:mode:dlss") && at_visible("gfx:mode:xess") && at_visible("gfx:mode:fsr"),
                 "...with the vendor upscalers of M78");
    });
    click("gfx:mode:spatial");
    step(4, [this] {
        at_check(graphicsWork_.mode == "spatial", "picking spatial sets the working copy");
        at_check(at_enabled("gfx:sharpness"), "...and the sharpness can be edited");
        at_check(at_enabled("gfx:save"), "...and Save is enabled");
        pendingFocus_ = "Graphics";
    });
    click("gfx:preset");
    step(4, [] {});
    click("gfx:preset:low");
    step(4, [this] {
        at_check(graphicsWork_.preset == "low", "picking a preset sets the working copy");
        pendingFocus_ = "Graphics";
    });
    click("gfx:dynEnabled");
    step(4, [this] {
        at_check(graphicsWork_.dynamic.enabled, "ticking Enabled turns the dynamic resolution on in the working copy");
        at_check(at_enabled("gfx:dynTarget") && at_enabled("gfx:dynMin") && at_enabled("gfx:dynMax"),
                 "...and its target and range can be edited");
        graphicsWork_.dynamic.targetMs = 16.7;  // the drag itself is not driven here: the model is what Save writes
        graphicsWork_.dynamic.minScale = 0.6f;
        pendingFocus_ = "Graphics";
    });
    click("gfx:save");
    step(5, [this, project_file] {
        const std::string text = read_file(project_file("factoria.json"));
        at_check(text.find("\"graphicsPreset\"") != std::string::npos && text.find("\"low\"") != std::string::npos &&
                     text.find("\"spatial\"") != std::string::npos,
                 "Save writes render.graphicsPreset and render.upscaler to factoria.json");
        at_check(text.find("\"dynamicResolution\"") != std::string::npos && text.find("16.7") != std::string::npos,
                 "...and render.dynamicResolution");
        auto back = read_graphics_settings(project_dir());
        at_check(back.ok() && back->preset == "low" && back->mode == "spatial" && back->quality == "native" &&
                     back->dynamic.enabled && back->dynamic.minScale == 0.6f,
                 "...and the engine's own reader finds them again");
        at_check(graphicsSaved_ == graphicsWork_ && !at_enabled("gfx:save"), "...Save is disabled again");
        pendingFocus_ = "Graphics";
    });

    // A wrong value (an AI or a script could not write it through this window; a person typing one cannot either).
    step(2, [this] { graphicsWork_.mode = "spatail"; });
    step(4, [this, project_file] {
        const auto problems = check_graphics_settings(graphicsWork_);
        at_check(problems.size() == 1 && problems[0].pointer == "/render/upscaler/mode",
                 "a misspelt mode is named with its pointer");
        at_check(!at_enabled("gfx:save"), "...and Save stays disabled");
        std::string err;
        at_check(!graphics_settings_save(&err) && !err.empty(), "...and saving anyway is refused with a message");
        at_check(read_file(project_file("factoria.json")).find("spatial") != std::string::npos,
                 "...and the file keeps the last good value");
        pendingFocus_ = "Graphics";
    });
    click("gfx:revert");
    step(4, [this] {
        at_check(graphicsWork_.mode == "spatial" && graphicsWork_.preset == "low",
                 "Revert reads the saved values again");
    });

    // The Low latency group (render.latency, docs/LATENCY.md). The renderer's table is replaced by a fixed one (and kept from refreshing),
    // so what each mode answers does not depend on this machine's GPU: reflex and antilag2 are not usable here, xell is.
    step(2, [this] {
        graphicsSupport_ = Json::parse(
            R"({"features":[
                {"name":"reflex","supported":false,"status":"arrives with the Streamline provider"},
                {"name":"antilag2","supported":false,"status":"needs an AMD Radeon GPU on Windows"},
                {"name":"xell","supported":true,"status":"supported"},
                {"name":"dlssFrameGen","supported":false,"status":"needs an NVIDIA RTX GPU"},
                {"name":"fsrFrameGen","supported":true,"status":"supported"},
                {"name":"xessFrameGen","supported":false,"status":"needs an Intel Arc GPU on Windows"}]})");
        graphicsSupportPinned_ = true;
        pendingFocus_ = "Graphics";
    });
    step(4, [this] {
        at_check(at_visible("gfx:latMode") && at_visible("gfx:latBoost"),
                 "the window has a Low latency group with the mode and the boost");
        at_check(graphicsWork_.latencyMode == "off" && !at_enabled("gfx:latBoost"),
                 "the mode is off by default and the boost is greyed out for it");
        at_check(graphicsLatencyLine_.find("Off") == 0, "...and the line under it says that nothing is paced");
        pendingFocus_ = "Graphics";
    });
    click("gfx:latMode");
    step(4, [this] {
        at_check(at_visible("gfx:latMode:off") && at_visible("gfx:latMode:auto") && at_visible("gfx:latMode:reflex") &&
                     at_visible("gfx:latMode:antilag2") && at_visible("gfx:latMode:xell"),
                 "the mode combo lists off, auto, reflex, antilag2 and xell");
        at_check(at_enabled("gfx:latMode:off") && at_enabled("gfx:latMode:auto") && at_enabled("gfx:latMode:xell"),
                 "...with the modes this machine can run enabled");
        at_check(!at_enabled("gfx:latMode:reflex") && !at_enabled("gfx:latMode:antilag2"),
                 "...and the modes it cannot run greyed out (their reason is the tooltip)");
    });
    click("gfx:latMode:auto");
    step(4, [this] {
        at_check(graphicsWork_.latencyMode == "auto", "picking auto sets the working copy");
        at_check(at_enabled("gfx:latBoost"), "...and auto has a boost switch");
        at_check(graphicsLatencyLine_.find("xell") != std::string::npos,
                 "...and the line names the SDK this machine can run");
        pendingFocus_ = "Graphics";
    });
    click("gfx:latBoost");
    step(4, [this] {
        at_check(graphicsWork_.latencyBoost, "ticking Boost sets it in the working copy");
        at_check(at_enabled("gfx:save"), "...and Save is enabled");
        pendingFocus_ = "Graphics";
    });
    click("gfx:save");
    step(5, [this, project_file] {
        const std::string text = read_file(project_file("factoria.json"));
        at_check(text.find("\"latency\"") != std::string::npos && text.find("\"auto\"") != std::string::npos &&
                     text.find("\"boost\": true") != std::string::npos,
                 "Save writes render.latency to factoria.json");
        auto back = read_graphics_settings(project_dir());
        at_check(back.ok() && back->latencyMode == "auto" && back->latencyBoost && back->mode == "spatial" &&
                     back->preset == "low",
                 "...the engine's own reader finds it again and the other keys are as they were");
        pendingFocus_ = "Graphics";
    });
    // A mode this machine cannot run is refused (the click does nothing) and its reason is what the window knows of it.
    click("gfx:latMode");
    step(4, [] {});
    click("gfx:latMode:reflex");
    step(4, [this] {
        at_check(graphicsWork_.latencyMode == "auto", "a click on a mode that cannot run is refused");
        at_check(!at_enabled("gfx:save"), "...and nothing is left to save");
    });
    step(2,
         [this] { graphicsWork_.latencyMode = "reflex"; });  // as a project file written for another machine would be
    step(4, [this] {
        at_check(graphicsLatencyLine_.find("Not usable") == 0 &&
                     graphicsLatencyLine_.find("arrives with the Streamline provider") != std::string::npos,
                 "a project that names such a mode shows its reason and what a run does instead");
        at_check(check_graphics_settings(graphicsWork_).empty(), "...but the value is valid, it only cannot run here");
        graphicsWork_.latencyMode = "antilag";
    });
    step(4, [this] {
        const auto problems = check_graphics_settings(graphicsWork_);
        at_check(problems.size() == 1 && problems[0].pointer == "/render/latency/mode" &&
                     problems[0].message.find("antilag2") != std::string::npos,
                 "a misspelt latency mode is named with its pointer and a \"did you mean\"");
        at_check(!at_enabled("gfx:save"), "...and Save stays disabled");
        pendingFocus_ = "Graphics";
    });
    click("gfx:revert");
    step(4, [this] {
        at_check(graphicsWork_.latencyMode == "auto" && graphicsWork_.latencyBoost,
                 "Revert reads the saved latency again");
        pendingFocus_ = "Graphics";
    });
    click("gfx:latMode");
    step(4, [] {});
    click("gfx:latMode:off");
    step(4, [this] {
        at_check(graphicsWork_.latencyMode == "off" && !graphicsWork_.latencyBoost,
                 "picking off puts the mode back and drops the boost it has no switch for");
        at_check(!at_enabled("gfx:latBoost") && at_enabled("gfx:save"), "...the boost is greyed out again");
        pendingFocus_ = "Graphics";
    });
    click("gfx:save");
    step(5, [this, project_file] {
        const std::string text = read_file(project_file("factoria.json"));
        at_check(text.find("\"latency\"") == std::string::npos && text.find("\"spatial\"") != std::string::npos,
                 "Save with the mode off removes render.latency and keeps the rest");
        auto back = read_graphics_settings(project_dir());
        at_check(back.ok() && back->latencyMode == "off" && !back->latencyBoost, "...and the reader finds the default");
        pendingFocus_ = "Graphics";
    });

    // The Frame generation group (render.frameGeneration, docs/FRAME_GENERATION.md), on the same fixed table: dlss and xess cannot run, fsr can.
    step(4, [this] {
        at_check(at_visible("gfx:fgMode") && at_visible("gfx:fgMinFps"),
                 "the window has a Frame generation group with the mode and the minimum base frame rate");
        at_check(graphicsWork_.frameGenMode == "off" && !at_enabled("gfx:fgMinFps"),
                 "the mode is off by default and the minimum is greyed out for it");
        at_check(graphicsFrameGenLine_.find("Off") == 0 && graphicsFrameGenHint_.empty(),
                 "...the line says that nothing is generated and there is no latency advice");
        at_check(graphicsFrameGenState_.find("Off") == 0 || graphicsFrameGenState_.find("Refused") == 0,
                 "...and the engine's readout is a line of its own (the editor's loop never generates)");
        pendingFocus_ = "Graphics";
    });
    click("gfx:fgMode");
    step(4, [this] {
        at_check(at_visible("gfx:fgMode:off") && at_visible("gfx:fgMode:auto") && at_visible("gfx:fgMode:dlss") &&
                     at_visible("gfx:fgMode:fsr") && at_visible("gfx:fgMode:xess"),
                 "the frame generation combo lists off, auto, dlss, fsr and xess");
        at_check(at_enabled("gfx:fgMode:off") && at_enabled("gfx:fgMode:auto") && at_enabled("gfx:fgMode:fsr"),
                 "...with the modes this machine can run enabled");
        at_check(!at_enabled("gfx:fgMode:dlss") && !at_enabled("gfx:fgMode:xess"),
                 "...and the SDKs it cannot run greyed out (their reason is the tooltip)");
    });
    click("gfx:fgMode:dlss");
    step(4, [this] {
        at_check(graphicsWork_.frameGenMode == "off", "a click on a mode that cannot run is refused");
        pendingFocus_ = "Graphics";
    });
    click("gfx:fgMode");
    step(4, [] {});
    click("gfx:fgMode:fsr");
    step(4, [this] {
        at_check(graphicsWork_.frameGenMode == "fsr", "picking fsr sets the working copy");
        at_check(at_enabled("gfx:fgMinFps") && at_enabled("gfx:save"), "...the minimum is enabled and Save too");
        at_check(graphicsFrameGenLine_.find("Usable on this machine") == 0 &&
                     graphicsFrameGenLine_.find("fewer than 60 frames") != std::string::npos,
                 "...and the line says it can run here and what the minimum does");
        at_check(graphicsFrameGenHint_.find("low-latency mode") != std::string::npos,
                 "...with the advice for a low-latency mode while render.latency is off");
        graphicsWork_.frameGenMinBaseFps = 45;  // what the slider sets
        pendingFocus_ = "Graphics";
    });
    click("gfx:save");
    step(5, [this, project_file] {
        const std::string text = read_file(project_file("factoria.json"));
        at_check(text.find("\"frameGeneration\"") != std::string::npos && text.find("\"fsr\"") != std::string::npos &&
                     text.find("\"minBaseFps\": 45") != std::string::npos,
                 "Save writes render.frameGeneration to factoria.json");
        auto back = read_graphics_settings(project_dir());
        at_check(back.ok() && back->frameGenMode == "fsr" && back->frameGenMinBaseFps == 45 &&
                     back->mode == "spatial" && back->preset == "low" && back->latencyMode == "off",
                 "...the engine's own reader finds it again and the other keys are as they were");
        graphicsWork_.latencyMode = "xell";  // a low-latency mode is chosen: the advice goes
    });
    step(4, [this] {
        at_check(graphicsFrameGenHint_.empty(), "with a low-latency mode set the advice goes");
        graphicsWork_.latencyMode = "off";
        graphicsWork_.frameGenMode = "dlss";  // as a project file written for another machine would be
    });
    step(4, [this] {
        at_check(graphicsFrameGenLine_.find("Not usable on this machine: needs an NVIDIA RTX GPU") == 0,
                 "a project that names an SDK this machine cannot run shows its reason");
        at_check(graphicsFrameGenHint_.find("turns NVIDIA Reflex on by itself") != std::string::npos,
                 "...and the advice says DLSS frame generation turns Reflex on itself");
        at_check(check_graphics_settings(graphicsWork_).empty(), "...but the value is valid, it only cannot run here");
        graphicsWork_.frameGenMode = "fsrr";
        graphicsWork_.frameGenMinBaseFps = 2000;
    });
    step(4, [this] {
        const auto problems = check_graphics_settings(graphicsWork_);
        at_check(problems.size() == 2 && problems[0].pointer == "/render/frameGeneration/mode" &&
                     problems[0].message.find("fsr") != std::string::npos &&
                     problems[1].pointer == "/render/frameGeneration/minBaseFps",
                 "a misspelt mode and a minimum out of range are named with their pointers");
        at_check(!at_enabled("gfx:save"), "...and Save stays disabled");
        pendingFocus_ = "Graphics";
    });
    click("gfx:revert");
    step(4, [this] {
        at_check(graphicsWork_.frameGenMode == "fsr" && graphicsWork_.frameGenMinBaseFps == 45,
                 "Revert reads the saved frame generation again");
        graphicsWork_.frameGenMode = "off";
        graphicsWork_.frameGenMinBaseFps = 60;
        pendingFocus_ = "Graphics";
    });
    click("gfx:save");
    step(5, [this, project_file] {
        const std::string text = read_file(project_file("factoria.json"));
        at_check(text.find("frameGeneration") == std::string::npos && text.find("\"spatial\"") != std::string::npos,
                 "Save with the mode off and the minimum at 60 removes render.frameGeneration and keeps the rest");
        auto back = read_graphics_settings(project_dir());
        at_check(back.ok() && back->frameGenMode == "off" && back->frameGenMinBaseFps == 60,
                 "...and the reader finds the default");
        pendingFocus_ = "Graphics";
    });

    // A range the controller cannot use (min above max) is named and Save stays off.
    step(2, [this] {
        graphicsWork_.dynamic.minScale = 0.9f;
        graphicsWork_.dynamic.maxScale = 0.7f;
    });
    step(4, [this] {
        const auto problems = check_graphics_settings(graphicsWork_);
        at_check(problems.size() == 1 && problems[0].pointer == "/render/dynamicResolution/minScale",
                 "a minimum scale above the maximum is named with its pointer");
        at_check(!at_enabled("gfx:save"), "...and Save stays disabled");
        pendingFocus_ = "Graphics";
    });

    // Put the project back as it was.
    step(2, [this, project_file, original] {
        write_file(project_file("factoria.json"), *original);
        showGraphics_ = false;
        graphicsDir_.clear();
        graphicsWork_ = graphicsSaved_ = GraphicsSettings{};
        graphicsSupport_ = Json();  // the renderer's own table again
        graphicsSupportAt_ = 0.0;
        graphicsSupportPinned_ = false;
        graphicsSupportStale_ = true;
    });
}

}  // namespace fa::editor
