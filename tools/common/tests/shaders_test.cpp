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

// A sky material: a starfield (the reflection fixture shdc_sky_hlsl5_glsl430.yaml is its compile).
const char* kSkyMaterial = R"({
  "format": "factoria.material/1",
  "kind": "sky",
  "doc": "A starfield that twinkles.",
  "shader": "shaders/stars.sky.glsl",
  "params": {
    "twinkle": { "type": "float", "default": 0.5, "min": 0.0, "max": 1.0, "doc": "How much the stars flicker." },
    "tint": { "type": "color", "default": [0.8, 0.9, 1.0, 1.0], "doc": "Color of the stars." }
  },
  "textures": { "stars": { "sampler": "linearRepeat", "doc": "Star map (r), looked up by the view direction." } }
})";

// sky() is the sky entry point and, as surface() of a mesh material, runs in the fragment stage only.
const char* kSkySnippet = R"(void sky(in SkyInput i, inout SkySurface s) {
    float n = texture(sampler2D(stars, stars_smp), i.dir.xz * 2.0).r;
    s.color += tint.rgb * n * (1.0 - twinkle + twinkle * sin(i.time * 4.0));
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
    void add_sky() {
        write("materials/stars.material.json", kSkyMaterial);
        write("shaders/stars.sky.glsl", kSkySnippet);
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
            bool template_present = false;
            for (const auto& e : stdfs::directory_iterator(work))
                template_present = template_present || e.path().filename().string().ends_with("_common.glsl");
            CHECK(template_present);
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

TEST_CASE("material kind: every kind has programs and compiles, none is refused as unsupported") {
    Project p;
    p.add_sprite();
    p.add_sky();
    p.add_post();
    FakeShdc shdc;
    CommandRegistry registry;
    register_shader_commands(registry, p.str(), shdc.context(p.str()));
    const std::vector<std::pair<std::string, std::string>> kinds = {
        {"sprite", "dissolve2d"}, {"sky", "stars"}, {"post", "tint"}};
    for (const auto& [kind, name] : kinds) {
        CAPTURE(kind);
        auto info =
            registry.call("material.info", Json::parse(R"({"material":"materials/)" + name + R"(.material.json"})"));
        REQUIRE(info.ok);
        CHECK(info.result["kind"] == kind);
        CHECK_FALSE(info.result["programs"].empty());
        CHECK(info.result["compile"]["state"] == "not_compiled");  // nothing in the cache yet; never "unsupported"
        CHECK_FALSE(info.result["compile"].contains("hint"));
    }
    // `factoria validate` compiles every kind: the project's three mesh materials and the three others, one run each
    ValidationReport report;
    validate_materials(p.str(), shdc.context(p.str()), report);
    CHECK(shdc.calls == 6);
    for (const auto& e : report.errors) CHECK(e.message.find("is not compiled yet") == std::string::npos);
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
// Compute materials (M72.4)
// ---------------------------------------------------------------------------------------------------------------

const char* const kComputeMaterial = R"({
  "format": "factoria.material/1",
  "kind": "compute",
  "shader": "shaders/move.compute.glsl",
  "workgroupSize": [64],
  "params": { "speed": { "type": "float", "default": 1.0, "doc": "Units per second." } },
  "buffers": {
    "particles": { "doc": "The particles.", "fields": [
      { "name": "pos", "type": "vec3", "doc": "Position." },
      { "name": "life", "type": "float" } ] },
    "src": { "access": "read", "fields": [ { "name": "v", "type": "vec4" } ] }
  }
})";
const char* const kComputeSnippet = R"(void compute(in ComputeInput i) {
    uint k = i.global_id.x;
    particles.data[k].pos = src.data[k].v.xyz * speed;
    particles.data[k].life = float(k);
}
)";

TEST_CASE("compute material: the file is read, the buffers are laid out as std430 and sorted by name") {
    const auto r = parse(kComputeMaterial);
    REQUIRE(r.ok());
    const MaterialDef& m = r.material;
    CHECK(m.kind == "compute");
    CHECK(m.workgroupSize[0] == 64);
    CHECK(m.workgroupSize[1] == 1);
    CHECK(m.workgroupSize[2] == 1);
    REQUIRE(m.buffers.size() == 2);
    CHECK(m.buffers[0].name == "particles");
    CHECK(m.buffers[0].binding == 0);
    CHECK(m.buffers[0].access == "readWrite");
    CHECK(m.buffers[0].fields[0].offset == 0);  // vec3 at 0 (size 12), the float fits in its padding
    CHECK(m.buffers[0].fields[1].offset == 12);
    CHECK(m.buffers[0].stride == 16);
    CHECK(m.buffers[1].name == "src");
    CHECK(m.buffers[1].binding == 1);
    CHECK(m.buffers[1].access == "read");
    CHECK(m.buffers[1].stride == 16);
    // the default workgroup is 64 x 1 x 1
    CHECK(parse(R"({"format":"factoria.material/1","kind":"compute","shader":"s.glsl"})").material.workgroupSize[0] ==
          64);
    // vec2 aligns to 8, vec3 and vec4 to 16, the stride rounds up to the widest alignment
    const auto layout = parse(
        R"({"format":"factoria.material/1","kind":"compute","shader":"s.glsl","buffers":{"b":{"fields":[
        {"name":"a","type":"float"},{"name":"b","type":"vec2"},{"name":"c","type":"vec3"},{"name":"d","type":"uint"}]}}})");
    REQUIRE(layout.ok());
    const auto& f = layout.material.buffers[0].fields;
    CHECK(f[0].offset == 0);
    CHECK(f[1].offset == 8);
    CHECK(f[2].offset == 16);
    CHECK(f[3].offset == 28);
    CHECK(layout.material.buffers[0].stride == 32);
    // the schema accepts it
    const Json schema = Json::parse(*bundled_read("schemas/material.schema.json"));
    CHECK(validate_json(Json::parse(kComputeMaterial), schema).empty());
}

TEST_CASE("compute material: errors name the JSON pointer, the problem and the fix") {
    const std::string head = R"({"format":"factoria.material/1","kind":"compute","shader":"s.glsl",)";
    auto bad = parse((head + R"("workgroupSize":[0]})").c_str());
    CHECK(has_error(bad, "/workgroupSize/0", "whole number from 1 to 256"));
    bad = parse((head + R"("workgroupSize":[32,32]})").c_str());
    CHECK(has_error(bad, "/workgroupSize", "1024 threads"));
    CHECK(has_error(bad, "/workgroupSize", "dispatch more workgroups"));
    bad = parse((head + R"("workgroupSize":[8]})").c_str());
    CHECK(has_error(bad, "/workgroupSize", "8 threads (8 x 1 x 1), which is not a multiple of 32"));
    CHECK(parse((head + R"("workgroupSize":[8,8]})").c_str()).errors.empty());
    bad = parse((head + R"("workgroupSize":[1,1,128]})").c_str());  // 128 threads, but z is limited to 64
    CHECK(has_error(bad, "/workgroupSize/2", "z is 128, at most 64"));
    CHECK(has_error(bad, "/workgroupSize/2", "[8, 8, 1] or [4, 4, 4]"));
    CHECK(parse((head + R"("workgroupSize":[1,1,64]})").c_str()).errors.empty());
    bad = parse((head + R"("workgroupSize":"big"})").c_str());
    CHECK(has_error(bad, "/workgroupSize", "1 to 3 integers"));
    bad = parse((head + R"("buffers":{"b":{"fields":[{"name":"x","type":"flaot"}]}}})").c_str());
    CHECK(has_error(bad, "/buffers/b/fields/0/type", "Did you mean 'float'?"));
    bad = parse((head + R"("buffers":{"b":{"fields":[{"name":"x","type":"float","tpye":1}]}}})").c_str());
    CHECK(has_error(bad, "/buffers/b/fields/0/tpye", "unknown key"));
    bad = parse((head + R"("buffers":{"b":{"access":"readwrite","fields":[{"name":"x","type":"float"}]}}})").c_str());
    CHECK(has_error(bad, "/buffers/b/access", "Did you mean 'readWrite'?"));
    bad = parse((head + R"("buffers":{"b":{"fields":[]}}})").c_str());
    CHECK(has_error(bad, "/buffers/b/fields", "non-empty array"));
    bad = parse((head + R"("buffers":{"b":{}}})").c_str());
    CHECK(has_error(bad, "/buffers/b/fields", "missing \"fields\""));
    bad = parse(
        (head + R"("buffers":{"b":{"fields":[{"name":"x","type":"float"},{"name":"x","type":"int"}]}}})").c_str());
    CHECK(has_error(bad, "/buffers/b/fields/1/name", "used twice"));
    // names: reserved words and the namespace shared with params, textures and the element type
    bad = parse((head + R"("buffers":{"fa_b":{"fields":[{"name":"x","type":"float"}]}}})").c_str());
    CHECK(has_error(bad, "/buffers/fa_b"));
    bad = parse(
        (head +
         R"("params":{"b":{"type":"float","default":0}},"buffers":{"b":{"fields":[{"name":"x","type":"float"}]}}})")
            .c_str());
    CHECK(has_error(bad, "/buffers/b", "used twice"));
    bad = parse(
        (head +
         R"("params":{"b_item":{"type":"float","default":0}},"buffers":{"b":{"fields":[{"name":"x","type":"float"}]}}})")
            .c_str());
    CHECK(has_error(bad, "/buffers/b", "b_item"));
    // at most four buffers
    std::string many = head + R"("buffers":{)";
    for (int i = 0; i < 5; ++i)
        many += std::string(i ? "," : "") + "\"b" + std::to_string(i) + R"(":{"fields":[{"name":"x","type":"float"}]})";
    bad = parse((many + "}}").c_str());
    CHECK(has_error(bad, "/buffers", "5 buffers, at most 4"));
    // compute keys on another kind, mesh keys on a compute material
    bad = parse(R"({"format":"factoria.material/1","shader":"s.glsl","workgroupSize":[8]})");
    CHECK(has_error(bad, "/workgroupSize", "\"kind\": \"compute\""));
    bad = parse(R"({"format":"factoria.material/1","shader":"s.glsl","buffers":{}})");
    CHECK(has_error(bad, "/buffers", "belongs to compute materials"));
    bad = parse((head + R"("lighting":"lit","alphaMode":"clip","doubleSided":true})").c_str());
    CHECK(has_error(bad, "/lighting", "does not apply"));
    CHECK(has_error(bad, "/alphaMode", "does not apply"));
    CHECK(has_error(bad, "/doubleSided", "does not apply"));
}

TEST_CASE("compute material: the generated top file declares the params, buffers, textures, workgroup and snippet") {
    const auto r = parse(kComputeMaterial);
    REQUIRE(r.ok());
    const auto g = generate_material_shader(r.material, kComputeSnippet);
    CHECK(g.kind == "compute");
    CHECK(g.hasCompute);
    CHECK(g.programs == std::vector<std::string>{"compute"});
    CHECK(g.top.find("@include compute_common.glsl") != std::string::npos);
    CHECK(g.top.find("@program compute fa_cs") != std::string::npos);
    CHECK(g.top.find("layout(binding=0) uniform fa_material {") != std::string::npos);
    CHECK(g.top.find("struct particles_item { vec3 pos; float life; };") != std::string::npos);
    CHECK(g.top.find("layout(binding=0) buffer fa_particles_buf { particles_item data[]; } particles;") !=
          std::string::npos);
    CHECK(g.top.find("layout(binding=1) readonly buffer fa_src_buf { src_item data[]; } src;") != std::string::npos);
    CHECK(g.top.find("layout(local_size_x=64, local_size_y=1, local_size_z=1) in;") != std::string::npos);
    CHECK(g.snippetLine.size() == std::size_t(std::count(g.top.begin(), g.top.end(), '\n')));
    CHECK(top_line_of(g, 1) > 0);
    // a snippet without compute() is flagged, comments do not count
    CHECK_FALSE(generate_material_shader(r.material, "// void compute(in ComputeInput i) {}\n").hasCompute);
    // textures bind after the buffers
    const auto t = parse(R"({"format":"factoria.material/1","kind":"compute","shader":"s.glsl",
        "textures":{"tex":{"doc":"Input."}},"buffers":{"b":{"fields":[{"name":"x","type":"float"}]}}})");
    REQUIRE(t.ok());
    const auto gt = generate_material_shader(t.material, "void compute(in ComputeInput i) {}\n");
    CHECK(gt.top.find("layout(binding=1) uniform texture2D tex;") != std::string::npos);
    CHECK(gt.top.find("layout(binding=0) uniform sampler tex_smp;") != std::string::npos);
}

