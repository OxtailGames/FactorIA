// macOS and iOS: NSURLSessionWebSocketTask (fa/platform/websocket.h, "nsurlsession"). The system brings the certificates, the
// proxy settings, TLS, the ping/pong keep-alive and the answers to the server's pings. App Transport Security applies as for
// http.fetch: plain ws:// is only allowed to loopback.
//
// It follows the pattern of fa/platform/websocket.h for every native client. Everything the network does reaches a Core (a
// shared_ptr: the event queue, the state, the flags) through the delegate of one ephemeral session and the completion blocks
// of the task; none of them touches the AppleWebSocket that the game holds. Destroying that handle abandons the queue, asks
// the task to close (1001, which takes no waiting) and returns; the session lets go of everything by itself.
//
// What NSURLSession does differently from the tcp client (docs/NETWORKING.md):
//   - a message is held whole before it is handed over: maximumMessageSize is set to maxMessageBytes (the system then fails
//     the task) and the size is checked again on arrival; either way the game gets Error then Close 1006.
//   - after close() the system reports the close as soon as it has sent the frame (didCloseWithCode, with the code and reason
//     that were asked for), so the Close event does not wait for the server's answer: wasClean is true, and the 5 s wait of
//     kWebSocketCloseWaitSec (Error, Close 1006) is only a safety net here. A close without a code is sent as 1000.
#import <Foundation/Foundation.h>

#include <algorithm>
#include <atomic>
#include <cstring>
#include <memory>
#include <mutex>
#include <string>

#include "fa/core/engine_version.h"
#include "fa/core/strings.h"
#include "fa/platform/websocket.h"
#include "fa/platform/websocket_codec.h"

namespace fa {

namespace {

// The most the game may have queued and not yet sent (the same as the tcp client): send_* fails above it.
constexpr std::size_t kMaxBuffered = 16u * 1024 * 1024;

std::string to_std(NSString* s) { return s ? std::string([s UTF8String]) : std::string(); }

std::string bytes_of(NSData* data) {
    if (!data || data.length == 0) return {};
    return std::string(static_cast<const char*>(data.bytes), data.length);
}

// Everything the delegate, the blocks and the game's handle share. Callbacks run on the session's queue, the game's calls on
// the game thread: the flags are atomic and the transitions out of Connecting and Open go through mutex_.
class Core {
public:
    Core(WebSocketRequest request, std::string host)
        : request_(std::move(request)),
          host_(std::move(host)),
          queue_(std::make_shared<WebSocketEventQueue>(WebSocketEventQueue::limit_for(request_.maxMessageBytes))) {}

    const std::shared_ptr<WebSocketEventQueue>& queue() const { return queue_; }
    WebSocketState state() const { return state_.load(); }
    std::size_t buffered() const { return buffered_.load(); }
    void add_buffered(std::size_t n) { buffered_ += n; }
    void sub_buffered(std::size_t n) { buffered_ -= n; }

    // The game let go of the connection: what is reported from now on is dropped.
    void abandon() {
        std::lock_guard<std::mutex> lock(mutex_);
        abandoned_ = true;
        queue_->abandon();
    }

    // --- the game thread ---------------------------------------------------------------------------------------------

    Result<void> can_send(std::size_t size) const {
        const WebSocketState s = state_.load();
        if (s == WebSocketState::Connecting)
            return make_error("the connection is not open yet", "Wait for the \"open\" event before sending.");
        if (s != WebSocketState::Open)
            return make_error("the connection is closing or closed", "Connect again to send.");
        if (size > request_.maxMessageBytes)
            return make_error("the message is " + std::to_string(size) + " bytes, above the limit of " +
                                  std::to_string(request_.maxMessageBytes) + " bytes",
                              "Send smaller messages, or raise maxMessageBytes in the options of websocket.connect.");
        if (buffered_.load() > kMaxBuffered)
            return make_error("more than " + std::to_string(kMaxBuffered / (1024 * 1024)) + " MB wait to be sent",
                              "Send less, or wait until bufferedAmount drops.");
        return {};
    }

    // What close() does to the state; returns false when there is nothing to send (already closing or closed). `connecting`
    // says the attempt is abandoned: the task is cancelled and its completion reports Error and Close 1006.
    bool begin_close(bool& connecting) {
        std::lock_guard<std::mutex> lock(mutex_);
        connecting = false;
        const WebSocketState s = state_.load();
        if (s == WebSocketState::Closing || s == WebSocketState::Closed) return false;
        if (s == WebSocketState::Connecting) {
            connecting = true;
            abortedConnecting_ = true;
        }
        state_ = WebSocketState::Closing;
        return true;
    }

