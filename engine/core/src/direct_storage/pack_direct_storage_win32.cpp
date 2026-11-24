// The DirectStorage runtime of the pack reader on Windows x64 (pack_direct_storage.h): dstorage.dll loaded at run time,
// through the engine's own declarations of its API (dstorage_api_win32.h). dstorage.dll and dstoragecore.dll are
// redistributable files that a Windows export with export.pack.directStorage puts next to the game (`factoria setup
// directstorage` fetches them).
//
// Three stages, each loaded once and only when asked for: the DLLs (all the codec of the tests needs), the factory (the
// D3D12 backend makes its own queue with it, d3d12_pack_reads_win32.cpp) and the memory queue of the pack reader.
#if defined(_WIN64)

#include "dstorage_api_win32.h"

#include <chrono>
#include <condition_variable>
#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <iterator>
#include <mutex>
#include <string>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "pack_direct_storage.h"

namespace fa::detail {

namespace dstorage {

std::string hresult_text(HRESULT hr) {
    char buf[16];
    std::snprintf(buf, sizeof buf, "0x%08lX", static_cast<unsigned long>(hr));
    const char* what = "";
    switch (static_cast<unsigned long>(hr)) {
        case 0x89240007ul: what = " (E_DSTORAGE_END_OF_FILE: the request reads past the end of the file)"; break;
        case 0x89240008ul: what = " (E_DSTORAGE_REQUEST_TOO_LARGE)"; break;
        case 0x8924000Ful: what = " (E_DSTORAGE_INVALID_DESTINATION_SIZE)"; break;
        case 0x89240010ul: what = " (E_DSTORAGE_FILE_NOT_OPEN)"; break;
        case 0x89240011ul: what = " (E_DSTORAGE_CANCELLED: the read was cancelled)"; break;
        case 0x8924001Dul: what = " (E_DSTORAGE_SYSTEM_NOT_SUPPORTED: this Windows has no DirectStorage)"; break;
        case 0x89240030ul: what = " (E_DSTORAGE_DECOMPRESSION_ERROR: a block is not a valid GDeflate stream)"; break;
        case 0x89240039ul: what = " (E_DSTORAGE_COMPRESSED_DATA_TOO_LARGE)"; break;
        default: break;
    }
    return std::string(buf) + what;
}

}  // namespace dstorage

namespace {

namespace ds = dstorage;
using ds::hresult_text;

using GetFactoryFn = HRESULT(WINAPI*)(REFIID riid, void** ppv);
using CreateCodecFn = HRESULT(WINAPI*)(std::uint8_t format, UINT32 numThreads, REFIID riid, void** ppv);

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

// ---- stage 1: the DLLs ----------------------------------------------------------------------------------------------

struct Dlls {
    std::string why;  // empty: loaded
    HMODULE core = nullptr, dll = nullptr;
    GetFactoryFn getFactory = nullptr;
    CreateCodecFn createCodec = nullptr;
};

void load_dlls(Dlls& d) {
    if (env_wide(L"FA_DIRECTSTORAGE") == L"0") {
        d.why = "FA_DIRECTSTORAGE=0 turns it off";
        return;
    }
    std::filesystem::path dir = env_wide(L"FA_DIRECTSTORAGE_DIR");
    if (dir.empty()) dir = executable_folder();
    std::error_code ec;
    // LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR needs a full path: a relative FA_DIRECTSTORAGE_DIR is taken from the current folder.
    if (dir.is_relative()) {
        std::filesystem::path abs = std::filesystem::absolute(dir, ec);
        if (!ec) dir = abs;
    }
    const std::filesystem::path corePath = dir / L"dstoragecore.dll", dllPath = dir / L"dstorage.dll";
    if (!std::filesystem::is_regular_file(dllPath, ec) || !std::filesystem::is_regular_file(corePath, ec)) {
        d.why = "dstorage.dll and dstoragecore.dll are not in " + fs::path_to_utf8(dir) +
                " (a Windows export with export.pack.directStorage puts them next to the game; `factoria setup "
                "directstorage` fetches them)";
        return;
    }
    // dstorage.dll loads dstoragecore.dll by name: loading that one first, by its full path, makes that name resolve to it
    // and not to a copy somewhere on the search path. Each DLL's own folder, then the system's, satisfy its imports.
    constexpr DWORD kFlags = LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR | LOAD_LIBRARY_SEARCH_DEFAULT_DIRS;
    d.core = LoadLibraryExW(corePath.c_str(), nullptr, kFlags);
    DWORD err = d.core ? 0 : GetLastError();
    if (d.core) {
        d.dll = LoadLibraryExW(dllPath.c_str(), nullptr, kFlags);
        if (!d.dll) err = GetLastError();
    }
    if (!d.core || !d.dll) {
        d.why = "Windows could not load " + fs::path_to_utf8(d.core ? dllPath : corePath) + " (error " +
                std::to_string(err) + "; an x64 game needs the x64 DLLs)";
        return;
    }
    d.getFactory = reinterpret_cast<GetFactoryFn>(reinterpret_cast<void*>(GetProcAddress(d.dll, "DStorageGetFactory")));
    d.createCodec = reinterpret_cast<CreateCodecFn>(
        reinterpret_cast<void*>(GetProcAddress(d.dll, "DStorageCreateCompressionCodec")));
    if (!d.getFactory) d.why = fs::path_to_utf8(dllPath) + " has no DStorageGetFactory (not the DirectStorage runtime)";
}

// The process's DLLs, factory and memory queue: loaded on first use and never unloaded (DirectStorage's worker threads
// live as long as the process), so they are leaked singletons.
Dlls& dlls() {
    static Dlls* d = [] {
        auto* r = new Dlls();  // never freed: see above
        load_dlls(*r);
        return r;
    }();
    return *d;
}

// ---- stage 2: the factory -------------------------------------------------------------------------------------------

struct FactoryStage {
    std::string why;
    ds::Ref<ds::Factory> factory;
};

FactoryStage& factory_stage() {
    static FactoryStage* f = [] {
        auto* r = new FactoryStage();  // never freed: see dlls()
        Dlls& d = dlls();
        if (!d.why.empty()) {
            r->why = d.why;
            return r;
        }
        const HRESULT hr = d.getFactory(ds::kIidFactory, r->factory.put());
        if (FAILED(hr) || !r->factory) {
            r->factory.reset();
            r->why = "DStorageGetFactory failed with " + hresult_text(hr) +
                     " (DirectStorage needs Windows 10 1909 or newer)";
        }
        return r;
    }();
    return *f;
}

// ---- stage 3: the memory queue of the pack reader -------------------------------------------------------------------

// Reads of several threads share the queue. Each read takes a status entry and its event (`slots`) and room in the queue,
// enqueues and submits under `mutex`, then waits for its own event without the lock.
constexpr UINT32 kStatusSlots = 32;

struct Slot {
    HANDLE event = nullptr;  // auto-reset; set by DirectStorage once the read's requests and status are done
    bool busy = false;       // a read waits for its event (and consumes it before the slot is free again)
};

struct MemoryQueue {
    std::string why;
    ds::Ref<ds::Queue1> queue;
    ds::Ref<ds::StatusArray> status;
    std::mutex mutex;
    std::condition_variable freed;  // a slot or queue room came back
    DirectQueueRoom room{kDirectQueueCapacity};
    Slot slots[kStatusSlots];
    std::uint64_t nextTag = 0;
};

void load_queue(MemoryQueue& q) {
    FactoryStage& f = factory_stage();
    if (!f.why.empty()) {
        q.why = f.why;
        return;
    }
    ds::QueueDesc desc;
    desc.capacity = std::uint16_t(kDirectQueueCapacity);
    desc.name = "FactorIA game.pak";
    ds::Ref<ds::Queue> queue;
    HRESULT hr = f.factory->CreateQueue(&desc, ds::kIidQueue, queue.put());
    if (FAILED(hr) || !queue) {
        q.why = "IDStorageFactory::CreateQueue failed with " + hresult_text(hr);
        return;
    }
    hr = queue->QueryInterface(ds::kIidQueue1, q.queue.put());
    if (FAILED(hr) || !q.queue) {
        q.queue.reset();
        q.why =
            "this DirectStorage runtime is older than 1.1 (no IDStorageQueue1); export the game again with the DLLs "
            "of `factoria setup directstorage`";
        return;
    }
    hr = f.factory->CreateStatusArray(kStatusSlots, "FactorIA game.pak", ds::kIidStatusArray, q.status.put());
    if (FAILED(hr) || !q.status) {
        q.status.reset();
        q.why = "IDStorageFactory::CreateStatusArray failed with " + hresult_text(hr);
        return;
    }
    for (Slot& s : q.slots) {
        s.event = CreateEventW(nullptr, FALSE, FALSE, nullptr);
        if (!s.event) {
            q.why = "CreateEventW failed (error " + std::to_string(GetLastError()) + ")";
            return;
        }
    }
}

MemoryQueue& memory_queue() {
    static MemoryQueue* q = [] {
        auto* r = new MemoryQueue();  // never freed: see dlls()
        load_queue(*r);
        return r;
    }();
    return *q;
}

std::uint64_t now_ms() {
    return std::uint64_t(
        std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now().time_since_epoch())
            .count());
}

}  // namespace

