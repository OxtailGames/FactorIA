// The Vulkan pipeline cache on disk (docs/design/ARCHITECTURE_RENDERING_VULKAN.md): the VkPipelineCache's data read
// from VulkanOptions::pipelineCacheFile when the device is made and written back by save_pipeline_cache()
// (PipelineCacheFile in vulkan_device.h says what the file holds); the file's default place, and the storage buffer
// range helper, on every platform.
#include "gpu/vulkan_device.h"

#include "fa/core/fs.h"

namespace fa::gpu {

std::filesystem::path vulkan_pipeline_cache_file() {
    const std::filesystem::path dir = fs::cache_dir();
    if (dir.empty()) return {};
    return dir / "shaders" / "vulkan-pipelines.bin";
}

std::uint64_t storage_buffer_range(std::uint64_t bufferBytes, std::uint64_t offset, std::uint64_t maxRange) {
    const std::uint64_t rest = bufferBytes > offset ? bufferBytes - offset : 0;
    if (rest <= maxRange) return ~std::uint64_t(0);  // VK_WHOLE_SIZE
    return maxRange & ~std::uint64_t(3);
}

}  // namespace fa::gpu

#if defined(FA_VULKAN_BACKEND)

#include <cstdio>
#include <cstring>
#include <string>
#include <system_error>
#include <vector>

#include "fa/core/hash.h"
#include "fa/core/log.h"

