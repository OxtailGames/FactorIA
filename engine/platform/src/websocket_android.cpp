// Android's WebSocket client (fa/platform/websocket.h): the engine's own protocol code (fa/platform/websocket_codec.h, through
// the StreamCore of websocket_stream.h) over a socket stream.
//
//   ws://   the POSIX tcp client (websocket_tcp_posix.cpp). fa/services/network.h lets only localhost through, and Android's
//           cleartext rule is enforced by its HTTP stacks, not by a plain socket, so a server on the device itself works.
//   wss://  TLS from Java through JNI (framework classes only, no Java code of ours): an unconnected java.net.Socket is
//           connected with the time left of the connect timeout, SSLSocketFactory.getDefault() layers TLS over it
//           (createSocket(socket, host, port, true): SNI and the system's certificate store), and after startHandshake the
//           certificate must name the host. SSLSocket checks no host name by itself: the endpoint identification of
//           SSLParameters is set to "HTTPS" and HttpsURLConnection's default HostnameVerifier is asked too; a refusal fails
//           the connection with an error that says so. The bytes go through the socket's InputStream and OutputStream.
//
// Threads: the connection's thread (attached to the JVM by android_thread_env(), detached when it ends) resolves, connects,
// does the TLS and the WebSocket handshakes and then reads, blocking in InputStream.read. A second attached thread writes
// (OutputStream.write blocks too, and a read must not wait for a write). A blocked Java call ends when its socket is closed
// from another thread: the game thread closes the plain socket under the TLS layer (never the SSLSocket, whose close() waits
// for a write in progress) when the connection is destroyed or closed while connecting. Both threads hold a shared_ptr to
// the core, so the global references live until the last of them lets go.
//
// Differences from the tcp client: destroying an open wss:// connection closes the socket at once, without the 1001 close
// frame, because a Java write may block (fa/platform/websocket.h: "only when that takes no waiting"). The server sees 1006.
//
// The DNS lookup (the InetSocketAddress constructor here, getaddrinfo in the tcp client) is neither bounded by the connect
// timeout nor interruptible: close() while connecting reports its Error and Close 1006 once the system's resolver has
// answered, and destroying the connection never waits for it (the thread is detached).
//
// The game's manifest needs the INTERNET permission: the export adds it when factoria.json declares network hosts
// (docs/NETWORKING.md); without it the socket or the DNS lookup fails, and the error says so.
//
// UNTESTED on a device: only compiled by CI (Android job); the shared parts (codec, StreamCore, the tcp path) run in the
// platform tests on every POSIX machine.
#include <jni.h>

#include <algorithm>
#include <chrono>
#include <climits>
#include <condition_variable>
#include <exception>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

#include "android_jni.h"
#include "fa/platform/websocket.h"
#include "websocket_stream.h"

namespace fa {

namespace {

using ws_stream::Clock;
using ws_stream::kCloseWait;

constexpr jint kChunk = 64 * 1024;  // bytes per Java read or write
// How long end_io() waits for the writer thread to end after the socket was closed (closing it ends a write that is stuck).
constexpr auto kWriterEndWait = std::chrono::seconds(2);

// The framework classes and methods the TLS client calls, looked up by the connection's thread. The method IDs stay valid
// on every thread (framework classes are never unloaded); the class references are local to that thread's frame.
struct JavaApi {
    jclass socket = nullptr, address = nullptr, factory = nullptr, sni = nullptr, collections = nullptr,
           https = nullptr;
    jmethodID socketInit = nullptr, socketConnect = nullptr, socketClose = nullptr, socketNoDelay = nullptr;
    jmethodID socketSoTimeout = nullptr, socketInput = nullptr, socketOutput = nullptr;
    jmethodID addressInit = nullptr, addressUnresolved = nullptr;
    jmethodID factoryDefault = nullptr, factoryLayer = nullptr;
    jmethodID sslHandshake = nullptr, sslSession = nullptr, sslGetParams = nullptr, sslSetParams = nullptr;
    jmethodID paramsEndpoint = nullptr, paramsServerNames = nullptr;
    jmethodID sniInit = nullptr, singletonList = nullptr, defaultVerifier = nullptr, verify = nullptr;
    jmethodID inRead = nullptr, outWrite = nullptr;

