// The asset providers behind generate_asset (private).
#pragma once

#include "fa/ai/assets.h"
#include "provider_util.h"

namespace fa::ai {

// The size OpenAI's image models draw at for `req` ("1024x1024", "1536x1024" or "1024x1536": the closest shape); the estimate of a
// picture is priced at this size, not at the size the file ends up.
const char* openai_image_size(const AssetRequest& req);

Result<AssetResult> openai_asset(const ProviderConfig& cfg, const AssetRequest& req, const ProviderRuntime& rt, const CancelFlag* cancel);
Result<AssetResult> elevenlabs_asset(const ProviderConfig& cfg, const AssetRequest& req, const ProviderRuntime& rt, const CancelFlag* cancel);
Result<AssetResult> meshy_asset(const ProviderConfig& cfg, const AssetRequest& req, const ProviderRuntime& rt, const CancelFlag* cancel);
Result<AssetResult> fake_asset(const AssetRequest& req);
Result<AssetResult> command_asset(const ProviderConfig& cfg, const AssetRequest& req, const CancelFlag* cancel);

// The key of `cfg` (apiKeyEnv, then the user config, then the conventional variable). An Error that says which variable to
// set when there is none; a server that needs no key (a local OpenAI-compatible one) gets an empty key.
Result<std::string> asset_api_key(const ProviderConfig& cfg, const ProviderRuntime& rt);

// One request of a provider, with the retries of the chat providers. A non-2xx answer is an Error with the provider's own
// message. Generation costs money, so a transient failure is retried twice at most.
Result<HttpResponse> asset_request(const ProviderConfig& cfg, HttpRequest request, const ProviderRuntime& rt, const CancelFlag* cancel);

}  // namespace fa::ai
