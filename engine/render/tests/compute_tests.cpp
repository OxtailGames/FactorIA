// Compute materials (fa/render/compute.h): storage buffers, a dispatch and the read back on the GPU of this machine (Metal, D3D11,
// GL 4.3+), and the refusal on a backend without compute. The fixture is tests/data/materials/materials/scale.material.json, whose
// twins were made by `factoria call shader.compile` (hlsl5, glsl430, metal_macos).
#include "fa/core/engine_version.h"
#include "fa/render/compute.h"
#include "test_util.h"

#include <clocale>
#include <cmath>
#include <cstdlib>
#include <fstream>
#include <limits>
#include <iterator>
#include <memory>
#include <mutex>
#include <string>
#include <vector>

#include "compute_internal.h"
#include "render_features.h"

using namespace fa;
using namespace fa::test;

namespace {

const char* const kScale = "materials/scale.material.json";
// Two storage images: `field` (rgba8, written: red 16 * x, green 16 * y, blue = the param) and `count` (r32f, read-write: + 1 a dispatch).
const char* const kField = "materials/field.material.json";

// Copies the fixture materials into the test project; every twin gets this build's engine version (its "template" stays, so a
// template change without regenerating the twins fails loudly).
void install_materials() {
    namespace sfs = std::filesystem;
    const sfs::path src = fs::path_from_utf8(FA_RENDER_DATA_DIR) / "materials";
    for (const auto& e : sfs::recursive_directory_iterator(src)) {
        if (!e.is_regular_file()) continue;
        std::ifstream in(e.path(), std::ios::binary);
        std::string bytes((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
        if (e.path().extension() == ".shader") {
            Json twin = Json::parse(bytes);
            twin["engine"] = FA_ENGINE_VERSION;
            bytes = twin.dump();
        }
        REQUIRE(fs::write_bytes(sfs::relative(e.path(), src).generic_string(), bytes.data(), bytes.size()).ok());
    }
}

// A test starts with an empty asset cache and no buffers, the fixtures installed, and leaves the real backend answering.
struct ComputeScope {
    Gfx& g = gfx();
    ComputeScope() {
        REQUIRE(g.ok);
        g.renderer.clear_asset_cache();
        install_materials();
    }
    ~ComputeScope() {
        for (const Json& b : g.renderer.compute().list()) (void)g.renderer.compute().destroy_buffer(b["id"].get<int>());
        for (const Json& i : g.renderer.compute().list_images())
            (void)g.renderer.compute().destroy_image(i["id"].get<int>());
        ComputeTestAccess::set_backend(g.renderer.compute(), -1);
        g.renderer.clear_asset_cache();
    }
    Compute& compute() { return g.renderer.compute(); }
};

// Errors logged while alive (the sink may run on a job thread: a locked, shared buffer).
struct ErrorLog {
    struct Lines {
        std::mutex mu;
        std::vector<std::string> lines;
    };
    std::shared_ptr<Lines> shared = std::make_shared<Lines>();
    int id;
    explicit ErrorLog(LogLevel lowest = LogLevel::Error)
        : id(add_log_sink([l = shared, lowest](const LogEntry& e) {
              if (e.level < lowest) return;
              std::lock_guard<std::mutex> lk(l->mu);
              l->lines.push_back(e.message);
          })) {}
    ~ErrorLog() { remove_log_sink(id); }
    ErrorLog(const ErrorLog&) = delete;
    ErrorLog& operator=(const ErrorLog&) = delete;
    int count(const std::string& needle) const {
        std::lock_guard<std::mutex> lk(shared->mu);
        int n = 0;
        for (const std::string& l : shared->lines)
            if (l.find(needle) != std::string::npos) ++n;
        return n;
    }
};

bool contains(const std::string& text, const std::string& part) { return text.find(part) != std::string::npos; }

Json element(double value, double x, double y, int steps = 0) {
    return Json::object({{"value", value}, {"pos", Json::array({x, y})}, {"steps", steps}});
}

// No compute on this machine's backend (WARP, llvmpipe, GL 4.1): one line says why the test does not run, and
// FA_REQUIRE_COMPUTE=1 (set it on a runner that must have compute) turns that into a failure so it can never become a silent pass.
void skip_without_compute(const char* what, const std::string& why) {
    const char* v = std::getenv("FA_REQUIRE_COMPUTE");
    if (v && *v && std::string(v) != "0")
        FAIL("FA_REQUIRE_COMPUTE=1 but this backend has no compute (" << why << "): " << what);
    MESSAGE("SKIPPED, no compute here (" << why << "): " << what << " (FA_REQUIRE_COMPUTE=1 fails instead)");
}

}  // namespace

TEST_CASE("compute: dispatch, read back, write and dispatch again on this GPU") {
    ComputeScope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("the dispatch is not run", why);
        return;
    }
    Json initial = Json::array();
    for (int i = 0; i < 64; ++i) initial.push_back(element(double(i), 0.5 * i, -1.0, 3));
    auto id = s.compute().create_buffer(kScale, "items", 128, initial);
    REQUIRE_MESSAGE(id.ok(), id.error().to_string());
    CHECK(s.compute().list().size() == 1);
    CHECK(s.compute().list()[0]["bytes"] == 128 * 24);

    // 2 workgroups of 64 threads cover the 128 elements: value * 2, pos + (1, 2), id = the thread's index, steps + 1.
    ComputeDispatch d;
    d.material = kScale;
    d.buffers["items"] = *id;
    d.params = Json::object({{"factor", 2.0}, {"offset", Json::array({1.0, 2.0})}});
    d.groups[0] = 2;
    auto ran = s.compute().dispatch(d);
    REQUIRE_MESSAGE(ran.ok(), ran.error().to_string());
    auto data = s.compute().read_buffer(*id, 0, 128);
    REQUIRE_MESSAGE(data.ok(), data.error().to_string());
    REQUIRE(data->size() == 128);
    CHECK((*data)[5]["value"] == 10.0);
    CHECK((*data)[5]["pos"] == Json::array({3.5, 1.0}));
    CHECK((*data)[5]["id"] == 5);
    CHECK((*data)[5]["steps"] == 4);
    CHECK((*data)[100]["value"] == 0.0);  // past `initial`: zero
    CHECK((*data)[100]["pos"] == Json::array({1.0, 2.0}));
    CHECK((*data)[100]["id"] == 100);
    CHECK((*data)[100]["steps"] == 1);

    // A second dispatch works on what the first left; a range read back is only that range.
    REQUIRE(s.compute().dispatch(d).ok());
    auto part = s.compute().read_buffer(*id, 4, 2);
    REQUIRE_MESSAGE(part.ok(), part.error().to_string());
    REQUIRE(part->size() == 2);
    CHECK((*part)[0]["value"] == 16.0);
    CHECK((*part)[0]["steps"] == 5);
    CHECK((*part)[1]["id"] == 5);

    // The game writes elements between dispatches; the elements around them stay as the GPU left them.
    REQUIRE(s.compute().write_buffer(*id, 6, Json::array({element(7.0, 0.0, 0.0, 10)})).ok());
    d.params = Json::object({{"factor", 1.0}});
    REQUIRE(s.compute().dispatch(d).ok());
    auto after = s.compute().read_buffer(*id, 5, 3);
    REQUIRE_MESSAGE(after.ok(), after.error().to_string());
    CHECK((*after)[0]["value"] == 20.0);  // 5 * 2 * 2 * 1: the elements around the write are as the GPU left them
    CHECK((*after)[1]["value"] == 7.0);   // written, then * 1
    CHECK((*after)[1]["steps"] == 11);
    CHECK((*after)[1]["pos"] == Json::array({0.0, 0.0}));  // offset keeps its default (0, 0)
    CHECK((*after)[2]["steps"] == 6);

    CHECK(s.compute().destroy_buffer(*id).ok());
    CHECK(s.compute().list().empty());
    CHECK_FALSE(s.compute().destroy_buffer(*id).ok());
}

TEST_CASE("compute: every wrong request is refused with its place and a way out") {
    ComputeScope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("the checks after the backend test are not run", why);
        return;
    }
    auto err = [](const auto& result) { return result.ok() ? std::string("<ok>") : result.error().to_string(); };

