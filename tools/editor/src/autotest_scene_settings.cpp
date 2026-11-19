// Autotest section Q3: the Scene settings panel (View > Scene settings, scene_settings_panel.cpp). It opens the panel
// from the menu, picks a sky material (the panel's own scene.set_component path), sees the material's params typed by
// material.info, sets one, takes it back with the param's Reset button and the material back with the field's Reset
// button (real clicks), undoes every step, and checks that a refused value changes nothing and leaves no undo step.
// Every wait counts frames or state; the panel is made to fit a 1024 x 642 window.
#include <memory>

#include "autotest_common.h"
#include "editor_internal.h"
#include "scene_settings_model.h"

namespace fa::editor {

using namespace at_support;

namespace {

const char* const kAtSkyMaterial = R"({
  "format": "factoria.material/1",
  "kind": "sky",
  "doc": "Editor autotest: a flat sky tinted by one color.",
  "shader": "shaders/at_sky.sky.glsl",
  "params": {
    "tint": { "type": "color", "default": [0.2, 0.4, 1.0, 1.0], "doc": "The sky color." },
    "strength": { "type": "float", "default": 1.0, "min": 0.0, "max": 2.0, "doc": "How strongly the tint shows." }
  }
})";
const char* const kAtSkySnippet =
    "void sky(in SkyInput i, inout SkySurface s) {\n    s.color = tint.rgb * strength;\n}\n";

}  // namespace

