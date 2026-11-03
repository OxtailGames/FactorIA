// The layers of a Photoshop file (assets.import of a .psd). Reads the layer records and their channel data (8 or 16 bit, RGB or
// grayscale; raw, RLE, zip and zip-with-prediction), the section dividers that make groups, the unicode names, blend modes, opacity,
// visibility, clipping and the layer masks (baked into the layer's alpha). It does not read what the compositor cannot draw:
// adjustment layers, layer styles, vector masks and smart-object filters are skipped, each with a warning.
#include <algorithm>
#include <cstring>
#include <format>
#include <map>

#include "fa/core/compress.h"
#include "image_edit.h"

namespace fa::imgedit {

namespace {

struct Bad {
    std::string message;
};

class Reader {
public:
    Reader(const std::vector<std::uint8_t>& b) : b_(b) {}
    std::size_t pos() const { return pos_; }
    void seek(std::size_t p) {
        if (p > b_.size()) throw Bad{std::format("a section points to byte {} but the file has {} bytes (the file is cut short or damaged)", p, b_.size())};
        pos_ = p;
    }
    void skip(std::size_t n) { seek(pos_ + n); }
    std::size_t size() const { return b_.size(); }
    std::uint32_t u8() {
        need(1);
        return b_[pos_++];
    }
    std::uint32_t u16() {
        need(2);
        const std::uint32_t v = (b_[pos_] << 8) | b_[pos_ + 1];
        pos_ += 2;
        return v;
    }
    std::uint32_t u32() {
        need(4);
        const std::uint32_t v = (std::uint32_t(b_[pos_]) << 24) | (b_[pos_ + 1] << 16) | (b_[pos_ + 2] << 8) | b_[pos_ + 3];
        pos_ += 4;
        return v;
    }
    std::int32_t i32() { return std::int32_t(u32()); }
    std::int32_t i16() { return std::int16_t(u16()); }
    std::string tag() {
        need(4);
        std::string s(reinterpret_cast<const char*>(&b_[pos_]), 4);
        pos_ += 4;
        return s;
    }
    const std::uint8_t* ptr(std::size_t n) {
        need(n);
        return &b_[pos_];
    }

private:
    void need(std::size_t n) const {
        if (pos_ + n > b_.size()) throw Bad{std::format("the file ends at byte {} but more data is expected (the file is cut short or damaged)", b_.size())};
    }
    const std::vector<std::uint8_t>& b_;
    std::size_t pos_ = 0;
};

struct ChannelInfo {
    int id = 0;
    std::uint32_t length = 0;
};

struct Record {
    int top = 0, left = 0, bottom = 0, right = 0;
    std::vector<ChannelInfo> channels;
    std::string blendKey = "norm";
    int opacity = 255;
    bool clipped = false;
    bool visible = true;
    std::string name;
    int divider = 0;  // lsct: 0 none, 1 open folder, 2 closed folder, 3 bounding section divider
    std::string dividerBlend;
    // layer mask
    bool hasMask = false, maskDisabled = false, maskInvert = false;
    int mTop = 0, mLeft = 0, mBottom = 0, mRight = 0, maskDefault = 0;
    int width() const { return std::max(0, right - left); }
    int height() const { return std::max(0, bottom - top); }
};

std::string utf16be_to_utf8(const std::uint8_t* p, std::size_t chars) {
    std::string out;
    for (std::size_t i = 0; i < chars; ++i) {
        std::uint32_t c = (p[i * 2] << 8) | p[i * 2 + 1];
        if (c >= 0xD800 && c < 0xDC00 && i + 1 < chars) {
            const std::uint32_t lo = (p[i * 2 + 2] << 8) | p[i * 2 + 3];
            if (lo >= 0xDC00 && lo < 0xE000) {
                c = 0x10000 + ((c - 0xD800) << 10) + (lo - 0xDC00);
                ++i;
            }
        }
        if (c < 0x80) out += char(c);
        else if (c < 0x800) { out += char(0xC0 | (c >> 6)); out += char(0x80 | (c & 63)); }
        else if (c < 0x10000) { out += char(0xE0 | (c >> 12)); out += char(0x80 | ((c >> 6) & 63)); out += char(0x80 | (c & 63)); }
        else { out += char(0xF0 | (c >> 18)); out += char(0x80 | ((c >> 12) & 63)); out += char(0x80 | ((c >> 6) & 63)); out += char(0x80 | (c & 63)); }
    }
    return out;
}

// One channel's samples, reduced to 8 bit. `data` starts at the compression code.
std::vector<std::uint8_t> decode_channel(const std::uint8_t* data, std::size_t len, int w, int h, int depth, const std::string& what) {
    if (w <= 0 || h <= 0) return {};
    if (len < 2) throw Bad{what + ": the channel has no data"};
    const int comp = (data[0] << 8) | data[1];
    const std::uint8_t* d = data + 2;
    const std::size_t n = len - 2, bps = depth == 16 ? 2 : 1, rowBytes = std::size_t(w) * bps, total = rowBytes * h;
    std::vector<std::uint8_t> raw;
    if (comp == 0) {
        if (n < total) throw Bad{what + ": raw channel data is shorter than the layer"};
        raw.assign(d, d + total);
    } else if (comp == 1) {
        if (n < std::size_t(h) * 2) throw Bad{what + ": RLE row table is cut short"};
        std::size_t at = std::size_t(h) * 2;
        raw.reserve(total);
        for (int y = 0; y < h; ++y) {
            const std::size_t rowLen = (d[y * 2] << 8) | d[y * 2 + 1];
            if (at + rowLen > n) throw Bad{what + ": an RLE row runs past the channel"};
            std::size_t i = at, produced = 0;
            const std::size_t end = at + rowLen;
            while (i < end && produced < rowBytes) {
                const int c = std::int8_t(d[i++]);
                if (c >= 0) {
                    const std::size_t cnt = std::size_t(c) + 1;
                    if (i + cnt > end) throw Bad{what + ": an RLE literal run is cut short"};
                    for (std::size_t k = 0; k < cnt && produced < rowBytes; ++k, ++produced) raw.push_back(d[i + k]);
                    i += cnt;
                } else if (c != -128) {
                    const std::size_t cnt = std::size_t(1 - c);
                    if (i >= end) throw Bad{what + ": an RLE repeat run is cut short"};
                    for (std::size_t k = 0; k < cnt && produced < rowBytes; ++k, ++produced) raw.push_back(d[i]);
                    ++i;
                }
            }
            if (produced < rowBytes) raw.insert(raw.end(), rowBytes - produced, 0);
            at = end;
        }
    } else if (comp == 2 || comp == 3) {
        auto z = zlib_decompress(std::string_view(reinterpret_cast<const char*>(d), n), total);
        if (!z.ok()) throw Bad{what + ": zip data does not decompress (" + z.error().message + ")"};
        if (z->size() < total) throw Bad{what + ": zip data is shorter than the layer"};
        raw.assign(z->begin(), z->begin() + std::ptrdiff_t(total));
        if (comp == 3) {  // undo the prediction: each sample is stored as the difference to the one on its left
            for (int y = 0; y < h; ++y) {
                std::uint8_t* row = &raw[std::size_t(y) * rowBytes];
                if (bps == 1) {
                    for (int x = 1; x < w; ++x) row[x] = std::uint8_t(row[x] + row[x - 1]);
                } else {
                    for (int x = 1; x < w; ++x) {
                        const unsigned prev = (row[(x - 1) * 2] << 8) | row[(x - 1) * 2 + 1], cur = (row[x * 2] << 8) | row[x * 2 + 1];
                        const unsigned v = (prev + cur) & 0xFFFF;
                        row[x * 2] = std::uint8_t(v >> 8);
                        row[x * 2 + 1] = std::uint8_t(v & 255);
                    }
                }
            }
        }
    } else {
        throw Bad{std::format("{}: unknown compression code {}", what, comp)};
    }
    if (bps == 1) return raw;
    std::vector<std::uint8_t> out(std::size_t(w) * h);
    for (std::size_t i = 0; i < out.size(); ++i) out[i] = std::uint8_t(((raw[i * 2] << 8 | raw[i * 2 + 1]) * 255 + 32767) / 65535);
    return out;
}

const char* blend_from_key(const std::string& key, std::vector<std::string>& warnings, const std::string& layer, bool& passThrough) {
    static const std::map<std::string, const char*> known = {
        {"norm", "normal"},  {"dark", "darken"},   {"mul ", "multiply"}, {"idiv", "colorBurn"}, {"lite", "lighten"},   {"scrn", "screen"},
        {"div ", "colorDodge"}, {"lddg", "add"},   {"over", "overlay"},  {"sLit", "softLight"}, {"hLit", "hardLight"}, {"diff", "difference"},
        {"smud", "exclusion"},  {"fsub", "subtract"}, {"hue ", "hue"},   {"sat ", "saturation"}, {"colr", "color"},    {"lum ", "luminosity"}};
    passThrough = false;
    if (key == "pass") {
        passThrough = true;
        return "normal";
    }
    auto it = known.find(key);
    if (it != known.end()) return it->second;
    static const std::map<std::string, std::pair<const char*, const char*>> approx = {
        {"lbrn", {"multiply", "Linear Burn"}}, {"vLit", {"overlay", "Vivid Light"}}, {"lLit", {"overlay", "Linear Light"}},
        {"pLit", {"overlay", "Pin Light"}},    {"hMix", {"hardLight", "Hard Mix"}},  {"dkCl", {"darken", "Darker Color"}},
        {"lgCl", {"lighten", "Lighter Color"}}, {"diss", {"normal", "Dissolve"}},     {"fdiv", {"difference", "Divide"}}};
    auto ap = approx.find(key);
    if (ap != approx.end()) {
        warnings.push_back(std::format("Layer '{}' uses the Photoshop blend mode {}, which the image documents do not have; it was imported as {}.", layer, ap->second.second, ap->second.first));
        return ap->second.first;
    }
    warnings.push_back(std::format("Layer '{}' uses the Photoshop blend mode '{}', which is unknown here; it was imported as normal.", layer, key));
    return "normal";
}

}  // namespace

Result<PsdDocument> read_psd_layers(const std::vector<std::uint8_t>& bytes, const std::string& file) {
    try {
        Reader r(bytes);
        if (r.tag() != "8BPS") return make_error("'" + file + "' is not a Photoshop file.", "");
        const int version = int(r.u16());
        if (version != 1) return make_error("'" + file + "' is a large document (.psb), whose layers are not read.", "Flatten it and save a PNG, or save it as .psd.");
        r.skip(6);
        const int channels = int(r.u16());
        const int height = int(r.u32()), width = int(r.u32());
        const int depth = int(r.u16()), mode = int(r.u16());
        (void)channels;
        if (depth != 8 && depth != 16)
            return make_error(std::format("'{}' is a {}-bit PSD; layers are read from 8 and 16 bit files.", file, depth), "In Photoshop use Image > Mode > 8 Bits/Channel and save again.");
        if (mode != 1 && mode != 3)
            return make_error(std::format("'{}' uses the colour mode {} (only RGB and grayscale layers are read).", file, mode == 4 ? "CMYK" : mode == 2 ? "indexed" : mode == 7 ? "multichannel" : mode == 8 ? "duotone" : mode == 9 ? "Lab" : "other"),
                              "In Photoshop use Image > Mode > RGB Color and save again.");
        if (width <= 0 || height <= 0 || width > 30000 || height > 30000) return make_error("'" + file + "' has an invalid size.", "");
        r.skip(r.u32());  // colour mode data
        r.skip(r.u32());  // image resources
        const std::size_t miscLen = r.u32();
        const std::size_t miscEnd = r.pos() + miscLen;
        if (miscEnd > r.size()) throw Bad{"the layer section is cut short"};
        PsdDocument doc;
        doc.width = width;
        doc.height = height;
        if (miscLen == 0) return doc;

        std::size_t layerInfoLen = r.u32();
        std::size_t infoStart = r.pos();
        if (layerInfoLen == 0) {
            // 16 and 32 bit files keep their layers in a tagged block after the (empty) layer info and the global mask
            r.seek(infoStart);
            const std::size_t gml = r.u32();
            r.skip(gml);
            bool found = false;
            while (r.pos() + 12 <= miscEnd) {
                const std::string sig = r.tag(), key = r.tag();
                const std::size_t len = r.u32();
                if (sig != "8BIM" && sig != "8B64") break;
                if (key == "Lr16" || key == "Lr32" || key == "Layr") {
                    infoStart = r.pos();
                    layerInfoLen = len;
                    found = true;
                    break;
                }
                r.skip((len + 3) & ~std::size_t(3));
            }
            if (!found) return doc;
        }
        r.seek(infoStart);
        int count = r.i16();
        if (count == 0) return doc;
        if (count < 0) count = -count;
        std::vector<Record> recs;
        for (int i = 0; i < count; ++i) {
            Record rec;
            rec.top = r.i32();
            rec.left = r.i32();
            rec.bottom = r.i32();
            rec.right = r.i32();
            const int nch = int(r.u16());
            for (int c = 0; c < nch; ++c) {
                ChannelInfo ci;
                ci.id = r.i16();
                ci.length = r.u32();
                rec.channels.push_back(ci);
            }
            if (r.tag() != "8BIM") throw Bad{std::format("layer record {} has a bad blend signature", i)};
            rec.blendKey = r.tag();
            rec.opacity = int(r.u8());
            rec.clipped = r.u8() != 0;
            const int flags = int(r.u8());
            rec.visible = (flags & 2) == 0;
            r.skip(1);
            const std::size_t extraLen = r.u32();
            const std::size_t extraEnd = r.pos() + extraLen;
            if (extraEnd > r.size()) throw Bad{std::format("layer record {} is cut short", i)};
            // layer mask
            const std::size_t maskLen = r.u32();
            if (maskLen >= 18) {
                const std::size_t maskEnd = r.pos() + maskLen;
                rec.mTop = r.i32();
                rec.mLeft = r.i32();
                rec.mBottom = r.i32();
                rec.mRight = r.i32();
                rec.maskDefault = int(r.u8());
                const int mf = int(r.u8());
                rec.hasMask = true;
                rec.maskDisabled = (mf & 2) != 0;
                rec.maskInvert = (mf & 4) != 0;
                r.seek(maskEnd);
            } else {
                r.skip(maskLen);
            }
            r.skip(r.u32());  // blending ranges
            // name: a Pascal string padded to a multiple of 4
            const std::size_t nameLen = r.u8();
            rec.name.assign(reinterpret_cast<const char*>(r.ptr(nameLen)), nameLen);
            r.skip(nameLen);
            r.skip((4 - ((nameLen + 1) % 4)) % 4);
            while (r.pos() + 12 <= extraEnd) {
                const std::string sig = r.tag(), key = r.tag();
                const std::size_t len = r.u32();
                const std::size_t start = r.pos();
                if ((sig != "8BIM" && sig != "8B64") || start + len > extraEnd) break;
                if (key == "luni" && len >= 4) {
                    const std::size_t chars = r.u32();
                    if (4 + chars * 2 <= len) rec.name = utf16be_to_utf8(r.ptr(chars * 2), chars);
                } else if (key == "lsct" || key == "lsdk") {
                    if (len >= 4) {
                        rec.divider = int(r.u32());
                        if (len >= 12) {
                            r.skip(4);
                            rec.dividerBlend = r.tag();
                        }
                    }
                }
                r.seek(start + len);
            }
            r.seek(extraEnd);
            recs.push_back(std::move(rec));
        }
        doc.layerCount = count;

        // channel data, in the order of the records
        struct Decoded {
            Image pixels;
        };
        std::vector<Image> images(recs.size());
        for (std::size_t i = 0; i < recs.size(); ++i) {
            const Record& rec = recs[i];
            std::map<int, std::vector<std::uint8_t>> planes;
            std::map<int, std::pair<int, int>> sizes;
            for (const ChannelInfo& ci : rec.channels) {
                const std::size_t start = r.pos();
                const bool isMask = ci.id == -2 || ci.id == -3;
                const int w = isMask ? std::max(0, rec.mRight - rec.mLeft) : rec.width();
                const int h = isMask ? std::max(0, rec.mBottom - rec.mTop) : rec.height();
                if (ci.length > r.size() - std::min(r.size(), start)) throw Bad{std::format("channel data of layer '{}' runs past the file", rec.name)};
                if (std::int64_t(w) * h > 200'000'000) throw Bad{std::format("layer '{}' is too large", rec.name)};
                if (ci.id >= -1 && ci.id <= 2 && rec.divider == 0) planes[ci.id] = decode_channel(r.ptr(ci.length), ci.length, w, h, depth, "layer '" + rec.name + "'");
                else if (ci.id == -2 && rec.divider == 0 && rec.hasMask) planes[-2] = decode_channel(r.ptr(ci.length), ci.length, w, h, depth, "mask of layer '" + rec.name + "'");
                r.seek(start + ci.length);
            }
            const int w = rec.width(), h = rec.height();
            if (rec.divider != 0 || w == 0 || h == 0) continue;
            Image img;
            img.width = w;
            img.height = h;
            img.rgba.assign(std::size_t(w) * h * 4, 255);
            const bool gray = mode == 1;
            for (int ch = 0; ch < 3; ++ch) {
                const auto it = planes.find(gray ? 0 : ch);
                if (it == planes.end()) {
                    std::fill(img.rgba.begin(), img.rgba.end(), 0);  // unreadable: transparent
                    continue;
                }
                for (std::size_t p = 0; p < it->second.size() && p * 4 < img.rgba.size(); ++p) img.rgba[p * 4 + ch] = it->second[p];
            }
            if (auto a = planes.find(-1); a != planes.end())
                for (std::size_t p = 0; p < a->second.size() && p * 4 < img.rgba.size(); ++p) img.rgba[p * 4 + 3] = a->second[p];
            if (auto m = planes.find(-2); m != planes.end() && !rec.maskDisabled) {
                const int mw = std::max(0, rec.mRight - rec.mLeft);
                for (int y = 0; y < h; ++y)
                    for (int x = 0; x < w; ++x) {
                        const int mx = rec.left + x - rec.mLeft, my = rec.top + y - rec.mTop;
                        int v = rec.maskDefault;
                        if (mx >= 0 && my >= 0 && mx < mw && my < std::max(0, rec.mBottom - rec.mTop)) v = m->second[std::size_t(my) * mw + mx];
                        if (rec.maskInvert) v = 255 - v;
                        std::uint8_t& al = img.rgba[(std::size_t(y) * w + x) * 4 + 3];
                        al = std::uint8_t((al * v + 127) / 255);
                    }
            }
            for (std::size_t p = 0; p < img.rgba.size(); p += 4)
                if (img.rgba[p + 3] == 0) img.rgba[p] = img.rgba[p + 1] = img.rgba[p + 2] = 0;
            images[i] = std::move(img);
        }

        // the tree: records are bottom first; a divider (type 3) opens a group, a folder record (1 or 2) closes it
        struct Open {
            PsdLayer group;
        };
        std::vector<PsdLayer> stack;  // stack[0] is a pseudo root
        stack.emplace_back();
        std::vector<std::string> skipped;
        int unmatched = 0;
        for (std::size_t i = 0; i < recs.size(); ++i) {
            const Record& rec = recs[i];
            if (rec.divider == 3) {
                PsdLayer g;
                g.isGroup = true;
                stack.push_back(std::move(g));
                continue;
            }
            PsdLayer layer;
            layer.name = rec.name.empty() ? "layer " + std::to_string(i + 1) : rec.name;
            layer.opacity = rec.opacity / 255.0f;
            layer.visible = rec.visible;
            layer.clip = rec.clipped;
            bool pass = false;
            const std::string key = rec.divider != 0 && rec.blendKey == "pass" ? "pass" : rec.blendKey;
            layer.blend = blend_from_key(key, doc.warnings, layer.name, pass);
            if (rec.divider == 1 || rec.divider == 2) {
                if (stack.size() < 2) {
                    ++unmatched;
                    continue;
                }
                PsdLayer g = std::move(stack.back());
                stack.pop_back();
                g.name = layer.name;
                g.opacity = layer.opacity;
                g.visible = layer.visible;
                g.clip = layer.clip;
                g.blend = layer.blend;
                if (pass) doc.warnings.push_back(std::format("Group '{}' passes through in Photoshop; image groups are isolated, so it was imported as a normal group (blend modes inside it only see the group).", g.name));
                stack.back().children.push_back(std::move(g));
                continue;
            }
            if (images[i].rgba.empty()) {
                skipped.push_back(layer.name);
                continue;
            }
            layer.x = rec.left;
            layer.y = rec.top;
            layer.pixels = std::move(images[i]);
            stack.back().children.push_back(std::move(layer));
        }
        while (stack.size() > 1) {  // groups never closed (a damaged file): keep their layers
            PsdLayer g = std::move(stack.back());
            stack.pop_back();
            g.name = "group";
            stack.back().children.push_back(std::move(g));
            ++unmatched;
        }
        if (unmatched) doc.warnings.push_back("Some groups in the file were not closed properly; their layers were kept.");
        if (!skipped.empty()) {
            std::string list;
            for (std::size_t i = 0; i < skipped.size() && i < 5; ++i) list += (i ? ", '" : "'") + skipped[i] + "'";
            if (skipped.size() > 5) list += std::format(" and {} more", skipped.size() - 5);
            doc.warnings.push_back(std::format("{} layer{} with no pixels {} skipped (adjustment layers, empty layers): {}.", skipped.size(), skipped.size() == 1 ? "" : "s", skipped.size() == 1 ? "was" : "were", list));
        }
        doc.layers = std::move(stack[0].children);
        return doc;
    } catch (const Bad& b) {
        return make_error("Cannot read the layers of '" + file + "': " + b.message + ".", "The merged image can still be imported.");
    }
}

}  // namespace fa::imgedit
