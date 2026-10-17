fa_add_module(core
    DEPS fa_ext_json
    PRIVATE_DEPS fa_ext_stb)
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
