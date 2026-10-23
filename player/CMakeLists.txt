# factoria_player: the minimal runtime shipped inside exported games.
#   Desktop : executable `factoria_player [projectDir]` (see main.cpp)
#   Android : SHARED library libfactoria_player.so loaded by NativeActivity
#             (android.app.lib_name = factoria_player, see platforms/android)
#   Web     : factoria_player.js + factoria_player.wasm (Emscripten, MODULARIZE, createFactoriaPlayer), run by
#             platforms/web/shell.html, which writes the game pack to /game.pak first (main.cpp)
#   iOS     : app bundle; the game is copied to <app>/game when FA_GAME_PROJECT_DIR is set
#
# iOS / bundle options (cache variables, set by `factoria export --platform ios`):
#   FA_GAME_PROJECT_DIR  game folder (contains factoria.json) copied into the bundle
#   FA_GAME_BUNDLE_ID    CFBundleIdentifier      (default com.factoria.player)
#   FA_GAME_NAME         display name            (default FactorIA Player)
#   FA_GAME_VERSION      version, e.g. 1.2.3     (default 0.1.0)
#   FA_GAME_BUILD        CFBundleVersion         (default: FA_GAME_VERSION)
#   FA_GAME_ORIENTATION  landscape|portrait|any  (default landscape)
#   FA_IOS_DEVELOPMENT_TEAM  Apple team id for signing (optional; can be set in Xcode)
#   FA_GAME_ASSET_CATALOG    an Assets.xcassets folder with an AppIcon set (optional), compiled into the app
#   FA_GAME_PRIVACY_MANIFEST a PrivacyInfo.xcprivacy file (optional), copied to the root of the app bundle
#   FA_GAME_NON_EXEMPT_ENCRYPTION  ON = ITSAppUsesNonExemptEncryption true in Info.plist (default OFF = false)
#   FA_GAME_PLUGINS, FA_GAME_PLUGIN_DIR  the game's native plugins, linked into the app (platforms/ios/plugins.cmake)
file(GLOB player_srcs CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp)

if(FA_PLATFORM STREQUAL "android")
    add_library(factoria_player SHARED ${player_srcs})
    # ANativeActivity_onCreate lives in the static fa_platform archive (sokol_app); force the linker
    # to pull it in and export it, otherwise NativeActivity cannot find its entry point.
    target_link_options(factoria_player PRIVATE -u ANativeActivity_onCreate)
    # 16 KB pages: Google Play requires every native library of an app that targets Android 15+ to load on devices with
    # 16 KB memory pages, so the segments are aligned to 0x4000 (NDK r28+ does it by default, r27 does not).
    target_link_options(factoria_player PRIVATE -Wl,-z,max-page-size=16384)
    target_link_libraries(factoria_player PRIVATE android log EGL GLESv3)
elseif(FA_PLATFORM STREQUAL "web")
    add_executable(factoria_player ${player_srcs})
    # The contract with the page (platforms/web/shell.html): a factory function createFactoriaPlayer(moduleOverrides) that
    # resolves to the module; no pthreads, so no SharedArrayBuffer and no COOP/COEP headers are needed on the host.
    #   FORCE_FILESYSTEM + idbfs.js    the save folder lives in IndexedDB (fs_web.cpp)
    #   EXPORTED_RUNTIME_METHODS       FS: the page writes /game.pak
    #   EXPORTED_FUNCTIONS             main, the save-restored callback of fs_web.cpp, and the two stack helpers the JS runtime
    #                                  needs (without them this Emscripten fails to link with "undefined symbol")
    #   ALLOW_MEMORY_GROWTH            the pack and the assets live in memory; the heap grows as needed
    #   STACK_SIZE                     QuickJS and the layout code recurse deeper than the 64 KB default allows
    #   ENVIRONMENT=web                no node/worker glue
    target_link_options(factoria_player PRIVATE
        -sMODULARIZE=1 -sEXPORT_NAME=createFactoriaPlayer -sENVIRONMENT=web
        -sUSE_WEBGL2=1 -sMIN_WEBGL_VERSION=2 -sMAX_WEBGL_VERSION=2
        -sALLOW_MEMORY_GROWTH=1 -sSTACK_SIZE=2097152 -sINITIAL_MEMORY=67108864
        -sFORCE_FILESYSTEM=1 -sEXPORTED_RUNTIME_METHODS=FS -lidbfs.js
        -sEXPORTED_FUNCTIONS=_main,_fa_web_save_restored,_emscripten_stack_get_current,__emscripten_stack_restore
        -sEXIT_RUNTIME=0)
    target_link_options(factoria_player PRIVATE "$<$<CONFIG:Debug>:-sASSERTIONS=1>")
