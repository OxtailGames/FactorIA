// Window-less GPU context for macOS / iOS: a Metal device with no view or
// layer. UNTESTED: written without an Apple toolchain on the development
// machine. (Objective-C++ because it implements the C++ HeadlessGpu class.)
#import <Metal/Metal.h>

#include <cstring>
#include <format>
#include <string>

#include "fa/platform/app.h"
#include "sokol_gfx.h"

namespace fa {

struct HeadlessGpu::Impl {
    id<MTLDevice> device = nil;
    bool valid = false;
    std::string description;
};

HeadlessGpu::HeadlessGpu() = default;
HeadlessGpu::~HeadlessGpu() { shutdown(); }

bool HeadlessGpu::init(std::string* error) {
    if (impl_) return true;
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (device == nil) {
        if (error) {
            *error = "MTLCreateSystemDefaultDevice() returned nil: no Metal-capable GPU is available. "
                     "Run on a Mac with Metal support (virtual machines and some CI runners have none).";
        }
        return false;
    }
    impl_ = new Impl();
    impl_->device = device;  // ARC keeps it alive
    impl_->description = std::format("Metal / {}", std::string([[device name] UTF8String]));
    impl_->valid = true;
    return true;
}

void HeadlessGpu::shutdown() {
    if (!impl_) return;
    impl_->device = nil;
    delete impl_;
    impl_ = nullptr;
}

bool HeadlessGpu::valid() const { return impl_ && impl_->valid; }

GfxEnvironment HeadlessGpu::environment() const {
    GfxEnvironment out{};
    sg_environment env{};
    env.defaults.color_format = SG_PIXELFORMAT_BGRA8;
    env.defaults.depth_format = SG_PIXELFORMAT_DEPTH_STENCIL;
    env.defaults.sample_count = 1;
    if (impl_) env.metal.device = (__bridge const void*)impl_->device;
    std::memcpy(out.storage, &env, sizeof(env));
    return out;
}

const char* HeadlessGpu::description() const { return impl_ ? impl_->description.c_str() : "not initialized"; }

// Rendering submits through sokol's own command buffer in sg_commit(); nothing to do here.
void HeadlessGpu::end_frame() {}

}  // namespace fa
