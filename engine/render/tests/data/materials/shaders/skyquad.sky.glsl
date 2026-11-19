void sky(in SkyInput i, inout SkySurface s) {
    s.color = vec3(i.dir.x > 0.0 ? 1.0 : 0.0, i.dir.y > 0.0 ? 1.0 : 0.0, i.dir.x > 0.0 ? 0.0 : 1.0);
}
