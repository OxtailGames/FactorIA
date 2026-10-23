// assets.import: where files land, provenance, the copied formats, Aseprite, PSD.
#include <doctest.h>

#include <cstring>

#include "asset_test_helpers.h"
#include "fa/core/asset_manifest.h"
#include "fa/tooling/validate.h"

extern "C" unsigned char* stbi_zlib_compress(unsigned char* data, int data_len, int* out_len, int quality);  // stb_image_write

using namespace fa;
using namespace fa::testing;
namespace stdfs = std::filesystem;

namespace {

// ---- a tiny Aseprite writer ------------------------------------------------------------------------------

struct Bytes {
    std::vector<std::uint8_t> v;
    Bytes& u8(unsigned x) { v.push_back(std::uint8_t(x)); return *this; }
    Bytes& u16(unsigned x) { return u8(x & 255).u8(x >> 8); }
    Bytes& u32(unsigned x) { return u16(x & 0xffff).u16(x >> 16); }
    Bytes& zeros(int n) { v.insert(v.end(), std::size_t(n), 0); return *this; }
    Bytes& str(const std::string& s) { u16(unsigned(s.size())); v.insert(v.end(), s.begin(), s.end()); return *this; }
    Bytes& add(const Bytes& b) { v.insert(v.end(), b.v.begin(), b.v.end()); return *this; }
};

Bytes chunk(unsigned type, const Bytes& data) { return Bytes().u32(unsigned(data.v.size()) + 6).u16(type).add(data); }

Bytes layer(const std::string& name, unsigned flags = 1, unsigned blend = 0, unsigned opacity = 255, unsigned type = 0, unsigned level = 0) {
    return chunk(0x2004, Bytes().u16(flags).u16(type).u16(level).u16(0).u16(0).u16(blend).u8(opacity).zeros(3).str(name));
}

Bytes cel_header(unsigned layerIndex, int x, int y, unsigned opacity, unsigned type, int z = 0) {
    return Bytes().u16(layerIndex).u16(unsigned(x) & 0xffff).u16(unsigned(y) & 0xffff).u8(opacity).u16(type).u16(unsigned(z) & 0xffff).zeros(5);
}

Bytes cel_raw(unsigned layerIndex, int x, int y, int w, int h, const std::vector<std::uint8_t>& pixels, unsigned opacity = 255) {
    Bytes b = cel_header(layerIndex, x, y, opacity, 0);
    b.u16(unsigned(w)).u16(unsigned(h));
    b.v.insert(b.v.end(), pixels.begin(), pixels.end());
    return chunk(0x2005, b);
}

Bytes cel_zlib(unsigned layerIndex, int x, int y, int w, int h, const std::vector<std::uint8_t>& pixels, unsigned opacity = 255) {
    int length = 0;
    std::vector<std::uint8_t> copy = pixels;
    unsigned char* z = stbi_zlib_compress(copy.data(), int(copy.size()), &length, 8);
    REQUIRE(z != nullptr);
    Bytes b = cel_header(layerIndex, x, y, opacity, 2);
    b.u16(unsigned(w)).u16(unsigned(h));
    b.v.insert(b.v.end(), z, z + length);
    std::free(z);
    return chunk(0x2005, b);
}

Bytes cel_linked(unsigned layerIndex, unsigned frame) { return chunk(0x2005, cel_header(layerIndex, 0, 0, 255, 1).u16(frame)); }

// from, to, direction, name
Bytes tags(const std::vector<std::tuple<int, int, int, std::string>>& list) {
    Bytes b;
    b.u16(unsigned(list.size())).zeros(8);
    for (const auto& [from, to, dir, name] : list) b.u16(unsigned(from)).u16(unsigned(to)).u8(unsigned(dir)).u16(0).zeros(6).zeros(3).u8(0).str(name);
    return chunk(0x2018, b);
}

Bytes palette(const std::vector<Rgba>& colors) {
    Bytes b;
    b.u32(unsigned(colors.size())).u32(0).u32(unsigned(colors.size()) - 1).zeros(8);
    for (const Rgba& c : colors) b.u16(0).u8(c.r).u8(c.g).u8(c.b).u8(c.a);
    return chunk(0x2019, b);
}

Bytes frame(unsigned durationMs, const std::vector<Bytes>& chunks) {
    Bytes body;
    for (const Bytes& c : chunks) body.add(c);
    Bytes b;
    b.u32(unsigned(body.v.size()) + 16).u16(0xF1FA).u16(unsigned(chunks.size())).u16(durationMs).zeros(2).u32(0);
    return b.add(body);
}

std::string aseprite(int w, int h, int depth, const std::vector<Bytes>& frames, unsigned transparentIndex = 0) {
    Bytes body;
    for (const Bytes& f : frames) body.add(f);
    Bytes b;
    b.u32(unsigned(body.v.size()) + 128).u16(0xA5E0).u16(unsigned(frames.size())).u16(unsigned(w)).u16(unsigned(h)).u16(unsigned(depth));
    b.u32(1).u16(100).u32(0).u32(0).u8(transparentIndex).zeros(3).u16(0).u8(1).u8(1).zeros(8).zeros(84);
    REQUIRE(b.v.size() == 128);
    b.add(body);
    return std::string(b.v.begin(), b.v.end());
}

std::vector<std::uint8_t> rgba_block(int count, Rgba c) {
    std::vector<std::uint8_t> v;
    for (int i = 0; i < count; ++i) v.insert(v.end(), {c.r, c.g, c.b, c.a});
    return v;
}

const Json* find_clip(const Json& sheet, const std::string& name) {
    for (const Json& c : sheet["clips"])
        if (c["name"] == name) return &c;
    return nullptr;
}

// A file from elsewhere on the machine: outside the project folder.
std::string art(AssetsProject& p, const std::string& name, const std::string& bytes) {
    const stdfs::path file = p.tmp.path / "art" / name;
    write_all(file, bytes);
    return file.string();
}

}  // namespace