class DirectStorageFile {
public:
    explicit DirectStorageFile(ds::File* file) : file_(file) {}
    ~DirectStorageFile() {
        if (file_) {
            file_->Close();
            file_->Release();
        }
    }
    DirectStorageFile(const DirectStorageFile&) = delete;
    DirectStorageFile& operator=(const DirectStorageFile&) = delete;
    ds::File* get() const { return file_; }

private:
    ds::File* file_ = nullptr;
};

Result<void> direct_storage_available() {
    MemoryQueue& q = memory_queue();
    if (!q.why.empty())
        return make_error("DirectStorage is not available: " + q.why,
                          "Run `factoria setup directstorage` and set FA_DIRECTSTORAGE_DIR to the folder it prints, or "
                          "put the two DLLs next to the executable.");
    return {};
}

ds::Factory* direct_storage_factory(std::string& why) {
    FactoryStage& f = factory_stage();
    if (!f.why.empty()) {
        why = f.why;
        return nullptr;
    }
    return f.factory.get();
}

bool direct_storage_verify() {
    static const bool on = env_wide(L"FA_DIRECTSTORAGE_VERIFY") == L"1";
    return on;
}

std::shared_ptr<DirectStorageFile> direct_storage_open(const std::filesystem::path& pack, std::string& why) {
    MemoryQueue& q = memory_queue();
    if (!q.why.empty()) {
        why = q.why;
        return nullptr;
    }
    // OpenFile takes no share mode: DirectStorage opens its own read handle, kept until the last DirectStorageFile goes. A
    // running game's game.pak is therefore locked against replacement as a mapped one is (ARCHITECTURE_FILES.md,
    // "DirectStorage", share mode).
    ds::Ref<ds::File> file;
    const HRESULT hr = factory_stage().factory->OpenFile(fs::os_path(pack).c_str(), ds::kIidFile, file.put());
    if (FAILED(hr) || !file) {
        why = "IDStorageFactory::OpenFile failed with " + hresult_text(hr);
        return nullptr;
    }
    return std::make_shared<DirectStorageFile>(file.detach());
}

