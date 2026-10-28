#include "fa/ai/progress_file.h"

#include <chrono>
#include <filesystem>
#include <fstream>
#include <mutex>

namespace fa::ai {

namespace sfs = std::filesystem;

std::string progress_file_path(const std::string& projectDir) {
    return (sfs::path(projectDir) / ".factoria" / "ai" / "progress.log").string();
}

void append_progress_line(const std::string& projectDir, const std::string& line) {
    static std::mutex mu;  // two sub-agents of one process: their lines do not interleave
    std::string clean = line;
    for (char& c : clean)
        if (c == '\n' || c == '\r') c = ' ';
    std::lock_guard<std::mutex> lock(mu);
    std::error_code ec;
    const sfs::path path = progress_file_path(projectDir);
    sfs::create_directories(path.parent_path(), ec);
    if (ec) return;
    if (sfs::exists(path, ec) && sfs::file_size(path, ec) > (1u << 20)) sfs::resize_file(path, 0, ec);  // never grows past 1 MB
    std::ofstream out(path, std::ios::app | std::ios::binary);
    if (out) out << clean << '\n';
}

ProgressTail::ProgressTail(const std::string& projectDir, std::function<void(const std::string&)> onLine, int pollMillis)
    : path_(progress_file_path(projectDir)), onLine_(std::move(onLine)), pollMillis_(pollMillis) {
    std::error_code ec;
    const auto size = sfs::exists(path_, ec) ? sfs::file_size(path_, ec) : 0;
    offset_ = ec ? 0 : size;  // what an earlier run left is not this run's
    thread_ = std::thread([this] {
        while (!stop_.load()) {
            poll();
            for (int waited = 0; waited < pollMillis_ && !stop_.load(); waited += 25)
                std::this_thread::sleep_for(std::chrono::milliseconds(25));
        }
    });
}

ProgressTail::~ProgressTail() {
    stop_ = true;
    if (thread_.joinable()) thread_.join();
    poll();  // what was written since the last look
    if (!partial_.empty() && onLine_) onLine_(partial_);
}

void ProgressTail::poll() {
    std::error_code ec;
    if (!sfs::exists(path_, ec)) return;
    const std::uintmax_t size = sfs::file_size(path_, ec);
    if (ec) return;
    if (size < offset_) offset_ = 0;  // the file was truncated: start over
    if (size == offset_) return;
    std::ifstream in(path_, std::ios::binary);
    if (!in) return;
    in.seekg(static_cast<std::streamoff>(offset_));
    std::string chunk(static_cast<std::size_t>(size - offset_), '\0');
    in.read(chunk.data(), static_cast<std::streamsize>(chunk.size()));
    chunk.resize(static_cast<std::size_t>(in.gcount()));
    offset_ += chunk.size();
    partial_ += chunk;
    std::size_t nl;
    while ((nl = partial_.find('\n')) != std::string::npos) {
        std::string line = partial_.substr(0, nl);
        partial_.erase(0, nl + 1);
        if (!line.empty() && onLine_) onLine_(line);
    }
}

}  // namespace fa::ai