    // --- the session's queue -----------------------------------------------------------------------------------------

    // The handshake is done. false: the task must be cancelled (the game gave up, or the queue ended).
    bool on_open(std::string subprotocol) {
        {
            std::lock_guard<std::mutex> lock(mutex_);
            if (finished_ || abandoned_ || abortedConnecting_) return false;
            state_ = WebSocketState::Open;
        }
        return queue_->push(WebSocketEvent::open(std::move(subprotocol)));
    }

    // A message arrived whole. false: the task must be cancelled (too big, or the queue ended); the failure is reported here.
    bool on_message(bool binary, std::string data) {
        if (data.size() > request_.maxMessageBytes) {
            fail("a message of " + std::to_string(data.size()) + " bytes is above the limit of " +
                     std::to_string(request_.maxMessageBytes) + " bytes",
                 "Raise maxMessageBytes in the options of websocket.connect, or make the server send smaller messages.");
            return false;
        }
        const bool ok =
            queue_->push(binary ? WebSocketEvent::binary(std::move(data)) : WebSocketEvent::text(std::move(data)));
        if (!ok) end_unreported();
        return ok;
    }

    // The receive loop got an error: the reason is kept for the completion of the task, which ends the connection.
    void note_error(NSError* error) {
        std::lock_guard<std::mutex> lock(mutex_);
        if (!lastError_ && error) lastError_ = error;
    }

    // The server (or our own close) ended the connection with a close frame.
    void on_closed(int code, std::string reason) {
        if (code == 0) code = ws::close_code::kNoStatus;
        end(WebSocketEvent::close(code, std::move(reason), true), nullptr);
    }

    // The task completed: with an error (the connection failed or broke) or without one.
    void on_complete(NSError* error, NSURLResponse* response) {
        std::string message, hint;
        int status = 0;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            if (finished_) return;
            if (abortedConnecting_) {
                message = "the connection was closed before it was open";
                hint = "close() was called before the connection opened; wait for the 'open' event, or ignore this error.";
            } else {
                if (!error) error = lastError_;
                describe(error, response, state_.load() == WebSocketState::Connecting, message, hint, status);
            }
        }
        fail(std::move(message), std::move(hint), status);
    }

    // kWebSocketCloseWaitSec passed after close() and the server has not answered: true when the connection was ended.
    bool on_close_timeout() {
        {
            std::lock_guard<std::mutex> lock(mutex_);
            if (finished_ || abandoned_) return false;
        }
        fail("the server did not answer the close within " + std::to_string(static_cast<int>(kWebSocketCloseWaitSec)) +
                 " seconds",
             "The connection was dropped; the server may be stuck.");
        return true;
    }

    // connectTimeoutSec passed: true when the connection was still being made and was ended.
    bool on_connect_timeout() {
        {
            std::lock_guard<std::mutex> lock(mutex_);
            if (finished_ || abandoned_ || state_.load() != WebSocketState::Connecting || abortedConnecting_)
                return false;
        }
        fail("timed out connecting to " + host_ + " after " +
                 std::to_string(static_cast<int>(request_.connectTimeoutSec)) + " seconds",
             "Check that the server is running and that the address is right, or raise the timeout of websocket.connect.");
        return true;
    }

    // Reports a failure: Error, then Close 1006, once.
    void fail(std::string message, std::string hint, int status = 0) {
        WebSocketEvent error = WebSocketEvent::failure(std::move(message), std::move(hint), status);
        end(WebSocketEvent::close(ws::close_code::kAbnormal, "", false), &error);
    }

private:
    // The queue ended under the callback (overflow): the state follows, nothing more is reported.
    void end_unreported() {
        std::lock_guard<std::mutex> lock(mutex_);
        finished_ = true;
        state_ = WebSocketState::Closed;
    }

    // Ends the connection once: the state first, then the events.
    void end(WebSocketEvent closeEvent, WebSocketEvent* errorEvent) {
        {
            std::lock_guard<std::mutex> lock(mutex_);
            if (finished_) return;
            finished_ = true;
            state_ = WebSocketState::Closed;  // before the events: when the game reads Close, state() is Closed
        }
        if (errorEvent) queue_->push(std::move(*errorEvent));
        queue_->push(std::move(closeEvent));
    }

    // What went wrong, in words. mutex_ held.
    void describe(NSError* error, NSURLResponse* response, bool handshake, std::string& message, std::string& hint,
                  int& status) const {
        NSHTTPURLResponse* http =
            [response isKindOfClass:[NSHTTPURLResponse class]] ? static_cast<NSHTTPURLResponse*>(response) : nil;
        if (http && http.statusCode != 101 && http.statusCode != 0 && handshake) {
            status = static_cast<int>(http.statusCode);
            message = "the server refused the WebSocket upgrade with HTTP " + std::to_string(status);
            switch (status) {
                case 301:
                case 302:
                case 303:
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
                           "address, and check what the server allows.";
                    break;
                case 404: hint = "There is no WebSocket endpoint at this path: check the path of the address."; break;
                case 426: hint = "The server asks for another protocol version or for TLS: try wss://."; break;
                default:
                    hint = status >= 500 ? "The server failed: try again later."
                                         : "Check the address and what the server expects.";
            }
            return;
        }
        if (!error) {
            message = handshake ? "the connection to " + host_ + " could not be opened"
                                : "the connection to " + host_ + " was lost";
            hint = "Check the connection; try again.";
            return;
        }
        const NSInteger code = error.code;
        NSString* domain = error.domain;
        const bool isUrl = [domain isEqualToString:NSURLErrorDomain];
        if (isUrl && code == NSURLErrorTimedOut) {
            message = "timed out connecting to " + host_;
            hint = "Check that the server is running and that the address is right, or raise the timeout of "
                   "websocket.connect.";
        } else if (isUrl && (code == NSURLErrorCannotFindHost || code == NSURLErrorDNSLookupFailed)) {
            message = "could not find the server " + host_;
            hint = "Check the address and the connection.";
        } else if (isUrl && (code == NSURLErrorCannotConnectToHost || code == NSURLErrorNotConnectedToInternet)) {
            message = "could not connect to " + host_;
            hint = "Check that the server is running and that the address and port are right.";
        } else if (isUrl && code == NSURLErrorNetworkConnectionLost) {
            message = "the connection to " + host_ + " was lost";
            hint = "Check the connection; try again.";
        } else if (isUrl && code <= NSURLErrorServerCertificateHasBadDate && code >= NSURLErrorClientCertificateRequired) {
            message = "the secure connection to " + host_ + " failed: " + to_std(error.localizedDescription);
            hint = "The server's certificate is not trusted by this computer (an expired certificate, a wrong clock, or a "
                   "proxy that rewrites traffic).";
        } else if (isUrl && code == NSURLErrorAppTransportSecurityRequiresSecureConnection) {
            message = "the system refuses a plain ws:// connection to " + host_;
            hint = "Use wss:// (plain ws:// is only allowed for localhost).";
        } else if ([domain isEqualToString:NSPOSIXErrorDomain] && code == EMSGSIZE) {
            message = "a message from " + host_ + " is above the limit of " + std::to_string(request_.maxMessageBytes) +
                      " bytes";
            hint = "Raise maxMessageBytes in the options of websocket.connect, or make the server send smaller messages.";
        } else if (isUrl && code == NSURLErrorBadServerResponse && handshake) {
            message = "the server at " + host_ + " did not answer the WebSocket upgrade correctly";
            hint = "Check the address and the path: a WebSocket server answers the upgrade with HTTP 101.";
        } else {
            message = std::string(handshake ? "could not open the connection to " : "the connection to ") + host_ +
                      (handshake ? ": " : " failed: ") + to_std(error.localizedDescription);
            hint = "Check the connection, and that the server is up.";
        }
    }

    WebSocketRequest request_;
    std::string host_;
    std::shared_ptr<WebSocketEventQueue> queue_;
    mutable std::mutex mutex_;  // guards the transitions out of Connecting and Open, finished_, abandoned_, lastError_
    std::atomic<WebSocketState> state_{WebSocketState::Connecting};
    std::atomic<std::size_t> buffered_{0};
    bool finished_ = false;
    bool abandoned_ = false;
    bool abortedConnecting_ = false;
    NSError* lastError_ = nil;
};

}  // namespace

}  // namespace fa

// The delegate of one session. It holds the Core and nothing of the game's handle.
@interface FaWebSocketDelegate : NSObject <NSURLSessionWebSocketDelegate> {
@public
    std::shared_ptr<fa::Core> core;
}
@end

@implementation FaWebSocketDelegate

