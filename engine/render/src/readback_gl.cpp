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

bool readback_storage_image(sg_image image, sg_pixel_format format, int x, int y, int width, int height,
                            std::vector<std::uint8_t>& out, std::string* error) {
#if defined(SOKOL_GLES3)
    (void)image, (void)format, (void)x, (void)y, (void)width, (void)height, (void)out;
    if (error) *error = "readback: GLES3 has no storage images (compute shaders need desktop OpenGL 4.3)";
    return false;
#else
    const sg_gl_image_info info = sg_gl_query_image_info(image);
    const GLuint tex = info.tex[info.active_slot];
    if (!tex) {
        if (error) *error = "readback: the storage image has no GL texture";
        return false;
    }
    const std::size_t pixel = std::size_t(sg_query_pixelformat(format).bytes_per_pixel);
    GLenum glFormat = GL_RGBA, glType = GL_UNSIGNED_BYTE;
    switch (format) {
        case SG_PIXELFORMAT_RGBA16F: glType = GL_HALF_FLOAT; break;
        case SG_PIXELFORMAT_R32F:
            glFormat = GL_RED;
            glType = GL_FLOAT;
            break;
        case SG_PIXELFORMAT_RGBA32F: glType = GL_FLOAT; break;
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
        sg_reset_state_cache();
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
    sg_reset_state_cache();
    if (!done && error) *error = "readback: the GL driver refused to read the storage image back";
    return done;
#endif
}

bool storage_image_loadable(sg_pixel_format format, std::string* why) {
    (void)format;
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
