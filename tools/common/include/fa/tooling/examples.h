// The example games a user can get (M97.5, docs/design/BUILDING.md, "Example games in the release").
//
// The download carries no examples (only a clone of the repository has examples/), so each release publishes every example as
// its own zip plus one manifest that says what is there:
//
//   examples/examples.json   the SOURCE manifest, kept in the repository: per example its title, what it shows and the docs to
//                            read first (format "factoria.examples-source/1"; parse_examples_source).
//   project.package_examples zips every example folder into <name>.zip and writes examples-manifest.json (package_examples).
//                            The release workflow runs it and uploads the files as assets of the GitHub release v<version>.
//   examples-manifest.json   the RELEASE manifest (format "factoria.examples/1"; parse_examples_manifest): the engine version and,
//                            per example, name, title, shows, readFirst, file, size (bytes of the zip) and sha256 (hex of the zip).
//
// Whoever downloads an example (project.create {example}, the editor's start window) builds the URL of the manifest and of each
// zip from the installed version alone (examples_manifest_url, examples_asset_url: the ONE place the pattern is written), reads
// the manifest, and checks every download against it (verify_example_bytes, verify_example_file) before it unpacks anything.
//
// The zip of an example is the same bytes whenever the same files are packed: entries sorted by name (deflated where that is
// smaller), the fixed DOS date 1980-01-01, no extra fields. It leaves out what is not part of the project: .factoria/ and every
// other hidden folder (.git), node_modules/, a top-level build/, the files the OS and the tests leave (.DS_Store, Thumbs.db,
// desktop.ini, *.actual.png, *.fa-tmp) and the secrets and local settings of a developer's folder (.env, ai.local.json, *.key,
// *.keystore, *.jks, *.p12, *.pem).
//
// Getting one (project.examples, project.create {example}; the editor's start window calls the same functions from a worker
// thread): list_examples downloads examples-manifest.json of the INSTALLED version and keeps a copy under
// <factoria_home>/cache/examples/<version>/ (the folder of setup's downloads: $FACTORIA_HOME, else ~/.factoria); create_example_project
// downloads the zip, checks its size and SHA-256 against the manifest BEFORE it opens it, unpacks it into a hidden folder next to
// the target (extract_example_zip refuses any entry that could leave it) and renames that folder to the target at the end, so a
// failure leaves nothing behind. Both go through SetupContext::fetch, so a test or an embedder gives the downloader, the home
// folder and the version (set_examples_context) and nothing touches the network.
#pragma once

#include <cstdint>
#include <filesystem>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/setup.h"

namespace fa {

// The "format" value of examples-manifest.json and of examples/examples.json. The number is bumped when a field changes meaning
// or goes away; a program that reads a higher number refuses it and says to update FactorIA.
inline constexpr const char* kExamplesManifestFormat = "factoria.examples/1";
inline constexpr const char* kExamplesSourceFormat = "factoria.examples-source/1";
inline constexpr int kExamplesFormatVersion = 1;

// File names: the release asset that lists the examples, the source file in the repository (inside examples/).
inline constexpr const char* kExamplesManifestFile = "examples-manifest.json";
inline constexpr const char* kExamplesSourceFile = "examples.json";

// One example. The source manifest fills name, title, shows and readFirst; the release manifest also fills file, size and sha256.
struct ExampleInfo {
    std::string name;   // the folder under examples/ and the project's name: "block-push" (a-z, 0-9, '-')
    std::string title;  // "Block Push"
    std::string shows;  // one line: what the example shows
    std::vector<std::string> readFirst;  // docs to read first, as docs/<NAME>.md paths ("docs/SCRIPTING.md"), at most 8
    std::string file;                    // the asset's name in the release: "block-push.zip" (release manifest only)
    std::uint64_t size = 0;              // bytes of the zip (release manifest only)
    std::string sha256;                  // lowercase hex of the zip's bytes, 64 characters (release manifest only)

    Json to_json() const;  // the manifest's object for it; file, size and sha256 only when `file` is set
};

struct ExamplesManifest {
    std::string format;         // kExamplesManifestFormat
    std::string engineVersion;  // the version of the release the zips belong to, "0.30.0"
    std::vector<ExampleInfo> examples;

