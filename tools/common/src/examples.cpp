// The example games a user can get: the two manifests, the release URLs, the checks of a download and the packaging
// (fa/tooling/examples.h).
#include "fa/tooling/examples.h"

#include <algorithm>
#include <cctype>
#include <fstream>
#include <iterator>
#include <set>

#include "export_internal.h"
#include "export_zip.h"
#include "fa/core/build_info.h"
#include "fa/core/fs.h"
#include "fa/core/hash.h"
#include "fa/core/strings.h"
#include "fa/runtime/project.h"
#include "fa/tooling/setup_parse.h"
#include "util.h"

namespace fa {

namespace stdfs = std::filesystem;

namespace {

constexpr std::size_t kMaxExamples = 200;
constexpr std::size_t kMaxReadFirst = 8;
constexpr std::size_t kMaxTitle = 80;
constexpr std::size_t kMaxShows = 240;

bool is_name_char(char c) { return (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '-'; }

bool valid_example_name(std::string_view n) {
    return !n.empty() && n.size() <= 64 && n[0] != '-' && std::all_of(n.begin(), n.end(), is_name_char);
}

// docs/<NAME>.md or docs/<folder>/<NAME>.md
bool valid_doc_path(std::string_view p) {
    if (p.size() < 9 || p.substr(0, 5) != "docs/" || p.substr(p.size() - 3) != ".md") return false;
    return std::all_of(p.begin() + 5, p.end() - 3, [](char c) {
        return std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '-' || c == '/';
    });
}

bool plain_file_name(std::string_view f) {
    if (f.empty() || f.size() > 128 || f == "." || f == "..") return false;
    return std::all_of(f.begin(), f.end(), [](char c) {
        return std::isalnum(static_cast<unsigned char>(c)) || c == '.' || c == '_' || c == '-' || c == '+';
    });
}

bool valid_version_text(std::string_view v) {
    if (v.empty() || v.size() > 64) return false;
    return std::all_of(v.begin(), v.end(), [](char c) {
        return std::isalnum(static_cast<unsigned char>(c)) || c == '.' || c == '-' || c == '+';
    });
}

bool is_hex64(std::string_view s) {
    return s.size() == 64 &&
           std::all_of(s.begin(), s.end(), [](char c) { return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f'); });
}

// "<source>#<pointer>: <message>", the form of ValidationIssue::to_string (a pointer is not a path inside the source).
Error at(std::string_view source, const std::string& pointer, const std::string& message, const std::string& hint) {
    return make_error(std::string(source) + (pointer.empty() ? "" : "#" + pointer) + ": " + message, hint);
}

// The member `key` of the object `o` as a string, or an Error that points at it.
Result<std::string> string_member(const Json& o, const char* key, std::string_view source, const std::string& base,
                                  const std::string& example) {
    auto it = o.find(key);
    if (it == o.end())
        return at(source, base + "/" + key, std::string("the field \"") + key + "\" is missing",
                  "Add " + example + ".");
    if (!it->is_string())
        return at(source, base + "/" + key,
                  std::string("\"") + key + "\" must be a string, got " + describe_json_value(*it),
                  "Write it as " + example + ".");
    return it->get<std::string>();
}

// The format check both manifests share: "<prefix><n>", n equal to kExamplesFormatVersion.
Result<void> check_format(const Json& root, const char* expected, std::string_view source) {
    if (!root.is_object())
        return at(source, "", "the manifest must be a JSON object, got " + describe_json_value(root),
                  std::string("Start it with {\"format\": \"") + expected + "\", ...}.");
    auto it = root.find("format");
    if (it == root.end() || !it->is_string())
        return at(source, "/format", "the field \"format\" is missing",
                  std::string("Add \"format\": \"") + expected +
                      "\". A file without it is not a FactorIA examples manifest.");
    const std::string format = it->get<std::string>();
    if (format == expected) return {};
    const std::string kind(expected, std::string_view(expected).find('/') + 1);  // "factoria.examples/"
    if (format.rfind(kind, 0) == 0)
        return at(source, "/format",
                  "the manifest has the format \"" + format + "\", and this FactorIA reads \"" + expected + "\" only",
                  std::string(expected) == kExamplesSourceFormat
                      ? "Use the examples.json of the same checkout as the factoria that reads it, or, if you wrote "
                        "it, bring its fields to the format \"" +
                            std::string(expected) +
                            "\" (docs/design/BUILDING.md, "
                            "\"Example games in the release\")."
                      : "The release was made by a different version of FactorIA than the one installed. Update "
                        "FactorIA (Help > Check for updates, or download it again) and try again.");
    return at(source, "/format", "the format is \"" + format + "\", expected \"" + expected + "\"",
              std::string("This is not the examples manifest this FactorIA reads; the format line must be \"") +
                  expected + "\".");
}

Result<ExampleInfo> parse_example(const Json& e, std::string_view source, const std::string& base, bool release) {
    if (!e.is_object())
        return at(
            source, base, "an example must be an object, got " + describe_json_value(e),
            R"(Write {"name": "block-push", "title": "Block Push", "shows": "...", "readFirst": ["docs/SCRIPTING.md"]}.)");
    ExampleInfo x;
    auto name = string_member(e, "name", source, base, R"("name": "block-push")");
    if (!name.ok()) return name.error();
    x.name = *name;
    if (!valid_example_name(x.name))
        return at(source, base + "/name", "the name \"" + x.name + "\" is not a valid example name",
                  "Use the example's folder name: lowercase letters, digits and '-', starting with a letter or digit, "
                  "at most 64 characters.");
    auto title = string_member(e, "title", source, base, R"("title": "Block Push")");
    if (!title.ok()) return title.error();
    x.title = *title;
    if (x.title.empty() || x.title.size() > kMaxTitle)
        return at(source, base + "/title", "the title must have 1 to " + std::to_string(kMaxTitle) + " characters",
                  "Write the name of the game as a person reads it, e.g. \"Block Push\".");
    auto shows =
        string_member(e, "shows", source, base, R"("shows": "A Sokoban puzzle: tile rules, undo, level data")");
    if (!shows.ok()) return shows.error();
    x.shows = *shows;
    if (x.shows.empty() || x.shows.size() > kMaxShows || x.shows.find('\n') != std::string::npos)
        return at(source, base + "/shows",
                  "\"shows\" must be one line of 1 to " + std::to_string(kMaxShows) + " characters",
                  "Say in one sentence what a person learns from this example.");
    auto rf = e.find("readFirst");
    if (rf == e.end() || !rf->is_array())
        return at(source, base + "/readFirst", "\"readFirst\" must be a list of docs",
                  R"(Add "readFirst": ["docs/SCRIPTING.md"] (an empty list is allowed).)");
    if (rf->size() > kMaxReadFirst)
        return at(source, base + "/readFirst", "more than " + std::to_string(kMaxReadFirst) + " docs to read first",
                  "Keep the docs that matter before opening the project; the README of the example lists the rest.");
    for (std::size_t i = 0; i < rf->size(); ++i) {
        const Json& d = (*rf)[i];
        const std::string pointer = base + "/readFirst/" + std::to_string(i);
        if (!d.is_string() || !valid_doc_path(d.get<std::string>()))
            return at(source, pointer, "expected a doc path like \"docs/SCRIPTING.md\", got " + describe_json_value(d),
                      "Write the path of a file of docs/ (read it with `factoria docs read SCRIPTING`).");
        x.readFirst.push_back(d.get<std::string>());
    }
    const bool hasRelease = e.contains("file") || e.contains("size") || e.contains("sha256");
    if (!release) {
        if (hasRelease)
            return at(
                source,
                base + (e.contains("file")   ? "/file"
                        : e.contains("size") ? "/size"
                                             : "/sha256"),
                "the source manifest does not hold file, size or sha256",
                "Remove them: `project.package_examples` computes them and writes them to examples-manifest.json.");
        return x;
    }
    auto file = string_member(e, "file", source, base, R"("file": "block-push.zip")");
    if (!file.ok()) return file.error();
    x.file = *file;
    if (!plain_file_name(x.file) || x.file.size() < 5 || x.file.substr(x.file.size() - 4) != ".zip")
        return at(source, base + "/file", "\"" + x.file + "\" is not the plain name of a zip",
                  "Write a file name ending in .zip, without a folder: \"" + x.name + ".zip\".");
    auto size = e.find("size");
    if (size == e.end() || !size->is_number_unsigned() || size->get<std::uint64_t>() == 0)
        return at(source, base + "/size", "\"size\" must be the size of the zip in bytes (a whole number above 0)",
                  "Add \"size\": 123456. `project.package_examples` writes it.");
    x.size = size->get<std::uint64_t>();
    auto sha = string_member(e, "sha256", source, base, R"("sha256": "<64 lowercase hex digits>")");
    if (!sha.ok()) return sha.error();
    x.sha256 = *sha;
    if (!is_hex64(x.sha256))
        return at(source, base + "/sha256", "\"sha256\" must be 64 lowercase hex digits",
                  "It is the SHA-256 of the zip; `project.package_examples` writes it.");
    return x;
}

Result<std::vector<ExampleInfo>> parse_list(const Json& root, std::string_view source, bool release) {
    auto it = root.find("examples");
    if (it == root.end() || !it->is_array())
        return at(source, "/examples", "\"examples\" must be a list",
                  "Add \"examples\": [{\"name\": \"block-push\", ...}].");
    if (it->size() > kMaxExamples)
        return at(source, "/examples", "more than " + std::to_string(kMaxExamples) + " examples",
                  "A manifest this long was not made by `project.package_examples`.");
    std::vector<ExampleInfo> out;
    std::set<std::string> seen;
    for (std::size_t i = 0; i < it->size(); ++i) {
        const std::string base = "/examples/" + std::to_string(i);
        auto x = parse_example((*it)[i], source, base, release);
        if (!x.ok()) return x.error();
        if (!seen.insert(x->name).second)
            return at(source, base + "/name", "the example \"" + x->name + "\" is listed twice",
                      "Keep one entry per example.");
        out.push_back(std::move(*x));
    }
    return out;
}

}  // namespace

// ---- manifests ------------------------------------------------------------------------------------------------------------

Json ExampleInfo::to_json() const {
    Json j = Json::object({{"name", name}, {"title", title}, {"shows", shows}, {"readFirst", Json::array()}});
    for (const std::string& d : readFirst) j["readFirst"].push_back(d);
    if (!file.empty()) {
        j["file"] = file;
        j["size"] = size;
        j["sha256"] = sha256;
    }
    return j;
}

Json ExamplesManifest::to_json() const {
    Json list = Json::array();
    for (const ExampleInfo& e : examples) list.push_back(e.to_json());
    return Json::object({{"format", format}, {"engineVersion", engineVersion}, {"examples", list}});
}

Result<ExampleInfo> ExamplesManifest::find(const std::string& name) const {
    std::vector<std::string> names;
    for (const ExampleInfo& e : examples) {
        if (e.name == name) return e;
        names.push_back(e.name);
    }
    return make_error("There is no example called '" + name + "' in the release " + engineVersion + ". " +
                          (names.empty() ? std::string("The release lists none.") : did_you_mean(name, names)),
                      "Ask for `project.examples` to list the examples this version has.");
}

Result<ExamplesManifest> parse_examples_manifest(std::string_view text, std::string_view source) {
    auto root = parse_json(text, source);
    if (!root.ok())
        return make_error(root.error().message, "The file must be the examples-manifest.json asset of the release.");
    if (auto f = check_format(*root, kExamplesManifestFormat, source); !f.ok()) return f.error();
    ExamplesManifest m;
    m.format = kExamplesManifestFormat;
    auto ver = string_member(*root, "engineVersion", source, "", R"("engineVersion": "0.30.0")");
    if (!ver.ok()) return ver.error();
    m.engineVersion = *ver;
    if (!valid_version_text(m.engineVersion))
        return at(source, "/engineVersion", "\"" + m.engineVersion + "\" is not a version",
                  "Write the version of the release, like \"0.30.0\".");
    auto list = parse_list(*root, source, true);
    if (!list.ok()) return list.error();
    m.examples = std::move(*list);
    return m;
}

Result<std::vector<ExampleInfo>> parse_examples_source(std::string_view text, std::string_view source) {
    auto root = parse_json(text, source);
    if (!root.ok()) return make_error(root.error().message, "Fix the JSON of examples/examples.json.");
    if (auto f = check_format(*root, kExamplesSourceFormat, source); !f.ok()) return f.error();
    return parse_list(*root, source, false);
}

// ---- URLs and checks ------------------------------------------------------------------------------------------------------

std::string examples_release_tag(std::string_view version) {
    if (!version.empty() && version[0] == 'v') return std::string(version);
    return "v" + std::string(version);
}

std::string examples_asset_url(std::string_view version, std::string_view file) {
    std::string v(version);
    if (!v.empty() && v[0] == 'v') v.erase(0, 1);
    if (!valid_version_text(v) || !plain_file_name(file)) return {};
    return std::string("https://github.com/") + kSetupReleaseRepo + "/releases/download/" + examples_release_tag(v) +
           "/" + std::string(file);
}

std::string examples_manifest_url(std::string_view version) {
    return examples_asset_url(version, kExamplesManifestFile);
}

Result<void> verify_example_bytes(const ExampleInfo& example, std::string_view bytes) {
    if (bytes.size() != example.size)
        return make_error(
            "The download of the example '" + example.name + "' is " + std::to_string(bytes.size()) +
                " bytes, and the release says " + std::to_string(example.size) + ". It is damaged or incomplete.",
            "Download it again; if it happens twice, report it with `feedback.submit`: the release asset is wrong.");
    const std::string hash = sha256_hex(bytes);
    if (hash != example.sha256)
        return make_error(
            "The download of the example '" + example.name + "' does not match the release: its SHA-256 is " + hash +
                ", the manifest says " + example.sha256 + ".",
            "Nothing was unpacked. Download it again; if it happens twice, report it with `feedback.submit`.");
    return {};
}

Result<void> verify_example_file(const ExampleInfo& example, const stdfs::path& zip) {
    std::error_code ec;
    const auto size = stdfs::file_size(fs::os_path(zip), ec);
    if (ec)
        return make_error("Cannot read the downloaded example '" + example.name + "' at " + fs::path_to_utf8(zip) +
                              ": " + ec.message() + ".",
                          "Download it again.");
    if (size != example.size)
        return make_error(
            "The download of the example '" + example.name + "' is " + std::to_string(size) +
                " bytes, and the release says " + std::to_string(example.size) + ". It is damaged or incomplete.",
            "Download it again; if it happens twice, report it with `feedback.submit`: the release asset is wrong.");
    auto hash = sha256_file_hex(fs::os_path(zip));
    if (!hash.ok()) return hash.error();
    if (*hash != example.sha256)
        return make_error(
            "The download of the example '" + example.name + "' does not match the release: its SHA-256 is " + *hash +
                ", the manifest says " + example.sha256 + ".",
            "Nothing was unpacked. Download it again; if it happens twice, report it with `feedback.submit`.");
    return {};
}

// ---- packaging ------------------------------------------------------------------------------------------------------------

namespace {

bool ends_with_text(const std::string& s, std::string_view suffix) {
    return s.size() > suffix.size() && s.compare(s.size() - suffix.size(), suffix.size(), suffix) == 0;
}

// What the OS, the tests and a developer's machine leave in a project folder: never part of an example. The secrets and local
// settings a developer keeps next to a project (.env, keys, keystores, ai.local.json) must never be published, whatever is in
// the folder the release job packs.
bool left_out_file(const std::string& name) {
    if (name == ".DS_Store" || name == "Thumbs.db" || name == "desktop.ini" || name == ".env" ||
        name == "ai.local.json")
        return true;
    for (const char* suffix : {".actual.png", ".fa-tmp", ".key", ".keystore", ".jks", ".p12", ".pem"})
        if (ends_with_text(name, suffix)) return true;
    return false;
}

// Same rule as checkpoints and project.validate: hidden folders, node_modules and a top-level build/.
bool left_out_dir(const std::string& name, bool topLevel) {
    return name == "node_modules" || (topLevel && name == "build") || (!name.empty() && name[0] == '.');
}

std::string utf8_relative(const stdfs::path& rel) { return fs::path_to_utf8(rel); }  // forward slashes

}  // namespace

Result<std::vector<std::string>> example_zip_files(const stdfs::path& dir) {
    std::vector<std::string> out;
    const stdfs::path root = fs::os_path(dir);
    auto fail = [&](const std::error_code& ec, const stdfs::path& at) {
        return make_error("Cannot list the files of the example folder " + fs::path_to_utf8(dir) + " (at " +
                              fs::path_to_utf8(at) + "): " + ec.message() + ".",
                          "Check that the folder exists and can be read; nothing was packed.");
    };
    std::error_code ec;
    stdfs::recursive_directory_iterator it(root, ec), end;
    if (ec) return fail(ec, root);
    for (; it != end; it.increment(ec)) {
        if (ec) return fail(ec, root);
        const stdfs::path rel = it->path().lexically_relative(root);
        const std::string name = utf8_relative(rel.filename());
        const bool link = it->is_symlink(ec);  // a link may point out of the example: never followed, never packed
        if (ec) return fail(ec, it->path());
        if (link) {
            if (it->is_directory(ec)) it.disable_recursion_pending();
            continue;
        }
        const bool isDir = it->is_directory(ec);
        if (ec) return fail(ec, it->path());
        if (isDir) {
            if (left_out_dir(name, !rel.has_parent_path())) it.disable_recursion_pending();
            continue;
        }
        const bool regular = it->is_regular_file(ec);
        if (ec) return fail(ec, it->path());
        if (regular && !left_out_file(name)) out.push_back(utf8_relative(rel));
    }
    std::sort(out.begin(), out.end());
    return out;
}

Result<void> package_example_zip(const stdfs::path& dir, const stdfs::path& zipFile) {
    std::error_code ec;
    if (!stdfs::exists(fs::os_path(dir / kProjectFileName), ec))
        return make_error(fs::path_to_utf8(dir) + " is not a FactorIA project: factoria.json is missing.",
                          "Pack the folder of one project, the one that holds factoria.json.");
    auto listed = example_zip_files(dir);
    if (!listed.ok()) return listed.error();
    const std::vector<std::string>& files = *listed;
    if (files.empty()) return make_error(fs::path_to_utf8(dir) + " has no files to pack.", "Check the folder.");
    stdfs::create_directories(fs::os_path(zipFile.parent_path()), ec);
    export_detail::ZipWriter zip(zipFile);
    for (const std::string& rel : files) {
        std::ifstream in(fs::os_path(dir / fs::path_from_utf8(rel)), std::ios::binary);
        if (!in)
            return make_error("Cannot read " + rel + " in " + fs::path_to_utf8(dir) + ".",
                              "Close what has it open and try again.");
        const std::string data((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
        if (in.bad())
            return make_error("Cannot read " + rel + " in " + fs::path_to_utf8(dir) + ".",
                              "Check the disk and try again.");
        if (auto a = zip.add(rel, data, true); !a.ok()) return a.error();
    }
    return zip.finish();
}

Result<ExamplesManifest> package_examples(const stdfs::path& examplesDir, const stdfs::path& outDir,
                                          const std::string& engineVersion, const std::vector<std::string>& only) {
    if (!valid_version_text(engineVersion))
        return make_error("\"" + engineVersion + "\" is not a version.",
                          "Pass the version of the release, like \"0.30.0\".");
    const stdfs::path sourceFile = examplesDir / kExamplesSourceFile;
    auto text = tooling_detail::read_file(fs::os_path(sourceFile));
    if (!text)
        return make_error(
            "Cannot read " + fs::path_to_utf8(sourceFile) + ".",
            "Pass the folder that holds the examples (`examples` in the repository) and its examples.json.");
    auto source = parse_examples_source(*text, fs::path_to_utf8(sourceFile));
    if (!source.ok()) return source.error();

    // Every project folder has an entry and every entry a folder: a release never leaves an example out by accident.
    std::set<std::string> folders, entries;
    std::error_code ec;
    auto cannot_list = [&](const stdfs::path& at) {
        return make_error("Cannot list the example folders in " + fs::path_to_utf8(examplesDir) + " (at " +
                              fs::path_to_utf8(at) + "): " + ec.message() + ".",
                          "Check that the folder exists and can be read; nothing was packed.");
    };
    stdfs::directory_iterator dit(fs::os_path(examplesDir), ec), dend;
    if (ec) return cannot_list(examplesDir);
    for (; dit != dend; dit.increment(ec)) {
        if (ec) return cannot_list(examplesDir);
        const bool isDir = dit->is_directory(ec);
        if (ec) return cannot_list(dit->path());
        if (!isDir) continue;
        const bool hasProject = stdfs::exists(dit->path() / kProjectFileName, ec);
        if (ec) return cannot_list(dit->path());
        if (hasProject) folders.insert(utf8_relative(dit->path().filename()));
    }
    for (const ExampleInfo& e : *source) entries.insert(e.name);
    for (const std::string& f : folders)
        if (!entries.count(f))
            return make_error(
                "examples/" + f + " has no entry in " + fs::path_to_utf8(sourceFile) + ".",
                "Add {\"name\": \"" + f +
                    "\", \"title\": ..., \"shows\": ..., \"readFirst\": [...]} to its \"examples\" list.");
    for (const std::string& n : entries)
        if (!folders.count(n))
            return make_error(fs::path_to_utf8(sourceFile) + " lists \"" + n + "\", but there is no project folder " +
                                  fs::path_to_utf8(examplesDir / n) + ".",
                              "Remove the entry, or fix its name (" +
                                  did_you_mean(n, std::vector<std::string>(folders.begin(), folders.end())) + ").");
    for (const std::string& n : only)
        if (!entries.count(n))
            return make_error("There is no example called '" + n + "'. " +
                                  did_you_mean(n, std::vector<std::string>(entries.begin(), entries.end())),
                              "Leave `only` out to pack all of them.");

    ExamplesManifest m;
    m.format = kExamplesManifestFormat;
    m.engineVersion = engineVersion;
    stdfs::create_directories(fs::os_path(outDir), ec);
    if (ec)
        return make_error("Cannot create " + fs::path_to_utf8(outDir) + ": " + ec.message() + ".",
                          "Check the folder and its permissions.");
    std::vector<ExampleInfo> sorted = *source;
    std::sort(sorted.begin(), sorted.end(), [](const ExampleInfo& a, const ExampleInfo& b) { return a.name < b.name; });
    for (ExampleInfo e : sorted) {
        if (!only.empty() && std::find(only.begin(), only.end(), e.name) == only.end()) continue;
        e.file = e.name + ".zip";
        const stdfs::path zip = outDir / e.file;
        if (auto r = package_example_zip(examplesDir / e.name, zip); !r.ok()) return r.error();
        std::error_code e2;
        e.size = stdfs::file_size(fs::os_path(zip), e2);
        if (e2)
            return make_error("Cannot measure " + fs::path_to_utf8(zip) + ": " + e2.message() + ".", "Check the disk.");
        auto h = sha256_file_hex(fs::os_path(zip));
        if (!h.ok()) return h.error();
        e.sha256 = *h;
        m.examples.push_back(std::move(e));
    }
    const std::string json = m.to_json().dump(2) + "\n";
    std::string werr;
    if (!tooling_detail::write_file(outDir / kExamplesManifestFile, json, &werr))
        return make_error("Cannot write " + fs::path_to_utf8(outDir / kExamplesManifestFile) +
                              (werr.empty() ? "" : ": " + werr) + ".",
                          "Check the folder and the disk.");
    return m;
}

// ---- the command ----------------------------------------------------------------------------------------------------------

void register_examples_commands(CommandRegistry& registry) {
    CommandInfo c;
    c.name = "project.package_examples";
    c.category = "project";
    c.readOnly = false;
    c.summary = "Zip every example game of examples/ and write examples-manifest.json, the files a release publishes.";
    c.description =
        "For the engine's release (docs/design/BUILDING.md, \"Example games in the release\"). Reads "
        "`examples`/examples.json "
        "(the title, what each example shows and the docs to read first), checks that every project folder has an "
        "entry and "
        "every entry a folder, writes <name>.zip per example into `out` (the project without .factoria/ and every "
        "other "
        "hidden folder, node_modules/, a top-level build/, .DS_Store, Thumbs.db, desktop.ini, *.actual.png, *.fa-tmp "
        "and the "
        "secrets and local settings .env, ai.local.json, *.key, *.keystore, *.jks, *.p12 and *.pem; a link is never "
        "followed; the same files give the same bytes) and examples-manifest.json beside them "
        "(format, engineVersion, and per example name, title, shows, readFirst, file, size and sha256). Replaces files "
        "of "
        "the same names in `out`. Returns the manifest. Run it from a checkout of the repository: a download has no "
        "examples/. Example: {\"examples\":\"examples\",\"out\":\"dist/examples\"}.";
    c.inputSchema = Json::parse(R"({"type":"object","required":["out"],"properties":{
        "examples":{"type":"string","description":"The folder that holds the example projects and examples.json (default: examples, relative to the current directory).","default":"examples"},
        "out":{"type":"string","description":"The folder the zips and examples-manifest.json are written to (created)."},
        "only":{"type":"array","items":{"type":"string"},"description":"Pack only these examples (default: all)."},
        "version":{"type":"string","description":"The engine version written to the manifest (default: this factoria's version)."}}})");
    registry.add(c, [](const Json& a) {
        const std::string examples = tooling_detail::arg_string(a, "examples", false, "examples");
        const std::string out = tooling_detail::arg_string(a, "out", true);
        std::string version = tooling_detail::arg_string(a, "version", false);
        if (version.empty()) version = engine_version();
        std::vector<std::string> only;
        if (auto it = a.find("only"); it != a.end()) {
            if (!it->is_array())
                throw CommandError("invalid_argument", "/only must be a list of example names.",
                                   "Write [\"block-push\"].");
            for (const Json& n : *it) {
                if (!n.is_string())
                    throw CommandError("invalid_argument", "/only must be a list of example names.",
                                       "Write [\"block-push\"].");
                only.push_back(n.get<std::string>());
            }
        }
        auto r = package_examples(fs::path_from_utf8(examples), fs::path_from_utf8(out), version, only);
        if (!r.ok()) throw CommandError("failed", r.error().message, r.error().hint);
        return r->to_json();
    });

    CommandInfo l;
    l.name = "project.examples";
    l.category = "project";
    l.readOnly = true;
    l.summary = "List the example games of the installed FactorIA version: what each shows and the docs to read first.";
    l.description =
        "The download of FactorIA carries no example games; every release publishes them as assets. This downloads "
        "examples-manifest.json of the release of the INSTALLED version (a few KB), keeps a copy in <FACTORIA_HOME or "
        "~/.factoria>/cache/examples/<version>/ and returns, per example, `name`, `title`, `shows` (what it shows), "
        "`readFirst` "
        "(docs to read before opening it: `docs.read` them), `size` (bytes to download) and `downloaded` (its zip is "
        "already in "
        "the cache). `stale` is true, and `staleReason` says why, when the network failed and the copy of an earlier "
        "call is "
        "returned: the list may then be older than the release. With no network and no copy it fails and says what to "
        "do. "
        "Create a project from one with project.create {example}. Example: {}.";
    l.inputSchema = Json::parse(R"({"type":"object","properties":{}})");
    registry.add(l, [](const Json&) {
        auto r = list_examples(examples_context());
        if (!r.ok()) throw CommandError("failed", r.error().message, r.error().hint);
        return r->to_json();
    });
    // package_examples reads and writes folders the caller names, anywhere: not for an agent that may write only inside its
    // project. project.examples reads the release over the network and keeps a copy in FactorIA's own cache folder (never a
    // path the caller chooses), so it is {read, network}.
    declare_command_capabilities(
        registry, {{"project.package_examples", CapabilitySet{Capability::Read, Capability::WriteAnywhere}},
                   {"project.examples", CapabilitySet{Capability::Read, Capability::Network}}});
}

}  // namespace fa
