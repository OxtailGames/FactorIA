// The string-table and font-coverage checks of project.validate (docs/LOCALIZATION.md, "factoria validate"). validate.cpp collects
// the texts the scenes and prefabs put on screen while it walks them, and hands them over with the "localization" section.
#pragma once

#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/runtime/project.h"
#include "fa/tooling/validate.h"

namespace fa::localization_detail {

// One text a scene or prefab file puts on screen: Text.text, Button.text, Toggle.label, Slider.label or TextField.placeholder.
struct SceneText {
    std::string file;      // "scenes/main.scene.json"
    std::string pointer;   // of the text field: "/entities/2/components/Button/text"
    std::string keyPointer;  // of the `key` field, whether or not it is written
    std::string component;   // "Button"
    std::string field;       // "text"
    std::string text;        // as written in the file: the text of the default language
    std::string key;         // "" = a literal text, never translated
    std::string font;        // the component's `font` ("" = the built-in DejaVu Sans)
    bool fontKnown = true;   // false: an instance of a prefab that does not override `font` (its font is in the prefab file)
};

// The texts of one entity's components (not its children). `entityPointer` is the pointer of the entity in `file`.
void collect_scene_texts(const std::string& file, const std::string& entityPointer, const Json& entity, std::vector<SceneText>& out);

// Runs the checks and appends their errors and warnings to `report`:
//  - without a section: a warning when scenes use `key` or locales/ exists, and the glyph check of every text against its own font;
//  - with one: every table (parse errors, missing and stale keys, placeholders, plural forms), every `key` of the scenes against
//    the default table, and the glyph check of tables and literal texts against the font chains of their language.
// `settings` must come from a section without issues. `projectDir` is the project folder; the checks read the VFS, which this
// call points at it for its duration.
void check_localization_content(const std::string& projectDir, const LocalizationSettings& settings, const std::vector<SceneText>& texts,
                                ValidationReport& report);

}  // namespace fa::localization_detail
