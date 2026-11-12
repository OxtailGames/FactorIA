#include "fa/core/private_file.h"

#include <atomic>
#include <filesystem>
#include <string>
#ifdef _WIN32
#include <process.h>
#else
#include <unistd.h>
#endif

#include "fa/core/fs.h"
#include "private_file_os.h"

namespace fa::fs {

namespace stdfs = std::filesystem;

Result<void> write_private(std::string_view path, std::string_view bytes) {
    static std::atomic<unsigned> counter{0};
    stdfs::path target = path_from_utf8(path);
    if (target.empty()) return make_error("Cannot write a private file: the path is empty", "Give the file's path.");
    std::error_code ec;
    if (target.has_parent_path()) stdfs::create_directories(os_path(target.parent_path()), ec);
    if (ec) {
        return make_error("Cannot create the folder of '" + std::string(path) + "': " + ec.message(),
                          "Check the folder can be written to.");
    }
    if (stdfs::is_symlink(os_path(target), ec)) {
        const stdfs::path resolved = stdfs::canonical(os_path(target), ec);
        if (!ec) target = resolved;  // a link that points nowhere (yet) is replaced by the file, as a plain write would
    }
#ifdef _WIN32
    const long long pid = _getpid();
#else
    const long long pid = static_cast<long long>(::getpid());
#endif
    stdfs::path tmp = target;
    tmp += ".fa-tmp" + std::to_string(pid) + "_" + std::to_string(counter++);
    const stdfs::path osTarget = os_path(target), osTmp = os_path(tmp);
    if (std::string problem = detail::create_private_file(osTmp, bytes); !problem.empty()) {
        stdfs::remove(osTmp, ec);
        return make_error("Cannot write '" + std::string(path) + "': " + problem,
                          "Check the folder exists and is writable, and that the disk is not full.");
    }
    replace_file(osTmp, osTarget, ec);
    if (ec) {
        std::error_code ignored;
        stdfs::remove(osTmp, ignored);
        return make_error("Cannot replace '" + std::string(path) + "': " + ec.message(),
                          "Check the file is writable and not open in another program. The old file was left untouched.");
    }
    return {};
}

Result<void> make_private(std::string_view path) {
    const stdfs::path file = os_path(path_from_utf8(path));
    std::error_code ec;
    if (!stdfs::is_regular_file(file, ec)) {
        return make_error("Cannot restrict '" + std::string(path) + "': it is not a file", "Check the path.");
    }
    if (std::string problem = detail::restrict_to_owner(file); !problem.empty()) {
        return make_error("Cannot restrict '" + std::string(path) + "' to its owner: " + problem,
                          "Check you own the file and can change its permissions.");
    }
    return {};
}

}  // namespace fa::fs
