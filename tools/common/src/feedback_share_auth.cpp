// GitHub sign-in of feedback sharing (device flow). Identity only: no scope is requested, the GitHub token goes to the
// feedback server once and is discarded here (docs/design/FEEDBACK_SHARING.md, "GitHub sign-in").
#include <algorithm>
#include <cctype>
#include <chrono>
#include <thread>

#include "fa/core/strings.h"
#include "fa/tooling/feedback_share.h"
#include "util.h"

namespace fa {

namespace {

std::string form_encode(const std::string& s) {
    static const char* hex = "0123456789ABCDEF";
    std::string out;
    for (unsigned char c : s) {
        if (std::isalnum(c) || c == '-' || c == '_' || c == '.' || c == '~') out += static_cast<char>(c);
        else {
            out += '%';
            out += hex[c >> 4];
            out += hex[c & 15];
        }
    }
    return out;
}

HttpRequest github_post(const std::string& url, const std::vector<std::pair<std::string, std::string>>& fields) {
    HttpRequest r;
    r.method = "POST";
    r.url = url;
    r.timeoutSec = 15.0;
    r.maxResponseBytes = 64 * 1024;
    r.headers = {{"Accept", "application/json"}, {"Content-Type", "application/x-www-form-urlencoded"}};
    for (const auto& [k, v] : fields) r.body += (r.body.empty() ? "" : "&") + k + "=" + form_encode(v);
    return r;
}

std::string transport_problem(const HttpResponse& r) {
    return r.error.empty() ? "the request failed with status " + std::to_string(r.status) : r.error;
}

}  // namespace

Result<DeviceCode> github_device_start(const ShareEnv& env) {
    if (env.githubClientId.empty())
        return make_error("GitHub sign-in is not available in this build: it has no GitHub client id.",
                          "Build the engine with -DFA_FEEDBACK_GITHUB_CLIENT_ID=<the client id of the GitHub OAuth app>. "
                          "Signing in is optional: reports are accepted anonymously.");
    // No scope: the token can only read the public profile.
    const HttpResponse resp = env.send(github_post("https://github.com/login/device/code", {{"client_id", env.githubClientId}}));
    if (!resp.ok) return make_error("Could not reach github.com: " + transport_problem(resp), "Check the network connection and try again.");
    Json body = Json::parse(resp.body, nullptr, false);
    if (resp.status != 200 || !body.is_object() || !body.contains("device_code") || !body.contains("user_code"))
        return make_error("GitHub did not start the sign-in (status " + std::to_string(resp.status) + (body.is_object() && body.contains("error_description") && body["error_description"].is_string()
                              ? ": " + body["error_description"].get<std::string>() : std::string()) + ").",
                          "Check that the device flow is enabled for the GitHub OAuth app of this build.");
    DeviceCode code;
    code.deviceCode = body.value("device_code", std::string());
    code.userCode = body.value("user_code", std::string());
    code.verificationUri = body.value("verification_uri", std::string("https://github.com/login/device"));
    code.expiresIn = body.value("expires_in", 900);
    code.interval = std::max(1, body.value("interval", 5));
    return code;
}

Result<std::string> github_device_poll(const ShareEnv& env, const DeviceCode& code, const std::function<bool()>& cancelled) {
    double waited = 0;
    int interval = code.interval;
    auto nap = [&](double seconds) {
        if (env.sleep) env.sleep(seconds);
        else std::this_thread::sleep_for(std::chrono::duration<double>(seconds));
        waited += seconds;
    };
    while (waited <= code.expiresIn) {
        nap(interval);
        if (cancelled && cancelled()) return make_error("Sign-in cancelled.", "Run the sign-in again when you are ready.");
        const HttpResponse resp = env.send(github_post("https://github.com/login/oauth/access_token",
                                                       {{"client_id", env.githubClientId},
                                                        {"device_code", code.deviceCode},
                                                        {"grant_type", "urn:ietf:params:oauth:grant-type:device_code"}}));
        if (!resp.ok) return make_error("Could not reach github.com: " + transport_problem(resp), "Check the network connection and try again.");
        const Json body = Json::parse(resp.body, nullptr, false);
        if (!body.is_object()) return make_error("GitHub answered something that is not JSON (status " + std::to_string(resp.status) + ").");
        if (body.contains("access_token") && body["access_token"].is_string()) return body["access_token"].get<std::string>();
        const std::string error = body.value("error", std::string());
        if (error == "authorization_pending") continue;
        if (error == "slow_down") {
            interval = std::max(interval + 5, body.value("interval", interval + 5));
            continue;
        }
        if (error == "expired_token") return make_error("The sign-in code expired.", "Run the sign-in again to get a new code.");
        if (error == "access_denied") return make_error("The sign-in was refused on GitHub.", "Run the sign-in again and authorize the app, or keep sending anonymously.");
        return make_error("GitHub refused the sign-in: " + (error.empty() ? std::string("status ") + std::to_string(resp.status) : error) + ".",
                          "Run the sign-in again; if it keeps failing, keep sending anonymously.");
    }
    return make_error("The sign-in code expired before it was authorized.", "Run the sign-in again to get a new code.");
}

Result<ShareSignIn> exchange_github_token(const ShareEnv& env, const std::string& githubToken) {
    const ShareSettings settings = load_share_settings(env);
    const std::string endpoint = share_endpoint(env, settings);
    if (endpoint.empty()) return make_error(share_unavailable_message());
    auto install = ensure_install_id(env);
    if (!install.ok()) return install.error();
    HttpRequest req;
    req.method = "POST";
    req.url = endpoint + "/v1/auth/github";
    req.timeoutSec = 15.0;
    req.maxResponseBytes = 64 * 1024;
    req.headers = {{"Content-Type", "application/json"}, {"Accept", "application/json"}, {"X-Factoria-Install", install.value()}};
    req.body = Json::object({{"githubToken", githubToken}}).dump();
    const HttpResponse resp = env.send(req);
    if (!resp.ok) return make_error("Could not reach the feedback server: " + transport_problem(resp), "Check the network connection and try again.");
    const Json body = Json::parse(resp.body, nullptr, false);
    if (resp.status != 200 || !body.is_object() || !body.value("ok", false) || !body.contains("credential") || !body["credential"].is_string()) {
        std::string why = "status " + std::to_string(resp.status);
        if (body.is_object() && body.contains("error") && body["error"].is_object()) why = body["error"].value("message", why);
        return make_error("The feedback server did not accept the GitHub sign-in (" + why + ").", "Try again later; reports are still accepted anonymously.");
    }
    ShareSignIn out;
    out.credential = body["credential"].get<std::string>();
    out.login = body.value("login", std::string());
    return out;
}

Result<ShareSignIn> github_sign_in(const ShareEnv& env, const std::function<void(const DeviceCode&)>& show,
                                   const std::function<bool()>& cancelled) {
    auto code = github_device_start(env);
    if (!code.ok()) return code.error();
    if (show) show(code.value());
    auto token = github_device_poll(env, code.value(), cancelled);
    if (!token.ok()) return token.error();
    auto signIn = exchange_github_token(env, token.value());  // the GitHub token lives in this scope only
    if (!signIn.ok()) return signIn.error();
    ShareSettings settings = load_share_settings(env);
    settings.credential = signIn->credential;
    settings.login = signIn->login;
    if (auto saved = save_share_settings(env, settings); !saved.ok()) return saved.error();
    return signIn.value();
}

Result<void> share_sign_out(const ShareEnv& env) {
    ShareSettings settings = load_share_settings(env);
    if (settings.credential.empty() && settings.login.empty()) return {};
    settings.credential.clear();
    settings.login.clear();
    return save_share_settings(env, settings);
}

}  // namespace fa
