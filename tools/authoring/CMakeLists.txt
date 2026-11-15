# fa_authoring: the commands that only developer tools use (the factoria CLI, the editor, the MCP/DAP/AI servers): the ones that
# write scene and prefab files, import assets, edit animations, ... They are not in fa_runtime, so an exported game's player does
# not carry them. fa_tooling links this library PUBLIC; a program calls fa::authoring::install() at start-up and every Engine it
# creates afterwards has them (fa/authoring/authoring.h). The root CMakeLists.txt fails the configure when the player links it.
fa_add_module(authoring DEPS fa_runtime)
fa_add_tests(authoring)
if(TARGET fa_test_authoring)
    # confinement_variants.h is shared with the runtime tests: included by name, not by a relative path.
    target_include_directories(fa_test_authoring PRIVATE ${FA_ROOT}/engine/runtime/tests)
endif()
