// The `prefab` option of assets.animate_svg: the entity that plays the layers of a layered effect together.
#pragma once

#include <string>
#include <vector>

#include "fa/core/json.h"

namespace fa::assets_detail {

// What `prefab` asks for (a path, or an object {path, name, tags, size, layers, pixelArt, overwrite}), checked.
struct AnimatePrefabSpec {
    std::string rel;                                     // project-relative, ends in .prefab.json
    std::string name;                                    // the parent entity's name
    std::vector<std::string> tags;                       // the parent entity's tags
    double width = 0, height = 0;                        // the world size of every layer's Sprite
    int layerBack = -1, layerFront = 1, layerLight = 2;  // Sprite.layer of each layer
    bool pixelArt = false;
    bool overwrite = false;
};

// Reads and checks `prefab` (arg_error with a JSON pointer, a hint and a "did you mean" when wrong). `bakedLayers` are the layers of
// this call (a subset of back, front, light); `frameW` / `frameH` give the default size. `warn` collects soft complaints.
AnimatePrefabSpec parse_animate_prefab(const char* command, const Json& prefab,
                                       const std::vector<std::string>& bakedLayers, int frameW, int frameH,
                                       std::vector<std::string>& warnings);

// The prefab document: a parent with one child per layer (Back, Front, Light, in that order), each a Sprite on that layer's sheet and
// a SpriteAnimator that plays `clip`; the light child is additive. `sheets` are the texture paths in the order of `bakedLayers`.
Json build_animate_prefab(const AnimatePrefabSpec& spec, const std::vector<std::string>& bakedLayers,
                          const std::vector<std::string>& sheets, const std::string& clip);

}  // namespace fa::assets_detail
