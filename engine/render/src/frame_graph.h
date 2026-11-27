// Private: the CPU core of the renderer's frame graph (no GPU, no sokol calls; tested without a device).
//
// A frame is declared as data: resources (imported ones the renderer owns, like the game target or the swapchain, and
// transient ones the graph may create) and passes that read and write them. compile() then
//   * orders the passes by their dependencies, and where there are none keeps the declaration order (the same
//     declaration always gives the same order);
//   * drops (culls) the passes whose outputs nobody reads, keeping the ones with side effects;
//   * finds the first and last pass that use each transient and groups the transients whose lifetimes do not overlap
//     (and that have the same size and formats) in alias slots: one physical target serves a whole slot;
//   * reports a graph that cannot run (a cycle, a transient read before anything writes it, a name that does not
//     exist) as an Error that names the passes and the resource and says what to change. A graph whose cycle policy is
//     CyclePolicy::Break (the renderer's order of the render-target jobs) does not fail on a cycle: see below.
// execute() runs the live passes in order with their physical targets (transients come from a TargetPool and go back
// to it after their last pass) and records each pass's CPU time. to_json() describes the compiled graph.
//
// Dependencies, from declaration order (a later pass sees what the earlier ones wrote):
//   read after write   a pass that reads R runs after the last pass declared before it that writes R;
//   write after write  a pass that writes R runs after the previous pass that writes R (HUD over the game image);
//   write after read   a pass that writes R runs after the passes declared before it that read R;
//   after(name)        an explicit order, by pass name, for the rest (the name may be declared later).
// Reading a transient that no earlier pass writes is an error (its contents would be garbage); an imported resource
// can be read without a writer (it already has contents).
//
// Cycles: with CyclePolicy::Error (the default) a cycle makes compile() fail. With CyclePolicy::Break, when no pass is
// ready and some are left, the one declared first goes next as if its unmet dependencies were met (it uses what the
// resource held before the frame: "the other's picture of the last frame"), and the break is recorded in
// cycle_breaks() and to_json(). Nothing depends on the CPU or on hash order: the same declaration breaks the same way.
//
// Culling: a pass is live when it has side effects, or writes an imported resource (the world sees it), or writes
// something a live pass reads. Culled passes do not run and their transients are never created.
//
// The contents of a transient are UNDEFINED at the start of the first pass that writes it: the pool hands out a target
// another pass (or another frame) drew into. So the first writer of a transient must CLEAR it, or DONTCARE it and
// draw every pixel; it must never LOAD. Later writers of the same transient may LOAD (they continue its picture).
// An imported resource keeps what the renderer put in it, so its passes load or clear as they need.
#pragma once

#include <cstdint>
#include <functional>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"
#include "target_pool.h"

namespace fa::gpu {
class CommandList;
}  // namespace fa::gpu