    // False when one is missing (every exception cleared).
    bool load(JNIEnv* env) {
        bool ok = true;
        const auto cls = [&](const char* name) -> jclass {
            jclass c = env->FindClass(name);
            if (android_clear_exception(env) || !c) {
                ok = false;
                return nullptr;
            }
            return c;
        };
        const auto method = [&](jclass c, const char* name, const char* sig, bool isStatic = false) -> jmethodID {
            if (!c) {
                ok = false;
                return nullptr;
            }
            jmethodID m = isStatic ? env->GetStaticMethodID(c, name, sig) : env->GetMethodID(c, name, sig);
            if (android_clear_exception(env) || !m) ok = false;
            return m;
        };
        socket = cls("java/net/Socket");
        address = cls("java/net/InetSocketAddress");
        factory = cls("javax/net/ssl/SSLSocketFactory");
        sni = cls("javax/net/ssl/SNIHostName");
        collections = cls("java/util/Collections");
        https = cls("javax/net/ssl/HttpsURLConnection");
        jclass ssl = cls("javax/net/ssl/SSLSocket");
        jclass params = cls("javax/net/ssl/SSLParameters");
        jclass verifier = cls("javax/net/ssl/HostnameVerifier");
        jclass in = cls("java/io/InputStream");
        jclass out = cls("java/io/OutputStream");
        socketInit = method(socket, "<init>", "()V");
        socketConnect = method(socket, "connect", "(Ljava/net/SocketAddress;I)V");
        socketClose = method(socket, "close", "()V");
        socketNoDelay = method(socket, "setTcpNoDelay", "(Z)V");
        socketSoTimeout = method(socket, "setSoTimeout", "(I)V");
        socketInput = method(socket, "getInputStream", "()Ljava/io/InputStream;");
        socketOutput = method(socket, "getOutputStream", "()Ljava/io/OutputStream;");
        addressInit = method(address, "<init>", "(Ljava/lang/String;I)V");
        addressUnresolved = method(address, "isUnresolved", "()Z");
        factoryDefault = method(factory, "getDefault", "()Ljavax/net/SocketFactory;", true);
        factoryLayer = method(factory, "createSocket", "(Ljava/net/Socket;Ljava/lang/String;IZ)Ljava/net/Socket;");
        sslHandshake = method(ssl, "startHandshake", "()V");
        sslSession = method(ssl, "getSession", "()Ljavax/net/ssl/SSLSession;");
        sslGetParams = method(ssl, "getSSLParameters", "()Ljavax/net/ssl/SSLParameters;");
        sslSetParams = method(ssl, "setSSLParameters", "(Ljavax/net/ssl/SSLParameters;)V");
        paramsEndpoint = method(params, "setEndpointIdentificationAlgorithm", "(Ljava/lang/String;)V");
        paramsServerNames = method(params, "setServerNames", "(Ljava/util/List;)V");
        sniInit = method(sni, "<init>", "(Ljava/lang/String;)V");
        singletonList = method(collections, "singletonList", "(Ljava/lang/Object;)Ljava/util/List;", true);
        defaultVerifier = method(https, "getDefaultHostnameVerifier", "()Ljavax/net/ssl/HostnameVerifier;", true);
        verify = method(verifier, "verify", "(Ljava/lang/String;Ljavax/net/ssl/SSLSession;)Z");
        inRead = method(in, "read", "([BII)I");
        outWrite = method(out, "write", "([BII)V");
        for (jclass c : {ssl, params, verifier, in, out})
            if (c) env->DeleteLocalRef(c);
        return ok;
    }
};

bool is_ip_literal(const std::string& host) {
    if (host.find(':') != std::string::npos) return true;  // IPv6 (parse_url drops the brackets)
    return !host.empty() && host.find_first_not_of("0123456789.") == std::string::npos;
}

// The milliseconds left until `deadline` as a Java timeout (0 = none left; never 0 for "infinite").
jint ms_left(Clock::time_point deadline) {
    const auto left = std::chrono::duration_cast<std::chrono::milliseconds>(deadline - Clock::now()).count();
    return static_cast<jint>(std::clamp<long long>(left, 0, INT_MAX));
}

bool has(const std::string& text, const char* part) { return text.find(part) != std::string::npos; }

// One wss:// connection. See the top of the file for its threads.
class TlsCore final : public ws_stream::StreamCore {
public:
    using StreamCore::StreamCore;

