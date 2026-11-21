// Reflection probes, the renderer's side (M73-P3b; docs/design/ARCHITECTURE_PROBES.md): which probes the world has, where their tiles are
// in the atlas, which faces of which realtime probe are drawn this frame, which baked pages are uploaded, and the report and the
// test hooks. The GPU passes are renderer_probes_gpu.cpp, the allocator and the scheduler are include/fa/render/probe.h.
//
// One frame with probes:
//   probes_plan    (after the cameras' jobs, before run_frame_graph)  the tiles of the probes are acquired or released; the scheduler says which
//                  faces are due and each one is a view job of the frame graph, "probe:<n>", whose image is upright on every backend
//   run_frame_graph
//   probes_finish  every face is copied into the scratch cube of its slot; the sixth face of a capture is followed by the filtering into the
//                  atlas; the baked pages and the sky's entry are written
// A world with no ReflectionProbe costs one test of the world's component count a frame and no GPU object.
#include <algorithm>
#include <cmath>
#include <limits>

#include "renderer_impl.h"
#include "renderer_test_access.h"

namespace fa {

namespace {

constexpr std::uint64_t kProbeViewKeyBit = 1ull
                                           << 61;  // the view_image keys of the probe faces: bit 61 and the job's index
constexpr std::uint64_t kProbeSyncKey = kProbeViewKeyBit | (1ull << 40);

bool same_tile(const ProbeTile& a, const ProbeTile& b) {
    return a.x == b.x && a.y == b.y && a.resolution == b.resolution;
}

float sane_gain(float intensity) { return std::isfinite(intensity) ? std::clamp(intensity, 0.0f, 64.0f) : 1.0f; }

Vec3 finite_or(Vec3 v, Vec3 fallback) {
    return std::isfinite(v.x) && std::isfinite(v.y) && std::isfinite(v.z) ? v : fallback;
}

ProbeUpdateKind update_kind(ProbeUpdate u) {
    switch (u) {
        case ProbeUpdate::EveryFrame: return ProbeUpdateKind::EveryFrame;
        case ProbeUpdate::OnDemand: return ProbeUpdateKind::OnDemand;
        default: return ProbeUpdateKind::TimeSliced;
    }
}

const char* update_name(ProbeUpdateKind k) {
    switch (k) {
        case ProbeUpdateKind::EveryFrame: return "everyFrame";
        case ProbeUpdateKind::OnDemand: return "onDemand";
        default: return "timeSliced";
    }
}

Json tile_json(const ProbeTile& t) { return Json::object({{"x", t.x}, {"y", t.y}, {"resolution", t.resolution}}); }

}  // namespace

// ---- the capture camera ---------------------------------------------------------------------------------------------------------

void Renderer::Impl::probe_face_frame(Frame& fr, World& world, const ReflectionProbe& rp, Vec3 position, int face,
                                      int resolution) {
    const ProbeFace f = probe_face(face);
    const bool z01 = gpu.depth_zero_to_one();
    const float nearP = std::isfinite(rp.nearPlane) ? std::max(1e-3f, rp.nearPlane) : 0.1f;
    const float farP = std::isfinite(rp.farPlane) ? std::max(rp.farPlane, nearP + 0.01f) : 100.0f;
    CameraInfo ci;
    // The matrices as camera_geometry builds them (view = R^T * T^-1 of a camera whose axes are right, up and -forward).
    const Vec3 x = f.right, y = f.up, z = -f.fwd;
    Mat4 view;
    view.at(0, 0) = x.x;
    view.at(1, 0) = x.y;
    view.at(2, 0) = x.z;
    view.at(0, 1) = y.x;
    view.at(1, 1) = y.y;
    view.at(2, 1) = y.z;
    view.at(0, 2) = z.x;
    view.at(1, 2) = z.y;
    view.at(2, 2) = z.z;
    view.at(3, 0) = -dot(x, position);
    view.at(3, 1) = -dot(y, position);
    view.at(3, 2) = -dot(z, position);
    ci.view = view;
    ci.position = position;
    ci.right = x;
    ci.up = y;
    ci.forward = f.fwd;
    ci.perspective = true;
    ci.fov = 90.0f;
    ci.proj = Mat4::perspective(90.0f, 1.0f, nearP, farP, z01);
    const Mat4 projGl = z01 ? Mat4::perspective(90.0f, 1.0f, nearP, farP, false) : ci.proj;
    ci.viewProj = ci.proj * ci.view;
    ci.invViewProj = ci.viewProj.inverse();
    ci.queryViewProj = projGl * ci.view;
    ci.queryInvViewProj = ci.queryViewProj.inverse();
    ci.clear = true;
    ci.clearColor = rp.clearColor;
    ci.noSky = rp.clear == ProbeClear::Color;
    fr = Frame{};
    fr.cam = std::move(ci);
    fr.wantWorld = true;
    fr.wantScreen = false;
    fr.noProbes = true;
    setup_frame(fr, world, 0.0f);
    fr.targetW = fr.targetH = resolution;
    fr.renderScale = 1.0f;
    fr.mask = CameraMask(camera_tag_list(rp.showTags), camera_tag_list(rp.hideTags));
}

// ---- the frame --------------------------------------------------------------------------------------------------------------------

void Renderer::Impl::probes_release() {
    ProbeSystem& ps = probes;
    ps.gpu.destroy_atlas(ps.atlas);
    ps.gpu.destroy_atlas(ps.syncAtlas);
    ps.gpu.release();
    ps.allocator = ProbeAtlasAllocator();
    ps.entries.clear();
    ps.scheduler.set_probes({});
    ps.world = nullptr;
    ps.sceneGeneration = 0;
    ps.skyPlaced = false;
    ps.skyTile = ProbeTile{};
    ps.skyKey = 0;
    ps.skyWrittenFrame = 0;
    ps.skyState.clear();
    ps.jobs.clear();
    ps.frames.clear();
    ps.uploads.clear();
    ps.overLimit = 0;
    gi_release();
}

void Renderer::Impl::probes_build_volumes(World& world) {
    probeVolumes.clear();
    const ProbeSystem& ps = probes;
    if (ps.entries.empty() || ps.world != &world || ps.sceneGeneration != world.scene_generation()) return;
    // The entries are a map by id: the same order on every machine, and the volumes' indices (part of the batch keys) follow it.
    for (const auto& [id, en] : ps.entries) {
        if (!en.placed || !en.tileValid || !world.alive(en.entity) || !world.active_in_hierarchy(en.entity)) continue;
        const ReflectionProbe* rp = world.get<ReflectionProbe>(en.entity);
        if (!rp) continue;
        const Mat4 m = world.drawn_matrix(en.entity, true);
        ProbeVolume v;
        v.id = id;
        v.position = m.translation();
        v.center = m.transform_point(finite_or(rp->boxOffset, Vec3{0, 0, 0}));
        const Vec3 size = finite_or(rp->boxSize, Vec3{10, 10, 10});
        const float sizes[3] = {std::fabs(size.x), std::fabs(size.y), std::fabs(size.z)};
        bool ok = std::isfinite(v.position.x) && std::isfinite(v.position.y) && std::isfinite(v.position.z) &&
                  std::isfinite(v.center.x) && std::isfinite(v.center.y) && std::isfinite(v.center.z);
        for (int c = 0; c < 3; ++c) {
            const Vec3 col{m.at(c, 0), m.at(c, 1), m.at(c, 2)};
            const float len = length(col);
            if (!(len > 1.0e-6f) || !std::isfinite(len)) {
                ok = false;
                break;
            }
            v.axis[c] = col * (1.0f / len);
            v.half[c] = std::clamp(sizes[c] * 0.5f * len, 1.0e-4f, 1.0e6f);
        }
        if (!ok) continue;
        v.blend = std::isfinite(rp->blendDistance) ? std::clamp(rp->blendDistance, 0.0f, 1.0e6f) : 0.0f;
        v.importance = rp->importance;
        v.projection = rp->boxProjection;
        probe_volume_finish(v);
        probeVolumes.push_back(v);
    }
}

void Renderer::Impl::probes_note_picks() {
    meshPicks.clear();
    if (probeVolumes.empty() || meshPickWatch == 0) return;  // only the mesh `render.probes` was asked about is kept
    for (const SceneMesh& sm : renderScene.meshes())
        if (sm.entity.bits() == meshPickWatch && sm.refl.any()) meshPicks.emplace_back(sm.entity.bits(), sm.refl);
}

void Renderer::Impl::probes_write_sky() {
    ProbeSystem& ps = probes;
    if (!ps.atlas.valid() || !ps.skyPlaced || !skyEnv.baked()) return;
    if (ps.skyWrittenFrame != 0 && skyEnv.key() == ps.skyKey) return;
    int calls = 0;
    ps.gpu.write_sky(gpu, ps.atlas, ps.skyTile, skyEnv.prefiltered_view(), skyEnv.sampler(),
                     skyEnv.format() == SG_PIXELFORMAT_RGBA8, &calls);
    ps.drawCalls += calls;
    ps.skyKey = skyEnv.key();
    ps.skyWrittenFrame = std::max<std::uint64_t>(ps.frame, 1);
}

void Renderer::Impl::probes_plan(World& world) {
    ProbeSystem& ps = probes;
    ps.jobs.clear();
    ps.frames.clear();
    ps.uploads.clear();
    gi_collect(world);  // cheap when the world has no RealtimeGI
    // Entity ids repeat from one scene to the next: another world, or another scene loaded into this one, makes every entry of the
    // last scene a stranger (an on-demand probe would keep showing the old scene). The atlas and the sky's tile stay.
    if (ps.world != &world || ps.sceneGeneration != world.scene_generation()) {
        for (const auto& [id, en] : ps.entries) ps.allocator.release(id);
        ps.entries.clear();
        ps.scheduler.set_probes({});
        ps.world = &world;
        ps.sceneGeneration = world.scene_generation();
    }

    struct Want {
        Entity e;
        std::uint64_t id = 0;
        bool realtime = false;
        ProbeUpdateKind update = ProbeUpdateKind::TimeSliced;
        int resolution = 128, importance = 0;
        float gain = 1.0f;
        std::string bakedMap;
    };
    std::vector<Want> wants;
    if (world.any<ReflectionProbe>()) {
        world.each<ReflectionProbe>([&](Entity e, ReflectionProbe& rp) {
            if (!world.active_in_hierarchy(e)) return;
            Want w;
            w.e = e;
            w.id = e.bits();
            w.realtime = rp.mode == ProbeMode::Realtime;
            w.update = update_kind(rp.update);
            w.resolution = probe_resolution(rp.resolution);
            w.importance = rp.importance;
            w.gain = sane_gain(rp.intensity);
            w.bakedMap = rp.bakedMap;
            wants.push_back(std::move(w));
        });
    }
    // The sky is entry 0 of the atlas, which the meshes sample (M73-P3c): a scene whose meshes use the baked sky keeps the atlas with no
    // probe in it. The cameras were planned before this call, so envJobs says whether this frame's meshes sample the sky.
    const bool skyWanted = envFrame == frameSerial && !envJobs.empty();
    if (wants.empty() && !skyWanted && ps.gi.wants.empty()) {
        if (!ps.entries.empty() || ps.atlas.valid() || ps.syncAtlas.valid() || ps.skyPlaced || !ps.gi.grids.empty())
            probes_release();
        probeVolumes.clear();
        return;
    }
    // The most important first (so a probe that matters takes a tile before one that does not), then the smaller id: the same order on
    // every machine and in every frame.
    std::sort(wants.begin(), wants.end(), [](const Want& a, const Want& b) {
        return a.importance != b.importance ? a.importance > b.importance : a.id < b.id;
    });
    ps.overLimit = 0;
    if (wants.size() > std::size_t(kProbeMaxCount)) {
        ps.overLimit = int(wants.size() - std::size_t(kProbeMaxCount));
        wants.resize(std::size_t(kProbeMaxCount));
        if (!ps.overLimitWarned) {
            ps.overLimitWarned = true;
            FA_WARN("render",
                    "The scene has more than {} active ReflectionProbe components: only the {} with the largest "
                    "importance are kept. "
                    "Hint: give the probes that matter a larger importance, or deactivate the ones nothing reflects",
                    kProbeMaxCount, kProbeMaxCount);
        }
    }
    ++ps.frame;

    // The entries of this frame; a probe that is no longer listed gives its tile back.
    for (auto& [id, en] : ps.entries) en.seen = false;
    for (const Want& w : wants) {
        ProbeEntry& en = ps.entries[w.id];
        en.entity = w.e;
        en.id = w.id;
        en.name = world.id_of(w.e);
        en.realtime = w.realtime;
        en.update = w.update;
        en.importance = w.importance;
        en.gain = w.gain;
        en.bakedPath = w.bakedMap;
        en.resolution = w.resolution;
        en.seen = true;
    }
    for (auto it = ps.entries.begin(); it != ps.entries.end();) {
        if (it->second.seen) {
            ++it;
            continue;
        }
        ps.allocator.release(it->first);
        it = ps.entries.erase(it);
    }

    const auto fail_all = [&](const std::string& why) {
        for (auto& [id, en] : ps.entries) {
            en.state = "failed";
            en.message = why;
            en.placed = false;
        }
        ps.skyState = "failed";
        ps.scheduler.set_probes({});
    };
    if (!ps.gpu.ready()) {
        fail_all("this GPU cannot draw the probes' passes (see the log)");
        return;
    }
    // A RealtimeGI needs the band of blocks below the square (gi.h): an atlas made without it is made again, once.
    // (not on a GPU that cannot blend into RGBA16F: the grids are "unsupported" there and the band would be 1 MB of nothing)
    const int atlasHeight = ps.gi.wants.empty() || ps.gpu.rgba8() ? 0 : kGiAtlasHeight;
    if (ps.atlas.valid() && ps.atlas.height < atlasHeight) ps.gpu.destroy_atlas(ps.atlas);
    bool atlasRemade = false;
    if (!ps.atlas.valid()) {
        atlasRemade = true;
        // A new atlas is empty: nothing in the allocator is in it any more.
        ps.allocator = ProbeAtlasAllocator();
        ps.skyPlaced = false;
        ps.skyWrittenFrame = 0;
        ps.skyKey = 0;
        for (auto& [id, en] : ps.entries) {
            en.placed = false;
            en.tileValid = false;  // the new atlas is empty
            en.uploadedTile = ProbeTile{};
            en.uploadedGain = 0.0f;
            en.bakedSerial = 0;
        }
        if (!ps.gpu.make_atlas(ps.atlas, kProbeAtlasSize, "probe-atlas", atlasHeight)) {
            fail_all("the " + std::to_string(kProbeAtlasSize) + " x " + std::to_string(kProbeAtlasSize) +
                     " probe atlas could not be created (out of GPU memory?)");
            return;
        }
    }

    std::vector<std::uint64_t> evicted;
    const auto evict = [&]() {
        for (std::uint64_t id : evicted) {
            auto it = ps.entries.find(id);
            if (it == ps.entries.end()) continue;
            it->second.placed = false;
            it->second.state = "noRoom";
            it->second.message = "its tile was taken by a probe of larger importance";
        }
        evicted.clear();
    };
    // The sky is entry 0 (a tile of its own, never evicted: nothing is less important than it).
    if (!ps.skyPlaced) {
        const std::optional<ProbeTile> t =
            ps.allocator.acquire(kProbeSkyId, kProbeSkyResolution, std::numeric_limits<int>::max(), ps.frame, &evicted);
        ps.skyPlaced = t.has_value();
        if (t) ps.skyTile = *t;
        ps.skyKey = 0;
        ps.skyWrittenFrame = 0;
        evict();
    }
    if (ps.skyPlaced) {
        if (skyEnv.baked()) {
            ps.skyState = "ready";
            // A new atlas gets the sky that is baked now, so the meshes of this very frame find it; a sky that is baked again is written
            // by the tail of the "sky-env" pass (probes_write_sky).
            if (ps.skyWrittenFrame == 0) probes_write_sky();
        } else {
            ps.skyState = "noSky";
        }
    } else {
        ps.skyState = "failed";
    }

    std::vector<ProbeSpec> specs;
    std::vector<std::uint64_t> movedAgain;  // realtime probes that lost their tile once and got one: capture again
    for (const Want& w : wants) {
        ProbeEntry& en = ps.entries[w.id];
        if (en.state != "failed") en.message.clear();  // a failure keeps its reason until its retry
        // A baked probe holds the resolution of its page, not the component's.
        const ProbeBakeAsset* bake = nullptr;
        if (!en.realtime) {
            if (en.bakedPath.empty()) {
                ps.allocator.release(en.id);
                en.placed = false;
                en.state = "noBake";
                en.message = "ReflectionProbe.bakedMap is empty: run `factoria call probe.bake` for this probe";
                continue;
            }
            bake = assets->probe_bake(en.bakedPath);
            if (!bake || !bake->ok) {
                ps.allocator.release(en.id);
                en.placed = false;
                en.state = "noBake";
                en.message = bake ? bake->error : std::string("the baked probe could not be read");
                continue;
            }
            en.resolution = probe_resolution(bake->manifest.resolution);
        }
        const std::optional<ProbeTile> t =
            ps.allocator.acquire(en.id, en.resolution, en.importance, ps.frame, &evicted);
        evict();
        if (!t) {
            en.placed = false;
            en.state = "noRoom";
            en.message = "the atlas has no free " + std::to_string(en.resolution) +
                         " tile and every probe in it matters at least as much";
            continue;
        }
        ps.allocator.touch(en.id, ps.frame);
        const bool moved = !en.placed || !same_tile(en.tile, *t);
        en.tile = *t;
        en.placed = true;
        if (moved) en.tileValid = false;  // the new tile holds nothing until the next capture or upload
        if (en.realtime) {
            if (en.state == "failed" && ps.frame >= en.retryFrame) en.state = "pending";
            specs.push_back(ProbeSpec{en.id, en.update, en.importance, en.resolution});
            if (moved && en.captures > 0) movedAgain.push_back(en.id);
        } else {
            const bool stale =
                en.bakedSerial != bake->serial || !same_tile(en.uploadedTile, en.tile) || en.uploadedGain != en.gain;
            if (stale) {
                ps.uploads.push_back(en.id);
                en.state = "pending";
            } else {
                en.state = "ready";
            }
        }
    }
    ps.scheduler.set_probes(specs);
    for (std::uint64_t id : movedAgain) ps.scheduler.refresh(id);

    // The faces due this frame, each a job of the frame graph.
    const std::vector<ProbeScheduler::Work> work = ps.scheduler.plan(ps.frame);
    int index = 0;
    // A face that cannot be drawn (no tile any more, no images) must not count as drawn: the capture of that probe starts again, and
    // the rest of its faces in this plan are not drawn either. A real failure is retried after kProbeRetryFrames frames.
    std::vector<std::uint64_t> abandoned;
    const auto give_up = [&](ProbeEntry& en, bool failure, const std::string& why) {
        if (std::find(abandoned.begin(), abandoned.end(), en.id) != abandoned.end()) return;
        abandoned.push_back(en.id);
        if (failure) {
            en.state = "failed";
            en.message = why;
            en.retryFrame = ps.frame + std::uint64_t(kProbeRetryFrames) + 1;
        }
    };
    for (const ProbeScheduler::Work& wk : work) {
        if (std::find(abandoned.begin(), abandoned.end(), wk.id) != abandoned.end()) continue;
        auto it = ps.entries.find(wk.id);
        if (it == ps.entries.end()) {
            abandoned.push_back(wk.id);
            continue;
        }
        ProbeEntry& en = it->second;
        const ReflectionProbe* rp = en.placed ? world.get<ReflectionProbe>(en.entity) : nullptr;
        if (!rp) {  // its tile was taken by a probe that matters more, or the component went away
            give_up(en, false, std::string());
            continue;
        }
        if (!ps.gpu.prepare_scratch(wk.slot, en.resolution)) {
            give_up(en, true, "the scratch cube maps of the capture could not be created (out of GPU memory?)");
            continue;
        }
        const std::uint64_t key = kProbeViewKeyBit | std::uint64_t(index);
        TextureAsset* tex = view_image(key, en.resolution, en.resolution, true);
        if (!tex) {
            give_up(en, true,
                    "the " + std::to_string(en.resolution) + " x " + std::to_string(en.resolution) +
                        " image of a capture face could not be created (out of GPU memory?)");
            continue;
        }
        auto vit = viewTargets.find(key);
        if (vit == viewTargets.end() || !vit->second->main.color.id) {
            give_up(en, true, "the image of a capture face has no render target (out of GPU memory?)");
            continue;
        }
        Frame& fr = ps.frames.emplace_back();
        probe_face_frame(fr, world, *rp, world.drawn_matrix(en.entity, true).translation(), wk.face, en.resolution);
        JobPlan plan;
        plan.name = "probe:" + std::to_string(index);
        plan_view_job(world, fr, *vit->second, key, plan);
        ProbeSystem::Job job;
        job.id = wk.id;
        job.slot = wk.slot;
        job.face = wk.face;
        job.last = wk.last;
        job.key = key;
        job.picture = tex->view;
        ps.jobs.push_back(job);
        ++index;
    }
    for (std::uint64_t id : abandoned) {
        const auto it = ps.entries.find(id);
        const bool failed = it != ps.entries.end() && it->second.state == "failed";
        ps.scheduler.abandon(id, ps.frame, failed ? kProbeRetryFrames : 0);
    }
    gi_plan(world, atlasRemade);
}

void Renderer::Impl::probes_finish() {
    ProbeSystem& ps = probes;
    gi_finish();
    if (ps.jobs.empty() && ps.uploads.empty()) {
        ps.frames.clear();
        // The states that follow the scheduler.
        for (auto& [id, en] : ps.entries) {
            if (!en.realtime || !en.placed || en.state == "failed") continue;
            const ProbeScheduler::Info info = ps.scheduler.info(id);
            en.captures = info.captures;
            en.lastFrame = info.lastFrame;
            en.state = info.facesDone > 0 ? "capturing" : info.captures > 0 ? "ready" : "pending";
        }
        return;
    }
    int calls = 0;
    for (const ProbeSystem::Job& job : ps.jobs) {
        ps.gpu.face_to_cube(gpu, job.slot, job.face, job.picture, &calls);
        if (!job.last) continue;
        auto it = ps.entries.find(job.id);
        if (it == ps.entries.end() || !it->second.placed) continue;
        ps.gpu.filter(gpu, ps.atlas, job.slot, it->second.tile, it->second.gain, &calls);
        it->second.tileValid = true;
    }
    for (std::uint64_t id : ps.uploads) {
        auto it = ps.entries.find(id);
        if (it == ps.entries.end() || !it->second.placed) continue;
        ProbeEntry& en = it->second;
        const ProbeBakeAsset* bake = assets->probe_bake(en.bakedPath);
        if (!bake || !bake->ok) continue;
        if (ps.gpu.upload(gpu, ps.atlas, en.tile, *bake->page, bake->manifest.sh, en.gain, &calls)) {
            en.uploadedTile = en.tile;
            en.tileValid = true;
            en.uploadedGain = en.gain;
            en.bakedSerial = bake->serial;
            en.bakedHash = bake->manifest.hash;
            en.lastFrame = ps.frame;
            ++en.captures;
            en.state = "ready";
        } else {
            en.state = "failed";
            en.message = "the page of the baked probe could not be uploaded to the atlas (out of GPU memory?)";
        }
    }
    ps.drawCalls += calls;
    ps.jobs.clear();
    ps.frames.clear();
    for (auto& [id, en] : ps.entries) {
        if (!en.realtime || !en.placed || en.state == "failed") continue;
        const ProbeScheduler::Info info = ps.scheduler.info(id);
        en.captures = info.captures;
        en.lastFrame = info.lastFrame;
        en.state = info.facesDone > 0 ? "capturing" : info.captures > 0 ? "ready" : "pending";
    }
}

// ---- the synchronous capture --------------------------------------------------------------------------------------------------

bool Renderer::Impl::probe_read_atlas(int x, int y, int w, int h, std::vector<float>& out, std::string* error) {
    ProbeSystem& ps = probes;
    if (!ps.atlas.valid()) {
        if (error) *error = "the renderer has no probe atlas yet (no ReflectionProbe has been drawn)";
        return false;
    }
    if (x < 0 || y < 0 || w < 1 || h < 1 || x + w > ps.atlas.size || y + h > std::max(ps.atlas.height, ps.atlas.size)) {
        if (error) *error = "the rectangle is outside the atlas";
        return false;
    }
    if (!gpu.committed()) {  // as read_floats: the work of the frame is submitted before a read-back waits for it
        sg_commit();
        gpu.note_commit();
    }
    sg_image scratch{};
    if (!ps.gpu.read_region_begin(gpu, ps.atlas, x, y, w, h, scratch, nullptr)) {
        if (error) *error = "the image for the read-back could not be created";
        return false;
    }
    sg_commit();
    gpu.note_commit();
    return ProbeGpu::read_region_end(scratch, w, h, ps.gpu.rgba8(), out, error);
}

bool Renderer::Impl::probe_sync_capture(World& world, Entity probe, Renderer::ProbePage& out, std::string* error) {
    const auto fail = [&](std::string message) {
        if (error) *error = std::move(message);
        return false;
    };
    const ReflectionProbe* found = world.get<ReflectionProbe>(probe);
    if (!found) return fail("the entity has no ReflectionProbe component");
    const ReflectionProbe rp = *found;
    ProbeSystem& ps = probes;
    if (!ps.gpu.ready()) return fail("this GPU cannot draw the probes' passes (see the log)");
    if (ps.gpu.rgba8())
        return fail("this GPU cannot render to RGBA16F, and a baked probe holds light above 1 (use a probe that is "
                    "captured at run time)");
    const int resolution = probe_resolution(rp.resolution);
    constexpr int kSlot = kProbeSlots;  // the slot that belongs to the synchronous capture
    if (!ps.gpu.prepare_scratch(kSlot, resolution))
        return fail("the scratch cube maps of the capture could not be created (out of GPU memory?)");
    if (!ps.syncAtlas.valid() && !ps.gpu.make_atlas(ps.syncAtlas, kProbeSyncAtlasSize, "probe-sync-atlas"))
        return fail("the image the capture is filtered into could not be created (out of GPU memory?)");

    sync_color_space(world);
    settle_pass_times();  // the capture replaces the frame graph that the last frame's pass times are read from
    const RenderStats savedStats = stats;
    const std::vector<const MaterialAsset*> savedMaterialsCounted = materialsCounted;
    const std::uint32_t savedMaterialResolves = assets->material_resolves();
    const auto cleanup = [&]() {
        stats = savedStats;
        materialsCounted = savedMaterialsCounted;
        assets->set_material_resolves(savedMaterialResolves);
        assets->drop_material_cache();
        auto it = viewTargets.find(kProbeSyncKey);
        if (it != viewTargets.end()) {
            release_view(*it->second);
            viewTargets.erase(it);
        }
        ps.gpu.release_slot(kSlot);
    };
    set_target_self({});
    const Vec3 position = world.world_matrix(probe).translation();
    int calls = 0;
    for (int face = 0; face < kProbeFaces; ++face) {
        ramps.begin_frame();
        Frame fr;
        probe_face_frame(fr, world, rp, position, face, resolution);
        assets->drop_material_cache();
        fonts->sync();
        ramps.sync();
        TextureAsset* tex = view_image(kProbeSyncKey, resolution, resolution, true);
        if (!tex) {
            cleanup();
            return fail("the image of a capture face could not be created (out of GPU memory?)");
        }
        gpu.begin_frame();
        transient_targets().pool.begin_frame();
        begin_frame_graph(false);
        JobPlan plan;
        plan.name = "probe-capture";
        plan_view_job(world, fr, *viewTargets[kProbeSyncKey], kProbeSyncKey, plan);
        run_frame_graph();
        graphFromCapture = true;
        renderScene.reset();
        ps.gpu.face_to_cube(gpu, kSlot, face, tex->view, &calls);
    }
    const ProbeTile tile{0, 0, resolution};
    ps.gpu.filter(gpu, ps.syncAtlas, kSlot, tile, 1.0f, &calls);
    const ProbeLayout lay = probe_layout(resolution);
    const int pw = probe_page_width(resolution), ph = probe_page_height(resolution);
    sg_image pageImage{}, shImage{};
    bool ok = ps.gpu.read_region_begin(gpu, ps.syncAtlas, 0, 0, pw, ph, pageImage, &calls);
    if (ok) ok = ps.gpu.read_region_begin(gpu, ps.syncAtlas, 0, lay.shY, kProbeShCoefficients, 1, shImage, &calls);
    sg_commit();  // the read-back waits for the GPU, and on Metal the work is only submitted by sg_commit
    gpu.note_commit();
    std::vector<float> pagePx, shPx;
    std::string readError;
    if (ok)
        ok = ProbeGpu::read_region_end(pageImage, pw, ph, false, pagePx, &readError);
    else if (pageImage.id)
        sg_destroy_image(pageImage);
    if (ok)
        ok = ProbeGpu::read_region_end(shImage, kProbeShCoefficients, 1, false, shPx, &readError);
    else if (shImage.id)
        sg_destroy_image(shImage);
    cleanup();
    if (!ok) return fail("reading the capture back from the GPU failed: " + readError);
    if (pagePx.size() != std::size_t(pw) * std::size_t(ph) * 4 || shPx.size() < std::size_t(kProbeShCoefficients) * 4)
        return fail("the read-back of the capture has the wrong size");

    out.resolution = resolution;
    out.width = pw;
    out.height = ph;
    out.rgb.resize(std::size_t(pw) * std::size_t(ph) * 3);
    for (std::size_t i = 0, n = std::size_t(pw) * std::size_t(ph); i < n; ++i)
        for (std::size_t c = 0; c < 3; ++c) out.rgb[i * 3 + c] = pagePx[i * 4 + c];
    for (int k = 0; k < kProbeShCoefficients; ++k)
        for (int c = 0; c < 3; ++c) out.sh[k][c] = shPx[std::size_t(k) * 4 + std::size_t(c)];
    return true;
}

// ---- the public API -----------------------------------------------------------------------------------------------------------

bool Renderer::probe_capture(World& world, Entity probe, ProbePage& out, std::string* error) {
    if (!initialized()) {
        if (error) *error = "Renderer is not initialized";
        return false;
    }
    return impl_->probe_sync_capture(world, probe, out, error);
}

bool Renderer::probe_refresh(Entity probe) {
    if (!initialized()) return false;
    ProbeSystem& ps = impl_->probes;
    auto it = ps.entries.find(probe.bits());
    if (it == ps.entries.end() || !it->second.realtime || !it->second.placed) return false;
    ps.scheduler.refresh(it->first);
    return true;
}

void Renderer::probe_set_budget(int faces) {
    if (initialized()) impl_->probes.scheduler.set_budget(faces);
}

Json Renderer::probe_report() const {
    if (!initialized()) return Json::object();
    const ProbeSystem& ps = impl_->probes;
    if (ps.entries.empty()) return Json::object();  // the sky alone keeps an atlas for the meshes: that is not a probe
    Json out = Json::object();
    Json atlas = Json::object();
    atlas["size"] = ps.allocator.atlas_size();
    atlas["format"] = ps.gpu.format() == SG_PIXELFORMAT_NONE ? "none" : ps.gpu.rgba8() ? "RGBA8" : "RGBA16F";
    atlas["tiles"] = ps.allocator.count();
    atlas["usedTexels"] = double(ps.allocator.used_texels());
    atlas["reservedTexels"] = double(ps.allocator.reserved_texels());
    atlas["capacityTexels"] =
        double(std::uint64_t(ps.allocator.atlas_size()) * std::uint64_t(ps.allocator.atlas_size()));
    atlas["created"] = ps.atlas.valid();
    out["atlas"] = std::move(atlas);
    Json sky = Json::object();
    sky["state"] = ps.skyState.empty() ? "none" : ps.skyState;
    sky["tile"] = ps.skyPlaced ? tile_json(ps.skyTile) : Json();
    sky["writtenFrame"] = double(ps.skyWrittenFrame);
    out["sky"] = std::move(sky);
    out["faceBudget"] = ps.scheduler.budget();
    out["frame"] = double(ps.frame);
    out["passes"] = ps.drawCalls;
    out["overLimit"] = ps.overLimit;
    Json list = Json::array();
    for (const auto& [id, en] : ps.entries) {
        Json p = Json::object();
        p["entity"] = en.name;
        p["mode"] = en.realtime ? "realtime" : "baked";
        if (en.realtime) p["update"] = update_name(en.update);
        p["state"] = en.state.empty() ? "pending" : en.state;
        if (!en.message.empty()) p["message"] = en.message;
        p["resolution"] = en.resolution;
        p["importance"] = en.importance;
        p["tile"] = en.placed ? tile_json(en.tile) : Json();
        p["captures"] = double(en.captures);
        p["lastFrame"] = double(en.lastFrame);
        if (en.realtime) {
            const ProbeScheduler::Info info = ps.scheduler.info(id);
            p["facesDone"] = info.facesDone;
        } else {
            p["bakedMap"] = en.bakedPath;
            if (!en.bakedHash.empty()) p["hash"] = en.bakedHash;
        }
        list.push_back(std::move(p));
    }
    out["probes"] = std::move(list);
    return out;
}

bool Renderer::probe_watch_mesh(Entity mesh) {
    if (!initialized()) return false;
    const bool already = impl_->meshPickWatch == mesh.bits();
    impl_->meshPickWatch = mesh.bits();
    return already;
}

Json Renderer::probe_mesh_report(Entity mesh) const {
    if (!initialized()) return Json::object();
    const Impl& im = *impl_;
    const auto round4 = [](float v) { return double(std::lround(v * 10000.0f)) / 10000.0; };
    Json list = Json::array();
    float taken = 0.0f;
    for (const auto& [bits, pick] : im.meshPicks) {
        if (bits != mesh.bits()) continue;
        float shares[2];
        pick.shares(shares);
        for (int k = 0; k < 2; ++k) {
            const std::uint16_t idx = pick.index[k];
            if (!idx || std::size_t(idx) > im.probeVolumes.size() || !(shares[k] > 0.0f)) continue;
            const auto it = im.probes.entries.find(im.probeVolumes[std::size_t(idx) - 1].id);
            if (it == im.probes.entries.end()) continue;
            list.push_back(Json::object({{"entity", it->second.name}, {"share", round4(shares[k])}}));
            taken += shares[k];
        }
        break;
    }
    Json out = Json::object();
    out["probes"] = std::move(list);
    out["sky"] = round4(std::max(0.0f, 1.0f - taken));
    return out;
}

bool RendererTestAccess::read_probe_atlas(Renderer& r, int x, int y, int w, int h, std::vector<float>& out,
                                          std::string* error) {
    if (!r.initialized()) {
        if (error) *error = "Renderer is not initialized";
        return false;
    }
    return r.impl_->probe_read_atlas(x, y, w, h, out, error);
}

bool RendererTestAccess::probe_tile(Renderer& r, std::uint64_t id, render::ProbeTile& out) {
    if (!r.initialized()) return false;
    const std::optional<render::ProbeTile> t = r.impl_->probes.allocator.find(id);
    if (!t) return false;
    out = *t;
    return true;
}

void RendererTestAccess::probe_force_rgba8(bool force) { render::ProbeGpu::force_rgba8_for_tests(force); }

bool RendererTestAccess::probe_tile_valid(Renderer& r, std::uint64_t id) {
    if (!r.initialized()) return false;
    const auto it = r.impl_->probes.entries.find(id);
    return it != r.impl_->probes.entries.end() && it->second.placed && it->second.tileValid;
}

int RendererTestAccess::probe_volume_count(Renderer& r) {
    return r.initialized() ? int(r.impl_->probeVolumes.size()) : 0;
}

}  // namespace fa