TEST_CASE(
    "compute material: compiles for the dialects with compute, skips glsl300es, and the twin carries the buffers") {
    Project p;
    p.write("materials/move.material.json", kComputeMaterial);
    p.write("shaders/move.compute.glsl", kComputeSnippet);
    FakeShdc shdc;
    shdc.reflection = fixture("shdc_compute_hlsl5_glsl430_metal.yaml");
    ShaderCompileOptions options;
    options.setup = shdc.context(p.str());
    options.dialects = {"hlsl5", "glsl430", "glsl300es", "metal_macos"};
    auto r = compile_material(p.str(), "materials/move.material.json", options);
    REQUIRE(r.ok());
    const std::string why = r->errors.empty() ? std::string() : r->errors[0].to_string();
    INFO(why);
    REQUIRE(r->ok);
    CHECK(shdc.calls == 1);
    CHECK(r->skippedDialects == std::vector<std::string>{"glsl300es"});
    REQUIRE(r->twins.size() == 3);
    CHECK(std::find(shdc.argvs[0].begin(), shdc.argvs[0].end(), "hlsl5:glsl430:metal_macos") != shdc.argvs[0].end());
    const Json& twin = r->twins.at("hlsl5");
    CHECK(twin["kind"] == "compute");
    CHECK(twin["template"] == shader_template_hash("compute"));
    CHECK(twin["workgroupSize"] == Json::parse("[64,1,1]"));
    REQUIRE(twin["buffers"].size() == 2);
    CHECK(twin["buffers"][0]["name"] == "particles");
    CHECK(twin["buffers"][0]["stride"] == 16);
    CHECK(twin["buffers"][0]["fields"][1] == Json::parse(R"({"name":"life","type":"float","offset":12})"));
    CHECK(twin["buffers"][1]["access"] == "read");
    REQUIRE(twin["programs"].contains("compute"));
    CHECK_FALSE(twin["programs"].contains("mesh"));
    CHECK(twin["programs"]["compute"]["cs"].get<std::string>().find("generated source") != std::string::npos);
    CHECK(twin["programs"]["compute"]["reflection"]["compute_func"]["d3d11_target"] == "cs_5_0");
    CHECK(r->twins.at("metal_macos")["programs"]["compute"]["reflection"]["mtl_threads_per_threadgroup"]["x"] == 64);

    // no dialects asked: every one that has compute
    options.dialects.clear();
    options.useCache = false;
    r = compile_material(p.str(), "materials/move.material.json", options);
    REQUIRE(r.ok());
    CHECK(r->dialects == shader_dialects_of_kind("compute"));
    CHECK(r->skippedDialects.empty());

    // the platforms that have no compute: nothing is compiled, and the result says why
    options.dialects = {"glsl300es"};
    const int calls = shdc.calls;
    r = compile_material(p.str(), "materials/move.material.json", options);
    REQUIRE(r.ok());
    CHECK(r->ok);
    CHECK(r->twins.empty());
    CHECK(r->skippedDialects == std::vector<std::string>{"glsl300es"});
    CHECK(shdc.calls == calls);
}

TEST_CASE("compute material: a snippet without compute() says what to define") {
    Project p;
    p.write("materials/move.material.json", kComputeMaterial);
    p.write("shaders/move.compute.glsl", "void surface(in SurfaceInput i, inout Surface s) {}\n");
    FakeShdc shdc;
    ShaderCompileOptions options;
    options.setup = shdc.context(p.str());
    auto r = compile_material(p.str(), "materials/move.material.json", options);
    REQUIRE(r.ok());
    CHECK_FALSE(r->ok);
    REQUIRE_FALSE(r->errors.empty());
    CHECK(r->errors[0].message.find("compute()") != std::string::npos);
    CHECK(r->errors[0].hint.find("ComputeInput") != std::string::npos);
    CHECK(shdc.calls == 0);
}

TEST_CASE("compute material: shader.compile and material.info list where it runs, the workgroup and the buffers") {
    Project p;
    p.write("materials/move.material.json", kComputeMaterial);
    p.write("shaders/move.compute.glsl", kComputeSnippet);
    FakeShdc shdc;
    shdc.reflection = fixture("shdc_compute_hlsl5_glsl430_metal.yaml");
    CommandRegistry registry;
    register_shader_commands(registry, p.str(), shdc.context(p.str()));
    auto info = registry.call("material.info", Json::parse(R"({"material":"materials/move.material.json"})"));
    REQUIRE(info.ok);
    CHECK(info.result["kind"] == "compute");
    CHECK(info.result["runsOn"] == Json::parse(R"(["windows","linux","macos","ios"])"));
    CHECK(info.result["notOn"] == Json::parse(R"(["android","web"])"));
    CHECK(info.result["workgroupSize"] == Json::parse("[64,1,1]"));
    REQUIRE(info.result["buffers"].size() == 2);
    CHECK(info.result["buffers"][0]["name"] == "particles");
    CHECK(info.result["buffers"][0]["stride"] == 16);
    CHECK(info.result["buffers"][0]["fields"][0]["offset"] == 0);
    CHECK(info.result["buffers"][1]["access"] == "read");
    CHECK(info.result["compile"]["state"] != "unsupported");
    auto c = registry.call("shader.compile",
                           Json::parse(R"({"material":"materials/move.material.json","platforms":["web"]})"));
    REQUIRE(c.ok);
    CHECK(c.result["ok"] == true);
    CHECK(c.result["skippedDialects"] == Json::parse(R"(["glsl300es"])"));
    CHECK(c.result["note"].get<std::string>().find("glsl300es") != std::string::npos);
    CHECK(c.result["notOn"] == Json::parse(R"(["android","web"])"));
}

// ---------------------------------------------------------------------------------------------------------------
// Storage images of a compute material (M72.17)
// ---------------------------------------------------------------------------------------------------------------

const char* const kImageMaterial = R"({
  "format": "factoria.material/1",
  "kind": "compute",
  "shader": "shaders/paint.compute.glsl",
  "workgroupSize": [8, 8],
  "textures": { "palette": { "doc": "Colours." } },
  "buffers": { "seeds": { "access": "read", "fields": [ { "name": "v", "type": "vec4" } ] } },
  "images": {
    "heat": { "doc": "Heat.", "format": "r32f", "access": "readWrite", "size": [64, 32] },
    "albedo": { "doc": "Colour.", "format": "rgba8", "size": [128] },
    "plain": {}
  }
})";

TEST_CASE("compute images: declared with a format, an access and a size, sorted by name, bound after the buffers") {
    const auto r = parse(kImageMaterial);
    REQUIRE(r.ok());
    const MaterialDef& m = r.material;
    REQUIRE(m.images.size() == 3);
    CHECK(m.images[0].name == "albedo");
    CHECK(m.images[0].format == "rgba8");
    CHECK(m.images[0].access == "write");  // the default
    CHECK(m.images[0].width == 128);
    CHECK(m.images[0].height == 128);  // one number is a square
    CHECK(m.images[0].binding == 1);   // after the one buffer
    CHECK(m.images[1].name == "heat");
    CHECK(m.images[1].format == "r32f");
    CHECK(m.images[1].access == "readWrite");
    CHECK(m.images[1].width == 64);
    CHECK(m.images[1].height == 32);
    CHECK(m.images[1].binding == 2);
    CHECK(m.images[2].name == "plain");
    CHECK(m.images[2].format == "rgba8");  // the defaults of an empty entry
    CHECK(m.images[2].width == kComputeDefaultImageSize);
    CHECK(m.images[2].binding == 3);
    const Json schema = Json::parse(*bundled_read("schemas/material.schema.json"));
    CHECK(validate_json(Json::parse(kImageMaterial), schema).empty());
}

TEST_CASE("compute images: errors name the JSON pointer, the problem and the fix") {
    const std::string head = R"({"format":"factoria.material/1","kind":"compute","shader":"s.glsl","images":)";
    auto bad = parse((head + R"({"a":{"format":"rgb8"}}})").c_str());
    CHECK(has_error(bad, "/images/a/format", "unknown image format \"rgb8\""));
    CHECK(has_error(bad, "/images/a/format", "rgba8, rgba16f, r32f, rgba32f"));
    bad = parse((head + R"({"a":{"format":"rgba16"}}})").c_str());
    CHECK(has_error(bad, "/images/a/format", "Did you mean"));
    bad = parse((head + R"({"a":{"access":"read"}}})").c_str());
    CHECK(has_error(bad, "/images/a/access", "cannot be read-only"));
    CHECK(has_error(bad, "/images/a/access", "declare it a texture"));
    bad = parse((head + R"({"a":{"access":"readwrite"}}})").c_str());
    CHECK(has_error(bad, "/images/a/access", "unknown access \"readwrite\""));
    CHECK(has_error(bad, "/images/a/access", "readWrite"));
    bad = parse((head + R"({"a":{"size":[0,4]}}})").c_str());
    CHECK(has_error(bad, "/images/a/size/0", "whole number from 1 to 8192"));
    bad = parse((head + R"({"a":{"size":[9000]}}})").c_str());
    CHECK(has_error(bad, "/images/a/size/0", "whole number from 1 to 8192"));
    bad = parse((head + R"({"a":{"size":[1,2,3]}}})").c_str());
    CHECK(has_error(bad, "/images/a/size", "expected an array of 1 or 2 integers"));
    bad = parse((head + R"({"a":{"size":"big"}}})").c_str());
    CHECK(has_error(bad, "/images/a/size", "expected an array of 1 or 2 integers"));
    bad = parse((head + R"({"a":{"fromat":"rgba8"}}})").c_str());
    CHECK(has_error(bad, "/images/a/fromat", "unknown key"));
    CHECK(has_error(bad, "/images/a/fromat", "format"));
    bad = parse((head + R"({"a":3}})").c_str());
    CHECK(has_error(bad, "/images/a", "expected an object"));
    bad = parse((head + R"([]})").c_str());
    CHECK(has_error(bad, "/images", "expected an object"));
    // more images than the storage image bindings every GPU with compute guarantees
    bad = parse((head + R"({"a":{},"b":{},"c":{},"d":{},"e":{}}})").c_str());
    CHECK(has_error(bad, "/images", "5 images, at most 4"));
    // the namespace is shared with the buffers, params and textures
    bad = parse(R"({"format":"factoria.material/1","kind":"compute","shader":"s.glsl",
        "textures":{"a":{}},"images":{"a":{}}})");
    CHECK_FALSE(bad.errors.empty());
    // a material of another kind has no storage images
    bad = parse(R"({"format":"factoria.material/1","shader":"s.glsl","images":{}})");
    CHECK(has_error(bad, "/images", "belongs to compute materials"));
}

TEST_CASE("compute images: the generated top file declares each image where the shader compiler numbers it") {
    const auto r = parse(kImageMaterial);
    REQUIRE(r.ok());
    const auto g = generate_material_shader(r.material, "void compute(in ComputeInput i) {}\n");
    CHECK(g.top.find("layout(binding=1, rgba8) uniform writeonly image2D albedo;") != std::string::npos);
    CHECK(g.top.find("layout(binding=2, r32f) uniform image2D heat;") != std::string::npos);  // readWrite: no writeonly
    CHECK(g.top.find("layout(binding=3, rgba8) uniform writeonly image2D plain;") != std::string::npos);
    // the textures come after the buffers and the images
    CHECK(g.top.find("layout(binding=4) uniform texture2D palette;") != std::string::npos);
    CHECK(g.top.find("layout(binding=0) uniform sampler palette_smp;") != std::string::npos);
    CHECK(g.snippetLine.size() == std::size_t(std::count(g.top.begin(), g.top.end(), '\n')));
}

