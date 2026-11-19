// "shader.compile", "material.info" and the material step of `factoria validate`.
#include <algorithm>
#include <filesystem>

#include "fa/core/strings.h"
#include "fa/tooling/shaders.h"
#include "fa/tooling/validate.h"
#include "shaders_internal.h"
#include "util.h"

namespace fa {

namespace stdfs = std::filesystem;

namespace {

// The project-relative path a command argument names: as written, or with ".material.json" added.
std::string resolve_material(const std::string& projectDir, const std::string& arg) {
    if (arg.empty())
        throw CommandError(
            "invalid_argument", "material is empty",
            "Pass the project-relative path of a *.material.json, e.g. \"materials/water.material.json\".");
    const stdfs::path p = stdfs::path(arg).lexically_normal();
    if (p.is_absolute() || p.generic_string().rfind("..", 0) == 0)
        throw CommandError("invalid_argument", "material '" + arg + "' is not inside the project",
                           "Pass a path relative to the project root, e.g. \"materials/water.material.json\".");
    std::error_code ec;
    for (const std::string& candidate : {p.generic_string(), p.generic_string() + ".material.json"})
        if (stdfs::is_regular_file(stdfs::path(projectDir) / candidate, ec)) return candidate;
    const std::vector<std::string> all = find_material_files(projectDir);
    throw CommandError("not_found", "no material '" + arg + "' in the project",
                       all.empty()
                           ? "The project has no *.material.json yet: create one (schema schemas/material.schema.json, "
                             "`docs.read` it) next to a snippet shaders/<name>.surface.glsl."
                           : did_you_mean(arg, all),
                       Json::object({{"materials", Json(all)}}));
}

Json issues_json(const std::vector<ShaderIssue>& issues) {
    Json arr = Json::array();
    for (const ShaderIssue& i : issues) arr.push_back(i.to_json());
    return arr;
}

Json param_json(const MaterialParam& p) {
    Json j = Json::object({{"name", p.name}, {"type", p.type}, {"default", p.defaultValue}});
    if (p.min) j["min"] = *p.min;
    if (p.max) j["max"] = *p.max;
    j["doc"] = p.doc;
    if (p.implicit) j["implicit"] = true;
    if (p.instanced) j["instanced"] = true;
    return j;
}

// runsOn / notOn: the platforms a material of `kind` has shaders for (shader_platforms_of_kind) and the ones it has none for.
void add_platforms(Json& out, const std::string& kind) {
    const std::vector<std::string> runsOn = shader_platforms_of_kind(kind);
    std::vector<std::string> notOn;
    for (const std::string& p : shader_platforms())
        if (std::find(runsOn.begin(), runsOn.end(), p) == runsOn.end()) notOn.push_back(p);
    out["runsOn"] = Json(runsOn);
    out["notOn"] = Json(notOn);
}

const char* const kSnippetContract =
    "The snippet is GLSL 450 (Vulkan style) with no @ tags and no main: for a mesh material `void surface(in "
    "SurfaceInput i, inout Surface s)` is required and `void vertex(inout VertexData v)` optional; for a \"sprite\" "
    "material `void fragment(in QuadInput i, inout QuadSurface s)` is required and `void vertex(inout QuadVertex v)` "
    "optional; for a \"sky\" material `void sky(in SkyInput i, inout SkySurface s)` is required (no vertex()); for a "
    "\"post\" material `void post(in PostInput i, inout PostSurface s)` is required (no vertex()). Params are "
    "globals named like the JSON keys; textures are sampled with "
    "texture(sampler2D(name, name_smp), uv); names starting with fa_ are the engine's.";

}  // namespace

void register_shader_commands(CommandRegistry& registry, const std::string& projectDir, const SetupContext& context) {
    {
        CommandInfo info;
        info.name = "shader.compile";
        info.category = "shader";
        info.readOnly = true;
        info.summary = "Compile a custom material's GLSL snippet for the dialects of some platforms and report errors "
                       "with file, line and fixes.";
        info.description =
            "Checks the material file (*.material.json, schemas/material.schema.json) and compiles its "
            "snippet with sokol-shdc, injected into the engine's mesh, 2D (sprite), sky, post-process or compute "
            "shader, for every shader dialect "
            "of "
            "the platforms asked (default: all six: hlsl5 for Windows, glsl430 for Linux, metal_macos, "
            "metal_ios and metal_sim for macOS and iOS, glsl300es for Android and web). Some errors exist in "
            "one dialect only (a gradient inside a loop is fine in GLSL and refused by HLSL), so compile for "
            "the platforms you ship. Returns {ok, material, dialects, errors: [{file, line, column, message, "
            "hint, source}], cached, kind, runsOn, notOn, skippedDialects}: `kind` is \"mesh\" (default), \"sprite\", "
            "\"sky\", \"post\" or \"compute\". A "
            "snippet error is mapped to the line of your snippet, with the "
            "offending line in `source` and a fix in `hint` (an unknown field of Surface gets \"did you mean "
            "albedo?\", texture(waves, uv) gets the separate-sampler form); a mistake in the material file "
            "has a JSON `pointer` instead of a line. Fix the file and call again until ok, then look at the "
            "result with game.screenshot. Results are cached in .factoria/shader-cache by content, so an "
            "unchanged material compiles instantly." FA_COMMAND_DETAILS
            "A compute material (a snippet defining void compute(in ComputeInput i) over storage buffers, run by "
            "compute.dispatch) has no shader for android and web (GLES3 and WebGL2 have no compute shaders): `runsOn` "
            "and `notOn` list the platforms the kind has shaders for, asking for those platforms compiles nothing and "
            "lists glsl300es in `skippedDialects`. "
            "Needs sokol-shdc: the factoria downloads carry it next to factoria; otherwise `factoria setup "
            "shaders` installs it, or set SOKOL_SHDC." +
            std::string(kSnippetContract) +
            " Example: {\"material\": \"materials/water.material.json\", \"platforms\": [\"windows\", \"web\"]}";
        info.inputSchema = Json::parse(R"({
          "type":"object","required":["material"],
          "properties":{
            "material":{"type":"string","description":"Project-relative path of the material, e.g. materials/water.material.json (the .material.json suffix may be left out)."},
            "platforms":{"type":"array","items":{"type":"string","enum":["windows","linux","macos","ios","android","web"]},
                         "description":"Platforms whose shader dialects to compile for. Omit for all."}
          }})");
        const std::string dir = projectDir;
        registry.add(info, [dir, context](const Json& args) {
            const std::string material = resolve_material(dir, tooling_detail::arg_string(args, "material", true));
            std::vector<std::string> platforms;
            if (args.contains("platforms") && args["platforms"].is_array())
                for (const Json& p : args["platforms"])
                    if (p.is_string()) platforms.push_back(p.get<std::string>());
            auto dialects = shader_dialects_for(platforms);
            if (!dialects.ok()) throw CommandError("invalid_argument", dialects.error().message, dialects.error().hint);
            ShaderCompileOptions options;
            options.setup = context;
            options.dialects = *dialects;
            auto result = compile_material(dir, material, options);
            if (!result.ok()) throw CommandError("unavailable", result.error().message, result.error().hint);
            Json out = Json::object({{"ok", result->ok},
                                     {"material", material},
                                     {"dialects", Json(result->dialects)},
                                     {"errors", issues_json(result->errors)},
                                     {"cached", result->cacheHits},
                                     {"kind", result->material.kind}});
            add_platforms(out, result->material.kind);
            out["skippedDialects"] = Json(result->skippedDialects);
            if (!result->skippedDialects.empty())
                out["note"] = "The " + result->material.kind + " material has no shader for " +
                              join(result->skippedDialects, ", ") + ": it runs on " +
                              join(shader_platforms_of_kind(result->material.kind), ", ") +
                              " only (GLES3 and WebGL2 have no compute shaders).";
            if (!result->errors.empty()) {
                std::string text;
                for (const ShaderIssue& i : result->errors) text += (text.empty() ? "" : "\n") + i.to_string();
                out["report"] = text;
            }
            return out;
        });
    }
    {
        CommandInfo info;
        info.name = "material.info";
        info.category = "material";
        info.readOnly = true;
        info.summary = "Describe a custom material: lighting, alpha mode, params with types, defaults, ranges and "
                       "docs, textures, programs and compile state.";
        info.description =
            "Reads a *.material.json (schemas/material.schema.json) and returns {material, doc, kind, shader, "
            "lighting, alphaMode, doubleSided, params: [{name, type, default, min?, max?, doc, implicit?, "
            "instanced?}], "
            "textures: [{name, default, sampler, doc}], vertexAttributes?, programs, compile: {state, dialect, "
            "toolFound, hint?}}. "
            "`kind` is \"mesh\" (default), \"sprite\", \"sky\", \"post\" or \"compute\". "
            "params are listed in the order of the uniform block (alphabetical); `implicit` marks "
            "alphaCutoff, which alphaMode \"clip\" adds by itself. "
            "compile.state is \"compiled\" when the cache holds this exact material for this machine's "
            "dialect, else \"not_compiled\" (run shader.compile); nothing is compiled by this command. "
            "A material file with errors returns them (JSON pointer, message, fix). Example: "
            "{\"material\": \"materials/water.material.json\"}" FA_COMMAND_DETAILS
            "`lighting` is \"pbr\", \"unlit\" or \"custom\" (the snippet defines light(), the engine's light loop "
            "calls it once per light). "
            "`programs` are the shader programs the material makes: mesh, mesh_skin, prepass and prepass_skin, plus "
            "shadow and shadow_skin when the snippet defines vertex() or the alpha mode is clip; a sprite "
            "material makes quad and quad_plain, a sky material one program, sky, a post material one, post. "
            "A compute material also returns workgroupSize [x, y, z] and buffers [{name, binding, access, stride, "
            "doc, fields: [{name, type, offset, doc}]}] (std430 layout); `runsOn` and `notOn` list the platforms the "
            "kind has shaders for (compute: not android or web). "
            "`instanced` marks a mesh param whose value every entity gives itself inside ONE instanced draw (it "
            "travels in the instance buffer instead of the uniform block); `vertexAttributes` lists the extra mesh "
            "channels (uv1, color1) vertex() reads as vertex_uv1 and vertex_color1 (docs/SHADERS.md, \"The material "
            "file\").";
        info.inputSchema = Json::parse(R"({
          "type":"object","required":["material"],
          "properties":{"material":{"type":"string","description":"Project-relative path of the material, e.g. materials/water.material.json."}}})");
        const std::string dir = projectDir;
        registry.add(info, [dir, context](const Json& args) {
            const std::string path = resolve_material(dir, tooling_detail::arg_string(args, "material", true));
            MaterialParse mp = read_material(dir, path);
            if (!mp.ok()) {
                Json errors = Json::array();
                for (const MaterialIssue& e : mp.errors)
                    errors.push_back(Json::object({{"pointer", e.pointer}, {"message", e.message}, {"hint", e.hint}}));
                throw CommandError("invalid_material",
                                   path + " has " + std::to_string(mp.errors.size()) +
                                       " error(s): " + mp.errors.front().to_string(),
                                   "Fix them (schemas/material.schema.json) and run shader.compile.",
                                   Json::object({{"errors", errors}}));
            }
            const MaterialDef& m = mp.material;
            Json params = Json::array(), textures = Json::array();
            for (const MaterialParam& p : m.params) params.push_back(param_json(p));
            for (const MaterialTexture& t : m.textures)
                textures.push_back(Json::object(
                    {{"name", t.name}, {"default", t.defaultPath}, {"sampler", t.sampler}, {"doc", t.doc}}));
            std::string snippet;
            if (auto raw = tooling_detail::read_file(stdfs::path(dir) / m.shader))
                snippet = shaders_detail::normalize_snippet(*raw);
            const GeneratedShader g = generate_material_shader(m, snippet);
            const std::string dialect = host_shader_dialect(context);
            const bool compiled =
                !shader_template_hash(m.kind).empty() && stdfs::exists(shader_cache_path(dir, g, snippet, dialect));
            Json out = Json::object({{"material", path},
                                     {"doc", m.doc},
                                     {"kind", m.kind},
                                     {"shader", m.shader},
                                     {"lighting", m.lighting},
                                     {"alphaMode", m.alphaMode},
                                     {"doubleSided", m.doubleSided},
                                     {"params", params},
                                     {"textures", textures},
                                     {"programs", Json(g.programs)}});
            if (!m.vertexAttributes.empty()) out["vertexAttributes"] = Json(m.vertexAttributes);
            add_platforms(out, m.kind);
            if (m.kind == "compute") {
                const Json fields = shaders_detail::compute_twin_fields(m);
                out["workgroupSize"] = fields["workgroupSize"];
                Json buffers = Json::array();
                for (const MaterialBuffer& b : m.buffers) {
                    Json bf = Json::array();
                    for (const MaterialBufferField& f : b.fields)
                        bf.push_back(
                            Json::object({{"name", f.name}, {"type", f.type}, {"offset", f.offset}, {"doc", f.doc}}));
                    buffers.push_back(Json::object({{"name", b.name},
                                                    {"binding", b.binding},
                                                    {"access", b.access},
                                                    {"stride", b.stride},
                                                    {"doc", b.doc},
                                                    {"fields", bf}}));
                }
                out["buffers"] = buffers;
            }
            out["compile"] = Json::object({{"state", compiled ? "compiled" : "not_compiled"},
                                           {"dialect", dialect},
                                           {"toolFound", !find_sokol_shdc(context).empty()}});
            if (!out["compile"]["toolFound"].get<bool>()) out["compile"]["toolHint"] = sokol_shdc_missing_hint(context);
            return out;
        });
    }
    // shader.compile runs sokol-shdc on the material; its cache lives in .factoria/shader-cache.
    declare_command_capabilities(registry, {{"shader.compile", CapabilitySet{Capability::Read, Capability::Process}},
                                            {"material.info", capability_sets::reads()}});
}

