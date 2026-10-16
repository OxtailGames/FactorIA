# The native code of the plugin loads its Java classes by name (JNI): R8 must not remove or rename them.
-keep class factoria.plugin.** { *; }
