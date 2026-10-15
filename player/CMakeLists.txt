# factoria_player: the minimal runtime shipped inside exported games.
#   Desktop : executable `factoria_player [projectDir]` (see main.cpp)
#   Android : SHARED library libfactoria_player.so loaded by NativeActivity
#             (android.app.lib_name = factoria_player, see platforms/android)
#   iOS     : app bundle; the game is copied to <app>/game when FA_GAME_PROJECT_DIR is set
#
# iOS / bundle options (cache variables, set by `factoria export --platform ios`):
#   FA_GAME_PROJECT_DIR  game folder (contains factoria.json) copied into the bundle
#   FA_GAME_BUNDLE_ID    CFBundleIdentifier      (default com.factoria.player)
#   FA_GAME_NAME         display name            (default FactorIA Player)
#   FA_GAME_VERSION      version, e.g. 1.2.3     (default 0.1.0)
#   FA_GAME_ORIENTATION  landscape|portrait|any  (default landscape)
#   FA_IOS_DEVELOPMENT_TEAM  Apple team id for signing (optional; can be set in Xcode)
file(GLOB player_srcs CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp)

if(FA_PLATFORM STREQUAL "android")
    add_library(factoria_player SHARED ${player_srcs})
    # ANativeActivity_onCreate lives in the static fa_platform archive (sokol_app); force the linker
    # to pull it in and export it, otherwise NativeActivity cannot find its entry point.
    target_link_options(factoria_player PRIVATE -u ANativeActivity_onCreate)
    target_link_libraries(factoria_player PRIVATE android log EGL GLESv3)
elseif(FA_PLATFORM STREQUAL "ios")
    set(FA_GAME_BUNDLE_ID "com.factoria.player" CACHE STRING "iOS bundle identifier (reverse DNS)")
    set(FA_GAME_NAME "FactorIA Player" CACHE STRING "Game display name")
    set(FA_GAME_VERSION "0.1.0" CACHE STRING "Game version (x.y.z)")
    set(FA_GAME_ORIENTATION "landscape" CACHE STRING "landscape | portrait | any")
    set(FA_GAME_PROJECT_DIR "" CACHE PATH "Game folder (contains factoria.json) to copy into the app bundle")
    set(FA_IOS_DEVELOPMENT_TEAM "" CACHE STRING "Apple developer team id used for signing")

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
    target_link_libraries(factoria_player PRIVATE "-framework UIKit" "-framework CoreGraphics" "-framework Metal" "-framework MetalKit"
        "-framework QuartzCore" "-framework Foundation" "-framework AudioToolbox" "-framework AVFoundation")

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
endif()

target_link_libraries(factoria_player PRIVATE fa_runtime fa_warnings)
