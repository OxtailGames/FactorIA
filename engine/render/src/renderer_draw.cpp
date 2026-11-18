// Renderer::Impl, part 3: draw_view_job and draw_job, the passes of one frame's jobs.
#include "color_space.h"
#include "renderer_impl.h"

#include <iterator>

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
};

// The packed params and textures of a custom material for one batch (its overrides are the same for every item).
struct Renderer::Impl::MaterialInputs {
    float params[kMaxMaterialParams][4];
    TextureAsset* textures[kMaxMaterialTextures]{};
};

// Holds references to the job's world and frame and a copy of its plan. It lives (Impl::jobContexts) from plan_job until the
// frame graph has run, because the callbacks of the job's passes use it; the world, the frame and the camera `plan.post`
// points to belong to the caller of plan_job, which keeps them until run_frame_graph().
struct Renderer::Impl::DrawContext {
    DrawContext(World& w, Frame& f, const JobPlan& p) : world(w), fr(f), plan(p), post(*p.post) {}
    World& world;
    Frame& fr;
    const JobPlan plan;
    const CameraInfo& post;
    JobEnv env;  // the sizes and images the job's passes draw with (a view job's are not the game target's)
    // plan_job: the viewports and clears of this job
    // hudAfterBloom: the screen-space items are drawn over the glowing game target (Camera.bloomScreenSpace false, no final pass).
    // hudAfterPost: the final passes of the frame write hudTarget and the screen-space items are drawn over it, in display space.
    bool hudAfterBloom = false, hudAfterPost = false, msaa = false, z01 = false;
    PostPlan
        postPlan;  // the post-processing stack of this job's camera (empty for the screen-only job and the view jobs)
    // Does this job begin the main pass? The screen-space job of a frame whose HUD goes over the bloom draws it after instead.
    bool doMainPass = false;
    Px fullPx, camPx;
    bool partial = false, clearByQuad = false, clearByLoad = false;
    // gather_meshes, collect_lights, shadow_bounds, cull_and_batch
    std::vector<MeshItem> opaque, blended;
    std::vector<LightData> lights;
    int shadowLight = -1;
    Vec3 lightDirForShadow{0, -1, 0};
    bool haveShadowCaster = false;
    Mat4 lightVP;
    bool doShadows = false;
    // plan_prepass: this job declares the prepass (its image is a transient of the graph, PostPlan::prepass) and, with a debug view on,
    // the pass that paints it over the game image.
    bool doPrepass = false, debugPrepass = false;
    // plan_outline: this job declares the sprite-coverage pass (PostPlan::coverage) for a sprite outline.
    bool doCoverage = false;
    std::vector<MeshBatch> opaqueBatches, blendedBatches;
    std::vector<Mat4> mainMats, shadowMats;
    // build_quad_stream
    struct Group {
        std::vector<QuadBatch> batches;
    };
    Group gClear, gWorld, gDebugWorld, gScreen, gDebugScreen;
    std::size_t lineFirst = 0;
    sg_buffer vbuf{};
    Mat4 screenProj;
    // upload_instances
    sg_buffer mainInst{}, shadowInst{};
    // scene_uniforms
    SceneSettings ss;
    TextureAsset* white = nullptr;
    mesh_fa_lights_t lightUniforms{};
    mesh_fa_mesh_vs_params_t vuScene{};
    mesh_fa_mesh_fs_params_t fuScene{};
    // light_pass
    int litMode = 0;
    sg_view shadowRowsTex{};
};

namespace {

void copy_mat(float* dst, const Mat4& m) { std::memcpy(dst, m.m, sizeof(float) * 16); }

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
void Renderer::Impl::begin_frame_graph() {
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
    ++frameSerial;
    trim_shadow_rows();
    sharedGame = sharedLight = sharedShadow = ResourceId{};
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
        postCams.push_back(&ctx);
        // The camera's view-projection of the frame before, for the effects that reproject (motion blur); one entry per camera, and the
        // cameras that were not drawn last frame are forgotten.
        const std::uint64_t camKey = fr.cam.entity.bits();
        const auto prev = prevViewProj.find(camKey);
        if (prev != prevViewProj.end() && prev->second.frame + 1 == frameSerial) {
            pp.prevViewProj = prev->second.viewProj;
            pp.prevValid = true;
        }
        PrevCamera& now = prevViewProj[camKey];
        now.viewProj = fr.cam.viewProj;
        now.frame = frameSerial;
        for (auto it = prevViewProj.begin(); it != prevViewProj.end();)
            it = it->second.frame + 1 < frameSerial ? prevViewProj.erase(it) : std::next(it);
        // Depth of field and motion blur (renderer_dof.h): the focus of this camera for the frame, the matrices of its movement.
        if (fr.cam.postStack)
            pp.sceneFx = sceneFx.plan(world, fr.cam, *fr.cam.postStack, camKey, frameSerial, fr.dt, renderScale,
                                      pp.prevViewProj, pp.prevValid);
        // The program is made only for a frame that runs it (a conversion or a colour filter): a game without a stack never compiles it.
        if ((pp.final_pass() || pp.colorFilter != 0) &&
            !gpu.post_ready()) {  // logged once; the frame is drawn without the final pass
            pp.exposure = pp.tonemap = pp.linear = false;
            pp.fx = PostFx{};
            pp.colorFilter = 0;
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
                pp.linear = pp.linear && (pp.exposure || pp.tonemap || pp.colorFilter != 0 || pp.fx.any());
            }
        }
    }

    gather_meshes(ctx);
    collect_lights(ctx);
    shadow_bounds(ctx);
    cull_and_batch(ctx);
    plan_prepass(ctx);
    plan_outline(ctx);
    // Depth of field and motion blur work on the scene colour, so the screen-space items are drawn after them (as they are over the bloom).
    if (plan.last && !plan.view) {
        bool sceneFxDrawn = false;
        for (const DrawContext* c : postCams)
            sceneFxDrawn = sceneFxDrawn || (c->postPlan.sceneFx.any() && c->doPrepass);
        if (sceneFxDrawn) {
            ctx.hudAfterBloom = true;
            ctx.doMainPass = fr.wantWorld || !ctx.hudAfterBloom;
        }
    }
    build_quad_stream(ctx);
    // The final pass converts the picture (exposure, tonemap, the encode of a linear scene): the screen-space items go over its result, in
    // display space, and are drawn after it instead of in the main pass. Only when there is something to draw, and the image for it exists.
    bool frameFinal = false;  // some camera of the frame runs a final pass
    for (const DrawContext* c : postCams) frameFinal = frameFinal || c->postPlan.final_pass();
    if (plan.last && !plan.view && frameFinal && fr.wantScreen &&
        (!ctx.gScreen.batches.empty() || !ctx.gDebugScreen.batches.empty()) && ensure_hud_target()) {
        ctx.hudAfterPost = true;
        ctx.hudAfterBloom =
            false;  // the glow goes into the resolved image: the multisampled one is not drawn over again
        ctx.doMainPass = fr.wantWorld;
    }
    upload_instances(ctx);
    scene_uniforms(ctx);
    light_plan(ctx);
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
    if (!renderScene.built() || renderScene.scope() != fr.scopeRoot)
        renderScene.build(world, *assets, fr.scopeRoot, false);
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
        if (sm.hasLods || sm.liveTextures) special.emplace_back(meshes.size(), &sm);
        MeshItem& mi = meshes.emplace_back();
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
        mi.colorsHash = sm.colorsHash;
        mi.sortKey = sm.sortKey;
        mi.keyed = sm.keyed;
        mi.dist = length(sm.model.translation() - fr.cam.position);
        meshBlended.push_back(sm.blended ? 1 : 0);
    }
    for (const auto& [i, sm] : special) {
        MeshItem& mi = meshes[i];
        const MeshRenderer& mr = *mi.mr;
        if (sm->liveTextures) {  // "target:<name>": the image depends on the job (a camera's own target is the checker)
            mi.tex = mr.texture.empty() ? nullptr : assets->texture(mr.texture);
            mi.normalTex = mr.normalMap.empty() ? nullptr : assets->texture(mr.normalMap);
        }
        if (!sm->hasLods) continue;
        const std::string& level = lod_mesh(mr, mi.dist);  // MeshRenderer::lods
        if (level == mr.mesh) continue;
        mi.mesh = assets->mesh(level);
        mesh_cull_bounds(*mi.mesh, world.get<Animator>(mi.entity), mi.bmin, mi.bmax, mi.anim);
        meshBlended[i] = mesh_is_blended(mr, *mi.mesh, mi.material) ? 1 : 0;
    }
    for (const auto& entry : special) {  // what the camera changed is ranked again; a value the table lacks: comparator
        MeshItem& mi = meshes[entry.first];
        mi.keyed = mi.keyed && renderScene.sort_table().key_of(fields_of(mi), mi.sortKey);
    }
    const rjobs::Split meshSplit = rjobs::split(meshes.size(), kMeshGrain, kParallelMeshes);
    rjobs::run("render.mesh_frustum", meshSplit, [&](const jobs::Chunk& c) {
        for (std::size_t i = c.begin; i < c.end; ++i) {
            MeshItem& mi = meshes[i];
            mi.visible = box_in_frustum(fr.cam.viewProj, z01, mi.bmin, mi.bmax, mi.model);
        }
    });
    for (std::size_t i = 0; i < meshes.size(); ++i) (meshBlended[i] ? blended : opaque).push_back(meshes[i]);
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
                }
            } else {
                Vec3 d = normalize(m.transform_dir(kForward));
                ld.pos = Vec4{m.translation(), l.range};
                ld.color = Vec4{col, l.type == LightType::Point ? 1.0f : 2.0f};
                ld.dir = Vec4{d, std::cos(radians(l.spotAngle))};
                // Relevance to the camera: bright and close first (the light's own range scales the fall-off).
                const float r2 = std::max(l.range * l.range, 1e-4f);
                ld.score = brightness * r2 / (r2 + length_sq(m.translation() - fr.cam.position));
            }
            lights.push_back(ld);
        });
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
    stats.lightsDropped += select_lights(lights, size_t(kMaxLights));
    stats.lights += int(lights.size());
    ctx.haveShadowCaster = shadowLight >= 0 && !lights.empty() && lights[0].rank == 0;
    if (!opaque.empty() && lights.empty() && !warnedNoLight && !plan.view) {
        warnedNoLight = true;
        FA_WARN("render", "the scene has MeshRenderer entities but no Light entity: meshes only receive ambient light "
                          "(SceneSettings.ambientLight). Add an entity with a Light component (type Directional) or "
                          "set MeshRenderer.unlit.");
    }
}

