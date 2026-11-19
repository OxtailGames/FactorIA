// The editor's text clipboard. Normally it is the system clipboard (sokol_app). The editor autotest gets a private one that
// lives in this process: the autotest copies and pastes text and checks what it finds, and another program writing to the
// system clipboard in between (a chat window, a clipboard manager, a second editor running its own autotest) failed the
// Ctrl+V and Paste checks at random. The private clipboard works the same on every OS and leaves the user's clipboard alone.
#include <cstdint>
#include <string>
#include <vector>

#include "editor_internal.h"
#include "sokol_app.h"

namespace fa::editor {

namespace {
bool g_private = false;
std::string g_privateText;
}  // namespace

void clipboard_use_private(bool on) {
    g_private = on;
    g_privateText.clear();
}

bool clipboard_is_private() { return g_private; }

void clipboard_set_text(const char* text) {
    if (g_private)
        g_privateText = text ? text : "";
    else
        sapp_set_clipboard_string(text ? text : "");
}

const char* clipboard_get_text() {
    if (g_private) return g_privateText.c_str();
    const char* text = sapp_get_clipboard_string();
    return text ? text : "";
}

// A private clipboard holds text only: a picture on the system clipboard is none of its business.
bool clipboard_has_text() { return g_private || system_clipboard_has_text(); }

std::vector<std::uint8_t> clipboard_image_png() {
    return g_private ? std::vector<std::uint8_t>{} : system_clipboard_image_png();
}

}  // namespace fa::editor
