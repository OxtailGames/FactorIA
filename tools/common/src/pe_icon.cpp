#include "fa/tooling/pe_icon.h"

#include <algorithm>
#include <cstring>
#include <string>

#include "fa/core/utf8.h"
#include "fa/tooling/icons.h"

namespace fa {

namespace {

constexpr std::uint32_t kRtIcon = 3;      // resource type of one icon image
constexpr std::uint32_t kRtVersion = 16;  // resource type of the version information
constexpr std::uint32_t kSubdirectoryFlag = 0x80000000u;
constexpr std::size_t kBitmapHeaderSize = 40;  // BITMAPINFOHEADER
constexpr std::uint32_t kFixedFileInfoSignature = 0xFEEF04BDu;

// Reads little-endian fields of the file; every caller checks has() first.
struct View {
    const std::vector<std::uint8_t>& d;
    bool has(std::uint64_t off, std::uint64_t n) const { return off <= d.size() && n <= d.size() - off; }
    std::uint32_t u16(std::uint64_t off) const { return std::uint32_t(d[off]) | (std::uint32_t(d[off + 1]) << 8); }
    std::uint32_t u32(std::uint64_t off) const { return u16(off) | (u16(off + 2) << 16); }
};

void put_u16(std::vector<std::uint8_t>& d, std::uint64_t off, std::uint32_t x) {
    for (int i = 0; i < 2; ++i) d[off + i] = std::uint8_t(x >> (8 * i));
}
void put_u32(std::vector<std::uint8_t>& d, std::uint64_t off, std::uint32_t x) {
    for (int i = 0; i < 4; ++i) d[off + i] = std::uint8_t(x >> (8 * i));
}

struct Section {
    std::uint32_t va = 0, rawPtr = 0, rawSize = 0;
};

// What the patchers need of the PE headers.
struct PeLayout {
    std::uint64_t opt = 0;           // the optional header
    std::uint64_t dirBase = 0;       // its data directories
    std::uint32_t dirCount = 0;
    std::uint64_t endOfRawData = 0;  // where the sections end (an appended certificate table starts at or after it)
    std::vector<Section> sections;

