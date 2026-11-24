// Renderer::Impl, part 3: draw_view_job and draw_job, the passes of one frame's jobs.
#include "color_space.h"
#include "light_clusters.h"
#include "light_layers.h"
#include "physical_sky.h"
#include "mesh_buffer_draw.h"
#include "renderer_impl.h"
#include "fa/scene/jitter.h"
#include "shadow_cascades.h"
#include "sprite_buffer_draw.h"
#include "water2d.h"

#include <algorithm>
#include <array>
#include <bit>
#include <functional>
#include <iterator>
#include <optional>
#include <string>

#include "shaders/prepass_view.glsl.h"

namespace fa {

using render::to_scene;

// ---------------------------------------------------------------------------
// The state of one draw_job, shared by its phases: what the lambdas of the former single function captured. Every phase
// says what it reads and what it writes (the declared reads and writes of a future frame-graph pass).
// ---------------------------------------------------------------------------

struct Renderer::Impl::Px {
    int x = 0, y = 0, w = 0, h = 0;
};

// What one part of an item is drawn with. A material that built uses its own programs; one that failed uses the engine's
// programs as the error material (unlit magenta, white textures, no emission).
struct Renderer::Impl::PartDraw {
    MaterialAsset* mat = nullptr;
    bool error = false;
    TextureAsset *tex = nullptr, *normal = nullptr, *mr = nullptr, *occlusion = nullptr, *emissive = nullptr;
    sg_view
        lightmap{};  // the lightmap page of the entity (view 26 of the engine's program); id 0 = none, a white texel is bound
};

// The packed params and textures of a custom material for one batch (its overrides are the same for every item).
struct Renderer::Impl::MaterialInputs {
    float params[kMaxMaterialParams][4];
    TextureAsset* textures[kMaxMaterialTextures]{};
    // A texture for the VERTEX stage's copy of a slot, where it differs from the fragment stage's (null = the same one). The terrain binds
    // its splat array to the fragment stage and the holes texture to the vertex stage of the same slot.
    TextureAsset* vsTextures[kMaxMaterialTextures]{};
};

// What draws the sky: the engine's own program (mat null) or a sky material (SceneSettings.skyMaterial) with its
// params, textures and the numbers of its uniform block. The main pass draws it into the picture and the environment
// bake (renderer_env.h) into the faces of a cube.
struct SkyDraw {
    MaterialAsset* mat = nullptr;
    const MaterialProgram* prog = nullptr;  // mat's program (null for the engine's)
    Renderer::Impl::MaterialInputs in{};
    float skyColor[3]{}, horizonColor[3]{}, sun[3]{0.0f, 1.0f, 0.0f};
    float time = 0.0f;
    bool linear = false;
    // The physical sky (SceneSettings.skyModel): the engine's own program for it, with its state; `slot` is the table it reads
    // (0 the picture's, 1 the environment's).
    bool physical = false, sunDisc = false;
    int slot = 0;
    PhysicalSkyState phys;
    // An HDRI (SceneSettings.environmentMap, renderer_hdri.h) instead of any of the above: its own program draws it.
    const HdriAsset* hdri = nullptr;
    float hdriRotation = 0.0f,
          hdriGain = 1.0f;  // degrees; the brightness (1 while the bake draws it: the bake's gain applies later)
};

// Holds references to the job's world and frame and a copy of its plan. It lives (Impl::jobContexts) from plan_job until the
// frame graph has run, because the callbacks of the job's passes use it; the world, the frame and the camera `plan.post`
// points to belong to the caller of plan_job, which keeps them until run_frame_graph().
// The sokol-shdc uniform blocks it holds are alignas(16): MSVC warns (C4324, an error under /WX) that the struct is padded.
#if defined(_MSC_VER)
#pragma warning(push)
#pragma warning(disable : 4324)
#endif
struct Renderer::Impl::DrawContext {
    DrawContext(World& w, Frame& f, const JobPlan& p) : world(w), fr(f), plan(p), post(*p.post) {}
    World& world;
    Frame& fr;
    const JobPlan plan;
    const CameraInfo& post;
    JobEnv env;  // the sizes and images the job's passes draw with (a view job's are not the game target's)
    // plan_job: the viewports and clears of this job
    // hudAfterBloom: the screen-space items are drawn over the glowing game target (PostProcess.bloomScreenSpace false, no final pass).
    // hudAfterPost: the final passes of the frame write hudTarget and the screen-space items are drawn over it, in display space.
    bool hudAfterBloom = false, hudAfterPost = false, msaa = false, z01 = false;
    // M76-P3a: the upscale stage draws the screen-space items after it, at the output size (hud-over-upscale), not into the game image.
    // hudDisplay: the final pass ran, so the picture holds display values and the items are drawn as in hudAfterPost.
    bool hudOut = false, hudDisplay = false;
    PostPlan
        postPlan;  // the post-processing stack of this job's camera (empty for the screen-only job and the view jobs)
    // Does this job begin the main pass? The screen-space job of a frame whose HUD goes over the bloom draws it after instead.
    bool doMainPass = false;
    Px fullPx, camPx;
    Gi2dJobPlan gi2d;  // gi2d_plan: the field this job's passes fill (inactive without an enabled GlobalIllumination2D)
    bool partial = false, clearByQuad = false, clearByLoad = false;
    // gather_meshes, collect_lights, shadow_bounds, cull_and_batch
    std::vector<MeshItem> opaque, blended;
    ImpostorDraws impostorDraws;           // gather_meshes: what the MeshItems of the impostor cards point at
    std::deque<TerrainDraw> terrainDraws;  // gather_meshes: what the MeshItems of the terrains' nodes point at
    std::vector<LightData> lights;
    // collect_decals: the decals of the view in drawing order, and every texture path the Decals of the world name (sorted, normalised).
    std::vector<DecalItem> decals;
    std::vector<std::string> decalPaths;
    int shadowLight = -1;
    Vec3 lightDirForShadow{0, -1, 0};
    bool haveShadowCaster = false;
    bool doShadows = false;
    // The sun's shadow (collect_lights, shadow_bounds): the light's own settings, the cascades planned for this job (their maps, where each
    // sits in the atlas and where each ends), the atlas this job draws into (a copy of the target: a later job may replace the renderer's
    // when it needs more room) and the block the mesh fragment shaders read (fill_shadow_block).
    struct SunShadow {
        int resolution = 0;
        float bias = 0.0f, normalBias = 0.0f, softness = 1.0f, distance = 0.0f;
        ShadowFilter filter = ShadowFilter::Pcf;
    } sun;
    int cascades = 0;
    std::array<render::CascadeFit, render::kMaxShadowCascades> fits;
    std::array<float, render::kMaxShadowCascades + 1> splits{};
    render::ShadowAtlasLayout atlas;
    // The shadows of the point and spot lights (shadow_bounds): the lights that got maps, and per tile of the atlas layout (view) the
    // matrix of its shadow pass. The views are the tiles of the layout in order: the cascades the sun asked for (sunViews of them, the
    // first `cascades` placed), then the tiles of localPlan.lights. A view with no map has an identity matrix and is never drawn.
    render::LocalShadowPlan localPlan;
    std::vector<render::LocalShadowInput>
        localInputs;                              // what each wanted (indices of the plan's `light` are table indexes)
    std::vector<render::LocalTileFit> localFits;  // per local tile, in the order of the layout from sunViews on
    std::vector<Mat4> viewProj;                   // per view
    int sunViews = 0;
    std::vector<render::ShadowRun> shadowRuns;  // the runs of every batch (MeshBatch::runFirst)
    long long localShadowBase = -1;             // upload_lights: the shadow region in the light data texture
    Target shadowTgt;
    mesh_fa_shadows_t shadowU{};
    // plan_prepass: this job declares the prepass (its image is a transient of the graph, PostPlan::prepass) and, with a debug view on,
    // the pass that paints it over the game image.
    bool doPrepass = false, debugPrepass = false;
    // M76 motion vectors: cull_and_batch keeps the previous model of every drawn instance (`prevMats`, uploaded to `prevInst`) when the camera
    // asks for the velocity image (collectPrev); plan_prepass decides whether the prepass writes it (doVelocity, build_graph makes the image).
    bool collectPrev = false, doVelocity = false;
    std::vector<PrevModelRows>
        prevRows;  // fill_prev_models: the previous model of every opaque item (MeshItem::prevIdx)
    std::vector<PrevModelRows> prevMats;  // build_batches: the same, one per drawn instance, in the order of mainMats
    sg_buffer prevInst{};
    // upload_prev_palettes (M76-P1c): the previous joint palettes of the skinned draws of the prepass in one RGBA32F image (`prevPalView`, empty = none);
    // `prevPalBase` has the first texel of the palette of (batch.rep, skin), key `prev_palette_key`. `prevPalTexels` is the CPU copy (capacity kept).
    sg_view prevPalView{};
    std::unordered_map<std::uint64_t, int> prevPalBase;
    std::vector<float> prevPalTexels;
    // fill_prev_models: whether the entities' histories count this frame (false after a cut: no motion of their own), and the game time of
    // the frame before in seconds, what a material's vertex() reads as fa_time.x in the prepass's second run (the time now after a cut).
    bool prevHistory = false;
    float prevTime = 0.0f;
    // M75.2b: the camera is culled with its depth pyramid (gather_meshes): plan_prepass draws the prepass for it and build_graph reduces it.
    HizCamera* hiz = nullptr;
    // M73.2c: a light has a contact shadow and the job has its prepass (plan_job), so the main pass binds the prepass at the screen slot
    // (view 28) of the opaque meshes; screenView is that image, set by main_pass (the transient exists from the graph's execution on).
    bool contactOn = false;
    sg_view screenView{};
    // M73-P6b: a visible blended draw is transmissive. plan_job sets `want` when the copy can be made (renderer_xmit.h); main_pass splits the pass
    // after the opaque phase, makes the atlas and sets `on` (the blended draws bind `atlasView` at view 28 and refract) and `levels`. `want`
    // without `on` (the copy failed at run time) draws the plain blend.
    struct {
        bool want = false, on = false;
        int levels = 0;
        sg_view atlasView{};
    } xmit;
    // M74.4: the picture drawn so far, which Water2D, DistortionZone2D and the sprite materials that call fa_scene_color() read (water2d.h).
    // main_pass plans the copies before the pass begins (`copyAt`: the batches of the world group a copy is made before); draw_group makes
    // them, and `view` is the latest copy while the world group is drawn (`live`). Nothing is planned, copied or held without such a batch.
    struct {
        bool live = false;
        std::vector<std::uint32_t> copyAt;
        std::size_t next = 0;
        std::uint64_t handle = 0;  // the pooled image of the latest copy (0 = none)
        sg_view view{};
        SceneMap map;
        sg_store_action finalStore = SG_STOREACTION_STORE;
        TargetFormat format;
    } sceneCopy;
    // M73.5: a mesh of this camera scatters light (MeshRenderer.subsurface) and the camera can draw it (plan_job): the job declares the "sss-draw" pass
    // (sss_draw_pass), the stack the blur and add passes (SssFx), and the scene uniforms carry the camera's view for the shader's visibility test.
    bool sssOn = false;
    // plan_outline: this job declares the sprite-coverage pass (PostPlan::coverage) for a sprite outline.
    bool doCoverage = false;
    std::vector<MeshBatch> opaqueBatches, blendedBatches;
    std::vector<Mat4> mainMats, shadowMats;
    std::vector<float> mainExtraData,
        shadowExtraData;  // the per-instance params of the batches that have them (MeshBatch::mainExtra)
    // build_quad_stream
    struct Group {
        std::vector<QuadBatch> batches;
    };
    Group gClear, gWorld, gDebugWorld, gScreen, gDebugScreen;
    std::size_t lineFirst = 0;
    sg_buffer vbuf{};
    sg_buffer
        vinst{};  // the instanced params of the sprite-material batches, per vertex (vertex buffer 1 of their pipelines)
    Mat4 screenProj;
    // upload_instances
    sg_buffer mainInst{}, shadowInst{};
    sg_buffer mainExtra{},
        shadowExtra{};  // the per-instance params of mainExtraData / shadowExtraData (vertex buffer 3)
    // scene_uniforms
    SceneSettings ss;
    TextureAsset* white = nullptr;
    // The light data texture of the job's view (scene_uniforms): bound at view 24 of the mesh programs; the white image while the job
    // has no lights or draws no mesh.
    sg_view lightView{};
    // The light atlas image the lights of this job's view were laid out in (collect_lights); empty = none (view 25 binds the white image).
    sg_view lightAtlasView{};
    // The atlas of the decal textures (view 27 of the mesh programs): the renderer's, once this job has decals to draw; else the white image.
    sg_view decalView{};
    mesh_fa_mesh_vs_params_t vuScene{};
    mesh_fa_mesh_fs_params_t fuScene{};
    // fuScene with the camera's stack fog (PostProcess.fog*): the blended meshes fog themselves with it, while the opaque meshes and the sky
    // are fogged by the full-screen draw (fuScene has no fog then). Equal to fuScene when the camera has no stack fog.
    mesh_fa_mesh_fs_params_t fuBlend{};
    // plan_env: the meshes of this job take the baked sky (SceneSettings.skyMaterial): the "sky-env" pass is declared
    // when envBake, and envSky is what it draws (the time quantized, see plan_env).
    bool envActive = false, envBake = false;
    // The physical sky: envSliced = this frame runs a slice of a bake (renderer_env.h, bake_slice), not a whole one; envStatic and
    // envSun are what a bake started from this job is tagged with (plan_env); physMainOn = the main pass draws the physical sky
    // with the state physMain (exact sun and clock, the picture's table), physSunDir / physSunColor = the sun as collect_lights
    // found it, before the sky tinted its light.
    bool envSliced = false, physMainOn = false;
    bool physSunOn =
        false;  // a directional light is the sun of this view (physSunDir / physSunColor are its): else no sun disc
    std::uint64_t envStatic = 0;
    float envSun[3]{0.0f, 1.0f, 0.0f};
    PhysicalSkyState physMain;
    float physSunDir[3]{0.0f, 1.0f, 0.0f}, physSunColor[3]{1.0f, 1.0f, 1.0f};
    std::uint64_t envKey = 0;
    SkyDraw envSky;
    // What the next bake of this job does with the sky (Environment::set_look): SceneSettings.environmentIntensity, and the limit
    // of one sample of the convolutions (an HDRI's, 0 for any other sky).
    float envGain = 1.0f, envTap = 0.0f;
    float envRotation = 0.0f;  // degrees, finite and inside (-360, 360): what the key and both draws of the HDRI use
    // plan_env: the HDRI the main pass draws as the background (SceneSettings.environmentMap with environmentBackground, no sky material),
    // null when it draws anything else.
    const HdriAsset* hdriMain = nullptr;
    // The textures plan_env resolved for the sky of the job, while the job's own render target was the checker: the sky
    // of the main pass draws with them (resolving them again when the pass runs would bind the target the pass writes).
    // Valid for skyPlannedMat.
    TextureAsset* skyPlanned[kMaxMaterialTextures]{};
    MaterialAsset* skyPlannedMat = nullptr;
    // build_graph: the occlusion image the main pass applies after the opaque meshes (valid when the "ssao-*" passes were declared).
    SsaoApply ssaoApply;
    // light_pass
    int litMode = 0;
    sg_view shadowRowsTex{};
    // light_plan (M74): the light buffer each layer mask of the flat lit visuals reads, and the cookies of the frame's lights (the
    // textures by atlas cell, and the atlas image while there are any).
    LightLayerPlan layerPlan;
    std::vector<TextureAsset*> cookieCells;
    sg_view cookieView{};
};
#if defined(_MSC_VER)
#pragma warning(pop)
#endif

namespace {

void copy_mat(float* dst, const Mat4& m) { std::memcpy(dst, m.m, sizeof(float) * 16); }

// Does this opaque mesh scatter light (MeshRenderer.subsurface above 0)? Only a mesh drawn by the engine's own program does: a material brings
// its own lighting, and the sss variant of the shader (mesh_common.glsl, fs_sss) is of the engine's template.
bool sss_scatters(const MeshItem& mi) { return mesh_scatters(*mi.mr, mi.material, false); }

// The block the mesh fragment shaders read the sun's cascaded shadow from (fa_shadows of shadow_common.glsl): where each cascade's map is in
// the atlas image this job draws into (the matrix that takes a world position to the atlas's u, v and a 0..1 depth, the tile's rectangle
// a texel smaller, the map's size), where the cascades end along the camera's forward axis, the filter and the biases. Empty (zero
// cascades: the shader returns light) when the job draws no shadow. `debug`: the cascade debug view tints the picture.
void fill_shadow_block(const Renderer::Impl::DrawContext& ctx, bool isGl, bool debug, mesh_fa_shadows_t& u) {
    u = mesh_fa_shadows_t{};
    const CameraInfo& cam = ctx.fr.cam;
    u.fa_shadow_eye[0] = cam.position.x;
    u.fa_shadow_eye[1] = cam.position.y;
    u.fa_shadow_eye[2] = cam.position.z;
    u.fa_shadow_eye[3] = debug ? 1.0f : 0.0f;
    if (!ctx.doShadows || !ctx.shadowTgt.color.id) return;
    const int count = ctx.cascades;
    const int w = ctx.shadowTgt.w, h = ctx.shadowTgt.h;
    // The texel size of the atlas: the filters of the sun and of the local lights both read it.
    u.fa_shadow_bias[2] = 1.0f / float(w);
    u.fa_shadow_bias[3] = 1.0f / float(h);
    if (count <= 0)
        return;  // no sun cascade (fa_shadow_cfg.x = 0: the sun is lit); the local lights' base is set with the light texture
    for (int c = 0; c < render::kMaxShadowCascades; ++c) {
        const std::size_t i = std::size_t(c);
        u.fa_shadow_split[c] =
            ctx.splits[std::size_t(std::min(c + 1, count))];  // an unused cascade ends where the last does
        if (c >= count) continue;
        const render::ShadowTile& tile = ctx.atlas.tiles[i];
        copy_mat(u.fa_shadow_mat[c], render::shadow_sample_matrix(ctx.fits[i], tile, w, h, ctx.z01, isGl));
        const Vec4 r = render::shadow_tile_rect(tile, w, h, isGl);
        const float tu = 1.0f / float(w), tv = 1.0f / float(h);
        u.fa_shadow_rect[c][0] = r.x + tu;
        u.fa_shadow_rect[c][1] = r.y + tv;
        u.fa_shadow_rect[c][2] = r.z - tu;
        u.fa_shadow_rect[c][3] = r.w - tv;
        u.fa_shadow_info[c][0] = ctx.fits[i].texel;
        u.fa_shadow_info[c][1] = ctx.fits[i].depthRange;
    }
    const float soft = std::clamp(ctx.sun.softness, 0.0f, 10.0f);
    u.fa_shadow_cfg[0] = float(count);
    u.fa_shadow_cfg[1] = std::clamp(ctx.ss.shadowCascadeBlend, 0.0f, 0.5f);
    u.fa_shadow_cfg[2] = ctx.sun.filter == ShadowFilter::Hard   ? 1.0f
                         : ctx.sun.filter == ShadowFilter::Pcss ? 2.0f
                                                                : 0.0f;
    u.fa_shadow_cfg[3] = std::tan(0.05f * soft);
    u.fa_shadow_bias[0] = std::clamp(ctx.sun.bias, 0.0f, 1.0f);
    u.fa_shadow_bias[1] = std::clamp(ctx.sun.normalBias, 0.0f, 1.0f);
    u.fa_shadow_fwd[0] = cam.forward.x;
    u.fa_shadow_fwd[1] = cam.forward.y;
    u.fa_shadow_fwd[2] = cam.forward.z;
    u.fa_shadow_fwd[3] = ctx.splits[0];
}

// The joint palette as the shaders read it: kMaxSkinJoints skinning matrices of 3 rows (a vec4 each); unused joints are the
// identity (fa_skin of mesh_common.glsl, shared by the mesh and shadow programs).
mesh_fa_skin_t pack_palette(const std::vector<Mat4>& palette) {
    mesh_fa_skin_t u{};
    for (int j = 0; j < kMaxSkinJoints; ++j) {
        const Mat4 m = std::size_t(j) < palette.size() ? palette[std::size_t(j)] : Mat4::identity();
        for (int r = 0; r < 3; ++r)
            for (int c = 0; c < 4; ++c) u.fa_joint_rows[j * 3 + r][c] = m.at(c, r);
    }
    return u;
}

// The key of the previous palette of skin `skin` of the item at `item` (an index into DrawContext::opaque) in DrawContext::prevPalBase.
std::uint64_t prev_palette_key(std::size_t item, int skin) {
    return (std::uint64_t(item) << 8) | std::uint64_t(std::uint8_t(skin));
}

using MaterialInputs = Renderer::Impl::MaterialInputs;
using Px = Renderer::Impl::Px;

// How an imported target shows in the graph's dumps.
TransientDesc import_desc(int w, int h, const TargetFormat& format, const char* label) {
    TransientDesc d;
    d.width = w;
    d.height = h;
    d.format = format;
    d.label = label;
    return d;
}

// Puts a job's JobEnv in place while one of its passes runs, and the previous one back after (also when the pass throws).
struct EnvScope {
    Renderer::Impl& im;
    Renderer::Impl::JobEnv saved;
    EnvScope(Renderer::Impl& i, const Renderer::Impl::JobEnv& env) : im(i), saved(i.job_env()) { im.set_job_env(env); }
    ~EnvScope() { im.set_job_env(saved); }
    EnvScope(const EnvScope&) = delete;
    EnvScope& operator=(const EnvScope&) = delete;
};

// The rectangle of a fraction of the target (see Px).
Px px_rect(const Rect& v, int W, int H) {
    const int x0 = std::clamp(int(std::lround(double(v.x) * W)), 0, W),
              y0 = std::clamp(int(std::lround(double(v.y) * H)), 0, H);
    const int x1 = std::clamp(int(std::lround(double(v.x + v.w) * W)), x0, W),
              y1 = std::clamp(int(std::lround(double(v.y + v.h) * H)), y0, H);
    return Px{x0, y0, x1 - x0, y1 - y0};
}

void apply_view(const Px& r) {
    sg_apply_viewport(r.x, r.y, r.w, r.h, true);
    sg_apply_scissor_rect(r.x, r.y, r.w, r.h, true);
}

// The glTF base color factor of a part, or the MeshRenderer.materialColors entry for its material name.
// `authored` is set when the colour comes from materialColors (picked by eye, sRGB) rather than from the model (glTF: linear).
Color part_base_color(const MeshRenderer& mr, const SubMesh& part, bool* authored = nullptr) {
    if (authored) *authored = false;
    if (!part.materialName.empty() && mr.materialColors.is_object()) {
        auto it = mr.materialColors.find(part.materialName);
        if (it != mr.materialColors.end() && it->is_array() && it->size() >= 3 && it->size() <= 4) {
            float v[4] = {1, 1, 1, 1};
            for (std::size_t i = 0; i < it->size(); ++i) {
                if (!(*it)[i].is_number()) return part.baseColor;  // validate reports it; the part keeps its own colour
                v[i] = (*it)[i].get<float>();
            }
            if (authored) *authored = true;
            return Color{v[0], v[1], v[2], v[3]};
        }
    }
    return part.baseColor;
}

// The material's params (fa_material_vs, fa_material), when the program declares them.
void apply_material_params(const MaterialProgram& prog, const MaterialInputs& in) {
    for (int slot : {kMaterialUbVertex, kMaterialUbFragment}) {
        if (!prog.has_ub(slot)) continue;
        sg_range r{in.params, std::min<std::size_t>(prog.ubSize[slot], sizeof(in.params))};
        sg_apply_uniforms(slot, &r);
    }
}
// What draws the sky of the job (its ss is in scene space): `mat` is the sky material sky_material accepted, or nullptr
// for the engine's gradient. The sun is the directional light of slot 0, up when the scene has none; the time is the
// job's (fuScene.fa_time).
void fill_sky(Renderer::Impl& im, const Renderer::Impl::DrawContext& ctx, MaterialAsset* mat, SkyDraw& d) {
    const SceneSettings& ss = ctx.ss;
    d = SkyDraw{};
    d.mat = mat;
    d.prog = mat ? &mat->programs[0] : nullptr;  // sky_material checked it has a shader
    if (d.prog) {
        pack_material_params(*mat, ss.skyMaterialParams, d.in.params, "skyMaterialParams", "SceneSettings");
        for (std::size_t i = 0; i < mat->textures.size(); ++i) {
            const int view = kMaterialSkyFirstView + int(i), smp = kMaterialSkyFirstSampler + int(i);
            if (!((d.prog->viewMask >> view) & 1u) || !((d.prog->samplerMask >> smp) & 1u)) continue;
            d.in.textures[i] =
                material_texture(*mat, int(i), ss.skyMaterialParams, *im.assets, "skyMaterialParams", "SceneSettings");
        }
    }
    d.skyColor[0] = ss.skyColor.r;
    d.skyColor[1] = ss.skyColor.g;
    d.skyColor[2] = ss.skyColor.b;
    d.horizonColor[0] = ss.horizonColor.r;
    d.horizonColor[1] = ss.horizonColor.g;
    d.horizonColor[2] = ss.horizonColor.b;
    if (!ctx.fr.cam.studio && !ctx.lights.empty()) {
        const LightData& l = ctx.lights[0];
        if (l.color.w == 0.0f && l.pos.w == 0.0f) {
            d.sun[0] = l.pos.x;
            d.sun[1] = l.pos.y;
            d.sun[2] = l.pos.z;
        }
    }
    d.time = d.prog ? ctx.fuScene.fa_time[0] : 0.0f;
    d.linear = ctx.fr.linear;
}

// Draws the sky as a full-screen triangle into the open pass: `invViewProj` (column-major) and `camPos` place the rays;
// `format`, when given, is the format of the pass's colour image (the environment bake's cube faces), else the scene's.
void draw_sky(Renderer::Impl& im, const SkyDraw& d, const float* invViewProj, const Vec3& camPos,
              const TargetFormat* format) {
    Gpu& gpu = im.gpu;
    if (d.hdri) {
        const float cam[3] = {camPos.x, camPos.y, camPos.z};
        im.hdriSky.draw(gpu, *d.hdri, d.hdriRotation, d.hdriGain, !d.linear, invViewProj, cam, format);
        return;
    }
    if (d.physical) {
        const float cam[3] = {camPos.x, camPos.y, camPos.z};
        im.physSky.draw(gpu, d.slot, d.phys, d.sunDisc, invViewProj, cam, format);
        return;
    }
    const sg_shader shader = d.prog ? d.prog->shader : sg_shader{};
    sg_apply_pipeline(format ? gpu.sky_pipeline(*format, shader) : gpu.sky_pipeline(shader));
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    if (d.prog)
        for (std::size_t i = 0; i < d.mat->textures.size(); ++i) {
            if (!d.in.textures[i]) continue;
            b.views[kMaterialSkyFirstView + int(i)] = d.in.textures[i]->gpu_view();
            b.samplers[kMaterialSkyFirstSampler + int(i)] = gpu.sampler(d.mat->textures[i].sampler);
        }
    sg_apply_bindings(&b);
    sky_sky_vs_params_t vu{};
    std::memcpy(vu.inv_view_proj, invViewProj, sizeof(float) * 16);
    vu.cam_pos[0] = camPos.x;
    vu.cam_pos[1] = camPos.y;
    vu.cam_pos[2] = camPos.z;
    apply_uniforms(UB_sky_sky_vs_params, vu);
    sky_sky_fs_params_t fu{};
    for (int c = 0; c < 3; ++c) {
        fu.sky_color[c] = d.skyColor[c];
        fu.horizon_color[c] = d.horizonColor[c];
        fu.fa_sun[c] = d.sun[c];
    }
    fu.sky_color[3] = 1;
    fu.horizon_color[3] = 1;
    fu.fa_time[0] = d.time;
    fu.fa_cspace[0] = d.linear ? 1.0f : 0.0f;
    apply_uniforms(UB_sky_sky_fs_params, fu);
    if (d.prog) apply_material_params(*d.prog, d.in);
    sg_draw(0, 3, 1);
}

// The same for the block a 2D item's MaterialUse holds.
void apply_use_params(const MaterialProgram& prog, const MaterialUse& use) {
    for (int slot : {kMaterialUbVertex, kMaterialUbFragment}) {
        if (!prog.has_ub(slot)) continue;
        sg_range r{use.params, std::min<std::size_t>(prog.ubSize[slot], sizeof(use.params))};
        sg_apply_uniforms(slot, &r);
    }
}
bool declares(const MaterialProgram* prog, int ub) { return !prog || prog->has_ub(ub); }

}  // namespace

Renderer::Impl::JobEnv Renderer::Impl::job_env() const {
    JobEnv e;
    e.targetW = targetW;
    e.targetH = targetH;
    e.physW = physW;
    e.physH = physH;
    e.colorAtt = gameTarget.colorAtt;
    e.resolveAtt = gameTarget.resolveAtt;
    e.depthAtt = gameTarget.depthAtt;
    return e;
}

void Renderer::Impl::set_job_env(const JobEnv& e) {
    targetW = e.targetW;
    targetH = e.targetH;
    physW = e.physW;
    physH = e.physH;
    gameTarget.colorAtt = e.colorAtt;
    gameTarget.resolveAtt = e.resolveAtt;
    gameTarget.depthAtt = e.depthAtt;
}

// Declares a CameraView's (or a render target's) camera in the frame graph, drawing into the view's image: the pass(es) of
// plan_job with the image in the place of the game target. The image is an imported resource that later jobs read
// (jobImages). No post effects (the frame's are those of the cameras on the screen), no 2D light buffer. While the job is planned and
// while its passes run, the renderer's sizes and game images are the view's (the job's JobEnv).
void Renderer::Impl::plan_view_job(World& world, Frame& fr, ViewTarget& target, std::uint64_t key, JobPlan plan) {
    static const CameraInfo noPost;  // bloom off, no colour filter
    const JobEnv saved = job_env();
    JobEnv env = saved;
    env.targetW = env.physW = target.w;
    env.targetH = env.physH = target.h;
    env.colorAtt = target.main.colorAtt;
    env.resolveAtt = target.main.resolveAtt;
    env.depthAtt = target.main.depthAtt;
    set_job_env(env);
    JobImage image;
    image.drawn = graph.import_target(plan.name, target.main.colorAtt.id,
                                      import_desc(target.w, target.h, target.main.format, "view"));
    image.shown = image.drawn;
    // "flipped:" + the job's name: no job name starts that way, so no render target's name can clash.
    if (target.flipCopy)
        image.shown = graph.import_target("flipped:" + plan.name, target.flip.color.id,
                                          import_desc(target.w, target.h, target.flip.format, "target-flipped"));
    jobImages[key] = image;
    plan.first = true;
    plan.last = false;
    plan.view = true;
    plan.post = &noPost;
    plan.image = image.drawn;
    if (plan.customPost) plan.target = &target.main;
    plan_job(world, fr, plan);
    set_job_env(saved);
    if (target.flipCopy) {
        // GL stores a render target bottom-up: the picture is copied the right way up into the image the texture samples.
        GraphPass p;
        p.name = plan.name + "/flip";
        p.reads = {image.drawn};
        p.writes = {image.shown};
        ViewTarget* t = &target;
        p.execute = [this, t](const PassContext&) { flip_copy(*t); };
        graph.add_pass(std::move(p));
    }
}

// Starts the frame graph of a frame: nothing declared, no job yet.
void Renderer::Impl::begin_frame_graph(bool countPost) {
    if (!passHooksSet) {
        passHooksSet = true;
        // Every pass is a GPU timestamp pair while the GPU timer measures the frame (the profiler is on) and a zone of the
        // profiler named `<job>/<pass>`. begin_pass and end_pass do nothing outside a measured frame.
        PassHooks hooks;
        hooks.begin = [this](const std::string& pass) {
            if (Profiler::on()) gpuTimer.begin_pass(pass);
        };
        hooks.end = [this](const std::string& pass, double cpuMs) {
            gpuTimer.end_pass();
            if (Profiler::on()) Profiler::get().add_zone(pass, cpuMs);
        };
        graph.set_pass_hooks(std::move(hooks));
    }
    graph.clear();
    jobContexts.clear();
    postCams.clear();
    frameJobs.clear();
    jobImages.clear();
    release_idle_ldr_targets();
    customPost.sweep_history(frameSerial);
    ++frameSerial;
    framePost = countPost;
    if (countPost) ++postSerial;
    trim_shadow_rows();
    free_retired_shadow_targets();  // the frame before has run its graph
    lightAtlas.free_retired();
    free_retired_decal_atlases();
    sharedGame = sharedLight = sharedShadow = sharedEnv = sharedSkyLut = sharedCookie = ResourceId{};
    gi2d.begin_frame(!countPost);
}

// Orders, culls and runs every pass of the frame (frame_graph.h), then drops what the pass callbacks captured: the job contexts
// and the references they hold are gone with the frame. A graph that cannot be compiled or run is logged once and draws
// nothing.
void Renderer::Impl::run_frame_graph() {
    // The first error of a graph is logged (the rest of the run, nothing), and it names the frame and its jobs: the message
    // of the graph names the pass (`<job>/<pass>`), and the jobs say what else was in the frame.
    auto report = [&](const Error& e, bool running) {
        if (warnedGraph) return;
        warnedGraph = true;
        std::string jobs;
        for (const std::string& j : frameJobs) jobs += (jobs.empty() ? "" : ", ") + j;
        // A graph that does not compile draws nothing; one that fails while it runs has drawn the passes before the failure.
        FA_ERROR("render", "Frame {} (jobs: {}) {}: {} {}", frameSerial, jobs.empty() ? "none" : jobs,
                 running ? "cannot be drawn completely" : "draws nothing", e.message, e.hint);
    };
    gi2d.free_unused();  // a frame without GlobalIllumination2D keeps no image of the field
    if (beforeFrameGraph) beforeFrameGraph();
    if (Result<void> r = graph.compile(); !r)
        report(r.error(), false);
    else if (Result<void> e = graph.execute(transient_targets().pool); !e)
        report(e.error(), true);
    graph.release_callbacks();
    jobContexts.clear();
    postCams.clear();
}

void Renderer::Impl::pass_times(std::vector<RenderStats::PassTime>& passes,
                                std::vector<RenderStats::JobTime>& jobs) const {
    passes.clear();
    jobs.clear();
    const bool gpuOn = Profiler::on();
    const std::vector<GpuTimer::PassTime>& gpuPasses = gpuTimer.last_passes();
    for (const PassStats& st : graph.stats()) {
        if (st.culled) continue;
        RenderStats::PassTime pt;
        pt.name = st.name;
        // A pass is `<job>/<pass>` and the pass part never has a '/', while a render target's name may.
        const std::size_t slash = st.name.rfind('/');
        pt.job = slash == std::string::npos ? std::string() : st.name.substr(0, slash);
        pt.cpuMs = st.cpuMs;
        if (gpuOn) {
            for (const GpuTimer::PassTime& g : gpuPasses) {
                if (g.name == st.name) {
                    pt.gpuMs = g.ms;
                    break;
                }
            }
        }
        RenderStats::JobTime* job = nullptr;
        for (RenderStats::JobTime& j : jobs) {
            if (j.job == pt.job) {
                job = &j;
                break;
            }
        }
        if (!job) {
            jobs.emplace_back();
            job = &jobs.back();
            job->job = pt.job;
        }
        ++job->passes;
        job->cpuMs += pt.cpuMs;
        if (pt.gpuMs >= 0.0) job->gpuMs = std::max(job->gpuMs, 0.0) + pt.gpuMs;
        passes.push_back(std::move(pt));
    }
}

// Declares one job of the frame in the frame graph: the pass(es) of one camera's world (and, for the single full-screen
// camera, the screen-space items too), or the screen-space pass of a split frame. The last job also gets the post effects.
// The CPU phases below (gather, cull, batch, upload, uniforms) run now, in the order the jobs are declared; what they decided
// stays in the job's DrawContext, which the pass callbacks use when run_frame_graph() runs the graph.
void Renderer::Impl::plan_job(World& world, Frame& fr, const JobPlan& plan) {
    frameJobs.push_back(plan.name);
    std::shared_ptr<DrawContext> owner = std::make_shared<DrawContext>(world, fr, plan);
    jobContexts.push_back(owner);  // a shared_ptr<void> keeps the type incomplete outside this file
    DrawContext& ctx = *owner;
    ctx.env = job_env();
    ctx.fullPx = Px{0, 0, physW, physH};
    ctx.camPx = fr.wantWorld ? px_rect(fr.cam.viewport, physW, physH) : ctx.fullPx;
    const bool draws = !plan.view && fr.wantWorld && ctx.camPx.w > 0 && ctx.camPx.h > 0;
    // The frame's bloom and colour filter are those of the camera that draws first (a camera whose rectangle has no pixel does not count);
    // a job before any camera drew, or a view job, uses the plan's.
    const CameraInfo& frameCam = plan.view || postCams.empty() ? (draws ? fr.cam : ctx.post) : postCams.front()->fr.cam;
    ctx.hudAfterBloom = frameCam.bloom.enabled && frameCam.bloom.intensity > 0.0f && !frameCam.bloom.screenSpace;
    ctx.partial = fr.wantWorld && !fr.cam.fullViewport();
    // A camera that clears and is not the first one (or the only one) cannot use a load action (it clears the whole target,
    // not its rectangle): a colour quad over its viewport does it.
    ctx.clearByQuad = fr.wantWorld && fr.cam.clear && ctx.partial && !plan.first;
    ctx.clearByLoad = fr.wantWorld && fr.cam.clear && (plan.first || !ctx.partial);
    ctx.z01 = gpu.depth_zero_to_one();
    ctx.msaa = gpu.sample_count() > 1;
    ctx.doMainPass = fr.wantWorld || !ctx.hudAfterBloom;
    // Every camera that draws the world has its own plan (its stack, its rectangle of the picture); a rectangle with no pixel draws
    // nothing and has none. Bloom and the colour filter are the frame's, from the camera that draws first (ctx.post).
    if (draws) {
        PostPlan& pp = ctx.postPlan;
        pp = make_post_plan(fr.cam, world.settings().colorSpace == ColorSpace::Linear, forceEffects, world.frame(),
                            renderScale, &frameCam);
        if (!(ctx.camPx.x == 0 && ctx.camPx.y == 0 && ctx.camPx.w == physW && ctx.camPx.h == physH))
            pp.rect = PostRect{ctx.camPx.x, ctx.camPx.y, ctx.camPx.w, ctx.camPx.h};
        if (debugView ==
            DebugView::
                Ao) {  // the occlusion alone: the camera's own settings or the defaults, and the prepass it reads
            pp.ssao = ssao_debug_settings(pp.ssao);
            pp.needsDepth = pp.needsNormals = true;
        }
        if (debugView == DebugView::MotionVectors || forceVelocity)
            pp.request_velocity();  // the debug view and the test hook
        if (pp.fx.grain)
            pp.fx.grainSeed =
                grain_seed_for_camera(pp.fx.grainSeed, int(postCams.size()));  // not the same grain per half
        postCams.push_back(&ctx);
        // The camera's view-projection of the frame before, for the effects that reproject (motion blur); one entry per camera, and the
        // cameras that were not drawn last frame are forgotten.
        const std::uint64_t camKey = fr.cam.entity.bits();
        int histJob = 0;  // which job of this camera in this frame (the custom passes' histories are one per job)
        // Counted in the frames of the game (postSerial): a capture_world between two of them neither reads nor writes the matrices,
        // so the next frame still reprojects from the one before the capture.
        // A second job of the same camera in the same frame (entry.frame == postSerial) takes what the first one took. A world frame
        // that went back, or more than 8 simulation ticks ahead, is a cut (a scene loaded, a seek): no blur across it.
        const auto prev = prevViewProj.find(camKey);
        if (prev != prevViewProj.end() && framePost) {
            const PrevCamera& e = prev->second;
            if (e.frame == postSerial) {
                if (e.hadBefore) {
                    pp.prevViewProj = e.before;
                    pp.prevJitteredViewProj = e.beforeJittered;
                    pp.prevJitterPx = e.beforeJitterPx;
                    pp.prevValid = true;
                }
            } else if (e.frame + 1 == postSerial && world.frame() >= e.worldFrame &&
                       world.frame() - e.worldFrame <= 8) {
                pp.prevViewProj = e.viewProj;
                pp.prevJitteredViewProj = e.jittered;
                pp.prevJitterPx = e.jitterPx;
                pp.prevValid = true;
            }
        }
        // The jitter this camera drew with (zero while it does not jitter) and, in NDC, of the frame before.
        {
            const Vec2 sizePx{float(std::max(ctx.camPx.w, 1)), float(std::max(ctx.camPx.h, 1))};
            pp.jitterPx = fr.cam.jitterPx;
            pp.jitterNdc = fr.cam.jitterNdc;
            pp.prevJitterNdc = jitter_pixels_to_ndc(pp.prevJitterPx, sizePx.x, sizePx.y);
        }
        if (fr.cam.postStack)
            pp.ssr = make_ssr_plan(fr.cam, *fr.cam.postStack);  // screen-space reflections (renderer_ssr.h)
        if (framePost) {
            PrevCamera& now = prevViewProj[camKey];
            if (now.frame != postSerial) {  // the first job of the camera this frame
                now.before = pp.prevViewProj;
                now.beforeJittered = pp.prevJitteredViewProj;
                now.beforeJitterPx = pp.prevJitterPx;
                now.hadBefore = pp.prevValid;
                now.viewProj = fr.cam.viewProj;
                now.jittered = fr.cam.drawViewProj;
                now.jitterPx = fr.cam.jitterPx;
                now.frame = postSerial;
                now.worldFrame = world.frame();
                now.jobs = 0;
            } else {
                ++now.jobs;
            }
            histJob = now.jobs;
            for (auto it = prevViewProj.begin(); it != prevViewProj.end();)
                it = it->second.frame + 1 < postSerial ? prevViewProj.erase(it) : std::next(it);
        }
        // Depth of field and motion blur (renderer_dof.h): the focus of this camera for the frame, the matrices of its movement.
        if (fr.cam.postStack)
            pp.sceneFx = sceneFx.plan(world, fr.cam, *fr.cam.postStack, camKey, postSerial, fr.dt, renderScale,
                                      pp.prevViewProj, pp.prevValid);
        // Temporal antialiasing (renderer_taa.h): the matrices that reproject the history and what decides whether it still holds. The scene's
        // identity (a load or a reload drops the history) is hashed only for a camera that asks for the effect.
        if (fr.cam.postStack) {
            const bool wantsTaa = fr.cam.postStack->has(PostEffect::TemporalAA);
            const std::uint64_t taaScene =
                wantsTaa ? std::hash<std::string>{}(world.scene_path()) * 1099511628211ull + world.scene_generation()
                         : 0;
            pp.taa = make_taa_plan(fr.cam, *fr.cam.postStack, framePost, !taa.unavailable(), camKey, postSerial,
                                   taaScene, originShifts, pp.prevViewProj, pp.prevValid);
        }
        // M76-P4: the temporal upscaler resolves this camera's jittered picture into the output image (renderer_taa.h, TaaFx::upscale), so the
        // camera's own TemporalAA is not drawn (its fields still tune the upscaler). One history, one resolve: the camera is the frame's only one.
        if (temporalFrame && !plan.view && framePost) {
            const std::uint64_t scene =
                std::hash<std::string>{}(world.scene_path()) * 1099511628211ull + world.scene_generation();
            upscaleTaa =
                make_upscale_taa_plan(fr.cam, fr.cam.postStack.get(), framePost, !taa.unavailable(), upscaler.sharpness,
                                      postSerial, scene, originShifts, pp.prevViewProj, pp.prevValid);
            if (upscaleTaa.on) pp.taa = TaaPlan{};
        }
        // The custom post passes (renderer_custom_post.h): the materials of PostProcess.customPasses that built. One
        // that did not is left out here, named in stats.materialFallbacks and logged once.
        if (fr.cam.postStack && fr.cam.postStack->has_custom())
            pp.custom = make_custom_post_plan(*fr.cam.postStack, *assets, stats.materialFallbacks, warnedCustomPass);
        // What the passes that read their own output of the frame before need to know (renderer_custom_post.h,
        // CustomHistoryFrame). The scene's hash only matters to a pass that keeps a history: a frame without one does
        // not hash the path.
        const std::uint64_t sceneKey =
            pp.custom.any_history()
                ? std::hash<std::string>{}(world.scene_path()) * 1099511628211ull + world.scene_generation()
                : 0;
        pp.custom.history = {camKey, histJob, postSerial, frameSerial, sceneKey, pp.prevValid, framePost};
        // The passes after the tonemap cut the final pass in pieces, which go through two images of their own; without
        // those the passes are not drawn (logged once) and the final pass stays whole.
        if (pp.custom.any()) pp.settle_custom();
        if (pp.customLdr) {
            // One cut needs one image, two or more need both (the pieces alternate); none (nothing is drawn before the
            // places) needs none.
            const int cuts = std::popcount(pp.ldr_cuts());
            if (!ensure_ldr_targets(cuts >= 2 ? 2 : cuts)) pp.drop_custom_ldr();
        }
        // A depth of field with no blur, and a motion blur with nothing to smear (the first frame, a cut, a still camera's null
        // intensity), draw nothing: they must not ask for a prepass. A forced effect (tests) and the AO debug view keep theirs.
        if (debugView != DebugView::Ao) {
            std::uint32_t drop = 0;
            if (!pp.sceneFx.dof) drop |= 1u << int(PostEffect::DepthOfField);
            if (!pp.sceneFx.motion) drop |= 1u << int(PostEffect::MotionBlur);
            if (!pp.taa.on)
                drop |=
                    1u << int(PostEffect::TemporalAA);  // a frame that cannot resolve (a capture) needs no depth for it
            drop &= ~forceEffects;
            if ((pp.readMask & drop) != 0) {
                pp.readMask &= ~drop;
                pp.needsDepth = post_mask_needs_depth(pp.readMask);
                pp.needsNormals = post_mask_needs_normals(pp.readMask);
            }
        }
        // The program is made only for a frame that runs it (a conversion or a colour filter): a game without a stack never compiles it.
        if ((pp.final_pass() || pp.colorFilter != 0) &&
            !gpu.post_ready()) {  // logged once; the frame is drawn without the final pass
            pp.exposure = pp.tonemap = pp.linear = false;
            pp.fx = PostFx{};
            pp.colorFilter = 0;
            pp.custom.drop_ldr();
            pp.customLdr = false;
        }
        if (pp.fx.lut) {
            // The .cube table of the grade: loaded (once) into a strip image; a file that cannot be read or parsed is logged once by
            // the asset cache and the table is skipped, the rest of the grade is drawn.
            const LutAsset* lut = assets->lut(pp.lut);
            if (lut && lut->view.id != 0) {
                pp.lutInfo = LutInfo{lut->view, lut->size, lut->cols, lut->rows};
            } else {
                pp.fx.lut = false;
                pp.lut.clear();
                // A LUT alone was the only reason to convert a linear scene: without it the present copy encodes it, as without a stack.
                // A custom pass at a display-referred place keeps the conversion (its pieces encode the picture).
                pp.settle_custom();
            }
        }
    }

    // A capture through a camera (Renderer::capture_camera): the custom passes of the camera's stack over the picture,
    // and nothing else of the stack. Their history is the capture's own (plan.history), their prepass the camera's
    // (plan_prepass).
    if (plan.view && plan.customPost && fr.wantWorld && fr.cam.postStack && fr.cam.postStack->has_custom()) {
        PostPlan& pp = ctx.postPlan;
        pp = PostPlan{};
        pp.sceneLinear = fr.linear;
        pp.custom = make_custom_post_plan(*fr.cam.postStack, *assets, stats.materialFallbacks, warnedCustomPass);
        pp.custom.history = plan.history;
    }

    gather_meshes(ctx);
    collect_lights(ctx);
    collect_decals(ctx);
    shadow_bounds(ctx);
    cull_and_batch(ctx);
    // Fog and sun shafts (renderer_fog.h), planned before the prepass: the sun is known once the lights are, and shafts alone with no sun in
    // view must not ask for a prepass. The sun is the light of slot 0 when it is a directional one (the shadow caster, otherwise the
    // brightest directional light) and it shines (select_lights); the studio rig is not a sun.
    if (draws && fr.cam.postStack) {
        Vec3 sun;
        bool haveSun = false;
        if (!fr.cam.studio && !ctx.lights.empty()) {
            const LightData& l = ctx.lights[0];
            if (l.color.w == 0.0f && l.pos.w == 0.0f && l.color.x + l.color.y + l.color.z > 0.0f) {
                sun = Vec3{l.pos.x, l.pos.y, l.pos.z};  // pos = the direction toward the light
                haveSun = true;
            }
        }
        PostPlan& pp = ctx.postPlan;
        pp.fogFx = make_fog_plan(fr.cam, *fr.cam.postStack, fr.linear, haveSun ? &sun : nullptr);
        // fogHeightBase is an absolute height (the +-1e6 cap of make_fog_plan is on that authored value, before this): in local
        // coordinates it moves down as the floating origin moves up (M75.4b). Subtracted in double, rounded to a float once.
        pp.fogFx.heightBase = float(double(pp.fogFx.heightBase) - world.origin().y);
        const std::uint32_t shaftsBit = 1u << int(PostEffect::SunShafts);
        if ((pp.readMask & shaftsBit) != 0 && !pp.fogFx.shafts && debugView != DebugView::Ao) {
            pp.readMask &= ~shaftsBit;  // no sun in view: the shafts draw nothing, so they need no depth
            pp.needsDepth = post_mask_needs_depth(pp.readMask);
            pp.needsNormals = post_mask_needs_normals(pp.readMask);
        }
    }
    // A custom post pass whose snippet calls fa_depth or fa_normal asks for the prepass; one that does not never makes
    // it.
    if ((draws || (plan.view && plan.customPost)) && ctx.postPlan.custom.reads_prepass())
        ctx.postPlan.needsDepth = ctx.postPlan.needsNormals = true;
    // The volumetric fog (renderer_volumetric.h): planned here, from the lights and the shadows of this job, so that it asks for the prepass it marches
    // to. It replaces the analytic fog of its camera (below), so a camera that cannot draw it keeps that.
    if (draws && !fr.cam.studio) {
        SceneSettings vss = world.settings();
        if (qualityOn) {  // the graphics preset: no fog, or at most its quality
            if (!quality.volumetricFog) vss.volumetricFog = false;
            vss.volumetricQuality = std::min(vss.volumetricQuality, quality.volumetricQuality);
        }
        ctx.postPlan.vol = make_vol_plan(vss, fr.cam, ctx.lights, fr.linear, ctx.camPx.w, ctx.camPx.h, ctx.doShadows,
                                         ctx.doShadows && ctx.cascades > 0 && ctx.haveShadowCaster);
        // An absolute height like the fog's (its +-10000 range is on the authored value); subtracted in double (M75.4b).
        ctx.postPlan.vol.heightBase = float(double(ctx.postPlan.vol.heightBase) - world.origin().y);
        // Only a camera that can draw it asks for the prepass: on a GPU without RGBA16F, or after a shader failure, no prepass is made for it.
        if (ctx.postPlan.vol.on) {
            if (volFx.can_draw(transient_targets(), ctx.postPlan.vol))
                ctx.postPlan.needsDepth = true;
            else
                ctx.postPlan.vol = VolPlan{};
        }
    }
    // Contact shadows (M73.2c) read the prepass depth: a camera with a light that has one asks for it (the volumetric fog's prepass is the
    // same image). A job that cannot make the prepass draws none: the lengths are cleared before the lights are packed (upload_lights).
    bool wantContact = false;
    if (draws && !fr.cam.studio)
        for (const LightData& l : ctx.lights) wantContact = wantContact || l.contactLength > 0.0f;
    if (wantContact) ctx.postPlan.needsDepth = true;
    // Subsurface scattering (M73.5): a camera with an opaque mesh that scatters asks for the prepass (the shader keeps only the surface the camera sees)
    // and for the images and programs of the passes. A camera that cannot make them draws the meshes as they are.
    bool wantSss = false;
    if (draws && !fr.cam.studio)
        for (const MeshBatch& b : ctx.opaqueBatches)
            wantSss = wantSss || (b.mainCount > 0 && sss_scatters(ctx.opaque[b.rep]));
    if (wantSss) {
        ctx.postPlan.sss = make_sss_plan(fr.cam, ctx.camPx.w, ctx.camPx.h);
        if (ctx.postPlan.sss.on && sssFx.can_draw(transient_targets(), gpu, ctx.postPlan.sss))
            ctx.postPlan.needsDepth = true;
        else
            ctx.postPlan.sss = SssPlan{};
    }
    if (draws && upscaleTaa.on && !plan.view) {
        ctx.postPlan.needsDepth = true;  // the temporal upscaler reprojects its history with the depth
        // and with the motion of the objects (M76-P1a), where the GPU can make the image
        ctx.postPlan.request_velocity();
    }
    plan_prepass(ctx);
    ctx.contactOn = wantContact && ctx.doPrepass;
    ctx.sssOn = ctx.postPlan.sss.on && ctx.doPrepass;
    if (ctx.sssOn)
        ++stats.subsurfaceCameras;
    else
        ctx.postPlan.sss = SssPlan{};
    if (ctx.contactOn) {
        for (const LightData& l : ctx.lights) stats.contactShadowLights += l.contactLength > 0.0f ? 1 : 0;
    } else {
        for (LightData& l : ctx.lights) l.contactLength = 0.0f;
    }
    plan_outline(ctx);
    plan_transmission(ctx);
    // The volumetric fog needs the prepass (its shaders and its image were checked above). A camera that draws it draws no analytic fog: neither the scene's
    // (ss.fogDensity, scene_uniforms) nor the stack's (fogFx.fog), the two would fog twice; the sun shafts of the stack stay.
    if (ctx.postPlan.vol.on) {
        if (ctx.doPrepass) {
            ctx.postPlan.fogFx.fog = false;
            ++stats.volumetricCameras;
            stats.volumetricLights += ctx.postPlan.vol.lightsUsed;
            stats.volumetricLightsDropped += ctx.postPlan.vol.lightsDropped;
        } else {
            ctx.postPlan.vol = VolPlan{};
        }
    }
    // The passes need the prepass and their shaders: a camera that cannot draw them keeps the scene's own fog (ss.fogDensity, below).
    if (ctx.postPlan.fogFx.any()) {
        FogFxPlan& ff = ctx.postPlan.fogFx;
        if (!ctx.doPrepass) {
            ff = FogFxPlan{};
        } else {
            if (ff.fog && !fogFx.ready(FogFx::Prog::Fog)) ff.fog = false;
            if (ff.shafts && !(fogFx.ready(FogFx::Prog::Rays) && fogFx.ready(FogFx::Prog::Add))) ff.shafts = false;
        }
    }
    // Reflections, sun shafts, depth of field and motion blur work on the scene colour, so the screen-space items are drawn after them
    // (as they are over the bloom).
    if (plan.last && !plan.view) {
        bool sceneColorFx = false;
        for (const DrawContext* c : postCams)
            sceneColorFx =
                sceneColorFx ||
                ((c->postPlan.ssr.any() || c->postPlan.fogFx.shafts || c->postPlan.sceneFx.any() ||
                  c->postPlan.vol.on || c->postPlan.sss.on) &&
                 c->doPrepass) ||
                c->postPlan.taa
                    .on ||  // the antialiasing works on the scene colour: the HUD goes over it, never through it
                c->postPlan.custom.any_hdr();
        if (sceneColorFx) {
            ctx.hudAfterBloom = true;
            ctx.doMainPass = fr.wantWorld || !ctx.hudAfterBloom;
        }
    }
    bool frameFinal = false;  // some camera of the frame runs a final pass
    for (const DrawContext* c : postCams) frameFinal = frameFinal || c->postPlan.final_pass();
    // With the upscale stage (M76-P3a) the screen-space items are drawn over the upscaled picture at the output size, so the glyphs and the
    // edges stay sharp when the game is drawn below that size. Only when no pass after them in the old order would have changed their
    // pixels: hudAfterBloom (they are drawn over the bloom) and the final pass (they are drawn over its result) already keep them out of
    // every effect; with neither, the bloom is the only effect left, and a HUD that glows (bloomScreenSpace) stays in the game image at
    // the render resolution, as it always was. render_world decided it (hudAtOutput) before the glyphs were rasterized, for the size they are drawn at.
    bool hudOutOk = false;
    if (plan.last && !plan.view && fr.wantScreen && hudAtOutput && upscale_active()) {
        const bool glowsOnHud =
            !ctx.hudAfterBloom && !frameFinal && frameCam.bloom.enabled && frameCam.bloom.intensity > 0.0f;
        // The format the picture has when it reaches the stage: display values after the final pass (its destination is filterTarget when the
        // items are not drawn into it), the scene format otherwise.
        if (!glowsOnHud && (!frameFinal || ensure_filter_target()) &&
            ensure_output_target(outTarget, "output", frameFinal ? gpu.display_format() : gameTarget.format.color,
                                 true)) {
            hudOutOk = true;
        }
    }
    build_quad_stream(ctx);
    if (hudOutOk && (!ctx.gScreen.batches.empty() || !ctx.gDebugScreen.batches.empty())) {
        ctx.hudOut = true;
        ctx.hudDisplay = frameFinal;  // the picture holds display values: the items are drawn as in hudAfterPost
    }
    // The final pass converts the picture (exposure, tonemap, the encode of a linear scene): the screen-space items go over its result, in
    // display space, and are drawn after it instead of in the main pass. Only when there is something to draw, and the image for it exists.
    if (plan.last && !plan.view && frameFinal && fr.wantScreen && !ctx.hudOut &&
        (!ctx.gScreen.batches.empty() || !ctx.gDebugScreen.batches.empty()) && ensure_hud_target()) {
        ctx.hudAfterPost = true;
        ctx.hudAfterBloom =
            false;  // the glow goes into the resolved image: the multisampled one is not drawn over again
        ctx.doMainPass = fr.wantWorld;
    }
    upload_instances(ctx);
    scene_uniforms(ctx);
    light_plan(ctx);
    gi2d_plan(ctx);
    // The passes of the job join the frame graph (frame_graph.h), declared from what the phases above decided.
    build_graph(ctx);
}

// ---- 3D gather ----
// Reads: renderScene (the MeshRenderers of the frame, gathered once: matrices, assets, boxes, hashes, flashes; built here only
// when the job's scope is not the one it was built for), fr (camera, tag mask), ctx.z01. Calls assets->mesh / texture on this
// thread for the items whose answer depends on the camera (lods, render-target textures). Writes: ctx.opaque, ctx.blended
// (blended far to near) with every MeshItem field (model, dist, flash, mesh, tex, material, normalTex, hashes, bounds, anim,
// visible), fr.anyFlash. The camera's own work is the tag mask, the distance, the frustum test and the sort.
void Renderer::Impl::gather_meshes(DrawContext& ctx) {
    World& world = ctx.world;
    Frame& fr = ctx.fr;
    const bool z01 = ctx.z01;

    auto& opaque = ctx.opaque;
    auto& blended = ctx.blended;
    fr.anyFlash = world.feel().any_flash();
    if (!fr.wantWorld) return;
    if (!renderScene.built() || renderScene.scope() != fr.scopeRoot) {
        probes_build_volumes(
            world);  // the boxes the meshes pick their reflection probes from (fill_probe_fs reads the same list)
        renderScene.build(world, *assets, fr.scopeRoot, false, &probeVolumes);
    }
    const std::vector<SceneMesh>& shared = renderScene.meshes();
    // The items this camera draws, in the scene's (the world's) order; `special` are those whose mesh or textures depend on the
    // camera.
    std::vector<MeshItem> meshes;
    std::vector<char> meshBlended;
    std::vector<std::pair<std::size_t, const SceneMesh*>> special;
    meshes.reserve(shared.size());
    meshBlended.reserve(shared.size());
    const bool masked = !fr.mask.empty();
    for (const SceneMesh& sm : shared) {
        if (masked && !fr.mask.draws(world, sm.entity)) continue;  // Camera.showTags / hideTags
        if (sm.hlodProxy && sm.hlodGroup == 0)
            continue;  // a proxy no group claimed would draw all the time, whatever the distance
        if (sm.hasLods || sm.liveTextures || sm.chainCount != 0 || sm.hlodGroup != 0)
            special.emplace_back(meshes.size(), &sm);
        MeshItem& mi = meshes.emplace_back();
        mi.hlod = sm.hlodGroup != 0 || sm.streamProxy;
        mi.mr = sm.mr;
        mi.entity = sm.entity;
        mi.model = sm.model;
        mi.mesh = sm.mesh;
        mi.tex = sm.tex;
        mi.normalTex = sm.normalTex;
        mi.material = sm.material;
        mi.flash = sm.flash;
        mi.anim = sm.anim;
        mi.bmin = sm.bmin;
        mi.bmax = sm.bmax;
        mi.paramsHash = sm.paramsHash;
        mi.noCull = sm.noCull;
        mi.colorsHash = sm.colorsHash;
        mi.sortKey = sm.sortKey;
        mi.keyed = sm.keyed;
        mi.lm = sm.lm;
        mi.probe = sm.probe;
        mi.probeKey = sm.probeKey;
        mi.refl = sm.refl;
        mi.dist = length(sm.model.translation() - fr.cam.position);
        meshBlended.push_back(sm.blended ? 1 : 0);
    }
    // Levels of detail (M75.1). Each job picks with its own camera (a split-screen camera, a render target, a CameraView); a probe or GI
    // capture follows the first main camera of the frame. The shadow passes of a job draw the items of the job, so they cast the level
    // of their camera. LodFades keeps the cross-fades per camera and entity.
    const bool lodsOn = renderScene.has_lods();
    const bool lodFollow = fr.lodFollowMain;
    const bool lodMainJob = !lodFollow && ctx.plan.name.compare(0, 7, "camera:") == 0;
    const std::uint64_t lodCam = std::hash<std::string>{}(ctx.plan.name);
    // The main camera's picks are kept for the captures only where a capture will ask: a world with a ReflectionProbe or a RealtimeGI.
    const bool lodRemember = lodMainJob && lodsOn && (world.any<ReflectionProbe>() || world.any<RealtimeGI>());
    const LodView lodView{fr.cam.perspective, fr.cam.fov, fr.cam.halfH};
    const auto lod_pick = [&](LodKind kind, std::uint64_t bits, int target, float crossFade, int farTarget) {
        if (lodFollow) {
            LodPick p;
            p.level = target;
            if (const LodPick* m = lodFades.main_pick(bits, kind))
                p.level = m->level;  // settled: a capture never fades
            return p;
        }
        const LodPick p = lodFades.step(lodCam, bits, kind, target, crossFade, fr.dt, farTarget);
        if (lodRemember && !lodFades.main_set()) lodFades.remember(bits, kind, p);
        return p;
    };
    std::vector<LodPick>
        groupPick;  // per LodGroup of the scene: the child this camera shows (level -1 = a group that draws nothing)
    if (lodsOn) {
        const auto& groups = renderScene.lod_groups();
        groupPick.resize(groups.size());
        for (std::size_t g = 0; g < groups.size(); ++g) {
            const SceneLodGroup& sg = groups[g];
            groupPick[g].level = -1;
            if (sg.children <= 0 || !(sg.radius > 0.0f)) continue;
            float distance = length(sg.origin - fr.cam.position);
            if (qualityOn)
                distance *= std::max(quality.lodDistanceScale, 1.0f);  // the graphics preset: levels switch sooner
            const float value =
                sg.group->mode == LodMode::ScreenSize ? lod_screen_size(2.0f * sg.radius, distance, lodView) : distance;
            // Past hlodThreshold the group is its proxy mesh (M75 P1d): one more level, past every child.
            const auto level_at = [&](float v) {
                return sg.proxy && lod_hlod_reached(*sg.group, v) ? kHlodLevel
                                                                  : lod_group_level(*sg.group, sg.children, v);
            };
            const bool screenMode = sg.group->mode == LodMode::ScreenSize;
            const int farLevel =
                level_at(screenMode ? value * (1.0f - kLodHysteresis) : value * (1.0f + kLodHysteresis));
            groupPick[g] = lod_pick(LodKind::Group, sg.entity.bits(), level_at(value), sg.group->crossFade, farLevel);
        }
    }
    std::vector<char> lodDropped;  // an item whose LodGroup child is not shown
    std::vector<std::pair<MeshItem, char>>
        lodOutgoing;  // the level fading out of an entity in a cross-fade, and whether it is blended
    std::vector<const SceneMesh*> lodOutgoingMesh;
    for (const auto& [i, sm] : special) {
        MeshItem& mi = meshes[i];
        const MeshRenderer& mr = *mi.mr;
        if (sm->liveTextures) {  // "target:<name>": the image depends on the job (a camera's own target is the checker)
            mi.tex = mr.texture.empty() ? nullptr : assets->texture(mr.texture);
            mi.normalTex = mr.normalMap.empty() ? nullptr : assets->texture(mr.normalMap);
        }
        // The levels switch at once (no dither) where the draw has no program with it: a full-shader material, a custom material
        // that is not alphaMode "clip" (its programs have no discard) and a mesh with subsurface scattering (its extra pass).
        // The engine's own program fades through its mesh_lod variant, a clip material through the discard it has.
        const bool customMat = mi.material && mi.material->ok;
        const bool canFade =
            customMat ? !mi.material->full && mi.material->alphaMode == "clip" : !(subsurface_of(mr)[0] > 0.0f);
        float groupFade = 0.0f;
        if (sm->hlodGroup !=
            0) {  // the proxy of a group: drawn only at the group's proxy level (or while it fades out)
            if (!hlod_proxy_shown(groupPick[sm->hlodGroup - 1], canFade, groupFade)) {
                if (lodDropped.empty()) lodDropped.assign(meshes.size(), 0);
                lodDropped[i] = 1;
                continue;
            }
            mi.lodFade = groupFade;
        }
        if (sm->chainCount != 0 && lodsOn) {
            const std::vector<std::uint32_t>& chains = renderScene.lod_chains();
            bool drop = false;
            for (std::uint32_t k = 0; k < sm->chainCount; ++k) {
                const std::uint32_t entry = chains[sm->chainFirst + k];
                const LodPick& r = groupPick[entry >> 4];
                const int child = int(entry & 15u);
                if (r.level < 0) continue;
                if (child == r.level) {
                    if (r.fading() && canFade && groupFade == 0.0f) groupFade = r.amount;
                } else if (r.fading() && child == r.from && canFade) {
                    if (groupFade == 0.0f) groupFade = -r.amount;
                } else {
                    drop = true;
                }
            }
            if (drop) {
                if (lodDropped.empty()) lodDropped.assign(meshes.size(), 0);
                lodDropped[i] = 1;
                continue;
            }
            mi.lodFade = groupFade;
        }
        if (!sm->hasLods) continue;
        float screen = 0.0f;
        const float lodDist = qualityOn ? mi.dist * std::max(quality.lodDistanceScale, 1.0f) : mi.dist;
        if (mr.lodMode ==
            LodMode::ScreenSize) {  // the box of the nearest level, so the size does not change with the level
            const float scale = std::max({length(Vec3{mi.model.at(0, 0), mi.model.at(0, 1), mi.model.at(0, 2)}),
                                          length(Vec3{mi.model.at(1, 0), mi.model.at(1, 1), mi.model.at(1, 2)}),
                                          length(Vec3{mi.model.at(2, 0), mi.model.at(2, 1), mi.model.at(2, 2)})});
            screen = lod_screen_size(length(sm->bmax - sm->bmin) * scale, lodDist, lodView);
        }
        // The impostor (M75-P1c) is one more level, past the last one: the sentinel level of LodFades, so its cross-fade with the last level is the
        // ordinary one. An atlas that cannot be used (a warning was given) leaves the last level drawn.
        const bool hasImpostor = !mr.impostor.empty() && mr.impostorDistance > 0.0f;
        const int lastLevel = hasImpostor ? lod_level_of(mr, 3.0e38f, 0.0f) : 0;
        ImpostorUse impostorUse;
        bool impostorReady = false;
        const auto level_at = [&](float dist, float scr) {
            if (hasImpostor && impostor_active(mr, dist, scr)) {
                if (!impostorReady) impostorReady = impostors.resolve(*assets, frameSerial, mr, mi.entity, impostorUse);
                return impostorReady ? kImpostorLevel : lastLevel;
            }
            return lod_level_of(mr, dist, scr);
        };
        const int target = level_at(lodDist, screen);
        // The hysteresis: the pick again with the metric pushed farther (the distance up, the screen size down).
        const int farTarget = level_at(lodDist * (1.0f + kLodHysteresis), screen * (1.0f - kLodHysteresis));
        const LodPick pick = lod_pick(LodKind::Mesh, mi.entity.bits(), target,
                                      canFade && groupFade == 0.0f ? mr.lodCrossFade : 0.0f, farTarget);
        // Puts the level `level` of the entity into `item` (the nearest level is what the scene gathered).
        const auto set_level = [&](MeshItem& item, int level) {
            const std::string& name = lod_level_mesh(mr, level);
            if (name == mr.mesh) return false;
            item.mesh = assets->mesh(name);
            item.lm = {};  // another mesh: the entity was baked for the one the manifest names
            mesh_cull_bounds(*item.mesh, world.get<Animator>(item.entity), item.bmin, item.bmax, item.anim);
            return true;
        };
        // Puts the level `level` (or the impostor's card, kImpostorLevel) into `item` and says whether the result is blended.
        const ImpostorCamera impostorCam{fr.cam.position, fr.cam.right, fr.cam.up, fr.linear};
        const auto place = [&](MeshItem& item, int level, char& isBlended) {
            if (level == kImpostorLevel) {
                if (!impostorReady)
                    impostorReady = impostors.resolve(*assets, frameSerial, mr, item.entity, impostorUse);
                if (impostorReady) {
                    impostors.make_item(item, ctx.impostorDraws, impostorUse, impostorCam);
                    isBlended = 0;  // a card is alpha-cut, never blended
                    return;
                }
                level = lastLevel;
            }
            if (set_level(item, level)) isBlended = mesh_is_blended(mr, *item.mesh, item.material) ? 1 : 0;
        };
        if (pick.fading()) {
            MeshItem out = mi;
            char outBlended = sm->blended ? 1 : 0;
            out.lodFade = -pick.amount;
            mi.lodFade = pick.amount;
            place(out, pick.from, outBlended);
            lodOutgoing.emplace_back(std::move(out), outBlended);
            lodOutgoingMesh.push_back(sm);
        }
        place(mi, pick.level, meshBlended[i]);
    }
    if (lodMainJob && lodsOn) lodFades.set_main();
    for (std::size_t k = 0; k < lodOutgoing.size(); ++k) {  // after the loop: it holds references into `meshes`
        special.emplace_back(meshes.size(), lodOutgoingMesh[k]);
        meshes.push_back(std::move(lodOutgoing[k].first));
        meshBlended.push_back(lodOutgoing[k].second);
    }
    for (const auto& entry : special) {  // what the camera changed is ranked again; a value the table lacks: comparator
        MeshItem& mi = meshes[entry.first];
        if (mi.impostor) continue;  // a card keeps its own key (kImpostorSortKey)
        mi.keyed = mi.keyed && renderScene.sort_table().key_of(fields_of(mi), mi.sortKey);
    }
    if (!lodDropped.empty()) {  // the children of a LodGroup this camera does not show
        lodDropped.resize(meshes.size(), 0);
        std::size_t kept = 0;
        for (std::size_t i = 0; i < meshes.size(); ++i) {
            if (lodDropped[i]) continue;
            if (kept != i) {
                meshes[kept] = std::move(meshes[i]);
                meshBlended[kept] = meshBlended[i];
            }
            ++kept;
        }
        meshes.resize(kept);
        meshBlended.resize(kept);
    }
    // The Terrains: one MeshItem per node of the quadtree the camera selects (renderer_terrain.h), opaque, ahead of the frustum job
    // like every other item.
    {
        TerrainRenderer::View tv;
        tv.world = &world;
        tv.scopeRoot = fr.scopeRoot;
        if (masked) tv.drawn = [&](Entity e) { return fr.mask.draws(world, e); };
        tv.assets = assets.get();
        tv.viewProj = fr.cam.viewProj;
        tv.z01 = z01;
        tv.camera = fr.cam.position;
        tv.linear = fr.linear;
        tv.serial = frameSerial;
        if (qualityOn) tv.lodQuality = quality.terrainLodQuality;
        tv.gpu = &gpu;
        tv.albedoFormat = gpu.texture_format(SG_PIXELFORMAT_RGBA8);
        terrains.gather(tv, ctx.terrainDraws, meshes);
        meshBlended.resize(meshes.size(), 0);
    }
    const rjobs::Split meshSplit = rjobs::split(meshes.size(), kMeshGrain, kParallelMeshes);
    rjobs::run("render.mesh_frustum", meshSplit, [&](const jobs::Chunk& c) {
        for (std::size_t i = c.begin; i < c.end; ++i) {
            MeshItem& mi = meshes[i];
            mi.visible = mi.noCull || box_in_frustum(fr.cam.viewProj, z01, mi.bmin, mi.bmax, mi.model);
        }
    });
    // Occlusion culling (M75.2): with no enabled Occluder in the world this is the one branch; a reflection probe's or a GI capture's pictures
    // are not culled (they show the scene from a point the Occluders were not placed for).
    // Areas and portals (M75.2) come first (a mesh in a room the portals do not show needs no depth test); the same single branch.
    if (!fr.noProbes && !fr.giCapture && fr.cam.areaCulling && world.any<OcclusionArea>())
        portal_cull_meshes(world, fr, meshes);
    // The GPU culling of the depth pyramid (M75.2b, SceneSettings.occlusionMode) is exclusive: a camera that uses it is not culled by the Occluders.
    const bool cullable = !fr.noProbes && !fr.giCapture;
    // A view job (a capture, a CameraView, a render target) never uses it: its pyramid could never be ready inside the capture
    // (hiz_submit runs when a frame begins), so the Occluders cull it and no reduce pass or buffer is made for it.
    if (cullable && hizOn && !ctx.plan.gi && !ctx.plan.view) ctx.hiz = hiz_cull(world, fr, meshes);
    const bool occluded = cullable && !ctx.hiz && world.any<Occluder>() && occlude_meshes(world, fr, z01, meshes);
    // The Foliage instances (renderer_foliage.h): after the culling, because the foliage culls its own chunks (with the buffer the
    // Occluders just filled) and its items are made visible or not by it.
    if (world.any<Foliage>() || foliage.size() != 0) {
        FoliageRenderer::View fv;
        fv.world = &world;
        fv.scopeRoot = fr.scopeRoot;
        if (masked) fv.drawn = [&](Entity e) { return fr.mask.draws(world, e); };
        fv.assets = assets.get();
        fv.viewProj = fr.cam.viewProj;
        fv.z01 = z01;
        fv.camera = fr.cam.position;
        fv.time = fr.time;
        fv.serial = frameSerial;
        fv.occlusion = occluded ? &occlusion : nullptr;
        if (qualityOn) {
            fv.density = quality.foliageDensity;
            fv.distance = quality.foliageDistance;
        }
        const FoliageRenderer::Counts fc = foliage.gather(fv, meshes, meshBlended);
        stats.foliageInstancesCulled += fc.culled;
    }
    for (std::size_t i = 0; i < meshes.size(); ++i)
        (meshBlended[i] ? blended : opaque).push_back(std::move(meshes[i]));  // the last use
    // Far to near; a NaN distance (a NaN transform) counts as the farthest (order_float), so the order stays total.
    const auto farther = [](const MeshItem& a, const MeshItem& b) {
        return rjobs::order_float(a.dist) > rjobs::order_float(b.dist);
    };
    rjobs::stable_sort("render.sort_blended", blended, farther, kParallelMeshes * 4, kMeshGrain * 4);
}

// ---- lights and studio rig ----
// Reads: world (Light), fr.cam (position, studio rig), ctx.opaque and plan.view (the no-light
// warning is not given for a view). Writes: ctx.lights (sorted,
// capped), ctx.shadowLight, ctx.lightDirForShadow, ctx.haveShadowCaster, stats.lights / lightsDropped, warnedNoLight.
void Renderer::Impl::collect_lights(DrawContext& ctx) {
    World& world = ctx.world;
    Frame& fr = ctx.fr;
    const JobPlan& plan = ctx.plan;
    auto& opaque = ctx.opaque;
    auto& lights = ctx.lights;
    auto& shadowLight = ctx.shadowLight;
    auto& lightDirForShadow = ctx.lightDirForShadow;
    int culledLocal = 0;
    // The lights that use the light atlas (M73.1b): an area light (the LTC tables), a cookie, an IES profile. Their data texels are
    // filled once the atlas has been made (below), when the rects of the tiles are known.
    struct PendingAtlas {
        std::size_t index;
        std::string cookie, ies;
        bool area;
        bool cube = false;  // the cookie is a point light's (six faces)
    };
    std::vector<PendingAtlas> pendingAtlas;
    if (fr.wantWorld && !fr.cam.studio)
        world.each<Light>([&](Entity e, Light& l) {
            if (!entity_active(world, e)) return;
            Mat4 m = world.world_matrix(e);
            LightData ld;
            const Color lc = to_scene(l.color, fr.linear);  // picked as sRGB; the light adds up in linear light
            Vec3 col{lc.r * l.intensity, lc.g * l.intensity, lc.b * l.intensity};
            const float brightness = std::max({col.x, col.y, col.z});
            if (l.type == LightType::Directional) {
                Vec3 d = normalize(m.transform_dir(kForward));
                ld.pos = Vec4{-d, 0.0f};
                ld.color = Vec4{col, 0.0f};
                ld.dir = Vec4{d, 1.0f};
                ld.rank = 1;
                ld.score = brightness;
                if (shadowLight < 0 && l.castShadows) {
                    lightDirForShadow = d;
                    shadowLight = 0;
                    ld.rank = 0;
                    // A preset without soft shadows draws a PCSS sun with the plain PCF filter (the limit of the local lights too).
                    const ShadowFilter sunFilter =
                        (qualityOn && !quality.softShadows && l.shadowFilter == ShadowFilter::Pcss) ? ShadowFilter::Pcf
                                                                                                    : l.shadowFilter;
                    ctx.sun = {l.shadowResolution, l.shadowBias,     l.shadowNormalBias,
                               l.shadowSoftness,   l.shadowDistance, sunFilter};
                }
                if (!l.ies.empty() && !warnedDirectionalIes) {
                    warnedDirectionalIes = true;
                    FA_WARN("render",
                            "Light.ies is set on a directional light ('{}'): an IES profile describes a lamp's "
                            "distribution "
                            "around a point, so it only shapes point and spot lights. Hint: clear Light.ies, or make "
                            "the light a "
                            "point or spot light.",
                            l.ies);
                }
                // A cookie tiled over the world (an orthographic projection along the light): Light.size is the size of one tile.
                if (!l.cookie.empty()) {
                    const Vec3 ax = normalize(m.transform_dir(Vec3{1, 0, 0})),
                               ay = normalize(m.transform_dir(Vec3{0, 1, 0}));
                    ld.ext[0] = Vec4{ax, 1.0f / std::max(l.size.x, 0.001f)};
                    ld.ext[1] = Vec4{ay, 1.0f / std::max(l.size.y, 0.001f)};
                    pendingAtlas.push_back({lights.size(), fs::normalize(l.cookie), {}, false});
                }
            } else {
                Vec3 d = normalize(m.transform_dir(kForward));
                ld.pos = Vec4{m.translation(), l.range};
                ld.color = Vec4{col, l.type == LightType::Spot ? 2.0f : (l.type == LightType::Area ? 3.0f : 1.0f)};
                ld.dir = Vec4{d, std::cos(radians(l.spotAngle))};
                const Vec3 ax = normalize(m.transform_dir(Vec3{1, 0, 0})),
                           ay = normalize(m.transform_dir(Vec3{0, 1, 0}));
                PendingAtlas pend{lights.size(), {}, {}, l.type == LightType::Area};
                if (l.type == LightType::Area) {
                    // The emitter's two half sizes (rectangle: half width and height; disc: the radius twice; tube: half length and
                    // half thickness) and the radius of the sphere around it, which the range is measured from.
                    const float hx = std::max(l.size.x, 0.001f) * 0.5f, hy = std::max(l.size.y, 0.001f) * 0.5f;
                    const float h2 = l.shape == LightShape::Disc ? hx : hy;
                    ld.ext[0] = Vec4{ax, hx};
                    ld.ext[1] = Vec4{ay, h2};
                    ld.ext[2].w = float(int(l.shape));
                    ld.extent = l.shape == LightShape::Disc ? hx * 1.06f : std::sqrt(hx * hx + h2 * h2);
                    ld.ext[3].w = ld.extent;
                    if (!l.cookie.empty() && !warnedAreaCookie) {
                        warnedAreaCookie = true;
                        FA_WARN(
                            "render",
                            "Light.cookie is set on an area light ('{}'): a cookie shapes spot, directional and point "
                            "lights, not area lights, so it is ignored. Hint: clear it or change Light.type.",
                            l.cookie);
                    }
                    if (!l.ies.empty() && !warnedAreaIes) {
                        warnedAreaIes = true;
                        FA_WARN(
                            "render",
                            "Light.ies is set on an area light ('{}'): an IES profile shapes point and spot lights, "
                            "not area lights, so it is ignored. Hint: clear it or change Light.type.",
                            l.ies);
                    }
                } else {
                    if (!l.cookie.empty()) {
                        // A spot's cookie is one perspective tile; a point light's is a cube of six face tiles baked from an
                        // equirectangular picture (light_atlas.h), picked by the same face selection as its shadow's cube.
                        pend.cookie = fs::normalize(l.cookie);
                        pend.cube = l.type == LightType::Point;
                    }
                    if (!l.ies.empty()) {
                        pend.ies = fs::normalize(l.ies);
                    }
                    ld.ext[0] = Vec4{ax, 0.0f};
                    ld.ext[1] = Vec4{ay, 0.0f};
                }
                if (pend.area || !pend.cookie.empty() || !pend.ies.empty()) pendingAtlas.push_back(std::move(pend));
                // The graphics preset (quality.localShadows): the point, spot and area lights cast no shadow when it is off.
                if (l.castShadows && !(qualityOn && !quality.localShadows && l.type != LightType::Directional)) {
                    ld.shadow.casts = true;
                    ld.shadow.resolution = qualityOn && l.shadowResolution > 0
                                               ? std::min(l.shadowResolution, quality.shadowTileSize)
                                               : l.shadowResolution;
                    ld.shadow.bias = l.shadowBias;
                    ld.shadow.normalBias = l.shadowNormalBias;
                    ld.shadow.softness = l.shadowSoftness;
                    ld.shadow.distance = l.shadowDistance > 0.0f ? l.shadowDistance : world.settings().shadowDistance;
                    ld.shadow.filter =
                        l.shadowFilter == ShadowFilter::Hard
                            ? 1
                            : (l.shadowFilter == ShadowFilter::Pcss && !(qualityOn && !quality.softShadows) ? 2 : 0);
                    ld.shadow.spotAngle = l.type == LightType::Spot ? l.spotAngle : 0.0f;
                    // An area light's PCSS light size: the emitter's mean full size (a rectangle's width and height, a disc's
                    // diameter, a tube's length and thickness); the penumbra then follows the emitter, scaled by shadowSoftness.
                    if (l.type == LightType::Area)
                        ld.shadow.emitter =
                            std::max(l.size.x, 0.001f) * 0.5f +
                            (l.shape == LightShape::Disc ? std::max(l.size.x, 0.001f) : std::max(l.size.y, 0.001f)) *
                                0.5f;
                }
                // Light.innerAngle: the cone at full strength (0 = the default fade of the outer quarter, light_data.glsl). The inner
                // cosine stays above the outer one, so the smoothstep has two different edges.
                if (l.type == LightType::Spot && l.innerAngle > 0.0f)
                    ld.cosInner = std::min(
                        std::max(std::cos(radians(std::min(l.innerAngle, l.spotAngle))), ld.dir.w + 1e-3f), 1.0f);
                // Relevance to the camera: bright and close first (the light's own range scales the fall-off).
                const float r2 = std::max(l.range * l.range, 1e-4f);
                ld.score = brightness * r2 / (r2 + length_sq(m.translation() - fr.cam.position));
                // A local light whose sphere is outside the view lights nothing that is drawn: it takes no place in the table (and no
                // part of the kMaxLights of the view).
                const float rg = std::max(l.range, 0.0f) + ld.extent;
                const Vec3 c = m.translation();
                if (rg > 0.0f && !box_in_frustum(fr.cam.viewProj, ctx.z01, Vec3{c.x - rg, c.y - rg, c.z - rg},
                                                 Vec3{c.x + rg, c.y + rg, c.z + rg}, Mat4::identity())) {
                    ++culledLocal;
                    if (!pendingAtlas.empty() && pendingAtlas.back().index == lights.size()) pendingAtlas.pop_back();
                    return;
                }
            }
            ld.baked = l.mode == LightMode::Baked;
            ld.volumetric = std::isfinite(l.volumetric) ? std::clamp(l.volumetric, 0.0f, 10.0f) : 0.0f;
            // Light.contactShadowLength counts only with the scene's master switch; plan_job drops it again when the frame has no prepass.
            if (world.settings().contactShadows && !(qualityOn && !quality.contactShadows) &&
                std::isfinite(l.contactShadowLength))
                ld.contactLength = std::clamp(l.contactShadowLength, 0.0f, 10.0f);
            lights.push_back(ld);
        });
    // The light atlas for the lights that use it: made (or made again) when a light asked for something it does not hold yet; each
    // light then gets the rects of its tiles. Without the atlas (a GPU that cannot filter RGBA16F) an area light shines like a point
    // light and a cookie or profile is not drawn.
    // (The tiles are asked for only now, so a light the frustum cull dropped does not make its cookie or profile bake.)
    for (const PendingAtlas& pa : pendingAtlas) {
        if (pa.area) lightAtlas.request_ltc();
        if (!pa.cookie.empty())
            lightAtlas.request(pa.cube ? LightAtlasKind::CookieCube : LightAtlasKind::Cookie, pa.cookie);
        if (!pa.ies.empty()) lightAtlas.request(LightAtlasKind::Ies, pa.ies);
    }
    lightAtlas.end_requests();
    if (!pendingAtlas.empty()) {
        const bool atlasOk =
            lightAtlas.sync([](const LightAtlasKey& k) { return load_light_atlas_source(k); },
                            [](const LightAtlasKey&, const std::string& message, const std::string& hint) {
                                FA_WARN("render", "{}. Hint: {}", message, hint);
                            });
        for (const PendingAtlas& pa : pendingAtlas) {
            LightData& ld = lights[pa.index];
            const LightAtlasRect* cr =
                atlasOk && !pa.cookie.empty()
                    ? lightAtlas.rect(pa.cube ? LightAtlasKind::CookieCube : LightAtlasKind::Cookie, pa.cookie)
                    : nullptr;
            const LightAtlasRect* ir =
                atlasOk && !pa.ies.empty() ? lightAtlas.rect(LightAtlasKind::Ies, pa.ies) : nullptr;
            if (pa.area && !atlasOk) {  // the point-light fallback
                ld.color.w = 1.0f;
                ld.extent = 0.0f;
                ld.shadow.emitter = 0.0f;  // a point light now: its shadow has no emitter size
                ld.ext[2] = ld.ext[3] = Vec4{};
                continue;
            }
            if (!pa.area && !cr && !ir) continue;
            ld.hasExt = true;
            if (cr) ld.ext[2] = Vec4{float(cr->x), float(cr->y), 1.0f, ld.ext[2].w};
            if (ir) ld.ext[3] = Vec4{float(ir->x), float(ir->y), 1.0f, ld.ext[3].w};
        }
        if (atlasOk) ctx.lightAtlasView = lightAtlas.view();
    }
    // Camera.lighting = studio: the rig of the camera takes the place of the scene's lights. Directions are relative to the camera
    // (right, up, forward), so an item looks the same wherever its stage is: a warm key from the upper left in front, a cool fill
    // from the right, a rim from behind and above.
    if (fr.wantWorld && fr.cam.studio) {
        auto directional = [&](float toRight, float toUp, float toCamera, Vec3 color, float intensity) {
            const Vec3 toward = normalize(fr.cam.right * toRight + fr.cam.up * toUp - fr.cam.forward * toCamera);
            LightData ld;
            ld.pos = Vec4{toward, 0.0f};
            const Color lc = to_scene(Color{color.x, color.y, color.z, 1.0f}, fr.linear);
            ld.color = Vec4{Vec3{lc.r, lc.g, lc.b} * (intensity * fr.cam.studioIntensity), 0.0f};
            ld.dir = Vec4{-toward, 1.0f};
            ld.rank = 1;
            ld.score = intensity;
            lights.push_back(ld);
        };
        directional(-0.55f, 0.65f, 0.55f, Vec3{1.0f, 0.96f, 0.9f}, 0.9f);  // key
        directional(0.8f, 0.1f, 0.45f, Vec3{0.7f, 0.8f, 1.0f}, 0.32f);     // fill
        directional(0.3f, 0.55f, -0.8f, Vec3{1.0f, 1.0f, 1.0f}, 0.5f);     // rim
    }
    // The shadow caster in slot 0, then the other directional lights, then point and spot lights by relevance; what the
    // shader's arrays cannot hold is left out.
    const int droppedNow = select_lights(lights, size_t(kMaxLights));
    stats.lightsDropped += droppedNow;
    if (droppedNow > 0 && !warnedLightsDropped) {
        warnedLightsDropped = true;
        FA_WARN("render",
                "{} lights were left out: a view lights at most {} lights at once, {} of them directional (the most "
                "relevant "
                "ones are kept). Hint: use fewer lights, or turn some Lights off; stats.lightsDropped counts them.",
                droppedNow, kMaxLights, kMaxDirectionalLights);
    }
    stats.lightsCulled += culledLocal;
    stats.lights += int(lights.size());
    // The physical sky (SceneSettings.skyModel): the sun is the light of slot 0 when it is a directional one. The sky is drawn with
    // the colour the author chose (physSunColor); when skyTintsSun is on, the light itself is what the air and the clouds let
    // through of it, relative to a noon sun. Never for a studio rig, never when a sky material draws the sky, never when this GPU
    // cannot make the sky's tables (the gradient is drawn then).
    {
        const SceneSettings& wss = world.settings();
        ctx.physSunOn = false;
        if (fr.wantWorld && !fr.cam.studio && !lights.empty() && lights[0].color.w == 0.0f && lights[0].pos.w == 0.0f) {
            LightData& sun = lights[0];
            ctx.physSunOn = true;
            ctx.physSunDir[0] = sun.pos.x;
            ctx.physSunDir[1] = sun.pos.y;
            ctx.physSunDir[2] = sun.pos.z;
            ctx.physSunColor[0] = sun.color.x;
            ctx.physSunColor[1] = sun.color.y;
            ctx.physSunColor[2] = sun.color.z;
            if (wss.skyModel == SkyModel::Physical && wss.skyTintsSun && wss.skyMaterial.empty() &&
                physSky.ready(gpu)) {  // the gradient is not tinted
                float f[3];
                sky_sun_light_factor(physical_sky_settings(wss), sun.pos.y, f);
                sun.color.x *= f[0];
                sun.color.y *= f[1];
                sun.color.z *= f[2];
            }
        }
    }
    // A sun that gives no light (below the horizon of the physical sky, or an intensity of 0) has no shadow to draw.
    ctx.haveShadowCaster = shadowLight >= 0 && !lights.empty() && lights[0].rank == 0 &&
                           std::max({lights[0].color.x, lights[0].color.y, lights[0].color.z}) > 0.0f;
    if (!opaque.empty() && lights.empty() && culledLocal == 0 && !warnedNoLight && !plan.view) {
        warnedNoLight = true;
        FA_WARN("render", "the scene has MeshRenderer entities but no Light entity: meshes only receive ambient light "
                          "(SceneSettings.ambientLight). Add an entity with a Light component (type Directional) or "
                          "set MeshRenderer.unlit.");
    }
}

// ---- shadow bounds ----
// Reads: ctx.haveShadowCaster, ctx.lightDirForShadow, ctx.sun, ctx.lights (the shadow settings of the point and spot lights), ctx.opaque /
// ctx.blended (castShadows, mesh part boxes, matrices), the scene settings (cascades, split, blend, distance, atlas size), fr.cam, gpu
// (shadows_supported, depth range). Writes: ctx.doShadows, ctx.cascades, ctx.fits, ctx.splits, ctx.atlas, ctx.localPlan, ctx.localFits,
// ctx.viewProj, ctx.sunViews, ctx.shadowTgt; creates (or grows) the shadow atlas.
// The sun's shadow is cut into cascades (shadow_cascades.h): the camera's view between its near plane and the shadow distance is split
// into 1..4 slices, each fitted by a sphere and drawn into its own tile of the atlas. Everything depends on the camera only through its
// position, its forward axis and its frustum, and the maps move in whole texels, so a still shadow does not shimmer. The point and spot
// lights that cast shadows (Light.castShadows) share the same atlas through the budget of plan_local_shadows (local_shadows.h): one
// perspective tile for a spot, six for a point light, ranked by importance for the camera.
void Renderer::Impl::shadow_bounds(DrawContext& ctx) {
    const bool haveSun = ctx.haveShadowCaster;
    auto& opaque = ctx.opaque;
    auto& blended = ctx.blended;
    auto& doShadows = ctx.doShadows;
    ctx.cascades = 0;
    ctx.sunViews = 0;
    ctx.localPlan = render::LocalShadowPlan{};
    ctx.localInputs.clear();
    ctx.localFits.clear();
    ctx.viewProj.clear();
    bool anyLocal = false;
    for (const LightData& ld : ctx.lights) anyLocal = anyLocal || (ld.rank == 2 && ld.shadow.casts);
    if (!haveSun && !anyLocal) return;
    // The world box of each caster's parts as jobs, joined here in the order of the items.
    Vec3 bmin{1e30f, 1e30f, 1e30f}, bmax{-1e30f, -1e30f, -1e30f};
    bool any = false;
    // The box of the meshes that are not lit by a lightmap and receive shadows: the receivers a baked light still lights in real time.
    Vec3 dmin{1e30f, 1e30f, 1e30f}, dmax{-1e30f, -1e30f, -1e30f};
    for (auto* list : {&opaque, &blended}) {
        struct Box {
            Vec3 lo{1e30f, 1e30f, 1e30f}, hi{-1e30f, -1e30f, -1e30f};
            Vec3 dlo{1e30f, 1e30f, 1e30f}, dhi{-1e30f, -1e30f, -1e30f};
            bool any = false, dynamic = false;
        };
        std::vector<Box> boxes(list->size());
        rjobs::run("render.shadow_bounds", rjobs::split(list->size(), kMeshGrain, kParallelMeshes),
                   [&](const jobs::Chunk& ch) {
                       for (std::size_t i = ch.begin; i < ch.end; ++i) {
                           const MeshItem& mi = (*list)[i];
                           const bool casts = mi.mr->castShadows;
                           // A receiver the light probes fully cover holds the baked lights in its probes: they do not light it in real time.
                           const bool dynamic =
                               mi.mr->receiveShadows && !mi.lm.mesh && !(mi.probe && mi.probe->coverage >= 1.0f);
                           if (!casts && !dynamic) continue;
                           Box& b = boxes[i];
                           for (auto& p : mi.mesh->parts) {
                               for (int c = 0; c < 8; ++c) {
                                   Vec3 corner{(c & 1) ? p.bmax.x : p.bmin.x, (c & 2) ? p.bmax.y : p.bmin.y,
                                               (c & 4) ? p.bmax.z : p.bmin.z};
                                   Vec3 w = mi.model.transform_point(corner);
                                   if (casts) {
                                       b.lo = min(b.lo, w);
                                       b.hi = max(b.hi, w);
                                       b.any = true;
                                   }
                                   if (dynamic) {
                                       b.dlo = min(b.dlo, w);
                                       b.dhi = max(b.dhi, w);
                                       b.dynamic = true;
                                   }
                               }
                           }
                       }
                   });
        for (const Box& b : boxes) {
            if (b.dynamic) {
                dmin = min(dmin, b.dlo);
                dmax = max(dmax, b.dhi);
            }
            if (!b.any) continue;
            bmin = min(bmin, b.lo);
            bmax = max(bmax, b.hi);
            any = true;
        }
    }
    if (!any) return;
    const Frame& fr = ctx.fr;
    const SceneSettings& settings = ctx.world.settings();
    // The sun's tiles: texels per side of a cascade's map: the light's shadowResolution, else 2048 for one cascade and 1024 for several
    // (the atlas stays 2048 x 2048 for four).
    int want = haveSun ? std::clamp(int(settings.shadowCascades), 1, render::kMaxShadowCascades) : 0;
    if (qualityOn)
        want = std::min(want, std::max(quality.shadowCascades, 0));  // the graphics preset's cap on the cascades
    int tile = ctx.sun.resolution > 0 ? std::clamp(render::pow2_floor(std::max(ctx.sun.resolution, 128)), 128, 4096)
                                      : (want == 1 ? 2048 : 1024);
    if (qualityOn) tile = std::max(128, std::min(tile, render::pow2_floor(std::max(quality.shadowTileSize, 128))));
    std::vector<render::ShadowTileRequest> requests;
    for (int c = 0; c < want; ++c) requests.push_back({tile, 128, c});
    // The point and spot lights that want a shadow: only those a caster can reach (the casters' box meets the light's sphere) and that
    // are not farther from the camera than their shadow distance.
    for (std::size_t i = 0; i < ctx.lights.size(); ++i) {
        const LightData& ld = ctx.lights[i];
        if (ld.rank != 2 || !ld.shadow.casts) continue;
        const Vec3 pos{ld.pos.x, ld.pos.y, ld.pos.z};
        const float range = ld.pos.w + ld.extent;  // an area light's range is measured from its emitter's surface
        const Vec3 nearest = min(max(pos, bmin), bmax);
        if (!(range > 0.0f) || length_sq(nearest - pos) > range * range) continue;
        // A baked light's shadows are in the lightmaps and a lightmapped surface skips the light, so it takes a map only for the
        // receivers it still lights in real time (meshes with no lightmap): none within its range, no map.
        if (ld.baked) {
            const Vec3 near2 = min(max(pos, dmin), dmax);
            if (dmin.x > dmax.x || length_sq(near2 - pos) > range * range) continue;
        }
        if (ld.shadow.distance > 0.0f && length(pos - fr.cam.position) - range > ld.shadow.distance) continue;
        render::LocalShadowInput in;
        in.light = int(i);
        in.position = pos;
        in.range = range;
        in.spotAngle = ld.shadow.spotAngle;
        in.brightness = std::max({ld.color.x, ld.color.y, ld.color.z});
        in.resolution = ld.shadow.resolution;
        // An area light's PCSS penumbra is as wide as its emitter, and the filter reads at most 16 texels around a pixel: with no
        // Light.shadowResolution of its own the tile is as coarse as the emitter allows (512 texels per face for 0.5 m, 256 for 1 m,
        // down to 64), so the widest penumbra the filter reaches grows with the emitter, and the six faces cost little.
        if (ld.shadow.emitter > 0.0f && in.resolution <= 0 && ld.shadow.filter == 2) {
            int px = 512;
            while (px > 64 && float(px) * ld.shadow.emitter > 256.0f) px /= 2;
            // ... and, like any other light, smaller the farther the camera is (the size the light would get with resolution 0).
            in.resolution = std::min(px, render::local_shadow_wanted_tile(in, length(pos - fr.cam.position)));
        }
        in.shadowDistance = ld.shadow.distance;
        ctx.localInputs.push_back(in);
    }
    if (want == 0 && ctx.localInputs.empty()) return;
    int atlasMax = std::min(std::clamp(int(settings.shadowAtlasSize), 512, 8192),
                            std::max(64, sg_query_limits().max_image_size_2d));
    if (qualityOn) atlasMax = std::max(64, std::min(atlasMax, quality.shadowAtlasSize));
    ctx.localPlan = render::plan_local_shadows(atlasMax, requests, ctx.localInputs, fr.cam.position);
    ctx.atlas = ctx.localPlan.atlas;
    if (!ctx.localPlan.lost.empty() && !warnedShadowBudget) {
        warnedShadowBudget = true;
        FA_WARN(
            "render",
            "{0} point or spot light(s) lost their shadow this frame: the shadow atlas ({1}x{1} texels, "
            "SceneSettings.shadowAtlasSize) or the {2} shadow maps of a frame are full, and the least important lights "
            "(by brightness, range and distance to the camera) give theirs up first. Hint: raise "
            "SceneSettings.shadowAtlasSize, lower Light.shadowResolution, set Light.shadowDistance, or turn "
            "castShadows "
            "off on lights that matter less.",
            ctx.localPlan.lost.size(), atlasMax, render::kMaxShadowViews);
    }
    const render::ShadowAtlasLayout& atlas = ctx.atlas;
    std::vector<int> tileSizes;
    while (int(tileSizes.size()) < want && atlas.tiles[tileSizes.size()].placed())
        tileSizes.push_back(atlas.tiles[tileSizes.size()].size);
    const int count = int(tileSizes.size());
    if (count > 0) {
        // The camera's slice of the world: from its near plane to the shadow distance (the light's, else the scene's, else what the
        // casters need, see plan_cascades).
        const render::CameraFrustum cf =
            render::camera_frustum(fr.cam.invViewProj, ctx.z01, fr.cam.position, normalize(fr.cam.forward));
        const float shadowDist = ctx.sun.distance > 0.0f ? ctx.sun.distance : settings.shadowDistance;
        const render::CascadePlan plan = render::plan_cascades(
            cf, bmin, bmax, normalize(ctx.lightDirForShadow), shadowDist, settings.shadowCascadeSplit,
            settings.shadowCascadeBlend, tileSizes, ctx.z01, ctx.world.origin());
        if (plan.ok) {
            ctx.splits = plan.splits;
            ctx.fits = plan.fits;
            ctx.cascades = count;
        }
    }
    if (ctx.cascades == 0 && ctx.localPlan.lights.empty()) return;
    // The atlas is the used part of the layout; a placed tile is inside it by construction.
    if (!create_shadow_targets(atlas.width, atlas.height)) {
        ctx.cascades = 0;
        ctx.localPlan = render::LocalShadowPlan{};
        return;
    }
    ctx.shadowTgt = shadowTarget;
    // One matrix per view: the cascades, then the tile of every local light (spots look along their axis, a point light's faces
    // along the six axes).
    ctx.sunViews = want;
    ctx.viewProj.assign(atlas.tiles.size(), Mat4::identity());
    for (int c = 0; c < ctx.cascades; ++c) ctx.viewProj[std::size_t(c)] = ctx.fits[std::size_t(c)].viewProj;
    ctx.localFits.assign(atlas.tiles.size() - std::size_t(want), render::LocalTileFit{});
    for (const render::LocalShadowLight& l : ctx.localPlan.lights) {
        const LightData& ld = ctx.lights[std::size_t(l.light)];
        const Vec3 pos{ld.pos.x, ld.pos.y, ld.pos.z};
        for (int f = 0; f < l.tiles; ++f) {
            const std::size_t view = std::size_t(l.firstTile + f);
            Vec3 fwd, up;
            float tanHalf = 1.0f;
            if (l.cube) {
                const render::CubeFace face = render::cube_face_basis(f);
                fwd = face.forward;
                up = face.up;
            } else {
                render::spot_tile_basis(Vec3{ld.dir.x, ld.dir.y, ld.dir.z}, fwd, up);
                tanHalf = std::tan(radians(ld.shadow.spotAngle));
            }
            render::LocalTileFit fit =
                render::fit_local_tile(pos, fwd, up, tanHalf, atlas.tiles[view].size, ld.pos.w + ld.extent, ctx.z01);
            ctx.localFits[view - std::size_t(want)] = fit;
            ctx.viewProj[view] = fit.viewProj;
        }
    }
    doShadows = true;
}

// ---- cull, then group into instanced batches ----
// Reads: ctx.doShadows, ctx.cascades, ctx.fits, ctx.z01, items' visible flags. Writes: ctx.opaque / ctx.blended (culled), item `casts` and
// `castMask` (the cascades whose map holds the item), ctx.opaqueBatches / ctx.blendedBatches, ctx.mainMats / ctx.shadowMats (instance
// matrices), stats.meshesCulled / shadowCasters.
void Renderer::Impl::cull_and_batch(DrawContext& ctx) {
    const bool z01 = ctx.z01;
    auto& opaque = ctx.opaque;
    auto& blended = ctx.blended;
    auto& doShadows = ctx.doShadows;
    auto& opaqueBatches = ctx.opaqueBatches;
    auto& blendedBatches = ctx.blendedBatches;
    auto& mainMats = ctx.mainMats;
    auto& shadowMats = ctx.shadowMats;
    // The views of the shadow pass: the sun's cascades (views 0..sunViews-1, those placed are 0..cascades-1) and the tiles of the local
    // lights (views sunViews.. of the atlas). A caster is drawn into every view whose volume holds it.
    const int views = doShadows ? int(ctx.viewProj.size()) : 0;
    const int cascades = doShadows ? ctx.cascades : 0;
    // The local views: the light that owns each tile (the sphere of its range), for the cheap test before the frustum's.
    struct LocalView {
        Vec3 centre;
        float range = 0;
    };
    std::vector<LocalView> localViews(std::size_t(std::max(views, 0)));
    std::vector<char> active(std::size_t(std::max(views, 0)), 0);
    for (int c = 0; c < cascades; ++c) active[std::size_t(c)] = 1;
    if (doShadows) {
        for (const render::LocalShadowLight& l : ctx.localPlan.lights) {
            const LightData& ld = ctx.lights[std::size_t(l.light)];
            for (int f = 0; f < l.tiles; ++f) {
                const std::size_t v = std::size_t(l.firstTile + f);
                if (v >= active.size()) continue;
                active[v] = 1;
                localViews[v] = {Vec3{ld.pos.x, ld.pos.y, ld.pos.z}, ld.pos.w + ld.extent};
            }
        }
    }
    ctx.shadowRuns.clear();
    // M76: the previous model of every drawn instance, for the motion vectors of a camera that asks for them (a GI capture face never does).
    const bool askVelocity = !ctx.plan.gi && ctx.fr.wantWorld &&
                             (ctx.postPlan.needsVelocity || debugView == DebugView::MotionVectors || forceVelocity);
    // A GPU that cannot render to the velocity format (RG16F) gets no attachment, no history and no work of its own: the temporal passes
    // read the camera alone, as they do for a draw the velocity cannot describe.
    ctx.collectPrev = askVelocity && gpu.velocity_ready() && !noVelocityTarget;
    if (askVelocity && !ctx.collectPrev && !warnedNoVelocity && gpu.prepass_ready()) {
        warnedNoVelocity = true;
        FA_WARN("render", "The motion vectors need a render target of the format RG16F and this GPU cannot make one: "
                          "temporal antialiasing, the "
                          "upscalers and the other effects that read them reproject with the camera alone, so a moving "
                          "object smears. Hint: "
                          "nothing to fix in the project; update the graphics driver.");
    }
    ctx.prevMats.clear();
    for (auto* list : {&opaque, &blended}) {
        if (doShadows)
            rjobs::run("render.shadow_cull", rjobs::split(list->size(), kMeshGrain, kParallelMeshes),
                       [&](const jobs::Chunk& ch) {
                           for (std::size_t i = ch.begin; i < ch.end; ++i) {
                               MeshItem& mi = (*list)[i];
                               mi.castMask = 0;
                               // The shadow draws the level that fades IN only (solid), never the one fading out: no dither in a shadow map.
                               if (mi.mr->castShadows && !(mi.lodFade < 0.0f)) {
                                   // A conservative world sphere of the item for the local lights' ranges.
                                   const Vec3 centre = mi.model.transform_point((mi.bmin + mi.bmax) * 0.5f);
                                   const float scale = std::max(
                                       {length(Vec3{mi.model.at(0, 0), mi.model.at(0, 1), mi.model.at(0, 2)}),
                                        length(Vec3{mi.model.at(1, 0), mi.model.at(1, 1), mi.model.at(1, 2)}),
                                        length(Vec3{mi.model.at(2, 0), mi.model.at(2, 1), mi.model.at(2, 2)})});
                                   const float radius = 0.5f * length(mi.bmax - mi.bmin) * scale;
                                   for (int v = 0; v < views; ++v) {
                                       if (!active[std::size_t(v)]) continue;
                                       if (v >= ctx.sunViews) {
                                           const LocalView& lv = localViews[std::size_t(v)];
                                           if (!mi.noCull && length(centre - lv.centre) > lv.range + radius) continue;
                                       }
                                       if (mi.noCull || box_in_frustum(ctx.viewProj[std::size_t(v)], z01, mi.bmin,
                                                                       mi.bmax, mi.model))
                                           mi.castMask |= std::uint64_t(1) << v;
                                   }
                               }
                               mi.casts = mi.castMask != 0;
                           }
                       });
        for (auto& mi : *list) {
            if (!mi.visible && !mi.foliage)
                ++stats.meshesCulled;  // a foliage instance kept for the shadows counts in foliageInstancesCulled
            if (mi.visible && mi.lodFade != 0.0f && !mi.foliage && !ctx.fr.lodFollowMain) ++stats.lodCrossFades;
            if (mi.visible && mi.hlod && !ctx.fr.lodFollowMain) ++stats.hlodProxies;
            if (!doShadows) mi.casts = false;
            if (mi.casts) ++stats.shadowCasters;
        }
        list->erase(
            std::remove_if(list->begin(), list->end(), [](const MeshItem& m) { return !m.visible && !m.casts; }),
            list->end());
    }
    if (ctx.collectPrev) fill_prev_models(ctx);
    build_batches(opaque, true, opaqueBatches, mainMats, shadowMats, &ctx.shadowRuns,
                  ctx.collectPrev ? &ctx.prevMats : nullptr, &ctx.prevRows);
    build_batches(blended, false, blendedBatches, mainMats, shadowMats, &ctx.shadowRuns);
    ctx.mainExtraData.clear();
    ctx.shadowExtraData.clear();
    instanceParams.begin_frame(frameSerial);
    pack_instance_extras(opaque, opaqueBatches, ctx.mainExtraData, ctx.shadowExtraData, &instanceParams,
                         &ctx.shadowRuns);
    pack_instance_extras(blended, blendedBatches, ctx.mainExtraData, ctx.shadowExtraData, &instanceParams,
                         &ctx.shadowRuns);
}

// ---- the previous model matrices (M76 motion vectors) ----
// Gives every visible opaque item the model matrix its entity had the game frame before (ctx.prevRows[item.prevIdx]), from what the renderer
// keeps in `prevModels`; the item's own model (no motion of its own) when the entity is new, was not drawn in the frame before, the camera was cut
// (PostPlan::prevValid false) or the frame is not one of the game's (capture_world). Terrain nodes, impostor cards and foliage instances keep
// their model: a node or a card is not an entity of its own and the instances of a foliage share one, and they are static. A skinned item also
// has its joint palette kept (`prevPalettes`, same rules). Every camera of the frame sees the same previous matrix (the first one to ask moves
// the history on). Reads: ctx.opaque, ctx.postPlan.prevValid, ctx.fr.time, postSerial, framePost. Writes: ctx.prevRows, ctx.prevHistory,
// ctx.prevTime, item prevIdx, prevModels, prevPalettes, the game clock of the history.
void Renderer::Impl::fill_prev_models(DrawContext& ctx) {
    const bool kept = framePost;
    if (kept && prevModelsPruned != postSerial) {  // an entity not drawn in the frame before is forgotten
        prevModelsPruned = postSerial;
        std::erase_if(prevModels, [&](const auto& kv) { return kv.second.frame + 1 < postSerial; });
        std::erase_if(prevPalettes, [&](const auto& kv) { return kv.second.frame + 1 < postSerial; });
    }
    const bool useHistory = kept && ctx.postPlan.prevValid;
    const float now = ctx.fr.time;
    if (kept &&
        clockFrame !=
            postSerial) {  // the game time of the frame before, as the models: the first camera of the frame moves it on
        clockPrev = clockFrame + 1 == postSerial ? clockCur : now;
        clockCur = now;
        clockFrame = postSerial;
    }
    ctx.prevHistory = useHistory;
    ctx.prevTime = useHistory ? clockPrev : now;
    ctx.prevRows.clear();
    ctx.prevRows.reserve(ctx.opaque.size());
    for (MeshItem& mi : ctx.opaque) {
        Mat4 prev = mi.model;
        if (kept && mi.visible && !mi.foliage && !mi.terrain && !mi.impostor && !mi.entity.is_null()) {
            auto [it, fresh] = prevModels.try_emplace(mi.entity.bits());
            PrevModel& e = it->second;
            if (fresh || e.frame + 1 < postSerial) {  // new, or not drawn in the frame before: no motion of its own
                e.prev = e.cur = mi.model;
            } else if (e.frame + 1 ==
                       postSerial) {  // the first time this frame: last frame's model is the previous one
                e.prev = e.cur;
                e.cur = mi.model;
            }  // e.frame == postSerial: another item or camera of this frame, same history
            e.frame = postSerial;
            if (useHistory) prev = e.prev;
            if (mi.anim) keep_prev_palette(mi);
        }
        mi.prevIdx = std::uint32_t(ctx.prevRows.size());
        ctx.prevRows.push_back(prev_model_rows(prev));
    }
}

// The joint palettes of a skinned item for the motion vectors: the current frame's and the one before, one per skin of its Animator (at most
// kMaxSkinJoints joints each, as the palette the draw uploads). Same life rules as prevModels. The vectors keep their capacity from frame to
// frame: the palette of the frame before is the one the frame before last wrote over.
void Renderer::Impl::keep_prev_palette(const MeshItem& mi) {
    auto [it, fresh] = prevPalettes.try_emplace(mi.entity.bits());
    PrevPalette& p = it->second;
    auto snapshot = [&](std::vector<std::vector<Mat4>>& out) {
        out.resize(std::max<std::size_t>(1, mi.anim->skinPalettes.size()));
        for (std::size_t skin = 0; skin < out.size(); ++skin) {
            const std::vector<Mat4>& pal = palette_of(*mi.anim, int(skin));
            out[skin].assign(pal.begin(),
                             pal.begin() + std::ptrdiff_t(std::min<std::size_t>(pal.size(), kMaxSkinJoints)));
        }
    };
    if (fresh || p.frame + 1 < postSerial) {
        snapshot(p.cur);
        p.prev = p.cur;
    } else if (p.frame + 1 == postSerial) {
        std::swap(p.prev, p.cur);
        snapshot(p.cur);
    }
    p.frame = postSerial;
}

// The palette of skin `skin` as it was the frame before for a draw of `mi` (the current one when there is no history, after a cut or when the
// skin changed size). Only the first kMaxSkinJoints joints count, as in the palette the draw uploads.
const std::vector<Mat4>& Renderer::Impl::prev_palette(const DrawContext& ctx, const MeshItem& mi, int skin) const {
    const std::vector<Mat4>& cur = palette_of(*mi.anim, skin);
    if (!ctx.prevHistory) return cur;
    const auto it = prevPalettes.find(mi.entity.bits());
    if (it == prevPalettes.end() || std::size_t(skin) >= it->second.prev.size()) return cur;
    const std::vector<Mat4>& prev = it->second.prev[std::size_t(skin)];
    return prev.size() == std::min<std::size_t>(cur.size(), kMaxSkinJoints) ? prev : cur;
}

// The previous joint palettes of the skinned draws the prepass makes with motion vectors, in one RGBA32F image (kPrevPaletteWidth texels a row;
// a palette is kPrevPaletteTexels texels from `ctx.prevPalBase`; joints past the skin's are the identity). Done before the first pass of the
// frame, next to the instance buffers: an image cannot be written inside a pass. A GPU that cannot sample RGBA32F, and the draws past
// kPrevPaletteMaxRows rows, get no palette and their fragments write the sentinel (one warning). Reads: ctx.collectPrev, ctx.opaque,
// ctx.opaqueBatches, the histories. Writes: ctx.prevPalView, ctx.prevPalBase, ctx.prevPalTexels, warnedPrevPalette.
void Renderer::Impl::upload_prev_palettes(DrawContext& ctx) {
    static_assert(kPrevPaletteWidth == kLightTextureWidth,
                  "the palette image is written through the light image's pool");
    ctx.prevPalView = {};
    ctx.prevPalBase.clear();
    if (!ctx.collectPrev || !ctx.prevInst.id) return;
    const bool canSample = sg_query_pixelformat(SG_PIXELFORMAT_RGBA32F).sample;
    const std::size_t maxTexels = std::size_t(kPrevPaletteWidth) * std::size_t(kPrevPaletteMaxRows);
    std::vector<float>& texels = ctx.prevPalTexels;
    texels.clear();
    bool clipped = false;
    for (std::size_t bi = 0; bi < ctx.opaqueBatches.size(); ++bi) {
        const MeshBatch& batch = ctx.opaqueBatches[bi];
        const MeshItem& mi = ctx.opaque[batch.rep];
        if (batch.mainCount == 0 || !mi.anim) continue;
        for (const SubMesh& part : mi.mesh->parts) {
            if (!part.skinVb.id) continue;
            const std::uint64_t key = prev_palette_key(batch.rep, part.skin);
            if (ctx.prevPalBase.count(key)) continue;
            const std::size_t first = texels.size() / 4;
            if (!canSample || first + std::size_t(kPrevPaletteTexels) > maxTexels) {
                clipped = true;
                continue;
            }
            const std::vector<Mat4>& pal = prev_palette(ctx, mi, part.skin);
            texels.resize(texels.size() + std::size_t(kPrevPaletteTexels) * 4);
            float* out = texels.data() + first * 4;
            for (int j = 0; j < kMaxSkinJoints; ++j) {
                const Mat4 m = std::size_t(j) < pal.size() ? pal[std::size_t(j)] : Mat4::identity();
                for (int r = 0; r < 3; ++r)
                    for (int c = 0; c < 4; ++c) *out++ = m.at(c, r);
            }
            ctx.prevPalBase[key] = int(first);
        }
    }
    if (clipped && !warnedPrevPalette) {
        warnedPrevPalette = true;
        if (canSample)
            FA_WARN("render",
                    "More than {} skinned draws in one camera's frame: the motion vectors of the ones past that count "
                    "carry the "
                    "camera's motion only (temporal antialiasing and the upscalers reproject them from the depth, so a "
                    "moving "
                    "character smears). Hint: draw fewer skinned meshes per camera, or share a skin between instances.",
                    kPrevPaletteMaxRows * kPrevPaletteWidth / kPrevPaletteTexels);
        else
            FA_WARN("render", "This GPU cannot sample 32-bit float textures in the vertex stage, which the motion "
                              "vectors of skinned meshes "
                              "need: they carry the camera's motion only (temporal antialiasing and the upscalers "
                              "reproject them from the "
                              "depth, so a moving character smears). Hint: nothing to fix in the project; update the "
                              "graphics driver.");
    }
    if (texels.empty()) return;
    // Whole rows, rounded up to 16 of them so that the pooled image is not made again for every skinned draw that comes or goes.
    const int rows =
        std::min(kPrevPaletteMaxRows,
                 int(((texels.size() / 4 + std::size_t(kPrevPaletteWidth) - 1) / std::size_t(kPrevPaletteWidth) + 15) /
                     16 * 16));
    texels.resize(std::size_t(rows) * std::size_t(kPrevPaletteWidth) * 4, 0.0f);
    ctx.prevPalView = gpu.write_light_image(rows, texels.data()).view;
}

// ---- flatten quads into one vertex stream ----
// Reads: fr (world, debugWorld, screen, debugScreen quad lists, debugLines, camera clear colour), ctx.clearByQuad, targetW/H.
// Writes: `stream`, `instStream`, ctx.gClear / gWorld / gDebugWorld / gScreen / gDebugScreen, ctx.lineFirst, ctx.vbuf,
// ctx.vinst (transient buffers), ctx.screenProj.
void Renderer::Impl::build_quad_stream(DrawContext& ctx) {
    Frame& fr = ctx.fr;
    const bool z01 = ctx.z01;
    const bool clearByQuad = ctx.clearByQuad;
    auto& gClear = ctx.gClear;
    auto& gWorld = ctx.gWorld;
    auto& gDebugWorld = ctx.gDebugWorld;
    auto& gScreen = ctx.gScreen;
    auto& gDebugScreen = ctx.gDebugScreen;
    auto& lineFirst = ctx.lineFirst;
    auto& vbuf = ctx.vbuf;
    stream.clear();
    instStream.clear();
    if (clearByQuad) {
        // The camera's clear colour over its viewport: one opaque quad over the unit square, which the viewport maps to the
        // camera's rectangle (see main_pass).
        QuadList clearList;
        clearList.begin_item(0, 0, assets->white(), SamplerKind::Nearest);
        clearList.set_opaque();
        QuadEmitter em{clearList, Mat4::identity(), false, pack_color(fr.cam.clearColor), kModeTextured, 0};
        em.rect(0, 0, 1, 1, 0, 0, 1, 1);
        clearList.end_item();
        clearList.flatten(stream, gClear.batches, &instStream);
    }
    fr.world.flatten(stream, gWorld.batches, &instStream);
    fr.debugWorld.flatten(stream, gDebugWorld.batches, &instStream);
    fr.screen.flatten(stream, gScreen.batches, &instStream);
    fr.debugScreen.flatten(stream, gDebugScreen.batches, &instStream);
    lineFirst = stream.size();
    stream.insert(stream.end(), fr.debugLines.begin(), fr.debugLines.end());

    if (!stream.empty()) {
        vbuf = gpu.acquire_transient(stream.size() * sizeof(Vertex2D));
        sg_write_buffer_desc wd{};
        wd.src.data = {stream.data(), stream.size() * sizeof(Vertex2D)};
        wd.dst.buffer = vbuf;
        sg_write_buffer_transient(&wd);
    }
    if (!instStream.empty()) {
        ctx.vinst = gpu.acquire_transient(instStream.size() * sizeof(float));
        sg_write_buffer_desc wd{};
        wd.src.data = {instStream.data(), instStream.size() * sizeof(float)};
        wd.dst.buffer = ctx.vinst;
        sg_write_buffer_transient(&wd);
    }

    ctx.screenProj = Mat4::ortho(0, float(targetW), float(targetH), 0, -1000.0f, 1000.0f, z01);
}

// ---- instance data: one model matrix per drawn mesh, written before any pass binds the buffers ----
// Reads: ctx.mainMats, ctx.shadowMats, ctx.mainExtraData, ctx.shadowExtraData. Writes: ctx.mainInst, ctx.shadowInst,
// ctx.mainExtra, ctx.shadowExtra (transient GPU buffers).
void Renderer::Impl::upload_instances(DrawContext& ctx) {
    static_assert(sizeof(Mat4) == kMeshInstanceBytes, "an instance is one Mat4");
    auto upload = [&](const void* data, std::size_t bytes) {
        if (bytes == 0) return sg_buffer{};
        sg_buffer buf = gpu.acquire_transient(bytes);
        sg_write_buffer_desc wd{};
        wd.src.data = {data, bytes};
        wd.dst.buffer = buf;
        sg_write_buffer_transient(&wd);
        return buf;
    };
    ctx.mainInst = upload(ctx.mainMats.data(), ctx.mainMats.size() * kMeshInstanceBytes);
    ctx.prevInst = upload(ctx.prevMats.data(), ctx.prevMats.size() * kPrevModelBytes);
    upload_prev_palettes(ctx);
    ctx.shadowInst = upload(ctx.shadowMats.data(), ctx.shadowMats.size() * kMeshInstanceBytes);
    ctx.mainExtra = upload(ctx.mainExtraData.data(), ctx.mainExtraData.size() * sizeof(float));
    ctx.shadowExtra = upload(ctx.shadowExtraData.data(), ctx.shadowExtraData.size() * sizeof(float));
}

// ---- the projected decals of the view (M73.5b) ----
// The Decals of the world that can touch this view: active, their box inside the camera frustum, in drawing order (SortOrder, then the
// world's order), at most kMaxDecals (the first in the world's order; the rest counts in stats.decalsDropped and is warned once). Also the
// paths of every texture the active Decals name, for the atlas (a decal turning into view must not rebuild it). Nothing for a job that draws
// no mesh, a studio camera or a view that does not draw the world.
// Reads: world, ctx.fr, ctx.opaque / ctx.blended. Writes: ctx.decals, ctx.decalPaths, stats.decalsDropped, warnedDecalCap.
void Renderer::Impl::collect_decals(DrawContext& ctx) {
    ctx.decals.clear();
    ctx.decalPaths.clear();
    const Frame& fr = ctx.fr;
    if (!fr.wantWorld || fr.cam.studio || (ctx.opaque.empty() && ctx.blended.empty())) return;
    World& world = ctx.world;
    std::set<std::string> paths;
    int dropped = 0;
    static const Vec3 kLo{-0.5f, -0.5f, -0.5f}, kHi{0.5f, 0.5f, 0.5f};
    world.each<Decal>([&](Entity e, Decal& d) {
        if (!entity_active(world, e)) return;
        for (const std::string* p : {&d.albedo, &d.normal}) {
            if (p->empty()) continue;
            if (paths.size() < render::kMaxDecalTextures) {
                paths.insert(decal_path_key(*p));
            } else if (!warnedDecalPaths && !paths.count(decal_path_key(*p))) {
                warnedDecalPaths = true;
                FA_WARN("render",
                        "The Decals of the world name more than {} different textures: the ones past that are not in "
                        "the atlas and "
                        "their decals are not drawn. Hint: share textures between decals or use fewer of them.",
                        render::kMaxDecalTextures);
            }
        }
        const Mat4 m = world.world_matrix(e);
        if (!box_in_frustum(fr.cam.viewProj, ctx.z01, kLo, kHi, m)) return;
        if (ctx.decals.size() >= std::size_t(render::kMaxDecals)) {
            ++dropped;
            return;
        }
        ctx.decals.push_back(DecalItem{m, &d});
    });
    std::stable_sort(ctx.decals.begin(), ctx.decals.end(),
                     [](const DecalItem& a, const DecalItem& b) { return a.decal->sortOrder < b.decal->sortOrder; });
    ctx.decalPaths.assign(paths.begin(), paths.end());
    stats.decalsDropped += dropped;
    if (dropped > 0 && !warnedDecalCap) {
        warnedDecalCap = true;
        FA_WARN("render",
                "More than {} Decals are in view: the first {} (in the order of the world) are drawn and the rest are "
                "left out. Hint: remove "
                "decals that have faded, or give them a Lifetime; stats.decalsDropped counts them.",
                render::kMaxDecals, render::kMaxDecals);
    }
}

// ---- the lights of the view: the light table and the clusters, in the data texture ----
// Clustered forward lighting (light_clusters.h): the table of ctx.lights (directional first, then the local lights by relevance) and,
// when there are local lights, the clusters of the view with each one's list of lights, are packed into one RGBA32F image that the
// mesh fragment shader reads (shaders/light_data.glsl). The build is a deterministic job (the same lists for any number of threads).
// Reads: ctx.lights, ctx.fr.cam, ctx.camPx, ctx.opaque / ctx.blended (nothing is built for a job that draws no mesh), gpu. Writes:
// ctx.lightView, the fa_cl_* fields of ctx.fuScene, stats.lightClusters / lightClusterEntries / lightClusterClipped / lightMaxPerCluster.
void Renderer::Impl::upload_lights(DrawContext& ctx) {
    const std::vector<LightData>& lights = ctx.lights;
    const Frame& fr = ctx.fr;
    // The "no clusters" value first, so every early return leaves a valid one (fuScene starts zeroed, which is not: the shader would
    // look up a cluster of a grid with no tiles). A view with no local lights keeps it too.
    ctx.fuScene.fa_cl_info[0] = -1.0f;
    ctx.fuScene.fa_cl_info[1] = ctx.fuScene.fa_cl_info[2] = ctx.fuScene.fa_cl_info[3] = 0.0f;
    ctx.fuScene.fa_counts[1] = 0.0f;
    ctx.fuScene.fa_ambient[3] = 0.0f;  // the light table's stride: 0 = 4 texels per light
    for (int c = 0; c < 4; ++c)
        ctx.fuScene.fa_gi[c] = 0.0f;  // no realtime GI grid (its records come with the table, below)
    // The records of the ready realtime GI grids (renderer_gi.cpp): packed after everything else, so a frame without one is unchanged.
    const GiSystem& gis = probes.gi;
    const int giCount = int(gis.records.size() / std::size_t(kGiRecordFloats));
    if ((lights.empty() && ctx.decals.empty() && giCount == 0) || (ctx.opaque.empty() && ctx.blended.empty()) ||
        ctx.camPx.w < 1 || ctx.camPx.h < 1)
        return;
    int directional = 0;
    while (directional < int(lights.size()) && lights[std::size_t(directional)].rank < 2) ++directional;
    ClusterCamera cam;
    cam.viewProj = fr.cam.viewProj;
    cam.position = fr.cam.position;
    cam.forward = fr.cam.forward;
    cam.widthPx = ctx.camPx.w;
    cam.heightPx = ctx.camPx.h;
    // The depth range of the view along its forward axis: the camera's near and far planes, found by unprojecting the middle of the
    // screen (an orthographic camera's range starts behind it; the clusters start a centimetre in front).
    {
        const Vec4 n = fr.cam.queryInvViewProj * Vec4{0, 0, -1, 1}, f = fr.cam.queryInvViewProj * Vec4{0, 0, 1, 1};
        auto depth_of = [&](const Vec4& p) {
            if (!(std::fabs(p.w) > 1e-12f)) return -1.0f;
            const Vec3 w{p.x / p.w, p.y / p.w, p.z / p.w};
            return dot(fr.cam.forward, w - fr.cam.position);
        };
        cam.nearDepth = std::max(depth_of(n), 0.01f);
        cam.farDepth = depth_of(f);
        if (!(cam.farDepth > cam.nearDepth)) cam.farDepth = cam.nearDepth * 10000.0f;
    }
    ClusterLists lists;
    // The decals of the view: their textures in the atlas, their records and boxes (nothing when none can be drawn).
    DecalPack decalPack;
    if (!ctx.decals.empty()) {
        // No atlas (every texture failed, or the GPU could not make it) is not "no decals": the atlas then holds no tile, a decal with an
        // albedo is skipped (counted in decalsDropped) and a decal with only a tint is still drawn.
        if (!ctx.decalPaths.empty()) ensure_decal_atlas(ctx.decalPaths, fr.linear);
        std::vector<DecalBox> boxes;
        int skipped = 0;
        make_decal_records(ctx.decals, fr.linear, decalPack, boxes, skipped);
        stats.decalsDropped += skipped;
        if (!decalPack.records.empty())
            build_decal_clusters(cam, make_cluster_grid(cam.widthPx, cam.heightPx, cam.nearDepth, cam.farDepth), boxes,
                                 decalPack.lists);
    }
    const bool haveDecals = !decalPack.records.empty();
    const bool clustered = int(lights.size()) > directional || haveDecals;
    if (clustered) {
        std::vector<LightSphere> spheres(lights.size());
        for (std::size_t i = std::size_t(directional); i < lights.size(); ++i)
            spheres[i] =
                LightSphere{lights[i].pos.x, lights[i].pos.y, lights[i].pos.z,
                            lights[i].pos.w + lights[i].extent};  // an area light's range counts from its surface
        build_light_clusters(cam, make_cluster_grid(cam.widthPx, cam.heightPx, cam.nearDepth, cam.farDepth), spheres,
                             lists);
        stats.lightClusters += lists.grid.clusters();
        stats.lightClusterEntries += int(lists.indices.size());
        stats.lightClusterClipped += int(lists.clippedEntries);
        stats.lightMaxPerCluster = std::max(stats.lightMaxPerCluster, int(lists.maxPerCluster));
        if (lists.clippedEntries > 0 && !warnedClusterClipped) {
            warnedClusterClipped = true;
            FA_WARN(
                "render",
                "{} light-list entries were left out: a cluster of the view holds at most {} lights and a view at most "
                "{} entries in all, so some pixels miss lights. Hint: give the lights a smaller range or use fewer "
                "lights "
                "that overlap; stats.lightClusterClipped counts them.",
                lists.clippedEntries, kMaxLightsPerCluster, kMaxClusterIndices);
        }
    }
    if (haveDecals) {
        stats.decals += int(decalPack.records.size());
        stats.decalClusterClipped += int(decalPack.lists.clippedEntries);
        if (decalPack.lists.clippedEntries > 0 && !warnedDecalClipped) {
            warnedDecalClipped = true;
            FA_WARN("render",
                    "{} decal-list entries were left out: a cluster of the view holds at most {} decals and a view at "
                    "most {} entries in all, "
                    "so some pixels miss decals. Hint: use fewer decals that overlap, or make them smaller; "
                    "stats.decalClusterClipped counts "
                    "them.",
                    decalPack.lists.clippedEntries, kMaxDecalsPerCluster, kMaxDecalIndices);
        }
        ctx.decalView = decal_view_or(ctx.white->view);
    }
    // The shadow records of the point and spot lights that got maps this frame (local_shadows.h): where each tile is in the atlas, its
    // matrix and its depth convention.
    std::vector<LocalShadowRecord> records;
    if (ctx.doShadows && ctx.shadowTgt.color.id) {
        const int aw = ctx.shadowTgt.w, ah = ctx.shadowTgt.h;
        const float tu = 1.0f / float(aw), tv = 1.0f / float(ah);
        for (const render::LocalShadowLight& l : ctx.localPlan.lights) {
            const LightData& ld = lights[std::size_t(l.light)];
            LocalShadowRecord rec;
            rec.light = l.light;
            rec.kind = l.cube ? 2 : 1;
            rec.fade = std::max(ld.shadow.distance, 0.0f);
            rec.filter = ld.shadow.filter;
            // A negative softness is an area light's emitter size in metres (fa_shadow_filter: PCSS sizes the penumbra by the emitter
            // over the distance to the blocker); otherwise the tangent of the light's angular size.
            rec.softness = ld.shadow.emitter > 0.0f
                               ? -ld.shadow.emitter * std::clamp(ld.shadow.softness, 0.0f, 10.0f) - 1e-4f
                               : std::tan(0.05f * std::clamp(ld.shadow.softness, 0.0f, 10.0f));
            rec.bias = std::clamp(ld.shadow.bias, 0.0f, 1.0f);
            rec.normalBias = std::clamp(ld.shadow.normalBias, 0.0f, 1.0f);
            for (int f = 0; f < l.tiles; ++f) {
                const std::size_t view = std::size_t(l.firstTile + f);
                const render::ShadowTile& tile = ctx.atlas.tiles[view];
                const render::LocalTileFit& fit = ctx.localFits[view - std::size_t(ctx.sunViews)];
                LocalShadowTileRecord t;
                t.sample = render::local_sample_matrix(fit, tile, aw, ah, gpu.is_gl());
                const Vec4 r = render::shadow_tile_rect(tile, aw, ah, gpu.is_gl());
                t.rect = Vec4{r.x + tu, r.y + tv, r.z - tu, r.w - tv};
                t.nearPlane = fit.nearPlane;
                t.farPlane = fit.farPlane;
                t.texelCoef = fit.texelCoef;
                rec.tiles.push_back(t);
            }
            records.push_back(std::move(rec));
        }
    }
    LightTexture tex;
    pack_light_texture(lights, directional, cam, clustered ? &lists : nullptr, tex,
                       records.empty() ? nullptr : &records, haveDecals ? &decalPack : nullptr,
                       giCount > 0 ? gis.records.data() : nullptr, giCount);
    ctx.localShadowBase = tex.shadowBase;
    ctx.lightView = gpu.write_light_image(tex.height, tex.texels.data()).view;
    ctx.fuScene.fa_counts[1] = tex.uniforms.decalBase;
    mesh_fa_mesh_fs_params_t& fu = ctx.fuScene;
    fu.fa_ambient[3] =
        float(tex.stride);  // texels per light (light_data.glsl: fa_light_base); fa_counts.y is the decal region
    if (tex.giBase >= 0) {
        // The grids' records (mesh_common.glsl fa_gi): a face of a grid's own capture (Frame::giCapture) sees the grid's light times its bounce.
        fu.fa_gi[0] = float(tex.giBase);
        fu.fa_gi[1] = float(giCount);
        fu.fa_gi[2] = fr.giCapture ? 1.0f : 0.0f;
    }
    const ClusterUniforms& u = tex.uniforms;
    for (int c = 0; c < 4; ++c) {
        fu.fa_cl_vpx[c] = u.vpx[c];
        fu.fa_cl_vpy[c] = u.vpy[c];
        fu.fa_cl_vpw[c] = u.vpw[c];
        fu.fa_cl_fwd[c] = u.fwd[c];
        fu.fa_cl_grid[c] = u.grid[c];
        fu.fa_cl_info[c] = u.info[c];
    }
}

// ---- the scene's uniforms: shared by the main pass and the shadow pass of alphaMode "clip" materials ----
// Reads: world (settings, time), fr.cam, ctx.lights, the shadow plan (ctx.cascades, fits, atlas, shadowTgt), gpu. Writes: ctx.ss, ctx.white,
// ctx.lightView, ctx.shadowU, ctx.vuScene, ctx.fuScene.
void Renderer::Impl::scene_uniforms(DrawContext& ctx) {
    World& world = ctx.world;
    Frame& fr = ctx.fr;
    const std::vector<LightData>& lights = ctx.lights;
    SceneSettings& ss = ctx.ss;
    mesh_fa_mesh_vs_params_t& vuScene = ctx.vuScene;
    mesh_fa_mesh_fs_params_t& fuScene = ctx.fuScene;
    ss = world.settings();
    if (fr.cam.studio) {  // a neutral room: no scene ambient, sky or fog reaches the camera
        const float k = fr.cam.studioIntensity;
        ss.ambientLight = Color{0.2f * k, 0.2f * k, 0.22f * k, 1.0f};
        ss.skyColor = Color{0.55f * k, 0.58f * k, 0.65f * k, 1.0f};
        ss.horizonColor = Color{0.4f * k, 0.4f * k, 0.42f * k, 1.0f};
        ss.fogDensity = 0.0f;
    }
    // The camera's own fog (PostProcess.fog*, drawn from the depth inside the main pass) replaces the scene's: the two never add up. It is
    // only planned (fogFx.fog) when its prepass and shader exist, so a frame that cannot draw it keeps the scene's fog. The volumetric fog
    // (vol.on, planned the same way) replaces both.
    if (ctx.postPlan.fogFx.fog || ctx.postPlan.vol.on) ss.fogDensity = 0.0f;
    // Colours the author picked are sRGB values; a linear scene computes with linear light (sky, fog and ambient, below, and the
    // main pass's sky and clear colour read these).
    ss.ambientLight = to_scene(ss.ambientLight, fr.linear);
    ss.fogColor = to_scene(ss.fogColor, fr.linear);
    ss.skyColor = to_scene(ss.skyColor, fr.linear);
    ss.horizonColor = to_scene(ss.horizonColor, fr.linear);
    ctx.white = assets->white();
    ctx.lightView = ctx.white->view;
    // (ctx.lightAtlasView is set by collect_lights, with the rects of the lights.)
    ctx.decalView = ctx.white->view;
    copy_mat(vuScene.fa_view_proj, fr.cam.drawViewProj);
    copy_mat(vuScene.fa_light_vp, ctx.doShadows && ctx.cascades > 0 ? ctx.fits[0].viewProj : Mat4::identity());
    fill_shadow_block(ctx, gpu.is_gl(), debugView == DebugView::Cascades, ctx.shadowU);
    vuScene.fa_time[0] = float(world.time());
    vuScene.fa_time[1] = fr.cam.position.x;  // yzw: the camera position, for the vertex stage of a full-shader material
    vuScene.fa_time[2] = fr.cam.position.y;
    vuScene.fa_time[3] = fr.cam.position.z;
    fuScene.fa_camera_pos[0] = fr.cam.position.x;
    fuScene.fa_camera_pos[1] = fr.cam.position.y;
    fuScene.fa_camera_pos[2] = fr.cam.position.z;
    fuScene.fa_ambient[0] = ss.ambientLight.r;
    fuScene.fa_ambient[1] = ss.ambientLight.g;
    fuScene.fa_ambient[2] = ss.ambientLight.b;
    fuScene.fa_fog[0] = ss.fogColor.r;
    fuScene.fa_fog[1] = ss.fogColor.g;
    fuScene.fa_fog[2] = ss.fogColor.b;
    fuScene.fa_fog[3] = ss.fogDensity;
    // The lights of the view: the light table and the clusters in the data texture (light_clusters.h); fa_counts.x is how many of the
    // first lights the full-shader API fa_light_count() hands over.
    fuScene.fa_counts[0] = float(std::min<std::size_t>(lights.size(), 32));
    upload_lights(ctx);
    for (int c = 0; c < 4; ++c) lastClusterInfo[c] = fuScene.fa_cl_info[c];
    // The point and spot lights' shadow records are in the light texture (upload_lights): the shadows block says where (0 = none).
    if (ctx.localShadowBase >= 0) ctx.shadowU.fa_shadow_lcfg[0] = float(ctx.localShadowBase + 1);
    fuScene.fa_counts[2] = gpu.is_gl() ? 1.0f : 0.0f;
    // The contact shadows' view of the camera (M73.2c; shaders/light_loop.glsl, fa_contact): three rows of the view-projection matrix and the
    // forward axis, the prepass's size and the distance where the shadows are gone. fa_ct_a.x, which turns them on, is set per draw (fill_fs). The
    // subsurface draw reads the same view for its visibility test against the prepass.
    if (ctx.contactOn || ctx.sssOn || ctx.xmit.want) {
        const Mat4& vp = fr.cam.drawViewProj;
        const Vec3& fwd = fr.cam.forward;
        for (int c = 0; c < 4; ++c) {
            fuScene.fa_ct_vpx[c] = vp.at(c, 0);
            fuScene.fa_ct_vpy[c] = vp.at(c, 1);
            fuScene.fa_ct_vpw[c] = vp.at(c, 3);
        }
        fuScene.fa_ct_fwd[0] = fwd.x;
        fuScene.fa_ct_fwd[1] = fwd.y;
        fuScene.fa_ct_fwd[2] = fwd.z;
        fuScene.fa_ct_fwd[3] = -dot(fwd, fr.cam.position);
        fuScene.fa_ct_a[1] = gpu.is_gl() ? 1.0f : 0.0f;
        fuScene.fa_ct_a[2] = float(ctx.camPx.w);
        fuScene.fa_ct_a[3] = float(ctx.camPx.h);
        fuScene.fa_ct_b[0] = kContactShadowFadeEnd;  // (the atlas of a transmissive draw reads the same rows and size)
    }
    fuScene.fa_env_sky[0] = ss.skyColor.r;
    fuScene.fa_env_sky[1] = ss.skyColor.g;
    fuScene.fa_env_sky[2] = ss.skyColor.b;
    fuScene.fa_env_horizon[0] = ss.horizonColor.r;
    fuScene.fa_env_horizon[1] = ss.horizonColor.g;
    fuScene.fa_env_horizon[2] = ss.horizonColor.b;
    fuScene.fa_pbr[3] = 0.0015f;
    fuScene.fa_time[0] = float(world.time());
    plan_env(ctx);  // before fuBlend is copied: it sets the environment flag of fuScene
    // The blended meshes fog themselves with the stack's fog (the same numbers as the full-screen draw, the same formula): by their own
    // distance, not by the opaque mesh behind them, and over the sky too.
    ctx.fuBlend = fuScene;
    const FogFxPlan& ff = ctx.postPlan.fogFx;
    if (ff.fog) {
        mesh_fa_mesh_fs_params_t& fb = ctx.fuBlend;
        fb.fa_fog[0] = ff.color[0];
        fb.fa_fog[1] = ff.color[1];
        fb.fa_fog[2] = ff.color[2];
        fb.fa_fog[3] = ff.density;
        fb.fa_fog_b[0] = ff.start;
        fb.fa_fog_b[1] = ff.heightDensity;
        fb.fa_fog_b[2] = ff.heightBase;
        fb.fa_fog_b[3] = ff.heightFalloff;
        fb.fa_fog_c[0] = ff.forward.x;
        fb.fa_fog_c[1] = ff.forward.y;
        fb.fa_fog_c[2] = ff.forward.z;
        fb.fa_fog_c[3] = ff.ortho ? 1.0f : 0.0f;
    }
}

static_assert(
    kMaterialEnvView == VIEW_mesh_fa_probe_atlas && kMaterialEnvSampler == SMP_mesh_fa_env_smp,
    "the probe atlas slots of mesh_common.glsl and render_internal.h (and tools/common/shaders.h) must agree");

// The sky environment (renderer_env.h) of a job: with SceneSettings.skyMaterial, the meshes light and reflect the sky
// that is seen, baked into two cubes. Reads: ctx.ss, ctx.lights, ctx.fuScene.fa_time (all set), the job's frame.
// Writes: ctx.envActive (the meshes of this job sample the cubes), ctx.envBake (this job declares the "sky-env" pass,
// which bakes them), ctx.envKey, ctx.envSky (what the pass draws). The meshes read the sky from its entry of the probe atlas
// (the bake pass writes it, probes_write_sky), not from the cubes. The cubes are baked again when their key changes: everything the sky depends on (the material and
// its build, its params and textures, the colours, the sun when the snippet reads it, the colour space) and, for an
// animated sky (its snippet reads the time), the game time in steps of kEnvTimeStep seconds (the sky is drawn at the
// step's start, so a run draws the same images at any frame rate). The first job of a frame that wants an environment
// decides it for the frame; a later job whose sky differs draws its meshes with the gradient (they share the cubes).
void Renderer::Impl::plan_env(DrawContext& ctx) {
    ctx.envActive = ctx.envBake = ctx.envSliced = ctx.physMainOn = false;
    ctx.skyPlannedMat = nullptr;
    ctx.hdriMain = nullptr;
    ctx.envTap = 0.0f;
    // environmentIntensity multiplies the background of an HDRI and the lighting of any sky (a value that is not a number is 1).
    ctx.envGain =
        std::isfinite(ctx.ss.environmentIntensity) ? std::clamp(ctx.ss.environmentIntensity, 0.0f, 100.0f) : 1.0f;
    // The rotation is made safe once: a script can write any number (NaN, 1e30), and the key and the drawing must agree.
    ctx.envRotation = std::isfinite(ctx.ss.environmentRotation) ? std::fmod(ctx.ss.environmentRotation, 360.0f) : 0.0f;
    const Frame& fr = ctx.fr;
    if (!ctx.doMainPass || !fr.wantWorld || fr.cam.studio) return;
    // The environment map (renderer_hdri.h says who decides what): an HDRI that loaded lights the meshes whatever the background is.
    const HdriAsset* hdri = nullptr;
    if (!ctx.ss.environmentMap.empty() && hdriSky.ready(gpu)) hdri = assets->hdri(ctx.ss.environmentMap);
    // It is also the background unless a sky material is set (even one that failed: the gradient shows, as without an HDRI) or
    // environmentBackground is off.
    if (hdri && ctx.ss.environmentBackground && ctx.ss.skyMaterial.empty()) ctx.hdriMain = hdri;
    // The physical sky (SceneSettings.skyModel) takes the place of the gradient, never of a sky material.
    const bool phys = ctx.ss.skyModel == SkyModel::Physical && ctx.ss.skyMaterial.empty() && physSky.ready(gpu);
    MaterialAsset* mat = (phys || hdri) ? nullptr : sky_material(ctx.ss);
    if (!mat && !phys && !hdri) return;
    SkyDraw sky;
    std::uint64_t h = 0xcbf29ce484222325ull;
    auto mix = [&h](std::uint64_t v) {
        h = (h ^ v) * 0x100000001b3ull;
        h ^= h >> 29;
    };
    auto mixf = [&mix](float f) {
        std::uint32_t u;
        std::memcpy(&u, &f, sizeof(u));
        mix(u);
    };
    std::uint64_t staticKey = 0;
    if (hdri) {
        // The cube starts as the picture itself (rotated, in the scene's colour space, brightness 1): the bake's gain applies it later.
        sky.hdri = hdri;
        sky.hdriRotation = ctx.envRotation;
        sky.linear = fr.linear;
        ctx.envTap = kHdriTapLimit;
        mix(std::hash<std::string>{}(hdri->path));
        mix(hdri->serial);
        mix(hdri->image.id);
        mixf(sky.hdriRotation);
        mix(sky.linear ? 1 : 0);
        if (phys) {  // the main pass may still draw the physical sky (environmentBackground off): its state is the frame's
            PhysicalSkyState st;
            st.s = physical_sky_settings(ctx.ss);
            for (int i = 0; i < 3; ++i) {
                st.sunDir[i] = ctx.physSunDir[i];
                st.sunColor[i] = ctx.physSunColor[i];
            }
            st.linear = fr.linear;
            const double t = ctx.world.time();
            st.time = std::isfinite(t) && t > 0.0 ? std::min(t, 1.0e9) : 0.0;
            ctx.physMain = st;
            ctx.physMainOn = fr.cam.perspective && fr.cam.clear && !fr.cam.noSky && !ctx.hdriMain;
        }
    } else if (phys) {
        // The picture draws the exact sun and clock; the environment the quantised ones (physical_sky.h), so a run bakes the same
        // images at any frame rate.
        PhysicalSkyState st;
        st.s = physical_sky_settings(ctx.ss);
        for (int i = 0; i < 3; ++i) {
            st.sunDir[i] = ctx.physSunDir[i];
            st.sunColor[i] = ctx.physSunColor[i];
        }
        st.linear = fr.linear;
        const double t = ctx.world.time();
        st.time = std::isfinite(t) && t > 0.0 ? std::min(t, 1.0e9) : 0.0;
        ctx.physMain = st;
        ctx.physMainOn = fr.cam.perspective && fr.cam.clear && !fr.cam.noSky;
        const PhysicalSkyState q = sky_quantised(st);
        sky.physical = true;
        sky.sunDisc = false;  // the light is the sun in the environment
        sky.slot = 1;
        sky.phys = q;
        staticKey = sky_env_static_key(q);
        h = sky_env_key(q) ^ 0x9e3779b97f4a7c15ull;
        for (int i = 0; i < 3; ++i) ctx.envSun[i] = q.sunDir[i];
        ctx.envStatic = staticKey;
    } else {
        fill_sky(*this, ctx, mat, sky);
        ctx.skyPlannedMat = mat;
        std::copy(std::begin(sky.in.textures), std::end(sky.in.textures), ctx.skyPlanned);
        sky.time = 0.0f;  // only an animated sky sees the time, quantized below
        std::int64_t step = 0;
        if (mat->animated) {
            const double t = ctx.world.time();
            step = std::isfinite(t) && t > 0.0 ? std::int64_t(std::min(t, 1.0e9) / kEnvTimeStep) : 0;
            sky.time = float(double(step) * kEnvTimeStep);
        }
        mix(std::hash<std::string>{}(mat->path));
        mix(std::uint64_t(mat->generation));
        mix(mat->programs[0].shader.id);
        mix(std::uint64_t(step));
        for (const auto& p : sky.in.params)
            for (float c : p) mixf(c);
        for (const TextureAsset* t : sky.in.textures) mix(t ? t->gpu_view().id : 0);
        for (float c : sky.skyColor) mixf(c);
        for (float c : sky.horizonColor) mixf(c);
        if (mat->usesSun)  // a sky that never reads the sun is not baked again when the sun turns
            for (float c : sky.sun) mixf(c);
        mix(sky.linear ? 1 : 0);
    }
    mixf(ctx.envGain);
    // Whether (and how) this job bakes the cubes for the key h. A sky material is baked whole when its key changes. The physical
    // sky is baked whole the first time, when anything but the sun's direction and the clouds' clock changed, and when the sun
    // moved a degree or more since the last bake started; else it follows the sun in slices, one per frame (renderer_env.h): a
    // sequence that is running goes on whatever the sky has become meanwhile, and a new one starts when the key differs.
    auto decide = [&](DrawContext& c) {
        c.envBake = c.envSliced = false;
        if (!skyEnv.baked()) {
            c.envBake = true;
            return;
        }
        if (!phys || hdri) {
            c.envBake = skyEnv.key() != h;
            return;
        }
        const float* ts = skyEnv.tag_sun();
        const float dx = c.envSun[0] - ts[0], dy = c.envSun[1] - ts[1], dz = c.envSun[2] - ts[2];
        const bool whole = skyEnv.tag_key() != c.envStatic || dx * dx + dy * dy + dz * dz > kSkyBakeJump * kSkyBakeJump;
        if (whole) {
            c.envBake = true;
        } else if (skyEnv.busy() || skyEnv.key() != h) {
            c.envBake = c.envSliced = true;
        }
    };
    const bool pictureJob = !ctx.plan.view;
    if (envFrame != frameSerial) {
        envFrame = frameSerial;
        envFrameOk = skyEnv.ready(gpu);
        envFrameKey = h;
        envFrameView = !pictureJob;
        envJobs.clear();
        if (envFrameOk) decide(ctx);
    } else if (envFrameKey != h) {
        // Jobs of the picture (a camera of the game's frame) are planned after the render targets and views, which
        // would otherwise fix the key with a sky of their own (a material texture "target:<own>" is the checker for the
        // camera that renders into it, so their key differs) and leave the main camera with the gradient. The picture
        // wins: the jobs that took the first key lose the environment (their passes read the job's fields when they
        // run), and this job bakes its own.
        if (!pictureJob || !envFrameView) return;
        for (DrawContext* other : envJobs) {
            other->envActive = other->envBake = other->envSliced = false;
            other->fuScene.fa_env_sky[3] = 0.0f;
            other->fuBlend.fa_env_sky[3] = 0.0f;
        }
        envJobs.clear();
        envFrameKey = h;
        envFrameView = false;
        if (envFrameOk) decide(ctx);
    }
    if (!envFrameOk) return;
    envJobs.push_back(&ctx);
    ctx.envActive = true;
    ctx.envKey = h;
    ctx.envSky = sky;
    // fa_env_sky.w (the sky's entry of the probe atlas is written) is set per draw by fill_probe_fs.
}

// Binds the vertex buffers of a custom material's extras (MeshExtras): its per-instance params from `data` (the floats
// of this batch start at `floatOffset`) and the part's uv1 and color1 channels, as the pipeline made with m.extras()
// reads them.
static void bind_extras(sg_bindings& b, const MaterialAsset& m, const SubMesh& part, sg_buffer data,
                        std::uint32_t floatOffset) {
    if (m.instanceVec4 > 0) {
        b.vertex_buffers[kInstanceDataBuffer] = data;
        b.vertex_buffer_offsets[kInstanceDataBuffer] = int(floatOffset * sizeof(float));
    }
    if (m.uv1) b.vertex_buffers[kUv1Buffer] = part.uv1Vb;
    if (m.color1) b.vertex_buffers[kColor1Buffer] = part.color1Vb;
}

// What one part of an item is drawn with (reads ctx.white).
Renderer::Impl::PartDraw Renderer::Impl::part_draw(DrawContext& ctx, const MeshItem& mi, const SubMesh& part) {
    TextureAsset* white = ctx.white;
    PartDraw d;
    // A material that built but declares a channel this part lacks (vertexAttributes) is drawn as the error material
    // too.
    const char* lacks = mi.material && mi.material->ok ? missing_channel(*mi.material, part) : nullptr;
    if (lacks) note_missing_channel(mi, part, lacks);
    d.error = mi.material && (!mi.material->ok || lacks);
    d.mat = mi.material && mi.material->ok && !lacks ? mi.material : nullptr;
    d.tex = d.error ? white : mi.tex ? mi.tex : (part.texture ? part.texture : white);
    d.normal = d.error ? nullptr : (mi.normalTex ? mi.normalTex : part.normalTex);
    d.mr = d.error || !part.mrTex ? white : part.mrTex;
    d.occlusion = d.error || !part.occlusionTex ? white : part.occlusionTex;
    d.emissive = d.error || !part.emissiveTex ? white : part.emissiveTex;
    if (mi.lm.mesh && mi.lm.page) d.lightmap = mi.lm.page->view;
    return d;
}

void Renderer::Impl::note_missing_channel(const MeshItem& mi, const SubMesh& part, const char* what) {
    MaterialAsset& mat = *mi.material;
    const bool uv = std::string(what) == "uv1";
    // Already logged? One hash lookup, no string: this runs for every part of every batch of every pass of every frame.
    // The part's index: it is one of the mesh's parts, or of the parts of its lightmap geometry (the same order).
    const SubMesh* first =
        mi.lm.mesh && !mi.lm.mesh->parts.empty() &&
                std::less_equal<const SubMesh*>()(mi.lm.mesh->parts.data(), &part) &&
                std::less<const SubMesh*>()(&part, mi.lm.mesh->parts.data() + mi.lm.mesh->parts.size())
            ? mi.lm.mesh->parts.data()
            : mi.mesh->parts.data();
    const std::uint64_t key =
        (std::uint64_t(reinterpret_cast<std::uintptr_t>(mi.mesh)) * 1000003u + std::uint64_t(&part - first)) * 2u +
        (uv ? 0u : 1u);
    if (!mat.missingNoted.insert(key).second) return;
    const std::string mesh = mi.mesh->key;
    const std::string channel = uv ? "TEXCOORD_1" : "COLOR_1";
    const bool primitive = MeshStore::is_id(mesh);
    assets->note_failure(
        "material-mesh", mat.path + " on " + mesh,
        "material '" + mat.path + "' lists \"" + what + "\" in vertexAttributes, but " +
            (primitive ? "'" + mesh +
                             "' is a built-in primitive (cube, plane, ...), which has only position, normal and uv, "
                             "no TEXCOORD_1 or COLOR_1"
                       : "part " + std::to_string(&part - first) + " of mesh '" + mesh + "' has no " + channel +
                             " attribute") +
            ". The meshes using both are drawn magenta.",
        primitive
            ? "Use a glTF model that has " + channel + " (the built-in primitives never do), or remove \"" + what +
                  "\" from the material's vertexAttributes."
            : "Export the model with a second " + std::string(uv ? "UV set" : "vertex colour set") + " (glTF " +
                  channel + "), remove \"" + what + "\" from the material's vertexAttributes, or use another mesh.");
}

// The material layers of one part (fa_layers_a..d): the glTF material's factors, replaced field by field by the MeshRenderer's
// when that is not at its default (a MeshRenderer field at its default leaves the model's value). Colours: the glTF ones are
// linear values, the MeshRenderer's go through to_scene like its other colours. A MeshRenderer value outside its range is
// clamped by the shader's own limits (the doc strings give the ranges); NaN counts as the default.
static void fill_layers(mesh_fa_mesh_fs_params_t& fu, const MeshRenderer& mr, const SubMesh& part, bool error,
                        bool linear) {
    auto num = [](float v, float fallback) { return std::isfinite(v) ? v : fallback; };
    const MaterialLayers& g = part.layers;
    static const MeshRenderer defaults;
    float coat = 0, coatRough = 0, sheenRough = 0, aniso = 0, rotation = 0, spec = 1, ior = 1.5f;
    float sheen[3] = {0, 0, 0}, specColor[3] = {1, 1, 1};
    float transmission = 0, thickness = 0, attDistance = 0, attColor[3] = {1, 1, 1};
    if (!error) {
        auto pick = [&](float m, float def, float fromModel) { return (num(m, def) != def) ? num(m, def) : fromModel; };
        coat = std::clamp(pick(mr.clearcoat, defaults.clearcoat, g.clearcoat), 0.0f, 1.0f);
        coatRough = std::clamp(pick(mr.clearcoatRoughness, defaults.clearcoatRoughness,
                                    g.clearcoat > 0.0f ? g.clearcoatRoughness : defaults.clearcoatRoughness),
                               0.0f, 1.0f);
        const Color sc = to_scene(mr.sheenColor, linear);
        const bool mrSheen = mr.sheenColor.r > 0.0f || mr.sheenColor.g > 0.0f || mr.sheenColor.b > 0.0f;
        const bool modelSheen = g.sheenColor != MaterialLayers{}.sheenColor;
        sheen[0] = mrSheen ? sc.r : g.sheenColor[0];
        sheen[1] = mrSheen ? sc.g : g.sheenColor[1];
        sheen[2] = mrSheen ? sc.b : g.sheenColor[2];
        sheenRough = std::clamp(
            pick(mr.sheenRoughness, defaults.sheenRoughness, modelSheen ? g.sheenRoughness : defaults.sheenRoughness),
            0.0f, 1.0f);
        aniso = std::clamp(pick(mr.anisotropy, 0.0f, g.anisotropy), -1.0f, 1.0f);
        rotation = num(mr.anisotropyRotation, 0.0f) != 0.0f ? num(mr.anisotropyRotation, 0.0f) * (3.14159265f / 180.0f)
                                                            : g.anisotropyRotation;
        spec = std::clamp(pick(mr.specular, 1.0f, g.specular), 0.0f, 1.0f);
        ior = std::clamp(pick(mr.ior, 1.5f, g.ior), 1.0f, 3.0f);
        for (int i = 0; i < 3; ++i) specColor[i] = g.specularColor[std::size_t(i)];
        // Transmission and volume (M73.6b): a MeshRenderer field that is not at its default replaces the model's value, as above.
        transmission = std::clamp(pick(mr.transmission, defaults.transmission, g.transmission), 0.0f, 1.0f);
        thickness = std::clamp(pick(mr.thickness, defaults.thickness, g.thickness), 0.0f, 1000.0f);
        attDistance = std::clamp(pick(mr.attenuationDistance, defaults.attenuationDistance, g.attenuationDistance),
                                 0.0f, 100000.0f);
        const Color ac = to_scene(mr.attenuationColor, linear);
        const bool mrAtt = mr.attenuationColor.r < 1.0f || mr.attenuationColor.g < 1.0f || mr.attenuationColor.b < 1.0f;
        attColor[0] = std::clamp(mrAtt ? ac.r : g.attenuationColor[0], 0.0f, 1.0f);
        attColor[1] = std::clamp(mrAtt ? ac.g : g.attenuationColor[1], 0.0f, 1.0f);
        attColor[2] = std::clamp(mrAtt ? ac.b : g.attenuationColor[2], 0.0f, 1.0f);
    }
    fu.fa_layers_a[0] = coat;
    fu.fa_layers_a[1] = coatRough;
    fu.fa_layers_a[2] = aniso;
    fu.fa_layers_a[3] = rotation;
    fu.fa_layers_b[0] = sheen[0];
    fu.fa_layers_b[1] = sheen[1];
    fu.fa_layers_b[2] = sheen[2];
    fu.fa_layers_b[3] = sheenRough;
    fu.fa_layers_c[0] = spec;
    fu.fa_layers_c[1] = ior;
    fu.fa_layers_c[2] = error ? 0.0f : float(part.layersPacked);
    fu.fa_layers_c[3] = 0.0f;
    for (int i = 0; i < 3; ++i) fu.fa_layers_d[i] = specColor[i];
    fu.fa_layers_d[3] = 0.0f;
    fu.fa_tr_a[0] = transmission;
    fu.fa_tr_a[1] = thickness;
    fu.fa_tr_a[2] = attDistance;
    for (int i = 0; i < 3; ++i) fu.fa_tr_b[i] = attColor[i];
}

// The reflection part of the fragment parameters (mesh_common.glsl fa_atlas, fa_rpa_*, fa_rpb_*; docs/design/ARCHITECTURE_PROBES.md,
// "What the meshes read"): where the atlas and the sky's entry are, and the tile, capture position and box of each probe the mesh picked
// (render_scene.cpp; at most two). A probe that is not in the atlas any more (evicted, its capture not done) is left out and the sky takes
// its share. A capture face (Frame::noProbes) and an unlit mesh read the sky only.
void Renderer::Impl::fill_probe_fs(const DrawContext& ctx, const MeshItem& mi, bool lit, mesh_fa_mesh_fs_params_t& fu) {
    const ProbeSystem& ps = probes;
    const bool atlas = ps.atlas.valid();
    fu.fa_atlas[0] = atlas ? float(ps.atlas.size) : 1.0f;
    fu.fa_atlas[1] = ps.gpu.rgba8() ? 1.0f : 0.0f;
    const bool sky = atlas && ctx.envActive && ps.skyPlaced && ps.skyWrittenFrame != 0;
    fu.fa_atlas[2] = sky ? float(ps.skyTile.x) : 0.0f;
    fu.fa_atlas[3] = sky ? float(ps.skyTile.y) : 0.0f;
    fu.fa_env_sky[3] = sky ? 1.0f : 0.0f;
    float* tile[2] = {fu.fa_rpa_tile, fu.fa_rpb_tile};
    float* pos[2] = {fu.fa_rpa_pos, fu.fa_rpb_pos};
    float* box[2][3] = {{fu.fa_rpa_bx, fu.fa_rpa_by, fu.fa_rpa_bz}, {fu.fa_rpb_bx, fu.fa_rpb_by, fu.fa_rpb_bz}};
    for (int k = 0; k < 2; ++k) {
        for (int c = 0; c < 4; ++c) {
            tile[k][c] = 0.0f;
            pos[k][c] = 0.0f;
            for (int r = 0; r < 3; ++r) box[k][r][c] = 0.0f;
        }
    }
    if (!atlas || !lit || ctx.fr.noProbes || !mi.refl.any()) return;
    float shares[2];
    mi.refl.shares(shares);
    for (int k = 0; k < 2; ++k) {
        const std::uint16_t idx = mi.refl.index[k];
        if (!idx || idx > probeVolumes.size() || !(shares[k] > 0.0f)) continue;
        const ProbeVolume& v = probeVolumes[std::size_t(idx) - 1];
        const auto it = ps.entries.find(v.id);
        if (it == ps.entries.end() || !it->second.placed || !it->second.tileValid) continue;
        const ProbeTile& t = it->second.tile;
        tile[k][0] = float(t.x);
        tile[k][1] = float(t.y);
        tile[k][2] = float(t.resolution);
        tile[k][3] = shares[k];
        pos[k][0] = v.position.x;
        pos[k][1] = v.position.y;
        pos[k][2] = v.position.z;
        pos[k][3] = v.projection ? 1.0f : 0.0f;
        for (int r = 0; r < 3; ++r)
            for (int c = 0; c < 4; ++c) box[k][r][c] = v.rows[r][c];
    }
}

// The fragment parameters (fa_mesh_fs_params) of one part (reads ctx.fuScene, or ctx.fuBlend for a blended part, ctx.doShadows).
mesh_fa_mesh_fs_params_t Renderer::Impl::fill_fs(DrawContext& ctx, const MeshItem& mi, const SubMesh& part,
                                                 const PartDraw& d, bool blended) {
    const mesh_fa_mesh_fs_params_t& fuScene = blended ? ctx.fuBlend : ctx.fuScene;
    const bool doShadows = ctx.doShadows;
    const MeshRenderer& mr = *mi.mr;
    mesh_fa_mesh_fs_params_t fu = fuScene;
    fu.fa_counts[3] = float(
        decal_recv(mr));  // 0 = receives no decal, else 1 + MeshRenderer.decalLayer (the view's decals: fa_counts.y)
    fu.fa_gi[3] = mi.lodFade;  // the dithered LOD cross-fade (mesh_common.glsl fa_lod_dither); 0 = none
    const bool unlit = mr.unlit || d.error || (d.mat && d.mat->lighting == "unlit");
    fill_probe_fs(ctx, mi, !unlit, fu);
    // MeshRenderer.emissiveStrength scales both the component's colour and the model's own emission; a NaN or negative
    // value (a script wrote it) counts as 0, no glow.
    const float strength = mr.emissiveStrength > 0.0f ? std::min(mr.emissiveStrength, 1000.0f) : 0.0f;
    const bool linear = ctx.fr.linear;
    if (!d.error) {
        const Color emissive = to_scene(mr.emissive, linear);
        fu.fa_emissive[0] = emissive.r * strength;
        fu.fa_emissive[1] = emissive.g * strength;
        fu.fa_emissive[2] = emissive.b * strength;
    }
    fu.fa_emissive[3] = unlit ? 1.0f : 0.0f;
    fu.fa_pbr[2] = (doShadows && mr.receiveShadows) ? 1.0f : 0.0f;
    // Contact shadows: an opaque mesh that receives shadows with a program of the engine's template (a full shader has none; a blended or
    // transmissive draw has no prepass at the screen slot). The shadow and prepass passes run before the main pass sets ctx.screenView, so
    // they (and a main pass whose prepass image is missing) draw with it off: the slot there holds the white image, not a prepass.
    fu.fa_ct_a[0] =
        (ctx.contactOn && ctx.screenView.id && !blended && mr.receiveShadows && !(d.mat && d.mat->full)) ? 1.0f : 0.0f;
    bool authoredPart = false;
    const Color partColor = d.error ? Color{} : part_base_color(mr, part, &authoredPart);
    const Color base = d.error ? Color{1, 0, 1, 1}
                               : to_scene(mr.color, linear) * (authoredPart ? to_scene(partColor, linear) : partColor);
    fu.fa_base_color[0] = base.r;
    fu.fa_base_color[1] = base.g;
    fu.fa_base_color[2] = base.b;
    fu.fa_base_color[3] = base.a;
    // glTF materials bring their own metallic/roughness; primitives use the MeshRenderer's.
    fu.fa_pbr[0] = part.hasPbr ? saturate(part.metallic) : saturate(mr.metallic);
    fu.fa_pbr[1] = part.hasPbr ? saturate(part.roughness) : saturate(mr.roughness);
    if (!d.error) {
        fu.fa_model_emissive[0] = part.emissiveFactor.r * strength;
        fu.fa_model_emissive[1] = part.emissiveFactor.g * strength;
        fu.fa_model_emissive[2] = part.emissiveFactor.b * strength;
    }
    fu.fa_maps[0] = mi.normalTex ? mr.normalScale : part.normalScale;
    fu.fa_maps[1] = part.occlusionStrength;
    fu.fa_maps[2] = d.normal ? 1.0f : 0.0f;
    // How the shader reads each texture (mesh_common.glsl fa_tex_fix): the colour ones as linear light in a linear scene, the data
    // ones (normal, metallic-roughness, occlusion) as the file's values, whichever format the images were made in.
    fu.fa_maps[3] = float(d.tex->tex_fix(linear, true) + 4 * d.emissive->tex_fix(linear, true) +
                          16 * (d.normal ? d.normal->tex_fix(linear, false) : 0) + 64 * d.mr->tex_fix(linear, false) +
                          256 * d.occlusion->tex_fix(linear, false));
    fill_layers(fu, mr, part, d.error, linear);
    // A transmissive draw (M73.6b) reads the refraction atlas at the screen slot, or, with no atlas this frame, is a plain blend (the
    // shader tells them by fa_tr_a.w). An unlit surface or one that draws a full shader transmits nothing.
    if (unlit || (d.mat && d.mat->full) || fu.fa_tr_a[0] <= 0.0f) {
        fu.fa_tr_a[0] = 0.0f;
        fu.fa_tr_a[3] = 0.0f;
    } else {
        fu.fa_tr_a[3] = (blended && ctx.xmit.on) ? 1.0f : 2.0f;
        fu.fa_tr_b[3] = float(ctx.xmit.levels);
    }
    // Baked light probes (M73.4d): the SH the mesh receives (coverage 0 = none: the shader keeps the sky's ambient).
    for (int k = 0; k < 9; ++k)
        for (int c = 0; c < 4; ++c) fu.fa_probe_sh[k][c] = 0.0f;
    if (mi.probe && !unlit && !mi.lm.mesh && !d.error) {
        for (int k = 0; k < 9; ++k) {
            fu.fa_probe_sh[k][0] = mi.probe->sh.c[k].x;
            fu.fa_probe_sh[k][1] = mi.probe->sh.c[k].y;
            fu.fa_probe_sh[k][2] = mi.probe->sh.c[k].z;
        }
        fu.fa_probe_sh[0][3] = std::clamp(mi.probe->coverage, 0.0f, 1.0f);
    }
    if (mi.flash.a > 0.0f && !d.error) {
        // A flash (feel.h) needs no shader change: the surface colour fades to nothing and the emission, which both the lit
        // and the unlit path add at the end (fog comes after), carries the flash colour. Lit meshes keep a little
        // specular and image-based reflection of their own.
        const float k = 1.0f - std::min(mi.flash.a, 1.0f), a = 1.0f - k;
        const Color flashColor = to_scene(mi.flash, linear);
        const float flash[3] = {flashColor.r, flashColor.g, flashColor.b};
        for (int i = 0; i < 3; ++i) {
            fu.fa_base_color[i] *= k;
            fu.fa_emissive[i] = fu.fa_emissive[i] * k + flash[i] * a;
            fu.fa_model_emissive[i] *= k;
        }
    }
    return fu;
}

// The material that draws the sky (SceneSettings.skyMaterial), or nullptr: the engine's gradient. A material that did
// not build (its own error was logged when it failed, and the previous good build, when there is one, stays in use) or
// that is not of kind "sky" draws the gradient, and the frame's materialFallbacks names it; a material of the wrong
// kind is reported once.
MaterialAsset* Renderer::Impl::sky_material(const SceneSettings& ss) {
    if (ss.skyMaterial.empty()) {
        warnedSkyMaterial.clear();
        return nullptr;
    }
    MaterialAsset* m = assets->material(ss.skyMaterial);
    const bool sky = m && m->ok && m->kind == MaterialKind::Sky;
    const bool hasProgram = sky && m->programs[0].shader.id != 0;
    if (hasProgram) {
        warnedSkyMaterial.clear();  // a good one is back: the next bad one is reported again
        return m;
    }
    if (std::find(stats.materialFallbacks.begin(), stats.materialFallbacks.end(), ss.skyMaterial) ==
        stats.materialFallbacks.end())
        stats.materialFallbacks.push_back(ss.skyMaterial);
    // Built but unusable: another kind, or a sky with no GPU program (the build error of a broken one is logged by
    // Assets).
    if (m && m->ok && warnedSkyMaterial != m->path) {
        warnedSkyMaterial = m->path;
        if (sky)
            FA_ERROR("render",
                     "SceneSettings.skyMaterial '{}' built but has no GPU program, so the built-in sky is drawn. Hint: "
                     "run `factoria validate` and check the graphics driver log lines above.",
                     m->path);
        else
            FA_ERROR(
                "render",
                "SceneSettings.skyMaterial '{}' is a \"{}\" material, not a \"sky\" one, so the built-in sky is "
                "drawn. Hint: set \"kind\": \"sky\" in the material (docs/SHADERS.md, \"Sky materials\"), or point "
                "skyMaterial at a sky material.",
                m->path, material_kind_name(m->kind));
    }
    return nullptr;
}

void Renderer::Impl::material_inputs(const MeshItem& mi, MaterialAsset* mat, MaterialInputs& in) {
    if (mi.impostor) {  // a card of an impostor: the draw's block and its two atlases (renderer_impostor.h)
        std::memset(in.params, 0, sizeof(in.params));
        std::memcpy(in.params, mi.impostor->params, std::min(sizeof(in.params), sizeof(mi.impostor->params)));
        for (int i = 0; i < 2; ++i) in.textures[i] = mi.impostor->textures[i];
        return;
    }
    if (mi.terrain) {  // a node of a terrain: the draw's block and textures (renderer_terrain.h)
        std::memset(in.params, 0, sizeof(in.params));
        std::memcpy(in.params, mi.terrain->params, std::min(sizeof(in.params), sizeof(mi.terrain->params)));
        for (int i = 0; i < 4; ++i) in.textures[i] = mi.terrain->textures[i];
        in.vsTextures[3] =
            mi.terrain->holes;  // the vertex copy of the "control" slot (renderer_terrain.cpp, material())
        return;
    }
    pack_material_params(*mat, mi.mr->materialParams, in.params);
    for (std::size_t i = 0; i < mat->textures.size(); ++i)
        in.textures[i] = material_texture(*mat, int(i), mi.mr->materialParams, *assets);
}

// Bindings of a custom program: the engine's textures and the material's, only the slots the program declares (sokol
// rejects a binding the shader does not have). `shadowPass`: the shadow map is being drawn, so it is not sampled.
void Renderer::Impl::bind_textures(DrawContext& ctx, sg_bindings& b, const PartDraw& d, const MaterialProgram* prog,
                                   const MaterialInputs& in, bool shadowPass, bool opaquePhase) {
    TextureAsset* white = ctx.white;
    const bool doShadows = ctx.doShadows;
    b.views[VIEW_mesh_fa_tex] = d.tex->gpu_view();
    b.views[VIEW_mesh_fa_shadow_tex] = (doShadows && !shadowPass) ? ctx.shadowTgt.texView : white->view;
    b.views[VIEW_mesh_fa_normal_tex] = (d.normal ? d.normal : white)->gpu_view();
    b.views[VIEW_mesh_fa_mr_tex] = d.mr->gpu_view();
    b.views[VIEW_mesh_fa_occlusion_tex] = d.occlusion->gpu_view();
    b.views[VIEW_mesh_fa_emissive_tex] = d.emissive->gpu_view();
    b.views[VIEW_mesh_fa_lightmap] = d.lightmap.id ? d.lightmap : white->view;
    b.samplers[SMP_mesh_fa_smp] = gpu.sampler(SamplerKind::LinearRepeat);
    b.samplers[SMP_mesh_fa_shadow_smp] = gpu.sampler(SamplerKind::Nearest);
    // The light data of the view (the shadow pass has no lights: any image does for a program that declares the slot).
    b.views[VIEW_mesh_fa_light_tex] = shadowPass ? white->view : ctx.lightView;
    // The light atlas (LTC tables, cookies, IES profiles): the image the view's lights were laid out in, else the white image (nothing
    // reads it while no light has the data texture's extension texels).
    b.views[VIEW_mesh_fa_light_atlas] = (!shadowPass && ctx.lightAtlasView.id) ? ctx.lightAtlasView : white->view;
    b.views[VIEW_mesh_fa_decal_tex] = shadowPass ? white->view : ctx.decalView;
    // The screen slot (view 28): the prepass in the opaque phase of a frame with contact shadows; in the blended phase of a frame with a
    // transmissive draw, the refraction atlas (renderer_xmit.h); a white image otherwise (no fragment reads it).
    sg_view screenSlot = white->view;
    if (!shadowPass) {
        if (opaquePhase && ctx.contactOn && ctx.screenView.id)
            screenSlot = ctx.screenView;
        else if (!opaquePhase && ctx.xmit.on && ctx.xmit.atlasView.id)
            screenSlot = ctx.xmit.atlasView;
    }
    b.views[VIEW_mesh_fa_screen_tex] = screenSlot;
    // The sky environment (renderer_env.h): the baked cube (the reflection and the SH of the ambient), or a black one while the meshes use the gradient (every
    // mesh program of the main pass declares the slots; a custom program that does not has them dropped below).
    b.views[kMaterialEnvView] = probes.atlas.valid() ? probes.atlas.tex : white->view;
    b.samplers[kMaterialEnvSampler] = gpu.sampler(SamplerKind::LinearClamp);
    if (!prog) return;
    if (d.mat)
        for (std::size_t i = 0; i < d.mat->textures.size(); ++i) {
            b.views[kMaterialFirstView + int(i)] = in.textures[i]->gpu_view();
            b.samplers[kMaterialFirstSampler + int(i)] = gpu.sampler(d.mat->textures[i].sampler);
            // The same texture for vertex(): the vertex stage's copy of the slot (dropped below when the program has
            // none).
            b.views[kMaterialVsFirstView + int(i)] = b.views[kMaterialFirstView + int(i)];
            b.samplers[kMaterialVsFirstSampler + int(i)] = b.samplers[kMaterialFirstSampler + int(i)];
            if (in.vsTextures[i]) b.views[kMaterialVsFirstView + int(i)] = in.vsTextures[i]->gpu_view();
        }
    for (int i = 0; i < SG_MAX_VIEW_BINDSLOTS; ++i)
        if (!((prog->viewMask >> i) & 1u)) b.views[i] = {};
    for (int i = 0; i < SG_MAX_SAMPLER_BINDSLOTS; ++i)
        if (!((prog->samplerMask >> i) & 1u)) b.samplers[i] = {};
}

// ---- 2D light buffer ----
// Lit visuals without a normal map read the point lights added up in a light buffer instead of looping over them per
// pixel, so the number of lights costs only the pixels the lights cover. The pass runs when the world group has such
// a visual, a point light exists and the camera is orthographic (a perspective camera has no screen-space map of the
// 2D plane); else flat visuals use the loop over the first kDirectLights2D lights (litMode 0) or, with no point light,
// just the ambient and directional lights (litMode 2). Visuals with a normal map always use the loop (the direction of
// each light matters), and the screen-space groups too.
// Reads: fr (lights2d, shadowRows, camera, viewport), ctx.gWorld, ctx.ss.lightScale, ctx.partial, plan.view (no light buffer
// for a view), gpu light state. Writes: ctx.litMode, ctx.shadowRowsTex (uploads the shadow-rows texture), lightW / lightH and
// the light target (ensure_light_target). It draws nothing: litMode 1 is the graph's "light-buffer" pass (light_pass).
void Renderer::Impl::light_plan(DrawContext& ctx) {
    Frame& fr = ctx.fr;
    const JobPlan& plan = ctx.plan;
    const SceneSettings& ss = ctx.ss;
    const DrawContext::Group& gWorld = ctx.gWorld;
    int& litMode = ctx.litMode;
    sg_view& shadowRowsTex = ctx.shadowRowsTex;
    bool anyFlatLit = false, anyLit = false;
    std::vector<std::int32_t>
        flatMasks;  // the layer masks of the flat lit batches (the receivers of the light buffers)
    for (const QuadBatch& qb : gWorld.batches) {
        anyLit = anyLit || qb.lit;
        if (qb.lit && !qb.normal) {
            anyFlatLit = true;
            if (std::find(flatMasks.begin(), flatMasks.end(), qb.fx.layers) == flatMasks.end())
                flatMasks.push_back(qb.fx.layers);
        }
    }
    for (const QuadBatch& qb : ctx.gScreen.batches) anyLit = anyLit || qb.lit;
    // The cookies of the lights (Light2D.cookie): one cell of the atlas each, copied by the "light-cookies" pass.
    ctx.cookieCells = anyLit ? plan_cookies(fr) : std::vector<TextureAsset*>{};
    ctx.cookieView = ctx.cookieCells.empty() ? sg_view{} : cookieTarget.texView;
    int points = 0;
    for (const Light2DData& l : fr.lights2d) points += l.pos[3] >= 0.0f ? 1 : 0;
    shadowRowsTex = upload_shadow_rows(fr);
    float lightScale = ss.lightScale;
    lightScale = std::isfinite(lightScale) ? std::clamp(lightScale, 0.25f, 1.0f) : 1.0f;
    if (qualityOn) lightScale = std::max(0.25f, std::min(lightScale, quality.lightScale));  // the graphics preset's cap
    if (anyFlatLit && !fr.cam.perspective && gpu.light_format() != SG_PIXELFORMAT_NONE) {
        if (points == 0) {
            litMode = 2;
        } else if (!plan.view && gpu.light_ready()) {
            // M74 light layers: one buffer per distinct set of point lights the receivers in view reach (light_layers.h); one for
            // the default scene, whose every light is on every layer.
            ctx.layerPlan = plan_light_layers(fr.lights2d, flatMasks, true);
            if (ctx.layerPlan.overflowed && !warnedLightBuffers2d) {
                warnedLightBuffers2d = true;
                FA_WARN("render",
                        "The lit sprites, shapes and tilemaps in view reach more different sets of Light2D than the {} "
                        "light "
                        "buffers a frame has. Those past the first {} sets are shaded per pixel by the first {} lights "
                        "only, so "
                        "the other lights do not light them. Hint: use fewer distinct lightLayers masks on the visuals "
                        "in view, "
                        "or give the lights that must stay apart distinct bits.",
                        kMaxLightBuffers2D, kMaxLightBuffers2D, kDirectLights2D);
            }
            if (ctx.layerPlan.buffers.empty()) {
                litMode = 2;  // no mask reaches a point light: ambient and directional lights only
            } else if (ensure_light_target(lightScale, int(ctx.layerPlan.buffers.size()))) {
                litMode = 1;  // the buffers are the game target's size
            }
        }
    }
}

// ---- 2D global illumination ----
// The field of a 2D camera job (gi2d.h): when the scene has an enabled GlobalIllumination2D and the GPU has RGBA16F targets, the job gets a
// slot of images sized from its view and the settings, and the CPU gathers what glows and what blocks light into it; build_graph declares
// the passes that draw them. Without the component nothing is made. Reads: world (GlobalIllumination2D), fr (camera, mask), ctx.camPx,
// plan.view. Writes: ctx.gi2d, gi2d (slots, lastSettings).
void Renderer::Impl::gi2d_plan(DrawContext& ctx) {
    Frame& fr = ctx.fr;
    ctx.gi2d = Gi2dJobPlan{};
    if (ctx.plan.view || !fr.wantWorld || fr.cam.perspective || ctx.camPx.w <= 0 || ctx.camPx.h <= 0) return;
    Gi2dSettings s = gi2d_settings(ctx.world);
    gi2d.lastSettings = s;
    if (qualityOn) {  // the graphics preset's caps (the report above keeps what the scene asks for)
        if (!quality.gi2d) s.on = false;
        s.quality = std::min(s.quality, quality.gi2dQuality);
        s.resolutionScale = std::max(0.1f, std::min(s.resolutionScale, quality.gi2dResolutionScale));
    }
    if (!s.on) return;
    if (framePost)
        gi2d.note_gi_asked();  // only the game's frames count (an offscreen shot or probe keeps the warnings)
    if (!Gi2dSystem::float_targets_ok()) {
        if (!gi2d.warned_unsupported) {
            gi2d.warned_unsupported = true;
            FA_WARN("render", "{}", Gi2dSystem::unsupported_message(Renderer::backend_name()));
        }
        return;
    }
    const Rect& vis = fr.cam.visible;
    const float ppu = vis.w > 0.0f ? float(double(ctx.camPx.w) / double(vis.w)) : 0.0f;
    const Gi2dGeometry geom = gi2d_geometry(vis, ppu, s, ctx.world.origin().x, ctx.world.origin().y);
    if (!geom.valid) return;
    // The cascades' counts for the quality, against the platform's budget (a phone or a browser has the smaller one): over it, no field at all.
    const sg_backend gfxBackend = sg_query_backend();
    const bool mobile = gfxBackend == SG_BACKEND_GLES3 || gfxBackend == SG_BACKEND_METAL_IOS;
    const Gi2dCascadePlan cascadePlan = gi2d_cascade_plan(s.quality, geom, mobile);
    // The fields the earlier jobs of this frame already planned, in slots and in bytes (the whole frame has one budget).
    int slot = 0;
    std::uint64_t usedBytes = 0;
    for (const auto& c : jobContexts) {
        const DrawContext* other = static_cast<const DrawContext*>(c.get());
        if (c.get() == &ctx || !other->gi2d.active || !other->gi2d.field) continue;
        ++slot;
        usedBytes += other->gi2d.field->cascade.totalBytes;  // at most 4 fields of at most 2^32 bytes each: no overflow
    }
    const std::string why = cascadePlan.ok ? gi2d_total_budget_why(usedBytes, cascadePlan, mobile) : cascadePlan.why;
    if (!why.empty()) {
        // Once per reason: another quality, range or size says so again.
        if (gi2d.budget_warn_once(why)) {
            FA_WARN("render", "2D global illumination is off: {} The scene is drawn without it.{}", why,
                    gi2d.lastWasLimit ? Gi2dSystem::budget_limit_note() : "");
        }
        return;
    }
    Gi2dField* field = gi2d.acquire(slot, geom, cascadePlan);
    if (!field) return;
    field->settings = s;
    field->job = ctx.plan.name;
    field->camera = fr.cam.entity.bits();
    auto gather = std::make_shared<Gi2dGather>();
    gi2d_gather(ctx.world, fr, geom, *gather);
    field->stats = *gather;
    if (gather->dropped > 0 && !gi2d.warned_dropped) {
        gi2d.warned_dropped = true;
        FA_WARN("render",
                "2D global illumination: {} emitting or occluding quads are over the {} a field draws and were left "
                "out of the field. "
                "Hint: GlobalIllumination2D.range limits what the field covers; lower it, or merge tiles into fewer "
                "Tilemap cells.",
                gather->dropped, kGi2dMaxQuads);
    }
    ctx.gi2d.active = true;
    ctx.gi2d.field = field;
    ctx.gi2d.gather = std::move(gather);
    if (assets && assets->white()) ctx.gi2d.white = assets->white()->gpu_view();
}

// The light buffer's pass (light_plan chose litMode 1): every point light of the camera is a quad added into the buffer.
// Reads: fr (lights2d, shadowRows, camera, viewport), ctx.partial, ctx.shadowRowsTex, lightW / lightH, the light target.
// Writes: the light target; stats.drawCalls.
void Renderer::Impl::light_pass(DrawContext& ctx) {
    Frame& fr = ctx.fr;
    const bool partial = ctx.partial;
    const sg_view shadowRowsTex = ctx.shadowRowsTex;
    static const float kCorner[4][2] = {{-1, -1}, {1, -1}, {1, 1}, {-1, 1}};
    static_assert(kMaxLights2D <= kMaxQuadsPerDraw, "every light of a buffer is drawn by one draw call");
    // One buffer per set of lights the layer plan made (light_layers.h); the default scene has one, holding every point light.
    const std::size_t buffers = std::max<std::size_t>(1, ctx.layerPlan.buffers.size());
    for (std::size_t bi = 0; bi < buffers; ++bi) {
        std::vector<LightVertex> lv;
        auto add_light = [&](const Light2DData& l) {
            const CookieShaderData cd = cookie_shader_data(l, gpu.is_gl());
            for (const auto& c : kCorner) {
                LightVertex v{};
                v.corner[0] = c[0];
                v.corner[1] = c[1];
                std::memcpy(v.pos, l.pos, sizeof(float) * 4);
                std::memcpy(v.color, l.color, sizeof(float) * 4);
                v.shadow[0] =
                    l.extra[0] >= 0.0f && fr.shadowRows > 0 ? (l.extra[0] + 0.5f) / float(fr.shadowRows) : -1.0f;
                v.shadow[1] = l.shadowSize;
                std::memcpy(v.cookie, cd.cell, sizeof(float) * 4);
                std::memcpy(v.cookieXf, cd.xf, sizeof(float) * 4);
                lv.push_back(v);
            }
        };
        if (ctx.layerPlan.buffers.empty()) {
            for (const Light2DData& l : fr.lights2d)
                if (l.pos[3] >= 0.0f) add_light(l);
        } else {
            for (int li : ctx.layerPlan.buffers[bi]) add_light(fr.lights2d[std::size_t(li)]);
        }
        sg_buffer lb = gpu.acquire_transient(lv.size() * sizeof(LightVertex));
        sg_write_buffer_desc wd{};
        wd.src.data = {lv.data(), lv.size() * sizeof(LightVertex)};
        wd.dst.buffer = lb;
        sg_write_buffer_transient(&wd);

        PassDesc lp = pass_into(light_buffer(int(bi)), "light-buffer");
        lp.colorLoad = SG_LOADACTION_CLEAR;
        lp.clearColor = {0, 0, 0, 0};
        lp.colorStore = SG_STOREACTION_STORE;
        gpu.begin_pass(lp);
        // The lights of this camera go to its rectangle of the buffer; the lit visuals of the camera read nothing else.
        if (partial) apply_view(px_rect(fr.cam.viewport, lightW, lightH));
        sg_apply_pipeline(gpu.light_pipeline());
        sg_bindings b{};
        b.vertex_buffers[0] = lb;
        b.index_buffer = gpu.quad_index_buffer();
        b.views[VIEW_light_shadow_tex] = shadowRowsTex.id ? shadowRowsTex : assets->white()->view;
        b.views[VIEW_light_cookie_tex] = ctx.cookieView.id ? ctx.cookieView : assets->white()->view;
        b.samplers[SMP_light_shadow_smp] = gpu.sampler(SamplerKind::Nearest);
        b.samplers[SMP_light_cookie_smp] = gpu.sampler(SamplerKind::LinearClamp);
        sg_apply_bindings(&b);
        light_light_vs_params_t vu{};
        copy_mat(vu.view_proj, fr.cam.drawViewProj);
        apply_uniforms(UB_light_light_vs_params, vu);
        light_light_fs_params_t fu{};
        fu.range[0] = 1.0f / gpu.light_range();
        apply_uniforms(UB_light_light_fs_params, fu);
        sg_draw(0, int(lv.size() / 4) * 6, 1);
        gpu.end_pass();
        ++stats.drawCalls;
    }
}

// ---- shadow pass ----
// Meshes cast with the engine's depth-only programs, except materials with their own shadow programs (vertex() moves the
// shadow, alphaMode "clip" cuts holes into it).
// Reads: ctx.doShadows, ctx.opaque / ctx.blended and their batches, ctx.shadowInst, ctx.vuScene,
// ctx.white and ctx.fuScene (part_draw, bind_textures, fill_fs), the shadow targets.
// Writes: the shadow atlas (ctx.shadowTgt); stats.drawCalls.
void Renderer::Impl::shadow_pass(DrawContext& ctx) {
    const std::vector<MeshBatch>& opaqueBatches = ctx.opaqueBatches;
    const std::vector<MeshBatch>& blendedBatches = ctx.blendedBatches;
    const std::vector<MeshItem>& opaque = ctx.opaque;
    const std::vector<MeshItem>& blended = ctx.blended;
    const sg_buffer shadowInst = ctx.shadowInst;
    const mesh_fa_mesh_vs_params_t& vuScene = ctx.vuScene;
    PassDesc sp = pass_into(ctx.shadowTgt, "shadow");
    sp.colorLoad = SG_LOADACTION_CLEAR;
    sp.clearColor = {1, 1, 1, 1};
    sp.colorStore = SG_STOREACTION_STORE;
    sp.depthLoad = SG_LOADACTION_CLEAR;
    sp.clearDepth = 1.0f;
    gpu.begin_pass(sp);
    mesh_fa_mesh_vs_params_t u = vuScene;  // the shadow programs read fa_light_vp (fa_view_proj is unused)
    // One draw per batch and view (a cascade of the sun, a tile of a local light), each into its own tile of the atlas: the viewport and
    // the scissor are the tile (y from the top). A batch's runs are in ascending view order, so each batch keeps a cursor.
    const std::vector<ShadowRun>& runs = ctx.shadowRuns;
    std::array<std::vector<std::uint32_t>, 2> cursors;
    cursors[0].assign(opaqueBatches.size(), 0);
    cursors[1].assign(blendedBatches.size(), 0);
    for (int view = 0; view < int(ctx.viewProj.size()); ++view) {
        const render::ShadowTile& tile = ctx.atlas.tiles[std::size_t(view)];
        if (!tile.placed() || (view >= ctx.cascades && view < ctx.sunViews)) continue;
        sg_apply_viewport(tile.x, tile.y, tile.size, tile.size, true);
        sg_apply_scissor_rect(tile.x, tile.y, tile.size, tile.size, true);
        copy_mat(u.fa_light_vp, ctx.viewProj[std::size_t(view)]);
        for (int pass = 0; pass < 2; ++pass) {
            const std::vector<MeshBatch>& batches = pass == 0 ? opaqueBatches : blendedBatches;
            const std::vector<MeshItem>& items = pass == 0 ? opaque : blended;
            for (std::size_t bi = 0; bi < batches.size(); ++bi) {
                const MeshBatch& batch = batches[bi];
                std::uint32_t& cur = cursors[std::size_t(pass)][bi];
                while (cur < batch.runCount && runs[batch.runFirst + cur].view < std::uint32_t(view)) ++cur;
                if (cur >= batch.runCount || runs[batch.runFirst + cur].view != std::uint32_t(view)) continue;
                const ShadowRun& run = runs[batch.runFirst + cur];
                const std::uint32_t count = run.count, first = run.first;
                if (count == 0) continue;
                const MeshItem& rep = items[batch.rep];
                u.fa_uv_scale[0] = rep.mr->uvScale.x;
                u.fa_uv_scale[1] = rep.mr->uvScale.y;
                MaterialAsset* mat = rep.material && rep.material->ok ? rep.material : nullptr;
                MaterialInputs inputs{};
                if (mat && (mat->programs[kProgShadow].shader.id || mat->programs[kProgShadowSkin].shader.id))
                    material_inputs(rep, mat, inputs);
                if (mat && mat->full && mat->shadow == FullShadow::None) continue;      // casts no shadow
                const MeshBufferUse mbu = resolve_mesh_buffers(*assets, compute, rep);  // mesh_buffer_draw.h
                if (mbu.skip) continue;
                for (auto& p : rep.mesh->parts) {
                    const bool skinned = rep.anim && p.skinVb.id;
                    const PartDraw pd = part_draw(ctx, rep, p);
                    const MaterialProgram* prog =
                        pd.mat ? &mat->programs[skinned ? kProgShadowSkin : kProgShadow] : nullptr;
                    if (prog && !prog->shader.id) prog = nullptr;
                    if (mbu.active && !prog)
                        continue;  // the engine's shadow program cannot place what the buffers place
                    sg_apply_pipeline(prog ? gpu.shadow_pipeline(skinned, prog->shader, true, mat->extras())
                                           : gpu.shadow_pipeline(skinned));
                    sg_bindings b{};
                    b.vertex_buffers[0] = p.vb;
                    b.vertex_buffers[1] = shadowInst;
                    b.vertex_buffer_offsets[1] = int(first * kMeshInstanceBytes);
                    if (skinned) b.vertex_buffers[2] = p.skinVb;
                    if (prog) bind_extras(b, *mat, p, ctx.shadowExtra, run.extra);
                    b.index_buffer = p.ib;
                    b.index_buffer_offset = p.ibOffset;
                    if (prog) bind_textures(ctx, b, pd, prog, inputs, true);
                    if (mbu.active) bind_mesh_buffers(b, mbu, *prog);
                    sg_apply_bindings(&b);
                    if (mbu.active) apply_mesh_base_model(*prog, rep.model);
                    if (declares(prog, UB_mesh_fa_mesh_vs_params)) apply_uniforms(UB_mesh_fa_mesh_vs_params, u);
                    if (skinned && declares(prog, UB_mesh_fa_skin))
                        apply_uniforms(UB_mesh_fa_skin, pack_palette(palette_of(*rep.anim, p.skin)));
                    if (prog) {
                        if (prog->has_ub(UB_mesh_fa_mesh_fs_params))
                            apply_uniforms(UB_mesh_fa_mesh_fs_params, fill_fs(ctx, rep, p, pd));
                        if (prog->has_ub(UB_mesh_fa_shadows)) apply_uniforms(UB_mesh_fa_shadows, ctx.shadowU);
                        apply_material_params(*prog, inputs);
                    }
                    sg_draw(0, p.indexCount, mbu.active ? mbu.instances : int(count));
                    ++stats.drawCalls;
                }
            }
        }
    }
    gpu.end_pass();
}

// ---- depth and normal prepass ----
// For the effects that read the scene's depth and normals (ambient occlusion, reflections, fog, sun shafts, depth of field, motion blur,
// outline): the opaque meshes of a camera drawn again into one float image (Gpu::prepass_color_format; r = linear view
// depth, gb = octahedral view-space normal, a = 1 on a mesh) with a depth buffer of its own, never multisampled (a multisampled depth
// cannot be sampled). Blended meshes, the sky, sprites, particles, shapes, text, debug lines and the HUD are not in it, and a CameraView or
// render target never has one. Meshes of a material with alphaMode "clip" cut the same holes as in the main pass (the prepass program runs
// its surface()), and a material's vertex() moves them the same way.

// Does this job draw the prepass? Every camera job that draws the world and has a stack with an effect that reads the depth or the
// normals (or a debug view, or a test that forces an effect) gets its own, when it draws opaque meshes and the GPU can make the image:
// a frame without any of that costs nothing (no pass, no image, no shader). The image has the size of the camera's rectangle of the
// picture (ctx.camPx), so a camera of a split screen reads depth at its own pixels. Reads: ctx.plan, ctx.postPlan, ctx.camPx,
// ctx.opaqueBatches, debugView. Writes: ctx.doPrepass, ctx.debugPrepass.
bool Renderer::Impl::plan_prepass(DrawContext& ctx) {
    const PostPlan& pp = ctx.postPlan;
    ctx.doPrepass = ctx.debugPrepass = ctx.doVelocity = false;
    if ((ctx.plan.view && !ctx.plan.customPost && !ctx.plan.gi) || !ctx.fr.wantWorld || ctx.camPx.w < 1 ||
        ctx.camPx.h < 1)
        return false;
    // A face of a realtime GI capture always has it: the distance of what the probe sees is made from it (renderer_gi.cpp).
    // The velocity alone (or its debug view) is worth a prepass only where collectPrev says the GPU can make the image.
    const bool debugPass = debugView != DebugView::None && debugView != DebugView::Cascades &&
                           debugView != DebugView::Occlusion &&
                           (debugView != DebugView::MotionVectors || ctx.collectPrev);
    if (!(ctx.plan.gi || ctx.hiz || pp.needsDepth || pp.needsNormals || (pp.needsVelocity && ctx.collectPrev) ||
          debugPass))
        return false;
    bool anyMesh = false;
    for (const MeshBatch& b : ctx.opaqueBatches) anyMesh = anyMesh || b.mainCount > 0;
    // A custom post pass that reads the depth gets the prepass of a camera with no opaque mesh too: it is cleared to
    // "nothing drawn".
    if (!(anyMesh || pp.custom.reads_prepass()) || !gpu.prepass_ready())
        return false;  // prepass_ready logs once why it is not
    // Made now (and given back to the pool) so that a GPU that refuses the image is one warning here, not a failed pass.
    TransientDesc d;
    d.width = ctx.camPx.w;
    d.height = ctx.camPx.h;
    d.format = gpu.prepass_target_format();
    d.label = "prepass";
    const std::uint64_t h = transient_targets().pool.acquire(d);
    if (h == 0) {
        if (!prepassWarned) {
            prepassWarned = true;
            FA_ERROR("render",
                     "The depth and normal prepass image ({}x{}) could not be made: the effects that read the depth "
                     "are skipped. "
                     "Hint: lower the window size or the render scale.",
                     ctx.camPx.w, ctx.camPx.h);
        }
        return false;
    }
    transient_targets().pool.release(h);
    ctx.doPrepass = true;
    // M76: the motion vectors go into a second attachment of the same pass when the camera asks and the GPU can make the image. A GPU that
    // cannot (or refuses the image) leaves the velocity out: PostPlan::velocity stays invalid and whoever asked reads the camera alone.
    if (pp.needsVelocity && !ctx.plan.gi && ctx.collectPrev) {
        TransientDesc vd = d;
        vd.format = TargetFormat{Gpu::velocity_format(), SG_PIXELFORMAT_NONE, 1};
        vd.label = "velocity";
        if (const std::uint64_t vh = transient_targets().pool.acquire(vd)) {
            transient_targets().pool.release(vh);
            ctx.doVelocity = true;
        }
    }
    ctx.debugPrepass = !ctx.plan.gi &&
                       (debugView == DebugView::Depth || debugView == DebugView::Normals ||
                        (debugView == DebugView::MotionVectors && ctx.doVelocity)) &&
                       gpu.prepass_view_ready();
    return true;
}

// Transmission (M73-P6b, renderer_xmit.h): counts the visible transmissive meshes of the blended phase; when there is one and the copy of the
// opaque picture can be made (the shader compiled, the pool makes the atlas and its level images), the main pass splits after the opaque phase
// (ctx.xmit.want). Without it the draws are blended plainly, with no refraction (the shader's mode 2). A job with no transmissive draw
// does nothing here, so its frame is the frame without the feature. Reads: ctx.blendedBatches, ctx.blended, ctx.camPx, ctx.fr, ctx.plan.
// Writes: ctx.xmit.want, stats.transmissiveMeshes, stats.transmissionPlain.
void Renderer::Impl::plan_transmission(DrawContext& ctx) {
    ctx.xmit = {};
    if (!ctx.fr.wantWorld || !ctx.doMainPass || ctx.camPx.w < 1 || ctx.camPx.h < 1) return;
    int meshes = 0;
    for (const MeshBatch& b : ctx.blendedBatches) {
        if (b.mainCount == 0) continue;
        const MeshItem& mi = ctx.blended[b.rep];
        if (mesh_is_transmissive(*mi.mr, *mi.mesh, mi.material)) meshes += int(b.mainCount);
    }
    if (meshes == 0) return;
    stats.transmissiveMeshes += meshes;
    if (xmit.can_make(transient_targets(), gpu, ctx.camPx.w, ctx.camPx.h))
        ctx.xmit.want = true;
    else
        ++stats.transmissionPlain;
}

// The image the outline reads. Depth mode needs the prepass (plan_prepass made it or said why not, once); sprite mode needs a coverage
// image of the camera's rectangle, made when the pool can make an RGBA8 image. Each camera of a split screen has its own.
// An outline without its image is dropped from the plan (PostPlan::skip_outline), so the camera is drawn as if the effect were off.
// Reads: ctx.plan, ctx.fr, ctx.camPx, ctx.doPrepass. Writes: ctx.postPlan, ctx.doCoverage, coverageWarned.
void Renderer::Impl::plan_outline(DrawContext& ctx) {
    PostPlan& pp = ctx.postPlan;
    ctx.doCoverage = false;
    if (ctx.plan.view || !ctx.fr.wantWorld || ctx.camPx.w < 1 || ctx.camPx.h < 1) return;
    if (pp.fx.outline_depth()) {
        if (!ctx.doPrepass) pp.skip_outline();
        return;
    }
    if (!pp.fx.outline_sprite()) return;
    auto skip = [&](const char* why) {
        if (!coverageWarned) {
            coverageWarned = true;
            FA_WARN("render", "The sprite outline is skipped: {}. Hint: lower the window size or the render scale.",
                    why);
        }
        pp.skip_outline();
    };
    TransientDesc d;
    d.width = ctx.camPx.w;
    d.height = ctx.camPx.h;
    d.format = TargetFormat{SG_PIXELFORMAT_RGBA8, SG_PIXELFORMAT_NONE, 1};
    d.label = "sprite-coverage";
    const std::uint64_t h = transient_targets().pool.acquire(d);
    if (h == 0) {
        skip("the coverage image could not be made (out of GPU memory? lower the window size or the render scale)");
        return;
    }
    transient_targets().pool.release(h);
    ctx.doCoverage = true;
}

// Draws the 2D world of the job into `t` as coverage: only the alpha channel matters (alpha blending accumulates how much of a pixel
// the sprites, tiles, shapes, text and particles cover; additive and multiply quads leave it alone). Cleared to 0 first. Reads:
// ctx.gWorld, ctx.fr.cam, ctx.camPx, the quad stream of the job. Writes: `t`; stats.drawCalls.
void Renderer::Impl::coverage_pass(DrawContext& ctx, const Target& t) {
    PassDesc pd = pass_into(t, "sprite-coverage");
    pd.colorLoad = SG_LOADACTION_CLEAR;
    pd.clearColor = {0.0f, 0.0f, 0.0f, 0.0f};
    pd.colorStore = SG_STOREACTION_STORE;
    gpu.begin_pass(pd);
    // The image has the size of the camera's rectangle and the camera's matrix maps the world onto that rectangle: the whole image.
    draw_group(ctx, ctx.gWorld.batches, ctx.fr.cam.drawViewProj, false, Px{0, 0, t.w, t.h}, 0, &pd.format, nullptr, t.w,
               t.h);
    gpu.end_pass();
}

// Draws the opaque meshes of the job into `t`. Reads: ctx.opaque / opaqueBatches, ctx.mainInst, ctx.vuScene, ctx.fuScene, ctx.fr.cam, the
// custom prepass programs of the materials. Writes: `t`; stats.drawCalls.
void Renderer::Impl::prepass_pass(DrawContext& ctx, const Target& t, bool backFaces, const Target* velocity) {
    const std::vector<MeshBatch>& batches = ctx.opaqueBatches;
    const std::vector<MeshItem>& items = ctx.opaque;
    PassDesc pd = pass_into(t, backFaces ? "prepass-back" : "prepass");
    // M76: the motion vectors are the second attachment, cleared to the sentinel ("no object wrote here"). The programs write it only for
    // an instance that has a previous model (fa_vel_on), and a pass without it uses pipelines with one attachment: the output is dropped.
    const bool vel = velocity && velocity->colorAtt.id && ctx.prevInst.id && !backFaces;
    if (vel) {
        pd.format = gpu.prepass_target_format(true);
        pd.color1 = velocity->colorAtt;
        pd.clearColor1 = {VelocityRef::kNone, VelocityRef::kNone, 0.0f, 0.0f};
    }
    pd.colorLoad = SG_LOADACTION_CLEAR;  // nothing drawn: far depth, no normal, coverage 0
    pd.clearColor = {PrepassRef::kFarDepth, 0.0f, 0.0f, 0.0f};
    pd.colorStore = SG_STOREACTION_STORE;
    pd.depthLoad = SG_LOADACTION_CLEAR;
    pd.clearDepth = 1.0f;
    gpu.begin_pass(pd);
    mesh_fa_mesh_vs_params_t vu = ctx.vuScene;
    copy_mat(vu.fa_light_vp,
             ctx.fr.cam.view);  // the prepass programs read the view matrix where the shadow programs read the light's
    // The two view-projections of the motion vectors, both without the jitter (it is not part of a motion): this frame's and the previous
    // one's (the same one when the camera was cut, so a cut has no motion of the objects either).
    // Without the image the block stays zero (the programs that declare it read fa_vel_on.x = 0 and skip the work).
    mesh_fa_vel_params_t velU{};
    if (vel) {
        copy_mat(velU.fa_vel_vp, ctx.fr.cam.viewProj);
        copy_mat(velU.fa_vel_prev_vp, ctx.postPlan.prevValid ? ctx.postPlan.prevViewProj : ctx.fr.cam.viewProj);
        velU.fa_vel_on[0] = 1.0f;
        velU.fa_vel_on[1] = ctx.prevTime;
    }
    for (const MeshBatch& batch : batches) {
        if (batch.mainCount == 0) continue;
        const MeshItem& mi = items[batch.rep];
        vu.fa_uv_scale[0] = mi.mr->uvScale.x;
        vu.fa_uv_scale[1] = mi.mr->uvScale.y;
        MaterialAsset* mat = mi.material && mi.material->ok ? mi.material : nullptr;
        MaterialInputs inputs{};
        if (mat && (mat->programs[kProgPrepass].shader.id || mat->programs[kProgPrepassSkin].shader.id))
            material_inputs(mi, mat, inputs);
        if (mat && mat->full && !mat->prepass) continue;  // a full shader that keeps out of the depth and normal image
        const MeshBufferUse mbu = resolve_mesh_buffers(*assets, compute, mi);
        if (mbu.skip) continue;
        for (const SubMesh& part : mi.mesh->parts) {
            const bool skinned = mi.anim && part.skinVb.id;
            const PartDraw pd0 = part_draw(ctx, mi, part);
            const MaterialProgram* custom =
                pd0.mat ? &mat->programs[skinned ? kProgPrepassSkin : kProgPrepass] : nullptr;
            if (custom && !custom->shader.id) custom = nullptr;  // a twin made before the prepass: the engine's program
            if (mbu.active && !custom) continue;  // the engine's program cannot place what the buffers place
            const MaterialProgram* prog = custom ? custom : &gpu.prepass_program(skinned);
            PartDraw bind = pd0;
            if (!custom) bind.mat = nullptr;  // the engine's program has no material textures
            sg_apply_pipeline(gpu.prepass_pipeline(
                pd.format, part.doubleSided || (pd0.mat && pd0.mat->doubleSided), skinned,
                custom ? custom->shader : sg_shader{}, custom ? mat->extras() : MeshExtras{}, backFaces,
                mi.lodFade != 0.0f));  // the engine's program of a fading draw: with the dither
            sg_bindings b{};
            b.vertex_buffers[0] = part.vb;
            b.vertex_buffers[1] = ctx.mainInst;
            b.vertex_buffer_offsets[1] = int(batch.mainFirst * kMeshInstanceBytes);
            if (skinned) b.vertex_buffers[2] = part.skinVb;
            if (custom) bind_extras(b, *mat, part, ctx.mainExtra, batch.mainExtra);
            // The previous model of each instance (vertex buffer 6) when the program reads it; with no velocity image the pipeline still
            // has the attributes, so the instance buffer stands in for it (never read: fa_vel_on is 0).
            if (prepass_prev_attr(skinned, custom != nullptr, custom ? mat->extras() : MeshExtras{}) >= 0) {
                b.vertex_buffers[kPrevModelBuffer] = vel ? ctx.prevInst : ctx.mainInst;
                b.vertex_buffer_offsets[kPrevModelBuffer] =
                    int(batch.mainFirst * (vel ? kPrevModelBytes : kMeshInstanceBytes));
            }
            b.index_buffer = part.ib;
            b.index_buffer_offset = part.ibOffset;
            bind_textures(ctx, b, bind, prog, inputs, true);
            // The previous palettes of the skinned programs (vertex stage). The slot is declared by every skinned prepass program, so a
            // pass without velocity binds the white image (never read: fa_vel_on.x is 0).
            if (skinned) {
                if ((prog->viewMask >> VIEW_mesh_fa_prev_pal_tex) & 1u)
                    b.views[VIEW_mesh_fa_prev_pal_tex] = vel && ctx.prevPalView.id ? ctx.prevPalView : ctx.white->view;
                if ((prog->samplerMask >> SMP_mesh_fa_prev_pal_smp) & 1u)
                    b.samplers[SMP_mesh_fa_prev_pal_smp] = gpu.sampler(SamplerKind::Nearest);
            }
            if (mbu.active) bind_mesh_buffers(b, mbu, *prog);
            sg_apply_bindings(&b);
            if (mbu.active) apply_mesh_base_model(*prog, mi.model);
            apply_uniforms(UB_mesh_fa_mesh_vs_params, vu);
            // A skinned draw reads the previous palette from the image of upload_prev_palettes (fa_vel_on.z = 1, the first texel in .w) when the
            // program has the previous model and the palette got a place in the image; otherwise its fragments write the sentinel.
            int palBase = -1;
            if (skinned && vel &&
                prepass_prev_attr(true, custom != nullptr, custom ? mat->extras() : MeshExtras{}) >= 0) {
                const auto at = ctx.prevPalBase.find(prev_palette_key(batch.rep, part.skin));
                if (at != ctx.prevPalBase.end()) palBase = at->second;
            }
            velU.fa_vel_on[2] = palBase >= 0 ? 1.0f : 0.0f;
            velU.fa_vel_on[3] = palBase >= 0 ? float(palBase) : 0.0f;
            if (prog->has_ub(UB_mesh_fa_vel_params)) apply_uniforms(UB_mesh_fa_vel_params, velU);
            if (skinned && prog->has_ub(UB_mesh_fa_skin))
                apply_uniforms(UB_mesh_fa_skin, pack_palette(palette_of(*mi.anim, part.skin)));
            if (prog->has_ub(UB_mesh_fa_mesh_fs_params))
                apply_uniforms(UB_mesh_fa_mesh_fs_params, fill_fs(ctx, mi, part, pd0));
            if (prog->has_ub(UB_mesh_fa_shadows)) apply_uniforms(UB_mesh_fa_shadows, ctx.shadowU);
            apply_material_params(*prog, inputs);
            sg_draw(0, part.indexCount, mbu.active ? mbu.instances : int(batch.mainCount));
            ++stats.drawCalls;
        }
    }
    gpu.end_pass();
}

// The subsurface draw (M73.5, docs/design/ARCHITECTURE_SUBSURFACE.md): the opaque meshes that scatter, drawn again with the sss program of the mesh
// shader into two images of the camera's size: `a` = the diffuse light the surface sends to the camera and its linear depth, `b` = the scatter radius
// per colour channel and the strength. The geometry, the instances, the skin, the lightmap and every uniform are the main pass's; only the surface the
// camera sees counts (the shader tests its depth against `pre`). Reads: ctx.opaque / opaqueBatches, ctx.mainInst, ctx.vuScene, ctx.fuScene,
// ctx.shadowU. Writes: stats.subsurfaceDraws.
void Renderer::Impl::sss_draw_pass(DrawContext& ctx, const Target& a, const Target& b, const Target& pre) {
    if (!a.colorAtt.id || !b.colorAtt.id || !pre.texView.id) return;
    PassDesc pd = pass_into(a, "sss-draw");
    pd.format = Gpu::sss_target_format();
    pd.color1 = b.colorAtt;
    pd.colorLoad = SG_LOADACTION_CLEAR;  // nothing scatters: no light, depth 0, no strength
    pd.clearColor = {0.0f, 0.0f, 0.0f, 0.0f};
    pd.colorStore = SG_STOREACTION_STORE;
    pd.depthLoad = SG_LOADACTION_CLEAR;
    pd.clearDepth = 1.0f;
    gpu.begin_pass(pd);
    mesh_fa_mesh_vs_params_t vu = ctx.vuScene;
    for (const MeshBatch& batch : ctx.opaqueBatches) {
        if (batch.mainCount == 0) continue;
        const MeshItem& mi = ctx.opaque[batch.rep];
        if (!sss_scatters(mi)) continue;
        const MeshBufferUse mbu = resolve_mesh_buffers(*assets, compute, mi);
        if (mbu.skip || mbu.active) continue;  // a mesh placed by GPU buffers has its own program
        const std::array<float, 5> sss = subsurface_of(*mi.mr);
        mesh_fa_sss_params_t su{};
        su.fa_sss[0] = sss[1] * sss[2];
        su.fa_sss[1] = sss[1] * sss[3];
        su.fa_sss[2] = sss[1] * sss[4];
        su.fa_sss[3] = sss[0];
        vu.fa_uv_scale[0] = mi.mr->uvScale.x;
        vu.fa_uv_scale[1] = mi.mr->uvScale.y;
        for (int k = 0; k < 4; ++k) vu.fa_lm_so[k] = mi.lm.mesh ? mi.lm.scaleOffset[k] : 0.0f;
        const std::vector<SubMesh>& drawParts = mi.lm.mesh ? mi.lm.mesh->parts : mi.mesh->parts;
        for (const SubMesh& part : drawParts) {
            const bool skinned = mi.anim && part.skinVb.id;
            const PartDraw d = part_draw(ctx, mi, part);
            if (d.error || d.mat) continue;
            const MaterialProgram& prog = gpu.sss_program(skinned);
            const sg_pipeline pipe = gpu.sss_pipeline(part.doubleSided, skinned);
            if (!pipe.id) continue;
            sg_apply_pipeline(pipe);
            sg_bindings bind{};
            bind.vertex_buffers[0] = part.vb;
            bind.vertex_buffers[1] = ctx.mainInst;
            bind.vertex_buffer_offsets[1] = int(batch.mainFirst * kMeshInstanceBytes);
            if (skinned)
                bind.vertex_buffers[2] = part.skinVb;
            else  // like the main pass: the lightmap UV, or zeros
                bind.vertex_buffers[kUv1Buffer] =
                    part.uv1Vb.id && mi.lm.mesh ? part.uv1Vb : assets->zero_uv1(std::size_t(part.vertexCount));
            bind.index_buffer = part.ib;
            bind.index_buffer_offset = part.ibOffset;
            bind_textures(ctx, bind, d, &prog, MaterialInputs{}, false, true);
            bind.views[VIEW_mesh_fa_screen_tex] =
                pre.texView;  // the shader's visibility test, always (contact shadows read it too)
            sg_apply_bindings(&bind);
            apply_uniforms(UB_mesh_fa_mesh_vs_params, vu);
            if (skinned && prog.has_ub(UB_mesh_fa_skin))
                apply_uniforms(UB_mesh_fa_skin, pack_palette(palette_of(*mi.anim, part.skin)));
            if (prog.has_ub(UB_mesh_fa_mesh_fs_params))
                apply_uniforms(UB_mesh_fa_mesh_fs_params, fill_fs(ctx, mi, part, d));
            if (prog.has_ub(UB_mesh_fa_shadows)) apply_uniforms(UB_mesh_fa_shadows, ctx.shadowU);
            if (prog.has_ub(UB_mesh_fa_sss_params)) apply_uniforms(UB_mesh_fa_sss_params, su);
            sg_draw(0, part.indexCount, int(batch.mainCount));
            ++stats.subsurfaceDraws;
        }
    }
    gpu.end_pass();
}

// Paints the prepass (depth or normals, Renderer::set_debug_view) over the game image the main pass drew.
void Renderer::Impl::prepass_view_pass(DrawContext& ctx, const Target& t) {
    PassDesc dp = pass_into(gameTarget, "prepass-view");
    dp.colorLoad = SG_LOADACTION_LOAD;
    // Like the main pass: only the last job may drop its multisampled colour (a camera after it loads the picture).
    dp.colorStore = (ctx.msaa && ctx.plan.last && !ctx.hudAfterBloom) ? SG_STOREACTION_DONTCARE : SG_STOREACTION_STORE;
    gpu.begin_pass(dp);
    sg_apply_pipeline(gpu.prepass_view_pipeline(dp.format));
    if (!ctx.postPlan.rect.whole(physW, physH)) apply_view(ctx.camPx);  // the camera's rectangle of the game image
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_prepass_view_tex] = t.texView;
    b.samplers[SMP_prepass_view_smp] = gpu.sampler(SamplerKind::Nearest);
    sg_apply_bindings(&b);
    prepass_view_prepass_view_vs_params_t vu{};
    vu.flip[0] = gpu.is_gl() ? 1.0f : 0.0f;
    apply_uniforms(UB_prepass_view_prepass_view_vs_params, vu);
    prepass_view_prepass_view_fs_params_t fu{};
    fu.mode[0] = debugView == DebugView::Normals ? 2.0f : debugView == DebugView::MotionVectors ? 3.0f : 1.0f;
    apply_uniforms(UB_prepass_view_prepass_view_fs_params, fu);
    sg_draw(0, 3, 1);
    ++stats.drawCalls;
    gpu.end_pass();
}

