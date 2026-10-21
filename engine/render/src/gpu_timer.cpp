// GPU frame time with timer queries (see GpuTimer in render_internal.h). Never blocks: a result that is not ready is read on
// a later frame. D3D11: timestamp queries inside a disjoint query. GLCORE: GL_TIME_ELAPSED. Metal, GLES3 and WebGL2: not
// measured (reason() says why).
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

namespace {
constexpr int kRing = 6;  // queries in flight: results are a few frames late; a full ring skips the frame being timed
}

#if defined(SOKOL_D3D11)

struct GpuTimer::State {
    struct Slot {
        ID3D11Query* disjoint = nullptr;
        ID3D11Query* start = nullptr;
        ID3D11Query* end = nullptr;
    };
    bool tried = false, ok = false;
    std::string why;
    std::array<Slot, kRing> slots{};
    std::deque<int> pending;  // slots with a result to read, oldest first
    int current = -1;
    std::size_t next = 0;

    ID3D11Device* device() const { return static_cast<ID3D11Device*>(const_cast<void*>(sg_d3d11_device())); }
    ID3D11DeviceContext* context() const { return static_cast<ID3D11DeviceContext*>(const_cast<void*>(sg_d3d11_device_context())); }

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
            s = Slot{};
        }
    }
    void begin() {
        init();
        current = -1;
        if (!ok) return;
        if (pending.size() >= kRing) return;  // the oldest answer is still out: skip this frame
        const int i = int(next++ % kRing);  // answers come back in order, so the next slot in the ring is the free one
        current = i;
        context()->Begin(slots[std::size_t(i)].disjoint);
        context()->End(slots[std::size_t(i)].start);
    }
    void end() {
        if (!ok || current < 0) return;
        Slot& s = slots[std::size_t(current)];
        context()->End(s.end);
        context()->End(s.disjoint);
        pending.push_back(current);
        current = -1;
    }
    void poll(std::vector<double>& out) {
        if (!ok) return;
        while (!pending.empty()) {
            Slot& s = slots[std::size_t(pending.front())];
            D3D11_QUERY_DATA_TIMESTAMP_DISJOINT dj{};
            if (context()->GetData(s.disjoint, &dj, sizeof(dj), D3D11_ASYNC_GETDATA_DONOTFLUSH) != S_OK) return;  // not yet: later
            UINT64 t0 = 0, t1 = 0;
            if (context()->GetData(s.start, &t0, sizeof(t0), D3D11_ASYNC_GETDATA_DONOTFLUSH) != S_OK) return;
            if (context()->GetData(s.end, &t1, sizeof(t1), D3D11_ASYNC_GETDATA_DONOTFLUSH) != S_OK) return;
            pending.pop_front();
            if (!dj.Disjoint && dj.Frequency > 0 && t1 >= t0) out.push_back(double(t1 - t0) * 1000.0 / double(dj.Frequency));
        }
    }
    ~State() { release(); }
};

#elif defined(SOKOL_GLCORE)

struct GpuTimer::State {
    bool tried = false, ok = false;
    std::string why;
    std::array<GLuint, kRing> ids{};
    std::deque<int> pending;
    int current = -1;
    std::size_t next = 0;

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
    void begin() {
        init();
        current = -1;
        if (!ok) return;
        if (pending.size() >= kRing) return;  // the oldest answer is still out: skip this frame
        const int i = int(next++ % kRing);  // answers come back in order, so the next slot in the ring is the free one
        current = i;
        glBeginQuery(GL_TIME_ELAPSED, ids[std::size_t(i)]);
    }
    void end() {
        if (!ok || current < 0) return;
        glEndQuery(GL_TIME_ELAPSED);
        pending.push_back(current);
        current = -1;
    }
    void poll(std::vector<double>& out) {
        if (!ok) return;
        while (!pending.empty()) {
            const GLuint id = ids[std::size_t(pending.front())];
            GLint ready = 0;
            glGetQueryObjectiv(id, GL_QUERY_RESULT_AVAILABLE, &ready);
            if (!ready) return;
            GLuint64 ns = 0;
            glGetQueryObjectui64v(id, GL_QUERY_RESULT, &ns);
            pending.pop_front();
            out.push_back(double(ns) * 1e-6);
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
    void begin() {}
    void end() {}
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
void GpuTimer::poll(std::vector<double>& out) { s_->poll(out); }

}  // namespace fa::render
