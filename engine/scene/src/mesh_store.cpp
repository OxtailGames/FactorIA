#include "fa/scene/mesh_store.h"

#include <algorithm>
#include <atomic>
#include <cmath>
#include <cstring>
#include <format>

#include "fa/core/fs.h"
#include "fa/core/json.h"
#include "fa/core/strings.h"

namespace fa {

namespace {

Error field_error(const char* field, const std::string& what, const std::string& fix) {
    return make_error(std::format("mesh {}: {}", field, what), fix);
}

bool finite_all(const std::vector<float>& v, std::size_t& badAt) {
    for (std::size_t i = 0; i < v.size(); ++i)
        if (!std::isfinite(v[i])) {
            badAt = i;
            return false;
        }
    return true;
}

// Area-weighted smooth normals: vertices shared by several triangles (through the indices) average them. A hard edge
// needs duplicated vertices.
void compute_normals(const std::vector<float>& pos, const std::vector<std::uint32_t>& idx, std::vector<float>& out) {
    const std::size_t n = pos.size() / 3;
    std::vector<Vec3> acc(n);
    auto P = [&](std::uint32_t i) { return Vec3{pos[i * 3], pos[i * 3 + 1], pos[i * 3 + 2]}; };
    for (std::size_t i = 0; i + 2 < idx.size(); i += 3) {
        const Vec3 a = P(idx[i]), b = P(idx[i + 1]), c = P(idx[i + 2]);
        const Vec3 f = cross(b - a, c - a);
        for (std::size_t k = 0; k < 3; ++k) acc[idx[i + k]] = acc[idx[i + k]] + f;
    }
    out.resize(n * 3);
    for (std::size_t i = 0; i < n; ++i) {
        Vec3 v = normalize(acc[i]);
        if (length_sq(v) < 0.5f) v = {0, 1, 0};
        out[i * 3] = v.x; out[i * 3 + 1] = v.y; out[i * 3 + 2] = v.z;
    }
}

// The renderer's rule for glTF files without tangents (assets.cpp, generate_tangents): tangent = direction of growing u,
// bitangent = direction of growing v with v up, handedness w from cross(normal, tangent) . bitangent.
void compute_tangents(const std::vector<float>& pos, const std::vector<float>& nrm, const std::vector<float>& uv,
                      const std::vector<std::uint32_t>& idx, std::vector<float>& out) {
    const std::size_t n = pos.size() / 3;
    std::vector<Vec3> tan(n), bit(n);
    auto P = [&](std::uint32_t i) { return Vec3{pos[i * 3], pos[i * 3 + 1], pos[i * 3 + 2]}; };
    for (std::size_t i = 0; i + 2 < idx.size(); i += 3) {
        const std::uint32_t ia = idx[i], ib = idx[i + 1], ic = idx[i + 2];
        const Vec3 e1 = P(ib) - P(ia), e2 = P(ic) - P(ia);
        const float du1 = uv[ib * 2] - uv[ia * 2], du2 = uv[ic * 2] - uv[ia * 2];
        const float dv1 = uv[ia * 2 + 1] - uv[ib * 2 + 1], dv2 = uv[ia * 2 + 1] - uv[ic * 2 + 1];  // v up
        const float det = du1 * dv2 - du2 * dv1;
        if (std::fabs(det) < 1e-12f) continue;
        const float r = 1.0f / det;
        const Vec3 t = (e1 * dv2 - e2 * dv1) * r;
        const Vec3 bt = (e2 * du1 - e1 * du2) * r;
        for (std::uint32_t k : {ia, ib, ic}) { tan[k] = tan[k] + t; bit[k] = bit[k] + bt; }
    }
    out.resize(n * 4);
    for (std::size_t i = 0; i < n; ++i) {
        const Vec3 nv = normalize(Vec3{nrm[i * 3], nrm[i * 3 + 1], nrm[i * 3 + 2]});
        const float tl = length(tan[i]);
        Vec3 t = tl > 0.0f ? tan[i] / tl : Vec3{};
        t = t - nv * dot(nv, t);
        if (length(t) < 1e-3f) t = std::fabs(nv.y) < 0.9f ? cross(Vec3{0, 1, 0}, nv) : cross(Vec3{1, 0, 0}, nv);
        t = normalize(t);
        out[i * 4] = t.x; out[i * 4 + 1] = t.y; out[i * 4 + 2] = t.z;
        out[i * 4 + 3] = dot(cross(nv, t), bit[i]) < 0.0f ? -1.0f : 1.0f;
    }
}

}  // namespace

Result<MeshData> build_mesh_data(const MeshInput& in, const MeshData* base) {
    MeshData d;
    std::size_t bad = 0;

    // ---- positions
    d.positions = !in.positions.empty() ? in.positions : (base ? base->positions : std::vector<float>{});
    if (d.positions.empty())
        return field_error("positions", "is empty", "Pass `positions` as a flat list [x, y, z, x, y, z, ...] (or a list of [x, y, z]), three numbers per vertex.");
    if (d.positions.size() % 3 != 0)
        return field_error("positions", std::format("has {} numbers, which is not a multiple of 3", d.positions.size()),
                           "Give three numbers (x, y, z) per vertex.");
    if (!finite_all(d.positions, bad))
        return field_error("positions", std::format("number {} (vertex {}, axis {}) is NaN or infinite", bad, bad / 3, "xyz"[bad % 3]),
                           "Check the arithmetic that produced it (a division by zero, an uninitialised value).");
    const std::size_t n = d.positions.size() / 3;
    if (n > kMaxProceduralVertices)
        return field_error("positions", std::format("{} vertices exceed the limit of {} per mesh", n, kMaxProceduralVertices),
                           "Split the mesh in several meshes (several entities), or use fewer vertices.");

    auto check_count = [&](const char* name, const std::vector<float>& v, std::initializer_list<std::size_t> per, bool kept) -> std::optional<Error> {
        if (v.empty()) return std::nullopt;
        for (std::size_t p : per)
            if (v.size() == n * p) return std::nullopt;
        std::string expect;
        for (std::size_t p : per) expect += (expect.empty() ? "" : " or ") + std::to_string(n * p);
        return field_error(name,
                           std::format("has {} numbers but the mesh has {} vertices (expected {}{})", v.size(), n, expect,
                                       kept ? "; these values are kept from the mesh's previous data" : ""),
                           kept ? std::string("Pass `") + name + "` again with the new vertex count, or keep the vertex count."
                                : std::string("Give one entry per vertex, in the order of `positions`."));
    };

    // ---- uvs, colors (kept from the base when not given)
    const bool uvKept = in.uvs.empty() && base && base->hasUvs;
    d.uvs = !in.uvs.empty() ? in.uvs : (uvKept ? base->uvs : std::vector<float>{});
    d.hasUvs = !d.uvs.empty();
    if (auto e = check_count("uvs", d.uvs, {2}, uvKept)) return *e;
    if (d.uvs.empty()) d.uvs.assign(n * 2, 0.0f);
    if (!finite_all(d.uvs, bad)) return field_error("uvs", std::format("number {} is NaN or infinite", bad), "Check the arithmetic that produced it.");

    const bool colKept = in.colors.empty() && base && !base->colors.empty();
    std::vector<float> colors = !in.colors.empty() ? in.colors : (base ? base->colors : std::vector<float>{});
    if (auto e = check_count("colors", colors, {3, 4}, colKept)) return *e;
    if (!colors.empty() && !finite_all(colors, bad)) return field_error("colors", std::format("number {} is NaN or infinite", bad), "Check the arithmetic that produced it.");
    if (colors.size() == n * 3 && n > 0 && !(colKept)) {  // rgb -> rgba
        std::vector<float> rgba(n * 4);
        for (std::size_t i = 0; i < n; ++i) {
            rgba[i * 4] = colors[i * 3]; rgba[i * 4 + 1] = colors[i * 3 + 1]; rgba[i * 4 + 2] = colors[i * 3 + 2]; rgba[i * 4 + 3] = 1.0f;
        }
        colors = std::move(rgba);
    }
    d.colors = std::move(colors);

    // ---- indices
    if (!in.indices.empty() || in.hasIndices) d.indices = in.indices;
    else if (base) d.indices = base->indices;
    else {
        d.indices.resize(n);
        for (std::size_t i = 0; i < n; ++i) d.indices[i] = std::uint32_t(i);
    }
    if (d.indices.empty())
        return field_error("indices", "is empty", "List the triangles as vertex numbers, three per triangle: [0, 1, 2, 0, 2, 3]. Leave `indices` out for a triangle soup (vertices 0,1,2 are the first triangle).");
    if (d.indices.size() % 3 != 0)
        return field_error("indices", std::format("has {} entries, which is not a multiple of 3", d.indices.size()),
                           "Each triangle needs exactly three vertex numbers.");
    if (d.indices.size() > kMaxProceduralIndices)
        return field_error("indices", std::format("{} indices exceed the limit of {} per mesh", d.indices.size(), kMaxProceduralIndices),
                           "Split the mesh in several meshes.");
    for (std::size_t i = 0; i < d.indices.size(); ++i)
        if (d.indices[i] >= n)
            return field_error("indices", std::format("entry {} (triangle {}) is {} but the mesh has {} vertices (valid: 0..{})", i, i / 3,
                                                      d.indices[i], n, n - 1),
                               "Every index must be a vertex number of `positions`; check the vertex count of this call, or pass `positions` too.");

    // ---- submeshes
    const std::uint32_t total = std::uint32_t(d.indices.size());
    if (!in.submeshes.empty()) d.submeshes = in.submeshes;
    else if (base && base->submeshes.size() == 1 && in.indices.empty() && !in.hasIndices && base->indices.size() == d.indices.size()) d.submeshes = base->submeshes;
    else if (base && base->submeshes.size() == 1) {  // a new index list and one submesh before: it keeps its material and covers the new list
        d.submeshes = base->submeshes;
        d.submeshes[0].start = 0;
        d.submeshes[0].count = total;
    } else if (base && base->submeshes.size() > 1 && (in.hasIndices || !in.indices.empty()))
        return field_error("submeshes", std::format("the mesh has {} submeshes but this call changes `indices` without `submeshes`, so their ranges may no longer fit", base->submeshes.size()),
                           "Pass `submeshes` ([{material, start, count}], start and count in indices) together with the new `indices`.");
    else if (base) d.submeshes = base->submeshes;
    else d.submeshes.push_back(MeshSubmesh{{}, 0, total});
    for (std::size_t s = 0; s < d.submeshes.size(); ++s) {
        MeshSubmesh& sm = d.submeshes[s];
        if (sm.count == kSubmeshToEnd && sm.start <= total) sm.count = total - sm.start;  // "the rest of the index list"
        const std::string at = std::format("submeshes[{}]", s);
        if (sm.count == 0)
            return field_error(at.c_str(), "has count 0", "A submesh draws at least one triangle: count is a number of indices, a multiple of 3.");
        if (sm.start % 3 != 0 || sm.count % 3 != 0)
            return field_error(at.c_str(), std::format("start {} and count {} must be multiples of 3 (they count indices, three per triangle)", sm.start, sm.count),
                               "Use start = 3 * firstTriangle and count = 3 * triangleCount.");
        if (std::uint64_t(sm.start) + sm.count > total)
            return field_error(at.c_str(), std::format("range {}..{} ends beyond the {} indices of the mesh", sm.start, std::uint64_t(sm.start) + sm.count, total),
                               "start + count must not exceed the length of `indices`.");
        const MeshMaterial& m = sm.material;
        if (!std::isfinite(m.color.r + m.color.g + m.color.b + m.color.a))
            return field_error(at.c_str(), "material color is NaN or infinite", "Give the color as [r, g, b, a] numbers in 0..1.");
        if ((m.metallic && !std::isfinite(*m.metallic)) || (m.roughness && !std::isfinite(*m.roughness)))
            return field_error(at.c_str(), "material metallic or roughness is NaN or infinite", "Give numbers in 0..1.");
    }

    // ---- normals, tangents
    if (!in.normals.empty()) {
        d.normals = in.normals;
        if (auto e = check_count("normals", d.normals, {3}, false)) return *e;
        if (!finite_all(d.normals, bad)) return field_error("normals", std::format("number {} is NaN or infinite", bad), "Check the arithmetic that produced it.");
        for (std::size_t i = 0; i < n; ++i) {
            Vec3 v = normalize(Vec3{d.normals[i * 3], d.normals[i * 3 + 1], d.normals[i * 3 + 2]});
            if (length_sq(v) < 0.5f) v = {0, 1, 0};
            d.normals[i * 3] = v.x; d.normals[i * 3 + 1] = v.y; d.normals[i * 3 + 2] = v.z;
        }
    } else {
        compute_normals(d.positions, d.indices, d.normals);
    }
    if (!in.tangents.empty()) {
        if (auto e = check_count("tangents", in.tangents, {3, 4}, false)) return *e;
        if (!finite_all(in.tangents, bad)) return field_error("tangents", std::format("number {} is NaN or infinite", bad), "Check the arithmetic that produced it.");
        const std::size_t per = in.tangents.size() / n;
        d.tangents.resize(n * 4);
        for (std::size_t i = 0; i < n; ++i) {
            d.tangents[i * 4] = in.tangents[i * per]; d.tangents[i * 4 + 1] = in.tangents[i * per + 1]; d.tangents[i * 4 + 2] = in.tangents[i * per + 2];
            d.tangents[i * 4 + 3] = per == 4 && in.tangents[i * 4 + 3] < 0.0f ? -1.0f : 1.0f;
        }
    } else {
        compute_tangents(d.positions, d.normals, d.uvs, d.indices, d.tangents);
    }

    // ---- bounds
    d.bmin = d.bmax = {d.positions[0], d.positions[1], d.positions[2]};
    for (std::size_t i = 1; i < n; ++i) {
        const Vec3 p{d.positions[i * 3], d.positions[i * 3 + 1], d.positions[i * 3 + 2]};
        d.bmin = min(d.bmin, p);
        d.bmax = max(d.bmax, p);
    }
    return d;
}

// ---------------------------------------------------------------------------------------------------- MeshStore

MeshStore::MeshStore() {
    static std::atomic<std::uint64_t> counter{0};
    serial_ = ++counter;
}

bool MeshStore::is_id(std::string_view s) {
    if (s.size() <= 5 || s.substr(0, 5) != "mesh:") return false;
    return std::all_of(s.begin() + 5, s.end(), [](char c) { return c >= '0' && c <= '9'; });
}

Result<std::string> MeshStore::create(const MeshInput& in) {
    if (entries_.size() >= kMaxProceduralMeshes)
        return make_error(std::format("cannot create another procedural mesh: {} are alive in this scene (the limit)", entries_.size()),
                          "Destroy the ones you no longer use with mesh.destroy(id), or update an existing mesh instead of making a new one.");
    auto data = build_mesh_data(in, nullptr);
    if (!data) return data.error();
    auto e = std::make_unique<Entry>();
    e->id = "mesh:" + std::to_string(next_++);
    e->data = std::move(*data);
    const std::string id = e->id;
    entries_[id] = std::move(e);
    return id;
}

Result<const MeshStore::Entry*> MeshStore::get(const std::string& id) const {
    if (const Entry* e = find(id)) return e;
    std::vector<std::string> live = ids();
    if (!is_id(id))
        return make_error(std::format("'{}' is not a procedural mesh id", id),
                          "Procedural mesh ids look like \"mesh:3\" and come from mesh.create(); built-in shapes and .glb files are not procedural meshes.");
    return make_error(std::format("procedural mesh '{}' does not exist (any more)", id),
                      live.empty() ? "It was destroyed with mesh.destroy(), or the scene it belonged to was unloaded (a scene load releases every procedural mesh). "
                                     "Create it again with mesh.create() in the scene that uses it, and check that the scene is still the current one before using an id kept across a wait."
                                   : "It was destroyed with mesh.destroy(), or the scene it belonged to was unloaded. " + did_you_mean(id, live));
}

Result<void> MeshStore::update(const std::string& id, const MeshInput& in) {
    auto got = get(id);
    if (!got) return got.error();
    Entry* e = entries_.find(id)->second.get();
    auto data = build_mesh_data(in, &e->data);
    if (!data) return data.error();
    e->data = std::move(*data);
    ++e->version;
    return {};
}

Result<void> MeshStore::destroy(const std::string& id) {
    auto got = get(id);
    if (!got) return got.error();
    entries_.erase(id);
    return {};
}

const MeshStore::Entry* MeshStore::find(const std::string& id) const {
    auto it = entries_.find(id);
    return it == entries_.end() ? nullptr : it->second.get();
}

std::vector<std::string> MeshStore::ids() const {
    std::vector<std::string> out;
    for (const auto& [k, v] : entries_) out.push_back(k);
    return out;
}

std::shared_ptr<const MeshGeometry> MeshStore::geometry(const std::string& id) {
    auto it = entries_.find(id);
    if (it == entries_.end()) return nullptr;
    Entry& e = *it->second;
    if (!e.geometry || e.geometryVersion != e.version) {
        auto g = std::make_shared<MeshGeometry>();
        g->positions.resize(e.data.vertex_count());
        for (std::size_t i = 0; i < g->positions.size(); ++i)
            g->positions[i] = {e.data.positions[i * 3], e.data.positions[i * 3 + 1], e.data.positions[i * 3 + 2]};
        g->indices = e.data.indices;
        g->bmin = e.data.bmin;
        g->bmax = e.data.bmax;
        e.geometry = std::move(g);
        e.geometryVersion = e.version;
    }
    return e.geometry;
}

std::shared_ptr<const MeshGeometry> mesh_geometry_for(MeshStore& store, const std::string& mesh, std::string* error) {
    if (MeshStore::is_id(mesh)) {
        auto g = store.geometry(mesh);
        if (!g && error) *error = store.get(mesh).error().to_string();
        return g;
    }
    auto r = load_mesh_geometry(mesh);
    if (!r) {
        if (error) *error = r.error().to_string();
        return nullptr;
    }
    return *r;
}

bool ray_hits_mesh(const MeshGeometry& g, Vec3 o, Vec3 d, float& tOut) {
    bool hit = false;
    float best = 1e30f;
    for (std::size_t i = 0; i + 2 < g.indices.size(); i += 3) {
        const Vec3 a = g.positions[g.indices[i]], b = g.positions[g.indices[i + 1]], c = g.positions[g.indices[i + 2]];
        const Vec3 e1 = b - a, e2 = c - a;
        const Vec3 p = cross(d, e2);
        const float det = dot(e1, p);
        if (std::fabs(det) < 1e-12f) continue;
        const float inv = 1.0f / det;
        const Vec3 tv = o - a;
        const float u = dot(tv, p) * inv;
        if (u < 0.0f || u > 1.0f) continue;
        const Vec3 q = cross(tv, e1);
        const float v = dot(d, q) * inv;
        if (v < 0.0f || u + v > 1.0f) continue;
        const float t = dot(e2, q) * inv;
        if (t >= 0.0f && t < best) {
            best = t;
            hit = true;
        }
    }
    if (hit) tOut = best;
    return hit;
}

// ------------------------------------------------------------------------------------------------------ JSON form

namespace {

// A list of numbers: flat, or a list of [..] / {x, y, z, w} entries of `per` numbers (`perMax` > per: either count).
Result<std::vector<float>> numbers_from_json(const Json& j, const char* field, std::size_t per, std::size_t perMax) {
    std::vector<float> out;
    if (!j.is_array())
        return field_error(field, "must be a list of numbers, e.g. [x, y, z, x, y, z] or [[x, y, z], [x, y, z]], but got " + describe_json_value(j),
                           "Pass an array (a typed array in a script is converted for you).");
    out.reserve(j.size() * per);
    for (std::size_t i = 0; i < j.size(); ++i) {
        const Json& e = j[i];
        if (e.is_number()) {
            out.push_back(e.get<float>());
        } else if (e.is_array() || e.is_object()) {
            std::vector<float> row;
            if (e.is_array()) {
                for (const Json& n : e) {
                    if (!n.is_number())
                        return field_error(field, std::format("entry {} contains {}, not a number", i, describe_json_value(n)), "Every entry is a list of numbers.");
                    row.push_back(n.get<float>());
                }
            } else {
                for (const char* k : {"x", "y", "z", "w"}) {
                    auto it = e.find(k);
                    if (it == e.end()) break;
                    if (!it->is_number())
                        return field_error(field, std::format("entry {} has {} for `{}`, not a number", i, describe_json_value(*it), k), "Use numbers.");
                    row.push_back(it->get<float>());
                }
            }
            if (row.size() < per || row.size() > perMax)
                return field_error(field, std::format("entry {} has {} numbers, expected {}", i, row.size(), per == perMax ? std::to_string(per) : std::format("{} or {}", per, perMax)),
                                   "Give the same count in every entry.");
            out.insert(out.end(), row.begin(), row.end());
        } else {
            return field_error(field, std::format("entry {} is {}, not a number or a list of numbers", i, describe_json_value(e)), "Use numbers.");
        }
    }
    return out;
}

}  // namespace

Result<MeshMaterial> mesh_material_from_json(const Json& j, const std::string& where) {
    MeshMaterial m;
    if (j.is_null()) return m;
    if (j.is_string()) {
        m.name = j.get<std::string>();
        return m;
    }
    if (!j.is_object())
        return make_error(where + ": material must be a name (a string) or an object { name, color, texture, metallic, roughness, emissive, doubleSided, blend }, but got " + describe_json_value(j),
                          "Example: { name: \"skin\", color: [0.9, 0.7, 0.5, 1], roughness: 0.8 }.");
    static const std::vector<std::string> known = {"name", "color", "texture", "metallic", "roughness", "emissive", "doubleSided", "blend"};
    for (auto it = j.begin(); it != j.end(); ++it)
        if (std::find(known.begin(), known.end(), it.key()) == known.end())
            return make_error(std::format("{}: unknown material field '{}'", where, it.key()), did_you_mean(it.key(), known) + " Fields: name, color, texture, metallic, roughness, emissive, doubleSided, blend.");
    std::string err;
    auto get = [&](const char* k, auto& out) -> std::optional<Error> {
        auto it = j.find(k);
        if (it == j.end() || it->is_null()) return std::nullopt;
        if (!json_to(*it, out, &err)) return make_error(std::format("{}: material `{}`: {}", where, k, err), "See the field list in the mesh docs (docs/SCRIPTING.md, \"Procedural meshes\").");
        return std::nullopt;
    };
    if (auto e = get("name", m.name)) return *e;
    if (auto e = get("color", m.color)) return *e;
    if (auto e = get("texture", m.texture)) return *e;
    float v = 0;
    if (j.contains("metallic") && !j["metallic"].is_null()) { if (auto e = get("metallic", v)) return *e; m.metallic = v; }
    if (j.contains("roughness") && !j["roughness"].is_null()) { if (auto e = get("roughness", v)) return *e; m.roughness = v; }
    if (auto e = get("emissive", m.emissive)) return *e;
    if (auto e = get("doubleSided", m.doubleSided)) return *e;
    if (auto e = get("blend", m.blend)) return *e;
    return m;
}

Result<MeshInput> mesh_input_from_json(const Json& args) {
    MeshInput in;
    if (!args.is_object())
        return make_error("mesh arguments must be an object { positions, indices, ... }, but got " + describe_json_value(args),
                          "Example: { positions: [0,0,0, 1,0,0, 0,1,0], indices: [0, 1, 2] }.");
    static const std::vector<std::string> known = {"positions", "normals", "uvs", "tangents", "colors", "indices", "submeshes", "id", "path"};
    for (auto it = args.begin(); it != args.end(); ++it)
        if (std::find(known.begin(), known.end(), it.key()) == known.end())
            return make_error(std::format("mesh: unknown field '{}'", it.key()), did_you_mean(it.key(), known) + " Fields: positions, normals, uvs, tangents, colors, indices, submeshes.");
    struct F { const char* name; std::vector<float>* out; std::size_t per, perMax; };
    for (const F& f : {F{"positions", &in.positions, 3, 3}, F{"normals", &in.normals, 3, 3}, F{"uvs", &in.uvs, 2, 2},
                       F{"tangents", &in.tangents, 3, 4}, F{"colors", &in.colors, 3, 4}}) {
        auto it = args.find(f.name);
        if (it == args.end() || it->is_null()) continue;
        auto r = numbers_from_json(*it, f.name, f.per, f.perMax);
        if (!r) return r.error();
        *f.out = std::move(*r);
        if (f.out->empty())
            return field_error(f.name, "is an empty list", std::string("Leave `") + f.name + "` out to not give it.");
    }
    if (auto it = args.find("indices"); it != args.end() && !it->is_null()) {
        auto r = numbers_from_json(*it, "indices", 3, 3);  // flat or [[a, b, c], ...]
        if (!r) return r.error();
        in.hasIndices = true;
        in.indices.reserve(r->size());
        for (std::size_t i = 0; i < r->size(); ++i) {
            const float v = (*r)[i];
            if (!(v >= 0) || v != std::floor(v) || v > 4294967040.0f)
                return field_error("indices", std::format("entry {} is {}, not a vertex number", i, v), "Indices are whole numbers from 0 up, the position of a vertex in `positions`.");
            in.indices.push_back(std::uint32_t(v));
        }
    }
    if (auto it = args.find("submeshes"); it != args.end() && !it->is_null()) {
        if (!it->is_array() || it->empty())
            return field_error("submeshes", "must be a non-empty list of { material, start, count }, but got " + describe_json_value(*it),
                               "Example: [{ material: \"skin\", start: 0, count: 6 }, { material: \"cloth\", start: 6, count: 12 }].");
        std::uint64_t next = 0;
        for (std::size_t i = 0; i < it->size(); ++i) {
            const Json& s = (*it)[i];
            const std::string at = std::format("submeshes[{}]", i);
            if (!s.is_object())
                return field_error(at.c_str(), "must be an object { material, start, count }, but got " + describe_json_value(s), "");
            for (auto k = s.begin(); k != s.end(); ++k)
                if (k.key() != "material" && k.key() != "start" && k.key() != "count")
                    return field_error(at.c_str(), std::format("unknown field '{}'", k.key()), "Fields: material, start, count.");
            MeshSubmesh sm;
            auto mat = mesh_material_from_json(s.value("material", Json()), "mesh " + at);
            if (!mat) return mat.error();
            sm.material = std::move(*mat);
            auto count_of = [&](const char* key, std::uint64_t fallback) -> Result<std::uint64_t> {
                auto k = s.find(key);
                if (k == s.end() || k->is_null()) return fallback;
                if (!k->is_number() || k->get<double>() < 0 || k->get<double>() != std::floor(k->get<double>()) || k->get<double>() > 4294967000.0)
                    return field_error(at.c_str(), std::format("`{}` must be a whole number of indices (>= 0), but got {}", key, describe_json_value(*k)), "start and count count indices, three per triangle.");
                return std::uint64_t(k->get<double>());
            };
            auto start = count_of("start", next);
            if (!start) return start.error();
            auto count = count_of("count", kSubmeshToEnd);
            if (!count) return count.error();
            sm.start = std::uint32_t(*start);
            sm.count = std::uint32_t(*count);
            next = *count == kSubmeshToEnd ? *start : *start + *count;
            in.submeshes.push_back(std::move(sm));
        }
    }
    return in;
}

Json mesh_info_json(const MeshStore::Entry& e) {
    Json subs = Json::array();
    for (const MeshSubmesh& s : e.data.submeshes) {
        Json m = Json::object();
        m["name"] = s.material.name;
        m["color"] = to_json(s.material.color);
        if (!s.material.texture.empty()) m["texture"] = s.material.texture;
        if (s.material.metallic) m["metallic"] = *s.material.metallic;
        if (s.material.roughness) m["roughness"] = *s.material.roughness;
        if (s.material.emissive.r + s.material.emissive.g + s.material.emissive.b > 0) m["emissive"] = to_json(s.material.emissive);
        if (s.material.doubleSided) m["doubleSided"] = true;
        if (s.material.blend) m["blend"] = true;
        subs.push_back(Json::object({{"material", m}, {"start", s.start}, {"count", s.count}}));
    }
    return Json::object({{"id", e.id},
                         {"version", e.version},
                         {"vertices", e.data.vertex_count()},
                         {"triangles", e.data.triangle_count()},
                         {"hasColors", !e.data.colors.empty()},
                         {"bounds", Json::object({{"min", to_json(e.data.bmin)}, {"max", to_json(e.data.bmax)}})},
                         {"submeshes", subs}});
}

// ------------------------------------------------------------------------------------------------------ .glb

namespace {

// "assets/models/" + "assets/tex/a b.png" -> "../tex/a%20b.png"
std::string relative_uri(const std::string& fromDir, const std::string& target) {
    auto split = [](const std::string& p) {
        std::vector<std::string> out;
        std::size_t i = 0;
        while (i <= p.size()) {
            std::size_t j = p.find('/', i);
            if (j == std::string::npos) j = p.size();
            if (j > i) out.push_back(p.substr(i, j - i));
            i = j + 1;
        }
        return out;
    };
    const auto a = split(fromDir), b = split(target);
    std::size_t common = 0;
    while (common < a.size() && common + 1 < b.size() && a[common] == b[common]) ++common;
    std::string rel;
    for (std::size_t i = common; i < a.size(); ++i) rel += "../";
    for (std::size_t i = common; i < b.size(); ++i) rel += (i > common ? "/" : "") + b[i];
    std::string enc;
    for (char c : rel) {
        const bool plain = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '-' || c == '.' || c == '_' || c == '~' || c == '/';
        if (plain) enc += c;
        else enc += std::format("%{:02X}", static_cast<unsigned char>(c));
    }
    return enc;
}

bool same_material(const MeshMaterial& a, const MeshMaterial& b) {
    return a.name == b.name && a.color == b.color && a.texture == b.texture && a.metallic == b.metallic && a.roughness == b.roughness &&
           a.emissive == b.emissive && a.doubleSided == b.doubleSided && a.blend == b.blend;
}

}  // namespace

Result<std::vector<std::uint8_t>> mesh_to_glb(const MeshData& d, const std::string& glbPath) {
    const std::string dir = fs::parent(glbPath);
    const std::size_t n = d.vertex_count();

    std::vector<std::uint8_t> bin;
    auto append = [&](const void* p, std::size_t bytes) {
        const std::size_t at = bin.size();
        bin.resize(at + bytes);
        std::memcpy(bin.data() + at, p, bytes);
        while (bin.size() % 4 != 0) bin.push_back(0);
        return at;
    };
    Json views = Json::array(), accessors = Json::array();
    auto add_view = [&](const void* p, std::size_t bytes, int target) {
        const std::size_t at = append(p, bytes);
        views.push_back({{"buffer", 0}, {"byteOffset", at}, {"byteLength", bytes}, {"target", target}});
        return int(views.size() - 1);
    };
    auto add_accessor = [&](int view, std::size_t byteOffset, int componentType, std::size_t count, const char* type) {
        Json a = {{"bufferView", view}, {"byteOffset", byteOffset}, {"componentType", componentType}, {"count", count}, {"type", type}};
        accessors.push_back(a);
        return int(accessors.size() - 1);
    };
    Json attributes = Json::object();
    {
        const int v = add_view(d.positions.data(), d.positions.size() * 4, 34962);
        const int a = add_accessor(v, 0, 5126, n, "VEC3");
        accessors[std::size_t(a)]["min"] = Json::array({d.bmin.x, d.bmin.y, d.bmin.z});
        accessors[std::size_t(a)]["max"] = Json::array({d.bmax.x, d.bmax.y, d.bmax.z});
        attributes["POSITION"] = a;
    }
    attributes["NORMAL"] = add_accessor(add_view(d.normals.data(), d.normals.size() * 4, 34962), 0, 5126, n, "VEC3");
    attributes["TEXCOORD_0"] = add_accessor(add_view(d.uvs.data(), d.uvs.size() * 4, 34962), 0, 5126, n, "VEC2");
    attributes["TANGENT"] = add_accessor(add_view(d.tangents.data(), d.tangents.size() * 4, 34962), 0, 5126, n, "VEC4");
    if (!d.colors.empty()) attributes["COLOR_0"] = add_accessor(add_view(d.colors.data(), d.colors.size() * 4, 34962), 0, 5126, n, "VEC4");
    const int indexView = add_view(d.indices.data(), d.indices.size() * 4, 34963);

    Json materials = Json::array(), images = Json::array(), textures = Json::array(), primitives = Json::array();
    std::vector<const MeshMaterial*> seen;
    std::vector<int> seenIndex;
    std::vector<std::string> imagePaths;
    for (const MeshSubmesh& sm : d.submeshes) {
        int mat = -1;
        for (std::size_t i = 0; i < seen.size(); ++i)
            if (same_material(*seen[i], sm.material)) mat = seenIndex[i];
        if (mat < 0) {
            const MeshMaterial& m = sm.material;
            Json pbr = {{"baseColorFactor", Json::array({m.color.r, m.color.g, m.color.b, m.color.a})},
                        {"metallicFactor", m.metallic.value_or(0.0f)},
                        {"roughnessFactor", m.roughness.value_or(0.6f)}};
            if (!m.texture.empty()) {
                if (m.texture.rfind("runtime:", 0) == 0)
                    return make_error(std::format("submesh material '{}' uses the run-time texture '{}', which lives in memory and has no file", m.name, m.texture),
                                      "A saved model can only refer to image files: use a project-relative image path (a PNG in assets/) as the material's texture, or save the mesh without texturing that submesh and texture it again at run time.");
                const std::string path = fs::normalize(m.texture);
                if (path.empty())
                    return make_error(std::format("submesh material '{}' has the texture path '{}', which is outside the project", m.name, m.texture),
                                      "Use a project-relative image path such as \"assets/textures/wood.png\".");
                auto it = std::find(imagePaths.begin(), imagePaths.end(), path);
                if (it == imagePaths.end()) {
                    imagePaths.push_back(path);
                    images.push_back({{"uri", relative_uri(dir, path)}});
                    textures.push_back({{"source", int(images.size() - 1)}});
                    it = imagePaths.end() - 1;
                }
                pbr["baseColorTexture"] = {{"index", int(it - imagePaths.begin())}};
            }
            Json jm = {{"pbrMetallicRoughness", pbr}};
            if (!m.name.empty()) jm["name"] = m.name;
            if (m.emissive.r != 0 || m.emissive.g != 0 || m.emissive.b != 0) jm["emissiveFactor"] = Json::array({m.emissive.r, m.emissive.g, m.emissive.b});
            if (m.blend) jm["alphaMode"] = "BLEND";
            if (m.doubleSided) jm["doubleSided"] = true;
            materials.push_back(jm);
            mat = int(materials.size() - 1);
            seen.push_back(&sm.material);
            seenIndex.push_back(mat);
        }
        const int acc = add_accessor(indexView, std::size_t(sm.start) * 4, 5125, sm.count, "SCALAR");
        primitives.push_back({{"attributes", attributes}, {"indices", acc}, {"material", mat}, {"mode", 4}});
    }

    Json root = {{"asset", {{"version", "2.0"}, {"generator", "FactorIA mesh.save"}}},
                 {"scene", 0},
                 {"scenes", Json::array({{{"nodes", Json::array({0})}}})},
                 {"nodes", Json::array({{{"mesh", 0}, {"name", "mesh"}}})},
                 {"meshes", Json::array({{{"name", "mesh"}, {"primitives", primitives}}})},
                 {"materials", materials},
                 {"buffers", Json::array({{{"byteLength", bin.size()}}})},
                 {"bufferViews", views},
                 {"accessors", accessors}};
    if (!images.empty()) {
        root["images"] = images;
        root["textures"] = textures;
    }
    std::string json = root.dump();
    while (json.size() % 4 != 0) json += ' ';

    std::vector<std::uint8_t> out;
    auto put32 = [&](std::uint32_t v) {
        for (int i = 0; i < 4; ++i) out.push_back(std::uint8_t(v >> (8 * i)));
    };
    put32(0x46546C67);  // "glTF"
    put32(2);
    put32(std::uint32_t(12 + 8 + json.size() + 8 + bin.size()));
    put32(std::uint32_t(json.size()));
    put32(0x4E4F534A);  // "JSON"
    out.insert(out.end(), json.begin(), json.end());
    put32(std::uint32_t(bin.size()));
    put32(0x004E4942);  // "BIN\0"
    out.insert(out.end(), bin.begin(), bin.end());
    return out;
}

Result<std::string> save_mesh_glb(const MeshData& data, const std::string& path) {
    if (path.empty())
        return make_error("mesh.save: `path` is empty", "Pass the project-relative file to write, for example \"assets/models/tree.glb\".");
    auto norm = fs::normalize_checked(path);
    if (!norm) return norm.error();
    if (!ends_with(to_lower(*norm), ".glb"))
        return make_error("mesh.save: '" + *norm + "' does not end in .glb",
                          "Name the file with the .glb extension, for example \"assets/models/tree.glb\"; it loads back as a normal model (MeshRenderer.mesh = \"assets/models/tree.glb\").");
    if (auto w = fs::check_writable(*norm); !w) return w.error();
    auto glb = mesh_to_glb(data, *norm);
    if (!glb) return glb.error();
    if (auto w = fs::write_bytes(*norm, glb->data(), glb->size()); !w) return w.error();
    return *norm;
}

}  // namespace fa
