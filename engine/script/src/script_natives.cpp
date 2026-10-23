// Native functions exposed to the JavaScript prelude as the object `N`. Everything the engine offers to scripts
// goes through here; ergonomics (views, classes, timers, matchers) live in src/js/factoria.js.
#include <charconv>
#include <chrono>
#include <cmath>
#include <cstring>
#include <filesystem>
#include <format>
#include <fstream>
#include <sstream>

#include "fa/audio/audio.h"
#include "fa/core/fs.h"
#include "fa/core/image.h"
#include "fa/core/log.h"
#include "fa/core/notices.h"
#include "fa/core/strings.h"
#include "fa/platform/accessibility.h"
#include "fa/platform/input.h"
#include "fa/platform/system_language.h"
#include "fa/physics/physics.h"
#include "fa/render/renderer.h"
#include "fa/scene/animation.h"
#include "fa/scene/bounds.h"
#include "fa/scene/localize.h"
#include "fa/scene/text_fit.h"
#include "fa/scene/ui_rect.h"
#include "fa/scene/serialize.h"
#include "fa/scene/tilemap.h"
#include "fa/ui/ui.h"
#include "debugger_internal.h"
#include "script_internal.h"

namespace fa {

using Impl = ScriptSystem::Impl;

namespace {

Impl* impl_of(JSContext* ctx) { return static_cast<Impl*>(JS_GetContextOpaque(ctx)); }

// ---- small conversion helpers -------------------------------------------------------------------------------------
struct CStr {
    JSContext* ctx;
    size_t len = 0;
    const char* p;
    CStr(JSContext* c, JSValueConst v) : ctx(c), p(JS_ToCStringLen(c, &len, v)) {}
    ~CStr() { if (p) JS_FreeCString(ctx, p); }
    CStr(const CStr&) = delete;
    CStr& operator=(const CStr&) = delete;
    std::string str() const { return p ? std::string(p, len) : std::string(); }
    std::string_view view() const { return p ? std::string_view(p, len) : std::string_view(); }
};

JSValue throw_err(JSContext* ctx, const std::string& msg) { return JS_ThrowPlainError(ctx, "%s", msg.c_str()); }

double arg_num(JSContext* ctx, int argc, JSValueConst* argv, int i, double fallback = 0.0) {
    if (i >= argc || JS_IsUndefined(argv[i]) || JS_IsNull(argv[i])) return fallback;
    double d = fallback;
    JS_ToFloat64(ctx, &d, argv[i]);
    return d;
}

std::string arg_str(JSContext* ctx, int argc, JSValueConst* argv, int i) {
    if (i >= argc || JS_IsUndefined(argv[i]) || JS_IsNull(argv[i])) return {};
    CStr s(ctx, argv[i]);
    return s.str();
}

bool arg_bool(JSContext* ctx, int argc, JSValueConst* argv, int i, bool fallback = false) {
    if (i >= argc || JS_IsUndefined(argv[i])) return fallback;
    return JS_ToBool(ctx, argv[i]) > 0;
}

JSValue float_to_js(JSContext* ctx, float f) {
    if (!std::isfinite(f)) return JS_NewFloat64(ctx, f);
    if (f == std::floor(f) && std::fabs(f) < 1e9f) return JS_NewInt32(ctx, static_cast<int32_t>(f));
    char buf[64];
    auto r = std::to_chars(buf, buf + sizeof(buf), f);
    *r.ptr = 0;
    return JS_NewFloat64(ctx, std::strtod(buf, nullptr));
}

JSValue ent_val(JSContext* ctx, Entity e) {
    if (e.is_null()) return JS_NULL;
    return JS_NewFloat64(ctx, static_cast<double>(e.bits()));
}

Entity ent_from(JSContext* ctx, JSValueConst v) {
    if (JS_IsNull(v) || JS_IsUndefined(v)) return kNullEntity;
    double d = 0;
    JS_ToFloat64(ctx, &d, v);
    if (d < 0) return kNullEntity;
    return Entity::from_bits(static_cast<u64>(d));
}

JSValue array_of(JSContext* ctx, std::initializer_list<double> vals) {
    JSValue a = JS_NewArray(ctx);
    uint32_t i = 0;
    for (double v : vals) JS_SetPropertyUint32(ctx, a, i++, JS_NewFloat64(ctx, v));
    return a;
}

JSValue entities_array(JSContext* ctx, const std::vector<Entity>& list) {
    JSValue a = JS_NewArray(ctx);
    uint32_t i = 0;
    for (Entity e : list) JS_SetPropertyUint32(ctx, a, i++, ent_val(ctx, e));
    return a;
}

// Validates that the entity is alive; on failure throws the friendly "destroyed" error.
bool need_entity(Impl* I, JSContext* ctx, JSValueConst v, Entity& out, JSValue& exc) {
    out = ent_from(ctx, v);
    if (out.is_null()) {
        exc = throw_err(ctx, "expected an entity but got null/undefined");
        return false;
    }
    if (!I->host->world().alive(out)) {
        std::string id = I->destroyed_id(out);
        exc = throw_err(ctx, id.empty() ? std::string("entity was destroyed; check entity.alive before using it")
                                        : "entity '" + id + "' was destroyed; check entity.alive before using it");
        return false;
    }
    return true;
}

#define NATIVE(name) JSValue n_##name(JSContext* ctx, JSValueConst thisv, int argc, JSValueConst* argv)
#define SETUP                                          \
    Impl* I = impl_of(ctx);                            \
    World& W = I->host->world();                       \
    (void)I; (void)W; (void)thisv; (void)argc; (void)argv
#define ENTITY(var, idx)                                                                  \
    Entity var;                                                                           \
    {                                                                                     \
        JSValue exc_ = JS_UNDEFINED;                                                      \
        if (!need_entity(I, ctx, (idx) < argc ? argv[idx] : JS_UNDEFINED, var, exc_)) return exc_; \
    }

const TypeInfo* find_type(JSContext* ctx, const std::string& name, JSValue* exc) {
    const TypeInfo* t = TypeRegistry::global().find(name);
    if (!t) t = TypeRegistry::global().find_ci(name);
    if (!t) {
        std::string sug = TypeRegistry::global().suggest(name);
        *exc = throw_err(ctx, "unknown component '" + name + "'" +
                                  (sug.empty() ? std::string("; see `factoria api components`") : "; did you mean '" + sug + "'?"));
    }
    return t;
}

// Resolves (entity handle | -1 for scene settings, type index) to engine memory.
bool resolve_obj(Impl* I, JSContext* ctx, JSValueConst h, JSValueConst ti, void*& obj, const TypeInfo*& type,
                 Entity& ent, JSValue& exc) {
    World& W = I->host->world();
    double tid = 0;
    JS_ToFloat64(ctx, &tid, ti);
    type = TypeRegistry::global().get(static_cast<TypeId>(tid));
    if (!type) {
        exc = throw_err(ctx, "internal error: unknown component type index");
        return false;
    }
    double hd = 0;
    JS_ToFloat64(ctx, &hd, h);
    if (hd < 0) {
        obj = &W.settings();
        ent = kNullEntity;
        return true;
    }
    if (!need_entity(I, ctx, h, ent, exc)) return false;
    obj = W.get(ent, *type);
    if (!obj) {
        exc = throw_err(ctx, "entity '" + W.id_of(ent) + "' has no " + type->name +
                                 " component (it was removed, or never added: entity.add(\"" + type->name + "\"))");
        return false;
    }
    return true;
}

int float_count(FieldKind k) {
    switch (k) {
        case FieldKind::Vec2: return 2;
        case FieldKind::Vec3: return 3;
        case FieldKind::Vec4:
        case FieldKind::Color:
        case FieldKind::Rect: return 4;
        default: return 0;
    }
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------
// destroyed-id memory
// ---------------------------------------------------------------------------------------------------------------------
void Impl::remember_destroyed(Entity e, const std::string& id) {
    destroyedIds[e.bits()] = id;
    destroyedOrder.push_back(e.bits());
    if (destroyedOrder.size() > 8192) {
        for (size_t i = 0; i < 4096; ++i) destroyedIds.erase(destroyedOrder[i]);
        destroyedOrder.erase(destroyedOrder.begin(), destroyedOrder.begin() + 4096);
    }
}

std::string Impl::destroyed_id(Entity e) const {
    auto it = destroyedIds.find(e.bits());
    return it == destroyedIds.end() ? std::string() : it->second;
}

// ---------------------------------------------------------------------------------------------------------------------
// storage
// ---------------------------------------------------------------------------------------------------------------------
namespace {
// The path a damaged storage.json is kept at: storage.corrupt.json, or storage.corrupt.2.json, .3... when an earlier
// damaged start already left one (the first one is never replaced: it is usually the most informative).
std::filesystem::path corrupt_keep_path() {
    const std::filesystem::path dir = fs::user_dir();
    std::error_code ec;
    std::filesystem::path p = dir / "storage.corrupt.json";
    for (int n = 2; std::filesystem::exists(p, ec) && n < 1000; ++n) p = dir / ("storage.corrupt." + std::to_string(n) + ".json");
    return p;
}
}  // namespace

void Impl::load_storage() {
    if (storageLoaded) return;
    storageLoaded = true;
    storage = Json::object();
    storageCorrupt = false;
    const bool hooked = storageTextHook.has_value();
    if (storageMode == StorageMode::Memory && !hooked) return;
    const std::filesystem::path file = fs::user_dir() / "storage.json";
    std::string text;
    if (hooked) {
        text = *storageTextHook;
    } else {
        std::ifstream f(file, std::ios::binary);
        if (!f) return;  // no save yet
        std::stringstream ss;
        ss << f.rdbuf();
        text = ss.str();
    }
    Json j = Json::parse(text, nullptr, false);
    if (j.is_object()) {
        storage = std::move(j);
        return;
    }
    // Damaged. Keep the bytes: the next save would otherwise replace them with the new data.
    storageCorrupt = true;
    if (hooked) {  // a test: nothing is on disk to keep
        log(LogLevel::Warn, "script",
            "the text game.setStorageText gave does not parse: storage.corrupt is true and storage starts empty (a test never "
            "writes the real save)");
        return;
    }
    const std::filesystem::path keep = corrupt_keep_path();
    std::error_code ec;
    std::filesystem::rename(file, keep, ec);
    if (ec) {  // e.g. another volume: copy the bytes instead
        auto w = fs::write_bytes(keep.generic_string(), text.data(), text.size());
        if (!w) {
            log(LogLevel::Warn, "script", "storage.json does not parse and could not be kept as " + keep.string() + ": " + w.error().message +
                                              ". The next save will replace it; copy it by hand now if it matters.");
            return;
        }
    }
    fs::user_dir_changed();
    log(LogLevel::Warn, "script",
        "storage.json does not parse (damaged by a crash or a bad edit?); it was kept as " + keep.filename().string() + " in " +
            fs::user_dir().string() + " and the game starts with empty save data. A script can check storage.corrupt at start to tell the player.");
}

void Impl::save_storage() {
    if (storageMode == StorageMode::Memory) return;
    // Atomic (temporary file, then rename): a crash during the save leaves the previous storage.json intact.
    const std::string text = dump_json(storage);
    auto r = fs::write_bytes((fs::user_dir() / "storage.json").generic_string(), text.data(), text.size());
    if (!r) {
        log(LogLevel::Warn, "script", "cannot write storage.json in " + fs::user_dir().string() + ": " + r.error().message);
        return;
    }
    fs::user_dir_changed();  // the web build copies the save folder to the browser's storage
}

// ---------------------------------------------------------------------------------------------------------------------
// natives
// ---------------------------------------------------------------------------------------------------------------------
namespace {

// ---- logging / errors / guard -------------------------------------------------------------------------------------
NATIVE(log) {
    SETUP;
    int lvl = static_cast<int>(arg_num(ctx, argc, argv, 0, 2));
    std::string msg = arg_str(ctx, argc, argv, 1);
    fa::log(static_cast<LogLevel>(std::clamp(lvl, 0, 4)), "script", msg);
    if (I->debugger) I->debugger->impl().on_console(lvl, msg);  // the debug console shows it with its file and line
    return JS_UNDEFINED;
}

NATIVE(reportError) {
    SETUP;
    std::string owner = arg_str(ctx, argc, argv, 1);
    std::string where = arg_str(ctx, argc, argv, 2);
    ScriptError e = I->error_from_exception(argc > 0 ? argv[0] : JS_UNDEFINED, owner, where);
    I->record_error(std::move(e), where);
    return JS_UNDEFINED;
}

NATIVE(guardBegin) {
    SETUP;
    I->push_guard(arg_str(ctx, argc, argv, 0), arg_num(ctx, argc, argv, 1, 2.0));
    return JS_UNDEFINED;
}

NATIVE(guardEnd) {
    SETUP;
    I->pop_guard();
    return JS_UNDEFINED;
}

NATIVE(logSeq) {
    (void)thisv; (void)argc; (void)argv;
    return JS_NewFloat64(ctx, static_cast<double>(fa::log_last_seq()));
}

NATIVE(sourceCaret) {
    (void)thisv;
    return JS_NewString(ctx, source_caret(arg_str(ctx, argc, argv, 0), static_cast<int>(arg_num(ctx, argc, argv, 1, 0)),
                                          static_cast<int>(arg_num(ctx, argc, argv, 2, 0))).c_str());
}

NATIVE(nowMs) {
    auto t = std::chrono::steady_clock::now().time_since_epoch();
    return JS_NewFloat64(ctx, std::chrono::duration<double, std::milli>(t).count());
    (void)thisv; (void)argc; (void)argv;
}

// ---- reflection tables --------------------------------------------------------------------------------------------
NATIVE(types) {
    SETUP;
    JSValue arr = JS_NewArray(ctx);
    uint32_t i = 0;
    for (const TypeInfo* t : TypeRegistry::global().all()) {
        JSValue o = JS_NewObject(ctx);
        JS_SetPropertyStr(ctx, o, "id", JS_NewInt32(ctx, static_cast<int32_t>(t->id)));
        JS_SetPropertyStr(ctx, o, "name", JS_NewString(ctx, t->name.c_str()));
        JS_SetPropertyStr(ctx, o, "doc", JS_NewString(ctx, t->doc.c_str()));
        JS_SetPropertyStr(ctx, o, "category", JS_NewString(ctx, t->category.c_str()));
        JSValue fields = JS_NewArray(ctx);
        uint32_t fi = 0;
        for (const FieldInfo& f : t->fields) {
            JSValue fo = JS_NewObject(ctx);
            JS_SetPropertyStr(ctx, fo, "name", JS_NewString(ctx, f.name.c_str()));
            JS_SetPropertyStr(ctx, fo, "kind", JS_NewString(ctx, field_kind_name(f.kind)));
            JS_SetPropertyStr(ctx, fo, "doc", JS_NewString(ctx, f.doc.c_str()));
            JS_SetPropertyStr(ctx, fo, "readOnly", JS_NewBool(ctx, f.readOnly));
            JS_SetPropertyStr(ctx, fo, "asset", JS_NewString(ctx, f.assetType.c_str()));
            JSValue en = JS_NewArray(ctx);
            uint32_t ei = 0;
            for (const auto& n : f.enumNames) JS_SetPropertyUint32(ctx, en, ei++, JS_NewString(ctx, n.c_str()));
            JS_SetPropertyStr(ctx, fo, "enum", en);
            JS_SetPropertyUint32(ctx, fields, fi++, fo);
        }
        JS_SetPropertyStr(ctx, o, "fields", fields);
        JS_SetPropertyUint32(ctx, arr, i++, o);
    }
    return arr;
}

// ---- time ---------------------------------------------------------------------------------------------------------
NATIVE(timeInfo) {
    SETUP;
    JSValue a = JS_NewArray(ctx);
    JS_SetPropertyUint32(ctx, a, 0, JS_NewFloat64(ctx, I->lastDt * I->timeScale));
    JS_SetPropertyUint32(ctx, a, 1, JS_NewFloat64(ctx, I->host->fixed_dt()));
    JS_SetPropertyUint32(ctx, a, 2, JS_NewFloat64(ctx, W.time()));
    JS_SetPropertyUint32(ctx, a, 3, JS_NewFloat64(ctx, static_cast<double>(W.frame())));
    JS_SetPropertyUint32(ctx, a, 4, JS_NewFloat64(ctx, I->timeScale));
    JS_SetPropertyUint32(ctx, a, 5, JS_NewFloat64(ctx, I->lastDt));
    return a;
}

NATIVE(setTimeScale) {
    SETUP;
    double v = arg_num(ctx, argc, argv, 0, 1.0);
    if (!(v >= 0) || !std::isfinite(v)) return throw_err(ctx, "time.scale must be a finite number >= 0 (0 pauses gameplay)");
    I->timeScale = v;
    return JS_UNDEFINED;
}

// ---- entities -----------------------------------------------------------------------------------------------------
NATIVE(alive) {
    SETUP;
    return JS_NewBool(ctx, W.alive(ent_from(ctx, argc > 0 ? argv[0] : JS_NULL)));
}

NATIVE(pendingDestroy) {
    SETUP;
    return JS_NewBool(ctx, W.pending_destroy(ent_from(ctx, argc > 0 ? argv[0] : JS_NULL)));
}

NATIVE(idOf) {
    SETUP;
    Entity e = ent_from(ctx, argc > 0 ? argv[0] : JS_NULL);
    if (W.alive(e)) return JS_NewString(ctx, W.id_of(e).c_str());
    return JS_NewString(ctx, I->destroyed_id(e).c_str());
}

NATIVE(destroyedId) {
    SETUP;
    return JS_NewString(ctx, I->destroyed_id(ent_from(ctx, argc > 0 ? argv[0] : JS_NULL)).c_str());
}

NATIVE(find) {
    SETUP;
    std::string key = arg_str(ctx, argc, argv, 0);
    Entity e = W.find(key);
    return ent_val(ctx, e);
}

NATIVE(findAll) {
    SETUP;
    return entities_array(ctx, W.find_all_by_name(arg_str(ctx, argc, argv, 0)));
}

NATIVE(findByTag) {
    SETUP;
    return entities_array(ctx, W.find_by_tag(arg_str(ctx, argc, argv, 0)));
}

NATIVE(entities) {
    SETUP;
    return entities_array(ctx, W.entities());
}

NATIVE(tags) {
    SETUP;
    ENTITY(e, 0);
    JSValue a = JS_NewArray(ctx);
    uint32_t i = 0;
    for (const auto& t : W.info(e).tags) JS_SetPropertyUint32(ctx, a, i++, JS_NewString(ctx, t.c_str()));
    return a;
}

NATIVE(setTags) {
    SETUP;
    ENTITY(e, 0);
    std::vector<std::string> tags;
    if (argc > 1 && JS_IsArray(argv[1])) {
        int64_t n = 0;
        JS_GetLength(ctx, argv[1], &n);
        for (int64_t i = 0; i < n; ++i) {
            JSValue v = JS_GetPropertyUint32(ctx, argv[1], static_cast<uint32_t>(i));
            CStr s(ctx, v);
            JS_FreeValue(ctx, v);
            if (s.len) tags.push_back(s.str());
        }
    }
    W.info(e).tags = std::move(tags);
    return JS_UNDEFINED;
}

NATIVE(hasTag) {
    SETUP;
    ENTITY(e, 0);
    return JS_NewBool(ctx, W.has_tag(e, arg_str(ctx, argc, argv, 1)));
}

NATIVE(addTag) {
    SETUP;
    ENTITY(e, 0);
    std::string t = arg_str(ctx, argc, argv, 1);
    auto& tags = W.info(e).tags;
    if (!t.empty() && std::find(tags.begin(), tags.end(), t) == tags.end()) tags.push_back(t);
    return JS_UNDEFINED;
}

NATIVE(removeTag) {
    SETUP;
    ENTITY(e, 0);
    std::string t = arg_str(ctx, argc, argv, 1);
    auto& tags = W.info(e).tags;
    tags.erase(std::remove(tags.begin(), tags.end(), t), tags.end());
    return JS_UNDEFINED;
}

NATIVE(setId) {
    SETUP;
    ENTITY(e, 0);
    std::string id = arg_str(ctx, argc, argv, 1);
    if (id.empty()) return throw_err(ctx, "entity id cannot be empty");
    auto r = W.set_id(e, id);
    if (!r) return throw_err(ctx, r.error().to_string());
    return JS_UNDEFINED;
}

NATIVE(getName) {
    SETUP;
    ENTITY(e, 0);
    return JS_NewString(ctx, W.info(e).name.c_str());
}

NATIVE(setName) {
    SETUP;
    ENTITY(e, 0);
    W.info(e).name = arg_str(ctx, argc, argv, 1);
    return JS_UNDEFINED;
}

NATIVE(getActive) {
    SETUP;
    ENTITY(e, 0);
    return JS_NewBool(ctx, W.info(e).active);
}

NATIVE(setActive) {
    SETUP;
    ENTITY(e, 0);
    W.set_active(e, arg_bool(ctx, argc, argv, 1, true));
    return JS_UNDEFINED;
}

NATIVE(activeInHierarchy) {
    SETUP;
    ENTITY(e, 0);
    return JS_NewBool(ctx, W.active_in_hierarchy(e));
}

NATIVE(destroy) {
    SETUP;
    ENTITY(e, 0);
    W.destroy(e);
    return JS_UNDEFINED;
}

NATIVE(parent) {
    SETUP;
    ENTITY(e, 0);
    return ent_val(ctx, W.parent(e));
}

NATIVE(children) {
    SETUP;
    ENTITY(e, 0);
    return entities_array(ctx, W.children(e));
}

NATIVE(setParent) {
    SETUP;
    ENTITY(e, 0);
    Entity p = ent_from(ctx, argc > 1 ? argv[1] : JS_NULL);
    if (!p.is_null() && !W.alive(p)) return throw_err(ctx, "setParent: the new parent entity was destroyed");
    if (p == e || (!p.is_null() && W.is_ancestor(e, p))) return throw_err(ctx, "setParent: an entity cannot be parented under itself or its own descendant");
    int index = -1;
    if (argc > 3 && !JS_IsUndefined(argv[3]) && !JS_IsNull(argv[3])) {
        std::string bad = W.check_child_index(p, e, arg_num(ctx, argc, argv, 3, -1.0));
        if (!bad.empty()) return throw_err(ctx, "setParent: " + bad);
        index = static_cast<int>(arg_num(ctx, argc, argv, 3, -1.0));
    }
    W.set_parent(e, p, arg_bool(ctx, argc, argv, 2, false), index);
    return JS_UNDEFINED;
}

NATIVE(worldPos) {
    SETUP;
    ENTITY(e, 0);
    Vec3 p = W.world_position(e);
    return array_of(ctx, {p.x, p.y, p.z});
}

NATIVE(setWorldPos) {
    SETUP;
    ENTITY(e, 0);
    Vec3 p = W.world_position(e);
    if (argc > 1 && JS_IsObject(argv[1])) {
        float v[3] = {p.x, p.y, p.z};
        for (uint32_t i = 0; i < 3; ++i) {
            JSValue x = JS_GetPropertyUint32(ctx, argv[1], i);
            if (JS_IsNumber(x)) { double d = 0; JS_ToFloat64(ctx, &d, x); v[i] = static_cast<float>(d); }
            JS_FreeValue(ctx, x);
        }
        W.set_world_position(e, {v[0], v[1], v[2]});
    }
    return JS_UNDEFINED;
}

NATIVE(entityJson) {
    SETUP;
    ENTITY(e, 0);
    EntityJsonOptions o;
    o.includeChildren = arg_bool(ctx, argc, argv, 1, true);
    o.includeDefaults = arg_bool(ctx, argc, argv, 2, false);
    return I->from_json(entity_to_json(W, e, o));
}

// Entities a script just created: their `key`s are translated now, not at the end of the frame (docs/LOCALIZATION.md).
void localize_created(Impl* I, const std::vector<Entity>& created) {
    if (const I18n* L = I->host->i18n())
        for (Entity e : created) localize_entity(I->host->world(), e, *L);
}

NATIVE(spawn) {
    SETUP;
    Json j = I->to_json(argc > 0 ? argv[0] : JS_UNDEFINED);
    if (!j.is_object()) return throw_err(ctx, "world.spawn expects an entity object like { name, tags, components: {...} }");
    Entity parent = ent_from(ctx, argc > 1 ? argv[1] : JS_NULL);
    int index = -1;
    if (argc > 2 && !JS_IsUndefined(argv[2]) && !JS_IsNull(argv[2])) {
        std::string bad = W.check_child_index(parent, kNullEntity, arg_num(ctx, argc, argv, 2, -1.0));
        if (!bad.empty()) return throw_err(ctx, "world.spawn: " + bad);
        index = static_cast<int>(arg_num(ctx, argc, argv, 2, -1.0));
    }
    LoadReport report;
    Entity e = entity_from_json(W, j, parent, report, "world.spawn", "", index);
    if (!report.ok() || e.is_null()) {
        return throw_err(ctx, "world.spawn failed:\n" + report.summary());
    }
    for (const auto& m : report.messages)
        if (m.severity == LoadMessage::Severity::Warning) fa::log(LogLevel::Warn, "script", m.to_string());
    I->construct_for(report.created);  // entity.behaviour exists right away; onStart runs before the first update
    localize_created(I, report.created);
    return ent_val(ctx, e);
}

NATIVE(spawnPrefab) {
    SETUP;
    std::string path = arg_str(ctx, argc, argv, 0);
    Entity parent = ent_from(ctx, argc > 1 ? argv[1] : JS_NULL);
    Json overrides = argc > 2 ? I->to_json(argv[2]) : Json::object();
    if (overrides.is_null()) overrides = Json::object();
    int index = -1;
    if (argc > 3 && !JS_IsUndefined(argv[3]) && !JS_IsNull(argv[3])) {
        std::string bad = W.check_child_index(parent, kNullEntity, arg_num(ctx, argc, argv, 3, -1.0));
        if (!bad.empty()) return throw_err(ctx, "world.spawnPrefab: " + bad);
        index = static_cast<int>(arg_num(ctx, argc, argv, 3, -1.0));
    }
    LoadReport report;
    Entity e = instantiate_prefab(W, path, parent, report, overrides, index);
    if (!report.ok() || e.is_null()) return throw_err(ctx, "world.spawnPrefab('" + path + "') failed:\n" + report.summary());
    I->construct_for(report.created);
    localize_created(I, report.created);
    return ent_val(ctx, e);
}

NATIVE(behaviour) {
    SETUP;
    Entity e = ent_from(ctx, argc > 0 ? argv[0] : JS_NULL);
    Behaviour* b = I->find_behaviour(e);
    if (!b || JS_IsUndefined(b->instance.get())) return JS_NULL;
    return JS_DupValue(ctx, b->instance.get());
}

NATIVE(isGrounded) {
    SETUP;
    ENTITY(e, 0);
    return JS_NewBool(ctx, I->host->physics().is_grounded(W, e, static_cast<float>(arg_num(ctx, argc, argv, 1, -1.0))));
}

NATIVE(isTouching) {  // (entity, x, y, z, tolerance)
    SETUP;
    ENTITY(e, 0);
    Vec3 d{static_cast<float>(arg_num(ctx, argc, argv, 1)), static_cast<float>(arg_num(ctx, argc, argv, 2)), static_cast<float>(arg_num(ctx, argc, argv, 3))};
    Physics& ph = I->host->physics();
    if (W.get<RigidBody3D>(e) || W.get<Collider3D>(e))
        return JS_NewBool(ctx, ph.is_touching3d(W, e, d, static_cast<float>(arg_num(ctx, argc, argv, 4, 0.05))));
    return JS_NewBool(ctx, ph.is_touching2d(W, e, {d.x, d.y}, static_cast<float>(arg_num(ctx, argc, argv, 4, 2.0))));
}

// Animator calls of entity.animator: (entity, method, a, b). Methods: play(clip, fade), stop, set(name, value),
// trigger(name), clips. Returns the clips for "clips", nothing else; failures throw a teaching Error.
NATIVE(animCall) {
    SETUP;
    ENTITY(e, 0);
    const std::string m = arg_str(ctx, argc, argv, 1);
    Result<void> r;
    if (m == "play") {
        r = animator_play(W, e, arg_str(ctx, argc, argv, 2), static_cast<float>(arg_num(ctx, argc, argv, 3, 0.2)));
    } else if (m == "stop") {
        r = animator_stop(W, e);
    } else if (m == "set") {
        r = animator_set(W, e, arg_str(ctx, argc, argv, 2), I->to_json(argc > 3 ? argv[3] : JS_UNDEFINED));
    } else if (m == "trigger") {
        r = animator_trigger(W, e, arg_str(ctx, argc, argv, 2));
    } else if (m == "clips") {
        auto c = animator_clips(W, e);
        if (!c) return throw_err(ctx, c.error().to_string());
        return I->from_json(*c);
    } else {
        return throw_err(ctx, "internal error: unknown animator call '" + m + "'");
    }
    if (!r) return throw_err(ctx, r.error().to_string());
    return JS_UNDEFINED;
}

NATIVE(particlesBurst) {
    SETUP;
    ENTITY(e, 0);
    int count = static_cast<int>(arg_num(ctx, argc, argv, 1, 10));
    Renderer* r = I->host->renderer();
    if (!r || !r->initialized()) {
        static bool warned = false;
        if (!warned) {
            warned = true;
            fa::log(LogLevel::Warn, "script", "particles.burst: no renderer in this run (headless); skipped");
        }
        return JS_UNDEFINED;
    }
    r->emit_burst(e, count);
    return JS_UNDEFINED;
}

// How scripts measure text: the renderer's own layout when there is one, otherwise (headless) an approximation of 0.6 em
// per character and 1.2 em per line, with a one-time warning (`what` names the caller in it). The Text-level size includes
// the player's text size, the maxTextScale cap and autoShrink (text_fit.h), like the renderer.
VisualMeasure script_measure(Impl* I, const char* what) {
    VisualMeasure m;
    m.textScale = I->host->text_scale();
    m.textSize = [I, what](const Text& t) {
        Renderer* r = I->host->renderer();
        if (r && r->initialized()) return r->measure_text(t);
        static bool warned = false;
        if (!warned) {
            warned = true;
            fa::log(LogLevel::Warn, "script", std::string(what) + ": no renderer in this run (headless); using an approximation of 0.6 * fontSize per character");
        }
        return approx_text_size(t, I->host->text_scale());
    };
    return m;
}

NATIVE(measureText) {  // (text, fontSize, font, maxWidth, screenSpace, maxTextScale, autoShrink, minFontSize, maxHeight) -> [w, h, size]
    SETUP;
    Text t;
    t.text = arg_str(ctx, argc, argv, 0);
    t.fontSize = static_cast<float>(arg_num(ctx, argc, argv, 1, 16));
    t.font = arg_str(ctx, argc, argv, 2);
    t.maxWidth = static_cast<float>(arg_num(ctx, argc, argv, 3, 0));
    t.space = arg_bool(ctx, argc, argv, 4, true) ? RenderSpace::Screen : RenderSpace::World;
    t.maxTextScale = static_cast<float>(arg_num(ctx, argc, argv, 5, 0));
    t.autoShrink = arg_bool(ctx, argc, argv, 6, false);
    t.minFontSize = static_cast<float>(arg_num(ctx, argc, argv, 7, 10));
    t.maxHeight = static_cast<float>(arg_num(ctx, argc, argv, 8, 0));
    const VisualMeasure measure = script_measure(I, "ui.measureText");
    const TextFit fit = fit_text(text_fit_spec(t), t.text, t.font, measure.textScale, text_extent_of(measure));
    return array_of(ctx, {fit.size.x, fit.size.y, fit.px});
}

NATIVE(textScale) {  // () -> the player's text size option
    SETUP;
    return float_to_js(ctx, I->host->text_scale());
}

NATIVE(setTextScale) {  // (scale): 0.5 .. 3, throws saying what is accepted
    SETUP;
    double v = 0;
    const bool number = argc > 0 && JS_IsNumber(argv[0]) && JS_ToFloat64(ctx, &v, argv[0]) == 0 && std::isfinite(v);
    if (!number || v < double(kMinTextScale) || v > double(kMaxTextScale))
        return throw_err(ctx, std::format("ui.textScale = {}: expected a number from {} to {} (1 is normal size, 1.5 is 50% bigger). A saved option "
                                          "from an older version or a hand-edited file may be out of range: clamp it first, e.g. "
                                          "ui.textScale = math.clamp(saved, {}, {}).",
                                          arg_str(ctx, argc, argv, 0), kMinTextScale, kMaxTextScale, kMinTextScale, kMaxTextScale));
    I->host->set_text_scale(float(v));
    return JS_UNDEFINED;
}

// ---- speech (fa/platform/speech.h; ui.speak, game.spoken) ---------------------------------------------------------------------
NATIVE(speak) {  // (text, interrupt) -> true when the system was asked to say it (false: the system has no speech)
    SETUP;
    const I18n* L = I->host->i18n();
    const std::string language = L && L->enabled() ? L->language() : std::string();
    return JS_NewBool(ctx, I->host->speech().speak(arg_str(ctx, argc, argv, 0), language, arg_bool(ctx, argc, argv, 1, true)));
}

NATIVE(stopSpeaking) {
    SETUP;
    I->host->speech().stop();
    return JS_UNDEFINED;
}

NATIVE(speechAvailable) {
    SETUP;
    return JS_NewBool(ctx, I->host->speech().available());
}

NATIVE(spokenLog) {  // (clear) -> [{text, language, interrupt}], oldest first
    SETUP;
    Json list = Json::array();
    for (const SpokenLine& line : I->host->speech().spoken())
        list.push_back(Json::object({{"text", line.text}, {"language", line.language}, {"interrupt", line.interrupt}}));
    if (arg_bool(ctx, argc, argv, 0, false)) I->host->speech().clear_spoken();
    return I->from_json(list);
}

// ---- ui ---------------------------------------------------------------------------------------------------------------------
NATIVE(uiState) {  // () -> [focused, hovered]: entity handles, null for none (or when the host has no UI)
    SETUP;
    UiSystem* U = I->host->ui();
    auto live = [&](Entity e) { return W.alive(e) ? ent_val(ctx, e) : JS_NULL; };
    JSValue a = JS_NewArray(ctx);
    JS_SetPropertyUint32(ctx, a, 0, live(U ? U->focused() : kNullEntity));
    JS_SetPropertyUint32(ctx, a, 1, live(U ? U->hovered() : kNullEntity));
    return a;
}

NATIVE(uiFocus) {  // (entity | null): throws saying why when the entity cannot take focus
    SETUP;
    UiSystem* U = I->host->ui();
    if (!U) return throw_err(ctx, "ui.focus: this run has no UI system");
    Entity e;
    if (argc > 0 && !JS_IsNull(argv[0]) && !JS_IsUndefined(argv[0])) {
        JSValue exc = JS_UNDEFINED;
        if (!need_entity(I, ctx, argv[0], e, exc)) return exc;
    }
    if (U->set_focus(W, e)) return JS_UNDEFINED;
    const UiKind kind = ui_kind(W, e);
    std::string why;
    if (!ui_is_control(kind))
        why = kind == UiKind::None ? "it has no Button, Toggle, Slider or TextField component"
                                   : std::string("a ") + ui_kind_name(kind) +
                                         (kind == UiKind::Panel || kind == UiKind::ScrollList ? " is a container and" : " is touch-only and") +
                                         " cannot be focused; focus a Button, Toggle, Slider or TextField";
    else if (!W.active_in_hierarchy(e)) why = "it is inactive (itself or an ancestor), so set active = true first";
    else why = "its interactable is false; set interactable = true first";
    return throw_err(ctx, "ui.focus(target): '" + W.id_of(e) + "' cannot take focus: " + why);
}

// ---- entity.bounds() ----------------------------------------------------------------------------------------------
// The world-space axis-aligned rectangle of an entity's 2D visuals, from the same geometry the renderer draws. The geometry
// itself (Tilemap through tilemap_size(), Sprite, Shape2D and Text from size and pivot, the box around the four corners moved
// by the world matrix, the union over all visuals) is entity_world_rect() in fa/scene/bounds.h, shared with the editor's
// picking and selection outline. What only this module knows is how to measure a texture file and a text.
// Pixel size of a texture file as the renderer sees it: 32 x 32 (the missing-texture checker) when the file is missing or
// unreadable. Cached per file and modification time, so a script may ask every frame.
Vec2 texture_pixel_size(Impl* I, const std::string& path) {
    std::string key = fs::normalize(path);
    if (key.empty()) key = path;
    const std::int64_t mtime = fs::modified_time(key);
    auto it = I->texSizes.find(key);
    if (it == I->texSizes.end() || it->second.mtime != mtime) {
        Impl::TexSize ts{32, 32, mtime};
        if (auto size = texture_size(key); size.ok()) { ts.w = size->width; ts.h = size->height; }  // also an exported twin or atlas rect
        it = I->texSizes.insert_or_assign(key, ts).first;
    }
    return {static_cast<float>(it->second.w), static_cast<float>(it->second.h)};
}

NATIVE(textureSize) {  // (path) -> [w, h]; assets.textureSize
    SETUP;
    Vec2 s = texture_pixel_size(I, arg_str(ctx, argc, argv, 0));
    return array_of(ctx, {s.x, s.y});
}

NATIVE(uiLayout) {  // () -> undefined: the per-frame UI layout, now
    SETUP;
    UiSystem* U = I->host->ui();
    if (!U) return throw_err(ctx, "ui.layout: this run has no UI system");
    const VisualMeasure measure = script_measure(I, "ui.layout()");
    U->layout(W, I->host->design_size(), measure, false);  // the script is still changing the menu: the frame's layout warns
    return JS_UNDEFINED;
}

NATIVE(screenRect) {  // (entity) -> [x, y, w, h] in design pixels, top-left origin | null
    SETUP;
    ENTITY(e, 0);
    const VisualMeasure measure = script_measure(I, "ui.rectOf() of a Text");
    const std::optional<Rect> box = ui_screen_rect(W, e, I->host->design_size(), measure);
    if (!box) return JS_NULL;
    JSValue a = JS_NewArray(ctx);
    const float v[4] = {box->x, box->y, box->w, box->h};
    for (uint32_t i = 0; i < 4; ++i) JS_SetPropertyUint32(ctx, a, i, float_to_js(ctx, v[i]));
    return a;
}

NATIVE(overflowed) {  // (entity) -> bool: the text of a Text or a widget label does not fit its box at its effective size
    SETUP;
    ENTITY(e, 0);
    const VisualMeasure measure = script_measure(I, "ui.overflowed()");
    return JS_NewBool(ctx, ui_text_overflowed(W, e, I->host->design_size(), measure));
}

NATIVE(bounds) {  // (entity) -> [x, y, w, h] | null
    SETUP;
    ENTITY(e, 0);
    VisualMeasure measure = script_measure(I, "entity.bounds() of a Text");
    measure.textureSize = [I](const std::string& path) { return texture_pixel_size(I, path); };
    const std::optional<Rect> box = entity_world_rect(W, e, measure);
    if (!box) return JS_NULL;
    JSValue a = JS_NewArray(ctx);
    const float v[4] = {box->x, box->y, box->w, box->h};
    for (uint32_t i = 0; i < 4; ++i) JS_SetPropertyUint32(ctx, a, i, float_to_js(ctx, v[i]));
    return a;
}

// ---- components ---------------------------------------------------------------------------------------------------
NATIVE(hasComp) {
    SETUP;
    ENTITY(e, 0);
    JSValue exc = JS_UNDEFINED;
    const TypeInfo* t = find_type(ctx, arg_str(ctx, argc, argv, 1), &exc);
    if (!t) return exc;
    return JS_NewBool(ctx, W.get(e, *t) != nullptr);
}

NATIVE(compType) {  // component name -> type index (throws on unknown)
    SETUP;
    JSValue exc = JS_UNDEFINED;
    const TypeInfo* t = find_type(ctx, arg_str(ctx, argc, argv, 0), &exc);
    if (!t) return exc;
    return JS_NewInt32(ctx, static_cast<int32_t>(t->id));
}

NATIVE(addComp) {
    SETUP;
    ENTITY(e, 0);
    JSValue exc = JS_UNDEFINED;
    const TypeInfo* t = find_type(ctx, arg_str(ctx, argc, argv, 1), &exc);
    if (!t) return exc;
    if (t->name == "EntityInfo" || t->name == "Transform") return JS_NewInt32(ctx, static_cast<int32_t>(t->id));
    Json fields = argc > 2 ? I->to_json(argv[2]) : Json::object();
    if (fields.is_null()) fields = Json::object();
    if (!fields.is_object()) return throw_err(ctx, "entity.add(name, fields): fields must be an object");
    auto r = patch_component(W, e, *t, fields);
    if (!r) return throw_err(ctx, r.error().to_string());
    if (t->name == "Script") I->construct_for({e});
    return JS_NewInt32(ctx, static_cast<int32_t>(t->id));
}

NATIVE(removeComp) {
    SETUP;
    ENTITY(e, 0);
    JSValue exc = JS_UNDEFINED;
    const TypeInfo* t = find_type(ctx, arg_str(ctx, argc, argv, 1), &exc);
    if (!t) return exc;
    if (t->name == "EntityInfo" || t->name == "Transform")
        return throw_err(ctx, "the " + t->name + " component cannot be removed");
    bool had = W.get(e, *t) != nullptr;
    W.remove(e, *t);
    return JS_NewBool(ctx, had);
}

NATIVE(compNames) {
    SETUP;
    ENTITY(e, 0);
    JSValue a = JS_NewArray(ctx);
    uint32_t i = 0;
    for (const TypeInfo* t : W.components_of(e)) {
        if (t->name == "EntityInfo") continue;
        JS_SetPropertyUint32(ctx, a, i++, JS_NewString(ctx, t->name.c_str()));
    }
    return a;
}

NATIVE(compJson) {
    SETUP;
    void* obj = nullptr;
    const TypeInfo* t = nullptr;
    Entity e;
    JSValue exc = JS_UNDEFINED;
    if (!resolve_obj(I, ctx, argv[0], argv[1], obj, t, e, exc)) return exc;
    Json j = e.is_null() ? object_to_json(*t, obj, true, true) : component_to_json(W, e, *t, true, true);
    if (e.is_null() == false && t->name == "EntityInfo") {
        j["tags"] = W.info(e).tags;
    }
    return I->from_json(j);
}

NATIVE(patchComp) {
    SETUP;
    ENTITY(e, 0);
    JSValue exc = JS_UNDEFINED;
    const TypeInfo* t = find_type(ctx, arg_str(ctx, argc, argv, 1), &exc);
    if (!t) return exc;
    Json fields = I->to_json(argc > 2 ? argv[2] : JS_UNDEFINED);
    if (!fields.is_object()) return throw_err(ctx, "entity.set(name, fields): fields must be an object like { speed: 3 }");
    if (t->name == "EntityInfo" && fields.contains("id")) {
        auto r = W.set_id(e, fields["id"].get<std::string>());
        if (!r) return throw_err(ctx, r.error().to_string());
        fields.erase("id");
    }
    if (t->name == "EntityInfo" && fields.contains("tags")) {
        W.info(e).tags = fields["tags"].get<std::vector<std::string>>();
        fields.erase("tags");
    }
    auto r = patch_component(W, e, *t, fields);
    if (!r) return throw_err(ctx, r.error().to_string());
    if (t->name == "Script") I->construct_for({e});
    return JS_UNDEFINED;
}

NATIVE(fget) {
    SETUP;
    void* obj = nullptr;
    const TypeInfo* t = nullptr;
    Entity e;
    JSValue exc = JS_UNDEFINED;
    if (!resolve_obj(I, ctx, argv[0], argv[1], obj, t, e, exc)) return exc;
    int32_t fi = 0;
    JS_ToInt32(ctx, &fi, argv[2]);
    if (fi < 0 || fi >= static_cast<int32_t>(t->fields.size())) return throw_err(ctx, "internal error: bad field index");
    const FieldInfo& f = t->fields[static_cast<size_t>(fi)];
    const void* p = f.ptr(obj);
    switch (f.kind) {
        case FieldKind::Bool: return JS_NewBool(ctx, *static_cast<const bool*>(p));
        case FieldKind::Int: return JS_NewInt32(ctx, *static_cast<const std::int32_t*>(p));
        case FieldKind::Float: return float_to_js(ctx, *static_cast<const float*>(p));
        case FieldKind::String:
        case FieldKind::Asset: return JS_NewString(ctx, static_cast<const std::string*>(p)->c_str());
        case FieldKind::Enum: {
            std::int32_t v = *static_cast<const std::int32_t*>(p);
            if (v >= 0 && v < static_cast<std::int32_t>(f.enumNames.size())) return JS_NewString(ctx, f.enumNames[static_cast<size_t>(v)].c_str());
            return JS_NewInt32(ctx, v);
        }
        case FieldKind::Entity: {
            Entity target = *static_cast<const Entity*>(p);
            if (target.is_null() || !W.alive(target)) return JS_NULL;
            return ent_val(ctx, target);
        }
        case FieldKind::Json: return I->from_json(*static_cast<const Json*>(p));
        default: {
            int n = float_count(f.kind);
            const float* fp = static_cast<const float*>(p);
            JSValue a = JS_NewArray(ctx);
            for (int i = 0; i < n; ++i) JS_SetPropertyUint32(ctx, a, static_cast<uint32_t>(i), float_to_js(ctx, fp[i]));
            return a;
        }
    }
}

NATIVE(fgetn) {
    SETUP;
    void* obj = nullptr;
    const TypeInfo* t = nullptr;
    Entity e;
    JSValue exc = JS_UNDEFINED;
    if (!resolve_obj(I, ctx, argv[0], argv[1], obj, t, e, exc)) return exc;
    int32_t fi = 0, k = 0;
    JS_ToInt32(ctx, &fi, argv[2]);
    JS_ToInt32(ctx, &k, argv[3]);
    const FieldInfo& f = t->fields[static_cast<size_t>(fi)];
    return float_to_js(ctx, static_cast<const float*>(f.ptr(obj))[k]);
}

NATIVE(fsetn) {
    SETUP;
    void* obj = nullptr;
    const TypeInfo* t = nullptr;
    Entity e;
    JSValue exc = JS_UNDEFINED;
    if (!resolve_obj(I, ctx, argv[0], argv[1], obj, t, e, exc)) return exc;
    int32_t fi = 0, k = 0;
    JS_ToInt32(ctx, &fi, argv[2]);
    JS_ToInt32(ctx, &k, argv[3]);
    const FieldInfo& f = t->fields[static_cast<size_t>(fi)];
    if (f.readOnly) return throw_err(ctx, t->name + "." + f.name + " is read-only");
    double d = 0;
    if (!JS_IsNumber(argv[4])) {
        CStr s(ctx, argv[4]);
        return throw_err(ctx, std::format("{}.{} components must be numbers, got {}", t->name, f.name, s.str().empty() ? "an empty value" : "'" + s.str() + "'"));
    }
    JS_ToFloat64(ctx, &d, argv[4]);
    static_cast<float*>(f.ptr(obj))[k] = static_cast<float>(d);
    return JS_UNDEFINED;
}

NATIVE(fset) {
    SETUP;
    void* obj = nullptr;
    const TypeInfo* t = nullptr;
    Entity e;
    JSValue exc = JS_UNDEFINED;
    if (!resolve_obj(I, ctx, argv[0], argv[1], obj, t, e, exc)) return exc;
    int32_t fi = 0;
    JS_ToInt32(ctx, &fi, argv[2]);
    if (fi < 0 || fi >= static_cast<int32_t>(t->fields.size())) return throw_err(ctx, "internal error: bad field index");
    const FieldInfo& f = t->fields[static_cast<size_t>(fi)];
    std::string what = t->name + "." + f.name;
    if (f.readOnly) return throw_err(ctx, what + " is read-only");
    JSValueConst v = argc > 3 ? argv[3] : JS_UNDEFINED;
    auto wrong = [&](const char* expected) {
        CStr s(ctx, v);
        return throw_err(ctx, std::format("{} expects {}, got {}", what, expected, JS_IsUndefined(v) ? "undefined" : "'" + s.str() + "'"));
    };
    void* p = f.ptr(obj);
    // EntityInfo.id must go through World::set_id (lookup tables).
    if (t->name == "EntityInfo" && !e.is_null()) {
        if (f.name == "id") {
            if (!JS_IsString(v)) return wrong("a string");
            auto r = W.set_id(e, CStr(ctx, v).view());
            if (!r) return throw_err(ctx, r.error().to_string());
            return JS_UNDEFINED;
        }
        if (f.name == "active") {
            W.set_active(e, JS_ToBool(ctx, v) > 0);
            return JS_UNDEFINED;
        }
    }
    switch (f.kind) {
        case FieldKind::Bool: *static_cast<bool*>(p) = JS_ToBool(ctx, v) > 0; break;
        case FieldKind::Int: {
            if (!JS_IsNumber(v)) return wrong("an integer");
            double d = 0;
            JS_ToFloat64(ctx, &d, v);
            if (!std::isfinite(d)) return wrong("a finite integer");
            const auto n = std::llround(d);
            if (auto r = check_range(f, double(n)); !r) return throw_err(ctx, what + ": " + r.error().to_string());
            *static_cast<std::int32_t*>(p) = static_cast<std::int32_t>(n);
            break;
        }
        case FieldKind::Float: {
            if (!JS_IsNumber(v)) return wrong("a number");
            double d = 0;
            JS_ToFloat64(ctx, &d, v);
            if (auto r = check_range(f, d); !r) return throw_err(ctx, what + ": " + r.error().to_string());
            *static_cast<float*>(p) = static_cast<float>(d);
            break;
        }
        case FieldKind::String:
        case FieldKind::Asset: {
            if (!JS_IsString(v)) return wrong("a string");
            *static_cast<std::string*>(p) = CStr(ctx, v).str();
            break;
        }
        case FieldKind::Enum: {
            if (JS_IsNumber(v)) {
                int32_t n = 0;
                JS_ToInt32(ctx, &n, v);
                if (n < 0 || n >= static_cast<int32_t>(f.enumNames.size())) return wrong("one of the enum names");
                *static_cast<std::int32_t*>(p) = n;
                break;
            }
            if (!JS_IsString(v)) return wrong("a string");
            std::string s = to_lower(CStr(ctx, v).view());
            int found = -1;
            for (size_t i = 0; i < f.enumNames.size(); ++i)
                if (to_lower(f.enumNames[i]) == s) found = static_cast<int>(i);
            if (found < 0) {
                return throw_err(ctx, "invalid value '" + CStr(ctx, v).str() + "' for " + what + ". " +
                                          did_you_mean(CStr(ctx, v).view(), f.enumNames));
            }
            *static_cast<std::int32_t*>(p) = found;
            break;
        }
        case FieldKind::Entity: {
            if (JS_IsNull(v) || JS_IsUndefined(v)) { *static_cast<Entity*>(p) = kNullEntity; break; }
            if (JS_IsString(v)) {
                std::string id = CStr(ctx, v).str();
                if (id.empty()) { *static_cast<Entity*>(p) = kNullEntity; break; }  // "" = no entity (the world, for a joint)
                Entity target = W.find_by_id(id);
                if (target.is_null()) return throw_err(ctx, what + ": no entity with id '" + id + "'");
                *static_cast<Entity*>(p) = target;
                break;
            }
            Entity target = ent_from(ctx, v);
            if (!W.alive(target)) return throw_err(ctx, what + ": that entity was destroyed");
            *static_cast<Entity*>(p) = target;
            break;
        }
        case FieldKind::Json: {
            *static_cast<Json*>(p) = I->to_json(v);
            break;
        }
        default: {
            int n = float_count(f.kind);
            if (!JS_IsObject(v)) return wrong(n == 2 ? "{x, y} or [x, y]" : n == 3 ? "{x, y, z} or [x, y, z]" : "an array or object of numbers");
            float* fp = static_cast<float*>(p);
            for (int i = 0; i < n; ++i) {
                JSValue x = JS_GetPropertyUint32(ctx, v, static_cast<uint32_t>(i));
                if (JS_IsNumber(x)) {
                    double d = 0;
                    JS_ToFloat64(ctx, &d, x);
                    fp[i] = static_cast<float>(d);
                }
                JS_FreeValue(ctx, x);
            }
            break;
        }
    }
    return JS_UNDEFINED;
}

// ---- world / events / rng -----------------------------------------------------------------------------------------
NATIVE(emit) {
    SETUP;
    GameEvent ev;
    ev.name = arg_str(ctx, argc, argv, 0);
    if (ev.name.empty()) return throw_err(ctx, "world.emit(name, data): name must be a non-empty string");
    ev.data = argc > 1 ? I->to_json(argv[1]) : Json(nullptr);
    ev.source = argc > 2 ? ent_from(ctx, argv[2]) : kNullEntity;
    W.events().game.push_back(std::move(ev));
    return JS_UNDEFINED;
}

NATIVE(scenePath) {
    SETUP;
    return JS_NewString(ctx, W.scene_path().c_str());
}

NATIVE(requestScene) {
    SETUP;
    std::string path = arg_str(ctx, argc, argv, 0);
    if (path.empty()) path = W.scene_path();
    if (!fs::exists(path)) {
        std::vector<std::string> scenes = fs::list("scenes", true, ".json");
        return throw_err(ctx, "scene '" + path + "' does not exist. " + did_you_mean(path, scenes));
    }
    I->host->request_scene_change(path);
    return JS_UNDEFINED;
}

NATIVE(rngFloat) {
    SETUP;
    return JS_NewFloat64(ctx, W.rng().next_float());
}
NATIVE(rngRange) {
    SETUP;
    return float_to_js(ctx, W.rng().range(static_cast<float>(arg_num(ctx, argc, argv, 0, 0)), static_cast<float>(arg_num(ctx, argc, argv, 1, 1))));
}
NATIVE(rngInt) {
    SETUP;
    return JS_NewInt32(ctx, W.rng().range_int(static_cast<int>(arg_num(ctx, argc, argv, 0, 0)), static_cast<int>(arg_num(ctx, argc, argv, 1, 1))));
}
NATIVE(rngChance) {
    SETUP;
    return JS_NewBool(ctx, W.rng().chance(static_cast<float>(arg_num(ctx, argc, argv, 0, 0.5))));
}
NATIVE(rngSeed) {
    SETUP;
    if (argc > 0 && !JS_IsUndefined(argv[0])) {
        W.rng().reseed(static_cast<std::uint64_t>(arg_num(ctx, argc, argv, 0, 1)));
    }
    return JS_UNDEFINED;
}

// ---- input --------------------------------------------------------------------------------------------------------
bool check_action(Impl* I, JSContext* ctx, const std::string& a, JSValue& exc) {
    Input& in = I->host->input();
    if (in.has_action(a)) return true;
    auto names = in.action_names();
    exc = throw_err(ctx, "unknown input action '" + a + "'. " +
                             (names.empty() ? std::string("No actions are defined; add them to factoria.json under input.actions.")
                                            : did_you_mean(a, names)));
    return false;
}

NATIVE(inAction) {
    SETUP;
    int kind = static_cast<int>(arg_num(ctx, argc, argv, 0));
    std::string a = arg_str(ctx, argc, argv, 1);
    JSValue exc = JS_UNDEFINED;
    if (!check_action(I, ctx, a, exc)) return exc;
    Input& in = I->host->input();
    return JS_NewBool(ctx, kind == 0 ? in.action_down(a) : kind == 1 ? in.action_pressed(a) : in.action_released(a));
}

NATIVE(inAxis) {
    SETUP;
    std::string n = arg_str(ctx, argc, argv, 0), p = arg_str(ctx, argc, argv, 1);
    JSValue exc = JS_UNDEFINED;
    if (!check_action(I, ctx, n, exc) || !check_action(I, ctx, p, exc)) return exc;
    return float_to_js(ctx, I->host->input().axis(n, p));
}

NATIVE(inVector) {
    SETUP;
    std::string a[4] = {arg_str(ctx, argc, argv, 0), arg_str(ctx, argc, argv, 1), arg_str(ctx, argc, argv, 2), arg_str(ctx, argc, argv, 3)};
    JSValue exc = JS_UNDEFINED;
    for (auto& s : a)
        if (!check_action(I, ctx, s, exc)) return exc;
    Vec2 v = I->host->input().vector(a[0], a[1], a[2], a[3]);
    return array_of(ctx, {v.x, v.y});
}

Key parse_key(Impl*, JSContext* ctx, const std::string& name, JSValue& exc, bool& ok) {
    Key k = key_from_name(name);
    ok = k != Key::Unknown;
    if (!ok) {
        std::vector<std::string> names;
        for (int i = 1; i < static_cast<int>(Key::Count); ++i) names.push_back(key_name(static_cast<Key>(i)));
        exc = throw_err(ctx, "unknown key '" + name + "'. " + did_you_mean(name, names, 20));
    }
    return k;
}

NATIVE(inKey) {
    SETUP;
    int kind = static_cast<int>(arg_num(ctx, argc, argv, 0));
    JSValue exc = JS_UNDEFINED;
    bool ok = false;
    Key k = parse_key(I, ctx, arg_str(ctx, argc, argv, 1), exc, ok);
    if (!ok) return exc;
    Input& in = I->host->input();
    return JS_NewBool(ctx, kind == 0 ? in.key_down(k) : kind == 1 ? in.key_pressed(k) : in.key_released(k));
}

MouseButton parse_button(const std::string& s, bool& ok) {
    std::string l = to_lower(s);
    ok = true;
    if (l == "left" || l.empty()) return MouseButton::Left;
    if (l == "right") return MouseButton::Right;
    if (l == "middle") return MouseButton::Middle;
    ok = false;
    return MouseButton::Left;
}

NATIVE(inMouse) {
    SETUP;
    Input& in = I->host->input();
    JSValue o = JS_NewObject(ctx);
    Vec2 p = in.mouse_position(), d = in.mouse_delta();
    JS_SetPropertyStr(ctx, o, "position", array_of(ctx, {p.x, p.y}));
    JS_SetPropertyStr(ctx, o, "delta", array_of(ctx, {d.x, d.y}));
    JS_SetPropertyStr(ctx, o, "wheel", float_to_js(ctx, in.mouse_wheel()));
    return o;
}

NATIVE(inMouseButton) {
    SETUP;
    int kind = static_cast<int>(arg_num(ctx, argc, argv, 0));
    bool ok = false;
    MouseButton b = parse_button(arg_str(ctx, argc, argv, 1), ok);
    if (!ok) return throw_err(ctx, "unknown mouse button '" + arg_str(ctx, argc, argv, 1) + "'; use \"left\", \"right\" or \"middle\"");
    Input& in = I->host->input();
    return JS_NewBool(ctx, kind == 0 ? in.mouse_down(b) : kind == 1 ? in.mouse_pressed(b) : in.mouse_released(b));
}

NATIVE(inTouches) {
    SETUP;
    JSValue a = JS_NewArray(ctx);
    uint32_t i = 0;
    for (const Touch& t : I->host->input().touches()) {
        JSValue o = JS_NewObject(ctx);
        JS_SetPropertyStr(ctx, o, "id", JS_NewFloat64(ctx, static_cast<double>(t.id)));
        JS_SetPropertyStr(ctx, o, "position", array_of(ctx, {t.position.x, t.position.y}));
        JS_SetPropertyStr(ctx, o, "pressed", JS_NewBool(ctx, t.pressedThisFrame));
        JS_SetPropertyUint32(ctx, a, i++, o);
    }
    return a;
}

NATIVE(inValue) {
    SETUP;
    std::string a = arg_str(ctx, argc, argv, 0);
    JSValue exc = JS_UNDEFINED;
    if (!check_action(I, ctx, a, exc)) return exc;
    return float_to_js(ctx, I->host->input().action_value(a));
}

// A gamepad index argument (0..3). Returns false with the error thrown in `exc`.
bool pad_index(JSContext* ctx, int argc, JSValueConst* argv, int at, int& out, JSValue& exc) {
    double d = arg_num(ctx, argc, argv, at, 0);
    if (!(d >= 0 && d < kMaxGamepads) || d != std::floor(d)) {
        exc = throw_err(ctx, "gamepad index must be an integer from 0 to " + std::to_string(kMaxGamepads - 1) + ", got " +
                                 arg_str(ctx, argc, argv, at));
        return false;
    }
    out = static_cast<int>(d);
    return true;
}

bool pad_button(JSContext* ctx, const std::string& name, GamepadButton& out, JSValue& exc) {
    if (gamepad_button_from_name(name, out)) return true;
    exc = throw_err(ctx, "unknown gamepad button '" + name + "'. " + did_you_mean(name, gamepad_button_names()));
    return false;
}

bool pad_axis_name(JSContext* ctx, const std::string& name, GamepadAxis& out, JSValue& exc) {
    if (gamepad_axis_from_name(name, out)) return true;
    exc = throw_err(ctx, "unknown gamepad axis '" + name + "'. " + did_you_mean(name, gamepad_axis_names()));
    return false;
}

NATIVE(inPad) {  // (kind 0 connected|1 down|2 pressed|3 released|4 axis (deadzone applied)|5 raw axis, index, name)
    SETUP;
    int kind = static_cast<int>(arg_num(ctx, argc, argv, 0));
    int i = 0;
    JSValue exc = JS_UNDEFINED;
    if (!pad_index(ctx, argc, argv, 1, i, exc)) return exc;
    Input& in = I->host->input();
    if (kind == 0) return JS_NewBool(ctx, in.gamepad_connected(i));
    std::string name = arg_str(ctx, argc, argv, 2);
    if (kind >= 4) {
        GamepadAxis a{};
        if (!pad_axis_name(ctx, name, a, exc)) return exc;
        return float_to_js(ctx, kind == 4 ? in.gamepad_axis(i, a) : in.gamepad_raw_axis(i, a));
    }
    GamepadButton b{};
    if (!pad_button(ctx, name, b, exc)) return exc;
    return JS_NewBool(ctx, kind == 1 ? in.gamepad_down(i, b) : kind == 2 ? in.gamepad_pressed(i, b) : in.gamepad_released(i, b));
}

NATIVE(inDeadzone) {  // (value?) sets when given; returns the current deadzone
    SETUP;
    Input& in = I->host->input();
    if (argc > 0 && !JS_IsUndefined(argv[0])) {
        double d = arg_num(ctx, argc, argv, 0);
        if (!(d >= 0 && d < 1)) return throw_err(ctx, "input.deadzone must be a number from 0 up to (not including) 1, got " + arg_str(ctx, argc, argv, 0));
        in.set_gamepad_deadzone(static_cast<float>(d));
    }
    return float_to_js(ctx, in.gamepad_deadzone());
}

// test injection
NATIVE(inSetAction) {
    SETUP;
    std::string a = arg_str(ctx, argc, argv, 0);
    JSValue exc = JS_UNDEFINED;
    if (!check_action(I, ctx, a, exc)) return exc;
    I->host->input().set_action_override(a, arg_bool(ctx, argc, argv, 1, true));
    return JS_UNDEFINED;
}
NATIVE(inClearOverrides) {
    SETUP;
    I->host->input().clear_action_overrides();
    return JS_UNDEFINED;
}
NATIVE(inKeyEvent) {
    SETUP;
    JSValue exc = JS_UNDEFINED;
    bool ok = false;
    Key k = parse_key(I, ctx, arg_str(ctx, argc, argv, 0), exc, ok);
    if (!ok) return exc;
    I->host->input().on_key(k, arg_bool(ctx, argc, argv, 1, true));
    return JS_UNDEFINED;
}
NATIVE(inMouseMove) {
    SETUP;
    I->host->input().on_mouse_move({static_cast<float>(arg_num(ctx, argc, argv, 0)), static_cast<float>(arg_num(ctx, argc, argv, 1))});
    return JS_UNDEFINED;
}
NATIVE(inMouseEvent) {
    SETUP;
    bool ok = false;
    MouseButton b = parse_button(arg_str(ctx, argc, argv, 0), ok);
    if (!ok) return throw_err(ctx, "unknown mouse button '" + arg_str(ctx, argc, argv, 0) + "'; use \"left\", \"right\" or \"middle\"");
    I->host->input().on_mouse_button(b, arg_bool(ctx, argc, argv, 1, true));
    return JS_UNDEFINED;
}
NATIVE(inWheel) {
    SETUP;
    I->host->input().on_mouse_wheel(static_cast<float>(arg_num(ctx, argc, argv, 0)));
    return JS_UNDEFINED;
}

// ---- input settings: rebinding, last input, button names, text, cursor, keyboard ------------------------------------
NATIVE(inText) {
    SETUP;
    return JS_NewString(ctx, I->host->input().text_utf8().c_str());
}

NATIVE(inActions) {
    SETUP;
    return I->from_json(Json(I->host->input().action_names()));
}

NATIVE(inBindings) {
    SETUP;
    std::string a = arg_str(ctx, argc, argv, 0);
    JSValue exc = JS_UNDEFINED;
    if (!check_action(I, ctx, a, exc)) return exc;
    return I->from_json(Json(I->host->input().bindings(a)));
}

NATIVE(inRebind) {  // (action, bindings[])
    SETUP;
    std::string a = arg_str(ctx, argc, argv, 0);
    JSValue exc = JS_UNDEFINED;
    if (!check_action(I, ctx, a, exc)) return exc;
    Json list = argc > 1 ? I->to_json(argv[1]) : Json(nullptr);
    std::vector<std::string> names;
    bool ok = list.is_array();
    if (ok)
        for (const Json& item : list) {
            if (item.is_string()) names.push_back(item.get<std::string>());
            else ok = false;
        }
    if (!ok)
        return throw_err(ctx, "input.rebind(action, bindings) expects an array of binding names, e.g. "
                              "input.rebind(\"" + a + "\", [\"Space\", \"GamepadA\"]); got " + (list.is_null() ? "nothing" : describe_json_value(list)));
    std::vector<std::string> problems = I->host->input().rebind(a, names);
    if (!problems.empty()) return throw_err(ctx, join(problems, "\n"));
    return JS_UNDEFINED;
}

NATIVE(inResetBindings) {  // (action?)
    SETUP;
    std::string a = argc > 0 && !JS_IsUndefined(argv[0]) ? arg_str(ctx, argc, argv, 0) : "";
    JSValue exc = JS_UNDEFINED;
    if (!a.empty() && !check_action(I, ctx, a, exc)) return exc;
    I->host->input().reset_bindings(a);
    return JS_UNDEFINED;
}

NATIVE(inLastPressed) {
    SETUP;
    std::string s = I->host->input().last_pressed();
    return s.empty() ? JS_NULL : JS_NewString(ctx, s.c_str());
}

NATIVE(inLastDevice) {
    SETUP;
    return JS_NewString(ctx, input_device_name(I->host->input().last_device()));
}

NATIVE(inPadType) {  // (index)
    SETUP;
    int i = 0;
    JSValue exc = JS_UNDEFINED;
    if (!pad_index(ctx, argc, argv, 0, i, exc)) return exc;
    return JS_NewString(ctx, gamepad_type_name(I->host->input().gamepad_type(i)));
}

NATIVE(inButtonName) {  // (bindingOrAction, pad)
    SETUP;
    std::string n = arg_str(ctx, argc, argv, 0);
    int pad = 0;
    JSValue exc = JS_UNDEFINED;
    if (!pad_index(ctx, argc, argv, 1, pad, exc)) return exc;
    Input& in = I->host->input();
    if (!in.has_action(n) && !Input::is_binding_name(n)) {
        std::vector<std::string> names = in.action_names();
        for (const std::string& b : Input::binding_names()) names.push_back(b);
        return throw_err(ctx, "input.buttonName: unknown action or binding '" + n + "'. " + did_you_mean(n, names));
    }
    return JS_NewString(ctx, in.button_name(n, pad).c_str());
}

NATIVE(inVibrate) {  // (seconds)
    SETUP;
    I->host->input().vibrate(static_cast<float>(arg_num(ctx, argc, argv, 0)));
    return JS_UNDEFINED;
}

NATIVE(screenInsets) {  // [left, top, right, bottom] of the safe area, in design pixels
    SETUP;
    const EdgeInsets& e = W.safe_insets();
    return array_of(ctx, {e.left, e.top, e.right, e.bottom});
}

NATIVE(testSafeInsets) {  // (left, top, right, bottom): the device a test pretends to run on
    SETUP;
    W.set_safe_insets(EdgeInsets{static_cast<float>(arg_num(ctx, argc, argv, 0)), static_cast<float>(arg_num(ctx, argc, argv, 1)),
                                 static_cast<float>(arg_num(ctx, argc, argv, 2)), static_cast<float>(arg_num(ctx, argc, argv, 3))});
    return JS_UNDEFINED;
}

Vec2 design_size(Impl* I);

NATIVE(testSafeProfile) {  // (name) -> "" or what is wrong
    SETUP;
    const std::string name = arg_str(ctx, argc, argv, 0);
    EdgeInsets e;
    if (!safe_area_profile(name, design_size(I), e))
        return JS_NewString(ctx, ("unknown profile '" + name + "'. " + did_you_mean(name, safe_area_profile_names())).c_str());
    W.set_safe_insets(e);
    return JS_NewString(ctx, "");
}

NATIVE(testBack) {
    SETUP;
    I->host->input().on_back();
    return JS_UNDEFINED;
}

NATIVE(testVibrations) {
    SETUP;
    return I->from_json(Json(I->host->input().vibrations()));
}

NATIVE(inCursor) {  // (kind 0 mouse visible|1 mouse locked|2 keyboard shown, value?): sets when given; returns the state
    SETUP;
    int kind = static_cast<int>(arg_num(ctx, argc, argv, 0));
    Input& in = I->host->input();
    if (argc > 1 && !JS_IsUndefined(argv[1])) {
        bool v = arg_bool(ctx, argc, argv, 1);
        if (kind == 0) in.set_mouse_visible(v);
        else if (kind == 1) in.set_mouse_locked(v);
        else in.set_keyboard_shown(v);
    }
    return JS_NewBool(ctx, kind == 0 ? in.mouse_visible() : kind == 1 ? in.mouse_locked() : in.keyboard_shown());
}

// ---- window -----------------------------------------------------------------------------------------------------------
NATIVE(windowInfo) {  // the state window.* reads: a windowed run asks the window, any other run answers from factoria.json
    SETUP;
    WindowControl* win = I->host->window();
    Json p = I->host->project_settings();
    const Json display = p.is_object() && p.contains("display") && p["display"].is_object() ? p["display"] : Json::object();
    int w = display.value("width", 1280), h = display.value("height", 720);
    bool fullscreen = display.value("fullscreen", false), vsync = display.value("vsync", true);
    int dw = w, dh = h, cap = 0;
    if (win) {
        fullscreen = win->fullscreen();
        win->size(w, h);
        win->display_size(dw, dh);
        vsync = win->vsync();
        cap = win->frame_cap();
    }
    JSValue o = JS_NewObject(ctx);
    JS_SetPropertyStr(ctx, o, "available", JS_NewBool(ctx, win != nullptr));
    JS_SetPropertyStr(ctx, o, "fullscreen", JS_NewBool(ctx, fullscreen));
    JS_SetPropertyStr(ctx, o, "width", JS_NewInt32(ctx, w));
    JS_SetPropertyStr(ctx, o, "height", JS_NewInt32(ctx, h));
    JS_SetPropertyStr(ctx, o, "displayWidth", JS_NewInt32(ctx, dw));
    JS_SetPropertyStr(ctx, o, "displayHeight", JS_NewInt32(ctx, dh));
    JS_SetPropertyStr(ctx, o, "vsync", JS_NewBool(ctx, vsync));
    JS_SetPropertyStr(ctx, o, "frameCap", JS_NewInt32(ctx, cap));
    return o;
}

NATIVE(windowSet) {  // (kind 0 fullscreen|1 size|2 vsync|3 frame cap, a, b) -> "" or the reason it did not happen
    SETUP;
    WindowControl* win = I->host->window();
    if (!win)
        return JS_NewString(ctx, "this run has no window (headless run / test). Full screen, size, vsync and the frame cap only "
                                 "apply to a windowed run (factoria run, an exported game); check window.available first.");
    int kind = static_cast<int>(arg_num(ctx, argc, argv, 0));
    std::string err;
    if (kind == 0) err = win->set_fullscreen(arg_bool(ctx, argc, argv, 1));
    else if (kind == 1) err = win->set_size(static_cast<int>(arg_num(ctx, argc, argv, 1)), static_cast<int>(arg_num(ctx, argc, argv, 2)));
    else if (kind == 2) err = win->set_vsync(arg_bool(ctx, argc, argv, 1));
    else err = win->set_frame_cap(static_cast<int>(arg_num(ctx, argc, argv, 1)));
    return JS_NewString(ctx, err.c_str());
}

// ---- audio --------------------------------------------------------------------------------------------------------
NATIVE(audioPlay) {
    SETUP;
    std::string path = arg_str(ctx, argc, argv, 0);
    PlayParams pp;
    pp.volume = static_cast<float>(arg_num(ctx, argc, argv, 1, 1));
    pp.pitch = static_cast<float>(arg_num(ctx, argc, argv, 2, 1));
    pp.pan = static_cast<float>(arg_num(ctx, argc, argv, 3, 0));
    pp.loop = arg_bool(ctx, argc, argv, 4, false);
    std::string bus = arg_str(ctx, argc, argv, 5);
    if (!bus.empty()) pp.bus = bus;
    const VoiceId voice = I->host->audio().play(path, pp);
    // (text, key, speaker, seconds): a caption that lives with the sound (seconds > 0: for that long instead). A clip that could
    // not play (voice 0, the error is logged) still shows its caption for `seconds`, or 3 s.
    const std::string captionText = arg_str(ctx, argc, argv, 6), captionKey = arg_str(ctx, argc, argv, 7);
    if (!captionText.empty() || !captionKey.empty()) {
        const double seconds = arg_num(ctx, argc, argv, 9, 0);
        CaptionLine line;
        line.text = captionText.empty() ? captionKey : captionText;
        line.key = captionKey;
        line.speaker = arg_str(ctx, argc, argv, 8);
        line.source = "audio:" + path;
        line.voice = voice;
        if (seconds > 0) line.endsAt = W.time() + seconds;
        else if (voice == 0) line.endsAt = W.time() + 3.0;
        I->host->captions().add(std::move(line), I->host->i18n());
    }
    return JS_NewInt32(ctx, static_cast<int32_t>(voice));
}
NATIVE(audioStop) {
    SETUP;
    const VoiceId voice = static_cast<VoiceId>(arg_num(ctx, argc, argv, 0));
    I->host->audio().stop(voice);
    I->host->captions().remove_voice(voice);
    return JS_UNDEFINED;
}
NATIVE(audioStopAll) {
    SETUP;
    I->host->audio().stop_all();
    I->host->captions().remove_all_voices();
    return JS_UNDEFINED;
}
NATIVE(captionAdd) {  // (text, key, speaker, seconds): a caption without a sound
    SETUP;
    CaptionLine line;
    line.key = arg_str(ctx, argc, argv, 1);
    line.text = arg_str(ctx, argc, argv, 0);
    if (line.text.empty()) line.text = line.key;
    line.speaker = arg_str(ctx, argc, argv, 2);
    line.source = "ui";
    line.endsAt = W.time() + arg_num(ctx, argc, argv, 3, 3);
    I->host->captions().add(std::move(line), I->host->i18n());
    return JS_UNDEFINED;
}
NATIVE(captionClear) {
    SETUP;
    I->host->captions().clear();
    return JS_UNDEFINED;
}
NATIVE(captionList) {  // () -> [{text, speaker, key, source}], oldest first
    SETUP;
    Json list = Json::array();
    for (const CaptionLine& l : I->host->captions().lines())
        list.push_back(Json::object({{"text", l.text}, {"speaker", l.speaker}, {"key", l.key}, {"source", l.source}}));
    return I->from_json(list);
}
NATIVE(audioMusic) {
    SETUP;
    I->host->audio().play_music(arg_str(ctx, argc, argv, 0), static_cast<float>(arg_num(ctx, argc, argv, 1, 0.6)), static_cast<float>(arg_num(ctx, argc, argv, 2, 0.5)));
    return JS_UNDEFINED;
}
NATIVE(audioStopMusic) {
    SETUP;
    I->host->audio().stop_music(static_cast<float>(arg_num(ctx, argc, argv, 0, 0.5)));
    return JS_UNDEFINED;
}
NATIVE(audioVolume) {
    SETUP;
    std::string bus = to_lower(arg_str(ctx, argc, argv, 0));
    float v = static_cast<float>(arg_num(ctx, argc, argv, 1, 1));
    if (bus == "master") I->host->audio().set_master_volume(v);
    else if (bus == "sfx" || bus == "music" || bus == "ui") I->host->audio().set_bus_volume(bus, v);
    else return throw_err(ctx, "unknown audio bus '" + bus + "'; use \"master\", \"sfx\", \"music\" or \"ui\"");
    return JS_UNDEFINED;
}

NATIVE(audioGetVolume) {
    SETUP;
    const std::string bus = to_lower(arg_str(ctx, argc, argv, 0));
    const float v = I->host->audio().bus_volume(bus);
    if (v < 0) return throw_err(ctx, "unknown audio bus '" + bus + "'; use \"master\", \"sfx\", \"music\" or \"ui\"");
    return JS_NewFloat64(ctx, v);
}

NATIVE(audioLog) {  // (clear) -> play log entries, oldest first
    SETUP;
    Json list = Json::array();
    for (const AudioEvent& ev : I->host->audio().play_log()) list.push_back(ev.to_json());
    if (arg_bool(ctx, argc, argv, 0, false)) I->host->audio().clear_play_log();
    return I->from_json(list);
}

// ---- physics ------------------------------------------------------------------------------------------------------
JSValue hit_to_js(JSContext* ctx, const std::optional<RaycastHit>& hit) {
    if (!hit) return JS_NULL;
    JSValue o = JS_NewObject(ctx);
    JS_SetPropertyStr(ctx, o, "entity", ent_val(ctx, hit->entity));
    JS_SetPropertyStr(ctx, o, "point", array_of(ctx, {hit->point.x, hit->point.y, hit->point.z}));
    JS_SetPropertyStr(ctx, o, "normal", array_of(ctx, {hit->normal.x, hit->normal.y, hit->normal.z}));
    JS_SetPropertyStr(ctx, o, "distance", float_to_js(ctx, hit->distance));
    return o;
}

NATIVE(raycast2d) {
    SETUP;
    Vec2 a{static_cast<float>(arg_num(ctx, argc, argv, 0)), static_cast<float>(arg_num(ctx, argc, argv, 1))};
    Vec2 b{static_cast<float>(arg_num(ctx, argc, argv, 2)), static_cast<float>(arg_num(ctx, argc, argv, 3))};
    RaycastOptions o;
    o.mask = static_cast<std::int32_t>(arg_num(ctx, argc, argv, 4, -1));
    o.ignore = ent_from(ctx, argc > 5 ? argv[5] : JS_NULL);
    o.ignoreTriggers = arg_bool(ctx, argc, argv, 6, true);
    return hit_to_js(ctx, I->host->physics().raycast2d(W, a, b, o));
}
NATIVE(raycast3d) {
    SETUP;
    Vec3 o{static_cast<float>(arg_num(ctx, argc, argv, 0)), static_cast<float>(arg_num(ctx, argc, argv, 1)), static_cast<float>(arg_num(ctx, argc, argv, 2))};
    Vec3 d{static_cast<float>(arg_num(ctx, argc, argv, 3)), static_cast<float>(arg_num(ctx, argc, argv, 4)), static_cast<float>(arg_num(ctx, argc, argv, 5))};
    RaycastOptions opt;
    opt.mask = static_cast<std::int32_t>(arg_num(ctx, argc, argv, 7, -1));
    opt.ignore = ent_from(ctx, argc > 8 ? argv[8] : JS_NULL);
    opt.ignoreTriggers = arg_bool(ctx, argc, argv, 9, true);
    return hit_to_js(ctx, I->host->physics().raycast3d(W, o, d, static_cast<float>(arg_num(ctx, argc, argv, 6, 1000)), opt));
}
// Shape casts. The shape arrives as the plain object the script wrote; cast_shape_from_json teaches what is wrong with it.
bool cast_shape_arg(Impl* I, JSContext* ctx, int argc, JSValueConst* argv, bool is3d, CastShape& out, JSValue& exc) {
    auto shape = cast_shape_from_json(I->to_json(argc > 0 ? argv[0] : JS_UNDEFINED), is3d);
    if (!shape.ok()) {
        exc = throw_err(ctx, "physics.shapeCast(shape, from, to): " + shape.error().to_string());
        return false;
    }
    out = *shape;
    return true;
}
NATIVE(shapeCast2d) {  // (shape, fromX, fromY, toX, toY, mask, ignore, ignoreTriggers)
    SETUP;
    CastShape shape;
    JSValue exc = JS_UNDEFINED;
    if (!cast_shape_arg(I, ctx, argc, argv, false, shape, exc)) return exc;
    Vec2 a{static_cast<float>(arg_num(ctx, argc, argv, 1)), static_cast<float>(arg_num(ctx, argc, argv, 2))};
    Vec2 b{static_cast<float>(arg_num(ctx, argc, argv, 3)), static_cast<float>(arg_num(ctx, argc, argv, 4))};
    RaycastOptions o;
    o.mask = static_cast<std::int32_t>(arg_num(ctx, argc, argv, 5, -1));
    o.ignore = ent_from(ctx, argc > 6 ? argv[6] : JS_NULL);
    o.ignoreTriggers = arg_bool(ctx, argc, argv, 7, true);
    return hit_to_js(ctx, I->host->physics().shape_cast2d(W, shape, a, b, o));
}
NATIVE(shapeCast3d) {  // (shape, fromX, fromY, fromZ, toX, toY, toZ, mask, ignore, ignoreTriggers)
    SETUP;
    CastShape shape;
    JSValue exc = JS_UNDEFINED;
    if (!cast_shape_arg(I, ctx, argc, argv, true, shape, exc)) return exc;
    Vec3 a{static_cast<float>(arg_num(ctx, argc, argv, 1)), static_cast<float>(arg_num(ctx, argc, argv, 2)), static_cast<float>(arg_num(ctx, argc, argv, 3))};
    Vec3 b{static_cast<float>(arg_num(ctx, argc, argv, 4)), static_cast<float>(arg_num(ctx, argc, argv, 5)), static_cast<float>(arg_num(ctx, argc, argv, 6))};
    RaycastOptions o;
    o.mask = static_cast<std::int32_t>(arg_num(ctx, argc, argv, 7, -1));
    o.ignore = ent_from(ctx, argc > 8 ? argv[8] : JS_NULL);
    o.ignoreTriggers = arg_bool(ctx, argc, argv, 9, true);
    return hit_to_js(ctx, I->host->physics().shape_cast3d(W, shape, a, b, o));
}
// Navigation (nav.findPath / nav.bake in factoria.js): the same Physics calls as the nav.* commands.
NATIVE(navFindPath) {  // ({ from: [x,y,z], to: [x,y,z], radius?, snap?, closest?, mesh? })
    SETUP;
    const Json a = I->to_json(argc > 0 ? argv[0] : JS_UNDEFINED);
    auto pt = [&](const char* key) {
        const Json v = a.value(key, Json());
        return Vec3{v[0].get<float>(), v[1].get<float>(), v[2].get<float>()};
    };
    NavPathOptions o;
    o.radius = a.value("radius", -1.0f);
    o.snap = a.value("snap", -1.0f);
    o.closest = a.value("closest", false);
    o.mesh = a.value("mesh", std::string());
    auto r = I->host->physics().nav_find_path(W, pt("from"), pt("to"), o);
    if (!r.ok()) return throw_err(ctx, "nav.findPath(from, to): " + r.error().to_string());
    return I->from_json(r.value().to_json());
}
NATIVE(navBake) {  // (mesh)
    SETUP;
    auto r = I->host->physics().nav_bake(W, arg_str(ctx, argc, argv, 0));
    if (!r.ok()) return throw_err(ctx, "nav.bake(mesh): " + r.error().to_string());
    Json out = Json::array();
    for (const NavBakeStats& st : r.value()) out.push_back(st.to_json());
    return I->from_json(out);
}
NATIVE(overlapCircle) {
    SETUP;
    return entities_array(ctx, I->host->physics().overlap_circle2d(W, {static_cast<float>(arg_num(ctx, argc, argv, 0)), static_cast<float>(arg_num(ctx, argc, argv, 1))},
                                                                   static_cast<float>(arg_num(ctx, argc, argv, 2)), static_cast<std::int32_t>(arg_num(ctx, argc, argv, 3, -1))));
}
NATIVE(overlapBox) {
    SETUP;
    Rect r{static_cast<float>(arg_num(ctx, argc, argv, 0)), static_cast<float>(arg_num(ctx, argc, argv, 1)), static_cast<float>(arg_num(ctx, argc, argv, 2)), static_cast<float>(arg_num(ctx, argc, argv, 3))};
    return entities_array(ctx, I->host->physics().overlap_box2d(W, r, static_cast<std::int32_t>(arg_num(ctx, argc, argv, 4, -1))));
}
NATIVE(overlapSphere) {
    SETUP;
    Vec3 c{static_cast<float>(arg_num(ctx, argc, argv, 0)), static_cast<float>(arg_num(ctx, argc, argv, 1)), static_cast<float>(arg_num(ctx, argc, argv, 2))};
    return entities_array(ctx, I->host->physics().overlap_sphere3d(W, c, static_cast<float>(arg_num(ctx, argc, argv, 3)), static_cast<std::int32_t>(arg_num(ctx, argc, argv, 4, -1))));
}
NATIVE(physicsApply) {  // (kind 0 impulse|1 force|2 velocity, entity, x, y, z)
    SETUP;
    int kind = static_cast<int>(arg_num(ctx, argc, argv, 0));
    Entity e;
    JSValue exc = JS_UNDEFINED;
    if (!need_entity(I, ctx, argc > 1 ? argv[1] : JS_UNDEFINED, e, exc)) return exc;
    Vec3 v{static_cast<float>(arg_num(ctx, argc, argv, 2)), static_cast<float>(arg_num(ctx, argc, argv, 3)), static_cast<float>(arg_num(ctx, argc, argv, 4))};
    Physics& ph = I->host->physics();
    if (kind == 0) ph.apply_impulse(W, e, v);
    else if (kind == 1) ph.apply_force(W, e, v);
    else {
        ph.set_velocity(W, e, v);
        // keep the mirrored component field in sync so the next physics step does not overwrite it
        if (auto* rb = W.get<RigidBody2D>(e)) rb->velocity = {v.x, v.y};
        if (auto* rb3 = W.get<RigidBody3D>(e)) rb3->velocity = v;
    }
    return JS_UNDEFINED;
}

NATIVE(moveCharacter) {  // (entity, dx, dy, dz) -> { position, moved, isGrounded, groundNormal, ground, hitWall, hitCeiling }
    SETUP;
    Entity e;
    JSValue exc = JS_UNDEFINED;
    if (!need_entity(I, ctx, argc > 0 ? argv[0] : JS_UNDEFINED, e, exc)) return exc;
    Vec3 delta{static_cast<float>(arg_num(ctx, argc, argv, 1)), static_cast<float>(arg_num(ctx, argc, argv, 2)), static_cast<float>(arg_num(ctx, argc, argv, 3))};
    if (!W.get<CharacterController3D>(e))
        return throw_err(ctx, "physics.moveCharacter(entity, delta): entity '" + W.id_of(e) + "' has no CharacterController3D. Add the component "
                              "(radius, height, stepOffset, slopeLimit) to the entity that walks, or use RigidBody3D.velocity for a physics body.");
    auto r = I->host->physics().move_character(W, e, delta);
    if (!r) return throw_err(ctx, "physics.moveCharacter(entity, delta): the character could not move (delta must be finite numbers; the entity must be enabled).");
    JSValue o = JS_NewObject(ctx);
    JS_SetPropertyStr(ctx, o, "position", array_of(ctx, {r->position.x, r->position.y, r->position.z}));
    JS_SetPropertyStr(ctx, o, "moved", array_of(ctx, {r->moved.x, r->moved.y, r->moved.z}));
    JS_SetPropertyStr(ctx, o, "isGrounded", JS_NewBool(ctx, r->isGrounded));
    JS_SetPropertyStr(ctx, o, "groundNormal", array_of(ctx, {r->groundNormal.x, r->groundNormal.y, r->groundNormal.z}));
    JS_SetPropertyStr(ctx, o, "ground", r->isGrounded ? ent_val(ctx, r->ground) : JS_NULL);
    JS_SetPropertyStr(ctx, o, "hitWall", JS_NewBool(ctx, r->hitWall));
    JS_SetPropertyStr(ctx, o, "hitCeiling", JS_NewBool(ctx, r->hitCeiling));
    return o;
}

// ---- camera / debug -----------------------------------------------------------------------------------------------
NATIVE(cameraMain) {
    SETUP;
    Entity best = kNullEntity;
    int bestDepth = 0;
    W.each<Camera>([&](Entity e, Camera& c) {
        if (!c.primary || !W.active_in_hierarchy(e)) return;
        if (best.is_null() || c.depth < bestDepth) { best = e; bestDepth = c.depth; }
    });
    return ent_val(ctx, best);
}

Vec2 design_size(Impl* I) {
    if (Renderer* r = I->host->renderer(); r && r->initialized()) return {static_cast<float>(r->target_width()), static_cast<float>(r->target_height())};
    return I->host->design_size();
}

float camera_scale(Impl* I, World& W, Entity cam, Vec2 size) {
    const Camera* c = cam.is_null() ? nullptr : W.get<Camera>(cam);
    float ortho = c && c->orthoSize > 0 ? c->orthoSize : size.y * 0.5f;
    (void)I;
    return size.y * 0.5f / ortho;
}

NATIVE(worldToScreen) {
    SETUP;
    Vec3 p{static_cast<float>(arg_num(ctx, argc, argv, 0)), static_cast<float>(arg_num(ctx, argc, argv, 1)), static_cast<float>(arg_num(ctx, argc, argv, 2))};
    if (Renderer* r = I->host->renderer(); r && r->initialized()) {
        Vec2 s = r->world_to_screen(p);
        return array_of(ctx, {s.x, s.y});
    }
    Vec2 size = design_size(I);
    Entity cam = kNullEntity;
    int bestDepth = 0;
    W.each<Camera>([&](Entity e, Camera& c) {
        if (c.primary && W.active_in_hierarchy(e) && (cam.is_null() || c.depth < bestDepth)) { cam = e; bestDepth = c.depth; }
    });
    Vec3 cp = cam.is_null() ? Vec3{} : W.world_position(cam);
    float s = camera_scale(I, W, cam, size);
    return array_of(ctx, {size.x * 0.5f + (p.x - cp.x) * s, size.y * 0.5f - (p.y - cp.y) * s});
}

NATIVE(screenToWorld) {
    SETUP;
    Vec2 sp{static_cast<float>(arg_num(ctx, argc, argv, 0)), static_cast<float>(arg_num(ctx, argc, argv, 1))};
    float depth = static_cast<float>(arg_num(ctx, argc, argv, 2));
    if (Renderer* r = I->host->renderer(); r && r->initialized()) {
        Vec3 w = r->screen_to_world(sp, depth);
        return array_of(ctx, {w.x, w.y, w.z});
    }
    Vec2 size = design_size(I);
    Entity cam = kNullEntity;
    int bestDepth = 0;
    W.each<Camera>([&](Entity e, Camera& c) {
        if (c.primary && W.active_in_hierarchy(e) && (cam.is_null() || c.depth < bestDepth)) { cam = e; bestDepth = c.depth; }
    });
    Vec3 cp = cam.is_null() ? Vec3{} : W.world_position(cam);
    float s = camera_scale(I, W, cam, size);
    return array_of(ctx, {cp.x + (sp.x - size.x * 0.5f) / s, cp.y - (sp.y - size.y * 0.5f) / s, depth});
}

Color arg_color(JSContext* ctx, int argc, JSValueConst* argv, int i) {
    Color c = Color::white();
    if (i < argc && JS_IsObject(argv[i])) {
        float* f = &c.r;
        for (uint32_t k = 0; k < 4; ++k) {
            JSValue x = JS_GetPropertyUint32(ctx, argv[i], k);
            if (JS_IsNumber(x)) { double d = 0; JS_ToFloat64(ctx, &d, x); f[k] = static_cast<float>(d); }
            JS_FreeValue(ctx, x);
        }
    }
    return c;
}

NATIVE(debugDraw) {  // (kind, ...)
    SETUP;
    Renderer* r = I->host->renderer();
    if (!r || !r->initialized()) return JS_UNDEFINED;
    DebugDraw& d = r->debug();
    int kind = static_cast<int>(arg_num(ctx, argc, argv, 0));
    auto n = [&](int i) { return static_cast<float>(arg_num(ctx, argc, argv, i)); };
    switch (kind) {
        case 0: d.line({n(1), n(2), n(3)}, {n(4), n(5), n(6)}, arg_color(ctx, argc, argv, 7), 1.0f); break;
        case 1: d.rect({n(1), n(2), n(3), n(4)}, arg_color(ctx, argc, argv, 5), arg_bool(ctx, argc, argv, 6)); break;
        case 2: d.circle({n(1), n(2)}, n(3), arg_color(ctx, argc, argv, 4), arg_bool(ctx, argc, argv, 5)); break;
        case 3: d.text({n(1), n(2)}, arg_str(ctx, argc, argv, 3), arg_color(ctx, argc, argv, 4), argc > 5 ? n(5) : 16.0f); break;
        case 4: d.box({n(1), n(2), n(3)}, {n(4), n(5), n(6)}, arg_color(ctx, argc, argv, 7)); break;
        case 5: d.sphere({n(1), n(2), n(3)}, n(4), arg_color(ctx, argc, argv, 5)); break;
        default: break;
    }
    return JS_UNDEFINED;
}

// ---- game / storage / commands ------------------------------------------------------------------------------------
NATIVE(quit) {
    SETUP;
    I->host->request_quit();
    return JS_UNDEFINED;
}

NATIVE(project) {
    SETUP;
    return I->from_json(I->host->project_settings());
}

NATIVE(screenSize) {
    SETUP;
    Vec2 s = design_size(I);
    return array_of(ctx, {s.x, s.y});
}

// game.notices(): the third-party parts of the runtime inside every game (what FACTORIA_NOTICES.txt holds), for credits.
NATIVE(notices) {
    SETUP;
    Json out = Json::array();
    for (const ThirdPartyComponent& c : third_party_components())
        if (c.inGames) out.push_back({{"name", c.name}, {"url", c.url}, {"license", c.license}, {"usedFor", c.usedFor}});
    return I->from_json(out);
}

NATIVE(platform) {
    return JS_NewString(ctx, FA_PLATFORM_NAME);
}

// [textScale, reduceMotion, highContrast, screenReader]. Only a game with its own window reads the system; headless runs,
// tests and the editor give the defaults (or what game.setAccessibility set), so that output never depends on the machine.
NATIVE(accessibility) {
    SETUP;
    const AccessibilitySettings s = I->host->window() ? system_accessibility() : I->testAccessibility;
    JSValue a = JS_NewArray(ctx);
    JS_SetPropertyUint32(ctx, a, 0, JS_NewFloat64(ctx, s.textScale));
    JS_SetPropertyUint32(ctx, a, 1, JS_NewBool(ctx, s.reduceMotion));
    JS_SetPropertyUint32(ctx, a, 2, JS_NewBool(ctx, s.highContrast));
    JS_SetPropertyUint32(ctx, a, 3, JS_NewBool(ctx, s.screenReader));
    return a;
}

// The device the game runs on: the host's values (fixed ones headless) with what game.setDevice set in a test on top.
NATIVE(deviceInfo) {
    SETUP;
    Json d = I->host->device_info();
    for (auto it = I->testDevice.begin(); it != I->testDevice.end(); ++it) d[it.key()] = it.value();
    return I->from_json(d);
}

NATIVE(testDevice) {  // (overrides object); no argument = back to the host's values
    SETUP;
    I->testDevice = argc > 0 ? I->to_json(argv[0]) : Json::object();
    if (!I->testDevice.is_object()) I->testDevice = Json::object();
    return JS_UNDEFINED;
}

NATIVE(renderStatsNow) {  // the renderer's stats of the picture now (a frame is drawn first when needed), or null
    SETUP;
    return I->from_json(I->host->render_stats_now());
}

NATIVE(renderScaleGet) {
    SETUP;
    return JS_NewFloat64(ctx, I->host->render_scale());
}

NATIVE(renderScaleSet) {  // "" or the reason it did not happen
    SETUP;
    const std::string err = I->host->set_render_scale(arg_num(ctx, argc, argv, 0, 1.0));
    return JS_NewString(ctx, err.c_str());
}

NATIVE(testAccessibility) {  // (textScale, reduceMotion, highContrast, screenReader); no arguments = back to the defaults
    SETUP;
    AccessibilitySettings s;
    if (argc >= 4) {
        s.textScale = static_cast<float>(arg_num(ctx, argc, argv, 0));
        s.reduceMotion = arg_bool(ctx, argc, argv, 1, false);
        s.highContrast = arg_bool(ctx, argc, argv, 2, false);
        s.screenReader = arg_bool(ctx, argc, argv, 3, false);
    }
    I->testAccessibility = sanitize_accessibility(s);
    return JS_UNDEFINED;
}

NATIVE(storageGet) {
    SETUP;
    I->load_storage();
    std::string key = arg_str(ctx, argc, argv, 0);
    if (!I->storage.contains(key)) return JS_UNDEFINED;
    return I->from_json(I->storage[key]);
}
NATIVE(storageSet) {
    SETUP;
    I->load_storage();
    std::string key = arg_str(ctx, argc, argv, 0);
    if (key.empty()) return throw_err(ctx, "storage.set(key, value): key must be a non-empty string");
    I->storage[key] = I->to_json(argc > 1 ? argv[1] : JS_NULL);
    I->save_storage();
    return JS_UNDEFINED;
}
NATIVE(storageRemove) {
    SETUP;
    I->load_storage();
    I->storage.erase(arg_str(ctx, argc, argv, 0));
    I->save_storage();
    return JS_UNDEFINED;
}
NATIVE(storageKeys) {
    SETUP;
    I->load_storage();
    JSValue a = JS_NewArray(ctx);
    uint32_t i = 0;
    for (auto it = I->storage.begin(); it != I->storage.end(); ++it) JS_SetPropertyUint32(ctx, a, i++, JS_NewString(ctx, it.key().c_str()));
    return a;
}
NATIVE(storageCorrupt) {
    SETUP;
    I->load_storage();
    return JS_NewBool(ctx, I->storageCorrupt);
}
NATIVE(storageClear) {
    SETUP;
    I->load_storage();  // a damaged file is kept before the cleared data replaces it
    I->storage = Json::object();
    I->storageLoaded = true;
    I->save_storage();
    return JS_UNDEFINED;
}

NATIVE(callCommand) {
    SETUP;
    std::string name = arg_str(ctx, argc, argv, 0);
    Json args = argc > 1 ? I->to_json(argv[1]) : Json::object();
    if (args.is_null()) args = Json::object();
    CommandResult r = I->host->commands().call(name, args);
    JSValue o = JS_NewObject(ctx);
    JS_SetPropertyStr(ctx, o, "ok", JS_NewBool(ctx, r.ok));
    if (r.ok) JS_SetPropertyStr(ctx, o, "result", I->from_json(r.result));
    else JS_SetPropertyStr(ctx, o, "error", I->from_json(r.error));
    return o;
}

NATIVE(commands) {
    SETUP;
    return I->from_json(I->host->commands().describe());
}

// ---- native plugins (ScriptSystem::set_plugins) -------------------------------------------------------------------
NATIVE(pluginList) {  // [{name, error?, functions: [{name, doc}]}]
    SETUP;
    return I->from_json(I->plugins_json());
}

NATIVE(pluginCall) {  // (plugin, function, args array) -> {ok, result} | {ok: false, error: {message, hint}}
    SETUP;
    const std::string plugin = arg_str(ctx, argc, argv, 0), name = arg_str(ctx, argc, argv, 1);
    Json args = argc > 2 ? I->to_json(argv[2]) : Json::array();
    JSValue o = JS_NewObject(ctx);
    for (const ScriptPlugin& p : I->plugins) {
        if (p.name != plugin) continue;
        for (const ScriptPlugin::Function& f : p.functions) {
            if (f.name != name) continue;
            try {
                Json result = f.call(args);
                JS_SetPropertyStr(ctx, o, "ok", JS_NewBool(ctx, true));
                JS_SetPropertyStr(ctx, o, "result", I->from_json(result));
            } catch (const CommandError& e) {
                JS_SetPropertyStr(ctx, o, "ok", JS_NewBool(ctx, false));
                JS_SetPropertyStr(ctx, o, "error", I->from_json(Json::object({{"message", e.what()}, {"hint", e.hint}})));
            }
            return o;
        }
    }
    return o;  // unreachable: the prelude only calls the functions pluginList returned
}

// ---- platform services (fa/services/platform.h; the `platform` object of the prelude) ------------------------------
NATIVE(platformStart) {  // (method, args) -> {id, answer?} | {mistake: {message, hint}}
    SETUP;
    const std::string method = arg_str(ctx, argc, argv, 0);
    Json args = argc > 1 ? I->to_json(argv[1]) : Json::object();
    if (args.is_null()) args = Json::object();
    PlatformServices* services = I->host->platform_services();
    JSValue o = JS_NewObject(ctx);
    if (!services) {
        JS_SetPropertyStr(ctx, o, "mistake", I->from_json(Json::object({{"message", "this run has no platform services"}, {"hint", ""}})));
        return o;
    }
    auto started = services->start(method, args);
    if (!started.ok()) {
        JS_SetPropertyStr(ctx, o, "mistake", I->from_json(Json::object({{"message", started.error().message}, {"hint", started.error().hint}})));
        return o;
    }
    JS_SetPropertyStr(ctx, o, "id", JS_NewFloat64(ctx, static_cast<double>(started->id)));
    if (started->answer) JS_SetPropertyStr(ctx, o, "answer", I->from_json(platform_answer_json(*started->answer)));
    return o;
}

NATIVE(platformInfo) {  // {backend, services, player: {id, name, signedIn}, pending}
    SETUP;
    PlatformServices* services = I->host->platform_services();
    if (services) return I->from_json(services->info());
    return I->from_json(Json::object({{"backend", "none"},
                                      {"services", Json::array()},
                                      {"player", Json::object({{"id", ""}, {"name", ""}, {"signedIn", false}})},
                                      {"pending", 0}}));
}

// ---- i18n (fa/core/i18n.h; the `i18n` object of the prelude) -------------------------------------------------------------
NATIVE(i18nInfo) {  // {enabled, language, defaultLanguage, languages, names, systemLanguages}
    SETUP;
    const I18n* L = I->host->i18n();
    Json j = Json::object({{"enabled", L && L->enabled()}, {"language", ""}, {"defaultLanguage", ""}, {"languages", Json::array()},
                           {"names", Json::object()}, {"systemLanguages", Json::array()}, {"direction", "ltr"}});
    if (L && L->enabled()) {
        j["language"] = L->language();
        j["defaultLanguage"] = L->default_language();
        j["direction"] = L->rtl() ? "rtl" : "ltr";
        for (const std::string& code : L->languages()) {
            j["languages"].push_back(code);
            j["names"][code] = L->name(code);
        }
        // The player's languages only in a game with its own window: headless runs and tests must not depend on the machine.
        if (I->host->window())
            for (const std::string& tag : system_languages()) j["systemLanguages"].push_back(tag);
    }
    return I->from_json(j);
}

NATIVE(i18nT) {  // (key, args) -> the string; the key itself when no table has it (warns once)
    SETUP;
    const std::string key = arg_str(ctx, argc, argv, 0);
    const I18n* L = I->host->i18n();
    if (!L) return JS_NewString(ctx, key.c_str());
    const Json args = argc > 1 ? I->to_json(argv[1]) : Json();
    const std::string text = L->t(key, args);
    return JS_NewStringLen(ctx, text.data(), text.size());
}

NATIVE(i18nHas) {
    SETUP;
    const I18n* L = I->host->i18n();
    return JS_NewBool(ctx, L && L->has(arg_str(ctx, argc, argv, 0)));
}

NATIVE(i18nSet) {  // (language) -> "" when done, else why not
    SETUP;
    return JS_NewString(ctx, I->host->set_language(arg_str(ctx, argc, argv, 0)).c_str());
}

// ---- test helpers -------------------------------------------------------------------------------------------------
NATIVE(testLoad) {
    SETUP;
    std::string path = arg_str(ctx, argc, argv, 0);
    if (path.empty()) path = W.scene_path();
    std::string err = I->host->load_scene_now(path);
    if (!err.empty()) return JS_NewString(ctx, err.c_str());
    I->after_test_load();
    return JS_NewString(ctx, "");
}

NATIVE(testStorageText) {
    SETUP;
    if (argc > 0 && JS_IsString(argv[0])) I->storageTextHook = arg_str(ctx, argc, argv, 0);
    else I->storageTextHook.reset();
    I->storage = Json::object();
    I->storageLoaded = false;
    return JS_UNDEFINED;
}

NATIVE(testLoadJson) {
    SETUP;
    Json scene = argc > 0 ? I->to_json(argv[0]) : Json(nullptr);
    if (!scene.is_object()) return JS_NewString(ctx, "game.loadJson(scene) expects a scene object like { format: \"factoria.scene/1\", entities: [...] }");
    std::string err = I->host->load_scene_json_now(scene, "game.loadJson");
    if (!err.empty()) return JS_NewString(ctx, err.c_str());
    I->after_test_load();
    return JS_NewString(ctx, "");
}

NATIVE(testTouch) {  // (kind 0 begin|1 move|2 end, id, x, y)
    SETUP;
    int kind = static_cast<int>(arg_num(ctx, argc, argv, 0));
    auto id = static_cast<std::uint64_t>(arg_num(ctx, argc, argv, 1, 1));
    Vec2 p{static_cast<float>(arg_num(ctx, argc, argv, 2)), static_cast<float>(arg_num(ctx, argc, argv, 3))};
    Input& in = I->host->input();
    if (kind == 0) in.on_touch_begin(id, p);
    else if (kind == 1) in.on_touch_move(id, p);
    else in.on_touch_end(id);
    return JS_UNDEFINED;
}

NATIVE(testPad) {  // (kind 0 press|1 release|2 axis|3 connect|4 disconnect|5 set the pad type, index, name, value)
    SETUP;
    int kind = static_cast<int>(arg_num(ctx, argc, argv, 0));
    int i = 0;
    JSValue exc = JS_UNDEFINED;
    if (!pad_index(ctx, argc, argv, 1, i, exc)) return exc;
    Input& in = I->host->input();
    std::string name = arg_str(ctx, argc, argv, 2);
    if (kind == 0 || kind == 1) {
        GamepadButton b{};
        if (!pad_button(ctx, name, b, exc)) return exc;
        in.on_gamepad_button(i, b, kind == 0);
    } else if (kind == 2) {
        GamepadAxis a{};
        if (!pad_axis_name(ctx, name, a, exc)) return exc;
        if (argc < 4 || !JS_IsNumber(argv[3])) return throw_err(ctx, "game.gamepad(" + std::to_string(i) + ").axis('" + name + "', value): value must be a number (-1..1, triggers 0..1)");
        in.on_gamepad_axis(i, a, static_cast<float>(arg_num(ctx, argc, argv, 3)));
    } else if (kind == 5) {
        GamepadType t{};
        if (!gamepad_type_from_name(name, t))
            return throw_err(ctx, "game.gamepad(" + std::to_string(i) + ").setType: unknown pad type '" + name + "'. " + did_you_mean(name, gamepad_type_names()));
        in.on_gamepad_connected(i, true);  // a type only means something for a pad that is there
        in.set_gamepad_type(i, t);
    } else {
        in.on_gamepad_connected(i, kind == 3);
    }
    return JS_UNDEFINED;
}

NATIVE(testText) {  // (codePoint): one typed character, as the keyboard would send it
    SETUP;
    I->host->input().on_text(static_cast<std::uint32_t>(arg_num(ctx, argc, argv, 0)));
    return JS_UNDEFINED;
}

// ---- the date and the app's life ------------------------------------------------------------------------------------
NATIVE(today) {  // [year, month, day, weekday, utcOffsetMinutes]
    SETUP;
    const CalendarDate d = I->owner->today();
    return array_of(ctx, {double(d.year), double(d.month), double(d.day), double(d.weekday()), double(d.utcOffsetMinutes)});
}

NATIVE(testSetDate) {  // (iso): "" when set, else the teaching error
    SETUP;
    return JS_NewString(ctx, I->owner->set_date(arg_str(ctx, argc, argv, 0)).c_str());
}

NATIVE(appState) {  // [focused, suspended]
    SETUP;
    JSValue a = JS_NewArray(ctx);
    JS_SetPropertyUint32(ctx, a, 0, JS_NewBool(ctx, I->owner->app_focused()));
    JS_SetPropertyUint32(ctx, a, 1, JS_NewBool(ctx, I->owner->app_suspended()));
    return a;
}

NATIVE(testAppEvent) {  // (0 suspend, 1 resume, 2 focus, 3 blur)
    SETUP;
    const int kind = static_cast<int>(arg_num(ctx, argc, argv, 0, 0));
    static const ScriptSystem::AppLifecycle events[] = {ScriptSystem::AppLifecycle::Suspend, ScriptSystem::AppLifecycle::Resume,
                                                    ScriptSystem::AppLifecycle::Focus, ScriptSystem::AppLifecycle::Blur};
    if (kind >= 0 && kind < 4) I->owner->app_event(events[kind]);
    return JS_UNDEFINED;
}

NATIVE(preloadStart) {  // (kind 0 scene | 1 assets, path | [paths]) -> {id} | {mistake: {message, hint}}
    SETUP;
    const bool scene = arg_num(ctx, argc, argv, 0, 0) == 0;
    Result<int> r = scene ? I->preload.start_scene(arg_str(ctx, argc, argv, 1)) : [&] {
        std::vector<std::string> paths;
        Json list = argc > 1 ? I->to_json(argv[1]) : Json::array();
        if (list.is_array())
            for (const Json& p : list) paths.push_back(p.is_string() ? p.get<std::string>() : std::string());
        return I->preload.start_assets(paths);
    }();
    JSValue o = JS_NewObject(ctx);
    if (!r.ok()) {
        JS_SetPropertyStr(ctx, o, "mistake", I->from_json(Json::object({{"message", r.error().message}, {"hint", r.error().hint}})));
        return o;
    }
    JS_SetPropertyStr(ctx, o, "id", JS_NewInt32(ctx, r.value()));
    return o;
}

NATIVE(preloadRelease) {  // (id)
    SETUP;
    I->preload.release(static_cast<int>(arg_num(ctx, argc, argv, 0, 0)));
    return JS_UNDEFINED;
}

NATIVE(testDiskReads) {  // () -> files read from disk so far
    SETUP;
    return JS_NewFloat64(ctx, static_cast<double>(fs::disk_reads()));
}

NATIVE(testAppReset) {
    SETUP;
    I->owner->reset_app_state();
    return JS_UNDEFINED;
}

NATIVE(testStep) {
    SETUP;
    int n = static_cast<int>(arg_num(ctx, argc, argv, 0, 1));
    if (n < 0 || n > 1000000) return throw_err(ctx, "game.step(frames): frames must be between 0 and 1000000");
    I->host->step_frames(n);
    return JS_UNDEFINED;
}

NATIVE(testScreenshot) {
    SETUP;
    std::string err;
    if (!I->host->screenshot_simulated(arg_str(ctx, argc, argv, 0), arg_num(ctx, argc, argv, 1, 1.0), arg_str(ctx, argc, argv, 2), &err)) return JS_NewString(ctx, err.empty() ? "screenshot failed" : err.c_str());
    return JS_NewString(ctx, "");
}

NATIVE(testState) {
    SETUP;
    CommandResult r = I->host->commands().call("game.state", Json::object());
    if (r.ok) return I->from_json(r.result);
    Json j = Json::object();
    j["scene"] = W.scene_path();
    j["frame"] = W.frame();
    j["time"] = W.time();
    Json ents = Json::array();
    for (Entity e : W.entities())
        if (W.parent(e).is_null()) ents.push_back(entity_to_json(W, e));
    j["entities"] = std::move(ents);
    return I->from_json(j);
}

NATIVE(resetInput) {
    SETUP;
    Input& in = I->host->input();
    in.clear_action_overrides();
    in.release_all();  // also unplugs the gamepads
    double dz = 0.2;  // a test that changed input.deadzone starts the next one from the project's value
    Json ps = I->host->project_settings();
    if (ps.is_object() && ps.contains("input") && ps["input"].is_object()) {
        auto it = ps["input"].find("deadzone");
        if (it != ps["input"].end() && it->is_number()) dz = it->get<double>();
    }
    in.set_gamepad_deadzone(static_cast<float>(dz));
    W.set_safe_insets({});  // a test that pretended to be a notched phone starts the next one on a plain screen
    in.reset_options();  // a test that rebound an action, hid the cursor or showed the keyboard starts the next one clean
    return JS_UNDEFINED;
}

NATIVE(pumpJobs) {
    SETUP;
    I->run_jobs();
    return JS_UNDEFINED;
}

struct Reg {
    const char* name;
    JSCFunction* fn;
    int argc;
};

#define R(n, a) {#n, n_##n, a}
const Reg kRegs[] = {
    R(log, 2), R(reportError, 3), R(guardBegin, 2), R(guardEnd, 0), R(nowMs, 0), R(sourceCaret, 3), R(logSeq, 0), R(types, 0), R(timeInfo, 0),
    R(setTimeScale, 1), R(alive, 1), R(pendingDestroy, 1), R(idOf, 1), R(destroyedId, 1), R(find, 1), R(findAll, 1),
    R(findByTag, 1), R(entities, 0), R(tags, 1), R(setTags, 2), R(hasTag, 2), R(addTag, 2), R(removeTag, 2),
    R(setId, 2), R(getName, 1), R(setName, 2), R(getActive, 1), R(setActive, 2), R(activeInHierarchy, 1),
    R(destroy, 1), R(parent, 1), R(children, 1), R(setParent, 4), R(worldPos, 1), R(setWorldPos, 2),
    R(entityJson, 3), R(spawn, 3), R(spawnPrefab, 4), R(behaviour, 1), R(isGrounded, 2), R(hasComp, 2),
    R(compType, 1), R(addComp, 3), R(removeComp, 2), R(compNames, 1), R(compJson, 2), R(patchComp, 3), R(fget, 3),
    R(fgetn, 4), R(fsetn, 5), R(fset, 4), R(emit, 3), R(scenePath, 0), R(requestScene, 1), R(rngFloat, 0),
    R(rngRange, 2), R(rngInt, 2), R(rngChance, 1), R(rngSeed, 1), R(inAction, 2), R(inAxis, 2), R(inVector, 4),
    R(inKey, 2), R(inMouse, 0), R(inMouseButton, 2), R(inTouches, 0), R(inSetAction, 2), R(inClearOverrides, 0),
    R(inValue, 1), R(inPad, 3), R(inDeadzone, 1), R(testPad, 4),
    R(inText, 0), R(inActions, 0), R(inBindings, 1), R(inRebind, 2), R(inResetBindings, 1), R(inLastPressed, 0),
    R(inLastDevice, 0), R(inPadType, 1), R(inButtonName, 2), R(inCursor, 2), R(windowInfo, 0), R(windowSet, 3),
    R(testText, 1), R(inVibrate, 1), R(screenInsets, 0), R(testSafeInsets, 4), R(testSafeProfile, 1), R(testBack, 0), R(testVibrations, 0),
    R(inKeyEvent, 2), R(inMouseMove, 2), R(inMouseEvent, 2), R(inWheel, 1), R(audioPlay, 10), R(audioStop, 1),
    R(audioStopAll, 0), R(captionAdd, 4), R(captionClear, 0), R(captionList, 0), R(audioMusic, 3), R(audioStopMusic, 1), R(audioVolume, 2), R(audioGetVolume, 1), R(audioLog, 1), R(raycast2d, 7),
    R(raycast3d, 10), R(navFindPath, 1), R(navBake, 1), R(shapeCast2d, 8), R(shapeCast3d, 10), R(isTouching, 5), R(particlesBurst, 2), R(animCall, 4), R(measureText, 9), R(overflowed, 1), R(textScale, 0), R(setTextScale, 1), R(speak, 2), R(stopSpeaking, 0), R(speechAvailable, 0), R(spokenLog, 1), R(uiState, 0), R(uiFocus, 1), R(uiLayout, 0), R(textureSize, 1), R(bounds, 1), R(screenRect, 1), R(overlapCircle, 4), R(overlapBox, 5), R(overlapSphere, 5), R(physicsApply, 5), R(moveCharacter, 4),
    R(cameraMain, 0), R(worldToScreen, 3), R(screenToWorld, 3), R(debugDraw, 8), R(quit, 0), R(project, 0),
    R(screenSize, 0), R(notices, 0), R(platform, 0), R(accessibility, 0), R(testAccessibility, 4), R(deviceInfo, 0), R(testDevice, 1), R(renderScaleGet, 0), R(renderStatsNow, 0), R(renderScaleSet, 1), R(storageGet, 1), R(storageSet, 2), R(storageRemove, 1), R(storageKeys, 0),
    R(storageClear, 0), R(storageCorrupt, 0), R(testStorageText, 1), R(callCommand, 2), R(commands, 0), R(pluginList, 0), R(pluginCall, 3), R(platformStart, 2), R(platformInfo, 0), R(i18nInfo, 0), R(i18nT, 2), R(i18nHas, 1), R(i18nSet, 1), R(testLoad, 1), R(testLoadJson, 1), R(testTouch, 4), R(testStep, 1), R(today, 0), R(testSetDate, 1), R(appState, 0), R(testAppEvent, 1), R(testAppReset, 0), R(preloadStart, 2), R(preloadRelease, 1), R(testDiskReads, 0), R(testScreenshot, 3),
    R(testState, 0), R(pumpJobs, 0), R(resetInput, 0),
};
#undef R

}  // namespace

void Impl::install_natives(JSValue N) {
    for (const Reg& r : kRegs) JS_SetPropertyStr(ctx, N, r.name, JS_NewCFunction(ctx, r.fn, r.name, r.argc));
}

}  // namespace fa
