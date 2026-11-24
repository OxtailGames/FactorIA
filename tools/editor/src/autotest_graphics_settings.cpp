// Autotest section Q4: the Graphics settings window (View > Graphics, graphics_settings_panel.cpp). It opens the window from
// the menu, picks an upscaler mode and a preset with real clicks on the combos (the popups' items), Saves, and checks
// factoria.json on disk (only the three keys of the window change), a wrong value (set as a script would) that disables Save and
// is named with its pointer, and Revert. The test project's factoria.json is put back at the end. Every wait counts frames.
#include <memory>

#include "autotest_common.h"
#include "editor_internal.h"
#include "graphics_settings_model.h"

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
    });
}

}  // namespace fa::editor
