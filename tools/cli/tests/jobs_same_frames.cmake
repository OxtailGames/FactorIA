# The render passes and animation poses run as jobs (docs/ARCHITECTURE.md, "Systems that run as jobs"): an example game
# must draw the same picture whatever the thread count. Captures each scene after the same frames with
# FA_JOB_THREADS=inline (every pass one chunk on the main thread) and with 8 workers (the big passes split into chunks)
# and compares the PNG files byte for byte.
#   cmake -DFACTORIA=<factoria> -DROOT=<repo> -DOUT=<dir> -DSCENES=example=scene,example=scene -P jobs_same_frames.cmake
string(REPLACE "," ";" scenes "${SCENES}")
foreach(entry ${scenes})
    string(REPLACE "=" ";" parts "${entry}")
    list(GET parts 0 ex)
    list(GET parts 1 scene)
    string(MAKE_C_IDENTIFIER "${ex}_${scene}" tag)
    foreach(threads inline 8)
        set(ENV{FA_JOB_THREADS} ${threads})
        execute_process(COMMAND ${FACTORIA} screenshot ${ROOT}/examples/${ex} --scene ${scene} --frames 90
                                --out ${OUT}/${tag}_${threads}.png
                        RESULT_VARIABLE rc OUTPUT_VARIABLE out ERROR_VARIABLE err)
        if(NOT rc EQUAL 0)
            message(FATAL_ERROR "factoria screenshot ${ex} ${scene} with FA_JOB_THREADS=${threads} failed (${rc}):\n${out}\n${err}")
        endif()
    endforeach()
    execute_process(COMMAND ${CMAKE_COMMAND} -E compare_files ${OUT}/${tag}_inline.png ${OUT}/${tag}_8.png RESULT_VARIABLE same)
    if(NOT same EQUAL 0)
        message(FATAL_ERROR "${ex} ${scene}: the frame drawn with 8 job threads differs from the one drawn inline "
                            "(${OUT}/${tag}_inline.png, ${OUT}/${tag}_8.png): a render or animation job depends on the threads")
    endif()
    message(STATUS "${ex} ${scene}: the same frame inline and with 8 job threads")
endforeach()