    Json to_json() const;
    // The example called `name`, or an Error that lists the ones there are, with "did you mean".
    Result<ExampleInfo> find(const std::string& name) const;
};

// ---- Reading the manifests -------------------------------------------------------------------------------------------------
// `source` names the text in the errors ("examples-manifest.json", a file path). Every Error points at the JSON pointer of the
// problem ("/examples/3/sha256") and says what to write. An unknown format version says which one this program reads and that
// the release is newer (or older) than the installed FactorIA.

// The release manifest: format, engineVersion and the examples with all their fields (file is a plain file name ending in .zip,
// sha256 is 64 hex digits, names are unique).
Result<ExamplesManifest> parse_examples_manifest(std::string_view text,
                                                 std::string_view source = kExamplesManifestFile);
// The source manifest examples/examples.json: format, then {name, title, shows, readFirst} per example (any file, size or sha256
// in it is an Error: they belong to the release manifest only).
Result<std::vector<ExampleInfo>> parse_examples_source(std::string_view text,
                                                       std::string_view source = kExamplesSourceFile);

// ---- Where a release keeps the files ------------------------------------------------------------------------------------------
// The tag of the release of `version` ("0.30.0" -> "v0.30.0"; a leading "v" is kept as it is).
std::string examples_release_tag(std::string_view version);
// https://github.com/<kSetupReleaseRepo>/releases/download/v<version>/<file>: the URL of an asset of that release. `file` is a
// plain file name (no folder, no "..", no "?" or "#"); anything else gives an empty string, never a URL that leaves the release.
// Every URL it returns passes is_trusted_download_url (fa/tooling/setup_parse.h).
std::string examples_asset_url(std::string_view version, std::string_view file);
// examples_asset_url(version, kExamplesManifestFile)
std::string examples_manifest_url(std::string_view version);

// ---- Checking a download ------------------------------------------------------------------------------------------------------
// The size and the SHA-256 of what was downloaded against the manifest entry. The Error names the example, says which of the two
// differs (what was expected, what arrived) and what to do: download again, or, if it happens twice, report it.
Result<void> verify_example_bytes(const ExampleInfo& example, std::string_view bytes);
Result<void> verify_example_file(const ExampleInfo& example, const std::filesystem::path& zip);

// ---- Packaging (the release job, `project.package_examples`) -----------------------------------------------------------------
// The files of the project folder `dir` that go into its zip: forward-slash paths relative to `dir`, sorted by byte. A folder or file
// that cannot be listed is an Error that names it (nothing is packed from a half-read folder).
Result<std::vector<std::string>> example_zip_files(const std::filesystem::path& dir);
// Writes the zip of the project folder `dir` to `zipFile` (replaced). The same files give the same bytes.
Result<void> package_example_zip(const std::filesystem::path& dir, const std::filesystem::path& zipFile);

// Packs every example of the source manifest `examplesDir`/examples.json into `outDir` as <name>.zip and writes
// `outDir`/examples-manifest.json for `engineVersion`. `only` limits it to those names (empty: all). Checks first that every folder
// of examplesDir that holds a factoria.json has an entry and every entry has a folder, so a release never leaves one out. Returns
// the manifest it wrote.
Result<ExamplesManifest> package_examples(const std::filesystem::path& examplesDir, const std::filesystem::path& outDir,
                                          const std::string& engineVersion, const std::vector<std::string>& only = {});

// ---- Getting an example (project.examples, project.create {example}) ----------------------------------------------------------

// What list_examples found.
struct ExamplesList {
    ExamplesManifest manifest;  // the release manifest of the installed version
    // false: just downloaded. true: the download failed and `manifest` is the copy kept by an earlier call (it may be older than
    // the release: the zips it names are checked again before they are used).
    bool stale = false;
    std::string staleReason;  // when stale: what went wrong with the download (message and hint, one line)
    std::string cacheDir;     // where the copy of the manifest and the downloaded zips are kept
    std::vector<std::string>
        downloaded;  // names of the examples whose zip is already in cacheDir: they need no network