TEST_CASE("compute images: material.info lists them with their format, access and size") {
    Project p;
    p.write("materials/paint.material.json", kImageMaterial);
    p.write("shaders/paint.compute.glsl", "void compute(in ComputeInput i) {}\n");
    FakeShdc shdc;
    CommandRegistry registry;
    register_shader_commands(registry, p.str(), shdc.context(p.str()));
    auto info = registry.call("material.info", Json::parse(R"({"material":"materials/paint.material.json"})"));
    REQUIRE(info.ok);
    REQUIRE(info.result["images"].size() == 3);
    CHECK(info.result["images"][0]["name"] == "albedo");
    CHECK(info.result["images"][0]["format"] == "rgba8");
    CHECK(info.result["images"][0]["access"] == "write");
    CHECK(info.result["images"][1]["name"] == "heat");
    CHECK(info.result["images"][1]["access"] == "readWrite");
    CHECK(info.result["images"][1]["width"] == 64);
    CHECK(info.result["images"][1]["height"] == 32);
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

    // a sprite's vertex() samples a material texture through its own vertex-stage view and sampler (slots 8.. and 7..,
    // after the fragment stage's 4.. and 3..), the same way a mesh material does
    const std::string sampling =
        std::string(kSpriteSnippet) +
        "void vertex(inout QuadVertex v) { v.world_pos.y += texture(sampler2D(mask, mask_smp), vec2(0.5)).r; }\n";
    const MaterialParse vsParse = read_material(p.str(), "materials/dissolve2d.material.json");
    REQUIRE(vsParse.ok());
    const GeneratedShader gv = generate_material_shader(vsParse.material, sampling);
    CHECK(gv.hasVertex);
    CHECK(gv.top.find("#define mask fa_vs_mask") != std::string::npos);
    CHECK(gv.top.find("layout(binding=8) uniform texture2D mask;") != std::string::npos);
    CHECK(gv.top.find("layout(binding=7) uniform sampler mask_smp;") != std::string::npos);
    CHECK(gv.top.find("layout(binding=4) uniform texture2D mask;") != std::string::npos);
    CHECK(gv.top.find("layout(binding=3) uniform sampler mask_smp;") != std::string::npos);
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

TEST_CASE(
    "sky material: the generator includes sky_common.glsl, takes views and samplers from 0 and lists the sky program") {
    Project p;
    p.add_sky();
    const MaterialParse parsed = read_material(p.str(), "materials/stars.material.json");
    REQUIRE(parsed.ok());
    CHECK(parsed.material.kind == "sky");
    const GeneratedShader g = generate_material_shader(parsed.material, kSkySnippet);
    CHECK(g.kind == "sky");
    CHECK(g.hasSurface);  // the sky() entry point
    CHECK_FALSE(g.hasVertex);
    CHECK(g.programs == std::vector<std::string>{"sky"});
    CHECK(g.defines.empty());  // the engine's own program is the same with an empty hook: nothing to switch
    CHECK(g.top.find("@include sky_common.glsl") != std::string::npos);
    CHECK(g.top.find("@include mesh_common.glsl") == std::string::npos);
    CHECK(g.top.find("@include quad_common.glsl") == std::string::npos);
    CHECK(g.top.find("@program sky vs fs\n") != std::string::npos);
    CHECK(g.top.find("@program mesh") == std::string::npos);
    // the engine binds no texture for the sky: the first texture of a material is view 0, sampler 0
    CHECK(g.top.find("layout(binding=0) uniform texture2D stars;") != std::string::npos);
    CHECK(g.top.find("layout(binding=0) uniform sampler stars_smp;") != std::string::npos);
    CHECK(g.top.find("layout(binding=5) uniform fa_material {") != std::string::npos);
    CHECK(g.top.find("#ifdef GL_FRAGMENT_SHADER\nvoid sky(in SkyInput i, inout SkySurface s) {") != std::string::npos);
    // a surface() or fragment() is not the entry point of a sky
    CHECK_FALSE(
        generate_material_shader(parsed.material, "void surface(in SurfaceInput i, inout Surface s) {}\n").hasSurface);
    CHECK_FALSE(generate_material_shader(parsed.material, "void fragment(in QuadInput i, inout QuadSurface s) {}\n")
                    .hasSurface);
    // the names of the contract: sky is a reserved name of a sky material only
    CHECK(has_error(parse(R"({"format":"factoria.material/1","kind":"sky","shader":"s.glsl","params":{
        "sky":{"type":"float","default":1,"doc":"d"}}})"),
                    "/params/sky"));
    CHECK_FALSE(has_error(parse(R"({"format":"factoria.material/1","shader":"s.glsl","params":{
        "sky":{"type":"float","default":1,"doc":"d"}}})"),
                          "/params/sky"));
    // the sky program's globals are not available as params
    CHECK(has_error(parse(R"({"format":"factoria.material/1","kind":"sky","shader":"s.glsl","params":{
        "ray_dir":{"type":"float","default":1,"doc":"d"}}})"),
                    "/params/ray_dir", "sky program"));
}

TEST_CASE("sky material: with an empty sky() the generated top file is sky.glsl, the engine's own program, modulo the "
          "user block") {
    MaterialDef m;
    m.kind = "sky";
    m.shader = "shaders/empty.glsl";
    const GeneratedShader g = generate_material_shader(m, "void sky(in SkyInput i, inout SkySurface s) {}\n");
    const std::string builtIn = testing::read_all(stdfs::path(FA_REPO_ROOT) / "engine/render/shaders/sky.glsl");
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
    CHECK(tail == "@include sky_common.glsl\n@program sky vs fs\n");
    CHECK(after_block(builtIn) == tail);
    CHECK(g.top.find("void sky(in SkyInput i, inout SkySurface s) {}") != std::string::npos);
    CHECK(builtIn.find("void sky(in SkyInput i, inout SkySurface s) {}") != std::string::npos);
    CHECK(g.defines.empty());
}

TEST_CASE("sky material: errors name sky() and the sky contract; lighting custom, alphaMode and vertex() are refused") {
    Project p;
    p.add_sky();
    FakeShdc shdc;
    shdc.reflection = fixture("shdc_sky_hlsl5_glsl430.yaml");
    ShaderCompileOptions options;
    options.setup = shdc.context(p.str());
    options.dialects = {"hlsl5"};

    // no sky(): the message and the hint are the sky's
    p.write("shaders/stars.sky.glsl", "void surface(in SurfaceInput i, inout Surface s) {}\n");
    auto r = compile_material(p.str(), "materials/stars.material.json", options);
    REQUIRE(r.ok());
    CHECK_FALSE(r->ok);
    REQUIRE_FALSE(r->errors.empty());
    CHECK(r->errors[0].message.find("defines no sky() function") != std::string::npos);
    CHECK(r->errors[0].hint.find("void sky(in SkyInput i, inout SkySurface s)") != std::string::npos);
    CHECK(r->errors[0].hint.find("s.color arrives holding the engine's sky") != std::string::npos);
    CHECK(shdc.calls == 0);

    // a mistake in the snippet is mapped to its line, with the fields of SkyInput and the aliases of the sun
    const std::string bad = "void sky(in SkyInput i, inout SkySurface s) {\n    s.color *= i.sun;\n}\n";
    p.write("shaders/stars.sky.glsl", bad);
    const GeneratedShader g =
        generate_material_shader(read_material(p.str(), "materials/stars.material.json").material, bad);
    shdc.stderrText =
        "top.glsl:" + std::to_string(top_line_of(g, 2)) + ":0: error: 'sun' : no such field in structure 'i'\n";
    r = compile_material(p.str(), "materials/stars.material.json", options);
    REQUIRE(r.ok());
    REQUIRE(r->errors.size() == 1);
    CHECK(r->errors[0].line == 2);
    CHECK(r->errors[0].hint.find("did you mean sun_dir?") != std::string::npos);
    CHECK(r->errors[0].hint.find("SkyInput has the fields") != std::string::npos);

    // the light() hook, the alpha modes and a vertex stage mean nothing for a sky
    auto light = parse(R"({"format":"factoria.material/1","kind":"sky","shader":"s.glsl","lighting":"custom"})");
    CHECK(has_error(light, "/lighting", "not lit"));
    auto clip = parse(R"({"format":"factoria.material/1","kind":"sky","shader":"s.glsl","alphaMode":"clip"})");
    CHECK(has_error(clip, "/alphaMode", "opaque background"));
    auto blend = parse(R"({"format":"factoria.material/1","kind":"sky","shader":"s.glsl","alphaMode":"blend"})");
    CHECK(has_error(blend, "/alphaMode", "opaque background"));
    auto ok = parse(R"({"format":"factoria.material/1","kind":"sky","shader":"s.glsl","lighting":"unlit",
        "alphaMode":"opaque","doubleSided":true})");
    CHECK(ok.ok());

    shdc.stderrText.clear();
    shdc.calls = 0;
    p.write("shaders/stars.sky.glsl",
            std::string(kSkySnippet) + "void vertex(inout VertexData v) { v.world_pos.y += 1.0; }\n");
    r = compile_material(p.str(), "materials/stars.material.json", options);
    REQUIRE(r.ok());
    CHECK_FALSE(r->ok);
    REQUIRE_FALSE(r->errors.empty());
    CHECK(r->errors[0].message.find("a sky material has no vertex()") != std::string::npos);
    CHECK(shdc.calls == 0);
}

TEST_CASE("sky material: compile writes a twin with the sky template hash and the program sky") {
    Project p;
    p.add_sky();
    FakeShdc shdc;
    shdc.reflection = fixture("shdc_sky_hlsl5_glsl430.yaml");
    ShaderCompileOptions options;
    options.setup = shdc.context(p.str());
    options.dialects = {"hlsl5", "glsl430"};

    auto first = compile_material(p.str(), "materials/stars.material.json", options);
    REQUIRE(first.ok());
    const std::string why = first->errors.empty() ? std::string() : first->errors[0].to_string();
    INFO(why);
    REQUIRE(first->ok);
    CHECK(shdc.calls == 1);
    CHECK(first->material.kind == "sky");
    CHECK(first->generated.kind == "sky");
    REQUIRE(first->twins.size() == 2);
    const Json& twin = first->twins.at("hlsl5");
    CHECK(twin["format"] == "factoria.shader/1");
    CHECK(twin["kind"] == "sky");
    CHECK(twin["template"] == shader_template_hash("sky"));
    CHECK(twin["template"] != shader_template_hash("mesh"));
    CHECK(twin["template"] != shader_template_hash("sprite"));
    CHECK(twin["params"] == Json::parse(R"(["tint","twinkle"])"));
    CHECK(twin["textures"] == Json::parse(R"(["stars"])"));
    REQUIRE(twin["programs"].contains("sky"));
    CHECK(twin["programs"].size() == 1);
    CHECK(twin["programs"]["sky"]["reflection"]["vertex_func"]["d3d11_target"] == "vs_5_0");
    auto second = compile_material(p.str(), "materials/stars.material.json", options);
    REQUIRE(second.ok());
    CHECK(second->cacheHits == 2);
    CHECK(shdc.calls == 1);

    CommandRegistry registry;
    register_shader_commands(registry, p.str(), shdc.context(p.str()));
    auto c = registry.call("shader.compile",
                           Json::parse(R"({"material":"materials/stars.material.json","platforms":["linux"]})"));
    REQUIRE(c.ok);
    CHECK(c.result["ok"] == true);
    CHECK(c.result["kind"] == "sky");
    auto info = registry.call("material.info", Json::parse(R"({"material":"materials/stars.material.json"})"));
    REQUIRE(info.ok);
    CHECK(info.result["kind"] == "sky");
    CHECK(info.result["programs"] == Json::parse(R"(["sky"])"));
}