    bool rva_to_offset(const View& v, std::uint32_t rva, std::uint64_t& out) const {
        for (const Section& s : sections)
            if (rva >= s.va && rva - s.va < s.rawSize) {
                out = std::uint64_t(s.rawPtr) + (rva - s.va);
                return v.has(out, 1);
            }
        return false;
    }
};

// The length of a 32-bit BMP icon image of `size` pixels (icon_bmp_entry): header, pixels, 1-bit AND mask.
std::uint64_t bmp_image_length(std::uint64_t size) { return kBitmapHeaderSize + size * size * 4 + ((size + 31) / 32) * 4 * size; }

// `what`: "icon" or "version information", for the messages.
Error not_a_pe(const std::string& what, const std::string& why) {
    return make_error("Cannot set the " + what + " of the Windows player: " + why,
                      "Pass the factoria_player.exe built for Windows (`--player <path>`), the one next to factoria in the FactorIA "
                      "download for Windows.");
}

Error damaged_resources(const std::string& what, const std::string& why) {
    return make_error("Cannot set the " + what + " of the Windows player: its resource table is damaged (" + why + ")",
                      "Use the factoria_player.exe of the FactorIA download, or build it again (cmake --build <build dir> --target factoria_player).");
}

Result<PeLayout> read_layout(const std::vector<std::uint8_t>& exe, const std::string& what) {
    const View v{exe};
    if (exe.size() < 0x40 || exe[0] != 'M' || exe[1] != 'Z')
        return not_a_pe(what, "the file is not a Windows executable (it does not start with 'MZ')");
    const std::uint64_t peOff = v.u32(0x3C);
    if (!v.has(peOff, 24) || std::memcmp(&exe[peOff], "PE\0\0", 4) != 0) return not_a_pe(what, "the file has no PE header");
    PeLayout pe;
    const std::uint64_t coff = peOff + 4;
    pe.opt = coff + 20;
    const std::uint32_t numSections = v.u16(coff + 2), optSize = v.u16(coff + 16);
    if (!v.has(pe.opt, optSize) || optSize < 96) return not_a_pe(what, "its optional header is missing or truncated");
    const std::uint32_t magic = v.u16(pe.opt);
    if (magic != 0x10b && magic != 0x20b) return not_a_pe(what, "its optional header has an unknown magic number");
    const bool pe32plus = magic == 0x20b;
    const std::uint64_t optEnd = pe.opt + optSize, dirCountOff = pe.opt + (pe32plus ? 108 : 92);
    pe.dirBase = pe.opt + (pe32plus ? 112 : 96);
    if (v.has(dirCountOff, 4) && dirCountOff + 4 <= optEnd) pe.dirCount = std::min<std::uint32_t>(v.u32(dirCountOff), 16);
    pe.dirCount = std::min<std::uint32_t>(pe.dirCount, std::uint32_t((optEnd - std::min(pe.dirBase, optEnd)) / 8));

    if (!v.has(optEnd, std::uint64_t(numSections) * 40)) return not_a_pe(what, "its section table is truncated");
    pe.endOfRawData = v.has(pe.opt + 60, 4) ? v.u32(pe.opt + 60) : 0;  // SizeOfHeaders
    for (std::uint32_t i = 0; i < numSections; ++i) {
        const std::uint64_t s = optEnd + std::uint64_t(i) * 40;
        pe.sections.push_back({v.u32(s + 12), v.u32(s + 20), v.u32(s + 16)});
        pe.endOfRawData = std::max<std::uint64_t>(pe.endOfRawData, std::uint64_t(pe.sections.back().rawPtr) + pe.sections.back().rawSize);
    }
    return pe;
}

struct ResourceData {
    std::uint64_t offset = 0;  // file offset
    std::uint32_t size = 0;
};

// The data of every resource of `type` in the resource tree (data directory 2: type -> name -> language -> data entry).
// Returns "" or what is damaged.
std::string find_resources(const std::vector<std::uint8_t>& exe, const PeLayout& pe, std::uint32_t type, std::vector<ResourceData>& out) {
    const View v{exe};
    const std::uint32_t resRva = pe.dirCount > 2 ? v.u32(pe.dirBase + 2 * 8) : 0;
    if (resRva == 0) return {};
    std::uint64_t resBase = 0;
    if (!pe.rva_to_offset(v, resRva, resBase)) return "the resource directory points outside every section";
    std::string problem;
    int visited = 0;
    // level 0: resource types (only `type` is followed), 1: names, 2: languages; the leaves are data entries.
    auto walk = [&](auto&& self, std::uint32_t dirOff, int level) -> void {
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
            if (level == 0 && !(i >= named && nameField == type)) continue;
            if (offField & kSubdirectoryFlag) {
                if (level >= 2) problem = "the tree is deeper than type, name, language";
                else self(self, offField & ~kSubdirectoryFlag, level + 1);
                continue;
            }
            if (level == 0) continue;  // a type that is a leaf: not one of ours
            const std::uint64_t de = resBase + offField;
            ResourceData r;
            if (!v.has(de, 16)) {
                problem = "a data entry lies outside the file";
                continue;
            }
            r.size = v.u32(de + 4);
            if (!pe.rva_to_offset(v, v.u32(de), r.offset) || !v.has(r.offset, r.size)) {
                problem = type == kRtIcon ? "an icon image lies outside the file" : "a resource lies outside the file";
                continue;
            }
            out.push_back(r);
        }
    };
    walk(walk, 0, 0);
    return problem;
}

// The bytes of a patched file changed, so its Authenticode signature (data directory 4: a FILE offset and a length, at
// the end of the file) is void: cut it. Then the checksum.
void finish_patch(std::vector<std::uint8_t>& exe, const PeLayout& pe, bool& signatureRemoved, bool& truncated) {
    const View v{exe};
    if (pe.dirCount > 4) {
        const std::uint64_t entry = pe.dirBase + 4 * 8;
        const std::uint64_t certOff = v.u32(entry), certSize = v.u32(entry + 4);
        if (certSize != 0) {
            put_u32(exe, entry, 0);
            put_u32(exe, entry + 4, 0);
            signatureRemoved = true;
            if (certOff >= pe.endOfRawData && certOff <= exe.size() && certOff + certSize >= exe.size()) {
                exe.resize(std::size_t(certOff));
                truncated = true;
            }
        }
    }
    put_u32(exe, pe.opt + 64, pe_checksum(exe, std::size_t(pe.opt + 64)));
}

// "1.2.3" -> {1, 2, 3, 0}: the leading digits of up to four dot-separated parts, each capped at 65535.
void version_numbers(const std::string& version, std::uint32_t out[4]) {
    std::size_t i = 0;
    for (int part = 0; part < 4; ++part) {
        std::uint32_t n = 0;
        while (i < version.size() && version[i] >= '0' && version[i] <= '9') n = std::min<std::uint32_t>(n * 10 + std::uint32_t(version[i++] - '0'), 65535);
        out[part] = n;
        if (i >= version.size() || version[i] != '.') {
            for (int rest = part + 1; rest < 4; ++rest) out[rest] = 0;
            return;
        }
        ++i;
    }
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
    auto pe = read_layout(exe, "icon");
    if (!pe.ok()) return pe.error();
    std::vector<ResourceData> images;
    if (std::string problem = find_resources(exe, *pe, kRtIcon, images); !problem.empty()) return damaged_resources("icon", problem);

    // A 32-bit uncompressed BMP image of a square size: the placeholder's.
    PeIconPatch result;
    struct Target {
        std::uint64_t offset;
        std::uint32_t width;
    };
    std::vector<Target> targets;
    const View v{exe};
    for (const ResourceData& r : images) {
        const std::uint32_t width = r.size >= kBitmapHeaderSize ? v.u32(r.offset + 4) : 0;
        const bool bmp = r.size >= kBitmapHeaderSize && v.u32(r.offset) == kBitmapHeaderSize && width >= 1 && width <= 256 &&
                         v.u32(r.offset + 8) == width * 2 && v.u16(r.offset + 12) == 1 && v.u16(r.offset + 14) == 32 &&
                         v.u32(r.offset + 16) == 0 && r.size == bmp_image_length(width);
        if (bmp) targets.push_back({r.offset, width});
        else ++result.skipped;
    }
    if (targets.empty()) return result;  // nothing to replace: the file stays exactly as it is

    // ---- from here on the file is changed -----------------------------------------------------------------------
    for (const Target& t : targets) {
        const std::vector<std::uint8_t> image = icon_bmp_entry(icon, int(t.width));
        std::copy(image.begin(), image.end(), exe.begin() + std::ptrdiff_t(t.offset));
        result.sizes.push_back(int(t.width));
        ++result.replaced;
    }
    finish_patch(exe, *pe, result.signatureRemoved, result.truncated);
    return result;
}

Result<PeVersionPatch> patch_pe_version(std::vector<std::uint8_t>& exe, const PeVersionInfo& info) {
    auto pe = read_layout(exe, "version information");
    if (!pe.ok()) return pe.error();
    std::vector<ResourceData> found;
    if (std::string problem = find_resources(exe, *pe, kRtVersion, found); !problem.empty())
        return damaged_resources("version information", problem);

    // VS_VERSIONINFO is a tree of blocks: {WORD wLength; WORD wValueLength; WORD wType; WCHAR szKey[]; padding to 4;
    // value; padding to 4; children}. The root ("VS_VERSION_INFO") holds VS_FIXEDFILEINFO, its StringFileInfo child the
    // string tables, whose children are the strings. A string's room is its block minus the terminating NUL: what
    // follows the key up to the block's end, whatever wValueLength says (compilers count it in bytes or in characters).
    struct Edit {
        std::uint64_t offset;
        std::u16string text;  // already padded with NULs to the room
    };
    std::vector<Edit> edits;
    std::uint64_t fixedInfo = 0;
    PeVersionPatch result;
    const View v{exe};
    for (const ResourceData& res : found) {
        std::vector<Edit> resEdits;
        std::uint64_t resFixedInfo = 0;
        std::vector<std::string> truncated;
        const std::uint64_t resEnd = res.offset + res.size;
        int blocks = 0;
        auto walk = [&](auto&& self, std::uint64_t at, std::uint64_t end, int depth) -> bool {
            if (!v.has(at, 6) || ++blocks > 4096 || depth > 3) return false;
            const std::uint64_t len = v.u16(at), valueLen = v.u16(at + 2), type = v.u16(at + 4), blockEnd = at + len;
            if (len < 6 || blockEnd > end) return false;
            std::string key;  // the keys are ASCII
            std::uint64_t k = at + 6;
            for (; k + 2 <= blockEnd && v.u16(k) != 0; k += 2) key += v.u16(k) < 0x80 ? char(v.u16(k)) : '?';
            if (k + 2 > blockEnd) return false;
            const std::uint64_t value = (k + 2 + 3) & ~std::uint64_t(3);
            if (depth == 0) {
                if (key != "VS_VERSION_INFO") return false;
                if (valueLen >= 52 && value + 52 <= blockEnd && v.u32(value) == kFixedFileInfoSignature) resFixedInfo = value;
            }
            if (depth == 3) {  // a string of a string table
                if (type != 1 || value + 2 > blockEnd) return true;
                const auto want = info.strings.find(key);
                if (want == info.strings.end()) return true;
                const std::size_t room = std::size_t((blockEnd - value) / 2) - 1;
                std::u16string text = utf8_to_utf16(want->second);
                if (text.size() > room) {
                    text.resize(room);
                    if (room > 0 && text.back() >= 0xD800 && text.back() < 0xDC00) text.back() = 0;  // half a surrogate pair
                    truncated.push_back(key);
                }
                text.resize(room + 1, u'\0');
                resEdits.push_back({value, text});
                return true;
            }
            const std::uint64_t valueBytes = type == 1 ? valueLen * 2 : valueLen;
            for (std::uint64_t child = (value + valueBytes + 3) & ~std::uint64_t(3); child + 6 <= blockEnd;) {
                const std::uint64_t childLen = v.u16(child);
                if (!self(self, child, blockEnd, depth + 1)) return false;
                child = (child + childLen + 3) & ~std::uint64_t(3);
            }
            return true;
        };
        // A resource that is not a well-formed VS_VERSIONINFO is not the placeholder: it is left alone.
        if (!walk(walk, res.offset, resEnd, 0)) continue;
        edits = std::move(resEdits), fixedInfo = resFixedInfo, result.truncated = std::move(truncated);
        result.found = true;
        break;
    }
    if (!result.found) return result;  // the file stays exactly as it is

    // ---- from here on the file is changed -----------------------------------------------------------------------
    for (const Edit& e : edits)
        for (std::size_t i = 0; i < e.text.size(); ++i) put_u16(exe, e.offset + 2 * i, e.text[i]);
    if (fixedInfo != 0 && !info.version.empty()) {
        std::uint32_t n[4];
        version_numbers(info.version, n);
        for (std::uint64_t at : {fixedInfo + 8, fixedInfo + 16}) {  // dwFileVersionMS/LS, then dwProductVersionMS/LS
            put_u32(exe, at, (n[0] << 16) | n[1]);
            put_u32(exe, at + 4, (n[2] << 16) | n[3]);
        }
    }
    bool truncatedFile = false;
    finish_patch(exe, *pe, result.signatureRemoved, truncatedFile);
    return result;
}

}  // namespace fa
