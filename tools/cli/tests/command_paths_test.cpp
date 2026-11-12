// Two walks over the REAL registry of a project (engine, tooling, ai, docs and project commands, as `factoria mcp` serves them;
// the registry of `factoria mcp` without a project too), so a command added later cannot skip the safety rules of M92:
//  - every command declares its capabilities (CommandInfo::capabilitiesDeclared), and
//  - every schema property marked "x-fa-path": "write" is confined: called as an MCP client with `../outside.txt` or an absolute
//    path, the command refuses (path_outside_root, absolute_path_denied, invalid_path, managed_path_denied or capability_denied)
//    and nothing appears outside the project.
// docs/ARCHITECTURE.md, "Commands", "Capabilities" and "Paths a caller gives to a command that writes".
#include <doctest.h>

#include <algorithm>
#include <filesystem>
#include <map>
#include <set>
#include <string>
#include <vector>

#include "common.h"  // tools/cli/src: Session
#include "fa/core/capability.h"
#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/tooling/scaffold.h"

namespace stdfs = std::filesystem;
using namespace fa;

namespace {

// A temporary folder holding the project (`game`) and nothing else: whatever else appears in it was written outside the project.
struct Sandbox {
    stdfs::path oldRoot = fs::project_root();
    stdfs::path root = fs::make_temp_dir("fa_command_paths");
    std::string dir;
    Sandbox() {
        ScaffoldOptions opt;
        opt.writeTypings = false;
        dir = fs::path_to_utf8(root / "game");
        auto made = create_project(dir, "2d-empty", opt);
        REQUIRE_MESSAGE(made.ok(), (made.ok() ? std::string() : made.error().to_string()));
        // i18n.export judges its `out` only in a project that has string tables.
        const std::string manifest = dir + "/factoria.json";
        auto text = fs::read_text(manifest);
        REQUIRE(text.ok());
        auto json = parse_json(*text, manifest);
        REQUIRE(json.ok());
        (*json)["localization"] = Json::parse(R"({"defaultLanguage": "en", "languages": ["en", "es"]})");
        REQUIRE(fs::write_text(manifest, json->dump(2)).ok());
        REQUIRE(fs::write_text(dir + "/locales/en.json", R"({"menu":{"play":"Play"}})").ok());
        REQUIRE(fs::write_text(dir + "/locales/es.json", R"({"menu":{"play":"Jugar"}})").ok());
        // vector.to_rig reads the groups of a drawing.
        REQUIRE(fs::write_text(dir + "/assets/art/hero.svg",
                               R"(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20"><g id="body"><rect width="10" height="10" fill="#f00"/></g></svg>)")
                    .ok());
    }
    ~Sandbox() {
        fs::set_project_root(oldRoot);
        std::error_code ec;
        stdfs::remove_all(root, ec);
    }
    // The names inside `root` other than the project.
    std::set<std::string> strangers() const {
        std::set<std::string> out;
        std::error_code ec;
        for (stdfs::directory_iterator it(root, ec), end; !ec && it != end; it.increment(ec))
            if (fs::path_to_utf8(it->path().filename()) != "game") out.insert(fs::path_to_utf8(it->path().filename()));
        return out;
    }
};

// ---- the schema walk ---------------------------------------------------------------------------------------------------

// A way down a schema to a value: "p:name" is the property `name` of an object, "i" the items of an array.
using Way = std::vector<std::string>;

// The properties marked "x-fa-path": `kind` is "write" or "read".
void find_path_properties(const Json& schema, const char* kind, Way way, std::vector<Way>& out, int depth = 0) {
    if (!schema.is_object() || depth > 8) return;
    if (schema.value("x-fa-path", std::string()) == kind) out.push_back(way);
    if (auto props = schema.find("properties"); props != schema.end() && props->is_object())
        for (auto it = props->begin(); it != props->end(); ++it) {
            Way next = way;
            next.push_back("p:" + it.key());
            find_path_properties(it.value(), kind, next, out, depth + 1);
        }
    if (auto items = schema.find("items"); items != schema.end()) {
        Way next = way;
        next.push_back("i");
        find_path_properties(*items, kind, next, out, depth + 1);
    }
}

Json sample_value(const Json& schema, int depth = 0);

// Fills the `required` properties of an object schema that `obj` does not hold yet, minimally.
void fill_required(const Json& schema, Json& obj, int depth) {
    auto req = schema.find("required");
    auto props = schema.find("properties");
    if (req == schema.end() || !req->is_array() || props == schema.end() || !props->is_object()) return;
    for (const Json& name : *req) {
        if (!name.is_string() || obj.contains(name.get<std::string>())) continue;
        auto p = props->find(name.get<std::string>());
        obj[name.get<std::string>()] = p == props->end() ? Json("x") : sample_value(*p, depth + 1);
    }
}

// A small value that fits `schema` (its default, first enum entry or the simplest value of its type).
Json sample_value(const Json& schema, int depth) {
    if (!schema.is_object() || depth > 6) return Json("x");
    if (schema.contains("default")) return schema["default"];
    if (schema.contains("const")) return schema["const"];
    if (auto e = schema.find("enum"); e != schema.end() && e->is_array() && !e->empty()) return (*e)[0];
    for (const char* key : {"oneOf", "anyOf"})
        if (auto alt = schema.find(key); alt != schema.end() && alt->is_array() && !alt->empty()) return sample_value((*alt)[0], depth + 1);
    std::string type = "string";
    if (auto t = schema.find("type"); t != schema.end()) {
        if (t->is_string()) type = t->get<std::string>();
        else if (t->is_array() && !t->empty() && (*t)[0].is_string()) type = (*t)[0].get<std::string>();
    }
    if (type == "boolean") return Json(false);
    if (type == "integer") return Json(static_cast<long long>(std::max(1.0, schema.value("minimum", 1.0))));
    if (type == "number") return Json(std::max(1.0, schema.value("minimum", 1.0)));
    if (type == "array") {
        Json arr = Json::array();
        const std::size_t n = static_cast<std::size_t>(schema.value("minItems", 0));
        for (std::size_t i = 0; i < n; ++i) arr.push_back(schema.contains("items") ? sample_value(schema["items"], depth + 1) : Json("x"));
        return arr;
    }
    if (type == "object") {
        Json obj = Json::object();
        fill_required(schema, obj, depth);
        return obj;
    }
    return Json("x");
}

// Puts `value` where `way` leads inside `node`, creating the objects and arrays on the way.
void set_way(Json& node, const Way& way, std::size_t at, const Json& value) {
    if (at == way.size()) {
        node = value;
        return;
    }
    if (way[at] == "i") {
        if (!node.is_array()) node = Json::array();
        if (node.empty()) node.push_back(Json());
        set_way(node[0], way, at + 1, value);
        return;
    }
    if (!node.is_object()) node = Json::object();
    set_way(node[way[at].substr(2)], way, at + 1, value);
}

std::string way_text(const Way& way) {
    std::string out;
    for (const std::string& w : way) out += (w == "i" ? std::string("[]") : "/" + w.substr(2));
    return out;
}

// The commands this walk cannot call with a bad path, and why. Keep it short: a command that only needs more arguments than the
// schema's `required` says belongs here only when no sample can reach its path check.
const std::map<std::string, std::string>& skipped_commands() {
    static const std::map<std::string, std::string> skip = {
        {"input.record", "`path` is only judged by `stop`, which needs a recording started first: command_capabilities_tests calls it."},
        {"vfx.filmstrip", "the project runs without a renderer here, so it answers `unavailable` before it reads `path`."},
        {"music.drums /pictureOut", "only used when `path` names a song, which the project here has none of; add_piano_roll judges it as music.info does."},
        {"music.arpeggio /pictureOut", "as music.drums /pictureOut."},
        {"music.bassline /pictureOut", "as music.drums /pictureOut."},
        {"anim.filmstrip", "needs a renderer and an animated entity, so it answers `unavailable` or `invalid_argument` before `path`."},
    };
    return skip;
}

// Arguments a command needs besides its schema's `required` ones before it gets as far as judging its path. A null removes
// the argument the sample would have given (two that exclude each other).
Json extra_arguments(const std::string& name) {
    static const std::map<std::string, Json> extra = {
        {"assets.draw_icon", Json::parse(R"({"background":{"color":"#ffffff"}})")},
        {"assets.pack_atlas", Json::parse(R"({"out":"atlas.png"})")},
        {"image.pixel.dither", Json::parse(R"({"gradient":null,"level":0.5,"colors":["#000000","#ffffff"]})")},
        {"image.pixel.scale", Json::parse(R"({"size":null,"factor":2})")},
        {"image.pixel.shade", Json::parse(R"({"light":45})")},
        {"model.preview", Json::parse(R"({"document":{"format":"factoria.model/1","nodes":[{"op":"box","size":[1,1,1]}]}})")},
        {"music.drums", Json::parse(R"({"style":"rock","picture":true})")},
        {"music.instrument", Json::parse(R"({"name":"pluck"})")},
        {"prefab.save", Json::parse(R"({"id":"camera"})")},
        {"scene.import_ascii", Json::parse(R"({"rows":["#"],"legend":{"#":0}})")},
        {"sfx.preset", Json::parse(R"({"name":"coin"})")},
        {"vector.to_rig", Json::parse(R"({"source":"assets/art/hero.svg"})")},
    };
    if (name.rfind("vector.", 0) == 0 && name != "vector.to_rig")  // the SVG comes from `svg`: `source`, `document` and `out` are free
        return Json::parse(R"({"svg":"<svg xmlns='http://www.w3.org/2000/svg' width='8' height='8'/>"})");
    const auto it = extra.find(name);
    return it == extra.end() ? Json::object() : it->second;
}

bool refused_by_path_rules(const std::string& code) {
    return code == "path_outside_root" || code == "absolute_path_denied" || code == "invalid_path" || code == "managed_path_denied" ||
           code == "capability_denied";
}

std::vector<const CommandInfo*> all_commands(CommandRegistry& session, CommandRegistry& bootstrap) {
    std::vector<const CommandInfo*> out = session.list();
    for (const CommandInfo* c : bootstrap.list())
        if (!session.has(c->name)) out.push_back(c);
    return out;
}

}  // namespace

TEST_CASE("every registered command declares its capabilities (M92)") {
    Sandbox box;
    cli::SessionOptions so;
    so.gfx = cli::Gfx::None;
    auto session = cli::Session::open(box.dir, so);
    cli::register_cli_commands(session->registry(), box.dir, &session->engine());
    CommandRegistry bootstrap;  // what `factoria mcp` serves before it has a project
    cli::register_cli_commands(bootstrap, "", nullptr);

    std::string undeclared;
    std::size_t count = 0;
    for (const CommandInfo* c : all_commands(session->registry(), bootstrap)) {
        ++count;
        if (!c->capabilitiesDeclared) undeclared += (undeclared.empty() ? "" : ", ") + c->name;
    }
    CHECK(count > 150);
    CHECK_MESSAGE(undeclared.empty(),
                  "commands without a capability declaration (declare them with declare_command_capabilities in their module): " << undeclared);
}

namespace {

bool contains(const std::string& haystack, const std::string& needle) { return haystack.find(needle) != std::string::npos; }

// What a call that was given a bad path came to.
struct Outcome {
    bool refused = false;    // it failed...
    bool aboutPath = false;  // ...with a path rule's code, or an error that quotes the bad path
    std::string code, message;
};

// Calls `info` with the sample arguments, `extra` on top and `bad` where `target` leads. With `others` (the other path arguments),
// `bad` also goes into those the sample or `extra` already gave: a command that reads one file and writes another may judge the
// first before it gets to the second.
Outcome call_with(CommandRegistry& reg, const CommandInfo& info, const Way& target, const std::vector<Way>& others, const std::string& bad,
                  const Json& extra) {
    Json args = sample_value(info.inputSchema);
    if (!args.is_object()) args = Json::object();
    for (auto it = extra.begin(); it != extra.end(); ++it) {
        if (it.value().is_null()) args.erase(it.key());
        else args[it.key()] = it.value();
    }
    // `svg` is an input of the vector commands only where their schema has it (vector.to_rig has not).
    if (args.contains("svg") && !(info.inputSchema.contains("properties") && info.inputSchema["properties"].contains("svg"))) args.erase("svg");
    if (target.size() == 1 && target[0] != "i" && (target[0] == "p:source" || target[0] == "p:document")) args.erase("svg");
    for (const Way& way : others)
        if (!way.empty() && way[0].rfind("p:", 0) == 0 && args.contains(way[0].substr(2))) set_way(args, way, 0, Json(bad));
    set_way(args, target, 0, Json(bad));
    const CommandResult r = reg.call(info.name, args);
    Outcome o;
    o.refused = !r.ok;
    if (!r.ok) {
        o.code = r.error.value("code", std::string());
        o.message = r.error.value("message", std::string());
        o.aboutPath = refused_by_path_rules(o.code) || contains(o.message, bad);
    }
    return o;
}

}  // namespace

TEST_CASE("every schema property marked x-fa-path write is confined for an MCP client (M92)") {
    Sandbox box;
    cli::SessionOptions so;
    so.gfx = cli::Gfx::None;
    auto session = cli::Session::open(box.dir, so);
    cli::register_cli_commands(session->registry(), box.dir, &session->engine());
    CommandRegistry bootstrap;
    cli::register_cli_commands(bootstrap, "", nullptr);

    // Two ways out of the project; the extension varies because some commands check it before they judge the path.
    const std::vector<std::string> stems = {"../outside", fs::path_to_utf8(box.root / "abs_outside")};
    const std::vector<std::string> extensions = {".txt", ".png", ".json", ".svg"};
    std::string created, notRefused, unreached;
    std::size_t targets = 0;
    std::set<std::string> commandsWithTargets;
    {
        CommandCallerScope mcp(CommandCaller::Mcp);
        for (const CommandInfo* info : all_commands(session->registry(), bootstrap)) {
            std::vector<Way> writes, reads;
            find_path_properties(info->inputSchema, "write", {}, writes);
            if (writes.empty()) continue;
            find_path_properties(info->inputSchema, "read", {}, reads);
            commandsWithTargets.insert(info->name);
            if (skipped_commands().count(info->name)) continue;
            CommandRegistry& reg = session->registry().has(info->name) ? session->registry() : bootstrap;
            const Json more = extra_arguments(info->name);
            for (const Way& way : writes) {
                commandsWithTargets.insert(info->name + " " + way_text(way));
                if (skipped_commands().count(info->name + " " + way_text(way))) continue;
                for (const std::string& stem : stems) {
                    ++targets;
                    const std::string label = "\n  " + info->name + " " + way_text(way) + " = " + stem;
                    Outcome o;
                    for (const std::string& ext : extensions) {
                        const std::string bad = stem + ext;
                        o = call_with(reg, *info, way, {}, bad, more);
                        if (!o.aboutPath && o.refused) {  // another path argument may fail first
                            std::vector<Way> others = writes;
                            others.insert(others.end(), reads.begin(), reads.end());
                            o = call_with(reg, *info, way, others, bad, more);
                        }
                        if (!o.refused || o.aboutPath || !box.strangers().empty()) break;
                    }
                    if (const std::set<std::string> outside = box.strangers(); !outside.empty()) {
                        created += label + " created " + *outside.begin();
                        std::error_code ec;
                        for (const std::string& n : outside) stdfs::remove_all(box.root / fs::path_from_utf8(n), ec);
                    }
                    if (!o.refused) notRefused += label + " succeeded";
                    else if (!o.aboutPath) unreached += label + " -> " + o.code + ": " + o.message.substr(0, 110);
                }
            }
        }
    }
    CHECK(targets > 40);
    CHECK_MESSAGE(created.empty(), "writers that created something outside the project:" << created);
    CHECK_MESSAGE(notRefused.empty(), "writers that accepted a path outside the project:" << notRefused);
    CHECK_MESSAGE(unreached.empty(),
                  "writers whose bad path was never judged (another argument failed first: give the sample the arguments it needs in "
                  "extra_arguments(), or list the command in skipped_commands() with the reason):" << unreached);
    for (const auto& [name, why] : skipped_commands()) {
        CAPTURE(name);
        CHECK_FALSE(why.empty());
        CHECK(commandsWithTargets.count(name));  // a skipped command that is gone or has no writing path is removed from the table
    }
}

