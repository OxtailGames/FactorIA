// libcurl loaded at run time (curl_library.h): one dlopen for the HTTP and the WebSocket clients.
#if !defined(_WIN32) && !defined(__EMSCRIPTEN__)

#include "curl_library.h"

#include <dlfcn.h>

namespace fa::libcurl {

const Library& library() {
    static const Library c = [] {
        Library k;
        const char* names[] = {
#if defined(__APPLE__)
            "libcurl.4.dylib",
            "libcurl.dylib",
#else
            "libcurl.so.4",
            "libcurl-gnutls.so.4",
            "libcurl-nss.so.4",
            "libcurl.so",
#endif
        };
        for (const char* name : names)
            if ((k.lib = dlopen(name, RTLD_NOW | RTLD_LOCAL))) break;
        if (!k.lib) {
            k.reason = "libcurl is not installed on this computer";
            return k;
        }
        auto sym = [&](const char* name) { return dlsym(k.lib, name); };
        k.global_init = reinterpret_cast<int (*)(long)>(sym("curl_global_init"));
        k.easy_init = reinterpret_cast<CURL* (*)()>(sym("curl_easy_init"));
        k.easy_cleanup = reinterpret_cast<void (*)(CURL*)>(sym("curl_easy_cleanup"));
        k.easy_setopt = reinterpret_cast<CURLcode (*)(CURL*, int, ...)>(sym("curl_easy_setopt"));
        k.easy_perform = reinterpret_cast<CURLcode (*)(CURL*)>(sym("curl_easy_perform"));
        k.easy_getinfo = reinterpret_cast<CURLcode (*)(CURL*, int, ...)>(sym("curl_easy_getinfo"));
        k.easy_strerror = reinterpret_cast<const char* (*)(CURLcode)>(sym("curl_easy_strerror"));
        k.slist_append = reinterpret_cast<curl_slist* (*)(curl_slist*, const char*)>(sym("curl_slist_append"));
        k.slist_free_all = reinterpret_cast<void (*)(curl_slist*)>(sym("curl_slist_free_all"));
        k.easy_send =
            reinterpret_cast<CURLcode (*)(CURL*, const void*, std::size_t, std::size_t*)>(sym("curl_easy_send"));
        k.easy_recv = reinterpret_cast<CURLcode (*)(CURL*, void*, std::size_t, std::size_t*)>(sym("curl_easy_recv"));
        k.version_info = reinterpret_cast<const VersionInfo* (*)(int)>(sym("curl_version_info"));
        if (!k.global_init || !k.easy_init || !k.easy_cleanup || !k.easy_setopt || !k.easy_perform || !k.easy_getinfo ||
            !k.easy_strerror || !k.slist_append || !k.slist_free_all) {
            dlclose(k.lib);
            k = Library{};
            k.reason = "the libcurl on this computer lacks functions the engine needs";
            return k;
        }
        k.global_init(3);  // CURL_GLOBAL_DEFAULT: once, before any thread uses curl
        return k;
    }();
    return c;
}

std::string version_text(const Library& c) {
    if (!c.version_info) return {};
    // The argument is the age the caller was built for; the fields read here exist in every age, and curl ignores it.
    const VersionInfo* v = c.version_info(0);
    return v && v->version ? std::string(v->version) : std::string();
}

}  // namespace fa::libcurl

#endif
