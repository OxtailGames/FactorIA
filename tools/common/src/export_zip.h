// A small, deterministic zip writer shared by the web export (<slug>-web.zip, export_web.cpp) and the MSIX package
// (export_msix.cpp): entries are written in the order they are added, with the DOS date 1980-01-01 and UTF-8 names, so the same
// files give the same bytes whenever they are zipped. Entries are stored or raw-deflated (miniz, as vendored by the Basis
// Universal encoder this library links). Sizes and offsets stay 32-bit: an entry, the archive or its entry count over the
// classic limits is an Error that says so (a game that big does not fit a web zip or a Store package anyway).
//
// ZipStyle::opc is the layout of an MSIX package: the ZIP64 end of central directory that MakeAppx always writes (Windows reads
// a package through it, whatever its size), "made by" version 4.5, and no UTF-8 flag (part names are percent-encoded ASCII).
#pragma once

#include <cstdint>
#include <fstream>
#include <functional>
#include <string>
#include <string_view>
#include <vector>

#include "export_internal.h"

namespace fa::export_detail {

struct ZipEntry {
    std::string name;
    std::uint32_t crc = 0, compressedSize = 0, size = 0, offset = 0;
    std::uint16_t method = 0;  // 0 stored, 8 deflate
    std::uint32_t headerSize =
        0;  // the local file header: 30 + name (no extra field); the MSIX block map lists it as LfhSize
};

enum class ZipStyle { plain, opc };

class ZipWriter {
public:
    // Creates (replaces) `file`; opening can fail: let add() / finish() report it.
    explicit ZipWriter(const stdfs::path& file, ZipStyle style = ZipStyle::plain);
    ~ZipWriter();
    ZipWriter(const ZipWriter&) = delete;
    ZipWriter& operator=(const ZipWriter&) = delete;

    // Appends an entry. `deflate` compresses it when that makes it smaller; otherwise it is stored.
    Result<void> add(const std::string& name, std::string_view data, bool deflate);
    // Writes the central directory and closes the file. On any failure the partial file is removed.
    Result<void> finish();

    const std::vector<ZipEntry>& entries() const { return entries_; }

private:
    stdfs::path file_;
    ZipStyle style_;
    std::ofstream out_;
    std::string central_;
    std::vector<ZipEntry> entries_;
    std::uint64_t written_ = 0;
    bool failed_ = false, finished_ = false;
};

// The CRC-32 of `data` (the zip one).
std::uint32_t zip_crc32(std::string_view data);

// The names of the entries of the zip `file`, in the order of its central directory (a ZIP64 end record is followed).
Result<std::vector<std::string>> zip_entry_names(const stdfs::path& file);

// The uncompressed bytes of entry `name` of the zip `file` (stored or deflated; the CRC-32 is checked). The Error says what is
// wrong with the file or lists nothing found under that name.
// `maxSize` != 0 refuses an entry whose directory says it is bigger, and inflates into a buffer of exactly the declared size (an
// entry that inflates to more fails instead of growing): the reader for a zip somebody else made.
Result<std::string> zip_read_entry(const stdfs::path& file, const std::string& name, std::uint64_t maxSize = 0);

// What the central directory says about an entry (nothing is read or inflated).
struct ZipEntryInfo {
    std::string name;        // as stored (UTF-8 or the zip's own encoding: not checked here)
    std::uint64_t size = 0;  // uncompressed bytes
    std::uint64_t compressedSize = 0;
    bool directory = false;  // the name ends in '/'
    bool symlink = false;    // made on Unix with the symbolic link file type
    bool special = false;    // made on Unix as a device, pipe or socket
    bool encrypted = false;
};
Result<std::vector<ZipEntryInfo>> zip_entries(const stdfs::path& file);

// Calls `visit(entry, bytes)` for every entry in directory order (bytes of a folder are empty), reading each with the limit
// `maxEntrySize` (as `maxSize` of zip_read_entry: pass a real limit for a zip somebody else made). Stops at the first Error, of the reader or of `visit`.
Result<void> zip_each_entry(const stdfs::path& file, std::uint64_t maxEntrySize,
                            const std::function<Result<void>(const ZipEntryInfo&, std::string&&)>& visit);

}  // namespace fa::export_detail
