// Autotest section X2: the Examples tab of the start window (examples_browser.h, dialogs.cpp).
// Split from autotest_tools.cpp: Editor::at_section_X2(AtScript&) adds its steps to the script, called by at_build_tools_script in the
// order of the full run (autotest_sections.h).
#include <atomic>
#include <chrono>
#include <filesystem>
#include <memory>
#include <string>
#include <thread>

#include "autotest_common.h"
#include "autotest_sections.h"
#include "editor_internal.h"
#include "fa/core/engine_version.h"
#include "fa/core/fs.h"
#include "fa/tooling/examples.h"

namespace fa::editor {

namespace stdfs = std::filesystem;
using at_support::read_file;
using at_support::write_file;

namespace {

// One fake release on disk (the assets of the installed version: alpha.zip, beta.zip and examples-manifest.json) and the downloader
// that serves it, which the section's steps drive from the UI thread while the editor's worker threads call it.
struct X2World {
    std::string root, assets, parent, fixtureDir, savedParent, target, alphaZip;
    std::atomic<bool> offline{true};
    std::atomic<int> hold{0};  // bit 1: the manifest's download waits, bit 2: a zip's (until released or cancelled)
    std::atomic<int> zips{0};  // zips served
};

}  // namespace

void Editor::at_section_X2(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ------------------------------------------------------- X2. The Examples tab: list, stale list, Create, a bad hash, Cancel
    // A fake release (two examples packed by package_examples) behind set_examples_context: nothing touches the network or
    // ~/.factoria. Offline with no saved copy the tab says why and offers Retry; online it lists both games; the saved copy shows at
    // once while the refresh waits and a refresh that is cancelled by closing the window never answers; a refresh that fails shows
    // the saved list with the reason; a zip that does not match the manifest is an error and leaves nothing; Cancel stops the
    // download; the last Create makes the project and opens it.
    auto w = std::make_shared<X2World>();
    auto wait_for = [this, &step](std::function<bool()> done, const char* what) {
        step(1, [this, done, what] {
            atWaitCount_ = 0;
            atWaitUntil_ = done;
            atWaitWhat_ = what;
        });
    };
    auto has = [](const std::string& text, const char* part) { return text.find(part) != std::string::npos; };

    step(2, [this, w] {
        std::error_code ec;
        w->root = atOutDir_ + "/x2";
        stdfs::remove_all(w->root, ec);
        w->assets = w->root + "/assets";
        w->parent = w->root + "/projects";
        w->fixtureDir = projectDir_;
        w->savedParent = dlgNewParent_;
        const std::string src = w->root + "/source";
        write_file(src + "/examples.json",
                   R"({"format":"factoria.examples-source/1","examples":[
  {"name":"alpha","title":"Alpha Runner","shows":"A runner with a jump.","readFirst":["docs/SCRIPTING.md","docs/ANIMATION.md"]},
  {"name":"beta","title":"Beta Blocks","shows":"Blocks that push and fall.","readFirst":[]}]})");
        for (const char* n : {"alpha", "beta"}) {
            write_file(src + "/" + n + "/factoria.json",
                       std::string(R"({"format":"factoria.project/1","id":"com.test.)") + n + R"(","name":")" + n +
                           R"("})");
            write_file(src + "/" + n + "/scripts/main.js", std::string("// ") + n + "\n");
        }
        auto m = package_examples(src, w->assets, FA_ENGINE_VERSION);
        at_check(m.ok(), "the fake release was packed (" + (m.ok() ? std::string() : m.error().to_string()) + ")");
        w->alphaZip = read_file(w->assets + "/alpha.zip");

