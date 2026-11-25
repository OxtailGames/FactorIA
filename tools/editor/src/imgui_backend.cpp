// The editor's Dear ImGui backend. Dear ImGui's draw data goes to the renderer's 2D painter (fa::render::UiPainter, which
// knows nothing of ImGui and owns every GPU object); sokol_app events go to ImGui's input queue. No sokol_gfx or
// sokol_imgui call lives here.
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "imgui.h"
#include "sokol_app.h"
#if defined(__linux__)
#include <dlfcn.h>
#endif
#if defined(__APPLE__)
#include "backbuffer_apple.h"
#endif

#include "editor_fonts.h"
#include "fa/core/log.h"
#include "fa/render/renderer.h"
#include "fa/render/ui_painter.h"
#include "ui_backend.h"

namespace fa::editor::ui {

namespace {

using render::UiDrawCommand;
using render::UiDrawList;
using render::UiFrame;
using render::UiNativeHandles;
using render::UiPainter;
using render::UiTexture;
using render::UiVertex;

// An ImDrawVert is copied into the painter's vertex buffer as it is.
static_assert(sizeof(ImDrawVert) == sizeof(UiVertex) && offsetof(ImDrawVert, pos) == offsetof(UiVertex, x) &&
                  offsetof(ImDrawVert, uv) == offsetof(UiVertex, u) &&
                  offsetof(ImDrawVert, col) == offsetof(UiVertex, color),
              "UiVertex must have the layout of ImDrawVert");
static_assert(sizeof(ImDrawIdx) == sizeof(std::uint16_t), "the painter draws 16-bit indices");

std::unique_ptr<UiPainter> g_painter;
UiNativeHandles g_native;  // this frame's Metal drawable and the queue / D3D11 device (read_backbuffer)

// What flush() prepared and draw() draws: the pointers refer to the ImDrawLists of the frame, which live until the next
// new_frame().
std::vector<UiDrawList> g_lists;
std::vector<UiDrawCommand> g_commands;
UiFrame g_frame;
bool g_reportedBadFrame = false;  // one log line for a UI that cannot be drawn, not one per frame

// An ImTextureID is the picture's view id, plus 1 << 32 when its pixels are shown as they are (no smoothing).
constexpr std::uint64_t kNearestBit = std::uint64_t(1) << 32;

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

void report_once(const std::string& what) {
    if (g_reportedBadFrame) return;
    g_reportedBadFrame = true;
    FA_ERROR("editor", "the editor's UI cannot be drawn: {}", what);
}

// Dear ImGui asks for textures (its font atlas) by status: make, update the changed rectangle, or free them.
void update_textures(ImDrawData* drawData) {
    if (!drawData->Textures) return;
    for (ImTextureData* tex : *drawData->Textures) {
        std::string error;
        if (tex->Status == ImTextureStatus_WantCreate) {
            const UiTexture t = g_painter->make_updatable_texture(tex->Width, tex->Height, &error);
            if (!t.valid() || !g_painter->update_texture(t, 0, 0, tex->Width, tex->Height,
                                                         static_cast<const std::uint8_t*>(tex->GetPixels()),
                                                         tex->GetPitch(), &error)) {
                if (t.valid()) g_painter->destroy_texture(t);
                report_once(error);
                continue;
            }
            tex->BackendUserData = reinterpret_cast<void*>(std::uintptr_t(t.image));
            tex->SetTexID(ImTextureID(t.view));
            tex->SetStatus(ImTextureStatus_OK);
        } else if (tex->Status == ImTextureStatus_WantUpdates) {
            const UiTexture t{std::uint32_t(std::uintptr_t(tex->BackendUserData)), std::uint32_t(tex->TexID)};
            const ImTextureRect& r = tex->UpdateRect;
            if (r.w > 0 && r.h > 0 &&
                !g_painter->update_texture(t, r.x, r.y, r.w, r.h,
                                           static_cast<const std::uint8_t*>(tex->GetPixelsAt(r.x, r.y)),
                                           tex->GetPitch(), &error)) {
                report_once(error);
                continue;
            }
            tex->SetStatus(ImTextureStatus_OK);
        } else if (tex->Status == ImTextureStatus_WantDestroy && tex->UnusedFrames > 0) {
            g_painter->destroy_texture(
                UiTexture{std::uint32_t(std::uintptr_t(tex->BackendUserData)), std::uint32_t(tex->TexID)});
            tex->BackendUserData = nullptr;
            tex->SetTexID(ImTextureID_Invalid);
            tex->SetStatus(ImTextureStatus_Destroyed);
        }
    }
}

ImGuiKey map_keycode(sapp_keycode key) {
    // The letters, digits, function and keypad keys are consecutive in both enums.
    if (key >= SAPP_KEYCODE_A && key <= SAPP_KEYCODE_Z) return ImGuiKey(ImGuiKey_A + (key - SAPP_KEYCODE_A));
    if (key >= SAPP_KEYCODE_0 && key <= SAPP_KEYCODE_9) return ImGuiKey(ImGuiKey_0 + (key - SAPP_KEYCODE_0));
    if (key >= SAPP_KEYCODE_F1 && key <= SAPP_KEYCODE_F12) return ImGuiKey(ImGuiKey_F1 + (key - SAPP_KEYCODE_F1));
    if (key >= SAPP_KEYCODE_KP_0 && key <= SAPP_KEYCODE_KP_9)
        return ImGuiKey(ImGuiKey_Keypad0 + (key - SAPP_KEYCODE_KP_0));
    switch (key) {
        case SAPP_KEYCODE_SPACE: return ImGuiKey_Space;
        case SAPP_KEYCODE_APOSTROPHE: return ImGuiKey_Apostrophe;
        case SAPP_KEYCODE_COMMA: return ImGuiKey_Comma;
        case SAPP_KEYCODE_MINUS: return ImGuiKey_Minus;
        case SAPP_KEYCODE_PERIOD: return ImGuiKey_Period;
        case SAPP_KEYCODE_SLASH: return ImGuiKey_Slash;
        case SAPP_KEYCODE_SEMICOLON: return ImGuiKey_Semicolon;
        case SAPP_KEYCODE_EQUAL: return ImGuiKey_Equal;
        case SAPP_KEYCODE_LEFT_BRACKET: return ImGuiKey_LeftBracket;
        case SAPP_KEYCODE_BACKSLASH: return ImGuiKey_Backslash;
        case SAPP_KEYCODE_RIGHT_BRACKET: return ImGuiKey_RightBracket;
        case SAPP_KEYCODE_GRAVE_ACCENT: return ImGuiKey_GraveAccent;
        case SAPP_KEYCODE_ESCAPE: return ImGuiKey_Escape;
        case SAPP_KEYCODE_ENTER: return ImGuiKey_Enter;
        case SAPP_KEYCODE_TAB: return ImGuiKey_Tab;
        case SAPP_KEYCODE_BACKSPACE: return ImGuiKey_Backspace;
        case SAPP_KEYCODE_INSERT: return ImGuiKey_Insert;
        case SAPP_KEYCODE_DELETE: return ImGuiKey_Delete;
        case SAPP_KEYCODE_RIGHT: return ImGuiKey_RightArrow;
        case SAPP_KEYCODE_LEFT: return ImGuiKey_LeftArrow;
        case SAPP_KEYCODE_DOWN: return ImGuiKey_DownArrow;
        case SAPP_KEYCODE_UP: return ImGuiKey_UpArrow;
        case SAPP_KEYCODE_PAGE_UP: return ImGuiKey_PageUp;
        case SAPP_KEYCODE_PAGE_DOWN: return ImGuiKey_PageDown;
        case SAPP_KEYCODE_HOME: return ImGuiKey_Home;
        case SAPP_KEYCODE_END: return ImGuiKey_End;
        case SAPP_KEYCODE_CAPS_LOCK: return ImGuiKey_CapsLock;
        case SAPP_KEYCODE_SCROLL_LOCK: return ImGuiKey_ScrollLock;
        case SAPP_KEYCODE_NUM_LOCK: return ImGuiKey_NumLock;
        case SAPP_KEYCODE_PRINT_SCREEN: return ImGuiKey_PrintScreen;
        case SAPP_KEYCODE_PAUSE: return ImGuiKey_Pause;
        case SAPP_KEYCODE_KP_DECIMAL: return ImGuiKey_KeypadDecimal;
        case SAPP_KEYCODE_KP_DIVIDE: return ImGuiKey_KeypadDivide;
        case SAPP_KEYCODE_KP_MULTIPLY: return ImGuiKey_KeypadMultiply;
        case SAPP_KEYCODE_KP_SUBTRACT: return ImGuiKey_KeypadSubtract;
        case SAPP_KEYCODE_KP_ADD: return ImGuiKey_KeypadAdd;
        case SAPP_KEYCODE_KP_ENTER: return ImGuiKey_KeypadEnter;
        case SAPP_KEYCODE_KP_EQUAL: return ImGuiKey_KeypadEqual;
        case SAPP_KEYCODE_LEFT_SHIFT: return ImGuiKey_LeftShift;
        case SAPP_KEYCODE_LEFT_CONTROL: return ImGuiKey_LeftCtrl;
        case SAPP_KEYCODE_LEFT_ALT: return ImGuiKey_LeftAlt;
        case SAPP_KEYCODE_LEFT_SUPER: return ImGuiKey_LeftSuper;
        case SAPP_KEYCODE_RIGHT_SHIFT: return ImGuiKey_RightShift;
        case SAPP_KEYCODE_RIGHT_CONTROL: return ImGuiKey_RightCtrl;
        case SAPP_KEYCODE_RIGHT_ALT: return ImGuiKey_RightAlt;
        case SAPP_KEYCODE_RIGHT_SUPER: return ImGuiKey_RightSuper;
        case SAPP_KEYCODE_MENU: return ImGuiKey_Menu;
        default: return ImGuiKey_None;
    }
}

#if defined(__APPLE__)
constexpr bool kIsMac = true;
#else
constexpr bool kIsMac = false;
#endif

// The key that copies and pastes: Cmd on macOS, Ctrl elsewhere.
bool is_copy_paste_modifier(std::uint32_t modifiers) {
    return (modifiers & (kIsMac ? SAPP_MODIFIER_SUPER : SAPP_MODIFIER_CTRL)) != 0;
}

void update_modifiers(ImGuiIO& io, std::uint32_t mods) {
    io.AddKeyEvent(ImGuiMod_Ctrl, (mods & SAPP_MODIFIER_CTRL) != 0);
    io.AddKeyEvent(ImGuiMod_Shift, (mods & SAPP_MODIFIER_SHIFT) != 0);
    io.AddKeyEvent(ImGuiMod_Alt, (mods & SAPP_MODIFIER_ALT) != 0);
    io.AddKeyEvent(ImGuiMod_Super, (mods & SAPP_MODIFIER_SUPER) != 0);
}

void add_mouse_pos(ImGuiIO& io, float x, float y, ImGuiMouseSource source) {
    io.AddMouseSourceEvent(source);
    io.AddMousePosEvent(x, y);
}

void apply_mouse_cursor() {
    sapp_mouse_cursor cursor = sapp_get_mouse_cursor();
    switch (ImGui::GetMouseCursor()) {
        case ImGuiMouseCursor_Arrow: cursor = SAPP_MOUSECURSOR_ARROW; break;
        case ImGuiMouseCursor_TextInput: cursor = SAPP_MOUSECURSOR_IBEAM; break;
        case ImGuiMouseCursor_ResizeAll: cursor = SAPP_MOUSECURSOR_RESIZE_ALL; break;
        case ImGuiMouseCursor_ResizeNS: cursor = SAPP_MOUSECURSOR_RESIZE_NS; break;
        case ImGuiMouseCursor_ResizeEW: cursor = SAPP_MOUSECURSOR_RESIZE_EW; break;
        case ImGuiMouseCursor_ResizeNESW: cursor = SAPP_MOUSECURSOR_RESIZE_NESW; break;
        case ImGuiMouseCursor_ResizeNWSE: cursor = SAPP_MOUSECURSOR_RESIZE_NWSE; break;
        case ImGuiMouseCursor_Hand: cursor = SAPP_MOUSECURSOR_POINTING_HAND; break;
        case ImGuiMouseCursor_NotAllowed: cursor = SAPP_MOUSECURSOR_NOT_ALLOWED; break;
        default: break;
    }
    sapp_set_mouse_cursor(cursor);
}

}  // namespace

void gfx_setup() {
    std::string error;
    if (!Renderer::open_context(app_gfx_environment(), &error))
        FA_ERROR("editor", "the graphics context could not be opened: {}", error);
}
void gfx_shutdown() { Renderer::close_context(); }

void setup(const char* iniFile) {
    ImGui::CreateContext();
    ImGui::StyleColorsDark();
    ImGuiIO& io = ImGui::GetIO();
    io.IniFilename = iniFile;
    io.ConfigMacOSXBehaviors = kIsMac;
    io.BackendPlatformName = "factoria-sokol-app";
    io.BackendRendererName = "factoria-ui-painter";
    io.BackendFlags |= ImGuiBackendFlags_RendererHasVtxOffset | ImGuiBackendFlags_RendererHasTextures |
                       ImGuiBackendFlags_HasMouseCursors;
    io.ConfigFlags |= ImGuiConfigFlags_DockingEnable | ImGuiConfigFlags_NavEnableKeyboard;
    io.ConfigWindowsMoveFromTitleBarOnly = true;
    io.ConfigDockingTransparentPayload = true;
    io.ConfigDragClickToInputText = true;  // the Inspector: a click on a number types a value, a drag changes it
    ImFontConfig cfg;
    cfg.FontDataOwnedByAtlas = false;
    ImFont* font = nullptr;
    for (const auto& f : fa_editor_fonts::files()) {
        font = io.Fonts->AddFontFromMemoryTTF(const_cast<char*>(f.data.data()), int(f.data.size()), 16.0f, &cfg);
        break;
    }
    if (!font) io.Fonts->AddFontDefault();
    apply_theme();

    std::string error;
    g_painter = UiPainter::create(&error);
    g_reportedBadFrame = false;
    if (!g_painter) report_once(error);
}

void shutdown() {
    if (ImGui::GetCurrentContext()) {
        if (g_painter) {
            for (ImTextureData* tex : ImGui::GetPlatformIO().Textures) {
                if (tex->RefCount == 1 && tex->TexID != ImTextureID_Invalid) {
                    g_painter->destroy_texture(
                        UiTexture{std::uint32_t(std::uintptr_t(tex->BackendUserData)), std::uint32_t(tex->TexID)});
                    tex->BackendUserData = nullptr;
                    tex->SetTexID(ImTextureID_Invalid);
                    tex->SetStatus(ImTextureStatus_Destroyed);
                }
            }
        }
        ImGui::DestroyContext();
    }
    g_lists.clear();
    g_commands.clear();
    g_frame = UiFrame{};
    g_native = UiNativeHandles{};
    g_painter.reset();
}

void new_frame(int w, int h, double dt, float dpi) {
    const float scale = dpi > 0.0f ? dpi : 1.0f;
    ImGuiIO& io = ImGui::GetIO();
    io.DisplaySize = ImVec2(float(w) / scale, float(h) / scale);
    io.DisplayFramebufferScale = ImVec2(scale, scale);
    io.DeltaTime = dt > 0 ? float(dt) : 1.0f / 60.0f;
    if (io.WantTextInput && !sapp_keyboard_shown()) sapp_show_keyboard(true);
    if (!io.WantTextInput && sapp_keyboard_shown()) sapp_show_keyboard(false);
    apply_mouse_cursor();
    ImGui::NewFrame();
}

void flush() {
    g_lists.clear();
    g_commands.clear();
    g_frame = UiFrame{};
    ImGui::Render();
    ImDrawData* drawData = ImGui::GetDrawData();
    if (!drawData || !g_painter) return;
    update_textures(drawData);

    // One UiDrawCommand per ImDrawCmd (a user callback draws nothing: the editor registers none). g_commands is sized
    // first, so the pointers into it stay valid.
    std::size_t commandCount = 0;
    for (const ImDrawList* list : drawData->CmdLists) commandCount += std::size_t(list->CmdBuffer.Size);
    g_commands.reserve(commandCount);
    std::vector<std::pair<std::size_t, std::size_t>> ranges;  // [first, count) of each list in g_commands
    for (const ImDrawList* list : drawData->CmdLists) {
        const std::size_t first = g_commands.size();
        for (const ImDrawCmd& cmd : list->CmdBuffer) {
            if (cmd.UserCallback) continue;
            const ImTextureID id = cmd.GetTexID();
            UiDrawCommand c;
            c.view = std::uint32_t(id & 0xFFFFFFFFu);
            c.nearest = (id & kNearestBit) != 0;
            c.clipMinX = cmd.ClipRect.x;
            c.clipMinY = cmd.ClipRect.y;
            c.clipMaxX = cmd.ClipRect.z;
            c.clipMaxY = cmd.ClipRect.w;
            c.indexOffset = cmd.IdxOffset;
            c.indexCount = cmd.ElemCount;
            c.vertexOffset = cmd.VtxOffset;
            g_commands.push_back(c);
        }
        ranges.emplace_back(first, g_commands.size() - first);
    }
    g_lists.reserve(ranges.size());
    for (int i = 0; i < drawData->CmdLists.Size; ++i) {
        const ImDrawList* list = drawData->CmdLists[i];
        UiDrawList l;
        l.vertices = reinterpret_cast<const UiVertex*>(list->VtxBuffer.Data);
        l.vertexCount = list->VtxBuffer.Size;
        l.indices = reinterpret_cast<const std::uint16_t*>(list->IdxBuffer.Data);
        l.indexCount = list->IdxBuffer.Size;
        l.commands = g_commands.data() + ranges[std::size_t(i)].first;
        l.commandCount = int(ranges[std::size_t(i)].second);
        g_lists.push_back(l);
    }
    g_frame.displayWidth = ImGui::GetIO().DisplaySize.x;
    g_frame.displayHeight = ImGui::GetIO().DisplaySize.y;
    g_frame.scaleX = drawData->FramebufferScale.x;
    g_frame.scaleY = drawData->FramebufferScale.y;
    g_frame.lists = g_lists.data();
    g_frame.listCount = int(g_lists.size());
    std::string error;
    if (!g_painter->upload(g_frame, &error)) report_once(error);
}

void draw(const fa::GfxSwapchain& swapchain) {
    if (g_painter && g_frame.listCount > 0) g_painter->draw(swapchain, g_frame);
}

bool handle_event(const sapp_event* ev) {
    ImGuiIO& io = ImGui::GetIO();
    const float scale = io.DisplayFramebufferScale.x > 0.0f ? io.DisplayFramebufferScale.x : 1.0f;
    switch (ev->type) {
        case SAPP_EVENTTYPE_FOCUSED: io.AddFocusEvent(true); break;
        case SAPP_EVENTTYPE_UNFOCUSED: io.AddFocusEvent(false); break;
        case SAPP_EVENTTYPE_MOUSE_DOWN:
        case SAPP_EVENTTYPE_MOUSE_UP:
            add_mouse_pos(io, ev->mouse_x / scale, ev->mouse_y / scale, ImGuiMouseSource_Mouse);
            // SAPP_MOUSEBUTTON_INVALID (0x100, a button sokol does not name) is not an ImGui button: only left, right, middle pass.
            if (ev->mouse_button >= SAPP_MOUSEBUTTON_LEFT && ev->mouse_button <= SAPP_MOUSEBUTTON_MIDDLE)
                io.AddMouseButtonEvent(int(ev->mouse_button), ev->type == SAPP_EVENTTYPE_MOUSE_DOWN);
            update_modifiers(io, ev->modifiers);
            break;
        case SAPP_EVENTTYPE_MOUSE_MOVE:
            add_mouse_pos(io, ev->mouse_x / scale, ev->mouse_y / scale, ImGuiMouseSource_Mouse);
            break;
        case SAPP_EVENTTYPE_MOUSE_SCROLL:
            io.AddMouseSourceEvent(ImGuiMouseSource_Mouse);
            io.AddMouseWheelEvent(ev->scroll_x, ev->scroll_y);
            break;
        case SAPP_EVENTTYPE_TOUCHES_BEGAN:
        case SAPP_EVENTTYPE_TOUCHES_MOVED:
        case SAPP_EVENTTYPE_TOUCHES_ENDED:
            add_mouse_pos(io, ev->touches[0].pos_x / scale, ev->touches[0].pos_y / scale, ImGuiMouseSource_TouchScreen);
            if (ev->type != SAPP_EVENTTYPE_TOUCHES_MOVED)
                io.AddMouseButtonEvent(0, ev->type == SAPP_EVENTTYPE_TOUCHES_BEGAN);
            break;
        case SAPP_EVENTTYPE_TOUCHES_CANCELLED:
            io.AddMouseSourceEvent(ImGuiMouseSource_TouchScreen);
            io.AddMouseButtonEvent(0, false);
            break;
        case SAPP_EVENTTYPE_KEY_DOWN:
        case SAPP_EVENTTYPE_KEY_UP: {
            const bool down = ev->type == SAPP_EVENTTYPE_KEY_DOWN;
            update_modifiers(io, ev->modifiers);
            // Ctrl/Cmd+V arrives as SAPP_EVENTTYPE_CLIPBOARD_PASTED below.
            if (is_copy_paste_modifier(ev->modifiers) && ev->key_code == SAPP_KEYCODE_V) break;
            // Copy and cut are the UI's: the browser must not see them either.
            if (is_copy_paste_modifier(ev->modifiers) &&
                (ev->key_code == SAPP_KEYCODE_X || ev->key_code == SAPP_KEYCODE_C))
                sapp_consume_event();
            io.AddKeyEvent(map_keycode(ev->key_code), down);  // an unmapped key is ImGuiKey_None, which ImGui ignores
            break;
        }
        case SAPP_EVENTTYPE_CHAR:
            update_modifiers(io, ev->modifiers);
            // Some platforms report special keys as characters; with Alt, Ctrl or Cmd down it is a shortcut, not text.
            if (ev->char_code >= 32 && ev->char_code != 127 &&
                (ev->modifiers & (SAPP_MODIFIER_ALT | SAPP_MODIFIER_CTRL | SAPP_MODIFIER_SUPER)) == 0)
                io.AddInputCharacter(ev->char_code);
            break;
        case SAPP_EVENTTYPE_CLIPBOARD_PASTED: {
            const ImGuiKey modifier = kIsMac ? ImGuiMod_Super : ImGuiMod_Ctrl;  // a Ctrl/Cmd+V key press
            io.AddKeyEvent(modifier, true);
            io.AddKeyEvent(ImGuiKey_V, true);
            io.AddKeyEvent(ImGuiKey_V, false);
            io.AddKeyEvent(modifier, false);
            break;
        }
        default: break;
    }
    return io.WantCaptureKeyboard || io.WantCaptureMouse;
}

std::uint64_t texture_from_view(std::uint32_t viewId, bool linear) {
    return std::uint64_t(viewId) | (linear ? 0 : kNearestBit);
}

bool make_texture(int w, int h, const std::uint8_t* rgba, std::uint32_t& imageId, std::uint32_t& viewId) {
    if (!g_painter) return false;
    const UiTexture t = g_painter->make_texture(w, h, rgba, nullptr);
    if (!t.valid()) return false;
    imageId = t.image;
    viewId = t.view;
    return true;
}
void destroy_texture(std::uint32_t imageId, std::uint32_t viewId) {
    if (g_painter) g_painter->destroy_texture(UiTexture{imageId, viewId});
}

void prepare_backbuffer_readback(bool showWindow) {
#if defined(__APPLE__)
    metal_make_window_readable(showWindow);
#else
    (void)showWindow;
#endif
}

void note_window_swapchain(const fa::GfxSwapchain& swapchain) { g_native = render::native_window_handles(swapchain); }

bool read_backbuffer(int w, int h, std::uint8_t* out) {
#if defined(__APPLE__)
    return metal_read_drawable(g_native.metalDrawable, g_native.metalQueue, w, h, out);
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
    for (int y = 0; y < h; ++y)
        std::memcpy(out + size_t(y) * w * 4, tmp.data() + size_t(h - 1 - y) * w * 4, size_t(w) * 4);
    return true;
#elif defined(_WIN32)
    // D3D11: the window pass has resolved MSAA into the swapchain's buffer 0, and the flip model only changes buffers inside
    // Present(), which the platform runs after the frame callback returns: the platform's presenter copies that buffer.
    return fa::app_read_window_back_buffer(w, h, out);
#else
    (void)w;
    (void)h;
    (void)out;
    return false;
#endif
}

}  // namespace fa::editor::ui
