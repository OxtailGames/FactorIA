{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "8dda08c124964ccb7d15a0a3238fb4669d4ca9ef375995bc9768b79891bfc837",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n};\n\nstruct fa_material\n{\n    float reflection;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float refraction;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n    float2 size;\n    float fa_pad6;\n    float fa_pad7;\n    float strength;\n    float fa_pad8;\n    float fa_pad9;\n    float fa_pad10;\n    float4 tint;\n    float waveAmplitude;\n    float fa_pad11;\n    float fa_pad12;\n    float fa_pad13;\n    float waveLength;\n    float fa_pad14;\n    float fa_pad15;\n    float fa_pad16;\n    float waveSpeed;\n    float fa_pad17;\n    float fa_pad18;\n    float fa_pad19;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _625 = fa_linear_to_srgb(param);\n        c = _625;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _633 = fa_srgb_to_linear(param_1);\n            c = _633;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _644 = tex.sample(smp, p);\n    float3 param = _644.xyz;\n    float param_1 = xform.y;\n    float3 _654 = fa_tex_fix(param, param_1);\n    return float4(_654, _644.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _134 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_134.x * 255.0) + 0.5) * 256.0) + floor((_134.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_tap(thread const float& v, thread const float& tt, thread const float& dist, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _237 = floor(tt);\n    float _247 = _237 - (1024.0 * floor(_237 * 0.0009765625));\n    float _250 = _247 + 1.0;\n    float i1 = _250;\n    if (_250 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _247;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), tt - _237);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_soft(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _287 = length(d);\n    float result = 1.0;\n    if (_287 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _298 = precise::atan2(d.y, d.x);\n        float a = _298;\n        float _301;\n        if (_298 < 0.0)\n        {\n            _301 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _301 = a;\n        }\n        a = _301;\n        float _311 = _301 * 162.9746551513671875;\n        float _320 = fast::min((size * 10.0) / _287, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _346 = floor(_311 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _320));\n            float param = v;\n            float param_1 = _346 - (1024.0 * floor(_346 * 0.0009765625));\n            float _360 = shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius;\n            if (_360 < _287)\n            {\n                sum += _360;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _392 = fast::min(size * ((1.0 / fast::max(sum / n, 1.0)) - (1.0 / _287)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _410 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _416 = 1.0 - (0.800000011920928955078125 * abs(_410));\n                float param_2 = v;\n                float param_3 = _311 + (_410 * _392);\n                float param_4 = _287;\n                float param_5 = radius;\n                acc += (_416 * light_shadow_tap(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp));\n                wsum += _416;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _158 = length(d);\n    if (_158 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _172 = precise::atan2(d.y, d.x);\n    float a = _172;\n    float _175;\n    if (_172 < 0.0)\n    {\n        _175 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _175 = a;\n    }\n    a = _175;\n    float _187 = _175 * 162.9746551513671875;\n    float _192 = fast::min(floor(_187), 1023.0);\n    float _199 = _192 + 1.0;\n    float i1 = _199;\n    if (_199 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _192;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _158) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _158) + 0.5, 0.0, 1.0), _187 - _192);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_sized(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6, shadow_tex, shadow_smp);\n    }\n    return r;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _497 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _501 = _497.x + 0.5;\n    float2 c = float2(_501, 0.5 - _497.y);\n    bool _509 = _501 >= 0.0;\n    bool _515;\n    if (_509)\n    {\n        _515 = c.x <= 1.0;\n    }\n    else\n    {\n        _515 = _509;\n    }\n    bool _521;\n    if (_515)\n    {\n        _521 = c.y >= 0.0;\n    }\n    else\n    {\n        _521 = _515;\n    }\n    bool _527;\n    if (_521)\n    {\n        _527 = c.y <= 1.0;\n    }\n    else\n    {\n        _527 = _521;\n    }\n    float2 _529 = c;\n    float2 _534 = fast::clamp(_529, float2(0.001953125), float2(0.998046875));\n    c = _534;\n    return float3(cell.x + (_534.x * cell.w), cell.y + (_534.y * cell.z), float(_527));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _683, sampler light_smp, texture2d<float> fx_cookie_tex)\n{\n    if (_683.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _683.light_cookie[i];\n    float4 param_1 = _683.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _881 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _881.xy, level(0.0));\n    return cookie_value(param_3) * _881.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, constant quad_fs_params& _683, sampler light_smp, thread float4& gl_FragCoord, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _902 = _683.lit.y > 0.5;\n    if (_902)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _683.normal_uv.xy) + _683.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _926 = fa_tex_fix(param, param_1);\n        float3 _930 = (_926 * 2.0) - float3(1.0);\n        float _937 = cos(params.y);\n        float _939 = sin(params.y);\n        n = fast::normalize(float3((float2(_937, _939) * _930.x) + ((float2(-_939, _937) * ((mode > 5.5) ? (-1.0) : 1.0)) * _930.y), fast::max(_930.z, 0.0500000007450580596923828125)));\n    }\n    bool _973 = !_902;\n    bool _979;\n    if (_973)\n    {\n        _979 = _683.lit.z > 0.5;\n    }\n    else\n    {\n        _979 = _973;\n    }\n    float3 _982;\n    if (_979)\n    {\n        _982 = _683.flat_ambient.xyz;\n    }\n    else\n    {\n        _982 = _683.ambient.xyz;\n    }\n    float3 total = _982;\n    bool _999;\n    if (_979)\n    {\n        _999 = _683.lit.z < 1.5;\n    }\n    else\n    {\n        _999 = _979;\n    }\n    if (_999)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _683.light_map.xy), level(0.0)).xyz * _683.light_map.z);\n    }\n    float3 l;\n    float _1126;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1036;\n        if (!_979)\n        {\n            _1036 = float(i) >= _683.lit.x;\n        }\n        else\n        {\n            _1036 = _979;\n        }\n        if (_1036)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_683.light_pos[i].w < 0.0)\n        {\n            l = _683.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _1062 = _683.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_1062) / fast::max(_683.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _683.light_color[i].w);\n            float3 _1082 = float3(_1062, _683.light_pos[i].z);\n            l = _1082 / float3(fast::max(length(_1082), 9.9999997473787516355514526367188e-05));\n            if (_683.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _683.light_shadow_v[i].x;\n                float param_3 = _683.light_shadow_v[i].y;\n                float2 param_4 = -_1062;\n                float param_5 = _683.light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp);\n            }\n            int param_6 = i;\n            float2 param_7 = -_1062;\n            att *= cookie_att(param_6, param_7, _683, light_smp, fx_cookie_tex);\n        }\n        if (_902)\n        {\n            _1126 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1126 = 1.0;\n        }\n        total += (_683.light_color[i].xyz * (att * _1126));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _670 = fa_srgb_to_linear(param);\n        c = _670;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1376 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1380 = uv * _1376;\n    float _1386 = _1376.x;\n    float _1388 = _1376.y;\n    float _1390 = fast::clamp(shape_rs.x, 0.0, fast::min(_1386, _1388));\n    float2 _1401 = (abs(_1380) - _1376) + float2(_1390);\n    float d = (length(fast::max(_1401, float2(0.0))) + fast::min(fast::max(_1401.x, _1401.y), 0.0)) - _1390;\n    float ax = params.y;\n    bool _1422 = params.y > 15.0;\n    if (_1422)\n    {\n        ax -= 20.0;\n    }\n    float _1433;\n    if (ax <= (-1.5))\n    {\n        _1433 = (-2.0) - ax;\n    }\n    else\n    {\n        _1433 = 0.0;\n    }\n    if (_1433 > 0.0)\n    {\n        float _1447 = _1433 * 0.5;\n        d = abs(d + _1447) - _1447;\n    }\n    float _1455 = fwidth(d);\n    float _1456 = fast::max(_1455, 9.9999997473787516355514526367188e-05);\n    float _1466 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1456)), 0.0, 1.0);\n    float _1471;\n    if (shape_rs.y > _1456)\n    {\n        _1471 = (_1466 * _1466) * (3.0 - (2.0 * _1466));\n    }\n    else\n    {\n        _1471 = _1466;\n    }\n    float4 c = color;\n    bool _1493 = (_1433 <= 0.0) && (ax > (-0.5));\n    if (_1493)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1508 = cos(ax);\n            float _1510 = sin(ax);\n            g = ((dot(_1380, float2(_1508, _1510)) / fast::max((abs(_1508) * _1386) + (abs(_1510) * _1388), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1422)\n        {\n            float4 _1553 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1553;\n            float3 param = _1553.xyz;\n            float param_1 = xform.y;\n            float3 _1560 = fa_tex_fix(param, param_1);\n            float4 _2349 = c;\n            _2349.x = _1560.x;\n            _2349.y = _1560.y;\n            _2349.z = _1560.z;\n            c = _2349;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1572 = scene_rgb(param_2, xform);\n            float4 _1597 = mix(float4(color.xyz * color.w, color.w), float4(_1572 * color2.w, color2.w), float4(g));\n            float _1599 = _1597.w;\n            float3 _1602;\n            if (_1599 > 9.9999997473787516355514526367188e-06)\n            {\n                _1602 = _1597.xyz / float3(_1599);\n            }\n            else\n            {\n                _1602 = color.xyz;\n            }\n            c = float4(_1602, _1599);\n        }\n    }\n    float4 _2358 = c;\n    _2358.w = _2358.w * _1471;\n    c = _2358;\n    if (_1493 || (shape_rs.y > 0.0))\n    {\n        float _1643 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1652 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1652 + float3(_1643 * 0.0039215688593685626983642578125);\n            float3 _1658 = fa_srgb_to_linear(param_4);\n            float4 _2361 = c;\n            _2361.x = _1658.x;\n            _2361.y = _1658.y;\n            _2361.z = _1658.z;\n            c = _2361;\n        }\n        else\n        {\n            float4 _1668 = c;\n            float3 _1671 = _1668.xyz + float3(_1643 * 0.0039215688593685626983642578125);\n            float4 _2368 = _1668;\n            _2368.x = _1671.x;\n            _2368.y = _1671.y;\n            _2368.z = _1671.z;\n            c = _2368;\n        }\n        float4 _2373 = c;\n        _2373.w = fast::clamp(_2373.w + ((_1643 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2373.w)), 0.0, 1.0);\n        c = _2373;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _683, sampler light_smp, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, thread float2& params)\n{\n    float2 _1163 = float2(_683.fx_rim_uv.x, 0.0);\n    float4 _1165 = tex.sample(smp, (uv - _1163));\n    float _1166 = _1165.w;\n    float4 _1176 = tex.sample(smp, (uv + _1163));\n    float _1177 = _1176.w;\n    float2 _1185 = float2(0.0, _683.fx_rim_uv.y);\n    float4 _1187 = tex.sample(smp, (uv - _1185));\n    float _1188 = _1187.w;\n    float4 _1198 = tex.sample(smp, (uv + _1185));\n    float _1199 = _1198.w;\n    float _1214 = _1166 - _1177;\n    float _1217 = _1199 - _1188;\n    float _1227 = cos(params.y);\n    float _1229 = sin(params.y);\n    float2 _1255 = ((float2(_1227, _1229) * _1214) + ((float2(-_1229, _1227) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1217)) / float2(fast::max(length(float2(_1214, _1217)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _683.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_683.light_pos[i].w < 0.0)\n        {\n            to_l = _683.light_pos[i].xy / float2(fast::max(length(_683.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _1301 = _683.light_pos[i].xy - world_xy;\n            float _1304 = length(_1301);\n            att = powr(fast::clamp(1.0 - (_1304 / fast::max(_683.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _683.light_color[i].w);\n            to_l = _1301 / float2(fast::max(_1304, 9.9999997473787516355514526367188e-05));\n            if (_683.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _683.light_shadow_v[i].x;\n                float param_1 = _683.light_shadow_v[i].y;\n                float2 param_2 = -_1301;\n                float param_3 = _683.light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1301;\n            att *= cookie_att(param_4, param_5, _683, light_smp, fx_cookie_tex);\n        }\n        sum += (_683.light_color[i].xyz * (att * fast::max(dot(_1255, to_l), 0.0)));\n    }\n    return (sum * _683.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_1166, _1177), fast::min(_1188, _1199))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(constant quad_fs_params& _683, thread float4& gl_FragCoord)\n{\n    float2 _734 = gl_FragCoord.xy * _683.fa_target.xy;\n    float _738 = _734.y;\n    return float2(_734.x, mix(_738, 1.0 - _738, _683.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, constant quad_fs_params& _683, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _774 = base_mode < 0.5;\n    bool _785;\n    if (!_774)\n    {\n        _785 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _785 = _774;\n    }\n    float _786;\n    if (_785)\n    {\n        _786 = shape_half.x;\n    }\n    else\n    {\n        _786 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(_683, gl_FragCoord), _683.fa_time.x, base_mode, float4(0.0), _786 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_scene_color(thread const float2& uv, constant quad_fs_params& _683, texture2d<float> fa_scene_tex, sampler light_smp)\n{\n    if (_683.fa_scene.x <= 0.0)\n    {\n        return float4(0.0);\n    }\n    float2 _703 = (uv * _683.fa_scene.xy) + _683.fa_scene.zw;\n    float _705 = _703.y;\n    _703.y = mix(_705, 1.0 - _705, _683.fa_target.z);\n    return fa_scene_tex.sample(light_smp, fast::clamp(_703, float2(0.0), float2(1.0)), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, constant quad_fs_params& _683, texture2d<float> fa_scene_tex, sampler light_smp, constant fa_material& _801)\n{\n    float2 param = i.screen_uv + (float2(_801.refraction + _801.strength, 0.0) * _683.fa_target.xy);\n    s.color = float4(mix(fa_scene_color(param, _683, fa_scene_tex, light_smp).xyz, _801.tint.xyz, float3(_801.tint.w)), 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _683 [[buffer(1)]], constant fa_material& _801 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> fx_emissive_tex [[texture(4)]], texture2d<float> fx_cookie_tex [[texture(5)]], texture2d<float> fa_scene_tex [[texture(6)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1698 = in.params.x > 31.5;\n    if (_1698)\n    {\n        mode -= 32.0;\n    }\n    float _1706 = mode;\n    bool _1708 = _1706 > 15.5;\n    if (_1708)\n    {\n        mode -= 16.0;\n    }\n    float _1716 = mode;\n    bool _1718 = _1716 > 7.5;\n    if (_1718)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1708)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, _683, light_smp, gl_FragCoord, in.uv, in.world_xy, fx_cookie_tex, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1708)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, _683, light_smp, gl_FragCoord, in.uv, in.world_xy, fx_cookie_tex, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1780 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1782 = _1780 * in.color;\n                float4 param_6 = _1782;\n                float param_7 = mode;\n                float _1789 = _1782.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, _683, light_smp, gl_FragCoord, in.uv, in.world_xy, fx_cookie_tex, normal_tex, in.params, light_tex), _1789);\n                if (_683.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1789;\n                    float param_9 = mode;\n                    float4 _1805 = out.frag_color;\n                    float3 _1807 = _1805.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _683, light_smp, in.uv, in.world_xy, fx_cookie_tex, in.params);\n                    out.frag_color.x = _1807.x;\n                    out.frag_color.y = _1807.y;\n                    out.frag_color.z = _1807.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1837 = length(in.uv);\n                    float _1840 = fwidth(_1837);\n                    float _1841 = fast::max(_1840, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1837) / _1841) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1837) / _1841) + 0.5, 0.0, 1.0) * fast::clamp(((_1837 - in.params.y) / _1841) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1881 = fast::clamp(1.0 - _1837, 0.0, 1.0);\n                            cov = (_1881 * _1881) * (3.0 - (2.0 * _1881));\n                        }\n                    }\n                    float3 _1890;\n                    if (_1708)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1890 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, _683, light_smp, gl_FragCoord, in.uv, in.world_xy, fx_cookie_tex, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1890 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1890, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_683.fx_emit.w > 0.5)\n    {\n        float3 e = _683.fx_emit.xyz;\n        if (_683.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _683.fx_emit_uv.xy) + _683.fx_emit_uv.zw)).xyz;\n            float param_13 = _683.fx_emit.w - 2.0;\n            float3 _1944 = fa_tex_fix(param_12, param_13);\n            e *= _1944;\n        }\n        float4 _1948 = out.frag_color;\n        float3 _1950 = _1948.xyz + e;\n        out.frag_color.x = _1950.x;\n        out.frag_color.y = _1950.y;\n        out.frag_color.z = _1950.z;\n    }\n    float param_14 = mode;\n    float4 _2275 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14, _683, gl_FragCoord, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _2275 };\n    fragment0(param_15, param_16, _683, fa_scene_tex, light_smp, _801);\n    _2275 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1698)\n    {\n        float4 _1976 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _1981 = scene_rgb(param_17, in.xform);\n        float3 _1985 = mix(_1976.xyz, _1981, float3(in.color2.w));\n        out.frag_color.x = _1985.x;\n        out.frag_color.y = _1985.y;\n        out.frag_color.z = _1985.z;\n    }\n    if (_1718)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _2008 = _683.fog_col.w > 0.0;\n    bool _2016;\n    if (!_2008)\n    {\n        _2016 = _683.fog_b.y > 0.0;\n    }\n    else\n    {\n        _2016 = _2008;\n    }\n    if (_2016)\n    {\n        float3 _2029 = float3(in.world_xy, in.world_z) - _683.fog_eye.xyz;\n        float _2036 = dot(_2029, _683.fog_c.xyz);\n        bool _2040 = _683.fog_c.w > 0.5;\n        float _2041;\n        if (_2040)\n        {\n            _2041 = _2036;\n        }\n        else\n        {\n            _2041 = length(_2029);\n        }\n        float _2053 = _2041 - _683.fog_b.x;\n        if (_2053 > 0.0)\n        {\n            float _2062 = _683.fog_col.w * _2053;\n            float tau = _2062 * _2062;\n            if (_683.fog_b.y > 0.0)\n            {\n                float _2078;\n                if (_2040)\n                {\n                    _2078 = in.world_xy.y - (_683.fog_c.y * _2036);\n                }\n                else\n                {\n                    _2078 = _683.fog_eye.y;\n                }\n                float _2099 = mix(_2078, in.world_xy.y, fast::clamp(_683.fog_b.x / _2041, 0.0, 1.0));\n                float _2103 = in.world_xy.y - _2099;\n                float _2108 = _2099 - _683.fog_b.z;\n                float _2113 = in.world_xy.y - _683.fog_b.z;\n                bool _2116 = _2108 <= 0.0;\n                bool _2117 = !_2116;\n                bool _2123;\n                if (_2117)\n                {\n                    _2123 = _683.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2123 = _2116;\n                }\n                float _2124;\n                if (_2123)\n                {\n                    _2124 = _683.fog_b.y;\n                }\n                else\n                {\n                    _2124 = _683.fog_b.y * exp(-fast::min(_683.fog_b.w * _2108, 80.0));\n                }\n                bool _2151;\n                if (_2117)\n                {\n                    _2151 = _683.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2151 = _2116;\n                }\n                float _2152;\n                if (_2151)\n                {\n                    _2152 = _683.fog_b.y * _2108;\n                }\n                else\n                {\n                    _2152 = (_683.fog_b.y * (1.0 - exp(-fast::min(_683.fog_b.w * _2108, 80.0)))) / _683.fog_b.w;\n                }\n                bool _2177 = _2113 <= 0.0;\n                bool _2184;\n                if (!_2177)\n                {\n                    _2184 = _683.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2184 = _2177;\n                }\n                float _2185;\n                if (_2184)\n                {\n                    _2185 = _683.fog_b.y * _2113;\n                }\n                else\n                {\n                    _2185 = (_683.fog_b.y * (1.0 - exp(-fast::min(_683.fog_b.w * _2113, 80.0)))) / _683.fog_b.w;\n                }\n                float _2212;\n                if (abs(_2103) < 0.001000000047497451305389404296875)\n                {\n                    _2212 = _2124;\n                }\n                else\n                {\n                    _2212 = (_2185 - _2152) / _2103;\n                }\n                tau += (_2053 * fast::max(_2212, 0.0));\n            }\n            float4 _2235 = out.frag_color;\n            float3 _2243 = mix(_2235.xyz, _683.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _2243.x;\n            out.frag_color.y = _2243.y;\n            out.frag_color.z = _2243.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "inst_name": "_683",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 128,
            "struct_name": "fa_material",
            "inst_name": "_801",
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
              "name": "fa_scene_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 6
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
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_scene_tex_light_smp",
            "view_name": "fa_scene_tex",
            "sampler_name": "light_smp",
            "view_slot": 14,
            "sampler_slot": 1
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _147 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _147;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n};\n\nstruct fa_material\n{\n    float reflection;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float refraction;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n    float2 size;\n    float fa_pad6;\n    float fa_pad7;\n    float strength;\n    float fa_pad8;\n    float fa_pad9;\n    float fa_pad10;\n    float4 tint;\n    float waveAmplitude;\n    float fa_pad11;\n    float fa_pad12;\n    float fa_pad13;\n    float waveLength;\n    float fa_pad14;\n    float fa_pad15;\n    float fa_pad16;\n    float waveSpeed;\n    float fa_pad17;\n    float fa_pad18;\n    float fa_pad19;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _106 = fa_linear_to_srgb(param);\n        c = _106;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _115 = fa_srgb_to_linear(param_1);\n            c = _115;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(constant quad_fs_params& _130, thread float4& gl_FragCoord)\n{\n    float2 _191 = gl_FragCoord.xy * _130.fa_target.xy;\n    float _195 = _191.y;\n    return float2(_191.x, mix(_195, 1.0 - _195, _130.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, constant quad_fs_params& _130, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _235 = base_mode < 0.5;\n    bool _246;\n    if (!_235)\n    {\n        _246 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _246 = _235;\n    }\n    float _247;\n    if (_246)\n    {\n        _247 = shape_half.x;\n    }\n    else\n    {\n        _247 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(_130, gl_FragCoord), _130.fa_time.x, base_mode, float4(0.0), _247 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_scene_color(thread const float2& uv, constant quad_fs_params& _130, texture2d<float> fa_scene_tex, sampler light_smp)\n{\n    if (_130.fa_scene.x <= 0.0)\n    {\n        return float4(0.0);\n    }\n    float2 _152 = (uv * _130.fa_scene.xy) + _130.fa_scene.zw;\n    float _155 = _152.y;\n    _152.y = mix(_155, 1.0 - _155, _130.fa_target.z);\n    return fa_scene_tex.sample(light_smp, fast::clamp(_152, float2(0.0), float2(1.0)), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, constant quad_fs_params& _130, texture2d<float> fa_scene_tex, sampler light_smp, constant fa_material& _263)\n{\n    float2 param = i.screen_uv + (float2(_263.refraction + _263.strength, 0.0) * _130.fa_target.xy);\n    s.color = float4(mix(fa_scene_color(param, _130, fa_scene_tex, light_smp).xyz, _263.tint.xyz, float3(_263.tint.w)), 1.0);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _130 [[buffer(1)]], constant fa_material& _263 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> fa_scene_tex [[texture(1)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _330 = tex.sample(smp, in.uv);\n    float3 param = _330.xyz;\n    float param_1 = in.xform.y;\n    float3 _341 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_341, _330.w) * in.color;\n    float param_2 = 0.0;\n    float4 _394 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, _130, gl_FragCoord, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _394 };\n    fragment0(param_3, param_4, _130, fa_scene_tex, light_smp, _263);\n    _394 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
              "slot": 14,
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
            "view_slot": 14,
            "sampler_slot": 1
          }
        ]
      }
    }
  }
}
