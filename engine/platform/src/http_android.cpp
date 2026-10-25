// Android: java.net.HttpURLConnection through JNI (framework classes only, no Java code of ours), on one short-lived
// native thread per request. The system's certificate store and proxy settings apply. The game's manifest needs the INTERNET
// permission: the export adds it when factoria.json declares network hosts (docs/NETWORKING.md); without it the connection
// fails with a SecurityException, reported here like any other failure.
//
// Differences from the other platforms, all from HttpURLConnection itself: PATCH is sent as POST with
// X-HTTP-Method-Override: PATCH (the class refuses the verb); redirects are followed by the class (up to 20, and never from
// https:// to http://), so the check here is that an https:// request ended on https://.
//
// UNTESTED on a device: only compiled by CI (Android job).
#include <algorithm>
#include <cctype>
#include <string>
#include <system_error>
#include <thread>

#include "android_jni.h"
#include "fa/platform/http.h"

namespace fa {

namespace {

HttpResponse failure(std::string error, std::string hint, bool timedOut = false) {
    HttpResponse r;
    r.error = std::move(error);
    r.hint = std::move(hint);
    r.timedOut = timedOut;
    return r;
}

std::string lower(std::string s) {
    for (char& c : s) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return s;
}

// A Java string as UTF-8 ("" for null).
std::string to_std(JNIEnv* env, jstring s) {
    if (!s) return {};
    const char* chars = env->GetStringUTFChars(s, nullptr);
    if (!chars) return {};
    std::string out(chars);
    env->ReleaseStringUTFChars(s, chars);
    return out;
}

jstring to_java(JNIEnv* env, const std::string& s) { return env->NewStringUTF(s.c_str()); }

// The pending exception's class name and message, cleared.
struct JavaError {
    std::string cls, message;
};
JavaError take_exception(JNIEnv* env) {
    JavaError e;
    jthrowable ex = env->ExceptionOccurred();
    env->ExceptionClear();
    if (!ex) return e;
    jclass throwable = env->FindClass("java/lang/Throwable");
    jclass classClass = env->FindClass("java/lang/Class");
    if (throwable && classClass) {
        jmethodID getClass = env->GetMethodID(throwable, "getClass", "()Ljava/lang/Class;");
        jmethodID getMessage = env->GetMethodID(throwable, "getMessage", "()Ljava/lang/String;");
        jmethodID getName = env->GetMethodID(classClass, "getName", "()Ljava/lang/String;");
        if (getClass && getName) {
            if (jobject c = env->CallObjectMethod(ex, getClass)) {
                e.cls = to_std(env, static_cast<jstring>(env->CallObjectMethod(c, getName)));
                env->DeleteLocalRef(c);
            }
        }
        if (getMessage) e.message = to_std(env, static_cast<jstring>(env->CallObjectMethod(ex, getMessage)));
        env->ExceptionClear();
    }
    env->DeleteLocalRef(ex);
    return e;
}

std::string host_of(const std::string& url) {
    std::size_t start = url.find("://");
    start = start == std::string::npos ? 0 : start + 3;
    const std::size_t end = url.find_first_of("/?#:", start);
    return url.substr(start, end == std::string::npos ? std::string::npos : end - start);
}

HttpResponse java_error(const JavaError& e, const std::string& host, double timeoutSec) {
    const auto is = [&](const char* name) { return e.cls == name; };
    if (is("java.net.SocketTimeoutException"))
        return failure("the request to " + host + " timed out after " + std::to_string(int(timeoutSec)) + " s",
                       "Check the connection, or raise the timeout option of http.fetch.", true);
    if (is("java.net.UnknownHostException"))
        return failure("could not find the server " + host, "Check the address, and that the player is online.");
    if (is("java.net.ConnectException") || is("java.net.NoRouteToHostException"))
        return failure("could not connect to " + host, "The server may be down, or the player offline.");
    if (e.cls.rfind("javax.net.ssl.", 0) == 0 || e.cls.find("Certificate") != std::string::npos)
        return failure("the secure connection to " + host + " failed: " + e.message,
                       "The server's certificate is not trusted by this device (an expired certificate, a wrong clock, or a proxy that "
                       "rewrites traffic).");
    if (is("java.lang.SecurityException"))
        return failure("the game is not allowed to use the network: " + e.message,
                       "The app needs the INTERNET permission: declare the hosts in factoria.json \"network\" and export again.");
    return failure("the request to " + host + " failed: " + (e.message.empty() ? e.cls : e.message),
                   "Check the connection, and that the server is up.");
}

HttpResponse perform(const HttpRequest& req) {
    JNIEnv* env = android_thread_env();
    if (!env) return failure("the Java runtime is not available", "Restart the game.");
    const std::string host = host_of(req.url);
    const int timeoutMs = static_cast<int>(std::max(1.0, req.timeoutSec * 1000.0));

    jclass urlClass = env->FindClass("java/net/URL");
    jclass connClass = env->FindClass("java/net/HttpURLConnection");
    jclass streamClass = env->FindClass("java/io/InputStream");
    jclass outClass = env->FindClass("java/io/OutputStream");
    if (!urlClass || !connClass || !streamClass || !outClass) {
        env->ExceptionClear();
        return failure("the Java networking classes are missing", "This Android version is not supported.");
    }
    const jmethodID newUrl = env->GetMethodID(urlClass, "<init>", "(Ljava/lang/String;)V");
    const jmethodID openConnection = env->GetMethodID(urlClass, "openConnection", "()Ljava/net/URLConnection;");
    const jmethodID getUrl = env->GetMethodID(connClass, "getURL", "()Ljava/net/URL;");
    const jmethodID getProtocol = env->GetMethodID(urlClass, "getProtocol", "()Ljava/lang/String;");
    const jmethodID setMethod = env->GetMethodID(connClass, "setRequestMethod", "(Ljava/lang/String;)V");
    const jmethodID setConnectTimeout = env->GetMethodID(connClass, "setConnectTimeout", "(I)V");
    const jmethodID setReadTimeout = env->GetMethodID(connClass, "setReadTimeout", "(I)V");
    const jmethodID setProperty = env->GetMethodID(connClass, "setRequestProperty", "(Ljava/lang/String;Ljava/lang/String;)V");
    const jmethodID setDoOutput = env->GetMethodID(connClass, "setDoOutput", "(Z)V");
    const jmethodID setFollow = env->GetMethodID(connClass, "setInstanceFollowRedirects", "(Z)V");
    const jmethodID getOutputStream = env->GetMethodID(connClass, "getOutputStream", "()Ljava/io/OutputStream;");
    const jmethodID getResponseCode = env->GetMethodID(connClass, "getResponseCode", "()I");
    const jmethodID getInputStream = env->GetMethodID(connClass, "getInputStream", "()Ljava/io/InputStream;");
    const jmethodID getErrorStream = env->GetMethodID(connClass, "getErrorStream", "()Ljava/io/InputStream;");
    const jmethodID getHeaderKey = env->GetMethodID(connClass, "getHeaderFieldKey", "(I)Ljava/lang/String;");
    const jmethodID getHeaderValue = env->GetMethodID(connClass, "getHeaderField", "(I)Ljava/lang/String;");
    const jmethodID disconnect = env->GetMethodID(connClass, "disconnect", "()V");
    const jmethodID readBytes = env->GetMethodID(streamClass, "read", "([B)I");
    const jmethodID closeStream = env->GetMethodID(streamClass, "close", "()V");
    const jmethodID writeBytes = env->GetMethodID(outClass, "write", "([B)V");
    const jmethodID closeOut = env->GetMethodID(outClass, "close", "()V");
    if (env->ExceptionCheck() || !newUrl || !openConnection || !getUrl || !getProtocol || !setMethod || !setConnectTimeout ||
        !setReadTimeout || !setProperty || !setDoOutput || !setFollow || !getOutputStream || !getResponseCode || !getInputStream ||
        !getErrorStream || !getHeaderKey || !getHeaderValue || !disconnect || !readBytes || !closeStream || !writeBytes || !closeOut) {
        env->ExceptionClear();
        return failure("the Java networking classes are not what the engine expects", "This Android version is not supported.");
    }

    jobject conn = nullptr;
    HttpResponse result;
    bool failed = false;
    const auto fail_java = [&] {
        result = java_error(take_exception(env), host, req.timeoutSec);
        failed = true;
    };

    {
        jstring urlText = to_java(env, req.url);
        jobject url = env->NewObject(urlClass, newUrl, urlText);
        env->DeleteLocalRef(urlText);
        if (env->ExceptionCheck() || !url) {
            env->ExceptionClear();
            return failure("the address is not a valid URL: " + req.url, "Write it as https://host/path.");
        }
        conn = env->CallObjectMethod(url, openConnection);
        env->DeleteLocalRef(url);
        if (env->ExceptionCheck() || !conn) {
            fail_java();
            return result;
        }
    }

    const bool patch = req.method == "PATCH";
    const std::string method = patch ? "POST" : req.method;
    {
        jstring m = to_java(env, method);
        env->CallVoidMethod(conn, setMethod, m);
        env->DeleteLocalRef(m);
    }
    if (env->ExceptionCheck()) {
        fail_java();
        env->CallVoidMethod(conn, disconnect);
        env->ExceptionClear();
        return result;
    }
    env->CallVoidMethod(conn, setConnectTimeout, static_cast<jint>(timeoutMs));
    env->CallVoidMethod(conn, setReadTimeout, static_cast<jint>(timeoutMs));
    env->CallVoidMethod(conn, setFollow, JNI_TRUE);
    auto set_header = [&](const std::string& name, const std::string& value) {
        jstring n = to_java(env, name);
        jstring v = to_java(env, value);
        env->CallVoidMethod(conn, setProperty, n, v);
        env->DeleteLocalRef(n);
        env->DeleteLocalRef(v);
    };
    for (const auto& [name, value] : req.headers) set_header(name, value);
    if (patch) set_header("X-HTTP-Method-Override", "PATCH");
    env->ExceptionClear();

    const auto finish = [&](HttpResponse r) {
        env->CallVoidMethod(conn, disconnect);
        env->ExceptionClear();
        env->DeleteLocalRef(conn);
        return r;
    };

    if (!req.body.empty()) {
        env->CallVoidMethod(conn, setDoOutput, JNI_TRUE);
        jobject out = env->CallObjectMethod(conn, getOutputStream);
        if (env->ExceptionCheck() || !out) {
            fail_java();
            return finish(std::move(result));
        }
        jbyteArray bytes = env->NewByteArray(static_cast<jsize>(req.body.size()));
        env->SetByteArrayRegion(bytes, 0, static_cast<jsize>(req.body.size()), reinterpret_cast<const jbyte*>(req.body.data()));
        env->CallVoidMethod(out, writeBytes, bytes);
        env->DeleteLocalRef(bytes);
        const bool writeFailed = env->ExceptionCheck();
        if (writeFailed) {
            fail_java();
        } else {
            env->CallVoidMethod(out, closeOut);
            env->ExceptionClear();
        }
        env->DeleteLocalRef(out);
        if (writeFailed) return finish(std::move(result));
    }

    const jint status = env->CallIntMethod(conn, getResponseCode);
    if (env->ExceptionCheck()) {
        fail_java();
        return finish(std::move(result));
    }

    // An https:// request must have ended on https://.
    if (req.url.rfind("https://", 0) == 0) {
        if (jobject finalUrl = env->CallObjectMethod(conn, getUrl)) {
            const std::string protocol = to_std(env, static_cast<jstring>(env->CallObjectMethod(finalUrl, getProtocol)));
            env->DeleteLocalRef(finalUrl);
            env->ExceptionClear();
            if (protocol != "https")
                return finish(failure("the request to " + host + " was redirected to a URL that is not https://",
                                      "Redirects are only followed to https:// addresses."));
        }
    }

    HttpResponse r;
    r.status = static_cast<int>(status);
    for (jint i = 1;; ++i) {
        jstring key = static_cast<jstring>(env->CallObjectMethod(conn, getHeaderKey, i));
        jstring value = static_cast<jstring>(env->CallObjectMethod(conn, getHeaderValue, i));
        env->ExceptionClear();
        if (!key && !value) break;
        if (key) r.headers.emplace_back(lower(to_std(env, key)), to_std(env, value));
        if (key) env->DeleteLocalRef(key);
        if (value) env->DeleteLocalRef(value);
        if (i > 500) break;
    }

    jobject in = env->CallObjectMethod(conn, status >= 400 ? getErrorStream : getInputStream);
    if (env->ExceptionCheck()) {
        fail_java();
        return finish(std::move(result));
    }
    if (in) {  // null: an error status without a body
        jbyteArray buffer = env->NewByteArray(16 * 1024);
        for (;;) {
            const jint n = env->CallIntMethod(in, readBytes, buffer);
            if (env->ExceptionCheck()) {
                fail_java();
                break;
            }
            if (n < 0) break;
            if (r.body.size() + static_cast<std::size_t>(n) > req.maxResponseBytes) {
                result = failure("the response from " + host + " is longer than " + std::to_string(req.maxResponseBytes / 1024) + " KB",
                                 "http.fetch is for small texts (JSON, configuration); ask the server for less data.");
                failed = true;
                break;
            }
            const std::size_t at = r.body.size();
            r.body.resize(at + static_cast<std::size_t>(n));
            env->GetByteArrayRegion(buffer, 0, n, reinterpret_cast<jbyte*>(r.body.data() + at));
        }
        env->DeleteLocalRef(buffer);
        env->CallVoidMethod(in, closeStream);
        env->ExceptionClear();
        env->DeleteLocalRef(in);
    }
    if (failed) return finish(std::move(result));
    r.ok = true;
    return finish(std::move(r));
}

class AndroidHttpClient final : public HttpClient {
public:
    std::string name() const override { return "httpurlconnection"; }
    bool available() const override { return android_activity() != nullptr; }
    std::string unavailable_reason() const override { return available() ? std::string() : "the Android activity is not running"; }
    void send(HttpRequest request, HttpDone done) override {
        try {
            std::thread([request = std::move(request), done = std::move(done)]() mutable { done(perform(request)); }).detach();
        } catch (const std::system_error& e) {
            done(failure(std::string("could not start a request thread: ") + e.what(), "Too many requests are running at once."));
        }
    }
};

}  // namespace

std::unique_ptr<HttpClient> make_system_http_client() { return std::make_unique<AndroidHttpClient>(); }

}  // namespace fa
