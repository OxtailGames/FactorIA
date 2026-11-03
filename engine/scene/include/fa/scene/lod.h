// Level of detail of a MeshRenderer (MeshRenderer::lods): which mesh to draw at a camera distance. Pure and stateless, so the same distance
// always picks the same mesh; the renderer calls it per entity per frame.
#pragma once

#include <string>

#include "fa/scene/components.h"

namespace fa {

// The mesh of the entry of `mr.lods` with the greatest `distance` that is <= `distance`, or `mr.mesh` when none applies (nearer than the first entry,
// no entries, or entries that are malformed: not an object with a non-empty `mesh` string and a numeric `distance`). Entries are tried in the
// order given; the entry with the greatest distance among those reached wins (ties: the later one).
const std::string& lod_mesh(const MeshRenderer& mr, float distance);

}  // namespace fa
