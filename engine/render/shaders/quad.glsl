// FactorIA 2D quad shader: sprites, tiles, text glyphs, shapes, particles, debug lines.
// One vertex format for everything:  pos.xyz | uv | color (ubyte4n) | params (mode, aux)
// mode 0 = textured quad (texture * color)
// mode 1 = anti-aliased filled circle   (uv in [-1,1], coverage from the distance to the center)
// mode 2 = anti-aliased ring            (aux = inner radius as a fraction of the outer radius)
// mode 3 = soft round particle          (smooth radial falloff)
// mode 4 = glyph                        (single-channel coverage texture * color)
@module quad

@vs vs
layout(binding=0) uniform vs_params {
    mat4 view_proj;
};

layout(location=0) in vec3 position;
layout(location=1) in vec2 texcoord0;
layout(location=2) in vec4 color0;
layout(location=3) in vec2 params0;

out vec2 uv;
out vec4 color;
out vec2 params;

void main() {
    gl_Position = view_proj * vec4(position, 1.0);
    uv = texcoord0;
    color = color0;
    params = params0;
}
@end

@fs fs
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;

in vec2 uv;
in vec4 color;
in vec2 params;
out vec4 frag_color;

void main() {
    float mode = params.x;
    if (mode < 0.5) {
        frag_color = texture(sampler2D(tex, smp), uv) * color;
    } else if (mode > 3.5) {
        frag_color = vec4(color.rgb, color.a * texture(sampler2D(tex, smp), uv).r);
    } else {
        float d = length(uv);
        float aa = max(fwidth(d), 1e-4);
        float cov;
        if (mode < 1.5) {
            cov = clamp((1.0 - d) / aa + 0.5, 0.0, 1.0);
        } else if (mode < 2.5) {
            float outer = clamp((1.0 - d) / aa + 0.5, 0.0, 1.0);
            float inner = clamp((d - params.y) / aa + 0.5, 0.0, 1.0);
            cov = outer * inner;
        } else {
            float t = clamp(1.0 - d, 0.0, 1.0);
            cov = t * t * (3.0 - 2.0 * t);
        }
        frag_color = vec4(color.rgb, color.a * cov);
    }
}
@end

@program quad vs fs
