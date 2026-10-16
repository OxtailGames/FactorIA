// Textures an export wrote: KTX2 twins (Basis Universal, transcoded to the format the GPU samples) and atlases.
// The KTX2 fixtures in tests/data were written with the encoder `factoria export` uses, from the patterns below (UASTC
// 12x8 and 10x6, ETC1S 16x16), so these tests need no encoder: they cover the part of the pipeline that runs in every game.
#include "test_util.h"

#include <algorithm>
#include <cstring>
#include <filesystem>
#include <fstream>

#include <transcoder/basisu_transcoder.h>

#include "fa/core/asset_manifest.h"
#include "fa/scene/bounds.h"

using namespace fa;
using namespace fa::test;
namespace stdfs = std::filesystem;

namespace {

// ---- fixtures ---------------------------------------------------------------------------------------------------

Image pattern(int w, int h, int seed) {
    Image img;
    img.width = w;
    img.height = h;
    img.rgba.resize(std::size_t(w) * h * 4);
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            std::uint8_t* p = &img.rgba[(std::size_t(y) * w + x) * 4];
            p[0] = std::uint8_t(x * 255 / std::max(1, w - 1));
            p[1] = std::uint8_t(y * 255 / std::max(1, h - 1));
            p[2] = std::uint8_t(seed * 60 + ((x + y) % 2) * 100);
            p[3] = 255;
        }
    }
    return img;
}

// The image tests/data/uastc_<w>x<h>.ktx2 was encoded from, with a translucent left edge.
Image pattern_uastc(int w, int h) {
    Image img;
    img.width = w;
    img.height = h;
    img.rgba.resize(std::size_t(w) * h * 4);
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            std::uint8_t* p = &img.rgba[(std::size_t(y) * w + x) * 4];
            p[0] = std::uint8_t(x * 25);
            p[1] = std::uint8_t(y * 45);
            p[2] = std::uint8_t(((x + y) % 2) * 200 + 20);
            p[3] = x < 2 ? 128 : 255;
        }
    }
    return img;
}

// The image tests/data/etc1s_16x16.ktx2 was encoded from.
Image pattern_etc1s() {
    Image img;
    img.width = 16;
    img.height = 16;
    img.rgba.resize(16 * 16 * 4);
    for (int y = 0; y < 16; ++y) {
        for (int x = 0; x < 16; ++x) {
            std::uint8_t* p = &img.rgba[(std::size_t(y) * 16 + x) * 4];
            p[0] = std::uint8_t(x * 16);
            p[1] = std::uint8_t(y * 16);
            p[2] = 128;
            p[3] = 255;
        }
    }
    return img;
}

void put_file(const std::string& projectPath, const std::string& bytes) {
    const stdfs::path file = fs::project_root() / projectPath;
    stdfs::create_directories(file.parent_path());
    std::ofstream(file, std::ios::binary).write(bytes.data(), std::streamsize(bytes.size()));
}

void install_fixture(const char* name, const std::string& projectPath) {
    std::ifstream in(stdfs::path(FA_RENDER_DATA_DIR) / name, std::ios::binary);
    REQUIRE_MESSAGE(in.good(), "missing fixture " << name);
    put_file(projectPath, std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>()));
}

void put_png(const std::string& projectPath, const Image& img) {
    REQUIRE(save_png(img, projectPath).ok());
}

void remove_file(const std::string& projectPath) {
    std::error_code ec;
    stdfs::remove(fs::project_root() / projectPath, ec);
}

// Sets (or, with nullptr, clears) an environment variable for the life of the object.
struct ScopedEnv {
    std::string name;
    std::string old;
    bool had = false;
    ScopedEnv(const char* n, const char* value) : name(n) {
        if (const char* cur = std::getenv(n)) {
            had = true;
            old = cur;
        }
        set(value);
    }
    ~ScopedEnv() { set(had ? old.c_str() : nullptr); }
    void set(const char* value) const {
#if defined(_WIN32)
        _putenv_s(name.c_str(), value ? value : "");  // an empty value removes the variable
#else
        if (value) setenv(name.c_str(), value, 1);
        else unsetenv(name.c_str());
#endif
    }
};

