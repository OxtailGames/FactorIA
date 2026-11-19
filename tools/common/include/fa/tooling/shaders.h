// Custom materials, the tooling half (docs/design/CUSTOM_SHADERS.md): reads and checks `*.material.json`
// (schemas/material.schema.json), generates the sokol-shdc top file around the author's GLSL snippet and the engine's mesh
// template of its kind (engine/render/shaders/*_common.glsl, embedded), runs sokol-shdc, maps its errors back to the snippet, and keeps
// the result as one JSON "twin" per dialect (`factoria.shader/1`). Commands: "shader.compile", "material.info", and the node-graph ones in fa/tooling/material_graph.h;
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
// Per-instance params and vertex channels: a param with `"instanced": true` is left out of the uniform block and travels in
// the instance buffer (instance_layout: at most kMaterialMaxInstanceVec4 vec4, floats and small vectors packed first-fit
// in alphabetical order), so entities with different values still share one draw; the snippet reads it by its name in
// vertex() and surface(). `"vertexAttributes": ["uv1", "color1"]` declares the extra mesh channels the snippet reads as the
// globals vertex_uv1 and vertex_color1. The twin lists both ("instanced", "instanceVec4", "vertexAttributes").
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
#include "fa/render/renderer.h"
#include "fa/tooling/setup.h"

