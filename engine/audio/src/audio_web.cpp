// Web: a browser starts an AudioContext suspended and lets it run only after the player did something on the page. sokol_audio
// already resumes it on the first click, touchend or keydown, but only once: a key that does not count as a user gesture (Tab,
// Escape...) or a pad button would use that one try up. This keeps trying on every pointer, touch and key event until the
// context really runs, then stops. The "stream running" line (audio.cpp) is logged by the first callback, which only comes
// once the context runs.
#include <emscripten.h>

namespace fa {

EM_JS(void, fa_web_audio_unlock_impl, (), {
    if (Module.faAudioUnlock) return;
    const events = ['pointerdown', 'pointerup', 'touchstart', 'touchend', 'click', 'keydown', 'keyup'];
    const unlock = () => {
        const ctx = Module._saudio_context;
        if (!ctx) return;
        if (ctx.state === 'running') {
            for (const e of events) document.removeEventListener(e, unlock, true);
            Module.faAudioUnlock = null;
            return;
        }
        ctx.resume().catch(() => {});
    };
    Module.faAudioUnlock = unlock;
    for (const e of events) document.addEventListener(e, unlock, true);
});

void audio_web_unlock() { fa_web_audio_unlock_impl(); }

}  // namespace fa