- (void)URLSession:(NSURLSession*)session
          webSocketTask:(NSURLSessionWebSocketTask*)task
    didOpenWithProtocol:(NSString*)protocol {
    if (!core->on_open(protocol ? std::string([protocol UTF8String]) : std::string())) [task cancel];
}

- (void)URLSession:(NSURLSession*)session
       webSocketTask:(NSURLSessionWebSocketTask*)task
    didCloseWithCode:(NSURLSessionWebSocketCloseCode)closeCode
              reason:(NSData*)reason {
    core->on_closed(static_cast<int>(closeCode), fa::bytes_of(reason));
}

- (void)URLSession:(NSURLSession*)session task:(NSURLSessionTask*)task didCompleteWithError:(NSError*)error {
    core->on_complete(error, task.response);
}

@end

namespace fa {

namespace {

// Asks for the next message; re-arms itself after each one. The block holds the task and the Core, never the game's handle.
void arm_receive(NSURLSessionWebSocketTask* task, std::shared_ptr<Core> core) {
    [task receiveMessageWithCompletionHandler:^(NSURLSessionWebSocketMessage* message, NSError* error) {
        if (error || !message) {
                    core->note_error(error);  // the task's completion (or the close frame) ends the connection
            return;
        }
        bool ok;
        if (message.type == NSURLSessionWebSocketMessageTypeString) {
            NSData* utf8 = [message.string dataUsingEncoding:NSUTF8StringEncoding];
            ok = core->on_message(false, bytes_of(utf8));
        } else {
            ok = core->on_message(true, bytes_of(message.data));
        }
        if (!ok) {
            [task cancelWithCloseCode:NSURLSessionWebSocketCloseCodeMessageTooBig reason:nil];
            return;
        }
        arm_receive(task, core);
    }];
}

class AppleWebSocket final : public WebSocket {
public:
    AppleWebSocket(std::shared_ptr<Core> core, NSURLSession* session, NSURLSessionWebSocketTask* task)
        : core_(std::move(core)), session_(session), task_(task) {}

    // Three steps (fa/platform/websocket.h): abandon the queue, ask the transport to stop, return.
    ~AppleWebSocket() override {
        const WebSocketState s = core_->state();
        core_->abandon();
        @autoreleasepool {
            NSURLSession* session = session_;
            if (s == WebSocketState::Open) {
                // A close frame (1001) that takes no waiting; the session ends when the task does, and in any case after
                // the close wait.
                [task_ cancelWithCloseCode:NSURLSessionWebSocketCloseCodeGoingAway reason:nil];
                [session finishTasksAndInvalidate];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, static_cast<int64_t>(kWebSocketCloseWaitSec * NSEC_PER_SEC)),
                               dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
                                   [session invalidateAndCancel];
                               });
            } else {
                [session invalidateAndCancel];
            }
        }
    }

    WebSocketState state() const override { return core_->state(); }

    Result<void> send_text(std::string_view text) override {
        if (auto r = core_->can_send(text.size()); !r.ok()) return r;
        if (!is_valid_utf8(text)) return make_error("the text is not valid UTF-8", "Send other data with send_binary.");
        @autoreleasepool {
            NSString* string = [[NSString alloc] initWithBytes:text.data() length:text.size() encoding:NSUTF8StringEncoding];
            if (!string) return make_error("the text is not valid UTF-8", "Send other data with send_binary.");
            send(text.size(), [[NSURLSessionWebSocketMessage alloc] initWithString:string]);
        }
        return {};
    }

    Result<void> send_binary(const void* data, std::size_t size) override {
        if (auto r = core_->can_send(size); !r.ok()) return r;
        @autoreleasepool {
            NSData* bytes = [NSData dataWithBytes:data length:size];
            send(size, [[NSURLSessionWebSocketMessage alloc] initWithData:bytes]);
        }
        return {};
    }

    Result<void> close(int code, std::string_view reason) override {
        if (auto r = ws::check_close_request(code, reason); !r.ok()) return r;
        bool connecting = false;
        if (!core_->begin_close(connecting)) return {};
        @autoreleasepool {
            if (connecting) {
                // The task's completion reports Error and Close 1006; the state is Closing until then.
                [task_ cancel];
                return {};
            }
            NSData* why = reason.empty() ? nil : [NSData dataWithBytes:reason.data() length:reason.size()];
            // NSURLSession cannot send a close frame without a code (code 0 is a plain cancel that drops the connection
            // with no frame at all): "no code" is sent as 1000.
            const int sent = code == 0 ? ws::close_code::kNormal : code;
            [task_ cancelWithCloseCode:static_cast<NSURLSessionWebSocketCloseCode>(sent) reason:why];
            // Safety net: the system reports the close by itself; if it ever does not, the wait of the contract ends it.
            std::shared_ptr<Core> core = core_;
            NSURLSessionWebSocketTask* task = task_;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, static_cast<int64_t>(kWebSocketCloseWaitSec * NSEC_PER_SEC)),
                           dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
                               if (core->on_close_timeout()) [task cancel];
                           });
        }
        return {};
    }

    std::size_t buffered_amount() const override { return core_->buffered(); }
    std::size_t poll(std::vector<WebSocketEvent>& out) override { return core_->queue()->drain(out); }

