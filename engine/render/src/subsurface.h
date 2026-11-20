// The CPU side of the screen-space subsurface scattering (MeshRenderer.subsurface, M73.5): the scattering profile, the weights of the taps and the
// pixel radius the shader mirrors, and the plan of a camera. Pure functions, so the maths is tested without a GPU. The passes are in
// renderer_subsurface.h; docs/design/ARCHITECTURE_SUBSURFACE.md explains the design.
//
// The profile. The light a surface scatters to the distance r from where it entered follows the normalized diffusion profile of Burley (2015),
//     R(r) = (exp(-r/d) + exp(-r/(3 d))) / (8 pi d r),
// the shape of skin and wax: a sharp core and a long red tail. A separable kernel (one pass along x, one along y) cannot be R, so the 1D kernel K(x)
// is a sum of four Gaussians fitted to the line integral of R (tools/shaders/fit_subsurface_profile.py, our own fit): the weights sum to 1 and the
// sigmas are in units of the scatter radius, the distance inside which 90% of the light of R lands. MeshRenderer.subsurfaceRadius is that distance
// in metres, per colour channel when subsurfaceColor differs between the channels.
#pragma once

namespace fa {
struct CameraGeometry;
}

namespace fa::render {

// One Gaussian of the profile: its share of the light and its standard deviation (units of the 90% radius).
struct SssGaussian {
    float weight;
    float sigma;
};
inline constexpr int kSssGaussians = 4;
// The fit of fit_subsurface_profile.py (squared error of the cumulative distribution 7.1e-3): weights sum to 1.
inline constexpr SssGaussian kSssGauss[kSssGaussians] = {
    {0.127627f, 0.023263f},
    {0.281541f, 0.112140f},
    {0.278810f, 0.266531f},
    {0.312022f, 0.642780f},
};

// The blur takes 2 * kSssTaps + 1 taps per pass. Tap k (1..kSssTaps) stands for the cell [kSssCell[k - 1], kSssCell[k]] on each side of the centre; the
// centre tap stands for [-kSssCell[0], kSssCell[0]]. Units of the radius that holds 90% of the light (the widest colour channel's). The last edge
// is where the widest Gaussian (sigma 0.64) is 3.4 sigma out: what lies beyond is under 0.1% of the light.
inline constexpr int kSssTaps = 7;
inline constexpr float kSssCell[kSssTaps + 1] = {0.03f, 0.09f, 0.19f, 0.35f, 0.6f, 0.95f, 1.45f, 2.2f};

// The widest radius the passes blur, in pixels (2.2 times that is the reach of the outer tap) and the largest MeshRenderer.subsurfaceRadius (metres).
inline constexpr float kSssMaxRadiusPx = 40.0f;
inline constexpr float kSssMaxRadiusM = 0.5f;

// The error function (the approximation of Abramowitz and Stegun 7.1.26, error below 1.5e-7) the shader uses.
float sss_erf(float x);

// The 1D kernel K(x) at x (units of the 90% radius): the sum of the four Gaussians. Integrates to 1.
float sss_kernel(float x);

// The 2D profile the kernel stands for, R(r) of Burley normalized to a 90% radius of 1: 2 pi R(r) r integrates to 1. For the tests of the fit.
float sss_profile_2d(float r);
// The share of the light of that profile inside the distance r (units of the 90% radius): 0.9 at r = 1.
float sss_profile_cdf(float r);

// The weights of the taps of a colour channel whose radius is `ratio` (0..1, clamped to 0.02 .. 1) times the widest channel's: w[0] is the centre
// tap, w[1..kSssTaps] each ONE side's tap (the other side has the same). The mass of the kernel inside each tap's cell; they add up to nearly 1
// (the light beyond the last edge is lost): w[0] + 2 * sum(w[1..]).
void sss_tap_weights(float ratio, float w[kSssTaps + 1]);
// The offset of tap k (1..kSssTaps) in pixels, for a widest radius of `radiusPx`: the middle of its cell.
float sss_tap_offset(int k, float radiusPx);

// The scatter radius in pixels of a surface at linear view depth `depth` (metres along the camera's forward axis): radiusM times the pixels one metre
// covers there (focalPx / depth, or focalPx for an orthographic camera), clamped to 0 .. kSssMaxRadiusPx. A non-finite input gives 0.
float sss_radius_px(float radiusM, float depth, float focalPx, bool ortho);

// What a camera's passes need: the pixels one metre covers at depth 1 (a perspective camera) or per world unit (an orthographic one), and the size of
// the camera's rectangle. `on` is false for an empty rectangle or a projection that is not finite.
struct SssPlan {
    bool on = false;
    bool ortho = false;
    int rectW = 0, rectH = 0;
    float focalPx = 0.0f;
};
SssPlan make_sss_plan(const CameraGeometry& cam, int rectW, int rectH);

}  // namespace fa::render
