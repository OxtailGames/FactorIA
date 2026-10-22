#include "export_zip.h"

#include <algorithm>
#include <cstdlib>

// miniz, as vendored by the Basis Universal encoder this library already links: raw deflate and CRC-32 for the zip.
#define MINIZ_HEADER_FILE_ONLY
#define MINIZ_NO_ZLIB_COMPATIBLE_NAMES
#include <encoder/basisu_miniz.h>

namespace fa::export_detail {

namespace {

void put16(std::string& o, std::uint32_t v) {
    o += static_cast<char>(v & 0xFF);
    o += static_cast<char>((v >> 8) & 0xFF);
}

void put32(std::string& o, std::uint32_t v) {
    put16(o, v & 0xFFFF);
    put16(o, v >> 16);
}

constexpr std::uint32_t kDosDate = (0 << 9) | (1 << 5) | 1;  // 1980-01-01: the same bytes for the same game, whenever it is zipped
constexpr std::uint32_t kUtf8Names = 0x0800;
constexpr std::uint64_t kClassicLimit = 0xFFFFFFFFull;  // sizes and offsets of a zip without ZIP64

}  // namespace

std::uint32_t zip_crc32(std::string_view data) {
    return static_cast<std::uint32_t>(buminiz::mz_crc32(buminiz::mz_crc32(0, nullptr, 0), reinterpret_cast<const unsigned char*>(data.data()), data.size()));
}

ZipWriter::ZipWriter(const stdfs::path& file) : file_(file) {
    std::error_code ec;
    stdfs::remove(os_path(file_), ec);
    out_.open(os_path(file_), std::ios::binary | std::ios::trunc);
    failed_ = !out_;
}

ZipWriter::~ZipWriter() {
    if (!finished_) {
        out_.close();
        std::error_code ec;
        stdfs::remove(os_path(file_), ec);
    }
}

Result<void> ZipWriter::add(const std::string& name, std::string_view data, bool deflate) {
    if (failed_) return err("export: cannot write " + generic(file_));
    if (entries_.size() >= 0xFFFF || name.size() > 0xFFFF)
        return err("export: the zip would have more than 65535 entries, more than a zip made here can hold", "Ship fewer files: pack them (export --release writes one game.pak).");
    if (data.size() >= kClassicLimit || written_ + data.size() + 30 + name.size() >= kClassicLimit)
        return err("export: " + name + " would take the zip over 4 GB, more than a zip made here can hold", "Make the game smaller (docs/ASSETS.md, \"Import settings\").");
    ZipEntry e;
    e.name = name;
    e.size = static_cast<std::uint32_t>(data.size());
    e.crc = zip_crc32(data);
    std::string_view body = data;
    std::string deflated;
    if (deflate && !data.empty()) {
        std::size_t n = 0;
        void* heap = buminiz::tdefl_compress_mem_to_heap(data.data(), data.size(), &n, 1024);  // raw deflate, 1024 probes
        if (heap) {
            if (n < data.size()) deflated.assign(static_cast<const char*>(heap), n);
            std::free(heap);
        }
    }
    if (!deflated.empty()) {
        e.method = 8;
        body = deflated;
    }
    e.compressedSize = static_cast<std::uint32_t>(body.size());
    e.offset = static_cast<std::uint32_t>(written_);
    e.headerSize = static_cast<std::uint32_t>(30 + name.size());
    std::string header;
    put32(header, 0x04034b50);
    put16(header, 20);
    put16(header, kUtf8Names);
    put16(header, e.method);
    put16(header, 0);
    put16(header, kDosDate);
    put32(header, e.crc);
    put32(header, e.compressedSize);
    put32(header, e.size);
    put16(header, static_cast<std::uint32_t>(name.size()));
    put16(header, 0);
    header += name;
    out_.write(header.data(), static_cast<std::streamsize>(header.size()));
    out_.write(body.data(), static_cast<std::streamsize>(body.size()));
    if (!out_) {
        failed_ = true;
        return err("export: cannot write " + generic(file_) + " (disk full?)");
    }
    written_ += header.size() + body.size();

    put32(central_, 0x02014b50);
    put16(central_, 20);
    put16(central_, 20);
    put16(central_, kUtf8Names);
    put16(central_, e.method);
    put16(central_, 0);
    put16(central_, kDosDate);
    put32(central_, e.crc);
    put32(central_, e.compressedSize);
    put32(central_, e.size);
    put16(central_, static_cast<std::uint32_t>(name.size()));
    put16(central_, 0);  // extra
    put16(central_, 0);  // comment
    put16(central_, 0);  // disk
    put16(central_, 0);  // internal attributes
    put32(central_, 0);  // external attributes
    put32(central_, e.offset);
    central_ += name;
    entries_.push_back(std::move(e));
    return {};
}

Result<void> ZipWriter::finish() {
    if (failed_) return err("export: cannot write " + generic(file_));
    if (written_ + central_.size() + 22 >= kClassicLimit)
        return err("export: the zip would be over 4 GB, more than a zip made here can hold", "Make the game smaller (docs/ASSETS.md, \"Import settings\").");
    std::string tail = central_;
    put32(tail, 0x06054b50);
    put16(tail, 0);
    put16(tail, 0);
    put16(tail, static_cast<std::uint32_t>(entries_.size()));
    put16(tail, static_cast<std::uint32_t>(entries_.size()));
    put32(tail, static_cast<std::uint32_t>(central_.size()));
    put32(tail, static_cast<std::uint32_t>(written_));
    put16(tail, 0);
    out_.write(tail.data(), static_cast<std::streamsize>(tail.size()));
    out_.close();
    if (!out_) {
        failed_ = true;
        return err("export: cannot write " + generic(file_) + " (disk full?)");
    }
    finished_ = true;
    return {};
}

namespace {

std::uint32_t get16(const std::string& s, std::size_t at) {
    return static_cast<std::uint8_t>(s[at]) | (static_cast<std::uint32_t>(static_cast<std::uint8_t>(s[at + 1])) << 8);
}

std::uint32_t get32(const std::string& s, std::size_t at) { return get16(s, at) | (get16(s, at + 2) << 16); }

struct CentralEntry {
    std::string name;
    std::uint32_t method = 0, crc = 0, compressedSize = 0, size = 0, offset = 0;
};

// The central directory of `file` (read from its end).
Result<std::vector<CentralEntry>> read_central_directory(const stdfs::path& file) {
    std::ifstream in(os_path(file), std::ios::binary);
    if (!in) return err("cannot open the zip " + generic(file));
    in.seekg(0, std::ios::end);
    const std::uint64_t total = static_cast<std::uint64_t>(in.tellg());
    const std::uint64_t tailSize = std::min<std::uint64_t>(total, 22 + 0xFFFF);
    std::string tail(tailSize, '\0');
    in.seekg(static_cast<std::streamoff>(total - tailSize));
    in.read(tail.data(), static_cast<std::streamsize>(tailSize));
    std::size_t eocd = std::string::npos;
    for (std::size_t i = tail.size() >= 22 ? tail.size() - 22 + 1 : 0; i-- > 0;)
        if (get32(tail, i) == 0x06054b50) {
            eocd = i;
            break;
        }
    if (eocd == std::string::npos) return err(generic(file) + " is not a zip (no end of central directory record)");
    const std::uint32_t count = get16(tail, eocd + 10), size = get32(tail, eocd + 12), offset = get32(tail, eocd + 16);
    if (static_cast<std::uint64_t>(offset) + size > total) return err(generic(file) + ": the central directory lies outside the file");
    std::string central(size, '\0');
    in.seekg(offset);
    in.read(central.data(), static_cast<std::streamsize>(size));
    std::vector<CentralEntry> out;
    std::size_t at = 0;
    for (std::uint32_t i = 0; i < count; ++i) {
        if (at + 46 > central.size() || get32(central, at) != 0x02014b50) return err(generic(file) + ": the central directory is damaged");
        CentralEntry e;
        e.method = get16(central, at + 10);
        e.crc = get32(central, at + 16);
        e.compressedSize = get32(central, at + 20);
        e.size = get32(central, at + 24);
        const std::size_t n = get16(central, at + 28), extra = get16(central, at + 30), comment = get16(central, at + 32);
        e.offset = get32(central, at + 42);
        if (at + 46 + n > central.size()) return err(generic(file) + ": the central directory is damaged");
        e.name = central.substr(at + 46, n);
        out.push_back(std::move(e));
        at += 46 + n + extra + comment;
    }
    return out;
}

}  // namespace

Result<std::vector<std::string>> zip_entry_names(const stdfs::path& file) {
    auto entries = read_central_directory(file);
    if (!entries.ok()) return entries.error();
    std::vector<std::string> names;
    for (const CentralEntry& e : *entries) names.push_back(e.name);
    return names;
}

Result<std::string> zip_read_entry(const stdfs::path& file, const std::string& name) {
    auto entries = read_central_directory(file);
    if (!entries.ok()) return entries.error();
    for (const CentralEntry& e : *entries) {
        if (e.name != name) continue;
        std::ifstream in(os_path(file), std::ios::binary);
        std::string header(30, '\0');
        in.seekg(e.offset);
        in.read(header.data(), 30);
        if (!in || get32(header, 0) != 0x04034b50) return err(generic(file) + ": the entry " + name + " has a damaged header");
        in.seekg(static_cast<std::streamoff>(e.offset) + 30 + get16(header, 26) + get16(header, 28));
        std::string packed(e.compressedSize, '\0');
        in.read(packed.data(), static_cast<std::streamsize>(e.compressedSize));
        if (!in) return err(generic(file) + ": the entry " + name + " is cut short");
        std::string data;
        if (e.method == 0) {
            data = std::move(packed);
        } else if (e.method == 8) {
            std::size_t n = 0;
            void* heap = buminiz::tinfl_decompress_mem_to_heap(packed.data(), packed.size(), &n, 0);
            if (!heap) return err(generic(file) + ": the entry " + name + " does not inflate");
            data.assign(static_cast<const char*>(heap), n);
            std::free(heap);
        } else {
            return err(generic(file) + ": the entry " + name + " uses compression method " + std::to_string(e.method) + ", which is not read here");
        }
        if (data.size() != e.size || zip_crc32(data) != e.crc) return err(generic(file) + ": the entry " + name + " does not match its CRC-32");
        return data;
    }
    return err(generic(file) + " has no entry " + name);
}

}  // namespace fa::export_detail
