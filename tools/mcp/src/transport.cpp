#include "fa/mcp/transport.h"

#include <iostream>
#include <mutex>

namespace fa {

int run_stdio(McpServer& server) { return run_stdio(server, std::cin, std::cout); }

int run_stdio(McpServer& server, std::istream& in, std::ostream& out) {
    // Responses and asynchronous notifications (other threads) share one writer.
    std::mutex writeMutex;
    auto write = [&](const std::string& line) {
        std::lock_guard<std::mutex> lock(writeMutex);
        out << line << '\n';
        out.flush();
    };
    server.set_notification_sink(write);
    std::string line;
    while (std::getline(in, line)) {
        if (!line.empty() && line.back() == '\r') line.pop_back();
        if (line.find_first_not_of(" \t") == std::string::npos) continue;
        if (auto response = server.handle_message(line)) write(*response);
    }
    server.set_notification_sink(nullptr);
    return 0;
}

}  // namespace fa
