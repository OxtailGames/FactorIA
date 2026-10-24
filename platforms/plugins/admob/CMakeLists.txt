# The {{NAME}} plugin: the ads backend of the game's `platform` API (docs/PLATFORM.md, "Ads"). It is Android only: the native
# library is a thin C bridge (src/plugin.c) to the Java in android/, which talks to Google's consent library (UMP) and the
# Mobile Ads SDK (AdMob). Build it once per ABI the engine ships with the NDK's toolchain file:
#
#   cmake -S . -B build/android-arm64-v8a -G Ninja -DCMAKE_BUILD_TYPE=Release -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-26 \
#         -DCMAKE_TOOLCHAIN_FILE=$ANDROID_HOME/ndk/27.2.12479018/build/cmake/android.toolchain.cmake
#   cmake --build build/android-arm64-v8a
#
# (`factoria call platform.add_backend '{"backend":"admob"}'` does this for both ABIs.) Each build is copied to
# android/src/main/jniLibs/<abi>/lib{{NAME}}.so, which the Gradle module in android/ packages into the APK.
cmake_minimum_required(VERSION 3.20)

# Checked before project() so that a computer without an Android toolchain gets this message, not "no C compiler".
if(NOT CMAKE_TOOLCHAIN_FILE MATCHES "android\\.toolchain\\.cmake$" AND NOT CMAKE_SYSTEM_NAME STREQUAL "Android" AND NOT ANDROID_ABI)
    message(FATAL_ERROR
        "The {{NAME}} plugin (AdMob) is built for Android only, with the Android NDK. Configure it with the NDK's toolchain "
        "file, once per ABI:\n"
        "  cmake -S . -B build/android-arm64-v8a -G Ninja -DCMAKE_BUILD_TYPE=Release -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-26 "
        "-DCMAKE_TOOLCHAIN_FILE=<Android SDK>/ndk/27.2.12479018/build/cmake/android.toolchain.cmake\n"
        "or run `factoria call platform.add_backend '{\"backend\":\"admob\"}'`, which finds the SDK and the NDK and builds both ABIs. "
        "Install the NDK with: sdkmanager \"ndk;27.2.12479018\" \"cmake;3.31.6\" (or Android Studio > SDK Manager > SDK Tools).")
endif()

project({{NAME}} C)

add_library({{NAME}} SHARED src/plugin.c)
target_include_directories({{NAME}} PRIVATE include)
target_compile_definitions({{NAME}} PRIVATE FA_PLUGIN_NAME={{NAME}})
set_target_properties({{NAME}} PROPERTIES C_VISIBILITY_PRESET hidden)

# Google Play wants 16 KB pages for apps that target Android 15+; the NDK still links for 4 KB.
target_link_options({{NAME}} PRIVATE -Wl,-z,max-page-size=16384 $<$<CONFIG:Release>:-Wl,--strip-all>)

set(platform android/src/main/jniLibs/${ANDROID_ABI})
add_custom_command(TARGET {{NAME}} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_SOURCE_DIR}/${platform}
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:{{NAME}}> ${CMAKE_CURRENT_SOURCE_DIR}/${platform}/)
