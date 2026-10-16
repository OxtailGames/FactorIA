# The {{NAME}} native plugin of a FactorIA game: the Steamworks backend of the platform API (achievements, stats, leaderboards,
# cloud saves, DLC purchases, overlay, rich presence; docs/PLATFORM.md, "Steam"). Build it for this computer:
#
#   cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
#   cmake --build build --config Release
#
# The build is copied into this folder, where `factoria run` and `factoria export` find it: windows/{{NAME}}.dll,
# macos/lib{{NAME}}.dylib or linux/lib{{NAME}}.so. It needs no Steamworks SDK to build: it loads Valve's redistributable
# (steam_api64.dll, libsteam_api.dylib, libsteam_api.so) at run time from the same folder, so copy that file next to the
# build; `factoria call platform.add_backend '{"backend": "steam", "sdk": "<Steamworks SDK folder>"}'` does it all.
cmake_minimum_required(VERSION 3.20)
project({{NAME}} CXX)

if(IOS OR ANDROID)
    message(FATAL_ERROR "The Steam plugin is for desktop games (Windows, macOS, Linux): Steam does not run on phones.")
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

file(GLOB sources CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)
add_library({{NAME}} SHARED ${sources})
target_include_directories({{NAME}} PRIVATE include)
target_compile_definitions({{NAME}} PRIVATE FA_PLUGIN_NAME={{NAME}})
target_link_libraries({{NAME}} PRIVATE ${CMAKE_DL_LIBS})  # dlopen, to load the Steamworks library
set_target_properties({{NAME}} PROPERTIES CXX_VISIBILITY_PRESET hidden VISIBILITY_INLINES_HIDDEN ON)

if(WIN32)
    set(platform windows)
    set_target_properties({{NAME}} PROPERTIES PREFIX "")  # {{NAME}}.dll, also with MinGW
    if(MSVC)
        # Like the engine: no Visual C++ Redistributable needed on the player's computer.
        set_property(TARGET {{NAME}} PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
        target_compile_options({{NAME}} PRIVATE /utf-8 /W4)
    endif()
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