    // Runs on whichever attached thread lets go last (one of the connection's threads, or the game thread).
    ~TlsCore() override {
        if (!raw_ && !ssl_ && !in_ && !out_) return;
        JNIEnv* env = android_thread_env();
        if (!env) return;
        for (jobject ref : {in_, out_, ssl_, raw_})
            if (ref) env->DeleteGlobalRef(ref);
    }

private:
    enum class Step { Connect, Tls, Answer };

    void wake() override { cv_.notify_all(); }  // mutex_ may be held: notify_all does not need it

    void interrupt() override {
        {
            std::lock_guard<std::mutex> lock(mutex_);
        }  // the writer is before its check of stop_, or waiting
        cv_.notify_all();
        close_raw(android_thread_env());
    }

    // The game's frame: when a close frame cannot leave (the writer has been stuck in a write since the close wait began),
    // close the socket so that the connection ends with Error and Close 1006 on time. It runs from poll() only: while the
    // app is in the background and no frame is drawn, a stuck close waits there until the next frame (or the socket's end).
    void tick() override {
        {
            std::lock_guard<std::mutex> lock(mutex_);
            if (watchdogFired_ || !writing_ || state_.load() != WebSocketState::Closing || !session_.close_sent() ||
                session_.close_received() || Clock::now() - closeAsked_ <= kCloseWait)
                return;
            watchdogFired_ = true;
        }
        close_raw(android_thread_env());
    }

    // Closes the plain socket under the TLS layer: every blocked read, write, connect or handshake of it ends.
    void close_raw(JNIEnv* env) {
        if (!env) return;
        std::lock_guard<std::mutex> lock(javaMutex_);
        if (!raw_ || rawClosed_) return;
        rawClosed_ = true;
        env->CallVoidMethod(raw_, socketClose_);
        env->ExceptionClear();
    }

    // The game thread may close the socket from now on; false: it was closed or destroyed already (the caller stops).
    bool publish_raw(JNIEnv* env, jobject raw) {
        jobject global = env->NewGlobalRef(raw);
        if (!global) {
            env->ExceptionClear();
            fail_connect("could not start the connection (the Java runtime is out of memory)", "Try again.");
            return false;
        }
        std::lock_guard<std::mutex> lock(javaMutex_);
        raw_ = global;
        return !stopping();
    }

