// Custom materials, the tooling half (fa/tooling/shaders.h): the material file checks, the generated top file, the YAML
// reader, the error mapping and the cache, with an injected sokol-shdc (fixtures captured from the real tool, so they run on
// every host), and the same material compiled by the real sokol-shdc where one is installed (SOKOL_SHDC or
// `factoria setup shaders`; skipped with a message otherwise).
#include "fa/core/engine_version.h"
#include <doctest.h>

#include <algorithm>
#include <filesystem>
#include <regex>

#include "fa/core/json_schema.h"
#include "fa/tooling/bundle.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/shaders.h"
#include "fa/tooling/validate.h"
#include "fa_test_paths.h"  // FA_REPO_ROOT
#include "shaders_internal.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

const char* kGemMaterial = R"({
  "format": "factoria.material/1",
  "doc": "A pulsing gem.",
  "shader": "shaders/gem.surface.glsl",
  "params": {
    "tint": { "type": "color", "default": [0.2, 0.6, 1.0, 1.0], "doc": "Base color." },
    "pulse": { "type": "float", "default": 1.0, "min": 0.0, "max": 4.0, "doc": "Strength of the breathing glow." }
  },
  "textures": { "glow": { "sampler": "linearRepeat", "doc": "Glow mask (rgb)." } }
})";

// breathe() is a helper both stages compile; surface() runs in the fragment stage only.
const char* kGemSnippet = R"(// A pulsing gem: the albedo tinted, an emission that breathes.
float breathe(float t) {
    return 0.5 + 0.5 * sin(t * 6.2831853);
}

void surface(in SurfaceInput i, inout Surface s) {
    vec3 g = texture(sampler2D(glow, glow_smp), i.uv).rgb;
    s.albedo = tint.rgb;
    s.emission += g * pulse * breathe(fa_time.x);
}
)";

const char* kWaveMaterial = R"({
  "format": "factoria.material/1",
  "shader": "shaders/wave.surface.glsl",
  "alphaMode": "clip",
  "params": { "amp": { "type": "float", "default": 0.2, "doc": "Wave height in meters." } }
})";

// Comments mention vertex() and surface(): only the real definitions count.
const char* kWaveSnippet = R"(// void vertex(inout VertexData v) {} is how a vertex() looks, but this is a comment
/* void surface(in SurfaceInput i, inout Surface s) {} */
void vertex(inout VertexData v) {
    v.world_pos.y += sin(v.world_pos.x + fa_time.x) * amp;
}

void surface(in SurfaceInput i, inout Surface s) {
    s.alpha = fract(i.uv.x * 8.0);
}
)";

// A mistake on line 7, inside a helper that both stages compile.
const char* kBadMaterial = R"({
  "format": "factoria.material/1",
  "shader": "shaders/bad.surface.glsl",
  "params": {
    "tint": { "type": "color", "default": [1, 0, 0, 1], "doc": "Color." },
    "pulse": { "type": "float", "default": 1.0, "doc": "Strength." }
  }
})";
const char* kBadSnippet = R"(// Line 7 uses a name that does not exist.
float wobble(float x) {
    return sin(x * 6.2831853);
}

float glow(vec2 uv) {
    return wobble(uv.x) * tnt;
}

void surface(in SurfaceInput i, inout Surface s) {
    s.emission += vec3(glow(i.uv)) * pulse;
}
)";

// A sprite material: a dissolve with a mask texture (the reflection fixture shdc_sprite_hlsl5_glsl430.yaml is its compile).
const char* kSpriteMaterial = R"({
  "format": "factoria.material/1",
  "kind": "sprite",
  "doc": "Dissolves along a mask; the edge glows.",
  "shader": "shaders/dissolve2d.fragment.glsl",
  "params": {
    "amount": { "type": "float", "default": 0.0, "min": 0.0, "max": 1.0, "doc": "How much is gone." },
    "edge": { "type": "color", "default": [1.0, 0.5, 0.1, 1.0], "doc": "Color of the glowing edge." }
  },
  "textures": { "mask": { "sampler": "linearRepeat", "doc": "Dissolve mask (r)." } }
})";

// fragment() is the sprite entry point and, as surface() of a mesh material, runs in the fragment stage only.
const char* kSpriteSnippet = R"(void fragment(in QuadInput i, inout QuadSurface s) {
    float n = texture(sampler2D(mask, mask_smp), i.uv).r;
    if (n < amount) discard;
    s.color.rgb = mix(s.color.rgb, edge.rgb, step(n, amount + 0.05));
}
)";

// A post material: a tint (the reflection fixture shdc_post_hlsl5_glsl430.yaml is its compile).
const char* kPostMaterial = R"({
  "format": "factoria.material/1",
  "kind": "post",
  "doc": "Multiplies the picture by a colour.",
  "shader": "shaders/tint.post.glsl",
  "params": { "tint": { "type": "color", "default": [1.0, 0.25, 0.25, 1.0], "doc": "Multiplied into the picture." } }
})";

const char* kPostSnippet = R"(void post(in PostInput i, inout PostSurface s) {
    s.color.rgb *= fa_scene_rgb(tint.rgb);
}
)";

std::string fixture(const std::string& name) {
    return testing::read_all(stdfs::path(FA_REPO_ROOT) / "tools/common/tests/fixtures" / name);
}

struct Project {
    testing::TempDir dir;
    Project() {
        write("materials/gem.material.json", kGemMaterial);
        write("shaders/gem.surface.glsl", kGemSnippet);
        write("materials/wave.material.json", kWaveMaterial);
        write("shaders/wave.surface.glsl", kWaveSnippet);
        write("materials/bad.material.json", kBadMaterial);
        write("shaders/bad.surface.glsl", kBadSnippet);
        write("textures/waves.png", "x");
    }
    void write(const std::string& rel, const std::string& text) { testing::write_all(dir.path / rel, text); }
    void add_sprite() {
        write("materials/dissolve2d.material.json", kSpriteMaterial);
        write("shaders/dissolve2d.fragment.glsl", kSpriteSnippet);
    }
    void add_post() {
        write("materials/tint.material.json", kPostMaterial);
        write("shaders/tint.post.glsl", kPostSnippet);
    }
    std::string str() const { return dir.str(); }
};

// A stand-in for sokol-shdc: counts runs, checks it was given the files it needs, and either "compiles" (writes the captured
// reflection and placeholder sources) or fails with the given stderr.
struct FakeShdc {
    int calls = 0;
    std::vector<std::vector<std::string>> argvs;
    std::string reflection;  // the YAML to write
    std::string stderrText;  // when set, the run fails with exit code 10 and this stderr
    ProcessRunner runner() {
        return [this](const ProcessOptions& o) -> Result<ProcessResult> {
            ++calls;
            argvs.push_back(o.argv);
            const stdfs::path work(o.workingDir);
            CHECK(stdfs::exists(work / "top.glsl"));
            CHECK((stdfs::exists(work / "mesh_common.glsl") || stdfs::exists(work / "quad_common.glsl") ||
                   stdfs::exists(work / "post_common.glsl")));
            ProcessResult r;
            if (!stderrText.empty()) {
                r.exitCode = 10;
                r.stderrText = stderrText;
                return r;
            }
            testing::write_all(work / "out/m_fa_mat_reflection.yaml", reflection);
            static const std::regex path(R"(\n\s*path: (\S+))");
            for (auto it = std::sregex_iterator(reflection.begin(), reflection.end(), path);
                 it != std::sregex_iterator(); ++it)
                testing::write_all(work / (*it)[1].str(), "// generated source " + (*it)[1].str() + "\n");
            r.exitCode = 0;
            return r;
        };
    }
    SetupContext context(const std::string& home) {
        SetupContext c;
        c.env = [](const std::string& n) {
            return n == "SOKOL_SHDC" ? std::string("/fake/sokol-shdc") : std::string();
        };
        c.home = home;
        c.host = "linux";
        c.run = runner();
        return c;
    }
};

// The line of the generated top file that holds line `snippetLine` of the snippet.
int top_line_of(const GeneratedShader& g, int snippetLine) {
    for (std::size_t i = 0; i < g.snippetLine.size(); ++i)
        if (g.snippetLine[i] == snippetLine) return int(i) + 1;
    return 0;
}

MaterialParse parse(const char* json, const std::string& dir = {}) {
    return parse_material(Json::parse(json), dir, "materials/x.material.json");
}

bool has_error(const MaterialParse& p, const std::string& pointer, const std::string& text = {}) {
    return std::any_of(p.errors.begin(), p.errors.end(), [&](const MaterialIssue& e) {
        return e.pointer == pointer &&
               (e.message.find(text) != std::string::npos || e.hint.find(text) != std::string::npos);
    });
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------------
// The material file
// ---------------------------------------------------------------------------------------------------------------

TEST_CASE("material: a valid file is read with params and textures in alphabetical order, and the schema accepts it") {
    Project p;
    const MaterialParse m = read_material(p.str(), "materials/gem.material.json");
    REQUIRE(m.ok());
    CHECK(m.material.lighting == "pbr");
    CHECK(m.material.alphaMode == "opaque");
    REQUIRE(m.material.params.size() == 2);
    CHECK(m.material.params[0].name == "pulse");  // alphabetical, not file order
    CHECK(m.material.params[1].type == "color");
    CHECK(m.material.params[0].max.value() == 4.0);
    REQUIRE(m.material.textures.size() == 1);
    CHECK(m.material.textures[0].sampler == "linearRepeat");

    auto schema = bundled_read("schemas/material.schema.json");
    REQUIRE(schema.has_value());
    CHECK(validate_json(Json::parse(*schema), Json::parse(kGemMaterial)).empty());
    CHECK(validate_json(Json::parse(*schema), Json::parse(kWaveMaterial)).empty());
}

TEST_CASE("material: alphaMode clip adds the float param alphaCutoff unless the file declares it") {
    const MaterialParse implicit = parse(kWaveMaterial);
    REQUIRE(implicit.ok());
    REQUIRE(implicit.material.params.size() == 2);
    CHECK(implicit.material.params[0].name == "alphaCutoff");
    CHECK(implicit.material.params[0].implicit);
    CHECK(implicit.material.params[0].defaultValue.get<double>() == 0.5);

    const MaterialParse declared = parse(R"({"format":"factoria.material/1","shader":"s.glsl","alphaMode":"clip",
        "params":{"alphaCutoff":{"type":"float","default":0.1,"min":0,"max":0.5,"doc":"Leaf cutoff."}}})");
    REQUIRE(declared.ok());
    REQUIRE(declared.material.params.size() == 1);
    CHECK_FALSE(declared.material.params[0].implicit);
    CHECK(declared.material.params[0].defaultValue.get<double>() == 0.1);

    const MaterialParse wrongType = parse(R"({"format":"factoria.material/1","shader":"s.glsl","alphaMode":"clip",
        "params":{"alphaCutoff":{"type":"vec2","default":[0,1],"doc":"x"}}})");
    CHECK(has_error(wrongType, "/params/alphaCutoff/type", "float"));
}

TEST_CASE("material: errors name the JSON pointer, the problem and the fix") {
    // lighting and alphaMode with did you mean
    auto bad = parse(R"({"format":"factoria.material/1","shader":"s.glsl","lighting":"pbs","alphaMode":"clipp"})");
    CHECK(has_error(bad, "/lighting", "Did you mean 'pbr'?"));
    CHECK(has_error(bad, "/alphaMode", "Did you mean 'clip'?"));
    // unknown key, missing format
    bad = parse(R"({"shader":"s.glsl","doubleSide":true})");
    CHECK(has_error(bad, "/doubleSide", "doubleSided"));
    CHECK(has_error(bad, "/format"));
    // param default of the wrong type, wrong arity, out of range
    bad = parse(R"({"format":"factoria.material/1","shader":"s.glsl","params":{
        "waveHeight":{"type":"float","default":"0.15","doc":"d"},
        "flow":{"type":"vec2","default":[1,2,3],"doc":"d"},
        "col":{"type":"color","default":0.5,"doc":"d"},
        "big":{"type":"float","default":9,"min":0,"max":2,"doc":"d"},
        "range":{"type":"float","default":1,"min":3,"max":2,"doc":"d"},
        "kind":{"type":"flaot","default":1,"doc":"d"},
        "nodoc":{"type":"float","default":1}}})");
    CHECK(has_error(bad, "/params/waveHeight/default", "expected a number"));
    CHECK(has_error(bad, "/params/flow/default", "needs 2 numbers"));
    CHECK(has_error(bad, "/params/col/default", "array of 4 numbers"));
    CHECK(has_error(bad, "/params/big/default", "above max"));
    CHECK(has_error(bad, "/params/range/min", "greater than max"));
    CHECK(has_error(bad, "/params/kind/type", "Did you mean 'float'?"));
    CHECK(has_error(bad, "/params/nodoc/doc", "needs a doc"));
}

