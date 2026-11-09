#include "fa/mcp/http_server.h"

#include <algorithm>
#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <deque>
#include <exception>
#include <future>
#include <map>
#include <mutex>
#include <optional>
#include <random>
#include <thread>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "fa/tooling/net.h"

namespace fa {

namespace {

using net::Socket;
using net::kNoSocket;
using net::close_socket;
using net::send_all;

constexpr std::size_t kMaxHeader = 64 * 1024;

enum class Received { Data, Closed, Failed };  // Failed: an error, the receive timeout, or stop() shut the socket

Received receive(Socket s, std::string& buf) {
    char chunk[16384];
    const auto n = net::recv_some(s, chunk, sizeof chunk);
    if (n == 0) return Received::Closed;
    if (n < 0) return Received::Failed;
    buf.append(chunk, static_cast<std::size_t>(n));
    return Received::Data;
}

std::string size_text(std::size_t bytes) {
    char out[32];
    if (bytes < 1024 * 1024) std::snprintf(out, sizeof out, "%.1f KiB", static_cast<double>(bytes) / 1024.0);
    else std::snprintf(out, sizeof out, "%.1f MiB", static_cast<double>(bytes) / (1024.0 * 1024.0));
    return out;
}

// Sends one response; returns whether the connection stays open.
bool reply(Socket s, int status, const char* reason, const std::string& body, bool keepAlive, const char* extra = "") {
    std::string out = "HTTP/1.1 " + std::to_string(status) + " " + reason + "\r\n";
    if (!body.empty()) out += "Content-Type: application/json\r\n";
    if (status != 204) out += "Content-Length: " + std::to_string(body.size()) + "\r\n";  // 204 has no body and no length
    out += extra;
    if (!keepAlive) out += "Connection: close\r\n";
    out += "\r\n" + body;
    return send_all(s, out) && keepAlive;
}

// A request (a method and an id), alone or in a batch: what must get a response, unless it was cancelled.
bool carries_request(const std::string& body) {
    const Json parsed = Json::parse(body, nullptr, false);
    auto is_request = [](const Json& m) {
        return m.is_object() && m.contains("method") && m.contains("id") && !m["id"].is_null();
    };
    if (parsed.is_array()) return std::any_of(parsed.begin(), parsed.end(), is_request);
    return is_request(parsed);
}

// The answer when the handler throws (it should not: McpServer::handle_message does not): a JSON-RPC Internal error
// for a request, carrying its id when the body is one request; nothing for notifications and responses (202).
std::optional<std::string> handler_failure(const std::string& body, const std::string& what) {
    ::fa::log(LogLevel::Error, "mcp", "The MCP endpoint's handler failed: " + what);
    if (!carries_request(body)) return std::nullopt;
    const Json parsed = Json::parse(body, nullptr, false);
    Json id = nullptr;
    if (parsed.is_object()) {
        const auto it = parsed.find("id");
        if (it != parsed.end() && (it->is_string() || it->is_number())) id = *it;
    }
    return Json::object({{"jsonrpc", "2.0"},
                         {"id", id},
                         {"error", Json::object({{"code", -32603}, {"message", "Internal error: " + what}})}})
        .dump(-1, ' ', false, Json::error_handler_t::replace);
}

std::string random_token() {
    std::random_device rd;  // not simulation state: a secret for the endpoint's path
    char hex[33];
    for (int i = 0; i < 4; ++i) std::snprintf(hex + i * 8, 9, "%08x", static_cast<unsigned>(rd()));
    return std::string(hex, 32);
}

}  // namespace

struct McpHttpServer::Impl {
    StreamHandler handler;
    McpHttpOptions options;
    std::string url, path, keepAliveHeader;
    Socket listener = kNoSocket;
    std::uint16_t port = 0;
    std::optional<net::SocketRuntime> sockets;  // Windows: WSAStartup for as long as the server runs
    std::thread acceptThread;
    std::mutex mu;  // guards everything below
    std::condition_variable slotFree;  // a connection ended, or stop()
    bool stopping = false;
    int active = 0;  // connections being served
    // The connections being served, by number. `idle`: kept alive after an answer, waiting for the next request.
    struct Connection {
        Socket socket = kNoSocket;
        bool idle = false;
        bool evicted = false;  // closed by close_oldest_idle_locked: a request read after that is not handled
        std::chrono::steady_clock::time_point idleSince;
    };
    std::map<std::uint64_t, Connection> connections;
    std::map<std::uint64_t, std::thread> threads;  // by connection number
    std::vector<std::uint64_t> finished;           // connections whose thread is ending: joined by the accept thread
    std::uint64_t nextConnection = 0;

