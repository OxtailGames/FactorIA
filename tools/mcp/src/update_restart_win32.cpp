// Windows: a process cannot replace itself in place, and the AI client owns the pipes the server talks through (a new process
// started from here would have different ones). The server tells the AI to reconnect instead (update_monitor.cpp).
#include "fa/mcp/update_monitor.h"

namespace fa {

bool can_restart_in_place() { return false; }

Result<void> restart_process(const std::filesystem::path&, const std::vector<std::string>&) {
    return make_error("Windows cannot replace a running program in place");
}

}  // namespace fa
