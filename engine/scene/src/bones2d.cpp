// 2D bones, skinned sprites and IK: see fa/scene/bones2d.h.
#include "fa/scene/bones2d.h"

#include <algorithm>
#include <cmath>
#include <map>
#include <mutex>

#include "fa/core/det_math.h"
#include "fa/core/image.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/scene/bounds.h"

namespace fa {

// ---------------------------------------------------------------------------------------------------------------- affine --
Affine2 Affine2::operator*(const Affine2& o) const {
    Affine2 r;
    r.a = a * o.a + c * o.b;
    r.b = b * o.a + d * o.b;
    r.c = a * o.c + c * o.d;
    r.d = b * o.c + d * o.d;
    r.tx = a * o.tx + c * o.ty + tx;
    r.ty = b * o.tx + d * o.ty + ty;
    return r;
}

Affine2 Affine2::inverse(bool* invertible) const {
    const float det = determinant();
    if (!(std::fabs(det) > 1e-12f) || !std::isfinite(det)) {
        if (invertible) *invertible = false;
        return Affine2{};
    }
    if (invertible) *invertible = true;
    Affine2 r;
    const float inv = 1.0f / det;
    r.a = d * inv;
    r.b = -b * inv;
    r.c = -c * inv;
    r.d = a * inv;
    r.tx = -(r.a * tx + r.c * ty);
    r.ty = -(r.b * tx + r.d * ty);
    return r;
}

Affine2 Affine2::from_mat4(const Mat4& m) {
    Affine2 r;
    r.a = m.at(0, 0);
    r.b = m.at(0, 1);
    r.c = m.at(1, 0);
    r.d = m.at(1, 1);
    r.tx = m.at(3, 0);
    r.ty = m.at(3, 1);
    return r;
}

namespace {

Affine2 world_affine(const World& w, Entity e) { return Affine2::from_mat4(w.world_matrix(e)); }

// ---------------------------------------------------------------------------------------------------------- name lookup --
bool has_bone(const World& w, Entity e) { return w.alive(e) && w.has<Bone2D>(e); }

// A name path under `root` (segments split on '/'). A single name matches a bone at any depth (the first in depth-first order);
// a longer path names direct children one after the other.
Entity find_bone_path(const World& w, Entity root, const std::vector<std::string>& seg, std::size_t i) {
    for (Entity c : w.children(root)) {
        if (w.info(c).name != seg[i]) continue;
        if (i + 1 == seg.size()) {
            if (has_bone(w, c)) return c;
        } else if (Entity r = find_bone_path(w, c, seg, i + 1); !r.is_null()) {
            return r;
        }
    }
    return kNullEntity;
}

Entity find_bone_named(const World& w, Entity root, const std::string& name) {
    for (Entity c : w.children(root)) {
        if (w.info(c).name == name && has_bone(w, c)) return c;
        if (Entity r = find_bone_named(w, c, name); !r.is_null()) return r;
    }
    return kNullEntity;
}

std::string label_of(const World& w, Entity e) {
    const EntityInfo& i = w.info(e);
    return i.name.empty() ? i.id : i.name;
}

// ------------------------------------------------------------------------------------------------------ angle utilities --
// An angle in degrees in (-180, 180]. fmod is exact, so this is the same bits everywhere.
float wrap180(float a) {
    a = std::fmod(a, 360.0f);
    if (a > 180.0f) a -= 360.0f;
    else if (a <= -180.0f) a += 360.0f;
    return a;
}

float angle_of(Vec2 v) { return degrees(det::atan2(v.y, v.x)); }

float orientation_of(const World& w, Entity parent) {
    if (parent.is_null()) return 1.0f;
    return world_affine(w, parent).determinant() < 0.0f ? -1.0f : 1.0f;
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------------- bones --
BoneSegment bone_world_segment(const World& w, Entity bone) {
    BoneSegment s;
    if (!w.alive(bone)) return s;
    const Affine2 m = world_affine(w, bone);
    const Bone2D* b = w.get<Bone2D>(bone);
    s.origin = m.apply({0, 0});
    s.tip = m.apply({b ? b->length : 0.0f, 0.0f});
    return s;
}

std::array<Vec2, 4> bone_kite(const BoneSegment& s) {
    const Vec2 v = s.tip - s.origin;
    const float len = length(v);
    if (len < 1e-6f) return {s.origin, s.origin, s.origin, s.origin};
    const Vec2 dir = v / len, n = perp(dir);
    const Vec2 shoulder = s.origin + v * 0.2f;
    return {s.origin, shoulder + n * (len * 0.1f), s.tip, shoulder - n * (len * 0.1f)};
}

float bone_clamp_angle(const Bone2D& bone, float z) {
    const float lo = bone.minAngle, hi = bone.maxAngle;
    if (!(hi - lo < 360.0f)) return z;
    const float mid = (lo + hi) * 0.5f, half = std::max(0.0f, (hi - lo) * 0.5f);
    const float d = std::clamp(wrap180(z - mid), -half, half);
    return mid + d;
}

// ------------------------------------------------------------------------------------------------------------------ skin --
SkinBones skin_resolve_bones(const World& w, Entity owner, const SpriteSkin& skin) {
    SkinBones out;
    if (!skin.bones.is_array()) {
        if (!skin.bones.is_null())
            out.problems.push_back("SpriteSkin.bones must be an array of bone ids or names, e.g. [\"hip\", \"spine\"]; it is " +
                                   std::string(skin.bones.type_name()) + ".");
        return out;
    }
    std::vector<std::string> candidates;
    bool candidatesBuilt = false;
    const std::size_t count = std::min<std::size_t>(skin.bones.size(), std::size_t(kMaxSkinBones));
    if (skin.bones.size() > count)
        out.problems.push_back("SpriteSkin.bones names " + std::to_string(skin.bones.size()) + " bones; a skin uses at most " +
                               std::to_string(kMaxSkinBones) + " and the rest are left out. Split the sprite in two.");
    for (std::size_t i = 0; i < count; ++i) {
        const Json& j = skin.bones[i];
        if (!j.is_string()) {
            out.entities.push_back(kNullEntity);
            out.problems.push_back("SpriteSkin.bones[" + std::to_string(i) + "] must be a string (the id or name of a Bone2D entity); it is " +
                                   std::string(j.type_name()) + ".");
            continue;
        }
        const std::string& want = j.get_ref<const std::string&>();
        Entity found = kNullEntity;
        std::vector<std::string> seg = split(want, '/');
        if (!seg.empty()) {
            for (Entity a = owner; !a.is_null() && found.is_null(); a = w.parent(a))
                found = seg.size() == 1 ? find_bone_named(w, a, want) : find_bone_path(w, a, seg, 0);
        }
        if (found.is_null()) {
            const Entity byId = w.find_by_id(want);
            if (has_bone(w, byId)) found = byId;
        }
        if (found.is_null()) {
            if (!candidatesBuilt) {
                candidatesBuilt = true;
                for (Entity b : w.entities_with(&World::type_of<Bone2D>())) {
                    const EntityInfo& info = w.info(b);
                    for (const std::string& s : {info.name, info.id})
                        if (!s.empty() && std::find(candidates.begin(), candidates.end(), s) == candidates.end()) candidates.push_back(s);
                }
            }
            out.problems.push_back("SpriteSkin.bones[" + std::to_string(i) + "] '" + want + "' matches no Bone2D entity (an id anywhere, or a name or a path of "
                                   "names under '" + label_of(w, owner) + "' or one of its parents), so that bone is left out. " +
                                   (candidates.empty() ? std::string("The scene has no Bone2D yet: add a Bone2D component to the entities of the skeleton.")
                                                       : did_you_mean(want, candidates)));
        }
        out.entities.push_back(found);
    }
    return out;
}

std::vector<Affine2> skin_bind_matrices(const SpriteSkin& skin, std::size_t boneCount) {
    std::vector<Affine2> out;
    if (!skin.bindPose.is_array() || boneCount == 0 || skin.bindPose.size() != boneCount * 6) return {};
    out.reserve(boneCount);
    for (std::size_t i = 0; i < boneCount; ++i) {
        float v[6];
        for (int k = 0; k < 6; ++k) {
            const Json& j = skin.bindPose[i * 6 + std::size_t(k)];
            if (!j.is_number()) return {};
            v[k] = float(j.get<double>());
            if (!std::isfinite(v[k])) return {};
        }
        out.push_back(Affine2{v[0], v[1], v[2], v[3], v[4], v[5]});
    }
    return out;
}

bool skin_is_bound(const World& w, Entity e) {
    const SpriteSkin* skin = w.get<SpriteSkin>(e);
    if (!skin || !skin->bones.is_array() || skin->bones.empty()) return false;
    return !skin_bind_matrices(*skin, std::min<std::size_t>(skin->bones.size(), kMaxSkinBones)).empty();
}

Result<void> skin_bind(World& w, Entity e) {
    SpriteSkin* skin = w.get<SpriteSkin>(e);
    if (!skin) return make_error("Entity '" + label_of(w, e) + "' has no SpriteSkin to bind.", "Add a SpriteSkin component (and a Sprite) to it first.");
    const SkinBones bones = skin_resolve_bones(w, e, *skin);
    if (bones.entities.empty())
        return make_error("SpriteSkin on '" + label_of(w, e) + "' has no bones to bind.", "Set SpriteSkin.bones to the ids or names of the Bone2D entities, e.g. [\"hip\", \"spine\"].");
    for (const std::string& p : bones.problems) return make_error(p, "Fix SpriteSkin.bones, then bind again.");
    bool ok = true;
    const Affine2 inv = world_affine(w, e).inverse(&ok);
    if (!ok)
        return make_error("The sprite '" + label_of(w, e) + "' has a zero scale, so there is no pose to bind against.",
                          "Give the entity (and its parents) a non-zero Transform.scale before binding.");
    Json pose = Json::array();
    for (Entity b : bones.entities) {
        const Affine2 m = inv * world_affine(w, b);
        for (float v : {m.a, m.b, m.c, m.d, m.tx, m.ty}) pose.push_back(double(v));
    }
    skin->bindPose = std::move(pose);
    return {};
}

void bind_pending_skins(World& w) {
    for (Entity e : w.entities_with(&World::type_of<SpriteSkin>())) {
        if (!w.alive(e)) continue;
        const SpriteSkin* skin = w.get<SpriteSkin>(e);
        if (!skin || !skin->bones.is_array() || skin->bones.empty()) continue;
        if (!skin_bind_matrices(*skin, std::min<std::size_t>(skin->bones.size(), kMaxSkinBones)).empty()) continue;
        (void)skin_bind(w, e);
    }
}

namespace {

// ---------------------------------------------------------------------------------------------------- outline tracing --
constexpr int kOutlineAlphaThreshold = 13;  // alpha of 0..255 above which a pixel counts as opaque (about 5%)

struct AlphaPlane {
    int w = 0, h = 0;
    std::vector<std::uint8_t> a;
    std::string problem;
};

struct OutlineCache {
    std::mutex mutex;
    std::map<std::string, std::shared_ptr<const OutlineGrid>> grids;
    std::map<std::string, std::shared_ptr<const AlphaPlane>> planes;
};

OutlineCache& outline_cache() {
    static OutlineCache cache;
    return cache;
}

std::shared_ptr<const AlphaPlane> alpha_plane(OutlineCache& c, const std::string& path) {
    if (auto it = c.planes.find(path); it != c.planes.end()) return it->second;
    auto plane = std::make_shared<AlphaPlane>();
    auto img = load_image(path);
    if (!img.ok()) {
        plane->problem = "the texture '" + path + "' could not be read as an image file (" + img.error().message +
                         "); an outline needs the picture itself (png, jpg, tga or bmp in the project)";
    } else {
        plane->w = img->width;
        plane->h = img->height;
        plane->a.resize(std::size_t(plane->w) * std::size_t(plane->h));
        for (std::size_t i = 0; i < plane->a.size(); ++i) plane->a[i] = img->rgba[i * 4 + 3];
    }
    if (c.planes.size() >= 24) c.planes.clear();
    c.planes[path] = plane;
    return plane;
}

std::string grid_key(const std::string& path, int x, int y, int w, int h, int cols, int rows) {
    return path + "|" + std::to_string(x) + "," + std::to_string(y) + "," + std::to_string(w) + "," + std::to_string(h) + "|" +
           std::to_string(cols) + "x" + std::to_string(rows);
}

}  // namespace

void skin_outline_dimensions(const SkinBox& box, int detail, int& columns, int& rows) {
    detail = std::clamp(detail, 2, 64);
    const float bw = std::fabs(box.x1 - box.x0), bh = std::fabs(box.y1 - box.y0);
    if (!(bw > 1e-6f) || !(bh > 1e-6f)) {
        columns = rows = detail;
        return;
    }
    if (bw >= bh) {
        columns = detail;
        rows = std::clamp(int(std::lround(double(detail) * double(bh) / double(bw))), 1, detail);
    } else {
        rows = detail;
        columns = std::clamp(int(std::lround(double(detail) * double(bw) / double(bh))), 1, detail);
    }
}

std::shared_ptr<const OutlineGrid> sprite_outline_grid(const std::string& texture, Rect region, int columns, int rows) {
    columns = std::max(columns, 1);
    rows = std::max(rows, 1);
    auto full = [&](bool traced, std::string problem) {
        auto g = std::make_shared<OutlineGrid>();
        g->columns = columns;
        g->rows = rows;
        g->keep.assign(std::size_t(columns) * std::size_t(rows), 1);
        g->traced = traced;
        g->problem = std::move(problem);
        return std::shared_ptr<const OutlineGrid>(g);
    };
    if (texture.empty()) return full(true, {});  // a solid colour quad is opaque everywhere
    OutlineCache& cache = outline_cache();
    std::lock_guard<std::mutex> lock(cache.mutex);
    const std::string key = grid_key(texture, int(region.x), int(region.y), int(region.w), int(region.h), columns, rows);
    if (auto it = cache.grids.find(key); it != cache.grids.end()) return it->second;
    const std::shared_ptr<const AlphaPlane> plane = alpha_plane(cache, texture);
    std::shared_ptr<const OutlineGrid> result;
    if (plane->w <= 0 || plane->h <= 0) {
        result = full(false, plane->problem);
    } else {
        int rx = 0, ry = 0, rw = plane->w, rh = plane->h;
        if (region.w > 0 && region.h > 0) {
            rx = std::clamp(int(std::floor(region.x)), 0, plane->w - 1);
            ry = std::clamp(int(std::floor(region.y)), 0, plane->h - 1);
            rw = std::clamp(int(std::ceil(region.x + region.w)) - rx, 1, plane->w - rx);
            rh = std::clamp(int(std::ceil(region.y + region.h)) - ry, 1, plane->h - ry);
        }
        // Integral image of the opaque pixels of the region, so each cell asks one question.
        const std::size_t stride = std::size_t(rw) + 1;
        std::vector<int> sum(stride * (std::size_t(rh) + 1), 0);
        for (int y = 0; y < rh; ++y) {
            int row = 0;
            for (int x = 0; x < rw; ++x) {
                row += plane->a[std::size_t(ry + y) * std::size_t(plane->w) + std::size_t(rx + x)] >= kOutlineAlphaThreshold ? 1 : 0;
                sum[std::size_t(y + 1) * stride + std::size_t(x + 1)] = sum[std::size_t(y) * stride + std::size_t(x + 1)] + row;
            }
        }
        auto g = std::make_shared<OutlineGrid>();
        g->columns = columns;
        g->rows = rows;
        g->traced = true;
        g->keep.assign(std::size_t(columns) * std::size_t(rows), 0);
        int kept = 0;
        for (int r = 0; r < rows; ++r)
            for (int c = 0; c < columns; ++c) {
                // The cell's pixels plus one pixel around, so linear filtering at the edge of a shape is not cut.
                const int x0 = std::max(0, (c * rw) / columns - 1), x1 = std::min(rw, ((c + 1) * rw + columns - 1) / columns + 1);
                const int y0 = std::max(0, (r * rh) / rows - 1), y1 = std::min(rh, ((r + 1) * rh + rows - 1) / rows + 1);
                const int n = sum[std::size_t(y1) * stride + std::size_t(x1)] - sum[std::size_t(y0) * stride + std::size_t(x1)] -
                              sum[std::size_t(y1) * stride + std::size_t(x0)] + sum[std::size_t(y0) * stride + std::size_t(x0)];
                if (n > 0) {
                    g->keep[std::size_t(r) * std::size_t(columns) + std::size_t(c)] = 1;
                    ++kept;
                }
            }
        if (kept == 0) std::fill(g->keep.begin(), g->keep.end(), 1);  // a picture with no opaque pixel: nothing to cut
        result = g;
    }
    if (cache.grids.size() >= 256) cache.grids.clear();
    cache.grids[key] = result;
    return result;
}

void invalidate_sprite_outlines(std::string_view texture) {
    OutlineCache& cache = outline_cache();
    std::lock_guard<std::mutex> lock(cache.mutex);
    if (texture.empty()) {
        cache.grids.clear();
        cache.planes.clear();
        return;
    }
    const std::string path(texture);
    cache.planes.erase(path);
    const std::string prefix = path + "|";
    for (auto it = cache.grids.begin(); it != cache.grids.end();)
        it = it->first.compare(0, prefix.size(), prefix) == 0 ? cache.grids.erase(it) : std::next(it);
}

// ---------------------------------------------------------------------------------------------------------- weights --
std::vector<VertexWeights> auto_skin_weights(const std::vector<Vec2>& vertices, const std::vector<std::pair<Vec2, Vec2>>& segments) {
    std::vector<VertexWeights> out(vertices.size());
    struct Candidate { float weight; int bone; };
    std::vector<Candidate> cand;
    for (std::size_t v = 0; v < vertices.size(); ++v) {
        const Vec2 p = vertices[v];
        cand.clear();
        for (std::size_t i = 0; i < segments.size(); ++i) {
            const Vec2 a = segments[i].first, b = segments[i].second;
            if (!std::isfinite(a.x) || !std::isfinite(a.y) || !std::isfinite(b.x) || !std::isfinite(b.y)) continue;
            const Vec2 ab = b - a;
            const float len2 = dot(ab, ab);
            const float t = len2 > 1e-12f ? std::clamp(dot(p - a, ab) / len2, 0.0f, 1.0f) : 0.0f;
            const Vec2 q = a + ab * t;
            const float d2 = dot(p - q, p - q);
            cand.push_back({1.0f / (d2 + 0.25f), int(i)});
        }
        // Heaviest first; equal weights keep the lower bone index (std::sort is not stable, so the index breaks ties).
        std::sort(cand.begin(), cand.end(), [](const Candidate& x, const Candidate& y) {
            return x.weight != y.weight ? x.weight > y.weight : x.bone < y.bone;
        });
        if (cand.size() > std::size_t(kMaxBonesPerVertex)) cand.resize(std::size_t(kMaxBonesPerVertex));
        float total = 0.0f;
        for (const Candidate& c : cand) total += c.weight;
        if (!(total > 0.0f)) continue;
        VertexWeights& vw = out[v];
        float kept = 0.0f;
        for (const Candidate& c : cand)
            if (c.weight >= total * 0.02f) kept += c.weight;
        for (const Candidate& c : cand) {
            if (c.weight < total * 0.02f) continue;
            vw.bone[std::size_t(vw.count)] = std::uint8_t(c.bone);
            vw.weight[std::size_t(vw.count)] = c.weight / kept;
            ++vw.count;
        }
    }
    return out;
}

namespace {

// One entry of explicit weights: [bone, weight, bone, weight...]. Invalid pairs are skipped; the rest are normalised.
VertexWeights parse_explicit_weights(const Json& entry, std::size_t boneCount) {
    VertexWeights vw;
    if (!entry.is_array()) return vw;
    float total = 0.0f;
    for (std::size_t i = 0; i + 1 < entry.size() && vw.count < kMaxBonesPerVertex; i += 2) {
        if (!entry[i].is_number() || !entry[i + 1].is_number()) continue;
        const double bone = entry[i].get<double>(), weight = entry[i + 1].get<double>();
        if (!(bone >= 0.0) || bone != std::floor(bone) || std::size_t(bone) >= boneCount || !(weight > 0.0) || !std::isfinite(weight)) continue;
        vw.bone[std::size_t(vw.count)] = std::uint8_t(bone);
        vw.weight[std::size_t(vw.count)] = float(weight);
        total += float(weight);
        ++vw.count;
    }
    if (!(total > 0.0f)) {
        vw.count = 0;
        return vw;
    }
    for (int i = 0; i < vw.count; ++i) vw.weight[std::size_t(i)] /= total;
    return vw;
}

// Everything build_skin_mesh and skin_auto_weights share: the grid, its rest vertices and the bones in bind space.
struct SkinSetup {
    int columns = 0, rows = 0;
    std::shared_ptr<const OutlineGrid> outline;
    std::vector<Vec2> rest;               // full grid, after Sprite.vertexOffsets
    std::vector<Affine2> bind;            // per bone (empty when not bound)
    SkinBones bones;
    std::string problem;
};

bool setup_skin(const World& w, Entity e, const Sprite& s, const SkinBox& box, SkinSetup& out, std::string* problem) {
    const SpriteSkin* skin = w.get<SpriteSkin>(e);
    if (!skin) return false;
    if (skin->outline) {
        skin_outline_dimensions(box, skin->outlineDetail, out.columns, out.rows);
        out.outline = sprite_outline_grid(s.texture, s.region, out.columns, out.rows);
        if (!out.outline->traced)
            out.problem = "SpriteSkin.outline on '" + label_of(w, e) + "': " + out.outline->problem + ". The full grid is drawn instead.";
    } else if (!sprite_mesh_grid(s, out.columns, out.rows)) {
        if (problem) {
            *problem = s.meshColumns > 0 && s.meshRows > 0
                           ? "The Sprite '" + label_of(w, e) + "' has meshColumns " + std::to_string(s.meshColumns) + " x meshRows " + std::to_string(s.meshRows) +
                                 ": more than " + std::to_string(kMaxSpriteMeshCells) + " cells (at most " + std::to_string(kMaxSpriteMeshSide) +
                                 " per side), so its SpriteSkin has no mesh and it is drawn as a plain quad. Use fewer cells (8 x 8 is plenty for a limb)."
                           : "SpriteSkin on '" + label_of(w, e) + "' needs a mesh to deform, and the Sprite has none, so it is drawn as a plain quad. Set Sprite.meshColumns "
                             "and Sprite.meshRows (e.g. 6 and 6) or SpriteSkin.outline = true.";
        }
        return false;
    }
    out.bones = skin_resolve_bones(w, e, *skin);
    for (const std::string& p : out.bones.problems) out.problem += (out.problem.empty() ? "" : " ") + p;
    const std::size_t stride = std::size_t(out.columns) + 1;
    out.rest.resize(stride * (std::size_t(out.rows) + 1));
    const std::vector<float> off = sprite_vertex_offsets(s, out.columns, out.rows);
    for (int r = 0; r <= out.rows; ++r)
        for (int c = 0; c <= out.columns; ++c) {
            const float fx = float(c) / float(out.columns), fy = float(r) / float(out.rows);
            const std::size_t i = std::size_t(r) * stride + std::size_t(c);
            Vec2 p{box.x0 + (box.x1 - box.x0) * fx, box.y1 + (box.y0 - box.y1) * fy};
            if (!off.empty()) {
                p.x += off[i * 2];
                p.y += off[i * 2 + 1];
            }
            out.rest[i] = p;
        }
    out.bind = skin_bind_matrices(*skin, out.bones.entities.size());
    return true;
}

// Weights of the used vertices: the explicit ones of the component, or the automatic ones from the bind pose.
std::vector<VertexWeights> weights_of_vertices(const World& w, Entity e, const SpriteSkin& skin, const SkinSetup& setup,
                                               const std::vector<std::size_t>& gridIndex, std::string& problem) {
    const std::size_t boneCount = setup.bones.entities.size();
    if (skin.weights.is_array()) {
        std::vector<VertexWeights> out(gridIndex.size());
        for (std::size_t i = 0; i < gridIndex.size(); ++i)
            if (gridIndex[i] < skin.weights.size()) out[i] = parse_explicit_weights(skin.weights[gridIndex[i]], boneCount);
        return out;
    }
    if (!(skin.weights.is_string() && skin.weights.get_ref<const std::string&>() == "auto") && !skin.weights.is_null()) {
        problem += (problem.empty() ? "" : " ") + std::string("SpriteSkin.weights on '") + label_of(w, e) +
                   "' must be \"auto\" or an array with one [bone, weight, ...] entry per grid vertex; \"auto\" is used.";
    }
    std::vector<std::pair<Vec2, Vec2>> segs(boneCount, {Vec2{NAN, NAN}, Vec2{NAN, NAN}});
    for (std::size_t i = 0; i < boneCount; ++i) {
        const Bone2D* b = w.get<Bone2D>(setup.bones.entities[i]);
        if (!b || i >= setup.bind.size()) continue;
        segs[i] = {setup.bind[i].apply({0, 0}), setup.bind[i].apply({b->length, 0})};
    }
    std::vector<Vec2> pts(gridIndex.size());
    for (std::size_t i = 0; i < gridIndex.size(); ++i) pts[i] = setup.rest[gridIndex[i]];
    return auto_skin_weights(pts, segs);
}

}  // namespace

bool build_skin_mesh(const World& w, Entity e, const Sprite& s, const SkinBox& box, SkinMesh& out, std::string* problem) {
    out = {};
    if (problem) problem->clear();
    SkinSetup setup;
    if (!setup_skin(w, e, s, box, setup, problem)) return false;
    const SpriteSkin& skin = *w.get<SpriteSkin>(e);
    out.columns = setup.columns;
    out.rows = setup.rows;

    // The cells that are drawn, and which grid vertices they use.
    const std::size_t stride = std::size_t(setup.columns) + 1;
    std::vector<std::int32_t> remap(setup.rest.size(), -1);
    std::vector<std::size_t> gridIndex;
    std::vector<std::array<std::uint32_t, 4>> cells;
    for (int r = 0; r < setup.rows; ++r)
        for (int c = 0; c < setup.columns; ++c) {
            if (setup.outline && !setup.outline->keep[std::size_t(r) * std::size_t(setup.columns) + std::size_t(c)]) continue;
            const std::size_t corner[4] = {std::size_t(r) * stride + std::size_t(c), std::size_t(r + 1) * stride + std::size_t(c),
                                           std::size_t(r + 1) * stride + std::size_t(c + 1), std::size_t(r) * stride + std::size_t(c + 1)};
            std::array<std::uint32_t, 4> cell{};
            for (int k = 0; k < 4; ++k) {
                if (remap[corner[k]] < 0) {
                    remap[corner[k]] = std::int32_t(gridIndex.size());
                    gridIndex.push_back(corner[k]);
                }
                cell[std::size_t(k)] = std::uint32_t(remap[corner[k]]);
            }
            cells.push_back(cell);
        }
    out.quads = std::move(cells);
    out.position.resize(gridIndex.size());
    out.uv.resize(gridIndex.size());
    for (std::size_t i = 0; i < gridIndex.size(); ++i) {
        const std::size_t g = gridIndex[i];
        out.position[i] = setup.rest[g];
        out.uv[i] = {float(g % stride) / float(setup.columns), float(g / stride) / float(setup.rows)};
    }

    std::string note = setup.problem;
    // Deform. Not bound yet (or no bones): the mesh stays at its rest place.
    const std::size_t boneCount = setup.bones.entities.size();
    if (boneCount > 0 && setup.bind.size() == boneCount) {
        bool sInvertible = true;
        const Affine2 sprInv = world_affine(w, e).inverse(&sInvertible);
        std::vector<Affine2> k(boneCount);
        bool moved = false;
        if (sInvertible) {
            for (std::size_t i = 0; i < boneCount; ++i) {
                if (!has_bone(w, setup.bones.entities[i])) continue;
                bool ok = true;
                const Affine2 inv = setup.bind[i].inverse(&ok);
                if (!ok) continue;
                k[i] = sprInv * world_affine(w, setup.bones.entities[i]) * inv;
                moved = moved || !(k[i] == Affine2{});
            }
        }
        if (moved) {
            const std::vector<VertexWeights> weights = weights_of_vertices(w, e, skin, setup, gridIndex, note);
            for (std::size_t v = 0; v < out.position.size(); ++v) {
                const VertexWeights& vw = weights[v];
                if (vw.count == 0) continue;
                const Vec2 p = out.position[v];
                Vec2 acc{0, 0};
                for (int j = 0; j < vw.count; ++j) acc += k[vw.bone[std::size_t(j)]].apply(p) * vw.weight[std::size_t(j)];
                out.position[v] = acc;
            }
        }
    }
    if (problem) *problem = note;
    return true;
}

Result<Json> skin_auto_weights(const World& w, Entity e, const SkinBox& box) {
    const Sprite* s = w.get<Sprite>(e);
    if (!s || !w.has<SpriteSkin>(e))
        return make_error("Entity '" + label_of(w, e) + "' needs a Sprite and a SpriteSkin to have weights.", "Add both components, then set Sprite.meshColumns / meshRows.");
    SkinSetup setup;
    std::string problem;
    if (!setup_skin(w, e, *s, box, setup, &problem)) return make_error(problem.empty() ? "The skin has no mesh." : problem);
    if (setup.bones.entities.empty()) return make_error("SpriteSkin on '" + label_of(w, e) + "' has no bones.", "Set SpriteSkin.bones first.");
    if (setup.bind.size() != setup.bones.entities.size())
        return make_error("SpriteSkin on '" + label_of(w, e) + "' is not bound yet, and automatic weights are measured from the bind pose.",
                          "Let the engine bind it (it does when the scene loads), or call skin_bind.");
    std::vector<std::size_t> all(setup.rest.size());
    for (std::size_t i = 0; i < all.size(); ++i) all[i] = i;
    SpriteSkin autoSkin = *w.get<SpriteSkin>(e);
    autoSkin.weights = Json("auto");
    std::string ignored;
    const std::vector<VertexWeights> weights = weights_of_vertices(w, e, autoSkin, setup, all, ignored);
    Json out = Json::array();
    for (const VertexWeights& vw : weights) {
        Json entry = Json::array();
        for (int j = 0; j < vw.count; ++j) {
            entry.push_back(int(vw.bone[std::size_t(j)]));
            entry.push_back(double(vw.weight[std::size_t(j)]));
        }
        out.push_back(std::move(entry));
    }
    return out;
}

// -------------------------------------------------------------------------------------------------------------------- IK --
namespace {

Vec2 bone_origin(const World& w, Entity b) { return world_affine(w, b).apply({0, 0}); }
Vec2 bone_tip(const World& w, Entity b) { return bone_world_segment(w, b).tip; }

float rotation_z(const World& w, Entity b) { return w.get<Transform>(b)->rotation.z; }
void set_rotation_z(World& w, Entity b, float z) { w.get<Transform>(b)->rotation.z = z; }

// Turns `bone` by `worldDelta` degrees as seen in the world, then keeps it inside its limits.
void turn_bone(World& w, Entity bone, float worldDelta) {
    const float o = orientation_of(w, w.parent(bone));
    set_rotation_z(w, bone, bone_clamp_angle(*w.get<Bone2D>(bone), rotation_z(w, bone) + worldDelta * o));
}

void solve_two_bone(World& w, Entity tip, Entity upper, const IK2D& ik, Vec2 target) {
    const Vec2 o = bone_origin(w, upper), j = bone_origin(w, tip), e = bone_tip(w, tip);
    const float l1 = length(j - o), l2 = length(e - j);
    if (l1 < 1e-4f || l2 < 1e-4f) return;
    const float d = length(target - o);
    const float dc = std::clamp(d, std::max(std::fabs(l1 - l2), 1e-4f), l1 + l2);
    const float cosA = std::clamp((l1 * l1 + dc * dc - l2 * l2) / (2.0f * l1 * dc), -1.0f, 1.0f);
    const float alpha = degrees(det::acos(cosA));
    const float phi = d > 1e-5f ? angle_of(target - o) : angle_of(j - o);
    const Vec2 reach = o + from_angle_deg(phi) * dc;
    // The joint sits on the clockwise side of the line origin -> target when the lower bone turns counter-clockwise.
    float bend = ik.bend == IKBend::Positive ? 1.0f : -1.0f;
    if (world_affine(w, upper).determinant() < 0.0f) bend = -bend;
    const float dir1 = phi - bend * alpha;
    turn_bone(w, upper, wrap180(dir1 - angle_of(j - o)));
    const Vec2 j2 = bone_origin(w, tip), e2 = bone_tip(w, tip);
    turn_bone(w, tip, wrap180(angle_of(reach - j2) - angle_of(e2 - j2)));
}

void solve_ccd(World& w, const std::vector<Entity>& chain, Vec2 target) {
    // chain[0] is the tip bone, chain.back() the root of the chain.
    for (int sweep = 0; sweep < kIkMaxSweeps; ++sweep) {
        float moved = 0.0f;
        for (Entity bone : chain) {
            const Vec2 o = bone_origin(w, bone), e = bone_tip(w, chain[0]);
            const Vec2 v1 = e - o, v2 = target - o;
            if (length_sq(v1) < 1e-10f || length_sq(v2) < 1e-10f) continue;
            const float delta = wrap180(angle_of(v2) - angle_of(v1));
            const float before = rotation_z(w, bone);
            turn_bone(w, bone, delta);
            moved = std::max(moved, std::fabs(wrap180(rotation_z(w, bone) - before)));
        }
        if (length(target - bone_tip(w, chain[0])) < 0.01f || moved < 1e-4f) break;
    }
}

}  // namespace

Result<float> solve_ik2d(World& w, Entity e) {
    const IK2D* ikp = w.get<IK2D>(e);
    if (!ikp) return make_error("Entity '" + label_of(w, e) + "' has no IK2D.", "Add an IK2D component to the last bone of the chain.");
    const IK2D ik = *ikp;
    if (!w.has<Bone2D>(e))
        return make_error("IK2D on '" + label_of(w, e) + "' needs a Bone2D on the same entity: it is the tip of the chain.",
                          "Add a Bone2D (length = how far the bone reaches along +X) to the entity.");
    if (!w.alive(ik.target))
        return make_error("IK2D on '" + label_of(w, e) + "' has no target to reach.", "Set IK2D.target to the id of an entity, e.g. the foot marker the leg should follow.");
    const bool two = ik.solver == IKSolver::TwoBone;
    const int wanted = two ? 2 : std::max(1, ik.chainLength);
    std::vector<Entity> chain{e};
    while (int(chain.size()) < wanted) {
        const Entity p = w.parent(chain.back());
        if (!has_bone(w, p)) break;
        chain.push_back(p);
    }
    if (two && chain.size() < 2)
        return make_error("IK2D on '" + label_of(w, e) + "' uses the twoBone solver, which turns this bone and its parent, and the parent has no Bone2D.",
                          "Put the IK2D on the lower bone of a two-bone chain (the shin, the forearm) whose parent entity is the upper bone with a Bone2D, "
                          "or use solver ccd for a chain of one or more bones.");
    if (!two && int(chain.size()) < wanted)
        return make_error("IK2D on '" + label_of(w, e) + "' has chainLength " + std::to_string(wanted) + " but only " + std::to_string(chain.size()) +
                              " bone(s) up its parents have a Bone2D.",
                          "Lower chainLength to " + std::to_string(chain.size()) + ", or add the Bone2D components the chain is missing.");
    const Vec2 target = w.world_position(ik.target).xy();

    std::vector<float> before(chain.size());
    for (std::size_t i = 0; i < chain.size(); ++i) before[i] = rotation_z(w, chain[i]);
    if (two) solve_two_bone(w, e, chain[1], ik, target);
    else solve_ccd(w, chain, target);
    const float weight = std::clamp(ik.weight, 0.0f, 1.0f);
    for (std::size_t i = 0; i < chain.size(); ++i) {
        const float solved = rotation_z(w, chain[i]);
        set_rotation_z(w, chain[i], weight >= 1.0f ? solved : before[i] + wrap180(solved - before[i]) * weight);
    }
    return length(target - bone_tip(w, e));
}

void update_ik2d(World& w) {
    for (Entity e : w.entities_with(&World::type_of<IK2D>())) {
        if (!w.alive(e) || !w.active_in_hierarchy(e)) continue;
        IK2D* ik = w.get<IK2D>(e);
        if (!ik || ik->weight <= 0.0f || ik->target.is_null()) continue;
        Result<float> r = solve_ik2d(w, e);
        if (!r.ok() && !ik->warned) {
            ik->warned = true;
            FA_WARN("animation", "{}", r.error().to_string());
        }
    }
}

}  // namespace fa