    CHECK(contains(err(s.compute().create_buffer(kScale, "item", 4)), "Did you mean 'items'"));
    CHECK(contains(err(s.compute().create_buffer(kScale, "items", 0)), "count: a buffer holds at least 1"));
    CHECK(contains(err(s.compute().create_buffer(kScale, "items", std::uint64_t(1) << 40)), "at most"));
    CHECK(contains(err(s.compute().create_buffer("materials/glow.material.json", "items", 4)), "not \"compute\""));
    CHECK(contains(err(s.compute().create_buffer("materials/none.material.json", "items", 4)), "none.material.json"));
    CHECK(contains(err(s.compute().create_buffer(kScale, "items", 4, Json::array({Json::object({{"valu", 1}})}))),
                   "/initial/0/valu"));
    CHECK(contains(err(s.compute().create_buffer(kScale, "items", 4, Json::array({Json::object({{"pos", 1}})}))),
                   "/initial/0/pos: number 1 is not an array of 2 numbers"));
    CHECK(contains(err(s.compute().create_buffer(kScale, "items", 4, Json::array({Json::object({{"steps", 1.5}})}))),
                   "an integer from -2147483648"));
    CHECK(
        contains(err(s.compute().create_buffer(kScale, "items", 1, Json::array({element(0, 0, 0), element(0, 0, 0)}))),
                 "do not fit"));
    CHECK(s.compute().list().empty());  // none of the refused requests left a buffer behind

