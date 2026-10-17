// A CI workflow for a game project: the command project.new_ci_workflow writes .github/workflows/factoria.yml (GitHub Actions)
// into the game's folder. On every push and pull request it installs FactorIA, runs `factoria validate` and `factoria test`
// (headless, under Xvfb), exports the game for Linux and Windows on an Ubuntu runner and for macOS on a macOS runner, and
// keeps the exports as workflow artifacts (docs/EXPORTING.md, "CI for your game").
//
// The workflow downloads the FactorIA package of the SAME version as the factoria that wrote it, from the GitHub releases
// the editor updates from (FA_UPDATE_REPO), and checks it against the SHA-256 GitHub lists for the release asset. A build
// from source has no release of its own (no FA_UPDATE_REPO): the workflow then follows the newest release, with a warning.
// A project template does not carry the file: templates stay minimal, and not every game lives on GitHub.
#pragma once

#include <optional>
#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

struct CiWorkflowOptions {
    std::string projectDir;                    // folder containing factoria.json
    std::string path = ".github/workflows/factoria.yml";  // where it goes, relative to projectDir (GitHub reads .github/workflows/*.yml)
    std::vector<std::string> platforms;        // linux | windows | macos ("" / empty = all three)
    std::string workingDirectory = ".";        // the game's folder inside the repository, when it is not the repository root
    std::string version;                       // "" = the version of this factoria (a release build) or "latest"; "latest" or x.y.z
    bool overwrite = false;                    // replace a file that is already there (else it is an error, unless it is identical)
    bool dryRun = false;                       // return the workflow, write nothing
    std::optional<std::string> engineVersion;  // nullopt = FA_ENGINE_VERSION; only tests change it
    std::optional<std::string> updateRepo;     // nullopt = FA_UPDATE_REPO, which is empty in a build from source; only tests change it
};

struct CiWorkflowReport {
    std::string path;                          // absolute path of the workflow file
    bool written = false;                      // the file was created or replaced (false: dry run, or it was already identical)
    bool dryRun = false;
    std::string version;                       // the FactorIA version the workflow downloads ("latest" = the newest release)
    std::string repo;                          // owner/name of the GitHub repository the releases come from
    std::vector<std::string> platforms;        // the exports the workflow makes
    std::string workflow;                      // the YAML
    std::vector<std::string> warnings;
    std::vector<std::string> nextSteps;
    Json to_json() const;
};

// The workflow text for these settings. Pure: it looks at nothing. `version` is "latest" or x.y.z, `repo` owner/name,
// `platforms` a subset of linux, windows, macos in that order, `workingDirectory` "." or a folder inside the repository.
std::string ci_workflow_yaml(const std::string& version, const std::string& repo, const std::vector<std::string>& platforms,
                             const std::string& workingDirectory);

// Writes (or, with dryRun, only plans) the workflow. An Error means nothing was written: an existing file, a path outside
// .github/workflows/, an unknown platform...; the message says how to fix it.
Result<CiWorkflowReport> write_ci_workflow(const CiWorkflowOptions& options);

// Registers project.new_ci_workflow (-> MCP tool project_new_ci_workflow, `factoria call`, editor console, fa.call) for the
// project at `projectDir`.
void register_ci_workflow_commands(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa
