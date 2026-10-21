#include "fa/platform/accessibility.h"

#include <cmath>
#include <cstdlib>
#include <string>

namespace fa {

AccessibilitySettings sanitize_accessibility(AccessibilitySettings s) {
    if (!std::isfinite(s.textScale)) s.textScale = 1.0f;
    if (s.textScale < kMinSystemTextScale) s.textScale = kMinSystemTextScale;
    if (s.textScale > kMaxSystemTextScale) s.textScale = kMaxSystemTextScale;
    return s;
}

namespace {
AccessibilitySettings g_current;
bool g_read = false;

std::string_view trim(std::string_view t) {
    const auto space = [](char c) { return c == ' ' || c == '\n' || c == '\r' || c == '\t'; };
    while (!t.empty() && space(t.front())) t.remove_prefix(1);
    while (!t.empty() && space(t.back())) t.remove_suffix(1);
    return t;
}
}  // namespace

AccessibilitySettings system_accessibility() {
    if (!g_read) refresh_system_accessibility();
    return g_current;
}

void refresh_system_accessibility() {
    g_current = sanitize_accessibility(read_system_accessibility());
    g_read = true;
}

std::optional<bool> parse_gsettings_bool(std::string_view text) {
    text = trim(text);
    if (text == "true") return true;
    if (text == "false") return false;
    return std::nullopt;
}

std::optional<double> parse_gsettings_number(std::string_view text) {
    text = trim(text);
    if (text.rfind("uint32 ", 0) == 0 || text.rfind("int32 ", 0) == 0) text = trim(text.substr(text.find(' ')));
    if (text.empty()) return std::nullopt;
    const std::string s(text);
    char* end = nullptr;
    const double v = std::strtod(s.c_str(), &end);
    if (end != s.c_str() + s.size() || !std::isfinite(v)) return std::nullopt;
    return v;
}

}  // namespace fa