namespace fa::gpu::vk {

namespace {

// A cache file bigger than this is not read (it would be one of thousands of pipelines; a damaged size field is
// likelier), and data bigger than this is not written.
constexpr std::int64_t kMaxPipelineCacheBytes = std::int64_t(1) << 30;

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

std::string uuid_text(const std::uint8_t* u) {
    std::string s;
    char b[4];
    for (unsigned i = 0; i < unsigned(VK_UUID_SIZE); ++i) {
        std::snprintf(b, sizeof b, "%02x", unsigned(u[i]));
        s += b;
        if (i == 3 || i == 5 || i == 7 || i == 9) s += '-';
    }
    return s;
}

}  // namespace

void VulkanDevice::cache_warning(const std::string& message) {
    FA_WARN("render", "{}", message);
    std::lock_guard<std::mutex> lock(msgMutex_);
    warnings_.push_back(message);
}

std::vector<std::uint8_t> VulkanDevice::load_pipeline_cache_file() {
    if (cacheFile_.empty()) return {};
    using F = PipelineCacheFile;
    const std::string file = fs::path_to_utf8(cacheFile_);
    std::string discard;  // why the file is thrown away; empty = kept (or there is none)
    std::vector<std::uint8_t> bytes;
    const std::int64_t size = fs::file_size(file);
    if (size < 0) return {};  // none yet: this run's pipelines make it
    if (size > kMaxPipelineCacheBytes) {
        discard = "it has " + std::to_string(size) + " bytes, more than the " + std::to_string(kMaxPipelineCacheBytes) +
                  " a pipeline cache may have";
    } else {
        auto read = fs::read_bytes(file);
        if (!read)
            discard = "it could not be read: " + read.error().message;
        else
            bytes = std::move(*read);
    }
    if (discard.empty()) {
        // Every check before the driver sees a byte: a damaged blob must not reach it.
        if (bytes.size() < F::kHeaderBytes) {
            discard = "it has " + std::to_string(bytes.size()) + " bytes, fewer than its header";
        } else if (std::memcmp(bytes.data(), F::kMagic, 8) != 0) {
            discard = "it is not a FactorIA Vulkan pipeline cache (its first bytes are not FAVKPSO)";
        } else if (read_at<std::uint32_t>(bytes, F::kVersionAt) != F::kVersion ||
                   read_at<std::uint32_t>(bytes, F::kHeaderBytesAt) != F::kHeaderBytes) {
            discard = "it is format version " + std::to_string(read_at<std::uint32_t>(bytes, F::kVersionAt)) +
                      " and this engine reads version " + std::to_string(F::kVersion);
        } else {
            const std::uint32_t vendor = read_at<std::uint32_t>(bytes, F::kVendorAt);
            const std::uint32_t deviceId = read_at<std::uint32_t>(bytes, F::kDeviceAt);
            const std::uint32_t driver = read_at<std::uint32_t>(bytes, F::kDriverAt);
            const std::uint64_t payload = read_at<std::uint64_t>(bytes, F::kPayloadBytesAt);
            const std::string checksum(reinterpret_cast<const char*>(bytes.data() + F::kPayloadSha256At), 64);
            const std::uint8_t* uuid = bytes.data() + F::kUuidAt;
            if (vendor != props_.vendorID || deviceId != props_.deviceID) {
                discard = "it was made on another GPU (vendor " + hex32(vendor) + ", device " + hex32(deviceId) +
                          "; this one is " + deviceName_ + ", vendor " + hex32(props_.vendorID) + ", device " +
                          hex32(props_.deviceID) + ")";
            } else if (driver != props_.driverVersion) {
                discard = "it was made by driver version " + hex32(driver) + " and this one is " +
                          hex32(props_.driverVersion);
            } else if (std::memcmp(uuid, props_.pipelineCacheUUID, VK_UUID_SIZE) != 0) {
                discard = "it was made for pipeline cache " + uuid_text(uuid) + " and this driver's is " +
                          uuid_text(props_.pipelineCacheUUID);
            } else if (payload != bytes.size() - F::kHeaderBytes) {
                discard = "it is damaged (its header says " + std::to_string(payload) +
                          " bytes of pipelines, it holds " + std::to_string(bytes.size() - F::kHeaderBytes) + ")";
            } else if (sha256_hex(bytes.data() + F::kHeaderBytes, std::size_t(payload)) != checksum) {
                discard = "it is damaged (its checksum does not match its bytes)";
            } else {
                // Vulkan's own header (VkPipelineCacheHeaderVersionOne), which the driver checks too: a file whose
                // outer header was rewritten by hand still has to match.
                const std::size_t at = F::kHeaderBytes;
                const std::uint32_t headerSize = payload >= F::kVkHeaderBytes ? read_at<std::uint32_t>(bytes, at) : 0;
                const std::uint32_t headerVersion =
                    payload >= F::kVkHeaderBytes ? read_at<std::uint32_t>(bytes, at + 4) : 0;
                if (payload < F::kVkHeaderBytes || headerSize < F::kVkHeaderBytes || headerSize > payload) {
                    discard = "its pipeline data has no Vulkan pipeline cache header";
                } else if (headerVersion != std::uint32_t(VK_PIPELINE_CACHE_HEADER_VERSION_ONE)) {
                    discard = "its pipeline data is Vulkan header version " + std::to_string(headerVersion) +
                              " (this engine reads version 1)";
                } else if (read_at<std::uint32_t>(bytes, at + 8) != props_.vendorID ||
                           read_at<std::uint32_t>(bytes, at + 12) != props_.deviceID ||
                           std::memcmp(bytes.data() + at + 16, props_.pipelineCacheUUID, VK_UUID_SIZE) != 0) {
                    discard = "its pipeline data was made for another GPU or driver (its Vulkan header names vendor " +
                              hex32(read_at<std::uint32_t>(bytes, at + 8)) + ", device " +
                              hex32(read_at<std::uint32_t>(bytes, at + 12)) + ", pipeline cache " +
                              uuid_text(bytes.data() + at + 16) + ")";
                }
            }
        }
    }
    if (!discard.empty()) {
        ++cacheDiscarded_;
        cacheDirty_ = true;  // the next save replaces the thrown-away file
        cache_warning("gpu vulkan: the pipeline cache " + file + " was thrown away: " + discard +
                      "; its pipelines are compiled again and the file is written anew (hint: nothing to fix; it "
                      "happens after a GPU or driver change, and deleting the file clears the cache)");
        return {};
    }
    cacheFileBytes_ = std::uint64_t(bytes.size());
    std::vector<std::uint8_t> data(bytes.begin() + std::ptrdiff_t(F::kHeaderBytes), bytes.end());
    cacheLoadedSha256_ = std::string(reinterpret_cast<const char*>(bytes.data() + F::kPayloadSha256At), 64);
    return data;
}

Result<void> VulkanDevice::save_pipeline_cache() {
    using F = PipelineCacheFile;
    std::vector<std::uint8_t> bytes;
    std::string checksum;
    {
        std::lock_guard<std::mutex> lock(cacheMutex_);
        if (cacheFile_.empty() || !pipelineCache_ || !cacheDirty_) return {};
        std::size_t payload = 0;
        VkResult r = fn_.vkGetPipelineCacheData(device_, pipelineCache_, &payload, nullptr);
        if (r == VK_SUCCESS && std::uint64_t(payload) > std::uint64_t(kMaxPipelineCacheBytes) - F::kHeaderBytes)
            return make_error("gpu vulkan: the pipeline cache has " + std::to_string(payload) +
                                  " bytes, more than a cache file may have; it is not written",
                              "a runaway number of distinct pipelines (VulkanDevice::counters().pipelinesCached says "
                              "how many the device keeps)");
        if (r == VK_SUCCESS) {
            bytes.resize(F::kHeaderBytes + payload);
            // VK_INCOMPLETE: the cache grew between the two calls (another thread made a pipeline); what fits is a
            // valid cache, and the next save takes the rest.
            r = fn_.vkGetPipelineCacheData(device_, pipelineCache_, &payload, bytes.data() + F::kHeaderBytes);
            if (r == VK_INCOMPLETE) r = VK_SUCCESS;
            bytes.resize(F::kHeaderBytes + payload);
        }
        if (r != VK_SUCCESS)
            return make_error("gpu vulkan: vkGetPipelineCacheData failed with " + result_text(r),
                              "the device was lost or out of memory; the old cache file was kept");
        checksum = sha256_hex(bytes.data() + F::kHeaderBytes, payload);
        cacheDirty_ = false;  // a pipeline made from here on makes it dirty again
        if (checksum == cacheLoadedSha256_) return {};  // the same data as the file holds: nothing new
    }
    std::memcpy(bytes.data(), F::kMagic, 8);
    write_at<std::uint32_t>(bytes, F::kVersionAt, F::kVersion);
    write_at<std::uint32_t>(bytes, F::kHeaderBytesAt, std::uint32_t(F::kHeaderBytes));
    write_at<std::uint32_t>(bytes, F::kVendorAt, props_.vendorID);
    write_at<std::uint32_t>(bytes, F::kDeviceAt, props_.deviceID);
    write_at<std::uint32_t>(bytes, F::kDriverAt, props_.driverVersion);
    std::memcpy(bytes.data() + F::kUuidAt, props_.pipelineCacheUUID, VK_UUID_SIZE);
    write_at<std::uint64_t>(bytes, F::kPayloadBytesAt, std::uint64_t(bytes.size() - F::kHeaderBytes));
    std::memcpy(bytes.data() + F::kPayloadSha256At, checksum.data(), 64);

    const std::string file = fs::path_to_utf8(cacheFile_);
    // A temporary file next to it, then a rename over the old one (fs::write_bytes, which makes the directory and takes
    // a long Windows path through fs::os_path): a reader never sees half a file, and a failed write (another process
    // holds the file open, which Windows does not let a rename replace; a full disk; a directory that cannot be
    // written) removes the temporary file and leaves the old one.
    auto written = fs::write_bytes(file, bytes.data(), bytes.size());
    std::lock_guard<std::mutex> lock(cacheMutex_);
    if (!written) {
        ++cacheStoreFailed_;
        cacheDirty_ = true;
        const std::string message = "gpu vulkan: the pipeline cache could not be written to " + file + ": " +
                                    written.error().message + "; the old file was kept";
        const std::string hint =
            "another process may hold the file open (Windows does not replace an open file), the directory cannot be "
            "written, or the disk is full; the cache is written again when the device is destroyed";
        cache_warning(message + " (hint: " + hint + ")");
        return make_error(message, hint);
    }
    ++cacheStored_;
    cacheFileBytes_ = std::uint64_t(bytes.size());
    cacheLoadedSha256_ = checksum;
    return {};
}

}  // namespace fa::gpu::vk

#endif  // FA_VULKAN_BACKEND
