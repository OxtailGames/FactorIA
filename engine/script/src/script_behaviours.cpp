// Behaviour lifecycle: creation from Script components, per-frame callbacks, collision/event dispatch.
#include <algorithm>
#include <format>

#include "fa/core/fs.h"
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
    JSValue idv = JS_NewString(ctx, id.c_str());
    JSValue pathv = JS_NewString(ctx, path.c_str());
    bool failed = false;
    JSValue instFn = JS_GetPropertyStr(ctx, hooks.get(), "instantiate");
    JSValue inst = call(path + "#constructor", id, instFn, hooks.get(), {cls, hv, propsV, idv, pathv}, &failed);
    JS_FreeValue(ctx, instFn);
    JS_FreeValue(ctx, cls);
    JS_FreeValue(ctx, hv);
    JS_FreeValue(ctx, propsV);
    JS_FreeValue(ctx, idv);
    JS_FreeValue(ctx, pathv);
    if (failed || !JS_IsObject(inst)) {
        JS_FreeValue(ctx, inst);
        b->loadFailed = true;
        return;
    }
    b->instance = JsVal(ctx, inst);
}

void Impl::start_behaviour(Behaviour& b) {
    if (b.started || b.dead || b.loadFailed || JS_IsUndefined(b.instance.get())) return;
    b.started = true;
    std::string id = host->world().alive(b.entity) ? host->world().id_of(b.entity) : std::string();
    JSValue r = call_method(b.path + "#onStart", id, b.instance.get(), "onStart", {});
    JS_FreeValue(ctx, r);
}

void Impl::construct_for(const std::vector<Entity>& entities) {
    if (!ctx || !initialized) return;
    World& W = host->world();
    for (Entity e : entities) {
        if (!W.alive(e) || byEntity.count(e.bits()) || W.pending_destroy(e)) continue;
        const Script* s = W.get<Script>(e);
        if (!s || !s->enabled || s->path.empty() || !W.active_in_hierarchy(e)) continue;
        std::string path = s->path;
        Json props = s->props;
        create_behaviour(e, path, props);
    }
}

void Impl::construct_all() { construct_for(host->world().entities_with(&World::type_of<Script>())); }

std::vector<std::string> Impl::check_props(const std::string& modulePath, const Json& props) {
    std::vector<std::string> out;
    auto norm = fs::normalize_checked(modulePath);
    if (!norm) return {norm.error().message};
    std::string path = *norm;
    if (!props.is_object() || props.empty()) return out;
    ScriptError detail;
    auto ns = import_module(path, &detail);
    if (!ns) return {ns.error().message};
    JsVal nsv(ctx, *ns);
    JsVal cls(ctx, JS_GetPropertyStr(ctx, nsv.get(), "default"));
    if (!JS_IsFunction(ctx, cls.get())) return {"module '" + path + "' has no default export class (export default class X extends Behaviour)"};
    JsVal propsV(ctx, from_json(props));
    JsVal pathV(ctx, JS_NewString(ctx, path.c_str()));
    JsVal fn(ctx, JS_GetPropertyStr(ctx, hooks.get(), "checkProps"));
    bool failed = false;
    JSValue r = call("checking props of " + path, "", fn.get(), hooks.get(), {cls.get(), propsV.get(), pathV.get()}, &failed);
    JsVal res(ctx, r);
    int64_t n = 0;
    if (!failed && JS_IsArray(res.get())) JS_GetLength(ctx, res.get(), &n);
    for (int64_t i = 0; i < n; ++i) {
        JsVal item(ctx, JS_GetPropertyUint32(ctx, res.get(), static_cast<uint32_t>(i)));
        if (JS_IsString(item.get())) {
            const char* c = JS_ToCString(ctx, item.get());
            if (c) { out.emplace_back(c); JS_FreeCString(ctx, c); }
        }
    }
    return out;
}

std::vector<std::string> Impl::check_hooks(const std::string& modulePath) {
    auto norm = fs::normalize_checked(modulePath);
    if (!norm) return {};
    auto ns = import_module(*norm, nullptr);
    if (!ns) return {};  // syntax errors are check_syntax's to report, load errors the game's
    JsVal nsv(ctx, *ns);
    JsVal cls(ctx, JS_GetPropertyStr(ctx, nsv.get(), "default"));
    JsVal fn(ctx, JS_GetPropertyStr(ctx, hooks.get(), "checkHooks"));
    bool failed = false;
    JsVal res(ctx, call("checking hooks of " + *norm, "", fn.get(), hooks.get(), {cls.get()}, &failed));
    std::vector<std::string> out;
    if (!failed)
        for (const Json& m : to_json(res.get()))
            if (m.is_string()) out.push_back(m.get<std::string>());
    return out;
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
    // onStart for everything constructed since the last sync (scene load, spawn), in creation order.
    for (size_t i = 0; i < behaviours.size(); ++i) {
        Behaviour& b = *behaviours[i];
        if (b.dead || b.started || b.loadFailed || JS_IsUndefined(b.instance.get())) continue;
        if (!W.alive(b.entity)) continue;
        start_behaviour(b);
    }
    compact();
    inSync = false;
}

void Impl::run_callbacks(const char* method, float dt, bool pausedOnly) {
    World& W = host->world();
    size_t n = behaviours.size();
    for (size_t i = 0; i < n && i < behaviours.size(); ++i) {
        Behaviour& b = *behaviours[i];
        if (b.dead || b.faulted || b.loadFailed || JS_IsUndefined(b.instance.get())) continue;
        if (!W.alive(b.entity)) continue;
        const Script* s = W.get<Script>(b.entity);
        if (!s || !s->enabled || !W.active_in_hierarchy(b.entity)) continue;
        if (!b.started) start_behaviour(b);  // spawned earlier this frame: onStart before its first callback
        JSValue en = JS_GetPropertyStr(ctx, b.instance.get(), "enabled");
        bool enabled = JS_IsUndefined(en) || JS_ToBool(ctx, en) > 0;
        JS_FreeValue(ctx, en);
        if (!enabled) continue;
        if (pausedOnly) {
            JSValue rp = JS_GetPropertyStr(ctx, b.instance.get(), "runWhilePaused");
            const bool runs = JS_ToBool(ctx, rp) > 0;
            JS_FreeValue(ctx, rp);
            if (!runs) continue;
        }
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
            if (!b->started) start_behaviour(*b);
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
