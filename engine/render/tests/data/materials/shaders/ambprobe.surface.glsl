void surface(in SurfaceInput i, inout Surface s) {}

vec3 light(in SurfaceInput i, in Surface s, in LightSample l) {
    return vec3(0.0);
}

// The diffuse ambient light toward the normal, as the engine hands it over (the scene's ambientLight, or the sky's L2 spherical harmonics).
vec3 ambient(in SurfaceInput i, in Surface s, vec3 ambientColor) {
    return ambientColor;
}
