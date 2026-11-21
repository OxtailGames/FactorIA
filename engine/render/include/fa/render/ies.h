// The IES photometric file (IESNA LM-63-1995 and LM-63-2002, `.ies`): the measured light distribution of a real lamp, what Light.ies
// names. CPU only: the renderer bakes the profile into a small tile of the light atlas (shaders/light_data.glsl reads it) and this
// parser, `candela_at` and `ies_bake` are the same data and maths on the CPU, for the importer (assets.import checks the file), the
// tests and anything that has to look at a profile. Our own parser of the public file format (no third-party code).
//
// What is read: the header keywords are skipped (the [LUMINAIRE] or [TEST] line names the profile), TILT=NONE or TILT=INCLUDE (the
// tilt table is read and ignored: the engine's lights do not tilt), the photometric header, the vertical and horizontal angles and the
// candela table. What is supported: photometric type C (the vertical angle runs from 0 at the nadir to 180 at the zenith around the
// luminaire's vertical axis, almost every lamp of a catalogue); photometric types A and B (goniometers that turn about a horizontal
// axis) are refused with the way to export type C. The horizontal angles may be one plane (a lamp that turns the same all around), 0
// to 90 (four-fold symmetry), 0 to 180 (two-fold) or 0 to 360 (all around); other ranges are refused.
#pragma once

#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/types.h"

namespace fa {

// A file larger than this is refused before it is parsed (catalogue files are a few kilobytes; a dense one 200 KB).
inline constexpr std::size_t kIesMaxFileBytes = std::size_t(4) << 20;
// The most angles and candela values a file may announce, checked before anything is allocated.
inline constexpr int kIesMaxVerticalAngles = 1024;
inline constexpr int kIesMaxHorizontalAngles = 1024;
inline constexpr std::size_t kIesMaxValues = std::size_t(1) << 20;

// The size of the baked profile (ies_bake): horizontal angle across (0 to 360 degrees), vertical angle down (0 to 180).
inline constexpr int kIesBakeWidth = 64;
inline constexpr int kIesBakeHeight = 32;

struct IesProfile {
    std::string version;      // "IESNA:LM-63-2002" as the file says it, "" for a 1986 file without a header line
    std::string name;         // the [LUMINAIRE] line, else the [TEST] line, "" when the file has neither
    int photometricType = 1;  // 1 = C (the only one supported), 2 = B, 3 = A
    int units = 2;            // 1 = feet, 2 = metres (the size of the luminous opening, not used by the renderer)
    double lampLumens =
        -1;  // lumens of one lamp, -1 = the file is in relative photometry (candela values are not absolute)
    double multiplier = 1;          // the file's candela multiplying factor (already applied to `candela`)
    std::vector<float> vertical;    // vertical angles in degrees, ascending, within 0..180
    std::vector<float> horizontal;  // horizontal angles in degrees, ascending, starting at 0 (or one plane)
    std::vector<float> candela;     // horizontal.size() planes of vertical.size() values each, times `multiplier`
    float maxCandela = 0;           // the largest value of `candela` (> 0)

    // The intensity in candela toward a direction given as the horizontal angle (any value, degrees; folded by the symmetry of the
    // table) and the vertical angle (0 = the nadir, 180 = the zenith): linear between the angles of the table, 0 outside the vertical
    // range it covers.
    float candela_at(float horizontalDeg, float verticalDeg) const;
};

// Parses the text of an .ies file. `name` is only used in messages ("lamp.ies:12: ..."). Every problem is an error that names the
// line and says how to fix it: a file that is not photometric data, a missing TILT line, a photometric type other than C, a count that
// does not match the numbers that follow, angles out of order or out of range, a horizontal range the renderer does not know, a
// negative candela value, a table of zeros.
Result<IesProfile> parse_ies(std::string_view text, std::string_view name);

// The profile as the renderer uploads it: kIesBakeWidth x kIesBakeHeight floats, row j = vertical angle (j + 0.5) / height * 180,
// column i = horizontal angle (i + 0.5) / width * 360, each value candela / maxCandela (so 0..1 and the brightest direction is 1: the
// light's intensity is the intensity at the peak, not the total power).
std::vector<float> ies_bake(const IesProfile& profile);

}  // namespace fa
