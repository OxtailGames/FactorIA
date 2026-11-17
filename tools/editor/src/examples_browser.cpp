// The Examples tab's logic: see examples_browser.h.
#include "examples_browser.h"

#include <algorithm>
#include <cstdio>
#include <system_error>
#include <utility>

#include "fa/core/fs.h"
#include "setup_job.h"

namespace fa::editor {

namespace stdfs = std::filesystem;

// ---- words and choices -------------------------------------------------------------------------------------------------------

std::string example_size_text(std::uint64_t bytes) {
    if (bytes == 0) return {};
    char buf[32];
    if (bytes < 1024)
        std::snprintf(buf, sizeof buf, "%u B", unsigned(bytes));
    else if (bytes < (1024ull << 10))
        std::snprintf(buf, sizeof buf, "%.0f KB", double(bytes) / 1024.0);
    else if (bytes < (1024ull << 20))
        std::snprintf(buf, sizeof buf, "%.1f MB", double(bytes) / double(1024ull << 10));
    else
        std::snprintf(buf, sizeof buf, "%.1f GB", double(bytes) / double(1024ull << 20));
    return buf;
}

std::string example_read_first_text(const std::vector<std::string>& readFirst) {
    std::string out;
    for (const std::string& path : readFirst) {
        std::string name = path.substr(path.find_last_of('/') == std::string::npos ? 0 : path.find_last_of('/') + 1);
        if (name.size() > 3 && name.compare(name.size() - 3, 3, ".md") == 0) name.resize(name.size() - 3);
        if (name.empty()) continue;
        if (!out.empty()) out += ", ";
        out += name;
    }
    return out;
}

std::string example_folder_name(const std::string& example, const stdfs::path& parent) {
    auto free_name = [&](const std::string& name) {
        std::error_code ec;
        const stdfs::path p = parent / fs::path_from_utf8(name);
        if (!stdfs::exists(fs::os_path(p), ec)) return true;
        return stdfs::is_directory(fs::os_path(p), ec) && stdfs::is_empty(fs::os_path(p), ec);
    };
    if (free_name(example)) return example;
    for (int n = 2; n < 1000; ++n) {
        const std::string name = example + "-" + std::to_string(n);
        if (free_name(name)) return name;
    }
    return example;
}

std::string example_target_problem(const std::string& parent, const std::string& name) {
    if (name.empty()) return "Give the project a name: it is the name of its new folder.";
    if (parent.empty()) return "Pick the folder the project is created in.";
    if (name == "." || name == ".." || name.find_first_of("/\\") != std::string::npos ||
        name.find_first_of(":*?\"<>|") != std::string::npos)
        return "The name '" + name +
               "' is a folder name: it cannot hold a path, ':' or any of * ? \" < > |. Put the "
               "folders in Folder.";
    return {};
}

// ---- the jobs ----------------------------------------------------------------------------------------------------------------

void ExamplesBrowser::start_list(const SetupContext& ctx) {
    auto job = std::make_shared<ListJob>();
    SetupContext c = ctx;
    c.cancel = &job->cancel;
    c.progress = nullptr;
    ListJob* raw = job.get();  // the job outlives its thread: it is joined before it is dropped (poll, shutdown)
    raw->thread = std::thread([raw, c = std::move(c)] {
        Result<ExamplesList> r = list_examples(c);
        raw->result = std::move(r);
        raw->done.store(true, std::memory_order_release);
    });
    list_ = std::move(job);
}

void ExamplesBrowser::retire(std::shared_ptr<ListJob> job) {
    if (!job) return;
    job->cancel.store(true);
    retiredLists_.push_back(std::move(job));
}

void ExamplesBrowser::retire(std::shared_ptr<CreateJob> job) {
    if (!job) return;
    job->cancel.store(true);
    retiredCreates_.push_back(std::move(job));
}

void ExamplesBrowser::show(const SetupContext& ctx) {
    if (visited_) return;
    visited_ = true;
    error_.clear();
    hint_.clear();
    data_ = cached_examples(ctx);
    fromCache_ = data_.has_value();
    start_list(ctx);
}

void ExamplesBrowser::refresh(const SetupContext& ctx) {
    visited_ = true;
    retire(std::move(list_));
    list_.reset();
    error_.clear();
    hint_.clear();
    start_list(ctx);
}

void ExamplesBrowser::close() {
    retire(std::move(list_));
    list_.reset();
    retire(std::move(create_));
    create_.reset();
    visited_ = false;
    data_.reset();
    fromCache_ = false;
    error_.clear();
    hint_.clear();
    created_.reset();
    poll();  // joins what already ended
}

void ExamplesBrowser::shutdown() {
    close();
    for (auto& j : retiredLists_)
        if (j->thread.joinable()) j->thread.join();
    for (auto& j : retiredCreates_)
        if (j->thread.joinable()) j->thread.join();
    retiredLists_.clear();
    retiredCreates_.clear();
}

bool ExamplesBrowser::poll() {
    bool changed = false;
    auto reap = [](auto& jobs) {
        jobs.erase(std::remove_if(jobs.begin(), jobs.end(),
                                  [](auto& j) {
                                      if (!j->done.load(std::memory_order_acquire)) return false;
                                      if (j->thread.joinable()) j->thread.join();
                                      return true;
                                  }),
                   jobs.end());
    };
    reap(retiredLists_);
    reap(retiredCreates_);

    if (list_ && list_->done.load(std::memory_order_acquire)) {
        if (list_->thread.joinable()) list_->thread.join();
        Result<ExamplesList> r = std::move(*list_->result);
        list_.reset();
        if (r.ok()) {
            data_ = std::move(*r);
            fromCache_ = false;
            error_.clear();
            hint_.clear();
        } else {
            error_ = r.error().message;
            hint_ = r.error().hint;
        }
        changed = true;
    }
    if (create_ && create_->done.load(std::memory_order_acquire)) {
        if (create_->thread.joinable()) create_->thread.join();
        ExampleCreated out;
        out.example = create_->example;
        out.targetDir = create_->targetDir;
        Result<ScaffoldResult>& r = *create_->result;
        if (r.ok()) {
            out.ok = true;
            out.dir = r->dir;
        } else if (create_->cancel.load()) {
            out.cancelled = true;
        } else {
            out.error = r.error().message;
            out.hint = r.error().hint;
        }
        create_.reset();
        created_ = std::move(out);
        changed = true;
    }
    return changed;
}

bool ExamplesBrowser::create(const SetupContext& ctx, const std::string& example, const std::string& targetDir,
                             const ScaffoldOptions& options) {
    if (create_) return false;
    auto job = std::make_shared<CreateJob>();
    job->example = example;
    job->targetDir = targetDir;
    created_.reset();
    SetupContext c = ctx;
    c.cancel = &job->cancel;
    CreateJob* raw = job.get();
    c.progress = [raw](const std::string& text) {
        std::string line = text;
        while (!line.empty() && (line.back() == '\n' || line.back() == '\r' || line.back() == ' ')) line.pop_back();
        if (line.empty()) return;
        const std::optional<int> percent = parse_progress_percent(line);
        std::lock_guard<std::mutex> lock(raw->mu);
        raw->line = std::move(line);
        raw->percent = percent ? *percent : -1;
    };
    raw->thread = std::thread([raw, c = std::move(c), example, targetDir, options] {
        raw->result = create_example_project(c, example, targetDir, options);
        raw->done.store(true, std::memory_order_release);
    });
    create_ = std::move(job);
    return true;
}

bool ExamplesBrowser::cancelling() const { return create_ && create_->cancel.load(); }

void ExamplesBrowser::cancel_create() {
    if (create_) create_->cancel.store(true);
}

std::string ExamplesBrowser::progress_line() const {
    if (!create_) return {};
    std::lock_guard<std::mutex> lock(create_->mu);
    return create_->line;
}

double ExamplesBrowser::fraction() const {
    if (!create_) return -1.0;
    std::lock_guard<std::mutex> lock(create_->mu);
    return create_->percent < 0 ? -1.0 : create_->percent / 100.0;
}

std::optional<ExampleCreated> ExamplesBrowser::take_created() {
    std::optional<ExampleCreated> out = std::move(created_);
    created_.reset();
    return out;
}

}  // namespace fa::editor
