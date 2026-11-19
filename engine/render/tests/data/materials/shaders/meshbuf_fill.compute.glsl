// Test fixture: one thread per instance of the `points` buffer that meshbuf.material.json draws from.
void compute(in ComputeInput i) {
    uint k = i.global_id.x;
    if (float(k) >= count) return;
    points.data[k].pos = vec4((float(k) - 2.0) * spacing, 0.0, 0.0, float(k) == hide ? 0.0 : 1.0);
    points.data[k].tint = vec4(1.0, 0.0, 0.0, 1.0);
}
