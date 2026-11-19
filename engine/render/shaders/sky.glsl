// The engine's own sky: the vertical gradient (SceneSettings.skyColor / horizonColor) of a perspective camera, drawn as one
// full-screen triangle. The template (sky_common.glsl) with the default snippet, an empty sky(). A sky material's generated top
// file has this very shape with its own fa_user block, so a material whose sky() is empty draws exactly what the engine's own
// program draws.
@module sky

@block fa_user
void sky(in SkyInput i, inout SkySurface s) {}
@end

@include sky_common.glsl

@program sky vs fs
