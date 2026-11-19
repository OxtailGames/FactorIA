void fragment(in QuadInput i, inout QuadSurface s) {
    s.color.rgb = texture(sampler2D(mask, mask_smp), vec2(0.05, 0.05)).rgb;
}
