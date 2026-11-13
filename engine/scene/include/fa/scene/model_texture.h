// Texturing 3D models made from documents (docs/MODELING.md, "Texturing"): materials whose tiling textures are baked into the model's UV atlas by
// triplanar projection, low-poly vertex-colour palettes, baked ambient occlusion, curvature and thickness, wear (worn edges, dirt in cavities) built
// from those maps, and decals projected on parts or selections. Everything runs on the CPU in the engine, GPU-free, and is deterministic: the same
// document and the same project images give the same pixels (no rand(), no clock; the sample directions are a fixed low-discrepancy sequence and
// the noise a hash of the position).
//
// Two things live here:
//   * the `vertexColors` section: colours written into the mesh while the document is evaluated (model_apply_vertex_colors; evaluate_model calls it).
//   * the `texturing` section: a bake over the finished mesh (bake_model_textures) that returns the LAYERS of the model's texture (base colour,
//     decals, wear, occlusion, the UV wireframe) as pictures the size of the UV atlas. The project side (tools/common) writes them next to the
//     model and composes them in a layered image document (`*.image.json`, M52) that a person or an AI paints on; a re-bake renews only the
//     layers it owns and keeps every layer that was painted.
#pragma once

#include <functional>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/image.h"
#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/scene/mesh_store.h"
#include "fa/scene/model_kernel.h"

