// Images and voice from the OpenAI API (and servers that copy it).
//   images:  POST {baseUrl}/images/generations, and POST {baseUrl}/images/edits with reference images (multipart/form-data)
//            https://developers.openai.com/api/docs/guides/image-generation
//   voice:   POST {baseUrl}/audio/speech
//            https://developers.openai.com/api/docs/guides/text-to-speech
#include "asset_providers.h"
#include "fa/core/strings.h"
#include "util.h"

namespace fa::ai {

using namespace util;

namespace {

constexpr const char* kImageModel = "gpt-image-1";
constexpr const char* kSpeechModel = "gpt-4o-mini-tts";
constexpr const char* kSpeechVoice = "alloy";  // accepted by every speech model
constexpr std::size_t kMaxSpeechChars = 4096;

// gpt-image-1 draws at 1024x1024, 1536x1024 or 1024x1536 only: the closest shape; the caller resizes to what it asked for.
const char* image_size(const AssetRequest& req) {
    const double aspect = req.height > 0 ? static_cast<double>(req.width) / req.height : 1.0;
    return aspect > 1.25 ? "1536x1024" : aspect < 0.8 ? "1024x1536" : "1024x1024";
}

// multipart/form-data, built by hand: HttpRequest takes a raw body.
class Multipart {
public:
    explicit Multipart(std::string boundary) : boundary_(std::move(boundary)) {}
    void field(const std::string& name, const std::string& value) {
        body_ += "--" + boundary_ + "\r\nContent-Disposition: form-data; name=\"" + name + "\"\r\n\r\n" + value + "\r\n";
    }
    void file(const std::string& name, std::string filename, const std::string& mediaType, const std::string& bytes) {
        for (char& c : filename) if (c == '"' || c == '\r' || c == '\n') c = '_';
        body_ += "--" + boundary_ + "\r\nContent-Disposition: form-data; name=\"" + name + "\"; filename=\"" + filename +
                 "\"\r\nContent-Type: " + mediaType + "\r\n\r\n" + bytes + "\r\n";
    }
    std::string finish() { return body_ + "--" + boundary_ + "--\r\n"; }
    const std::string& boundary() const { return boundary_; }

private:
    std::string boundary_, body_;
};

Result<AssetResult> image(const ProviderConfig& cfg, const AssetRequest& req, const ProviderRuntime& rt, const CancelFlag* cancel,
                          const std::string& key) {
    const std::string model = req.model.empty() ? kImageModel : req.model;
    HttpRequest hr;
    hr.headers.emplace_back("Authorization", "Bearer " + key);
    for (const auto& kv : cfg.headers) hr.headers.push_back(kv);
    if (req.references.empty()) {
        hr.url = trim_slashes(cfg.baseUrl) + "/images/generations";
        hr.headers.emplace_back("Content-Type", "application/json");
        Json body = Json::object({{"model", model}, {"prompt", req.prompt}, {"n", 1}, {"size", image_size(req)}, {"output_format", "png"}});
        if (req.transparent) body["background"] = "transparent";
        hr.body = dump(body);
    } else {
        // Reference images go to the edits endpoint as image[] parts. It takes PNG, JPEG and WebP.
        for (const ReferenceImage& r : req.references) {
            if (r.mediaType != "image/png" && r.mediaType != "image/jpeg" && r.mediaType != "image/webp") {
                return make_error("OpenAI takes reference images as PNG, JPEG or WebP, not '" + r.name + "' (" + r.mediaType + ")",
                                  "Convert the reference to PNG, or remove it from the call and from style.references.");
            }
        }
        Multipart form("factoria-form-boundary-9d41c7e2");
        for (const ReferenceImage& r : req.references) form.file("image[]", r.name, r.mediaType, r.bytes);
        form.field("model", model);
        form.field("prompt", req.prompt);
        form.field("size", image_size(req));
        form.field("output_format", "png");
        if (req.transparent) form.field("background", "transparent");
        hr.url = trim_slashes(cfg.baseUrl) + "/images/edits";
        hr.headers.emplace_back("Content-Type", "multipart/form-data; boundary=" + form.boundary());
        hr.body = form.finish();
    }
    auto resp = asset_request(cfg, std::move(hr), rt, cancel);
    if (!resp) return resp.error();
    const Json reply = parse(resp->body);
    const Json* data = child(reply, "data");
    const std::string b64 = data && data->is_array() && !data->empty() ? str((*data)[0], "b64_json") : std::string();
    if (b64.empty()) {
        return make_error("OpenAI answered without image data: " + resp->body.substr(0, 200),
                          "The reply must have data[0].b64_json (gpt-image-1 always answers that way). Check the model name.");
    }
    const auto bytes = fa::base64_decode(b64);
    AssetResult out;
    out.bytes.assign(bytes.begin(), bytes.end());
    out.model = model;
    out.usedReferences = !req.references.empty();
    return out;
}

Result<AssetResult> speech(const ProviderConfig& cfg, const AssetRequest& req, const ProviderRuntime& rt, const CancelFlag* cancel,
                           const std::string& key) {
    if (req.prompt.size() > kMaxSpeechChars) {
        return make_error("The text to speak has " + std::to_string(req.prompt.size()) + " characters; OpenAI speech takes at most " +
                              std::to_string(kMaxSpeechChars),
                          "Split it into several lines of dialogue and generate each one.");
    }
    const std::string model = req.model.empty() ? kSpeechModel : req.model;
    const std::string voice = req.voice.empty() ? kSpeechVoice : req.voice;
    HttpRequest hr;
    hr.url = trim_slashes(cfg.baseUrl) + "/audio/speech";
    hr.headers.emplace_back("Authorization", "Bearer " + key);
    hr.headers.emplace_back("Content-Type", "application/json");
    for (const auto& kv : cfg.headers) hr.headers.push_back(kv);
    hr.body = dump(Json::object({{"model", model},
                                 {"input", req.prompt},
                                 {"voice", voice},
                                 {"response_format", "mp3"}}));
    auto resp = asset_request(cfg, std::move(hr), rt, cancel);
    if (!resp) return resp.error();
    AssetResult out;
    out.bytes = std::move(resp->body);
    out.model = model;
    out.voice = voice;
    return out;
}

}  // namespace

Result<AssetResult> openai_asset(const ProviderConfig& cfg, const AssetRequest& req, const ProviderRuntime& rt, const CancelFlag* cancel) {
    auto key = asset_api_key(cfg, rt);
    if (!key) return key.error();
    return req.kind == MediaKind::Image ? image(cfg, req, rt, cancel, *key) : speech(cfg, req, rt, cancel, *key);
}

}  // namespace fa::ai
