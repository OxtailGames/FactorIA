#include "fa/render/graphics_preset.h"

#include <algorithm>
#include <cctype>
#include <string>

namespace fa::render {

std::optional<GraphicsPreset> parse_graphics_preset(std::string_view name) {
    std::string lower(name);
    std::transform(lower.begin(), lower.end(), lower.begin(), [](unsigned char c) { return char(std::tolower(c)); });
    for (int i = 0; i < kGraphicsPresetCount; ++i)
        if (kGraphicsPresetNames[std::size_t(i)] == lower) return GraphicsPreset(i);
    return std::nullopt;
}

}  // namespace fa::render
