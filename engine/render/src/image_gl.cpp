// The OpenGL ES fix of every image SokolDevice makes (gpu/sokol_native.h, native_finish_image). The GL names come from
// the Device's natives; nothing here calls sokol.
#include "gpu/sokol_native.h"

#if defined(SOKOL_GLES3)
#include <GLES3/gl3.h>

#include <algorithm>
#endif

#include "gpu/device.h"

namespace fa::gpu {

void native_finish_image(Device& device, Image image, int mipmaps) {
#if defined(SOKOL_GLES3)
    // sokol_gfx gives every sampler a mipmap min filter (GL_NEAREST_MIPMAP_NEAREST, ...) and creates textures with
    // glTexStorage2D, trusting the driver to clamp the effective max level to the storage's levels. The Android
    // emulator's software GLES 3.0 does not: it treats every texture without a full mip chain as incomplete and samples
    // black, so everything but 1x1 textures (the game target, glyph atlas, bloom levels) vanishes. Setting the real
    // last level explicitly (what sokol itself does when it has no glTexStorage2D) makes the texture complete on any
    // driver and changes nothing on the conforming ones. A write-transient image (a video) has one texture per frame in
    // flight: all of them. On the image's own target (a cube or an array texture cannot be bound to GL_TEXTURE_2D); a
    // 3D image is left as sokol made it, as before.
    if (device.state(image) != ResourceState::Valid) return;
    const NativeImage native = device.native_image(image);
    GLenum binding = 0;
    switch (native.glTarget) {
        case GL_TEXTURE_2D: binding = GL_TEXTURE_BINDING_2D; break;
        case GL_TEXTURE_CUBE_MAP: binding = GL_TEXTURE_BINDING_CUBE_MAP; break;
        case GL_TEXTURE_2D_ARRAY: binding = GL_TEXTURE_BINDING_2D_ARRAY; break;
        default: return;
    }
    const GLenum target = GLenum(native.glTarget);
    GLint previous = 0;
    glGetIntegerv(binding, &previous);
    for (const std::uint32_t tex : native.glTextures) {
        if (!tex) continue;
        glBindTexture(target, GLuint(tex));
        glTexParameteri(target, GL_TEXTURE_MAX_LEVEL, std::max(mipmaps, 1) - 1);
    }
    glBindTexture(target, GLuint(previous));
#else
    (void)device, (void)image, (void)mipmaps;
#endif
}

}  // namespace fa::gpu
