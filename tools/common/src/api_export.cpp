#include "fa/tooling/api_export.h"

#include <algorithm>
#include <filesystem>
#include <map>
#include <sstream>

#include "fa/core/reflect.h"
#include "fa/core/strings.h"
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
// One component: heading, version mark, doc and the fields table. heading is "###" in the single file reference.
void write_component(std::ostream& o, const Json& t, const char* heading) {
    const std::string compSince = t.value("since", "");
    o << heading << " " << t.value("name", "") << "\n\n";
    if (!since_line(compSince).empty()) o << since_line(compSince) << "\n\n";
    o << t.value("doc", "") << "\n\n";
    if (t["fields"].empty()) { o << "_No fields._\n\n"; return; }
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

// One command: heading, version mark, summary, description and the arguments table.
void write_command(std::ostream& o, const CommandInfo* c, const char* heading) {
    o << heading << " `" << c->name << "`" << (c->readOnly ? "" : " (modifies state)") << "\n\n";
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
    return scripts.typescript_declarations([](const std::string& section, const std::string& key) {
        std::string v = api_since(section, key);
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
         "The scripting API at the end marks its functions, types and members the same way, with a JSDoc `@since` tag. "
         "In scene JSON a component is `\"Name\": { field: value, ... }` "
         "(omitted fields keep their defaults); in scripts use `entity.get(\"Name\")`. Vectors accept `[x, y]` or `{x, y}`; "
         "colors accept `[r, g, b, a]` (0..1) or `\"#rrggbb\"`.\n\n";
    std::string lastCategory;
    for (const auto& t : all) {
        std::string cat = t.value("category", "");
        if (cat != lastCategory) { o << "## " << cat << "\n\n"; lastCategory = cat; }
        write_component(o, t, "###");
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
        write_command(o, c, "###");
    }
    return o.str();
}

namespace {
// File name of a category page: lowercase ASCII, "general" for an empty category.
std::string category_file(const std::string& category) {
    std::string out;
    for (char c : category) {
        if (c >= 'A' && c <= 'Z') c = char(c - 'A' + 'a');
        const bool ok = (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9');
        if (ok) out += c;
        else if (!out.empty() && out.back() != '-') out += '-';
    }
    while (!out.empty() && out.back() == '-') out.pop_back();
    return out.empty() ? "general" : out;
}

// GitHub's anchor for a heading: lowercase, letters digits '_' '-' kept, spaces become '-', the rest dropped.
std::string heading_anchor(const std::string& heading) {
    std::string out;
    for (char c : heading) {
        if (c >= 'A' && c <= 'Z') c = char(c - 'A' + 'a');
        if ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_' || c == '-') out += c;
        else if (c == ' ') out += '-';
    }
    return out;
}

// First sentence of a doc string, on one line, for the index.
std::string first_sentence(const std::string& doc) {
    std::string line = doc.substr(0, doc.find('\n'));
    size_t dot = line.find(". ");
    if (dot != std::string::npos) line.resize(dot + 1);
    return md_escape(line);
}

std::string index_mark(const std::string& since) {
    if (since.empty() || since == "0.1.0") return {};
    return since == "unreleased" ? " _Not released yet._" : " _" + api_since_label(since) + "._";
}
}  // namespace

std::string export_api_markdown(const CommandRegistry& registry, const ScriptSystem& scripts) {
    return export_components_markdown() + "\n" + export_commands_markdown(registry) +
           "\n## Scripting API (TypeScript declarations)\n\n```ts\n" + export_typescript(scripts) + "\n```\n";
}

std::vector<ApiReferencePage> export_api_reference(const CommandRegistry& registry, const ScriptSystem& scripts) {
    std::vector<ApiReferencePage> pages;
    pages.push_back({"COMPONENTS.md", export_api_markdown(registry, scripts)});

    // Both kinds grouped by category (sorted), items sorted by name inside a category.
    std::map<std::string, std::vector<Json>> comps;
    for (const Json& t : export_components_json()) comps[t.value("category", "")].push_back(t);
    for (auto& [cat, v] : comps)
        std::sort(v.begin(), v.end(), [](const Json& a, const Json& b) { return a.value("name", "") < b.value("name", ""); });
    std::map<std::string, std::vector<const CommandInfo*>> cmds;
    for (const CommandInfo* c : registry.list()) cmds[c->category].push_back(c);

    std::ostringstream idx;
    idx << "# API reference\n\n"
        << "Every component and every command of FactorIA, one page per category. The pages are generated from the engine itself "
           "(`factoria call docs.write_reference '{\"out\":\"docs\"}'`), so they are exact for this version; a test fails when they "
           "fall behind. The same data is available offline with `factoria api --md`, `factoria commands` and, over MCP, "
           "`docs_components` and `docs_commands`. Use your browser's find (Ctrl+F) on this page to locate anything.\n\n"
        << "Version marks: an entry added after 0.1.0 ends with \"(Since 0.1.x)\", and \"(Not released yet ...)\" means it is only "
           "on the main branch, in no download. Nothing is shown for what existed in 0.1.0. If your factoria is older than a mark, "
           "that item is missing there (`factoria --version`).\n\n"
        << "## Components\n\n";
    std::vector<ApiReferencePage> catPages;
    for (const auto& [cat, v] : comps) {
        const std::string file = "components/" + category_file(cat) + ".md";
        std::ostringstream page;
        page << "[Back to the index](../README.md)\n\n# Components: " << (cat.empty() ? "general" : cat) << "\n\n";
        idx << "### [" << (cat.empty() ? "general" : cat) << "](" << file << ")\n\n";
        for (const Json& t : v) {
            const std::string name = t.value("name", "");
            write_component(page, t, "##");
            idx << "- [" << name << "](" << file << "#" << heading_anchor(name) << "): " << first_sentence(t.value("doc", ""))
                << index_mark(t.value("since", "")) << "\n";
        }
        idx << "\n";
        catPages.push_back({"reference/" + file, page.str()});
    }
    idx << "## Commands\n\n"
        << "Every command is a CLI call (`factoria call <name> '<json>'`), an MCP tool (dots become underscores) and a script "
           "function (`fa.call(name, args)`). Commands of plugins (for example `steam.*`) and the project's own `tools/*.js` are not "
           "listed: they depend on the project.\n\n";
    for (const auto& [cat, v] : cmds) {
        const std::string file = "commands/" + category_file(cat) + ".md";
        std::ostringstream page;
        page << "[Back to the index](../README.md)\n\n# Commands: " << (cat.empty() ? "general" : cat) << "\n\n";
        idx << "### [" << (cat.empty() ? "general" : cat) << "](" << file << ")\n\n";
        for (const CommandInfo* c : v) {
            write_command(page, c, "##");
            const std::string heading = "`" + c->name + "`" + (c->readOnly ? "" : " (modifies state)");
            idx << "- [`" << c->name << "`](" << file << "#" << heading_anchor(heading) << "): " << md_escape(c->summary)
                << index_mark(api_since("commands", c->name)) << "\n";
        }
        idx << "\n";
        catPages.push_back({"reference/" + file, page.str()});
    }
    pages.push_back({"reference/README.md", idx.str()});
    for (ApiReferencePage& p : catPages) pages.push_back(std::move(p));
    return pages;
}

namespace {
// docs.components / docs.commands: no argument lists names with a one-line summary (the whole reference is over 200 KB, more than an
// MCP tool result may carry); `name` gives one entry in full, `filter` narrows the list, `full` gives everything.
Json docs_filter_schema(const char* what) {
    const std::string n = what;
    return Json::object({{"type", "object"},
        {"properties", Json::object({
            {"name", Json::object({{"type", "string"}, {"description", "Exact " + n + " name (case-insensitive): returns its full reference."}})},
            {"filter", Json::object({{"type", "string"}, {"description", "Keep the " + n + "s whose name, category or summary contains this text (case-insensitive)."}})},
            {"full", Json::object({{"type", "boolean"}, {"default", false}, {"description", "Return every " + n + " in full (over 200 KB: too large for most MCP clients; prefer name or filter)."}})},
            {"format", Json::object({{"type", "string"}, {"enum", Json::array({"markdown", "json"})}, {"default", "markdown"}, {"description", "Output format."}})}})}});
}

bool contains_ci(const std::string& hay, const std::string& needle) { return to_lower(hay).find(to_lower(needle)) != std::string::npos; }

struct Entry {
    std::string name, category, summary;
    const Json* json = nullptr;        // components
    const CommandInfo* info = nullptr;  // commands
};

Json entries_json(const std::vector<Entry>& v) {
    Json arr = Json::array();
    for (const Entry& e : v) arr.push_back(Json::object({{"name", e.name}, {"category", e.category}, {"summary", e.summary}}));
    return arr;
}

std::string entries_markdown(const std::vector<Entry>& v, const std::string& title, const std::string& tool, const std::string& example,
                             const std::string& filterNote) {
    std::ostringstream o;
    o << "# " << title << " (" << v.size() << ")\n\n" << filterNote
      << "One line per entry. Read one in full: `" << tool << " {\"name\":\"" << example << "\"}`; narrow the list with `{\"filter\":\"text\"}`; "
      << "everything at once with `{\"full\":true}` (over 200 KB).\n\n";
    std::string last = "\x01";
    for (const Entry& e : v) {
        if (e.category != last) { if (last != "\x01") o << "\n"; last = e.category; o << "## " << (last.empty() ? "general" : last) << "\n\n"; }
        o << "- `" << e.name << "`: " << e.summary << "\n";
    }
    return o.str();
}

// Picks the entries for the arguments; throws not_found (with a did-you-mean) for a `name` that does not exist.
std::vector<Entry> select_entries(const std::vector<Entry>& all, const Json& args, const char* what, const char* listTool, const Entry** exact) {
    *exact = nullptr;
    const std::string name = tooling_detail::arg_string(args, "name", false);
    if (!name.empty()) {
        for (const Entry& e : all)
            if (to_lower(e.name) == to_lower(name)) { *exact = &e; return {e}; }
        std::vector<std::string> names;
        for (const Entry& e : all) names.push_back(e.name);
        throw CommandError("not_found", std::string("There is no ") + what + " named '" + name + "'. " + did_you_mean(name, names),
                           std::string("Call ") + listTool + " {} for the list of names, or {\"filter\":\"" + name + "\"} to search.");
    }
    const std::string filter = tooling_detail::arg_string(args, "filter", false);
    std::vector<Entry> out;
    for (const Entry& e : all)
        if (filter.empty() || contains_ci(e.name, filter) || contains_ci(e.category, filter) || contains_ci(e.summary, filter)) out.push_back(e);
    return out;
}
}  // namespace

void register_api_export_commands(CommandRegistry& registry) {
    {
        CommandInfo info;
        info.name = "docs.components";
        info.category = "docs";
        info.summary = "Reference of components and fields (types, defaults, docs): a list of names, or one component in full.";
        info.description = "Generated from the engine's reflection data; always accurate for this build. Use before writing scene JSON. "
                           "With no argument it lists every component with a one-line summary (the whole reference is over 200 KB, more than "
                           "an MCP tool result carries). {\"name\":\"Sprite\"} returns that component with all its fields, "
                           "{\"filter\":\"physics\"} the components whose name, category or summary contains the text, "
                           "{\"full\":true} everything.";
        info.inputSchema = docs_filter_schema("component");
        registry.add(info, [](const Json& args) {
            const bool json = tooling_detail::arg_string(args, "format", false, "markdown") == "json";
            if (tooling_detail::arg_bool(args, "full", false) && !args.contains("name") && !args.contains("filter")) {
                if (json) return Json::object({{"components", export_components_json()}});
                return Json::object({{"markdown", export_components_markdown()}});
            }
            const Json all = export_components_json();
            std::vector<Entry> entries;
            for (const Json& t : all) entries.push_back({t.value("name", ""), t.value("category", ""), first_sentence(t.value("doc", "")), &t, nullptr});
            const Entry* exact = nullptr;
            std::vector<Entry> picked = select_entries(entries, args, "component", "docs.components", &exact);
            if (exact) {
                if (json) return Json::object({{"components", Json::array({*exact->json})}});
                std::ostringstream o;
                write_component(o, *exact->json, "##");
                return Json::object({{"markdown", o.str()}});
            }
            if (json) return Json::object({{"components", entries_json(picked)}, {"hint", "docs.components {\"name\":\"<name>\"} returns one in full."}});
            const std::string f = tooling_detail::arg_string(args, "filter", false);
            return Json::object({{"markdown", entries_markdown(picked, "Components", "docs.components", picked.empty() ? "Sprite" : picked.front().name,
                                                                f.empty() ? "" : "Filter: `" + f + "`.\n\n")}});
        });
    }
    {
        CommandInfo info;
        info.name = "docs.commands";
        info.category = "docs";
        info.summary = "Reference of the available commands (tools) with arguments: a list of names, or one command in full.";
        info.description = "Lists the commands of this session, including project tools from tools/*.js. With no argument it lists every command "
                           "with its summary (the whole reference is over 200 KB, more than an MCP tool result carries). "
                           "{\"name\":\"game.click\"} returns that command with its arguments, {\"filter\":\"ui\"} the commands whose name, "
                           "category or summary contains the text, {\"full\":true} everything.";
        info.inputSchema = docs_filter_schema("command");
        registry.add(info, [&registry](const Json& args) {
            const bool json = tooling_detail::arg_string(args, "format", false, "markdown") == "json";
            if (tooling_detail::arg_bool(args, "full", false) && !args.contains("name") && !args.contains("filter")) {
                if (json) return Json::object({{"commands", export_commands_json(registry)}});
                return Json::object({{"markdown", export_commands_markdown(registry)}});
            }
            std::vector<Entry> entries;
            for (const CommandInfo* c : registry.list()) entries.push_back({c->name, c->category, c->summary, nullptr, c});
            const Entry* exact = nullptr;
            std::vector<Entry> picked = select_entries(entries, args, "command", "docs.commands", &exact);
            if (exact) {
                if (json) {
                    for (const Json& c : export_commands_json(registry))
                        if (c.value("name", "") == exact->name) return Json::object({{"commands", Json::array({c})}});
                }
                std::ostringstream o;
                write_command(o, exact->info, "##");
                return Json::object({{"markdown", o.str()}});
            }
            if (json) return Json::object({{"commands", entries_json(picked)}, {"hint", "docs.commands {\"name\":\"<name>\"} returns one in full."}});
            const std::string f = tooling_detail::arg_string(args, "filter", false);
            return Json::object({{"markdown", entries_markdown(picked, "Commands", "docs.commands", picked.empty() ? "game.step" : picked.front().name,
                                                                f.empty() ? "" : "Filter: `" + f + "`.\n\n")}});
        });
    }
}

void register_api_reference_command(CommandRegistry& registry, const ScriptSystem& scripts) {
    {
        CommandInfo info;
        info.name = "docs.write_reference";
        info.category = "docs";
        info.readOnly = false;
        info.summary = "Write the browsable API reference pages (docs/reference/) and docs/COMPONENTS.md.";
        info.description =
            "Writes <out>/COMPONENTS.md (the whole `factoria api --md` text, including the scripting API) and <out>/reference/: README.md (index of every component and command), "
            "components/<category>.md and commands/<category>.md, all generated from the registries of this session. Run it outside "
            "a project (the scratch session) so plugin and project commands are not included; the unit test api_reference compares "
            "the committed files with this output. The files are identical on every platform. Example: {\"out\":\"docs\"} from the "
            "repository root.";
        info.inputSchema = Json::object({{"type", "object"}, {"required", Json::array({"out"})},
            {"properties", Json::object({{"out", Json::object({{"type", "string"},
                {"description", "Docs folder to write into (relative to the working directory), usually \"docs\"."}})}})}});
        registry.add(info, [&registry, &scripts](const Json& args) {
            const std::filesystem::path out = std::filesystem::absolute(tooling_detail::arg_string(args, "out", true));
            Json written = Json::array();
            for (const ApiReferencePage& p : export_api_reference(registry, scripts)) {
                std::string err;
                if (!tooling_detail::write_file(out / p.path, p.text, &err))
                    throw CommandError("write_failed", "Cannot write " + p.path + " under " + out.generic_string() + ": " + err,
                                       "Check that the folder exists and is writable.");
                written.push_back(p.path);
            }
            return Json::object({{"out", out.generic_string()}, {"written", written}});
        });
    }
}

}  // namespace fa
