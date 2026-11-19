// FactorIA compute template (material kind "compute", docs/SHADERS.md, "Compute materials"): the source of the one program a
// compute material is made from. The generator (tools/common/src/shaders_compute.cpp) writes the material's own part into
// `@block fa_user`: the params block, the storage buffers, the textures, the `layout(local_size_*) in;` line and the author's
// snippet, which defines `void compute(in ComputeInput i)`. This file adds the types the snippet reads and main(), which
// fills a ComputeInput and calls compute() once per thread.
//
// Nothing else includes this file: the built-in shaders (compile_shaders.sh) are unchanged. Every engine identifier starts
// with fa_ (the snippet contract's own names do not).

@block fa_compute_types
struct ComputeInput {           // read-only, per thread
    uvec3 global_id;            // the thread's index over the whole dispatch (group_id * workgroup size + local_id)
    uvec3 local_id;             // the thread's index inside its workgroup
    uvec3 group_id;             // the workgroup's index in the dispatch
    uint local_index;           // local_id flattened: x + y * size.x + z * size.x * size.y
};
@end

@cs fa_cs
@include_block fa_compute_types
@include_block fa_user
void main() {
    ComputeInput fa_input;
    fa_input.global_id = gl_GlobalInvocationID;
    fa_input.local_id = gl_LocalInvocationID;
    fa_input.group_id = gl_WorkGroupID;
    fa_input.local_index = gl_LocalInvocationIndex;
    compute(fa_input);
}
@end