TEST_CASE("assets.import: Aseprite frames, layers, cels and tags become a sheet and its clips") {
    AssetsProject p;
    const Rgba red{255, 0, 0, 255}, blue{0, 0, 255, 255};
    // Layers: 0 "body", 1 "hidden" (not visible), 2 "half" (layer opacity 128), 3 "glow" (addition blend mode).
    std::vector<Bytes> first = {layer("body"), layer("hidden", 0), layer("half", 1, 0, 128), layer("glow", 1, 16)};
    first.push_back(cel_zlib(0, 0, 0, 4, 2, rgba_block(8, red)));   // a compressed cel: the whole frame red
    first.push_back(cel_zlib(1, 0, 0, 4, 2, rgba_block(8, blue)));  // on a hidden layer: must not show
    first.push_back(tags({{0, 1, 0, "idle"}, {2, 3, 2, "run"}}));    // "run" is ping-pong
    std::vector<Bytes> frames;
    frames.push_back(frame(100, first));
    frames.push_back(frame(100, {cel_linked(0, 0)}));                                              // a linked cel: red again
    frames.push_back(frame(50, {cel_raw(0, 1, 1, 2, 1, rgba_block(2, {0, 255, 0, 255}), 128)}));  // raw, partial, cel opacity 128
    frames.push_back(frame(50, {cel_raw(2, 0, 0, 1, 1, rgba_block(1, red))}));                    // on the layer with opacity 128
    const std::string source = art(p, "hero.aseprite", aseprite(4, 2, 32, frames));

    const Json r = p.ok("assets.import", {{"source", source}, {"license", "CC0"}, {"author", "Ana"}});
    CHECK(r["importer"] == "aseprite");
    CHECK(r["path"] == "assets/hero.png");
    const Json& sheet = r["sheet"];
    CHECK(sheet["columns"] == 2);
    CHECK(sheet["rows"] == 2);
    CHECK(sheet["frameWidth"] == 4);
    CHECK(sheet["frameHeight"] == 2);
    CHECK(sheet["frames"] == 4);
    REQUIRE(sheet["clips"].size() == 2);
    const Json* idle = find_clip(sheet, "idle");
    const Json* run = find_clip(sheet, "run");
    REQUIRE((idle && run));
    CHECK((*idle)["firstFrame"] == 0);
    CHECK((*idle)["lastFrame"] == 1);
    CHECK((*idle)["fps"] == 10);
    CHECK((*run)["firstFrame"] == 2);
    CHECK((*run)["lastFrame"] == 3);
    CHECK((*run)["fps"] == 20);
    CHECK(has_text(r["warnings"], "'run' (ping-pong)"));
    CHECK(has_text(r["warnings"], "'glow' (addition)"));
    CHECK(has_text(r["nextSteps"], "SpriteAnimator"));

    const Image img = read_png(p.file("assets/hero.png"));
    REQUIRE(img.width == 8);
    REQUIRE(img.height == 4);
    CHECK(get(img, 0, 0) == red);  // frame 0: red everywhere, the hidden blue layer is not drawn
    CHECK(get(img, 3, 1) == red);
    CHECK(get(img, 4, 0) == red);  // frame 1: the linked cel
    CHECK(get(img, 7, 1) == red);
    CHECK(get(img, 0, 2).a == 0);  // frame 2: only the partial cel
    CHECK(get(img, 1, 3) == Rgba{0, 255, 0, 128});
    CHECK(get(img, 2, 3) == Rgba{0, 255, 0, 128});
    CHECK(get(img, 3, 3).a == 0);
    CHECK(get(img, 4, 2) == Rgba{255, 0, 0, 128});  // frame 3: layer opacity 128
    CHECK(get(img, 5, 2).a == 0);

    const Json entry = p.manifest()["assets"]["assets/hero.png"];
    CHECK(entry["sheet"] == sheet);
    CHECK(entry["provenance"]["origin"] == "imported");
    CHECK(entry["provenance"]["license"] == "CC0");
    CHECK(entry["provenance"]["author"] == "Ana");
    CHECK(entry["provenance"]["date"] == assets::today());
    CHECK(entry["provenance"]["source"].get<std::string>().find("hero.aseprite") != std::string::npos);
    CHECK_FALSE(entry["provenance"].contains("ai"));

    // `columns` lays the frames out in one row.
    const Json row = p.ok("assets.import", {{"source", source}, {"path", "assets/row.png"}, {"columns", 4}});
    CHECK(row["sheet"]["columns"] == 4);
    CHECK(row["sheet"]["rows"] == 1);
    CHECK(read_png(p.file("assets/row.png")).width == 16);
}

