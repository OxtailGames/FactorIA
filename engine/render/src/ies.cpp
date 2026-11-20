#include "fa/render/ies.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <format>

#include "fa/core/strings.h"

namespace fa {

namespace {

// A decimal number: sign, digits, a point, an exponent. Not strtod (the C locale may use a comma) and not NaN / inf.
bool parse_number(std::string_view t, double& out) {
    std::size_t i = 0;
    bool neg = false;
    if (i < t.size() && (t[i] == '+' || t[i] == '-')) neg = t[i++] == '-';
    double mant = 0.0;
    int digits = 0, scale = 0;
    bool point = false;
    for (; i < t.size(); ++i) {
        const char c = t[i];
        if (c >= '0' && c <= '9') {
            ++digits;
            if (digits <= 18) {
                mant = mant * 10.0 + double(c - '0');
                if (point) --scale;
            } else if (!point) {
                ++scale;
            }
        } else if (c == '.' && !point) {
            point = true;
        } else {
            break;
        }
    }
    if (digits == 0) return false;
    if (i < t.size() && (t[i] == 'e' || t[i] == 'E')) {
        ++i;
        bool eneg = false;
        if (i < t.size() && (t[i] == '+' || t[i] == '-')) eneg = t[i++] == '-';
        int e = 0, edigits = 0;
        for (; i < t.size() && t[i] >= '0' && t[i] <= '9'; ++i, ++edigits) e = std::min(e * 10 + (t[i] - '0'), 400);
        if (edigits == 0) return false;
        scale += eneg ? -e : e;
    }
    if (i != t.size()) return false;
    const double v = mant * std::pow(10.0, double(scale));
    if (!std::isfinite(v)) return false;
    out = neg ? -v : v;
    return true;
}

std::string_view trim_ws(std::string_view s) {
    while (!s.empty() && (s.front() == ' ' || s.front() == '\t' || s.front() == '\r')) s.remove_prefix(1);
    while (!s.empty() && (s.back() == ' ' || s.back() == '\t' || s.back() == '\r')) s.remove_suffix(1);
    return s;
}

std::string upper(std::string_view s) {
    std::string r(s);
    std::transform(r.begin(), r.end(), r.begin(), [](unsigned char c) { return char(std::toupper(c)); });
    return r;
}

Error line_error(std::string_view name, int line, const std::string& what, const std::string& hint) {
    return make_error(std::format("{}:{}: {}", name, line, what), hint);
}

struct Token {
    std::string_view text;
    int line = 0;
};

// The numbers of the data section, in order, each with its line.
class Numbers {
public:
    Numbers(std::string_view text, int firstLine, std::string_view name) : text_(text), line_(firstLine), name_(name) {}

    // The next token, or false at the end.
    bool next(Token& t) {
        while (pos_ < text_.size()) {
            const char c = text_[pos_];
            if (c == '\n') {
                ++line_;
                ++pos_;
            } else if (c == ' ' || c == '\t' || c == '\r' || c == ',') {
                ++pos_;
            } else {
                break;
            }
        }
        if (pos_ >= text_.size()) return false;
        const std::size_t start = pos_;
        while (pos_ < text_.size() && std::string_view(" \t\r\n,").find(text_[pos_]) == std::string_view::npos) ++pos_;
        t = Token{text_.substr(start, pos_ - start), line_};
        return true;
    }

    // The next number; an error naming `what` when the file ends or the token is not a number.
    Result<double> number(const char* what) {
        Token t;
        if (!next(t))
            return make_error(
                std::format("{}:{}: the file ends before {}", name_, line_, what),
                "The photometric data is the header line of numbers, the ballast line, the vertical angles, the "
                "horizontal angles and then one row of candela values per horizontal angle; the file looks cut short. "
                "Export the profile again from the lamp's catalogue or the photometry tool.");
        double v = 0;
        if (!parse_number(t.text, v))
            return line_error(name_, t.line, std::format("'{}' is not a number where {} should be", t.text, what),
                              "After the TILT line an .ies file holds only numbers; a word here means the file is not "
                              "photometric data, or an earlier count is wrong so the numbers shifted.");
        return v;
    }