    // A float with no fraction is a whole number (a script's 3 may arrive as 3.0); 1.5 stays refused (above).
    auto whole =
        s.compute().create_buffer(kScale, "items", 2, Json::array({Json::object({{"steps", 3.0}, {"id", 7.0}})}));
    REQUIRE(whole.ok());
    auto back = s.compute().read_buffer(*whole, 0, 1);
    REQUIRE(back.ok());
    CHECK((*back)[0]["steps"] == 3);
    CHECK((*back)[0]["id"] == 7);
    CHECK(s.compute().destroy_buffer(*whole).ok());

    auto id = s.compute().create_buffer(kScale, "items", 64);
    REQUIRE(id.ok());
    ComputeDispatch d;
    d.material = kScale;
    d.buffers["items"] = *id;
    d.groups[0] = 0;
    CHECK(contains(err(s.compute().dispatch(d)), "groups/0"));
    d.groups[0] = 70000;
    CHECK(contains(err(s.compute().dispatch(d)), "1 to 65535"));
    d.groups[0] = 1;
    d.buffers["itms"] = 1;
    CHECK(contains(err(s.compute().dispatch(d)), "buffers/itms"));
    d.buffers.erase("itms");
    d.buffers["items"] = 99;
    CHECK(contains(err(s.compute().dispatch(d)), "no compute buffer 99"));
    d.buffers.clear();
    CHECK(contains(err(s.compute().dispatch(d)), "the buffer 'items'"));
    d.buffers["items"] = *id;
    d.params = Json::object({{"factr", 2.0}});
    CHECK(contains(err(s.compute().dispatch(d)), "Did you mean 'factor'"));
    d.params = Json::object({{"offset", 2.0}});
    CHECK(contains(err(s.compute().dispatch(d)), "params/offset"));
    d.params = Json::object({{"factor", "big"}});
    CHECK(contains(err(s.compute().dispatch(d)), "params/factor"));
    d.params = Json();
    d.material = "materials/glow.material.json";
    CHECK(contains(err(s.compute().dispatch(d)), "not \"compute\""));

    CHECK(contains(err(s.compute().read_buffer(*id, 60, 5)), "outside the buffer of 64"));
    CHECK(contains(err(s.compute().read_buffer(*id, 0, std::uint64_t(1) << 30)), "at most"));
    CHECK(contains(err(s.compute().read_buffer(77, 0, 1)), "no compute buffer 77"));
    CHECK(
        contains(err(s.compute().write_buffer(*id, 63, Json::array({element(0, 0, 0), element(0, 0, 0)}))), "outside"));
    CHECK(contains(err(s.compute().write_buffer(*id, 0, Json::object())), "not an array"));
    CHECK(s.compute().read_buffer(*id, 64, 0)->empty());

    // Another buffer shape of the same material cannot be mixed up: a buffer is bound where it was made for.
    CHECK(s.compute().list().size() == 1);
}

