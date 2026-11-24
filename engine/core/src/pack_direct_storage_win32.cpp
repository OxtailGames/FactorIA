// The DirectStorage runtime of the pack reader on Windows x64 (pack_direct_storage.h): dstorage.dll loaded at run time.
//
// The declarations below are the engine's own, written from Microsoft's public DirectStorage documentation (the
// interfaces, structures, enumerations and IIDs of dstorage.h, version 1.1 and later): only what a read into memory
// needs. No SDK header is used and nothing is linked: dstorage.dll and dstoragecore.dll are redistributable files that
// a Windows export with export.pack.directStorage puts next to the game (`factoria setup directstorage` fetches them).
// Their layouts are checked with static_asserts against the sizes and offsets the documentation gives for x64.
#if defined(_WIN64)

#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#include <unknwn.h>

#include <cstddef>
#include <cstdio>
#include <iterator>
#include <mutex>
#include <string>

#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "pack_direct_storage.h"

namespace fa::detail {

namespace {

// ---- the DirectStorage API (from the documentation of dstorage.h) ---------------------------------------------------

constexpr GUID kIidFactory = {0x6924ea0c, 0xc3cd, 0x4826, {0xb1, 0x0a, 0xf6, 0x4f, 0x4e, 0xd9, 0x27, 0xc1}};
constexpr GUID kIidFile = {0x5de95e7b, 0x955a, 0x4868, {0xa7, 0x3c, 0x24, 0x3b, 0x29, 0xf4, 0xb8, 0xda}};
constexpr GUID kIidStatusArray = {0x82397587, 0x7cd5, 0x453b, {0xa0, 0x2e, 0x31, 0x37, 0x9b, 0xd6, 0x46, 0x56}};
constexpr GUID kIidQueue = {0xcfdbd83f, 0x9e06, 0x4fda, {0x8e, 0xa5, 0x69, 0x04, 0x21, 0x37, 0xf4, 0x9b}};
constexpr GUID kIidQueue1 = {0xdd2f482c, 0x5eff, 0x41e8, {0x9c, 0x9e, 0xd2, 0x37, 0x4b, 0x27, 0x81, 0x28}};
constexpr GUID kIidCodec = {0x84ef5121, 0x9b43, 0x4d03, {0xb5, 0xc1, 0xcc, 0x34, 0x60, 0x6b, 0x26, 0x2d}};

constexpr std::uint64_t kSourceFile = 0;         // DSTORAGE_REQUEST_SOURCE_FILE
constexpr std::uint64_t kDestinationMemory = 0;  // DSTORAGE_REQUEST_DESTINATION_MEMORY
constexpr std::uint8_t kFormatNone = 0;          // DSTORAGE_COMPRESSION_FORMAT_NONE
constexpr std::uint8_t kFormatGDeflate = 1;      // DSTORAGE_COMPRESSION_FORMAT_GDEFLATE
constexpr std::int8_t kPriorityNormal = 0;       // DSTORAGE_PRIORITY_NORMAL
constexpr std::int32_t kCompressionDefault = 0;  // DSTORAGE_COMPRESSION_DEFAULT

// DSTORAGE_QUEUE_DESC.
struct DsQueueDesc {
    std::uint64_t sourceType = kSourceFile;
    std::uint16_t capacity = 0;
    std::int8_t priority = kPriorityNormal;
    const char* name = nullptr;
    void* device = nullptr;  // ID3D12Device*: none, the queue's destinations are memory
};
static_assert(sizeof(DsQueueDesc) == 32 && offsetof(DsQueueDesc, capacity) == 8 &&
              offsetof(DsQueueDesc, priority) == 10 && offsetof(DsQueueDesc, name) == 16 &&
              offsetof(DsQueueDesc, device) == 24);

// DSTORAGE_REQUEST with DSTORAGE_REQUEST_OPTIONS spelled out (a byte of format, 7 reserved bytes, then a 64-bit word whose
// bit 0 is the source type and bits 1-7 the destination type), the file member of the DSTORAGE_SOURCE union (24 bytes)
// and the memory member of the DSTORAGE_DESTINATION union (40 bytes: its largest member, the texture region, sets it).
struct DsRequest {
    std::uint8_t compressionFormat = kFormatNone;
    std::uint8_t reserved1[7] = {};
    std::uint64_t sourceAndDestination = kSourceFile | (kDestinationMemory << 1);
    void* sourceFile = nullptr;  // IDStorageFile*
    std::uint64_t sourceOffset = 0;
    std::uint32_t sourceSize = 0;
    std::uint32_t sourcePadding = 0;
    void* destinationBuffer = nullptr;
    std::uint32_t destinationSize = 0;
    std::uint8_t destinationRest[28] = {};
    std::uint32_t uncompressedSize = 0;
    std::uint64_t cancellationTag = 0;
    const char* name = nullptr;
};
static_assert(sizeof(DsRequest) == 104 && offsetof(DsRequest, sourceAndDestination) == 8 &&
              offsetof(DsRequest, sourceFile) == 16 && offsetof(DsRequest, sourceOffset) == 24 &&
              offsetof(DsRequest, sourceSize) == 32 && offsetof(DsRequest, destinationBuffer) == 40 &&
              offsetof(DsRequest, destinationSize) == 48 && offsetof(DsRequest, uncompressedSize) == 80 &&
              offsetof(DsRequest, cancellationTag) == 88 && offsetof(DsRequest, name) == 96);

// The interfaces, their methods in vtable order. Methods this file never calls keep their slot with a plain signature.
struct DsFile : IUnknown {
    virtual void STDMETHODCALLTYPE Close() = 0;
    virtual HRESULT STDMETHODCALLTYPE GetFileInformation(BY_HANDLE_FILE_INFORMATION* info) = 0;
};
struct DsStatusArray : IUnknown {
    virtual bool STDMETHODCALLTYPE IsComplete(UINT32 index) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetHResult(UINT32 index) = 0;
};
struct DsQueue : IUnknown {
    virtual void STDMETHODCALLTYPE EnqueueRequest(const DsRequest* request) = 0;
    virtual void STDMETHODCALLTYPE EnqueueStatus(DsStatusArray* statusArray, UINT32 index) = 0;
    virtual void STDMETHODCALLTYPE EnqueueSignal(void* fence, UINT64 value) = 0;
    virtual void STDMETHODCALLTYPE Submit() = 0;
    virtual void STDMETHODCALLTYPE CancelRequestsWithTag(UINT64 mask, UINT64 value) = 0;
    virtual void STDMETHODCALLTYPE Close() = 0;
    virtual HANDLE STDMETHODCALLTYPE GetErrorEvent() = 0;
    virtual void STDMETHODCALLTYPE RetrieveErrorRecord(void* record) = 0;
    virtual void STDMETHODCALLTYPE Query(void* info) = 0;
};
struct DsQueue1 : DsQueue {  // DirectStorage 1.1
    virtual void STDMETHODCALLTYPE EnqueueSetEvent(HANDLE handle) = 0;
};
struct DsFactory : IUnknown {
    virtual HRESULT STDMETHODCALLTYPE CreateQueue(const DsQueueDesc* desc, REFIID riid, void** ppv) = 0;
    virtual HRESULT STDMETHODCALLTYPE OpenFile(const WCHAR* path, REFIID riid, void** ppv) = 0;
    virtual HRESULT STDMETHODCALLTYPE CreateStatusArray(UINT32 capacity, PCSTR name, REFIID riid, void** ppv) = 0;
    virtual void STDMETHODCALLTYPE SetDebugFlags(UINT32 flags) = 0;
    virtual HRESULT STDMETHODCALLTYPE SetStagingBufferSize(UINT32 size) = 0;
};
struct DsCodec : IUnknown {
    virtual HRESULT STDMETHODCALLTYPE CompressBuffer(const void* uncompressedData, size_t uncompressedDataSize,
                                                     std::int32_t compressionSetting, void* compressedBuffer,
                                                     size_t compressedBufferSize, size_t* compressedDataSize) = 0;
    virtual HRESULT STDMETHODCALLTYPE DecompressBuffer(const void* compressedData, size_t compressedDataSize,
                                                       void* uncompressedBuffer, size_t uncompressedBufferSize,
                                                       size_t* uncompressedDataSize) = 0;
    virtual size_t STDMETHODCALLTYPE CompressBufferBound(size_t uncompressedDataSize) = 0;
};

using GetFactoryFn = HRESULT(WINAPI*)(REFIID riid, void** ppv);
using CreateCodecFn = HRESULT(WINAPI*)(std::uint8_t format, UINT32 numThreads, REFIID riid, void** ppv);

template <class T>
void release(T*& p) {
    if (p) p->Release();
    p = nullptr;
}

std::string hresult_text(HRESULT hr) {
    char buf[16];
    std::snprintf(buf, sizeof buf, "0x%08lX", static_cast<unsigned long>(hr));
    const char* what = "";
    switch (static_cast<unsigned long>(hr)) {
        case 0x89240007ul: what = " (E_DSTORAGE_END_OF_FILE: the request reads past the end of the file)"; break;
        case 0x89240008ul: what = " (E_DSTORAGE_REQUEST_TOO_LARGE)"; break;
        case 0x8924000Ful: what = " (E_DSTORAGE_INVALID_DESTINATION_SIZE)"; break;
        case 0x8924001Dul: what = " (E_DSTORAGE_SYSTEM_NOT_SUPPORTED: this Windows has no DirectStorage)"; break;
        case 0x89240030ul: what = " (E_DSTORAGE_DECOMPRESSION_ERROR: a block is not a valid GDeflate stream)"; break;
        case 0x89240039ul: what = " (E_DSTORAGE_COMPRESSED_DATA_TOO_LARGE)"; break;
        default: break;
    }
    return std::string(buf) + what;
}

// A variable of the environment as a path (wide, so no code page touches it); empty when unset.
std::wstring env_wide(const wchar_t* name) {
    wchar_t buf[2048];
    const DWORD n = GetEnvironmentVariableW(name, buf, DWORD(std::size(buf)));
    return n > 0 && n < std::size(buf) ? std::wstring(buf, n) : std::wstring();
}

std::filesystem::path executable_folder() {
    std::wstring buf(32768, L'\0');
    const DWORD n = GetModuleFileNameW(nullptr, buf.data(), DWORD(buf.size()));
    if (n == 0 || n >= buf.size()) return {};
    buf.resize(n);
    return std::filesystem::path(buf).parent_path();
}

// The process's DirectStorage runtime: loaded on first use and never unloaded (its worker threads live as long as the
// process), so it is a leaked singleton. `mutex` makes the reads of every pack take turns on the one queue.
struct Runtime {
    std::string why;  // empty: loaded
    HMODULE core = nullptr, dll = nullptr;
    DsFactory* factory = nullptr;
    DsQueue1* queue = nullptr;
    DsStatusArray* status = nullptr;
    HANDLE event = nullptr;
    CreateCodecFn createCodec = nullptr;
    std::mutex mutex;
    UINT32 nextSlot = 0;
};
constexpr UINT32 kStatusSlots = 8;

void load(Runtime& rt) {
    if (env_wide(L"FA_DIRECTSTORAGE") == L"0") {
        rt.why = "FA_DIRECTSTORAGE=0 turns it off";
        return;
    }
    std::filesystem::path dir = env_wide(L"FA_DIRECTSTORAGE_DIR");
    if (dir.empty()) dir = executable_folder();
    const std::filesystem::path corePath = dir / L"dstoragecore.dll", dllPath = dir / L"dstorage.dll";
    std::error_code ec;
    if (!std::filesystem::is_regular_file(dllPath, ec) || !std::filesystem::is_regular_file(corePath, ec)) {
        rt.why = "dstorage.dll and dstoragecore.dll are not in " + fs::path_to_utf8(dir) +
                 " (a Windows export with export.pack.directStorage puts them next to the game; `factoria setup "
                 "directstorage` fetches them)";
        return;
    }
    // dstorage.dll loads dstoragecore.dll by name: loading that one first, by its full path, makes that name resolve to it
    // and not to a copy somewhere on the search path.
    rt.core = LoadLibraryExW(corePath.c_str(), nullptr, LOAD_WITH_ALTERED_SEARCH_PATH);
    rt.dll = rt.core ? LoadLibraryExW(dllPath.c_str(), nullptr, LOAD_WITH_ALTERED_SEARCH_PATH) : nullptr;
    if (!rt.core || !rt.dll) {
        rt.why = "Windows could not load " + fs::path_to_utf8(rt.core ? dllPath : corePath) + " (error " +
                 std::to_string(GetLastError()) + "; an x64 game needs the x64 DLLs)";
        return;
    }
    const auto getFactory =
        reinterpret_cast<GetFactoryFn>(reinterpret_cast<void*>(GetProcAddress(rt.dll, "DStorageGetFactory")));
    rt.createCodec = reinterpret_cast<CreateCodecFn>(
        reinterpret_cast<void*>(GetProcAddress(rt.dll, "DStorageCreateCompressionCodec")));
    if (!getFactory) {
        rt.why = fs::path_to_utf8(dllPath) + " has no DStorageGetFactory (not the DirectStorage runtime)";
        return;
    }
    HRESULT hr = getFactory(kIidFactory, reinterpret_cast<void**>(&rt.factory));
    if (FAILED(hr) || !rt.factory) {
        rt.why =
            "DStorageGetFactory failed with " + hresult_text(hr) + " (DirectStorage needs Windows 10 1909 or newer)";
        return;
    }
    DsQueueDesc desc;
    desc.capacity = std::uint16_t(kDirectQueueCapacity);
    desc.name = "FactorIA game.pak";
    DsQueue* queue = nullptr;
    hr = rt.factory->CreateQueue(&desc, kIidQueue, reinterpret_cast<void**>(&queue));
    if (FAILED(hr) || !queue) {
        rt.why = "IDStorageFactory::CreateQueue failed with " + hresult_text(hr);
        return;
    }
    hr = queue->QueryInterface(kIidQueue1, reinterpret_cast<void**>(&rt.queue));
    release(queue);
    if (FAILED(hr) || !rt.queue) {
        rt.why =
            "this DirectStorage runtime is older than 1.1 (no IDStorageQueue1); export the game again with the DLLs "
            "of `factoria setup directstorage`";
        return;
    }
    hr = rt.factory->CreateStatusArray(kStatusSlots, "FactorIA game.pak", kIidStatusArray,
                                       reinterpret_cast<void**>(&rt.status));
    if (FAILED(hr) || !rt.status) {
        rt.why = "IDStorageFactory::CreateStatusArray failed with " + hresult_text(hr);
        return;
    }
    rt.event = CreateEventW(nullptr, FALSE, FALSE, nullptr);
    if (!rt.event) rt.why = "CreateEventW failed (error " + std::to_string(GetLastError()) + ")";
}

Runtime& runtime() {
    static Runtime* rt = [] {
        auto* r = new Runtime();  // never freed: see Runtime
        load(*r);
        return r;
    }();
    return *rt;
}

}  // namespace

class DirectStorageFile {
public:
    explicit DirectStorageFile(DsFile* file) : file_(file) {}
    ~DirectStorageFile() {
        if (file_) {
            file_->Close();
            file_->Release();
        }
    }
    DirectStorageFile(const DirectStorageFile&) = delete;
    DirectStorageFile& operator=(const DirectStorageFile&) = delete;
    DsFile* get() const { return file_; }

private:
    DsFile* file_ = nullptr;
};

Result<void> direct_storage_available() {
    Runtime& rt = runtime();
    if (!rt.why.empty())
        return make_error("DirectStorage is not available: " + rt.why,
                          "Run `factoria setup directstorage` and set FA_DIRECTSTORAGE_DIR to the folder it prints, or "
                          "put the two DLLs next to the executable.");
    return {};
}

std::shared_ptr<DirectStorageFile> direct_storage_open(const std::filesystem::path& pack, std::string& why) {
    Runtime& rt = runtime();
    if (!rt.why.empty()) {
        why = rt.why;
        return nullptr;
    }
    DsFile* file = nullptr;
    const HRESULT hr = rt.factory->OpenFile(fs::os_path(pack).c_str(), kIidFile, reinterpret_cast<void**>(&file));
    if (FAILED(hr) || !file) {
        why = "IDStorageFactory::OpenFile failed with " + hresult_text(hr);
        return nullptr;
    }
    return std::make_shared<DirectStorageFile>(file);
}

Result<void> direct_storage_read(DirectStorageFile& file, std::span<const DirectIo> ios) {
    if (ios.empty()) return {};
    Runtime& rt = runtime();
    if (!rt.why.empty()) return make_error("DirectStorage is not available: " + rt.why);
    if (ios.size() > kDirectBatchRequests) return make_error("too many DirectStorage requests in one batch");
    std::lock_guard<std::mutex> lock(rt.mutex);
    for (const DirectIo& io : ios) {
        DsRequest req;
        req.compressionFormat = io.compressed ? kFormatGDeflate : kFormatNone;
        req.sourceFile = file.get();
        req.sourceOffset = io.fileOffset;
        req.sourceSize = io.storedSize;
        req.destinationBuffer = io.dest;
        req.destinationSize = io.decodedSize;
        req.uncompressedSize = io.decodedSize;
        rt.queue->EnqueueRequest(&req);
    }
    const UINT32 slot = rt.nextSlot;
    rt.nextSlot = (rt.nextSlot + 1) % kStatusSlots;
    rt.queue->EnqueueStatus(rt.status, slot);
    rt.queue->EnqueueSetEvent(rt.event);
    rt.queue->Submit();
    // Never return before DirectStorage is done: it writes into the caller's buffers. The event is set once every request
    // before it (and the status) completed, and batches take turns under the mutex, so each batch consumes exactly its own
    // signal of the auto-reset event (a status slot that is reused is never read before its new value is written). A read
    // that takes this long is a drive that stalls, not a cap: the wait goes on, with one warning.
    bool warned = false;
    for (;;) {
        const DWORD waited = WaitForSingleObject(rt.event, 30000);
        if (waited == WAIT_OBJECT_0) break;
        if (waited == WAIT_TIMEOUT) {
            if (!warned) FA_WARN("fs", "DirectStorage has not finished a read of game.pak for 30 s; still waiting");
            warned = true;
            continue;
        }
        // The wait itself failed (it never does with a valid event): poll the status instead.
        while (!rt.status->IsComplete(slot)) Sleep(1);
        break;
    }
    const HRESULT hr = rt.status->GetHResult(slot);
    if (FAILED(hr)) return make_error("a DirectStorage read failed with " + hresult_text(hr));
    return {};
}

namespace {

Result<DsCodec*> make_codec() {
    if (auto ok = direct_storage_available(); !ok.ok()) return ok.error();
    Runtime& rt = runtime();
    if (!rt.createCodec) return make_error("dstorage.dll has no DStorageCreateCompressionCodec");
    DsCodec* codec = nullptr;
    const HRESULT hr = rt.createCodec(kFormatGDeflate, 1, kIidCodec, reinterpret_cast<void**>(&codec));
    if (FAILED(hr) || !codec) return make_error("DStorageCreateCompressionCodec failed with " + hresult_text(hr));
    return codec;
}

}  // namespace

Result<std::vector<std::uint8_t>> direct_storage_decompress(std::span<const std::uint8_t> stream, std::size_t size) {
    auto codec = make_codec();
    if (!codec.ok()) return codec.error();
    std::vector<std::uint8_t> out(size);
    size_t written = 0;
    const HRESULT hr = codec.value()->DecompressBuffer(stream.data(), stream.size(), out.data(), out.size(), &written);
    codec.value()->Release();
    if (FAILED(hr)) return make_error("IDStorageCompressionCodec::DecompressBuffer failed with " + hresult_text(hr));
    out.resize(written);
    return out;
}

Result<std::vector<std::uint8_t>> direct_storage_compress(std::span<const std::uint8_t> data) {
    auto codec = make_codec();
    if (!codec.ok()) return codec.error();
    std::vector<std::uint8_t> out(codec.value()->CompressBufferBound(data.size()));
    size_t written = 0;
    const HRESULT hr =
        codec.value()->CompressBuffer(data.data(), data.size(), kCompressionDefault, out.data(), out.size(), &written);
    codec.value()->Release();
    if (FAILED(hr)) return make_error("IDStorageCompressionCodec::CompressBuffer failed with " + hresult_text(hr));
    out.resize(written);
    return out;
}

}  // namespace fa::detail

#endif  // _WIN64