void Editor::at_section_Q3(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    auto depth0 = std::make_shared<std::size_t>(0);
    step(2, [this, project_file, depth0] {
        stop();
        write_file(project_file("materials/at_sky.material.json"), kAtSkyMaterial);
        write_file(project_file("shaders/at_sky.sky.glsl"), kAtSkySnippet);
        project_files_changed();
        showSceneSettings_ = false;
        *depth0 = undo_depth();
    });
    click("menu:view");
    step(3, [] {});
    click("menu:scenesettings");
    step(4, [this] {
        at_check(showSceneSettings_, "View > Scene settings shows the Scene settings panel");
        pendingFocus_ = "Scene settings";
    });
    step(4, [this] {
        at_check(at_visible("sset:label:skyColor") && at_visible("sset:label:skyMaterial") &&
                     at_visible("sset:label:skyMaterialParams"),
                 "the panel lists the sky fields: skyColor, skyMaterial and skyMaterialParams");
        at_check(!at_visible("sset:reset:skyMaterial"), "...and offers no Reset for a field at its default");
        pendingFocus_ = "Scene settings";
    });

    // A sky material picked through the panel's own path: one undo step, and the params appear typed by material.info.
    step(2, [this, depth0] {
        std::string err;
        at_check(scene_settings_edit("skyMaterial", "materials/at_sky.material.json", false, &err),
                 "picking a sky material is accepted: " + err);
        at_check(world().settings().skyMaterial == "materials/at_sky.material.json",
                 "...and writes SceneSettings.skyMaterial");
        at_check(undo_depth() == *depth0 + 1, "...as one undo step");
    });
    step(6, [this] {
        at_check(at_visible("insp:SceneSettings:matparam:tint") && at_visible("insp:SceneSettings:matparam:strength"),
                 "the panel shows one control per param of the sky material, typed by material.info");
        at_check(at_visible("sset:note"), "...and says what the material is (a sky one)");
        at_check(at_visible("sset:reset:skyMaterial"), "...and a Reset appears for the field that changed");
        pendingFocus_ = "Scene settings";
    });
    snap("editor_scene_settings.png");

    // A param: written under skyMaterialParams (merged, so the other params keep the material's default).
    step(2, [this, depth0] {
        std::string err;
        at_check(scene_settings_edit("skyMaterialParams", Json::object({{"strength", 1.5}}), true, &err),
                 "setting one param is accepted: " + err);
        const Json& p = world().settings().skyMaterialParams;
        at_check(p.is_object() && p.value("strength", 0.0) == 1.5 && !p.contains("tint"),
                 "...and writes only that param to SceneSettings.skyMaterialParams");
        at_check(undo_depth() == *depth0 + 2, "...as a second undo step");
    });
    step(6, [this] {
        at_check(at_enabled("insp:SceneSettings:matreset:strength") && !at_enabled("insp:SceneSettings:matreset:tint"),
                 "the param's Reset is enabled for the overridden param only");
        pendingFocus_ = "Scene settings";
    });
    scroll_to("insp:SceneSettings:matreset:strength", "Scene settings");
    click("insp:SceneSettings:matreset:strength");
    step(4, [this, depth0] {
        const Json& p = world().settings().skyMaterialParams;
        at_check(!p.contains("strength"), "the param's Reset button removes the override from the scene settings");
        at_check(undo_depth() == *depth0 + 3, "...as one undo step");
        pendingFocus_ = "Scene settings";
    });

    // The field's Reset: the material goes back to "" (the gradient), one step.
    scroll_to("sset:reset:skyMaterial", "Scene settings");
    click("sset:reset:skyMaterial");
    step(4, [this, depth0] {
        at_check(world().settings().skyMaterial.empty(), "the field's Reset button puts skyMaterial back to \"\"");
        at_check(undo_depth() == *depth0 + 4, "...as one undo step");
    });
    step(4, [this] {
        at_check(!at_visible("insp:SceneSettings:matparam:tint"), "with no sky material the typed params are gone");
        pendingFocus_ = "Scene settings";
    });

    // Undo walks the four steps back, redo forward again.
    step(2, [this] {
        undo();
        undo();
    });
    step(3, [this] {
        const SceneSettings& s = world().settings();
        at_check(s.skyMaterial == "materials/at_sky.material.json" && s.skyMaterialParams.is_object() &&
                     s.skyMaterialParams.value("strength", 0.0) == 1.5,
                 "two undos bring the sky material and the overridden param back");
        undo();
    });
    step(3, [this] {
        const SceneSettings& s = world().settings();
        at_check(s.skyMaterial == "materials/at_sky.material.json" && !s.skyMaterialParams.contains("strength"),
                 "a third takes the param's override away again");
        undo();
    });
    step(3, [this, depth0] {
        at_check(world().settings().skyMaterial.empty() && undo_depth() == *depth0,
                 "the fourth gives the scene its gradient again, as it was before the panel");
        redo();
    });
    step(3, [this] {
        at_check(world().settings().skyMaterial == "materials/at_sky.material.json",
                 "a redo picks the sky material again");
        undo();
    });

    // A colour through the same path, and what a refused value does: nothing, with no undo step.
    step(3, [this, depth0] {
        std::string err;
        at_check(scene_settings_edit("skyColor", Json::array({1.0, 0.0, 0.0, 1.0}), false, &err),
                 "a colour edit is accepted: " + err);
        at_check(world().settings().skyColor.r == 1.0f && world().settings().skyColor.g == 0.0f,
                 "...and writes SceneSettings.skyColor");
        at_check(undo_depth() == *depth0 + 1, "...as one undo step");
        const std::size_t depth = undo_depth();
        const bool refused = !scene_settings_edit("fogDensity", "thick", false, &err);
        at_check(refused && err.find("fogDensity") != std::string::npos,
                 "a value of the wrong type is refused, and the message names the field: " + err);
        at_check(!scene_settings_edit("nonsense", 1, false, &err) && err.find("nonsense") != std::string::npos,
                 "an unknown setting is refused and named: " + err);
        at_check(undo_depth() == depth, "...and a refused edit leaves no undo step");
        undo();
        pendingFocus_ = "Scene settings";
    });
    step(3, [this, depth0] {
        at_check(world().settings().skyColor.r != 1.0f && undo_depth() == *depth0, "Undo brings the old colour back");
    });
    step(3, [this] { showSceneSettings_ = false; });
    step(3, [this] { at_check(!at_visible("sset:label:skyColor"), "closing the panel removes it"); });
}

}  // namespace fa::editor
