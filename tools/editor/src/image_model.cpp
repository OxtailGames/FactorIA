// The Image panel's model, part 1: the document, the picture, layers, adjustments and effects, saving and the undo steps. Selections,
// strokes, move and transform are in image_model_tools.cpp.
#include "image_model.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <fstream>
#include <sstream>

#include "fa/core/strings.h"
#include "fa/scene/autotile.h"
#include "fa/tooling/image_tileset.h"
#include "fa/tooling/image_tile.h"
#include "fa/tooling/project_fs.h"
#include "inspector_model.h"

namespace fa::editor {

namespace stdfs = std::filesystem;

// ---- tools -----------------------------------------------------------------------------------------------------------------

const char* image_tool_name(ImageTool tool) {
    switch (tool) {
        case ImageTool::Move: return "Move";
        case ImageTool::Brush: return "Brush";
        case ImageTool::Eraser: return "Eraser";
        case ImageTool::Fill: return "Fill";
        case ImageTool::Picker: return "Picker";
        case ImageTool::SelectRect: return "Rectangle";
        case ImageTool::SelectEllipse: return "Ellipse";
        case ImageTool::SelectLasso: return "Lasso";
        case ImageTool::SelectPolygon: return "Polygon";
        case ImageTool::Wand: return "Magic wand";
        case ImageTool::Transform: return "Transform";
    }
    return "?";
}

const std::vector<ImageTool>& image_tools() {
    static const std::vector<ImageTool> t = {ImageTool::Move, ImageTool::Brush, ImageTool::Eraser, ImageTool::Fill, ImageTool::Picker,
                                             ImageTool::SelectRect, ImageTool::SelectEllipse, ImageTool::SelectLasso, ImageTool::SelectPolygon,
                                             ImageTool::Wand, ImageTool::Transform};
    return t;
}

bool image_tool_selects(ImageTool tool) {
    return tool == ImageTool::SelectRect || tool == ImageTool::SelectEllipse || tool == ImageTool::SelectLasso ||
           tool == ImageTool::SelectPolygon || tool == ImageTool::Wand;
}

const char* select_op_name(SelectOp op) {
    switch (op) {
        case SelectOp::Replace: return "replace";
        case SelectOp::Add: return "add";
        case SelectOp::Subtract: return "subtract";
        case SelectOp::Intersect: return "intersect";
    }
    return "replace";
}

// ---- the fields of adjustments and effects ---------------------------------------------------------------------------------

namespace {

using Field = ImageOpField;

Field num(const char* key, double lo, double hi, double def, bool optional = false) {
    Field f;
    f.kind = Field::Kind::Number;
    f.key = key;
    f.label = key;
    f.min = lo;
    f.max = hi;
    f.def = def;
    f.optional = optional;
    return f;
}
Field integer(const char* key, double lo, double hi, double def, bool optional = false) {
    Field f = num(key, lo, hi, def, optional);
    f.kind = Field::Kind::Int;
    return f;
}
Field flag(const char* key, bool def = false) {
    Field f;
    f.kind = Field::Kind::Bool;
    f.key = key;
    f.label = key;
    f.def = def ? 1 : 0;
    f.optional = !def;
    return f;
}
Field choice(const char* key, std::vector<std::string> options, const char* def, bool optional = false) {
    Field f;
    f.kind = Field::Kind::Choice;
    f.key = key;
    f.label = key;
    f.options = std::move(options);
    f.defText = def;
    f.optional = optional;
    return f;
}
Field colour(const char* key, const char* def, bool optional = false) {
    Field f;
    f.kind = Field::Kind::Color;
    f.key = key;
    f.label = key;
    f.defText = def;
    f.optional = optional;
    return f;
}
Field text(const char* key, bool optional = true) {
    Field f;
    f.kind = Field::Kind::Text;
    f.key = key;
    f.label = key;
    f.optional = optional;
    return f;
}
Field vec3(const char* key, double lo, double hi) {
    Field f;
    f.kind = Field::Kind::Vec3;
    f.key = key;
    f.label = key;
    f.min = lo;
    f.max = hi;
    return f;
}
Field special(Field::Kind kind, const char* key) {
    Field f;
    f.kind = kind;
    f.key = key;
    f.label = key;
    return f;
}

const std::map<std::string, std::vector<Field>>& adjustment_fields() {
    static const std::vector<std::string> channels = {"rgb", "red", "green", "blue"};
    static const std::vector<std::string> dithers = {"none", "bayer2", "bayer4", "bayer8", "floydSteinberg", "atkinson"};
    static const std::map<std::string, std::vector<Field>> m = {
        {"invert", {}},
        {"brightness", {num("amount", -1, 1, 0.2)}},
        {"levels", {num("inBlack", 0, 1, 0), num("inWhite", 0, 1, 1), num("gamma", 0.1, 10, 1), num("outBlack", 0, 1, 0), num("outWhite", 0, 1, 1),
                    choice("channel", channels, "rgb")}},
        {"curves", {special(Field::Kind::Curve, "points"), choice("channel", channels, "rgb")}},
        {"hsv", {num("hue", -180, 180, 0), num("saturation", -1, 1, 0), num("value", -1, 1, 0), flag("colorize")}},
        {"posterize", {integer("levels", 2, 256, 4)}},
        {"quantize", {choice("palette", {"style"}, "style"), choice("space", {"oklab", "rgb"}, "oklab"), choice("dither", dithers, "none"),
                      num("strength", 0, 1, 1)}},
        {"dither", {choice("method", dithers, "bayer4"), integer("levels", 2, 256, 2), choice("palette", {"", "style"}, "", true),
                    choice("space", {"oklab", "rgb"}, "oklab", true), num("strength", 0, 1, 1)}},
        {"gradientMap", {special(Field::Kind::Stops, "stops")}},
        {"colorBalance", {vec3("shadows", -1, 1), vec3("midtones", -1, 1), vec3("highlights", -1, 1)}},
        {"threshold", {num("level", 0, 1, 0.5), colour("above", "#ffffff"), colour("below", "#000000")}},
    };
    return m;
}

const std::map<std::string, std::vector<Field>>& effect_fields() {
    static const std::vector<std::string> positions = {"outside", "inside", "center"};
    static const std::map<std::string, std::vector<Field>> m = {
        {"colorOverlay", {colour("color", "#ff0000"), num("amount", 0, 1, 1)}},
        {"outline", {colour("color", "#000000"), num("width", 0.5, 64, 1), choice("position", positions, "outside"), flag("smooth")}},
        {"stroke", {colour("color", "#ffffff"), num("width", 0.5, 64, 2), choice("position", positions, "center"), flag("smooth")}},
        {"dropShadow", {integer("offsetX", -512, 512, 2), integer("offsetY", -512, 512, 2), num("blur", 0, 64, 2), colour("color", "#000000"),
                        num("opacity", 0, 1, 0.5)}},
        {"outerGlow", {colour("color", "#ffffff"), num("size", 0, 64, 4), num("strength", 0, 8, 1), num("opacity", 0, 1, 1)}},
        {"innerGlow", {colour("color", "#ffffff"), num("size", 0, 64, 4), num("strength", 0, 8, 1), num("opacity", 0, 1, 1)}},
        {"blur", {choice("mode", {"gaussian", "box"}, "gaussian"), num("radius", 0, 64, 2)}},
        {"sharpen", {num("radius", 0.1, 32, 1), num("amount", 0, 10, 1), num("threshold", 0, 1, 0, true)}},
        {"noise", {num("amount", 0, 1, 0.1), integer("seed", 0, 1000000, 0), choice("mode", {"mono", "color"}, "mono")}},
        {"shade", {text("normalMap"), flag("flipGreen"), num("smooth", 0, 16, 1), num("strength", 0, 32, 3), num("lightDirection", -360, 360, 135, true),
                   num("elevation", 1, 90, 45), num("intensity", 0, 4, 1), num("amount", 0, 1, 1)}},
    };
    return m;
}

}  // namespace

const std::vector<ImageOpField>& image_op_fields(const std::string& type, bool effect) {
    static const std::vector<ImageOpField> none;
    const auto& m = effect ? effect_fields() : adjustment_fields();
    auto it = m.find(type);
    return it == m.end() ? none : it->second;
}

Json ImageModel::default_operation(const std::string& type, bool effect) {
    Json op = Json::object({{"type", type}});
    for (const ImageOpField& f : image_op_fields(type, effect)) {
        if (f.optional) continue;
        switch (f.kind) {
            case ImageOpField::Kind::Number: op[f.key] = f.def; break;
            case ImageOpField::Kind::Int: op[f.key] = int(f.def); break;
            case ImageOpField::Kind::Bool: op[f.key] = f.def != 0; break;
            case ImageOpField::Kind::Choice:
            case ImageOpField::Kind::Color:
            case ImageOpField::Kind::Text:
                if (!f.defText.empty()) op[f.key] = f.defText;
                break;
            case ImageOpField::Kind::Vec3: op[f.key] = Json::array({f.def, f.def, f.def}); break;
            case ImageOpField::Kind::Curve: op[f.key] = Json::array({Json::array({0, 0}), Json::array({1, 1})}); break;
            case ImageOpField::Kind::Stops:
                op[f.key] = Json::array({Json::object({{"at", 0}, {"color", "#000000"}}), Json::object({{"at", 1}, {"color", "#ffffff"}})});
                break;
        }
    }
    return op;
}

// ---- small helpers ---------------------------------------------------------------------------------------------------------

namespace {

std::vector<int> split_path(const std::string& path) {
    std::vector<int> out;
    std::string cur;
    for (char c : path + "/") {
        if (c == '/') {
            if (!cur.empty()) out.push_back(std::atoi(cur.c_str()));
            cur.clear();
        } else {
            cur += c;
        }
    }
    return out;
}

std::string join_path(const std::vector<int>& p) {
    std::string out;
    for (std::size_t i = 0; i < p.size(); ++i) out += (i ? "/" : "") + std::to_string(p[i]);
    return out;
}

const ImageLayer* find_in(const std::vector<ImageLayer>& layers, const std::vector<int>& path) {
    const std::vector<ImageLayer>* list = &layers;
    const ImageLayer* cur = nullptr;
    for (int i : path) {
        if (i < 0 || std::size_t(i) >= list->size()) return nullptr;
        cur = &(*list)[std::size_t(i)];
        list = &cur->children;
    }
    return cur;
}

ImageLayer* find_in_mut(std::vector<ImageLayer>& layers, const std::vector<int>& path) {
    return const_cast<ImageLayer*>(find_in(layers, path));
}

const Json* json_layer(const Json& doc, const std::vector<int>& path) {
    const Json* list = doc.contains("layers") ? &doc["layers"] : nullptr;
    const Json* cur = nullptr;
    for (int i : path) {
        if (!list || !list->is_array() || i < 0 || std::size_t(i) >= list->size()) return nullptr;
        cur = &(*list)[std::size_t(i)];
        list = cur->contains("layers") ? &(*cur)["layers"] : nullptr;
    }
    return cur;
}

void merge_patch(Json& target, const Json& patch) {
    for (auto it = patch.begin(); it != patch.end(); ++it) {
        if (it.value().is_null()) target.erase(it.key());
        else if (it.value().is_object() && target.contains(it.key()) && target[it.key()].is_object() && it.key() != "texture" && it.key() != "provenance")
            merge_patch(target[it.key()], it.value());
        else target[it.key()] = it.value();
    }
}

std::optional<std::string> read_bytes(const stdfs::path& p) {
    std::ifstream in(p, std::ios::binary);
    if (!in) return std::nullopt;
    std::ostringstream ss;
    ss << in.rdbuf();
    return ss.str();
}

bool write_bytes(const stdfs::path& p, const std::string& data) {
    std::error_code ec;
    stdfs::create_directories(p.parent_path(), ec);
    std::ofstream out(p, std::ios::binary | std::ios::trunc);
    if (!out) return false;
    out.write(data.data(), std::streamsize(data.size()));
    return bool(out);
}

std::string stem_of(const std::string& rel) {
    const std::string suffix = kImageDocSuffix;
    return rel.size() > suffix.size() && rel.compare(rel.size() - suffix.size(), suffix.size(), suffix) == 0 ? rel.substr(0, rel.size() - suffix.size()) : rel;
}

std::string layers_dir_of(const std::string& rel) { return stem_of(rel) + ".layers/"; }
std::string selections_dir_of(const std::string& rel) { return ".factoria/selections/" + rel + "/"; }

std::string slug_of(const std::string& name) {
    std::string out;
    for (char c : name) {
        if (std::isalnum(static_cast<unsigned char>(c))) out += char(std::tolower(static_cast<unsigned char>(c)));
        else if (!out.empty() && out.back() != '-') out += '-';
    }
    while (!out.empty() && out.back() == '-') out.pop_back();
    return out.empty() ? "layer" : out;
}

std::uint64_t mix(std::uint64_t h, std::uint64_t v) { return (h ^ (v + 0x9e3779b97f4a7c15ULL + (h << 6) + (h >> 2))) * 0x100000001b3ULL; }

}  // namespace

// ---- construction, loading -------------------------------------------------------------------------------------------------

ImageModel::ImageModel(std::string projectDir, ImageCommandFn call) : projectDir_(std::move(projectDir)), call_(std::move(call)) {}

std::string ImageModel::lock_key(const std::string& path) const {
    const ImageLayer* l = layer(path);
    return l && !l->name.empty() ? l->name : "#" + path;
}

bool ImageModel::open(const std::string& rel) {
    close();
    rel_ = rel;
    frame_ = 0;
    status_.clear();
    load_from_disk();
    return valid_;
}

void ImageModel::close() {
    live_ = Live{};
    previewSet_ = Json();
    previewOp_ = false;
    rel_.clear();
    error_.clear();
    json_ = Json();
    doc_ = ImageDocument{};
    valid_ = false;
    selected_.clear();
    lockedNames_.clear();
    closedNames_.clear();
    selection_ = ImageSelection{};
    ++selRev_;
    picture_ = Image{};
    below_ = Image{};
    belowKey_.clear();
    pictureDirty_ = true;
    stamp_ = 0;
}

bool ImageModel::load_from_disk() {
    live_ = Live{};
    previewSet_ = Json();
    previewOp_ = false;
    std::vector<ImageIssue> issues;
    auto parsed = load_image_document(projectDir_, rel_, &issues);
    ++docRev_;
    pictureDirty_ = true;
    belowKey_.clear();
    if (!parsed.ok()) {
        valid_ = false;
        error_ = parsed.error().message + (parsed.error().hint.empty() ? "" : " " + parsed.error().hint);
        doc_ = ImageDocument{};
        bake_ = ImageBakeStatus{ImageBakeState::Broken, "", error_};
        refresh_selection();
        return false;
    }
    valid_ = true;
    error_.clear();
    doc_ = std::move(*parsed);
    json_ = doc_.json;
    bake_ = image_bake_status(projectDir_, rel_);
    frame_ = std::clamp(frame_, 0, std::max(0, image_frame_count(doc_) - 1));
    if (!selected_.empty() && !layer(selected_)) selected_.clear();
    refresh_selection();
    // the stamp is made last: it lists the files the document names
    std::uint64_t h = 1469598103934665603ULL;
    for (const std::string& p : tracked_paths(json_)) {
        auto abs = resolve_project_path(projectDir_, p);
        std::error_code ec;
        if (!abs.ok() || !stdfs::is_regular_file(*abs, ec)) continue;
        for (char c : p) h = mix(h, std::uint64_t(static_cast<unsigned char>(c)));
        h = mix(h, std::uint64_t(stdfs::file_size(*abs, ec)));
        h = mix(h, std::uint64_t(stdfs::last_write_time(*abs, ec).time_since_epoch().count()));
    }
    stamp_ = h;
    return true;
}

bool ImageModel::reload() {
    if (!is_open()) return false;
    return load_from_disk();
}

bool ImageModel::poll_external() {
    if (!is_open() || live_.kind != Live::Kind::None || previewing()) return false;
    std::uint64_t h = 1469598103934665603ULL;
    const std::string was = error_;
    // the same hash as load_from_disk: the document may not load, then only the document file counts
    std::set<std::string> paths;
    if (valid_) paths = tracked_paths(json_);
    else paths.insert(rel_);
    for (const std::string& p : paths) {
        auto abs = resolve_project_path(projectDir_, p);
        std::error_code ec;
        if (!abs.ok() || !stdfs::is_regular_file(*abs, ec)) continue;
        for (char c : p) h = mix(h, std::uint64_t(static_cast<unsigned char>(c)));
        h = mix(h, std::uint64_t(stdfs::file_size(*abs, ec)));
        h = mix(h, std::uint64_t(stdfs::last_write_time(*abs, ec).time_since_epoch().count()));
    }
    if (h == stamp_) return false;
    load_from_disk();
    return true;
}

// ---- the picture -----------------------------------------------------------------------------------------------------------

const Image& ImageModel::picture() {
    if (pictureDirty_) recomposite();
    return picture_;
}

void ImageModel::set_frame(int frame) {
    if (live_.kind != Live::Kind::None) return;
    frame = std::clamp(frame, 0, std::max(0, frame_count() - 1));
    if (frame == frame_) return;
    frame_ = frame;
    refresh_selection();
    mark_dirty();
}

void ImageModel::set_onion(bool on) {
    if (on == onion_) return;
    onion_ = on;
    mark_dirty();
}

int ImageModel::frame_duration(int frame) const {
    return frame >= 0 && std::size_t(frame) < doc_.frames.size() ? doc_.frames[std::size_t(frame)].duration : 100;
}

void ImageModel::set_onion_settings(const OnionSettings& s) {
    OnionSettings n = s;
    n.before = std::clamp(n.before, 0, 8);
    n.after = std::clamp(n.after, 0, 8);
    n.opacity = std::clamp(n.opacity, 0.0f, 1.0f);
    if (n.before == onionSettings_.before && n.after == onionSettings_.after && n.opacity == onionSettings_.opacity && n.loop == onionSettings_.loop) return;
    onionSettings_ = n;
    if (onion_) mark_dirty();
}

ImageEditOutcome ImageModel::add_frame(bool duplicate) {
    const int at = std::clamp(frame_ + 1, 0, std::max(1, frame_count()));
    Json args = Json::object({{"count", 1}, {"at", at}});
    if (duplicate) args["from"] = frame_;
    else args["blank"] = true;
    ImageEditOutcome out = run(duplicate ? "Duplicate frame" : "Add frame", {{"image.frame.add", args}});
    if (out.ok) {
        frame_ = std::clamp(at, 0, std::max(0, frame_count() - 1));
        refresh_selection();
        mark_dirty();
    }
    return out;
}

ImageEditOutcome ImageModel::resize_canvas(int width, int height, const std::string& anchor, const std::string& fill) {
    Json args = Json::object({{"width", std::clamp(width, 1, 4096)}, {"height", std::clamp(height, 1, 4096)}, {"anchor", anchor}});
    if (!fill.empty()) args["fill"] = fill;
    ImageEditOutcome out = run("Resize canvas", {{"image.resize", args}});
    if (out.ok) {
        refresh_selection();
        mark_dirty();
    }
    return out;
}

ImageEditOutcome ImageModel::remove_frame(int frame) {
    ImageEditOutcome out = run("Delete frame", {{"image.frame.remove", Json::object({{"frame", frame}})}});
    if (out.ok) {
        frame_ = std::clamp(frame_ > frame || frame_ == frame_count() ? frame_ - 1 : frame_, 0, std::max(0, frame_count() - 1));
        refresh_selection();
        mark_dirty();
    }
    return out;
}

ImageEditOutcome ImageModel::move_frame(int frame, int to) {
    ImageEditOutcome out = run("Move frame", {{"image.frame.move", Json::object({{"frame", frame}, {"to", to}})}});
    if (out.ok) {
        frame_ = std::clamp(to, 0, std::max(0, frame_count() - 1));
        refresh_selection();
        mark_dirty();
    }
    return out;
}

ImageEditOutcome ImageModel::set_frame_duration(int frame, int milliseconds) {
    return run("Frame duration", {{"image.frame.set", Json::object({{"frame", frame}, {"duration", std::clamp(milliseconds, 1, 60000)}})}});
}

namespace {

// Puts the picture `source` (pixels) or `rows` (indexed) on the layer's cel of `frame`, at x, y relative to the layer's parent.
void place_cel(ImageLayer& l, int frame, bool indexed, const std::string& source, const std::vector<std::string>& rows, int x, int y) {
    if (frame <= 0) {
        if (indexed) {
            l.rows = rows;
            l.width = l.height = 0;
        } else {
            l.source = source;
        }
        l.x = x;
        l.y = y;
        return;
    }
    auto it = std::find_if(l.cels.begin(), l.cels.end(), [&](const ImageCel& c) { return c.frame == frame; });
    if (it == l.cels.end()) {
        ImageCel c;
        c.frame = frame;
        it = l.cels.insert(std::find_if(l.cels.begin(), l.cels.end(), [&](const ImageCel& o) { return o.frame > frame; }), c);
    }
    it->empty = false;
    it->link = -1;
    if (indexed) it->rows = rows;
    else it->source = source;
    it->x = x;
    it->y = y;
}

}  // namespace

bool ImageModel::apply_preview_json(ImageDocument& out) const {
    Json j = json_;
    const std::vector<int> path = split_path(previewLayer_);
    Json* list = j.contains("layers") ? &j["layers"] : nullptr;
    Json* cur = nullptr;
    for (int i : path) {
        if (!list || !list->is_array() || i < 0 || std::size_t(i) >= list->size()) return false;
        cur = &(*list)[std::size_t(i)];
        list = cur->contains("layers") ? &(*cur)["layers"] : nullptr;
    }
    if (!cur) return false;
    if (previewOp_) {
        const char* key = previewIsEffect_ ? "effects" : "adjustments";
        if (!cur->contains(key) || !(*cur)[key].is_array() || previewOpIndex_ < 0 || std::size_t(previewOpIndex_) >= (*cur)[key].size()) return false;
        merge_patch((*cur)[key][std::size_t(previewOpIndex_)], previewSet_);
    } else {
        merge_patch(*cur, previewSet_);
    }
    auto parsed = parse_image_document(j, rel_, projectDir_);
    if (!parsed.ok()) return false;
    out = std::move(*parsed);
    return true;
}

void ImageModel::update_live() {
    Live& L = live_;
    L.stale = false;
    if (L.kind == Live::Kind::None) return;
    if (L.kind == Live::Kind::Stroke) {
        if (L.indexed) {
            L.grid = L.gridBase;
            const int value = L.erase ? -1 : L.brush.paletteIndex;
            for (const PixelPoint& p : indexed_stamp(L.points, L.brush.size)) L.grid.set(p.x - L.gridX, p.y - L.gridY, value);
        } else {
            L.work = L.base.img;
            ImageBrush b;
            b.size = L.brush.size;
            b.hardness = L.brush.hardness;
            b.opacity = L.brush.opacity;
            b.color = L.brush.color;
            b.erase = L.erase;
            const TileGrid tiles = tile_grid_of(json_);
            paint_image_stroke(L.work, L.base.ox, L.base.oy, L.points, b, L.sel ? &*L.sel : nullptr, &tiles);
        }
    } else if (L.kind == Live::Kind::Move && !L.wholeLayer) {
        L.work = L.erased;
        ImagePatch p = L.patch;
        p.x += L.moveDx;
        p.y += L.moveDy;
        const TileGrid tiles = tile_grid_of(json_);
        if (tiles.on) image_patch_draw_wrapped(L.work, L.base.ox, L.base.oy, p, L.patch.x, L.patch.y, tiles);
        else image_patch_draw(L.work, L.base.ox, L.base.oy, p);
    } else if (L.kind == Live::Kind::Transform) {
        L.work = L.erased;
        ImagePatch p = L.patch;
        p.x += L.tf.dx;
        p.y += L.tf.dy;
        ImageTransform t;
        t.scaleX = L.tf.scaleX;
        t.scaleY = L.tf.scaleY;
        t.rotate = L.tf.rotate;
        t.flipH = L.tf.flipH;
        t.flipV = L.tf.flipV;
        t.pivotX = L.tf.pivotX + L.tf.dx;
        t.pivotY = L.tf.pivotY + L.tf.dy;
        t.nearest = L.tf.nearest;
        Result<ImagePatch> r = image_patch_transform(p, t);
        if (r.ok()) image_patch_draw(L.work, L.base.ox, L.base.oy, *r);
        else status_ = r.error().message;
    }
}

void ImageModel::recomposite() {
    pictureDirty_ = false;
    if (!valid_) {
        picture_ = Image{};
        ++pictureRev_;
        return;
    }
    const auto t0 = std::chrono::steady_clock::now();
    if (live_.kind != Live::Kind::None && live_.stale) update_live();

    const bool live = live_.kind != Live::Kind::None;
    const bool preview = previewing();
    const std::string edited = live ? live_.layer : (preview ? previewLayer_ : std::string());
    const std::vector<int> editedPath = split_path(edited);

    ImageDocument tmp;
    bool haveTmp = false;
    if (preview) {
        if (apply_preview_json(tmp)) haveTmp = true;
        else status_ = "That value does not make a valid document; showing the saved one.";
    }
    if (live && !haveTmp) {
        tmp = doc_;
        haveTmp = true;
    }
    if (live) {
        if (ImageLayer* l = find_in_mut(tmp.layers, editedPath)) {
            auto parent = parent_offset(live_.layer);
            if (live_.kind == Live::Kind::Move && live_.wholeLayer) {
                l->x = live_.layerX0 + live_.moveDx;
                l->y = live_.layerY0 + live_.moveDy;
            } else if (live_.indexed) {
                place_cel(*l, frame_, true, "", index_grid_rows(live_.grid), live_.gridX - parent.first, live_.gridY - parent.second);
            } else {
                place_cel(*l, frame_, false, "$live", {}, live_.base.ox - parent.first, live_.base.oy - parent.second);
            }
        }
    }

    // The layers under the one being edited do not change while it is edited: draw them once (belowKey_) and stand a picture for them.
    const ImageDocument* src = haveTmp ? &tmp : &doc_;
    ImageDocument withBelow;
    int editedTop = editedPath.empty() ? -1 : editedPath.front();
    const bool useBelow = editedTop > 0 && !onion_ && std::size_t(editedTop) < src->layers.size() && !src->layers[std::size_t(editedTop)].clip;
    ImageRenderOptions options;
    options.projectDir = projectDir_;
    options.frame = std::min(frame_, std::max(0, image_frame_count(*src) - 1));
    if (onion_ && image_frame_count(*src) > 1) {
        ImageOnionSkin skin;
        skin.before = onionSettings_.before;
        skin.after = onionSettings_.after;
        skin.opacity = onionSettings_.opacity;
        skin.loop = onionSettings_.loop;
        options.onion = skin;
    }
    if (useBelow) {
        const std::string key = std::to_string(docRev_) + ":" + std::to_string(editedTop) + ":" + std::to_string(frame_);
        if (key != belowKey_) {
            ImageDocument lower = doc_;
            lower.layers.resize(std::size_t(editedTop));
            ImageRenderOptions lo = options;
            lo.onion.reset();
            auto r = composite_image_document(lower, lo);
            if (r.ok()) {
                below_ = std::move(r->image);
                belowKey_ = key;
            }
        }
        if (key == belowKey_) {
            withBelow = *src;
            ImageLayer base;
            base.kind = ImageLayerKind::Pixels;
            base.name = "$below";
            base.source = "$below";
            withBelow.layers.erase(withBelow.layers.begin(), withBelow.layers.begin() + editedTop);
            withBelow.layers.insert(withBelow.layers.begin(), base);
            withBelow.background.reset();   // the lower picture already holds it
            src = &withBelow;
            pics_["$below"] = std::move(below_);
        }
    }
    if (live && !live_.work.empty() && !live_.indexed) pics_["$live"] = std::move(live_.work);
    options.pictures = &pics_;
    auto result = composite_image_document(*src, options);
    if (auto it = pics_.find("$below"); it != pics_.end()) below_ = std::move(it->second);
    if (auto it = pics_.find("$live"); it != pics_.end()) live_.work = std::move(it->second);
    pics_.clear();

    if (result.ok()) {
        picture_ = std::move(result->image);
    } else {
        status_ = "Cannot draw the picture: " + result.error().message;
        if (picture_.empty()) picture_ = Image{};
    }
    ++pictureRev_;
    ++composites_;
    compositeMs_ = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count();
}

// ---- reading the document --------------------------------------------------------------------------------------------------

const ImageLayer* ImageModel::layer(const std::string& path) const { return find_in(doc_.layers, split_path(path)); }

const Json* ImageModel::layer_json(const std::string& path) const { return json_layer(json_, split_path(path)); }

std::pair<int, int> ImageModel::parent_offset(const std::string& path) const {
    std::vector<int> p = split_path(path);
    int x = 0, y = 0;
    for (std::size_t n = 1; n < p.size(); ++n) {
        const ImageLayer* g = find_in(doc_.layers, std::vector<int>(p.begin(), p.begin() + long(n)));
        if (g) {
            x += g->x;
            y += g->y;
        }
    }
    return {x, y};
}

bool ImageModel::is_locked(const std::string& path) const { return lockedNames_.count(lock_key(path)) != 0; }
void ImageModel::set_locked(const std::string& path, bool locked) {
    if (locked) lockedNames_.insert(lock_key(path));
    else lockedNames_.erase(lock_key(path));
}
bool ImageModel::is_open(const std::string& path) const { return closedNames_.count(lock_key(path)) == 0; }
void ImageModel::set_open(const std::string& path, bool open) {
    if (open) closedNames_.erase(lock_key(path));
    else closedNames_.insert(lock_key(path));
}

void ImageModel::select_layer(const std::string& path) {
    if (live_.kind != Live::Kind::None) return;
    selected_ = layer(path) ? path : std::string();
}

std::vector<ImageLayerRow> ImageModel::layer_rows() const {
    std::vector<ImageLayerRow> rows;
    std::function<void(const std::vector<ImageLayer>&, const std::string&, int)> walk = [&](const std::vector<ImageLayer>& list,
                                                                                         const std::string& prefix, int depth) {
        for (int i = int(list.size()) - 1; i >= 0; --i) {
            const ImageLayer& l = list[std::size_t(i)];
            ImageLayerRow r;
            r.path = prefix.empty() ? std::to_string(i) : prefix + "/" + std::to_string(i);
            r.depth = depth;
            r.name = l.name.empty() ? std::string(image_layer_kind_name(l.kind)) : l.name;
            r.kind = l.kind;
            r.visible = l.visible;
            r.opacity = l.opacity;
            r.blend = l.blend;
            r.isGroup = l.kind == ImageLayerKind::Group;
            r.clip = l.clip;
            r.childCount = int(l.children.size());
            r.locked = is_locked(r.path);
            r.open = is_open(r.path);
            rows.push_back(r);
            if (r.isGroup && r.open) walk(l.children, r.path, depth + 1);
        }
    };
    walk(doc_.layers, "", 0);
    return rows;
}

bool ImageModel::paintable(const std::string& path, std::string* why) const {
    auto fail = [&](const std::string& m) {
        if (why) *why = m;
        return false;
    };
    if (!valid_) return fail("The document does not load.");
    const ImageLayer* l = layer(path);
    if (!l) return fail("Select a layer first.");
    if (l->kind != ImageLayerKind::Pixels && l->kind != ImageLayerKind::Indexed)
        return fail(std::string("A ") + image_layer_kind_name(l->kind) + " layer has no pixels to draw on: select a pixels or indexed layer, or add one.");
    if (is_locked(path)) return fail("The layer is locked.");
    if (l->kind == ImageLayerKind::Indexed && doc_.palette.empty()) return fail("The document has no palette to draw with.");
    return true;
}

std::string ImageModel::unique_layer_name(const std::string& base) const {
    std::set<std::string> taken;
    std::function<void(const std::vector<ImageLayer>&)> walk = [&](const std::vector<ImageLayer>& list) {
        for (const ImageLayer& l : list) {
            taken.insert(l.name);
            walk(l.children);
        }
    };
    walk(doc_.layers);
    if (!taken.count(base)) return base;
    for (int i = 2;; ++i) {
        const std::string n = base + " " + std::to_string(i);
        if (!taken.count(n)) return n;
    }
}

std::string ImageModel::find_path_by_name(const std::string& name) const {
    std::string found;
    std::function<void(const std::vector<ImageLayer>&, const std::string&)> walk = [&](const std::vector<ImageLayer>& list, const std::string& prefix) {
        for (std::size_t i = 0; i < list.size() && found.empty(); ++i) {
            const std::string p = prefix.empty() ? std::to_string(i) : prefix + "/" + std::to_string(i);
            if (list[i].name == name) found = p;
            else walk(list[i].children, p);
        }
    };
    walk(doc_.layers, "");
    return found;
}

// ---- files and undo steps --------------------------------------------------------------------------------------------------

std::set<std::string> ImageModel::tracked_paths(const Json& doc) const {
    std::set<std::string> out;
    out.insert(rel_);
    auto add = [&](const Json& v) {
        if (v.is_string() && !v.get<std::string>().empty() && v.get<std::string>()[0] != '$') out.insert(v.get<std::string>());
    };
    std::function<void(const Json&)> walk = [&](const Json& layers) {
        if (!layers.is_array()) return;
        for (const Json& l : layers) {
            if (!l.is_object()) continue;
            if (l.contains("source")) add(l["source"]);
            if (l.contains("masks") && l["masks"].is_array())
                for (const Json& m : l["masks"])
                    if (m.is_object() && m.contains("source")) add(m["source"]);
            if (l.contains("cels") && l["cels"].is_array())
                for (const Json& c : l["cels"])
                    if (c.is_object() && c.contains("source")) add(c["source"]);
            if (l.contains("layers")) walk(l["layers"]);
        }
    };
    if (doc.is_object() && doc.contains("layers")) walk(doc["layers"]);
    auto list_dir = [&](const std::string& dirRel, bool skipPreview) {
        auto abs = resolve_project_path(projectDir_, dirRel);
        std::error_code ec;
        if (!abs.ok() || !stdfs::is_directory(*abs, ec)) return;
        for (const auto& e : stdfs::directory_iterator(*abs, ec)) {
            if (!e.is_regular_file(ec)) continue;
            const std::string name = e.path().filename().string();
            if (skipPreview && name.size() > 12 && name.compare(name.size() - 12, 12, ".preview.png") == 0) continue;
            out.insert(dirRel + name);
        }
    };
    list_dir(layers_dir_of(rel_), false);
    list_dir(selections_dir_of(rel_), true);
    return out;
}

ImageBlob ImageModel::blob_of(const std::string& rel) {
    auto abs = resolve_project_path(projectDir_, rel);
    std::error_code ec;
    if (!abs.ok() || !stdfs::is_regular_file(*abs, ec)) {
        fileCache_.erase(rel);
        return nullptr;
    }
    auto data = read_bytes(*abs);
    if (!data) return nullptr;
    auto it = fileCache_.find(rel);
    if (it != fileCache_.end() && it->second && *it->second == *data) return it->second;
    ImageBlob blob = std::make_shared<const std::string>(std::move(*data));
    fileCache_[rel] = blob;
    return blob;
}

ImageFileSet ImageModel::capture(const std::set<std::string>& paths) {
    ImageFileSet out;
    for (const std::string& p : paths) out[p] = blob_of(p);
    return out;
}

bool ImageModel::restore(const ImageFileSet& files) {
    for (const auto& [rel, blob] : files) {
        auto abs = resolve_project_path(projectDir_, rel);
        if (!abs.ok()) {
            note_error(abs.error().message);
            return false;
        }
        std::error_code ec;
        if (!blob) {
            stdfs::remove(*abs, ec);
        } else if (!write_bytes(*abs, *blob)) {
            note_error("Cannot write " + rel + ".");
            return false;
        }
        fileCache_.erase(rel);
    }
    return true;
}

void ImageModel::note_error(const std::string& m) {
    status_ = m;
    lastError_ = m;
}

ImageEditOutcome ImageModel::run(const std::string& label, Calls calls, const Prepare& prepare) {
    ImageEditOutcome out;
    if (!valid_) {
        out.ok = false;
        out.error = "The document does not load" + (error_.empty() ? std::string(".") : ": " + error_);
        note_error(out.error);
        return out;
    }
    live_ = Live{};
    const std::string keepName = selected_.empty() ? std::string() : (layer(selected_) ? layer(selected_)->name : std::string());
    const std::string keepPath = selected_;
    const std::set<std::string> paths = tracked_paths(json_);
    ImageFileSet before = capture(paths);
    auto fail = [&](const std::string& message) {
        // put every file back, including files a half-done edit created in the folders we list
        std::set<std::string> now = paths;
        if (!load_from_disk()) now.insert(rel_);
        else for (const std::string& p : tracked_paths(json_)) now.insert(p);
        ImageFileSet back = before;
        for (const std::string& p : now)
            if (!back.count(p) && (p.rfind(layers_dir_of(rel_), 0) == 0 || p.rfind(selections_dir_of(rel_), 0) == 0)) back[p] = nullptr;
        restore(back);
        load_from_disk();
        out.ok = false;
        out.error = message;
        note_error(message);
        return out;
    };
    if (prepare) {
        std::string err;
        if (!prepare(err, calls)) return fail(err);
    }
    for (const auto& [name, args] : calls) {
        const bool frameAware = name == "image.edit" || name == "image.paint" || name == "image.pixel" || name == "image.draw" || name == "image.select";
        Json a = args;
        a["path"] = rel_;
        if (name != "image.select") a["bake"] = false;
        if (frameAware && animated()) a["frame"] = frame_;
        CommandResult r = call_(name, a);
        if (!r.ok) return fail(label + ": " + command_error_text(r.error));
        out.result = r.result;
    }
    if (!load_from_disk()) {
        // the edit left a document that does not load: put it back
        return fail(label + ": the document no longer loads (" + error_ + ").");
    }
    std::set<std::string> now = paths;
    for (const std::string& p : tracked_paths(json_)) now.insert(p);
    // A file the edit started to name is tracked only when it sits in a folder we listed before the edit (so it did not exist then)
    ImageFileSet after;
    for (const std::string& p : now) {
        const bool known = paths.count(p) != 0;
        const bool listed = p.rfind(layers_dir_of(rel_), 0) == 0 || p.rfind(selections_dir_of(rel_), 0) == 0;
        if (!known && !listed) continue;
        if (!known) before[p] = nullptr;
        after[p] = blob_of(p);
    }
    for (auto it = before.begin(); it != before.end();) {
        auto a = after.find(it->first);
        const bool same = a != after.end() && (a->second == it->second || (a->second && it->second && *a->second == *it->second) );
        if (same) {
            after.erase(a);
            it = before.erase(it);
        } else {
            ++it;
        }
    }
    if (!after.empty() || !before.empty()) {
        ImageStep step;
        step.id = nextStep_++;
        step.rel = rel_;
        step.label = label;
        step.before = std::move(before);
        step.after = std::move(after);
        // a file that is in only one of the two sets was absent in the other
        for (const auto& [p, b] : step.before)
            if (!step.after.count(p)) step.after[p] = blob_of(p);
        for (const auto& [p, b] : step.after)
            if (!step.before.count(p)) step.before[p] = nullptr;
        out.step = step.id;
        steps_[step.id] = std::move(step);
    }
    // keep the same layer selected through moves and renames
    if (!keepName.empty()) {
        const std::string p = find_path_by_name(keepName);
        selected_ = !p.empty() ? p : (layer(keepPath) ? keepPath : std::string());
    } else if (!layer(keepPath)) {
        selected_.clear();
    } else {
        selected_ = keepPath;
    }
    status_ = label;
    return out;
}

const ImageStep* ImageModel::step(int id) const {
    auto it = steps_.find(id);
    return it == steps_.end() ? nullptr : &it->second;
}

std::string ImageModel::step_document(int id) const {
    auto it = steps_.find(id);
    return it == steps_.end() ? std::string() : it->second.rel;
}

bool ImageModel::apply_step(int id, bool forward) {
    auto it = steps_.find(id);
    if (it == steps_.end()) {
        note_error("That image edit is no longer remembered.");
        return false;
    }
    live_ = Live{};
    const ImageStep& s = it->second;
    if (!restore(forward ? s.after : s.before)) return false;
    if (s.rel == rel_) {
        const std::string keep = selected_.empty() || !layer(selected_) ? std::string() : layer(selected_)->name;
        load_from_disk();
        if (!keep.empty()) selected_ = find_path_by_name(keep);
    }
    status_ = std::string(forward ? "Redo: " : "Undo: ") + s.label;
    return true;
}

void ImageModel::merge_steps(int first, int second) {
    auto a = steps_.find(first), b = steps_.find(second);
    if (a == steps_.end() || b == steps_.end() || first == second) return;
    for (const auto& [p, blob] : b->second.before)
        if (!a->second.before.count(p)) a->second.before[p] = blob;
    for (const auto& [p, blob] : b->second.after) a->second.after[p] = blob;
    steps_.erase(b);
}

void ImageModel::retain_steps(const std::set<int>& keep) {
    for (auto it = steps_.begin(); it != steps_.end();) {
        if (keep.count(it->first)) ++it;
        else it = steps_.erase(it);
    }
}

// ---- layers ----------------------------------------------------------------------------------------------------------------

namespace {

Json default_layer(const std::string& kind) {
    Json l = Json::object({{"kind", kind}});
    if (kind == "fill") l["color"] = "#ffffff";
    else if (kind == "gradient")
        l["gradient"] = Json::object({{"stops", Json::array({Json::object({{"at", 0}, {"color", "#000000"}}), Json::object({{"at", 1}, {"color", "#ffffff"}})})}});
    else if (kind == "text") {
        l["text"] = "Text";
        l["size"] = 16;
        l["color"] = "#000000";
    } else if (kind == "group") l["layers"] = Json::array();
    else if (kind == "adjustment") l["adjustments"] = Json::array({ImageModel::default_operation("brightness", false)});
    return l;
}

}  // namespace


ImageEditOutcome ImageModel::add_layer(const std::string& kind) {
    std::vector<int> sel = split_path(selected_);
    std::string parent;
    int index = int(doc_.layers.size());
    if (!sel.empty()) {
        index = sel.back() + 1;
        parent = join_path(std::vector<int>(sel.begin(), sel.end() - 1));
    }
    const std::string name = unique_layer_name(kind);
    Json layer = default_layer(kind);
    layer["name"] = name;
    Json args = Json::object({{"layer", layer}, {"index", index}});
    if (!parent.empty()) args["parent"] = parent;
    Prepare prepare;
    if (kind == "pixels") {
        prepare = [&](std::string& err, Calls& calls) {
            Image blank;
            blank.width = doc_.width;
            blank.height = doc_.height;
            blank.rgba.assign(std::size_t(blank.width) * blank.height * 4, 0);
            std::string rel;
            for (int i = 1;; ++i) {
                rel = layers_dir_of(rel_) + slug_of(name) + (i > 1 ? "-" + std::to_string(i) : "") + ".png";
                auto abs = resolve_project_path(projectDir_, rel);
                if (!abs.ok()) {
                    err = abs.error().message;
                    return false;
                }
                std::error_code ec;
                if (!stdfs::exists(*abs, ec)) break;
            }
            const auto png = encode_png(blank);
            if (!write_bytes(*resolve_project_path(projectDir_, rel), std::string(reinterpret_cast<const char*>(png.data()), png.size()))) {
                err = "Cannot write " + rel + ".";
                return false;
            }
            calls[0].second["layer"]["source"] = rel;
            return true;
        };
    }
    ImageEditOutcome out = run("Add " + kind + " layer", {{"image.layer.add", args}}, prepare);
    if (out.ok) selected_ = (parent.empty() ? "" : parent + "/") + std::to_string(index);
    return out;
}

ImageEditOutcome ImageModel::add_provider_layer(const std::string& label, Json addArgs) {
    const std::string name = addArgs.value("name", std::string());
    addArgs.erase("path");
    ImageEditOutcome out = run(label, {{"image.layer.add_provider", addArgs}});
    if (out.ok && !name.empty()) {
        const std::string path = find_path_by_name(name);
        if (!path.empty()) selected_ = path;
    }
    return out;
}

ImageEditOutcome ImageModel::duplicate_layer(const std::string& path) {
    const Json* src = layer_json(path);
    if (!src) {
        ImageEditOutcome e;
        e.ok = false;
        e.error = "Select a layer to duplicate.";
        note_error(e.error);
        return e;
    }
    Json copy = *src;
    std::set<std::string> taken;
    std::function<void(const std::vector<ImageLayer>&)> collect = [&](const std::vector<ImageLayer>& list) {
        for (const ImageLayer& l : list) {
            taken.insert(l.name);
            collect(l.children);
        }
    };
    collect(doc_.layers);
    std::vector<std::pair<std::string, std::string>> files;   // source -> copy
    std::set<std::string> newFiles;
    auto copy_file = [&](Json& holder, const char* key, const std::string& name) {
        if (!holder.contains(key) || !holder[key].is_string() || holder[key].get<std::string>().empty()) return;
        const std::string from = holder[key].get<std::string>();
        std::string to;
        for (int i = 1;; ++i) {
            to = layers_dir_of(rel_) + slug_of(name) + (i > 1 ? "-" + std::to_string(i) : "") + ".png";
            auto abs = resolve_project_path(projectDir_, to);
            std::error_code ec;
            if (abs.ok() && !stdfs::exists(*abs, ec) && !newFiles.count(to)) break;
            if (!abs.ok()) return;
        }
        newFiles.insert(to);
        files.push_back({from, to});
        holder[key] = to;
    };
    std::function<void(Json&, bool)> dup = [&](Json& l, bool top) {
        const std::string base = (l.value("name", std::string(l.value("kind", std::string("layer"))))) + (top ? " copy" : "");
        std::string name = base;
        for (int i = 2; taken.count(name); ++i) name = base + " " + std::to_string(i);
        taken.insert(name);
        l["name"] = name;
        if (l.value("kind", std::string()) == "pixels") {
            copy_file(l, "source", name);
            if (l.contains("cels") && l["cels"].is_array())
                for (Json& c : l["cels"]) copy_file(c, "source", name + "-cel");
        }
        if (l.contains("layers") && l["layers"].is_array())
            for (Json& c : l["layers"]) dup(c, false);
    };
    dup(copy, true);
    std::vector<int> p = split_path(path);
    const int index = p.empty() ? 0 : p.back() + 1;
    Json args = Json::object({{"layer", copy}, {"index", index}});
    if (p.size() > 1) args["parent"] = join_path(std::vector<int>(p.begin(), p.end() - 1));
    Prepare prepare = [&](std::string& err, Calls&) {
        for (const auto& [from, to] : files) {
            auto a = resolve_project_path(projectDir_, from);
            auto b = resolve_project_path(projectDir_, to);
            if (!a.ok() || !b.ok()) {
                err = "Cannot copy " + from + ".";
                return false;
            }
            auto data = read_bytes(*a);
            if (!data || !write_bytes(*b, *data)) {
                err = "Cannot copy " + from + " to " + to + ".";
                return false;
            }
        }
        return true;
    };
    ImageEditOutcome out = run("Duplicate layer", {{"image.layer.add", args}}, prepare);
    if (out.ok) selected_ = (p.size() > 1 ? join_path(std::vector<int>(p.begin(), p.end() - 1)) + "/" : "") + std::to_string(index);
    return out;
}

ImageEditOutcome ImageModel::remove_layer(const std::string& path) {
    std::vector<int> p = split_path(path);
    selected_ = path;
    ImageEditOutcome out = run("Remove layer", {{"image.layer.remove", Json::object({{"layer", path}})}});
    if (out.ok) {
        // the layer below takes the selection (the one above when it was the bottom)
        if (!p.empty()) {
            std::vector<int> q = p;
            if (q.back() > 0) --q.back();
            selected_ = layer(join_path(q)) ? join_path(q) : (p.size() > 1 ? join_path(std::vector<int>(p.begin(), p.end() - 1)) : std::string());
            if (!layer(selected_)) selected_.clear();
        }
    }
    return out;
}

ImageEditOutcome ImageModel::set_layer(const std::string& path, const Json& set, const std::string& label) {
    const std::string keep = selected_;
    selected_ = path;   // run() keeps this layer selected
    ImageEditOutcome out = run(label, {{"image.layer.set", Json::object({{"layer", path}, {"set", set}})}});
    if (!out.ok) selected_ = keep;
    else if (keep != path && layer(keep)) selected_ = keep;
    return out;
}

ImageEditOutcome ImageModel::rename_layer(const std::string& path, const std::string& name) {
    const bool wasLocked = is_locked(path), wasClosed = !is_open(path);
    const std::string oldKey = lock_key(path);
    ImageEditOutcome out = set_layer(path, Json::object({{"name", name}}), "Rename layer");
    if (out.ok) {
        lockedNames_.erase(oldKey);
        closedNames_.erase(oldKey);
        if (wasLocked) lockedNames_.insert(name);
        if (wasClosed) closedNames_.insert(name);
    }
    return out;
}

ImageEditOutcome ImageModel::move_layer(const std::string& path, const std::string& parent, int index) {
    selected_ = path;
    return run("Move layer", {{"image.layer.move", Json::object({{"layer", path}, {"parent", parent}, {"index", index}})}});
}

// ---- previews (slider drags) -----------------------------------------------------------------------------------------------

void ImageModel::preview_layer(const std::string& path, const Json& set) {
    if (live_.kind != Live::Kind::None || !layer(path)) return;
    previewLayer_ = path;
    previewSet_ = set;
    previewOp_ = false;
    mark_dirty();
}

ImageEditOutcome ImageModel::commit_preview(const std::string& label) {
    const std::string path = previewLayer_;
    const Json set = previewSet_;
    const bool op = previewOp_;
    cancel_preview();
    if (set.is_null() || op) return ImageEditOutcome{};
    return set_layer(path, set, label);
}

void ImageModel::cancel_preview() {
    if (previewSet_.is_null() && !previewOp_) return;
    previewSet_ = Json();
    previewOp_ = false;
    mark_dirty();
}

// ---- adjustments and effects -----------------------------------------------------------------------------------------------

namespace {
const char* op_key(bool effect) { return effect ? "effects" : "adjustments"; }
}  // namespace

ImageEditOutcome ImageModel::add_operation(const std::string& path, bool effect, const std::string& type) {
    const Json* l = layer_json(path);
    Json list = l && l->contains(op_key(effect)) && (*l)[op_key(effect)].is_array() ? (*l)[op_key(effect)] : Json::array();
    list.push_back(default_operation(type, effect));
    return set_layer(path, Json::object({{op_key(effect), list}}), std::string("Add ") + (effect ? "effect " : "adjustment ") + type);
}

ImageEditOutcome ImageModel::remove_operation(const std::string& path, bool effect, int index) {
    const Json* l = layer_json(path);
    Json list = l && l->contains(op_key(effect)) && (*l)[op_key(effect)].is_array() ? (*l)[op_key(effect)] : Json::array();
    if (index < 0 || std::size_t(index) >= list.size()) {
        ImageEditOutcome e;
        e.ok = false;
        e.error = "There is no such entry to remove.";
        return e;
    }
    list.erase(list.begin() + index);
    return set_layer(path, Json::object({{op_key(effect), list}}), effect ? "Remove effect" : "Remove adjustment");
}

ImageEditOutcome ImageModel::move_operation(const std::string& path, bool effect, int from, int to) {
    const Json* l = layer_json(path);
    Json list = l && l->contains(op_key(effect)) && (*l)[op_key(effect)].is_array() ? (*l)[op_key(effect)] : Json::array();
    const int n = int(list.size());
    if (from < 0 || from >= n || to < 0 || to >= n || from == to) {
        ImageEditOutcome e;
        e.ok = from == to;
        if (!e.ok) e.error = "That position does not exist.";
        return e;
    }
    Json item = list[std::size_t(from)];
    list.erase(list.begin() + from);
    list.insert(list.begin() + to, item);
    return set_layer(path, Json::object({{op_key(effect), list}}), effect ? "Reorder effects" : "Reorder adjustments");
}

void ImageModel::preview_operation(const std::string& path, bool effect, int index, const Json& fields) {
    if (live_.kind != Live::Kind::None || !layer(path)) return;
    previewLayer_ = path;
    previewSet_ = fields;
    previewOp_ = true;
    previewIsEffect_ = effect;
    previewOpIndex_ = index;
    mark_dirty();
}

ImageEditOutcome ImageModel::commit_operation_preview(const std::string& label) {
    if (!previewOp_) return ImageEditOutcome{};
    const std::string path = previewLayer_;
    const bool effect = previewIsEffect_;
    const int index = previewOpIndex_;
    const Json fields = previewSet_;
    cancel_preview();
    const Json* l = layer_json(path);
    if (!l || !l->contains(op_key(effect)) || !(*l)[op_key(effect)].is_array() || index < 0 || std::size_t(index) >= (*l)[op_key(effect)].size()) return ImageEditOutcome{};
    Json list = (*l)[op_key(effect)];
    merge_patch(list[std::size_t(index)], fields);
    if (list == (*l)[op_key(effect)]) return ImageEditOutcome{};
    return set_layer(path, Json::object({{op_key(effect), list}}), label);
}

// ---- palette and saving ----------------------------------------------------------------------------------------------------

ImageEditOutcome ImageModel::set_palette_color(int index, const std::string& hex) {
    ImageEditOutcome e;
    if (index < 0 || index >= doc_.palette.size()) {
        e.ok = false;
        e.error = "That palette colour does not exist.";
        return e;
    }
    Json list = Json::array();
    for (int i = 0; i < doc_.palette.size(); ++i) {
        const auto& en = doc_.palette.entries[std::size_t(i)];
        std::string h = i == index ? hex : doc_.palette.hex(i);
        list.push_back(en.name.empty() ? Json(h) : Json::object({{"name", en.name}, {"color", h}}));
    }
    return run("Edit palette colour", {{"image.palette", Json::object({{"palette", list}})}});
}

ImageEditOutcome ImageModel::add_palette_color(const std::string& hex, const std::string& name) {
    ImageEditOutcome e;
    if (doc_.palette.size() >= kMaxIndexedColours) {
        e.ok = false;
        e.error = "A palette holds at most " + std::to_string(kMaxIndexedColours) + " colours.";
        note_error(e.error);
        return e;
    }
    Json list = Json::array();
    for (int i = 0; i < doc_.palette.size(); ++i) {
        const auto& en = doc_.palette.entries[std::size_t(i)];
        list.push_back(en.name.empty() ? Json(doc_.palette.hex(i)) : Json::object({{"name", en.name}, {"color", doc_.palette.hex(i)}}));
    }
    list.push_back(name.empty() ? Json(hex) : Json::object({{"name", name}, {"color", hex}}));
    return run("Add palette colour", {{"image.palette", Json::object({{"palette", list}})}});
}

ImageEditOutcome ImageModel::move_palette_color(int from, int to) {
    return run("Move palette colour", {{"image.palette.move", Json::object({{"from", from}, {"to", to}})}});
}

ImageEditOutcome ImageModel::remove_palette_color(int index, int replaceWith) {
    Json args = Json::object({{"index", index}});
    if (replaceWith >= 0) args["replaceWith"] = replaceWith;
    return run("Remove palette colour", {{"image.palette.remove", args}});
}

namespace {
// The first tileset layer and where its parents put its origin on the canvas.
const ImageLayer* find_tileset(const std::vector<ImageLayer>& layers, int& ox, int& oy) {
    for (const ImageLayer& l : layers) {
        if (l.kind == ImageLayerKind::Tileset) return &l;
        int cx = ox + l.x, cy = oy + l.y;
        if (const ImageLayer* c = find_tileset(l.children, cx, cy)) {
            ox = cx;
            oy = cy;
            return c;
        }
    }
    return nullptr;
}
}  // namespace

const ImageLayer* ImageModel::tileset_layer() const {
    int ox = 0, oy = 0;
    return find_tileset(doc_.layers, ox, oy);
}

Image ImageModel::terrain_preview(const std::vector<std::string>& pattern) {
    Image out;
    const ImageLayer* l = tileset_layer();
    if (!l || !valid_ || pattern.empty()) return out;
    const TilesetSpec& spec = l->tileset;
    AutotileMode mode = AutotileMode::Blob47;
    autotile_mode_from_name(spec.mode, mode);
    const TilesetLayout lay = tileset_layout(spec);
    if (lay.tileWidth <= 0 || lay.tileHeight <= 0 || lay.columns <= 0) return out;
    const Image& sheet = picture();
    if (sheet.empty()) return out;
    // where the sheet's top-left corner is on the canvas
    int ox = 0, oy = 0;
    find_tileset(doc_.layers, ox, oy);
    ox += l->x;
    oy += l->y;
    int rows = int(pattern.size()), cols = 0;
    for (const std::string& r : pattern) cols = std::max(cols, int(r.size()));
    out.width = cols * lay.tileWidth;
    out.height = rows * lay.tileHeight;
    out.rgba.assign(std::size_t(out.width) * std::size_t(out.height) * 4, 0);
    auto terrain = [&](int c, int r) { return r >= 0 && r < rows && c >= 0 && c < int(pattern[std::size_t(r)].size()) && pattern[std::size_t(r)][std::size_t(c)] == '#'; };
    for (int r = 0; r < rows; ++r)
        for (int c = 0; c < cols; ++c) {
            if (!terrain(c, r)) continue;
            int raw = 0;
            if (terrain(c, r - 1)) raw |= kAutoN;
            if (terrain(c + 1, r - 1)) raw |= kAutoNE;
            if (terrain(c + 1, r)) raw |= kAutoE;
            if (terrain(c + 1, r + 1)) raw |= kAutoSE;
            if (terrain(c, r + 1)) raw |= kAutoS;
            if (terrain(c - 1, r + 1)) raw |= kAutoSW;
            if (terrain(c - 1, r)) raw |= kAutoW;
            if (terrain(c - 1, r - 1)) raw |= kAutoNW;
            const int slot = autotile_slot(mode, raw);
            const int variation = lay.variations > 1 ? int(autotile_hash(spec.seed, c, r) % std::uint32_t(lay.variations)) : 0;
            const int tile = lay.tile_index(slot, variation);
            const int sx = ox + (tile % lay.columns) * lay.tileWidth, sy = oy + (tile / lay.columns) * lay.tileHeight;
            for (int y = 0; y < lay.tileHeight; ++y)
                for (int x = 0; x < lay.tileWidth; ++x) {
                    if (sx + x < 0 || sy + y < 0 || sx + x >= sheet.width || sy + y >= sheet.height) continue;
                    std::copy_n(&sheet.rgba[(std::size_t(sy + y) * std::size_t(sheet.width) + std::size_t(sx + x)) * 4], 4,
                                &out.rgba[(std::size_t(r * lay.tileHeight + y) * std::size_t(out.width) + std::size_t(c * lay.tileWidth + x)) * 4]);
                }
        }
    return out;
}

ImageEditOutcome ImageModel::save() {
    ImageEditOutcome out;
    if (!valid_) {
        out.ok = false;
        out.error = "The document does not load" + (error_.empty() ? std::string(".") : ": " + error_);
        note_error(out.error);
        return out;
    }
    live_ = Live{};
    CommandResult r = call_("image.save", Json::object({{"path", rel_}, {"document", json_}, {"bake", true}}));
    if (!r.ok) {
        out.ok = false;
        out.error = "Save: " + command_error_text(r.error);
        note_error(out.error);
        return out;
    }
    out.result = r.result;
    load_from_disk();
    status_ = "Saved " + rel_ + (r.result.contains("output") && r.result["output"].is_string() ? " and baked " + r.result["output"].get<std::string>() : std::string());
    return out;
}

}  // namespace fa::editor
