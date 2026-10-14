#include "util.h"

#include <cctype>
#include <chrono>
#include <ctime>
#include <fstream>
#include <sstream>

#include "fa/core/fs.h"
#include "fa/tooling/bundle.h"

namespace fa::tooling_detail {

std::string today_utc() {
    std::time_t t = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());
    std::tm tm{};
#if defined(_WIN32)
    gmtime_s(&tm, &t);
#else
    gmtime_r(&t, &tm);
#endif
    char buf[16];
    std::strftime(buf, sizeof buf, "%Y-%m-%d", &tm);
    return buf;
}

std::optional<std::string> read_file(const std::filesystem::path& p) {
    std::ifstream in(p, std::ios::binary);
    if (!in) return std::nullopt;
    std::ostringstream ss;
    ss << in.rdbuf();
    return ss.str();
}

bool write_file(const std::filesystem::path& p, std::string_view data, std::string* err) {
    // `p` is a host path (relative to the current directory, not to the project root): make it absolute for the VFS.
    // fs::write_bytes replaces the file atomically and creates the folders.
    std::error_code ec;
    const std::filesystem::path abs = std::filesystem::absolute(p, ec);
    auto r = fs::write_bytes((ec ? p : abs).generic_string(), data.data(), data.size());
    if (!r.ok() && err) *err = r.error().to_string();
    return r.ok();
}

std::string slugify(std::string_view s, char sep) {
    std::string out;
    bool pendingSep = false;
    for (char c : s) {
        unsigned char u = static_cast<unsigned char>(c);
        if (std::isalnum(u)) {
            if (pendingSep && !out.empty()) out += sep;
            pendingSep = false;
            out += static_cast<char>(std::tolower(u));
        } else {
            pendingSep = true;
        }
    }
    return out;
}

Json load_schema(std::string_view bundledPath) {
    auto text = bundled_read(bundledPath);
    if (!text) return Json();
    auto j = parse_json(*text, bundledPath);
    return j.ok() ? j.value() : Json();
}

std::string arg_string(const Json& args, const char* key, bool required, std::string def) {
    auto it = args.find(key);
    if (it == args.end() || it->is_null()) {
        if (required) throw CommandError("invalid_argument", std::string("missing required argument '") + key + "'");
        return def;
    }
    if (!it->is_string())
        throw CommandError("invalid_argument", std::string("argument '") + key + "' must be a string");
    return it->get<std::string>();
}

bool arg_bool(const Json& args, const char* key, bool def) {
    auto it = args.find(key);
    return (it != args.end() && it->is_boolean()) ? it->get<bool>() : def;
}

long arg_int(const Json& args, const char* key, long def) {
    auto it = args.find(key);
    return (it != args.end() && it->is_number()) ? it->get<long>() : def;
}

}  // namespace fa::tooling_detail
