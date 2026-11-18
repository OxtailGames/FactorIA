#include <doctest.h>

#include <cmath>
#include <limits>

#include "fa/platform/hdr_output.h"

using namespace fa;

namespace {

HdrRequest wanting(unsigned encodable) {
    HdrRequest r;
    r.want = true;
    r.encodable = encodable;
    return r;
}

constexpr unsigned kAll =
    hdr_encoding_bit(HdrEncoding::ScRgb) | hdr_encoding_bit(HdrEncoding::Hdr10) | hdr_encoding_bit(HdrEncoding::Edr);

}  // namespace

TEST_CASE("hdr output: encoding names and bits") {
    CHECK(std::string(hdr_encoding_name(HdrEncoding::Sdr)) == "sdr");
    CHECK(std::string(hdr_encoding_name(HdrEncoding::ScRgb)) == "scRGB");
    CHECK(std::string(hdr_encoding_name(HdrEncoding::Hdr10)) == "hdr10");
    CHECK(std::string(hdr_encoding_name(HdrEncoding::Edr)) == "edr");
    unsigned all = 0;
    for (int i = 0; i < kHdrEncodingCount; ++i) {
        CHECK((all & hdr_encoding_bit(HdrEncoding(i))) == 0u);
        all |= hdr_encoding_bit(HdrEncoding(i));
    }
}

TEST_CASE("hdr output: the Windows display from DXGI_OUTPUT_DESC1") {
    const HdrDisplay on = hdr_display_from_dxgi(true, 1015.237f, 0.0123f, 640.0f, "LG HDR 4K");
    CHECK(on.known);
    CHECK(on.hdr);
    CHECK(on.offers == (hdr_encoding_bit(HdrEncoding::ScRgb) | hdr_encoding_bit(HdrEncoding::Hdr10)));
    CHECK(on.maxNits == doctest::Approx(1015.24f));  // rounded to 2 decimals: the same on every CPU
    CHECK(on.minNits == doctest::Approx(0.01f));
    CHECK(on.maxFullFrameNits == doctest::Approx(640.0f));
    CHECK(on.name == "LG HDR 4K");
    CHECK(on.why.empty());

    // An HDR monitor with Windows' HDR switch off, and a plain monitor: different advice.
    const HdrDisplay off = hdr_display_from_dxgi(false, 600.0f, 0.1f, 400.0f, "");
    CHECK(off.known);
    CHECK_FALSE(off.hdr);
    CHECK(off.offers == 0);
    CHECK(off.why.find("Use HDR") != std::string::npos);
    const HdrDisplay plain = hdr_display_from_dxgi(false, 270.0f, 0.5f, 270.0f, "");
    CHECK(plain.why.find("Use HDR") == std::string::npos);
    CHECK(plain.why.find("standard range") != std::string::npos);

    // Nonsense luminances read as unknown (0), never NaN in the JSON.
    const HdrDisplay odd = hdr_display_from_dxgi(true, std::numeric_limits<float>::quiet_NaN(), -3.0f, INFINITY, "");
    CHECK(odd.maxNits == 0.0f);
    CHECK(odd.minNits == 0.0f);
    CHECK(odd.maxFullFrameNits == 0.0f);
}

TEST_CASE("hdr output: the Apple display from its EDR headroom") {
    const HdrDisplay xdr = hdr_display_from_edr(16.0f, 2.3456f, "Built-in Liquid Retina XDR Display");
    CHECK(xdr.known);
    CHECK(xdr.hdr);
    CHECK(xdr.offers == hdr_encoding_bit(HdrEncoding::Edr));
    CHECK(xdr.maxHeadroom == doctest::Approx(16.0f));
    CHECK(xdr.headroom == doctest::Approx(2.35f));
    CHECK(xdr.maxNits == 0.0f);  // macOS does not say
    const HdrDisplay sdr = hdr_display_from_edr(1.0f, 1.0f, "Studio");
    CHECK(sdr.known);
    CHECK_FALSE(sdr.hdr);
    CHECK(sdr.offers == 0);
    CHECK_FALSE(sdr.why.empty());
    const HdrDisplay odd = hdr_display_from_edr(std::numeric_limits<float>::quiet_NaN(), 0.2f, "");
    CHECK(odd.maxHeadroom == 1.0f);
    CHECK(odd.headroom == 1.0f);
    CHECK_FALSE(odd.hdr);
}

