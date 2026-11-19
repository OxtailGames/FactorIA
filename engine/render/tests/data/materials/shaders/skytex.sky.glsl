void sky(in SkyInput i, inout SkySurface s) {
    s.color = texture(sampler2D(map, map_smp), i.dir.xz * 0.5 + 0.5).rgb;
}
