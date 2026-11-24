// OpenGL / GLES3 readback (gpu/sokol_native.h): a render target through a temporary FBO, a storage buffer with
// glGetBufferSubData. The GL names come from the Device's natives; after its own GL calls each read tells the device to
// forget its cached GL state (Device::reset_state_cache).
#include "gpu/sokol_native.h"

#if defined(SOKOL_GLCORE) || defined(SOKOL_GLES3)

#include <cstring>

#if defined(SOKOL_GLES3)
#include <GLES3/gl3.h>
#else
#define GL_GLEXT_PROTOTYPES 1
#include <GL/gl.h>
#include <GL/glext.h>
#endif

#include "gpu/device.h"

namespace fa::gpu {

bool native_read_image_rgba8(Device& device, Image image, int width, int height, std::vector<std::uint8_t>& out,
                             std::string* error) {
    const GLuint tex = device.native_image(image).glTexture;
    if (!tex) {
        if (error) *error = "capture: the game target has no GL texture (renderer not initialized?)";
        return false;
    }
    GLint prevFbo = 0;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &prevFbo);
    GLuint fbo = 0;
    glGenFramebuffers(1, &fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex, 0);
    bool ok = glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE;
    if (ok) {
        std::vector<std::uint8_t> raw(std::size_t(width) * height * 4);
        glPixelStorei(GL_PACK_ALIGNMENT, 1);
        glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, raw.data());
        out.resize(raw.size());
        std::size_t stride = std::size_t(width) * 4;
        for (int y = 0; y < height; ++y)  // GL rows are bottom-up
            std::memcpy(&out[std::size_t(y) * stride], &raw[std::size_t(height - 1 - y) * stride], stride);
    } else if (error) {
        *error = "capture: GL framebuffer incomplete while reading back the game target";
    }
    glBindFramebuffer(GL_FRAMEBUFFER, GLuint(prevFbo));
    glDeleteFramebuffers(1, &fbo);
    device.reset_state_cache();
    return ok;
}

bool native_read_image_rgba16f(Device& device, Image image, int width, int height, std::vector<float>& out,
                               std::string* error) {
    const GLuint tex = device.native_image(image).glTexture;
    if (!tex) {
        if (error) *error = "readback: the image has no GL texture";
        return false;
    }
    GLint prevFbo = 0;
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &prevFbo);
    GLuint fbo = 0;
    glGenFramebuffers(1, &fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex, 0);
    bool ok = glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE;
    if (ok) {
        // Clear the errors of earlier calls: a bounded count, because a lost context answers GL_CONTEXT_LOST on every call.
        for (int i = 0; i < 16 && glGetError() != GL_NO_ERROR; ++i) {
        }
        const std::size_t stride = std::size_t(width) * 4;
        std::vector<float> raw(stride * std::size_t(height));
        glPixelStorei(GL_PACK_ALIGNMENT, 4);
        glReadPixels(0, 0, width, height, GL_RGBA, GL_FLOAT, raw.data());
        ok = glGetError() == GL_NO_ERROR;
        if (ok) {
            out.resize(raw.size());
            for (int y = 0; y < height; ++y)  // GL rows are bottom-up
                std::memcpy(&out[std::size_t(y) * stride], &raw[std::size_t(height - 1 - y) * stride],
                            stride * sizeof(float));
        } else if (error) {
            *error = "readback: this GL driver does not read a float framebuffer back as floats";
        }
    } else if (error) {
        *error = "readback: GL framebuffer incomplete while reading back a float image";
    }
    glBindFramebuffer(GL_FRAMEBUFFER, GLuint(prevFbo));
    glDeleteFramebuffers(1, &fbo);
    device.reset_state_cache();
    return ok;
}

