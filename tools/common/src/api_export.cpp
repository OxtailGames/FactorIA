#include "fa/core/engine_version.h"
#include "fa/tooling/api_export.h"

#include <algorithm>
#include <cmath>
#include <filesystem>
#include <functional>
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
// A range bound: an integer field's bounds are stored as doubles but read as integers ("3..64", not "3.0..64.0").
std::string bound_text(const Json& j, bool integerField) {
    if (integerField && j.is_number() && j.get<double>() == std::floor(j.get<double>()) && std::fabs(j.get<double>()) < 9e15)
        return std::to_string(static_cast<long long>(j.get<double>()));
    return short_json(j);
}

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
            for (const auto& e : f["enum"]) { type += (first ? "" : " | ") + e.get<std::string>(); first = false; }  // md_escape escapes the bars once
        }
        if (f.contains("assetType")) type += " (" + f["assetType"].get<std::string>() + ")";
        std::string desc = f.value("doc", "");
        if (f.contains("min")) desc += " Range " + bound_text(f["min"], f.value("kind", "") == "int") + ".." + bound_text(f["max"], f.value("kind", "") == "int") + ".";
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
    if (!c->details.empty()) o << c->details << "\n\n";
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

std::string command_details_pointer(const CommandInfo& info) {
    if (info.details.empty()) return {};
    return "More (the rest of this description): docs_commands {\"name\":\"" + info.name +
           "\"}, the section `" + info.name + "` of the docs reference.";
}

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
// docs.components / docs.commands: no argument lists names with a one-line summary; `name` gives one entry in full, `filter`
// narrows the list, `full` gives the entries in full. Lists and `full` come in pages of at most `maxBytes` (like docs.read), each
// page ends at a whole entry and names the next one in `nextCursor`.
constexpr long kDocsPageDefaultBytes = 40000;  // same as docs.read: ~10k tokens, an MCP tool result is capped near 25k tokens
constexpr long kDocsPageMaxBytes = 90000;

Json docs_filter_schema(const char* what) {
    const std::string n = what;
    return Json::object({{"type", "object"},
        {"properties", Json::object({
            {"name", Json::object({{"type", "string"}, {"description", "Exact " + n + " name (case-insensitive): returns its full reference."}})},
            {"filter", Json::object({{"type", "string"}, {"description", "Keep the " + n + "s whose name, category or summary contains this text (case-insensitive)."}})},
            {"full", Json::object({{"type", "boolean"}, {"default", false}, {"description", "Return the " + n + "s in full, one page at a time (see maxBytes, cursor); with filter, only the matches."}})},
            {"cursor", Json::object({{"type", "string"}, {"description", "The nextCursor of the previous page: continues the list or the full reference from there. Use it with the same filter and format."}})},
            {"maxBytes", Json::object({{"type", "integer"}, {"minimum", 1000}, {"maximum", kDocsPageMaxBytes}, {"default", kDocsPageDefaultBytes}, {"description", "Page size in bytes: whole entries are added until the next would not fit (a page has at least one)."}})},
            {"format", Json::object({{"type", "string"}, {"enum", Json::array({"markdown", "json"})}, {"default", "markdown"}, {"description", "Output format."}})}})}});
}

bool contains_ci(const std::string& hay, const std::string& needle) { return to_lower(hay).find(to_lower(needle)) != std::string::npos; }

struct Entry {
    std::string name, category, summary;
    const Json* json = nullptr;        // components
    const CommandInfo* info = nullptr;  // commands
};

// How a kind of entry renders in full.
struct FullRender {
    std::function<Json(const Entry&)> asJson;
    std::function<std::string(const Entry&)> asMarkdown;  // starts with "### Name"
};

