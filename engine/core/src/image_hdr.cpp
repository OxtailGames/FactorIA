// Radiance RGBE (.hdr) reader and writer (fa/core/image_float.h). Format: Greg Ward, "Real Pixels" (Graphics Gems II) and
// the Radiance file format notes: a text header, a resolution line, then one scanline per row, each pixel 4 bytes
// (R, G, B mantissas and a shared exponent).
#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <format>
#include <limits>
#include <new>
#include <optional>
#include <string>

#include "fa/core/fs.h"
#include "fa/core/image_float.h"

namespace fa {

namespace {

constexpr std::size_t kMaxHeaderBytes = 16384;  // the header and resolution line together
constexpr std::size_t kMaxHeaderLine = 1024;

const char* const kReexportHint =
    "Re-export the picture as a Radiance HDR file (RGBE, .hdr) from your image or HDRI tool. OpenEXR, TIFF and other "
    "formats are not read.";

Error hdr_error(std::size_t offset, const std::string& what, const std::string& hint = kReexportHint) {
    return make_error(std::format("Cannot decode HDR image: {} (at byte {})", what, offset), hint);
}

// Header text shown in an error: printable ASCII only, short.
std::string shown(std::string_view text) {
    std::string s;
    for (char ch : text.substr(0, 48)) s += (ch >= 32 && ch < 127) ? ch : '?';
    if (text.size() > 48) s += "...";
    return s;
}

enum class LineStatus { Ok, Truncated, TooLong };

// One header line from `pos` (without its "\n" and an optional "\r"); `pos` moves past the "\n".
LineStatus read_line(const std::uint8_t* data, std::size_t size, std::size_t& pos, std::string_view& line) {
    const std::size_t start = pos;
    while (pos < size && data[pos] != '\n') {
        if (pos - start >= kMaxHeaderLine || pos >= kMaxHeaderBytes) return LineStatus::TooLong;
        ++pos;
    }
    if (pos >= size) return LineStatus::Truncated;
    std::size_t end = pos;
    ++pos;  // the "\n"
    if (end > start && data[end - 1] == '\r') --end;
    line = std::string_view(reinterpret_cast<const char*>(data) + start, end - start);
    return LineStatus::Ok;
}

// A positive decimal number ("2.5", "1e-3"), parsed without the C locale (a decimal comma must not change a file's meaning).
std::optional<double> parse_positive_number(std::string_view s) {
    std::size_t i = 0;
    while (i < s.size() && (s[i] == ' ' || s[i] == '\t')) ++i;
    std::size_t end = s.size();
    while (end > i && (s[end - 1] == ' ' || s[end - 1] == '\t')) --end;
    s = s.substr(i, end - i);
    double mantissa = 0;
    int exp10 = 0, digits = 0;
    bool seenDot = false;
    std::size_t k = 0;
    for (; k < s.size(); ++k) {
        const char ch = s[k];
        if (ch == '.' && !seenDot) {
            seenDot = true;
        } else if (ch >= '0' && ch <= '9') {
            ++digits;
            if (digits <= 18) {
                mantissa = mantissa * 10 + (ch - '0');
                if (seenDot) --exp10;
            } else if (!seenDot) {
                ++exp10;  // digits beyond the precision still scale the number
            }
        } else {
            break;
        }
    }
    if (digits == 0) return std::nullopt;
    if (k < s.size() && (s[k] == 'e' || s[k] == 'E')) {
        ++k;
        bool neg = false;
        if (k < s.size() && (s[k] == '+' || s[k] == '-')) neg = s[k++] == '-';
        int e = 0, edigits = 0;
        for (; k < s.size() && s[k] >= '0' && s[k] <= '9'; ++k, ++edigits) e = std::min(e * 10 + (s[k] - '0'), 10000);
        if (edigits == 0) return std::nullopt;
        exp10 += neg ? -e : e;
    }
    if (k != s.size()) return std::nullopt;
    if (mantissa == 0) return 0.0;
    // Scaling by 10 one step at a time (not std::pow: no C library maths in code that decides what a file means); beyond
    // e+-400 the result is infinity or 0 anyway, and a caller refuses both.
    double value = mantissa;
    for (int i = 0, n = std::min(std::abs(exp10), 400); i < n; ++i) value = exp10 >= 0 ? value * 10.0 : value / 10.0;
    return value;
}

std::optional<std::int64_t> parse_int(std::string_view s) {
    if (s.empty() || s.size() > 10) return std::nullopt;
    std::int64_t v = 0;
    for (char ch : s) {
        if (ch < '0' || ch > '9') return std::nullopt;
        v = v * 10 + (ch - '0');
    }
    return v;
}

std::vector<std::string_view> split_spaces(std::string_view line) {
    std::vector<std::string_view> out;
    std::size_t i = 0;
    while (i < line.size()) {
        while (i < line.size() && (line[i] == ' ' || line[i] == '\t')) ++i;
        const std::size_t start = i;
        while (i < line.size() && line[i] != ' ' && line[i] != '\t') ++i;
        if (i > start) out.push_back(line.substr(start, i - start));
    }
    return out;
}

bool starts_with(std::string_view s, std::string_view prefix) { return s.substr(0, prefix.size()) == prefix; }

void rgbe_to_floats(const std::uint8_t* p, float* out) {
    if (p[3] == 0) {
        out[0] = out[1] = out[2] = 0.0f;
        return;
    }
    const float f = std::ldexp(1.0f, int(p[3]) - (128 + 8));
    out[0] = float(p[0]) * f;
    out[1] = float(p[1]) * f;
    out[2] = float(p[2]) * f;
}

struct ScanlineFailure {
    std::size_t offset = 0;
    std::string what;
};

// Reads one row of `w` RGBE pixels at `pos` into `row` (w * 4 bytes). False with `fail` set on truncated or corrupt data.
bool read_scanline(const std::uint8_t* d, std::size_t n, std::size_t& pos, int w, std::uint8_t* row, ScanlineFailure& fail) {
    const std::size_t width = std::size_t(w);
    auto truncated = [&](std::size_t at) {
        fail = {at, "the file ends in the middle of a row"};
        return false;
    };
    if (w >= 8 && w <= 32767 && n - pos >= 4 && d[pos] == 2 && d[pos + 1] == 2 && (d[pos + 2] & 0x80) == 0) {
        // New-style run-length scanline: the marker (2, 2, width high, width low), then each of the four channels in turn
        // as runs (code > 128: code - 128 copies of the next byte) and literals (code 1..128: that many bytes).
        const std::size_t claimed = (std::size_t(d[pos + 2]) << 8) | d[pos + 3];
        if (claimed != width) {
            fail = {pos, std::format("a run-length row is {} pixels wide but the header says {}", claimed, w)};
            return false;
        }
        pos += 4;
        for (std::size_t c = 0; c < 4; ++c) {
            std::size_t x = 0;
            while (x < width) {
                if (pos >= n) return truncated(pos);
                const std::size_t code = d[pos++];
                if (code > 128) {
                    const std::size_t count = code - 128;
                    if (x + count > width) {
                        fail = {pos - 1, "a run goes past the end of its row"};
                        return false;
                    }
                    if (pos >= n) return truncated(pos);
                    const std::uint8_t value = d[pos++];
                    for (std::size_t i = 0; i < count; ++i) row[(x + i) * 4 + c] = value;
                    x += count;
                } else {
                    const std::size_t count = code;
                    if (count == 0) {
                        fail = {pos - 1, "a literal of length 0 in a run-length row"};
                        return false;
                    }
                    if (x + count > width) {
                        fail = {pos - 1, "a literal goes past the end of its row"};
                        return false;
                    }
                    if (n - pos < count) return truncated(n);
                    for (std::size_t i = 0; i < count; ++i) row[(x + i) * 4 + c] = d[pos + i];
                    pos += count;
                    x += count;
                }
            }
        }
        return true;
    }
    // Flat pixels, with the old-style repeat marker (1, 1, 1, n): n more copies of the pixel before it, and each marker that
    // follows another is worth 256 times more (n << 8, n << 16).
    std::size_t x = 0;
    unsigned shift = 0;
    while (x < width) {
        if (n - pos < 4) return truncated(n);
        const std::uint8_t* p = d + pos;
        if (p[0] == 1 && p[1] == 1 && p[2] == 1) {
            if (x == 0) {
                fail = {pos, "a repeat marker before the first pixel of a row"};
                return false;
            }
            if (shift > 16) {
                fail = {pos, "too many repeat markers in a row"};
                return false;
            }
            const std::size_t count = std::size_t(p[3]) << shift;
            if (x + count > width) {
                fail = {pos, "a repeat goes past the end of its row"};
                return false;
            }
            for (std::size_t i = 0; i < count; ++i) std::memcpy(row + (x + i) * 4, row + (x - 1) * 4, 4);
            x += count;
            shift += 8;
        } else {
            std::memcpy(row + x * 4, p, 4);
            ++x;
            shift = 0;
        }
        pos += 4;
    }
    return true;
}

}  // namespace

Result<ImageF> decode_hdr(const std::uint8_t* data, std::size_t size) {
    if (!data || size == 0)
        return hdr_error(0, "the file is empty");
    std::size_t pos = 0;
    std::string_view line;
    auto line_error = [&](LineStatus st, const char* where) {
        return st == LineStatus::TooLong
                   ? hdr_error(pos, std::format("a header line is longer than {} bytes ({}): this is not a Radiance file",
                                                kMaxHeaderLine, where))
                   : hdr_error(size, std::format("the file ends inside the header ({})", where));
    };

    // 1. The signature line.
    if (size < 2 || data[0] != '#' || data[1] != '?') {
        if (size >= 4 && data[0] == 0x76 && data[1] == 0x2f && data[2] == 0x31 && data[3] == 0x01)
            return hdr_error(0, "this is an OpenEXR file, not a Radiance .hdr");
        return hdr_error(0, "it does not start with '#?RADIANCE' or '#?RGBE': this is not a Radiance .hdr file");
    }
    LineStatus st = read_line(data, size, pos, line);
    if (st != LineStatus::Ok) return line_error(st, "first line");

    // 2. Header variables up to the empty line.
    double exposure = 1.0;
    for (;;) {
        const std::size_t lineStart = pos;
        st = read_line(data, size, pos, line);
        if (st != LineStatus::Ok) return line_error(st, "before the empty line that ends it");
        if (pos > kMaxHeaderBytes) return hdr_error(lineStart, std::format("the header is longer than {} bytes", kMaxHeaderBytes));
        if (line.empty()) break;
        if (line[0] == '#') continue;
        if (starts_with(line, "FORMAT=")) {
            const std::string_view format = line.substr(7);
            if (format == "32-bit_rle_xyze")
                return hdr_error(lineStart, "the pixels are XYZE (FORMAT=32-bit_rle_xyze), not RGBE",
                                 "Re-export the picture as RGBE (FORMAT=32-bit_rle_rgbe): in Radiance, convert it with "
                                 "'ra_xyze -r', in an image editor save it as Radiance HDR.");
            if (format != "32-bit_rle_rgbe")
                return hdr_error(lineStart, std::format("FORMAT is '{}', only 32-bit_rle_rgbe is read", shown(format)));
        } else if (starts_with(line, "EXPOSURE=")) {
            const auto value = parse_positive_number(line.substr(9));
            if (!value || !(*value > 0.0) || !std::isfinite(*value))
                return hdr_error(lineStart, std::format("'{}' is not a positive EXPOSURE", shown(line)),
                                 "Remove the EXPOSURE line or give a positive number such as EXPOSURE=1.0.");
            exposure *= *value;
            if (!std::isfinite(exposure) || exposure <= 0.0 || exposure > 1.0e30 || exposure < 1.0e-30)
                return hdr_error(lineStart, "the EXPOSURE lines multiply to a value outside 1e-30..1e30");
        }
        // Other variables (SOFTWARE=, PRIMARIES=, GAMMA=, VIEW=...) do not change the pixels.
    }

    // 3. The resolution line: only "-Y <height> +X <width>".
    const std::size_t resStart = pos;
    st = read_line(data, size, pos, line);
    if (st != LineStatus::Ok) return line_error(st, "the resolution line is missing");
    const auto tokens = split_spaces(line);
    if (tokens.size() != 4 || (tokens[0] != "-Y" && tokens[0] != "+Y" && tokens[0] != "-X" && tokens[0] != "+X"))
        return hdr_error(resStart, std::format("the resolution line '{}' is not '-Y <height> +X <width>'", shown(line)),
                         "Re-save the picture as a standard Radiance HDR file: its size line reads '-Y 512 +X 1024'.");
    if (tokens[0] != "-Y" || tokens[2] != "+X")
        return hdr_error(resStart,
                         std::format("the orientation '{}' is not supported (the rows must run top to bottom and left "
                                     "to right: '-Y <height> +X <width>')",
                                     shown(line)),
                         "Flip or rotate the picture in your image editor, or re-export it from your HDRI tool with the "
                         "default orientation, so that its size line reads '-Y <height> +X <width>'.");
    const auto parsedH = parse_int(tokens[1]), parsedW = parse_int(tokens[3]);
    if (!parsedH || !parsedW || *parsedH < 1 || *parsedW < 1)
        return hdr_error(resStart, std::format("the size '{}' is not two positive whole numbers", shown(line)));
    if (*parsedH > kMaxImageFloatSide || *parsedW > kMaxImageFloatSide)
        return hdr_error(resStart,
                         std::format("the picture is {} x {} pixels, more than the {} pixels per side the engine reads",
                                     *parsedW, *parsedH, kMaxImageFloatSide),
                         "Scale the picture down (an 8192 x 4096 panorama is enough for an environment map).");
    const int w = int(*parsedW), h = int(*parsedH);
    const std::uint64_t bytes = image_float_bytes(w, h, 3);
    if (bytes > kMaxImageFloatBytes)
        return hdr_error(resStart,
                         std::format("the picture is {} x {} pixels: its floats need {} MB, more than the {} MB the "
                                     "engine allows",
                                     w, h, bytes / (1024 * 1024), kMaxImageFloatBytes / (1024 * 1024)),
                         "Scale the picture down: an 8192 x 4096 panorama is enough for an environment map.");

    // 4. Pixels. The sizes passed the budget, but the memory is taken row by row as the data proves itself (a few bytes
    // that claim a huge picture never ask for its memory): the capacity doubles up to the full size, never beyond it.
    ImageF img;
    img.width = w;
    img.height = h;
    img.channels = 3;
    img.exposure = float(exposure);
    const std::size_t rowFloats = std::size_t(w) * 3, total = rowFloats * std::size_t(h);
    std::vector<std::uint8_t> row(std::size_t(w) * 4);
    try {
        for (int y = 0; y < h; ++y) {
            ScanlineFailure fail;
            if (!read_scanline(data, size, pos, w, row.data(), fail))
                return hdr_error(fail.offset, std::format("{} (row {} of {})", fail.what, y + 1, h),
                                 "The file is damaged or cut short: download or export it again.");
            const std::size_t need = std::size_t(y + 1) * rowFloats;
            if (img.data.capacity() < need)
                img.data.reserve(std::min(total, std::max({need, img.data.capacity() * 2, std::size_t(1) << 20})));
            img.data.resize(need);
            float* out = &img.data[std::size_t(y) * rowFloats];
            for (int x = 0; x < w; ++x) rgbe_to_floats(&row[std::size_t(x) * 4], out + std::size_t(x) * 3);
        }
    } catch (const std::bad_alloc&) {
        return hdr_error(pos, std::format("out of memory for a {} x {} picture", w, h),
                         "Close other programs or scale the picture down.");
    }
    return img;
}

Result<ImageF> load_hdr(std::string_view path) {
    auto bytes = fs::read_bytes(path);
    if (!bytes) return bytes.error();
    auto img = decode_hdr(bytes->data(), bytes->size());
    if (!img) return make_error("'" + std::string(path) + "': " + img.error().message, img.error().hint);
    return img;
}

namespace {

void to_rgbe(float r, float g, float b, std::uint8_t out[4]) {
    auto clean = [](float v) {
        if (!(v > 0.0f)) return 0.0f;  // negative and NaN
        return std::min(v, std::numeric_limits<float>::max());
    };
    const float v[3] = {clean(r), clean(g), clean(b)};
    const float maxc = std::max({v[0], v[1], v[2]});
    out[0] = out[1] = out[2] = out[3] = 0;
    if (maxc < 1.0e-37f) return;
    int e = 0;
    std::frexp(maxc, &e);  // maxc = f * 2^e, f in [0.5, 1)
    e = std::min(e, 127);  // above 2^127 the mantissas saturate at 255: the largest value
    int m[3];
    auto mantissas = [&] {
        for (int c = 0; c < 3; ++c) m[c] = int(std::lround(std::ldexp(v[c], -e) * 256.0f));
    };
    mantissas();
    if (std::max({m[0], m[1], m[2]}) > 255 && e < 127) {  // rounded up to 256: the next exponent holds it
        ++e;
        mantissas();
    }
    for (int c = 0; c < 3; ++c) out[c] = std::uint8_t(std::clamp(m[c], 0, 255));
    out[3] = std::uint8_t(e + 128);
}

// Appends one row (w RGBE pixels) as a new-style run-length scanline (8 <= w <= 32767).
void append_rle_row(std::vector<std::uint8_t>& out, const std::uint8_t* row, int w) {
    out.push_back(2);
    out.push_back(2);
    out.push_back(std::uint8_t(w >> 8));
    out.push_back(std::uint8_t(w & 255));
    const std::size_t n = std::size_t(w);
    auto run_at = [&](std::size_t i, std::size_t c, std::size_t cap) {
        std::size_t r = 1;
        while (i + r < n && r < cap && row[(i + r) * 4 + c] == row[i * 4 + c]) ++r;
        return r;
    };
    for (std::size_t c = 0; c < 4; ++c) {
        std::size_t i = 0;
        while (i < n) {
            const std::size_t r = run_at(i, c, 127);
            if (r >= 4) {
                out.push_back(std::uint8_t(128 + r));
                out.push_back(row[i * 4 + c]);
                i += r;
                continue;
            }
            std::size_t j = i;  // a literal up to the next run of 4 or 128 bytes
            while (j < n && j - i < 128 && run_at(j, c, 4) < 4) ++j;
            out.push_back(std::uint8_t(j - i));
            for (std::size_t k = i; k < j; ++k) out.push_back(row[k * 4 + c]);
            i = j;
        }
    }
}

}  // namespace

std::vector<std::uint8_t> encode_hdr(const ImageF& image) {
    std::vector<std::uint8_t> out;
    if (image.empty() || (image.channels != 3 && image.channels != 4) ||
        image.data.size() < std::size_t(image.width) * std::size_t(image.height) * std::size_t(image.channels))
        return out;
    std::string header = "#?RADIANCE\nFORMAT=32-bit_rle_rgbe\n";
    if (std::isfinite(image.exposure) && image.exposure > 0.0f && image.exposure != 1.0f)
        header += std::format("EXPOSURE={}\n", image.exposure);
    header += std::format("\n-Y {} +X {}\n", image.height, image.width);
    out.assign(header.begin(), header.end());
    const bool rle = image.width >= 8 && image.width <= 32767;
    const std::size_t w = std::size_t(image.width), ch = std::size_t(image.channels);
    out.reserve(out.size() + (rle ? w * std::size_t(image.height) * 2 : w * std::size_t(image.height) * 4));
    std::vector<std::uint8_t> row(w * 4);
    for (int y = 0; y < image.height; ++y) {
        const float* src = &image.data[std::size_t(y) * w * ch];
        for (std::size_t x = 0; x < w; ++x) to_rgbe(src[x * ch], src[x * ch + 1], src[x * ch + 2], &row[x * 4]);
        if (rle)
            append_rle_row(out, row.data(), image.width);
        else
            out.insert(out.end(), row.begin(), row.end());
    }
    return out;
}

Result<void> save_hdr(const ImageF& image, std::string_view path) {
    if (image.empty())
        return make_error("Cannot save an empty float image to '" + std::string(path) + "'",
                          "Create or load the image first.");
    const std::vector<std::uint8_t> bytes = encode_hdr(image);
    if (bytes.empty())
        return make_error("HDR encoding failed for '" + std::string(path) + "': the image has " +
                              std::to_string(image.channels) + " channels or fewer values than its size says",
                          "An image has 3 (RGB) or 4 (RGBA) channels and width x height x channels values.");
    return fs::write_bytes(path, bytes.data(), bytes.size());
}

}  // namespace fa
