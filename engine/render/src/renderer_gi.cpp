// The realtime GI, the renderer's side (M73-P5d-1; docs/design/ARCHITECTURE_PROBES.md, "Realtime GI: the data side"): which RealtimeGI grids the
// world has, where their probes' blocks are in the band of the probe atlas, which probes are captured this frame (a few a frame, in
// include/fa/render/gi.h's order), the six face jobs of each capture, the filtering of a finished capture into its block, and the report.
// It is a part of the probes' frame (renderer_probes.cpp calls gi_collect and gi_plan from probes_plan, gi_finish from probes_finish): a
// world without a RealtimeGI costs one test of the world's component count a frame, no pass, no image and no shader.
#include <algorithm>
#include <cmath>

#include "renderer_impl.h"
#include "renderer_test_access.h"

namespace fa {

namespace {

constexpr std::uint64_t kGiViewKeyBit =
    (1ull << 61) | (1ull << 41);  // the view_image keys of the GI's faces (bit 61 is the probes')

Json vec_json(Vec3 v) { return Json::array({Json(double(v.x)), Json(double(v.y)), Json(double(v.z))}); }
double round3(double v) { return std::round(v * 1000.0) / 1000.0; }

}  // namespace

void Renderer::Impl::gi_release() { probes.gi = GiSystem{}; }

void Renderer::Impl::gi_collect(World& world) {
    GiSystem& g = probes.gi;
    g.wants.clear();
    g.jobs.clear();
    g.plans.clear();
    g.frames.clear();
    // Entity ids repeat from one scene to the next: another world or scene makes every grid a stranger.
    if (g.world != &world || g.sceneGeneration != world.scene_generation()) {
        g.grids.clear();
        g.blocks.clear();
        g.perFrame.clear();
        g.world = &world;
        g.sceneGeneration = world.scene_generation();
    }
    if (!world.any<RealtimeGI>()) return;
    world.each<RealtimeGI>([&](Entity e, RealtimeGI&) {
        if (world.active_in_hierarchy(e)) g.wants.push_back(e);
    });
    std::sort(g.wants.begin(), g.wants.end(), [](Entity a, Entity b) { return a.bits() < b.bits(); });
    if (g.wants.size() > std::size_t(kGiMaxGrids)) {
        FA_WARN("render",
                "The scene has {} active RealtimeGI components: only the first {} (by entity) are drawn. Hint: one "
                "grid per room is "
                "enough; deactivate the others or merge their boxes",
                g.wants.size(), kGiMaxGrids);
        g.wants.resize(std::size_t(kGiMaxGrids));
    }
}

// The grids the meshes of this frame read: those whose probes were all captured once (ready), as they stand after the last frame's captures,
// so a grid that is still filling is never read (no flash). Their records go into the light data texture of every view of the frame
// (upload_lights), a capture's views too: a face of a probe sees the grid times its `bounce`.
void Renderer::Impl::gi_build_records(World& world) {
    GiSystem& g = probes.gi;
    g.records.clear();
    g.shaded.clear();
    if (g.grids.empty() || g.world != &world || g.sceneGeneration != world.scene_generation()) return;
    const ProbeSystem& ps = probes;
    if (g.unsupported || ps.gpu.rgba8() || !ps.atlas.valid() || ps.atlas.height < kGiAtlasHeight) return;
    for (const auto& [id, gr] : g.grids) {
        if (!gr.valid || gr.base < 0 || gr.captured < gr.layout.count) continue;
        const std::size_t at = g.records.size();
        g.records.resize(at + std::size_t(kGiRecordFloats));
        gi_pack_record(gr.layout, gr.base, true, g.records.data() + at);
        g.shaded.push_back(id);
    }
}

void Renderer::Impl::gi_plan(World& world, bool atlasRemade) {
    ProbeSystem& ps = probes;
    GiSystem& g = ps.gi;
    if (g.wants.empty()) {
        for (const auto& [id, gr] : g.grids) g.blocks.release(id);
        g.grids.clear();
        g.perFrame.clear();
        g.unsupported = false;
        return;
    }
    for (auto& [id, gr] : g.grids) gr.seen = false;
    const bool supported =
        !ps.gpu.rgba8() && ps.atlas.valid() && ps.atlas.height >= kGiAtlasHeight && ps.gpu.gi_ready();
    g.unsupported = !supported;
    // The grids: the layout of each (a bad component says what is wrong and is not drawn), its run of blocks.
    for (Entity e : g.wants) {
        const RealtimeGI* c = world.get<RealtimeGI>(e);
        if (!c) continue;
        GiGrid& gr = g.grids[e.bits()];
        gr.entity = e;
        gr.id = e.bits();
        gr.name = world.id_of(e);
        gr.seen = true;
        if (!supported) {
            gr.valid = false;
            gr.state = "unsupported";
            gr.message = "this GPU cannot blend into RGBA16F images (the probe atlas of the realtime GI); the grid is "
                         "not captured";
            continue;
        }
        const Vec3 where = world.drawn_matrix(e, true).translation();
        const Result<GiLayout> layout = gi_layout(*c, where, gr.name);
        if (!layout.ok()) {
            gr.valid = false;
            gr.state = "invalid";
            gr.message = layout.error().to_string();
            g.blocks.release(gr.id);
            gr.base = -1;
            continue;
        }
        const std::optional<int> base = g.blocks.acquire(gr.id, layout.value().count);
        // Every probe is captured again (and the grid is not "ready" until they are) when the layout changed, the atlas was made again, the
        // grid's blocks are not where they were, or the entity moved half a spacing.
        const bool changed = !gr.valid || gr.layout.key != layout.value().key || atlasRemade ||
                             gr.last.size() != std::size_t(layout.value().count) || (base && *base != gr.base) ||
                             gi_layout_moved(layout.value(), gr.anchor);
        gr.valid = true;
        gr.layout = layout.value();
        gr.probesPerFrame = qualityOn ? std::max(1, std::min(c->probesPerFrame, quality.realtimeGiProbesPerFrame))
                                      : c->probesPerFrame;  // the graphics preset caps how fast the grid updates
        if (changed) {
            gr.last.assign(std::size_t(gr.layout.count), 0);
            gr.retry.assign(std::size_t(gr.layout.count), 0);
            gr.serial = gr.captured = 0;
            gr.cycles = 0;
            gr.anchor = gr.layout.origin;
            gr.failed = false;
        }
        if (!base) {
            gr.base = -1;
            gr.state = "noRoom";
            gr.message = "the grids of the scene together have more than " + std::to_string(kGiMaxProbes) +
                         " probes: raise /spacing or shrink /size of this one, or of the others";
            continue;
        }
        gr.base = *base;
        if (!gr.failed) gr.message.clear();
    }
    for (auto it = g.grids.begin(); it != g.grids.end();) {
        if (it->second.seen) {
            ++it;
            continue;
        }
        g.blocks.release(it->first);
        it = g.grids.erase(it);
    }
    g.rtJobs.clear();
    g.rtPrevSerial.clear();
    g.rtReason.clear();
    g.rtBudget = 0;
    g.rtWanted = supported && rtSettings.enabled && rtSettings.gi == render::RtGi::Probes;
    if (!g.rtWanted) {  // turned off (and on again later): the next try starts clean
        g.rtMisses = 0;
        g.rtFallbackUntil = 0;
    }
    if (!supported) return;

    ++g.frame;
    // The ray traced mode (render.rayTracing.gi "probes"): the kernel updates the probes of every grid and the raster captures rest this frame.
    // When it cannot (the reason is kept for `render.ray_tracing`) the grids are captured the way they always were.
    if (g.wants.size() && g.rtWanted && gi_plan_rays()) return;
    for (auto& [id, gr] : g.grids) gr.rtMode = false;

    // The probes captured this frame, grid by grid in entity order, each as six face jobs.
    int left = kGiMaxFrameProbes;
    int index = 0;
    for (auto& [id, gr] : g.grids) {
        gr.lastFrameCaptures = 0;
        if (!gr.valid || gr.base < 0 || left <= 0) continue;
        const RealtimeGI* c = world.get<RealtimeGI>(gr.entity);
        if (!c) continue;
        const std::vector<int> picks = gi_pick(gr.last, gr.retry, g.frame, std::min(gr.probesPerFrame, left));
        ReflectionProbe rp;  // what probe_face_frame reads: the planes and the tags of the capture
        rp.nearPlane = gr.layout.nearPlane;
        rp.farPlane = gr.layout.maxDistance;
        rp.clear = ProbeClear::Sky;
        rp.showTags = c->showTags;
        rp.hideTags = c->hideTags;
        const int res = gr.layout.resolution;
        for (int probe : picks) {
            // Every picture of the probe first: a probe that cannot be drawn in full is not drawn at all, and tried again later.
            bool ok = true;
            std::vector<TextureAsset*> pictures;
            for (int face = 0; face < 6 && ok; ++face) {
                TextureAsset* tex = view_image(kGiViewKeyBit | std::uint64_t(index + face), res, res, true);
                const auto vit = viewTargets.find(kGiViewKeyBit | std::uint64_t(index + face));
                ok = tex && vit != viewTargets.end() && vit->second->main.color.id &&
                     ps.gpu.dist_image(index + face, res);
                pictures.push_back(tex);
            }
            if (!ok) {
                gr.retry[std::size_t(probe)] = g.frame + std::uint64_t(kGiRetryFrames);
                gr.failed = true;
                gr.failFrame = g.frame;
                gr.state = "failed";
                gr.message =
                    "the images of a capture could not be created (out of GPU memory?); the probe is tried again later";
                continue;
            }
            const bool first = gr.last[std::size_t(probe)] == 0;
            gr.last[std::size_t(probe)] = ++gr.serial;
            const Vec3 position = gi_probe_position(gr.layout, probe);
            for (int face = 0; face < 6; ++face) {
                const std::uint64_t key = kGiViewKeyBit | std::uint64_t(index);
                Frame& fr = g.frames.emplace_back();
                probe_face_frame(fr, world, rp, position, face, res);
                // This face sees the grid's light times its bounce (a ReflectionProbe's capture does not).
                fr.giCapture = true;
                GiFacePlan& fp = g.plans.emplace_back();
                fp.distIndex = index;
                fp.maxDistance = gr.layout.maxDistance;
                JobPlan plan;
                plan.name = "gi:" + std::to_string(index);
                plan.gi = &fp;
                plan_view_job(world, fr, *viewTargets.find(key)->second, key, plan);
                GiSystem::Job job;
                job.grid = id;
                job.probe = probe;
                job.face = face;
                job.distIndex = index;
                job.last = face == 5;
                job.first = first;
                job.picture = pictures[std::size_t(face)]->view;
                g.jobs.push_back(job);
                ++index;
            }
            --left;
        }
    }
}

// The ray traced update of this frame (docs/design/ARCHITECTURE_RT_GI.md): which probes of which grids (the order of gi_pick: the ones never
// updated first, then the ones updated longest ago, a budget per grid and kGiRtMaxFrameProbes together), the kernel's constants for each grid,
// and the `gi-probes` pass declared after the main camera's `rt-accel`. False, with g.rtReason: nothing is declared and the caller captures.
bool Renderer::Impl::gi_plan_rays() {
    ProbeSystem& ps = probes;
    GiSystem& g = ps.gi;
    for (auto& [id, gr] : g.grids) {
        gr.lastFrameCaptures = 0;
        gr.lastFrameRtUpdates = 0;
    }
    if (!rtScene.active()) {
        g.rtReason = "this device cannot trace rays here (render.supports raytracing says why)";
        return false;
    }
    if (rtAccelPass.empty() || !rtGiHitValid) {
        g.rtReason = "no camera drew the scene this frame, so the traced scene was not built";
        return false;
    }
    if (g.frame < g.rtFallbackUntil) {
        g.rtReason =
            g.rtFallbackReason;  // the rays failed a moment ago: the raster captures update the grids until the next try
        return false;
    }
    struct Pick {
        GiGrid* grid = nullptr;
        std::vector<int> probes;
    };
    std::vector<Pick> picks;
    RtGiRequest req;
    int left = kGiRtMaxFrameProbes;
    // The grids in a fixed order, starting at a grid that changes every frame: the 64 probes of the frame go to the first grids, so a fixed
    // start would starve the last ones when the grids ask for more than 64 together.
    std::vector<GiGrid*> order;
    for (auto& [id, gr] : g.grids)
        if (gr.valid && gr.base >= 0) order.push_back(&gr);
    const std::size_t first = order.empty() ? 0 : g.rtStart++ % order.size();
    for (std::size_t k = 0; k < order.size(); ++k) {
        GiGrid& gr = *order[(first + k) % order.size()];
        // M79-P6a: not capped by quality.realtimeGiProbesPerFrame (that knob is the raster captures' rate): the preset's lever for the
        // rays is the tier (QualityLimits::rtGi, which decides whether the probes are updated by rays at all).
        const int want = gr.layout.rtProbesPerFrame;
        g.rtBudget += std::min(want, kGiRtMaxFrameProbes);
        if (left <= 0) continue;
        Pick pick;
        pick.grid = &gr;
        pick.probes = gi_pick(gr.last, gr.retry, g.frame, std::min(want, left));
        if (pick.probes.empty()) continue;
        left -= int(pick.probes.size());
        const GiLayout& l = gr.layout;
        RtGiDispatch d;
        RtGiParams& p = d.params;
        p.grid0[0] = l.origin.x;
        p.grid0[1] = l.origin.y;
        p.grid0[2] = l.origin.z;
        p.grid0[3] = l.spacing;
        p.grid1[0] = float(l.nx);
        p.grid1[1] = float(l.ny);
        p.grid1[2] = float(l.nz);
        p.grid1[3] = float(l.count);
        p.grid2[0] = float(gr.base);
        p.grid2[1] = float(kGiBlocksPerRow);
        p.grid2[2] = l.maxDistance;
        p.grid2[3] = l.intensity;
        p.grid3[0] = l.bounce;
        p.grid3[1] = l.backfaceTolerance;
        p.grid3[2] = l.bounce > 0.0f ? 1.0f : 0.0f;
        p.grid3[3] = l.nearPlane;
        p.frame[0] = std::uint32_t(g.frame & 0xffffffffu);
        p.frame[1] = rt_effect_seed(g.frame);
        p.frame[2] = std::uint32_t(std::clamp(l.raysPerProbe, kGiRtMinRays, kGiRtMaxRays));
        p.frame[3] = std::uint32_t(pick.probes.size());
        p.flags[0] = gpu.has_device() ? rt_gi_front_sense(gpu.device().backend()) : 0.0f;
        const float blend = std::clamp(1.0f - l.hysteresis, 0.01f, 1.0f);
        for (std::size_t j = 0; j < pick.probes.size(); ++j) {
            const int probe = pick.probes[j];
            const GiTexel o = gi_block_origin(gr.base + probe);
            p.probe[j][0] = float(probe);
            p.probe[j][1] = gr.last[std::size_t(probe)] == 0 ? 1.0f : blend;
            p.probe[j][2] = float(o.x);
            p.probe[j][3] = float(o.y - kProbeAtlasSize);
        }
        req.dispatches.push_back(d);
        picks.push_back(std::move(pick));
    }
    if (req.dispatches.empty()) {
        g.rtReason = "no RealtimeGI grid is valid (render.gi_grid says why)";
        return false;
    }
    req.pass = "gi-probes";
    req.after = rtAccelPass;
    req.atlas = ps.atlas.tex;
    req.hit = rtGiHit;
    req.scene = &rtScene;
    req.frameSerial = frameSerial;
    req.drawCalls = &stats.drawCalls;
    std::string why;
    if (!rtGi.add_pass(graph, gpu, req, &why)) {
        g.rtReason = why;
        return false;
    }
    // Declared: the picks are taken now (a pass that does not run puts them back in gi_finish).
    for (Pick& pick : picks) {
        GiGrid& gr = *pick.grid;
        g.rtPrevSerial[gr.id] = gr.serial;
        gr.rtMode = true;
        for (int probe : pick.probes) {
            GiSystem::RtJob job;
            job.grid = gr.id;
            job.probe = probe;
            job.block = gr.base + probe;
            job.prevLast = gr.last[std::size_t(probe)];
            job.first = job.prevLast == 0;
            gr.last[std::size_t(probe)] = ++gr.serial;
            g.rtJobs.push_back(job);
        }
    }
    return true;
}

void Renderer::Impl::gi_finish() {
    ProbeSystem& ps = probes;
    GiSystem& g = ps.gi;
    if (g.wants.empty() && g.jobs.empty() && g.rtJobs.empty()) {
        std::lock_guard<std::mutex> lock(rtGiStatusMutex);
        rtGiStatus = render::RtGiStatus{};
        rtGiStatus.wanted = rtSettings.enabled && rtSettings.gi == render::RtGi::Probes;
        if (rtGiStatus.wanted) rtGiStatus.reason = "the scene has no RealtimeGI component";
        return;
    }
    int calls = 0;
    int rtUpdated = 0, rtGrids = 0;
    if (!g.rtJobs.empty()) {
        // The kernel wrote the new value of each probe's block, with its weight in alpha, into the band image: blend it into the atlas. A
        // pass that did not run (the scene had no TLAS yet, the driver refused the pipeline) gives the picks back.
        const RtGiImage* img = rtGi.image();
        const bool ran = img && img->ran;
        std::uint64_t lastGrid = 0;
        for (const GiSystem::RtJob& job : g.rtJobs) {
            auto it = g.grids.find(job.grid);
            if (it == g.grids.end()) continue;
            GiGrid& gr = it->second;
            if (ran) {
                ps.gpu.blit_gi(gpu, ps.atlas, img->texture, job.block, &calls);
                if (job.first) ++gr.captured;
                gr.lastCaptureFrame = g.frame;
                ++gr.lastFrameRtUpdates;
                ++rtUpdated;
                ++g.totalCaptures;
                ++g.rtTotal;
                if (lastGrid != job.grid) ++rtGrids;
                lastGrid = job.grid;
            } else {
                gr.last[std::size_t(job.probe)] = job.prevLast;
                const auto prev = g.rtPrevSerial.find(job.grid);
                if (prev != g.rtPrevSerial.end()) gr.serial = prev->second;
            }
        }
        if (ran) {
            g.rtMisses = 0;
        } else {
            // The pass was declared and did not run. A reason it declared (a refused pipeline) hands the grids to the raster captures at once; a
            // pass with no reason (the traced scene had no instance yet) gets kGiRtMissFrames frames to start, a scene may need one to build.
            const std::string why = rtGi.failure();
            g.rtReason = why.empty() ? "the traced scene was not ready this frame (it has no instance yet)" : why;
            if (!why.empty() || ++g.rtMisses >= kGiRtMissFrames) {
                g.rtFallbackUntil = g.frame + std::uint64_t(kGiRtRetryFrames);
                g.rtFallbackReason =
                    g.rtReason + " (the raster captures update the grids; the rays are tried again in 120 frames)";
                g.rtMisses = 0;
            }
        }
        g.rtJobs.clear();
        g.rtPrevSerial.clear();
    }
    {
        std::lock_guard<std::mutex> lock(rtGiStatusMutex);
        rtGiStatus = render::RtGiStatus{};
        rtGiStatus.wanted = rtSettings.enabled && rtSettings.gi == render::RtGi::Probes;
        rtGiStatus.active = rtUpdated > 0;
        rtGiStatus.grids = rtGrids;
        rtGiStatus.probesPerFrame = rtUpdated;
        rtGiStatus.budget = std::min(g.rtBudget, kGiRtMaxFrameProbes);
        if (rtGiStatus.wanted && !rtGiStatus.active)
            rtGiStatus.reason = g.unsupported
                                    ? std::string("this GPU cannot blend into RGBA16F images (the probe atlas)")
                                : g.rtReason.empty() ? std::string("no probe needed an update this frame")
                                                     : g.rtReason;
    }
    std::uint64_t skipped =
        0;  // the grid and probe of a capture whose faces are not drawn (its scratch cubes could not be made)
    bool skipping = false;
    int captured = rtUpdated;
    for (std::size_t i = 0; i < g.jobs.size(); ++i) {
        const GiSystem::Job& job = g.jobs[i];
        auto it = g.grids.find(job.grid);
        if (it == g.grids.end()) continue;
        GiGrid& gr = it->second;
        if (job.face == 0) {
            skipping = !ps.gpu.prepare_scratch(kGiScratchSlot, gr.layout.resolution);
            skipped = job.grid;
            if (skipping) {
                gr.last[std::size_t(job.probe)] = job.first ? 0 : gr.last[std::size_t(job.probe)];
                gr.retry[std::size_t(job.probe)] = g.frame + std::uint64_t(kGiRetryFrames);
                gr.failed = true;
                gr.failFrame = g.frame;
                gr.state = "failed";
                gr.message = "the scratch cube maps of a capture could not be created (out of GPU memory?)";
            }
        }
        if (skipping && skipped == job.grid) continue;
        const bool drawn = i < g.plans.size() && g.plans[i].drawn;
        ps.gpu.face_gi(gpu, kGiScratchSlot, job.face, job.picture,
                       drawn ? ps.gpu.dist_view(job.distIndex) : gpu::View{}, gr.layout.maxDistance, &calls);
        if (!job.last) continue;
        const float blend = job.first ? 1.0f : std::clamp(1.0f - gr.layout.hysteresis, 0.01f, 1.0f);
        ps.gpu.filter_gi(gpu, ps.atlas, kGiScratchSlot, gr.base + job.probe, gr.layout.resolution, blend,
                         gr.layout.maxDistance, &calls);
        if (job.first) ++gr.captured;
        gr.lastCaptureFrame = g.frame;
        ++gr.lastFrameCaptures;
        ++captured;
        ++g.totalCaptures;
    }
    for (auto& [id, gr] : g.grids) {
        if (!gr.valid || gr.base < 0) continue;
        gr.cycles = gr.layout.count > 0 ? gr.serial / std::uint64_t(gr.layout.count) : 0;
        // A failure stays visible (state and message, to render.gi_grid) until a capture finishes after it.
        if (gr.failed && gr.lastCaptureFrame > gr.failFrame) gr.failed = false;
        if (gr.failed) {
            gr.state = "failed";
        } else {
            gr.state = gr.captured >= gr.layout.count ? "ready" : "updating";
            gr.message.clear();
        }
    }
    g.perFrame.push_back(captured);
    if (g.perFrame.size() > GiSystem::kHistory) g.perFrame.erase(g.perFrame.begin());
    g.drawCalls += calls;
    ps.drawCalls += calls;
    g.jobs.clear();
    g.plans.clear();
    g.frames.clear();
}

// ---- the report -----------------------------------------------------------------------------------------------------------------

Renderer::GiProgress Renderer::gi_progress(Entity grid) const {
    GiProgress out;
    if (!initialized()) return out;
    const auto& grids = impl_->probes.gi.grids;
    const auto it = grids.find(grid.bits());
    if (it == grids.end() || !it->second.valid) return out;
    out.known = true;
    out.captured = it->second.captured;
    out.count = it->second.layout.count;
    return out;
}

Json Renderer::gi_report() {
    if (!initialized()) return Json::object();
    ProbeSystem& ps = impl_->probes;
    GiSystem& g = ps.gi;
    if (g.grids.empty() && !g.unsupported) return Json::object();
    Json out = Json::object();
    out["frame"] = double(g.frame);
    out["probeLimit"] = kGiMaxProbes;
    out["probesPerFrameLimit"] = kGiMaxFrameProbes;
    out["captures"] = double(g.totalCaptures);
    out["passes"] = g.drawCalls;
    out["rtUpdates"] = double(g.rtTotal);  // the probes the rays updated (they count in `captures` too)
    out["rtProbesPerFrameLimit"] = kGiRtMaxFrameProbes;
    Json history = Json::array();
    for (int n : g.perFrame) history.push_back(n);
    out["capturesPerFrame"] = std::move(history);  // the last frames, newest last
    Json atlas = Json::object();
    atlas["width"] = ps.atlas.size;
    atlas["height"] = ps.atlas.height;
    atlas["format"] = ps.gpu.format() == gpu::PixelFormat::None ? "none"
                      : ps.gpu.rgba8()                          ? "RGBA16F unavailable (RGBA8)"
                                                                : "RGBA16F";
    atlas["bytes"] = double(std::uint64_t(ps.atlas.size) * std::uint64_t(ps.atlas.height) * (ps.gpu.rgba8() ? 4u : 8u));
    atlas["blocksUsed"] = g.blocks.used();
    out["atlas"] = std::move(atlas);
    // The meta texels of the band, read back once: this is a command, not the frame.
    std::vector<float> band;
    std::string bandError;
    const bool haveBand = !g.grids.empty() && ps.atlas.valid() && ps.atlas.height >= kGiAtlasHeight &&
                          impl_->probe_read_atlas(0, kProbeAtlasSize, kProbeAtlasSize, kGiBandHeight, band, &bandError);
    if (!haveBand && !bandError.empty()) out["readError"] = bandError;
    Json list = Json::array();
    for (const auto& [id, gr] : g.grids) {
        Json o = Json::object();
        o["entity"] = gr.name;
        o["state"] = gr.state.empty() ? "pending" : gr.state;
        if (!gr.message.empty()) o["message"] = gr.message;
        if (gr.valid) {
            const GiLayout& l = gr.layout;
            o["probes"] = l.count;
            o["dimensions"] = Json::array({Json(l.nx), Json(l.ny), Json(l.nz)});
            o["spacing"] = round3(double(l.spacing));
            o["origin"] = vec_json(l.origin);
            o["resolution"] = l.resolution;
            o["probesPerFrame"] = gr.probesPerFrame;
            o["firstBlock"] = gr.base;
            o["captured"] = gr.captured;
            o["progress"] = l.count > 0 ? round3(double(gr.captured) / double(l.count)) : 0.0;
            o["cycles"] = double(gr.cycles);
            o["capturesLastFrame"] = gr.lastFrameCaptures;
            // M79-P4a: how the grid is updated ("rays": the ray traced probes of render.rayTracing.gi, "captures": the raster captures).
            o["updatedBy"] = gr.rtMode ? "rays" : "captures";
            o["raysPerProbe"] = l.raysPerProbe;
            o["rtProbesPerFrame"] = l.rtProbesPerFrame;
            o["rtUpdatesLastFrame"] = gr.lastFrameRtUpdates;
            o["meshesRead"] = std::find(g.shaded.begin(), g.shaded.end(), id) != g.shaded.end();
            const int perFrame = gr.rtMode ? l.rtProbesPerFrame : gr.probesPerFrame;
            o["framesPerCycle"] = (l.count + perFrame - 1) / std::max(perFrame, 1);
            o["bytes"] = double(std::uint64_t(l.count) * std::uint64_t(kGiBlockW) * std::uint64_t(kGiBlockH) * 8u);
            if (haveBand && gr.base >= 0) {
                std::vector<int> invalid;
                int pending = 0;
                for (int i = 0; i < l.count; ++i) {
                    const GiTexel t = gi_block_origin(gr.base + i);
                    const int x = t.x + kGiMetaX, y = t.y - kProbeAtlasSize + kGiShRow;
                    const std::size_t at = (std::size_t(y) * std::size_t(kProbeAtlasSize) + std::size_t(x)) * 4;
                    if (at + 3 >= band.size()) continue;
                    if (band[at + 1] < 0.5f)
                        ++pending;
                    else if (band[at] > l.backfaceTolerance)
                        invalid.push_back(i);
                }
                o["notCaptured"] = pending;
                o["invalidProbes"] = int(invalid.size());
                Json ids = Json::array();
                for (std::size_t k = 0; k < invalid.size() && k < 64; ++k) {
                    Json p = Json::object();
                    p["index"] = invalid[k];
                    p["position"] = vec_json(gi_probe_position(l, invalid[k]));
                    ids.push_back(std::move(p));
                }
                o["invalid"] = std::move(ids);  // up to 64: the probes inside geometry
            }
        }
        list.push_back(std::move(o));
    }
    out["grids"] = std::move(list);
    return out;
}

}  // namespace fa
