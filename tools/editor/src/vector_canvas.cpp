// The canvas of the Vector panel: the drawing rasterized by the engine (a texture made again whenever the SVG changes or, once the view stops
// moving, when it no longer covers what is on screen), the checkerboard, grid and guides, the selection with its transform box, the nodes
// and handles, the pen's path, and the mouse and keyboard of every tool. Every edit is made through VectorModel, which calls the vector.*
// commands, so nothing here knows how an SVG is written.
#include <algorithm>
#include <cmath>
#include <functional>

#include "editor_internal.h"
#include "ui_backend.h"

namespace fa::editor {

namespace {

constexpr double kPiD = 3.14159265358979323846;
constexpr float kMinZoom = 0.02f;
constexpr float kMaxZoom = 256.0f;
constexpr int kMaxTexture = 4096;
constexpr float kHit = 6.0f;          // pixels: how near the pointer must be to grab a node, a handle or a segment
constexpr float kBoxHandle = 4.5f;    // half the size of a transform handle, in pixels
constexpr int kMaxNodesShown = 4000;  // anchors drawn per frame

ImTextureRef texture_ref(const VectorTexture& t) { return ImTextureRef(ImTextureID(ui::texture_from_view(t.view, true))); }

double dist2(ImVec2 a, ImVec2 b) { return std::hypot(a.x - b.x, a.y - b.y); }

// The shapes whose nodes the Node tool edits: the selected shapes, and the shapes inside the selected groups.
std::vector<const VecItem*> node_shapes(const VectorModel& m) {
    std::vector<const VecItem*> out;
    const VecScene& sc = m.scene();
    std::function<void(const VecItem&)> add = [&](const VecItem& it) {
        if (!it.isGroup) {
            if (it.problem.empty() && !it.nodes.empty() && !it.locked && !it.lockedByAncestor) out.push_back(&it);
            return;
        }
        for (int c : it.children) add(sc.items[std::size_t(c)]);
    };
    for (int i : m.selected_items()) add(sc.items[std::size_t(i)]);
    return out;
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------------- the view --
ImVec2 Editor::vector_to_screen(VecPoint p) const {
    const VecRect cv = vector_.model ? vector_.model->scene().canvas : VecRect{};
    return ImVec2(vector_.canvasX + vector_.panX + float(p.x - cv.x0) * vector_.zoom, vector_.canvasY + vector_.panY + float(p.y - cv.y0) * vector_.zoom);
}

VecPoint Editor::vector_from_screen(ImVec2 p) const {
    const VecRect cv = vector_.model ? vector_.model->scene().canvas : VecRect{};
    const double z = std::max(vector_.zoom, 1e-6f);
    return VecPoint{(p.x - vector_.canvasX - vector_.panX) / z + cv.x0, (p.y - vector_.canvasY - vector_.panY) / z + cv.y0};
}

void Editor::vector_fit() {
    VectorUi& u = vector_;
    if (!u.model || !u.model->is_open() || u.canvasW < 8 || u.canvasH < 8) return;
    const VecRect cv = u.model->scene().canvas;
    const float iw = float(std::max(1e-3, cv.width())), ih = float(std::max(1e-3, cv.height()));
    u.zoom = std::clamp(std::min((u.canvasW - 32.0f) / iw, (u.canvasH - 32.0f) / ih), kMinZoom, kMaxZoom);
    u.panX = (u.canvasW - iw * u.zoom) * 0.5f;
    u.panY = (u.canvasH - ih * u.zoom) * 0.5f;
    u.viewMoving = true;
}

// ------------------------------------------------------------------------------------------------------------------ texture --
void Editor::vector_update_texture(VectorModel& m) {
    VectorUi& u = vector_;
    auto retire = [&](VectorTexture& t) {
        if (t.image || t.view) u.graveyard.push_back({t.image, t.view, uiFrame_});
        t = VectorTexture{};
    };
    if (u.viewMoving) u.idleFrames = 0;
    else ++u.idleFrames;
    u.viewMoving = false;
    if (!m.valid()) {
        retire(u.picture);
        return;
    }
    const VecRect cv = m.scene().canvas;
    // what is on screen of the canvas, in the drawing space
    const VecPoint tl = vector_from_screen(ImVec2(u.canvasX, u.canvasY));
    const VecPoint br = vector_from_screen(ImVec2(u.canvasX + u.canvasW, u.canvasY + u.canvasH));
    VecRect vis{std::max(cv.x0, tl.x), std::max(cv.y0, tl.y), std::min(cv.x1, br.x), std::min(cv.y1, br.y)};
    if (vis.x1 <= vis.x0 || vis.y1 <= vis.y0) return;   // the canvas is out of view: keep what there is
    const VectorTexture& pic = u.picture;
    const bool stale = pic.view == 0 || pic.revision != m.revision();
    const double eps = 1e-6;
    const bool covers = pic.view != 0 && pic.region.x0 <= vis.x0 + eps && pic.region.y0 <= vis.y0 + eps && pic.region.x1 >= vis.x1 - eps && pic.region.y1 >= vis.y1 - eps;
    const bool sharp = pic.view != 0 && std::abs(pic.zoom - u.zoom) <= 0.02f * u.zoom;
    if (!stale && (covers && sharp)) return;
    if (!stale && u.idleFrames < 6) return;   // the view is moving: the old picture is stretched until it stops
    // the part to make: what is on screen plus a quarter of it on each side, so a small pan does not need a new picture
    const double padX = vis.width() * 0.25, padY = vis.height() * 0.25;
    VecRect want{std::max(cv.x0, vis.x0 - padX), std::max(cv.y0, vis.y0 - padY), std::min(cv.x1, vis.x1 + padX), std::min(cv.y1, vis.y1 + padY)};
    double scale = u.zoom;
    const double longest = std::max(want.width(), want.height()) * scale;
    if (longest > kMaxTexture) scale *= kMaxTexture / longest;
    const int w = std::max(1, int(std::ceil(want.width() * scale))), h = std::max(1, int(std::ceil(want.height() * scale)));
    Result<Image> img = m.rasterize(&want, w, h);
    if (!img.ok()) {
        m.set_status("Cannot draw the picture: " + img.error().message);
        return;
    }
    retire(u.picture);
    VectorTexture t;
    if (ui::make_texture(img->width, img->height, img->rgba.data(), t.image, t.view)) {
        t.w = img->width;
        t.h = img->height;
        t.revision = m.revision();
        t.region = want;
        t.zoom = u.zoom;
        u.picture = t;
    }
}

// ---------------------------------------------------------------------------------------------------------------- drawing --
namespace {

void polyline_of(const VecSubpath& sub, std::vector<VecPoint>& out, int steps = 14) {
    out.clear();
    const int segs = vector_segment_count(sub);
    if (sub.nodes.empty()) return;
    out.push_back(sub.nodes[0].p);
    for (int s = 0; s < segs; ++s) {
        if (!vector_segment_is_curve(sub, s)) {
            const std::size_t next = std::size_t((s + 1) % int(sub.nodes.size()));
            out.push_back(sub.nodes[next].p);
            continue;
        }
        for (int i = 1; i <= steps; ++i) out.push_back(vector_segment_point(sub, s, double(i) / steps));
    }
}

}  // namespace

void Editor::vector_draw_overlay(VectorModel& m, ImDrawList* dl) {
    VectorUi& u = vector_;
    const VecScene& sc = m.scene();
    const bool editable = play_ == PlayState::Edit && m.valid();
    const ImVec2 cmin(u.canvasX, u.canvasY), cmax(u.canvasX + u.canvasW, u.canvasY + u.canvasH);
    const ImU32 blue = IM_COL32(60, 150, 255, 255);
    auto line2 = [&](ImVec2 a, ImVec2 b, ImU32 col, float w = 1.0f) {
        dl->AddLine(a, b, IM_COL32(0, 0, 0, 150), w + 2.0f);
        dl->AddLine(a, b, col, w);
    };
    auto S = [&](VecPoint p) { return vector_to_screen(p); };

    // ---- grid and guides
    const ImVec2 c0 = S({sc.canvas.x0, sc.canvas.y0}), c1 = S({sc.canvas.x1, sc.canvas.y1});
    if (m.snapping.grid && m.snapping.gridSize * u.zoom >= 5.0) {
        const double g = m.snapping.gridSize;
        const VecPoint tl = vector_from_screen(cmin), br = vector_from_screen(cmax);
        const double x0 = std::max(tl.x, sc.canvas.x0), x1 = std::min(br.x, sc.canvas.x1), y0 = std::max(tl.y, sc.canvas.y0), y1 = std::min(br.y, sc.canvas.y1);
        for (double x = std::ceil(x0 / g) * g; x <= x1 + 1e-9; x += g) dl->AddLine(S({x, y0}), S({x, y1}), IM_COL32(110, 160, 255, 60));
        for (double y = std::ceil(y0 / g) * g; y <= y1 + 1e-9; y += g) dl->AddLine(S({x0, y}), S({x1, y}), IM_COL32(110, 160, 255, 60));
    }
    if (m.snapping.guides) {
        for (double gx : m.guidesX) dl->AddLine(ImVec2(S({gx, 0}).x, cmin.y), ImVec2(S({gx, 0}).x, cmax.y), IM_COL32(40, 220, 220, 200));
        for (double gy : m.guidesY) dl->AddLine(ImVec2(cmin.x, S({0, gy}).y), ImVec2(cmax.x, S({0, gy}).y), IM_COL32(40, 220, 220, 200));
    }
    (void)c0;
    (void)c1;

    // ---- hover
    if (editable && u.drag == VectorUi::Drag::None && !u.hover.empty() && !m.is_selected(u.hover) && u.tool != VectorTool::Pen) {
        const int hi = sc.find(u.hover);
        if (hi >= 0 && sc.items[std::size_t(hi)].hasBounds) {
            const VecRect b = sc.items[std::size_t(hi)].bounds;
            dl->AddRect(S({b.x0, b.y0}), S({b.x1, b.y1}), IM_COL32(60, 150, 255, 150), 0.0f, 0, 1.0f);
        }
    }

    // ---- the selection: each item's box, and one transform box around them
    const std::vector<int> selected = m.selected_items();
    for (int i : selected) {
        const VecItem& it = sc.items[std::size_t(i)];
        if (!it.hasBounds) continue;
        const ImVec2 a = S({it.bounds.x0, it.bounds.y0}), b = S({it.bounds.x1, it.bounds.y1});
        if (selected.size() > 1 || u.tool != VectorTool::Select) dl->AddRect(a, b, IM_COL32(60, 150, 255, 140), 0.0f, 0, 1.0f);
        if (u.tool == VectorTool::Node && !it.isGroup) {
            // the outline the nodes belong to, so the path is visible over a fill that hides it
            std::vector<VecPoint> pts;
            for (const VecSubpath& sub : it.nodes) {
                polyline_of(sub, pts);
                std::vector<ImVec2> sp;
                for (VecPoint p : pts) sp.push_back(S(p));
                if (sp.size() >= 2) dl->AddPolyline(sp.data(), int(sp.size()), blue, sub.closed ? ImDrawFlags_Closed : 0, 1.5f);
            }
        }
    }
    VecRect box;
    if (u.tool == VectorTool::Select && m.selection_bounds(box, false) && u.drag != VectorUi::Drag::Create) {
        const ImVec2 a = S({box.x0, box.y0}), b = S({box.x1, box.y1});
        dl->AddRect(a, b, IM_COL32(0, 0, 0, 160), 0.0f, 0, 3.0f);
        dl->AddRect(a, b, blue, 0.0f, 0, 1.0f);
        if (editable) {
            for (int dy = -1; dy <= 1; ++dy)
                for (int dx = -1; dx <= 1; ++dx) {
                    if (dx == 0 && dy == 0) continue;
                    const ImVec2 s((a.x + b.x) * 0.5f + float(dx) * (b.x - a.x) * 0.5f, (a.y + b.y) * 0.5f + float(dy) * (b.y - a.y) * 0.5f);
                    dl->AddRectFilled(ImVec2(s.x - kBoxHandle, s.y - kBoxHandle), ImVec2(s.x + kBoxHandle, s.y + kBoxHandle), IM_COL32(255, 255, 255, 255));
                    dl->AddRect(ImVec2(s.x - kBoxHandle, s.y - kBoxHandle), ImVec2(s.x + kBoxHandle, s.y + kBoxHandle), IM_COL32(0, 0, 0, 255));
                }
        }
    }

    // ---- nodes and handles (Node tool)
    if (u.tool == VectorTool::Node) {
        int shown = 0;
        for (const VecItem* it : node_shapes(m)) {
            for (std::size_t si = 0; si < it->nodes.size(); ++si) {
                const VecSubpath& sub = it->nodes[si];
                for (std::size_t ni = 0; ni < sub.nodes.size() && shown < kMaxNodesShown; ++ni, ++shown) {
                    const VecNode& n = sub.nodes[ni];
                    const VectorNodeRef ref{it->ref, int(si), int(ni)};
                    const bool sel = m.node_selected(ref);
                    const ImVec2 p = S(n.p);
                    if (p.x < cmin.x - 20 || p.x > cmax.x + 20 || p.y < cmin.y - 20 || p.y > cmax.y + 20) continue;
                    if (sel) {
                        for (int which = 0; which < 2; ++which) {
                            if (!(which ? n.hasOut : n.hasIn)) continue;
                            const ImVec2 h = S(which ? n.out : n.in);
                            line2(p, h, IM_COL32(255, 200, 80, 255), 1.0f);
                            dl->AddCircleFilled(h, 4.0f, IM_COL32(255, 200, 80, 255));
                            dl->AddCircle(h, 4.0f, IM_COL32(0, 0, 0, 255));
                        }
                    }
                    const bool smooth = vector_node_kind(n) != VecNodeKind::Corner;
                    if (smooth) {
                        dl->AddCircleFilled(p, 4.5f, sel ? blue : IM_COL32(255, 255, 255, 255));
                        dl->AddCircle(p, 4.5f, IM_COL32(0, 0, 0, 255));
                    } else {
                        dl->AddRectFilled(ImVec2(p.x - 4, p.y - 4), ImVec2(p.x + 4, p.y + 4), sel ? blue : IM_COL32(255, 255, 255, 255));
                        dl->AddRect(ImVec2(p.x - 4, p.y - 4), ImVec2(p.x + 4, p.y + 4), IM_COL32(0, 0, 0, 255));
                    }
                }
            }
        }
    }

    // ---- the pen
    const VectorPen& pen = m.pen();
    if (pen.active && !pen.path.empty()) {
        const VecSubpath& sub = pen.path[0];
        std::vector<VecPoint> pts;
        polyline_of(sub, pts);
        std::vector<ImVec2> sp;
        for (VecPoint p : pts) sp.push_back(S(p));
        if (u.mouseInside && !sub.nodes.empty() && !pen.dragging) {
            // the rubber band to the pointer (a curve when the last node has a handle)
            VecSubpath preview = sub;
            VecNode next;
            next.p = u.mouse;
            preview.nodes.push_back(next);
            polyline_of(preview, pts);
            sp.clear();
            for (VecPoint p : pts) sp.push_back(S(p));
        }
        if (sp.size() >= 2) {
            dl->AddPolyline(sp.data(), int(sp.size()), IM_COL32(0, 0, 0, 255), 0, 3.0f);
            dl->AddPolyline(sp.data(), int(sp.size()), blue, 0, 1.5f);
        }
        for (std::size_t i = 0; i < sub.nodes.size(); ++i) {
            const VecNode& n = sub.nodes[i];
            const ImVec2 p = S(n.p);
            if (n.hasOut) {
                line2(p, S(n.out), IM_COL32(255, 200, 80, 255));
                line2(p, S(n.in), IM_COL32(255, 200, 80, 255));
                dl->AddCircleFilled(S(n.out), 3.5f, IM_COL32(255, 200, 80, 255));
                dl->AddCircleFilled(S(n.in), 3.5f, IM_COL32(255, 200, 80, 255));
            }
            const bool first = i == 0 && pen.continueShape.empty();
            dl->AddRectFilled(ImVec2(p.x - 4, p.y - 4), ImVec2(p.x + 4, p.y + 4), first ? IM_COL32(255, 200, 80, 255) : IM_COL32(255, 255, 255, 255));
            dl->AddRect(ImVec2(p.x - 4, p.y - 4), ImVec2(p.x + 4, p.y + 4), IM_COL32(0, 0, 0, 255));
        }
    }

    // ---- shapes being dragged out and the marquee
    if (u.drag == VectorUi::Drag::Create && u.dragged) {
        const VecPoint a = u.press, b = u.current;
        const ImVec2 sa = S(a), sb = S(b);
        if (u.tool == VectorTool::Ellipse) {
            const ImVec2 c((sa.x + sb.x) / 2, (sa.y + sb.y) / 2), r(std::abs(sb.x - sa.x) / 2, std::abs(sb.y - sa.y) / 2);
            dl->AddEllipse(c, r, IM_COL32(0, 0, 0, 255), 0.0f, 48, 3.0f);
            dl->AddEllipse(c, r, IM_COL32(255, 255, 255, 255), 0.0f, 48, 1.0f);
        } else if (u.tool == VectorTool::Line || (u.tool == VectorTool::Shape && u.shapeKind == "arrow")) {
            line2(sa, sb, IM_COL32(255, 255, 255, 255), 1.0f);
        } else {
            dl->AddRect(sa, sb, IM_COL32(0, 0, 0, 255), 0.0f, 0, 3.0f);
            dl->AddRect(sa, sb, IM_COL32(255, 255, 255, 255), 0.0f, 0, 1.0f);
        }
    }
    if ((u.drag == VectorUi::Drag::Marquee || u.drag == VectorUi::Drag::NodeMarquee) && u.dragged) {
        const ImVec2 sa = S(u.press), sb = S(u.current);
        dl->AddRectFilled(sa, sb, IM_COL32(60, 150, 255, 30));
        dl->AddRect(sa, sb, blue);
    }
    if (u.drag == VectorUi::Drag::Rotate) {
        const ImVec2 c = S(u.dragAnchor);
        line2(c, S(u.current), IM_COL32(255, 200, 80, 255));
        dl->AddCircle(c, 4.0f, IM_COL32(255, 200, 80, 255));
    }

    // ---- the snap indicator
    if (u.snapShown && u.snapKind != VectorSnapKind::None) {
        const ImVec2 p = S(u.snapAt);
        const ImU32 col = u.snapKind == VectorSnapKind::Point ? IM_COL32(255, 80, 200, 255) : IM_COL32(40, 220, 220, 255);
        dl->AddCircle(p, 6.0f, col, 0, 1.5f);
        dl->AddLine(ImVec2(p.x - 10, p.y), ImVec2(p.x + 10, p.y), col);
        dl->AddLine(ImVec2(p.x, p.y - 10), ImVec2(p.x, p.y + 10), col);
    }
}

// --------------------------------------------------------------------------------------------------------------- the canvas --
void Editor::draw_vector_canvas(VectorModel& m, ImVec2 size) {
    VectorUi& u = vector_;
    const bool editable = play_ == PlayState::Edit && m.valid();
    ImGui::BeginChild("##veccanvas", size, false, ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse | ImGuiWindowFlags_NoMove);
    const ImVec2 origin = ImGui::GetCursorScreenPos();
    const ImVec2 avail = ImGui::GetContentRegionAvail();
    u.canvasX = origin.x;
    u.canvasY = origin.y;
    u.canvasW = avail.x;
    u.canvasH = avail.y;
    if (u.fitNext) {
        vector_fit();
        u.fitNext = false;
    }
    ImGui::InvisibleButton("##veccanvasbtn", ImVec2(std::max(1.0f, avail.x), std::max(1.0f, avail.y)),
                           ImGuiButtonFlags_MouseButtonLeft | ImGuiButtonFlags_MouseButtonRight | ImGuiButtonFlags_MouseButtonMiddle);
    at_track("vec:canvas");
    const bool hovered = ImGui::IsItemHovered();
    ImDrawList* dl = ImGui::GetWindowDrawList();
    const ImVec2 cmin(u.canvasX, u.canvasY), cmax(u.canvasX + u.canvasW, u.canvasY + u.canvasH);
    dl->AddRectFilled(cmin, cmax, IM_COL32(38, 38, 42, 255));
    dl->PushClipRect(cmin, cmax, true);

    vector_canvas_input(m, hovered, editable);
    vector_update_texture(m);

    const VecRect cv = m.scene().canvas;
    const ImVec2 p0 = vector_to_screen({cv.x0, cv.y0});
    const ImVec2 p1 = vector_to_screen({cv.x1, cv.y1});
    if (u.checker) {
        const float x0 = std::max(p0.x, cmin.x), y0 = std::max(p0.y, cmin.y), x1 = std::min(p1.x, cmax.x), y1 = std::min(p1.y, cmax.y);
        if (x1 > x0 && y1 > y0) {
            constexpr float cell = 12.0f;
            dl->AddRectFilled(ImVec2(x0, y0), ImVec2(x1, y1), IM_COL32(200, 200, 204, 255));
            const int ix0 = int(std::floor((x0 - p0.x) / cell)), iy0 = int(std::floor((y0 - p0.y) / cell));
            for (int iy = iy0; p0.y + float(iy) * cell < y1; ++iy) {
                int ix = ix0;
                if (((ix + iy) & 1) == 0) ++ix;
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
    if (u.picture.view) {
        const VecRect r = u.picture.region;
        dl->AddImage(texture_ref(u.picture), vector_to_screen({r.x0, r.y0}), vector_to_screen({r.x1, r.y1}));
    }
    dl->AddRect(p0, p1, IM_COL32(0, 0, 0, 160));
    vector_draw_overlay(m, dl);
    dl->PopClipRect();
    ImGui::EndChild();
}

// ------------------------------------------------------------------------------------------------------------------ input --
void Editor::vector_canvas_input(VectorModel& m, bool hovered, bool editable) {
    VectorUi& u = vector_;
    ImGuiIO& io = ImGui::GetIO();
    const ImVec2 mouseScreen = io.MousePos;
    const VecPoint f = vector_from_screen(mouseScreen);
    const VecRect cv = m.scene().canvas;
    u.mouse = f;
    u.mouseInside = hovered && f.x >= cv.x0 && f.y >= cv.y0 && f.x <= cv.x1 && f.y <= cv.y1;
    const bool keys = (u.focused || hovered) && !io.WantTextInput;
    const bool mod = io.KeyCtrl || io.KeySuper;
    const double z = std::max(double(u.zoom), 1e-6);
    const double tol = double(kHit) / z;          // a hit, in drawing units
    const double snapTol = 8.0 / z;

    // ---- the view: wheel and pan
    if (hovered) {
        auto zoom_around = [&](float factor) {
            const float nz = std::clamp(u.zoom * factor, kMinZoom, kMaxZoom);
            u.zoom = nz;
            u.panX = (mouseScreen.x - u.canvasX) - float(f.x - cv.x0) * nz;
            u.panY = (mouseScreen.y - u.canvasY) - float(f.y - cv.y0) * nz;
            u.viewMoving = true;
        };
        if (io.MouseWheel != 0 && (!io.KeyShift || mod)) zoom_around(std::pow(1.15f, io.MouseWheel));
        else if (io.MouseWheel != 0) {
            u.panX += io.MouseWheel * 40.0f;
            u.viewMoving = true;
        }
        if (io.MouseWheelH != 0) {
            u.panX += io.MouseWheelH * 40.0f;
            u.viewMoving = true;
        }
    }
    const bool down = ImGui::IsMouseDown(ImGuiMouseButton_Left);
    const bool downMiddle = ImGui::IsMouseDown(ImGuiMouseButton_Middle);
    const bool space = keys && ImGui::IsKeyDown(ImGuiKey_Space);
    if (u.drag == VectorUi::Drag::Pan) {
        if (down || downMiddle) {
            u.panX += io.MouseDelta.x;
            u.panY += io.MouseDelta.y;
            u.viewMoving = true;
        } else {
            u.drag = VectorUi::Drag::None;
        }
        return;
    }
    if (hovered && u.drag == VectorUi::Drag::None && (ImGui::IsMouseClicked(ImGuiMouseButton_Middle) || (space && ImGui::IsMouseClicked(ImGuiMouseButton_Left)))) {
        u.drag = VectorUi::Drag::Pan;
        return;
    }
    if (space) ImGui::SetMouseCursor(ImGuiMouseCursor_ResizeAll);

    if (!editable) {
        if (u.drag != VectorUi::Drag::None) {
            m.cancel_preview();
            u.drag = VectorUi::Drag::None;
        }
        u.hover.clear();
        return;
    }

    // the snapped pointer for the tools that snap
    auto snapped = [&](VecPoint p, const std::vector<std::string>& exclude) {
        VectorSnapKind kind = VectorSnapKind::None;
        const VecPoint s = m.snap_point(p, snapTol, exclude, &kind);
        u.snapShown = kind != VectorSnapKind::None;
        u.snapKind = kind;
        u.snapAt = s;
        return s;
    };
    const bool shift = io.KeyShift, alt = io.KeyAlt;

    // ---- a drag in progress
    if (u.drag != VectorUi::Drag::None) {
        const bool cancel = ImGui::IsKeyPressed(ImGuiKey_Escape, false);
        if (cancel) {
            m.cancel_preview();
            if (u.drag == VectorUi::Drag::Pen) m.pen_release();
            u.drag = VectorUi::Drag::None;
            u.snapShown = false;
            return;
        }
        if (!u.dragged && dist2(mouseScreen, ImVec2(u.pressScreenX, u.pressScreenY)) >= 3.0f) u.dragged = true;
        switch (u.drag) {
            case VectorUi::Drag::Marquee:
            case VectorUi::Drag::NodeMarquee:
                u.current = f;
                break;
            case VectorUi::Drag::Create: {
                VecPoint p = snapped(f, {});
                if (u.tool == VectorTool::Line || (u.tool == VectorTool::Shape && u.shapeKind == "arrow")) {
                    if (shift) {
                        const double dx = p.x - u.press.x, dy = p.y - u.press.y;
                        const double ang = std::round(std::atan2(dy, dx) / (kPiD / 4)) * (kPiD / 4), len = std::hypot(dx, dy);
                        p = {u.press.x + std::cos(ang) * len, u.press.y + std::sin(ang) * len};
                    }
                } else if (shift) {
                    const double dx = p.x - u.press.x, dy = p.y - u.press.y;
                    const double side = std::max(std::abs(dx), std::abs(dy));
                    p = {u.press.x + (dx < 0 ? -side : side), u.press.y + (dy < 0 ? -side : side)};
                }
                u.current = p;
                break;
            }
            case VectorUi::Drag::Pen: {
                if (u.dragged) m.pen_drag(snapped(f, {}));
                break;
            }
            case VectorUi::Drag::Move: {
                if (!u.dragged) break;
                VecPoint delta{f.x - u.press.x, f.y - u.press.y};
                if (shift) {
                    if (std::abs(delta.x) >= std::abs(delta.y)) delta.y = 0;
                    else delta.x = 0;
                }
                const VecPoint d = m.snap_move(u.dragBox, delta, snapTol, u.dragRefs);
                const VecPoint sd = shift ? VecPoint{delta.x == 0 ? 0 : d.x, delta.y == 0 ? 0 : d.y} : d;
                u.snapShown = false;
                u.applied = sd;
                m.preview_edit("vector.transform", Json::object({{"elements", Json(u.dragRefs)}, {"translate", Json::array({sd.x, sd.y})}}));
                break;
            }
            case VectorUi::Drag::Scale: {
                if (!u.dragged) break;
                const VecPoint p = snapped(f, u.dragRefs);
                const VecRect b = u.dragBox;
                const double hx = u.dirX < 0 ? b.x0 : b.x1, hy = u.dirY < 0 ? b.y0 : b.y1;   // the handle's own position
                double sx = 1, sy = 1;
                VecPoint about = u.dragAnchor;
                if (alt) about = b.center();
                if (u.dirX != 0 && std::abs(hx - about.x) > 1e-9) sx = (p.x - about.x) / (hx - about.x);
                if (u.dirY != 0 && std::abs(hy - about.y) > 1e-9) sy = (p.y - about.y) / (hy - about.y);
                if (shift && u.dirX != 0 && u.dirY != 0) {
                    const double s2 = std::abs(sx) > std::abs(sy) ? sx : sy;
                    sx = sy = s2;
                }
                auto fix = [](double s) { return std::abs(s) < 1e-3 ? (s < 0 ? -1e-3 : 1e-3) : s; };
                sx = fix(sx);
                sy = fix(sy);
                m.preview_edit("vector.transform",
                               Json::object({{"elements", Json(u.dragRefs)}, {"scale", Json::array({sx, sy})}, {"about", Json::array({about.x, about.y})}}));
                break;
            }
            case VectorUi::Drag::Rotate: {
                u.current = f;
                if (!u.dragged) break;
                double deg = (std::atan2(f.y - u.dragAnchor.y, f.x - u.dragAnchor.x) - u.startAngle) * 180.0 / kPiD;
                if (shift) deg = std::round(deg / 15.0) * 15.0;
                m.preview_edit("vector.transform", Json::object({{"elements", Json(u.dragRefs)}, {"rotate", deg}, {"about", Json::array({u.dragAnchor.x, u.dragAnchor.y})}}));
                break;
            }
            case VectorUi::Drag::NodeMove: {
                if (!u.dragged) break;
                VecPoint target{u.nodeStart.x + (f.x - u.press.x), u.nodeStart.y + (f.y - u.press.y)};
                if (shift) {
                    if (std::abs(target.x - u.nodeStart.x) >= std::abs(target.y - u.nodeStart.y)) target.y = u.nodeStart.y;
                    else target.x = u.nodeStart.x;
                }
                target = snapped(target, {u.nodeRef.shape});
                const VecPoint d{target.x - u.nodeStart.x, target.y - u.nodeStart.y};
                Json ops = Json::array();
                for (const VectorNodeRef& n : m.selected_nodes())
                    if (n.shape == u.nodeRef.shape)
                        ops.push_back(Json::object({{"op", "move"}, {"subpath", n.subpath}, {"node", n.node}, {"by", Json::array({d.x, d.y})}}));
                m.preview_node_ops(u.nodeRef.shape, ops);
                break;
            }
            case VectorUi::Drag::HandleMove: {
                if (!u.dragged) break;
                VecPoint target{u.nodeStart.x + (f.x - u.press.x), u.nodeStart.y + (f.y - u.press.y)};
                target = snapped(target, {u.nodeRef.shape});
                m.preview_node_ops(u.nodeRef.shape,
                                   Json::array({Json::object({{"op", "handle"}, {"subpath", u.nodeRef.subpath}, {"node", u.nodeRef.node}, {"which", u.handleOut ? "out" : "in"},
                                                              {"to", Json::array({target.x, target.y})}, {"link", alt ? "none" : "auto"}})}));
                break;
            }
            default: break;
        }
        if (down) return;

        // ---- the button went up
        const VectorUi::Drag d = u.drag;
        u.drag = VectorUi::Drag::None;
        u.snapShown = false;
        switch (d) {
            case VectorUi::Drag::Marquee: {
                if (!u.dragged) {
                    if (!u.shiftAtPress) m.clear_selection();
                    break;
                }
                const VecRect box{std::min(u.press.x, u.current.x), std::min(u.press.y, u.current.y), std::max(u.press.x, u.current.x), std::max(u.press.y, u.current.y)};
                // dragging to the left also picks what the box only touches
                const bool touch = u.current.x < u.press.x;
                std::vector<std::string> refs = u.shiftAtPress ? m.selection() : std::vector<std::string>{};
                for (int i : m.marquee(box, touch)) {
                    const std::string& r = m.scene().items[std::size_t(i)].ref;
                    if (std::find(refs.begin(), refs.end(), r) == refs.end()) refs.push_back(r);
                }
                m.select(refs);
                break;
            }
            case VectorUi::Drag::NodeMarquee: {
                if (!u.dragged) {
                    if (!u.shiftAtPress) m.select_nodes({});
                    break;
                }
                const VecRect box{std::min(u.press.x, u.current.x), std::min(u.press.y, u.current.y), std::max(u.press.x, u.current.x), std::max(u.press.y, u.current.y)};
                std::vector<VectorNodeRef> sel = u.shiftAtPress ? m.selected_nodes() : std::vector<VectorNodeRef>{};
                for (const VecItem* it : node_shapes(m))
                    for (std::size_t si = 0; si < it->nodes.size(); ++si)
                        for (std::size_t ni = 0; ni < it->nodes[si].nodes.size(); ++ni)
                            if (box.contains(it->nodes[si].nodes[ni].p)) {
                                const VectorNodeRef r{it->ref, int(si), int(ni)};
                                if (std::find(sel.begin(), sel.end(), r) == sel.end()) sel.push_back(r);
                            }
                m.select_nodes(sel);
                break;
            }
            case VectorUi::Drag::Create: {
                if (!u.dragged) break;
                VecPoint a = u.press, b = u.current;
                const bool line = u.tool == VectorTool::Line || (u.tool == VectorTool::Shape && u.shapeKind == "arrow");
                if (alt && !line) a = {2 * u.press.x - b.x, 2 * u.press.y - b.y};
                VectorEditOutcome out;
                if (u.tool == VectorTool::Rectangle) out = m.add_rect(a, b);
                else if (u.tool == VectorTool::Ellipse) out = m.add_ellipse(a, b);
                else if (u.tool == VectorTool::Line) out = m.add_line(a, b);
                else out = m.add_shape(u.shapeKind, a, b, Json::object());
                vector_edited(out);
                break;
            }
            case VectorUi::Drag::Pen:
                m.pen_release();
                break;
            case VectorUi::Drag::Move:
            case VectorUi::Drag::Scale:
            case VectorUi::Drag::Rotate:
                if (u.dragged && m.previewing()) vector_edited(m.commit_preview(d == VectorUi::Drag::Move ? "Move" : d == VectorUi::Drag::Scale ? "Scale" : "Rotate"));
                else m.cancel_preview();
                // a click without a drag on an already selected shape among several narrows the selection to it
                if (!u.dragged && d == VectorUi::Drag::Move && !u.shiftAtPress && m.selection().size() > 1) {
                    const int hit = m.pick(u.press, tol);
                    if (hit >= 0) m.select({m.scene().items[std::size_t(hit)].ref});
                }
                break;
            case VectorUi::Drag::NodeMove:
            case VectorUi::Drag::HandleMove:
                if (u.dragged && m.previewing()) vector_edited(m.commit_preview(d == VectorUi::Drag::NodeMove ? "Move nodes" : "Move handle"));
                else m.cancel_preview();
                break;
            default: break;
        }
        return;
    }

    // ---- hover
    u.hover.clear();
    if (hovered && (u.tool == VectorTool::Select || u.tool == VectorTool::Node)) {
        const int h = m.pick(f, tol);
        if (h >= 0) u.hover = m.scene().items[std::size_t(h)].ref;
    }

    // ---- a press
    const bool doubleClick = ImGui::IsMouseDoubleClicked(ImGuiMouseButton_Left);
    const bool clicked = hovered && (ImGui::IsMouseClicked(ImGuiMouseButton_Left) || doubleClick);
    if (clicked) {
        u.press = f;
        u.pressScreenX = mouseScreen.x;
        u.pressScreenY = mouseScreen.y;
        u.current = f;
        u.dragged = false;
        u.shiftAtPress = shift;
        switch (u.tool) {
            case VectorTool::Select: {
                // 1. the handles of the transform box
                VecRect box;
                if (m.selection_bounds(box, false) && !doubleClick) {
                    const ImVec2 a = vector_to_screen({box.x0, box.y0}), b = vector_to_screen({box.x1, box.y1});
                    int hitX = 99, hitY = 99;
                    bool rotate = false;
                    for (int dy = -1; dy <= 1 && hitX == 99; ++dy)
                        for (int dx = -1; dx <= 1; ++dx) {
                            if (dx == 0 && dy == 0) continue;
                            const ImVec2 s((a.x + b.x) * 0.5f + float(dx) * (b.x - a.x) * 0.5f, (a.y + b.y) * 0.5f + float(dy) * (b.y - a.y) * 0.5f);
                            if (dist2(mouseScreen, s) <= kBoxHandle + 3.0f) {
                                hitX = dx;
                                hitY = dy;
                                break;
                            }
                        }
                    if (hitX == 99) {
                        // just outside a corner: rotate
                        for (int dy = -1; dy <= 1; dy += 2)
                            for (int dx = -1; dx <= 1; dx += 2) {
                                const ImVec2 s((a.x + b.x) * 0.5f + float(dx) * (b.x - a.x) * 0.5f, (a.y + b.y) * 0.5f + float(dy) * (b.y - a.y) * 0.5f);
                                const float d = static_cast<float>(dist2(mouseScreen, s));
                                const bool outside = (mouseScreen.x - s.x) * float(dx) > 0 || (mouseScreen.y - s.y) * float(dy) > 0;
                                if (d > kBoxHandle + 3.0f && d <= 22.0f && outside) rotate = true;
                            }
                    }
                    if (hitX != 99 || rotate) {
                        u.dragRefs = m.selection();
                        u.dragBox = box;
                        u.drag = hitX != 99 ? VectorUi::Drag::Scale : VectorUi::Drag::Rotate;
                        if (hitX != 99) {
                            u.dirX = hitX;
                            u.dirY = hitY;
                            u.dragAnchor = {hitX < 0 ? box.x1 : (hitX > 0 ? box.x0 : box.center().x), hitY < 0 ? box.y1 : (hitY > 0 ? box.y0 : box.center().y)};
                        } else {
                            u.dragAnchor = box.center();
                            u.startAngle = std::atan2(f.y - u.dragAnchor.y, f.x - u.dragAnchor.x);
                        }
                        break;
                    }
                }
                // 2. a shape
                const int hit = m.pick(f, tol);
                if (doubleClick) {
                    if (hit >= 0 && m.scene().items[std::size_t(hit)].isGroup) m.enter_group(m.scene().items[std::size_t(hit)].ref);
                    else if (hit < 0) m.leave_group();
                    break;
                }
                if (hit >= 0) {
                    const std::string ref = m.scene().items[std::size_t(hit)].ref;
                    if (shift) {
                        m.toggle_selected(ref);
                        if (!m.is_selected(ref)) break;
                    } else if (!m.is_selected(ref)) {
                        m.select({ref});
                    }
                    u.dragRefs = m.selection();
                    VecRect b;
                    if (!m.selection_bounds(b, false)) break;
                    u.dragBox = b;
                    u.drag = VectorUi::Drag::Move;
                    u.applied = {0, 0};
                } else {
                    u.drag = VectorUi::Drag::Marquee;
                }
                break;
            }
            case VectorTool::Node: {
                const std::vector<const VecItem*> shapes = node_shapes(m);
                const ImVec2 ms = mouseScreen;
                // a handle of a selected node
                for (const VectorNodeRef& n : m.selected_nodes()) {
                    const VecNodePath* path = m.nodes_of(n.shape);
                    if (!path || n.subpath >= int(path->size()) || n.node >= int((*path)[std::size_t(n.subpath)].nodes.size())) continue;
                    const VecNode& node = (*path)[std::size_t(n.subpath)].nodes[std::size_t(n.node)];
                    for (int which = 0; which < 2; ++which) {
                        if (!(which ? node.hasOut : node.hasIn)) continue;
                        const VecPoint hp = which ? node.out : node.in;
                        if (dist2(ms, vector_to_screen(hp)) <= kHit) {
                            u.drag = VectorUi::Drag::HandleMove;
                            u.nodeRef = n;
                            u.handleOut = which == 1;
                            u.nodeStart = hp;
                            break;
                        }
                    }
                    if (u.drag != VectorUi::Drag::None) break;
                }
                if (u.drag != VectorUi::Drag::None) break;
                // an anchor
                for (const VecItem* it : shapes) {
                    for (std::size_t si = 0; si < it->nodes.size() && u.drag == VectorUi::Drag::None; ++si)
                        for (std::size_t ni = 0; ni < it->nodes[si].nodes.size(); ++ni) {
                            const VecNode& node = it->nodes[si].nodes[ni];
                            if (dist2(ms, vector_to_screen(node.p)) > kHit) continue;
                            const VectorNodeRef ref{it->ref, int(si), int(ni)};
                            if (doubleClick) {
                                // corner <-> smooth
                                const char* to = vector_node_kind(node) == VecNodeKind::Corner ? "smooth" : "corner";
                                vector_edited(m.node_ops(it->ref, Json::array({Json::object({{"op", "convert"}, {"subpath", int(si)}, {"node", int(ni)}, {"to", to}})}),
                                                         std::string("Make ") + to));
                                u.drag = VectorUi::Drag::None;
                                goto node_done;
                            }
                            if (shift) m.toggle_node(ref);
                            else if (!m.node_selected(ref)) m.select_nodes({ref});
                            if (!m.node_selected(ref)) goto node_done;
                            u.drag = VectorUi::Drag::NodeMove;
                            u.nodeRef = ref;
                            u.nodeStart = node.p;
                            break;
                        }
                    if (u.drag != VectorUi::Drag::None) break;
                }
                if (u.drag != VectorUi::Drag::None) break;
                // a segment: a double click adds a node there
                if (doubleClick) {
                    const VecItem* best = nullptr;
                    VecNearest bestN;
                    for (const VecItem* it : shapes) {
                        const VecNearest n = vector_nearest_on_path(it->nodes, f);
                        if (n.segment >= 0 && n.distance < bestN.distance) {
                            bestN = n;
                            best = it;
                        }
                    }
                    if (best && bestN.distance * z <= kHit * 1.5) {
                        vector_edited(m.node_ops(best->ref,
                                                 Json::array({Json::object({{"op", "insert"}, {"subpath", bestN.subpath}, {"segment", bestN.segment}, {"t", std::clamp(bestN.t, 1e-3, 1 - 1e-3)}})}),
                                                 "Add node"));
                        m.select_nodes({});
                        break;
                    }
                }
                // another shape, or nothing
                {
                    const int hit = m.pick(f, tol);
                    if (hit >= 0) {
                        const std::string ref = m.scene().items[std::size_t(hit)].ref;
                        if (shift) m.toggle_selected(ref);
                        else if (!m.is_selected(ref)) m.select({ref});
                        m.select_nodes({});
                    } else {
                        u.drag = VectorUi::Drag::NodeMarquee;
                    }
                }
            node_done:
                break;
            }
            case VectorTool::Pen: {
                if (m.pen().active && doubleClick) {
                    if (m.pen_can_finish()) vector_edited(m.pen_finish(false));
                    else m.pen_cancel();
                    break;
                }
                if (!m.pen().active) {
                    // continue the open path whose end is under the pointer
                    bool continued = false;
                    for (const VecItem* it : node_shapes(m)) {
                        for (std::size_t si = 0; si < it->nodes.size() && !continued; ++si) {
                            const VecSubpath& sub = it->nodes[si];
                            if (sub.closed || sub.nodes.size() < 1) continue;
                            for (int atEnd = 1; atEnd >= 0; --atEnd) {
                                const VecNode& n = atEnd ? sub.nodes.back() : sub.nodes.front();
                                if (dist2(mouseScreen, vector_to_screen(n.p)) <= kHit && m.pen_continue(it->ref, int(si), atEnd == 1)) {
                                    continued = true;
                                    break;
                                }
                            }
                        }
                        if (continued) break;
                    }
                    if (continued) break;
                }
                const VecPoint p = snapped(f, {});
                if (m.pen_press(p, tol)) vector_edited(m.pen_finish(true));
                else u.drag = VectorUi::Drag::Pen;
                break;
            }
            default: {
                u.press = snapped(f, {});
                u.current = u.press;
                u.drag = VectorUi::Drag::Create;
                break;
            }
        }
        if (u.drag == VectorUi::Drag::None) return;
    }

    // ---- the keyboard
    if (!keys) return;
    if (!mod && !alt) {
        const std::pair<ImGuiKey, VectorTool> hotkeys[] = {{ImGuiKey_V, VectorTool::Select}, {ImGuiKey_A, VectorTool::Node},      {ImGuiKey_P, VectorTool::Pen},
                                                           {ImGuiKey_R, VectorTool::Rectangle}, {ImGuiKey_O, VectorTool::Ellipse}, {ImGuiKey_L, VectorTool::Line},
                                                           {ImGuiKey_S, VectorTool::Shape}};
        for (const auto& [key, tool] : hotkeys)
            if (ImGui::IsKeyPressed(key, false) && tool != u.tool) {
                if (m.pen().active) {
                    if (m.pen_can_finish()) vector_edited(m.pen_finish(false));
                    else m.pen_cancel();
                }
                u.tool = tool;
            }
    }
    if (m.pen().active) {
        if (ImGui::IsKeyPressed(ImGuiKey_Enter, false) || ImGui::IsKeyPressed(ImGuiKey_KeypadEnter, false)) {
            if (m.pen_can_finish()) vector_edited(m.pen_finish(false));
            else m.pen_cancel();
        } else if (ImGui::IsKeyPressed(ImGuiKey_Escape, false)) {
            m.pen_cancel();
        }
        return;
    }
    if (ImGui::IsKeyPressed(ImGuiKey_Escape, false)) {
        if (!m.selected_nodes().empty()) m.select_nodes({});
        else if (!m.selection().empty()) m.clear_selection();
        else if (!m.context().empty()) m.leave_group();
    }
    if (ImGui::IsKeyPressed(ImGuiKey_Home, false)) u.fitNext = true;
    if (!m.valid()) return;
    if (ImGui::IsKeyPressed(ImGuiKey_Delete, false) || ImGui::IsKeyPressed(ImGuiKey_Backspace, false)) {
        if (u.tool == VectorTool::Node && !m.selected_nodes().empty()) {
            // the nodes of one shape per edit, the highest index first so the others keep their place
            std::vector<VectorNodeRef> sel = m.selected_nodes();
            const std::string shape = sel[0].shape;
            Json ops = Json::array();
            std::sort(sel.begin(), sel.end(), [](const VectorNodeRef& a, const VectorNodeRef& b) { return a.subpath != b.subpath ? a.subpath > b.subpath : a.node > b.node; });
            for (const VectorNodeRef& n : sel)
                if (n.shape == shape) ops.push_back(Json::object({{"op", "delete"}, {"subpath", n.subpath}, {"node", n.node}}));
            vector_edited(m.node_ops(shape, ops, "Delete nodes"));
            m.select_nodes({});
        } else if (!m.selection().empty()) {
            vector_edited(m.delete_selection());
        }
    }
    // nudges: 1 unit, 10 with Shift (a screen pixel at 100% zoom)
    {
        const double step = shift ? 10.0 : 1.0;
        double dx = 0, dy = 0;
        if (ImGui::IsKeyPressed(ImGuiKey_LeftArrow)) dx = -step;
        if (ImGui::IsKeyPressed(ImGuiKey_RightArrow)) dx = step;
        if (ImGui::IsKeyPressed(ImGuiKey_UpArrow)) dy = -step;
        if (ImGui::IsKeyPressed(ImGuiKey_DownArrow)) dy = step;
        if ((dx != 0 || dy != 0) && !mod) {
            if (u.tool == VectorTool::Node && !m.selected_nodes().empty()) {
                const std::string shape = m.selected_nodes()[0].shape;
                Json ops = Json::array();
                for (const VectorNodeRef& n : m.selected_nodes())
                    if (n.shape == shape) ops.push_back(Json::object({{"op", "move"}, {"subpath", n.subpath}, {"node", n.node}, {"by", Json::array({dx, dy})}}));
                vector_edited(m.node_ops(shape, ops, "Nudge nodes"));
            } else if (!m.selection().empty()) {
                vector_edited(m.move_selection(dx, dy));
            }
        }
    }
    if (mod) {
        if (ImGui::IsKeyPressed(ImGuiKey_A, false)) m.select_all();
        if (ImGui::IsKeyPressed(ImGuiKey_D, false) && !m.selection().empty()) vector_edited(m.duplicate_selection(10, 10));
        if (ImGui::IsKeyPressed(ImGuiKey_G, false) && !m.selection().empty()) vector_edited(shift ? m.ungroup_selection() : m.group_selection());
    }
}

}  // namespace fa::editor
