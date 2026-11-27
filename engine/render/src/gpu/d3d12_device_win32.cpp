// The D3D12 device: the factory, the adapter, the debug layer, the queue, the fence and the frames in flight, the
// deferred releases, the capabilities, the statistics and the commit listeners
// (docs/design/ARCHITECTURE_RENDERING_GPU.md, "D3D12 backend").
#include <algorithm>
#include <array>
#include <cstdio>
#include <cstring>
#include <format>
#include <memory>
#include <span>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/log.h"
#include "gpu/d3d12_device.h"

namespace fa::gpu {

Result<std::unique_ptr<Device>> make_d3d12_device(const D3d12Options& options) {
    auto device = d3d12::D3d12Device::create(options);
    if (!device) return device.error();
    return std::unique_ptr<Device>(std::move(device.value()));
}

std::string d3d12_program_name() {
    // The path may be longer than MAX_PATH (a long-path aware process): the buffer grows until the name fits.
    std::wstring buffer(260, L'\0');
    for (int attempt = 0; attempt < 6; ++attempt) {
        const DWORD n = GetModuleFileNameW(nullptr, buffer.data(), DWORD(buffer.size()));
        if (n == 0) return {};
        if (n < buffer.size()) {
            buffer.resize(n);
            return fs::path_to_utf8(std::filesystem::path(buffer).stem());
        }
        buffer.resize(buffer.size() * 4);
    }
    return {};
}

}  // namespace fa::gpu