TEST_CASE("compute: a backend without compute shaders is refused with its name and what to do, never a no-op") {
    ComputeScope s;
    using FB = render::FeatureBackend;
    for (FB backend : {FB::Gles3, FB::WebGl2, FB::Headless}) {
        ComputeTestAccess::set_backend(s.compute(), int(backend));
        std::string why;
        CHECK_FALSE(s.compute().available(&why));
        CHECK(contains(why, render::feature_backend_label(backend)));
        CHECK(contains(why, "render.supports"));
        CHECK(contains(why, "Android (GLES3), the web (WebGL2) or macOS OpenGL"));
        CHECK(contains(why, "CPU path"));
        auto made = s.compute().create_buffer(kScale, "items", 4);
        REQUIRE_FALSE(made.ok());
        CHECK(made.error().message == why);
        CHECK(contains(made.error().hint, "render.supports computeShaders"));
        ComputeDispatch d;
        d.material = kScale;
        CHECK_FALSE(s.compute().dispatch(d).ok());
        CHECK_FALSE(s.compute().read_buffer(1, 0, 1).ok());
        CHECK_FALSE(s.compute().write_buffer(1, 0, Json::array()).ok());
        CHECK(s.compute().list().empty());
        auto image =
            s.compute().create_image(kField, "field");  // images are refused the same way, with the CPU path named
        REQUIRE_FALSE(image.ok());
        CHECK(image.error().message == why);
        CHECK_FALSE(s.compute().resize_image(1, 8, 8).ok());
        CHECK_FALSE(s.compute().read_image(1, 0, 0, 0, 0).ok());
        CHECK(s.compute().list_images().empty());
    }
    ComputeTestAccess::set_backend(s.compute(), int(FB::Metal));
    CHECK(s.compute()
              .available());  // a backend with compute passes the capability check (the GPU may still say no below)
}

TEST_CASE("compute: a MeshRenderer that names a compute material is drawn with the engine's shader and warned once") {
    ComputeScope s;
    ErrorLog log(LogLevel::Warn);
    World w;
    Entity cam = make(w, "cam", {0, 0, 4});
    auto& c = w.add<Camera>(cam);
    c.projection = Projection::Perspective;
    c.fov = 60;
    Entity cube = make(w, "cube");
    auto& m = w.add<MeshRenderer>(cube);
    m.mesh = "cube";
    m.material = kScale;
    Image img;
    for (int i = 0; i < 3; ++i) img = s.g.render(w);
    const Color px = img.pixel(160, 90);
    CHECK_FALSE(
        (px.r > 0.9f && px.g < 0.1f && px.b > 0.9f));  // not the magenta of a failed material: the cube is drawn
    CHECK(log.count("compute") >= 1);
    CHECK(log.count("scale.material.json") == 1);  // once, not once per frame
}

TEST_CASE("compute: a float leaves with 7 digits whatever the C locale, and a call is capped by its numbers") {
    // A comma-decimal locale made printf/strtod lose the fraction; to_chars/from_chars do not look at it.
    const char* current = std::setlocale(LC_NUMERIC, nullptr);
    const std::string old = current ? current : "C";
    bool switched = false;
    for (const char* name : {"de_DE.UTF-8", "de_DE.utf8", "fr_FR.UTF-8", "German_Germany.1252"})
        if (std::setlocale(LC_NUMERIC, name)) {
            switched = true;
            break;
        }
    if (!switched) MESSAGE("locale not installed: the floats are checked in the C locale only");
    CHECK(compute_json_float(0.1f).get<double>() == 0.1);
    CHECK(compute_json_float(-2.5f).get<double>() == -2.5);
    CHECK(compute_json_float(1234.5678f).get<double>() == 1234.568);  // 7 significant digits
    CHECK(compute_json_float(16777217.0f).get<double>() ==
          16777220.0);  // rounded to 7 digits (not a float32 round trip)
    CHECK(compute_json_float(std::numeric_limits<float>::infinity()).is_null());
    CHECK(compute_json_float(std::nanf("")).is_null());
    std::setlocale(LC_NUMERIC, old.c_str());

    ComputeScope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("the value cap is not run", why);
        return;
    }
    auto id = s.compute().create_buffer(kScale, "items", std::uint64_t(1) << 20);
    REQUIRE_MESSAGE(id.ok(), id.error().to_string());
    // An element of the fixture has more than 4 numbers (value, pos x2, steps, id), so 1M elements are within the element cap
    // but over the 4M-number cap.
    auto r = s.compute().read_buffer(*id, 0, std::uint64_t(1) << 20);
    REQUIRE_FALSE(r.ok());
    CHECK(contains(r.error().to_string(), "numbers one call converts"));
    CHECK(contains(r.error().to_string(), "in chunks of at most"));
    CHECK(contains(r.error().to_string(), "`first`"));
    CHECK(s.compute().read_buffer(*id, 0, 1000).ok());
    // Without `count` the command stops at the largest count that fits: the default never errs on a count nobody passed.
    CHECK(s.compute().max_json_elements(*id) < (std::uint64_t(1) << 20));
    CHECK(s.compute().max_json_elements(*id) >= 1000);
}

