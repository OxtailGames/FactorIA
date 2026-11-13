// Shared by the image.* editing commands: opening a document, finding layers by name or index path, selections stored in
// the project, the pixels of a layer to edit, and the result of a command.
#include <algorithm>
#include <cmath>
#include <format>

#include "fa/core/asset_manifest.h"
#include "fa/core/strings.h"
#include "fa/tooling/project_fs.h"
#include "image_doc_internal.h"
#include "image_edit.h"
#include "image_frames.h"
#include "util.h"

namespace fa::imgedit {

namespace {

bool is_index_path(const std::string& s) {
    if (s.empty()) return false;
    bool digit = false;
    for (char c : s) {
        if (c >= '0' && c <= '9')
            digit = true;
        else if (c == '/' && digit)
            digit = false;
        else
            return false;
    }
    return digit;
}

struct Entry {
    Json* layer;
    Json* list;
    int index;
    std::vector<int> path;
    Json* parent;
    int px, py;
};

int int_or(const Json& j, const char* key, int def) {
    auto it = j.find(key);
    return it != j.end() && it->is_number() ? int(std::lround(it->get<double>())) : def;
}

void collect(Json& list, Json* parent, std::vector<int>& path, int px, int py, std::vector<Entry>& out) {
    if (!list.is_array()) return;
    for (std::size_t i = 0; i < list.size(); ++i) {
        Json& layer = list[i];
        if (!layer.is_object()) continue;
        path.push_back(int(i));
        out.push_back({&layer, &list, int(i), path, parent, px, py});
        auto kids = layer.find("layers");
        if (kids != layer.end() && kids->is_array())
            collect(*kids, &layer, path, px + int_or(layer, "x", 0), py + int_or(layer, "y", 0), out);
        path.pop_back();
    }
}

std::string pointer_of(const std::vector<int>& path) {
    std::string p;
    for (std::size_t i = 0; i < path.size(); ++i) p += "/layers/" + std::to_string(path[i]);
    return p;
}

std::string layer_label(const Entry& e) {
    const std::string name = e.layer->value("name", std::string());
    return index_path_string(e.path) + (name.empty() ? "" : " " + name) + " (" +
           e.layer->value("kind", std::string("?")) + ")";
}

LayerRef to_ref(const Entry& e) {
    LayerRef r;
    r.layer = e.layer;
    r.list = e.list;
    r.index = e.index;
    r.path = e.path;
    r.indexPath = index_path_string(e.path);
    r.pointer = pointer_of(e.path);
    r.parentX = e.px;
    r.parentY = e.py;
    r.parent = e.parent;
    return r;
}

}  // namespace

std::string index_path_string(const std::vector<int>& path) {
    std::string s;
    for (std::size_t i = 0; i < path.size(); ++i) s += (i ? "/" : "") + std::to_string(path[i]);
    return s;
}

std::string describe_layers(const Json& docIn, std::size_t max) {
    Json& doc = const_cast<Json&>(docIn);
    std::vector<Entry> all;
    std::vector<int> path;
    if (doc.contains("layers")) collect(doc["layers"], nullptr, path, 0, 0, all);
    if (all.empty()) return "the document has no layers";
    std::vector<std::string> parts;
    for (std::size_t i = 0; i < all.size() && i < max; ++i) parts.push_back(layer_label(all[i]));
    std::string s = "layers: " + join(parts, ", ");
    if (all.size() > max) s += ", ... (" + std::to_string(all.size() - max) + " more)";
    return s;
}

std::vector<std::string> layer_names(const Json& docIn) {
    Json& doc = const_cast<Json&>(docIn);
    std::vector<Entry> all;
    std::vector<int> path;
    if (doc.contains("layers")) collect(doc["layers"], nullptr, path, 0, 0, all);
    std::vector<std::string> names;
    for (const Entry& e : all) {
        const std::string n = e.layer->value("name", std::string());
        if (!n.empty() && std::find(names.begin(), names.end(), n) == names.end()) names.push_back(n);
    }
    return names;
}

std::string unique_layer_name(const Json& doc, const std::string& base) {
    const auto names = layer_names(doc);
    auto taken = [&](const std::string& n) { return std::find(names.begin(), names.end(), n) != names.end(); };
    if (!taken(base)) return base;
    for (int i = 2;; ++i) {
        const std::string n = base + " " + std::to_string(i);
        if (!taken(n)) return n;
    }
}

static bool find_impl(Json& doc, const Json& ref, const char* command, const std::string& argName, LayerRef& out,
                      bool must) {
    std::vector<Entry> all;
    std::vector<int> path;
    if (doc.contains("layers")) collect(doc["layers"], nullptr, path, 0, 0, all);
    std::string text;
    if (ref.is_number_integer())
        text = std::to_string(ref.get<long long>());
    else if (ref.is_string())
        text = ref.get<std::string>();
    else
        assets_detail::arg_error(command, "/" + argName,
                                 "expected a layer name or an index path such as \"1/0\", got " +
                                     describe_json_value(ref) + ".",
                                 describe_layers(doc));
    // 1. an exact name
    std::vector<const Entry*> named;
    for (const Entry& e : all)
        if (e.layer->value("name", std::string()) == text) named.push_back(&e);
    if (named.size() == 1) {
        out = to_ref(*named[0]);
        return true;
    }
    if (named.size() > 1) {
        std::vector<std::string> where;
        for (const Entry* e : named) where.push_back("\"" + index_path_string(e->path) + "\"");
        assets_detail::arg_error(command, "/" + argName, "several layers are named '" + text + "'.",
                                 "Address one by its index path: " + join(where, ", ") +
                                     ". (Give layers distinct names with image.layer.set.)");
    }
    // 2. an index path
    if (is_index_path(text)) {
        for (const Entry& e : all)
            if (index_path_string(e.path) == text) {
                out = to_ref(e);
                return true;
            }
        std::string why;
        const auto parts = split(text, '/');
        Json* list = doc.contains("layers") ? &doc["layers"] : nullptr;
        std::string walked;
        for (std::size_t i = 0; i < parts.size() && why.empty(); ++i) {
            const std::size_t n = list && list->is_array() ? list->size() : 0;
            const std::size_t idx = std::stoul(parts[i]);
            if (idx >= n) {
                why = (i == 0 ? std::string("the document has ") : "the group '" + walked + "' has ") +
                      std::to_string(n) + (n == 1 ? " layer" : " layers") +
                      (n ? " (indexes 0.." + std::to_string(n - 1) + ")" : "");
            } else {
                walked += (walked.empty() ? "" : "/") + parts[i];
                Json& l = (*list)[idx];
                if (i + 1 < parts.size()) {
                    auto kids = l.find("layers");
                    if (kids == l.end() || !kids->is_array()) {
                        why = "layer '" + walked + "' is not a group, so it has no children";
                        break;
                    }
                    list = &*kids;
                }
            }
        }
        assets_detail::arg_error(command, "/" + argName, "there is no layer at index path '" + text + "': " + why + ".",
                                 describe_layers(doc));
    }
    // 3. nothing
    if (!must) return false;
    const auto names = layer_names(doc);
    std::string hint = names.empty() ? std::string() : did_you_mean(text, names) + " ";
    assets_detail::arg_error(command, "/" + argName, "there is no layer named '" + text + "'.",
                             hint + describe_layers(doc));
}

bool try_find_layer(Json& doc, const Json& ref, const char* command, const std::string& argName, LayerRef& out) {
    const bool found = find_impl(doc, ref, command, argName, out, false);
    if (found)
        if (FrameScope* fs = FrameScope::current())
            fs->open_layer(doc, out);  // the layer as it is in the frame the command works on
    return found;
}

LayerRef find_layer(Json& doc, const Json& ref, const char* command, const std::string& argName) {
    LayerRef r;
    find_impl(doc, ref, command, argName, r, true);
    if (FrameScope* fs = FrameScope::current()) fs->open_layer(doc, r);
    return r;
}

// ---- documents ----------------------------------------------------------------------------------------------------

std::string doc_path_arg(const std::string& relArg, const char* command, const char* key) {
    auto norm = fs::normalize_checked(relArg);
    if (!norm.ok() || norm->empty())
        assets_detail::arg_error(command, std::string("/") + key, "'" + relArg + "' is not a path inside the project.",
                                 "Use a project-relative path such as \"assets/art/hero.image.json\".");
    if (!ends_with(*norm, kImageDocSuffix))
        assets_detail::arg_error(
            command, std::string("/") + key, "'" + *norm + "' is not an image document.",
            "A layered image's file name ends in .image.json, for example \"assets/art/hero.image.json\".");
    return *norm;
}

void check_write_target(const std::string& projectDir, const std::string& rel, const char* command, const char* key) {
    auto path = fs::resolve_for_write_in(fs::path_from_utf8(projectDir), fs::WriteRoot::Project, rel,
                                         /*allowAnywhere=*/false, fs::ManagedFolders::Refuse);
    if (!path.ok())
        assets_detail::arg_error(
            command, std::string("/") + key, "'" + rel + "' cannot be written: " + path.error().message,
            path.error().hint.empty() ? "Use a path inside the project that is not in .git or .factoria."
                                      : path.error().hint);
}

void mark_image_paths(CommandInfo& info, bool writes) {
    if (!info.inputSchema.is_object() || !info.inputSchema.contains("properties") ||
        !info.inputSchema["properties"].is_object())
        return;
    Json& props = info.inputSchema["properties"];
    auto mark = [&](const char* name, const char* kind) {
        auto it = props.find(name);
        if (it != props.end() && it->is_object()) (*it)["x-fa-path"] = kind;
    };
    mark("path", writes ? "write" : "read");
    for (const char* name : {"out", "output", "rules"}) mark(name, "write");
    mark("png", "read");
}

void add_image_command(CommandRegistry& registry, CommandInfo info, CommandHandler handler, bool savesDocument) {
    mark_image_paths(info, !info.readOnly && savesDocument);
    const std::string name = info.name;
    const bool readOnly = info.readOnly;
    registry.add(std::move(info), std::move(handler));
    registry.declare_capabilities(name, readOnly ? capability_sets::reads() : capability_sets::writes_project());
}

DocFile open_doc(const std::string& projectDir, const std::string& relArg, const char* command, bool forWrite) {
    DocFile d;
    d.rel = doc_path_arg(relArg, command);
    if (forWrite) check_write_target(projectDir, d.rel, command, "path");
    auto path = resolve_project_path(projectDir, d.rel);
    if (!path.ok()) fail("invalid_argument", path.error().message, path.error().hint);
    std::error_code ec;
    if (!stdfs::is_regular_file(*path, ec))
        fail("not_found", "The image document '" + d.rel + "' does not exist.",
             "Make one with image.create {\"path\":\"" + d.rel + "\",\"width\":64,\"height\":64}.");
    auto text = tooling_detail::read_file(*path);
    if (!text) fail("failed", "Cannot read '" + d.rel + "'.", "Check the file's permissions.");
    auto json = parse_json(*text, d.rel);
    if (!json.ok()) fail("invalid_argument", json.error().message, json.error().hint);
    if (!json->is_object())
        fail("invalid_argument", "'" + d.rel + "' is not an image document (the top level must be an object).",
             "Docs: docs.read IMAGES.");
    d.json = std::move(*json);
    if (!d.json.contains("layers") || !d.json["layers"].is_array()) d.json["layers"] = Json::array();
    return d;
}

// ---- results ------------------------------------------------------------------------------------------------------

Region changed_region(const Image& a, const Image& b) {
    if (a.width != b.width || a.height != b.height) return {0, 0, b.width, b.height};
    int x0 = b.width, y0 = b.height, x1 = -1, y1 = -1;
    for (int y = 0; y < b.height; ++y) {
        const std::uint8_t* pa = &a.rgba[std::size_t(y) * a.width * 4];
        const std::uint8_t* pb = &b.rgba[std::size_t(y) * b.width * 4];
        for (int x = 0; x < b.width; ++x) {
            const bool bothClear = pa[x * 4 + 3] == 0 && pb[x * 4 + 3] == 0;
            if (!bothClear && !std::equal(pa + x * 4, pa + x * 4 + 4, pb + x * 4)) {
                x0 = std::min(x0, x);
                x1 = std::max(x1, x);
                y0 = std::min(y0, y);
                y1 = std::max(y1, y);
            }
        }
    }
    if (x1 < 0) return {};
    return {x0, y0, x1 - x0 + 1, y1 - y0 + 1};
}

Json bake_result_json(const std::string& projectDir, const ImageBakeResult& r) {
    Json out = Json::object({{"document", r.document},
                             {"path", r.output},
                             {"width", r.width},
                             {"height", r.height},
                             {"written", r.written},
                             {"ai", r.ai}});
    if (!r.sha256.empty()) out["sha256"] = r.sha256;
    if (!r.inputs.empty()) out["inputs"] = r.inputs;
    if (!r.provenance.is_null()) out["provenance"] = r.provenance;
    if (!r.warnings.empty()) out["warnings"] = r.warnings;
    if (r.sheet.is_object()) out["sheet"] = r.sheet;
    auto png = resolve_project_path(projectDir, r.output);
    std::error_code ec;
    if (png.ok() && stdfs::is_regular_file(*png, ec))
        out["$image"] = Json::object({{"path", png->string()}, {"mimeType", "image/png"}});
    if (r.sheet.is_object()) {
        std::vector<std::string> steps = assets_detail::sheet_next_steps(r.output, r.sheet, 10);
        steps.insert(steps.begin(),
                     "The PNG is a sprite sheet of the document's frames and tags. To change a frame, edit it "
                     "(image.pixel, image.draw, image.edit, image.paint with `frame`) and call image.bake again.");
        out["nextSteps"] = steps;
    } else {
        out["nextSteps"] = Json::array({"Look at the picture in this result. To change it, edit the layers of '" +
                                            r.document + "' and call image.bake again.",
                                        "Use it as a Sprite texture: Sprite.texture \"" + r.output + "\"."});
    }
    return out;
}

std::optional<Image> read_png_file(const std::string& projectDir, const std::string& rel) {
    auto path = resolve_project_path(projectDir, rel);
    if (!path.ok()) return std::nullopt;
    auto bytes = tooling_detail::read_file(*path);
    if (!bytes) return std::nullopt;
    auto img = decode_image(reinterpret_cast<const std::uint8_t*>(bytes->data()), bytes->size());
    if (!img.ok()) return std::nullopt;
    return std::move(*img);
}

void write_png_file(const std::string& projectDir, const std::string& rel, const Image& img) {
    auto path = resolve_project_path(projectDir, rel);
    if (!path.ok()) fail("invalid_argument", path.error().message, path.error().hint);
    const auto png = encode_png(img);
    std::string err;
    if (!tooling_detail::write_file(*path, std::string_view(reinterpret_cast<const char*>(png.data()), png.size()),
                                    &err))
        fail("failed", "Cannot write '" + rel + "': " + err, "Check that the folder is writable.");
}

std::optional<Image> render_document_json(const std::string& projectDir, const Json& doc) {
    const FrameScope* fs = FrameScope::current();
    return render_frame_json(projectDir, doc, fs ? fs->frame() : 0);
}

std::optional<Image> render_preview_json(const std::string& projectDir, const Json& doc) {
    const FrameScope* fs = FrameScope::current();
    return render_frame_json(projectDir, doc, fs ? fs->frame() : 0, fs ? fs->onion() : std::nullopt);
}

Json commit_document(const std::string& projectDir, const std::string& rel, const Json& docIn,
                     const std::optional<Image>& before, bool bake, Json extra,
                     const std::vector<std::string>& warnings, const char* command) {
    FrameScope* fs = FrameScope::current();
    // in a frame, the layers the command opened are folded back into their cels first
    const Json doc = fs ? fs->folded(docIn) : docIn;
    Json oldDoc;  // the document as it was on disk, for the pictures nothing reads any more
    if (auto oldPath = resolve_project_path(projectDir, rel); oldPath.ok())
        if (auto text = tooling_detail::read_file(*oldPath)) oldDoc = Json::parse(*text, nullptr, false);
    auto r = save_image_document(projectDir, rel, doc, bake);
    if (!r.ok()) fail("invalid_argument", r.error().message, r.error().hint);
    if (fs) fs->record_files(command);
    const std::vector<std::string> pruned =
        oldDoc.is_object() ? prune_orphan_cels(projectDir, rel, oldDoc, doc) : std::vector<std::string>();
    Json out = bake_result_json(projectDir, *r);
    if (!pruned.empty()) out["removedFiles"] = pruned;
    // the picture of the frame (the bake of an animated document is the whole sheet)
    const bool animated = r->sheet.is_object();
    std::optional<Image> after;
    if (animated || fs)
        after = render_frame_json(projectDir, doc, fs ? fs->frame() : 0);
    else if (bake)
        after = read_png_file(projectDir, r->output);
    else
        after = render_document_json(projectDir, doc);
    if (!bake) out.erase("$image");
    if (fs && fs->frames() > 1) {
        out["frame"] = fs->frame();
        out["frames"] = fs->frames();
        if (bake)
            if (Json shown = frame_preview(projectDir, rel, doc, fs->frame(), fs->onion(), 1); shown.is_object()) {
                out["$image"] = shown;
                out["preview"] = ".factoria/previews/" + rel + ".png";
            }
    }
    Region region;
    if (after)
        region = before ? changed_region(*before, *after) : Region{0, 0, after->width, after->height};
    else
        region = {0, 0, r->width, r->height};
    out["region"] = region.to_json();
    out["changed"] = !region.empty();
    if (!bake)
        out["note"] = "The document was written but not baked (bake: false): call image.bake to see the picture.";
    for (auto it = extra.begin(); it != extra.end(); ++it) out[it.key()] = it.value();
    if (!warnings.empty()) {
        Json w = out.contains("warnings") ? out["warnings"] : Json::array();
        for (const std::string& s : warnings) w.push_back(s);
        out["warnings"] = w;
    }
    return out;
}

Image render_layer_alone(const std::string& projectDir, const Json& layerJson, int width, int height, int offX,
                         int offY, std::vector<std::string>* warnings, const Json* docJson) {
    Json layer = layerJson;
    if (layer.contains("cels")) {
        // outside a frame (FrameScope) a layer is what it shows in frame 0; a document of one frame has no cels
        layer.erase("cels");
        if (layer.value("kind", std::string()) == "pixels" && !layer.contains("source")) {
            Image blank;
            blank.width = width;
            blank.height = height;
            blank.rgba.assign(std::size_t(width) * height * 4, 0);
            return blank;
        }
    }
    for (const char* k : {"visible", "opacity", "blend", "clip"}) layer.erase(k);
    layer["x"] = int_or(layerJson, "x", 0) + offX;
    layer["y"] = int_or(layerJson, "y", 0) + offY;
    Json doc = Json::object(
        {{"format", kImageDocFormat}, {"width", width}, {"height", height}, {"layers", Json::array({layer})}});
    if (docJson)
        for (const char* k : {"palette", "ramps"})
            if (docJson->contains(k)) doc[k] = (*docJson)[k];
    auto parsed = parse_image_document(doc, "layer", projectDir);
    if (!parsed.ok()) fail("invalid_argument", parsed.error().message, parsed.error().hint);
    auto render = composite_image_document(*parsed, {projectDir});
    if (!render.ok()) fail("failed", render.error().message, render.error().hint);
    if (warnings)
        for (const std::string& w : render->warnings) warnings->push_back(w);
    return std::move(render->image);
}

// ---- masks ---------------------------------------------------------------------------------------------------------

std::size_t Mask::count(int threshold) const {
    std::size_t n = 0;
    for (std::uint8_t c : v) n += c >= threshold ? 1 : 0;
    return n;
}

Region Mask::bounds() const {
    int x0 = w, y0 = h, x1 = -1, y1 = -1;
    for (int y = 0; y < h; ++y)
        for (int x = 0; x < w; ++x)
            if (v[std::size_t(y) * w + x]) {
                x0 = std::min(x0, x);
                x1 = std::max(x1, x);
                y0 = std::min(y0, y);
                y1 = std::max(y1, y);
            }
    if (x1 < 0) return {};
    return {x0, y0, x1 - x0 + 1, y1 - y0 + 1};
}

void mask_combine(Mask& base, const Mask& other, CombineMode mode) {
    if (mode == CombineMode::Replace) {
        base = other;
        return;
    }
    for (std::size_t i = 0; i < base.v.size(); ++i) {
        const int a = base.v[i], b = other.v[i];
        switch (mode) {
            case CombineMode::Add: base.v[i] = std::uint8_t(std::max(a, b)); break;
            case CombineMode::Subtract: base.v[i] = std::uint8_t((a * (255 - b) + 127) / 255); break;
            case CombineMode::Intersect: base.v[i] = std::uint8_t(std::min(a, b)); break;
            default: break;
        }
    }
}

void mask_invert(Mask& m) {
    for (std::uint8_t& c : m.v) c = std::uint8_t(255 - c);
}

namespace {

// Squared Euclidean distance transform (Felzenszwalb and Huttenlocher): d[i] = min over q of (i-q)^2 + f[q].
void edt_1d(const std::vector<double>& f, std::vector<double>& d, std::vector<int>& v, std::vector<double>& z) {
    const int n = int(f.size());
    int k = 0;
    v[0] = 0;
    z[0] = -1e30;
    z[1] = 1e30;
    for (int q = 1; q < n; ++q) {
        auto cross = [&](int a, int b) {
            return ((f[b] + double(b) * b) - (f[a] + double(a) * a)) / (2.0 * b - 2.0 * a);
        };
        double s = cross(v[k], q);
        while (s <= z[k]) {
            --k;
            s = cross(v[k], q);
        }
        ++k;
        v[k] = q;
        z[k] = s;
        z[k + 1] = 1e30;
    }
    k = 0;
    for (int q = 0; q < n; ++q) {
        while (z[k + 1] < double(q)) ++k;
        d[q] = double(q - v[k]) * double(q - v[k]) + f[v[k]];
    }
}

// The squared distance of each pixel to the nearest pixel where `source` is non-zero (very large when there is none).
std::vector<double> distance_squared(int w, int h, const std::vector<std::uint8_t>& source) {
    const double inf = 1e12;
    std::vector<double> g(std::size_t(w) * h);
    for (std::size_t i = 0; i < g.size(); ++i) g[i] = source[i] ? 0.0 : inf;
    const int n = std::max(w, h);
    std::vector<double> f, d, z(n + 2);
    std::vector<int> v(n);
    for (int x = 0; x < w; ++x) {
        f.assign(h, 0);
        d.assign(h, 0);
        for (int y = 0; y < h; ++y) f[y] = g[std::size_t(y) * w + x];
        edt_1d(f, d, v, z);
        for (int y = 0; y < h; ++y) g[std::size_t(y) * w + x] = d[y];
    }
    for (int y = 0; y < h; ++y) {
        f.assign(w, 0);
        d.assign(w, 0);
        for (int x = 0; x < w; ++x) f[x] = g[std::size_t(y) * w + x];
        edt_1d(f, d, v, z);
        for (int x = 0; x < w; ++x) g[std::size_t(y) * w + x] = d[x];
    }
    return g;
}

}  // namespace

void mask_grow(Mask& m, float pixels) {
    if (pixels <= 0 || m.v.empty()) return;
    std::vector<std::uint8_t> sel(m.v.size());
    for (std::size_t i = 0; i < sel.size(); ++i) sel[i] = m.v[i] >= 128;
    const auto d = distance_squared(m.w, m.h, sel);
    for (std::size_t i = 0; i < d.size(); ++i) m.v[i] = d[i] <= double(pixels) * pixels + 1e-3 ? 255 : 0;
}

void mask_shrink(Mask& m, float pixels) {
    if (pixels <= 0 || m.v.empty()) return;
    std::vector<std::uint8_t> out(m.v.size());
    for (std::size_t i = 0; i < out.size(); ++i) out[i] = m.v[i] < 128;
    const auto d = distance_squared(m.w, m.h, out);
    for (std::size_t i = 0; i < d.size(); ++i)
        m.v[i] = (m.v[i] >= 128 && d[i] > double(pixels) * pixels + 1e-3) ? 255 : 0;
}

void mask_feather(Mask& m, float pixels) {
    if (pixels <= 0 || m.v.empty()) return;
    imgdoc::Plane plane(m.w, m.h, 0, 0);
    for (std::size_t i = 0; i < m.v.size(); ++i) plane.v[i] = m.v[i] / 255.0f;
    imgdoc::blur_plane(plane, pixels / 2.0f);
    for (std::size_t i = 0; i < m.v.size(); ++i)
        m.v[i] = std::uint8_t(std::lround(std::clamp(plane.v[i], 0.0f, 1.0f) * 255.0f));
}

// ---- selections on disk ---------------------------------------------------------------------------------------------

bool valid_selection_name(const std::string& name) {
    if (name.empty() || name.size() > 40) return false;
    for (char c : name)
        if (!(std::isalnum(static_cast<unsigned char>(c)) || c == '-' || c == '_')) return false;
    return true;
}

std::string selection_file(const std::string& rel, const std::string& name) {
    return ".factoria/selections/" + rel + "/" + name + ".png";
}

void save_selection(const std::string& projectDir, const std::string& rel, const std::string& name, const Mask& m) {
    Image img;
    img.width = m.w;
    img.height = m.h;
    img.rgba.resize(std::size_t(m.w) * m.h * 4);
    for (std::size_t i = 0; i < m.v.size(); ++i) {
        img.rgba[i * 4] = img.rgba[i * 4 + 1] = img.rgba[i * 4 + 2] = m.v[i];
        img.rgba[i * 4 + 3] = 255;
    }
    write_png_file(projectDir, selection_file(rel, name), img);
}

bool selection_exists(const std::string& projectDir, const std::string& rel, const std::string& name) {
    auto p = resolve_project_path(projectDir, selection_file(rel, name));
    std::error_code ec;
    return p.ok() && stdfs::is_regular_file(*p, ec);
}

std::vector<std::string> list_selections(const std::string& projectDir, const std::string& rel) {
    std::vector<std::string> out;
    auto dir = resolve_project_path(projectDir, ".factoria/selections/" + rel);
    std::error_code ec;
    if (!dir.ok() || !stdfs::is_directory(*dir, ec)) return out;
    for (stdfs::directory_iterator it(*dir, ec), end; !ec && it != end; it.increment(ec)) {
        const std::string f = it->path().filename().string();
        if (ends_with(f, ".png") && !ends_with(f, ".preview.png")) out.push_back(f.substr(0, f.size() - 4));
    }
    std::sort(out.begin(), out.end());
    return out;
}

Mask load_selection(const std::string& projectDir, const std::string& rel, const std::string& name, int canvasW,
                    int canvasH, const char* command) {
    if (name == "all") return Mask(canvasW, canvasH, 255);
    if (!selection_exists(projectDir, rel, name)) {
        const auto names = list_selections(projectDir, rel);
        std::string hint = names.empty()
                               ? "This document has no stored selection yet: make one with image.select {\"path\":\"" +
                                     rel + "\",\"name\":\"" + name + "\",\"by\":\"rect\",...}."
                               : did_you_mean(name, names) + " Selections of this document: " + join(names, ", ") + ".";
        hint += " The name \"all\" selects the whole canvas.";
        assets_detail::arg_error(command, "/selection", "there is no selection named '" + name + "' for '" + rel + "'.",
                                 hint);
    }
    auto img = read_png_file(projectDir, selection_file(rel, name));
    if (!img) fail("failed", "The stored selection '" + name + "' cannot be read.", "Make it again with image.select.");
    if (img->width != canvasW || img->height != canvasH)
        assets_detail::arg_error(
            command, "/selection",
            std::format("the selection '{}' was made for a {}x{} canvas and the document is {}x{} now.", name,
                        img->width, img->height, canvasW, canvasH),
            "Select again with image.select (the old selection is replaced when you reuse the name).");
    Mask m(canvasW, canvasH);
    for (std::size_t i = 0; i < m.v.size(); ++i) m.v[i] = img->rgba[i * 4];
    return m;
}

std::string write_selection_preview(const std::string& projectDir, const std::string& rel, const std::string& name,
                                    const Image& picture, const Mask& m) {
    Image out = picture;
    if (out.width != m.w || out.height != m.h) {
        out = Image();
        out.width = m.w;
        out.height = m.h;
        out.rgba.assign(std::size_t(m.w) * m.h * 4, 0);
    }
    for (int y = 0; y < m.h; ++y)
        for (int x = 0; x < m.w; ++x) {
            std::uint8_t* p = &out.rgba[(std::size_t(y) * m.w + x) * 4];
            const int c = m.at(x, y);
            // outside the selection: a quarter of the picture over a dark checker; the picture is opaque so it can be read
            const int shade = ((x / 4 + y / 4) & 1) ? 40 : 56;
            const float keep = c / 255.0f;
            const float a = p[3] / 255.0f;
            for (int k = 0; k < 3; ++k) {
                const float full = p[k];
                const float dim = full * 0.35f * a + shade * (1 - 0.35f * a);
                p[k] = std::uint8_t(std::lround(full * keep + dim * (1 - keep)));
            }
            p[3] = 255;
            const bool inside = c >= 128;
            const bool edge = inside && (m.at(x - 1, y) < 128 || m.at(x + 1, y) < 128 || m.at(x, y - 1) < 128 ||
                                         m.at(x, y + 1) < 128);
            if (edge) {
                const bool on = ((x + y) / 2) & 1;
                p[0] = on ? 255 : 0;
                p[1] = on ? 255 : 0;
                p[2] = on ? 255 : 0;
            }
        }
    const std::string rel2 = ".factoria/selections/" + rel + "/" + name + ".preview.png";
    write_png_file(projectDir, rel2, out);
    return rel2;
}

// ---- layer pixels ---------------------------------------------------------------------------------------------------

namespace {

std::string layers_dir(const std::string& docRel) {
    return docRel.substr(0, docRel.size() - std::string(kImageDocSuffix).size()) + ".layers/";
}

void collect_sources(const Json& list, std::vector<std::string>& out) {
    if (!list.is_array()) return;
    for (const Json& l : list) {
        if (!l.is_object()) continue;
        if (l.contains("source") && l["source"].is_string())
            out.push_back(fs::normalize(l["source"].get<std::string>()));
        if (l.contains("layers")) collect_sources(l["layers"], out);
    }
}

}  // namespace

std::string layer_png_path(const std::string& projectDir, const std::string& docRel, const std::string& layerName,
                           const Json& doc) {
    std::string slug = tooling_detail::slugify(layerName, '-');
    if (slug.empty()) slug = "layer";
    std::vector<std::string> used;
    if (doc.contains("layers")) collect_sources(doc["layers"], used);
    for (int i = 1;; ++i) {
        const std::string rel = layers_dir(docRel) + slug + (i > 1 ? "-" + std::to_string(i) : "") + ".png";
        auto p = resolve_project_path(projectDir, rel);
        std::error_code ec;
        const bool onDisk = p.ok() && stdfs::exists(*p, ec);
        if (!onDisk && std::find(used.begin(), used.end(), rel) == used.end()) return rel;
    }
}

void write_layer_png(const std::string& projectDir, const std::string& pngRel, const std::string& docRel,
                     const Image& img, const char* command, bool ai) {
    write_png_file(projectDir, pngRel, img);
    assets_detail::ProjectRootGuard root(projectDir);
    Json prov = Json::object({{"origin", "generated"},
                              {"ai", ai},
                              {"kind", "image"},
                              {"provider", std::string("factoria ") + command},
                              {"source", docRel},
                              {"date", assets::today()}});
    (void)assets::update_entry(pngRel, [&](Json& e) { e["provenance"] = prov; });
}

Work open_work(const std::string& projectDir, Json& doc, const LayerRef& ref, const char* command, bool expand,
               bool allowRasterize) {
    Work w;
    const Json& L = *ref.layer;
    w.kind = L.value("kind", std::string());
    const std::string label =
        "layer '" + (L.value("name", std::string()).empty() ? ref.indexPath : L.value("name", std::string())) + "' (" +
        ref.indexPath + ")";
    if (w.kind == "group")
        assets_detail::arg_error(command, "/layer",
                                 label + " is a group, and a group has no pixels of its own to edit.",
                                 "Edit a layer inside it (" + describe_layers(doc, 12) +
                                     "), or select with image.select by:\"layer\" and use a layer of the group.");
    if (w.kind == "indexed")
        assets_detail::arg_error(
            command, "/layer",
            label + " is an indexed pixel-art layer: it is locked to the palette, and this command would blend colours "
                    "that are not in it.",
            "Draw on it with image.pixel and image.draw, or turn it into a pixels layer first: image.layer.convert "
            "{\"layer\":\"" +
                (L.value("name", std::string()).empty() ? ref.indexPath : L.value("name", std::string())) +
                "\",\"to\":\"pixels\"}.");
    if (w.kind == "adjustment")
        assets_detail::arg_error(command, "/layer",
                                 label + " is an adjustment layer: it has no pixels, it changes the layers below it.",
                                 "Change it with image.layer.set (its `adjustments`), or edit a pixels layer.");
    const int W = doc.value("width", 0), H = doc.value("height", 0);
    if (w.kind == "pixels") {
        const std::string src = L.value("source", std::string());
        auto img = read_png_file(projectDir, src);
        if (!img)
            fail("failed", label + " reads '" + src + "', which cannot be read as a PNG.",
                 "Check the file, or replace the layer's `source`.");
        w.img = std::move(*img);
        w.ox = w.originX = ref.parentX + int_or(L, "x", 0);
        w.oy = w.originY = ref.parentY + int_or(L, "y", 0);
        w.fixedRect = L.contains("masks") && L["masks"].is_array() && !L["masks"].empty();
        if (expand && !w.fixedRect) {
            const int x0 = std::min(w.ox, 0), y0 = std::min(w.oy, 0);
            const int x1 = std::max(w.ox + w.img.width, W), y1 = std::max(w.oy + w.img.height, H);
            if (x0 != w.ox || y0 != w.oy || x1 - x0 != w.img.width || y1 - y0 != w.img.height) {
                Image big;
                big.width = x1 - x0;
                big.height = y1 - y0;
                big.rgba.assign(std::size_t(big.width) * big.height * 4, 0);
                for (int y = 0; y < w.img.height; ++y)
                    std::copy_n(&w.img.rgba[std::size_t(y) * w.img.width * 4], std::size_t(w.img.width) * 4,
                                &big.rgba[(std::size_t(y + w.oy - y0) * big.width + (w.ox - x0)) * 4]);
                w.img = std::move(big);
                w.ox = x0;
                w.oy = y0;
            }
        }
        return w;
    }
    if (!allowRasterize)
        assets_detail::arg_error(command, "/layer", label + " is a " + w.kind + " layer, not a pixels layer.",
                                 "Edit a pixels layer.");
    w.rasterized = true;
    w.img = render_layer_alone(projectDir, L, W, H, ref.parentX, ref.parentY, &w.warnings);
    w.ox = w.oy = w.originX = w.originY = 0;
    return w;
}

void commit_work(const std::string& projectDir, const std::string& rel, Json& doc, const LayerRef& ref, Work& work,
                 const char* command) {
    Json& L = *ref.layer;
    Image out = work.img;
    int cx = work.ox, cy = work.oy;
    if (!work.fixedRect) {  // crop to the pixels that show
        int x0 = out.width, y0 = out.height, x1 = -1, y1 = -1;
        for (int y = 0; y < out.height; ++y)
            for (int x = 0; x < out.width; ++x)
                if (out.rgba[(std::size_t(y) * out.width + x) * 4 + 3]) {
                    x0 = std::min(x0, x);
                    x1 = std::max(x1, x);
                    y0 = std::min(y0, y);
                    y1 = std::max(y1, y);
                }
        Image c;
        if (x1 < 0) {
            c.width = c.height = 1;
            c.rgba.assign(4, 0);
            cx += 0;
            cy += 0;
        } else {
            c.width = x1 - x0 + 1;
            c.height = y1 - y0 + 1;
            c.rgba.resize(std::size_t(c.width) * c.height * 4);
            for (int y = 0; y < c.height; ++y)
                std::copy_n(&out.rgba[(std::size_t(y + y0) * out.width + x0) * 4], std::size_t(c.width) * 4,
                            &c.rgba[std::size_t(y) * c.width * 4]);
            cx += x0;
            cy += y0;
        }
        out = std::move(c);
    }
    const std::string label = L.value("name", std::string()).empty() ? ref.indexPath : L.value("name", std::string());
    if (!work.rasterized) {
        const std::string src = L.value("source", std::string());
        // the file is the layer's own data, written in place; tell when another layer draws the same file
        std::vector<std::string> used;
        collect_sources(doc["layers"], used);
        if (std::count(used.begin(), used.end(), fs::normalize(src)) > 1)
            work.warnings.push_back("Another layer also draws '" + src + "', so it changed too.");
        write_png_file(projectDir, src, out);
        if (!work.fixedRect) {
            L["x"] = cx - ref.parentX;
            L["y"] = cy - ref.parentY;
            if (L["x"] == 0) L.erase("x");
            if (L["y"] == 0) L.erase("y");
        }
        return;
    }
    const bool ai = work.kind == "provider";
    const std::string png = layer_png_path(
        projectDir, rel, L.value("name", std::string()).empty() ? work.kind : L.value("name", std::string()), doc);
    write_layer_png(projectDir, png, rel, out, command, ai);
    Json fresh = Json::object({{"kind", "pixels"}});
    for (const char* k : {"name", "visible", "opacity", "blend", "clip"})
        if (L.contains(k)) fresh[k] = L[k];
    if (cx - ref.parentX) fresh["x"] = cx - ref.parentX;
    if (cy - ref.parentY) fresh["y"] = cy - ref.parentY;
    fresh["source"] = png;
    const bool hadMasks = L.contains("masks") || L.contains("adjustments") || L.contains("effects");
    L = std::move(fresh);
    work.warnings.push_back(
        "Layer '" + label + "' was a " + work.kind + " layer; it is now a pixels layer ('" + png + "')" +
        (hadMasks ? ", with its masks, adjustments and effects drawn into the pixels" : "") +
        ". Its original settings are gone: use a pixels layer next time to keep the layer editable.");
}

std::string add_pixels_layer(const std::string& projectDir, const std::string& rel, Json& doc, const LayerRef* above,
                             const std::string& name, const Image& img, int canvasX, int canvasY, const char* command,
                             bool ai) {
    const std::string png = layer_png_path(projectDir, rel, name, doc);
    write_layer_png(projectDir, png, rel, img, command, ai);
    Json layer = Json::object({{"kind", "pixels"}, {"name", name}});
    const int px = above ? above->parentX : 0, py = above ? above->parentY : 0;
    if (canvasX - px) layer["x"] = canvasX - px;
    if (canvasY - py) layer["y"] = canvasY - py;
    layer["source"] = png;
    if (!above) {
        doc["layers"].push_back(layer);
        return std::to_string(doc["layers"].size() - 1);
    }
    std::vector<int> path = above->path;
    path.back() += 1;
    above->list->insert(above->list->begin() + above->index + 1, layer);
    return index_path_string(path);
}

}  // namespace fa::imgedit