Result<void> direct_storage_read(DirectStorageFile& file, std::span<const DirectIo> ios) {
    if (ios.empty()) return {};
    MemoryQueue& q = memory_queue();
    if (!q.why.empty()) return make_error("DirectStorage is not available: " + q.why);
    if (ios.size() > kDirectBatchRequests) return make_error("too many DirectStorage requests in one batch");

    // Enqueue and submit under the lock, once a status slot and room in the queue are free (they come back when other
    // reads end, and every read ends within its own bounded wait below).
    UINT32 slot = 0;
    std::uint64_t tag = 0;
    {
        std::unique_lock<std::mutex> lock(q.mutex);
        auto freeSlot = [&]() -> int {
            for (UINT32 i = 0; i < kStatusSlots; ++i)
                if (!q.slots[i].busy) return int(i);
            return -1;
        };
        for (;;) {
            const int s = freeSlot();
            if (s >= 0 && q.room.take(ios.size())) {
                slot = UINT32(s);
                break;
            }
            q.freed.wait(lock);
        }
        q.slots[slot].busy = true;
        tag = ++q.nextTag;
        for (const DirectIo& io : ios) {
            ds::Request req;
            req.compressionFormat = io.compressed ? ds::kFormatGDeflate : ds::kFormatNone;
            req.sourceFile = file.get();
            req.sourceOffset = io.fileOffset;
            req.sourceSize = io.storedSize;
            ds::set_destination(req, ds::kDestinationMemory, ds::MemoryDestination{io.dest, io.decodedSize});
            req.uncompressedSize = io.decodedSize;
            req.cancellationTag = tag;
            q.queue->EnqueueRequest(&req);
        }
        q.queue->EnqueueStatus(q.status.get(), slot);
        q.queue->EnqueueSetEvent(q.slots[slot].event);
        q.queue->Submit();
    }

    // Wait without the lock. Never return before DirectStorage is done: it writes into the caller's buffers. This read's
    // event decides: DirectStorage sets it after every request before it in the queue (the read's own) and its status
    // entry are done, and only this read waits for it, since the auto-reset event is consumed here before the slot is
    // used again. The status entry is not the exit condition: until DirectStorage reaches this read's EnqueueStatus, the
    // entry may still say "complete" from the slot's previous read.
    const std::uint64_t start = now_ms();
    bool warned = false, cancelled = false;
    std::uint64_t cancelAt = 0;
    for (;;) {
        const DWORD waited = WaitForSingleObject(q.slots[slot].event, 1000);
        if (waited == WAIT_OBJECT_0) break;
        if (waited == WAIT_FAILED) Sleep(1000);  // never with a valid event; the bounds below still hold
        const std::uint64_t waitedMs = now_ms() - start;
        if (!warned && waitedMs >= kDirectWarnMs) {
            FA_WARN("fs", "DirectStorage has not finished a read of game.pak for {} s; still waiting",
                    kDirectWarnMs / 1000);
            warned = true;
        }
        if (!cancelled && waitedMs >= kDirectGiveUpMs) {
            FA_ERROR("fs", "DirectStorage has not finished a read of game.pak for {} s; cancelling it",
                     kDirectGiveUpMs / 1000);
            std::lock_guard<std::mutex> lock(q.mutex);
            q.queue->CancelRequestsWithTag(~std::uint64_t(0), tag);
            cancelled = true;
            cancelAt = now_ms();
        }
        if (cancelled && now_ms() - cancelAt >= kDirectGiveUpMs) {
            // Neither finished nor cancelled: the runtime may still write into the caller's buffers, which a return
            // would free. Stop the process rather than let it write into freed memory.
            FA_ERROR("fs", "DirectStorage did not confirm the cancellation of a read for {} s; stopping the process",
                     kDirectGiveUpMs / 1000);
            std::abort();
        }
    }
    // The event came, so the status entry is this read's (it was enqueued before the event).
    const bool complete = q.status->IsComplete(slot);
    const HRESULT hr = complete ? q.status->GetHResult(slot) : E_FAIL;
    {
        std::lock_guard<std::mutex> lock(q.mutex);
        q.slots[slot].busy = false;
        q.room.give(ios.size());
    }
    q.freed.notify_all();
    if (!complete) return make_error("DirectStorage set a read's event before its status entry was complete");
    if (FAILED(hr)) return make_error("a DirectStorage read failed with " + hresult_text(hr));
    return {};
}

