// Drag and drop: a press on a draggable widget that travels past its slop starts a drag; the drag reports where the pointer is and
// what is under it until the button is released. docs/MENUS.md, "Drag and drop". The events go to world.events().game like the
// other ui.* ones (ui.cpp); the click the release would make never happens because the press is dropped when the drag starts.
#include <algorithm>
#include <cmath>

#include "fa/core/log.h"
#include "fa/ui/ui.h"
#include "ui_internal.h"

namespace fa {

namespace {

constexpr float kDefaultSlop = 6.0f, kMaxSlop = 100.0f;

// Is `e` the entity `root` or below it?
bool at_or_under(const World& w, Entity e, Entity root) {
    for (; e; e = w.parent(e))
        if (e == root) return true;
    return false;
}

}  // namespace

std::optional<UiDragSpec> ui_drag_spec(const Json& d, std::string* error) {
    UiDragSpec spec;
    if (d.is_null() || (d.is_boolean() && !d.get<bool>())) return std::nullopt;
    if (d.is_boolean()) return spec;
    if (!d.is_object()) {
        if (error) *error = "draggable is false, true or an object {payload, slop}, got " + d.dump() + ". Write true, or {\"payload\": {\"worker\": 3}, \"slop\": 8}.";
        return std::nullopt;
    }
    for (auto it = d.begin(); it != d.end(); ++it) {
        if (it.key() == "payload") {
            spec.payload = it.value();
        } else if (it.key() == "slop") {
            if (!it.value().is_number() || !(it.value().get<double>() >= 0.0) || it.value().get<double>() > kMaxSlop) {
                if (error) *error = "draggable.slop is a number of pixels from 0 to 100, got " + it.value().dump() + ".";
                return std::nullopt;
            }
            spec.slop = it.value().get<float>();
        } else {
            if (error) *error = "draggable has no field '" + it.key() + "'; use payload and slop.";
            return std::nullopt;
        }
    }
    return spec;
}

void UiSystem::set_drop_target(Entity e, UiDropMode mode) {
    if (!e) {
        worldDrop_ = mode == UiDropMode::None ? UiDropMode::Accept : mode;
        return;
    }
    if (mode == UiDropMode::None) dropRules_.erase(e.bits());
    else dropRules_[e.bits()] = mode;
}

Json UiSystem::drag_json(const World& w) const {
    if (!drag_.active) return nullptr;
    return Json::object({{"id", drag_.sourceId},
                         {"payload", drag_.payload},
                         {"from", Json::array({drag_.from.x, drag_.from.y})},
                         {"x", drag_.pos.x},
                         {"y", drag_.pos.y},
                         {"target", drag_.target && w.alive(drag_.target) ? Json(w.id_of(drag_.target)) : Json(nullptr)},
                         {"accepts", drag_.accepts}});
}

void UiSystem::drag_emit(World& w, const char* name, const char* reason) {
    Json data = Json::object({{"id", drag_.sourceId},
                              {"payload", drag_.payload},
                              {"x", drag_.pos.x},
                              {"y", drag_.pos.y},
                              {"target", drag_.target && w.alive(drag_.target) ? Json(w.id_of(drag_.target)) : Json(nullptr)},
                              {"accepts", drag_.accepts}});
    if (reason) data["reason"] = reason;
    const Entity source = w.alive(drag_.source) ? drag_.source : kNullEntity;
    w.events().game.push_back(GameEvent{name, std::move(data), source});
}

void UiSystem::cancel_drag(World& w, const char* reason) {
    dragCand_ = kNullEntity;
    if (!drag_.active) return;
    if (drag_.started) drag_emit(w, "ui.dragStart");  // a drag that ends in the frame it began is still announced first
    drag_emit(w, "ui.dragCancel", reason);
    drag_ = DragState{};
    dragImage_ = kNullEntity;
}

void UiSystem::update_drag(World& w, Vec2 design, Vec2 mouse, bool down, bool pressed, bool released, const VisualMeasure&, bool navCancel) {
    // ---- a press that may become a drag: the nearest draggable widget at or above what is under the pointer
    if (pressed && !drag_.active) {
        dragCand_ = kNullEntity;
        for (Entity a = ui_widget_at(w, design, mouse, dragImage_); a; a = w.parent(a)) {
            const UiKind kind = ui_kind(w, a);
            if (kind == UiKind::Slider || kind == UiKind::TextField) break;  // they keep the pointer for themselves
            const UiControl* c = ui_control(w, a);
            if (c && !c->interactable) continue;
            std::string problem;
            if (ui_drag_spec(ui_box(w, a)->draggable, &problem)) {
                dragCand_ = a;
                dragCandFrom_ = mouse;
                break;
            }
            if (!problem.empty()) FA_WARN("ui", "'{}': {} The widget is not draggable until it is fixed.", w.id_of(a), problem);
        }
    }
    if (dragCand_) {
        if (!w.alive(dragCand_) || (!down && !released)) {
            dragCand_ = kNullEntity;
        } else if (const std::optional<UiDragSpec> spec = ui_drag_spec(ui_box(w, dragCand_)->draggable);
                   spec && distance(mouse, dragCandFrom_) >= spec->slop) {
            drag_ = DragState{};
            drag_.active = true;
            drag_.source = dragCand_;
            drag_.sourceId = w.id_of(dragCand_);
            drag_.payload = spec->payload;
            drag_.from = dragCandFrom_;
            drag_.pos = mouse;
            dragCand_ = kNullEntity;
            press_ = kNullEntity;  // no longer a press: the release makes no click or toggle
            hide_tooltip(w);
            drag_.started = true;
        }
    }
    if (!drag_.active) return;
    if (!w.alive(drag_.source) || !w.active_in_hierarchy(drag_.source)) {
        cancel_drag(w, "gone");
        return;
    }
    if (navCancel) {
        cancel_drag(w, "cancel");
        return;
    }

    // ---- what is under the pointer and whether it takes the drop
    drag_.pos = mouse;
    const Entity under = ui_widget_at(w, design, mouse, dragImage_);
    Entity target = under;
    UiDropMode mode = UiDropMode::None;
    bool ruled = false;
    for (Entity a = under; a && !ruled; a = w.parent(a)) {
        if (auto it = dropRules_.find(a.bits()); it != dropRules_.end()) {
            target = a;
            mode = it->second;
            ruled = true;
        }
    }
    if (!under) mode = worldDrop_, ruled = true;
    const Json info = Json::object({{"id", drag_.sourceId}, {"payload", drag_.payload}, {"x", mouse.x}, {"y", mouse.y}});
    bool accepts = false;
    if (ruled) {
        if (mode == UiDropMode::Accept) accepts = true;
        else if (mode == UiDropMode::Script) accepts = under ? (dropHooks_.widget && dropHooks_.widget(target, info)) : (dropHooks_.world && dropHooks_.world(info));
    }
    drag_.target = target;
    drag_.accepts = accepts;

    // ---- the drag image follows the pointer: its centre under it
    if (dragImage_ && w.alive(dragImage_) && w.active_in_hierarchy(dragImage_)) {
        if (const std::optional<Rect> r = ui_rect(w, dragImage_, design)) {
            const float k = ui_scale_clamped(w.ui_scale());
            if (Transform* t = w.get<Transform>(dragImage_)) {
                t->position.x += (mouse.x - r->w * 0.5f - r->x) / k;
                t->position.y += (mouse.y - r->h * 0.5f - r->y) / k;
            }
        }
    }

    if (drag_.started) {
        drag_.started = false;
        drag_emit(w, "ui.dragStart");
    } else if (!released && down && (mouse.x != lastDragPos_.x || mouse.y != lastDragPos_.y || target.bits() != lastDragTarget_ || accepts != lastDragAccepts_)) {
        drag_emit(w, "ui.dragOver");
    }
    lastDragPos_ = mouse;
    lastDragTarget_ = target.bits();
    lastDragAccepts_ = accepts;

    if (released || !down) {
        if (accepts) drag_emit(w, "ui.drop");
        else drag_emit(w, "ui.dragCancel", "rejected");
        drag_ = DragState{};
        dragImage_ = kNullEntity;
    }
}

}  // namespace fa