    int line() const { return line_; }

private:
    std::string_view text_;
    std::size_t pos_ = 0;
    int line_;
    std::string_view name_;
};

bool whole(double v, int lo, int hi, int& out) {
    if (!(v >= double(lo) && v <= double(hi)) || v != std::floor(v)) return false;
    out = int(v);
    return true;
}

}  // namespace

float IesProfile::candela_at(float horizontalDeg, float verticalDeg) const {
    if (vertical.empty() || horizontal.empty() || candela.size() != vertical.size() * horizontal.size()) return 0.0f;
    const std::size_t nv = vertical.size(), nh = horizontal.size();
    if (!(verticalDeg >= vertical.front() - 1e-4f && verticalDeg <= vertical.back() + 1e-4f)) return 0.0f;
    // The vertical segment.
    std::size_t v1 = std::upper_bound(vertical.begin(), vertical.end(), verticalDeg) - vertical.begin();
    if (v1 >= nv) v1 = nv - 1;
    const std::size_t v0 = v1 > 0 ? v1 - 1 : 0;
    const float vspan = vertical[v1] - vertical[v0];
    const float vt = vspan > 1e-6f ? std::clamp((verticalDeg - vertical[v0]) / vspan, 0.0f, 1.0f) : 0.0f;
    auto plane = [&](std::size_t h) {
        return candela[h * nv + v0] + (candela[h * nv + v1] - candela[h * nv + v0]) * vt;
    };
    if (nh == 1) return plane(0);
    // The horizontal angle folded into the range the table covers.
    float h = std::fmod(horizontalDeg, 360.0f);
    if (h < 0.0f) h += 360.0f;
    const float last = horizontal.back();
    if (last <= 90.5f) {
        if (h > 180.0f) h = 360.0f - h;
        if (h > 90.0f) h = 180.0f - h;
    } else if (last <= 180.5f) {
        if (h > 180.0f) h = 360.0f - h;
    }
    std::size_t h0, h1;
    float ht;
    if (h >= last) {
        if (last >= 359.5f || last <= 180.5f)
            return plane(nh - 1);  // the closing plane, or the edge of a symmetric table
        // A full table whose last plane is short of 360 degrees: the way back to plane 0 wraps.
        h0 = nh - 1;
        h1 = 0;
        ht = std::clamp((h - last) / (360.0f - last), 0.0f, 1.0f);
    } else {
        h1 = std::upper_bound(horizontal.begin(), horizontal.end(), h) - horizontal.begin();
        if (h1 >= nh) h1 = nh - 1;
        h0 = h1 > 0 ? h1 - 1 : 0;
        const float hspan = horizontal[h1] - horizontal[h0];
        ht = hspan > 1e-6f ? std::clamp((h - horizontal[h0]) / hspan, 0.0f, 1.0f) : 0.0f;
    }
    const float a = plane(h0), b = plane(h1);
    return a + (b - a) * ht;
}

Result<IesProfile> parse_ies(std::string_view text, std::string_view name) {
    if (text.size() >= 3 && text.substr(0, 3) == "\xEF\xBB\xBF") text.remove_prefix(3);  // a UTF-8 byte order mark
    IesProfile p;
    // The header: keyword lines up to the TILT line.
    int line = 0;
    std::size_t pos = 0;
    bool haveTilt = false;
    std::string tilt;
    std::string luminaire, test;
    while (pos <= text.size() && !haveTilt) {
        std::size_t end = text.find('\n', pos);
        if (end == std::string_view::npos) end = text.size();
        const std::string_view raw = trim_ws(text.substr(pos, end - pos));
        pos = end + 1;
        ++line;
        if (raw.empty()) {
            if (end >= text.size()) break;
            continue;
        }
        if (line == 1 && upper(raw).rfind("IESNA", 0) == 0) {
            p.version = std::string(raw);
            continue;
        }
        const std::string up = upper(raw);
        if (up.rfind("TILT", 0) == 0) {
            const std::size_t eq = raw.find('=');
            if (eq == std::string_view::npos)
                return line_error(name, line, "the TILT line has no '='",
                                  "Write `TILT=NONE` (the engine does not use a lamp's tilt table).");
            tilt = upper(trim_ws(raw.substr(eq + 1)));
            haveTilt = true;
            continue;
        }
        if (raw.front() == '[') {
            const std::size_t close = raw.find(']');
            if (close == std::string_view::npos)
                return line_error(name, line, "a keyword line starts with '[' and has no closing ']'",
                                  "Keywords look like `[MANUFAC] Name`; check the line or delete it.");
            const std::string key = upper(raw.substr(1, close - 1));
            const std::string rest(trim_ws(raw.substr(close + 1)));
            if (key == "LUMINAIRE" && luminaire.empty()) luminaire = rest;
            if (key == "TEST" && test.empty()) test = rest;
            continue;
        }
        // Anything else before TILT is a continuation of a keyword (the format allows it) or free text: skipped.
    }
    if (!haveTilt)
        return make_error(
            std::format("{}: there is no TILT= line, so this is not an IES photometric file", name),
            "An .ies file (IESNA LM-63) starts with `IESNA:LM-63-2002`, has `[KEYWORD]` lines and a `TILT=NONE` line "
            "before the numbers. Export the profile from the lamp maker's download or the photometry tool as .ies.");
    p.name = !luminaire.empty() ? luminaire : test;
    Numbers in(text.substr(std::min(pos, text.size())), line + 1, name);
    // TILT=INCLUDE: lamp-to-luminaire geometry, the number of tilt angles, the angles and the factors; read and dropped.
    if (tilt == "INCLUDE") {
        auto geometry = in.number("the lamp-to-luminaire geometry of the TILT=INCLUDE block");
        if (!geometry) return geometry.error();
        auto count = in.number("the number of tilt angles of the TILT=INCLUDE block");
        if (!count) return count.error();
        int n = 0;
        if (!whole(*count, 0, 1024, n))
            return line_error(name, in.line(), std::format("the number of tilt angles is {}", *count),
                              "It is a whole number from 0 to 1024; or write TILT=NONE, the tilt is not used.");
        for (int i = 0; i < 2 * n; ++i) {
            auto v = in.number("a value of the TILT=INCLUDE block");
            if (!v) return v.error();
        }
    }
    // The photometric header.
    auto lamps = in.number("the number of lamps");
    if (!lamps) return lamps.error();
    auto lumens = in.number("the lumens per lamp");
    if (!lumens) return lumens.error();
    auto multiplier = in.number("the candela multiplying factor");
    if (!multiplier) return multiplier.error();
    auto nvNum = in.number("the number of vertical angles");
    if (!nvNum) return nvNum.error();
    const int headerLine = in.line();
    auto nhNum = in.number("the number of horizontal angles");
    if (!nhNum) return nhNum.error();
    auto typeNum = in.number("the photometric type");
    if (!typeNum) return typeNum.error();
    auto unitsNum = in.number("the units type");
    if (!unitsNum) return unitsNum.error();
    for (const char* what : {"the width of the luminous opening", "its length", "its height", "the ballast factor",
                             "the ballast-lamp photometric factor", "the input watts"}) {
        auto v = in.number(what);
        if (!v) return v.error();
    }
    int nv = 0, nh = 0, type = 0, units = 0;
    if (!whole(*nvNum, 1, kIesMaxVerticalAngles, nv))
        return line_error(name, headerLine, std::format("the number of vertical angles is {}", *nvNum),
                          std::format("It is a whole number from 1 to {}; check the 10 numbers after the TILT line "
                                      "(lamps, lumens, multiplier, vertical angles, horizontal angles, type, units, "
                                      "width, length, height).",
                                      kIesMaxVerticalAngles));
    if (!whole(*nhNum, 1, kIesMaxHorizontalAngles, nh))
        return line_error(name, headerLine, std::format("the number of horizontal angles is {}", *nhNum),
                          std::format("It is a whole number from 1 to {}; check the 10 numbers after the TILT line.",
                                      kIesMaxHorizontalAngles));
    if (!whole(*typeNum, 1, 3, type))
        return line_error(name, headerLine, std::format("the photometric type is {}", *typeNum),
                          "It is 1 (type C), 2 (type B) or 3 (type A); check the 10 numbers after the TILT line.");
    if (type != 1)
        return line_error(
            name, headerLine,
            std::format("this profile is photometric type {} (a goniometer that turns about a horizontal axis)",
                        type == 2 ? "B" : "A"),
            "Only type C (a vertical angle from the nadir around the vertical axis) is supported, which is "
            "what lamp catalogues and photometry tools export by default. Export the profile again as type C.");
    if (!whole(*unitsNum, 1, 2, units))
        units = 2;  // the units only size the opening; a wrong value is not worth an error
    if (!(*multiplier > 0.0) || !std::isfinite(*multiplier))
        return line_error(name, headerLine, std::format("the candela multiplying factor is {}", *multiplier),
                          "It must be above 0 (1 for most files).");
    if (std::size_t(nv) * std::size_t(nh) > kIesMaxValues)
        return line_error(name, headerLine, std::format("{} x {} candela values are too many", nv, nh),
                          std::format("A profile holds at most {} values; export one with fewer angles (a "
                                      "5 degree step is plenty).",
                                      kIesMaxValues));
    p.photometricType = type;
    p.units = units;
    p.lampLumens = *lumens;
    p.multiplier = *multiplier;
    // The angles.
    p.vertical.resize(std::size_t(nv));
    for (int i = 0; i < nv; ++i) {
        auto v = in.number("a vertical angle");
        if (!v) return v.error();
        const int l = in.line();
        if (!(*v >= 0.0 && *v <= 180.0))
            return line_error(
                name, l, std::format("the vertical angle {} is outside 0 to 180 degrees", *v),
                "Type C vertical angles go from 0 (the nadir, straight down the lamp's axis) to 180 (straight up).");
        if (i > 0 && !(*v > double(p.vertical[std::size_t(i) - 1])))
            return line_error(name, l,
                              std::format("the vertical angles are not ascending ({} comes after {})", *v,
                                          p.vertical[std::size_t(i) - 1]),
                              "List the vertical angles in increasing order, each one once.");
        p.vertical[std::size_t(i)] = float(*v);
    }
    p.horizontal.resize(std::size_t(nh));
    for (int i = 0; i < nh; ++i) {
        auto v = in.number("a horizontal angle");
        if (!v) return v.error();
        const int l = in.line();
        if (!(*v >= 0.0 && *v <= 360.0))
            return line_error(name, l, std::format("the horizontal angle {} is outside 0 to 360 degrees", *v),
                              "Type C horizontal angles go from 0 to 360 degrees around the lamp's axis.");
        if (i > 0 && !(*v > double(p.horizontal[std::size_t(i) - 1])))
            return line_error(name, l,
                              std::format("the horizontal angles are not ascending ({} comes after {})", *v,
                                          p.horizontal[std::size_t(i) - 1]),
                              "List the horizontal angles in increasing order, each one once.");
        p.horizontal[std::size_t(i)] = float(*v);
    }
    if (nh > 1) {
        const float first = p.horizontal.front(), last = p.horizontal.back();
        const bool ok = std::fabs(first) < 1e-3f &&
                        (std::fabs(last - 90.0f) < 1e-3f || std::fabs(last - 180.0f) < 1e-3f || last > 180.5f);
        if (!ok)
            return line_error(
                name, in.line(), std::format("the horizontal angles run from {} to {} degrees", first, last),
                "The renderer reads tables that start at 0 and end at 90 (four-fold symmetry), 180 (two-fold) or go "
                "all around (up to 360). A table from 90 to 270 degrees is not supported: export the profile with the "
                "full 0 to 360 range.");
    }
    // The candela table: one row of nv values per horizontal angle.
    p.candela.resize(std::size_t(nv) * std::size_t(nh));
    float maxValue = 0.0f;
    for (std::size_t i = 0; i < p.candela.size(); ++i) {
        auto v = in.number("a candela value");
        if (!v) return v.error();
        if (!(*v >= 0.0))
            return line_error(name, in.line(), std::format("the candela value {} is negative", *v),
                              "Candela values are intensities, 0 or more.");
        const float c = float(*v * *multiplier);
        if (!std::isfinite(c))
            return line_error(name, in.line(), std::format("the candela value {} is too large", *v),
                              "Check the candela multiplying factor and the values.");
        p.candela[i] = c;
        maxValue = std::max(maxValue, c);
    }
    if (!(maxValue > 0.0f))
        return make_error(std::format("{}: every candela value is 0, so the lamp emits no light", name),
                          "Export the profile again; a lamp's table has values above 0 where it shines.");
    p.maxCandela = maxValue;
    return p;
}

std::vector<float> ies_bake(const IesProfile& profile) {
    std::vector<float> out(std::size_t(kIesBakeWidth) * std::size_t(kIesBakeHeight), 0.0f);
    const float inv = profile.maxCandela > 0.0f ? 1.0f / profile.maxCandela : 0.0f;
    for (int j = 0; j < kIesBakeHeight; ++j)
        for (int i = 0; i < kIesBakeWidth; ++i) {
            const float h = (float(i) + 0.5f) / float(kIesBakeWidth) * 360.0f;
            const float v = (float(j) + 0.5f) / float(kIesBakeHeight) * 180.0f;
            out[std::size_t(j) * std::size_t(kIesBakeWidth) + std::size_t(i)] =
                std::clamp(profile.candela_at(h, v) * inv, 0.0f, 1.0f);
        }
    return out;
}

}  // namespace fa
