// Linux: libcurl's WebSocket support, loaded with dlopen (websocket_curl.cpp, written by M98.2c; until then unavailable and
// saying so, which is what websocket.connect reports to the game).
#include "fa/platform/websocket.h"

namespace fa {

std::unique_ptr<WebSocketClient> make_system_websocket_client() { return make_curl_websocket_client(); }

}  // namespace fa
