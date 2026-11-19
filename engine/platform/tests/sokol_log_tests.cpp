#include <doctest.h>

#include <string>
#include <vector>

#include "fa/core/log.h"
#include "fa/platform/sokol_logging.h"
#include "sokol_gfx.h"

using namespace fa;

TEST_CASE("sokol log: GL's 'not found in shader' notes are Debug, every other sokol warning stays a warning") {
    std::vector<std::pair<LogLevel, std::string>> seen;
    const int sink = add_log_sink([&seen](const LogEntry& e) {
        if (e.category == "sg" || e.category == "sapp") seen.emplace_back(e.level, e.message);
    });
    // what sokol_gfx's GL backend sends when the driver removed an unused uniform block: a warning, then its name
    fa_sokol_log_func("sg", 2, SG_LOGITEM_GL_UNIFORMBLOCK_NAME_NOT_FOUND_IN_SHADER, nullptr, 1, nullptr, nullptr);
    fa_sokol_log_func("sg", 3, SG_LOGITEM_GL_UNIFORMBLOCK_NAME_NOT_FOUND_IN_SHADER, "quad_fs_params", 1, nullptr,
                      nullptr);
    fa_sokol_log_func("sg", 2, SG_LOGITEM_GL_IMAGE_SAMPLER_NAME_NOT_FOUND_IN_SHADER, nullptr, 1, nullptr, nullptr);
    fa_sokol_log_func("sg", 2, SG_LOGITEM_GL_VERTEX_ATTRIBUTE_NOT_FOUND_IN_SHADER, nullptr, 1, nullptr, nullptr);
    // another sokol_gfx warning, and the same item number from sokol_app, are not touched
    fa_sokol_log_func("sg", 2, SG_LOGITEM_GL_FRAMEBUFFER_STATUS_UNDEFINED, nullptr, 1, nullptr, nullptr);
    fa_sokol_log_func("sapp", 2, SG_LOGITEM_GL_UNIFORMBLOCK_NAME_NOT_FOUND_IN_SHADER, nullptr, 1, nullptr, nullptr);
    remove_log_sink(sink);
    int warnings = 0;
    for (const auto& [level, message] : seen) {
        CAPTURE(message);
        if (level >= LogLevel::Warn) ++warnings;
        if (message == "quad_fs_params") CHECK(level == LogLevel::Debug);
    }
    CHECK(warnings == 2);
}
