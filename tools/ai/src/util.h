// Private helpers (not installed).
#pragma once

#include <cctype>
#include <string>
#include <string_view>

#include "fa/core/json.h"

namespace fa::ai::util {

// Safe JSON accessors: never throw on type mismatch.
inline std::string str(const Json& j, const char* key, std::string def = {}) {
    if (!j.is_object()) return def;
    auto it = j.find(key);
    return (it != j.end() && it->is_string()) ? it->get<std::string>() : def;
}
inline double num(const Json& j, const char* key, double def = 0) {
    if (!j.is_object()) return def;
    auto it = j.find(key);
    return (it != j.end() && it->is_number()) ? it->get<double>() : def;
}
inline bool flag(const Json& j, const char* key, bool def = false) {
    if (!j.is_object()) return def;
    auto it = j.find(key);
    return (it != j.end() && it->is_boolean()) ? it->get<bool>() : def;
}
inline const Json* child(const Json& j, const char* key) {
    if (!j.is_object()) return nullptr;
    auto it = j.find(key);
    return it == j.end() ? nullptr : &*it;
}

// Compact dump that never throws on invalid UTF-8.
inline std::string dump(const Json& j) { return j.dump(-1, ' ', false, Json::error_handler_t::replace); }
inline std::string dump_pretty(const Json& j, int indent = 2) {
    return j.dump(indent, ' ', false, Json::error_handler_t::replace);
}
// Non-throwing parse; returns discarded value on error.
inline Json parse(std::string_view text) { return Json::parse(text.begin(), text.end(), nullptr, false); }

inline std::string lower(std::string s) {
    for (auto& c : s) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return s;
}
inline bool contains(std::string_view s, std::string_view needle) { return s.find(needle) != std::string_view::npos; }

}  // namespace fa::ai::util
