// Private declarations shared by the shaders_*.cpp files (the public API is fa/tooling/shaders.h).
//
//   shaders_material.cpp  the material file: checks, platforms and dialects, the list of materials
//   shaders_generate.cpp  the top file around the snippet
//   shaders_yaml.cpp      the YAML reader for sokol-shdc's reflection
//   shaders_compile.cpp   running sokol-shdc, error mapping and hints, twins, the cache
//   shaders_commands.cpp  shader.compile, material.info, factoria validate
#pragma once

#include <functional>
#include <set>
#include <string>
#include <string_view>
#include <vector>

#include "fa/tooling/shaders.h"

namespace fa::shaders_detail {

// `text` with every comment (// and /* */) replaced by spaces, newlines kept, so offsets and lines stay those of `text`.
std::string blank_comments(std::string_view text);

bool ident_char(char c);  // [A-Za-z0-9_]
// A GLSL identifier: [A-Za-z_][A-Za-z0-9_]*.
bool is_identifier(std::string_view s);
// A GLSL keyword or a name of the snippet contract that a parameter or texture must not take.
bool is_reserved_word(std::string_view s);

// 1-based line of byte `offset` in `text`, and its 0-based column.
int line_of(std::string_view text, std::size_t offset);
int column_of(std::string_view text, std::size_t offset);
// The text of 1-based line `line` (without the newline); "" when out of range.
std::string line_text(std::string_view text, int line);

// The fields of the structs of the snippet contract of a material kind (mesh: SurfaceInput, Surface, VertexData; sprite:
// QuadInput, QuadSurface; sky: SkyInput, SkySurface; post: PostInput, PostSurface), read from the bundled template so they
// cannot drift from it: struct name -> field names. Empty for an unknown kind or one without a template.
const std::vector<std::pair<std::string, std::vector<std::string>>>& contract_structs(const std::string& kind = "mesh");

// The names of the template files of a material kind (one list per kind, the same as engine/render/CMakeLists.txt hashes).
const std::vector<std::string>& template_file_names(const std::string& kind);
// The template files the generator includes for a kind: file name (without folder) and content, sorted by name.
std::vector<std::pair<std::string, std::string>> template_files(const std::string& kind = "mesh");

// Why a kind other than "mesh" is refused for now: names the M72 package that brings it ("sprite materials arrive with M72.1").
std::string kind_refusal(const std::string& kind);

// The snippet's text with CRs removed (the line numbers stay those of the file).
std::string normalize_snippet(std::string_view snippet);

// ---- compute materials (shaders_compute.cpp) ----
// The rule for the names of params, textures and buffers (Checker::check_name of shaders_material.cpp): reports an error and
// returns false when `name` cannot be used; `what` is "param", "texture"...
using CheckName = std::function<bool(const std::string& pointer, const std::string& name, const char* what)>;
// std430 offsets of the fields of a buffer element and its stride.
void layout_buffer(MaterialBuffer& buffer);
// Reads "workgroupSize" and "buffers" of a material file into `m` (m.kind is already set), with JSON-pointer errors; a key that
// is not for the kind is an error too. `taken` holds the names in use (params, textures) and gets the ones the buffers take.
void parse_compute_fields(const Json& doc, MaterialDef& m, std::vector<MaterialIssue>& errors,
                          std::set<std::string>& taken, const CheckName& checkName);
// True when the (comment-free) snippet defines `void compute(...)`.
bool defines_compute_entry(const std::string& strippedSnippet);
// {"workgroupSize": [x, y, z], "buffers": [{name, binding, stride, access, fields: [{name, type, offset}]}]}: what a compute
// twin carries next to the programs, for the runtime that makes the buffers.
Json compute_twin_fields(const MaterialDef& m);

}  // namespace fa::shaders_detail

namespace fa {
// The top file of a "compute" material: params block, buffers, textures, local size, the snippet, compute_common.glsl.
GeneratedShader generate_compute_shader(const MaterialDef& material, std::string_view snippet);
}  // namespace fa
