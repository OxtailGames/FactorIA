// Fixes for bugs in the bundled QuickJS-ng (external/ stays untouched): each one replaces a built-in at context creation.
#include "script_internal.h"

namespace fa {
namespace {

enum FindMode { kFind, kFindIndex, kFindLast, kFindLastIndex };

// Array.prototype.find, findIndex, findLast and findLastIndex. QuickJS-ng's own (js_array_find, v0.17.0 and master)
// polls for an interrupt at the top of each step and on failure frees the previous step's element a second time, so the
// watchdog stopping a script inside find() over objects left one of them a reference short: a use after free, or the
// GC aborting in gc_decref_child later. This is the same algorithm without that poll; the JS_Call of each step polls.
JSValue array_find(JSContext* ctx, JSValueConst thisVal, int argc, JSValueConst* argv, int mode) {
    JSValue obj = JS_ToObject(ctx, thisVal);
    if (JS_IsException(obj)) return obj;
    int64_t len = 0;
    if (JS_GetLength(ctx, obj, &len) < 0) {
        JS_FreeValue(ctx, obj);
        return JS_EXCEPTION;
    }
    JSValueConst fn = argc > 0 ? argv[0] : JS_UNDEFINED;
    if (!JS_IsFunction(ctx, fn)) {
        JS_FreeValue(ctx, obj);
        return JS_ThrowTypeError(ctx, "not a function");
    }
    JSValueConst thisArg = argc > 1 ? argv[1] : JS_UNDEFINED;
    const bool last = mode == kFindLast || mode == kFindLastIndex;
    const bool index = mode == kFindIndex || mode == kFindLastIndex;
    for (int64_t i = 0; i < len; ++i) {
        const int64_t k = last ? len - 1 - i : i;
        JSValue val = JS_GetPropertyInt64(ctx, obj, k);
        if (JS_IsException(val)) {
            JS_FreeValue(ctx, obj);
            return JS_EXCEPTION;
        }
        JSValue key = JS_NewInt64(ctx, k);
        JSValueConst args[3] = {val, key, thisVal};
        JSValue res = JS_Call(ctx, fn, thisArg, 3, args);
        if (JS_IsException(res)) {
            JS_FreeValue(ctx, val);
            JS_FreeValue(ctx, obj);
            return JS_EXCEPTION;
        }
        const bool found = JS_ToBool(ctx, res) > 0;
        JS_FreeValue(ctx, res);
        if (found) {
            JS_FreeValue(ctx, obj);
            if (!index) return val;
            JS_FreeValue(ctx, val);
            return key;
        }
        JS_FreeValue(ctx, val);
    }
    JS_FreeValue(ctx, obj);
    return index ? JS_NewInt32(ctx, -1) : JS_UNDEFINED;
}

}  // namespace

void install_quickjs_fixes(JSContext* ctx) {
    JSValue global = JS_GetGlobalObject(ctx);
    JSValue array = JS_GetPropertyStr(ctx, global, "Array");
    JSValue proto = JS_GetPropertyStr(ctx, array, "prototype");
    struct {
        const char* name;
        FindMode mode;
    } const finds[] = {{"find", kFind}, {"findIndex", kFindIndex}, {"findLast", kFindLast}, {"findLastIndex", kFindLastIndex}};
    for (const auto& f : finds) {
        JSValue fn = JS_NewCFunctionMagic(ctx, array_find, f.name, 1, JS_CFUNC_generic_magic, f.mode);
        JS_DefinePropertyValueStr(ctx, proto, f.name, fn, JS_PROP_WRITABLE | JS_PROP_CONFIGURABLE);
    }
    JS_FreeValue(ctx, proto);
    JS_FreeValue(ctx, array);
    JS_FreeValue(ctx, global);
}

}  // namespace fa
