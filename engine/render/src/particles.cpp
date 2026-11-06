// The particles of the scene: the simulation is fa::ParticleSim (fa_scene, scene/particles.h; deterministic, each emitter owns an Rng
// seeded from its stable entity id, so gameplay randomness (world.rng()) is never consumed by rendering and headless/windowed runs
// produce identical particles). This file keeps one sim per emitter, gives it the world around it (a Tilemap to bounce on, a mesh to
// be born on, the emitters sub-emitters name) and draws what it holds as quads on the shared 2D path: soft dots, textures, flipbook
// frames, ribbons for trails, hard pixels in pixel mode. Nothing here is GPU specific.
#include <algorithm>
#include <cmath>
#include <memory>
#include <mutex>
#include <unordered_map>

#include "fa/core/asset_manifest.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/log.h"
#include "fa/scene/particles.h"
#include "fa/scene/ui_rect.h"
#include "frame.h"

namespace fa::render {

namespace {

struct EmitterState {
    ParticleSim sim;
    bool seen = false;
    // shape = mesh: the surface being sampled and the name it was loaded for.
    std::shared_ptr<const MeshSurface> mesh;
    std::string meshName;
    bool meshWarned = false;
    // pixel mode: the palette of each group (ParticleEmitter.palette of the emitter, or of its sub-emitter), parsed from `src`.
    struct GroupPalette {
        Json src;
        std::vector<Color> colors;
        bool valid = false;
    };
    std::vector<GroupPalette> palettes;
};

std::unordered_map<std::uint64_t, EmitterState>& states() {
    // Intentionally leaked: Renderer::shutdown() may run during static destruction.
    static auto* s = new std::unordered_map<std::uint64_t, EmitterState>();
    return *s;
}

std::uint64_t hash_id(const std::string& id) {
    std::uint64_t h = 1469598103934665603ULL;
    for (unsigned char c : id) { h ^= c; h *= 1099511628211ULL; }
    return h;
}

EmitterState& state_for(World& world, Entity e, const ParticleEmitter& em) {
    EmitterState& st = states()[e.bits()];
    if (!st.sim.seeded()) {
        std::uint64_t s = hash_id(world.id_of(e));
        // A non-zero `seed` gives another run of the same emitter; 0 keeps the run derived from the id alone.
        if (em.seed != 0) s ^= std::uint64_t(std::uint32_t(em.seed)) * 0x9E3779B97F4A7C15ULL;
        st.sim.seed(s);
    }
    return st;
}

// A screen-space emitter is simulated exactly like a world one (+Y up: direction 90 = up, negative gravity falls) and
// only flipped onto the y-down screen when drawn. is3D has no screen space, so it wins.
bool screen_space(const ParticleEmitter& em) { return em.space == RenderSpace::Screen && !em.is3D; }

// The Tilemap particles bounce on: the one `collisionTilemap` names, else the first active one with solid tiles.
const Tilemap* find_tilemap(World& world, const ParticleEmitter& em, Mat4& matrix) {
    if (!em.collisionTilemap.is_null() && world.alive(em.collisionTilemap)) {
        if (const Tilemap* tm = world.get<Tilemap>(em.collisionTilemap)) {
            matrix = world.world_matrix(em.collisionTilemap);
            return tm;
        }
    }
    const Tilemap* found = nullptr;
    world.each<Tilemap>([&](Entity t, Tilemap& tm) {
        if (found || !entity_active(world, t)) return;
        if (!tm.solidTiles.is_array() || tm.solidTiles.empty()) return;
        found = &tm;
        matrix = world.world_matrix(t);
    });
    return found;
}

ParticleEnv make_env(World& world, Entity e, const ParticleEmitter& em, EmitterState& st) {
    ParticleEnv env;
    env.emitter = world.world_matrix(e);
    env.is3D = em.is3D;
    env.screen = screen_space(em);
    // The sim asks for the map of every group whose collision is "tilemap": the emitter's and its sub-emitters'.
    env.findTilemap = [&world](const ParticleEmitter& c, Mat4& matrix) { return find_tilemap(world, c, matrix); };
    if (em.shape == ParticleShape::Mesh && !em.shapeMesh.empty()) {
        // A procedural "mesh:N" is asked every time (the store answers from its cache and notices a mesh.update); the others once.
        const bool procedural = em.shapeMesh.rfind("mesh:", 0) == 0;
        if (st.meshName != em.shapeMesh || procedural || (!st.mesh && !st.meshWarned)) {
            auto r = load_mesh_surface(world.meshes(), em.shapeMesh);
            if (r) {
                st.mesh = *r;
                st.meshWarned = false;
            } else {
                st.mesh.reset();
                if (!st.meshWarned)
                    FA_WARN("particles", "{}: shapeMesh '{}' cannot be read, so particles are born at the point: {}", world.id_of(e),
                            em.shapeMesh, r.error().to_string());
                st.meshWarned = true;
            }
            st.meshName = em.shapeMesh;
        }
        env.mesh = st.mesh.get();
    }
    env.findEmitter = [&world](std::string_view id) -> const ParticleEmitter* {
        const Entity t = world.find_by_id(id);
        return t.is_null() ? nullptr : world.get<ParticleEmitter>(t);
    };
    return env;
}

void log_problems(World& world, Entity e, EmitterState& st) {
    for (const std::string& p : st.sim.take_problems()) FA_WARN("particles", "{}: ParticleEmitter: {}", world.id_of(e), p);
}

// ---- pixel mode palettes ----

// The project palette (assets.json style.palette: a list of colours, or an image whose colours are the palette). Rebuilt when the manifest
// is read again or, for an image, when the image file changes; shared so a frame that holds it is not affected by a rebuild. The cache has a
// lock: gather runs on the render thread but nothing says every renderer does.
std::shared_ptr<const std::vector<Color>> style_palette() {
    struct Cache {
        std::mutex mutex;
        std::uint64_t version = 0;
        bool have = false;
        std::string image;  // the palette image of the manifest, "" when the palette is a list
        std::int64_t imageTime = -1;
        std::string warned;  // "image|time" of the last unreadable image, so it is logged once
        std::shared_ptr<const std::vector<Color>> colors;
    };
    static Cache* cache = new Cache();  // intentionally leaked, like the emitter states
    std::lock_guard lock(cache->mutex);
    const std::uint64_t version = assets::manifest_version();
    if (cache->have && cache->version == version && (cache->image.empty() || fs::modified_time(cache->image) == cache->imageTime))
        return cache->colors;
    cache->have = true;
    cache->version = version;
    cache->image.clear();
    cache->imageTime = -1;
    auto colors = std::make_shared<std::vector<Color>>();
    const Json src = assets::style_palette();
    if (src.is_array()) {
        for (const Json& v : src) {
            Color c;
            if (json_to(v, c, nullptr)) colors->push_back(Color{c.r, c.g, c.b, 1.0f});
        }
    } else if (src.is_string()) {
        cache->image = src.get<std::string>();
        cache->imageTime = fs::modified_time(cache->image);
        auto img = load_image(cache->image);
        if (img) {
            for (std::size_t i = 0; i + 3 < img->rgba.size() && colors->size() < 256; i += 4) {
                if (img->rgba[i + 3] < 128) continue;
                const Color c{img->rgba[i] / 255.0f, img->rgba[i + 1] / 255.0f, img->rgba[i + 2] / 255.0f, 1.0f};
                if (std::none_of(colors->begin(), colors->end(), [&](const Color& o) { return o.r == c.r && o.g == c.g && o.b == c.b; }))
                    colors->push_back(c);
            }
        } else {
            const std::string tag = cache->image + "|" + std::to_string(cache->imageTime);
            if (cache->warned != tag) {
                cache->warned = tag;
                FA_WARN("particles", "assets.json style.palette is the image '{}', which cannot be read, so pixel-mode particles without their own "
                                     "palette use four levels per colour channel: {}",
                        cache->image, img.error().to_string());
            }
        }
    }
    cache->colors = std::move(colors);
    return cache->colors;
}

// The palette of the group `g` of an emitter that sets its own (ParticleEmitter.palette). Kept per group, since every sub-emitter has its
// own field; parsed again only when the field is different from what was parsed.
const std::vector<Color>& own_palette(EmitterState& st, int g, const Json& palette) {
    if (int(st.palettes.size()) <= g) st.palettes.resize(std::size_t(g) + 1);
    EmitterState::GroupPalette& gp = st.palettes[std::size_t(g)];
    if (!gp.valid || !(gp.src == palette)) {
        gp.src = palette;
        gp.colors.clear();
        for (const Json& v : palette) {
            Color c;
            if (json_to(v, c, nullptr)) gp.colors.push_back(Color{c.r, c.g, c.b, 1.0f});
        }
        gp.valid = true;
    }
    return gp.colors;
}

Color snap_to_palette(const std::vector<Color>& palette, Color c) {
    if (palette.empty()) {
        // No palette to snap to: each channel in 4 steps, a limited look like a small palette has.
        auto q = [](float v) { return std::floor(std::clamp(v, 0.0f, 1.0f) * 3.0f + 0.5f) / 3.0f; };
        return Color{q(c.r), q(c.g), q(c.b), c.a};
    }
    float best = 1e30f;
    const Color* pick = &palette[0];
    for (const Color& p : palette) {
        const float dr = p.r - c.r, dg = p.g - c.g, db = p.b - c.b;
        const float d = dr * dr + dg * dg + db * db;
        if (d < best) {
            best = d;
            pick = &p;
        }
    }
    return Color{pick->r, pick->g, pick->b, c.a};
}

}  // namespace

void clear_particles() { states().clear(); }

void queue_particle_burst(std::uint64_t entityBits, int count) {
    if (count <= 0) return;
    states()[entityBits].sim.queue_burst(count);
}

void flush_particle_bursts(World& world) {
    auto& all = states();
    bool any = false;
    for (auto& [k, s] : all) any = any || s.sim.pending_burst() > 0;
    if (!any) return;
    world.each<ParticleEmitter>([&](Entity e, ParticleEmitter& em) {
        if (!entity_active(world, e)) return;
        auto it = all.find(e.bits());
        if (it == all.end() || it->second.sim.pending_burst() <= 0) return;
        EmitterState& st = state_for(world, e, em);
        const ParticleEnv env = make_env(world, e, em, st);
        st.sim.flush(em, env);
        log_problems(world, e, st);
    });
}

void update_particles(World& world, float dt) {
    auto& all = states();
    for (auto& [k, s] : all) s.seen = false;

    world.each<ParticleEmitter>([&](Entity e, ParticleEmitter& em) {
        if (!entity_active(world, e)) return;
        EmitterState& st = state_for(world, e, em);
        st.seen = true;
        const ParticleEnv env = make_env(world, e, em, st);
        st.sim.step(em, env, dt);
        log_problems(world, e, st);
        if (em.autoDestroy && !em.emitting && st.sim.everSpawned && st.sim.empty() && st.sim.emitterTrail.empty() &&
            st.sim.pending_burst() == 0 && !world.pending_destroy(e))
            world.destroy(e);
    });

    for (auto it = all.begin(); it != all.end();) {
        if (!it->second.seen) it = all.erase(it);
        else ++it;
    }
}

void gather_particles(World& world, Frame& f) {
    auto& all = states();
    static const std::vector<Color> kNoPalette;
    // The project palette, read once per frame and only when an emitter in pixel mode without a palette of its own is drawn.
    std::shared_ptr<const std::vector<Color>> frameStylePalette;
    world.each<ParticleEmitter>([&](Entity e, ParticleEmitter& em) {
        if (!entity_active(world, f, e)) return;
        auto it = all.find(e.bits());
        if (it == all.end()) return;
        EmitterState& st = it->second;
        const ParticleSim& sim = st.sim;
        if (sim.empty() && sim.emitterTrail.empty()) return;
        const bool screen = screen_space(em);
        if (screen ? !f.wantScreen : !f.wantWorld) return;
        if (!screen && !f.mask.draws(world, e)) return;  // Camera.showTags / hideTags
        Mat4 m = world.world_matrix(e);
        Vec3 anchor{};
        if (screen) {
            const Vec2 a = anchor_point(em.anchor, em.safeArea, Vec2{float(f.targetW), float(f.targetH)}, world.safe_insets());
            anchor = Vec3{a.x, a.y, 0.0f};
        }

        const Color tint = inherited_tint(world, f, e);
        QuadList& list = screen ? f.screen : f.world;
        Rect clip;
        if (screen && !screen_clip(world, e, f, clip)) return;
        const float depth = f.cam.perspective && !screen ? length(m.translation() - f.cam.position) : 0.0f;
        // The sim's space -> where it is drawn (the +Y up simulation of a screen emitter is flipped onto the y-down screen).
        auto to_draw = [&](Vec3 q) {
            if (screen) q.y = -q.y;
            return (em.worldSpace ? q : m.transform_point(q)) + anchor;
        };
        TextureAsset* white = f.assets->white();
        const Vec2 whiteUv = white->uv(0.0f, 0.0f);
        const Vec3 viewDir = cross(f.cam.right, f.cam.up);
        const float now = float(sim.clock());

        // A ribbon through `pts` (head first, drawn space; s = 0 at the head, 1 at the oldest point), coloured from `head`.
        std::vector<Vec3> pts, left, right;
        std::vector<float> s;
        std::vector<Color> col;
        auto ribbon = [&](const ParticleEmitter& c, const ParticleStyle& style, Color head, float alphaMul, bool billboard) {
            const std::size_t n = pts.size();
            if (n < 2) return;
            left.resize(n);
            right.resize(n);
            col.resize(n);
            Vec3 dir{1, 0, 0};
            for (std::size_t i = 0; i < n; ++i) {
                const Vec3 d = pts[i > 0 ? i - 1 : 0] - pts[i + 1 < n ? i + 1 : n - 1];
                if (length_sq(d) > 1e-12f) dir = normalize(d);
                Vec3 perp = billboard ? cross(dir, viewDir) : Vec3{-dir.y, dir.x, 0.0f};
                perp = length_sq(perp) > 1e-12f ? normalize(perp) : (billboard ? f.cam.right : Vec3{0, 1, 0});
                const float w = c.trailWidth * style.trailWidth.eval_or(s[i], 1.0f - s[i]) * 0.5f;
                left[i] = pts[i] + perp * w;
                right[i] = pts[i] - perp * w;
                Color k = style.trailColor.empty() ? Color{head.r, head.g, head.b, head.a * (1.0f - s[i])} : style.trailColor.eval(s[i]);
                k = k * tint;
                k.a *= alphaMul;
                col[i] = k;
            }
            for (std::size_t i = 0; i + 1 < n; ++i) {
                if (col[i].a <= 0.0f && col[i + 1].a <= 0.0f) continue;
                auto v = [&](const Vec3& p, const Color& k) {
                    return Vertex2D{p.x, p.y, p.z, whiteUv.x, whiteUv.y, pack_color(k), float(kModeTextured), 0};
                };
                list.quad(v(left[i], col[i]), v(right[i], col[i]), v(right[i + 1], col[i + 1]), v(left[i + 1], col[i + 1]));
            }
        };

        for (int g = 0; g < sim.group_count(); ++g) {
            const ParticleEmitter& c = sim.group_emitter(g, em);
            const ParticleStyle& style = sim.group_style(g);
            const bool billboard = c.is3D && !screen;

            // ---- trails ----
            if (g == 0 && em.trail == ParticleTrail::Emitter && !sim.emitterTrail.empty()) {
                pts.clear();
                s.clear();
                Vec3 here = m.translation();  // where the emitter is now, in the sim's (+Y up) space
                if (screen) here.y = -here.y;
                pts.push_back(to_draw(here));
                s.push_back(0.0f);
                for (std::size_t i = sim.emitterTrail.size(); i-- > 0;) {
                    pts.push_back(to_draw(sim.emitterTrail[i].pos));
                    s.push_back(std::clamp((now - sim.emitterTrail[i].time) / std::max(1e-3f, em.trailTime), 0.0f, 1.0f));
                }
                list.begin_item(em.layer, depth, white, SamplerKind::Linear, em.blend, clip);
                ribbon(em, style, em.startColor, 1.0f, billboard);
                list.end_item();
            }
            if (sim.live(g) <= 0) continue;
            if (c.trail == ParticleTrail::Particle) {
                list.begin_item(c.layer, depth, white, SamplerKind::Linear, c.blend, clip);
                for (const Particle& p : sim.particles) {
                    const int points = sim.trail_size(p);
                    if (p.group != g || points == 0) continue;
                    const float t = p.age / p.life;
                    pts.clear();
                    s.clear();
                    pts.push_back(to_draw(p.pos));
                    s.push_back(0.0f);
                    for (int i = 0; i < points; ++i) {  // newest first
                        const ParticleTrailPoint& tp = sim.trail_point(p, i);
                        pts.push_back(to_draw(tp.pos));
                        s.push_back(std::clamp((now - tp.time) / std::max(1e-3f, c.trailTime), 0.0f, 1.0f));
                    }
                    const Color head = style.color.empty() ? lerp(c.startColor, c.endColor, t) : style.color.eval(t);
                    ribbon(c, style, head, style.alpha.eval_or(t, 1.0f), billboard);
                }
                list.end_item();
            }

            // ---- the particles ----
            const bool pixel = c.pixelMode;
            const bool soft = c.texture.empty() && !pixel;
            TextureAsset* tex = (c.texture.empty() || pixel) ? white : f.assets->texture(c.texture);
            // The whole texture (inside its atlas when packed); the soft dot of a texture-less emitter spans -1..1.
            const Vec2 uvMin = soft ? Vec2{-1.0f, -1.0f} : tex->uv(0.0f, 0.0f);
            const Vec2 uvMax = soft ? Vec2{1.0f, 1.0f} : tex->uv(float(tex->width), float(tex->height));
            const bool flipbook = !soft && !pixel && flipbook_frame_count(c) > 1;
            const float cw = flipbook ? float(tex->width) / float(std::max(1, c.flipbookColumns)) : 0.0f;
            const float ch = flipbook ? float(tex->height) / float(std::max(1, c.flipbookRows)) : 0.0f;
            const std::vector<Color>* palettePtr = &kNoPalette;
            if (pixel) {
                if (c.palette.is_array() && !c.palette.empty()) {
                    palettePtr = &own_palette(st, g, c.palette);
                } else {
                    if (!frameStylePalette) frameStylePalette = style_palette();
                    palettePtr = frameStylePalette.get();
                }
            }
            const std::vector<Color>& palette = *palettePtr;
            const float pxSize = std::max(1e-3f, c.pixelSize);
            const float mode = soft ? float(kModeSoft) : float(kModeTextured);
            const bool plain = !c.alignToVelocity && c.startRotation.x == 0.0f && c.startRotation.y == 0.0f && c.spin.x == 0.0f &&
                               c.spin.y == 0.0f;
            list.begin_item(c.layer, depth, tex, pixel ? SamplerKind::Nearest : SamplerKind::Linear, c.blend, clip);
            for (const Particle& p : sim.particles) {
                if (p.group != g) continue;
                const float t = p.age / p.life;
                float size = lerp(c.startSize, c.endSize, t) * style.size.eval_or(t, 1.0f) * p.sizeScale;
                if (size <= 0.0f) continue;
                Color colour = (style.color.empty() ? lerp(c.startColor, c.endColor, t) : style.color.eval(t)) * tint;
                colour.a *= style.alpha.eval_or(t, 1.0f);
                if (colour.a <= 0.0f) continue;
                if (pixel) colour = snap_to_palette(palette, colour);
                Vec3 pos = to_draw(p.pos);
                Vec3 r{1, 0, 0}, u{0, screen ? -1.0f : 1.0f, 0};
                if (pixel && !billboard) {
                    // Whole pixels: the square covers a whole number of them and sits on the grid.
                    size = std::max(1.0f, std::floor(size / pxSize + 0.5f)) * pxSize;
                    pos.x = std::floor(pos.x / pxSize + 0.5f) * pxSize;
                    pos.y = std::floor(pos.y / pxSize + 0.5f) * pxSize;
                } else {
                    if (billboard) { r = f.cam.right; u = f.cam.up; }
                    if (!plain) {
                        float deg = p.rotation;
                        if (c.alignToVelocity) {
                            const float vx = billboard ? dot(p.vel, f.cam.right) : p.vel.x;
                            const float vy = billboard ? dot(p.vel, f.cam.up) : p.vel.y;
                            if (vx != 0.0f || vy != 0.0f) deg += degrees(det::atan2(vy, vx));
                        }
                        float sn, cs;
                        det::sin_cos(radians(deg), sn, cs);
                        const Vec3 r0 = r, u0 = u;  // counter-clockwise on screen (u already points down the y-down screen)
                        r = r0 * cs + u0 * sn;
                        u = u0 * cs - r0 * sn;
                    }
                }
                Vec2 a = uvMin, b = uvMax;
                if (flipbook) {
                    const FlipbookFrame fr = flipbook_frame(c, p.age, p.life, p.random);
                    a = tex->uv(float(fr.column) * cw, float(fr.row) * ch);
                    b = tex->uv(float(fr.column + 1) * cw, float(fr.row + 1) * ch);
                }
                const float h = size * 0.5f;
                const std::uint32_t pc = pack_color(colour);
                auto v = [&](float sx, float sy, float uu, float vv) {
                    const Vec3 q = pos + r * (sx * h) + u * (sy * h);
                    return Vertex2D{q.x, q.y, q.z, uu, vv, pc, mode, 0};
                };
                list.quad(v(-1, 1, a.x, a.y), v(-1, -1, a.x, b.y), v(1, -1, b.x, b.y), v(1, 1, b.x, a.y));
            }
            list.end_item();
        }
        f.stats->particles += int(sim.particles.size());
    });
}

}  // namespace fa::render