    // Reports the pending Java exception as a failed connection (nothing when the game closed or destroyed it meanwhile:
    // finish_aborted() speaks then).
    void fail_java(JNIEnv* env, Step step) {
        const JavaError e = android_take_exception(env);
        if (stopping()) return;
        const std::string& host = url_.host;
        const std::string all = e.cls + " " + e.message + " " + e.causeCls + " " + e.causeMessage;
        // No pending exception (an empty JavaError): say that, not "could not connect to host ()".
        const std::string detail = !e.message.empty() ? e.message
                                   : !e.cls.empty()   ? e.cls
                                                      : std::string("Java gave no reason");
        if (e.cls == "java.lang.SecurityException" || has(all, "EACCES") || has(all, "EPERM") ||
            has(all, "Permission denied")) {
            fail_connect("the game is not allowed to use the network: " + detail,
                         "The app needs the INTERNET permission: declare the hosts in factoria.json \"network\" and "
                         "export again.");
        } else if (e.cls == "java.net.SocketTimeoutException") {
            if (step == Step::Answer)
                fail_connect("timed out waiting for the server's answer to the handshake",
                             "Check that the address is a WebSocket server and not a web page.");
            else
                fail_connect(step == Step::Tls ? "timed out in the secure handshake with " + host
                                               : "timed out connecting to " + host,
                             "Check that the server is running and that the address and port are right.");
        } else if (e.cls == "java.net.UnknownHostException") {
            fail_connect("could not find the server " + host + " (" + detail + ")",
                         "Check the address, and that the device is online.");
        } else if (e.cls == "java.net.ConnectException" || e.cls == "java.net.NoRouteToHostException") {
            fail_connect("could not connect to " + host + ":" + std::to_string(url_.port) + " (" + detail + ")",
                         "Check that the server is running and that the address and port are right.");
        } else if (e.cls.rfind("javax.net.ssl.", 0) == 0 || has(all, "Certificate") || has(all, "certificate")) {
            fail_connect("the secure connection to " + host + " failed: " + detail +
                             (e.causeMessage.empty() ? std::string() : " (" + e.causeMessage + ")"),
                         "The device does not trust the server's certificate, or it is not issued for " + host +
                             ": an expired certificate, a wrong clock on the device, a proxy that rewrites traffic, or "
                             "an address that is not the name in the certificate.");
        } else if (step == Step::Answer) {
            fail_connect("the connection to " + host + " broke during the handshake (" + detail + ")",
                         "Check the address and the port, and that the server speaks WebSocket.");
        } else {
            fail_connect("could not connect to " + host + " (" + detail + ")",
                         "Check the connection, and that the server is up.");
        }
    }

    // SNI and the TLS layer's own host name check (endpoint identification "HTTPS"). Anything this Android version does
    // not take is skipped: the HostnameVerifier check after the handshake is the one that must pass.
    void configure_tls(JNIEnv* env, const JavaApi& j, jobject ssl, jstring host) {
        jobject params = env->CallObjectMethod(ssl, j.sslGetParams);
        if (android_clear_exception(env) || !params) return;
        if (jstring https = env->NewStringUTF("HTTPS")) {
            env->CallVoidMethod(params, j.paramsEndpoint, https);
            env->ExceptionClear();
            env->DeleteLocalRef(https);
        }
        env->ExceptionClear();
        if (!is_ip_literal(url_.host)) {
            jobject name = env->NewObject(j.sni, j.sniInit, host);
            if (!android_clear_exception(env) && name) {
                jobject list = env->CallStaticObjectMethod(j.collections, j.singletonList, name);
                if (!android_clear_exception(env) && list) {
                    env->CallVoidMethod(params, j.paramsServerNames, list);
                    env->ExceptionClear();
                    env->DeleteLocalRef(list);
                }
                env->DeleteLocalRef(name);
            }
        }
        env->CallVoidMethod(ssl, j.sslSetParams, params);
        env->ExceptionClear();
        env->DeleteLocalRef(params);
    }

