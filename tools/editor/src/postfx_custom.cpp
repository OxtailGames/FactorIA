#include "postfx_custom.h"

#include <utility>
#include <vector>

namespace fa::editor {

namespace {

// The entries of `list` as a vector (a value that is not an array is no entries).
std::vector<Json> entries_of(const Json& list) {
    std::vector<Json> out;
    if (list.is_array())
        for (std::size_t i = 0; i < list.size(); ++i) out.push_back(list[i]);
    return out;
}

Json array_of(std::vector<Json> entries) {
    Json out = Json::array();
    for (Json& e : entries) out.push_back(std::move(e));
    return out;
}

}  // namespace

Json custom_pass_add(const Json& list, const std::string& material) {
    std::vector<Json> entries = entries_of(list);
    entries.push_back(Json::object({{"material", material}, {"position", "before:tonemap"}, {"enabled", true}}));
    return array_of(std::move(entries));
}

Json custom_pass_move(const Json& list, std::size_t index, int delta) {
    std::vector<Json> entries = entries_of(list);
    if (index >= entries.size() || delta == 0) return array_of(std::move(entries));
    const long long target = static_cast<long long>(index) + delta;
    if (target < 0 || target >= static_cast<long long>(entries.size())) return array_of(std::move(entries));
    std::swap(entries[index], entries[std::size_t(target)]);
    return array_of(std::move(entries));
}

Json custom_pass_remove(const Json& list, std::size_t index) {
    std::vector<Json> entries = entries_of(list);
    if (index < entries.size()) entries.erase(entries.begin() + static_cast<std::ptrdiff_t>(index));
    return array_of(std::move(entries));
}

Json custom_pass_set(const Json& list, std::size_t index, const std::string& key, const Json& value) {
    std::vector<Json> entries = entries_of(list);
    if (index >= entries.size() || !entries[index].is_object()) return array_of(std::move(entries));
    Json& e = entries[index];
    if (value.is_null()) {
        if (e.contains(key)) e.erase(key);
    } else {
        e[key] = value;
    }
    if (key == "material" && e.contains("materialParams")) e.erase("materialParams");
    return array_of(std::move(entries));
}

Json custom_pass_set_param(const Json& list, std::size_t index, const std::string& name, const Json& value) {
    std::vector<Json> entries = entries_of(list);
    if (index >= entries.size() || !entries[index].is_object()) return array_of(std::move(entries));
    Json& e = entries[index];
    Json params =
        e.contains("materialParams") && e["materialParams"].is_object() ? e["materialParams"] : Json::object();
    if (value.is_null()) {
        if (params.contains(name)) params.erase(name);
    } else {
        params[name] = value;
    }
    if (params.empty()) {
        if (e.contains("materialParams")) e.erase("materialParams");
    } else {
        e["materialParams"] = std::move(params);
    }
    return array_of(std::move(entries));
}

std::string custom_pass_label(const Json& entry) {
    if (!entry.is_object()) return "(no material)";
    if (entry.contains("name") && entry["name"].is_string() && !entry["name"].get<std::string>().empty())
        return entry["name"].get<std::string>();
    std::string m =
        entry.contains("material") && entry["material"].is_string() ? entry["material"].get<std::string>() : "";
    if (m.empty()) return "(no material)";
    const std::size_t slash = m.find_last_of('/');
    if (slash != std::string::npos) m.erase(0, slash + 1);
    const std::string ext = ".material.json";
    if (m.size() > ext.size() && m.compare(m.size() - ext.size(), ext.size(), ext) == 0) m.erase(m.size() - ext.size());
    return m;
}

}  // namespace fa::editor
