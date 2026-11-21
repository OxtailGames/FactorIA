#include "water2d.h"

#include <algorithm>
#include <cmath>
#include <cstring>

#include "fa/core/json.h"
#include "fa/core/log.h"
#include "fa/scene/components.h"
#include "fa/scene/world.h"

#include "color_space.h"
#include "frame.h"
#include "render_scene.h"
#include "shader_cache.h"
#include "shaders/water2d.glsl.h"

namespace fa::render {

// ---------------------------------------------------------------------------
// The mapping to the copy
// ---------------------------------------------------------------------------
SceneMap scene_map(const Mat4& vp, int x, int y, int w, int h, int targetW, int targetH) {
    SceneMap out;
    const float W = float(std::max(targetW, 1)), H = float(std::max(targetH, 1));
    const float cw = float(std::max(w, 1)), ch = float(std::max(h, 1));
    out.scene[0] = W / cw;
    out.scene[1] = H / ch;
    out.scene[2] = -float(x) / cw;
    out.scene[3] = -float(y) / ch;
    // screen u = (x + w * (0.5 + 0.5 * ndc.x)) / W and screen v = (y + h * (0.5 - 0.5 * ndc.y)) / H, with ndc = clip.xy / clip.w:
    // multiplied by clip.w they are linear in the position, so each is a row of the matrix (the rows of a column-major matrix).
    const float au = (float(x) + 0.5f * cw) / W, bu = 0.5f * cw / W;
    const float av = (float(y) + 0.5f * ch) / H, bv = 0.5f * ch / H;
    for (int c = 0; c < 4; ++c) {
        const float r0 = vp.at(c, 0), r1 = vp.at(c, 1), r3 = vp.at(c, 3);
        out.worldUv[0][c] = au * r3 + bu * r0;
        out.worldUv[1][c] = av * r3 - bv * r1;
        out.worldUv[2][c] = r3;
    }
    return out;
}

bool reads_scene(const QuadBatch& qb) {
    if (qb.effect != 0) return true;
    if (!qb.use || qb.use->error || !qb.use->material) return false;
    const MaterialAsset& m = *qb.use->material;
    const std::uint32_t bit = 1u << kMaterialSpriteSceneView;
    return ((m.programs[0].viewMask | m.programs[1].viewMask) & bit) != 0;
}

int count_scene_readers(const std::vector<QuadBatch>& batches) {
    int n = 0;
    for (const QuadBatch& qb : batches)
        if (reads_scene(qb)) ++n;
    return n;
}

int plan_scene_copies(const std::vector<QuadBatch>& batches, std::vector<std::uint32_t>& at) {
    int runs = 0;
    bool inRun = false;
    for (std::size_t i = 0; i < batches.size(); ++i) {
        const bool reads = reads_scene(batches[i]);
        if (reads && !inRun) {
            ++runs;
            if (runs <= kMaxSceneCopies) at.push_back(std::uint32_t(i));
        }
        inRun = reads;
    }
    return runs;
}

// ---------------------------------------------------------------------------
// Gather
// ---------------------------------------------------------------------------
namespace {

float finite_clamp(float v, float lo, float hi, float fallback) {
    if (!std::isfinite(v)) return fallback;
    return std::clamp(v, lo, hi);
}

// The area an effect covers, in the world: `origin` (the middle of the surface of water, the centre of a zone), the unit `up` axis, and the
// width across it and the height along it after the entity's scale.
struct Area {
    Vec2 origin, up;
    float width = 0, height = 0, z = 0;
};

bool area_of(const Mat4& m, Vec2 size, bool surfaceAtTop, Area& a) {
    const float sx = std::sqrt(m.at(0, 0) * m.at(0, 0) + m.at(0, 1) * m.at(0, 1));
    const float sy = std::sqrt(m.at(1, 0) * m.at(1, 0) + m.at(1, 1) * m.at(1, 1));
    if (!(sy > 1e-6f) || !(sx > 1e-6f) || !std::isfinite(size.x) || !std::isfinite(size.y) || size.x <= 0.0f ||
        size.y <= 0.0f)
        return false;
    a.up = {m.at(1, 0) / sy, m.at(1, 1) / sy};
    a.width = size.x * sx;
    a.height = size.y * sy;
    const Vec3 c = m.translation();
    a.z = c.z;
    a.origin = {c.x, c.y};
    if (surfaceAtTop) {  // the top edge of the box is the surface
        a.origin.x += a.up.x * a.height * 0.5f;
        a.origin.y += a.up.y * a.height * 0.5f;
    }
    return std::isfinite(a.origin.x) && std::isfinite(a.origin.y) && std::isfinite(a.width) && std::isfinite(a.height);
}

// Adds the param `name` of the material (when it declares one) to `out`, from the first `n` of `v`, shaped as the param says: a number for
// one component, else an array of its components (missing ones 0). A name the material does not declare is left out: an unknown key of
// materialParams is a warning, and a material takes the fields it needs.
void add_param(const MaterialAsset& m, Json& out, const char* name, const float* v, int n) {
    const MaterialParamDef* p = nullptr;
    for (const MaterialParamDef& d : m.params)
        if (d.name == name) p = &d;
    for (const MaterialParamDef& d : m.instanced)
        if (d.name == name) p = &d;
    if (!p) return;
    if (p->components == 1) {
        out[name] = v[0];
        return;
    }
    Json a = Json::array();
    for (int c = 0; c < p->components; ++c) a.push_back(c < n ? v[c] : 0.0f);
    out[name] = std::move(a);
}

// The one quad of the area: (across, along) its axes, from `left` to `right` and from `top` down to `bottom`. A built-in effect draws only
// the position, so the uv are not used.
void emit_quad(QuadList& list, const Area& a, float left, float right, float top, float bottom) {
    const Vec2 side{a.up.y, -a.up.x};
    auto vert = [&](float across, float along, float u, float v) {
        return Vertex2D{a.origin.x + side.x * across + a.up.x * along,
                        a.origin.y + side.y * across + a.up.y * along,
                        a.z,
                        u,
                        v,
                        0xFFFFFFFFu,
                        float(kModeTextured),
                        0.0f};
    };
    list.quad(vert(left, top, 0, 0), vert(left, bottom, 0, 1), vert(right, bottom, 1, 1), vert(right, top, 1, 0));
}

// True when the quad of an area (its corners from `left` to `right` across and `bottom` to `top` along its up axis) lies wholly outside
// the view of an orthographic camera: the item is then not made at all, so an off-screen pond neither splits the pass nor copies the
// picture (the sprites, shapes and tilemaps cull the same way). A perspective camera, or a view without a size, never culls.
bool outside_view(const Frame& f, const Area& a, float left, float right, float top, float bottom) {
    const Rect view = f.cam.visible;
    if (f.cam.perspective || !(view.w > 0.0f) || !(view.h > 0.0f)) return false;
    const Vec2 side{a.up.y, -a.up.x};
    float minX = 0, maxX = 0, minY = 0, maxY = 0;
    for (int c = 0; c < 4; ++c) {
        const float across = (c & 1) ? right : left, along = (c & 2) ? top : bottom;
        const float x = a.origin.x + side.x * across + a.up.x * along;
        const float y = a.origin.y + side.y * across + a.up.y * along;
        minX = c == 0 ? x : std::min(minX, x);
        maxX = c == 0 ? x : std::max(maxX, x);
        minY = c == 0 ? y : std::min(minY, y);
        maxY = c == 0 ? y : std::max(maxY, y);
    }
    return maxX < view.x || minX > view.x + view.w || maxY < view.y || minY > view.y + view.h;
}

}  // namespace

void gather_water_fx(World& world, Frame& f) {
    if (!f.wantWorld || !f.assets) return;
    const bool anyWater = world.any<Water2D>(), anyZone = world.any<DistortionZone2D>();
    if (!anyWater && !anyZone) return;
    Assets& assets = *f.assets;
    QuadList& list = f.world;
    auto secondary = [&](const Mat4& m) { return f.cam.perspective ? length(m.translation() - f.cam.position) : 0.0f; };

    if (anyWater)
        world.each<Water2D>([&](Entity e, Water2D& w) {
            if (!f.mask.draws(world, e) || !entity_active_in_scope(world, f.scopeRoot, e)) return;
            const Mat4 m = drawn_visual_matrix(world, e);
            Area a;
            if (!area_of(m, w.size, true, a)) return;
            const float amplitude = finite_clamp(w.waveAmplitude, 0.0f, 1000.0f, 0.0f);
            const float waveLen = finite_clamp(w.waveLength, 0.1f, 100000.0f, 64.0f);
            const float speed = finite_clamp(w.waveSpeed, -100.0f, 100.0f, 0.0f);
            const float reflection = finite_clamp(w.reflection, 0.0f, 1.0f, 0.5f);
            const float refraction = finite_clamp(w.refraction, 0.0f, 256.0f, 4.0f);
            // The surface moves up to `amplitude` above the top edge: the quad reaches that far (the fragment shader cuts the water at the
            // moving surface), plus a unit for the antialiased edge.
            const float rise = amplitude + 1.0f;
            const float half = a.width * 0.5f;
            if (outside_view(f, a, -half, half, rise, -a.height)) return;
            list.begin_item(w.layer, secondary(m), assets.white(), SamplerKind::Nearest);
            if (!w.material.empty()) {
                // The material draws the area: its quad's uv run 0..1 across the area (u left to right, v from the surface down), v is
                // negative in the strip above the surface, and the fields arrive as params of the names below (those it declares).
                const MaterialAsset* mat = assets.material(w.material);
                Json p = Json::object();
                if (mat && mat->ok) {
                    const float size[2] = {a.width, a.height};
                    const Color tint = w.tint;
                    const float tintv[4] = {tint.r, tint.g, tint.b, tint.a};
                    add_param(*mat, p, "size", size, 2);
                    add_param(*mat, p, "tint", tintv, 4);
                    add_param(*mat, p, "reflection", &reflection, 1);
                    add_param(*mat, p, "refraction", &refraction, 1);
                    add_param(*mat, p, "waveAmplitude", &amplitude, 1);
                    add_param(*mat, p, "waveLength", &waveLen, 1);
                    add_param(*mat, p, "waveSpeed", &speed, 1);
                }
                list.set_material(assets.sprite_material_once(w.material, p));
                const Vec2 side{a.up.y, -a.up.x};
                auto vert = [&](float across, float along) {
                    return Vertex2D{a.origin.x + side.x * across + a.up.x * along,
                                    a.origin.y + side.y * across + a.up.y * along,
                                    a.z,
                                    (across + half) / a.width,
                                    -along / a.height,
                                    0xFFFFFFFFu,
                                    float(kModeTextured),
                                    0.0f};
                };
                list.quad(vert(-half, rise), vert(-half, -a.height), vert(half, -a.height), vert(half, rise));
            } else {
                Fx2D fx;
                fx.water = true;
                fx.origin[0] = a.origin.x;
                fx.origin[1] = a.origin.y;
                fx.up[0] = a.up.x;
                fx.up[1] = a.up.y;
                fx.size[0] = a.width;
                fx.size[1] = a.height;
                const Color tint = to_scene(w.tint, f.linear);
                fx.tint[0] = tint.r;
                fx.tint[1] = tint.g;
                fx.tint[2] = tint.b;
                fx.tint[3] = finite_clamp(w.tint.a, 0.0f, 1.0f, 0.5f);
                fx.reflection = reflection;
                fx.refraction = refraction;
                fx.amplitude = amplitude;
                fx.length = waveLen;
                fx.speed = speed;
                list.set_effect(fx);
                emit_quad(list, a, -half, half, rise, -a.height);
            }
            list.end_item();
        });

    if (anyZone)
        world.each<DistortionZone2D>([&](Entity e, DistortionZone2D& z) {
            if (!f.mask.draws(world, e) || !entity_active_in_scope(world, f.scopeRoot, e)) return;
            const Mat4 m = drawn_visual_matrix(world, e);
            Area a;
            if (!area_of(m, z.size, false, a)) return;
            const float strength = finite_clamp(z.strength, 0.0f, 100.0f, 1.0f);
            const float hw = a.width * 0.5f, hh = a.height * 0.5f;
            if (outside_view(f, a, -hw, hw, hh, -hh)) return;
            list.begin_item(z.layer, secondary(m), assets.white(), SamplerKind::Nearest);
            if (!z.material.empty()) {
                const MaterialAsset* mat = assets.material(z.material);
                Json p = Json::object();
                if (mat && mat->ok) {
                    const float size[2] = {a.width, a.height};
                    add_param(*mat, p, "size", size, 2);
                    add_param(*mat, p, "strength", &strength, 1);
                }
                list.set_material(assets.sprite_material_once(z.material, p));
                const Vec2 side{a.up.y, -a.up.x};
                auto vert = [&](float across, float along) {
                    return Vertex2D{a.origin.x + side.x * across + a.up.x * along,
                                    a.origin.y + side.y * across + a.up.y * along,
                                    a.z,
                                    (across + hw) / a.width,
                                    (hh - along) / a.height,
                                    0xFFFFFFFFu,
                                    float(kModeTextured),
                                    0.0f};
                };
                list.quad(vert(-hw, hh), vert(-hw, -hh), vert(hw, -hh), vert(hw, hh));
            } else {
                Fx2D fx;
                fx.water = false;
                fx.origin[0] = a.origin.x;
                fx.origin[1] = a.origin.y;
                fx.up[0] = a.up.x;
                fx.up[1] = a.up.y;
                fx.size[0] = a.width;
                fx.size[1] = a.height;
                fx.strength = strength;
                list.set_effect(fx);
                emit_quad(list, a, -hw, hw, hh, -hh);
            }
            list.end_item();
        });
}

// ---------------------------------------------------------------------------
// WaterFx: the shaders, the copy and the draw
// ---------------------------------------------------------------------------
bool WaterFx::ready() {
    if (state_ != 0) return state_ > 0;
    copyShader_ = make_shader(water2d_copy_shader_desc(sg_query_backend()), "water2d_copy");
    fxShader_ = make_shader(water2d_fx_shader_desc(sg_query_backend()), "water2d_fx");
    if (sg_query_shader_state(copyShader_) != SG_RESOURCESTATE_VALID ||
        sg_query_shader_state(fxShader_) != SG_RESOURCESTATE_VALID) {
        if (copyShader_.id) sg_destroy_shader(copyShader_);
        if (fxShader_.id) sg_destroy_shader(fxShader_);
        copyShader_ = {};
        fxShader_ = {};
        state_ = -1;
        FA_ERROR("render", "Water2D, DistortionZone2D and the sprite materials that call fa_scene_color() are not "
                           "drawn: their shaders failed to "
                           "compile for this graphics backend (see the sokol log lines above). Hint: update the "
                           "graphics driver (Mesa: try "
                           "LIBGL_ALWAYS_SOFTWARE=1).");
        return false;
    }
    state_ = 1;
    return true;
}

sg_pipeline WaterFx::copy_pipeline(const TargetFormat& format) {
    for (const PipelineEntry& e : copyPipelines_)
        if (e.format == format) return e.pipeline;
    if (state_ <= 0) return {};
    sg_pipeline_desc d{};
    d.shader = copyShader_;
    d.layout.attrs[ATTR_water2d_copy_pos].format = SG_VERTEXFORMAT_FLOAT2;
    d.depth.compare = SG_COMPAREFUNC_ALWAYS;
    d.depth.write_enabled = false;
    d.depth.pixel_format = format.depth;
    d.colors[0].pixel_format = format.color;
    d.sample_count = format.samples;
    d.face_winding = SG_FACEWINDING_CCW;
    d.label = "scene-copy";
    sg_pipeline p = sg_make_pipeline(&d);
    if (sg_query_pipeline_state(p) != SG_RESOURCESTATE_VALID) {
        FA_ERROR("render", "failed to create the pipeline that copies the picture for Water2D / DistortionZone2D / "
                           "fa_scene_color(): those items "
                           "are not drawn. Hint: see the sokol log lines above.");
        if (p.id) sg_destroy_pipeline(p);
        p = {};
    }
    copyPipelines_.push_back({format, false, p});
    return p;
}

sg_pipeline WaterFx::fx_pipeline(const TargetFormat& format, bool depthTest) {
    for (const PipelineEntry& e : fxPipelines_)
        if (e.format == format && e.depthTest == depthTest) return e.pipeline;
    if (state_ <= 0) return {};
    sg_pipeline_desc d{};
    d.shader = fxShader_;
    static_assert(sizeof(Vertex2D) == 48, "the stride below is that of Vertex2D");
    d.layout.buffers[0].stride = int(sizeof(Vertex2D));
    d.layout.attrs[ATTR_water2d_fx_position].format = SG_VERTEXFORMAT_FLOAT3;
    d.layout.attrs[ATTR_water2d_fx_position].offset = 0;
    d.primitive_type = SG_PRIMITIVETYPE_TRIANGLES;
    d.index_type = SG_INDEXTYPE_UINT16;
    d.depth.compare = depthTest ? SG_COMPAREFUNC_LESS_EQUAL : SG_COMPAREFUNC_ALWAYS;
    d.depth.write_enabled = false;
    d.depth.pixel_format = format.depth;
    d.colors[0].pixel_format = format.color;
    d.colors[0].blend.enabled = true;
    d.colors[0].blend.src_factor_rgb = SG_BLENDFACTOR_SRC_ALPHA;
    d.colors[0].blend.dst_factor_rgb = SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
    d.colors[0].blend.src_factor_alpha = SG_BLENDFACTOR_ONE;
    d.colors[0].blend.dst_factor_alpha = SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
    d.sample_count = format.samples;
    d.cull_mode = SG_CULLMODE_NONE;
    d.face_winding = SG_FACEWINDING_CCW;
    d.label = "water2d";
    sg_pipeline p = sg_make_pipeline(&d);
    if (sg_query_pipeline_state(p) != SG_RESOURCESTATE_VALID) {
        FA_ERROR("render", "failed to create the pipeline of Water2D / DistortionZone2D for this render target format: "
                           "they are not drawn. "
                           "Hint: see the sokol log lines above.");
        if (p.id) sg_destroy_pipeline(p);
        p = {};
    }
    fxPipelines_.push_back({format, depthTest, p});
    return p;
}

bool WaterFx::copy(TransientTargets& targets, Gpu& gpu, const Target& game, int x, int row, int w, int h,
                   std::uint64_t& handle, sg_view& view) {
    handle = 0;
    view = {};
    if (w < 1 || h < 1 || !game.texView.id || !ready()) return false;
    TransientDesc d;
    d.width = w;
    d.height = h;
    d.format = TargetFormat{gpu.scene_format(), SG_PIXELFORMAT_NONE, 1};
    d.label = "scene-copy";
    const std::uint64_t got = targets.pool.acquire(d);
    if (!got) return false;
    const Target* t = targets.get(got);
    if (!t || !t->texView.id) {
        targets.pool.release(got);
        return false;
    }
    PassDesc pd = pass_into(*t, "scene-copy");
    const sg_pipeline pipe = copy_pipeline(pd.format);
    if (!pipe.id) {
        targets.pool.release(got);
        return false;
    }
    pd.colorLoad = SG_LOADACTION_DONTCARE;  // every pixel is drawn
    pd.colorStore = SG_STOREACTION_STORE;
    Gpu::begin_pass(pd);
    sg_apply_pipeline(pipe);
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_water2d_src] = game.texView;
    b.samplers[SMP_water2d_src_smp] = gpu.sampler(SamplerKind::Nearest);
    sg_apply_bindings(&b);
    water2d_water2d_copy_params_t cu{};
    cu.origin[0] = float(x);
    cu.origin[1] = float(row);
    sg_range r{&cu, sizeof(cu)};
    sg_apply_uniforms(UB_water2d_water2d_copy_params, &r);
    sg_draw(0, 3, 1);
    Gpu::end_pass();
    handle = got;
    view = t->texView;
    return true;
}

