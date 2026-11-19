void post(in PostInput i, inout PostSurface s) {
    s.color.rgb *= fa_scene_rgb(tint.rgb);
}
