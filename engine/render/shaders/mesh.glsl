// The engine's mesh programs: the template (mesh_common.glsl) with the default snippet, an empty surface(). A custom
// material's generated top file has this very shape with its own fa_user block, so a material whose surface() is empty
// renders exactly what a plain MeshRenderer does.
@module mesh

@block fa_user
void surface(in SurfaceInput i, inout Surface s) {}
// The engine's own program reads the lightmap UV attribute of every mesh (mesh_common.glsl, fa_extra_attrs).
#define FA_LM_BUILTIN
@end

@include mesh_common.glsl

@program mesh vs fs
@program mesh_skin vs_skin fs
// The subsurface variants (M73.5): the diffuse light and the scatter parameters in two targets, drawn by renderer_subsurface.cpp.
@program mesh_sss vs fs_sss
@program mesh_skin_sss vs_skin fs_sss
// The LOD cross-fade variants (M75.1): the only programs with the dither's discard, used by the draws that fade (renderer_draw.cpp).
@program mesh_lod vs fs_lod
@program mesh_skin_lod vs_skin fs_lod
@program shadow shadow_vs shadow_fs
@program shadow_skin shadow_vs_skin shadow_fs
@program prepass prepass_vs prepass_fs
@program prepass_skin prepass_vs_skin prepass_fs
@program prepass_lod prepass_vs prepass_fs_lod
@program prepass_skin_lod prepass_vs_skin prepass_fs_lod
