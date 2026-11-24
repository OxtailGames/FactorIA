// GPU time of a frame and of each pass of its frame graph with timer queries (see GpuTimer in render_internal.h). Never blocks:
// a result that is not ready is read on a later frame. D3D11: timestamp queries inside a disjoint query (the frame's pair and
// one pair per pass). GLCORE: GL_TIME_ELAPSED for the frame and glQueryCounter(GL_TIMESTAMP) pairs for the passes (a
// GL_TIME_ELAPSED query cannot nest). Metal, GLES3 and WebGL2: not measured (reason() says why).
// What is measured is the span from the first command of the frame to the last one the GPU finishes, not the time the
// GPU was busy: a frame that waits for the CPU (a game limited by its scripts, a present that blocks) reads long here
// although the GPU idled.
#include "render_internal.h"

#include <array>
#include <deque>

#if defined(SOKOL_D3D11)
#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <d3d11.h>
#elif defined(SOKOL_GLCORE)
#define GL_GLEXT_PROTOTYPES 1
#include <GL/gl.h>
#include <GL/glext.h>
#endif

namespace fa::render {

#if defined(SOKOL_D3D11) || defined(SOKOL_GLCORE)
namespace {
constexpr int kRing = 6;  // queries in flight: results are a few frames late; a full ring skips the frame being timed
}
#endif

#if defined(SOKOL_D3D11)

struct GpuTimer::State {
    struct PassQuery {
        ID3D11Query* start = nullptr;
        ID3D11Query* end = nullptr;
    };
    struct Slot {
        ID3D11Query* disjoint = nullptr;
        ID3D11Query* start = nullptr;
        ID3D11Query* end = nullptr;
        std::vector<PassQuery> passQueries;  // made when a frame first needs them, then reused by the slot
        std::vector<std::string> names;      // names[i] is the pass of passQueries[i] in this slot's frame
        std::size_t used = 0;                // passes of the frame in flight in this slot
    };
    bool tried = false, ok = false;
    std::string why;
    std::array<Slot, kRing> slots{};
    std::deque<int> pending;  // slots with a result to read, oldest first
    int current = -1;
    int openPass = -1;  // index of the pass begun and not ended in the current slot
    std::size_t next = 0;
    std::vector<PassTime> lastPasses;
    std::size_t stale = 0;  // the next `stale` results to arrive are of frames timed before forget(): dropped
    void forget() {
        lastPasses.clear();
        stale = pending.size();
    }

    ID3D11Device* device() const { return static_cast<ID3D11Device*>(const_cast<void*>(sg_d3d11_device())); }
    ID3D11DeviceContext* context() const {
        return static_cast<ID3D11DeviceContext*>(const_cast<void*>(sg_d3d11_device_context()));
    }