bool WaterFx::draw(Gpu& gpu, const Fx2D& fx, std::uint32_t firstQuad, const DrawEnv& env) {
    if (!env.scene.id || !env.viewProj || !env.map || !ready()) return false;
    const sg_pipeline pipe = fx_pipeline(env.format, env.depthTest);
    if (!pipe.id) return false;
    sg_apply_pipeline(pipe);
    sg_bindings b{};
    b.vertex_buffers[0] = env.vertices;
    b.vertex_buffer_offsets[0] = int(std::size_t(firstQuad) * 4 * sizeof(Vertex2D));
    b.index_buffer = gpu.quad_index_buffer();
    b.views[VIEW_water2d_scene_tex] = env.scene;
    b.samplers[SMP_water2d_scene_smp] = gpu.sampler(SamplerKind::LinearClamp);
    sg_apply_bindings(&b);
    water2d_water2d_vs_params_t vu{};
    std::memcpy(vu.view_proj, env.viewProj->m, sizeof(vu.view_proj));
    sg_range vr{&vu, sizeof(vu)};
    sg_apply_uniforms(UB_water2d_water2d_vs_params, &vr);
    water2d_water2d_fs_params_t fu{};
    fu.area[0] = fx.origin[0];
    fu.area[1] = fx.origin[1];
    fu.area[2] = fx.up[0];
    fu.area[3] = fx.up[1];
    fu.shape[0] = fx.size[0];
    fu.shape[1] = fx.size[1];
    fu.shape[2] = fx.water ? 0.0f : 1.0f;
    fu.shape[3] = env.time;
    std::memcpy(fu.tint, fx.tint, sizeof(fu.tint));
    fu.wave[0] = fx.reflection;
    fu.wave[1] = fx.water ? fx.refraction : fx.strength;
    fu.wave[2] = fx.amplitude;
    fu.wave[3] = fx.length;
    fu.misc[0] = fx.speed;
    fu.target[0] = env.targetInv[0];
    fu.target[1] = env.targetInv[1];
    fu.target[2] = env.gl ? 1.0f : 0.0f;
    std::memcpy(fu.scene, env.map->scene, sizeof(fu.scene));
    std::memcpy(fu.world_uv, env.map->worldUv, sizeof(fu.world_uv));
    sg_range fr{&fu, sizeof(fu)};
    sg_apply_uniforms(UB_water2d_water2d_fs_params, &fr);
    sg_draw(0, 6, 1);
    return true;
}

void WaterFx::release() {
    for (PipelineEntry& e : copyPipelines_)
        if (e.pipeline.id) sg_destroy_pipeline(e.pipeline);
    for (PipelineEntry& e : fxPipelines_)
        if (e.pipeline.id) sg_destroy_pipeline(e.pipeline);
    copyPipelines_.clear();
    fxPipelines_.clear();
    if (copyShader_.id) sg_destroy_shader(copyShader_);
    if (fxShader_.id) sg_destroy_shader(fxShader_);
    copyShader_ = {};
    fxShader_ = {};
    state_ = 0;
}

}  // namespace fa::render