    // Resolves, connects, layers TLS, checks the certificate's name and keeps the streams. Local references belong to the
    // caller's frame. false: reported (or the connection was closed or destroyed meanwhile).
    bool connect_tls(JNIEnv* env, JavaApi& j, Clock::time_point deadline) {
        if (!j.load(env)) {
            fail_connect("the Java TLS classes are not what the engine expects",
                         "This Android version is not supported.");
            return false;
        }
        socketClose_ = j.socketClose;
        soTimeout_ = j.socketSoTimeout;
        inRead_ = j.inRead;
        outWrite_ = j.outWrite;
        jobject raw = env->NewObject(j.socket, j.socketInit);
        if (env->ExceptionCheck() || !raw) {
            fail_java(env, Step::Connect);
            return false;
        }
        if (!publish_raw(env, raw)) return false;
        jstring host = env->NewStringUTF(url_.host.c_str());
        if (env->ExceptionCheck() || !host) {
            fail_java(env, Step::Connect);
            return false;
        }
        jobject address = env->NewObject(j.address, j.addressInit, host, static_cast<jint>(url_.port));  // DNS lookup
        if (env->ExceptionCheck() || !address) {
            fail_java(env, Step::Connect);
            return false;
        }
        if (stopping()) return false;
        const bool unresolved = env->CallBooleanMethod(address, j.addressUnresolved) == JNI_TRUE;
        if (android_clear_exception(env) || unresolved) {
            fail_connect("could not find the server " + url_.host,
                         "Check the address, and that the device is online (and that the app has the INTERNET "
                         "permission: declare the hosts in factoria.json \"network\").");
            return false;
        }
        const jint connectMs = ms_left(deadline);
        if (connectMs <= 0) {
            fail_connect("timed out connecting to " + url_.host,
                         "Check that the server is running and that the address and port are right.");
            return false;
        }
        env->CallVoidMethod(raw, j.socketConnect, address, connectMs);
        if (env->ExceptionCheck()) {
            fail_java(env, Step::Connect);
            return false;
        }
        env->CallVoidMethod(raw, j.socketNoDelay, JNI_TRUE);
        env->ExceptionClear();
        jobject factory = env->CallStaticObjectMethod(j.factory, j.factoryDefault);
        if (env->ExceptionCheck() || !factory) {
            fail_java(env, Step::Tls);
            return false;
        }
        jobject ssl = env->CallObjectMethod(factory, j.factoryLayer, raw, host, static_cast<jint>(url_.port), JNI_TRUE);
        if (env->ExceptionCheck() || !ssl) {
            fail_java(env, Step::Tls);
            return false;
        }
        ssl_ = env->NewGlobalRef(ssl);
        if (!ssl_) {
            env->ExceptionClear();
            fail_connect("could not start the connection (the Java runtime is out of memory)", "Try again.");
            return false;
        }
        configure_tls(env, j, ssl, host);
        const jint handshakeMs = ms_left(deadline);
        if (handshakeMs <= 0) {
            fail_connect("timed out in the secure handshake with " + url_.host,
                         "Check that the server is running and that the address and port are right.");
            return false;
        }
        env->CallVoidMethod(ssl, j.socketSoTimeout, handshakeMs);
        env->ExceptionClear();
        env->CallVoidMethod(ssl, j.sslHandshake);
        if (env->ExceptionCheck()) {
            fail_java(env, Step::Tls);
            return false;
        }
        if (stopping()) return false;
        // SSLSocket checked the certificate's chain, not the name it was issued for.
        bool verified = false;
        jobject session = env->CallObjectMethod(ssl, j.sslSession);
        jobject verifier =
            android_clear_exception(env) ? nullptr : env->CallStaticObjectMethod(j.https, j.defaultVerifier);
        if (!android_clear_exception(env) && session && verifier) {
            verified = env->CallBooleanMethod(verifier, j.verify, host, session) == JNI_TRUE;
            if (android_clear_exception(env)) verified = false;
        }
        if (!verified) {
            fail_connect("the certificate of " + url_.host + " is not issued for that name",
                         "Use the host name the server's certificate names (not its IP address or another name of the "
                         "same machine); if it is right, something between the device and the server answers in its "
                         "place.");
            return false;
        }
        jobject in = env->CallObjectMethod(ssl, j.socketInput);
        if (env->ExceptionCheck() || !in) {
            fail_java(env, Step::Tls);
            return false;
        }
        jobject out = env->CallObjectMethod(ssl, j.socketOutput);
        if (env->ExceptionCheck() || !out) {
            fail_java(env, Step::Tls);
            return false;
        }
        in_ = env->NewGlobalRef(in);
        out_ = env->NewGlobalRef(out);
        if (!in_ || !out_) {
            env->ExceptionClear();
            fail_connect("could not start the connection (the Java runtime is out of memory)", "Try again.");
            return false;
        }
        return true;
    }

