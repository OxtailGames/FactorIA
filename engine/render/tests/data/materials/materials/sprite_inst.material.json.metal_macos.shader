{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "92b6737b88986088c23ec149effb731593899af4f139a1a2f6aa207cd28c4169",
  "slang": "metal_macos",
  "params": [
    "boost"
  ],
  "textures": [],
  "kind": "sprite",
  "instanced": [
    {
      "name": "shift",
      "vec4": 0,
      "offset": 0,
      "components": 1
    },
    {
      "name": "tint",
      "vec4": 1,
      "offset": 0,
      "components": 4
    }
  ],
  "instanceVec4": 2,
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 fa_inst_v0 [[user(locn9)]];\n    float4 fa_inst_v1 [[user(locn10)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n    float4 fa_inst_d0 [[attribute(7)]];\n    float4 fa_inst_d1 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& shift, thread float4& tint)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread QuadVertex& v, thread float& shift)\n{\n    v.world_pos.x += shift;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _107 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_inst_d0;\n    float4 param_1 = in.fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    float shift;\n    float4 tint;\n    fa_instance_unpack(param, param_1, param_2, shift, tint);\n    out.fa_inst_v0 = in.fa_inst_d0;\n    out.fa_inst_v1 = in.fa_inst_d1;\n    float3 _184 = in.position;\n    float2 _185 = in.texcoord0;\n    float4 _186 = in.color0;\n    if (_107.cspace.x > 0.5)\n    {\n        float3 param_3 = in.color0.xyz;\n        float3 _119 = fa_srgb_to_linear(param_3);\n        float4 _198 = _186;\n        _198.x = _119.x;\n        _198.y = _119.y;\n        _198.z = _119.z;\n        _186 = _198;\n    }\n    QuadVertex param_4 = QuadVertex{ _184, _185, _186 };\n    vertex0(param_4, shift);\n    _184 = param_4.world_pos;\n    _185 = param_4.uv;\n    _186 = param_4.color;\n    out.gl_Position = _107.view_proj * float4(param_4.world_pos, 1.0);\n    out.uv = param_4.uv;\n    out.color = param_4.color;\n    out.xform = _107.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = param_4.world_pos.xy;\n    out.world_z = param_4.world_pos.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 fa_inst_v0 [[user(locn9), flat]];\n    float4 fa_inst_v1 [[user(locn10), flat]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _256 = fa_linear_to_srgb(param);\n        c = _256;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _264 = fa_srgb_to_linear(param_1);\n            c = _264;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _275 = tex.sample(smp, p);\n    float3 param = _275.xyz;\n    float param_1 = xform.y;\n    float3 _285 = fa_tex_fix(param, param_1);\n    return float4(_285, _275.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _98 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_98.x * 255.0) + 0.5) * 256.0) + floor((_98.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _122 = length(d);\n    if (_122 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _136 = precise::atan2(d.y, d.x);\n    float a = _136;\n    float _139;\n    if (_136 < 0.0)\n    {\n        _139 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _139 = a;\n    }\n    a = _139;\n    float _151 = _139 * 162.9746551513671875;\n    float _156 = fast::min(floor(_151), 1023.0);\n    float _163 = _156 + 1.0;\n    float i1 = _163;\n    if (_163 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _156;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _122) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _122) + 0.5, 0.0, 1.0), _151 - _156);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _323, thread float2& uv, thread float2& world_xy, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex, sampler light_smp)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _437 = _323.lit.y > 0.5;\n    if (_437)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _323.normal_uv.xy) + _323.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _461 = fa_tex_fix(param, param_1);\n        float3 _465 = (_461 * 2.0) - float3(1.0);\n        float _472 = cos(params.y);\n        float _474 = sin(params.y);\n        n = fast::normalize(float3((float2(_472, _474) * _465.x) + ((float2(-_474, _472) * ((mode > 5.5) ? (-1.0) : 1.0)) * _465.y), fast::max(_465.z, 0.0500000007450580596923828125)));\n    }\n    bool _508 = !_437;\n    bool _514;\n    if (_508)\n    {\n        _514 = _323.lit.z > 0.5;\n    }\n    else\n    {\n        _514 = _508;\n    }\n    float3 _517;\n    if (_514)\n    {\n        _517 = _323.flat_ambient.xyz;\n    }\n    else\n    {\n        _517 = _323.ambient.xyz;\n    }\n    float3 total = _517;\n    bool _534;\n    if (_514)\n    {\n        _534 = _323.lit.z < 1.5;\n    }\n    else\n    {\n        _534 = _514;\n    }\n    if (_534)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _323.light_map.xy), level(0.0)).xyz * _323.light_map.z);\n    }\n    float3 l;\n    float _652;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _574;\n        if (!_514)\n        {\n            _574 = float(i) >= _323.lit.x;\n        }\n        else\n        {\n            _574 = _514;\n        }\n        if (_574)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_323.light_pos[i].w < 0.0)\n        {\n            l = _323.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _600 = _323.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_600) / fast::max(_323.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _323.light_color[i].w);\n            float3 _620 = float3(_600, _323.light_pos[i].z);\n            l = _620 / float3(fast::max(length(_620), 9.9999997473787516355514526367188e-05));\n            if (_323.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _323.light_shadow_v[i].x;\n                float2 param_3 = -_600;\n                float param_4 = _323.light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4, shadow_tex, shadow_smp);\n            }\n        }\n        if (_437)\n        {\n            _652 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _652 = 1.0;\n        }\n        total += (_323.light_color[i].xyz * (att * _652));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _302 = fa_srgb_to_linear(param);\n        c = _302;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _680 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _684 = uv * _680;\n    float _690 = _680.x;\n    float _692 = _680.y;\n    float _694 = fast::clamp(shape_rs.x, 0.0, fast::min(_690, _692));\n    float2 _705 = (abs(_684) - _680) + float2(_694);\n    float d = (length(fast::max(_705, float2(0.0))) + fast::min(fast::max(_705.x, _705.y), 0.0)) - _694;\n    float ax = params.y;\n    bool _726 = params.y > 15.0;\n    if (_726)\n    {\n        ax -= 20.0;\n    }\n    float _737;\n    if (ax <= (-1.5))\n    {\n        _737 = (-2.0) - ax;\n    }\n    else\n    {\n        _737 = 0.0;\n    }\n    if (_737 > 0.0)\n    {\n        float _751 = _737 * 0.5;\n        d = abs(d + _751) - _751;\n    }\n    float _759 = fwidth(d);\n    float _760 = fast::max(_759, 9.9999997473787516355514526367188e-05);\n    float _770 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _760)), 0.0, 1.0);\n    float _775;\n    if (shape_rs.y > _760)\n    {\n        _775 = (_770 * _770) * (3.0 - (2.0 * _770));\n    }\n    else\n    {\n        _775 = _770;\n    }\n    float4 c = color;\n    bool _797 = (_737 <= 0.0) && (ax > (-0.5));\n    if (_797)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _812 = cos(ax);\n            float _814 = sin(ax);\n            g = ((dot(_684, float2(_812, _814)) / fast::max((abs(_812) * _690) + (abs(_814) * _692), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_726)\n        {\n            float4 _857 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _857;\n            float3 param = _857.xyz;\n            float param_1 = xform.y;\n            float3 _864 = fa_tex_fix(param, param_1);\n            float4 _1561 = c;\n            _1561.x = _864.x;\n            _1561.y = _864.y;\n            _1561.z = _864.z;\n            c = _1561;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _876 = scene_rgb(param_2, xform);\n            float4 _901 = mix(float4(color.xyz * color.w, color.w), float4(_876 * color2.w, color2.w), float4(g));\n            float _903 = _901.w;\n            float3 _906;\n            if (_903 > 9.9999997473787516355514526367188e-06)\n            {\n                _906 = _901.xyz / float3(_903);\n            }\n            else\n            {\n                _906 = color.xyz;\n            }\n            c = float4(_906, _903);\n        }\n    }\n    float4 _1570 = c;\n    _1570.w = _1570.w * _775;\n    c = _1570;\n    if (_797 || (shape_rs.y > 0.0))\n    {\n        float _947 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _956 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _956 + float3(_947 * 0.0039215688593685626983642578125);\n            float3 _962 = fa_srgb_to_linear(param_4);\n            float4 _1573 = c;\n            _1573.x = _962.x;\n            _1573.y = _962.y;\n            _1573.z = _962.z;\n            c = _1573;\n        }\n        else\n        {\n            float4 _972 = c;\n            float3 _975 = _972.xyz + float3(_947 * 0.0039215688593685626983642578125);\n            float4 _1580 = _972;\n            _1580.x = _975.x;\n            _1580.y = _975.y;\n            _1580.z = _975.z;\n            c = _1580;\n        }\n        float4 _1585 = c;\n        _1585.w = fast::clamp(_1585.w + ((_947 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1585.w)), 0.0, 1.0);\n        c = _1585;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _323)\n{\n    float2 _330 = gl_FragCoord.xy * _323.fa_target.xy;\n    float _334 = _330.y;\n    return float2(_330.x, mix(_334, 1.0 - _334, _323.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _323, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _376 = base_mode < 0.5;\n    bool _387;\n    if (!_376)\n    {\n        _387 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _387 = _376;\n    }\n    float _388;\n    if (_387)\n    {\n        _388 = shape_half.x;\n    }\n    else\n    {\n        _388 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _323), _323.fa_time.x, base_mode, float4(0.0), _388 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& shift, thread float4& tint)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& shift, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, shift, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _308 = scene_rgb(param, xform);\n    return _308;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, thread float4& tint, constant fa_material& _413)\n{\n    float3 param = tint.xyz;\n    float3 _416 = fa_scene_rgb(param, xform) * _413.boost;\n    s.color.x = _416.x;\n    s.color.y = _416.y;\n    s.color.z = _416.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _323 [[buffer(1)]], constant fa_material& _413 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1002 = in.params.x > 31.5;\n    float shift;\n    float4 tint;\n    if (_1002)\n    {\n        mode -= 32.0;\n    }\n    float _1010 = mode;\n    bool _1012 = _1010 > 15.5;\n    if (_1012)\n    {\n        mode -= 16.0;\n    }\n    float _1020 = mode;\n    bool _1022 = _1020 > 7.5;\n    if (_1022)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1012)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _323, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1012)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _323, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1086 = tex_color(param_5, tex, smp, in.xform) * in.color;\n                float4 param_6 = _1086;\n                float param_7 = mode;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _323, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), _1086.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1121 = length(in.uv);\n                    float _1124 = fwidth(_1121);\n                    float _1125 = fast::max(_1124, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1121) / _1125) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1121) / _1125) + 0.5, 0.0, 1.0) * fast::clamp(((_1121 - in.params.y) / _1125) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1165 = fast::clamp(1.0 - _1121, 0.0, 1.0);\n                            cov = (_1165 * _1165) * (3.0 - (2.0 * _1165));\n                        }\n                    }\n                    float3 _1174;\n                    if (_1012)\n                    {\n                        float4 param_8 = in.color;\n                        float param_9 = 5.0;\n                        _1174 = lit_color(param_8, param_9, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _323, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp);\n                    }\n                    else\n                    {\n                        _1174 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1174, in.color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1514 = out.frag_color;\n    fa_inst_load(shift, tint, in.fa_inst_v0, in.fa_inst_v1);\n    QuadInput param_11 = fa_quad_input(param_10, gl_FragCoord, _323, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_12 = QuadSurface{ _1514 };\n    fragment0(param_11, param_12, in.xform, tint, _413);\n    _1514 = param_12.color;\n    out.frag_color = param_12.color;\n    if (_1002)\n    {\n        float4 _1212 = out.frag_color;\n        float3 param_13 = in.color2.xyz;\n        float3 _1217 = scene_rgb(param_13, in.xform);\n        float3 _1221 = mix(_1212.xyz, _1217, float3(in.color2.w));\n        out.frag_color.x = _1221.x;\n        out.frag_color.y = _1221.y;\n        out.frag_color.z = _1221.z;\n    }\n    if (_1022)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1245 = _323.fog_col.w > 0.0;\n    bool _1253;\n    if (!_1245)\n    {\n        _1253 = _323.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1253 = _1245;\n    }\n    if (_1253)\n    {\n        float3 _1267 = float3(in.world_xy, in.world_z) - _323.fog_eye.xyz;\n        float _1274 = dot(_1267, _323.fog_c.xyz);\n        bool _1278 = _323.fog_c.w > 0.5;\n        float _1279;\n        if (_1278)\n        {\n            _1279 = _1274;\n        }\n        else\n        {\n            _1279 = length(_1267);\n        }\n        float _1291 = _1279 - _323.fog_b.x;\n        if (_1291 > 0.0)\n        {\n            float _1300 = _323.fog_col.w * _1291;\n            float tau = _1300 * _1300;\n            if (_323.fog_b.y > 0.0)\n            {\n                float _1316;\n                if (_1278)\n                {\n                    _1316 = in.world_xy.y - (_323.fog_c.y * _1274);\n                }\n                else\n                {\n                    _1316 = _323.fog_eye.y;\n                }\n                float _1337 = mix(_1316, in.world_xy.y, fast::clamp(_323.fog_b.x / _1279, 0.0, 1.0));\n                float _1341 = in.world_xy.y - _1337;\n                float _1346 = _1337 - _323.fog_b.z;\n                float _1351 = in.world_xy.y - _323.fog_b.z;\n                bool _1354 = _1346 <= 0.0;\n                bool _1355 = !_1354;\n                bool _1361;\n                if (_1355)\n                {\n                    _1361 = _323.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1361 = _1354;\n                }\n                float _1362;\n                if (_1361)\n                {\n                    _1362 = _323.fog_b.y;\n                }\n                else\n                {\n                    _1362 = _323.fog_b.y * exp(-fast::min(_323.fog_b.w * _1346, 80.0));\n                }\n                bool _1389;\n                if (_1355)\n                {\n                    _1389 = _323.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1389 = _1354;\n                }\n                float _1390;\n                if (_1389)\n                {\n                    _1390 = _323.fog_b.y * _1346;\n                }\n                else\n                {\n                    _1390 = (_323.fog_b.y * (1.0 - exp(-fast::min(_323.fog_b.w * _1346, 80.0)))) / _323.fog_b.w;\n                }\n                bool _1415 = _1351 <= 0.0;\n                bool _1422;\n                if (!_1415)\n                {\n                    _1422 = _323.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1422 = _1415;\n                }\n                float _1423;\n                if (_1422)\n                {\n                    _1423 = _323.fog_b.y * _1351;\n                }\n                else\n                {\n                    _1423 = (_323.fog_b.y * (1.0 - exp(-fast::min(_323.fog_b.w * _1351, 80.0)))) / _323.fog_b.w;\n                }\n                float _1450;\n                if (abs(_1341) < 0.001000000047497451305389404296875)\n                {\n                    _1450 = _1362;\n                }\n                else\n                {\n                    _1450 = (_1423 - _1390) / _1341;\n                }\n                tau += (_1291 * fast::max(_1450, 0.0));\n            }\n            float4 _1473 = out.frag_color;\n            float3 _1481 = mix(_1473.xyz, _323.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _1481.x;\n            out.frag_color.y = _1481.y;\n            out.frag_color.z = _1481.z;\n        }\n    }\n    return out;\n}\n\n",
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
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_107",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 1008,
            "struct_name": "quad_fs_params",
            "inst_name": "_323",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_413",
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
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 fa_inst_v0 [[user(locn9)]];\n    float4 fa_inst_v1 [[user(locn10)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n    float4 fa_inst_d0 [[attribute(7)]];\n    float4 fa_inst_d1 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& shift, thread float4& tint)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread QuadVertex& v, thread float& shift)\n{\n    v.world_pos.x += shift;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _107 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_inst_d0;\n    float4 param_1 = in.fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    float shift;\n    float4 tint;\n    fa_instance_unpack(param, param_1, param_2, shift, tint);\n    out.fa_inst_v0 = in.fa_inst_d0;\n    out.fa_inst_v1 = in.fa_inst_d1;\n    float3 _184 = in.position;\n    float2 _185 = in.texcoord0;\n    float4 _186 = in.color0;\n    if (_107.cspace.x > 0.5)\n    {\n        float3 param_3 = in.color0.xyz;\n        float3 _119 = fa_srgb_to_linear(param_3);\n        float4 _198 = _186;\n        _198.x = _119.x;\n        _198.y = _119.y;\n        _198.z = _119.z;\n        _186 = _198;\n    }\n    QuadVertex param_4 = QuadVertex{ _184, _185, _186 };\n    vertex0(param_4, shift);\n    _184 = param_4.world_pos;\n    _185 = param_4.uv;\n    _186 = param_4.color;\n    out.gl_Position = _107.view_proj * float4(param_4.world_pos, 1.0);\n    out.uv = param_4.uv;\n    out.color = param_4.color;\n    out.xform = _107.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = param_4.world_pos.xy;\n    out.world_z = param_4.world_pos.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n    float4 fa_inst_v0 [[user(locn9), flat]];\n    float4 fa_inst_v1 [[user(locn10), flat]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _114 = fa_linear_to_srgb(param);\n        c = _114;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _123 = fa_srgb_to_linear(param_1);\n            c = _123;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _162)\n{\n    float2 _169 = gl_FragCoord.xy * _162.fa_target.xy;\n    float _174 = _169.y;\n    return float2(_169.x, mix(_174, 1.0 - _174, _162.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _162, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _217 = base_mode < 0.5;\n    bool _228;\n    if (!_217)\n    {\n        _228 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _228 = _217;\n    }\n    float _229;\n    if (_228)\n    {\n        _229 = shape_half.x;\n    }\n    else\n    {\n        _229 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _162), _162.fa_time.x, base_mode, float4(0.0), _229 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& shift, thread float4& tint)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& shift, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, shift, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _139 = fa_srgb_to_linear(param);\n        c = _139;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _145 = scene_rgb(param, xform);\n    return _145;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, thread float4& tint, constant fa_material& _254)\n{\n    float3 param = tint.xyz;\n    float3 _257 = fa_scene_rgb(param, xform) * _254.boost;\n    s.color.x = _257.x;\n    s.color.y = _257.y;\n    s.color.z = _257.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _162 [[buffer(1)]], constant fa_material& _254 [[buffer(5)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _284 = tex.sample(smp, in.uv);\n    float3 param = _284.xyz;\n    float param_1 = in.xform.y;\n    float3 _293 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_293, _284.w) * in.color;\n    float param_2 = 0.0;\n    float4 _348 = out.frag_color;\n    float shift;\n    float4 tint;\n    fa_inst_load(shift, tint, in.fa_inst_v0, in.fa_inst_v1);\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _162, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _348 };\n    fragment0(param_3, param_4, in.xform, tint, _254);\n    _348 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_107",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 1008,
            "struct_name": "quad_fs_params",
            "inst_name": "_162",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_254",
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
          }
        ],
        "samplers": [
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
          }
        ]
      }
    }
  }
}
