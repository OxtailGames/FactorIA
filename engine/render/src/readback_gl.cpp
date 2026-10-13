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

}  // namespace fa::render

#endif
