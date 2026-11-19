void surface(in SurfaceInput i, inout Surface s) {}

// The whole light loop: only the brightest light of the frame shades the surface, as a two-band toon; the sky reflection is
// added on top, scaled by skyAmount.
vec3 lighting(in SurfaceInput i, in Surface s) {
    int best = -1;
    float bestPower = 0.0;
    for (int n = 0; n < fa_light_count(); ++n) {
        LightSample l = fa_light_unshadowed(n, i);
        float power = dot(l.color, vec3(0.299, 0.587, 0.114));
        if (power > bestPower) {
            bestPower = power;
            best = n;
        }
    }
    vec3 lit = fa_ambient.rgb * s.albedo * s.occlusion;
    if (best >= 0) {
        LightSample l = fa_light(best, i);
        float band = dot(s.normal, l.direction) > 0.5 ? 1.0 : dark;
        lit += s.albedo * l.color * band;
    }
    return lit + fa_sky_light(i, s) * skyAmount;
}
