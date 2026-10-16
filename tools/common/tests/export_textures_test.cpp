// Export: texture compression (KTX2) and atlas packing (tools/common/src/export_textures.cpp).
#include <doctest.h>

#include <algorithm>
#include <array>
#include <chrono>
#include <filesystem>

#include "fa/core/image.h"
#include "fa/core/json.h"
#include "fa/tooling/export.h"
#include "fa/tooling/scaffold.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

Image gradient(int w, int h, int seed) {
    Image img;
    img.width = w;
    img.height = h;
    img.rgba.resize(std::size_t(w) * h * 4);
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            std::uint8_t* p = &img.rgba[(std::size_t(y) * w + x) * 4];
            p[0] = std::uint8_t((x * 255) / std::max(1, w - 1));
            p[1] = std::uint8_t((y * 255) / std::max(1, h - 1));
            p[2] = std::uint8_t(seed * 40 + (x + y) % 16);
            p[3] = 255;
        }
    }
    return img;
}

void write_png(const stdfs::path& path, const Image& img) {
    const std::vector<std::uint8_t> bytes = encode_png(img);
    testing::write_all(path, std::string(bytes.begin(), bytes.end()));
}

Image read_png(const stdfs::path& path) {
    const std::string data = testing::read_all(path);
    auto img = decode_image(reinterpret_cast<const std::uint8_t*>(data.data()), data.size());
    REQUIRE_MESSAGE(img.ok(), path.string());
    return std::move(*img);
}

ImageSize ktx2_file_size(const stdfs::path& path) {
    const std::string data = testing::read_all(path);
    auto size = ktx2_size(reinterpret_cast<const std::uint8_t*>(data.data()), data.size());
    REQUIRE_MESSAGE(size.ok(), path.string());
    return *size;
}

bool has_warning(const ExportReport& r, const std::string& part) {
    return std::any_of(r.warnings.begin(), r.warnings.end(), [&](const std::string& w) { return w.find(part) != std::string::npos; });
}
// The warnings of the texture steps (the export has others, such as the missing icon).
bool texture_warnings(const ExportReport& r) { return has_warning(r, "Texture ") || has_warning(r, "Atlas "); }

// A 2d-platformer project (its assets/tileset.png is 128x32) with a fake desktop player and a fake Android download.
struct TextureFixture {
    testing::TempDir tmp;
    std::string proj = tmp.sub("proj");
    std::string player = tmp.sub("fake_player/factoria_player");
    std::string mobile = tmp.sub("download/mobile");
    TextureFixture() {
        auto r = create_project(proj, "2d-platformer");
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        testing::write_all(player, "#!/bin/sh\nexit 0\n");
        for (const char* abi : {"arm64-v8a", "x86_64"})
            testing::write_all(stdfs::path(mobile) / "android" / "jniLibs" / abi / "libfactoria_player.so", abi);
    }
    void manifest(const std::string& json) { testing::write_all(stdfs::path(proj) / "assets.json", json); }
    Result<ExportReport> export_to(const std::string& platform) {
        ExportOptions o;
        o.projectDir = proj;
        o.platform = platform;
        o.outDir = tmp.sub("out");
        o.playerBinary = player;
        o.mobileDir = mobile;
        o.format = "gradle";  // an apk would need a JDK and the Android SDK
        auto r = export_project(o);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        return r;
    }
    // The folder of the game inside the export.
    stdfs::path game(const std::string& platform) const {
        return stdfs::path(tmp.sub("out")) / ("proj-" + platform) / (platform == "android" ? "app/src/main/assets" : "game");
    }
    std::vector<stdfs::path> cache_files(const std::string& platform, const std::string& prefix) const {
        std::vector<stdfs::path> out;
        std::error_code ec;
        for (const auto& e : stdfs::directory_iterator(stdfs::path(proj) / ".factoria" / "export-cache" / platform, ec))
            if (e.path().filename().string().rfind(prefix, 0) == 0) out.push_back(e.path());
        return out;
    }
    Json shipped_manifest(const std::string& platform) const {
        auto j = parse_json(testing::read_all(game(platform) / "assets.json"));
        REQUIRE(j.ok());
        return *j;
    }
};

}  // namespace