TEST_CASE("material: names are GLSL identifiers that are not fa_ names or keywords, and the limits say why") {
    auto bad = parse(R"({"format":"factoria.material/1","shader":"s.glsl","params":{
        "fa_speed":{"type":"float","default":1,"doc":"d"},
        "float":{"type":"float","default":1,"doc":"d"},
        "2fast":{"type":"float","default":1,"doc":"d"},
        "bad-name":{"type":"float","default":1,"doc":"d"},
        "surface":{"type":"float","default":1,"doc":"d"}}})");
    CHECK(has_error(bad, "/params/fa_speed", "reserved for the engine"));
    CHECK(has_error(bad, "/params/float", "keyword"));
    CHECK(has_error(bad, "/params/2fast", "not a GLSL identifier"));
    CHECK(has_error(bad, "/params/bad-name", "not a GLSL identifier"));
    CHECK(has_error(bad, "/params/surface", "contract"));

    // 17 params
    Json many = Json::object({{"format", "factoria.material/1"}, {"shader", "s.glsl"}, {"params", Json::object()}});
    for (int i = 0; i < 17; ++i)
        many["params"]["p" + std::to_string(i)] = Json::object({{"type", "float"}, {"default", 1}, {"doc", "d"}});
    CHECK(has_error(parse_material(many, "", "x"), "/params", "at most 16"));
    many["params"].erase("p16");
    CHECK(parse_material(many, "", "x").ok());

    // 5 textures: the limit error gives its reason
    Json five = Json::object({{"format", "factoria.material/1"}, {"shader", "s.glsl"}, {"textures", Json::object()}});
    for (int i = 0; i < 5; ++i) five["textures"]["t" + std::to_string(i)] = Json::object({{"doc", "d"}});
    const MaterialParse tooMany = parse_material(five, "", "x");
    CHECK(has_error(tooMany, "/textures", "at most 4"));
    CHECK(has_error(tooMany, "/textures", "GLES3 and WebGL2"));

    // texture sampler and doc
    bad = parse(
        R"({"format":"factoria.material/1","shader":"s.glsl","textures":{"a":{"sampler":"linearRepeet"},"b":{"doc":"d","default":"textures/none.png"}}})");
    CHECK(has_error(bad, "/textures/a/sampler", "linearRepeat"));
    CHECK(has_error(bad, "/textures/a/doc"));
}

TEST_CASE("material: the shader path is relative to the project root and must exist") {
    Project p;
    CHECK(has_error(parse(R"({"format":"factoria.material/1","shader":"/etc/x.glsl"})", p.str()), "/shader",
                    "relative to the project root"));
    CHECK(has_error(parse(R"({"format":"factoria.material/1","shader":"../x.glsl"})", p.str()), "/shader",
                    "relative to the project root"));
    CHECK(has_error(parse(R"({"format":"factoria.material/1","shader":"shaders\\x.glsl"})", p.str()), "/shader",
                    "forward slashes"));
    CHECK(has_error(parse(R"({"format":"factoria.material/1","shader":"shaders/gem.surface.gls"})", p.str()), "/shader",
                    "Did you mean 'shaders/gem.surface.glsl'?"));
    CHECK(has_error(
        parse(
            R"({"format":"factoria.material/1","shader":"shaders/gem.surface.glsl","textures":{"t":{"doc":"d","default":"textures/wave.png"}}})",
            p.str()),
        "/textures/t/default", "Did you mean 'textures/waves.png'?"));
    // a file that is not JSON: one error with line and column
    p.write("materials/broken.material.json", "{\n  \"format\": ,\n}");
    const MaterialParse broken = read_material(p.str(), "materials/broken.material.json");
    REQUIRE_FALSE(broken.ok());
    CHECK(broken.errors[0].message.find("broken.material.json") != std::string::npos);
    CHECK(find_material_files(p.str()) ==
          std::vector<std::string>{"materials/bad.material.json", "materials/broken.material.json",
                                   "materials/gem.material.json", "materials/wave.material.json"});
}

TEST_CASE("shader dialects: one set per platform, as the design's table says") {
    CHECK(*shader_dialects_for({"windows"}) == std::vector<std::string>{"hlsl5"});
    CHECK(*shader_dialects_for({"linux"}) == std::vector<std::string>{"glsl430"});
    CHECK(*shader_dialects_for({"macos"}) == std::vector<std::string>{"metal_macos"});
    CHECK(*shader_dialects_for({"ios"}) == std::vector<std::string>{"metal_ios", "metal_sim"});
    CHECK(*shader_dialects_for({"android", "web"}) == std::vector<std::string>{"glsl300es"});
    CHECK(shader_dialects_for({}).value() == shader_dialects());
    CHECK(shader_dialects().size() == 6);
    const auto unknown = shader_dialects_for({"windos"});
    REQUIRE_FALSE(unknown.ok());
    CHECK(unknown.error().hint.find("Did you mean 'windows'?") != std::string::npos);
}

// ---------------------------------------------------------------------------------------------------------------
// The generator
// ---------------------------------------------------------------------------------------------------------------

TEST_CASE(
    "generator: the top file has the material block, textures, guarded entry points and the programs of the design") {
    Project p;
    const MaterialDef gem = read_material(p.str(), "materials/gem.material.json").material;
    const GeneratedShader g = generate_material_shader(gem, kGemSnippet);
    CHECK(g.hasSurface);
    CHECK_FALSE(g.hasVertex);
    CHECK(g.defines.empty());
    CHECK(g.programs == std::vector<std::string>{"mesh", "mesh_skin", "prepass", "prepass_skin"});
    // alphabetical block: pulse (padded to a vec4) then tint
    const std::size_t pulse = g.top.find("float pulse; float fa_pad0; float fa_pad1; float fa_pad2;");
    const std::size_t tint = g.top.find("vec4 tint;");
    CHECK(pulse != std::string::npos);
    CHECK(tint != std::string::npos);
    CHECK(pulse < tint);
    CHECK(g.top.find("layout(binding=5) uniform fa_material {") != std::string::npos);
    CHECK(g.top.find("layout(binding=4) uniform fa_material_vs {") != std::string::npos);
    CHECK(g.top.find("layout(binding=6) uniform texture2D glow;") != std::string::npos);
    CHECK(g.top.find("layout(binding=2) uniform sampler glow_smp;") != std::string::npos);
    CHECK(g.top.find("@include mesh_common.glsl") != std::string::npos);
    CHECK(g.top.find("@program mesh vs fs") != std::string::npos);
    CHECK(g.top.find("@program mesh_skin vs_skin fs") != std::string::npos);
    CHECK(g.top.find("@program shadow ") == std::string::npos);
    CHECK(g.top.find("#ifdef GL_FRAGMENT_SHADER\nvoid surface(") !=
          std::string::npos);  // surface() only in the fragment stage
    // The table says where the snippet is: line 6 of the snippet is `void surface(`.
    const int top = top_line_of(g, 6);
    REQUIRE(top > 0);
    std::string line;
    std::size_t at = 0;
    for (int l = 1; l <= top; ++l) {
        const std::size_t nl = g.top.find('\n', at);
        line = g.top.substr(at, nl - at);
        at = nl + 1;
    }
    CHECK(line.rfind("void surface(in SurfaceInput i", 0) == 0);
    CHECK(g.snippetLine.size() == std::size_t(std::count(g.top.begin(), g.top.end(), '\n')));
}

TEST_CASE("generator: vertex() and alphaMode clip add the shadow programs; comments do not count as definitions") {
    Project p;
    const MaterialDef wave = read_material(p.str(), "materials/wave.material.json").material;
    const GeneratedShader g = generate_material_shader(wave, kWaveSnippet);
    CHECK(g.hasVertex);
    CHECK(g.hasSurface);
    CHECK(g.programs ==
          std::vector<std::string>{"mesh", "mesh_skin", "shadow", "shadow_skin", "prepass", "prepass_skin"});
    CHECK(g.defines == std::vector<std::string>{"FA_HAS_VERTEX", "FA_ALPHA_CLIP"});
    CHECK(g.top.find("@program shadow_skin shadow_vs_skin shadow_fs") != std::string::npos);
    CHECK(g.top.find("#ifdef GL_VERTEX_SHADER\nvoid vertex(") != std::string::npos);

    // Only comments mention vertex(): not a vertex material, and a commented surface() is no surface().
    MaterialDef plain = wave;
    plain.alphaMode = "opaque";
    const GeneratedShader c =
        generate_material_shader(plain, "// void vertex(inout VertexData v) {}\n/* void surface(in SurfaceInput i, "
                                        "inout Surface s) {} */\nvoid helper() {}\n");
    CHECK_FALSE(c.hasVertex);
    CHECK_FALSE(c.hasSurface);
    CHECK(c.programs == std::vector<std::string>{"mesh", "mesh_skin", "prepass", "prepass_skin"});
    // clip alone is enough for the shadow programs
    const GeneratedShader clipOnly =
        generate_material_shader(wave, "void surface(in SurfaceInput i, inout Surface s) {}\n");
    CHECK(clipOnly.programs.size() == 6);
    CHECK(clipOnly.defines == std::vector<std::string>{"FA_ALPHA_CLIP"});
    // CRLF snippets keep their line numbers
    const GeneratedShader crlf =
        generate_material_shader(wave, "float a;\r\nvoid surface(in SurfaceInput i, inout Surface s) {}\r\n");
    CHECK(top_line_of(crlf, 2) > 0);
}

namespace {
const char* kToonMaterial = R"({
  "format": "factoria.material/1",
  "doc": "A cel-shaded material.",
  "shader": "shaders/toon.surface.glsl",
  "lighting": "custom",
  "textures": { "ramp": { "sampler": "nearest", "doc": "Light ramp: one texel per band." } }
})";
const char* kToonSnippet = R"(void surface(in SurfaceInput i, inout Surface s) {}

vec3 light(in SurfaceInput i, in Surface s, in LightSample l) {
    float ndl = dot(s.normal, l.direction) * 0.5 + 0.5;
    return s.albedo * l.color * textureLod(sampler2D(ramp, ramp_smp), vec2(ndl, 0.5), 0.0).r;
}

vec3 ambient(in SurfaceInput i, in Surface s, vec3 ambientColor) {
    return ambientColor * s.albedo;
}
)";
}  // namespace

TEST_CASE(
    "generator: lighting custom reads light() and ambient(), keeps them out of the vertex stage and declares every "
    "texture once per stage") {
    Project p;
    p.write("materials/toon.material.json", kToonMaterial);
    p.write("shaders/toon.surface.glsl", kToonSnippet);
    const MaterialParse m = read_material(p.str(), "materials/toon.material.json");
    REQUIRE(m.ok());
    CHECK(m.material.lighting == "custom");
    const GeneratedShader g = generate_material_shader(m.material, kToonSnippet);
    CHECK(g.hasSurface);
    CHECK(g.hasLight);
    CHECK(g.hasAmbient);
    CHECK_FALSE(g.hasVertex);
    CHECK(g.defines == std::vector<std::string>{"FA_CUSTOM_LIGHT", "FA_HAS_AMBIENT"});
    CHECK(g.programs == std::vector<std::string>{"mesh", "mesh_skin", "prepass", "prepass_skin"});
    CHECK(g.top.find("#ifdef GL_FRAGMENT_SHADER\nvec3 light(in SurfaceInput i") != std::string::npos);
    CHECK(g.top.find("#ifdef GL_FRAGMENT_SHADER\nvec3 ambient(in SurfaceInput i") != std::string::npos);
    // the fragment stage reads the ramp at view 6 / sampler 2, the vertex stage at view 10 / sampler 6 under its own name
    CHECK(g.top.find(
              "#ifdef GL_VERTEX_SHADER\n#define ramp fa_vs_ramp\n#define ramp_smp fa_vs_ramp_smp\n"
              "layout(binding=10) uniform texture2D ramp;\nlayout(binding=6) uniform sampler ramp_smp;\n#else\n"
              "layout(binding=6) uniform texture2D ramp;\nlayout(binding=2) uniform sampler ramp_smp;\n#endif\n") !=
          std::string::npos);
    CHECK(g.top.find("#undef ramp\n#undef ramp_smp\n#endif\n@end") != std::string::npos);

    // without ambient() only FA_CUSTOM_LIGHT is defined; a commented light() does not count
    const GeneratedShader noAmbient = generate_material_shader(
        m.material, "// vec3 light(in SurfaceInput i, in Surface s, in LightSample l) { return vec3(0.0); }\n"
                    "void surface(in SurfaceInput i, inout Surface s) {}\n");
    CHECK_FALSE(noAmbient.hasLight);
    CHECK(noAmbient.defines == std::vector<std::string>{"FA_CUSTOM_LIGHT"});

    // in a pbr material `light` and `ambient` are ordinary helpers, compiled in both stages
    MaterialDef pbr = m.material;
    pbr.lighting = "pbr";
    const GeneratedShader helper =
        generate_material_shader(pbr, "vec3 light(vec3 a) { return a; }\nvoid surface(in SurfaceInput i, inout Surface "
                                      "s) { s.albedo = light(s.albedo); }\n");
    CHECK_FALSE(helper.hasLight);
    CHECK(helper.defines.empty());
    CHECK(helper.top.find("#ifdef GL_FRAGMENT_SHADER\nvec3 light(") == std::string::npos);

    // a texture read in vertex() uses the same names and the shadow programs declare the vertex binding too
    MaterialDef wave = m.material;
    wave.lighting = "pbr";
    const GeneratedShader vertexTex = generate_material_shader(
        wave, "void vertex(inout VertexData v) { v.world_pos.y += texture(sampler2D(ramp, ramp_smp), v.uv).r; }\n"
              "void surface(in SurfaceInput i, inout Surface s) {}\n");
    CHECK(vertexTex.hasVertex);
    CHECK(vertexTex.defines == std::vector<std::string>{"FA_HAS_VERTEX"});
    CHECK(vertexTex.top.find("#define texture(s, uv) textureLod(s, uv, 0.0)") != std::string::npos);
}

