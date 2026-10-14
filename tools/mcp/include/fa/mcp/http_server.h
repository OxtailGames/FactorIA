// MCP over Streamable HTTP on the loopback interface, for AI clients this process starts itself: the editor gives the
// URL to Claude Code, whose tool calls then run on the editor's own command registry (its live world and undo history)
// instead of in a separate `factoria mcp` process.
//
// Stateless and minimal: every POST carries one JSON-RPC message (or batch) for the handler, and its reply comes back as
// `application/json` (202 Accepted when there is none, e.g. a notification). A call still running after `streamAfter`
// (an ai_run that hands a task to the worker) is answered as an event stream instead, kept alive until its reply is
// ready, so the client's HTTP timeout does not cut it. GET and DELETE get 405: there is no server stream and no session. Only 127.0.0.1 is bound and only the path holding a random token is served (404 elsewhere), so
// other programs and web pages on the machine cannot drive the engine.
#pragma once

#include <chrono>
#include <functional>
#include <memory>
#include <optional>
#include <string>
#include <string_view>

#include "fa/core/types.h"

namespace fa {

class McpHttpServer {
public:
    // One JSON-RPC message in, the serialized reply out (nullopt = none), e.g. `McpServer(host).handle_message(m)`.
    // Called on a thread of its own per request; several requests call it at the same time.
    using Handler = std::function<std::optional<std::string>(std::string_view message)>;

    McpHttpServer();
    ~McpHttpServer();  // stop()
    McpHttpServer(const McpHttpServer&) = delete;
    McpHttpServer& operator=(const McpHttpServer&) = delete;

    // Listens on 127.0.0.1 (a free port) and returns the endpoint, "http://127.0.0.1:<port>/mcp/<token>".
    Result<std::string> start(Handler handler, std::chrono::milliseconds streamAfter = std::chrono::seconds(10));
    // Closes the listener and every connection, then waits for their threads: a handler that is still running must
    // return first (make it fail fast before calling stop()).
    void stop();
    const std::string& url() const;  // "" when not running

private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
};

}  // namespace fa