TEST_CASE("sky material: validate compiles it next to the mesh materials") {
    Project p;
    p.add_sky();
    FakeShdc shdc;
    shdc.reflection = fixture("shdc_sky_hlsl5_glsl430.yaml");
    for (const char* name : {"gem", "wave", "bad"})
        stdfs::remove(p.dir.path / "materials" / (std::string(name) + ".material.json"));
    ValidationReport report;
    validate_materials(p.str(), shdc.context(p.str()), report);
    CHECK(report.materialsChecked == 1);
    CHECK(shdc.calls == 1);
    for (const auto& e : report.errors) CHECK(e.message.find("is not compiled yet") == std::string::npos);

    const std::string bad = "void sky(in SkyInput i, inout SkySurface s) {\n    s.color = tnt;\n}\n";
    p.write("shaders/stars.sky.glsl", bad);
    const GeneratedShader g =
        generate_material_shader(read_material(p.str(), "materials/stars.material.json").material, bad);
    shdc.stderrText = "top.glsl:" + std::to_string(top_line_of(g, 2)) + ":0: error: 'tnt' : undeclared identifier\n";
    ValidationReport failing;
    validate_materials(p.str(), shdc.context(p.str()), failing);
    CHECK_FALSE(failing.ok);
    const auto err = std::find_if(failing.errors.begin(), failing.errors.end(),
                                  [](const ValidationIssue& e) { return e.file == "shaders/stars.sky.glsl"; });
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

TEST_CASE("post material: fa_history is a function of a post material; the mistakes are refused before sokol-shdc with "
          "a hint") {
    Project p;
    p.add_post();
    FakeShdc shdc;
    shdc.reflection = fixture("shdc_post_hlsl5_glsl430.yaml");
    ShaderCompileOptions options;
    options.setup = shdc.context(p.str());
    options.dialects = {"hlsl5"};

    // used as a texture
    p.write("shaders/tint.post.glsl", "void post(in PostInput i, inout PostSurface s) {\n    s.color = "
                                      "texture(sampler2D(fa_history, x), i.uv);\n}\n");
    auto r = compile_material(p.str(), "materials/tint.material.json", options);
    REQUIRE(r.ok());
    CHECK_FALSE(r->ok);
    REQUIRE_FALSE(r->errors.empty());
    CHECK(r->errors[0].message.find("it is a function, not a texture") != std::string::npos);
    CHECK(r->errors[0].line == 2);
    CHECK(r->errors[0].hint.find("fa_history(i.uv)") != std::string::npos);

    // the flag called as a function
    p.write("shaders/tint.post.glsl", "void post(in PostInput i, inout PostSurface s) {\n    if (fa_history_valid()) "
                                      "s.color = fa_history(i.uv);\n}\n");
    r = compile_material(p.str(), "materials/tint.material.json", options);
    REQUIRE(r.ok());
    CHECK_FALSE(r->ok);
    REQUIRE_FALSE(r->errors.empty());
    CHECK(r->errors[0].message.find("it is a value, not a function") != std::string::npos);
    CHECK(r->errors[0].hint.find("if (fa_history_valid)") != std::string::npos);
    CHECK(shdc.calls == 0);

    // the names other engines use for the previous frame point at fa_history
    const std::string guess = "void post(in PostInput i, inout PostSurface s) {\n    s.color = prevFrame;\n}\n";
    p.write("shaders/tint.post.glsl", guess);
    const GeneratedShader g =
        generate_material_shader(read_material(p.str(), "materials/tint.material.json").material, guess);
    shdc.stderrText =
        "top.glsl:" + std::to_string(top_line_of(g, 2)) + ":0: error: 'prevFrame' : undeclared identifier\n";
    r = compile_material(p.str(), "materials/tint.material.json", options);
    REQUIRE(r.ok());
    REQUIRE_FALSE(r->errors.empty());
    CHECK(r->errors[0].hint.find("fa_history(uv)") != std::string::npos);
    shdc.stderrText.clear();

    // a misspelt helper gets a did-you-mean among the post's engine names
    const std::string typo = "void post(in PostInput i, inout PostSurface s) {\n    s.color = vec4(fa_histroy);\n}\n";
    p.write("shaders/tint.post.glsl", typo);
    const GeneratedShader t =
        generate_material_shader(read_material(p.str(), "materials/tint.material.json").material, typo);
    shdc.stderrText =
        "top.glsl:" + std::to_string(top_line_of(t, 2)) + ":0: error: 'fa_histroy' : undeclared identifier\n";
    r = compile_material(p.str(), "materials/tint.material.json", options);
    REQUIRE(r.ok());
    REQUIRE_FALSE(r->errors.empty());
    CHECK(r->errors[0].hint.find("fa_history") != std::string::npos);
    shdc.stderrText.clear();

    // a good call reaches sokol-shdc
    const int before = shdc.calls;
    p.write(
        "shaders/tint.post.glsl",
        "void post(in PostInput i, inout PostSurface s) {\n    if (fa_history_valid) s.color = fa_history(i.uv);\n}\n");
    r = compile_material(p.str(), "materials/tint.material.json", options);
    REQUIRE(r.ok());
    CHECK(shdc.calls == before + 1);
}

TEST_CASE("post material: the history view is the one after the material's textures") {
    CHECK(kMaterialPostHistoryView == kMaterialPostFirstView + kMaterialMaxTextures);
    CHECK(kMaterialPostHistoryView > kMaterialPostFirstView + 3);
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
    // a texture named like a field of the contract (s.normal, s.albedo...) is a valid name: surface() reads it in the fragment stage
    // only; the clash in vertex() or a shared helper is explained by the compile hint (the test "a texture named like a field")
    const MaterialParse field = parse(
        R"({"format":"factoria.material/1","shader":"s.glsl","textures":{"normal":{"sampler":"linearRepeat","doc":"d"},
            "albedo":{"sampler":"linearRepeat","doc":"d"}}})");
    CHECK(field.ok());
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

TEST_CASE("sprite material: fa_sample_main in a vertex stage says it is fragment-only; did you mean offers documented "
          "names") {
    Project p;
    p.add_sprite();
    FakeShdc shdc;
    ShaderCompileOptions options;
    options.setup = shdc.context(p.str());
    options.dialects = {"hlsl5"};
    const MaterialDef material = read_material(p.str(), "materials/dissolve2d.material.json").material;
    auto compile_snippet = [&](const std::string& snippet, const std::string& message) {
        p.write("shaders/dissolve2d.fragment.glsl", snippet);
        const GeneratedShader g = generate_material_shader(material, snippet);
        shdc.stderrText = "top.glsl:" + std::to_string(top_line_of(g, 1)) + ":0: error: " + message + "\n";
        auto r = compile_material(p.str(), "materials/dissolve2d.material.json", options);
        REQUIRE(r.ok());
        REQUIRE(r->errors.size() == 1);
        return r->errors[0];
    };
    // a helper that vertex() calls is compiled into the vertex stage, where the main texture is not bound
    ShaderIssue e = compile_snippet("vec4 grab(vec2 p) { return fa_sample_main(p); }\n"
                                    "void vertex(inout QuadVertex v) { v.position.xy += grab(v.position.xy).xy; }\n" +
                                        std::string(kSpriteSnippet),
                                    "'fa_sample_main' : no matching overloaded function found");
    CHECK(e.hint.find("fragment stage only") != std::string::npos);
    CHECK(e.hint.find("vec4 fa_sample_main(vec2 p)") != std::string::npos);
    // a misspelled name: the suggestion is one the docs list, never an internal name of quad_common.glsl
    e = compile_snippet("float x = fa_inst_flgs;\n" + std::string(kSpriteSnippet),
                        "'fa_inst_flgs' : undeclared identifier");
    CHECK(e.hint.find("fa_inst_flags") == std::string::npos);
    CHECK(e.hint.find("fa_sample_main()") != std::string::npos);
    e = compile_snippet("float x = fa_sample_mian(vec2(0.0)).r;\n" + std::string(kSpriteSnippet),
                        "'fa_sample_mian' : undeclared identifier");
    CHECK(e.hint.find("did you mean fa_sample_main?") != std::string::npos);
}

TEST_CASE("compile: the engine names a \"did you mean\" suggests are the ones the docs list for the kind") {
    const auto names_in = [](const char* page) {
        const std::string text = testing::read_all(stdfs::path(FA_REPO_ROOT) / page);
        std::set<std::string> out;
        static const std::regex name(R"(\bfa_[a-z0-9_]+)");
        for (auto it = std::sregex_iterator(text.begin(), text.end(), name); it != std::sregex_iterator(); ++it)
            out.insert(it->str());
        return out;
    };
    const auto list_of = [](const char* kind, bool full) {
        MaterialDef m;
        m.kind = kind;
        m.full = full;
        const auto& names = shaders_detail::documented_engine_names(m);
        return std::set<std::string>(names.begin(), names.end());
    };
    // the pages of the post and the full shaders document these names and no others: the lists are equal to them
    CHECK(list_of("post", false) == names_in("docs/shaders/SHADERS_POST.md"));
    CHECK(list_of("mesh", true) == names_in("docs/shaders/SHADERS_FULL.md"));
    // SHADERS.md documents the mesh, sprite and sky names (and the lighting functions, which have their own list): each one is in it
    const std::set<std::string> guide = names_in("docs/SHADERS.md");
    for (const char* kind : {"mesh", "sprite", "sky"})
        for (const std::string& name : list_of(kind, false)) {
            CAPTURE(kind);
            CHECK_MESSAGE(guide.count(name) == 1, name << " is suggested for a " << kind
                                                       << " material but docs/SHADERS.md does not mention it");
        }
}

namespace {
bool real_tool(SetupContext& context);
}

TEST_CASE("real sokol-shdc: a texture named like a field compiles when only surface() reads it; vertex() reading it "
          "gets the hint") {
    SetupContext context;
    if (!real_tool(context)) return;
    ShaderCompileOptions options;
    options.setup = context;
    options.dialects = {"hlsl5", "glsl430", "glsl300es"};
    options.useCache = false;
    Project p;
    const auto material = [](const char* textures) {
        return std::string(R"({"format":"factoria.material/1","shader":"shaders/n.surface.glsl","textures":{)") +
               textures + "}}";
    };
    // `normal` and `albedo` are fields of Surface and textures here: the texture is renamed in the vertex stage only
    p.write("materials/n.material.json",
            material(R"("normal":{"sampler":"linearRepeat","doc":"d"},"albedo":{"sampler":"linearRepeat","doc":"d"})"));
    p.write("shaders/n.surface.glsl",
            "void surface(in SurfaceInput i, inout Surface s) {\n"
            "    s.albedo = texture(sampler2D(albedo, albedo_smp), i.uv).rgb;\n"
            "    s.normal = normalize(s.normal + texture(sampler2D(normal, normal_smp), i.uv).xyz * 0.01);\n}\n");
    auto ok = compile_material(p.str(), "materials/n.material.json", options);
    REQUIRE(ok.ok());
    const std::string why = ok->errors.empty() ? std::string() : ok->errors[0].to_string();
    INFO(why);
    CHECK(ok->ok);
    // vertex() reads the field `uv` of VertexData while a texture is called `uv`: the vertex stage reads `v.fa_vs_uv`
    p.write("materials/n.material.json", material(R"("uv":{"sampler":"linearRepeat","doc":"d"})"));
    p.write("shaders/n.surface.glsl", "void vertex(inout VertexData v) {\n    v.uv *= 2.0;\n}\n"
                                      "void surface(in SurfaceInput i, inout Surface s) {\n"
                                      "    s.albedo = texture(sampler2D(uv, uv_smp), i.uv).rgb;\n}\n");
    auto bad = compile_material(p.str(), "materials/n.material.json", options);
    REQUIRE(bad.ok());
    REQUIRE_FALSE(bad->ok);
    REQUIRE_FALSE(bad->errors.empty());
    INFO(bad->errors[0].to_string());
    CHECK(bad->errors[0].line == 2);
    CHECK(bad->errors[0].hint.find("Rename the texture") != std::string::npos);
    CHECK(bad->errors[0].hint.find("uvMap") != std::string::npos);
}