    // Joins the threads of the connections that ended (each is past its last use of anything shared).
    void reap() {
        std::vector<std::thread> done;
        {
            std::lock_guard<std::mutex> lock(mu);
            for (std::uint64_t id : finished) {
                auto it = threads.find(id);
                if (it == threads.end()) continue;
                done.push_back(std::move(it->second));
                threads.erase(it);
            }
            finished.clear();
        }
        for (std::thread& t : done) t.join();
    }

    // Over maxConnections (the spare slot is in use): the connection that has idled longest since its last answer is
    // closed, so the next client (a notifications/cancelled for a call that runs) is not left waiting behind connections
    // that only keep alive. Under `mu`.
    void close_oldest_idle_locked() {
        auto oldest = connections.end();
        for (auto it = connections.begin(); it != connections.end(); ++it)
            if (it->second.idle && (oldest == connections.end() || it->second.idleSince < oldest->second.idleSince)) oldest = it;
        if (oldest == connections.end()) return;
        oldest->second.idle = false;                  // closed once
        oldest->second.evicted = true;                // a request its recv() already got is dropped, never run
        net::shutdown_socket(oldest->second.socket);  // its thread's recv() ends; the thread closes the socket
    }

    // A connection waits for its next request (`idle`) or got one. Returns false when it should end instead: it has
    // answered a request and the server is over maxConnections, or it was closed for another client while it waited
    // (evicted: what it read then is not handled; its client sees the connection close and can send it again).
    bool set_idle(std::uint64_t id, bool idle) {
        std::lock_guard<std::mutex> lock(mu);
        auto it = connections.find(id);
        if (it == connections.end()) return !idle;
        if (it->second.evicted) return false;
        if (idle && active > options.maxConnections) return false;
        it->second.idle = idle;
        if (idle) it->second.idleSince = std::chrono::steady_clock::now();
        return true;
    }

    void accept_loop() {
        for (;;) {
            reap();
            {
                // Bounded: maxConnections, plus one spare slot so that a client gets in when every connection is taken
                // (a cancel for a call that runs). Beyond that the next client waits in the listen backlog until a
                // connection ends.
                std::unique_lock<std::mutex> lock(mu);
                slotFree.wait(lock, [this] { return stopping || active <= options.maxConnections; });
                if (stopping) return;
            }
            // Polled, so that stop() needs no connection to wake a blocked accept() (one could not get through a full
            // backlog on macOS and Windows).
            const int ready = net::wait_readable(listener, 100);
            {
                std::lock_guard<std::mutex> lock(mu);
                if (stopping) return;
            }
            if (ready == 0) continue;
            if (ready < 0) {
                std::this_thread::sleep_for(std::chrono::milliseconds(50));
                continue;
            }
            // Non-blocking: a client that reset its connection between the poll and accept() leaves nothing to accept,
            // and a blocking accept() would then wait for the next client (macOS, the BSDs) where stop() cannot wake it.
            Socket c = kNoSocket;
            const net::Accepted got = net::accept_pending(listener, c);
            if (got == net::Accepted::Nothing) continue;
            reap();  // connections that ended meanwhile: their threads go before a new one starts
            std::unique_lock<std::mutex> lock(mu);
            if (stopping) {
                if (c != kNoSocket) close_socket(c);
                return;
            }
            if (got == net::Accepted::Failed) {  // e.g. out of file descriptors: try again shortly
                lock.unlock();
                std::this_thread::sleep_for(std::chrono::milliseconds(50));
                continue;
            }
            const int timeoutMs = static_cast<int>(std::min<long long>(options.receiveTimeout.count(), 24LL * 3600 * 1000));
            net::set_io_timeouts(c, timeoutMs, timeoutMs);  // a silent or stuck client frees its slot
            const std::uint64_t id = nextConnection++;
            connections[id].socket = c;
            ++active;
            if (active > options.maxConnections) close_oldest_idle_locked();
            threads.emplace(id, std::thread([this, c, id] {
                std::string buf;
                bool answered = false;
                while (serve_one(c, id, answered, buf)) answered = true;
                {
                    std::lock_guard<std::mutex> lock(mu);
                    connections.erase(id);  // stop() must not touch its socket any more
                }
                close_socket(c);
                {
                    std::lock_guard<std::mutex> lock(mu);
                    --active;
                    finished.push_back(id);
                }
                slotFree.notify_all();
            }));
        }
    }