    // Writes all of `bytes` through out_ with `buf` (kChunk bytes); false leaves the Java exception pending.
    bool write_all(JNIEnv* env, jbyteArray buf, const std::string& bytes) {
        for (std::size_t at = 0; at < bytes.size();) {
            const jint n = static_cast<jint>(std::min<std::size_t>(bytes.size() - at, kChunk));
            env->SetByteArrayRegion(buf, 0, n, reinterpret_cast<const jbyte*>(bytes.data() + at));
            env->CallVoidMethod(out_, outWrite_, buf, 0, n);
            if (env->ExceptionCheck()) return false;
            at += static_cast<std::size_t>(n);
        }
        return true;
    }

    // The WebSocket handshake over the TLS stream; reads time out with what is left of the connect timeout.
    bool handshake(JNIEnv* env, Clock::time_point deadline, std::string& leftover) {
        std::string key, request;
        if (!begin_handshake(key, request)) return false;
        jbyteArray buf = env->NewByteArray(kChunk);
        if (android_clear_exception(env) || !buf) {
            fail_connect("could not start the connection (the Java runtime is out of memory)", "Try again.");
            return false;
        }
        if (!write_all(env, buf, request)) {
            fail_java(env, Step::Answer);
            return false;
        }
        std::string data;
        std::vector<char> bytes(kChunk);
        for (;;) {
            const jint left = ms_left(deadline);
            if (left <= 0) {
                fail_connect("timed out waiting for the server's answer to the handshake",
                             "Check that the address is a WebSocket server and not a web page.");
                return false;
            }
            env->CallVoidMethod(ssl_, soTimeout_, left);
            env->ExceptionClear();
            const jint n = env->CallIntMethod(in_, inRead_, buf, 0, kChunk);
            if (env->ExceptionCheck()) {
                fail_java(env, Step::Answer);
                return false;
            }
            if (n < 0) {
                if (!stopping())
                    fail_connect("the server closed the connection during the handshake",
                                 "Check the address and the port, and that the server speaks WebSocket.");
                return false;
            }
            if (n == 0) continue;
            env->GetByteArrayRegion(buf, 0, n, reinterpret_cast<jbyte*>(bytes.data()));
            data.append(bytes.data(), static_cast<std::size_t>(n));
            const int checked = check_handshake(data, key, leftover);
            if (checked < 0) return false;
            if (checked > 0) break;
        }
        env->CallVoidMethod(ssl_, soTimeout_, 0);  // from now on a read waits for data, a close or the socket's end
        env->ExceptionClear();
        return true;
    }

    // Starts the writer thread and waits until it has its Java environment (it needs one to write): a writer that cannot
    // attach would leave the connection Open with nothing able to send, and close() Closing for ever.
    bool start_writer() {
        {
            std::lock_guard<std::mutex> lock(mutex_);
            writerDone_ = false;
            writerReady_ = writerFailed_ = false;
        }
        try {
            std::thread([self = std::static_pointer_cast<TlsCore>(shared_from_this())] {
                self->write_loop();
            }).detach();
        } catch (const std::exception& e) {  // no thread to be had (std::system_error)
            {
                std::lock_guard<std::mutex> lock(mutex_);
                writerDone_ = true;
            }
            fail_connect(std::string("could not start the connection (") + e.what() + ")",
                         "Close other connections or programs and try again.");
            return false;
        }
        bool failed;
        {
            // Attaching a thread takes no waiting for the network; the game closing or destroying the connection ends it too
            // (interrupt() takes the mutex before it notifies).
            std::unique_lock<std::mutex> lock(mutex_);
            cv_.wait(lock, [&] { return writerReady_ || writerFailed_ || stopping(); });
            failed = writerFailed_;
        }
        if (failed) {
            fail_connect("could not start the connection (the Java runtime is not available on a new thread)",
                         "Restart the game; close other connections or programs and try again.");
            return false;
        }
        return !stopping();
    }

