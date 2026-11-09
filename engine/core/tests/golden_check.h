// Golden image comparison shared by every test that checks a picture against a committed PNG (render goldens in
// engine/render/tests/golden, the menus and export goldens in tools/cli/tests/golden). Header-only on purpose: the
// render and CLI test binaries include it by relative path, and engine/core/tests/test_golden.cpp tests it.
//
// The rules (docs/ARCHITECTURE.md, "Testing"; docs/BUILDING.md, "Golden images"):
//  - A golden that does not exist FAILS the test. Only FA_UPDATE_GOLDENS=1 writes goldens (FA_UPDATE_GOLDEN=1, the old
//    spelling, still works). A test that silently wrote its own reference compared the picture with itself.
//  - A picture matches when all three hold: the mean error over all channels, the share of pixels with any channel off
//    by more than `pixelThreshold`, and the largest single-channel error are within the limits. The mean alone lets one
//    wrong region (a missing sprite, a black glyph) pass on a big picture; the share catches a region and the maximum
//    catches one wrong pixel, except in a golden with text, thin lines or nearest-sampled edges: golden_edge_limits()
//    allows a largest error of 1.0 there, so for those only the mean and the share guard against a missing glyph or edge.
//  - One golden file serves every backend (Metal, D3D11, GL on Mesa llvmpipe): the limits are what the backends'
//    rasterizers needed, so a limit is raised only with a measurement of a backend, never to make a failure go away.
#pragma once

#include <doctest.h>

#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <sstream>
#include <string>

#include "fa/core/fs.h"
#include "fa/core/image.h"

