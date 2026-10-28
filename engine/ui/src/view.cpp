// Pointer events of a CameraView: what a script needs to turn, move or zoom what the view shows. docs/MENUS.md, "A camera inside
// the UI". The game event ui.viewPointer goes to world.events().game like the other ui.* ones (ui.cpp).
#include "fa/core/log.h"
#include "fa/ui/ui.h"
#include "ui_internal.h"

namespace fa {

namespace {

// One ui.viewPointer event. x, y: the pointer in design pixels; u, v: where it is in the view, 0..1 from the top-left corner
// (outside that range while a drag leaves the view); dx, dy: how far it moved since the last event of this press; wheel: the
// wheel steps of a "wheel" event (positive = away from the player, like input.mouse.wheel).
void send_view_event(World& w, Entity view, const char* phase, Vec2 pointer, Vec2 delta, float wheel, Vec2 design) {
    const Rect r = *ui_rect(w, view, design);
    const float u = r.w > 0 ? (pointer.x - r.x) / r.w : 0.0f, v = r.h > 0 ? (pointer.y - r.y) / r.h : 0.0f;
    w.events().game.push_back(GameEvent{"ui.viewPointer",
        Json::object({{"id", w.id_of(view)}, {"phase", phase}, {"x", pointer.x}, {"y", pointer.y}, {"u", u}, {"v", v},
                      {"dx", delta.x}, {"dy", delta.y}, {"wheel", wheel}}),
        view});
}

}  // namespace

// The press, the drag and the release of the primary pointer, and the wheel, over a CameraView. The widget under the pointer is
// the topmost one (ui_widget_at: a modal Panel and the clip of a ScrollList count), so a Button over the view keeps its click and
// a view below a modal Panel hears nothing. A press starts the drag of the view it landed on; it ends with the release, wherever
// the pointer is then. Called before the wheel scrolls lists: a view under the pointer takes the wheel for itself.
void UiSystem::update_view_pointer(World& w, Input& in, Vec2 design, Vec2 mouse, bool down, bool pressed, bool released) {
    if (viewDrag_ && (!w.alive(viewDrag_) || w.pending_destroy(viewDrag_) || !w.has<CameraView>(viewDrag_) || !w.active_in_hierarchy(viewDrag_))) viewDrag_ = kNullEntity;
    const Entity top = ui_widget_at(w, design, mouse, dragImage_);
    const CameraView* under = top && w.has<CameraView>(top) ? w.get<CameraView>(top) : nullptr;
    if (pressed && under && under->pointerEvents && !drag_.active) {
        viewDrag_ = top;
        viewLast_ = mouse;
        send_view_event(w, top, "down", mouse, Vec2{0, 0}, 0.0f, design);
    } else if (viewDrag_) {
        if (released || !down) {
            send_view_event(w, viewDrag_, "up", mouse, mouse - viewLast_, 0.0f, design);
            viewDrag_ = kNullEntity;
        } else if (mouse.x != viewLast_.x || mouse.y != viewLast_.y) {
            send_view_event(w, viewDrag_, "drag", mouse, mouse - viewLast_, 0.0f, design);
            viewLast_ = mouse;
        }
    }
    if (under && under->captureWheel && in.mouse_wheel() != 0.0f) {
        send_view_event(w, top, "wheel", mouse, Vec2{0, 0}, in.mouse_wheel(), design);
        wheelConsumed_ = true;
        in.consume_mouse_wheel();
    }
}

}  // namespace fa
