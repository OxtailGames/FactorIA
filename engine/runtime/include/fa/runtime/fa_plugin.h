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
 * A plugin can also be a platform backend (version 2): it answers the game's `platform` requests (achievements, stats,
 * leaderboards, cloud saves, purchases, overlay, presence, integrity tokens) with a store SDK. It registers one with add_backend and
 * answers each FaRequest with resolve() or reject(), now or later and from any thread; docs/PLATFORM.md lists the methods.
 *
 *   static void on_request(FaRequest* req, const char* method, const char* args, void* user) {
 *       if (strcmp(method, "achievements.unlock") == 0) {
 *           // ... call the store; when its callback fires, on any thread:
 *           g_api->resolve(req, "{\"unlocked\":true,\"newly\":true}");
 *       } else {
 *           g_api->reject(req, "unavailable", "this backend does not do that", NULL);
 *       }
 *   }
 *
 * A plugin can also show the platform's own keyboard (version 3): the Steam Deck's, say. It registers a handler with
 * add_text_input; the engine calls it when a TextField takes or loses the focus with a gamepad, and the handler says
 * whether the platform shows its keyboard (the game's own on-screen keyboard then stays closed). Text the platform
 * keyboard returns goes back with submit_text.
 *
 *   static int on_text_input(const FaTextInput* in, void* user) {
 *       if (!in->focused) { hide_keyboard(); return 0; }
 *       return show_keyboard(in->x, in->y, in->width, in->height, in->text, in->max_length);   // 1 = shown
 *   }
 *   // later, when the keyboard answers:  g_api->submit_text(g_api, "the player's text");
 *
 * Rules:
 *   - Register everything inside the entry point; the engine calls it once per process, before any game starts.
 *   - Handlers run on the game's thread. Answer each call once, before returning, with reply() or fail(); a handler
 *     that does neither returns null. Never let a C++ exception or a longjmp leave a handler.
 *   - Strings passed to the engine are copied: they may be temporaries.
 *   - The api pointer stays valid until the process ends: keep it for reply/fail/log.
 *   - The engine only grows this struct at its end and raises FA_PLUGIN_API_VERSION when it does; a plugin built
 *     against a newer header checks api->version before it uses a newer member (add_backend, resolve, reject and emit
 *     need version 2, add_text_input and submit_text version 3, set_device_fact version 4; a version 1 plugin keeps working unchanged).
 *   - Backends: answer each FaRequest exactly once; a second answer, or one for a game that has since ended, is
 *     ignored. resolve, reject and emit may be called from any thread. frame runs on the game thread.
 */
#ifndef FA_PLUGIN_H
#define FA_PLUGIN_H

#include <stdint.h>

#define FA_PLUGIN_API_VERSION 4

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
typedef struct FaRequest FaRequest; /* one platform request; answer it once with resolve() or reject(), now or later, any thread */

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

/* A platform backend (version 2): the plugin answers the game's `platform` requests with a store SDK. */
typedef struct FaBackendDesc {
    const char* name;     /* the backend's name: "steam", "apple"; the catalog's "ids" are keyed by it (required) */
    const char* services; /* JSON array of what it offers: "achievements","stats","leaderboards","cloudSave","purchases",
                           * "overlay","presence","integrity","ads" (required; leave out
                           * what it does not offer: the engine then answers "unavailable") */
    /* Starts one request: method is "achievements.unlock", "purchases.buy", ... and args_json its arguments, with the
     * store's own id for the entry in "storeId" (docs/PLATFORM.md lists every method). Answer req with resolve() or
     * reject() before or after returning, from any thread. Required. */
    void (*request)(FaRequest* req, const char* method, const char* args_json, void* user);
    /* Once per frame on the game thread, before scripts run (Steam: SteamAPI_RunCallbacks). May be NULL. */
    void (*frame)(void* user);
    void* user;
} FaBackendDesc;

/* A TextField the player focused or left with a gamepad (version 3). Its strings are valid during the call only. */
typedef struct FaTextInput {
    int focused;      /* 1: the field took the focus, or the player pressed the pad's submit button on it again (show the
                       * keyboard); 0: it lost the focus (hide the keyboard; the answer is ignored) */
    float x, y;       /* the field's rectangle in window pixels, from the top left of the window's drawing area */
    float width, height;
    const char* text; /* what the field holds now, UTF-8 */
    int multiline;    /* 1 when the field takes several lines (no TextField does yet: always 0) */
    int max_length;   /* the most characters (code points) the field takes; 0 = no limit */
    int password;     /* 1 when the typed text must be hidden (no TextField does yet: always 0) */
} FaTextInput;

/* Called on the game thread. Return 1 when the platform shows its own keyboard for this field, 0 when it does not (the
 * game's on-screen keyboard then opens, as without a plugin). */
typedef int (*FaTextInputHandler)(const FaTextInput* input, void* user);

struct FaPluginApi {
    uint32_t version;    /* FA_PLUGIN_API_VERSION of the engine running the plugin */
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

    /* Version 2: platform backends. Check api->version >= 2 before using these. */

    /* Register the plugin's platform backend (only inside the entry point; one per plugin). 0 = done; otherwise the
     * engine logged why (no name, services that are not JSON or not service names, no request handler, a second one). */
    int (*add_backend)(const FaPluginApi* api, const FaBackendDesc* desc);
    /* Answer a request: the result as JSON text. A result that is not JSON fails the request with the code "failed". */
    void (*resolve)(FaRequest* req, const char* result_json);
    /* Answer a request with an error. code: "unavailable", "notSignedIn", "notAllowed", "unknownId", "network" or
     * "failed" (anything else becomes "failed"); message says what went wrong and hint how to fix it (hint may be NULL). */
    void (*reject)(FaRequest* req, const char* code, const char* message, const char* hint);
    /* Tell the game something happened without being asked: event "purchase" {status, productId, transactionId,
     * receipt}, "overlay" {open} or "player" {id, name, signedIn}; scripts get it through platform.on(event, fn). */
    void (*emit)(const FaPluginApi* api, const char* event, const char* data_json);

    /* Version 3: the platform's own keyboard. Check api->version >= 3 before using these. */

    /* Register the plugin's text input handler (only inside the entry point; one per plugin). 0 = done; otherwise the
     * engine logged why (no handler, a second one). */
    int (*add_text_input)(const FaPluginApi* api, FaTextInputHandler handler, void* user);
    /* Hand text typed on the platform keyboard to the TextField that took it (the handler answered 1 for it and it still
     * has the focus). May be called from any thread: the engine applies it on the game thread at the next frame,
     * replacing the field's text (cut to its maxLength) and sending ui.change. Text for a field that no longer has the
     * focus is dropped. */
    void (*submit_text)(const FaPluginApi* api, const char* text_utf8);

    /* Version 4: facts about the device. Check api->version >= 4 before using this. */

    /* Tell the engine a fact about the device the game runs on, once the plugin knows it (inside the entry point or later,
     * on the game thread). name "steamDeck": value 1 when the platform says this is a Steam Deck, 0 when it says it is not
     * (game.device.steamDeck, and game.device.handheld with it). An unknown name is ignored with a warning in the log. A
     * plugin that does not know (its SDK did not start) must not call it: the engine then falls back to the SteamDeck=1
     * environment variable. */
    void (*set_device_fact)(const FaPluginApi* api, const char* name, int value);
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
