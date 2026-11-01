#include "fa/scene/camera_mask.h"

#include <algorithm>

#include "fa/scene/components.h"

namespace fa {

std::vector<std::string> camera_tag_list(const Json& value) {
    std::vector<std::string> out;
    if (!value.is_array()) return out;
    for (const Json& j : value)
        if (j.is_string()) {
            std::string s = j.get<std::string>();
            if (!s.empty() && std::find(out.begin(), out.end(), s) == out.end()) out.push_back(std::move(s));
        }
    return out;
}

std::string camera_tags_problem(const Json& value, const char* field) {
    const std::string name = std::string("Camera.") + field;
    if (value.is_null()) return {};
    if (!value.is_array()) return name + " must be an array of tag names, e.g. [\"page_left\"]";
    for (std::size_t i = 0; i < value.size(); ++i) {
        const Json& j = value[i];
        if (!j.is_string()) return name + "[" + std::to_string(i) + "] is " + j.dump() + ", not a tag name (a string)";
        if (j.get<std::string>().empty()) return name + "[" + std::to_string(i) + "] is an empty string, which no entity has as a tag";
    }
    return {};
}

CameraMask::CameraMask(const Camera& camera) : show_(camera_tag_list(camera.showTags)), hide_(camera_tag_list(camera.hideTags)) {}

CameraMask CameraMask::of(const World& world, Entity camera) {
    if (camera == kNullEntity || !world.alive(camera)) return {};
    const Camera* c = world.get<Camera>(camera);
    return c ? CameraMask(*c) : CameraMask{};
}

std::uint8_t CameraMask::state(const World& world, Entity e) const {
    if (e == kNullEntity || !world.alive(e)) return 0;
    if (const auto it = seen_.find(e.bits()); it != seen_.end()) return it->second;
    std::uint8_t s = state(world, world.parent(e));
    const std::vector<std::string>& tags = world.info(e).tags;
    if (!tags.empty()) {
        for (const std::string& t : show_)
            if (std::find(tags.begin(), tags.end(), t) != tags.end()) {
                s |= 1;
                break;
            }
        for (const std::string& t : hide_)
            if (std::find(tags.begin(), tags.end(), t) != tags.end()) {
                s |= 2;
                break;
            }
    }
    seen_.emplace(e.bits(), s);
    return s;
}

bool CameraMask::draws(const World& world, Entity e) const {
    if (empty()) return true;
    const std::uint8_t s = state(world, e);
    if (s & 2) return false;
    return show_.empty() || (s & 1) != 0;
}

}  // namespace fa
