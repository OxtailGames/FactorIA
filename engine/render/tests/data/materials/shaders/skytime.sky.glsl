void sky(in SkyInput i, inout SkySurface s) {
    s.color = vec3(0.5 + 0.5 * sin(i.time * 3.0), 0.25 * fract(i.time), 0.25);
}
