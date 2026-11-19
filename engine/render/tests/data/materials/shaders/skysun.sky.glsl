void sky(in SkyInput i, inout SkySurface s) {
    s.color = vec3(0.1, 0.1, 0.2) + vec3(1.0, 0.8, 0.4) * pow(max(dot(i.dir, i.sun_dir), 0.0), 8.0);
}
