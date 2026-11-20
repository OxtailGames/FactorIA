// FactorIA physical sky (SceneSettings.skyModel = physical, M73-P3d). Four programs:
//
//   transmittance  the optical depth of the air from a point at altitude h to the top of the atmosphere along a ray that leaves
//                  it at cosine mu to the vertical: a 128 x 64 table (u = sqrt of the angle above the horizon of the point, v =
//                  sqrt of the altitude). The table stores the optical depth, not the transmittance, so a bilinear fetch and an
//                  exp() are as exact as the table is smooth.
//   multiscatter   the light that has scattered more than once, as an isotropic source per unit of scattering: a 32 x 32 table
//                  (sun cosine, altitude). Each texel averages the light that comes from the sphere around the point and sums the
//                  repeated bounces as a geometric series (the energy that one scatter returns to the air).
//   skyview        the sky as seen from the observer, one ray march per texel of a 128 x 128 table (azimuth from the sun 0..pi,
//                  elevation concentrated at the horizon): single scattering of the sun (Rayleigh + Mie phase) plus the multiple
//                  scattering table, and the ground below the horizon.
//   sky            the picture: one fetch of the sky view per pixel, the sun disc with limb darkening, the cloud layer.
//
// Units: kilometres. The observer stands OBS_H above the ground of a planet of radius R_G; the air ends at R_T. Everything the tables
// hold is per unit of sun illuminance (the sun's colour is applied in the sky program), so a table depends on the air and the
// ground only. engine/render/src/physical_sky.cpp has the CPU twin of the transmittance (the colour of the sun light) and the
// packing of the uniform block `sky_params` (q[0..7], see sky_shader_params()). Constants that appear in both files say so.
//
// The atmosphere math stays highp (the generated GLES3 code declares every float highp): at 6360 km one ulp of a float is half a
// millimetre of a coordinate and the horizon rays depend on it. Altitudes are computed from radii, never from differences of
// squares, where a cancellation would show.
@module skyphys

@include color_space.glsl

@block sky_core
layout(binding=1) uniform sky_params {
    vec4 q[8];      // sky_shader_params(): q0 sun dir (xyz), q1 sun colour * exposure (rgb) and the linear flag, q2 ground albedo,
                    // q3 clouds (threshold, optical thickness, altitude km, on), q4 cloud offset in cells (xy), sun disc flag (w),
                    // q5 Rayleigh (rgb) + Mie scattering, q6 Mie absorption, Mie g, sun radius in radians, q7 ozone (rgb)
};
const float PI = 3.14159265;
const float R_G = 6360.0;           // kSkyPlanetKm
const float R_T = 6460.0;           // kSkyPlanetKm + kSkyAirKm
const float H_A = 100.0;            // kSkyAirKm
const float OBS_H = 0.01;           // kSkyObserverKm
const float HR = 8.0;               // kSkyRayleighScaleKm
const float HM = 1.2;               // kSkyMieScaleKm
const float OZ_C = 25.0;            // kSkyOzoneCenterKm
const float OZ_W = 15.0;            // kSkyOzoneHalfKm
const float SUN_EDGE = 0.004;       // kSkySunEdge
const float TR_W = 128.0;           // kSkyTransmittanceW / H
const float TR_H = 64.0;
const float MS_W = 32.0;            // kSkyMultiScatterSize
const float MS_H = 32.0;
const float SV_W = 128.0;           // kSkyViewW / H
const float SV_H = 128.0;
const float CLOUD_CELL = 1.5;       // kSkyCloudCellKm
const float DISC_GAIN = 40.0;       // kSkySunDiscGain: the disc is this many times the colour of the light
const float EXTINCTION_FLOOR = 1.0e-7;

vec3 sky_sun_dir() { return q[0].xyz; }

float horizon_mu(float h) { return -sqrt(max(h * (2.0 * R_G + h), 0.0)) / (R_G + h); }

