void post(in PostInput i, inout PostSurface s) {
    vec4 h = fa_history(i.uv);
    s.color.rgb = max(s.color.rgb, h.rgb * keep);
    if (mark > 0.5 && fa_history_valid) s.color.rgb = vec3(1.0, 0.0, 0.0);
}
