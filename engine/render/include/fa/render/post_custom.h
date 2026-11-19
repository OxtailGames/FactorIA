// Custom post-process passes (M72, "Post-process materials"): PostProcess.customPasses is a list of entries
// {material, materialParams, enabled, position, name}, each one full-screen pass drawn by a kind "post" material. This header is
// the CPU contract shared by the renderer, the postprocess.* commands and the editor: the entry format with its teaching errors,
// and the ONE table of the positions an entry can ask for ("after:ssr", "before:tonemap", ...).
//
// A position names a built-in effect and a side. The renderer has a few places ("slots") where a custom pass can be put in the
// frame graph, each between two built-in passes; a position maps to the slot that has that effect on that side. Where the slot is
// between two passes that do not fit a request (a pass cannot go between the SSAO and the scene it is part of), the position is
// refused with the list of the ones that work. Adding a place (M72.2b adds the display-referred ones) is one new slot and the
// rows that map to it in kCustomPostPositions: nothing else in the entry format changes.
#pragma once

#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa::render {

// The places of the frame graph a custom pass can be drawn at, in frame order. All of them work on scene-linear HDR colour.
enum class PostSlot : std::int32_t {
    Main,        // after the scene (its ambient occlusion and fog) is drawn, before the screen-space reflections
    AfterSsr,    // after the screen-space reflections, before the sun shafts
    AfterShafts, // after the sun shafts, before the depth of field
    AfterDof,    // after the depth of field and the motion blur, before the bloom
    AfterBloom,  // after the bloom, before the final pass (exposure, lens effects, tonemap, grading and the display looks)
    Count
};
inline constexpr int kPostSlotCount = int(PostSlot::Count);

struct CustomPostPosition {
    std::string_view name;  // "after:ssr"
    PostSlot slot;
};
// Every accepted position, in frame order. The default of an entry is kCustomPostDefaultPosition.
extern const CustomPostPosition kCustomPostPositions[];
extern const int kCustomPostPositionCount;
inline constexpr std::string_view kCustomPostDefaultPosition = "before:tonemap";
// The names of kCustomPostPositions.
std::vector<std::string> custom_post_position_names();

// One entry of PostProcess.customPasses after validation.
struct CustomPostPass {
    std::string name;       // optional label shown in logs and the editor ("" = the material's file name)
    std::string material;   // project-relative path of the kind "post" *.material.json
    Json params = Json::object();  // per-pass overrides of the material's params (MeshRenderer.materialParams semantics)
    bool enabled = true;    // false: the entry stays in the list and draws nothing
    std::string position = std::string(kCustomPostDefaultPosition);
    PostSlot slot = PostSlot::AfterBloom;
    // The entity of the PostProcess the entry came from (set by resolve_post_stack; null from parse_*), for log messages.
    std::uint64_t source = 0;
};

// One entry. `pointer` is its JSON pointer ("/customPasses/2") and starts every error message, so a command can say which entry is
// wrong. Errors teach: an unknown key lists the valid ones, an unknown position lists every position, and a position that exists
// as a built-in effect but cannot take a custom pass says why. A material that does not exist or is not a post material is NOT
// found here (this is pure data); the renderer and `shader.compile` report that.
Result<CustomPostPass> parse_custom_post_pass(const Json& entry, std::string_view pointer);

// The whole array (`pointer` = "/customPasses"). Also refuses more than kMaxCustomPostPasses entries.
inline constexpr int kMaxCustomPostPasses = 8;
Result<std::vector<CustomPostPass>> parse_custom_post_passes(const Json& array, std::string_view pointer);

}  // namespace fa::render
