// The example games a user can get (M97.5, docs/design/BUILDING_RELEASE.md, "Example games in the release").
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
// The zip of an example is the same bytes whenever the same files are packed: entries sorted by name, the fixed DOS date
// 1980-01-01, no extra fields. It leaves out what is not part of the project: .factoria/ and every other hidden folder (.git),
// node_modules/, a top-level build/, and the files the OS and the tests leave (.DS_Store, Thumbs.db, *.actual.png).
#pragma once

#include <cstdint>
#include <filesystem>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/types.h"

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
// The files of the project folder `dir` that go into its zip: forward-slash paths relative to `dir`, sorted by byte.
std::vector<std::string> example_zip_files(const std::filesystem::path& dir);
// Writes the zip of the project folder `dir` to `zipFile` (replaced). The same files give the same bytes.
Result<void> package_example_zip(const std::filesystem::path& dir, const std::filesystem::path& zipFile);

// Packs every example of the source manifest `examplesDir`/examples.json into `outDir` as <name>.zip and writes
// `outDir`/examples-manifest.json for `engineVersion`. `only` limits it to those names (empty: all). Checks first that every folder
// of examplesDir that holds a factoria.json has an entry and every entry has a folder, so a release never leaves one out. Returns
// the manifest it wrote.
Result<ExamplesManifest> package_examples(const std::filesystem::path& examplesDir, const std::filesystem::path& outDir,
                                          const std::string& engineVersion, const std::vector<std::string>& only = {});

// project.package_examples
void register_examples_commands(CommandRegistry& registry);

}  // namespace fa
