// The operating system's accessibility settings, for a game to start its own options from (`game.accessibility`).
//
//   textScale     the system text size: 1 = 100 %.
//   reduceMotion  the player asked for less animation.
//   highContrast  the player asked for more contrast.
//   screenReader  a screen reader (or touch exploration) is running.
//
// What each platform reads (anything it cannot read stays at the default 1 / false):
//   Windows    SPI_GETCLIENTAREAANIMATION (off = reduceMotion), SPI_GETHIGHCONTRAST, SPI_GETSCREENREADER, and
//              HKCU\SOFTWARE\Microsoft\Accessibility\TextScaleFactor (100-225; missing = 100).
//   macOS      NSWorkspace accessibilityDisplayShouldReduceMotion / ...IncreaseContrast, isVoiceOverEnabled. Text size 1.
//   iOS        UIAccessibilityIsReduceMotionEnabled / DarkerSystemColorsEnabled / IsVoiceOverRunning, and the Dynamic Type
//              size (UIFontMetrics) for textScale.
//   Android    Configuration.fontScale, Settings.Global animator_duration_scale == 0, Settings.Secure
//              high_text_contrast_enabled, AccessibilityManager.isTouchExplorationEnabled. Through JNI.
//   Linux      GNOME settings through the `gsettings` program when it exists (text-scaling-factor, enable-animations,
//              a11y high-contrast, a11y screen-reader-enabled). KDE and other desktops (or no gsettings) give the defaults.
//   web        matchMedia: prefers-reduced-motion, prefers-contrast: more / forced-colors: active. Browsers do not tell
//              the text size or a screen reader: 1 and false.
//
// Headless runs, tests and the editor never read the system (see script_natives.cpp): they give the defaults, so that
// output does not depend on the machine.
#pragma once

#include <optional>
#include <string_view>

namespace fa {

struct AccessibilitySettings {
    float textScale = 1.0f;
    bool reduceMotion = false;
    bool highContrast = false;
    bool screenReader = false;
};

// The smallest and largest textScale a game ever sees (a broken value from the system must not break layouts).
constexpr float kMinSystemTextScale = 0.5f;
constexpr float kMaxSystemTextScale = 4.0f;

// Clamps textScale to [kMinSystemTextScale, kMaxSystemTextScale]; NaN and infinity give 1.
AccessibilitySettings sanitize_accessibility(AccessibilitySettings s);

// Reads the settings now, from the system of this platform (one file per platform).
AccessibilitySettings read_system_accessibility();

// The settings read at the first call, and read again by refresh_system_accessibility() (the window regained focus or the
// app resumed: the player may have changed a setting meanwhile). Always sanitized.
AccessibilitySettings system_accessibility();
void refresh_system_accessibility();

// The text a `gsettings get` prints: "true", "false", "1.25", "uint32 3". nullopt when it is not that type.
std::optional<bool> parse_gsettings_bool(std::string_view text);
std::optional<double> parse_gsettings_number(std::string_view text);

}  // namespace fa
