// 3D models from Meshy's text-to-3D API, an asynchronous one: create a task, poll it until it succeeds, download the GLB.
//   POST /openapi/v2/text-to-3d       {"mode": "preview", "prompt": ...}  ->  {"result": "<task id>"}
//   GET  /openapi/v2/text-to-3d/{id}  ->  {"status": PENDING|IN_PROGRESS|SUCCEEDED|FAILED|CANCELED, "model_urls": {"glb": url}, ...}
//   https://docs.meshy.ai/en/api/text-to-3d
// A "preview" task makes the untextured mesh (a "refine" task would texture it, for a second payment).
#include "asset_providers.h"
#include "provider_util.h"
#include "util.h"

namespace fa::ai {

using namespace util;

namespace {

constexpr double kPollSeconds = 5;
constexpr std::size_t kMaxPromptChars = 800;

}  // namespace

Result<AssetResult> meshy_asset(const ProviderConfig& cfg, const AssetRequest& req, const ProviderRuntime& rt, const CancelFlag* cancel) {
    auto key = asset_api_key(cfg, rt);
    if (!key) return key.error();
    if (req.prompt.size() > kMaxPromptChars) {
        return make_error("The prompt has " + std::to_string(req.prompt.size()) + " characters; Meshy takes at most " +
                              std::to_string(kMaxPromptChars),
                          "Describe the model in fewer words: shape, material, style.");
    }
    const std::string model = req.model.empty() ? "latest" : req.model;
    const std::string tasks = trim_slashes(cfg.baseUrl) + "/openapi/v2/text-to-3d";
    auto authorize = [&](HttpRequest& hr) {
        hr.headers.emplace_back("Authorization", "Bearer " + *key);
        for (const auto& kv : cfg.headers) hr.headers.push_back(kv);
    };

    HttpRequest create;
    create.url = tasks;
    create.headers.emplace_back("Content-Type", "application/json");
    authorize(create);
    create.body = dump(Json::object({{"mode", "preview"}, {"prompt", req.prompt}, {"ai_model", model}}));
    auto created = asset_request(cfg, std::move(create), rt, cancel);
    if (!created) return created.error();
    const std::string id = str(parse(created->body), "result");
    if (id.empty()) {
        return make_error("Meshy answered without a task id: " + created->body.substr(0, 200),
                          "The reply must be {\"result\": \"<task id>\"}. Check the key and the account's credits.");
    }

    // Poll. rt.sleep is the seam tests replace; the wait is counted in poll intervals, not read from a clock.
    for (double waited = 0;; waited += kPollSeconds) {
        HttpRequest poll;
        poll.method = "GET";
        poll.url = tasks + "/" + id;
        authorize(poll);
        auto polled = asset_request(cfg, std::move(poll), rt, cancel);
        if (!polled) return polled.error();
        const Json task = parse(polled->body);
        const std::string status = str(task, "status");
        if (status == "SUCCEEDED") {
            const Json* urls = child(task, "model_urls");
            const std::string glb = urls ? str(*urls, "glb") : std::string();
            if (glb.empty()) return make_error("Meshy finished task " + id + " without a GLB file", "Reply: " + polled->body.substr(0, 200));
            HttpRequest download;  // a signed link on Meshy's storage: no key goes with it
            download.method = "GET";
            download.url = glb;
            auto file = asset_request(cfg, std::move(download), rt, cancel);
            if (!file) return file.error();
            AssetResult out;
            out.bytes = std::move(file->body);
            out.model = model;
            return out;
        }
        if (status == "FAILED" || status == "CANCELED") {
            const Json* err = child(task, "task_error");
            const std::string why = err ? str(*err, "message") : std::string();
            return make_error("Meshy " + std::string(status == "FAILED" ? "failed" : "canceled") + " task " + id + (why.empty() ? "" : ": " + why),
                              "Try another prompt. A failed task costs no credits.");
        }
        if (waited >= cfg.timeoutSeconds) {
            return make_error("Meshy task " + id + " was still " + (status.empty() ? "running" : status) + " after " +
                                  std::to_string(static_cast<int>(waited)) + " seconds",
                              "Raise \"timeoutSeconds\" of the meshy provider in ai.json, or retry later: the task keeps running on Meshy's side.");
        }
        if (rt.sleep) rt.sleep(kPollSeconds);
        else default_sleep(kPollSeconds, cancel);
        if (is_cancelled(cancel)) return make_error("Cancelled");
    }
}

}  // namespace fa::ai
