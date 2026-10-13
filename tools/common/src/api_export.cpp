#include "fa/tooling/api_export.h"

#include <algorithm>
#include <sstream>

#include "fa/core/reflect.h"
#include "fa/scene/components.h"
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
}  // namespace

Json export_components_json() {
    ensure_builtin_components();
    return TypeRegistry::global().describe_all();
}

std::string export_components_markdown() {
    Json all = export_components_json();
    std::ostringstream o;
    o << "# Components reference\n\n"
      << "Generated from the engine's reflection data. In scene JSON a component is `\"Name\": { field: value, ... }` "
         "(omitted fields keep their defaults); in scripts use `entity.get(\"Name\")`. Vectors accept `[x, y]` or `{x, y}`; "
         "colors accept `[r, g, b, a]` (0..1) or `\"#rrggbb\"`.\n\n";
    std::string lastCategory;
    for (const auto& t : all) {
        std::string cat = t.value("category", "");
        if (cat != lastCategory) { o << "## " << cat << "\n\n"; lastCategory = cat; }
        o << "### " << t.value("name", "") << "\n\n" << t.value("doc", "") << "\n\n";
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
            o << "| `" << f.value("name", "") << "` | " << md_escape(type) << " | "
              << (f.contains("default") ? "`" + md_escape(short_json(f["default"])) + "`" : "") << " | " << md_escape(desc) << " |\n";
        }
        o << "\n";
    }
    return o.str();
}

Json export_commands_json(const CommandRegistry& registry) { return registry.describe(); }

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
        o << "### `" << c->name << "`" << (c->readOnly ? "" : " (modifies state)") << "\n\n" << c->summary << "\n\n";
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
