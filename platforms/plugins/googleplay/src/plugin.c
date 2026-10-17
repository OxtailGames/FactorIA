/* The {{NAME}} plugin: the Google Play backend of the game's `platform` API (docs/PLATFORM.md, "Google Play").
 *
 * This file is only the bridge. The work (Google Play Billing, Play Games Services, Play Integrity) is Java, in
 * android/src/main/java/factoria/plugin/<name>/, because those SDKs have no C API. What it does:
 *   - loads the Java class factoria.plugin.<name>.Backend through the activity's class loader (FindClass on a native thread
 *     only sees the system's classes), registers the four callbacks Java answers through (resolve, reject, emit, log) and
 *     calls Backend.init, which returns the JSON list of the services this device offers;
 *   - registers the backend with the engine: every `platform` request becomes a call of Backend.request(token, method, args);
 *   - registers the command <name>.status.
 * include/fa_plugin.h is the engine's plugin API. CMakeLists.txt passes the plugin's name as FA_PLUGIN_NAME. */
#if !defined(__ANDROID__)
#error "The Google Play plugin is built for Android only, with the NDK: see CMakeLists.txt."
#endif

#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <android/native_activity.h>
#include <jni.h>

#include "fa_plugin.h"

#define BACKEND_NAME "googleplay" /* the key of the catalog's "ids": ids.googleplay */

static const FaPluginApi* g_api;
static JavaVM* g_vm;
static jclass g_backend;  /* global reference to factoria.plugin.<name>.Backend */
static jmethodID g_request; /* static void request(long token, String method, String argsJson): never throws */
static jmethodID g_status;  /* static String status() */

static void say(int level, const char* format, ...) {
    char text[1536];
    va_list args;
    va_start(args, format);
    vsnprintf(text, sizeof text, format, args);
    va_end(args);
    g_api->log(g_api, level, text);
}

/* ---- strings: Java's UTF-16 <-> the engine's UTF-8 ----------------------------------------------------------------------
 * JNI's own conversions use "modified UTF-8" (an emoji becomes two 3-byte surrogates, which the engine's JSON parser rejects),
 * and CheckJNI aborts the app when NewStringUTF gets a 4-byte sequence. So both directions are converted here. */

/* UTF-8 text of a Java string, to free() ; NULL for null. */
static char* utf8_from_jstring(JNIEnv* env, jstring s) {
    jsize n, i;
    size_t k = 0;
    const jchar* u;
    char* out;
    if (!s) return NULL;
    n = (*env)->GetStringLength(env, s);
    u = (*env)->GetStringChars(env, s, NULL);
    if (!u) return NULL;
    out = (char*)malloc((size_t)n * 3 + 1); /* a UTF-16 unit is at most 3 bytes; a surrogate pair is 4 bytes for 2 units */
    if (out) {
        for (i = 0; i < n; ++i) {
            unsigned c = u[i];
            if (c >= 0xD800 && c <= 0xDBFF && i + 1 < n && u[i + 1] >= 0xDC00 && u[i + 1] <= 0xDFFF) {
                c = 0x10000 + ((c - 0xD800) << 10) + (u[i + 1] - 0xDC00);
                ++i;
            } else if (c >= 0xD800 && c <= 0xDFFF) {
                c = 0xFFFD; /* a lone surrogate */
            }
            if (c < 0x80) {
                out[k++] = (char)c;
            } else if (c < 0x800) {
                out[k++] = (char)(0xC0 | (c >> 6));
                out[k++] = (char)(0x80 | (c & 0x3F));
            } else if (c < 0x10000) {
                out[k++] = (char)(0xE0 | (c >> 12));
                out[k++] = (char)(0x80 | ((c >> 6) & 0x3F));
                out[k++] = (char)(0x80 | (c & 0x3F));
            } else {
                out[k++] = (char)(0xF0 | (c >> 18));
                out[k++] = (char)(0x80 | ((c >> 12) & 0x3F));
                out[k++] = (char)(0x80 | ((c >> 6) & 0x3F));
                out[k++] = (char)(0x80 | (c & 0x3F));
            }
        }
        out[k] = 0;
    }
    (*env)->ReleaseStringChars(env, s, u);
    return out;
}