// A table coordinate of 0..1 (the first to the last texel centre) and back.
float lut_u(float frag, float size) { return (frag - 0.5) / (size - 1.0); }
float lut_uv(float u, float size) { return (0.5 + clamp(u, 0.0, 1.0) * (size - 1.0)) / size; }

float rho_o(float h) { return max(1.0 - abs(h - OZ_C) / OZ_W, 0.0); }
vec3 sky_scatter(float h) { return q[5].xyz * exp(-h / HR) + vec3(q[5].w * exp(-h / HM)); }
vec3 sky_extinction(float h) {
    return q[5].xyz * exp(-h / HR) + vec3((q[5].w + q[6].x) * exp(-h / HM)) + q[7].xyz * rho_o(h);
}

float phase_r(float c) { return 3.0 / (16.0 * PI) * (1.0 + c * c); }
float phase_m(float c) {
    float g = q[6].y;
    float g2 = g * g;
    return 3.0 * (1.0 - g2) / (2.0 * (2.0 + g2)) * (1.0 + c * c) / pow(1.0 + g2 - 2.0 * g * c, 1.5) / (4.0 * PI);
}
float phase_hg(float g, float c) {
    float g2 = g * g;
    return (1.0 - g2) / (4.0 * PI * pow(1.0 + g2 - 2.0 * g * c, 1.5));
}

// Where a ray from the altitude h with the cosine mu to the vertical leaves the atmosphere, or meets the ground (when mu is
// below the horizon of that altitude): the distance, in km.
float ray_length(float h, float mu) {
    float r0 = R_G + h;
    float muh = horizon_mu(h);
    if (mu < muh) return r0 * (-mu - sqrt(max((mu - muh) * (mu + muh), 0.0)));
    float b = r0 * mu;
    return -b + sqrt(b * b + (R_T - r0) * (R_T + r0));
}
@end

@block sky_tr
layout(binding=0) uniform texture2D sky_tr_tex;
layout(binding=0) uniform sampler sky_smp;
vec3 sky_tau(float h, float mu) {
    float muh = horizon_mu(h);
    float x = sqrt(clamp((mu - muh) / (1.0 - muh), 0.0, 1.0));
    float y = sqrt(clamp(h / H_A, 0.0, 1.0));
    return textureLod(sampler2D(sky_tr_tex, sky_smp), vec2(lut_uv(x, TR_W), lut_uv(y, TR_H)), 0.0).rgb;
}
// What reaches altitude h of the sun's light when the sun's cosine to the vertical is mu: 0 below the horizon.
vec3 sun_trans(float h, float mu) {
    float vis = smoothstep(-SUN_EDGE, SUN_EDGE, mu - horizon_mu(h));
    return exp(-sky_tau(h, mu)) * vis;
}
@end

@block sky_ms
layout(binding=1) uniform texture2D sky_ms_tex;
vec3 sky_multi(float h, float mus) {
    vec2 uv = vec2(lut_uv(0.5 * mus + 0.5, MS_W), lut_uv(sqrt(clamp(h / H_A, 0.0, 1.0)), MS_H));
    return textureLod(sampler2D(sky_ms_tex, sky_smp), uv, 0.0).rgb;
}
@end

@vs vs_lut
layout(location=0) in vec2 pos;
void main() {
    gl_Position = vec4(pos, 0.0, 1.0);
}
@end

// ---- transmittance ---------------------------------------------------------------------------------------------------
@fs fs_transmittance
@include_block sky_core
out vec4 frag_color;
void main() {
    float u = lut_u(gl_FragCoord.x, TR_W);
    float v = lut_u(gl_FragCoord.y, TR_H);
    float h = H_A * v * v;
    float muh = horizon_mu(h);
    float mu = muh + (1.0 - muh) * u * u;
    float r0 = R_G + h;
    float len = ray_length(h, mu);
    vec3 tau = vec3(0.0);
    // Steps grow with the distance (t = len * s^2): the dense air is close to the start of the ray.
    for (int i = 0; i < 48; i++) {
        float s0 = float(i) / 48.0;
        float s1 = float(i + 1) / 48.0;
        float sm = 0.5 * (s0 + s1);
        float t = len * sm * sm;
        float r = sqrt(max(r0 * r0 + 2.0 * t * r0 * mu + t * t, 0.0));
        tau += sky_extinction(max(r - R_G, 0.0)) * (len * (s1 * s1 - s0 * s0));
    }
    frag_color = vec4(tau, 0.0);
}
@end

