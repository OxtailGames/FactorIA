// M71: the HDR display output on the CPU (src/hdr_encode.h): the PQ curve, the scRGB scale, the Rec.709 -> Rec.2020 matrix, which
// encode a window's output gets, and the tonemap above paper white. No GPU: these run where `ctest -LE gpu` does
// (render_postprocess_core). hdr_output_render_tests.cpp checks that the shaders compute the same.
#include <doctest.h>

#include <cmath>
#include <limits>
#include <string>

#include "hdr_encode.h"
#include "render_features.h"

using namespace fa;
using namespace fa::render;

namespace {

HdrOutputInfo active(HdrEncoding e, float headroom, float paperWhite = 200.0f) {
    HdrOutputInfo i;
    i.requested = true;
    i.active = true;
    i.encoding = e;
    i.headroom = headroom;
    i.paperWhiteNits = paperWhite;
    return i;
}

}  // namespace

TEST_CASE("hdr encode: PQ (SMPTE ST 2084) gives the published signal values and inverts") {
    // Reference values of the inverse EOTF (ITU-R BT.2100, BT.2408: 203 nits, the HDR reference white, is 58%).
    CHECK(pq_from_nits(0.0f) == doctest::Approx(7.3e-7).epsilon(0.05));
    CHECK(pq_from_nits(100.0f) == doctest::Approx(0.5081).epsilon(0.001));
    CHECK(pq_from_nits(203.0f) == doctest::Approx(0.5807).epsilon(0.001));
    CHECK(pq_from_nits(1000.0f) == doctest::Approx(0.7518).epsilon(0.001));
    CHECK(pq_from_nits(10000.0f) == doctest::Approx(1.0f).epsilon(1e-5));
    // Out of range and NaN: clamped, never NaN.
    CHECK(pq_from_nits(20000.0f) == doctest::Approx(1.0f).epsilon(1e-5));
    CHECK(pq_from_nits(-5.0f) == doctest::Approx(pq_from_nits(0.0f)));
    CHECK(std::isfinite(pq_from_nits(std::numeric_limits<float>::quiet_NaN())));
    for (float n : {0.5f, 10.0f, 80.0f, 200.0f, 600.0f, 4000.0f}) {
        CAPTURE(n);
        CHECK(nits_from_pq(pq_from_nits(n)) == doctest::Approx(n).epsilon(1e-3));
    }
    // Rising everywhere.
    float prev = -1.0f;
    for (float n = 0.0f; n <= 10000.0f; n += 50.0f) {
        const float s = pq_from_nits(n);
        CHECK(s > prev);
        prev = s;
    }
}

TEST_CASE("hdr encode: scRGB is linear light with 1.0 = 80 nits, so paper white scales it") {
    const Rgb white{1.0f, 1.0f, 1.0f};
    CHECK(encode_output(OutputEncode::ScRgb, white, 80.0f)[0] == doctest::Approx(1.0f));
    CHECK(encode_output(OutputEncode::ScRgb, white, 200.0f)[1] == doctest::Approx(2.5f));
    CHECK(encode_output(OutputEncode::ScRgb, {4.0f, 0.5f, 0.0f}, 240.0f)[0] == doctest::Approx(12.0f));
    CHECK(encode_output(OutputEncode::ScRgb, {4.0f, 0.5f, 0.0f}, 240.0f)[1] == doctest::Approx(1.5f));
    // A paper white outside 80..1000 is clamped (SceneSettings.paperWhiteNits has the same range).
    CHECK(encode_output(OutputEncode::ScRgb, white, 5000.0f)[0] == doctest::Approx(12.5f));
    // EDR: extended linear sRGB, the light as it is; SDR: sRGB-encoded within white.
    CHECK(encode_output(OutputEncode::EdrLinear, {3.0f, 0.25f, 0.0f}, 200.0f)[0] == doctest::Approx(3.0f));
    CHECK(encode_output(OutputEncode::Sdr, {0.5f, 2.0f, -1.0f}, 200.0f)[0] == doctest::Approx(0.7354).epsilon(1e-3));
    CHECK(encode_output(OutputEncode::Sdr, {0.5f, 2.0f, -1.0f}, 200.0f)[1] == doctest::Approx(1.0f));
    CHECK(encode_output(OutputEncode::Sdr, {0.5f, 2.0f, -1.0f}, 200.0f)[2] == doctest::Approx(0.0f));
}

