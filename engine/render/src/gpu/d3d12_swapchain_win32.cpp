// The window of the D3D12 backend (M77-P9c; d3d12_device.h, "The window"; docs/design/ARCHITECTURE_RENDERING_D3D12.md,
// "Swapchain"): a DXGI flip-model swapchain on a native HWND, made on the direct queue. Its back buffers are images of
// the device's pools (their state tracked like any other image), so a PassDesc::for_swapchain pass is a pass into
// views and present() is one barrier to PRESENT on an internal list, then IDXGISwapChain::Present.
#include <algorithm>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "fa/core/log.h"
#include "gpu/d3d12_device.h"

namespace fa::gpu::d3d12 {
namespace {

// How long acquire_swapchain waits for the frame-latency object: a safety net far above any frame (a window on a
// display that stopped presenting must not hang the render thread). A timeout draws the frame anyway and is counted.
constexpr DWORD kLatencyWaitMs = 1000;

// A swapchain colour format: the back buffers' DXGI format (flip model takes no sRGB buffer format: an sRGB format
// gets UNORM buffers and sRGB render target views) and the colour space they are shown in.
struct SwapFormat {
    DXGI_FORMAT buffer = DXGI_FORMAT_UNKNOWN;
    DXGI_COLOR_SPACE_TYPE space = DXGI_COLOR_SPACE_RGB_FULL_G22_NONE_P709;
    const char* name = "";
};

SwapFormat swap_format(PixelFormat f) {
    switch (f) {
        case PixelFormat::Bgra8:
        case PixelFormat::Sbgr8A8: return {DXGI_FORMAT_B8G8R8A8_UNORM, DXGI_COLOR_SPACE_RGB_FULL_G22_NONE_P709, "sRGB"};
        case PixelFormat::Rgba8:
        case PixelFormat::Srgb8A8: return {DXGI_FORMAT_R8G8B8A8_UNORM, DXGI_COLOR_SPACE_RGB_FULL_G22_NONE_P709, "sRGB"};
        case PixelFormat::Rgba16F:
            return {DXGI_FORMAT_R16G16B16A16_FLOAT, DXGI_COLOR_SPACE_RGB_FULL_G10_NONE_P709, "scRGB"};
        case PixelFormat::Rgb10A2:
            return {DXGI_FORMAT_R10G10B10A2_UNORM, DXGI_COLOR_SPACE_RGB_FULL_G2084_NONE_P2020, "HDR10"};
        default: return {};
    }
}

const char* color_space_name(DXGI_COLOR_SPACE_TYPE s) {
    switch (s) {
        case DXGI_COLOR_SPACE_RGB_FULL_G10_NONE_P709: return "DXGI_COLOR_SPACE_RGB_FULL_G10_NONE_P709";
        case DXGI_COLOR_SPACE_RGB_FULL_G2084_NONE_P2020: return "DXGI_COLOR_SPACE_RGB_FULL_G2084_NONE_P2020";
        default: return "DXGI_COLOR_SPACE_RGB_FULL_G22_NONE_P709";
    }
}

void set_name(ID3D12Object* o, const std::string& label) {
    if (o && !label.empty()) o->SetName(widen(label.c_str()).c_str());
}

// The client size of `hwnd`, at least 1 x 1 (a minimised window has none).
void client_size(HWND hwnd, int& width, int& height) {
    RECT rc{};
    if (hwnd) GetClientRect(hwnd, &rc);
    if (width == 0) width = std::max(1, int(rc.right - rc.left));
    if (height == 0) height = std::max(1, int(rc.bottom - rc.top));
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------
// Formats
// ---------------------------------------------------------------------------------------------------------------------

bool D3d12Device::swapchain_format_supported(PixelFormat format, std::string* why) const {
    if (format == PixelFormat::Default) return true;
    const SwapFormat sf = swap_format(format);
    if (sf.buffer == DXGI_FORMAT_UNKNOWN) {
        if (why)
            *why = std::string("the D3D12 backend's swapchain takes Bgra8, Sbgr8A8, Rgba8, Srgb8A8, Rgba16F (scRGB) or "
                               "Rgb10A2 (HDR10), not ") +
                   pixel_format_name(format);
        return false;
    }
    D3D12_FEATURE_DATA_FORMAT_SUPPORT fs{};
    fs.Format = sf.buffer;
    const UINT need = UINT(D3D12_FORMAT_SUPPORT1_DISPLAY) | UINT(D3D12_FORMAT_SUPPORT1_RENDER_TARGET);
    if (!device_ || FAILED(device_->CheckFeatureSupport(D3D12_FEATURE_FORMAT_SUPPORT, &fs, sizeof fs)) ||
        (UINT(fs.Support1) & need) != need) {
        if (why)
            *why = "the D3D12 GPU " + adapterName_ + " cannot display " + pixel_format_name(format) + " (" + sf.name +
                   ") back buffers (its format support has no DISPLAY and RENDER_TARGET)";
        return false;
    }
    return true;
}

// ---------------------------------------------------------------------------------------------------------------------
// The back buffers' images and views
// ---------------------------------------------------------------------------------------------------------------------

Image D3d12Device::adopt_image(ImageRecord rec) {
    const std::string label = rec.label;
    std::lock_guard<std::mutex> lock(resMutex_);
    const bool ok = rec.tracked != nullptr;
    const std::uint32_t id = images_.add(std::move(rec));
    if (id == 0) {
        report("gpu d3d12: the swapchain's image '" + label + "': the image pool is full (" +
               std::to_string(images_.capacity()) +
               " images) (hint: destroy images you no longer use, or raise DeviceInit::imagePoolSize)");
        return {};
    }
    count_make(stats_.images, ok);
    return Image{id};
}

Result<void> D3d12Device::make_swap_buffers() {
    std::vector<SwapBuffer> buffers;
    Image msaa{}, depth{};
    View msaaView{}, depthView{};
    int width = 0, height = 0, samples = 1;
    PixelFormat depthFormat = PixelFormat::None;
    {
        std::lock_guard<std::mutex> lock(swapMutex_);
        width = swapWidth_;
        height = swapHeight_;
        samples = swapSamples_;
        depthFormat = swapDepthFormat_;
    }
    std::string error;
    for (UINT i = 0; i < swapCount_ && error.empty(); ++i) {
        Com<ID3D12Resource> res;
        const HRESULT hr = swapchain_->GetBuffer(i, __uuidof(ID3D12Resource), res.put_void());
        if (FAILED(hr)) {
            error =
                "IDXGISwapChain::GetBuffer(" + std::to_string(i) + ") failed with " + hr_text(hr) + removed_reason();
            break;
        }
        const std::string name = swapLabel_ + " back buffer " + std::to_string(i);
        set_name(res.get(), name);
        auto t = std::make_shared<TrackedResource>();
        t->resource = std::move(res);
        t->states.assign(1, StateBits(D3D12_RESOURCE_STATE_PRESENT));  // a new back buffer is in PRESENT (COMMON)
        t->label = "image '" + name + "'";
        ImageRecord rec;
        rec.tracked = t;
        rec.type = ImageType::Tex2d;
        rec.usage.colorAttachment = true;
        rec.usage.resolveAttachment = true;
        rec.format = swapFormat_;
        rec.width = width;
        rec.height = height;
        rec.label = name;
        SwapBuffer b;
        b.tracked = std::move(t);
        b.image = adopt_image(std::move(rec));
        if (b.image.id != 0) {
            ViewDesc vd;
            if (samples > 1)
                vd.resolveAttachment.image = b.image;
            else
                vd.colorAttachment.image = b.image;
            vd.label = name.c_str();
            b.view = make_view(vd);
        }
        if (b.image.id == 0 || state(b.view) != ResourceState::Valid)
            error = "the image or view of back buffer " + std::to_string(i) + " could not be made (see errors())";
        buffers.push_back(std::move(b));
    }
    if (error.empty() && samples > 1) {
        const std::string name = swapLabel_ + " msaa";
        ImageDesc id;
        id.usage.colorAttachment = true;
        id.width = width;
        id.height = height;
        id.pixelFormat = swapFormat_;
        id.sampleCount = samples;
        id.label = name.c_str();
        msaa = make_image(id);
        ViewDesc vd;
        vd.colorAttachment.image = msaa;
        vd.label = name.c_str();
        msaaView = make_view(vd);
        if (state(msaaView) != ResourceState::Valid)
            error = "its " + std::to_string(samples) + "x MSAA colour image could not be made (see errors())";
    }
    if (error.empty() && depthFormat != PixelFormat::None) {
        const std::string name = swapLabel_ + " depth";
        ImageDesc id;
        id.usage.depthStencilAttachment = true;
        id.width = width;
        id.height = height;
        id.pixelFormat = depthFormat;
        id.sampleCount = samples;
        id.label = name.c_str();
        depth = make_image(id);
        ViewDesc vd;
        vd.depthStencilAttachment.image = depth;
        vd.label = name.c_str();
        depthView = make_view(vd);
        if (state(depthView) != ResourceState::Valid)
            error =
                std::string("its ") + pixel_format_name(depthFormat) + " depth image could not be made (see errors())";
    }
    {
        // Kept even when something failed: release_swap_buffers() destroys what was made.
        std::lock_guard<std::mutex> lock(swapMutex_);
        swapBuffers_ = std::move(buffers);
        swapMsaa_ = msaa;
        swapMsaaView_ = msaaView;
        swapDepth_ = depth;
        swapDepthView_ = depthView;
    }
    if (!error.empty())
        return make_error("gpu d3d12: the swapchain '" + swapLabel_ + "' (" + std::to_string(width) + "x" +
                              std::to_string(height) + "): " + error,
                          "the GPU ran out of memory, or the image pool or a descriptor heap is full");
    return {};
}

void D3d12Device::release_swap_buffers() {
    std::vector<SwapBuffer> buffers;
    Image msaa{}, depth{};
    View msaaView{}, depthView{};
    {
        std::lock_guard<std::mutex> lock(swapMutex_);
        buffers = std::move(swapBuffers_);
        swapBuffers_.clear();
        msaa = std::exchange(swapMsaa_, Image{});
        depth = std::exchange(swapDepth_, Image{});
        msaaView = std::exchange(swapMsaaView_, View{});
        depthView = std::exchange(swapDepthView_, View{});
        swapAcquired_ = false;
    }
    for (const SwapBuffer& b : buffers) {
        if (b.view.id != 0) destroy_view(b.view);
        if (b.image.id != 0) destroy_image(b.image);
    }
    for (View v : {msaaView, depthView})
        if (v.id != 0) destroy_view(v);
    for (Image i : {msaa, depth})
        if (i.id != 0) destroy_image(i);
    // ResizeBuffers and the swapchain's release need every reference to the back buffers gone: the GPU finishes what
    // uses them (the lists that hold them are then released too), and the tracked resources drop theirs.
    if (auto r = wait_idle(); !r) report(r.error().to_string());
    for (SwapBuffer& b : buffers)
        if (b.tracked) b.tracked->resource.reset();
}

// ---------------------------------------------------------------------------------------------------------------------
// The swapchain
// ---------------------------------------------------------------------------------------------------------------------

Result<void> D3d12Device::create_swapchain(const SwapchainDesc& desc) {
    const std::string label = desc.label && *desc.label ? desc.label : "window";
    const std::string where = "gpu d3d12: create_swapchain '" + label + "'";
    if (swapchain_)
        return make_error(where + ": the device has a swapchain already",
                          "call destroy_swapchain() first, or resize_swapchain() for a new size");
    HWND hwnd = static_cast<HWND>(const_cast<void*>(desc.nativeWindow));
    if (!hwnd)
        return make_error(where + ": SwapchainDesc::nativeWindow is null; the D3D12 backend makes its own swapchain "
                                  "on the window's HWND",
                          "pass the window's HWND in SwapchainDesc::nativeWindow, or draw offscreen "
                          "(RendererDesc::headless true, then Renderer::capture)");
    if (!IsWindow(hwnd))
        return make_error(where + ": SwapchainDesc::nativeWindow is not a window (IsWindow is false)",
                          "pass the HWND of a window that exists (it may have been destroyed)");
    if (desc.width < 0 || desc.height < 0)
        return make_error(where + ": a size of " + std::to_string(desc.width) + "x" + std::to_string(desc.height),
                          "the size is 0 (the window's client size) or more");
    const int samples = desc.sampleCount;
    if (samples != 1 && samples != 2 && samples != 4 && samples != 8)
        return make_error(where + ": sampleCount " + std::to_string(samples) + " is not 1, 2, 4 or 8",
                          "1 is no MSAA; 4 multisamples on every D3D12 GPU");
    const PixelFormat format = desc.colorFormat == PixelFormat::Default ? defaults_.colorFormat : desc.colorFormat;
    std::string why;
    if (!swapchain_format_supported(format, &why))
        return make_error(where + ": " + why,
                          "ask for PixelFormat::Default (the SDR format); swapchain_format_supported() says which "
                          "formats it takes");
    if (samples > 1 && !caps_[std::size_t(format)].msaa)
        return make_error(where + ": " + pixel_format_name(format) + " cannot be multisampled on the D3D12 GPU " +
                              adapterName_,
                          "sampleCount 1, or an SDR format");
    if (samples > 1 && (format == PixelFormat::Srgb8A8 || format == PixelFormat::Sbgr8A8))
        return make_error(where + ": an sRGB swapchain with sampleCount " + std::to_string(samples) +
                              " (its back buffers are UNORM; ResolveSubresource needs one format on both sides)",
                          "sampleCount 1 with " + std::string(pixel_format_name(format)) +
                              ", or Bgra8/Rgba8 with MSAA and an sRGB-encoding last pass");
    const SwapFormat sf = swap_format(format);
    int width = desc.width, height = desc.height;
    if (width == 0 || height == 0) client_size(hwnd, width, height);
    if (width > limits_.maxImageSize2d || height > limits_.maxImageSize2d)
        return make_error(where + ": " + std::to_string(width) + "x" + std::to_string(height) +
                              " is more than the GPU's largest image (" + std::to_string(limits_.maxImageSize2d) + ")",
                          "a smaller window or framebuffer");

    // Tearing (DXGI 1.5): presents without vsync may tear, which variable-refresh displays need.
    BOOL tearing = FALSE;
    if (Com<IDXGIFactory5> f5 = factory_.as<IDXGIFactory5>(); f5)
        if (FAILED(f5->CheckFeatureSupport(DXGI_FEATURE_PRESENT_ALLOW_TEARING, &tearing, sizeof tearing)))
            tearing = FALSE;

    DXGI_SWAP_CHAIN_DESC1 d{};
    d.Width = UINT(width);
    d.Height = UINT(height);
    d.Format = sf.buffer;
    d.SampleDesc.Count = 1;  // flip model: the MSAA image is the swapchain's own, resolved into the back buffer
    d.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    d.BufferCount = UINT(std::max(2, framesInFlight_ + 1));  // one more than the latency: the GPU never waits for one
    d.Scaling = DXGI_SCALING_STRETCH;
    d.SwapEffect = DXGI_SWAP_EFFECT_FLIP_DISCARD;
    d.AlphaMode = DXGI_ALPHA_MODE_IGNORE;
    d.Flags = UINT(DXGI_SWAP_CHAIN_FLAG_FRAME_LATENCY_WAITABLE_OBJECT) |
              (tearing ? UINT(DXGI_SWAP_CHAIN_FLAG_ALLOW_TEARING) : 0u);
    Com<IDXGISwapChain1> chain1;
    // The device hooks (gpu/device_hooks.h) may change the description, make the swapchain themselves (a frame
    // generation proxy) or wrap the one made.
    const bool byHook = !hooks_.empty() && hooks_make_swapchain(hwnd, d, chain1);
    HRESULT hr = S_OK;
    if (!byHook) hr = factory_->CreateSwapChainForHwnd(queue_.get(), hwnd, &d, nullptr, nullptr, chain1.put());
    const bool hooksTold = SUCCEEDED(hr) && !hooks_.empty();
    if (hooksTold) hooks_swapchain_created(chain1);
    // The hooks heard swapchain_created: a swapchain dropped by one of the errors below (before the device keeps it)
    // makes them hear swapchain_destroying too, so the two callbacks always pair.
    struct Pairing {
        D3d12Device& device;
        const void* chain;
        bool armed;
        ~Pairing() {
            if (armed) device.hooks_swapchain_destroying(chain);
        }
    } pairing{*this, chain1.get(), hooksTold};
    if (FAILED(hr)) {
        drain_messages();
        return make_error(where + ": IDXGIFactory2::CreateSwapChainForHwnd failed with " + hr_text(hr) +
                              removed_reason(),
                          "a window takes one swapchain: one of D3D11, OpenGL or sokol_app's may hold it already; "
                          "else the GPU was lost");
    }
    // The engine goes fullscreen by itself (a borderless window), never through DXGI's Alt+Enter.
    factory_->MakeWindowAssociation(hwnd, DXGI_MWA_NO_ALT_ENTER);
    Com<IDXGISwapChain3> chain = chain1.as<IDXGISwapChain3>();
    if (!chain) return make_error(where + ": the swapchain has no IDXGISwapChain3", "D3D12 needs Windows 10 or later");
    if (sf.space != DXGI_COLOR_SPACE_RGB_FULL_G22_NONE_P709) {
        UINT support = 0;
        hr = chain->CheckColorSpaceSupport(sf.space, &support);
        if (FAILED(hr) || !(support & UINT(DXGI_SWAP_CHAIN_COLOR_SPACE_SUPPORT_FLAG_PRESENT)))
            return make_error(where + ": the window's display cannot present " + pixel_format_name(format) + " (" +
                                  sf.name + ") in " + color_space_name(sf.space) +
                                  " (IDXGISwapChain3::CheckColorSpaceSupport)",
                              "turn HDR on in the Windows display settings (fa/platform/hdr_output.h says whether the "
                              "display shows HDR), or ask for PixelFormat::Default");
        hr = chain->SetColorSpace1(sf.space);
        if (FAILED(hr))
            return make_error(where + ": IDXGISwapChain3::SetColorSpace1(" + color_space_name(sf.space) +
                                  ") failed with " + hr_text(hr),
                              "ask for PixelFormat::Default (the SDR format)");
    }
    // As many frames queued as the device has in flight; acquire_swapchain waits for the latency object.
    hr = chain->SetMaximumFrameLatency(UINT(std::max(1, framesInFlight_)));
    if (FAILED(hr))
        return make_error(where + ": IDXGISwapChain2::SetMaximumFrameLatency failed with " + hr_text(hr),
                          "the swapchain was made with DXGI_SWAP_CHAIN_FLAG_FRAME_LATENCY_WAITABLE_OBJECT; a driver "
                          "bug otherwise");

    pairing.armed = false;  // the device keeps it: destroy_swapchain() tells the hooks
    swapchain_ = std::move(chain);
    swapWaitable_ = swapchain_->GetFrameLatencyWaitableObject();
    swapLabel_ = label;
    swapFormat_ = format;
    swapBufferFormat_ = sf.buffer;
    swapColorSpace_ = sf.space;
    swapCount_ = d.BufferCount;
    swapFlags_ = d.Flags;
    if (DXGI_SWAP_CHAIN_DESC1 made{}; byHook && SUCCEEDED(swapchain_->GetDesc1(&made))) {
        swapCount_ = made.BufferCount;  // what the hook's swapchain has, for its back buffers and its resizes
        swapFlags_ = made.Flags;
    }
    swapTearing_ = tearing != FALSE;
    swapVsync_ = desc.vsync;
    swapWaitTimeouts_ = 0;
    {
        std::lock_guard<std::mutex> lock(swapMutex_);
        swapWidth_ = width;
        swapHeight_ = height;
        swapSamples_ = samples;
        swapDepthFormat_ = defaults_.depthFormat;
        swapAcquired_ = false;
        swapIndex_ = 0;
    }
    if (auto made = make_swap_buffers(); !made) {
        destroy_swapchain();
        return made;
    }
    drain_messages();
    FA_INFO("render", "gpu d3d12: swapchain '{}' {}x{} {} ({}), {} buffers, {} sample(s), tearing {}", swapLabel_,
            width, height, pixel_format_name(format), sf.name, swapCount_, samples,
            swapTearing_ ? "allowed" : "not supported");
    return {};
}

Result<void> D3d12Device::resize_swapchain(int width, int height) {
    if (!swapchain_)
        return make_error("gpu d3d12: resize_swapchain without a swapchain", "call create_swapchain() first");
    const std::string where = "gpu d3d12: resize_swapchain '" + swapLabel_ + "'";
    if (width < 0 || height < 0)
        return make_error(where + " to " + std::to_string(width) + "x" + std::to_string(height),
                          "the size is 0 (the window's client size) or more");
    int oldW = 0, oldH = 0;
    {
        std::lock_guard<std::mutex> lock(swapMutex_);
        if (swapAcquired_)
            return make_error(where + " between acquire_swapchain() and present()",
                              "resize before the frame's acquire_swapchain() (the passes of this frame draw into the "
                              "buffer it acquired)");
        oldW = swapWidth_;
        oldH = swapHeight_;
    }
    if (width == 0 || height == 0) {
        HWND hwnd = nullptr;
        swapchain_->GetHwnd(&hwnd);
        client_size(hwnd, width, height);
    }
    if (width > limits_.maxImageSize2d || height > limits_.maxImageSize2d)
        return make_error(where + " to " + std::to_string(width) + "x" + std::to_string(height) +
                              ": more than the GPU's largest image (" + std::to_string(limits_.maxImageSize2d) + ")",
                          "a smaller window or framebuffer");
    const bool whole = swapBuffers_.size() == swapCount_;  // a failed resize left none
    if (width == oldW && height == oldH && whole) return {};

    // Every list that uses the back buffers finishes and every reference to them goes before ResizeBuffers.
    release_swap_buffers();
    const HRESULT hr =
        swapchain_->ResizeBuffers(swapCount_, UINT(width), UINT(height), DXGI_FORMAT_UNKNOWN, swapFlags_);
    if (FAILED(hr)) {
        // The old buffers are still the swapchain's: make their images again, so the window keeps presenting.
        (void)make_swap_buffers();
        drain_messages();
        return make_error(where + " to " + std::to_string(width) + "x" + std::to_string(height) +
                              ": IDXGISwapChain::ResizeBuffers failed with " + hr_text(hr) + removed_reason(),
                          "the GPU ran out of memory or was lost; the swapchain keeps its old size");
    }
    // New buffers keep the colour space only where the driver says so: set it again.
    if (swapColorSpace_ != DXGI_COLOR_SPACE_RGB_FULL_G22_NONE_P709) (void)swapchain_->SetColorSpace1(swapColorSpace_);
    {
        std::lock_guard<std::mutex> lock(swapMutex_);
        swapWidth_ = width;
        swapHeight_ = height;
    }
    auto made = make_swap_buffers();
    drain_messages();
    return made;
}

Result<Swapchain> D3d12Device::acquire_swapchain(const Swapchain&) {
    if (!swapchain_)
        return make_error("gpu d3d12: acquire_swapchain without a swapchain",
                          "call create_swapchain() with the window's HWND first");
    bool waited = false;
    {
        std::lock_guard<std::mutex> lock(swapMutex_);
        waited = swapAcquired_;  // a second acquire of the frame hands back the same buffer
        // Without buffers (a failed resize) no present follows: waiting would use up the latency count for nothing.
        if (swapBuffers_.size() != swapCount_) waited = true;
    }
    if (!waited && swapWaitable_ && WaitForSingleObjectEx(swapWaitable_, kLatencyWaitMs, FALSE) == WAIT_TIMEOUT)
        ++swapWaitTimeouts_;
    std::lock_guard<std::mutex> lock(swapMutex_);
    if (swapBuffers_.size() != swapCount_)
        return make_error("gpu d3d12: acquire_swapchain '" + swapLabel_ +
                              "': its buffers were not made (an earlier "
                              "resize_swapchain failed)",
                          "resize_swapchain() again, or destroy_swapchain() and create_swapchain()");
    if (!swapAcquired_) {
        swapIndex_ = swapchain_->GetCurrentBackBufferIndex();
        swapAcquired_ = true;
    }
    Swapchain sc;
    sc.width = swapWidth_;
    sc.height = swapHeight_;
    sc.sampleCount = swapSamples_;
    sc.colorFormat = swapFormat_;
    sc.depthFormat = swapDepthFormat_;
    return sc;
}

std::string D3d12Device::swapchain_pass(const PassDesc& pass, PassDesc& into) const {
    std::lock_guard<std::mutex> lock(swapMutex_);
    if (!swapchain_)
        return "a pass into the window (PassDesc::swapchain) without a swapchain (hint: create_swapchain() with the "
               "window's HWND first, or draw into views)";
    if (!swapAcquired_ || swapIndex_ >= swapBuffers_.size())
        return "a pass into the window before this frame's acquire_swapchain() (hint: acquire_swapchain() once per "
               "frame before the passes into the window; present() ends the frame)";
    const Swapchain& sc = *pass.swapchain;
    if (sc.width != swapWidth_ || sc.height != swapHeight_)
        return "PassDesc::swapchain is " + std::to_string(sc.width) + "x" + std::to_string(sc.height) +
               ", the window's swapchain " + std::to_string(swapWidth_) + "x" + std::to_string(swapHeight_) +
               " (hint: begin the pass with the Swapchain acquire_swapchain() returned this frame)";
    into = pass;
    into.swapchain = nullptr;
    into.color1 = {};
    const SwapBuffer& b = swapBuffers_[swapIndex_];
    if (swapSamples_ > 1) {
        into.color = swapMsaaView_;
        into.resolve = b.view;
    } else {
        into.color = b.view;
        into.resolve = {};
    }
    into.depth = pass.format.depth == PixelFormat::None ? View{} : swapDepthView_;
    return {};
}

Result<void> D3d12Device::present() {
    if (!swapchain_)
        return make_error("gpu d3d12: present without a swapchain",
                          "call create_swapchain() with the window's HWND first");
    std::shared_ptr<TrackedResource> back;
    UINT presented = 0;
    {
        std::lock_guard<std::mutex> lock(swapMutex_);
        presented = swapIndex_;
        if (!swapAcquired_)
            return make_error("gpu d3d12: present of the swapchain '" + swapLabel_ +
                                  "' without this frame's acquire_swapchain()",
                              "acquire_swapchain(), draw, commit(), then present() once");
        if (swapIndex_ < swapBuffers_.size()) back = swapBuffers_[swapIndex_].tracked;
    }
    {
        // The back buffer goes to PRESENT on the direct queue, behind the frame's lists: the fix-up barrier of an
        // internal list that only requires that state.
        std::lock_guard<std::mutex> lock(queueMutex_);
        flush_prelude();
        if (D3d12CommandList* list = acquire_list("fa-d3d12-present", true)) {
            if (back) list->require(back, D3d12CommandList::kAllSubresources, D3D12_RESOURCE_STATE_PRESENT);
            execute(*list);
        }
    }
    const UINT interval = swapVsync_ ? 1u : 0u;
    const UINT flags = !swapVsync_ && swapTearing_ ? UINT(DXGI_PRESENT_ALLOW_TEARING) : 0u;
    HRESULT hr = S_OK;
    if (hooks_.empty()) {
        hr = swapchain_->Present(interval, flags);
    } else {  // the hooks see each present (Reflex and Anti-Lag markers, frame generation's pacing)
        ++presents_;
        hooks_present(true, presented, S_OK);
        hr = swapchain_->Present(interval, flags);
        hooks_present(false, presented, hr);
    }
    {
        std::lock_guard<std::mutex> lock(swapMutex_);
        swapAcquired_ = false;
    }
    drain_messages();
    // DXGI_STATUS_OCCLUDED (a minimised or hidden window) is a success: the frame is not shown, the next one goes on.
    if (FAILED(hr))
        return make_error("gpu d3d12: present of the swapchain '" + swapLabel_ + "': IDXGISwapChain::Present failed " +
                              "with " + hr_text(hr) + removed_reason(),
                          "the GPU was lost or reset: run with D3d12Options::debugLayer for the cause");
    return {};
}

void D3d12Device::destroy_swapchain() {
    if (!swapchain_) return;
    release_swap_buffers();
    if (!hooks_.empty()) hooks_swapchain_destroying(swapchain_.get());
    if (swapWaitable_) {
        CloseHandle(swapWaitable_);
        swapWaitable_ = nullptr;
    }
    swapchain_.reset();
    swapLabel_.clear();
    swapFormat_ = PixelFormat::None;
    swapBufferFormat_ = DXGI_FORMAT_UNKNOWN;
    swapColorSpace_ = DXGI_COLOR_SPACE_RGB_FULL_G22_NONE_P709;
    swapCount_ = 0;
    swapFlags_ = 0;
    swapTearing_ = false;
    std::lock_guard<std::mutex> lock(swapMutex_);
    swapWidth_ = swapHeight_ = 0;
    swapSamples_ = 1;
    swapDepthFormat_ = PixelFormat::None;
    swapIndex_ = 0;
}

bool D3d12Device::has_swapchain() const { return bool(swapchain_); }

Image D3d12Device::swapchain_image() const {
    std::lock_guard<std::mutex> lock(swapMutex_);
    if (!swapAcquired_ || swapIndex_ >= swapBuffers_.size()) return {};
    return swapBuffers_[swapIndex_].image;
}

int D3d12Device::swapchain_buffer_count() const { return swapchain_ ? int(swapCount_) : 0; }
bool D3d12Device::swapchain_tearing() const { return swapchain_ && swapTearing_; }
std::uint64_t D3d12Device::swapchain_wait_timeouts() const { return swapWaitTimeouts_; }

// ---- device hooks (gpu/device_hooks.h) ----

bool D3d12Device::hooks_make_swapchain(HWND hwnd, DXGI_SWAP_CHAIN_DESC1& desc, Com<IDXGISwapChain1>& chain) {
    for (const auto& h : hooks_) {
        if (!h->available()) continue;
        const DXGI_SWAP_CHAIN_DESC1 before = desc;
        D3d12SwapchainCreate sc;
        sc.factory = factory_.get();
        sc.queue = queue_.get();
        sc.hwnd = hwnd;
        sc.desc = &desc;
        const bool byHook = h->d3d12_create_swapchain(sc);
        // The engine's buffer count and flags stay (it waits on the frame latency object, counts its back buffers).
        desc.BufferCount = before.BufferCount;
        desc.Flags = before.Flags;
        std::string error = sc.error;
        if (error.empty() && byHook && !sc.swapchain)
            error = "it said it made the swapchain, but gave no IDXGISwapChain1";
        if (!error.empty()) {
            if (sc.swapchain) {  // a swapchain handed with an error is released
                Com<IDXGISwapChain1> drop;
                *drop.put() = static_cast<IDXGISwapChain1*>(sc.swapchain);
            }
            desc = before;
            hook_unavailable(*h, "making the swapchain failed: " + error +
                                     "; the engine made its own swapchain without the hook");
            continue;
        }
        if (byHook) {
            *chain.put() = static_cast<IDXGISwapChain1*>(sc.swapchain);
            return true;
        }
    }
    return false;
}

void D3d12Device::hooks_swapchain_created(Com<IDXGISwapChain1>& chain) {
    for (const auto& h : hooks_) {
        if (!h->available()) continue;
        void* s = chain.get();
        h->d3d12_swapchain_created(s);
        if (s && s != chain.get()) *chain.put() = static_cast<IDXGISwapChain1*>(s);
    }
}

void D3d12Device::hooks_swapchain_destroying(const void* swapchain) {
    SwapchainEvent e;
    e.backend = Backend::D3d12;
    e.swapchain = swapchain;
    for (const auto& h : hooks_)
        if (h->available()) h->swapchain_destroying(e);
}

void D3d12Device::hooks_present(bool begin, UINT image, HRESULT result) {
    PresentEvent e;
    e.backend = Backend::D3d12;
    e.frame = presents_;
    e.swapchain = swapchain_.get();
    e.queue = queue_.get();
    e.imageIndex = std::uint32_t(image);
    e.result = std::int32_t(result);
    for (const auto& h : hooks_) {
        if (!h->available()) continue;
        if (begin)
            h->present_begin(e);
        else
            h->present_end(e);
    }
}

}  // namespace fa::gpu::d3d12
