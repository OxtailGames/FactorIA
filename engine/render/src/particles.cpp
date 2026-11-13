// Draws the particles of the scene. The simulation is not here: the runtime steps fa::ParticleSim (fa_scene, scene/particles.h) in
// the fixed simulation step, one per emitter in the world's ParticleStore (scene/particle_store.h, World::particles()), with or
// without a renderer. This file reads what the store holds and draws it as quads on the shared 2D path: soft dots, textures,
// flipbook frames, ribbons for trails, hard pixels in pixel mode. Nothing here is GPU specific.
#include <algorithm>
#include <cmath>
#include <memory>
#include <mutex>

#include "fa/core/asset_manifest.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/log.h"
#include "fa/scene/particle_store.h"
#include "fa/scene/ui_rect.h"
#include "frame.h"
#include "render_jobs.h"

namespace fa::render {

namespace {

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
    if (cache->have && cache->version == version &&
        (cache->image.empty() || fs::modified_time(cache->image) == cache->imageTime))
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
                if (std::none_of(colors->begin(), colors->end(),
                                 [&](const Color& o) { return o.r == c.r && o.g == c.g && o.b == c.b; }))
                    colors->push_back(c);
            }
        } else {
            const std::string tag = cache->image + "|" + std::to_string(cache->imageTime);
            if (cache->warned != tag) {
                cache->warned = tag;
                FA_WARN("particles",
                        "assets.json style.palette is the image '{}', which cannot be read, so pixel-mode particles "
                        "without their own "
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
const std::vector<Color>& own_palette(ParticleEmitterState& st, int g, const Json& palette) {
    if (int(st.palettes.size()) <= g) st.palettes.resize(std::size_t(g) + 1);
    ParticleEmitterState::GroupPalette& gp = st.palettes[std::size_t(g)];
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

// The emitters are drawn as jobs (render_jobs.h) once the scene holds kParallelParticles live particles: drawing one costs ~50 ns,
// handing out a chunk a few microseconds. A chunk is a run of whole emitters of about kParticleChunk particles, counting
// kEmitterWeight for the emitter's own work (its trail).
constexpr std::size_t kParallelParticles = 2048;
constexpr std::size_t kParticleChunk = 1024;
constexpr std::size_t kEmitterWeight = 16;

// An emitter gather_particles draws, with what only the calling thread may look up (textures, the project palette).
struct DrawItem {
    Entity e;
    const ParticleEmitter* em = nullptr;
    ParticleEmitterState* st = nullptr;  // only the chunk drawing this emitter touches it (its palettes)
    bool screen = false;
    Rect clip;
    std::vector<TextureAsset*> groupTex;  // the texture of each group (white for soft dots and pixel mode)
};

// Draws one emitter into `list`: a chunk's own list, so this only reads the World and the Frame.
void draw_emitter(const World& world, const Frame& f, const DrawItem& item, const std::vector<Color>& stylePalette,
                  QuadList& list) {
    static const std::vector<Color> kNoPalette;
    const Entity e = item.e;
    const ParticleEmitter& em = *item.em;
    ParticleEmitterState& st = *item.st;
    const ParticleSim& sim = st.sim;
    const bool screen = item.screen;
    const Rect& clip = item.clip;
    {
        Mat4 m = world.world_matrix(e);
        Vec3 anchor{};
        if (screen) {
            const Vec2 a =
                anchor_point(em.anchor, em.safeArea, Vec2{float(f.targetW), float(f.targetH)}, world.safe_insets());
            anchor = Vec3{a.x, a.y, 0.0f};
        }

        const Color tint = inherited_tint(world, f, e);
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
        auto ribbon = [&](const ParticleEmitter& c, const ParticleStyle& style, Color head, float alphaMul,
                          bool billboard) {
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
                Color k = style.trailColor.empty() ? Color{head.r, head.g, head.b, head.a * (1.0f - s[i])}
                                                   : style.trailColor.eval(s[i]);
                k = k * tint;
                k.a *= alphaMul;
                col[i] = k;
            }
            for (std::size_t i = 0; i + 1 < n; ++i) {
                if (col[i].a <= 0.0f && col[i + 1].a <= 0.0f) continue;
                auto v = [&](const Vec3& p, const Color& k) {
                    return Vertex2D{p.x, p.y, p.z, whiteUv.x, whiteUv.y, pack_color(k), float(kModeTextured), 0};
                };
                list.quad(v(left[i], col[i]), v(right[i], col[i]), v(right[i + 1], col[i + 1]),
                          v(left[i + 1], col[i + 1]));
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
                    s.push_back(
                        std::clamp((now - sim.emitterTrail[i].time) / std::max(1e-3f, em.trailTime), 0.0f, 1.0f));
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
            TextureAsset* tex = item.groupTex[std::size_t(g)];
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
                    palettePtr = &stylePalette;
                }
            }
            const std::vector<Color>& palette = *palettePtr;
            const float pxSize = std::max(1e-3f, c.pixelSize);
            const float mode = soft ? float(kModeSoft) : float(kModeTextured);
            const bool plain = !c.alignToVelocity && c.startRotation.x == 0.0f && c.startRotation.y == 0.0f &&
                               c.spin.x == 0.0f && c.spin.y == 0.0f;
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
                    if (billboard) {
                        r = f.cam.right;
                        u = f.cam.up;
                    }
                    if (!plain) {
                        float deg = p.rotation;
                        if (c.alignToVelocity) {
                            const float vx = billboard ? dot(p.vel, f.cam.right) : p.vel.x;
                            const float vy = billboard ? dot(p.vel, f.cam.up) : p.vel.y;
                            if (vx != 0.0f || vy != 0.0f) deg += degrees(det::atan2(vy, vx));
                        }
                        float sn, cs;
                        det::sin_cos(radians(deg), sn, cs);
                        const Vec3 r0 = r,
                                   u0 = u;  // counter-clockwise on screen (u already points down the y-down screen)
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
    }
}

}  // namespace

void gather_particles(World& world, Frame& f) {
    auto& all = world.particles();
    // On this thread: which emitters are drawn, the textures of their groups (a texture may be loaded) and, when an
    // emitter in pixel mode without a palette of its own is drawn, the project palette (read once per frame).
    std::vector<DrawItem> items;
    std::vector<std::size_t> weights;
    std::shared_ptr<const std::vector<Color>> frameStylePalette;
    world.each<ParticleEmitter>([&](Entity e, ParticleEmitter& em) {
        if (!entity_active(world, f, e)) return;
        ParticleEmitterState* found = all.find(e);
        if (!found) return;
        ParticleEmitterState& st = *found;
        const ParticleSim& sim = st.sim;
        if (sim.empty() && sim.emitterTrail.empty()) return;
        const bool screen = particle_screen_space(em);
        if (screen ? !f.wantScreen : !f.wantWorld) return;
        if (!screen && !f.mask.draws(world, e)) return;  // Camera.showTags / hideTags
        DrawItem item;
        item.e = e;
        item.em = &em;
        item.st = &st;
        item.screen = screen;
        if (screen && !screen_clip(world, e, f, item.clip)) return;
        item.groupTex.resize(std::size_t(sim.group_count()));
        for (int g = 0; g < sim.group_count(); ++g) {
            const ParticleEmitter& c = sim.group_emitter(g, em);
            item.groupTex[std::size_t(g)] = f.assets->white();
            if (sim.live(g) <= 0) continue;  // nothing of this group is drawn: nothing to look up
            if (!c.texture.empty() && !c.pixelMode) item.groupTex[std::size_t(g)] = f.assets->texture(c.texture);
            if (c.pixelMode && !(c.palette.is_array() && !c.palette.empty()) && !frameStylePalette)
                frameStylePalette = style_palette();
        }
        f.stats->particles += int(sim.particles.size());
        weights.push_back(sim.particles.size() + kEmitterWeight);
        items.push_back(std::move(item));
    });
    static const std::vector<Color> kNoStylePalette;
    const std::vector<Color>& stylePalette = frameStylePalette ? *frameStylePalette : kNoStylePalette;

    // The quads, a run of emitters per chunk into the chunk's own lists, joined in chunk order: the lists end up as if
    // every emitter had been drawn into them one after the other.
    const auto ranges = rjobs::weighted_ranges(weights, kParticleChunk, kParallelParticles);
    if (ranges.size() <= 1) {
        for (const DrawItem& item : items) draw_emitter(world, f, item, stylePalette, item.screen ? f.screen : f.world);
        return;
    }
    std::vector<QuadList> worldParts(ranges.size()), screenParts(ranges.size());
    rjobs::run("render.gather_particles", rjobs::split(ranges.size(), 1, 2), [&](const jobs::Chunk& c) {
        for (std::size_t r = c.begin; r < c.end; ++r)
            for (std::size_t i = ranges[r].first; i < ranges[r].second; ++i)
                draw_emitter(world, f, items[i], stylePalette, items[i].screen ? screenParts[r] : worldParts[r]);
    });
    for (std::size_t r = 0; r < ranges.size(); ++r) {
        f.world.append(worldParts[r]);
        f.screen.append(screenParts[r]);
    }
}

}  // namespace fa::render
