#include "fa/tooling/project_fs.h"

#include <algorithm>
#include <cctype>
#include <regex>
#include <sstream>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa {

namespace stdfs = std::filesystem;
using tooling_detail::arg_bool;
using tooling_detail::arg_int;
using tooling_detail::arg_string;

namespace {

constexpr std::uintmax_t kMaxReadBytes = 1 << 20;     // 1 MiB per fs.read
constexpr std::uintmax_t kMaxWriteBytes = 8u << 20;   // 8 MiB per fs.write
constexpr std::uintmax_t kMaxSearchFileBytes = 2u << 20;

bool is_under(const stdfs::path& root, const stdfs::path& p) {
    auto r = root.begin(), rend = root.end();
    auto q = p.begin(), qend = p.end();
    for (; r != rend; ++r, ++q)
        if (q == qend || *q != *r) return false;
    return true;
}

bool is_binary(const std::string& s) {
    return s.find('\0') != std::string::npos;
}

// fs.list and fs.search skip the tools' folders (.factoria and the version-control folder), except the scratch folder
// `.factoria/tmp` (fa::fs::kScratchDir), whose files commands may create and delete, so they can be listed there.
bool in_hidden_dir(const std::string& rel) {
    if (fs::is_scratch_path(rel)) return false;
    return rel == ".factoria" || rel.rfind(".factoria/", 0) == 0 || rel == ".git" || rel.rfind(".git/", 0) == 0;
}

[[noreturn]] void fail(const char* code, const std::string& msg, const std::string& hint = {}) {
    throw CommandError(code, msg, hint);
}

// Throws unless fs.write / fs.edit / fs.delete may change `rel` (normalized, project-relative). It is the rule of
// fa::fs::check_writable, shared with scene.save and scene.import_ascii, so every command agrees on where files can be
// written and deleted: normal project folders and `.factoria/tmp/`, never the rest of `.factoria/`.
void require_writable(const std::string& rel) {
    auto ok = fs::check_writable(rel);
    if (!ok.ok()) fail("invalid_argument", ok.error().message, ok.error().hint);
}

stdfs::path root_of(const std::string& projectDir) {
    std::error_code ec;
    stdfs::path r = stdfs::weakly_canonical(stdfs::absolute(projectDir), ec);
    return r;
}

stdfs::path resolve_or_throw(const std::string& projectDir, const std::string& rel) {
    auto r = resolve_project_path(projectDir, rel);
    if (!r.ok()) fail("invalid_argument", r.error().message, r.error().hint);
    return r.value();
}

std::string rel_of(const stdfs::path& root, const stdfs::path& p) {
    std::error_code ec;
    std::string s = stdfs::relative(p, root, ec).generic_string();
    return s.empty() ? "." : s;
}

std::string lines_slice(const std::string& text, long from, long to, bool numbered, long* totalOut) {
    std::istringstream in(text);
    std::string line, out;
    long n = 0;
    while (std::getline(in, line)) {
        ++n;
        if (n < from || n > to) continue;
        if (numbered) out += std::to_string(n) + "\t";
        out += line + "\n";
    }
    *totalOut = n;
    return out;
}

Json str_prop(const char* desc) { return Json::object({{"type", "string"}, {"description", desc}}); }
Json bool_prop(const char* desc, bool def) { return Json::object({{"type", "boolean"}, {"default", def}, {"description", desc}}); }
Json int_prop(const char* desc, long def) { return Json::object({{"type", "integer"}, {"default", def}, {"description", desc}}); }

}  // namespace

