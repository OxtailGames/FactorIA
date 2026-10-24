// Steam's own keyboard for a TextField that a gamepad player focuses (plugin API 3, docs/PLATFORM.md "Steam Deck keyboard").
//
// Only on a Steam Deck or in Big Picture: on a desktop Steam a player has a physical keyboard, and the game's own on-screen
// keyboard (menu kit) serves a pad. Two keyboards, tried in this order:
//   floating  ShowFloatingGamepadTextInput: Steam draws a keyboard over the game, next to the field, and types into the window
//             as key presses, so the TextField fills exactly as with a real keyboard. Nothing comes back through this plugin.
//   modal     ShowGamepadTextInput: a full-screen keyboard. When the player is done Steam sends GamepadTextInputDismissed_t,
//             GetEnteredGamepadTextInput has the text, and api->submit_text hands it to the field.
#include <algorithm>
#include <string>
#include <vector>

#include "backend.h"

namespace steam_plugin {

namespace {

bool wanted() {
    SteamApi& s = steam();
    const bool deck = s.SteamAPI_ISteamUtils_IsSteamRunningOnSteamDeck && s.SteamAPI_ISteamUtils_IsSteamRunningOnSteamDeck(s.utils);
    const bool bigPicture = s.SteamAPI_ISteamUtils_IsSteamInBigPictureMode && s.SteamAPI_ISteamUtils_IsSteamInBigPictureMode(s.utils);
    return deck || bigPicture;
}

int rounded(float v) { return static_cast<int>(v < 0 ? v - 0.5f : v + 0.5f); }

}  // namespace

int on_text_input(const FaTextInput* in, void*) {
    Backend& b = backend();
    SteamApi& s = b.steam;
    if (!b.started || !in) return 0;
    if (!in->focused) {
        // The field lost the focus: take the floating keyboard down. The modal one covers the screen and ends by itself.
        if (b.keyboard == Backend::Keyboard::Floating && s.SteamAPI_ISteamUtils_DismissFloatingGamepadTextInput)
            s.SteamAPI_ISteamUtils_DismissFloatingGamepadTextInput(s.utils);
        if (b.keyboard == Backend::Keyboard::Floating) b.keyboard = Backend::Keyboard::None;
        return 0;
    }
    if (!wanted()) return 0;  // a desktop Steam: the game's keyboard serves the pad
    if (b.keyboard != Backend::Keyboard::None) return 1;  // already up (the player pressed A on the field again)

    if (s.SteamAPI_ISteamUtils_ShowFloatingGamepadTextInput &&
        s.SteamAPI_ISteamUtils_ShowFloatingGamepadTextInput(s.utils, in->multiline ? kFloatingMultipleLines : kFloatingSingleLine,
                                                            rounded(in->x), rounded(in->y), std::max(1, rounded(in->width)),
                                                            std::max(1, rounded(in->height)))) {
        b.keyboard = Backend::Keyboard::Floating;
        return 1;
    }
    if (s.SteamAPI_ISteamUtils_ShowGamepadTextInput &&
        s.SteamAPI_ISteamUtils_ShowGamepadTextInput(s.utils, in->password ? kTextInputPassword : kTextInputNormal,
                                                    in->multiline ? kTextLineMultiple : kTextLineSingle, "Enter text",
                                                    in->max_length > 0 ? static_cast<u32>(in->max_length) : 256u,
                                                    in->text ? in->text : "")) {
        b.keyboard = Backend::Keyboard::Modal;
        return 1;
    }
    warn_once("textinput", "Steam did not open a keyboard (ShowFloatingGamepadTextInput and ShowGamepadTextInput both refused): "
                           "the game's own on-screen keyboard is used.");
    return 0;
}

void text_input_dismissed(const GamepadTextInputDismissed& result) {
    Backend& b = backend();
    SteamApi& s = b.steam;
    if (b.keyboard == Backend::Keyboard::Modal) b.keyboard = Backend::Keyboard::None;
    if (!result.submitted || !s.SteamAPI_ISteamUtils_GetEnteredGamepadTextLength || !s.SteamAPI_ISteamUtils_GetEnteredGamepadTextInput) return;
    const u32 length = s.SteamAPI_ISteamUtils_GetEnteredGamepadTextLength(s.utils);  // bytes, with the terminating zero
    std::vector<char> text(static_cast<std::size_t>(length) + 1, '\0');
    if (!s.SteamAPI_ISteamUtils_GetEnteredGamepadTextInput(s.utils, text.data(), static_cast<u32>(text.size()))) return;
    text.back() = '\0';
    if (b.api && b.api->submit_text) b.api->submit_text(b.api, text.data());
}

void floating_text_input_dismissed() {
    Backend& b = backend();
    if (b.keyboard == Backend::Keyboard::Floating) b.keyboard = Backend::Keyboard::None;
}

}  // namespace steam_plugin
