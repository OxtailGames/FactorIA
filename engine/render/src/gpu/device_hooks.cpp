// Device hooks for vendor SDKs: the process registry and the helpers the backends share (gpu/device_hooks.h).
#include "gpu/device_hooks.h"

#include <algorithm>
#include <mutex>
#include <utility>

namespace fa::gpu {

namespace {

std::mutex& registry_mutex() {
    static std::mutex m;
    return m;
}

DeviceHooks& registry() {
    static DeviceHooks hooks;
    return hooks;
}

}  // namespace

void register_device_hook(std::shared_ptr<DeviceHook> hook) {
    if (!hook) return;
    std::lock_guard<std::mutex> lock(registry_mutex());
    auto& hooks = registry();
    for (const auto& h : hooks)
        if (h.get() == hook.get()) return;
    hooks.push_back(std::move(hook));
}

void unregister_device_hook(const DeviceHook* hook) {
    std::lock_guard<std::mutex> lock(registry_mutex());
    auto& hooks = registry();
    hooks.erase(std::remove_if(hooks.begin(), hooks.end(), [&](const auto& h) { return h.get() == hook; }),
                hooks.end());
}

DeviceHooks registered_device_hooks() {
    std::lock_guard<std::mutex> lock(registry_mutex());
    return registry();
}

DeviceHooks with_registered_hooks(const DeviceHooks& hooks) {
    DeviceHooks out;
    out.reserve(hooks.size());
    auto add = [&](const std::shared_ptr<DeviceHook>& h) {
        if (!h) return;
        for (const auto& o : out)
            if (o.get() == h.get()) return;
        out.push_back(h);
    };
    for (const auto& h : hooks) add(h);
    for (const auto& h : registered_device_hooks()) add(h);
    return out;
}

void mark_hooks_unsupported(const DeviceHooks& hooks, Backend backend) {
    for (const auto& h : hooks) {
        if (!h) continue;  // a live D3D12 or Vulkan device that uses it keeps its state (mark_unsupported_if_unused)
        h->mark_unsupported_if_unused(std::string("the ") + backend_name(backend) +
                                      " backend calls no device hooks: vendor SDKs that change how the device or the "
                                      "swapchain is made need the D3D12 or the Vulkan backend (render.backend in "
                                      "factoria.json)");
    }
}

DeviceHooks HookAttachment::attach(const DeviceHooks& hooks, Backend backend, std::vector<std::string>* refused) {
    release();
    for (const auto& h : hooks) {
        if (!h || std::find(hooks_.begin(), hooks_.end(), h) != hooks_.end()) continue;
        if (h->try_begin_use())
            hooks_.push_back(h);
        else if (refused)
            refused->push_back(device_hook_refused_warning(backend, *h));
    }
    return hooks_;
}

std::string device_hook_refused_warning(Backend backend, const DeviceHook& hook) {
    return std::string("gpu ") + backend_name(backend) + ": device hook '" + std::string(hook.name()) +
           "' is not used by this device: another live D3D12 or Vulkan device holds it, and a hook serves one device "
           "at a time (the device is made without it; destroy the other device first, or give this one its own hook)";
}

std::string device_hook_warning(Backend backend, const DeviceHook& hook) {
    return std::string("gpu ") + backend_name(backend) + ": device hook '" + std::string(hook.name()) +
           "' is unavailable: " + hook.unavailable_reason();
}

}  // namespace fa::gpu
