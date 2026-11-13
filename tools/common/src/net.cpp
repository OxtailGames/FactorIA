#include "fa/tooling/net.h"

#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX  // MinGW: winsock2.h includes windows.h, whose min/max macros break std::min
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <winsock2.h>
#include <ws2tcpip.h>
#include <iphlpapi.h>
#include <bcrypt.h>
#else
#include <arpa/inet.h>
#include <fcntl.h>
#include <ifaddrs.h>
#include <net/if.h>
#include <netinet/in.h>
#include <poll.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <unistd.h>
#if defined(__linux__) && !defined(__ANDROID__)
#include <sys/random.h>
#endif
#endif

#include <cerrno>
#include <cstdio>

#include <algorithm>
#include <cctype>
#include <chrono>
#include <cstdlib>
#include <cstring>

namespace fa::net {

namespace {

#ifdef _WIN32
using IoLen = int;
SOCKET native(Socket s) { return static_cast<SOCKET>(s); }
#else
using IoLen = std::size_t;
int native(Socket s) { return s; }
#endif
#ifdef MSG_NOSIGNAL
constexpr int kSendFlags = MSG_NOSIGNAL;  // a closed peer must not raise SIGPIPE (macOS sets SO_NOSIGPIPE instead)
#else
constexpr int kSendFlags = 0;
#endif

// 10/8, 172.16/12, 192.168/16 (host byte order).
bool is_private_v4(std::uint32_t a) { return (a >> 24) == 10 || (a >> 20) == 0xAC1 || (a >> 16) == 0xC0A8; }

std::string v4_text(std::uint32_t a) {
    return std::to_string(a >> 24) + "." + std::to_string((a >> 16) & 255) + "." + std::to_string((a >> 8) & 255) +
           "." + std::to_string(a & 255);
}

// Lower is better: Wi-Fi and Ethernet before virtual adapters (VPN, Docker, VM bridges, which a phone cannot reach).
int interface_rank(const std::string& name) {
    std::string n;
    for (char c : name) n += static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    for (const char* virt : {"docker",   "vbox", "virtualbox", "vmware",    "vmnet",   "veth", "br-",      "bridge",
                             "utun",     "tun",  "tap",        "vethernet", "hyper-v", "wsl",  "zerotier", "tailscale",
                             "loopback", "awdl", "llw",        "anpi",      "gif",     "stf"})
        if (n.find(virt) != std::string::npos) return 3;
    for (const char* wifi : {"wi-fi", "wifi", "wlan", "wireless"})
        if (n.find(wifi) != std::string::npos) return 0;
    if (n == "en0") return 0;  // macOS: the Wi-Fi on a laptop, the Ethernet on a desktop
    if (n.rfind("en", 0) == 0 || n.rfind("eth", 0) == 0 || n.find("ethernet") != std::string::npos) return 1;
    return 2;
}

}  // namespace

SocketRuntime::SocketRuntime() {
#ifdef _WIN32
    WSADATA data;
    ok_ = WSAStartup(MAKEWORD(2, 2), &data) == 0;
#endif
}

SocketRuntime::~SocketRuntime() {
#ifdef _WIN32
    if (ok_) WSACleanup();
#endif
}

void close_socket(Socket s) {
    if (s == kNoSocket) return;
#ifdef _WIN32
    ::closesocket(native(s));
#else
    ::close(native(s));
#endif
}

void shutdown_socket(Socket s) {
    if (s == kNoSocket) return;
#ifdef _WIN32
    ::shutdown(native(s), SD_BOTH);
#else
    ::shutdown(native(s), SHUT_RDWR);
#endif
}

bool send_all(Socket s, std::string_view data) {
    while (!data.empty()) {
        const auto n =
            ::send(native(s), data.data(), static_cast<IoLen>(std::min<std::size_t>(data.size(), 1 << 20)), kSendFlags);
#ifndef _WIN32
        if (n < 0 && errno == EINTR) continue;  // a signal arrived: not an error
#endif
        if (n <= 0) return false;
        data.remove_prefix(static_cast<std::size_t>(n));
    }
    return true;
}

std::ptrdiff_t recv_some(Socket s, char* buffer, std::size_t size) {
    while (true) {
        const auto n = static_cast<std::ptrdiff_t>(::recv(native(s), buffer, static_cast<IoLen>(size), 0));
#ifndef _WIN32
        if (n < 0 && errno == EINTR) continue;
#endif
        return n;
    }
}

void linger_close(Socket s, int maxMs, std::size_t maxBytes, int idleMs) {
    if (s == kNoSocket) return;
#ifdef _WIN32
    ::shutdown(native(s), SD_SEND);
#else
    ::shutdown(native(s), SHUT_WR);
#endif
    set_io_timeouts(s, idleMs, idleMs);  // a client that went quiet ends the wait
    const auto deadline = std::chrono::steady_clock::now() + std::chrono::milliseconds(std::max(maxMs, 0));
    char buf[4096];
    std::size_t total = 0;
    while (total < maxBytes && std::chrono::steady_clock::now() < deadline) {
        const std::ptrdiff_t n = recv_some(s, buf, sizeof buf);
        if (n <= 0) break;  // the client closed (0) or has nothing more to say (timeout, error)
        total += static_cast<std::size_t>(n);
    }
}

bool secure_random(void* buffer, std::size_t size) {
    if (size == 0) return true;
#if defined(_WIN32)
    return BCryptGenRandom(nullptr, static_cast<PUCHAR>(buffer), static_cast<ULONG>(size),
                           BCRYPT_USE_SYSTEM_PREFERRED_RNG) == 0;
#elif defined(__APPLE__)
    arc4random_buf(buffer, size);
    return true;
#else
#if defined(__linux__) && !defined(__ANDROID__)
    std::size_t got = 0;
    while (got < size) {
        const ssize_t n = ::getrandom(static_cast<char*>(buffer) + got, size - got, 0);
        if (n < 0 && errno == EINTR) continue;
        if (n <= 0) break;
        got += static_cast<std::size_t>(n);
    }
    if (got == size) return true;
#endif
    std::FILE* f = std::fopen("/dev/urandom", "rb");
    if (!f) return false;
    const bool ok = std::fread(buffer, 1, size, f) == size;
    std::fclose(f);
    return ok;
#endif
}

bool constant_time_equal(std::string_view a, std::string_view b) {
    if (a.size() != b.size()) return false;  // the length of a token is not a secret
    unsigned char diff = 0;
    for (std::size_t i = 0; i < a.size(); ++i)
        diff |= static_cast<unsigned char>(a[i]) ^ static_cast<unsigned char>(b[i]);
    return diff == 0;
}

void set_io_timeouts(Socket s, int recvMs, int sendMs) {
    recvMs = std::max(recvMs, 0);
    sendMs = std::max(sendMs, 0);
#ifdef _WIN32
    const DWORD r = static_cast<DWORD>(recvMs), w = static_cast<DWORD>(sendMs);
    ::setsockopt(native(s), SOL_SOCKET, SO_RCVTIMEO, reinterpret_cast<const char*>(&r), sizeof r);
    ::setsockopt(native(s), SOL_SOCKET, SO_SNDTIMEO, reinterpret_cast<const char*>(&w), sizeof w);
#else
    timeval r{}, w{};
    r.tv_sec = recvMs / 1000;
    r.tv_usec = (recvMs % 1000) * 1000;
    w.tv_sec = sendMs / 1000;
    w.tv_usec = (sendMs % 1000) * 1000;
    ::setsockopt(native(s), SOL_SOCKET, SO_RCVTIMEO, &r, sizeof r);
    ::setsockopt(native(s), SOL_SOCKET, SO_SNDTIMEO, &w, sizeof w);
#endif
}

void disable_sigpipe(Socket s) {
#ifdef SO_NOSIGPIPE
    int one = 1;
    ::setsockopt(native(s), SOL_SOCKET, SO_NOSIGPIPE, &one, sizeof one);
#else
    (void)s;
#endif
}

Result<Listener> listen_tcp(bool allInterfaces, int backlog) {
    auto fail = [](Socket s, const std::string& what) -> Result<Listener> {
        close_socket(s);
        return make_error("Cannot listen for connections: " + what + " failed.",
                          "Another program may be blocking connections (firewall, security software). Allow the "
                          "program, then try again.");
    };
    const Socket s = static_cast<Socket>(::socket(AF_INET, SOCK_STREAM, IPPROTO_TCP));
    if (s == kNoSocket) return fail(kNoSocket, "socket()");
    sockaddr_in addr{};
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(allInterfaces ? INADDR_ANY : INADDR_LOOPBACK);
    addr.sin_port = 0;  // any free port
#ifdef _WIN32
    {
        // Without it another program can bind the same port on a more specific address and receive our connections.
        const BOOL exclusive = TRUE;
        ::setsockopt(native(s), SOL_SOCKET, SO_EXCLUSIVEADDRUSE, reinterpret_cast<const char*>(&exclusive),
                     sizeof exclusive);
    }
#endif
    if (::bind(native(s), reinterpret_cast<sockaddr*>(&addr), sizeof addr) != 0) return fail(s, "bind()");
    socklen_t length = sizeof addr;
    if (::getsockname(native(s), reinterpret_cast<sockaddr*>(&addr), &length) != 0) return fail(s, "getsockname()");
    if (::listen(native(s), backlog) != 0) return fail(s, "listen()");
    Listener l;
    l.socket = s;
    l.port = ntohs(addr.sin_port);
    return l;
}

int wait_readable(Socket s, int timeoutMs) {
    if (s == kNoSocket) return -1;
    timeoutMs = std::max(0, timeoutMs);
#ifdef _WIN32
    fd_set readable;
    FD_ZERO(&readable);
    FD_SET(native(s), &readable);
    timeval tv;
    tv.tv_sec = static_cast<long>(timeoutMs / 1000);
    tv.tv_usec = static_cast<long>((timeoutMs % 1000) * 1000);
    const int n = ::select(0, &readable, nullptr, nullptr, &tv);  // the first argument is ignored on Windows
    if (n == SOCKET_ERROR) return -1;
    return n > 0 ? 1 : 0;
#else
    pollfd p{};
    p.fd = native(s);
    p.events = POLLIN;
    for (;;) {
        const int n = ::poll(&p, 1, timeoutMs);
        if (n < 0 && errno == EINTR) continue;  // a signal: the wait is short, start it again
        if (n < 0) return -1;
        if (n == 0) return 0;
        return (p.revents & (POLLIN | POLLHUP | POLLERR)) != 0 ? 1 : -1;
    }
#endif
}

Socket accept_connection(Socket listener) {
    Socket c;
    while (true) {
        c = static_cast<Socket>(::accept(native(listener), nullptr, nullptr));
#ifndef _WIN32
        if (c == kNoSocket && errno == EINTR) continue;
#endif
        break;
    }
    if (c != kNoSocket) disable_sigpipe(c);
    return c;
}

bool set_nonblocking(Socket s, bool nonBlocking) {
    if (s == kNoSocket) return false;
#ifdef _WIN32
    u_long mode = nonBlocking ? 1 : 0;
    return ::ioctlsocket(native(s), FIONBIO, &mode) == 0;
#else
    const int flags = ::fcntl(native(s), F_GETFL, 0);
    if (flags < 0) return false;
    const int wanted = nonBlocking ? (flags | O_NONBLOCK) : (flags & ~O_NONBLOCK);
    return wanted == flags || ::fcntl(native(s), F_SETFL, wanted) == 0;
#endif
}

Accepted accept_pending(Socket listener, Socket& out) {
    out = kNoSocket;
    for (;;) {
        const Socket c = static_cast<Socket>(::accept(native(listener), nullptr, nullptr));
        if (c != kNoSocket) {
            // Windows and the BSDs (macOS) give the connection the listener's non-blocking mode: the server's reads wait.
            set_nonblocking(c, false);
            disable_sigpipe(c);
            out = c;
            return Accepted::Connection;
        }
#ifdef _WIN32
        const int e = ::WSAGetLastError();
        if (e == WSAEINTR) continue;
        // Nothing waits (the client that made the listener readable reset its connection before accept()).
        if (e == WSAEWOULDBLOCK || e == WSAECONNRESET) return Accepted::Nothing;
#else
        const int e = errno;
        if (e == EINTR) continue;
        if (e == EAGAIN || e == EWOULDBLOCK || e == ECONNABORTED || e == EPROTO || e == ECONNRESET)
            return Accepted::Nothing;
#endif
        return Accepted::Failed;
    }
}

Socket connect_loopback(std::uint16_t port) {
    const Socket s = static_cast<Socket>(::socket(AF_INET, SOCK_STREAM, IPPROTO_TCP));
    if (s == kNoSocket) return kNoSocket;
    sockaddr_in addr{};
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    addr.sin_port = htons(port);
    if (::connect(native(s), reinterpret_cast<sockaddr*>(&addr), sizeof addr) != 0) {
        close_socket(s);
        return kNoSocket;
    }
    disable_sigpipe(s);
    return s;
}

std::vector<std::string> lan_addresses() {
    struct Found {
        int rank;
        std::string name, address;
    };
    std::vector<Found> found;
#ifdef _WIN32
    ULONG size = 0;
    constexpr ULONG flags = GAA_FLAG_SKIP_ANYCAST | GAA_FLAG_SKIP_MULTICAST | GAA_FLAG_SKIP_DNS_SERVER;
    std::vector<char> buffer;
    ULONG rc = ERROR_BUFFER_OVERFLOW;
    for (int attempt = 0; attempt < 3 && rc == ERROR_BUFFER_OVERFLOW; ++attempt) {
        buffer.assign(size ? size : 15000, 0);
        size = static_cast<ULONG>(buffer.size());
        rc = GetAdaptersAddresses(AF_INET, flags, nullptr, reinterpret_cast<IP_ADAPTER_ADDRESSES*>(buffer.data()),
                                  &size);
    }
    if (rc != NO_ERROR) return {};
    for (auto* a = reinterpret_cast<IP_ADAPTER_ADDRESSES*>(buffer.data()); a; a = a->Next) {
        if (a->OperStatus != IfOperStatusUp || a->IfType == IF_TYPE_SOFTWARE_LOOPBACK) continue;
        std::string name;
        for (const wchar_t* w = a->FriendlyName; w && *w; ++w) name += *w < 128 ? static_cast<char>(*w) : '?';
        for (auto* u = a->FirstUnicastAddress; u; u = u->Next) {
            if (!u->Address.lpSockaddr || u->Address.lpSockaddr->sa_family != AF_INET) continue;
            const auto* in = reinterpret_cast<const sockaddr_in*>(u->Address.lpSockaddr);
            const std::uint32_t host = ntohl(in->sin_addr.s_addr);
            if (is_private_v4(host))
                found.push_back(
                    {interface_rank(name) + (a->IfType == IF_TYPE_IEEE80211 ? -1 : 0), name, v4_text(host)});
        }
    }
#else
    ifaddrs* list = nullptr;
    if (::getifaddrs(&list) != 0) return {};
    for (const ifaddrs* a = list; a; a = a->ifa_next) {
        if (!a->ifa_addr || a->ifa_addr->sa_family != AF_INET) continue;
        if (!(a->ifa_flags & IFF_UP) || (a->ifa_flags & IFF_LOOPBACK)) continue;
        const auto* in = reinterpret_cast<const sockaddr_in*>(a->ifa_addr);
        const std::uint32_t host = ntohl(in->sin_addr.s_addr);
        if (is_private_v4(host))
            found.push_back(
                {interface_rank(a->ifa_name ? a->ifa_name : ""), a->ifa_name ? a->ifa_name : "", v4_text(host)});
    }
    ::freeifaddrs(list);
#endif
    std::stable_sort(found.begin(), found.end(), [](const Found& a, const Found& b) { return a.rank < b.rank; });
    std::vector<std::string> out;
    for (const Found& f : found)
        if (std::find(out.begin(), out.end(), f.address) == out.end()) out.push_back(f.address);
    return out;
}

}  // namespace fa::net
