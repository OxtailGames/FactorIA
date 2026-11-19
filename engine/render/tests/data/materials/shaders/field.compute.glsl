// Test fixture of the storage images of a compute material: one thread per pixel.
void compute(in ComputeInput i) {
    ivec2 p = ivec2(i.global_id.xy);
    ivec2 size = imageSize(field);
    if (p.x >= size.x || p.y >= size.y) return;
    float opaque = textureLod(sampler2D(src, src_smp), vec2(0.5), 0.0).a;  // 1: the checker (or white) is opaque
    imageStore(field, p, vec4(float(p.x * 16) / 255.0, float(p.y * 16) / 255.0, blue * opaque, 1.0));
    float n = imageLoad(count, p).x + 1.0;
    imageStore(count, p, vec4(n, 0.0, 0.0, 0.0));
}
