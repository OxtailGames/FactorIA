# Written by factoria export. R8 / ProGuard reads it only when minifyEnabled is on (app/build.gradle).
# The engine's native code loads factoria.engine.Ime by name and registers its native methods (ime_android.cpp):
# renaming or removing it would turn the IME off.
-keep class factoria.engine.** { *; }
-keepclasseswithmembernames class * {
    native <methods>;
}
