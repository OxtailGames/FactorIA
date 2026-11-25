// MetalFX (metalfx.h) where there is none: every backend that is not Metal. metalfx_apple.mm is the real one.
#include "metalfx.h"

#if !defined(SOKOL_METAL)

namespace fa::render::metalfx {

namespace {

const char* backend_name() {
#if defined(SOKOL_D3D11)
    return "Direct3D 11";
#elif defined(SOKOL_GLCORE)
    return "OpenGL";
#elif defined(SOKOL_GLES3)
    return "OpenGL ES 3 / WebGL 2";
#elif defined(SOKOL_WGPU)
    return "WebGPU";
#else
    return "this graphics backend";
#endif
}

std::string unavailable_reason() {
    return std::string("MetalFX is Apple's upscaler: it needs the Metal graphics backend (macOS 13 or later, iOS 16 or "
                       "later, a real "
                       "GPU), and this build draws with ") +
           backend_name() +
           ". Use the engine's own spatial or temporal upscaler, which work on every backend"
           " (on a Mac, build without the CMake option -DFA_GFX_BACKEND=<another backend>).";
}

}  // namespace

struct Scaler::Impl {
    Desc desc;
};

Support support(const void*) {
    Support s;
    s.reason = unavailable_reason();
    return s;
}
Support support_default_device() { return support(nullptr); }

Scaler::Scaler() : impl_(std::make_unique<Impl>()) {}
Scaler::~Scaler() = default;

bool Scaler::configure(gpu::Device&, const Desc&, std::string* error) {
    if (error) *error = unavailable_reason();
    return false;
}
bool Scaler::encode(gpu::Device&, const Frame&, std::string* error) {
    if (error) *error = unavailable_reason();
    return false;
}
bool Scaler::valid() const { return false; }
const Desc& Scaler::desc() const { return impl_->desc; }
int Scaler::generation() const { return 0; }
int Scaler::encoded() const { return 0; }
bool Scaler::command_failed(std::string*) const { return false; }
void Scaler::release() {}
bool Scaler::reactive_mask() const { return false; }
int Scaler::reactive_encoded() const { return 0; }
void Scaler::set_test_hooks(const TestHooks&) {}
bool Scaler::test_wait_signalled(int) { return false; }

}  // namespace fa::render::metalfx

#endif  // !SOKOL_METAL
