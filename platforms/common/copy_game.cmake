# Copies a game project into a build/bundle folder, leaving out files that must not ship.
#   cmake -DSRC=<game dir> -DDST=<dest dir> -P copy_game.cmake
# Keep the exclude list in sync with fa::export_project (tools/common/src/export.cpp).
if(NOT SRC OR NOT DST)
    message(FATAL_ERROR "usage: cmake -DSRC=<game dir> -DDST=<dest> -P copy_game.cmake")
endif()
file(REMOVE_RECURSE "${DST}")
file(COPY "${SRC}/" DESTINATION "${DST}"
    PATTERN ".factoria" EXCLUDE
    PATTERN ".git" EXCLUDE
    PATTERN ".mcp.json" EXCLUDE
    PATTERN "tests" EXCLUDE
    PATTERN "tools" EXCLUDE
    PATTERN "types" EXCLUDE
    PATTERN "ENGINE_FEEDBACK.json" EXCLUDE
    PATTERN "AGENTS.md" EXCLUDE
    PATTERN "CLAUDE.md" EXCLUDE
    PATTERN "jsconfig.json" EXCLUDE
    PATTERN ".DS_Store" EXCLUDE)
