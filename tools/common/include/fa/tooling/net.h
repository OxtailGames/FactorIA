// The TCP socket layer the developer tools share (the editor's MCP endpoint in fa_mcp, the web server of
// project.serve_web in fa/tooling/serve_web.h, and the tests that talk to them): the same Windows/POSIX differences
// handled once. Blocking sockets, IPv4 only. The header includes no operating-system header.
#pragma once

#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/types.h"

namespace fa::net {

#ifdef _WIN32
using Socket = std::uintptr_t;  // SOCKET
inline constexpr Socket kNoSocket = ~static_cast<Socket>(0);
#else
using Socket = int;
inline constexpr Socket kNoSocket = -1;
#endif

// Windows needs WSAStartup before the first socket (counted by the system: every holder starts and cleans up its own
// share); elsewhere this does nothing. Hold one for as long as any socket of yours lives.
class SocketRuntime {
public:
    SocketRuntime();
    ~SocketRuntime();
    SocketRuntime(const SocketRuntime&) = delete;
    SocketRuntime& operator=(const SocketRuntime&) = delete;
    bool ok() const { return ok_; }

private:
    bool ok_ = true;
};

void close_socket(Socket s);
// Both directions: wakes a thread blocked in recv() or accept() on it.
void shutdown_socket(Socket s);
// Writes all of `data`; false when the peer is gone or the send timeout (set_io_timeouts) ran out. A closed peer never
// raises SIGPIPE.
bool send_all(Socket s, std::string_view data);
// Ends a connection after an error answer without a reset: stops sending (the client sees the end of the answer), then reads and
// discards what the client is still sending, for at most `maxMs` and `maxBytes` (it stops earlier when nothing arrives for `idleMs`: a client that is slow to read on a loaded machine still gets the answer). Closing a socket with unread input makes the
// system send an RST that can wipe the answer from the client's receive queue (Windows and macOS do it), so the client would
// see "connection reset" instead of the status. The caller closes the socket afterwards.
void linger_close(Socket s, int maxMs = 500, std::size_t maxBytes = 256 * 1024, int idleMs = 300);
// Reads up to `size` bytes: the count, 0 when the peer closed, a negative number on an error or when the receive timeout ran out.
std::ptrdiff_t recv_some(Socket s, char* buffer, std::size_t size);
// Fills `buffer` with random bytes from the operating system's generator (BCryptGenRandom, arc4random_buf, getrandom or
// /dev/urandom), the kind a secret may come from. False when it is not available: never use a weaker source then.
bool secure_random(void* buffer, std::size_t size);
// Compares two strings without stopping at the first difference (the time does not tell how much of a secret matched).
bool constant_time_equal(std::string_view a, std::string_view b);
// Gives up a recv()/send() that waits longer than this (milliseconds; 0 = never).
void set_io_timeouts(Socket s, int recvMs, int sendMs);
// macOS: a write to a closed peer must not raise SIGPIPE (other systems pass MSG_NOSIGNAL to send()).
void disable_sigpipe(Socket s);

struct Listener {
    Socket socket = kNoSocket;
    std::uint16_t port = 0;  // the port the system chose
};
// Listens on a free port of 127.0.0.1, or of every interface (0.0.0.0, so the LAN can connect) when `allInterfaces`.
// On Windows the port is taken exclusively (SO_EXCLUSIVEADDRUSE): another program of this user cannot bind the same port
// on a more specific address and receive the connections meant for this one.
// The caller owns the socket (close_socket). The error says which call failed.
Result<Listener> listen_tcp(bool allInterfaces, int backlog = 16);
// accept(); kNoSocket when the listener was shut down or the call failed.
Socket accept_connection(Socket listener);
// Waits at most `timeoutMs` for `s` to be readable (a listener: a connection to accept; a connection: data or its end).
// 1 = readable, 0 = the time ran out, -1 = an error (the socket was closed or shut down on some systems). A loop that
// polls with it can see a stop flag without a connection to wake it.
int wait_readable(Socket s, int timeoutMs);
// A client connection to 127.0.0.1:<port>; kNoSocket when it fails. For waking an accept() and for tests.
Socket connect_loopback(std::uint16_t port);

// The IPv4 addresses of this computer on private networks (10/8, 172.16/12, 192.168/16) whose interface is up, the
// ones another device on the same Wi-Fi or Ethernet can reach, most likely first (names like en0, wlan0, Wi-Fi first).
// Empty without a network.
std::vector<std::string> lan_addresses();

}  // namespace fa::net
