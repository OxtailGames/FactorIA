// image.select: builds a selection of a document's canvas (by colour, alpha, rectangle, ellipse, polygon or a layer's shape),
// shapes it (grow, shrink, feather, invert), combines it with the stored one, and stores it by name. image.edit and image.paint
// use the name. Selections are grey PNGs in .factoria/selections/<document>/ (see image_edit.h).
#include <algorithm>
#include <cmath>
#include <format>

#include "fa/core/strings.h"
#include "fa/tooling/project_fs.h"
#include "image_doc_internal.h"
#include "image_edit.h"
#include "image_frames.h"
#include "util.h"

namespace fa::imgedit {

using assets_detail::arg_error;
using assets_detail::check_arg_keys;
using tooling_detail::arg_bool;
using tooling_detail::arg_string;

namespace {

const char* kCmd = "image.select";

double num_arg(const Json& a, const std::string& base, const char* key, double lo, double hi, double def, bool required = false) {
    auto it = a.find(key);
    if (it == a.end() || it->is_null()) {
        if (required) arg_error(kCmd, base + "/" + key, std::string("`") + key + "` is required here.", "A number.");
        return def;
    }
    if (!it->is_number() || it->get<double>() < lo || it->get<double>() > hi)
        arg_error(kCmd, base + "/" + key, std::format("`{}` must be a number from {} to {}, got {}.", key, lo, hi, describe_json_value(*it)), "");
    return it->get<double>();
}

Mask shape_mask(int w, int h, const std::vector<imgdoc::Polyline>& shapes) {
    const imgdoc::Plane plane = imgdoc::fill_shapes(shapes, w, h, 0, 0);
    Mask m(w, h);
    for (std::size_t i = 0; i < m.v.size(); ++i) m.v[i] = std::uint8_t(std::lround(std::clamp(plane.v[i], 0.0f, 1.0f) * 255.0f));
    return m;
}

struct Box {
    double x = 0, y = 0, w = 0, h = 0;
};

Box box_arg(const Json& a, const char* by) {
    Box b;
    const std::string where = std::string("/") + by;
    // the box may be flat (x, y, width, height at the top level) or an object under the name of the shape
    const Json* src = &a;
    if (a.contains(by) && a[by].is_object()) src = &a[by];
    const std::string base = src == &a ? "" : where;
    b.x = num_arg(*src, base, "x", -1e6, 1e6, 0, true);
    b.y = num_arg(*src, base, "y", -1e6, 1e6, 0, true);
    b.w = num_arg(*src, base, "width", 0, 1e6, 0, true);
    b.h = num_arg(*src, base, "height", 0, 1e6, 0, true);
    return b;
}

Color read_color(const Json& v) { return assets_detail::colour_arg(kCmd, v, "/color"); }

int distance(const std::uint8_t* p, const std::uint8_t* q) {
    if (p[3] == 0 && q[3] == 0) return 0;
    return std::max({std::abs(p[0] - q[0]), std::abs(p[1] - q[1]), std::abs(p[2] - q[2]), std::abs(p[3] - q[3])});
}

}  // namespace

Json image_select(const std::string& projectDir, const Json& a) {
    check_arg_keys(kCmd, a, "",
                   {"path", "name", "by", "mode", "then", "clear", "color", "at", "tolerance", "contiguous", "threshold", "layer", "x", "y", "width", "height", "points", "rect",
                    "ellipse", "polygon", "frame"});
    DocFile d = open_doc(projectDir, arg_string(a, "path", true), kCmd);
    FrameScope frameScope(projectDir, d.rel, d.json, a, kCmd);   // color / alpha / layer selections read the picture of `frame`
    const int W = d.json.value("width", 0), H = d.json.value("height", 0);
    const std::string name = arg_string(a, "name", false, "selection");
    if (!valid_selection_name(name) || name == "all")
        arg_error(kCmd, "/name", "'" + name + "' is not a usable selection name.", "Use 1 to 40 letters, digits, '-' or '_' (\"all\" is reserved for the whole canvas), e.g. \"sky\".");
    std::vector<std::string> warnings;

    if (arg_bool(a, "clear", false)) {
        auto p = resolve_project_path(projectDir, selection_file(d.rel, name));
        std::error_code ec;
        const bool had = p.ok() && stdfs::remove(*p, ec);
        auto pp = resolve_project_path(projectDir, ".factoria/selections/" + d.rel + "/" + name + ".preview.png");
        if (pp.ok()) stdfs::remove(*pp, ec);
        return Json::object({{"document", d.rel}, {"name", name}, {"cleared", had}, {"selections", list_selections(projectDir, d.rel)},
                             {"nextSteps", Json::array({"Select again with image.select."})}});
    }

    std::string by = arg_string(a, "by", false);
    const Json then = a.contains("then") && !a["then"].is_null() ? a["then"] : Json::array();
    if (!then.is_array())
        arg_error(kCmd, "/then", "expected a list of steps, got " + describe_json_value(then) + ".", "Example: [{\"grow\":2},{\"feather\":1.5}]. Steps: grow, shrink, feather (pixels), invert (true).");

    CombineMode mode = CombineMode::Replace;
    {
        const std::string m = arg_string(a, "mode", false, "replace");
        const std::vector<std::string> modes = {"replace", "add", "subtract", "intersect"};
        const auto it = std::find(modes.begin(), modes.end(), m);
        if (it == modes.end()) arg_error(kCmd, "/mode", "unknown mode '" + m + "'.", did_you_mean(m, modes) + " Modes: replace, add, subtract, intersect.");
        mode = CombineMode(it - modes.begin());
    }

    // 1. the new shape
    Mask fresh(W, H);
    std::optional<Image> source;  // the picture colour/alpha selections read
    auto source_image = [&]() -> const Image& {
        if (!source) {
            if (a.contains("layer") && !a["layer"].is_null()) {
                LayerRef ref = find_layer(d.json, a["layer"], kCmd);
                source = render_layer_alone(projectDir, *ref.layer, W, H, ref.parentX, ref.parentY, &warnings, &d.json);
            } else {
                std::vector<ImageIssue> issues;
                auto parsed = parse_image_document(d.json, d.rel, projectDir, &issues);
                if (!parsed.ok()) fail("invalid_argument", parsed.error().message, parsed.error().hint);
                ImageRenderOptions options{projectDir};
                options.frame = frameScope.frame();
                auto render = composite_image_document(*parsed, options);
                if (!render.ok()) fail("failed", render.error().message, render.error().hint);
                source = std::move(render->image);
            }
        }
        return *source;
    };

    if (by.empty()) {
        if (then.empty())
            arg_error(kCmd, "/by", "say what to select: `by` is one of color, alpha, rect, ellipse, polygon, layer, all.",
                      "Example: {\"path\":\"" + d.rel + "\",\"name\":\"sky\",\"by\":\"rect\",\"x\":0,\"y\":0,\"width\":64,\"height\":32}. To reshape the stored selection, give `then` without `by`.");
    } else if (by == "all") {
        fresh = Mask(W, H, 255);
    } else if (by == "rect" || by == "ellipse") {
        const Box b = box_arg(a, by.c_str());
        imgdoc::Polyline poly;
        if (by == "rect") poly.pts = {{float(b.x), float(b.y)}, {float(b.x + b.w), float(b.y)}, {float(b.x + b.w), float(b.y + b.h)}, {float(b.x), float(b.y + b.h)}};
        else poly = imgdoc::ellipse_polyline(float(b.x), float(b.y), float(b.w), float(b.h));
        fresh = shape_mask(W, H, {poly});
    } else if (by == "polygon") {
        const Json* pts = a.contains("points") ? &a["points"] : (a.contains("polygon") && a["polygon"].is_array() ? &a["polygon"] : nullptr);
        if (!pts || !pts->is_array() || pts->size() < 3)
            arg_error(kCmd, "/points", "a polygon needs `points`: at least three [x, y] corners.", "Example: \"points\":[[2,2],[30,4],[16,28]].");
        imgdoc::Polyline poly;
        for (std::size_t i = 0; i < pts->size(); ++i) {
            const Json& p = (*pts)[i];
            if (!p.is_array() || p.size() != 2 || !p[0].is_number() || !p[1].is_number())
                arg_error(kCmd, "/points/" + std::to_string(i), "expected [x, y], got " + describe_json_value(p) + ".", "Example: [12, 30].");
            poly.pts.push_back({p[0].get<float>(), p[1].get<float>()});
        }
        fresh = shape_mask(W, H, {poly});
    } else if (by == "layer") {
        if (!a.contains("layer") || a["layer"].is_null()) arg_error(kCmd, "/layer", "`by: \"layer\"` needs `layer`: the layer whose shape is selected.", "Example: \"layer\":\"hero\". " + describe_layers(d.json, 12));
        const Image& img = source_image();
        for (std::size_t i = 0; i < fresh.v.size(); ++i) fresh.v[i] = img.rgba[i * 4 + 3];
    } else if (by == "alpha") {
        const int threshold = int(num_arg(a, "", "threshold", 1, 255, 1));
        const Image& img = source_image();
        for (std::size_t i = 0; i < fresh.v.size(); ++i) fresh.v[i] = img.rgba[i * 4 + 3] >= threshold ? 255 : 0;
    } else if (by == "color") {
        const Image& img = source_image();
        const int tol = int(num_arg(a, "", "tolerance", 0, 255, 16));
        std::array<std::uint8_t, 4> target{};
        std::optional<std::pair<int, int>> seed;
        if (a.contains("at") && !a["at"].is_null()) {
            const Json& at = a["at"];
            if (!at.is_array() || at.size() != 2 || !at[0].is_number() || !at[1].is_number())
                arg_error(kCmd, "/at", "expected [x, y], got " + describe_json_value(at) + ".", "Example: \"at\":[10, 4].");
            const int sx = int(std::floor(at[0].get<double>())), sy = int(std::floor(at[1].get<double>()));
            if (sx < 0 || sy < 0 || sx >= W || sy >= H) arg_error(kCmd, "/at", std::format("the point ({}, {}) is outside the {}x{} canvas.", sx, sy, W, H), "Use x from 0 to " + std::to_string(W - 1) + " and y from 0 to " + std::to_string(H - 1) + ".");
            seed = std::pair{sx, sy};
        }
        if (a.contains("color") && !a["color"].is_null()) {
            const Color c = read_color(a["color"]);
            target = {std::uint8_t(std::lround(std::clamp(c.r, 0.f, 1.f) * 255)), std::uint8_t(std::lround(std::clamp(c.g, 0.f, 1.f) * 255)),
                      std::uint8_t(std::lround(std::clamp(c.b, 0.f, 1.f) * 255)), std::uint8_t(std::lround(std::clamp(c.a, 0.f, 1.f) * 255))};
        } else if (seed) {
            std::copy_n(&img.rgba[(std::size_t(seed->second) * W + seed->first) * 4], 4, target.begin());
        } else {
            arg_error(kCmd, "/color", "`by: \"color\"` needs `color` (the colour to select) or `at` ([x, y], a pixel whose colour is taken).",
                      "Example: {\"by\":\"color\",\"color\":\"#ff0000\",\"tolerance\":24} or {\"by\":\"color\",\"at\":[3,3],\"contiguous\":true}.");
        }
        auto matches = [&](int x, int y) { return distance(&img.rgba[(std::size_t(y) * W + x) * 4], target.data()) <= tol; };
        if (arg_bool(a, "contiguous", false)) {
            if (!seed) arg_error(kCmd, "/contiguous", "a contiguous selection grows from a point: give `at` [x, y].", "Example: \"at\":[3,3]. Without `contiguous` every pixel of the colour is selected.");
            if (matches(seed->first, seed->second)) {
                std::vector<std::pair<int, int>> stack = {*seed};
                fresh.ref(seed->first, seed->second) = 255;
                while (!stack.empty()) {
                    const auto [x, y] = stack.back();
                    stack.pop_back();
                    const int nx[4] = {x - 1, x + 1, x, x}, ny[4] = {y, y, y - 1, y + 1};
                    for (int k = 0; k < 4; ++k) {
                        if (nx[k] < 0 || ny[k] < 0 || nx[k] >= W || ny[k] >= H || fresh.at(nx[k], ny[k]) || !matches(nx[k], ny[k])) continue;
                        fresh.ref(nx[k], ny[k]) = 255;
                        stack.push_back({nx[k], ny[k]});
                    }
                }
            } else {
                warnings.push_back("The pixel at `at` is not within `tolerance` of the colour, so nothing was selected.");
            }
        } else {
            for (int y = 0; y < H; ++y)
                for (int x = 0; x < W; ++x)
                    if (matches(x, y)) fresh.ref(x, y) = 255;
        }
    } else {
        const std::vector<std::string> bys = {"color", "alpha", "rect", "ellipse", "polygon", "layer", "all"};
        arg_error(kCmd, "/by", "unknown selection kind '" + by + "'.", did_you_mean(by, bys) + " Kinds: " + join(bys, ", ") + ".");
    }

    // 2. `then`: grow, shrink, feather, invert (on the new shape, or on the stored one when there is no `by`)
    Mask stored;
    const bool reshapeStored = by.empty();
    if (reshapeStored) fresh = load_selection(projectDir, d.rel, name, W, H, kCmd);
    for (std::size_t i = 0; i < then.size(); ++i) {
        const Json& step = then[i];
        const std::string at = "/then/" + std::to_string(i);
        if (!step.is_object() || step.empty())
            arg_error(kCmd, at, "a step is an object such as {\"grow\":2}, got " + describe_json_value(step) + ".", "Steps: grow, shrink, feather (pixels), invert (true).");
        for (auto it = step.begin(); it != step.end(); ++it) {
            const std::string key = it.key();
            const std::vector<std::string> steps = {"grow", "shrink", "feather", "invert"};
            if (std::find(steps.begin(), steps.end(), key) == steps.end())
                arg_error(kCmd, at + "/" + key, "unknown step '" + key + "'.", did_you_mean(key, steps) + " Steps: grow, shrink, feather (pixels), invert (true).");
            if (key == "invert") {
                if (it.value() == true) mask_invert(fresh);
                continue;
            }
            if (!it.value().is_number() || it.value().get<double>() < 0 || it.value().get<double>() > 512)
                arg_error(kCmd, at + "/" + key, "`" + key + "` is a number of pixels from 0 to 512, got " + describe_json_value(it.value()) + ".", "Example: {\"" + key + "\":2}.");
            const float px = it.value().get<float>();
            if (key == "grow") mask_grow(fresh, px);
            else if (key == "shrink") mask_shrink(fresh, px);
            else mask_feather(fresh, px);
        }
    }

    // 3. combine with the stored selection
    Mask result = fresh;
    if (!reshapeStored && mode != CombineMode::Replace) {
        if (!selection_exists(projectDir, d.rel, name)) {
            if (mode == CombineMode::Add) {
                warnings.push_back("There was no stored selection named '" + name + "', so the new shape is the selection.");
            } else {
                arg_error(kCmd, "/mode", "mode '" + arg_string(a, "mode", false) + "' needs an existing selection named '" + name + "' to combine with.",
                          "Make one first (image.select with the same `name`), or use mode \"replace\". Stored: " + (list_selections(projectDir, d.rel).empty() ? std::string("none") : join(list_selections(projectDir, d.rel), ", ")) + ".");
            }
        } else {
            result = load_selection(projectDir, d.rel, name, W, H, kCmd);
            mask_combine(result, fresh, mode);
        }
    }
    save_selection(projectDir, d.rel, name, result);

    const Region bounds = result.bounds();
    const std::size_t selected = result.count();
    std::optional<Image> picture = render_document_json(projectDir, d.json);
    if (!picture) {
        picture = Image();
        picture->width = W;
        picture->height = H;
        picture->rgba.assign(std::size_t(W) * H * 4, 0);
    }
    const std::string preview = write_selection_preview(projectDir, d.rel, name, *picture, result);
    auto previewPath = resolve_project_path(projectDir, preview);
    Json out = Json::object({{"document", d.rel}, {"name", name}, {"selection", name}, {"file", selection_file(d.rel, name)}, {"selected", selected},
                             {"coverage", double(selected) / double(std::max<std::size_t>(1, result.v.size()))}, {"region", bounds.to_json()},
                             {"selections", list_selections(projectDir, d.rel)}});
    if (previewPath.ok()) out["$image"] = Json::object({{"path", previewPath->string()}, {"mimeType", "image/png"}});
    if (selected == 0) warnings.push_back("The selection is empty: nothing is selected, so image.edit would change nothing.");
    if (!warnings.empty()) out["warnings"] = warnings;
    out["nextSteps"] = Json::array({"Use it: image.edit {\"path\":\"" + d.rel + "\",\"selection\":\"" + name + "\",\"layer\":\"<layer>\",\"action\":{\"type\":\"fill\",\"color\":\"#ff0000\"}}.",
                                    "The picture shows the selected part as is and the rest dimmed, with the edge in black and white. The selection stays stored until you replace or clear it."});
    return out;
}

void register_select_commands(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "image.select";
    info.category = "assets";
    info.readOnly = false;
    info.summary = "Select part of an image document's canvas (by colour, alpha, rectangle, ellipse, polygon or a layer's shape) and store it by name for image.edit and image.paint.";
    info.description =
        "Builds a selection: a coverage (0..255) per canvas pixel. `by` picks how: color (pixels within `tolerance` 0..255 of `color`, or of the pixel at `at`; "
        "`contiguous: true` only the connected area around `at`), alpha (pixels whose alpha is at least `threshold`), rect or ellipse (x, y, width, height; anti-aliased), "
        "polygon (`points` [[x,y],...]), layer (the layer's shape: its alpha after its masks and effects, soft edges kept) or all. color and alpha read the flattened "
        "picture, or only `layer` when it is given. `then` reshapes the new selection with steps in order: [{\"grow\":2},{\"shrink\":1},{\"feather\":1.5},{\"invert\":true}] "
        "(pixels; grow and shrink use a round brush and make a hard edge; feather is a blur of sigma pixels/2). `mode` combines the result with the stored selection "
        "of the same `name`: replace (default), add, subtract or intersect. Without `by`, `then` reshapes the stored selection; `clear: true` deletes it. "
        "PERSISTENCE: the selection is saved as a grey PNG of the canvas at .factoria/selections/<document path>/<name>.png (white = selected) and stays until replaced or "
        "cleared; later calls use it by name (the name \"all\" is the whole canvas without a file). Changing the canvas size makes old selections unusable (they say so). "
        "The result has `selected` (pixels), `coverage`, the bounding box as `region` {x,y,width,height} and the picture with the selection marked as `$image`. "
        "IN AN ANIMATION (frames, docs.read IMAGES \"Frames and tags\") color, alpha and layer selections read the picture of `frame` (default 0: the layer's cel for that frame, or the whole picture "
        "of that frame); the stored selection is one mask of the canvas per document and name, the same for every frame, so select on the frame you are working on. "
        "Example: {\"path\":\"assets/art/hero.image.json\",\"name\":\"cape\",\"by\":\"color\",\"at\":[20,30],\"contiguous\":true,\"tolerance\":20,\"then\":[{\"grow\":1}]}";
    info.inputSchema = Json::parse(R"({"type":"object","required":["path"],"properties":{
      "path":{"type":"string","description":"The image document, project-relative, ending in .image.json."},
      "name":{"type":"string","default":"selection","description":"The selection's name (1-40 letters, digits, - or _). Reusing a name replaces it, or combines with it when mode is not replace."},
      "by":{"type":"string","enum":["color","alpha","rect","ellipse","polygon","layer","all"],"description":"How to select. Omit it to reshape the stored selection with `then`."},
      "mode":{"type":"string","enum":["replace","add","subtract","intersect"],"default":"replace","description":"How the new shape combines with the stored selection of the same name."},
      "then":{"type":"array","items":{"type":"object"},"description":"Steps applied to the new shape, in order: {\"grow\":px}, {\"shrink\":px}, {\"feather\":px}, {\"invert\":true}."},
      "clear":{"type":"boolean","default":false,"description":"Delete the stored selection `name`."},
      "color":{"description":"by color: the colour to select (\"#rrggbb\", a CSS name, [r,g,b,a])."},
      "at":{"type":"array","items":{"type":"number"},"description":"by color: [x, y] canvas pixel whose colour is taken when `color` is not given, and where a contiguous selection starts."},
      "tolerance":{"type":"number","minimum":0,"maximum":255,"default":16,"description":"by color: the largest difference of any channel (r, g, b, a; 0..255) that still matches."},
      "contiguous":{"type":"boolean","default":false,"description":"by color: select only the connected area (4-neighbours) around `at`."},
      "threshold":{"type":"number","minimum":1,"maximum":255,"default":1,"description":"by alpha: the least alpha (0..255) that is selected."},
      "layer":{"description":"by layer: the layer (name or index path). For color and alpha: read only this layer instead of the flattened picture."},
      "x":{"type":"number","description":"rect / ellipse: left of the box, canvas pixels."},
      "y":{"type":"number","description":"rect / ellipse: top of the box."},
      "width":{"type":"number","minimum":0,"description":"rect / ellipse: width of the box."},
      "height":{"type":"number","minimum":0,"description":"rect / ellipse: height of the box."},
      "points":{"type":"array","items":{"type":"array","items":{"type":"number"}},"description":"polygon: the corners [[x,y],...], at least three."}}})");
    add_frame_support(info, "the color, alpha and layer selections read", false, "the selection reads the picture of that frame; the stored selection itself is the same for every frame");
    registry.add(info, [projectDir](const Json& args) { return image_select(projectDir, args); });
}

}  // namespace fa::imgedit
