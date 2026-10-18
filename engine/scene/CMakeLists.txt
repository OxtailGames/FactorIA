fa_add_module(scene DEPS fa_core PRIVATE_DEPS fa_ext_cgltf)

# The cgltf implementation translation unit (glTF reading for skeleton.cpp, mesh_geometry.cpp and the renderer's loader): no warnings.
if(MSVC)
    set_source_files_properties(src/cgltf_impl.cpp PROPERTIES COMPILE_OPTIONS "/w")
else()
    set_source_files_properties(src/cgltf_impl.cpp PROPERTIES COMPILE_OPTIONS "-w")
endif()

fa_add_tests(scene)