    // Reads and answers one request (HTTP/1.1, keep-alive); false when the connection is done. `answered`: the connection
    // answered a request before, so while it waits for the next one it is idle (close_oldest_idle_locked may close it).
    bool serve_one(Socket c, std::uint64_t id, bool answered, std::string& buf) {
        bool idle = answered && buf.empty();
        if (idle && !set_idle(id, true)) return false;
        std::size_t headEnd;
        while ((headEnd = buf.find("\r\n\r\n")) == std::string::npos) {
            if (buf.size() > kMaxHeader) return reply(c, 431, "Request Header Fields Too Large", "", false);
            const Received got = receive(c, buf);
            if (idle) {
                idle = false;
                if (!set_idle(id, false)) return false;  // evicted while it waited: the request is not run
            }
            if (got == Received::Failed && !buf.empty()) return reply(c, 408, "Request Timeout", "", false);  // half a request
            if (got != Received::Data) return false;
        }
        const std::vector<std::string> lines = split(std::string_view(buf).substr(0, headEnd), '\n');
        const std::vector<std::string> request = lines.empty() ? std::vector<std::string>{} : split(trim(lines[0]), ' ');
        if (request.size() != 3) return reply(c, 400, "Bad Request", "", false);
        std::map<std::string, std::string> headers;  // lowercase names
        for (std::size_t i = 1; i < lines.size(); ++i) {
            if (const auto colon = lines[i].find(':'); colon != std::string::npos)
                headers[to_lower(lines[i].substr(0, colon))] = std::string(trim(std::string_view(lines[i]).substr(colon + 1)));
        }
        const std::string& method = request[0];
        if (request[1] != path) return reply(c, 404, "Not Found", "", false);
        if (method != "POST") return reply(c, 405, "Method Not Allowed", "", false, "Allow: POST\r\n");  // no SSE stream, no session
        const auto len = headers.find("content-length");
        if (len == headers.end()) return reply(c, 411, "Length Required", "", false);
        const unsigned long long declared = std::strtoull(len->second.c_str(), nullptr, 10);
        if (declared > options.maxBody) {
            // Teaches what to do instead, as a JSON-RPC error the client shows its model. The body is not read: the
            // connection ends after the answer (linger_close keeps the unread body from resetting it away).
            const Json error = Json::object(
                {{"jsonrpc", "2.0"},
                 {"id", nullptr},
                 {"error",
                  Json::object({{"code", -32600},
                                {"message", "The request is " + size_text(static_cast<std::size_t>(std::min<unsigned long long>(declared, SIZE_MAX))) +
                                                ", over the " + size_text(options.maxBody) + " a request to this MCP endpoint may carry."},
                                {"data", Json::object({{"hint", "Do not send a big file's bytes through a tool call (fs.write with "
                                                                "base64): put the file into the project folder another way (a CLI "
                                                                "agent copies it with its shell), or send it in smaller parts."}})}})}});
            reply(c, 413, "Content Too Large", error.dump(), false);
            net::linger_close(c);
            return false;
        }
        const std::size_t size = static_cast<std::size_t>(declared);
        if (iequals(headers["expect"], "100-continue") && !send_all(c, "HTTP/1.1 100 Continue\r\n\r\n")) return false;
        const std::size_t bodyAt = headEnd + 4;
        while (buf.size() < bodyAt + size) {
            const Received got = receive(c, buf);
            if (got == Received::Failed) return reply(c, 408, "Request Timeout", "", false);
            if (got != Received::Data) return false;
        }
        const std::string body = buf.substr(bodyAt, size);
        buf.erase(0, bodyAt + size);
        const bool keepAlive = !iequals(headers["connection"], "close");
        // A tool call can run for minutes (ai_run hands a whole task to the worker), longer than an HTTP client waits
        // for an answer (fetch gives up after 5 idle minutes). So a call still running after `streamAfter`, or one
        // that notifies the client (progress), is answered as an event stream at once: notifications go out as they
        // come, a comment line every 15 s keeps it alive, and the reply ends it.
        const bool canStream = headers["accept"].find("text/event-stream") != std::string::npos;
        struct Call {
            std::mutex mu;
            std::condition_variable cv;
            std::deque<std::string> out;  // notifications not written yet
            std::optional<std::string> response;
            bool done = false;
            bool closed = false;  // the client is gone, or does not take notifications
        };
        auto call = std::make_shared<Call>();
        call->closed = !canStream;  // the handler's notifications have nowhere to go
        const Notify notify = [call](const std::string& message) {
            std::lock_guard<std::mutex> lock(call->mu);
            if (call->closed) return false;
            call->out.push_back(message);
            call->cv.notify_all();
            return true;
        };
        auto pending = std::async(std::launch::async, [&, call] {
            std::optional<std::string> r;
            try {
                r = handler(body, notify);
            } catch (const std::exception& e) {  // never rethrown by pending.get(): that would end the editor
                r = handler_failure(body, e.what());
            } catch (...) {
                r = handler_failure(body, "unknown exception");
            }
            std::lock_guard<std::mutex> lock(call->mu);
            call->response = std::move(r);
            call->done = true;
            call->cv.notify_all();
        });
        std::unique_lock<std::mutex> lock(call->mu);
        call->cv.wait_for(lock, options.streamAfter, [&] { return call->done || !call->out.empty(); });
        if (!call->done || !call->out.empty()) {
            if (!canStream) {  // cannot stream: wait for the reply like a plain call
                call->cv.wait(lock, [&] { return call->done; });
            } else {
                lock.unlock();
                bool open = send_all(c, "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nCache-Control: no-cache\r\n"
                                        "Connection: close\r\n\r\n");
                lock.lock();
                for (;;) {
                    if (!open) call->closed = true;
                    if (call->out.empty() && !call->done)
                        if (!call->cv.wait_for(lock, std::chrono::seconds(15), [&] { return call->done || !call->out.empty(); })) {
                            lock.unlock();
                            open = open && send_all(c, ": working\n\n");
                            lock.lock();
                            continue;
                        }
                    std::deque<std::string> batch;
                    batch.swap(call->out);
                    const bool finished = call->done;
                    lock.unlock();
                    for (const std::string& m : batch) open = open && send_all(c, "event: message\ndata: " + m + "\n\n");
                    lock.lock();
                    if (finished && call->out.empty()) break;
                }
                lock.unlock();
                pending.get();  // stop() needs the handler done anyway
                if (open && call->response) send_all(c, "event: message\ndata: " + std::string(trim(*call->response)) + "\n\n");
                return false;  // the stream ends with the connection
            }
        }
        lock.unlock();
        pending.get();
        const char* extra = keepAlive ? keepAliveHeader.c_str() : "";
        if (!call->response) {
            // No reply: 202 for notifications and responses only. A request that has none was cancelled
            // (notifications/cancelled) and never gets one: a client that takes event streams gets an empty one, which
            // ends with the connection (MCP Streamable HTTP lets the server close a stream before the response); one that
            // does not gets 204.
            if (!carries_request(body)) return reply(c, 202, "Accepted", "", keepAlive, extra);
            if (!canStream) return reply(c, 204, "No Content", "", keepAlive, extra);
            send_all(c, "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nCache-Control: no-cache\r\n"
                        "Connection: close\r\n\r\n");
            return false;
        }
        return reply(c, 200, "OK", *call->response, keepAlive, extra);
    }
};

McpHttpServer::McpHttpServer() : impl_(std::make_unique<Impl>()) {}
McpHttpServer::~McpHttpServer() { stop(); }

const std::string& McpHttpServer::url() const { return impl_->url; }

std::size_t McpHttpServer::connection_threads() const {
    std::lock_guard<std::mutex> lock(impl_->mu);
    return impl_->threads.size();
}

Result<std::string> McpHttpServer::start(Handler handler, std::chrono::milliseconds streamAfter) {
    return start(StreamHandler([h = std::move(handler)](std::string_view m, const Notify&) { return h(m); }), streamAfter);
}

Result<std::string> McpHttpServer::start(StreamHandler handler, std::chrono::milliseconds streamAfter) {
    McpHttpOptions options;
    options.streamAfter = streamAfter;
    return start(std::move(handler), options);
}

Result<std::string> McpHttpServer::start(StreamHandler handler, const McpHttpOptions& options) {
    stop();
    Impl& m = *impl_;
    m.sockets.emplace();
    auto fail = [&m](const std::string& what) -> Result<std::string> {
        m.sockets.reset();
        return make_error("Cannot start the editor's MCP endpoint on 127.0.0.1. " + what,
                          "Another program may be blocking local connections (firewall, security software). "
                          "Allow loopback connections for the editor, then send the message again.");
    };
    if (!m.sockets->ok()) return fail("Windows sockets (WSAStartup) are unavailable.");
    auto listener = net::listen_tcp(false);
    if (!listener.ok()) return fail(listener.error().message);
    m.listener = listener->socket;
    m.port = listener->port;
    if (!net::set_nonblocking(m.listener, true)) {
        close_socket(m.listener);
        m.listener = kNoSocket;
        return fail("The listening socket cannot be made non-blocking.");
    }
    m.handler = std::move(handler);
    m.options = options;
    m.options.maxConnections = std::max(1, options.maxConnections);
    m.options.receiveTimeout = std::max(options.receiveTimeout, std::chrono::milliseconds(1));
    // Short (5 s at most), so a client lets an idle connection go soon and frees its slot; below the receive timeout, so
    // a client stops reusing an idle connection before the server closes it.
    const long long idleSeconds =
        std::max<long long>(1, std::min<long long>(5, m.options.receiveTimeout.count() * 2 / 3 / 1000));
    m.keepAliveHeader = "Keep-Alive: timeout=" + std::to_string(idleSeconds) + "\r\n";
    m.path = "/mcp/" + random_token();
    m.url = "http://127.0.0.1:" + std::to_string(m.port) + m.path;
    m.stopping = false;
    m.acceptThread = std::thread([&m] { m.accept_loop(); });
    return m.url;
}

void McpHttpServer::stop() {
    Impl& m = *impl_;
    if (!m.acceptThread.joinable()) return;
    {
        std::lock_guard<std::mutex> lock(m.mu);
        m.stopping = true;
        for (const auto& [id, conn] : m.connections) net::shutdown_socket(conn.socket);  // wakes threads blocked in recv()
    }
    m.slotFree.notify_all();  // an accept loop waiting for a free slot
    // The accept loop polls the listener and sees `stopping` within 100 ms: no connection is needed to wake it, so a full
    // backlog cannot hold stop() up.
    m.acceptThread.join();
    std::map<std::uint64_t, std::thread> threads;
    {
        std::lock_guard<std::mutex> lock(m.mu);
        threads.swap(m.threads);
    }
    for (auto& [id, t] : threads) t.join();  // each closes its own socket
    m.finished.clear();  // every thread has ended: nothing else touches it
    close_socket(m.listener);
    m.listener = kNoSocket;
    m.active = 0;
    m.nextConnection = 0;
    m.url.clear();
    m.path.clear();
    m.handler = nullptr;
    m.sockets.reset();
}

}  // namespace fa
