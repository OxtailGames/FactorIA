void fragment(in QuadInput i, inout QuadSurface s) {
    s.color.rgb = vec3(i.life);
}