bool native_read_storage_image(Device& device, Image image, PixelFormat format, int x, int y, int width, int height,
                               std::vector<std::uint8_t>& out, std::string* error) {
#if defined(SOKOL_GLES3)
    (void)device, (void)image, (void)format, (void)x, (void)y, (void)width, (void)height, (void)out;
    if (error) *error = "readback: GLES3 has no storage images (compute shaders need desktop OpenGL 4.3)";
    return false;
#else
    const GLuint tex = device.native_image(image).glTexture;
    if (!tex) {
        if (error) *error = "readback: the storage image has no GL texture";
        return false;
    }
    const std::size_t pixel = std::size_t(pixel_format_bytes(format));
    GLenum glFormat = GL_RGBA, glType = GL_UNSIGNED_BYTE;
    switch (format) {
        case PixelFormat::Rgba16F: glType = GL_HALF_FLOAT; break;
        case PixelFormat::R32F:
            glFormat = GL_RED;
            glType = GL_FLOAT;
            break;
        case PixelFormat::Rgba32F: glType = GL_FLOAT; break;
        default: break;
    }
    if (pixel == 0 || x < 0 || y < 0 || width < 1 || height < 1) {
        if (error) *error = "readback: the storage image does not have the size or format asked for";
        return false;
    }
    for (int i = 0; i < 16 && glGetError() != GL_NO_ERROR; ++i) {  // a bounded clear of the errors of earlier calls
    }
    glMemoryBarrier(GL_ALL_BARRIER_BITS);  // the shaders' writes are visible to the read below
    GLint prevTex = 0;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, &prevTex);
    glBindTexture(GL_TEXTURE_2D, tex);
    GLint w = 0, h = 0;
    glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_WIDTH, &w);
    glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_HEIGHT, &h);
    glBindTexture(GL_TEXTURE_2D, GLuint(prevTex));
    if (std::int64_t(x) + width > w ||
        std::int64_t(y) + height > h) {  // a buffer sized for the rectangle must not be overrun
        device.reset_state_cache();
        if (error) *error = "readback: the rectangle is outside the storage image";
        return false;
    }
    const std::size_t row = std::size_t(width) * pixel;
    out.resize(row * std::size_t(height));
    glPixelStorei(GL_PACK_ALIGNMENT, 1);
    // The rectangle through a temporary framebuffer and glReadPixels: it copies only the rectangle (glGetTexImage, the
    // only other read of OpenGL 4.3, copies the whole level). The images are colour-renderable (make_image_gpu checks
    // it) and the framebuffer's row 0 is the texture's row 0, the one an imageStore at y = 0 writes: no flip.
    bool done = false;
    GLint prevFbo = 0;
    glGetIntegerv(GL_READ_FRAMEBUFFER_BINDING, &prevFbo);
    GLuint fbo = 0;
    glGenFramebuffers(1, &fbo);
    glBindFramebuffer(GL_READ_FRAMEBUFFER, fbo);
    glFramebufferTexture2D(GL_READ_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex, 0);
    if (glCheckFramebufferStatus(GL_READ_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE) {
        glReadBuffer(GL_COLOR_ATTACHMENT0);
        glReadPixels(x, y, width, height, glFormat, glType, out.data());
        done = glGetError() == GL_NO_ERROR;
    }
    glBindFramebuffer(GL_READ_FRAMEBUFFER, GLuint(prevFbo));
    glDeleteFramebuffers(1, &fbo);
    // A driver that will not complete that framebuffer: the whole level, then the rectangle cut out of it.
    if (!done) {
        std::vector<std::uint8_t> whole(std::size_t(w) * std::size_t(h) * pixel);
        glBindTexture(GL_TEXTURE_2D, tex);
        glGetTexImage(GL_TEXTURE_2D, 0, glFormat, glType,
                      whole.data());  // rows in texture order: row 0 = imageStore y 0
        done = glGetError() == GL_NO_ERROR;
        glBindTexture(GL_TEXTURE_2D, GLuint(prevTex));
        if (done)
            for (int r = 0; r < height; ++r)
                std::memcpy(&out[std::size_t(r) * row],
                            &whole[(std::size_t(y + r) * std::size_t(w) + std::size_t(x)) * pixel], row);
    }
    device.reset_state_cache();
    if (!done && error) *error = "readback: the GL driver refused to read the storage image back";
    return done;
#endif
}

bool native_storage_image_loadable(const Device& device, PixelFormat format, std::string* why) {
    (void)device, (void)format;
    // Desktop OpenGL 4.3 loads every format the shader declares with a layout qualifier (the engine always writes one);
    // GLES3 has no storage images at all, so no material reaches this.
    if (why) why->clear();
#if defined(SOKOL_GLES3)
    if (why) *why = "GLES3 has no storage images";
    return false;
#else
    return true;
#endif
}

bool native_read_buffer(Device& device, Buffer buffer, std::size_t offset, std::size_t bytes,
                        std::vector<std::uint8_t>& out, std::string* error) {
#if defined(SOKOL_GLES3)
    (void)device, (void)buffer, (void)offset, (void)bytes, (void)out;
    if (error) *error = "readback: GLES3 has no storage buffers (compute shaders need desktop OpenGL 4.3)";
    return false;
#else
    const GLuint buf = device.native_buffer(buffer).glBuffer;
    if (!buf) {
        if (error) *error = "readback: the storage buffer has no GL buffer";
        return false;
    }
    out.resize(bytes);
    if (bytes == 0) return true;
    for (int i = 0; i < 16 && glGetError() != GL_NO_ERROR; ++i) {  // a bounded clear of the errors of earlier calls
    }
    glMemoryBarrier(GL_ALL_BARRIER_BITS);  // the shaders' writes are visible to the read below
    glBindBuffer(GL_COPY_READ_BUFFER, buf);
    glGetBufferSubData(GL_COPY_READ_BUFFER, GLintptr(offset), GLsizeiptr(bytes), out.data());
    const bool ok = glGetError() == GL_NO_ERROR;
    glBindBuffer(GL_COPY_READ_BUFFER, 0);
    device.reset_state_cache();
    if (!ok && error) *error = "readback: the GL driver refused to read the storage buffer back";
    return ok;
#endif
}