// ---------------------------------------------------------------------------------------------------------------------------------
// Storage images (M72.17): a compute material writes (and reads) 2D images that any material then shows.
// ---------------------------------------------------------------------------------------------------------------------------------
namespace {

// The pixel (x, y) of a read_image answer whose rows are `width` pixels of `channels` numbers.
Json pixel_of(const Json& data, int x, int y, int channels, int width = 16) {
    Json out = Json::array();
    for (int c = 0; c < channels; ++c) out.push_back(data[std::size_t((y * width + x) * channels + c)]);
    return out;
}

// A 2D camera and a sprite of `size` x `size` at the origin that shows `texture`; texel (i, j) of an `n` x `n` image is then at the
// screen pixel (160 - size / 2 + (i + 0.5) * size / n, 90 - size / 2 + (j + 0.5) * size / n) of the 320 x 180 target.
void shown(World& w, const std::string& texture, float size = 160.0f) {
    Entity cam = make(w, "cam");
    w.add<Camera>(cam).clearColor = Color::black();
    Entity e = make(w, "shown");
    auto& sp = w.add<Sprite>(e);
    sp.texture = texture;
    sp.size = {size, size};
    sp.color = Color{1, 1, 1, 1};
}

bool near_color(const Color& got, float r, float g, float b, float tol = 0.03f) {
    return std::fabs(got.r - r) <= tol && std::fabs(got.g - g) <= tol && std::fabs(got.b - b) <= tol;
}

// The centre of the texel (3, 5) of a 16 x 16 image shown by `shown(.., 160)`.
Color texel_3_5(const Image& img) { return img.pixel(160 - 80 + 3 * 10 + 5, 90 - 80 + 5 * 10 + 5); }

}  // namespace

