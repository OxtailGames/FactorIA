// Linux: libcurl, loaded with dlopen (http_curl.cpp). Nothing is linked: where libcurl is missing the client is unavailable.
#include "fa/platform/http.h"

namespace fa {

std::unique_ptr<HttpClient> make_system_http_client() { return make_curl_http_client(); }

}  // namespace fa
