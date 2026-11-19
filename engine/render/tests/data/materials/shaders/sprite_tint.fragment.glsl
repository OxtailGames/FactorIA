void fragment(in QuadInput i, inout QuadSurface s) {
    s.color.rgb *= fa_scene_rgb(tint.rgb);
}