TEST_CASE("template: the generator includes every _common.glsl and the contract structs are read from them") {
    CHECK_FALSE(shader_template_hash().empty());
    CHECK(shader_template_hash().size() == 64);
    const auto g = generate_material_shader(parse(kGemMaterial).material, kGemSnippet);
    CHECK(g.top.find("@include mesh_common.glsl") != std::string::npos);
    // the mesh hash is the one committed twins carry (the kinds did not change it)
    const Json fixtureTwin =
        Json::parse(testing::read_all(stdfs::path(FA_REPO_ROOT) / "engine/render/tests/data/materials/"
                                                                  "materials/empty.material.json.hlsl5.shader"));
    CHECK(fixtureTwin["template"] == shader_template_hash("mesh"));
}

// ---------------------------------------------------------------------------------------------------------------
// Kinds (M72)
// ---------------------------------------------------------------------------------------------------------------

TEST_CASE("material kind: absent means mesh, every kind is read, and a wrong one says what the kinds are") {
    CHECK(parse(R"({"format":"factoria.material/1","shader":"s.glsl"})").material.kind == "mesh");
    for (const char* kind : {"mesh", "sprite", "sky", "post", "compute"}) {
        const auto ok = parse(
            (std::string(R"({"format":"factoria.material/1","shader":"s.glsl","kind":")") + kind + "\"}").c_str());
        CAPTURE(kind);
        CHECK(ok.ok());
        CHECK(ok.material.kind == kind);
    }
    auto bad = parse(R"({"format":"factoria.material/1","shader":"s.glsl","kind":"spirte"})");
    CHECK(has_error(bad, "/kind", "unknown kind"));
    CHECK(has_error(bad, "/kind", "Did you mean 'sprite'?"));
    bad = parse(R"({"format":"factoria.material/1","shader":"s.glsl","kind":3})");
    CHECK(has_error(bad, "/kind", "Use one of: mesh, sprite, sky, post, compute"));
    // the schema lists the same kinds
    const Json schema = Json::parse(*bundled_read("schemas/material.schema.json"));
    CHECK(schema["properties"]["kind"]["enum"] == Json(material_kind_names()));
    CHECK(schema["properties"]["kind"]["default"] == "mesh");
    CHECK(validate_json(Json::parse(R"({"format":"factoria.material/1","shader":"s.glsl","kind":"sky"})"), schema)
              .empty());
}

TEST_CASE("material kind: mesh, sprite and post compile, the others are refused with the package that brings them") {
    Project p;
    FakeShdc shdc;
    ShaderCompileOptions options;
    options.setup = shdc.context(p.str());
    const std::vector<std::pair<std::string, std::string>> kinds = {{"sky", "sky materials arrive with M72.1"},
                                                                    {"compute", "compute materials arrive with M72.4"}};
    CommandRegistry registry;
    register_shader_commands(registry, p.str(), shdc.context(p.str()));
    for (const auto& [kind, text] : kinds) {
        CAPTURE(kind);
        p.write("materials/" + kind + ".material.json",
                R"({"format":"factoria.material/1","kind":")" + kind + R"(","shader":"shaders/gem.surface.glsl"})");
        auto r = compile_material(p.str(), "materials/" + kind + ".material.json", options);
        REQUIRE(r.ok());
        CHECK_FALSE(r->ok);
        CHECK(r->material.kind == kind);
        REQUIRE(r->errors.size() == 1);
        CHECK(r->errors[0].pointer == "/kind");
        CHECK(r->errors[0].message.find(text) != std::string::npos);
        CHECK(r->errors[0].hint.find("\"mesh\"") != std::string::npos);
        CHECK(shdc.calls == 0);

        auto c =
            registry.call("shader.compile", Json::parse(R"({"material":"materials/)" + kind + R"(.material.json"})"));
        REQUIRE(c.ok);
        CHECK(c.result["ok"] == false);
        CHECK(c.result["kind"] == kind);
        CHECK(c.result["errors"][0]["pointer"] == "/kind");
        auto info =
            registry.call("material.info", Json::parse(R"({"material":"materials/)" + kind + R"(.material.json"})"));
        REQUIRE(info.ok);
        CHECK(info.result["kind"] == kind);
        CHECK(info.result["programs"].empty());
        CHECK(info.result["compile"]["state"] == "unsupported");
        CHECK(info.result["compile"]["hint"].get<std::string>().find(text) != std::string::npos);
    }
    // `factoria validate` lists the refusal as an error of the material
    // (the project's three mesh materials do compile, one run each; the two refused kinds never reach the compiler)
    ValidationReport report;
    validate_materials(p.str(), shdc.context(p.str()), report);
    CHECK_FALSE(report.ok);
    CHECK(shdc.calls == 3);
    int kindErrors = 0;
    for (const auto& e : report.errors)
        if (e.message.find("is not compiled yet") != std::string::npos) ++kindErrors;
    CHECK(kindErrors == 2);
}

TEST_CASE("material kind: a mesh twin has no kind key (the format of every twin made before M72), info and compile say "
          "\"mesh\"") {
    Project p;
    FakeShdc shdc;
    shdc.reflection = fixture("shdc_mesh_hlsl5_glsl430.yaml");
    ShaderCompileOptions options;
    options.setup = shdc.context(p.str());
    options.dialects = {"hlsl5"};
    auto r = compile_material(p.str(), "materials/gem.material.json", options);
    REQUIRE(r.ok());
    REQUIRE(r->ok);
    CHECK(r->material.kind == "mesh");
    CHECK(r->generated.kind == "mesh");
    CHECK_FALSE(r->twins.at("hlsl5").contains("kind"));
    CommandRegistry registry;
    register_shader_commands(registry, p.str(), shdc.context(p.str()));
    auto info = registry.call("material.info", Json::parse(R"({"material":"materials/gem.material.json"})"));
    REQUIRE(info.ok);
    CHECK(info.result["kind"] == "mesh");
    auto c = registry.call("shader.compile",
                           Json::parse(R"({"material":"materials/gem.material.json","platforms":["windows"]})"));
    REQUIRE(c.ok);
    CHECK(c.result["kind"] == "mesh");
}

// ---------------------------------------------------------------------------------------------------------------
// The YAML reader
// ---------------------------------------------------------------------------------------------------------------

// ---------------------------------------------------------------------------------------------------------------
// Sprite materials (M72.1)
// ---------------------------------------------------------------------------------------------------------------

TEST_CASE(
    "sprite material: the generator includes quad_common.glsl, takes the 2D slots and lists quad and quad_plain") {
    Project p;
    p.add_sprite();
    const MaterialParse parsed = read_material(p.str(), "materials/dissolve2d.material.json");
    REQUIRE(parsed.ok());
    CHECK(parsed.material.kind == "sprite");
    const GeneratedShader g = generate_material_shader(parsed.material, kSpriteSnippet);
    CHECK(g.kind == "sprite");
    CHECK(g.hasSurface);  // the fragment() entry point
    CHECK_FALSE(g.hasVertex);
    CHECK(g.programs == std::vector<std::string>{"quad", "quad_plain"});
    CHECK(g.defines == std::vector<std::string>{"FA_MATERIAL"});
    CHECK(g.top.find("@include quad_common.glsl") != std::string::npos);
    CHECK(g.top.find("@include mesh_common.glsl") == std::string::npos);
    CHECK(g.top.find("@program quad vs fs\n@program quad_plain vs fs_plain\n") != std::string::npos);
    CHECK(g.top.find("@program mesh") == std::string::npos);
    CHECK(g.top.find("layout(binding=5) uniform fa_material {") != std::string::npos);
    CHECK(g.top.find("layout(binding=4) uniform fa_material_vs {") != std::string::npos);
    // views 0-3 and samplers 0-2 are the engine's: the first texture of a material is view 4, sampler 3
    CHECK(g.top.find("layout(binding=4) uniform texture2D mask;") != std::string::npos);
    CHECK(g.top.find("layout(binding=3) uniform sampler mask_smp;") != std::string::npos);
    CHECK(g.top.find("#ifdef GL_FRAGMENT_SHADER\nvoid fragment(in QuadInput i, inout QuadSurface s) {") !=
          std::string::npos);
    // vertex() is found, and defines FA_HAS_VERTEX
    const GeneratedShader v = generate_material_shader(
        parsed.material, std::string(kSpriteSnippet) + "void vertex(inout QuadVertex v) { v.world_pos.y += 1.0; }\n");
    CHECK(v.hasVertex);
    CHECK(v.defines == std::vector<std::string>{"FA_MATERIAL", "FA_HAS_VERTEX"});
    CHECK(v.top.find("#ifdef GL_VERTEX_SHADER\nvoid vertex(") != std::string::npos);
    // a surface() is not the entry point of a sprite
    const GeneratedShader s =
        generate_material_shader(parsed.material, "void surface(in SurfaceInput i, inout Surface s) {}\n");
    CHECK_FALSE(s.hasSurface);
    // the names of the contract are not available as params
    CHECK(has_error(parse(R"({"format":"factoria.material/1","kind":"sprite","shader":"s.glsl","params":{
        "fragment":{"type":"float","default":1,"doc":"d"}}})"),
                    "/params/fragment"));
}

TEST_CASE("sprite material: with an empty fragment() the generated top file is quad.glsl, the engine's own program, "
          "modulo the user block") {
    MaterialDef m;
    m.kind = "sprite";
    m.shader = "shaders/empty.glsl";
    const GeneratedShader g = generate_material_shader(m, "void fragment(in QuadInput i, inout QuadSurface s) {}\n");
    const std::string builtIn = testing::read_all(stdfs::path(FA_REPO_ROOT) / "engine/render/shaders/quad.glsl");
    // What follows the user block: the include and the programs, with the comments and blank lines of the file dropped.
    auto after_block = [](const std::string& text) {
        const std::size_t end = text.find("@end\n");
        REQUIRE(end != std::string::npos);
        std::string out;
        std::size_t at = end + 5;
        while (at < text.size()) {
            std::size_t nl = text.find('\n', at);
            if (nl == std::string::npos) nl = text.size();
            const std::string line = text.substr(at, nl - at);
            if (!line.empty() && line.rfind("//", 0) != 0) out += line + "\n";
            at = nl + 1;
        }
        return out;
    };
    const std::string tail = after_block(g.top);
    CHECK(tail == "@include quad_common.glsl\n@program quad vs fs\n@program quad_plain vs fs_plain\n");
    CHECK(after_block(builtIn) == tail);
    // the user block of a material that declares nothing is the built-in's fragment()
    CHECK(g.top.find("void fragment(in QuadInput i, inout QuadSurface s) {}") != std::string::npos);
    CHECK(builtIn.find("void fragment(in QuadInput i, inout QuadSurface s) {}") != std::string::npos);
    // the only difference of the build: a material defines FA_MATERIAL, the engine's program does not
    CHECK(g.defines == std::vector<std::string>{"FA_MATERIAL"});
}

TEST_CASE("sprite material: errors name fragment() and the sprite contract; alphaMode clip is refused") {
    Project p;
    p.add_sprite();
    FakeShdc shdc;
    shdc.reflection = fixture("shdc_sprite_hlsl5_glsl430.yaml");
    ShaderCompileOptions options;
    options.setup = shdc.context(p.str());
    options.dialects = {"hlsl5"};

    // no fragment(): the message and the hint are the sprite's
    p.write("shaders/dissolve2d.fragment.glsl", "void surface(in SurfaceInput i, inout Surface s) {}\n");
    auto r = compile_material(p.str(), "materials/dissolve2d.material.json", options);
    REQUIRE(r.ok());
    CHECK_FALSE(r->ok);
    REQUIRE_FALSE(r->errors.empty());
    CHECK(r->errors[0].message.find("defines no fragment() function") != std::string::npos);
    CHECK(r->errors[0].hint.find("void fragment(in QuadInput i, inout QuadSurface s)") != std::string::npos);
    CHECK(shdc.calls == 0);

    // a mistake in the snippet is mapped to its line, with the fields of QuadInput
    const std::string bad =
        "void fragment(in QuadInput i, inout QuadSurface s) {\n    s.color.rgb *= i.colour.rgb;\n}\n";
    p.write("shaders/dissolve2d.fragment.glsl", bad);
    const GeneratedShader g =
        generate_material_shader(read_material(p.str(), "materials/dissolve2d.material.json").material, bad);
    shdc.stderrText =
        "top.glsl:" + std::to_string(top_line_of(g, 2)) + ":0: error: 'colour' : no such field in structure 'i'\n";
    r = compile_material(p.str(), "materials/dissolve2d.material.json", options);
    REQUIRE(r.ok());
    REQUIRE(r->errors.size() == 1);
    CHECK(r->errors[0].line == 2);
    CHECK(r->errors[0].hint.find("did you mean color?") != std::string::npos);
    CHECK(r->errors[0].hint.find("QuadInput has the fields") != std::string::npos);

    // alphaMode clip is the mesh template's alpha test
    auto clip = parse(R"({"format":"factoria.material/1","kind":"sprite","shader":"s.glsl","alphaMode":"clip"})");
    CHECK(has_error(clip, "/alphaMode", "discard"));

    // lighting "custom" is the light() hook of a mesh material: a sprite has no lights
    auto light = parse(R"({"format":"factoria.material/1","kind":"sprite","shader":"s.glsl","lighting":"custom"})");
    CHECK(has_error(light, "/lighting"));

    // a sprite's vertex() cannot sample a material texture (no vertex-stage views in the 2D pipeline): refused
    // before sokol-shdc runs, with the texture named
    const std::string sampling =
        std::string(kSpriteSnippet) +
        "void vertex(inout QuadVertex v) { v.world_pos.y += texture(sampler2D(mask, mask_smp), vec2(0.5)).r; }\n";
    p.write("shaders/dissolve2d.fragment.glsl", sampling);
    shdc.calls = 0;
    r = compile_material(p.str(), "materials/dissolve2d.material.json", options);
    REQUIRE(r.ok());
    CHECK_FALSE(r->ok);
    REQUIRE_FALSE(r->errors.empty());
    CHECK(r->errors[0].message.find("vertex() of a sprite material cannot sample the texture \"mask\"") !=
          std::string::npos);
    CHECK(shdc.calls == 0);
}

