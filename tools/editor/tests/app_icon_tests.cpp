// The program icon embedded in the editor (app_icon.h): the window icon sizes for Windows and Linux and the macOS Dock icon
// decode, and the window icon fits what sokol_app takes (at most 8 images).
#include <vector>

#include "app_icon.h"
#include "doctest.h"

using namespace fa;
using namespace fa::editor;

TEST_CASE("editor window icon: every size from 16 to 256, smallest first, RGBA") {
    std::vector<AppIconImage> icons = editor_window_icon();
    REQUIRE(icons.size() == 7);
    CHECK(icons.size() <= 8);  // SAPP_MAX_ICONIMAGES
    const int sizes[] = {16, 24, 32, 48, 64, 128, 256};
    for (std::size_t i = 0; i < icons.size(); ++i) {
        CAPTURE(i);
        CHECK(icons[i].width == sizes[i]);
        CHECK(icons[i].height == sizes[i]);
        CHECK(icons[i].rgba.size() == std::size_t(sizes[i]) * std::size_t(sizes[i]) * 4);
    }
    // The tile is rounded: the corner pixel is transparent, the middle is opaque.
    const AppIconImage& big = icons.back();
    CHECK(big.rgba[3] == 0);
    CHECK(big.rgba[(std::size_t(128) * 256 + 128) * 4 + 3] == 255);
}

TEST_CASE("editor dock icon: 512 px on the macOS icon grid") {
    AppIconImage dock = editor_dock_icon();
    REQUIRE(dock.width == 512);
    CHECK(dock.height == 512);
    REQUIRE(dock.rgba.size() == std::size_t(512) * 512 * 4);
    // Apple's grid leaves a margin around the tile: the edge row is empty, the middle is not.
    CHECK(dock.rgba[(std::size_t(10) * 512 + 256) * 4 + 3] == 0);
    CHECK(dock.rgba[(std::size_t(256) * 512 + 256) * 4 + 3] == 255);
}