    void init() {
        if (tried) return;
        ID3D11Device* dev = device();
        if (!dev || !context()) {
            why = "no D3D11 device yet";
            return;  // try again later
        }
        tried = true;
        D3D11_QUERY_DESC d{};
        for (Slot& s : slots) {
            d.Query = D3D11_QUERY_TIMESTAMP_DISJOINT;
            const bool a = SUCCEEDED(dev->CreateQuery(&d, &s.disjoint));
            d.Query = D3D11_QUERY_TIMESTAMP;
            const bool b = SUCCEEDED(dev->CreateQuery(&d, &s.start)) && SUCCEEDED(dev->CreateQuery(&d, &s.end));
            if (!a || !b) {
                why = "this D3D11 device cannot create timestamp queries";
                release();
                return;
            }
        }
        ok = true;
    }
    void release() {
        for (Slot& s : slots) {
            if (s.disjoint) s.disjoint->Release();
            if (s.start) s.start->Release();
            if (s.end) s.end->Release();
            for (PassQuery& q : s.passQueries) {
                if (q.start) q.start->Release();
                if (q.end) q.end->Release();
            }
            s = Slot{};
        }
    }
    // Makes the timestamp pair of pass `i` of a slot when it has none yet. False when the device refuses.
    bool ensure_pass_queries(Slot& s, std::size_t i) {
        if (i < s.passQueries.size()) return true;
        D3D11_QUERY_DESC d{};
        d.Query = D3D11_QUERY_TIMESTAMP;
        PassQuery q;
        if (FAILED(device()->CreateQuery(&d, &q.start)) || FAILED(device()->CreateQuery(&d, &q.end))) {
            if (q.start) q.start->Release();
            if (q.end) q.end->Release();
            return false;
        }
        s.passQueries.push_back(q);
        s.names.emplace_back();
        return true;
    }
    void begin() {
        init();
        current = -1;
        openPass = -1;
        if (!ok) return;
        if (pending.size() >= kRing) return;  // the oldest answer is still out: skip this frame
        const int i = int(next++ % kRing);  // answers come back in order, so the next slot in the ring is the free one
        current = i;
        slots[std::size_t(i)].used = 0;
        context()->Begin(slots[std::size_t(i)].disjoint);
        context()->End(slots[std::size_t(i)].start);
    }
    void begin_pass(const std::string& name) {
        if (!ok || current < 0) return;
        end_pass();
        Slot& s = slots[std::size_t(current)];
        if (s.used >= std::size_t(kMaxTimedPasses) || !ensure_pass_queries(s, s.used)) return;  // drawn, not measured
        s.names[s.used] = name;
        context()->End(s.passQueries[s.used].start);
        openPass = int(s.used);
        ++s.used;
    }
    void end_pass() {
        if (!ok || current < 0 || openPass < 0) return;
        Slot& s = slots[std::size_t(current)];
        context()->End(s.passQueries[std::size_t(openPass)].end);
        openPass = -1;
    }
    void end() {
        if (!ok || current < 0) return;
        end_pass();
        Slot& s = slots[std::size_t(current)];
        context()->End(s.end);
        context()->End(s.disjoint);
        // The results are read with D3D11_ASYNC_GETDATA_DONOTFLUSH: without a flush the queries sit in the command buffer until
        // something else submits it (a Present, which render.frame_graph's redraws and a capture never reach). Every
        // timed frame gets here: while the profiler or the dynamic resolution asks, one Flush per frame (a frame
        // nobody times pays nothing).
        context()->Flush();
        pending.push_back(current);
        current = -1;
    }
    void poll(std::vector<double>& out) {
        if (!ok) return;
        while (!pending.empty()) {
            Slot& s = slots[std::size_t(pending.front())];
            D3D11_QUERY_DATA_TIMESTAMP_DISJOINT dj{};
            if (context()->GetData(s.disjoint, &dj, sizeof(dj), D3D11_ASYNC_GETDATA_DONOTFLUSH) != S_OK)
                return;  // not yet: later
            UINT64 t0 = 0, t1 = 0;
            if (context()->GetData(s.start, &t0, sizeof(t0), D3D11_ASYNC_GETDATA_DONOTFLUSH) != S_OK) return;
            if (context()->GetData(s.end, &t1, sizeof(t1), D3D11_ASYNC_GETDATA_DONOTFLUSH) != S_OK) return;
            std::vector<PassTime> passes;
            passes.reserve(s.used);
            for (std::size_t i = 0; i < s.used; ++i) {
                UINT64 p0 = 0, p1 = 0;
                if (context()->GetData(s.passQueries[i].start, &p0, sizeof(p0), D3D11_ASYNC_GETDATA_DONOTFLUSH) != S_OK)
                    return;
                if (context()->GetData(s.passQueries[i].end, &p1, sizeof(p1), D3D11_ASYNC_GETDATA_DONOTFLUSH) != S_OK)
                    return;
                PassTime pt;
                pt.name = s.names[i];
                pt.ms = dj.Frequency > 0 && p1 >= p0 ? double(p1 - p0) * 1000.0 / double(dj.Frequency) : 0.0;
                passes.push_back(std::move(pt));
            }
            pending.pop_front();
            if (stale > 0) {
                --stale;
                continue;
            }
            if (!dj.Disjoint && dj.Frequency > 0 && t1 >= t0) {
                out.push_back(double(t1 - t0) * 1000.0 / double(dj.Frequency));
                lastPasses = std::move(passes);
            }
        }
    }
    ~State() { release(); }
};

#elif defined(SOKOL_GLCORE)

struct GpuTimer::State {
    struct PassQuery {
        GLuint start = 0;
        GLuint end = 0;
    };
    struct Slot {
        std::vector<PassQuery> passQueries;  // made when a frame first needs them, then reused by the slot
        std::vector<std::string> names;      // names[i] is the pass of passQueries[i] in this slot's frame
        std::size_t used = 0;                // passes of the frame in flight in this slot
    };
    bool tried = false, ok = false;
    std::string why;
    std::array<GLuint, kRing> ids{};
    std::array<Slot, kRing> slots{};
    std::deque<int> pending;
    int current = -1;
    int openPass = -1;  // index of the pass begun and not ended in the current slot
    std::size_t next = 0;
    std::vector<PassTime> lastPasses;
    std::size_t stale = 0;  // the next `stale` results to arrive are of frames timed before forget(): dropped
    void forget() {
        lastPasses.clear();
        stale = pending.size();
    }