// ---- shadow bounds ----
// Reads: ctx.haveShadowCaster, ctx.lightDirForShadow, ctx.opaque / ctx.blended (castShadows, mesh part boxes, matrices), gpu
// (shadows_supported, depth range). Writes: ctx.lightVP, ctx.doShadows; creates the shadow targets.
void Renderer::Impl::shadow_bounds(DrawContext& ctx) {
    const bool haveShadowCaster = ctx.haveShadowCaster;
    auto& opaque = ctx.opaque;
    auto& blended = ctx.blended;
    auto& lightDirForShadow = ctx.lightDirForShadow;
    auto& lightVP = ctx.lightVP;
    auto& doShadows = ctx.doShadows;
    if (haveShadowCaster) {
        // The world box of each caster's parts as jobs, joined here in the order of the items.
        Vec3 bmin{1e30f, 1e30f, 1e30f}, bmax{-1e30f, -1e30f, -1e30f};
        bool any = false;
        for (auto* list : {&opaque, &blended}) {
            struct Box {
                Vec3 lo{1e30f, 1e30f, 1e30f}, hi{-1e30f, -1e30f, -1e30f};
                bool any = false;
            };
            std::vector<Box> boxes(list->size());
            rjobs::run("render.shadow_bounds", rjobs::split(list->size(), kMeshGrain, kParallelMeshes),
                       [&](const jobs::Chunk& ch) {
                           for (std::size_t i = ch.begin; i < ch.end; ++i) {
                               const MeshItem& mi = (*list)[i];
                               if (!mi.mr->castShadows) continue;
                               Box& b = boxes[i];
                               for (auto& p : mi.mesh->parts) {
                                   for (int c = 0; c < 8; ++c) {
                                       Vec3 corner{(c & 1) ? p.bmax.x : p.bmin.x, (c & 2) ? p.bmax.y : p.bmin.y,
                                                   (c & 4) ? p.bmax.z : p.bmin.z};
                                       Vec3 w = mi.model.transform_point(corner);
                                       b.lo = min(b.lo, w);
                                       b.hi = max(b.hi, w);
                                       b.any = true;
                                   }
                               }
                           }
                       });
            for (const Box& b : boxes) {
                if (!b.any) continue;
                bmin = min(bmin, b.lo);
                bmax = max(bmax, b.hi);
                any = true;
            }
        }
        if (any && create_shadow_targets()) {
            Vec3 center = (bmin + bmax) * 0.5f;
            float radius = std::max(0.5f, length(bmax - bmin) * 0.5f);
            Vec3 up = std::fabs(lightDirForShadow.y) > 0.99f ? Vec3{0, 0, 1} : Vec3{0, 1, 0};
            Mat4 lv = Mat4::look_at(center - lightDirForShadow * (radius * 2.0f), center, up);
            Mat4 lp = Mat4::ortho(-radius, radius, -radius, radius, 0.1f, radius * 4.0f, gpu.depth_zero_to_one());
            lightVP = lp * lv;
            doShadows = true;
        }
    }
}

