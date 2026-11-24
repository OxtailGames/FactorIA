// The D3D12 device: the factory, the adapter, the debug layer, the queue, the fence and the frames in flight, the
// deferred releases, the capabilities, the statistics and the commit listeners
// (docs/design/ARCHITECTURE_RENDERING_GPU.md, "D3D12 backend").
#include <algorithm>
#include <cstdio>
#include <cstring>
#include <format>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/log.h"
#include "gpu/d3d12_device.h"

namespace fa::gpu {

Result<std::unique_ptr<Device>> make_d3d12_device(const D3d12Options& options) {
    auto device = d3d12::D3d12Device::create(options);
    if (!device) return device.error();
    return std::unique_ptr<Device>(std::move(device.value()));
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
    return {};
}

Result<void> D3d12Device::init(const D3d12Options& options) {
    framesInFlight_ = options.framesInFlight;
    if (auto r = init_adapter(options); !r) return r;

    if (debugLayer_) {
        infoQueue_ = device_.as<ID3D12InfoQueue>();
        if (infoQueue_) {
            // Not errors: a clear colour other than the one given at creation (the engine gives none) and the
            // Map/Unmap of a whole buffer.
            D3D12_MESSAGE_SEVERITY denySeverities[] = {D3D12_MESSAGE_SEVERITY_INFO, D3D12_MESSAGE_SEVERITY_MESSAGE};
            D3D12_MESSAGE_ID denyIds[] = {
                D3D12_MESSAGE_ID_CLEARRENDERTARGETVIEW_MISMATCHINGCLEARVALUE,
                D3D12_MESSAGE_ID_CLEARDEPTHSTENCILVIEW_MISMATCHINGCLEARVALUE,
                D3D12_MESSAGE_ID_MAP_INVALID_NULLRANGE,
                D3D12_MESSAGE_ID_UNMAP_INVALID_NULLRANGE,
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
    hr = device_->CreateFence(0, D3D12_FENCE_FLAG_NONE, __uuidof(ID3D12Fence), fence_.put_void());
    if (FAILED(hr)) return hr_error("CreateFence", hr, "the device was lost; update the GPU driver");
    fenceEvent_ = CreateEventW(nullptr, FALSE, FALSE, nullptr);
    if (!fenceEvent_)
        return make_error("gpu d3d12: CreateEventW failed (GetLastError " + std::to_string(GetLastError()) + ")",
                          "the process ran out of kernel handles");

    const DeviceInit& in = options.init;
    buffers_.init(in.bufferPoolSize);
    images_.init(in.imagePoolSize);
    views_.init(in.viewPoolSize);
    samplers_.init(in.samplerPoolSize);
    shaders_.init(in.shaderPoolSize);
    pipelines_.init(in.pipelinePoolSize);
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
    init_caps();
    init_timer();
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
}

D3d12Device::~D3d12Device() {
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
    n.context = queue_.get();  // the ID3D12CommandQueue
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

std::string D3d12Device::removed_reason() const {
    const HRESULT r = device_->GetDeviceRemovedReason();
    return r == S_OK ? std::string() : "; the device was removed: " + hr_text(r);
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
    std::lock_guard<std::mutex> lock(cacheMutex_);
    c.psoCacheHits = psoHits_;
    c.psoCacheMisses = psoMisses_;
    c.psos = psos_.size();
    c.rootSignatureCacheHits = rootHits_;
    c.rootSignatures = rootLayouts_.size();
    return c;
}

// ---------------------------------------------------------------------------------------------------------------------
// The frame: lists, submission, fences, deferred releases
// ---------------------------------------------------------------------------------------------------------------------

D3d12CommandList* D3d12Device::acquire_list(const char* label, bool internal) {
    collect();
    for (;;) {
        const std::uint64_t completed = fence_->GetCompletedValue();
        for (auto& l : lists_)
            if (!l->open_ && l->fence_ <= completed) {
                if (auto r = l->open(label); !r) {
                    report(r.error().to_string());
                    return nullptr;
                }
                l->internal_ = internal;
                l->openFrame_ = frame_;
                return l.get();
            }
        if (lists_.size() < kMaxLists) break;
        // Every list is open or in flight: wait for the oldest submitted one.
        std::uint64_t oldest = 0;
        for (auto& l : lists_)
            if (!l->open_ && (oldest == 0 || l->fence_ < oldest)) oldest = l->fence_;
        if (oldest == 0) {
            report("gpu d3d12: begin_commands: " + std::to_string(kMaxLists) +
                   " command lists are open and none was submitted (hint: submit() each list begin_commands() "
                   "returned)");
            return nullptr;
        }
        if (auto r = wait_fence(oldest, "begin_commands (every command list is in flight)"); !r) {
            report(r.error().to_string());
            return nullptr;
        }
    }
    auto l = std::make_unique<D3d12CommandList>(*this);
    if (auto r = l->create(label); !r) {
        report(r.error().to_string());
        return nullptr;
    }
    if (auto r = l->open(label); !r) {
        report(r.error().to_string());
        return nullptr;
    }
    l->internal_ = internal;
    l->openFrame_ = frame_;
    lists_.push_back(std::move(l));
    return lists_.back().get();
}

CommandList& D3d12Device::begin_commands(const char* label) {
    std::lock_guard<std::mutex> lock(queueMutex_);
    if (D3d12CommandList* l = acquire_list(label ? label : "", false)) return *l;
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

void D3d12Device::submit(CommandList& l) {
    auto* list = dynamic_cast<D3d12CommandList*>(&l);
    if (!list || &list->device_ != this) {
        report("gpu d3d12: submit: the list was not made by this device (hint: submit the list begin_commands() of "
               "this device returned)");
        return;
    }
    std::lock_guard<std::mutex> lock(queueMutex_);
    if (!list->open_) {
        if (list->list_)  // the dead list of a failed begin_commands() needs no second report
            report("gpu d3d12: submit: list '" + list->label_ +
                   "' is not open (hint: submit each list once; take a new one with begin_commands())");
        return;
    }
    if (list->debugDepth_ != 0) {
        report("gpu d3d12: submit: list '" + list->label_ + "' still has " + std::to_string(list->debugDepth_) +
               " debug group(s) open (hint: pop_debug_group() once for each push_debug_group())");
        for (; list->debugDepth_ > 0; --list->debugDepth_) list->list_->EndEvent();
    }
    if (list->passState_ != PassState::None) {
        report("gpu d3d12: submit: list '" + list->label_ +
               "' is still inside a pass (hint: end_pass() before submit(); it was ended here)");
        list->end_pass();
    }
    if (list->openFrame_ != frame_) {
        // Its uniforms and descriptors are in the ring room and the descriptor segment of the frame it was opened in,
        // which commit() handed back to the frames after it: running it could read what a later frame wrote there.
        report("gpu d3d12: submit: list '" + list->label_ + "' was begun in frame " + std::to_string(list->openFrame_) +
               " and submitted in frame " + std::to_string(frame_) +
               "; it was dropped (hint: submit() every list in the frame begin_commands() returned it, before "
               "commit())");
        list->list_->Close();
        list->open_ = false;
        list->uses_.clear();
        list->useIndex_.clear();
        list->pending_.clear();
        for (Com<ID3D12Resource>& r : list->keep_) {
            Deferred d;
            d.frame = frame_;
            d.raw = std::move(r);
            deferred_.push_back(std::move(d));
        }
        list->keep_.clear();
        return;
    }
    flush_prelude();  // the initial uploads of resources this list may use go first
    execute(*list);
}

void D3d12Device::execute(D3d12CommandList& list) {
    list.flush_barriers();
    if (list.scopeOpen_) list.close_scope();  // a timed scope left open ends with its list
    if (!list.scopes_.empty()) {
        // The scopes of the timed frame still open run before its end: timer_end_frame reports them.
        std::lock_guard<std::mutex> lock(timerMutex_);
        for (const D3d12CommandList::ScopeRef& s : list.scopes_) {
            if (s.slot != timerCurrent_ || s.slot < 0) continue;
            TimerSlot& slot = timerSlots_[std::size_t(s.slot)];
            if (slot.serial == s.serial && s.scope < slot.submitted.size()) slot.submitted[s.scope] = true;
        }
        list.scopes_.clear();
    }
    list.open_ = false;
    HRESULT hr = list.list_->Close();
    if (FAILED(hr)) {
        report(hr_error("ID3D12GraphicsCommandList::Close of '" + list.label_ + "'", hr,
                        "the debug layer's message before this one names the command that was wrong")
                   .to_string() +
               removed_reason());
        list.uses_.clear();
        list.useIndex_.clear();
        list.keep_.clear();
        drain_messages();
        return;
    }
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
            hr = device_->CreateCommandAllocator(D3D12_COMMAND_LIST_TYPE_DIRECT, __uuidof(ID3D12CommandAllocator),
                                                 list.fixupAllocator_.put_void());
            if (SUCCEEDED(hr))
                hr = device_->CreateCommandList(0, D3D12_COMMAND_LIST_TYPE_DIRECT, list.fixupAllocator_.get(), nullptr,
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
    queue_->ExecuteCommandLists(n, lists);
    // What the list leaves each resource in; buffers decay to COMMON once the queue finished ExecuteCommandLists.
    Deferred held;
    held.frame = frame_;
    held.held.reserve(list.uses_.size());
    for (D3d12CommandList::Use& u : list.uses_) {
        TrackedResource& t = *u.res;
        for (std::size_t s = 0; s < u.current.size(); ++s)
            if (u.current[s] != kStateUnknown)
                t.states[s] = t.buffer ? StateBits(D3D12_RESOURCE_STATE_COMMON) : u.current[s];
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
    hr = queue_->Signal(fence_.get(), ++fenceValue_);
    if (FAILED(hr))
        report(hr_error("ID3D12CommandQueue::Signal", hr, "the device was lost").to_string() + removed_reason());
    list.fence_ = fenceValue_;
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
        HRESULT hr = queue_->Signal(fence_.get(), ++fenceValue_);
        if (FAILED(hr))
            report(hr_error("ID3D12CommandQueue::Signal (commit)", hr, "the device was lost").to_string() +
                   removed_reason());
        frameFences_.emplace_back(frame_, fenceValue_);
        ring_.end_frame(frame_);
        ++frame_;
        // The frame that starts now reuses the slot (descriptor segment, ring room) of frame_ - framesInFlight_.
        if (frame_ >= std::uint64_t(framesInFlight_)) {
            const std::uint64_t old = frame_ - std::uint64_t(framesInFlight_);
            for (const auto& [frame, value] : frameFences_)
                if (frame == old) {
                    if (auto r = wait_fence(value, "commit (frames in flight)"); !r) report(r.error().to_string());
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
    for (const Listener& l : calls) l.func(l.user);
}

Result<void> D3d12Device::wait_fence(std::uint64_t value, const char* what) {
    std::uint64_t completed = fence_->GetCompletedValue();
    if (completed == UINT64_MAX)
        return make_error(std::string("gpu d3d12: ") + what + ": the GPU device was lost" + removed_reason(),
                          "the debug layer (D3d12Options::debugLayer) usually says which command caused it");
    if (completed >= value) return {};
    const HRESULT hr = fence_->SetEventOnCompletion(value, fenceEvent_);
    if (FAILED(hr))
        return hr_error(std::string("ID3D12Fence::SetEventOnCompletion (") + what + ")", hr,
                        "the device was lost" + removed_reason());
    const DWORD r = WaitForSingleObject(fenceEvent_, kFenceWaitMs);
    completed = fence_->GetCompletedValue();
    if (r != WAIT_OBJECT_0 || completed == UINT64_MAX || completed < value)
        return make_error(std::string("gpu d3d12: ") + what + ": the GPU did not reach fence value " +
                              std::to_string(value) + " within " + std::to_string(kFenceWaitMs / 1000) +
                              " s (it is at " + std::to_string(completed) + ")" + removed_reason(),
                          "the GPU hung or the device was lost: run with D3d12Options::debugLayer for the cause");
    return {};
}

Result<void> D3d12Device::wait_idle() {
    std::lock_guard<std::mutex> lock(queueMutex_);
    flush_prelude();
    const HRESULT hr = queue_->Signal(fence_.get(), ++fenceValue_);
    if (FAILED(hr)) return hr_error("ID3D12CommandQueue::Signal (wait_idle)", hr, "the device was lost");
    auto r = wait_fence(fenceValue_, "wait_idle");
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
}

void D3d12Device::collect() {
    const std::uint64_t completed = fence_->GetCompletedValue();
    if (completed == UINT64_MAX) return;  // device lost: keep everything (the destructor drops it)
    while (!frameFences_.empty() && frameFences_.front().second <= completed) {
        completedFrames_ = frameFences_.front().first + 1;
        ring_.frame_done(frameFences_.front().first);
        frameFences_.pop_front();
    }
    while (!deferred_.empty() && deferred_.front().frame < completedFrames_) {
        release(deferred_.front());
        deferred_.pop_front();
    }
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
