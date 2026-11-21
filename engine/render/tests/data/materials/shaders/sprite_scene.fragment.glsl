void fragment(in QuadInput i, inout QuadSurface s) {
    vec4 scene = fa_scene_color(i.screen_uv + vec2(dx, dy));
    s.color = vec4(mix(s.color.rgb, scene.rgb, amount), s.color.a);
}
