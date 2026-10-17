# The native code of the plugin loads its Java classes by name (JNI) and registers native methods on them: R8 must not remove or
# rename them.
-keep class factoria.plugin.** { *; }
