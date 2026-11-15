// Renderer::Impl, part 3: draw_view_job and draw_job, the passes of one frame's jobs.
#include "renderer_impl.h"

namespace fa {

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

struct Renderer::Impl::DrawContext {
    DrawContext(World& w, Frame& f, const JobPlan& p) : world(w), fr(f), plan(p), post(*p.post) {}
    World& world;
    Frame& fr;
    const JobPlan& plan;
    const CameraInfo& post;
    // draw_job: the viewports and clears of this job
    bool hudAfterBloom = false, msaa = false, z01 = false;
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

// The 3D gather of a camera (matrices, culling boxes, frustum and shadow tests) runs as jobs from this many
// MeshRenderers on, kMeshGrain per chunk: an item costs ~1 us (a skinned one several), a chunk a few to hand out.
constexpr std::size_t kParallelMeshes = 256;
constexpr std::size_t kMeshGrain = 64;

void copy_mat(float* dst, const Mat4& m) { std::memcpy(dst, m.m, sizeof(float) * 16); }

// The palette of glTF skin `skin` (a part is drawn with its own skin's); skin 0 when the animator has none for it.
const std::vector<Mat4>& palette_of(const Animator& a, int skin) {
    return skin > 0 && std::size_t(skin) < a.skinPalettes.size() ? a.skinPalettes[std::size_t(skin)] : a.palette;
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

using MaterialInputs = Renderer::Impl::MaterialInputs;
using Px = Renderer::Impl::Px;

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
Color part_base_color(const MeshRenderer& mr, const SubMesh& part) {
    if (!part.materialName.empty() && mr.materialColors.is_object()) {
        auto it = mr.materialColors.find(part.materialName);
        if (it != mr.materialColors.end() && it->is_array() && it->size() >= 3 && it->size() <= 4) {
            float v[4] = {1, 1, 1, 1};
            for (std::size_t i = 0; i < it->size(); ++i) {
                if (!(*it)[i].is_number()) return part.baseColor;  // validate reports it; the part keeps its own colour
                v[i] = (*it)[i].get<float>();
            }
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

// Draws a CameraView's camera into the view's image: the pass(es) of draw_job with the image in the place of the game target.
// No post effects (the frame has one set, the first camera's), no 2D light buffer.
void Renderer::Impl::draw_view_job(World& world, Frame& fr, ViewTarget& target) {
    const int sTargetW = targetW, sTargetH = targetH, sPhysW = physW, sPhysH = physH;
    const sg_view sColor = colorAtt, sResolve = resolveAtt, sDepth = depthAtt;
    targetW = physW = target.w;
    targetH = physH = target.h;
    colorAtt = target.colorAtt;
    resolveAtt = target.resolveAtt;
    depthAtt = target.depthAtt;
    const CameraInfo noPost;  // bloom off, no colour filter
    JobPlan plan;
    plan.first = true;
    plan.last = false;
    plan.view = true;
    plan.post = &noPost;
    draw_job(world, fr, plan);
    targetW = sTargetW;
    targetH = sTargetH;
    physW = sPhysW;
    physH = sPhysH;
    colorAtt = sColor;
    resolveAtt = sResolve;
    depthAtt = sDepth;
}

// Draws one job of the frame into the game target: the pass(es) of one camera's world (and, for the single full-screen
// camera, the screen-space items too), or the screen-space pass of a split frame. The last job also runs the post effects.
// The phases below run in this order, one GPU command stream, nothing reordered.
void Renderer::Impl::draw_job(World& world, Frame& fr, const JobPlan& plan) {
    DrawContext c(world, fr, plan);
    c.hudAfterBloom = c.post.bloom.enabled && c.post.bloom.intensity > 0.0f && !c.post.bloom.screenSpace;
    c.fullPx = Px{0, 0, physW, physH};
    c.camPx = fr.wantWorld ? px_rect(fr.cam.viewport, physW, physH) : c.fullPx;
    c.partial = fr.wantWorld && !fr.cam.fullViewport();
    // A camera that clears and is not the first one (or the only one) cannot use a load action (it clears the whole target,
    // not its rectangle): a colour quad over its viewport does it.
    c.clearByQuad = fr.wantWorld && fr.cam.clear && c.partial && !plan.first;
    c.clearByLoad = fr.wantWorld && fr.cam.clear && (plan.first || !c.partial);
    c.z01 = gpu.depth_zero_to_one();
    c.msaa = gpu.sample_count() > 1;

    gather_meshes(c);
    collect_lights(c);
    shadow_bounds(c);
    cull_and_batch(c);
    build_quad_stream(c);
    upload_instances(c);
    scene_uniforms(c);
    light_pass(c);
    shadow_pass(c);
    main_pass(c);
    if (!plan.last) return;
    post_passes(c);
}

// ---- 3D gather ----
// Reads: world (MeshRenderer, Animator, Feel, drawn matrices), fr (camera, tag mask, active filter), assets (mesh, texture,
// material lookups, on this thread). Writes: c.opaque, c.blended (blended far to near), fr.anyFlash.
void Renderer::Impl::gather_meshes(DrawContext& c) {
    World& world = c.world;
    Frame& fr = c.fr;
    const bool z01 = c.z01;

    auto& opaque = c.opaque;
    auto& blended = c.blended;
    fr.anyFlash = world.feel().any_flash();
    // The MeshRenderers this camera draws, in their order; the matrices, bounds and frustum tests run as jobs around the
    // asset lookups, which stay on this thread (a mesh, texture or material may be loaded).
    std::vector<MeshItem> meshes;
    if (fr.wantWorld)
        world.each<MeshRenderer>([&](Entity e, MeshRenderer& mr) {
            if (!entity_active(world, fr, e) || !fr.mask.draws(world, e)) return;  // Camera.showTags / hideTags
            MeshItem mi;
            mi.mr = &mr;
            mi.entity = e;
            meshes.push_back(mi);
        });
    const rjobs::Split meshSplit = rjobs::split(meshes.size(), kMeshGrain, kParallelMeshes);
    rjobs::run("render.mesh_matrices", meshSplit, [&](const jobs::Chunk& c) {
        for (std::size_t i = c.begin; i < c.end; ++i) {
            MeshItem& mi = meshes[i];
            if (const auto flash = inherited_flash(world, fr, mi.entity))
                mi.flash = *flash;  // feel.h: flashing items never share a draw
            mi.model = world.drawn_matrix(mi.entity);
            mi.dist = length(mi.model.translation() - fr.cam.position);
        }
    });
    for (MeshItem& mi : meshes) {
        const MeshRenderer& mr = *mi.mr;
        mi.mesh = assets->mesh(mr.lods.empty() ? mr.mesh : lod_mesh(mr, mi.dist));  // MeshRenderer::lods
        mi.tex = mr.texture.empty() ? nullptr : assets->texture(mr.texture);
        mi.material = mr.material.empty() ? nullptr : assets->material(mr.material);
        mi.normalTex = mr.normalMap.empty() ? nullptr : assets->texture(mr.normalMap);
    }
    // Per item: the hashes of its overrides, its culling box, the frustum test and whether it is blended (a char: each
    // chunk writes its own items' slots).
    std::vector<char> meshBlended(meshes.size(), 0);
    rjobs::run("render.mesh_cull", meshSplit, [&](const jobs::Chunk& c) {
        for (std::size_t i = c.begin; i < c.end; ++i) {
            MeshItem& mi = meshes[i];
            const MeshRenderer& mr = *mi.mr;
            if (mi.material && mr.materialParams.is_object() && !mr.materialParams.empty())
                mi.paramsHash = std::hash<std::string>{}(mr.materialParams.dump());
            if (mr.materialColors.is_object() && !mr.materialColors.empty())
                mi.colorsHash = std::hash<std::string>{}(mr.materialColors.dump());
            mi.bmin = mi.mesh->bmin;
            mi.bmax = mi.mesh->bmax;
            // A skinned model with a computed pose is drawn deformed by the Animator's palette (before its first fixed step the
            // palette is empty and the model shows in bind pose).
            const Animator* anim = world.get<Animator>(mi.entity);
            if (anim && !anim->palette.empty()) {
                for (auto& p : mi.mesh->parts)
                    if (p.skinVb.id) mi.anim = anim;
                if (mi.anim) {  // the box of every skinned part carried by the joints of its own skin, joined with the rest
                    bool first = true;
                    for (auto& p : mi.mesh->parts) {
                        Vec3 lo = p.bmin, hi = p.bmax;
                        if (p.skinVb.id) skinned_bounds(palette_of(*anim, p.skin), p.bmin, p.bmax, lo, hi);
                        mi.bmin = first ? lo : min(mi.bmin, lo);
                        mi.bmax = first ? hi : max(mi.bmax, hi);
                        first = false;
                    }
                }
            }
            mi.visible = box_in_frustum(fr.cam.viewProj, z01, mi.bmin, mi.bmax, mi.model);
            // The alphaMode of a material decides (blend = drawn far to near with the blended meshes; opaque and clip are not),
            // whatever Color.a or the glTF material say.
            bool anyBlend = mr.color.a < 0.999f;
            for (auto& p : mi.mesh->parts) anyBlend = anyBlend || p.blended;
            if (mi.material) anyBlend = mi.material->alphaMode == "blend";
            meshBlended[i] = anyBlend ? 1 : 0;
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
// Reads: world (Light), fr.cam (position, studio rig), c.opaque (the no-light warning), plan.view. Writes: c.lights (sorted,
// capped), c.shadowLight, c.lightDirForShadow, c.haveShadowCaster, stats.lights / lightsDropped, warnedNoLight.
void Renderer::Impl::collect_lights(DrawContext& c) {
    World& world = c.world;
    Frame& fr = c.fr;
    const JobPlan& plan = c.plan;
    auto& opaque = c.opaque;
    auto& lights = c.lights;
    auto& shadowLight = c.shadowLight;
    auto& lightDirForShadow = c.lightDirForShadow;
    if (fr.wantWorld && !fr.cam.studio)
        world.each<Light>([&](Entity e, Light& l) {
            if (!entity_active(world, e)) return;
            Mat4 m = world.world_matrix(e);
            LightData ld;
            Vec3 col{l.color.r * l.intensity, l.color.g * l.intensity, l.color.b * l.intensity};
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
            ld.color = Vec4{color * (intensity * fr.cam.studioIntensity), 0.0f};
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
    c.haveShadowCaster = shadowLight >= 0 && !lights.empty() && lights[0].rank == 0;
    if (!opaque.empty() && lights.empty() && !warnedNoLight && !plan.view) {
        warnedNoLight = true;
        FA_WARN("render", "the scene has MeshRenderer entities but no Light entity: meshes only receive ambient light "
                          "(SceneSettings.ambientLight). Add an entity with a Light component (type Directional) or "
                          "set MeshRenderer.unlit.");
    }
}

// ---- shadow bounds ----
// Reads: c.haveShadowCaster, c.lightDirForShadow, c.opaque / c.blended (castShadows, mesh part boxes, matrices), gpu
// (shadows_supported, depth range). Writes: c.lightVP, c.doShadows; creates the shadow targets.
void Renderer::Impl::shadow_bounds(DrawContext& c) {
    const bool haveShadowCaster = c.haveShadowCaster;
    auto& opaque = c.opaque;
    auto& blended = c.blended;
    auto& lightDirForShadow = c.lightDirForShadow;
    auto& lightVP = c.lightVP;
    auto& doShadows = c.doShadows;
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
        if (any && gpu.shadows_supported()) {
            create_shadow_targets();
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
// Reads: c.doShadows, c.lightVP, c.z01, items' visible flags. Writes: c.opaque / c.blended (culled), item `casts`,
// c.opaqueBatches / c.blendedBatches, c.mainMats / c.shadowMats (instance matrices), stats.meshesCulled / shadowCasters.
void Renderer::Impl::cull_and_batch(DrawContext& c) {
    const bool z01 = c.z01;
    auto& opaque = c.opaque;
    auto& blended = c.blended;
    auto& lightVP = c.lightVP;
    auto& doShadows = c.doShadows;
    auto& opaqueBatches = c.opaqueBatches;
    auto& blendedBatches = c.blendedBatches;
    auto& mainMats = c.mainMats;
    auto& shadowMats = c.shadowMats;
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
// Reads: fr (world, debugWorld, screen, debugScreen quad lists, debugLines, camera clear colour), c.clearByQuad, targetW/H.
// Writes: `stream`, c.gClear / gWorld / gDebugWorld / gScreen / gDebugScreen, c.lineFirst, c.vbuf (transient buffer),
// c.screenProj.
void Renderer::Impl::build_quad_stream(DrawContext& c) {
    Frame& fr = c.fr;
    const bool z01 = c.z01;
    const bool clearByQuad = c.clearByQuad;
    auto& gClear = c.gClear;
    auto& gWorld = c.gWorld;
    auto& gDebugWorld = c.gDebugWorld;
    auto& gScreen = c.gScreen;
    auto& gDebugScreen = c.gDebugScreen;
    auto& lineFirst = c.lineFirst;
    auto& vbuf = c.vbuf;
    stream.clear();
    if (clearByQuad) {
        // The camera's clear colour over its viewport: one opaque quad over the unit square, which the viewport maps to the
        // camera's rectangle (see the draw below).
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

    c.screenProj = Mat4::ortho(0, float(targetW), float(targetH), 0, -1000.0f, 1000.0f, z01);
}

// ---- instance data: one model matrix per drawn mesh, written before any pass binds the buffers ----
// Reads: c.mainMats, c.shadowMats. Writes: c.mainInst, c.shadowInst (transient GPU buffers).
void Renderer::Impl::upload_instances(DrawContext& c) {
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
    c.mainInst = upload(c.mainMats);
    c.shadowInst = upload(c.shadowMats);
}

// ---- the scene's uniforms: shared by the main pass and the shadow pass of alphaMode "clip" materials ----
// Reads: world (settings, time), fr.cam, c.lights, c.lightVP, gpu. Writes: c.ss, c.white, c.lightUniforms, c.vuScene,
// c.fuScene.
void Renderer::Impl::scene_uniforms(DrawContext& c) {
    World& world = c.world;
    Frame& fr = c.fr;
    const std::vector<LightData>& lights = c.lights;
    const Mat4& lightVP = c.lightVP;
    SceneSettings& ss = c.ss;
    mesh_fa_lights_t& lightUniforms = c.lightUniforms;
    mesh_fa_mesh_vs_params_t& vuScene = c.vuScene;
    mesh_fa_mesh_fs_params_t& fuScene = c.fuScene;
    ss = world.settings();
    if (fr.cam.studio) {  // a neutral room: no scene ambient, sky or fog reaches the camera
        const float k = fr.cam.studioIntensity;
        ss.ambientLight = Color{0.2f * k, 0.2f * k, 0.22f * k, 1.0f};
        ss.skyColor = Color{0.55f * k, 0.58f * k, 0.65f * k, 1.0f};
        ss.horizonColor = Color{0.4f * k, 0.4f * k, 0.42f * k, 1.0f};
        ss.fogDensity = 0.0f;
    }
    c.white = assets->white();
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

// What one part of an item is drawn with (reads c.white).
Renderer::Impl::PartDraw Renderer::Impl::part_draw(DrawContext& c, const MeshItem& mi, const SubMesh& part) {
    TextureAsset* white = c.white;
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

// The fragment parameters (fa_mesh_fs_params) of one part (reads c.fuScene, c.doShadows).
mesh_fa_mesh_fs_params_t Renderer::Impl::fill_fs(DrawContext& c, const MeshItem& mi, const SubMesh& part,
                                                 const PartDraw& d) {
    const mesh_fa_mesh_fs_params_t& fuScene = c.fuScene;
    const bool doShadows = c.doShadows;
    const MeshRenderer& mr = *mi.mr;
    mesh_fa_mesh_fs_params_t fu = fuScene;
    const bool unlit = mr.unlit || d.error || (d.mat && d.mat->lighting == "unlit");
    // MeshRenderer.emissiveStrength scales both the component's colour and the model's own emission; a NaN or negative
    // value (a script wrote it) counts as 0, no glow.
    const float strength = mr.emissiveStrength > 0.0f ? std::min(mr.emissiveStrength, 1000.0f) : 0.0f;
    if (!d.error) {
        fu.fa_emissive[0] = mr.emissive.r * strength;
        fu.fa_emissive[1] = mr.emissive.g * strength;
        fu.fa_emissive[2] = mr.emissive.b * strength;
    }
    fu.fa_emissive[3] = unlit ? 1.0f : 0.0f;
    fu.fa_pbr[2] = (doShadows && mr.receiveShadows) ? 1.0f : 0.0f;
    const Color base = d.error ? Color{1, 0, 1, 1} : mr.color * part_base_color(mr, part);
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
    if (mi.flash.a > 0.0f && !d.error) {
        // A flash (feel.h) needs no shader change: the surface colour fades to nothing and the emission, which both the lit
        // and the unlit path add at the end (fog comes after), carries the flash colour. Lit meshes keep a little
        // specular and image-based reflection of their own.
        const float k = 1.0f - std::min(mi.flash.a, 1.0f), a = 1.0f - k;
        const float flash[3] = {mi.flash.r, mi.flash.g, mi.flash.b};
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
void Renderer::Impl::bind_textures(DrawContext& c, sg_bindings& b, const PartDraw& d, const MaterialProgram* prog,
                                   const MaterialInputs& in, bool shadowPass) {
    TextureAsset* white = c.white;
    const bool doShadows = c.doShadows;
    b.views[VIEW_mesh_fa_tex] = d.tex->gpu_view();
    b.views[VIEW_mesh_fa_shadow_tex] = (doShadows && !shadowPass) ? shadowTexView : white->view;
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
// Reads: fr (lights2d, shadowRows, camera), c.gWorld, c.ss.lightScale, c.partial, plan.view, gpu light state.
// Writes: c.litMode, c.shadowRowsTex; the light target (lightAtt) and, in litMode 1, its pass; stats.drawCalls.
void Renderer::Impl::light_pass(DrawContext& c) {
    Frame& fr = c.fr;
    const JobPlan& plan = c.plan;
    const bool partial = c.partial;
    const SceneSettings& ss = c.ss;
    const DrawContext::Group& gWorld = c.gWorld;
    int& litMode = c.litMode;
    sg_view& shadowRowsTex = c.shadowRowsTex;
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
    if (litMode == 1) {
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
                v.shadow[0] =
                    l.extra[0] >= 0.0f && fr.shadowRows > 0 ? (l.extra[0] + 0.5f) / float(fr.shadowRows) : -1.0f;
                lv.push_back(v);
            }
        }
        static_assert(kMaxLights2D <= kMaxQuadsPerDraw, "every light of a frame is drawn by one draw call");
        sg_buffer lb = gpu.acquire_transient(lv.size() * sizeof(LightVertex));
        sg_write_buffer_desc wd{};
        wd.src.data = {lv.data(), lv.size() * sizeof(LightVertex)};
        wd.dst.buffer = lb;
        sg_write_buffer_transient(&wd);

        sg_pass lp{};
        lp.action.colors[0].load_action = SG_LOADACTION_CLEAR;
        lp.action.colors[0].clear_value = {0, 0, 0, 0};
        lp.action.colors[0].store_action = SG_STOREACTION_STORE;
        lp.attachments.colors[0] = lightAtt;
        lp.label = "light-buffer";
        sg_begin_pass(&lp);
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
        sg_end_pass();
        ++stats.drawCalls;
    }
}

// ---- shadow pass ----
// Meshes cast with the engine's depth-only programs, except materials with their own shadow programs (vertex() moves the
// shadow, alphaMode "clip" cuts holes into it).
// Reads: c.doShadows, c.opaque / c.blended and their batches, c.shadowInst, c.vuScene, c.lights uniforms, the shadow targets.
// Writes: the shadow map (shadowColorAtt, shadowDepthAtt); stats.drawCalls.
void Renderer::Impl::shadow_pass(DrawContext& c) {
    if (!c.doShadows) return;
    const std::vector<MeshBatch>& opaqueBatches = c.opaqueBatches;
    const std::vector<MeshBatch>& blendedBatches = c.blendedBatches;
    const std::vector<MeshItem>& opaque = c.opaque;
    const std::vector<MeshItem>& blended = c.blended;
    const sg_buffer shadowInst = c.shadowInst;
    const mesh_fa_mesh_vs_params_t& vuScene = c.vuScene;
    const mesh_fa_lights_t& lightUniforms = c.lightUniforms;
    {
        sg_pass sp{};
        sp.action.colors[0].load_action = SG_LOADACTION_CLEAR;
        sp.action.colors[0].clear_value = {1, 1, 1, 1};
        sp.action.depth.load_action = SG_LOADACTION_CLEAR;
        sp.action.depth.clear_value = 1.0f;
        sp.attachments.colors[0] = shadowColorAtt;
        sp.attachments.depth_stencil = shadowDepthAtt;
        sp.label = "shadow";
        sg_begin_pass(&sp);
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
                    const MaterialProgram* prog =
                        mat ? &mat->programs[skinned ? kProgShadowSkin : kProgShadow] : nullptr;
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
                    const PartDraw pd = part_draw(c, rep, p);
                    if (prog) bind_textures(c, b, pd, prog, inputs, true);
                    sg_apply_bindings(&b);
                    apply_uniforms(UB_mesh_fa_mesh_vs_params, u);
                    if (skinned && declares(prog, UB_mesh_fa_skin))
                        apply_uniforms(UB_mesh_fa_skin, pack_palette(palette_of(*rep.anim, p.skin)));
                    if (prog) {
                        if (prog->has_ub(UB_mesh_fa_mesh_fs_params))
                            apply_uniforms(UB_mesh_fa_mesh_fs_params, fill_fs(c, rep, p, pd));
                        if (prog->has_ub(UB_mesh_fa_lights)) apply_uniforms(UB_mesh_fa_lights, lightUniforms);
                        apply_material_params(*prog, inputs);
                    }
                    sg_draw(0, p.indexCount, int(batch.shadowCount));
                    ++stats.drawCalls;
                }
            }
        }
        sg_end_pass();
    }
}

// Draws the batches of a quad group (reads c.vbuf, c.shadowRowsTex, fr.lights2d, lightTexView; `flatMode` 1 reads the
// light buffer). Writes: stats.drawCalls.
void Renderer::Impl::draw_group(DrawContext& c, const std::vector<QuadBatch>& batches, const Mat4& vp, bool depthTest,
                                const Px& base, int flatMode) {
    Frame& fr = c.fr;
    const sg_buffer vbuf = c.vbuf;
    const sg_view shadowRowsTex = c.shadowRowsTex;
    if (batches.empty()) return;
    quad_vs_params_t u{};
    copy_mat(u.view_proj, vp);
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
    const sg_view lightTexBound = flatMode == 1 ? lightTexView : assets->white()->view;
    const sg_view shadowTexBound = shadowRowsTex.id ? shadowRowsTex : assets->white()->view;
    for (const QuadBatch& qb : batches) {
        apply_clip(qb.clip);
        sg_apply_pipeline(gpu.quad_pipeline(depthTest, false, qb.blend, qb.plain, qb.opaque));
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
// Reads: everything the earlier phases wrote (batches, instances, uniforms, quad groups, litMode), the target images.
// Writes: the game target (colorAtt / resolveAtt / depthAtt); stats (drawCalls, triangles, meshes, meshBatches, materials,
// materialFallbacks).
void Renderer::Impl::main_pass(DrawContext& c) {
    Frame& fr = c.fr;
    const JobPlan& plan = c.plan;
    const bool z01 = c.z01, msaa = c.msaa, hudAfterBloom = c.hudAfterBloom;
    const bool clearByQuad = c.clearByQuad, clearByLoad = c.clearByLoad, partial = c.partial;
    const Px& camPx = c.camPx;
    const Px& fullPx = c.fullPx;
    const SceneSettings& ss = c.ss;
    const Mat4& screenProj = c.screenProj;
    const std::size_t lineFirst = c.lineFirst;
    const sg_buffer vbuf = c.vbuf;
    const int litMode = c.litMode;
    const DrawContext::Group& gClear = c.gClear;
    const DrawContext::Group& gWorld = c.gWorld;
    const DrawContext::Group& gDebugWorld = c.gDebugWorld;
    const DrawContext::Group& gScreen = c.gScreen;
    const DrawContext::Group& gDebugScreen = c.gDebugScreen;
    const std::vector<MeshBatch>& opaqueBatches = c.opaqueBatches;
    const std::vector<MeshBatch>& blendedBatches = c.blendedBatches;
    const std::vector<MeshItem>& opaque = c.opaque;
    const std::vector<MeshItem>& blended = c.blended;
    const sg_buffer mainInst = c.mainInst;
    const mesh_fa_mesh_vs_params_t& vuScene = c.vuScene;
    const mesh_fa_lights_t& lightUniforms = c.lightUniforms;
    // Does this job begin a pass? The screen-space job of a frame whose HUD goes over the bloom draws after it instead.
    const bool doMainPass = fr.wantWorld || !hudAfterBloom;
    const bool drawHudInPass = fr.wantScreen && !hudAfterBloom;
    if (doMainPass) {
        sg_pass mp{};
        mp.action.colors[0].load_action = clearByLoad ? SG_LOADACTION_CLEAR : SG_LOADACTION_LOAD;
        mp.action.colors[0].clear_value = {fr.cam.clearColor.r, fr.cam.clearColor.g, fr.cam.clearColor.b,
                                           fr.cam.clearColor.a};
        mp.action.colors[0].store_action =
            (msaa && (plan.last || plan.view) && !hudAfterBloom) ? SG_STOREACTION_DONTCARE : SG_STOREACTION_STORE;
        mp.action.depth.load_action = SG_LOADACTION_CLEAR;
        mp.action.depth.clear_value = 1.0f;
        mp.action.stencil.load_action = SG_LOADACTION_CLEAR;
        mp.attachments.colors[0] = colorAtt;
        if (gpu.sample_count() > 1) mp.attachments.resolves[0] = resolveAtt;
        mp.attachments.depth_stencil = depthAtt;
        mp.label = plan.view ? "view" : fr.wantWorld ? "game" : "game-hud";
        sg_begin_pass(&mp);
        if (partial) apply_view(camPx);

        // clear of a camera that shares the target with others
        if (clearByQuad) draw_group(c, gClear.batches, Mat4::ortho(0, 1, 1, 0, -1.0f, 1.0f, z01), false, camPx);

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
                    const PartDraw pd = part_draw(c, mi, part);
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
                    bind_textures(c, b, pd, prog, inputs, false);
                    sg_apply_bindings(&b);
                    apply_uniforms(UB_mesh_fa_mesh_vs_params, vu);
                    if (skinned && declares(prog, UB_mesh_fa_skin))
                        apply_uniforms(UB_mesh_fa_skin, pack_palette(palette_of(*mi.anim, part.skin)));
                    apply_uniforms(UB_mesh_fa_mesh_fs_params, fill_fs(c, mi, part, pd));
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

        draw_group(c, gWorld.batches, fr.cam.viewProj, fr.cam.perspective, camPx, litMode);
        draw_group(c, gDebugWorld.batches, fr.cam.viewProj, false, camPx);
        if (!fr.debugLines.empty()) {
            sg_apply_pipeline(gpu.quad_pipeline(false, true));
            quad_vs_params_t u{};
            copy_mat(u.view_proj, fr.cam.viewProj);
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
            draw_group(c, gScreen.batches, screenProj, false, fullPx, 0);
            draw_group(c, gDebugScreen.batches, screenProj, false, fullPx, 0);
        }

        sg_end_pass();
    }  // doMainPass
}

// ---- post-process: bloom adds its glow into the game target ----
// Reads: c.post.bloom, c.hudAfterBloom, c.msaa, the game target images. Writes: the game target (glow); stats.drawCalls.
void Renderer::Impl::bloom_pass(DrawContext& c) {
    const CameraInfo& post = c.post;
    const bool hudAfterBloom = c.hudAfterBloom, msaa = c.msaa;
    if (post.bloom.enabled) {
        BloomTarget dst;
        if (hudAfterBloom && msaa) {
            // Glow into the multisampled image (resolved again at the end of the composite pass) so the HUD pass below
            // can load it. Reads the already resolved image of the main pass.
            dst = BloomTarget{colorAtt, resolveAtt, gpu.sample_count()};
        } else {
            // The finished frame: the resolved image when MSAA is on (the main pass already resolved into it).
            dst = BloomTarget{msaa ? resolveColorAtt : colorAtt, sg_view{}, 1};
        }
        stats.drawCalls += bloom.apply(gpu, post.bloom, physW, physH, texView, dst);
    }
}

// ---- HUD pass (Camera.bloomScreenSpace = false): screen-space groups over the glowing frame ----
// Reads: c.gScreen, c.gDebugScreen, c.screenProj, c.vbuf, c.msaa, fr.wantScreen. Writes: the game target; stats.drawCalls.
void Renderer::Impl::hud_pass(DrawContext& c) {
    Frame& fr = c.fr;
    const bool hudAfterBloom = c.hudAfterBloom, msaa = c.msaa;
    const Px& fullPx = c.fullPx;
    const Mat4& screenProj = c.screenProj;
    const DrawContext::Group& gScreen = c.gScreen;
    const DrawContext::Group& gDebugScreen = c.gDebugScreen;
    if (hudAfterBloom && fr.wantScreen && (!gScreen.batches.empty() || !gDebugScreen.batches.empty())) {
        sg_pass hp{};
        hp.action.colors[0].load_action = SG_LOADACTION_LOAD;  // keep the world and its glow
        hp.action.colors[0].store_action = msaa ? SG_STOREACTION_DONTCARE : SG_STOREACTION_STORE;
        hp.action.depth.load_action = SG_LOADACTION_CLEAR;
        hp.action.depth.clear_value = 1.0f;
        hp.action.stencil.load_action = SG_LOADACTION_CLEAR;
        hp.attachments.colors[0] = colorAtt;
        if (msaa) hp.attachments.resolves[0] = resolveAtt;
        hp.attachments.depth_stencil = depthAtt;
        hp.label = "game-hud";
        sg_begin_pass(&hp);
        draw_group(c, gScreen.batches, screenProj, false, fullPx, 0);
        draw_group(c, gDebugScreen.batches, screenProj, false, fullPx, 0);
        sg_end_pass();
    }
}

// The last job of the frame: bloom, the HUD over it, then Camera.colorFilter (costs nothing with "none").
// Reads: c.post, plus what bloom_pass and hud_pass read. Writes: the game target, filterImg / filterActive; stats.drawCalls.
void Renderer::Impl::post_passes(DrawContext& c) {
    bloom_pass(c);
    hud_pass(c);
    filterActive = false;
    if (c.post.colorFilter != 0) stats.drawCalls += apply_color_filter(c.post.colorFilter);
}

}  // namespace fa
