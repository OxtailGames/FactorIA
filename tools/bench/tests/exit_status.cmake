# fa_bench's exit status must not depend on how the numbers are printed: a comparison that fails exits 1 with --json as
# well. A baseline file that does not exist leaves every benchmark without a baseline entry, which --require-baseline
# turns into a failure. Run by ctest as `bench_exit_status`: cmake -DBENCH=<fa_bench> -DWORK=<dir> -P exit_status.cmake
foreach(extra "" "--json")
    execute_process(
        COMMAND ${BENCH} --filter ecs.spawn_destroy --repeats 1 --warmup 0 --retries 0 ${extra}
                --compare --baseline ${WORK}/missing-baseline.json --require-baseline
        RESULT_VARIABLE status OUTPUT_QUIET ERROR_QUIET)
    if(NOT status EQUAL 1)
        message(FATAL_ERROR "fa_bench ${extra} --compare --require-baseline with no baseline exited with '${status}', expected 1")
    endif()
endforeach()
# Without --require-baseline the same comparison passes, with and without --json.
foreach(extra "" "--json")
    execute_process(
        COMMAND ${BENCH} --filter ecs.spawn_destroy --repeats 1 --warmup 0 --retries 0 ${extra}
                --compare --baseline ${WORK}/missing-baseline.json
        RESULT_VARIABLE status OUTPUT_QUIET ERROR_QUIET)
    if(NOT status EQUAL 0)
        message(FATAL_ERROR "fa_bench ${extra} --compare with no baseline exited with '${status}', expected 0")
    endif()
endforeach()
