void post(in PostInput i, inout PostSurface s) {
    float d = fa_depth(i.uv);
    vec3 n = fa_normal(i.uv);
    s.color.rgb = vec3(clamp(d / 20.0, 0.0, 1.0), n.x * 0.5 + 0.5, n.y * 0.5 + 0.5);
}
