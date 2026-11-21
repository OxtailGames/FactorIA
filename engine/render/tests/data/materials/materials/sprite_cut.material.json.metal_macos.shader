{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "c463ccd1917be78236231aa4aa6bc7a9036af5c2e4c419a950fb6e8c51e433a6",
  "slang": "metal_macos",
  "params": [
    "cut",
    "cutY"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _147 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _147;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 gi_xf;\n    float4 gi_p;\n};\n\nstruct fa_material\n{\n    float cut;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float cutY;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _625 = fa_linear_to_srgb(param);\n        c = _625;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _633 = fa_srgb_to_linear(param_1);\n            c = _633;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _644 = tex.sample(smp, p);\n    float3 param = _644.xyz;\n    float param_1 = xform.y;\n    float3 _654 = fa_tex_fix(param, param_1);\n    return float4(_654, _644.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 gi_irradiance(constant quad_fs_params& _687, thread float2& world_xy, sampler light_smp, texture2d<float> fx_gi_tex)\n{\n    float2 _826 = (world_xy * _687.gi_xf.xy) + _687.gi_xf.zw;\n    float4 _833 = fx_gi_tex.sample(light_smp, _826, level(0.0));\n    float _837 = _826.x;\n    bool _838 = _837 >= 0.0;\n    bool _844;\n    if (_838)\n    {\n        _844 = _826.y >= 0.0;\n    }\n    else\n    {\n        _844 = _838;\n    }\n    bool _850;\n    if (_844)\n    {\n        _850 = _837 <= 1.0;\n    }\n    else\n    {\n        _850 = _844;\n    }\n    bool _856;\n    if (_850)\n    {\n        _856 = _826.y <= 1.0;\n    }\n    else\n    {\n        _856 = _850;\n    }\n    bool _864;\n    if (_856)\n    {\n        _864 = _833.w > 0.0199999995529651641845703125;\n    }\n    else\n    {\n        _864 = _856;\n    }\n    float3 _865;\n    if (_864)\n    {\n        _865 = (_833.xyz / float3(_833.w)) * _687.gi_p.x;\n    }\n    else\n    {\n        _865 = float3(0.0);\n    }\n    return _865;\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _134 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_134.x * 255.0) + 0.5) * 256.0) + floor((_134.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_tap(thread const float& v, thread const float& tt, thread const float& dist, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _237 = floor(tt);\n    float _247 = _237 - (1024.0 * floor(_237 * 0.0009765625));\n    float _250 = _247 + 1.0;\n    float i1 = _250;\n    if (_250 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _247;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), tt - _237);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_soft(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _287 = length(d);\n    float result = 1.0;\n    if (_287 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _298 = precise::atan2(d.y, d.x);\n        float a = _298;\n        float _301;\n        if (_298 < 0.0)\n        {\n            _301 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _301 = a;\n        }\n        a = _301;\n        float _311 = _301 * 162.9746551513671875;\n        float _320 = fast::min((size * 10.0) / _287, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _346 = floor(_311 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _320));\n            float param = v;\n            float param_1 = _346 - (1024.0 * floor(_346 * 0.0009765625));\n            float _360 = shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius;\n            if (_360 < _287)\n            {\n                sum += _360;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _392 = fast::min(size * ((1.0 / fast::max(sum / n, 1.0)) - (1.0 / _287)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _410 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _416 = 1.0 - (0.800000011920928955078125 * abs(_410));\n                float param_2 = v;\n                float param_3 = _311 + (_410 * _392);\n                float param_4 = _287;\n                float param_5 = radius;\n                acc += (_416 * light_shadow_tap(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp));\n                wsum += _416;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _158 = length(d);\n    if (_158 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _172 = precise::atan2(d.y, d.x);\n    float a = _172;\n    float _175;\n    if (_172 < 0.0)\n    {\n        _175 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _175 = a;\n    }\n    a = _175;\n    float _187 = _175 * 162.9746551513671875;\n    float _192 = fast::min(floor(_187), 1023.0);\n    float _199 = _192 + 1.0;\n    float i1 = _199;\n    if (_199 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _192;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _158) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _158) + 0.5, 0.0, 1.0), _187 - _192);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_sized(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6, shadow_tex, shadow_smp);\n    }\n    return r;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _497 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _501 = _497.x + 0.5;\n    float2 c = float2(_501, 0.5 - _497.y);\n    bool _509 = _501 >= 0.0;\n    bool _515;\n    if (_509)\n    {\n        _515 = c.x <= 1.0;\n    }\n    else\n    {\n        _515 = _509;\n    }\n    bool _521;\n    if (_515)\n    {\n        _521 = c.y >= 0.0;\n    }\n    else\n    {\n        _521 = _515;\n    }\n    bool _527;\n    if (_521)\n    {\n        _527 = c.y <= 1.0;\n    }\n    else\n    {\n        _527 = _521;\n    }\n    float2 _529 = c;\n    float2 _534 = fast::clamp(_529, float2(0.001953125), float2(0.998046875));\n    c = _534;\n    return float3(cell.x + (_534.x * cell.w), cell.y + (_534.y * cell.z), float(_527));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _687, texture2d<float> fx_cookie_tex, sampler light_smp)\n{\n    if (_687.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _687.light_cookie[i];\n    float4 param_1 = _687.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _800 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _800.xy, level(0.0));\n    return cookie_value(param_3) * _800.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _687, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, texture2d<float> fx_gi_tex, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _887 = _687.lit.y > 0.5;\n    if (_887)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _687.normal_uv.xy) + _687.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _911 = fa_tex_fix(param, param_1);\n        float3 _915 = (_911 * 2.0) - float3(1.0);\n        float _922 = cos(params.y);\n        float _924 = sin(params.y);\n        n = fast::normalize(float3((float2(_922, _924) * _915.x) + ((float2(-_924, _922) * ((mode > 5.5) ? (-1.0) : 1.0)) * _915.y), fast::max(_915.z, 0.0500000007450580596923828125)));\n    }\n    bool _958 = !_887;\n    bool _964;\n    if (_958)\n    {\n        _964 = _687.lit.z > 0.5;\n    }\n    else\n    {\n        _964 = _958;\n    }\n    float3 _967;\n    if (_964)\n    {\n        _967 = _687.flat_ambient.xyz;\n    }\n    else\n    {\n        _967 = _687.ambient.xyz;\n    }\n    float3 total = _967;\n    if (_687.gi_p.x > 0.0)\n    {\n        total += gi_irradiance(_687, world_xy, light_smp, fx_gi_tex);\n    }\n    bool _992;\n    if (_964)\n    {\n        _992 = _687.lit.z < 1.5;\n    }\n    else\n    {\n        _992 = _964;\n    }\n    if (_992)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _687.light_map.xy), level(0.0)).xyz * _687.light_map.z);\n    }\n    float3 l;\n    float _1119;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1029;\n        if (!_964)\n        {\n            _1029 = float(i) >= _687.lit.x;\n        }\n        else\n        {\n            _1029 = _964;\n        }\n        if (_1029)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_687.light_pos[i].w < 0.0)\n        {\n            l = _687.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _1055 = _687.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_1055) / fast::max(_687.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _687.light_color[i].w);\n            float3 _1075 = float3(_1055, _687.light_pos[i].z);\n            l = _1075 / float3(fast::max(length(_1075), 9.9999997473787516355514526367188e-05));\n            if (_687.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _687.light_shadow_v[i].x;\n                float param_3 = _687.light_shadow_v[i].y;\n                float2 param_4 = -_1055;\n                float param_5 = _687.light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp);\n            }\n            int param_6 = i;\n            float2 param_7 = -_1055;\n            att *= cookie_att(param_6, param_7, _687, fx_cookie_tex, light_smp);\n        }\n        if (_887)\n        {\n            _1119 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1119 = 1.0;\n        }\n        total += (_687.light_color[i].xyz * (att * _1119));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _670 = fa_srgb_to_linear(param);\n        c = _670;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1369 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1373 = uv * _1369;\n    float _1379 = _1369.x;\n    float _1381 = _1369.y;\n    float _1383 = fast::clamp(shape_rs.x, 0.0, fast::min(_1379, _1381));\n    float2 _1394 = (abs(_1373) - _1369) + float2(_1383);\n    float d = (length(fast::max(_1394, float2(0.0))) + fast::min(fast::max(_1394.x, _1394.y), 0.0)) - _1383;\n    float ax = params.y;\n    bool _1415 = params.y > 15.0;\n    if (_1415)\n    {\n        ax -= 20.0;\n    }\n    float _1426;\n    if (ax <= (-1.5))\n    {\n        _1426 = (-2.0) - ax;\n    }\n    else\n    {\n        _1426 = 0.0;\n    }\n    if (_1426 > 0.0)\n    {\n        float _1440 = _1426 * 0.5;\n        d = abs(d + _1440) - _1440;\n    }\n    float _1448 = fwidth(d);\n    float _1449 = fast::max(_1448, 9.9999997473787516355514526367188e-05);\n    float _1459 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1449)), 0.0, 1.0);\n    float _1464;\n    if (shape_rs.y > _1449)\n    {\n        _1464 = (_1459 * _1459) * (3.0 - (2.0 * _1459));\n    }\n    else\n    {\n        _1464 = _1459;\n    }\n    float4 c = color;\n    bool _1486 = (_1426 <= 0.0) && (ax > (-0.5));\n    if (_1486)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1501 = cos(ax);\n            float _1503 = sin(ax);\n            g = ((dot(_1373, float2(_1501, _1503)) / fast::max((abs(_1501) * _1379) + (abs(_1503) * _1381), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1415)\n        {\n            float4 _1546 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1546;\n            float3 param = _1546.xyz;\n            float param_1 = xform.y;\n            float3 _1553 = fa_tex_fix(param, param_1);\n            float4 _2347 = c;\n            _2347.x = _1553.x;\n            _2347.y = _1553.y;\n            _2347.z = _1553.z;\n            c = _2347;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1565 = scene_rgb(param_2, xform);\n            float4 _1590 = mix(float4(color.xyz * color.w, color.w), float4(_1565 * color2.w, color2.w), float4(g));\n            float _1592 = _1590.w;\n            float3 _1595;\n            if (_1592 > 9.9999997473787516355514526367188e-06)\n            {\n                _1595 = _1590.xyz / float3(_1592);\n            }\n            else\n            {\n                _1595 = color.xyz;\n            }\n            c = float4(_1595, _1592);\n        }\n    }\n    float4 _2356 = c;\n    _2356.w = _2356.w * _1464;\n    c = _2356;\n    if (_1486 || (shape_rs.y > 0.0))\n    {\n        float _1636 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1645 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1645 + float3(_1636 * 0.0039215688593685626983642578125);\n            float3 _1651 = fa_srgb_to_linear(param_4);\n            float4 _2359 = c;\n            _2359.x = _1651.x;\n            _2359.y = _1651.y;\n            _2359.z = _1651.z;\n            c = _2359;\n        }\n        else\n        {\n            float4 _1661 = c;\n            float3 _1664 = _1661.xyz + float3(_1636 * 0.0039215688593685626983642578125);\n            float4 _2366 = _1661;\n            _2366.x = _1664.x;\n            _2366.y = _1664.y;\n            _2366.z = _1664.z;\n            c = _2366;\n        }\n        float4 _2371 = c;\n        _2371.w = fast::clamp(_2371.w + ((_1636 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2371.w)), 0.0, 1.0);\n        c = _2371;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _687, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, thread float2& params)\n{\n    float2 _1156 = float2(_687.fx_rim_uv.x, 0.0);\n    float4 _1158 = tex.sample(smp, (uv - _1156));\n    float _1159 = _1158.w;\n    float4 _1169 = tex.sample(smp, (uv + _1156));\n    float _1170 = _1169.w;\n    float2 _1178 = float2(0.0, _687.fx_rim_uv.y);\n    float4 _1180 = tex.sample(smp, (uv - _1178));\n    float _1181 = _1180.w;\n    float4 _1191 = tex.sample(smp, (uv + _1178));\n    float _1192 = _1191.w;\n    float _1207 = _1159 - _1170;\n    float _1210 = _1192 - _1181;\n    float _1220 = cos(params.y);\n    float _1222 = sin(params.y);\n    float2 _1248 = ((float2(_1220, _1222) * _1207) + ((float2(-_1222, _1220) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1210)) / float2(fast::max(length(float2(_1207, _1210)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _687.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_687.light_pos[i].w < 0.0)\n        {\n            to_l = _687.light_pos[i].xy / float2(fast::max(length(_687.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _1294 = _687.light_pos[i].xy - world_xy;\n            float _1297 = length(_1294);\n            att = powr(fast::clamp(1.0 - (_1297 / fast::max(_687.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _687.light_color[i].w);\n            to_l = _1294 / float2(fast::max(_1297, 9.9999997473787516355514526367188e-05));\n            if (_687.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _687.light_shadow_v[i].x;\n                float param_1 = _687.light_shadow_v[i].y;\n                float2 param_2 = -_1294;\n                float param_3 = _687.light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1294;\n            att *= cookie_att(param_4, param_5, _687, fx_cookie_tex, light_smp);\n        }\n        sum += (_687.light_color[i].xyz * (att * fast::max(dot(_1248, to_l), 0.0)));\n    }\n    return (sum * _687.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_1159, _1170), fast::min(_1181, _1192))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _687)\n{\n    float2 _693 = gl_FragCoord.xy * _687.fa_target.xy;\n    float _697 = _693.y;\n    return float2(_693.x, mix(_697, 1.0 - _697, _687.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _687, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _735 = base_mode < 0.5;\n    bool _746;\n    if (!_735)\n    {\n        _746 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _746 = _735;\n    }\n    float _747;\n    if (_746)\n    {\n        _747 = shape_half.x;\n    }\n    else\n    {\n        _747 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _687), _687.fa_time.x, base_mode, float4(0.0), _747 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread const QuadSurface& s, constant fa_material& _763)\n{\n    bool _766 = i.screen_uv.x < _763.cut;\n    bool _775;\n    if (!_766)\n    {\n        _775 = i.screen_uv.y < _763.cutY;\n    }\n    else\n    {\n        _775 = _766;\n    }\n    if (_775)\n    {\n        discard_fragment();\n    }\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _687 [[buffer(1)]], constant fa_material& _763 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> fx_emissive_tex [[texture(4)]], texture2d<float> fx_cookie_tex [[texture(5)]], texture2d<float> fx_gi_tex [[texture(6)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1691 = in.params.x > 31.5;\n    if (_1691)\n    {\n        mode -= 32.0;\n    }\n    float _1699 = mode;\n    bool _1701 = _1699 > 15.5;\n    if (_1701)\n    {\n        mode -= 16.0;\n    }\n    float _1709 = mode;\n    bool _1711 = _1709 > 7.5;\n    if (_1711)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1701)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _687, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1701)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _687, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1773 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1775 = _1773 * in.color;\n                float4 param_6 = _1775;\n                float param_7 = mode;\n                float _1782 = _1775.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _687, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), _1782);\n                if (_687.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1782;\n                    float param_9 = mode;\n                    float4 _1798 = out.frag_color;\n                    float3 _1800 = _1798.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _687, in.uv, in.world_xy, fx_cookie_tex, light_smp, in.params);\n                    out.frag_color.x = _1800.x;\n                    out.frag_color.y = _1800.y;\n                    out.frag_color.z = _1800.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1830 = length(in.uv);\n                    float _1833 = fwidth(_1830);\n                    float _1834 = fast::max(_1833, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1830) / _1834) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1830) / _1834) + 0.5, 0.0, 1.0) * fast::clamp(((_1830 - in.params.y) / _1834) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1874 = fast::clamp(1.0 - _1830, 0.0, 1.0);\n                            cov = (_1874 * _1874) * (3.0 - (2.0 * _1874));\n                        }\n                    }\n                    float3 _1883;\n                    if (_1701)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1883 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _687, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1883 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1883, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_687.fx_emit.w > 0.5)\n    {\n        float3 e = _687.fx_emit.xyz;\n        if (_687.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _687.fx_emit_uv.xy) + _687.fx_emit_uv.zw)).xyz;\n            float param_13 = _687.fx_emit.w - 2.0;\n            float3 _1938 = fa_tex_fix(param_12, param_13);\n            e *= _1938;\n        }\n        float4 _1942 = out.frag_color;\n        float3 _1944 = _1942.xyz + e;\n        out.frag_color.x = _1944.x;\n        out.frag_color.y = _1944.y;\n        out.frag_color.z = _1944.z;\n    }\n    float param_14 = mode;\n    float4 _2271 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14, gl_FragCoord, _687, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _2271 };\n    fragment0(param_15, param_16, _763);\n    _2271 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1691)\n    {\n        float4 _1970 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _1975 = scene_rgb(param_17, in.xform);\n        float3 _1979 = mix(_1970.xyz, _1975, float3(in.color2.w));\n        out.frag_color.x = _1979.x;\n        out.frag_color.y = _1979.y;\n        out.frag_color.z = _1979.z;\n    }\n    if (_1711)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _2003 = _687.fog_col.w > 0.0;\n    bool _2011;\n    if (!_2003)\n    {\n        _2011 = _687.fog_b.y > 0.0;\n    }\n    else\n    {\n        _2011 = _2003;\n    }\n    if (_2011)\n    {\n        float3 _2025 = float3(in.world_xy, in.world_z) - _687.fog_eye.xyz;\n        float _2032 = dot(_2025, _687.fog_c.xyz);\n        bool _2036 = _687.fog_c.w > 0.5;\n        float _2037;\n        if (_2036)\n        {\n            _2037 = _2032;\n        }\n        else\n        {\n            _2037 = length(_2025);\n        }\n        float _2049 = _2037 - _687.fog_b.x;\n        if (_2049 > 0.0)\n        {\n            float _2058 = _687.fog_col.w * _2049;\n            float tau = _2058 * _2058;\n            if (_687.fog_b.y > 0.0)\n            {\n                float _2074;\n                if (_2036)\n                {\n                    _2074 = in.world_xy.y - (_687.fog_c.y * _2032);\n                }\n                else\n                {\n                    _2074 = _687.fog_eye.y;\n                }\n                float _2095 = mix(_2074, in.world_xy.y, fast::clamp(_687.fog_b.x / _2037, 0.0, 1.0));\n                float _2099 = in.world_xy.y - _2095;\n                float _2104 = _2095 - _687.fog_b.z;\n                float _2109 = in.world_xy.y - _687.fog_b.z;\n                bool _2112 = _2104 <= 0.0;\n                bool _2113 = !_2112;\n                bool _2119;\n                if (_2113)\n                {\n                    _2119 = _687.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2119 = _2112;\n                }\n                float _2120;\n                if (_2119)\n                {\n                    _2120 = _687.fog_b.y;\n                }\n                else\n                {\n                    _2120 = _687.fog_b.y * exp(-fast::min(_687.fog_b.w * _2104, 80.0));\n                }\n                bool _2147;\n                if (_2113)\n                {\n                    _2147 = _687.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2147 = _2112;\n                }\n                float _2148;\n                if (_2147)\n                {\n                    _2148 = _687.fog_b.y * _2104;\n                }\n                else\n                {\n                    _2148 = (_687.fog_b.y * (1.0 - exp(-fast::min(_687.fog_b.w * _2104, 80.0)))) / _687.fog_b.w;\n                }\n                bool _2173 = _2109 <= 0.0;\n                bool _2180;\n                if (!_2173)\n                {\n                    _2180 = _687.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2180 = _2173;\n                }\n                float _2181;\n                if (_2180)\n                {\n                    _2181 = _687.fog_b.y * _2109;\n                }\n                else\n                {\n                    _2181 = (_687.fog_b.y * (1.0 - exp(-fast::min(_687.fog_b.w * _2109, 80.0)))) / _687.fog_b.w;\n                }\n                float _2208;\n                if (abs(_2099) < 0.001000000047497451305389404296875)\n                {\n                    _2208 = _2120;\n                }\n                else\n                {\n                    _2208 = (_2181 - _2148) / _2099;\n                }\n                tau += (_2049 * fast::max(_2208, 0.0));\n            }\n            float4 _2231 = out.frag_color;\n            float3 _2239 = mix(_2231.xyz, _687.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _2239.x;\n            out.frag_color.y = _2239.y;\n            out.frag_color.z = _2239.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "size": 1552,
            "struct_name": "quad_fs_params",
            "inst_name": "_687",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_763",
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
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _147 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _147;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 gi_xf;\n    float4 gi_p;\n};\n\nstruct fa_material\n{\n    float cut;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float cutY;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _129)\n{\n    float2 _136 = gl_FragCoord.xy * _129.fa_target.xy;\n    float _142 = _136.y;\n    return float2(_136.x, mix(_142, 1.0 - _142, _129.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _129, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _186 = base_mode < 0.5;\n    bool _197;\n    if (!_186)\n    {\n        _197 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _197 = _186;\n    }\n    float _198;\n    if (_197)\n    {\n        _198 = shape_half.x;\n    }\n    else\n    {\n        _198 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _129), _129.fa_time.x, base_mode, float4(0.0), _198 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread const QuadSurface& s, constant fa_material& _215)\n{\n    bool _218 = i.screen_uv.x < _215.cut;\n    bool _227;\n    if (!_218)\n    {\n        _227 = i.screen_uv.y < _215.cutY;\n    }\n    else\n    {\n        _227 = _218;\n    }\n    if (_227)\n    {\n        discard_fragment();\n    }\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _129 [[buffer(1)]], constant fa_material& _215 [[buffer(5)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _243 = tex.sample(smp, in.uv);\n    float3 param = _243.xyz;\n    float param_1 = in.xform.y;\n    float3 _254 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_254, _243.w) * in.color;\n    float param_2 = 0.0;\n    float4 _308 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _129, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _308 };\n    fragment0(param_3, param_4, _215);\n    _308 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "size": 1552,
            "struct_name": "quad_fs_params",
            "inst_name": "_129",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_215",
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
