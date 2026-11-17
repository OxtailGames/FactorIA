// The Examples tab of the start window (docs/EDITOR.md, "The Examples tab"): the example games of the installed version, listed and
// downloaded by fa/tooling/examples.h (list_examples, cached_examples, create_example_project), the functions behind
// `project.examples` and `project.create {example}`.
//
// Plain logic: no ImGui, no Editor (tests call it with an injected fa::SetupContext). Both calls block (a download), so they run on
// worker threads; the UI thread only starts them, polls every frame and never waits:
//   show()   the first call of a visit: the saved copy of the list at once (disk only), then list_examples on a worker thread;
//   close()  the window closed: both jobs are cancelled through SetupContext::cancel and whatever they bring is ignored;
//   a result belongs to the job that was current when it started (a generation): a refresh that is replaced, or a job that was
//   running when the window closed, is cancelled, joined later (poll, shutdown) and its result dropped.
#pragma once

#include <atomic>
#include <cstdint>
#include <filesystem>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <thread>
#include <vector>

#include "fa/core/process.h"
#include "fa/tooling/examples.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/setup.h"

namespace fa::editor {

// ---- words and choices (doctests: tools/editor/tests/examples_browser_tests.cpp) ----------------------------------------------

// "812 B", "34 KB", "26.4 MB", "1.2 GB" (a download's size, binary units); "" for 0.
std::string example_size_text(std::uint64_t bytes);
// The docs to read first as names: {"docs/SCRIPTING.md", "docs/ANIMATION.md"} -> "SCRIPTING, ANIMATION"; "" for none.
std::string example_read_first_text(const std::vector<std::string>& readFirst);
// The folder name proposed for `example` inside `parent`: the example's name, or name-2, name-3... when a folder of that name is not
// empty (or is a file). Looks at the disk (a few stats): never call it every frame.
std::string example_folder_name(const std::string& example, const std::filesystem::path& parent);
// Why <parent>/<name> cannot be the project of an example ("" = it can): an empty folder or name, a name with a separator or one
// that is not a single folder name. A folder that exists and is not empty is reported by create_example_project (before it
// downloads anything), not here.
std::string example_target_problem(const std::string& parent, const std::string& name);

// ---- the jobs ----------------------------------------------------------------------------------------------------------------------

// What a finished create did.
struct ExampleCreated {
    std::string example;    // the example's name
    std::string targetDir;  // what was asked
    bool ok = false;
    bool cancelled = false;   // Cancel (or the window closing) stopped it: nothing was created
    std::string dir;          // when ok: the project folder
    std::string error, hint;  // when !ok and not cancelled
};

class ExamplesBrowser {
public:
    ExamplesBrowser() = default;
    ExamplesBrowser(const ExamplesBrowser&) = delete;
    ExamplesBrowser& operator=(const ExamplesBrowser&) = delete;
    ~ExamplesBrowser() { shutdown(); }

    // The window shows the tab. The first call of a visit loads the saved copy of the list (no network, no wait) and starts the
    // refresh on a worker thread; later calls do nothing until close().
    void show(const SetupContext& ctx);
    // Retry: a new refresh (the one in flight, if any, is cancelled and its result ignored). The list on screen stays.
    void refresh(const SetupContext& ctx);
    // The window closed: cancels the refresh and the create, forgets what was loaded; their results are ignored. Does not wait.
    void close();
    // The editor quits: cancels and joins every thread.
    void shutdown();
    // Every frame: takes in what the current jobs finished, joins the ones that were dropped. True when something changed.
    bool poll();

    bool visited() const { return visited_; }
    bool loading() const { return list_ != nullptr; }
    const std::optional<ExamplesList>& list() const { return data_; }
    // The list is the saved copy, the refresh has not answered yet.
    bool shown_from_cache() const { return fromCache_; }
    const std::string& error() const { return error_; }  // the refresh failed with no list to show (or was cancelled)
    const std::string& hint() const { return hint_; }

    // One create at a time; false while one runs. `targetDir` is the project folder (new or empty).
    bool create(const SetupContext& ctx, const std::string& example, const std::string& targetDir,
                const ScaffoldOptions& options);
    bool creating() const { return create_ != nullptr; }
    bool cancelling() const;
    void cancel_create();
    std::string creating_example() const { return create_ ? create_->example : std::string(); }
    std::string progress_line() const;  // the latest line of the create ("Downloading the example 'x' (12 MB)...")
    double fraction() const;            // 0..1 from that line's percentage; -1 = none
    // The finished create of the current visit, once.
    std::optional<ExampleCreated> take_created();

private:
    struct ListJob {
        CancelFlag cancel{false};
        std::atomic<bool> done{false};
        std::optional<Result<ExamplesList>> result;  // written before done is set
        std::thread thread;
    };
    struct CreateJob {
        CancelFlag cancel{false};
        std::atomic<bool> done{false};
        std::string example, targetDir;
        std::optional<Result<ScaffoldResult>> result;  // written before done is set
        mutable std::mutex mu;
        std::string line;
        int percent = -1;
        std::thread thread;
    };

    void start_list(const SetupContext& ctx);
    void retire(std::shared_ptr<ListJob> job);
    void retire(std::shared_ptr<CreateJob> job);

    bool visited_ = false;
    std::shared_ptr<ListJob> list_;  // the refresh whose result counts
    std::shared_ptr<CreateJob> create_;
    std::vector<std::shared_ptr<ListJob>> retiredLists_;  // cancelled: joined when they end, results dropped
    std::vector<std::shared_ptr<CreateJob>> retiredCreates_;
    std::optional<ExamplesList> data_;
    bool fromCache_ = false;
    std::string error_, hint_;
    std::optional<ExampleCreated> created_;
};

}  // namespace fa::editor
