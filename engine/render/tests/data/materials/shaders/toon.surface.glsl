void surface(in SurfaceInput i, inout Surface s) {}

vec3 light(in SurfaceInput i, in Surface s, in LightSample l) {
    float ndl = dot(s.normal, l.direction);
    float band = ndl > 0.5? 1.0 : dark;
    return s.albedo * l.color * band;
}
