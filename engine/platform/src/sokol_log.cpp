#include "fa/platform/sokol_logging.h"

#include "fa/core/log.h"
#include "sokol_gfx.h"

#include <cstring>

namespace {

// sokol_gfx's GL backend looks every attribute, uniform block and texture of a shader up by name, and says so when the
// driver's GLSL compiler removed one the shader does not use (a material without fog or fa_time, an unlit program
// that ignores the shadow map). Nothing is wrong: the binding is skipped and the shader draws the same. sokol's own
// note says as much, so these (and the line with the name that follows each) go to Debug, not to a game's warnings.
bool is_gl_unused_global(const char* tag, std::uint32_t logItemId) {
    if (!tag || std::strcmp(tag, "sg") != 0) return false;
    return logItemId == SG_LOGITEM_GL_VERTEX_ATTRIBUTE_NOT_FOUND_IN_SHADER ||
           logItemId == SG_LOGITEM_GL_UNIFORMBLOCK_NAME_NOT_FOUND_IN_SHADER ||
           logItemId == SG_LOGITEM_GL_IMAGE_SAMPLER_NAME_NOT_FOUND_IN_SHADER;
}

}  // namespace

extern "C" void fa_sokol_log_func(const char* tag, std::uint32_t logLevel, std::uint32_t logItemId,
                                  const char* messageOrNull, std::uint32_t lineNr, const char* filenameOrNull,
                                  void* userData) {
    (void)userData;
    fa::LogLevel level = fa::LogLevel::Info;
    switch (logLevel) {
        case 0:
        case 1: level = fa::LogLevel::Error; break;
        case 2: level = fa::LogLevel::Warn; break;
        default: level = fa::LogLevel::Info; break;
    }
    if (is_gl_unused_global(tag, logItemId)) level = fa::LogLevel::Debug;
    std::string msg = messageOrNull ? messageOrNull : "(no message, item " + std::to_string(logItemId) + ")";
    if (filenameOrNull && logLevel <= 2) msg += std::string(" [") + filenameOrNull + ":" + std::to_string(lineNr) + "]";
    fa::log(level, tag ? tag : "sokol", std::move(msg));
}
