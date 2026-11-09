#include "fa/mcp/transport.h"

#include <iostream>

#include "fa/mcp/stdio.h"

namespace fa {

int run_stdio(McpServer& server) { return run_stdio(server, std::cin, std::cout); }

int run_stdio(McpServer& server, std::istream& in, std::ostream& out) {
    // The loop of `factoria mcp` without its clock: a thread reads `in`, so a notifications/cancelled reaches the request
    // it cancels while that request runs. Returns at the end of `in` (the reader's thread has ended then).
    std::unique_ptr<LineReader> reader = make_stream_reader(in);
    run_stdio_loop(server, *reader, out);
    return 0;
}

}  // namespace fa