        SetupContext c;
        c.home = w->root + "/home";
        c.engineVersion = FA_ENGINE_VERSION;
        c.download = [w](const DownloadRequest& rq) {
            DownloadResult r;
            const std::string probe = examples_asset_url(FA_ENGINE_VERSION, "x.zip");
            const std::string prefix = probe.substr(0, probe.size() - 5);
            const std::string file = rq.url.rfind(prefix, 0) == 0 ? rq.url.substr(prefix.size()) : std::string();
            const int bit = file == kExamplesManifestFile ? 1 : 2;
            while ((w->hold.load() & bit) && !is_cancelled(rq.cancel))
                std::this_thread::sleep_for(std::chrono::milliseconds(5));
            if (is_cancelled(rq.cancel)) {
                r.ok = false;
                r.cancelled = true;
                r.error = make_error("The download was cancelled.", "Start it again.");
                return r;
            }
            auto fail = [&](int status, const std::string& message) {
                r.ok = false;
                r.httpStatus = status;
                r.error = make_error(message, "Check the connection.");
                return r;
            };
            if (w->offline.load())
                return fail(0, "Cannot download " + rq.what + ": cannot resolve the address github.com.");
            std::error_code ec2;
            if (file.empty() || !stdfs::exists(stdfs::path(w->assets) / file, ec2))
                return fail(404, "HTTP 404 for " + rq.url);
            if (bit == 2) ++w->zips;
            const stdfs::path dest = fs::path_from_utf8(rq.destination);
            stdfs::create_directories(dest.parent_path(), ec2);
            stdfs::copy_file(stdfs::path(w->assets) / file, dest, stdfs::copy_options::overwrite_existing, ec2);
            if (ec2) return fail(0, "copy failed: " + ec2.message());
            return r;
        };
        set_examples_context(c);
        dlgNewParent_ = w->parent;
        showProjectDialog_ = true;
    });

    // Offline, no saved copy: the error, what to do, and Retry.
    click("project:tab-examples");
    wait_for([this] { return examples_.visited() && !examples_.loading(); }, "the Examples tab's first list");
    step(2, [this, has] {
        at_check(!examples_.list().has_value(), "offline with no saved copy there is no list");
        at_check(has(examples_.error(), "no saved copy") && !examples_.hint().empty(),
                 "...the error says what is missing and the hint what to do (" + examples_.error() + ")");
        at_check(at_visible("examples:error") && at_enabled("examples:retry"),
                 "...the tab shows the error and an enabled Retry");
    });

    // Online: Retry lists both games.
    step(2, [w] { w->offline = false; });
    click("examples:retry");
    wait_for([this] { return !examples_.loading() && examples_.list().has_value(); }, "the list after Retry");
    step(3, [this] {
        const auto& l = examples_.list();
        at_check(l && l->manifest.examples.size() == 2 && !l->stale && l->downloaded.empty(),
                 "Retry online lists both examples, none downloaded yet");
        at_check(examples_.error().empty() && !at_visible("examples:error") && !at_visible("examples:stale"),
                 "...with no error and no stale banner");
        at_check(at_visible("examples:row:alpha") && at_visible("examples:row:beta"), "...a row per example");
        at_check(l && !example_size_text(l->manifest.examples[0].size).empty(), "...each with a size to show");
    });
    snap("editor_examples_tab.png");

    // The saved copy shows at once; closing the window cancels the refresh and its answer is ignored.
    step(2, [this, w] {
        w->offline = true;
        w->hold = 1;
        showProjectDialog_ = false;
    });
    step(3, [this] {
        at_check(!examples_.visited() && !examples_.list().has_value() && !examples_.loading(),
                 "closing the window forgets the list");
        showProjectDialog_ = true;
    });
    step(3, [this] {
        at_check(examples_.list().has_value() && examples_.shown_from_cache() && examples_.loading(),
                 "reopening shows the saved list at once while the refresh runs");
        at_check(at_visible("examples:row:alpha"), "...its rows are drawn");
        showProjectDialog_ = false;  // closed while the refresh waits: it is cancelled
    });
    step(3, [this] {
        at_check(!examples_.list().has_value() && !examples_.loading(),
                 "a refresh still running when the window closes is cancelled and brings nothing back");
        showProjectDialog_ = true;
    });
    step(3, [this] { at_check(examples_.loading() && examples_.list().has_value(), "the next visit loads again"); });

    // The refresh fails (offline): the saved list with the reason and Retry.
    step(2, [w] { w->hold = 0; });
    wait_for([this] { return !examples_.loading(); }, "the failed refresh");
    step(3, [this, has] {
        const auto& l = examples_.list();
        at_check(l && l->stale && has(l->staleReason, "github.com"),
                 "a failed refresh keeps the saved list marked stale, with the reason");
        at_check(at_visible("examples:stale") && at_enabled("examples:retry") && at_visible("examples:row:alpha"),
                 "...the banner, Retry and the rows are shown");
    });
    snap("editor_examples_stale.png");
    step(2, [w] { w->offline = false; });
    click("examples:retry");
    wait_for([this] { return !examples_.loading(); }, "the list after Retry");
    step(3, [this] {
        const auto& l = examples_.list();
        at_check(l && !l->stale && !at_visible("examples:stale"), "Retry online replaces the stale list");
    });

    // A zip that does not match the manifest: the error, nothing left behind.
    click("examples:row:alpha");
    step(2, [this, w] {
        at_check(dlgExampleSel_ == "alpha" && dlgExampleName_ == "alpha",
                 "a click picks the example and proposes its name");
        at_check(at_enabled("examples:create"), "...Create is available");
        w->target = w->parent + "/alpha";
        std::string bad = w->alphaZip;
        bad[bad.size() / 2] = char(bad[bad.size() / 2] ^ 0x55);  // the same size, another hash
        write_file(w->assets + "/alpha.zip", bad);
    });
    click("examples:create");
    wait_for([this] { return !examples_.creating() && !dlgExampleError_.empty(); },
             "the create with a bad zip to fail");
    step(3, [this, w, has] {
        at_check(has(dlgExampleError_, "SHA-256") && has(dlgExampleError_, "alpha"),
                 "a zip with another hash is an error that names the example (" + dlgExampleError_ + ")");
        at_check(at_visible("examples:create-error") && at_enabled("examples:create"),
                 "...shown in the tab, Create stays available");
        std::error_code ec;
        at_check(!stdfs::exists(w->target, ec), "...and no project folder was made");
        int left = 0;
        if (stdfs::exists(w->parent, ec))
            for (auto it = stdfs::directory_iterator(w->parent, ec); !ec && it != stdfs::directory_iterator();
                 it.increment(ec))
                ++left;
        at_check(left == 0, "...nor a half-unpacked folder next to it (" + std::to_string(left) + " entries)");
        at_check(!stdfs::exists(w->root + "/home/cache/examples/" FA_ENGINE_VERSION "/alpha.zip", ec),
                 "...nor a kept copy of the bad zip");
    });

    // Cancel while the zip downloads.
    step(2, [w] {
        write_file(w->assets + "/alpha.zip", w->alphaZip);
        w->hold = 2;
    });
    click("examples:create");
    // The create reads the list again first ("Downloading the list..."), then the zip, which the hold stops: wait for that
    // stage, not the first line (a slow runner still shows the list's line one frame later).
    wait_for([this, has] { return examples_.creating() && has(examples_.progress_line(), "alpha"); },
             "the create's progress line of the zip");
    step(3, [this, has] {
        at_check(has(examples_.progress_line(), "alpha"),
                 "the create shows what it is doing (" + examples_.progress_line() + ")");
        at_check(at_visible("examples:progress") && at_enabled("examples:cancel"),
                 "...with a progress bar and an enabled Cancel");
    });
    snap("editor_examples_creating.png");
    click("examples:cancel");
    wait_for([this] { return !examples_.creating() && !dlgExampleError_.empty(); }, "the cancelled create to end");
    step(3, [this, w, has] {
        std::error_code ec;
        at_check(has(dlgExampleError_, "Cancelled") && !stdfs::exists(w->target, ec),
                 "Cancel stops the create and no project is made (" + dlgExampleError_ + ")");
        w->hold = 0;
    });

    // The real Create: the project is made and opened.
    click("examples:create");
    wait_for(
        [this, w] {
            std::error_code ec;
            return engine_ && pendingOpen_.empty() && !pendingWelcome_ && atReopenIn_ == 0 &&
                   stdfs::exists(w->target, ec) && stdfs::equivalent(projectDir_, w->target, ec);
        },
        "the created example project to open");
    step(3, [this, w, has] {
        std::error_code ec;
        at_check(stdfs::exists(w->target + "/factoria.json", ec) && stdfs::exists(w->target + "/scripts/main.js", ec),
                 "Create unpacks the example into <folder>/<name>");
        at_check(has(read_file(w->target + "/factoria.json"), "\"name\": \"alpha\""), "...with the name the form gave");
        at_check(stdfs::exists(w->root + "/home/cache/examples/" FA_ENGINE_VERSION "/alpha.zip", ec),
                 "...and the checked zip stays in the cache");
        at_check(!showProjectDialog_, "...the new project is open and the dialog closed");
    });

    // Back on the fixture; the dialog opens on its first tab again (section G and the others expect it).
    step(2, [this, w] { open_project(w->fixtureDir); });
    wait_for(
        [this, w] {
            std::error_code ec;
            return engine_ && pendingOpen_.empty() && !pendingWelcome_ && atReopenIn_ == 0 &&
                   stdfs::equivalent(projectDir_, w->fixtureDir, ec);
        },
        "the fixture project to open again");
    step(2, [this] { showProjectDialog_ = true; });
    click("project:tab-projects");
    step(2, [this, w] {
        at_check(at_visible("project:delete"), "the dialog's Projects tab is back");
        set_examples_context(std::nullopt);
        close_examples_tab();
        dlgNewParent_ = w->savedParent;
        showProjectDialog_ = false;
        dlgScanned_ = false;
        std::error_code ec;
        stdfs::remove_all(w->root, ec);
    });
}

}  // namespace fa::editor
