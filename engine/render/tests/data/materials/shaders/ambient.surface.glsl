void surface(in SurfaceInput i, inout Surface s) {}

vec3 light(in SurfaceInput i, in Surface s, in LightSample l) {
    return vec3(0.0);
}

vec3 ambient(in SurfaceInput i, in Surface s, vec3 ambientColor) {
    return vec3(0.0, ambientColor.g, 0.0);
}