TEST_CASE("export textures: a desktop export ships PNGs unless the import settings ask for compression") {
    TextureFixture f;
    auto plain = f.export_to("linux");
    CHECK(stdfs::exists(f.game("linux") / "assets/tileset.png"));
    CHECK_FALSE(stdfs::exists(f.game("linux") / "assets/tileset.png.ktx2"));
    CHECK(f.cache_files("linux", "tex-").empty());  // nothing was decoded, nothing encoded
    CHECK_FALSE(texture_warnings(*plain));

    f.manifest(R"({"format": "factoria.assets/1", "assets": {"assets/tileset.png": {"import": {"compression": "uastc"}}}})");
    auto r = f.export_to("linux");
    CHECK_FALSE(stdfs::exists(f.game("linux") / "assets/tileset.png"));
    REQUIRE(stdfs::exists(f.game("linux") / "assets/tileset.png.ktx2"));
    const ImageSize size = ktx2_file_size(f.game("linux") / "assets/tileset.png.ktx2");
    CHECK(size.width == 128);
    CHECK(size.height == 32);
    CHECK(std::find(r->files.begin(), r->files.end(), "game/assets/tileset.png.ktx2") != r->files.end());
    CHECK_FALSE(texture_warnings(*r));
    // The project keeps its PNG, and the import setting travels with the game.
    CHECK(stdfs::exists(stdfs::path(f.proj) / "assets/tileset.png"));
    CHECK(f.shipped_manifest("linux")["assets"]["assets/tileset.png"]["import"]["compression"] == "uastc");
}

TEST_CASE("export textures: a compressed file is cached by content and reused, stale ones are pruned") {
    TextureFixture f;
    f.manifest(R"({"format": "factoria.assets/1", "defaults": {"texture": {"compression": "uastc"}}})");
    (void)f.export_to("linux");
    const auto first = f.cache_files("linux", "tex-");
    REQUIRE(first.size() == 1);
    const std::string bytes = testing::read_all(first[0]);

    // Make the cached file look old: an export that encodes again would write it anew.
    const auto hourAgo = stdfs::file_time_type::clock::now() - std::chrono::hours(1);
    stdfs::last_write_time(first[0], hourAgo - std::chrono::hours(4));
    (void)f.export_to("linux");
    REQUIRE(f.cache_files("linux", "tex-").size() == 1);
    CHECK(stdfs::last_write_time(first[0]) < hourAgo);
    CHECK(testing::read_all(f.game("linux") / "assets/tileset.png.ktx2") == bytes);

    // Another picture under the same name is another cache entry, and the old one goes.
    write_png(stdfs::path(f.proj) / "assets/tileset.png", gradient(64, 64, 2));
    (void)f.export_to("linux");
    const auto second = f.cache_files("linux", "tex-");
    REQUIRE(second.size() == 1);
    CHECK(second[0] != first[0]);
    CHECK(ktx2_file_size(f.game("linux") / "assets/tileset.png.ktx2").width == 64);

    // Another codec is another entry too.
    f.manifest(R"({"format": "factoria.assets/1", "defaults": {"texture": {"compression": "etc1s"}}})");
    (void)f.export_to("linux");
    const auto third = f.cache_files("linux", "tex-");
    REQUIRE(third.size() == 1);
    CHECK(third[0] != second[0]);
    CHECK(ktx2_file_size(f.game("linux") / "assets/tileset.png.ktx2").height == 64);
}