TEST_CASE(
    "real sokol-shdc: a sprite vertex() may call fa_scene_rgb(), and fa_sample_main() there gets the stage hint") {
    SetupContext context;
    if (!real_tool(context)) return;
    ShaderCompileOptions options;
    options.setup = context;
    options.useCache = false;
    Project p;
    p.add_sprite();
    p.write("shaders/dissolve2d.fragment.glsl",
            "void vertex(inout QuadVertex v) {\n    v.color.rgb *= fa_scene_rgb(vec3(1.0, 0.5, 0.2));\n}\n" +
                std::string(kSpriteSnippet));
    auto ok = compile_material(p.str(), "materials/dissolve2d.material.json", options);
    REQUIRE(ok.ok());
    const std::string why = ok->errors.empty() ? std::string() : ok->errors[0].to_string();
    INFO(why);
    CHECK(ok->ok);
    p.write("shaders/dissolve2d.fragment.glsl",
            "void vertex(inout QuadVertex v) {\n    v.color *= fa_sample_main(v.uv);\n}\n" +
                std::string(kSpriteSnippet));
    auto bad = compile_material(p.str(), "materials/dissolve2d.material.json", options);
    REQUIRE(bad.ok());
    REQUIRE_FALSE(bad->ok);
    REQUIRE_FALSE(bad->errors.empty());
    INFO(bad->errors[0].to_string());
    CHECK(bad->errors[0].line == 2);
    CHECK(bad->errors[0].hint.find("fragment stage only") != std::string::npos);
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

TEST_CASE(
    "compile: lighting() is the whole light loop: the generator, the errors and the did-you-mean of its functions") {
    Project p;
    FakeShdc shdc;
    p.write("materials/toon.material.json", kToonMaterial);
    ShaderCompileOptions options;
    options.setup = shdc.context(p.str());
    options.dialects = {"hlsl5"};
    const std::string surface = "void surface(in SurfaceInput i, inout Surface s) {}\n";
    const std::string loop = "vec3 lighting(in SurfaceInput i, in Surface s) {\n"
                             "    vec3 lit = fa_ambient.rgb * s.albedo;\n"
                             "    for (int n = 0; n < fa_light_count(); ++n) lit += fa_light(n, i).color * s.albedo;\n"
                             "    return lit + fa_sky_light(i, s);\n}\n";
    const MaterialDef custom = read_material(p.str(), "materials/toon.material.json").material;
    auto errors_of = [&](const MaterialDef& material, const std::string& snippet) {
        p.write(material.shader, snippet);
        shdc.calls = 0;
        return compile_material(p.str(), "materials/toon.material.json", options);
    };

    // the hook alone is a complete custom lighting: no "defines no light()" error, FA_HAS_LIGHTING, no FA_HAS_AMBIENT
    const GeneratedShader g = generate_material_shader(custom, surface + loop);
    CHECK(g.hasLighting);
    CHECK_FALSE(g.hasLight);
    CHECK_FALSE(g.lightingWithoutCustom);
    CHECK(g.defines == std::vector<std::string>{"FA_CUSTOM_LIGHT", "FA_HAS_LIGHTING"});
    CHECK(g.top.find("#ifdef GL_FRAGMENT_SHADER\nvec3 lighting(in SurfaceInput i") != std::string::npos);
    auto r = errors_of(custom, surface + loop);
    // the checks before sokol-shdc found nothing to refuse (the fake one runs once and writes no reflection file)
    CHECK(shdc.calls == 1);

    // a helper that is called lighting() but takes something else is not the hook
    const GeneratedShader helper =
        generate_material_shader(custom, surface + "vec3 lighting(vec3 a) { return a; }\n"
                                                   "vec3 light(in SurfaceInput i, in Surface s, "
                                                   "in LightSample l) { return lighting(l.color); }\n");
    CHECK_FALSE(helper.hasLighting);
    CHECK(helper.hasLight);
    CHECK(helper.defines == std::vector<std::string>{"FA_CUSTOM_LIGHT"});

    // a commented hook does not count
    CHECK_FALSE(generate_material_shader(custom, surface + "// " + loop + "\n").hasLighting);

    // the hook and light() (or ambient()) together: the engine would never call the second
    r = errors_of(custom, surface + loop +
                              "vec3 light(in SurfaceInput i, in Surface s, in LightSample l) { return vec3(0.0); }\n");
    REQUIRE(r.ok());
    REQUIRE(r->errors.size() == 1);
    CHECK(r->errors[0].message.find("defines both lighting() and light()") != std::string::npos);
    CHECK(r->errors[0].hint.find("Remove light()") != std::string::npos);
    CHECK(r->errors[0].line == 7);  // where light() is defined
    CHECK(shdc.calls == 0);
    r = errors_of(custom,
                  surface + loop +
                      "vec3 ambient(in SurfaceInput i, in Surface s, vec3 ambientColor) { return ambientColor; }\n");
    REQUIRE(r.ok());
    REQUIRE(r->errors.size() == 1);
    CHECK(r->errors[0].message.find("defines both lighting() and ambient()") != std::string::npos);

    // the hook in a material without "lighting": "custom" says where to set it
    MaterialDef pbr = custom;
    pbr.lighting = "pbr";
    std::string pbrFile = kToonMaterial;
    pbrFile.replace(pbrFile.find("\"custom\""), 8, "\"pbr\"");
    p.write("materials/toon.material.json", pbrFile);
    r = errors_of(pbr, surface + loop);
    REQUIRE(r.ok());
    REQUIRE_FALSE(r->errors.empty());
    CHECK(r->errors[0].message.find("does not have \"lighting\": \"custom\"") != std::string::npos);
    CHECK(r->errors[0].hint.find("/lighting") != std::string::npos);
    CHECK(shdc.calls == 0);
    // the error points at the hook, not at an overload of the same name that comes first
    r = errors_of(pbr, surface + "vec3 lighting(vec3 a) { return a; }\n" + loop);
    REQUIRE(r.ok());
    REQUIRE_FALSE(r->errors.empty());
    CHECK(r->errors[0].message.find("does not have \"lighting\": \"custom\"") != std::string::npos);
    CHECK(r->errors[0].line == 3);
    // ... and so does a pbr material that calls one of the lighting functions from its own helper
    r = errors_of(pbr, surface + "vec3 sky(in SurfaceInput i, in Surface s) { return fa_sky_light(i, s); }\n");
    REQUIRE(r.ok());
    REQUIRE(r->errors.size() == 1);
    CHECK(r->errors[0].message.find("'fa_sky_light' : the lighting functions belong to a material with") !=
          std::string::npos);
    CHECK(r->errors[0].hint.find("/lighting") != std::string::npos);
    p.write("materials/toon.material.json", kToonMaterial);

    // surface() runs before the lights are known: calling the functions there is refused, light() may call them
    r = errors_of(custom,
                  "void surface(in SurfaceInput i, inout Surface s) {\n    s.emission = fa_sky_light(i, s);\n}\n"
                  "vec3 light(in SurfaceInput i, in Surface s, in LightSample l) { return fa_sky_light(i, s); }\n");
    REQUIRE(r.ok());
    REQUIRE(r->errors.size() == 1);
    CHECK(r->errors[0].message.find("'fa_sky_light' : the lighting functions cannot be called from surface()") !=
          std::string::npos);
    CHECK(r->errors[0].line == 2);
    CHECK(r->errors[0].hint.find("light(), ambient() or lighting()") != std::string::npos);
    // ... except the four that only read the sky environment (an alphaMode "clip" surface() runs in the shadow and depth programs too)
    r = errors_of(custom, "void surface(in SurfaceInput i, inout Surface s) {\n"
                          "    s.emission = fa_environment(i.world_normal, 0.5) * fa_ambient_light(i.world_normal);\n"
                          "    s.emission += fa_sky_reflection(s.normal, i.view_dir, vec3(0.04), 0.5);\n"
                          "    s.alpha = fa_env_brdf(0.5, 0.5).x;\n}\n"
                          "vec3 light(in SurfaceInput i, in Surface s, in LightSample l) { return vec3(0.0); }\n");
    CHECK(shdc.calls == 1);  // the checks before sokol-shdc refused nothing (the fake one writes no reflection file)

    // a misspelled function: did you mean, with the list of the functions
    const std::string misspelled = surface + "vec3 lighting(in SurfaceInput i, in Surface s) {\n"
                                             "    return fa_sky_ligth(i, s);\n}\n";
    const GeneratedShader gm = generate_material_shader(custom, misspelled);
    p.write(custom.shader, misspelled);
    shdc.stderrText = "top.glsl:" + std::to_string(top_line_of(gm, 3)) +
                      ":0: error: 'fa_sky_ligth' : no matching overloaded "
                      "function found\n";
    r = compile_material(p.str(), "materials/toon.material.json", options);
    REQUIRE(r.ok());
    REQUIRE(r->errors.size() == 1);
    CHECK(r->errors[0].hint.find("did you mean fa_sky_light?") != std::string::npos);
    CHECK(r->errors[0].hint.find("fa_light_unshadowed") != std::string::npos);
    // a name that exists but fails to compile in the vertex stage (a helper compiled into both stages): the stage hint, with the signature
    const std::string helperUse =
        surface + "vec3 sky_helper(in SurfaceInput i, in Surface s) { return fa_sky_light(i, s); }\n"
                  "vec3 light(in SurfaceInput i, in Surface s, in LightSample l) { return sky_helper(i, s); }\n";
    const GeneratedShader gh = generate_material_shader(custom, helperUse);
    p.write(custom.shader, helperUse);
    shdc.stderrText = "top.glsl:" + std::to_string(top_line_of(gh, 2)) +
                      ":0: error: 'fa_sky_light' : no matching overloaded function found\n";
    r = compile_material(p.str(), "materials/toon.material.json", options);
    REQUIRE(r.ok());
    REQUIRE(r->errors.size() == 1);
    CHECK(r->errors[0].hint.find("did you mean fa_sky_light") == std::string::npos);
    CHECK(r->errors[0].hint.find("GL_FRAGMENT_SHADER") != std::string::npos);
    CHECK(r->errors[0].hint.find("vec3 fa_sky_light(in SurfaceInput i, in Surface s)") != std::string::npos);
    // the same message from a call inside light() (a fragment-stage entry point): the arguments are wrong, not the stage
    const std::string wrongArgs =
        surface + "vec3 light(in SurfaceInput i, in Surface s, in LightSample l) { return fa_sky_light(i); }\n";
    const GeneratedShader gw = generate_material_shader(custom, wrongArgs);
    p.write(custom.shader, wrongArgs);
    shdc.stderrText = "top.glsl:" + std::to_string(top_line_of(gw, 2)) +
                      ":0: error: 'fa_sky_light' : no matching overloaded function found\n";
    r = compile_material(p.str(), "materials/toon.material.json", options);
    REQUIRE(r.ok());
    REQUIRE(r->errors.size() == 1);
    CHECK(r->errors[0].hint.find("does not match its signature") != std::string::npos);
    CHECK(r->errors[0].hint.find("vec3 fa_sky_light(in SurfaceInput i, in Surface s)") != std::string::npos);
    CHECK(r->errors[0].hint.find("GL_FRAGMENT_SHADER") == std::string::npos);
    shdc.stderrText.clear();

    // the name `lighting` is reserved for the hook only in a custom material, like light and ambient
    CHECK(has_error(parse(R"({"format":"factoria.material/1","shader":"s.glsl","lighting":"custom","params":{
        "lighting":{"type":"float","default":1,"doc":"d"}}})"),
                    "/params/lighting", "name of the snippet contract"));
    CHECK(parse(R"({"format":"factoria.material/1","shader":"s.glsl","params":{
        "lighting":{"type":"float","default":1,"doc":"d"}}})")
              .ok());
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

// ---------------------------------------------------------------------------------------------------------------
// Per-instance params and declared vertex channels
// ---------------------------------------------------------------------------------------------------------------

namespace {
const char* kInstParams = R"("params":{
    "a":{"type":"color","default":[1,1,1,1],"instanced":true,"doc":"A color per entity."},
    "b":{"type":"color","default":[1,1,1,1],"instanced":true,"doc":"Another color per entity."},
    "c":{"type":"vec3","default":[0,0,0],"instanced":true,"doc":"A lift per entity."},
    "d":{"type":"float","default":0,"instanced":true,"doc":"Its strength per entity."},
    "k":{"type":"float","default":1,"min":0,"max":4,"doc":"One value per draw."}}})";
const std::string kInstMaterial =
    std::string(
        R"({"format":"factoria.material/1","shader":"shaders/inst.surface.glsl","vertexAttributes":["uv1","color1"],)") +
    kInstParams;
const std::string kInstMaterialNoChannels =
    std::string(R"({"format":"factoria.material/1","shader":"shaders/inst.surface.glsl",)") + kInstParams;
const char* kInstSnippet = R"(void vertex(inout VertexData v) {
    v.world_pos += c * d;
    v.uv = vertex_uv1;
    v.color = vertex_color1;
}
void surface(in SurfaceInput i, inout Surface s) {
    s.emission += a.rgb * b.rgb * k + c * d;
}
)";
}  // namespace

