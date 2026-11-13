// The house style of a project (assets.json "style") as data the tools can measure: the generation settings the asset
// providers read (prompt, references, palette) and the rules a check can verify (outline, lightDirection, texelsPerUnit,
// pixelArt, value, saturation, audio loudness per bus). One parser serves every reader: the generation commands
// (assets.generate_image...), `assets.check_art`, `assets.check_mix` and the style warnings of `project.validate`
// (docs/ASSETS.md, "House style"). Only the rules the project wrote are set; a check never judges a rule left out.
#pragma once

#include <map>
#include <optional>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/tooling/palette.h"

namespace fa {

// style.outline: the line around a sprite's silhouette.
struct StyleOutline {
    Color color;            // the colour of the line
    std::string colorText;  // as written ("#000000", "black")
    double width = 1.0;     // thickness in texture pixels
};

// style.value / style.saturation: an allowed range in 0..1; either end may be left out.
struct StyleRange {
    std::optional<double> min;
    std::optional<double> max;
};

// style.audio: loudness targets per mixer bus, read by assets.check_mix.
struct StyleAudio {
    std::map<std::string, double> loudnessLufs;  // bus name -> integrated loudness the sounds on that bus aim at (LUFS)
    double toleranceLu = 3.0;  // how far a sound may be from its bus target before the check warns (LU)
};

// One style.ignore entry that skips only some rules for a path.
struct StyleIgnoreRule {
    std::string path;                // file, folder ending in "/" or glob, normalized
    std::vector<std::string> rules;  // rule names (see style_rule_names)
};

struct StyleGuide {
    std::string prompt;                   // appended to every image prompt
    std::vector<std::string> references;  // project-relative images sent with every image request
    std::optional<Palette> palette;       // the colours of the style (also the palette lock of assets.generate_image)
    std::optional<StyleOutline> outline;
    std::optional<double>
        lightDirection;  // degrees: direction TOWARDS the light, counter-clockwise from +x (right), [0, 360)
    std::string lightDirectionName;       // the name it was written as ("upper-left"), empty when written as degrees
    std::optional<double> texelsPerUnit;  // texture pixels per world unit
    std::optional<bool> pixelArt;
    std::optional<StyleRange> value;       // brightness (HSV value) of the asset's darkest and lightest pixels
    std::optional<StyleRange> saturation;  // mean HSV saturation of the asset's visible pixels
    std::optional<StyleAudio> audio;
    std::vector<std::string> ignore;  // files, folders (ending in "/") or globs ("assets/ui/**") the style checks skip
    std::vector<StyleIgnoreRule>
        ignoreRules;  // style.ignore entries {path, rules}: only those rules are skipped for the path
    std::vector<std::pair<std::string, std::string>>
        roles;  // style.roles: glob -> role (ui, icon, effect), in file order

    // True when at least one rule an image check can measure is set (not just prompt, references or audio).
    bool has_art_rules() const;
    // True when `path` (project-relative) is named by `ignore` (every rule skipped).
    bool ignores(const std::string& path) const;
};

// The roles an asset can have (provenance.role, or a glob of style.roles), the style rules that do not apply to each, and the rule
// names `style.ignore` accepts. A name matches a rule of its own and every rule under it: "outline" is outline.color and outline.width.
const std::vector<std::string>& style_roles();
const std::vector<std::string>& style_rule_names();
std::vector<std::string> style_role_skips(const std::string& role);
bool style_rule_matches(const std::string& name, const std::string& rule);
// True when the style.ignore / style.roles entry `pattern` names `path`: a glob (it has * or ?), a folder (ends in "/") or a file.
bool style_path_matches(const std::string& pattern, const std::string& path);

// One mistake in the style section: where (JSON pointer from the start of assets.json), what, and the fix.
struct StyleProblem {
    std::string pointer;
    std::string message;
    std::string hint;
};

struct StyleParse {
    StyleGuide guide;                    // everything that parsed; a rule with a problem is left unset
    std::vector<StyleProblem> problems;  // unknown keys, wrong types, out-of-range values, an unreadable palette
};

// The names `lightDirection` accepts, with their angle (see StyleGuide::lightDirection).
const std::vector<std::pair<std::string, double>>& light_direction_names();
// The name closest to `degrees` ("upper-left" for 135), for messages.
std::string light_direction_label(double degrees);

// Parses the `style` object of assets.json. A palette that is an image path is read through fa::fs (the VFS project root).
// Never throws: every mistake is a StyleProblem with its pointer ("/style/outline/width"), a fix and a "did you mean".
StyleParse parse_style(const Json& style);

// The style of the project whose root is the VFS project root (assets.json, or an empty guide when there is no `style`).
StyleParse load_style_guide();

// The same for the project at `projectDir` (sets the VFS root for the call).
StyleParse load_style_guide(const std::string& projectDir);

}  // namespace fa
