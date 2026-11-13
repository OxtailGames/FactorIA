#include "fa/core/pack.h"

#include <algorithm>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <map>
#include <new>
#include <system_error>
#include <unordered_map>
#include <unordered_set>

#include "compress_internal.h"
#include "fa/core/strings.h"
#include "fs_internal.h"
#include "pack_file.h"

namespace stdfs = std::filesystem;

namespace fa {
namespace {

constexpr char kHeaderMagic[8] = {'F', 'A', 'P', 'A', 'C', 'K', '\r', '\n'};
constexpr char kFooterMagic[8] = {'F', 'A', 'P', 'K', 'E', 'N', 'D', '!'};
constexpr std::uint64_t kHeaderSize = 16;
constexpr std::uint64_t kFooterSize = 24;
constexpr std::uint32_t kRawBit = 0x80000000u;  // block table: the block is stored as it is
constexpr std::uint32_t kMinBlockSize = 4096, kMaxBlockSize = 64u << 20;

void put_u16(std::vector<std::uint8_t>& out, std::uint16_t v) {
    out.push_back(std::uint8_t(v & 0xff));
    out.push_back(std::uint8_t(v >> 8));
}
void put_u32(std::vector<std::uint8_t>& out, std::uint32_t v) {
    for (int i = 0; i < 4; ++i) out.push_back(std::uint8_t(v >> (8 * i)));
}
void put_u64(std::vector<std::uint8_t>& out, std::uint64_t v) {
    for (int i = 0; i < 8; ++i) out.push_back(std::uint8_t(v >> (8 * i)));
}
std::uint64_t get_le(const std::uint8_t* p, int bytes) {
    std::uint64_t v = 0;
    for (int i = 0; i < bytes; ++i) v |= std::uint64_t(p[i]) << (8 * i);
    return v;
}

// ---- XXH32 (the xxHash 32-bit algorithm, seed 0): the checksum of each block and of the index -----------------------
constexpr std::uint32_t kP1 = 2654435761u, kP2 = 2246822519u, kP3 = 3266489917u, kP4 = 668265263u, kP5 = 374761393u;
inline std::uint32_t rotl32(std::uint32_t x, int r) { return (x << r) | (x >> (32 - r)); }
inline std::uint32_t read32(const std::uint8_t* p) { return std::uint32_t(get_le(p, 4)); }
inline std::uint32_t xxh_round(std::uint32_t acc, std::uint32_t input) { return rotl32(acc + input * kP2, 13) * kP1; }

std::uint32_t xxh32(const std::uint8_t* p, std::size_t len) {
    const std::uint8_t* const end = p + len;
    std::uint32_t h;
    if (len >= 16) {
        const std::uint8_t* const limit = end - 16;
        std::uint32_t v1 = kP1 + kP2, v2 = kP2, v3 = 0, v4 = 0u - kP1;
        do {
            v1 = xxh_round(v1, read32(p));
            v2 = xxh_round(v2, read32(p + 4));
            v3 = xxh_round(v3, read32(p + 8));
            v4 = xxh_round(v4, read32(p + 12));
            p += 16;
        } while (p <= limit);
        h = rotl32(v1, 1) + rotl32(v2, 7) + rotl32(v3, 12) + rotl32(v4, 18);
    } else {
        h = kP5;
    }
    h += std::uint32_t(len);
    for (; end - p >= 4; p += 4) h = rotl32(h + read32(p) * kP3, 17) * kP4;
    for (; p < end; ++p) h = rotl32(h + std::uint32_t(*p) * kP5, 11) * kP1;
    h ^= h >> 15;
    h *= kP2;
    h ^= h >> 13;
    h *= kP3;
    h ^= h >> 16;
    return h;
}

std::string quoted(const stdfs::path& p) { return "'" + fs::path_to_utf8(p) + "'"; }

// FA_PACK_MAP=0 (or false / off / no) makes every pack this process opens read without a mapping.
bool env_allows_map() {
    const char* v = std::getenv("FA_PACK_MAP");
    if (!v || !*v) return true;
    const std::string s = to_lower(v);
    return !(s == "0" || s == "false" || s == "off" || s == "no");
}

const char* const kAgain = "Export the game again with this FactorIA version (`factoria export --release`).";

}  // namespace

std::uint32_t pack_checksum(std::span<const std::uint8_t> data) { return xxh32(data.data(), data.size()); }

Codec pack_default_codec(std::string_view path, std::span<const std::uint8_t> head) {
    const std::string ext = fs::extension(path);
    static const std::unordered_set<std::string> stored = {
        ".png",  ".jpg",   ".jpeg", ".webp", ".gif", ".avif", ".heic", ".basis", ".ogg",  ".oga",
        ".opus", ".mp3",   ".qoa",  ".flac", ".m4a", ".aac",  ".mp4",  ".m4v",   ".webm", ".mov",
        ".woff", ".woff2", ".zip",  ".gz",   ".zst", ".lz4",  ".7z",   ".xz",    ".bz2",  ".pak"};
    static const std::unordered_set<std::string> zstd = {".ttf",   ".otf", ".ttc",  ".txt",  ".md",   ".csv",  ".tsv",
                                                         ".xml",   ".svg", ".html", ".htm",  ".glsl", ".wgsl", ".hlsl",
                                                         ".metal", ".po",  ".pot",  ".yaml", ".yml",  ".ini",  ".fnt"};
    if (ext == ".ktx2") {
        // The header's supercompressionScheme (u32 at byte 44): 0 = the mip levels are raw texels, which compress.
        if (head.size() >= 48 && get_le(head.data() + 44, 4) == 0) return Codec::Lz4;
        return Codec::Store;
    }
    if (stored.count(ext)) return Codec::Store;
    if (zstd.count(ext)) return Codec::Zstd;
    return Codec::Lz4;  // JSON, scenes, scripts and bytecode, meshes, raw images and sounds, anything else
}

// ================================================================== PackWriter

Result<void> PackWriter::check_path(const std::string& path) const {
    auto n = fs::normalize_checked(path);
    if (!n.ok()) return n.error();
    if (path.empty() || n.value() != path || fs::is_absolute(path) || path.size() > 0xffff)
        return make_error(
            "Cannot pack '" + path + "': pack paths are normalized and project-relative",
            "Use forward slashes and no '.', '..' or leading '/', e.g. 'assets/hero.png' (at most 65535 bytes).");
    return {};
}

Result<void> PackWriter::add_bytes(std::string path, std::vector<std::uint8_t> data, std::optional<Codec> codec) {
    if (auto ok = check_path(path); !ok.ok()) return ok;
    Item item;
    item.codec = codec ? *codec : pack_default_codec(path, data);
    item.size = data.size();
    item.path = std::move(path);
    item.bytes = std::move(data);
    items_.push_back(std::move(item));
    return {};
}

Result<void> PackWriter::add_file(std::string path, stdfs::path source, std::optional<Codec> codec) {
    if (auto ok = check_path(path); !ok.ok()) return ok;
    std::error_code ec;
    const auto size = stdfs::file_size(fs::os_path(source), ec);
    if (ec)
        return make_error("Cannot pack '" + path + "': cannot read the size of " + quoted(source) + ": " + ec.message(),
                          "Check that the file exists and can be read.");
    Item item;
    if (codec) {
        item.codec = *codec;
    } else {
        std::vector<std::uint8_t> head(48);
        std::size_t got = 0;
        {
            fs::ReadStream in(fs::os_path(source), std::ios::binary);
            if (in) {
                in.read(reinterpret_cast<char*>(head.data()), std::streamsize(head.size()));
                got = std::size_t(in.gcount());
            }
        }
        head.resize(got);
        item.codec = pack_default_codec(path, head);
    }
    item.size = size;
    item.path = std::move(path);
    item.source = std::move(source);
    items_.push_back(std::move(item));
    return {};
}

void PackWriter::set_order(std::vector<std::string> paths) { order_ = std::move(paths); }

Result<PackStats> PackWriter::write(const stdfs::path& out) const {
    std::vector<const Item*> sorted;
    sorted.reserve(items_.size());
    for (const Item& item : items_) sorted.push_back(&item);
    std::sort(sorted.begin(), sorted.end(), [](const Item* a, const Item* b) { return a->path < b->path; });
    for (std::size_t i = 1; i < sorted.size(); ++i)
        if (sorted[i]->path == sorted[i - 1]->path)
            return make_error("Cannot write the pack: '" + sorted[i]->path + "' was added twice",
                              "Each path can be in a pack once; add the file under one name.");
    if (sorted.size() > 0xffffffffu)
        return make_error("Cannot write the pack: " + std::to_string(sorted.size()) +
                              " files are more than a pack holds",
                          "A pack holds at most 4294967295 files.");

    // The data order: set_order's paths first, then the rest by path.
    PackStats stats;
    std::vector<const Item*> dataOrder;
    dataOrder.reserve(sorted.size());
    {
        std::unordered_map<std::string_view, const Item*> byPath;
        for (const Item* item : sorted) byPath.emplace(item->path, item);
        std::unordered_set<const Item*> placed;
        for (const std::string& p : order_) {
            auto it = byPath.find(p);
            if (it != byPath.end() && placed.insert(it->second).second) dataOrder.push_back(it->second);
        }
        stats.orderedFiles = dataOrder.size();
        for (const Item* item : sorted)
            if (!placed.count(item)) dataOrder.push_back(item);
    }

    stdfs::path tmp = out;
    tmp += ".tmp";
    const stdfs::path osTmp = fs::os_path(tmp);
    std::error_code ec;
    std::ofstream file(osTmp, std::ios::binary | std::ios::trunc);
    if (!file) return make_error("Cannot create " + quoted(tmp), "Check that the folder exists and can be written to.");
    auto fail = [&](std::string message, std::string hint) -> Result<PackStats> {
        file.close();
        std::error_code rec;
        stdfs::remove(osTmp, rec);
        return make_error(std::move(message), std::move(hint));
    };
    std::uint64_t position = 0;
    auto put = [&](const void* data, std::uint64_t size) {
        file.write(static_cast<const char*>(data), std::streamsize(size));
        position += size;
    };

    std::vector<std::uint8_t> header(kHeaderMagic, kHeaderMagic + 8);
    put_u32(header, kPackFormatVersion);
    put_u32(header, 0);
    put(header.data(), header.size());

    struct Written {
        Codec codec = Codec::Store;
        std::uint64_t offset = 0, stored = 0;
        std::vector<std::uint32_t> blockStored, blockChecksum;  // stored size (with kRawBit), checksum
    };
    std::unordered_map<const Item*, Written> written;
    written.reserve(sorted.size());
    std::vector<std::uint8_t> raw(kPackBlockSize);
    const int level = level_;
    for (const Item* item : dataOrder) {
        Written w;
        w.offset = position;
        fs::ReadStream in;
        if (!item->source.empty()) {
            in.open(fs::os_path(item->source), std::ios::binary);
            if (!in)
                return fail("Cannot pack '" + item->path + "': cannot open " + quoted(item->source),
                            "Check that the file can be read.");
        }
        bool anyCompressed = false;
        std::uint64_t done = 0, keptRaw = 0;
        while (done < item->size) {
            const std::size_t want = std::size_t(std::min<std::uint64_t>(kPackBlockSize, item->size - done));
            const std::uint8_t* block = nullptr;
            if (item->source.empty()) {
                block = item->bytes.data() + done;
            } else {
                in.read(reinterpret_cast<char*>(raw.data()), std::streamsize(want));
                if (std::size_t(in.gcount()) != want)
                    return fail("Cannot pack '" + item->path + "': " + quoted(item->source) +
                                    " changed while the pack was written (" + std::to_string(item->size) +
                                    " bytes expected, " + std::to_string(done + std::uint64_t(in.gcount())) + " read)",
                                "Do not edit the game's files during an export; export again.");
                block = raw.data();
            }
            const std::span<const std::uint8_t> rawSpan(block, want);
            std::vector<std::uint8_t> packed;
            bool keep = false;
            if (item->codec != Codec::Store) {
                auto c = compress(rawSpan, CompressOptions{item->codec, level});
                if (!c.ok()) {
                    if (stats.compressErrors++ == 0) stats.firstCompressError = c.error().to_string();
                } else if (c.value().size() + std::max<std::size_t>(1, want / 32) <= want) {
                    packed = std::move(c.value());
                    keep = true;
                } else {
                    keptRaw++;
                }
            }
            const std::span<const std::uint8_t> storedSpan = keep ? std::span<const std::uint8_t>(packed) : rawSpan;
            put(storedSpan.data(), storedSpan.size());
            w.blockStored.push_back(std::uint32_t(storedSpan.size()) | (keep ? 0u : kRawBit));
            w.blockChecksum.push_back(xxh32(storedSpan.data(), storedSpan.size()));
            w.stored += storedSpan.size();
            anyCompressed = anyCompressed || keep;
            done += want;
            if (!file) return fail("Cannot write " + quoted(tmp), "Is the disk full?");
        }
        if (!item->source.empty() && in.peek() != std::char_traits<char>::eof())
            return fail("Cannot pack '" + item->path + "': " + quoted(item->source) +
                            " grew while the pack was written",
                        "Do not edit the game's files during an export; export again.");
        // Not one block saved enough: the file is recorded as stored (a reader then never runs the decoder for it).
        w.codec = anyCompressed ? item->codec : Codec::Store;
        if (anyCompressed) stats.blocksKeptRaw += keptRaw;
        PackCodecStats& cs = stats.codecs[std::size_t(w.codec)];
        cs.files++;
        cs.bytes += item->size;
        cs.storedBytes += w.stored;
        stats.files++;
        stats.bytes += item->size;
        stats.storedBytes += w.stored;
        written.emplace(item, std::move(w));
    }

    // The index: files by path, then the block table in the same order, then the index's own checksum.
    const std::uint64_t indexOffset = position;
    std::vector<std::uint8_t> index;
    std::uint64_t blockCount = 0;
    for (const Item* item : sorted) blockCount += written[item].blockStored.size();
    if (blockCount > 0xffffffffu)
        return fail("Cannot write the pack: it would have more than 4294967295 blocks", "Split the game's data.");
    put_u32(index, std::uint32_t(sorted.size()));
    put_u32(index, kPackBlockSize);
    put_u32(index, std::uint32_t(blockCount));
    std::uint32_t firstBlock = 0;
    for (const Item* item : sorted) {
        const Written& w = written[item];
        put_u16(index, std::uint16_t(item->path.size()));
        index.insert(index.end(), item->path.begin(), item->path.end());
        index.push_back(std::uint8_t(w.codec));
        put_u64(index, item->size);
        put_u64(index, w.offset);
        put_u64(index, w.stored);
        put_u32(index, firstBlock);
        firstBlock += std::uint32_t(w.blockStored.size());
    }
    for (const Item* item : sorted) {
        const Written& w = written[item];
        for (std::size_t b = 0; b < w.blockStored.size(); ++b) {
            put_u32(index, w.blockStored[b]);
            put_u32(index, w.blockChecksum[b]);
        }
    }
    put_u32(index, xxh32(index.data(), index.size()));
    put(index.data(), index.size());
    std::vector<std::uint8_t> footer;
    put_u64(footer, indexOffset);
    put_u64(footer, index.size());
    footer.insert(footer.end(), kFooterMagic, kFooterMagic + 8);
    put(footer.data(), footer.size());
    file.close();
    if (!file) return fail("Cannot write " + quoted(tmp), "Is the disk full?");
    stats.packBytes = position;
    // The readers refuse a file bigger than this pack may hold (pack_max_file_size): never write one.
    for (const Item* item : sorted)
        if (item->size > pack_max_file_size(position))
            return fail(
                "Cannot pack '" + item->path + "': its " + std::to_string(item->size) +
                    " bytes compress to so little that a pack of " + std::to_string(position) +
                    " bytes may not hold it (a file may be at most 64 times its pack's size, or 256 MiB)",
                "Store that file as it is: give its extension the codec \"store\" in factoria.json, export.pack.codecs "
                "(docs/EXPORTING.md).");

    fs::replace_file(osTmp, fs::os_path(out), ec);
    bool held = ec && fs::is_sharing_violation(ec) && ec != std::errc::permission_denied;  // the emulation's code
#ifdef _WIN32
    // MoveFileExW refuses a target another program has open (mapped or not) with ERROR_ACCESS_DENIED, the same code as
    // for a file this process may not write: an exclusive open of the target tells them apart.
    if (ec && !held && ec == std::errc::permission_denied) held = fs::detail::open_elsewhere(fs::os_path(out));
#endif
    if (held)
        return fail("Cannot replace " + quoted(out) + ": it is open in another program (" + ec.message() + ")",
                    "A running copy of the game has its pack open (Windows does not let a program replace a file "
                    "another one has "
                    "open). Close the game, and any program that has " +
                        fs::path_to_utf8(out.filename()) + " open, then export again. The old pack was not changed.");
    if (ec)
        return fail("Cannot move the finished pack to " + quoted(out) + ": " + ec.message(),
                    "Is a file of that name open in another program?");
    return stats;
}

// ================================================================== PackReader

PackReader::~PackReader() {
    if (!inMemory_) detail::pack_unmap(map_, mapSize_, mapping_);  // open_memory's bytes are not a mapping
    detail::pack_close(native_);
    // After the file is let go, as fs::ReadStream does: the registry never says closed while the file is still open.
    if (!registered_.empty())
        fs::detail::unregister_open_file(registered_, /*sharesDelete=*/map_ == nullptr);  // as registered
}

bool PackReader::read_at(std::uint64_t offset, void* dst, std::uint64_t size) const {
    if (size == 0) return true;
    if (map_) {
        if (offset > mapSize_ || size > mapSize_ - offset) return false;
        std::memcpy(dst, map_ + offset, std::size_t(size));
        return true;
    }
    return detail::pack_read_at(native_, offset, dst, size);
}

Result<std::shared_ptr<const PackReader>> PackReader::open(const stdfs::path& file, const PackOpenOptions& options) {
    const std::string name = quoted(file);
    std::error_code ec;
    const auto fileSize = stdfs::file_size(fs::os_path(file), ec);
    if (ec)
        return make_error("Cannot open the game pack " + name + ": " + ec.message(),
                          "Keep game.pak next to the game's executable (inside the .app on macOS).");
    std::shared_ptr<PackReader> pack(new PackReader());
    pack->file_ = file;
    pack->native_ = detail::pack_open(file);
    if (pack->native_ == -1) return make_error("Cannot open the game pack " + name, "Check that the file can be read.");
    if (const auto t = stdfs::last_write_time(fs::os_path(file), ec); !ec) pack->mtime_ = fs::file_time_ns(t);
    if (pack->mtime_ < 0) pack->mtime_ = 0;
    return finish_open(std::move(pack), name, fileSize, &file, options);
}

Result<std::shared_ptr<const PackReader>> PackReader::open_memory(std::vector<std::uint8_t> bytes, std::string name) {
    std::shared_ptr<PackReader> pack(new PackReader());
    pack->file_ = fs::path_from_utf8(name);
    pack->inMemory_ = true;
    pack->memory_ = std::move(bytes);
    pack->map_ = pack->memory_.data();
    pack->mapSize_ = pack->memory_.size();
    const std::uint64_t size = pack->mapSize_;
    return finish_open(std::move(pack), "'" + name + "'", size, nullptr, {});
}

Result<std::shared_ptr<const PackReader>> PackReader::finish_open(std::shared_ptr<PackReader> pack,
                                                                  const std::string& name, std::uint64_t fileSize,
                                                                  const stdfs::path* file,
                                                                  const PackOpenOptions& options) {
    const std::string again = kAgain;
    std::uint8_t header[kHeaderSize];
    if (fileSize < kHeaderSize + kFooterSize || !pack->read_at(0, header, kHeaderSize))
        return make_error("The game pack " + name + " is too small to be a pack (" + std::to_string(fileSize) +
                              " bytes)",
                          "It was probably cut short while it was copied or downloaded. " + again);
    if (std::memcmp(header, kHeaderMagic, 8) != 0)
        return make_error("The file " + name +
                              " is not a FactorIA game pack (it does not start with the pack signature)",
                          "Pass the game.pak that `factoria export --release` wrote, or a game folder.");
    const auto version = std::uint32_t(get_le(header + 8, 4));
    if (version != 1 && version != kPackFormatVersion)
        return make_error("The game pack " + name + " has format version " + std::to_string(version) +
                              "; this FactorIA reads versions 1 and " + std::to_string(kPackFormatVersion),
                          again);
    pack->version_ = version;
    std::uint8_t footer[kFooterSize];
    if (!pack->read_at(fileSize - kFooterSize, footer, kFooterSize) || std::memcmp(footer + 16, kFooterMagic, 8) != 0)
        return make_error("The game pack " + name + " is incomplete (its end marker is missing)",
                          "It was probably cut short while it was copied or downloaded. " + again);
    const std::uint64_t indexOffset = get_le(footer, 8), indexSize = get_le(footer + 8, 8);
    const std::uint64_t minIndex = version == 1 ? 4 : 16;
    if (indexOffset < kHeaderSize || indexSize < minIndex || indexOffset > fileSize - kFooterSize ||
        indexSize != fileSize - kFooterSize - indexOffset)
        return make_error("The game pack " + name + " is damaged (its index is outside the file)", again);
    if (indexSize > std::uint64_t(SIZE_MAX / 2))
        return make_error("The game pack " + name + " has an index too big for this device (" +
                              std::to_string(indexSize) + " bytes)",
                          again);

    std::vector<std::uint8_t> index;
    index.resize(std::size_t(indexSize));
    if (!pack->read_at(indexOffset, index.data(), indexSize))
        return make_error("Cannot read the index of the game pack " + name, "Check that the file can be read.");
    auto cut = [&] { return make_error("The game pack " + name + " is damaged (its index is cut short)", again); };
    std::size_t at = 0;
    std::uint64_t count = 0, blockTotal = 0;
    if (version == 1) {
        count = get_le(index.data(), 4);
        at = 4;
    } else {
        const std::size_t body = index.size() - 4;
        if (xxh32(index.data(), body) != read32(index.data() + body))
            return make_error("The game pack " + name + " is damaged (its index does not match its checksum)",
                              "The file changed after it was written (a bad copy, a damaged drive or download). " +
                                  again);
        index.resize(body);
        count = get_le(index.data(), 4);
        pack->blockSize_ = read32(index.data() + 4);
        blockTotal = get_le(index.data() + 8, 4);
        at = 12;
        if (pack->blockSize_ < kMinBlockSize || pack->blockSize_ > kMaxBlockSize)
            return make_error("The game pack " + name + " is damaged (its block size " +
                                  std::to_string(pack->blockSize_) + " is not possible)",
                              again);
    }
    pack->entries_.reserve(std::size_t(std::min<std::uint64_t>(count, indexSize / 18)));
    const std::uint64_t entryTail = version == 1 ? 16 : 29;  // the bytes after the path
    std::uint64_t nextBlock = 0;
    for (std::uint64_t i = 0; i < count; ++i) {
        if (at + 2 > index.size()) return cut();
        const std::size_t length = std::size_t(get_le(&index[at], 2));
        at += 2;
        if (at + length + entryTail > index.size()) return cut();
        Entry e;
        e.path.assign(reinterpret_cast<const char*>(&index[at]), length);
        at += length;
        if (version == 1) {
            e.offset = get_le(&index[at], 8);
            e.size = e.stored = get_le(&index[at + 8], 8);
        } else {
            const std::uint8_t codec = index[at];
            if (codec > std::uint8_t(Codec::Zstd))
                return make_error("The game pack " + name + " stores '" + e.path + "' with codec " +
                                      std::to_string(codec) + ", which this FactorIA does not know",
                                  again);
            e.codec = Codec(codec);
            e.size = get_le(&index[at + 1], 8);
            e.offset = get_le(&index[at + 9], 8);
            e.stored = get_le(&index[at + 17], 8);
            e.firstBlock = read32(&index[at + 25]);
            // Before anything trusts the size: a hostile index must not make a read allocate gigabytes (pack.h).
            if (e.size > pack_max_file_size(fileSize))
                return make_error("The game pack " + name + " is damaged ('" + e.path + "' claims " +
                                      std::to_string(e.size) + " bytes, more than a pack of " +
                                      std::to_string(fileSize) + " bytes may hold)",
                                  again);
            const std::uint64_t blocks = e.size / pack->blockSize_ + (e.size % pack->blockSize_ != 0 ? 1 : 0);
            if (e.firstBlock != nextBlock || blocks > blockTotal - std::min(blockTotal, nextBlock))
                return make_error("The game pack " + name + " is damaged (the blocks of '" + e.path +
                                      "' are not in its block table)",
                                  again);
            e.blockCount = std::uint32_t(blocks);
            nextBlock += blocks;
        }
        at += std::size_t(entryTail);
        if (e.offset < kHeaderSize || e.offset > indexOffset || e.stored > indexOffset - e.offset)
            return make_error("The game pack " + name + " is damaged ('" + e.path + "' lies outside the file)", again);
        if (!pack->entries_.empty() && !(pack->entries_.back().path < e.path))
            return make_error("The game pack " + name + " is damaged (its index is not sorted at '" + e.path + "')",
                              again);
        pack->entries_.push_back(std::move(e));
    }
    if (version == 1) {
        if (at != index.size())
            return make_error("The game pack " + name + " is damaged (its index has bytes after the last file)", again);
    } else {
        if (nextBlock != blockTotal || index.size() - at != blockTotal * 8)
            return make_error("The game pack " + name + " is damaged (its block table does not match its files)",
                              again);
        pack->blocks_.resize(std::size_t(blockTotal));
        for (const Entry& e : pack->entries_) {
            std::uint64_t offset = e.offset, sum = 0;
            for (std::uint32_t k = 0; k < e.blockCount; ++k) {
                Block& b = pack->blocks_[e.firstBlock + k];
                const std::uint32_t word = read32(&index[at]);
                b.checksum = read32(&index[at + 4]);
                at += 8;
                b.raw = (word & kRawBit) != 0;
                b.stored = word & ~kRawBit;
                b.offset = offset;
                const std::uint64_t decoded =
                    std::min<std::uint64_t>(pack->blockSize_, e.size - std::uint64_t(k) * pack->blockSize_);
                // A compressed block must be smaller than what it decodes to, and able to hold it: checked here, so no
                // read allocates or decodes a size the block could never give (a hostile index with a right checksum).
                const bool fits = b.raw ? b.stored == decoded
                                        : (b.stored > 0 && b.stored < decoded &&
                                           decoded <= codec::max_decoded_size(e.codec, b.stored));
                if (!fits || (e.codec == Codec::Store && !b.raw))
                    return make_error("The game pack " + name + " is damaged (block " + std::to_string(k + 1) +
                                          " of '" + e.path + "' has an impossible size)",
                                      again);
                offset += b.stored;
                sum += b.stored;
            }
            if (sum != e.stored)
                return make_error("The game pack " + name + " is damaged (the blocks of '" + e.path +
                                      "' do not add up to its size)",
                                  again);
        }
    }

    if (!file) return std::shared_ptr<const PackReader>(std::move(pack));  // in memory: nothing to map or register
    if (options.map && env_allows_map() && detail::pack_map(pack->native_, fileSize, pack->map_, pack->mapping_))
        pack->mapSize_ = fileSize;
    // Windows refuses to replace a file that is open, mapped or not (MoveFileExW onto it fails even with FILE_SHARE_DELETE),
    // and to delete a mapped one; an unmapped one shares delete (pack_file_win32.cpp), so a delete goes through: the
    // emulation does the same for as long as the reader lives.
    pack->registered_ = fs::detail::register_open_file(*file, /*sharesDelete=*/pack->map_ == nullptr);
    return std::shared_ptr<const PackReader>(std::move(pack));
}

const PackReader::Entry* PackReader::find(std::string_view path) const {
    auto it = std::lower_bound(entries_.begin(), entries_.end(), path,
                               [](const Entry& e, std::string_view p) { return e.path < p; });
    return it != entries_.end() && it->path == path ? &*it : nullptr;
}

Result<const PackReader::Entry*> PackReader::find_file(std::string_view path) const {
    if (const Entry* e = find(path)) return e;
    if (is_directory(path))
        return make_error("'" + std::string(path) + "' is a directory, not a file", "Use fs.list to see its contents.");
    return not_found(path, path);
}

bool PackReader::contains(std::string_view path) const { return find(path) != nullptr; }

bool PackReader::is_directory(std::string_view path) const {
    if (path.empty()) return true;
    std::string prefix(path);
    prefix += '/';
    auto it = std::lower_bound(entries_.begin(), entries_.end(), prefix,
                               [](const Entry& e, const std::string& p) { return e.path < p; });
    return it != entries_.end() && it->path.compare(0, prefix.size(), prefix) == 0;
}

std::int64_t PackReader::size_of(std::string_view path) const {
    const Entry* e = find(path);
    return e ? std::int64_t(e->size) : -1;
}

std::int64_t PackReader::stored_size_of(std::string_view path) const {
    const Entry* e = find(path);
    return e ? std::int64_t(e->stored) : -1;
}

Codec PackReader::codec_of(std::string_view path) const {
    const Entry* e = find(path);
    return e ? e->codec : Codec::Store;
}

Error PackReader::damaged(const Entry& e, std::uint32_t block, const std::string& what) const {
    return make_error("The game pack " + quoted(file_) + " is damaged: block " + std::to_string(block + 1) + " of " +
                          std::to_string(e.blockCount) + " of '" + e.path + "' " + what,
                      std::string("The file changed after it was written (a bad copy, a damaged drive or download). ") +
                          kAgain);
}

void PackReader::count(std::uint64_t bytes, std::uint64_t stored) const {
    reads_.fetch_add(1, std::memory_order_relaxed);
    bytesRead_.fetch_add(bytes, std::memory_order_relaxed);
    storedRead_.fetch_add(stored, std::memory_order_relaxed);
}

Result<void> PackReader::decode_range(const Entry& e, std::uint64_t from, std::span<std::uint8_t> out) const {
    if (out.empty()) return {};
    const auto readError = [&] {
        return make_error("Failed while reading '" + e.path + "' from the game pack " + quoted(file_),
                          "The pack may be damaged or on a drive that went away. Export the game again.");
    };
    if (e.blockCount == 0) {  // format 1: the bytes as they are, unchecked
        if (!read_at(e.offset + from, out.data(), out.size())) return readError();
        return {};
    }
    const std::uint64_t B = blockSize_, end = from + out.size();
    std::vector<std::uint8_t> storedBuf,
        decodedBuf;  // at most one block each, only when the block cannot go to `out` directly
    for (std::uint64_t k = from / B; k * B < end; ++k) {
        const Block& b = blocks_[std::size_t(e.firstBlock + k)];
        const std::uint64_t blockStart = k * B;
        const std::uint64_t blockLen = std::min<std::uint64_t>(B, e.size - blockStart);
        const std::uint64_t partStart = std::max(from, blockStart), partEnd = std::min(end, blockStart + blockLen);
        std::uint8_t* dest = out.data() + (partStart - from);
        const bool whole = partStart == blockStart && partEnd == blockStart + blockLen;
        // The block's stored bytes: in the mapping, or read into `dest` (a whole raw block) or a scratch buffer.
        const std::uint8_t* src = nullptr;
        if (map_) {
            src = map_ + b.offset;
        } else if (b.raw && whole) {
            if (!read_at(b.offset, dest, b.stored)) return readError();
            src = dest;
        } else {
            storedBuf.resize(b.stored);
            if (!read_at(b.offset, storedBuf.data(), b.stored)) return readError();
            src = storedBuf.data();
        }
        if (xxh32(src, b.stored) != b.checksum) return damaged(e, std::uint32_t(k), "does not match its checksum");
        if (b.raw) {
            if (src != dest) std::memcpy(dest, src + (partStart - blockStart), std::size_t(partEnd - partStart));
            continue;
        }
        const std::span<const std::uint8_t> block(src, b.stored);
        if (whole) {
            if (auto d = decompress_into(e.codec, block, std::span<std::uint8_t>(dest, std::size_t(blockLen))); !d.ok())
                return damaged(e, std::uint32_t(k), "cannot be decoded (" + d.error().message + ")");
        } else {
            decodedBuf.resize(std::size_t(blockLen));
            if (auto d = decompress_into(e.codec, block, decodedBuf); !d.ok())
                return damaged(e, std::uint32_t(k), "cannot be decoded (" + d.error().message + ")");
            std::memcpy(dest, decodedBuf.data() + (partStart - blockStart), std::size_t(partEnd - partStart));
        }
    }
    return {};
}

Result<std::vector<std::uint8_t>> PackReader::read(std::string_view path) const {
    auto e = find_file(path);
    if (!e.ok()) return e.error();
    return read_range(path, 0, e.value()->size);
}

Result<std::vector<std::uint8_t>> PackReader::read_range(std::string_view path, std::uint64_t offset,
                                                         std::uint64_t size) const {
    auto found = find_file(path);
    if (!found.ok()) return found.error();
    const Entry& e = *found.value();
    offset = std::min(offset, e.size);
    size = std::min(size, e.size - offset);
    if (size > std::uint64_t(SIZE_MAX / 2))
        return make_error("'" + e.path + "' is too big to read at once on this device (" + std::to_string(size) +
                              " bytes)",
                          "Read it in parts (fs streams, or a smaller range).");
    std::vector<std::uint8_t> data;
    try {
        data.resize(static_cast<std::size_t>(size));
    } catch (const std::bad_alloc&) {
        return make_error("Out of memory reading '" + e.path + "' from the game pack (" + std::to_string(size) +
                              " bytes)",
                          "Close other programs, or read it in parts (fs streams, or a smaller range).");
    }
    if (auto r = decode_range(e, offset, data); !r.ok()) return r.error();
    std::uint64_t stored = size;
    if (e.blockCount > 0 && size > 0) {
        stored = 0;
        for (std::uint64_t k = offset / blockSize_; k * blockSize_ < offset + size; ++k)
            stored += blocks_[std::size_t(e.firstBlock + k)].stored;
    }
    count(size, stored);
    return data;
}

Result<fs::FileView> PackReader::view(std::string_view path) const {
    auto found = find_file(path);
    if (!found.ok()) return found.error();
    const Entry& e = *found.value();
    if (map_ && e.codec == Codec::Store && e.size > 0) {
        for (std::uint32_t k = 0; k < e.blockCount; ++k) {
            const Block& b = blocks_[std::size_t(e.firstBlock) + k];
            if (xxh32(map_ + b.offset, b.stored) != b.checksum) return damaged(e, k, "does not match its checksum");
        }
        count(e.size, e.stored);
        return fs::FileView(shared_from_this(), map_ + e.offset, std::size_t(e.size), true);
    }
    auto bytes = read(path);
    if (!bytes.ok()) return bytes.error();
    return fs::FileView(std::move(bytes.value()));
}

std::vector<std::string> PackReader::data_order() const {
    std::vector<const Entry*> byOffset;
    byOffset.reserve(entries_.size());
    for (const Entry& e : entries_) byOffset.push_back(&e);
    // Equal offsets (empty files take no bytes): by path, as the writer placed them only relative to their neighbours.
    std::stable_sort(byOffset.begin(), byOffset.end(),
                     [](const Entry* a, const Entry* b) { return a->offset < b->offset; });
    std::vector<std::string> out;
    out.reserve(byOffset.size());
    for (const Entry* e : byOffset) out.push_back(e->path);
    return out;
}

PackReader::Counters PackReader::counters() const {
    return Counters{reads_.load(std::memory_order_relaxed), bytesRead_.load(std::memory_order_relaxed),
                    storedRead_.load(std::memory_order_relaxed)};
}

std::vector<std::string> PackReader::list(std::string_view dir, bool recursive) const {
    std::string prefix(dir);
    if (!prefix.empty() && prefix.back() != '/') prefix += '/';
    std::vector<std::string> out;
    auto it = std::lower_bound(entries_.begin(), entries_.end(), prefix,
                               [](const Entry& e, const std::string& p) { return e.path < p; });
    for (; it != entries_.end() && it->path.compare(0, prefix.size(), prefix) == 0; ++it) {
        if (!recursive && it->path.find('/', prefix.size()) != std::string::npos) continue;
        out.push_back(it->path);
    }
    return out;
}

Error PackReader::not_found(std::string_view requested, std::string_view normalized) const {
    std::string hint = "Paths are relative to the project root and, inside " + fs::path_to_utf8(file_.filename()) +
                       ", case-sensitive.";
    const std::string dir = fs::parent(normalized);
    std::vector<std::string> names = list(dir, false);
    std::string match = closest_match(normalized, names);
    if (match.empty()) {
        // Nothing alike in that folder (a wrong folder, a typo in it): look at every path of the pack.
        names.clear();
        for (const Entry& e : entries_) names.push_back(e.path);
        match = closest_match(normalized, names);
    }
    if (!match.empty())
        hint = "Did you mean '" + match + "'? " + hint;
    else if (!dir.empty() && !is_directory(dir))
        hint += " The folder '" + dir + "' is not in the pack.";
    return make_error("File not found: '" + std::string(requested) + "'", hint);
}

}  // namespace fa