TEST_CASE("instanced params: the layout packs floats and small vectors first-fit, alphabetically, in at most 3 vec4") {
    Project p;
    p.write("materials/inst.material.json", kInstMaterial);
    p.write("shaders/inst.surface.glsl", kInstSnippet);
    const MaterialParse m = read_material(p.str(), "materials/inst.material.json");
    REQUIRE(m.ok());
    CHECK(m.material.vertexAttributes == std::vector<std::string>{"color1", "uv1"});
    const InstanceLayout layout = instance_layout(m.material.params);
    CHECK(layout.vec4Count == 3);
    REQUIRE(layout.slots.size() == 4);  // k is not instanced
    CHECK(layout.slots[0].name == "a");
    CHECK(layout.slots[0].vec4 == 0);
    CHECK(layout.slots[1].vec4 == 1);
    CHECK(layout.slots[2].name == "c");
    CHECK(layout.slots[2].vec4 == 2);
    CHECK(layout.slots[2].offset == 0);
    CHECK(layout.slots[2].components == 3);
    CHECK(layout.slots[3].name == "d");
    CHECK(layout.slots[3].vec4 == 2);
    CHECK(layout.slots[3].offset == 3);
    CHECK(kMaterialMaxInstanceVec4 == 3);

    auto schema = bundled_read("schemas/material.schema.json");
    REQUIRE(schema.has_value());
    CHECK(validate_json(Json::parse(*schema), Json::parse(kInstMaterial)).empty());

    // 12 instanced floats fill exactly three vec4; the 13th does not fit
    auto floats = [](int n) {
        std::string s = R"({"format":"factoria.material/1","shader":"s.glsl","params":{)";
        for (int i = 0; i < n; ++i)
            s += std::string(i ? "," : "") + "\"f" + std::string(i < 10 ? "0" : "") + std::to_string(i) +
                 R"(":{"type":"float","default":0,"instanced":true,"doc":"d"})";
        return s + "}}";
    };
    const MaterialParse twelve = parse(floats(12).c_str());
    CHECK(twelve.ok());
    CHECK(instance_layout(twelve.material.params).vec4Count == 3);
    CHECK(has_error(parse(floats(13).c_str()), "/params", "at most 3"));
}

TEST_CASE("instanced params: errors name the pointer, and the 16-param limit counts only the params of the block") {
    CHECK(has_error(parse(R"({"format":"factoria.material/1","shader":"s.glsl","params":{
        "tint":{"type":"color","default":[1,1,1,1],"instanced":"yes","doc":"d"}}})"),
                    "/params/tint/instanced", "true or false"));
    // four vec4 per instance are too many, and the message names the params
    const auto four = parse(R"({"format":"factoria.material/1","shader":"s.glsl","params":{
        "a":{"type":"color","default":[1,1,1,1],"instanced":true,"doc":"d"},
        "b":{"type":"color","default":[1,1,1,1],"instanced":true,"doc":"d"},
        "c":{"type":"color","default":[1,1,1,1],"instanced":true,"doc":"d"},
        "d":{"type":"color","default":[1,1,1,1],"instanced":true,"doc":"d"}}})");
    CHECK(has_error(four, "/params", "4 vec4"));
    CHECK(has_error(four, "/params", "Make some of them not instanced"));
    // a vec3 and a float share one vec4
    CHECK(parse(R"({"format":"factoria.material/1","shader":"s.glsl","params":{
        "a":{"type":"vec3","default":[0,0,0],"instanced":true,"doc":"d"},
        "b":{"type":"float","default":0,"instanced":true,"doc":"d"}}})")
              .ok());
    // 17 params are too many for the block, unless some are instanced
    auto many = [](int instanced) {
        std::string s = R"({"format":"factoria.material/1","shader":"s.glsl","params":{)";
        for (int i = 0; i < 17; ++i)
            s += std::string(i ? "," : "") + "\"p" + std::string(i < 10 ? "0" : "") + std::to_string(i) +
                 R"(":{"type":"float","default":1,"doc":"d")" + (i < instanced ? R"(,"instanced":true)" : "") + "}";
        return s + "}}";
    };
    CHECK_FALSE(parse(many(0).c_str()).ok());
    CHECK(parse(many(3).c_str()).ok());
}

TEST_CASE("vertexAttributes: the names are checked with their pointer, did you mean and the list of channels") {
    CHECK(parse(R"({"format":"factoria.material/1","shader":"s.glsl","vertexAttributes":["uv1","color1"]})").ok());
    auto bad = parse(R"({"format":"factoria.material/1","shader":"s.glsl","vertexAttributes":["uv2","uv1","uv1",3]})");
    CHECK(has_error(bad, "/vertexAttributes/0", "Did you mean 'uv1'?"));
    CHECK(has_error(bad, "/vertexAttributes/0", "TEXCOORD_1"));
    CHECK(has_error(bad, "/vertexAttributes/2", "twice"));
    CHECK(has_error(bad, "/vertexAttributes/3", "expected a name"));
    CHECK(has_error(parse(R"({"format":"factoria.material/1","shader":"s.glsl","vertexAttributes":"uv1"})"),
                    "/vertexAttributes", "expected an array"));
}

TEST_CASE("instanced params: a sprite material takes them with the mesh limits, and the error names the pointer") {
    const std::string head = R"({"format":"factoria.material/1","shader":"s.glsl","kind":"sprite")";
    const auto ok = parse(
        (head + R"(,"params":{"tint":{"type":"color","default":[1,1,1,1],"instanced":true,"doc":"d"}}})").c_str());
    CHECK(ok.ok());
    const InstanceLayout layout = instance_layout(ok.material.params);
    CHECK(layout.vec4Count == 1);
    // four vec4 per sprite are too many, as for a mesh
    const auto four = parse((head + R"(,"params":{
        "a":{"type":"color","default":[1,1,1,1],"instanced":true,"doc":"d"},
        "b":{"type":"color","default":[1,1,1,1],"instanced":true,"doc":"d"},
        "c":{"type":"color","default":[1,1,1,1],"instanced":true,"doc":"d"},
        "d":{"type":"color","default":[1,1,1,1],"instanced":true,"doc":"d"}}})")
                                .c_str());
    CHECK_FALSE(four.ok());
    CHECK(has_error(four, "/params", "4 vec4"));
    CHECK(has_error(four, "/params", "Make some of them not instanced"));
    // vertexAttributes are the mesh's: a sprite has no channels to read
    const auto chan = parse((head + R"(,"vertexAttributes":["uv1"]})").c_str());
    CHECK(has_error(chan, "/vertexAttributes", "only mesh materials"));
    // the generator gives the sprite programs the per-quad stream, and a material without instanced params none of it
    Project p;
    p.add_sprite();
    const std::string src = std::string(kSpriteSnippet);
    const GeneratedShader plain =
        generate_material_shader(read_material(p.str(), "materials/dissolve2d.material.json").material, src);
    for (const std::string& d : plain.defines) CHECK(d.rfind("FA_INST_", 0) != 0);
    CHECK(plain.top.find("fa_instance_unpack") == std::string::npos);
    const GeneratedShader inst = generate_material_shader(
        ok.material, "void fragment(in QuadInput i, inout QuadSurface s) { s.color.rgb = tint.rgb; }\n");
    CHECK(std::find(inst.defines.begin(), inst.defines.end(), "FA_INST_1") != inst.defines.end());
    CHECK(inst.top.find("fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)") != std::string::npos);
    CHECK(inst.top.find("tint = fa_d0;") != std::string::npos);
    // material.info reports the layout for a sprite as for a mesh
    p.write("materials/quads.material.json",
            R"({"format":"factoria.material/1","kind":"sprite","shader":"shaders/quads.fragment.glsl","params":{
        "tint":{"type":"color","default":[1,1,1,1],"instanced":true,"doc":"d"},
        "wave":{"type":"float","default":0,"instanced":true,"doc":"d"}}})");
    p.write("shaders/quads.fragment.glsl",
            "void fragment(in QuadInput i, inout QuadSurface s) { s.color.rgb *= tint.rgb * wave; }\n");
    FakeShdc shdc;
    CommandRegistry registry;
    register_shader_commands(registry, p.str(), shdc.context(p.str()));
    auto info = registry.call("material.info", Json::parse(R"({"material":"materials/quads.material.json"})"));
    REQUIRE(info.ok);
    CHECK(info.result["kind"] == "sprite");
    REQUIRE(info.result.contains("instanceLayout"));
    CHECK(info.result["instanceLayout"]["vec4"] == 2);
    CHECK(info.result["instanceLayout"]["slots"].size() == 2);
}

TEST_CASE(
    "instanced params and vertexAttributes are refused in every kind but mesh and sprite, with the pointer and the "
    "fix") {
    for (const char* kind : {"compute", "sky"}) {
        CAPTURE(kind);
        const std::string head =
            std::string(R"({"format":"factoria.material/1","shader":"s.glsl","kind":")") + kind + "\"";
        const auto inst = parse(
            (head + R"(,"params":{"tint":{"type":"color","default":[1,1,1,1],"instanced":true,"doc":"d"}}})").c_str());
        CHECK_FALSE(inst.ok());
        CHECK(has_error(inst, "/params/tint/instanced", "only mesh and sprite materials"));
        CHECK(has_error(inst, "/params/tint/instanced", "Remove \"instanced\""));
        const auto chan = parse((head + R"(,"vertexAttributes":["uv1"]})").c_str());
        CHECK_FALSE(chan.ok());
        CHECK(has_error(chan, "/vertexAttributes", "only mesh materials"));
        CHECK(has_error(chan, "/vertexAttributes", "Remove \"vertexAttributes\""));
        // "instanced": false is what every kind may write
        CHECK_FALSE(has_error(
            parse((head + R"(,"params":{"tint":{"type":"color","default":[1,1,1,1],"instanced":false,"doc":"d"}}})")
                      .c_str()),
            "/params/tint/instanced", "only mesh"));
    }
}

TEST_CASE("the instance limit of the renderer is the one of the tooling") {
    // render_internal.h is private to fa_render: read the constant the way the generator and the runtime must agree on it.
    const std::string header = testing::read_all(stdfs::path(FA_REPO_ROOT) / "engine/render/src/render_internal.h");
    std::smatch m;
    REQUIRE(std::regex_search(header, m, std::regex(R"(constexpr int kMaxInstanceVec4 = (\d+);)")));
    CHECK(std::stoi(m[1].str()) == kMaterialMaxInstanceVec4);
}

