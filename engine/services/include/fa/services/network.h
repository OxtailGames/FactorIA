// What a game declares about the network (docs/NETWORKING.md): the "network" section of factoria.json lists the hosts
// `http.fetch` may call. The same list decides the INTERNET permission of the Android export and is what the privacy docs
// ask a game to disclose; PlatformServices refuses a request to any other host before it leaves the game, so a typo or a
// forgotten declaration is an error in the very test that makes the call.
//
//   "network": { "hosts": ["api.example.com", "*.cdn.example.com"], "purpose": "Daily challenge and online leaderboard." }
//
// Policy in one place (also in docs/NETWORKING.md):
//   - only https:// URLs; plain http:// is allowed to loopback hosts (localhost, 127.x.x.x, ::1) for a server on the developer's
//     own machine, and only when the section lists that host;
//   - the host of the URL must be listed: exactly, or covered by a "*.domain" entry (subdomains, not the domain itself);
//   - no user name or password in the URL.
#pragma once

#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

inline constexpr const char* kNetworkKey = "network";  // the section of factoria.json
inline constexpr const char* kAnalyticsKey = "analytics";        // factoria.json: where analytics.event sends (docs/ANALYTICS.md)
inline constexpr const char* kRemoteConfigKey = "remoteConfig";  // factoria.json: where remoteConfig.get reads (docs/ANALYTICS.md)

struct NetworkPolicy {
    std::vector<std::string> hosts;  // lower case, as written: "api.example.com", "*.example.com", "localhost", "127.0.0.1", "::1"
    std::string purpose;             // one sentence for the privacy notice; optional
    bool declared() const { return !hosts.empty(); }
    // True when `host` (lower case, no port, IPv6 without brackets) is covered by an entry.
    bool allows(const std::string& host) const;
    // True when a host is loopback only: such a game needs no privacy notice of its own, but still the permission.
    static bool is_loopback(const std::string& host);
};

struct NetworkIssue {
    std::string pointer, message, hint;  // pointer: JSON pointer into factoria.json ("/network/hosts/1")
    bool warning = false;
    Error to_error() const;
};

struct NetworkParse {
    NetworkPolicy policy;
    std::vector<NetworkIssue> issues;
    bool ok() const;  // no issue that is not a warning
};

// Parses the value of factoria.json "network" (null / absent = nothing declared). Reports every problem, each with the
// field, what is wrong and how to fix it. `factoria validate` uses this; the engine uses load_network.
NetworkParse parse_network(const Json& section);
Result<NetworkPolicy> load_network(const Json& section);

// The "analytics" section: analytics.event(name, props) batches events and POSTs them to `endpoint`, after the player consented.
struct AnalyticsSettings {
    bool configured = false;
    std::string endpoint;          // https URL; its host must be in "network".hosts
    int batch = 20;                // events that make a batch go out at once (1 to 100)
    double flushSeconds = 30;      // the longest an event waits in the queue (1 to 3600)
    double timeoutSeconds = 10;    // of one request (above 0, at most 120)
    bool consentFromAds = false;   // until the player answers, the ads consent decides (docs/ANALYTICS.md)
};
struct AnalyticsParse {
    AnalyticsSettings settings;
    std::vector<NetworkIssue> issues;
    bool ok() const;
};
// `network` is the policy of the same factoria.json: the endpoint's host must be declared there.
AnalyticsParse parse_analytics(const Json& section, const NetworkPolicy& network);

// The "remoteConfig" section: remoteConfig.get(key, default) reads the JSON object served at `url`.
struct RemoteConfigSettings {
    bool configured = false;
    std::string url;               // https URL; its host must be in "network".hosts
    double timeoutSeconds = 5;     // above 0, at most 30
};
struct RemoteConfigParse {
    RemoteConfigSettings settings;
    std::vector<NetworkIssue> issues;
    bool ok() const;
};
RemoteConfigParse parse_remote_config(const Json& section, const NetworkPolicy& network);

// An absolute http(s) URL taken apart. `url` is the text to send: the host in lower case, the fragment removed.
struct HttpUrl {
    std::string scheme;  // "http" | "https"
    std::string host;    // lower case; IPv6 without the brackets
    int port = 0;        // 0 = the scheme's default
    std::string url;
};

// Checks the URL's shape: scheme, host, port, no user name or password, no spaces or control characters, at most 2048 bytes.
// It does not apply the policy (see check_http_url).
Result<HttpUrl> parse_http_url(const std::string& url);

// The policy applied to one request: https only (http for loopback), host declared. The error names what is wrong and what to
// write in factoria.json.
Result<HttpUrl> check_http_url(const std::string& url, const NetworkPolicy& policy);

}  // namespace fa
