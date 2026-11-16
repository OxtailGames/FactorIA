// libcurl's WebSocket support loaded with dlopen (Linux's client; macOS builds it too so the tests can exercise it there).
// M98.2c writes it, next to http_curl.cpp. Until then it is unavailable.
#if !defined(_WIN32) && !defined(__EMSCRIPTEN__)

#include "fa/platform/websocket.h"

namespace fa {

std::unique_ptr<WebSocketClient> make_curl_websocket_client() {
    return make_unavailable_websocket_client("curl", "WebSocket client for Linux lands in M98.2c");
}

}  // namespace fa

#endif