TEST_CASE("sprite material: compile writes a twin with the sprite template hash and the programs quad and quad_plain") {
    Project p;
    p.add_sprite();
    FakeShdc shdc;
    shdc.reflection = fixture("shdc_sprite_hlsl5_glsl430.yaml");
    ShaderCompileOptions options;
    options.setup = shdc.context(p.str());
    options.dialects = {"hlsl5", "glsl430"};

    auto first = compile_material(p.str(), "materials/dissolve2d.material.json", options);
    REQUIRE(first.ok());
    const std::string why = first->errors.empty() ? std::string() : first->errors[0].to_string();
    INFO(why);
    REQUIRE(first->ok);
    CHECK(shdc.calls == 1);
    CHECK(first->material.kind == "sprite");
    CHECK(first->generated.kind == "sprite");
    const auto& argv = shdc.argvs[0];
    const auto defines = std::find(argv.begin(), argv.end(), "--defines");
    REQUIRE(defines != argv.end());
    CHECK(*(defines + 1) == "FA_MATERIAL");
    REQUIRE(first->twins.size() == 2);
    const Json& twin = first->twins.at("hlsl5");
    CHECK(twin["format"] == "factoria.shader/1");
    CHECK(twin["kind"] == "sprite");
    CHECK(twin["template"] == shader_template_hash("sprite"));
    CHECK(twin["template"] != shader_template_hash("mesh"));
    CHECK(twin["params"] == Json::parse(R"(["amount","edge"])"));
    CHECK(twin["textures"] == Json::parse(R"(["mask"])"));
    REQUIRE(twin["programs"].contains("quad"));
    REQUIRE(twin["programs"].contains("quad_plain"));
    CHECK(twin["programs"].size() == 2);
    CHECK(twin["programs"]["quad"]["reflection"]["vertex_func"]["d3d11_target"] == "vs_5_0");
    // the cache key holds the kind's hash: the second run starts no process
    auto second = compile_material(p.str(), "materials/dissolve2d.material.json", options);
    REQUIRE(second.ok());
    CHECK(second->cacheHits == 2);
    CHECK(shdc.calls == 1);
    CHECK(second->twins.at("glsl430") == first->twins.at("glsl430"));

    // shader.compile and material.info say "sprite", with the programs
    CommandRegistry registry;
    register_shader_commands(registry, p.str(), shdc.context(p.str()));
    auto c = registry.call("shader.compile",
                           Json::parse(R"({"material":"materials/dissolve2d.material.json","platforms":["linux"]})"));
    REQUIRE(c.ok);
    CHECK(c.result["ok"] == true);
    CHECK(c.result["kind"] == "sprite");
    auto info = registry.call("material.info", Json::parse(R"({"material":"materials/dissolve2d.material.json"})"));
    REQUIRE(info.ok);
    CHECK(info.result["kind"] == "sprite");
    CHECK(info.result["programs"] == Json::parse(R"(["quad","quad_plain"])"));
}

TEST_CASE("sprite material: validate compiles it next to the mesh materials") {
    Project p;
    p.add_sprite();
    FakeShdc shdc;
    shdc.reflection = fixture("shdc_sprite_hlsl5_glsl430.yaml");
    // only the sprite material is in the project: the others would need the mesh reflection
    for (const char* name : {"gem", "wave", "bad"})
        stdfs::remove(p.dir.path / "materials" / (std::string(name) + ".material.json"));
    ValidationReport report;
    validate_materials(p.str(), shdc.context(p.str()), report);
    CHECK(report.materialsChecked == 1);
    CHECK(shdc.calls == 1);
    // validate compiles for all six dialects and the fixture holds two: what matters here is that the sprite top file
    // (FA_MATERIAL, quad_common.glsl) is what the compiler was given, and that nothing refuses the kind
    const auto& argv = shdc.argvs[0];
    const auto defines = std::find(argv.begin(), argv.end(), "--defines");
    REQUIRE(defines != argv.end());
    CHECK(*(defines + 1) == "FA_MATERIAL");
    for (const auto& e : report.errors) CHECK(e.message.find("is not compiled yet") == std::string::npos);

    // a mistake in fragment() is the error of the material's snippet
    const std::string bad = "void fragment(in QuadInput i, inout QuadSurface s) {\n    s.color = tnt;\n}\n";
    p.write("shaders/dissolve2d.fragment.glsl", bad);
    const GeneratedShader g =
        generate_material_shader(read_material(p.str(), "materials/dissolve2d.material.json").material, bad);
    shdc.stderrText = "top.glsl:" + std::to_string(top_line_of(g, 2)) + ":0: error: 'tnt' : undeclared identifier\n";
    ValidationReport failing;
    validate_materials(p.str(), shdc.context(p.str()), failing);
    CHECK_FALSE(failing.ok);
    const auto err = std::find_if(failing.errors.begin(), failing.errors.end(), [](const ValidationIssue& e) {
        return e.file == "shaders/dissolve2d.fragment.glsl";
    });
    REQUIRE(err != failing.errors.end());
    CHECK(err->message.find("line 2") != std::string::npos);
}

// ---------------------------------------------------------------------------------------------------------------
// Post-process materials (M72.2)
// ---------------------------------------------------------------------------------------------------------------

TEST_CASE("post material: the generator includes post_common.glsl, takes the post slots and lists the one program") {
    Project p;
    p.add_post();
    const MaterialParse parsed = read_material(p.str(), "materials/tint.material.json");
    REQUIRE(parsed.ok());
    CHECK(parsed.material.kind == "post");
    const GeneratedShader g = generate_material_shader(parsed.material, kPostSnippet);
    CHECK(g.kind == "post");
    CHECK(g.hasSurface);  // the post() entry point
    CHECK_FALSE(g.hasVertex);
    CHECK(g.programs == std::vector<std::string>{"post"});
    CHECK(g.defines.empty());  // the template has no variants: one program, one build
    CHECK(g.top.find("@include post_common.glsl") != std::string::npos);
    CHECK(g.top.find("@include mesh_common.glsl") == std::string::npos);
    CHECK(g.top.find("@program post vs fs\n") != std::string::npos);
    CHECK(g.top.find("layout(binding=5) uniform fa_material {") != std::string::npos);
    CHECK(g.top.find("#ifdef GL_FRAGMENT_SHADER\nvoid post(in PostInput i, inout PostSurface s) {") !=
          std::string::npos);
    // views 0 and 1 and samplers 0 and 1 are the engine's (the picture and the prepass): a material's first texture is 2
    const MaterialParse withTexture = parse(R"({"format":"factoria.material/1","kind":"post","shader":"s.glsl",
        "textures":{"mask":{"sampler":"linear","doc":"d"}}})");
    REQUIRE(withTexture.ok());
    const GeneratedShader t =
        generate_material_shader(withTexture.material, "void post(in PostInput i, inout PostSurface s) {}\n");
    CHECK(t.top.find("layout(binding=2) uniform texture2D mask;") != std::string::npos);
    CHECK(t.top.find("layout(binding=2) uniform sampler mask_smp;") != std::string::npos);
    // the names of the contract are not available as params
    CHECK(has_error(parse(R"({"format":"factoria.material/1","kind":"post","shader":"s.glsl","params":{
        "post":{"type":"float","default":1,"doc":"d"}}})"),
                    "/params/post"));
}

TEST_CASE("post material: keys of a surface drawn into the scene are refused with the reason") {
    for (const char* key : {R"("lighting":"unlit")", R"("alphaMode":"blend")", R"("doubleSided":true)"}) {
        CAPTURE(key);
        const auto m = parse(
            (std::string(R"({"format":"factoria.material/1","kind":"post","shader":"s.glsl",)") + key + "}").c_str());
        CHECK_FALSE(m.ok());
        REQUIRE_FALSE(m.errors.empty());
        CHECK(m.errors[0].message.find("does not apply to a post material") != std::string::npos);
        CHECK(m.errors[0].hint.find("customPasses") != std::string::npos);
    }
    // a mesh material still takes them
    CHECK(parse(R"({"format":"factoria.material/1","shader":"s.glsl","lighting":"unlit","alphaMode":"blend"})").ok());
}

TEST_CASE("post material: errors name post() and the post contract; the frequent mistakes get a hint") {
    Project p;
    p.add_post();
    FakeShdc shdc;
    shdc.reflection = fixture("shdc_post_hlsl5_glsl430.yaml");
    ShaderCompileOptions options;
    options.setup = shdc.context(p.str());
    options.dialects = {"hlsl5"};

    // no post(): the message and the hint are the post's
    p.write("shaders/tint.post.glsl", "void fragment(in QuadInput i, inout QuadSurface s) {}\n");
    auto r = compile_material(p.str(), "materials/tint.material.json", options);
    REQUIRE(r.ok());
    CHECK_FALSE(r->ok);
    REQUIRE_FALSE(r->errors.empty());
    CHECK(r->errors[0].message.find("defines no post() function") != std::string::npos);
    CHECK(r->errors[0].hint.find("void post(in PostInput i, inout PostSurface s)") != std::string::npos);
    CHECK(shdc.calls == 0);

    // a vertex() is refused before sokol-shdc runs, with its line
    p.write("shaders/tint.post.glsl", std::string(kPostSnippet) + "void vertex(inout QuadVertex v) { }\n");
    r = compile_material(p.str(), "materials/tint.material.json", options);
    REQUIRE(r.ok());
    CHECK_FALSE(r->ok);
    REQUIRE_FALSE(r->errors.empty());
    CHECK(r->errors[0].message.find("a post material has no vertex() hook") != std::string::npos);
    CHECK(r->errors[0].line == 4);
    CHECK(shdc.calls == 0);

    // the names other engines use for the picture and the depth are explained
    const std::string bad = "void post(in PostInput i, inout PostSurface s) {\n    s.color = "
                            "texture(sampler2D(screenTexture, x), i.uv);\n}\n";
    p.write("shaders/tint.post.glsl", bad);
    const GeneratedShader g =
        generate_material_shader(read_material(p.str(), "materials/tint.material.json").material, bad);
    shdc.stderrText =
        "top.glsl:" + std::to_string(top_line_of(g, 2)) + ":0: error: 'screenTexture' : undeclared identifier\n";
    r = compile_material(p.str(), "materials/tint.material.json", options);
    REQUIRE(r.ok());
    REQUIRE_FALSE(r->errors.empty());
    CHECK(r->errors[0].line == 2);
    CHECK(r->errors[0].hint.find("fa_scene_color(uv)") != std::string::npos);
    shdc.stderrText =
        "top.glsl:" + std::to_string(top_line_of(g, 2)) + ":0: error: 'uv' : no such field in structure 'i'\n";
    r = compile_material(p.str(), "materials/tint.material.json", options);
    REQUIRE(r.ok());
    REQUIRE_FALSE(r->errors.empty());
    CHECK(r->errors[0].hint.find("PostInput has the fields") != std::string::npos);
}

TEST_CASE("post material: compile writes a twin with the post template hash and the program post") {
    Project p;
    p.add_post();
    FakeShdc shdc;
    shdc.reflection = fixture("shdc_post_hlsl5_glsl430.yaml");
    ShaderCompileOptions options;
    options.setup = shdc.context(p.str());
    options.dialects = {"hlsl5", "glsl430"};

    auto first = compile_material(p.str(), "materials/tint.material.json", options);
    REQUIRE(first.ok());
    const std::string why = first->errors.empty() ? std::string() : first->errors[0].to_string();
    INFO(why);
    REQUIRE(first->ok);
    CHECK(shdc.calls == 1);
    CHECK(first->generated.kind == "post");
    const auto& argv = shdc.argvs[0];
    CHECK(std::find(argv.begin(), argv.end(), "--defines") == argv.end());
    REQUIRE(first->twins.size() == 2);
    const Json& twin = first->twins.at("hlsl5");
    CHECK(twin["format"] == "factoria.shader/1");
    CHECK(twin["kind"] == "post");
    CHECK(twin["template"] == shader_template_hash("post"));
    CHECK(twin["template"] != shader_template_hash("sprite"));
    CHECK(twin["params"] == Json::parse(R"(["tint"])"));
    REQUIRE(twin["programs"].contains("post"));
    CHECK(twin["programs"].size() == 1);
    CHECK(twin["programs"]["post"]["reflection"]["fragment_func"]["d3d11_target"] == "ps_5_0");
    auto second = compile_material(p.str(), "materials/tint.material.json", options);
    REQUIRE(second.ok());
    CHECK(second->cacheHits == 2);
    CHECK(shdc.calls == 1);

    CommandRegistry registry;
    register_shader_commands(registry, p.str(), shdc.context(p.str()));
    auto c = registry.call("shader.compile",
                           Json::parse(R"({"material":"materials/tint.material.json","platforms":["linux"]})"));
    REQUIRE(c.ok);
    CHECK(c.result["ok"] == true);
    CHECK(c.result["kind"] == "post");
    auto info = registry.call("material.info", Json::parse(R"({"material":"materials/tint.material.json"})"));
    REQUIRE(info.ok);
    CHECK(info.result["kind"] == "post");
    CHECK(info.result["programs"] == Json::parse(R"(["post"])"));
}