// The test copy of the velocity image (RendererTestAccess::read_velocity): the vectors as floats in an RGBA16F image of the camera's size.
// prepass_view.glsl mode 4, which only this pass uses (no game draws it). On GL the pass flips like the debug view does (vu.flip = 1 there:
// the image is sampled row for row, so the copy keeps the texture's own row order, bottom row first); readback_rgba16f turns the rows over on
// GL as readback_rgba8 does, so on every backend the vector of the pixel (x, y) is out[(y * w + x) * 4], the top row first. (Reasoned from
// those two, as the GL backend is not run by this host's tests.)
constexpr float kPrepassViewRaw = 4.0f;
void Renderer::Impl::velocity_probe_pass(DrawContext& ctx, const Target& velocity) {
    const int w = ctx.camPx.w, h = ctx.camPx.h;
    if (!velocity.texView.id || w < 1 || h < 1) return;
    if (!velocityProbe.valid() || velocityProbe.w != w || velocityProbe.h != h) {
        destroy_target(velocityProbe);
        TargetDesc td;
        td.label = "velocity-probe";
        td.width = w;
        td.height = h;
        td.colorFormat = SG_PIXELFORMAT_RGBA16F;
        velocityProbe = make_target(td);
        if (!velocityProbe.valid()) return;
    }
    PassDesc dp = pass_into(velocityProbe, "velocity-probe");
    dp.colorLoad = SG_LOADACTION_DONTCARE;  // every pixel is drawn
    dp.colorStore = SG_STOREACTION_STORE;
    gpu.begin_pass(dp);
    sg_apply_pipeline(gpu.prepass_view_pipeline(dp.format));
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_prepass_view_tex] = velocity.texView;
    b.samplers[SMP_prepass_view_smp] = gpu.sampler(SamplerKind::Nearest);
    sg_apply_bindings(&b);
    prepass_view_prepass_view_vs_params_t vu{};
    vu.flip[0] = gpu.is_gl() ? 1.0f : 0.0f;
    apply_uniforms(UB_prepass_view_prepass_view_vs_params, vu);
    prepass_view_prepass_view_fs_params_t fu{};
    fu.mode[0] = kPrepassViewRaw;
    apply_uniforms(UB_prepass_view_prepass_view_fs_params, fu);
    sg_draw(0, 3, 1);
    gpu.end_pass();
}