namespace fa::test {

struct GoldenLimits {
    double maxMeanError = 0.004;       // mean absolute channel error over the whole picture, 0..1
    double maxDifferingShare = 0.08;   // share of pixels (0..1) with a channel more than pixelThreshold off
    double maxPixelError = 0.6;        // the largest single-channel error anywhere, 0..1
    float pixelThreshold = 4.0f / 255.0f;
};

// Where the numbers come from (FA_GOLDEN_REPORT=1 prints them for every golden). The committed goldens differ from what every
// backend draws, so the limits are the worst of the backends measured, with a margin:
//  - Metal (Apple M-series) and Mesa llvmpipe (x86-64, GL) against the same files: mean error up to 0.0029, up to 4.3 % of the
//    pixels more than 4/255 off (2d_captions on llvmpipe; 3.7 % for 3d_pbr_normalmap_ibl), largest error up to 0.19 on
//    the 3D goldens. So 0.004 mean (the bound the goldens always had), 8 % of the pixels (about 2x the worst measured:
//    a wrong region of a twelfth of the picture still fails) and 0.6 for the largest error (3x the worst 3D case).
//  - Direct3D 11 on Windows (Debug MSVC; fa_test_render 295/295 and the 3 fa_test_cli golden cases pass with these limits):
//    WARP (FACTORIA_D3D11_WARP=1, the CI runner's adapter): worst share 3.5 % (3d_pbr_normalmap_ibl, mean 0.0015, max 0.19;
//    3d_mixed 1.4 %), worst mean 0.0021 (2d_debug); a largest error above 0.6 only on edge-limit goldens: 2d_debug 1.0,
//    2d_captions 0.91, 2d_widgets 0.85, 2d_parallax 0.81 (0.07 % of the pixels), 3d_material_cutout 0.78 (0.06 %). CLI:
//    export_2d_platformer project mean 0.000002, exported game mean 0.00034 / share 1.1 % / max 0.098; menus_ar mean 0.0008 /
//    share 0.43 % / max 0.49; menus_text200 exact. Hardware (AMD RX 6950 XT): every 3D golden exact except 3d_mixed (share
//    1.4 %, max 0.078); the 2D and UI goldens as on WARP.
//  - Goldens with text, thin lines or nearest-sampled texture edges have single pixels that flip between ink and background
//    from one GPU to the next (largest error 0.78 to 1.0 on Metal and llvmpipe, in under 0.3 % of the pixels): they pass
//    golden_edge_limits(), which lets the largest error be 1.0 and keeps the mean and the share.
// A limit is raised only with a measurement of a backend, written here.

// The tolerance of the render goldens before this check existed was the mean error alone (0.004, or 0.008 for a
// golden that needed it); a test that needs more passes its own GoldenLimits.
inline GoldenLimits golden_limits(double maxMeanError) {
    GoldenLimits l;
    l.maxMeanError = maxMeanError;
    return l;
}

// For a golden with text, thin lines or nearest-sampled edges (see above): any single pixel may differ completely.
inline GoldenLimits golden_edge_limits(double maxMeanError = 0.004) {
    GoldenLimits l = golden_limits(maxMeanError);
    l.maxPixelError = 1.0;
    return l;
}

enum class GoldenVerdict {
    Match,         // within the limits
    Wrote,         // update mode: the golden was (re)written from the picture
    Missing,       // no golden file and not in update mode
    Unreadable,    // the file exists but is not a readable image, or could not be written
    SizeMismatch,  // different dimensions
    TooDifferent,  // outside a limit
};

struct GoldenResult {
    GoldenVerdict verdict = GoldenVerdict::Match;
    ImageDiff diff;
    double differingShare = 0.0;
    std::string message;
    bool ok() const { return verdict == GoldenVerdict::Match || verdict == GoldenVerdict::Wrote; }
};

// True when the environment asks for goldens to be written: FA_UPDATE_GOLDENS=1. FA_UPDATE_GOLDEN=1 is the old name and
// counts only when FA_UPDATE_GOLDENS is not set, so FA_UPDATE_GOLDENS=0 turns an old FA_UPDATE_GOLDEN=1 off.
inline bool golden_update_requested() {
    if (const char* v = std::getenv("FA_UPDATE_GOLDENS")) return std::string(v) == "1";
    const char* old = std::getenv("FA_UPDATE_GOLDEN");
    return old && std::string(old) == "1";
}

// Compares `img` with the PNG at `golden`. No assertions: the caller (or expect_golden_file) decides what a verdict means.
inline GoldenResult compare_golden(const Image& img, const std::filesystem::path& golden, const GoldenLimits& limits,
                                   bool update) {
    GoldenResult r;
    std::ostringstream msg;
    if (update) {
        std::error_code ec;
        std::filesystem::create_directories(golden.parent_path(), ec);
        auto saved = save_png(img, fs::path_to_utf8(golden));
        if (!saved.ok()) {
            r.verdict = GoldenVerdict::Unreadable;
            msg << "cannot write golden " << fs::path_to_utf8(golden);
        } else {
            r.verdict = GoldenVerdict::Wrote;
            msg << "wrote golden " << fs::path_to_utf8(golden);
        }
        r.message = msg.str();
        return r;
    }
    std::error_code ec;
    if (!std::filesystem::exists(golden, ec)) {
        r.verdict = GoldenVerdict::Missing;
        msg << "golden " << fs::path_to_utf8(golden) << " does not exist. A missing golden is a failure, not a new reference: "
            << "if this picture is the intended one, run the test once with FA_UPDATE_GOLDENS=1, look at the written PNG and "
               "commit it (docs/BUILDING.md, \"Golden images\")";
        r.message = msg.str();
        return r;
    }
    auto loaded = load_image(fs::path_to_utf8(golden));
    if (!loaded.ok()) {
        r.verdict = GoldenVerdict::Unreadable;
        msg << "cannot load golden " << fs::path_to_utf8(golden) << ": " << loaded.error().to_string();
        r.message = msg.str();
        return r;
    }
    if (loaded->width != img.width || loaded->height != img.height) {
        r.verdict = GoldenVerdict::SizeMismatch;
        r.diff = diff_images(*loaded, img, limits.pixelThreshold);
        msg << "golden " << fs::path_to_utf8(golden) << " is " << loaded->width << "x" << loaded->height << " but the picture is "
            << img.width << "x" << img.height;
        r.message = msg.str();
        return r;
    }
    r.diff = diff_images(*loaded, img, limits.pixelThreshold);
    const double pixels = double(img.width) * double(img.height);
    r.differingShare = pixels > 0.0 ? double(r.diff.differingPixels) / pixels : 0.0;
    msg << "golden " << fs::path_to_utf8(golden) << ": meanError=" << r.diff.meanError << " (limit " << limits.maxMeanError << "), "
        << "differingShare=" << r.differingShare << " (" << r.diff.differingPixels << " pixels over " << limits.pixelThreshold * 255.0f
        << "/255; limit " << limits.maxDifferingShare << "), maxError=" << r.diff.maxError << " (limit " << limits.maxPixelError << ")";
    if (r.diff.meanError > limits.maxMeanError || r.differingShare > limits.maxDifferingShare ||
        r.diff.maxError > limits.maxPixelError)
        r.verdict = GoldenVerdict::TooDifferent;
    r.message = msg.str();
    // FA_GOLDEN_REPORT=1: one line per golden with the measured numbers, to choose limits from a backend (docs/BUILDING.md).
    if (const char* report = std::getenv("FA_GOLDEN_REPORT"); report && std::string(report) == "1" && r.verdict != GoldenVerdict::Wrote)
        std::fprintf(stderr, "GOLDEN %s mean=%.6f share=%.6f max=%.4f\n", fs::path_to_utf8(golden.filename()).c_str(), r.diff.meanError,
                     r.differingShare, r.diff.maxError);
    return r;
}

// The test-side check. On a failure the picture is written next to the golden as <name>.actual.png (git-ignored) so it can
// be looked at, and copied over the golden by hand or by FA_UPDATE_GOLDENS=1 when it is the intended one. When that folder
// cannot be written (a read-only checkout, a Docker volume) the picture goes to the temp folder instead; the failure message
// names the path that was written, or says that none could be.
inline GoldenResult expect_golden_file(const Image& img, const std::filesystem::path& golden, const GoldenLimits& limits = {}) {
    GoldenResult r = compare_golden(img, golden, limits, golden_update_requested());
    if (r.verdict == GoldenVerdict::Wrote) {
        MESSAGE(r.message);
        return r;
    }
    if (!r.ok()) {
        if (r.verdict != GoldenVerdict::Unreadable) {
            std::filesystem::path actual = golden;
            actual.replace_extension(".actual.png");
            if (save_png(img, fs::path_to_utf8(actual)).ok()) {
                r.message += "; the picture is saved as " + fs::path_to_utf8(actual);
            } else {
                std::error_code ec;
                const std::filesystem::path tmp = std::filesystem::temp_directory_path(ec);
                std::filesystem::path alt = tmp / golden.filename();
                alt.replace_extension(".actual.png");
                if (!ec && save_png(img, fs::path_to_utf8(alt)).ok())
                    r.message += "; " + fs::path_to_utf8(actual) + " is not writable, so the picture is saved as " + fs::path_to_utf8(alt);
                else
                    r.message += "; the picture could not be saved (neither next to the golden nor in the temp folder)";
            }
        }
        FAIL_CHECK(r.message);
    }
    return r;
}

}  // namespace fa::test