// The assets.json of the temp project for the life of the object.
struct ScopedManifest {
    explicit ScopedManifest(const std::string& json) { put_file("assets.json", json); }
    ~ScopedManifest() { remove_file("assets.json"); }
};

// The report entry of a loaded texture; a null Json when it is not loaded.
Json texture_entry(Gfx& g, const std::string& path) {
    const Json report = g.renderer.asset_report();
    for (const Json& t : report["textures"])
        if (t["path"] == path) return t;
    return Json();
}

bool has_failure(Gfx& g, const std::string& path) {
    const Json report = g.renderer.asset_report();
    for (const Json& f : report["failures"])
        if (f["path"] == path) return true;
    return false;
}

// One sprite of `texture` in front of a camera.
void single_sprite(World& w, const std::string& texture, Vec2 size = {100, 60}, bool pixelArt = true) {
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = Color::hex(0x202830);
    Entity e = make(w, "s", {0, 0, 0});
    auto& s = w.add<Sprite>(e);
    s.texture = texture;
    s.size = size;
    s.pixelArt = pixelArt;
}

// What the renderer is expected to hold for a texture with its whole mip chain: 4 bytes a pixel, or 16 a 4x4 block.
std::size_t expected_bytes(const std::string& format, int w, int h) {
    std::size_t total = 0;
    for (;; w = std::max(1, w / 2), h = std::max(1, h / 2)) {
        total += format == "RGBA8" ? std::size_t(w) * h * 4 : std::size_t((w + 3) / 4) * ((h + 3) / 4) * 16;
        if (w == 1 && h == 1) return total;
    }
}

}  // namespace

TEST_CASE("textures: a KTX2 twin is drawn in place of the texture it replaces, with every mip and the original size") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    install_fixture("uastc_12x8.ktx2", "assets/kt_twin.png.ktx2");  // only the twin exists: the export dropped the PNG
    put_png("assets/kt_ref.png", pattern_uastc(12, 8));

    World twin, ref;
    single_sprite(twin, "assets/kt_twin.png");
    single_sprite(ref, "assets/kt_ref.png");
    const Image a = g.render(twin);
    const Image b = g.render(ref);

    const Json entry = texture_entry(g, "assets/kt_twin.png");
    REQUIRE(entry.is_object());
    CHECK(entry["width"] == 12);
    CHECK(entry["height"] == 8);
    const std::string format = entry["format"];
    MESSAGE("GPU format picked for a KTX2 texture: " << format);
    CHECK((format == "ASTC_4x4" || format == "BC7" || format == "ETC2_RGBA8" || format == "RGBA8"));
    CHECK(entry["bytes"] == expected_bytes(format, 12, 8));
    CHECK(texture_entry(g, "assets/kt_ref.png")["bytes"] == expected_bytes("RGBA8", 12, 8));  // uncompressed: 3 times more
    CHECK_FALSE(has_failure(g, "assets/kt_twin.png"));

    // Lossy, so not identical to the PNG; but the same picture. The pattern is the worst case for a block codec (a
    // one-pixel checker in one channel under gradients in the others): about 0.6% mean error, a few edge pixels far off.
    const ImageDiff d = diff_images(a, b, 8.0f / 255.0f);
    INFO("meanError=" << d.meanError << " maxError=" << d.maxError);
    CHECK(d.sameSize);
    CHECK(d.meanError < 0.01);
    // Not just the clear colour.
    CHECK(diff_images(a, [&] { World w; single_sprite(w, ""); return g.render(w); }(), 0.02f).meanError > 0.02);
}

