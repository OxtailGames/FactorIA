// The Target helpers of render_internal.h (make_target, destroy_target, Target::valid, pass_into): every image and
// view is made on a gpu::Device (Target still holds them as sokol handles for the passes: gpu::to_sg / from_sg). The overloads without a device use Gpu::active_device() (TRANSITIONAL, M77-P2..P4:
// the passes pass their Gpu's device once they are converted).
#include <algorithm>
#include <string>

#include "render_internal.h"

namespace fa::render {

namespace {

bool usable(const gpu::Device& device, gpu::Image i) { return !i.id || device.state(i) == gpu::ResourceState::Valid; }
bool usable(const gpu::Device& device, gpu::View v) { return !v.id || device.state(v) == gpu::ResourceState::Valid; }

bool empty(const Target& t) {
    return !t.color.id && !t.resolve.id && !t.depth.id && !t.colorAtt.id && !t.resolveAtt.id && !t.resolveColorAtt.id &&
           !t.depthAtt.id && !t.texView.id;
}

}  // namespace

bool Target::valid(const gpu::Device& device) const {
    if (!color.id) return false;
    for (sg_image i : {color, resolve, depth})
        if (!usable(device, gpu::from_sg(i))) return false;
    for (sg_view v : {colorAtt, resolveAtt, resolveColorAtt, depthAtt, texView})
        if (!usable(device, gpu::from_sg(v))) return false;
    // A view the description asked for that the GPU did not even create (a full pool) is as bad as a failed one.
    return colorAtt.id && (!expectTexture || texView.id) && (!expectDepth || (depth.id && depthAtt.id)) &&
           (samples <= 1 || (resolve.id && resolveAtt.id));
}

bool Target::valid() const { return color.id && valid(Gpu::active_device()); }

Target make_target(gpu::Device& device, const TargetDesc& d) {
    Target t;
    t.w = d.width;
    t.h = d.height;
    t.samples = std::max(1, d.samples);
    t.format = TargetFormat{d.colorFormat, d.depthFormat, t.samples};
    t.expectTexture = d.texture;
    const gpu::PixelFormat colorFormat = gpu::from_sg(d.colorFormat), depthFormat = gpu::from_sg(d.depthFormat);
    t.expectDepth = depthFormat != gpu::PixelFormat::None;
    const std::string base = d.label ? d.label : "target";
    const std::string colorLabel = base + "-color", colorAttLabel = base + "-color-att",
                      resolveLabel = base + "-resolve", resolveColorLabel = base + "-resolve-color-att",
                      textureLabel = base + "-texture", depthLabel = base + "-depth";
    const bool msaa = t.samples > 1;
    if (colorFormat != gpu::PixelFormat::None) {
        gpu::ImageDesc cd;
        cd.usage.colorAttachment = true;
        cd.usage.storageImage = d.storage && !msaa;
        cd.width = d.width;
        cd.height = d.height;
        cd.pixelFormat = colorFormat;
        cd.sampleCount = t.samples;
        cd.label = colorLabel.c_str();
        t.color = gpu::to_sg(device.make_image(cd));
        gpu::ViewDesc cv;
        cv.colorAttachment.image = gpu::from_sg(t.color);
        cv.label = colorAttLabel.c_str();
        t.colorAtt = gpu::to_sg(device.make_view(cv));
        if (msaa) {
            gpu::ImageDesc rd;
            rd.usage.resolveAttachment = true;
            rd.usage.colorAttachment = d.resolveAsColor;
            rd.width = d.width;
            rd.height = d.height;
            rd.pixelFormat = colorFormat;
            rd.sampleCount = 1;
            rd.label = resolveLabel.c_str();
            t.resolve = gpu::to_sg(device.make_image(rd));
            gpu::ViewDesc rv;
            rv.resolveAttachment.image = gpu::from_sg(t.resolve);
            rv.label = resolveLabel.c_str();
            t.resolveAtt = gpu::to_sg(device.make_view(rv));
            if (d.resolveAsColor) {
                gpu::ViewDesc rc;
                rc.colorAttachment.image = gpu::from_sg(t.resolve);
                rc.label = resolveColorLabel.c_str();
                t.resolveColorAtt = gpu::to_sg(device.make_view(rc));
            }
        }
        if (d.texture) {
            gpu::ViewDesc tv;
            tv.texture.image = gpu::from_sg(t.texture_image());
            tv.label = textureLabel.c_str();
            t.texView = gpu::to_sg(device.make_view(tv));
        }
    }
    if (depthFormat != gpu::PixelFormat::None) {
        gpu::ImageDesc dd;
        dd.usage.depthStencilAttachment = true;
        dd.width = d.width;
        dd.height = d.height;
        dd.pixelFormat = depthFormat;
        dd.sampleCount = t.samples;
        dd.label = depthLabel.c_str();
        t.depth = gpu::to_sg(device.make_image(dd));
        gpu::ViewDesc dv;
        dv.depthStencilAttachment.image = gpu::from_sg(t.depth);
        dv.label = depthLabel.c_str();
        t.depthAtt = gpu::to_sg(device.make_view(dv));
    }
    return t;
}

Target make_target(const TargetDesc& d) { return make_target(Gpu::active_device(), d); }

void destroy_target(gpu::Device& device, Target& t) {
    for (const sg_view v : {t.colorAtt, t.resolveAtt, t.resolveColorAtt, t.depthAtt, t.texView})
        if (v.id) device.destroy_view(gpu::from_sg(v));
    for (const sg_image i : {t.color, t.resolve, t.depth})
        if (i.id) device.destroy_image(gpu::from_sg(i));
    t = Target{};
}

void destroy_target(Target& t) {
    if (empty(t)) {
        t = Target{};  // nothing to free: no device needed (a second destroy, a target never made)
        return;
    }
    destroy_target(Gpu::active_device(), t);
}

PassDesc pass_into(const Target& t, const char* label) {
    PassDesc p;
    p.label = label;
    p.color = t.colorAtt;
    if (t.samples > 1) p.resolve = t.resolveAtt;
    p.depth = t.depthAtt;
    p.format = t.format;
    return p;
}

}  // namespace fa::render
