// Private declarations shared by the material_graph*.cpp files (the public API is fa/tooling/material_graph.h).
//
//   material_graph_lib.cpp       the node types and the helper functions of the library
//   material_graph.cpp           checking a graph, generating its snippet, the library as JSON
//   material_graph_commands.cpp  material.graph.nodes, material.graph.validate, material.graph.generate
#pragma once

#include <string>
#include <vector>

#include "fa/tooling/material_graph.h"

namespace fa::graph_detail {

// A function of the library the generator pastes when a node it draws calls it (and the helpers it calls).
struct Helper {
    const char* name;
    std::vector<const char*> deps;
    const char* code;  // GLSL, ends with a newline
};

const std::vector<GraphNodeType>& library();
const std::vector<Helper>& helpers();  // in the order they are pasted: dependencies first

}  // namespace fa::graph_detail
