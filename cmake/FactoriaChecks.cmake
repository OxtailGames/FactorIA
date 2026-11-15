
# fa_check_not_linked(<target> <library>)
#   Fails the configure when <target> links <library>, directly or through any library it links (the chain is in the message).
#   Does nothing when either target does not exist in this build. The player must not link fa_authoring: its commands are for
#   developer tools, and a game that carried them would offer a script commands the player is not meant to have (root
#   CMakeLists.txt calls this after every subdirectory is added).
function(fa_check_not_linked target forbidden)
    if(NOT TARGET ${target} OR NOT TARGET ${forbidden})
        return()
    endif()
    set(todo ${target})
    set(seen "")
    set(via_${target} "${target}")
    while(todo)
        list(POP_FRONT todo current)
        if(current IN_LIST seen)
            continue()
        endif()
        list(APPEND seen ${current})
        get_target_property(type ${current} TYPE)
        set(props INTERFACE_LINK_LIBRARIES)
        if(NOT type STREQUAL "INTERFACE_LIBRARY")
            list(APPEND props LINK_LIBRARIES)
        endif()
        foreach(prop IN LISTS props)
            get_target_property(libs ${current} ${prop})
            if(NOT libs)
                continue()
            endif()
            foreach(entry IN LISTS libs)
                # An entry is a target name or a generator expression around one ($<LINK_ONLY:x> for a static library's
                # private dependency, $<$<CONFIG:Release>:x>, $<BUILD_INTERFACE:x>...): look at every name inside it.
                string(REGEX MATCHALL "[A-Za-z0-9_.+-]+(::[A-Za-z0-9_.+-]+)*" names "${entry}")
                foreach(lib IN LISTS names)
                    if(lib STREQUAL forbidden)
                        message(FATAL_ERROR "${target} links ${forbidden} (${via_${current}} -> ${forbidden}). ${forbidden} "
                            "holds commands for developer tools only; the player must not carry them. Link the module that "
                            "needs it from tools/, never from engine/ or player/.")
                    endif()
                    if(TARGET ${lib} AND NOT lib IN_LIST seen)
                        set(via_${lib} "${via_${current}} -> ${lib}")
                        list(APPEND todo ${lib})
                    endif()
                endforeach()
            endforeach()
        endforeach()
    endwhile()
endfunction()
