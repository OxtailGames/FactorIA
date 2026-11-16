// The Apple IME backend's own interface (ime_apple.mm), private to fa_platform. The shared hooks are in ime_impl.h.
#pragma once

#include <cstddef>
#include <span>
#include <string>
#include <string_view>

#include <fa/core/math.h>

#include "ime_text.h"

namespace fa {

class Input;

// Which Input the composition events go to (AppDesc::input; app.cpp sets it when the app starts and clears it at the end).
// Without one the IME backend does nothing and keys and text reach the game as sokol_app delivers them.
void ime_apple_attach(Input* input);
// iOS: sokol_app creates its hidden text field on the first sapp_show_keyboard(); called right after, so the IME handles it.
void ime_apple_keyboard_shown();

// ---- test hooks (macOS) ---------------------------------------------------------------------------------------------------
// The NSTextInputClient that the game's view forwards to, driven without a window: tests call the protocol's methods through
// these. `Client` is opaque; the text is UTF-16 like the protocol's.
namespace ime_apple_test {
struct Client;
Client* create(Input& input, bool enabled);
void destroy(Client* c);
void set_marked(Client* c, std::u16string_view text, std::size_t selLoc, std::size_t selLen,
                std::span<const ime_text::Run> runs = {});
void insert_text(Client* c, std::u16string_view text);
void unmark(Client* c);
void cancel(Client* c);  // ime_cancel()
bool has_marked(const Client* c);
void set_enabled(Client* c, bool enabled);
void set_caret_rect(Client* c, Rect framebufferPixels);
// firstRectForCharacterRange: in the coordinates of a 400 x 300 point view that has no window.
Rect first_rect(Client* c);
}  // namespace ime_apple_test

}  // namespace fa
