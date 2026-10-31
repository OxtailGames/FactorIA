#include "app_icon.h"

#include <algorithm>
#include <string_view>

#include "editor_icon.h"
#include "fa/core/image.h"
#include "fa/core/log.h"

namespace fa::editor {

namespace {

AppIconImage decode(std::string_view path, std::string_view data) {
    auto image = decode_image(reinterpret_cast<const std::uint8_t*>(data.data()), data.size());
    if (!image) {
        FA_WARN("editor", "icon {}: {}", path, image.error().to_string());  // the platform's default icon instead
        return {};
    }
    AppIconImage out;
    out.width = image->width;
    out.height = image->height;
    out.rgba = std::move(image->rgba);
    return out;
}

}  // namespace

std::vector<AppIconImage> editor_window_icon() {
    std::vector<AppIconImage> icons;
    for (const auto& f : fa_editor_icon::files()) {
        if (f.path == "factoria_dock.png") continue;
        AppIconImage icon = decode(f.path, f.data);
        if (icon.width > 0) icons.push_back(std::move(icon));
    }
    std::sort(icons.begin(), icons.end(), [](const AppIconImage& a, const AppIconImage& b) { return a.width < b.width; });
    return icons;
}

#if !defined(__APPLE__)
bool set_dock_name(const char*) { return false; }  // app_name_apple.mm
#endif

AppIconImage editor_dock_icon() {
    for (const auto& f : fa_editor_icon::files())
        if (f.path == "factoria_dock.png") return decode(f.path, f.data);
    return {};
}

}  // namespace fa::editor
