#include "fa/scene/particles.h"

#include <algorithm>
#include <cmath>
#include <format>

#include "fa/core/det_math.h"
#include "fa/core/fs.h"
#include "fa/core/reflect.h"
#include "fa/core/strings.h"

namespace fa {

namespace {

// The reflection of ParticleEmitter (sub-emitters and prefabs are patched through it), registered if no World made it yet.
const TypeInfo* emitter_type() {
    ensure_builtin_components();
    return TypeRegistry::global().of<ParticleEmitter>();
}

// Smallest speed (world units per second) a bounce must have to count as a hit (collision sub-emitters, lifetime loss); a particle
// that lies on the surface and is pushed down by gravity every step is resting, not hitting.
constexpr float kMinImpactSpeed = 1e-3f;

// The cube root of x in [0, 1] by Newton's method (std::cbrt may differ between C libraries).
float cbrt01(float x) {
    if (!(x > 0.0f)) return 0.0f;
    float y = 1.0f;
    for (int i = 0; i < 12; ++i) y = (2.0f * y + x / (y * y)) * (1.0f / 3.0f);
    return y;
}

float lattice(std::int32_t ix, std::int32_t iy, std::int32_t iz, std::uint32_t seed, std::uint32_t channel) {
    std::uint32_t h = seed ^ (std::uint32_t(ix) * 0x8da6b343u) ^ (std::uint32_t(iy) * 0xd8163841u) ^ (std::uint32_t(iz) * 0xcb1ab31fu) ^
                      (channel * 0x9e3779b9u);
    h ^= h >> 16;
    h *= 0x7feb352du;
    h ^= h >> 15;
    h *= 0x846ca68bu;
    h ^= h >> 16;
    return float(h >> 8) * (2.0f / 16777216.0f) - 1.0f;
}

float fade(float s) { return s * s * (3.0f - 2.0f * s); }

float next_unit(Rng& r) { return r.next_float(); }

std::string pointer_of(const std::string& base, const std::string& key) { return base + "/" + key; }

template <class T>
void check_parse(std::vector<ParticleProblem>& out, const ParticleEmitter&, const Json& value, const char* field, const char* type) {
    (void)type;
    Result<T> r = T::parse(value, std::string("ParticleEmitter.") + field);
    if (!r) out.push_back({true, std::string("/") + field, r.error().message, r.error().hint});
}

const char* kLinkKeys[] = {"count", "emitter", "prefab", "entity", "inherit", "chance"};

// Checks the shape of ParticleEmitter.subEmitters (not what a prefab holds: that is read when the emitter runs).
void check_sub_spec(std::vector<ParticleProblem>& out, const Json& spec, int depth, const std::string& pointer) {
    if (spec.is_null() || (spec.is_object() && spec.empty())) return;
    if (!spec.is_object()) {
        out.push_back({true, pointer, "sub-emitters must be an object, got " + describe_json_value(spec),
                       "Write {\"death\": {\"count\": 6, \"emitter\": {...}}}: the events are birth, death and collision."});
        return;
    }
    if (depth >= kParticleSubDepth) {
        out.push_back({false, pointer, std::format("sub-emitters nested more than {} levels deep are ignored", kParticleSubDepth),
                       "Move the effect up a level, or give the sub-emitter's particles no sub-emitters."});
        return;
    }
    static const std::vector<std::string> events = {"birth", "death", "collision"};
    static const std::vector<std::string> linkKeys(std::begin(kLinkKeys), std::end(kLinkKeys));
    for (auto it = spec.begin(); it != spec.end(); ++it) {
        const std::string ptr = pointer_of(pointer, it.key());
        if (std::find(events.begin(), events.end(), it.key()) == events.end()) {
            out.push_back({true, ptr, "unknown sub-emitter event '" + it.key() + "'", did_you_mean(it.key(), events)});
            continue;
        }
        std::vector<const Json*> links;
        if (it.value().is_object()) links.push_back(&it.value());
        else if (it.value().is_array()) for (const Json& l : it.value()) links.push_back(&l);
        else {
            out.push_back({true, ptr, "expected a sub-emitter object or an array of them, got " + describe_json_value(it.value()),
                           "Example: {\"count\": 4, \"emitter\": {\"lifetime\": 0.3}}"});
            continue;
        }
        std::size_t li = 0;
        for (const Json* l : links) {
            const std::string lp = it.value().is_array() ? ptr + "/" + std::to_string(li) : ptr;
            ++li;
            if (!l->is_object()) {
                out.push_back({true, lp, "a sub-emitter must be an object, got " + describe_json_value(*l), "Example: {\"count\": 4, \"emitter\": {\"lifetime\": 0.3}}"});
                continue;
            }
            for (auto k = l->begin(); k != l->end(); ++k)
                if (std::find(linkKeys.begin(), linkKeys.end(), k.key()) == linkKeys.end())
                    out.push_back({true, pointer_of(lp, k.key()), "unknown sub-emitter key '" + k.key() + "'",
                                   did_you_mean(k.key(), linkKeys)});
            const int given = int(l->contains("emitter")) + int(l->contains("prefab")) + int(l->contains("entity"));
            if (given != 1)
                out.push_back({true, lp, "a sub-emitter names what it emits with exactly one of \"emitter\", \"prefab\" and \"entity\"",
                               "\"emitter\": {...ParticleEmitter fields...} inline, \"prefab\": \"prefabs/x.prefab.json\", or \"entity\": \"<entity id>\"."});
            if (l->contains("emitter")) {
                const Json& e = (*l)["emitter"];
                if (const TypeInfo* ti = emitter_type()) {
                    ParticleEmitter scratch;
                    if (auto r = object_patch_from_json(*ti, &scratch, e); !r)
                        out.push_back({true, pointer_of(lp, "emitter"), r.error().message, r.error().hint});
                    else {
                        if (e.is_object() && e.contains("worldSpace"))
                            out.push_back({false, pointer_of(pointer_of(lp, "emitter"), "worldSpace"),
                                           "a sub-emitter's worldSpace is ignored: its particles live in the space of the emitter that owns them",
                                           "Remove worldSpace here and set it on the emitter that has the subEmitters."});
                        check_sub_spec(out, scratch.subEmitters, depth + 1, pointer_of(pointer_of(lp, "emitter"), "subEmitters"));
                    }
                }
            }
            if (l->contains("prefab") && !(*l)["prefab"].is_string())
                out.push_back({true, pointer_of(lp, "prefab"), "\"prefab\" must be a path string", "Example: \"prefabs/spark.prefab.json\""});
            if (l->contains("entity") && !(*l)["entity"].is_string())
                out.push_back({true, pointer_of(lp, "entity"), "\"entity\" must be an entity id string", "Example: \"spark-emitter\""});
            for (const char* num : {"count", "inherit", "chance"})
                if (l->contains(num) && !(*l)[num].is_number())
                    out.push_back({true, pointer_of(lp, num), std::string("\"") + num + "\" must be a number", ""});
        }
    }
}

}  // namespace

// ---------------------------------------------------------------- checking --

std::vector<ParticleProblem> particle_emitter_problems(const ParticleEmitter& em) {
    std::vector<ParticleProblem> out;
    check_parse<Gradient>(out, em, em.colorGradient, "colorGradient", "gradient");
    check_parse<Gradient>(out, em, em.trailGradient, "trailGradient", "gradient");
    check_parse<Curve>(out, em, em.sizeCurve, "sizeCurve", "curve");
    check_parse<Curve>(out, em, em.speedCurve, "speedCurve", "curve");
    check_parse<Curve>(out, em, em.alphaCurve, "alphaCurve", "curve");
    check_parse<Curve>(out, em, em.trailWidthCurve, "trailWidthCurve", "curve");
    check_sub_spec(out, em.subEmitters, 0, "/subEmitters");

    if (!em.palette.is_array()) {
        out.push_back({true, "/palette", "the palette must be an array of colours, got " + describe_json_value(em.palette),
                       "Example: [\"#1a1c2c\", \"#5d275d\", \"#b13e53\", \"#ef7d57\", \"#ffcd75\"]"});
    } else {
        for (std::size_t i = 0; i < em.palette.size(); ++i) {
            Color c;
            std::string err;
            if (!json_to(em.palette[i], c, &err))
                out.push_back({true, "/palette/" + std::to_string(i), "palette colour " + std::to_string(i) + " does not read: " + err,
                               "Write each colour as \"#rrggbb\", a colour name or [r, g, b, a]."});
        }
    }
    if (em.flipbookColumns < 1 || em.flipbookRows < 1)
        out.push_back({true, "/flipbookColumns", "flipbookColumns and flipbookRows must be at least 1",
                       "A texture that is not a flipbook has 1 column and 1 row."});
    else if (em.flipbookFrames > em.flipbookColumns * em.flipbookRows)
        out.push_back({false, "/flipbookFrames", std::format("flipbookFrames {} is more than the {} cells of the grid; the extra frames are ignored",
                                                           em.flipbookFrames, em.flipbookColumns * em.flipbookRows),
                       "Use 0 for every cell, or at most columns * rows."});
    if ((em.flipbookColumns > 1 || em.flipbookRows > 1) && em.texture.empty())
        out.push_back({false, "/texture", "a flipbook needs a texture (the soft round dot has one frame)",
                       "Set texture to a sheet of frames, or put flipbookColumns and flipbookRows back to 1."});
    if (em.shape == ParticleShape::Mesh && em.shapeMesh.empty())
        out.push_back({false, "/shapeMesh", "shape is \"mesh\" but shapeMesh names no mesh, so particles are born at the point",
                       "Set shapeMesh to a primitive (\"sphere\") or a model path."});
    if (em.collision != ParticleCollision::None && !em.worldSpace)
        out.push_back({false, "/collision", "collision only works with worldSpace: true, so it does nothing here",
                       "Set worldSpace to true."});
    if (em.collision != ParticleCollision::None && em.space == RenderSpace::Screen && !em.is3D)
        out.push_back({false, "/collision", "collision does nothing for a screen-space emitter", "Use a world-space emitter."});
    if (em.collision == ParticleCollision::Plane && length(em.collisionPlane.xyz()) < kEpsilon)
        out.push_back({true, "/collisionPlane", "the plane's normal [nx, ny, nz] is zero, so there is no plane",
                       "Use [0, 1, 0, 0] for the floor y = 0."});
    if (em.trail == ParticleTrail::Emitter && !em.worldSpace)
        out.push_back({false, "/trail", "trail \"emitter\" draws the path the emitter moved along, which only exists with worldSpace: true",
                       "Set worldSpace to true."});
    if (em.noiseStrength != 0.0f && !(em.noiseScale > 0.0f))
        out.push_back({false, "/noiseScale", "noiseScale must be positive for the turbulence to do anything", "Try 64."});
    if (em.pixelMode && !(em.pixelSize > 0.0f))
        out.push_back({false, "/pixelSize", "pixelSize must be positive in pixel mode", "Use 1 for one world unit (one design pixel)."});
    if (em.trail != ParticleTrail::None && !(em.trailTime > 0.0f))
        out.push_back({false, "/trailTime", "trailTime must be positive for a trail to show", "Try 0.5."});
    return out;
}

Result<ParticleEmitter> load_prefab_particle_emitter(const std::string& path) {
    auto text = fs::read_text(path);
    if (!text) return Error{"sub-emitter prefab '" + path + "' cannot be read: " + text.error().message, text.error().hint};
    auto parsed = parse_json(*text, path);
    if (!parsed) return parsed.error();
    const Json& root = *parsed;
    if (!root.is_object() || !root.contains("entity") || !root["entity"].is_object())
        return Error{path + ": not a prefab (no \"entity\" object)", "A prefab file is {\"format\": \"factoria.prefab/1\", \"entity\": {...}}."};
    const TypeInfo* ti = emitter_type();
    if (!ti) return Error{"ParticleEmitter is not registered", ""};
    // Depth first: the entity itself, then its children in order.
    std::vector<const Json*> stack{&root["entity"]};
    while (!stack.empty()) {
        const Json* e = stack.back();
        stack.pop_back();
        if (e->contains("components") && (*e)["components"].is_object() && (*e)["components"].contains("ParticleEmitter")) {
            ParticleEmitter em;
            if (auto r = object_patch_from_json(*ti, &em, (*e)["components"]["ParticleEmitter"]); !r)
                return Error{path + ": ParticleEmitter: " + r.error().message, r.error().hint};
            return em;
        }
        if (e->contains("children") && (*e)["children"].is_array())
            for (std::size_t i = e->at("children").size(); i-- > 0;) stack.push_back(&(*e)["children"][i]);
    }
    return Error{path + " has no ParticleEmitter component", "A sub-emitter prefab is an entity with a ParticleEmitter."};
}

// ---------------------------------------------------------------- the style --

void ParticleStyle::refresh(const ParticleEmitter& em) {
    news.clear();
    if (valid_ && srcColor_ == em.colorGradient && srcSize_ == em.sizeCurve && srcSpeed_ == em.speedCurve && srcAlpha_ == em.alphaCurve &&
        srcTrailWidth_ == em.trailWidthCurve && srcTrailColor_ == em.trailGradient)
        return;
    const std::vector<std::string> before = problems;
    problems.clear();
    auto get = [&](auto& dst, const Json& src, const char* field) {
        using T = std::remove_reference_t<decltype(dst)>;
        auto r = T::parse(src, std::string("ParticleEmitter.") + field);
        if (r) dst = std::move(*r);
        else {
            dst = T{};
            problems.push_back(r.error().to_string());
        }
    };
    get(color, em.colorGradient, "colorGradient");
    get(trailColor, em.trailGradient, "trailGradient");
    get(size, em.sizeCurve, "sizeCurve");
    get(speed, em.speedCurve, "speedCurve");
    get(alpha, em.alphaCurve, "alphaCurve");
    get(trailWidth, em.trailWidthCurve, "trailWidthCurve");
    srcColor_ = em.colorGradient;
    srcSize_ = em.sizeCurve;
    srcSpeed_ = em.speedCurve;
    srcAlpha_ = em.alphaCurve;
    srcTrailWidth_ = em.trailWidthCurve;
    srcTrailColor_ = em.trailGradient;
    valid_ = true;
    for (const std::string& p : problems)
        if (std::find(before.begin(), before.end(), p) == before.end()) news.push_back(p);
}

// ----------------------------------------------------------------- flipbook --

int flipbook_frame_count(const ParticleEmitter& em) {
    const int cells = std::max(1, em.flipbookColumns) * std::max(1, em.flipbookRows);
    return em.flipbookFrames > 0 ? std::clamp(em.flipbookFrames, 1, cells) : cells;
}

FlipbookFrame flipbook_frame(const ParticleEmitter& em, float age, float life, float startFrame01) {
    const int count = flipbook_frame_count(em);
    const int cols = std::max(1, em.flipbookColumns);
    int idx = 0;
    const int start = em.flipbookRandomStart ? std::clamp(int(std::floor(startFrame01 * float(count))), 0, count - 1) : 0;
    if (count > 1) {
        if (em.flipbookFps > 0.0f) {
            const double n = std::floor(double(std::max(0.0f, age)) * double(em.flipbookFps));
            idx = int((std::int64_t(start) + std::int64_t(std::min(n, 1e9))) % count);
        } else if (em.flipbookRandomStart) {
            idx = start;
        } else {
            const float t = life > 0.0f ? std::clamp(age / life, 0.0f, 1.0f) : 0.0f;
            idx = std::clamp(int(std::floor(t * float(count))), 0, count - 1);
        }
    }
    return {idx % cols, idx / cols};
}

// -------------------------------------------------------------------- noise --

Vec3 particle_noise(Vec3 p, float t, float scale, float speed, std::uint32_t seed) {
    if (!(scale > 0.0f)) return {};
    const float k = t * speed;
    const float inv = 1.0f / scale;
    auto clampf = [](float v) { return v == v ? std::clamp(v, -1.0e6f, 1.0e6f) : 0.0f; };  // a NaN position or time counts as 0
    const float qx = clampf(p.x * inv + k), qy = clampf(p.y * inv + k * 0.618f), qz = clampf(p.z * inv + k * 0.382f);
    const float fx = std::floor(qx), fy = std::floor(qy), fz = std::floor(qz);
    const std::int32_t ix = std::int32_t(fx), iy = std::int32_t(fy), iz = std::int32_t(fz);
    const float sx = fade(qx - fx), sy = fade(qy - fy), sz = fade(qz - fz);
    float out[3];
    for (std::uint32_t ch = 0; ch < 3; ++ch) {
        const float c000 = lattice(ix, iy, iz, seed, ch), c100 = lattice(ix + 1, iy, iz, seed, ch);
        const float c010 = lattice(ix, iy + 1, iz, seed, ch), c110 = lattice(ix + 1, iy + 1, iz, seed, ch);
        const float c001 = lattice(ix, iy, iz + 1, seed, ch), c101 = lattice(ix + 1, iy, iz + 1, seed, ch);
        const float c011 = lattice(ix, iy + 1, iz + 1, seed, ch), c111 = lattice(ix + 1, iy + 1, iz + 1, seed, ch);
        const float x00 = c000 + (c100 - c000) * sx, x10 = c010 + (c110 - c010) * sx;
        const float x01 = c001 + (c101 - c001) * sx, x11 = c011 + (c111 - c011) * sx;
        const float y0 = x00 + (x10 - x00) * sy, y1 = x01 + (x11 - x01) * sy;
        out[ch] = y0 + (y1 - y0) * sz;
    }
    return {out[0], out[1], out[2]};
}

// ---------------------------------------------------------------- the sim --

void ParticleSim::seed(std::uint64_t s) {
    rng_.reseed(s);
    noiseSeed_ = std::uint32_t(s ^ (s >> 32));
    seeded_ = true;
}

std::vector<std::string> ParticleSim::take_problems() {
    std::vector<std::string> out;
    out.swap(problems_);
    return out;
}

void ParticleSim::note(const std::string& problem) {
    if (std::find(reported_.begin(), reported_.end(), problem) != reported_.end()) return;
    if (reported_.size() < 64) reported_.push_back(problem);
    problems_.push_back(problem);
}

const ParticleEmitter& ParticleSim::group_emitter(int g, const ParticleEmitter& root) const {
    if (g <= 0 || g >= int(groups_.size()) || !groups_[std::size_t(g)].emitter) return root;
    return *groups_[std::size_t(g)].emitter;
}

bool ParticleSim::can_spawn(int g) const {
    if (int(particles.size()) >= kParticleHardCap) return false;
    const int cap = std::min(cfg(g).maxParticles, kParticleHardCap);
    return live(g) < cap;
}

ParticleSim::Place ParticleSim::root_place(const ParticleEnv& env) const {
    const ParticleEmitter& em = *root_;
    Place pl;
    if (!em.worldSpace) return pl;  // particles live in the emitter's own space: it is the origin
    pl.m = env.emitter;
    pl.origin = pl.m.translation();
    pl.rotZ = degrees(det::atan2(pl.m.at(0, 1), pl.m.at(0, 0)));
    pl.scale = {length(Vec3{pl.m.at(0, 0), pl.m.at(0, 1), pl.m.at(0, 2)}), length(Vec3{pl.m.at(1, 0), pl.m.at(1, 1), pl.m.at(1, 2)})};
    if (env.screen) {
        pl.origin.y = -pl.origin.y;  // the screen position, seen +Y up (flipped back when drawn)
        pl.rotZ = -pl.rotZ;          // a rotation turns clockwise on the +Y down screen, as it does for sprites
    }
    return pl;
}

void ParticleSim::begin(const ParticleEmitter& em, const ParticleEnv& env, bool forceSync) {
    root_ = &em;
    env_ = &env;
    if (groups_.empty()) groups_.resize(1);
    sync_sub_emitters(env, forceSync);
    if (counts_.size() != groups_.size()) counts_.assign(groups_.size(), 0);
    bool mesh = false;
    for (std::size_t g = 0; g < groups_.size(); ++g) {
        const ParticleEmitter& c = cfg(int(g));
        Group& grp = groups_[g];
        // The root's fields can change at any step (a script, the editor); a sub-emitter's only when it is copied from an entity.
        if (g == 0 || grp.styleDirty) {
            grp.style.refresh(c);
            grp.styleDirty = false;
            for (const std::string& p : grp.style.news) note(g == 0 ? p : "in a sub-emitter: " + p);
        }
        mesh = mesh || (g == 0 && c.shape == ParticleShape::Mesh);
        grp.tilemap = nullptr;
        if (c.collision == ParticleCollision::Tilemap && root_->worldSpace && !env.screen) {
            if (g == 0 && env.tilemap) {
                grp.tilemap = env.tilemap;
                grp.tilemapWorld = env.tilemapWorld;
            } else if (env.findTilemap) {
                grp.tilemap = env.findTilemap(c, grp.tilemapWorld);
            }
            if (grp.tilemap) refresh_solid(int(g));
            else if (!grp.tilemapWarned) {
                grp.tilemapWarned = true;
                note(std::string(g == 0 ? "" : "in a sub-emitter: ") +
                     "collision is \"tilemap\" but there is no Tilemap with solidTiles to bounce on (set collisionTilemap, or add solidTiles to a "
                     "Tilemap), so particles pass through");
            }
        }
    }
    // Only an emitter that draws from a mesh asks for its surface to be read; rebuilt only when the surface is another one.
    if (mesh && (env_->mesh != cdfSurface_ || (env_->mesh && cdfTriangles_ != env_->mesh->indices.size() / 3))) refresh_cdf();
}

void ParticleSim::refresh_cdf() {
    const MeshSurface* s = env_->mesh;
    cdfSurface_ = s;
    cdf_.clear();
    cdfTriangles_ = s ? s->indices.size() / 3 : 0;
    if (!s) return;
    const std::size_t tris = s->indices.size() / 3;
    cdf_.reserve(tris);
    float total = 0.0f;
    for (std::size_t t = 0; t < tris; ++t) {
        const std::uint32_t i0 = s->indices[t * 3], i1 = s->indices[t * 3 + 1], i2 = s->indices[t * 3 + 2];
        float area = 0.0f;
        if (i0 < s->positions.size() && i1 < s->positions.size() && i2 < s->positions.size())
            area = 0.5f * length(cross(s->positions[i1] - s->positions[i0], s->positions[i2] - s->positions[i0]));
        total += area;
        cdf_.push_back(total);
    }
}

void ParticleSim::refresh_solid(int gi) {
    Group& g = groups_[std::size_t(gi)];
    const Tilemap& tm = *g.tilemap;
    if (!g.solidValid || !(g.solidSrc == tm.solidTiles)) {
        g.solid.clear();
        if (tm.solidTiles.is_array())
            for (const Json& v : tm.solidTiles)
                if (v.is_number_integer()) g.solid.push_back(int(v.get<std::int64_t>()));
        std::sort(g.solid.begin(), g.solid.end());
        g.solidSrc = tm.solidTiles;
        g.solidValid = true;
    }
    tilemap_local_to_cell(tm, g.cellMap);
    g.tilemapSize = tilemap_size(tm);
    g.tilemapInv = g.tilemapWorld.inverse();
}

bool ParticleSim::solid_cell(const Group& g, int col, int row) const {
    if (g.solid.empty()) return false;
    const int idx = tile_index(tilemap_tile_at(*g.tilemap, g.tilemapSize, col, row));
    return idx >= 0 && std::binary_search(g.solid.begin(), g.solid.end(), idx);
}

// ------------------------------------------------------------- sub-emitters --

void ParticleSim::sync_sub_emitters(const ParticleEnv& env, bool forceSync) {
    if (!(subSpecValid_ && subSpec_ == root_->subEmitters)) {
        groups_.resize(1);
        for (auto& list : groups_[0].on) list.clear();
        retries_.clear();
        subSpec_ = root_->subEmitters;
        subSpecValid_ = true;
        const int keep = int(groups_.size());
        for (Particle& p : particles)
            if (p.group >= keep) release_trail(p);
        particles.erase(std::remove_if(particles.begin(), particles.end(), [&](const Particle& p) { return p.group >= keep; }), particles.end());
        build_links(0, subSpec_, 0, env);
        counts_.assign(groups_.size(), 0);
        for (const Particle& p : particles) ++counts_[p.group];
        nextLinkSync_ = clock_ + kParticleLinkSync;
    } else if (groups_.size() > 1 || !retries_.empty()) {
        // The emitters an {"entity": id} link names are copied now and then (a copy of a whole emitter is not free), and a link that
        // could not be built is tried again about once a second.
        if (forceSync || clock_ >= nextLinkSync_) {
            nextLinkSync_ = clock_ + kParticleLinkSync;
            for (std::size_t g = 1; g < groups_.size(); ++g) {
                if (groups_[g].entityId.empty() || !env.findEmitter) continue;
                if (const ParticleEmitter* e = env.findEmitter(groups_[g].entityId)) {
                    *groups_[g].emitter = *e;
                    groups_[g].styleDirty = true;
                }
            }
        }
        retry_links(env);
    }
}

void ParticleSim::retry_links(const ParticleEnv& env) {
    for (std::size_t i = 0; i < retries_.size();) {
        if (clock_ < retries_[i].next) { ++i; continue; }
        const Retry r = retries_[i];  // a copy: add_link may queue new retries
        const LinkResult res = add_link(r.parent, r.kind, r.event, r.link, r.depth, env);
        if (res == LinkResult::Retry) {
            retries_[i].next = clock_ + kParticleLinkRetry;
            ++i;
        } else {
            retries_.erase(retries_.begin() + std::ptrdiff_t(i));
        }
    }
    counts_.resize(groups_.size(), 0);
}

void ParticleSim::build_links(int g, const Json& spec, int depth, const ParticleEnv& env) {
    if (spec.is_null() || (spec.is_object() && spec.empty())) return;
    if (!spec.is_object()) {
        note("subEmitters must be an object like {\"death\": {\"count\": 6, \"emitter\": {...}}}, got " + describe_json_value(spec));
        return;
    }
    if (depth >= kParticleSubDepth) {
        note(std::format("sub-emitters nested more than {} levels deep are ignored", kParticleSubDepth));
        return;
    }
    static const std::vector<std::string> events = {"birth", "death", "collision"};
    for (auto it = spec.begin(); it != spec.end(); ++it) {
        const auto ev = std::find(events.begin(), events.end(), it.key());
        if (ev == events.end()) {
            note("unknown sub-emitter event '" + it.key() + "': " + did_you_mean(it.key(), events));
            continue;
        }
        const int kind = int(ev - events.begin());
        std::vector<const Json*> links;
        if (it.value().is_object()) links.push_back(&it.value());
        else if (it.value().is_array()) for (const Json& l : it.value()) links.push_back(&l);
        else {
            note("sub-emitter '" + it.key() + "' must be an object or an array of objects, got " + describe_json_value(it.value()));
            continue;
        }
        for (const Json* lp : links) {
            const LinkResult res = add_link(g, kind, it.key(), *lp, depth, env);
            if (res == LinkResult::Full) return;
            if (res == LinkResult::Retry) {
                Retry r;
                r.parent = g;
                r.kind = kind;
                r.depth = depth;
                r.link = *lp;
                r.event = it.key();
                r.next = clock_ + kParticleLinkRetry;
                retries_.push_back(std::move(r));
            }
        }
    }
}

ParticleSim::LinkResult ParticleSim::add_link(int g, int kind, const std::string& event, const Json& l, int depth, const ParticleEnv& env) {
    static const std::vector<std::string> linkKeys(std::begin(kLinkKeys), std::end(kLinkKeys));
    if (!l.is_object()) {
        note("a '" + event + "' sub-emitter must be an object, got " + describe_json_value(l));
        return LinkResult::Dropped;
    }
    bool bad = false;
    for (auto k = l.begin(); k != l.end(); ++k)
        if (std::find(linkKeys.begin(), linkKeys.end(), k.key()) == linkKeys.end()) {
            note("unknown key '" + k.key() + "' in a '" + event + "' sub-emitter: " + did_you_mean(k.key(), linkKeys));
            bad = true;
        }
    const int given = int(l.contains("emitter")) + int(l.contains("prefab")) + int(l.contains("entity"));
    if (given != 1) {
        note("a '" + event + "' sub-emitter needs exactly one of \"emitter\", \"prefab\" and \"entity\"");
        bad = true;
    }
    if (bad) return LinkResult::Dropped;
    if (int(groups_.size()) > kParticleSubGroups) {
        note(std::format("at most {} sub-emitters are used; the others are ignored", kParticleSubGroups));
        return LinkResult::Full;
    }
    Link link;
    if (l.contains("count") && l["count"].is_number()) link.count = std::clamp(int(std::clamp(l["count"].get<double>(), 0.0, 1.0e6)), 1, kParticleSubCount);
    if (l.contains("chance") && l["chance"].is_number()) link.chance = std::clamp(float(l["chance"].get<double>()), 0.0f, 1.0f);
    if (l.contains("inherit") && l["inherit"].is_number()) link.inherit = float(l["inherit"].get<double>());

    Group ng;
    ng.emitter = std::make_unique<ParticleEmitter>();
    if (l.contains("emitter")) {
        const TypeInfo* ti = emitter_type();
        if (!ti) return LinkResult::Dropped;
        if (auto r = object_patch_from_json(*ti, ng.emitter.get(), l["emitter"]); !r) {
            note("sub-emitter '" + event + "' emitter: " + r.error().to_string());
            return LinkResult::Dropped;
        }
    } else if (l.contains("prefab")) {
        if (!l["prefab"].is_string()) { note("a sub-emitter's \"prefab\" must be a path string"); return LinkResult::Dropped; }
        auto r = load_prefab_particle_emitter(l["prefab"].get<std::string>());
        if (!r) {
            note(r.error().to_string() + " (the '" + event + "' sub-emitter is not born until the prefab can be read; it is tried again every second)");
            return LinkResult::Retry;
        }
        *ng.emitter = std::move(*r);
    } else {
        if (!l["entity"].is_string()) { note("a sub-emitter's \"entity\" must be an entity id string"); return LinkResult::Dropped; }
        ng.entityId = l["entity"].get<std::string>();
        const ParticleEmitter* e = env.findEmitter ? env.findEmitter(ng.entityId) : nullptr;
        if (!e) {
            note("sub-emitter entity '" + ng.entityId + "' has no ParticleEmitter (is the id right, and is the entity in the scene?); the '" + event +
                 "' sub-emitter is not born until it has one, and is tried again every second");
            return LinkResult::Retry;
        }
        *ng.emitter = *e;
    }
    groups_.push_back(std::move(ng));
    const int idx = int(groups_.size()) - 1;
    link.group = idx;
    groups_[std::size_t(g)].on[kind].push_back(link);
    const Json nested = groups_[std::size_t(idx)].emitter->subEmitters;  // a copy: groups_ may grow below
    build_links(idx, nested, depth + 1, env);
    return LinkResult::Built;
}

void ParticleSim::fire(int g, int kind, Vec3 pos, Vec3 vel, Vec3 normal) {
    for (const Link& l : groups_[std::size_t(g)].on[kind]) spawn_children(l, pos, vel, normal, kind == 2);
}

void ParticleSim::spawn_children(const Link& link, Vec3 pos, Vec3 vel, Vec3 normal, bool hasNormal) {
    if (link.group <= 0 || link.group >= int(groups_.size())) return;
    if (link.chance < 1.0f && !rng_.chance(link.chance)) return;
    const ParticleEmitter& c = cfg(link.group);
    Place pl;
    pl.origin = pos;
    if (!c.is3D) {
        pl.rotZ = hasNormal ? degrees(det::atan2(normal.y, normal.x)) - 90.0f : 0.0f;  // direction 90 (up) = along the surface normal
        pl.m = Mat4::translate(pos) * Mat4::rotate_z_deg(pl.rotZ);
    } else {
        Mat4 basis;
        if (hasNormal) {
            const Vec3 n = normalize(normal);
            const Vec3 helper = std::fabs(n.y) < 0.9f ? Vec3{0, 1, 0} : Vec3{1, 0, 0};
            const Vec3 x = normalize(cross(n, helper)), z = cross(x, n);
            basis.at(0, 0) = x.x; basis.at(0, 1) = x.y; basis.at(0, 2) = x.z;
            basis.at(1, 0) = n.x; basis.at(1, 1) = n.y; basis.at(1, 2) = n.z;
            basis.at(2, 0) = z.x; basis.at(2, 1) = z.y; basis.at(2, 2) = z.z;
        }
        pl.m = Mat4::translate(pos) * basis;
    }
    const Vec3 extra = vel * link.inherit;
    for (int i = 0; i < link.count; ++i) {
        if (subBudget_ <= 0 || !can_spawn(link.group)) break;
        --subBudget_;
        spawn_one(link.group, pl, extra, true);
    }
}

// --------------------------------------------------------------- spawning --

void ParticleSim::sample_shape(const ParticleEmitter& c, const Place& place, Vec3& offset, int& dirMode, Vec3& dir) {
    offset = {};
    dirMode = 0;
    dir = {};
    const Vec3 sz = c.shapeSize;
    const bool edge = c.shapeFrom == ParticleShapeFrom::Edge;
    const bool outward = c.shapeDirection == ParticleShapeDirection::Outward;
    Vec3 loc{}, localDir{};
    switch (c.shape) {
    case ParticleShape::Point: return;
    case ParticleShape::Circle: {
        if (!c.is3D) {
            const float a = rng_.range(0.0f, kTau);
            float s, co;
            det::sin_cos(a, s, co);
            const float r = sz.x * (edge ? 1.0f : std::sqrt(next_unit(rng_)));
            loc = {co * r, s * r, 0.0f};
            localDir = {co, s, 0.0f};
        } else {
            const float z = rng_.range(-1.0f, 1.0f);
            const float phi = rng_.range(0.0f, kTau);
            float s, co;
            det::sin_cos(phi, s, co);
            const float ring = std::sqrt(std::max(0.0f, 1.0f - z * z));
            const float r = sz.x * (edge ? 1.0f : cbrt01(next_unit(rng_)));
            localDir = {ring * co, ring * s, z};
            loc = localDir * r;
        }
        if (outward) { dirMode = 1; }
        break;
    }
    case ParticleShape::Box: {
        const float hx = sz.x * 0.5f, hy = sz.y * 0.5f, hz = c.is3D ? sz.z * 0.5f : 0.0f;
        if (!c.is3D) {
            if (edge) {
                const float per = 2.0f * (sz.x + sz.y);
                const float u = next_unit(rng_) * per;
                if (u < sz.x) { loc = {-hx + u, hy, 0}; localDir = {0, 1, 0}; }
                else if (u < sz.x + sz.y) { loc = {hx, hy - (u - sz.x), 0}; localDir = {1, 0, 0}; }
                else if (u < 2.0f * sz.x + sz.y) { loc = {hx - (u - sz.x - sz.y), -hy, 0}; localDir = {0, -1, 0}; }
                else { loc = {-hx, -hy + (u - 2.0f * sz.x - sz.y), 0}; localDir = {-1, 0, 0}; }
            } else {
                loc = {rng_.range(-hx, hx), rng_.range(-hy, hy), 0.0f};
                localDir = normalize(loc);
            }
        } else if (edge) {
            const float ax = sz.y * sz.z, ay = sz.x * sz.z, az = sz.x * sz.y;
            const float u = next_unit(rng_) * 2.0f * (ax + ay + az);
            const float a = rng_.range(-1.0f, 1.0f), b = rng_.range(-1.0f, 1.0f);
            if (u < ax) { loc = {hx, a * hy, b * hz}; localDir = {1, 0, 0}; }
            else if (u < 2.0f * ax) { loc = {-hx, a * hy, b * hz}; localDir = {-1, 0, 0}; }
            else if (u < 2.0f * ax + ay) { loc = {a * hx, hy, b * hz}; localDir = {0, 1, 0}; }
            else if (u < 2.0f * ax + 2.0f * ay) { loc = {a * hx, -hy, b * hz}; localDir = {0, -1, 0}; }
            else if (u < 2.0f * ax + 2.0f * ay + az) { loc = {a * hx, b * hy, hz}; localDir = {0, 0, 1}; }
            else { loc = {a * hx, b * hy, -hz}; localDir = {0, 0, -1}; }
        } else {
            loc = {rng_.range(-hx, hx), rng_.range(-hy, hy), rng_.range(-hz, hz)};
            localDir = normalize(loc);
        }
        if (outward) dirMode = 1;
        break;
    }
    case ParticleShape::Cone: {
        // A base perpendicular to the direction the cone points along; the cone's spread is the emitter's `spread`.
        const Vec2 d0 = from_angle_deg(c.direction);
        if (!c.is3D) {
            const float t = edge ? (rng_.chance(0.5f) ? 1.0f : -1.0f) : rng_.range(-1.0f, 1.0f);
            loc = {-d0.y * t * sz.x, d0.x * t * sz.x, 0.0f};
            if (outward) {
                const Vec2 d = from_angle_deg(c.direction + c.spread * t);
                localDir = {d.x, d.y, 0.0f};
                dirMode = 2;
            }
        } else {
            const Vec3 axis{d0.x, d0.y, 0.0f};
            const Vec3 helper = std::fabs(axis.y) < 0.9f ? Vec3{0, 1, 0} : Vec3{1, 0, 0};
            const Vec3 u = normalize(cross(axis, helper)), v = cross(axis, u);
            const float phi = rng_.range(0.0f, kTau);
            float s, co;
            det::sin_cos(phi, s, co);
            const float f = edge ? 1.0f : std::sqrt(next_unit(rng_));
            const Vec3 radial = u * co + v * s;
            loc = radial * (f * sz.x);
            if (outward) {
                float ts, tc;
                det::sin_cos(radians(std::clamp(c.spread, 0.0f, 180.0f)) * f, ts, tc);
                localDir = axis * tc + radial * ts;
                dirMode = 2;
            }
        }
        break;
    }
    case ParticleShape::Edge: {
        loc = {rng_.range(-0.5f, 0.5f) * sz.x, 0.0f, 0.0f};
        break;
    }
    case ParticleShape::Mesh: {
        const MeshSurface* s = env_->mesh;
        if (!s || cdf_.empty() || !(cdf_.back() > 0.0f) || cdf_.size() * 3 > s->indices.size()) return;
        const float pick = next_unit(rng_) * cdf_.back();
        std::size_t t = std::size_t(std::lower_bound(cdf_.begin(), cdf_.end(), pick) - cdf_.begin());
        if (t >= cdf_.size()) t = cdf_.size() - 1;
        // The surface is data from a file: a triangle that points past the vertices (refresh_cdf gave it no area) is not sampled.
        const std::uint32_t i0 = s->indices[t * 3], i1 = s->indices[t * 3 + 1], i2 = s->indices[t * 3 + 2];
        if (i0 >= s->positions.size() || i1 >= s->positions.size() || i2 >= s->positions.size()) return;
        const Vec3 a = s->positions[i0], b = s->positions[i1], d = s->positions[i2];
        Vec3 p;
        if (edge) {
            const int e = rng_.range_int(0, 2);
            const float k = next_unit(rng_);
            const Vec3 from = e == 0 ? a : (e == 1 ? b : d), to = e == 0 ? b : (e == 1 ? d : a);
            p = lerp(from, to, k);
        } else {
            float u = next_unit(rng_), w = next_unit(rng_);
            if (u + w > 1.0f) { u = 1.0f - u; w = 1.0f - w; }
            p = a + (b - a) * u + (d - a) * w;
        }
        localDir = normalize(cross(b - a, d - a));
        const Vec3 worldPoint = place.m.transform_point(p);
        offset = worldPoint - place.origin;
        if (outward) { dir = normalize(place.m.transform_dir(localDir)); dirMode = 1; }
        return;
    }
    }
    if (!c.is3D) {
        // Turned by the emitter's rotation and stretched by its scale, in the plane.
        float s, co;
        det::sin_cos(radians(place.rotZ), s, co);
        offset = {(loc.x * place.scale.x) * co - (loc.y * place.scale.y) * s, (loc.x * place.scale.x) * s + (loc.y * place.scale.y) * co, 0.0f};
        dir = {localDir.x * co - localDir.y * s, localDir.x * s + localDir.y * co, 0.0f};
    } else {
        offset = place.m.transform_dir(loc);
        dir = normalize(place.m.transform_dir(localDir));
    }
}

void ParticleSim::spawn_one(int g, const Place& place, Vec3 extraVel, bool child) {
    const ParticleEmitter& c = cfg(g);
    Particle p;
    p.group = std::uint8_t(g);
    p.life = std::max(0.01f, c.lifetime * (1.0f + rng_.range(-c.lifetimeVariance, c.lifetimeVariance)));
    const float speed = c.speed * (1.0f + rng_.range(-c.speedVariance, c.speedVariance));
    Vec3 offset, shapeDir;
    int dirMode = 0;
    if (!(child && c.shape == ParticleShape::Mesh)) sample_shape(c, place, offset, dirMode, shapeDir);  // a sub-emitter has no mesh of its own
    if (!c.is3D) {
        float ang = c.direction + place.rotZ;
        if (dirMode == 2 || (dirMode == 1 && length_sq(shapeDir) > 0.0f)) {
            const float base = degrees(det::atan2(shapeDir.y, shapeDir.x));
            ang = base;
        }
        if (dirMode != 2) ang = ang + rng_.range(-c.spread, c.spread);
        const Vec2 d = from_angle_deg(ang);
        p.vel = {d.x * speed, d.y * speed, 0.0f};
    } else {
        Vec3 dir;
        if (dirMode == 2) {
            dir = shapeDir;
        } else {
            const Vec2 d0 = from_angle_deg(c.direction);
            Vec3 axis{d0.x, d0.y, 0.0f};
            axis = normalize(place.m.transform_dir(axis));
            if (dirMode == 1 && length_sq(shapeDir) > 0.0f) axis = shapeDir;
            const Vec3 helper = std::fabs(axis.y) < 0.9f ? Vec3{0, 1, 0} : Vec3{1, 0, 0};
            const Vec3 u = normalize(cross(axis, helper)), v = cross(axis, u);
            const float cosT = lerp(1.0f, det::cos(radians(std::clamp(c.spread, 0.0f, 180.0f))), rng_.next_float());
            const float sinT = std::sqrt(std::max(0.0f, 1.0f - cosT * cosT));
            const float phi = rng_.range(0.0f, kTau);
            float ps, pc;
            det::sin_cos(phi, ps, pc);
            dir = axis * cosT + (u * pc + v * ps) * sinT;
        }
        p.vel = dir * speed;
    }
    p.vel += extraVel;
    p.pos = place.origin + offset;
    p.sizeScale = c.sizeVariance > 0.0f ? std::max(0.0f, 1.0f + rng_.range(-c.sizeVariance, c.sizeVariance)) : 1.0f;
    p.rotation = c.startRotation.y > c.startRotation.x ? rng_.range(c.startRotation.x, c.startRotation.y) : c.startRotation.x;
    p.spin = c.spin.y > c.spin.x ? rng_.range(c.spin.x, c.spin.y) : c.spin.x;
    if (c.flipbookRandomStart) p.random = rng_.next_float();
    if (c.trail == ParticleTrail::Particle) {
        p.trailSlot = acquire_trail_slot();
        if (p.trailSlot < 0)
            note(std::format("the trails of this emitter use up their pool of {} points ({} trails of {} points): particles born while it is "
                             "full have no trail",
                             kParticleTrailBudget, kParticleTrailSlots, kParticleTrailPoints));
        else record_trail(p, c);
    }
    const Vec3 pos = p.pos, vel = p.vel;
    particles.push_back(std::move(p));
    ++counts_[std::size_t(g)];
    everSpawned = true;
    if (!groups_[std::size_t(g)].on[0].empty()) fire(g, 0, pos, vel, Vec3{});
}

void ParticleSim::spawn(const ParticleEmitter& em, const ParticleEnv& env, int count) {
    begin(em, env, true);
    subBudget_ = kParticleSubPerStep;
    const Place place = root_place(env);
    const Vec3 extra = em.worldSpace ? emitterVel_ * em.inheritVelocity : Vec3{};
    for (int i = 0; i < count && can_spawn(0); ++i) spawn_one(0, place, extra, false);
}

void ParticleSim::flush(const ParticleEmitter& em, const ParticleEnv& env) {
    if (pendingBurst_ <= 0) return;
    const int n = pendingBurst_;
    pendingBurst_ = 0;
    spawn(em, env, n);
}

// ------------------------------------------------------------------- trails --

int ParticleSim::acquire_trail_slot() {
    int slot;
    if (!freeSlots_.empty()) {
        slot = freeSlots_.back();
        freeSlots_.pop_back();
    } else {
        const int used = int(trailPool_.size() / std::size_t(kParticleTrailPoints));
        if (used >= kParticleTrailSlots) return -1;
        slot = used;
        trailPool_.resize(trailPool_.size() + std::size_t(kParticleTrailPoints));  // the vector grows geometrically: few allocations
    }
    ++trailsInUse_;
    return slot;
}

void ParticleSim::release_trail(Particle& p) {
    if (p.trailSlot < 0) return;
    freeSlots_.push_back(p.trailSlot);
    --trailsInUse_;
    p.trailSlot = -1;
    p.trailCount = 0;
    p.trailHead = 0;
}

void ParticleSim::record_trail(Particle& p, const ParticleEmitter& c) {
    if (p.trailSlot < 0) return;
    constexpr int mask = kParticleTrailPoints - 1;
    ParticleTrailPoint* pts = &trailPool_[std::size_t(p.trailSlot) * std::size_t(kParticleTrailPoints)];
    const float now = float(clock_);
    const float interval = std::max(0.001f, c.trailTime / float(kParticleTrailPoints));
    int head = p.trailHead, count = p.trailCount;
    if (count == 0 || now - pts[(head + mask) & mask].time >= interval) {
        pts[head] = {p.pos, now};
        head = (head + 1) & mask;
        if (count < kParticleTrailPoints) ++count;
    }
    while (count > 0 && now - pts[(head - count) & mask].time > c.trailTime) --count;
    p.trailHead = std::uint8_t(head);
    p.trailCount = std::uint8_t(count);
}

const ParticleTrailPoint& ParticleSim::trail_point(const Particle& p, int i) const {
    constexpr int mask = kParticleTrailPoints - 1;
    return trailPool_[std::size_t(p.trailSlot) * std::size_t(kParticleTrailPoints) + std::size_t((int(p.trailHead) + mask - i) & mask)];
}

int ParticleSim::trail_quads() const {
    int quads = int(emitterTrail.size());
    for (const Particle& p : particles)
        if (p.trailSlot >= 0 && p.trailCount > 1) quads += int(p.trailCount) - 1;
    return quads;
}

// ----------------------------------------------------------------- motion --

// Friction of a particle that rests or slides on a surface, per second: its sliding speed falls like e^(-this * collisionFriction * t).
constexpr float kRestingFriction = 10.0f;
constexpr float kPlaneSkin = 1e-3f;

void ParticleSim::bounce(Particle& p, const ParticleEmitter& c, Vec3 normal, float dt) {
    const float vn = dot(p.vel, normal);
    const float impactSpeed = -vn;
    const float resting = std::max(kMinImpactSpeed, 2.0f * length(c.gravity) * dt);
    const bool impact = c.collisionKill || impactSpeed > resting;
    if (vn < 0.0f) {
        const Vec3 vt = p.vel - normal * vn;
        const float f = std::clamp(c.collisionFriction, 0.0f, 1.0f);
        // A hit loses the fraction `collisionFriction` of the sliding speed at once. A particle that only rests or slides on the
        // surface touches it every step, so it loses speed per second instead (scaled by dt): it slides the same at any frame rate.
        const float x = kRestingFriction * f * dt;  // 1 / (1 + x + x^2 / 2) follows e^-x well enough at any frame rate
        const Vec3 slide = impact ? vt * (1.0f - f) : vt * (1.0f / (1.0f + x + 0.5f * x * x));
        p.vel = slide + normal * (impactSpeed * std::max(0.0f, c.collisionBounce));
    }
    if (!impact) return;
    p.age += std::clamp(c.collisionLifetimeLoss, 0.0f, 1.0f) * p.life;
    if (c.collisionKill) p.age = p.life;
    if (!groups_[p.group].on[2].empty()) events_.push_back({2, int(p.group), p.pos, p.vel, normal});
}

void ParticleSim::collide(Particle& p, const ParticleEmitter& c, Vec3 before, float dt) {
    if (c.collision == ParticleCollision::Plane) {
        // dot(n, p) = d for the plane as written, whatever the length of [nx, ny, nz]: both sides are divided by it.
        const Vec3 raw = c.collisionPlane.xyz();
        const float len = length(raw);
        if (!(len > kEpsilon)) return;
        const Vec3 n = raw * (1.0f / len);
        const float d = c.collisionPlane.w / len;
        const float sBefore = dot(n, before) - d, s = dot(n, p.pos) - d;
        // A particle put back on the plane by the last hit sits at s = 0 up to rounding (a slanted plane has no exact answer):
        // a hair of tolerance keeps it from slipping through on the next step.
        if (sBefore >= -kPlaneSkin && s < 0.0f) {
            p.pos = p.pos - n * s;
            bounce(p, c, n, dt);
        }
        return;
    }
    const Group& grp = groups_[p.group];
    if (c.collision != ParticleCollision::Tilemap || !grp.tilemap || grp.solid.empty() || grp.tilemapSize.empty()) return;
    const Tilemap& tm = *grp.tilemap;
    const Vec3 a = grp.tilemapInv.transform_point(before), b = grp.tilemapInv.transform_point(p.pos);
    int ca, ra, cb, rb;
    if (!tilemap_cell_at_local(tm, {a.x, a.y}, ca, ra) || !tilemap_cell_at_local(tm, {b.x, b.y}, cb, rb)) return;
    if ((ca == cb && ra == rb) || !solid_cell(grp, cb, rb) || solid_cell(grp, ca, ra)) return;
    const int dc = cb - ca, dr = rb - ra;
    bool faceX = dc != 0 && dr == 0, faceY = dr != 0 && dc == 0;
    if (!faceX && !faceY) {
        const bool sx = solid_cell(grp, cb, ra), sy = solid_cell(grp, ca, rb);
        if (sx && !sy) faceX = true;
        else if (sy && !sx) faceY = true;
        else faceX = faceY = true;  // a corner
    }
    const float* cm = grp.cellMap;
    Vec2 n{0, 0};
    if (faceX) n += Vec2{cm[0], cm[1]} * (dc > 0 ? -1.0f : 1.0f);
    if (faceY) n += Vec2{cm[2], cm[3]} * (dr > 0 ? -1.0f : 1.0f);
    if (faceX && !faceY && dc == 0) n = Vec2{cm[0], cm[1]} * -1.0f;
    if (faceY && !faceX && dr == 0) n = Vec2{cm[2], cm[3]} * -1.0f;
    n = normalize(n);
    if (length_sq(n) <= 0.0f) return;
    Vec3 nw = normalize(grp.tilemapWorld.transform_dir(Vec3{n.x, n.y, 0.0f}));
    nw.z = 0.0f;
    p.pos = before;  // back to the last free place
    bounce(p, c, nw, dt);
}

void ParticleSim::move(Particle& p, const ParticleEmitter& c, const ParticleStyle& style, float dt) {
    const float t = std::clamp(p.age / p.life, 0.0f, 1.0f);
    p.vel += c.gravity * dt;
    if (c.noiseStrength != 0.0f) {
        Vec3 n = particle_noise(p.pos, float(clock_), c.noiseScale, c.noiseSpeed, noiseSeed_);
        if (!c.is3D) n.z = 0.0f;
        p.vel += n * (c.noiseStrength * dt);
    }
    if (c.drag > 0.0f) p.vel = p.vel * (1.0f / (1.0f + c.drag * dt));
    p.rotation += p.spin * dt;
    const float mult = style.speed.eval_or(t, 1.0f);
    // A sub-emitter's particles live in the space of the emitter that owns them (they are born where the parent is and drawn the way
    // the parent's are), so its own `worldSpace` does not count.
    const bool collides = c.collision != ParticleCollision::None && root_->worldSpace && !env_->screen;
    if (!collides) {
        p.pos += p.vel * (mult * dt);
        return;
    }
    // Several short steps when the particle would cross a whole tile (or a thin plane) in one.
    int steps = 1;
    const Group& grp = groups_[p.group];
    if (c.collision == ParticleCollision::Tilemap && grp.tilemap) {
        const float cell = std::max(1e-3f, 0.5f * std::min(grp.tilemap->tileSize.x, grp.tilemap->tileSize.y));
        float n = std::ceil(length(p.vel) * std::fabs(mult) * dt / cell);
        if (!(n >= 1.0f)) n = 1.0f;  // also a NaN
        steps = int(std::min(n, 8.0f));  // clamped as a float: a huge speed must not overflow the int
    }
    const float sdt = dt / float(steps);
    for (int i = 0; i < steps && p.age < p.life; ++i) {
        const Vec3 before = p.pos;
        p.pos += p.vel * (mult * sdt);
        collide(p, c, before, sdt);
    }
}

void ParticleSim::step(const ParticleEmitter& em, const ParticleEnv& env, float dt) {
    begin(em, env, !(dt > 0.0f));
    subBudget_ = kParticleSubPerStep;
    events_.clear();
    const Place place = root_place(env);

    // The emitter's velocity is measured between fixed steps. A settle pass (dt 0, at the end of a frame) leaves it, and the place it
    // was last seen at, alone: what a script or a tween moved the emitter by since the last step still counts at the next one.
    if (dt > 0.0f) {
        if (em.worldSpace) {
            if (haveLastPos_) emitterVel_ = (place.origin - lastPos_) / dt;
            lastPos_ = place.origin;
            haveLastPos_ = true;
        } else {
            emitterVel_ = {};
            haveLastPos_ = false;
        }
    }
    const Vec3 extra = em.worldSpace ? emitterVel_ * em.inheritVelocity : Vec3{};
    auto spawn_root = [&](int n) {
        for (int i = 0; i < n && can_spawn(0); ++i) spawn_one(0, place, extra, false);
    };

    spawn_root(pendingBurst_);
    pendingBurst_ = 0;
    // The configured burst fires once when the emitter first appears (even with emitting = false) and again each time `emitting`
    // goes from false to true.
    const bool startBurst = fresh_ || (em.emitting && !wasEmitting_);
    fresh_ = false;
    wasEmitting_ = em.emitting;
    if (startBurst) spawn_root(em.burst);
    if (em.emitting && dt > 0.0f && em.rate > 0.0f) {
        acc_ += em.rate * dt;
        while (acc_ >= 1.0f) {
            acc_ -= 1.0f;
            if (!can_spawn(0)) {
                acc_ -= std::floor(acc_);  // keep the fraction; do not queue up what cannot be born
                break;
            }
            spawn_one(0, place, extra, false);
        }
    }

    if (dt > 0.0f) {
        clock_ += double(dt);
        for (Particle& p : particles) {
            const ParticleEmitter& c = cfg(p.group);
            p.age += dt;
            move(p, c, groups_[p.group].style, dt);
            if (c.trail == ParticleTrail::Particle) record_trail(p, c);
        }
        for (Particle& p : particles) {
            if (p.age < p.life) continue;
            if (!groups_[p.group].on[1].empty()) events_.push_back({1, int(p.group), p.pos, p.vel, Vec3{}});
            release_trail(p);
        }
        particles.erase(std::remove_if(particles.begin(), particles.end(), [](const Particle& p) { return p.age >= p.life; }), particles.end());
        std::fill(counts_.begin(), counts_.end(), 0);
        for (const Particle& p : particles) ++counts_[p.group];
        // Children are born after the whole step moved; they start at age 0 and move from the next step.
        for (std::size_t i = 0; i < events_.size(); ++i) {
            const Event ev = events_[i];
            fire(ev.group, ev.kind, ev.pos, ev.vel, ev.normal);
        }
        events_.clear();
        if (em.trail == ParticleTrail::Emitter && em.worldSpace) {
            const float interval = std::max(0.001f, em.trailTime / float(kParticleTrailPoints));
            if (em.emitting && (emitterTrail.empty() || float(clock_) - emitterTrail.back().time >= interval))
                emitterTrail.push_back({place.origin, float(clock_)});
        }
        std::size_t drop = 0;
        while (drop < emitterTrail.size() && float(clock_) - emitterTrail[drop].time > em.trailTime) ++drop;
        if (emitterTrail.size() - drop > std::size_t(kParticleTrailPoints)) drop = emitterTrail.size() - std::size_t(kParticleTrailPoints);
        if (drop > 0) emitterTrail.erase(emitterTrail.begin(), emitterTrail.begin() + std::ptrdiff_t(drop));
    }
    std::fill(counts_.begin(), counts_.end(), 0);
    for (const Particle& p : particles) ++counts_[p.group];
}

}  // namespace fa
