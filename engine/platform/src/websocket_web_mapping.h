// What the browser's WebSocket reports, turned into the events and states of fa/platform/websocket.h. Pure C++ (no
// Emscripten): websocket_web.cpp hands every browser event to a Mapper and applies what it answers, and the platform tests
// run the same Mapper on any host, so the rules (the order of Error and Close, the state before the event, the size
// check on arrival, the teaching messages) are checked without a browser.
#pragma once

#include <cstddef>
#include <string>
#include <vector>

#include "fa/platform/websocket.h"

namespace fa::web_ws {

// What went wrong, for the words of the Error event.
enum class Problem {
    CouldNotConnect,   // the browser's error event before the connection opened
    ConnectionLost,    // an error, or a close without a closing handshake, after it opened
    ConnectTimeout,    // the browser has no timeout: ours ended the attempt
    CloseTimeout,      // the server did not answer our close frame within kWebSocketCloseWaitSec
    ClosedBeforeOpen,  // close() was called while connecting
};

struct Text {
    std::string message, hint;
};

// The message and the hint of an Error event. `host` is "host" or "host:port" of the address; `secureAddress` is true for
// wss://; `pageHttps` is true when the page the game runs in came over https.
Text problem_text(Problem problem, const std::string& host, bool secureAddress, bool pageHttps, double timeoutSec);

// The browser's `new WebSocket(...)` threw: `name` and `message` are the exception's. The text of connect()'s error.
Text constructor_failure_text(const std::string& name, const std::string& message, const std::string& url,
                              bool pageHttps);

// The browser cannot send handshake headers: a request that has some is an error that names them.
Result<void> check_request(const WebSocketRequest& request);

// What send_text / send_binary check before they hand the message to the browser (state, size, unsent data).
inline constexpr std::size_t kMaxBuffered = 16u * 1024 * 1024;
Result<void> check_send(WebSocketState state, std::size_t size, std::size_t maxMessageBytes, std::size_t buffered);

// A JSON string literal, for handing a list of subprotocols to JavaScript as JSON text.
std::string json_quote(const std::string& s);
// ["a","b"]
std::string json_string_array(const std::vector<std::string>& items);

struct BrowserEvent {
    enum class Kind {
        Open,            // onopen; `data` = ws.protocol
        Text,            // onmessage with a string; `size` = its UTF-8 length, `data` the message (see wants_payload)
        Binary,          // onmessage with an ArrayBuffer; `size` = byteLength
        Error,           // onerror
        Close,           // onclose: `code`, `reason`, `wasClean`
        ConnectTimeout,  // the timer of the connection attempt ran out
        CloseTimeout,    // the timer of the closing handshake ran out
    };
    Kind kind = Kind::Error;
    std::string data;
    std::size_t size = 0;
    int code = 0;
    std::string reason;
    bool wasClean = false;
};

// What the glue does after a call: the events to push (state() already shows the new state), and what to do with the
// browser's socket.
struct Reaction {
    std::vector<WebSocketEvent> events;
    bool stopBrowser =
        false;  // remove the handlers and close the browser's socket (closeCode/closeReason for its close())
    bool startClosing = false;  // call the browser's close(closeCode, closeReason) and start the closing timer
    int closeCode = 0;
    std::string closeReason;
};

// The rules of one connection. Single threaded (the browser's main thread).
class Mapper {
public:
    Mapper(std::string host, bool secureAddress, bool pageHttps, std::size_t maxMessageBytes, double connectTimeoutSec);

    WebSocketState state() const { return state_; }
    bool finished() const { return finished_; }

    // false: the glue need not copy the payload of this message (it is too long, or the connection is over).
    bool wants_payload(BrowserEvent::Kind kind, std::size_t size) const;
    Reaction on_browser(BrowserEvent event);
    // close() of the game, arguments already checked with ws::check_close_request.
    Reaction on_close_requested(int code, const std::string& reason);
    // The queue ended before the browser did (overflow): the connection is over, the queue holds its own Error and Close.
    Reaction on_queue_ended();
    // After poll() drained the events: a connection abandoned while connecting is Closed now.
    void after_poll();

private:
    Reaction fail(Problem problem, bool stopBrowser, bool abandoned = false);

    std::string host_;
    bool secure_, pageHttps_;
    std::size_t max_;
    double timeoutSec_;
    WebSocketState state_ = WebSocketState::Connecting;
    bool opened_ = false;
    bool errored_ = false;    // an Error event was queued (the browser's onclose follows it)
    bool finished_ = false;   // the Close event was queued: nothing more is reported
    bool abandoned_ = false;  // close() came while connecting: Closing until poll() delivered Error and Close
};

}  // namespace fa::web_ws