private:
    void send(std::size_t n, NSURLSessionWebSocketMessage* message) {
        std::shared_ptr<Core> core = core_;
        core->add_buffered(n);
        [task_ sendMessage:message
            completionHandler:^(NSError* error) {
                core->sub_buffered(n);
                if (error) core->note_error(error);
            }];
    }

    std::shared_ptr<Core> core_;
    NSURLSession* session_;
    NSURLSessionWebSocketTask* task_;
};

class AppleWebSocketClient final : public WebSocketClient {
public:
    std::string name() const override { return "nsurlsession"; }
    bool available() const override { return true; }

    Result<std::unique_ptr<WebSocket>> connect(WebSocketRequest request) override {
        auto parsed = ws::parse_url(request.url);
        if (!parsed.ok()) return parsed.error();
        // A header or subprotocol the handshake refuses is an error now, not a failed connection later.
        const std::uint8_t zeros[16] = {};
        if (auto head = ws::build_client_request(parsed.value(), ws::make_client_key(zeros), request.subprotocols,
                                                 request.headers);
            !head.ok())
            return head.error();

        @autoreleasepool {
            NSString* text = [NSString stringWithUTF8String:request.url.c_str()];
            NSURL* url = text ? [NSURL URLWithString:text] : nil;
            if (!url) return make_error("the address is not a valid URL: " + request.url, "Write it as wss://host/path.");
            NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:url];
            for (const auto& [name, value] : request.headers) {
                NSString* n = [NSString stringWithUTF8String:name.c_str()];
                NSString* v = [NSString stringWithUTF8String:value.c_str()];
                if (!n || !v)
                    return make_error("the header \"" + name + "\" is not valid UTF-8", "Use plain text for header values.");
                [req setValue:v forHTTPHeaderField:n];
            }
            if (![req valueForHTTPHeaderField:@"User-Agent"])
                [req setValue:@"FactorIA/" FA_ENGINE_VERSION forHTTPHeaderField:@"User-Agent"];
            if (!request.subprotocols.empty()) {
                std::string joined;
                for (const std::string& p : request.subprotocols) joined += (joined.empty() ? "" : ", ") + p;
                [req setValue:[NSString stringWithUTF8String:joined.c_str()] forHTTPHeaderField:@"Sec-WebSocket-Protocol"];
            }

            NSURLSessionConfiguration* config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
            // The connect timeout is ours (below): the system's per-request timeout would also end a connection that is
            // merely idle, which a WebSocket may be for as long as it likes.
            config.timeoutIntervalForRequest = 7 * 24 * 3600.0;
            config.waitsForConnectivity = NO;

            auto core = std::make_shared<Core>(request, parsed->host_header());
            FaWebSocketDelegate* delegate = [[FaWebSocketDelegate alloc] init];
            delegate->core = core;
            NSURLSession* session = [NSURLSession sessionWithConfiguration:config delegate:delegate delegateQueue:nil];
            NSURLSessionWebSocketTask* task = [session webSocketTaskWithRequest:req];
            task.maximumMessageSize = request.maxMessageBytes > static_cast<std::size_t>(NSIntegerMax)
                                          ? NSIntegerMax
                                          : static_cast<NSInteger>(request.maxMessageBytes);
            arm_receive(task, core);
            [task resume];

            const double timeout = std::clamp(request.connectTimeoutSec, 0.001, 24.0 * 3600.0);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, static_cast<int64_t>(timeout * NSEC_PER_SEC)),
                           dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
                               if (core->on_connect_timeout()) [task cancel];
                           });
            return std::unique_ptr<WebSocket>(std::make_unique<AppleWebSocket>(core, session, task));
        }
    }
};

}  // namespace

std::unique_ptr<WebSocketClient> make_system_websocket_client() { return std::make_unique<AppleWebSocketClient>(); }

}  // namespace fa
