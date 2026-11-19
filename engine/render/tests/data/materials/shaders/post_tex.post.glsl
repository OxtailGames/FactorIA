void post(in PostInput i, inout PostSurface s) {
    vec3 t = texture(sampler2D(mask, mask_smp), vec2(0.05, 0.05)).rgb;
    s.color.rgb = mix(fa_scene_color(i.uv).rgb, t, amount);
}