TEST_CASE("post material: validate compiles it next to the other kinds") {
    Project p;
    p.add_post();
    FakeShdc shdc;
    shdc.reflection = fixture("shdc_post_hlsl5_glsl430.yaml");
    for (const char* name : {"gem", "wave", "bad"})
        stdfs::remove(p.dir.path / "materials" / (std::string(name) + ".material.json"));
    ValidationReport report;
    validate_materials(p.str(), shdc.context(p.str()), report);
    CHECK(report.materialsChecked == 1);
    CHECK(shdc.calls == 1);
    for (const auto& e : report.errors) CHECK(e.message.find("is not compiled yet") == std::string::npos);

    const std::string bad = "void post(in PostInput i, inout PostSurface s) {\n    s.color = tnt;\n}\n";
    p.write("shaders/tint.post.glsl", bad);
    const GeneratedShader g =
        generate_material_shader(read_material(p.str(), "materials/tint.material.json").material, bad);
    shdc.stderrText = "top.glsl:" + std::to_string(top_line_of(g, 2)) + ":0: error: 'tnt' : undeclared identifier\n";
    ValidationReport failing;
    validate_materials(p.str(), shdc.context(p.str()), failing);
    CHECK_FALSE(failing.ok);
    const auto err = std::find_if(failing.errors.begin(), failing.errors.end(),
                                  [](const ValidationIssue& e) { return e.file == "shaders/tint.post.glsl"; });
    REQUIRE(err != failing.errors.end());
    CHECK(err->message.find("line 2") != std::string::npos);
}

TEST_CASE("yaml: the reflection sokol-shdc writes becomes JSON") {
    const std::string text = fixture("shdc_mesh_hlsl5_glsl430.yaml");
    REQUIRE_FALSE(text.empty());
    const auto yaml = parse_shdc_yaml(text);
    REQUIRE(yaml.ok());
    const Json& shaders = (*yaml)["shaders"];
    REQUIRE(shaders.is_array());
    REQUIRE(shaders.size() == 2);
    const Json& hlsl = shaders[0]["slang"] == "hlsl5" ? shaders[0] : shaders[1];  // sokol-shdc writes glsl430 first
    const Json& glsl = shaders[0]["slang"] == "hlsl5" ? shaders[1] : shaders[0];
    CHECK(hlsl["slang"] == "hlsl5");
    CHECK(glsl["slang"] == "glsl430");
    const Json& mesh = hlsl["programs"][0];
    CHECK(mesh["name"] == "mesh");
    CHECK(mesh["vertex_func"]["entry_point"] == "main");
    CHECK(mesh["vertex_func"]["d3d11_target"] == "vs_5_0");
    CHECK(mesh["fragment_func"]["is_binary"] == false);
    CHECK(mesh["attrs"][0]["hlsl_sem_name"] == "TEXCOORD");
    CHECK(mesh["attrs"][0]["slot"] == 0);
    // a uniform block of the material, in the fragment stage, with its register
    bool material = false;
    for (const Json& ub : mesh["uniform_blocks"])
        if (ub["struct_name"] == "fa_material") {
            material = true;
            CHECK(ub["stage"] == "fragment");
            CHECK(ub["slot"] == 5);
            CHECK(ub["size"].get<int>() % 16 == 0);
        }
    CHECK(material);
    // the material texture is view 6 with its sampler
    bool texture = false;
    for (const Json& v : mesh["views"])
        if (v["texture"]["name"] == "glow") {
            texture = true;
            CHECK(v["texture"]["slot"] == 6);
            CHECK(v["texture"]["stage"] == "fragment");
        }
    CHECK(texture);
    CHECK(glsl["programs"][0]["uniform_blocks"][0].contains("glsl_uniforms"));
}

TEST_CASE("yaml: scalars, inline sequence items and the errors of what is not sokol-shdc's YAML") {
    const auto y = parse_shdc_yaml("a:\n  - x: 1\n    y: true\n  - x: 2.5\n    y: \"q r\"\nb:\n  -\n    c: text\n");
    REQUIRE(y.ok());
    CHECK((*y)["a"][0]["x"] == 1);
    CHECK((*y)["a"][0]["y"] == true);
    CHECK((*y)["a"][1]["x"] == 2.5);
    CHECK((*y)["a"][1]["y"] == "q r");
    CHECK((*y)["b"][0]["c"] == "text");
    const auto bad = parse_shdc_yaml("a:\n  b\n");
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("line 2") != std::string::npos);
    CHECK_FALSE(parse_shdc_yaml("").ok());
}

// ---------------------------------------------------------------------------------------------------------------
// Compiling with an injected sokol-shdc
// ---------------------------------------------------------------------------------------------------------------

TEST_CASE("compile: the twins carry the engine, template, dialect, params and one entry per program; the second run "
          "starts no process") {
    Project p;
    FakeShdc shdc;
    shdc.reflection = fixture("shdc_mesh_hlsl5_glsl430.yaml");
    ShaderCompileOptions options;
    options.setup = shdc.context(p.str());
    options.dialects = {"hlsl5", "glsl430"};

    auto first = compile_material(p.str(), "materials/gem.material.json", options);
    REQUIRE(first.ok());
    REQUIRE(first->ok);
    CHECK(shdc.calls == 1);
    // one process for both dialects, with the options of the design
    const auto& argv = shdc.argvs[0];
    CHECK(argv[0] == "/fake/sokol-shdc");
    CHECK(std::find(argv.begin(), argv.end(), "bare_yaml") != argv.end());
    CHECK(std::find(argv.begin(), argv.end(), "gcc") != argv.end());
    CHECK(std::find(argv.begin(), argv.end(), "hlsl5:glsl430") != argv.end());
    CHECK(std::find(argv.begin(), argv.end(), "--defines") == argv.end());
    REQUIRE(first->twins.size() == 2);
    const Json& twin = first->twins.at("hlsl5");
    CHECK(twin["format"] == "factoria.shader/1");
    CHECK(twin["engine"] == std::string(FA_ENGINE_VERSION));
    CHECK(twin["template"] == shader_template_hash());
    CHECK(twin["slang"] == "hlsl5");
    CHECK(twin["params"] == Json::parse(R"(["pulse","tint"])"));
    CHECK(twin["textures"] == Json::parse(R"(["glow"])"));
    REQUIRE(twin["programs"].contains("mesh"));
    REQUIRE(twin["programs"].contains("mesh_skin"));
    CHECK_FALSE(twin["programs"].contains("shadow"));
    CHECK(twin["programs"]["mesh"]["vs"].get<std::string>().find("generated source") != std::string::npos);
    CHECK(twin["programs"]["mesh"]["reflection"]["vertex_func"]["d3d11_target"] == "vs_5_0");
    CHECK_FALSE(twin["programs"]["mesh"]["reflection"].contains("name"));
    CHECK(stdfs::exists(shader_cache_path(p.str(), first->generated, kGemSnippet, "hlsl5")));

    // an unchanged material is served from .factoria/shader-cache
    auto second = compile_material(p.str(), "materials/gem.material.json", options);
    REQUIRE(second.ok());
    CHECK(second->ok);
    CHECK(second->cacheHits == 2);
    CHECK(shdc.calls == 1);
    CHECK(second->twins.at("glsl430") == first->twins.at("glsl430"));

    // a changed snippet, or a changed param, is a new key
    p.write("shaders/gem.surface.glsl", std::string(kGemSnippet) + "// edited\nfloat extra() { return 1.0; }\n");
    auto third = compile_material(p.str(), "materials/gem.material.json", options);
    REQUIRE(third.ok());
    CHECK(third->cacheHits == 0);
    CHECK(shdc.calls == 2);
    // only the dialect that is missing is compiled
    options.dialects = {"hlsl5", "glsl430"};
    p.write("shaders/gem.surface.glsl", kGemSnippet);
    std::error_code ec;
    stdfs::remove(shader_cache_path(p.str(), first->generated, kGemSnippet, "glsl430"), ec);
    auto fourth = compile_material(p.str(), "materials/gem.material.json", options);
    REQUIRE(fourth.ok());
    CHECK(fourth->cacheHits == 1);
    CHECK(shdc.calls == 3);
    CHECK(std::find(shdc.argvs[2].begin(), shdc.argvs[2].end(), "glsl430") != shdc.argvs[2].end());
    // useCache = false always compiles
    options.useCache = false;
    REQUIRE(compile_material(p.str(), "materials/gem.material.json", options).ok());
    CHECK(shdc.calls == 4);
}

TEST_CASE("compile: vertex() and clip make the shadow programs and define FA_HAS_VERTEX and FA_ALPHA_CLIP") {
    Project p;
    FakeShdc shdc;
    shdc.reflection = fixture("shdc_shadow_glsl300es.yaml");
    ShaderCompileOptions options;
    options.setup = shdc.context(p.str());
    options.dialects = {"glsl300es"};
    auto r = compile_material(p.str(), "materials/wave.material.json", options);
    REQUIRE(r.ok());
    REQUIRE(r->ok);
    const auto& argv = shdc.argvs[0];
    const auto d = std::find(argv.begin(), argv.end(), "--defines");
    REQUIRE(d != argv.end());
    CHECK(*(d + 1) == "FA_HAS_VERTEX:FA_ALPHA_CLIP");
    const Json& programs = r->twins.at("glsl300es")["programs"];
    CHECK(programs.contains("mesh"));
    CHECK(programs.contains("mesh_skin"));
    CHECK(programs.contains("shadow"));
    CHECK(programs.contains("shadow_skin"));
    CHECK(r->twins.at("glsl300es")["params"] == Json::parse(R"(["alphaCutoff","amp"])"));
}

TEST_CASE("compile: an error in a helper both stages compile is reported once, at the line of the snippet, with the "
          "line quoted") {
    Project p;
    FakeShdc shdc;
    ShaderCompileOptions options;
    options.setup = shdc.context(p.str());
    options.dialects = {"hlsl5"};
    const GeneratedShader g =
        generate_material_shader(read_material(p.str(), "materials/bad.material.json").material, kBadSnippet);
    const int top = top_line_of(g, 7);
    REQUIRE(top > 0);
    const std::string err = "top.glsl:" + std::to_string(top) + ":0: error: 'tnt' : undeclared identifier\n";
    const std::string followOn = "top.glsl:" + std::to_string(top) +
                                 ":0: error: '*' :  wrong operand types: no operation '*' exists that takes a "
                                 "left-hand operand of type ' temp float' and a right operand of type ' temp float'\n";
    shdc.stderrText = err + followOn + err + followOn;  // the vertex stage and the fragment stage both fail
    auto r = compile_material(p.str(), "materials/bad.material.json", options);
    REQUIRE(r.ok());
    CHECK_FALSE(r->ok);
    REQUIRE(r->errors.size() == 1);
    const ShaderIssue& e = r->errors[0];
    CHECK(e.file == "shaders/bad.surface.glsl");
    CHECK(e.line == 7);
    CHECK(e.column == 27);  // the position of tnt in the line
    CHECK(e.source == "    return wobble(uv.x) * tnt;");
    CHECK(e.message.find("'tnt' : undeclared identifier") != std::string::npos);
    CHECK(e.hint.find("did you mean tint?") != std::string::npos);
    const std::string text = e.to_string();
    CHECK(text.find("shaders/bad.surface.glsl:7:27: error:") != std::string::npos);
    CHECK(text.find("7 |     return wobble(uv.x) * tnt;") != std::string::npos);
    CHECK(r->twins.empty());
    // an error is not cached: fixing it compiles again
    CHECK(shdc.calls == 1);
}

