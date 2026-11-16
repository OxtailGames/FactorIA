// The no-replace rename of an unpacked example, Linux, macOS and Android (examples_place.h). The Windows one is
// examples_place_win32.cpp.
#include <cerrno>
#include <cstdio>

#include "examples_place.h"

#if defined(__linux__)
#include <fcntl.h>
#include <sys/syscall.h>
#endif
#include <unistd.h>

namespace fa::examples_detail {

// This rename does not go through fs::windows_rules (the emulation of Windows' sharing violations for files opened with
// fs::ReadStream): nothing in a freshly unpacked example is held open by this process, and the Windows build asks Windows itself.
void rename_no_replace(const std::filesystem::path& from, const std::filesystem::path& to, std::error_code& ec) {
    int rc = -1;
    int err = ENOSYS;
#if defined(__APPLE__)
    rc = renamex_np(from.c_str(), to.c_str(), RENAME_EXCL);
    err = errno;
#elif defined(__linux__) && defined(SYS_renameat2)
    rc = int(::syscall(SYS_renameat2, AT_FDCWD, from.c_str(), AT_FDCWD, to.c_str(), 1u /* RENAME_NOREPLACE */));
    err = errno;
#endif
    if (rc == 0) {
        ec.clear();
        return;
    }
    bool unsupported = err == ENOSYS || err == EINVAL || err == EPERM || err == EOPNOTSUPP;
#if defined(__APPLE__)
    unsupported = unsupported || err == ENOTSUP;
#endif
    if (!unsupported) {
        ec.assign(err, std::generic_category());
        return;
    }
    std::error_code probe;
    if (std::filesystem::exists(std::filesystem::symlink_status(to, probe))) {
        ec = std::make_error_code(std::errc::file_exists);
        return;
    }
    std::filesystem::rename(from, to, ec);
}

}  // namespace fa::examples_detail
