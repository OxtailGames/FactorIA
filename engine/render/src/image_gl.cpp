// Image creation shared by the renderer's subsystems.
#include <algorithm>

#include "render_internal.h"

#if defined(SOKOL_GLES3)
#include <GLES3/gl3.h>
#endif

namespace fa::render {

sg_image make_image(const sg_image_desc& desc) {
    sg_image image = sg_make_image(&desc);
#if defined(SOKOL_GLES3)
    // sokol_gfx gives every sampler a mipmap min filter (GL_NEAREST_MIPMAP_NEAREST, ...) and creates textures with
    // glTexStorage2D, trusting the driver to clamp the effective max level to the storage's levels. The Android
    // emulator's software GLES 3.0 does not: it treats every texture without a full mip chain as incomplete and samples
    // black, so everything but 1x1 textures (the game target, glyph atlas, bloom levels) vanishes. Setting the real
    // last level explicitly (what sokol itself does when it has no glTexStorage2D) makes the texture complete on any
    // driver and changes nothing on the conforming ones.
    const sg_gl_image_info info = sg_gl_query_image_info(image);
    const GLuint tex = info.tex[info.active_slot];
    if (tex && sg_query_image_state(image) == SG_RESOURCESTATE_VALID) {
        GLint previous = 0;
        glGetIntegerv(GL_TEXTURE_BINDING_2D, &previous);
        glBindTexture(GL_TEXTURE_2D, tex);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, std::max(desc.num_mipmaps, 1) - 1);
        glBindTexture(GL_TEXTURE_2D, GLuint(previous));
    }
#endif
    return image;
}

}  // namespace fa::render
