// MCP transports. stdout carries ONLY protocol messages (one JSON object per
// line); everything else must go to stderr.
#pragma once

#include <iosfwd>

#include "fa/mcp/server.h"

namespace fa {

// Blocking loop: reads newline-delimited JSON-RPC from `in`, writes responses and server
// notifications to `out` (flushed per message). Returns when `in` reaches EOF. Built on run_stdio_loop (stdio.h): the
// input is read on while a request runs, so notifications/cancelled stops it.
// Defaults: std::cin / std::cout. Also redirects fa logging to stderr-only behaviour is the
// caller's job (fa::log already writes to stderr).
int run_stdio(McpServer& server);
int run_stdio(McpServer& server, std::istream& in, std::ostream& out);

}  // namespace fa
