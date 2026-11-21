{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "92b6737b88986088c23ec149effb731593899af4f139a1a2f6aa207cd28c4169",
  "slang": "metal_macos",
  "params": [
    "reflection",
    "refraction",
    "size",
    "strength",
    "tint",
    "waveAmplitude",
    "waveLength",
    "waveSpeed"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _147 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _147;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n};\n\nstruct fa_material\n{\n    float reflection;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float refraction;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n    float2 size;\n    float fa_pad6;\n    float fa_pad7;\n    float strength;\n    float fa_pad8;\n    float fa_pad9;\n    float fa_pad10;\n    float4 tint;\n    float waveAmplitude;\n    float fa_pad11;\n    float fa_pad12;\n    float fa_pad13;\n    float waveLength;\n    float fa_pad14;\n    float fa_pad15;\n    float fa_pad16;\n    float waveSpeed;\n    float fa_pad17;\n    float fa_pad18;\n    float fa_pad19;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _250 = fa_linear_to_srgb(param);\n        c = _250;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _258 = fa_srgb_to_linear(param_1);\n            c = _258;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _269 = tex.sample(smp, p);\n    float3 param = _269.xyz;\n    float param_1 = xform.y;\n    float3 _279 = fa_tex_fix(param, param_1);\n    return float4(_279, _269.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _92 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_92.x * 255.0) + 0.5) * 256.0) + floor((_92.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _116 = length(d);\n    if (_116 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _130 = precise::atan2(d.y, d.x);\n    float a = _130;\n    float _133;\n    if (_130 < 0.0)\n    {\n        _133 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _133 = a;\n    }\n    a = _133;\n    float _145 = _133 * 162.9746551513671875;\n    float _150 = fast::min(floor(_145), 1023.0);\n    float _157 = _150 + 1.0;\n    float i1 = _157;\n    if (_157 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _150;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _116) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _116) + 0.5, 0.0, 1.0), _145 - _150);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, constant quad_fs_params& _307, sampler light_smp, thread float4& gl_FragCoord, thread float2& uv, thread float2& world_xy, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _497 = _307.lit.y > 0.5;\n    if (_497)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _307.normal_uv.xy) + _307.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _521 = fa_tex_fix(param, param_1);\n        float3 _525 = (_521 * 2.0) - float3(1.0);\n        float _532 = cos(params.y);\n        float _534 = sin(params.y);\n        n = fast::normalize(float3((float2(_532, _534) * _525.x) + ((float2(-_534, _532) * ((mode > 5.5) ? (-1.0) : 1.0)) * _525.y), fast::max(_525.z, 0.0500000007450580596923828125)));\n    }\n    bool _568 = !_497;\n    bool _574;\n    if (_568)\n    {\n        _574 = _307.lit.z > 0.5;\n    }\n    else\n    {\n        _574 = _568;\n    }\n    float3 _577;\n    if (_574)\n    {\n        _577 = _307.flat_ambient.xyz;\n    }\n    else\n    {\n        _577 = _307.ambient.xyz;\n    }\n    float3 total = _577;\n    bool _594;\n    if (_574)\n    {\n        _594 = _307.lit.z < 1.5;\n    }\n    else\n    {\n        _594 = _574;\n    }\n    if (_594)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _307.light_map.xy), level(0.0)).xyz * _307.light_map.z);\n    }\n    float3 l;\n    float _710;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _632;\n        if (!_574)\n        {\n            _632 = float(i) >= _307.lit.x;\n        }\n        else\n        {\n            _632 = _574;\n        }\n        if (_632)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_307.light_pos[i].w < 0.0)\n        {\n            l = _307.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _658 = _307.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_658) / fast::max(_307.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _307.light_color[i].w);\n            float3 _678 = float3(_658, _307.light_pos[i].z);\n            l = _678 / float3(fast::max(length(_678), 9.9999997473787516355514526367188e-05));\n            if (_307.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _307.light_shadow_v[i].x;\n                float2 param_3 = -_658;\n                float param_4 = _307.light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4, shadow_tex, shadow_smp);\n            }\n        }\n        if (_497)\n        {\n            _710 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _710 = 1.0;\n        }\n        total += (_307.light_color[i].xyz * (att * _710));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _296 = fa_srgb_to_linear(param);\n        c = _296;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _738 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _742 = uv * _738;\n    float _748 = _738.x;\n    float _750 = _738.y;\n    float _752 = fast::clamp(shape_rs.x, 0.0, fast::min(_748, _750));\n    float2 _763 = (abs(_742) - _738) + float2(_752);\n    float d = (length(fast::max(_763, float2(0.0))) + fast::min(fast::max(_763.x, _763.y), 0.0)) - _752;\n    float ax = params.y;\n    bool _784 = params.y > 15.0;\n    if (_784)\n    {\n        ax -= 20.0;\n    }\n    float _795;\n    if (ax <= (-1.5))\n    {\n        _795 = (-2.0) - ax;\n    }\n    else\n    {\n        _795 = 0.0;\n    }\n    if (_795 > 0.0)\n    {\n        float _809 = _795 * 0.5;\n        d = abs(d + _809) - _809;\n    }\n    float _817 = fwidth(d);\n    float _818 = fast::max(_817, 9.9999997473787516355514526367188e-05);\n    float _828 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _818)), 0.0, 1.0);\n    float _833;\n    if (shape_rs.y > _818)\n    {\n        _833 = (_828 * _828) * (3.0 - (2.0 * _828));\n    }\n    else\n    {\n        _833 = _828;\n    }\n    float4 c = color;\n    bool _855 = (_795 <= 0.0) && (ax > (-0.5));\n    if (_855)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _870 = cos(ax);\n            float _872 = sin(ax);\n            g = ((dot(_742, float2(_870, _872)) / fast::max((abs(_870) * _748) + (abs(_872) * _750), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_784)\n        {\n            float4 _915 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _915;\n            float3 param = _915.xyz;\n            float param_1 = xform.y;\n            float3 _922 = fa_tex_fix(param, param_1);\n            float4 _1620 = c;\n            _1620.x = _922.x;\n            _1620.y = _922.y;\n            _1620.z = _922.z;\n            c = _1620;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _934 = scene_rgb(param_2, xform);\n            float4 _959 = mix(float4(color.xyz * color.w, color.w), float4(_934 * color2.w, color2.w), float4(g));\n            float _961 = _959.w;\n            float3 _964;\n            if (_961 > 9.9999997473787516355514526367188e-06)\n            {\n                _964 = _959.xyz / float3(_961);\n            }\n            else\n            {\n                _964 = color.xyz;\n            }\n            c = float4(_964, _961);\n        }\n    }\n    float4 _1629 = c;\n    _1629.w = _1629.w * _833;\n    c = _1629;\n    if (_855 || (shape_rs.y > 0.0))\n    {\n        float _1005 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1014 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1014 + float3(_1005 * 0.0039215688593685626983642578125);\n            float3 _1020 = fa_srgb_to_linear(param_4);\n            float4 _1632 = c;\n            _1632.x = _1020.x;\n            _1632.y = _1020.y;\n            _1632.z = _1020.z;\n            c = _1632;\n        }\n        else\n        {\n            float4 _1030 = c;\n            float3 _1033 = _1030.xyz + float3(_1005 * 0.0039215688593685626983642578125);\n            float4 _1639 = _1030;\n            _1639.x = _1033.x;\n            _1639.y = _1033.y;\n            _1639.z = _1033.z;\n            c = _1639;\n        }\n        float4 _1644 = c;\n        _1644.w = fast::clamp(_1644.w + ((_1005 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1644.w)), 0.0, 1.0);\n        c = _1644;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(constant quad_fs_params& _307, thread float4& gl_FragCoord)\n{\n    float2 _360 = gl_FragCoord.xy * _307.fa_target.xy;\n    float _364 = _360.y;\n    return float2(_360.x, mix(_364, 1.0 - _364, _307.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, constant quad_fs_params& _307, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _403 = base_mode < 0.5;\n    bool _414;\n    if (!_403)\n    {\n        _414 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _414 = _403;\n    }\n    float _415;\n    if (_414)\n    {\n        _415 = shape_half.x;\n    }\n    else\n    {\n        _415 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(_307, gl_FragCoord), _307.fa_time.x, base_mode, float4(0.0), _415 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_scene_color(thread const float2& uv, constant quad_fs_params& _307, texture2d<float> fa_scene_tex, sampler light_smp)\n{\n    if (_307.fa_scene.x <= 0.0)\n    {\n        return float4(0.0);\n    }\n    float2 _328 = (uv * _307.fa_scene.xy) + _307.fa_scene.zw;\n    float _330 = _328.y;\n    _328.y = mix(_330, 1.0 - _330, _307.fa_target.z);\n    return fa_scene_tex.sample(light_smp, fast::clamp(_328, float2(0.0), float2(1.0)), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, constant quad_fs_params& _307, texture2d<float> fa_scene_tex, sampler light_smp, constant fa_material& _430)\n{\n    float2 param = i.screen_uv + (float2(_430.refraction + _430.strength, 0.0) * _307.fa_target.xy);\n    s.color = float4(mix(fa_scene_color(param, _307, fa_scene_tex, light_smp).xyz, _430.tint.xyz, float3(_430.tint.w)), 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _307 [[buffer(1)]], constant fa_material& _430 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> fa_scene_tex [[texture(4)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1060 = in.params.x > 31.5;\n    if (_1060)\n    {\n        mode -= 32.0;\n    }\n    float _1068 = mode;\n    bool _1070 = _1068 > 15.5;\n    if (_1070)\n    {\n        mode -= 16.0;\n    }\n    float _1078 = mode;\n    bool _1080 = _1078 > 7.5;\n    if (_1080)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1070)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, _307, light_smp, gl_FragCoord, in.uv, in.world_xy, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1070)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, _307, light_smp, gl_FragCoord, in.uv, in.world_xy, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1144 = tex_color(param_5, tex, smp, in.xform) * in.color;\n                float4 param_6 = _1144;\n                float param_7 = mode;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, _307, light_smp, gl_FragCoord, in.uv, in.world_xy, normal_tex, in.params, light_tex), _1144.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1179 = length(in.uv);\n                    float _1182 = fwidth(_1179);\n                    float _1183 = fast::max(_1182, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1179) / _1183) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1179) / _1183) + 0.5, 0.0, 1.0) * fast::clamp(((_1179 - in.params.y) / _1183) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1223 = fast::clamp(1.0 - _1179, 0.0, 1.0);\n                            cov = (_1223 * _1223) * (3.0 - (2.0 * _1223));\n                        }\n                    }\n                    float3 _1232;\n                    if (_1070)\n                    {\n                        float4 param_8 = in.color;\n                        float param_9 = 5.0;\n                        _1232 = lit_color(param_8, param_9, shadow_tex, shadow_smp, smp, in.xform, _307, light_smp, gl_FragCoord, in.uv, in.world_xy, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1232 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1232, in.color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1569 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10, _307, gl_FragCoord, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_12 = QuadSurface{ _1569 };\n    fragment0(param_11, param_12, _307, fa_scene_tex, light_smp, _430);\n    _1569 = param_12.color;\n    out.frag_color = param_12.color;\n    if (_1060)\n    {\n        float4 _1270 = out.frag_color;\n        float3 param_13 = in.color2.xyz;\n        float3 _1275 = scene_rgb(param_13, in.xform);\n        float3 _1279 = mix(_1270.xyz, _1275, float3(in.color2.w));\n        out.frag_color.x = _1279.x;\n        out.frag_color.y = _1279.y;\n        out.frag_color.z = _1279.z;\n    }\n    if (_1080)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1302 = _307.fog_col.w > 0.0;\n    bool _1310;\n    if (!_1302)\n    {\n        _1310 = _307.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1310 = _1302;\n    }\n    if (_1310)\n    {\n        float3 _1323 = float3(in.world_xy, in.world_z) - _307.fog_eye.xyz;\n        float _1330 = dot(_1323, _307.fog_c.xyz);\n        bool _1334 = _307.fog_c.w > 0.5;\n        float _1335;\n        if (_1334)\n        {\n            _1335 = _1330;\n        }\n        else\n        {\n            _1335 = length(_1323);\n        }\n        float _1347 = _1335 - _307.fog_b.x;\n        if (_1347 > 0.0)\n        {\n            float _1356 = _307.fog_col.w * _1347;\n            float tau = _1356 * _1356;\n            if (_307.fog_b.y > 0.0)\n            {\n                float _1372;\n                if (_1334)\n                {\n                    _1372 = in.world_xy.y - (_307.fog_c.y * _1330);\n                }\n                else\n                {\n                    _1372 = _307.fog_eye.y;\n                }\n                float _1393 = mix(_1372, in.world_xy.y, fast::clamp(_307.fog_b.x / _1335, 0.0, 1.0));\n                float _1397 = in.world_xy.y - _1393;\n                float _1402 = _1393 - _307.fog_b.z;\n                float _1407 = in.world_xy.y - _307.fog_b.z;\n                bool _1410 = _1402 <= 0.0;\n                bool _1411 = !_1410;\n                bool _1417;\n                if (_1411)\n                {\n                    _1417 = _307.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1417 = _1410;\n                }\n                float _1418;\n                if (_1417)\n                {\n                    _1418 = _307.fog_b.y;\n                }\n                else\n                {\n                    _1418 = _307.fog_b.y * exp(-fast::min(_307.fog_b.w * _1402, 80.0));\n                }\n                bool _1445;\n                if (_1411)\n                {\n                    _1445 = _307.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1445 = _1410;\n                }\n                float _1446;\n                if (_1445)\n                {\n                    _1446 = _307.fog_b.y * _1402;\n                }\n                else\n                {\n                    _1446 = (_307.fog_b.y * (1.0 - exp(-fast::min(_307.fog_b.w * _1402, 80.0)))) / _307.fog_b.w;\n                }\n                bool _1471 = _1407 <= 0.0;\n                bool _1478;\n                if (!_1471)\n                {\n                    _1478 = _307.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1478 = _1471;\n                }\n                float _1479;\n                if (_1478)\n                {\n                    _1479 = _307.fog_b.y * _1407;\n                }\n                else\n                {\n                    _1479 = (_307.fog_b.y * (1.0 - exp(-fast::min(_307.fog_b.w * _1407, 80.0)))) / _307.fog_b.w;\n                }\n                float _1506;\n                if (abs(_1397) < 0.001000000047497451305389404296875)\n                {\n                    _1506 = _1418;\n                }\n                else\n                {\n                    _1506 = (_1479 - _1446) / _1397;\n                }\n                tau += (_1347 * fast::max(_1506, 0.0));\n            }\n            float4 _1529 = out.frag_color;\n            float3 _1537 = mix(_1529.xyz, _307.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _1537.x;\n            out.frag_color.y = _1537.y;\n            out.frag_color.z = _1537.z;\n        }\n    }\n    return out;\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main0"
        },
        "fragment_func": {
          "entry_point": "main0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 1,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 3,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 5,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec2",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_68",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 1008,
            "struct_name": "quad_fs_params",
            "inst_name": "_307",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 128,
            "struct_name": "fa_material",
            "inst_name": "_430",
            "msl_buffer_n": 5
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 1
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 2
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 3
            }
          },
          {
            "texture": {
              "slot": 12,
              "stage": "fragment",
              "name": "fa_scene_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 4
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "shadow_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 2
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "light_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 1
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "tex_smp",
            "view_name": "tex",
            "sampler_name": "smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "normal_tex_smp",
            "view_name": "normal_tex",
            "sampler_name": "smp",
            "view_slot": 1,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "light_tex_light_smp",
            "view_name": "light_tex",
            "sampler_name": "light_smp",
            "view_slot": 2,
            "sampler_slot": 1
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "shadow_tex_shadow_smp",
            "view_name": "shadow_tex",
            "sampler_name": "shadow_smp",
            "view_slot": 3,
            "sampler_slot": 2
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_scene_tex_light_smp",
            "view_name": "fa_scene_tex",
            "sampler_name": "light_smp",
            "view_slot": 12,
            "sampler_slot": 1
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _147 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _147;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n};\n\nstruct fa_material\n{\n    float reflection;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float refraction;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n    float2 size;\n    float fa_pad6;\n    float fa_pad7;\n    float strength;\n    float fa_pad8;\n    float fa_pad9;\n    float fa_pad10;\n    float4 tint;\n    float waveAmplitude;\n    float fa_pad11;\n    float fa_pad12;\n    float fa_pad13;\n    float waveLength;\n    float fa_pad14;\n    float fa_pad15;\n    float fa_pad16;\n    float waveSpeed;\n    float fa_pad17;\n    float fa_pad18;\n    float fa_pad19;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _106 = fa_linear_to_srgb(param);\n        c = _106;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _115 = fa_srgb_to_linear(param_1);\n            c = _115;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(constant quad_fs_params& _128, thread float4& gl_FragCoord)\n{\n    float2 _189 = gl_FragCoord.xy * _128.fa_target.xy;\n    float _193 = _189.y;\n    return float2(_189.x, mix(_193, 1.0 - _193, _128.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, constant quad_fs_params& _128, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _233 = base_mode < 0.5;\n    bool _244;\n    if (!_233)\n    {\n        _244 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _244 = _233;\n    }\n    float _245;\n    if (_244)\n    {\n        _245 = shape_half.x;\n    }\n    else\n    {\n        _245 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(_128, gl_FragCoord), _128.fa_time.x, base_mode, float4(0.0), _245 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_scene_color(thread const float2& uv, constant quad_fs_params& _128, texture2d<float> fa_scene_tex, sampler light_smp)\n{\n    if (_128.fa_scene.x <= 0.0)\n    {\n        return float4(0.0);\n    }\n    float2 _150 = (uv * _128.fa_scene.xy) + _128.fa_scene.zw;\n    float _153 = _150.y;\n    _150.y = mix(_153, 1.0 - _153, _128.fa_target.z);\n    return fa_scene_tex.sample(light_smp, fast::clamp(_150, float2(0.0), float2(1.0)), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, constant quad_fs_params& _128, texture2d<float> fa_scene_tex, sampler light_smp, constant fa_material& _261)\n{\n    float2 param = i.screen_uv + (float2(_261.refraction + _261.strength, 0.0) * _128.fa_target.xy);\n    s.color = float4(mix(fa_scene_color(param, _128, fa_scene_tex, light_smp).xyz, _261.tint.xyz, float3(_261.tint.w)), 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _128 [[buffer(1)]], constant fa_material& _261 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> fa_scene_tex [[texture(1)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _329 = tex.sample(smp, in.uv);\n    float3 param = _329.xyz;\n    float param_1 = in.xform.y;\n    float3 _340 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_340, _329.w) * in.color;\n    float param_2 = 0.0;\n    float4 _393 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, _128, gl_FragCoord, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _393 };\n    fragment0(param_3, param_4, _128, fa_scene_tex, light_smp, _261);\n    _393 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main0"
        },
        "fragment_func": {
          "entry_point": "main0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float"
          },
          {
            "slot": 1,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 3,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 5,
            "type": "vec2",
            "base_type": "Float"
          },
          {
            "slot": 6,
            "type": "vec2",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_68",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 1008,
            "struct_name": "quad_fs_params",
            "inst_name": "_128",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 128,
            "struct_name": "fa_material",
            "inst_name": "_261",
            "msl_buffer_n": 5
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          },
          {
            "texture": {
              "slot": 12,
              "stage": "fragment",
              "name": "fa_scene_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 1
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "light_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 1
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 0
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "tex_smp",
            "view_name": "tex",
            "sampler_name": "smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_scene_tex_light_smp",
            "view_name": "fa_scene_tex",
            "sampler_name": "light_smp",
            "view_slot": 12,
            "sampler_slot": 1
          }
        ]
      }
    }
  }
}
