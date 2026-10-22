#include "fa/dap/framing.h"

#include <cctype>
#include <charconv>

namespace fa {

std::string dap_encode(const Json& message) {
    const std::string body = message.dump(-1, ' ', false, Json::error_handler_t::replace);
    return "Content-Length: " + std::to_string(body.size()) + "\r\n\r\n" + body;
}

namespace {

std::string lower(std::string s) {
    for (char& c : s) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return s;
}

// The Content-Length of a header block, or -1 with `why` set.
long long content_length(std::string_view header, std::string& why) {
    long long length = -1;
    std::size_t pos = 0;
    while (pos < header.size()) {
        std::size_t eol = header.find("\r\n", pos);
        if (eol == std::string_view::npos) eol = header.size();
        std::string_view line = header.substr(pos, eol - pos);
        pos = eol + 2;
        if (line.empty()) continue;
        std::size_t colon = line.find(':');
        if (colon == std::string_view::npos) {
            why = "header line '" + std::string(line) + "' has no ':'. Every header is 'Name: value'";
            return -1;
        }
        if (lower(std::string(line.substr(0, colon))) != "content-length") continue;  // Content-Type etc.: ignored
        std::string_view value = line.substr(colon + 1);
        while (!value.empty() && (value.front() == ' ' || value.front() == '\t')) value.remove_prefix(1);
        while (!value.empty() && (value.back() == ' ' || value.back() == '\t')) value.remove_suffix(1);
        long long n = 0;
        auto r = std::from_chars(value.data(), value.data() + value.size(), n);
        if (value.empty() || r.ec != std::errc() || r.ptr != value.data() + value.size() || n < 0) {
            why = "Content-Length '" + std::string(value) + "' is not a whole number of bytes";
            return -1;
        }
        length = n;
    }
    if (length < 0 && why.empty()) why = "the header has no Content-Length. A message is 'Content-Length: N\\r\\n\\r\\n' + N bytes of JSON";
    return length;
}

}  // namespace

std::vector<DapFrameReader::Item> DapFrameReader::feed(std::string_view bytes) {
    std::vector<Item> out;
    buffer_.append(bytes);
    for (;;) {
        std::size_t end = buffer_.find("\r\n\r\n");
        if (end == std::string::npos) {
            if (buffer_.size() > kMaxHeader) {  // no end of header in sight: this is not a DAP stream
                out.push_back({Json(), "no 'Content-Length' header in the first " + std::to_string(buffer_.size()) +
                                           " bytes; discarding them. Frames are 'Content-Length: N\\r\\n\\r\\n' + JSON"});
                buffer_.clear();
            }
            break;
        }
        std::string why;
        const long long length = content_length(std::string_view(buffer_).substr(0, end), why);
        const std::size_t bodyStart = end + 4;
        if (length < 0) {
            out.push_back({Json(), "bad message header: " + why + "; skipped the header"});
            buffer_.erase(0, bodyStart);
            continue;
        }
        if (static_cast<std::size_t>(length) > kMaxBody) {
            out.push_back({Json(), "Content-Length " + std::to_string(length) + " is larger than the " +
                                       std::to_string(kMaxBody) + " bytes a message may have; skipped the header"});
            buffer_.erase(0, bodyStart);
            continue;
        }
        if (buffer_.size() < bodyStart + static_cast<std::size_t>(length)) break;  // the body is still arriving
        const std::string body = buffer_.substr(bodyStart, static_cast<std::size_t>(length));
        buffer_.erase(0, bodyStart + static_cast<std::size_t>(length));
        Json parsed = Json::parse(body, nullptr, false);
        if (parsed.is_discarded())
            out.push_back({Json(), "the message body is not valid JSON: '" + body.substr(0, 80) + (body.size() > 80 ? "..." : "") + "'"});
        else
            out.push_back({std::move(parsed), {}});
    }
    return out;
}

}  // namespace fa
