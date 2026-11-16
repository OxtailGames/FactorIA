// RFC 6455 codec (fa/platform/websocket_codec.h): pure functions and the Session state machine.
#include "fa/platform/websocket_codec.h"

#include <algorithm>
#include <cctype>
#include <chrono>
#include <cstdlib>
#include <exception>
#include <iterator>
#include <string>

#include "fa/core/hash.h"
#include "fa/core/strings.h"

namespace fa::ws {

namespace {

constexpr const char* kGuid = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

bool is_token_char(unsigned char c) {
    if (std::isalnum(c)) return true;
    return c != 0 && std::string_view("!#$%&'*+-.^_`|~").find(static_cast<char>(c)) != std::string_view::npos;
}

bool is_token(std::string_view s) {
    return !s.empty() &&
           std::all_of(s.begin(), s.end(), [](char c) { return is_token_char(static_cast<unsigned char>(c)); });
}

std::string shown(std::string_view s, std::size_t max = 60) {
    std::string out;
    for (char c : s.substr(0, max)) out += (static_cast<unsigned char>(c) < 0x20 || c == 0x7f) ? '.' : c;
    if (s.size() > max) out += "...";
    return out;
}

// The raw 20 bytes of a SHA-1 (core gives the hex text).
std::string sha1_raw(std::string_view data) {
    const std::string hex = sha1_hex(data);
    std::string raw;
    for (std::size_t i = 0; i + 1 < hex.size(); i += 2)
        raw += static_cast<char>(std::stoi(hex.substr(i, 2), nullptr, 16));
    return raw;
}

struct Head {
    std::string firstLine;
    std::vector<std::pair<std::string, std::string>> headers;  // names in lower case, values trimmed
    bool ok = false;
    std::string problem;
    std::string value(const std::string& name) const {
        std::string joined;
        for (const auto& [k, v] : headers)
            if (k == name) joined += (joined.empty() ? "" : ", ") + v;
        return joined;
    }
};

Head parse_head(std::string_view text) {
    Head h;
    std::size_t pos = 0;
    bool first = true;
    while (pos < text.size()) {
        std::size_t end = text.find("\r\n", pos);
        if (end == std::string_view::npos) end = text.size();
        const std::string_view line = text.substr(pos, end - pos);
        pos = end + 2;
        if (line.empty()) break;
        if (first) {
            h.firstLine = std::string(line);
            first = false;
            continue;
        }
        const std::size_t colon = line.find(':');
        if (colon == std::string_view::npos || colon == 0) {
            h.problem = "the header line " + std::string("\"") + shown(line) + "\" has no \"name: value\" form";
            return h;
        }
        h.headers.emplace_back(to_lower(trim(line.substr(0, colon))), std::string(trim(line.substr(colon + 1))));
    }
    h.ok = !first;
    if (!h.ok && h.problem.empty()) h.problem = "the head is empty";
    return h;
}

// True when the comma separated `list` has `token` (case-insensitive).
bool list_has(const std::string& list, std::string_view token) {
    for (const std::string& part : split(list, ',', true))
        if (iequals(trim(part), token)) return true;
    return false;
}

}  // namespace

bool close_code_valid_on_wire(int code) {
    return (code >= 1000 && code <= 1003) || (code >= 1007 && code <= 1014) || (code >= 3000 && code <= 4999);
}
bool close_code_app_may_send(int code) { return code == 1000 || (code >= 3000 && code <= 4999); }

Result<void> check_close_request(int code, std::string_view reason) {
    if (code != 0 && !close_code_app_may_send(code))
        return make_error("the close code " + std::to_string(code) + " cannot be used",
                          "Use 1000 (normal) or a code from 3000 to 4999 that your server defines.");
    if (reason.size() > kMaxCloseReasonBytes)
        return make_error("the close reason is " + std::to_string(reason.size()) + " bytes; the most is " +
                              std::to_string(kMaxCloseReasonBytes),
                          "Shorten the reason.");
    if (!is_valid_utf8(reason)) return make_error("the close reason is not valid UTF-8", "Use a plain text reason.");
    return {};
}

std::string encode_frame(Opcode opcode, std::string_view payload, bool fin, const std::uint8_t* maskKey) {
    std::string out;
    const std::uint64_t n = payload.size();
    out.reserve(payload.size() + 14);
    out.push_back(static_cast<char>((fin ? 0x80 : 0) | static_cast<std::uint8_t>(opcode)));
    const std::uint8_t maskBit = maskKey ? 0x80 : 0;
    if (n < 126) {
        out.push_back(static_cast<char>(maskBit | n));
    } else if (n <= 0xFFFF) {
        out.push_back(static_cast<char>(maskBit | 126));
        out.push_back(static_cast<char>(n >> 8));
        out.push_back(static_cast<char>(n & 0xFF));
    } else {
        out.push_back(static_cast<char>(maskBit | 127));
        for (int shift = 56; shift >= 0; shift -= 8) out.push_back(static_cast<char>((n >> shift) & 0xFF));
    }
    if (maskKey) {
        out.append(reinterpret_cast<const char*>(maskKey), 4);
        for (std::size_t i = 0; i < payload.size(); ++i)
            out.push_back(static_cast<char>(static_cast<std::uint8_t>(payload[i]) ^ maskKey[i & 3]));
    } else {
        out.append(payload);
    }
    return out;
}

std::string close_payload(int code, std::string_view reason) {
    if (code == 0) return {};
    std::string p;
    p.push_back(static_cast<char>((code >> 8) & 0xFF));
    p.push_back(static_cast<char>(code & 0xFF));
    p.append(reason);
    return p;
}

// ------------------------------------------------------------------------------------------------------ handshake ---
std::string Url::host_header() const {
    std::string h = host.find(':') != std::string::npos ? "[" + host + "]" : host;
    if (port != (secure ? 443 : 80)) h += ":" + std::to_string(port);
    return h;
}

Result<Url> parse_url(std::string_view url) {
    Url out;
    std::string_view rest = url;
    if (starts_with(rest, "wss://")) {
        out.secure = true;
        rest.remove_prefix(6);
    } else if (starts_with(rest, "ws://")) {
        rest.remove_prefix(5);
    } else {
        return make_error("the address \"" + shown(url) + "\" does not start with ws:// or wss://",
                          "Write the address as wss://host/path (ws:// only for a server on your own computer).");
    }
    if (const std::size_t hash = rest.find('#'); hash != std::string_view::npos) rest = rest.substr(0, hash);
    const std::size_t pathStart = rest.find_first_of("/?");
    std::string_view authority = rest.substr(0, pathStart);
    out.path = pathStart == std::string_view::npos ? "/" : std::string(rest.substr(pathStart));
    if (out.path[0] == '?') out.path = "/" + out.path;
    std::string_view portText;
    if (!authority.empty() && authority[0] == '[') {
        const std::size_t close = authority.find(']');
        if (close == std::string_view::npos)
            return make_error("the address has an unclosed [ in its host", "Write [::1]:8080.");
        out.host = std::string(authority.substr(1, close - 1));
        if (authority.size() > close + 1) {
            if (authority[close + 1] != ':')
                return make_error("the address has text after the IPv6 host", "Write [::1]:8080.");
            portText = authority.substr(close + 2);
        }
    } else if (const std::size_t colon = authority.rfind(':'); colon != std::string_view::npos) {
        out.host = std::string(authority.substr(0, colon));
        portText = authority.substr(colon + 1);
    } else {
        out.host = std::string(authority);
    }
    out.host = to_lower(out.host);
    if (out.host.empty()) return make_error("the address has no host", "Write it as wss://host/path.");
    for (char c : out.host)
        if (!(std::isalnum(static_cast<unsigned char>(c)) || c == '-' || c == '.' || c == '_' || c == ':' || c == '%'))
            return make_error("the host \"" + shown(out.host) + "\" has a character that a host name cannot have",
                              "Use letters, digits, - and . (or an IPv6 address in brackets).");
    out.port = out.secure ? 443 : 80;
    if (!portText.empty()) {
        int n = 0;
        for (char c : portText) {
            if (c < '0' || c > '9' || n > 65535)
                return make_error("the port \"" + std::string(portText) + "\" is not a number from 1 to 65535",
                                  "Write it like wss://host:8443/path.");
            n = n * 10 + (c - '0');
        }
        if (n < 1 || n > 65535)
            return make_error("the port \"" + std::string(portText) + "\" is not a number from 1 to 65535",
                              "Write it like wss://host:8443/path.");
        out.port = n;
    }
    return out;
}

std::string make_client_key(const std::uint8_t random16[16]) { return base64_encode(random16, 16); }

std::string accept_key(std::string_view clientKey) {
    const std::string raw = sha1_raw(std::string(clientKey) + kGuid);
    return base64_encode(raw.data(), raw.size());
}

Result<std::string> build_client_request(const Url& url, std::string_view key,
                                         const std::vector<std::string>& subprotocols,
                                         const std::vector<std::pair<std::string, std::string>>& headers) {
    std::string out = "GET " + url.path + " HTTP/1.1\r\nHost: " + url.host_header() +
                      "\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: " + std::string(key) +
                      "\r\nSec-WebSocket-Version: 13\r\n";
    if (!subprotocols.empty()) {
        out += "Sec-WebSocket-Protocol: ";
        for (std::size_t i = 0; i < subprotocols.size(); ++i) {
            if (!is_token(subprotocols[i]))
                return make_error(
                    "the subprotocol \"" + shown(subprotocols[i]) + "\" is not a valid token",
                    "A subprotocol is a name such as \"chat\" or \"v1.game.example.com\": letters, digits and "
                    "the characters ! # $ % & ' * + - . ^ _ ` | ~ only.");
            out += (i ? ", " : "") + subprotocols[i];
        }
        out += "\r\n";
    }
    static const char* const kOwn[] = {"host", "upgrade", "connection", "content-length", "transfer-encoding",
                                       "te",   "trailer", "keep-alive", "expect"};
    for (const auto& [name, value] : headers) {
        const std::string lower = to_lower(name);
        const bool own = std::any_of(std::begin(kOwn), std::end(kOwn), [&](const char* o) { return lower == o; }) ||
                         starts_with(lower, "sec-") || starts_with(lower, "proxy-");
        if (!is_token(name))
            return make_error("the header name \"" + shown(name) + "\" is not valid",
                              "A header name has letters, digits and - only, e.g. \"Authorization\".");
        if (own)
            return make_error("the header \"" + name + "\" is set by the WebSocket handshake itself",
                              "Remove it; use the subprotocols option for Sec-WebSocket-Protocol.");
        if (value.find_first_of(std::string("\r\n\0", 3)) != std::string::npos)
            return make_error("the value of the header \"" + name + "\" has a line break",
                              "A header value is one line of text.");
        out += name + ": " + value + "\r\n";
    }
    out += "\r\n";
    return out;
}

std::size_t find_head_end(std::string_view data) {
    const std::size_t at = data.find("\r\n\r\n");
    return at == std::string_view::npos ? at : at + 4;
}

HandshakeResult check_server_response(std::string_view headText, std::string_view key,
                                      const std::vector<std::string>& offered) {
    HandshakeResult r;
    auto fail = [&](std::string error, std::string hint) {
        r.ok = false;
        r.error = std::move(error);
        r.hint = std::move(hint);
        return r;
    };
    const Head head = parse_head(headText);
    if (!head.ok || !starts_with(head.firstLine, "HTTP/"))
        return fail(
            "the server did not answer with HTTP (it sent \"" + shown(headText.empty() ? head.firstLine : headText) +
                "\")",
            "Check the address and the port: a WebSocket server answers the upgrade with an HTTP head. A wss:// "
            "address needs a server with TLS, a ws:// one needs a server without.");
    // "HTTP/1.1 101 Switching Protocols"
    const std::size_t sp = head.firstLine.find(' ');
    if (sp == std::string::npos)
        return fail("the server's status line \"" + shown(head.firstLine) + "\" has no status code", "");
    r.status = std::atoi(head.firstLine.c_str() + sp + 1);
    if (r.status != 101) {
        std::string reason = head.firstLine.substr(sp + 1);
        if (const std::size_t sp2 = reason.find(' '); sp2 != std::string::npos) reason = reason.substr(sp2 + 1);
        std::string hint;
        switch (r.status) {
            case 200:
                hint = "The address answers like a web page, not like a WebSocket endpoint: check the path of the "
                       "address.";
                break;
            case 301:
            case 302:
            case 307:
            case 308:
                hint = "The server redirects: use the address it redirects to (a WebSocket connection does not follow "
                       "redirects).";
                break;
            case 400:
                hint = "The server did not understand the upgrade: check the path and the subprotocols the server "
                       "supports.";
                break;
            case 401:
            case 403:
                hint = "The server wants a login or refuses this game: send a token in the headers option or in the "
                       "address, "
                       "and check what the server allows.";
                break;
            case 404: hint = "There is no WebSocket endpoint at this path: check the path of the address."; break;
            case 426: hint = "The server asks for another protocol version or for TLS: try wss://."; break;
            default:
                hint = r.status >= 500 ? "The server failed: try again later."
                                       : "Check the address and what the server expects.";
        }
        return fail("the server refused the WebSocket upgrade with HTTP " + std::to_string(r.status) +
                        (reason.empty() ? "" : " " + shown(reason)),
                    hint);
    }
    if (!iequals(trim(head.value("upgrade")), "websocket"))
        return fail("the server answered 101 without \"Upgrade: websocket\"",
                    "The address is not served by a WebSocket server (a proxy may be in the way).");
    if (!list_has(head.value("connection"), "upgrade"))
        return fail("the server answered 101 without \"Connection: Upgrade\"", "A proxy may be in the way.");
    if (head.value("sec-websocket-accept") != accept_key(key))
        return fail("the server's Sec-WebSocket-Accept does not match the key sent",
                    "The server is not following RFC 6455, or a proxy rewrote the handshake.");
    if (!head.value("sec-websocket-extensions").empty())
        return fail("the server chose a WebSocket extension (\"" + shown(head.value("sec-websocket-extensions")) +
                        "\") that was never offered",
                    "The server breaks RFC 6455: an extension must be offered by the client first.");
    const std::string chosen = head.value("sec-websocket-protocol");
    if (!chosen.empty()) {
        if (std::find(offered.begin(), offered.end(), chosen) == offered.end())
            return fail("the server chose the subprotocol \"" + shown(chosen) + "\", which was not offered",
                        offered.empty() ? "The game offered no subprotocol: pass the protocols option."
                                        : "Offered: " + join(offered, ", ") + ".");
        r.subprotocol = chosen;
    }
    r.ok = true;
    return r;
}

std::string ClientRequest::header(const std::string& lowerName) const {
    for (const auto& [k, v] : headers)
        if (k == lowerName) return v;
    return {};
}

Result<ClientRequest> parse_client_request(std::string_view headText) {
    const Head head = parse_head(headText);
    if (!head.ok) return make_error("the request is not HTTP: " + head.problem);
    const std::vector<std::string> parts = split(head.firstLine, ' ', true);
    if (parts.size() != 3 || parts[0] != "GET" || !starts_with(parts[2], "HTTP/1."))
        return make_error("the request line \"" + shown(head.firstLine) + "\" is not \"GET /path HTTP/1.1\"");
    ClientRequest req;
    req.path = parts[1];
    req.headers = head.headers;
    if (!iequals(trim(head.value("upgrade")), "websocket"))
        return make_error("the request has no \"Upgrade: websocket\"");
    if (!list_has(head.value("connection"), "upgrade")) return make_error("the request has no \"Connection: Upgrade\"");
    if (head.value("sec-websocket-version") != "13")
        return make_error("Sec-WebSocket-Version is \"" + shown(head.value("sec-websocket-version")) + "\", not 13");
    req.key = head.value("sec-websocket-key");
    if (base64_decode(req.key).size() != 16) return make_error("Sec-WebSocket-Key is not the base64 of 16 bytes");
    for (const std::string& p : split(head.value("sec-websocket-protocol"), ',', true))
        req.subprotocols.emplace_back(trim(p));
    return req;
}

std::string build_server_response(const ClientRequest& request, std::string_view subprotocol) {
    std::string out =
        "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: " +
        accept_key(request.key) + "\r\n";
    if (!subprotocol.empty()) out += "Sec-WebSocket-Protocol: " + std::string(subprotocol) + "\r\n";
    return out + "\r\n";
}

std::string build_reject_response(int status, std::string_view reason) {
    return "HTTP/1.1 " + std::to_string(status) + " " + std::string(reason) +
           "\r\nContent-Length: 0\r\nConnection: close\r\n\r\n";
}

// ------------------------------------------------------------------------------------------------------ session ---
Session::Session(SessionOptions options) : options_(std::move(options)) {}

std::uint32_t Session::next_mask() {
    if (options_.maskKey) return options_.maskKey();
    if (fallback_ == 0) {
        try {
            if (!random_) random_ = std::make_unique<std::random_device>();
            return static_cast<std::uint32_t>((*random_)());
        } catch (const std::exception&) {
            // No entropy source (std::system_error): the keys come from a splitmix64 sequence seeded from the clock and
            // this session's address. Masking keeps proxies from reading frames as HTTP; it is not encryption.
            const auto t = static_cast<std::uint64_t>(std::chrono::steady_clock::now().time_since_epoch().count());
            fallback_ = (t ^ static_cast<std::uint64_t>(reinterpret_cast<std::uintptr_t>(this))) | 1;
        }
    }
    std::uint64_t z = (fallback_ += 0x9E3779B97F4A7C15ull);
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ull;
    z = (z ^ (z >> 27)) * 0x94D049BB133111EBull;
    return static_cast<std::uint32_t>((z ^ (z >> 31)) >> 32);
}

void Session::queue(Opcode op, std::string_view payload, bool fin) {
    if (options_.role == Role::Client) {
        const std::uint32_t k = next_mask();
        const std::uint8_t key[4] = {static_cast<std::uint8_t>(k >> 24), static_cast<std::uint8_t>(k >> 16),
                                     static_cast<std::uint8_t>(k >> 8), static_cast<std::uint8_t>(k)};
        out_ += encode_frame(op, payload, fin, key);
    } else {
        out_ += encode_frame(op, payload, fin, nullptr);
    }
}

std::string Session::take_output() {
    std::string out;
    out.swap(out_);
    return out;
}

Result<void> Session::send_text(std::string_view text) {
    if (closeSent_ || failed_)
        return make_error("the connection is closing", "Wait for the \"close\" event, then connect again.");
    if (text.size() > options_.maxMessageBytes)
        return make_error("the message is " + std::to_string(text.size()) + " bytes; the most is " +
                              std::to_string(options_.maxMessageBytes),
                          "Split the data into smaller messages.");
    if (!is_valid_utf8(text))
        return make_error("the text is not valid UTF-8",
                          "Send other data with send_binary, or encode it as UTF-8 first.");
    queue(Opcode::Text, text);
    return {};
}

Result<void> Session::send_binary(const void* data, std::size_t size) {
    if (closeSent_ || failed_)
        return make_error("the connection is closing", "Wait for the \"close\" event, then connect again.");
    if (size > options_.maxMessageBytes)
        return make_error("the message is " + std::to_string(size) + " bytes; the most is " +
                              std::to_string(options_.maxMessageBytes),
                          "Split the data into smaller messages.");
    queue(Opcode::Binary, std::string_view(static_cast<const char*>(data), size));
    return {};
}

Result<void> Session::send_ping(std::string_view payload) {
    if (closeSent_ || failed_) return make_error("the connection is closing");
    if (payload.size() > kMaxControlPayload)
        return make_error("a ping carries at most " + std::to_string(kMaxControlPayload) + " bytes");
    queue(Opcode::Ping, payload);
    return {};
}

Result<void> Session::close(int code, std::string_view reason) {
    if (code != 0 && !close_code_valid_on_wire(code))
        return make_error("close code " + std::to_string(code) + " cannot be sent",
                          "Use 1000 (normal) or a code from 3000 to 4999 that your server defines.");
    if (reason.size() > kMaxCloseReasonBytes)
        return make_error("the close reason is " + std::to_string(reason.size()) + " bytes; the most is " +
                          std::to_string(kMaxCloseReasonBytes));
    if (!is_valid_utf8(reason)) return make_error("the close reason is not valid UTF-8");
    if (closeSent_ || failed_) return {};
    queue(Opcode::Close, close_payload(code == 0 && !reason.empty() ? close_code::kNormal : code, reason));
    closeSent_ = true;
    return {};
}

void Session::fail(int code, std::string error, std::string hint, std::vector<Event>& events) {
    if (failed_) return;
    failed_ = true;
    if (hint.empty())
        hint = "The server (or a proxy in front of it) is not following the WebSocket protocol (RFC 6455); check it, "
               "then connect again.";
    if (!closeSent_) {
        queue(Opcode::Close, close_payload(code, {}));
        closeSent_ = true;
    }
    Event e;
    e.type = Event::Type::Failure;
    e.code = code;
    e.error = std::move(error);
    e.hint = std::move(hint);
    events.push_back(std::move(e));
}

void Session::feed(const void* data, std::size_t size, std::vector<Event>& events) {
    const auto* p = static_cast<const std::uint8_t*>(data);
    std::size_t n = size;
    // Bytes of the header that are needed in total, from the ones read so far.
    auto header_need = [&]() -> std::size_t {
        if (in_.size() < 2) return 2;
        const std::uint8_t len7 = static_cast<std::uint8_t>(in_[1]) & 0x7F;
        return 2 + (len7 == 126 ? 2 : len7 == 127 ? 8 : 0) + ((static_cast<std::uint8_t>(in_[1]) & 0x80) ? 4 : 0);
    };
    while (n > 0 && !failed_ && !done()) {
        if (stage_ == Stage::Header) {
            while (n > 0 && in_.size() < header_need()) {
                in_.push_back(static_cast<char>(*p++));
                --n;
            }
            if (in_.size() < header_need()) break;
            const std::uint8_t b0 = static_cast<std::uint8_t>(in_[0]), b1 = static_cast<std::uint8_t>(in_[1]);
            fin_ = (b0 & 0x80) != 0;
            const unsigned op = b0 & 0x0F;
            masked_ = (b1 & 0x80) != 0;
            const std::uint8_t len7 = b1 & 0x7F;
            std::uint64_t len = len7;
            std::size_t at = 2;
            if (len7 == 126) {
                len = (std::uint64_t(static_cast<std::uint8_t>(in_[2])) << 8) | static_cast<std::uint8_t>(in_[3]);
                at = 4;
            } else if (len7 == 127) {
                len = 0;
                for (int i = 0; i < 8; ++i) len = (len << 8) | static_cast<std::uint8_t>(in_[2 + i]);
                at = 10;
            }
            if (masked_) {
                for (int i = 0; i < 4; ++i) mask_[i] = static_cast<std::uint8_t>(in_[at + i]);
            }
            in_.clear();
            const bool control = (op & 0x8) != 0;
            if (b0 & 0x70) {
                fail(close_code::kProtocolError, "a frame has a reserved bit (RSV1-3) set",
                     "No WebSocket extension (such as permessage-deflate) is negotiated, so the server must not use "
                     "one.",
                     events);
                break;
            }
            if (!(op <= 2 || (op >= 8 && op <= 10))) {
                fail(close_code::kProtocolError, "a frame has the unknown opcode " + std::to_string(op), "", events);
                break;
            }
            if (options_.role == Role::Server && !masked_) {
                fail(close_code::kProtocolError, "a client frame is not masked",
                     "A client must mask every frame (RFC 6455 5.1).", events);
                break;
            }
            if (options_.role == Role::Client && masked_) {
                fail(close_code::kProtocolError, "a server frame is masked",
                     "A server must not mask its frames (RFC 6455 5.1).", events);
                break;
            }
            if ((len7 == 126 && len < 126) || (len7 == 127 && (len < 65536 || (len >> 63) != 0))) {
                fail(close_code::kProtocolError, "a frame length is not in its shortest form or has the top bit set",
                     "", events);
                break;
            }
            opcode_ = static_cast<Opcode>(op);
            if (control) {
                if (!fin_ || len > kMaxControlPayload) {
                    fail(close_code::kProtocolError,
                         !fin_ ? "a control frame (ping, pong, close) is fragmented"
                               : "a control frame is longer than 125 bytes",
                         "", events);
                    break;
                }
                control_.clear();
            } else if (opcode_ == Opcode::Continuation) {
                if (!inMessage_) {
                    fail(close_code::kProtocolError, "a continuation frame arrived with no message to continue", "",
                         events);
                    break;
                }
            } else if (inMessage_) {
                fail(close_code::kProtocolError, "a new message started before the previous one ended", "", events);
                break;
            }
            if (!control) {
                // message_.size() never exceeds the limit, so this subtraction cannot wrap; the comparison is in 64 bits.
                if (len > static_cast<std::uint64_t>(options_.maxMessageBytes - message_.size())) {
                    fail(close_code::kMessageTooBig,
                         "a message is longer than the limit of " + std::to_string(options_.maxMessageBytes) + " bytes",
                         "Send smaller messages, or raise the maxMessageBytes option.", events);
                    break;
                }
                if (opcode_ != Opcode::Continuation) {
                    inMessage_ = true;
                    messageIsText_ = opcode_ == Opcode::Text;
                    message_.clear();
                }
                message_.reserve(message_.size() + static_cast<std::size_t>(std::min<std::uint64_t>(len, 64 * 1024)));
            }
            remaining_ = len;
            index_ = 0;
            stage_ = Stage::Payload;
            if (remaining_ == 0) {
                finish_frame(events);
                stage_ = Stage::Header;
            }
            continue;
        }
        // Payload.
        const std::size_t take = static_cast<std::size_t>(std::min<std::uint64_t>(remaining_, n));
        std::string& dst = (opcode_ == Opcode::Continuation || opcode_ == Opcode::Text || opcode_ == Opcode::Binary)
                               ? message_
                               : control_;
        const std::size_t base = dst.size();
        dst.append(reinterpret_cast<const char*>(p), take);
        if (masked_)
            for (std::size_t i = 0; i < take; ++i)
                dst[base + i] = static_cast<char>(static_cast<std::uint8_t>(dst[base + i]) ^ mask_[(index_ + i) & 3]);
        index_ += take;
        remaining_ -= take;
        p += take;
        n -= take;
        if (remaining_ == 0) {
            finish_frame(events);
            stage_ = Stage::Header;
        }
    }
}

void Session::finish_frame(std::vector<Event>& events) {
    switch (opcode_) {
        case Opcode::Ping: {
            Event e;
            e.type = Event::Type::Ping;
            e.data = control_;
            events.push_back(std::move(e));
            if (!closeSent_) queue(Opcode::Pong, control_);
            return;
        }
        case Opcode::Pong: {
            Event e;
            e.type = Event::Type::Pong;
            e.data = control_;
            events.push_back(std::move(e));
            return;
        }
        case Opcode::Close: {
            int code = close_code::kNoStatus;
            std::string reason;
            if (control_.size() == 1) {
                fail(close_code::kProtocolError, "a close frame has a 1-byte payload",
                     "A close payload is empty or a 2-byte code and a reason.", events);
                return;
            }
            if (control_.size() >= 2) {
                code = (static_cast<std::uint8_t>(control_[0]) << 8) | static_cast<std::uint8_t>(control_[1]);
                reason = control_.substr(2);
                if (!close_code_valid_on_wire(code)) {
                    fail(close_code::kProtocolError,
                         "a close frame has the code " + std::to_string(code) + ", which is not allowed on the wire",
                         "", events);
                    return;
                }
                if (!is_valid_utf8(reason)) {
                    fail(close_code::kInvalidData, "the reason of a close frame is not valid UTF-8", "", events);
                    return;
                }
            }
            closeReceived_ = true;
            if (!closeSent_) {
                queue(Opcode::Close, close_payload(code == close_code::kNoStatus ? 0 : code, reason));
                closeSent_ = true;
            }
            Event e;
            e.type = Event::Type::Close;
            e.code = code;
            e.reason = std::move(reason);
            events.push_back(std::move(e));
            return;
        }
        default: break;
    }
    if (!fin_) return;  // more fragments to come
    inMessage_ = false;
    if (messageIsText_ && !is_valid_utf8(message_)) {
        message_.clear();
        fail(close_code::kInvalidData, "a text message is not valid UTF-8",
             "Text messages must be UTF-8; send other data as a binary message.", events);
        return;
    }
    Event e;
    e.type = messageIsText_ ? Event::Type::Text : Event::Type::Binary;
    e.data = std::move(message_);
    message_.clear();
    events.push_back(std::move(e));
}

}  // namespace fa::ws
