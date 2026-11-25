// Renderer::Impl, occlusion culling on the GPU with a hierarchical depth image (M75.2b; docs/BIG_WORLDS_LOD.md, "Occlusion"; the maths and what
// a test can prove are in hiz.h). Every frame a camera that is culled this way draws its depth and normal prepass, a compute pass reduces
// that image to a small grid of (nearest, farthest) depths in a storage buffer, and a ring of staging buffers brings the grid to the CPU
// without waiting. The CPU builds the mip chain and tests the boxes of the meshes of the NEXT frames against it (the camera's pose of the
// picture it was made from is kept with it). The result is one flag per mesh (MeshItem::visible = false): a culled mesh is left out of the
// main pass and the prepass, and still casts shadows (the shadow passes are not culled by it).
#include <algorithm>
#include <cmath>
#include <cstring>
#include <format>

#include "fa/core/profiler.h"
#include "render_jobs.h"
#include "render_scene.h"
#include "shader_cache.h"
#include "render_features.h"
#include "renderer_impl.h"
#include "shaders/hiz.glsl.h"

namespace fa {

namespace {

constexpr int kBoxEdgesHiz[12][2] = {{0, 1}, {2, 3}, {4, 5}, {6, 7}, {0, 2}, {1, 3},
                                     {4, 6}, {5, 7}, {0, 4}, {1, 5}, {2, 6}, {3, 7}};

// A game that draws every frame with the same few cameras keeps their pictures; a camera that was not drawn for this many frames loses its buffers.
constexpr std::uint64_t kHizForgetFrames = 120;

}  // namespace

Renderer::Impl::HizCamera::~HizCamera() {
    if (!device) return;
    // The copies still in flight are released with the camera; the device frees the staging buffers with itself.
    for (const Flight& f : flights) device->release_buffer_read(f.ticket);
    if (cellsView.id) device->destroy_view(cellsView);
    if (cells.id) device->destroy_buffer(cells);
}

bool Renderer::Impl::hiz_resolve(World& world) {
    const OcclusionMode mode = world.settings().occlusionMode;
    if (mode == OcclusionMode::Cpu) return false;
    if (hizSupport == 0) {
        std::string why;
        const gpu::Backend backend = gpu.device().backend();
        bool ok = false;
        if (backend == gpu::Backend::D3d12 || backend == gpu::Backend::Vulkan) {
            // The feature table has no column of their own yet (feature_backend_of): the depth pyramid needs compute
            // shaders and the reads without waiting below, which the device answers itself (M77-P10d: its reduce is the
            // work of the async compute queue).
            ok = gpu.device().features().compute;
            if (!ok) why = "this device has no compute shaders";
        } else {
            const render::FeatureEnv env = render::feature_env_from_device(gpu.device());
            ok = render::feature_supported(env, render::find_feature("occlusionGpu"), &why);
        }
        if (ok && !gpu.device().async_read_supported()) {
            ok = false;
            why = "this backend cannot read a storage buffer back without waiting";
        }
        if (ok && hizShaderState == 0) {
            hizShader = render::make_shader(gpu.device(), gpu::generated_shader_desc(gpu.device(), hiz_hiz_shader_desc),
                                            "hiz_hiz");
            hizShaderState = hizShader.id && gpu.device().state(hizShader) == gpu::ResourceState::Valid ? 1 : -1;
            if (hizShaderState < 0) {
                if (hizShader.id) gpu.destroy_shader(hizShader);
                hizShader = {};
                ok = false;
                why = "the depth reduction program was refused by this graphics driver (see the sokol log lines above)";
            }
        }
        hizSupport = ok ? 1 : -1;
        hizWhy = why;
    }
    if (hizSupport > 0) return true;
    if (mode == OcclusionMode::Gpu && !warnedHizMode) {
        warnedHizMode = true;
        FA_WARN("render",
                "SceneSettings.occlusionMode is \"gpu\" but this GPU cannot cull with the depth pyramid ({}). The CPU "
                "culling of the Occluders "
                "is used instead. Hint: set occlusionMode to \"auto\" (the pyramid where the GPU can make it, the "
                "Occluders elsewhere) or "
                "\"cpu\".",
                hizWhy);
    }
    return false;
}

void Renderer::Impl::hiz_release() {
    hizCams.clear();
    hizShown = {};
    hizPrev = {};
    if (hizShader.id && gpu.has_device()) gpu.destroy_shader(hizShader);
    hizShader = {};
    hizShaderState = 0;
    hizSupport = 0;
}

void Renderer::Impl::hiz_shift(const Vec3& off) {
    const Mat4 back = Mat4::translate(off);
    auto shift = [&](render::HizPose& p) {
        p.viewProj = p.viewProj * back;
        p.position -= off;
    };
    for (auto& [key, hc] : hizCams) {
        shift(hc->pose);
        shift(hc->reducedInfo.pose);
        for (HizCamera::Flight& f : hc->flights) shift(f.pose);
    }
}

// Asks for the copy of every reduce that is waiting for one, and takes the copies that came back. Runs when a frame begins, outside any pass:
// on Metal the copy is a blit after the sokol command buffer that holds the reduce, so that buffer must have been committed (an uncommitted
// frame is committed here, as a read-back does).
void Renderer::Impl::hiz_submit() {
    if (hizCams.empty()) return;
    const bool wait =
        desc.headless;  // a headless frame's result must not depend on the GPU's speed: one frame of latency, always
    bool pending = false;
    for (auto& [key, hc] : hizCams) pending = pending || hc->reduced;
    if (pending && !gpu.committed()) {
        gpu.commit_frame();
        gpu.note_commit();
    }
    gpu::Device& device = gpu.device();
    std::vector<std::uint8_t> bytes;
    for (auto& [key, hcPtr] : hizCams) {
        HizCamera& hc = *hcPtr;
        if (hc.reduced) {
            hc.reduced = false;
            std::string error;
            const std::size_t size = std::size_t(hc.reducedInfo.w) * std::size_t(hc.reducedInfo.h) * 8;
            gpu::ReadTicket ticket;
            if (hc.cells.id && size > 0) {
                const Result<gpu::ReadTicket> asked = device.request_buffer_read(hc.cells, 0, size);
                if (asked)
                    ticket =
                        asked.value();  // invalid without an error: every slot is in flight, the next frame asks again
                else
                    error = asked.error().message;
            }
            if (ticket.valid()) {
                HizCamera::Flight f = hc.reducedInfo;
                f.ticket = ticket;
                hc.flights.push_back(f);
            } else if (!error.empty() && !warnedHizRead) {
                warnedHizRead = true;
                FA_WARN("render",
                        "The depth pyramid of '{}' could not be read back from the GPU: {} The camera is drawn without "
                        "the GPU occlusion culling.",
                        hc.name, error);
            }
        }
        // Oldest first: the GPU runs its copies in order, so the newest that is done is the one to keep.
        for (std::size_t i = 0; i < hc.flights.size();) {
            HizCamera::Flight& f = hc.flights[i];
            if (!device.poll_buffer_read(f.ticket, bytes, wait)) {
                ++i;
                continue;
            }
            const std::size_t count = bytes.size() / sizeof(float);
            std::vector<float> cells(count);
            std::memcpy(cells.data(), bytes.data(), count * sizeof(float));
            if (f.frame >= hc.pyramidFrame && hc.pyramid.build(f.w, f.h, cells.data(), count)) {
                hc.pose = f.pose;
                hc.pyramidFrame = f.frame;
                hc.pyramidWorldFrame = f.worldFrame;
            }
            hc.flights.erase(hc.flights.begin() + std::ptrdiff_t(i));
        }
        // A GPU that never answers (a lost device) must not keep the ring full for ever: the copies older than the usable age are dropped.
        for (std::size_t i = 0; i < hc.flights.size();) {
            if (frameSerial > hc.flights[i].frame + 4 * render::kHizMaxAgeFrames) {
                device.release_buffer_read(hc.flights[i].ticket);
                hc.flights.erase(hc.flights.begin() + std::ptrdiff_t(i));
            } else {
                ++i;
            }
        }
    }
}

// Frame start of render(): the mode of the world, the pictures of a scene that is gone, the cameras that are not drawn any more.
void Renderer::Impl::hiz_begin_frame(World& world) {
    if (hizWorld != &world || hizScene != world.scene_path()) {
        hizCams.clear();  // the pictures of another scene hide nothing of this one
        hizWorld = &world;
        hizScene = world.scene_path();
    }
    hizOn = hiz_resolve(world);
    const OcclusionMode mode = world.settings().occlusionMode;
    hizModeName = mode == OcclusionMode::Gpu ? "gpu" : mode == OcclusionMode::Auto ? "auto" : "cpu";
    if (!hizOn && !hizCams.empty()) hizCams.clear();  // the mode was switched off: the buffers go
    for (auto it = hizCams.begin(); it != hizCams.end();)
        it = it->second->usedFrame + kHizForgetFrames < frameSerial ? hizCams.erase(it) : std::next(it);
}

render::HizPose Renderer::Impl::hiz_pose_of(const CameraInfo& cam) {
    return render::hiz_pose(cam.proj, cam.viewProj, cam.position);
}

Renderer::Impl::HizCamera* Renderer::Impl::hiz_cull(World& world, Frame& fr, std::vector<MeshItem>& meshes) {
    // An orthographic camera has no use for it (the depth of a cell is the clip w of a perspective matrix): the Occluders cull it.
    if (!fr.cam.perspective || !std::isfinite(fr.cam.proj.at(0, 0) + fr.cam.proj.at(1, 1))) return nullptr;
    const std::uint64_t key = fr.cam.entity.bits();
    auto it = hizCams.find(key);
    if (it == hizCams.end()) {
        if (int(hizCams.size()) >= render::kHizMaxCameras) {
            if (!warnedHizCameras) {
                warnedHizCameras = true;
                FA_WARN("render",
                        "More than {} cameras draw the world with the GPU occlusion culling: the others are culled by "
                        "the Occluders only. "
                        "Hint: keep the pyramid for the cameras of the player's view (split screen has a few) and set "
                        "occlusionMode to \"cpu\" "
                        "if the scene draws more.",
                        render::kHizMaxCameras);
            }
            return nullptr;
        }
        auto fresh = std::make_unique<HizCamera>();
        fresh->key = key;
        fresh->device = &gpu.device();
        fresh->name = fr.cam.fromEntity ? std::string(world.id_of(fr.cam.entity)) : std::string("camera");
        it = hizCams.emplace(key, std::move(fresh)).first;
    }
    HizCamera& hc = *it->second;
    hc.usedFrame = frameSerial;
    ++hizShown.cameras;
    hizShown.valid = true;
    hizShown.camera = hc.name;

    std::string why;
    bool usable = hc.pyramid.ready();
    if (!usable) {
        why = "no depth picture has come back from the GPU yet (the first frames of a camera draw everything)";
    } else {
        const std::uint64_t age = frameSerial - hc.pyramidFrame;
        const std::uint64_t wf = world.frame();
        if (age > std::uint64_t(render::kHizMaxAgeFrames)) {
            usable = false;
            why = std::format("the newest depth picture is {} frames old", age);
        } else if (wf < hc.pyramidWorldFrame || wf - hc.pyramidWorldFrame > render::kHizMaxWorldTicks) {
            usable = false;
            hc.pyramid = render::HizPyramid{};
            why = "the world jumped since the depth picture was made (a scene load or a seek)";
        }
    }
    hizShown.ageFrames = hc.pyramid.ready() ? int(std::min<std::uint64_t>(frameSerial - hc.pyramidFrame, 1000000)) : -1;
    if (!usable) {
        hizShown.why = why;
        return &hc;
    }
    ++hizShown.usable;
    const render::HizPose now = hiz_pose_of(fr.cam);
    std::vector<std::uint8_t> reason(meshes.size(), 0xFF);
    std::vector<char> hiddenFlag(meshes.size(), 0);
    const rjobs::Split split = rjobs::split(meshes.size(), kMeshGrain, kParallelMeshes);
    rjobs::run("render.mesh_hiz", split, [&](const jobs::Chunk& c) {
        for (std::size_t i = c.begin; i < c.end; ++i) {
            const MeshItem& mi = meshes[i];
            if (!mi.visible || mi.noCull) continue;  // not in the frustum already, or no known bounds
            render::HizTestInfo info;
            hiddenFlag[i] = render::hiz_hidden(hc.pyramid, hc.pose, now, mi.bmin, mi.bmax, mi.model, &info) ? 1 : 0;
            reason[i] = std::uint8_t(info.why);
        }
    });
    int tested = 0, hidden = 0;
    const bool boxes = debugView == DebugView::Occlusion;
    for (std::size_t i = 0; i < meshes.size(); ++i) {
        if (reason[i] == 0xFF) continue;
        ++tested;
        ++hizShown.reasons[std::min<std::size_t>(reason[i], hizShown.reasons.size() - 1)];
        if (!hiddenFlag[i]) continue;
        ++hidden;
        meshes[i].visible = false;
        if (boxes) {
            OcclusionShown::Box b;
            b.culled = true;
            for (int k = 0; k < 8; ++k)
                b.corners[std::size_t(k)] = meshes[i].model.transform_point(
                    Vec3{(k & 1) ? meshes[i].bmax.x : meshes[i].bmin.x, (k & 2) ? meshes[i].bmax.y : meshes[i].bmin.y,
                         (k & 4) ? meshes[i].bmax.z : meshes[i].bmin.z});
            hizShown.boxes.push_back(b);
        }
    }
    hizShown.tests += tested;
    hizShown.hidden += hidden;
    hizShown.cells = hc.pyramid.width(0);
    hizShown.cellsDown = hc.pyramid.height(0);
    hizShown.levels = hc.pyramid.levels();
    hizShown.coveredCells = int(std::min<std::size_t>(hc.pyramid.covered_cells(), 0x7fffffffu));
    if (boxes) {
        // A coarse level for the debug view: about 64 cells across.
        const int level = std::min(2, hc.pyramid.levels() - 1);
        hizShown.greyLevel = level;
        hizShown.greyW = hc.pyramid.width(level);
        hizShown.greyH = hc.pyramid.height(level);
        hizShown.grey = hc.pyramid.grey(level);
    }
    stats.occlusionTests += tested;
    stats.meshesOccluded += hidden;
    return &hc;
}

void Renderer::Impl::hiz_reduce_pass(gpu::CommandList& cmd, HizCamera& hc, const Target& prepass,
                                     const render::HizPose& pose, std::uint64_t worldFrame,
                                     std::uint64_t prepassHandle) {
    if (hizShaderState <= 0 || !prepass.texView.id || prepass.w < 1 || prepass.h < 1) return;
    gpu::Device& device = gpu.device();
    int w = 0, h = 0;
    render::hiz_size_for(float(prepass.w) / float(prepass.h), w, h);
    if (!hc.cells.id || hc.w != w || hc.h != h) {
        if (hc.cellsView.id) device.destroy_view(hc.cellsView);
        if (hc.cells.id) device.destroy_buffer(hc.cells);
        hc.cellsView = {};
        hc.cells = {};
        hc.w = hc.h = 0;
        // A picture of another grid cannot be mixed with the new ones: the pyramid stays as it is (it has its own size) until a new one replaces it.
        gpu::BufferDesc bd{};
        bd.size = std::size_t(w) * std::size_t(h) * 8;
        bd.usage.storageBuffer = true;
        bd.usage.copyDst =
            true;  // sokol: a storage buffer with no initial data is made with copy_dst (the shader fills it)
        bd.label = "hiz cells";
        hc.cells = device.make_buffer(bd);
        if (device.state(hc.cells) != gpu::ResourceState::Valid) {
            if (hc.cells.id) device.destroy_buffer(hc.cells);
            hc.cells = {};
            return;
        }
        gpu::ViewDesc vd{};
        vd.storageBuffer.buffer = hc.cells;
        vd.label = "hiz cells view";
        hc.cellsView = device.make_view(vd);
        if (device.state(hc.cellsView) != gpu::ResourceState::Valid) {
            if (hc.cellsView.id) device.destroy_view(hc.cellsView);
            device.destroy_buffer(hc.cells);
            hc.cellsView = {};
            hc.cells = {};
            return;
        }
        hc.w = w;
        hc.h = h;
    }
    const gpu::Pipeline pip = gpu.compute_pipeline(hizShader);
    if (device.state(pip) != gpu::ResourceState::Valid) {
        // The driver refused the program (the pipeline getter logged the reason once): this GPU cannot cull with the pyramid, so the
        // next frame's hiz_resolve answers "no" and the CPU culling of the Occluders takes over, with no more tries.
        hizShaderState = -1;
        hizSupport = -1;
        hizWhy = "the depth reduction pipeline was refused by this graphics driver (see the log lines above)";
        if (!warnedHizPipeline) {
            warnedHizPipeline = true;
            FA_WARN("render", "The depth pyramid cannot be used: {}. The CPU culling of the Occluders is used instead.",
                    hizWhy);
        }
        return;
    }
    gpu::Bindings bind{};
    bind.views[VIEW_hiz_hiz_cells_buf] = hc.cellsView;
    bind.views[VIEW_hiz_prepass_tex] = prepass.texView;
    bind.samplers[SMP_hiz_prepass_smp] = gpu.sampler(render::SamplerKind::Nearest);
    hiz_hiz_params_t u{};
    u.dims[0] = float(prepass.w);
    u.dims[1] = float(prepass.h);
    u.dims[2] = float(w);
    u.dims[3] = float(h);
    u.flip[0] = gpu.is_gl() ? 1.0f : 0.0f;  // an OpenGL render target's row 0 is the bottom of the picture
    // Async compute (M77-P10d, D3D12 and Vulkan with a compute queue of their own): the frame's list is submitted handing the
    // prepass image and the cells to the compute queue, the reduce runs on a compute list that waits for it, and its submit
    // hands both back. The graphics passes after this one run meanwhile; the first one that declares the prepass target waits
    // for the reduce (Gpu::wait_compute_for, the frame graph's `before` hook), the frame's commit waits for it otherwise. The
    // reduce reads what the prepass wrote and writes only the cells, so its result is the same on either queue.
    const bool async = gpu.async_compute();
    gpu::QueueHandoff uses[2];
    uses[0].image = prepass.texture_image();
    uses[1].buffer = hc.cells;
    gpu::CommandList& list = async ? gpu.begin_async_compute("hiz-reduce", uses, prepassHandle) : cmd;
    list.begin_compute_pass("hiz-reduce");
    list.set_pipeline(pip);
    list.set_bindings(bind);
    list.set_uniforms(UB_hiz_hiz_params, gpu::Range{&u, sizeof(u)});
    list.dispatch((w + 7) / 8, (h + 7) / 8, 1);
    list.end_pass();
    if (async) gpu.end_async_compute(list, uses, prepassHandle);
    gpu.note_work();
    hc.reduced = true;
    hc.reducedInfo = HizCamera::Flight{};
    hc.reducedInfo.pose = pose;
    hc.reducedInfo.w = w;
    hc.reducedInfo.h = h;
    hc.reducedInfo.frame = frameSerial;
    hc.reducedInfo.worldFrame = worldFrame;
    ++hizReduces;
}

void Renderer::Impl::hiz_overlay() {
    if (debugView != DebugView::Occlusion || !hizPrev.valid) return;
    // The boxes the pyramid culled, red like the Occluder path's.
    const Color red{1.0f, 0.2f, 0.2f, 1.0f};
    for (const OcclusionShown::Box& b : hizPrev.boxes)
        for (const auto& e : kBoxEdgesHiz) debug.line(b.corners[std::size_t(e[0])], b.corners[std::size_t(e[1])], red);
    // The pyramid's coarse level in the corner, nearer = brighter, black = a cell that shows no mesh in some pixel.
    if (!hizPrev.grey.empty() && hizPrev.greyW > 0 && hizPrev.greyH > 0) {
        const float cell = 3.0f, x0 = 8.0f, y0 = 56.0f;
        for (int y = 0; y < hizPrev.greyH; ++y)
            for (int x = 0; x < hizPrev.greyW; ++x) {
                const float g =
                    float(hizPrev.grey[std::size_t(y) * std::size_t(hizPrev.greyW) + std::size_t(x)]) / 255.0f;
                debug.rect(Rect{x0 + float(x) * cell, y0 + float(y) * cell, cell, cell}, Color{g, g, g, 1.0f}, true);
            }
    }
    debug.text({8.0f, 28.0f},
               std::format("depth pyramid: {} camera(s), {} tests, {} hidden (red), {}x{} cells, level {} below",
                           hizPrev.cameras, hizPrev.tests, hizPrev.hidden, hizPrev.cells, hizPrev.cellsDown,
                           hizPrev.greyLevel),
               Color::white(), 16.0f);
}

Json Renderer::Impl::hiz_report(std::string_view savePath, int level) {
    Json g = Json::object();
    g["mode"] = hizModeName;
    g["supported"] = hizSupport > 0;
    if (hizSupport < 0) g["why"] = hizWhy;
    g["active"] = hizOn && hizShown.valid;
    g["limits"] = Json::object({{"width", render::kHizWidth},
                                {"maxDilateCells", render::kHizMaxDilate},
                                {"maxAgeFrames", render::kHizMaxAgeFrames},
                                {"maxCameras", render::kHizMaxCameras}});
    const HizShown& s = hizShown;
    if (!hizOn || !s.valid) {
        g["message"] =
            hizModeName == "cpu"
                ? "SceneSettings.occlusionMode is \"cpu\": the depth pyramid is off. Hint: set it to \"auto\" (or "
                  "\"gpu\") to cull "
                  "with the GPU where the backend has compute shaders, then draw a frame (game.step) and call this "
                  "again."
                : (hizSupport < 0 ? "This GPU cannot cull with the depth pyramid (see why); the Occluders cull instead."
                                  : "No camera of the last frame was culled with the depth pyramid. Hint: draw a frame "
                                    "(game.step) "
                                    "and call this again.");
        return g;
    }
    g["camera"] = s.camera;
    g["cameras"] = s.cameras;
    g["usableCameras"] = s.usable;
    g["width"] = s.cells;
    g["height"] = s.cellsDown;
    g["levels"] = s.levels;
    g["coveredCells"] = s.coveredCells;
    g["ageFrames"] = s.ageFrames;
    g["tests"] = s.tests;
    g["hidden"] = s.hidden;
    static const char* const kWhy[8] = {"hidden",     "visible",     "noPyramid",     "cut",
                                        "behindNear", "outsideView", "tooMuchMotion", "noOccluder"};
    Json why = Json::object();
    for (std::size_t i = 0; i < 8; ++i) why[kWhy[i]] = s.reasons[i];
    g["testResults"] = why;
    if (!s.why.empty()) g["drewEverythingBecause"] = s.why;
    g["reducePasses"] = hizReduces;
    if (!savePath.empty()) {
        const HizCamera* found = nullptr;
        for (const auto& [key, hc] : hizCams)
            if (hc->pyramid.ready() && (!found || hc->name == s.camera)) found = hc.get();
        if (!found) {
            g["error"] = "no depth picture has come back from the GPU yet, so there is nothing to save. Hint: draw a "
                         "few frames (game.step) first.";
        } else {
            const int lv = std::clamp(level, 0, found->pyramid.levels() - 1);
            Image img;
            img.width = found->pyramid.width(lv);
            img.height = found->pyramid.height(lv);
            img.rgba.resize(std::size_t(img.width) * std::size_t(img.height) * 4);
            const std::vector<std::uint8_t> grey = found->pyramid.grey(lv);
            for (std::size_t i = 0; i < grey.size(); ++i) {
                img.rgba[4 * i] = img.rgba[4 * i + 1] = img.rgba[4 * i + 2] = grey[i];
                img.rgba[4 * i + 3] = 255;
            }
            const Result<void> saved = save_png(img, savePath);
            if (!saved)
                g["error"] =
                    std::format("could not write {}: {} {}", savePath, saved.error().message, saved.error().hint);
            else
                g["file"] = std::string(savePath);
            g["level"] = lv;
        }
    }
    return g;
}

}  // namespace fa