/* A Java string from UTF-8 text (an invalid byte becomes U+FFFD). NULL when out of memory. */
static jstring jstring_from_utf8(JNIEnv* env, const char* s) {
    size_t len = strlen(s), i = 0, k = 0;
    jchar* units = (jchar*)malloc((len + 1) * sizeof(jchar)); /* a UTF-8 sequence never gives more units than it has bytes */
    jstring result;
    if (!units) return NULL;
    while (i < len) {
        unsigned char b = (unsigned char)s[i];
        unsigned c = 0xFFFD;
        size_t need = b < 0x80 ? 0 : (b >> 5) == 0x6 ? 1 : (b >> 4) == 0xE ? 2 : (b >> 3) == 0x1E ? 3 : 0;
        if (b < 0x80) {
            c = b;
        } else if (need && i + need < len) { /* the continuation bytes are all there */
            size_t j;
            unsigned v = need == 1 ? (b & 0x1Fu) : need == 2 ? (b & 0x0Fu) : (b & 0x07u);
            int ok = 1;
            for (j = 1; j <= need && ok; ++j) {
                unsigned char cb = (unsigned char)s[i + j];
                if ((cb & 0xC0) != 0x80) ok = 0;
                else v = (v << 6) | (cb & 0x3Fu);
            }
            if (ok && v <= 0x10FFFF) {
                c = v;
                i += need;
            }
        }
        ++i;
        if (c >= 0x10000) {
            c -= 0x10000;
            units[k++] = (jchar)(0xD800 + (c >> 10));
            units[k++] = (jchar)(0xDC00 + (c & 0x3FF));
        } else {
            units[k++] = (jchar)c;
        }
    }
    result = (*env)->NewString(env, units, (jsize)k);
    free(units);
    return result;
}

/* ---- the callbacks Java answers through (registered with RegisterNatives; any Java thread) -------------------------------- */

static void native_resolve(JNIEnv* env, jclass cls, jlong token, jstring json) {
    char* text = utf8_from_jstring(env, json);
    (void)cls;
    g_api->resolve((FaRequest*)(intptr_t)token, text ? text : "null");
    free(text);
}

static void native_reject(JNIEnv* env, jclass cls, jlong token, jstring code, jstring message, jstring hint) {
    char* c = utf8_from_jstring(env, code);
    char* m = utf8_from_jstring(env, message);
    char* h = utf8_from_jstring(env, hint);
    (void)cls;
    g_api->reject((FaRequest*)(intptr_t)token, c ? c : "failed", m ? m : "the request failed", h);
    free(c);
    free(m);
    free(h);
}

static void native_emit(JNIEnv* env, jclass cls, jstring event, jstring json) {
    char* e = utf8_from_jstring(env, event);
    char* d = utf8_from_jstring(env, json);
    (void)cls;
    if (e) g_api->emit(g_api, e, d ? d : "{}");
    free(e);
    free(d);
}

static void native_log(JNIEnv* env, jclass cls, jint level, jstring message) {
    char* m = utf8_from_jstring(env, message);
    (void)cls;
    if (m) g_api->log(g_api, (int)level, m);
    free(m);
}

/* ---- calling Java from the game's thread ------------------------------------------------------------------------------- */

typedef struct JavaScope {
    JNIEnv* env;
    int attached; /* this scope attached the thread, so it detaches it */
    int framed;
} JavaScope;

/* The game's thread is not a Java thread: attach it for the call (and detach after), with a local reference frame so that no
 * reference outlives the call. Returns 0 when the thread cannot be attached. */
static int java_enter(JavaScope* scope) {
    jint state;
    scope->env = NULL;
    scope->attached = 0;
    scope->framed = 0;
    if (!g_vm) return 0;
    state = (*g_vm)->GetEnv(g_vm, (void**)&scope->env, JNI_VERSION_1_6);
    if (state == JNI_EDETACHED) {
        if ((*g_vm)->AttachCurrentThread(g_vm, &scope->env, NULL) != JNI_OK) return 0;
        scope->attached = 1;
    } else if (state != JNI_OK) {
        return 0;
    }
    if ((*scope->env)->PushLocalFrame(scope->env, 32) != 0) {
        (*scope->env)->ExceptionClear(scope->env);
    } else {
        scope->framed = 1;
    }
    return 1;
}

