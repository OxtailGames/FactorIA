# The check of a doctest executable that CMake split into several ctest entries with --fa-files / --fa-files-exclude
# (cmake/doctest_main.cpp): the entries together list exactly the test cases the whole executable lists, each once. Plain
# CMake, so it runs under any `ctest` on every platform (no Python).
#
#   cmake -DFA_TEST_EXE=<executable> "-DFA_SPLIT_ENTRIES=<arg>|<arg>|..." -P fa_doctest_split_check.cmake
#
# Every <arg> is the command-line argument of one entry (for example --fa-files=a_test.cpp,b_test.cpp). It fails when a test case
# is in no entry, in two, or when an entry lists a test case the executable does not have.

if(NOT FA_TEST_EXE OR NOT FA_SPLIT_ENTRIES)
    message(FATAL_ERROR "fa_doctest_split_check.cmake: pass -DFA_TEST_EXE=<test executable> and \"-DFA_SPLIT_ENTRIES=<arg>|<arg>|...\"")
endif()

# The test case names of `<exe> <args> --list-test-cases`, one list element each, sorted. A name with ';', '[' or ']' would break a
# CMake list, so those characters are replaced by words on every side alike.
function(fa_listed_test_cases out)
    execute_process(COMMAND ${FA_TEST_EXE} ${ARGN} --list-test-cases
        RESULT_VARIABLE code OUTPUT_VARIABLE text ERROR_VARIABLE errors)
    if(NOT code EQUAL 0)
        message(FATAL_ERROR "'${FA_TEST_EXE} ${ARGN} --list-test-cases' exited with ${code}:\n${text}\n${errors}")
    endif()
    string(REPLACE "\r" "" text "${text}")
    string(REPLACE ";" "<semicolon>" text "${text}")
    string(REPLACE "[" "<lbracket>" text "${text}")
    string(REPLACE "]" "<rbracket>" text "${text}")
    string(REPLACE "\n" ";" lines "${text}")
    list(FILTER lines EXCLUDE REGEX "^(<lbracket>doctest<rbracket>|=====|$)")
    list(SORT lines)
    set(${out} "${lines}" PARENT_SCOPE)
endfunction()

fa_listed_test_cases(whole)
list(LENGTH whole whole_count)
if(whole_count EQUAL 0)
    message(FATAL_ERROR "${FA_TEST_EXE} --list-test-cases listed no test case: the check has nothing to compare.")
endif()

string(REPLACE "|" ";" entries "${FA_SPLIT_ENTRIES}")
set(together "")
set(number 0)
foreach(entry IN LISTS entries)
    math(EXPR number "${number} + 1")
    fa_listed_test_cases(part "${entry}")
    list(LENGTH part part_count)
    message(STATUS "entry ${number} (${entry}): ${part_count} test cases")
    if(part_count EQUAL 0)
        message(FATAL_ERROR "The entry ${number} (${entry}) runs no test case: its file names match no test case. "
            "Fix the file names in tools/common/CMakeLists.txt.")
    endif()
    list(APPEND together ${part})
endforeach()
list(SORT together)
list(LENGTH together together_count)
message(STATUS "together ${together_count} test cases; the whole executable ${whole_count}")

if(NOT "${together}" STREQUAL "${whole}")
    # Walk both sorted lists and name the first differences.
    set(report "")
    set(shown 0)
    set(i 0)
    set(j 0)
    while((i LESS whole_count OR j LESS together_count) AND shown LESS 8)
        set(a "")
        set(b "")
        if(i LESS whole_count)
            list(GET whole ${i} a)
        endif()
        if(j LESS together_count)
            list(GET together ${j} b)
        endif()
        if(i LESS whole_count AND j LESS together_count AND "${a}" STREQUAL "${b}")
            math(EXPR i "${i} + 1")
            math(EXPR j "${j} + 1")
        elseif(j GREATER_EQUAL together_count OR (i LESS whole_count AND "${a}" STRLESS "${b}"))
            string(APPEND report "  runs in no entry: ${a}\n")
            math(EXPR i "${i} + 1")
            math(EXPR shown "${shown} + 1")
        else()
            string(APPEND report "  runs in more entries than it exists: ${b}\n")
            math(EXPR j "${j} + 1")
            math(EXPR shown "${shown} + 1")
        endif()
    endwhile()
    # The names as doctest printed them.
    string(REPLACE "<semicolon>" ";" report "${report}")
    string(REPLACE "<lbracket>" "[" report "${report}")
    string(REPLACE "<rbracket>" "]" report "${report}")
    message(FATAL_ERROR "The ctest entries do not run what ${FA_TEST_EXE} runs: ${together_count} test cases in the entries, "
        "${whole_count} in the executable. First differences:\n${report}"
        "Every test file must be in exactly one entry: fix the lists in tools/common/CMakeLists.txt.")
endif()
message(STATUS "ok: every one of the ${whole_count} test cases runs in exactly one entry")