TEST_CASE("textures: FA_TEXTURE_FORMAT picks the format, and every choice draws the same picture") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    put_png("assets/kf_ref.png", pattern_uastc(12, 8));
    World ref;
    single_sprite(ref, "assets/kf_ref.png");
    const Image reference = g.render(ref);

    bool anyCompressed = false;
    for (const std::string wanted : {"astc", "bc7", "etc2", "rgba8", "bogus"}) {
        CAPTURE(wanted);
        const std::string path = "assets/kf_" + wanted + ".png";
        install_fixture("uastc_12x8.ktx2", path + ".ktx2");
        ScopedEnv env("FA_TEXTURE_FORMAT", wanted.c_str());
        World w;
        single_sprite(w, path);
        const Image img = g.render(w);
        const Json entry = texture_entry(g, path);
        REQUIRE(entry.is_object());
        const std::string format = entry["format"];
        MESSAGE("FA_TEXTURE_FORMAT=" << wanted << " -> " << format);
        // A format the GPU cannot sample (or an unknown name) falls back to RGBA8, never to a broken texture.
        if (wanted == "astc") CHECK((format == "ASTC_4x4" || format == "RGBA8"));
        if (wanted == "bc7") CHECK((format == "BC7" || format == "RGBA8"));
        if (wanted == "etc2") CHECK((format == "ETC2_RGBA8" || format == "RGBA8"));
        if (wanted == "rgba8" || wanted == "bogus") CHECK(format == "RGBA8");
        CHECK(entry["bytes"] == expected_bytes(format, 12, 8));
        anyCompressed = anyCompressed || format != "RGBA8";
        const ImageDiff d = diff_images(img, reference, 8.0f / 255.0f);
        INFO("meanError=" << d.meanError);
        CHECK(d.meanError < 0.01);
    }
    if (!anyCompressed) MESSAGE("this GPU samples none of ASTC 4x4, BC7 and ETC2: KTX2 textures were transcoded to RGBA8");
}

TEST_CASE("textures: a size that is not a whole number of 4x4 blocks is transcoded to RGBA8, without a GPU error") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    clear_recent_logs();
    install_fixture("uastc_10x6.ktx2", "assets/ko_twin.png.ktx2");
    put_png("assets/ko_ref.png", pattern_uastc(10, 6));
    World twin, ref;
    single_sprite(twin, "assets/ko_twin.png");
    single_sprite(ref, "assets/ko_ref.png");
    const Image a = g.render(twin);
    const Image b = g.render(ref);
    const Json entry = texture_entry(g, "assets/ko_twin.png");
    REQUIRE(entry.is_object());
    CHECK(entry["width"] == 10);  // the picture's size, whatever the format
    CHECK(entry["height"] == 6);
    CHECK(entry["format"] == "RGBA8");  // D3D11 and WebGPU would refuse BC7 here
    CHECK(entry["bytes"] == expected_bytes("RGBA8", 10, 6));
    CHECK(diff_images(a, b, 8.0f / 255.0f).meanError < 0.01);
    for (const auto& l : recent_logs(100, LogLevel::Error)) CHECK_MESSAGE(l.message.find("ko_twin") == std::string::npos, l.message);
}

TEST_CASE("textures: ETC1S files load too") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    install_fixture("etc1s_16x16.ktx2", "assets/ke_twin.png.ktx2");
    put_png("assets/ke_ref.png", pattern_etc1s());
    World twin, ref;
    single_sprite(twin, "assets/ke_twin.png", {96, 96}, false);
    single_sprite(ref, "assets/ke_ref.png", {96, 96}, false);
    const Image a = g.render(twin);
    const Image b = g.render(ref);
    const Json entry = texture_entry(g, "assets/ke_twin.png");
    REQUIRE(entry.is_object());
    CHECK(entry["width"] == 16);
    CHECK(entry["height"] == 16);
    const ImageDiff d = diff_images(a, b, 16.0f / 255.0f);
    INFO("meanError=" << d.meanError << " maxError=" << d.maxError);
    CHECK(d.meanError < 0.02);  // ETC1S trades quality for size: looser than UASTC, still the same gradient
}

