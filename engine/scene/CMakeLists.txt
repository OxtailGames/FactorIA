fa_add_module(scene DEPS fa_core PRIVATE_DEPS fa_ext_cgltf)

# Third-party implementation TU (cgltf): no warnings.
if(MSVC)
    set_source_files_properties(src/cgltf_impl.cpp PROPERTIES COMPILE_OPTIONS "/w")
else()
    set_source_files_properties(src/cgltf_impl.cpp PROPERTIES COMPILE_OPTIONS "-w")
endif()

fa_add_tests(scene)