// Returns one page of the (already filtered) entries: the list of summaries, or with `full` each entry in full.
Json docs_page(const std::vector<Entry>& v, const Json& args, bool full, bool json, const char* key, const std::string& title,
               const std::string& tool, const std::string& example, const std::string& filter, const FullRender& render) {
    double wanted = double(kDocsPageDefaultBytes);  // clamped as a double: a huge JSON number must not wrap when narrowed
    if (auto it = args.find("maxBytes"); it != args.end() && it->is_number()) wanted = it->get<double>();
    if (!(wanted >= 1000.0)) wanted = 1000.0;
    const long maxBytes = wanted > double(kDocsPageMaxBytes) ? kDocsPageMaxBytes : long(wanted);
    const std::string cursor = tooling_detail::arg_string(args, "cursor", false);
    size_t start = 0;
    if (!cursor.empty()) {
        while (start < v.size() && v[start].name != cursor) ++start;
        if (start == v.size()) {
            Json restart = Json::object();
            if (!filter.empty()) restart["filter"] = filter;
            if (full) restart["full"] = true;
            throw CommandError("invalid_argument",
                               "cursor '" + cursor + "' is not an entry of this " + title + " list" + (filter.empty() ? "" : " (filter '" + filter + "')") +
                                   ": it was not returned by " + tool + " with these arguments, or the set of entries changed.",
                               "Use the nextCursor of the previous page unchanged, with the same filter, full and format. To start again, call " + tool + " " +
                                   restart.dump() + " without cursor.");
        }
    }
    std::ostringstream o;
    Json arr = Json::array();
    long used = 0;
    size_t i = start;
    std::string lastCat;
    for (; i < v.size(); ++i) {
        const Entry& e = v[i];
        std::string piece;
        Json item;
        if (json) {
            item = full ? render.asJson(e) : Json::object({{"name", e.name}, {"category", e.category}, {"summary", e.summary}});
            piece = item.dump();
        } else {
            if (i == start || e.category != lastCat)
                piece += std::string(i == start ? "" : "\n") + "## " + (e.category.empty() ? "general" : e.category) + "\n\n";
            piece += full ? render.asMarkdown(e) : "- `" + e.name + "`: " + e.summary + "\n";
        }
        if (i > start && used + long(piece.size()) > maxBytes) break;
        used += long(piece.size());
        lastCat = e.category;
        if (json) arr.push_back(std::move(item)); else o << piece;
    }
    Json r = Json::object({{"total", v.size()}, {"returned", i - start}});
    if (i < v.size()) {
        r["nextCursor"] = v[i].name;
        Json call = Json::object();
        if (!filter.empty()) call["filter"] = filter;
        if (full) call["full"] = true;
        call["cursor"] = v[i].name;
        if (json) call["format"] = "json";
        r["next"] = tool + " " + call.dump() + " returns the next page (" + std::to_string(v.size() - i) + " entries left).";
    }
    if (json) {
        r[key] = std::move(arr);
        if (!full) r["hint"] = tool + " {\"name\":\"<name>\"} returns one in full.";
        return r;
    }
    std::ostringstream md;
    if (start == 0) {
        md << "# " << title << " (" << v.size() << ")\n\n" << (filter.empty() ? "" : "Filter: `" + filter + "`.\n\n");
        if (full) md << "Full reference, in pages of at most " << maxBytes << " bytes: follow `nextCursor` until it is absent.\n\n";
        else md << "One line per entry. Read one in full: `" << tool << " {\"name\":\"" << example << "\"}`; narrow the list with `{\"filter\":\"text\"}`; "
                << "all in full, page by page, with `{\"full\":true}`.\n\n";
    } else {
        md << "# " << title << " (continued: entries " << start + 1 << "-" << i << " of " << v.size() << ")\n\n";
    }
    md << o.str();
    r["markdown"] = md.str();
    return r;
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
                           "With no argument it lists every component with a one-line summary. {\"name\":\"Sprite\"} returns that component "
                           "with all its fields, {\"filter\":\"physics\"} the components whose name, category or summary contains the text, "
                           "{\"full\":true} every component in full (over 200 KB) in pages of at most maxBytes (default 40000): "
                           "pass the result's nextCursor as cursor for the next page, until it is absent.";
        info.inputSchema = docs_filter_schema("component");
        registry.add(info, [](const Json& args) {
            const bool json = tooling_detail::arg_string(args, "format", false, "markdown") == "json";
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
            FullRender render;
            render.asJson = [](const Entry& e) { return *e.json; };
            render.asMarkdown = [](const Entry& e) { std::ostringstream o; write_component(o, *e.json, "###"); return o.str(); };
            return docs_page(picked, args, tooling_detail::arg_bool(args, "full", false), json, "components", "Components", "docs.components",
                             picked.empty() ? "Sprite" : picked.front().name, tooling_detail::arg_string(args, "filter", false), render);
        });
    }
    {
        CommandInfo info;
        info.name = "docs.commands";
        info.category = "docs";
        info.summary = "Reference of the available commands (tools) with arguments: a list of names, or one command in full.";
        info.description = "Lists the commands of this session, including project tools from tools/*.js. With no argument it lists every command "
                           "with its summary. {\"name\":\"game.click\"} returns that command with its arguments, {\"filter\":\"ui\"} the commands "
                           "whose name, category or summary contains the text, {\"full\":true} every command in full (over 200 KB) in pages of at "
                           "most maxBytes (default 40000): pass the result's nextCursor as cursor for the next page, until it is absent.";
        info.inputSchema = docs_filter_schema("command");
        registry.add(info, [&registry](const Json& args) {
            const bool json = tooling_detail::arg_string(args, "format", false, "markdown") == "json";
            std::vector<Entry> entries;
            for (const CommandInfo* c : registry.list()) entries.push_back({c->name, c->category, c->summary, nullptr, c});
            const Entry* exact = nullptr;
            std::vector<Entry> picked = select_entries(entries, args, "command", "docs.commands", &exact);
            const bool full = tooling_detail::arg_bool(args, "full", false);
            Json described;
            if (json && (exact || full)) described = export_commands_json(registry);
            auto json_of = [&described](const std::string& name) {
                for (const Json& c : described)
                    if (c.value("name", "") == name) return c;
                return Json::object({{"name", name}});
            };
            if (exact) {
                if (json) return Json::object({{"commands", Json::array({json_of(exact->name)})}});
                std::ostringstream o;
                write_command(o, exact->info, "##");
                return Json::object({{"markdown", o.str()}});
            }
            FullRender render;
            render.asJson = [json_of](const Entry& e) { return json_of(e.name); };
            render.asMarkdown = [](const Entry& e) { std::ostringstream o; write_command(o, e.info, "###"); return o.str(); };
            return docs_page(picked, args, full, json, "commands", "Commands", "docs.commands", picked.empty() ? "game.step" : picked.front().name,
                             tooling_detail::arg_string(args, "filter", false), render);
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
            "components/<category>.md and commands/<category>.md, and it refreshes the generated tools table between the markers in section 4 of <out>/AI_GUIDE.md; all generated from the registries of this session. Run it outside "
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
            // The generated tools table inside <out>/AI_GUIDE.md (the rest of that hand-written page stays).
            if (auto guide = tooling_detail::read_file(out / "AI_GUIDE.md")) {
                guide->erase(std::remove(guide->begin(), guide->end(), '\r'), guide->end());
                std::string err;
                if (!splice_ai_guide_tools_table(*guide, registry, &err)) throw CommandError("write_failed", err, "Restore the markers in section 4.");
                if (!tooling_detail::write_file(out / "AI_GUIDE.md", *guide, &err))
                    throw CommandError("write_failed", "Cannot write AI_GUIDE.md under " + out.generic_string() + ": " + err,
                                       "Check that the file is writable.");
                written.push_back("AI_GUIDE.md");
            }
            return Json::object({{"out", out.generic_string()}, {"written", written}});
        });
    }
}

}  // namespace fa