TEST_CASE("cache: a twin made before a param was toggled \"instanced\" is not the one of the toggled material") {
    // the twin lists the params of the block and the instance layout, and the cache key covers the generated top file and defines:
    // toggling `instanced` without compiling again must not find the old twin (material.info says not_compiled, validate recompiles)
    Project p;
    const std::string snippet = "void surface(in SurfaceInput i, inout Surface s) { s.emission += vec3(k); }\n";
    p.write("shaders/s.surface.glsl", snippet);
    auto key_with = [&](const char* instanced) {
        p.write("materials/m.material.json",
                std::string(R"({"format":"factoria.material/1","shader":"shaders/s.surface.glsl","params":{
                    "k":{"type":"float","default":1,"doc":"d")") +
                    instanced + "}}}");
        const MaterialParse mp = read_material(p.str(), "materials/m.material.json");
        REQUIRE(mp.ok());
        return shader_cache_path(p.str(), generate_material_shader(mp.material, snippet), snippet, "hlsl5");
    };
    const std::string plain = key_with("");
    const std::string instanced = key_with(R"(,"instanced":true)");
    CHECK(plain != instanced);
    CHECK(plain == key_with(R"(,"instanced":false)"));
}

TEST_CASE("generator: instanced params are left out of the block, read from the instance data, and the channels are "
          "globals of vertex()") {
    Project p;
    p.write("materials/inst.material.json", kInstMaterial);
    p.write("shaders/inst.surface.glsl", kInstSnippet);
    const MaterialDef inst = read_material(p.str(), "materials/inst.material.json").material;
    const GeneratedShader g = generate_material_shader(inst, kInstSnippet);
    CHECK(g.hasVertex);
    CHECK(std::find(g.defines.begin(), g.defines.end(), "FA_INST_3") != g.defines.end());
    CHECK(std::find(g.defines.begin(), g.defines.end(), "FA_CH_UV1") != g.defines.end());
    CHECK(std::find(g.defines.begin(), g.defines.end(), "FA_CH_COLOR1") != g.defines.end());
    CHECK(g.top.find("float k;") != std::string::npos);  // the one param of the block
    CHECK(g.top.find("fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)") != std::string::npos);
    CHECK(g.top.find("c = fa_d2.xyz;") != std::string::npos);
    CHECK(g.top.find("d = fa_d2.w;") != std::string::npos);
    CHECK(g.top.find("vec2 vertex_uv1;") != std::string::npos);
    CHECK(g.top.find("vec4 vertex_color1;") != std::string::npos);
    // a material with neither gets none of it
    const GeneratedShader plain =
        generate_material_shader(read_material(p.str(), "materials/gem.material.json").material, kGemSnippet);
    CHECK(plain.top.find("fa_instance_unpack") == std::string::npos);
    CHECK(plain.top.find("vertex_uv1") == std::string::npos);
    for (const std::string& d : plain.defines) CHECK(d.rfind("FA_INST_", 0) != 0);
}

TEST_CASE(
    "real sokol-shdc: a material with three vec4 of instanced params and both channels compiles to every dialect") {
    SetupContext context;
    if (!real_tool(context)) return;
    Project p;
    p.write("materials/inst.material.json", kInstMaterial);
    p.write("shaders/inst.surface.glsl", kInstSnippet);
    ShaderCompileOptions options;
    options.setup = context;
    options.useCache = false;
    auto r = compile_material(p.str(), "materials/inst.material.json", options);
    REQUIRE(r.ok());
    const std::string why = r->errors.empty() ? std::string() : r->errors[0].to_string();
    INFO(why);
    REQUIRE(r->ok);
    REQUIRE(r->twins.size() == 6);
    for (const auto& [slang, twin] : r->twins) {
        CAPTURE(slang);
        CHECK(twin["params"] == Json::parse(R"(["k"])"));
        CHECK(twin["instanceVec4"] == 3);
        CHECK(twin["vertexAttributes"] == Json::parse(R"(["color1","uv1"])"));
        REQUIRE(twin["instanced"].size() == 4);
        CHECK(twin["instanced"][2] == Json::parse(R"({"name":"c","vec4":2,"offset":0,"components":3})"));
        CHECK(twin["programs"].size() == 6);
        // the nine attributes of the mesh, three instance vec4, uv1 and color1; the skinned program adds joints and weights
        CHECK(twin["programs"]["mesh"]["reflection"]["attrs"].size() == 14);
        CHECK(twin["programs"]["mesh_skin"]["reflection"]["attrs"].size() == 16);
        CHECK(twin["programs"]["shadow"]["reflection"]["attrs"].size() == 14);
        CHECK(twin["programs"]["prepass"]["reflection"]["attrs"].size() == 14);
    }
    // a surface()-only material without channels: the instance data only, the shadow programs do not exist
    p.write("shaders/inst.surface.glsl",
            "void surface(in SurfaceInput i, inout Surface s) {\n    s.emission += a.rgb * b.rgb * k + c * d;\n}\n");
    p.write("materials/inst.material.json", kInstMaterialNoChannels);
    auto s = compile_material(p.str(), "materials/inst.material.json", options);
    REQUIRE(s.ok());
    REQUIRE(s->ok);
    for (const auto& [slang, twin] : s->twins) {
        CAPTURE(slang);
        CHECK_FALSE(twin.contains("vertexAttributes"));
        CHECK(twin["programs"].size() == 4);
        CHECK(twin["programs"]["mesh"]["reflection"]["attrs"].size() == 12);
    }
}

// ---------------------------------------------------------------------------------------------------------------
// Full shaders (mode "full"): the file holds the vertex and the fragment stage
// ---------------------------------------------------------------------------------------------------------------

namespace {

const char* kFullMaterial = R"({
  "format": "factoria.material/1",
  "mode": "full",
  "shader": "shaders/ring.full.glsl",
  "shadow": "custom",
  "passes": [
    {"name": "body", "cull": "back"},
    {"name": "outline", "cull": "front", "depthWrite": true}
  ],
  "params": {
    "width": { "type": "float", "default": 0.05, "min": 0.0, "max": 1.0, "doc": "Outline width." },
    "ink": { "type": "color", "default": [0, 0, 0, 1], "doc": "Outline colour." }
  }
})";

// Line 1 is `@common`, the vertex main() is on line 5, gl_Position on line 11, `@fragment` on line 14, the outline colour on line 17.
const char* kFullShader = R"(@common
varying vec3 v_normal;

@vertex
void main() {
    vec3 p = fa_position;
#ifdef FA_PASS_OUTLINE
    p += fa_normal * width;
#endif
    v_normal = fa_normal;
    gl_Position = fa_view_proj * vec4(fa_world_position(p), 1.0);
}

@fragment
void main() {
#ifdef FA_PASS_OUTLINE
    fa_frag_color = vec4(ink.rgb, 1.0);
#else
    fa_frag_color = vec4(v_normal * 0.5 + 0.5, 1.0);
#endif
}
)";

// A project with the full material above; `shader` replaces the shader file.
struct FullProject : Project {
    explicit FullProject(const std::string& shader = kFullShader, const char* material = kFullMaterial) {
        write("materials/ring.material.json", material);
        write("shaders/ring.full.glsl", shader);
    }
    MaterialParse read() { return read_material(str(), "materials/ring.material.json"); }
};

std::string replace_in(std::string text, const std::string& from, const std::string& to) {
    const std::size_t at = text.find(from);
    REQUIRE(at != std::string::npos);
    return text.replace(at, from.size(), to);
}

}  // namespace

TEST_CASE("full material: the file is read with its passes in order, and the schema accepts it") {
    FullProject p;
    const MaterialParse mp = p.read();
    for (const MaterialIssue& e : mp.errors) INFO(e.pointer << ": " << e.message);
    REQUIRE(mp.ok());
    const MaterialDef& m = mp.material;
    CHECK(m.full);
    CHECK(m.kind == "mesh");
    CHECK(m.shadow == "custom");
    CHECK(m.prepass);
    REQUIRE(m.passes.size() == 2);
    CHECK(m.passes[0].name == "body");
    CHECK(m.passes[0].cull == "back");
    CHECK(m.passes[0].depthWrite);  // an opaque pass writes depth unless the file says otherwise
    CHECK(m.passes[1].cull == "front");
    // no "passes": one pass called main; "blend" turns the depth write off
    const auto one = parse(R"({"format":"factoria.material/1","mode":"full","shader":"s.glsl"})");
    REQUIRE(one.material.passes.size() == 1);
    CHECK(one.material.passes[0].name == "main");
    const auto glass = parse(
        R"({"format":"factoria.material/1","mode":"full","shader":"s.glsl","passes":[{"name":"glass","blend":"alpha"}]})");
    REQUIRE(glass.material.passes.size() == 1);
    CHECK_FALSE(glass.material.passes[0].depthWrite);
    // the schema accepts the file and refuses a typo
    auto schema = bundled_read("schemas/material.schema.json");
    REQUIRE(schema.has_value());
    CHECK(validate_json(Json::parse(*schema), Json::parse(kFullMaterial)).empty());
    Json bad = Json::parse(kFullMaterial);
    bad["mode"] = "fulll";
    CHECK_FALSE(validate_json(Json::parse(*schema), bad).empty());
}

TEST_CASE("full material: errors name the JSON pointer, the problem and the fix") {
    const std::string head = R"({"format":"factoria.material/1","shader":"s.glsl",)";
    auto full = [&](const std::string& rest) { return parse((head + R"("mode":"full",)" + rest + "}").c_str()); };

    const auto mode = parse((head + R"("mode":"fulll"})").c_str());
    CHECK(has_error(mode, "/mode", "Did you mean 'full'?"));

    // passes, shadow and prepass are for full materials only
    for (const char* key : {"passes", "shadow", "prepass"}) {
        CAPTURE(key);
        const std::string value = std::string(key) == "passes"   ? R"([{"name":"a"}])"
                                  : std::string(key) == "shadow" ? R"("none")"
                                                                 : "false";
        const auto snip = parse((head + "\"" + key + "\":" + value + "}").c_str());
        CHECK(has_error(snip, std::string("/") + key, "belongs to a full-shader material"));
        CHECK(has_error(snip, std::string("/") + key, "\"mode\": \"full\""));
    }
    // keys that describe the engine's shader do nothing in a full material
    CHECK(has_error(full(R"("lighting":"unlit")"), "/lighting", "has no effect"));
    CHECK(has_error(full(R"("alphaMode":"blend")"), "/alphaMode", "set \"blend\""));
    CHECK(has_error(full(R"("doubleSided":true)"), "/doubleSided", "\"cull\": \"none\""));
    // other kinds have no full mode
    const auto sprite = parse((head + R"("kind":"sprite","mode":"full"})").c_str());
    CHECK(has_error(sprite, "/mode", "is for mesh materials"));

    CHECK(has_error(full(R"("shadow":"deph")"), "/shadow", "Did you mean 'depth'?"));
    CHECK(has_error(full(R"("prepass":"no")"), "/prepass", "expected true or false"));
    CHECK(has_error(full(R"("passes":[])"), "/passes", "non-empty array"));
    CHECK(has_error(full(R"("passes":{"a":1})"), "/passes", "non-empty array"));
    CHECK(has_error(full(R"("passes":[3])"), "/passes/0", "expected an object"));
    CHECK(has_error(full(R"("passes":[{"cull":"back"}])"), "/passes/0/name", "missing \"name\""));
    CHECK(has_error(full(R"("passes":[{"name":"1a"}])"), "/passes/0/name", "must be an identifier"));
    CHECK(has_error(full(R"("passes":[{"name":"float"}])"), "/passes/0/name", "must be an identifier"));
    CHECK(has_error(full(R"("passes":[{"name":"a"},{"name":"A"}])"), "/passes/1/name", "used twice"));
    CHECK(has_error(full(R"("passes":[{"name":"a","cul":"back"}])"), "/passes/0/cul", "Did you mean 'cull'?"));
    CHECK(has_error(full(R"("passes":[{"name":"a","cull":"bak"}])"), "/passes/0/cull", "Did you mean 'back'?"));
    CHECK(has_error(full(R"("passes":[{"name":"a","blend":"alfa"}])"), "/passes/0/blend", "alpha"));
    CHECK(has_error(full(R"("passes":[{"name":"a","depthTest":1}])"), "/passes/0/depthTest", "expected true or false"));
    CHECK(has_error(full(R"("passes":[{"name":"a","depthWrite":"yes"}])"), "/passes/0/depthWrite",
                    "expected true or false"));
    const auto five = full(R"("passes":[{"name":"a"},{"name":"b"},{"name":"c"},{"name":"d"},{"name":"e"}])");
    CHECK(has_error(five, "/passes", "5 passes, at most 4"));
    CHECK(full(R"("passes":[{"name":"a"},{"name":"b"},{"name":"c"},{"name":"d"}])").ok());
}

TEST_CASE("full material: the file is checked without a compiler, each problem at its line") {
    FakeShdc shdc;
    shdc.reflection = fixture("shdc_mesh_hlsl5_glsl430.yaml");
    ShaderCompileOptions options;
    options.dialects = {"hlsl5"};
    auto errors_of = [&](const std::string& shader) {
        FullProject p(shader);
        options.setup = shdc.context(p.str());
        auto r = compile_material(p.str(), "materials/ring.material.json", options);
        REQUIRE(r.ok());
        return r->errors;
    };
    auto has = [](const std::vector<ShaderIssue>& v, int line, const std::string& text) {
        return std::any_of(v.begin(), v.end(), [&](const ShaderIssue& i) {
            return i.line == line &&
                   (i.message.find(text) != std::string::npos || i.hint.find(text) != std::string::npos);
        });
    };

    // no main() in a stage: reported at the line of its section
    const auto noMain = errors_of(replace_in(kFullShader, "void main() {\n#ifdef FA_PASS_OUTLINE\n    fa_frag_color",
                                             "void mian() {\n#ifdef FA_PASS_OUTLINE\n    fa_frag_color"));
    CHECK(has(noMain, 14, "defines no `void main()`"));
    // a missing section has no line
    CHECK(has(errors_of("@fragment\nvoid main() { fa_frag_color = vec4(1.0); }\n"), 0, "no `@vertex` section"));
    CHECK(has(errors_of("@vertex\nvoid main() { gl_Position = vec4(0.0); }\n"), 0, "no `@fragment` section"));
    // code before the first section; an unknown section; two of one
    CHECK(has(errors_of("float x = 1.0;\n" + std::string(kFullShader)), 1, "code before the first section"));
    CHECK(has(errors_of(replace_in(kFullShader, "@common", "@comon")), 1, "Did you mean `@common`?"));
    CHECK(has(errors_of(std::string(kFullShader) + "@fragment\nvoid main() {}\n"), 22, "appears twice"));
    // main() in @common would be defined twice
    CHECK(has(errors_of(replace_in(kFullShader, "@common\n", "@common\nvoid main() {}\n")), 1, "defines `main()`"));
    // the stages never write their output
    CHECK(has(errors_of(replace_in(kFullShader, "gl_Position", "gl_Positon")), 4, "never writes gl_Position"));
    CHECK(has(errors_of(replace_in(replace_in(kFullShader, "fa_frag_color = vec4(ink", "x = vec4(ink"),
                                   "fa_frag_color = vec4(v_normal", "x = vec4(v_normal")),
              14, "never writes fa_frag_color"));

    // varyings: the same list in both stages, in the same order
    const std::string vertexOnly = replace_in(kFullShader, "@common\nvarying vec3 v_normal;\n\n@vertex",
                                              "@common\n\n@vertex\nvarying vec3 v_normal;");
    CHECK(has(errors_of(vertexOnly), 4,
              "the vertex stage declares `varying vec3 v_normal`, which the fragment stage does not"));
    const auto otherType = errors_of(replace_in(vertexOnly, "@fragment\n", "@fragment\nvarying vec4 v_normal;\n"));
    bool mismatch = false;
    for (const ShaderIssue& i : otherType) mismatch = mismatch || i.message.find("as varying 1") != std::string::npos;
    CHECK(mismatch);
    CHECK(has(errors_of(replace_in(
                  kFullShader, "varying vec3 v_normal;",
                  "varying vec3 v_normal;\nvarying mat4 a;\nvarying mat4 b;\nvarying mat4 c;\nvarying mat4 d;")),
              6, "varying vec4 slots"));

    // fa_ names: the ones the template documents are free, the others are the engine's
    const auto reserved = errors_of(replace_in(kFullShader, "vec3 p = fa_position;", "vec3 p = fa_positon;"));
    REQUIRE(reserved.size() == 1);
    CHECK(reserved[0].line == 6);
    CHECK(reserved[0].column == 14);
    CHECK(reserved[0].message.find("`fa_positon` is not a name a full shader may use") != std::string::npos);
    CHECK(reserved[0].hint.find("did you mean `fa_position`?") != std::string::npos);
    CHECK(has(errors_of(replace_in(kFullShader, "vec3 p = fa_position;", "float fa_mine = 1.0; vec3 p = fa_position;")),
              6, "fa_mine"));
    // FA_PASS_<NAME> of a pass the material declares is a define; of a pass it does not, a typo
    for (const ShaderIssue& i :
         errors_of(replace_in(kFullShader, "#ifdef FA_PASS_OUTLINE\n    p +=", "#ifdef FA_PASS_BODY\n    p +=")))
        CHECK(i.message.find("FA_PASS_") == std::string::npos);
    CHECK(has(errors_of(replace_in(kFullShader, "#ifdef FA_PASS_OUTLINE\n    p +=", "#ifdef FA_PASS_OUTLNE\n    p +=")),
              7, "FA_PASS_OUTLNE"));
}

