// The Target helpers of render_internal.h (make_target, destroy_target, Target::valid, pass_into): every image and
// view is made on a gpu::Device and the Target holds the device's own handles.
#include <algorithm>
#include <string>

#include "render_internal.h"

namespace fa::render {

namespace {

bool usable(const gpu::Device& device, gpu::Image i) { return !i.id || device.state(i) == gpu::ResourceState::Valid; }
bool usable(const gpu::Device& device, gpu::View v) { return !v.id || device.state(v) == gpu::ResourceState::Valid; }

}  // namespace

bool Target::valid(const gpu::Device& device) const {
    if (!color.id) return false;
    for (gpu::Image i : {color, resolve, depth})
        if (!usable(device, i)) return false;
    for (gpu::View v : {colorAtt, resolveAtt, resolveColorAtt, depthAtt, texView})
        if (!usable(device, v)) return false;
    // A view the description asked for that the GPU did not even create (a full pool) is as bad as a failed one.
    return colorAtt.id && (!expectTexture || texView.id) && (!expectDepth || (depth.id && depthAtt.id)) &&
           (samples <= 1 || (resolve.id && resolveAtt.id));
}

Target make_target(gpu::Device& device, const TargetDesc& d) {
    Target t;
    t.w = d.width;
    t.h = d.height;
    t.samples = std::max(1, d.samples);
    t.format = TargetFormat{d.colorFormat, d.depthFormat, t.samples};
    t.expectTexture = d.texture;
    const gpu::PixelFormat colorFormat = d.colorFormat, depthFormat = d.depthFormat;
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
        t.color = device.make_image(cd);
        gpu::ViewDesc cv;
        cv.colorAttachment.image = t.color;
        cv.label = colorAttLabel.c_str();
        t.colorAtt = device.make_view(cv);
        if (msaa) {
            gpu::ImageDesc rd;
            rd.usage.resolveAttachment = true;
            rd.usage.colorAttachment = d.resolveAsColor;
            rd.width = d.width;
            rd.height = d.height;
            rd.pixelFormat = colorFormat;
            rd.sampleCount = 1;
            rd.label = resolveLabel.c_str();
            t.resolve = device.make_image(rd);
            gpu::ViewDesc rv;
            rv.resolveAttachment.image = t.resolve;
            rv.label = resolveLabel.c_str();
            t.resolveAtt = device.make_view(rv);
            if (d.resolveAsColor) {
                gpu::ViewDesc rc;
                rc.colorAttachment.image = t.resolve;
                rc.label = resolveColorLabel.c_str();
                t.resolveColorAtt = device.make_view(rc);
            }
        }
        if (d.texture) {
            gpu::ViewDesc tv;
            tv.texture.image = t.texture_image();
            tv.label = textureLabel.c_str();
            t.texView = device.make_view(tv);
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
        t.depth = device.make_image(dd);
        gpu::ViewDesc dv;
        dv.depthStencilAttachment.image = t.depth;
        dv.label = depthLabel.c_str();
        t.depthAtt = device.make_view(dv);
    }
    return t;
}

void destroy_target(gpu::Device& device, Target& t) {
    for (const gpu::View v : {t.colorAtt, t.resolveAtt, t.resolveColorAtt, t.depthAtt, t.texView})
        if (v.id) device.destroy_view(v);
    for (const gpu::Image i : {t.color, t.resolve, t.depth})
        if (i.id) device.destroy_image(i);
    t = Target{};
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