namespace fa::gpu::d3d12 {

namespace {

// The longest a CPU wait for the GPU may take before it is reported as a hang: a safety net far above any frame or
// readback (a loaded CI machine running WARP included), never a budget.
constexpr DWORD kFenceWaitMs = 120000;
// Command lists the device keeps for reuse; past this many a new one waits for the oldest to finish first.
constexpr std::size_t kMaxLists = 64;
// D3D12's limit on the samplers of a shader-visible heap, and the CBV/SRV/UAV limit of resource binding tier 2.
constexpr std::uint64_t kMaxShaderVisibleSamplers = 2048;
constexpr std::uint64_t kMaxShaderVisibleViews = 1000000;

Error hr_error(const std::string& call, HRESULT hr, const std::string& hint) {
    return make_error("gpu d3d12: " + call + " failed with " + hr_text(hr), hint);
}

void set_name(ID3D12Object* o, const char* label) {
    if (o && label && *label) o->SetName(widen(label).c_str());
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------------------------------------------------

std::string hr_text(HRESULT hr) {
    struct Name {
        HRESULT hr;
        const char* name;
    };
    static const Name kNames[] = {
        {S_OK, "S_OK"},
        {S_FALSE, "S_FALSE"},
        {E_FAIL, "E_FAIL"},
        {E_INVALIDARG, "E_INVALIDARG"},
        {E_OUTOFMEMORY, "E_OUTOFMEMORY"},
        {E_NOINTERFACE, "E_NOINTERFACE"},
        {E_NOTIMPL, "E_NOTIMPL"},
        {E_POINTER, "E_POINTER"},
        {E_ACCESSDENIED, "E_ACCESSDENIED"},
        {DXGI_ERROR_DEVICE_REMOVED, "DXGI_ERROR_DEVICE_REMOVED"},
        {DXGI_ERROR_DEVICE_HUNG, "DXGI_ERROR_DEVICE_HUNG"},
        {DXGI_ERROR_DEVICE_RESET, "DXGI_ERROR_DEVICE_RESET"},
        {DXGI_ERROR_DRIVER_INTERNAL_ERROR, "DXGI_ERROR_DRIVER_INTERNAL_ERROR"},
        {DXGI_ERROR_INVALID_CALL, "DXGI_ERROR_INVALID_CALL"},
        {DXGI_ERROR_NOT_FOUND, "DXGI_ERROR_NOT_FOUND"},
        {DXGI_ERROR_UNSUPPORTED, "DXGI_ERROR_UNSUPPORTED"},
        {DXGI_ERROR_WAS_STILL_DRAWING, "DXGI_ERROR_WAS_STILL_DRAWING"},
        {DXGI_ERROR_SDK_COMPONENT_MISSING, "DXGI_ERROR_SDK_COMPONENT_MISSING"},
        {D3D12_ERROR_ADAPTER_NOT_FOUND, "D3D12_ERROR_ADAPTER_NOT_FOUND"},
        {D3D12_ERROR_DRIVER_VERSION_MISMATCH, "D3D12_ERROR_DRIVER_VERSION_MISMATCH"},
    };
    const char* name = "unknown HRESULT";
    for (const Name& n : kNames)
        if (n.hr == hr) name = n.name;
    char buf[16];
    std::snprintf(buf, sizeof buf, "0x%08lX", static_cast<unsigned long>(static_cast<std::uint32_t>(hr)));
    return std::string(buf) + " (" + name + ")";
}

std::wstring widen(const char* utf8) {
    if (!utf8 || !*utf8) return {};
    const int n = MultiByteToWideChar(CP_UTF8, 0, utf8, -1, nullptr, 0);
    if (n <= 0) return {};
    std::wstring w(std::size_t(n), L'\0');
    MultiByteToWideChar(CP_UTF8, 0, utf8, -1, w.data(), n);
    w.resize(std::size_t(n - 1));  // without the terminator the count included
    return w;
}

std::string narrow(const wchar_t* utf16) {
    if (!utf16 || !*utf16) return {};
    const int n = WideCharToMultiByte(CP_UTF8, 0, utf16, -1, nullptr, 0, nullptr, nullptr);
    if (n <= 0) return {};
    std::string s(std::size_t(n), '\0');
    WideCharToMultiByte(CP_UTF8, 0, utf16, -1, s.data(), n, nullptr, nullptr);
    s.resize(std::size_t(n - 1));
    return s;
}

// ---------------------------------------------------------------------------------------------------------------------
// Creation
// ---------------------------------------------------------------------------------------------------------------------

Result<std::unique_ptr<D3d12Device>> D3d12Device::create(const D3d12Options& options) {
    // Contradictions in the options first, before any D3D12 work.
    if (options.framesInFlight < 1 || options.framesInFlight > 3)
        return make_error("gpu d3d12: D3d12Options::framesInFlight is " + std::to_string(options.framesInFlight) +
                              ", outside 1..3",
                          "use 2 (the engine's kInflightFrames) unless a test needs another count");
    if (options.gpuValidation && !options.debugLayer)
        return make_error("gpu d3d12: D3d12Options::gpuValidation is on but debugLayer is off",
                          "GPU-based validation is part of the debug layer: turn debugLayer on too");
    if (options.uploadRingBytes < 64u * 1024u || options.uploadRingBytes > (std::size_t(1) << 30))
        return make_error("gpu d3d12: D3d12Options::uploadRingBytes is " + std::to_string(options.uploadRingBytes) +
                              ", outside 64 KiB..1 GiB",
                          "the default (32 MiB) suits the renderer; a test of the ring's wrap uses 64 KiB");
    if (options.bindlessDescriptors < 0 || options.frameViewDescriptors < 1 || options.frameSamplerDescriptors < 1 ||
        options.cpuViewDescriptors < 0 || options.cpuRtvDescriptors < 0 || options.cpuDsvDescriptors < 0 ||
        options.cpuSamplerDescriptors < 0)
        return make_error(
            "gpu d3d12: a descriptor count of D3d12Options is negative (or a per-frame count is 0)",
            "leave the cpu*Descriptors at 0 for the defaults, and give every frame at least 1 descriptor");
    const std::uint64_t views = std::uint64_t(options.bindlessDescriptors) +
                                std::uint64_t(options.framesInFlight) * std::uint64_t(options.frameViewDescriptors);
    if (views > kMaxShaderVisibleViews)
        return make_error("gpu d3d12: the shader-visible view heap would hold " + std::to_string(views) +
                              " descriptors (bindlessDescriptors + framesInFlight * frameViewDescriptors), more than "
                              "the 1000000 of resource binding tier 2",
                          "lower D3d12Options::bindlessDescriptors or frameViewDescriptors");
    const std::uint64_t samplers =
        std::uint64_t(options.framesInFlight) * std::uint64_t(options.frameSamplerDescriptors);
    if (samplers > kMaxShaderVisibleSamplers)
        return make_error("gpu d3d12: the shader-visible sampler heap would hold " + std::to_string(samplers) +
                              " samplers (framesInFlight * frameSamplerDescriptors), more than D3D12's 2048",
                          "lower D3d12Options::frameSamplerDescriptors (512 with 2 or 3 frames in flight fits)");

    std::unique_ptr<D3d12Device> d(new D3d12Device());
    if (auto r = d->init(options); !r) return r.error();
    return d;
}

Result<void> D3d12Device::init_adapter(const D3d12Options& options) {
    {
        // Starts each hook available; one another live device holds is left out of this device (gpu/device_hooks.h).
        std::vector<std::string> refused;
        hooks_ = hookUse_.attach(options.init.hooks, Backend::D3d12, &refused);
        for (const std::string& w : refused) {
            FA_WARN("render", "{}", w);
            std::lock_guard<std::mutex> lock(msgMutex_);
            warnings_.push_back(w);
        }
    }
    UINT factoryFlags = 0;
    if (options.debugLayer) {
        Com<ID3D12Debug> debug;
        const HRESULT hr = D3D12GetDebugInterface(__uuidof(ID3D12Debug), debug.put_void());
        if (SUCCEEDED(hr) && debug) {
            debug->EnableDebugLayer();
            debugLayer_ = true;
            factoryFlags = DXGI_CREATE_FACTORY_DEBUG;
            if (options.gpuValidation) {
                if (Com<ID3D12Debug1> debug1 = debug.as<ID3D12Debug1>()) {
                    debug1->SetEnableGPUBasedValidation(TRUE);
                    gpuValidation_ = true;
                } else {
                    FA_WARN("render", "gpu d3d12: GPU-based validation is not available (no ID3D12Debug1): the "
                                      "device runs with the debug layer only");
                }
            }
        } else {
            FA_WARN("render",
                    "gpu d3d12: the debug layer is not available (D3D12GetDebugInterface: {}): the device runs "
                    "without it. Install the Windows optional feature 'Graphics Tools' to get it",
                    hr_text(hr));
        }
        // DRED, with the debug layer: a removal the debug layer has no message for (a fault on the GPU, a driver or
        // WARP that gives up mid-list) still says which command of which list the GPU was at. The settings belong to
        // the process and hold for the devices made after this one too; the runtime has them without the Graphics
        // Tools, so a debug device on a machine without the debug layer gets them as well.
        Com<ID3D12DeviceRemovedExtendedDataSettings> dred;
        if (SUCCEEDED(D3D12GetDebugInterface(__uuidof(ID3D12DeviceRemovedExtendedDataSettings), dred.put_void())) &&
            dred) {
            dred->SetAutoBreadcrumbsEnablement(D3D12_DRED_ENABLEMENT_FORCED_ON);
            dred->SetPageFaultEnablement(D3D12_DRED_ENABLEMENT_FORCED_ON);
            dred_ = true;
        }
    }
    HRESULT hr = CreateDXGIFactory2(factoryFlags, __uuidof(IDXGIFactory4), factory_.put_void());
    if (FAILED(hr) && factoryFlags != 0)  // the DXGI debug layer is missing: the D3D12 one still works
        hr = CreateDXGIFactory2(0, __uuidof(IDXGIFactory4), factory_.put_void());
    if (FAILED(hr) || !factory_)
        return hr_error("CreateDXGIFactory2", hr, "DXGI 1.4 (Windows 10 or later) is needed for Direct3D 12");

    HRESULT deviceHr = E_FAIL;
    if (options.warp) {
        hr = factory_->EnumWarpAdapter(__uuidof(IDXGIAdapter1), adapter_.put_void());
        if (FAILED(hr) || !adapter_)
            return hr_error("IDXGIFactory4::EnumWarpAdapter", hr,
                            "WARP (the software rasterizer) ships with Windows 10 and later; ask for a hardware "
                            "adapter (D3d12Options::warp = false) instead");
        if (!hooks_.empty()) hooks_before_device(adapter_.get(), true);
        deviceHr =
            D3D12CreateDevice(adapter_.get(), D3D_FEATURE_LEVEL_11_0, __uuidof(ID3D12Device), device_.put_void());
        if (FAILED(deviceHr) || !device_)
            return hr_error("D3D12CreateDevice (WARP)", deviceHr,
                            "this Windows has no Direct3D 12 WARP device; use the D3D11 backend");
        warp_ = true;
    } else {
        Com<IDXGIFactory6> factory6 = factory_.as<IDXGIFactory6>();
        std::string tried;
        for (UINT i = 0;; ++i) {
            Com<IDXGIAdapter1> candidate;
            if (factory6)
                hr = factory6->EnumAdapterByGpuPreference(i, DXGI_GPU_PREFERENCE_HIGH_PERFORMANCE,
                                                          __uuidof(IDXGIAdapter1), candidate.put_void());
            else
                hr = factory_->EnumAdapters1(i, candidate.put());
            if (hr == DXGI_ERROR_NOT_FOUND || FAILED(hr) || !candidate) break;
            DXGI_ADAPTER_DESC1 ad{};
            candidate->GetDesc1(&ad);
            if (ad.Flags & DXGI_ADAPTER_FLAG_SOFTWARE) continue;  // WARP only when asked for
            Com<ID3D12Device> dev;
            if (!hooks_.empty()) hooks_before_device(candidate.get(), false);
            deviceHr =
                D3D12CreateDevice(candidate.get(), D3D_FEATURE_LEVEL_11_0, __uuidof(ID3D12Device), dev.put_void());
            if (SUCCEEDED(deviceHr) && dev) {
                adapter_ = candidate;
                device_ = dev;
                break;
            }
            tried += (tried.empty() ? "" : ", ") + narrow(ad.Description) + " (" + hr_text(deviceHr) + ")";
        }
        if (!device_)
            return make_error(
                "gpu d3d12: no hardware adapter makes a Direct3D 12 device at feature level 11.0" +
                    (tried.empty() ? std::string(" (no hardware adapter was found)") : ": tried " + tried),
                "update the GPU driver, use the D3D11 backend, or WARP (D3d12Options::warp) for tests");
    }
    DXGI_ADAPTER_DESC1 ad{};
    adapter_->GetDesc1(&ad);
    adapterName_ = narrow(ad.Description);

    D3D12_FEATURE_DATA_D3D12_OPTIONS o{};
    hr = device_->CheckFeatureSupport(D3D12_FEATURE_D3D12_OPTIONS, &o, sizeof o);
    if (FAILED(hr))
        return hr_error("CheckFeatureSupport(D3D12_OPTIONS) on " + adapterName_, hr,
                        "update the GPU driver or use the D3D11 backend");
    // Tier 1 has no unbounded descriptor ranges: init() makes no bindless table there (bindless_descriptors() is 0).
    bindingTier_ = o.ResourceBindingTier >= D3D12_RESOURCE_BINDING_TIER_3   ? 3
                   : o.ResourceBindingTier >= D3D12_RESOURCE_BINDING_TIER_2 ? 2
                                                                            : 1;
    typedUavLoadAdditional_ = o.TypedUAVLoadAdditionalFormats != FALSE;
    // The highest feature level (tier 1's UAV limit depends on it: 8 at 11.0, 64 above).
    const D3D_FEATURE_LEVEL levels[] = {D3D_FEATURE_LEVEL_12_1, D3D_FEATURE_LEVEL_12_0, D3D_FEATURE_LEVEL_11_1,
                                        D3D_FEATURE_LEVEL_11_0};
    D3D12_FEATURE_DATA_FEATURE_LEVELS fl{};
    fl.NumFeatureLevels = UINT(sizeof levels / sizeof levels[0]);
    fl.pFeatureLevelsRequested = levels;
    if (SUCCEEDED(device_->CheckFeatureSupport(D3D12_FEATURE_FEATURE_LEVELS, &fl, sizeof fl)))
        featureLevel_ = fl.MaxSupportedFeatureLevel;
    // What a pipeline cache file must have been made on (the user-mode driver's version: 0 when DXGI does not say).
    identity_.vendor = ad.VendorId;
    identity_.device = ad.DeviceId;
    identity_.subsys = ad.SubSysId;
    identity_.revision = ad.Revision;
    identity_.luidLow = ad.AdapterLuid.LowPart;
    identity_.luidHigh = ad.AdapterLuid.HighPart;
    LARGE_INTEGER umd{};
    if (SUCCEEDED(adapter_->CheckInterfaceSupport(__uuidof(IDXGIDevice), &umd)))
        identity_.driverVersion = std::uint64_t(umd.QuadPart);
    return {};
}

// ---- device hooks (gpu/device_hooks.h) ----

void D3d12Device::hook_unavailable(DeviceHook& hook, std::string reason) {
    if (!hook.available()) return;
    hook.mark_unavailable(std::move(reason));
    const std::string w = device_hook_warning(Backend::D3d12, hook);
    FA_WARN("render", "{}", w);
    std::lock_guard<std::mutex> lock(msgMutex_);
    warnings_.push_back(w);
}

void D3d12Device::hooks_before_device(IDXGIAdapter1* adapter, bool warp) {
    D3d12BeforeDevice b;
    b.factory = factory_.get();
    b.adapter = adapter;
    b.warp = warp;
    for (const auto& h : hooks_)
        if (h->available()) h->d3d12_before_device(b);
}

namespace {

// Takes over the reference a hook handed in `replaced` when it is not what `held` holds already.
template <class T>
void adopt(Com<T>& held, void* replaced) {
    if (!replaced || replaced == held.get()) return;
    Com<T> next;
    *next.put() = static_cast<T*>(replaced);
    held = std::move(next);
}

}  // namespace

void D3d12Device::hooks_device_created() {
    hookCreated_.assign(hooks_.size(), 0);
    for (std::size_t i = 0; i < hooks_.size(); ++i) {
        const auto& h = hooks_[i];
        if (!h->available()) continue;
        D3d12DeviceCreated c;
        c.factory = factory_.get();
        c.device = device_.get();
        c.queue = queue_.get();
        c.adapter = adapter_.get();
        hookCreated_[i] = 1;
        h->d3d12_device_created(c);
        if (!c.error.empty()) {
            // Changes nothing; a replacement it handed anyway is released.
            Com<IDXGIFactory4> f;
            Com<ID3D12Device> d;
            Com<ID3D12CommandQueue> q;
            adopt(f, c.factory != factory_.get() ? c.factory : nullptr);
            adopt(d, c.device != device_.get() ? c.device : nullptr);
            adopt(q, c.queue != queue_.get() ? c.queue : nullptr);
            hook_unavailable(*h, "on " + adapterName_ + ": " + c.error);
            continue;
        }
        adopt(factory_, c.factory);
        adopt(device_, c.device);
        adopt(queue_, c.queue);
    }
}

Result<void> D3d12Device::init(const D3d12Options& options) {
    framesInFlight_ = options.framesInFlight;
    if (auto r = init_adapter(options); !r) return r;

    if (debugLayer_) {
        infoQueue_ = device_.as<ID3D12InfoQueue>();
        if (infoQueue_) {
            // Not errors: a clear colour other than the one given at creation (the engine gives none), the
            // Map/Unmap of a whole buffer, and the pipeline library's answers the PSO cache handles itself (a PSO it
            // does not hold yet, one two threads stored at once, a cache file the driver refuses: thrown away).
            D3D12_MESSAGE_SEVERITY denySeverities[] = {D3D12_MESSAGE_SEVERITY_INFO, D3D12_MESSAGE_SEVERITY_MESSAGE};
            D3D12_MESSAGE_ID denyIds[] = {
                D3D12_MESSAGE_ID_CLEARRENDERTARGETVIEW_MISMATCHINGCLEARVALUE,
                D3D12_MESSAGE_ID_CLEARDEPTHSTENCILVIEW_MISMATCHINGCLEARVALUE,
                D3D12_MESSAGE_ID_MAP_INVALID_NULLRANGE,
                D3D12_MESSAGE_ID_UNMAP_INVALID_NULLRANGE,
                D3D12_MESSAGE_ID_LOADPIPELINE_NAMENOTFOUND,
                D3D12_MESSAGE_ID_STOREPIPELINE_DUPLICATENAME,
                D3D12_MESSAGE_ID_CREATEPIPELINELIBRARY_INVALIDLIBRARYBLOB,
                D3D12_MESSAGE_ID_CREATEPIPELINELIBRARY_DRIVERVERSIONMISMATCH,
                D3D12_MESSAGE_ID_CREATEPIPELINELIBRARY_ADAPTERVERSIONMISMATCH,
                D3D12_MESSAGE_ID_CREATEPIPELINELIBRARY_UNSUPPORTED,
            };
            D3D12_INFO_QUEUE_FILTER filter{};
            filter.DenyList.NumSeverities = UINT(sizeof denySeverities / sizeof denySeverities[0]);
            filter.DenyList.pSeverityList = denySeverities;
            filter.DenyList.NumIDs = UINT(sizeof denyIds / sizeof denyIds[0]);
            filter.DenyList.pIDList = denyIds;
            infoQueue_->PushStorageFilter(&filter);
        }
    }

    D3D12_COMMAND_QUEUE_DESC qd{};
    qd.Type = D3D12_COMMAND_LIST_TYPE_DIRECT;
    HRESULT hr = device_->CreateCommandQueue(&qd, __uuidof(ID3D12CommandQueue), queue_.put_void());
    if (FAILED(hr)) return hr_error("CreateCommandQueue (direct)", hr, "the device was lost; update the GPU driver");
    set_name(queue_.get(), "fa-d3d12-direct-queue");
    // The vendor SDKs' hooks (gpu/device_hooks.h) may wrap the factory, the device and the queue: everything below is
    // made with what they leave.
    if (!hooks_.empty()) hooks_device_created();
    hr = device_->CreateFence(0, D3D12_FENCE_FLAG_NONE, __uuidof(ID3D12Fence), fence_.put_void());
    if (FAILED(hr)) return hr_error("CreateFence", hr, "the device was lost; update the GPU driver");
    fenceEvent_ = CreateEventW(nullptr, FALSE, FALSE, nullptr);
    if (!fenceEvent_)
        return make_error("gpu d3d12: CreateEventW failed (GetLastError " + std::to_string(GetLastError()) + ")",
                          "the process ran out of kernel handles");
    init_side_queues(options.asyncQueues);

    const DeviceInit& in = options.init;
    buffers_.init(in.bufferPoolSize);
    images_.init(in.imagePoolSize);
    views_.init(in.viewPoolSize);
    samplers_.init(in.samplerPoolSize);
    shaders_.init(in.shaderPoolSize);
    pipelines_.init(in.pipelinePoolSize);
    accels_.init(in.bufferPoolSize);  // acceleration structures live in buffers: as many as buffers
    auto count = [](int option, int fallback) { return std::uint32_t(option > 0 ? option : std::max(fallback, 16)); };
    const struct {
        D3D12_DESCRIPTOR_HEAP_TYPE type;
        std::uint32_t n;
        const char* name;
    } heaps[kHeapCount] = {
        // a storage buffer view takes two descriptors (SRV and UAV)
        {D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV, count(options.cpuViewDescriptors, in.viewPoolSize * 2), "view"},
        {D3D12_DESCRIPTOR_HEAP_TYPE_RTV, count(options.cpuRtvDescriptors, in.viewPoolSize / 4), "colour attachment"},
        {D3D12_DESCRIPTOR_HEAP_TYPE_DSV, count(options.cpuDsvDescriptors, in.viewPoolSize / 8), "depth attachment"},
        {D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER, count(options.cpuSamplerDescriptors, in.samplerPoolSize), "sampler"},
    };
    for (int i = 0; i < kHeapCount; ++i)
        if (auto r = cpuHeaps_[std::size_t(i)].init(device_.get(), heaps[i].type, heaps[i].n, heaps[i].name); !r)
            return r;
    // Resource binding tier 1 allows no unbounded descriptor range in a root signature (and at most 128 views per
    // stage): the bindless table, an unbounded SRV range in every root signature, is left out there.
    bindlessDescriptors_ = std::uint32_t(options.bindlessDescriptors);
    if (bindingTier_ < 2 && bindlessDescriptors_ > 0) {
        FA_WARN("render",
                "gpu d3d12: {} has resource binding tier 1, which has no unbounded descriptor ranges: the device makes "
                "no bindless table (D3d12Options::bindlessDescriptors {} is taken as 0; set it to 0 to silence this)",
                adapterName_, bindlessDescriptors_);
        bindlessDescriptors_ = 0;
    }
    // The tier is what the device says; whether its runtime takes the table is asked too, with the table itself: the
    // D3D12 runtime of Windows Server 2022 (10.0.20348) with the WARP of the Microsoft.Direct3D.WARP NuGet package
    // (1.0.22) says tier 2 or more and still refuses every root signature that holds an unbounded SRV range (debug
    // layer message 699, CREATE_ROOT_SIGNATURE_NOT_SUPPORTED_ON_DEVICE). There the device makes no bindless table, so
    // every root signature it makes is one the runtime takes.
    if (bindlessDescriptors_ > 0) {
        std::string why;
        if (!bindless_table_accepted(why)) {
            FA_WARN("render",
                    "gpu d3d12: {} has resource binding tier {}, but its D3D12 runtime refuses the bindless table's "
                    "unbounded SRV range ({}): the device makes no bindless table (D3d12Options::bindlessDescriptors "
                    "{} is taken as 0; set it to 0 to silence this, or update Windows or the GPU driver)",
                    adapterName_, bindingTier_, why, bindlessDescriptors_);
            bindlessDescriptors_ = 0;
        }
    }
    if (auto r = viewHeap_.init(device_.get(), D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV, bindlessDescriptors_,
                                std::uint32_t(options.frameViewDescriptors), framesInFlight_, "fa-d3d12-shader-views");
        !r)
        return r;
    if (const ShaderVisibleHeap::Span bindless = viewHeap_.reserved(); bindless.ok()) {
        // Null textures until something is put there: a table the GPU may read holds no uninitialized descriptor.
        D3D12_SHADER_RESOURCE_VIEW_DESC none{};
        none.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
        none.ViewDimension = D3D12_SRV_DIMENSION_TEXTURE2D;
        none.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
        none.Texture2D.MipLevels = 1;
        D3D12_CPU_DESCRIPTOR_HANDLE at = bindless.cpu;
        for (std::uint32_t i = 0; i < bindless.count; ++i, at.ptr += viewHeap_.increment())
            device_->CreateShaderResourceView(nullptr, &none, at);
    }
    if (auto r = samplerHeap_.init(device_.get(), D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER, 0,
                                   std::uint32_t(options.frameSamplerDescriptors), framesInFlight_,
                                   "fa-d3d12-shader-samplers");
        !r)
        return r;
    // The ring hands out offsets aligned to at most 512 bytes: a size in whole 64 KiB blocks keeps every one inside it.
    if (auto r = ring_.init(device_.get(), std::size_t(align_up(options.uploadRingBytes, 64u * 1024u))); !r) return r;

    const EnvironmentDefaults& env = in.environment.defaults;
    defaults_.colorFormat = env.colorFormat != PixelFormat::Default ? env.colorFormat : PixelFormat::Bgra8;
    defaults_.depthFormat = env.depthFormat != PixelFormat::Default ? env.depthFormat : PixelFormat::DepthStencil;
    defaults_.sampleCount = env.sampleCount > 0 ? env.sampleCount : 1;
    info_.backend = Backend::D3d12;
    info_.metalTarget = MetalTarget::None;
    info_.name = backend_name(Backend::D3d12);
    info_.gpu.vendorId = identity_.vendor;  // the adapter's DXGI_ADAPTER_DESC1 (init_adapter)
    info_.gpu.deviceId = identity_.device;
    info_.gpu.vendor = gpu_vendor_from_pci(identity_.vendor);
    info_.gpu.luidValid = true;
    info_.gpu.luidLow = identity_.luidLow;
    info_.gpu.luidHigh = identity_.luidHigh;
    info_.gpu.software = warp_;
    init_caps();
    // Lists record on any thread (each its own allocator; the shared state is under locks), compute lists run on the
    // compute queue, and every live Texture view has a slot in the bindless table when there is one.
    features_.asyncCompute = bool(side_[0].queue);
    features_.multiThreadRecording = true;
    features_.bindless = bindlessDescriptors_ > 0;
    init_timer();
    pipelineCacheFile_ = options.pipelineCacheFile;
    trimBytes_ = options.pipelineCacheTrimBytes;
    init_pipeline_library();
    dead_ = std::make_unique<D3d12CommandList>(*this);
    drain_messages();
    FA_INFO("render", "gpu d3d12: {} ({}{}{}), {} frames in flight", adapterName_, warp_ ? "WARP" : "hardware",
            debugLayer_ ? ", debug layer" : "", gpuValidation_ ? ", GPU-based validation" : "", framesInFlight_);
    return {};
}

void D3d12Device::init_caps() {
    Features& f = features_;
    f.originTopLeft = true;
    f.imageClampToBorder = true;
    f.mrtIndependentBlendState = true;
    f.mrtIndependentWriteMask = true;
    f.compute = true;
    f.msaaTextureBindings = true;
    f.separateBufferTypes = false;
    f.drawBaseVertex = true;
    f.drawBaseInstance = true;
    f.dualSourceBlending = true;
    f.vertexFormatInt10N2 = false;  // D3D has R10G10B10A2_UNORM only
    f.copyBufferToImageRelaxedBufferType = true;
    f.copyBufferToImageRelaxedBytesPerRow = true;  // unaligned rows are repacked on the GPU (copy_buffer_to_image)
    f.glTextureViews = false;

    Limits& l = limits_;
    l.maxImageSize2d = D3D12_REQ_TEXTURE2D_U_OR_V_DIMENSION;
    l.maxImageSizeCube = D3D12_REQ_TEXTURECUBE_DIMENSION;
    l.maxImageSize3d = D3D12_REQ_TEXTURE3D_U_V_OR_W_DIMENSION;
    l.maxImageSizeArray = D3D12_REQ_TEXTURE2D_U_OR_V_DIMENSION;
    l.maxImageArrayLayers = D3D12_REQ_TEXTURE2D_ARRAY_AXIS_DIMENSION;
    l.maxVertexAttrs = kMaxVertexAttributes;
    l.maxColorAttachments = kMaxColorAttachments;
    l.maxTextureBindingsPerStage = kMaxViews;
    l.maxStorageBufferBindingsPerStage = kMaxViews;
    l.maxStorageImageBindingsPerStage = kMaxViews;

    for (std::uint32_t i = std::uint32_t(PixelFormat::R8); i < std::uint32_t(PixelFormat::Count); ++i) {
        const PixelFormat pf = PixelFormat(i);
        const FormatInfo fi = format_info(pf);
        PixelFormatCaps c;
        c.depth = pixel_format_depth(pf);
        c.compressed = pixel_format_compressed(pf);
        c.bytesPerPixel = pixel_format_bytes(pf);
        if (fi.resource == DXGI_FORMAT_UNKNOWN) {
            caps_[i] = c;
            continue;
        }
        D3D12_FEATURE_DATA_FORMAT_SUPPORT view{};
        view.Format = fi.srv;
        if (FAILED(device_->CheckFeatureSupport(D3D12_FEATURE_FORMAT_SUPPORT, &view, sizeof view))) {
            caps_[i] = c;
            continue;
        }
        const bool tex2d = (view.Support1 & D3D12_FORMAT_SUPPORT1_TEXTURE2D) != 0;
        c.sample = tex2d && (view.Support1 & (D3D12_FORMAT_SUPPORT1_SHADER_LOAD | D3D12_FORMAT_SUPPORT1_SHADER_SAMPLE));
        // as on sokol's backends: integer and depth formats are not filtered (a depth texture is compared)
        c.filter =
            c.sample && (view.Support1 & D3D12_FORMAT_SUPPORT1_SHADER_SAMPLE) && !c.depth && !pixel_format_integer(pf);
        if (!c.compressed) {
            D3D12_FEATURE_DATA_FORMAT_SUPPORT att{};
            att.Format = fi.rtv;
            if (SUCCEEDED(device_->CheckFeatureSupport(D3D12_FEATURE_FORMAT_SUPPORT, &att, sizeof att))) {
                c.render = (att.Support1 &
                            (c.depth ? D3D12_FORMAT_SUPPORT1_DEPTH_STENCIL : D3D12_FORMAT_SUPPORT1_RENDER_TARGET)) != 0;
                c.blend = !c.depth && (att.Support1 & D3D12_FORMAT_SUPPORT1_BLENDABLE) != 0;
                if (c.render && (att.Support1 & D3D12_FORMAT_SUPPORT1_MULTISAMPLE_RENDERTARGET)) {
                    D3D12_FEATURE_DATA_MULTISAMPLE_QUALITY_LEVELS ms{};
                    ms.Format = fi.rtv;
                    ms.SampleCount = 4;
                    c.msaa = SUCCEEDED(device_->CheckFeatureSupport(D3D12_FEATURE_MULTISAMPLE_QUALITY_LEVELS, &ms,
                                                                    sizeof ms)) &&
                             ms.NumQualityLevels > 0;
                }
            }
            if (!c.depth && (view.Support1 & D3D12_FORMAT_SUPPORT1_TYPED_UNORDERED_ACCESS_VIEW)) {
                c.read = (view.Support2 & D3D12_FORMAT_SUPPORT2_UAV_TYPED_LOAD) != 0;
                c.write = (view.Support2 & D3D12_FORMAT_SUPPORT2_UAV_TYPED_STORE) != 0;
            }
        }
        caps_[i] = c;
    }
    init_ray_tracing();
}

// After the device hooks (init): a hook may have replaced device_, and these are its answers.
void D3d12Device::init_ray_tracing() {
    RtCaps caps;
    caps.adapter = adapterName_;
    D3D12_FEATURE_DATA_D3D12_OPTIONS5 o5{};
    if (SUCCEEDED(device_->CheckFeatureSupport(D3D12_FEATURE_D3D12_OPTIONS5, &o5, sizeof o5)))
        caps.tier = int(o5.RaytracingTier);
    // The highest shader model: asked from the newest known value down (a runtime answers E_INVALIDARG for one newer
    // than it knows). None of them: shader model 5.1, which every D3D12 device has.
    caps.shaderModel = 0x51;
    for (int candidate : {0x6A, 0x69, 0x68, 0x67, 0x66, 0x65, 0x64, 0x63, 0x62, 0x61, 0x60}) {
        D3D12_FEATURE_DATA_SHADER_MODEL model{};
        model.HighestShaderModel = D3D_SHADER_MODEL(candidate);
        if (SUCCEEDED(device_->CheckFeatureSupport(D3D12_FEATURE_SHADER_MODEL, &model, sizeof model))) {
            caps.shaderModel = int(model.HighestShaderModel);
            break;
        }
    }
    // The DXR interfaces only where the engine would use them.
    if (caps.tier >= kRtTier1_1 && caps.shaderModel >= kShaderModel6_5) {
        device5_ = device_.as<ID3D12Device5>();
        caps.interfaces = bool(device5_);
    }
    rtCaps_ = caps;
    if (!apply_rt_caps(caps, features_, limits_, rtWhy_)) device5_.reset();
    FA_INFO("render", "gpu d3d12: DXR tier {}, shader model {}: {}", rt_tier_name(caps.tier),
            shader_model_name(caps.shaderModel), rtWhy_.empty() ? std::string("inline ray query") : rtWhy_);
}

bool D3d12Device::storage_image_loadable(PixelFormat format, std::string* why) const {
    DXGI_FORMAT dxgi = DXGI_FORMAT_UNKNOWN;
    switch (format) {
        case PixelFormat::Rgba8: dxgi = DXGI_FORMAT_R8G8B8A8_UNORM; break;
        case PixelFormat::Rgba16F: dxgi = DXGI_FORMAT_R16G16B16A16_FLOAT; break;
        case PixelFormat::R32F: dxgi = DXGI_FORMAT_R32_FLOAT; break;
        case PixelFormat::Rgba32F: dxgi = DXGI_FORMAT_R32G32B32A32_FLOAT; break;
        default: break;
    }
    if (dxgi == DXGI_FORMAT_UNKNOWN) {
        if (why)
            *why = std::string("storage image format ") + pixel_format_name(format) +
                   " is not one the engine reads in a shader (rgba8, rgba16f, r32f or rgba32f)";
        return false;
    }
    // r32f (with r32 uint and sint) loads on every D3D12 GPU; the rest are TypedUAVLoadAdditionalFormats, a group
    // whose members each say so in their format support.
    D3D12_FEATURE_DATA_FORMAT_SUPPORT support{};
    support.Format = dxgi;
    const bool supported =
        SUCCEEDED(device_->CheckFeatureSupport(D3D12_FEATURE_FORMAT_SUPPORT, &support, sizeof support)) &&
        (support.Support2 & D3D12_FORMAT_SUPPORT2_UAV_TYPED_LOAD) != 0;
    if (supported && (format == PixelFormat::R32F || typedUavLoadAdditional_)) return true;
    if (why) {
        if (format != PixelFormat::R32F && !typedUavLoadAdditional_)
            *why = "the D3D12 GPU " + adapterName_ +
                   " has no typed UAV loads beyond r32 (D3D12_OPTIONS.TypedUAVLoadAdditionalFormats is false), so a "
                   "shader cannot read a " +
                   pixel_format_name(format) + " storage image (only r32f loads on every D3D12 GPU)";
        else
            *why = "the D3D12 GPU " + adapterName_ + " cannot load " + pixel_format_name(format) +
                   " from a storage image (its format support has no UAV_TYPED_LOAD; only r32f loads on every D3D12 "
                   "GPU)";
    }
    return false;
}

D3d12Device::~D3d12Device() {
    // DirectStorage writes into this device's resources from its own queue: its reads end (bounded) and its queue and
    // files close before anything goes.
    if (device_ && queue_ && fence_) shutdown_pack_reads();
    packReads_.reset();
    // The window's swapchain goes before the queue it presents on (it waits for the GPU first; the hooks hear it).
    destroy_swapchain();
    // Then the hooks (slShutdown and the SDKs' contexts): the GPU idle, every other object still there.
    // Only a hook that heard d3d12_device_created hears it (an init that failed before, or at the fence, never told
    // them the device was made).
    if (!hooks_.empty() && device_ && queue_) {
        if (fence_) {
            if (auto r = wait_idle(); !r) FA_ERROR("render", "{}", r.error().to_string());
        }
        for (std::size_t i = 0; i < hooks_.size(); ++i)
            if (i < hookCreated_.size() && hookCreated_[i] && hooks_[i]->available()) hooks_[i]->device_destroying();
    }
    // The PSOs made since the cache file was loaded go to it. save_pipeline_cache logs what happened itself: the file
    // it wrote (info), or a warning that says why it wrote none and that the old file stays.
    (void)save_pipeline_cache();
    if (device_ && queue_ && fence_) {
        if (auto r = wait_idle(); !r) FA_ERROR("render", "{}", r.error().to_string());
        std::lock_guard<std::mutex> lock(queueMutex_);
        prelude_ = nullptr;
        deferred_.clear();
    }
    drain_messages();
    if (fenceEvent_) CloseHandle(fenceEvent_);
}

// ---------------------------------------------------------------------------------------------------------------------
// Capabilities, natives, statistics, messages
// ---------------------------------------------------------------------------------------------------------------------

PixelFormatCaps D3d12Device::pixel_format_caps(PixelFormat format) const {
    const std::uint32_t i = std::uint32_t(format);
    if (i >= std::uint32_t(PixelFormat::Count)) return {};
    return caps_[i];
}

NativeDevice D3d12Device::native() const {
    NativeDevice n;
    n.device = device_.get();
    n.context = queue_.get();  // the direct ID3D12CommandQueue
    n.computeQueue =
        side_[0].queue.get();    // the compute ID3D12CommandQueue (null: compute lists run on the direct one)
    n.adapter = adapter_.get();  // IDXGIAdapter1*
    return n;
}

bool D3d12Device::add_commit_listener(void (*func)(void* user), void* user) {
    if (!func) return false;
    std::lock_guard<std::mutex> lock(queueMutex_);
    for (const Listener& l : listeners_)
        if (l.func == func && l.user == user) return false;
    if (listeners_.size() >= 1024) return false;  // sokol's default table size
    listeners_.push_back({func, user});
    return true;
}

bool D3d12Device::remove_commit_listener(void (*func)(void* user), void* user) {
    std::lock_guard<std::mutex> lock(queueMutex_);
    for (auto it = listeners_.begin(); it != listeners_.end(); ++it)
        if (it->func == func && it->user == user) {
            listeners_.erase(it);
            return true;
        }
    return false;
}

void D3d12Device::count_make(ResourceTotals& t, bool ok) {
    if (!statsEnabled_) return;
    ++t.allocated;
    if (ok) ++t.inited;
}

void D3d12Device::count_destroy(ResourceTotals& t) {
    if (!statsEnabled_) return;
    ++t.uninited;
    ++t.deallocated;
}

TotalStats D3d12Device::total_stats() const {
    std::lock_guard<std::mutex> lock(resMutex_);
    TotalStats s = stats_;
    auto pool = [](ResourceTotals& t, int alive, int capacity) {
        t.alive = std::uint32_t(alive);
        t.free = std::uint32_t(capacity - alive);
    };
    pool(s.buffers, buffers_.alive(), buffers_.capacity());
    pool(s.images, images_.alive(), images_.capacity());
    pool(s.views, views_.alive(), views_.capacity());
    pool(s.samplers, samplers_.alive(), samplers_.capacity());
    pool(s.shaders, shaders_.alive(), shaders_.capacity());
    pool(s.pipelines, pipelines_.alive(), pipelines_.capacity());
    return s;
}

void D3d12Device::report(const std::string& message) {
    FA_ERROR("render", "{}", message);
    std::lock_guard<std::mutex> lock(msgMutex_);
    errors_.push_back(message);
}

void D3d12Device::report_once(const std::string& what, const std::string& message) {
    {
        std::lock_guard<std::mutex> lock(msgMutex_);
        if (std::find(notYetReported_.begin(), notYetReported_.end(), what) != notYetReported_.end()) return;
        notYetReported_.push_back(what);
    }
    report(message);
}

std::vector<std::string> D3d12Device::errors() {
    drain_messages();
    std::lock_guard<std::mutex> lock(msgMutex_);
    return errors_;
}

std::vector<std::string> D3d12Device::warnings() {
    drain_messages();
    std::lock_guard<std::mutex> lock(msgMutex_);
    return warnings_;
}

void D3d12Device::clear_messages() {
    drain_messages();
    std::lock_guard<std::mutex> lock(msgMutex_);
    errors_.clear();
    warnings_.clear();
}

void D3d12Device::drain_messages() {
    if (!infoQueue_) return;
    std::lock_guard<std::mutex> lock(msgMutex_);
    const UINT64 n = infoQueue_->GetNumStoredMessagesAllowedByRetrievalFilter();
    std::vector<std::uint64_t> storage;  // 8-byte aligned room for one D3D12_MESSAGE and its text
    for (UINT64 i = 0; i < n; ++i) {
        SIZE_T bytes = 0;
        if (FAILED(infoQueue_->GetMessage(i, nullptr, &bytes)) || bytes == 0) continue;
        storage.assign((bytes + 7) / 8, 0);
        auto* m = reinterpret_cast<D3D12_MESSAGE*>(storage.data());
        if (FAILED(infoQueue_->GetMessage(i, m, &bytes))) continue;
        std::string text(m->pDescription ? m->pDescription : "",
                         m->DescriptionByteLength > 0 ? m->DescriptionByteLength - 1 : 0);
        const bool error =
            m->Severity == D3D12_MESSAGE_SEVERITY_ERROR || m->Severity == D3D12_MESSAGE_SEVERITY_CORRUPTION;
        std::string line = std::string("gpu d3d12 debug layer: ") +
                           (m->Severity == D3D12_MESSAGE_SEVERITY_CORRUPTION ? "CORRUPTION"
                            : error                                          ? "ERROR"
                                                                             : "WARNING") +
                           " #" + std::to_string(int(m->ID)) + ": " + text;
        if (error) {
            FA_ERROR("render", "{}", line);
            errors_.push_back(std::move(line));
        } else if (m->Severity == D3D12_MESSAGE_SEVERITY_WARNING) {
            FA_WARN("render", "{}", line);
            warnings_.push_back(std::move(line));
        }
    }
    infoQueue_->ClearStoredMessages();
}

std::string D3d12Device::removed_reason(const std::string& during) const {
    const HRESULT r = device_->GetDeviceRemovedReason();
    if (r == S_OK) return {};
    if (dred_ && !dredLogged_.exchange(true)) log_dred();
    std::lock_guard<std::mutex> lock(trailMutex_);
    if (removedDuring_.empty()) removedDuring_ = during;
    return d3d12_removal_text(hr_text(r), during, removedDuring_, lastPipeline_, lastList_);
}

void D3d12Device::note_removal(const std::string& during) {
    if (removalNoted_.load(std::memory_order_relaxed)) return;
    const std::string text = removed_reason(during);
    if (text.empty() || removalNoted_.exchange(true)) return;
    report("gpu d3d12: device lost" + text +
           " (hint: the GPU or its driver refused work it was given; DRED's error above names the command, and the "
           "debug layer (D3d12Options::debugLayer) the call; a failing shader is usually found by making its pipeline "
           "alone)");
}

namespace {

const char* dred_op_name(D3D12_AUTO_BREADCRUMB_OP op) {
    switch (op) {
        case D3D12_AUTO_BREADCRUMB_OP_SETMARKER: return "SetMarker";
        case D3D12_AUTO_BREADCRUMB_OP_BEGINEVENT: return "BeginEvent";
        case D3D12_AUTO_BREADCRUMB_OP_ENDEVENT: return "EndEvent";
        case D3D12_AUTO_BREADCRUMB_OP_DRAWINSTANCED: return "DrawInstanced";
        case D3D12_AUTO_BREADCRUMB_OP_DRAWINDEXEDINSTANCED: return "DrawIndexedInstanced";
        case D3D12_AUTO_BREADCRUMB_OP_EXECUTEINDIRECT: return "ExecuteIndirect";
        case D3D12_AUTO_BREADCRUMB_OP_DISPATCH: return "Dispatch";
        case D3D12_AUTO_BREADCRUMB_OP_COPYBUFFERREGION: return "CopyBufferRegion";
        case D3D12_AUTO_BREADCRUMB_OP_COPYTEXTUREREGION: return "CopyTextureRegion";
        case D3D12_AUTO_BREADCRUMB_OP_COPYRESOURCE: return "CopyResource";
        case D3D12_AUTO_BREADCRUMB_OP_COPYTILES: return "CopyTiles";
        case D3D12_AUTO_BREADCRUMB_OP_RESOLVESUBRESOURCE: return "ResolveSubresource";
        case D3D12_AUTO_BREADCRUMB_OP_CLEARRENDERTARGETVIEW: return "ClearRenderTargetView";
        case D3D12_AUTO_BREADCRUMB_OP_CLEARUNORDEREDACCESSVIEW: return "ClearUnorderedAccessView";
        case D3D12_AUTO_BREADCRUMB_OP_CLEARDEPTHSTENCILVIEW: return "ClearDepthStencilView";
        case D3D12_AUTO_BREADCRUMB_OP_RESOURCEBARRIER: return "ResourceBarrier";
        case D3D12_AUTO_BREADCRUMB_OP_EXECUTEBUNDLE: return "ExecuteBundle";
        case D3D12_AUTO_BREADCRUMB_OP_PRESENT: return "Present";
        case D3D12_AUTO_BREADCRUMB_OP_RESOLVEQUERYDATA: return "ResolveQueryData";
        case D3D12_AUTO_BREADCRUMB_OP_BEGINSUBMISSION: return "BeginSubmission";
        case D3D12_AUTO_BREADCRUMB_OP_ENDSUBMISSION: return "EndSubmission";
        case D3D12_AUTO_BREADCRUMB_OP_WRITEBUFFERIMMEDIATE: return "WriteBufferImmediate";
        case D3D12_AUTO_BREADCRUMB_OP_BUILDRAYTRACINGACCELERATIONSTRUCTURE:
            return "BuildRaytracingAccelerationStructure";
        case D3D12_AUTO_BREADCRUMB_OP_COPYRAYTRACINGACCELERATIONSTRUCTURE: return "CopyRaytracingAccelerationStructure";
        default: return nullptr;
    }
}

}  // namespace

void D3d12Device::log_dred() const {
    Com<ID3D12DeviceRemovedExtendedData> dred = device_.as<ID3D12DeviceRemovedExtendedData>();
    if (!dred) return;
    std::string text = "gpu d3d12: DRED, what the GPU was doing when the device was removed:";
    D3D12_DRED_AUTO_BREADCRUMBS_OUTPUT crumbs{};
    if (SUCCEEDED(dred->GetAutoBreadcrumbsOutput(&crumbs))) {
        // Only the lists the GPU had started and not finished: a list it finished (or never began) is not the cause.
        // The node list is bounded by DRED itself; the count below is a safety net far above it.
        int lists = 0;
        for (const D3D12_AUTO_BREADCRUMB_NODE* n = crumbs.pHeadAutoBreadcrumbNode; n && lists < 64; n = n->pNext) {
            const std::uint32_t done = n->pLastBreadcrumbValue ? *n->pLastBreadcrumbValue : 0;
            if (n->BreadcrumbCount == 0 || done >= n->BreadcrumbCount) continue;
            ++lists;
            text += "\n  list '" +
                    (n->pCommandListDebugNameW ? narrow(n->pCommandListDebugNameW) : std::string("unnamed")) +
                    "' on queue '" +
                    (n->pCommandQueueDebugNameW ? narrow(n->pCommandQueueDebugNameW) : std::string("unnamed")) +
                    "': " + std::to_string(done) + " of " + std::to_string(n->BreadcrumbCount) +
                    " commands finished; around the first unfinished one:";
            const std::uint32_t from = done > 4 ? done - 4 : 0;
            const std::uint32_t to = std::min<std::uint32_t>(n->BreadcrumbCount, done + 4);
            for (std::uint32_t i = from; i < to && n->pCommandHistory; ++i) {
                const char* name = dred_op_name(n->pCommandHistory[i]);
                text += (i == done ? " [" : " ") +
                        (name ? std::string(name) : "op " + std::to_string(int(n->pCommandHistory[i]))) +
                        (i == done ? "]" : "");
            }
        }
        if (lists == 0) text += "\n  no command list was unfinished (the removal came between lists)";
    } else {
        text += "\n  no breadcrumbs";
    }
    D3D12_DRED_PAGE_FAULT_OUTPUT fault{};
    if (SUCCEEDED(dred->GetPageFaultAllocationOutput(&fault)) && fault.PageFaultVA != 0) {
        text += std::format("\n  page fault at GPU address 0x{:x}", std::uint64_t(fault.PageFaultVA));
        int shown = 0;
        for (const D3D12_DRED_ALLOCATION_NODE* a = fault.pHeadExistingAllocationNode; a && shown < 8;
             a = a->pNext, ++shown)
            text += std::string(shown == 0 ? "; live there: " : ", ") + (a->ObjectNameW   ? narrow(a->ObjectNameW)
                                                                         : a->ObjectNameA ? std::string(a->ObjectNameA)
                                                                                          : "unnamed");
        shown = 0;
        for (const D3D12_DRED_ALLOCATION_NODE* a = fault.pHeadRecentFreedAllocationNode; a && shown < 8;
             a = a->pNext, ++shown)
            text += std::string(shown == 0 ? "; freed there recently: " : ", ") +
                    (a->ObjectNameW   ? narrow(a->ObjectNameW)
                     : a->ObjectNameA ? std::string(a->ObjectNameA)
                                      : "unnamed");
    } else {
        text += "\n  no page fault recorded";
    }
    FA_ERROR("render", "{}", text);
}

D3d12Counters D3d12Device::counters() const {
    D3d12Counters c;
    {
        std::lock_guard<std::mutex> lock(queueMutex_);
        c.pendingReleases = deferred_.size();
        c.fenceValue = fenceValue_;
    }
    c.completedFenceValue = fence_->GetCompletedValue();
    c.uploadRingWraps = ring_.wraps();
    c.uploadRingBytes = ring_.size();
    c.uploadRingInUse = ring_.in_use();
    c.dedicatedUploads = dedicatedUploads_.load();
    c.barriers = barriers_.load();
    c.cpuViewDescriptors = cpuHeaps_[kHeapView].used();
    c.cpuRtvDescriptors = cpuHeaps_[kHeapRtv].used();
    c.cpuDsvDescriptors = cpuHeaps_[kHeapDsv].used();
    c.cpuSamplerDescriptors = cpuHeaps_[kHeapSampler].used();
    c.frameViewDescriptors = viewHeap_.frame_used();
    c.frameSamplerDescriptors = samplerHeap_.frame_used();
    {
        std::lock_guard<std::mutex> lock(libraryMutex_);
        c.pipelineLibrary = library_.get() != nullptr;
        c.psoLibraryHits = libraryHits_;
        c.psoLibraryMisses = libraryMisses_;
        c.pipelineCacheStored = cacheStored_;
        c.pipelineCacheDiscarded = cacheDiscarded_;
        c.pipelineCacheTrimmed = cacheTrimmed_;
    }
    std::lock_guard<std::mutex> lock(cacheMutex_);
    c.psoCacheHits = psoHits_;
    c.psoCacheMisses = psoMisses_;
    c.psos = psos_.size();
    c.rootSignatureCacheHits = rootHits_;
    c.rootSignatures = rootLayouts_.size();
    pack_read_counters(c);
    return c;
}

// ---------------------------------------------------------------------------------------------------------------------
// The frame: lists, submission, fences, deferred releases
// ---------------------------------------------------------------------------------------------------------------------

void D3d12Device::init_side_queues(bool wanted) {
    if (!wanted) return;
    const struct {
        D3D12_COMMAND_LIST_TYPE type;
        const char* what;
        const char* queue;
        const char* fence;
    } want[2] = {
        {D3D12_COMMAND_LIST_TYPE_COMPUTE, "compute", "fa-d3d12-compute-queue", "fa-d3d12-compute-fence"},
        {D3D12_COMMAND_LIST_TYPE_COPY, "copy", "fa-d3d12-copy-queue", "fa-d3d12-copy-fence"},
    };
    for (std::size_t i = 0; i < side_.size(); ++i) {
        SideQueue& s = side_[i];
        D3D12_COMMAND_QUEUE_DESC qd{};
        qd.Type = want[i].type;
        HRESULT hr = device_->CreateCommandQueue(&qd, __uuidof(ID3D12CommandQueue), s.queue.put_void());
        if (SUCCEEDED(hr))
            hr = device_->CreateFence(0, D3D12_FENCE_FLAG_NONE, __uuidof(ID3D12Fence), s.fence.put_void());
        if (FAILED(hr)) {
            FA_WARN("render", "gpu d3d12: {} could not make its {} queue ({}): those lists run on another queue",
                    adapterName_, want[i].what, hr_text(hr));
            s.queue.reset();
            s.fence.reset();
            continue;
        }
        set_name(s.queue.get(), want[i].queue);
        set_name(s.fence.get(), want[i].fence);
    }
    if (!side_[0].queue && side_[1].queue) {  // map_queue sends every list to the direct queue then: keep no idle one
        side_[1].queue.reset();
        side_[1].fence.reset();
    }
}

QueueKind D3d12Device::map_queue(QueueKind q) const {
    // No compute queue (asyncCompute is false): every queue is the graphics one, a copy queue made on its own too.
    if (!side_[0].queue) return QueueKind::Graphics;
    if (q == QueueKind::Transfer) {
        if (side_[1].queue) return QueueKind::Transfer;
        q = QueueKind::Compute;  // copies run on the compute queue just as well
    }
    if (q == QueueKind::Compute && side_[0].queue) return QueueKind::Compute;
    return QueueKind::Graphics;
}

ID3D12CommandQueue* D3d12Device::queue_of(QueueKind q) const {
    switch (map_queue(q)) {
        case QueueKind::Compute: return side_[0].queue.get();
        case QueueKind::Transfer: return side_[1].queue.get();
        default: return queue_.get();
    }
}

ID3D12Fence* D3d12Device::fence_of(QueueKind q) const {
    switch (map_queue(q)) {
        case QueueKind::Compute: return side_[0].fence.get();
        case QueueKind::Transfer: return side_[1].fence.get();
        default: return fence_.get();
    }
}

std::uint64_t& D3d12Device::fence_value(QueueKind q) {
    switch (map_queue(q)) {
        case QueueKind::Compute: return side_[0].value;
        case QueueKind::Transfer: return side_[1].value;
        default: return fenceValue_;
    }
}

std::uint64_t D3d12Device::completed_value(QueueKind q) const { return fence_of(q)->GetCompletedValue(); }

std::uint64_t D3d12Device::signal(QueueKind q, const char* what) {
    std::uint64_t& value = fence_value(q);
    const HRESULT hr = queue_of(q)->Signal(fence_of(q), ++value);
    if (FAILED(hr))
        report(hr_error(std::string("ID3D12CommandQueue::Signal (") + what + ", the " + queue_name(map_queue(q)) +
                            " queue)",
                        hr, "the device was lost")
                   .to_string() +
               removed_reason());
    return value;
}

bool D3d12Device::token_issued(SyncToken token) const {
    if (!token.valid()) return false;
    const QueueKind q = map_queue(token.queue);
    const std::uint64_t last = q == QueueKind::Compute    ? side_[0].value
                               : q == QueueKind::Transfer ? side_[1].value
                                                          : fenceValue_;
    return token.value <= last;
}

void D3d12Device::queue_wait(QueueKind waiter, SyncToken token) {
    waiter = map_queue(waiter);
    const QueueKind from = map_queue(token.queue);
    if (!token.valid() || from == waiter) return;  // a queue's own order covers its tokens
    std::uint64_t& seen = waited_[std::size_t(waiter)][std::size_t(from)];
    if (token.value <= seen) return;
    const HRESULT hr = queue_of(waiter)->Wait(fence_of(from), token.value);
    if (FAILED(hr)) {
        report(hr_error(std::string("ID3D12CommandQueue::Wait (the ") + queue_name(waiter) + " queue for the " +
                            queue_name(from) + " queue's value " + std::to_string(token.value) + ")",
                        hr, "the device was lost")
                   .to_string() +
               removed_reason());
        return;
    }
    seen = token.value;
}

D3d12CommandList* D3d12Device::acquire_list(const char* label, bool internal, QueueKind kind) {
    collect();
    kind = map_queue(kind);
    auto ready = [&](D3d12CommandList& l) -> D3d12CommandList* {
        if (auto r = l.open(label); !r) {
            report(r.error().to_string());
            return nullptr;
        }
        l.internal_ = internal;
        l.openFrame_ = frame_;
        return &l;
    };
    for (;;) {
        const std::uint64_t completed = completed_value(kind);
        for (auto& l : lists_)
            if (!l->open_ && l->kind_ == kind && l->fence_ <= completed) return ready(*l);
        if (lists_.size() < kMaxLists) break;
        // The pool is full: a finished list of another queue is made again for this one.
        for (auto& l : lists_)
            if (!l->open_ && l->fence_ <= completed_value(l->kind_)) {
                if (auto r = l->create(label, kind); !r) {
                    report(r.error().to_string());
                    return nullptr;
                }
                return ready(*l);
            }
        // Every list is open or in flight: wait for the oldest submitted one of this queue (else of any queue).
        D3d12CommandList* oldest = nullptr;
        for (int pass = 0; pass < 2 && !oldest; ++pass)
            for (auto& l : lists_)
                if (!l->open_ && (pass == 1 || l->kind_ == kind) && (!oldest || l->fence_ < oldest->fence_))
                    oldest = l.get();
        if (!oldest) {
            report("gpu d3d12: begin_commands: " + std::to_string(kMaxLists) +
                   " command lists are open and none was submitted (hint: submit() each list begin_commands() "
                   "returned)");
            return nullptr;
        }
        if (auto r = wait_fence(oldest->fence_, "begin_commands (every command list is in flight)", oldest->kind_);
            !r) {
            report(r.error().to_string());
            return nullptr;
        }
    }
    auto l = std::make_unique<D3d12CommandList>(*this);
    if (auto r = l->create(label, kind); !r) {
        report(r.error().to_string());
        return nullptr;
    }
    lists_.push_back(std::move(l));
    return ready(*lists_.back());
}

CommandList& D3d12Device::begin_commands(const char* label) { return begin_commands(label, QueueKind::Graphics); }

CommandList& D3d12Device::begin_commands(const char* label, QueueKind queue) {
    std::lock_guard<std::mutex> lock(queueMutex_);
    if (D3d12CommandList* l = acquire_list(label ? label : "", false, queue)) return *l;
    // D3D12 could not give a list (reported): hand out the one that ignores everything, so the frame goes on.
    return *dead_;
}

D3d12CommandList& D3d12Device::prelude() {
    if (!prelude_) prelude_ = acquire_list("fa-d3d12-uploads", true);
    return prelude_ ? *prelude_ : *dead_;
}

void D3d12Device::flush_prelude() {
    if (prelude_ && !prelude_->empty_) {
        D3d12CommandList* p = prelude_;
        prelude_ = nullptr;
        execute(*p);
    }
}

void D3d12Device::submit(CommandList& l) { (void)submit_token(l, {}); }

SyncToken D3d12Device::submit_token(CommandList& l, std::span<const QueueHandoff> handoffs) {
    auto* list = dynamic_cast<D3d12CommandList*>(&l);
    if (!list || &list->device_ != this) {
        report("gpu d3d12: submit: the list was not made by this device (hint: submit the list begin_commands() of "
               "this device returned)");
        return {};
    }
    // The handoffs' resources, looked up before queueMutex_ (the lookups take resMutex_).
    struct Move {
        std::shared_ptr<TrackedResource> res;
        QueueKind to = QueueKind::Graphics;
    };
    std::vector<Move> moves;
    moves.reserve(handoffs.size());
    for (std::size_t i = 0; i < handoffs.size(); ++i) {
        const QueueHandoff& h = handoffs[i];
        const std::string at =
            "gpu d3d12: submit_token: handoff " + std::to_string(i) + " of list '" + list->label_ + "'";
        if (h.image.valid() == h.buffer.valid()) {
            report(at + " names " + (h.image.valid() ? "both an image and a buffer" : "no resource") +
                   " (hint: set exactly one of QueueHandoff::image and QueueHandoff::buffer)");
            continue;
        }
        Move m;
        m.to = map_queue(h.to);
        if (h.buffer.valid()) {
            m.res = buffer_tracked(h.buffer, nullptr, nullptr);
        } else if (ImageRecord rec; image_info(h.image, rec)) {
            m.res = rec.tracked;
        }
        if (!m.res) {
            report(at + " names a " + (h.image.valid() ? "destroyed image" : "destroyed buffer") +
                   " (hint: hand a resource over before destroying it)");
            continue;
        }
        moves.push_back(std::move(m));
    }
    std::lock_guard<std::mutex> lock(queueMutex_);
    if (!list->open_) {
        if (list->list_)  // the dead list of a failed begin_commands() needs no second report
            report("gpu d3d12: submit: list '" + list->label_ +
                   "' is not open (hint: submit each list once; take a new one with begin_commands())");
        return {};
    }
    const QueueKind kind = list->kind_;
    const std::uint64_t before = fence_value(kind);
    if (check_submit(*list, "submit")) {
        std::vector<Move*> moving;
        for (Move& m : moves) {
            if (m.res->owner != kind) {
                report("gpu d3d12: submit_token: list '" + list->label_ + "' (the " + queue_name(kind) +
                       " queue) hands over " + m.res->display_name() + ", which the " + queue_name(m.res->owner) +
                       " queue owns (hint: a resource is handed over by a list of the queue that owns it; it stays "
                       "where it is)");
                continue;
            }
            if (m.to == kind) continue;  // stays on this queue
            // The destination queue type takes a texture from COMMON (buffers are COMMON between lists anyway).
            if (!m.res->buffer)
                list->require_plain(m.res, D3d12CommandList::kAllSubresources, D3D12_RESOURCE_STATE_COMMON);
            moving.push_back(&m);
        }
        flush_prelude();  // the initial uploads of resources this list may use go first
        execute(*list);
        if (list->fence_ > before)
            for (Move* m : moving) {
                m->res->owner = m->to;
                m->res->handoff = SyncToken{kind, list->fence_};
            }
    }
    // A list that did not run still gives a token its consumers can wait for.
    const std::uint64_t value = list->fence_ > before ? list->fence_ : signal(kind, "submit");
    return SyncToken{kind, value};
}

bool D3d12Device::check_submit(D3d12CommandList& list, const char* what) {
    const std::string at = std::string("gpu d3d12: ") + what + ": list '" + list.label_ + "'";
    if (list.debugDepth_ != 0) {
        report(at + " still has " + std::to_string(list.debugDepth_) +
               " debug group(s) open (hint: pop_debug_group() once for each push_debug_group())");
        for (; list.debugDepth_ > 0; --list.debugDepth_) list.list_->EndEvent();
    }
    if (list.passState_ != PassState::None) {
        report(at + " is still inside a pass (hint: end_pass() before submit(); it was ended here)");
        list.end_pass();
    }
    if (list.nativeOpen_) {
        report(at + " still has a native section open (hint: end_native() before submit(); it was closed here with "
                    "every resource in its declared state)");
        (void)list.end_native();
    }
    if (list.openFrame_ != frame_) {
        // Its uniforms and descriptors are in the ring room and the descriptor segment of the frame it was opened in,
        // which commit() handed back to the frames after it: running it could read what a later frame wrote there.
        report(at + " was begun in frame " + std::to_string(list.openFrame_) + " and submitted in frame " +
               std::to_string(frame_) +
               "; it was dropped (hint: submit() every list in the frame begin_commands() returned it, before "
               "commit())");
        drop_list(list);
        return false;
    }
    for (auto it = list.waits_.begin(); it != list.waits_.end();) {
        if (token_issued(*it)) {
            ++it;
            continue;
        }
        report(at + " waits for value " + std::to_string(it->value) + " of the " + queue_name(it->queue) +
               " queue, which no submit_token() of this device returned; the wait was dropped (hint: wait_list() "
               "only for a token submit_token() returned, after that call)");
        it = list.waits_.erase(it);
    }
    const QueueKind kind = list.kind_;
    for (const D3d12CommandList::Use& u : list.uses_) {
        const TrackedResource& t = *u.res;
        if (t.owner == kind) continue;
        const char* owner = queue_name(t.owner);
        report(at + " runs on the " + queue_name(kind) + " queue and uses " + t.display_name() + ", which the " +
               owner + " queue owns; the list was dropped (hint: the last " + owner +
               " list that uses it hands it over with submit_token(list, {QueueHandoff{..., QueueKind::" +
               (kind == QueueKind::Compute    ? "Compute"
                : kind == QueueKind::Transfer ? "Transfer"
                                              : "Graphics") +
               "}}), and this list waits for that token with wait_list())");
        drop_list(list);
        return false;
    }
    for (const D3d12CommandList::Use& u : list.uses_) {
        const TrackedResource& t = *u.res;
        if (!t.handoff.valid() || !token_issued(t.handoff)) continue;  // never wait for a value nothing signals
        const QueueKind from = map_queue(t.handoff.queue);
        bool covered = waited_[std::size_t(kind)][std::size_t(from)] >= t.handoff.value;
        for (const SyncToken& w : list.waits_)
            if (map_queue(w.queue) == from && w.value >= t.handoff.value) covered = true;
        if (covered) continue;
        report(at + " uses " + t.display_name() + ", which the " + queue_name(from) +
               " queue handed over to it, without waiting for that handoff's token; the wait was added (hint: "
               "wait_list(list, token) with the token the producer's submit_token() returned)");
        list.waits_.push_back(t.handoff);
    }
    return true;
}

void D3d12Device::timer_list_done(D3d12CommandList& list, bool ran) {
    if (list.scopes_.empty()) return;
    std::lock_guard<std::mutex> lock(timerMutex_);
    const QueueKind kind = list.kind_;
    for (std::size_t i = 0; i < list.scopes_.size(); ++i) {
        const D3d12CommandList::ScopeRef& s = list.scopes_[i];
        if (s.slot < 0) continue;
        TimerSlot& slot = timerSlots_[std::size_t(s.slot)];
        const bool first = std::none_of(list.scopes_.begin(), list.scopes_.begin() + std::ptrdiff_t(i),
                                        [&](const D3d12CommandList::ScopeRef& o) { return o.slot == s.slot; });
        if (first) {
            if (slot.openLists > 0) --slot.openLists;
            if (ran) {
                std::uint64_t& last = slot.lastWrite[std::size_t(kind)];
                last = std::max(last, list.fence_);
            }
        }
        // The scopes of the timed frame still open run before its end: timer_end_frame reports them. Only once the
        // list ran, and only scopes of the frame their slot holds now.
        if (!ran || s.slot != timerCurrent_ || slot.serial != s.serial) continue;
        if (s.scope < slot.submitted.size()) slot.submitted[s.scope] = true;
        if (kind == QueueKind::Compute) slot.computeWait = std::max(slot.computeWait, list.fence_);
    }
    list.scopes_.clear();
}

void D3d12Device::drop_list(D3d12CommandList& list) {
    if (list.list_) list.list_->Close();
    list.open_ = false;
    list.scopeOpen_ = false;
    timer_list_done(list, false);
    list.uses_.clear();
    list.useIndex_.clear();
    list.pending_.clear();
    list.waits_.clear();
    for (Com<ID3D12Resource>& r : list.keep_) {
        Deferred d;
        d.frame = frame_;
        d.raw = std::move(r);
        deferred_.push_back(std::move(d));
    }
    list.keep_.clear();
}

void D3d12Device::execute(D3d12CommandList& list) {
    const QueueKind kind = list.kind_;
    // The device's own lists (uploads, readbacks: graphics) may touch what another queue owns: they leave its textures
    // in COMMON, which every queue type takes, and the owner queue goes on from there.
    std::array<bool, std::size_t(kQueueKinds)> foreign{};
    if (list.internal_) {
        for (std::size_t i = 0; i < list.uses_.size(); ++i) {
            const std::shared_ptr<TrackedResource> t = list.uses_[i].res;
            if (t->owner == kind) continue;
            foreign[std::size_t(t->owner)] = true;
            if (!t->buffer) list.require_plain(t, D3d12CommandList::kAllSubresources, D3D12_RESOURCE_STATE_COMMON);
        }
    }
    list.flush_barriers();
    if (list.scopeOpen_) list.close_scope();  // a timed scope left open ends with its list
    list.open_ = false;
    HRESULT hr = list.list_->Close();
    if (FAILED(hr)) {
        report(hr_error("ID3D12GraphicsCommandList::Close of '" + list.label_ + "'", hr,
                        "the debug layer's message before this one names the command that was wrong")
                   .to_string() +
               removed_reason());
        timer_list_done(list, false);
        list.uses_.clear();
        list.useIndex_.clear();
        list.keep_.clear();
        list.waits_.clear();
        drain_messages();
        return;
    }
    // The waits go first: on the queue, everything submitted after them (the fix-up list too) waits.
    for (const SyncToken& w : list.waits_) queue_wait(kind, w);
    list.waits_.clear();
    for (int q = 0; q < kQueueKinds; ++q)
        if (foreign[std::size_t(q)]) queue_wait(kind, SyncToken{QueueKind(q), fence_value(QueueKind(q))});
    for (const D3d12CommandList::Use& u : list.uses_)
        if (list.internal_ && u.res->owner == kind) queue_wait(kind, u.res->handoff);
    // The fix-up barriers: from the state the queue leaves each resource in to the state the list starts with. Not for
    // buffers: the queue decayed them to COMMON and their first use promotes them (a COMMON -> state barrier would
    // also be one the debug layer checks against a state it promoted itself, BEFORE_AFTER_MISMATCH #527).
    std::vector<D3D12_RESOURCE_BARRIER> fix;
    for (D3d12CommandList::Use& u : list.uses_) {
        TrackedResource& t = *u.res;
        if (t.buffer) continue;
        for (std::uint32_t s = 0; s < std::uint32_t(u.first.size()); ++s) {
            if (u.first[s] == kStateUnknown || t.states[s] == u.first[s]) continue;
            D3D12_RESOURCE_BARRIER b{};
            b.Type = D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
            b.Transition.pResource = t.resource.get();
            b.Transition.Subresource = s;
            b.Transition.StateBefore = D3D12_RESOURCE_STATES(t.states[s]);
            b.Transition.StateAfter = D3D12_RESOURCE_STATES(u.first[s]);
            fix.push_back(b);
        }
    }
    ID3D12CommandList* lists[2] = {};
    UINT n = 0;
    if (!fix.empty()) {
        bool ok = true;
        if (!list.fixup_) {
            hr = device_->CreateCommandAllocator(list_type(kind), __uuidof(ID3D12CommandAllocator),
                                                 list.fixupAllocator_.put_void());
            if (SUCCEEDED(hr))
                hr = device_->CreateCommandList(0, list_type(kind), list.fixupAllocator_.get(), nullptr,
                                                __uuidof(ID3D12GraphicsCommandList), list.fixup_.put_void());
            if (SUCCEEDED(hr)) hr = list.fixup_->Close();
            ok = SUCCEEDED(hr);
        }
        if (ok) hr = list.fixupAllocator_->Reset();
        if (ok && SUCCEEDED(hr)) hr = list.fixup_->Reset(list.fixupAllocator_.get(), nullptr);
        if (ok && SUCCEEDED(hr)) {
            list.fixup_->ResourceBarrier(UINT(fix.size()), fix.data());
            hr = list.fixup_->Close();
        }
        if (!ok || FAILED(hr)) {
            report(hr_error("the fix-up list of '" + list.label_ + "'", hr,
                            "the GPU ran out of memory or the device was lost")
                       .to_string() +
                   removed_reason());
        } else {
            lists[n++] = list.fixup_.get();
            barriers_ += fix.size();
        }
    }
    lists[n++] = list.list_.get();
    {
        std::lock_guard<std::mutex> lock(trailMutex_);
        lastList_ = "'" + list.label_ + "' (" + queue_name(kind) + " queue)";
    }
    queue_of(kind)->ExecuteCommandLists(n, lists);
    note_removal("executing list '" + list.label_ + "' on the " + queue_name(kind) +
                 " queue (checked right after ExecuteCommandLists)");
    // What the list leaves each resource in. Buffers decay to COMMON once the queue finished ExecuteCommandLists,
    // and so does everything a copy queue touched.
    Deferred held;
    held.frame = frame_;
    held.held.reserve(list.uses_.size());
    for (D3d12CommandList::Use& u : list.uses_) {
        TrackedResource& t = *u.res;
        const bool decays = t.buffer || kind == QueueKind::Transfer;
        for (std::size_t s = 0; s < u.current.size(); ++s)
            if (u.current[s] != kStateUnknown)
                t.states[s] = decays ? StateBits(D3D12_RESOURCE_STATE_COMMON) : u.current[s];
        // A handoff this queue waited for is done with.
        if (t.owner == kind && t.handoff.valid() &&
            waited_[std::size_t(kind)][std::size_t(map_queue(t.handoff.queue))] >= t.handoff.value)
            t.handoff = {};
        held.held.push_back(std::move(u.res));
    }
    // The resources stay alive until the frame it was submitted in is finished, even when destroyed meanwhile.
    if (!held.held.empty()) deferred_.push_back(std::move(held));
    list.uses_.clear();
    list.useIndex_.clear();
    for (Com<ID3D12Resource>& r : list.keep_) {
        Deferred d;
        d.frame = frame_;
        d.raw = std::move(r);
        deferred_.push_back(std::move(d));
    }
    list.keep_.clear();
    list.fence_ = signal(kind, "execute");
    timer_list_done(list, true);
    // What it touched of another queue's: that queue waits for it before its next work.
    for (int q = 0; q < kQueueKinds; ++q)
        if (foreign[std::size_t(q)]) queue_wait(QueueKind(q), SyncToken{kind, list.fence_});
}

void D3d12Device::wait_list(CommandList& l, SyncToken token) {
    auto* list = dynamic_cast<D3d12CommandList*>(&l);
    if (!list || &list->device_ != this) {
        report("gpu d3d12: wait_list: the list was not made by this device (hint: pass a list begin_commands() of this "
               "device returned)");
        return;
    }
    if (!list->open_) {
        if (list->list_)
            report("gpu d3d12: wait_list: list '" + list->label_ +
                   "' is not open (hint: wait_list() between begin_commands() and submit())");
        return;
    }
    if (!token.valid()) return;
    token.queue = map_queue(token.queue);
    if (token.queue == list->kind_) return;  // the queue's own order covers it
    list->waits_.push_back(token);           // checked (issued?) and executed at submit
}

void D3d12Device::wait_queue(QueueKind queue, SyncToken token) {
    std::lock_guard<std::mutex> lock(queueMutex_);
    if (!token.valid()) return;
    if (!token_issued(token)) {
        report("gpu d3d12: wait_queue: the " + std::string(queue_name(map_queue(queue))) +
               " queue would wait for value " + std::to_string(token.value) + " of the " + queue_name(token.queue) +
               " queue, which no submit_token() of this device returned; ignored (hint: wait only for a token "
               "submit_token() returned)");
        return;
    }
    queue_wait(queue, token);
}

void D3d12Device::commit() {
    std::vector<Listener> calls;
    {
        std::lock_guard<std::mutex> lock(queueMutex_);
        flush_prelude();
        for (auto& l : lists_)
            if (l->open_ && !l->internal_)
                report("gpu d3d12: commit: list '" + l->label_ +
                       "' was not submitted (hint: submit() every list begin_commands() returned before commit())");
        // The frame ends where every queue is now (the graphics queue at a signal of its own).
        FrameFence ended;
        ended.frame = frame_;
        ended.values[std::size_t(QueueKind::Graphics)] = signal(QueueKind::Graphics, "commit");
        ended.values[std::size_t(QueueKind::Compute)] = side_[0].value;
        ended.values[std::size_t(QueueKind::Transfer)] = side_[1].value;
        frameFences_.push_back(ended);
        ring_.end_frame(frame_);
        ++frame_;
        // The frame that starts now reuses the slot (descriptor segment, ring room) of frame_ - framesInFlight_.
        if (frame_ >= std::uint64_t(framesInFlight_)) {
            const std::uint64_t old = frame_ - std::uint64_t(framesInFlight_);
            for (const FrameFence& f : frameFences_)
                if (f.frame == old) {
                    for (int q = 0; q < kQueueKinds; ++q)
                        if (f.values[std::size_t(q)] > 0)
                            if (auto r =
                                    wait_fence(f.values[std::size_t(q)], "commit (frames in flight)", QueueKind(q));
                                !r)
                                report(r.error().to_string());
                    break;
                }
        }
        collect();
        const int slot = int(frame_ % std::uint64_t(framesInFlight_));
        viewHeap_.begin_frame(slot);
        samplerHeap_.begin_frame(slot);
        calls = listeners_;
    }
    drain_messages();
    pump_pack_reads();  // DirectStorage submissions whose list finished, and finished reads
    for (const Listener& l : calls) l.func(l.user);
}

Result<void> D3d12Device::wait_fence(std::uint64_t value, const char* what, QueueKind queue) {
    ID3D12Fence* fence = fence_of(queue);
    std::uint64_t completed = fence->GetCompletedValue();
    if (completed == UINT64_MAX)
        return make_error(std::string("gpu d3d12: ") + what + ": the GPU device was lost" + removed_reason(),
                          "the debug layer (D3d12Options::debugLayer) usually says which command caused it");
    if (completed >= value) return {};
    const HRESULT hr = fence->SetEventOnCompletion(value, fenceEvent_);
    if (FAILED(hr))
        return hr_error(std::string("ID3D12Fence::SetEventOnCompletion (") + what + ")", hr,
                        "the device was lost" + removed_reason());
    const DWORD r = WaitForSingleObject(fenceEvent_, kFenceWaitMs);
    completed = fence->GetCompletedValue();
    if (r != WAIT_OBJECT_0 || completed == UINT64_MAX || completed < value)
        return make_error(std::string("gpu d3d12: ") + what + ": the " + queue_name(map_queue(queue)) +
                              " queue did not reach fence value " + std::to_string(value) + " within " +
                              std::to_string(kFenceWaitMs / 1000) + " s (it is at " + std::to_string(completed) + ")" +
                              removed_reason(),
                          "the GPU hung or the device was lost: run with D3d12Options::debugLayer for the cause");
    return {};
}

Result<void> D3d12Device::wait_idle() {
    std::lock_guard<std::mutex> lock(queueMutex_);
    flush_prelude();
    Result<void> r;
    for (int q = 0; q < kQueueKinds; ++q) {
        const auto kind = QueueKind(q);
        if (map_queue(kind) != kind) continue;  // no such queue: its lists ran on another one
        const std::uint64_t value = signal(kind, "wait_idle");
        if (auto w = wait_fence(value, "wait_idle", kind); !w && r) r = w;
    }
    collect();
    if (r) {
        // The GPU finished everything submitted: what waits for the open frame can go too (a list still recording
        // holds its own references, and the descriptors it bound were copied when it bound them).
        for (Deferred& d : deferred_) release(d);
        deferred_.clear();
    }
    return r;
}

void D3d12Device::release(Deferred& d) {
    if (d.heap >= 0) {
        if (d.descriptor != kNoDescriptor) cpuHeaps_[std::size_t(d.heap)].free(d.descriptor);
        if (d.descriptor2 != kNoDescriptor) cpuHeaps_[std::size_t(d.heap)].free(d.descriptor2);
    }
    d.heap = -1;
    if (d.bindless != kNoBindlessIndex) free_bindless(d.bindless);
    d.bindless = kNoBindlessIndex;
}

void D3d12Device::collect() {
    // A frame is finished once every queue reached the value its work ended at.
    std::array<std::uint64_t, std::size_t(kQueueKinds)> completed{};
    for (int q = 0; q < kQueueKinds; ++q) {
        completed[std::size_t(q)] = completed_value(QueueKind(q));
        if (completed[std::size_t(q)] == UINT64_MAX) return;  // device lost: keep everything (the destructor drops it)
    }
    auto done = [&](const FrameFence& f) {
        for (int q = 0; q < kQueueKinds; ++q)
            if (f.values[std::size_t(q)] > completed[std::size_t(q)]) return false;
        return true;
    };
    while (!frameFences_.empty() && done(frameFences_.front())) {
        completedFrames_ = frameFences_.front().frame + 1;
        ring_.frame_done(frameFences_.front().frame);
        frameFences_.pop_front();
    }
    while (!deferred_.empty() && deferred_.front().frame < completedFrames_) {
        release(deferred_.front());
        deferred_.pop_front();
    }
}

std::uint32_t D3d12Device::take_bindless(D3D12_CPU_DESCRIPTOR_HANDLE src) {
    const ShaderVisibleHeap::Span table = viewHeap_.reserved();
    if (!table.ok()) return kNoBindlessIndex;
    std::uint32_t index = kNoBindlessIndex;
    std::lock_guard<std::mutex> lock(bindlessMutex_);
    if (!bindlessFree_.empty()) {
        index = bindlessFree_.back();
        bindlessFree_.pop_back();
    } else if (bindlessNext_ < table.count) {
        index = bindlessNext_++;
    } else {
        return kNoBindlessIndex;
    }
    // The root signatures are version 1.0 (descriptors volatile): a slot no running list reads may be written now.
    D3D12_CPU_DESCRIPTOR_HANDLE at = table.cpu;
    at.ptr += SIZE_T(index) * viewHeap_.increment();
    device_->CopyDescriptorsSimple(1, at, src, D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV);
    return index;
}

void D3d12Device::free_bindless(std::uint32_t index) {
    const ShaderVisibleHeap::Span table = viewHeap_.reserved();
    if (!table.ok() || index >= table.count) return;
    D3D12_SHADER_RESOURCE_VIEW_DESC none{};
    none.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
    none.ViewDimension = D3D12_SRV_DIMENSION_TEXTURE2D;
    none.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
    none.Texture2D.MipLevels = 1;
    D3D12_CPU_DESCRIPTOR_HANDLE at = table.cpu;
    at.ptr += SIZE_T(index) * viewHeap_.increment();
    std::lock_guard<std::mutex> lock(bindlessMutex_);
    device_->CreateShaderResourceView(nullptr, &none, at);  // a shader that still indexes it reads zero
    bindlessFree_.push_back(index);
}

void D3d12Device::defer(Deferred d) {
    std::lock_guard<std::mutex> lock(queueMutex_);
    d.frame = frame_;
    deferred_.push_back(std::move(d));
}

UploadAlloc D3d12Device::upload(std::size_t size, std::size_t align, D3d12CommandList* keeper) {
    UploadAlloc a;
    if (ring_.alloc(size, align, a)) return a;
    // Bigger than the ring, or the frames in flight hold it all: a buffer of its own, released with the frame.
    D3D12_RESOURCE_DESC d{};
    d.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
    d.Width = (std::uint64_t(size) + 255u) & ~std::uint64_t(255);
    d.Height = 1;
    d.DepthOrArraySize = 1;
    d.MipLevels = 1;
    d.Format = DXGI_FORMAT_UNKNOWN;
    d.SampleDesc.Count = 1;
    d.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
    Com<ID3D12Resource> r = make_committed(d, D3D12_HEAP_TYPE_UPLOAD, D3D12_RESOURCE_STATE_GENERIC_READ,
                                           "an upload that does not fit the ring", "fa-d3d12-upload");
    if (!r) return {};
    void* p = nullptr;
    const D3D12_RANGE none{0, 0};
    const HRESULT hr = r->Map(0, &none, &p);
    if (FAILED(hr) || !p) {
        report(hr_error("ID3D12Resource::Map (upload of " + std::to_string(size) + " bytes)", hr,
                        "the process ran out of address space or the device was lost")
                   .to_string());
        return {};
    }
    a.resource = r.get();
    a.offset = 0;
    a.cpu = static_cast<std::uint8_t*>(p);
    a.gpu = r->GetGPUVirtualAddress();
    ++dedicatedUploads_;
    if (keeper) {
        keeper->keep_until_done(std::move(r));
    } else {
        Deferred def;
        def.raw = std::move(r);
        defer(std::move(def));
    }
    return a;
}

Com<ID3D12Resource> D3d12Device::make_committed(const D3D12_RESOURCE_DESC& desc, D3D12_HEAP_TYPE heap,
                                                D3D12_RESOURCE_STATES state, const char* what, const char* label) {
    D3D12_HEAP_PROPERTIES hp{};
    hp.Type = heap;
    hp.CPUPageProperty = D3D12_CPU_PAGE_PROPERTY_UNKNOWN;
    hp.MemoryPoolPreference = D3D12_MEMORY_POOL_UNKNOWN;
    hp.CreationNodeMask = 1;
    hp.VisibleNodeMask = 1;
    Com<ID3D12Resource> r;
    const HRESULT hr = device_->CreateCommittedResource(&hp, D3D12_HEAP_FLAG_NONE, &desc, state, nullptr,
                                                        __uuidof(ID3D12Resource), r.put_void());
    if (FAILED(hr) || !r) {
        const std::string size = desc.Dimension == D3D12_RESOURCE_DIMENSION_BUFFER
                                     ? std::to_string(desc.Width) + " bytes"
                                     : std::to_string(desc.Width) + "x" + std::to_string(desc.Height) + "x" +
                                           std::to_string(desc.DepthOrArraySize) + ", " +
                                           std::to_string(desc.MipLevels) + " mips, " +
                                           std::to_string(desc.SampleDesc.Count) + " samples, DXGI format " +
                                           std::to_string(int(desc.Format));
        drain_messages();  // the debug layer's reason comes first
        report(hr_error(std::string(what) + " '" + (label ? label : "") + "': CreateCommittedResource (" + size + ")",
                        hr,
                        hr == E_OUTOFMEMORY ? "the GPU is out of memory: free resources or make them smaller"
                                            : "the debug layer (D3d12Options::debugLayer) says which field is wrong")
                   .to_string() +
               removed_reason());
        return {};
    }
    set_name(r.get(), label);
    return r;
}

}  // namespace fa::gpu::d3d12