TEST_CASE("assets.import: Aseprite indexed color uses the palette and the transparent index; grayscale uses its alpha") {
    AssetsProject p;
    const Bytes pal = palette({{0, 0, 0, 255}, {255, 0, 0, 255}, {0, 255, 0, 128}});
    const std::vector<std::uint8_t> indices = {0, 1, 2, 1};
    const std::string indexed = art(p, "indexed.aseprite", aseprite(2, 2, 8, {frame(100, {pal, layer("l"), cel_raw(0, 0, 0, 2, 2, indices)})}));
    p.ok("assets.import", {{"source", indexed}});
    const Image a = read_png(p.file("assets/indexed.png"));
    CHECK(get(a, 0, 0).a == 0);  // the transparent index
    CHECK(get(a, 1, 0) == Rgba{255, 0, 0, 255});
    CHECK(get(a, 0, 1) == Rgba{0, 255, 0, 128});  // the palette entry has its own alpha
    CHECK(get(a, 1, 1) == Rgba{255, 0, 0, 255});

    // On a Background layer the transparent index is an ordinary color.
    const std::string background = art(p, "bg.aseprite", aseprite(2, 2, 8, {frame(100, {pal, layer("Background", 1 | 8), cel_raw(0, 0, 0, 2, 2, indices)})}));
    p.ok("assets.import", {{"source", background}});
    CHECK(get(read_png(p.file("assets/bg.png")), 0, 0) == Rgba{0, 0, 0, 255});

    // The old palette chunk (0x0004).
    const Bytes oldPalette = chunk(0x0004, Bytes().u16(1).u8(0).u8(2).u8(255).u8(0).u8(0).u8(0).u8(255).u8(0));
    const std::string old = art(p, "old.aseprite", aseprite(2, 1, 8, {frame(100, {oldPalette, layer("l"), cel_raw(0, 0, 0, 2, 1, {0, 1})})}, 5));
    p.ok("assets.import", {{"source", old}});
    const Image o = read_png(p.file("assets/old.png"));
    CHECK(get(o, 0, 0) == Rgba{255, 0, 0, 255});
    CHECK(get(o, 1, 0) == Rgba{0, 255, 0, 255});

    const std::string gray = art(p, "gray.aseprite", aseprite(2, 1, 16, {frame(100, {layer("l"), cel_raw(0, 0, 0, 2, 1, {100, 255, 200, 128})})}));
    p.ok("assets.import", {{"source", gray}});
    const Image g = read_png(p.file("assets/gray.png"));
    CHECK(get(g, 0, 0) == Rgba{100, 100, 100, 255});
    CHECK(get(g, 1, 0) == Rgba{200, 200, 200, 128});
}

