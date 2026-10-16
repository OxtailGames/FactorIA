# Written by `factoria export --platform ios` in prebuilt mode (docs/EXPORTING.md, "iOS"): the iOS app, linked from the
# prebuilt engine libraries in lib/<iphoneos|iphonesimulator>/ that the FactorIA download carries. It needs no engine
# source. ./build_ios.sh configures it with the Xcode generator (-DCMAKE_SYSTEM_NAME=iOS, the SDK and the game settings
# below). The libraries come from the release workflow: the player's static library (target factoria_player_main in
# player/CMakeLists.txt) plus every engine archive it links.
cmake_minimum_required(VERSION 3.24)
set(CMAKE_OSX_DEPLOYMENT_TARGET "16.3" CACHE STRING "Minimum iOS version (the libraries are built for 16.3)")
project(FactorIA LANGUAGES C CXX)

if(NOT CMAKE_SYSTEM_NAME STREQUAL "iOS")
    message(FATAL_ERROR "This project builds an iOS app, but CMAKE_SYSTEM_NAME is '${CMAKE_SYSTEM_NAME}'. "
        "Run ./build_ios.sh (it passes -G Xcode -DCMAKE_SYSTEM_NAME=iOS and the SDK).")
endif()

set(FA_GAME_BUNDLE_ID "com.factoria.player" CACHE STRING "iOS bundle identifier (reverse DNS)")
set(FA_GAME_NAME "FactorIA Player" CACHE STRING "Game display name")
set(FA_GAME_VERSION "0.1.0" CACHE STRING "Game version (x.y.z)")
set(FA_GAME_BUILD "" CACHE STRING "Build number, CFBundleVersion (empty = the version)")
set(FA_GAME_ORIENTATION "landscape" CACHE STRING "landscape | portrait | any")
set(FA_GAME_PROJECT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/game" CACHE PATH "Game folder (contains factoria.json) copied into the app bundle")
set(FA_IOS_DEVELOPMENT_TEAM "" CACHE STRING "Apple developer team id used for signing")
set(FA_GAME_ASSET_CATALOG "" CACHE PATH "Assets.xcassets folder with an AppIcon set, compiled into the app (optional)")

# Info.plist: the same template and orientation rules as the app built from the engine source.
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/plist.cmake)
set(FA_PLIST_OUT ${CMAKE_CURRENT_BINARY_DIR}/Info.plist)
fa_ios_configure_plist(${FA_PLIST_OUT})

# The libraries of the SDK this configure builds for: a device or the simulator (the simulator ones hold arm64 and x86_64).
string(TOLOWER "${CMAKE_OSX_SYSROOT}" fa_sdk)
if(fa_sdk MATCHES "simulator")
    set(FA_IOS_SLICE iphonesimulator)
else()
    set(FA_IOS_SLICE iphoneos)
endif()
file(GLOB FA_PLAYER_LIBS CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/lib/${FA_IOS_SLICE}/*.a)
if(NOT FA_PLAYER_LIBS)
    message(FATAL_ERROR "No engine libraries in ${CMAKE_CURRENT_SOURCE_DIR}/lib/${FA_IOS_SLICE}. "
        "Export the game again with `factoria export --platform ios` from the FactorIA download for macOS "
        "(its mobile/ios folder holds them).")
endif()

if(NOT EXISTS "${FA_GAME_PROJECT_DIR}/factoria.json")
    message(FATAL_ERROR "FA_GAME_PROJECT_DIR='${FA_GAME_PROJECT_DIR}' has no factoria.json. "
        "Point it at the game folder, e.g. -DFA_GAME_PROJECT_DIR=/path/to/mygame")
endif()

# All code is in the libraries: the app target only needs one source file.
file(CONFIGURE OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/stub.cpp CONTENT "// The player is linked from the prebuilt libraries in lib/.\n")
add_executable(factoria_player MACOSX_BUNDLE ${CMAKE_CURRENT_BINARY_DIR}/stub.cpp)
set_target_properties(factoria_player PROPERTIES
    MACOSX_BUNDLE_INFO_PLIST ${FA_PLIST_OUT}
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${FA_GAME_BUNDLE_ID}"
    XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2"
    XCODE_ATTRIBUTE_ENABLE_BITCODE "NO"
    XCODE_ATTRIBUTE_CODE_SIGN_STYLE "Automatic")
if(FA_IOS_DEVELOPMENT_TEAM)
    set_target_properties(factoria_player PROPERTIES XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "${FA_IOS_DEVELOPMENT_TEAM}")
endif()
# The app icon: the Assets.xcassets that `factoria export --platform ios` writes next to build_ios.sh (an AppIcon set). Xcode
# compiles it into Assets.car and adds CFBundleIcons / CFBundleIconName to the app's Info.plist.
if(FA_GAME_ASSET_CATALOG)
    if(NOT IS_DIRECTORY "${FA_GAME_ASSET_CATALOG}")
        message(FATAL_ERROR "FA_GAME_ASSET_CATALOG='${FA_GAME_ASSET_CATALOG}' is not a folder. "
            "Export the game again with `factoria export --platform ios` (it writes Assets.xcassets next to build_ios.sh).")
    endif()
    target_sources(factoria_player PRIVATE "${FA_GAME_ASSET_CATALOG}")
    set_source_files_properties("${FA_GAME_ASSET_CATALOG}" PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
    set_target_properties(factoria_player PROPERTIES XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME "AppIcon")
endif()
# The archives are linked by path, in any order (the linker resolves symbols across all of them; `main` comes from
# sokol_app inside the platform archive). The frameworks are those of engine/platform/CMakeLists.txt (iOS) and
# player/CMakeLists.txt: keep the lists in sync when the engine starts using another one.
target_link_libraries(factoria_player PRIVATE ${FA_PLAYER_LIBS}
    "-framework UIKit" "-framework CoreGraphics" "-framework Metal" "-framework MetalKit" "-framework QuartzCore"
    "-framework Foundation" "-framework AudioToolbox" "-framework AVFoundation" "-framework GameController")

add_custom_command(TARGET factoria_player POST_BUILD
    # Not VERBATIM on purpose: with the Xcode generator the bundle path contains ${EFFECTIVE_PLATFORM_NAME}, which the
    # build-phase shell must expand (same as in player/CMakeLists.txt).
    COMMAND ${CMAKE_COMMAND} "-DSRC=${FA_GAME_PROJECT_DIR}" "-DDST=$<TARGET_BUNDLE_CONTENT_DIR:factoria_player>/game"
        -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/copy_game.cmake
    COMMENT "Copying game into the app bundle")
