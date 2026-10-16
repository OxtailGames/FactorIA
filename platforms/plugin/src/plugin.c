/* A FactorIA native plugin (docs/EXTENDING.md, "Native plugins"): the script function plugins.<name>.add(a, b) and the
 * command <name>.info. include/fa_plugin.h is the whole API. CMakeLists.txt passes the plugin's name as FA_PLUGIN_NAME
 * and copies the build where the game finds it. */
#include <stdio.h>

#if defined(__ANDROID__)
#include <android/native_activity.h>
#include <jni.h>
#endif

#include "fa_plugin.h"

static const FaPluginApi* g_api;

#if defined(__ANDROID__)
/* Calls Plugin.add(a, b) of the plugin's Java class. Returns NULL and the sum, or the step that failed. The class comes
 * from the activity's class loader: FindClass on a native thread only sees the system's classes, not the APK's. */
static const char* java_add(JNIEnv* env, jobject activity, const char* class_name, double a, double b, double* sum) {
    jclass activity_class = (*env)->GetObjectClass(env, activity);
    jmethodID get_loader = (*env)->GetMethodID(env, activity_class, "getClassLoader", "()Ljava/lang/ClassLoader;");
    jobject loader = get_loader ? (*env)->CallObjectMethod(env, activity, get_loader) : NULL;
    jmethodID load_class = NULL;
    jstring name = NULL;
    jclass cls;
    jmethodID add_method;

    if (!loader) return "get the activity's class loader";
    load_class = (*env)->GetMethodID(env, (*env)->GetObjectClass(env, loader), "loadClass", "(Ljava/lang/String;)Ljava/lang/Class;");
    if (load_class) name = (*env)->NewStringUTF(env, class_name);
    if (!name) return "ask the class loader for the class";
    cls = (jclass)(*env)->CallObjectMethod(env, loader, load_class, name);
    if (!cls) return "find the class in the app";
    add_method = (*env)->GetStaticMethodID(env, cls, "add", "(DD)D");
    if (!add_method) return "find the method add(double, double)";
    *sum = (*env)->CallStaticDoubleMethod(env, cls, add_method, a, b);
    return NULL;
}

/* The sum, computed by the Java class android/src/main/java/factoria/plugin/<name>/Plugin.java: how a plugin reaches an
 * Android SDK. Returns 1, or 0 after answering the call with the failure. */
static int add_in_java(FaCall* call, double a, double b, double* sum) {
    const ANativeActivity* activity = (const ANativeActivity*)g_api->native_handle("android.activity");
    JavaVM* vm = activity ? activity->vm : NULL;
    JNIEnv* env = NULL;
    int attached = 0;
    const char* problem = vm ? "attach the game's thread to the Java VM" : "get the Android activity";
    char class_name[160], message[400];

    snprintf(class_name, sizeof class_name, "factoria.plugin.%s.Plugin", g_api->plugin);
    if (vm && (*vm)->GetEnv(vm, (void**)&env, JNI_VERSION_1_6) == JNI_EDETACHED) /* the game's thread is not a Java thread */
        attached = (*vm)->AttachCurrentThread(vm, &env, NULL) == JNI_OK;
    if (env && (*env)->PushLocalFrame(env, 16) == 0) {
        problem = java_add(env, activity->clazz, class_name, a, b, sum);
        if (!problem && (*env)->ExceptionCheck(env)) problem = "run add(), which threw an exception (it is in the log)";
        if ((*env)->ExceptionCheck(env)) (*env)->ExceptionDescribe(env); /* logs the exception and clears it */
        (*env)->PopLocalFrame(env, NULL);
    }
    if (attached) (*vm)->DetachCurrentThread(vm);
    if (!problem) return 1;
    snprintf(message, sizeof message, "the Java class %s could not be called: failed to %s", class_name, problem);
    g_api->fail(call, message,
                "android/ must be the plugin's Gradle module (build.gradle, src/main/java/factoria/plugin/<name>/Plugin.java with "
                "public static double add(double, double)); export the game again so that the app contains it (docs/MOBILE.md)");
    return 0;
}
#endif

/* add(a, b): args_json is the call's arguments as a JSON array, e.g. "[1,2]"; the reply is JSON text. */
static void add(FaCall* call, const char* args_json, void* user) {
    double a = 0, b = 0, sum = 0;
    char out[128];
    (void)user;
    if (sscanf(args_json, " [ %lf , %lf ]", &a, &b) != 2) {
        snprintf(out, sizeof out, "plugins.%s.add(1, 2)", g_api->plugin);
        g_api->fail(call, "add(a, b) takes two numbers", out);
        return;
    }
#if defined(__ANDROID__)
    if (!add_in_java(call, a, b, &sum)) return; /* it answered with the failure */
#else
    sum = a + b;
#endif
    snprintf(out, sizeof out, "%.17g", sum);
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
