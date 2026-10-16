# The {{NAME}} native plugin of a FactorIA game (docs/EXTENDING.md, "Native plugins"). Build it for this computer:
#
#   cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
#   cmake --build build --config Release
#
# The build is copied into this folder, where `factoria run` and `factoria export` find it: windows/{{NAME}}.dll,
# macos/lib{{NAME}}.dylib or linux/lib{{NAME}}.so. Libraries the plugin needs go next to it, in the same folder.
#
# For iOS the plugin is a static library, one per SDK, built with the Xcode generator and copied to
# ios/iphoneos/lib{{NAME}}.a and ios/iphonesimulator/lib{{NAME}}.a (README.md has the commands).
cmake_minimum_required(VERSION 3.20)
project({{NAME}} C)

if(IOS)
    add_library({{NAME}} STATIC src/plugin.c)
    target_compile_definitions({{NAME}} PRIVATE FA_PLUGIN_STATIC)  # fa_plugin_init_{{NAME}}: the app registers it
else()
    add_library({{NAME}} SHARED src/plugin.c)
endif()
target_include_directories({{NAME}} PRIVATE include)
target_compile_definitions({{NAME}} PRIVATE FA_PLUGIN_NAME={{NAME}})
set_target_properties({{NAME}} PROPERTIES C_VISIBILITY_PRESET hidden)

if(IOS)
    # The architectures of the player's libraries (release workflow): arm64 on a device, arm64 + x86_64 in the simulator.
    string(TOLOWER "${CMAKE_OSX_SYSROOT}" sdk)
    if(sdk MATCHES "simulator")
        set(platform ios/iphonesimulator)
        set_target_properties({{NAME}} PROPERTIES OSX_ARCHITECTURES "arm64;x86_64")
    else()
        set(platform ios/iphoneos)
        set_target_properties({{NAME}} PROPERTIES OSX_ARCHITECTURES arm64)
    endif()
elseif(WIN32)
    set(platform windows)
    set_target_properties({{NAME}} PROPERTIES PREFIX "")  # {{NAME}}.dll, also with MinGW
elseif(APPLE)
    set(platform macos)
    # Libraries next to the plugin (in macos/, Contents/Frameworks once exported) are found through @loader_path.
    set_target_properties({{NAME}} PROPERTIES INSTALL_RPATH "@loader_path" BUILD_WITH_INSTALL_RPATH ON)
else()
    set(platform linux)
    set_target_properties({{NAME}} PROPERTIES INSTALL_RPATH "$ORIGIN" BUILD_WITH_INSTALL_RPATH ON)
endif()
add_custom_command(TARGET {{NAME}} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_SOURCE_DIR}/${platform}
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:{{NAME}}> ${CMAKE_CURRENT_SOURCE_DIR}/${platform}/)