TEST_CASE(
    "sprite material: the names of the engine's 2D program are refused for params and textures, mesh keeps them") {
    const auto& names = shaders_detail::template_globals("sprite");
    // derived from quad_common.glsl, color_space.glsl and light_shadow.glsl: the inputs, varyings, block members, textures,
    // samplers, helpers and the defines
    for (const char* n : {"position",     "texcoord0",
                          "color0",       "uv",
                          "color",        "params",
                          "world_xy",     "xform",
                          "world_z",      "view_proj",
                          "cspace",       "fa_time",
                          "lit",          "ambient",
                          "light_pos",    "light_color",
                          "fog_col",      "tex",
                          "normal_tex",   "light_tex",
                          "shadow_tex",   "smp",
                          "light_smp",    "shadow_smp",
                          "frag_color",   "tex_color",
                          "scene_rgb",    "shape_color",
                          "lit_color",    "light_shadow",
                          "shadow_texel", "fa_srgb_to_linear",
                          "vs_params",    "quad_fs_params",
                          "QuadInput",    "main"}) {
        CAPTURE(std::string(n));
        CHECK(names.count(n) > 0);
    }
    // locals of function bodies, struct fields and the user's own names are not globals
    for (const char* n : {"p", "base", "mode", "radius", "amount", "mask", "world_pos", "float", "vec4"}) {
        CAPTURE(std::string(n));
        CHECK(names.count(n) == 0);
    }
    CHECK(shaders_detail::template_globals("mesh").empty());
    CHECK(shaders_detail::template_globals("nonsense").empty());

    const auto sprite = [](const char* params, const char* textures) {
        return parse((std::string(R"({"format":"factoria.material/1","kind":"sprite","shader":"s.glsl","params":{)") +
                      params + R"(},"textures":{)" + textures + "}}")
                         .c_str());
    };
    auto bad = sprite(R"("color":{"type":"float","default":1,"doc":"d"},
                       "lit":{"type":"float","default":1,"doc":"d"},
                       "okName":{"type":"float","default":1,"doc":"d"})",
                      R"("tex":{"sampler":"linearRepeat","doc":"d"},
                         "light":{"sampler":"linearRepeat","doc":"d"},
                         "noise":{"sampler":"linearRepeat","doc":"d"},
                         "fine":{"sampler":"linearRepeat","doc":"d"})");
    CHECK(has_error(bad, "/params/color", "engine's 2D program"));
    CHECK(has_error(bad, "/params/color", "colorValue"));
    CHECK(has_error(bad, "/params/lit", "engine's 2D program"));
    CHECK(has_error(bad, "/textures/tex", "engine's 2D program"));
    CHECK(has_error(bad, "/textures/tex", "texMap"));
    CHECK(has_error(bad, "/textures/light", "light_smp"));  // its sampler would be the engine's light_smp
    CHECK(has_error(bad, "/textures/noise", "sokol-shdc"));
    CHECK_FALSE(has_error(bad, "/params/okName"));
    CHECK_FALSE(has_error(bad, "/textures/fine"));
    CHECK(bad.errors.size() == 5);

    // a mesh material keeps `color`, `uv` and `tex`: the mesh program prefixes or scopes its own names
    const MaterialParse mesh = parse(R"({"format":"factoria.material/1","shader":"s.glsl","params":{
        "color":{"type":"color","default":[1,1,1,1],"doc":"d"},"uv":{"type":"float","default":1,"doc":"d"}},
        "textures":{"tex":{"sampler":"linearRepeat","doc":"d"}}})");
    CHECK(mesh.ok());
    // `noise` breaks sokol-shdc for every kind
    const MaterialParse noise = parse(
        R"({"format":"factoria.material/1","shader":"s.glsl","textures":{"noise":{"sampler":"linearRepeat","doc":"d"}}})");
    CHECK(has_error(noise, "/textures/noise", "noiseMap"));
}

TEST_CASE("sprite material: a snippet that redefines a name of the engine's 2D program gets the hint") {
    Project p;
    p.add_sprite();
    FakeShdc shdc;
    ShaderCompileOptions options;
    options.setup = shdc.context(p.str());
    options.dialects = {"hlsl5"};
    const std::string snippet = "float tex_color = 1.0;\n" + std::string(kSpriteSnippet);
    p.write("shaders/dissolve2d.fragment.glsl", snippet);
    const GeneratedShader g =
        generate_material_shader(read_material(p.str(), "materials/dissolve2d.material.json").material, snippet);
    shdc.stderrText = "top.glsl:" + std::to_string(top_line_of(g, 1)) + ":0: error: 'tex_color' : redefinition\n";
    auto r = compile_material(p.str(), "materials/dissolve2d.material.json", options);
    REQUIRE(r.ok());
    REQUIRE(r->errors.size() == 1);
    CHECK(r->errors[0].hint.find("name taken by the engine's 2D program") != std::string::npos);
    CHECK(r->errors[0].hint.find("is already a global") == std::string::npos);
}

TEST_CASE("compile: hints for the frequent mistakes") {
    Project p;
    FakeShdc shdc;
    ShaderCompileOptions options;
    options.setup = shdc.context(p.str());
    options.dialects = {"hlsl5"};
    auto compile_with = [&](const std::string& snippetLine, const std::string& glslangMessage) {
        const std::string snippet = "void surface(in SurfaceInput i, inout Surface s) {\n" + snippetLine + "\n}\n";
        p.write("shaders/gem.surface.glsl", snippet);
        const GeneratedShader g =
            generate_material_shader(read_material(p.str(), "materials/gem.material.json").material, snippet);
        shdc.stderrText = "top.glsl:" + std::to_string(top_line_of(g, 2)) + ":0: error: " + glslangMessage + "\n";
        auto r = compile_material(p.str(), "materials/gem.material.json", options);
        REQUIRE(r.ok());
        REQUIRE(r->errors.size() == 1);
        return r->errors[0];
    };

    ShaderIssue e = compile_with("    s.colour = tint.rgb;", "'colour' : no such field in structure 's'");
    CHECK(e.line == 2);
    CHECK(e.column == 7);
    CHECK(e.hint.find("did you mean albedo?") != std::string::npos);
    CHECK(e.hint.find("Surface has the fields") != std::string::npos);

    e = compile_with("    vec3 p = i.position;", "'position' : no such field in structure 'i'");
    CHECK(e.hint.find("did you mean world_pos?") != std::string::npos);
    CHECK(e.hint.find("SurfaceInput has the fields") != std::string::npos);

    e = compile_with("    s.albedo = texture(glow, i.uv).rgb;", "'texture' : no matching overloaded function found");
    CHECK(e.hint.find("texture(sampler2D(glow, glow_smp), uv)") != std::string::npos);

    e = compile_with("    s.roughness = pulze;", "'pulze' : undeclared identifier");
    CHECK(e.hint.find("did you mean pulse?") != std::string::npos);

    e = compile_with("    s.albedo = world_pos;", "'world_pos' : undeclared identifier");
    CHECK(e.hint.find("is a field of SurfaceInput: write i.world_pos") != std::string::npos);

    e = compile_with("    s.albedo = fa_tme.xxx;", "'fa_tme' : undeclared identifier");
    CHECK(e.hint.find("did you mean fa_time?") != std::string::npos);

    e = compile_with("    float fa_time2 = 1.0;", "'fa_time' : redefinition");
    CHECK(e.hint.find("Names starting with fa_") != std::string::npos);

    e = compile_with("    s.roughness = 1", "'' :  syntax error, unexpected RIGHT_BRACE, expecting COMMA or SEMICOLON");
    CHECK(e.hint.find("line after the real mistake") != std::string::npos);

    // a param of another material
    p.write("materials/other.material.json", R"({"format":"factoria.material/1","shader":"shaders/gem.surface.glsl",
        "params":{"sparkle":{"type":"float","default":1,"doc":"d"}}})");
    e = compile_with("    s.emission += vec3(sparkle);", "'sparkle' : undeclared identifier");
    CHECK(e.hint.find("materials/other.material.json") != std::string::npos);
}

TEST_CASE("compile: errors outside the snippet say so and name the rule; a missing surface() and fa_ declarations are "
          "found without a compiler") {
    Project p;
    FakeShdc shdc;
    ShaderCompileOptions options;
    options.setup = shdc.context(p.str());
    options.dialects = {"hlsl5"};

    // the template cannot find a matching surface(): reported at the template, with the signature
    p.write("shaders/gem.surface.glsl", "void surface(in SurfaceInput i) {}\n");
    shdc.stderrText = "mesh_common.glsl:289:0: error: 'surface' : no matching overloaded function found\n";
    auto r = compile_material(p.str(), "materials/gem.material.json", options);
    REQUIRE(r.ok());
    REQUIRE(r->errors.size() == 1);
    CHECK(r->errors[0].message.find("not the snippet's") != std::string::npos);
    CHECK(r->errors[0].message.find("mesh_common.glsl:289") != std::string::npos);
    CHECK(r->errors[0].hint.find("void surface(in SurfaceInput i, inout Surface s)") != std::string::npos);
    CHECK(r->errors[0].line == 0);
    CHECK(shdc.calls == 1);

    p.write("shaders/gem.surface.glsl", "void main() {}\nvoid surface(in SurfaceInput i, inout Surface s) {}\n");
    shdc.stderrText = "mesh_common.glsl:145:0: error: 'main' : function already has a body\n";
    r = compile_material(p.str(), "materials/gem.material.json", options);
    REQUIRE(r.ok());
    REQUIRE(r->errors.size() == 1);
    CHECK(r->errors[0].hint.find("owns main()") != std::string::npos);

    // no surface(): found before any process starts
    p.write("shaders/gem.surface.glsl",
            "// void surface(in SurfaceInput i, inout Surface s) {}\nfloat helper() { return 1.0; }\n");
    const int calls = shdc.calls;
    r = compile_material(p.str(), "materials/gem.material.json", options);
    REQUIRE(r.ok());
    REQUIRE(r->errors.size() == 1);
    CHECK(r->errors[0].message.find("no surface() function") != std::string::npos);
    CHECK(r->errors[0].hint.find("void surface(in SurfaceInput i, inout Surface s)") != std::string::npos);
    CHECK(shdc.calls == calls);

    // a snippet declaring an fa_ name: the prefix rule, at its line
    p.write("shaders/gem.surface.glsl",
            "float fa_foo = 1.0;\nfloat fa_bar(float x) { return x; }\nvoid surface(in SurfaceInput i, inout Surface "
            "s) {\n    s.roughness = fa_time.x;\n    return fa_foo;\n}\n");
    r = compile_material(p.str(), "materials/gem.material.json", options);
    REQUIRE(r.ok());
    REQUIRE(r->errors.size() == 2);  // fa_foo and fa_bar; `fa_time.x` is a use and `return fa_foo` too
    CHECK(r->errors[0].line == 1);
    CHECK(r->errors[0].column == 7);
    CHECK(r->errors[0].source == "float fa_foo = 1.0;");
    CHECK(r->errors[0].hint.find("Names starting with fa_ belong to the engine") != std::string::npos);
    CHECK(r->errors[1].line == 2);
    CHECK(shdc.calls == calls);
}

TEST_CASE("compile: lighting custom needs light(): the error names the material file and the fix, before any process "
          "starts; light and ambient are reserved names only there") {
    Project p;
    FakeShdc shdc;
    p.write("materials/toon.material.json", kToonMaterial);
    p.write("shaders/toon.surface.glsl", "void surface(in SurfaceInput i, inout Surface s) {}\n");
    ShaderCompileOptions options;
    options.setup = shdc.context(p.str());
    options.dialects = {"hlsl5"};
    auto r = compile_material(p.str(), "materials/toon.material.json", options);
    REQUIRE(r.ok());
    REQUIRE(r->errors.size() == 1);
    CHECK(r->errors[0].message.find("materials/toon.material.json") != std::string::npos);
    CHECK(r->errors[0].message.find("no light() function") != std::string::npos);
    CHECK(r->errors[0].hint.find("vec3 light(in SurfaceInput i, in Surface s, in LightSample l)") != std::string::npos);
    CHECK(r->errors[0].hint.find("/lighting") != std::string::npos);
    CHECK(r->errors[0].hint.find("l.color") != std::string::npos);
    CHECK(shdc.calls == 0);

    // a light() with the wrong signature: the template cannot find it, and the error says which signature it wants
    p.write("shaders/toon.surface.glsl", "void surface(in SurfaceInput i, inout Surface s) {}\n"
                                         "vec3 light(in Surface s) { return s.albedo; }\n");
    shdc.stderrText = "mesh_common.glsl:424:0: error: 'light' : no matching overloaded function found\n";
    r = compile_material(p.str(), "materials/toon.material.json", options);
    REQUIRE(r.ok());
    REQUIRE(r->errors.size() == 1);
    CHECK(r->errors[0].hint.find("vec3 light(in SurfaceInput i, in Surface s, in LightSample l)") != std::string::npos);
    CHECK(r->errors[0].hint.find("LightSample") != std::string::npos);

    // the LightSample fields get a did-you-mean
    p.write("shaders/toon.surface.glsl", "void surface(in SurfaceInput i, inout Surface s) {}\n"
                                         "vec3 light(in SurfaceInput i, in Surface s, in LightSample l) {\n"
                                         "    return l.colour;\n}\n");
    const GeneratedShader g = generate_material_shader(read_material(p.str(), "materials/toon.material.json").material,
                                                       testing::read_all(p.dir.path / "shaders/toon.surface.glsl"));
    shdc.stderrText =
        "top.glsl:" + std::to_string(top_line_of(g, 3)) + ":0: error: 'colour' : no such field in structure 'l'\n";
    r = compile_material(p.str(), "materials/toon.material.json", options);
    REQUIRE(r.ok());
    REQUIRE(r->errors.size() == 1);
    CHECK(r->errors[0].hint.find("did you mean color?") != std::string::npos);
    CHECK(r->errors[0].hint.find("LightSample has the fields") != std::string::npos);

    // `light` and `ambient` are reserved for the entry points of a custom material only
    auto bad = parse(R"({"format":"factoria.material/1","shader":"s.glsl","lighting":"custom","params":{
        "light":{"type":"float","default":1,"doc":"d"}, "ambient":{"type":"float","default":1,"doc":"d"}}})");
    CHECK(has_error(bad, "/params/light", "name of the snippet contract"));
    CHECK(has_error(bad, "/params/ambient", "name of the snippet contract"));
    CHECK(parse(R"({"format":"factoria.material/1","shader":"s.glsl","params":{
        "light":{"type":"float","default":1,"doc":"d"}}})")
              .ok());
    // LightSample is a type name of the contract in every material
    CHECK(has_error(parse(R"({"format":"factoria.material/1","shader":"s.glsl","params":{
        "LightSample":{"type":"float","default":1,"doc":"d"}}})"),
                    "/params/LightSample"));
    CHECK(parse(R"({"format":"factoria.material/1","shader":"s.glsl","lighting":"custom"})").ok());
    CHECK(has_error(parse(R"({"format":"factoria.material/1","shader":"s.glsl","lighting":"cutom"})"), "/lighting",
                    "Did you mean 'custom'?"));
    auto schema = bundled_read("schemas/material.schema.json");
    REQUIRE(schema.has_value());
    CHECK(validate_json(Json::parse(*schema), Json::parse(kToonMaterial)).empty());
}

