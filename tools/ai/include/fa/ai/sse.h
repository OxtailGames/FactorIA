// Server-Sent Events line splitter.
#pragma once

#include <functional>
#include <string>
#include <string_view>

namespace fa::ai {

class SseSplitter {
public:
    // onEvent(eventName, data) is called for every complete event.
    explicit SseSplitter(std::function<void(const std::string&, const std::string&)> onEvent)
        : onEvent_(std::move(onEvent)) {}

    void feed(std::string_view chunk) {
        buf_.append(chunk);
        std::size_t start = 0;
        for (;;) {
            auto nl = buf_.find('\n', start);
            if (nl == std::string::npos) break;
            std::string_view line(buf_.data() + start, nl - start);
            if (!line.empty() && line.back() == '\r') line.remove_suffix(1);
            handle_line(line);
            start = nl + 1;
        }
        buf_.erase(0, start);
    }
    // Flush a trailing event with no final blank line.
    void finish() {
        if (!buf_.empty()) {
            std::string_view line(buf_);
            if (!line.empty() && line.back() == '\r') line.remove_suffix(1);
            handle_line(line);
            buf_.clear();
        }
        dispatch();
    }

private:
    void handle_line(std::string_view line) {
        if (line.empty()) { dispatch(); return; }
        if (line[0] == ':') return;  // comment / keep-alive
        auto colon = line.find(':');
        std::string_view field = line.substr(0, colon);
        std::string_view value = colon == std::string_view::npos ? std::string_view{} : line.substr(colon + 1);
        if (!value.empty() && value[0] == ' ') value.remove_prefix(1);
        if (field == "event") event_ = std::string(value);
        else if (field == "data") {
            if (hasData_) data_.push_back('\n');
            data_.append(value);
            hasData_ = true;
        }
    }
    void dispatch() {
        if (hasData_ || !event_.empty()) onEvent_(event_, data_);
        event_.clear();
        data_.clear();
        hasData_ = false;
    }
    std::function<void(const std::string&, const std::string&)> onEvent_;
    std::string buf_, event_, data_;
    bool hasData_ = false;
};

}  // namespace fa::ai