    // {engineVersion, source: "network"|"cache", stale, staleReason?, cacheDir, examples: [{name, title, shows, readFirst, size,
    //  downloaded}], next}. `size` is the download in bytes; the file name and SHA-256 stay in the manifest.
    Json to_json() const;
};

// The examples of the installed version (ctx.version()): downloads examples-manifest.json, keeps a copy and returns it; when the
// download fails returns the copy of an earlier call with `stale` set; with neither, an Error that says what is missing, how to fix it
// and that the base download carries no examples. It blocks while it downloads (a few KB; curl gives up after about a minute): call it
// from a worker thread, never from a UI thread, and pass ctx.cancel to stop it (a cancelled call is an Error, never the cache).
Result<ExamplesList> list_examples(const SetupContext& ctx);
// The saved copy only, no network and no wait: nullopt when there is none (or it does not parse, or belongs to another version).
// What a window shows at once while list_examples runs on a worker thread.
std::optional<ExamplesList> cached_examples(const SetupContext& ctx);

// <ctx.home_dir()>/cache/examples/<version>
std::filesystem::path examples_cache_dir(const SetupContext& ctx);

// Creates the project `targetDir` (new or empty; relative paths are made absolute) from the example `name` of the installed version.
// Order: the target and the options are checked, the example is looked up in list_examples (a name that is not there gets "did you
// mean"), the zip comes from the cache when its size and SHA-256 match or from the release otherwise, verify_example_file checks it,
// extract_example_zip unpacks it into a hidden sibling folder of `targetDir`, options.name / options.id replace "name" / "id" of
// factoria.json when given, and the folder is renamed to `targetDir`. An existing empty `targetDir` is never deleted or replaced (it
// may be a working directory, a link or a mount point): what is in the hidden folder moves into it, and if that fails what moved is
// taken out again. A failure leaves nothing: no hidden folder, no half project, no parent folder this call made. The verified zip is
// kept in the cache, so the same example again downloads nothing. result.templateName is empty. Blocks while it downloads (a worker
// thread); ctx.cancel stops it before the download, between files and before the move (an Error, nothing left).
Result<ScaffoldResult> create_example_project(const SetupContext& ctx, const std::string& name,
                                              const std::string& targetDir, const ScaffoldOptions& options = {});

// What extract_example_zip refuses to unpack (a release's zip is far inside every limit: the biggest example has ~600 files and 26 MB).
struct ExampleExtractLimits {
    std::size_t maxEntries = 20000;
    std::uint64_t maxEntryBytes = 256ull << 20;
    std::uint64_t maxTotalBytes = 1ull << 30;
};
// Unpacks the project zip `zip` into `destination` (created; its files are replaced). Checks every entry BEFORE it writes any: a
// name with "..", a "." or empty part, a leading "/", a "\\", a ':' (drive letter, NTFS stream), a character Windows does not allow,
// a part that ends in a dot or space or is a device name (CON, NUL...), bytes that are not UTF-8, two names that differ only in
// capitals (ASCII and Latin-1 letters are folded; the capitals of other scripts and Unicode normalisation are not) or a file that is
// also a folder, an encrypted, linked or special entry, more entries or bytes than `limits`, and a zip without factoria.json at its
// top. It also checks that the path it will write lies inside `destination`. `cancel` is looked at before every entry. Returns the
// files it wrote (forward slashes, sorted). On an Error `destination` may hold part of the files: the caller unpacks into a folder
// it removes. project.package_examples applies the same name rules, so it never writes a zip this refuses.
Result<std::vector<std::string>> extract_example_zip(const std::filesystem::path& zip,
                                                     const std::filesystem::path& destination,
                                                     const ExampleExtractLimits& limits = {},
                                                     const CancelFlag* cancel = nullptr);

// project.create {example}: the arguments (`example`, `dir` resolved by the caller to an absolute path, `name`, `id`; `template` is a
// contradiction) -> the command's result. Needs the network capability of its caller (CommandError "capability_denied" otherwise).
// Throws CommandError (code "failed") with the message and hint of the Error. Both registrations of project.create call it.
Json create_example_for_command(const Json& args, const std::string& absoluteDir);

// What the commands (and the editor's window) use: a default SetupContext (curl, the user's home, the installed version).
// set_examples_context replaces it for tests and embedders; an empty optional puts the default back. Thread-safe.
SetupContext examples_context();
void set_examples_context(std::optional<SetupContext> ctx);

// project.package_examples and project.examples
void register_examples_commands(CommandRegistry& registry);

}  // namespace fa
