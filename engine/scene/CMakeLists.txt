fa_add_module(scene DEPS fa_core PRIVATE_DEPS fa_ext_cgltf fa_ext_manifold fa_ext_xatlas fa_ext_meshoptimizer fa_ext_vhacd)

# The cgltf implementation translation unit (glTF reading for skeleton.cpp, mesh_geometry.cpp and the renderer's loader): no warnings.
if(MSVC)
    set_source_files_properties(src/cgltf_impl.cpp PROPERTIES COMPILE_OPTIONS "/w")
else()
    set_source_files_properties(src/cgltf_impl.cpp PROPERTIES COMPILE_OPTIONS "-w")
endif()

# V-HACD gives a different decomposition on each standard library: it keeps its hulls in an std::unordered_map (libc++,
# libstdc++ and MSVC iterate it in different orders, and that order decides which merge costs are queued first) and its
# priority queue of hull pairs has no tie-break. external/ stays untouched: configure writes a copy of the header with those two
# spots made deterministic (an ordered map, ties broken by hull ids) as vhacd_deterministic.h, which the engine includes instead.
set(_fa_vhacd_src "${CMAKE_CURRENT_SOURCE_DIR}/../../external/vhacd/include/VHACD.h")
set(_fa_vhacd_out "${CMAKE_CURRENT_BINARY_DIR}/vhacd/vhacd_deterministic.h")
set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${_fa_vhacd_src}")
file(READ "${_fa_vhacd_src}" _fa_vhacd)
function(_fa_vhacd_patch from to)
    string(FIND "${_fa_vhacd}" "${from}" _at)
    if(_at EQUAL -1)
        message(FATAL_ERROR "engine/scene/CMakeLists.txt: the V-HACD header no longer contains \"${from}\". "
                            "external/vhacd was updated: check that the new version still needs this patch and adapt it.")
    endif()
    string(REPLACE "${from}" "${to}" _fa_vhacd "${_fa_vhacd}")
    set(_fa_vhacd "${_fa_vhacd}" PARENT_SCOPE)
endfunction()
_fa_vhacd_patch("#include <list>\n" "#include <list>\n#include <map>\n")
_fa_vhacd_patch("std::unordered_map<uint32_t, IVHACD::ConvexHull*>   m_hulls;"
                "std::map<uint32_t, IVHACD::ConvexHull*>             m_hulls;")
_fa_vhacd_patch("    return m_concavity > h.m_concavity ? true : false;"
                "    if (m_concavity != h.m_concavity) return m_concavity > h.m_concavity;\n    if (m_hullA != h.m_hullA) return m_hullA > h.m_hullA;\n    return m_hullB > h.m_hullB;")
file(WRITE "${_fa_vhacd_out}.tmp" "${_fa_vhacd}")
configure_file("${_fa_vhacd_out}.tmp" "${_fa_vhacd_out}" COPYONLY)  # rewritten only when it changes: no rebuild per configure
target_include_directories(fa_scene PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/vhacd")

# The V-HACD implementation translation unit (the library is one header): no warnings.
if(MSVC)
    set_source_files_properties(src/vhacd_impl.cpp PROPERTIES COMPILE_OPTIONS "/w;/bigobj")
else()
    set_source_files_properties(src/vhacd_impl.cpp PROPERTIES COMPILE_OPTIONS "-w")
endif()

fa_add_tests(scene)

# The particle and feel replay hashes (tests/test_det_replay.cpp) run ONLY here, so CI can print them: `ctest -R det_replay_hashes
# -V`. The cases are marked doctest::skip() so the `scene` test above does not run them a second time; --no-skip runs them.
if(TARGET fa_test_scene)
    add_test(NAME det_replay_hashes COMMAND fa_test_scene --no-skip "-tc=det replay*" WORKING_DIRECTORY ${FA_ROOT})
endif()
