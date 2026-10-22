// Debug Adapter Protocol framing: `Content-Length: N\r\n\r\n` followed by N bytes of JSON, both ways.
#pragma once

#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"

namespace fa {

// Bytes of one message as they go on the wire.
std::string dap_encode(const Json& message);

// Incremental parser for the bytes a client sends. Feed whatever a read returned (half a header, several messages,
// one byte at a time): complete messages come out in order. A damaged frame produces an `error` entry (what is wrong
// and how the reader recovered) and the reader goes on with the next frame, so one bad message never ends a session.
class DapFrameReader {
public:
    struct Item {
        Json message;       // valid when `error` is empty
        std::string error;  // non-empty: a frame that could not be used
    };
    static constexpr std::size_t kMaxBody = 64u * 1024 * 1024;
    static constexpr std::size_t kMaxHeader = 8u * 1024;

    std::vector<Item> feed(std::string_view bytes);
    // Bytes received that do not make a whole frame yet.
    std::size_t pending() const { return buffer_.size(); }

private:
    std::string buffer_;
};

}  // namespace fa
