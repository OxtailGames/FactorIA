// The numbers a style check needs from one picture, and their cache (fa/tooling/art_check.h).
#include <algorithm>
#include <array>
#include <cmath>
#include <cstring>
#include <format>
#include <unordered_map>

#include "fa/core/asset_manifest.h"
#include "fa/core/hash.h"
#include "fa/tooling/art_check.h"
#include "util.h"

namespace fa {

namespace {

constexpr int kCacheVersion = 1;
constexpr int kMaxColours = 512;
constexpr double kOutlineTolerance = 48;

std::uint32_t pack(std::uint8_t r, std::uint8_t g, std::uint8_t b) {
    return (std::uint32_t(r) << 16) | (std::uint32_t(g) << 8) | b;
}

double distance(const ArtColour& a, const ArtColour& b) {
    const double dr = double(a.r) - b.r, dg = double(a.g) - b.g, db = double(a.b) - b.b;
    return std::sqrt(dr * dr + dg * dg + db * db);
}
double luminance(std::uint8_t r, std::uint8_t g, std::uint8_t b) {
    return (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0;
}

struct Bin {
    double r = 0, g = 0, b = 0;
    std::uint64_t n = 0;
};

// The `n` biggest bins as colours (mean colour of each), most used first.
std::vector<ArtColour> top_bins(const std::unordered_map<std::uint32_t, Bin>& bins, std::size_t n) {
    std::vector<std::pair<std::uint32_t, const Bin*>> order;
    order.reserve(bins.size());
    for (const auto& [key, bin] : bins) order.push_back({key, &bin});
    std::sort(order.begin(), order.end(), [](const auto& a, const auto& b) {
        return a.second->n != b.second->n ? a.second->n > b.second->n : a.first < b.first;
    });
    std::vector<ArtColour> out;
    for (std::size_t i = 0; i < order.size() && i < n; ++i) {
        const Bin& b = *order[i].second;
        out.push_back({std::uint8_t(std::lround(b.r / double(b.n))), std::uint8_t(std::lround(b.g / double(b.n))),
                       std::uint8_t(std::lround(b.b / double(b.n))), std::uint32_t(b.n)});
    }
    return out;
}

}  // namespace

ArtMeasure measure_art(const Image& img, int cellWidth, int cellHeight) {
    ArtMeasure m;
    m.width = img.width;
    m.height = img.height;
    m.cellWidth = cellWidth;
    m.cellHeight = cellHeight;
    if (img.empty()) return m;
    const int w = img.width, h = img.height;
    auto px = [&](int x, int y) { return &img.rgba[(std::size_t(y) * w + x) * 4]; };
    auto visible_at = [&](int x, int y) { return px(x, y)[3] >= 128; };

    std::unordered_map<std::uint32_t, std::uint32_t> exact;
    std::unordered_map<std::uint32_t, Bin> bins;
    std::array<std::uint64_t, 256> valueHist{};
    double saturationSum = 0;
    std::uint64_t partial = 0, anyAlpha = 0;
    std::unordered_map<std::uint32_t, Bin> ringBins;
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            const std::uint8_t* p = px(x, y);
            if (p[3] > 0) {
                ++anyAlpha;
                if (p[3] < 255) ++partial;
            }
            if (p[3] < 128) continue;
            ++m.visible;
            ++exact[pack(p[0], p[1], p[2])];
            const std::uint32_t key = pack(p[0] >> 3, p[1] >> 3, p[2] >> 3);
            Bin& bin = bins[key];
            bin.r += p[0];
            bin.g += p[1];
            bin.b += p[2];
            ++bin.n;
            const int mx = std::max({p[0], p[1], p[2]}), mn = std::min({p[0], p[1], p[2]});
            ++valueHist[std::size_t(mx)];
            saturationSum += mx > 0 ? double(mx - mn) / mx : 0.0;
            const bool ring = (x > 0 && !visible_at(x - 1, y)) || (x + 1 < w && !visible_at(x + 1, y)) ||
                              (y > 0 && !visible_at(x, y - 1)) || (y + 1 < h && !visible_at(x, y + 1));
            if (ring) {
                ++m.ringPixels;
                Bin& rb = ringBins[key];
                rb.r += p[0];
                rb.g += p[1];
                rb.b += p[2];
                ++rb.n;
            }
        }
    }
    m.partialShare = anyAlpha ? double(partial) / double(anyAlpha) : 0.0;
    m.distinct = int(exact.size());
    if (m.visible == 0) return m;
    m.saturationMean = saturationSum / double(m.visible);
    {
        std::uint64_t acc = 0;
        const std::uint64_t lowAt = std::max<std::uint64_t>(1, m.visible / 100), highAt = m.visible - m.visible / 100;
        bool lowDone = false;
        for (int v = 0; v < 256; ++v) {
            acc += valueHist[std::size_t(v)];
            if (!lowDone && acc >= lowAt) {
                m.valueLow = v / 255.0;
                lowDone = true;
            }
            if (acc >= highAt) {
                m.valueHigh = v / 255.0;
                break;
            }
        }
    }
    if (exact.size() <= std::size_t(kMaxColours)) {
        m.exact = true;
        std::vector<std::pair<std::uint32_t, std::uint32_t>> order(exact.begin(), exact.end());
        std::sort(order.begin(), order.end(), [](const auto& a, const auto& b) {
            return a.second != b.second ? a.second > b.second : a.first < b.first;
        });
        for (const auto& [key, n] : order)
            m.colours.push_back({std::uint8_t(key >> 16), std::uint8_t(key >> 8), std::uint8_t(key), n});
    } else {
        m.exact = false;
        m.colours = top_bins(bins, kMaxColours);
    }
    m.ringColours = top_bins(ringBins, 8);

