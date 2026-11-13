// The Review window's reader (review_panel.cpp): one worker thread that lists the sheets, reads a sheet's manifest and decodes its
// pictures, so the UI thread never scans .factoria/review/ or decodes a PNG of up to 8192 px a side. The UI thread asks, polls take()
// every frame and uploads at most one decoded picture per frame. Every request carries the window's generation: a result of an older
// generation (another project, another sheet) is dropped by the caller. Plain logic: no ImGui, no Editor (tests drive it).
#pragma once

#include <atomic>
#include <condition_variable>
#include <cstdint>
#include <deque>
#include <filesystem>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

#include "fa/core/image.h"
#include "fa/core/json.h"
#include "review_model.h"

namespace fa::editor {

struct ReviewLoaded {
    enum class Kind { List, Sheet, Picture };
    Kind kind = Kind::List;
    std::uint64_t gen = 0;
    std::string error;  // "" when it worked
    // List: review_list's value and the history of every picked sheet (newest pick first), the drop status checked on disk.
    std::vector<ReviewListRow> rows;
    std::vector<ReviewHistoryRow> history;
    // Sheet: the manifest of `sheet`.
    std::string sheet;
    Json manifest;
    // Picture: `key` as asked, decoded and shrunk to fit the asked side.
    std::string key;
    Image picture;
};

// The largest picture the reader decodes (pixels): the biggest sheet review.sheet makes (8192 x 8192). A bigger PNG is refused from
// its header before anything is allocated; a file that is not a PNG is refused above kReviewMaxOtherBytes, then by the size in its own
// header (fa::image_size) before it is decoded.
inline constexpr std::int64_t kReviewDecodeMaxPixels = std::int64_t(8192) * 8192;
inline constexpr std::uintmax_t kReviewMaxPngBytes = 256u * 1024u * 1024u;
inline constexpr std::uintmax_t kReviewMaxOtherBytes = 32u * 1024u * 1024u;

class ReviewLoader {
public:
    ReviewLoader() = default;
    ReviewLoader(const ReviewLoader&) = delete;
    ReviewLoader& operator=(const ReviewLoader&) = delete;
    ~ReviewLoader() { stop(); }

    // `projectDir` is the editor's native folder string (stdfs::path(projectDir) names it on every system).
    void request_list(const std::string& projectDir, std::uint64_t gen);
    void request_sheet(const std::string& projectDir, const std::string& sheet, std::uint64_t gen);
    // `projectFile`: the picture is a candidate's own file (the Compare view's source pictures), which a pick may move: while one is
    // open, reading_project_file() is true (Windows cannot move a file another thread holds open).
    void request_picture(const std::string& key, const std::filesystem::path& file, int maxSide, bool projectFile,
                         std::uint64_t gen);
    void drop_pictures();  // forgets the pictures still waiting (the window moved to another sheet)
    // Forgets only the candidates' own files still waiting (a pick is about to move them) and returns their keys: the window forgets
    // those slots too, so they do not say "Loading..." forever, and asks for them again once the pick is over.
    std::vector<std::string> drop_project_files();
    std::vector<ReviewLoaded> take();  // what finished since the last call
    bool busy() const;                 // something is queued or being read
    bool reading_project_file() const { return readingProjectFile_.load(); }
    void stop();  // joins the thread (the queue is dropped); a later request starts it again

private:
    struct Job {
        ReviewLoaded::Kind kind = ReviewLoaded::Kind::List;
        std::uint64_t gen = 0;
        std::string projectDir, sheet, key;
        std::filesystem::path file;
        int maxSide = 0;
        bool projectFile = false;
    };
    void push(Job job);
    void run();
    ReviewLoaded work(const Job& job);

    mutable std::mutex mu_;
    std::condition_variable cv_;
    std::deque<Job> jobs_;
    std::vector<ReviewLoaded> done_;
    std::thread thread_;
    bool stopping_ = false;
    bool working_ = false;
    std::atomic<bool> readingProjectFile_{false};
};

// Reads and decodes one picture for the window: refuses what is too big before allocating it, shrinks it to `maxSide`.
Result<Image> review_read_picture(const std::filesystem::path& file, int maxSide);

}  // namespace fa::editor
