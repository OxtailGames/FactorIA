// The engine's mesh programs: the template (mesh_common.glsl) with the default snippet, an empty surface(). A custom
// material's generated top file has this very shape with its own fa_user block, so a material whose surface() is empty
// renders exactly what a plain MeshRenderer does.
@module mesh

@block fa_user
void surface(in SurfaceInput i, inout Surface s) {}
@end

@include mesh_common.glsl

@program mesh vs fs
@program mesh_skin vs_skin fs
@program shadow shadow_vs shadow_fs
@program shadow_skin shadow_vs_skin shadow_fs
