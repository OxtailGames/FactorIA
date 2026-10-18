// Custom materials, the tooling half (docs/design/CUSTOM_SHADERS.md): reads and checks `*.material.json`
// (schemas/material.schema.json), generates the sokol-shdc top file around the author's GLSL snippet and the engine's mesh
// template (engine/render/shaders/*_common.glsl, embedded), runs sokol-shdc, maps its errors back to the snippet, and keeps
// the result as one JSON "twin" per dialect (`factoria.shader/1`). Commands: "shader.compile", "material.info";
// `factoria validate` compiles every material for every dialect; `factoria export` ships the twins of the target's dialects
// (<material>.json.<slang>.shader) in place of the snippets (tools/common/src/export_shaders.cpp).
//
// Files of one material: <name>.material.json, the snippet it names (`shader`, e.g. shaders/water.surface.glsl), and
// .factoria/shader-cache/<sha256>.<slang>.shader (the compiled twins; the key hashes the generated top file, the snippet,
// the template files, the dialect, the engine version and the sokol-shdc pin, so a cache hit starts no process).
//
// alphaCutoff: `"alphaMode": "clip"` makes the generator add the float param `alphaCutoff` (default 0.5, 0..1) to the
// material by itself and define FA_ALPHA_CLIP for the template; a material may declare `alphaCutoff` as a float to change its
// default, range or doc. The snippet reads it like any param and the engine discards below it after surface().
//
// sokol-shdc is looked up with find_sokol_shdc (fa/tooling/setup.h) and started through SetupContext::run, so tests inject
// both.
#pragma once

#include <map>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/tooling/setup.h"