static void java_leave(JavaScope* scope) {
    if (scope->framed) (*scope->env)->PopLocalFrame(scope->env, NULL);
    if (scope->attached) (*g_vm)->DetachCurrentThread(g_vm);
}

/* Describes a pending Java exception in the log and clears it. Returns 1 when there was one. */
static int java_exception(JNIEnv* env) {
    if (!(*env)->ExceptionCheck(env)) return 0;
    (*env)->ExceptionDescribe(env); /* logs the exception and clears it */
    (*env)->ExceptionClear(env);
    return 1;
}

/* The class `name` ("factoria.plugin.googleplay.Backend") from the activity's class loader, as a local reference. */
static jclass load_class(JNIEnv* env, jobject activity, const char* name) {
    jclass activity_class = (*env)->GetObjectClass(env, activity);
    jmethodID get_loader = (*env)->GetMethodID(env, activity_class, "getClassLoader", "()Ljava/lang/ClassLoader;");
    jobject loader = get_loader ? (*env)->CallObjectMethod(env, activity, get_loader) : NULL;
    jmethodID load = NULL;
    jstring java_name;
    jclass cls = NULL;
    if (java_exception(env) || !loader) return NULL;
    load = (*env)->GetMethodID(env, (*env)->GetObjectClass(env, loader), "loadClass", "(Ljava/lang/String;)Ljava/lang/Class;");
    java_name = load ? (*env)->NewStringUTF(env, name) : NULL; /* a class name is ASCII */
    if (java_name) cls = (jclass)(*env)->CallObjectMethod(env, loader, load, java_name);
    if (java_exception(env)) return NULL;
    return cls;
}

/* ---- the engine's side ------------------------------------------------------------------------------------------------ */

/* Every request of the game, on its thread. Java answers each exactly once (Backend.request never throws and every answer
 * goes through one flag per request); only when the call itself cannot be made does this answer, and then Java has not. */
static void on_request(FaRequest* req, const char* method, const char* args_json, void* user) {
    JavaScope scope;
    jstring java_method = NULL, java_args = NULL;
    const char* problem = "attach the game's thread to the Java VM";
    (void)user;
    if (java_enter(&scope)) {
        JNIEnv* env = scope.env;
        problem = "make the call (out of memory?)";
        java_method = (*env)->NewStringUTF(env, method);
        java_args = jstring_from_utf8(env, args_json ? args_json : "{}");
        if (java_method && java_args) {
            (*env)->CallStaticVoidMethod(env, g_backend, g_request, (jlong)(intptr_t)req, java_method, java_args);
            problem = java_exception(env) ? "run Backend.request, which threw an exception (it is in the log)" : NULL;
        }
        java_leave(&scope);
    }
    if (problem) {
        char message[320];
        snprintf(message, sizeof message, "%s could not be sent to the Google Play code: failed to %s", method, problem);
        g_api->reject(req, "failed", message,
                      "Export the game again (factoria export --platform android) so that the app has the plugin's android/ Gradle module, "
                      "and read the log for the Java exception (docs/PLATFORM.md, section Google Play).");
    }
}

/* <name>.status: Backend.status() returns the JSON text. */
static void on_status(FaCall* call, const char* args_json, void* user) {
    JavaScope scope;
    char* json = NULL;
    (void)args_json;
    (void)user;
    if (java_enter(&scope)) {
        JNIEnv* env = scope.env;
        jstring text = (jstring)(*env)->CallStaticObjectMethod(env, g_backend, g_status);
        if (!java_exception(env) && text) json = utf8_from_jstring(env, text);
        java_leave(&scope);
    }
    if (json) {
        g_api->reply(call, json);
    } else {
        g_api->fail(call, "the Google Play code did not answer status()",
                    "The plugin's Java module is not in the app, or it threw (see the log). Export the game again: factoria export --platform android.");
    }
    free(json);
}

