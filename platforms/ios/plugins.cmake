# Native plugins in the iOS app (docs/MOBILE.md, "Native plugins (iOS)"), shared by two builds of the app:
#   - player/CMakeLists.txt (the app built from the engine source), and
#   - the project that `factoria export --platform ios` writes in prebuilt mode (cmake/plugins.cmake next to it).
# An iOS plugin is a static library per SDK. `factoria export` copies each plugin's ios/ folder to <export>/plugins/<name>/
# and build_ios.sh passes:
#   FA_GAME_PLUGINS     the plugins' names (a list)
#   FA_GAME_PLUGIN_DIR  the folder that holds <name>/<iphoneos|iphonesimulator>/lib<name>.a
# and, from the plugins' manifests (<plugin>/ios/plugin.json, fa/tooling/plugin_manifest.h), merged over all plugins:
#   FA_GAME_PLUGIN_FRAMEWORKS  the system frameworks their code uses (a list: StoreKit;GameKit); a static library cannot link them
#   FA_GAME_PLUGIN_SWIFT       ON when a plugin is written in Swift: the app is given the Swift runtime
#   FA_GAME_PLUGIN_XCFRAMEWORKS        the vendored XCFrameworks ("admob/frameworks/GoogleMobileAds.xcframework", relative to
#                                      FA_GAME_PLUGIN_DIR): the slice of the SDK is linked into the app
#   FA_GAME_PLUGIN_EMBED_XCFRAMEWORKS  those that are dynamic: also embedded and signed in the app (a static one is not)
#   FA_GAME_LOCALIZED_STRINGS          a folder of <language>.lproj/InfoPlist.strings (the translated "Allow tracking" text)
#   FA_GAME_ENTITLEMENTS       the .entitlements file the app is signed with (Game Center, iCloud, ...)
#   FA_GAME_STOREKIT           ON when build_ios.sh will wire a StoreKit configuration into the scheme (platforms/ios/storekit_scheme.cmake):
#                              the scheme has to exist as a file for that, and CMake writes none unless asked
set(FA_GAME_PLUGINS "" CACHE STRING "Names of the game's native plugins (a list)")
set(FA_GAME_PLUGIN_DIR "" CACHE PATH "Folder with <name>/<iphoneos|iphonesimulator>/lib<name>.a for each plugin")
set(FA_GAME_PLUGIN_FRAMEWORKS "" CACHE STRING "System frameworks the plugins use (a list), linked into the app")
set(FA_GAME_PLUGIN_SWIFT OFF CACHE BOOL "A plugin is written in Swift: link the Swift runtime into the app")
set(FA_GAME_PLUGIN_XCFRAMEWORKS "" CACHE STRING "XCFrameworks of the plugins (a list, relative to FA_GAME_PLUGIN_DIR), linked into the app")
set(FA_GAME_PLUGIN_EMBED_XCFRAMEWORKS "" CACHE STRING "The dynamic ones among them, also embedded in the app")
set(FA_GAME_LOCALIZED_STRINGS "" CACHE PATH "Folder with <language>.lproj/InfoPlist.strings, the translated Info.plist texts")
set(FA_GAME_ENTITLEMENTS "" CACHE FILEPATH "The .entitlements file the app is signed with (the plugins' capabilities)")
set(FA_GAME_STOREKIT OFF CACHE BOOL "Write the Xcode scheme as a file, for storekit_scheme.cmake to add a StoreKit configuration to")

