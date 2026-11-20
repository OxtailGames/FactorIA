// The physical sky (SceneSettings.skyModel = physical, M73-P3d): the CPU half. Everything here is plain double / float
// arithmetic with no GPU object, so it is deterministic on every machine and a test can check it:
//
//   the air         the scattering and absorption coefficients of the atmosphere (Rayleigh, Mie, ozone), computed from the
//                   physics of each (the formula of molecular scattering, a turbidity to aerosol optical depth law, an ozone
//                   column and its absorption bands), in kilometres: the planet is 6360 km and the air 100 km thick
//   the sun light   what the air and the clouds let through of the sun (a ray integral over the same density profile the
//                   GPU's transmittance table is made from): the colour factor of the directional light
//   the keys        what the LUTs and the baked environment depend on, and how finely (the trigger of a new bake)
//
// The GPU half (renderer_sky_phys.h, shaders/sky_physical.glsl) draws the sky from these numbers: three small look-up
// tables (transmittance, multiple scattering, sky view) computed with the very same profile, a per-pixel sun disc and a
// procedural cloud layer.
#pragma once

#include <cstdint>

#include "fa/scene/components.h"

namespace fa::render {

inline constexpr double kSkyPlanetKm = 6360.0;      // radius of the ground
inline constexpr double kSkyAirKm = 100.0;          // thickness of the atmosphere
inline constexpr double kSkyRayleighScaleKm = 8.0;  // density falls by e every 8 km
inline constexpr double kSkyMieScaleKm = 1.2;       // aerosols hug the ground: e every 1.2 km
inline constexpr double kSkyOzoneCenterKm = 25.0;   // the ozone layer: a tent of this height and half-width
inline constexpr double kSkyOzoneHalfKm = 15.0;
// The observer is at a fixed height above the ground: the sky is a function of the viewing direction only (like a
// skybox), so the baked environment and the background are the same sky wherever the camera stands.
inline constexpr double kSkyObserverKm = 0.01;
inline constexpr double kSkyCloudCellKm = 1.5;  // the size of the first octave of the cloud noise, km
inline constexpr int kSkyCloudPeriod = 256;     // the cloud noise repeats every this many cells (its hash lattice)
inline constexpr double kSkySunEdge =
    0.004;  // the sun's light fades over this much of mu around the horizon (its own width)
inline constexpr double kSkyCloudTau = 20.0;     // optical thickness of the thickest cloud (CloudDensity 1)
inline constexpr float kSkySunDiscGain = 40.0f;  // the sun disc is this many times the colour of the light
// The tables (the shader file sky_physical.glsl repeats these sizes).
inline constexpr int kSkyTransmittanceW = 128, kSkyTransmittanceH = 64;
inline constexpr int kSkyMultiScatterSize = 32;
inline constexpr int kSkyViewW = 128, kSkyViewH = 128;

// Quantisation of what the baked environment depends on: the sun's direction in steps of 1/256 (a quarter of a degree) and,
// for drifting clouds, the game clock in steps of kSkyCloudStep seconds. A change below a step does not bake again.
inline constexpr float kSkySunStep = 1.0f / 256.0f;
inline constexpr double kSkyCloudStep = 2.0;

// The settings of SceneSettings the physical sky reads, clamped to their ranges (a script can write any number).
struct PhysicalSkySettings {
    float sunSizeDeg = 0.53f;
    float turbidity = 2.0f;
    float groundAlbedo[3] = {0.3f, 0.3f, 0.3f};
    float exposure = 1.0f;
    bool tintsSun = true;
    float coverage = 0.25f;
    float density = 0.6f;
    float altitudeM = 2500.0f;
    float windX = 8.0f, windZ = 3.0f;  // metres per second
    bool clouds() const { return coverage > 0.0f && density > 0.0f; }
    bool drifting() const { return clouds() && (windX != 0.0f || windZ != 0.0f); }
};
PhysicalSkySettings physical_sky_settings(const SceneSettings& ss);

// The coefficients of the air, per kilometre.
struct SkyAir {
    double rayleigh[3];            // scattering = extinction of the molecules, red, green, blue (680, 550, 440 nm)
    double mieScatter, mieAbsorb;  // aerosols at sea level (all wavelengths alike)
    double mieG;                   // their forward-scattering asymmetry
    double ozone[3];               // absorption at the peak of the ozone layer
};
// The air for a turbidity (1 = very clean .. 10 = heavy haze): the aerosol optical depth of the zenith is
// 0.02 * turbidity^1.5 (0.02 clean, 0.057 for 2, 0.63 for 10).
SkyAir sky_air(double turbidity);

// Optical depth, per colour channel, of the ray that leaves altitude `h` km with the cosine `mu` of its angle to the local
// vertical, up to the top of the atmosphere (a planet in the way is not considered: see sky_sun_visibility).
void sky_optical_depth(const SkyAir& air, double h, double mu, double tau[3]);
// 1 when the sun (direction cosine `mu` to the vertical) is above the horizon of a point at altitude h, 0 when the planet
// hides it, a smooth step over the sun's own width between.
double sky_sun_visibility(double h, double mu);
// What the sun's light gets through the air of a sun with direction cosine `mu` at the observer's altitude, relative to a sun
// overhead (so the colour you chose for the light is the colour at noon); 0 below the horizon. Clouds not included.
void sky_sun_transmittance(const SkyAir& air, double mu, double out[3]);
// The factor the sun's light keeps when the cloud layer is as thick as the settings say, averaged over the sky: 1 for a
// clear sky, 0.1 under a heavy overcast.
double sky_cloud_sun_factor(const PhysicalSkySettings& s);
// The colour factor of the directional light that is the sun (the product of the two above), per channel.
void sky_sun_light_factor(const PhysicalSkySettings& s, float sunY, float out[3]);

// What the GPU needs of one frame of the sky.
struct PhysicalSkyState {
    PhysicalSkySettings s;
    float sunDir[3] = {0.0f, 1.0f, 0.0f};    // unit vector towards the sun
    float sunColor[3] = {1.0f, 1.0f, 1.0f};  // the colour of the sun light in the scene's numbers (intensity included)
    bool linear = true;                      // the scene computes in linear light: else the sky is encoded to sRGB
    double time = 0.0;                       // seconds of game time (the cloud drift)
};
// The state the baked environment is drawn with: the sun direction rounded to kSkySunStep and the clock to kSkyCloudStep (a
// still sky keeps the clock at 0), so a run draws the same environment at any frame rate.
PhysicalSkyState sky_quantised(const PhysicalSkyState& st);
// Hashes of what each table depends on. The atmosphere (transmittance and multiple scattering) changes with the air and the
// ground; the sky view also with the sun's height; the environment with everything quantised.
std::uint64_t sky_air_key(const PhysicalSkySettings& s);
std::uint64_t sky_view_key(const PhysicalSkySettings& s, float sunY);
std::uint64_t sky_env_key(const PhysicalSkyState& quantised);
// What the environment depends on besides the sun's direction and the clock: a bake started because THIS changed is whole (a
// sliced bake, physical_sky amortisation, only follows a moving sun and drifting clouds).
std::uint64_t sky_env_static_key(const PhysicalSkyState& st);
// A sun that moved further than this (chord of the unit sphere, about a degree) since the last bake started gets a whole bake.
inline constexpr float kSkyBakeJump = 1.0f / 64.0f;

// The numbers the shader's parameter block (`sky_params`, sky_physical.glsl) holds, for a state. `sunDisc`: draw the sun disc (the
// environment bake leaves it out: the light itself is the sun there).
struct SkyShaderParams {
    float v[8][4];
};
SkyShaderParams sky_shader_params(const PhysicalSkyState& st, bool sunDisc);

}  // namespace fa::render