TEST_CASE(
    "compute images: a dispatch writes a known pattern, it is read back and a sprite and a sprite material show it") {
    ComputeScope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("the storage image dispatch is not run", why);
        return;
    }
    auto field = s.compute().create_image(kField, "field");
    auto count = s.compute().create_image(kField, "count");
    REQUIRE_MESSAGE(field.ok(), field.error().to_string());
    REQUIRE_MESSAGE(count.ok(), count.error().to_string());
    const Json listed = s.compute().list_images();
    REQUIRE(listed.size() == 2);
    CHECK(listed[0]["image"] == "field");
    CHECK(listed[0]["format"] == "rgba8");
    CHECK(listed[0]["access"] == "write");
    CHECK(listed[0]["width"] == 16);
    CHECK(listed[0]["bytes"] == 16 * 16 * 4);
    CHECK(listed[0]["textureId"] == Compute::image_texture_id(*field));
    CHECK(listed[1]["format"] == "r32f");
    CHECK(listed[1]["access"] == "readWrite");

    // A new image is zero, not whatever the GPU memory held.
    auto zero = s.compute().read_image(*field, 0, 0, 0, 0);
    REQUIRE_MESSAGE(zero.ok(), zero.error().to_string());
    REQUIRE((*zero)["data"].size() == 16 * 16 * 4);
    bool allZero = true;
    for (const Json& v : (*zero)["data"]) allZero = allZero && v == 0;
    CHECK(allZero);

    ComputeDispatch d;
    d.material = kField;
    d.images["field"] = *field;
    d.images["count"] = *count;
    d.params = Json::object({{"blue", 1.0}});
    d.groups[0] = 2;  // 8 x 8 threads a workgroup: 2 x 2 workgroups cover the 16 x 16 pixels
    d.groups[1] = 2;
    auto ran = s.compute().dispatch(d);
    REQUIRE_MESSAGE(ran.ok(), ran.error().to_string());
    auto data = s.compute().read_image(*field, 0, 0, 0, 0);
    REQUIRE_MESSAGE(data.ok(), data.error().to_string());
    CHECK((*data)["format"] == "rgba8");
    CHECK((*data)["channels"] == 4);
    CHECK((*data)["width"] == 16);
    CHECK((*data)["height"] == 16);
    const Json& all = (*data)["data"];
    REQUIRE(all.size() == 16 * 16 * 4);
    CHECK(pixel_of(all, 0, 0, 4) == Json::array({0, 0, 255, 255}));
    CHECK(pixel_of(all, 3, 5, 4) == Json::array({48, 80, 255, 255}));
    CHECK(pixel_of(all, 15, 15, 4) == Json::array({240, 240, 255, 255}));

    // A rectangle is only that rectangle (row by row from the top).
    auto part = s.compute().read_image(*field, 2, 1, 2, 3);
    REQUIRE_MESSAGE(part.ok(), part.error().to_string());
    CHECK((*part)["x"] == 2);
    CHECK((*part)["width"] == 2);
    CHECK((*part)["height"] == 3);
    REQUIRE((*part)["data"].size() == 2 * 3 * 4);
    CHECK(pixel_of((*part)["data"], 1, 2, 4, 2) == Json::array({48, 48, 255, 255}));

    // The read-write image counts the dispatches: imageLoad sees what the earlier one stored.
    REQUIRE(s.compute().dispatch(d).ok());
    auto counted = s.compute().read_image(*count, 0, 0, 4, 4);
    REQUIRE_MESSAGE(counted.ok(), counted.error().to_string());
    CHECK((*counted)["format"] == "r32f");
    CHECK((*counted)["channels"] == 1);
    REQUIRE((*counted)["data"].size() == 16);
    bool twice = true;
    for (const Json& v : (*counted)["data"]) twice = twice && v == 2.0;
    CHECK(twice);

    // A sprite shows the image: the texel (3, 5) of the 16 x 16 pattern.
    {
        World w;
        shown(w, Compute::image_texture_id(*field));
        const Color c = texel_3_5(s.g.render(w));
        CHECK_MESSAGE(near_color(c, 48 / 255.0f, 80 / 255.0f, 1.0f), c.r << " " << c.g << " " << c.b);
    }
    // The order inside a frame: a dispatch made now (blue 0) is what the next draw shows, with no frame in between.
    d.params = Json::object({{"blue", 0.0}});
    REQUIRE(s.compute().dispatch(d).ok());
    {
        World w;
        shown(w, Compute::image_texture_id(*field));
        const Color c = texel_3_5(s.g.render(w));
        CHECK_MESSAGE(near_color(c, 48 / 255.0f, 80 / 255.0f, 0.0f), c.r << " " << c.g << " " << c.b);
    }
    // A sprite material takes the image as its texture param (it shows the texel at (0.05, 0.05): (0, 0, blue)).
    d.params = Json::object({{"blue", 1.0}});
    REQUIRE(s.compute().dispatch(d).ok());
    {
        World w;
        Entity cam = make(w, "cam");
        w.add<Camera>(cam).clearColor = Color::black();
        Entity e = make(w, "shown");
        auto& sp = w.add<Sprite>(e);
        sp.material = "materials/sprite_mask.material.json";
        sp.materialParams = Json::object({{"mask", Compute::image_texture_id(*field)}});
        sp.size = {64, 64};
        sp.color = Color{1, 1, 1, 1};
        const Color c = s.g.render(w).pixel(160, 90);
        CHECK_MESSAGE(near_color(c, 0, 0, 1.0f), c.r << " " << c.g << " " << c.b);
    }
}