TEST_CASE("hdr output: off, unknown and standard-range displays decide SDR with a reason") {
    const HdrDisplay hdr10 = hdr_display_from_dxgi(true, 1000.0f, 0.0f, 600.0f, "TV");

    HdrRequest off = wanting(kAll);
    off.want = false;
    HdrDecision d = decide_hdr_output(off, hdr10);
    CHECK(d.encoding == HdrEncoding::Sdr);
    CHECK(d.why.find("hdrOutput") != std::string::npos);

    HdrDisplay unknown;
    unknown.why = "there is no window";
    d = decide_hdr_output(wanting(kAll), unknown);
    CHECK(d.encoding == HdrEncoding::Sdr);
    CHECK(d.why == "there is no window");

    d = decide_hdr_output(wanting(kAll), hdr_display_from_dxgi(false, 600.0f, 0.0f, 400.0f, ""));
    CHECK(d.encoding == HdrEncoding::Sdr);
    CHECK(d.why.find("Use HDR") != std::string::npos);

    HdrRequest blocked = wanting(kAll);
    blocked.blocked = "the editor shows the game in its own view";
    d = decide_hdr_output(blocked, hdr10);
    CHECK(d.encoding == HdrEncoding::Sdr);
    CHECK(d.why == blocked.blocked);
}

TEST_CASE("hdr output: auto picks what the display offers and the renderer writes, scRGB before HDR10") {
    const HdrDisplay win = hdr_display_from_dxgi(true, 1000.0f, 0.0f, 600.0f, "TV");
    HdrDecision d = decide_hdr_output(wanting(kAll), win);
    CHECK(d.encoding == HdrEncoding::ScRgb);
    CHECK(d.fallback == HdrEncoding::Hdr10);
    CHECK(d.why.empty());

    d = decide_hdr_output(wanting(hdr_encoding_bit(HdrEncoding::Hdr10)), win);
    CHECK(d.encoding == HdrEncoding::Hdr10);
    CHECK(d.fallback == HdrEncoding::Sdr);

    // The renderer cannot write what the display takes: SDR, with the renderer's own reason.
    HdrRequest edrOnly = wanting(hdr_encoding_bit(HdrEncoding::Edr));
    edrOnly.pending = "planned (M71): the renderer does not write scRGB or HDR10 yet";
    d = decide_hdr_output(edrOnly, win);
    CHECK(d.encoding == HdrEncoding::Sdr);
    CHECK(d.why == edrOnly.pending);
    edrOnly.pending.clear();
    d = decide_hdr_output(edrOnly, win);
    CHECK(d.why.find("scRGB or hdr10") != std::string::npos);

    d = decide_hdr_output(edrOnly, hdr_display_from_edr(8.0f, 1.0f, "XDR"));
    CHECK(d.encoding == HdrEncoding::Edr);
    CHECK(d.fallback == HdrEncoding::Sdr);
}

