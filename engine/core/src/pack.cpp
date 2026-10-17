#include "fa/core/pack.h"

#include <algorithm>
#include <cerrno>
#include <cstring>
#include <fstream>
#include <system_error>

#ifdef _WIN32
#include <windows.h>
#else
#include <fcntl.h>
#include <unistd.h>
#endif

#include "fa/core/fs.h"
#include "fa/core/strings.h"

namespace stdfs = std::filesystem;

namespace fa {
namespace {

constexpr char kHeaderMagic[8] = {'F', 'A', 'P', 'A', 'C', 'K', '\r', '\n'};
constexpr char kFooterMagic[8] = {'F', 'A', 'P', 'K', 'E', 'N', 'D', '!'};
constexpr std::uint64_t kHeaderSize = 16;
constexpr std::uint64_t kFooterSize = 24;

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

// ---- positional reads: the file position is never used, so threads do not disturb each other -----------------------

std::intptr_t open_native(const stdfs::path& file) {
#ifdef _WIN32
    HANDLE h = CreateFileW(fs::os_path(file).c_str(), GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, nullptr,
                           OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_RANDOM_ACCESS, nullptr);
    return h == INVALID_HANDLE_VALUE ? -1 : reinterpret_cast<std::intptr_t>(h);
#else
    return ::open(file.c_str(), O_RDONLY);
#endif
}

void close_native(std::intptr_t native) {
    if (native == -1) return;
#ifdef _WIN32
    CloseHandle(reinterpret_cast<HANDLE>(native));
#else
    ::close(int(native));
#endif
}

std::string quoted(const stdfs::path& p) { return "'" + p.generic_string() + "'"; }

}  // namespace

// ================================================================== PackWriter

Result<void> PackWriter::check_path(const std::string& path) const {
    auto n = fs::normalize_checked(path);
    if (!n.ok()) return n.error();
    if (path.empty() || n.value() != path || fs::is_absolute(path) || path.size() > 0xffff)
        return make_error("Cannot pack '" + path + "': pack paths are normalized and project-relative",
                          "Use forward slashes and no '.', '..' or leading '/', e.g. 'assets/hero.png' (at most 65535 bytes).");
    return {};
}

Result<void> PackWriter::add_bytes(std::string path, std::vector<std::uint8_t> data) {
    if (auto ok = check_path(path); !ok.ok()) return ok;
    Item item;
    item.size = data.size();
    item.path = std::move(path);
    item.bytes = std::move(data);
    items_.push_back(std::move(item));
    return {};
}

Result<void> PackWriter::add_file(std::string path, stdfs::path source) {
    if (auto ok = check_path(path); !ok.ok()) return ok;
    std::error_code ec;
    const auto size = stdfs::file_size(fs::os_path(source), ec);
    if (ec)
        return make_error("Cannot pack '" + path + "': cannot read the size of " + quoted(source) + ": " + ec.message(),
                          "Check that the file exists and can be read.");
    Item item;
    item.size = size;
    item.path = std::move(path);
    item.source = std::move(source);
    items_.push_back(std::move(item));
    return {};
}

Result<void> PackWriter::write(const stdfs::path& out) const {
    std::vector<const Item*> sorted;
    sorted.reserve(items_.size());
    for (const Item& item : items_) sorted.push_back(&item);
    std::sort(sorted.begin(), sorted.end(), [](const Item* a, const Item* b) { return a->path < b->path; });
    for (std::size_t i = 1; i < sorted.size(); ++i)
        if (sorted[i]->path == sorted[i - 1]->path)
            return make_error("Cannot write the pack: '" + sorted[i]->path + "' was added twice",
                              "Each path can be in a pack once; add the file under one name.");

    stdfs::path tmp = out;
    tmp += ".tmp";
    const stdfs::path osTmp = fs::os_path(tmp);
    std::error_code ec;
    std::ofstream file(osTmp, std::ios::binary | std::ios::trunc);
    if (!file)
        return make_error("Cannot create " + quoted(tmp), "Check that the folder exists and can be written to.");
    auto fail = [&](std::string message, std::string hint) -> Result<void> {
        file.close();
        stdfs::remove(osTmp, ec);
        return make_error(std::move(message), std::move(hint));
    };
    auto put = [&](const void* data, std::uint64_t size) { file.write(static_cast<const char*>(data), std::streamsize(size)); };

    std::vector<std::uint8_t> header(kHeaderMagic, kHeaderMagic + 8);
    put_u32(header, kPackFormatVersion);
    put_u32(header, 0);
    put(header.data(), header.size());

    std::vector<std::uint64_t> offsets;
    offsets.reserve(sorted.size());
    std::uint64_t position = kHeaderSize;
    std::vector<char> buffer(std::size_t(1) << 20);
    for (const Item* item : sorted) {
        offsets.push_back(position);
        if (item->source.empty()) {
            put(item->bytes.data(), item->bytes.size());
        } else {
            std::ifstream in(fs::os_path(item->source), std::ios::binary);
            if (!in) return fail("Cannot pack '" + item->path + "': cannot open " + quoted(item->source), "Check that the file can be read.");
            std::uint64_t copied = 0;
            while (in) {
                in.read(buffer.data(), std::streamsize(buffer.size()));
                const auto got = std::uint64_t(in.gcount());
                if (got == 0) break;
                put(buffer.data(), got);
                copied += got;
            }
            if (copied != item->size)
                return fail("Cannot pack '" + item->path + "': " + quoted(item->source) + " changed while the pack was written (" +
                                std::to_string(item->size) + " bytes expected, " + std::to_string(copied) + " read)",
                            "Do not edit the game's files during an export; export again.");
        }
        position += item->size;
        if (!file) return fail("Cannot write " + quoted(tmp), "Is the disk full?");
    }

    std::vector<std::uint8_t> index;
    put_u32(index, std::uint32_t(sorted.size()));
    for (std::size_t i = 0; i < sorted.size(); ++i) {
        put_u16(index, std::uint16_t(sorted[i]->path.size()));
        index.insert(index.end(), sorted[i]->path.begin(), sorted[i]->path.end());
        put_u64(index, offsets[i]);
        put_u64(index, sorted[i]->size);
    }
    put(index.data(), index.size());
    std::vector<std::uint8_t> footer;
    put_u64(footer, position);
    put_u64(footer, index.size());
    footer.insert(footer.end(), kFooterMagic, kFooterMagic + 8);
    put(footer.data(), footer.size());
    file.close();
    if (!file) return fail("Cannot write " + quoted(tmp), "Is the disk full?");

    stdfs::rename(osTmp, fs::os_path(out), ec);
    if (ec) return fail("Cannot move the finished pack to " + quoted(out) + ": " + ec.message(), "Is a file of that name open in another program?");
    return {};
}

// ================================================================== PackReader

PackReader::~PackReader() { close_native(native_); }

bool PackReader::read_at(std::uint64_t offset, void* dst, std::uint64_t size) const {
    auto* out = static_cast<std::uint8_t*>(dst);
    while (size > 0) {
#ifdef _WIN32
        const DWORD chunk = DWORD(std::min<std::uint64_t>(size, std::uint64_t(1) << 28));
        OVERLAPPED at{};
        at.Offset = DWORD(offset & 0xffffffffu);
        at.OffsetHigh = DWORD(offset >> 32);
        DWORD got = 0;
        if (!ReadFile(reinterpret_cast<HANDLE>(native_), out, chunk, &got, &at) || got == 0) return false;
#else
        const std::size_t chunk = std::size_t(std::min<std::uint64_t>(size, std::uint64_t(1) << 30));
        ssize_t got = ::pread(int(native_), out, chunk, off_t(offset));
        if (got < 0 && errno == EINTR) continue;
        if (got <= 0) return false;
#endif
        out += got;
        offset += std::uint64_t(got);
        size -= std::uint64_t(got);
    }
    return true;
}

Result<std::shared_ptr<const PackReader>> PackReader::open(const stdfs::path& file) {
    const std::string name = quoted(file);
    const std::string again = "Export the game again with this FactorIA version (`factoria export --release`).";
    std::error_code ec;
    const auto fileSize = stdfs::file_size(fs::os_path(file), ec);
    if (ec)
        return make_error("Cannot open the game pack " + name + ": " + ec.message(),
                          "Keep game.pak next to the game's executable (inside the .app on macOS).");
    std::shared_ptr<PackReader> pack(new PackReader());
    pack->file_ = file;
    pack->native_ = open_native(file);
    if (pack->native_ == -1) return make_error("Cannot open the game pack " + name, "Check that the file can be read.");
    if (const auto t = stdfs::last_write_time(fs::os_path(file), ec); !ec) pack->mtime_ = std::int64_t(t.time_since_epoch().count());
    if (pack->mtime_ < 0) pack->mtime_ = 0;

    std::uint8_t header[kHeaderSize];
    if (fileSize < kHeaderSize + kFooterSize || !pack->read_at(0, header, kHeaderSize))
        return make_error("The game pack " + name + " is too small to be a pack (" + std::to_string(fileSize) + " bytes)",
                          "It was probably cut short while it was copied or downloaded. " + again);
    if (std::memcmp(header, kHeaderMagic, 8) != 0)
        return make_error("The file " + name + " is not a FactorIA game pack (it does not start with the pack signature)",
                          "Pass the game.pak that `factoria export --release` wrote, or a game folder.");
    const auto version = std::uint32_t(get_le(header + 8, 4));
    if (version != kPackFormatVersion)
        return make_error("The game pack " + name + " has format version " + std::to_string(version) + "; this FactorIA reads version " +
                              std::to_string(kPackFormatVersion),
                          again);
    std::uint8_t footer[kFooterSize];
    if (!pack->read_at(fileSize - kFooterSize, footer, kFooterSize) || std::memcmp(footer + 16, kFooterMagic, 8) != 0)
        return make_error("The game pack " + name + " is incomplete (its end marker is missing)",
                          "It was probably cut short while it was copied or downloaded. " + again);
    const std::uint64_t indexOffset = get_le(footer, 8), indexSize = get_le(footer + 8, 8);
    if (indexOffset < kHeaderSize || indexSize < 4 || indexOffset + indexSize != fileSize - kFooterSize)
        return make_error("The game pack " + name + " is damaged (its index is outside the file)", again);

    std::vector<std::uint8_t> index;
    index.resize(std::size_t(indexSize));
    if (!pack->read_at(indexOffset, index.data(), indexSize))
        return make_error("Cannot read the index of the game pack " + name, "Check that the file can be read.");
    const std::uint64_t count = get_le(index.data(), 4);
    std::size_t at = 4;
    pack->entries_.reserve(std::size_t(std::min<std::uint64_t>(count, indexSize / 18)));
    for (std::uint64_t i = 0; i < count; ++i) {
        if (at + 2 > index.size()) return make_error("The game pack " + name + " is damaged (its index is cut short)", again);
        const std::size_t length = std::size_t(get_le(&index[at], 2));
        at += 2;
        if (at + length + 16 > index.size()) return make_error("The game pack " + name + " is damaged (its index is cut short)", again);
        Entry e;
        e.path.assign(reinterpret_cast<const char*>(&index[at]), length);
        at += length;
        e.offset = get_le(&index[at], 8);
        e.size = get_le(&index[at + 8], 8);
        at += 16;
        if (e.offset < kHeaderSize || e.offset > indexOffset || e.size > indexOffset - e.offset)
            return make_error("The game pack " + name + " is damaged ('" + e.path + "' lies outside the file)", again);
        if (!pack->entries_.empty() && !(pack->entries_.back().path < e.path))
            return make_error("The game pack " + name + " is damaged (its index is not sorted at '" + e.path + "')", again);
        pack->entries_.push_back(std::move(e));
    }
    return std::shared_ptr<const PackReader>(std::move(pack));
}

const PackReader::Entry* PackReader::find(std::string_view path) const {
    auto it = std::lower_bound(entries_.begin(), entries_.end(), path, [](const Entry& e, std::string_view p) { return e.path < p; });
    return it != entries_.end() && it->path == path ? &*it : nullptr;
}

bool PackReader::contains(std::string_view path) const { return find(path) != nullptr; }

bool PackReader::is_directory(std::string_view path) const {
    if (path.empty()) return true;
    std::string prefix(path);
    prefix += '/';
    auto it = std::lower_bound(entries_.begin(), entries_.end(), prefix, [](const Entry& e, const std::string& p) { return e.path < p; });
    return it != entries_.end() && it->path.compare(0, prefix.size(), prefix) == 0;
}

std::int64_t PackReader::size_of(std::string_view path) const {
    const Entry* e = find(path);
    return e ? std::int64_t(e->size) : -1;
}

Result<std::vector<std::uint8_t>> PackReader::read(std::string_view path) const {
    const Entry* e = find(path);
    if (!e) {
        if (is_directory(path))
            return make_error("'" + std::string(path) + "' is a directory, not a file", "Use fs.list to see its contents.");
        return not_found(path, path);
    }
    std::vector<std::uint8_t> data(std::size_t(e->size));
    if (e->size > 0 && !read_at(e->offset, data.data(), e->size))
        return make_error("Failed while reading '" + e->path + "' from the game pack " + quoted(file_),
                          "The pack may be damaged or on a drive that went away. Export the game again.");
    return data;
}

std::vector<std::string> PackReader::list(std::string_view dir, bool recursive) const {
    std::string prefix(dir);
    if (!prefix.empty() && prefix.back() != '/') prefix += '/';
    std::vector<std::string> out;
    auto it = std::lower_bound(entries_.begin(), entries_.end(), prefix, [](const Entry& e, const std::string& p) { return e.path < p; });
    for (; it != entries_.end() && it->path.compare(0, prefix.size(), prefix) == 0; ++it) {
        if (!recursive && it->path.find('/', prefix.size()) != std::string::npos) continue;
        out.push_back(it->path);
    }
    return out;
}

Error PackReader::not_found(std::string_view requested, std::string_view normalized) const {
    std::string hint = "Paths are relative to the project root and, inside " + file_.filename().generic_string() + ", case-sensitive.";
    const std::string dir = fs::parent(normalized);
    std::vector<std::string> names = list(dir, false);
    std::string match = closest_match(normalized, names);
    if (match.empty()) {
        // Nothing alike in that folder (a wrong folder, a typo in it): look at every path of the pack.
        names.clear();
        for (const Entry& e : entries_) names.push_back(e.path);
        match = closest_match(normalized, names);
    }
    if (!match.empty()) hint = "Did you mean '" + match + "'? " + hint;
    else if (!dir.empty() && !is_directory(dir)) hint += " The folder '" + dir + "' is not in the pack.";
    return make_error("File not found: '" + std::string(requested) + "'", hint);
}

}  // namespace fa
