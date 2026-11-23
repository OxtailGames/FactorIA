// The graphics quality presets of M76 (docs/UPSCALING.md, "Graphics presets"): Low, Medium, High, Ultra, and "custom" for a
// setting the player changed by hand. M76-P0 defines the names; M76 P6a builds what a preset sets (graphics.preset,
// graphics.detect) over every renderer feature of M70-M80.
#pragma once

#include <array>
#include <optional>
#include <string_view>

#include "fa/core/types.h"

namespace fa::render {

enum class GraphicsPreset : std::int32_t { Low, Medium, High, Ultra, Custom };
inline constexpr int kGraphicsPresetCount = 5;
inline constexpr std::array<std::string_view, kGraphicsPresetCount> kGraphicsPresetNames = {"low", "medium", "high",
                                                                                            "ultra", "custom"};

constexpr std::string_view graphics_preset_name(GraphicsPreset p) {
    const int i = int(p);
    return (i >= 0 && i < kGraphicsPresetCount) ? kGraphicsPresetNames[std::size_t(i)] : std::string_view("custom");
}
// "low", "Low" or "LOW" -> Low; anything else -> nullopt (the caller teaches with did_you_mean over kGraphicsPresetNames).
std::optional<GraphicsPreset> parse_graphics_preset(std::string_view name);

}  // namespace fa::render
