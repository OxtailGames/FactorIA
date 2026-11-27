#include "rt_gi.h"

#include <algorithm>
#include <cmath>

#include "fa/core/log.h"
#include "fa/render/gi.h"
#include "rt_scene.h"

namespace fa::render {

// ---- the kernel's ray set ------------------------------------------------------------------------------------------------------

namespace {
constexpr float kInv24 = 1.0f / 16777216.0f;
constexpr float kTwoPi = 6.28318530717958647692f;
constexpr float kGoldenAngle = 2.39996322972865332f;
float unit_float(std::uint32_t h) { return float(h >> 8u) * kInv24; }
}  // namespace

std::uint32_t rt_gi_pcg(std::uint32_t v) {
    const std::uint32_t s = v * 747796405u + 2891336453u;
    const std::uint32_t w = ((s >> ((s >> 28u) + 4u)) ^ s) * 277803737u;
    return (w >> 22u) ^ w;
}

void rt_gi_rotation(std::uint32_t seed, std::uint32_t probe, float q[4]) {
    std::uint32_t h = rt_gi_pcg(seed ^ rt_gi_pcg(probe + 0x9E3779B9u));
    const float u1 = unit_float(h);
    h = rt_gi_pcg(h);
    const float u2 = unit_float(h);
    h = rt_gi_pcg(h);
    const float u3 = unit_float(h);
    const float a = std::sqrt(1.0f - u1), b = std::sqrt(u1);
    q[0] = a * std::sin(kTwoPi * u2);
    q[1] = a * std::cos(kTwoPi * u2);
    q[2] = b * std::sin(kTwoPi * u3);
    q[3] = b * std::cos(kTwoPi * u3);
}

Vec3 rt_gi_fibonacci(std::uint32_t i, std::uint32_t n) {
    const float y = 1.0f - (2.0f * float(i) + 1.0f) / float(n);
    const float r = std::sqrt(std::max(1.0f - y * y, 0.0f));
    const float phi = float(i) * kGoldenAngle;
    return Vec3{r * std::cos(phi), y, r * std::sin(phi)};
}

Vec3 rt_gi_rotate(const float q[4], Vec3 v) {
    const Vec3 qv{q[0], q[1], q[2]};
    const Vec3 t = cross(qv, v) * 2.0f;
    return v + t * q[3] + cross(qv, t);
}

Vec3 rt_gi_direction(const float q[4], std::uint32_t i, std::uint32_t n) {
    return rt_gi_rotate(q, rt_gi_fibonacci(i, n));
}

// ---- the pass -------------------------------------------------------------------------------------------------------------------

gpu::View RtGiProbes::records_view(Gpu& gpu, gpu::Buffer records) {
    gpu::Device& device = gpu.device();
    if (!records.id) return {};
    if (recordsView_.id && recordsBuffer_.id == records.id) return recordsView_;
    if (recordsView_.id) device.destroy_view(recordsView_);
    recordsView_ = {};
    recordsBuffer_ = {};
    gpu::ViewDesc vd{};
    vd.storageBuffer.buffer = records;
    vd.storageBuffer.structureStride =
        int(sizeof(RtInstanceRecord));  // the kernels declare StructuredBuffer<RtInstanceRecord>
    vd.label = "rt gi records";
    const gpu::View v = device.make_view(vd);
    if (!v.id || device.state(v) != gpu::ResourceState::Valid) {
        if (v.id) device.destroy_view(v);
        return {};
    }
    recordsView_ = v;
    recordsBuffer_ = records;
    return v;
}

void RtGiProbes::note_failure(const std::string& why) {
    bool say = false;
    {
        std::lock_guard<std::mutex> lock(failureMutex_);
        failure_ = why;
        say = !warned_;
        warned_ = true;
    }
    if (say)
        FA_WARN(
            "render",
            "The realtime GI probes could not be updated with rays: {}. The raster captures update the grids instead "
            "for a while, then the rays are tried again. Hint: "
            "`factoria call render.ray_tracing` shows the reason; set render.rayTracing.gi to \"off\" to silence this.",
            why);
}

std::string RtGiProbes::failure() const {
    std::lock_guard<std::mutex> lock(failureMutex_);
    return failure_;
}

bool RtGiProbes::add_pass(FrameGraph& graph, Gpu& gpu, const RtGiRequest& req, std::string* why) {
    auto refuse = [&](const std::string& reason) {
        if (why) *why = reason;
        return false;
    };
    if (!req.scene || !req.atlas.id || req.dispatches.empty())
        return refuse("the request of the GI probes is incomplete");
    if (!gpu.has_device()) return refuse("there is no graphics device");
    gpu::Device& device = gpu.device();
    if (state_ == 0) {
        const rt_kernels::RtKernel* kernel = rt_kernels::find_rt_kernel("rt_gi");
        const RtEffectKernelSpec* spec = find_rt_effect_spec("rt_gi");
        if (!kernel || !spec) {
            state_ = -1;
            why_ = "the ray traced kernel rt_gi is not in the kernel table";
        } else {
            const gpu::ShaderDesc desc = rt_effect_shader_desc(*kernel, *spec, device.backend());
            if (!desc.compute()) {
                state_ = -1;
                why_ = "the kernel rt_gi has no code for this graphics backend";
            } else {
                shader_ = device.make_shader(desc);
                if (!shader_.id || device.state(shader_) != gpu::ResourceState::Valid) {
                    if (shader_.id) gpu.destroy_shader(shader_);
                    shader_ = {};
                    state_ = -1;
                    why_ = "this device refused the kernel rt_gi";
                } else {
                    state_ = 1;
                }
            }
        }
    }
    if (state_ < 0) return refuse(why_);

    if (!image_) image_ = std::make_unique<RtGiImage>();
    RtGiImage& img = *image_;
    if (!img.image.id) {
        const gpu::PixelFormatCaps caps = device.pixel_format_caps(gpu::PixelFormat::Rgba16F);
        if (!caps.write || !caps.sample) {
            image_.reset();
            return refuse("this device cannot write a 16-bit float RGBA image from a compute shader and sample it");
        }
        gpu::ImageDesc id{};
        id.type = gpu::ImageType::Tex2d;
        id.width = kProbeAtlasSize;
        id.height = kGiBandHeight;
        id.numMipmaps = 1;
        id.sampleCount = 1;
        id.pixelFormat = gpu::PixelFormat::Rgba16F;
        id.usage.storageImage = true;
        id.label = "rt gi band";
        img.image = device.make_image(id);
        gpu::ViewDesc vd{};
        vd.storageImage.image = img.image;
        vd.label = "rt gi band storage view";
        img.storage = img.image.id ? device.make_view(vd) : gpu::View{};
        vd = gpu::ViewDesc{};
        vd.texture.image = img.image;
        vd.label = "rt gi band texture view";
        img.texture = img.image.id ? device.make_view(vd) : gpu::View{};
        const bool ok = img.image.id && device.state(img.image) == gpu::ResourceState::Valid && img.storage.id &&
                        device.state(img.storage) == gpu::ResourceState::Valid && img.texture.id &&
                        device.state(img.texture) == gpu::ResourceState::Valid;
        if (!ok) {
            if (img.storage.id) device.destroy_view(img.storage);
            if (img.texture.id) device.destroy_view(img.texture);
            if (img.image.id) device.destroy_image(img.image);
            image_.reset();
            return refuse("this device could not make the " + std::to_string(kProbeAtlasSize) + " x " +
                          std::to_string(kGiBandHeight) + " image of the GI probes");
        }
    }
    img.ran = false;
    img.lastUsed = req.frameSerial;

    GraphPass pass;
    pass.name = req.pass;
    pass.sideEffect =
        true;  // it writes the band image the renderer blends into the atlas after the graph: nothing in the graph reads it
    if (!req.after.empty()) pass.after.push_back(req.after);
    const bool needsSampler = rt_effect_needs_sampler(device.backend());
    RtScene* scene = req.scene;
    int* drawCalls = req.drawCalls;
    const gpu::Shader shader = shader_;
    const gpu::View atlas = req.atlas;
    const RtHitParams hit = req.hit;
    std::vector<RtGiDispatch> dispatches = req.dispatches;
    RtGiImage* out = &img;
    Gpu* gpuPtr = &gpu;
    pass.execute = [this, gpuPtr, scene, drawCalls, shader, atlas, hit, needsSampler, out,
                    dispatches = std::move(dispatches), name = pass.name](const PassContext& c) {
        out->ran = false;
        gpu::CommandList* list = c.commands();
        if (!list) return;
        const gpu::AccelStructure tlas = scene->tlas();  // none while the scene has no instance
        if (!tlas.valid()) return;
        const gpu::View rv = records_view(*gpuPtr, scene->records_buffer());
        if (!rv.id) return;
        const gpu::Pipeline pip = gpuPtr->compute_pipeline(shader);
        if (gpuPtr->device().state(pip) != gpu::ResourceState::Valid) {
            note_failure("the graphics driver refused the compute pipeline of the kernel rt_gi");
            return;
        }
        {
            std::lock_guard<std::mutex> lock(failureMutex_);
            failure_.clear();
        }
        gpu::Bindings b{};
        b.views[RtEffectBindings::kViewOut] = out->storage;
        b.views[RtEffectBindings::kViewPrepass] = atlas;
        b.views[RtEffectBindings::kViewRecords] = rv;
        b.accelStructures[0] = tlas;
        if (needsSampler) b.samplers[RtEffectBindings::kSampler] = gpuPtr->sampler(SamplerKind::Nearest);
        list->begin_compute_pass(name.c_str());
        list->set_pipeline(pip);
        list->set_bindings(b);
        for (const RtGiDispatch& d : dispatches) {
            list->set_uniforms(RtEffectBindings::kUniformParams, gpu::Range{&d.params, sizeof d.params});
            list->set_uniforms(RtEffectBindings::kUniformHit, gpu::Range{&hit, sizeof hit});
            list->dispatch(std::uint32_t(std::clamp<std::uint32_t>(d.params.frame[3], 1u, std::uint32_t(kRtGiMaxJobs))),
                           1, 1);
        }
        list->end_pass();
        if (drawCalls) *drawCalls += int(dispatches.size());
        out->ran = true;
    };
    graph.add_pass(std::move(pass));
    return true;
}

void RtGiProbes::sweep(Gpu& gpu, std::uint64_t serial) {
    if (!gpu.has_device() || !image_) return;
    if (image_->lastUsed + 2 >= serial) return;
    free_resources(gpu);
}

void RtGiProbes::free_resources(Gpu& gpu) {
    if (!gpu.has_device()) {
        image_.reset();
        recordsView_ = {};
        recordsBuffer_ = {};
        shader_ = {};
        if (state_ > 0) state_ = 0;
        return;
    }
    gpu::Device& device = gpu.device();
    if (image_) {
        if (image_->storage.id) device.destroy_view(image_->storage);
        if (image_->texture.id) device.destroy_view(image_->texture);
        if (image_->image.id) device.destroy_image(image_->image);
        image_.reset();
    }
    if (shader_.id) gpu.destroy_shader(shader_);
    shader_ = {};
    if (state_ > 0) state_ = 0;  // a kernel the device refused stays refused until release()
    if (recordsView_.id) device.destroy_view(recordsView_);
    recordsView_ = {};
    recordsBuffer_ = {};
}

void RtGiProbes::release(Gpu& gpu) {
    {
        std::lock_guard<std::mutex> lock(failureMutex_);
        failure_.clear();
        warned_ = false;  // turned off and on again: the reason is said again
    }
    free_resources(gpu);
    state_ = 0;
    why_.clear();
}

}  // namespace fa::render
