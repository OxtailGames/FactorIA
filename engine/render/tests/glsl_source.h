#pragma once

#include <string>

// The GLSL ES 3.00 source of one shader of a generated header (engine/render/src/shaders/<name>.glsl.h): `key` is the array sokol-shdc
// named it with ("env_fs_sh_source_glsl300es", a trailing "[" is allowed). The headers keep the text compressed
// (engine/render/src/shader_text.h) and only for the build's own backend, so shader_text_tests.cpp, which sees them all, decodes it.
// Without the terminating NUL; empty when the header has no such text.
std::string glsl_source_from_header(const std::string& headerName, const std::string& key);
