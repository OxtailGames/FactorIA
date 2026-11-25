# fa_shader_pack: the host tool tools/shaders/compile_shaders.sh runs on the generated shader headers to replace their GLSL
# text arrays by zstd frames made with the engine's own encoder (engine/core/src/zstd_encode.cpp). It is its own small
# project, not part of the engine build: it compiles the codec sources of fa_core and nothing else, so it needs a C++20
# compiler and cmake and no installed program. compile_shaders.sh configures and builds it under .cache/shader-pack.
cmake_minimum_required(VERSION 3.20)
project(fa_shader_pack CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release)
endif()
get_filename_component(FA_ROOT ${CMAKE_CURRENT_LIST_DIR}/../../.. ABSOLUTE)
set(CORE ${FA_ROOT}/engine/core)
add_executable(fa_shader_pack shader_pack.cpp
    ${CORE}/src/compress_blocks.cpp ${CORE}/src/lz4_codec.cpp ${CORE}/src/zstd_decode.cpp ${CORE}/src/zstd_encode.cpp
    ${CORE}/src/gdeflate_codec.cpp ${CORE}/src/xxh64.cpp ${CORE}/src/strings.cpp)
target_include_directories(fa_shader_pack PRIVATE ${CORE}/include ${CORE}/src ${FA_ROOT}/engine/render/src)
