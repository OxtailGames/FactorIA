// The compute.* commands: storage buffers and dispatches of "kind": "compute" materials (docs/SHADERS.md, "Compute
// materials"). Thin wrappers of fa::Compute (fa/render/compute.h), which owns the buffers and says why a backend cannot.
#include <algorithm>
#include <cmath>
#include <optional>

#include "engine_impl.h"
#include "fa/core/strings.h"
#include "fa/render/compute.h"
#include "fa/render/renderer.h"

namespace fa {

namespace {

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

void check_args_known(const Json& a, std::initializer_list<const char*> known, const char* command) {
    if (!a.is_object()) return;
    std::vector<std::string> names;
    for (const char* k : known) names.push_back(k);
    for (auto it = a.begin(); it != a.end(); ++it)
        if (std::find(names.begin(), names.end(), it.key()) == names.end())
            throw CommandError("invalid_argument",
                               std::string(command) + ": unknown argument '" + it.key() + "'. " +
                                   did_you_mean(it.key(), names),
                               names.empty() ? std::string("The command takes no arguments.")
                                             : "The arguments are: " + join(names, ", ") + ".");
}

// The renderer's Compute, or `unavailable` without graphics or on a backend without compute shaders (never a silent no-op).
Compute& need_compute(Engine::Impl& I, const char* command) {
    if (!I.renderer || !I.renderer->initialized())
        throw CommandError("unavailable", std::string(command) + ": no renderer, the engine runs with graphics=false.",
                           "Compute needs a GPU: run with graphics (not graphics=false).");
    Compute& c = I.renderer->compute();
    std::string why;
    if (!c.available(&why))
        throw CommandError("unavailable", std::string(command) + ": " + why,
                           "render.supports {\"feature\":\"computeShaders\"} tells whether a backend can; "
                           "docs/SHADERS.md, \"Compute materials\" lists the backends.");
    return c;
}

// A whole number argument in [lo, hi] (a JSON integer or a float with no fraction, as scripts send them), never narrowed before
// the range check.
std::uint64_t whole_arg(const Json& a, const char* key, std::uint64_t lo, std::uint64_t hi, const char* command,
                        std::optional<std::uint64_t> fallback = std::nullopt) {
    if (!a.is_object() || !a.contains(key)) {
        if (fallback) return *fallback;
        throw CommandError("invalid_argument", std::string(command) + ": " + key + " is required.",
                           std::string("Pass \"") + key + "\": a whole number from " + std::to_string(lo) + " to " +
                               std::to_string(hi) + ".");
    }
    const Json& v = a[key];
    double d = 0;
    if (v.is_number()) d = v.get<double>();
    const bool whole = v.is_number() && std::isfinite(d) && std::floor(d) == d && d >= 0 && d < 9007199254740992.0;
    if (!whole || std::uint64_t(d) < lo || std::uint64_t(d) > hi)
        throw CommandError("invalid_argument",
                           std::string(command) + ": " + key + ": " + describe_json_value(v) +
                               " is not a whole number from " + std::to_string(lo) + " to " + std::to_string(hi) + ".",
                           std::string("Pass \"") + key + "\" as a whole number in that range.");
    return std::uint64_t(d);
}

std::string string_arg(const Json& a, const char* key, const char* command) {
    if (!a.is_object() || !a.contains(key) || !a[key].is_string() || a[key].get<std::string>().empty())
        throw CommandError("invalid_argument",
                           std::string(command) + ": " + key + " is required, a non-empty string" +
                               (a.is_object() && a.contains(key) ? " (got " + describe_json_value(a[key]) + ")" : "") +
                               ".",
                           std::string("Pass \"") + key + "\" as text, e.g. \"materials/boids.material.json\".");
    return a[key].get<std::string>();
}

[[noreturn]] void rethrow(const Error& e) { throw CommandError("invalid_argument", e.message, e.hint); }

}  // namespace

void register_compute_commands(Engine& engine, Engine::Impl& I) {
    (void)engine;
    I.commands.add(
        {"compute.create_buffer",
         "Makes a GPU storage buffer shaped like one buffer of a compute material; returns its id.",
         "A zero-filled buffer of `count` elements, each laid out like the element of the material's buffer `buffer` "
         "(its \"buffers\" entry: fields of float, vec2, vec3, vec4, int, uint). `initial` fills the first elements. "
         "The "
         "buffer lives until compute.destroy_buffer or the end of the game, whatever the scene (it is not part of "
         "one). "
         "Returns {id, count, stride, bytes}. Example: compute.create_buffer "
         "{\"material\":\"materials/boids.material.json\","
         "\"buffer\":\"boids\",\"count\":1000,\"initial\":[{\"pos\":[0,0],\"vel\":[1,0]}]}" FA_COMMAND_DETAILS
         "Limits: 64 live buffers, 256 MiB each, 1 GiB in all; over one is `invalid_argument` with the number it hit. "
         "Errors: `unavailable` on a backend without compute shaders (GLES3, WebGL2, macOS OpenGL 4.1: the message "
         "names the backend and what to do; ask render.supports computeShaders first) or without graphics; "
         "`invalid_argument` for a material that is not a compute material or does not build, an unknown buffer name "
         "(did you mean), and an `initial` value that does not fit a field (the message has its JSON pointer).",
         parse_schema(R"({"type":"object","properties":{
               "material":{"type":"string","description":"Project-relative path of the compute material, e.g. materials/boids.material.json."},
               "buffer":{"type":"string","description":"Name of one of the material's buffers (its \"buffers\" entry)."},
               "count":{"type":"integer","minimum":1,"description":"Number of elements (at most 256 MiB / the element stride)."},
               "initial":{"type":"array","items":{"type":"object"},"description":"Optional {field: value} objects for the first elements (a vecN field is an array); fields left out are 0."}},
               "required":["material","buffer","count"]})"),
         true, "game"},
        [&I](const Json& a) {
            check_args_known(a, {"material", "buffer", "count", "initial"}, "compute.create_buffer");
            Compute& c = need_compute(I, "compute.create_buffer");
            const std::string material = string_arg(a, "material", "compute.create_buffer");
            const std::string buffer = string_arg(a, "buffer", "compute.create_buffer");
            const std::uint64_t count = whole_arg(a, "count", 1, kMaxComputeBufferBytes, "compute.create_buffer");
            auto id = c.create_buffer(material, buffer, count, a.contains("initial") ? a["initial"] : Json());
            if (!id.ok()) rethrow(id.error());
            for (const Json& b : c.list())
                if (b["id"] == *id) return b;
            return Json::object({{"id", *id}});
        });

    I.commands.add(
        {"compute.write_buffer", "Overwrites elements of a compute storage buffer with values from the game.",
         "Writes `elements` ({field: value} objects) from element `first` on; a field left out is written as 0, the "
         "other elements stay as the GPU left them. Returns {written}. Example: compute.write_buffer {\"buffer\":1,"
         "\"first\":0,\"elements\":[{\"pos\":[0,0],\"vel\":[1,0]}]}" FA_COMMAND_DETAILS
         "At most 1048576 elements in one call. Errors: `unavailable` without compute (see compute.create_buffer); "
         "`invalid_argument` for an unknown buffer id (compute.list_buffers), a range outside the buffer, or a value "
         "that "
         "does not fit its field (the message has its JSON pointer).",
         parse_schema(R"({"type":"object","properties":{
               "buffer":{"type":"integer","description":"Buffer id from compute.create_buffer."},
               "first":{"type":"integer","minimum":0,"description":"Index of the first element to overwrite. Default 0."},
               "elements":{"type":"array","items":{"type":"object"},"description":"{field: value} objects, one per element."}},
               "required":["buffer","elements"]})"),
         true, "game"},
        [&I](const Json& a) {
            check_args_known(a, {"buffer", "first", "elements"}, "compute.write_buffer");
            Compute& c = need_compute(I, "compute.write_buffer");
            const int id = int(whole_arg(a, "buffer", 0, 0x7fffffff, "compute.write_buffer"));
            const std::uint64_t first = whole_arg(a, "first", 0, kMaxComputeBufferBytes, "compute.write_buffer", 0);
            if (!a.contains("elements"))
                throw CommandError("invalid_argument", "compute.write_buffer: elements is required.",
                                   "Pass \"elements\": [{field: value}, ...].");
            auto done = c.write_buffer(id, first, a["elements"]);
            if (!done.ok()) rethrow(done.error());
            return Json::object({{"written", a["elements"].size()}});
        });

    I.commands.add(
        {"compute.read_buffer", "Reads elements of a compute storage buffer back to the game (waits for the GPU).",
         "Submits the recorded GPU work, waits for it and returns `count` elements from `first` as an array of {field: "
         "value} "
         "objects: a vecN field is an array, floats have 7 significant digits, a NaN or infinity is null. A read back "
         "stalls the frame: do it for a result you need, not every frame. Example: compute.read_buffer {\"buffer\":1,"
         "\"first\":0,\"count\":10}" FA_COMMAND_DETAILS "At most 1048576 elements in one call (read a large buffer in "
         "parts). Errors: `unavailable` without compute (see "
         "compute.create_buffer); `invalid_argument` for an unknown buffer id or a range outside the buffer.",
         parse_schema(R"({"type":"object","properties":{
               "buffer":{"type":"integer","description":"Buffer id from compute.create_buffer."},
               "first":{"type":"integer","minimum":0,"description":"Index of the first element to read. Default 0."},
               "count":{"type":"integer","minimum":0,"description":"Number of elements to read. Default: from `first` to the end (at most 1048576 elements and 4194304 numbers per call: read bigger buffers in chunks with first/count)."}},
               "required":["buffer"]})"),
         true, "game"},
        [&I](const Json& a) {
            check_args_known(a, {"buffer", "first", "count"}, "compute.read_buffer");
            Compute& c = need_compute(I, "compute.read_buffer");
            const int id = int(whole_arg(a, "buffer", 0, 0x7fffffff, "compute.read_buffer"));
            const std::uint64_t first = whole_arg(a, "first", 0, kMaxComputeBufferBytes, "compute.read_buffer", 0);
            std::uint64_t count = 0;
            if (a.contains("count")) {
                count = whole_arg(a, "count", 0, kMaxComputeBufferBytes, "compute.read_buffer");
            } else {
                std::uint64_t total = 0;
                bool found = false;
                for (const Json& b : c.list())
                    if (b["id"] == id) {
                        total = b["count"].get<std::uint64_t>();
                        found = true;
                    }
                if (found) count = total > first ? std::min(total - first, c.max_json_elements(id)) : 0;
            }
            auto data = c.read_buffer(id, first, count);
            if (!data.ok()) rethrow(data.error());
            return *data;
        });

    I.commands.add(
        {"compute.dispatch", "Runs a compute material once over its storage buffers.",
         "`groups` counts WORKGROUPS of the material's workgroupSize threads each, not threads: ceil(work / "
         "workgroupSize.x) for a one-dimensional job. `buffers` gives a buffer id for every buffer of the material and "
         "`images` an image id for every storage image of it; "
         "`params` "
         "its param values and texture paths (like MeshRenderer.materialParams; what is left out keeps the material's "
         "default). The call returns when the work is recorded; compute.read_buffer and compute.read_image wait for "
         "it, "
         "and a draw of the same frame sees the image the dispatch wrote. Returns {dispatched: "
         "[x, y, z]}. Example: compute.dispatch "
         "{\"material\":\"materials/boids.material.json\",\"buffers\":{\"boids\":1},"
         "\"params\":{\"speed\":2},\"groups\":[16,1,1]}" FA_COMMAND_DETAILS
         "Each dimension of `groups` is 1 to 65535. A buffer or image must have been made for the same buffer or image "
         "of the same "
         "material "
         "(same layout or format), and one buffer or image cannot be bound twice. An image cannot also be one of the "
         "dispatch's texture params. Errors: `unavailable` without compute (see "
         "compute.create_buffer); `invalid_argument` for a missing or unknown buffer, image or param (did you mean), a "
         "value "
         "of "
         "the wrong type, or groups out of range.",
         parse_schema(R"({"type":"object","properties":{
               "material":{"type":"string","description":"Project-relative path of the compute material."},
               "buffers":{"type":"object","additionalProperties":{"type":"integer"},"description":"The material's buffer name -> buffer id from compute.create_buffer; every buffer of the material (omit it for a material with none)."},
               "images":{"type":"object","additionalProperties":{"type":"integer"},"description":"The material's storage image name -> image id from compute.create_image; every image of the material (omit it for a material with none)."},
               "params":{"type":"object","description":"{param: number or array} and {texture: path}; left out keeps the material's default."},
               "groups":{"type":"array","items":{"type":"integer","minimum":1,"maximum":65535},"minItems":1,"maxItems":3,"description":"Workgroups in x, y, z; a missing dimension is 1. Default [1,1,1]."}},
               "required":["material"]})"),
         true, "game"},
        [&I](const Json& a) {
            check_args_known(a, {"material", "buffers", "images", "params", "groups"}, "compute.dispatch");
            Compute& c = need_compute(I, "compute.dispatch");
            ComputeDispatch d;
            d.material = string_arg(a, "material", "compute.dispatch");
            if (a.contains("buffers") && !a["buffers"].is_object())
                throw CommandError("invalid_argument",
                                   "compute.dispatch: buffers: " + describe_json_value(a["buffers"]) +
                                       " is not an object of {bufferName: id}.",
                                   "Pass \"buffers\": {\"boids\": 1}, one id from compute.create_buffer per buffer.");
            if (a.contains("images") && !a["images"].is_object())
                throw CommandError("invalid_argument",
                                   "compute.dispatch: images: " + describe_json_value(a["images"]) +
                                       " is not an object of {imageName: id}.",
                                   "Pass \"images\": {\"field\": 1}, one id from compute.create_image per image.");
            if (a.contains("buffers"))
                for (auto it = a["buffers"].begin(); it != a["buffers"].end(); ++it) {
                    Json one = Json::object({{"id", it.value()}});
                    d.buffers[it.key()] =
                        int(whole_arg(one, "id", 0, 0x7fffffff, ("compute.dispatch buffers/" + it.key()).c_str()));
                }
            if (a.contains("images"))
                for (auto it = a["images"].begin(); it != a["images"].end(); ++it) {
                    Json one = Json::object({{"id", it.value()}});
                    d.images[it.key()] =
                        int(whole_arg(one, "id", 0, 0x7fffffff, ("compute.dispatch images/" + it.key()).c_str()));
                }
            if (a.contains("params")) d.params = a["params"];
            if (a.contains("groups")) {
                const Json& g = a["groups"];
                if (!g.is_array() || g.empty() || g.size() > 3)
                    throw CommandError("invalid_argument",
                                       "compute.dispatch: groups: " + describe_json_value(g) +
                                           " is not an array of 1 to 3 whole numbers.",
                                       "Pass \"groups\": [16] or [16, 16, 1].");
                for (std::size_t i = 0; i < g.size(); ++i) {
                    Json one = Json::object({{"n", g[i]}});
                    d.groups[i] = std::uint32_t(whole_arg(one, "n", 1, kMaxComputeGroups,
                                                          ("compute.dispatch groups/" + std::to_string(i)).c_str()));
                }
            }
            auto done = c.dispatch(d);
            if (!done.ok()) rethrow(done.error());
            return Json::object({{"dispatched", Json::array({d.groups[0], d.groups[1], d.groups[2]})}});
        });

    I.commands.add(
        {"compute.destroy_buffer", "Frees a compute storage buffer.",
         "Destroys the GPU buffer; its id is not used again. Returns {destroyed: id}. Example: "
         "compute.destroy_buffer {\"buffer\":1}" FA_COMMAND_DETAILS
         "Errors: `invalid_argument` for an id that is not alive (compute.list_buffers lists the live ones).",
         parse_schema(R"({"type":"object","properties":{
               "buffer":{"type":"integer","description":"Buffer id from compute.create_buffer."}},"required":["buffer"]})"),
         true, "game"},
        [&I](const Json& a) {
            check_args_known(a, {"buffer"}, "compute.destroy_buffer");
            if (!I.renderer || !I.renderer->initialized())
                throw CommandError("unavailable", "compute.destroy_buffer: no renderer, so no compute buffers.");
            const int id = int(whole_arg(a, "buffer", 0, 0x7fffffff, "compute.destroy_buffer"));
            auto done = I.renderer->compute().destroy_buffer(id);
            if (!done.ok()) rethrow(done.error());
            return Json::object({{"destroyed", id}});
        });

    I.commands.add(
        {"compute.list_buffers", "Lists the live compute storage buffers and whether this backend runs compute.",
         "Returns {available, status, buffers: [{id, material, buffer, count, stride, bytes}]}. `available` is "
         "the answer of render.supports computeShaders; when it is false `status` says which backend cannot and "
         "what to do, and `buffers` is empty. Example: compute.list_buffers {}" FA_COMMAND_DETAILS
         "Without graphics (graphics=false) `available` is false too.",
         parse_schema(R"({"type":"object","properties":{}})"), true, "game"},
        [&I](const Json& a) {
            check_args_known(a, {}, "compute.list_buffers");
            std::string why = "no renderer: the engine runs with graphics=false";
            bool ok = false;
            Json buffers = Json::array();
            if (I.renderer && I.renderer->initialized()) {
                ok = I.renderer->compute().available(&why);
                if (ok) buffers = I.renderer->compute().list();
            }
            return Json::object(
                {{"available", ok}, {"status", ok ? std::string("available") : why}, {"buffers", buffers}});
        });

    I.commands.add(
        {"compute.create_image",
         "Makes a GPU storage image a compute material writes and a material shows; returns its id.",
         "A zero-filled 2D image shaped like one image of a compute material (its \"images\" entry: format rgba8, "
         "rgba16f, r32f or rgba32f). `width` and `height` default to the size the material declares. The image lives "
         "until compute.destroy_image or the end of the game, whatever the scene. Returns {id, material, image, "
         "format, access, width, height, bytes, textureId}: put `textureId` (\"compute:<id>\") in a Sprite.texture, "
         "MeshRenderer.texture or the texture param of a mesh, sprite or post material to show it (rgba8 and rgba16f "
         "filter everywhere; r32f and rgba32f may not on this GPU, then the checker shows and the log says why). "
         "Example: compute.create_image {\"material\":\"materials/noise.material.json\",\"image\":\"field\","
         "\"width\":512,\"height\":512}" FA_COMMAND_DETAILS "Limits: 32 live images, 8192 pixels a side (or what the "
         "GPU allows), 256 MiB each, 512 MiB in all; over one is "
         "`invalid_argument` with the number it hit. A format the backend cannot write as a storage image is refused "
         "with the formats that work. Errors: `unavailable` on a backend without compute shaders (GLES3, WebGL2, "
         "macOS OpenGL 4.1: the message names the backend and the CPU path) or without graphics.",
         parse_schema(R"({"type":"object","properties":{
               "material":{"type":"string","description":"Project-relative path of the compute material, e.g. materials/noise.material.json."},
               "image":{"type":"string","description":"Name of one of the material's images (its \"images\" entry)."},
               "width":{"type":"integer","minimum":0,"maximum":8192,"description":"Width in pixels. Default: the material's size."},
               "height":{"type":"integer","minimum":0,"maximum":8192,"description":"Height in pixels. Default: the material's size."}},
               "required":["material","image"]})"),
         true, "game"},
        [&I](const Json& a) {
            check_args_known(a, {"material", "image", "width", "height"}, "compute.create_image");
            Compute& c = need_compute(I, "compute.create_image");
            const std::string material = string_arg(a, "material", "compute.create_image");
            const std::string image = string_arg(a, "image", "compute.create_image");
            const int w = int(whole_arg(a, "width", 0, kMaxComputeImageSide, "compute.create_image", 0));
            const int h = int(whole_arg(a, "height", 0, kMaxComputeImageSide, "compute.create_image", 0));
            auto id = c.create_image(material, image, w, h);
            if (!id.ok()) rethrow(id.error());
            for (const Json& i : c.list_images())
                if (i["id"] == *id) return i;
            return Json::object({{"id", *id}});
        });

    I.commands.add(
        {"compute.resize_image",
         "Gives a compute storage image another size (its pixels are lost, its texture id stays).",
         "Makes the image `width` x `height` and zero-fills it; `textureId` stays valid, so a Sprite or material that "
         "shows it "
         "follows the new size. Run the dispatch again to fill it. Returns the image as compute.list_images lists it. "
         "Example: compute.resize_image {\"image\":1,\"width\":1024,\"height\":1024}" FA_COMMAND_DETAILS
         "Same limits as compute.create_image. Errors: `unavailable` without compute; `invalid_argument` for an id "
         "that is "
         "not alive or a size over a limit.",
         parse_schema(R"({"type":"object","properties":{
               "image":{"type":"integer","description":"Image id from compute.create_image."},
               "width":{"type":"integer","minimum":1,"maximum":8192,"description":"New width in pixels."},
               "height":{"type":"integer","minimum":1,"maximum":8192,"description":"New height in pixels."}},
               "required":["image","width","height"]})"),
         true, "game"},
        [&I](const Json& a) {
            check_args_known(a, {"image", "width", "height"}, "compute.resize_image");
            Compute& c = need_compute(I, "compute.resize_image");
            const int id = int(whole_arg(a, "image", 0, 0x7fffffff, "compute.resize_image"));
            const int w = int(whole_arg(a, "width", 1, kMaxComputeImageSide, "compute.resize_image"));
            const int h = int(whole_arg(a, "height", 1, kMaxComputeImageSide, "compute.resize_image"));
            auto done = c.resize_image(id, w, h);
            if (!done.ok()) rethrow(done.error());
            for (const Json& i : c.list_images())
                if (i["id"] == id) return i;
            return Json::object({{"id", id}});
        });

    I.commands.add(
        {"compute.read_image", "Reads pixels of a compute storage image back to the game (waits for the GPU).",
         "Submits the recorded GPU work, waits for it and returns {x, y, width, height, format, channels, data}: "
         "`data` is "
         "a flat array, row by row from the top, pixel by pixel, `channels` numbers each (rgba8: integers 0..255; "
         "rgba16f "
         "and rgba32f: r, g, b, a floats; r32f: one float), floats with 7 significant digits, a NaN or infinity is "
         "null. "
         "A read back stalls the frame: do it for a result you need, not every frame. Example: compute.read_image "
         "{\"image\":1,\"x\":0,\"y\":0,\"width\":4,\"height\":4}" FA_COMMAND_DETAILS
         "x and y default to 0, and width and height to the right and bottom edge; when both are left out of an image "
         "too "
         "large for one call, you get the top rows that fit (width from x to the right edge). At most 4194304 numbers "
         "in "
         "one call (read a large image in rectangles). Errors: `unavailable` without compute; `invalid_argument` for "
         "an id that is "
         "not alive or a rectangle outside the image.",
         parse_schema(R"({"type":"object","properties":{
               "image":{"type":"integer","description":"Image id from compute.create_image."},
               "x":{"type":"integer","minimum":0,"description":"Left pixel of the rectangle. Default 0."},
               "y":{"type":"integer","minimum":0,"description":"Top pixel of the rectangle. Default 0."},
               "width":{"type":"integer","minimum":0,"description":"Width of the rectangle; 0 or left out = to the right edge."},
               "height":{"type":"integer","minimum":0,"description":"Height of the rectangle; 0 or left out = to the bottom edge."}},
               "required":["image"]})"),
         true, "game"},
        [&I](const Json& a) {
            check_args_known(a, {"image", "x", "y", "width", "height"}, "compute.read_image");
            Compute& c = need_compute(I, "compute.read_image");
            const int id = int(whole_arg(a, "image", 0, 0x7fffffff, "compute.read_image"));
            const int x = int(whole_arg(a, "x", 0, kMaxComputeImageSide, "compute.read_image", 0));
            const int y = int(whole_arg(a, "y", 0, kMaxComputeImageSide, "compute.read_image", 0));
            int w = int(whole_arg(a, "width", 0, kMaxComputeImageSide, "compute.read_image", 0));
            int h = int(whole_arg(a, "height", 0, kMaxComputeImageSide, "compute.read_image", 0));
            if (!a.contains("width") &&
                !a.contains("height")) {  // the whole image would not fit one call: take what fits
                for (const Json& i : c.list_images())
                    if (i["id"] == id && x < i["width"].get<int>() && y < i["height"].get<int>()) {
                        const std::uint64_t iw = std::uint64_t(i["width"].get<int>() - x);
                        const std::uint64_t ih = std::uint64_t(i["height"].get<int>() - y);
                        const std::uint64_t most = c.max_json_pixels(id);
                        w = int(iw);
                        h = int(std::max<std::uint64_t>(1, std::min(ih, most / iw)));
                    }
            }
            auto data = c.read_image(id, x, y, w, h);
            if (!data.ok()) rethrow(data.error());
            return *data;
        });

    I.commands.add(
        {"compute.destroy_image", "Frees a compute storage image.",
         "Destroys the GPU image; its id is not used again and a material that still shows its textureId gets the "
         "checker "
         "(the log says why). Returns {destroyed: id}. Example: compute.destroy_image {\"image\":1}" FA_COMMAND_DETAILS
         "Errors: `invalid_argument` for an id that is not alive (compute.list_images lists the live ones).",
         parse_schema(R"({"type":"object","properties":{
               "image":{"type":"integer","description":"Image id from compute.create_image."}},"required":["image"]})"),
         true, "game"},
        [&I](const Json& a) {
            check_args_known(a, {"image"}, "compute.destroy_image");
            if (!I.renderer || !I.renderer->initialized())
                throw CommandError("unavailable", "compute.destroy_image: no renderer, so no compute images.");
            const int id = int(whole_arg(a, "image", 0, 0x7fffffff, "compute.destroy_image"));
            auto done = I.renderer->compute().destroy_image(id);
            if (!done.ok()) rethrow(done.error());
            return Json::object({{"destroyed", id}});
        });

    I.commands.add(
        {"compute.list_images", "Lists the live compute storage images and whether this backend runs compute.",
         "Returns {available, status, images: [{id, material, image, format, access, width, height, bytes, "
         "textureId}]}. "
         "`available` is the answer of render.supports computeShaders; when it is false `status` says which backend "
         "cannot and the CPU path to use instead, and `images` is empty. Example: compute.list_images "
         "{}" FA_COMMAND_DETAILS "Without graphics (graphics=false) `available` is false too.",
         parse_schema(R"({"type":"object","properties":{}})"), true, "game"},
        [&I](const Json& a) {
            check_args_known(a, {}, "compute.list_images");
            std::string why = "no renderer: the engine runs with graphics=false";
            bool ok = false;
            Json images = Json::array();
            if (I.renderer && I.renderer->initialized()) {
                ok = I.renderer->compute().available(&why);
                if (ok) images = I.renderer->compute().list_images();
            }
            return Json::object(
                {{"available", ok}, {"status", ok ? std::string("available") : why}, {"images", images}});
        });

    declare_command_capabilities(I.commands, {
                                                 {"compute.create_image", capability_sets::changes_state()},
                                                 {"compute.resize_image", capability_sets::changes_state()},
                                                 {"compute.read_image", capability_sets::reads()},
                                                 {"compute.destroy_image", capability_sets::changes_state()},
                                                 {"compute.list_images", capability_sets::reads()},
                                                 {"compute.create_buffer", capability_sets::changes_state()},
                                                 {"compute.write_buffer", capability_sets::changes_state()},
                                                 {"compute.read_buffer", capability_sets::reads()},
                                                 {"compute.dispatch", capability_sets::changes_state()},
                                                 {"compute.destroy_buffer", capability_sets::changes_state()},
                                                 {"compute.list_buffers", capability_sets::reads()},
                                             });
}

}  // namespace fa
