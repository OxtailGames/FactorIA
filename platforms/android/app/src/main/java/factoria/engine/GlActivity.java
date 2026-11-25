// The GL player's activity on Android (written by factoria export from platforms/android in the engine repo; do not edit
// it in an exported project, export again).
//
// An export with the Vulkan player (export.android.vulkanPlayer, docs/EXPORTING.md, "Android") launches
// android.app.NativeActivity with libfactoria_player_vulkan.so. Where Vulkan cannot start (no driver, no device), that
// player starts this activity with the extras FA_GPU_FALLBACK_FROM and FA_GPU_FALLBACK_REASON and finishes itself
// (engine/runtime/src/gpu_launch_android.cpp). This class only gives the GL player an activity of its own: a plain
// NativeActivity that loads the library its manifest entry names (android.app.lib_name = factoria_player), in the
// process ":gl", because sokol_app ends the process of an activity that is destroyed. The GL player reads the extras,
// draws with OpenGL ES 3 and never hands back.
package factoria.engine;

import android.app.NativeActivity;

public class GlActivity extends NativeActivity {}
