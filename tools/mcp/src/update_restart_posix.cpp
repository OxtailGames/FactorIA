// Linux and macOS: a process replaces itself with exec; its open files (stdin, stdout) stay open.
#include <unistd.h>

#include <cerrno>
#include <cstring>

#include "fa/mcp/update_monitor.h"

namespace fa {

bool can_restart_in_place() { return true; }

Result<void> restart_process(const std::filesystem::path& executable, const std::vector<std::string>& argv) {
    if (executable.empty()) return make_error("cannot restart: the path of this program is unknown");
    std::vector<char*> args;
    for (const std::string& a : argv) args.push_back(const_cast<char*>(a.c_str()));
    args.push_back(nullptr);
    const std::string path = executable.string();
    ::execv(path.c_str(), args.data());
    return make_error("cannot execute " + path + ": " + std::strerror(errno));
}

}  // namespace fa
