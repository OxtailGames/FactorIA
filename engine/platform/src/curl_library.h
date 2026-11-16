// libcurl loaded at run time, shared by the HTTP client (http_curl.cpp) and the WebSocket client (websocket_curl.cpp): one
// dlopen per process. Nothing is linked, so the Linux player and the Steam Runtime keep working on a machine without libcurl,
// where both clients report themselves unavailable. The few pieces of curl.h used are declared here (the option numbers and
// the C ABI are stable since 7.x).
//
// Compiled on every POSIX platform; Linux uses it, macOS exercises it in the tests.
#pragma once

#if !defined(_WIN32) && !defined(__EMSCRIPTEN__)

#include <cstddef>
#include <string>

namespace fa::libcurl {

using CURL = void;
struct curl_slist;
using CURLcode = int;
using curl_off_t = long long;  // 64 bits on every platform this file builds for

// The CURLOPT_ numbers: type base (LONG 0, OBJECTPOINT 10000, FUNCTIONPOINT 20000, OFF_T 30000) plus the option's number.
constexpr int kOptWriteData = 10001, kOptUrl = 10002, kOptErrorBuffer = 10010, kOptPostFields = 10015,
              kOptUserAgent = 10018, kOptHttpHeader = 10023, kOptHeaderData = 10029, kOptCustomRequest = 10036,
              kOptXferInfoData = 10057, kOptWriteFunction = 20011, kOptHeaderFunction = 20079,
              kOptXferInfoFunction = 20219, kOptNoProgress = 43, kOptNoBody = 44, kOptPost = 47,
              kOptFollowLocation = 52, kOptPostFieldSize = 60, kOptHttpProxyTunnel = 61, kOptMaxRedirs = 68,
              kOptHttpVersion = 84, kOptNoSignal = 99, kOptConnectOnly = 141, kOptTimeoutMs = 155,
              kOptConnectTimeoutMs = 156, kOptAcceptEncoding = 10102, kOptProtocols = 181, kOptRedirProtocols = 182,
              kOptProtocolsStr = 10318, kOptRedirProtocolsStr = 10319;
constexpr int kInfoResponseCode = 0x200000 + 2;
constexpr int kInfoActiveSocket = 0x500000 + 44;  // curl_socket_t, 7.45.0
constexpr int kCurlOk = 0, kCurlUnsupportedProtocol = 1, kCurlCouldntResolveProxy = 5, kCurlCouldntResolveHost = 6,
              kCurlCouldntConnect = 7, kCurlTimedOut = 28, kCurlSslConnectError = 35, kCurlAbortedByCallback = 42,
              kCurlTooManyRedirects = 47, kCurlUnknownOption = 48, kCurlSslPeerCertificate = 51, kCurlGotNothing = 52,
              kCurlSslCertProblem = 58, kCurlSslCipher = 59, kCurlPeerFailedVerification = 60,
              kCurlSslCacertBadfile = 77, kCurlAgain = 81, kCurlSslIssuerError = 83;
constexpr long kProtoHttp = 1, kProtoHttps = 2;
constexpr long kHttpVersion1_1 = 2;  // CURL_HTTP_VERSION_1_1: also what TLS offers in ALPN
constexpr unsigned kVersionNum7_45 = 0x072D00;
constexpr int kFeatureSsl = 1 << 2;  // CURL_VERSION_SSL

// The first fields of curl_version_info_data, which every age of the struct has.
struct VersionInfo {
    int age;
    const char* version;
    unsigned int version_num;
    const char* host;
    int features;
};

struct Library {
    void* lib = nullptr;
    int (*global_init)(long) = nullptr;
    CURL* (*easy_init)() = nullptr;
    void (*easy_cleanup)(CURL*) = nullptr;
    CURLcode (*easy_setopt)(CURL*, int, ...) = nullptr;
    CURLcode (*easy_perform)(CURL*) = nullptr;
    CURLcode (*easy_getinfo)(CURL*, int, ...) = nullptr;
    const char* (*easy_strerror)(CURLcode) = nullptr;
    curl_slist* (*slist_append)(curl_slist*, const char*) = nullptr;
    void (*slist_free_all)(curl_slist*) = nullptr;
    // Not needed by the HTTP client, so a libcurl without them still serves http.fetch (null when missing).
    CURLcode (*easy_send)(CURL*, const void*, std::size_t, std::size_t*) = nullptr;  // 7.18.2
    CURLcode (*easy_recv)(CURL*, void*, std::size_t, std::size_t*) = nullptr;        // 7.18.2
    const VersionInfo* (*version_info)(int) = nullptr;
    std::string reason;  // why there is no library
    bool ok() const { return lib != nullptr; }
};

// Loaded on the first call (thread safe), never unloaded; curl_global_init has run when ok().
const Library& library();

// "8.5.0", or "" when the library does not say.
std::string version_text(const Library& c);

}  // namespace fa::libcurl

#endif