Result<stdfs::path> resolve_project_path(const std::string& projectDir, std::string_view relPath) {
    std::string rel(relPath);
    std::replace(rel.begin(), rel.end(), '\\', '/');
    if (rel.empty()) rel = ".";
    if (rel[0] == '/' || (rel.size() > 1 && rel[1] == ':') || rel[0] == '~')
        return make_error("Absolute path '" + std::string(relPath) + "' is not allowed.",
                          "Use a project-relative path such as \"scenes/main.scene.json\".");
    for (const auto& part : split(rel, '/'))
        if (part == "..")
            return make_error("Path '" + std::string(relPath) + "' escapes the project directory.",
                              "Paths must stay inside the project; remove the \"..\" segments.");
    stdfs::path root = root_of(projectDir);
    std::error_code ec;
    // weakly_canonical resolves symlinks of the existing prefix, so links pointing out are caught.
    stdfs::path full = stdfs::weakly_canonical(root / rel, ec);
    if (ec) return make_error("Cannot resolve path '" + std::string(relPath) + "': " + ec.message());
    if (!is_under(root, full))
        return make_error("Path '" + std::string(relPath) + "' resolves outside the project (symlink?).",
                          "Only files physically inside the project directory are accessible.");
    return full;
}

void register_fs_commands(CommandRegistry& registry, const std::string& projectDir) {
    // ---------------------------------------------------------------- list
    {
        CommandInfo info;
        info.name = "fs.list";
        info.category = "fs";
        info.summary = "List files and folders in the project.";
        info.description = "Project-relative. Hides the tools' folders (.factoria, version control) except the scratch folder .factoria/tmp. Example: {\"path\":\"scenes\",\"recursive\":true}";
        info.inputSchema = Json::object({{"type", "object"},
            {"properties", Json::object({{"path", str_prop("Folder to list (default: project root).")},
                                         {"recursive", bool_prop("Descend into subfolders.", false)},
                                         {"glob", str_prop("Only paths matching this glob, e.g. \"**/*.js\".")},
                                         {"limit", int_prop("Maximum entries returned.", 500)}})}});
        registry.add(info, [projectDir](const Json& args) {
            stdfs::path root = root_of(projectDir);
            stdfs::path dir = resolve_or_throw(projectDir, arg_string(args, "path", false, "."));
            std::error_code ec;
            if (!stdfs::is_directory(dir, ec))
                fail("not_found", "'" + rel_of(root, dir) + "' is not a directory.", "Use fs.list on the parent folder to see what exists.");
            bool recursive = arg_bool(args, "recursive", false);
            std::string glob = arg_string(args, "glob", false);
            size_t limit = size_t(std::max<long>(1, arg_int(args, "limit", 500)));
            std::vector<std::pair<std::string, Json>> items;
            auto consider = [&](const stdfs::directory_entry& e) {
                std::string rel = rel_of(root, e.path());
                if (in_hidden_dir(rel)) return false;
                if (!glob.empty() && !glob_match(glob, rel)) return true;
                bool isDir = e.is_directory(ec);
                Json j = Json::object({{"path", rel}, {"type", isDir ? "dir" : "file"}});
                if (!isDir) j["size"] = e.file_size(ec);
                items.emplace_back(rel, std::move(j));
                return true;
            };
            if (recursive) {
                for (stdfs::recursive_directory_iterator it(dir, ec), end; !ec && it != end; it.increment(ec)) {
                    if (!consider(*it)) it.disable_recursion_pending();
                }
            } else {
                for (stdfs::directory_iterator it(dir, ec), end; !ec && it != end; it.increment(ec)) consider(*it);
            }
            std::sort(items.begin(), items.end(), [](auto& a, auto& b) { return a.first < b.first; });
            Json arr = Json::array();
            for (auto& [k, v] : items) {
                if (arr.size() >= limit) break;
                arr.push_back(std::move(v));
            }
            return Json::object({{"entries", arr}, {"count", arr.size()}, {"truncated", items.size() > limit}});
        });
    }
    // ---------------------------------------------------------------- read
    {
        CommandInfo info;
        info.name = "fs.read";
        info.category = "fs";
        info.summary = "Read a text file (optionally a line range).";
        info.description = "Example: {\"path\":\"scripts/player.js\",\"startLine\":1,\"endLine\":80}. "
                           "Binary files are refused. Set numbered=true to get line numbers for fs.edit planning.";
        info.inputSchema = Json::object({{"type", "object"},
            {"properties", Json::object({{"path", str_prop("Project-relative file path.")},
                                         {"startLine", int_prop("First line (1-based).", 1)},
                                         {"endLine", int_prop("Last line, inclusive (default: end of file).", 0)},
                                         {"numbered", bool_prop("Prefix every line with its number and a tab.", false)}})},
            {"required", Json::array({"path"})}});
        registry.add(info, [projectDir](const Json& args) {
            stdfs::path root = root_of(projectDir);
            std::string rel = arg_string(args, "path", true);
            stdfs::path p = resolve_or_throw(projectDir, rel);
            std::error_code ec;
            if (!stdfs::exists(p, ec)) fail("not_found", "File '" + rel + "' does not exist.", "Use fs.list to see available files.");
            if (stdfs::is_directory(p, ec)) fail("invalid_argument", "'" + rel + "' is a directory.", "Use fs.list to list it.");
            if (stdfs::file_size(p, ec) > kMaxReadBytes)
                fail("too_large", "File is larger than 1 MiB.", "Read a slice with startLine/endLine or use fs.search.");
            auto text = tooling_detail::read_file(p);
            if (!text) fail("failed", "Cannot read '" + rel + "'.");
            if (is_binary(*text)) fail("binary_file", "'" + rel + "' is a binary file.", "Only text files can be read.");
            long start = std::max<long>(1, arg_int(args, "startLine", 1));
            long end = arg_int(args, "endLine", 0);
            if (end <= 0) end = LONG_MAX;
            long total = 0;
            std::string content = lines_slice(*text, start, end, arg_bool(args, "numbered", false), &total);
            return Json::object({{"path", rel_of(root, p)}, {"content", content}, {"startLine", start},
                                 {"totalLines", total}, {"bytes", text->size()}});
        });
    }
    // --------------------------------------------------------------- write
    {
        CommandInfo info;
        info.name = "fs.write";
        info.category = "fs";
        info.readOnly = false;
        info.summary = "Create or overwrite a file (text, or binary via base64; parent folders are created).";
        info.description = "Example: {\"path\":\"scripts/enemy.js\",\"content\":\"export default class ...\"}. "
                           "For binary files such as PNG sprites pass encoding=\"base64\" and the base64 of the bytes as content "
                           "(e.g. {\"path\":\"sprites/hero.png\",\"encoding\":\"base64\",\"content\":\"iVBORw0KGgo...\"}). "
                           "For small changes to an existing file prefer fs.edit. .json files are checked for syntax "
                           "and a warning is returned if invalid; run project.validate afterwards. Writing into .factoria/ is refused except "
                           ".factoria/tmp/, the scratch folder for throw-away files (the same rule as scene.save).";
        info.inputSchema = Json::object({{"type", "object"},
            {"properties", Json::object({{"path", str_prop("Project-relative file path.")},
                                         {"content", str_prop("Full new file content (base64 text when encoding=base64).")},
                                         {"encoding", Json::object({{"type", "string"}, {"enum", Json::array({"utf8", "base64"})},
                                              {"default", "utf8"},
                                              {"description", "\"utf8\" writes content as text; \"base64\" decodes it and writes the bytes (images, audio)."}})},
                                         {"overwrite", bool_prop("Allow replacing an existing file.", true)}})},
            {"required", Json::array({"path", "content"})}});
        registry.add(info, [projectDir](const Json& args) {
            stdfs::path root = root_of(projectDir);
            std::string rel = arg_string(args, "path", true);
            std::string content = arg_string(args, "content", true);
            std::string encoding = arg_string(args, "encoding", false, "utf8");
            if (encoding != "utf8" && encoding != "base64")
                fail("invalid_argument", "Unknown encoding '" + encoding + "'.", "Use \"utf8\" (default) or \"base64\".");
            if (encoding == "base64") {
                // base64_decode skips unknown characters, so validate first and point at the bad one.
                size_t pad = 0;
                for (size_t i = 0; i < content.size(); ++i) {
                    char c = content[i];
                    bool ok = std::isalnum(static_cast<unsigned char>(c)) || c == '+' || c == '/' || c == '-' || c == '_';
                    if (c == '=') { ++pad; continue; }
                    if (std::isspace(static_cast<unsigned char>(c))) continue;
                    if (!ok || pad)
                        fail("invalid_argument", std::string("Invalid base64 at character ") + std::to_string(i) + " ('" + c + "').",
                             pad ? "'=' padding may only appear at the very end."
                                 : "Use only A-Z a-z 0-9 + / (and optional trailing '='); no data: prefix, quotes or other text.");
                }
                auto bytes = base64_decode(content);
                content.assign(reinterpret_cast<const char*>(bytes.data()), bytes.size());
            }
            stdfs::path p = resolve_or_throw(projectDir, rel);
            std::string r = rel_of(root, p);
            if (r == ".") fail("invalid_argument", "Writing to '" + rel + "' is not allowed.", "Give a file path inside the project.");
            require_writable(r);
            if (content.size() > kMaxWriteBytes) fail("too_large", "Content larger than 8 MiB.");
            std::error_code ec;
            bool existed = stdfs::exists(p, ec);
            if (stdfs::is_directory(p, ec)) fail("invalid_argument", "'" + rel + "' is a directory.");
            if (existed && !arg_bool(args, "overwrite", true))
                fail("exists", "'" + rel + "' already exists.", "Pass overwrite=true or choose another path.");
            std::string err;
            if (!tooling_detail::write_file(p, content, &err)) fail("failed", err);
            Json out = Json::object({{"path", r}, {"bytes", content.size()}, {"created", !existed}});
            if (ends_with(r, ".json")) {
                auto parsed = parse_json(content, r);
                if (!parsed.ok()) out["warning"] = "File written but is not valid JSON: " + parsed.error().to_string();
            }
            return out;
        });
    }
    // ---------------------------------------------------------------- edit
    {
        CommandInfo info;
        info.name = "fs.edit";
        info.category = "fs";
        info.readOnly = false;
        info.summary = "Replace exact text in a file (must match exactly once unless replaceAll).";
        info.description = "Example: {\"path\":\"scripts/player.js\",\"find\":\"speed = 300\",\"replace\":\"speed = 360\"}. "
                           "Fails if 'find' is not found or matches several places; include more surrounding text to make it unique. "
                           "Same write rule as fs.write (inside .factoria/ only .factoria/tmp/ may be edited).";
        info.inputSchema = Json::object({{"type", "object"},
            {"properties", Json::object({{"path", str_prop("Project-relative file path.")},
                                         {"find", str_prop("Exact text to find (whitespace-sensitive).")},
                                         {"replace", str_prop("Replacement text (may be empty to delete).")},
                                         {"replaceAll", bool_prop("Replace every occurrence.", false)}})},
            {"required", Json::array({"path", "find", "replace"})}});
        registry.add(info, [projectDir](const Json& args) {
            stdfs::path root = root_of(projectDir);
            std::string rel = arg_string(args, "path", true);
            std::string find = arg_string(args, "find", true), repl = arg_string(args, "replace", true);
            if (find.empty()) fail("invalid_argument", "'find' must not be empty.", "Use fs.write to create or replace whole files.");
            stdfs::path p = resolve_or_throw(projectDir, rel);
            std::string r = rel_of(root, p);
            require_writable(r);
            auto text = tooling_detail::read_file(p);
            if (!text) fail("not_found", "File '" + rel + "' does not exist.", "Use fs.list, or fs.write to create it.");
            if (is_binary(*text)) fail("binary_file", "'" + rel + "' is a binary file.");
            std::vector<size_t> positions;
            for (size_t pos = text->find(find); pos != std::string::npos; pos = text->find(find, pos + find.size()))
                positions.push_back(pos);
            if (positions.empty())
                fail("no_match", "Text to replace was not found in '" + rel + "'.",
                     "Read the file with fs.read and copy the text exactly (indentation, quotes, line breaks).");
            bool all = arg_bool(args, "replaceAll", false);
            if (positions.size() > 1 && !all) {
                std::string lines;
                for (size_t pos : positions) {
                    auto ln = 1 + std::count(text->begin(), text->begin() + std::ptrdiff_t(pos), '\n');
                    lines += (lines.empty() ? "" : ", ") + std::to_string(ln);
                }
                fail("ambiguous", "Text matches " + std::to_string(positions.size()) + " places in '" + rel + "' (lines " + lines + ").",
                     "Include more surrounding context in 'find' so it matches once, or pass replaceAll=true.");
            }
            std::string out;
            size_t last = 0;
            for (size_t pos : positions) {
                out.append(*text, last, pos - last);
                out += repl;
                last = pos + find.size();
                if (!all) break;
            }
            out.append(*text, last, std::string::npos);
            std::string err;
            if (!tooling_detail::write_file(p, out, &err)) fail("failed", err);
            Json res = Json::object({{"path", r}, {"replacements", all ? positions.size() : size_t(1)}});
            if (ends_with(r, ".json")) {
                auto parsed = parse_json(out, r);
                if (!parsed.ok()) res["warning"] = "File is no longer valid JSON: " + parsed.error().to_string();
            }
            return res;
        });
    }
    // -------------------------------------------------------------- search
    {
        CommandInfo info;
        info.name = "fs.search";
        info.category = "fs";
        info.summary = "Search text in project files (substring or regex).";
        info.description = "Skips binary files and .factoria/.git. Example: {\"query\":\"RigidBody2D\",\"glob\":\"**/*.json\"} "
                           "or {\"query\":\"onUpdate\\\\(\",\"regex\":true}.";
        info.inputSchema = Json::object({{"type", "object"},
            {"properties", Json::object({{"query", str_prop("Text or regular expression (ECMAScript).")},
                                         {"regex", bool_prop("Treat query as a regular expression.", false)},
                                         {"caseSensitive", bool_prop("Case-sensitive match.", false)},
                                         {"path", str_prop("Folder to search (default: project root).")},
                                         {"glob", str_prop("Only files matching this glob, e.g. \"**/*.js\".")},
                                         {"limit", int_prop("Maximum matches returned.", 100)}})},
            {"required", Json::array({"query"})}});
        registry.add(info, [projectDir](const Json& args) {
            stdfs::path root = root_of(projectDir);
            std::string query = arg_string(args, "query", true);
            if (query.empty()) fail("invalid_argument", "'query' must not be empty.");
            bool cs = arg_bool(args, "caseSensitive", false);
            std::regex re;
            bool useRe = arg_bool(args, "regex", false);
            if (useRe) {
                try {
                    re = std::regex(query, cs ? std::regex::ECMAScript : (std::regex::ECMAScript | std::regex::icase));
                } catch (const std::regex_error& e) {
                    fail("invalid_argument", std::string("Invalid regular expression: ") + e.what(),
                         "Escape special characters with \\\\ or set regex=false for a plain substring search.");
                }
            }
            std::string needle = cs ? query : to_lower(query);
            stdfs::path dir = resolve_or_throw(projectDir, arg_string(args, "path", false, "."));
            std::string glob = arg_string(args, "glob", false);
            size_t limit = size_t(std::max<long>(1, arg_int(args, "limit", 100)));
            Json matches = Json::array();
            size_t filesScanned = 0;
            bool truncated = false;
            std::error_code ec;
            std::vector<std::string> paths;
            if (stdfs::is_regular_file(dir, ec)) {
                paths.push_back(rel_of(root, dir));
            } else {
                for (stdfs::recursive_directory_iterator it(dir, ec), end; !ec && it != end; it.increment(ec)) {
                    std::string rel = rel_of(root, it->path());
                    if (in_hidden_dir(rel)) { it.disable_recursion_pending(); continue; }
                    if (!it->is_regular_file(ec)) continue;
                    if (!glob.empty() && !glob_match(glob, rel)) continue;
                    paths.push_back(rel);
                }
            }
            std::sort(paths.begin(), paths.end());
            for (const auto& rel : paths) {
                stdfs::path p = root / rel;
                if (stdfs::file_size(p, ec) > kMaxSearchFileBytes) continue;
                auto text = tooling_detail::read_file(p);
                if (!text || is_binary(*text)) continue;
                ++filesScanned;
                std::istringstream in(*text);
                std::string line;
                long n = 0;
                while (std::getline(in, line)) {
                    ++n;
                    bool hit = useRe ? std::regex_search(line, re) : (cs ? line : to_lower(line)).find(needle) != std::string::npos;
                    if (!hit) continue;
                    if (matches.size() >= limit) { truncated = true; break; }
                    if (line.size() > 300) line = line.substr(0, 300) + "...";
                    matches.push_back(Json::object({{"path", rel}, {"line", n}, {"text", line}}));
                }
                if (truncated) break;
            }
            return Json::object({{"matches", matches}, {"count", matches.size()}, {"filesScanned", filesScanned}, {"truncated", truncated}});
        });
    }
    // -------------------------------------------------------------- delete
    {
        CommandInfo info;
        info.name = "fs.delete";
        info.category = "fs";
        info.readOnly = false;
        info.summary = "Delete a file or folder from the project.";
        info.description = "Folders need recursive=true. factoria.json and ENGINE_FEEDBACK.json cannot be deleted. Not undoable "
                           "unless the project is under version control. Inside .factoria/ (screenshots, saves, AI transcripts) "
                           "only the scratch folder .factoria/tmp/ can be deleted, the same folder fs.write and scene.save may "
                           "write to. Example: {\"path\":\"scripts/old.js\"} or {\"path\":\".factoria/tmp\",\"recursive\":true}";
        info.inputSchema = Json::object({{"type", "object"},
            {"properties", Json::object({{"path", str_prop("Project-relative path.")},
                                         {"recursive", bool_prop("Delete a folder and everything in it.", false)}})},
            {"required", Json::array({"path"})}});
        registry.add(info, [projectDir](const Json& args) {
            stdfs::path root = root_of(projectDir);
            std::string rel = arg_string(args, "path", true);
            stdfs::path p = resolve_or_throw(projectDir, rel);
            std::string r = rel_of(root, p);
            if (r == "." || r == "factoria.json" || r == "ENGINE_FEEDBACK.json")
                fail("invalid_argument", "Deleting '" + rel + "' is not allowed.", "The project root, factoria.json and ENGINE_FEEDBACK.json are protected.");
            require_writable(r);
            std::error_code ec;
            if (!stdfs::exists(stdfs::symlink_status(p, ec))) fail("not_found", "'" + rel + "' does not exist.");
            if (stdfs::is_directory(p, ec) && !stdfs::is_symlink(p, ec)) {
                if (!arg_bool(args, "recursive", false))
                    fail("invalid_argument", "'" + rel + "' is a folder.", "Pass recursive=true to delete it with its contents.");
                auto n = stdfs::remove_all(p, ec);
                if (ec) fail("failed", "Delete failed: " + ec.message());
                return Json::object({{"path", r}, {"deleted", n}});
            }
            stdfs::remove(p, ec);
            if (ec) fail("failed", "Delete failed: " + ec.message());
            return Json::object({{"path", r}, {"deleted", 1}});
        });
    }
}

}  // namespace fa