TEST_CASE("hdr output: the info reports the headroom over paper white and why SDR") {
    const HdrDisplay win = hdr_display_from_dxgi(true, 1000.0f, 0.0f, 600.0f, "TV");
    HdrRequest r = wanting(kAll);
    r.paperWhiteNits = 300.0f;
    const HdrDecision d = decide_hdr_output(r, win);
    HdrOutputInfo info = make_hdr_output_info(r, win, d, HdrEncoding::ScRgb, "RGBA16F");
    CHECK(info.requested);
    CHECK(info.active);
    CHECK(info.encoding == HdrEncoding::ScRgb);
    CHECK(info.swapchainFormat == "RGBA16F");
    CHECK(info.maxNits == doctest::Approx(1000.0f));
    CHECK(info.paperWhiteNits == doctest::Approx(300.0f));
    CHECK(info.headroom == doctest::Approx(3.33f));  // 1000 / 300, rounded
    CHECK(info.status.find("scRGB on TV") != std::string::npos);
    CHECK(info.status.find("3.33 times") != std::string::npos);

    // The platform refused the switch: SDR, and the status says so.
    info = make_hdr_output_info(r, win, d, HdrEncoding::Sdr, "BGRA8");
    CHECK_FALSE(info.active);
    CHECK(info.headroom == 1.0f);
    CHECK(info.status.find("could not switch") != std::string::npos);

    // Paper white out of range or NaN is clamped like SceneSettings clamps it; a peak below paper white is 1x, not less.
    r.paperWhiteNits = std::numeric_limits<float>::quiet_NaN();
    info = make_hdr_output_info(r, win, d, HdrEncoding::ScRgb, "RGBA16F");
    CHECK(info.paperWhiteNits == doctest::Approx(200.0f));
    r.paperWhiteNits = 5000.0f;
    info = make_hdr_output_info(r, hdr_display_from_dxgi(true, 400.0f, 0.0f, 400.0f, ""), d, HdrEncoding::Hdr10,
                                "RGB10A2");
    CHECK(info.paperWhiteNits == doctest::Approx(1000.0f));
    CHECK(info.headroom == 1.0f);

    // EDR: the current headroom of the screen, and the renderer's note while the picture stays within white.
    const HdrDisplay xdr = hdr_display_from_edr(16.0f, 4.5f, "XDR");
    HdrRequest edr = wanting(hdr_encoding_bit(HdrEncoding::Edr));
    edr.activeNote = "within white for now";
    info = make_hdr_output_info(edr, xdr, decide_hdr_output(edr, xdr), HdrEncoding::Edr, "RGBA16F");
    CHECK(info.active);
    CHECK(info.headroom == doctest::Approx(4.5f));
    CHECK(info.maxNits == 0.0f);
    CHECK(info.status.find("within white for now") != std::string::npos);

    // Off: SDR with the decision's reason.
    edr.want = false;
    info = make_hdr_output_info(edr, xdr, decide_hdr_output(edr, xdr), HdrEncoding::Sdr, "BGRA8");
    CHECK_FALSE(info.requested);
    CHECK_FALSE(info.active);
    CHECK(info.status.find("hdrOutput is off") != std::string::npos);
}

TEST_CASE("hdr output: without a window the display is unknown and nothing switches") {
    const HdrDisplay d = app_hdr_display();
    CHECK_FALSE(d.known);
    CHECK_FALSE(d.hdr);
    CHECK(d.why.find("no window") != std::string::npos);
    const HdrOutputInfo before = app_hdr_output();
    CHECK_FALSE(before.active);
    CHECK(before.swapchainFormat.empty());
    const HdrOutputInfo info = app_update_hdr_output(wanting(kAll));
    CHECK_FALSE(info.active);
    CHECK(info.encoding == HdrEncoding::Sdr);
    CHECK(info.requested);
    CHECK(info.status.find("no window") != std::string::npos);
    CHECK(app_hdr_output().status == info.status);
}

TEST_CASE("hdr output: a request that does not want HDR is answered once, then 'unchanged' until the display is asked "
          "again") {
    HdrRequest off = wanting(kAll);
    off.want = false;
    off.paperWhiteNits = 321.0f;  // not the request of any other case: the first call below always builds an answer
    HdrOutputInfo info;
    REQUIRE(app_update_hdr_output(off, info));
    CHECK_FALSE(info.active);
    CHECK(info.status.find("hdrOutput is off") != std::string::npos);
    const std::string status = info.status;
    // 130 more frames: the display is asked again every 120th (kIdleRefresh), the other ones change nothing and leave `info` alone.
    int answers = 0;
    for (int i = 0; i < 130; ++i) {
        HdrOutputInfo again;
        again.status = "untouched";
        if (app_update_hdr_output(off, again)) {
            ++answers;
            CHECK(again.status == status);
        } else {
            CHECK(again.status == "untouched");
        }
    }
    CHECK(answers >= 1);
    CHECK(answers <= 2);
    CHECK(app_hdr_output().status == status);
    // A different request is answered at once.
    off.blocked = "the editor shows the game in its own view";
    CHECK(app_update_hdr_output(off, info));
    CHECK(app_hdr_output().status == info.status);
}
