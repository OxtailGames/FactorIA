// The only translation unit with the sokol_imgui implementation.
#include "imgui.h"
#include "sokol_app.h"
#include "sokol_gfx.h"
#include "sokol_glue.h"
#include "sokol_log.h"
#define SOKOL_IMGUI_IMPL
#include "sokol_imgui.h"

#include <cstring>
#include <vector>
#if defined(__linux__)
#include <dlfcn.h>
#endif
#if defined(__APPLE__)
#include "backbuffer_apple.h"
#endif
#if defined(_WIN32)
#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <d3d11.h>
#endif

#include "editor_fonts.h"
#include "ui_backend.h"

namespace fa::editor::ui {

namespace {
sg_sampler g_linear{};
const void* g_frameDrawable = nullptr;  // Metal: the window pass's drawable of this frame (read_backbuffer)

void apply_theme() {
    ImGuiStyle& s = ImGui::GetStyle();
    s.WindowRounding = 3.0f;
    s.ChildRounding = 3.0f;
    s.FrameRounding = 3.0f;
    s.PopupRounding = 3.0f;
    s.ScrollbarRounding = 4.0f;
    s.GrabRounding = 3.0f;
    s.TabRounding = 3.0f;
    s.WindowPadding = ImVec2(8, 8);
    s.FramePadding = ImVec2(6, 3);
    s.ItemSpacing = ImVec2(6, 4);
    s.ItemInnerSpacing = ImVec2(4, 4);
    s.IndentSpacing = 16.0f;
    s.ScrollbarSize = 12.0f;
    s.WindowBorderSize = 1.0f;
    s.FrameBorderSize = 0.0f;
    s.TabBarOverlineSize = 0.0f;
    ImVec4* c = s.Colors;
    const ImVec4 bg(0.105f, 0.110f, 0.125f, 1.0f);
    const ImVec4 panel(0.135f, 0.140f, 0.160f, 1.0f);
    const ImVec4 frame(0.185f, 0.195f, 0.225f, 1.0f);
    const ImVec4 hover(0.250f, 0.270f, 0.320f, 1.0f);
    const ImVec4 accent(0.26f, 0.55f, 0.95f, 1.0f);
    c[ImGuiCol_Text] = ImVec4(0.90f, 0.91f, 0.93f, 1.0f);
    c[ImGuiCol_TextDisabled] = ImVec4(0.50f, 0.52f, 0.57f, 1.0f);
    c[ImGuiCol_WindowBg] = panel;
    c[ImGuiCol_ChildBg] = ImVec4(0, 0, 0, 0);
    c[ImGuiCol_PopupBg] = ImVec4(0.12f, 0.125f, 0.145f, 0.98f);
    c[ImGuiCol_Border] = ImVec4(0.06f, 0.065f, 0.075f, 1.0f);
    c[ImGuiCol_FrameBg] = frame;
    c[ImGuiCol_FrameBgHovered] = hover;
    c[ImGuiCol_FrameBgActive] = ImVec4(0.30f, 0.33f, 0.40f, 1.0f);
    c[ImGuiCol_TitleBg] = bg;
    c[ImGuiCol_TitleBgActive] = bg;
    c[ImGuiCol_TitleBgCollapsed] = bg;
    c[ImGuiCol_MenuBarBg] = bg;
    c[ImGuiCol_ScrollbarBg] = ImVec4(0, 0, 0, 0.2f);
    c[ImGuiCol_ScrollbarGrab] = ImVec4(0.28f, 0.30f, 0.35f, 1.0f);
    c[ImGuiCol_CheckMark] = accent;
    c[ImGuiCol_SliderGrab] = accent;
    c[ImGuiCol_SliderGrabActive] = ImVec4(0.40f, 0.66f, 1.0f, 1.0f);
    c[ImGuiCol_Button] = ImVec4(0.23f, 0.25f, 0.30f, 1.0f);
    c[ImGuiCol_ButtonHovered] = ImVec4(0.30f, 0.33f, 0.40f, 1.0f);
    c[ImGuiCol_ButtonActive] = ImVec4(0.24f, 0.50f, 0.88f, 1.0f);
    c[ImGuiCol_Header] = ImVec4(0.20f, 0.22f, 0.27f, 1.0f);
    c[ImGuiCol_HeaderHovered] = ImVec4(0.26f, 0.29f, 0.36f, 1.0f);
    c[ImGuiCol_HeaderActive] = ImVec4(0.24f, 0.46f, 0.80f, 1.0f);
    c[ImGuiCol_Separator] = ImVec4(0.06f, 0.065f, 0.075f, 1.0f);
    c[ImGuiCol_SeparatorHovered] = accent;
    c[ImGuiCol_SeparatorActive] = accent;
    c[ImGuiCol_ResizeGrip] = ImVec4(0.26f, 0.55f, 0.95f, 0.25f);
    c[ImGuiCol_Tab] = bg;
    c[ImGuiCol_TabHovered] = ImVec4(0.26f, 0.45f, 0.78f, 1.0f);
    c[ImGuiCol_TabSelected] = panel;
    c[ImGuiCol_TabSelectedOverline] = accent;
    c[ImGuiCol_TabDimmed] = bg;
    c[ImGuiCol_TabDimmedSelected] = panel;
    c[ImGuiCol_TabDimmedSelectedOverline] = ImVec4(0.4f, 0.4f, 0.45f, 1.0f);
    c[ImGuiCol_DockingPreview] = ImVec4(0.26f, 0.55f, 0.95f, 0.5f);
    c[ImGuiCol_DockingEmptyBg] = bg;
    c[ImGuiCol_TableHeaderBg] = bg;
    c[ImGuiCol_TableBorderStrong] = ImVec4(0.06f, 0.065f, 0.075f, 1.0f);
    c[ImGuiCol_TableBorderLight] = ImVec4(0.17f, 0.18f, 0.2f, 1.0f);
    c[ImGuiCol_TableRowBgAlt] = ImVec4(1, 1, 1, 0.025f);
    c[ImGuiCol_TextSelectedBg] = ImVec4(0.26f, 0.55f, 0.95f, 0.35f);
    c[ImGuiCol_DragDropTarget] = ImVec4(1.0f, 0.8f, 0.2f, 1.0f);
    c[ImGuiCol_NavCursor] = accent;
}
}  // namespace

void gfx_setup() {
    sg_desc d{};
    d.environment = sglue_environment();
    d.logger.func = slog_func;
    sg_setup(&d);
}
void gfx_shutdown() {
    if (sg_isvalid()) sg_shutdown();
}

void setup(const char* iniFile) {
    simgui_desc_t d{};
    d.no_default_font = true;
    d.ini_filename = iniFile;
    d.logger.func = slog_func;
    simgui_setup(&d);
    ImGuiIO& io = ImGui::GetIO();
    io.ConfigFlags |= ImGuiConfigFlags_DockingEnable | ImGuiConfigFlags_NavEnableKeyboard;
    io.ConfigWindowsMoveFromTitleBarOnly = true;
    io.ConfigDockingTransparentPayload = true;
    ImFontConfig cfg;
    cfg.FontDataOwnedByAtlas = false;
    ImFont* font = nullptr;
    for (const auto& f : fa_editor_fonts::files()) {
        font = io.Fonts->AddFontFromMemoryTTF(const_cast<char*>(f.data.data()), int(f.data.size()), 16.0f, &cfg);
        break;
    }
    if (!font) io.Fonts->AddFontDefault();
    apply_theme();

    sg_sampler_desc sd{};
    sd.min_filter = SG_FILTER_LINEAR;
    sd.mag_filter = SG_FILTER_LINEAR;
    sd.wrap_u = SG_WRAP_CLAMP_TO_EDGE;
    sd.wrap_v = SG_WRAP_CLAMP_TO_EDGE;
    g_linear = sg_make_sampler(&sd);
}

void shutdown() {
    if (g_linear.id) {
        sg_destroy_sampler(g_linear);
        g_linear = {};
    }
    simgui_shutdown();
}

void new_frame(int w, int h, double dt, float dpi) {
    simgui_frame_desc_t d{};
    d.width = w;
    d.height = h;
    d.delta_time = dt > 0 ? dt : 1.0 / 60.0;
    d.dpi_scale = dpi;
    simgui_new_frame(&d);
}
void flush() { simgui_flush(); }
void draw() { simgui_draw(); }
bool handle_event(const sapp_event* ev) { return simgui_handle_event(ev); }

std::uint64_t texture_from_view(std::uint32_t viewId, bool linear) {
    sg_view v{viewId};
    return linear ? simgui_imtextureid_with_sampler(v, g_linear) : simgui_imtextureid(v);
}

bool make_texture(int w, int h, const std::uint8_t* rgba, std::uint32_t& imageId, std::uint32_t& viewId) {
    sg_image_desc id{};
    id.width = w;
    id.height = h;
    id.pixel_format = SG_PIXELFORMAT_RGBA8;
    id.data.mip_levels[0].ptr = rgba;
    id.data.mip_levels[0].size = size_t(w) * size_t(h) * 4;
    sg_image img = sg_make_image(&id);
    if (sg_query_image_state(img) != SG_RESOURCESTATE_VALID) return false;
    sg_view_desc vd{};
    vd.texture.image = img;
    sg_view v = sg_make_view(&vd);
    imageId = img.id;
    viewId = v.id;
    return true;
}
void destroy_texture(std::uint32_t imageId, std::uint32_t viewId) {
    if (viewId) sg_destroy_view(sg_view{viewId});
    if (imageId) sg_destroy_image(sg_image{imageId});
}

void prepare_backbuffer_readback() {
#if defined(__APPLE__)
    metal_make_window_readable();
#endif
}

void note_window_swapchain(const sg_swapchain& swapchain) { g_frameDrawable = swapchain.metal.current_drawable; }

bool read_backbuffer(int w, int h, std::uint8_t* out) {
#if defined(__APPLE__)
    return metal_read_drawable(g_frameDrawable, w, h, out);
#elif defined(__linux__)
    // libGL is already loaded by sokol_app; resolve glReadPixels without linking GL.
    void* lib = dlopen("libGL.so.1", RTLD_LAZY | RTLD_NOLOAD);
    if (!lib) lib = dlopen("libGL.so.1", RTLD_LAZY);
    if (!lib) return false;
    using GetProc = void* (*)(const unsigned char*);
    auto getProc = reinterpret_cast<GetProc>(dlsym(lib, "glXGetProcAddressARB"));
    if (!getProc) getProc = reinterpret_cast<GetProc>(dlsym(lib, "glXGetProcAddress"));
    auto load = [&](const char* name) -> void* {
        void* p = getProc ? getProc(reinterpret_cast<const unsigned char*>(name)) : nullptr;
        return p ? p : dlsym(lib, name);
    };
    using BindFb = void (*)(unsigned, unsigned);
    using ReadBuf = void (*)(unsigned);
    using ReadPix = void (*)(int, int, int, int, unsigned, unsigned, void*);
    using PixStore = void (*)(unsigned, int);
    auto bindFb = reinterpret_cast<BindFb>(load("glBindFramebuffer"));
    auto readBuf = reinterpret_cast<ReadBuf>(load("glReadBuffer"));
    auto readPix = reinterpret_cast<ReadPix>(load("glReadPixels"));
    auto pixStore = reinterpret_cast<PixStore>(load("glPixelStorei"));
    if (!readPix) return false;
    if (bindFb) bindFb(0x8CA8 /*GL_READ_FRAMEBUFFER*/, 0);
    if (readBuf) readBuf(0x0405 /*GL_BACK*/);
    if (pixStore) pixStore(0x0D05 /*GL_PACK_ALIGNMENT*/, 1);
    std::vector<std::uint8_t> tmp(size_t(w) * size_t(h) * 4);
    readPix(0, 0, w, h, 0x1908 /*GL_RGBA*/, 0x1401 /*GL_UNSIGNED_BYTE*/, tmp.data());
    for (int y = 0; y < h; ++y) std::memcpy(out + size_t(y) * w * 4, tmp.data() + size_t(h - 1 - y) * w * 4, size_t(w) * 4);
    return true;
#elif defined(_WIN32)
    // D3D11: sokol_gfx has already resolved the MSAA render target into the swap chain's buffer 0 at the end of the
    // window pass, and the flip-discard swap chain only changes buffers inside Present(), which runs after the frame
    // callback returns. So buffer 0 holds exactly the frame just drawn; copy it to a staging texture and map it.
    auto* swap = static_cast<IDXGISwapChain*>(const_cast<void*>(sapp_d3d11_get_swap_chain()));
    auto* dev = static_cast<ID3D11Device*>(const_cast<void*>(sg_d3d11_device()));
    auto* ctx = static_cast<ID3D11DeviceContext*>(const_cast<void*>(sg_d3d11_device_context()));
    if (!swap || !dev || !ctx) return false;
    ID3D11Texture2D* back = nullptr;
    if (FAILED(swap->GetBuffer(0, __uuidof(ID3D11Texture2D), reinterpret_cast<void**>(&back))) || !back) return false;
    D3D11_TEXTURE2D_DESC desc{};
    back->GetDesc(&desc);
    if (int(desc.Width) != w || int(desc.Height) != h || desc.SampleDesc.Count != 1 ||
        (desc.Format != DXGI_FORMAT_B8G8R8A8_UNORM && desc.Format != DXGI_FORMAT_B8G8R8A8_UNORM_SRGB)) {
        back->Release();
        return false;
    }
    D3D11_TEXTURE2D_DESC sd = desc;
    sd.Usage = D3D11_USAGE_STAGING;
    sd.BindFlags = 0;
    sd.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
    sd.MiscFlags = 0;
    ID3D11Texture2D* staging = nullptr;
    D3D11_MAPPED_SUBRESOURCE m{};
    if (FAILED(dev->CreateTexture2D(&sd, nullptr, &staging)) || !staging) {
        back->Release();
        return false;
    }
    ctx->CopyResource(staging, back);
    back->Release();
    if (FAILED(ctx->Map(staging, 0, D3D11_MAP_READ, 0, &m))) {
        staging->Release();
        return false;
    }
    for (int y = 0; y < h; ++y) {
        const auto* src = static_cast<const std::uint8_t*>(m.pData) + size_t(y) * m.RowPitch;
        std::uint8_t* dst = out + size_t(y) * w * 4;
        for (int x = 0; x < w; ++x) {  // BGRA -> RGBA; the surface is already top row first
            dst[x * 4 + 0] = src[x * 4 + 2];
            dst[x * 4 + 1] = src[x * 4 + 1];
            dst[x * 4 + 2] = src[x * 4 + 0];
            dst[x * 4 + 3] = src[x * 4 + 3];
        }
    }
    ctx->Unmap(staging, 0);
    staging->Release();
    return true;
#else
    (void)w; (void)h; (void)out;
    return false;
#endif
}

}  // namespace fa::editor::ui
