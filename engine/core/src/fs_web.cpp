// Web: the save folder (user_dir()) lives in the browser's IndexedDB through Emscripten's IDBFS.
//
// The file system the C++ code sees is in memory (MEMFS). restore_user_dir() mounts IDBFS on the save folder and copies what
// the last visit saved into memory (FS.syncfs(true)) before the game starts. Everything the game writes there afterwards
// stays in memory until user_dir_changed() copies it back (FS.syncfs(false)): a write schedules one copy half a second
// later, writes in between join it, a copy that is still running gets one more after it, and flush_user_dir() copies at
// once. The web player calls that after the suspend, resume and quit handlers have run (the tab hiding or closing; see
// app.cpp), so a save made inside a handler is in the copy. Only the save folder is persistent: nothing else in the file
// system is.
#include <emscripten.h>

#include "fa/core/fs.h"
#include "fa/core/log.h"

EM_JS(void, fa_web_idbfs_mount, (const char* path), {
    const dir = UTF8ToString(path);
    const state = Module.faSave = { dir: dir, timer: 0, running: false, again: false, ok: false, dirty: false };
    const done = () => Module._fa_web_save_restored();
    try {
        FS.mkdirTree(dir);
        FS.mount(IDBFS, {}, dir);
    } catch (e) {
        console.warn('factoria: saving in the browser is not available (' + e + '); saves last until this tab closes');
        done();
        return;
    }
    const flush = () => {
        state.timer = 0;
        state.dirty = false;
        if (state.running) { state.again = true; return; }
        state.running = true;
        FS.syncfs(false, (err) => {
            state.running = false;
            if (err) console.warn('factoria: could not store the save in the browser: ' + err);
            if (state.again) { state.again = false; if (state.urgent) { state.urgent = false; flush(); } else state.timer = setTimeout(flush, 500); }
        });
    };
    state.flush = flush;
    state.schedule = () => { state.dirty = true; if (state.ok && !state.timer) state.timer = setTimeout(flush, 500); };
    state.now = () => { if (state.ok && state.dirty) { if (state.timer) clearTimeout(state.timer); state.urgent = state.running; flush(); } };
    FS.syncfs(true, (err) => {
        if (err) console.warn('factoria: could not load the saved game from the browser: ' + err + ' (starting without it)');
        else state.ok = true;
        done();
    });
});

EM_JS(void, fa_web_idbfs_changed, (), {
    if (Module.faSave) Module.faSave.schedule();
});

EM_JS(void, fa_web_idbfs_flush_now, (), {
    if (Module.faSave) Module.faSave.now();
});

namespace {
void (*g_done)() = nullptr;
}

// Called by the page code above (Module._fa_web_save_restored) when the saved files are in memory.
extern "C" EMSCRIPTEN_KEEPALIVE void fa_web_save_restored() {
    if (g_done) g_done();
}

namespace fa::fs {

void user_dir_changed() { fa_web_idbfs_changed(); }

void flush_user_dir() { fa_web_idbfs_flush_now(); }

void restore_user_dir(const std::filesystem::path& dir, void (*done)()) {
    g_done = done;
    fa_web_idbfs_mount(dir.generic_string().c_str());
}

}  // namespace fa::fs