    // ---- the thickness of the commonest line of the ring ----
    if (!m.ringColours.empty()) {
        const ArtColour dom = m.ringColours.front();
        auto near_dom = [&](int x, int y) {
            const std::uint8_t* p = px(x, y);
            return p[3] >= 128 && distance({p[0], p[1], p[2], 0}, dom) <= kOutlineTolerance;
        };
        std::array<std::uint32_t, 65> runs{};
        std::uint32_t counted = 0;
        for (int y = 0; y < h; ++y)
            for (int x = 0; x < w; ++x) {
                if (!near_dom(x, y)) continue;
                int dx = 0, dy = 0;  // inward: away from the transparent neighbour
                if (x > 0 && !visible_at(x - 1, y))
                    dx = 1;
                else if (x + 1 < w && !visible_at(x + 1, y))
                    dx = -1;
                else if (y > 0 && !visible_at(x, y - 1))
                    dy = 1;
                else if (y + 1 < h && !visible_at(x, y + 1))
                    dy = -1;
                else
                    continue;
                int run = 0;
                for (int cx = x, cy = y; cx >= 0 && cy >= 0 && cx < w && cy < h && near_dom(cx, cy) && run < 64;
                     cx += dx, cy += dy)
                    ++run;
                ++runs[std::size_t(run)];
                ++counted;
            }
        if (counted) {
            std::uint32_t acc = 0;
            for (std::size_t k = 0; k < runs.size(); ++k) {
                acc += runs[k];
                if (acc * 2 >= counted) {
                    m.ringWidth = double(k);
                    break;
                }
            }
        }
    }

    // ---- which way the shading leans (per cell, so the frames of a sheet do not mix) ----
    {
        const int cw = cellWidth > 0 ? std::min(cellWidth, w) : w, ch = cellHeight > 0 ? std::min(cellHeight, h) : h;
        double sxx = 0, syy = 0, sll = 0, sxl = 0, syl = 0;
        for (int cy0 = 0; cy0 < h; cy0 += ch)
            for (int cx0 = 0; cx0 < w; cx0 += cw) {
                const int x1 = std::min(w, cx0 + cw), y1 = std::min(h, cy0 + ch);
                double n = 0, mx = 0, my = 0, ml = 0;
                for (int y = cy0; y < y1; ++y)
                    for (int x = cx0; x < x1; ++x) {
                        const std::uint8_t* p = px(x, y);
                        if (p[3] < 128) continue;
                        ++n;
                        mx += x;
                        my += y;
                        ml += luminance(p[0], p[1], p[2]);
                    }
                if (n < 16) continue;
                mx /= n;
                my /= n;
                ml /= n;
                for (int y = cy0; y < y1; ++y)
                    for (int x = cx0; x < x1; ++x) {
                        const std::uint8_t* p = px(x, y);
                        if (p[3] < 128) continue;
                        const double dl = luminance(p[0], p[1], p[2]) - ml;
                        sxx += (x - mx) * (x - mx);
                        syy += (y - my) * (y - my);
                        sll += dl * dl;
                        sxl += (x - mx) * dl;
                        syl += (y - my) * dl;
                    }
            }
        const double count = double(m.visible);
        if (sll / count > 0.03 * 0.03 && sxx + syy > 0) {
            m.lightStrength = std::min(1.0, std::hypot(sxl, syl) / std::sqrt(sll * (sxx + syy) / 2.0));
            double deg = std::atan2(-syl, sxl) * 180.0 / 3.14159265358979323846;  // the picture's y axis points down
            if (deg < 0) deg += 360;
            m.lightDegrees = deg;
        }
    }

    // ---- pixel art drawn at k x k ----
    if (m.distinct <= 256) {
        m.blockSize = 1;
        for (int k = 8; k >= 2; --k) {
            if (w < k || h < k) continue;
            bool same = true;
            for (int y = 0; y < h && same; ++y)
                for (int x = 0; x < w; ++x)
                    if (std::memcmp(px(x, y), px(x - x % k, y - y % k), 4) != 0) {
                        same = false;
                        break;
                    }
            if (same) {
                m.blockSize = k;
                break;
            }
        }
    }
    return m;
}

// ---- JSON (the cache file) ----------------------------------------------------------------------------------------

