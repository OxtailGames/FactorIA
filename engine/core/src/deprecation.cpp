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

// The row of the Bloom filters of a kind.
int bloom_slot(std::string_view kind) {
    if (kind == kDeprecatedCommands) return 0;
    if (kind == kDeprecatedComponents) return 1;
    if (kind == kDeprecatedScript) return 2;
    return 3;
}

// A component is filtered by its name alone, so "Sprite" and "Sprite.oldField" both set the bits of "Sprite".
std::string_view bloom_key(std::string_view kind, std::string_view key) {
    if (kind == kDeprecatedComponents) key = key.substr(0, key.find('.'));
    return key;
}

std::uint64_t fnv1a(std::string_view s) {
    std::uint64_t h = 1469598103934665603ull;
    for (char c : s) h = (h ^ static_cast<unsigned char>(c)) * 1099511628211ull;
    return h;
}

constexpr unsigned kBloomBits = 512;  // 8 words of 64 bits
// The two bit positions of a key.
void bloom_bits(std::uint64_t h, unsigned& a, unsigned& b) {
    a = static_cast<unsigned>(h % kBloomBits);
    b = static_cast<unsigned>((h >> 24) % kBloomBits);
}
}  // namespace

std::string deprecation_removal_version(std::string_view since) {
    long major = 0, minor = 0;
    if (!parse_version(since, major, minor)) return {};
    return std::to_string(major) + "." + std::to_string(minor + 2) + ".0";
}

std::string removed_field_hint(std::string_view component, std::string_view field) {
    struct Removed {
        std::string_view component, field, text;
    };
    // The six Camera post-processing fields (deprecated in 0.31.0): the PostProcess component has them all.
    constexpr std::string_view kBloom =
        "add a PostProcess component to the camera's entity and set bloomEnabled (and "
        "bloomIntensity/bloomThreshold/bloomRadius/bloomScreenSpace/colorFilter there).";
    static const Removed kRemoved[] = {
        {"Camera", "bloom", kBloom},
        {"Camera", "bloomIntensity", kBloom},
        {"Camera", "bloomRadius", kBloom},
        {"Camera", "bloomScreenSpace", kBloom},
        {"Camera", "bloomThreshold", kBloom},
        {"Camera", "colorFilter",
         "add a PostProcess component to the camera's entity, set colorFilterEnabled to true and colorFilterMode to "
         "the filter (none, greyscale, highContrast, protanopia, deuteranopia, tritanopia)."},
    };
    // The field name is compared without regard to case: a scene that says "Bloom" meant the removed field too.
    auto same_field = [](std::string_view a, std::string_view b) {
        if (a.size() != b.size()) return false;
        for (std::size_t i = 0; i < a.size(); ++i)
            if (std::tolower(static_cast<unsigned char>(a[i])) != std::tolower(static_cast<unsigned char>(b[i])))
                return false;
        return true;
    };
    for (const Removed& r : kRemoved)
        if (r.component == component && same_field(r.field, field))
            return std::string(component) + "." + std::string(r.field) +
                   " was removed in 0.33.0: " + std::string(r.text);
    return {};
}

std::string deprecation_summary(const Deprecation& d) {
    std::string out = d.since == "unreleased" ? "Deprecated before its first release" : "Deprecated since " + d.since;
    out += d.use.empty() ? " - no replacement" : " - use `" + d.use + "`";
    const std::string removal = deprecation_removal_version(d.since);
    out += removal.empty() ? ". Removed two minor versions after the release that ships it."
                           : ". Removed in " + removal + ".";
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
    std::uint64_t bloom[4][kBloomWords] = {};
    if (section.is_object()) {
        for (auto kind = section.begin(); kind != section.end(); ++kind) {
            if (!kind.value().is_object()) continue;
            for (auto it = kind.value().begin(); it != kind.value().end(); ++it) {
                if (!it.value().is_object()) continue;
                Deprecation d;
                d.since = it.value().value("since", "");
                d.use = it.value().value("use", "");
                d.note = it.value().value("note", "");
                unsigned a = 0, b = 0;
                bloom_bits(fnv1a(bloom_key(kind.key(), it.key())), a, b);
                std::uint64_t* row = bloom[bloom_slot(kind.key())];
                row[a / 64] |= std::uint64_t{1} << (a % 64);
                row[b / 64] |= std::uint64_t{1} << (b % 64);
                table[kind.key()][it.key()] = std::move(d);
                any = true;
            }
        }
    }
    std::lock_guard<std::mutex> lock(mutex_);
    table_ = std::move(table);
    warned_.clear();
    for (int k = 0; k < 4; ++k)
        for (int w = 0; w < kBloomWords; ++w) bloom_[k][w].store(bloom[k][w], std::memory_order_relaxed);
    // Release: a reader that sees the table as not empty (acquire) also sees the Bloom words written above.
    empty_.store(!any, std::memory_order_release);
}

void Deprecations::clear() { set(Json::object()); }

bool Deprecations::may_contain(std::string_view kind, std::string_view key) const noexcept {
    if (empty()) return false;
    unsigned a = 0, b = 0;
    bloom_bits(fnv1a(bloom_key(kind, key)), a, b);
    const auto* row = bloom_[bloom_slot(kind)];
    return (row[a / 64].load(std::memory_order_relaxed) >> (a % 64) & 1) &&
           (row[b / 64].load(std::memory_order_relaxed) >> (b % 64) & 1);
}

bool Deprecations::may_contain_component(std::string_view component) const noexcept {
    return may_contain(kDeprecatedComponents, component);
}

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
    if (!may_contain(kind, key)) return {};  // the common call: not deprecated, no lock
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
