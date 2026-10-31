// Web audio output. sokol_audio drives a ScriptProcessorNode here, which browsers deprecate (a console warning on every start)
// and which mixes on the main thread inside a callback that has to be on time. This is the web's own device, in engine code
// (external/ is not edited): an AudioWorkletNode whose processor only plays queued sample chunks, fed from the main thread by
// messages. The player has no pthreads and no SharedArrayBuffer (a page without COOP/COEP), so Emscripten's AUDIO_WORKLET
// (which runs wasm inside the worklet) is out. The worklet asks for more when its queue falls below a target, the main thread
// mixes that many frames with the same callback every other platform uses and posts them back (the buffer is transferred, not
// copied). Without AudioWorklet (or if its module fails to load) a ScriptProcessorNode pulls from the same function.
//
// A browser also starts an AudioContext suspended and lets it run only after the player did something on the page. A key that
// does not count as a user gesture (Tab, Escape...) or a pad button must not use up the one try, so the unlock listens to every
// pointer, touch and key event until the context really runs, then stops. The "stream running" line (audio.cpp) is logged by the
// first callback, which only comes once the context runs.
#include <emscripten.h>

#include <vector>

#include "audio_web.h"

namespace {
fa::WebAudioCallback g_callback = nullptr;
void* g_user = nullptr;
int g_channels = 2;
std::vector<float> g_buffer;
}  // namespace

extern "C" EMSCRIPTEN_KEEPALIVE float* fa_web_audio_pull(int frames) {
    if (!g_callback || frames <= 0 || frames > 65536) return nullptr;
    g_buffer.assign(std::size_t(frames) * std::size_t(g_channels), 0.0f);
    g_callback(g_buffer.data(), frames, g_channels, g_user);
    return g_buffer.data();
}

