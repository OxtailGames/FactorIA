// Compiled scripts (QuickJS bytecode) for game packs: fa/script/bytecode.h. The loader side is in script_system.cpp.
#include "fa/script/bytecode.h"

#include <cstdio>
#include <cstring>

#include "quickjs.h"

namespace fa {
namespace {

constexpr char kMagic[7] = {'F', 'A', 'Q', 'J', 'S', 'B', 'C'};
constexpr std::uint8_t kFormat = 1;
constexpr std::size_t kPrefix = 8;  // magic + format version

std::string js_text(JSContext* ctx, JSValueConst v) {
    const char* s = JS_ToCString(ctx, v);
    std::string out = s ? s : "";
    if (s) JS_FreeCString(ctx, s);
    return out;
}

std::string property(JSContext* ctx, JSValueConst obj, const char* name) {
    JSValue v = JS_GetPropertyStr(ctx, obj, name);
    std::string out = JS_IsUndefined(v) ? std::string() : js_text(ctx, v);
    JS_FreeValue(ctx, v);
    return out;
}

// Compiling a module makes QuickJS resolve its imports, which asks the loader for each one ("factoria", "./lib.js",
// "./data.json"). Nothing runs here, so an empty module per name is all the compiler needs; the real modules are found
// by the game's own loader when the compiled script is read (script_system.cpp).
JSModuleDef* stub_module_loader(JSContext* ctx, const char* name, void*) {
    return JS_NewCModule(ctx, name, [](JSContext*, JSModuleDef*) { return 0; });
}

}  // namespace

bool is_script_bytecode(std::string_view data) { return data.size() >= kPrefix && std::memcmp(data.data(), kMagic, sizeof kMagic) == 0; }

std::string script_bytecode_tag() { return std::string("FactorIA ") + FA_ENGINE_VERSION + "; QuickJS " + JS_GetVersion(); }

Result<std::vector<std::uint8_t>> compile_script_bytecode(std::string_view source, std::string_view moduleName) {
    JSRuntime* rt = JS_NewRuntime();
    if (!rt) return make_error("Cannot compile '" + std::string(moduleName) + "': the JavaScript runtime did not start");
    JS_SetMaxStackSize(rt, size_t(2) * 1024 * 1024);  // the game's runtime has the same, so nothing compiles here that cannot there
    JS_SetModuleLoaderFunc(rt, nullptr, stub_module_loader, nullptr);
    JSContext* ctx = JS_NewContext(rt);
    auto done = [&](Result<std::vector<std::uint8_t>> r) {
        if (ctx) JS_FreeContext(ctx);
        JS_FreeRuntime(rt);
        return r;
    };
    if (!ctx) return done(make_error("Cannot compile '" + std::string(moduleName) + "': the JavaScript context did not start"));

    const std::string name(moduleName), text(source);  // JS_Eval wants a zero-terminated buffer
    JSValue module = JS_Eval(ctx, text.c_str(), text.size(), name.c_str(), JS_EVAL_TYPE_MODULE | JS_EVAL_FLAG_COMPILE_ONLY);
    if (JS_IsException(module)) {
        JSValue exc = JS_GetException(ctx);
        std::string kind = property(ctx, exc, "name"), message = property(ctx, exc, "message"), stack = property(ctx, exc, "stack");
        JS_FreeValue(ctx, exc);
        // The stack of a syntax error ends with "at <name>:line:column".
        int line = 0, column = 0;
        if (const std::size_t at = stack.find(name + ":"); at != std::string::npos)
            std::sscanf(stack.c_str() + at + name.size() + 1, "%d:%d", &line, &column);
        std::string where = name;
        if (line > 0) where += ":" + std::to_string(line) + (column > 0 ? ":" + std::to_string(column) : "");
        return done(make_error(where + ": " + (kind.empty() ? "SyntaxError" : kind) + ": " + message,
                               "Fix the syntax error at that position; modules use ES2023 syntax (import/export, classes, async). "
                               "`factoria validate` checks every script."));
    }
    size_t size = 0;
    // Source text out, debug information (file name and line numbers) in: errors in the shipped game still say where.
    uint8_t* bytes = JS_WriteObject(ctx, &size, module, JS_WRITE_OBJ_BYTECODE | JS_WRITE_OBJ_STRIP_SOURCE);
    JS_FreeValue(ctx, module);
    if (!bytes) {
        JSValue exc = JS_GetException(ctx);
        std::string why = js_text(ctx, exc);
        JS_FreeValue(ctx, exc);
        return done(make_error("Cannot compile '" + name + "' to bytecode: " + why));
    }
    const std::string tag = script_bytecode_tag();
    std::vector<std::uint8_t> out(kMagic, kMagic + sizeof kMagic);
    out.push_back(kFormat);
    out.push_back(std::uint8_t(tag.size() & 0xff));
    out.push_back(std::uint8_t(tag.size() >> 8));
    out.insert(out.end(), tag.begin(), tag.end());
    out.insert(out.end(), bytes, bytes + size);
    js_free(ctx, bytes);
    return done(std::move(out));
}

Result<std::string_view> script_bytecode_payload(std::string_view data, std::string_view file) {
    const std::string name(file);
    const std::string again = "Export the game again with this FactorIA version (`factoria export --release`); "
                              "export.scriptBytecode: false in factoria.json ships the scripts as plain source instead.";
    if (!is_script_bytecode(data)) return make_error("'" + name + "' is not a compiled script", again);
    if (static_cast<std::uint8_t>(data[7]) != kFormat)
        return make_error("'" + name + "' is a compiled script of format " + std::to_string(static_cast<std::uint8_t>(data[7])) +
                              ", which this FactorIA does not read (it reads format " + std::to_string(kFormat) + ")",
                          again);
    if (data.size() < kPrefix + 2) return make_error("'" + name + "' is a compiled script that was cut short", again);
    const std::size_t tagSize = static_cast<std::uint8_t>(data[8]) | (std::size_t(static_cast<std::uint8_t>(data[9])) << 8);
    if (data.size() < kPrefix + 2 + tagSize) return make_error("'" + name + "' is a compiled script that was cut short", again);
    const std::string_view tag = data.substr(kPrefix + 2, tagSize);
    if (tag != script_bytecode_tag())
        return make_error("'" + name + "' was compiled by " + std::string(tag) + ", but this game runs " + script_bytecode_tag() +
                              ", and compiled scripts only run on the version that wrote them",
                          again);
    return data.substr(kPrefix + 2 + tagSize);
}

}  // namespace fa
