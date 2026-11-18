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
                           std::string(command) + ": " + key + ": " + describe_json_value(v) + " is not a whole number from " +
                               std::to_string(lo) + " to " + std::to_string(hi) + ".",
                           std::string("Pass \"") + key + "\" as a whole number in that range.");
    return std::uint64_t(d);
}

std::string string_arg(const Json& a, const char* key, const char* command) {
    if (!a.is_object() || !a.contains(key) || !a[key].is_string() || a[key].get<std::string>().empty())
        throw CommandError("invalid_argument",
                           std::string(command) + ": " + key + " is required, a non-empty string" +
                               (a.is_object() && a.contains(key) ? " (got " + describe_json_value(a[key]) + ")" : "") + ".",
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
         "(its \"buffers\" entry: fields of float, vec2, vec3, vec4, int, uint). `initial` fills the first elements. The "
         "buffer lives until compute.destroy_buffer or the end of the game, whatever the scene (it is not part of one). "
         "Returns {id, count, stride, bytes}. Example: compute.create_buffer {\"material\":\"materials/boids.material.json\","
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
         "`invalid_argument` for an unknown buffer id (compute.list_buffers), a range outside the buffer, or a value that "
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
         "Submits the recorded GPU work, waits for it and returns `count` elements from `first` as an array of {field: value} "
         "objects: a vecN field is an array, floats have 7 significant digits, a NaN or infinity is null. A read back "
         "stalls the frame: do it for a result you need, not every frame. Example: compute.read_buffer {\"buffer\":1,"
         "\"first\":0,\"count\":10}" FA_COMMAND_DETAILS
         "At most 1048576 elements in one call (read a large buffer in parts). Errors: `unavailable` without compute (see "
         "compute.create_buffer); `invalid_argument` for an unknown buffer id or a range outside the buffer.",
         parse_schema(R"({"type":"object","properties":{
               "buffer":{"type":"integer","description":"Buffer id from compute.create_buffer."},
               "first":{"type":"integer","minimum":0,"description":"Index of the first element to read. Default 0."},
               "count":{"type":"integer","minimum":0,"description":"Number of elements to read. Default: from `first` to the end (at most 1048576)."}},
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
                if (found) count = total > first ? std::min(total - first, kMaxComputeJsonElements) : 0;
            }
            auto data = c.read_buffer(id, first, count);
            if (!data.ok()) rethrow(data.error());
            return *data;
        });

    I.commands.add(
        {"compute.dispatch", "Runs a compute material once over its storage buffers.",
         "`groups` counts WORKGROUPS of the material's workgroupSize threads each, not threads: ceil(work / "
         "workgroupSize.x) for a one-dimensional job. `buffers` gives a buffer id for every buffer of the material; `params` "
         "its param values and texture paths (like MeshRenderer.materialParams; what is left out keeps the material's "
         "default). The call returns when the work is recorded; compute.read_buffer waits for it. Returns {dispatched: "
         "[x, y, z]}. Example: compute.dispatch {\"material\":\"materials/boids.material.json\",\"buffers\":{\"boids\":1},"
         "\"params\":{\"speed\":2},\"groups\":[16,1,1]}" FA_COMMAND_DETAILS
         "Each dimension of `groups` is 1 to 65535. A buffer must have been made for the same buffer of the same material "
         "(same layout), and one buffer cannot be bound twice. Errors: `unavailable` without compute (see "
         "compute.create_buffer); `invalid_argument` for a missing or unknown buffer or param (did you mean), a value of "
         "the wrong type, or groups out of range.",
         parse_schema(R"({"type":"object","properties":{
               "material":{"type":"string","description":"Project-relative path of the compute material."},
               "buffers":{"type":"object","additionalProperties":{"type":"integer"},"description":"The material's buffer name -> buffer id from compute.create_buffer; every buffer of the material."},
               "params":{"type":"object","description":"{param: number or array} and {texture: path}; left out keeps the material's default."},
               "groups":{"type":"array","items":{"type":"integer","minimum":1,"maximum":65535},"minItems":1,"maxItems":3,"description":"Workgroups in x, y, z; a missing dimension is 1. Default [1,1,1]."}},
               "required":["material","buffers"]})"),
         true, "game"},
        [&I](const Json& a) {
            check_args_known(a, {"material", "buffers", "params", "groups"}, "compute.dispatch");
            Compute& c = need_compute(I, "compute.dispatch");
            ComputeDispatch d;
            d.material = string_arg(a, "material", "compute.dispatch");
            if (!a.contains("buffers") || !a["buffers"].is_object())
                throw CommandError("invalid_argument",
                                   "compute.dispatch: buffers: " +
                                       (a.contains("buffers") ? describe_json_value(a["buffers"]) : std::string("missing")) +
                                       " is not an object of {bufferName: id}.",
                                   "Pass \"buffers\": {\"boids\": 1}, one id from compute.create_buffer per buffer.");
            for (auto it = a["buffers"].begin(); it != a["buffers"].end(); ++it) {
                Json one = Json::object({{"id", it.value()}});
                d.buffers[it.key()] = int(whole_arg(one, "id", 0, 0x7fffffff, ("compute.dispatch buffers/" + it.key()).c_str()));
            }
            if (a.contains("params")) d.params = a["params"];
            if (a.contains("groups")) {
                const Json& g = a["groups"];
                if (!g.is_array() || g.empty() || g.size() > 3)
                    throw CommandError("invalid_argument", "compute.dispatch: groups: " + describe_json_value(g) +
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

    I.commands.add({"compute.destroy_buffer", "Frees a compute storage buffer.",
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

    I.commands.add({"compute.list_buffers", "Lists the live compute storage buffers and whether this backend runs compute.",
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
                       return Json::object({{"available", ok}, {"status", ok ? std::string("available") : why}, {"buffers", buffers}});
                   });

    declare_command_capabilities(I.commands, {
                                                 {"compute.create_buffer", capability_sets::changes_state()},
                                                 {"compute.write_buffer", capability_sets::changes_state()},
                                                 {"compute.read_buffer", capability_sets::reads()},
                                                 {"compute.dispatch", capability_sets::changes_state()},
                                                 {"compute.destroy_buffer", capability_sets::changes_state()},
                                                 {"compute.list_buffers", capability_sets::reads()},
                                             });
}

}  // namespace fa