FA_PLUGIN_INIT(FA_PLUGIN_NAME) {
    static const JNINativeMethod natives[] = {
        {"resolve", "(JLjava/lang/String;)V", (void*)native_resolve},
        {"reject", "(JLjava/lang/String;Ljava/lang/String;Ljava/lang/String;)V", (void*)native_reject},
        {"emit", "(Ljava/lang/String;Ljava/lang/String;)V", (void*)native_emit},
        {"log", "(ILjava/lang/String;)V", (void*)native_log},
    };
    const ANativeActivity* activity;
    JavaScope scope;
    char class_name[160], services[256];
    const char* problem = NULL;
    const char* fix = "";

    g_api = api;
    if (api->version < 2 || !api->add_backend || !api->resolve || !api->reject || !api->emit) {
        say(3, "the Google Play plugin needs plugin API version 2 (the engine runs version %u): build the game with a FactorIA that has "
               "the platform API (docs/PLATFORM.md)", (unsigned)api->version);
        return 1;
    }
    activity = (const ANativeActivity*)api->native_handle("android.activity");
    if (!activity || !activity->vm || !activity->clazz) {
        say(3, "the Google Play plugin runs on Android only and needs the game's activity; the engine gave it none");
        return 1;
    }
    g_vm = activity->vm;
    snprintf(class_name, sizeof class_name, "factoria.plugin.%s.Backend", api->plugin);
    services[0] = 0;

    if (!java_enter(&scope)) {
        say(3, "the Google Play plugin could not attach the game's thread to the Java VM");
        return 1;
    }
    {
        JNIEnv* env = scope.env;
        jclass cls = load_class(env, activity->clazz, class_name);
        jmethodID init;
        if (!cls) {
            problem = "find the Java class in the app";
            fix = "The plugin's android/ folder is a Gradle module that `factoria export --platform android` adds to the app: export the "
                  "game again, with the plugin declared for \"android\" in factoria.json (platform.add_backend does that).";
        } else if ((*env)->RegisterNatives(env, cls, natives, (jint)(sizeof natives / sizeof natives[0])) != 0) {
            java_exception(env);
            problem = "register the native callbacks of the Java class";
            fix = "The Java class and this library are from different versions of the plugin: build both from the same plugin folder "
                  "(platform.add_backend writes and builds them together), then export again.";
        } else {
            g_backend =(jclass)(*env)->NewGlobalRef(env, cls);
            g_request = (*env)->GetStaticMethodID(env, cls, "request", "(JLjava/lang/String;Ljava/lang/String;)V");
            g_status = (*env)->GetStaticMethodID(env, cls, "status", "()Ljava/lang/String;");
            init = (*env)->GetStaticMethodID(env, cls, "init", "(Landroid/app/Activity;Ljava/lang/String;)Ljava/lang/String;");
            if (java_exception(env) || !g_backend || !g_request || !g_status || !init) {
                problem = "find request(), status() and init() in the Java class";
                fix = "The Java class and this library are from different versions of the plugin: build both from the same plugin folder, "
                      "then export again.";
            } else {
                jstring plugin = (*env)->NewStringUTF(env, api->plugin);
                jstring list = (jstring)(*env)->CallStaticObjectMethod(env, g_backend, init, activity->clazz, plugin);
                char* text = java_exception(env) ? NULL : utf8_from_jstring(env, list);
                if (!text) {
                    problem = "run Backend.init, which threw an exception (it is in the log)";
                    fix = "Read the exception above. The usual causes are a missing dependency (an AndroidX or Play library the Gradle module "
                          "declares) or a class the app's minification removed (consumer-rules.pro keeps factoria.plugin.**).";
                } else {
                    snprintf(services, sizeof services, "%s", text);
                    free(text);
                }
            }
        }
    }
    java_leave(&scope);

    if (problem) {
        say(3, "the Google Play plugin cannot start: failed to %s (%s). %s The game runs without it.", problem, class_name, fix);
        return 1;
    }
    {
        FaBackendDesc backend = {BACKEND_NAME, services, on_request, NULL, NULL};
        char name[96];
        FaCommandDesc status = {name,
                                "Show what works on this device for Google Play (Billing, Play Games, Play Integrity) and what to fix.",
                                "Reports the package name, whether the app was installed from Google Play, the state of Google Play services, the Play "
                                "Store and the billing connection, whether Play Games is configured and a player signed in, the services offered, and a "
                                "`problems` list of sentences that say what to fix. Example: {}.",
                                NULL, 1, on_status, NULL};
        snprintf(name, sizeof name, "%s.status", api->plugin);
        if (api->add_backend(api, &backend) != 0) return 1; /* the engine logged why */
        if (api->add_command(api, &status) != 0) say(2, "the command %s could not be registered (the engine logged why)", name);
    }
    say(1, "Google Play backend ready: services %s", services);
    return 0;
}
