# The {{NAME}} plugin: the ads backend of the game's `platform` API (docs/PLATFORM.md, "Ads"). One folder, two builds:
#
# Android. The native library is a thin C bridge (src/plugin.c) to the Java in android/, which talks to Google's consent library (UMP)
# and the Mobile Ads SDK (AdMob). Build it once per ABI the engine ships with the NDK's toolchain file:
#
#   cmake -S . -B build/android-arm64-v8a -G Ninja -DCMAKE_BUILD_TYPE=Release -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-26 \
#         -DCMAKE_TOOLCHAIN_FILE=$ANDROID_HOME/ndk/27.2.12479018/build/cmake/android.toolchain.cmake
#   cmake --build build/android-arm64-v8a
#
# (`factoria call platform.add_backend '{"backend":"admob"}'` does this for both ABIs.) Each build is copied to
# android/src/main/jniLibs/<abi>/lib{{NAME}}.so, which the Gradle module in android/ packages into the APK.
#
# iOS and macOS, on a Mac with Xcode, without a toolchain file:
#
#   cmake -S . -B build && cmake --build build
#
# The iOS library is Swift (src/*.swift: UMP, the App Tracking Transparency prompt, the Mobile Ads SDK) and needs Google's
# XCFrameworks in ios/frameworks/ (GoogleMobileAds.xcframework and UserMessagingPlatform.xcframework): they are a download, never
# part of this repo. `factoria call platform.add_backend '{"backend":"admob","sdk":"<the SDK zip or folder>"}'` copies them in
# and runs this build. It writes:
#
#   ios/iphoneos/lib{{NAME}}.a             an iPhone or iPad (arm64)
#   ios/iphonesimulator/lib{{NAME}}.a      the iOS Simulator (arm64 and x86_64)
#   macos/lib{{NAME}}.dylib                macOS: a library that offers no ads (Google ships no AdMob SDK for macOS)
#
# -DFA_ADMOB_SLICES="macos" builds only the macOS library ("macos;iphoneos;iphonesimulator" is the default). The compilers are
# called through `xcrun` with custom commands (as in the apple plugin): the build works the same with Ninja, Makefiles and Xcode.
cmake_minimum_required(VERSION 3.20)

if(CMAKE_TOOLCHAIN_FILE MATCHES "android\\.toolchain\\.cmake$" OR CMAKE_SYSTEM_NAME STREQUAL "Android" OR ANDROID_ABI)
    set(FA_ADMOB_TARGET android)
elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
    set(FA_ADMOB_TARGET apple)
else()
    # Checked before project() so that a computer without a toolchain for either gets this message, not "no C compiler".
    message(FATAL_ERROR
        "The {{NAME}} plugin (AdMob) is built for Android and iOS only. For Android, use the Android NDK's toolchain file, once per "
        "ABI:\n"
        "  cmake -S . -B build/android-arm64-v8a -G Ninja -DCMAKE_BUILD_TYPE=Release -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-26 "
        "-DCMAKE_TOOLCHAIN_FILE=<Android SDK>/ndk/27.2.12479018/build/cmake/android.toolchain.cmake\n"
        "or run `factoria call platform.add_backend '{\"backend\":\"admob\"}'`, which finds the SDK and the NDK and builds both ABIs. "
        "Install the NDK with: sdkmanager \"ndk;27.2.12479018\" \"cmake;3.31.6\" (or Android Studio > SDK Manager > SDK Tools). "
        "For iOS, build on a Mac with Xcode: Google's iOS SDK and the Swift compiler exist only there.")
endif()

# =========================================================================================================== Android ====
if(FA_ADMOB_TARGET STREQUAL "android")
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
    return()
endif()

# ============================================================================================================= Apple ====
project({{NAME}} NONE)

find_program(FA_XCRUN xcrun)
if(NOT FA_XCRUN)
    message(FATAL_ERROR "xcrun was not found: install Xcode from the App Store, then run `sudo xcode-select -s /Applications/Xcode.app`.")
endif()

