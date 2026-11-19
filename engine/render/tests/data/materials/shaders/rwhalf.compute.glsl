// Test fixture: a read-write rgba16f image that every dispatch grows by a constant (halves hold these sums exactly).
void compute(in ComputeInput i) {
    ivec2 p = ivec2(i.global_id.xy);
    ivec2 size = imageSize(acc);
    if (p.x >= size.x || p.y >= size.y) return;
    vec4 v = imageLoad(acc, p) + vec4(0.5, 1.0, 2.0, 3.0);
    imageStore(acc, p, v);
}