TEST_CASE("full material: the generated top file has one vertex and fragment program per pass, and the twin fields say "
          "how to draw them") {
    FullProject p;
    const MaterialDef m = p.read().material;
    const GeneratedShader g = generate_material_shader(m, kFullShader);
    CHECK(g.kind == "mesh-full");
    CHECK(g.programs == std::vector<std::string>{"mesh", "mesh_skin", "pass1", "pass1_skin", "shadow", "shadow_skin",
                                                 "prepass", "prepass_skin"});
    CHECK(g.top.find("@include mesh_full_common.glsl") != std::string::npos);
    CHECK(g.top.find("#define FA_PASS 1\n#define FA_PASS_OUTLINE 1\n") != std::string::npos);
    CHECK(g.top.find("#define FA_SKIN\n") != std::string::npos);
    CHECK(g.top.find("#define FA_SHADOW_PASS\n") != std::string::npos);
    CHECK(g.top.find("@program pass1_skin fvs_pass1_skin ffs_pass1") != std::string::npos);
    CHECK(g.top.find("float width;") != std::string::npos);  // the params block, as in a snippet material
    // the author's lines map back to the file: the vertex main() is line 5, the fragment main() line 15
    CHECK(top_line_of(g, 5) > 0);
    CHECK(top_line_of(g, 15) > top_line_of(g, 5));
    // the passes are part of the cache key even though the top file does not hold them
    MaterialDef other = m;
    other.passes[1].cull = "none";
    CHECK(generate_material_shader(other, kFullShader).stateKey != g.stateKey);
    // "prepass": false and "shadow": "depth" leave their programs out
    MaterialDef lean = m;
    lean.prepass = false;
    lean.shadow = "depth";
    CHECK(generate_material_shader(lean, kFullShader).programs ==
          std::vector<std::string>{"mesh", "mesh_skin", "pass1", "pass1_skin"});
    const Json fields = shaders_detail::full_twin_fields(m);
    CHECK(fields["full"] == true);
    CHECK(fields["shadow"] == "custom");
    REQUIRE(fields["passes"].size() == 2);
    CHECK(fields["passes"][1]["program"] == "pass1");
    CHECK(fields["passes"][1]["programSkin"] == "pass1_skin");
}

TEST_CASE("full material: material.info reports the mode, the passes and the programs of each") {
    FullProject p;
    FakeShdc shdc;
    shdc.reflection = fixture("shdc_mesh_hlsl5_glsl430.yaml");
    CommandRegistry registry;
    register_shader_commands(registry, p.str(), shdc.context(p.str()));
    auto info = registry.call("material.info", Json::parse(R"({"material":"materials/ring.material.json"})"));
    REQUIRE(info.ok);
    CHECK(info.result["mode"] == "full");
    CHECK(info.result["kind"] == "mesh");
    CHECK_FALSE(info.result.contains("lighting"));
    CHECK_FALSE(info.result.contains("alphaMode"));
    CHECK(info.result["shadow"] == "custom");
    CHECK(info.result["prepass"] == true);
    REQUIRE(info.result["passes"].size() == 2);
    CHECK(info.result["passes"][0]["name"] == "body");
    CHECK(info.result["passes"][1]["cull"] == "front");
    CHECK(info.result["passes"][1]["program"] == "pass1");
    CHECK(info.result["passes"][1]["programSkin"] == "pass1_skin");
    CHECK(info.result["programs"].size() == 8);
    CHECK(info.result["compile"]["state"] == "not_compiled");
    // a snippet material says its mode and has no passes
    info = registry.call("material.info", Json::parse(R"({"material":"materials/gem.material.json"})"));
    REQUIRE(info.ok);
    CHECK(info.result["mode"] == "snippet");
    CHECK_FALSE(info.result.contains("passes"));
    CHECK(info.result["lighting"] == "pbr");
    // an error of the file comes back with its pointer
    p.write("materials/ring.material.json", replace_in(kFullMaterial, "\"back\"", "\"bak\""));
    auto bad = registry.call("material.info", Json::parse(R"({"material":"materials/ring.material.json"})"));
    CHECK_FALSE(bad.ok);
    CHECK(bad.error["message"].get<std::string>().find("/passes/0/cull") != std::string::npos);
}

TEST_CASE("real sokol-shdc: a full material compiles to every dialect, one program per pass, and its twin says how to "
          "draw them") {
    SetupContext context;
    if (!real_tool(context)) return;
    FullProject p;
    ShaderCompileOptions options;
    options.setup = context;
    options.useCache = false;
    auto r = compile_material(p.str(), "materials/ring.material.json", options);
    REQUIRE(r.ok());
    const std::string why = r->errors.empty() ? std::string() : r->errors[0].to_string();
    INFO(why);
    REQUIRE(r->ok);
    REQUIRE(r->twins.size() == 6);
    for (const auto& [slang, twin] : r->twins) {
        CAPTURE(slang);
        CHECK_FALSE(twin.contains("kind"));  // a mesh twin, as every twin made before M72
        CHECK(twin["full"] == true);
        CHECK(twin["shadow"] == "custom");
        CHECK(twin["passes"].size() == 2);
        for (const char* name :
             {"mesh", "mesh_skin", "pass1", "pass1_skin", "shadow", "shadow_skin", "prepass", "prepass_skin"}) {
            CAPTURE(name);
            REQUIRE(twin["programs"].contains(name));
            CHECK_FALSE(twin["programs"][name]["vs"].get<std::string>().empty());
            CHECK_FALSE(twin["programs"][name]["fs"].get<std::string>().empty());
        }
        // the params block sits on the same slot as a snippet material's: the inspector and the renderer write it alike
        bool block = false;
        for (const Json& ub : twin["programs"]["pass1"]["reflection"]["uniform_blocks"])
            if (ub["struct_name"] == "fa_material") {
                block = true;
                CHECK(ub["slot"] == 5);
            }
        CHECK(block);
    }
}

TEST_CASE("real sokol-shdc: a full shader at the varying limit (12 slots) with instanced params compiles for GLES3") {
    SetupContext context;
    if (!real_tool(context)) return;
    // 12 vec4 varyings plus the three flat instance varyings (three vec4 of instanced params) are the 15 that OpenGL ES 3 guarantees
    std::string varyings, writes, sum = "vec4(0.0)";
    for (int n = 0; n < 12; ++n) {
        varyings += "varying vec4 v" + std::to_string(n) + ";\n";
        writes += "    v" + std::to_string(n) + " = vec4(fa_normal, " + std::to_string(n) + ".0);\n";
        sum += " + v" + std::to_string(n);
    }
    const std::string shader = "@common\n" + varyings + "\n@vertex\nvoid main() {\n" + writes +
                               "    gl_Position = fa_view_proj * vec4(fa_world_position(fa_position), 1.0);\n}\n\n"
                               "@fragment\nvoid main() {\n    vec4 sum = " +
                               sum + ";\n    fa_frag_color = vec4(sum.rgb / 12.0 * (a.rgb * b.rgb + c * d), 1.0);\n}\n";
    FullProject p(shader, R"({
      "format": "factoria.material/1", "mode": "full", "shader": "shaders/ring.full.glsl",
      "params": {
        "a": {"type": "color", "default": [1, 1, 1, 1], "instanced": true, "doc": "A colour per entity."},
        "b": {"type": "color", "default": [1, 1, 1, 1], "instanced": true, "doc": "Another colour per entity."},
        "c": {"type": "vec3", "default": [0, 0, 0], "instanced": true, "doc": "A lift per entity."},
        "d": {"type": "float", "default": 0, "instanced": true, "doc": "Its strength per entity."}}
    })");
    ShaderCompileOptions options;
    options.setup = context;
    options.dialects = {"glsl300es", "glsl430"};
    options.useCache = false;
    auto r = compile_material(p.str(), "materials/ring.material.json", options);
    REQUIRE(r.ok());
    const std::string why = r->errors.empty() ? std::string() : r->errors[0].to_string();
    INFO(why);
    REQUIRE(r->ok);
    REQUIRE(r->twins.size() == 2);
    CHECK(r->twins.at("glsl300es")["instanceVec4"] == 3);
    CHECK_FALSE(r->twins.at("glsl300es")["programs"]["mesh"]["vs"].get<std::string>().empty());
    // one slot more is the engine's own refusal, before any compiler runs
    FullProject over(replace_in(shader, "varying vec4 v11;\n", "varying vec4 v11;\nvarying vec4 v12;\n"),
                     R"({"format": "factoria.material/1", "mode": "full", "shader": "shaders/ring.full.glsl"})");
    auto refused = compile_material(over.str(), "materials/ring.material.json", options);
    REQUIRE(refused.ok());
    REQUIRE_FALSE(refused->ok);
    CHECK(refused->errors[0].message.find("13 varying vec4 slots, at most 12") != std::string::npos);
}

TEST_CASE("real sokol-shdc: an error of a full shader is mapped to the line of the user's file, in each stage") {
    SetupContext context;
    if (!real_tool(context)) return;
    ShaderCompileOptions options;
    options.setup = context;
    options.dialects = {"hlsl5", "glsl430"};
    options.useCache = false;
    auto first_error = [&](const std::string& shader) {
        FullProject p(shader);
        auto r = compile_material(p.str(), "materials/ring.material.json", options);
        REQUIRE(r.ok());
        REQUIRE_FALSE(r->ok);
        REQUIRE_FALSE(r->errors.empty());
        return r->errors[0];
    };
    // line 11 is in the vertex stage, line 17 in the fragment stage
    ShaderIssue e =
        first_error(replace_in(kFullShader, "gl_Position = fa_view_proj", "gl_Position = fa_view_proj * wdth"));
    CHECK(e.file == "shaders/ring.full.glsl");
    CHECK(e.line == 11);
    CHECK(e.hint.find("did you mean width?") != std::string::npos);
    e = first_error(
        replace_in(kFullShader, "fa_frag_color = vec4(ink.rgb, 1.0);", "fa_frag_color = vec4(ik.rgb, 1.0);"));
    CHECK(e.file == "shaders/ring.full.glsl");
    CHECK(e.line == 17);
    CHECK(e.to_string().find("shaders/ring.full.glsl:17:") != std::string::npos);
}
