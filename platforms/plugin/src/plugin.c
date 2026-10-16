/* A FactorIA native plugin (docs/EXTENDING.md, "Native plugins"): the script function plugins.<name>.add(a, b) and the
 * command <name>.info. include/fa_plugin.h is the whole API. CMakeLists.txt passes the plugin's name as FA_PLUGIN_NAME
 * and copies the build where the game finds it. */
#include <stdio.h>

#include "fa_plugin.h"

static const FaPluginApi* g_api;

/* add(a, b): args_json is the call's arguments as a JSON array, e.g. "[1,2]"; the reply is JSON text. */
static void add(FaCall* call, const char* args_json, void* user) {
    double a = 0, b = 0;
    char out[128];
    (void)user;
    if (sscanf(args_json, " [ %lf , %lf ]", &a, &b) != 2) {
        snprintf(out, sizeof out, "plugins.%s.add(1, 2)", g_api->plugin);
        g_api->fail(call, "add(a, b) takes two numbers", out);
        return;
    }
    snprintf(out, sizeof out, "%.17g", a + b);
    g_api->reply(call, out);
}

/* <name>.info: args_json is the command's arguments as a JSON object (checked against its input_schema). */
static void info(FaCall* call, const char* args_json, void* user) {
    char out[256];
    (void)args_json;
    (void)user;
    snprintf(out, sizeof out, "{\"plugin\":\"%s\",\"platform\":\"%s\",\"apiVersion\":%u}", g_api->plugin, g_api->platform,
             (unsigned)g_api->version);
    g_api->reply(call, out);
}

FA_PLUGIN_INIT(FA_PLUGIN_NAME) {
    char name[96];
    FaFunctionDesc fn = {"add", "add(a, b): the sum of two numbers, computed by the native plugin.", add, NULL};
    FaCommandDesc cmd = {name, "Describe this native plugin.", "Returns {plugin, platform, apiVersion}. Example: {}.", NULL, 1, info,
                         NULL};
    g_api = api;
    snprintf(name, sizeof name, "%s.info", api->plugin); /* a plugin's commands are named <plugin>.<verb> */
    if (api->add_function(api, &fn) != 0 || api->add_command(api, &cmd) != 0) return 1;
    api->log(api, 1, "ready");
    return 0;
}