// ---- cull, then group into instanced batches ----
// Reads: ctx.doShadows, ctx.lightVP, ctx.z01, items' visible flags. Writes: ctx.opaque / ctx.blended (culled), item `casts`,
// ctx.opaqueBatches / ctx.blendedBatches, ctx.mainMats / ctx.shadowMats (instance matrices), stats.meshesCulled / shadowCasters.
void Renderer::Impl::cull_and_batch(DrawContext& ctx) {
    const bool z01 = ctx.z01;
    auto& opaque = ctx.opaque;
    auto& blended = ctx.blended;
    auto& lightVP = ctx.lightVP;
    auto& doShadows = ctx.doShadows;
    auto& opaqueBatches = ctx.opaqueBatches;
    auto& blendedBatches = ctx.blendedBatches;
    auto& mainMats = ctx.mainMats;
    auto& shadowMats = ctx.shadowMats;
    for (auto* list : {&opaque, &blended}) {
        if (doShadows)
            rjobs::run("render.shadow_cull", rjobs::split(list->size(), kMeshGrain, kParallelMeshes),
                       [&](const jobs::Chunk& ch) {
                           for (std::size_t i = ch.begin; i < ch.end; ++i) {
                               MeshItem& mi = (*list)[i];
                               mi.casts =
                                   mi.mr->castShadows && box_in_frustum(lightVP, z01, mi.bmin, mi.bmax, mi.model);
                           }
                       });
        for (auto& mi : *list) {
            if (!mi.visible) ++stats.meshesCulled;
            if (!doShadows) mi.casts = false;
            if (mi.casts) ++stats.shadowCasters;
        }
        list->erase(
            std::remove_if(list->begin(), list->end(), [](const MeshItem& m) { return !m.visible && !m.casts; }),
            list->end());
    }
    build_batches(opaque, true, opaqueBatches, mainMats, shadowMats);
    build_batches(blended, false, blendedBatches, mainMats, shadowMats);
}

// ---- flatten quads into one vertex stream ----
// Reads: fr (world, debugWorld, screen, debugScreen quad lists, debugLines, camera clear colour), ctx.clearByQuad, targetW/H.
// Writes: `stream`, ctx.gClear / gWorld / gDebugWorld / gScreen / gDebugScreen, ctx.lineFirst, ctx.vbuf (transient buffer),
// ctx.screenProj.
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
    if (clearByQuad) {
        // The camera's clear colour over its viewport: one opaque quad over the unit square, which the viewport maps to the
        // camera's rectangle (see main_pass).
        QuadList clearList;
        clearList.begin_item(0, 0, assets->white(), SamplerKind::Nearest);
        clearList.set_opaque();
        QuadEmitter em{clearList, Mat4::identity(), false, pack_color(fr.cam.clearColor), kModeTextured, 0};
        em.rect(0, 0, 1, 1, 0, 0, 1, 1);
        clearList.end_item();
        clearList.flatten(stream, gClear.batches);
    }
    fr.world.flatten(stream, gWorld.batches);
    fr.debugWorld.flatten(stream, gDebugWorld.batches);
    fr.screen.flatten(stream, gScreen.batches);
    fr.debugScreen.flatten(stream, gDebugScreen.batches);
    lineFirst = stream.size();
    stream.insert(stream.end(), fr.debugLines.begin(), fr.debugLines.end());

    if (!stream.empty()) {
        vbuf = gpu.acquire_transient(stream.size() * sizeof(Vertex2D));
        sg_write_buffer_desc wd{};
        wd.src.data = {stream.data(), stream.size() * sizeof(Vertex2D)};
        wd.dst.buffer = vbuf;
        sg_write_buffer_transient(&wd);
    }

    ctx.screenProj = Mat4::ortho(0, float(targetW), float(targetH), 0, -1000.0f, 1000.0f, z01);
}

// ---- instance data: one model matrix per drawn mesh, written before any pass binds the buffers ----
// Reads: ctx.mainMats, ctx.shadowMats. Writes: ctx.mainInst, ctx.shadowInst (transient GPU buffers).
void Renderer::Impl::upload_instances(DrawContext& ctx) {
    static_assert(sizeof(Mat4) == kMeshInstanceBytes, "an instance is one Mat4");
    auto upload = [&](const std::vector<Mat4>& mats) {
        if (mats.empty()) return sg_buffer{};
        const std::size_t bytes = mats.size() * kMeshInstanceBytes;
        sg_buffer buf = gpu.acquire_transient(bytes);
        sg_write_buffer_desc wd{};
        wd.src.data = {mats.data(), bytes};
        wd.dst.buffer = buf;
        sg_write_buffer_transient(&wd);
        return buf;
    };
    ctx.mainInst = upload(ctx.mainMats);
    ctx.shadowInst = upload(ctx.shadowMats);
}

// ---- the scene's uniforms: shared by the main pass and the shadow pass of alphaMode "clip" materials ----
// Reads: world (settings, time), fr.cam, ctx.lights, ctx.lightVP, gpu. Writes: ctx.ss, ctx.white, ctx.lightUniforms, ctx.vuScene,
// ctx.fuScene.
void Renderer::Impl::scene_uniforms(DrawContext& ctx) {
    World& world = ctx.world;
    Frame& fr = ctx.fr;
    const std::vector<LightData>& lights = ctx.lights;
    const Mat4& lightVP = ctx.lightVP;
    SceneSettings& ss = ctx.ss;
    mesh_fa_lights_t& lightUniforms = ctx.lightUniforms;
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
    // Colours the author picked are sRGB values; a linear scene computes with linear light (sky, fog and ambient, below, and the
    // main pass's sky and clear colour read these).
    ss.ambientLight = to_scene(ss.ambientLight, fr.linear);
    ss.fogColor = to_scene(ss.fogColor, fr.linear);
    ss.skyColor = to_scene(ss.skyColor, fr.linear);
    ss.horizonColor = to_scene(ss.horizonColor, fr.linear);
    ctx.white = assets->white();
    for (std::size_t i = 0; i < lights.size(); ++i) {
        for (int c = 0; c < 4; ++c) {
            lightUniforms.fa_light_pos[i][c] = lights[i].pos[c];
            lightUniforms.fa_light_color[i][c] = lights[i].color[c];
            lightUniforms.fa_light_dir[i][c] = lights[i].dir[c];
        }
    }
    copy_mat(vuScene.fa_view_proj, fr.cam.viewProj);
    copy_mat(vuScene.fa_light_vp, lightVP);
    vuScene.fa_time[0] = float(world.time());
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
    fuScene.fa_counts[0] = float(lights.size());
    fuScene.fa_counts[1] = 1.0f / float(kShadowSize);
    fuScene.fa_counts[2] = gpu.is_gl() ? 1.0f : 0.0f;
    fuScene.fa_env_sky[0] = ss.skyColor.r;
    fuScene.fa_env_sky[1] = ss.skyColor.g;
    fuScene.fa_env_sky[2] = ss.skyColor.b;
    fuScene.fa_env_horizon[0] = ss.horizonColor.r;
    fuScene.fa_env_horizon[1] = ss.horizonColor.g;
    fuScene.fa_env_horizon[2] = ss.horizonColor.b;
    fuScene.fa_pbr[3] = 0.0015f;
    fuScene.fa_time[0] = float(world.time());
}

// What one part of an item is drawn with (reads ctx.white).
Renderer::Impl::PartDraw Renderer::Impl::part_draw(DrawContext& ctx, const MeshItem& mi, const SubMesh& part) {
    TextureAsset* white = ctx.white;
    PartDraw d;
    d.error = mi.material && !mi.material->ok;
    d.mat = mi.material && mi.material->ok ? mi.material : nullptr;
    d.tex = d.error ? white : mi.tex ? mi.tex : (part.texture ? part.texture : white);
    d.normal = d.error ? nullptr : (mi.normalTex ? mi.normalTex : part.normalTex);
    d.mr = d.error || !part.mrTex ? white : part.mrTex;
    d.occlusion = d.error || !part.occlusionTex ? white : part.occlusionTex;
    d.emissive = d.error || !part.emissiveTex ? white : part.emissiveTex;
    return d;
}