// ---- multiscatter ----------------------------------------------------------------------------------------------------
@fs fs_multiscatter
@include_block sky_core
@include_block sky_tr
out vec4 frag_color;
void main() {
    float mus = 2.0 * lut_u(gl_FragCoord.x, MS_W) - 1.0;
    float v = lut_u(gl_FragCoord.y, MS_H);
    float h = H_A * v * v;
    vec3 sun = vec3(sqrt(max(1.0 - mus * mus, 0.0)), mus, 0.0);
    float r0 = R_G + h;
    vec3 p0 = vec3(0.0, r0, 0.0);
    float muh = horizon_mu(h);
    vec3 lsum = vec3(0.0);
    vec3 fsum = vec3(0.0);
    for (int k = 0; k < 32; k++) {
        // The directions: a spiral on the sphere, the same 32 points for every texel.
        float z = 1.0 - 2.0 * (float(k) + 0.5) / 32.0;
        float ph = float(k) * 2.39996323;
        float sz = sqrt(max(1.0 - z * z, 0.0));
        vec3 d = vec3(sz * cos(ph), z, sz * sin(ph));
        float len = ray_length(h, d.y);
        vec3 tv = vec3(1.0);
        vec3 l2 = vec3(0.0);
        vec3 f = vec3(0.0);
        for (int i = 0; i < 16; i++) {
            float s0 = float(i) / 16.0;
            float s1 = float(i + 1) / 16.0;
            float sm = 0.5 * (s0 + s1);
            float t = len * sm * sm;
            float dt = len * (s1 * s1 - s0 * s0);
            vec3 p = p0 + d * t;
            float rp = length(p);
            float hp = max(rp - R_G, 0.0);
            float mup = dot(p / rp, sun);
            vec3 ext = max(sky_extinction(hp), vec3(EXTINCTION_FLOOR));
            vec3 sc = sky_scatter(hp);
            vec3 st = exp(-ext * dt);
            vec3 sun_in = sun_trans(hp, mup) * sc / (4.0 * PI);
            l2 += tv * (sun_in - sun_in * st) / ext;
            f += tv * (sc - sc * st) / ext;
            tv *= st;
        }
        if (d.y < muh) {  // the ray ends on the ground: it adds what the ground sends back
            vec3 pg = p0 + d * len;
            vec3 up = normalize(pg);
            float mug = dot(up, sun);
            l2 += tv * q[2].xyz / PI * max(mug, 0.0) * sun_trans(0.0, mug);
        }
        lsum += l2;
        fsum += f;
    }
    vec3 l_in = lsum / 32.0;
    vec3 f_ms = min(fsum / 32.0, vec3(0.99));
    frag_color = vec4(l_in / (vec3(1.0) - f_ms), 0.0);
}
@end

// ---- skyview ---------------------------------------------------------------------------------------------------------
@block sky_view_map
// The elevation of the view direction (from the horizontal) of the sky view's row v (0..1): the horizon of the observer is v = 0.5,
// and the rows crowd around it (the sky changes fastest there).
float view_horizon() { return asin(horizon_mu(OBS_H)); }
float view_e(float v) {
    float eh = view_horizon();
    if (v >= 0.5) {
        float t = (v - 0.5) * 2.0;
        return eh + (0.5 * PI - eh) * t * t;
    }
    float t = (0.5 - v) * 2.0;
    return eh - (0.5 * PI + eh) * t * t;
}
float view_v(float e) {
    float eh = view_horizon();
    if (e >= eh) return 0.5 + 0.5 * sqrt(clamp((e - eh) / (0.5 * PI - eh), 0.0, 1.0));
    return 0.5 - 0.5 * sqrt(clamp((eh - e) / (0.5 * PI + eh), 0.0, 1.0));
}
@end

