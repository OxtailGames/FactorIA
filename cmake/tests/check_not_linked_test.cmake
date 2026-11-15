# Test of fa_check_not_linked (cmake/FactoriaHelpers.cmake): `cmake -DFA_ROOT=<repo> -DWORK=<dir> -P check_not_linked_test.cmake`.
# Configures cmake/tests/not_linked once per way a target can reach a forbidden library: the configure must fail with the
# message (naming the chain) for every way, and pass when the library is not reached.
if(NOT FA_ROOT OR NOT WORK)
    message(FATAL_ERROR "usage: cmake -DFA_ROOT=<repo> -DWORK=<scratch dir> -P check_not_linked_test.cmake")
endif()
set(problems "")
foreach(style none direct indirect link_only config)
    set(dir "${WORK}/${style}")
    file(REMOVE_RECURSE "${dir}")
    execute_process(
        COMMAND "${CMAKE_COMMAND}" -S "${FA_ROOT}/cmake/tests/not_linked" -B "${dir}" -DFA_ROOT=${FA_ROOT} -DLINK_STYLE=${style}
        RESULT_VARIABLE result OUTPUT_VARIABLE out ERROR_VARIABLE err)
    if(style STREQUAL "none")
        if(NOT result EQUAL 0)
            string(APPEND problems "\n  ${style}: the configure failed but nothing reaches the library:\n${out}${err}")
        endif()
    elseif(result EQUAL 0)
        string(APPEND problems "\n  ${style}: the configure passed although player reaches forbidden")
    elseif(NOT err MATCHES "player links forbidden")
        string(APPEND problems "\n  ${style}: the configure failed without the expected message:\n${err}")
    endif()
endforeach()
if(problems)
    message(FATAL_ERROR "fa_check_not_linked:${problems}")
endif()
message(STATUS "fa_check_not_linked ok")
