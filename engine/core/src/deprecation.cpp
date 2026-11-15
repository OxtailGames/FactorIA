#include "fa/core/deprecation.h"

#include <cctype>
#include <cstdlib>

#include "fa/core/log.h"

namespace fa {

namespace {
// "0.30.2" -> {0, 30}; false for anything else (a version of exactly three numbers).
bool parse_version(std::string_view v, long& major, long& minor) {
    long parts[3] = {0, 0, 0};
    int n = 0;
    std::size_t i = 0;
    while (i < v.size() && n < 3) {
        std::size_t start = i;
        while (i < v.size() && std::isdigit(static_cast<unsigned char>(v[i]))) ++i;
        if (i == start || i - start > 6) return false;
        parts[n++] = std::strtol(std::string(v.substr(start, i - start)).c_str(), nullptr, 10);
        if (i < v.size()) {
            if (v[i] != '.' || n == 3) return false;
            ++i;
        }
    }
    if (n != 3 || i != v.size()) return false;
    major = parts[0];
    minor = parts[1];
    return true;
}

std::string kind_label(std::string_view kind) {
    if (kind == kDeprecatedCommands) return "command";
    if (kind == kDeprecatedScript) return "script API";
    return "component";  // "component 'Sprite'" or "component field 'Sprite.oldField'", see deprecation_message
}
}  // namespace

std::string deprecation_removal_version(std::string_view since) {
    long major = 0, minor = 0;
    if (!parse_version(since, major, minor)) return {};
    return std::to_string(major) + "." + std::to_string(minor + 2) + ".0";
}

std::string deprecation_summary(const Deprecation& d) {
    std::string out = d.since == "unreleased" ? "Deprecated before its first release" : "Deprecated since " + d.since;
    out += d.use.empty() ? " - no replacement" : " - use `" + d.use + "`";
    const std::string removal = deprecation_removal_version(d.since);
    out += removal.empty() ? ". Removed two minor versions after the release that ships it." : ". Removed in " + removal + ".";
    return out;
}

std::string deprecation_message(std::string_view kind, std::string_view key, const Deprecation& d) {
    std::string what = kind_label(kind);
    if (kind == kDeprecatedComponents && key.find('.') != std::string_view::npos) what += " field";
    std::string out = "Deprecated: " + what + " '" + std::string(key) + "' (" +
                      (d.since == "unreleased" ? "deprecated before its first release" : "since " + d.since) + ")";
    const std::string removal = deprecation_removal_version(d.since);
    out += removal.empty() ? " will be removed two minor versions after the release that ships it."
                           : " will be removed in " + removal + ".";
    out += d.use.empty() ? " It has no replacement." : " Use '" + d.use + "' instead.";
    if (!d.note.empty()) out += " " + d.note;
    return out;
}

Deprecations& Deprecations::global() {
    static Deprecations instance;
    return instance;
}

void Deprecations::set(const Json& section) {
    std::map<std::string, std::map<std::string, Deprecation, std::less<>>, std::less<>> table;
    bool any = false;
    if (section.is_object()) {
        for (auto kind = section.begin(); kind != section.end(); ++kind) {
            if (!kind.value().is_object()) continue;
            for (auto it = kind.value().begin(); it != kind.value().end(); ++it) {
                if (!it.value().is_object()) continue;
                Deprecation d;
                d.since = it.value().value("since", "");
                d.use = it.value().value("use", "");
                d.note = it.value().value("note", "");
                table[kind.key()][it.key()] = std::move(d);
                any = true;
            }
        }
    }
    std::lock_guard<std::mutex> lock(mutex_);
    table_ = std::move(table);
    warned_.clear();
    empty_.store(!any, std::memory_order_relaxed);
}

void Deprecations::clear() { set(Json::object()); }

std::optional<Deprecation> Deprecations::find(std::string_view kind, std::string_view key) const {
    std::lock_guard<std::mutex> lock(mutex_);
    auto k = table_.find(kind);
    if (k == table_.end()) return std::nullopt;
    auto it = k->second.find(key);
    if (it == k->second.end()) return std::nullopt;
    return it->second;
}

std::vector<std::string> Deprecations::keys(std::string_view kind) const {
    std::lock_guard<std::mutex> lock(mutex_);
    std::vector<std::string> out;
    auto k = table_.find(kind);
    if (k != table_.end())
        for (const auto& [key, d] : k->second) out.push_back(key);
    return out;
}

std::string Deprecations::take_warning(std::string_view kind, std::string_view key) {
    if (empty()) return {};
    std::lock_guard<std::mutex> lock(mutex_);
    auto k = table_.find(kind);
    if (k == table_.end()) return {};
    auto it = k->second.find(key);
    if (it == k->second.end()) return {};
    if (!warned_.insert(std::string(kind) + "\n" + std::string(key)).second) return {};
    return deprecation_message(kind, key, it->second);
}

void Deprecations::reset_warned() {
    std::lock_guard<std::mutex> lock(mutex_);
    warned_.clear();
}

bool warn_deprecated(std::string_view kind, std::string_view key) {
    std::string text = Deprecations::global().take_warning(kind, key);
    if (text.empty()) return false;
    log(LogLevel::Warn, "deprecated", text);
    return true;
}

}  // namespace fa
