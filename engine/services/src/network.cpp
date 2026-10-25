// The "network" section of factoria.json and the URL policy of http.fetch (fa/services/network.h).
#include "fa/services/network.h"

#include <algorithm>
#include <cctype>
#include <set>

#include "fa/core/strings.h"

namespace fa {

namespace {

constexpr std::size_t kMaxHosts = 64;
constexpr std::size_t kMaxUrlBytes = 2048;

std::string in_quotes(const std::string& s) { return Json(s).dump(); }

std::string lower(std::string s) {
    for (char& c : s) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return s;
}

bool ends_with(const std::string& s, const std::string& suffix) {
    return s.size() >= suffix.size() && s.compare(s.size() - suffix.size(), suffix.size(), suffix) == 0;
}

bool is_ipv6_literal(const std::string& s) {
    return s.find(':') != std::string::npos &&
           std::all_of(s.begin(), s.end(), [](unsigned char c) { return std::isxdigit(c) || c == ':' || c == '.'; });
}

// A DNS name or an IPv4 address: labels of letters, digits and '-', not starting or ending with '-'.
bool valid_domain(const std::string& s) {
    if (s.empty() || s.size() > 253) return false;
    std::size_t start = 0;
    while (start <= s.size()) {
        std::size_t end = s.find('.', start);
        if (end == std::string::npos) end = s.size();
        const std::size_t length = end - start;
        if (length == 0 || length > 63 || s[start] == '-' || s[end - 1] == '-') return false;
        for (std::size_t i = start; i < end; ++i)
            if (!std::isalnum(static_cast<unsigned char>(s[i])) && s[i] != '-') return false;
        start = end + 1;
    }
    return true;
}

struct Parser {
    NetworkParse out;
    void issue(std::string pointer, std::string message, std::string hint, bool warning = false) {
        out.issues.push_back({std::move(pointer), std::move(message), std::move(hint), warning});
    }
};

const char* kHostsExample = "\"network\": {\"hosts\": [\"api.example.com\"]}";

// Why the entry is not a host, or "".
std::string host_problem(const std::string& entry, std::string& hint) {
    if (entry.empty()) {
        hint = std::string("Write the host name of the server, e.g. ") + kHostsExample + ".";
        return "an empty host";
    }
    if (entry.find("://") != std::string::npos || entry.find('/') != std::string::npos || entry.find('?') != std::string::npos) {
        hint = "Write only the host name, without https:// and without a path: \"api.example.com\". http.fetch URLs may then use any path on it.";
        return in_quotes(entry) + " is a URL, not a host";
    }
    if (entry.find_first_of(" \t\r\n") != std::string::npos) {
        hint = "A host name has no spaces: \"api.example.com\".";
        return in_quotes(entry) + " has a space";
    }
    if (entry.find('@') != std::string::npos) {
        hint = "Write only the host name; user names and passwords never go in a URL.";
        return in_quotes(entry) + " has a user name or password";
    }
    if (is_ipv6_literal(entry)) return {};
    if (entry.find(':') != std::string::npos) {
        hint = "Hosts are declared without a port: \"api.example.com\" covers every port of that host.";
        return in_quotes(entry) + " has a port";
    }
    if (entry.rfind("*.", 0) == 0) {
        const std::string rest = entry.substr(2);
        if (!valid_domain(rest) || rest.find('.') == std::string::npos) {
            hint = "A wildcard covers the subdomains of a domain you own: \"*.example.com\". \"*.com\" and the like are too broad.";
            return in_quotes(entry) + " is not a valid wildcard host";
        }
        return {};
    }
    if (entry.find('*') != std::string::npos) {
        hint = "A \"*\" is only allowed at the start, as \"*.example.com\".";
        return in_quotes(entry) + " has a \"*\" in the wrong place";
    }
    if (!valid_domain(entry)) {
        hint = "A host name has letters, digits, \"-\" and dots, e.g. \"api.example.com\".";
        return in_quotes(entry) + " is not a valid host name";
    }
    return {};
}

}  // namespace

bool NetworkPolicy::is_loopback(const std::string& host) {
    if (host == "localhost" || host == "::1") return true;
    return host.rfind("127.", 0) == 0 && std::all_of(host.begin(), host.end(), [](unsigned char c) { return std::isdigit(c) || c == '.'; });
}

bool NetworkPolicy::allows(const std::string& host) const {
    for (const std::string& entry : hosts) {
        if (entry == host) return true;
        if (entry.rfind("*.", 0) == 0 && host.size() > entry.size() - 1 && ends_with(host, entry.substr(1))) return true;
    }
    return false;
}

Error NetworkIssue::to_error() const { return make_error("factoria.json#" + pointer + ": " + message, hint); }

bool NetworkParse::ok() const {
    return std::none_of(issues.begin(), issues.end(), [](const NetworkIssue& i) { return !i.warning; });
}

NetworkParse parse_network(const Json& section) {
    Parser p;
    if (section.is_null()) return p.out;
    if (!section.is_object()) {
        p.issue("/network", "expected an object like {\"hosts\": [\"api.example.com\"]}, got " + describe_json_value(section),
                "List the hosts http.fetch may call (docs/NETWORKING.md).");
        return std::move(p.out);
    }
    const std::vector<std::string> known = {"hosts", "purpose"};
    for (auto it = section.begin(); it != section.end(); ++it) {
        if (std::find(known.begin(), known.end(), it.key()) != known.end()) continue;
        p.issue("/network/" + it.key(), "unknown key " + in_quotes(it.key()) + "; the keys here are \"hosts\" and \"purpose\"",
                did_you_mean(it.key(), known), true);
    }
    if (auto it = section.find("purpose"); it != section.end()) {
        if (!it->is_string()) p.issue("/network/purpose", "must be a string, got " + describe_json_value(*it),
                                      "One sentence for the privacy notice: \"Daily challenge and online leaderboard.\"");
        else p.out.policy.purpose = it->get<std::string>();
    }
    auto hosts = section.find("hosts");
    if (hosts == section.end()) {
        p.issue("/network/hosts", "missing: the section must list the hosts http.fetch may call",
                std::string("Add e.g. ") + kHostsExample + ", or remove the \"network\" section if the game does not use the network.");
        return std::move(p.out);
    }
    if (!hosts->is_array()) {
        p.issue("/network/hosts", "must be a list of host names, got " + describe_json_value(*hosts), std::string("Example: ") + kHostsExample + ".");
        return std::move(p.out);
    }
    if (hosts->empty())
        p.issue("/network/hosts", "is empty", "List at least one host, or remove the \"network\" section if the game does not use the network.");
    if (hosts->size() > kMaxHosts)
        p.issue("/network/hosts", "has " + std::to_string(hosts->size()) + " entries; the most is " + std::to_string(kMaxHosts),
                "A game talks to a few servers. Use \"*.example.com\" for many subdomains of one domain.");
    std::set<std::string> seen;
    for (std::size_t i = 0; i < hosts->size() && i < kMaxHosts; ++i) {
        const std::string ptr = "/network/hosts/" + std::to_string(i);
        const Json& e = (*hosts)[i];
        if (!e.is_string()) {
            p.issue(ptr, "must be a host name string, got " + describe_json_value(e), "Example: \"api.example.com\".");
            continue;
        }
        const std::string entry = lower(e.get<std::string>());
        std::string hint;
        if (const std::string problem = host_problem(entry, hint); !problem.empty()) {
            p.issue(ptr, problem, hint);
            continue;
        }
        if (!seen.insert(entry).second) {
            p.issue(ptr, in_quotes(entry) + " is listed twice", "Remove the duplicate.", true);
            continue;
        }
        p.out.policy.hosts.push_back(entry);
    }
    if (!p.out.policy.hosts.empty() && p.out.policy.purpose.empty() && !section.contains("purpose"))
        p.issue("/network/purpose", "missing: say what the game sends over the network",
                "Add one sentence for the privacy notice, e.g. \"purpose\": \"Online leaderboard and the daily challenge.\" (docs/NETWORKING.md).", true);
    return std::move(p.out);
}

Result<NetworkPolicy> load_network(const Json& section) {
    NetworkParse parsed = parse_network(section);
    for (const NetworkIssue& i : parsed.issues)
        if (!i.warning) return i.to_error();
    return std::move(parsed.policy);
}

// ---------------------------------------------------------------------------------------------------------- URLs ---
Result<HttpUrl> parse_http_url(const std::string& url) {
    const std::string shown = url.size() > 80 ? url.substr(0, 77) + "..." : url;
    if (url.empty()) return make_error("the URL is empty", "Pass an absolute address: \"https://api.example.com/path\".");
    if (url.size() > kMaxUrlBytes)
        return make_error("the URL is " + std::to_string(url.size()) + " bytes long; the most is " + std::to_string(kMaxUrlBytes),
                          "Send long data in the body of a POST request, not in the address.");
    for (unsigned char c : url)
        if (c <= 0x20 || c == 0x7f)
            return make_error("the URL " + in_quotes(shown) + " has a space or control character",
                              "Write spaces as %20 (or encode the pieces with encodeURIComponent).");
    const std::size_t schemeEnd = url.find("://");
    if (schemeEnd == std::string::npos)
        return make_error("the URL " + in_quotes(shown) + " is not absolute", "Start it with https://, e.g. \"https://api.example.com/path\".");
    HttpUrl out;
    out.scheme = lower(url.substr(0, schemeEnd));
    if (out.scheme != "https" && out.scheme != "http")
        return make_error("the URL " + in_quotes(shown) + " uses " + in_quotes(out.scheme) + ": http.fetch only speaks https",
                          "Use an https:// address.");
    const std::size_t authorityStart = schemeEnd + 3;
    const std::size_t authorityEnd = url.find_first_of("/?#", authorityStart);
    std::string authority = url.substr(authorityStart, authorityEnd == std::string::npos ? std::string::npos : authorityEnd - authorityStart);
    std::string rest = authorityEnd == std::string::npos ? std::string() : url.substr(authorityEnd);
    if (const std::size_t hash = rest.find('#'); hash != std::string::npos) rest.erase(hash);  // a fragment is never sent
    if (authority.find('@') != std::string::npos)
        return make_error("the URL " + in_quotes(shown) + " has a user name or password",
                          "Send credentials in a header (headers: { Authorization: \"Bearer ...\" }), never in the address.");
    std::string host = authority, port;
    if (!authority.empty() && authority[0] == '[') {
        const std::size_t close = authority.find(']');
        if (close == std::string::npos)
            return make_error("the URL " + in_quotes(shown) + " has an unclosed [ in the host", "Write an IPv6 address as http://[::1]:8080/.");
        host = authority.substr(1, close - 1);
        const std::string after = authority.substr(close + 1);
        if (!after.empty()) {
            if (after[0] != ':') return make_error("the URL " + in_quotes(shown) + " has text after the IPv6 address", "Write [::1]:8080.");
            port = after.substr(1);
        }
    } else if (const std::size_t colon = authority.rfind(':'); colon != std::string::npos) {
        host = authority.substr(0, colon);
        port = authority.substr(colon + 1);
    }
    host = lower(host);
    if (host.empty()) return make_error("the URL " + in_quotes(shown) + " has no host", "Write it as https://host/path.");
    if (!(authority[0] == '[' ? is_ipv6_literal(host) : valid_domain(host)))
        return make_error("the URL " + in_quotes(shown) + " has an invalid host " + in_quotes(host),
                          "A host name has letters, digits, \"-\" and dots.");
    if (!port.empty()) {
        const bool digits = port.size() <= 5 && std::all_of(port.begin(), port.end(), [](unsigned char c) { return std::isdigit(c); });
        const int n = digits ? std::stoi(port) : 0;
        if (n < 1 || n > 65535)
            return make_error("the URL " + in_quotes(shown) + " has the port " + in_quotes(port) + ", which is not 1 to 65535",
                              "Write the port as a number after the host: https://host:8443/.");
        out.port = n;
    }
    out.host = host;
    out.url = out.scheme + "://" + (host.find(':') != std::string::npos ? "[" + host + "]" : host) + (port.empty() ? "" : ":" + std::to_string(out.port)) +
              (rest.empty() ? std::string("/") : (rest[0] == '/' ? rest : "/" + rest));
    return out;
}

Result<HttpUrl> check_http_url(const std::string& url, const NetworkPolicy& policy) {
    Result<HttpUrl> parsed = parse_http_url(url);
    if (!parsed.ok()) return parsed;
    const HttpUrl& u = parsed.value();
    if (u.scheme == "http" && !NetworkPolicy::is_loopback(u.host))
        return make_error("http.fetch refuses the plain http:// address " + in_quotes(url),
                          "Use https://" + u.host + "/... : only https is allowed (http:// works for localhost, 127.0.0.1 and ::1 while "
                          "developing). docs/NETWORKING.md, \"Which URLs\".");
    if (!policy.declared())
        return make_error("this game declares no network hosts, so http.fetch cannot call " + in_quotes(u.host),
                          "Declare the host in factoria.json: \"network\": {\"hosts\": [" + in_quotes(u.host) +
                              "]}. The same list gives the Android export its INTERNET permission (docs/NETWORKING.md).");
    if (!policy.allows(u.host)) {
        std::string hint = did_you_mean(u.host, policy.hosts);
        if (!hint.empty()) hint += " ";
        hint += "Declared: " + [&] {
            std::string list;
            for (const std::string& h : policy.hosts) list += (list.empty() ? "" : ", ") + in_quotes(h);
            return list;
        }() + ". Add the host to factoria.json \"network\".\"hosts\" if the game should call it.";
        return make_error("the host " + in_quotes(u.host) + " is not declared in factoria.json \"network\".\"hosts\"", hint);
    }
    return parsed;
}

}  // namespace fa
