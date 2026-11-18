// Private declarations shared by the shaders_*.cpp files (the public API is fa/tooling/shaders.h).
//
//   shaders_material.cpp  the material file: checks, platforms and dialects, the list of materials
//   shaders_generate.cpp  the top file around the snippet
//   shaders_yaml.cpp      the YAML reader for sokol-shdc's reflection
//   shaders_compile.cpp   running sokol-shdc, error mapping and hints, twins, the cache
//   shaders_commands.cpp  shader.compile, material.info, factoria validate
#pragma once

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
// The unprefixed names the template of a material kind declares at the top level of its program (vertex inputs, varyings,
// textures, samplers, uniform blocks and their members, functions, #defines), read from the bundled template files so they
// cannot drift from them. Only the sprite template has any: its params and textures must not take one (they would redefine
// it in sokol-shdc). Empty for every other kind.
const std::set<std::string, std::less<>>& template_globals(const std::string& kind);

// 1-based line of byte `offset` in `text`, and its 0-based column.
int line_of(std::string_view text, std::size_t offset);
int column_of(std::string_view text, std::size_t offset);
// The text of 1-based line `line` (without the newline); "" when out of range.
std::string line_text(std::string_view text, int line);

// The fields of the structs of the snippet contract of a material kind (mesh: SurfaceInput, Surface, VertexData; sprite:
// QuadInput, QuadSurface, QuadVertex; sky: SkyInput, SkySurface; post: PostInput, PostSurface), read from the bundled template so they
// cannot drift from it: struct name -> field names. Empty for an unknown kind or one without a template.
const std::vector<std::pair<std::string, std::vector<std::string>>>& contract_structs(const std::string& kind);

// The names of the template files of a material kind (one list per kind, the same as engine/render/CMakeLists.txt hashes).
const std::vector<std::string>& template_file_names(const std::string& kind);
// The template files the generator includes for a kind: file name (without folder) and content, sorted by name.
std::vector<std::pair<std::string, std::string>> template_files(const std::string& kind);

// True for the kinds the generator and the compiler handle (mesh and sprite); the others are refused with kind_refusal().
bool kind_is_compiled(const std::string& kind);
// Why a kind that is not compiled yet is refused for now: names the M72 package that brings it ("sky materials arrive with M72.1").
std::string kind_refusal(const std::string& kind);

// The snippet's text with CRs removed (the line numbers stay those of the file).
std::string normalize_snippet(std::string_view snippet);

}  // namespace fa::shaders_detail
