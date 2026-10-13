// Shared by the API providers (private).
#pragma once

#include "fa/ai/provider.h"

namespace fa::ai {

// Sends with retries on 429/5xx/529/overloaded/transport errors, honouring
// Retry-After and exponential backoff. Returns the last response.
HttpResponse send_with_retry(const ProviderRuntime& rt, HttpRequest request, int maxRetries, const CancelFlag* cancel,
                             const std::function<void(const std::string&)>& onRetry = {});

bool is_retryable_status(int status);

// "Anthropic API error 400 (invalid_request_error): message" from an error body.
std::string describe_http_error(std::string_view provider, const HttpResponse& resp);
// Teaching hint for common statuses.
std::string http_error_hint(std::string_view provider, int status);

// Default cancel-aware sleep.
void default_sleep(double seconds, const CancelFlag* cancel);

}  // namespace fa::ai