    // The writer's thread: writes what the session queued until the reader ends (after it flushed the rest), the
    // connection is destroyed, a write fails, or the peer does not answer our close frame in time.
    void write_loop() {
        JNIEnv* env = android_thread_env();
        jbyteArray buf = env ? env->NewByteArray(kChunk) : nullptr;
        if (env && !buf) env->ExceptionClear();
        bool closeSocket = !buf;  // no Java: the reader must not wait for this thread's writes
        {
            std::lock_guard<std::mutex> lock(mutex_);
            (buf ? writerReady_ : writerFailed_) = true;  // start_writer() is waiting for this
        }
        cv_.notify_all();
        std::string chunk;
        while (buf) {
            bool write = false;
            {
                std::unique_lock<std::mutex> lock(mutex_);
                for (;;) {
                    if (stop_) break;
                    take_session_output();
                    if (sent_ < outgoing_.size()) {
                        chunk.assign(outgoing_, sent_, static_cast<std::size_t>(kChunk));
                        writing_ = true;
                        write = true;
                        break;
                    }
                    outgoing_.clear();
                    sent_ = 0;
                    if (readerDone_) break;
                    if (state_.load() == WebSocketState::Closing && session_.close_sent() &&
                        !session_.close_received()) {
                        // Our close frame is out: the peer has kCloseWait to answer, then the socket is closed and the
                        // reader reports the connection lost.
                        const auto until = closeAsked_ + kCloseWait;
                        if (Clock::now() >= until) {
                            closeSocket = true;
                            break;
                        }
                        cv_.wait_until(lock, until);
                    } else {
                        cv_.wait(lock);
                    }
                }
            }
            if (!write) break;
            const jint n = static_cast<jint>(chunk.size());
            env->SetByteArrayRegion(buf, 0, n, reinterpret_cast<const jbyte*>(chunk.data()));
            env->CallVoidMethod(out_, outWrite_, buf, 0, n);
            const bool failed = android_clear_exception(env);
            {
                std::lock_guard<std::mutex> lock(mutex_);
                writing_ = false;
                if (!failed) {
                    sent_ += static_cast<std::size_t>(n);
                    if (sent_ >= 1024 * 1024) {  // a game that keeps sending never lets the buffer empty: trim it
                        outgoing_.erase(0, sent_);
                        sent_ = 0;
                    }
                }
            }
            if (failed) {
                closeSocket = true;  // the reader notices and reports the connection lost
                break;
            }
        }
        if (closeSocket) close_raw(env);
        if (buf) env->DeleteLocalRef(buf);
        {
            std::lock_guard<std::mutex> lock(mutex_);
            writing_ = false;
            writerDone_ = true;
        }
        cv_.notify_all();
    }

    // The reading part of an open connection, until the closing handshake is over, the protocol fails, the stream ends or
    // the connection is destroyed.
    void read_loop(JNIEnv* env, const std::string& leftover, ws_stream::Ending& ending) {
        if (!leftover.empty()) feed(leftover.data(), leftover.size(), ending);
        jbyteArray buf = env->NewByteArray(kChunk);
        if (android_clear_exception(env) || !buf) {
            ending.lost = true;
            return;
        }
        std::vector<char> bytes(kChunk);
        while (!stop_ && !dead_) {
            {
                std::lock_guard<std::mutex> lock(mutex_);
                if (session_.done()) break;
            }
            const jint n = env->CallIntMethod(in_, inRead_, buf, 0, kChunk);
            if (android_clear_exception(env) || n < 0) {
                ending.lost = true;
                break;
            }
            if (n == 0) continue;
            env->GetByteArrayRegion(buf, 0, n, reinterpret_cast<jbyte*>(bytes.data()));
            feed(bytes.data(), static_cast<std::size_t>(n), ending);
        }
        env->DeleteLocalRef(buf);
    }