bool Renderer::Impl::read_velocity(std::vector<float>& out, int& w, int& h, std::string* error) {
    if (!velocityProbe.valid()) {
        if (error)
            *error =
                "no velocity image was drawn (force_velocity is off, or the frame drew no prepass with motion vectors)";
        return false;
    }
    w = velocityProbe.w;
    h = velocityProbe.h;
    return render::readback_rgba16f(velocityProbe.color, w, h, out, error);
}

// Draws the batches of a quad group. Reads: ctx.vbuf, ctx.shadowRowsTex, fr (lights2d, shadowRows, ambient2d), renderScale,
// physW / physH, gpu.light_range(), lightTarget.texView (`flatMode` 1 reads the light buffer). Writes: stats
// (drawCalls, materials, materialFallbacks).
void Renderer::Impl::draw_group(DrawContext& ctx, const std::vector<QuadBatch>& batches, const Mat4& vp, bool depthTest,
                                const Px& base, int flatMode, const TargetFormat* format, const FogFxPlan* fog,
                                int passW, int passH) {
    Frame& fr = ctx.fr;
    const sg_buffer vbuf = ctx.vbuf;
    const sg_view shadowRowsTex = ctx.shadowRowsTex;
    if (batches.empty()) return;
    quad_vs_params_t u{};
    copy_mat(u.view_proj, vp);
    u.cspace[0] = fr.linear ? 1.0f : 0.0f;  // vertex colours are sRGB values: decoded in the vertex shader
    Rect
        scissor;  // the clip applied now (w <= 0: `base`, the whole target or the camera's viewport); a ScrollList's content is cut at its rectangle
    auto apply_clip = [&](const Rect& c) {
        if (c == scissor) return;
        scissor = c;
        if (c.w <= 0) {
            sg_apply_scissor_rect(base.x, base.y, base.w, base.h, true);
            return;
        }
        Rect r = c;
        const float k = renderScale;
        const int x0 = std::clamp(int(std::lround(r.x * k)), 0, physW),
                  y0 = std::clamp(int(std::lround(r.y * k)), 0, physH);
        const int x1 = std::clamp(int(std::lround((r.x + r.w) * k)), x0, physW),
                  y1 = std::clamp(int(std::lround((r.y + r.h) * k)), y0, physH);
        sg_apply_scissor_rect(x0, y0, x1 - x0, y1 - y0, true);
    };
    // fragment uniforms of the 2D lights: the same for every lit batch except the normal map's uv transform
    quad_quad_fs_params_t unlit{};
    quad_quad_fs_params_t litUniforms{};
    litUniforms.lit[0] = float(std::min<std::size_t>(fr.lights2d.size(), std::size_t(kDirectLights2D)));
    litUniforms.lit[2] = float(flatMode);
    litUniforms.ambient[0] = fr.ambient2d.r;
    litUniforms.ambient[1] = fr.ambient2d.g;
    litUniforms.ambient[2] = fr.ambient2d.b;
    // A flat visual gets every directional light in full (it faces them head on): they join the ambient light.
    litUniforms.flat_ambient[0] = fr.ambient2d.r;
    litUniforms.flat_ambient[1] = fr.ambient2d.g;
    litUniforms.flat_ambient[2] = fr.ambient2d.b;
    for (const Light2DData& l : fr.lights2d) {
        if (l.pos[3] >= 0.0f) continue;
        for (int c = 0; c < 3; ++c) litUniforms.flat_ambient[c] += l.color[c];
    }
    litUniforms.light_map[0] = 1.0f / float(std::max(1, physW));
    litUniforms.light_map[1] = 1.0f / float(std::max(1, physH));
    litUniforms.light_map[2] = gpu.light_range();
    for (std::size_t i = 0; i < fr.lights2d.size() && i < std::size_t(kDirectLights2D); ++i) {
        std::memcpy(litUniforms.light_pos[i], fr.lights2d[i].pos, sizeof(float) * 4);
        std::memcpy(litUniforms.light_color[i], fr.lights2d[i].color, sizeof(float) * 4);
        const float row = fr.lights2d[i].extra[0];
        litUniforms.light_shadow_v[i][0] =
            row >= 0.0f && fr.shadowRows > 0 ? (row + 0.5f) / float(fr.shadowRows) : -1.0f;
        litUniforms.light_shadow_v[i][1] = fr.lights2d[i].shadowSize;
    }
    // M74: the cookies of those lights (light_cookie.glsl), the same for every lit batch.
    for (std::size_t i = 0; i < fr.lights2d.size() && i < std::size_t(kDirectLights2D); ++i) {
        const CookieShaderData cd = cookie_shader_data(fr.lights2d[i], gpu.is_gl());
        std::memcpy(litUniforms.light_cookie[i], cd.cell, sizeof(float) * 4);
        std::memcpy(litUniforms.light_cookie_xf[i], cd.xf, sizeof(float) * 4);
    }
    // M74 light layers: a lit batch is lit by the lights whose lightLayers share a bit with its own mask. litUniforms starts with every
    // light; a batch with another mask zeroes the colour of the lights that do not reach it (and takes the directional lights that do
    // not out of the flat ambient light). With every light on every layer (the default) nothing is ever rewritten.
    bool everyLightEverywhere = true;
    for (const Light2DData& l : fr.lights2d) everyLightEverywhere = everyLightEverywhere && l.layers == -1;
    bool layersFull = true;      // litUniforms holds every light (as filled above)
    std::int32_t layersFor = 0;  // otherwise the mask it was filled for
    const auto lit_layers = [&](std::int32_t mask) {
        const bool wantFull = everyLightEverywhere && mask != 0;
        if (wantFull ? layersFull : (!layersFull && layersFor == mask)) return;
        layersFull = wantFull;
        layersFor = mask;
        for (std::size_t i = 0; i < fr.lights2d.size() && i < std::size_t(kDirectLights2D); ++i) {
            const bool reach = wantFull || light_reaches(fr.lights2d[i].layers, mask);
            for (int c = 0; c < 3; ++c) litUniforms.light_color[i][c] = reach ? fr.lights2d[i].color[c] : 0.0f;
        }
        litUniforms.flat_ambient[0] = fr.ambient2d.r;
        litUniforms.flat_ambient[1] = fr.ambient2d.g;
        litUniforms.flat_ambient[2] = fr.ambient2d.b;
        for (const Light2DData& l : fr.lights2d) {
            if (l.pos[3] >= 0.0f || !(wantFull || light_reaches(l.layers, mask))) continue;
            for (int c = 0; c < 3; ++c) litUniforms.flat_ambient[c] += l.color[c];
        }
    };
    // M74: what a batch adds to the plain picture (QuadFx): emission and rim light, in the fragment uniforms of the batch.
    const auto fill_fx = [&](quad_quad_fs_params_t& s, const QuadBatch& qb) {
        std::memset(s.fx_emit, 0, sizeof s.fx_emit);
        std::memset(s.fx_emit_uv, 0, sizeof s.fx_emit_uv);
        std::memset(s.fx_rim, 0, sizeof s.fx_rim);
        std::memset(s.fx_rim_uv, 0, sizeof s.fx_rim_uv);
        const QuadFx& f = qb.fx;
        if (f.has_emissive()) {
            for (int c = 0; c < 3; ++c) s.fx_emit[c] = f.emissive[c];
            s.fx_emit[3] = 1.0f;
            if (f.emissiveMap) {
                s.fx_emit[3] = 2.0f + float(f.emissiveMap->tex_fix(fr.linear, true, fr.displayOverLinear));
                normal_uv_transform(*qb.tex, *f.emissiveMap, s.fx_emit_uv);
            }
        }
        if (f.has_rim() && qb.lit) {
            for (int c = 0; c < 3; ++c) s.fx_rim[c] = f.rim[c];
            s.fx_rim[3] = 1.0f;
            s.fx_rim_uv[0] = f.rimUv[0];
            s.fx_rim_uv[1] = f.rimUv[1];
        }
    };
    // The camera's stack fog on the world's quads (shaders/quad.glsl): each batch fades to the fog colour, an additive one to nothing and a
    // multiplying one to 1 (the colour that changes nothing), by the quad's own distance. Only the full program reads it.
    quad_quad_fs_params_t fogged{};
    if (fog && fog->fog) {
        fogged.fog_b[0] = fog->start;
        fogged.fog_b[1] = fog->heightDensity;
        fogged.fog_b[2] = fog->heightBase;
        fogged.fog_b[3] = fog->heightFalloff;
        fogged.fog_c[0] = fog->forward.x;
        fogged.fog_c[1] = fog->forward.y;
        fogged.fog_c[2] = fog->forward.z;
        fogged.fog_c[3] = fog->ortho ? 1.0f : 0.0f;
        fogged.fog_eye[0] = fog->eye.x;
        fogged.fog_eye[1] = fog->eye.y;
        fogged.fog_eye[2] = fog->eye.z;
        std::memcpy(litUniforms.fog_b, fogged.fog_b, sizeof(fogged.fog_b));
        std::memcpy(litUniforms.fog_c, fogged.fog_c, sizeof(fogged.fog_c));
        std::memcpy(litUniforms.fog_eye, fogged.fog_eye, sizeof(fogged.fog_eye));
        fogged.fog_col[3] = litUniforms.fog_col[3] = fog->density;
    }
    const bool fogOn = fog && fog->fog;
    const sg_view lightTexBound = flatMode == 1 ? lightTarget.texView : assets->white()->view;
    const sg_view shadowTexBound = shadowRowsTex.id ? shadowRowsTex : assets->white()->view;
    const sg_view cookieTexBound = ctx.cookieView.id ? ctx.cookieView : assets->white()->view;
    // M74-P3b: the irradiance of the 2D GI cascades, added to the lit quads of the camera's own world group (not the coverage image's).
    // The screen and debug groups draw in screen pixels (their world_xy is not a world position) and the clear group in 0..1: the field
    // does not apply to them, they bind the white image and gi_p.x = 0.
    const bool giOn = ctx.gi2d.active && ctx.gi2d.cascadePasses > 0 && ctx.gi2d.irradianceView.id && !format &&
                      ctx.gi2d.intensity > 0.0f && &batches == &ctx.gWorld.batches;
    const sg_view giTexBound = giOn ? ctx.gi2d.irradianceView : assets->white()->view;
    if (giOn) {
        std::memcpy(litUniforms.gi_xf, ctx.gi2d.xf, sizeof(litUniforms.gi_xf));
        litUniforms.gi_p[0] = ctx.gi2d.intensity;
    }
    // The material draws: fa_time and fa_target are filled for them only (the engine's own programs never read them).
    // (the size of the image the pass draws into: the game target's, or `passW` x `passH` for a smaller one)
    const float targetInv[2] = {1.0f / float(std::max(1, passW > 0 ? passW : physW)),
                                1.0f / float(std::max(1, passH > 0 ? passH : physH))};
    // The world group of the main pass may read the picture drawn so far (water2d.h): before the first batch of a run of such batches the pass
    // ends, the camera's rectangle is copied and the pass goes on from what it stored (the way the transmission copy splits it).
    auto& sc = ctx.sceneCopy;
    const bool sceneGroup = sc.live && &batches == &ctx.gWorld.batches;
    auto split_for_scene = [&]() {
        gpu.end_pass();
        if (sc.handle) transient_targets().pool.release(sc.handle);
        sc.handle = 0;
        sc.view = {};
        const int row = gpu.is_gl() ? gameTarget.h - base.y - base.h : base.y;  // image rows
        if (waterFx.copy(transient_targets(), gpu, gameTarget, base.x, row, base.w, base.h, sc.handle, sc.view)) {
            sc.map = scene_map(vp, base.x, base.y, base.w, base.h, gameTarget.w, gameTarget.h);
            ++stats.sceneCopies;
        } else if (!sceneCopyWarned) {
            sceneCopyWarned = true;
            if (base.w < 1 || base.h < 1)
                FA_ERROR(
                    "render",
                    "The picture drawn so far could not be copied for Water2D, DistortionZone2D or a sprite material "
                    "that calls fa_scene_color(): the camera's rectangle is {}x{} pixels, so there is nothing to copy; "
                    "those items are not drawn and the materials read transparent black. Hint: give the Camera a "
                    "viewport (or the CameraView a size) of at least one pixel each way.",
                    base.w, base.h);
            else
                FA_ERROR(
                    "render",
                    "The picture drawn so far could not be copied for Water2D, DistortionZone2D or a sprite material "
                    "that calls fa_scene_color(): the water and the zones are not drawn and those materials read "
                    "transparent black. Hint: lower the render scale or the window size, and see the log lines above.");
        }
        const bool last = sc.next + 1 >= sc.copyAt.size();
        PassDesc cp = pass_into(gameTarget, "game-scene");
        cp.colorLoad = SG_LOADACTION_LOAD;
        cp.depthLoad = SG_LOADACTION_LOAD;
        cp.stencilLoad = SG_LOADACTION_LOAD;
        cp.colorStore = last ? sc.finalStore : SG_STOREACTION_STORE;
        if (!last) {
            cp.depthStore = SG_STOREACTION_STORE;
            cp.stencilStore = SG_STOREACTION_STORE;
        }
        gpu.begin_pass(cp);
        if (ctx.partial) apply_view(ctx.camPx);
        ++sc.next;
        scissor = Rect{-1, -1, -1,
                       -1};  // the new pass starts with the base viewport: the next apply_clip sets the clip again
    };
    // What view 15 of a material shows (kMaterialSpriteSceneView).
    sg_view sceneBound = sceneGroup && sc.view.id ? sc.view : assets->white()->view;
    for (const QuadBatch& qb : batches) {
        if (sceneGroup && sc.next < sc.copyAt.size() && sc.copyAt[sc.next] == std::uint32_t(&qb - batches.data())) {
            split_for_scene();
            sceneBound = sc.view.id ? sc.view : assets->white()->view;
        }
        apply_clip(qb.clip);
        if (qb.effect) {
            // Water2D / DistortionZone2D with the built-in look: one quad drawn from the copy. Outside the world group of the main pass (the
            // sprite-outline coverage image) or without a copy there is nothing to read: not drawn.
            if (!sceneGroup || !sc.view.id || qb.effect > fr.world.effects.size()) continue;
            WaterFx::DrawEnv env;
            env.vertices = vbuf;
            env.viewProj = &vp;
            env.map = &sc.map;
            env.scene = sc.view;
            env.time = fr.time;
            env.targetInv[0] = targetInv[0];
            env.targetInv[1] = targetInv[1];
            env.gl = gpu.is_gl();
            env.depthTest = depthTest;
            env.format = sc.format;
            if (waterFx.draw(gpu, fr.world.effects[qb.effect - 1], qb.firstQuad, env)) ++stats.drawCalls;
            continue;
        }
        const bool plain = qb.plain && !fogOn;  // the lean program has no fog
        // A sprite material that built draws with its own programs (quad, quad_plain: the ones of its twin); one that
        // did not (the error material) draws with the built-in programs, its quads already tinted magenta by flatten().
        const MaterialUse* use = qb.use && !qb.use->error ? qb.use : nullptr;
        // A material that built has both programs (the build fails otherwise): quad_plain for a plain batch.
        const MaterialProgram* prog = use ? &use->material->programs[plain ? 1 : 0] : nullptr;
        // The instanced params of the material travel in vertex buffer 1, one value per vertex, written by flatten()
        // for exactly the batches of such a use. A use made before a hot reload that changed them has no matching data:
        // skipped for this frame (before it is counted as drawn), and reported once.
        const int instVec4 = prog ? use->instVec4 : 0;
        if (prog && instVec4 != use->material->instanceVec4) {
            if (warnedSpriteInstLayout.insert(use->material->path).second)
                FA_WARN("render",
                        "The sprite material {} is not drawn: its instanced params changed after it was reloaded, so "
                        "the batch built "
                        "before no longer matches. Hint: recompile the material (shader.compile) and reopen the scene.",
                        use->material->path);
            continue;
        }
        if (instVec4 > 0 && !ctx.vinst.id) continue;
        // A material with "buffers" is drawn from them (M72.4, sprite_buffer_draw.h): only a Sprite makes such a batch
        // (one quad, QuadBatch::instances times). The other 2D items (Shape2D, Tilemap, Text, ParticleEmitter, UiBox)
        // have no buffers to give it, so an item of that kind with the material is not drawn (and the log says so
        // once); a batch that cannot bind its buffers any more is not drawn either.
        MeshBufferUse sbu;
        if (prog && (!use->material->buffers.empty() || qb.instances > 0)) {
            if (qb.instances <= 0 || use->material->buffers.empty()) {
                // Every frame this branch is reached again: the key is cheap to build and look up, the message is built
                // once.
                const std::string key = use->material->path + " on a 2D item that is not a Sprite";
                if (!assets->failure_logged("material-sprite", key))
                    assets->note_failure(
                        "material-sprite", key,
                        "the material '" + use->material->path +
                            "' declares \"buffers\" (it is drawn from compute buffers), but a Shape2D, Tilemap, Text, "
                            "ParticleEmitter or UiBox uses it: only a Sprite can draw from buffers, so that item is "
                            "not drawn",
                        "Use a material without \"buffers\" for this item, or draw it with a Sprite whose instances is "
                        "set (docs/shaders/SHADERS_COMPUTE.md, \"Sprites from a compute buffer\").");
                continue;
            }
            if (!bind_sprite_buffer_views(*assets, compute, *use, qb.instances, sbu)) continue;
        }
        if (qb.use && !prog) {
            const std::string& path = qb.use->material->path;
            if (std::find(stats.materialFallbacks.begin(), stats.materialFallbacks.end(), path) ==
                stats.materialFallbacks.end())
                stats.materialFallbacks.push_back(path);
        } else if (prog) {
            count_material(use->material);
        }
        const sg_shader programShader = prog ? prog->shader : sg_shader{};
        sg_apply_pipeline(
            format ? gpu.quad_pipeline(*format, depthTest, false, qb.blend, plain, qb.opaque, programShader, instVec4)
                   : gpu.quad_pipeline(depthTest, false, qb.blend, plain, qb.opaque, programShader, instVec4));
        if (fogOn) {
            const float to = qb.blend == BlendMode::Multiply ? 1.0f : qb.blend == BlendMode::Additive ? 0.0f : -1.0f;
            for (int c = 0; c < 3; ++c) {
                const float v = to < 0.0f ? fog->color[c] : to;
                fogged.fog_col[c] = litUniforms.fog_col[c] = v;
            }
        }
        u.cspace[1] = float(qb.tex->tex_fix(fr.linear, true, fr.displayOverLinear));
        u.cspace[2] = qb.lit && qb.normal ? float(qb.normal->tex_fix(fr.linear, false)) : 0.0f;
        u.fa_time[0] = prog ? fr.time : 0.0f;
        apply_uniforms(UB_quad_vs_params, u);
        sg_view batchLightTex = lightTexBound;
        if (qb.lit) {
            litUniforms.lit[1] = qb.normal ? 1.0f : 0.0f;
            if (qb.normal) normal_uv_transform(*qb.tex, *qb.normal, litUniforms.normal_uv);
            lit_layers(qb.fx.layers);
            litUniforms.lit[2] = float(flatMode);
            if (flatMode == 1 && !qb.normal) {
                // The light buffer of this batch's layer mask (light_layers.h): none when no point light reaches it, or the loop
                // over the first lights when the frame ran out of buffers.
                const int buffer = ctx.layerPlan.buffer_of(qb.fx.layers);
                if (buffer >= 0) batchLightTex = light_buffer(buffer).texView;
                litUniforms.lit[2] = buffer >= 0 ? 1.0f : buffer == LightLayerPlan::kNoPoint ? 2.0f : 0.0f;
            }
        }
        if (prog) {
            // The lean program of a material declares the block too (its snippet may read fa_time and fa_target).
            if (prog->has_ub(UB_quad_quad_fs_params)) {
                quad_quad_fs_params_t fu = qb.lit ? litUniforms : fogOn ? fogged : unlit;
                fill_fx(fu, qb);
                fu.fa_time[0] = fr.time;
                fu.fa_target[0] = targetInv[0];
                fu.fa_target[1] = targetInv[1];
                fu.fa_target[2] = gpu.is_gl() ? 1.0f : 0.0f;
                if (sceneGroup &&
                    sc.view
                        .id) {  // fa_scene_color(): where the copy is (zero = no picture: it reads transparent black)
                    std::memcpy(fu.fa_scene, sc.map.scene, sizeof(fu.fa_scene));
                    std::memcpy(fu.fa_world_uv, sc.map.worldUv, sizeof(fu.fa_world_uv));
                }
                sg_range r{&fu, std::min<std::size_t>(prog->ubSize[UB_quad_quad_fs_params], sizeof(fu))};
                sg_apply_uniforms(UB_quad_quad_fs_params, &r);
            }
            apply_use_params(*prog, *use);
        } else if (qb.lit) {
            fill_fx(litUniforms, qb);
            apply_uniforms(UB_quad_quad_fs_params, litUniforms);
        } else if (!plain) {  // quad_plain declares no fragment uniforms
            quad_quad_fs_params_t& fs = fogOn ? fogged : unlit;
            fill_fx(fs, qb);
            apply_uniforms(UB_quad_quad_fs_params, fs);
        }
        // A batch from buffers is ONE quad drawn `instances` times (emit_sprite). Should another item ever make one
        // with more quads, instancing them all would repeat the whole list: draw it once, without the buffers, and say
        // so.
        int instanceCount = sbu.active ? sbu.instances : 1;
        if (sbu.active && qb.quadCount != 1) {
            instanceCount = 1;
            assets->note_failure("material-sprite", use->material->path + " batch with several quads",
                                 "a batch drawn from the buffers of '" + use->material->path + "' has " +
                                     std::to_string(qb.quadCount) +
                                     " quads, not one, so it is drawn once and not instanced",
                                 "Report this: only a Sprite with instances > 0 should make such a batch.");
        }
        std::uint32_t done = 0;
        while (done < qb.quadCount) {
            std::uint32_t n = std::min<std::uint32_t>(qb.quadCount - done, kMaxQuadsPerDraw);
            sg_bindings b{};
            b.vertex_buffers[0] = vbuf;
            b.vertex_buffer_offsets[0] = int((qb.firstQuad + done) * 4 * sizeof(Vertex2D));
            if (instVec4 > 0) {
                b.vertex_buffers[kQuadInstBuffer] = ctx.vinst;
                b.vertex_buffer_offsets[kQuadInstBuffer] =
                    int((qb.instFirst + std::size_t(done) * 4 * std::size_t(instVec4) * 4) * sizeof(float));
            }
            b.index_buffer = gpu.quad_index_buffer();
            b.views[VIEW_quad_tex] = qb.tex->gpu_view();
            b.views[VIEW_quad_normal_tex] = (qb.lit && qb.normal ? qb.normal : assets->white())->gpu_view();
            b.views[VIEW_quad_light_tex] = batchLightTex;
            b.views[VIEW_quad_shadow_tex] = shadowTexBound;
            b.views[VIEW_quad_fx_emissive_tex] = (qb.fx.emissiveMap ? qb.fx.emissiveMap : assets->white())->gpu_view();
            b.views[VIEW_quad_fx_cookie_tex] = cookieTexBound;
            b.views[VIEW_quad_fx_gi_tex] = giTexBound;
            b.samplers[SMP_quad_smp] = gpu.sampler(qb.smp);
            b.samplers[SMP_quad_light_smp] = gpu.sampler(SamplerKind::LinearClamp);
            b.samplers[SMP_quad_shadow_smp] = gpu.sampler(SamplerKind::Nearest);
            if (prog) {  // the material's textures follow the engine's views and samplers; only what the program declares
                const MaterialAsset& mat = *use->material;
                for (std::size_t i = 0; i < mat.textures.size() && i < std::size_t(kMaxMaterialTextures); ++i) {
                    // Bound for both stages; the program takes the slots it declares (vertex() may sample the texture
                    // too).
                    b.views[kMaterialSpriteFirstView + int(i)] = use->textures[i]->gpu_view();
                    b.samplers[kMaterialSpriteFirstSampler + int(i)] = gpu.sampler(mat.textures[i].sampler);
                    b.views[kMaterialSpriteVsFirstView + int(i)] = use->textures[i]->gpu_view();
                    b.samplers[kMaterialSpriteVsFirstSampler + int(i)] = gpu.sampler(mat.textures[i].sampler);
                }
                b.views[kMaterialSpriteSceneView] = sceneBound;  // its sampler is the engine's light_smp (slot 1)
                for (int i = 0; i < SG_MAX_VIEW_BINDSLOTS; ++i)
                    if (!((prog->viewMask >> i) & 1u)) b.views[i] = {};
                for (int i = 0; i < SG_MAX_SAMPLER_BINDSLOTS; ++i)
                    if (!((prog->samplerMask >> i) & 1u)) b.samplers[i] = {};
            }
            if (sbu.active) bind_mesh_buffers(b, sbu, *prog);
            sg_apply_bindings(&b);
            sg_draw(0, int(n * 6), instanceCount);
            ++stats.drawCalls;
            done += n;
        }
    }
    apply_clip(Rect{});
}