TEST_CASE("compile: a material file with errors is reported with its JSON pointer and nothing is started") {
    Project p;
    FakeShdc shdc;
    ShaderCompileOptions options;
    options.setup = shdc.context(p.str());
    p.write("materials/gem.material.json", R"({"format":"factoria.material/1","shader":"shaders/gem.surface.glsl",
        "params":{"x":{"type":"float","default":"0.15","doc":"d"}}})");
    auto r = compile_material(p.str(), "materials/gem.material.json", options);
    REQUIRE(r.ok());
    CHECK_FALSE(r->ok);
    REQUIRE(r->errors.size() == 1);
    CHECK(r->errors[0].file == "materials/gem.material.json");
    CHECK(r->errors[0].pointer == "/params/x/default");
    CHECK(r->errors[0].message.find("expected a number") != std::string::npos);
    CHECK(shdc.calls == 0);
}

TEST_CASE("compile: without sokol-shdc the error names `factoria setup shaders` and SOKOL_SHDC, unless the cache has "
          "the twin") {
    Project p;
    FakeShdc shdc;
    shdc.reflection = fixture("shdc_mesh_hlsl5_glsl430.yaml");
    ShaderCompileOptions with;
    with.setup = shdc.context(p.str());
    with.dialects = {"hlsl5", "glsl430"};
    REQUIRE(compile_material(p.str(), "materials/gem.material.json", with).ok());

    ShaderCompileOptions without;
    without.setup = shdc.context(p.str());
    without.setup.env = [](const std::string&) { return std::string(); };
    without.setup.executableDir = (p.dir.path / "no-exe").string();
    without.setup.home = (p.dir.path / "no-home").string();
    without.dialects = {"hlsl5", "glsl430"};
    auto cached = compile_material(p.str(), "materials/gem.material.json", without);
    REQUIRE(cached.ok());
    CHECK(cached->ok);  // everything from the cache: no compiler needed

    without.useCache = false;
    auto missing = compile_material(p.str(), "materials/gem.material.json", without);
    REQUIRE_FALSE(missing.ok());
    CHECK(missing.error().message.find("sokol-shdc") != std::string::npos);
    CHECK(missing.error().hint.find("factoria setup shaders") != std::string::npos);
    CHECK(missing.error().hint.find("SOKOL_SHDC") != std::string::npos);
    CHECK(missing.error().hint.find("Defender") == std::string::npos);  // linux host
    without.setup.host = "windows";
    auto win = compile_material(p.str(), "materials/gem.material.json", without);
    REQUIRE_FALSE(win.ok());
    CHECK(win.error().hint.find("Windows Defender may have quarantined sokol-shdc.exe") != std::string::npos);
    CHECK(win.error().hint.find("Protection history") != std::string::npos);
    CHECK(win.error().hint.find("factoria setup shaders") != std::string::npos);
}

// ---------------------------------------------------------------------------------------------------------------
// Commands and validate
// ---------------------------------------------------------------------------------------------------------------

TEST_CASE("shader.compile and material.info: arguments, results and teaching errors") {
    Project p;
    FakeShdc shdc;
    shdc.reflection = fixture("shdc_mesh_hlsl5_glsl430.yaml");
    CommandRegistry registry;
    register_shader_commands(registry, p.str(), shdc.context(p.str()));
    REQUIRE(registry.has("shader.compile"));
    REQUIRE(registry.has("material.info"));
    CHECK_FALSE(registry.info("shader.compile")->readOnly);  // it runs sokol-shdc: process
    CHECK(registry.info("shader.compile")->capabilities.has(Capability::Process));
    CHECK(registry.info("material.info")->readOnly);
    CHECK_FALSE(registry.info("shader.compile")->description.empty());

    auto info = registry.call("material.info", Json::parse(R"({"material":"materials/gem.material.json"})"));
    REQUIRE(info.ok);
    CHECK(info.result["lighting"] == "pbr");
    CHECK(info.result["alphaMode"] == "opaque");
    CHECK(info.result["params"][0]["name"] == "pulse");
    CHECK(info.result["params"][0]["max"] == 4.0);
    CHECK(info.result["params"][1]["default"] == Json::parse("[0.2,0.6,1.0,1.0]"));
    CHECK(info.result["textures"][0]["name"] == "glow");
    CHECK(info.result["textures"][0]["doc"] == "Glow mask (rgb).");
    CHECK(info.result["programs"] == Json::parse(R"(["mesh","mesh_skin","prepass","prepass_skin"])"));
    CHECK(info.result["compile"]["state"] == "not_compiled");
    CHECK(info.result["compile"]["dialect"] == "glsl430");
    CHECK(info.result["compile"]["toolFound"] == true);
    auto wave =
        registry.call("material.info", Json::parse(R"({"material":"materials/wave"})"));  // the suffix may be left out
    REQUIRE(wave.ok);
    CHECK(wave.result["programs"].size() == 6);
    CHECK(wave.result["params"][0]["implicit"] == true);

    // compile for two platforms; the dialects come back in the table's order
    auto c = registry.call(
        "shader.compile", Json::parse(R"({"material":"materials/gem.material.json","platforms":["linux","windows"]})"));
    REQUIRE(c.ok);
    CHECK(c.result["ok"] == true);
    CHECK(c.result["dialects"] == Json::parse(R"(["hlsl5","glsl430"])"));
    CHECK(c.result["errors"].empty());
    CHECK(shdc.calls == 1);
    info = registry.call("material.info", Json::parse(R"({"material":"materials/gem.material.json"})"));
    CHECK(info.result["compile"]["state"] == "compiled");  // linux host: glsl430 is in the cache now
    c = registry.call("shader.compile",
                      Json::parse(R"({"material":"materials/gem.material.json","platforms":["windows"]})"));
    REQUIRE(c.ok);
    CHECK(c.result["cached"] == 1);
    CHECK(shdc.calls == 1);

    // errors
    c = registry.call("shader.compile", Json::parse(R"({"material":"materials/gam.material.json"})"));
    CHECK_FALSE(c.ok);
    CHECK(c.error["hint"].get<std::string>().find("Did you mean 'materials/gem.material.json'?") != std::string::npos);
    c = registry.call("shader.compile",
                      Json::parse(R"({"material":"materials/gem.material.json","platforms":["windos"]})"));
    CHECK_FALSE(c.ok);  // the schema's enum refuses it
    c = registry.call("shader.compile", Json::parse(R"({"material":"../outside.material.json"})"));
    CHECK_FALSE(c.ok);

    // a broken snippet comes back as data, with the report
    shdc.stderrText =
        "top.glsl:" +
        std::to_string(top_line_of(
            generate_material_shader(read_material(p.str(), "materials/bad.material.json").material, kBadSnippet), 7)) +
        ":0: error: 'tnt' : undeclared identifier\n";
    c = registry.call("shader.compile",
                      Json::parse(R"({"material":"materials/bad.material.json","platforms":["windows"]})"));
    REQUIRE(c.ok);
    CHECK(c.result["ok"] == false);
    CHECK(c.result["errors"][0]["file"] == "shaders/bad.surface.glsl");
    CHECK(c.result["errors"][0]["line"] == 7);
    CHECK(c.result["errors"][0]["source"] == "    return wobble(uv.x) * tnt;");
    CHECK(c.result["report"].get<std::string>().find("shaders/bad.surface.glsl:7:") != std::string::npos);

    // no compiler: a teaching error
    CommandRegistry bare;
    SetupContext none = shdc.context(p.str());
    none.env = [](const std::string&) { return std::string(); };
    none.executableDir = (p.dir.path / "no-exe").string();
    none.home = (p.dir.path / "no-home").string();
    register_shader_commands(bare, p.str(), none);
    c = bare.call("shader.compile", Json::parse(R"({"material":"materials/wave.material.json"})"));
    REQUIRE_FALSE(c.ok);
    CHECK(c.error["hint"].get<std::string>().find("factoria setup shaders") != std::string::npos);
    CHECK(c.error["hint"].get<std::string>().find("SOKOL_SHDC") != std::string::npos);
}

TEST_CASE("validate: every material is checked and compiled; without sokol-shdc a warning says the snippets were not "
          "compiled") {
    testing::TempDir tmp;
    REQUIRE(create_project(tmp.sub("game"), "2d-empty").ok());
    const std::string dir = tmp.sub("game");
    REQUIRE(validate_project(dir).ok);
    CHECK(validate_project(dir).materialsChecked == 0);

    testing::write_all(stdfs::path(dir) / "materials/gem.material.json", kGemMaterial);
    testing::write_all(stdfs::path(dir) / "shaders/gem.surface.glsl", kGemSnippet);

    FakeShdc shdc;
    shdc.reflection = fixture("shdc_mesh_hlsl5_glsl430.yaml");
    ValidateOptions none;
    none.shaderContext = shdc.context(tmp.sub("home"));
    none.shaderContext.env = [](const std::string&) { return std::string(); };
    none.shaderContext.executableDir = tmp.sub("no-exe");
    ValidationReport report = validate_project(dir, none);
    CHECK(report.ok);
    CHECK(report.materialsChecked == 1);
    const auto warning = std::find_if(report.warnings.begin(), report.warnings.end(), [](const ValidationIssue& w) {
        return w.message.find("not compiled") != std::string::npos;
    });
    REQUIRE(warning != report.warnings.end());
    CHECK(warning->hint.find("factoria setup shaders") != std::string::npos);
    CHECK(warning->hint.find("SOKOL_SHDC") != std::string::npos);
    CHECK(warning->hint.find("Defender") == std::string::npos);  // linux host
    none.shaderContext.host = "windows";
    const auto winWarning = [&] {
        ValidationReport r = validate_project(dir, none);
        return std::find_if(
                   r.warnings.begin(), r.warnings.end(),
                   [](const ValidationIssue& w) { return w.message.find("not compiled") != std::string::npos; })
            ->hint;
    }();
    CHECK(winWarning.find("Windows Defender may have quarantined sokol-shdc.exe") != std::string::npos);
    none.shaderContext.host = "linux";

    // a material file with a mistake is an error even without a compiler
    testing::write_all(stdfs::path(dir) / "materials/bad.material.json",
                       R"({"format":"factoria.material/1","shader":"shaders/gem.surface.glsl","lighting":"pbs"})");
    report = validate_project(dir, none);
    CHECK_FALSE(report.ok);
    const auto err = std::find_if(report.errors.begin(), report.errors.end(),
                                  [](const ValidationIssue& e) { return e.file == "materials/bad.material.json"; });
    REQUIRE(err != report.errors.end());
    CHECK(err->pointer == "/lighting");
    stdfs::remove(stdfs::path(dir) / "materials/bad.material.json");

    // with the compiler (injected): compiled for all six dialects, so the fake must know them all; use a failing run to see the mapping
    ValidateOptions failing;
    failing.shaderContext = shdc.context(tmp.sub("home"));
    testing::write_all(stdfs::path(dir) / "materials/bad.material.json", kBadMaterial);
    testing::write_all(stdfs::path(dir) / "shaders/bad.surface.glsl", kBadSnippet);
    stdfs::remove(stdfs::path(dir) / "materials/gem.material.json");
    stdfs::remove(stdfs::path(dir) / "shaders/gem.surface.glsl");
    const GeneratedShader g = generate_material_shader(
        parse_material(Json::parse(kBadMaterial), dir, "materials/bad.material.json").material, kBadSnippet);
    shdc.stderrText = "top.glsl:" + std::to_string(top_line_of(g, 7)) + ":0: error: 'tnt' : undeclared identifier\n";
    failing.shaderContext.run = shdc.runner();
    report = validate_project(dir, failing);
    CHECK_FALSE(report.ok);
    const auto shaderError = std::find_if(report.errors.begin(), report.errors.end(), [](const ValidationIssue& e) {
        return e.file == "shaders/bad.surface.glsl";
    });
    REQUIRE(shaderError != report.errors.end());
    CHECK(shaderError->message.find("line 7, column 27") != std::string::npos);
    CHECK(shaderError->message.find("tnt") != std::string::npos);
    CHECK(shaderError->hint.find("did you mean tint?") != std::string::npos);
}

// ---------------------------------------------------------------------------------------------------------------
// The real sokol-shdc
// ---------------------------------------------------------------------------------------------------------------

