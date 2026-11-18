// FactorIA sun shafts (PostProcess.sunShaftsEnabled, M71-D3b): screen-space light scattering from the sun's position on the screen.
//
//   rays   picture + prepass -> 1/2 res (one channel): for every pixel, a fixed number of taps along the screen line from the pixel toward
//          the sun, each tap adding the sky's brightness above the threshold there (only where the prepass says nothing was drawn: the
//          sky) times a glow that is strongest near the sun. What stands between the pixel and the sun's sky blocks the taps behind it,
//          so the rays stream away from the silhouettes. The tap pattern is jittered by a fixed noise: the same picture on every run.
//   add    the half-resolution rays x tint -> added onto the camera's rectangle of the picture (additive blending: it reads nothing of it)
//
// `uv` is the texture coordinate of the image being drawn; `s` is the same point in the camera-local top-left uv, in which the sun's
// position (b.xy) is given. The picture is read at fl(s * rc.zw + rc.xy), the prepass (the camera rectangle's size) at fl(s).
@module sun_shafts

@vs vs
layout(binding=0) uniform shafts_vs_params {
    vec4 flip;      // x = 1 when render targets have their origin at the bottom (OpenGL), 0 otherwise
};
layout(location=0) in vec2 pos;
out vec2 uv;
void main() {
    gl_Position = vec4(pos, 0.0, 1.0);
    float v_top_down = 0.5 - pos.y * 0.5;
    float v_bottom_up = 0.5 + pos.y * 0.5;
    uv = vec2(pos.x * 0.5 + 0.5, mix(v_top_down, v_bottom_up, flip.x));
}
@end

@fs fs_rays
layout(binding=0) uniform texture2D tex_c;
layout(binding=1) uniform texture2D tex_p;
layout(binding=0) uniform sampler smp_lin;
layout(binding=1) uniform sampler smp_pt;
@image_sample_type tex_p unfilterable_float
@sampler_type smp_pt nonfiltering
layout(binding=1) uniform rays_params {
    vec4 a;         // x = 1 when render targets are bottom-up (OpenGL), yz = the camera's rectangle in pixels, w = its aspect (width / height)
    vec4 rc;        // the rectangle of the picture the camera covers (top-left, fractions of the picture): xy corner, zw size
    vec4 b;         // xy = the sun's position (camera-local top-left uv), z = the longest ray (in screen heights), w = the brightness the sky needs
    vec4 c;         // x = 1 / (1 - threshold), y = 1 for a linear scene (brightness is then compared as the display shows it), z = glow rate
};
in vec2 uv;
out vec4 frag_color;

vec2 fl(vec2 s) { return vec2(s.x, mix(s.y, 1.0 - s.y, a.x)); }
vec2 game_uv(vec2 s) { return fl(s * rc.zw + rc.xy); }
float ign(vec2 p) { return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715)))); }
// One channel made safe, as bloom.glsl: NaN and Inf (by their bits) become 0, a finite value is kept between 0 and 65504.
float sane(float x) {
    if (((floatBitsToUint(x) >> 23u) & 255u) == 255u) return 0.0;
    return clamp(x, 0.0, 65504.0);
}
// How much light the sky sends from the camera-local point `p`: 0 on anything the prepass drew, else the brightness above the threshold.
float sky_light(vec2 p) {
    if (p.x < 0.0 || p.x > 1.0 || p.y < 0.0 || p.y > 1.0) return 0.0;  // off the picture: no sky to read (a clamped read would streak along the border)
    vec2 size = a.yz;
    vec2 lo = 0.5 / size;
    vec2 q = clamp(p, lo, 1.0 - lo);
    vec4 pre = textureLod(sampler2D(tex_p, smp_pt), fl(q), 0.0);
    if (pre.a > 0.5) return 0.0;
    vec3 col = textureLod(sampler2D(tex_c, smp_lin), game_uv(q), 0.0).rgb;
    float lum = dot(vec3(sane(col.r), sane(col.g), sane(col.b)), vec3(0.2126, 0.7152, 0.0722));
    float shown = c.y > 0.5 ? pow(lum, 1.0 / 2.2) : lum;
    return clamp((shown - b.w) * c.x, 0.0, 4.0);
}

void main() {
    vec2 s = fl(uv);
    vec2 d = b.xy - s;
    float dist = length(vec2(d.x * a.w, d.y));      // to the sun, in screen heights
    float reach = min(dist, b.z);
    vec2 dir = d / max(dist, 1e-4);                  // uv per screen height, toward the sun
    float jitter = ign(floor(s * a.yz * 0.5));
    float acc = 0.0;
    float wsum = 0.0;
    for (int i = 0; i < 48; i++) {
        float t = (float(i) + jitter) / 48.0;
        vec2 p = s + dir * (reach * t);
        vec2 ds = b.xy - p;
        float glow = exp(-c.z * length(vec2(ds.x * a.w, ds.y)));
        float wt = 1.0 - t;
        acc += sky_light(p) * glow * wt;
        wsum += wt;
    }
    frag_color = vec4(acc / wsum, 0.0, 0.0, 1.0);
}
@end

@fs fs_add
layout(binding=0) uniform texture2D tex_r;
layout(binding=0) uniform sampler smp_lin;
layout(binding=1) uniform add_params {
    vec4 tint;      // rgb = colour * intensity * fade (in the scene's colour space)
};
in vec2 uv;
out vec4 frag_color;
void main() {
    float r = textureLod(sampler2D(tex_r, smp_lin), uv, 0.0).r;
    frag_color = vec4(tint.rgb * r, 0.0);
}
@end

@program rays vs fs_rays
@program add vs fs_add