TEST_CASE("textures: a damaged twin falls back to the placeholder with one error, and a fixed file loads on hot reload") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    clear_recent_logs();
    put_file("assets/kb_bad.png.ktx2", "this is not a KTX2 file");
    World w;
    single_sprite(w, "assets/kb_bad.png");
    for (int i = 0; i < 3; ++i) g.render(w);  // three frames, one error
    int errors = 0;
    std::string message;
    for (const auto& l : recent_logs(100, LogLevel::Error))
        if (l.message.find("kb_bad.png") != std::string::npos) {
            ++errors;
            message = l.message;
        }
    CHECK(errors == 1);
    CHECK(message.find("assets/kb_bad.png.ktx2") != std::string::npos);
    CHECK(message.find("Export the project again") != std::string::npos);
    CHECK(has_failure(g, "assets/kb_bad.png"));
    CHECK_FALSE(texture_entry(g, "assets/kb_bad.png").is_object());  // the placeholder is not a texture of the game

    install_fixture("uastc_12x8.ktx2", "assets/kb_bad.png.ktx2");
    g.renderer.reload_asset("assets/kb_bad.png.ktx2");  // the watcher reports the file that changed: the twin
    g.render(w);
    CHECK_FALSE(has_failure(g, "assets/kb_bad.png"));
    const Json entry = texture_entry(g, "assets/kb_bad.png");
    REQUIRE(entry.is_object());
    CHECK(entry["width"] == 12);

    // A different file under the same name replaces the texture in place.
    install_fixture("etc1s_16x16.ktx2", "assets/kb_bad.png.ktx2");
    g.renderer.reload_asset("assets/kb_bad.png.ktx2");
    g.render(w);
    const Json again = texture_entry(g, "assets/kb_bad.png");
    REQUIRE(again.is_object());
    CHECK(again["width"] == 16);
    CHECK(again["height"] == 16);

    // And the twin may go away again: the PNG (here a different size) is what loads then.
    remove_file("assets/kb_bad.png.ktx2");
    put_png("assets/kb_bad.png", pattern(8, 8, 1));
    g.renderer.reload_asset("assets/kb_bad.png");
    g.render(w);
    CHECK(texture_entry(g, "assets/kb_bad.png")["width"] == 8);
}