namespace {
// A project whose compiler is the real one; false (and a message) when none is installed.
bool real_tool(SetupContext& context) {
    context = SetupContext{};
    if (find_sokol_shdc(context).empty()) {
        FA_FAIL_IF_SHDC_REQUIRED();
        MESSAGE("sokol-shdc is not installed (SOKOL_SHDC, next to factoria, or `factoria setup shaders`): the "
                "real-compiler tests are skipped here and run in CI");
        return false;
    }
    return true;
}
}  // namespace

TEST_CASE("real sokol-shdc: the fixture material compiles to every dialect and the twins list the shadow programs only "
          "with vertex() or clip") {
    SetupContext context;
    if (!real_tool(context)) return;
    Project p;
    ShaderCompileOptions options;
    options.setup = context;
    options.useCache = false;

    auto gem = compile_material(p.str(), "materials/gem.material.json", options);
    REQUIRE(gem.ok());
    const std::string gemWhy = gem->errors.empty() ? std::string() : gem->errors[0].to_string();
    INFO(gemWhy);
    REQUIRE(gem->ok);
    REQUIRE(gem->twins.size() == 6);
    for (const std::string slang : {"hlsl5", "glsl430", "glsl300es", "metal_macos", "metal_ios", "metal_sim"}) {
        CAPTURE(slang);
        REQUIRE(gem->twins.count(slang) == 1);
        const Json& twin = gem->twins.at(slang);
        CHECK(twin["slang"] == slang);
        CHECK(twin["programs"].size() == 4);
        CHECK(twin["programs"].contains("mesh"));
        CHECK(twin["programs"].contains("mesh_skin"));
        CHECK_FALSE(twin["programs"]["mesh"]["vs"].get<std::string>().empty());
        CHECK_FALSE(twin["programs"]["mesh"]["fs"].get<std::string>().empty());
        // position, normal, uv, tangent, vertex color and the four instance-matrix rows
        CHECK(twin["programs"]["mesh"]["reflection"]["attrs"].size() == 9);
        // the material block is in the fragment stage only, its texture is view 6
        bool block = false;
        for (const Json& ub : twin["programs"]["mesh"]["reflection"]["uniform_blocks"])
            if (ub["struct_name"] == "fa_material") {
                block = true;
                CHECK(ub["stage"] == "fragment");
                CHECK(ub["slot"] == 5);
                CHECK(ub["size"] == 32);  // two params, one vec4 each
            }
        CHECK(block);
    }

    auto wave = compile_material(p.str(), "materials/wave.material.json", options);
    REQUIRE(wave.ok());
    const std::string waveWhy = wave->errors.empty() ? std::string() : wave->errors[0].to_string();
    INFO(waveWhy);
    REQUIRE(wave->ok);
    for (const auto& [slang, twin] : wave->twins) {
        CAPTURE(slang);
        CHECK(twin["programs"].size() == 6);
        CHECK(twin["programs"].contains("shadow"));
        CHECK(twin["programs"].contains("shadow_skin"));
        // vertex() reads amp: the vertex stage has its own block, at binding 4
        bool vsBlock = false;
        for (const Json& ub : twin["programs"]["mesh"]["reflection"]["uniform_blocks"])
            if (ub["struct_name"] == "fa_material_vs") {
                vsBlock = true;
                CHECK(ub["stage"] == "vertex");
                CHECK(ub["slot"] == 4);
            }
        CHECK(vsBlock);
    }

    // the second compile of the unchanged material is the cache's
    options.useCache = true;
    REQUIRE(compile_material(p.str(), "materials/gem.material.json", options)->ok);
    auto again = compile_material(p.str(), "materials/gem.material.json", options);
    REQUIRE(again.ok());
    CHECK(again->cacheHits == 6);
}

TEST_CASE("real sokol-shdc: a sprite material compiles to every dialect with the 2D slots, and with vertex() too") {
    SetupContext context;
    if (!real_tool(context)) return;
    Project p;
    p.add_sprite();
    ShaderCompileOptions options;
    options.setup = context;
    options.useCache = false;
    // a vertex() of the sprite contract: a wobble of the corners, reading a param (the vertex stage block)
    const std::string vertexSnippet =
        std::string(kSpriteSnippet) +
        "void vertex(inout QuadVertex v) { v.world_pos.y += sin(v.world_pos.x + fa_time.x) * amount; }\n";
    for (const bool withVertex : {false, true}) {
        CAPTURE(withVertex);
        p.write("shaders/dissolve2d.fragment.glsl", withVertex ? vertexSnippet : std::string(kSpriteSnippet));
        auto r = compile_material(p.str(), "materials/dissolve2d.material.json", options);
        REQUIRE(r.ok());
        const std::string why = r->errors.empty() ? std::string() : r->errors[0].to_string();
        INFO(why);
        REQUIRE(r->ok);
        REQUIRE(r->twins.size() == 6);
        for (const auto& [slang, twin] : r->twins) {
            CAPTURE(slang);
            CHECK(twin["kind"] == "sprite");
            REQUIRE(twin["programs"].size() == 2);
            for (const char* program : {"quad", "quad_plain"}) {
                CAPTURE(program);
                REQUIRE(twin["programs"].contains(program));
                const Json& refl = twin["programs"][program]["reflection"];
                // the engine's views 0-3 and samplers 0-2 stay, the material's mask is view 4 and sampler 3
                bool mask = false, block = false, vsBlock = false;
                for (const Json& v : refl["views"])
                    if (v["texture"]["name"] == "mask") {
                        mask = true;
                        CHECK(v["texture"]["slot"] == 4);
                    }
                for (const Json& ub : refl["uniform_blocks"]) {
                    if (ub["struct_name"] == "fa_material") {
                        block = true;
                        CHECK(ub["slot"] == 5);
                    }
                    if (ub["struct_name"] == "fa_material_vs") vsBlock = true;
                }
                CHECK(mask);
                CHECK(block);
                CHECK(vsBlock == withVertex);  // both programs share the vertex shader
            }
        }
    }
}

TEST_CASE("real sokol-shdc: errors are mapped to the snippet once, with hints") {
    SetupContext context;
    if (!real_tool(context)) return;
    Project p;
    ShaderCompileOptions options;
    options.setup = context;
    options.dialects = {"hlsl5", "glsl430"};
    options.useCache = false;

    // Line 7 of a helper both stages compile.
    auto bad = compile_material(p.str(), "materials/bad.material.json", options);
    REQUIRE(bad.ok());
    REQUIRE_FALSE(bad->ok);
    REQUIRE(bad->errors.size() == 1);
    CHECK(bad->errors[0].file == "shaders/bad.surface.glsl");
    CHECK(bad->errors[0].line == 7);
    CHECK(bad->errors[0].column > 0);
    CHECK(bad->errors[0].source == "    return wobble(uv.x) * tnt;");
    CHECK(bad->errors[0].hint.find("did you mean tint?") != std::string::npos);
    CHECK(bad->errors[0].to_string().find("shaders/bad.surface.glsl:7:") != std::string::npos);

    auto one = [&](const std::string& body) {
        p.write("shaders/gem.surface.glsl", "void surface(in SurfaceInput i, inout Surface s) {\n" + body + "\n}\n");
        auto r = compile_material(p.str(), "materials/gem.material.json", options);
        REQUIRE(r.ok());
        REQUIRE_FALSE(r->ok);
        REQUIRE_FALSE(r->errors.empty());
        return r->errors[0];
    };
    ShaderIssue e = one("    s.colour = tint.rgb;");
    CHECK(e.line == 2);
    CHECK(e.hint.find("did you mean albedo?") != std::string::npos);
    e = one("    s.albedo = texture(glow, i.uv).rgb;");
    CHECK(e.line == 2);
    CHECK(e.hint.find("sampler2D(glow, glow_smp)") != std::string::npos);
    e = one("    s.albedo = vec3(1.0)");  // missing ;
    CHECK(e.file == "shaders/gem.surface.glsl");
    CHECK(e.hint.find("syntax") != std::string::npos);
    e = one("    s.roughness = pulze;");
    CHECK(e.hint.find("did you mean pulse?") != std::string::npos);

    // outside the snippet: the signature is wrong
    p.write("shaders/gem.surface.glsl", "void surface(in SurfaceInput i) {}\n");
    auto wrong = compile_material(p.str(), "materials/gem.material.json", options);
    REQUIRE(wrong.ok());
    REQUIRE(wrong->errors.size() == 1);
    CHECK(wrong->errors[0].message.find("not the snippet's") != std::string::npos);
    CHECK(wrong->errors[0].hint.find("void surface(in SurfaceInput i, inout Surface s)") != std::string::npos);

    // the engine's main() cannot be redefined
    p.write("shaders/gem.surface.glsl", "void main() {}\nvoid surface(in SurfaceInput i, inout Surface s) {}\n");
    auto mainRedef = compile_material(p.str(), "materials/gem.material.json", options);
    REQUIRE(mainRedef.ok());
    REQUIRE_FALSE(mainRedef->errors.empty());
    CHECK(mainRedef->errors[0].message.find("not the snippet's") != std::string::npos);
}

TEST_CASE("real sokol-shdc: a texture read in vertex() compiles to every dialect, both stages and the shadow program "
          "bind it, and a custom light() is compiled and mapped to the snippet") {
    SetupContext context;
    if (!real_tool(context)) return;
    Project p;
    p.write("shaders/wave.surface.glsl",
            "void vertex(inout VertexData v) {\n    v.world_pos.y += texture(sampler2D(h, h_smp), v.uv).r;\n}\n"
            "void surface(in SurfaceInput i, inout Surface s) {\n    s.albedo *= texture(sampler2D(h, h_smp), "
            "i.uv).r;\n}\n");
    p.write(
        "materials/wave.material.json",
        R"({"format":"factoria.material/1","shader":"shaders/wave.surface.glsl","textures":{"h":{"doc":"Height map (r)."}}})");
    ShaderCompileOptions options;
    options.setup = context;
    options.useCache = false;
    auto r = compile_material(p.str(), "materials/wave.material.json", options);
    REQUIRE(r.ok());
    const std::string why = r->errors.empty() ? std::string() : r->errors[0].to_string();
    INFO(why);
    REQUIRE(r->ok);
    REQUIRE(r->twins.size() == 6);
    for (const auto& [slang, twin] : r->twins) {
        CAPTURE(slang);
        for (const char* program : {"mesh", "shadow"}) {
            CAPTURE(program);
            const Json& refl = twin["programs"][program]["reflection"];
            bool vertexView = false, fragmentView = false;
            for (const Json& entry : refl["views"]) {
                const Json& v = entry["texture"];
                if (v["stage"] == "vertex") {
                    vertexView = true;
                    CHECK(v["slot"] == kMaterialVsFirstView);
                }
                if (v["stage"] == "fragment" && v["name"] == "h") {
                    fragmentView = true;
                    CHECK(v["slot"] == kMaterialFsFirstView);
                }
            }
            CHECK(vertexView);
            CHECK(fragmentView == (std::string(program) == "mesh"));  // the shadow program has no fragment texture
        }
    }

    // lighting custom: light() and ambient() compile in every dialect, in the fragment stage only
    p.write("materials/toon.material.json", kToonMaterial);
    p.write("shaders/toon.surface.glsl", kToonSnippet);
    auto toon = compile_material(p.str(), "materials/toon.material.json", options);
    REQUIRE(toon.ok());
    const std::string toonWhy = toon->errors.empty() ? std::string() : toon->errors[0].to_string();
    INFO(toonWhy);
    REQUIRE(toon->ok);
    CHECK(toon->twins.size() == 6);

    // a mistake inside light() is reported at its line of the snippet, with the fields of LightSample
    p.write("shaders/toon.surface.glsl", "void surface(in SurfaceInput i, inout Surface s) {}\n"
                                         "vec3 light(in SurfaceInput i, in Surface s, in LightSample l) {\n"
                                         "    return s.albedo * l.colour;\n}\n");
    auto bad = compile_material(p.str(), "materials/toon.material.json", options);
    REQUIRE(bad.ok());
    REQUIRE_FALSE(bad->ok);
    REQUIRE(bad->errors.size() >= 1);
    CHECK(bad->errors[0].line == 3);
    CHECK(bad->errors[0].hint.find("did you mean color?") != std::string::npos);
}

TEST_CASE("engine compiler: returns the twin, and an error with every issue's file:line:col and the first hint") {
    Project p;
    FakeShdc shdc;
    shdc.reflection = fixture("shdc_mesh_hlsl5_glsl430.yaml");
    const ShaderCompiler compiler = make_engine_shader_compiler(p.str(), shdc.context(p.str()));
    auto twin = compiler("materials/gem.material.json", "hlsl5");
    REQUIRE(twin.ok());
    CHECK((*twin)["slang"] == "hlsl5");

    const GeneratedShader g =
        generate_material_shader(read_material(p.str(), "materials/bad.material.json").material, kBadSnippet);
    const int top = top_line_of(g, 7);
    shdc.stderrText = "top.glsl:" + std::to_string(top) + ":0: error: 'tnt' : undeclared identifier\n";
    auto bad = compiler("materials/bad.material.json", "hlsl5");
    REQUIRE_FALSE(bad.ok());
    CHECK(bad.error().message.find("shaders/bad.surface.glsl:7:27: error:") != std::string::npos);
    CHECK(bad.error().message.find("return wobble(uv.x) * tnt;") != std::string::npos);
    CHECK(bad.error().hint.find("did you mean tint?") != std::string::npos);

    auto missing = compiler("materials/none.material.json", "hlsl5");
    CHECK_FALSE(missing.ok());
}
