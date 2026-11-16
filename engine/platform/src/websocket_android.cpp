// Android (a JNI socket stream and fa/platform/websocket_codec.h): M98.2c replaces this stub with the real client (fa/platform/websocket.h says what it has to do). Until then the
// client is unavailable and says so, which is what websocket.connect reports to the game.
#include "fa/platform/websocket.h"

namespace fa {

std::unique_ptr<WebSocketClient> make_system_websocket_client() {
    return make_unavailable_websocket_client("socket", "WebSocket client for Android lands in M98.2c");
}

}  // namespace fa