namespace {

// Copies `img` into `atlas` at (x, y) with `pad` pixels of its own edge repeated around it (what the export writes).
void blit_extruded(Image& atlas, const Image& img, int x, int y, int pad = 2) {
    for (int dy = -pad; dy < img.height + pad; ++dy) {
        for (int dx = -pad; dx < img.width + pad; ++dx) {
            const int sx = std::clamp(dx, 0, img.width - 1), sy = std::clamp(dy, 0, img.height - 1);
            atlas.set_pixel(x + dx, y + dy, img.pixel(sx, sy));
        }
    }
}

struct AtlasFixture {
    Image a = pattern(8, 8, 1), b = pattern(12, 6, 2), sheet = pattern(16, 8, 3), spark = pattern(4, 4, 0);
    AtlasFixture() {
        // Frame 2 of the sheet is another picture, so a wrong frame shows.
        for (int y = 0; y < 8; ++y)
            for (int x = 8; x < 16; ++x) sheet.set_pixel(x, y, Color{1.0f - float(x - 8) / 8.0f, 0.2f, float(y) / 8.0f, 1});
        Image atlas;
        atlas.width = 64;
        atlas.height = 32;
        atlas.rgba.assign(64 * 32 * 4, 0);
        blit_extruded(atlas, a, 2, 2);
        blit_extruded(atlas, b, 16, 2);
        blit_extruded(atlas, sheet, 2, 18);
        blit_extruded(atlas, spark, 36, 2);
        put_png("assets/atlases/g.png", atlas);
        put_png("assets/ref_a.png", a);
        put_png("assets/ref_b.png", b);
        put_png("assets/ref_sheet.png", sheet);
        put_png("assets/ref_spark.png", spark);
    }
    static std::string manifest() {
        auto entry = [](const char* path, int x, int y, int w, int h) {
            return std::string("\"") + path + "\": {\"packed\": {\"atlas\": \"assets/atlases/g.png\", \"rect\": [" + std::to_string(x) + ", " +
                   std::to_string(y) + ", " + std::to_string(w) + ", " + std::to_string(h) + "]}}";
        };
        return "{\"format\": \"factoria.assets/1\", \"assets\": {" + entry("assets/pk_a.png", 2, 2, 8, 8) + ", " +
               entry("assets/pk_b.png", 16, 2, 12, 6) + ", " + entry("assets/pk_sheet.png", 2, 18, 16, 8) + ", " +
               entry("assets/pk_spark.png", 36, 2, 4, 4) + "}}";
    }
};

// Every way a 2D texture reaches the screen: a sprite filtered linearly (its edges read the padding), a sprite with a
// region, a flipbook, a screen-space sprite and particles. `packed` names the textures the atlas holds.
std::vector<Entity> build_scene(World& w, bool packed) {
    auto tex = [&](const char* name) { return std::string("assets/") + (packed ? "pk_" : "ref_") + name + ".png"; };
    std::vector<Entity> sprites;
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = Color::hex(0x202830);

    Entity a = make(w, "a", {-110, 50, 0});
    {
        auto& s = w.add<Sprite>(a);
        s.texture = tex("a");
        s.size = {40, 40};
        s.pixelArt = false;
    }
    Entity b = make(w, "b", {-50, 50, 0});
    {
        auto& s = w.add<Sprite>(b);
        s.texture = tex("b");
        s.region = Rect{2, 1, 6, 4};
        s.size = {48, 32};
        s.pixelArt = false;
        s.flipX = true;
    }
    Entity sheet = make(w, "sheet", {10, 50, 0});
    {
        auto& s = w.add<Sprite>(sheet);
        s.texture = tex("sheet");
        s.size = {32, 32};
        auto& an = w.add<SpriteAnimator>(sheet);
        an.columns = 2;
        an.rows = 1;
        an.firstFrame = 1;
        an.lastFrame = 1;
        an.playing = false;
        an.frame = 1;
    }
    Entity hud = make(w, "hud", {20, 20, 0});
    {
        auto& s = w.add<Sprite>(hud);
        s.texture = tex("a");
        s.size = {24, 24};
        s.space = RenderSpace::Screen;
    }
    Entity fx = make(w, "fx", {90, -40, 0});
    {
        auto& p = w.add<ParticleEmitter>(fx);
        p.texture = tex("spark");
        p.rate = 0;
        p.burst = 40;
        p.lifetime = 1.0f;
        p.speed = 80;
        p.spread = 60;
        p.startSize = 12;
        p.endSize = 6;
        p.endColor = Color::white();
    }
    return {a, b, sheet, hud};
}

}  // namespace

