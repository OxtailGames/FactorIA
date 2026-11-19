void vertex(inout QuadVertex v) {
    v.world_pos.x += texture(sampler2D(mask, mask_smp), vec2(0.4, 0.05)).r * 40.0;
}

void fragment(in QuadInput i, inout QuadSurface s) {
    s.color.rgb = texture(sampler2D(mask, mask_smp), vec2(0.4, 0.05)).rgb;
}
