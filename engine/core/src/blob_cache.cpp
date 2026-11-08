#include "fa/core/blob_cache.h"

#include <atomic>
#include <cstring>
#include <fstream>

#include "fa/core/fs.h"
#include "fa/core/hash.h"
#include "fa/core/log.h"

#ifdef _WIN32
#include <process.h>
#else
#include <unistd.h>
#endif

namespace stdfs = std::filesystem;

namespace fa {

namespace {

constexpr char kMagic[4] = {'F', 'A', 'B', 'C'};
constexpr std::size_t kMaxKeyBytes = 4096;
constexpr std::size_t kDigestChars = 64;  // SHA-256 as lowercase hex

void put_u32(std::vector<std::uint8_t>& v, std::uint32_t x) {
    for (int i = 0; i < 4; ++i) v.push_back(std::uint8_t(x >> (8 * i)));
}
void put_u64(std::vector<std::uint8_t>& v, std::uint64_t x) {
    for (int i = 0; i < 8; ++i) v.push_back(std::uint8_t(x >> (8 * i)));
}
std::uint32_t get_u32(const std::uint8_t* p) {
    std::uint32_t x = 0;
    for (int i = 0; i < 4; ++i) x |= std::uint32_t(p[i]) << (8 * i);
    return x;
}
std::uint64_t get_u64(const std::uint8_t* p) {
    std::uint64_t x = 0;
    for (int i = 0; i < 8; ++i) x |= std::uint64_t(p[i]) << (8 * i);
    return x;
}

bool valid_name(std::string_view name) {
    if (name.empty() || name.size() > 128 || name == "." || name == "..") return false;
    for (char c : name) {
        const bool ok = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '.' || c == '_' || c == '-';
        if (!ok) return false;
    }
    return true;
}

}  // namespace

const char* blob_cache_status_name(BlobCache::Status s) {
    switch (s) {
        case BlobCache::Status::Hit: return "hit";
        case BlobCache::Status::Miss: return "miss";
        case BlobCache::Status::Stale: return "stale";
        case BlobCache::Status::Damaged: return "damaged";
        case BlobCache::Status::Disabled: return "disabled";
    }
    return "?";
}

BlobCache::BlobCache(stdfs::path dir, std::string key) : dir_(std::move(dir)), key_(std::move(key)) {
    if (key_.size() > kMaxKeyBytes) key_.resize(kMaxKeyBytes);
}

stdfs::path BlobCache::file_for(std::string_view name) const {
    return dir_ / (std::string(name) + ".facache");
}

std::vector<std::uint8_t> BlobCache::encode(std::string_view key, std::span<const std::uint8_t> payload) {
    std::vector<std::uint8_t> out;
    out.reserve(payload.size() + key.size() + 4 + 4 + 4 + 8 + kDigestChars);
    out.insert(out.end(), kMagic, kMagic + 4);
    put_u32(out, kFormatVersion);
    put_u32(out, std::uint32_t(key.size()));
    out.insert(out.end(), key.begin(), key.end());
    put_u64(out, payload.size());
    const std::string digest = sha256_hex(payload.data(), payload.size());
    out.insert(out.end(), digest.begin(), digest.end());
    out.insert(out.end(), payload.begin(), payload.end());
    return out;
}

BlobCache::Status BlobCache::load(std::string_view name, std::vector<std::uint8_t>& out, std::string* why) const {
    out.clear();
    if (!enabled()) return Status::Disabled;
    if (!valid_name(name)) {
        if (why) *why = "cache name '" + std::string(name) + "' must be 1..128 letters, digits, '.', '_' or '-'";
        return Status::Miss;
    }
    const stdfs::path file = fs::os_path(file_for(name));
    // Open first and measure the opened file: a store that renames a new file over this one between a size query and the open
    // would otherwise give a size of one file and the bytes of the other.
    fs::ReadStream in(file, std::ios::binary);
    if (!in) return Status::Miss;  // no such file, or locked by a writer: absent
    in.seekg(0, std::ios::end);
    const std::streamoff endPos = in.tellg();
    in.seekg(0, std::ios::beg);
    if (endPos < 0 || !in) return Status::Miss;
    const std::uintmax_t size = std::uintmax_t(endPos);
    auto ignore = [&](Status status, const std::string& reason) {
        const std::string text = reason + "; ignoring " + fs::path_to_utf8(file_for(name)) + " (it is rebuilt and stored again)";
        if (why) *why = text;
        FA_INFO("cache", "{}", text);
        out.clear();
        return status;
    };
    // magic + version + key length + payload size + digest is the smallest a file can be.
    const std::size_t fixed = 4 + 4 + 4 + 8 + kDigestChars;
    if (size < fixed || size > kMaxBlobBytes + kMaxKeyBytes + fixed)
        return ignore(Status::Damaged, size < fixed ? "the cache file is cut short (" + std::to_string(size) + " bytes, a header alone is " +
                                                          std::to_string(fixed) + ")"
                                                    : "the cache file is bigger than the 64 MiB limit");
    std::vector<std::uint8_t> bytes(static_cast<std::size_t>(size));
    in.read(reinterpret_cast<char*>(bytes.data()), std::streamsize(bytes.size()));
    if (std::size_t(in.gcount()) != bytes.size()) return ignore(Status::Damaged, "the cache file could not be read completely");
    in.close();
    if (std::memcmp(bytes.data(), kMagic, 4) != 0) return ignore(Status::Damaged, "the file does not start with the cache magic (not a cache file)");
    if (get_u32(bytes.data() + 4) != kFormatVersion)
        return ignore(Status::Damaged, "the cache file has format version " + std::to_string(get_u32(bytes.data() + 4)) + ", this engine writes " +
                                           std::to_string(kFormatVersion));
    const std::uint32_t keyLen = get_u32(bytes.data() + 8);
    if (keyLen > kMaxKeyBytes || std::size_t(12) + keyLen + 8 + kDigestChars > bytes.size())
        return ignore(Status::Damaged, "the cache file is cut short (its key does not fit)");
    const std::string fileKey(reinterpret_cast<const char*>(bytes.data() + 12), keyLen);
    if (fileKey != key_)
        return ignore(Status::Stale, "the cache file was made for '" + fileKey + "', this run needs '" + key_ + "'");
    const std::uint8_t* p = bytes.data() + 12 + keyLen;
    const std::uint64_t payloadSize = get_u64(p);
    p += 8;
    const std::string digest(reinterpret_cast<const char*>(p), kDigestChars);
    p += kDigestChars;
    const std::size_t have = std::size_t(bytes.data() + bytes.size() - p);
    if (payloadSize > kMaxBlobBytes || payloadSize != have)
        return ignore(Status::Damaged, "the cache file is cut short or has extra bytes (its header says " + std::to_string(payloadSize) +
                                           " payload bytes, the file holds " + std::to_string(have) + ")");
    if (sha256_hex(p, have) != digest) return ignore(Status::Damaged, "the checksum of the cache file does not match its bytes");
    out.assign(p, p + have);
    return Status::Hit;
}

Result<void> BlobCache::store(std::string_view name, std::span<const std::uint8_t> payload) const {
    if (!enabled()) return make_error("The shader cache is off (no cache folder)", "Set fs::set_cache_dir() or the FA_CACHE_DIR environment variable.");
    if (!valid_name(name))
        return make_error("Cache name '" + std::string(name) + "' is not allowed", "Use 1..128 letters, digits, '.', '_' or '-'.");
    if (payload.size() > kMaxBlobBytes)
        return make_error("The blob '" + std::string(name) + "' is " + std::to_string(payload.size()) + " bytes", "A cache blob holds at most 64 MiB.");
    std::error_code ec;
    stdfs::create_directories(fs::os_path(dir_), ec);
    if (ec) return make_error("Cannot create the cache folder " + fs::path_to_utf8(dir_) + ": " + ec.message(), "Is the disk full or the folder read-only? The game runs without the cache.");
    const std::vector<std::uint8_t> bytes = encode(key_, payload);
    const stdfs::path target = file_for(name);
    static std::atomic<unsigned> counter{0};
#ifdef _WIN32
    const long long pid = _getpid();
#else
    const long long pid = static_cast<long long>(::getpid());
#endif
    stdfs::path tmp = target;
    tmp += ".tmp" + std::to_string(pid) + "_" + std::to_string(counter++);
    {
        std::ofstream out(fs::os_path(tmp), std::ios::binary | std::ios::trunc);
        if (!out) return make_error("Cannot open " + fs::path_to_utf8(tmp) + " for writing", "Is the cache folder read-only?");
        out.write(reinterpret_cast<const char*>(bytes.data()), std::streamsize(bytes.size()));
        out.close();
        if (!out) {
            std::error_code ignored;
            stdfs::remove(fs::os_path(tmp), ignored);
            return make_error("Failed while writing " + fs::path_to_utf8(tmp), "Is the disk full?");
        }
    }
    fs::replace_file(fs::os_path(tmp), fs::os_path(target), ec);
    if (ec) {
        std::error_code ignored;
        stdfs::remove(fs::os_path(tmp), ignored);
        return make_error("Cannot replace " + fs::path_to_utf8(target) + ": " + ec.message(),
                          "Another program may hold it open; the old file stays and the game runs without the new one.");
    }
    return {};
}

}  // namespace fa