TEST_CASE("export textures: mobile exports compress by default, and none keeps the PNG") {
    TextureFixture f;
    write_png(stdfs::path(f.proj) / "assets/keep.png", gradient(32, 32, 1));
    f.manifest(R"({"format": "factoria.assets/1", "assets": {"assets/keep.png": {"import": {"compression": "none"}}}})");
    auto r = f.export_to("android");
    const stdfs::path game = f.game("android");
    CHECK(stdfs::exists(game / "assets/tileset.png.ktx2"));
    CHECK_FALSE(stdfs::exists(game / "assets/tileset.png"));
    CHECK(stdfs::exists(game / "assets/keep.png"));
    CHECK_FALSE(stdfs::exists(game / "assets/keep.png.ktx2"));
    // The player and the notices are not textures: untouched.
    CHECK(stdfs::exists(game / "FACTORIA_NOTICES.txt"));
    CHECK(f.cache_files("android", "tex-").size() == 1);
    CHECK(f.cache_files("linux", "tex-").empty());  // each platform has its own cache
}

TEST_CASE("export textures: what cannot be compressed ships as it is, with a warning only when it should have worked") {
    TextureFixture f;
    f.manifest(R"({"format": "factoria.assets/1", "defaults": {"texture": {"compression": "uastc"}}})");
    write_png(stdfs::path(f.proj) / "assets/wide.png", gradient(16388, 4, 1));  // the encoder stops at 16384 pixels
    write_png(stdfs::path(f.proj) / "assets/dot.png", gradient(2, 2, 1));       // smaller than one 4x4 block
    write_png(stdfs::path(f.proj) / "assets/odd.png", gradient(10, 6, 1));      // not a whole number of blocks
    testing::write_all(stdfs::path(f.proj) / "assets/broken.png", "not a png");
    auto r = f.export_to("linux");
    const stdfs::path game = f.game("linux");

    CHECK(stdfs::exists(game / "assets/wide.png"));
    CHECK_FALSE(stdfs::exists(game / "assets/wide.png.ktx2"));
    CHECK(has_warning(*r, "assets/wide.png could not be compressed"));
    CHECK(has_warning(*r, "larger than 16384"));
    CHECK(stdfs::exists(game / "assets/dot.png"));
    CHECK_FALSE(has_warning(*r, "assets/dot.png"));  // too small to matter: no word
    // GPU formats need a width and height that are multiples of 4: D3D11 and WebGPU refuse any other size.
    CHECK(stdfs::exists(game / "assets/odd.png"));
    CHECK_FALSE(stdfs::exists(game / "assets/odd.png.ktx2"));
    CHECK(has_warning(*r, "multiples of 4 pixels"));
    CHECK(has_warning(*r, "assets/odd.png"));
    CHECK(stdfs::exists(game / "assets/broken.png"));
    CHECK(has_warning(*r, "assets/broken.png could not be read"));
    CHECK(stdfs::exists(game / "assets/tileset.png.ktx2"));  // the rest of the export went on
}

TEST_CASE("export textures: an unknown compression value falls back to auto with a warning") {
    TextureFixture f;
    f.manifest(R"({"format": "factoria.assets/1", "assets": {"assets/tileset.png": {"import": {"compression": "astc"}}}})");
    auto r = f.export_to("linux");
    CHECK(has_warning(*r, "compression \"astc\" is not one of"));
    CHECK(stdfs::exists(f.game("linux") / "assets/tileset.png"));  // auto on desktop
}

