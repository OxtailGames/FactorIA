{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "8dda08c124964ccb7d15a0a3238fb4669d4ca9ef375995bc9768b79891bfc837",
  "slang": "metal_macos",
  "params": [
    "tint"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _147 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _147;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n};\n\nstruct fa_material\n{\n    float4 tint;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _625 = fa_linear_to_srgb(param);\n        c = _625;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _633 = fa_srgb_to_linear(param_1);\n            c = _633;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _644 = tex.sample(smp, p);\n    float3 param = _644.xyz;\n    float param_1 = xform.y;\n    float3 _654 = fa_tex_fix(param, param_1);\n    return float4(_654, _644.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _134 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_134.x * 255.0) + 0.5) * 256.0) + floor((_134.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_tap(thread const float& v, thread const float& tt, thread const float& dist, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _237 = floor(tt);\n    float _247 = _237 - (1024.0 * floor(_237 * 0.0009765625));\n    float _250 = _247 + 1.0;\n    float i1 = _250;\n    if (_250 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _247;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), tt - _237);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_soft(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _287 = length(d);\n    float result = 1.0;\n    if (_287 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _298 = precise::atan2(d.y, d.x);\n        float a = _298;\n        float _301;\n        if (_298 < 0.0)\n        {\n            _301 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _301 = a;\n        }\n        a = _301;\n        float _311 = _301 * 162.9746551513671875;\n        float _320 = fast::min((size * 10.0) / _287, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _346 = floor(_311 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _320));\n            float param = v;\n            float param_1 = _346 - (1024.0 * floor(_346 * 0.0009765625));\n            float _360 = shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius;\n            if (_360 < _287)\n            {\n                sum += _360;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _392 = fast::min(size * ((1.0 / fast::max(sum / n, 1.0)) - (1.0 / _287)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _410 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _416 = 1.0 - (0.800000011920928955078125 * abs(_410));\n                float param_2 = v;\n                float param_3 = _311 + (_410 * _392);\n                float param_4 = _287;\n                float param_5 = radius;\n                acc += (_416 * light_shadow_tap(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp));\n                wsum += _416;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _158 = length(d);\n    if (_158 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _172 = precise::atan2(d.y, d.x);\n    float a = _172;\n    float _175;\n    if (_172 < 0.0)\n    {\n        _175 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _175 = a;\n    }\n    a = _175;\n    float _187 = _175 * 162.9746551513671875;\n    float _192 = fast::min(floor(_187), 1023.0);\n    float _199 = _192 + 1.0;\n    float i1 = _199;\n    if (_199 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _192;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _158) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _158) + 0.5, 0.0, 1.0), _187 - _192);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_sized(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6, shadow_tex, shadow_smp);\n    }\n    return r;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _497 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _501 = _497.x + 0.5;\n    float2 c = float2(_501, 0.5 - _497.y);\n    bool _509 = _501 >= 0.0;\n    bool _515;\n    if (_509)\n    {\n        _515 = c.x <= 1.0;\n    }\n    else\n    {\n        _515 = _509;\n    }\n    bool _521;\n    if (_515)\n    {\n        _521 = c.y >= 0.0;\n    }\n    else\n    {\n        _521 = _515;\n    }\n    bool _527;\n    if (_521)\n    {\n        _527 = c.y <= 1.0;\n    }\n    else\n    {\n        _527 = _521;\n    }\n    float2 _529 = c;\n    float2 _534 = fast::clamp(_529, float2(0.001953125), float2(0.998046875));\n    c = _534;\n    return float3(cell.x + (_534.x * cell.w), cell.y + (_534.y * cell.z), float(_527));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _693, texture2d<float> fx_cookie_tex, sampler light_smp)\n{\n    if (_693.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _693.light_cookie[i];\n    float4 param_1 = _693.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _804 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _804.xy, level(0.0));\n    return cookie_value(param_3) * _804.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _693, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _826 = _693.lit.y > 0.5;\n    if (_826)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _693.normal_uv.xy) + _693.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _850 = fa_tex_fix(param, param_1);\n        float3 _854 = (_850 * 2.0) - float3(1.0);\n        float _861 = cos(params.y);\n        float _863 = sin(params.y);\n        n = fast::normalize(float3((float2(_861, _863) * _854.x) + ((float2(-_863, _861) * ((mode > 5.5) ? (-1.0) : 1.0)) * _854.y), fast::max(_854.z, 0.0500000007450580596923828125)));\n    }\n    bool _897 = !_826;\n    bool _903;\n    if (_897)\n    {\n        _903 = _693.lit.z > 0.5;\n    }\n    else\n    {\n        _903 = _897;\n    }\n    float3 _906;\n    if (_903)\n    {\n        _906 = _693.flat_ambient.xyz;\n    }\n    else\n    {\n        _906 = _693.ambient.xyz;\n    }\n    float3 total = _906;\n    bool _923;\n    if (_903)\n    {\n        _923 = _693.lit.z < 1.5;\n    }\n    else\n    {\n        _923 = _903;\n    }\n    if (_923)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _693.light_map.xy), level(0.0)).xyz * _693.light_map.z);\n    }\n    float3 l;\n    float _1050;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _960;\n        if (!_903)\n        {\n            _960 = float(i) >= _693.lit.x;\n        }\n        else\n        {\n            _960 = _903;\n        }\n        if (_960)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_693.light_pos[i].w < 0.0)\n        {\n            l = _693.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _986 = _693.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_986) / fast::max(_693.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _693.light_color[i].w);\n            float3 _1006 = float3(_986, _693.light_pos[i].z);\n            l = _1006 / float3(fast::max(length(_1006), 9.9999997473787516355514526367188e-05));\n            if (_693.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _693.light_shadow_v[i].x;\n                float param_3 = _693.light_shadow_v[i].y;\n                float2 param_4 = -_986;\n                float param_5 = _693.light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp);\n            }\n            int param_6 = i;\n            float2 param_7 = -_986;\n            att *= cookie_att(param_6, param_7, _693, fx_cookie_tex, light_smp);\n        }\n        if (_826)\n        {\n            _1050 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1050 = 1.0;\n        }\n        total += (_693.light_color[i].xyz * (att * _1050));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _670 = fa_srgb_to_linear(param);\n        c = _670;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1300 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1304 = uv * _1300;\n    float _1310 = _1300.x;\n    float _1312 = _1300.y;\n    float _1314 = fast::clamp(shape_rs.x, 0.0, fast::min(_1310, _1312));\n    float2 _1325 = (abs(_1304) - _1300) + float2(_1314);\n    float d = (length(fast::max(_1325, float2(0.0))) + fast::min(fast::max(_1325.x, _1325.y), 0.0)) - _1314;\n    float ax = params.y;\n    bool _1346 = params.y > 15.0;\n    if (_1346)\n    {\n        ax -= 20.0;\n    }\n    float _1357;\n    if (ax <= (-1.5))\n    {\n        _1357 = (-2.0) - ax;\n    }\n    else\n    {\n        _1357 = 0.0;\n    }\n    if (_1357 > 0.0)\n    {\n        float _1371 = _1357 * 0.5;\n        d = abs(d + _1371) - _1371;\n    }\n    float _1379 = fwidth(d);\n    float _1380 = fast::max(_1379, 9.9999997473787516355514526367188e-05);\n    float _1390 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1380)), 0.0, 1.0);\n    float _1395;\n    if (shape_rs.y > _1380)\n    {\n        _1395 = (_1390 * _1390) * (3.0 - (2.0 * _1390));\n    }\n    else\n    {\n        _1395 = _1390;\n    }\n    float4 c = color;\n    bool _1417 = (_1357 <= 0.0) && (ax > (-0.5));\n    if (_1417)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1432 = cos(ax);\n            float _1434 = sin(ax);\n            g = ((dot(_1304, float2(_1432, _1434)) / fast::max((abs(_1432) * _1310) + (abs(_1434) * _1312), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1346)\n        {\n            float4 _1477 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1477;\n            float3 param = _1477.xyz;\n            float param_1 = xform.y;\n            float3 _1484 = fa_tex_fix(param, param_1);\n            float4 _2273 = c;\n            _2273.x = _1484.x;\n            _2273.y = _1484.y;\n            _2273.z = _1484.z;\n            c = _2273;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1496 = scene_rgb(param_2, xform);\n            float4 _1521 = mix(float4(color.xyz * color.w, color.w), float4(_1496 * color2.w, color2.w), float4(g));\n            float _1523 = _1521.w;\n            float3 _1526;\n            if (_1523 > 9.9999997473787516355514526367188e-06)\n            {\n                _1526 = _1521.xyz / float3(_1523);\n            }\n            else\n            {\n                _1526 = color.xyz;\n            }\n            c = float4(_1526, _1523);\n        }\n    }\n    float4 _2282 = c;\n    _2282.w = _2282.w * _1395;\n    c = _2282;\n    if (_1417 || (shape_rs.y > 0.0))\n    {\n        float _1567 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1576 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1576 + float3(_1567 * 0.0039215688593685626983642578125);\n            float3 _1582 = fa_srgb_to_linear(param_4);\n            float4 _2285 = c;\n            _2285.x = _1582.x;\n            _2285.y = _1582.y;\n            _2285.z = _1582.z;\n            c = _2285;\n        }\n        else\n        {\n            float4 _1592 = c;\n            float3 _1595 = _1592.xyz + float3(_1567 * 0.0039215688593685626983642578125);\n            float4 _2292 = _1592;\n            _2292.x = _1595.x;\n            _2292.y = _1595.y;\n            _2292.z = _1595.z;\n            c = _2292;\n        }\n        float4 _2297 = c;\n        _2297.w = fast::clamp(_2297.w + ((_1567 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2297.w)), 0.0, 1.0);\n        c = _2297;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _693, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, thread float2& params)\n{\n    float2 _1087 = float2(_693.fx_rim_uv.x, 0.0);\n    float4 _1089 = tex.sample(smp, (uv - _1087));\n    float _1090 = _1089.w;\n    float4 _1100 = tex.sample(smp, (uv + _1087));\n    float _1101 = _1100.w;\n    float2 _1109 = float2(0.0, _693.fx_rim_uv.y);\n    float4 _1111 = tex.sample(smp, (uv - _1109));\n    float _1112 = _1111.w;\n    float4 _1122 = tex.sample(smp, (uv + _1109));\n    float _1123 = _1122.w;\n    float _1138 = _1090 - _1101;\n    float _1141 = _1123 - _1112;\n    float _1151 = cos(params.y);\n    float _1153 = sin(params.y);\n    float2 _1179 = ((float2(_1151, _1153) * _1138) + ((float2(-_1153, _1151) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1141)) / float2(fast::max(length(float2(_1138, _1141)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _693.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_693.light_pos[i].w < 0.0)\n        {\n            to_l = _693.light_pos[i].xy / float2(fast::max(length(_693.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _1225 = _693.light_pos[i].xy - world_xy;\n            float _1228 = length(_1225);\n            att = powr(fast::clamp(1.0 - (_1228 / fast::max(_693.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _693.light_color[i].w);\n            to_l = _1225 / float2(fast::max(_1228, 9.9999997473787516355514526367188e-05));\n            if (_693.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _693.light_shadow_v[i].x;\n                float param_1 = _693.light_shadow_v[i].y;\n                float2 param_2 = -_1225;\n                float param_3 = _693.light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1225;\n            att *= cookie_att(param_4, param_5, _693, fx_cookie_tex, light_smp);\n        }\n        sum += (_693.light_color[i].xyz * (att * fast::max(dot(_1179, to_l), 0.0)));\n    }\n    return (sum * _693.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_1090, _1101), fast::min(_1112, _1123))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _693)\n{\n    float2 _699 = gl_FragCoord.xy * _693.fa_target.xy;\n    float _703 = _699.y;\n    return float2(_699.x, mix(_703, 1.0 - _703, _693.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _693, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _741 = base_mode < 0.5;\n    bool _752;\n    if (!_741)\n    {\n        _752 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _752 = _741;\n    }\n    float _753;\n    if (_752)\n    {\n        _753 = shape_half.x;\n    }\n    else\n    {\n        _753 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _693), _693.fa_time.x, base_mode, float4(0.0), _753 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _676 = scene_rgb(param, xform);\n    return _676;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, constant fa_material& _767)\n{\n    float3 param = _767.tint.xyz;\n    float4 _774 = s.color;\n    float3 _776 = _774.xyz * fa_scene_rgb(param, xform);\n    s.color.x = _776.x;\n    s.color.y = _776.y;\n    s.color.z = _776.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _693 [[buffer(1)]], constant fa_material& _767 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> fx_emissive_tex [[texture(4)]], texture2d<float> fx_cookie_tex [[texture(5)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1622 = in.params.x > 31.5;\n    if (_1622)\n    {\n        mode -= 32.0;\n    }\n    float _1630 = mode;\n    bool _1632 = _1630 > 15.5;\n    if (_1632)\n    {\n        mode -= 16.0;\n    }\n    float _1640 = mode;\n    bool _1642 = _1640 > 7.5;\n    if (_1642)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1632)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _693, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1632)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _693, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1704 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1706 = _1704 * in.color;\n                float4 param_6 = _1706;\n                float param_7 = mode;\n                float _1713 = _1706.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _693, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), _1713);\n                if (_693.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1713;\n                    float param_9 = mode;\n                    float4 _1729 = out.frag_color;\n                    float3 _1731 = _1729.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _693, in.uv, in.world_xy, fx_cookie_tex, light_smp, in.params);\n                    out.frag_color.x = _1731.x;\n                    out.frag_color.y = _1731.y;\n                    out.frag_color.z = _1731.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1761 = length(in.uv);\n                    float _1764 = fwidth(_1761);\n                    float _1765 = fast::max(_1764, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1761) / _1765) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1761) / _1765) + 0.5, 0.0, 1.0) * fast::clamp(((_1761 - in.params.y) / _1765) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1805 = fast::clamp(1.0 - _1761, 0.0, 1.0);\n                            cov = (_1805 * _1805) * (3.0 - (2.0 * _1805));\n                        }\n                    }\n                    float3 _1814;\n                    if (_1632)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1814 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _693, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1814 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1814, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_693.fx_emit.w > 0.5)\n    {\n        float3 e = _693.fx_emit.xyz;\n        if (_693.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _693.fx_emit_uv.xy) + _693.fx_emit_uv.zw)).xyz;\n            float param_13 = _693.fx_emit.w - 2.0;\n            float3 _1869 = fa_tex_fix(param_12, param_13);\n            e *= _1869;\n        }\n        float4 _1873 = out.frag_color;\n        float3 _1875 = _1873.xyz + e;\n        out.frag_color.x = _1875.x;\n        out.frag_color.y = _1875.y;\n        out.frag_color.z = _1875.z;\n    }\n    float param_14 = mode;\n    float4 _2203 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14, gl_FragCoord, _693, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _2203 };\n    fragment0(param_15, param_16, in.xform, _767);\n    _2203 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1622)\n    {\n        float4 _1901 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _1906 = scene_rgb(param_17, in.xform);\n        float3 _1910 = mix(_1901.xyz, _1906, float3(in.color2.w));\n        out.frag_color.x = _1910.x;\n        out.frag_color.y = _1910.y;\n        out.frag_color.z = _1910.z;\n    }\n    if (_1642)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1934 = _693.fog_col.w > 0.0;\n    bool _1942;\n    if (!_1934)\n    {\n        _1942 = _693.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1942 = _1934;\n    }\n    if (_1942)\n    {\n        float3 _1956 = float3(in.world_xy, in.world_z) - _693.fog_eye.xyz;\n        float _1963 = dot(_1956, _693.fog_c.xyz);\n        bool _1967 = _693.fog_c.w > 0.5;\n        float _1968;\n        if (_1967)\n        {\n            _1968 = _1963;\n        }\n        else\n        {\n            _1968 = length(_1956);\n        }\n        float _1980 = _1968 - _693.fog_b.x;\n        if (_1980 > 0.0)\n        {\n            float _1989 = _693.fog_col.w * _1980;\n            float tau = _1989 * _1989;\n            if (_693.fog_b.y > 0.0)\n            {\n                float _2005;\n                if (_1967)\n                {\n                    _2005 = in.world_xy.y - (_693.fog_c.y * _1963);\n                }\n                else\n                {\n                    _2005 = _693.fog_eye.y;\n                }\n                float _2026 = mix(_2005, in.world_xy.y, fast::clamp(_693.fog_b.x / _1968, 0.0, 1.0));\n                float _2030 = in.world_xy.y - _2026;\n                float _2035 = _2026 - _693.fog_b.z;\n                float _2040 = in.world_xy.y - _693.fog_b.z;\n                bool _2043 = _2035 <= 0.0;\n                bool _2044 = !_2043;\n                bool _2050;\n                if (_2044)\n                {\n                    _2050 = _693.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2050 = _2043;\n                }\n                float _2051;\n                if (_2050)\n                {\n                    _2051 = _693.fog_b.y;\n                }\n                else\n                {\n                    _2051 = _693.fog_b.y * exp(-fast::min(_693.fog_b.w * _2035, 80.0));\n                }\n                bool _2078;\n                if (_2044)\n                {\n                    _2078 = _693.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2078 = _2043;\n                }\n                float _2079;\n                if (_2078)\n                {\n                    _2079 = _693.fog_b.y * _2035;\n                }\n                else\n                {\n                    _2079 = (_693.fog_b.y * (1.0 - exp(-fast::min(_693.fog_b.w * _2035, 80.0)))) / _693.fog_b.w;\n                }\n                bool _2104 = _2040 <= 0.0;\n                bool _2111;\n                if (!_2104)\n                {\n                    _2111 = _693.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2111 = _2104;\n                }\n                float _2112;\n                if (_2111)\n                {\n                    _2112 = _693.fog_b.y * _2040;\n                }\n                else\n                {\n                    _2112 = (_693.fog_b.y * (1.0 - exp(-fast::min(_693.fog_b.w * _2040, 80.0)))) / _693.fog_b.w;\n                }\n                float _2139;\n                if (abs(_2030) < 0.001000000047497451305389404296875)\n                {\n                    _2139 = _2051;\n                }\n                else\n                {\n                    _2139 = (_2112 - _2079) / _2030;\n                }\n                tau += (_1980 * fast::max(_2139, 0.0));\n            }\n            float4 _2162 = out.frag_color;\n            float3 _2170 = mix(_2162.xyz, _693.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _2170.x;\n            out.frag_color.y = _2170.y;\n            out.frag_color.z = _2170.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "size": 1584,
            "struct_name": "quad_fs_params",
            "inst_name": "_693",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_767",
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
            "name": "fx_cookie_tex_light_smp",
            "view_name": "fx_cookie_tex",
            "sampler_name": "light_smp",
            "view_slot": 13,
            "sampler_slot": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fx_emissive_tex_smp",
            "view_name": "fx_emissive_tex",
            "sampler_name": "smp",
            "view_slot": 12,
            "sampler_slot": 0
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _147 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _147;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n};\n\nstruct fa_material\n{\n    float4 tint;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _107 = fa_linear_to_srgb(param);\n        c = _107;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _116 = fa_srgb_to_linear(param_1);\n            c = _116;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _157)\n{\n    float2 _164 = gl_FragCoord.xy * _157.fa_target.xy;\n    float _169 = _164.y;\n    return float2(_164.x, mix(_169, 1.0 - _169, _157.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _157, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _213 = base_mode < 0.5;\n    bool _224;\n    if (!_213)\n    {\n        _224 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _224 = _213;\n    }\n    float _225;\n    if (_224)\n    {\n        _225 = shape_half.x;\n    }\n    else\n    {\n        _225 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _157), _157.fa_time.x, base_mode, float4(0.0), _225 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _132 = fa_srgb_to_linear(param);\n        c = _132;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _138 = scene_rgb(param, xform);\n    return _138;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, constant fa_material& _239)\n{\n    float3 param = _239.tint.xyz;\n    float4 _246 = s.color;\n    float3 _248 = _246.xyz * fa_scene_rgb(param, xform);\n    s.color.x = _248.x;\n    s.color.y = _248.y;\n    s.color.z = _248.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _157 [[buffer(1)]], constant fa_material& _239 [[buffer(5)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _267 = tex.sample(smp, in.uv);\n    float3 param = _267.xyz;\n    float param_1 = in.xform.y;\n    float3 _276 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_276, _267.w) * in.color;\n    float param_2 = 0.0;\n    float4 _331 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _157, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _331 };\n    fragment0(param_3, param_4, in.xform, _239);\n    _331 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "size": 1584,
            "struct_name": "quad_fs_params",
            "inst_name": "_157",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_239",
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