namespace {

Json colours_json(const std::vector<ArtColour>& list) {
    Json a = Json::array();
    for (const ArtColour& c : list) a.push_back(Json::array({c.r, c.g, c.b, c.count}));
    return a;
}
bool colours_from(const Json& j, std::vector<ArtColour>& out) {
    if (!j.is_array()) return false;
    for (const Json& c : j) {
        if (!c.is_array() || c.size() != 4) return false;
        out.push_back({std::uint8_t(c[0].get<int>()), std::uint8_t(c[1].get<int>()), std::uint8_t(c[2].get<int>()),
                       c[3].get<std::uint32_t>()});
    }
    return true;
}

}  // namespace

Json ArtMeasure::to_json() const {
    return Json::object({{"version", kCacheVersion},
                         {"width", width},
                         {"height", height},
                         {"visible", visible},
                         {"partialShare", partialShare},
                         {"distinct", distinct},
                         {"exact", exact},
                         {"colours", colours_json(colours)},
                         {"valueLow", valueLow},
                         {"valueHigh", valueHigh},
                         {"saturationMean", saturationMean},
                         {"ringPixels", ringPixels},
                         {"ringColours", colours_json(ringColours)},
                         {"ringWidth", ringWidth},
                         {"lightDegrees", lightDegrees},
                         {"lightStrength", lightStrength},
                         {"blockSize", blockSize},
                         {"cellWidth", cellWidth},
                         {"cellHeight", cellHeight}});
}

std::optional<ArtMeasure> ArtMeasure::from_json(const Json& j) {
    if (!j.is_object() || j.value("version", 0) != kCacheVersion) return std::nullopt;
    try {
        ArtMeasure m;
        m.width = j.at("width").get<int>();
        m.height = j.at("height").get<int>();
        m.visible = j.at("visible").get<std::uint64_t>();
        m.partialShare = j.at("partialShare").get<double>();
        m.distinct = j.at("distinct").get<int>();
        m.exact = j.at("exact").get<bool>();
        if (!colours_from(j.at("colours"), m.colours) || !colours_from(j.at("ringColours"), m.ringColours))
            return std::nullopt;
        m.valueLow = j.at("valueLow").get<double>();
        m.valueHigh = j.at("valueHigh").get<double>();
        m.saturationMean = j.at("saturationMean").get<double>();
        m.ringPixels = j.at("ringPixels").get<std::uint64_t>();
        m.ringWidth = j.at("ringWidth").get<double>();
        m.lightDegrees = j.at("lightDegrees").get<double>();
        m.lightStrength = j.at("lightStrength").get<double>();
        m.blockSize = j.at("blockSize").get<int>();
        m.cellWidth = j.at("cellWidth").get<int>();
        m.cellHeight = j.at("cellHeight").get<int>();
        return m;
    } catch (const std::exception&) {
        return std::nullopt;
    }
}

Result<ArtMeasure> measure_art_file(const std::string& projectDir, const std::string& rel, bool* fromCache) {
    if (fromCache) *fromCache = false;
    namespace stdfs = std::filesystem;
    const stdfs::path file = stdfs::path(projectDir) / rel;
    auto bytes = tooling_detail::read_file(file);
    if (!bytes)
        return make_error("'" + rel + "' cannot be read.",
                          "Use a project-relative path of an existing image, e.g. assets/hero.png.");

    // The cells of a sheet only matter to the light measurement; they are part of the cache key.
    std::shared_ptr<const assets::Sheet> sheet;
    {
        tooling_detail::ProjectRootScope root(projectDir);
        sheet = assets::sheet(rel);
    }
    const std::string key = sha256_hex(bytes->data(), bytes->size()) +
                            (sheet ? std::format("-c{}r{}f{}x{}p{}", sheet->columns, sheet->rows, sheet->frameWidth,
                                                 sheet->frameHeight, sheet->padding)
                                   : "");
    const stdfs::path cacheFile = stdfs::path(projectDir) / ".factoria" / "art-cache" / (key + ".json");
    if (auto text = tooling_detail::read_file(cacheFile)) {
        Json parsed = Json::parse(*text, nullptr, false);
        if (auto m = ArtMeasure::from_json(parsed)) {
            if (fromCache) *fromCache = true;
            return *m;
        }
    }
    auto img = decode_image(reinterpret_cast<const std::uint8_t*>(bytes->data()), bytes->size());
    if (!img) return make_error("'" + rel + "': " + img.error().message, img.error().hint);
    int cw = 0, ch = 0;
    if (sheet) {
        cw = sheet->frameWidth > 0 ? sheet->frameWidth + 2 * sheet->padding : img->width / std::max(1, sheet->columns);
        ch = sheet->frameHeight > 0 ? sheet->frameHeight + 2 * sheet->padding : img->height / std::max(1, sheet->rows);
    }
    ArtMeasure m = measure_art(*img, cw, ch);
    tooling_detail::write_file(cacheFile, m.to_json().dump());  // best effort: a read-only project just measures again
    return m;
}

}  // namespace fa
