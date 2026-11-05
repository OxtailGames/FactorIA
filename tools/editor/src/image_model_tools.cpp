// The Image panel's model, part 2: selections, brush strokes, fill, picker, move and transform. Every edit that is kept is one image.*
// command call (see image_model.h); what the canvas shows while a gesture goes on is made by the shared functions of
// fa/tooling/image_paint.h and pixel_art.h.
#include <algorithm>
#include <cmath>
#include <cstdio>

#include "image_model.h"

namespace fa::editor {

namespace {

std::string hex_of(const Color& c) {
    auto b = [](float v) { return int(std::lround(std::clamp(v, 0.f, 1.f) * 255)); };
    char buf[16];
    std::snprintf(buf, sizeof buf, "#%02x%02x%02x", b(c.r), b(c.g), b(c.b));
    return buf;
}

double quantize(double v) { return std::round(v * 100.0) / 100.0; }

ImageEditOutcome refuse(ImageModel& m, const std::string& why) {
    ImageEditOutcome e;
    e.ok = false;
    e.error = why;
    m.set_status(why);
    return e;
}

}  // namespace

// ---- selections ------------------------------------------------------------------------------------------------------------

void ImageModel::refresh_selection() {
    ImageSelection next;
    if (valid_) {
        if (auto s = read_image_selection(projectDir_, rel_, kSelectionName, doc_.width, doc_.height)) {
            const bool any = std::any_of(s->v.begin(), s->v.end(), [](std::uint8_t v) { return v != 0; });
            if (any) next = std::move(*s);
        }
    }
    if (next.w != selection_.w || next.h != selection_.h || next.v != selection_.v) {
        selection_ = std::move(next);
        ++selRev_;
    }
}

bool ImageModel::selection_bounds(int& x, int& y, int& w, int& h) const {
    if (selection_.empty()) return false;
    int x0 = selection_.w, y0 = selection_.h, x1 = -1, y1 = -1;
    for (int j = 0; j < selection_.h; ++j)
        for (int i = 0; i < selection_.w; ++i)
            if (selection_.at(i, j) >= 128) {
                x0 = std::min(x0, i);
                y0 = std::min(y0, j);
                x1 = std::max(x1, i);
                y1 = std::max(y1, j);
            }
    if (x1 < 0) return false;
    x = x0;
    y = y0;
    w = x1 - x0 + 1;
    h = y1 - y0 + 1;
    return true;
}

const std::vector<ImageEdge>& ImageModel::selection_edges() {
    if (edgesRev_ == selRev_) return edges_;
    edgesRev_ = selRev_;
    edges_.clear();
    edgesTruncated_ = false;
    if (selection_.empty()) return edges_;
    const int W = selection_.w, H = selection_.h;
    auto in = [&](int x, int y) { return selection_.at(x, y) >= 128; };
    auto push = [&](float x0, float y0, float x1, float y1) {
        if (edges_.size() >= kMaxEdges) {
            edgesTruncated_ = true;
            return;
        }
        edges_.push_back({x0, y0, x1, y1});
    };
    for (int y = 0; y <= H && !edgesTruncated_; ++y) {   // horizontal edges between row y-1 and row y, as runs
        int start = -1;
        int kind = 0;
        for (int x = 0; x <= W; ++x) {
            const int k = x < W ? (in(x, y) != in(x, y - 1) ? (in(x, y) ? 1 : 2) : 0) : 0;
            if (k != kind) {
                if (kind != 0) push(float(start), float(y), float(x), float(y));
                start = x;
                kind = k;
            }
        }
    }
    for (int x = 0; x <= W && !edgesTruncated_; ++x) {   // vertical edges between column x-1 and column x
        int start = -1;
        int kind = 0;
        for (int y = 0; y <= H; ++y) {
            const int k = y < H ? (in(x, y) != in(x - 1, y) ? (in(x, y) ? 1 : 2) : 0) : 0;
            if (k != kind) {
                if (kind != 0) push(float(x), float(start), float(x), float(y));
                start = y;
                kind = k;
            }
        }
    }
    return edges_;
}

ImageEditOutcome ImageModel::run_select(Json args, const std::string& label) { return run(label, {{"image.select", std::move(args)}}); }

ImageEditOutcome ImageModel::select_rect(int x, int y, int w, int h, SelectOp op) {
    const int x0 = std::max(0, x), y0 = std::max(0, y), x1 = std::min(doc_.width, x + w), y1 = std::min(doc_.height, y + h);
    if (x1 <= x0 || y1 <= y0) return refuse(*this, "The rectangle is outside the picture.");
    return run_select(Json::object({{"name", kSelectionName}, {"by", "rect"}, {"x", x0}, {"y", y0}, {"width", x1 - x0}, {"height", y1 - y0}, {"mode", select_op_name(op)}}),
                      "Select rectangle");
}

ImageEditOutcome ImageModel::select_ellipse(int x, int y, int w, int h, SelectOp op) {
    const int x0 = std::max(0, x), y0 = std::max(0, y), x1 = std::min(doc_.width, x + w), y1 = std::min(doc_.height, y + h);
    if (x1 <= x0 || y1 <= y0) return refuse(*this, "The ellipse is outside the picture.");
    return run_select(Json::object({{"name", kSelectionName}, {"by", "ellipse"}, {"x", x0}, {"y", y0}, {"width", x1 - x0}, {"height", y1 - y0}, {"mode", select_op_name(op)}}),
                      "Select ellipse");
}

ImageEditOutcome ImageModel::select_polygon(const std::vector<std::pair<double, double>>& points, SelectOp op) {
    if (points.size() < 3) return refuse(*this, "A polygon needs at least three corners.");
    Json pts = Json::array();
    for (const auto& p : points) pts.push_back(Json::array({quantize(p.first), quantize(p.second)}));
    return run_select(Json::object({{"name", kSelectionName}, {"by", "polygon"}, {"points", pts}, {"mode", select_op_name(op)}}), "Select polygon");
}

ImageEditOutcome ImageModel::select_wand(int x, int y, const ImageWandSettings& wand, SelectOp op) {
    if (x < 0 || y < 0 || x >= doc_.width || y >= doc_.height) return refuse(*this, "Click inside the picture.");
    return run_select(Json::object({{"name", kSelectionName}, {"by", "color"}, {"at", Json::array({x, y})}, {"tolerance", std::clamp(wand.tolerance, 0, 255)},
                                    {"contiguous", wand.contiguous}, {"mode", select_op_name(op)}}),
                      "Magic wand");
}

ImageEditOutcome ImageModel::select_all() { return run_select(Json::object({{"name", kSelectionName}, {"by", "all"}}), "Select all"); }

ImageEditOutcome ImageModel::deselect() {
    if (!has_selection()) return ImageEditOutcome{};
    return run_select(Json::object({{"name", kSelectionName}, {"clear", true}}), "Deselect");
}

ImageEditOutcome ImageModel::selection_grow(double px) {
    return run_select(Json::object({{"name", kSelectionName}, {"then", Json::array({Json::object({{"grow", px}})})}}), "Grow selection");
}
ImageEditOutcome ImageModel::selection_shrink(double px) {
    return run_select(Json::object({{"name", kSelectionName}, {"then", Json::array({Json::object({{"shrink", px}})})}}), "Shrink selection");
}
ImageEditOutcome ImageModel::selection_feather(double px) {
    return run_select(Json::object({{"name", kSelectionName}, {"then", Json::array({Json::object({{"feather", px}})})}}), "Feather selection");
}
ImageEditOutcome ImageModel::selection_invert() {
    return run_select(Json::object({{"name", kSelectionName}, {"then", Json::array({Json::object({{"invert", true}})})}}), "Invert selection");
}

// ---- brush strokes ---------------------------------------------------------------------------------------------------------

std::vector<PixelPoint> ImageModel::indexed_stamp(const std::vector<std::pair<double, double>>& points, double size) {
    std::vector<PixelPoint> centres;
    for (const auto& p : points) centres.push_back({int(std::floor(p.first)), int(std::floor(p.second))});
    const int n = std::max(1, int(std::lround(size)));
    std::vector<PixelPoint> offsets;   // the pixels one stamp covers, around (0, 0)
    const int lo = -((n - 1) / 2);
    for (int j = 0; j < n; ++j)
        for (int i = 0; i < n; ++i) {
            const double dx = (i + 0.5) - n / 2.0, dy = (j + 0.5) - n / 2.0;
            if (n <= 2 || dx * dx + dy * dy <= (n / 2.0) * (n / 2.0) + 1e-9) offsets.push_back({lo + i, lo + j});
        }
    std::set<PixelPoint> out;
    for (const PixelPoint& c : pixel_polyline(centres, false))
        for (const PixelPoint& o : offsets) out.insert({c.x + o.x, c.y + o.y});
    return std::vector<PixelPoint>(out.begin(), out.end());
}

bool ImageModel::begin_stroke(bool erase, const ImageBrushSettings& brush, double x, double y) {
    if (!valid_ || live_.kind != Live::Kind::None) return false;
    std::string why;
    if (!paintable(selected_, &why)) {
        status_ = why;
        return false;
    }
    const ImageLayer* l = layer(selected_);
    Live L;
    L.kind = Live::Kind::Stroke;
    L.layer = selected_;
    L.erase = erase;
    L.brush = brush;
    L.indexed = l->kind == ImageLayerKind::Indexed;
    if (L.indexed) {
        const ImageCelView v = image_layer_cel(*l, frame_);
        std::vector<std::string> rows = v.rows ? *v.rows : std::vector<std::string>{};
        const auto parent = parent_offset(selected_);
        if (!rows.empty()) {
            auto g = index_grid_from_rows(rows, doc_.palette.size());
            if (!g.ok()) {
                status_ = g.error().message;
                return false;
            }
            L.gridBase = std::move(*g);
        } else {
            L.gridBase = IndexGrid(l->width > 0 ? l->width : doc_.width, l->height > 0 ? l->height : doc_.height);
        }
        L.gridX = parent.first + v.x;
        L.gridY = parent.second + v.y;
        L.grid = L.gridBase;
    } else {
        auto b = open_image_edit_buffer(projectDir_, rel_, json_, selected_, frame_);
        if (!b.ok()) {
            status_ = b.error().message;
            return false;
        }
        L.base = std::move(*b);
        L.work = L.base.img;
        if (has_selection()) L.sel = selection_;
    }
    L.points.push_back({quantize(x), quantize(y)});
    live_ = std::move(L);
    if (live_.indexed) {
        const int value = live_.erase ? -1 : live_.brush.paletteIndex;
        for (const PixelPoint& p : indexed_stamp(live_.points, live_.brush.size)) live_.grid.set(p.x - live_.gridX, p.y - live_.gridY, value);
        live_.stale = false;
    }
    mark_dirty();
    return true;
}

void ImageModel::stroke_to(double x, double y) {
    if (live_.kind != Live::Kind::Stroke) return;
    const std::pair<double, double> p{quantize(x), quantize(y)};
    if (p == live_.points.back()) return;
    if (live_.indexed) {
        const int value = live_.erase ? -1 : live_.brush.paletteIndex;
        for (const PixelPoint& q : indexed_stamp({live_.points.back(), p}, live_.brush.size)) live_.grid.set(q.x - live_.gridX, q.y - live_.gridY, value);
        live_.stale = false;
    } else {
        live_.stale = true;
    }
    live_.points.push_back(p);
    mark_dirty();
}

void ImageModel::cancel_stroke() {
    if (live_.kind == Live::Kind::None) return;
    live_ = Live{};
    mark_dirty();
}

ImageEditOutcome ImageModel::end_stroke() {
    if (live_.kind != Live::Kind::Stroke) return ImageEditOutcome{};
    Live L = std::move(live_);
    live_ = Live{};
    const bool selected = L.sel.has_value();
    if (L.indexed) {
        Json px = Json::array();
        const Json value = L.erase || L.brush.paletteIndex < 0 ? Json(nullptr) : Json(L.brush.paletteIndex);
        for (const PixelPoint& p : indexed_stamp(L.points, L.brush.size)) px.push_back(Json::array({p.x, p.y, value}));
        return run(L.erase ? "Erase pixels" : "Draw pixels", {{"image.pixel", Json::object({{"layer", L.layer}, {"pixels", px}})}});
    }
    Json pts = Json::array();
    for (const auto& p : L.points) pts.push_back(Json::array({p.first, p.second}));
    Json stroke = Json::object({{"points", pts}, {"size", L.brush.size}, {"hardness", L.brush.hardness}, {"opacity", L.brush.opacity},
                                {"color", hex_of(L.brush.color)}, {"erase", L.erase}});
    Json args = Json::object({{"layer", L.layer}, {"strokes", Json::array({stroke})}});
    if (selected) args["selection"] = kSelectionName;
    return run(L.erase ? "Erase" : "Paint", {{"image.paint", args}});
}

ImageEditOutcome ImageModel::fill_at(int x, int y, const ImageBrushSettings& brush, int tolerance) {
    std::string why;
    if (!paintable(selected_, &why)) return refuse(*this, why);
    if (x < 0 || y < 0 || x >= doc_.width || y >= doc_.height) return refuse(*this, "Click inside the picture.");
    const ImageLayer* l = layer(selected_);
    const std::string path = selected_;
    if (l->kind == ImageLayerKind::Indexed) {
        Json value = brush.paletteIndex < 0 ? Json(nullptr) : Json(brush.paletteIndex);
        Json shape = Json::object({{"type", "fill"}, {"at", Json::array({x, y})}, {"color", value}});
        return run("Fill", {{"image.draw", Json::object({{"layer", path}, {"shapes", Json::array({shape})}})}});
    }
    auto b = open_image_edit_buffer(projectDir_, rel_, json_, path, frame_);
    if (!b.ok()) return refuse(*this, b.error().message);
    const Image& img = b->img;
    const int sx = x - b->ox, sy = y - b->oy;
    if (sx < 0 || sy < 0 || sx >= img.width || sy >= img.height) return refuse(*this, "That pixel is outside the layer.");
    auto px = [&](int i, int j) { return &img.rgba[(std::size_t(j) * img.width + i) * 4]; };
    auto distance = [&](const std::uint8_t* p, const std::uint8_t* q) {
        if (p[3] == 0 && q[3] == 0) return 0;
        return std::max({std::abs(p[0] - q[0]), std::abs(p[1] - q[1]), std::abs(p[2] - q[2]), std::abs(p[3] - q[3])});
    };
    const std::uint8_t target[4] = {px(sx, sy)[0], px(sx, sy)[1], px(sx, sy)[2], px(sx, sy)[3]};
    ImageSelection region(doc_.width, doc_.height, 0);
    std::vector<std::uint8_t> seen(std::size_t(img.width) * img.height, 0);
    std::vector<std::pair<int, int>> stack = {{sx, sy}};
    seen[std::size_t(sy) * img.width + sx] = 1;
    const int tol = std::clamp(tolerance, 0, 255);
    std::size_t count = 0;
    while (!stack.empty()) {
        const auto [i, j] = stack.back();
        stack.pop_back();
        if (distance(px(i, j), target) > tol) continue;
        const int cx = b->ox + i, cy = b->oy + j;
        if (cx >= 0 && cy >= 0 && cx < region.w && cy < region.h) {
            region.ref(cx, cy) = has_selection() ? selection_.at(cx, cy) : 255;
            if (region.at(cx, cy)) ++count;
        }
        const int nx[4] = {i - 1, i + 1, i, i}, ny[4] = {j, j, j - 1, j + 1};
        for (int k = 0; k < 4; ++k) {
            if (nx[k] < 0 || ny[k] < 0 || nx[k] >= img.width || ny[k] >= img.height) continue;
            std::uint8_t& s = seen[std::size_t(ny[k]) * img.width + nx[k]];
            if (s) continue;
            s = 1;
            stack.push_back({nx[k], ny[k]});
        }
    }
    if (count == 0) return refuse(*this, "Nothing to fill there: the area is outside the selection.");
    Json action = Json::object({{"type", "fill"}, {"color", hex_of(brush.color)}, {"opacity", brush.opacity}});
    Prepare prepare = [&](std::string& err, Calls&) {
        auto r = write_image_selection(projectDir_, rel_, "fill", region);
        if (!r.ok()) {
            err = r.error().message;
            return false;
        }
        return true;
    };
    return run("Fill", {{"image.edit", Json::object({{"selection", "fill"}, {"layer", path}, {"action", action}})},
                        {"image.select", Json::object({{"name", "fill"}, {"clear", true}})}},
               prepare);
}

std::optional<Color> ImageModel::pick_color(int x, int y) const {
    if (picture_.empty() || x < 0 || y < 0 || x >= picture_.width || y >= picture_.height) return std::nullopt;
    const std::uint8_t* p = &picture_.rgba[(std::size_t(y) * picture_.width + x) * 4];
    return Color{p[0] / 255.f, p[1] / 255.f, p[2] / 255.f, p[3] / 255.f};
}

int ImageModel::pick_index(int x, int y) const {
    const ImageLayer* l = layer(selected_);
    if (!l || l->kind != ImageLayerKind::Indexed) return -1;
    const ImageCelView v = image_layer_cel(*l, frame_);
    if (!v.rows) return -1;
    const auto parent = parent_offset(selected_);
    const int gx = x - parent.first - v.x, gy = y - parent.second - v.y;
    if (gy < 0 || std::size_t(gy) >= v.rows->size()) return -1;
    const std::string& row = (*v.rows)[std::size_t(gy)];
    if (gx < 0 || std::size_t(gx) >= row.size()) return -1;
    return std::max(-1, pixel_char_index(row[std::size_t(gx)]));
}

// ---- move ------------------------------------------------------------------------------------------------------------------

bool ImageModel::begin_move() {
    if (!valid_ || live_.kind != Live::Kind::None) return false;
    const ImageLayer* l = layer(selected_);
    if (!l) {
        status_ = "Select a layer first.";
        return false;
    }
    if (is_locked(selected_)) {
        status_ = "The layer is locked.";
        return false;
    }
    Live L;
    L.kind = Live::Kind::Move;
    L.layer = selected_;
    if (has_selection() && l->kind == ImageLayerKind::Pixels) {
        auto b = open_image_edit_buffer(projectDir_, rel_, json_, selected_, frame_);
        if (!b.ok()) {
            status_ = b.error().message;
            return false;
        }
        L.base = std::move(*b);
        L.patch = image_patch_extract(L.base.img, L.base.ox, L.base.oy, selection_);
        if (L.patch.img.empty()) {
            status_ = "The selection covers no pixel of the layer: select where the layer has pixels, or deselect to move the whole layer.";
            return false;
        }
        L.erased = L.base.img;
        image_patch_erase(L.erased, L.base.ox, L.base.oy, selection_);
        L.work = L.erased;
    } else {
        L.wholeLayer = true;
        L.layerX0 = l->x;
        L.layerY0 = l->y;
    }
    live_ = std::move(L);
    mark_dirty();
    return true;
}

void ImageModel::move_by(int dx, int dy) {
    if (live_.kind != Live::Kind::Move || (dx == 0 && dy == 0)) return;
    live_.moveDx += dx;
    live_.moveDy += dy;
    live_.stale = true;
    mark_dirty();
}

ImageEditOutcome ImageModel::end_move() {
    if (live_.kind != Live::Kind::Move) return ImageEditOutcome{};
    Live L = std::move(live_);
    live_ = Live{};
    mark_dirty();
    if (L.moveDx == 0 && L.moveDy == 0) return ImageEditOutcome{};
    if (L.wholeLayer) return set_layer(L.layer, Json::object({{"x", L.layerX0 + L.moveDx}, {"y", L.layerY0 + L.moveDy}}), "Move layer");
    return run("Move pixels", {{"image.edit", Json::object({{"selection", kSelectionName}, {"layer", L.layer},
                                                            {"action", Json::object({{"type", "move"}, {"dx", L.moveDx}, {"dy", L.moveDy}})}})}});
}

// ---- transform -------------------------------------------------------------------------------------------------------------

bool ImageModel::begin_transform() {
    if (!valid_ || live_.kind != Live::Kind::None) return false;
    const ImageLayer* l = layer(selected_);
    std::string why;
    if (!paintable(selected_, &why)) {
        status_ = why;
        return false;
    }
    if (l->kind != ImageLayerKind::Pixels) {
        status_ = "Transform works on the pixels of a pixels layer; convert the layer (image.layer.convert to pixels) first.";
        return false;
    }
    auto b = open_image_edit_buffer(projectDir_, rel_, json_, selected_, frame_);
    if (!b.ok()) {
        status_ = b.error().message;
        return false;
    }
    Live L;
    L.kind = Live::Kind::Transform;
    L.layer = selected_;
    L.base = std::move(*b);
    L.useAll = !has_selection();
    L.selAll = has_selection() ? selection_ : ImageSelection(doc_.width, doc_.height, 255);
    L.patch = image_patch_extract(L.base.img, L.base.ox, L.base.oy, L.selAll);
    if (L.patch.img.empty()) {
        status_ = "There are no pixels to transform: select where the layer has pixels.";
        return false;
    }
    L.erased = L.base.img;
    image_patch_erase(L.erased, L.base.ox, L.base.oy, L.selAll);
    L.work = L.erased;
    L.tf.active = true;
    L.tf.boxX = L.patch.x;
    L.tf.boxY = L.patch.y;
    L.tf.boxW = L.patch.img.width;
    L.tf.boxH = L.patch.img.height;
    L.tf.pivotX = L.patch.x + L.patch.img.width / 2.0;
    L.tf.pivotY = L.patch.y + L.patch.img.height / 2.0;
    L.tf.nearest = !doc_.palette.empty();
    live_ = std::move(L);
    update_live();
    mark_dirty();
    return true;
}

void ImageModel::set_transform(double scaleX, double scaleY, double rotate, bool flipH, bool flipV, int dx, int dy) {
    if (live_.kind != Live::Kind::Transform) return;
    TransformState& t = live_.tf;
    t.scaleX = std::clamp(scaleX, 0.01, 32.0);
    t.scaleY = std::clamp(scaleY, 0.01, 32.0);
    t.rotate = std::clamp(rotate, -3600.0, 3600.0);
    t.flipH = flipH;
    t.flipV = flipV;
    t.dx = dx;
    t.dy = dy;
    live_.stale = true;
    mark_dirty();
}

void ImageModel::set_transform_nearest(bool nearest) {
    if (live_.kind != Live::Kind::Transform) return;
    live_.tf.nearest = nearest;
    live_.stale = true;
    mark_dirty();
}

void ImageModel::cancel_transform() {
    if (live_.kind != Live::Kind::Transform) return;
    live_ = Live{};
    mark_dirty();
}

ImageEditOutcome ImageModel::apply_transform() {
    if (live_.kind != Live::Kind::Transform) return ImageEditOutcome{};
    Live L = std::move(live_);
    live_ = Live{};
    mark_dirty();
    const TransformState& t = L.tf;
    const bool identity = t.scaleX == 1 && t.scaleY == 1 && t.rotate == 0 && !t.flipH && !t.flipV;
    if (identity && t.dx == 0 && t.dy == 0) return ImageEditOutcome{};
    const std::string selection = L.useAll ? "all" : kSelectionName;
    Calls calls;
    if (t.dx != 0 || t.dy != 0)
        calls.push_back({"image.edit", Json::object({{"selection", selection}, {"layer", L.layer},
                                                     {"action", Json::object({{"type", "move"}, {"dx", t.dx}, {"dy", t.dy}})}})});
    if (!identity) {
        Json action = Json::object({{"type", "transform"}, {"scale", Json::array({t.scaleX, t.scaleY})}, {"rotate", t.rotate}, {"flipH", t.flipH},
                                    {"flipV", t.flipV}, {"filter", t.nearest ? "nearest" : "bilinear"},
                                    {"pivot", Json::array({t.pivotX + t.dx, t.pivotY + t.dy})}});
        calls.push_back({"image.edit", Json::object({{"selection", selection}, {"layer", L.layer}, {"action", action}})});
    }
    return run("Transform", std::move(calls));
}

}  // namespace fa::editor
