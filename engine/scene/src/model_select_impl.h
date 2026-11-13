// Private: the evaluator of selection queries (model_select.cpp) used by the edit operations (model_edit_ops.cpp). The public side is
// fa/scene/model_select.h.
#pragma once

#include <array>
#include <string>
#include <vector>

#include "fa/scene/model_select.h"
#include "model_mesh_ops.h"

namespace fa::sel {

// Centres, normals and corners of the faces in one space (the node's or the model's).
struct SpaceData {
    bool ready = false;
    std::vector<Vec3> center, normal;  // normal is unit length, or zero for a face with no area
    std::vector<std::array<Vec3, 3>> corner;
};

class Selector {
public:
    Selector(const mm::Soup& soup, const mm::Edges& edges, const ModelEditContext& context);

    // The faces (one flag per soup triangle) or edges (one flag per entry of the edge table) a query chose. Whatever is learned on the way
    // that would help when the result is empty goes to `notes`.
    std::vector<char> faces(const Json& query);
    std::vector<char> edges(const Json& query);

    std::vector<std::string> notes;

    const mm::Soup& soup() const { return s_; }
    const mm::Edges& edge_table() const { return e_; }
    const ModelEditContext& context() const { return ctx_; }
    const std::string& part_name(std::size_t tri) const;
    Vec3 face_normal(std::size_t tri) const { return node_data().normal[tri]; }
    float face_area(std::size_t tri) const { return area_[tri]; }

private:
    const SpaceData& node_data() const;
    const SpaceData& space(bool model);
    std::vector<char> face_leaf(const std::string& by, const Json& q);
    std::vector<char> edge_leaf(const std::string& by, const Json& q);
    std::vector<char> by_extreme(const Json& q, bool top);
    std::vector<char> by_region(const std::string& by, const Json& q);
    std::vector<std::string> existing_parts() const;

    const mm::Soup& s_;
    const mm::Edges& e_;
    const ModelEditContext& ctx_;
    mutable SpaceData node_, model_;
    std::vector<float> area_;
};

// What a face mask / edge mask matched, as a report (without the node's pointer and op).
ModelSelectionReport make_report(const Selector& selector, const std::vector<char>& mask, ModelSelectKind kind,
                                 const std::string& selectionDescription);
// "faces" -> "no faces matched: ..." with the notes, for an empty selection.
std::string empty_warning(const std::string& what, const std::vector<std::string>& notes);

}  // namespace fa::sel
