// The DirectStorage API as the engine declares it (M77, docs/design/ARCHITECTURE_FILES.md, "DirectStorage"). Private:
// fa_core's pack reader uses it (pack_direct_storage_win32.cpp), and so does fa_render's D3D12 backend for its GPU
// destinations (engine/render/src/gpu/d3d12_pack_reads_win32.cpp), which adds this folder, and only this one, to its
// private include path. Windows x64 only; elsewhere this header declares nothing.
//
// The declarations are the engine's own, written from Microsoft's public DirectStorage documentation (the interfaces,
// structures, enumerations and IIDs of dstorage.h, version 1.1 and later): only what the engine calls. No SDK header is
// used and nothing is linked: dstorage.dll and dstoragecore.dll are loaded at run time. Every layout is checked with
// static_asserts against the sizes and offsets the documentation gives for x64.
#pragma once

#if defined(_WIN32) && defined(_WIN64)

#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
// windows.h first: unknwn.h needs its types
#include <unknwn.h>

#include <cstddef>
#include <cstdint>
#include <cstring>
#include <string>

namespace fa::detail::dstorage {

inline constexpr GUID kIidFactory = {0x6924ea0c, 0xc3cd, 0x4826, {0xb1, 0x0a, 0xf6, 0x4f, 0x4e, 0xd9, 0x27, 0xc1}};
inline constexpr GUID kIidFile = {0x5de95e7b, 0x955a, 0x4868, {0xa7, 0x3c, 0x24, 0x3b, 0x29, 0xf4, 0xb8, 0xda}};
inline constexpr GUID kIidStatusArray = {0x82397587, 0x7cd5, 0x453b, {0xa0, 0x2e, 0x31, 0x37, 0x9b, 0xd6, 0x46, 0x56}};
inline constexpr GUID kIidQueue = {0xcfdbd83f, 0x9e06, 0x4fda, {0x8e, 0xa5, 0x69, 0x04, 0x21, 0x37, 0xf4, 0x9b}};
inline constexpr GUID kIidQueue1 = {0xdd2f482c, 0x5eff, 0x41e8, {0x9c, 0x9e, 0xd2, 0x37, 0x4b, 0x27, 0x81, 0x28}};
inline constexpr GUID kIidCodec = {0x84ef5121, 0x9b43, 0x4d03, {0xb5, 0xc1, 0xcc, 0x34, 0x60, 0x6b, 0x26, 0x2d}};

inline constexpr std::uint64_t kSourceFile = 0;                // DSTORAGE_REQUEST_SOURCE_FILE
inline constexpr std::uint64_t kDestinationMemory = 0;         // DSTORAGE_REQUEST_DESTINATION_MEMORY
inline constexpr std::uint64_t kDestinationBuffer = 1;         // DSTORAGE_REQUEST_DESTINATION_BUFFER
inline constexpr std::uint64_t kDestinationTextureRegion = 2;  // DSTORAGE_REQUEST_DESTINATION_TEXTURE_REGION
inline constexpr std::uint8_t kFormatNone = 0;                 // DSTORAGE_COMPRESSION_FORMAT_NONE
inline constexpr std::uint8_t kFormatGDeflate = 1;             // DSTORAGE_COMPRESSION_FORMAT_GDEFLATE
inline constexpr std::int8_t kPriorityNormal = 0;              // DSTORAGE_PRIORITY_NORMAL
inline constexpr std::int32_t kCompressionDefault = 0;         // DSTORAGE_COMPRESSION_DEFAULT
inline constexpr std::uint16_t kMinQueueCapacity = 0x80;       // DSTORAGE_MIN_QUEUE_CAPACITY
inline constexpr std::uint16_t kMaxQueueCapacity = 0x2000;     // DSTORAGE_MAX_QUEUE_CAPACITY

// DSTORAGE_QUEUE_DESC.
struct QueueDesc {
    std::uint64_t sourceType = kSourceFile;
    std::uint16_t capacity = 0;
    std::int8_t priority = kPriorityNormal;
    const char* name = nullptr;
    // ID3D12Device*: null for a queue whose destinations are all memory; set for buffers and textures of that device.
    void* device = nullptr;
};
static_assert(sizeof(QueueDesc) == 32 && offsetof(QueueDesc, capacity) == 8 && offsetof(QueueDesc, priority) == 10 &&
              offsetof(QueueDesc, name) == 16 && offsetof(QueueDesc, device) == 24);

// The members of the DSTORAGE_DESTINATION union the engine uses. set_destination copies one into a request.
struct MemoryDestination {  // DSTORAGE_DESTINATION_MEMORY
    void* buffer = nullptr;
    std::uint32_t size = 0;
};
static_assert(sizeof(MemoryDestination) == 16 && offsetof(MemoryDestination, size) == 8);
struct BufferDestination {     // DSTORAGE_DESTINATION_BUFFER
    void* resource = nullptr;  // ID3D12Resource*
    std::uint64_t offset = 0;
    std::uint32_t size = 0;
};
static_assert(sizeof(BufferDestination) == 24 && offsetof(BufferDestination, offset) == 8 &&
              offsetof(BufferDestination, size) == 16);
struct Box {  // D3D12_BOX
    std::uint32_t left = 0, top = 0, front = 0, right = 0, bottom = 0, back = 0;
};
struct TextureRegionDestination {  // DSTORAGE_DESTINATION_TEXTURE_REGION
    void* resource = nullptr;      // ID3D12Resource*
    std::uint32_t subresource = 0;
    Box region;
};
static_assert(sizeof(Box) == 24 && sizeof(TextureRegionDestination) == 40 &&
              offsetof(TextureRegionDestination, subresource) == 8 && offsetof(TextureRegionDestination, region) == 12);

// DSTORAGE_REQUEST with DSTORAGE_REQUEST_OPTIONS spelled out (a byte of format, 7 reserved bytes, then a 64-bit word whose
// bit 0 is the source type and bits 1-7 the destination type), the file member of the DSTORAGE_SOURCE union (24 bytes)
// and the DSTORAGE_DESTINATION union as its 40 bytes (its largest members, the texture region and the tiles, set its
// size), written by set_destination.
struct Request {
    std::uint8_t compressionFormat = kFormatNone;
    std::uint8_t reserved1[7] = {};
    std::uint64_t sourceAndDestination = kSourceFile | (kDestinationMemory << 1);
    void* sourceFile = nullptr;  // IDStorageFile*
    std::uint64_t sourceOffset = 0;
    std::uint32_t sourceSize = 0;
    std::uint32_t sourcePadding = 0;
    alignas(8) std::uint8_t destination[40] = {};
    std::uint32_t uncompressedSize = 0;
    std::uint64_t cancellationTag = 0;
    const char* name = nullptr;
};
static_assert(sizeof(Request) == 104 && offsetof(Request, sourceAndDestination) == 8 &&
              offsetof(Request, sourceFile) == 16 && offsetof(Request, sourceOffset) == 24 &&
              offsetof(Request, sourceSize) == 32 && offsetof(Request, destination) == 40 &&
              offsetof(Request, uncompressedSize) == 80 && offsetof(Request, cancellationTag) == 88 &&
              offsetof(Request, name) == 96);

// Makes `d` the request's destination (`type`: kDestinationMemory, kDestinationBuffer or kDestinationTextureRegion).
template <class D>
void set_destination(Request& r, std::uint64_t type, const D& d) {
    static_assert(sizeof(D) <= sizeof(Request::destination));
    std::memset(r.destination, 0, sizeof r.destination);
    std::memcpy(r.destination, &d, sizeof d);
    r.sourceAndDestination = kSourceFile | (type << 1);
}

// The interfaces, their methods in vtable order. Methods the engine never calls keep their slot with a plain signature.
struct File : IUnknown {  // IDStorageFile
    virtual void STDMETHODCALLTYPE Close() = 0;
    virtual HRESULT STDMETHODCALLTYPE GetFileInformation(BY_HANDLE_FILE_INFORMATION* info) = 0;
};
struct StatusArray : IUnknown {  // IDStorageStatusArray
    virtual bool STDMETHODCALLTYPE IsComplete(UINT32 index) = 0;
    virtual HRESULT STDMETHODCALLTYPE GetHResult(UINT32 index) = 0;
};
struct Queue : IUnknown {  // IDStorageQueue
    virtual void STDMETHODCALLTYPE EnqueueRequest(const Request* request) = 0;
    virtual void STDMETHODCALLTYPE EnqueueStatus(StatusArray* statusArray, UINT32 index) = 0;
    virtual void STDMETHODCALLTYPE EnqueueSignal(void* fence, UINT64 value) = 0;  // ID3D12Fence*
    virtual void STDMETHODCALLTYPE Submit() = 0;
    virtual void STDMETHODCALLTYPE CancelRequestsWithTag(UINT64 mask, UINT64 value) = 0;
    virtual void STDMETHODCALLTYPE Close() = 0;
    virtual HANDLE STDMETHODCALLTYPE GetErrorEvent() = 0;
    virtual void STDMETHODCALLTYPE RetrieveErrorRecord(void* record) = 0;
    virtual void STDMETHODCALLTYPE Query(void* info) = 0;
};
struct Queue1 : Queue {  // IDStorageQueue1 (DirectStorage 1.1)
    virtual void STDMETHODCALLTYPE EnqueueSetEvent(HANDLE handle) = 0;
};
struct Factory : IUnknown {  // IDStorageFactory
    virtual HRESULT STDMETHODCALLTYPE CreateQueue(const QueueDesc* desc, REFIID riid, void** ppv) = 0;
    virtual HRESULT STDMETHODCALLTYPE OpenFile(const WCHAR* path, REFIID riid, void** ppv) = 0;
    virtual HRESULT STDMETHODCALLTYPE CreateStatusArray(UINT32 capacity, PCSTR name, REFIID riid, void** ppv) = 0;
    virtual void STDMETHODCALLTYPE SetDebugFlags(UINT32 flags) = 0;
    virtual HRESULT STDMETHODCALLTYPE SetStagingBufferSize(UINT32 size) = 0;
};
struct Codec : IUnknown {  // IDStorageCompressionCodec
    virtual HRESULT STDMETHODCALLTYPE CompressBuffer(const void* uncompressedData, size_t uncompressedDataSize,
                                                     std::int32_t compressionSetting, void* compressedBuffer,
                                                     size_t compressedBufferSize, size_t* compressedDataSize) = 0;
    virtual HRESULT STDMETHODCALLTYPE DecompressBuffer(const void* compressedData, size_t compressedDataSize,
                                                       void* uncompressedBuffer, size_t uncompressedBufferSize,
                                                       size_t* uncompressedDataSize) = 0;
    virtual size_t STDMETHODCALLTYPE CompressBufferBound(size_t uncompressedDataSize) = 0;
};

// An owning reference to one of the interfaces above: released when it goes, so no error path leaks one.
template <class T>
class Ref {
public:
    Ref() = default;
    Ref(const Ref&) = delete;
    Ref& operator=(const Ref&) = delete;
    Ref(Ref&& o) noexcept : p_(o.p_) { o.p_ = nullptr; }
    Ref& operator=(Ref&& o) noexcept {
        if (this != &o) {
            reset();
            p_ = o.p_;
            o.p_ = nullptr;
        }
        return *this;
    }
    ~Ref() { reset(); }
    void reset() {
        if (p_) p_->Release();
        p_ = nullptr;
    }
    T* get() const { return p_; }
    T* operator->() const { return p_; }
    explicit operator bool() const { return p_ != nullptr; }
    // For a creation call's `void** ppv`: releases what it held first.
    void** put() {
        reset();
        return reinterpret_cast<void**>(&p_);
    }
    // Gives the reference up without releasing it.
    T* detach() {
        T* p = p_;
        p_ = nullptr;
        return p;
    }

private:
    T* p_ = nullptr;
};

// "0x89240030 (E_DSTORAGE_DECOMPRESSION_ERROR: ...)": the HRESULT and, for DirectStorage's own codes, what it means.
std::string hresult_text(HRESULT hr);

}  // namespace fa::detail::dstorage

#endif  // _WIN32 && _WIN64