std::vector<ValidationIssue> shader_validation_issues(const ShaderCompileResult& result) {
    std::vector<ValidationIssue> out;
    for (const ShaderIssue& i : result.errors) {
        std::string message = i.message;
        if (i.line > 0)
            message = "line " + std::to_string(i.line) + ", column " + std::to_string(std::max(i.column, 1)) + ": " +
                      message + "\n    " + std::to_string(i.line) + " | " + i.source;
        out.push_back({i.file, i.pointer, message, i.hint});
    }
    return out;
}

void validate_materials(const std::string& projectDir, const SetupContext& context, ValidationReport& report) {
    const std::vector<std::string> materials = find_material_files(projectDir);
    if (materials.empty()) return;
    const bool toolFound = !find_sokol_shdc(context).empty();
    int notCompiled = 0;
    ShaderCompileOptions options;
    options.setup = context;
    for (const std::string& path : materials) {
        ++report.materialsChecked;
        auto result = compile_material(projectDir, path, options);
        if (!result.ok()) {
            if (!toolFound) {
                ++notCompiled;
                continue;
            }
            report.errors.push_back({path, "", result.error().message, result.error().hint});
            continue;
        }
        for (ValidationIssue& i : shader_validation_issues(*result)) report.errors.push_back(std::move(i));
    }
    if (notCompiled > 0)
        report.warnings.push_back(
            {"", "",
             std::to_string(notCompiled) +
                 " material(s) were checked but their snippets were not compiled: sokol-shdc, the shader compiler, was "
                 "not found, so a broken snippet is only found when the game runs or is exported",
             sokol_shdc_missing_hint(context)});
    report.ok = report.errors.empty();
}

}  // namespace fa