struct AsyncBufferRead::Impl {
#if !defined(SOKOL_GLES3)
    enum class State { Free, Pending, Discard };
    struct Slot {
        GLuint staging = 0;
        GLsync fence = nullptr;
        std::size_t bytes = 0, capacity = 0;
        State state = State::Free;
    };
    Slot slots[kSlots];
    // Done: the copy's fence has been signalled (a bounded wait of `timeoutNs`, 0 = only look).
    static bool signalled(Slot& s, GLuint64 timeoutNs) {
        const GLenum r = glClientWaitSync(s.fence, timeoutNs ? GL_SYNC_FLUSH_COMMANDS_BIT : 0, timeoutNs);
        return r == GL_ALREADY_SIGNALED || r == GL_CONDITION_SATISFIED;
    }
    static void free_fence(Slot& s) {
        if (s.fence) glDeleteSync(s.fence);
        s.fence = nullptr;
        s.state = State::Free;
    }
#endif
};

AsyncBufferRead::AsyncBufferRead(Device& device) : device_(device), impl_(std::make_unique<Impl>()) {}
AsyncBufferRead::~AsyncBufferRead() {
#if !defined(SOKOL_GLES3)
    for (Impl::Slot& s : impl_->slots) {
        if (s.fence) glDeleteSync(s.fence);
        if (s.staging) glDeleteBuffers(1, &s.staging);
    }
#endif
}

#if defined(SOKOL_GLES3)
bool AsyncBufferRead::supported() { return false; }
int AsyncBufferRead::request(Buffer, std::size_t, std::string* error) {
    (void)device_;
    if (error) *error = "readback: GLES3 has no storage buffers (compute shaders need desktop OpenGL 4.3)";
    return -1;
}
bool AsyncBufferRead::poll(int, std::vector<std::uint8_t>&, bool) { return false; }
void AsyncBufferRead::release(int) {}
#else
bool AsyncBufferRead::supported() { return true; }

int AsyncBufferRead::request(Buffer buffer, std::size_t bytes, std::string* error) {
    for (Impl::Slot& s : impl_->slots)
        if (s.state == Impl::State::Discard && Impl::signalled(s, 0)) Impl::free_fence(s);
    int slot = -1;
    for (int i = 0; i < kSlots && slot < 0; ++i)
        if (impl_->slots[i].state == Impl::State::Free) slot = i;
    if (slot < 0) return -1;
    const GLuint src = device_.native_buffer(buffer).glBuffer;
    if (!src || bytes == 0) {
        if (error) *error = "readback: the storage buffer has no GL buffer";
        return -1;
    }
    Impl::Slot& s = impl_->slots[slot];
    for (int i = 0; i < 16 && glGetError() != GL_NO_ERROR; ++i) {  // a bounded clear of the errors of earlier calls
    }
    if (!s.staging) glGenBuffers(1, &s.staging);
    glMemoryBarrier(GL_BUFFER_UPDATE_BARRIER_BIT |
                    GL_SHADER_STORAGE_BARRIER_BIT);  // the shaders' writes are visible to the copy
    glBindBuffer(GL_COPY_WRITE_BUFFER, s.staging);
    if (s.capacity < bytes) {
        glBufferData(GL_COPY_WRITE_BUFFER, GLsizeiptr(bytes), nullptr, GL_STREAM_READ);
        s.capacity = bytes;
    }
    glBindBuffer(GL_COPY_READ_BUFFER, src);
    glCopyBufferSubData(GL_COPY_READ_BUFFER, GL_COPY_WRITE_BUFFER, 0, 0, GLsizeiptr(bytes));
    s.fence = glFenceSync(GL_SYNC_GPU_COMMANDS_COMPLETE, 0);
    glFlush();
    glBindBuffer(GL_COPY_READ_BUFFER, 0);
    glBindBuffer(GL_COPY_WRITE_BUFFER, 0);
    device_.reset_state_cache();
    if (glGetError() != GL_NO_ERROR || !s.fence) {
        if (s.fence) glDeleteSync(s.fence);
        s.fence = nullptr;
        if (error) *error = "readback: the GL driver refused to copy the storage buffer";
        return -1;
    }
    s.bytes = bytes;
    s.state = Impl::State::Pending;
    return slot;
}

bool AsyncBufferRead::poll(int slot, std::vector<std::uint8_t>& out, bool wait) {
    if (slot < 0 || slot >= kSlots || impl_->slots[slot].state != Impl::State::Pending) return false;
    Impl::Slot& s = impl_->slots[slot];
    // A wait is a safety net far above a copy's time (2 s), never a pacing device.
    if (!Impl::signalled(s, wait ? GLuint64(2000000000) : 0)) return false;
    out.resize(s.bytes);
    glBindBuffer(GL_COPY_READ_BUFFER, s.staging);
    glGetBufferSubData(GL_COPY_READ_BUFFER, 0, GLsizeiptr(s.bytes), out.data());
    const bool ok = glGetError() == GL_NO_ERROR;
    glBindBuffer(GL_COPY_READ_BUFFER, 0);
    device_.reset_state_cache();
    Impl::free_fence(s);
    return ok;
}

void AsyncBufferRead::release(int slot) {
    if (slot < 0 || slot >= kSlots) return;
    Impl::Slot& s = impl_->slots[slot];
    if (s.state == Impl::State::Pending) s.state = Impl::State::Discard;
}
#endif

}  // namespace fa::gpu

#endif
