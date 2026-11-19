void surface(in SurfaceInput i, inout Surface s) {}

vec3 light(in SurfaceInput i, in Surface s, in LightSample l) {
    return vec3(0.0);
}

// The sky reflection (IBL) is off in custom lighting unless the snippet adds it.
vec3 ambient(in SurfaceInput i, in Surface s, vec3 ambientColor) {
    return fa_sky_light(i, s);
}
