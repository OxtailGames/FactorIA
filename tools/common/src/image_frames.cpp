// The timeline of an image document (what each layer shows in each frame) and FrameScope, which lets the single-frame editing commands
// work on one frame of an animated document. See image_frames.h.
#include "image_frames.h"

#include <algorithm>
#include <cmath>
#include <format>

#include "fa/core/asset_manifest.h"
#include "fa/core/strings.h"
#include "fa/tooling/project_fs.h"
#include "util.h"

namespace fa::imgedit {

using assets_detail::arg_error;
using assets_detail::fail;

namespace {

thread_local FrameScope* g_current = nullptr;

int json_int(const Json& j, const char* key, int def) {
    auto it = j.find(key);
    return it != j.end() && it->is_number() ? int(std::lround(it->get<double>())) : def;
}

std::optional<Image> read_png_rel(const std::string& projectDir, const std::string& rel) {
    if (rel.empty()) return std::nullopt;
    auto path = resolve_project_path(projectDir, rel);
    if (!path.ok()) return std::nullopt;
    auto bytes = tooling_detail::read_file(*path);
    if (!bytes) return std::nullopt;
    auto img = decode_image(reinterpret_cast<const std::uint8_t*>(bytes->data()), bytes->size());
    if (!img.ok()) return std::nullopt;
    return std::move(*img);
}

// The opaque box of a picture placed at (x, y): the pixels that show, cropped, and where they land. Equal pictures have equal boxes even when
// one of them kept transparent margins.
struct Trimmed {
    Image img;
    int x = 0, y = 0;
    bool empty = true;
};
Trimmed trimmed(const Image& in, int x, int y) {
    Trimmed t;
    int x0 = in.width, y0 = in.height, x1 = -1, y1 = -1;
    for (int py = 0; py < in.height; ++py)
        for (int px = 0; px < in.width; ++px)
            if (in.rgba[(std::size_t(py) * in.width + px) * 4 + 3]) {
                x0 = std::min(x0, px);
                x1 = std::max(x1, px);
                y0 = std::min(y0, py);
                y1 = std::max(y1, py);
            }
    if (x1 < 0) return t;
    t.empty = false;
    t.img.width = x1 - x0 + 1;
    t.img.height = y1 - y0 + 1;
    t.img.rgba.resize(std::size_t(t.img.width) * t.img.height * 4);
    for (int py = 0; py < t.img.height; ++py)
        std::copy_n(&in.rgba[(std::size_t(py + y0) * in.width + x0) * 4], std::size_t(t.img.width) * 4, &t.img.rgba[std::size_t(py) * t.img.width * 4]);
    t.x = x + x0;
    t.y = y + y0;
    return t;
}

void set_or_erase(Json& j, const char* key, int value) {
    if (value == 0) j.erase(key);
    else j[key] = value;
}

void collect_timeline(const Json& list, const std::string& base, int frames, std::vector<TimelineLayer>& out) {
    if (!list.is_array()) return;
    for (std::size_t i = 0; i < list.size(); ++i) {
        const Json& l = list[i];
        if (!l.is_object()) continue;
        const std::string pointer = base + "/layers/" + std::to_string(i);
        const std::string kind = l.value("kind", std::string());
        if (kind == "pixels" || kind == "indexed") {
            TimelineLayer t;
            t.pointer = pointer;
            t.indexed = kind == "indexed";
            t.frames = layer_cels(l, frames);
            out.push_back(std::move(t));
        }
        if (auto kids = l.find("layers"); kids != l.end()) collect_timeline(*kids, pointer, frames, out);
    }
}

}  // namespace

bool CelData::same(const CelData& o, const std::string& projectDir) const {
    if (empty || o.empty) return empty == o.empty;
    if (x != o.x || y != o.y || opacity != o.opacity || rows != o.rows) return false;
    if (source == o.source) return true;
    if (projectDir.empty() || source.empty() || o.source.empty()) return false;
    const auto a = read_png_rel(projectDir, source), b = read_png_rel(projectDir, o.source);
    return a && b && a->width == b->width && a->height == b->height && a->rgba == b->rgba;
}

int json_frame_count(const Json& doc) {
    auto it = doc.find("frames");
    return it != doc.end() && it->is_array() && !it->empty() ? int(it->size()) : 1;
}

bool json_animated(const Json& doc) {
    if (doc.contains("frames") || doc.contains("sheet")) return true;
    auto it = doc.find("tags");
    return it != doc.end() && it->is_array() && !it->empty();
}

std::vector<CelData> layer_cels(const Json& layer, int frames) {
    frames = std::max(1, frames);
    const bool indexed = layer.value("kind", std::string()) == "indexed";
    std::vector<CelData> t(static_cast<std::size_t>(frames));
    CelData base;
    base.x = json_int(layer, "x", 0);
    base.y = json_int(layer, "y", 0);
    if (indexed) {
        if (auto r = layer.find("rows"); r != layer.end() && r->is_array())
            for (const Json& row : *r) base.rows.push_back(row.is_string() ? row.get<std::string>() : std::string());
        base.empty = base.rows.empty();
    } else {
        base.source = layer.value("source", std::string());
        base.empty = base.source.empty();
    }
    t[0] = base;
    std::vector<const Json*> byFrame(std::size_t(frames), nullptr);
    if (auto c = layer.find("cels"); c != layer.end() && c->is_array())
        for (const Json& cel : *c) {
            const int f = cel.is_object() ? json_int(cel, "frame", -1) : -1;
            if (f >= 1 && f < frames) byFrame[std::size_t(f)] = &cel;
        }
    for (int f = 1; f < frames; ++f) {
        t[std::size_t(f)] = t[std::size_t(f - 1)];
        const Json* cel = byFrame[std::size_t(f)];
        if (!cel) continue;
        CelData& c = t[std::size_t(f)];
        if (auto link = cel->find("link"); link != cel->end()) {
            const int g = link->is_number_integer() ? link->get<int>() : -1;
            if (g >= 0 && g < f) c = t[std::size_t(g)];
        } else if (cel->contains("empty") && (*cel)["empty"] == true) {
            c.empty = true;
        } else if (indexed ? cel->contains("rows") : cel->contains("source")) {
            c = CelData();
            if (indexed) {
                const Json& rows = (*cel)["rows"];
                if (rows.is_array())
                    for (const Json& row : rows) c.rows.push_back(row.is_string() ? row.get<std::string>() : std::string());
                c.empty = c.rows.empty();
            } else {
                c.source = cel->value("source", std::string());
                c.empty = c.source.empty();
            }
            c.x = json_int(*cel, "x", base.x);
            c.y = json_int(*cel, "y", base.y);
            if (auto o = cel->find("opacity"); o != cel->end() && o->is_number()) c.opacity = float(o->get<double>());
        }
    }
    return t;
}

void write_layer_cels(Json& layer, const std::vector<CelData>& t, const std::string& projectDir) {
    const bool indexed = layer.value("kind", std::string()) == "indexed";
    const CelData& b = t.at(0);
    if (indexed) {
        if (b.empty || b.rows.empty()) layer.erase("rows");
        else layer["rows"] = b.rows;
    } else {
        if (b.empty || b.source.empty()) layer.erase("source");
        else layer["source"] = b.source;
    }
    set_or_erase(layer, "x", b.x);
    set_or_erase(layer, "y", b.y);
    Json cels = Json::array();
    for (std::size_t f = 1; f < t.size(); ++f) {
        const CelData& c = t[f];
        if (c.same(t[f - 1], projectDir)) continue;
        Json cel = Json::object({{"frame", int(f)}});
        if (c.empty) {
            cel["empty"] = true;
            cels.push_back(cel);
            continue;
        }
        int link = -1;
        for (int g = int(f) - 2; g >= 0; --g)
            if (!t[std::size_t(g)].empty && c.same(t[std::size_t(g)], projectDir)) {
                link = g;
                break;
            }
        if (link >= 0) {
            cel["link"] = link;
        } else {
            if (indexed) cel["rows"] = c.rows;
            else cel["source"] = c.source;
            if (c.x != b.x) cel["x"] = c.x;
            if (c.y != b.y) cel["y"] = c.y;
            if (c.opacity != 1.0f) cel["opacity"] = c.opacity;
        }
        cels.push_back(cel);
    }
    layer.erase("cels");
    if (!cels.empty() || (!indexed && (b.empty || b.source.empty()))) layer["cels"] = cels;
}

std::vector<TimelineLayer> load_timeline(const Json& doc) {
    std::vector<TimelineLayer> out;
    if (doc.contains("layers")) collect_timeline(doc["layers"], "", json_frame_count(doc), out);
    return out;
}

void store_timeline(Json& doc, const std::vector<TimelineLayer>& layers, const std::string& projectDir) {
    for (const TimelineLayer& t : layers) {
        Json& l = doc.at(Json::json_pointer(t.pointer));
        write_layer_cels(l, t.frames, projectDir);
    }
}

void normalize_animation(Json& doc) {
    const int count = json_frame_count(doc);
    const bool hasTags = doc.contains("tags") && doc["tags"].is_array() && !doc["tags"].empty();
    if (doc.contains("tags") && !hasTags) doc.erase("tags");
    if (count <= 1 && !hasTags && !doc.contains("sheet")) doc.erase("frames");
}

int frame_number(const char* command, const Json& value, const std::string& pointer, int count, const char* what) {
    if (!value.is_number_integer())
        arg_error(command, pointer, std::format("`{}` must be a whole frame number, got {}.", what, describe_json_value(value)),
                  count > 1 ? std::format("Frames count from 0: this document has {} (0 to {}).", count, count - 1)
                            : "This document has one frame (0); add more with image.frame.add.");
    const long long v = value.get<long long>();
    if (v < 0 || v >= count)
        arg_error(command, pointer, std::format("there is no frame {}: the document has {} frame{} ({}).", v, count, count == 1 ? "" : "s", count == 1 ? std::string("only frame 0") : std::format("0 to {}", count - 1)),
                  count == 1 ? "Make it an animation with image.frame.add, or leave `frame` out." : "Frames count from 0; image.info lists them.");
    return int(v);
}

// ---- FrameScope -----------------------------------------------------------------------------------------------------------

namespace {

ImageOnionSkin onion_arg(const char* command, const Json& v) {
    ImageOnionSkin o;
    if (v.is_boolean()) return o;
    if (!v.is_object())
        arg_error(command, "/onion", "`onion` is true, or an object like {\"before\":2,\"after\":1,\"opacity\":0.4}, got " + describe_json_value(v) + ".",
                  "It draws the neighbouring frames, tinted, under the frame in the picture the command returns.");
    assets_detail::check_arg_keys(command, v, "/onion", {"before", "after", "opacity", "beforeColor", "afterColor", "loop"});
    auto count = [&](const char* key, int& out) {
        auto it = v.find(key);
        if (it == v.end()) return;
        if (!it->is_number_integer() || it->get<int>() < 0 || it->get<int>() > 8)
            arg_error(command, std::string("/onion/") + key, std::string("`") + key + "` is how many frames to show, a whole number from 0 to 8, got " + describe_json_value(*it) + ".", "Example: 1.");
        out = it->get<int>();
    };
    count("before", o.before);
    count("after", o.after);
    if (auto it = v.find("opacity"); it != v.end()) {
        if (!it->is_number() || it->get<double>() < 0 || it->get<double>() > 1)
            arg_error(command, "/onion/opacity", "`opacity` is a number from 0 to 1, got " + describe_json_value(*it) + ".", "The nearest ghost frame; the next ones are 1/2, 1/3 as strong. Default 0.4.");
        o.opacity = float(it->get<double>());
    }
    if (v.contains("beforeColor")) o.beforeColor = assets_detail::colour_arg(command, v["beforeColor"], "/onion/beforeColor");
    if (v.contains("afterColor")) o.afterColor = assets_detail::colour_arg(command, v["afterColor"], "/onion/afterColor");
    if (auto it = v.find("loop"); it != v.end()) {
        if (!it->is_boolean()) arg_error(command, "/onion/loop", "`loop` is true or false, got " + describe_json_value(*it) + ".", "true makes the frame before 0 the last one.");
        o.loop = it->get<bool>();
    }
    return o;
}

}  // namespace

FrameScope::FrameScope(const std::string& projectDir, const std::string& rel, Json& doc, const Json& args, const char* command)
    : projectDir_(projectDir), rel_(rel), command_(command), doc_(&doc) {
    frames_ = json_frame_count(doc);
    if (auto it = args.find("frame"); it != args.end() && !it->is_null()) frame_ = frame_number(command, *it, "/frame", frames_);
    if (auto it = args.find("onion"); it != args.end() && !it->is_null() && !(it->is_boolean() && !it->get<bool>())) {
        ImageOnionSkin o = onion_arg(command, *it);
        if (frames_ > 1) onion_ = o;
    }
    active_ = json_animated(doc) || frame_ != 0;
    if (active_) {
        previous_ = g_current;
        g_current = this;
    }
}

FrameScope::~FrameScope() {
    if (active_) g_current = previous_;
    for (const Opened& o : opened_) {
        if (o.kept || o.clone.empty()) continue;
        auto p = resolve_project_path(projectDir_, o.clone);
        std::error_code ec;
        if (p.ok()) stdfs::remove(*p, ec);
    }
}

FrameScope* FrameScope::current() { return g_current; }

void FrameScope::open_layer(const Json& doc, const LayerRef& ref) {
    if (!active_ || &doc != doc_) return;
    const std::string kind = ref.layer->value("kind", std::string());
    if (kind != "pixels" && kind != "indexed") return;
    for (const Opened& o : opened_)
        if (o.pointer == ref.pointer) return;
    Opened o;
    o.pointer = ref.pointer;
    o.indexed = kind == "indexed";
    o.original = layer_cels(*ref.layer, frames_);
    const CelData cel = o.original[std::size_t(frame_)];
    Json& L = *ref.layer;
    L.erase("cels");
    if (o.indexed) {
        if (cel.empty || cel.rows.empty()) L.erase("rows");
        else L["rows"] = cel.rows;
        set_or_erase(L, "x", cel.x);
        set_or_erase(L, "y", cel.y);
    } else {
        const int W = doc.value("width", 1), H = doc.value("height", 1);
        const std::string name = L.value("name", std::string()).empty() ? std::string("layer") : L.value("name", std::string());
        o.clone = layer_png_path(projectDir_, rel_, name + " frame " + std::to_string(frame_), doc);
        auto dest = resolve_project_path(projectDir_, o.clone);
        if (!dest.ok()) fail("invalid_argument", dest.error().message, dest.error().hint);
        std::string err;
        if (cel.empty || cel.source.empty()) {
            Image blank;
            blank.width = std::max(1, W);
            blank.height = std::max(1, H);
            blank.rgba.assign(std::size_t(blank.width) * blank.height * 4, 0);
            const auto png = encode_png(blank);
            if (!tooling_detail::write_file(*dest, std::string_view(reinterpret_cast<const char*>(png.data()), png.size()), &err))
                fail("failed", "Cannot write '" + o.clone + "': " + err, "Check that the folder is writable.");
            L["source"] = o.clone;
            L.erase("x");
            L.erase("y");
        } else {
            auto from = resolve_project_path(projectDir_, cel.source);
            auto bytes = from.ok() ? tooling_detail::read_file(*from) : std::nullopt;
            if (!bytes) fail("failed", "Layer " + ref.indexPath + " shows '" + cel.source + "' in frame " + std::to_string(frame_) + ", which cannot be read.", "Check the file, or replace the cel's `source`.");
            if (!tooling_detail::write_file(*dest, *bytes, &err)) fail("failed", "Cannot write '" + o.clone + "': " + err, "Check that the folder is writable.");
            L["source"] = o.clone;
            set_or_erase(L, "x", cel.x);
            set_or_erase(L, "y", cel.y);
        }
    }
    opened_.push_back(std::move(o));
}

Json FrameScope::folded(const Json& doc) {
    Json out = doc;
    for (Opened& o : opened_) {
        Json* found = nullptr;
        try {
            found = &out.at(Json::json_pointer(o.pointer));
        } catch (const std::exception&) {
            continue;   // the layer is gone
        }
        Json& L = *found;
        const std::string kind = L.value("kind", std::string());
        if (kind != (o.indexed ? "indexed" : "pixels")) continue;   // the command turned it into something else: it keeps what it made
        const CelData& was = o.original[std::size_t(frame_)];
        CelData now;
        now.x = json_int(L, "x", 0);
        now.y = json_int(L, "y", 0);
        now.opacity = was.opacity;
        bool unchanged = false;
        if (o.indexed) {
            if (auto r = L.find("rows"); r != L.end() && r->is_array())
                for (const Json& row : *r) now.rows.push_back(row.is_string() ? row.get<std::string>() : std::string());
            now.empty = now.rows.empty();
            unchanged = now.same(was, std::string());
        } else {
            now.source = L.value("source", std::string());
            const auto img = read_png_rel(projectDir_, now.source);
            const Trimmed t = img ? trimmed(*img, now.x, now.y) : Trimmed();
            now.empty = t.empty;
            if (was.empty || was.source.empty()) {
                unchanged = t.empty;
            } else {
                const auto old = read_png_rel(projectDir_, was.source);
                const Trimmed ot = old ? trimmed(*old, was.x, was.y) : Trimmed();
                unchanged = !t.empty && !ot.empty && t.x == ot.x && t.y == ot.y && t.img.width == ot.img.width && t.img.height == ot.img.height && t.img.rgba == ot.img.rgba;
            }
        }
        std::vector<CelData> table = o.original;
        if (unchanged) {
            if (!o.indexed) {
                // the layer's own place did not change either: keep the original cel (and its file)
            }
        } else {
            table[std::size_t(frame_)] = now;
            o.kept = true;
        }
        write_layer_cels(L, table, projectDir_);
    }
    return out;
}

void FrameScope::record_files(const std::string& command) {
    assets_detail::ProjectRootGuard root(projectDir_);
    for (const Opened& o : opened_) {
        if (!o.kept || o.clone.empty()) continue;
        Json prov = Json::object({{"origin", "generated"}, {"ai", false}, {"kind", "image"}, {"provider", "factoria " + command}, {"source", rel_}, {"date", assets::today()}});
        (void)assets::update_entry(o.clone, [&](Json& e) { e["provenance"] = prov; });
    }
}

// ---- schema pieces and previews -------------------------------------------------------------------------------------------

void add_frame_support(CommandInfo& info, const char* what, bool withOnion) {
    Json props = Json::object(
        {{"frame", Json::object({{"type", "integer"}, {"minimum", 0},
                                 {"description", std::string("Which frame of an animated document ") + what + " (0 = the first; default 0). A document with one frame has only frame 0. "
                                                 "In a frame after the first the layer's cel is copied on write: the other frames keep what they show."}})},
         {"onion", Json::object({{"description", "Preview only: ghost the neighbouring frames, tinted, under the frame in the returned picture. true, or {\"before\":1,\"after\":1,\"opacity\":0.4,"
                                                 "\"beforeColor\":\"#ff4040\",\"afterColor\":\"#4080ff\",\"loop\":false}. Frames before are tinted red, frames after blue; "
                                                 "the second frame away is half as strong, the third a third. Does not change the document or the bake."}})}});
    if (!info.inputSchema.is_object()) info.inputSchema = Json::object();
    if (!info.inputSchema.contains("properties")) info.inputSchema["properties"] = Json::object();
    if (!withOnion) props.erase("onion");
    for (auto it = props.begin(); it != props.end(); ++it) info.inputSchema["properties"][it.key()] = it.value();
    info.description += std::string(" Frames: in an animated document (docs.read IMAGES, \"Frames and tags\") `frame` (default 0) is the frame ") + what +
                        (withOnion ? ": the layer's cel for that frame is changed and the other frames keep what they show; `onion` ghosts the neighbouring frames in the returned picture."
                                   : ": the picture of that frame is written.");
}

void add_frame_keys(std::vector<std::string>& keys) {
    keys.push_back("frame");
    keys.push_back("onion");
}

std::optional<Image> render_frame_json(const std::string& projectDir, const Json& doc, int frame, const std::optional<ImageOnionSkin>& onion) {
    auto parsed = parse_image_document(doc, "document", projectDir);
    if (!parsed.ok()) return std::nullopt;
    ImageRenderOptions options;
    options.projectDir = projectDir;
    options.frame = frame;
    options.onion = onion;
    auto render = composite_image_document(*parsed, options);
    if (!render.ok()) return std::nullopt;
    return std::move(render->image);
}

Json frame_preview(const std::string& projectDir, const std::string& rel, const Json& doc, int frame, const std::optional<ImageOnionSkin>& onion, int scale) {
    auto picture = render_frame_json(projectDir, doc, frame, onion);
    if (!picture) return Json();
    if (scale <= 0) scale = std::clamp(512 / std::max(1, std::max(picture->width, picture->height)), 1, 32);
    if (std::size_t(picture->width) * scale > 4096 || std::size_t(picture->height) * scale > 4096) scale = std::max(1, 4096 / std::max(picture->width, picture->height));
    Image big;
    big.width = picture->width * scale;
    big.height = picture->height * scale;
    big.rgba.resize(std::size_t(big.width) * big.height * 4);
    for (int y = 0; y < big.height; ++y)
        for (int x = 0; x < big.width; ++x)
            std::copy_n(&picture->rgba[(std::size_t(y / scale) * picture->width + x / scale) * 4], 4, &big.rgba[(std::size_t(y) * big.width + x) * 4]);
    const std::string previewRel = ".factoria/previews/" + rel + ".png";
    auto path = resolve_project_path(projectDir, previewRel);
    if (!path.ok()) return Json();
    const auto png = encode_png(big);
    if (!tooling_detail::write_file(*path, std::string_view(reinterpret_cast<const char*>(png.data()), png.size()), nullptr)) return Json();
    return Json::object({{"path", path->string()}, {"mimeType", "image/png"}});
}

}  // namespace fa::imgedit