// Opens the context and the node. Returns the context's sample rate, or 0 without WebAudio.
EM_JS(int, fa_web_audio_open_impl, (int rate, int channels, int chunk, int target), {
    if (typeof AudioContext === 'undefined') {
        console.log('factoria audio: no WebAudio support');
        return 0;
    }
    const ctx = new AudioContext({sampleRate: rate, latencyHint: 'interactive'});
    Module._saudio_context = ctx;  // the unlock below (and the tooling that looks for it) uses this name
    const info = {backend: 'pending', rate: ctx.sampleRate, channels: channels, chunk: chunk, target: target,
                  baseLatency: ctx.baseLatency || 0, underruns: 0, pulls: 0, framesPulled: 0};
    Module.faAudio = info;
    globalThis.FactoriaAudio = info;  // for the browser console and test tooling: backend, latency, underruns
    let node = null;

    const pull = (frames) => {
        const ptr = _fa_web_audio_pull(frames);
        if (!ptr) return null;
        info.pulls++;
        info.framesPulled += frames;
        return HEAPF32.slice(ptr >> 2, (ptr >> 2) + frames * channels);  // a copy: the wasm buffer is reused
    };

    const useScriptProcessor = (why) => {
        if (Module._saudio_context !== ctx) return;
        info.backend = 'ScriptProcessorNode';
        const size = 2048;
        node = ctx.createScriptProcessor(size, 0, channels);
        info.scriptBufferFrames = size;
        node.onaudioprocess = (event) => {
            const frames = event.outputBuffer.length;
            const data = pull(frames);
            if (!data) return;
            const n = event.outputBuffer.numberOfChannels;
            for (let c = 0; c < n; c++) {
                const dst = event.outputBuffer.getChannelData(c);
                for (let i = 0; i < frames; i++) dst[i] = data[i * channels + Math.min(c, channels - 1)];
            }
        };
        node.connect(ctx.destination);
        console.log('factoria audio: ScriptProcessorNode (' + why + '), ' + ctx.sampleRate + ' Hz');
    };

    const workletSource = `
        class FactoriaOut extends AudioWorkletProcessor {
            constructor(options) {
                super();
                const o = options.processorOptions;
                this.channels = o.channels;
                this.target = o.target;
                this.queue = [];
                this.offset = 0;
                this.queued = 0;
                this.pending = false;
                this.underruns = 0;
                this.port.onmessage = (e) => {
                    this.queue.push(e.data);
                    this.queued += e.data.length / this.channels;
                    this.pending = false;
                };
                this.request();
            }
            request() {
                if (this.pending) return;
                this.pending = true;
                this.port.postMessage({need: Math.max(this.target - this.queued, 1), underruns: this.underruns});
            }
            process(inputs, outputs) {
                const out = outputs[0];
                const n = out[0].length;
                const ch = this.channels;
                let w = 0;
                while (w < n && this.queue.length) {
                    const chunk = this.queue[0];
                    const have = chunk.length / ch - this.offset;
                    const take = Math.min(have, n - w);
                    for (let c = 0; c < out.length; c++) {
                        const dst = out[c], cc = Math.min(c, ch - 1);
                        for (let i = 0; i < take; i++) dst[w + i] = chunk[(this.offset + i) * ch + cc];
                    }
                    w += take;
                    this.offset += take;
                    this.queued -= take;
                    if (this.offset >= chunk.length / ch) { this.queue.shift(); this.offset = 0; }
                }
                if (w < n) {
                    for (let c = 0; c < out.length; c++) out[c].fill(0, w);
                    this.underruns++;
                }
                if (this.queued < this.target) this.request();
                return true;
            }
        }
        registerProcessor('factoria-out', FactoriaOut);`;

    if (typeof AudioWorkletNode === 'undefined' || !ctx.audioWorklet) {
        useScriptProcessor('no AudioWorklet');
    } else {
        const url = URL.createObjectURL(new Blob([workletSource], {type: 'text/javascript'}));
        ctx.audioWorklet.addModule(url).then(() => {
            URL.revokeObjectURL(url);
            if (Module._saudio_context !== ctx) return;  // closed while loading
            node = new AudioWorkletNode(ctx, 'factoria-out', {
                numberOfInputs: 0, numberOfOutputs: 1, outputChannelCount: [channels],
                processorOptions: {channels: channels, target: target}});
            node.port.onmessage = (e) => {
                const need = e.data.need | 0;
                const under = e.data.underruns | 0;
                if (under > info.underruns && performance.now() - (info.lastWarn || -1e9) > 1000) {
                    info.lastWarn = performance.now();
                    console.warn('factoria audio: underrun (' + under + ' so far): the main thread was too busy to feed the worklet in time');
                }
                info.underruns = under;
                info.outputLatency = ctx.outputLatency || 0;
                const frames = Math.min(Math.max(Math.ceil(need / chunk), 1), 16) * chunk;
                const data = pull(frames);
                if (data) node.port.postMessage(data, [data.buffer]);
            };
            node.onprocessorerror = () => console.warn('factoria audio: the worklet processor failed');
            node.connect(ctx.destination);
            info.backend = 'AudioWorkletNode';
            console.log('factoria audio: AudioWorkletNode, ' + ctx.sampleRate + ' Hz, chunks of ' + chunk + ' frames, queue target '
                        + target + ' frames, base latency ' + (info.baseLatency * 1000).toFixed(1) + ' ms');
        }).catch((err) => {
            URL.revokeObjectURL(url);
            console.warn('factoria audio: the AudioWorklet module did not load (' + err + ')');
            useScriptProcessor('worklet failed');
        });
    }

    const resume = () => {
        if (Module._saudio_context === ctx && (ctx.state === 'suspended' || ctx.state === 'interrupted')) ctx.resume().catch(() => {});
    };
    ctx.onstatechange = resume;
    Module.faAudioVisibility = () => { if (document.visibilityState === 'visible') resume(); };
    document.addEventListener('visibilitychange', Module.faAudioVisibility);
    Module.faAudioClose = () => {
        document.removeEventListener('visibilitychange', Module.faAudioVisibility);
        ctx.onstatechange = null;
        if (node) {
            node.onaudioprocess = null;
            if (node.port) { node.port.onmessage = null; node.port.close(); }
            node.disconnect();
        }
        ctx.close().catch(() => {});
        Module._saudio_context = null;
        Module.faAudio = null;
        globalThis.FactoriaAudio = null;
    };
    return ctx.sampleRate | 0;
});

EM_JS(void, fa_web_audio_close_impl, (), {
    if (Module.faAudioClose) { Module.faAudioClose(); Module.faAudioClose = null; }
});

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

int audio_web_open(int rate, int channels, WebAudioCallback callback, void* user) {
    g_callback = callback;
    g_user = user;
    g_channels = channels;
    // 512-frame chunks (about 11 ms), a queue of 2048 frames (about 43 ms): the main thread may be busy for a long frame
    // (a 60 fps frame is 16.7 ms) and the message still arrives before the worklet runs dry.
    return fa_web_audio_open_impl(rate, channels, 512, 2048);
}

void audio_web_close() {
    fa_web_audio_close_impl();
    g_callback = nullptr;
    g_user = nullptr;
}

}  // namespace fa
