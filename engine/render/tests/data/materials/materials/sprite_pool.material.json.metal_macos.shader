{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "d75bc1c2988d2355d3b6c4618a7c68ff76094f3e9d32765c88b7244d10541da4",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n    float4 gi_xf;\n    float4 gi_p;\n};\n\nstruct fa_material\n{\n    float reflection;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float refraction;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n    float2 size;\n    float fa_pad6;\n    float fa_pad7;\n    float strength;\n    float fa_pad8;\n    float fa_pad9;\n    float fa_pad10;\n    float4 tint;\n    float waveAmplitude;\n    float fa_pad11;\n    float fa_pad12;\n    float fa_pad13;\n    float waveLength;\n    float fa_pad14;\n    float fa_pad15;\n    float fa_pad16;\n    float waveSpeed;\n    float fa_pad17;\n    float fa_pad18;\n    float fa_pad19;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _628 = fa_linear_to_srgb(param);\n        c = _628;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _636 = fa_srgb_to_linear(param_1);\n            c = _636;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _647 = tex.sample(smp, p);\n    float3 param = _647.xyz;\n    float param_1 = xform.y;\n    float3 _657 = fa_tex_fix(param, param_1);\n    return float4(_657, _647.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 gi_irradiance(constant quad_fs_params& _686, sampler light_smp, thread float2& world_xy, texture2d<float> fx_gi_tex)\n{\n    float2 _909 = (world_xy * _686.gi_xf.xy) + _686.gi_xf.zw;\n    float4 _916 = fx_gi_tex.sample(light_smp, _909, level(0.0));\n    float _920 = _909.x;\n    bool _921 = _920 >= 0.0;\n    bool _927;\n    if (_921)\n    {\n        _927 = _909.y >= 0.0;\n    }\n    else\n    {\n        _927 = _921;\n    }\n    bool _933;\n    if (_927)\n    {\n        _933 = _920 <= 1.0;\n    }\n    else\n    {\n        _933 = _927;\n    }\n    bool _939;\n    if (_933)\n    {\n        _939 = _909.y <= 1.0;\n    }\n    else\n    {\n        _939 = _933;\n    }\n    bool _947;\n    if (_939)\n    {\n        _947 = _916.w > 0.0199999995529651641845703125;\n    }\n    else\n    {\n        _947 = _939;\n    }\n    float3 _948;\n    if (_947)\n    {\n        _948 = (_916.xyz / float3(_916.w)) * _686.gi_p.x;\n    }\n    else\n    {\n        _948 = float3(0.0);\n    }\n    return _948;\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _137 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_137.x * 255.0) + 0.5) * 256.0) + floor((_137.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_tap(thread const float& v, thread const float& tt, thread const float& dist, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _240 = floor(tt);\n    float _250 = _240 - (1024.0 * floor(_240 * 0.0009765625));\n    float _253 = _250 + 1.0;\n    float i1 = _253;\n    if (_253 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _250;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), tt - _240);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_soft(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _290 = length(d);\n    float result = 1.0;\n    if (_290 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _301 = precise::atan2(d.y, d.x);\n        float a = _301;\n        float _304;\n        if (_301 < 0.0)\n        {\n            _304 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _304 = a;\n        }\n        a = _304;\n        float _314 = _304 * 162.9746551513671875;\n        float _323 = fast::min((size * 10.0) / _290, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _349 = floor(_314 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _323));\n            float param = v;\n            float param_1 = _349 - (1024.0 * floor(_349 * 0.0009765625));\n            float _363 = shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius;\n            if (_363 < _290)\n            {\n                sum += _363;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _395 = fast::min(size * ((1.0 / fast::max(sum / n, 1.0)) - (1.0 / _290)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _413 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _419 = 1.0 - (0.800000011920928955078125 * abs(_413));\n                float param_2 = v;\n                float param_3 = _314 + (_413 * _395);\n                float param_4 = _290;\n                float param_5 = radius;\n                acc += (_419 * light_shadow_tap(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp));\n                wsum += _419;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _161 = length(d);\n    if (_161 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _175 = precise::atan2(d.y, d.x);\n    float a = _175;\n    float _178;\n    if (_175 < 0.0)\n    {\n        _178 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _178 = a;\n    }\n    a = _178;\n    float _190 = _178 * 162.9746551513671875;\n    float _195 = fast::min(floor(_190), 1023.0);\n    float _202 = _195 + 1.0;\n    float i1 = _202;\n    if (_202 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _195;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _161) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _161) + 0.5, 0.0, 1.0), _190 - _195);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_sized(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6, shadow_tex, shadow_smp);\n    }\n    return r;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _500 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _504 = _500.x + 0.5;\n    float2 c = float2(_504, 0.5 - _500.y);\n    bool _512 = _504 >= 0.0;\n    bool _518;\n    if (_512)\n    {\n        _518 = c.x <= 1.0;\n    }\n    else\n    {\n        _518 = _512;\n    }\n    bool _524;\n    if (_518)\n    {\n        _524 = c.y >= 0.0;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    bool _530;\n    if (_524)\n    {\n        _530 = c.y <= 1.0;\n    }\n    else\n    {\n        _530 = _524;\n    }\n    float2 _532 = c;\n    float2 _537 = fast::clamp(_532, float2(0.001953125), float2(0.998046875));\n    c = _537;\n    return float3(cell.x + (_537.x * cell.w), cell.y + (_537.y * cell.z), float(_530));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _686, sampler light_smp, texture2d<float> fx_cookie_tex)\n{\n    if (_686.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _686.light_cookie[i];\n    float4 param_1 = _686.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _884 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _884.xy, level(0.0));\n    return cookie_value(param_3) * _884.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, constant quad_fs_params& _686, sampler light_smp, thread float4& gl_FragCoord, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, texture2d<float> fx_gi_tex, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _970 = _686.lit.y > 0.5;\n    if (_970)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _686.normal_uv.xy) + _686.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _994 = fa_tex_fix(param, param_1);\n        float3 _998 = (_994 * 2.0) - float3(1.0);\n        float _1005 = cos(params.y);\n        float _1007 = sin(params.y);\n        n = fast::normalize(float3((float2(_1005, _1007) * _998.x) + ((float2(-_1007, _1005) * ((mode > 5.5) ? (-1.0) : 1.0)) * _998.y), fast::max(_998.z, 0.0500000007450580596923828125)));\n    }\n    bool _1041 = !_970;\n    bool _1047;\n    if (_1041)\n    {\n        _1047 = _686.lit.z > 0.5;\n    }\n    else\n    {\n        _1047 = _1041;\n    }\n    float3 _1050;\n    if (_1047)\n    {\n        _1050 = _686.flat_ambient.xyz;\n    }\n    else\n    {\n        _1050 = _686.ambient.xyz;\n    }\n    float3 total = _1050;\n    if (_686.gi_p.x > 0.0)\n    {\n        total += gi_irradiance(_686, light_smp, world_xy, fx_gi_tex);\n    }\n    bool _1075;\n    if (_1047)\n    {\n        _1075 = _686.lit.z < 1.5;\n    }\n    else\n    {\n        _1075 = _1047;\n    }\n    if (_1075)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _686.light_map.xy), level(0.0)).xyz * _686.light_map.z);\n    }\n    float3 l;\n    float _1202;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1112;\n        if (!_1047)\n        {\n            _1112 = float(i) >= _686.lit.x;\n        }\n        else\n        {\n            _1112 = _1047;\n        }\n        if (_1112)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_686.light_pos[i].w < 0.0)\n        {\n            l = _686.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _1138 = _686.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_1138) / fast::max(_686.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _686.light_color[i].w);\n            float3 _1158 = float3(_1138, _686.light_pos[i].z);\n            l = _1158 / float3(fast::max(length(_1158), 9.9999997473787516355514526367188e-05));\n            if (_686.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _686.light_shadow_v[i].x;\n                float param_3 = _686.light_shadow_v[i].y;\n                float2 param_4 = -_1138;\n                float param_5 = _686.light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp);\n            }\n            int param_6 = i;\n            float2 param_7 = -_1138;\n            att *= cookie_att(param_6, param_7, _686, light_smp, fx_cookie_tex);\n        }\n        if (_970)\n        {\n            _1202 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1202 = 1.0;\n        }\n        total += (_686.light_color[i].xyz * (att * _1202));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _673 = fa_srgb_to_linear(param);\n        c = _673;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1452 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1456 = uv * _1452;\n    float _1462 = _1452.x;\n    float _1464 = _1452.y;\n    float _1466 = fast::clamp(shape_rs.x, 0.0, fast::min(_1462, _1464));\n    float2 _1477 = (abs(_1456) - _1452) + float2(_1466);\n    float d = (length(fast::max(_1477, float2(0.0))) + fast::min(fast::max(_1477.x, _1477.y), 0.0)) - _1466;\n    float ax = params.y;\n    bool _1498 = params.y > 15.0;\n    if (_1498)\n    {\n        ax -= 20.0;\n    }\n    float _1509;\n    if (ax <= (-1.5))\n    {\n        _1509 = (-2.0) - ax;\n    }\n    else\n    {\n        _1509 = 0.0;\n    }\n    if (_1509 > 0.0)\n    {\n        float _1523 = _1509 * 0.5;\n        d = abs(d + _1523) - _1523;\n    }\n    float _1531 = fwidth(d);\n    float _1532 = fast::max(_1531, 9.9999997473787516355514526367188e-05);\n    float _1542 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1532)), 0.0, 1.0);\n    float _1547;\n    if (shape_rs.y > _1532)\n    {\n        _1547 = (_1542 * _1542) * (3.0 - (2.0 * _1542));\n    }\n    else\n    {\n        _1547 = _1542;\n    }\n    float4 c = color;\n    bool _1569 = (_1509 <= 0.0) && (ax > (-0.5));\n    if (_1569)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1584 = cos(ax);\n            float _1586 = sin(ax);\n            g = ((dot(_1456, float2(_1584, _1586)) / fast::max((abs(_1584) * _1462) + (abs(_1586) * _1464), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1498)\n        {\n            float4 _1629 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1629;\n            float3 param = _1629.xyz;\n            float param_1 = xform.y;\n            float3 _1636 = fa_tex_fix(param, param_1);\n            float4 _2431 = c;\n            _2431.x = _1636.x;\n            _2431.y = _1636.y;\n            _2431.z = _1636.z;\n            c = _2431;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1648 = scene_rgb(param_2, xform);\n            float4 _1673 = mix(float4(color.xyz * color.w, color.w), float4(_1648 * color2.w, color2.w), float4(g));\n            float _1675 = _1673.w;\n            float3 _1678;\n            if (_1675 > 9.9999997473787516355514526367188e-06)\n            {\n                _1678 = _1673.xyz / float3(_1675);\n            }\n            else\n            {\n                _1678 = color.xyz;\n            }\n            c = float4(_1678, _1675);\n        }\n    }\n    float4 _2440 = c;\n    _2440.w = _2440.w * _1547;\n    c = _2440;\n    if (_1569 || (shape_rs.y > 0.0))\n    {\n        float _1719 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1728 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1728 + float3(_1719 * 0.0039215688593685626983642578125);\n            float3 _1734 = fa_srgb_to_linear(param_4);\n            float4 _2443 = c;\n            _2443.x = _1734.x;\n            _2443.y = _1734.y;\n            _2443.z = _1734.z;\n            c = _2443;\n        }\n        else\n        {\n            float4 _1744 = c;\n            float3 _1747 = _1744.xyz + float3(_1719 * 0.0039215688593685626983642578125);\n            float4 _2450 = _1744;\n            _2450.x = _1747.x;\n            _2450.y = _1747.y;\n            _2450.z = _1747.z;\n            c = _2450;\n        }\n        float4 _2455 = c;\n        _2455.w = fast::clamp(_2455.w + ((_1719 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2455.w)), 0.0, 1.0);\n        c = _2455;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _686, sampler light_smp, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, thread float2& params)\n{\n    float2 _1239 = float2(_686.fx_rim_uv.x, 0.0);\n    float4 _1241 = tex.sample(smp, (uv - _1239));\n    float _1242 = _1241.w;\n    float4 _1252 = tex.sample(smp, (uv + _1239));\n    float _1253 = _1252.w;\n    float2 _1261 = float2(0.0, _686.fx_rim_uv.y);\n    float4 _1263 = tex.sample(smp, (uv - _1261));\n    float _1264 = _1263.w;\n    float4 _1274 = tex.sample(smp, (uv + _1261));\n    float _1275 = _1274.w;\n    float _1290 = _1242 - _1253;\n    float _1293 = _1275 - _1264;\n    float _1303 = cos(params.y);\n    float _1305 = sin(params.y);\n    float2 _1331 = ((float2(_1303, _1305) * _1290) + ((float2(-_1305, _1303) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1293)) / float2(fast::max(length(float2(_1290, _1293)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _686.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_686.light_pos[i].w < 0.0)\n        {\n            to_l = _686.light_pos[i].xy / float2(fast::max(length(_686.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _1377 = _686.light_pos[i].xy - world_xy;\n            float _1380 = length(_1377);\n            att = powr(fast::clamp(1.0 - (_1380 / fast::max(_686.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _686.light_color[i].w);\n            to_l = _1377 / float2(fast::max(_1380, 9.9999997473787516355514526367188e-05));\n            if (_686.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _686.light_shadow_v[i].x;\n                float param_1 = _686.light_shadow_v[i].y;\n                float2 param_2 = -_1377;\n                float param_3 = _686.light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1377;\n            att *= cookie_att(param_4, param_5, _686, light_smp, fx_cookie_tex);\n        }\n        sum += (_686.light_color[i].xyz * (att * fast::max(dot(_1331, to_l), 0.0)));\n    }\n    return (sum * _686.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_1242, _1253), fast::min(_1264, _1275))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(constant quad_fs_params& _686, thread float4& gl_FragCoord)\n{\n    float2 _737 = gl_FragCoord.xy * _686.fa_target.xy;\n    float _741 = _737.y;\n    return float2(_737.x, mix(_741, 1.0 - _741, _686.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, constant quad_fs_params& _686, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _777 = base_mode < 0.5;\n    bool _788;\n    if (!_777)\n    {\n        _788 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _788 = _777;\n    }\n    float _789;\n    if (_788)\n    {\n        _789 = shape_half.x;\n    }\n    else\n    {\n        _789 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(_686, gl_FragCoord), _686.fa_time.x, base_mode, float4(0.0), _789 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_scene_color(thread const float2& uv, constant quad_fs_params& _686, texture2d<float> fa_scene_tex, sampler light_smp)\n{\n    if (_686.fa_scene.x <= 0.0)\n    {\n        return float4(0.0);\n    }\n    float2 _706 = (uv * _686.fa_scene.xy) + _686.fa_scene.zw;\n    float _708 = _706.y;\n    _706.y = mix(_708, 1.0 - _708, _686.fa_target.z);\n    return fa_scene_tex.sample(light_smp, fast::clamp(_706, float2(0.0), float2(1.0)), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, constant quad_fs_params& _686, texture2d<float> fa_scene_tex, sampler light_smp, constant fa_material& _804)\n{\n    float2 param = i.screen_uv + (float2(_804.refraction + _804.strength, 0.0) * _686.fa_target.xy);\n    s.color = float4(mix(fa_scene_color(param, _686, fa_scene_tex, light_smp).xyz, _804.tint.xyz, float3(_804.tint.w)), 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _686 [[buffer(1)]], constant fa_material& _804 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> fx_emissive_tex [[texture(4)]], texture2d<float> fx_cookie_tex [[texture(5)]], texture2d<float> fx_gi_tex [[texture(6)]], texture2d<float> fa_scene_tex [[texture(7)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1774 = in.params.x > 31.5;\n    if (_1774)\n    {\n        mode -= 32.0;\n    }\n    float _1782 = mode;\n    bool _1784 = _1782 > 15.5;\n    if (_1784)\n    {\n        mode -= 16.0;\n    }\n    float _1792 = mode;\n    bool _1794 = _1792 > 7.5;\n    if (_1794)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1784)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, _686, light_smp, gl_FragCoord, in.uv, in.world_xy, fx_cookie_tex, fx_gi_tex, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1784)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, _686, light_smp, gl_FragCoord, in.uv, in.world_xy, fx_cookie_tex, fx_gi_tex, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1856 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1858 = _1856 * in.color;\n                float4 param_6 = _1858;\n                float param_7 = mode;\n                float _1865 = _1858.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, _686, light_smp, gl_FragCoord, in.uv, in.world_xy, fx_cookie_tex, fx_gi_tex, normal_tex, in.params, light_tex), _1865);\n                if (_686.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1865;\n                    float param_9 = mode;\n                    float4 _1881 = out.frag_color;\n                    float3 _1883 = _1881.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _686, light_smp, in.uv, in.world_xy, fx_cookie_tex, in.params);\n                    out.frag_color.x = _1883.x;\n                    out.frag_color.y = _1883.y;\n                    out.frag_color.z = _1883.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1913 = length(in.uv);\n                    float _1916 = fwidth(_1913);\n                    float _1917 = fast::max(_1916, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1913) / _1917) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1913) / _1917) + 0.5, 0.0, 1.0) * fast::clamp(((_1913 - in.params.y) / _1917) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1957 = fast::clamp(1.0 - _1913, 0.0, 1.0);\n                            cov = (_1957 * _1957) * (3.0 - (2.0 * _1957));\n                        }\n                    }\n                    float3 _1966;\n                    if (_1784)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1966 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, _686, light_smp, gl_FragCoord, in.uv, in.world_xy, fx_cookie_tex, fx_gi_tex, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1966 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1966, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_686.fx_emit.w > 0.5)\n    {\n        float3 e = _686.fx_emit.xyz;\n        if (_686.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _686.fx_emit_uv.xy) + _686.fx_emit_uv.zw)).xyz;\n            float param_13 = _686.fx_emit.w - 2.0;\n            float3 _2020 = fa_tex_fix(param_12, param_13);\n            e *= _2020;\n        }\n        float4 _2024 = out.frag_color;\n        float3 _2026 = _2024.xyz + e;\n        out.frag_color.x = _2026.x;\n        out.frag_color.y = _2026.y;\n        out.frag_color.z = _2026.z;\n    }\n    float param_14 = mode;\n    float4 _2351 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14, _686, gl_FragCoord, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _2351 };\n    fragment0(param_15, param_16, _686, fa_scene_tex, light_smp, _804);\n    _2351 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1774)\n    {\n        float4 _2052 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _2057 = scene_rgb(param_17, in.xform);\n        float3 _2061 = mix(_2052.xyz, _2057, float3(in.color2.w));\n        out.frag_color.x = _2061.x;\n        out.frag_color.y = _2061.y;\n        out.frag_color.z = _2061.z;\n    }\n    if (_1794)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _2084 = _686.fog_col.w > 0.0;\n    bool _2092;\n    if (!_2084)\n    {\n        _2092 = _686.fog_b.y > 0.0;\n    }\n    else\n    {\n        _2092 = _2084;\n    }\n    if (_2092)\n    {\n        float3 _2105 = float3(in.world_xy, in.world_z) - _686.fog_eye.xyz;\n        float _2112 = dot(_2105, _686.fog_c.xyz);\n        bool _2116 = _686.fog_c.w > 0.5;\n        float _2117;\n        if (_2116)\n        {\n            _2117 = _2112;\n        }\n        else\n        {\n            _2117 = length(_2105);\n        }\n        float _2129 = _2117 - _686.fog_b.x;\n        if (_2129 > 0.0)\n        {\n            float _2138 = _686.fog_col.w * _2129;\n            float tau = _2138 * _2138;\n            if (_686.fog_b.y > 0.0)\n            {\n                float _2154;\n                if (_2116)\n                {\n                    _2154 = in.world_xy.y - (_686.fog_c.y * _2112);\n                }\n                else\n                {\n                    _2154 = _686.fog_eye.y;\n                }\n                float _2175 = mix(_2154, in.world_xy.y, fast::clamp(_686.fog_b.x / _2117, 0.0, 1.0));\n                float _2179 = in.world_xy.y - _2175;\n                float _2184 = _2175 - _686.fog_b.z;\n                float _2189 = in.world_xy.y - _686.fog_b.z;\n                bool _2192 = _2184 <= 0.0;\n                bool _2193 = !_2192;\n                bool _2199;\n                if (_2193)\n                {\n                    _2199 = _686.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2199 = _2192;\n                }\n                float _2200;\n                if (_2199)\n                {\n                    _2200 = _686.fog_b.y;\n                }\n                else\n                {\n                    _2200 = _686.fog_b.y * exp(-fast::min(_686.fog_b.w * _2184, 80.0));\n                }\n                bool _2227;\n                if (_2193)\n                {\n                    _2227 = _686.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2227 = _2192;\n                }\n                float _2228;\n                if (_2227)\n                {\n                    _2228 = _686.fog_b.y * _2184;\n                }\n                else\n                {\n                    _2228 = (_686.fog_b.y * (1.0 - exp(-fast::min(_686.fog_b.w * _2184, 80.0)))) / _686.fog_b.w;\n                }\n                bool _2253 = _2189 <= 0.0;\n                bool _2260;\n                if (!_2253)\n                {\n                    _2260 = _686.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2260 = _2253;\n                }\n                float _2261;\n                if (_2260)\n                {\n                    _2261 = _686.fog_b.y * _2189;\n                }\n                else\n                {\n                    _2261 = (_686.fog_b.y * (1.0 - exp(-fast::min(_686.fog_b.w * _2189, 80.0)))) / _686.fog_b.w;\n                }\n                float _2288;\n                if (abs(_2179) < 0.001000000047497451305389404296875)\n                {\n                    _2288 = _2200;\n                }\n                else\n                {\n                    _2288 = (_2261 - _2228) / _2179;\n                }\n                tau += (_2129 * fast::max(_2288, 0.0));\n            }\n            float4 _2311 = out.frag_color;\n            float3 _2319 = mix(_2311.xyz, _686.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _2319.x;\n            out.frag_color.y = _2319.y;\n            out.frag_color.z = _2319.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "size": 1616,
            "struct_name": "quad_fs_params",
            "inst_name": "_686",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 128,
            "struct_name": "fa_material",
            "inst_name": "_804",
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
              "name": "fx_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 4
            }
          },
          {
            "texture": {
              "slot": 13,
              "stage": "fragment",
              "name": "fx_cookie_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 5
            }
          },
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fx_gi_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 6
            }
          },
          {
            "texture": {
              "slot": 15,
              "stage": "fragment",
              "name": "fa_scene_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 7
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
            "name": "fx_gi_tex_light_smp",
            "view_name": "fx_gi_tex",
            "sampler_name": "light_smp",
            "view_slot": 14,
            "sampler_slot": 1
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "light_tex_light_smp",
            "view_name": "light_tex",
            "sampler_name": "light_smp",
            "view_slot": 2,
            "sampler_slot": 1
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "shadow_tex_shadow_smp",
            "view_name": "shadow_tex",
            "sampler_name": "shadow_smp",
            "view_slot": 3,
            "sampler_slot": 2
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fx_cookie_tex_light_smp",
            "view_name": "fx_cookie_tex",
            "sampler_name": "light_smp",
            "view_slot": 13,
            "sampler_slot": 1
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fx_emissive_tex_smp",
            "view_name": "fx_emissive_tex",
            "sampler_name": "smp",
            "view_slot": 12,
            "sampler_slot": 0
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_scene_tex_light_smp",
            "view_name": "fa_scene_tex",
            "sampler_name": "light_smp",
            "view_slot": 15,
            "sampler_slot": 1
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _147 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _147;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n    float4 gi_xf;\n    float4 gi_p;\n};\n\nstruct fa_material\n{\n    float reflection;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float refraction;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n    float2 size;\n    float fa_pad6;\n    float fa_pad7;\n    float strength;\n    float fa_pad8;\n    float fa_pad9;\n    float fa_pad10;\n    float4 tint;\n    float waveAmplitude;\n    float fa_pad11;\n    float fa_pad12;\n    float fa_pad13;\n    float waveLength;\n    float fa_pad14;\n    float fa_pad15;\n    float fa_pad16;\n    float waveSpeed;\n    float fa_pad17;\n    float fa_pad18;\n    float fa_pad19;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _106 = fa_linear_to_srgb(param);\n        c = _106;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _115 = fa_srgb_to_linear(param_1);\n            c = _115;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(constant quad_fs_params& _130, thread float4& gl_FragCoord)\n{\n    float2 _191 = gl_FragCoord.xy * _130.fa_target.xy;\n    float _195 = _191.y;\n    return float2(_191.x, mix(_195, 1.0 - _195, _130.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, constant quad_fs_params& _130, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _235 = base_mode < 0.5;\n    bool _246;\n    if (!_235)\n    {\n        _246 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _246 = _235;\n    }\n    float _247;\n    if (_246)\n    {\n        _247 = shape_half.x;\n    }\n    else\n    {\n        _247 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(_130, gl_FragCoord), _130.fa_time.x, base_mode, float4(0.0), _247 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_scene_color(thread const float2& uv, constant quad_fs_params& _130, texture2d<float> fa_scene_tex, sampler light_smp)\n{\n    if (_130.fa_scene.x <= 0.0)\n    {\n        return float4(0.0);\n    }\n    float2 _152 = (uv * _130.fa_scene.xy) + _130.fa_scene.zw;\n    float _155 = _152.y;\n    _152.y = mix(_155, 1.0 - _155, _130.fa_target.z);\n    return fa_scene_tex.sample(light_smp, fast::clamp(_152, float2(0.0), float2(1.0)), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, constant quad_fs_params& _130, texture2d<float> fa_scene_tex, sampler light_smp, constant fa_material& _263)\n{\n    float2 param = i.screen_uv + (float2(_263.refraction + _263.strength, 0.0) * _130.fa_target.xy);\n    s.color = float4(mix(fa_scene_color(param, _130, fa_scene_tex, light_smp).xyz, _263.tint.xyz, float3(_263.tint.w)), 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _130 [[buffer(1)]], constant fa_material& _263 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> fa_scene_tex [[texture(1)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _330 = tex.sample(smp, in.uv);\n    float3 param = _330.xyz;\n    float param_1 = in.xform.y;\n    float3 _341 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_341, _330.w) * in.color;\n    float param_2 = 0.0;\n    float4 _394 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, _130, gl_FragCoord, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _394 };\n    fragment0(param_3, param_4, _130, fa_scene_tex, light_smp, _263);\n    _394 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "size": 1616,
            "struct_name": "quad_fs_params",
            "inst_name": "_130",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 128,
            "struct_name": "fa_material",
            "inst_name": "_263",
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
              "slot": 15,
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
            "view_slot": 15,
            "sampler_slot": 1
          }
        ]
      }
    }
  }
}
