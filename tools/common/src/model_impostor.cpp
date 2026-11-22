// model.bake_impostor (M75-P1c, docs/BIG_WORLDS_LOD.md "Impostors"): a model drawn from views x views directions into an atlas the renderer shows
// as a camera-facing quad far away. The pictures are made on the CPU with an orthographic rasterizer (no GPU, no window), single-threaded and
// in a fixed order, so the same model and arguments give the same files on one build. The layout and the maths of the atlas are
// fa/scene/impostor.h; this file is the bake and the command.
#include <algorithm>
#include <cmath>
#include <limits>
#include <map>

#include "assets_internal.h"
#include "fa/core/image.h"
#include "fa/core/strings.h"
#include "fa/scene/gltf_mesh.h"
#include "fa/scene/impostor.h"
#include "fa/scene/model_doc.h"
#include "fa/tooling/model_bake.h"
#include "util.h"

namespace fa::assets_detail {

namespace {

constexpr std::size_t kMaxTriangles = 4000000;  // a model with more is too heavy to draw from every direction
constexpr double kMaxFrameTriangles = 4.0e8;    // triangles x frames: the setup work of the whole bake
constexpr double kMaxPixelWork = 6.0e9;         // pixels the triangles' bounding boxes cover, over every frame
constexpr int kDilatePasses = 4;                // pixels the colour of an edge grows into the transparent area
constexpr const char* kCommand = "model.bake_impostor";

const float* srgb_to_linear_table() {
    static float table[256];
    static bool ready = false;
    if (!ready) {
        for (int i = 0; i < 256; ++i) {
            const double c = i / 255.0;
            table[i] = float(c <= 0.04045 ? c / 12.92 : std::pow((c + 0.055) / 1.055, 2.4));
        }
        ready = true;
    }
    return table;
}

std::uint8_t linear_to_srgb_byte(float lin) {
    const double c = std::clamp(double(lin), 0.0, 1.0);
    const double s = c <= 0.0031308 ? c * 12.92 : 1.055 * std::pow(c, 1.0 / 2.4) - 0.055;
    return std::uint8_t(std::lround(std::clamp(s, 0.0, 1.0) * 255.0));
}

struct Tex {
    const Image* image = nullptr;  // null: the material has no base colour texture
};

// What the rasterizer needs about the mesh, once.
struct Scene {
    const MeshData* mesh = nullptr;
    std::vector<Tex> textures;  // per submesh
    Vec3 center{};
    double radius = 1;
    std::size_t triangles = 0;
};

struct FrameBuffer {
    int side = 0;  // samples per side
    std::vector<float> depth;
    std::vector<float> rgb;  // linear colour, 3 per sample
    std::vector<float> nrm;  // model-space normal, 3 per sample
    void reset(int s) {
        side = s;
        const std::size_t n = std::size_t(s) * std::size_t(s);
        depth.assign(n, -std::numeric_limits<float>::infinity());
        rgb.assign(n * 3, 0.0f);
        nrm.assign(n * 3, 0.0f);
    }
};

struct Projected {
    double sx = 0, sy = 0, z = 0;
};

// Draws the whole mesh seen from `dir` into `fb`. `work` counts the pixels the bounding boxes of the triangles cover (a deterministic count).
void draw_frame(const Scene& sc, Vec3 dir, FrameBuffer& fb, std::vector<Projected>& proj, double& work) {
    const MeshData& m = *sc.mesh;
    Vec3 right, up;
    impostor_basis(dir, right, up);
    const double side = double(fb.side), inv = 1.0 / (2.0 * sc.radius);
    const std::size_t vc = m.vertex_count();
    proj.resize(vc);
    for (std::size_t i = 0; i < vc; ++i) {
        const Vec3 rel{m.positions[i * 3] - sc.center.x, m.positions[i * 3 + 1] - sc.center.y,
                       m.positions[i * 3 + 2] - sc.center.z};
        proj[i] = {(double(dot(rel, right)) * inv + 0.5) * side, (0.5 - double(dot(rel, up)) * inv) * side,
                   double(dot(rel, dir))};
    }
    const float* toLinear = srgb_to_linear_table();
    for (std::size_t s = 0; s < m.submeshes.size(); ++s) {
        const MeshSubmesh& sub = m.submeshes[s];
        const Image* img = sc.textures[s].image;
        const Color& cf = sub.material.color;
        const std::size_t end = std::min<std::size_t>(std::size_t(sub.start) + sub.count, m.indices.size());
        for (std::size_t k = sub.start; k + 3 <= end; k += 3) {
            const std::uint32_t id[3] = {m.indices[k], m.indices[k + 1], m.indices[k + 2]};
            if (id[0] >= vc || id[1] >= vc || id[2] >= vc) continue;
            const Projected &a = proj[id[0]], &b = proj[id[1]], &c = proj[id[2]];
            const double area = (b.sx - a.sx) * (c.sy - a.sy) - (c.sx - a.sx) * (b.sy - a.sy);
            if (std::fabs(area) < 1e-12) continue;
            // the geometric normal (counter-clockwise = front): a single-sided surface is not drawn from behind
            const Vec3 p0{m.positions[id[0] * 3], m.positions[id[0] * 3 + 1], m.positions[id[0] * 3 + 2]};
            const Vec3 p1{m.positions[id[1] * 3], m.positions[id[1] * 3 + 1], m.positions[id[1] * 3 + 2]};
            const Vec3 p2{m.positions[id[2] * 3], m.positions[id[2] * 3 + 1], m.positions[id[2] * 3 + 2]};
            const bool front = dot(cross(p1 - p0, p2 - p0), dir) > 0.0f;
            if (!front && !sub.material.doubleSided) continue;
            const int x0 = std::max(0, int(std::floor(std::min({a.sx, b.sx, c.sx})))),
                      x1 = std::min(fb.side - 1, int(std::ceil(std::max({a.sx, b.sx, c.sx}))));
            const int y0 = std::max(0, int(std::floor(std::min({a.sy, b.sy, c.sy})))),
                      y1 = std::min(fb.side - 1, int(std::ceil(std::max({a.sy, b.sy, c.sy}))));
            if (x1 < x0 || y1 < y0) continue;
            work += double(x1 - x0 + 1) * double(y1 - y0 + 1);
            const double invArea = 1.0 / area;
            for (int y = y0; y <= y1; ++y)
                for (int x = x0; x <= x1; ++x) {
                    const double px = x + 0.5, py = y + 0.5;
                    const double w0 = ((b.sx - px) * (c.sy - py) - (c.sx - px) * (b.sy - py)) * invArea;
                    const double w1 = ((c.sx - px) * (a.sy - py) - (a.sx - px) * (c.sy - py)) * invArea;
                    const double w2 = 1.0 - w0 - w1;
                    constexpr double kEdge = -1e-9;
                    if (w0 < kEdge || w1 < kEdge || w2 < kEdge) continue;
                    const float z = float(w0 * a.z + w1 * b.z + w2 * c.z);
                    const std::size_t at = std::size_t(y) * std::size_t(fb.side) + std::size_t(x);
                    if (z <= fb.depth[at]) continue;
                    float col[4] = {cf.r, cf.g, cf.b, cf.a};
                    if (!m.colors.empty())
                        for (int ch = 0; ch < 4; ++ch)
                            col[ch] *= float(w0 * m.colors[id[0] * 4 + ch] + w1 * m.colors[id[1] * 4 + ch] +
                                             w2 * m.colors[id[2] * 4 + ch]);
                    if (img && img->width > 0 && img->height > 0) {
                        const double u = w0 * m.uvs[id[0] * 2] + w1 * m.uvs[id[1] * 2] + w2 * m.uvs[id[2] * 2];
                        const double v =
                            w0 * m.uvs[id[0] * 2 + 1] + w1 * m.uvs[id[1] * 2 + 1] + w2 * m.uvs[id[2] * 2 + 1];
                        auto wrap = [](double t, int n) {
                            const double f = t - std::floor(t);
                            return std::min(int(f * n), n - 1);
                        };
                        const std::uint8_t* t =
                            &img->rgba[(std::size_t(wrap(v, img->height)) * std::size_t(img->width) +
                                        std::size_t(wrap(u, img->width))) *
                                       4];
                        col[0] *= toLinear[t[0]];
                        col[1] *= toLinear[t[1]];
                        col[2] *= toLinear[t[2]];
                        col[3] *= t[3] / 255.0f;
                    }
                    if (col[3] < 0.5f) continue;  // the cut-out of leaves and fences: the silhouette is the alpha
                    Vec3 n{float(w0 * m.normals[id[0] * 3] + w1 * m.normals[id[1] * 3] + w2 * m.normals[id[2] * 3]),
                           float(w0 * m.normals[id[0] * 3 + 1] + w1 * m.normals[id[1] * 3 + 1] +
                                 w2 * m.normals[id[2] * 3 + 1]),
                           float(w0 * m.normals[id[0] * 3 + 2] + w1 * m.normals[id[1] * 3 + 2] +
                                 w2 * m.normals[id[2] * 3 + 2])};
                    n = normalize(n);
                    if (!front) n = n * -1.0f;
                    fb.depth[at] = z;
                    fb.rgb[at * 3] = col[0];
                    fb.rgb[at * 3 + 1] = col[1];
                    fb.rgb[at * 3 + 2] = col[2];
                    fb.nrm[at * 3] = n.x;
                    fb.nrm[at * 3 + 1] = n.y;
                    fb.nrm[at * 3 + 2] = n.z;
                }
        }
    }
}

// The atlas under construction: RGBA8 pictures of the colour and of the normal (alpha = coverage), and which pixels hold colour.
struct Atlas {
    int size = 0;
    Image albedo, normal;
    void init(int s) {
        size = s;
        for (Image* im : {&albedo, &normal}) {
            im->width = im->height = s;
            im->rgba.assign(std::size_t(s) * std::size_t(s) * 4, 0);
        }
    }
};

void resolve_frame(const FrameBuffer& fb, int ss, int frameSize, int ox, int oy, Atlas& atlas) {
    for (int y = 0; y < frameSize; ++y)
        for (int x = 0; x < frameSize; ++x) {
            double r = 0, g = 0, b = 0, nx = 0, ny = 0, nz = 0;
            int covered = 0;
            for (int sy = 0; sy < ss; ++sy)
                for (int sx = 0; sx < ss; ++sx) {
                    const std::size_t at = std::size_t(y * ss + sy) * std::size_t(fb.side) + std::size_t(x * ss + sx);
                    if (!(fb.depth[at] > -std::numeric_limits<float>::infinity())) continue;
                    ++covered;
                    r += fb.rgb[at * 3];
                    g += fb.rgb[at * 3 + 1];
                    b += fb.rgb[at * 3 + 2];
                    nx += fb.nrm[at * 3];
                    ny += fb.nrm[at * 3 + 1];
                    nz += fb.nrm[at * 3 + 2];
                }
            if (covered == 0) continue;
            const std::size_t o = (std::size_t(oy + y) * std::size_t(atlas.size) + std::size_t(ox + x)) * 4;
            const double inv = 1.0 / covered;
            const std::uint8_t alpha = std::uint8_t(std::lround(255.0 * covered / double(ss * ss)));
            atlas.albedo.rgba[o] = linear_to_srgb_byte(float(r * inv));
            atlas.albedo.rgba[o + 1] = linear_to_srgb_byte(float(g * inv));
            atlas.albedo.rgba[o + 2] = linear_to_srgb_byte(float(b * inv));
            atlas.albedo.rgba[o + 3] = alpha;
            Vec3 n = normalize(Vec3{float(nx), float(ny), float(nz)});
            if (length_sq(n) < 0.5f) n = {0, 0, 1};
            atlas.normal.rgba[o] = std::uint8_t(std::lround((n.x * 0.5f + 0.5f) * 255.0f));
            atlas.normal.rgba[o + 1] = std::uint8_t(std::lround((n.y * 0.5f + 0.5f) * 255.0f));
            atlas.normal.rgba[o + 2] = std::uint8_t(std::lround((n.z * 0.5f + 0.5f) * 255.0f));
            atlas.normal.rgba[o + 3] = alpha;
        }
}

// The colour of the silhouette grows kDilatePasses pixels into the transparent area of every frame (never into the next frame), so the
// filtering at the edge blends the model's colour, not the black of the empty pixels. Alpha is untouched.
void dilate(Image& img, int frameSize) {
    const int size = img.width;
    std::vector<std::uint8_t> filled(std::size_t(size) * std::size_t(size), 0);
    for (std::size_t i = 0; i < filled.size(); ++i) filled[i] = img.rgba[i * 4 + 3] > 0 ? 1 : 0;
    for (int pass = 0; pass < kDilatePasses; ++pass) {
        std::vector<std::uint8_t> nextFilled = filled;
        std::vector<std::uint8_t> nextRgba = img.rgba;
        for (int y = 0; y < size; ++y)
            for (int x = 0; x < size; ++x) {
                const std::size_t at = std::size_t(y) * std::size_t(size) + std::size_t(x);
                if (filled[at]) continue;
                const int fx0 = x / frameSize * frameSize, fy0 = y / frameSize * frameSize;
                int sum[3] = {0, 0, 0}, n = 0;
                for (int dy = -1; dy <= 1; ++dy)
                    for (int dx = -1; dx <= 1; ++dx) {
                        const int nx = x + dx, ny = y + dy;
                        if (nx < fx0 || ny < fy0 || nx >= fx0 + frameSize || ny >= fy0 + frameSize) continue;
                        const std::size_t q = std::size_t(ny) * std::size_t(size) + std::size_t(nx);
                        if (!filled[q]) continue;
                        for (int ch = 0; ch < 3; ++ch) sum[ch] += img.rgba[q * 4 + std::size_t(ch)];
                        ++n;
                    }
                if (n == 0) continue;
                for (int ch = 0; ch < 3; ++ch) nextRgba[at * 4 + std::size_t(ch)] = std::uint8_t((sum[ch] + n / 2) / n);
                nextFilled[at] = 1;
            }
        filled.swap(nextFilled);
        img.rgba.swap(nextRgba);
    }
}

std::string strip_extension(const std::string& rel) {
    const std::size_t slash = rel.rfind('/');
    const std::size_t dot = rel.rfind('.');
    return dot == std::string::npos || (slash != std::string::npos && dot < slash) ? rel : rel.substr(0, dot);
}

int int_arg(const Json& a, const char* key, int def, int lo, int hi, const char* hint) {
    if (!a.contains(key) || a[key].is_null()) return def;
    const std::string pointer = std::string("/") + key;
    if (!a[key].is_number_integer())
        arg_error(kCommand, pointer, "must be a whole number, " + std::to_string(lo) + ".." + std::to_string(hi) + ".",
                  hint);
    const long long v = a[key].get<long long>();
    if (v < lo || v > hi)
        arg_error(kCommand, pointer,
                  "is " + std::to_string(v) + ", outside " + std::to_string(lo) + ".." + std::to_string(hi) + ".",
                  hint);
    return int(v);
}

// An impostor file this command wrote before (the format line), so only those are replaced without `overwrite`.
bool is_our_impostor(const std::string& projectDir, const std::string& rel) {
    ProjectRootGuard root(projectDir);
    auto text = fs::read_text(rel);
    if (!text.ok()) return false;
    auto j = parse_json(*text, rel);
    return j.ok() && j->is_object() && j->contains("format") && (*j)["format"].is_string() &&
           (*j)["format"].get<std::string>() == kImpostorFormat;
}

// The entities of the loaded scene that draw `meshPath` get MeshRenderer.impostor = `file` (only the live scene: save it to keep it).
Json apply_to_scene(const CommandRegistry& registry, const std::string& meshPath, const std::string& file,
                    Json& warnings) {
    Json applied = Json::array();
    if (!registry.info("scene.list_entities") || !registry.info("scene.set_component")) {
        warnings.push_back(
            "apply: there is no scene in this session (no scene.* commands), so no MeshRenderer was changed. Set "
            "MeshRenderer.impostor to '" +
            file + "' with scene.set_component or in the scene file.");
        return applied;
    }
    CommandResult list =
        registry.call("scene.list_entities", Json::object({{"component", "MeshRenderer"}, {"limit", 20000}}));
    if (!list.ok) {
        warnings.push_back("apply: scene.list_entities failed: " + list.error.value("message", std::string()));
        return applied;
    }
    if (list.result.value("total", 0) > 20000)
        warnings.push_back("apply: the scene has more than 20000 MeshRenderers; only the first 20000 were looked at.");
    for (const Json& e : list.result["entities"]) {
        const std::string id = e.value("id", std::string());
        CommandResult got = registry.call("scene.get_entity", Json::object({{"id", id}}));
        if (!got.ok || !got.result.contains("components") || !got.result["components"].contains("MeshRenderer"))
            continue;
        const Json& mr = got.result["components"]["MeshRenderer"];
        if (!mr.contains("mesh") || !mr["mesh"].is_string()) continue;
        auto norm = fs::normalize_checked(mr["mesh"].get<std::string>());
        if (!norm.ok() || *norm != meshPath) continue;
        CommandResult set = registry.call(
            "scene.set_component",
            Json::object({{"id", id}, {"component", "MeshRenderer"}, {"fields", Json::object({{"impostor", file}})}}));
        if (set.ok)
            applied.push_back(id);
        else
            warnings.push_back("apply: '" + id + "' was not changed: " + set.error.value("message", std::string()));
    }
    if (applied.empty() && warnings.empty())
        warnings.push_back("apply: no entity of the loaded scene draws '" + meshPath +
                           "'; set MeshRenderer.impostor to '" + file + "' by hand.");
    return applied;
}

Json bake_impostor_command(const CommandRegistry& registry, const std::string& projectDir, const Json& a) {
    check_arg_keys(kCommand, a, "", {"model", "views", "resolution", "mode", "apply", "overwrite"});
    const std::string arg = tooling_detail::arg_string(a, "model", true);
    const int views =
        int_arg(a, "views", 8, kImpostorMinViews, kImpostorMaxViews,
                "More views follow the camera more closely and cost atlas pixels; 8 is a good start (a tree: 12).");
    const int resolution = int_arg(a, "resolution", 1024, kImpostorMinViews * kImpostorMinFrame, kImpostorMaxAtlas,
                                   "The atlas side in pixels, views times the side of one frame; try 1024 or 2048.");
    const std::string modeName = tooling_detail::arg_string(a, "mode", false, "octahedral");
    ImpostorMode mode;
    if (!impostor_mode_from_name(modeName, mode))
        arg_error(
            kCommand, "/mode", "is \"" + modeName + "\".",
            "Use \"octahedral\" (the model is seen from every side) or \"hemiOctahedral\" (only from above: trees, "
            "rocks, buildings; twice the angular resolution for the same atlas)." +
                (modeName.empty()
                     ? std::string()
                     : " " + did_you_mean(modeName, std::vector<std::string>{"octahedral", "hemiOctahedral"})));
    const int frameSize = resolution / views;
    if (frameSize < kImpostorMinFrame)
        arg_error(kCommand, "/resolution",
                  "is " + std::to_string(resolution) + ", which leaves " + std::to_string(frameSize) +
                      " pixels for each of the " + std::to_string(views) + " x " + std::to_string(views) +
                      " frames (at least " + std::to_string(kImpostorMinFrame) + " are needed).",
                  "Raise resolution to " + std::to_string(views * kImpostorMinFrame) + " or more, or lower views.");
    const bool apply = tooling_detail::arg_bool(a, "apply", false);
    const bool overwrite = tooling_detail::arg_bool(a, "overwrite", false);

    // which mesh file
    auto norm = fs::normalize_checked(arg);
    if (!norm.ok() || norm->empty())
        fail("invalid_argument", "/model: '" + arg + "' is not a project-relative path.",
             "Example: \"assets/models/tree.glb\" or \"assets/models/tree.model.json\".");
    std::string meshPath = *norm;
    const std::string lower = to_lower(*norm);
    if (ends_with(lower, kModelDocSuffix)) {
        ProjectRootGuard root(projectDir);
        auto doc = load_model_doc(*norm);
        if (!doc.ok()) fail("invalid_document", doc.error().message, doc.error().hint);
        meshPath = model_document_output(*doc, *norm);
    } else if (!ends_with(lower, ".glb") && !ends_with(lower, ".gltf")) {
        fail("invalid_argument", "/model: '" + *norm + "' is not a .glb, a .gltf or a .model.json.",
             "Give the model file the MeshRenderer draws, e.g. \"assets/models/tree.glb\", or its model document.");
    }
    {
        ProjectRootGuard root(projectDir);
        if (!fs::exists(meshPath))
            fail("not_found",
                 "/model: '" + meshPath + "' does not exist" +
                     (meshPath == *norm ? "." : " (the .glb of '" + *norm + "' is not baked yet)."),
                 meshPath == *norm ? "Check the path; assets.list shows the project's models."
                                   : "Run model.bake {\"path\":\"" + *norm + "\"} first.");
    }

    // the files: decided and checked before the expensive part
    const std::string stem = strip_extension(meshPath);
    const std::string jsonRel = stem + ".impostor.json", albedoRel = stem + ".impostor.png",
                      normalRel = stem + ".impostor.normal.png";
    const stdfs::path jsonFile = project_write_file(projectDir, jsonRel);
    const stdfs::path albedoFile = project_write_file(projectDir, albedoRel);
    const stdfs::path normalFile = project_write_file(projectDir, normalRel);
    if (!overwrite) {
        std::error_code ec;
        const bool ours = is_our_impostor(projectDir, jsonRel);
        for (const auto& [file, rel] :
             {std::pair{jsonFile, jsonRel}, std::pair{albedoFile, albedoRel}, std::pair{normalFile, normalRel}})
            if (stdfs::exists(file, ec) && !ours)
                fail("exists", "'" + rel + "' exists and no impostor of this model wrote it.",
                     "Pass \"overwrite\": true to replace it, or move the file.");
    }

    // the mesh
    ProjectRootGuard root(projectDir);
    auto gltf = read_gltf_mesh(meshPath);
    if (!gltf.ok()) fail("invalid_argument", gltf.error().message, gltf.error().hint);
    const MeshData& data = gltf->data;
    Scene sc;
    sc.mesh = &data;
    sc.triangles = data.triangle_count();
    if (sc.triangles == 0 || data.vertex_count() == 0)
        fail("invalid_argument", "/model: '" + meshPath + "' has no triangles.",
             "An impostor shows a mesh; pick a model that has one.");
    if (sc.triangles > kMaxTriangles || double(sc.triangles) * views * views > kMaxFrameTriangles)
        fail("too_heavy",
             "/model: '" + meshPath + "' has " + std::to_string(sc.triangles) + " triangles; drawing it from " +
                 std::to_string(views * views) + " directions is more work than one bake allows (" +
                 std::to_string(std::size_t(kMaxFrameTriangles)) + " triangle draws).",
             "Bake the impostor from a lower level of detail: model.generate_lods writes <name>.lod1.glb, "
             "<name>.lod2.glb...; give one "
             "of those as `model` (the impostor is the same picture from afar), or lower `views`.");
    // the sphere that holds every vertex a triangle uses
    Vec3 lo{std::numeric_limits<float>::max(), std::numeric_limits<float>::max(), std::numeric_limits<float>::max()},
        hi = lo * -1.0f;
    for (std::uint32_t idx : data.indices) {
        if (idx >= data.vertex_count()) continue;
        const Vec3 p{data.positions[idx * 3], data.positions[idx * 3 + 1], data.positions[idx * 3 + 2]};
        lo = {std::min(lo.x, p.x), std::min(lo.y, p.y), std::min(lo.z, p.z)};
        hi = {std::max(hi.x, p.x), std::max(hi.y, p.y), std::max(hi.z, p.z)};
    }
    sc.center = (lo + hi) * 0.5f;
    double r2 = 0;
    for (std::uint32_t idx : data.indices) {
        if (idx >= data.vertex_count()) continue;
        const double dx = data.positions[idx * 3] - sc.center.x, dy = data.positions[idx * 3 + 1] - sc.center.y,
                     dz = data.positions[idx * 3 + 2] - sc.center.z;
        r2 = std::max(r2, dx * dx + dy * dy + dz * dz);
    }
    sc.radius = std::sqrt(r2) * 1.02;
    if (!(sc.radius > 1e-6) || !std::isfinite(sc.radius))
        fail("invalid_argument", "/model: '" + meshPath + "' has no size (every vertex is at one point).",
             "Pick a model with some extent.");

    // textures
    Json warnings = Json::array();
    std::map<std::string, Image> loaded;
    std::vector<Image> embedded(gltf->materials.size());
    std::vector<bool> hasEmbedded(gltf->materials.size(), false);
    for (const GltfEmbeddedImage& e : gltf->embedded) {
        if (e.material >= embedded.size()) continue;
        auto img = decode_image(e.bytes.data(), e.bytes.size());
        if (img.ok()) {
            embedded[e.material] = std::move(*img);
            hasEmbedded[e.material] = true;
        } else {
            warnings.push_back("A texture inside '" + meshPath + "' could not be read (" + img.error().message +
                               "); its colour factor is used.");
        }
    }
    sc.textures.resize(data.submeshes.size());
    for (std::size_t s = 0; s < data.submeshes.size(); ++s) {
        const std::string& tex = data.submeshes[s].material.texture;
        if (!tex.empty()) {
            auto it = loaded.find(tex);
            if (it == loaded.end()) {
                auto img = load_image(tex);
                if (!img.ok()) {
                    warnings.push_back("The texture '" + tex + "' could not be read (" + img.error().message +
                                       "); its colour factor is used.");
                    img = Image{};
                }
                it = loaded.emplace(tex, std::move(*img)).first;
            }
            if (it->second.width > 0) sc.textures[s].image = &it->second;
        } else if (s < gltf->submeshMaterial.size() && gltf->submeshMaterial[s] < hasEmbedded.size() &&
                   hasEmbedded[gltf->submeshMaterial[s]]) {
            sc.textures[s].image = &embedded[gltf->submeshMaterial[s]];
        }
    }

    // the frames
    const int ss = frameSize <= 512 ? 2 : 1;  // samples per pixel side: the biggest frames keep the memory under 100 MB
    Atlas atlas;
    atlas.init(views * frameSize);
    FrameBuffer fb;
    std::vector<Projected> proj;
    double work = 0;
    for (int j = 0; j < views; ++j)
        for (int i = 0; i < views; ++i) {
            fb.reset(frameSize * ss);
            draw_frame(sc, impostor_direction(mode, views, i, j), fb, proj, work);
            if (work > kMaxPixelWork)
                fail("too_heavy",
                     "/model: '" + meshPath + "' covers too many pixels over " + std::to_string(views * views) +
                         " frames (its triangles are huge on screen).",
                     "Lower `views` or `resolution`, or bake from a model with fewer, smaller triangles.");
            resolve_frame(fb, ss, frameSize, i * frameSize, j * frameSize, atlas);
        }
    dilate(atlas.albedo, frameSize);
    dilate(atlas.normal, frameSize);

    ImpostorAtlas out;
    out.mode = mode;
    out.views = views;
    out.frameSize = frameSize;
    out.albedo = albedoRel;
    out.normal = normalRel;
    out.center = sc.center;
    out.radius = float(sc.radius);
    out.source = meshPath;
    Json file = impostor_to_json(out);
    file["triangles"] = sc.triangles;
    file["bounds"] = Json::object({{"min", Json::array({lo.x, lo.y, lo.z})}, {"max", Json::array({hi.x, hi.y, hi.z})}});

    std::string err;
    const auto png1 = encode_png(atlas.albedo), png2 = encode_png(atlas.normal);
    if (!tooling_detail::write_file(albedoFile,
                                    std::string_view(reinterpret_cast<const char*>(png1.data()), png1.size()), &err) ||
        !tooling_detail::write_file(normalFile,
                                    std::string_view(reinterpret_cast<const char*>(png2.data()), png2.size()), &err) ||
        !tooling_detail::write_file(jsonFile, dump_json(file), &err))
        fail("failed", "Cannot write the impostor files next to '" + meshPath + "': " + err,
             "Check that the folder is writable.");

    Json result = Json::object({{"file", jsonRel},
                                {"albedo", albedoRel},
                                {"normal", normalRel},
                                {"mode", impostor_mode_name(mode)},
                                {"views", views},
                                {"frameSize", frameSize},
                                {"resolution", views * frameSize},
                                {"radius", std::round(sc.radius * 1000.0) / 1000.0},
                                {"triangles", sc.triangles}});
    if (apply) result["applied"] = apply_to_scene(registry, meshPath, jsonRel, warnings);
    result["nextSteps"] =
        Json::array({"Set MeshRenderer.impostor to \"" + jsonRel +
                     "\" and impostorDistance to where the model should turn into its picture (metres, "
                     "or a screen fraction in screenSize mode)."});
    if (!warnings.empty()) result["warnings"] = warnings;
    return result;
}

}  // namespace

void register_model_impostor_command(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = kCommand;
    info.category = "assets";
    info.readOnly = false;
    info.summary =
        "Bake an impostor atlas of a model: pictures from many directions that a camera-facing quad shows far away.";
    info.description =
        "Draws `model` (a .glb or .gltf, or a .model.json: its baked .glb) from views x views directions with a CPU "
        "rasterizer (orthographic, no GPU) and writes, next to the model, `<name>.impostor.json` (the atlas data), "
        "`<name>.impostor.png` (colour with alpha) and `<name>.impostor.normal.png` (model-space normals, so the quad "
        "is lit like the model). `resolution` is the side of the whole atlas in pixels (default 1024, at most 4096). "
        "Then set MeshRenderer.impostor and impostorDistance: the renderer draws the card from there on "
        "(docs/BIG_WORLDS_LOD.md, \"Impostors\"). "
        "Example: model.bake_impostor "
        "{\"model\":\"assets/models/tree.glb\",\"views\":8,\"mode\":\"hemiOctahedral\"}. " FA_COMMAND_DETAILS
        "Frames cover a sphere around the model, so one frame size fits every direction. `mode` octahedral (default) "
        "covers every direction; hemiOctahedral only the upper half (y >= 0), with twice the angular resolution: for "
        "trees, rocks and buildings that are seen from above. Each frame gets resolution / views pixels, at least 8. "
        "Same model and arguments give the same files. Transparent materials are cut out at alpha 0.5. A model of "
        "more than 4 million triangles, or whose triangles x views x views is above 400 million, is refused: bake from "
        "a lower LOD (model.generate_lods). Existing files of an earlier bake are replaced; others need `overwrite`. "
        "`apply` also sets MeshRenderer.impostor of the entities of the loaded scene that draw the model (the scene "
        "file is not saved: set the field in the scene to keep it). Result: {file, albedo, normal, mode, views, "
        "frameSize, resolution, radius, triangles, applied?, warnings?}.";
    info.inputSchema = Json::object(
        {{"type", "object"},
         {"required", Json::array({"model"})},
         {"additionalProperties", false},
         {"properties",
          Json::object(
              {{"model",
                Json::object(
                    {{"type", "string"},
                     {"description",
                      "The model to bake: a project-relative .glb or .gltf, or the .model.json whose .glb it is."}})},
               {"views", Json::object({{"type", "integer"},
                                       {"minimum", kImpostorMinViews},
                                       {"maximum", kImpostorMaxViews},
                                       {"default", 8},
                                       {"description", "Frames per side of the atlas: views x views directions."}})},
               {"resolution",
                Json::object({{"type", "integer"},
                              {"minimum", kImpostorMinViews * kImpostorMinFrame},
                              {"maximum", kImpostorMaxAtlas},
                              {"default", 1024},
                              {"description",
                               "Pixels of the whole atlas side; one frame is resolution / views (at least 8)."}})},
               {"mode", Json::object({{"type", "string"},
                                      {"enum", Json::array({"octahedral", "hemiOctahedral"})},
                                      {"default", "octahedral"},
                                      {"description", "octahedral: every direction. hemiOctahedral: only from above (y "
                                                      ">= 0), twice the resolution."}})},
               {"apply",
                Json::object(
                    {{"type", "boolean"},
                     {"default", false},
                     {"description",
                      "Set MeshRenderer.impostor of the loaded scene's entities that draw the model (not saved)."}})},
               {"overwrite",
                Json::object({{"type", "boolean"},
                              {"default", false},
                              {"description",
                               "Replace files at the output paths that no earlier bake of this command wrote."}})}})}});
    mark_paths(info.inputSchema, "read", {"model"});
    registry.add(info, [&registry, projectDir](const Json& args) {
        return bake_impostor_command(registry, projectDir, args.is_null() ? Json::object() : args);
    });
}

}  // namespace fa::assets_detail