namespace {

// DirectStorage's CPU codec: needs the DLL only (not the factory nor a queue).
Result<ds::Ref<ds::Codec>> make_codec() {
    Dlls& d = dlls();
    if (!d.why.empty())
        return make_error("DirectStorage is not available: " + d.why,
                          "Run `factoria setup directstorage` and set FA_DIRECTSTORAGE_DIR to the folder it prints, or "
                          "put the two DLLs next to the executable.");
    if (!d.createCodec) return make_error("dstorage.dll has no DStorageCreateCompressionCodec");
    ds::Ref<ds::Codec> codec;
    const HRESULT hr = d.createCodec(ds::kFormatGDeflate, 1, ds::kIidCodec, codec.put());
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
    if (FAILED(hr)) return make_error("IDStorageCompressionCodec::DecompressBuffer failed with " + hresult_text(hr));
    out.resize(written);
    return out;
}

Result<std::vector<std::uint8_t>> direct_storage_compress(std::span<const std::uint8_t> data) {
    auto codec = make_codec();
    if (!codec.ok()) return codec.error();
    std::vector<std::uint8_t> out(codec.value()->CompressBufferBound(data.size()));
    size_t written = 0;
    const HRESULT hr = codec.value()->CompressBuffer(data.data(), data.size(), ds::kCompressionDefault, out.data(),
                                                     out.size(), &written);
    if (FAILED(hr)) return make_error("IDStorageCompressionCodec::CompressBuffer failed with " + hresult_text(hr));
    out.resize(written);
    return out;
}

}  // namespace fa::detail

#endif  // _WIN64
