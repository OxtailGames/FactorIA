// Getting an example game (fa/tooling/examples.h, "Getting an example"): the list of the installed version's release, the download
// of one zip, its safe unpacking and the project created from it. docs/design/BUILDING.md, "Example games in the release".
#include <algorithm>
#include <atomic>
#include <cstdlib>
#include <map>
#include <mutex>
#include <set>

#include "export_zip.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/runtime/project.h"
#include "fa/tooling/examples.h"
#include "fa/tooling/setup_parse.h"
#include "setup_internal.h"
#include "util.h"

#if defined(_WIN32)
#include <process.h>
#else
#include <unistd.h>
#endif

namespace fa {

namespace stdfs = std::filesystem;

namespace {

constexpr std::uint64_t kMaxManifestBytes = 1ull << 20;  // the real one is ~5 KB
constexpr std::uint64_t kMaxZipBytes = 512ull << 20;     // the biggest example is 26 MB

int process_number() {
#if defined(_WIN32)
    return _getpid();
#else
    return int(::getpid());
#endif
}

std::string unique_suffix() {
    static std::atomic<int> counter{0};
    return std::to_string(process_number()) + "-" + std::to_string(++counter);
}

std::mutex g_contextMutex;
std::optional<SetupContext> g_context;

// The installed version without a leading "v" ("" when it is not one a release can have).
std::string installed_version(const SetupContext& ctx) {
    std::string v = ctx.version();
    if (!v.empty() && v[0] == 'v') v.erase(0, 1);
    return v;
}

// A file or folder that is removed when it goes out of scope (a download that failed, the staging folder of an unpack).
struct Scratch {
    stdfs::path path;
    bool isDir = false;
    ~Scratch() { release(); }
    void release() {
        if (path.empty()) return;
        std::error_code ec;
        if (isDir)
            fs::remove_tree(fs::os_path(path), ec);
        else
            stdfs::remove(fs::os_path(path), ec);
        path.clear();
    }
    void keep() { path.clear(); }
};

Error not_released(const std::string& what, const std::string& url) {
    return make_error("The release has no " + what + ": the server answered HTTP 404 for " + url + ".",
                      "A release made before the example games were published has none, and so has a development build that "
                      "no release matches. Update FactorIA (Help > Check for updates, or download it again), or use the "
                      "examples/ folder of a clone of the repository.");
}

// Downloads `url` into the file `scratch.path` (a new name in the cache folder) through ctx.fetch and checks its size against `maxBytes`.
Result<void> fetch_to(const SetupContext& ctx, const std::string& url, const stdfs::path& cacheDir, const std::string& what,
                      std::uint64_t expectedBytes, std::uint64_t maxBytes, const std::string& fileName, Scratch& scratch,
                      bool* cancelled) {
    if (!is_trusted_download_url(url))
        return make_error("The address " + url + " is not one FactorIA downloads from.", "This is a bug; please report it.");
    std::error_code ec;
    stdfs::create_directories(fs::os_path(cacheDir), ec);
    if (ec)
        return make_error("Cannot create the folder " + fs::path_to_utf8(cacheDir) + " for the downloaded example games: " +
                              ec.message() + ".",
                          "Check that the folder can be written, or set FACTORIA_HOME to one that can.");
    scratch.path = cacheDir / (fileName + "." + unique_suffix() + ".fa-tmp");
    scratch.isDir = false;
    DownloadRequest rq;
    rq.url = url;
    rq.destination = fs::path_to_utf8(scratch.path);
    rq.expectedBytes = expectedBytes;
    rq.what = what;
    rq.onBytes = [&ctx, what, expectedBytes](std::uint64_t got) {
        if (expectedBytes != 0)
            ctx.say("Downloading " + what + ": " + std::to_string(std::min<std::uint64_t>(100, got * 100 / expectedBytes)) + "%");
    };
    ctx.say("Downloading " + what + "...");
    const DownloadResult r = ctx.fetch(rq);
    if (cancelled) *cancelled = r.cancelled || is_cancelled(ctx.cancel);
    if (!r.ok) {
        scratch.release();
        if (r.httpStatus == 404) return not_released(what, url);
        return r.error;
    }
    const auto size = stdfs::file_size(fs::os_path(scratch.path), ec);
    if (ec) {
        scratch.release();
        return make_error("The download of " + what + " left no file: " + ec.message() + ".", "Try again.");
    }
    if (size > maxBytes) {
        scratch.release();
        return make_error("The download of " + what + " is " + std::to_string(size) + " bytes, more than the " +
                              std::to_string(maxBytes) + " a release has.",
                          "Nothing was kept. Try again; if it happens twice, report it with `feedback.submit`.");
    }
    return {};
}

Result<ExamplesManifest> read_manifest_file(const stdfs::path& file, const std::string& version) {
    std::error_code ec;
    const auto size = stdfs::file_size(fs::os_path(file), ec);
    if (ec) return make_error("Cannot read " + fs::path_to_utf8(file) + ": " + ec.message() + ".", "Download the list again.");
    if (size > kMaxManifestBytes)
        return make_error(fs::path_to_utf8(file) + " is " + std::to_string(size) + " bytes: too big for a list of examples.",
                          "Download the list again.");
    auto text = tooling_detail::read_file(fs::os_path(file));
    if (!text) return make_error("Cannot read " + fs::path_to_utf8(file) + ".", "Download the list again.");
    auto m = parse_examples_manifest(*text, fs::path_to_utf8(file));
    if (!m.ok()) return m.error();
    if (m->engineVersion != version)
        return make_error(fs::path_to_utf8(file) + " is the list of the release " + m->engineVersion + ", and this FactorIA is " +
                              version + ".",
                          "Download the list again.");
    return m;
}

std::vector<std::string> downloaded_zips(const ExamplesManifest& m, const stdfs::path& cacheDir) {
    std::vector<std::string> names;
    for (const ExampleInfo& e : m.examples) {
        std::error_code ec;
        const auto size = stdfs::file_size(fs::os_path(cacheDir / e.file), ec);
        if (!ec && size == e.size) names.push_back(e.name);
    }
    return names;
}

std::string one_line(const Error& e) { return e.hint.empty() ? e.message : e.message + " " + e.hint; }

}  // namespace

// ---- the context ----------------------------------------------------------------------------------------------------------

SetupContext examples_context() {
    std::lock_guard<std::mutex> lock(g_contextMutex);
    return g_context ? *g_context : SetupContext{};
}

void set_examples_context(std::optional<SetupContext> ctx) {
    std::lock_guard<std::mutex> lock(g_contextMutex);
    g_context = std::move(ctx);
}

stdfs::path examples_cache_dir(const SetupContext& ctx) {
    return fs::path_from_utf8(ctx.home_dir()) / "cache" / "examples" / installed_version(ctx);
}

// ---- the list -------------------------------------------------------------------------------------------------------------

Json ExamplesList::to_json() const {
    Json list = Json::array();
    for (const ExampleInfo& e : manifest.examples) {
        Json item = Json::object({{"name", e.name}, {"title", e.title}, {"shows", e.shows}, {"readFirst", Json::array()},
                                  {"size", e.size},
                                  {"downloaded", std::find(downloaded.begin(), downloaded.end(), e.name) != downloaded.end()}});
        for (const std::string& d : e.readFirst) item["readFirst"].push_back(d);
        list.push_back(std::move(item));
    }
    Json j = Json::object({{"engineVersion", manifest.engineVersion},
                           {"source", stale ? "cache" : "network"},
                           {"stale", stale},
                           {"cacheDir", cacheDir},
                           {"examples", list},
                           {"next", "project.create {\"example\": \"<name>\", \"dir\": \"<folder>\"} makes a project from one; "
                                    "read its \"readFirst\" docs with `docs.read`."}});
    if (stale) j["staleReason"] = staleReason;
    return j;
}

std::optional<ExamplesList> cached_examples(const SetupContext& ctx) {
    const std::string version = installed_version(ctx);
    const stdfs::path dir = examples_cache_dir(ctx);
    auto m = read_manifest_file(dir / kExamplesManifestFile, version);
    if (!m.ok()) return std::nullopt;
    ExamplesList out;
    out.stale = true;
    out.staleReason = "this is the copy saved by an earlier call";
    out.cacheDir = fs::path_to_utf8(dir);
    out.downloaded = downloaded_zips(*m, dir);
    out.manifest = std::move(*m);
    return out;
}

Result<ExamplesList> list_examples(const SetupContext& ctx) {
    const std::string version = installed_version(ctx);
    const std::string url = examples_manifest_url(version);
    if (url.empty())
        return make_error("This FactorIA reports the version \"" + ctx.version() + "\", which no release has.",
                          "Install a released version of FactorIA to download its example games.");
    const stdfs::path dir = examples_cache_dir(ctx);
    const stdfs::path cached = dir / kExamplesManifestFile;

    Scratch scratch;
    bool cancelled = false;
    std::string why;
    auto got = fetch_to(ctx, url, dir, "the list of example games of FactorIA " + version, 0, kMaxManifestBytes,
                        kExamplesManifestFile, scratch, &cancelled);
    if (got.ok()) {
        auto m = read_manifest_file(scratch.path, version);
        if (m.ok()) {
            ExamplesList out;
            out.cacheDir = fs::path_to_utf8(dir);
            out.downloaded = downloaded_zips(*m, dir);
            out.manifest = std::move(*m);
            std::error_code ec;  // keep the copy for the next call; a failure only costs the offline list
            stdfs::rename(fs::os_path(scratch.path), fs::os_path(cached), ec);
            if (!ec) scratch.keep();
            return out;
        }
        why = one_line(m.error());
    } else {
        why = one_line(got.error());
    }
    scratch.release();
    if (cancelled) return make_error("Listing the example games was cancelled.", "Run it again.");

    if (auto old = cached_examples(ctx)) {
        old->staleReason = why;
        return *old;
    }
    return make_error("Cannot list the example games of FactorIA " + version + ": " + why +
                          " There is no saved copy of the list to show instead, and the base download of FactorIA carries no example "
                          "games: they are downloaded from the GitHub release when asked for.",
                      "Connect to the internet and run `project.examples` again (it keeps a copy of the list in " +
                          fs::path_to_utf8(dir) + ", so later calls work offline), or use the examples/ folder of a clone of the "
                          "repository.");
}

// ---- unpacking ------------------------------------------------------------------------------------------------------------

namespace {

std::string ascii_lower(std::string s) {
    for (char& c : s)
        if (c >= 'A' && c <= 'Z') c = static_cast<char>(c - 'A' + 'a');
    return s;
}

// A name with the characters that cannot be shown safely replaced, for messages.
std::string printable(const std::string& s) {
    std::string out;
    for (char c : s) out += (static_cast<unsigned char>(c) < 0x20 || c == 0x7f) ? '?' : c;
    return out.size() > 120 ? out.substr(0, 117) + "..." : out;
}

bool windows_device_name(const std::string& part) {
    std::string stem = ascii_lower(part.substr(0, part.find('.')));
    while (!stem.empty() && stem.back() == ' ') stem.pop_back();
    if (stem == "con" || stem == "prn" || stem == "aux" || stem == "nul" || stem == "conin$" || stem == "conout$") return true;
    return stem.size() == 4 && (stem.compare(0, 3, "com") == 0 || stem.compare(0, 3, "lpt") == 0) && stem[3] >= '0' && stem[3] <= '9';
}

// "" when the entry name can be unpacked; else why it cannot.
std::string unsafe_name_reason(const std::string& name) {
    if (name.empty()) return "it is empty";
    if (name.size() > 240) return "it is longer than 240 bytes";
    if (!is_valid_utf8(name)) return "it is not valid UTF-8";
    for (char c : name)
        if (static_cast<unsigned char>(c) < 0x20 || c == 0x7f) return "it holds a control character";
    if (name.find('\\') != std::string::npos) return "it holds a backslash";
    if (name[0] == '/') return "it is an absolute path";
    if (name.find(':') != std::string::npos) return "it holds a ':' (a drive letter or a data stream)";
    if (name.find_first_of("<>\"|?*") != std::string::npos) return "it holds a character Windows does not allow";
    std::string path = name;
    if (path.back() == '/') path.pop_back();
    for (const std::string& part : split(path, '/', false)) {
        if (part.empty()) return "it has an empty part (\"//\")";
        if (part == "..") return "it goes up a folder (\"..\")";
        if (part == ".") return "it has a \".\" part";
        if (part.back() == '.' || part.back() == ' ') return "a part ends in a dot or a space, which Windows drops";
        if (windows_device_name(part)) return "a part is the name of a Windows device (" + part + ")";
    }
    return "";
}

Error unsafe(const std::string& name, const std::string& reason) {
    return make_error("The zip of the example holds an entry that is not safe to unpack: \"" + printable(name) + "\" (" + reason + ").",
                      "Nothing was unpacked. If the zip came from FactorIA's release, report it with `feedback.submit`: "
                      "`project.package_examples` never writes such a name.");
}

}  // namespace

Result<std::vector<std::string>> extract_example_zip(const stdfs::path& zip, const stdfs::path& destination,
                                                     const ExampleExtractLimits& limits) {
    auto entries = export_detail::zip_entries(zip);
    if (!entries.ok())
        return make_error("Cannot read the example zip " + fs::path_to_utf8(zip) + ": " + entries.error().message,
                          "Download it again; if it happens twice, report it with `feedback.submit`.");
    if (entries->size() > limits.maxEntries)
        return make_error("The zip of the example has " + std::to_string(entries->size()) + " entries, more than the " +
                              std::to_string(limits.maxEntries) + " that are unpacked.",
                          "Nothing was unpacked. If it came from FactorIA's release, report it with `feedback.submit`.");

    // 1. Every name and every size is checked before one byte is written.
    stdfs::path root = fs::os_path(destination).lexically_normal();
    std::map<std::string, std::string> files;  // folded path -> the name as stored
    std::map<std::string, std::string> dirs;
    std::uint64_t total = 0;
    bool hasProject = false;
    for (const export_detail::ZipEntryInfo& e : *entries) {
        if (auto why = unsafe_name_reason(e.name); !why.empty()) return unsafe(e.name, why);
        if (e.encrypted) return unsafe(e.name, "it is encrypted");
        if (e.symlink) return unsafe(e.name, "it is a symbolic link");
        if (e.special) return unsafe(e.name, "it is not a file or a folder");
        if (e.size > limits.maxEntryBytes)
            return make_error("The entry \"" + printable(e.name) + "\" of the example zip is " + std::to_string(e.size) +
                                  " bytes, more than the " + std::to_string(limits.maxEntryBytes) + " that are unpacked.",
                              "Nothing was unpacked. If it came from FactorIA's release, report it with `feedback.submit`.");
        total += e.size;
        if (total > limits.maxTotalBytes)
            return make_error("The example zip unpacks to more than " + std::to_string(limits.maxTotalBytes) + " bytes.",
                              "Nothing was unpacked. If it came from FactorIA's release, report it with `feedback.submit`.");
        const std::string path = e.directory ? e.name.substr(0, e.name.size() - 1) : e.name;
        const stdfs::path target = (root / fs::path_from_utf8(path)).lexically_normal();
        const stdfs::path rel = target.lexically_relative(root);
        if (rel.empty() || *rel.begin() == "..") return unsafe(e.name, "it would be written outside the folder of the project");
        // Every folder on the way is a folder; the entry itself is a file or a folder, once.
        std::string prefix;
        for (const std::string& part : split(path, '/', false)) {
            prefix += (prefix.empty() ? "" : "/") + part;
            const bool last = prefix.size() == path.size();
            const std::string key = ascii_lower(prefix);
            if (!last || e.directory) {
                if (auto f = files.find(key); f != files.end())
                    return unsafe(e.name, "it is also a file (\"" + printable(f->second) + "\")");
                dirs.emplace(key, e.name);
            }
        }
        if (!e.directory) {
            const std::string key = ascii_lower(path);
            if (auto d = dirs.find(key); d != dirs.end())
                return unsafe(e.name, "it is also a folder (\"" + printable(d->second) + "\")");
            auto [it, fresh] = files.emplace(key, e.name);
            if (!fresh)
                return unsafe(e.name, it->second == e.name ? "the zip holds it twice"
                                                           : "it differs only in capitals from \"" + printable(it->second) +
                                                                 "\", so one would replace the other on Windows and macOS");
            if (path == kProjectFileName) hasProject = true;
        }
    }
    if (!hasProject)
        return make_error("The zip of the example has no " + std::string(kProjectFileName) + " at its top: it is not a project.",
                          "Nothing was unpacked. If it came from FactorIA's release, report it with `feedback.submit`.");

    // 2. Write.
    std::error_code ec;
    stdfs::create_directories(root, ec);
    if (ec)
        return make_error("Cannot create " + fs::path_to_utf8(destination) + ": " + ec.message() + ".",
                          "Check the folder and its permissions.");
    std::vector<std::string> written;
    auto r = export_detail::zip_each_entry(zip, limits.maxEntryBytes, [&](const export_detail::ZipEntryInfo& e, std::string&& data) -> Result<void> {
        const std::string path = e.directory ? e.name.substr(0, e.name.size() - 1) : e.name;
        const stdfs::path target = root / fs::path_from_utf8(path);
        if (e.directory) {
            std::error_code dec;
            stdfs::create_directories(target, dec);
            if (dec) return make_error("Cannot create " + fs::path_to_utf8(target) + ": " + dec.message() + ".", "Check the folder.");
            return {};
        }
        auto w = fs::write_bytes(fs::path_to_utf8(target), data.data(), data.size());
        if (!w.ok()) return make_error("Cannot write " + fs::path_to_utf8(target) + ": " + w.error().message, "Check the free disk space and the folder's permissions.");
        written.push_back(path);
        return {};
    });
    if (!r.ok())
        return make_error("Cannot unpack the example zip " + fs::path_to_utf8(zip) + ": " + r.error().message,
                          r.error().hint.empty() ? "Download it again; if it happens twice, report it with `feedback.submit`."
                                                 : r.error().hint);
    std::sort(written.begin(), written.end());
    return written;
}

// ---- creating a project -----------------------------------------------------------------------------------------------------

namespace {

Result<void> patch_project_file(const stdfs::path& dir, const ScaffoldOptions& options) {
    if (options.name.empty() && options.id.empty()) return {};
    const stdfs::path file = dir / kProjectFileName;
    auto text = tooling_detail::read_file(fs::os_path(file));
    if (!text) return make_error("Cannot read " + std::string(kProjectFileName) + " of the example.", "Create the project again.");
    auto root = parse_json(*text, kProjectFileName);
    if (!root.ok() || !root->is_object())
        return make_error("The " + std::string(kProjectFileName) + " of the example is not a JSON object.",
                          "Report it with `feedback.submit`: the release's example is damaged.");
    if (!options.name.empty()) (*root)["name"] = options.name;
    if (!options.id.empty()) (*root)["id"] = options.id;
    std::string err;
    if (!tooling_detail::write_file(file, root->dump(2) + "\n", &err)) return make_error(err, "Check the folder.");
    return {};
}

}  // namespace

Result<ScaffoldResult> create_example_project(const SetupContext& ctx, const std::string& name, const std::string& targetDir,
                                              const ScaffoldOptions& options) {
    // The cheap checks first: nothing is downloaded for a folder that cannot be used or an id that is not one.
    std::error_code ec;
    stdfs::path dir = stdfs::absolute(fs::path_from_utf8(targetDir), ec).lexically_normal();
    if (dir.filename().empty()) dir = dir.parent_path();
    if (dir.empty() || dir.filename().empty())
        return make_error("\"" + targetDir + "\" is not a folder a project can be created in.", "Give a new folder, like \"my-game\".");
    const bool exists = stdfs::exists(fs::os_path(dir), ec);
    if (exists) {
        if (!stdfs::is_directory(fs::os_path(dir), ec)) return make_error(fs::path_to_utf8(dir) + " exists and is not a directory.");
        if (!stdfs::is_empty(fs::os_path(dir), ec))
            return make_error("Target directory " + fs::path_to_utf8(dir) + " is not empty.",
                              "Choose a new folder; nothing was downloaded.");
    }
    if (!options.id.empty() && !is_valid_project_id(options.id))
        return make_error("Invalid project id '" + options.id + "'.",
                          "Use reverse-DNS like com.example.spacedodge (letters, digits, underscores).");

    auto list = list_examples(ctx);
    if (!list.ok()) return list.error();
    auto example = list->manifest.find(name);
    if (!example.ok()) return example.error();
    if (example->size > kMaxZipBytes)
        return make_error("The release lists the example '" + name + "' as " + std::to_string(example->size) +
                              " bytes, more than the " + std::to_string(kMaxZipBytes) + " this downloads.",
                          "Report it with `feedback.submit`: the manifest of the release is wrong.");

    // The zip: the verified copy of an earlier call, else the release's (checked before anything is opened).
    const stdfs::path cacheDir = examples_cache_dir(ctx);
    const stdfs::path cachedZip = cacheDir / example->file;
    stdfs::path zip = cachedZip;
    Scratch download;
    if (!verify_example_file(*example, cachedZip).ok()) {
        bool cancelled = false;
        auto got = fetch_to(ctx, examples_asset_url(installed_version(ctx), example->file), cacheDir,
                            "the example '" + example->name + "' (" + setup_detail::format_bytes(example->size) + ")", example->size,
                            kMaxZipBytes, example->file, download, &cancelled);
        if (!got.ok()) return cancelled ? make_error("Creating the project was cancelled.", "Run it again.") : got.error();
        if (auto v = verify_example_file(*example, download.path); !v.ok()) return v.error();
        zip = download.path;
    }

    // Unpack beside the target and rename at the end: a failure leaves no half project.
    const stdfs::path parent = dir.parent_path();
    stdfs::create_directories(fs::os_path(parent), ec);
    if (ec)
        return make_error("Cannot create " + fs::path_to_utf8(parent) + ": " + ec.message() + ".", "Check the folder and its permissions.");
    Scratch staging;
    staging.isDir = true;
    staging.path = parent / ("." + fs::path_to_utf8(dir.filename()) + "." + unique_suffix() + ".fa-tmp");
    auto files = extract_example_zip(zip, staging.path);
    if (!files.ok()) return files.error();
    if (auto p = patch_project_file(staging.path, options); !p.ok()) return p.error();

    if (exists) stdfs::remove(fs::os_path(dir), ec);  // an empty folder: a directory is not renamed over another on Windows
    stdfs::rename(fs::os_path(staging.path), fs::os_path(dir), ec);
    if (ec) {
        const std::string why = ec.message();
        stdfs::create_directories(fs::os_path(dir), ec);  // the empty folder the caller gave stays
        return make_error("Cannot move the unpacked example to " + fs::path_to_utf8(dir) + ": " + why + ".",
                          "Close what has the folder open and try again.");
    }
    staging.keep();
    if (!download.path.empty()) {  // keep the verified zip: the same example again downloads nothing
        stdfs::rename(fs::os_path(download.path), fs::os_path(cachedZip), ec);
        if (!ec) download.keep();
    }

    ScaffoldResult result;
    result.dir = fs::path_to_utf8(dir);
    result.files = std::move(*files);
    return result;
}

Json create_example_for_command(const Json& args, const std::string& absoluteDir) {
    if (args.contains("template"))
        throw CommandError("invalid_argument", "/template and /example cannot be given together: an example is a whole project, not a template.",
                           "Give `example` to start from an example game, or `template` for an empty project (project.templates).");
    require_capability(Capability::Network, "project.create", "downloading the example game from the release");
    const auto name = args.at("example");
    if (!name.is_string() || name.get<std::string>().empty())
        throw CommandError("invalid_argument", "/example must be the name of an example, like \"block-push\".",
                           "List them with `project.examples`.");
    ScaffoldOptions o;
    o.name = args.value("name", std::string());
    o.id = args.value("id", std::string());
    auto r = create_example_project(examples_context(), name.get<std::string>(), absoluteDir, o);
    if (!r.ok()) throw CommandError("failed", r.error().message, r.error().hint);
    Json out = r->to_json();
    out.erase("template");
    out["example"] = name.get<std::string>();
    return out;
}

}  // namespace fa
