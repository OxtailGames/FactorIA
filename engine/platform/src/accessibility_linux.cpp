// Linux: GNOME's settings through the `gsettings` program (no library is linked: the Steam Runtime build stays as it is).
// Without gsettings, or on a desktop that does not keep these keys in GSettings (KDE, Xfce...), the answer is the default.
#include <cstdio>
#include <string>

#include "fa/platform/accessibility.h"

namespace fa {

namespace {
// `gsettings get schema key`, or "" when the program or the key does not exist.
std::string gsettings_get(const char* schema, const char* key) {
    const std::string command = std::string("gsettings get ") + schema + " " + key + " 2>/dev/null";
    FILE* pipe = popen(command.c_str(), "r");
    if (!pipe) return {};
    std::string out;
    char buffer[128];
    while (std::fgets(buffer, sizeof buffer, pipe)) out += buffer;
    pclose(pipe);
    return out;
}
}  // namespace

AccessibilitySettings read_system_accessibility() {
    AccessibilitySettings s;
    if (auto v = parse_gsettings_number(gsettings_get("org.gnome.desktop.interface", "text-scaling-factor")))
        s.textScale = static_cast<float>(*v);
    if (auto v = parse_gsettings_bool(gsettings_get("org.gnome.desktop.interface", "enable-animations"))) s.reduceMotion = !*v;
    if (auto v = parse_gsettings_bool(gsettings_get("org.gnome.desktop.a11y.interface", "high-contrast"))) s.highContrast = *v;
    if (auto v = parse_gsettings_bool(gsettings_get("org.gnome.desktop.a11y.applications", "screen-reader-enabled")))
        s.screenReader = *v;
    return s;
}

}  // namespace fa