TEST_CASE("assets.import: a damaged Aseprite file is an error that says what is wrong") {
    AssetsProject p;
    const std::string good = aseprite(2, 1, 32, {frame(100, {layer("l"), cel_zlib(0, 0, 0, 2, 1, rgba_block(2, {1, 2, 3, 255}))})});
    CommandResult cut = p.call("assets.import", {{"source", art(p, "cut.aseprite", good.substr(0, good.size() - 6))}});
    REQUIRE_FALSE(cut.ok);
    CHECK(cut.error["message"].get<std::string>().find("cut.aseprite") != std::string::npos);
    CHECK(cut.error["message"].get<std::string>().find("cut short") != std::string::npos);
    CHECK_FALSE(cut.error["hint"].get<std::string>().empty());
    CommandResult notAse = p.call("assets.import", {{"source", art(p, "text.aseprite", std::string(200, 'x'))}});
    REQUIRE_FALSE(notAse.ok);
    CHECK(notAse.error["message"].get<std::string>().find("signature") != std::string::npos);
    CHECK_FALSE(p.exists("assets/cut.png"));
    CHECK_FALSE(p.exists("assets.json"));
}

TEST_CASE("assets.import: destination rules and the errors that teach") {
    AssetsProject p;
    const std::string png = art(p, "hero.png", png_string(make_image(4, 4, {9, 9, 9, 255})));

    const Json r = p.ok("assets.import", {{"source", png}, {"path", "assets/chars/"}, {"sourceUrl", "https://example.com/hero"}, {"ai", true}});
    CHECK(r["path"] == "assets/chars/hero.png");
    CHECK(r["details"]["width"] == 4);
    CHECK(p.manifest()["assets"]["assets/chars/hero.png"]["provenance"]["source"] == "https://example.com/hero");
    CHECK(p.manifest()["assets"]["assets/chars/hero.png"]["provenance"]["ai"] == true);
    CHECK(has_text(r["nextSteps"], "license"));  // no license given: the result asks for one

    CommandResult outside = p.call("assets.import", {{"source", png}, {"path", "sprites/hero.png"}});
    REQUIRE_FALSE(outside.ok);
    CHECK(outside.error["message"].get<std::string>().find("under assets/") != std::string::npos);
    CommandResult wrongExt = p.call("assets.import", {{"source", png}, {"path", "assets/hero.jpg"}});
    REQUIRE_FALSE(wrongExt.ok);
    CHECK(wrongExt.error["message"].get<std::string>().find("'.png'") != std::string::npos);
    CommandResult escape = p.call("assets.import", {{"source", png}, {"path", "assets/../../x.png"}});
    CHECK_FALSE(escape.ok);

    CommandResult again = p.call("assets.import", {{"source", png}, {"path", "assets/chars/hero.png"}});
    REQUIRE_FALSE(again.ok);
    CHECK(again.error["code"] == "exists");
    CHECK(again.error["hint"].get<std::string>().find("overwrite") != std::string::npos);
    CHECK(p.call("assets.import", {{"source", png}, {"path", "assets/chars/hero.png"}, {"overwrite", true}}).ok);

    CommandResult missing = p.call("assets.import", {{"source", (p.tmp.path / "nope.png").string()}});
    CHECK(missing.error["code"] == "not_found");
    CommandResult url = p.call("assets.import", {{"source", "https://example.com/x.png"}});
    REQUIRE_FALSE(url.ok);
    CHECK(url.error["hint"].get<std::string>().find("sourceUrl") != std::string::npos);
    CommandResult blend = p.call("assets.import", {{"source", art(p, "ship.blend", "x")}});
    REQUIRE_FALSE(blend.ok);
    CHECK(blend.error["hint"].get<std::string>().find("glTF") != std::string::npos);
    CommandResult notImage = p.call("assets.import", {{"source", art(p, "bad.png", "not a png")}});
    CHECK_FALSE(notImage.ok);
    CHECK_FALSE(p.exists("assets/bad.png"));

    // A broken assets.json is reported before any file is written.
    write_all(p.file("assets.json"), "{ nope");
    CommandResult broken = p.call("assets.import", {{"source", png}, {"path", "assets/other.png"}});
    REQUIRE_FALSE(broken.ok);
    CHECK(broken.error["message"].get<std::string>().find("assets.json") != std::string::npos);
    CHECK_FALSE(p.exists("assets/other.png"));
}