# fa_ios_link_plugins(<app target>): links each plugin's library of the SDK this configure builds for into the app and adds
# a source to it that registers the plugins' entry points (fa_plugin_init_<name>) with the engine before main. The source
# is part of the app, not of an archive, so the linker keeps it.
function(fa_ios_link_plugins app)
    if("${FA_GAME_PLUGINS}" STREQUAL "")  # not if(NOT FA_GAME_PLUGINS): a plugin named "n" or "off" would count as false
        return()
    endif()
    string(TOLOWER "${CMAKE_OSX_SYSROOT}" sdk)
    if(sdk MATCHES "simulator")
        set(slice iphonesimulator)
    else()
        set(slice iphoneos)
    endif()
    set(declarations "")
    set(registrations "")
    foreach(name IN LISTS FA_GAME_PLUGINS)
        set(library "${FA_GAME_PLUGIN_DIR}/${name}/${slice}/lib${name}.a")
        if(NOT EXISTS "${library}")
            message(FATAL_ERROR "The plugin '${name}' has no ${library}. FA_GAME_PLUGIN_DIR is '${FA_GAME_PLUGIN_DIR}'. "
                "Build the plugin for ${slice} (its README.md has the commands) and export the game again with "
                "`factoria export --platform ios`, which copies the plugin's ios/ folder to <export>/plugins/${name}.")
        endif()
        target_link_libraries(${app} PRIVATE "${library}")
        string(APPEND declarations "extern \"C\" int fa_plugin_init_${name}(const FaPluginApi*);\n")
        string(APPEND registrations "        fa_register_static_plugin(\"${name}\", fa_plugin_init_${name});\n")
    endforeach()
    foreach(framework IN LISTS FA_GAME_PLUGIN_FRAMEWORKS)
        target_link_libraries(${app} PRIVATE "-framework ${framework}")
    endforeach()
    # Vendored XCFrameworks: the slice of this SDK is linked (a static one is copied into the executable; -ObjC loads the
    # Objective-C classes and categories of a static archive that nothing references by name), and the dynamic ones are also
    # embedded in the app (Frameworks/) and signed with it.
    set(embedded "")
    foreach(xcframework IN LISTS FA_GAME_PLUGIN_XCFRAMEWORKS)
        set(xcframework_path "${FA_GAME_PLUGIN_DIR}/${xcframework}")
        if(NOT IS_DIRECTORY "${xcframework_path}")
            message(FATAL_ERROR "The XCFramework '${xcframework_path}' does not exist. FA_GAME_PLUGIN_DIR is '${FA_GAME_PLUGIN_DIR}'. "
                "Export the game again with `factoria export --platform ios`, which copies the plugin's ios/ folder (frameworks included) "
                "to <export>/plugins/<name>.")
        endif()
        file(GLOB slices LIST_DIRECTORIES true "${xcframework_path}/ios-*")
        set(slice_path "")
        foreach(candidate IN LISTS slices)
            get_filename_component(candidate_name "${candidate}" NAME)
            if(NOT IS_DIRECTORY "${candidate}" OR candidate_name MATCHES "-maccatalyst$")
                continue()
            endif()
            if(candidate_name MATCHES "-simulator$")
                set(candidate_simulator ON)
            else()
                set(candidate_simulator OFF)
            endif()
            if(slice STREQUAL "iphonesimulator")
                set(wants_simulator ON)
            else()
                set(wants_simulator OFF)
            endif()
            if((candidate_simulator AND wants_simulator) OR (NOT candidate_simulator AND NOT wants_simulator))
                set(slice_path "${candidate}")
                break()
            endif()
        endforeach()
        if(slice_path STREQUAL "")
            message(FATAL_ERROR "${xcframework_path} has no slice for ${slice}. Download the iOS XCFramework again: its ios-arm64 "
                "slice is for the iPhone (iphoneos) and ios-arm64_x86_64-simulator for the simulator (iphonesimulator).")
        endif()
        file(GLOB frameworks LIST_DIRECTORIES true "${slice_path}/*.framework")
        file(GLOB archives "${slice_path}/lib*.a")
        if(frameworks)
            list(GET frameworks 0 framework_path)
            get_filename_component(framework_name "${framework_path}" NAME_WE)
            target_link_libraries(${app} PRIVATE "-F${slice_path}" "-framework ${framework_name}")
            list(FIND FA_GAME_PLUGIN_EMBED_XCFRAMEWORKS "${xcframework}" embed_index)
            if(NOT embed_index EQUAL -1)
                list(APPEND embedded "${framework_path}")
            endif()
        elseif(archives)
            list(GET archives 0 archive_path)
            target_link_libraries(${app} PRIVATE "${archive_path}")
        else()
            message(FATAL_ERROR "${slice_path} holds no .framework and no lib*.a. Download the iOS XCFramework again.")
        endif()
    endforeach()
    if(FA_GAME_PLUGIN_XCFRAMEWORKS)
        target_link_options(${app} PRIVATE "-ObjC")
    endif()
    if(embedded)
        set_target_properties(${app} PROPERTIES XCODE_EMBED_FRAMEWORKS "${embedded}" XCODE_EMBED_FRAMEWORKS_CODE_SIGN_ON_COPY ON)
        target_link_options(${app} PRIVATE "-Wl,-rpath,@executable_path/Frameworks")
    endif()
    # The texts of the Info.plist that the game translates (<language>.lproj/InfoPlist.strings, which `factoria export` writes
    # into FA_GAME_LOCALIZED_STRINGS): each goes to its <language>.lproj folder of the app.
    if(FA_GAME_LOCALIZED_STRINGS)
        file(GLOB localized_strings "${FA_GAME_LOCALIZED_STRINGS}/*.lproj/InfoPlist.strings")
        foreach(strings_file IN LISTS localized_strings)
            target_sources(${app} PRIVATE "${strings_file}")
            set_source_files_properties("${strings_file}" PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
        endforeach()
    endif()
    if(FA_GAME_PLUGIN_SWIFT)
        # What Xcode adds to a target with Swift code: the Swift runtime lives in the OS (/usr/lib/swift, found through
        # the rpath), and the back-deployment libraries a Swift static library asks for are in the toolchain. Without an
        # .swift source in the app, Xcode would not add them, and the link fails with "library 'swiftCompatibility56'
        # not found". $(TOOLCHAIN_DIR) and $(PLATFORM_NAME) are build settings: Xcode expands them for the SDK it builds.
        target_link_options(${app} PRIVATE "-L$(TOOLCHAIN_DIR)/usr/lib/swift/$(PLATFORM_NAME)" "-L/usr/lib/swift"
                            "-Wl,-rpath,/usr/lib/swift")
    endif()
    if(FA_GAME_ENTITLEMENTS)
        if(NOT EXISTS "${FA_GAME_ENTITLEMENTS}")
            message(FATAL_ERROR "FA_GAME_ENTITLEMENTS='${FA_GAME_ENTITLEMENTS}' does not exist. "
                "Export the game again with `factoria export --platform ios` (it writes the entitlements next to build_ios.sh).")
        endif()
        set_target_properties(${app} PROPERTIES XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS "${FA_GAME_ENTITLEMENTS}")
    endif()
    if(FA_GAME_STOREKIT)
        set_target_properties(${app} PROPERTIES XCODE_GENERATE_SCHEME ON)
    endif()
    file(CONFIGURE OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/plugins.cpp CONTENT
"// Generated by platforms/ios/plugins.cmake: registers the game's native plugins before main (fa/runtime/plugins.h).
struct FaPluginApi;
extern \"C\" void fa_register_static_plugin(const char* name, int (*init)(const FaPluginApi*));
@declarations@
namespace {
struct RegisterPlugins {
    RegisterPlugins() {
@registrations@    }
} registerPlugins;
}  // namespace
" @ONLY)
    target_sources(${app} PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/plugins.cpp)
endfunction()
