// Camera.showTags / Camera.hideTags: which entities a camera draws and picks. One rule, used by the renderer (everything a camera
// draws in world space), the pointer (Interactable hit tests, the mesh that shows a render target), `factoria validate` and the
// editor, so what is drawn and what can be clicked never disagree.
//
// A camera draws entity `e` when (showTags is empty OR `e` or one of its ancestors has one of showTags) AND neither `e` nor any
// ancestor has one of hideTags. Tags are EntityInfo::tags ("tags": [...] in a scene file).
#pragma once

#include <cstdint>
#include <string>
#include <unordered_map>
#include <vector>

#include "fa/core/json.h"
#include "fa/scene/world.h"

namespace fa {

struct Camera;

// The strings of a showTags / hideTags value (an array; anything else, and elements that are not strings, are skipped).
std::vector<std::string> camera_tag_list(const Json& value);
// "" when `value` is a valid showTags / hideTags (an array of strings, without empty strings), else what is wrong, as the first
// half of an error message (the hint is the caller's). `field` is "showTags" or "hideTags".
std::string camera_tags_problem(const Json& value, const char* field);

// A camera's rule, ready to ask about entities. Cheap to copy and free to ask when both lists are empty (the usual case). With
// a list it remembers what it found per entity, so build one per frame (or per query) and drop it: it never sees a tag that
// changes afterwards.
class CameraMask {
public:
    CameraMask() = default;
    CameraMask(std::vector<std::string> show, std::vector<std::string> hide) : show_(std::move(show)), hide_(std::move(hide)) {}
    explicit CameraMask(const Camera& camera);
    // The mask of the Camera on `camera` (empty when that is not a Camera, so everything is drawn).
    static CameraMask of(const World& world, Entity camera);

    // True when the camera filters nothing.
    bool empty() const { return show_.empty() && hide_.empty(); }
    const std::vector<std::string>& show() const { return show_; }
    const std::vector<std::string>& hide() const { return hide_; }

    // Does the camera draw `e`? (An entity that is not alive is not drawn when the mask has a showTags list.)
    bool draws(const World& world, Entity e) const;

private:
    // bit 0: the entity or an ancestor has a showTags tag; bit 1: the same for hideTags.
    std::uint8_t state(const World& world, Entity e) const;

    std::vector<std::string> show_, hide_;
    mutable std::unordered_map<std::uint64_t, std::uint8_t> seen_;
};

}  // namespace fa
