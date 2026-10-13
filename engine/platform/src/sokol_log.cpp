#include "fa/platform/sokol_logging.h"

#include "fa/core/log.h"

extern "C" void fa_sokol_log_func(const char* tag, std::uint32_t logLevel, std::uint32_t logItemId,
                                  const char* messageOrNull, std::uint32_t lineNr, const char* filenameOrNull,
                                  void* userData) {
    (void)userData;
    fa::LogLevel level = fa::LogLevel::Info;
    switch (logLevel) {
        case 0: case 1: level = fa::LogLevel::Error; break;
        case 2: level = fa::LogLevel::Warn; break;
        default: level = fa::LogLevel::Info; break;
    }
    std::string msg = messageOrNull ? messageOrNull : "(no message, item " + std::to_string(logItemId) + ")";
    if (filenameOrNull && logLevel <= 2) msg += std::string(" [") + filenameOrNull + ":" + std::to_string(lineNr) + "]";
    fa::log(level, tag ? tag : "sokol", std::move(msg));
}
