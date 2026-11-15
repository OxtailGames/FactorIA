// Private: a pool of render targets, keyed by (width, height, TargetFormat), that lives across frames.
//
// The pool never touches the GPU: the code that owns it gives two callbacks, `create` (makes a target, returns an
// opaque non-zero handle) and `destroy`. Tests give counters instead, so the pool and the FrameGraph that uses it are
// tested without a GPU. A target released at the end of a pass can be acquired again by a later pass of the same frame
// (transients whose lifetimes do not overlap share one), and by the next frame; one nobody acquires for more than
// `maxIdleFrames` whole frames is destroyed at the start of a frame (begin_frame).
#pragma once

#include <cstdint>
#include <functional>
#include <string>
#include <vector>

#include "gpu_types.h"

namespace fa::render {

// What a transient target is: its size and formats. `label` names it in dumps and in error messages; it is not part
// of the pool key (two targets with another label but the same size and formats are interchangeable).
struct TransientDesc {
    int width = 0;
    int height = 0;
    TargetFormat format{};
    std::string label;

    // The pool key: the size and formats, never the label.
    bool same_shape(const TransientDesc& o) const {
        return width == o.width && height == o.height && format == o.format;
    }
};

struct TargetPoolStats {
    int live = 0;       // targets that exist now (in use + free)
    int inUse = 0;      // acquired and not released yet
    int created = 0;    // `create` calls since the pool was made
    int reused = 0;     // acquires answered by a free target
    int destroyed = 0;  // `destroy` calls (evictions and the destructor)
};

class TargetPool {
public:
    using CreateFn = std::function<std::uint64_t(const TransientDesc&)>;
    using DestroyFn = std::function<void(std::uint64_t)>;

    // `maxIdleFrames`: whole frames a free target may stay unused before begin_frame destroys it (>= 0).
    TargetPool(CreateFn create, DestroyFn destroy, int maxIdleFrames = 4);
    ~TargetPool();  // destroys every target, in use or not
    TargetPool(const TargetPool&) = delete;
    TargetPool& operator=(const TargetPool&) = delete;

    // A free target of the same shape (reused) or a new one (created). Returns 0 when `create` returned 0.
    std::uint64_t acquire(const TransientDesc& desc);
    // Gives a target back. A handle the pool does not know, or one already free, is ignored.
    void release(std::uint64_t handle);

    // Starts the next frame and destroys the free targets unused for more than maxIdleFrames whole frames.
    void begin_frame();
    // Destroys every free target now (a resize, a lost device).
    void clear_free();

    TargetPoolStats stats() const;
    int frame() const { return frame_; }

private:
    struct Entry {
        std::uint64_t handle = 0;
        TransientDesc desc;
        bool inUse = false;
        int lastUsedFrame = 0;
    };
    CreateFn create_;
    DestroyFn destroy_;
    int maxIdle_;
    int frame_ = 0;
    std::vector<Entry> entries_;
    TargetPoolStats counters_;
};

}  // namespace fa::render
