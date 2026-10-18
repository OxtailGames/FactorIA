# fa_platform also owns the single sokol implementation translation unit
# (sokol_impl.c on most platforms, sokol_impl_apple.m on Apple).
fa_add_module(platform
    DEPS fa_core fa_ext_sokol)

# SDL_GameControllerDB (Linux lines) is baked into the binary as text; gamepad_mapping.cpp indexes it on first use
# (namespace fa::gamepad_db, header embedded_gamepad_db.h). Compiled on every OS so the tests cover it everywhere.
fa_embed_files(fa_platform fa::gamepad_db embedded_gamepad_db
    FILES ${FA_ROOT}/external/sdl_gamecontrollerdb/gamecontrollerdb_linux.txt
    BASE ${FA_ROOT}/external/sdl_gamecontrollerdb)

# sokol is third-party code: silence warnings in its implementation TU.
if(MSVC)
    set_source_files_properties(src/sokol_impl.c PROPERTIES COMPILE_OPTIONS "/w")
else()
    set_source_files_properties(src/sokol_impl.c PROPERTIES COMPILE_OPTIONS "-w")
endif()
if(APPLE)
    set_source_files_properties(src/sokol_impl_apple.m PROPERTIES COMPILE_OPTIONS "-fobjc-arc;-w")
    set_source_files_properties(src/headless_apple.mm src/gamepad_apple.mm src/mobile_apple.mm PROPERTIES COMPILE_OPTIONS "-fobjc-arc")
endif()

if(FA_PLATFORM STREQUAL "linux")
    find_package(X11 REQUIRED)
    # GL for the window (GLX via sokol_app), EGL for headless rendering.
    find_package(OpenGL REQUIRED COMPONENTS EGL)
    find_package(ALSA)
    # GLVND's libOpenGL.so.0 is not on every system (the Steam Runtime "sniper" lacks it), libGL.so.1 is:
    # -DOpenGL_GL_PREFERENCE=LEGACY links that one (the linux-sniper preset does).
    if(TARGET OpenGL::OpenGL AND NOT OpenGL_GL_PREFERENCE STREQUAL "LEGACY")
        set(FA_GL_LIB OpenGL::OpenGL OpenGL::GLX)
    else()
        set(FA_GL_LIB OpenGL::GL)
    endif()
    target_link_libraries(fa_platform PUBLIC X11::X11 X11::Xi X11::Xcursor ${FA_GL_LIB} OpenGL::EGL ${CMAKE_DL_LIBS} Threads::Threads)
    if(ALSA_FOUND)
        target_link_libraries(fa_platform PUBLIC ALSA::ALSA)
    else()
        message(WARNING "ALSA not found: audio output disabled (install libasound2-dev)")
        target_compile_definitions(fa_platform PRIVATE FA_NO_AUDIO_DEVICE=1)
    endif()
elseif(FA_PLATFORM STREQUAL "windows")
    target_link_libraries(fa_platform PUBLIC d3d11 dxgi dxguid ole32 user32 gdi32 shell32 kernel32)
elseif(FA_PLATFORM STREQUAL "macos")
    target_link_libraries(fa_platform PUBLIC "-framework Cocoa" "-framework QuartzCore" "-framework Metal"
        "-framework MetalKit" "-framework AudioToolbox" "-framework Foundation" "-framework GameController")
elseif(FA_PLATFORM STREQUAL "ios")
    target_link_libraries(fa_platform PUBLIC "-framework UIKit" "-framework CoreGraphics" "-framework QuartzCore" "-framework Metal"
        "-framework MetalKit" "-framework AudioToolbox" "-framework AVFoundation" "-framework Foundation"
        "-framework GameController")
elseif(FA_PLATFORM STREQUAL "android")
    target_link_libraries(fa_platform PUBLIC GLESv3 EGL android log aaudio)
endif()
fa_add_tests(platform)
