// AppDesc::icon: to_sapp_desc hands the window icon to sokol_app on Windows and Linux, keeps the pixels alive and ignores what
// sokol_app could not use.
#include <doctest.h>

#include "fa/platform/sokol_entry.h"

using namespace fa;

namespace {

AppIconImage solid(int w, int h, std::uint8_t value) {
    AppIconImage i;
    i.width = w;
    i.height = h;
    i.rgba.assign(std::size_t(w) * h * 4, value);
    return i;
}

}  // namespace

namespace {

std::vector<AppIconImage> mixed_icons() {
    std::vector<AppIconImage> icons;
    icons.push_back(solid(16, 16, 11));
    icons.push_back(solid(0, 0, 0));  // no pixels: skipped
    AppIconImage broken = solid(32, 32, 22);
    broken.rgba.resize(10);  // not width * height * 4 bytes: skipped
    icons.push_back(broken);
    icons.push_back(solid(48, 48, 33));
    for (int i = 0; i < 12; ++i) icons.push_back(solid(64, 64, 44));  // more than sokol_app takes
    return icons;
}

}  // namespace

TEST_CASE("fill_sapp_icon: the usable images, at most SAPP_MAX_ICONIMAGES, pointing at the caller's pixels") {
    const std::vector<AppIconImage> icons = mixed_icons();
    sapp_icon_desc out{};
    CHECK(fill_sapp_icon(out, icons) == SAPP_MAX_ICONIMAGES);
    CHECK(out.images[0].width == 16);
    CHECK(out.images[0].height == 16);
    CHECK(out.images[0].pixels.size == 16 * 16 * 4);
    CHECK(out.images[0].pixels.ptr == icons[0].rgba.data());
    CHECK(out.images[1].width == 48);  // the two unusable images are not there
    CHECK(static_cast<const std::uint8_t*>(out.images[1].pixels.ptr)[5] == 33);
    CHECK(out.images[SAPP_MAX_ICONIMAGES - 1].width == 64);

    sapp_icon_desc none{};
    CHECK(fill_sapp_icon(none, {}) == 0);
    CHECK(none.images[0].width == 0);
}

TEST_CASE("to_sapp_desc: the window icon reaches sapp_desc on Windows and Linux and stays valid after the AppDesc is gone") {
    AppDesc d;
    d.icon = mixed_icons();
    sapp_desc s = to_sapp_desc(d);
    d.icon.clear();  // to_sapp_desc owns a copy

#if defined(_WIN32) || (defined(__linux__) && !defined(__ANDROID__))
    CHECK(s.icon.images[0].width == 16);
    REQUIRE(s.icon.images[0].pixels.ptr != nullptr);
    CHECK(static_cast<const std::uint8_t*>(s.icon.images[0].pixels.ptr)[0] == 11);
    CHECK(s.icon.images[1].width == 48);
    for (int i = 0; i < SAPP_MAX_ICONIMAGES; ++i) CHECK(s.icon.images[i].width > 0);
    CHECK_FALSE(s.icon.sokol_default);
#else
    // macOS keeps the Dock icon of the app bundle; mobile has no window icon: sapp_desc.icon stays empty.
    for (int i = 0; i < SAPP_MAX_ICONIMAGES; ++i) CHECK(s.icon.images[i].width == 0);
#endif
}

TEST_CASE("to_sapp_desc: no icon leaves sapp_desc.icon untouched") {
    AppDesc d;
    sapp_desc s = to_sapp_desc(d);
    for (int i = 0; i < SAPP_MAX_ICONIMAGES; ++i) CHECK(s.icon.images[i].width == 0);
    CHECK_FALSE(s.icon.sokol_default);
}