    void init() {
        if (tried) return;
        tried = true;
        glGenQueries(kRing, ids.data());
        if (!ids[0] || glGetError() != GL_NO_ERROR) {
            why = "this OpenGL context has no timer queries (needs OpenGL 3.3 or ARB_timer_query)";
            return;
        }
        ok = true;
    }
    // Makes the timestamp pair of pass `i` of a slot when it has none yet. False when the context refuses.
    bool ensure_pass_queries(Slot& s, std::size_t i) {
        if (i < s.passQueries.size()) return true;
        GLuint two[2] = {0, 0};
        glGenQueries(2, two);
        if (!two[0] || !two[1]) return false;
        PassQuery q;
        q.start = two[0];
        q.end = two[1];
        s.passQueries.push_back(q);
        s.names.emplace_back();
        return true;
    }
    void begin() {
        init();
        current = -1;
        openPass = -1;
        if (!ok) return;
        if (pending.size() >= kRing) return;  // the oldest answer is still out: skip this frame
        const int i = int(next++ % kRing);  // answers come back in order, so the next slot in the ring is the free one
        current = i;
        slots[std::size_t(i)].used = 0;
        glBeginQuery(GL_TIME_ELAPSED, ids[std::size_t(i)]);
    }
    void begin_pass(const std::string& name) {
        if (!ok || current < 0) return;
        end_pass();
        Slot& s = slots[std::size_t(current)];
        if (s.used >= std::size_t(kMaxTimedPasses) || !ensure_pass_queries(s, s.used)) return;  // drawn, not measured
        s.names[s.used] = name;
        glQueryCounter(s.passQueries[s.used].start, GL_TIMESTAMP);
        openPass = int(s.used);
        ++s.used;
    }
    void end_pass() {
        if (!ok || current < 0 || openPass < 0) return;
        Slot& s = slots[std::size_t(current)];
        glQueryCounter(s.passQueries[std::size_t(openPass)].end, GL_TIMESTAMP);
        openPass = -1;
    }
    void end() {
        if (!ok || current < 0) return;
        end_pass();
        glEndQuery(GL_TIME_ELAPSED);
        pending.push_back(current);
        current = -1;
    }
    static bool available(GLuint id) {
        GLint ready = 0;
        glGetQueryObjectiv(id, GL_QUERY_RESULT_AVAILABLE, &ready);
        return ready != 0;
    }
    void poll(std::vector<double>& out) {
        if (!ok) return;
        while (!pending.empty()) {
            const std::size_t slotIndex = std::size_t(pending.front());
            const GLuint id = ids[slotIndex];
            if (!available(id)) return;
            Slot& s = slots[slotIndex];
            // The pass timestamps were issued before the frame's query ended, but check each one: never block.
            for (std::size_t i = 0; i < s.used; ++i) {
                if (!available(s.passQueries[i].start) || !available(s.passQueries[i].end)) return;
            }
            GLuint64 ns = 0;
            glGetQueryObjectui64v(id, GL_QUERY_RESULT, &ns);
            std::vector<PassTime> passes;
            passes.reserve(s.used);
            for (std::size_t i = 0; i < s.used; ++i) {
                GLuint64 a = 0, b = 0;
                glGetQueryObjectui64v(s.passQueries[i].start, GL_QUERY_RESULT, &a);
                glGetQueryObjectui64v(s.passQueries[i].end, GL_QUERY_RESULT, &b);
                PassTime pt;
                pt.name = s.names[i];
                pt.ms = b >= a ? double(b - a) * 1e-6 : 0.0;
                passes.push_back(std::move(pt));
            }
            pending.pop_front();
            if (stale > 0) {
                --stale;
                continue;
            }
            out.push_back(double(ns) * 1e-6);
            lastPasses = std::move(passes);
        }
    }
    // The query ids are not deleted: the GL context may be gone by the time the renderer is (destroying the context frees them).
};

#else

struct GpuTimer::State {
    bool ok = false;
    void init() {}
    std::string why =
#if defined(SOKOL_METAL)
        "no GPU timer on Metal: sokol_gfx does not expose the command buffer's GPU times"
#elif defined(SOKOL_GLES3)
        "no GPU timer on GLES3/WebGL2: timer queries need EXT_disjoint_timer_query, which the engine does not use"
#else
        "no GPU timer on this graphics backend"
#endif
        ;
    std::vector<PassTime> lastPasses;  // always empty
    void forget() {}
    void begin() {}
    void end() {}
    void begin_pass(const std::string&) {}
    void end_pass() {}
    void poll(std::vector<double>&) {}
};

#endif

GpuTimer::GpuTimer() : s_(std::make_unique<State>()) {}
GpuTimer::~GpuTimer() = default;

bool GpuTimer::supported() const {
    s_->init();
    return s_->ok;
}

std::string GpuTimer::reason() const { return s_->why; }
void GpuTimer::begin() { s_->begin(); }
void GpuTimer::end() { s_->end(); }
void GpuTimer::begin_pass(const std::string& name) { s_->begin_pass(name); }
void GpuTimer::end_pass() { s_->end_pass(); }
void GpuTimer::forget() { s_->forget(); }
void GpuTimer::poll(std::vector<double>& out) { s_->poll(out); }
const std::vector<GpuTimer::PassTime>& GpuTimer::last_passes() const { return s_->lastPasses; }

}  // namespace fa::render