elseif(FA_PLATFORM STREQUAL "ios")
    set(FA_GAME_BUNDLE_ID "com.factoria.player" CACHE STRING "iOS bundle identifier (reverse DNS)")
    set(FA_GAME_NAME "FactorIA Player" CACHE STRING "Game display name")
    set(FA_GAME_VERSION "0.1.0" CACHE STRING "Game version (x.y.z)")
    set(FA_GAME_BUILD "" CACHE STRING "Build number, CFBundleVersion (empty = the version)")
    set(FA_GAME_ORIENTATION "landscape" CACHE STRING "landscape | portrait | any")
    set(FA_GAME_PROJECT_DIR "" CACHE PATH "Game folder (contains factoria.json) to copy into the app bundle")
    set(FA_IOS_DEVELOPMENT_TEAM "" CACHE STRING "Apple developer team id used for signing")
    set(FA_GAME_ASSET_CATALOG "" CACHE PATH "Assets.xcassets folder with an AppIcon set, compiled into the app (optional)")
    set(FA_GAME_PRIVACY_MANIFEST "" CACHE FILEPATH "PrivacyInfo.xcprivacy copied to the root of the app bundle (optional)")
    option(FA_GAME_NON_EXEMPT_ENCRYPTION "ITSAppUsesNonExemptEncryption true in Info.plist" OFF)

    set(FA_PLIST_OUT ${CMAKE_CURRENT_BINARY_DIR}/Info.plist)
    include(${FA_ROOT}/platforms/ios/plist.cmake)  # fa_ios_configure_plist(): orientations + XML-escaped name -> Info.plist.in
    fa_ios_configure_plist(${FA_PLIST_OUT})

    add_executable(factoria_player MACOSX_BUNDLE ${player_srcs} ${CMAKE_CURRENT_SOURCE_DIR}/ios_bundle.mm)
    set_source_files_properties(ios_bundle.mm PROPERTIES COMPILE_OPTIONS "-fobjc-arc")
    set_target_properties(factoria_player PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST ${FA_PLIST_OUT}
        XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${FA_GAME_BUNDLE_ID}"
        XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2"
        XCODE_ATTRIBUTE_ENABLE_BITCODE "NO"
        XCODE_ATTRIBUTE_CODE_SIGN_STYLE "Automatic")
    if(FA_IOS_DEVELOPMENT_TEAM)
        set_target_properties(factoria_player PROPERTIES XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "${FA_IOS_DEVELOPMENT_TEAM}")
    endif()
    if(FA_GAME_ASSET_CATALOG)
        # `factoria export --platform ios` writes <export>/Assets.xcassets (AppIcon set) and build_ios.sh passes it here.
        # Xcode compiles it into Assets.car and adds CFBundleIcons / CFBundleIconName to the app's Info.plist.
        if(NOT IS_DIRECTORY "${FA_GAME_ASSET_CATALOG}")
            message(FATAL_ERROR "FA_GAME_ASSET_CATALOG='${FA_GAME_ASSET_CATALOG}' is not a folder. "
                "Point it at the Assets.xcassets folder that `factoria export --platform ios` writes next to build_ios.sh.")
        endif()
        target_sources(factoria_player PRIVATE "${FA_GAME_ASSET_CATALOG}")
        set_source_files_properties("${FA_GAME_ASSET_CATALOG}" PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
        set_target_properties(factoria_player PROPERTIES XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME "AppIcon")
    endif()
    fa_ios_add_privacy_manifest(factoria_player)
    target_link_libraries(factoria_player PRIVATE "-framework UIKit" "-framework CoreGraphics" "-framework Metal" "-framework MetalKit"
        "-framework QuartzCore" "-framework Foundation" "-framework AudioToolbox" "-framework AVFoundation")
    include(${FA_ROOT}/platforms/ios/plugins.cmake)
    fa_ios_link_plugins(factoria_player)

    # The player's own code as a static library. The release workflow builds it with the engine archives it links
    # (every fa_* module, quickjs, box2d) for the device and the simulator, and the macOS download carries them in
    # mobile/ios/<sdk>/: `factoria export --platform ios` then links an app from them, without the engine source
    # (platforms/ios/prebuilt/CMakeLists.txt, docs/EXPORTING.md). Not part of ALL.
    add_library(factoria_player_main STATIC EXCLUDE_FROM_ALL ${player_srcs} ${CMAKE_CURRENT_SOURCE_DIR}/ios_bundle.mm)
    target_link_libraries(factoria_player_main PUBLIC fa_runtime PRIVATE fa_warnings)

    if(FA_GAME_PROJECT_DIR)
        if(NOT EXISTS "${FA_GAME_PROJECT_DIR}/factoria.json")
            message(FATAL_ERROR "FA_GAME_PROJECT_DIR='${FA_GAME_PROJECT_DIR}' has no factoria.json. "
                "Point it at the game folder, e.g. -DFA_GAME_PROJECT_DIR=/path/to/mygame")
        endif()
        add_custom_command(TARGET factoria_player POST_BUILD
            # Not VERBATIM on purpose: with the Xcode generator the bundle path contains
            # ${EFFECTIVE_PLATFORM_NAME}, which the build-phase shell must expand (VERBATIM escapes
            # it, and the game ends up in a literal "Debug${EFFECTIVE_PLATFORM_NAME}" folder).
            COMMAND ${CMAKE_COMMAND} "-DSRC=${FA_GAME_PROJECT_DIR}" "-DDST=$<TARGET_BUNDLE_CONTENT_DIR:factoria_player>/game"
                -P ${FA_ROOT}/platforms/common/copy_game.cmake
            COMMENT "Copying game into the app bundle")
    else()
        message(STATUS "factoria_player (iOS): FA_GAME_PROJECT_DIR not set; the app will show an error screen. "
            "Use -DFA_GAME_PROJECT_DIR=<game folder> or `factoria export --platform ios`.")
    endif()
else()
    add_executable(factoria_player ${player_srcs})
    if(WIN32)
        # A GUI program, so an exported game opens no console window (main.cpp attaches to the console of a terminal that
        # starts it, and every run writes log.txt). main() stays the entry point: MSVC has to be told, MinGW's startup
        # code calls main() by itself.
        set_target_properties(factoria_player PROPERTIES WIN32_EXECUTABLE ON)
        if(MSVC)
            target_link_options(factoria_player PRIVATE /ENTRY:mainCRTStartup)
        endif()
        # The placeholder icon and version information of the exe (player/windows/factoria_player.rc): 32-bit BMP images of
        # fixed sizes and padded strings that `factoria export --platform windows` overwrites in place with the game's icon,
        # name and version (tools/common/src/pe_icon.cpp).
        # CMake enables the RC language by itself with C/C++ on Windows (rc.exe with MSVC, windres with MinGW); the include
        # directory is where both look for the .ico named in the .rc.
        target_sources(factoria_player PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/windows/factoria_player.rc)
        target_include_directories(factoria_player PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/windows)
        set_source_files_properties(${CMAKE_CURRENT_SOURCE_DIR}/windows/factoria_player.rc PROPERTIES
            OBJECT_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/windows/factoria_player.ico
            COMPILE_DEFINITIONS "FA_VERSION_MAJOR=${PROJECT_VERSION_MAJOR};FA_VERSION_MINOR=${PROJECT_VERSION_MINOR};FA_VERSION_PATCH=${PROJECT_VERSION_PATCH}")
    endif()
    # `factoria_player --version` prints the version and build that `factoria version` prints (the release checks run it on Linux).
    if(FA_BUILD_TESTS)
        add_test(NAME player_version COMMAND factoria_player --version)
        set_tests_properties(player_version PROPERTIES PASS_REGULAR_EXPRESSION
                              "^factoria_player ${FA_ENGINE_VERSION} \\(build [^)]+\\)[\r\n]")
    endif()
endif()

target_link_libraries(factoria_player PRIVATE fa_runtime fa_warnings)
