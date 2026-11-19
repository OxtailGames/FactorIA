void post(in PostInput i, inout PostSurface s) {
    s.color.rgb = vec3(i.uv.x, i.uv.y, clamp(i.time * 0.25, 0.0, 1.0));
}
