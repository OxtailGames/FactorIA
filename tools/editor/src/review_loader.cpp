// The Review window's reader thread (review_loader.h).
#include "review_loader.h"

#include <algorithm>
#include <system_error>

#include "fa/core/fs.h"
#include "fa/tooling/review.h"

namespace fa::editor {

namespace stdfs = std::filesystem;

Result<Image> review_read_picture(const stdfs::path& file, int maxSide) {
    std::error_code ec;
    const std::uintmax_t bytes = stdfs::file_size(fs::os_path(file), ec);
    if (ec) return Error{"Cannot read " + fs::path_to_utf8(file) + ": " + ec.message(), "The file was moved or deleted; press Refresh."};
    if (bytes == 0) return Error{fs::path_to_utf8(file) + " is empty.", "Make the sheet again."};
    std::vector<std::uint8_t> data;
    {
        // ReadStream: under the Windows file rules a pick that tries to move this file while it is open fails like on Windows.
        fs::ReadStream in(fs::os_path(file), std::ios::binary);
        if (!in) return Error{"Cannot open " + fs::path_to_utf8(file) + ".", "The file was moved or deleted; press Refresh."};
        std::uint8_t head[24] = {};
        in.read(reinterpret_cast<char*>(head), sizeof(head));
        const std::size_t got = std::size_t(in.gcount());
        const auto png = review_png_size(head, got);
        if (png) {
            if (std::int64_t(png->first) * std::int64_t(png->second) > kReviewDecodeMaxPixels || bytes > kReviewMaxPngBytes)
                return Error{fs::path_to_utf8(file) + " is " + std::to_string(png->first) + " x " + std::to_string(png->second) +
                                 " pixels, more than the Review window shows.",
                             "A review sheet is at most 8192 pixels a side; open a picture this big in the Image panel instead."};
        } else if (bytes > kReviewMaxOtherBytes) {
            return Error{fs::path_to_utf8(file) + " is " + std::to_string(bytes / (1024 * 1024)) + " MB, more than the Review window reads.",
                         "The Compare view shows the thumbnail instead."};
        }
        data.resize(std::size_t(bytes));
        std::copy(head, head + got, data.begin());
        if (bytes > got) {
            in.read(reinterpret_cast<char*>(data.data() + got), std::streamsize(bytes - got));
            data.resize(got + std::size_t(in.gcount()));  // the file got shorter while it was read: decode what is there
        }
    }
    // A JPG, BMP or TGA: its header says its size too, checked before decode_image allocates width * height * 4 bytes (a 32 MB JPG can
    // hold a picture of hundreds of megapixels).
    if (!review_png_size(data.data(), data.size())) {
        if (const auto size = image_size(data.data(), data.size());
            size.ok() && std::int64_t(size->width) * std::int64_t(size->height) > kReviewDecodeMaxPixels)
            return Error{fs::path_to_utf8(file) + " is " + std::to_string(size->width) + " x " + std::to_string(size->height) +
                             " pixels, more than the Review window shows.",
                         "The Compare view shows the thumbnail instead; open a picture this big in the Image panel."};
    }
    Result<Image> img = decode_image(data.data(), data.size());
    data.clear();
    data.shrink_to_fit();
    if (!img.ok()) return Error{"Cannot decode " + fs::path_to_utf8(file) + ": " + img.error().message, img.error().hint};
    int w = 0, h = 0;
    review_upload_size(img->width, img->height, maxSide, w, h);
    if (w != img->width || h != img->height) return resize_image(*img, w, h);
    return img;
}

void ReviewLoader::push(Job job) {
    std::lock_guard<std::mutex> lock(mu_);
    if (!thread_.joinable()) {
        stopping_ = false;
        thread_ = std::thread([this] { run(); });
    }
    // The newest request of a kind replaces an older one still waiting (a listing asked twice is read once).
    if (job.kind != ReviewLoaded::Kind::Picture)
        jobs_.erase(std::remove_if(jobs_.begin(), jobs_.end(), [&](const Job& j) { return j.kind == job.kind; }), jobs_.end());
    else
        jobs_.erase(std::remove_if(jobs_.begin(), jobs_.end(),
                                   [&](const Job& j) { return j.kind == ReviewLoaded::Kind::Picture && j.key == job.key; }),
                    jobs_.end());
    jobs_.push_back(std::move(job));
    cv_.notify_one();
}

void ReviewLoader::request_list(const std::string& projectDir, std::uint64_t gen) {
    Job j;
    j.kind = ReviewLoaded::Kind::List;
    j.gen = gen;
    j.projectDir = projectDir;
    push(std::move(j));
}

void ReviewLoader::request_sheet(const std::string& projectDir, const std::string& sheet, std::uint64_t gen) {
    Job j;
    j.kind = ReviewLoaded::Kind::Sheet;
    j.gen = gen;
    j.projectDir = projectDir;
    j.sheet = sheet;
    push(std::move(j));
}

void ReviewLoader::request_picture(const std::string& key, const stdfs::path& file, int maxSide, bool projectFile, std::uint64_t gen) {
    Job j;
    j.kind = ReviewLoaded::Kind::Picture;
    j.gen = gen;
    j.key = key;
    j.file = file;
    j.maxSide = maxSide;
    j.projectFile = projectFile;
    push(std::move(j));
}

void ReviewLoader::drop_pictures() {
    std::lock_guard<std::mutex> lock(mu_);
    jobs_.erase(std::remove_if(jobs_.begin(), jobs_.end(), [](const Job& j) { return j.kind == ReviewLoaded::Kind::Picture; }), jobs_.end());
}

std::vector<std::string> ReviewLoader::drop_project_files() {
    std::lock_guard<std::mutex> lock(mu_);
    std::vector<std::string> keys;
    jobs_.erase(std::remove_if(jobs_.begin(), jobs_.end(),
                               [&keys](const Job& j) {
                                   if (j.kind != ReviewLoaded::Kind::Picture || !j.projectFile) return false;
                                   keys.push_back(j.key);
                                   return true;
                               }),
                jobs_.end());
    return keys;
}

std::vector<ReviewLoaded> ReviewLoader::take() {
    std::lock_guard<std::mutex> lock(mu_);
    std::vector<ReviewLoaded> out;
    out.swap(done_);
    return out;
}

bool ReviewLoader::busy() const {
    std::lock_guard<std::mutex> lock(mu_);
    return working_ || !jobs_.empty() || !done_.empty();
}

void ReviewLoader::stop() {
    {
        std::lock_guard<std::mutex> lock(mu_);
        stopping_ = true;
        jobs_.clear();
        cv_.notify_all();
    }
    if (thread_.joinable()) thread_.join();
    std::lock_guard<std::mutex> lock(mu_);
    done_.clear();
    working_ = false;
    stopping_ = false;
}

void ReviewLoader::run() {
    for (;;) {
        Job job;
        {
            std::unique_lock<std::mutex> lock(mu_);
            cv_.wait(lock, [this] { return stopping_ || !jobs_.empty(); });
            if (stopping_) return;
            job = std::move(jobs_.front());
            jobs_.pop_front();
            working_ = true;
            // Set under the lock: after drop_pictures() returns, reading_project_file() tells whether such a read already started.
            if (job.kind == ReviewLoaded::Kind::Picture && job.projectFile) readingProjectFile_.store(true);
        }
        ReviewLoaded result = work(job);
        std::lock_guard<std::mutex> lock(mu_);
        working_ = false;
        if (stopping_) return;
        done_.push_back(std::move(result));
    }
}

ReviewLoaded ReviewLoader::work(const Job& job) {
    ReviewLoaded out;
    out.kind = job.kind;
    out.gen = job.gen;
    switch (job.kind) {
        case ReviewLoaded::Kind::List: {
            const ReviewOutcome listed = review_list(job.projectDir, kReviewListMax);
            if (!listed.ok) {
                out.error = listed.message;
                break;
            }
            out.rows = review_rows(listed.value);
            // The history: the manifest of every picked sheet (who, when, the note, the files dropped), and whether each dropped file is
            // still in the drop folder (moved back or deleted by hand: "gone").
            for (const ReviewListRow& row : out.rows) {
                if (row.picked == 0) continue;
                const ReviewOutcome m = review_load(job.projectDir, row.id);
                if (!m.ok) continue;
                std::optional<ReviewHistoryRow> h = review_history_row(m.value);
                if (!h) continue;
                for (ReviewDroppedLine& d : h->dropped) {
                    if (d.status != "moved" || d.to.empty()) continue;
                    std::error_code ec;
                    if (!stdfs::exists(fs::os_path(stdfs::path(job.projectDir) / fs::path_from_utf8(d.to)), ec) && !ec) d.status = "gone";
                }
                out.history.push_back(std::move(*h));
            }
            review_sort_history(out.history);
            break;
        }
        case ReviewLoaded::Kind::Sheet: {
            out.sheet = job.sheet;
            const ReviewOutcome m = review_load(job.projectDir, job.sheet);
            if (!m.ok) out.error = m.message + (m.hint.empty() ? std::string() : " " + m.hint);
            else out.manifest = m.value;
            break;
        }
        case ReviewLoaded::Kind::Picture: {
            out.key = job.key;
            Result<Image> img = review_read_picture(job.file, job.maxSide);
            readingProjectFile_.store(false);
            if (!img.ok()) out.error = img.error().message;
            else out.picture = std::move(*img);
            break;
        }
    }
    return out;
}

}  // namespace fa::editor
