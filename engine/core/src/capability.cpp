#include "fa/core/capability.h"

#include <array>

#include "fa/core/strings.h"

namespace fa {
namespace {

struct CapabilityRow {
    Capability capability;
    const char* name;
    const char* doc;
};

constexpr std::array<CapabilityRow, kCapabilityCount> kRows{{
    {Capability::Read, "read", "reads project or engine state"},
    {Capability::State, "state", "changes the running game or the open scene in memory only, writes no file"},
    {Capability::WriteProject, "writeProject", "writes files inside the project"},
    {Capability::WriteAnywhere, "writeAnywhere", "writes outside the project (absolute paths, the user's folders and settings)"},
    {Capability::Network, "network", "talks to a remote service"},
    {Capability::Process, "process", "starts an external program"},
    {Capability::Spend, "spend", "can cost money (paid APIs, store fees)"},
    {Capability::Publish, "publish", "makes something public or uploads a build to a store"},
}};

Error unknown_capability(std::string_view name, const std::string& where) {
    const std::vector<std::string> valid = capability_names();
    std::string message = "Unknown capability '" + std::string(name) + "'";
    if (!where.empty()) message += " at " + where;
    message += ".";
    return make_error(std::move(message), did_you_mean(name, valid) + " Names are camelCase, e.g. \"writeProject\".");
}

}  // namespace

const char* capability_name(Capability c) { return kRows[static_cast<std::size_t>(c)].name; }

const char* capability_doc(Capability c) { return kRows[static_cast<std::size_t>(c)].doc; }

std::optional<Capability> capability_from_name(std::string_view name) {
    for (const CapabilityRow& r : kRows)
        if (name == r.name) return r.capability;
    return std::nullopt;
}

std::vector<std::string> capability_names() {
    std::vector<std::string> out;
    for (const CapabilityRow& r : kRows) out.emplace_back(r.name);
    return out;
}

std::vector<std::string> CapabilitySet::names() const {
    std::vector<std::string> out;
    for (const CapabilityRow& r : kRows)
        if (has(r.capability)) out.emplace_back(r.name);
    return out;
}

Json CapabilitySet::to_json() const {
    Json arr = Json::array();
    for (const std::string& n : names()) arr.push_back(n);
    return arr;
}

std::string CapabilitySet::to_string() const {
    std::string out = "{";
    bool first = true;
    for (const std::string& n : names()) {
        if (!first) out += ", ";
        out += n;
        first = false;
    }
    return out + "}";
}

Result<CapabilitySet> CapabilitySet::parse(const Json& json, std::string_view pointer) {
    CapabilitySet set;
    const std::string base(pointer);
    if (json.is_string()) {
        const std::string name = json.get<std::string>();
        const std::optional<Capability> c = capability_from_name(name);
        if (!c) return unknown_capability(name, base.empty() ? std::string("/") : base);
        return set.with(*c);
    }
    if (!json.is_array())
        return make_error("Capabilities at " + (base.empty() ? std::string("/") : base) + " must be an array of names, e.g. [\"read\", \"state\"].",
                          "Valid names: " + CapabilitySet::all().to_string() + ".");
    for (std::size_t i = 0; i < json.size(); ++i) {
        const std::string at = base + "/" + std::to_string(i);
        if (!json[i].is_string())
            return make_error("Capability at " + at + " must be a string.", "Use a name like \"read\" or \"writeProject\".");
        const std::string name = json[i].get<std::string>();
        const std::optional<Capability> c = capability_from_name(name);
        if (!c) return unknown_capability(name, at);
        set = set.with(*c);
    }
    return set;
}

Result<CapabilitySet> CapabilitySet::parse_list(std::string_view text) {
    CapabilitySet set;
    std::size_t i = 0;
    const auto is_sep = [](char ch) { return ch == ',' || ch == ' ' || ch == '\t'; };
    while (i < text.size()) {
        while (i < text.size() && is_sep(text[i])) ++i;
        const std::size_t start = i;
        while (i < text.size() && !is_sep(text[i])) ++i;
        if (i == start) break;
        const std::string_view name = text.substr(start, i - start);
        const std::optional<Capability> c = capability_from_name(name);
        if (!c) return unknown_capability(name, {});
        set = set.with(*c);
    }
    return set;
}

}  // namespace fa
