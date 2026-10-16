// Windows PE files built in memory for the tests of the icon patcher and of the Windows export (no Windows toolchain
// needed): a resource tree with RT_ICON / RT_GROUP_ICON entries, an optional fake Authenticode certificate table, 32- and
// 64-bit headers.
#pragma once

#include <algorithm>
#include <cstdint>
#include <cstring>
#include <map>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/image.h"
#include "fa/tooling/icons.h"

namespace fa::testing::pe {

using Bytes = std::vector<std::uint8_t>;

inline void put16(Bytes& b, std::size_t off, std::uint32_t x) {
    for (int i = 0; i < 2; ++i) b[off + i] = std::uint8_t((x >> (8 * i)) & 0xff);
}
inline void put32(Bytes& b, std::size_t off, std::uint32_t x) {
    for (int i = 0; i < 4; ++i) b[off + i] = std::uint8_t((x >> (8 * i)) & 0xff);
}
inline std::uint32_t get32(const Bytes& b, std::size_t off) {
    return std::uint32_t(b[off]) | (std::uint32_t(b[off + 1]) << 8) | (std::uint32_t(b[off + 2]) << 16) | (std::uint32_t(b[off + 3]) << 24);
}

// A solid-colour square image with a transparent top-left quarter, so the AND mask is not all zero.
inline Image solid(int size, std::uint8_t r, std::uint8_t g, std::uint8_t b) {
    Image img;
    img.width = img.height = size;
    img.rgba.assign(std::size_t(size) * size * 4, 0);
    for (int y = 0; y < size; ++y)
        for (int x = 0; x < size; ++x) {
            std::uint8_t* p = &img.rgba[(std::size_t(y) * size + x) * 4];
            const bool hole = x < size / 4 && y < size / 4;
            p[0] = r, p[1] = g, p[2] = b, p[3] = hole ? 0 : 255;
        }
    return img;
}

struct Blob {
    std::uint32_t type, id;
    Bytes data;
};

struct PeFile {
    Bytes bytes;
    std::size_t optOffset = 0;                       // the optional header
    std::size_t textOffset = 0, textSize = 0;        // the .text raw data
    std::vector<std::size_t> blobOffset;             // file offset of each blob, in the order given
    std::size_t endOfSections = 0;                   // where an appended certificate table starts
};

struct PeOptions {
    bool pe32plus = true;
    bool resources = true;
    std::size_t certificate = 0;   // bytes of fake Authenticode data appended (a multiple of 8), 0 = unsigned
    std::size_t overlayAfter = 0;  // bytes appended AFTER the certificate table (a signed file never has them)
};

// The .rsrc section: root -> type -> name -> language -> data entry, then the data, 4-byte aligned.
inline Bytes build_resource_section(const std::vector<Blob>& blobs, std::uint32_t rva, std::vector<std::size_t>& dataOffsets) {
    std::map<std::uint32_t, std::vector<std::size_t>> byType;
    for (std::size_t i = 0; i < blobs.size(); ++i) byType[blobs[i].type].push_back(i);
    std::size_t cur = 16 + 8 * byType.size();
    std::map<std::uint32_t, std::size_t> typeDir;
    for (auto& [type, list] : byType) {
        typeDir[type] = cur;
        cur += 16 + 8 * list.size();
    }
    std::vector<std::size_t> nameDir(blobs.size()), dataEntry(blobs.size());
    for (std::size_t i = 0; i < blobs.size(); ++i) nameDir[i] = cur, cur += 16 + 8;
    for (std::size_t i = 0; i < blobs.size(); ++i) dataEntry[i] = cur, cur += 16;
    dataOffsets.assign(blobs.size(), 0);
    for (std::size_t i = 0; i < blobs.size(); ++i) {
        cur = (cur + 3) & ~std::size_t(3);
        dataOffsets[i] = cur;
        cur += blobs[i].data.size();
    }
    Bytes out((cur + 3) & ~std::size_t(3), 0);
    auto dir = [&](std::size_t at, std::size_t idEntries) { put16(out, at + 14, std::uint32_t(idEntries)); };
    dir(0, byType.size());
    std::size_t e = 16;
    for (auto& [type, list] : byType) {
        put32(out, e, type);
        put32(out, e + 4, 0x80000000u | std::uint32_t(typeDir[type]));
        e += 8;
        dir(typeDir[type], list.size());
        std::size_t t = typeDir[type] + 16;
        std::vector<std::size_t> sorted = list;
        std::sort(sorted.begin(), sorted.end(), [&](std::size_t a, std::size_t b) { return blobs[a].id < blobs[b].id; });
        for (std::size_t i : sorted) {
            put32(out, t, blobs[i].id);
            put32(out, t + 4, 0x80000000u | std::uint32_t(nameDir[i]));
            t += 8;
            dir(nameDir[i], 1);
            put32(out, nameDir[i] + 16, 0x0409);  // the language level
            put32(out, nameDir[i] + 20, std::uint32_t(dataEntry[i]));
            put32(out, dataEntry[i], rva + std::uint32_t(dataOffsets[i]));
            put32(out, dataEntry[i] + 4, std::uint32_t(blobs[i].data.size()));
            std::copy(blobs[i].data.begin(), blobs[i].data.end(), out.begin() + std::ptrdiff_t(dataOffsets[i]));
        }
    }
    return out;
}

inline PeFile build_pe(const std::vector<Blob>& blobs, PeOptions opt = {}) {
    PeFile pe;
    const std::size_t optSize = opt.pe32plus ? 112 + 16 * 8 : 96 + 16 * 8;
    const std::size_t peOff = 0x80, optOff = peOff + 24, sectionTable = optOff + optSize;
    const std::uint32_t textVa = 0x1000, rsrcVa = 0x2000;
    const std::size_t textRaw = 0x200, textRawSize = 0x200, rsrcRaw = 0x400;
    std::vector<std::size_t> dataOffsets;
    Bytes rsrc = opt.resources ? build_resource_section(blobs, rsrcVa, dataOffsets) : Bytes();
    const std::size_t rsrcRawSize = opt.resources ? (rsrc.size() + 0x1ff) & ~std::size_t(0x1ff) : 0;
    const std::size_t numSections = opt.resources ? 2 : 1;

    Bytes b(rsrcRaw + rsrcRawSize, 0);
    b[0] = 'M', b[1] = 'Z';
    put32(b, 0x3C, std::uint32_t(peOff));
    std::memcpy(&b[peOff], "PE\0\0", 4);
    put16(b, peOff + 4, opt.pe32plus ? 0x8664 : 0x14c);
    put16(b, peOff + 6, std::uint32_t(numSections));
    put16(b, peOff + 20, std::uint32_t(optSize));
    put16(b, peOff + 22, 0x22);
    put16(b, optOff, opt.pe32plus ? 0x20b : 0x10b);
    put32(b, optOff + 60, 0x200);                                                // SizeOfHeaders
    put32(b, optOff + (opt.pe32plus ? 108 : 92), 16);                            // NumberOfRvaAndSizes
    const std::size_t dirs = optOff + (opt.pe32plus ? 112 : 96);
    if (opt.resources) {
        put32(b, dirs + 2 * 8, rsrcVa);
        put32(b, dirs + 2 * 8 + 4, std::uint32_t(rsrc.size()));
    }
    auto section = [&](std::size_t i, const char* name, std::uint32_t va, std::size_t size, std::size_t raw, std::size_t rawSize) {
        const std::size_t s = sectionTable + i * 40;
        std::memcpy(&b[s], name, std::strlen(name));
        put32(b, s + 8, std::uint32_t(size));
        put32(b, s + 12, va);
        put32(b, s + 16, std::uint32_t(rawSize));
        put32(b, s + 20, std::uint32_t(raw));
    };
    section(0, ".text", textVa, textRawSize, textRaw, textRawSize);
    if (opt.resources) section(1, ".rsrc", rsrcVa, rsrc.size(), rsrcRaw, rsrcRawSize);
    for (std::size_t i = 0; i < textRawSize; ++i) b[textRaw + i] = std::uint8_t((i * 31 + 7) & 0xff);  // "code"
    if (opt.resources) std::copy(rsrc.begin(), rsrc.end(), b.begin() + std::ptrdiff_t(rsrcRaw));
    pe.endOfSections = b.size();
    if (opt.certificate) {
        put32(b, dirs + 4 * 8, std::uint32_t(b.size()));  // a FILE offset
        put32(b, dirs + 4 * 8 + 4, std::uint32_t(opt.certificate));
        for (std::size_t i = 0; i < opt.certificate; ++i) b.push_back(std::uint8_t(0xA0 + (i % 7)));
    }
    for (std::size_t i = 0; i < opt.overlayAfter; ++i) b.push_back(0xEE);
    put32(b, optOff + 64, 0xDEADBEEF);  // a stale checksum
    pe.bytes = std::move(b);
    pe.optOffset = optOff;
    pe.textOffset = textRaw;
    pe.textSize = textRawSize;
    for (std::size_t o : dataOffsets) pe.blobOffset.push_back(rsrcRaw + o);
    return pe;
}

// The loader's own algorithm (ChkSum of imagehlp): 16-bit words with the carry folded in after every addition, over the
// whole file with the CheckSum field counted as zero, plus the length.
inline std::uint32_t reference_checksum(Bytes b, std::size_t checksumOffset) {
    std::memset(&b[checksumOffset], 0, 4);
    std::uint32_t sum = 0;
    for (std::size_t i = 0; i < b.size(); i += 2) {
        sum += std::uint32_t(b[i]) | (i + 1 < b.size() ? std::uint32_t(b[i + 1]) << 8 : 0u);
        sum = (sum >> 16) + (sum & 0xffff);
    }
    sum = ((sum >> 16) + sum) & 0xffff;
    return sum + std::uint32_t(b.size());
}

// A PNG-looking image (skipped by the patcher) and a 32-bit BMP of `size` rendered from `icon` (what the placeholder holds).
inline Bytes png_blob() {
    Bytes b = {0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A};
    b.resize(300, 0x42);
    return b;
}
inline Bytes bmp(const Image& icon, int size) { return icon_bmp_entry(icon, size); }

// A VS_VERSIONINFO resource laid out as rc.exe writes it: the fixed file info (version 0.0.0.0), one string table
// (040904B0) holding `strings` (key, value; ASCII) and VarFileInfo. Each block is {wLength, wValueLength, wType, key,
// padding to 4, value, children each aligned to 4}.
inline Bytes version_blob(const std::vector<std::pair<std::string, std::string>>& strings) {
    auto align = [](Bytes& b) {
        while (b.size() % 4) b.push_back(0);
    };
    auto wide = [](const std::string& text) {
        Bytes b;
        for (char c : text) b.push_back(std::uint8_t(c)), b.push_back(0);
        b.push_back(0), b.push_back(0);
        return b;
    };
    auto block = [&](const std::string& key, std::uint32_t type, const Bytes& value, std::uint32_t valueLength,
                     const std::vector<Bytes>& children) {
        Bytes b(6, 0);
        const Bytes k = wide(key);
        b.insert(b.end(), k.begin(), k.end());
        align(b);
        b.insert(b.end(), value.begin(), value.end());
        for (const Bytes& c : children) {
            align(b);
            b.insert(b.end(), c.begin(), c.end());
        }
        put16(b, 0, std::uint32_t(b.size()));
        put16(b, 2, valueLength);
        put16(b, 4, type);
        return b;
    };
    std::vector<Bytes> table;
    for (const auto& [key, value] : strings) table.push_back(block(key, 1, wide(value), std::uint32_t(value.size() + 1), {}));
    Bytes fixed(52, 0);
    put32(fixed, 0, 0xFEEF04BDu);
    put32(fixed, 4, 0x10000);
    const Bytes translation = {0x09, 0x04, 0xB0, 0x04};
    return block("VS_VERSION_INFO", 0, fixed, 52,
                 {block("StringFileInfo", 1, {}, 0, {block("040904B0", 1, {}, 0, table)}),
                  block("VarFileInfo", 1, {}, 0, {block("Translation", 0, translation, 4, {})})});
}

// The version strings of factoria_player.rc: placeholders padded with spaces (room: 39 characters, 15 for versions).
inline Bytes placeholder_version_blob() {
    const std::string name(39, ' '), version(15, ' ');
    return version_blob({{"FileDescription", "FactorIA Player" + name.substr(15)}, {"ProductName", "FactorIA Player" + name.substr(15)},
                         {"FileVersion", version}, {"ProductVersion", version}, {"InternalName", name}, {"OriginalFilename", name}});
}

// The value of the version string `key` in `exe` ("" when the key is not there): the UTF-16 text after the key, aligned
// to 4 bytes, up to its NUL (ASCII only).
inline std::string version_string(const Bytes& exe, const std::string& key) {
    Bytes k;
    for (char c : key) k.push_back(std::uint8_t(c)), k.push_back(0);
    k.push_back(0), k.push_back(0);
    auto it = std::search(exe.begin(), exe.end(), k.begin(), k.end());
    if (it == exe.end()) return {};
    std::size_t at = ((std::size_t(it - exe.begin()) + k.size()) + 3) & ~std::size_t(3);
    std::string out;
    for (; at + 1 < exe.size() && (exe[at] || exe[at + 1]); at += 2) out += char(exe[at]);
    return out;
}

inline std::vector<Blob> placeholder_blobs(const Image& red) {
    return {{3, 1, bmp(red, 16)},   {3, 2, bmp(red, 32)}, {3, 3, bmp(red, 48)}, {3, 4, png_blob()},
            {14, 1, Bytes(34, 0x11)}, {16, 1, placeholder_version_blob()}};
}


}  // namespace fa::testing::pe
