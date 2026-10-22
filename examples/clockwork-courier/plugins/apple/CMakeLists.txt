# The apple plugin: the Apple platform backend of a FactorIA game (docs/PLATFORM.md, "Apple"): Game Center, StoreKit 2
# and iCloud, written in Swift. It builds on a Mac with Xcode, all three libraries at once:
#
#   cmake -S . -B build && cmake --build build
#
# and copies them where `factoria run` and `factoria export` find them:
#
#   macos/libapple.dylib                    macOS (the architecture of this Mac; -DFA_MACOS_ARCHS="arm64;x86_64" for both)
#   ios/iphoneos/libapple.a                 an iPhone or iPad (arm64)
#   ios/iphonesimulator/libapple.a          the iOS Simulator (arm64 and x86_64)
#
# -DFA_APPLE_SLICES="macos" builds only the macOS library ("macos;iphoneos;iphonesimulator" is the default).
#
# There is no CMake language for Swift in every generator, so the compilers are called through `xcrun` (the Xcode that
# `xcode-select -p` names) with custom commands: the build works the same with Ninja, Makefiles and Xcode, and needs no
# toolchain file. ios/plugin.json and macos/plugin.json tell the exports which frameworks, Swift runtime and
# entitlements the plugin needs (docs/MOBILE.md, "Native plugins (iOS)").
cmake_minimum_required(VERSION 3.20)
project(apple NONE)

if(NOT CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
    message(FATAL_ERROR "The apple plugin builds on a Mac with Xcode: StoreKit and Game Center exist only in Apple's SDKs. "
                        "Build it on a Mac and copy macos/ and ios/ back (platforms: set them in factoria.json \"plugins\").")
endif()
find_program(FA_XCRUN xcrun)
if(NOT FA_XCRUN)
    message(FATAL_ERROR "xcrun was not found: install Xcode from the App Store, then run `sudo xcode-select -s /Applications/Xcode.app`.")
endif()

set(FA_APPLE_SLICES "macos;iphoneos;iphonesimulator" CACHE STRING "Which libraries to build: macos, iphoneos, iphonesimulator.")
set(FA_MACOS_ARCHS "${CMAKE_HOST_SYSTEM_PROCESSOR}" CACHE STRING "Architectures of the macOS library (arm64, x86_64).")
set(FA_MACOS_MIN "12.0" CACHE STRING "Oldest macOS the library runs on (StoreKit 2 needs 12).")
set(FA_IOS_MIN "16.3" CACHE STRING "Oldest iOS the library runs on (the player's).")

file(GLOB swift_sources CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/*.swift)
set(entry_source ${CMAKE_CURRENT_SOURCE_DIR}/src/entry.c)
set(include_dir ${CMAKE_CURRENT_SOURCE_DIR}/include)  # fa_plugin.h and module.modulemap (module CFaPlugin)
set(inputs ${swift_sources} ${entry_source} ${include_dir}/fa_plugin.h ${include_dir}/module.modulemap)

function(fa_sdk_path sdk out)
    execute_process(COMMAND ${FA_XCRUN} --sdk ${sdk} --show-sdk-path OUTPUT_VARIABLE path OUTPUT_STRIP_TRAILING_WHITESPACE
                    RESULT_VARIABLE status ERROR_QUIET)
    if(NOT status EQUAL 0 OR NOT path)
        message(FATAL_ERROR "The ${sdk} SDK was not found. Install the full Xcode (not only the Command Line Tools), open it once to "
                            "accept the license, and run `sudo xcode-select -s /Applications/Xcode.app`. To build fewer libraries: "
                            "-DFA_APPLE_SLICES=macos")
    endif()
    set(${out} ${path} PARENT_SCOPE)
endfunction()

# One library for one SDK. `triple` is the target without the architecture ("apple-macos12.0", "apple-ios16.3-simulator").
function(fa_apple_library slice sdk archs triple output)
    fa_sdk_path(${sdk} sdk_path)
    set(per_arch)
    foreach(arch IN LISTS archs)
        set(work ${CMAKE_CURRENT_BINARY_DIR}/${slice}-${arch})
        set(target ${arch}-${triple})
        if(slice STREQUAL "macos")
            set(built ${work}/libapple.dylib)
            add_custom_command(OUTPUT ${built}
                COMMAND ${CMAKE_COMMAND} -E make_directory ${work}
                COMMAND ${FA_XCRUN} --sdk ${sdk} clang -target ${target} -isysroot ${sdk_path} -c ${entry_source} -I ${include_dir}
                        -DFA_PLUGIN_NAME=apple -fvisibility=hidden -o ${work}/entry.o
                COMMAND ${FA_XCRUN} --sdk ${sdk} swiftc -emit-library -o ${built} -module-name FaApplePlugin -target ${target}
                        -sdk ${sdk_path} -I ${include_dir} -O -swift-version 5 -parse-as-library ${swift_sources} ${work}/entry.o
                        -Xlinker -install_name -Xlinker @rpath/libapple.dylib
                DEPENDS ${inputs}
                COMMENT "Swift: libapple.dylib (${arch}, macOS ${FA_MACOS_MIN})" VERBATIM)
        else()
            # A static library for the app to link: the Swift objects and the C entry point (fa_plugin_init_apple).
            set(built ${work}/libapple.a)
            add_custom_command(OUTPUT ${built}
                COMMAND ${CMAKE_COMMAND} -E make_directory ${work}
                COMMAND ${FA_XCRUN} --sdk ${sdk} clang -target ${target} -isysroot ${sdk_path} -c ${entry_source} -I ${include_dir}
                        -DFA_PLUGIN_NAME=apple -DFA_PLUGIN_STATIC -fvisibility=hidden -o ${work}/entry.o
                COMMAND ${FA_XCRUN} --sdk ${sdk} swiftc -emit-library -static -o ${work}/swift.a -module-name FaApplePlugin
                        -target ${target} -sdk ${sdk_path} -I ${include_dir} -O -swift-version 5 -parse-as-library ${swift_sources}
                COMMAND ${FA_XCRUN} --sdk ${sdk} libtool -static -o ${built} ${work}/swift.a ${work}/entry.o
                DEPENDS ${inputs}
                COMMENT "Swift: libapple.a (${arch}, ${sdk}, iOS ${FA_IOS_MIN})" VERBATIM)
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
        COMMENT "apple: ${output}" VERBATIM)
    add_custom_target(apple_${slice} ALL DEPENDS ${output})
endfunction()

foreach(slice IN LISTS FA_APPLE_SLICES)
    if(slice STREQUAL "macos")
        fa_apple_library(macos macosx "${FA_MACOS_ARCHS}" apple-macos${FA_MACOS_MIN}
                         ${CMAKE_CURRENT_SOURCE_DIR}/macos/libapple.dylib)
    elseif(slice STREQUAL "iphoneos")
        fa_apple_library(iphoneos iphoneos arm64 apple-ios${FA_IOS_MIN}
                         ${CMAKE_CURRENT_SOURCE_DIR}/ios/iphoneos/libapple.a)
    elseif(slice STREQUAL "iphonesimulator")
        fa_apple_library(iphonesimulator iphonesimulator "arm64;x86_64" apple-ios${FA_IOS_MIN}-simulator
                         ${CMAKE_CURRENT_SOURCE_DIR}/ios/iphonesimulator/libapple.a)
    else()
        message(FATAL_ERROR "FA_APPLE_SLICES names \"${slice}\": use macos, iphoneos or iphonesimulator.")
    endif()
endforeach()