// ---- main pass ----
// PostProcess.bloomScreenSpace = false: the frame is split in two passes. This one draws the world, the bloom then
// glows it, and a second pass (hud_pass) draws the screen-space groups (HUD) on top, so the HUD never glows.
// With MSAA the multisampled image must survive every pass but the last one (STORE): the next pass loads it, and with
// the HUD over the bloom the bloom adds its glow to it, the HUD pass loads it again, so the HUD is multisampled too and
// the final resolve contains everything.
// Reads: plan (first / last / view), fr (camera, wantWorld, wantScreen, debugLines), ctx.z01, msaa, hudAfterBloom,
// clearByQuad, clearByLoad, partial, camPx, fullPx, ctx.white, ss, fuScene, vuScene, lightView, shadowRowsTex, litMode,
// opaque / blended with their batches, mainInst, the quad groups (gClear, gWorld, gDebugWorld, gScreen, gDebugScreen), vbuf,
// lineFirst, screenProj, ctx.shadowTgt.texView (doShadows) and lightTarget.texView (litMode 1), the game target images.
// Writes: the game target (gameTarget.colorAtt / resolveAtt / depthAtt); stats (drawCalls, triangles, meshes, meshBatches, materials,
// materialFallbacks).
void Renderer::Impl::main_pass(DrawContext& ctx, const PassContext& pc) {
    Frame& fr = ctx.fr;
    const JobPlan& plan = ctx.plan;
    const bool z01 = ctx.z01, msaa = ctx.msaa, hudAfterBloom = ctx.hudAfterBloom;
    const bool clearByQuad = ctx.clearByQuad, clearByLoad = ctx.clearByLoad, partial = ctx.partial;
    const Px& camPx = ctx.camPx;
    const Px& fullPx = ctx.fullPx;
    const SceneSettings& ss = ctx.ss;
    const Mat4& screenProj = ctx.screenProj;
    const std::size_t lineFirst = ctx.lineFirst;
    const sg_buffer vbuf = ctx.vbuf;
    const int litMode = ctx.litMode;
    const DrawContext::Group& gClear = ctx.gClear;
    const DrawContext::Group& gWorld = ctx.gWorld;
    const DrawContext::Group& gDebugWorld = ctx.gDebugWorld;
    const DrawContext::Group& gScreen = ctx.gScreen;
    const DrawContext::Group& gDebugScreen = ctx.gDebugScreen;
    const std::vector<MeshBatch>& opaqueBatches = ctx.opaqueBatches;
    const std::vector<MeshBatch>& blendedBatches = ctx.blendedBatches;
    const std::vector<MeshItem>& opaque = ctx.opaque;
    const std::vector<MeshItem>& blended = ctx.blended;
    const sg_buffer mainInst = ctx.mainInst;
    const mesh_fa_mesh_vs_params_t& vuScene = ctx.vuScene;
    const bool drawHudInPass = fr.wantScreen && !hudAfterBloom && !ctx.hudAfterPost && !ctx.hudOut;
    if (ctx.envActive && !skyEnv.baked()) {  // the bake did not complete: the meshes keep the gradient
        ctx.envActive = false;
        ctx.fuScene.fa_env_sky[3] = 0.0f;
        ctx.fuBlend.fa_env_sky[3] = 0.0f;
    }
    if (ctx.doMainPass) {
        // The prepass image (M73.2c): bound at the screen slot of the opaque meshes (bind_textures) while a light has a contact shadow, and
        // read by the effects after them (below).
        const Target* preT = ctx.postPlan.prepass.target(pc);
        ctx.screenView = preT ? preT->texView : sg_view{};
        PassDesc mp = pass_into(gameTarget, plan.view ? "view" : fr.wantWorld ? "game" : "game-hud");
        mp.colorLoad = clearByLoad ? SG_LOADACTION_CLEAR : SG_LOADACTION_LOAD;
        const Color clearScene = to_scene(fr.cam.clearColor, fr.linear);
        mp.clearColor = {clearScene.r, clearScene.g, clearScene.b, clearScene.a};
        // The debug view of the prepass draws over the multisampled image next, so it must be kept.
        mp.colorStore = (msaa && (plan.last || plan.view) && !hudAfterBloom && !ctx.debugPrepass)
                            ? SG_STOREACTION_DONTCARE
                            : SG_STOREACTION_STORE;
        const sg_store_action finalStore = mp.colorStore;
        // A transmissive draw splits the pass after the opaque phase (below): the first half keeps the picture, the depth and the stencil for the
        // second.
        // The same for a world group that reads the picture drawn so far (Water2D, fa_scene_color; planned just below).
        ctx.sceneCopy = {};
        ctx.sceneCopy.finalStore = finalStore;
        ctx.sceneCopy.format = mp.format;
        if (fr.wantWorld && count_scene_readers(gWorld.batches) > 0 && waterFx.ready()) {
            const int runs = plan_scene_copies(gWorld.batches, ctx.sceneCopy.copyAt);
            if (runs > kMaxSceneCopies && !sceneCapWarned) {
                sceneCapWarned = true;
                FA_WARN("render",
                        "A camera has {} separate runs of 2D draws that read the picture drawn so far (Water2D, "
                        "DistortionZone2D, sprite "
                        "materials that call fa_scene_color()): the picture is copied for the first {} only and the "
                        "later runs read the "
                        "last copy, so they do not see what is drawn between. Hint: give those items neighbouring "
                        "layers so that they "
                        "share a copy, or use fewer of them.",
                        runs, kMaxSceneCopies);
            }
        }
        const bool sceneSplits = !ctx.sceneCopy.copyAt.empty();
        if (ctx.xmit.want || sceneSplits) {
            mp.colorStore = SG_STOREACTION_STORE;
            mp.depthStore = SG_STOREACTION_STORE;
            mp.stencilStore = SG_STOREACTION_STORE;
        }
        mp.depthLoad = SG_LOADACTION_CLEAR;
        mp.clearDepth = 1.0f;
        mp.stencilLoad = SG_LOADACTION_CLEAR;
        gpu.begin_pass(mp);
        if (partial) apply_view(camPx);

        // clear of a camera that shares the target with others
        if (clearByQuad) draw_group(ctx, gClear.batches, Mat4::ortho(0, 1, 1, 0, -1.0f, 1.0f, z01), false, camPx);

        // sky. Not for a studio camera (Camera.lighting = studio paints its clearColor). The editor's Viewport has no
        // camera of its own: it shows what the scene's cameras draw, so it draws the sky exactly when the game does.
        if (fr.wantWorld && fr.cam.perspective && fr.cam.clear && !fr.cam.studio && !fr.cam.noSky) {
            // SceneSettings.skyMaterial draws the sky through its own program (same vertex stage, same uniform blocks,
            // plus the material's block and textures); anything wrong with it keeps the gradient. The meshes'
            // reflections and ambient light follow the sky that is drawn here when it is a material (plan_env bakes
            // it), else skyColor and horizonColor.
            SkyDraw sky;
            if (ctx.hdriMain) {
                sky.hdri = ctx.hdriMain;
                sky.hdriRotation = ctx.envRotation;
                sky.hdriGain = ctx.envGain;
                sky.linear = fr.linear;
            } else if (ctx.physMainOn) {
                sky.physical = true;
                sky.sunDisc = ctx.physSunOn;  // no directional light: the gradient of the air, without a disc
                sky.slot = 0;
                sky.phys = ctx.physMain;
            } else {
                fill_sky(*this, ctx, sky_material(ss), sky);
                if (sky.mat && sky.mat == ctx.skyPlannedMat)
                    std::copy(std::begin(ctx.skyPlanned), std::end(ctx.skyPlanned), sky.in.textures);
            }
            // The sky and the panorama are drawn with the jitter of the meshes (the temporal antialiasing resolves them like everything else);
            // the environment bake and everything that asks where a pixel is in the world keep the unjittered matrices.
            draw_sky(*this, sky, fr.cam.drawInvViewProj.m, fr.cam.position, nullptr);
            ++stats.drawCalls;
        }

        // meshes: one instanced draw per part of every batch
        auto draw_meshes = [&](const std::vector<MeshBatch>& batches, const std::vector<MeshItem>& items,
                               bool isBlend) {
            mesh_fa_mesh_vs_params_t vu = vuScene;
            for (const MeshBatch& batch : batches) {
                if (batch.mainCount == 0) continue;
                const MeshItem& mi = items[batch.rep];
                const MeshRenderer& mr = *mi.mr;
                vu.fa_uv_scale[0] = mr.uvScale.x;
                vu.fa_uv_scale[1] = mr.uvScale.y;
                // A lightmapped entity: the rectangle of its page (fa_lm_so.x > 0 switches the lightmap on), its own geometry and no baked lights.
                for (int k = 0; k < 4; ++k) vu.fa_lm_so[k] = mi.lm.mesh ? mi.lm.scaleOffset[k] : 0.0f;
                const std::vector<SubMesh>& drawParts = mi.lm.mesh ? mi.lm.mesh->parts : mi.mesh->parts;
                MaterialInputs inputs{};
                if (mi.material && mi.material->ok) {
                    material_inputs(mi, mi.material, inputs);
                    if (!mi.terrain && !mi.impostor) count_material(mi.material);
                } else if (mi.material && std::find(stats.materialFallbacks.begin(), stats.materialFallbacks.end(),
                                                    mi.material->path) == stats.materialFallbacks.end()) {
                    stats.materialFallbacks.push_back(mi.material->path);
                }
                const MeshBufferUse mbu = resolve_mesh_buffers(*assets, compute, mi);  // mesh_buffer_draw.h
                if (mbu.skip) continue;
                bool anyDrawn = false;  // a material with buffers that has no program for this mesh draws nothing
                for (const SubMesh& part : drawParts) {
                    const bool skinned = mi.anim && part.skinVb.id;
                    const PartDraw pd = part_draw(ctx, mi, part);
                    if (pd.error && mi.material && mi.material->ok &&
                        std::find(stats.materialFallbacks.begin(), stats.materialFallbacks.end(), mi.material->path) ==
                            stats.materialFallbacks.end())
                        stats.materialFallbacks.push_back(
                            mi.material->path);  // built, but this mesh lacks a declared channel
                    // A full-shader material draws the part once per pass, in order, each with its own program and
                    // state.
                    const int passCount =
                        pd.mat && pd.mat->full ? int(pd.mat->passes.size()) : (mbu.active && !pd.mat ? 0 : 1);
                    if (passCount == 0) continue;  // nothing is drawn for this part: it is not in the stats either
                    anyDrawn = true;
                    // The palette and the fragment parameters belong to the part, not to the pass: made by the first
                    // pass that declares the block, reused by the others.
                    bool paletteMade = false, fragmentMade = false;
                    mesh_fa_skin_t palette{};
                    mesh_fa_mesh_fs_params_t fragmentParams{};
                    for (int pass = 0; pass < passCount; ++pass) {
                        const MaterialProgram* prog =
                            pd.mat ? &pd.mat->programs[pass_program_slot(pass, skinned)] : nullptr;
                        if (pd.mat && pd.mat->full)
                            sg_apply_pipeline(
                                gpu.full_pipeline(pd.mat->passes[pass], skinned, prog->shader, pd.mat->extras()));
                        else
                            sg_apply_pipeline(gpu.mesh_pipeline(
                                isBlend, part.doubleSided || (pd.mat && pd.mat->doubleSided), skinned,
                                prog ? prog->shader : sg_shader{}, pd.mat ? pd.mat->extras() : MeshExtras{},
                                isBlend && mesh_is_transmissive(mr, *mi.mesh, mi.material),
                                mi.lodFade != 0.0f));  // the engine's program of a fading draw: the one with the dither
                        sg_bindings b{};
                        b.vertex_buffers[0] = part.vb;
                        b.vertex_buffers[1] = mainInst;
                        b.vertex_buffer_offsets[1] = int(batch.mainFirst * kMeshInstanceBytes);
                        if (skinned) b.vertex_buffers[2] = part.skinVb;
                        if (pd.mat)
                            bind_extras(b, *pd.mat, part, ctx.mainExtra, batch.mainExtra);
                        else if (!skinned)  // the engine's program always reads uv1: the lightmap UV, or zeros
                            b.vertex_buffers[kUv1Buffer] = part.uv1Vb.id && mi.lm.mesh
                                                               ? part.uv1Vb
                                                               : assets->zero_uv1(std::size_t(part.vertexCount));
                        b.index_buffer = part.ib;
                        b.index_buffer_offset = part.ibOffset;
                        bind_textures(ctx, b, pd, prog, inputs, false, !isBlend);
                        if (mbu.active && prog) bind_mesh_buffers(b, mbu, *prog);
                        sg_apply_bindings(&b);
                        if (mbu.active && prog) apply_mesh_base_model(*prog, mi.model);
                        // A full shader declares only the blocks it reads (the compiler drops an unused one).
                        if (declares(prog, UB_mesh_fa_mesh_vs_params)) apply_uniforms(UB_mesh_fa_mesh_vs_params, vu);
                        if (skinned && declares(prog, UB_mesh_fa_skin)) {
                            if (!paletteMade) {
                                palette = pack_palette(palette_of(*mi.anim, part.skin));
                                paletteMade = true;
                            }
                            apply_uniforms(UB_mesh_fa_skin, palette);
                        }
                        if (declares(prog, UB_mesh_fa_mesh_fs_params)) {
                            if (!fragmentMade) {
                                fragmentParams = fill_fs(ctx, mi, part, pd, isBlend);
                                fragmentMade = true;
                            }
                            apply_uniforms(UB_mesh_fa_mesh_fs_params, fragmentParams);
                        }
                        if (declares(prog, UB_mesh_fa_shadows)) apply_uniforms(UB_mesh_fa_shadows, ctx.shadowU);
                        if (prog) apply_material_params(*prog, inputs);
                        sg_draw(0, part.indexCount, mbu.active ? mbu.instances : int(batch.mainCount));
                        ++stats.drawCalls;
                        // Per pass drawn, like drawCalls: a part a full shader draws in 3 passes is 3 times its
                        // triangles.
                        stats.triangles += part.indexCount / 3 * (mbu.active ? mbu.instances : int(batch.mainCount));
                    }
                }
                if (mi.impostor) {  // its cards are not meshes: renderStats.impostors counts them
                    stats.impostors += int(batch.mainCount);
                    ++stats.meshBatches;
                } else if (mi.terrain) {  // its nodes are tiles, not meshes
                    stats.terrainTiles += int(batch.mainCount);
                    stats.terrainTriangles += kTerrainTrianglesPerNode * int(batch.mainCount);
                    ++stats.meshBatches;
                } else if (mi.foliage) {  // its instances are not meshes of the scene
                    stats.foliageInstances += int(batch.mainCount);
                    ++stats.meshBatches;
                } else if (anyDrawn || !mbu.active) {
                    stats.meshes += int(batch.mainCount);
                    ++stats.meshBatches;
                }
            }
        };
        draw_meshes(opaqueBatches, opaque, false);

        // The effects that work on the opaque picture (the sky and the opaque meshes) and nothing else: the ambient occlusion and the
        // camera's fog, as full-screen draws over the camera's rectangle, reading the prepass. What is drawn after them (blended meshes,
        // sprites, particles, 3D text, the HUD) is not darkened, and fogs itself by its own distance (mesh_common.glsl, quad.glsl).
        bool fogDrawn = false;
        if (preT && preT->texView.id) {
            if (partial) apply_view(camPx);
            if (ctx.ssaoApply.valid) {
                const Target* aoT = transient_targets().get(pc.handle(ctx.ssaoApply.ao));
                if (aoT && aoT->texView.id) {
                    Ssao::draw_apply(gpu, ctx.ssaoApply, aoT->texView, preT->texView, mp.format);
                    ++stats.drawCalls;
                }
            }
            if (ctx.postPlan.fogFx.fog && fogFx.draw_fog(gpu, ctx.postPlan.fogFx, preT->texView, mp.format)) {
                ++stats.drawCalls;
                fogDrawn = true;
            }
        }
        // Planned with its prepass, but the prepass image or the draw failed: the scene's own fog was already switched off for this
        // camera, so the opaque meshes show none. Said once (a frame later the plan is made again and may succeed).
        if (ctx.postPlan.fogFx.fog && !fogDrawn && !fogMissingWarned) {
            fogMissingWarned = true;
            FA_ERROR("render",
                     "The camera's fog could not be drawn this frame (its depth image is missing): the opaque meshes "
                     "show no fog. "
                     "Hint: turn PostProcess.fogEnabled off, or lower the render scale if the GPU is out of memory.");
        }

        // Transmission (renderer_xmit.h): the opaque picture is finished here. The pass ends (the multisampled picture is resolved), the picture is
        // copied into the refraction atlas, and the pass goes on from what it stored (colour, depth, stencil LOAD): the blended meshes, which see
        // the atlas at view 28, then everything drawn after them. A copy that cannot be made leaves ctx.xmit.on off: the plain blend.
        XmitImages xmitImages;
        if (ctx.xmit.want) {
            gpu.end_pass();
            const int row = gpu.is_gl() ? gameTarget.h - camPx.y - camPx.h : camPx.y;  // image rows (xmit.h)
            if (xmit.build(transient_targets(), gpu, gameTarget, camPx.x, row, camPx.w, camPx.h, xmitImages)) {
                ctx.xmit.on = true;
                ctx.xmit.levels = xmitImages.levels;
                ctx.xmit.atlasView = xmitImages.atlasView;
                ++stats.transmissionCopies;
            } else {
                ++stats.transmissionPlain;
            }
            PassDesc cp = pass_into(gameTarget, plan.view ? "view-glass" : fr.wantWorld ? "game-glass" : "game-hud");
            cp.colorLoad = SG_LOADACTION_LOAD;
            cp.colorStore = sceneSplits ? SG_STOREACTION_STORE : finalStore;
            cp.depthLoad = SG_LOADACTION_LOAD;
            cp.stencilLoad = SG_LOADACTION_LOAD;
            if (sceneSplits) {
                cp.depthStore = SG_STOREACTION_STORE;
                cp.stencilStore = SG_STOREACTION_STORE;
            }
            gpu.begin_pass(cp);
            if (partial) apply_view(camPx);
        }

        draw_meshes(blendedBatches, blended, true);

        // quad groups
        ctx.sceneCopy.live = sceneSplits;
        draw_group(ctx, gWorld.batches, fr.cam.drawViewProj, fr.cam.perspective, camPx, litMode, nullptr,
                   ctx.postPlan.fogFx.fog ? &ctx.postPlan.fogFx : nullptr);
        ctx.sceneCopy.live = false;
        draw_group(ctx, gDebugWorld.batches, fr.cam.drawViewProj, false, camPx);
        if (!fr.debugLines.empty()) {
            sg_apply_pipeline(gpu.quad_pipeline(false, true));
            quad_vs_params_t u{};
            copy_mat(u.view_proj, fr.cam.drawViewProj);
            u.cspace[0] = fr.linear ? 1.0f : 0.0f;
            apply_uniforms(UB_quad_vs_params, u);
            quad_quad_fs_params_t unlit{};
            apply_uniforms(UB_quad_quad_fs_params, unlit);
            sg_bindings b{};
            b.vertex_buffers[0] = vbuf;
            b.vertex_buffer_offsets[0] = int(lineFirst * sizeof(Vertex2D));
            b.views[VIEW_quad_tex] = assets->white()->view;
            b.views[VIEW_quad_normal_tex] = assets->white()->view;
            b.views[VIEW_quad_light_tex] = assets->white()->view;
            b.views[VIEW_quad_shadow_tex] = assets->white()->view;
            b.views[VIEW_quad_fx_emissive_tex] =
                assets->white()->view;  // the quad program declares them all: every view needs a handle
            b.views[VIEW_quad_fx_cookie_tex] = assets->white()->view;
            b.views[VIEW_quad_fx_gi_tex] = assets->white()->view;
            b.samplers[SMP_quad_smp] = gpu.sampler(SamplerKind::Nearest);
            b.samplers[SMP_quad_light_smp] = gpu.sampler(SamplerKind::LinearClamp);
            b.samplers[SMP_quad_shadow_smp] = gpu.sampler(SamplerKind::Nearest);
            sg_apply_bindings(&b);
            sg_draw(0, int(fr.debugLines.size()), 1);
            ++stats.drawCalls;
        }
        if (drawHudInPass) {
            draw_group(ctx, gScreen.batches, screenProj, false, fullPx, 0);
            draw_group(ctx, gDebugScreen.batches, screenProj, false, fullPx, 0);
        }

        gpu.end_pass();
        if (xmitImages.atlas) xmit.finish(transient_targets(), xmitImages);
        if (ctx.sceneCopy.handle) transient_targets().pool.release(ctx.sceneCopy.handle);
        ctx.sceneCopy.handle = 0;
        ctx.sceneCopy.view = {};
    }  // doMainPass
}