namespace fa {

struct ModelIssue;

inline constexpr int kModelTextureMinSize = 16;
inline constexpr int kModelTextureMaxSize = 4096;
inline constexpr int kModelTextureMaxBleed = 32;
inline constexpr int kModelTextureMaxSamples = 256;

// A colour as the format writes it: "#rrggbb", "#rrggbbaa", or [r, g, b] / [r, g, b, a] with numbers from 0 to 1. nullopt for anything else.
std::optional<Vec4> model_parse_color(const Json& value);

// ---- materials ---------------------------------------------------------------------------------------------------------------

// The extra fields of a document's material that say how its `texture` is put on the model.
struct ModelMaterialTexturing {
    std::string mapping =
        "uv";  // "uv": the texture is drawn through the model's uvs (the .glb references it). "triplanar": it is baked into the atlas.
    bool mappingGiven =
        false;  // the document said it (otherwise a document with `texturing` uses triplanar for a material with a texture)
    float scale = 1;        // triplanar: metres one repeat of the texture covers
    int sharpness = 4;      // triplanar: how fast the three projections hand over to each other (1 soft .. 16 hard)
    Vec3 offset{0, 0, 0};   // triplanar: metres the texture is shifted by
    Vec4 tint{1, 1, 1, 1};  // multiplies the texture (and the material colour)
};

// ---- vertex colour palettes --------------------------------------------------------------------------------------------------

// A colour of the `vertexColors` section: a colour, or the position of one in the palette.
struct ModelColorRef {
    bool isIndex = false;
    int index = 0;
    Vec4 rgba{1, 1, 1, 1};
};
struct ModelColorGradient {
    char axis = 'y';                               // the model axis the colour changes along
    ModelColorRef from, to;                        // at the low and the high end of the range
    std::optional<ModelColorRef> via;              // the middle
    std::optional<std::pair<float, float>> range;  // metres along the axis; default the part's own extent
};
struct ModelPartColors {
    std::optional<ModelColorRef> color;
    std::optional<ModelColorGradient> gradient;
    std::optional<float> variation;  // overrides the section's
};
struct ModelVertexColors {
    std::vector<Vec4> palette;  // explicit colours
    bool style = false;         // the palette is the project's style palette (assets.json style.palette)
    bool snap = true;           // every colour becomes the nearest palette colour (when there is a palette)
    bool flat = false;          // one colour per triangle (vertices are split): the faceted low-poly look
    float variation = 0;        // random brightness change per triangle (flat) or vertex, +-this much (0..0.5)
    int seed = 0;
    std::optional<ModelColorRef> color;                          // for the parts with no entry
    std::vector<std::pair<std::string, ModelPartColors>> parts;  // by part name ("" is the nodes that name no part)
};

// Reads the `vertexColors` section (the JSON under that key). Problems go to `issues` with pointers starting at "/vertexColors"; none is
// returned when there were any.
std::optional<ModelVertexColors> parse_model_vertex_colors(const Json& json, std::vector<ModelIssue>& issues);
Json model_vertex_colors_schema();
// The section with its defaults filled in.
Json model_vertex_colors_json(const ModelVertexColors& settings);

struct ModelVertexColorReport {
    std::size_t paletteSize = 0;
    std::size_t coloredTriangles = 0;
    std::size_t distinctColors = 0;  // after snapping, over the triangles' corners
    std::size_t verticesBefore = 0, verticesAfter = 0;
    std::vector<std::string> warnings;
};
// Colours the vertices of `mesh` (they multiply the colours it already has). `partNames[mesh.triParts[t]]` is the part of each triangle.
// `stylePalette` is the project's palette (empty if it has none). The triangles keep their order and parts; vertices are split where two
// triangles must differ (always for `flat`, between parts otherwise).
ModelVertexColorReport model_apply_vertex_colors(ModelMesh& mesh, const std::vector<std::string>& partNames,
                                                 const ModelVertexColors& settings,
                                                 const std::vector<Vec4>& stylePalette);

// ---- the texturing section ---------------------------------------------------------------------------------------------------

struct ModelWearSpec {
    std::string name;            // a label for the report
    std::string mask = "edges";  // edges, cavity, ao, thickness
    std::optional<Vec4> color;   // default: light for edges and thickness, dark for cavity and ao
    float amount = 0.8f;         // the opacity at the strongest
    std::optional<float> width;  // edges, cavity: metres of the band at an edge (default maps.edgeWidth)
    float threshold = 0.1f;      // the mask below this is nothing
    float noise = 0.4f;          // how much noise breaks the mask up (0..1)
    float noiseScale = 0.15f;    // metres per noise feature
    int seed = 0;
    float upBias = 0;                // -1..1: more on the surfaces that look up (dust, snow) or down
    std::vector<std::string> parts;  // only these parts (empty: all)
};
struct ModelDecalSpec {
    std::string name;
    std::string image;               // a project image
    std::vector<std::string> parts;  // only on these parts (empty: any)
    Json faces;                      // only on the faces a selection query chooses (null: any)
    Vec3 position{0, 0, 0};          // the centre of the projection, in model space
    Vec3 normal{0, 0, 1};            // the way the surface it sits on faces; the decal is projected along its opposite
    Vec2 size{1, 1};                 // metres
    float depth =
        0;  // metres the projection reaches from the plane through `position`, each way along the normal (0 = the smaller side)
    float rotation = 0;  // degrees around the normal
    float opacity = 1;
    Vec4 tint{1, 1, 1, 1};
    float maxAngle = 75;  // degrees: surfaces turned more than this away from `normal` are left alone
};
struct ModelMapSettings {
    int samples = 16;                // rays per texel for occlusion and thickness (4..256)
    float distance = 0;              // metres an occluder may be away (0 = 15% of the model's diagonal)
    float thicknessDistance = 0;     // metres the thickness is measured up to (0 = 50% of the diagonal)
    float edgeAngle = 20;            // degrees: an edge turns the surface at least this much to count as a sharp edge
    float edgeWidth = 0;             // metres: the width of the band a sharp edge gives (0 = 3% of the diagonal)
    std::vector<std::string> write;  // maps also written as pictures: "ao", "curvature", "thickness"
};
struct ModelTexturing {
    int size = 0;                          // side of the atlas; 0 = the `uv` section's texture size
    int bleed = -1;                        // texels the colours are spread beyond each piece (-1 = the uv padding)
    std::string vertexColors = "bake";     // "bake": vertex colours go into the texture; "keep": they stay on the mesh
    Vec4 background{0.5f, 0.5f, 0.5f, 1};  // the texels no triangle covers
    std::string document;              // the layered image document ("" = <model>.texture.image.json next to the model)
    std::optional<float> aoStrength;   // set: occlusion is baked and multiplied in with this strength (0..1)
    std::vector<std::string> aoParts;  // occlusion only darkens these parts (empty: all)
    ModelMapSettings maps;
    std::vector<ModelWearSpec> wear;
    std::vector<ModelDecalSpec> decals;
};

// Reads the `texturing` section. `materials` are the document's material names (for the references inside). Problems go to `issues` with
// pointers starting at "/texturing".
std::optional<ModelTexturing> parse_model_texturing(const Json& json, std::vector<ModelIssue>& issues);
Json model_texturing_schema();
// The section with its defaults filled in.
Json model_texturing_json(const ModelTexturing& settings);
// The extra fields of a material (mapping, textureScale, textureOffset, sharpness, tint): reads them from the material's JSON object (they
// are not part of MeshMaterial). Problems go to `issues` with pointers under `at`.
ModelMaterialTexturing parse_model_material_texturing(const Json& material, const std::string& at,
                                                      std::vector<ModelIssue>& issues);
// Their JSON schema properties.
Json model_material_texturing_schema_properties();
// The keys of a material object that parse_model_material_texturing reads.
const std::vector<std::string>& model_material_texturing_keys();

// ---- baking ------------------------------------------------------------------------------------------------------------------

// The picture of a project file a decal or a material names (a PNG/JPG read through the VFS); the caller supplies it so tests need no files.
using ModelImageSource = std::function<Result<Image>(const std::string& path)>;

struct ModelTextureInput {
    const MeshData* mesh = nullptr;  // the evaluated model: positions, normals, uvs (one atlas), colours, submeshes
    const ModelTexturing* settings = nullptr;
    // material name -> texturing options and the material itself, in document order; "" is the default material
    std::vector<std::pair<std::string, ModelMaterialTexturing>> mappings;
    ModelImageSource images;
    int uvTextureSize = 0;  // the `uv` section's report: the size the uvs were packed for
    int uvPadding = 2;
};

// What a map looks like over the texels the model covers.
struct ModelMapStats {
    std::string name;                   // "ao", "curvature", "thickness", or a wear entry's name
    double mean = 0, min = 0, max = 0;  // 0..1 over the covered texels
    double coverage =
        0;  // share of the covered texels at 0.1 or more (wear, decals), or that differ from the neutral value (maps)
};
struct ModelTextureReport {
    int size = 0;
    int bleed = 0;
    std::size_t texels = 0;  // covered by a triangle
    double utilization = 0;  // covered / size^2
    double overlap = 0;      // share of covered texels that two triangles claim (a painted texel shows on both)
    std::vector<ModelMapStats> maps;  // ao, curvature, thickness when computed
    std::vector<ModelMapStats> wear;  // one per wear entry
    struct DecalInfo {
        std::string name;
        std::size_t texels = 0;     // painted
        std::size_t triangles = 0;  // that the projection reaches
    };
    std::vector<DecalInfo> decals;
    struct PartInfo {
        std::string part, material, mapping;  // mapping: "color", "uv" or "triplanar"
        std::string texture;
        std::size_t texels = 0;
    };
    std::vector<PartInfo> parts;
    std::vector<std::string> warnings;
};

// The layers of the model's texture, each the size of the atlas, straight alpha like every image of the engine.
struct ModelTextureLayers {
    int size = 0;
    Image base;       // material colours, textures and vertex colours (opaque unless a material is transparent)
    Image decals;     // transparent where no decal is
    Image wear;       // transparent where nothing is worn or dirty
    Image occlusion;  // opaque grey: 1 (white) is open, multiplied over the rest; empty when occlusion is not asked for
    Image uvWire;     // transparent with the triangles' edges drawn, a colour per part
    Image ao, curvature, thickness;  // the maps in `maps.write` (and the ones needed), grey; empty when not computed
    bool hasDecals = false, hasWear = false;
    ModelTextureReport report;
    std::vector<std::string> inputs;  // project images read
};

// Bakes the layers. Fails (with a message that says what to change) when the mesh has no atlas uvs, a decal or texture cannot be read, or the
// size is out of range. The mesh must come from a document with an atlas `uv` section.
Result<ModelTextureLayers> bake_model_textures(const ModelTextureInput& input);

// The three maps alone, for a mesh and a size (what model.bake_maps writes). `maps` is the list asked for ("ao", "curvature", "thickness").
struct ModelMapsResult {
    int size = 0;
    Image ao, curvature, thickness;
    ModelTextureReport report;
};
Result<ModelMapsResult> bake_model_maps(const MeshData& mesh, int size, int bleed, const ModelMapSettings& settings,
                                        const std::vector<std::string>& maps);

// The grey (0..1) a map holds at each covered texel, for tests and measurements: the same maps as above but as float arrays (row 0 = top).
struct ModelMapField {
    int size = 0;
    std::vector<float> values;  // size * size, NaN where no triangle covers the texel
};
Result<ModelMapField> compute_model_map(const MeshData& mesh, int size, const ModelMapSettings& settings,
                                        const std::string& map);

}  // namespace fa
