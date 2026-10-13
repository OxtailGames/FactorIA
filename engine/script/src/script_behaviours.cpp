// Behaviour lifecycle: creation from Script components, per-frame callbacks, collision/event dispatch.
#include <algorithm>
#include <format>

#include "fa/core/log.h"
#include "fa/scene/components.h"
#include "script_internal.h"

namespace fa {

using Impl = ScriptSystem::Impl;

Behaviour* Impl::find_behaviour(Entity e) {
    auto it = byEntity.find(e.bits());
    return it == byEntity.end() ? nullptr : it->second;
}

JSValue Impl::entity_object(Entity e) {
    JSValue h = JS_NewFloat64(ctx, static_cast<double>(e.bits()));
    JSValue fn = JS_GetPropertyStr(ctx, hooks.get(), "entity");
    JSValue r = JS_Call(ctx, fn, JS_UNDEFINED, 1, &h);
    JS_FreeValue(ctx, fn);
    JS_FreeValue(ctx, h);
    if (JS_IsException(r)) {
        report_pending_exception("", "entity wrapper");
        return JS_UNDEFINED;
    }
    return r;
}

void Impl::compact() {
    behaviours.erase(std::remove_if(behaviours.begin(), behaviours.end(), [](const auto& b) { return b->dead; }),
                     behaviours.end());
}

void Impl::destroy_behaviour(Behaviour& b, bool callOnDestroy) {
    if (b.dead) return;
    if (callOnDestroy && b.started && !JS_IsUndefined(b.instance.get()) && host->world().alive(b.entity)) {
        std::string id = host->world().id_of(b.entity);
        JSValue r = call_method(b.path + "#onDestroy", id, b.instance.get(), "onDestroy", {});
        JS_FreeValue(ctx, r);
    }
    JSValue h = JS_NewFloat64(ctx, static_cast<double>(b.entity.bits()));
    JSValue fn = JS_GetPropertyStr(ctx, hooks.get(), "dropOwner");
    JSValue r = JS_Call(ctx, fn, JS_UNDEFINED, 1, &h);
    JS_FreeValue(ctx, r);
    JS_FreeValue(ctx, fn);
    JS_FreeValue(ctx, h);
    b.dead = true;
    byEntity.erase(b.entity.bits());
    b.instance.reset();
}

void Impl::drop_all_behaviours() {
    for (auto& b : behaviours) b->dead = true;
    behaviours.clear();
    byEntity.clear();
}

void Impl::on_entity_destroyed(Entity e) {
    if (!ctx) return;
    World& W = host->world();
    std::string id = W.id_of(e);
    remember_destroyed(e, id);
    if (Behaviour* b = find_behaviour(e)) destroy_behaviour(*b, true);
    JSValue h = JS_NewFloat64(ctx, static_cast<double>(e.bits()));
    JSValue fn = JS_GetPropertyStr(ctx, hooks.get(), "entityDestroyed");
    JSValue r = JS_Call(ctx, fn, JS_UNDEFINED, 1, &h);
    JS_FreeValue(ctx, r);
    JS_FreeValue(ctx, fn);
    JS_FreeValue(ctx, h);
}

void Impl::create_behaviour(Entity e, const std::string& path, const Json& props) {
    World& W = host->world();
    std::string id = W.id_of(e);
    auto rec = std::make_unique<Behaviour>();
    rec->entity = e;
    rec->path = path;
    Behaviour* b = rec.get();
    behaviours.push_back(std::move(rec));
    byEntity[e.bits()] = b;

    auto fail = [&](ScriptError err) {
        err.entityId = id;
        record_error(std::move(err), path);
        b->loadFailed = true;
    };

    ScriptError detail;
    auto ns = import_module(path, &detail);
    if (!ns) {
        if (detail.message.empty()) {
            detail.message = ns.error().message;
            detail.file = path;
        }
        fail(detail);
        return;
    }
    JSValue nsv = *ns;
    JSValue cls = JS_GetPropertyStr(ctx, nsv, "default");
    JS_FreeValue(ctx, nsv);
    if (!JS_IsFunction(ctx, cls)) {
        JS_FreeValue(ctx, cls);
        ScriptError err;
        err.file = path;
        err.message = "module '" + path + "' has no default export class. Add: export default class MyScript extends Behaviour { ... }";
        fail(err);
        return;
    }
    JSValue isB = call_method("loading " + path, id, hooks.get(), "isBehaviourClass", {cls});
    bool okClass = JS_ToBool(ctx, isB) > 0;
    JS_FreeValue(ctx, isB);
    if (!okClass) {
        JS_FreeValue(ctx, cls);
        ScriptError err;
        err.file = path;
        err.message = "the default export of '" + path + "' must extend Behaviour. Write: import { Behaviour } from \"factoria\"; export default class X extends Behaviour { ... }";
        fail(err);
        return;
    }
    JSValue nameV = JS_GetPropertyStr(ctx, cls, "name");
    if (JS_IsString(nameV)) {
        const char* s = JS_ToCString(ctx, nameV);
        if (s) { b->className = s; JS_FreeCString(ctx, s); }
    }
    JS_FreeValue(ctx, nameV);

    JSValue propsV = from_json(props.is_object() ? props : Json::object());
    JSValue hv = JS_NewFloat64(ctx, static_cast<double>(e.bits()));
    bool failed = false;
    JSValue instFn = JS_GetPropertyStr(ctx, hooks.get(), "instantiate");
    JSValue inst = call(path + "#constructor", id, instFn, hooks.get(), {cls, hv, propsV}, &failed);
    JS_FreeValue(ctx, instFn);
    JS_FreeValue(ctx, cls);
    JS_FreeValue(ctx, hv);
    JS_FreeValue(ctx, propsV);
    if (failed || !JS_IsObject(inst)) {
        JS_FreeValue(ctx, inst);
        b->loadFailed = true;
        return;
    }
    b->instance = JsVal(ctx, inst);
    b->started = true;
    JSValue r = call_method(path + "#onStart", id, b->instance.get(), "onStart", {});
    JS_FreeValue(ctx, r);
}

void Impl::sync() {
    if (inSync || !ctx) return;
    inSync = true;
    World& W = host->world();
    for (size_t i = 0; i < behaviours.size(); ++i) {
        Behaviour& b = *behaviours[i];
        if (b.dead) continue;
        if (!W.alive(b.entity)) {
            destroy_behaviour(b, false);
            continue;
        }
        const Script* s = W.get<Script>(b.entity);
        if (!s || s->path != b.path) destroy_behaviour(b, true);
    }
    struct Pending {
        Entity e;
        std::string path;
        Json props;
    };
    std::vector<Pending> todo;
    W.each<Script>([&](Entity e, Script& s) {
        if (!s.enabled || s.path.empty() || !W.active_in_hierarchy(e)) return;
        if (byEntity.count(e.bits())) return;
        todo.push_back({e, s.path, s.props});
    });
    for (auto& p : todo) {
        if (!W.alive(p.e) || byEntity.count(p.e.bits())) continue;
        create_behaviour(p.e, p.path, p.props);
    }
    compact();
    inSync = false;
}

void Impl::run_callbacks(const char* method, float dt, bool) {
    World& W = host->world();
    size_t n = behaviours.size();
    for (size_t i = 0; i < n && i < behaviours.size(); ++i) {
        Behaviour& b = *behaviours[i];
        if (b.dead || b.faulted || b.loadFailed || JS_IsUndefined(b.instance.get())) continue;
        if (!W.alive(b.entity)) continue;
        const Script* s = W.get<Script>(b.entity);
        if (!s || !s->enabled || !W.active_in_hierarchy(b.entity)) continue;
        JSValue en = JS_GetPropertyStr(ctx, b.instance.get(), "enabled");
        bool enabled = JS_IsUndefined(en) || JS_ToBool(ctx, en) > 0;
        JS_FreeValue(ctx, en);
        if (!enabled) continue;
        bool failed = false;
        std::string label = b.path + "#" + method;
        JSValue r = call_method(label, W.id_of(b.entity), b.instance.get(), method, {JS_NewFloat64(ctx, dt)}, &failed);
        JS_FreeValue(ctx, r);
        if (failed && lastCallTimedOut) {
            b.faulted = true;
            log(LogLevel::Error, "script",
                "behaviour " + b.path + " on entity '" + W.id_of(b.entity) +
                    "' was disabled because it ran too long; fix the loop and save the file to reload it");
        }
    }
    compact();
}

void Impl::dispatch(const char* method, Entity self, std::initializer_list<JSValue> args) {
    Behaviour* b = find_behaviour(self);
    if (b && !b->dead && !b->faulted && !b->loadFailed && !JS_IsUndefined(b->instance.get())) {
        World& W = host->world();
        const Script* s = W.get<Script>(self);
        if (s && s->enabled && W.active_in_hierarchy(self)) {
            JSValue r = call_method(b->path + "#" + method, W.id_of(self), b->instance.get(), method, args);
            JS_FreeValue(ctx, r);
        }
    }
    for (JSValue a : args) JS_FreeValue(ctx, a);
}

void ScriptSystem::dispatch_events() {
    Impl& I = *impl_;
    if (!I.initialized) return;
    World& W = I.host->world();
    I.sync();
    for (int round = 0; round < 8; ++round) {
        auto cols = std::move(W.events().collisions);
        auto games = std::move(W.events().game);
        W.events().collisions.clear();
        W.events().game.clear();
        if (cols.empty() && games.empty()) break;
        JSContext* ctx = I.ctx;

        for (const CollisionEvent& ev : cols) {
            bool is2d = W.alive(ev.a) && (W.get<Collider2D>(ev.a) || W.get<RigidBody2D>(ev.a));
            if (!is2d && W.alive(ev.b)) is2d = W.get<Collider2D>(ev.b) != nullptr;
            const bool begin = ev.phase == CollisionEvent::Phase::Begin;
            const char* method = ev.trigger ? (begin ? "onTriggerEnter" : "onTriggerExit")
                                            : (begin ? "onCollisionEnter" : "onCollisionExit");
            for (int side = 0; side < 2; ++side) {
                Entity self = side == 0 ? ev.a : ev.b;
                Entity other = side == 0 ? ev.b : ev.a;
                if (!W.alive(self) || !W.alive(other)) continue;
                Behaviour* b = I.find_behaviour(self);
                if (!b || b->dead) continue;
                float sgn = side == 0 ? 1.0f : -1.0f;
                JSValue otherObj = I.entity_object(other);
                if (ev.trigger || !begin) {
                    I.dispatch(method, self, {otherObj});
                } else {
                    JSValue args[8] = {JS_NewBool(ctx, is2d),
                                       JS_NewFloat64(ctx, ev.point.x), JS_NewFloat64(ctx, ev.point.y), JS_NewFloat64(ctx, ev.point.z),
                                       JS_NewFloat64(ctx, ev.normal.x * sgn), JS_NewFloat64(ctx, ev.normal.y * sgn),
                                       JS_NewFloat64(ctx, ev.normal.z * sgn), JS_NewFloat64(ctx, ev.impulse)};
                    JSValue infoFn = JS_GetPropertyStr(ctx, I.hooks.get(), "makeInfo");
                    JSValue info = I.call("collision info", "", infoFn, I.hooks.get(),
                                          {args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7]});
                    JS_FreeValue(ctx, infoFn);
                    I.dispatch(method, self, {otherObj, info});
                }
            }
        }

        for (const GameEvent& ge : games) {
            JSValue data = ge.data.is_null() ? JS_UNDEFINED : I.from_json(ge.data);
            JSValue src = (!ge.source.is_null() && W.alive(ge.source)) ? I.entity_object(ge.source) : JS_NULL;
            JSValue name = JS_NewString(ctx, ge.name.c_str());
            {
                JSValue fn = JS_GetPropertyStr(ctx, I.hooks.get(), "emit");
                JSValue r = I.call("world.on(" + ge.name + ")", "", fn, I.hooks.get(), {name, data, src});
                JS_FreeValue(ctx, r);
                JS_FreeValue(ctx, fn);
            }
            // snapshot of entities with behaviours (callbacks may create/destroy)
            std::vector<Entity> targets;
            for (auto& b : I.behaviours)
                if (!b->dead) targets.push_back(b->entity);
            for (Entity t : targets) {
                if (!W.alive(t)) continue;
                I.dispatch("onEvent", t, {JS_DupValue(ctx, name), JS_DupValue(ctx, data), JS_DupValue(ctx, src)});
            }
            JS_FreeValue(ctx, name);
            JS_FreeValue(ctx, data);
            JS_FreeValue(ctx, src);
        }
    }
    if (!W.events().game.empty() || !W.events().collisions.empty()) {
        log(LogLevel::Warn, "script", "world events keep re-emitting events; dropping the remainder (check for an emit loop)");
    }
    W.events().clear();
    I.run_jobs();
    I.compact();
}

}  // namespace fa
