# The feedback server (Cloudflare Worker + D1) is JavaScript with no build step. Its tests run with Node's own test
# runner (`node --test`, no framework); ctest runs them when Node.js 20 or newer is found and skips them quietly when
# it is not, so a C++-only machine needs nothing installed.
if(FA_BUILD_TESTS)
    find_program(FA_NODE_EXECUTABLE node)
    set(_fa_node_ok FALSE)
    if(FA_NODE_EXECUTABLE)
        execute_process(COMMAND ${FA_NODE_EXECUTABLE} -p "process.versions.node.split('.')[0]"
            OUTPUT_VARIABLE _fa_node_major OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET RESULT_VARIABLE _fa_node_rc)
        if(_fa_node_rc EQUAL 0 AND _fa_node_major GREATER_EQUAL 20)
            set(_fa_node_ok TRUE)
        endif()
    endif()
    if(_fa_node_ok)
        file(GLOB _fa_feedback_server_tests CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/test/*.test.js)
        add_test(NAME feedback_server
            COMMAND ${FA_NODE_EXECUTABLE} --test ${_fa_feedback_server_tests}
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
        set_tests_properties(feedback_server PROPERTIES TIMEOUT 120)
    else()
        message(STATUS "FactorIA: Node.js 20+ not found, the feedback server tests (tools/feedback-server) are skipped")
    endif()
endif()