@fs fs_skyview
@include_block sky_core
@include_block sky_tr
@include_block sky_ms
@include_block sky_view_map
out vec4 frag_color;
void main() {
    float phi = lut_u(gl_FragCoord.x, SV_W) * PI;
    float e = view_e(lut_u(gl_FragCoord.y, SV_H));
    vec3 sun = sky_sun_dir();
    // The frame of the table: the sun at azimuth 0, the view at azimuth phi from it.
    sun = vec3(sqrt(max(1.0 - sun.y * sun.y, 0.0)), sun.y, 0.0);
    vec3 d = vec3(cos(e) * cos(phi), sin(e), cos(e) * sin(phi));
    float r0 = R_G + OBS_H;
    vec3 p0 = vec3(0.0, r0, 0.0);
    float len = ray_length(OBS_H, d.y);
    bool ground = d.y < horizon_mu(OBS_H);
    float cth = dot(d, sun);
    float pr = phase_r(cth);
    float pm = phase_m(cth);
    vec3 tv = vec3(1.0);
    vec3 l = vec3(0.0);
    for (int i = 0; i < 32; i++) {
        float s0 = float(i) / 32.0;
        float s1 = float(i + 1) / 32.0;
        float sm = 0.5 * (s0 + s1);
        float t = len * sm * sm;
        float dt = len * (s1 * s1 - s0 * s0);
        vec3 p = p0 + d * t;
        float rp = length(p);
        float hp = max(rp - R_G, 0.0);
        float mup = dot(p / rp, sun);
        vec3 ext = max(sky_extinction(hp), vec3(EXTINCTION_FLOOR));
        vec3 sr = q[5].xyz * exp(-hp / HR);
        vec3 sm_ = vec3(q[5].w * exp(-hp / HM));
        vec3 st = exp(-ext * dt);
        vec3 s = sun_trans(hp, mup) * (sr * pr + sm_ * pm) + sky_multi(hp, mup) * (sr + sm_);
        l += tv * (s - s * st) / ext;
        tv *= st;
    }
    if (ground) {
        vec3 pg = p0 + d * len;
        vec3 up = normalize(pg);
        float mug = dot(up, sun);
        // What the ground sends back: the sun on it, and the air's multiple scattering as an even light from the sky.
        l += tv * q[2].xyz * (max(mug, 0.0) / PI * sun_trans(0.0, mug) + sky_multi(0.0, mug));
    }
    frag_color = vec4(l, 0.0);
}
@end

// ---- sky -------------------------------------------------------------------------------------------------------------
@vs vs_sky
layout(binding=0) uniform sky_vs_params {
    mat4 inv_view_proj;
    vec4 cam_pos;
};
layout(location=0) in vec2 pos;
out vec3 ray_dir;
void main() {
    gl_Position = vec4(pos, 1.0, 1.0);
    vec4 far_pt = inv_view_proj * vec4(pos, 1.0, 1.0);
    ray_dir = far_pt.xyz / far_pt.w - cam_pos.xyz;
}
@end

@fs fs_sky
@include_block sky_core
@include_block sky_tr
@include_block sky_ms
@include_block sky_view_map
@include_block color_space
layout(binding=2) uniform texture2D sky_sv_tex;
in vec3 ray_dir;
out vec4 frag_color;

vec3 sky_view(float phi01, float e) {
    vec2 uv = vec2(lut_uv(phi01, SV_W), lut_uv(view_v(e), SV_H));
    return textureLod(sampler2D(sky_sv_tex, sky_smp), uv, 0.0).rgb;
}