TEST_CASE("export textures: atlas groups are packed with padding, the originals leave the export and the manifest says where") {
    TextureFixture f;
    const Image a = gradient(10, 12, 1), b = gradient(7, 5, 2), c = gradient(20, 9, 3);
    write_png(stdfs::path(f.proj) / "assets/ui/a.png", a);
    write_png(stdfs::path(f.proj) / "assets/ui/b.png", b);
    write_png(stdfs::path(f.proj) / "assets/ui/c.png", c);
    f.manifest(R"({"format": "factoria.assets/1", "assets": {
        "assets/ui/a.png": {"import": {"atlas": "ui"}},
        "assets/ui/b.png": {"import": {"atlas": "ui"}},
        "assets/ui/c.png": {"import": {"atlas": "ui"}}}})");
    auto r = f.export_to("linux");
    const stdfs::path game = f.game("linux");
    CHECK_FALSE(texture_warnings(*r));

    for (const char* gone : {"a", "b", "c"}) CHECK_FALSE(stdfs::exists(game / "assets/ui" / (std::string(gone) + ".png")));
    CHECK(stdfs::exists(game / "assets/tileset.png"));  // not in a group
    REQUIRE(stdfs::exists(game / "assets/atlases/ui.png"));
    const Image atlas = read_png(game / "assets/atlases/ui.png");
    CHECK((atlas.width % 4 == 0 && atlas.height % 4 == 0));

    const Json manifest = f.shipped_manifest("linux");
    struct Source {
        const char* path;
        const Image* image;
    };
    std::vector<std::array<int, 4>> rects;
    for (const Source& s : {Source{"assets/ui/a.png", &a}, Source{"assets/ui/b.png", &b}, Source{"assets/ui/c.png", &c}}) {
        CAPTURE(s.path);
        const Json& packed = manifest["assets"][s.path]["packed"];
        REQUIRE(packed.is_object());
        CHECK(packed["atlas"] == "assets/atlases/ui.png");
        const std::array<int, 4> rect = {packed["rect"][0], packed["rect"][1], packed["rect"][2], packed["rect"][3]};
        CHECK(rect[2] == s.image->width);
        CHECK(rect[3] == s.image->height);
        // The pixels are the texture's, and the 2 pixels around it repeat its edge (so filtering never reads a neighbour).
        for (int y = -2; y < rect[3] + 2; ++y) {
            for (int x = -2; x < rect[2] + 2; ++x) {
                const Color want = s.image->pixel(std::clamp(x, 0, rect[2] - 1), std::clamp(y, 0, rect[3] - 1));
                const Color got = atlas.pixel(rect[0] + x, rect[1] + y);
                CHECK((got.r == want.r && got.g == want.g && got.b == want.b && got.a == want.a));
            }
        }
        for (const auto& other : rects)  // no two padded rectangles overlap
            CHECK((rect[0] - 2 >= other[0] + other[2] + 2 || other[0] - 2 >= rect[0] + rect[2] + 2 || rect[1] - 2 >= other[1] + other[3] + 2 ||
                   other[1] - 2 >= rect[1] + rect[3] + 2));
        rects.push_back(rect);
    }
    // The import settings stay in the shipped manifest.
    CHECK(manifest["assets"]["assets/ui/a.png"]["import"]["atlas"] == "ui");
    // The project's own manifest is untouched.
    CHECK(testing::read_all(stdfs::path(f.proj) / "assets.json").find("packed") == std::string::npos);
}

TEST_CASE("export textures: the atlas is compressed like any texture, by the settings of its own entry") {
    TextureFixture f;
    write_png(stdfs::path(f.proj) / "assets/ui/a.png", gradient(16, 16, 1));
    write_png(stdfs::path(f.proj) / "assets/ui/b.png", gradient(16, 16, 2));
    f.manifest(R"({"format": "factoria.assets/1", "defaults": {"texture": {"atlas": "ui"}}, "assets": {
        "assets/tileset.png": {"import": {"atlas": ""}}}})");
    auto desktop = f.export_to("linux");
    CHECK(stdfs::exists(f.game("linux") / "assets/atlases/ui.png"));  // desktop: auto = none
    CHECK_FALSE(stdfs::exists(f.game("linux") / "assets/atlases/ui.png.ktx2"));

    auto mobile = f.export_to("android");
    CHECK_FALSE(stdfs::exists(f.game("android") / "assets/atlases/ui.png"));
    REQUIRE(stdfs::exists(f.game("android") / "assets/atlases/ui.png.ktx2"));
    const ImageSize size = ktx2_file_size(f.game("android") / "assets/atlases/ui.png.ktx2");
    CHECK(size.width >= 16 + 4);
    CHECK(size.height >= 16 + 4);
    CHECK(size.width % 4 == 0);  // the page is sized for the GPU format
    CHECK(size.height % 4 == 0);
    CHECK(stdfs::exists(f.game("android") / "assets/tileset.png.ktx2"));  // opted out of the group, compressed alone

    // The atlas entry's own import settings win.
    f.manifest(R"({"format": "factoria.assets/1", "defaults": {"texture": {"atlas": "ui"}}, "assets": {
        "assets/tileset.png": {"import": {"atlas": ""}},
        "assets/atlases/ui.png": {"import": {"compression": "none"}}}})");
    (void)f.export_to("android");
    CHECK(stdfs::exists(f.game("android") / "assets/atlases/ui.png"));
    CHECK_FALSE(stdfs::exists(f.game("android") / "assets/atlases/ui.png.ktx2"));
}

