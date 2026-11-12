// Private files on POSIX: mode 0600 from the moment the file exists (open with O_EXCL and the mode, no chmod afterwards).
#include <cerrno>
#include <cstring>
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>

#include "private_file_os.h"

namespace fa::detail {

std::string create_private_file(const std::filesystem::path& file, std::string_view bytes) {
    int fd;
    do {
        fd = ::open(file.c_str(), O_WRONLY | O_CREAT | O_EXCL | O_CLOEXEC, 0600);
    } while (fd < 0 && errno == EINTR);
    if (fd < 0) return std::strerror(errno);
    std::size_t done = 0;
    while (done < bytes.size()) {
        const ssize_t n = ::write(fd, bytes.data() + done, bytes.size() - done);
        if (n < 0 && errno == EINTR) continue;
        if (n <= 0) {
            const int e = n < 0 ? errno : ENOSPC;
            ::close(fd);
            return std::strerror(e);
        }
        done += static_cast<std::size_t>(n);
    }
    if (::close(fd) != 0) return std::strerror(errno);
    return {};
}

std::string restrict_to_owner(const std::filesystem::path& file) {
    if (::chmod(file.c_str(), S_IRUSR | S_IWUSR) != 0) return std::strerror(errno);
    return {};
}

}  // namespace fa::detail
