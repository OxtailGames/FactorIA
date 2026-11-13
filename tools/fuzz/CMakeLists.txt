# Fuzz targets (docs/BUILDING.md, "Fuzzing"; tools/fuzz/README.md). cmake/FactoriaFuzz.cmake has fa_add_fuzz_target.
#
# To add a target: tools/fuzz/targets/<name>.cpp with `extern "C" int LLVMFuzzerTestOneInput(const uint8_t*, size_t)`,
# a few small seed files in tools/fuzz/corpus/<name>/, and one line below.

fa_add_fuzz_target(json DEPS fa_core)
fa_add_fuzz_target(json_schema DEPS fa_core)
fa_add_fuzz_target(pak DEPS fa_core)
fa_add_fuzz_target(scene DEPS fa_scene)
fa_add_fuzz_target(prefab DEPS fa_scene)
if(TARGET fa_mcp)  # the developer tools (not on mobile or web)
    fa_add_fuzz_target(mcp_jsonrpc DEPS fa_mcp)
    fa_add_fuzz_target(translations DEPS fa_tooling)
endif()
