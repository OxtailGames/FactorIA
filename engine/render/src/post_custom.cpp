#include "fa/render/post_custom.h"

#include <algorithm>

#include "fa/core/strings.h"
#include "fa/scene/postprocess.h"

namespace fa::render {

namespace {

constexpr std::string_view kEntryKeys[] = {"material", "materialParams", "enabled", "position", "name"};

std::string join(const std::vector<std::string>& v) {
    std::string out;
    for (const std::string& s : v) out += (out.empty() ? "" : ", ") + s;
    return out;
}

std::string pointer_of(std::string_view base, std::string_view key) {
    return std::string(base) + "/" + std::string(key);
}

}  // namespace

// The one table. Several positions can name the same slot: a pass cannot be between two things that run fused, so
// "before the tonemap" and "after the bloom" are the same place. A built-in effect missing from the table is refused
// with the reason below.
const CustomPostPosition kCustomPostPositions[] = {
    {"after:ssao", PostSlot::Main},
    {"after:fog", PostSlot::Main},
    {"before:ssr", PostSlot::Main},
    {"after:ssr", PostSlot::AfterSsr},
    {"before:sunShafts", PostSlot::AfterSsr},
    {"after:sunShafts", PostSlot::AfterShafts},
    {"before:depthOfField", PostSlot::AfterShafts},
    {"after:motionBlur", PostSlot::AfterDof},
    {"before:bloom", PostSlot::AfterDof},
    {"after:bloom", PostSlot::AfterBloom},
    {"before:exposure", PostSlot::AfterBloom},
    {"before:radialBlur", PostSlot::AfterBloom},
    {"before:lensDistortion", PostSlot::AfterBloom},
    {"before:chromaticAberration", PostSlot::AfterBloom},
    {"before:tonemap", PostSlot::AfterBloom},
    {"after:tonemap", PostSlot::AfterTonemap},
    {"before:colorGrading", PostSlot::AfterTonemap},
    {"after:colorGrading", PostSlot::AfterGrading},
    {"before:vignette", PostSlot::AfterGrading},
    {"after:vignette", PostSlot::AfterVignette},
    {"before:sharpen", PostSlot::AfterVignette},
    {"after:sharpen", PostSlot::AfterSharpen},
    {"before:outline", PostSlot::AfterSharpen},
    {"after:outline", PostSlot::AfterOutline},
    {"before:posterize", PostSlot::AfterOutline},
    {"after:posterize", PostSlot::AfterPosterize},
    {"before:filmGrain", PostSlot::AfterPosterize},
    {"after:filmGrain", PostSlot::AfterGrain},
    {"before:colorFilter", PostSlot::AfterGrain},
};
const int kCustomPostPositionCount = int(sizeof(kCustomPostPositions) / sizeof(kCustomPostPositions[0]));

std::vector<std::string> custom_post_position_names() {
    std::vector<std::string> names;
    for (int i = 0; i < kCustomPostPositionCount; ++i) names.emplace_back(kCustomPostPositions[i].name);
    return names;
}

namespace {

// Why a position that names a real effect has no slot, or "" when the effect does not exist.
std::string why_refused(std::string_view side, std::string_view effect) {
    const PostEffect e = post_effect_from_name(effect);
    if (e == PostEffect::Count) return {};
    const std::string at = std::string(side) + ":" + std::string(effect);
    if (e == PostEffect::Ssao || e == PostEffect::Fog)
        return at + " is inside the scene's own pass (the " + std::string(effect) +
               " is part of how the scene is lit): a custom pass can only go after it, use \"after:" +
               std::string(effect) + "\".";
    if (e == PostEffect::MotionBlur || (e == PostEffect::DepthOfField && side == "after"))
        return at +
               " is not a place: the depth of field and the motion blur are drawn together, so a custom pass goes "
               "before the depth of field (\"before:depthOfField\") or after the motion blur (\"after:motionBlur\").";
    if (post_effect_is_hdr(e) && side == "after" && e != PostEffect::Bloom)
        return at + " is not a place: the exposure, the lens effects and the radial blur run fused in the final pass, "
                    "after the bloom. A custom pass goes before them, e.g. \"before:tonemap\" (or \"after:bloom\").";
    if (e == PostEffect::Pixelate)
        return at +
               " is not a place: the pixelate is not a step of its own, it moves the position every display effect "
               "reads (the picture is blocky before and after them). A custom pass goes around the effects it is made "
               "for, e.g. \"after:outline\" or \"before:posterize\".";
    return at + " is not a place: the colour filter is the last thing the frame draws, so a custom pass goes before it "
                "(\"before:colorFilter\").";
}

}  // namespace

Result<CustomPostPass> parse_custom_post_pass(const Json& entry, std::string_view pointer) {
    const std::string at(pointer);
    if (!entry.is_object())
        return make_error(
            at + ": a custom pass is an object, got " + std::string(entry.type_name()) + ".",
            "Write {\"material\": \"materials/vignette.material.json\", \"position\": \"before:tonemap\"}; "
            "the material is a kind \"post\" material (docs/shaders/SHADERS_POST.md).");
    std::vector<std::string> keys;
    for (std::string_view k : kEntryKeys) keys.emplace_back(k);
    for (auto it = entry.begin(); it != entry.end(); ++it) {
        if (std::find(keys.begin(), keys.end(), it.key()) == keys.end())
            return make_error(pointer_of(at, it.key()) + ": unknown key \"" + it.key() + "\" of a custom pass.",
                              fa::did_you_mean(it.key(), keys));
    }

    CustomPostPass out;
    auto string_of = [&](const char* key, std::string& dst, bool required) -> Result<void> {
        if (!entry.contains(key)) {
            if (required)
                return make_error(at + ": a custom pass needs \"" + key + "\".",
                                  std::string("Add \"") + key + "\": " +
                                      (std::string_view(key) == "material"
                                           ? "the project-relative path of a kind \"post\" material, e.g. "
                                             "\"materials/vignette.material.json\"."
                                           : "a string."));
            return {};
        }
        if (!entry[key].is_string())
            return make_error(pointer_of(at, key) + ": \"" + key + "\" must be a string, got " +
                              std::string(entry[key].type_name()) + ".");
        dst = entry[key].get<std::string>();
        return {};
    };
    if (auto r = string_of("material", out.material, true); !r.ok()) return r.error();
    if (out.material.empty())
        return make_error(
            pointer_of(at, "material") + ": the material path is empty.",
            "Name a kind \"post\" *.material.json of the project, e.g. \"materials/vignette.material.json\".");
    if (auto r = string_of("name", out.name, false); !r.ok()) return r.error();
    if (entry.contains("enabled")) {
        if (!entry["enabled"].is_boolean())
            return make_error(pointer_of(at, "enabled") + ": \"enabled\" must be true or false, got " +
                              std::string(entry["enabled"].type_name()) + ".");
        out.enabled = entry["enabled"].get<bool>();
    }
    if (entry.contains("materialParams")) {
        if (!entry["materialParams"].is_object())
            return make_error(
                pointer_of(at, "materialParams") + ": \"materialParams\" must be an object, got " +
                    std::string(entry["materialParams"].type_name()) + ".",
                "Give the material's params by name, e.g. {\"strength\": 0.5, \"tint\": [1, 0.8, 0.8, 1]} "
                "(`material.info` lists them).");
        out.params = entry["materialParams"];
    }
    std::string position(kCustomPostDefaultPosition);
    if (auto r = string_of("position", position, false); !r.ok()) return r.error();
    const auto found = std::find_if(kCustomPostPositions, kCustomPostPositions + kCustomPostPositionCount,
                                    [&](const CustomPostPosition& p) { return p.name == position; });
    if (found == kCustomPostPositions + kCustomPostPositionCount) {
        const std::size_t colon = position.find(':');
        std::string why;
        if (colon != std::string::npos)
            why =
                why_refused(std::string_view(position).substr(0, colon), std::string_view(position).substr(colon + 1));
        const std::vector<std::string> names = custom_post_position_names();
        std::string hint = why.empty() ? fa::did_you_mean(position, names) : why + " Valid: " + join(names) + ".";
        if (why.empty() && colon == std::string::npos)
            hint += " A position is \"before:<effect>\" or \"after:<effect>\" with an effect of PostProcess (e.g. "
                    "\"before:tonemap\").";
        return make_error(
            pointer_of(at, "position") + ": \"" + position + "\" is not a position a custom pass can take.", hint);
    }
    out.position = position;
    out.slot = found->slot;
    return out;
}

Result<std::vector<CustomPostPass>> parse_custom_post_passes(const Json& array, std::string_view pointer) {
    const std::string at(pointer);
    if (!array.is_array())
        return make_error(at + ": customPasses is an array of custom passes, got " + std::string(array.type_name()) +
                              ".",
                          "Write [] for none, or [{\"material\": \"materials/vignette.material.json\", \"position\": "
                          "\"before:tonemap\"}].");
    if (array.size() > std::size_t(kMaxCustomPostPasses))
        return make_error(at + ": " + std::to_string(array.size()) + " custom passes; at most " +
                              std::to_string(kMaxCustomPostPasses) + " per PostProcess.",
                          "Every pass costs a full-screen draw: merge effects into one material, or spread them over "
                          "volumes.");
    std::vector<CustomPostPass> out;
    for (std::size_t i = 0; i < array.size(); ++i) {
        auto r = parse_custom_post_pass(array[i], at + "/" + std::to_string(i));
        if (!r.ok()) return r.error();
        out.push_back(std::move(*r));
    }
    return out;
}

}  // namespace fa::render