    // The reader is done: the writer sends what is left (the answer to a close, the close frame of a failure) for up to
    // kCloseWait unless the connection was destroyed, then the socket is closed, which also ends a write that is stuck.
    void end_io(JNIEnv* env, bool flushFirst) {
        std::unique_lock<std::mutex> lock(mutex_);
        readerDone_ = true;
        cv_.notify_all();
        if (flushFirst) cv_.wait_until(lock, Clock::now() + kCloseWait, [&] { return writerDone_ || stop_.load(); });
        lock.unlock();
        close_raw(env);
        lock.lock();
        const bool writerEnded = cv_.wait_for(lock, kWriterEndWait, [&] { return writerDone_; });
        lock.unlock();
        if (env && ssl_ && writerEnded) {  // frees the TLS state now rather than when the collector finds it
            env->CallVoidMethod(ssl_, socketClose_);
            env->ExceptionClear();
        }
    }

    void run() override {
        JNIEnv* env = android_thread_env();
        if (!env) {
            fail_connect("the Java runtime is not available", "Restart the game.");
            return;
        }
        const auto deadline = connect_deadline();
        std::string leftover;
        bool opened = false;
        if (env->PushLocalFrame(64) == JNI_OK) {
            JavaApi api;
            opened = connect_tls(env, api, deadline) && handshake(env, deadline, leftover) && start_writer() &&
                     open_connection();
            env->PopLocalFrame(nullptr);
        } else {
            env->ExceptionClear();
            fail_connect("could not start the connection (the Java runtime is out of memory)", "Try again.");
        }
        if (!opened) {
            finish_aborted();
            end_io(env, false);
            return;
        }
        ws_stream::Ending ending;
        read_loop(env, leftover, ending);
        if (dead_ && !stop_) queue_goodbye();  // the queue overflowed: the writer sends 1008 within the close wait
        end_io(env, !stop_);
        finish(ending);
    }

    std::condition_variable cv_;  // with mutex_: the writer waits for output, its close deadline or the end
    // Guarded by mutex_.
    bool writing_ = false;        // the writer is in OutputStream.write
    bool readerDone_ = false;     // the reader stopped: the writer flushes what is left and ends
    bool writerDone_ = true;      // no writer thread is running (none started yet, or it ended)
    bool writerReady_ = false;    // the writer has its Java environment and buffer
    bool writerFailed_ = false;   // it has not: the connection never opens
    bool watchdogFired_ = false;  // tick() closed the socket already

    std::mutex javaMutex_;  // guards raw_ and rawClosed_: the game thread closes raw_ to end a blocked call
    jobject raw_ = nullptr;
    bool rawClosed_ = false;
    // Set once by the connection's thread before the writer starts (ssl_, in_, out_) or before raw_ is published.
    jobject ssl_ = nullptr, in_ = nullptr, out_ = nullptr;
    jmethodID socketClose_ = nullptr, soTimeout_ = nullptr, inRead_ = nullptr, outWrite_ = nullptr;
};

class AndroidWebSocketClient final : public WebSocketClient {
public:
    std::string name() const override { return "socket"; }
    bool available() const override { return android_activity() != nullptr; }
    std::string unavailable_reason() const override {
        return available() ? std::string() : "the Android activity is not running";
    }
    Result<std::unique_ptr<WebSocket>> connect(WebSocketRequest request) override {
        if (!available())
            return make_error("WebSockets are not available: " + unavailable_reason(), "Restart the game.");
        auto url = ws_stream::check_request(request);
        if (!url.ok()) return url.error();
        std::shared_ptr<ws_stream::StreamCore> core;
        if (url->secure)
            core = std::make_shared<TlsCore>(std::move(request), std::move(url.value()));
        else
            core = ws_stream::make_tcp_core(std::move(request), std::move(url.value()));
        return std::unique_ptr<WebSocket>(std::make_unique<ws_stream::StreamWebSocket>(std::move(core)));
    }
};

}  // namespace

std::unique_ptr<WebSocketClient> make_system_websocket_client() { return std::make_unique<AndroidWebSocketClient>(); }

}  // namespace fa
