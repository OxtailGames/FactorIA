#include "transient_targets.h"

namespace fa::render {

TransientTargets::TransientTargets(gpu::Device& device)
    : device_(device),
      pool([this](const TransientDesc& d) { return create(d); }, [this](std::uint64_t h) { destroy(h); }) {}

std::uint64_t TransientTargets::create(const TransientDesc& d) {
    TargetDesc td;
    td.label = d.label.empty() ? "transient" : d.label.c_str();  // make_target copies it
    td.width = d.width;
    td.height = d.height;
    td.colorFormat = d.format.color;
    td.depthFormat = d.format.depth;
    td.samples = d.format.samples;
    Target t = make_target(device_, td);
    if (!t.valid(device_)) {  // the GPU refused it: nothing is kept, the caller sees 0
        destroy_target(device_, t);
        return 0;
    }
    const std::uint64_t h = next_++;
    targets_.emplace(h, t);
    return h;
}

void TransientTargets::destroy(std::uint64_t handle) {
    auto it = targets_.find(handle);
    if (it == targets_.end()) return;
    destroy_target(device_, it->second);
    targets_.erase(it);
}

const Target* TransientTargets::get(std::uint64_t handle) const {
    auto it = targets_.find(handle);
    return it == targets_.end() ? nullptr : &it->second;
}

}  // namespace fa::render
