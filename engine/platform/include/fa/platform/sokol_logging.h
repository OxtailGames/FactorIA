// Logger callback shared by every sokol subsystem (see sokol_entry.h).
#pragma once

#include <cstdint>

// Forwards sokol_app / sokol_gfx / sokol_audio messages to fa::log with the
// sokol tag ("sapp", "sg", "saudio") as category. Use as `.logger.func`.
extern "C" void fa_sokol_log_func(const char* tag, std::uint32_t logLevel, std::uint32_t logItemId,
                                  const char* messageOrNull, std::uint32_t lineNr, const char* filenameOrNull,
                                  void* userData);
