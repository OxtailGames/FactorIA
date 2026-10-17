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
set(CMAKE_FIND_ROOT_PATH /usr/${FA_MINGW_PREFIX})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
# Ship self-contained executables and DLLs (plugins, test mocks): no libstdc++/libgcc/winpthread DLLs needed.
set(CMAKE_EXE_LINKER_FLAGS_INIT "-static -static-libgcc -static-libstdc++")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "${CMAKE_EXE_LINKER_FLAGS_INIT}")
set(CMAKE_MODULE_LINKER_FLAGS_INIT "${CMAKE_EXE_LINKER_FLAGS_INIT}")