namespace fa::render {

struct ResourceId {
    std::uint32_t index = 0xffffffffu;
    bool valid() const { return index != 0xffffffffu; }
    bool operator==(const ResourceId& o) const { return index == o.index; }
};

class PassContext;

enum class CyclePolicy { Error, Break };

// A pass that went first although it waits for passes that wait for it (CyclePolicy::Break): `waitedFor` are the
// passes it did not wait for, in declaration order.
struct CycleBreak {
    std::string pass;
    std::vector<std::string> waitedFor;
};

// One pass as declared.
struct GraphPass {
    std::string name;                // unique; shown in errors, stats and dumps
    std::vector<ResourceId> reads;   // resources the pass samples or loads
    std::vector<ResourceId> writes;  // resources the pass draws into
    std::vector<std::string> after;  // passes (by name) that must run before this one, besides the data dependencies
    bool sideEffect = false;         // present, readback, ...: never culled
    std::function<void(const PassContext&)> execute;
};

struct PassStats {
    std::string name;
    double cpuMs = 0.0;  // wall time of the execute callback (profiling only, never used by the simulation)
    bool culled = false;
};

// Called around the callback of every pass execute() runs (not for a pass without callback, nor a culled one): `begin` right
// before it, `end` right after it with its CPU time in milliseconds, also when the callback throws. The renderer uses them to
// place GPU timestamps and to feed the profiler; they must not touch the graph. Empty functions are skipped.
struct PassHooks {
    // Before `begin`, with the physical handle of every resource the pass declared (its reads, then its writes; 0 for none): the
    // renderer makes the graphics queue wait there for the async compute work that still holds one of them (Gpu::wait_compute_for).
    std::function<void(const std::vector<std::uint64_t>& handles)> before;
    std::function<void(const std::string& pass)> begin;
    std::function<void(const std::string& pass, double cpuMs)> end;
};

class FrameGraph {
public:
    // A resource the renderer owns (the game target, the swapchain, an image of a render-target asset). `handle` is
    // opaque to the graph and given back by PassContext::handle (compile() rejects a handle of 0). `desc` only describes
    // it in dumps.
    ResourceId import_target(const std::string& name, std::uint64_t handle, const TransientDesc& desc = {});
    // Points an imported resource at another target (the game target of another view, a resized light buffer) without
    // rebuilding the graph: the next execute() gives the new handle to the passes. `desc` (when given) replaces the
    // size and formats shown in dumps (the renderer uses it to point the image slots of render targets at their current
    // targets). The compiled plan stays valid (the handle is not part of it). False, and
    // nothing changes, when `r` is not an imported resource of this graph.
    bool set_import_handle(ResourceId r, std::uint64_t handle, const TransientDesc* desc = nullptr);
    // A target that exists only inside the frame, made by the pool when its first pass starts.
    ResourceId create_transient(const TransientDesc& desc);

    // Adds a pass; passes run in declaration order unless a dependency says otherwise. Returns its index.
    int add_pass(GraphPass pass);
    // Adds `before` to the `after` list of the declared pass named `pass` (for an order only known once later passes are declared: a pass that must run
    // after a pass the renderer declares further on). The name `before` must be declared by compile(). False when no pass has that name.
    bool add_after(const std::string& pass, const std::string& before);

    // What compile() does with a cycle (see "Cycles" above); Error until set.
    void set_cycle_policy(CyclePolicy policy) { cyclePolicy_ = policy; }
    // Orders, culls and plans the targets. Call again after changing the declaration. Fails, naming the resource, for a
    // transient with a width or height <= 0, an imported resource with handle 0 and two resources with the same name;
    // `order` and `aliasSlots` of to_json() are empty while the graph is not compiled.
    Result<void> compile();
    bool compiled() const { return compiled_; }

    // Runs the live passes in order. Transients come from `pool` (acquired at their first pass, released after
    // their last one; whatever the way out, a failure or a pass that throws, none stays acquired). Fails when
    // compile() has not succeeded. `commands` is the command list the passes record on (PassContext::commands(): the
    // renderer's frame list, Gpu::commands()); null in the CPU-only tests.
    Result<void> execute(TargetPool& pool, gpu::CommandList* commands = nullptr);
    // The same, with the address of the list pointer instead of the list: PassContext::commands() reads `*current` each time, so
    // a pass that ends the list and begins another (the renderer's parallel shadow recording and async compute,
    // Gpu::commands_slot) leaves the passes after it the new list. Null = no list.
    Result<void> execute_on(TargetPool& pool, gpu::CommandList* const* current);

    // The functions execute() calls around each pass callback; kept by clear() and release_callbacks().
    void set_pass_hooks(PassHooks hooks) { hooks_ = std::move(hooks); }

    // The cycles the last compile() broke (CyclePolicy::Break), in the order they were broken.
    const std::vector<CycleBreak>& cycle_breaks() const { return breaks_; }

    // Per pass of the last execute(): the executed ones in order, then the culled ones.
    const std::vector<PassStats>& stats() const { return stats_; }

    // How many times an `end` hook threw during the last execute() (0 after clear()): the sample of that pass was lost,
    // the frame was not. Like the rest of the graph, read on the render thread only.
    int hook_failures() const { return hookFailures_; }

