#include "fa/tooling/pe_icon.h"

#include <algorithm>
#include <cstring>
#include <string>

#include "fa/tooling/icons.h"

namespace fa {

namespace {

constexpr std::uint32_t kRtIcon = 3;                 // resource type of one icon image
constexpr std::uint32_t kSubdirectoryFlag = 0x80000000u;
constexpr std::size_t kBitmapHeaderSize = 40;         // BITMAPINFOHEADER

// Reads little-endian fields of the file; every caller checks has() first.
struct View {
    const std::vector<std::uint8_t>& d;
    bool has(std::uint64_t off, std::uint64_t n) const { return off <= d.size() && n <= d.size() - off; }
    std::uint32_t u16(std::uint64_t off) const { return std::uint32_t(d[off]) | (std::uint32_t(d[off + 1]) << 8); }
    std::uint32_t u32(std::uint64_t off) const { return u16(off) | (u16(off + 2) << 16); }
};

void put_u32(std::vector<std::uint8_t>& d, std::uint64_t off, std::uint32_t x) {
    for (int i = 0; i < 4; ++i) d[off + i] = std::uint8_t((x >> (8 * i)) & 0xff);
}

struct Section {
    std::uint32_t va = 0, rawPtr = 0, rawSize = 0;
};

// The length of a 32-bit BMP icon image of `size` pixels (icon_bmp_entry): header, pixels, 1-bit AND mask.
std::uint64_t bmp_image_length(std::uint64_t size) { return kBitmapHeaderSize + size * size * 4 + ((size + 31) / 32) * 4 * size; }

Error not_a_pe(const std::string& why) {
    return make_error("Cannot set the icon of the Windows player: " + why,
                      "Pass the factoria_player.exe built for Windows (`--player <path>`), the one next to factoria in the FactorIA "
                      "download for Windows.");
}

Error damaged_resources(const std::string& why) {
    return make_error("Cannot set the icon of the Windows player: its resource table is damaged (" + why + ")",
                      "Use the factoria_player.exe of the FactorIA download, or build it again (cmake --build <build dir> --target factoria_player).");
}

}  // namespace

std::uint32_t pe_checksum(const std::vector<std::uint8_t>& bytes, std::size_t checksumOffset) {
    const std::size_t n = bytes.size();
    auto at = [&](std::size_t k) -> std::uint32_t {
        return k >= checksumOffset && k < checksumOffset + 4 ? 0u : std::uint32_t(bytes[k]);
    };
    std::uint64_t sum = 0;
    for (std::size_t i = 0; i < n; i += 2) sum += at(i) | (i + 1 < n ? at(i + 1) << 8 : 0u);
    while (sum >> 16) sum = (sum & 0xffff) + (sum >> 16);
    return std::uint32_t(sum + n);
}

Result<PeIconPatch> patch_pe_icon(std::vector<std::uint8_t>& exe, const Image& icon) {
    if (icon.empty())
        return make_error("Cannot set the icon of the Windows player: the icon image is empty", "Load it with load_icon_image first.");
    const View v{exe};

    // ---- headers ---------------------------------------------------------------------------------------------
    if (exe.size() < 0x40 || exe[0] != 'M' || exe[1] != 'Z') return not_a_pe("the file is not a Windows executable (it does not start with 'MZ')");
    const std::uint64_t peOff = v.u32(0x3C);
    if (!v.has(peOff, 24) || std::memcmp(&exe[peOff], "PE\0\0", 4) != 0) return not_a_pe("the file has no PE header");
    const std::uint64_t coff = peOff + 4, opt = coff + 20;
    const std::uint32_t numSections = v.u16(coff + 2), optSize = v.u16(coff + 16);
    if (!v.has(opt, optSize) || optSize < 96) return not_a_pe("its optional header is missing or truncated");
    const std::uint32_t magic = v.u16(opt);
    if (magic != 0x10b && magic != 0x20b) return not_a_pe("its optional header has an unknown magic number");
    const bool pe32plus = magic == 0x20b;
    const std::uint64_t dirCountOff = opt + (pe32plus ? 108 : 92), dirBase = opt + (pe32plus ? 112 : 96);
    std::uint32_t dirCount = 0;
    if (v.has(dirCountOff, 4) && dirCountOff + 4 <= opt + optSize) dirCount = std::min<std::uint32_t>(v.u32(dirCountOff), 16);
    dirCount = std::min<std::uint32_t>(dirCount, std::uint32_t((opt + optSize - std::min(dirBase, opt + optSize)) / 8));

    const std::uint64_t sectionTable = opt + optSize;
    if (!v.has(sectionTable, std::uint64_t(numSections) * 40)) return not_a_pe("its section table is truncated");
    std::vector<Section> sections;
    std::uint64_t endOfRawData = v.has(opt + 60, 4) ? v.u32(opt + 60) : 0;  // SizeOfHeaders
    for (std::uint32_t i = 0; i < numSections; ++i) {
        const std::uint64_t s = sectionTable + std::uint64_t(i) * 40;
        sections.push_back({v.u32(s + 12), v.u32(s + 20), v.u32(s + 16)});
        endOfRawData = std::max<std::uint64_t>(endOfRawData, std::uint64_t(sections.back().rawPtr) + sections.back().rawSize);
    }
    auto rva_to_offset = [&](std::uint32_t rva, std::uint64_t& out) {
        for (const Section& s : sections)
            if (rva >= s.va && rva - s.va < s.rawSize) {
                out = std::uint64_t(s.rawPtr) + (rva - s.va);
                return v.has(out, 1);
            }
        return false;
    };

    // ---- the RT_ICON images in the resource tree --------------------------------------------------------------
    PeIconPatch result;
    struct Target {
        std::uint64_t offset;
        std::uint32_t width;
    };
    std::vector<Target> targets;
    const std::uint32_t resRva = dirCount > 2 ? v.u32(dirBase + 2 * 8) : 0;
    if (resRva != 0) {
        std::uint64_t resBase = 0;
        if (!rva_to_offset(resRva, resBase)) return damaged_resources("the resource directory points outside every section");
        std::string problem;
        int visited = 0;
        // level 0: resource types (only RT_ICON is followed), 1: names, 2: languages; the leaves are data entries.
        auto walk = [&](auto&& self, std::uint32_t dirOff, int level) -> void {
            if (!problem.empty()) return;
            const std::uint64_t at = resBase + dirOff;
            if (!v.has(at, 16) || ++visited > 4096) {
                problem = "a directory lies outside the file or the tree is too deep";
                return;
            }
            const std::uint32_t named = v.u16(at + 12), ids = v.u16(at + 14);
            if (!v.has(at + 16, std::uint64_t(named + ids) * 8)) {
                problem = "a directory lists more entries than the file holds";
                return;
            }
            for (std::uint32_t i = 0; i < named + ids && problem.empty(); ++i) {
                const std::uint64_t e = at + 16 + std::uint64_t(i) * 8;
                const std::uint32_t nameField = v.u32(e), offField = v.u32(e + 4);
                if (level == 0 && !(i >= named && nameField == kRtIcon)) continue;
                if (offField & kSubdirectoryFlag) {
                    if (level >= 2) problem = "the tree is deeper than type, name, language";
                    else self(self, offField & ~kSubdirectoryFlag, level + 1);
                    continue;
                }
                if (level == 0) continue;  // a type that is a leaf: not an icon
                const std::uint64_t de = resBase + offField;
                std::uint64_t imageOff = 0;
                if (!v.has(de, 16)) {
                    problem = "a data entry lies outside the file";
                    continue;
                }
                const std::uint32_t size = v.u32(de + 4);
                if (!rva_to_offset(v.u32(de), imageOff) || !v.has(imageOff, size)) {
                    problem = "an icon image lies outside the file";
                    continue;
                }
                // A 32-bit uncompressed BMP image of a square size: the placeholder's.
                const std::uint32_t width = size >= kBitmapHeaderSize ? v.u32(imageOff + 4) : 0;
                const bool bmp = size >= kBitmapHeaderSize && v.u32(imageOff) == kBitmapHeaderSize && width >= 1 && width <= 256 &&
                                 v.u32(imageOff + 8) == width * 2 && v.u16(imageOff + 12) == 1 && v.u16(imageOff + 14) == 32 &&
                                 v.u32(imageOff + 16) == 0 && size == bmp_image_length(width);
                if (bmp) targets.push_back({imageOff, width});
                else ++result.skipped;
            }
        };
        walk(walk, 0, 0);
        if (!problem.empty()) return damaged_resources(problem);
    }
    if (targets.empty()) return result;  // nothing to replace: the file stays exactly as it is

    // ---- from here on the file is changed -----------------------------------------------------------------------
    for (const Target& t : targets) {
        const std::vector<std::uint8_t> image = icon_bmp_entry(icon, int(t.width));
        std::copy(image.begin(), image.end(), exe.begin() + std::ptrdiff_t(t.offset));
        result.sizes.push_back(int(t.width));
        ++result.replaced;
    }

    // The bytes changed, so the Authenticode signature (data directory 4: a FILE offset and a length, at the end of the
    // file) is void: cut it.
    if (dirCount > 4) {
        const std::uint64_t entry = dirBase + 4 * 8;
        const std::uint64_t certOff = v.u32(entry), certSize = v.u32(entry + 4);
        if (certSize != 0) {
            put_u32(exe, entry, 0);
            put_u32(exe, entry + 4, 0);
            result.signatureRemoved = true;
            if (certOff >= endOfRawData && certOff <= exe.size() && certOff + certSize >= exe.size()) {
                exe.resize(std::size_t(certOff));
                result.truncated = true;
            }
        }
    }

    put_u32(exe, opt + 64, pe_checksum(exe, std::size_t(opt + 64)));
    return result;
}

}  // namespace fa