// ---- HUD pass: screen-space groups over the finished frame ----
// PostProcess.bloomScreenSpace = false draws them over the glowing game target ("hud-over-bloom"); a final pass that converts the picture
// (exposure, tonemap, linear colour) draws them over its result in hudTarget, in display space ("hud-over-post"). Either way they are
// never glowed, tonemapped or exposed.
// Reads: ctx.gScreen, ctx.gDebugScreen, ctx.screenProj, ctx.vbuf, ctx.msaa, `into` (LOAD). Writes: `into`; stats.drawCalls. Declared by
// build_graph when there is something to draw.
void Renderer::Impl::hud_pass(DrawContext& ctx, const Target& into, const char* label) {
    const bool msaa = into.samples > 1;
    // At the output size (the upscale stage, M76-P3a) the items are clipped and rasterized at scale 1 over a picture of the design size.
    const bool atOutput = ctx.hudOut;
    struct SizeScope {
        Impl& im;
        int w, h;
        float scale;
        ~SizeScope() {
            im.physW = w;
            im.physH = h;
            im.renderScale = scale;
        }
    } sizes{*this, physW, physH, renderScale};
    if (atOutput) {
        physW = into.w;
        physH = into.h;
        renderScale = 1.0f;
    }
    const Px fullPx = atOutput ? Px{0, 0, into.w, into.h} : ctx.fullPx;
    const Mat4& screenProj = ctx.screenProj;
    const DrawContext::Group& gScreen = ctx.gScreen;
    const DrawContext::Group& gDebugScreen = ctx.gDebugScreen;
    // The items go over the final picture, which holds display (sRGB) values: they are drawn as in a gamma scene, whatever the colour space.
    const bool saveLinear = ctx.fr.linear;
    const bool saveOver = ctx.fr.displayOverLinear;
    if (ctx.hudAfterPost || ctx.hudDisplay) {
        ctx.fr.displayOverLinear = saveLinear;
        ctx.fr.linear = false;
    }
    PassDesc hp = pass_into(into, label);
    hp.colorLoad = SG_LOADACTION_LOAD;  // keep the world and its glow
    hp.colorStore = msaa ? SG_STOREACTION_DONTCARE : SG_STOREACTION_STORE;
    hp.depthLoad = SG_LOADACTION_CLEAR;
    hp.clearDepth = 1.0f;
    hp.stencilLoad = SG_LOADACTION_CLEAR;
    gpu.begin_pass(hp);
    const TargetFormat* format =
        atOutput ? &into.format : nullptr;  // the output image is not multisampled: its own pipelines
    draw_group(ctx, gScreen.batches, screenProj, false, fullPx, 0, format);
    draw_group(ctx, gDebugScreen.batches, screenProj, false, fullPx, 0, format);
    gpu.end_pass();
    ctx.fr.linear = saveLinear;
    ctx.fr.displayOverLinear = saveOver;
}