TEST_CASE("hdr encode: Rec.709 to Rec.2020 keeps white and moves the primaries inside the wider gamut") {
    const Rgb w = rec709_to_rec2020({1.0f, 1.0f, 1.0f});
    for (float v : w) CHECK(v == doctest::Approx(1.0f).epsilon(1e-5));
    // Pure 709 red is the matrix's first column (BT.2087).
    const Rgb r = rec709_to_rec2020({1.0f, 0.0f, 0.0f});
    CHECK(r[0] == doctest::Approx(0.6274).epsilon(1e-3));
    CHECK(r[1] == doctest::Approx(0.0691).epsilon(1e-3));
    CHECK(r[2] == doctest::Approx(0.0164).epsilon(1e-3));
    const Rgb b = rec709_to_rec2020({0.0f, 0.0f, 1.0f});
    CHECK(b[2] == doctest::Approx(0.8956).epsilon(1e-3));
    // HDR10: white at a paper white of 200 nits is the PQ signal of 200 nits on every channel.
    const Rgb pq = encode_output(OutputEncode::Hdr10, {1.0f, 1.0f, 1.0f}, 200.0f);
    for (float v : pq) CHECK(v == doctest::Approx(pq_from_nits(200.0f)).epsilon(1e-4));
    // Four times paper white is 800 nits.
    CHECK(encode_output(OutputEncode::Hdr10, {4.0f, 4.0f, 4.0f}, 200.0f)[0] ==
          doctest::Approx(pq_from_nits(800.0f)).epsilon(1e-4));
}

TEST_CASE("hdr encode: the output info of each platform selects its encode and headroom") {
    // Not asked, or asked and refused: the standard range.
    CHECK(select_output(HdrOutputInfo{}, true).encode == OutputEncode::Sdr);
    HdrOutputInfo refused = active(HdrEncoding::ScRgb, 5.0f);
    refused.active = false;
    CHECK(select_output(refused, true).encode == OutputEncode::Sdr);
    CHECK(select_output(refused, true).headroom == doctest::Approx(1.0f));
    CHECK_FALSE(select_output(refused, true).extended());

    // D3D11 on a 1000-nit display Windows composes in HDR, through the platform's own decision: scRGB, headroom 1000 / 200.
    const HdrRequest d3d = hdr_request(FeatureBackend::D3d11, true, 200.0f);
    const HdrDisplay tv = hdr_display_from_dxgi(true, 1000.0f, 0.05f, 600.0f, "TV");
    const HdrDecision dd = decide_hdr_output(d3d, tv);
    REQUIRE(dd.encoding == HdrEncoding::ScRgb);
    const OutputTarget sc = select_output(make_hdr_output_info(d3d, tv, dd, HdrEncoding::ScRgb, "RGBA16F"), true);
    CHECK(sc.encode == OutputEncode::ScRgb);
    CHECK(sc.headroom == doctest::Approx(5.0f));
    CHECK(sc.paperWhiteNits == doctest::Approx(200.0f));
    CHECK(sc.extended());
    // The driver refused scRGB and took the HDR10 fallback (RGB10A2): HDR10, the same headroom.
    HdrDecision fell = dd;
    fell.encoding = dd.fallback;
    const OutputTarget h10 = select_output(make_hdr_output_info(d3d, tv, fell, HdrEncoding::Hdr10, "RGB10A2"), true);
    CHECK(h10.encode == OutputEncode::Hdr10);
    CHECK(h10.headroom == doctest::Approx(5.0f));
    // A display that does not say its peak: the headroom is 1, HDR10 within paper white.
    const HdrDisplay unknownPeak = hdr_display_from_dxgi(true, 0.0f, 0.0f, 0.0f, "TV");
    const OutputTarget flat = select_output(
        make_hdr_output_info(d3d, unknownPeak, decide_hdr_output(d3d, unknownPeak), HdrEncoding::ScRgb, "RGBA16F"),
        true);
    CHECK(flat.encode == OutputEncode::ScRgb);
    CHECK(flat.headroom == doctest::Approx(1.0f));
    CHECK_FALSE(flat.extended());

    // Metal on a screen with EDR: extended linear sRGB, the headroom of the screen now.
    const HdrRequest mtl = hdr_request(FeatureBackend::Metal, true, 200.0f);
    const HdrDisplay xdr = hdr_display_from_edr(16.0f, 3.5f, "XDR");
    const OutputTarget edr =
        select_output(make_hdr_output_info(mtl, xdr, decide_hdr_output(mtl, xdr), HdrEncoding::Edr, "RGBA16F"), true);
    CHECK(edr.encode == OutputEncode::EdrLinear);
    CHECK(edr.headroom == doctest::Approx(3.5f));

    // GL on the same TV: the renderer writes no HDR encoding there.
    const HdrRequest gl = hdr_request(FeatureBackend::Gl, true, 200.0f);
    CHECK(decide_hdr_output(gl, tv).encoding == HdrEncoding::Sdr);

    // An 8-bit display picture (SRGB8A8 scene): the encode stays, the headroom is 1 (nothing above white can be stored).
    const OutputTarget eight = select_output(active(HdrEncoding::Edr, 4.0f), false);
    CHECK(eight.encode == OutputEncode::EdrLinear);
    CHECK(eight.headroom == doctest::Approx(1.0f));
    CHECK_FALSE(eight.extended());

    // Bad numbers: NaN headroom is 1, NaN paper white is 200, both are clamped (no more than 10000 nits).
    const float nan = std::numeric_limits<float>::quiet_NaN();
    CHECK(select_output(active(HdrEncoding::ScRgb, nan), true).headroom == doctest::Approx(1.0f));
    CHECK(select_output(active(HdrEncoding::ScRgb, 2.0f, nan), true).paperWhiteNits == doctest::Approx(200.0f));
    CHECK(select_output(active(HdrEncoding::ScRgb, 2.0f, 5000.0f), true).paperWhiteNits == doctest::Approx(1000.0f));
    CHECK(select_output(active(HdrEncoding::ScRgb, 500.0f, 200.0f), true).headroom == doctest::Approx(50.0f));
    CHECK(select_output(active(HdrEncoding::Edr, 0.5f), true).headroom == doctest::Approx(1.0f));
    CHECK(std::string(output_encode_name(OutputEncode::Hdr10)) == "hdr10");
}

