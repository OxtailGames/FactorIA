fa_add_module(core
    DEPS fa_ext_json
    PRIVATE_DEPS fa_ext_stb fa_ext_plmpeg)
# The build fingerprint (fa/core/build_info.h): the commit, written to a header at every build; only build_info.cpp includes it.
find_package(Git QUIET)
set(FA_BUILD_FINGERPRINT_DIR ${CMAKE_BINARY_DIR}/generated)
add_custom_target(fa_build_fingerprint
    COMMAND ${CMAKE_COMMAND} -DOUT=${FA_BUILD_FINGERPRINT_DIR}/fa_build_fingerprint.h -DSRC=${FA_ROOT}
            -DGIT=${GIT_EXECUTABLE} -P ${FA_ROOT}/cmake/build_fingerprint.cmake
    BYPRODUCTS ${FA_BUILD_FINGERPRINT_DIR}/fa_build_fingerprint.h
    COMMENT "Build fingerprint" VERBATIM)
add_dependencies(fa_core fa_build_fingerprint)
target_include_directories(fa_core PRIVATE ${FA_BUILD_FINGERPRINT_DIR})
if(FA_PLATFORM STREQUAL "android")
    target_link_libraries(fa_core PRIVATE android log)
endif()
if(WIN32)
    target_link_libraries(fa_core PRIVATE dbghelp)  # crash_win32.cpp: names for the frames of a crash report, minidumps
endif()
fa_add_tests(core)
if(FA_BUILD_TESTS AND TARGET fa_test_core)
    # tests/test_crash.cpp runs this program, which installs the crash reporter and crashes on purpose; ctest hands the
    # test its path (FA_CRASH_CHILD). Its functions are exported so the stack names them without symbol files.
    add_executable(fa_crash_child tests/programs/crash_child.cpp)
    target_link_libraries(fa_crash_child PRIVATE fa_core fa_warnings)
    if(NOT WIN32)
        set_target_properties(fa_crash_child PROPERTIES ENABLE_EXPORTS ON)
    endif()
    add_dependencies(fa_test_core fa_crash_child)
    set_tests_properties(core PROPERTIES ENVIRONMENT "FA_CRASH_CHILD=$<TARGET_FILE:fa_crash_child>")
endif()