TEST_CASE("export textures: a group that does not fit one atlas uses more pages, a texture too big for any stays out") {
    TextureFixture f;
    // Mobile atlases are at most 2048 pixels: two of these cannot share one.
    write_png(stdfs::path(f.proj) / "assets/big/a.png", gradient(1100, 1100, 1));
    write_png(stdfs::path(f.proj) / "assets/big/b.png", gradient(1100, 1100, 2));
    write_png(stdfs::path(f.proj) / "assets/big/huge.png", gradient(3000, 8, 3));
    f.manifest(R"({"format": "factoria.assets/1", "defaults": {"texture": {"compression": "none"}}, "assets": {
        "assets/big/a.png": {"import": {"atlas": "big"}},
        "assets/big/b.png": {"import": {"atlas": "big"}},
        "assets/big/huge.png": {"import": {"atlas": "big"}}}})");
    auto r = f.export_to("android");
    const stdfs::path game = f.game("android");
    CHECK(stdfs::exists(game / "assets/atlases/big.png"));
    CHECK(stdfs::exists(game / "assets/atlases/big-2.png"));
    CHECK_FALSE(stdfs::exists(game / "assets/big/a.png"));
    CHECK_FALSE(stdfs::exists(game / "assets/big/b.png"));
    CHECK(stdfs::exists(game / "assets/big/huge.png"));
    CHECK(has_warning(*r, "assets/big/huge.png"));
    const Json manifest = f.shipped_manifest("android");
    CHECK(manifest["assets"]["assets/big/a.png"]["packed"]["atlas"] != manifest["assets"]["assets/big/b.png"]["packed"]["atlas"]);
    CHECK_FALSE(manifest["assets"]["assets/big/huge.png"].contains("packed"));
}

TEST_CASE("export textures: a group name that makes no file name, or a file in the way, leaves the textures unpacked") {
    TextureFixture f;
    write_png(stdfs::path(f.proj) / "assets/a.png", gradient(8, 8, 1));
    write_png(stdfs::path(f.proj) / "assets/b.png", gradient(8, 8, 2));
    write_png(stdfs::path(f.proj) / "assets/atlases/taken.png", gradient(8, 8, 3));
    f.manifest(R"({"format": "factoria.assets/1", "assets": {
        "assets/a.png": {"import": {"atlas": "!!!"}},
        "assets/b.png": {"import": {"atlas": "taken"}}}})");
    auto r = f.export_to("linux");
    const stdfs::path game = f.game("linux");
    CHECK(stdfs::exists(game / "assets/a.png"));
    CHECK(stdfs::exists(game / "assets/b.png"));
    CHECK(has_warning(*r, "Atlas group \"!!!\""));
    CHECK(has_warning(*r, "Atlas group \"taken\""));
    CHECK(read_png(game / "assets/atlases/taken.png").width == 8);  // the project's own file, not an atlas
    CHECK_FALSE(f.shipped_manifest("linux")["assets"]["assets/b.png"].contains("packed"));
}
