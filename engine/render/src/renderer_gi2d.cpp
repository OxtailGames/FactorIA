// The renderer's side of the 2D GI field that reads the GPU: the `render.gi2d_field` report (and the PNG files it can write) and the test
// access to the field's images. The passes that fill the field are Gi2dSystem::add_passes (gi2d.cpp).
#include <algorithm>
#include <cmath>
#include <format>

#include "fa/core/image.h"
#include "fa/render/renderer.h"

#include "gi2d.h"
#include "renderer_impl.h"
#include "renderer_test_access.h"

namespace fa {

namespace {

std::uint8_t to_byte(float v) {
    if (!(v > 0.0f)) return 0;
    if (v >= 1.0f) return 255;
    return std::uint8_t(std::lround(double(v) * 255.0));
}

// The field image `which` (0 emission, 1 occluders, 2 distance, 3 the irradiance of the last frame that ran) of `f` as floats, row 0 = the
// smallest world y. The irradiance image has one texel per probe of cascade 0 (Gi2dCascadePlan::gridW x gridH).
bool read_image(render::Gpu& gpu, const render::Gi2dField& f, int which, std::vector<float>& out, std::string* error) {
    if (!gpu.committed()) {  // as read_floats: the work of the frame is submitted before a read-back waits for it
        sg_commit();
        gpu.note_commit();
    }
    const render::Target& t = which == 0   ? f.emission
                              : which == 1 ? f.occluder
                              : which == 2 ? f.distance
                                           : f.irradiance[f.irrCur];
    return render::gi2d_read(t, gpu.is_gl(), out, error);
}

// A PNG of a field image: row 0 of the file is the largest world y (the way a picture of the world is read). Emission and albedo are written
// as stored, clamped to 0..1; the occluder's alpha is its occupancy; the distance is grey, 0 at an occluder and 1 at the largest distance of
// the field, and white where the field has no occluder at all.
Image make_png(const std::vector<float>& px, int w, int h, int which) {
    Image img;
    img.width = w;
    img.height = h;
    img.rgba.assign(std::size_t(w) * std::size_t(h) * 4u, 255);
    float maxDist = 0.0f;
    if (which == 2) {
        for (std::size_t i = 0; i < std::size_t(w) * std::size_t(h); ++i) {
            const float d = px[i * 4 + 2];
            if (px[i * 4 + 3] > 0.5f && d < render::kGi2dNoDistance && d > maxDist) maxDist = d;
        }
    }
    for (int row = 0; row < h; ++row) {
        const int src = h - 1 - row;
        for (int x = 0; x < w; ++x) {
            const float* p = &px[(std::size_t(src) * std::size_t(w) + std::size_t(x)) * 4u];
            std::uint8_t* o = &img.rgba[(std::size_t(row) * std::size_t(w) + std::size_t(x)) * 4u];
            if (which == 0) {
                o[0] = to_byte(p[0]);
                o[1] = to_byte(p[1]);
                o[2] = to_byte(p[2]);
                o[3] = 255;
            } else if (which == 1 ||
                       which == 3) {  // the irradiance's alpha is its validity (rgb is stored premultiplied by it)
                o[0] = to_byte(p[0]);
                o[1] = to_byte(p[1]);
                o[2] = to_byte(p[2]);
                o[3] = to_byte(p[3]);
            } else {
                const bool found = p[3] > 0.5f && p[2] < render::kGi2dNoDistance;
                const float g = !found ? 1.0f : maxDist > 0.0f ? p[2] / maxDist : 0.0f;
                o[0] = o[1] = o[2] = to_byte(g);
                o[3] = 255;
            }
        }
    }
    return img;
}

}  // namespace

Json Renderer::gi2d_field(std::string_view savePrefix, std::string_view job) {
    if (!initialized()) return Json::object();
    Impl& im = *impl_;
    Json out = im.gi2d.report(im.gpu.device(), backend_name());
    if (savePrefix.empty()) return out;
    const std::string jobName(job);
    render::Gi2dField* f = im.gi2d.find(jobName);
    if (!f) {
        out["error"] =
            jobName.empty()
                ? "no field to save: the last frame drew none. Hint: add a GlobalIllumination2D with enabled true to "
                  "the scene "
                  "and an orthographic camera, then draw a frame."
                : std::format(
                      "no field to save for the job '{}'. Hint: the \"job\" values of fields[] say which exist.",
                      jobName);
        return out;
    }
    static const char* const names[4] = {"emission", "occluders", "distance", "irradiance"};
    Json files = Json::array();
    for (int which = 0; which < (f->cascade.ok && f->irrValid ? 4 : 3); ++which) {
        std::vector<float> px;
        std::string error;
        if (!read_image(im.gpu, *f, which, px, &error)) {
            out["error"] = std::format("the {} image could not be read back: {}", names[which], error);
            break;
        }
        const Image img = make_png(px, which == 3 ? f->cascade.gridW : f->geom.width,
                                   which == 3 ? f->cascade.gridH : f->geom.height, which);
        const std::string path = std::string(savePrefix) + "-" + names[which] + ".png";
        const Result<void> saved = save_png(img, path);
        if (!saved) {
            out["error"] = std::format("could not write {}: {} {}", path, saved.error().message, saved.error().hint);
            break;
        }
        files.push_back(path);
    }
    out["files"] = std::move(files);
    return out;
}

bool RendererTestAccess::gi2d_read(Renderer& r, int slot, int which, std::vector<float>& out, std::string* error) {
    if (!r.initialized()) {
        if (error) *error = "Renderer is not initialized";
        return false;
    }
    render::Gi2dField* f = r.impl_->gi2d.slot(slot);
    if (!f || !f->valid || (which == 3 && !f->irrValid)) {
        if (error) *error = "the slot holds no finished field";
        return false;
    }
    return read_image(r.impl_->gpu, *f, which, out, error);
}

render::Gi2dFieldInfo RendererTestAccess::gi2d_info(Renderer& r, int slot) {
    render::Gi2dFieldInfo info;
    if (!r.initialized()) return info;
    const render::Gi2dField* f = r.impl_->gi2d.slot(slot);
    if (!f) return info;
    info.exists = true;
    info.ready = f->valid;
    info.width = f->geom.width;
    info.height = f->geom.height;
    info.texel = f->geom.texel;
    info.originX = f->geom.originX;
    info.originY = f->geom.originY;
    info.passes = f->passes;
    info.cascades = f->cascade.ok ? f->cascade.cascades : 0;
    info.probeSpacing = f->cascade.spacing0;
    info.irradianceWidth = f->cascade.gridW;
    info.irradianceHeight = f->cascade.gridH;
    info.irradianceReady = f->irrValid;
    info.primed = f->primed;
    info.history = f->irrValid;
    info.emitters = f->stats.emissiveSprites + f->stats.emissiveTiles + f->stats.lights;
    info.occluders = f->stats.solidTiles + f->stats.boxes + f->stats.polygons + f->stats.spriteCasters;
    return info;
}

int RendererTestAccess::gi2d_slots_in_use(Renderer& r) {
    if (!r.initialized()) return 0;
    int n = 0;
    for (int i = 0; i < r.impl_->gi2d.slot_count(); ++i) n += r.impl_->gi2d.slot(i) ? 1 : 0;
    return n;
}

}  // namespace fa
