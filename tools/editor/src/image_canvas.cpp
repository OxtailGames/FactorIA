// The canvas of the Image panel: the composited picture (a texture made again whenever the model's picture changes), the checkerboard,
// the pixel grid, the selection, the transform handles, and the mouse and keyboard of every tool. All edits go through ImageModel, which
// calls the image.* commands, so nothing here knows how a pixel is painted.
#include <algorithm>
#include <cmath>

#include "editor_internal.h"
#include "ui_backend.h"

namespace fa::editor {

namespace {

constexpr double kPiD = 3.14159265358979323846;
constexpr float kMinZoom = 0.02f;
constexpr float kMaxZoom = 64.0f;
constexpr float kGridZoom = 8.0f;   // the pixel grid shows from 800%

ImTextureRef texture_ref(const ImageTexture& t, bool linear) {
    return ImTextureRef(ImTextureID(ui::texture_from_view(t.view, linear)));
}

// The rotation of the transform as a pair (cos, sin); positive degrees turn clockwise on the screen (y points down).
struct Rot {
    double c, s;
    explicit Rot(double degrees) : c(std::cos(degrees * kPiD / 180.0)), s(std::sin(degrees * kPiD / 180.0)) {}
    std::pair<double, double> apply(double x, double y) const { return {c * x - s * y, s * x + c * y}; }
    std::pair<double, double> inverse(double x, double y) const { return {c * x + s * y, -s * x + c * y}; }
};

// Where a point of the transform's box (offset from its centre, in the box's own pixels) lands in the image.
std::pair<double, double> transformed(const ImageModel::TransformState& t, double ox, double oy) {
    const Rot r(t.rotate);
    const double sx = (t.flipH ? -t.scaleX : t.scaleX) * ox, sy = (t.flipV ? -t.scaleY : t.scaleY) * oy;
    const auto p = r.apply(sx, sy);
    return {t.pivotX + t.dx + p.first, t.pivotY + t.dy + p.second};
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------- the view --
ImVec2 Editor::image_to_screen(float x, float y) const {
    return ImVec2(image_.canvasX + image_.panX + x * image_.zoom, image_.canvasY + image_.panY + y * image_.zoom);
}

ImVec2 Editor::image_from_screen(ImVec2 p) const {
    const float z = std::max(image_.zoom, 1e-6f);
    return ImVec2((p.x - image_.canvasX - image_.panX) / z, (p.y - image_.canvasY - image_.panY) / z);
}

void Editor::image_fit() {
    ImageUi& u = image_;
    if (!u.model || !u.model->is_open() || u.canvasW < 8 || u.canvasH < 8) return;
    const float repeat = u.tiled ? 3.0f : 1.0f;   // the tiled preview shows the picture three times across
    const float iw = float(std::max(1, u.model->width())) * repeat, ih = float(std::max(1, u.model->height())) * repeat;
    float z = std::min((u.canvasW - 24.0f) / iw, (u.canvasH - 24.0f) / ih);
    if (z >= 1.0f) z = std::floor(z);   // whole pixels when enlarging, so pixel art stays crisp
    u.zoom = std::clamp(z, kMinZoom, kMaxZoom);
    u.panX = (u.canvasW - iw * u.zoom) * 0.5f + (repeat - 1.0f) * 0.5f * float(u.model->width()) * u.zoom;
    u.panY = (u.canvasH - ih * u.zoom) * 0.5f + (repeat - 1.0f) * 0.5f * float(u.model->height()) * u.zoom;
}

// ------------------------------------------------------------------------------------------------------------ textures --
void Editor::image_update_textures(ImageModel& m) {
    ImageUi& u = image_;
    auto retire = [&](ImageTexture& t) {
        if (t.image || t.view) u.graveyard.push_back({t.image, t.view, uiFrame_});
        t = ImageTexture{};
    };
    const Image& pic = m.picture();
    if (!pic.empty() && (u.picture.view == 0 || u.picture.revision != m.revision() || u.picture.w != pic.width || u.picture.h != pic.height)) {
        retire(u.picture);
        ImageTexture t;
        if (ui::make_texture(pic.width, pic.height, pic.rgba.data(), t.image, t.view)) {
            t.w = pic.width;
            t.h = pic.height;
            t.revision = m.revision();
            u.picture = t;
        }
    }
    if (!m.tileset_layer() && u.terrain.view) retire(u.terrain);
    const bool wantTint = m.has_selection() && (u.tint || m.selection_edges_truncated());
    if (!wantTint) {
        if (u.selectionTint.view) retire(u.selectionTint);
        return;
    }
    const ImageSelection& sel = m.selection();
    if (u.selectionTint.view == 0 || u.selectionTint.revision != m.selection_revision() || u.selectionTint.w != sel.w || u.selectionTint.h != sel.h) {
        retire(u.selectionTint);
        u.tintBytes.assign(std::size_t(sel.w) * std::size_t(sel.h) * 4, 0);
        for (std::size_t i = 0; i < sel.v.size(); ++i) {
            u.tintBytes[i * 4 + 0] = 70;
            u.tintBytes[i * 4 + 1] = 140;
            u.tintBytes[i * 4 + 2] = 255;
            u.tintBytes[i * 4 + 3] = std::uint8_t(sel.v[i] * 90 / 255);
        }
        ImageTexture t;
        if (ui::make_texture(sel.w, sel.h, u.tintBytes.data(), t.image, t.view)) {
            t.w = sel.w;
            t.h = sel.h;
            t.revision = m.selection_revision();
            u.selectionTint = t;
        }
    }
}

// ------------------------------------------------------------------------------------------------------------- drawing --
void Editor::image_draw_selection(ImageModel& m, ImDrawList* dl) {
    ImageUi& u = image_;
    if (!m.has_selection()) return;
    const ImVec2 p0 = image_to_screen(0, 0);
    const ImVec2 p1 = image_to_screen(float(m.width()), float(m.height()));
    if (u.selectionTint.view) dl->AddImage(texture_ref(u.selectionTint, u.zoom < 1.0f), p0, p1);
    if (m.selection_edges_truncated()) return;   // too long to outline: the tint says it
    const std::vector<ImageEdge>& edges = m.selection_edges();
    const ImVec2 lo(u.canvasX - 4, u.canvasY - 4), hi(u.canvasX + u.canvasW + 4, u.canvasY + u.canvasH + 4);
    const bool crawl = edges.size() <= 3000;
    const float phase = float(std::fmod(u.antsPhase, 12.0));
    for (const ImageEdge& e : edges) {
        const ImVec2 a = image_to_screen(e.x0, e.y0), b = image_to_screen(e.x1, e.y1);
        if (std::max(a.x, b.x) < lo.x || std::min(a.x, b.x) > hi.x || std::max(a.y, b.y) < lo.y || std::min(a.y, b.y) > hi.y) continue;
        dl->AddLine(a, b, IM_COL32(0, 0, 0, 255), 1.0f);
        if (!crawl) {
            dl->AddLine(a, b, IM_COL32(255, 255, 255, 170), 1.0f);
            continue;
        }
        const float len = std::hypot(b.x - a.x, b.y - a.y);
        if (len < 0.5f) continue;
        const ImVec2 dir((b.x - a.x) / len, (b.y - a.y) / len);
        for (float s = -phase; s < len; s += 12.0f) {
            const float s0 = std::max(s, 0.0f), s1 = std::min(s + 6.0f, len);
            if (s1 > s0) dl->AddLine(ImVec2(a.x + dir.x * s0, a.y + dir.y * s0), ImVec2(a.x + dir.x * s1, a.y + dir.y * s1), IM_COL32(255, 255, 255, 255), 1.0f);
        }
    }
}

void Editor::image_draw_transform(ImageModel& m, ImDrawList* dl, bool editable) {
    (void)editable;
    if (!m.transforming()) return;
    const ImageModel::TransformState& t = m.transform();
    const double hw = t.boxW / 2.0, hh = t.boxH / 2.0;
    const double ox[4] = {-hw, hw, hw, -hw}, oy[4] = {-hh, -hh, hh, hh};
    ImVec2 c[4];
    for (int i = 0; i < 4; ++i) {
        const auto p = transformed(t, ox[i], oy[i]);
        c[i] = image_to_screen(float(p.first), float(p.second));
    }
    for (int i = 0; i < 4; ++i) {
        dl->AddLine(c[i], c[(i + 1) % 4], IM_COL32(0, 0, 0, 255), 3.0f);
        dl->AddLine(c[i], c[(i + 1) % 4], IM_COL32(255, 200, 80, 255), 1.5f);
    }
    for (int dy = -1; dy <= 1; ++dy)
        for (int dx = -1; dx <= 1; ++dx) {
            if (dx == 0 && dy == 0) continue;
            const auto p = transformed(t, dx * hw, dy * hh);
            const ImVec2 s = image_to_screen(float(p.first), float(p.second));
            dl->AddRectFilled(ImVec2(s.x - 4, s.y - 4), ImVec2(s.x + 4, s.y + 4), IM_COL32(255, 255, 255, 255));
            dl->AddRect(ImVec2(s.x - 4, s.y - 4), ImVec2(s.x + 4, s.y + 4), IM_COL32(0, 0, 0, 255));
        }
    const auto centre = transformed(t, 0, 0);
    const ImVec2 cs = image_to_screen(float(centre.first), float(centre.second));
    dl->AddCircle(cs, 4.0f, IM_COL32(255, 200, 80, 255));
}

void Editor::draw_image_canvas(ImageModel& m, ImVec2 size) {
    ImageUi& u = image_;
    const bool editable = play_ == PlayState::Edit && m.valid();
    ImGui::BeginChild("##imgcanvas", size, false, ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse | ImGuiWindowFlags_NoMove);
    const ImVec2 origin = ImGui::GetCursorScreenPos();
    const ImVec2 avail = ImGui::GetContentRegionAvail();
    u.canvasX = origin.x;
    u.canvasY = origin.y;
    u.canvasW = avail.x;
    u.canvasH = avail.y;
    if (u.fitNext) {
        image_fit();
        u.fitNext = false;
    }
    ImGui::InvisibleButton("##imgcanvasbtn", avail,
                           ImGuiButtonFlags_MouseButtonLeft | ImGuiButtonFlags_MouseButtonRight | ImGuiButtonFlags_MouseButtonMiddle);
    at_track("img:canvas");
    const bool hovered = ImGui::IsItemHovered();
    ImDrawList* dl = ImGui::GetWindowDrawList();
    const ImVec2 cmin(u.canvasX, u.canvasY), cmax(u.canvasX + u.canvasW, u.canvasY + u.canvasH);
    dl->AddRectFilled(cmin, cmax, IM_COL32(38, 38, 42, 255));
    dl->PushClipRect(cmin, cmax, true);

    image_canvas_input(m, hovered, editable);

    u.antsPhase += double(ImGui::GetIO().DeltaTime) * 14.0;
    image_update_textures(m);
    const ImVec2 p0 = image_to_screen(0, 0);
    const ImVec2 p1 = image_to_screen(float(m.width()), float(m.height()));
    if (u.checker) {
        // only the part of the picture that is on screen
        const float x0 = std::max(p0.x, cmin.x), y0 = std::max(p0.y, cmin.y), x1 = std::min(p1.x, cmax.x), y1 = std::min(p1.y, cmax.y);
        if (x1 > x0 && y1 > y0) {
            constexpr float cell = 12.0f;
            dl->AddRectFilled(ImVec2(x0, y0), ImVec2(x1, y1), IM_COL32(200, 200, 204, 255));
            const int ix0 = int(std::floor((x0 - p0.x) / cell)), iy0 = int(std::floor((y0 - p0.y) / cell));
            for (int iy = iy0; p0.y + float(iy) * cell < y1; ++iy) {
                int ix = ix0;
                if (((ix + iy) & 1) == 0) ++ix;   // the dark cells are the odd ones
                for (; p0.x + float(ix) * cell < x1; ix += 2) {
                    const float ax = std::max(p0.x + float(ix) * cell, x0), ay = std::max(p0.y + float(iy) * cell, y0);
                    const float bx = std::min(p0.x + float(ix + 1) * cell, x1), by = std::min(p0.y + float(iy + 1) * cell, y1);
                    if (bx > ax && by > ay) dl->AddRectFilled(ImVec2(ax, ay), ImVec2(bx, by), IM_COL32(150, 150, 156, 255));
                }
            }
        }
    } else {
        dl->AddRectFilled(p0, p1, IM_COL32(20, 20, 22, 255));
    }
    u.tiledDrawn = false;
    if (u.picture.view && u.tiled) {
        // the picture repeated around itself: a seam shows where one copy meets the next
        const float w = p1.x - p0.x, h = p1.y - p0.y;
        for (int ty = -1; ty <= 1; ++ty)
            for (int tx = -1; tx <= 1; ++tx) {
                if (tx == 0 && ty == 0) continue;
                const ImVec2 a(p0.x + float(tx) * w, p0.y + float(ty) * h), b(a.x + w, a.y + h);
                if (b.x < cmin.x || a.x > cmax.x || b.y < cmin.y || a.y > cmax.y) continue;
                dl->AddImage(texture_ref(u.picture, u.zoom < 1.0f), a, b);
            }
        u.tiledDrawn = true;
    }
    if (u.picture.view) dl->AddImage(texture_ref(u.picture, u.zoom < 1.0f), p0, p1);
    dl->AddRect(p0, p1, IM_COL32(0, 0, 0, 160));

    u.gridDrawn = false;
    if (u.showGrid && u.zoom >= kGridZoom) {
        const int gx0 = std::max(0, int(std::floor((cmin.x - p0.x) / u.zoom))), gx1 = std::min(m.width(), int(std::ceil((cmax.x - p0.x) / u.zoom)));
        const int gy0 = std::max(0, int(std::floor((cmin.y - p0.y) / u.zoom))), gy1 = std::min(m.height(), int(std::ceil((cmax.y - p0.y) / u.zoom)));
        // the stronger lines: the tiles of a tile document, else every gridMajor pixels
        const ImageTileMode& tm = m.doc().tile;
        const int majorX = tm.enabled && tm.width > 0 ? tm.width : u.gridMajor, majorY = tm.enabled && tm.height > 0 ? tm.height : u.gridMajor;
        for (int x = gx0; x <= gx1; ++x) {
            const bool major = majorX > 0 && x % majorX == 0;
            dl->AddLine(image_to_screen(float(x), float(gy0)), image_to_screen(float(x), float(gy1)), major ? IM_COL32(0, 0, 0, 150) : IM_COL32(0, 0, 0, 70));
        }
        for (int y = gy0; y <= gy1; ++y) {
            const bool major = majorY > 0 && y % majorY == 0;
            dl->AddLine(image_to_screen(float(gx0), float(y)), image_to_screen(float(gx1), float(y)), major ? IM_COL32(0, 0, 0, 150) : IM_COL32(0, 0, 0, 70));
        }
        u.gridDrawn = true;
    }

    image_draw_selection(m, dl);
    image_draw_transform(m, dl, editable);

    // what a drag or an open polygon is drawing
    const ImVec2 mouse = ImGui::GetIO().MousePos;
    if (u.drag == ImageUi::Drag::Rect || u.drag == ImageUi::Drag::Ellipse) {
        const ImVec2 a = image_to_screen(std::round(u.pressX), std::round(u.pressY));
        const ImVec2 cur = image_from_screen(mouse);
        const ImVec2 b = image_to_screen(std::round(cur.x), std::round(cur.y));
        if (u.drag == ImageUi::Drag::Rect) {
            dl->AddRect(a, b, IM_COL32(0, 0, 0, 255), 0, 0, 3.0f);
            dl->AddRect(a, b, IM_COL32(255, 255, 255, 255), 0, 0, 1.0f);
        } else {
            const ImVec2 c((a.x + b.x) / 2, (a.y + b.y) / 2), r(std::abs(b.x - a.x) / 2, std::abs(b.y - a.y) / 2);
            dl->AddEllipse(c, r, IM_COL32(0, 0, 0, 255), 0.0f, 48, 3.0f);
            dl->AddEllipse(c, r, IM_COL32(255, 255, 255, 255), 0.0f, 48, 1.0f);
        }
    }
    if ((u.drag == ImageUi::Drag::Lasso || u.polygonOpen) && u.points.size() >= 1) {
        std::vector<ImVec2> pts;
        for (const auto& p : u.points) pts.push_back(image_to_screen(float(p.first), float(p.second)));
        if (u.polygonOpen) pts.push_back(mouse);
        dl->AddPolyline(pts.data(), int(pts.size()), IM_COL32(0, 0, 0, 255), 0, 3.0f);
        dl->AddPolyline(pts.data(), int(pts.size()), IM_COL32(255, 255, 255, 255), 0, 1.0f);
        if (u.polygonOpen) dl->AddCircle(pts.front(), 5.0f, IM_COL32(255, 200, 80, 255));
    }
    // the pixel under the mouse for the tools that act on one pixel of a pixel-art document
    if (hovered && editable && !m.palette().empty() && u.mouseImageX >= 0 && u.drag == ImageUi::Drag::None &&
        (u.tool == ImageTool::Fill || u.tool == ImageTool::Picker || u.tool == ImageTool::Wand)) {
        const ImVec2 a = image_to_screen(u.mouseImageX, u.mouseImageY), b = image_to_screen(u.mouseImageX + 1, u.mouseImageY + 1);
        dl->AddRect(a, b, IM_COL32(0, 0, 0, 255), 0, 0, 2.0f);
        dl->AddRect(a, b, IM_COL32(255, 255, 255, 255));
    }
    // brush outline
    if (hovered && editable && (u.tool == ImageTool::Brush || u.tool == ImageTool::Eraser) && u.drag != ImageUi::Drag::Pan) {
        const bool indexed = !m.palette().empty() && m.layer(m.selected_layer()) && m.layer(m.selected_layer())->kind == ImageLayerKind::Indexed;
        const float r = std::max(1.0f, float(u.brush.size) * 0.5f * u.zoom);
        if (indexed) {
            const ImVec2 f = image_from_screen(mouse);
            const ImVec2 a = image_to_screen(std::floor(f.x), std::floor(f.y));
            const ImVec2 b = image_to_screen(std::floor(f.x) + 1, std::floor(f.y) + 1);
            dl->AddRect(a, b, IM_COL32(0, 0, 0, 255), 0, 0, 2.0f);
            dl->AddRect(a, b, IM_COL32(255, 255, 255, 255));
        } else {
            dl->AddCircle(mouse, r, IM_COL32(0, 0, 0, 200), 0, 2.0f);
            dl->AddCircle(mouse, r, IM_COL32(255, 255, 255, 230), 0, 1.0f);
        }
    }
    dl->PopClipRect();
    ImGui::EndChild();
}

// -------------------------------------------------------------------------------------------------------------- input --
void Editor::image_canvas_input(ImageModel& m, bool hovered, bool editable) {
    ImageUi& u = image_;
    ImGuiIO& io = ImGui::GetIO();
    const ImVec2 mouse = io.MousePos;
    const ImVec2 f = image_from_screen(mouse);
    const bool inside = f.x >= 0 && f.y >= 0 && f.x < float(m.width()) && f.y < float(m.height());
    u.mouseImageX = hovered && inside ? std::floor(f.x) : -1;
    u.mouseImageY = hovered && inside ? std::floor(f.y) : -1;
    const bool keys = (u.focused || hovered) && !io.WantTextInput;
    const bool mod = io.KeyCtrl || io.KeySuper;

    // ---- the view: wheel, pan
    if (hovered && !mod) {
        if (io.MouseWheel != 0 && !io.KeyShift) {
            const float before = u.zoom;
            const float z = std::clamp(before * std::pow(1.15f, io.MouseWheel), kMinZoom, kMaxZoom);
            u.zoom = z;
            u.panX = (mouse.x - u.canvasX) - f.x * z;
            u.panY = (mouse.y - u.canvasY) - f.y * z;
        } else if (io.MouseWheel != 0) {
            u.panX += io.MouseWheel * 40.0f;
        }
        if (io.MouseWheelH != 0) u.panX += io.MouseWheelH * 40.0f;
    } else if (hovered && mod && io.MouseWheel != 0) {   // a pinch arrives as Ctrl + wheel
        const float z = std::clamp(u.zoom * std::pow(1.15f, io.MouseWheel), kMinZoom, kMaxZoom);
        u.zoom = z;
        u.panX = (mouse.x - u.canvasX) - f.x * z;
        u.panY = (mouse.y - u.canvasY) - f.y * z;
    }

    // ---- a drag in progress
    const bool down = ImGui::IsMouseDown(u.dragButton == 1 ? ImGuiMouseButton_Right : ImGuiMouseButton_Left);
    const bool downMiddle = ImGui::IsMouseDown(ImGuiMouseButton_Middle);
    const auto sel_op = [&] {
        if (io.KeyShift && io.KeyAlt) return SelectOp::Intersect;
        if (io.KeyShift) return SelectOp::Add;
        if (io.KeyAlt) return SelectOp::Subtract;
        return u.selectOp;
    };
    const auto pick_at = [&](int px, int py) {
        if (px < 0 || py < 0 || px >= m.width() || py >= m.height()) return;
        const std::optional<Color> c = m.pick_color(px, py);
        if (c) {
            u.brush.color = *c;
            u.brush.color.a = std::max(u.brush.color.a, 0.0f);
        }
        const int idx = m.pick_index(px, py);
        if (idx >= 0) u.brush.paletteIndex = idx;
    };
    if (u.drag != ImageUi::Drag::None) {
        if (!editable && u.drag != ImageUi::Drag::Pan) {
            m.cancel_stroke();
            u.drag = ImageUi::Drag::None;
        } else if (u.drag == ImageUi::Drag::Pan) {
            if (down || downMiddle) {
                u.panX += io.MouseDelta.x;
                u.panY += io.MouseDelta.y;
            } else {
                u.drag = ImageUi::Drag::None;
            }
        } else if (ImGui::IsKeyPressed(ImGuiKey_Escape, false)) {
            if (u.drag == ImageUi::Drag::Stroke) m.cancel_stroke();
            u.points.clear();
            u.drag = ImageUi::Drag::None;
        } else if (!down) {
            const ImageUi::Drag d = u.drag;
            u.drag = ImageUi::Drag::None;
            switch (d) {
                case ImageUi::Drag::Stroke: m.stroke_to(f.x, f.y); image_edited(m.end_stroke()); break;
                case ImageUi::Drag::Move: image_edited(m.end_move()); break;
                case ImageUi::Drag::Rect:
                case ImageUi::Drag::Ellipse: {
                    const int x0 = int(std::lround(u.pressX)), y0 = int(std::lround(u.pressY));
                    const int x1 = int(std::lround(f.x)), y1 = int(std::lround(f.y));
                    const int x = std::min(x0, x1), y = std::min(y0, y1), w = std::abs(x1 - x0), h = std::abs(y1 - y0);
                    if (w == 0 || h == 0) {
                        if (u.dragOp == SelectOp::Replace && m.has_selection()) image_edited(m.deselect());
                    } else if (d == ImageUi::Drag::Rect) {
                        image_edited(m.select_rect(x, y, w, h, u.dragOp));
                    } else {
                        image_edited(m.select_ellipse(x, y, w, h, u.dragOp));
                    }
                    break;
                }
                case ImageUi::Drag::Lasso:
                    if (u.points.size() >= 3) image_edited(m.select_polygon(u.points, u.dragOp));
                    else if (u.dragOp == SelectOp::Replace && m.has_selection()) image_edited(m.deselect());
                    u.points.clear();
                    break;
                default: break;   // the transform drags keep their state in the model until Apply
            }
        } else {
            switch (u.drag) {
                case ImageUi::Drag::Stroke: m.stroke_to(f.x, f.y); break;
                case ImageUi::Drag::Move: {
                    const int dx = int(std::lround(f.x - u.pressX)), dy = int(std::lround(f.y - u.pressY));
                    m.move_by(dx - u.appliedDx, dy - u.appliedDy);
                    u.appliedDx = dx;
                    u.appliedDy = dy;
                    break;
                }
                case ImageUi::Drag::Lasso:
                    if (u.points.empty() || std::hypot(f.x - u.points.back().first, f.y - u.points.back().second) * u.zoom >= 3.0)
                        u.points.emplace_back(f.x, f.y);
                    break;
                case ImageUi::Drag::TransformMove: {
                    ImageModel::TransformState t = m.transform();
                    m.set_transform(t.scaleX, t.scaleY, t.rotate, t.flipH, t.flipV, u.tfStartDx + int(std::lround(f.x - u.pressX)),
                                    u.tfStartDy + int(std::lround(f.y - u.pressY)));
                    break;
                }
                case ImageUi::Drag::TransformScale: {
                    ImageModel::TransformState t = m.transform();
                    const Rot r(t.rotate);
                    const double cx = t.pivotX + t.dx, cy = t.pivotY + t.dy;
                    const auto local = r.inverse(f.x - cx, f.y - cy);
                    double sx = u.tfDirX != 0 ? std::max(0.01, std::abs(local.first) / std::max(1.0, t.boxW / 2.0)) : t.scaleX;
                    double sy = u.tfDirY != 0 ? std::max(0.01, std::abs(local.second) / std::max(1.0, t.boxH / 2.0)) : t.scaleY;
                    if (u.tfDirX != 0 && u.tfDirY != 0 && io.KeyShift) sx = sy = std::max(sx, sy);
                    m.set_transform(std::min(sx, 64.0), std::min(sy, 64.0), t.rotate, t.flipH, t.flipV, t.dx, t.dy);
                    break;
                }
                case ImageUi::Drag::TransformRotate: {
                    ImageModel::TransformState t = m.transform();
                    const double cx = t.pivotX + t.dx, cy = t.pivotY + t.dy;
                    const double ang = std::atan2(f.y - cy, f.x - cx) * 180.0 / kPiD;
                    double rot = u.tfStartRotate + (ang - u.tfStartAngle);
                    if (io.KeyShift) rot = std::round(rot / 15.0) * 15.0;
                    m.set_transform(t.scaleX, t.scaleY, rot, t.flipH, t.flipV, t.dx, t.dy);
                    break;
                }
                case ImageUi::Drag::Rect:
                case ImageUi::Drag::Ellipse:
                default: break;
            }
            if (u.drag == ImageUi::Drag::Rect || u.drag == ImageUi::Drag::Ellipse) u.dragOp = sel_op();
            if (u.drag == ImageUi::Drag::Lasso) u.dragOp = sel_op();
        }
    }

    // ---- keyboard
    if (keys && !mod && u.drag == ImageUi::Drag::None && editable) {
        auto pick_tool = [&](ImageTool t) {
            if (u.tool == ImageTool::Transform && t != ImageTool::Transform) m.cancel_transform();
            u.points.clear();
            u.polygonOpen = false;
            u.tool = t;
            if (t == ImageTool::Transform && !m.transforming()) m.begin_transform();
        };
        const bool shift = io.KeyShift;
        if (ImGui::IsKeyPressed(ImGuiKey_V, false)) pick_tool(ImageTool::Move);
        if (ImGui::IsKeyPressed(ImGuiKey_B, false)) pick_tool(ImageTool::Brush);
        if (ImGui::IsKeyPressed(ImGuiKey_E, false)) pick_tool(ImageTool::Eraser);
        if (ImGui::IsKeyPressed(ImGuiKey_G, false)) pick_tool(ImageTool::Fill);
        if (ImGui::IsKeyPressed(ImGuiKey_I, false)) pick_tool(ImageTool::Picker);
        if (ImGui::IsKeyPressed(ImGuiKey_M, false)) pick_tool(shift ? ImageTool::SelectEllipse : ImageTool::SelectRect);
        if (ImGui::IsKeyPressed(ImGuiKey_L, false)) pick_tool(shift ? ImageTool::SelectPolygon : ImageTool::SelectLasso);
        if (ImGui::IsKeyPressed(ImGuiKey_W, false)) pick_tool(ImageTool::Wand);
        if (ImGui::IsKeyPressed(ImGuiKey_T, false)) pick_tool(ImageTool::Transform);
        if (ImGui::IsKeyPressed(ImGuiKey_X, false)) {   // swap the primary and secondary colours
            std::swap(u.brush.paletteIndex, u.secondaryIndex);
            std::swap(u.brush.color, u.secondaryColor);
        }
        if (ImGui::IsKeyPressed(ImGuiKey_LeftBracket)) u.brush.size = std::max(1.0, std::floor(u.brush.size * 0.8 - 0.5));
        if (ImGui::IsKeyPressed(ImGuiKey_RightBracket)) u.brush.size = std::min(256.0, std::ceil(u.brush.size * 1.25 + 0.5));
        if (ImGui::IsKeyPressed(ImGuiKey_Escape, false)) {
            if (u.polygonOpen) {
                u.points.clear();
                u.polygonOpen = false;
            } else if (m.transforming()) {
                m.cancel_transform();
            }
        }
        if (ImGui::IsKeyPressed(ImGuiKey_Enter, false) || ImGui::IsKeyPressed(ImGuiKey_KeypadEnter, false)) {
            if (u.polygonOpen && u.points.size() >= 3) {
                image_edited(m.select_polygon(u.points, sel_op()));
                u.points.clear();
                u.polygonOpen = false;
            } else if (m.transforming()) {
                image_edited(m.apply_transform());
            }
        }
    }
    if (keys && mod && !io.WantTextInput && editable && u.drag == ImageUi::Drag::None) {
        if (ImGui::IsKeyPressed(ImGuiKey_A, false)) image_edited(m.select_all());
        if (ImGui::IsKeyPressed(ImGuiKey_D, false)) image_edited(m.deselect());
    }

    // ---- a button went down on the canvas
    if (!hovered || u.drag != ImageUi::Drag::None) return;
    if (ImGui::IsMouseClicked(ImGuiMouseButton_Middle) || (ImGui::IsMouseClicked(ImGuiMouseButton_Left) && ImGui::IsKeyDown(ImGuiKey_Space))) {
        u.dragButton = 0;
        u.drag = ImageUi::Drag::Pan;
        return;
    }
    // the right button paints with the secondary colour (brush, eraser and fill)
    const bool rightClick = ImGui::IsMouseClicked(ImGuiMouseButton_Right) &&
                            (u.tool == ImageTool::Brush || u.tool == ImageTool::Eraser || u.tool == ImageTool::Fill);
    if (!ImGui::IsMouseClicked(ImGuiMouseButton_Left) && !rightClick) return;
    u.playing = false;   // the timeline preview stops when you start to draw
    if (!editable) return;
    u.dragButton = rightClick && !ImGui::IsMouseClicked(ImGuiMouseButton_Left) ? 1 : 0;
    ImageBrushSettings brush = u.brush;
    if (u.dragButton == 1) {
        brush.color = u.secondaryColor;
        brush.paletteIndex = u.secondaryIndex;
    }
    std::string why;
    const std::string layerPath = m.selected_layer();
    const int px = int(std::floor(f.x)), py = int(std::floor(f.y));
    u.pressX = f.x;
    u.pressY = f.y;
    u.pressScreenX = mouse.x;
    u.pressScreenY = mouse.y;
    switch (u.tool) {
        case ImageTool::Brush:
        case ImageTool::Eraser:
            if (io.KeyAlt) {
                pick_at(px, py);
                break;
            }
            if (m.begin_stroke(u.tool == ImageTool::Eraser, brush, f.x, f.y)) u.drag = ImageUi::Drag::Stroke;
            break;
        case ImageTool::Fill:
            if (io.KeyAlt) pick_at(px, py);
            else if (inside) image_edited(m.fill_at(px, py, brush, u.wand.tolerance));
            break;
        case ImageTool::Picker: pick_at(px, py); break;
        case ImageTool::SelectRect:
            u.drag = ImageUi::Drag::Rect;
            u.dragOp = sel_op();
            break;
        case ImageTool::SelectEllipse:
            u.drag = ImageUi::Drag::Ellipse;
            u.dragOp = sel_op();
            break;
        case ImageTool::SelectLasso:
            u.drag = ImageUi::Drag::Lasso;
            u.dragOp = sel_op();
            u.points.clear();
            u.points.emplace_back(f.x, f.y);
            break;
        case ImageTool::SelectPolygon: {
            const bool closeNear = u.polygonOpen && u.points.size() >= 3 &&
                                   std::hypot(mouse.x - image_to_screen(float(u.points.front().first), float(u.points.front().second)).x,
                                              mouse.y - image_to_screen(float(u.points.front().first), float(u.points.front().second)).y) < 8.0f;
            if (closeNear || (u.polygonOpen && u.points.size() >= 3 && ImGui::IsMouseDoubleClicked(ImGuiMouseButton_Left))) {
                image_edited(m.select_polygon(u.points, sel_op()));
                u.points.clear();
                u.polygonOpen = false;
            } else {
                u.points.emplace_back(f.x, f.y);
                u.polygonOpen = true;
            }
            break;
        }
        case ImageTool::Wand:
            if (inside) image_edited(m.select_wand(px, py, u.wand, sel_op()));
            break;
        case ImageTool::Move:
            if (m.begin_move()) {
                u.drag = ImageUi::Drag::Move;
                u.appliedDx = u.appliedDy = 0;
            }
            break;
        case ImageTool::Transform: {
            if (!m.transforming() && !m.begin_transform()) break;
            const ImageModel::TransformState t = m.transform();
            u.tfStartScaleX = t.scaleX;
            u.tfStartScaleY = t.scaleY;
            u.tfStartRotate = t.rotate;
            u.tfStartDx = t.dx;
            u.tfStartDy = t.dy;
            const double cx = t.pivotX + t.dx, cy = t.pivotY + t.dy;
            u.tfStartAngle = std::atan2(f.y - cy, f.x - cx) * 180.0 / kPiD;
            const double hw = t.boxW / 2.0, hh = t.boxH / 2.0;
            // a handle first, then the inside of the box (move), then anywhere else (rotate)
            for (int dy = -1; dy <= 1 && u.drag == ImageUi::Drag::None; ++dy)
                for (int dx = -1; dx <= 1; ++dx) {
                    if (dx == 0 && dy == 0) continue;
                    const auto p = transformed(t, dx * hw, dy * hh);
                    const ImVec2 s = image_to_screen(float(p.first), float(p.second));
                    if (std::abs(s.x - mouse.x) <= 7 && std::abs(s.y - mouse.y) <= 7) {
                        u.drag = ImageUi::Drag::TransformScale;
                        u.tfDirX = dx;
                        u.tfDirY = dy;
                        break;
                    }
                }
            if (u.drag == ImageUi::Drag::None) {
                const Rot r(t.rotate);
                const auto local = r.inverse(f.x - cx, f.y - cy);
                const double sx = std::max(0.01, t.scaleX), sy = std::max(0.01, t.scaleY);
                u.drag = std::abs(local.first) <= hw * sx && std::abs(local.second) <= hh * sy ? ImageUi::Drag::TransformMove : ImageUi::Drag::TransformRotate;
            }
            break;
        }
    }
}

// ----------------------------------------------------------------------------------------------- terrain preview --
// A tileset document: a small map painted with its terrain (the engine's autotile rules choose each tile from its neighbours), drawn
// from the sheet the document shows, so a wrong edge or corner is seen in place.
void Editor::draw_image_terrain(ImageModel& m) {
    ImageUi& u = image_;
    u.terrainShown = false;
    if (!m.tileset_layer()) return;
    static const std::vector<std::string> kPattern = {
        "............",
        ".#####..##..",
        ".######.##..",
        ".#####..##..",
        ".##.##..###.",
        ".#####......",
        "..###..#.#..",
        "............",
    };
    if (!ImGui::CollapsingHeader("Terrain preview", ImGuiTreeNodeFlags_DefaultOpen)) return;
    at_track("img:terrain");
    if (u.terrain.view == 0 || u.terrain.revision != m.revision()) {
        Image pic = m.terrain_preview(kPattern);
        if (u.terrain.view || u.terrain.image) u.graveyard.push_back({u.terrain.image, u.terrain.view, uiFrame_});
        u.terrain = ImageTexture{};
        if (!pic.empty()) {
            ImageTexture t;
            if (ui::make_texture(pic.width, pic.height, pic.rgba.data(), t.image, t.view)) {
                t.w = pic.width;
                t.h = pic.height;
                t.revision = m.revision();
                u.terrain = t;
            }
        }
        if (u.terrain.view == 0) u.terrain.revision = m.revision();   // do not retry every frame
    }
    if (u.terrain.view == 0) {
        ImGui::TextDisabled("The sheet is not drawn yet: see the document's tileset layer.");
        return;
    }
    const float avail = std::max(32.0f, ImGui::GetContentRegionAvail().x);
    float scale = avail / float(u.terrain.w);
    if (scale >= 1.0f) scale = std::floor(scale);
    const ImVec2 size(float(u.terrain.w) * scale, float(u.terrain.h) * scale);
    const ImVec2 at = ImGui::GetCursorScreenPos();
    ImGui::Dummy(size);
    ImDrawList* dl = ImGui::GetWindowDrawList();
    dl->AddRectFilled(at, ImVec2(at.x + size.x, at.y + size.y), IM_COL32(38, 38, 42, 255));
    dl->AddImage(texture_ref(u.terrain, scale < 1.0f), at, ImVec2(at.x + size.x, at.y + size.y));
    u.terrainShown = true;
    ImGui::TextDisabled("Each '#' cell of this shape is a terrain cell; the tile is chosen by its neighbours like Tilemap's terrain paint does.");
}

}  // namespace fa::editor