TEST_CASE("textures: sprites of a packed atlas draw exactly like the textures they replace, with the same bounds") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    AtlasFixture atlas;
    ScopedManifest manifest(AtlasFixture::manifest());

    World packed, plain;
    const std::vector<Entity> packedSprites = build_scene(packed, true);
    const std::vector<Entity> plainSprites = build_scene(plain, false);
    Image a, b;
    for (int i = 0; i < 20; ++i) a = g.render(packed, 1.0f / 60.0f);
    g.renderer.clear_asset_cache();  // resets emitter states so both worlds start identically
    for (int i = 0; i < 20; ++i) b = g.render(plain, 1.0f / 60.0f);

    const ImageDiff d = diff_images(a, b, 1.0f / 255.0f);
    INFO("meanError=" << d.meanError << " maxError=" << d.maxError << " differingPixels=" << d.differingPixels);
    CHECK(d.meanError < 0.0005);
    CHECK(d.differingPixels < 40);
    // The picture is not empty: the sprites and the particles are there.
    CHECK(g.renderer.stats().particles > 20);
    World empty;
    Entity cam = make(empty, "cam");
    empty.add<Camera>(cam).clearColor = Color::hex(0x202830);
    CHECK(diff_images(a, g.render(empty), 0.02f).meanError > 0.015);

    // The packed textures share the atlas's GPU image: the report says where each one lives and charges the bytes once.
    g.renderer.clear_asset_cache();
    g.render(packed, 1.0f / 60.0f);
    const Json entry = texture_entry(g, "assets/pk_b.png");
    REQUIRE(entry.is_object());
    CHECK(entry["atlas"] == "assets/atlases/g.png");
    CHECK(entry["width"] == 12);
    CHECK(entry["height"] == 6);
    CHECK(entry["bytes"] == 0);
    CHECK(texture_entry(g, "assets/atlases/g.png")["bytes"].get<int>() > 0);

    // What scripts and the editor measure does not change: entity.bounds() asks texture_size() for the picture's size.
    VisualMeasure measure;
    measure.textureSize = [](const std::string& path) {
        auto size = texture_size(path);
        return size.ok() ? Vec2{float(size->width), float(size->height)} : Vec2{32, 32};
    };
    for (std::size_t i = 0; i < packedSprites.size(); ++i) {
        CAPTURE(i);
        const auto pf = visual_footprints(packed, packedSprites[i], measure);  // screen-space ones included
        const auto rf = visual_footprints(plain, plainSprites[i], measure);
        REQUIRE(!pf.empty());
        REQUIRE(pf.size() == rf.size());
        for (std::size_t j = 0; j < pf.size(); ++j) {
            for (int k = 0; k < 4; ++k) {
                CHECK(pf[j].box[std::size_t(k)].x == doctest::Approx(rf[j].box[std::size_t(k)].x));
                CHECK(pf[j].box[std::size_t(k)].y == doctest::Approx(rf[j].box[std::size_t(k)].y));
            }
        }
    }
    // A sprite with no size and no region is as big as its picture (8x8), not as the whole atlas (64x32).
    World bare;
    Entity e = make(bare, "bare");
    bare.add<Sprite>(e).texture = "assets/pk_a.png";
    auto r = entity_world_rect(bare, e, measure);
    REQUIRE(r.has_value());
    CHECK(r->w == doctest::Approx(8.0f));
    CHECK(r->h == doctest::Approx(8.0f));
}

TEST_CASE("textures: a texture packed into an atlas that cannot be loaded is one reported failure, not a crash") {
    Gfx& g = gfx();
    REQUIRE(g.ok);
    clear_recent_logs();
    ScopedManifest manifest(R"({"format": "factoria.assets/1", "assets": {"assets/pk_lost.png":
        {"packed": {"atlas": "assets/atlases/lost.png", "rect": [2, 2, 8, 8]}}}})");
    World w;
    single_sprite(w, "assets/pk_lost.png");
    for (int i = 0; i < 3; ++i) g.render(w);
    CHECK(has_failure(g, "assets/pk_lost.png"));
    CHECK(has_failure(g, "assets/atlases/lost.png"));
    int errors = 0;
    for (const auto& l : recent_logs(100, LogLevel::Error))
        if (l.message.find("pk_lost.png") != std::string::npos) ++errors;
    CHECK(errors == 1);
}

