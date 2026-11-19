void sky(in SkyInput i, inout SkySurface s) {
    s.color = mix(ground.rgb, zenith.rgb, clamp(i.dir.y * 0.5 + 0.5, 0.0, 1.0));
}
