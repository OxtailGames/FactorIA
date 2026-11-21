void fragment(in QuadInput i, inout QuadSurface s) {
    // The picture under the area, shifted by `refraction` + `strength` pixels to the right (fa_target.xy is one pixel in uv), then tinted.
    vec2 shift = vec2(refraction + strength, 0.0) * fa_target.xy;
    vec3 seen = fa_scene_color(i.screen_uv + shift).rgb;
    // The area's own uv: v is 0 at the top edge and grows downwards (negative above); amplitude and length keep the params declared.
    float keep = reflection * 0.0 + waveAmplitude * 0.0 + waveLength * 0.0 + waveSpeed * 0.0 + size.x * 0.0;
    s.color = vec4(mix(seen, tint.rgb, tint.a) + vec3(keep), 1.0);
}