// The GPU on a development machine samples one or two of these formats, so the others are checked on the data itself:
// every format the engine asks the transcoder for must come out for every mip of every codec, and ASTC (what phones
// sample) must decode to the same picture as the RGBA32 transcoding. UASTC is a subset of ASTC, so for it that is exact.
TEST_CASE("textures: every format the engine transcodes to works for every mip of both codecs, and ASTC decodes to the picture") {
    basist::basisu_transcoder_init();
    struct Fixture {
        const char* file;
        bool uastc;
    };
    for (const Fixture& fx : {Fixture{"uastc_12x8.ktx2", true}, Fixture{"uastc_10x6.ktx2", true}, Fixture{"etc1s_16x16.ktx2", false}}) {
        CAPTURE(fx.file);
        std::ifstream in(stdfs::path(FA_RENDER_DATA_DIR) / fx.file, std::ios::binary);
        REQUIRE(in.good());
        const std::string bytes((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
        basist::ktx2_transcoder ktx;
        REQUIRE(ktx.init(bytes.data(), std::uint32_t(bytes.size())));
        CHECK((fx.uastc ? ktx.is_uastc() : ktx.is_etc1s()));
        REQUIRE(ktx.start_transcoding());
        REQUIRE(ktx.get_levels() >= 2);  // the export wrote the whole mip chain

        using Format = basist::transcoder_texture_format;
        for (const Format format : {Format::cTFASTC_4x4_RGBA, Format::cTFBC7_RGBA, Format::cTFETC2_RGBA, Format::cTFRGBA32}) {
            CAPTURE(int(format));
            for (std::uint32_t level = 0; level < ktx.get_levels(); ++level) {
                basist::ktx2_image_level_info info{};
                REQUIRE(ktx.get_image_level_info(info, level, 0, 0));
                const bool block = format != Format::cTFRGBA32;
                const std::uint32_t units = block ? info.m_total_blocks : info.m_orig_width * info.m_orig_height;
                std::vector<std::uint8_t> out(std::size_t(units) * basist::basis_get_bytes_per_block_or_pixel(format));
                CHECK_MESSAGE(ktx.transcode_image_level(level, 0, 0, out.data(), units, format), "level " << level);
            }
        }

        // Level 0: ASTC blocks decoded in software against the RGBA32 transcoding.
        basist::ktx2_image_level_info info{};
        REQUIRE(ktx.get_image_level_info(info, 0, 0, 0));
        std::vector<std::uint8_t> astc(std::size_t(info.m_total_blocks) * 16), rgba(std::size_t(info.m_orig_width) * info.m_orig_height * 4);
        REQUIRE(ktx.transcode_image_level(0, 0, 0, astc.data(), info.m_total_blocks, Format::cTFASTC_4x4_RGBA));
        REQUIRE(ktx.transcode_image_level(0, 0, 0, rgba.data(), info.m_orig_width * info.m_orig_height, Format::cTFRGBA32));
        double sum = 0;
        int worst = 0;
        for (std::uint32_t y = 0; y < info.m_orig_height; ++y) {
            for (std::uint32_t x = 0; x < info.m_orig_width; ++x) {
                const std::uint8_t* blockData = &astc[(std::size_t(y / 4) * info.m_num_blocks_x + x / 4) * 16];
                astc_helpers::log_astc_block logical;
                std::uint8_t pixels[4 * 4 * 4];
                REQUIRE(astc_helpers::unpack_block(blockData, logical, 4, 4));
                REQUIRE(astc_helpers::decode_block(logical, pixels, 4, 4, astc_helpers::cDecodeModeLDR8));
                for (int c = 0; c < 4; ++c) {
                    const int diff = std::abs(int(pixels[((y % 4) * 4 + x % 4) * 4 + c]) - int(rgba[(std::size_t(y) * info.m_orig_width + x) * 4 + c]));
                    sum += diff;
                    worst = std::max(worst, diff);
                }
            }
        }
        const double mean = sum / (double(info.m_orig_width) * info.m_orig_height * 4);
        INFO("mean difference " << mean << ", worst " << worst << " (of 255)");
        CHECK(mean < (fx.uastc ? 0.5 : 6.0));
        if (fx.uastc) CHECK(worst <= 2);
    }
}
