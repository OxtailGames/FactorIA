/* fa_plugin.h: the C ABI of FactorIA native plugins (docs/EXTENDING.md, "Native plugins").
 *
 * A native plugin is a library a game declares in factoria.json ("plugins") that adds commands (MCP tools, `factoria
 * call`, fa.call) and script functions (plugins.<plugin>.<function>(...args)) written in C, C++, or anything that can
 * export a C function: store SDKs, platform services, code a game cannot write in JavaScript. This file is the whole
 * interface: plain C, no engine headers, no engine library to link. `project.new_plugin` copies it into a new plugin.
 *
 *   #include "fa_plugin.h"
 *   static const FaPluginApi* g_api;
 *   static void add(FaCall* call, const char* args, void* user) {   // args: "[1,2]"
 *       double a = 0, b = 0;
 *       sscanf(args, " [ %lf , %lf", &a, &b);
 *       char out[64];
 *       snprintf(out, sizeof out, "%.17g", a + b);
 *       g_api->reply(call, out);                                     // the result, as JSON text
 *   }
 *   FA_PLUGIN_INIT(example) {                                        // the entry point
 *       g_api = api;
 *       FaFunctionDesc f = {"add", "add(a, b): the sum of two numbers.", add, NULL};
 *       return api->add_function(api, &f);
 *   }
 *
 * Rules:
 *   - Register everything inside the entry point; the engine calls it once per process, before any game starts.
 *   - Handlers run on the game's thread. Answer each call once, before returning, with reply() or fail(); a handler
 *     that does neither returns null. Never let a C++ exception or a longjmp leave a handler.
 *   - Strings passed to the engine are copied: they may be temporaries.
 *   - The api pointer stays valid until the process ends: keep it for reply/fail/log.
 *   - The engine only grows this struct at its end and raises FA_PLUGIN_API_VERSION when it does; a plugin built
 *     against a newer header checks api->version before it uses a newer member.
 */
#ifndef FA_PLUGIN_H
#define FA_PLUGIN_H

#include <stdint.h>

#define FA_PLUGIN_API_VERSION 1

#if defined(_WIN32)
#define FA_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FA_PLUGIN_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct FaPluginApi FaPluginApi;
typedef struct FaCall FaCall; /* one call of a command or function; answer it with api->reply or api->fail */

/* Runs a command or a script function. args_json: UTF-8 JSON text, an object for a command (already checked against
 * its input_schema, defaults filled in), an array of the arguments for a function. `user` is the desc's user. */
typedef void (*FaHandler)(FaCall* call, const char* args_json, void* user);

typedef struct FaCommandDesc {
    const char* name;         /* "<plugin>.<verb>" in snake_case, e.g. "example.info" (required) */
    const char* summary;      /* one imperative line (required): what MCP clients and `factoria commands` show */
    const char* description;  /* details, caveats and an example call (may be NULL) */
    const char* input_schema; /* JSON Schema of the arguments as text; NULL = an object with no properties */
    int read_only;            /* 1 when the command changes nothing */
    FaHandler handler;
    void* user;
} FaCommandDesc;

typedef struct FaFunctionDesc {
    const char* name;  /* a JavaScript identifier: scripts call plugins.<plugin>.<name>(...args) */
    const char* doc;   /* what it does, its arguments and its result (required): it goes into types/factoria.d.ts */
    FaHandler handler;
    void* user;
} FaFunctionDesc;

struct FaPluginApi {
    uint32_t version;     /* FA_PLUGIN_API_VERSION of the engine running the plugin */
    const char* plugin;   /* the plugin's name in factoria.json */
    const char* platform; /* "windows", "macos", "linux", "android" or "ios" */
    void* host;           /* the engine's: never touch it */

    /* Register a command or a function (only inside the entry point). 0 = done; otherwise the engine logged why
     * (a bad name, a missing doc string, a duplicate, an input_schema that is not JSON). */
    int (*add_command)(const FaPluginApi* api, const FaCommandDesc* desc);
    int (*add_function)(const FaPluginApi* api, const FaFunctionDesc* desc);

    /* Answer a call: the result as JSON text ("3", "{\"ok\":true}", "\"text\""), or an error that teaches: what went
     * wrong and how to fix it (hint may be NULL). Scripts get the error as an exception, commands as a failed result. */
    void (*reply)(FaCall* call, const char* result_json);
    void (*fail)(FaCall* call, const char* message, const char* hint);

    /* A line in the game's log under the plugin's name. level: 0 debug, 1 info, 2 warning, 3 error. */
    void (*log)(const FaPluginApi* api, int level, const char* message);

    /* Platform objects an SDK needs, by name; NULL when this platform has none:
     *   "android.activity"  the game's ANativeActivity* (->vm for JNI, ->clazz for the activity object and its
     *                       class loader, which finds the plugin's own Java classes) */
    void* (*native_handle)(const char* name);
};

typedef int (*FaPluginInitFn)(const FaPluginApi* api);

/* The entry point: FA_PLUGIN_INIT(<plugin name>) { ...; return 0; }. Return 0 when the plugin is ready; anything else
 * means it failed to start (log why first): the game then runs without it, and scripts that use it get that error.
 * A shared library (Windows, macOS, Linux, Android) exports fa_plugin_init. A static library (iOS) is linked into the
 * app next to other plugins, so its entry point carries the plugin's name: build it with -DFA_PLUGIN_STATIC. */
#ifdef __cplusplus
}
#define FA_PLUGIN_EXTERN_C extern "C"
#else
#define FA_PLUGIN_EXTERN_C
#endif
#if defined(FA_PLUGIN_STATIC)
#define FA_PLUGIN_INIT_(name) FA_PLUGIN_EXTERN_C int fa_plugin_init_##name(const FaPluginApi* api)
#else
#define FA_PLUGIN_INIT_(name) FA_PLUGIN_EXTERN_C FA_PLUGIN_EXPORT int fa_plugin_init(const FaPluginApi* api)
#endif
#define FA_PLUGIN_INIT(name) FA_PLUGIN_INIT_(name) /* indirection: `name` may be a macro */

#endif /* FA_PLUGIN_H */