// The fragment parameters (fa_mesh_fs_params) of one part (reads ctx.fuScene, ctx.doShadows).
mesh_fa_mesh_fs_params_t Renderer::Impl::fill_fs(DrawContext& ctx, const MeshItem& mi, const SubMesh& part,
                                                 const PartDraw& d) {
    const mesh_fa_mesh_fs_params_t& fuScene = ctx.fuScene;
    const bool doShadows = ctx.doShadows;
    const MeshRenderer& mr = *mi.mr;
    mesh_fa_mesh_fs_params_t fu = fuScene;
    const bool unlit = mr.unlit || d.error || (d.mat && d.mat->lighting == "unlit");
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

void Renderer::Impl::material_inputs(const MeshItem& mi, MaterialAsset* mat, MaterialInputs& in) {
    pack_material_params(*mat, mi.mr->materialParams, in.params);
    for (std::size_t i = 0; i < mat->textures.size(); ++i)
        in.textures[i] = material_texture(*mat, int(i), mi.mr->materialParams, *assets);
}

// Bindings of a custom program: the engine's textures and the material's, only the slots the program declares (sokol
// rejects a binding the shader does not have). `shadowPass`: the shadow map is being drawn, so it is not sampled.
void Renderer::Impl::bind_textures(DrawContext& ctx, sg_bindings& b, const PartDraw& d, const MaterialProgram* prog,
                                   const MaterialInputs& in, bool shadowPass) {
    TextureAsset* white = ctx.white;
    const bool doShadows = ctx.doShadows;
    b.views[VIEW_mesh_fa_tex] = d.tex->gpu_view();
    b.views[VIEW_mesh_fa_shadow_tex] = (doShadows && !shadowPass) ? shadowTarget.texView : white->view;
    b.views[VIEW_mesh_fa_normal_tex] = (d.normal ? d.normal : white)->gpu_view();
    b.views[VIEW_mesh_fa_mr_tex] = d.mr->gpu_view();
    b.views[VIEW_mesh_fa_occlusion_tex] = d.occlusion->gpu_view();
    b.views[VIEW_mesh_fa_emissive_tex] = d.emissive->gpu_view();
    b.samplers[SMP_mesh_fa_smp] = gpu.sampler(SamplerKind::LinearRepeat);
    b.samplers[SMP_mesh_fa_shadow_smp] = gpu.sampler(SamplerKind::Nearest);
    if (!prog) return;
    if (d.mat)
        for (std::size_t i = 0; i < d.mat->textures.size(); ++i) {
            b.views[kMaterialFirstView + int(i)] = in.textures[i]->gpu_view();
            b.samplers[kMaterialFirstSampler + int(i)] = gpu.sampler(d.mat->textures[i].sampler);
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
    bool anyFlatLit = false;
    for (const QuadBatch& qb : gWorld.batches) anyFlatLit = anyFlatLit || (qb.lit && !qb.normal);
    int points = 0;
    for (const Light2DData& l : fr.lights2d) points += l.pos[3] >= 0.0f ? 1 : 0;
    shadowRowsTex = upload_shadow_rows(fr);
    float lightScale = ss.lightScale;
    lightScale = std::isfinite(lightScale) ? std::clamp(lightScale, 0.25f, 1.0f) : 1.0f;
    if (anyFlatLit && !fr.cam.perspective && gpu.light_format() != SG_PIXELFORMAT_NONE) {
        if (points == 0)
            litMode = 2;
        else if (!plan.view && gpu.light_ready() && ensure_light_target(lightScale))
            litMode = 1;  // the buffer is the game target's size
    }
}

// The light buffer's pass (light_plan chose litMode 1): every point light of the camera is a quad added into the buffer.
// Reads: fr (lights2d, shadowRows, camera, viewport), ctx.partial, ctx.shadowRowsTex, lightW / lightH, the light target.
// Writes: the light target; stats.drawCalls.
void Renderer::Impl::light_pass(DrawContext& ctx) {
    Frame& fr = ctx.fr;
    const bool partial = ctx.partial;
    const sg_view shadowRowsTex = ctx.shadowRowsTex;
    int points = 0;
    for (const Light2DData& l : fr.lights2d) points += l.pos[3] >= 0.0f ? 1 : 0;
    std::vector<LightVertex> lv;
    lv.reserve(std::size_t(points) * 4);
    static const float kCorner[4][2] = {{-1, -1}, {1, -1}, {1, 1}, {-1, 1}};
    for (const Light2DData& l : fr.lights2d) {
        if (l.pos[3] < 0.0f) continue;
        for (const auto& c : kCorner) {
            LightVertex v{};
            v.corner[0] = c[0];
            v.corner[1] = c[1];
            std::memcpy(v.pos, l.pos, sizeof(float) * 4);
            std::memcpy(v.color, l.color, sizeof(float) * 4);
            v.shadow[0] = l.extra[0] >= 0.0f && fr.shadowRows > 0 ? (l.extra[0] + 0.5f) / float(fr.shadowRows) : -1.0f;
            lv.push_back(v);
        }
    }
    static_assert(kMaxLights2D <= kMaxQuadsPerDraw, "every light of a frame is drawn by one draw call");
    sg_buffer lb = gpu.acquire_transient(lv.size() * sizeof(LightVertex));
    sg_write_buffer_desc wd{};
    wd.src.data = {lv.data(), lv.size() * sizeof(LightVertex)};
    wd.dst.buffer = lb;
    sg_write_buffer_transient(&wd);

    PassDesc lp = pass_into(lightTarget, "light-buffer");
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
    b.samplers[SMP_light_shadow_smp] = gpu.sampler(SamplerKind::Nearest);
    sg_apply_bindings(&b);
    light_light_vs_params_t vu{};
    copy_mat(vu.view_proj, fr.cam.viewProj);
    apply_uniforms(UB_light_light_vs_params, vu);
    light_light_fs_params_t fu{};
    fu.range[0] = 1.0f / gpu.light_range();
    apply_uniforms(UB_light_light_fs_params, fu);
    sg_draw(0, int(lv.size() / 4) * 6, 1);
    gpu.end_pass();
    ++stats.drawCalls;
}

// ---- shadow pass ----
// Meshes cast with the engine's depth-only programs, except materials with their own shadow programs (vertex() moves the
// shadow, alphaMode "clip" cuts holes into it).
// Reads: ctx.doShadows, ctx.opaque / ctx.blended and their batches, ctx.shadowInst, ctx.vuScene, ctx.lightUniforms,
// ctx.white and ctx.fuScene (part_draw, bind_textures, fill_fs), the shadow targets.
// Writes: the shadow map (shadowTarget); stats.drawCalls.
void Renderer::Impl::shadow_pass(DrawContext& ctx) {
    const std::vector<MeshBatch>& opaqueBatches = ctx.opaqueBatches;
    const std::vector<MeshBatch>& blendedBatches = ctx.blendedBatches;
    const std::vector<MeshItem>& opaque = ctx.opaque;
    const std::vector<MeshItem>& blended = ctx.blended;
    const sg_buffer shadowInst = ctx.shadowInst;
    const mesh_fa_mesh_vs_params_t& vuScene = ctx.vuScene;
    const mesh_fa_lights_t& lightUniforms = ctx.lightUniforms;
    PassDesc sp = pass_into(shadowTarget, "shadow");
    sp.colorLoad = SG_LOADACTION_CLEAR;
    sp.clearColor = {1, 1, 1, 1};
    sp.colorStore = SG_STOREACTION_STORE;
    sp.depthLoad = SG_LOADACTION_CLEAR;
    sp.clearDepth = 1.0f;
    gpu.begin_pass(sp);
    mesh_fa_mesh_vs_params_t u = vuScene;  // the shadow programs read fa_light_vp (fa_view_proj is unused)
    for (int pass = 0; pass < 2; ++pass) {
        const std::vector<MeshBatch>& batches = pass == 0 ? opaqueBatches : blendedBatches;
        const std::vector<MeshItem>& items = pass == 0 ? opaque : blended;
        for (const MeshBatch& batch : batches) {
            if (batch.shadowCount == 0) continue;
            const MeshItem& rep = items[batch.rep];
            u.fa_uv_scale[0] = rep.mr->uvScale.x;
            u.fa_uv_scale[1] = rep.mr->uvScale.y;
            MaterialAsset* mat = rep.material && rep.material->ok ? rep.material : nullptr;
            MaterialInputs inputs{};
            if (mat && (mat->programs[kProgShadow].shader.id || mat->programs[kProgShadowSkin].shader.id))
                material_inputs(rep, mat, inputs);
            for (auto& p : rep.mesh->parts) {
                const bool skinned = rep.anim && p.skinVb.id;
                const MaterialProgram* prog = mat ? &mat->programs[skinned ? kProgShadowSkin : kProgShadow] : nullptr;
                if (prog && !prog->shader.id) prog = nullptr;
                sg_apply_pipeline(prog ? gpu.shadow_pipeline(skinned, prog->shader, true)
                                       : gpu.shadow_pipeline(skinned));
                sg_bindings b{};
                b.vertex_buffers[0] = p.vb;
                b.vertex_buffers[1] = shadowInst;
                b.vertex_buffer_offsets[1] = int(batch.shadowFirst * kMeshInstanceBytes);
                if (skinned) b.vertex_buffers[2] = p.skinVb;
                b.index_buffer = p.ib;
                b.index_buffer_offset = p.ibOffset;
                const PartDraw pd = part_draw(ctx, rep, p);
                if (prog) bind_textures(ctx, b, pd, prog, inputs, true);
                sg_apply_bindings(&b);
                apply_uniforms(UB_mesh_fa_mesh_vs_params, u);
                if (skinned && declares(prog, UB_mesh_fa_skin))
                    apply_uniforms(UB_mesh_fa_skin, pack_palette(palette_of(*rep.anim, p.skin)));
                if (prog) {
                    if (prog->has_ub(UB_mesh_fa_mesh_fs_params))
                        apply_uniforms(UB_mesh_fa_mesh_fs_params, fill_fs(ctx, rep, p, pd));
                    if (prog->has_ub(UB_mesh_fa_lights)) apply_uniforms(UB_mesh_fa_lights, lightUniforms);
                    apply_material_params(*prog, inputs);
                }
                sg_draw(0, p.indexCount, int(batch.shadowCount));
                ++stats.drawCalls;
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
    ctx.doPrepass = ctx.debugPrepass = false;
    if (ctx.plan.view || !ctx.fr.wantWorld || ctx.camPx.w < 1 || ctx.camPx.h < 1) return false;
    if (!(pp.needsDepth || pp.needsNormals || debugView != DebugView::None)) return false;
    bool anyMesh = false;
    for (const MeshBatch& b : ctx.opaqueBatches) anyMesh = anyMesh || b.mainCount > 0;
    if (!anyMesh || !gpu.prepass_ready()) return false;  // prepass_ready logs once why it is not
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
    ctx.debugPrepass = debugView != DebugView::None && gpu.prepass_view_ready();
    return true;
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
    draw_group(ctx, ctx.gWorld.batches, ctx.fr.cam.viewProj, false, Px{0, 0, t.w, t.h}, 0, &pd.format);
    gpu.end_pass();
}

// Draws the opaque meshes of the job into `t`. Reads: ctx.opaque / opaqueBatches, ctx.mainInst, ctx.vuScene, ctx.fuScene, ctx.fr.cam, the
// custom prepass programs of the materials. Writes: `t`; stats.drawCalls.
void Renderer::Impl::prepass_pass(DrawContext& ctx, const Target& t) {
    const std::vector<MeshBatch>& batches = ctx.opaqueBatches;
    const std::vector<MeshItem>& items = ctx.opaque;
    PassDesc pd = pass_into(t, "prepass");
    pd.colorLoad = SG_LOADACTION_CLEAR;  // nothing drawn: far depth, no normal, coverage 0
    pd.clearColor = {PrepassRef::kFarDepth, 0.0f, 0.0f, 0.0f};
    pd.colorStore = SG_STOREACTION_STORE;
    pd.depthLoad = SG_LOADACTION_CLEAR;
    pd.clearDepth = 1.0f;
    gpu.begin_pass(pd);
    mesh_fa_mesh_vs_params_t vu = ctx.vuScene;
    copy_mat(vu.fa_light_vp,
             ctx.fr.cam.view);  // the prepass programs read the view matrix where the shadow programs read the light's
    for (const MeshBatch& batch : batches) {
        if (batch.mainCount == 0) continue;
        const MeshItem& mi = items[batch.rep];
        vu.fa_uv_scale[0] = mi.mr->uvScale.x;
        vu.fa_uv_scale[1] = mi.mr->uvScale.y;
        MaterialAsset* mat = mi.material && mi.material->ok ? mi.material : nullptr;
        MaterialInputs inputs{};
        if (mat && (mat->programs[kProgPrepass].shader.id || mat->programs[kProgPrepassSkin].shader.id))
            material_inputs(mi, mat, inputs);
        for (const SubMesh& part : mi.mesh->parts) {
            const bool skinned = mi.anim && part.skinVb.id;
            const PartDraw pd0 = part_draw(ctx, mi, part);
            const MaterialProgram* custom = mat ? &mat->programs[skinned ? kProgPrepassSkin : kProgPrepass] : nullptr;
            if (custom && !custom->shader.id) custom = nullptr;  // a twin made before the prepass: the engine's program
            const MaterialProgram* prog = custom ? custom : &gpu.prepass_program(skinned);
            PartDraw bind = pd0;
            if (!custom) bind.mat = nullptr;  // the engine's program has no material textures
            sg_apply_pipeline(gpu.prepass_pipeline(pd.format, part.doubleSided || (pd0.mat && pd0.mat->doubleSided),
                                                   skinned, custom ? custom->shader : sg_shader{}));
            sg_bindings b{};
            b.vertex_buffers[0] = part.vb;
            b.vertex_buffers[1] = ctx.mainInst;
            b.vertex_buffer_offsets[1] = int(batch.mainFirst * kMeshInstanceBytes);
            if (skinned) b.vertex_buffers[2] = part.skinVb;
            b.index_buffer = part.ib;
            b.index_buffer_offset = part.ibOffset;
            bind_textures(ctx, b, bind, prog, inputs, true);
            sg_apply_bindings(&b);
            apply_uniforms(UB_mesh_fa_mesh_vs_params, vu);
            if (skinned && prog->has_ub(UB_mesh_fa_skin))
                apply_uniforms(UB_mesh_fa_skin, pack_palette(palette_of(*mi.anim, part.skin)));
            if (prog->has_ub(UB_mesh_fa_mesh_fs_params))
                apply_uniforms(UB_mesh_fa_mesh_fs_params, fill_fs(ctx, mi, part, pd0));
            if (prog->has_ub(UB_mesh_fa_lights)) apply_uniforms(UB_mesh_fa_lights, ctx.lightUniforms);
            apply_material_params(*prog, inputs);
            sg_draw(0, part.indexCount, int(batch.mainCount));
            ++stats.drawCalls;
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
    fu.mode[0] = debugView == DebugView::Normals ? 2.0f : 1.0f;
    apply_uniforms(UB_prepass_view_prepass_view_fs_params, fu);
    sg_draw(0, 3, 1);
    ++stats.drawCalls;
    gpu.end_pass();
}

// Draws the batches of a quad group. Reads: ctx.vbuf, ctx.shadowRowsTex, fr (lights2d, shadowRows, ambient2d), renderScale,
// physW / physH, gpu.light_range(), lightTarget.texView (`flatMode` 1 reads the light buffer). Writes: stats.drawCalls.
void Renderer::Impl::draw_group(DrawContext& ctx, const std::vector<QuadBatch>& batches, const Mat4& vp, bool depthTest,
                                const Px& base, int flatMode, const TargetFormat* format) {
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
    }
    const sg_view lightTexBound = flatMode == 1 ? lightTarget.texView : assets->white()->view;
    const sg_view shadowTexBound = shadowRowsTex.id ? shadowRowsTex : assets->white()->view;
    for (const QuadBatch& qb : batches) {
        apply_clip(qb.clip);
        sg_apply_pipeline(format ? gpu.quad_pipeline(*format, depthTest, false, qb.blend, qb.plain, qb.opaque)
                                 : gpu.quad_pipeline(depthTest, false, qb.blend, qb.plain, qb.opaque));
        u.cspace[1] = float(qb.tex->tex_fix(fr.linear, true, fr.displayOverLinear));
        u.cspace[2] = qb.lit && qb.normal ? float(qb.normal->tex_fix(fr.linear, false)) : 0.0f;
        apply_uniforms(UB_quad_vs_params, u);
        if (qb.lit) {
            litUniforms.lit[1] = qb.normal ? 1.0f : 0.0f;
            if (qb.normal) normal_uv_transform(*qb.tex, *qb.normal, litUniforms.normal_uv);
            apply_uniforms(UB_quad_quad_fs_params, litUniforms);
        } else if (!qb.plain) {  // quad_plain declares no fragment uniforms
            apply_uniforms(UB_quad_quad_fs_params, unlit);
        }
        std::uint32_t done = 0;
        while (done < qb.quadCount) {
            std::uint32_t n = std::min<std::uint32_t>(qb.quadCount - done, kMaxQuadsPerDraw);
            sg_bindings b{};
            b.vertex_buffers[0] = vbuf;
            b.vertex_buffer_offsets[0] = int((qb.firstQuad + done) * 4 * sizeof(Vertex2D));
            b.index_buffer = gpu.quad_index_buffer();
            b.views[VIEW_quad_tex] = qb.tex->gpu_view();
            b.views[VIEW_quad_normal_tex] = (qb.lit && qb.normal ? qb.normal : assets->white())->gpu_view();
            b.views[VIEW_quad_light_tex] = lightTexBound;
            b.views[VIEW_quad_shadow_tex] = shadowTexBound;
            b.samplers[SMP_quad_smp] = gpu.sampler(qb.smp);
            b.samplers[SMP_quad_light_smp] = gpu.sampler(SamplerKind::LinearClamp);
            b.samplers[SMP_quad_shadow_smp] = gpu.sampler(SamplerKind::Nearest);
            sg_apply_bindings(&b);
            sg_draw(0, int(n * 6), 1);
            ++stats.drawCalls;
            done += n;
        }
    }
    apply_clip(Rect{});
}

// ---- main pass ----
// Camera.bloomScreenSpace = false: the frame is split in two passes. This one draws the world, the bloom then
// glows it, and a second pass (hud_pass) draws the screen-space groups (HUD) on top, so the HUD never glows.
// With MSAA the multisampled image must survive every pass but the last one (STORE): the next pass loads it, and with
// the HUD over the bloom the bloom adds its glow to it, the HUD pass loads it again, so the HUD is multisampled too and
// the final resolve contains everything.
// Reads: plan (first / last / view), fr (camera, wantWorld, wantScreen, debugLines), ctx.z01, msaa, hudAfterBloom,
// clearByQuad, clearByLoad, partial, camPx, fullPx, ctx.white, ss, fuScene, vuScene, lightUniforms, shadowRowsTex, litMode,
// opaque / blended with their batches, mainInst, the quad groups (gClear, gWorld, gDebugWorld, gScreen, gDebugScreen), vbuf,
// lineFirst, screenProj, shadowTarget.texView (doShadows) and lightTarget.texView (litMode 1), the game target images.
// Writes: the game target (gameTarget.colorAtt / resolveAtt / depthAtt); stats (drawCalls, triangles, meshes, meshBatches, materials,
// materialFallbacks).
void Renderer::Impl::main_pass(DrawContext& ctx) {
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
    const mesh_fa_lights_t& lightUniforms = ctx.lightUniforms;
    const bool drawHudInPass = fr.wantScreen && !hudAfterBloom && !ctx.hudAfterPost;
    if (ctx.doMainPass) {
        PassDesc mp = pass_into(gameTarget, plan.view ? "view" : fr.wantWorld ? "game" : "game-hud");
        mp.colorLoad = clearByLoad ? SG_LOADACTION_CLEAR : SG_LOADACTION_LOAD;
        const Color clearScene = to_scene(fr.cam.clearColor, fr.linear);
        mp.clearColor = {clearScene.r, clearScene.g, clearScene.b, clearScene.a};
        // The debug view of the prepass draws over the multisampled image next, so it must be kept.
        mp.colorStore = (msaa && (plan.last || plan.view) && !hudAfterBloom && !ctx.debugPrepass)
                            ? SG_STOREACTION_DONTCARE
                            : SG_STOREACTION_STORE;
        mp.depthLoad = SG_LOADACTION_CLEAR;
        mp.clearDepth = 1.0f;
        mp.stencilLoad = SG_LOADACTION_CLEAR;
        gpu.begin_pass(mp);
        if (partial) apply_view(camPx);

        // clear of a camera that shares the target with others
        if (clearByQuad) draw_group(ctx, gClear.batches, Mat4::ortho(0, 1, 1, 0, -1.0f, 1.0f, z01), false, camPx);

        // sky
        if (fr.wantWorld && fr.cam.perspective && fr.cam.clear && !fr.cam.studio) {
            sg_apply_pipeline(gpu.sky_pipeline());
            sg_bindings b{};
            b.vertex_buffers[0] = gpu.fullscreen_triangle();
            sg_apply_bindings(&b);
            sky_sky_vs_params_t vu{};
            copy_mat(vu.inv_view_proj, fr.cam.invViewProj);
            vu.cam_pos[0] = fr.cam.position.x;
            vu.cam_pos[1] = fr.cam.position.y;
            vu.cam_pos[2] = fr.cam.position.z;
            apply_uniforms(UB_sky_sky_vs_params, vu);
            sky_sky_fs_params_t fu{};
            fu.sky_color[0] = ss.skyColor.r;
            fu.sky_color[1] = ss.skyColor.g;
            fu.sky_color[2] = ss.skyColor.b;
            fu.sky_color[3] = 1;
            fu.horizon_color[0] = ss.horizonColor.r;
            fu.horizon_color[1] = ss.horizonColor.g;
            fu.horizon_color[2] = ss.horizonColor.b;
            fu.horizon_color[3] = 1;
            apply_uniforms(UB_sky_sky_fs_params, fu);
            sg_draw(0, 3, 1);
            ++stats.drawCalls;
        }

        // meshes: one instanced draw per part of every batch
        std::vector<const MaterialAsset*> materialsDrawn;
        auto draw_meshes = [&](const std::vector<MeshBatch>& batches, const std::vector<MeshItem>& items,
                               bool isBlend) {
            mesh_fa_mesh_vs_params_t vu = vuScene;
            for (const MeshBatch& batch : batches) {
                if (batch.mainCount == 0) continue;
                const MeshItem& mi = items[batch.rep];
                const MeshRenderer& mr = *mi.mr;
                vu.fa_uv_scale[0] = mr.uvScale.x;
                vu.fa_uv_scale[1] = mr.uvScale.y;
                MaterialInputs inputs{};
                if (mi.material && mi.material->ok) {
                    material_inputs(mi, mi.material, inputs);
                    if (std::find(materialsDrawn.begin(), materialsDrawn.end(), mi.material) == materialsDrawn.end())
                        materialsDrawn.push_back(mi.material);
                } else if (mi.material && std::find(stats.materialFallbacks.begin(), stats.materialFallbacks.end(),
                                                    mi.material->path) == stats.materialFallbacks.end()) {
                    stats.materialFallbacks.push_back(mi.material->path);
                }
                for (auto& part : mi.mesh->parts) {
                    const bool skinned = mi.anim && part.skinVb.id;
                    const PartDraw pd = part_draw(ctx, mi, part);
                    const MaterialProgram* prog =
                        pd.mat ? &pd.mat->programs[skinned ? kProgMeshSkin : kProgMesh] : nullptr;
                    sg_apply_pipeline(gpu.mesh_pipeline(isBlend, part.doubleSided || (pd.mat && pd.mat->doubleSided),
                                                        skinned, prog ? prog->shader : sg_shader{}));
                    sg_bindings b{};
                    b.vertex_buffers[0] = part.vb;
                    b.vertex_buffers[1] = mainInst;
                    b.vertex_buffer_offsets[1] = int(batch.mainFirst * kMeshInstanceBytes);
                    if (skinned) b.vertex_buffers[2] = part.skinVb;
                    b.index_buffer = part.ib;
                    b.index_buffer_offset = part.ibOffset;
                    bind_textures(ctx, b, pd, prog, inputs, false);
                    sg_apply_bindings(&b);
                    apply_uniforms(UB_mesh_fa_mesh_vs_params, vu);
                    if (skinned && declares(prog, UB_mesh_fa_skin))
                        apply_uniforms(UB_mesh_fa_skin, pack_palette(palette_of(*mi.anim, part.skin)));
                    apply_uniforms(UB_mesh_fa_mesh_fs_params, fill_fs(ctx, mi, part, pd));
                    apply_uniforms(UB_mesh_fa_lights, lightUniforms);
                    if (prog) apply_material_params(*prog, inputs);
                    sg_draw(0, part.indexCount, int(batch.mainCount));
                    ++stats.drawCalls;
                    stats.triangles += part.indexCount / 3 * int(batch.mainCount);
                }
                stats.meshes += int(batch.mainCount);
                ++stats.meshBatches;
            }
        };
        draw_meshes(opaqueBatches, opaque, false);
        draw_meshes(blendedBatches, blended, true);
        stats.materials += int(materialsDrawn.size());

        // quad groups
        draw_group(ctx, gWorld.batches, fr.cam.viewProj, fr.cam.perspective, camPx, litMode);
        draw_group(ctx, gDebugWorld.batches, fr.cam.viewProj, false, camPx);
        if (!fr.debugLines.empty()) {
            sg_apply_pipeline(gpu.quad_pipeline(false, true));
            quad_vs_params_t u{};
            copy_mat(u.view_proj, fr.cam.viewProj);
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
    }  // doMainPass
}

// ---- HUD pass: screen-space groups over the finished frame ----
// Camera.bloomScreenSpace = false draws them over the glowing game target ("hud-over-bloom"); a final pass that converts the picture
// (exposure, tonemap, linear colour) draws them over its result in hudTarget, in display space ("hud-over-post"). Either way they are
// never glowed, tonemapped or exposed.
// Reads: ctx.gScreen, ctx.gDebugScreen, ctx.screenProj, ctx.vbuf, ctx.msaa, `into` (LOAD). Writes: `into`; stats.drawCalls. Declared by
// build_graph when there is something to draw.
void Renderer::Impl::hud_pass(DrawContext& ctx, const Target& into, const char* label) {
    const bool msaa = ctx.msaa;
    const Px& fullPx = ctx.fullPx;
    const Mat4& screenProj = ctx.screenProj;
    const DrawContext::Group& gScreen = ctx.gScreen;
    const DrawContext::Group& gDebugScreen = ctx.gDebugScreen;
    // The items go over the final picture, which holds display (sRGB) values: they are drawn as in a gamma scene, whatever the colour space.
    const bool saveLinear = ctx.fr.linear;
    const bool saveOver = ctx.fr.displayOverLinear;
    if (ctx.hudAfterPost) {
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
    draw_group(ctx, gScreen.batches, screenProj, false, fullPx, 0);
    draw_group(ctx, gDebugScreen.batches, screenProj, false, fullPx, 0);
    gpu.end_pass();
    ctx.fr.linear = saveLinear;
    ctx.fr.displayOverLinear = saveOver;
}

// Declares the passes of the job in `graph` (the frame's), named "<job>/<pass>", in the order they always ran: the light buffer,
// the shadow map, the main pass, and in the last job of the frame the post-processing stack of the frame (the postCams' plans, postprocess.h): bloom (its
// stages), the HUD over the bloom (Camera.bloomScreenSpace false), the automatic exposure of each camera, the final pass `post` of each camera over its rectangle (exposure, tonemap, the
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
    ResourceId lightRes, shadowRes;
    if (ctx.litMode == 1) {
        lightRes = shared(sharedLight, "light-buffer", lightTarget.color.id,
                          import_desc(lightW, lightH, lightTarget.format, "light-buffer"));
        add("light-buffer", {}, {lightRes}, [this, &ctx](const PassContext&) { light_pass(ctx); });
    }
    if (ctx.doShadows) {  // no shadow caster, no pass
        shadowRes = shared(sharedShadow, "shadow-map", shadowTarget.color.id,
                           import_desc(shadowTarget.w, shadowTarget.h, shadowTarget.format, "shadow-map"));
        add("shadow", {}, {shadowRes}, [this, &ctx](const PassContext&) { shadow_pass(ctx); });
    }
    ResourceId prepassRes;
    if (ctx.doPrepass) {  // the image is a transient: the effects that read it list it in their reads
        TransientDesc pdsc;
        pdsc.width = ctx.camPx.w;  // the camera's rectangle of the picture
        pdsc.height = ctx.camPx.h;
        pdsc.format = gpu.prepass_target_format();
        pdsc.label = plan.name + "/prepass";  // resource names are unique in a graph, and every camera has its own
        prepassRes = graph.create_transient(pdsc);
        ctx.postPlan.prepass = PrepassRef{prepassRes, &transient_targets()};
        // Never culled: nothing reads the image until an effect or the debug view does, and the passes that need it are declared after.
        add(
            "prepass", {}, {prepassRes},
            [this, &ctx, prepassRes](const PassContext& c) {
                const Target* t = transient_targets().get(c.handle(prepassRes));
                if (t) prepass_pass(ctx, *t);
            },
            true);
    }
    if (ctx.doMainPass) {
        std::vector<ResourceId> reads;
        if (ctx.litMode == 1) reads.push_back(lightRes);
        if (ctx.doShadows) reads.push_back(shadowRes);
        if (!ctx.clearByLoad) reads.push_back(game);  // LOAD: a second camera or the HUD job continues the picture
        reads.insert(reads.end(), shown.begin(), shown.end());
        add(plan.view      ? "view"
            : fr.wantWorld ? "game"
                           : "game-hud",
            std::move(reads), {game}, [this, &ctx](const PassContext&) { main_pass(ctx); });
        if (ctx.debugPrepass)
            add("prepass-view", {prepassRes, game}, {game}, [this, &ctx, prepassRes](const PassContext& c) {
                const Target* t = transient_targets().get(c.handle(prepassRes));
                if (t) prepass_view_pass(ctx, *t);
            });
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
    if (!plan.last) return;

    // ---- the post-processing stack of the frame (postprocess.h): bloom -> the final pass of every camera -> the HUD -> the colour filter ----
    filterActive = false;
    hudActive = false;
    finalEncoded = false;
    for (auto it = autoExposures.begin(); it != autoExposures.end();) {
        if (it->second.frame + 1 < frameSerial) {  // its camera has not asked for two frames
            if (it->second.exposure) it->second.exposure->release();
            it = autoExposures.erase(it);
        } else {
            ++it;
        }
    }
    if (postCams.empty()) return;  // no camera drew a pixel
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
    const bool hudItems = fr.wantScreen && (!ctx.gScreen.batches.empty() || !ctx.gDebugScreen.batches.empty());
    if (ctx.hudAfterBloom && hudItems) {
        std::vector<ResourceId> reads{game};
        reads.insert(reads.end(), shown.begin(), shown.end());
        add("hud-over-bloom", std::move(reads), {game},
            [this, &ctx](const PassContext&) { hud_pass(ctx, gameTarget, "game-hud"); });
    }
    // The final pass of every camera that has one: exposure, tonemap and the output encode (and the colour filter, when nothing is drawn
    // in between) in one pass over the camera's rectangle.
    bool anyFinal = false;
    for (const DrawContext* c : postCams) anyFinal = anyFinal || c->postPlan.final_pass();
    if (anyFinal && (ctx.hudAfterPost || ensure_filter_target())) {
        const bool hud = ctx.hudAfterPost;
        const ResourceId dest =
            hud ? graph.import_target("game-post", hudTarget.colorAtt.id,
                                      import_desc(physW, physH, gameTarget.format, "game-post"))
                : graph.import_target("game-filtered", filterTarget.color.id,
                                      import_desc(physW, physH, filterTarget.format, "game-filtered"));
        // The colour filter works on what the screen shows, the interface included: with the interface over the picture it is a pass of
        // its own after it, else it is part of each final pass.
        const int filter = hud ? 0 : pp.colorFilter;
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
            true;  // the first pass draws every pixel it covers; the others keep what the passes before them drew
        auto declare = [&](const std::string& job, const char* name, const PostPlan& use, AutoExposure* exposure,
                           ResourceId evRes, const PostRect& rect) {
            const bool autoExp = evRes.valid();
            std::vector<ResourceId> reads{game};
            if (autoExp) reads.push_back(evRes);
            if (use.fx.outline) reads.push_back(use.outline_source().res);
            if (!first) reads.push_back(dest);
            const bool load = !first;
            first = false;
            add_job(job, name, std::move(reads), {dest},
                    [this, use, autoExp, exposure, outline_view, filter, rect, load, hud](const PassContext& c) {
                        PostPlan drawn;
                        const sg_view aux = outline_view(use, c, drawn);
                        post_pass(drawn, true, filter, autoExp, gameTarget.texView,
                                  autoExp ? exposure->ev_view() : assets->white()->view, aux,
                                  hud ? hudTarget : filterTarget, "post", hud, rect, load);
                        if (hud)
                            hudActive = true;
                        else
                            filterActive = true;
                        finalEncoded = true;
                    });
        };
        if (needBase) declare(plan.name, "post-base", basePlan, nullptr, ResourceId{}, PostRect{});
        for (std::size_t i = 0; i < postCams.size(); ++i) {
            DrawContext* c = postCams[i];
            const PostPlan& cp = c->postPlan;
            if (cp.final_pass()) {
                ResourceId evRes;
                AutoExposure* exposure = nullptr;
                if (cp.autoExposure) {
                    ExposureSlot& slot = autoExposures[c->fr.cam.entity.bits()];
                    if (!slot.exposure) slot.exposure = std::make_unique<AutoExposure>();
                    slot.frame = frameSerial;
                    exposure = slot.exposure.get();
                    evRes = exposure->add_passes(graph, transient_targets(), gpu, cp, game, gameTarget.texView, fr.dt,
                                                 frameSerial, &stats.drawCalls, c->plan.name, physW, physH);
                }
                declare(c->plan.name, "post", cp, exposure, evRes, cp.rect);
                continue;
            }
            // No stack: the plain pass, only where a stack drawn before it reaches its pixels.
            bool covered = false;
            const Rc mine = rect_of(cp);
            for (std::size_t j = 0; j < i && !covered; ++j)
                covered = postCams[j]->postPlan.final_pass() && overlap(mine, rect_of(postCams[j]->postPlan));
            if (covered) declare(c->plan.name, "post", basePlan, nullptr, ResourceId{}, cp.rect);
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
            }
        }
    } else if (pp.colorFilter != 0 && ensure_filter_target()) {
        // Only the colour filter (Camera.colorFilter / PostProcess.colorFilter): a copy of the game target through the filter.
        const ResourceId filtered = graph.import_target(
            "game-filtered", filterTarget.color.id, import_desc(physW, physH, filterTarget.format, "game-filtered"));
        add("color-filter", {game}, {filtered}, [this, pp](const PassContext&) {
            post_pass(pp, false, pp.colorFilter, false, gameTarget.texView, assets->white()->view, sg_view{},
                      filterTarget, "color-filter", false);
            filterActive = true;
        });
    }
}

}  // namespace fa
