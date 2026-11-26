#include "rt_effect.h"

#include <algorithm>
#include <cmath>

#include "fa/core/log.h"
#include "rt_scene.h"

namespace fa::render {

namespace {

const RtEffectKernelSpec kSpecs[] = {
    // {kernel, usesRecords, usesGbuffer, usesHit, usesTlas, usesAux}
    {"rt_shadow", false, false, false, true, false},
    // Moves the soft sun shadow's denoised visibility into the layout the lit pass reads (no ray query: no TLAS).
    {"rt_shadow_pack", false, false, false, false, true},
    {"rt_ao", false, false, false, true, false},
    {"rt_reflect", true, true, true, true, false},
    // M79-P2a-3: the shadows of up to three point, spot and area lights (one visibility per channel), and the pack that puts them in the image the
    // lit pass reads next to the sun's.
    {"rt_shadow_local", false, false, false, true, false, true},
    {"rt_shadow_local_pack", false, false, false, false, true, false},
};

void set4(float* dst, double x, double y, double z, double w) {
    dst[0] = float(x);
    dst[1] = float(y);
    dst[2] = float(z);
    dst[3] = float(w);
}

struct Pt {
    double x = 0, y = 0, z = 0;
};

Pt unproject(const Mat4& inv, double nx, double ny, double nz) {
    const double v[4] = {nx, ny, nz, 1.0};
    double r[4];
    for (int row = 0; row < 4; ++row) {
        double s = 0.0;
        for (int k = 0; k < 4; ++k) s += double(inv.at(k, row)) * v[k];
        r[row] = s;
    }
    const double w = std::fabs(r[3]) > 1e-30 ? r[3] : 1.0;
    return {r[0] / w, r[1] / w, r[2] / w};
}

// The origin and the direction of the pixel rays of `inv` (an inverse view-projection matrix) as affine functions of the pixel's ndc: both are
// affine because the depth of a point of a clip-space plane z = const is the same everywhere on it (a perspective's w and an orthographic
// camera's z depend on z only), so two planes give the direction scaled to a view depth of 1 and the origin at the view depth 0.
void ray_basis(const Mat4& inv, const Vec3& pos, const Vec3& fwd, bool zeroToOne, float* o0, float* ox, float* oy,
               float* d0, float* dx, float* dy) {
    const double zA = zeroToOne ? 0.5 : 0.0, zB = zeroToOne ? 0.9 : 0.8;
    const double corners[3][2] = {{0, 0}, {1, 0}, {0, 1}};
    Pt o[3], d[3];
    for (int i = 0; i < 3; ++i) {
        const Pt a = unproject(inv, corners[i][0], corners[i][1], zA);
        const Pt b = unproject(inv, corners[i][0], corners[i][1], zB);
        Pt dir{b.x - a.x, b.y - a.y, b.z - a.z};
        const double s = dir.x * fwd.x + dir.y * fwd.y + dir.z * fwd.z;
        if (std::fabs(s) < 1e-12) {  // a degenerate matrix: look along the camera's axis, so the pixel is on it
            dir = {fwd.x, fwd.y, fwd.z};
        } else {
            dir = {dir.x / s, dir.y / s, dir.z / s};
        }
        const double depth = (a.x - pos.x) * fwd.x + (a.y - pos.y) * fwd.y + (a.z - pos.z) * fwd.z;
        d[i] = dir;
        o[i] = {a.x - dir.x * depth, a.y - dir.y * depth, a.z - dir.z * depth};
    }
    set4(o0, o[0].x, o[0].y, o[0].z, 0);
    set4(ox, o[1].x - o[0].x, o[1].y - o[0].y, o[1].z - o[0].z, 0);
    set4(oy, o[2].x - o[0].x, o[2].y - o[0].y, o[2].z - o[0].z, 0);
    set4(d0, d[0].x, d[0].y, d[0].z, 0);
    set4(dx, d[1].x - d[0].x, d[1].y - d[0].y, d[1].z - d[0].z, 0);
    set4(dy, d[2].x - d[0].x, d[2].y - d[0].y, d[2].z - d[0].z, 0);
}

}  // namespace

const RtEffectKernelSpec* find_rt_effect_spec(std::string_view kernel) {
    for (const RtEffectKernelSpec& s : kSpecs)
        if (s.kernel == kernel) return &s;
    return nullptr;
}

gpu::ShaderDesc rt_effect_shader_desc(const rt_kernels::RtKernel& kernel, const RtEffectKernelSpec& spec,
                                      gpu::Backend backend) {
    using namespace gpu;
    ShaderDesc d;
    d.label = kernel.name.data();  // the table's names are string literals
    switch (backend) {
        case Backend::D3d12:
            if (kernel.dxil.empty()) return d;
            d.computeFunc.bytecode = Range{kernel.dxil.data(), kernel.dxil.size()};
            break;
        case Backend::Vulkan:
            if (kernel.spirv.empty()) return d;
            d.computeFunc.bytecode = Range{kernel.spirv.data(), kernel.spirv.size()};
            break;
        case Backend::Metal:
        case Backend::Recording:
            if (kernel.msl.empty()) return d;
            d.computeFunc.source = kernel.msl.data();
            d.computeFunc.entry = kernel.name.data();
            d.mtlThreadsPerThreadgroup[0] = 8;
            d.mtlThreadsPerThreadgroup[1] = 8;
            d.mtlThreadsPerThreadgroup[2] = 1;
            break;
        default: return d;  // no ray queries on the other backends
    }
    if (spec.usesTlas) {
        d.usesRayQuery = true;
        // The TLAS: t0 / binding 0 / buffer(0).
        d.accelStructures[0].stage = ShaderStage::Compute;
        d.accelStructures[0].binding.hlslRegister = 0;
        d.accelStructures[0].binding.mslIndex = 0;
        d.accelStructures[0].binding.spirvSet = 0;
        d.accelStructures[0].binding.spirvBinding = 0;
    }
    // The constants: b0 / binding 2 / buffer(1).
    d.uniformBlocks[RtEffectBindings::kUniformParams].stage = ShaderStage::Compute;
    d.uniformBlocks[RtEffectBindings::kUniformParams].size = std::uint32_t(sizeof(RtEffectParams));
    d.uniformBlocks[RtEffectBindings::kUniformParams].binding.hlslRegister = 0;
    d.uniformBlocks[RtEffectBindings::kUniformParams].binding.mslIndex = 1;
    d.uniformBlocks[RtEffectBindings::kUniformParams].binding.spirvSet = 0;
    d.uniformBlocks[RtEffectBindings::kUniformParams].binding.spirvBinding = 2;
    // The output: u0 / binding 1 / texture(0).
    ShaderStorageImageView& out = d.views[RtEffectBindings::kViewOut].storageImage;
    out.stage = ShaderStage::Compute;
    out.imageType = ImageType::Tex2d;
    out.accessFormat = PixelFormat::Rgba32F;
    out.writeonly = true;
    out.binding.hlslRegister = 0;
    out.binding.mslIndex = 0;
    out.binding.spirvSet = 0;
    out.binding.spirvBinding = 1;
    auto texture = [&](int slot, int reg, int msl, int vk) {
        ShaderTextureView& t = d.views[slot].texture;
        t.stage = ShaderStage::Compute;
        t.imageType = ImageType::Tex2d;
        t.sampleType = ImageSampleType::UnfilterableFloat;
        t.binding.hlslRegister = std::uint8_t(reg);
        t.binding.mslIndex = std::uint8_t(msl);
        t.binding.spirvSet = 0;
        t.binding.spirvBinding = std::uint8_t(vk);
    };
    texture(RtEffectBindings::kViewPrepass, 1, 1, 3);  // t1 / binding 3 / texture(1)
    if (spec.usesRecords) {  // t2 / binding 4 / buffer(8): Sokol's Metal numbers the storage buffers 8 .. 23 (the uniform blocks 0 .. 7)
        ShaderStorageBufferView& r = d.views[RtEffectBindings::kViewRecords].storageBuffer;
        r.stage = ShaderStage::Compute;
        r.readonly = true;
        r.binding.hlslRegister = 2;
        r.binding.mslIndex = 8;
        r.binding.spirvSet = 0;
        r.binding.spirvBinding = 4;
    }
    if (spec.usesGbuffer) {
        texture(RtEffectBindings::kViewAlbedo, 3, 2, 5);    // t3 / binding 5 / texture(2)
        texture(RtEffectBindings::kViewMaterial, 4, 3, 6);  // t4 / binding 6 / texture(3)
    }
    if (spec.usesAux) texture(RtEffectBindings::kViewAux, 5, 4, 7);  // t5 / binding 7 / texture(4)
    if (spec.usesHit || spec.usesLocal) {                            // b1 / binding 7 / buffer(3)
        ShaderUniformBlock& h = d.uniformBlocks[RtEffectBindings::kUniformHit];
        h.stage = ShaderStage::Compute;
        h.size = std::uint32_t(spec.usesLocal ? sizeof(RtLocalParams) : sizeof(RtHitParams));
        h.binding.hlslRegister = 1;
        h.binding.mslIndex = 3;
        h.binding.spirvSet = 0;
        h.binding.spirvBinding = 7;
    }
    if (rt_effect_needs_sampler(backend)) {
        // Sokol (Metal) wants every texture view paired with a sampler slot even when the kernel reads the texel with `read`: the nearest one.
        d.samplers[RtEffectBindings::kSampler].stage = ShaderStage::Compute;
        d.samplers[RtEffectBindings::kSampler].samplerType = SamplerType::Nonfiltering;
        d.samplers[RtEffectBindings::kSampler].binding.mslIndex = 0;
        int pairs = 0;
        for (int slot = 0; slot < kMaxViews; ++slot) {
            if (d.views[slot].texture.stage != ShaderStage::Compute) continue;
            d.textureSamplerPairs[pairs].stage = ShaderStage::Compute;
            d.textureSamplerPairs[pairs].viewSlot = std::uint8_t(slot);
            d.textureSamplerPairs[pairs].samplerSlot = std::uint8_t(RtEffectBindings::kSampler);
            ++pairs;
        }
    }
    return d;
}

bool rt_effect_needs_sampler(gpu::Backend backend) {
    return backend == gpu::Backend::Metal || backend == gpu::Backend::Recording;
}

void fill_rt_effect_camera(RtEffectParams& p, const CameraGeometry& cam, int w, int h, bool zeroToOne) {
    const double fw = double(std::max(w, 1)), fh = double(std::max(h, 1));
    set4(p.camera, cam.position.x, cam.position.y, cam.position.z, cam.perspective ? 0.0 : 1.0);
    set4(p.image, fw, fh, 1.0 / fw, 1.0 / fh);
    ray_basis(cam.drawInvViewProj, cam.position, cam.forward, zeroToOne, p.rayO0, p.rayOX, p.rayOY, p.rayD0, p.rayDX,
              p.rayDY);
    ray_basis(cam.invViewProj, cam.position, cam.forward, zeroToOne, p.uRayO0, p.uRayOX, p.uRayOY, p.uRayD0, p.uRayDX,
              p.uRayDY);
    set4(p.viewRight, cam.right.x, cam.right.y, cam.right.z, 0);
    set4(p.viewUp, cam.up.x, cam.up.y, cam.up.z, 0);
    set4(p.viewBack, -cam.forward.x, -cam.forward.y, -cam.forward.z, 0);
    float* rows[4] = {p.viewProj0, p.viewProj1, p.viewProj2, p.viewProj3};
    for (int r = 0; r < 4; ++r)
        for (int c = 0; c < 4; ++c) rows[r][c] = cam.viewProj.at(c, r);
}

std::uint32_t rt_effect_seed(std::uint64_t frameSerial) {
    std::uint64_t z = frameSerial + 0x9E3779B97F4A7C15ull;  // splitmix64
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ull;
    z = (z ^ (z >> 27)) * 0x94D049BB133111EBull;
    z ^= z >> 31;
    return std::uint32_t(z >> 32);
}

RtEffects::Kernel* RtEffects::kernel_for(Gpu& gpu, const rt_kernels::RtKernel& k, const RtEffectKernelSpec& spec,
                                         std::string* why) {
    Kernel& kn = kernels_[std::string(k.name)];
    if (kn.state == 0) {
        gpu::Device& device = gpu.device();
        const gpu::ShaderDesc desc = rt_effect_shader_desc(k, spec, device.backend());
        if (!desc.compute()) {
            kn.state = -1;
            kn.why = std::string("the kernel ") + std::string(k.name) + " has no code for this graphics backend";
        } else {
            kn.shader = device.make_shader(desc);
            if (!kn.shader.id || device.state(kn.shader) != gpu::ResourceState::Valid) {
                if (kn.shader.id) gpu.destroy_shader(kn.shader);
                kn.shader = {};
                kn.state = -1;
                kn.why = std::string("this device refused the kernel ") + std::string(k.name);
            } else {
                kn.state = 1;
            }
        }
    }
    if (kn.state < 0) {
        if (why) *why = kn.why;
        return nullptr;
    }
    return &kn;
}

gpu::View RtEffects::records_view(Gpu& gpu, gpu::Buffer records) {
    gpu::Device& device = gpu.device();
    if (!records.id) return {};
    if (recordsView_.id && recordsBuffer_.id == records.id) return recordsView_;
    if (recordsView_.id) device.destroy_view(recordsView_);
    recordsView_ = {};
    recordsBuffer_ = {};
    gpu::ViewDesc vd{};
    vd.storageBuffer.buffer = records;
    vd.label = "rt effect records";
    const gpu::View v = device.make_view(vd);
    if (!v.id || device.state(v) != gpu::ResourceState::Valid) {
        if (v.id) device.destroy_view(v);
        return {};
    }
    recordsView_ = v;
    recordsBuffer_ = records;
    return v;
}

RtEffectOutput RtEffects::add_pass(FrameGraph& graph, Gpu& gpu, const RtEffectRequest& req) {
    RtEffectOutput result;
    const rt_kernels::RtKernel* kernel = rt_kernels::find_rt_kernel(req.kernel);
    const RtEffectKernelSpec* spec = find_rt_effect_spec(req.kernel);
    if (!kernel || !spec) {
        result.why = "the ray traced kernel \"" + req.kernel + "\" is not in the kernel table";
        return result;
    }
    const bool fromImage = req.srcImage != nullptr;
    const bool auxFromImage = req.auxImage != nullptr;
    if (!req.camera || !req.scene || !(fromImage ? req.srcRes.valid() : req.prepass.valid()) || req.width < 1 ||
        req.height < 1 || (spec->usesHit && !spec->usesRecords) || (spec->usesHit && spec->usesAux) ||
        (spec->usesLocal && (spec->usesHit || spec->usesAux)) ||
        (spec->usesGbuffer && !(req.gbufferAlbedo.valid() && req.gbufferMaterial.valid())) ||
        (spec->usesAux && !(auxFromImage ? req.auxRes.valid() : req.aux.valid()))) {
        result.why = "the request of " + req.effect + " lacks its camera, its scene, its prepass or its size";
        return result;
    }
    if (!gpu.has_device()) {
        result.why = "there is no graphics device";
        return result;
    }
    gpu::Device& device = gpu.device();
    Kernel* kn = kernel_for(gpu, *kernel, *spec, &result.why);
    if (!kn) return result;
    kn->lastUsed = req.frameSerial;

    // The output image: one per effect and camera, made again when the camera's rectangle changes size.
    const std::string key = req.job + "/" + req.effect;
    std::unique_ptr<RtEffectImage>& slot = images_[key];
    if (!slot) slot = std::make_unique<RtEffectImage>();
    RtEffectImage& img = *slot;
    if (img.image.id && (img.width != req.width || img.height != req.height)) {
        device.destroy_view(img.storage);
        device.destroy_view(img.texture);
        device.destroy_image(img.image);
        img = RtEffectImage{};
    }
    if (!img.image.id) {
        const gpu::PixelFormatCaps caps = device.pixel_format_caps(gpu::PixelFormat::Rgba32F);
        if (!caps.write || !caps.sample) {
            result.why = "this device cannot write a 32-bit float RGBA image from a compute shader and sample it";
            images_.erase(key);
            return result;
        }
        gpu::ImageDesc id{};
        id.type = gpu::ImageType::Tex2d;
        id.width = req.width;
        id.height = req.height;
        id.numMipmaps = 1;
        id.sampleCount = 1;
        id.pixelFormat = gpu::PixelFormat::Rgba32F;
        id.usage.storageImage = true;
        const std::string label = "rt " + req.effect + " " + req.job;
        id.label = label.c_str();
        img.image = device.make_image(id);
        gpu::ViewDesc vd{};
        vd.storageImage.image = img.image;
        vd.label = "rt effect storage view";
        img.storage = img.image.id ? device.make_view(vd) : gpu::View{};
        vd = gpu::ViewDesc{};
        vd.texture.image = img.image;
        vd.label = "rt effect texture view";
        img.texture = img.image.id ? device.make_view(vd) : gpu::View{};
        const bool ok = img.image.id && device.state(img.image) == gpu::ResourceState::Valid && img.storage.id &&
                        device.state(img.storage) == gpu::ResourceState::Valid && img.texture.id &&
                        device.state(img.texture) == gpu::ResourceState::Valid;
        if (!ok) {
            if (img.storage.id) device.destroy_view(img.storage);
            if (img.texture.id) device.destroy_view(img.texture);
            if (img.image.id) device.destroy_image(img.image);
            images_.erase(key);
            result.why = "this device could not make the " + std::to_string(req.width) + " x " +
                         std::to_string(req.height) + " image of the effect";
            return result;
        }
        img.width = req.width;
        img.height = req.height;
    }
    img.ran = false;
    img.lastUsed = req.frameSerial;

    RtEffectParams params{};
    fill_rt_effect_camera(params, *req.camera, req.width, req.height, req.zeroToOne);
    set4(params.lightDir, req.lightDir[0], req.lightDir[1], req.lightDir[2], 0.0);
    params.frame[0] = std::uint32_t(req.frameSerial);
    params.frame[1] = rt_effect_seed(req.frameSerial);
    params.frame[2] = std::uint32_t(std::clamp(req.raysPerPixel, 1, 64));
    params.frame[3] = 0;
    for (int i = 0; i < 4; ++i) {
        params.user0[i] = req.user0[i];
        params.user1[i] = req.user1[i];
    }

    TransientDesc imp;
    imp.width = req.width;
    imp.height = req.height;
    imp.format = TargetFormat{gpu::PixelFormat::Rgba32F, gpu::PixelFormat::None, 1};
    imp.label = req.job + "/rt-" + req.effect + "-image";
    result.res = graph.import_target(imp.label, std::uint64_t(img.image.id), imp);

    GraphPass pass;
    pass.name = req.job + "/rt-" + req.effect;
    pass.reads.push_back(fromImage ? req.srcRes : req.prepass.res);
    if (spec->usesAux) pass.reads.push_back(auxFromImage ? req.auxRes : req.aux.res);
    if (spec->usesGbuffer) {
        pass.reads.push_back(req.gbufferAlbedo.res);
        pass.reads.push_back(req.gbufferMaterial.res);
    }
    pass.writes.push_back(result.res);
    if (!req.after.empty()) pass.after.push_back(req.after);
    const bool usesRecords = spec->usesRecords, usesGbuffer = spec->usesGbuffer, usesHit = spec->usesHit,
               usesTlas = spec->usesTlas, usesAux = spec->usesAux, usesLocal = spec->usesLocal;
    const RtHitParams hit = req.hit;
    const RtLocalParams local = req.local;
    const RtEffectImage* srcImage = req.srcImage;
    const RtEffectImage* auxImage = req.auxImage;
    const PrepassRef aux = req.aux;
    const bool needsSampler = rt_effect_needs_sampler(gpu.device().backend());
    const PrepassRef prepass = req.prepass, albedo = req.gbufferAlbedo, material = req.gbufferMaterial;
    RtScene* scene = req.scene;
    int* drawCalls = req.drawCalls;
    const gpu::Shader shader = kn->shader;
    RtEffectImage* out = &img;
    Gpu* gpuPtr = &gpu;
    pass.execute = [this, gpuPtr, scene, drawCalls, shader, out, prepass, albedo, material, aux, srcImage, auxImage,
                    usesRecords, usesGbuffer, usesHit, usesTlas, usesAux, usesLocal, needsSampler, params, hit, local, key,
                    name = pass.name](const PassContext& c) {
        out->ran = false;
        gpu::CommandList* list = c.commands();
        if (!list) return;
        gpu::AccelStructure tlas{};
        if (usesTlas) {
            tlas = scene->tlas();  // none while the scene has no instance: the lit pass keeps its own shadows
            if (!tlas.valid()) return;
        }
        gpu::View inView{};
        if (srcImage) {
            // The image of another effect: nothing to do when that one did not run this frame (it says why itself).
            if (!srcImage->ran || srcImage->width != out->width || srcImage->height != out->height) return;
            inView = srcImage->texture;
        } else {
            const Target* pre = prepass.target(c);
            if (!pre || !pre->texView.id) return;
            if (pre->w != out->width || pre->h != out->height) {
                // The prepass has another size than the image this pass was declared for (a resize between the plan and the frame): the
                // next frame makes the image again; say so once so a mismatch that lasts is not silent.
                note_failure(key, "the prepass is " + std::to_string(pre->w) + " x " + std::to_string(pre->h) +
                                      " but the effect's image is " + std::to_string(out->width) + " x " +
                                      std::to_string(out->height));
                return;
            }
            inView = pre->texView;
        }
        gpu::View auxView{};
        if (usesAux && auxImage) {
            // The image of another effect (the local shadows' trace, when it is not denoised): nothing to do when it did not run this frame.
            if (!auxImage->ran || auxImage->width != out->width || auxImage->height != out->height) return;
            auxView = auxImage->texture;
        } else if (usesAux) {
            const Target* a = aux.target(c);
            if (!a || !a->texView.id) return;
            auxView = a->texView;
        }
        gpu::Bindings b{};
        b.views[RtEffectBindings::kViewOut] = out->storage;
        b.views[RtEffectBindings::kViewPrepass] = inView;
        if (usesAux) b.views[RtEffectBindings::kViewAux] = auxView;
        if (usesTlas) b.accelStructures[0] = tlas;
        if (needsSampler) b.samplers[RtEffectBindings::kSampler] = gpuPtr->sampler(SamplerKind::Nearest);
        if (usesRecords) {
            const gpu::View rv = records_view(*gpuPtr, scene->records_buffer());
            if (!rv.id) return;
            b.views[RtEffectBindings::kViewRecords] = rv;
        }
        if (usesGbuffer) {
            const Target* a = albedo.target(c);
            const Target* m = material.target(c);
            if (!a || !m || !a->texView.id || !m->texView.id) return;
            b.views[RtEffectBindings::kViewAlbedo] = a->texView;
            b.views[RtEffectBindings::kViewMaterial] = m->texView;
        }
        const gpu::Pipeline pip = gpuPtr->compute_pipeline(shader);
        if (gpuPtr->device().state(pip) != gpu::ResourceState::Valid) {
            note_failure(key, "the graphics driver refused the compute pipeline of the kernel " + name);
            return;
        }
        clear_failure(key);
        list->begin_compute_pass(name.c_str());
        list->set_pipeline(pip);
        list->set_bindings(b);
        list->set_uniforms(RtEffectBindings::kUniformParams, gpu::Range{&params, sizeof params});
        if (usesHit) list->set_uniforms(RtEffectBindings::kUniformHit, gpu::Range{&hit, sizeof hit});
        if (usesLocal) list->set_uniforms(RtEffectBindings::kUniformHit, gpu::Range{&local, sizeof local});
        list->dispatch((out->width + 7) / 8, (out->height + 7) / 8, 1);
        list->end_pass();
        if (drawCalls) ++*drawCalls;
        out->ran = true;
    };
    graph.add_pass(std::move(pass));
    result.valid = true;
    result.out = &img;
    return result;
}

void RtEffects::note_failure(const std::string& key, const std::string& why) {
    bool say = false;
    {
        std::lock_guard<std::mutex> lock(failureMutex_);
        failures_[key] = why;
        say = warned_.insert(key + "\n" + why).second;
    }
    if (say)
        FA_WARN("render",
                "A ray traced effect ({}) could not run: {}. The raster version of the effect is drawn instead. Hint: "
                "`factoria call "
                "render.ray_tracing` shows the reason; set render.rayTracing.shadows to \"off\" to silence this.",
                key, why);
}

void RtEffects::clear_failure(const std::string& key) {
    std::lock_guard<std::mutex> lock(failureMutex_);
    failures_.erase(key);
}

std::string RtEffects::failure() const {
    std::lock_guard<std::mutex> lock(failureMutex_);
    for (const auto& [key, why] : failures_)
        if (!why.empty()) return key + ": " + why;
    return std::string();
}

void RtEffects::sweep(Gpu& gpu, std::uint64_t serial) {
    if (!gpu.has_device()) return;
    gpu::Device& device = gpu.device();
    for (auto it = images_.begin(); it != images_.end();) {
        RtEffectImage& img = *it->second;
        if (img.lastUsed + 2 < serial) {
            if (img.storage.id) device.destroy_view(img.storage);
            if (img.texture.id) device.destroy_view(img.texture);
            if (img.image.id) device.destroy_image(img.image);
            clear_failure(it->first);
            it = images_.erase(it);
        } else {
            ++it;
        }
    }
    // A kernel no request used for two frames goes (the soft shadows' pack kernel when the setting goes back to hard); a kernel the device
    // refused stays, so it is not tried every frame.
    for (auto it = kernels_.begin(); it != kernels_.end();) {
        if (it->second.state >= 0 && it->second.lastUsed + 2 < serial) {
            if (it->second.shader.id) gpu.destroy_shader(it->second.shader);
            it = kernels_.erase(it);
        } else {
            ++it;
        }
    }
    if (!images_.empty()) return;
    // Nothing asks any more: the records view goes too.
    if (recordsView_.id) device.destroy_view(recordsView_);
    recordsView_ = {};
    recordsBuffer_ = {};
}

void RtEffects::release(Gpu& gpu) {
    {
        std::lock_guard<std::mutex> lock(failureMutex_);
        failures_.clear();
        warned_.clear();  // turned off and on again: the reasons are said again
    }
    if (!gpu.has_device()) {
        images_.clear();
        kernels_.clear();
        recordsView_ = {};
        recordsBuffer_ = {};
        return;
    }
    gpu::Device& device = gpu.device();
    for (auto& [key, img] : images_) {
        if (img->storage.id) device.destroy_view(img->storage);
        if (img->texture.id) device.destroy_view(img->texture);
        if (img->image.id) device.destroy_image(img->image);
    }
    images_.clear();
    for (auto& [name, k] : kernels_)
        if (k.shader.id) gpu.destroy_shader(k.shader);
    kernels_.clear();
    if (recordsView_.id) device.destroy_view(recordsView_);
    recordsView_ = {};
    recordsBuffer_ = {};
}

}  // namespace fa::render
