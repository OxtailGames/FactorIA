#include "physical_sky.h"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace fa::render {

namespace {

constexpr double kPi = 3.14159265358979323846;

float finite_clamp(float v, float lo, float hi, float fallback) {
    if (!std::isfinite(v)) return fallback;
    return std::clamp(v, lo, hi);
}

double smooth_step(double a, double b, double x) {
    const double t = std::clamp((x - a) / (b - a), 0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
}

double horizon_mu(double h) { return -std::sqrt(std::max(h * (2.0 * kSkyPlanetKm + h), 0.0)) / (kSkyPlanetKm + h); }

struct Fnv {
    std::uint64_t h = 0xcbf29ce484222325ull;
    void mix(std::uint64_t v) {
        h = (h ^ v) * 0x100000001b3ull;
        h ^= h >> 29;
    }
    void mixf(float f) {
        std::uint32_t u;
        std::memcpy(&u, &f, sizeof(u));
        mix(u);
    }
};

}  // namespace

PhysicalSkySettings physical_sky_settings(const SceneSettings& ss) {
    PhysicalSkySettings s;
    s.sunSizeDeg = finite_clamp(ss.skySunSize, 0.1f, 10.0f, 0.53f);
    s.turbidity = finite_clamp(ss.skyTurbidity, 1.0f, 10.0f, 2.0f);
    s.groundAlbedo[0] = finite_clamp(ss.skyGroundAlbedo.r, 0.0f, 1.0f, 0.3f);
    s.groundAlbedo[1] = finite_clamp(ss.skyGroundAlbedo.g, 0.0f, 1.0f, 0.3f);
    s.groundAlbedo[2] = finite_clamp(ss.skyGroundAlbedo.b, 0.0f, 1.0f, 0.3f);
    s.exposure = finite_clamp(ss.skyExposure, 0.0f, 16.0f, 1.0f);
    s.tintsSun = ss.skyTintsSun;
    s.coverage = finite_clamp(ss.cloudCoverage, 0.0f, 1.0f, 0.0f);
    s.density = finite_clamp(ss.cloudDensity, 0.0f, 1.0f, 0.0f);
    s.altitudeM = finite_clamp(ss.cloudAltitude, 300.0f, 12000.0f, 2500.0f);
    s.windX = finite_clamp(ss.cloudWind.x, -1000.0f, 1000.0f, 0.0f);
    s.windZ = finite_clamp(ss.cloudWind.y, -1000.0f, 1000.0f, 0.0f);
    return s;
}

SkyAir sky_air(double turbidity) {
    turbidity = std::clamp(turbidity, 1.0, 10.0);
    SkyAir a{};
    // Molecular scattering (Rayleigh): 8 pi^3 (n^2 - 1)^2 / (3 N lambda^4), with the King factor for the anisotropy of air
    // (depolarisation 0.035). n = 1.000278 and N = 2.5469e25 molecules per cubic metre at sea level; per kilometre.
    const double n = 1.000278, num = 2.5469e25, king = (6.0 + 3.0 * 0.035) / (6.0 - 7.0 * 0.035);
    const double lambda[3] = {680e-9, 550e-9, 440e-9};
    for (int c = 0; c < 3; ++c) {
        const double l2 = lambda[c] * lambda[c];
        const double nn = (n * n - 1.0) * (n * n - 1.0);
        a.rayleigh[c] = 8.0 * kPi * kPi * kPi * nn / (3.0 * num * l2 * l2) * king * 1000.0;
    }
    // Aerosols: the optical depth of the zenith is 0.02 * turbidity^1.5 (all wavelengths alike), spread over the scale height
    // of the haze; 90 % of what they take out of the beam they scatter, the rest they absorb.
    const double ext = 0.02 * std::pow(turbidity, 1.5) / kSkyMieScaleKm;
    a.mieScatter = 0.9 * ext;
    a.mieAbsorb = 0.1 * ext;
    a.mieG = 0.8;
    // Ozone: the Chappuis band takes red and green out of the beam (the cross sections of 680, 550 and 440 nm times a column of
    // 300 Dobson units spread over the layer's tent), which is what keeps the zenith of the twilight sky blue.
    const double cross[3] = {1.5e-21, 3.3e-21, 3.5e-22};               // cm^2
    const double peak = 8.06e18 / (kSkyOzoneHalfKm * 1.0e5);           // molecules per cm^3 at the centre of the layer
    for (int c = 0; c < 3; ++c) a.ozone[c] = cross[c] * peak * 1.0e5;  // per km
    return a;
}

void sky_optical_depth(const SkyAir& air, double h, double mu, double tau[3]) {
    constexpr int kSteps = 64;
    const double r0 = kSkyPlanetKm + std::max(h, 0.0);
    const double rt = kSkyPlanetKm + kSkyAirKm;
    mu = std::clamp(mu, -1.0, 1.0);
    const double b = r0 * mu;
    const double len = -b + std::sqrt(std::max(b * b + (rt - r0) * (rt + r0), 0.0));
    tau[0] = tau[1] = tau[2] = 0.0;
    for (int i = 0; i < kSteps; ++i) {
        const double s0 = double(i) / kSteps, s1 = double(i + 1) / kSteps, sm = 0.5 * (s0 + s1);
        const double t = len * sm * sm, dt = len * (s1 * s1 - s0 * s0);
        const double r = std::sqrt(std::max(r0 * r0 + 2.0 * t * r0 * mu + t * t, 0.0));
        const double alt = std::max(r - kSkyPlanetKm, 0.0);
        const double dr = std::exp(-alt / kSkyRayleighScaleKm), dm = std::exp(-alt / kSkyMieScaleKm);
        const double doz = std::max(1.0 - std::abs(alt - kSkyOzoneCenterKm) / kSkyOzoneHalfKm, 0.0);
        for (int c = 0; c < 3; ++c)
            tau[c] += (air.rayleigh[c] * dr + (air.mieScatter + air.mieAbsorb) * dm + air.ozone[c] * doz) * dt;
    }
}

double sky_sun_visibility(double h, double mu) { return smooth_step(-kSkySunEdge, kSkySunEdge, mu - horizon_mu(h)); }

void sky_sun_transmittance(const SkyAir& air, double mu, double out[3]) {
    double tau[3], zen[3];
    sky_optical_depth(air, kSkyObserverKm, mu, tau);
    sky_optical_depth(air, kSkyObserverKm, 1.0, zen);
    const double vis = sky_sun_visibility(kSkyObserverKm, mu);
    for (int c = 0; c < 3; ++c) out[c] = vis * std::exp(-(tau[c] - zen[c]));
}

double sky_cloud_sun_factor(const PhysicalSkySettings& s) {
    if (!s.clouds()) return 1.0;
    const double thick = 1.0 - std::exp(-double(s.density) * kSkyCloudTau);
    return std::max(1.0 - double(s.coverage) * thick, 0.08);
}

void sky_sun_light_factor(const PhysicalSkySettings& s, float sunY, float out[3]) {
    const SkyAir air = sky_air(s.turbidity);
    double t[3];
    sky_sun_transmittance(air, double(sunY), t);
    const double cloud = sky_cloud_sun_factor(s);
    for (int c = 0; c < 3; ++c) out[c] = float(t[c] * cloud);
}

PhysicalSkyState sky_quantised(const PhysicalSkyState& st) {
    PhysicalSkyState q = st;
    double v[3];
    double len = 0.0;
    for (int i = 0; i < 3; ++i) {
        v[i] = std::round(double(st.sunDir[i]) / kSkySunStep) * kSkySunStep;
        len += v[i] * v[i];
    }
    len = std::sqrt(len);
    if (len < 1.0e-6) {  // a direction that rounded to nothing: straight up
        v[0] = v[2] = 0.0;
        v[1] = 1.0;
        len = 1.0;
    }
    for (int i = 0; i < 3; ++i) q.sunDir[i] = float(v[i] / len);
    if (st.s.drifting()) {
        const double t = std::isfinite(st.time) && st.time > 0.0 ? std::min(st.time, 1.0e9) : 0.0;
        q.time = std::floor(t / kSkyCloudStep) * kSkyCloudStep;
    } else {
        q.time = 0.0;
    }
    return q;
}

std::uint64_t sky_air_key(const PhysicalSkySettings& s) {
    Fnv f;
    f.mix(0x5ca1ab1eull);  // the model's version: a change of the tables' maths changes it
    f.mixf(s.turbidity);
    for (float a : s.groundAlbedo) f.mixf(a);
    return f.h;
}

std::uint64_t sky_view_key(const PhysicalSkySettings& s, float sunY) {
    Fnv f;
    f.mix(sky_air_key(s));
    f.mixf(sunY);
    return f.h;
}

std::uint64_t sky_env_static_key(const PhysicalSkyState& st) {
    Fnv f;
    f.mix(sky_air_key(st.s));
    for (float c : st.sunColor) f.mixf(c);
    f.mixf(st.s.exposure);
    f.mixf(st.s.coverage);
    f.mixf(st.s.density);
    f.mixf(st.s.altitudeM);
    f.mixf(st.s.windX);
    f.mixf(st.s.windZ);
    f.mix(st.linear ? 1 : 0);
    return f.h;
}

std::uint64_t sky_env_key(const PhysicalSkyState& st) {
    Fnv f;
    f.mix(sky_env_static_key(st));
    for (float c : st.sunDir) f.mixf(c);
    f.mix(std::uint64_t(st.time / kSkyCloudStep + 0.5));
    return f.h;
}

SkyShaderParams sky_shader_params(const PhysicalSkyState& st, bool sunDisc) {
    SkyShaderParams p{};
    const PhysicalSkySettings& s = st.s;
    const SkyAir air = sky_air(s.turbidity);
    for (int i = 0; i < 3; ++i) {
        p.v[0][i] = st.sunDir[i];
        p.v[1][i] = st.sunColor[i] * s.exposure;
        p.v[2][i] = s.groundAlbedo[i];
        p.v[5][i] = float(air.rayleigh[i]);
        p.v[7][i] = float(air.ozone[i]);
    }
    p.v[1][3] = st.linear ? 1.0f : 0.0f;
    // Clouds: the noise value above which there is cloud (coverage 0 = a high threshold, 1 = nearly all of the sky), the
    // optical thickness of the thickest, the altitude in km, on/off.
    p.v[3][0] = 0.78f - 0.56f * s.coverage;
    p.v[3][1] = float(double(s.density) * kSkyCloudTau);
    p.v[3][2] = s.altitudeM * 0.001f;
    p.v[3][3] = s.clouds() ? 1.0f : 0.0f;
    // The pattern drifts with the wind: its offset in cells, wrapped to the period of the noise in double so a long game keeps
    // its precision.
    const double t = std::isfinite(st.time) ? st.time : 0.0;
    const double cell = kSkyCloudCellKm * 1000.0;
    auto wrap = [](double v) {
        v = std::fmod(v, double(kSkyCloudPeriod));
        return v < 0.0 ? v + double(kSkyCloudPeriod) : v;
    };
    p.v[4][0] = float(wrap(-double(s.windX) * t / cell));
    p.v[4][1] = float(wrap(-double(s.windZ) * t / cell));
    p.v[4][3] = sunDisc ? 1.0f : 0.0f;
    p.v[5][3] = float(air.mieScatter);
    p.v[6][0] = float(air.mieAbsorb);
    p.v[6][1] = float(air.mieG);
    p.v[6][2] = float(0.5 * double(s.sunSizeDeg) * kPi / 180.0);
    return p;
}

}  // namespace fa::render