    // Names of the live passes in execution order, and of the culled ones (empty before compile()).
    std::vector<std::string> order_names() const;
    std::vector<std::string> culled_names() const;
    // Number of alias slots = the physical targets one frame needs for its transients.
    int alias_slot_count() const { return int(slotCount_); }
    // The alias slot of a transient used by a live pass, else -1.
    int alias_slot(ResourceId r) const;

    // The compiled graph for tools and AIs: resources (kind, size, formats, first/last use, alias slot), passes
    // (reads, writes, after, side effect, culled, position), order and alias slots.
    Json to_json() const;

    void clear();  // forget every resource and pass
    // Forgets what the pass callbacks captured and keeps the declaration, the compiled plan and the stats (what to_json,
    // order_names and stats show): the renderer calls it after execute(), because the callbacks hold references to
    // state of the frame that is gone by then. execute() fails after it until the passes are declared again.
    void release_callbacks();

private:
    friend class PassContext;
    struct Resource {
        std::string name;
        bool imported = false;
        std::uint64_t handle = 0;
        TransientDesc desc;
        int firstUse = -1;  // position in `order_` of the first live pass using it (transients only)
        int lastUse = -1;
        int slot = -1;
    };
    struct Edge {
        int from = 0;
        bool data = false;  // true: keeps `from` alive when the later pass is live
    };

    const std::string& resource_name(ResourceId r) const;

    std::vector<Resource> resources_;
    std::vector<GraphPass> passes_;
    std::vector<bool> culled_;
    std::vector<int> order_;  // live passes in execution order (indices into passes_)
    std::size_t slotCount_ = 0;
    bool compiled_ = false;
    CyclePolicy cyclePolicy_ = CyclePolicy::Error;
    std::vector<CycleBreak> breaks_;
    bool released_ = false;  // release_callbacks() ran: the passes cannot execute
    std::vector<PassStats> stats_;
    PassHooks hooks_;
    int hookFailures_ = 0;                        // `end` hooks that threw in the last execute()
    std::vector<std::uint64_t> hookHandles_;      // what the `before` hook is given (kept: no allocation per pass)
    std::vector<std::uint64_t> physical_;         // per resource, valid while execute() runs
    gpu::CommandList* commands_ = nullptr;        // execute()'s `commands`, while it runs
    gpu::CommandList* const* current_ = nullptr;  // where PassContext::commands() reads the list, while execute runs
};

// What a pass's callback sees: the physical target of each resource it declared.
class PassContext {
public:
    PassContext(const FrameGraph& g, const std::vector<std::uint64_t>& physical, const GraphPass& pass)
        : graph_(g), physical_(physical), pass_(pass) {}
    // The handle of an imported resource, or of the pool's target for a transient; 0 for a resource the pass did not
    // declare in `reads` or `writes` (a transient it does not use is not held for it, and an imported one is not its
    // business), and for an unknown one.
    std::uint64_t handle(ResourceId r) const {
        if (!r.valid() || r.index >= physical_.size()) return 0;
        for (const std::vector<ResourceId>* list : {&pass_.reads, &pass_.writes}) {
            for (ResourceId d : *list) {
                if (d == r) return physical_[r.index];
            }
        }
        return 0;
    }
    // The size and formats the resource was declared with.
    const TransientDesc& desc(ResourceId r) const { return graph_.resources_[r.index].desc; }
    const std::string& pass_name() const { return pass_.name; }
    // The command list the pass records on (FrameGraph::execute's `commands`): null when the graph runs without one
    // (the CPU-only tests). Ask for it in the callback each frame: it is valid only while the pass runs (a list is
    // invalid after its submit, gpu/device.h, LIFETIME).
    gpu::CommandList* commands() const { return graph_.current_ ? *graph_.current_ : nullptr; }

private:
    const FrameGraph& graph_;
    const std::vector<std::uint64_t>& physical_;
    const GraphPass& pass_;
};

}  // namespace fa::render
