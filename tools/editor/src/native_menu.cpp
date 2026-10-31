#include "native_menu.h"

#include <cstdlib>
#include <cstring>

namespace fa::editor {

bool native_menu_wanted() {
#ifdef __APPLE__
    const char* v = std::getenv("FA_EDITOR_NATIVE_MENU");  // =0: the in-window ImGui bar, as on Windows and Linux
    return !(v && std::strcmp(v, "0") == 0);
#else
    return false;
#endif
}

#ifndef __APPLE__
std::unique_ptr<NativeMenu> make_native_menu(const NativeAppMenuSpec&) { return nullptr; }  // native_menu_apple.mm has the real one
#endif

}  // namespace fa::editor
