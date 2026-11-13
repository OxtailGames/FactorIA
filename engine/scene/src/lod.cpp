#include "fa/scene/lod.h"

namespace fa {

const std::string& lod_mesh(const MeshRenderer& mr, float distance) {
    if (!mr.lods.is_array() || mr.lods.empty()) return mr.mesh;
    const std::string* pick = &mr.mesh;
    float best = -1.0f;
    for (const Json& e : mr.lods) {
        if (!e.is_object()) continue;
        auto m = e.find("mesh");
        auto d = e.find("distance");
        if (m == e.end() || !m->is_string() || m->get_ref<const std::string&>().empty() || d == e.end() ||
            !d->is_number())
            continue;
        const float at = d->get<float>();
        if (at <= distance && at >= best) {  // the farthest entry already reached
            best = at;
            pick = &m->get_ref<const std::string&>();
        }
    }
    return *pick;
}

}  // namespace fa