set(FA_ADMOB_SLICES "macos;iphoneos;iphonesimulator" CACHE STRING "Which libraries to build: macos, iphoneos, iphonesimulator.")
set(FA_MACOS_ARCHS "${CMAKE_HOST_SYSTEM_PROCESSOR}" CACHE STRING "Architectures of the macOS library (arm64, x86_64).")
set(FA_MACOS_MIN "12.0" CACHE STRING "Oldest macOS the library runs on.")
set(FA_IOS_MIN "16.3" CACHE STRING "Oldest iOS the library runs on (the player's).")

file(GLOB swift_sources CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/*.swift)
set(entry_source ${CMAKE_CURRENT_SOURCE_DIR}/src/entry.c)
set(include_dir ${CMAKE_CURRENT_SOURCE_DIR}/include)  # fa_plugin.h and module.modulemap (module CFaPlugin)
set(frameworks_dir ${CMAKE_CURRENT_SOURCE_DIR}/ios/frameworks)

function(fa_sdk_path sdk out)
    execute_process(COMMAND ${FA_XCRUN} --sdk ${sdk} --show-sdk-path OUTPUT_VARIABLE path OUTPUT_STRIP_TRAILING_WHITESPACE
                    RESULT_VARIABLE status ERROR_QUIET)
    if(NOT status EQUAL 0 OR NOT path)
        message(FATAL_ERROR "The ${sdk} SDK was not found. Install the full Xcode (not only the Command Line Tools), open it once to "
                            "accept the license, and run `sudo xcode-select -s /Applications/Xcode.app`. To build fewer libraries: "
                            "-DFA_ADMOB_SLICES=macos")
    endif()
    set(${out} ${path} PARENT_SCOPE)
endfunction()

# The folder of an XCFramework's slice for the device or the simulator ("ios-arm64", "ios-arm64_x86_64-simulator").
function(fa_xcframework_slice name simulator out)
    set(xcframework ${frameworks_dir}/${name}.xcframework)
    if(NOT IS_DIRECTORY ${xcframework})
        message(FATAL_ERROR "${xcframework} does not exist. Google's SDK is a download that this repository never holds: get the "
                            "Google Mobile Ads SDK for iOS (zip) from https://developers.google.com/admob/ios/quick-start and run "
                            "`factoria call platform.add_backend '{\"backend\":\"admob\",\"sdk\":\"<the zip or the unzipped folder>\"}'`, "
                            "which copies GoogleMobileAds.xcframework and UserMessagingPlatform.xcframework to ios/frameworks/. "
                            "To build only the macOS library: -DFA_ADMOB_SLICES=macos")
    endif()
    file(GLOB candidates LIST_DIRECTORIES true ${xcframework}/ios-*)
    foreach(candidate IN LISTS candidates)
        if(NOT IS_DIRECTORY ${candidate} OR candidate MATCHES "-maccatalyst$")
            continue()
        endif()
        if(candidate MATCHES "-simulator$")
            set(is_simulator ON)
        else()
            set(is_simulator OFF)
        endif()
        if(is_simulator STREQUAL simulator)
            set(${out} ${candidate} PARENT_SCOPE)
            return()
        endif()
    endforeach()
    message(FATAL_ERROR "${xcframework} has no slice for ${simulator} (simulator: ON means ios-*-simulator). Download the iOS SDK again.")
endfunction()

# One library for one SDK. `triple` is the target without the architecture ("apple-macos12.0", "apple-ios16.3-simulator").
function(fa_admob_library slice sdk archs triple output)
    fa_sdk_path(${sdk} sdk_path)
    if(slice STREQUAL "macos")
        set(inputs ${entry_source} ${include_dir}/fa_plugin.h)
    else()
        if(slice STREQUAL "iphonesimulator")
            set(simulator ON)
        else()
            set(simulator OFF)
        endif()
        fa_xcframework_slice(GoogleMobileAds ${simulator} ads_slice)
        fa_xcframework_slice(UserMessagingPlatform ${simulator} ump_slice)
        set(inputs ${swift_sources} ${entry_source} ${include_dir}/fa_plugin.h ${include_dir}/module.modulemap)
    endif()
    set(per_arch)
    foreach(arch IN LISTS archs)
        set(work ${CMAKE_CURRENT_BINARY_DIR}/${slice}-${arch})
        set(target ${arch}-${triple})
        if(slice STREQUAL "macos")
            # No Swift and no Google code: the library registers nothing, so the Mac build of the game has no ads.
            set(built ${work}/lib{{NAME}}.dylib)
            add_custom_command(OUTPUT ${built}
                COMMAND ${CMAKE_COMMAND} -E make_directory ${work}
                COMMAND ${FA_XCRUN} --sdk ${sdk} clang -dynamiclib -target ${target} -isysroot ${sdk_path} ${entry_source}
                        -I ${include_dir} -DFA_PLUGIN_NAME={{NAME}} -fvisibility=hidden -o ${built}
                        -install_name @rpath/lib{{NAME}}.dylib
                DEPENDS ${inputs}
                COMMENT "AdMob: lib{{NAME}}.dylib (${arch}, macOS ${FA_MACOS_MIN}, no ads)" VERBATIM)
        else()
            # A static library for the app to link: the Swift objects and the C entry point (fa_plugin_init_{{NAME}}). Google's
            # frameworks are not in it: the app links them (their XCFrameworks are listed in plugin.json).
            set(built ${work}/lib{{NAME}}.a)
            add_custom_command(OUTPUT ${built}
                COMMAND ${CMAKE_COMMAND} -E make_directory ${work}
                COMMAND ${FA_XCRUN} --sdk ${sdk} clang -target ${target} -isysroot ${sdk_path} -c ${entry_source} -I ${include_dir}
                        -DFA_PLUGIN_NAME={{NAME}} -DFA_PLUGIN_STATIC -fvisibility=hidden -o ${work}/entry.o
                COMMAND ${FA_XCRUN} --sdk ${sdk} swiftc -emit-library -static -o ${work}/swift.a -module-name FaAdmobPlugin
                        -target ${target} -sdk ${sdk_path} -I ${include_dir} -F ${ads_slice} -F ${ump_slice} -O -swift-version 5
                        -parse-as-library ${swift_sources}
                COMMAND ${FA_XCRUN} --sdk ${sdk} libtool -static -o ${built} ${work}/swift.a ${work}/entry.o
                DEPENDS ${inputs}
                COMMENT "Swift: lib{{NAME}}.a (${arch}, ${sdk}, iOS ${FA_IOS_MIN})" VERBATIM)
        endif()
        list(APPEND per_arch ${built})
    endforeach()
    get_filename_component(folder ${output} DIRECTORY)
    list(LENGTH per_arch count)
    if(count GREATER 1)
        set(join COMMAND ${FA_XCRUN} lipo -create ${per_arch} -output ${output})
    else()
        set(join COMMAND ${CMAKE_COMMAND} -E copy ${per_arch} ${output})
    endif()
    add_custom_command(OUTPUT ${output}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${folder}
        ${join}
        DEPENDS ${per_arch}
        COMMENT "{{NAME}}: ${output}" VERBATIM)
    add_custom_target({{NAME}}_${slice} ALL DEPENDS ${output})
endfunction()

foreach(slice IN LISTS FA_ADMOB_SLICES)
    if(slice STREQUAL "macos")
        fa_admob_library(macos macosx "${FA_MACOS_ARCHS}" apple-macos${FA_MACOS_MIN}
                         ${CMAKE_CURRENT_SOURCE_DIR}/macos/lib{{NAME}}.dylib)
    elseif(slice STREQUAL "iphoneos")
        fa_admob_library(iphoneos iphoneos arm64 apple-ios${FA_IOS_MIN}
                         ${CMAKE_CURRENT_SOURCE_DIR}/ios/iphoneos/lib{{NAME}}.a)
    elseif(slice STREQUAL "iphonesimulator")
        fa_admob_library(iphonesimulator iphonesimulator "arm64;x86_64" apple-ios${FA_IOS_MIN}-simulator
                         ${CMAKE_CURRENT_SOURCE_DIR}/ios/iphonesimulator/lib{{NAME}}.a)
    else()
        message(FATAL_ERROR "FA_ADMOB_SLICES names \"${slice}\": use macos, iphoneos or iphonesimulator.")
    endif()
endforeach()
