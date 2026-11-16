// Linux: libcurl loaded with dlopen (websocket_curl.cpp); where libcurl is missing the client is unavailable and says why,
// which is what websocket.connect reports to the game.
#include "fa/platform/websocket.h"

namespace fa {

std::unique_ptr<WebSocketClient> make_system_websocket_client() { return make_curl_websocket_client(); }

}  // namespace fa
