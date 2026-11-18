#include "fa/render/cube_lut.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <format>

#include "fa/core/strings.h"

namespace fa {

namespace {

// A decimal number: sign, digits, a point, an exponent. Not strtod (the C locale may use a comma) and not NaN / inf: a LUT never holds
// them, and they must be an error with a line, not a silent hole in the picture.
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
                ++scale;  // more digits than a double keeps: only their place counts
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

// Splits on spaces, tabs and the CR of a CRLF file.
std::size_t tokens(std::string_view line, std::string_view* out, std::size_t max) {
    std::size_t n = 0, i = 0;
    while (i < line.size()) {
        while (i < line.size() && (line[i] == ' ' || line[i] == '\t' || line[i] == '\r')) ++i;
        if (i >= line.size()) break;
        const std::size_t start = i;
        while (i < line.size() && line[i] != ' ' && line[i] != '\t' && line[i] != '\r') ++i;
        if (n < max) out[n] = line.substr(start, i - start);
        ++n;
    }
    return n;
}

Error line_error(std::string_view name, int line, const std::string& what, const std::string& hint) {
    return make_error(std::format("{}:{}: {}", name, line, what), hint);
}

const std::vector<std::string>& keywords() {
    static const std::vector<std::string> k = {"TITLE",          "DOMAIN_MIN",         "DOMAIN_MAX",
                                               "LUT_3D_SIZE",    "LUT_3D_INPUT_RANGE", "LUT_1D_SIZE",
                                               "LUT_1D_INPUT_RANGE"};
    return k;
}

}  // namespace

Result<CubeLut> parse_cube_lut(std::string_view text, std::string_view name) {
    if (text.size() >= 3 && text.substr(0, 3) == "\xEF\xBB\xBF") text.remove_prefix(3);  // a UTF-8 byte order mark
    CubeLut lut;
    std::size_t expected = 0;
    int line = 0, dataLine = 0;
    std::size_t pos = 0;
    while (pos <= text.size()) {
        std::size_t end = text.find('\n', pos);
        if (end == std::string_view::npos) end = text.size();
        const std::string_view raw = text.substr(pos, end - pos);
        pos = end + 1;
        ++line;
        std::string_view tok[8];
        const std::size_t n = tokens(raw, tok, 8);
        if (n == 0 || tok[0][0] == '#') continue;
        const char first = tok[0][0];
        const bool keyword = (first >= 'A' && first <= 'Z') || (first >= 'a' && first <= 'z');
        if (!keyword) {
            // A colour: three numbers.
            if (lut.size == 0)
                return line_error(name, line, "a colour row comes before LUT_3D_SIZE",
                                  "Put `LUT_3D_SIZE <n>` (16, 32 or 64 for most files) before the first row of colours.");
            double v[3];
            if (n != 3 || !parse_number(tok[0], v[0]) || !parse_number(tok[1], v[1]) || !parse_number(tok[2], v[2]))
                return line_error(name, line, std::format("'{}' is not a colour of three numbers", trim(raw)),
                                  "Each row holds the red, green and blue of one entry, like `0.25 0.5 0.75`.");
            if (lut.rgb.size() >= expected * 3)
                return line_error(name, line,
                                  std::format("there are more colour rows than the {}x{}x{} = {} that LUT_3D_SIZE {} announces",
                                              lut.size, lut.size, lut.size, expected, lut.size),
                                  "Fix LUT_3D_SIZE or cut the extra rows; the file must hold exactly size^3 rows.");
            for (double c : v) lut.rgb.push_back(float(c));
            dataLine = line;
            continue;
        }
        std::string key(tok[0]);
        std::transform(key.begin(), key.end(), key.begin(), [](unsigned char c) { return char(std::toupper(c)); });
        if (key == "TITLE") {
            const std::size_t at = raw.find("TITLE");
            std::string_view rest = at == std::string_view::npos ? std::string_view() : raw.substr(at + 5);
            rest = trim(rest);
            if (rest.size() >= 2 && rest.front() == '"' && rest.back() == '"') rest = rest.substr(1, rest.size() - 2);
            lut.title = std::string(rest);
        } else if (key == "LUT_3D_SIZE") {
            double v = 0;
            if (n != 2 || !parse_number(tok[1], v) || v != std::floor(v))
                return line_error(name, line, "LUT_3D_SIZE needs one whole number",
                                  "Write it like `LUT_3D_SIZE 32`.");
            if (lut.size != 0)
                return line_error(name, line, "LUT_3D_SIZE appears twice", "Keep one LUT_3D_SIZE line.");
            if (v < kCubeLutMinSize || v > kCubeLutMaxSize)
                return line_error(name, line,
                                  std::format("LUT_3D_SIZE {} is outside {} to {}", v, kCubeLutMinSize, kCubeLutMaxSize),
                                  "Export the table with 16, 32 or 64 entries per side (17, 33 and 65 work too).");
            lut.size = int(v);
            expected = std::size_t(lut.size) * std::size_t(lut.size) * std::size_t(lut.size);
            lut.rgb.reserve(expected * 3);
        } else if (key == "LUT_1D_SIZE") {
            return line_error(name, line, "this is a 1D LUT (LUT_1D_SIZE); only 3D tables are drawn",
                              "Export a 3D LUT from the grading tool (LUT_3D_SIZE 32 or 64).");
        } else if (key == "DOMAIN_MIN" || key == "DOMAIN_MAX" || key == "LUT_3D_INPUT_RANGE" ||
                   key == "LUT_1D_INPUT_RANGE") {
            const bool range = key.find("INPUT_RANGE") != std::string::npos;
            const std::size_t want = range ? 2 : 3;
            double v[3] = {0, 0, 0};
            bool good = n == want + 1;
            for (std::size_t i = 0; good && i < want; ++i) good = parse_number(tok[i + 1], v[i]);
            if (!good)
                return line_error(name, line, std::format("{} needs {} numbers", key, want),
                                  range ? "Write `LUT_3D_INPUT_RANGE 0.0 1.0`." : "Write it like `DOMAIN_MIN 0.0 0.0 0.0`.");
            const bool isMax = key == "DOMAIN_MAX" || range;
            for (std::size_t i = 0; i < want; ++i) {
                const double expect = range ? (i == 0 ? 0.0 : 1.0) : (isMax ? 1.0 : 0.0);
                if (std::fabs(v[i] - expect) > 1e-6)
                    return line_error(name, line,
                                      std::format("{} is not the 0 to 1 input range the final pass looks tables up in", key),
                                      "Export the LUT with the standard 0 to 1 domain (DOMAIN_MIN 0 0 0, DOMAIN_MAX 1 1 1).");
            }
        } else {
            return line_error(name, line, std::format("unknown keyword '{}'", tok[0]),
                              "A .cube file has TITLE, DOMAIN_MIN, DOMAIN_MAX, LUT_3D_SIZE and then size^3 rows of three "
                              "numbers." +
                                  did_you_mean(key, keywords()));
        }
    }
    if (lut.size == 0)
        return make_error(std::format("{}: there is no LUT_3D_SIZE line, so this is not a 3D .cube table", name),
                          "Export a 3D LUT from the grading tool; its header says `LUT_3D_SIZE 32`.");
    if (lut.rgb.size() != expected * 3)
        return make_error(std::format("{}:{}: the table holds {} colour rows but LUT_3D_SIZE {} announces {}", name,
                                      dataLine > 0 ? dataLine : line, lut.rgb.size() / 3, lut.size, expected),
                          "The file is cut short or LUT_3D_SIZE is wrong: it must hold exactly size^3 rows (red varies "
                          "fastest).");
    return lut;
}

Vec3 CubeLut::sample(Vec3 c) const {
    if (size < 2 || rgb.size() != std::size_t(size) * size * size * 3) return c;
    const float m = float(size - 1);
    const float x = saturate(c.x) * m, y = saturate(c.y) * m, z = saturate(c.z) * m;
    const int x0 = std::min(int(x), size - 1), y0 = std::min(int(y), size - 1), z0 = std::min(int(z), size - 1);
    const int x1 = std::min(x0 + 1, size - 1), y1 = std::min(y0 + 1, size - 1), z1 = std::min(z0 + 1, size - 1);
    const float fx = x - float(x0), fy = y - float(y0), fz = z - float(z0);
    auto plane = [&](int zi) {
        const Vec3 a = lerp(at(x0, y0, zi), at(x1, y0, zi), fx);
        const Vec3 b = lerp(at(x0, y1, zi), at(x1, y1, zi), fx);
        return lerp(a, b, fy);
    };
    return lerp(plane(z0), plane(z1), fz);
}

CubeLutStrip cube_lut_strip(const CubeLut& lut) {
    CubeLutStrip s;
    s.size = lut.size;
    s.cols = int(std::ceil(std::sqrt(double(lut.size))));
    s.rows = (lut.size + s.cols - 1) / s.cols;
    const int w = s.width(), h = s.height();
    s.rgba.assign(std::size_t(w) * std::size_t(h) * 4, 0);
    auto byte = [](float v) { return std::uint8_t(std::lround(saturate(std::isfinite(v) ? v : 0.0f) * 255.0f)); };
    for (int b = 0; b < lut.size; ++b) {
        const int ox = (b % s.cols) * lut.size, oy = (b / s.cols) * lut.size;
        for (int g = 0; g < lut.size; ++g)
            for (int r = 0; r < lut.size; ++r) {
                const Vec3 c = lut.at(r, g, b);
                std::uint8_t* p = &s.rgba[(std::size_t(oy + g) * std::size_t(w) + std::size_t(ox + r)) * 4];
                p[0] = byte(c.x);
                p[1] = byte(c.y);
                p[2] = byte(c.z);
                p[3] = 255;
            }
    }
    return s;
}

}  // namespace fa
