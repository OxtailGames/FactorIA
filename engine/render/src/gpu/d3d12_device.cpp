// make_d3d12_device() where Direct3D 12 does not exist: a teaching error. The Windows factory is in
// d3d12_device_win32.cpp (docs/design/ARCHITECTURE_RENDERING_GPU.md, "D3D12 backend"). The pipeline cache's file name,
// its header and the process totals are here, on every platform (the shader cache's report reads them, and their tests
// run everywhere).
#include "gpu/d3d12_device.h"

#include <atomic>
#include <cstdio>
#include <cstring>
#include <string_view>

#include "fa/core/fs.h"
#include "fa/core/hash.h"

namespace fa::gpu {

namespace {

std::atomic<std::uint64_t> g_libraryHits{0}, g_libraryMisses{0}, g_filesLoaded{0}, g_filesStored{0},
    g_filesDiscarded{0}, g_storeFailed{0}, g_filesTrimmed{0};

template <class T>
T read_at(const std::vector<std::uint8_t>& bytes, std::size_t at) {
    T v{};
    std::memcpy(&v, bytes.data() + at, sizeof v);
    return v;
}

template <class T>
void write_at(std::vector<std::uint8_t>& bytes, std::size_t at, T v) {
    std::memcpy(bytes.data() + at, &v, sizeof v);
}

std::string hex32(std::uint32_t v) {
    char text[16];
    std::snprintf(text, sizeof text, "0x%04x", unsigned(v));
    return text;
}

// The driver version DXGI reports as four 16-bit parts (31.0.101.5186).
std::string driver_text(std::uint64_t v) {
    return std::to_string((v >> 48) & 0xffffu) + "." + std::to_string((v >> 32) & 0xffffu) + "." +
           std::to_string((v >> 16) & 0xffffu) + "." + std::to_string(v & 0xffffu);
}

}  // namespace

void write_pipeline_cache_header(std::vector<std::uint8_t>& bytes, const PipelineCacheIdentity& id) {
    using F = PipelineCacheFile;
    if (bytes.size() < F::kHeaderBytes) bytes.resize(F::kHeaderBytes);
    std::memset(bytes.data(), 0, F::kHeaderBytes);
    std::memcpy(bytes.data(), F::kMagic, 8);
    write_at<std::uint32_t>(bytes, F::kVersionAt, F::kVersion);
    write_at<std::uint32_t>(bytes, F::kHeaderSizeAt, std::uint32_t(F::kHeaderBytes));
    write_at<std::uint32_t>(bytes, F::kVendorAt, id.vendor);
    write_at<std::uint32_t>(bytes, F::kVendorAt + 4, id.device);
    write_at<std::uint32_t>(bytes, F::kVendorAt + 8, id.subsys);
    write_at<std::uint32_t>(bytes, F::kVendorAt + 12, id.revision);
    write_at<std::uint64_t>(bytes, F::kDriverAt, id.driverVersion);
    write_at<std::uint32_t>(bytes, F::kLuidAt, id.luidLow);
    write_at<std::int32_t>(bytes, F::kLuidAt + 4, id.luidHigh);
    const std::size_t payload = bytes.size() - F::kHeaderBytes;
    write_at<std::uint64_t>(bytes, F::kPayloadSizeAt, std::uint64_t(payload));
    const std::string checksum = sha256_hex(bytes.data() + F::kHeaderBytes, payload);
    std::memcpy(bytes.data() + F::kChecksumAt, checksum.data(), 64);
}

std::string d3d12_removal_text(const std::string& reason, const std::string& during, const std::string& firstSeen,
                               const std::string& lastPipeline, const std::string& lastList) {
    std::string s = "; the device was removed";
    if (!during.empty()) s += " while " + during;
    s += ": " + reason;
    if (!firstSeen.empty() && firstSeen != during) s += "; first seen while " + firstSeen;
    if (!lastPipeline.empty()) s += "; last pipeline made or loaded: " + lastPipeline;
    if (!lastList.empty()) s += "; last list executed: " + lastList;
    return s;
}

std::string pipeline_cache_mismatch(const std::vector<std::uint8_t>& bytes, const PipelineCacheIdentity& self,
                                    const std::string& adapterName) {
    using F = PipelineCacheFile;
    // Every check before the driver sees a byte: a damaged blob must not reach it.
    if (bytes.size() < F::kHeaderBytes)
        return "it has " + std::to_string(bytes.size()) + " bytes, fewer than its header";
    if (std::memcmp(bytes.data(), F::kMagic, 8) != 0)
        return "it is not a FactorIA pipeline cache (its first bytes are not FAPSOLIB)";
    if (read_at<std::uint32_t>(bytes, F::kVersionAt) != F::kVersion ||
        read_at<std::uint32_t>(bytes, F::kHeaderSizeAt) != F::kHeaderBytes)
        return "it is format version " + std::to_string(read_at<std::uint32_t>(bytes, F::kVersionAt)) +
               " and this engine reads version " + std::to_string(F::kVersion);
    const std::uint32_t vendor = read_at<std::uint32_t>(bytes, F::kVendorAt);
    const std::uint32_t deviceId = read_at<std::uint32_t>(bytes, F::kVendorAt + 4);
    const std::uint32_t subsys = read_at<std::uint32_t>(bytes, F::kVendorAt + 8);
    const std::uint32_t revision = read_at<std::uint32_t>(bytes, F::kVendorAt + 12);
    const std::uint64_t driver = read_at<std::uint64_t>(bytes, F::kDriverAt);
    const std::uint64_t payload = read_at<std::uint64_t>(bytes, F::kPayloadSizeAt);
    // The LUID (kLuidAt) is not compared: Windows gives the adapter a new one at every boot.
    if (vendor != self.vendor || deviceId != self.device || subsys != self.subsys || revision != self.revision)
        return "it was made on another GPU (vendor " + hex32(vendor) + ", device " + hex32(deviceId) + ", subsystem " +
               hex32(subsys) + ", revision " + std::to_string(revision) + "; this one is " + adapterName + ", vendor " +
               hex32(self.vendor) + ", device " + hex32(self.device) + ", subsystem " + hex32(self.subsys) +
               ", revision " + std::to_string(self.revision) + ")";
    if (driver != self.driverVersion)
        return "it was made by driver " + driver_text(driver) + " and this one is " + driver_text(self.driverVersion);
    if (payload != bytes.size() - F::kHeaderBytes)
        return "it is damaged (its header says " + std::to_string(payload) + " bytes of pipelines, it holds " +
               std::to_string(bytes.size() - F::kHeaderBytes) + ")";
    const std::string checksum(reinterpret_cast<const char*>(bytes.data() + F::kChecksumAt), 64);
    if (sha256_hex(bytes.data() + F::kHeaderBytes, std::size_t(payload)) != checksum)
        return "it is damaged (its checksum does not match its bytes)";
    return {};
}

std::string d3d12_pipeline_cache_name(std::string_view program) {
    if (program.empty()) return "d3d12-pipelines.bin";
    std::string safe, folded;
    for (char c : program) {
        // Windows paths ignore case: Game.exe and game.exe share a file. Only ASCII is folded (this runs on every
        // platform, without the Win32 case tables): a program name that differs in the case of a non-ASCII letter
        // gets a file of its own, a duplicate of a cache and never a wrong one.
        if (c >= 'A' && c <= 'Z') c = char(c - 'A' + 'a');
        folded += c;
        const bool ok = (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '-' || c == '_';
        if (safe.size() < 48) safe += ok ? c : '_';
    }
    // The cleaned-up, cut name alone would give "Jóc" and "Jòc", or two long names with one start, the same file.
    return "d3d12-pipelines-" + safe + "-" + sha256_hex(folded).substr(0, 8) + ".bin";
}

CacheWriteFailure d3d12_classify_cache_write_error(unsigned winError, bool tempHeld, bool targetHeld,
                                                   bool targetReadOnly) {
    constexpr unsigned kAccessDenied = 5, kSharingViolation = 32, kLockViolation = 33, kUserMappedFile = 1224;
    const bool heldKind = winError == kSharingViolation || winError == kLockViolation || winError == kUserMappedFile;
    if (!heldKind && winError != kAccessDenied) return CacheWriteFailure::Other;
    if (tempHeld) return CacheWriteFailure::TempHeld;
    if (winError == kAccessDenied && targetReadOnly) return CacheWriteFailure::ReadOnlyFile;
    if (heldKind || targetHeld) return CacheWriteFailure::TargetHeld;
    return CacheWriteFailure::FolderDenied;
}

CacheReplacePolicy d3d12_cache_replace_policy(CacheWriteFailure kind) {
    switch (kind) {
        case CacheWriteFailure::TempHeld: return {8, 20};
        case CacheWriteFailure::TargetHeld:
        case CacheWriteFailure::FolderDenied: return {3, 1};
        case CacheWriteFailure::ReadOnlyFile:
        case CacheWriteFailure::Other: break;
    }
    return {};
}

std::string d3d12_cache_write_hint(CacheWriteFailure kind, std::string_view file) {
    const std::string f(file);
    switch (kind) {
        case CacheWriteFailure::TargetHeld:
            return "another process holds " + f +
                   " open (Windows replaces no open file): it is written again at the next save or the next run";
        case CacheWriteFailure::TempHeld:
            return "an antivirus or indexer held the temporary file next to " + f +
                   " open for longer than a save waits: it is written again at the next save or the next run; "
                   "excluding the cache folder from the scanner stops it";
        case CacheWriteFailure::ReadOnlyFile:
            return f + " has the read-only attribute: clear it (attrib -r \"" + f +
                   "\") or delete the file; the next save or the next run writes it then";
        case CacheWriteFailure::FolderDenied:
            return "Windows denied access to " + f +
                   " or its folder, for one of two reasons: the folder's or the file's permissions do not let this "
                   "user write (check them), or another program holds the file open in a way that allows its deletion "
                   "(a mapped view of it, a scanner: Windows then answers access denied, not a sharing violation; "
                   "close that program); the next save or the next run tries again";
        case CacheWriteFailure::Other: break;
    }
    return "check that the folder of " + f +
           " is writable and the disk has room; the next save or the next run tries again";
}

std::vector<std::string> d3d12_orphan_cache_temps(const std::vector<CacheFolderEntry>& entries,
                                                  std::string_view cacheFileName) {
    auto lower = [](char c) { return (c >= 'A' && c <= 'Z') ? char(c - 'A' + 'a') : c; };
    const std::string marker = ".fa-tmp";
    std::vector<std::string> orphans;
    if (cacheFileName.empty()) return orphans;
    for (const CacheFolderEntry& e : entries) {
        if (e.ageSeconds < kOrphanTempAgeSeconds) continue;
        const std::string_view name = e.name;
        if (name.size() <= cacheFileName.size() + marker.size()) continue;
        bool match = true;
        for (std::size_t i = 0; i < cacheFileName.size() && match; ++i)
            match = lower(name[i]) == lower(cacheFileName[i]);
        for (std::size_t i = 0; i < marker.size() && match; ++i) match = name[cacheFileName.size() + i] == marker[i];
        for (std::size_t i = cacheFileName.size() + marker.size(); i < name.size() && match; ++i)
            match = (name[i] >= '0' && name[i] <= '9') || name[i] == '_';
        if (match) orphans.push_back(e.name);
    }
    return orphans;
}

std::filesystem::path d3d12_pipeline_cache_file() {
    const std::filesystem::path dir = fs::cache_dir();
    if (dir.empty()) return {};
    return dir / "shaders" / fs::path_from_utf8(d3d12_pipeline_cache_name(d3d12_program_name()));
}

D3d12PipelineCacheTotals d3d12_pipeline_cache_totals() {
    D3d12PipelineCacheTotals t;
    t.libraryHits = g_libraryHits.load(std::memory_order_relaxed);
    t.libraryMisses = g_libraryMisses.load(std::memory_order_relaxed);
    t.filesLoaded = g_filesLoaded.load(std::memory_order_relaxed);
    t.filesStored = g_filesStored.load(std::memory_order_relaxed);
    t.filesDiscarded = g_filesDiscarded.load(std::memory_order_relaxed);
    t.storeFailed = g_storeFailed.load(std::memory_order_relaxed);
    t.filesTrimmed = g_filesTrimmed.load(std::memory_order_relaxed);
    return t;
}

void d3d12_pipeline_cache_count(const D3d12PipelineCacheTotals& add) {
    g_libraryHits.fetch_add(add.libraryHits, std::memory_order_relaxed);
    g_libraryMisses.fetch_add(add.libraryMisses, std::memory_order_relaxed);
    g_filesLoaded.fetch_add(add.filesLoaded, std::memory_order_relaxed);
    g_filesStored.fetch_add(add.filesStored, std::memory_order_relaxed);
    g_filesDiscarded.fetch_add(add.filesDiscarded, std::memory_order_relaxed);
    g_storeFailed.fetch_add(add.storeFailed, std::memory_order_relaxed);
    g_filesTrimmed.fetch_add(add.filesTrimmed, std::memory_order_relaxed);
}

}  // namespace fa::gpu

#if !defined(_WIN32)

#include <string>

namespace fa::gpu {

std::string d3d12_program_name() { return {}; }

Result<std::unique_ptr<Device>> make_d3d12_device(const D3d12Options&) {
    return make_error(std::string("gpu: the d3d12 backend runs on Windows only (this binary was built for another "
                                  "platform, whose sokol backend is ") +
                          backend_name(built_sokol_backend()) + ")",
                      "use make_device(built_sokol_backend()) here; Direct3D 12 exists only on Windows 10 and later");
}

}  // namespace fa::gpu

#endif