// Value noise on a lattice that repeats every 256 cells (integer hash: the same on every GPU), five octaves.
float lattice(ivec2 c) {
    uvec2 u = uvec2(c & ivec2(255));
    uint h = u.x * 374761393u + u.y * 668265263u + 2246822519u;
    h = (h ^ (h >> 13)) * 1274126177u;
    h = h ^ (h >> 16);
    return float(h & 16777215u) / 16777215.0;
}
float value_noise(vec2 p) {
    vec2 f = floor(p);
    vec2 w = p - f;
    w = w * w * w * (w * (w * 6.0 - 15.0) + 10.0);
    ivec2 c = ivec2(f);
    return mix(mix(lattice(c), lattice(c + ivec2(1, 0)), w.x), mix(lattice(c + ivec2(0, 1)), lattice(c + ivec2(1, 1)), w.x), w.y);
}
float cloud_fbm(vec2 p) {
    float sum = 0.0;
    float amp = 0.5;
    float norm = 0.0;
    for (int o = 0; o < 5; o++) {
        sum += amp * value_noise(p);
        norm += amp;
        p = p * 2.0 + vec2(17.0, 31.0);
        amp *= 0.5;
    }
    return sum / norm;
}
// The optical thickness of the cloud layer along the direction d: 0 where there is none.
float cloud_tau(vec3 d) {
    if (q[3].w < 0.5 || d.y < 0.02) return 0.0;
    float t = (q[3].z - OBS_H) / d.y;
    vec2 p = d.xz * (t / CLOUD_CELL) + q[4].xy;
    float n = cloud_fbm(p);
    float mask = smoothstep(q[3].x, q[3].x + 0.1, n);
    return mask * q[3].y * smoothstep(0.02, 0.2, d.y);
}

void main() {
    vec3 d = normalize(ray_dir);
    vec3 sun = sky_sun_dir();
    float e = asin(clamp(d.y, -1.0, 1.0));
    vec2 sxz = sun.xz;
    float sl = length(sxz);
    sxz = sl > 1.0e-4 ? sxz / sl : vec2(1.0, 0.0);
    vec2 dxz = d.xz;
    float dl = length(dxz);
    dxz = dl > 1.0e-5 ? dxz / dl : sxz;
    float phi = acos(clamp(dot(sxz, dxz), -1.0, 1.0));
    vec3 sky = sky_view(phi / PI, e);
    // The sun disc: the sun's colour times DISC_GAIN, reddened by the air in its way, darker at the limb.
    if (q[4].w > 0.5 && d.y > -0.002) {
        float cd = dot(d, sun);
        float ang = sqrt(max(2.0 * (1.0 - cd), 0.0));
        float rho = ang / max(q[6].z, 1.0e-5);
        if (rho < 1.0) {
            float limb = 0.4 + 0.6 * sqrt(1.0 - rho * rho);
            float edge = 1.0 - smoothstep(0.92, 1.0, rho);
            sky += sun_trans(OBS_H, sun.y) * (limb / (1.0 - 0.6 / 3.0) * edge * DISC_GAIN / PI);
        }
    }
    // The clouds: the layer hides the sky behind it by its thickness and adds its own light, the sun through the air up there
    // (a silver edge towards the sun) and the sky's light.
    float tau = cloud_tau(d);
    if (tau > 0.0) {
        float c = dot(d, sun);
        vec3 st = sun_trans(q[3].z, sun.y);
        vec3 lit = st * (max(sun.y, 0.0) * 0.22 + 0.06 + 1.1 * phase_hg(0.7, c)) * exp(-0.06 * tau);
        vec3 amb = sky_view(0.0, 0.5 * PI) * 1.5;
        float a = 1.0 - exp(-tau);
        sky = sky * (1.0 - a) + (lit + amb) * a;
    }
    vec3 rgb = sky * q[1].xyz * PI;
    if (q[1].w < 0.5) rgb = fa_linear_to_srgb(rgb);
    frag_color = vec4(rgb, 1.0);
}
@end

@program transmittance vs_lut fs_transmittance
@program multiscatter vs_lut fs_multiscatter
@program skyview vs_lut fs_skyview
@program sky vs_sky fs_sky
