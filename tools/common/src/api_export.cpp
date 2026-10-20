#include "fa/tooling/api_export.h"

#include <algorithm>
#include <sstream>

#include "fa/core/reflect.h"
#include "fa/scene/components.h"
#include "fa/script/script.h"
#include "fa/tooling/bundle.h"
#include "util.h"

namespace fa {

namespace {
std::string md_escape(std::string s) {
    std::string out;
    for (char c : s) {
        if (c == '|') out += "\\|";
        else if (c == '\n') out += ' ';
        else out += c;
    }
    return out;
}
std::string short_json(const Json& j) { return j.dump(); }

const Json& since_data() {
    static const Json data = [] {
        auto text = bundled_read(kApiSincePath);
        Json j = text ? Json::parse(*text, nullptr, false) : Json();
        return j.is_object() ? j : Json::object();
    }();
    return data;
}

// "Since 0.1.3." for the line under a heading; "" for 0.1.0 and for things without an entry.
std::string since_line(const std::string& since) {
    if (since.empty() || since == "0.1.0") return {};
    return api_since_label(since) + ".";
}
}  // namespace

std::string api_since(std::string_view section, std::string_view key) {
    const Json& d = since_data();
    auto s = d.find(std::string(section));
    if (s == d.end() || !s->is_object()) return {};
    auto v = s->find(std::string(key));
    return v != s->end() && v->is_string() ? v->get<std::string>() : std::string();
}

std::string api_since_label(const std::string& since) {
    if (since == "unreleased") return "Not released yet (on main after " FA_ENGINE_VERSION ")";
    return "Since " + since;
}

Json export_components_json() {
    ensure_builtin_components();
    Json all = TypeRegistry::global().describe_all();
    for (Json& t : all) {
        std::string name = t.value("name", "");
        std::string since = api_since("components", name);
        if (!since.empty()) t["since"] = since;
        for (Json& f : t["fields"]) {
            std::string fs = api_since("components", name + "." + f.value("name", ""));
            if (!fs.empty()) f["since"] = fs;
        }
    }
    return all;
}

std::string export_typescript(const ScriptSystem& scripts) {
    return scripts.typescript_declarations([](const std::string& key) {
        std::string v = api_since("components", key);
        return v == "0.1.0" ? std::string() : v;
    });
}

std::string export_components_markdown() {
    Json all = export_components_json();
    std::ostringstream o;
    o << "# Components reference\n\n"
      << "Generated from the engine's reflection data. Version marks: a component added after 0.1.0 has a "
         "\"Since 0.1.x.\" line under its heading, and a field added later than its component ends with "
         "\"(since 0.1.x)\"; \"Not released yet\" means it is only on the main branch, in no download. Nothing is printed "
         "for what existed in 0.1.0; if your factoria is older than a mark, that item is missing there. "
         "In scene JSON a component is `\"Name\": { field: value, ... }` "
         "(omitted fields keep their defaults); in scripts use `entity.get(\"Name\")`. Vectors accept `[x, y]` or `{x, y}`; "
         "colors accept `[r, g, b, a]` (0..1) or `\"#rrggbb\"`.\n\n";
    std::string lastCategory;
    for (const auto& t : all) {
        std::string cat = t.value("category", "");
        if (cat != lastCategory) { o << "## " << cat << "\n\n"; lastCategory = cat; }
        const std::string compSince = t.value("since", "");
        o << "### " << t.value("name", "") << "\n\n";
        if (!since_line(compSince).empty()) o << since_line(compSince) << "\n\n";
        o << t.value("doc", "") << "\n\n";
        if (t["fields"].empty()) { o << "_No fields._\n\n"; continue; }
        o << "| Field | Type | Default | Description |\n|---|---|---|---|\n";
        for (const auto& f : t["fields"]) {
            std::string type = f.value("kind", "");
            if (f.contains("enum")) {
                type = "enum: ";
                bool first = true;
                for (const auto& e : f["enum"]) { type += (first ? "" : " \\| ") + e.get<std::string>(); first = false; }
            }
            if (f.contains("assetType")) type += " (" + f["assetType"].get<std::string>() + ")";
            std::string desc = f.value("doc", "");
            if (f.contains("min")) desc += " Range " + short_json(f["min"]) + ".." + short_json(f["max"]) + ".";
            if (f.value("readOnly", false)) desc += " Read-only.";
            if (f.value("runtimeOnly", false)) desc += " Runtime-only (not saved).";
            const std::string fieldSince = f.value("since", "");
            if (!fieldSince.empty() && fieldSince != compSince && fieldSince != "0.1.0")
                desc += fieldSince == "unreleased" ? " (not released yet, on main after " FA_ENGINE_VERSION ")" : " (since " + fieldSince + ")";
            o << "| `" << f.value("name", "") << "` | " << md_escape(type) << " | "
              << (f.contains("default") ? "`" + md_escape(short_json(f["default"])) + "`" : "") << " | " << md_escape(desc) << " |\n";
        }
        o << "\n";
    }
    return o.str();
}

Json export_commands_json(const CommandRegistry& registry) {
    Json all = registry.describe();
    for (Json& c : all) {
        std::string since = api_since("commands", c.value("name", ""));
        if (!since.empty()) c["since"] = since;
    }
    return all;
}

std::string export_commands_markdown(const CommandRegistry& registry) {
    std::ostringstream o;
    o << "# Commands reference\n\n"
      << "Every command is a CLI call (`factoria call <name> '<json>'`), an MCP tool (dots become underscores) and a "
         "script function (`fa.call(name, args)`).\n\n";
    std::string lastCategory = "\x01";
    for (const CommandInfo* c : registry.list()) {
        if (c->category != lastCategory) {
            lastCategory = c->category;
            o << "## " << (lastCategory.empty() ? "general" : lastCategory) << "\n\n";
        }
        o << "### `" << c->name << "`" << (c->readOnly ? "" : " (modifies state)") << "\n\n";
        const std::string since = since_line(api_since("commands", c->name));
        if (!since.empty()) o << since << "\n\n";
        o << c->summary << "\n\n";
        if (!c->description.empty()) o << c->description << "\n\n";
        const Json& props = c->inputSchema.contains("properties") ? c->inputSchema["properties"] : Json::object();
        if (props.is_object() && !props.empty()) {
            std::vector<std::string> required;
            if (c->inputSchema.contains("required"))
                for (const auto& r : c->inputSchema["required"]) required.push_back(r.get<std::string>());
            o << "| Argument | Type | Required | Description |\n|---|---|---|---|\n";
            for (auto it = props.begin(); it != props.end(); ++it) {
                const Json& p = it.value();
                std::string type = p.contains("type") && p["type"].is_string() ? p["type"].get<std::string>() : "any";
                if (p.contains("enum")) type += " " + short_json(p["enum"]);
                bool req = std::find(required.begin(), required.end(), it.key()) != required.end();
                std::string desc = p.value("description", "");
                if (p.contains("default")) desc += " Default " + short_json(p["default"]) + ".";
                o << "| `" << it.key() << "` | " << md_escape(type) << " | " << (req ? "yes" : "no") << " | " << md_escape(desc) << " |\n";
            }
            o << "\n";
        }
    }
    return o.str();
}

void register_api_export_commands(CommandRegistry& registry) {
    auto fmt_schema = [] {
        return Json::object({{"type", "object"},
            {"properties", Json::object({{"format", Json::object({{"type", "string"}, {"enum", Json::array({"markdown", "json"})},
                                                                  {"default", "markdown"}, {"description", "Output format."}})}})}});
    };
    {
        CommandInfo info;
        info.name = "docs.components";
        info.category = "docs";
        info.summary = "Reference of every component and field (types, defaults, docs).";
        info.description = "Generated from the engine's reflection data; always accurate for this build. Use before writing scene JSON.";
        info.inputSchema = fmt_schema();
        registry.add(info, [](const Json& args) {
            if (tooling_detail::arg_string(args, "format", false, "markdown") == "json")
                return Json::object({{"components", export_components_json()}});
            return Json::object({{"markdown", export_components_markdown()}});
        });
    }
    {
        CommandInfo info;
        info.name = "docs.commands";
        info.category = "docs";
        info.summary = "Reference of every available command (tool) with arguments.";
        info.description = "Lists the commands of this session, including project tools from tools/*.js.";
        info.inputSchema = fmt_schema();
        registry.add(info, [&registry](const Json& args) {
            if (tooling_detail::arg_string(args, "format", false, "markdown") == "json")
                return Json::object({{"commands", export_commands_json(registry)}});
            return Json::object({{"markdown", export_commands_markdown(registry)}});
        });
    }
}

}  // namespace fa
