fa_add_module(scene DEPS fa_core PRIVATE_DEPS fa_ext_cgltf fa_ext_manifold fa_ext_meshoptimizer fa_ext_vhacd)

# The cgltf implementation translation unit (glTF reading for skeleton.cpp, mesh_geometry.cpp and the renderer's loader): no warnings.
if(MSVC)
    set_source_files_properties(src/cgltf_impl.cpp PROPERTIES COMPILE_OPTIONS "/w")
else()
    set_source_files_properties(src/cgltf_impl.cpp PROPERTIES COMPILE_OPTIONS "-w")
endif()

# The V-HACD implementation translation unit (the library is one header): no warnings.
if(MSVC)
    set_source_files_properties(src/vhacd_impl.cpp PROPERTIES COMPILE_OPTIONS "/w;/bigobj")
else()
    set_source_files_properties(src/vhacd_impl.cpp PROPERTIES COMPILE_OPTIONS "-w")
endif()

fa_add_tests(scene)
