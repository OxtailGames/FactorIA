void fragment(in QuadInput i, inout QuadSurface s) {
    s.color.rgb = vec3(clamp(i.time * 0.25, 0.0, 1.0), 0.0, 0.0);
}