namespace fa {

inline constexpr int kMaterialMaxParams = 16;    // each padded to a vec4 (256 bytes)
inline constexpr int kMaterialMaxTextures = 4;   // fragment stage; the engine binds 6 of the 16 units GLES3 and WebGL2 guarantee
inline constexpr const char* kMaterialFormat = "factoria.material/1";
inline constexpr const char* kShaderTwinFormat = "factoria.shader/1";
inline constexpr const char* kMaterialAlphaCutoff = "alphaCutoff";

// ---------------------------------------------------------------------------------------------------------------
// The material file
// ---------------------------------------------------------------------------------------------------------------

struct MaterialParam {
    std::string name;
    std::string type;    // "float" | "vec2" | "vec3" | "vec4" | "color"
    Json defaultValue;   // a number, or an array of 2..4 numbers
    std::optional<double> min, max;
    std::string doc;
    bool implicit = false;  // added by the generator (alphaCutoff of a "clip" material), not written in the file
    int components() const;  // 1, 2, 3 or 4
};

struct MaterialTexture {
    std::string name;
    std::string defaultPath;  // project-relative texture used when an entity gives none; "" = none
    std::string sampler;      // "linear" | "linearRepeat" | "nearest" | "nearestRepeat"
    std::string doc;
};

struct MaterialDef {
    std::string path;    // project-relative path of the .material.json
    std::string doc;
    std::string shader;  // project-relative path of the snippet
    std::string lighting = "pbr";      // "pbr" | "unlit"
    std::string alphaMode = "opaque";  // "opaque" | "clip" | "blend"
    bool doubleSided = false;
    std::vector<MaterialParam> params;      // alphabetical (the packing order of the uniform block); includes implicit ones
    std::vector<MaterialTexture> textures;  // alphabetical (view bindings 6.., sampler bindings 2..)
};

struct MaterialIssue {
    std::string pointer;  // JSON pointer inside the material file ("/params/waveHeight/default")
    std::string message;
    std::string hint;
    std::string to_string() const;  // "pointer: message (hint: ...)"
};

struct MaterialParse {
    MaterialDef material;
    std::vector<MaterialIssue> errors;
    bool ok() const { return errors.empty(); }
};

// Checks a parsed material file. `projectDir` is where `shader` and texture defaults are looked for. `path` (project-relative)
// is stored in the result and used for nothing else.
MaterialParse parse_material(const Json& doc, const std::string& projectDir, const std::string& path = {});
// Reads and checks `<projectDir>/<path>`; a file that is not JSON is one error with line and column.
MaterialParse read_material(const std::string& projectDir, const std::string& path);
// Every *.material.json of the project (project-relative, sorted); folders starting with '.', node_modules and a top-level
// build/ are skipped, like the scene search.
std::vector<std::string> find_material_files(const std::string& projectDir);

// ---------------------------------------------------------------------------------------------------------------
// Platforms and dialects
// ---------------------------------------------------------------------------------------------------------------

// windows linux macos ios android web.
const std::vector<std::string>& shader_platforms();
// Every dialect an export can need, in the order they are compiled: hlsl5 glsl430 glsl300es metal_macos metal_ios metal_sim.
const std::vector<std::string>& shader_dialects();
// The dialects of some platforms (union, no duplicates, in shader_dialects() order); empty = all. An unknown platform is an
// error with a "did you mean".
Result<std::vector<std::string>> shader_dialects_for(const std::vector<std::string>& platforms);
// The dialect the running machine's renderer uses (hlsl5 on Windows, glsl430 on Linux, metal_macos on macOS).
std::string host_shader_dialect(const SetupContext& context = {});

// ---------------------------------------------------------------------------------------------------------------
// Generating the top file
// ---------------------------------------------------------------------------------------------------------------

struct GeneratedShader {
    std::string top;                   // the sokol-shdc input
    std::vector<int> snippetLine;      // per line of `top` (index = line - 1): the 1-based line of the snippet it holds, 0 = generated
    bool hasVertex = false;            // the snippet defines vertex()
    bool hasSurface = false;           // the snippet defines surface()
    std::vector<std::string> programs;  // "mesh", "mesh_skin" and, with vertex() or "clip", "shadow", "shadow_skin"
    std::vector<std::string> defines;   // for --defines: FA_HAS_VERTEX, FA_ALPHA_CLIP
};

// Builds the top file of the design: the material block(s) in alphabetical order, the textures, the snippet (surface() only
// in the fragment stage, vertex() only in the vertex stage, everything else in both), `@include mesh_common.glsl` and the
// programs. Comments are ignored when looking for vertex() and surface().
GeneratedShader generate_material_shader(const MaterialDef& material, std::string_view snippet);

// ---------------------------------------------------------------------------------------------------------------
// The YAML sokol-shdc writes (--format bare_yaml)
// ---------------------------------------------------------------------------------------------------------------

// Reads exactly the YAML subset sokol-shdc writes (block mappings and sequences, scalars) into JSON. Numbers and
// true/false become JSON numbers and booleans, an empty value an empty array, everything else a string.
Result<Json> parse_shdc_yaml(std::string_view text);

// ---------------------------------------------------------------------------------------------------------------
// Compiling
// ---------------------------------------------------------------------------------------------------------------

struct ShaderIssue {
    std::string file;     // "shaders/water.surface.glsl" (project-relative), or the material file for JSON errors
    std::string pointer;  // JSON pointer, for errors in the material file
    int line = 0;         // 1-based line of `file`; 0 = not applicable
    int column = 0;       // 1-based
    std::string message;
    std::string hint;
    std::string source;   // the offending line of the snippet, as written
    Json to_json() const;
    std::string to_string() const;  // "file:line:col: error: message", the line quoted, "hint: ..."
};

struct ShaderCompileOptions {
    SetupContext setup;                  // env (SOKOL_SHDC), run (process runner), host...
    std::vector<std::string> dialects;   // empty = every dialect
    bool useCache = true;
};

struct ShaderCompileResult {
    bool ok = false;
    std::vector<std::string> dialects;          // the dialects asked for (all compiled when ok)
    std::vector<ShaderIssue> errors;
    std::map<std::string, Json> twins;          // slang -> the factoria.shader/1 document (only when ok)
    int cacheHits = 0;                          // dialects served from .factoria/shader-cache
    MaterialDef material;                       // as parsed (valid when the material file was)
    GeneratedShader generated;
};

// How to get sokol-shdc, for the errors and warnings that say it is missing or would not start: `factoria setup shaders`,
// SOKOL_SHDC and, on Windows, that Windows Defender may have quarantined sokol-shdc.exe as a false positive.
std::string sokol_shdc_missing_hint(const SetupContext& context);
// SHA-256 of the template files the generator includes (name and content, sorted by name); "" when none is bundled.
std::string shader_template_hash();
// Compiles the material at `materialPath` (project-relative) for the dialects asked. Fails (Error) when sokol-shdc is needed
// and not found, or cannot be started; everything the author can fix is in result.errors.
Result<ShaderCompileResult> compile_material(const std::string& projectDir, const std::string& materialPath,
                                             const ShaderCompileOptions& options = {});
// The cache file of one dialect: <projectDir>/.factoria/shader-cache/<key>.<slang>.shader. Computed without a process.
std::string shader_cache_path(const std::string& projectDir, const GeneratedShader& generated, std::string_view snippet,
                              const std::string& slang);

// ---------------------------------------------------------------------------------------------------------------
// Commands and `factoria validate`
// ---------------------------------------------------------------------------------------------------------------

struct ValidationIssue;   // fa/tooling/validate.h
struct ValidationReport;  // fa/tooling/validate.h
// The errors of a compile the author can fix, as `factoria validate` lists them (a failed `factoria export` prints the same):
// material file errors with their JSON pointer, snippet errors with line, column and the line quoted.
std::vector<ValidationIssue> shader_validation_issues(const ShaderCompileResult& result);
// Checks every material of the project and compiles it for every dialect; adds errors and warnings to `report`. Without
// sokol-shdc the snippets are not compiled and one warning says so.
void validate_materials(const std::string& projectDir, const SetupContext& context, ValidationReport& report);

// "shader.compile" and "material.info" (category "shader"). `context` supplies the sokol-shdc lookup and the process runner.
void register_shader_commands(CommandRegistry& registry, const std::string& projectDir, const SetupContext& context = {});

}  // namespace fa
