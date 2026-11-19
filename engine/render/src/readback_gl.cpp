// OpenGL / GLES3 readback of an RGBA8 render target through a temporary FBO.
#include "render_internal.h"

#if defined(SOKOL_GLCORE) || defined(SOKOL_GLES3)

#include <cstring>

#if defined(SOKOL_GLES3)
#include <GLES3/gl3.h>
#else
#define GL_GLEXT_PROTOTYPES 1
#include <GL/gl.h>
#include <GL/glext.h>
#endif

namespace fa::render {

bool readback_rgba8(sg_image image, int width, int height, std::vector<std::uint8_t>& out, std::string* error) {
    sg_gl_image_info info = sg_gl_query_image_info(image);
    GLuint tex = info.tex[info.active_slot];
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
    sg_reset_state_cache();
    return ok;
}

bool readback_rgba16f(sg_image image, int width, int height, std::vector<float>& out, std::string* error) {
    sg_gl_image_info info = sg_gl_query_image_info(image);
    GLuint tex = info.tex[info.active_slot];
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
    sg_reset_state_cache();
    return ok;
}

bool readback_buffer(sg_buffer buffer, std::size_t offset, std::size_t bytes, std::vector<std::uint8_t>& out,
                     std::string* error) {
#if defined(SOKOL_GLES3)
    (void)buffer, (void)offset, (void)bytes, (void)out;
    if (error) *error = "readback: GLES3 has no storage buffers (compute shaders need desktop OpenGL 4.3)";
    return false;
#else
    const sg_gl_buffer_info info = sg_gl_query_buffer_info(buffer);
    const GLuint buf = info.buf[info.active_slot];
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
    sg_reset_state_cache();
    if (!ok && error) *error = "readback: the GL driver refused to read the storage buffer back";
    return ok;
#endif
}

}  // namespace fa::render

#endif
