// Private: the render targets of the frame graph's transients. A TargetPool whose handles are the keys of a table of
// Target (render_internal.h): the pool makes a target with make_target when a pass of the graph needs one nobody has
// released, keeps it for the next frames and destroys it when it stays unused (TargetPool::begin_frame). One per
// Renderer; it must be destroyed while the graphics context is open (Renderer::shutdown does).
#pragma once

#include <cstdint>
#include <unordered_map>

#include "render_internal.h"
#include "target_pool.h"

namespace fa::render {

class TransientTargets {
    // Declared before `pool`: the pool's destructor destroys its targets through destroy(), which needs the table.
    std::unordered_map<std::uint64_t, Target> targets_;
    std::uint64_t next_ = 1;
    gpu::Device& device_;

public:
    // `device` makes and destroys the targets: it must outlive the pool (Renderer::shutdown destroys the pool first).
    explicit TransientTargets(gpu::Device& device);
    TransientTargets(const TransientTargets&) = delete;
    TransientTargets& operator=(const TransientTargets&) = delete;

    TargetPool pool;

    // The target behind a handle the pool gave out; null for 0 or a handle that was destroyed.
    const Target* get(std::uint64_t handle) const;

private:
    std::uint64_t create(const TransientDesc& d);
    void destroy(std::uint64_t handle);
};

}  // namespace fa::render
