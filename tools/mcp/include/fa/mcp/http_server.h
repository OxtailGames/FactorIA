// MCP over Streamable HTTP on the loopback interface, for AI clients this process starts itself: the editor gives the
// URL to Claude Code, whose tool calls then run on the editor's own command registry (its live world and undo history)
// instead of in a separate `factoria mcp` process.
//
// Stateless and minimal: every POST carries one JSON-RPC message (or batch) for the handler, and its reply comes back as
// `application/json` (202 Accepted for a notification or a response, which have none). A request the client cancelled
// (notifications/cancelled) gets no reply: an empty event stream that ends with the connection, or 204 No Content for a
// client that does not accept text/event-stream. A call still running after `streamAfter`
// (an ai_run that hands a task to the worker), or that sends a notification meanwhile, is answered as an event stream
// instead: the notifications the handler sends (MCP notifications/progress, which keep a client from timing the call
// out) are written to it as they come, a comment line every 15 s keeps the connection alive, and the reply closes it.
// GET and DELETE get 405: there is no server stream and no session. Only 127.0.0.1 is bound and only the path
// holding a random token is served (404 elsewhere), so other programs and web pages on the machine cannot drive the
// engine.
//
// Bounded: at most McpHttpOptions::maxConnections connections are served at once, each on a thread of its own, plus one
// spare: a client still gets in when every connection is taken (a notifications/cancelled for a call that runs). When
// the spare is used, the keep-alive connection that has idled longest since its answer is closed, and a connection that
// finishes an answer then ends instead of idling, so the spare frees again. A connection beyond that is not refused: it
// waits in the listen backlog until one ends (its request is then served), so a client that opens many connections gets
// slower answers, never a 503. A connection's thread is joined when the next connection is accepted, or at stop(), so
// there are never more threads than maxConnections + 1. A connection that sends nothing for `receiveTimeout` is closed
// (an idle keep-alive one too: replies say `Keep-Alive: timeout=` with less, 5 s at most, so the client lets it go
// first), a connection the server ends after an answer (an error, `Connection: close`, a stream) lingers before it is
// closed (net::linger_close: up to 500 ms, 300 ms without input), so it holds its slot a little longer, and a body over `maxBody` gets 413 with a JSON-RPC error that says what to do instead. The listener is polled,
// so stop() never waits on a full backlog.
#pragma once

#include <chrono>
#include <cstddef>
#include <functional>
#include <memory>
#include <optional>
#include <string>
#include <string_view>

#include "fa/core/types.h"

namespace fa {

struct McpHttpOptions {
    // A call still running after this is answered as an event stream (see above).
    std::chrono::milliseconds streamAfter{std::chrono::seconds(10)};
    // Connections served at the same time, plus one spare (see above); more wait until one ends.
    int maxConnections = 16;
    // A connection that sends nothing for this long (between requests, or in the middle of one) is closed; a send that
    // cannot go out for this long gives the connection up too.
    std::chrono::milliseconds receiveTimeout{std::chrono::seconds(30)};
    // The largest request body. A tool call that carries more (a big file as base64) gets 413.
    std::size_t maxBody = 8 * 1024 * 1024;
};

class McpHttpServer {
public:
    // One JSON-RPC message in, the serialized reply out (nullopt = none), e.g. `McpServer(host).handle_message(m)`.
    // Called on a thread of its own per request; several requests call it at the same time. One that throws ends nothing:
    // the request gets a JSON-RPC Internal error (-32603) with its id, a notification 202, and the failure is logged.
    using Handler = std::function<std::optional<std::string>(std::string_view message)>;

    // Sends a server notification (one serialized JSON-RPC message) on the request being handled; false once the client
    // has gone (the handler may stop reporting). Safe to call from any thread while the handler runs.
    using Notify = std::function<bool(const std::string& message)>;
    // Like Handler, with the way to notify the client during the call: `McpServer s(host);
    // s.set_notification_sink(notify); return s.handle_message(m);`. A client that does not accept
    // text/event-stream gets the reply only (the notifications are dropped).
    using StreamHandler = std::function<std::optional<std::string>(std::string_view message, const Notify& notify)>;

    McpHttpServer();
    ~McpHttpServer();  // stop()
    McpHttpServer(const McpHttpServer&) = delete;
    McpHttpServer& operator=(const McpHttpServer&) = delete;

    // Listens on 127.0.0.1 (a free port) and returns the endpoint, "http://127.0.0.1:<port>/mcp/<token>".
    Result<std::string> start(Handler handler, std::chrono::milliseconds streamAfter = std::chrono::seconds(10));
    Result<std::string> start(StreamHandler handler, std::chrono::milliseconds streamAfter = std::chrono::seconds(10));
    Result<std::string> start(StreamHandler handler, const McpHttpOptions& options);
    // Closes the listener and every connection, then waits for their threads: a handler that is still running must
    // return first (make it fail fast before calling stop()). Not to be called from a handler.
    void stop();
    const std::string& url() const;  // "" when not running
    // Threads of connections that were not joined yet: never more than maxConnections + 1 (tests).
    std::size_t connection_threads() const;

private:
    struct Impl;
    std::unique_ptr<Impl> impl_;
};

}  // namespace fa