// Declares the passes of the job in `graph` (the frame's), named "<job>/<pass>", in the order they always ran: the light buffer,
// the shadow map, the main pass, and in the last job of the frame the post-processing stack of the frame (the postCams' plans, postprocess.h): bloom (its
// stages), the HUD over the bloom (PostProcess.bloomScreenSpace false), the automatic exposure of each camera, the final pass `post` of each camera over its rectangle (exposure, tonemap, the
// output encode), the HUD over it (`hud-over-post`) and the colour filter. A frame without a stack declares none of them. The targets
// that outlive the frame (the game target or the view's image, the light buffer, the shadow map, the final images: present() and
// capture() sample them after the graph ran) are imported; the bloom levels and the exposure measure are transients of the pool. The game target, the light buffer and the shadow map
// are one resource each for the whole frame (the jobs that use them are declared in the order they run, so each one sees what
// the one before wrote); a view job's image is its own resource, which the jobs that show it read (`plan.shows`).
// Every callback puts the job's JobEnv in place while it runs (a view job draws with the view's size and images).
// Reads: what the phases decided (litMode, doShadows, doMainPass, clearByLoad, hudAfterBloom, the screen groups), plan,
// post, the game, light, shadow and filter targets, jobImages. Writes: graph, filterActive (false for the frame; the filter
// pass sets it), the shared resources.
void Renderer::Impl::build_graph(DrawContext& ctx) {
    Frame& fr = ctx.fr;
    const JobPlan& plan = ctx.plan;
    // `fn` keeps its own type instead of becoming a std::function first: the pass's callback wraps it once, not twice.
    auto add_job = [&](const std::string& jobName, const std::string& name, std::vector<ResourceId> reads,
                       std::vector<ResourceId> writes, auto&& fn, bool sideEffect = false) {
        GraphPass p;
        p.name = jobName + "/" + name;
        p.sideEffect = sideEffect;
        p.reads = std::move(reads);
        p.writes = std::move(writes);
        p.execute = [this, &ctx, body = std::forward<decltype(fn)>(fn)](const PassContext& c) {
            EnvScope env(*this, ctx.env);
            body(c);
        };
        graph.add_pass(std::move(p));
    };
    auto add = [&](const std::string& name, std::vector<ResourceId> reads, std::vector<ResourceId> writes, auto&& fn,
                   bool sideEffect = false) {
        add_job(plan.name, name, std::move(reads), std::move(writes), std::forward<decltype(fn)>(fn), sideEffect);
    };
    // One imported resource per frame for a target the jobs share; its handle and size follow the latest job.
    auto shared = [&](ResourceId& slot, const char* name, std::uint64_t handle, const TransientDesc& imageDesc) {
        if (slot.valid())
            graph.set_import_handle(slot, handle, &imageDesc);
        else
            slot = graph.import_target(name, handle, imageDesc);
        return slot;
    };
    const ResourceId game = plan.view ? plan.image
                                      : shared(sharedGame, "game", gameTarget.colorAtt.id,
                                               import_desc(physW, physH, gameTarget.format, "game"));
    std::vector<ResourceId> shown;  // the images of other jobs this job samples (the ones drawn before it)
    for (std::uint64_t key : plan.shows) {
        auto it = jobImages.find(key);
        if (it != jobImages.end() && std::find(shown.begin(), shown.end(), it->second.shown) == shown.end())
            shown.push_back(it->second.shown);
    }
    ResourceId lightRes, shadowRes, cookieRes;
    if (!ctx.cookieCells
             .empty()) {  // M74: the cookies of the lights, copied into the atlas the lit visuals and the light buffers read
        cookieRes = shared(sharedCookie, "light-cookies", cookieTarget.color.id,
                           import_desc(cookieTarget.w, cookieTarget.h, cookieTarget.format, "light-cookies"));
        add("light-cookies", {}, {cookieRes}, [this, &ctx](const PassContext&) { cookie_pass(ctx.cookieCells); });
    }
    if (ctx.litMode == 1) {
        lightRes = shared(sharedLight, "light-buffer", lightTarget.color.id,
                          import_desc(lightW, lightH, lightTarget.format, "light-buffer"));
        std::vector<ResourceId> lightReads;
        if (cookieRes.valid()) lightReads.push_back(cookieRes);
        add("light-buffer", std::move(lightReads), {lightRes}, [this, &ctx](const PassContext&) { light_pass(ctx); });
    }
    if (ctx.doShadows) {  // no shadow caster, no pass
        shadowRes = shared(sharedShadow, "shadow-map", ctx.shadowTgt.color.id,
                           import_desc(ctx.shadowTgt.w, ctx.shadowTgt.h, ctx.shadowTgt.format, "shadow-map"));
        add("shadow", {}, {shadowRes}, [this, &ctx](const PassContext&) { shadow_pass(ctx); });
    }
    // The 2D GI field (gi2d_plan): its passes run before the camera's main pass, which P3b's cascades will read it in.
    if (ctx.gi2d.active) {
        if (gi2d.add_passes(graph, transient_targets(), gpu, ctx.gi2d, plan.name, &stats.drawCalls) == 0)
            ctx.gi2d.active = false;
    }
    // The sky environment (plan_env): the first job that wants it declares the bake, every job that uses it reads it
    // before its main pass.
    ResourceId envRes;
    if (ctx.envActive) {
        TransientDesc envDesc =
            import_desc(kEnvSize, kEnvSize, TargetFormat{skyEnv.format(), SG_PIXELFORMAT_NONE, 1}, "sky-env");
        envRes = shared(sharedEnv, "sky-env", skyEnv.image_id(), envDesc);
        if (ctx.envBake)
            add("sky-env", {}, {envRes}, [this, &ctx](const PassContext&) {
                if (!ctx.envBake) return;  // the job lost the environment to a camera of the picture (plan_env)
                const std::uint64_t key = ctx.envKey;
                const SkyDraw& sky = ctx.envSky;
                // A bake that starts (a whole one, or the first slice of a sequence) draws the sky of this frame, and the physical
                // sky needs its environment table for it; the next slices finish the images from the first's.
                const bool starts = !ctx.envSliced || !skyEnv.busy();
                if (starts) {
                    skyEnv.set_look(ctx.envGain, ctx.envTap);
                    if (sky.physical) physSky.update(gpu, sky.slot, sky.phys, &stats.drawCalls);
                    skyEnv.set_tag(sky.physical ? ctx.envStatic : 0,
                                   ctx.envSun);  // a sky of another kind: the next physical bake is whole
                }
                const auto draw = [this, &sky](const float* invViewProj, const TargetFormat& format) {
                    draw_sky(*this, sky, invViewProj, Vec3{0.0f, 0.0f, 0.0f}, &format);
                };
                if (ctx.envSliced)
                    skyEnv.bake_slice(gpu, key, draw, &stats.drawCalls);
                else
                    skyEnv.bake(gpu, key, draw, &stats.drawCalls);
                probes_write_sky();  // the meshes read the sky from its entry of the probe atlas
            });
    }
    // The physical sky's table of the picture: the first job that shows the sky draws it, the others read it.
    ResourceId skyLutRes;
    if (ctx.physMainOn) {
        const TransientDesc lutDesc =
            import_desc(kSkyViewW, kSkyViewH, TargetFormat{physSky.format(), SG_PIXELFORMAT_NONE, 1}, "sky-view");
        skyLutRes = shared(sharedSkyLut, "sky-view", physSky.image_id(), lutDesc);
        if (skyLutFrame != frameSerial) {
            skyLutFrame = frameSerial;
            add("sky-view", {}, {skyLutRes},
                [this, &ctx](const PassContext&) { physSky.update(gpu, 0, ctx.physMain, &stats.drawCalls); });
        }
    }
    ResourceId prepassRes, velRes;
    if (ctx.doPrepass) {  // the image is a transient: the effects that read it list it in their reads
        TransientDesc pdsc;
        pdsc.width = ctx.camPx.w;  // the camera's rectangle of the picture
        pdsc.height = ctx.camPx.h;
        pdsc.format = gpu.prepass_target_format();
        pdsc.label = plan.name + "/prepass";  // resource names are unique in a graph, and every camera has its own
        prepassRes = graph.create_transient(pdsc);
        ctx.postPlan.prepass = PrepassRef{prepassRes, &transient_targets()};
        // M76: the motion vectors, a second attachment of the same pass (RG16F, the size of the prepass). The pass writes both, so whoever
        // reads one lists the pass before it in the graph; PostPlan::velocity is valid from here on only when the GPU made the image.
        std::vector<ResourceId> prepassOut{prepassRes};
        if (ctx.doVelocity) {
            TransientDesc vdsc = pdsc;
            vdsc.format = TargetFormat{Gpu::velocity_format(), SG_PIXELFORMAT_NONE, 1};
            vdsc.label = plan.name + "/velocity";
            velRes = graph.create_transient(vdsc);
            prepassOut.push_back(velRes);
            ctx.postPlan.velocity = VelocityRef{PrepassRef{velRes, &transient_targets()}};
        }
        // Never culled: nothing reads the image until an effect or the debug view does, and the passes that need it are declared after.
        add(
            "prepass", {}, prepassOut,
            [this, &ctx, prepassRes, velRes](const PassContext& c) {
                const Target* t = transient_targets().get(c.handle(prepassRes));
                const Target* v = velRes.valid() ? transient_targets().get(c.handle(velRes)) : nullptr;
                if (t) prepass_pass(ctx, *t, false, v);
            },
            true);
        // The depth pyramid of the camera (renderer_hiz.cpp): a compute pass reduces the image to a small grid the CPU reads back a frame later.
        if (ctx.hiz) {
            HizCamera* hc = ctx.hiz;
            add(
                "hiz-reduce", {prepassRes}, {},
                [this, &ctx, hc, prepassRes](const PassContext& c) {
                    const Target* t = transient_targets().get(c.handle(prepassRes));
                    if (t) hiz_reduce_pass(*hc, *t, hiz_pose_of(ctx.fr.cam), ctx.world.frame());
                },
                true);
        }
        // A face of a realtime GI capture: the same prepass with the back faces only, and the pass that turns the two into the face's
        // distance picture (renderer_gi.cpp). A probe whose first hit is a back face is inside geometry.
        if (plan.gi) {
            pdsc.label = plan.name + "/prepass-back";
            const ResourceId backRes = graph.create_transient(pdsc);
            add(
                "prepass-back", {}, {backRes},
                [this, &ctx, backRes](const PassContext& c) {
                    const Target* t = transient_targets().get(c.handle(backRes));
                    if (t) prepass_pass(ctx, *t, true);
                },
                true);
            GiFacePlan* gi = plan.gi;
            gi->drawn = true;
            add(
                "gi-distance", {prepassRes, backRes}, {},
                [this, prepassRes, backRes, gi](const PassContext& c) {
                    const Target* front = transient_targets().get(c.handle(prepassRes));
                    const Target* back = transient_targets().get(c.handle(backRes));
                    if (front && back && front->texView.id && back->texView.id)
                        probes.gpu.gi_dist(gpu, gi->distIndex, front->texView, back->texView, gi->maxDistance,
                                           &probes.gi.drawCalls);
                },
                true);
        }
    }
    // The march of the volumetric fog (renderer_volumetric.h): in this camera's own job, after its shadow and prepass passes, because it reads the
    // shadow atlas this job drew (a later job may draw into the shared atlas again). The pass that blends it over the picture is declared with the
    // post stack, in the last job.
    if (ctx.postPlan.vol.on && ctx.postPlan.prepass.valid()) {
        const ResourceId volRes = graph.create_transient(VolumetricFx::image_desc(ctx.postPlan.vol, plan.name));
        ctx.postPlan.volImage = volRes;
        std::vector<ResourceId> reads{prepassRes};
        if (ctx.doShadows) reads.push_back(shadowRes);
        add("vol-march", std::move(reads), {volRes}, [this, &ctx, volRes, prepassRes](const PassContext& c) {
            const Target* vt = transient_targets().get(c.handle(volRes));
            const Target* pt = transient_targets().get(c.handle(prepassRes));
            if (!vt || !pt) return;
            const sg_view shadowTex =
                ctx.doShadows && ctx.shadowTgt.texView.id ? ctx.shadowTgt.texView : ctx.white->view;
            volFx.march(gpu, ctx.postPlan.vol, *vt, pt->texView, shadowTex, ctx.lightView, ctx.shadowU,
                        &stats.drawCalls);
        });
    }
    // The subsurface draw (M73.5): in this camera's own job, after its shadow and prepass passes (it reads this job's shadow atlas); the blur and the pass that
    // adds the change to the picture are declared with the post stack, in the last job.
    if (ctx.sssOn && ctx.postPlan.prepass.valid()) {
        const ResourceId lightRes_ = graph.create_transient(SssFx::light_desc(ctx.postPlan.sss, plan.name));
        const ResourceId paramRes = graph.create_transient(SssFx::params_desc(ctx.postPlan.sss, plan.name + "/b"));
        ctx.postPlan.sssLight = lightRes_;
        ctx.postPlan.sssParams = paramRes;
        std::vector<ResourceId> reads{prepassRes};
        if (ctx.doShadows) reads.push_back(shadowRes);
        if (ctx.envActive) reads.push_back(envRes);
        reads.insert(reads.end(), shown.begin(), shown.end());
        add("sss-draw", std::move(reads), {lightRes_, paramRes},
            [this, &ctx, lightRes_, paramRes, prepassRes](const PassContext& c) {
                const Target* at = transient_targets().get(c.handle(lightRes_));
                const Target* bt = transient_targets().get(c.handle(paramRes));
                const Target* pt = transient_targets().get(c.handle(prepassRes));
                if (at && bt && pt) sss_draw_pass(ctx, *at, *bt, *pt);
            });
    }
    // The ambient occlusion (renderer_ssao.h): its images are made from the prepass before the main pass, which applies them after the
    // opaque meshes (main_pass). Only a job that draws the world and has the prepass declares them.
    ctx.ssaoApply = SsaoApply{};
    if (ctx.doMainPass && ctx.doPrepass && fr.wantWorld && ctx.postPlan.ssao.enabled && ctx.postPlan.prepass.valid())
        ssao.add_passes(graph, transient_targets(), gpu, ctx.postPlan.ssao, ssao_camera(fr.cam), ctx.postPlan.prepass,
                        ctx.postPlan.rect, physW, physH, ctx.postPlan.sceneLinear, &stats.drawCalls, plan.name,
                        &ctx.ssaoApply);
    if (ctx.doMainPass) {
        std::vector<ResourceId> reads;
        if (ctx.postPlan.prepass.valid()) reads.push_back(ctx.postPlan.prepass.res);
        if (ctx.ssaoApply.valid) reads.push_back(ctx.ssaoApply.ao);
        if (ctx.litMode == 1) reads.push_back(lightRes);
        if (cookieRes.valid()) reads.push_back(cookieRes);
        if (ctx.gi2d.active && ctx.gi2d.cascadePasses > 0) reads.push_back(ctx.gi2d.irradiance);
        if (ctx.doShadows) reads.push_back(shadowRes);
        if (ctx.envActive) reads.push_back(envRes);
        if (ctx.physMainOn) reads.push_back(skyLutRes);
        if (!ctx.clearByLoad) reads.push_back(game);  // LOAD: a second camera or the HUD job continues the picture
        reads.insert(reads.end(), shown.begin(), shown.end());
        add(plan.view      ? "view"
            : fr.wantWorld ? "game"
                           : "game-hud",
            std::move(reads), {game}, [this, &ctx](const PassContext& c) { main_pass(ctx, c); });
        if (forceVelocity && velRes.valid())
            add(
                "velocity-probe", {velRes}, {},
                [this, &ctx, velRes](const PassContext& c) {
                    if (const Target* v = transient_targets().get(c.handle(velRes))) velocity_probe_pass(ctx, *v);
                },
                true);
        if (ctx.debugPrepass) {
            // The debug view "motionVectors" paints the velocity image (the prepass's depth and normals are not part of it).
            const bool vv = debugView == DebugView::MotionVectors && velRes.valid();
            const ResourceId shown = vv ? velRes : prepassRes;
            add("prepass-view", {shown, game}, {game}, [this, &ctx, shown](const PassContext& c) {
                const Target* t = transient_targets().get(c.handle(shown));
                if (t) prepass_view_pass(ctx, *t);
            });
        }
    }
    ResourceId coverageRes;
    if (ctx.doCoverage) {  // a sprite outline: the 2D world's alpha in an RGBA8 transient, read by the final pass
        TransientDesc cdsc;
        cdsc.width = ctx.camPx.w;
        cdsc.height = ctx.camPx.h;
        cdsc.format = TargetFormat{SG_PIXELFORMAT_RGBA8, SG_PIXELFORMAT_NONE, 1};
        cdsc.label = plan.name + "/sprite-coverage";
        coverageRes = graph.create_transient(cdsc);
        ctx.postPlan.coverage = PrepassRef{coverageRes, &transient_targets()};
        add("sprite-coverage", {}, {coverageRes}, [this, &ctx, coverageRes](const PassContext& c) {
            const Target* t = transient_targets().get(c.handle(coverageRes));
            if (t) coverage_pass(ctx, *t);
        });
    }
    // A capture through a camera: its custom passes run over the picture the main pass drew, in the order of their
    // places, as one chain (a view job has no final pass to cut). The picture is the view's resolved image, as the
    // game's is for the bloom.
    if (plan.customPost && plan.target && ctx.postPlan.custom.any()) {
        const BloomTarget dst{ctx.msaa ? plan.target->resolveColorAtt : plan.target->colorAtt, sg_view{}, 1};
        customPost.add_passes(graph, transient_targets(), gpu, sceneFx, ctx.postPlan.custom,
                              (1u << kPostSlotCount) - 1u, ctx.postPlan.rect, physW, physH, game, plan.target->texView,
                              dst, gpu.scene_format(), ctx.postPlan.prepass, fr.linear, fr.time, &stats.drawCalls,
                              stats.materialFallbacks, plan.name);
    }
    if (!plan.last) return;

    // ---- the post-processing stack of the frame (postprocess.h): bloom -> the final pass of every camera -> the HUD -> the colour filter ----
    filterActive = false;
    hudActive = false;
    outActive = false;
    outFilterActive = false;
    finalEncoded = false;
    // The upscale stage (M76-P3a, render_upscale.h): the finished picture of the render resolution (`srcRes`, held by `srcTarget`) is
    // brought to the output size, the screen-space items are drawn over it there (hud-over-upscale), and the colour filter, which
    // must reach them, runs after. Nothing is declared (and no image made) unless Renderer::set_upscale_stage is on and the game
    // is drawn below the output size.
    auto finish_output = [&](ResourceId srcRes, const Target* srcTarget, const PostPlan* filterPlan) {
        if (!upscale_active() || plan.view) return;
        // With the items for it (hudOut) the image was made, with its depth, by plan_job for the format the picture has here; else it is made now.
        // When it cannot be made the picture stays at the render resolution and the items stay in it, where plan_job (hudOut false) left them.
        if (!ensure_output_target(outTarget, "output", ctx.hudOut ? outTarget.format.color : srcTarget->format.color,
                                  false))
            return;
        const ResourceId outRes = graph.import_target("output", outTarget.colorAtt.id,
                                                      import_desc(targetW, targetH, outTarget.format, "output"));
        // The temporal upscaler also reads the camera's prepass (the depth that reprojects its history) and the velocity, when they exist.
        std::vector<ResourceId> upReads{srcRes};
        upscalePrepass = PrepassRef{};
        upscaleVelocity = VelocityRef{};
        if (upscaleImpl == render::UpscaleImpl::Temporal && upscaleTaa.on && !postCams.empty()) {
            const PostPlan& cam0 = postCams.front()->postPlan;
            upscalePrepass = cam0.prepass;
            upscaleVelocity = cam0.velocity;
            if (upscalePrepass.valid()) upReads.push_back(upscalePrepass.res);
            if (upscaleVelocity.valid()) upReads.push_back(upscaleVelocity.res);
        }
        add("upscale", std::move(upReads), {outRes}, [this](const PassContext& c) { run_upscale(outTarget, c); });
        if (!ctx.hudOut) return;
        std::vector<ResourceId> reads{outRes};
        reads.insert(reads.end(), shown.begin(), shown.end());
        add("hud-over-upscale", std::move(reads), {outRes},
            [this, &ctx](const PassContext&) { hud_pass(ctx, outTarget, "output-hud"); });
        if (filterPlan && filterPlan->colorFilter != 0 &&
            ensure_output_target(outFilterTarget, "output-filtered", gpu.display_format(), false)) {
            const ResourceId filtered =
                graph.import_target("output-filtered", outFilterTarget.color.id,
                                    import_desc(targetW, targetH, outFilterTarget.format, "output-filtered"));
            add("output-color-filter", {outRes}, {filtered}, [this, pp = *filterPlan](const PassContext&) {
                post_pass(pp, false, pp.colorFilter, false, outTarget.texView, assets->white()->view, sg_view{},
                          outFilterTarget, "color-filter", false);
                outFilterActive = true;
            });
        }
    };
    for (auto it = autoExposures.begin(); it != autoExposures.end();) {
        if (it->second.frame + 1 < postSerial) {  // its camera has not asked for two frames
            if (it->second.exposure) it->second.exposure->release();
            it = autoExposures.erase(it);
        } else {
            ++it;
        }
    }
    if (postCams.empty()) {  // no camera drew a pixel
        finish_output(game, &gameTarget, nullptr);
        return;
    }
    for (DrawContext* c : postCams)
        if (c->postPlan.fx.outline && !c->postPlan.outline_source().valid())
            c->postPlan.skip_outline();  // no image to read
    // The frame's bloom and colour filter are the first camera's (the one that draws first); everything else is the camera's own.
    const PostPlan& pp = postCams.front()->postPlan;
    // The final pass reads the outline's image, and hands its view to post.glsl (a pass that is not the final one has none).
    auto outline_view = [](const PostPlan& plan_, const PassContext& c, PostPlan& use) {
        use = plan_;
        const Target* t = use.fx.outline ? use.outline_source().target(c) : nullptr;
        if (use.fx.outline && !(t && t->texView.id))
            use.skip_outline();  // the pass did not get the image: drawn without
        return t && use.fx.outline ? t->texView : sg_view{};
    };
    // The custom post passes of PostProcess.customPasses (renderer_custom_post.h) at one place of the stack: every
    // camera's own, over its rectangle of the picture, where the built-in passes of the camera before and after leave
    // it. Where a pass that works on the game picture in place writes: the multisampled image (resolved at the end of
    // the pass) when the screen-space items are drawn into it after, else the resolved image.
    auto game_dst = [&]() {
        return ctx.hudAfterBloom && ctx.msaa
                   ? BloomTarget{gameTarget.colorAtt, gameTarget.resolveAtt, gpu.sample_count()}
                   : BloomTarget{ctx.msaa ? gameTarget.resolveColorAtt : gameTarget.colorAtt, sg_view{}, 1};
    };
    auto custom_slot = [&](PostSlot slot) {
        for (DrawContext* c : postCams) {
            if (!c->postPlan.custom.any_in(slot)) continue;
            customPost.add_passes(graph, transient_targets(), gpu, sceneFx, c->postPlan.custom, 1u << int(slot),
                                  c->postPlan.rect, physW, physH, game, gameTarget.texView, game_dst(),
                                  gpu.scene_format(), c->postPlan.prepass, c->postPlan.sceneLinear, fr.time,
                                  &stats.drawCalls, stats.materialFallbacks, c->plan.name);
        }
    };
    custom_slot(PostSlot::Main);
    // The subsurface scattering of every camera (renderer_subsurface.h): the blur of the light the sss-draw pass left in its images, and the change it makes
    // added to the camera's rectangle of the picture the main pass drew (the blended meshes are in it, as the fog sees them).
    for (DrawContext* c : postCams) {
        if (!c->postPlan.sss.on || !c->postPlan.sssLight.valid() || !c->postPlan.sssParams.valid()) continue;
        sssFx.add_passes(graph, transient_targets(), gpu, c->postPlan.sss, c->postPlan.sssLight, c->postPlan.sssParams,
                         c->postPlan.rect, physW, physH, game, game_dst(), &stats.drawCalls, c->plan.name);
    }
    // The volumetric fog of every camera (renderer_volumetric.h): its march image blended over the camera's rectangle of the picture the main pass drew (the
    // blended meshes are in it), before the reflections, the sun shafts and the rest of the stack.
    for (DrawContext* c : postCams) {
        if (!c->postPlan.vol.on || !c->postPlan.prepass.valid() || !c->postPlan.volImage.valid()) continue;
        const BloomTarget volDst =
            ctx.hudAfterBloom && ctx.msaa
                ? BloomTarget{gameTarget.colorAtt, gameTarget.resolveAtt, gpu.sample_count()}
                : BloomTarget{ctx.msaa ? gameTarget.resolveColorAtt : gameTarget.colorAtt, sg_view{}, 1};
        volFx.add_apply(graph, transient_targets(), gpu, c->postPlan.vol, c->postPlan.volImage, c->postPlan.rect, physW,
                        physH, game, volDst, c->postPlan.prepass, &stats.drawCalls, c->plan.name);
    }
    // Screen-space reflections of every camera (renderer_ssr.h), over its rectangle of the scene colour, on the picture the main pass drew (the ambient occlusion
    // and the fog are already in it), before the sun shafts, the depth of field and the rest of the stack.
    for (DrawContext* c : postCams) {
        if (!c->postPlan.ssr.any() || !c->postPlan.prepass.valid()) continue;
        const BloomTarget ssrDst =
            ctx.hudAfterBloom && ctx.msaa
                ? BloomTarget{gameTarget.colorAtt, gameTarget.resolveAtt, gpu.sample_count()}
                : BloomTarget{ctx.msaa ? gameTarget.resolveColorAtt : gameTarget.colorAtt, sg_view{}, 1};
        ssr.add_passes(graph, transient_targets(), gpu, c->postPlan.ssr, c->postPlan.rect, physW, physH, game,
                       gameTarget.texView, ssrDst, c->postPlan.prepass, &stats.drawCalls, c->plan.name);
    }
    custom_slot(PostSlot::AfterSsr);
    // The sun shafts of every camera (renderer_fog.h), over its rectangle of the scene colour, before the depth of field. (The fog is
    // drawn in the main pass.)
    for (DrawContext* c : postCams) {
        if (!c->postPlan.fogFx.shafts || !c->postPlan.prepass.valid()) continue;
        const BloomTarget fogDst =
            ctx.hudAfterBloom && ctx.msaa
                ? BloomTarget{gameTarget.colorAtt, gameTarget.resolveAtt, gpu.sample_count()}
                : BloomTarget{ctx.msaa ? gameTarget.resolveColorAtt : gameTarget.colorAtt, sg_view{}, 1};
        fogFx.add_passes(graph, transient_targets(), gpu, c->postPlan.fogFx, c->postPlan.rect, physW, physH, game,
                         gameTarget.texView, fogDst, c->postPlan.prepass, &stats.drawCalls, c->plan.name);
    }
    // Temporal antialiasing of every camera (renderer_taa.h): the jittered picture resolved with its history, over the camera's rectangle of
    // the scene colour, after the sun shafts (and the custom passes "after:ssr", which are in it) and before the depth of field. The camera's
    // history lives in the TaaFx: a camera that is not planned a frame loses it.
    if (framePost) taa.sweep(postSerial);
    for (DrawContext* c : postCams) {
        if (!c->postPlan.taa.on) continue;
        const BloomTarget taaDst =
            ctx.hudAfterBloom && ctx.msaa
                ? BloomTarget{gameTarget.colorAtt, gameTarget.resolveAtt, gpu.sample_count()}
                : BloomTarget{ctx.msaa ? gameTarget.resolveColorAtt : gameTarget.colorAtt, sg_view{}, 1};
        taa.add_passes(graph, gpu, c->postPlan.taa, c->postPlan.rect, physW, physH, game, gameTarget.texView, taaDst,
                       c->postPlan.prepass, c->postPlan.velocity, PrepassRef{}, assets->white()->view, &stats.drawCalls,
                       c->plan.name);
    }
    custom_slot(PostSlot::AfterShafts);
    // Depth of field and motion blur of every camera (renderer_dof.h), over its rectangle of the scene colour and before the bloom.
    for (DrawContext* c : postCams) {
        if (!c->postPlan.sceneFx.any() || !c->postPlan.prepass.valid()) continue;
        const BloomTarget fxDst =
            ctx.hudAfterBloom && ctx.msaa
                ? BloomTarget{gameTarget.colorAtt, gameTarget.resolveAtt, gpu.sample_count()}
                : BloomTarget{ctx.msaa ? gameTarget.resolveColorAtt : gameTarget.colorAtt, sg_view{}, 1};
        sceneFx.add_passes(graph, transient_targets(), gpu, c->postPlan.sceneFx, c->postPlan.rect, physW, physH, game,
                           gameTarget.texView, fxDst, c->postPlan.prepass, &stats.drawCalls, c->plan.name);
    }
    custom_slot(PostSlot::AfterDof);
    if (pp.bloom.enabled) {
        BloomTarget dst;
        if (ctx.hudAfterBloom && ctx.msaa) {
            // Glow into the multisampled image (resolved again at the end of the composite pass) so the HUD pass below
            // can load it. Reads the already resolved image of the main pass.
            dst = BloomTarget{gameTarget.colorAtt, gameTarget.resolveAtt, gpu.sample_count()};
        } else {
            // The finished frame: the resolved image when MSAA is on (the main pass already resolved into it).
            dst = BloomTarget{ctx.msaa ? gameTarget.resolveColorAtt : gameTarget.colorAtt, sg_view{}, 1};
        }
        // The lens dirt: its texture, or a white one the composite ignores (intensity 0) when there is none.
        const sg_view dirt = pp.bloom.dirt.empty() ? assets->white()->view : assets->texture(pp.bloom.dirt)->view;
        bloom.add_passes(graph, transient_targets(), gpu, pp.bloom, physW, physH, game, gameTarget.texView, dst, dirt,
                         &stats.drawCalls, plan.name);
    }
    custom_slot(PostSlot::AfterBloom);
    const bool hudItems = fr.wantScreen && (!ctx.gScreen.batches.empty() || !ctx.gDebugScreen.batches.empty());
    if (ctx.hudAfterBloom && hudItems && !ctx.hudOut) {
        std::vector<ResourceId> reads{game};
        reads.insert(reads.end(), shown.begin(), shown.end());
        add("hud-over-bloom", std::move(reads), {game},
            [this, &ctx](const PassContext&) { hud_pass(ctx, gameTarget, "game-hud"); });
    }
    // The final pass of every camera that has one: exposure, tonemap and the output encode (and the colour filter, when nothing is drawn
    // in between) in one pass over the camera's rectangle.
    bool anyFinal = false;
    for (const DrawContext* c : postCams) anyFinal = anyFinal || c->postPlan.final_pass();
    ResourceId finishRes = game;  // the picture the upscale stage reads: the last pass below that wrote it
    const Target* finishTarget = &gameTarget;
    if (anyFinal && (ctx.hudAfterPost || ensure_filter_target())) {
        const bool hud = ctx.hudAfterPost;
        const ResourceId dest =
            hud ? graph.import_target("game-post", hudTarget.colorAtt.id,
                                      import_desc(physW, physH, gameTarget.format, "game-post"))
                : graph.import_target("game-filtered", filterTarget.color.id,
                                      import_desc(physW, physH, filterTarget.format, "game-filtered"));
        // The colour filter works on what the screen shows, the interface included: with the interface over the picture it is a pass of
        // its own after it, else it is part of each final pass.
        const int filter =
            hud || ctx.hudOut ? 0 : pp.colorFilter;  // with hudOut the filter runs after the items, at the output size
        finishRes = dest;
        finishTarget = hud ? &hudTarget : &filterTarget;
        // The rectangles of the cameras with a final pass. When they tile the picture every pixel is written by one of them; else a first
        // pass with the plan of an empty stack (the encode of a linear scene, a copy of a gamma one, the colour filter) fills the picture and
        // the cameras draw over it. A camera without a stack that draws over one with a stack gets that plain pass over its own rectangle
        // too (the stack of the camera below must not reach its pixels).
        struct Rc {
            int x0, y0, x1, y1;
        };
        auto rect_of = [&](const PostPlan& p) {
            return p.rect.whole(physW, physH) ? Rc{0, 0, physW, physH}
                                              : Rc{p.rect.x, p.rect.y, p.rect.x + p.rect.w, p.rect.y + p.rect.h};
        };
        auto overlap = [](const Rc& a, const Rc& b) {
            return a.x0 < b.x1 && b.x0 < a.x1 && a.y0 < b.y1 && b.y0 < a.y1;
        };
        std::vector<Rc> stacked;
        std::int64_t area = 0;
        bool disjoint = true;
        for (const DrawContext* c : postCams) {
            if (!c->postPlan.final_pass()) continue;
            const Rc r = rect_of(c->postPlan);
            for (const Rc& o : stacked) disjoint = disjoint && !overlap(r, o);
            stacked.push_back(r);
            area += std::int64_t(r.x1 - r.x0) * std::int64_t(r.y1 - r.y0);
        }
        // Not needed when the first camera has a stack and covers the whole picture: its pass draws every pixel.
        const bool firstCoversAll =
            postCams.front()->postPlan.final_pass() && postCams.front()->postPlan.rect.whole(physW, physH);
        const bool needBase = !firstCoversAll && !(disjoint && area == std::int64_t(physW) * std::int64_t(physH));
        PostPlan basePlan;
        basePlan.sceneLinear = pp.sceneLinear;
        basePlan.linear = pp.sceneLinear;
        basePlan.colorFilter = pp.colorFilter;
        bool first =
            true;  // the first pass that writes the destination draws every pixel it covers; the others keep what the passes before them drew
        // The picture between two pieces of a final pass cut by custom passes: the game target (mid -1) or one of the
        // images of ldrMid.
        struct Where {
            ResourceId res;
            int mid = -1;
        };
        ResourceId midRes[2];
        bool anyLdr = false;
        for (const DrawContext* c : postCams) anyLdr = anyLdr || c->postPlan.customLdr;
        if (anyLdr)
            for (int i = 0; i < 2; ++i)
                if (ldrMid[i].valid())
                    midRes[i] = graph.import_target(i == 0 ? "post-mid-0" : "post-mid-1", ldrMid[i].colorAtt.id,
                                                    import_desc(physW, physH, ldrMid[i].format, "post-mid"));
        // One piece of a camera's final pass (all of it when no custom pass cuts it): the stages of `slice` over the
        // camera's rectangle, from `from` into the image `toMid` of ldrMid or, -1, into the destination.
        auto piece = [&](const std::string& job, const std::string& name, const PostPlan& use, AutoExposure* exposure,
                         ResourceId evRes, const PostRect& rect, const PostSlice& slice, const Where& from,
                         int toMid) -> Where {
            const bool autoExp = evRes.valid() && slice.has(kStageScene);
            const bool toDest = toMid < 0;
            const bool outline = use.fx.outline && slice.has(kStageOutline);
            std::vector<ResourceId> reads{from.res};
            if (autoExp) reads.push_back(evRes);
            if (outline) reads.push_back(use.outline_source().res);
            if (toDest && !first) reads.push_back(dest);
            const bool load = toDest && !first;
            if (toDest) first = false;
            add_job(job, name, std::move(reads), {toDest ? dest : midRes[toMid]},
                    [this, use, autoExp, exposure, outline_view, filter, rect, load, hud, slice, outline,
                     fromMid = from.mid, toMid](const PassContext& c) {
                        PostPlan drawn;
                        sg_view aux{};
                        if (outline)
                            aux = outline_view(use, c, drawn);
                        else
                            drawn = use;
                        const sg_view src = fromMid < 0 ? gameTarget.texView : ldrMid[fromMid].texView;
                        const bool lastPiece = toMid < 0;
                        Target& out = lastPiece ? (hud ? hudTarget : filterTarget) : ldrMid[toMid];
                        post_pass(drawn, true, filter, autoExp, src,
                                  autoExp ? exposure->ev_view() : assets->white()->view, aux, out, "post",
                                  lastPiece && hud, rect, load, slice);
                        if (!lastPiece) return;
                        if (hud)
                            hudActive = true;
                        else
                            filterActive = true;
                        finalEncoded = true;
                    });
            return Where{toDest ? dest : midRes[toMid], toMid};
        };
        // The custom passes of the display-referred places in `slots`, on the picture `at` (where the pieces before
        // them left it).
        auto custom_here = [&](const DrawContext* c, std::uint32_t slots, const Where& at) {
            if (slots == 0) return;
            const bool onMid = at.mid >= 0;
            const Target& pic = onMid ? ldrMid[at.mid] : gameTarget;
            const BloomTarget to = onMid ? BloomTarget{pic.colorAtt, sg_view{}, 1} : game_dst();
            customPost.add_passes(graph, transient_targets(), gpu, sceneFx, c->postPlan.custom, slots, c->postPlan.rect,
                                  physW, physH, at.res, pic.texView, to, onMid ? pic.format.color : gpu.scene_format(),
                                  c->postPlan.prepass, false, fr.time, &stats.drawCalls, stats.materialFallbacks,
                                  c->plan.name);
        };
        auto declare = [&](const DrawContext* c, const std::string& job, const char* name, const PostPlan& use,
                           AutoExposure* exposure, ResourceId evRes, const PostRect& rect) {
            Where cur{game, -1};
            if (use.customLdr) {
                // Cut the final pass after every stage that has a custom pass at its place and something to do before
                // it, and at no other: places with nothing drawn between them share one cut, and a custom pass before
                // any stage that does something works on the picture as it is.
                const std::uint32_t cuts = use.ldr_cuts();
                std::uint32_t pending = 0;  // the places whose passes run before the next piece
                int from = kStageScene, part = 0;
                for (int i = kStageScene; i < kStageTail; ++i) {
                    const PostSlot slot = PostSlot(int(PostSlot::AfterTonemap) + i);
                    if (!use.custom.any_in(slot)) continue;
                    if ((cuts >> i) & 1u) {
                        custom_here(c, pending, cur);
                        pending = 0;
                        cur = piece(job, "post-part" + std::to_string(part++), use, exposure, evRes, rect,
                                    PostSlice{from, i}, cur, cur.mid == 0 ? 1 : 0);
                        from = i + 1;
                    }
                    pending |= 1u << int(slot);
                }
                custom_here(c, pending, cur);
                piece(job, name, use, exposure, evRes, rect, PostSlice{from, kStageTail}, cur, -1);
                return;
            }
            piece(job, name, use, exposure, evRes, rect, PostSlice{}, cur, -1);
        };
        if (needBase) declare(nullptr, plan.name, "post-base", basePlan, nullptr, ResourceId{}, PostRect{});
        for (std::size_t i = 0; i < postCams.size(); ++i) {
            DrawContext* c = postCams[i];
            const PostPlan& cp = c->postPlan;
            if (cp.final_pass()) {
                ResourceId evRes;
                AutoExposure* exposure = nullptr;
                if (cp.autoExposure) {
                    ExposureSlot& slot = autoExposures[c->fr.cam.entity.bits()];
                    if (!slot.exposure) slot.exposure = std::make_unique<AutoExposure>();
                    slot.frame = postSerial;
                    exposure = slot.exposure.get();
                    evRes = exposure->add_passes(graph, transient_targets(), gpu, cp, game, gameTarget.texView, fr.dt,
                                                 postSerial, &stats.drawCalls, c->plan.name, physW, physH);
                }
                declare(c, c->plan.name, "post", cp, exposure, evRes, cp.rect);
                continue;
            }
            // No stack: the plain pass, only where a stack drawn before it reaches its pixels.
            bool covered = false;
            const Rc mine = rect_of(cp);
            for (std::size_t j = 0; j < i && !covered; ++j)
                covered = postCams[j]->postPlan.final_pass() && overlap(mine, rect_of(postCams[j]->postPlan));
            if (covered) declare(c, c->plan.name, "post", basePlan, nullptr, ResourceId{}, cp.rect);
        }
        if (hud) {
            // The picture went into hudTarget (its multisampled image kept), the screen-space items are drawn over it, and the colour
            // filter (it works on what the screen shows, the items included) copies it into filterTarget.
            std::vector<ResourceId> hudReads{dest};
            hudReads.insert(hudReads.end(), shown.begin(), shown.end());
            add("hud-over-post", std::move(hudReads), {dest},
                [this, &ctx](const PassContext&) { hud_pass(ctx, hudTarget, "game-post-hud"); });
            if (pp.colorFilter != 0 && ensure_filter_target()) {
                const ResourceId filtered =
                    graph.import_target("game-filtered", filterTarget.color.id,
                                        import_desc(physW, physH, filterTarget.format, "game-filtered"));
                add("color-filter", {dest}, {filtered}, [this, pp](const PassContext&) {
                    post_pass(pp, false, pp.colorFilter, false, hudTarget.texView, assets->white()->view, sg_view{},
                              filterTarget, "color-filter", false);
                    filterActive = true;
                });
                finishRes = filtered;
                finishTarget = &filterTarget;
            }
        }
    } else if (pp.colorFilter != 0 && !ctx.hudOut && ensure_filter_target()) {
        // Only the colour filter (PostProcess.colorFilterEnabled / colorFilterMode): a copy of the game target through the filter.
        const ResourceId filtered = graph.import_target(
            "game-filtered", filterTarget.color.id, import_desc(physW, physH, filterTarget.format, "game-filtered"));
        add("color-filter", {game}, {filtered}, [this, pp](const PassContext&) {
            post_pass(pp, false, pp.colorFilter, false, gameTarget.texView, assets->white()->view, sg_view{},
                      filterTarget, "color-filter", false);
            filterActive = true;
        });
        finishRes = filtered;
        finishTarget = &filterTarget;
    }
    finish_output(finishRes, finishTarget, &pp);
}

}  // namespace fa