TEST_CASE(
    "compute images: resize keeps the texture id, destroy leaves the checker and a log line, ids are not reused") {
    ComputeScope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("the image lifecycle is not run", why);
        return;
    }
    auto field = s.compute().create_image(kField, "field", 32, 8);  // a size of its own
    REQUIRE_MESSAGE(field.ok(), field.error().to_string());
    CHECK(s.compute().list_images()[0]["width"] == 32);
    CHECK(s.compute().list_images()[0]["height"] == 8);
    auto count = s.compute().create_image(kField, "count", 16, 16);
    REQUIRE(count.ok());
    const std::string textureId = Compute::image_texture_id(*field);

    REQUIRE_MESSAGE(s.compute().resize_image(*field, 16, 16).ok(), "resize");
    CHECK(s.compute().list_images()[0]["width"] == 16);
    CHECK(s.compute().list_images()[0]["textureId"] == textureId);
    CHECK(s.compute().max_json_pixels(*field) == kMaxComputeJsonValues / 4);
    ComputeDispatch d;
    d.material = kField;
    d.images["field"] = *field;
    d.images["count"] = *count;
    d.params = Json::object({{"blue", 1.0}});
    d.groups[0] = 2;
    d.groups[1] = 2;
    REQUIRE(s.compute().dispatch(d).ok());
    {
        World w;
        shown(w, textureId);
        const Color c = texel_3_5(s.g.render(w));
        CHECK_MESSAGE(near_color(c, 48 / 255.0f, 80 / 255.0f, 1.0f), c.r << " " << c.g << " " << c.b);
    }
    // A bigger image is zero again (its pixels are lost) and the same texture id shows it.
    REQUIRE(s.compute().resize_image(*field, 32, 32).ok());
    auto cleared = s.compute().read_image(*field, 0, 0, 0, 0);
    REQUIRE(cleared.ok());
    REQUIRE((*cleared)["data"].size() == 32 * 32 * 4);
    bool allZero = true;
    for (const Json& v : (*cleared)["data"]) allZero = allZero && v == 0;
    CHECK(allZero);
    {
        World w;
        shown(w, textureId);
        CHECK(near_color(s.g.render(w).pixel(160, 90), 0, 0, 0));  // transparent black over the black clear
    }

    // Destroyed: the sprite shows the checker (its first block is magenta) and the log says which id and why.
    ErrorLog log(LogLevel::Warn);
    REQUIRE(s.compute().destroy_image(*field).ok());
    CHECK_FALSE(s.compute().destroy_image(*field).ok());
    CHECK(s.compute().list_images().size() == 1);
    {
        World w;
        shown(w, textureId, 64.0f);
        const Color c = s.g.render(w).pixel(160 - 32 + 2, 90 - 32 + 2);
        CHECK_MESSAGE(near_color(c, 1, 0, 1, 0.1f), c.r << " " << c.g << " " << c.b);
    }
    CHECK(log.count(textureId) >= 1);
    CHECK(log.count("no live compute image") >= 1);
    auto again = s.compute().create_image(kField, "field");
    REQUIRE(again.ok());
    CHECK(*again > *count);  // an id is never reused: an old textureId cannot show somebody else's image
}

