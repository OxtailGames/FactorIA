# Cross-compile for Windows x64 from Linux with MinGW-w64 (posix threads).
# Used by scripts/ci-local.sh to check the Windows code paths (D3D11, Win32
# process/file APIs) without a Windows machine. MSVC-specific issues still need
# a real Visual Studio build (scripts/build.ps1).
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)
set(FA_MINGW_PREFIX x86_64-w64-mingw32)
find_program(CMAKE_C_COMPILER NAMES ${FA_MINGW_PREFIX}-gcc-posix ${FA_MINGW_PREFIX}-gcc REQUIRED)
find_program(CMAKE_CXX_COMPILER NAMES ${FA_MINGW_PREFIX}-g++-posix ${FA_MINGW_PREFIX}-g++ REQUIRED)
find_program(CMAKE_RC_COMPILER NAMES ${FA_MINGW_PREFIX}-windres)
# Debian/Ubuntu put the target root in /usr/<prefix>; Homebrew (macOS) next to the compiler, in
# <cellar>/toolchain-x86_64/<prefix>.
get_filename_component(FA_MINGW_BIN "${CMAKE_CXX_COMPILER}" REALPATH)
get_filename_component(FA_MINGW_BIN "${FA_MINGW_BIN}" DIRECTORY)
if(EXISTS "${FA_MINGW_BIN}/../${FA_MINGW_PREFIX}/include/windows.h")
    get_filename_component(FA_MINGW_ROOT "${FA_MINGW_BIN}/../${FA_MINGW_PREFIX}" ABSOLUTE)
else()
    set(FA_MINGW_ROOT /usr/${FA_MINGW_PREFIX})
endif()
set(CMAKE_FIND_ROOT_PATH "${FA_MINGW_ROOT}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
# Ship self-contained executables and DLLs (plugins, test mocks): no libstdc++/libgcc/winpthread DLLs needed.
set(CMAKE_EXE_LINKER_FLAGS_INIT "-static -static-libgcc -static-libstdc++")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "${CMAKE_EXE_LINKER_FLAGS_INIT}")