TEST_CASE(
    "hdr tonemap: headroom 1 is the SDR curve; above it mid tones stay and highlights roll off toward the headroom") {
    for (int mode = 1; mode <= 4; ++mode) {
        CAPTURE(mode);
        const HdrShoulder sh = hdr_shoulder(mode);
        CHECK(sh.input > 0.0f);
        CHECK(sh.slope > 0.0f);
        CHECK(tonemap_sdr({sh.input, sh.input, sh.input}, mode)[0] == doctest::Approx(sh.start).epsilon(1e-3));
        for (float x : {0.05f, 0.3f, 1.0f, 3.0f, 20.0f, 300.0f}) {
            CAPTURE(x);
            const Rgb sdr = tonemap_sdr({x, x * 0.5f, x * 0.1f}, mode);
            const Rgb one = tonemap_hdr({x, x * 0.5f, x * 0.1f}, mode, 1.0f);
            for (std::size_t i = 0; i < 3; ++i) CHECK(one[i] == doctest::Approx(sdr[i]));
        }
        // Mid tones and shadows (below the shoulder) are the SDR curve whatever the headroom.
        for (float x = 0.0f; x < sh.input * 0.99f; x += sh.input / 16.0f) {
            CAPTURE(x);
            CHECK(tonemap_hdr({x, x, x}, mode, 6.0f)[0] == doctest::Approx(tonemap_sdr({x, x, x}, mode)[0]));
        }
        // Grey above it: rising, continuous where the curves meet, below the headroom, and past white.
        constexpr float H = 6.0f;
        float prev = -1.0f;
        for (float x = sh.input * 0.5f; x < 2000.0f; x *= 1.1f) {
            const float v = tonemap_hdr({x, x, x}, mode, H)[0];
            CHECK(v >= prev);
            CHECK(v < H);
            prev = v;
        }
        CHECK(prev > 0.9f * H);
        const float below = tonemap_hdr({sh.input * 0.999f, sh.input * 0.999f, sh.input * 0.999f}, mode, H)[0];
        const float above = tonemap_hdr({sh.input * 1.001f, sh.input * 1.001f, sh.input * 1.001f}, mode, H)[0];
        CHECK(std::fabs(above - below) < 0.01f);
        CHECK(tonemap_hdr({8.0f, 8.0f, 8.0f}, mode, H)[0] > 1.0f);
        // A colour keeps the SDR curve's ratios between its channels.
        const Rgb s = tonemap_sdr({6.0f, 3.0f, 0.6f}, mode);
        const Rgb h = tonemap_hdr({6.0f, 3.0f, 0.6f}, mode, H);
        CHECK(h[0] / h[1] == doctest::Approx(s[0] / s[1]).epsilon(1e-3));
        // Between headroom 1 and 2 it is mixed in: just above 1 it is (almost) the SDR curve.
        CHECK(tonemap_hdr({8.0f, 8.0f, 8.0f}, mode, 1.001f)[0] ==
              doctest::Approx(tonemap_sdr({8, 8, 8}, mode)[0]).epsilon(0.01));
    }
    // `none` clips at the headroom instead of at 1.
    CHECK(tonemap_hdr({3.0f, 9.0f, -1.0f}, 0, 4.0f)[0] == doctest::Approx(3.0f));
    CHECK(tonemap_hdr({3.0f, 9.0f, -1.0f}, 0, 4.0f)[1] == doctest::Approx(4.0f));
    CHECK(tonemap_hdr({3.0f, 9.0f, -1.0f}, 0, 4.0f)[2] == doctest::Approx(0.0f));
    CHECK(tonemap_hdr({3.0f, 9.0f, -1.0f}, 0, 1.0f)[0] == doctest::Approx(1.0f));
}

TEST_CASE("hdr encode: halves read back from an RGBA16F image") {
    CHECK(half_to_float(0x3C00) == 1.0f);
    CHECK(half_to_float(0xC000) == -2.0f);
    CHECK(half_to_float(0x7BFF) == 65504.0f);
    CHECK(half_to_float(0x0001) == doctest::Approx(5.9604645e-8));
    CHECK(half_to_float(0x3800) == 0.5f);
    CHECK(std::isinf(half_to_float(0x7C00)));
    CHECK(std::isnan(half_to_float(0x7E00)));
}