TEST_CASE("assets.import: sounds and fonts are copied into their folders; names are made safe") {
    AssetsProject p;
    const Json wav = p.ok("assets.import", {{"source", art(p, "Jump (2).wav", "RIFFdata")}, {"license", "CC-BY 4.0"}});
    CHECK(wav["path"] == "assets/audio/Jump__2_.wav");
    CHECK(read_all(p.file("assets/audio/Jump__2_.wav")) == "RIFFdata");
    CHECK(wav["written"][0]["kind"] == "audio");
    CHECK(has_text(wav["nextSteps"], "audio.play"));
    const Json font = p.ok("assets.import", {{"source", art(p, "Some Font.TTF", "ttfdata")}});
    CHECK(font["path"] == "assets/fonts/Some_Font.ttf");
}

TEST_CASE("assets.import: a .gltf brings its buffer and images along") {
    AssetsProject p;
    write_all(p.tmp.path / "art/model.bin", "abcd");
    write_png(p.tmp.path / "art/tex/wood floor.png", make_image(2, 2, {1, 2, 3, 255}));
    const std::string gltf = R"({"asset":{"version":"2.0"},"buffers":[{"uri":"model.bin","byteLength":4},{"uri":"data:application/octet-stream;base64,AAAA","byteLength":3}],
        "images":[{"uri":"tex/wood%20floor.png"},{"uri":"missing.png"}]})";
    const Json r = p.ok("assets.import", {{"source", art(p, "model.gltf", gltf)}});
    CHECK(r["path"] == "assets/models/model.gltf");
    CHECK(r["details"]["buffers"] == 1);
    CHECK(r["details"]["images"] == 1);
    CHECK(read_all(p.file("assets/models/model.bin")) == "abcd");
    CHECK(p.exists("assets/models/tex/wood floor.png"));
    CHECK(has_text(r["warnings"], "missing.png"));
    CHECK(p.manifest()["assets"].contains("assets/models/model.bin"));

    CommandResult noBuffer = p.call("assets.import", {{"source", art(p, "broken.gltf", R"({"asset":{"version":"2.0"},"buffers":[{"uri":"gone.bin","byteLength":4}]})")}});
    REQUIRE_FALSE(noBuffer.ok);
    CHECK(noBuffer.error["message"].get<std::string>().find("gone.bin") != std::string::npos);
    CommandResult remote = p.call("assets.import", {{"source", art(p, "remote.gltf", R"({"asset":{"version":"2.0"},"images":[{"uri":"https://x.test/a.png"}]})")}});
    CHECK_FALSE(remote.ok);
}

TEST_CASE("assets.import: a PSD becomes a PNG of its merged image") {
    AssetsProject p;
    auto be16 = [](Bytes& b, unsigned v) { b.u8(v >> 8).u8(v & 255); };
    auto be32 = [&](Bytes& b, unsigned v) { be16(b, v >> 16); be16(b, v & 0xffff); };
    Bytes psd;
    psd.v.insert(psd.v.end(), {'8', 'B', 'P', 'S'});
    be16(psd, 1);
    psd.zeros(6);
    be16(psd, 3);  // channels
    be32(psd, 2);  // height
    be32(psd, 2);  // width
    be16(psd, 8);  // bits per channel
    be16(psd, 3);  // RGB
    be32(psd, 0);  // color mode data
    be32(psd, 0);  // image resources
    be32(psd, 0);  // layers and masks
    be16(psd, 0);  // raw image data, one plane per channel
    psd.v.insert(psd.v.end(), {255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255});
    const Json r = p.ok("assets.import", {{"source", art(p, "layers.psd", std::string(psd.v.begin(), psd.v.end()))}});
    CHECK(r["importer"] == "psd");
    CHECK(r["path"] == "assets/layers.png");
    CHECK(has_text(r["warnings"], "flattened"));
    const Image img = read_png(p.file("assets/layers.png"));
    CHECK(get(img, 0, 0) == Rgba{255, 0, 0, 255});
    CHECK(get(img, 1, 0) == Rgba{0, 255, 0, 255});
    CHECK(get(img, 0, 1) == Rgba{0, 0, 255, 255});
    CHECK(get(img, 1, 1) == Rgba{255, 255, 255, 255});

    CommandResult bad = p.call("assets.import", {{"source", art(p, "fake.psd", "not photoshop")}});
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error["message"].get<std::string>().find("Photoshop") != std::string::npos);
}

namespace {

// A binary glTF whose JSON chunk is `json` (no BIN chunk).
std::string glb_with(std::string json) {
    while (json.size() % 4) json += ' ';
    std::string b;
    auto u32 = [&](std::uint32_t v) { for (int i = 0; i < 4; ++i) b.push_back(char(v >> (8 * i))); };
    b += "glTF"; u32(2); u32(std::uint32_t(20 + json.size())); u32(std::uint32_t(json.size())); b += "JSON"; b += json;
    return b;
}

}  // namespace

TEST_CASE("assets.import: a .glb brings its external texture, validate passes, and a collision warns") {
    AssetsProject p;
    write_png(p.tmp.path / "kitA/Textures/colormap.png", make_image(2, 2, {1, 2, 3, 255}));
    write_png(p.tmp.path / "kitB/Textures/colormap.png", make_image(2, 2, {200, 2, 3, 255}));
    const std::string json = R"({"asset":{"version":"2.0"},"images":[{"uri":"Textures/colormap.png"}]})";
    write_all(p.tmp.path / "kitA/tree.glb", glb_with(json));
    write_all(p.tmp.path / "kitB/rock.glb", glb_with(json));

    const Json a = p.ok("assets.import", {{"source", (p.tmp.path / "kitA/tree.glb").string()}});
    CHECK(a["details"]["images"] == 1);
    CHECK(p.exists("assets/models/Textures/colormap.png"));
    CHECK(p.manifest()["assets"].contains("assets/models/Textures/colormap.png"));
    CHECK_FALSE(a.contains("warnings"));
    {
        ValidationReport r = validate_project(p.dir);
        for (const ValidationIssue& e : r.errors) CHECK_MESSAGE(e.file != "assets/models/tree.glb", e.message);
    }

    // the same texture again is shared silently; a different one is kept and warned about
    const Json same = p.ok("assets.import", {{"source", (p.tmp.path / "kitA/tree.glb").string()}, {"path", "assets/models/tree2.glb"}});
    CHECK_FALSE(same.contains("warnings"));
    const Json clash = p.ok("assets.import", {{"source", (p.tmp.path / "kitB/rock.glb").string()}});
    CHECK(has_warning(clash, "Textures/colormap.png"));
    CHECK(has_warning(clash, "DIFFERENT"));
    CHECK(read_png(p.file("assets/models/Textures/colormap.png")).rgba[0] == 1);  // the first kit's texture is still there
    // its own folder avoids it
    const Json own = p.ok("assets.import", {{"source", (p.tmp.path / "kitB/rock.glb").string()}, {"path", "assets/models/kitB/"}});
    CHECK_FALSE(own.contains("warnings"));
    CHECK(read_png(p.file("assets/models/kitB/Textures/colormap.png")).rgba[0] == 200);

    // validate reports a model whose texture is gone
    stdfs::remove(p.file("assets/models/kitB/Textures/colormap.png"));
    ValidationReport r = validate_project(p.dir);
    bool found = false;
    for (const ValidationIssue& e : r.errors)
        if (e.file == "assets/models/kitB/rock.glb" && e.message.find("colormap.png") != std::string::npos) found = true;
    CHECK(found);
}

TEST_CASE("assets.import: a different buffer with the same name is a clash, an identical one is shared") {
    AssetsProject p;
    const std::string gltf = R"({"asset":{"version":"2.0"},"buffers":[{"uri":"scene.bin","byteLength":4}]})";
    write_all(p.tmp.path / "a/car.gltf", gltf);
    write_all(p.tmp.path / "a/scene.bin", "AAAA");
    write_all(p.tmp.path / "b/boat.gltf", gltf);
    write_all(p.tmp.path / "b/scene.bin", "BBBB");
    p.ok("assets.import", {{"source", (p.tmp.path / "a/car.gltf").string()}});
    const Json same = p.ok("assets.import", {{"source", (p.tmp.path / "a/car.gltf").string()}, {"path", "assets/models/car2.gltf"}});
    CHECK_FALSE(same.contains("warnings"));
    CommandResult clash = p.call("assets.import", {{"source", (p.tmp.path / "b/boat.gltf").string()}});
    REQUIRE_FALSE(clash.ok);
    CHECK(clash.error["message"].get<std::string>().find("scene.bin") != std::string::npos);
    CHECK_FALSE(p.exists("assets/models/boat.gltf"));
    CHECK(read_all(p.file("assets/models/scene.bin")) == "AAAA");
    p.ok("assets.import", {{"source", (p.tmp.path / "b/boat.gltf").string()}, {"path", "assets/models/b/"}});
    CHECK(read_all(p.file("assets/models/b/scene.bin")) == "BBBB");
}

TEST_CASE("assets.synth_sound: the same seed gives the same bytes, another seed another take, provenance recorded") {
    AssetsProject p;
    const Json a = p.ok("assets.synth_sound", {{"path", "assets/audio/bark.wav"}, {"preset", "bark"}, {"seed", 3}});
    CHECK(a["path"] == "assets/audio/bark.wav");
    const std::string first = read_all(p.file("assets/audio/bark.wav"));
    REQUIRE(first.size() > 44);
    CHECK(first.substr(0, 4) == "RIFF");
    p.ok("assets.synth_sound", {{"path", "assets/audio/bark2.wav"}, {"preset", "bark"}, {"seed", 3}});
    CHECK(read_all(p.file("assets/audio/bark2.wav")) == first);
    p.ok("assets.synth_sound", {{"path", "assets/audio/bark3.wav"}, {"preset", "bark"}, {"seed", 4}});
    CHECK(read_all(p.file("assets/audio/bark3.wav")) != first);
    const Json prov = p.manifest()["assets"]["assets/audio/bark.wav"]["provenance"];
    CHECK(prov["origin"] == "original");
    CHECK(prov["ai"] == false);
    CHECK(prov["seed"] == 3);

    // every preset makes a sound that is not silent
    for (const char* preset : {"growl", "meow", "screech", "whoosh", "explosion", "hit", "coin", "pickup", "jump", "powerup", "laser", "blip", "click", "error", "splash", "footstep"}) {
        p.ok("assets.synth_sound", {{"path", std::string("assets/audio/p_") + preset + ".wav"}, {"preset", preset}});
        const std::string wav = read_all(p.file(std::string("assets/audio/p_") + preset + ".wav"));
        bool loud = false;
        for (std::size_t i = 44; i + 1 < wav.size(); i += 2) loud = loud || wav[i + 1] != 0 || wav[i] != 0;
        CHECK_MESSAGE(loud, preset);
    }

    CommandResult bad = p.call("assets.synth_sound", {{"path", "assets/audio/x.wav"}, {"preset", "barkk"}});
    REQUIRE_FALSE(bad.ok);
    CHECK(bad.error["hint"].get<std::string>().find("bark") != std::string::npos);
    CHECK_FALSE(p.call("assets.synth_sound", {{"path", "assets/audio/bark.wav"}, {"preset", "bark"}}).ok);  // exists
    CHECK_FALSE(p.call("assets.synth_sound", {{"path", "sounds/x.wav"}, {"preset", "bark"}}).ok);
    CHECK_FALSE(p.call("assets.synth_sound", {{"path", "assets/x.ogg"}, {"preset", "bark"}}).ok);
}