TEST_CASE("compute images: every wrong request is refused with its place and a way out") {
    ComputeScope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("the image checks are not run", why);
        return;
    }
    auto err = [](const auto& result) { return result.ok() ? std::string("<ok>") : result.error().to_string(); };

    CHECK(contains(err(s.compute().create_image(kField, "fied")), "Did you mean 'field'"));
    CHECK(contains(err(s.compute().create_image(kScale, "field")), "declares no images"));
    CHECK(contains(err(s.compute().create_image("materials/glow.material.json", "field")), "not \"compute\""));
    CHECK(contains(err(s.compute().create_image("materials/none.material.json", "field")), "none.material.json"));
    CHECK(contains(err(s.compute().create_image(kField, "field", -1, 4)), "is not a size"));
    CHECK(contains(err(s.compute().create_image(kField, "field", 100000, 4)), "pixels a side may have"));
    CHECK(contains(err(s.compute().create_image(kField, "field", 4, 100000)), "pixels a side may have"));
    CHECK(s.compute().list_images().empty());  // none of the refused requests left an image behind

    auto field = s.compute().create_image(kField, "field");
    auto count = s.compute().create_image(kField, "count");
    REQUIRE(field.ok());
    REQUIRE(count.ok());
    ComputeDispatch d;
    d.material = kField;
    d.groups[0] = 2;
    d.groups[1] = 2;
    CHECK(contains(err(s.compute().dispatch(d)), "the image 'count' of"));
    d.images["field"] = *field;
    d.images["count"] = *count;
    d.images["fied"] = 1;
    CHECK(contains(err(s.compute().dispatch(d)), "images/fied"));
    d.images.erase("fied");
    d.images["count"] = 999;
    CHECK(contains(err(s.compute().dispatch(d)), "no compute image 999"));
    d.images["count"] = *field;  // an rgba8 image where the material declares r32f
    CHECK(contains(err(s.compute().dispatch(d)), "was made for 'field'"));
    d.images["count"] = *count;
    d.images["field"] = *count;
    CHECK(contains(err(s.compute().dispatch(d)), "images/field"));
    d.images["field"] = *field;
    // The image the dispatch writes cannot also be its texture (one image as a storage image and a texture in one pass).
    d.params = Json::object({{"src", Compute::image_texture_id(*field)}});
    CHECK(contains(err(s.compute().dispatch(d)), "writes as a storage image"));
    d.params = Json();
    CHECK(s.compute().dispatch(d).ok());

    CHECK(contains(err(s.compute().read_image(77, 0, 0, 0, 0)), "no compute image 77"));
    CHECK(contains(err(s.compute().read_image(*field, 16, 0, 0, 0)), "is not inside the 16 x 16 image"));
    CHECK(contains(err(s.compute().read_image(*field, -1, 0, 0, 0)), "is not inside"));
    CHECK(contains(err(s.compute().read_image(*field, 10, 0, 7, 1)), "goes past the 16 x 16 image"));
    CHECK(contains(err(s.compute().resize_image(77, 4, 4)), "no compute image 77"));
    CHECK(contains(err(s.compute().resize_image(*field, 0, 4)), "is not a size"));
    CHECK(contains(err(s.compute().resize_image(*field, 4, 9000)), "pixels a side may have"));
    CHECK(s.compute().list_images()[0]["width"] == 16);  // the refused resize changed nothing
    CHECK_FALSE(s.compute().destroy_image(77).ok());

    // The live images are capped: the refusal says how many are alive and how to free one.
    int made = 0;
    std::string refusal;
    for (int i = 0; i < kMaxLiveComputeImages + 2; ++i) {
        auto r = s.compute().create_image(kField, "field", 2, 2);
        if (!r.ok()) {
            refusal = r.error().to_string();
            break;
        }
        ++made;
    }
    CHECK(made == kMaxLiveComputeImages - 2);
    CHECK(contains(refusal, std::to_string(kMaxLiveComputeImages) + " images are alive already"));
    CHECK(contains(refusal, "compute.destroy_image"));
}

TEST_CASE(
    "compute images: readWrite needs a GPU that can imageLoad the format, and the refusal says what to use instead") {
    ComputeScope s;
    std::string why;
    if (!s.compute().available(&why)) {
        skip_without_compute("the readWrite capability check is not run", why);
        return;
    }
    // This GPU's real answer for r32f (the one format every backend loads): the image of the material works.
    auto real = s.compute().create_image(kField, "count");
    CHECK_MESSAGE(real.ok(), real.error().to_string());
    if (real.ok()) CHECK(s.compute().destroy_image(*real).ok());

    // A GPU that loads r32f only (Metal Tier 1, D3D11.0): r32f still passes.
    ComputeTestAccess::set_load_override(s.compute(), 1);
    auto r32 = s.compute().create_image(kField, "count");
    CHECK_MESSAGE(r32.ok(), r32.error().to_string());
    if (r32.ok()) CHECK(s.compute().destroy_image(*r32).ok());
    auto write = s.compute().create_image(kField, "field");  // a write-only image never needs a load
    CHECK(write.ok());

    // A GPU that loads nothing: the readWrite image is refused with its JSON pointer, what the GPU does and the way out.
    ComputeTestAccess::set_load_override(s.compute(), 2);
    auto refused = s.compute().create_image(kField, "count");
    REQUIRE_FALSE(refused.ok());
    const std::string text = refused.error().to_string();
    CHECK(contains(text, "/images/count/access"));
    CHECK(contains(text, "does not work on this GPU"));
    CHECK(contains(text, "split it into two images"));
    CHECK(s.compute().list_images().size() == (write.ok() ? 1u : 0u));  // the refused request left nothing behind
    ComputeTestAccess::set_load_override(s.compute(), 0);
}