namespace fa {

inline constexpr int kMaterialMaxParams = 16;  // each padded to a vec4 (256 bytes)
inline constexpr int kMaterialMaxTextures =
    4;  // each is bound in both stages (see below), so 6 + 4 fragment and 4 vertex units: under the 16 per stage GLES3 and WebGL2 guarantee
// Where the textures of a material are bound (render_internal.h has the same numbers): the fragment stage reads texture i at view
// kMaterialFsFirstView + i and sampler kMaterialFsFirstSampler + i, the vertex stage (vertex() may sample too) at kMaterialVsFirstView + i
// and kMaterialVsFirstSampler + i, under the name fa_vs_<name>. The engine's own six views and two samplers come first.
inline constexpr int kMaterialFsFirstView = 6, kMaterialFsFirstSampler = 2;
inline constexpr int kMaterialVsFirstView = kMaterialFsFirstView + kMaterialMaxTextures,
                     kMaterialVsFirstSampler = kMaterialFsFirstSampler + kMaterialMaxTextures;
// Per-instance params ("instanced": true) travel in a second per-instance vertex buffer next to the model matrices: at most
// this many vec4 (12 floats) per instance, so the main program of a skinned mesh (11 attributes + 3 + 2 declared channels)
// stays within the 16 vertex attributes sokol and every backend allow.
inline constexpr int kMaterialMaxInstanceVec4 = 3;
// A mesh material in "full" mode (its own vertex and fragment stage) draws at most this many passes per mesh part, and its stages
// may declare this many `varying`s (GLES3 and WebGL2 guarantee 15 vec4 varyings; the engine's three flat instance varyings
// take the other three).
inline constexpr int kMaterialMaxPasses = 4;
inline constexpr int kMaterialMaxVaryings = 12;
// A sprite material's textures (kind "sprite") are read by fragment() at view kMaterialSpriteFirstView + i and sampler
// kMaterialSpriteFirstSampler + i: the 2D program's own four views and three samplers come first (render_internal.h has the same numbers).
inline constexpr int kMaterialSpriteFirstView = 4, kMaterialSpriteFirstSampler = 3;
// ... and the same textures for the vertex stage (vertex() may sample them as fa_vs_<name>): views and samplers after the fragment ones.
inline constexpr int kMaterialSpriteVsFirstView = kMaterialSpriteFirstView + kMaterialMaxTextures,
                     kMaterialSpriteVsFirstSampler = kMaterialSpriteFirstSampler + kMaterialMaxTextures;
// A sky material's textures (kind "sky") are fragment-stage only too, and the sky program binds no texture of its own, so they are views
// 0.. and samplers 0.. (render_internal.h has the same numbers).
inline constexpr int kMaterialSkyFirstView = 0, kMaterialSkyFirstSampler = 0;
inline constexpr int kComputeMaxMaterialBuffers = 4;  // storage buffers of one compute material
inline constexpr int kComputeMaxBufferFields = 16;    // fields of one buffer element
// Storage images of one compute material: the portable minimum of sg_limits.max_storage_image_bindings_per_stage (sokol_gfx.h,
// SG_MAX_PORTABLE_STORAGEIMAGE_BINDINGS_PER_STAGE), a floor on every GPU with compute.
inline constexpr int kComputeMaxMaterialImages = 4;
inline constexpr int kComputeMaxImageSize =
    8192;  // a side of a declared image; the GPU's own limit is checked on creation
inline constexpr int kComputeDefaultImageSize = 256;
// x*y*z of the workgroup size: WebGPU's default limit, a floor on every GPU (D3D11 and Metal allow 1024).
inline constexpr int kComputeMaxWorkgroupInvocations = 256;
inline constexpr int kComputeMaxWorkgroupZ =
    64;  // z of the workgroup: Direct3D 11 numthreads and the OpenGL guaranteed minimum
// A post material's textures (kind "post") are fragment-stage only, at view kMaterialPostFirstView + i and sampler
// kMaterialPostFirstSampler + i: the pass's own scene colour and prepass views (0, 1) and its two samplers come first.
inline constexpr int kMaterialPostFirstView = 2, kMaterialPostFirstSampler = 2;
// The history of a post pass (fa_history(): the pass's own output of the frame before) is a view after the material's textures; it is read
// through the engine's sampler 0.
inline constexpr int kMaterialPostHistoryView = kMaterialPostFirstView + kMaterialMaxTextures;
inline constexpr const char* kMaterialFormat = "factoria.material/1";
inline constexpr const char* kShaderTwinFormat = "factoria.shader/1";
inline constexpr const char* kMaterialAlphaCutoff = "alphaCutoff";

// ---------------------------------------------------------------------------------------------------------------
// The material file
// ---------------------------------------------------------------------------------------------------------------

struct MaterialParam {
    std::string name;
    std::string type;   // "float" | "vec2" | "vec3" | "vec4" | "color"
    Json defaultValue;  // a number, or an array of 2..4 numbers
    std::optional<double> min, max;
    std::string doc;
    bool implicit = false;  // added by the generator (alphaCutoff of a "clip" material), not written in the file
    bool instanced =
        false;  // per instance: every entity's value travels in the instance buffer, so entities with different
                // values stay in one draw; not part of the uniform block
    int components() const;  // 1, 2, 3 or 4
};

// Where an instanced param sits in the per-instance data: the vec4 index and the first float inside it.
struct InstanceSlot {
    std::string name;
    int vec4 = 0;
    int offset = 0;
    int components = 1;
};
struct InstanceLayout {
    std::vector<InstanceSlot> slots;  // alphabetical, like the params
    int vec4Count = 0;                // 0 = the material has no instanced params
};
// First fit, alphabetical: a param takes the first vec4 where its components still fit (a vec3 or vec4 never straddles two).
// More than kMaterialMaxInstanceVec4 vec4 is not an error here (parse_material reports it); vec4Count says what it needs.
InstanceLayout instance_layout(const std::vector<MaterialParam>& params);

// The mesh channels beyond position, normal, uv0, tangent and color0 a material may declare in "vertexAttributes":
// "uv1" (glTF TEXCOORD_1, vec2, read in vertex() as vertex_uv1) and "color1" (glTF COLOR_1, vec4 0..1, vertex_color1).
const std::vector<std::string>& material_vertex_attribute_names();

struct MaterialTexture {
    std::string name;
    std::string defaultPath;  // project-relative texture used when an entity gives none; "" = none
    std::string sampler;      // "linear" | "linearRepeat" | "nearest" | "nearestRepeat"
    std::string doc;
};

// One field of an element of a compute material's storage buffer (kind "compute", "buffers").
struct MaterialBufferField {
    std::string name;
    std::string type;  // "float" | "vec2" | "vec3" | "vec4" | "int" | "uint"
    std::string doc;
    int offset = 0;  // bytes from the start of an element (std430), filled in by parse_material
};

// A storage buffer a compute material declares: an array of structs the snippet reads and writes as `<name>.data[i].<field>`.
struct MaterialBuffer {
    std::string name;
    std::string access = "readWrite";  // "readWrite" | "read" (the shader only reads it)
    std::string doc;
    std::vector<MaterialBufferField> fields;  // in the order written: it is the memory layout
    int stride = 0;   // bytes of one element (std430: a multiple of 16 when it holds a vec3 or vec4)
    int binding = 0;  // the storage buffer binding of the shader (alphabetical order of the buffers)
};

// A storage image a compute material declares: a 2D texture the snippet writes (imageStore) and optionally reads (imageLoad),
// that mesh, sprite and post materials can then sample ("compute:<id>", docs/shaders/SHADERS_COMPUTE.md "Storage images").
struct MaterialImage {
    std::string name;
    std::string format =
        "rgba8";  // "rgba8" | "rgba16f" | "r32f" | "rgba32f" (the GLSL layout qualifier of the same name)
    std::string access = "write";  // "write" (imageStore only) | "readWrite" (imageLoad too)
    std::string doc;
    int width = kComputeDefaultImageSize,
        height = kComputeDefaultImageSize;  // size when compute.create_image gives none
    int binding = 0;  // the shader's view slot: after the buffers (buffers.size() + index in the alphabetical order)
};

// One draw of a full-mode mesh material (docs/shaders/SHADERS_FULL.md): the fixed-function state of that pass. Drawn in array order for
// every mesh part, each with its own programs.
struct MaterialPass {
    std::string
        name;  // identifier; the pass's programs get `#define FA_PASS_<NAME>` (upper case) and `FA_PASS <index>`
    std::string cull = "back";   // "back" | "front" | "none": the faces that are not drawn
    bool depthTest = true;       // compare with the depth buffer (less or equal)
    bool depthWrite = true;      // write the depth buffer (default: no when the pass blends)
    std::string blend = "none";  // "none" | "alpha" | "additive" | "multiply"
};

struct MaterialDef {
    std::string path;  // project-relative path of the .material.json
    std::string doc;
    std::string shader;  // project-relative path of the snippet
    std::string kind =
        "mesh";  // "mesh" | "sprite" | "sky" | "post" | "compute" (fa::material_kind_names()); every kind compiles
    std::string lighting = "pbr";      // "pbr" | "unlit" | "custom" (a mesh material whose snippet defines light())
    std::string alphaMode = "opaque";  // "opaque" | "clip" | "blend"
    bool doubleSided = false;
    std::vector<MaterialParam> params;  // alphabetical (the packing order of the uniform block); includes implicit ones
    std::vector<MaterialTexture> textures;  // alphabetical (view bindings 6.., sampler bindings 2..)
    // Kind "mesh" only. true = "mode": "full": the file holds the vertex and the fragment stage (`@common`, `@vertex`, `@fragment`
    // sections, each with its own main()) instead of a surface() snippet; passes (at least one, default one "main" pass), shadow
    // ("depth" = the engine's depth-only program, "custom" = this material's pass 0 with FA_SHADOW_PASS defined, "none").
    bool full = false;
    std::string shadow = "depth";
    bool prepass = true;  // draws in the engine's depth and normal prepass (the mesh as the MeshRenderer has it)
    std::vector<MaterialPass> passes;
    std::vector<std::string>
        vertexAttributes;  // kind "mesh" only: extra mesh channels vertex() reads (material_vertex_attribute_names()), sorted
    // Kind "compute" only: the local workgroup size the shader declares ([x, y, z], x*y*z at most
    // kComputeMaxWorkgroupInvocations) and its storage buffers (alphabetical, bindings 0..; the textures of a compute material
    // bind after them).
    int workgroupSize[3] = {64, 1, 1};
    std::vector<MaterialBuffer> buffers;
    std::vector<MaterialImage> images;  // alphabetical, view slots buffers.size().. (the textures bind after them)
    // The node graph the snippet is generated from (fa/tooling/material_graph.h); null = the snippet is hand-written. graphHash
    // is the hash of the snippet material.graph.generate wrote ("" = never generated).
    Json graph;
    std::string graphHash;
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
// The dialects a material of `kind` is compiled for: shader_dialects() for every kind except "compute", which has no glsl300es
// (GLES3 and WebGL2, hence Android and the web, have no compute shaders).
std::vector<std::string> shader_dialects_of_kind(const std::string& kind);
// The platforms a material of `kind` runs on (shader_platforms() order): all of them, except "compute": windows (D3D11), linux
// (OpenGL 4.3 or newer), macos and ios (Metal). The GPU must still support it (render.supports computeShaders): an OpenGL
// driver older than 4.3 does not.
std::vector<std::string> shader_platforms_of_kind(const std::string& kind);
// The dialect the running machine's renderer uses (hlsl5 on Windows, glsl430 on Linux, metal_macos on macOS).
std::string host_shader_dialect(const SetupContext& context = {});

// ---------------------------------------------------------------------------------------------------------------
// Generating the top file
// ---------------------------------------------------------------------------------------------------------------

struct GeneratedShader {
    std::string kind =
        "mesh";  // the material's kind (its template files and template hash): "mesh", "sprite", "sky" or "compute"
    std::string top;  // the sokol-shdc input
    std::vector<int>
        snippetLine;  // per line of `top` (index = line - 1): the 1-based line of the snippet it holds, 0 = generated
    bool hasVertex = false;  // the snippet defines vertex()
    bool hasSurface =
        false;  // the snippet defines surface() (a sprite material: fragment(), a sky material: sky(), a post material: post())
    bool hasLight = false;    // lighting "custom": the snippet defines light()
    bool hasAmbient = false;  // lighting "custom": the snippet defines ambient()
    bool hasLighting =
        false;  // the snippet defines lighting(in SurfaceInput, in Surface), the whole light loop (lighting "custom")
    bool lightingWithoutCustom =
        false;                // a pbr or unlit snippet defines lighting(in SurfaceInput, ...): the compiler refuses it
    bool hasCompute = false;  // the snippet defines compute() (kind "compute")
    std::string
        stateKey;  // twin fields that the top file does not hold (a full material's passes): part of the cache key
    std::vector<std::string>
        programs;  // post: "post". Sprite: "quad", "quad_plain". Sky: "sky". Compute: "compute". Mesh: "mesh", "mesh_skin", with vertex() or "clip" "shadow", "shadow_skin", and "prepass", "prepass_skin"
    std::vector<std::string>
        defines;  // for --defines: FA_MATERIAL (sprite), FA_HAS_VERTEX, FA_ALPHA_CLIP, FA_CUSTOM_LIGHT, FA_HAS_AMBIENT (mesh),
                  // FA_INST_1..3 (the vec4 of per-instance data), FA_CH_UV1, FA_CH_COLOR1 (declared vertexAttributes)
};

// Builds the top file of the design: the material block(s) in alphabetical order, the textures, the snippet (surface() only
// in the fragment stage, vertex() only in the vertex stage, everything else in both), `@include mesh_common.glsl` (a sprite material: quad_common.glsl, a sky material: sky_common.glsl) and the
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
    std::string source;  // the offending line of the snippet, as written
    Json to_json() const;
    std::string to_string() const;  // "file:line:col: error: message", the line quoted, "hint: ..."
};

struct ShaderCompileOptions {
    SetupContext setup;                 // env (SOKOL_SHDC), run (process runner), host...
    std::vector<std::string> dialects;  // empty = every dialect
    bool useCache = true;
};

struct ShaderCompileResult {
    bool ok = false;
    std::vector<std::string> dialects;  // the dialects asked for (all compiled when ok)
    // The dialects asked for that the kind of the material has no shader for (a compute material and glsl300es): not in
    // `dialects` nor in `twins`, which may then be empty with ok true.
    std::vector<std::string> skippedDialects;
    std::vector<ShaderIssue> errors;
    std::map<std::string, Json> twins;  // slang -> the factoria.shader/1 document (only when ok)
    int cacheHits = 0;                  // dialects served from .factoria/shader-cache
    MaterialDef material;               // as parsed (valid when the material file was)
    GeneratedShader generated;
};

// How to get sokol-shdc, for the errors and warnings that say it is missing or would not start: `factoria setup shaders`,
// SOKOL_SHDC and, on Windows, that Windows Defender may have quarantined sokol-shdc.exe as a false positive.
std::string sokol_shdc_missing_hint(const SetupContext& context);
// SHA-256 of the template files of a material kind (fa::material_template_hash: the value this build of the renderer checks
// twins against); "" when the kind has no template or none is bundled. "mesh-full" is the template of a full-mode mesh material
// (fa::mesh_full_template_hash).
std::string shader_template_hash(const std::string& kind = "mesh");
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
void register_shader_commands(CommandRegistry& registry, const std::string& projectDir,
                              const SetupContext& context = {});

// The compiler the engine calls (EngineConfig::shaderCompiler) for the materials of `projectDir`: compiles the material for
// one dialect (cached under .factoria/shader-cache) and returns its twin. A failed compile returns an Error whose message
// is every issue (file:line:col, the quoted line) and whose hint is the first issue's hint.
ShaderCompiler make_engine_shader_compiler(const std::string& projectDir, const SetupContext& context = {});

}  // namespace fa
