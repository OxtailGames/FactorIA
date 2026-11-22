{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "d75bc1c2988d2355d3b6c4618a7c68ff76094f3e9d32765c88b7244d10541da4",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _144 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _144;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n    float4 gi_xf;\n    float4 gi_p;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _625 = fa_linear_to_srgb(param);\n        c = _625;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _633 = fa_srgb_to_linear(param_1);\n            c = _633;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _644 = tex.sample(smp, p);\n    float3 param = _644.xyz;\n    float param_1 = xform.y;\n    float3 _654 = fa_tex_fix(param, param_1);\n    return float4(_654, _644.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 gi_irradiance(constant quad_fs_params& _688, thread float2& world_xy, sampler light_smp, texture2d<float> fx_gi_tex)\n{\n    float2 _816 = (world_xy * _688.gi_xf.xy) + _688.gi_xf.zw;\n    float4 _823 = fx_gi_tex.sample(light_smp, _816, level(0.0));\n    float _827 = _816.x;\n    bool _828 = _827 >= 0.0;\n    bool _834;\n    if (_828)\n    {\n        _834 = _816.y >= 0.0;\n    }\n    else\n    {\n        _834 = _828;\n    }\n    bool _840;\n    if (_834)\n    {\n        _840 = _827 <= 1.0;\n    }\n    else\n    {\n        _840 = _834;\n    }\n    bool _846;\n    if (_840)\n    {\n        _846 = _816.y <= 1.0;\n    }\n    else\n    {\n        _846 = _840;\n    }\n    bool _854;\n    if (_846)\n    {\n        _854 = _823.w > 0.0199999995529651641845703125;\n    }\n    else\n    {\n        _854 = _846;\n    }\n    float3 _855;\n    if (_854)\n    {\n        _855 = (_823.xyz / float3(_823.w)) * _688.gi_p.x;\n    }\n    else\n    {\n        _855 = float3(0.0);\n    }\n    return _855;\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _134 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_134.x * 255.0) + 0.5) * 256.0) + floor((_134.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_tap(thread const float& v, thread const float& tt, thread const float& dist, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _237 = floor(tt);\n    float _247 = _237 - (1024.0 * floor(_237 * 0.0009765625));\n    float _250 = _247 + 1.0;\n    float i1 = _250;\n    if (_250 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _247;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), tt - _237);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_soft(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _287 = length(d);\n    float result = 1.0;\n    if (_287 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _298 = precise::atan2(d.y, d.x);\n        float a = _298;\n        float _301;\n        if (_298 < 0.0)\n        {\n            _301 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _301 = a;\n        }\n        a = _301;\n        float _311 = _301 * 162.9746551513671875;\n        float _320 = fast::min((size * 10.0) / _287, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _346 = floor(_311 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _320));\n            float param = v;\n            float param_1 = _346 - (1024.0 * floor(_346 * 0.0009765625));\n            float _360 = shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius;\n            if (_360 < _287)\n            {\n                sum += _360;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _392 = fast::min(size * ((1.0 / fast::max(sum / n, 1.0)) - (1.0 / _287)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _410 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _416 = 1.0 - (0.800000011920928955078125 * abs(_410));\n                float param_2 = v;\n                float param_3 = _311 + (_410 * _392);\n                float param_4 = _287;\n                float param_5 = radius;\n                acc += (_416 * light_shadow_tap(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp));\n                wsum += _416;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _158 = length(d);\n    if (_158 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _172 = precise::atan2(d.y, d.x);\n    float a = _172;\n    float _175;\n    if (_172 < 0.0)\n    {\n        _175 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _175 = a;\n    }\n    a = _175;\n    float _187 = _175 * 162.9746551513671875;\n    float _192 = fast::min(floor(_187), 1023.0);\n    float _199 = _192 + 1.0;\n    float i1 = _199;\n    if (_199 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _192;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _158) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _158) + 0.5, 0.0, 1.0), _187 - _192);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_sized(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6, shadow_tex, shadow_smp);\n    }\n    return r;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _497 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _501 = _497.x + 0.5;\n    float2 c = float2(_501, 0.5 - _497.y);\n    bool _509 = _501 >= 0.0;\n    bool _515;\n    if (_509)\n    {\n        _515 = c.x <= 1.0;\n    }\n    else\n    {\n        _515 = _509;\n    }\n    bool _521;\n    if (_515)\n    {\n        _521 = c.y >= 0.0;\n    }\n    else\n    {\n        _521 = _515;\n    }\n    bool _527;\n    if (_521)\n    {\n        _527 = c.y <= 1.0;\n    }\n    else\n    {\n        _527 = _521;\n    }\n    float2 _529 = c;\n    float2 _534 = fast::clamp(_529, float2(0.001953125), float2(0.998046875));\n    c = _534;\n    return float3(cell.x + (_534.x * cell.w), cell.y + (_534.y * cell.z), float(_527));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _688, texture2d<float> fx_cookie_tex, sampler light_smp)\n{\n    if (_688.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _688.light_cookie[i];\n    float4 param_1 = _688.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _790 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _790.xy, level(0.0));\n    return cookie_value(param_3) * _790.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _688, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, texture2d<float> fx_gi_tex, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _877 = _688.lit.y > 0.5;\n    if (_877)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _688.normal_uv.xy) + _688.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _901 = fa_tex_fix(param, param_1);\n        float3 _905 = (_901 * 2.0) - float3(1.0);\n        float _912 = cos(params.y);\n        float _914 = sin(params.y);\n        n = fast::normalize(float3((float2(_912, _914) * _905.x) + ((float2(-_914, _912) * ((mode > 5.5) ? (-1.0) : 1.0)) * _905.y), fast::max(_905.z, 0.0500000007450580596923828125)));\n    }\n    bool _948 = !_877;\n    bool _954;\n    if (_948)\n    {\n        _954 = _688.lit.z > 0.5;\n    }\n    else\n    {\n        _954 = _948;\n    }\n    float3 _957;\n    if (_954)\n    {\n        _957 = _688.flat_ambient.xyz;\n    }\n    else\n    {\n        _957 = _688.ambient.xyz;\n    }\n    float3 total = _957;\n    if (_688.gi_p.x > 0.0)\n    {\n        total += gi_irradiance(_688, world_xy, light_smp, fx_gi_tex);\n    }\n    bool _982;\n    if (_954)\n    {\n        _982 = _688.lit.z < 1.5;\n    }\n    else\n    {\n        _982 = _954;\n    }\n    if (_982)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _688.light_map.xy), level(0.0)).xyz * _688.light_map.z);\n    }\n    float3 l;\n    float _1109;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1019;\n        if (!_954)\n        {\n            _1019 = float(i) >= _688.lit.x;\n        }\n        else\n        {\n            _1019 = _954;\n        }\n        if (_1019)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_688.light_pos[i].w < 0.0)\n        {\n            l = _688.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _1045 = _688.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_1045) / fast::max(_688.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _688.light_color[i].w);\n            float3 _1065 = float3(_1045, _688.light_pos[i].z);\n            l = _1065 / float3(fast::max(length(_1065), 9.9999997473787516355514526367188e-05));\n            if (_688.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _688.light_shadow_v[i].x;\n                float param_3 = _688.light_shadow_v[i].y;\n                float2 param_4 = -_1045;\n                float param_5 = _688.light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp);\n            }\n            int param_6 = i;\n            float2 param_7 = -_1045;\n            att *= cookie_att(param_6, param_7, _688, fx_cookie_tex, light_smp);\n        }\n        if (_877)\n        {\n            _1109 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1109 = 1.0;\n        }\n        total += (_688.light_color[i].xyz * (att * _1109));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _670 = fa_srgb_to_linear(param);\n        c = _670;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1359 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1363 = uv * _1359;\n    float _1369 = _1359.x;\n    float _1371 = _1359.y;\n    float _1373 = fast::clamp(shape_rs.x, 0.0, fast::min(_1369, _1371));\n    float2 _1384 = (abs(_1363) - _1359) + float2(_1373);\n    float d = (length(fast::max(_1384, float2(0.0))) + fast::min(fast::max(_1384.x, _1384.y), 0.0)) - _1373;\n    float ax = params.y;\n    bool _1405 = params.y > 15.0;\n    if (_1405)\n    {\n        ax -= 20.0;\n    }\n    float _1416;\n    if (ax <= (-1.5))\n    {\n        _1416 = (-2.0) - ax;\n    }\n    else\n    {\n        _1416 = 0.0;\n    }\n    if (_1416 > 0.0)\n    {\n        float _1430 = _1416 * 0.5;\n        d = abs(d + _1430) - _1430;\n    }\n    float _1438 = fwidth(d);\n    float _1439 = fast::max(_1438, 9.9999997473787516355514526367188e-05);\n    float _1449 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1439)), 0.0, 1.0);\n    float _1454;\n    if (shape_rs.y > _1439)\n    {\n        _1454 = (_1449 * _1449) * (3.0 - (2.0 * _1449));\n    }\n    else\n    {\n        _1454 = _1449;\n    }\n    float4 c = color;\n    bool _1476 = (_1416 <= 0.0) && (ax > (-0.5));\n    if (_1476)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1491 = cos(ax);\n            float _1493 = sin(ax);\n            g = ((dot(_1363, float2(_1491, _1493)) / fast::max((abs(_1491) * _1369) + (abs(_1493) * _1371), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1405)\n        {\n            float4 _1536 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1536;\n            float3 param = _1536.xyz;\n            float param_1 = xform.y;\n            float3 _1543 = fa_tex_fix(param, param_1);\n            float4 _2338 = c;\n            _2338.x = _1543.x;\n            _2338.y = _1543.y;\n            _2338.z = _1543.z;\n            c = _2338;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1555 = scene_rgb(param_2, xform);\n            float4 _1580 = mix(float4(color.xyz * color.w, color.w), float4(_1555 * color2.w, color2.w), float4(g));\n            float _1582 = _1580.w;\n            float3 _1585;\n            if (_1582 > 9.9999997473787516355514526367188e-06)\n            {\n                _1585 = _1580.xyz / float3(_1582);\n            }\n            else\n            {\n                _1585 = color.xyz;\n            }\n            c = float4(_1585, _1582);\n        }\n    }\n    float4 _2347 = c;\n    _2347.w = _2347.w * _1454;\n    c = _2347;\n    if (_1476 || (shape_rs.y > 0.0))\n    {\n        float _1626 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1635 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1635 + float3(_1626 * 0.0039215688593685626983642578125);\n            float3 _1641 = fa_srgb_to_linear(param_4);\n            float4 _2350 = c;\n            _2350.x = _1641.x;\n            _2350.y = _1641.y;\n            _2350.z = _1641.z;\n            c = _2350;\n        }\n        else\n        {\n            float4 _1651 = c;\n            float3 _1654 = _1651.xyz + float3(_1626 * 0.0039215688593685626983642578125);\n            float4 _2357 = _1651;\n            _2357.x = _1654.x;\n            _2357.y = _1654.y;\n            _2357.z = _1654.z;\n            c = _2357;\n        }\n        float4 _2362 = c;\n        _2362.w = fast::clamp(_2362.w + ((_1626 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2362.w)), 0.0, 1.0);\n        c = _2362;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _688, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, thread float2& params)\n{\n    float2 _1146 = float2(_688.fx_rim_uv.x, 0.0);\n    float4 _1148 = tex.sample(smp, (uv - _1146));\n    float _1149 = _1148.w;\n    float4 _1159 = tex.sample(smp, (uv + _1146));\n    float _1160 = _1159.w;\n    float2 _1168 = float2(0.0, _688.fx_rim_uv.y);\n    float4 _1170 = tex.sample(smp, (uv - _1168));\n    float _1171 = _1170.w;\n    float4 _1181 = tex.sample(smp, (uv + _1168));\n    float _1182 = _1181.w;\n    float _1197 = _1149 - _1160;\n    float _1200 = _1182 - _1171;\n    float _1210 = cos(params.y);\n    float _1212 = sin(params.y);\n    float2 _1238 = ((float2(_1210, _1212) * _1197) + ((float2(-_1212, _1210) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1200)) / float2(fast::max(length(float2(_1197, _1200)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _688.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_688.light_pos[i].w < 0.0)\n        {\n            to_l = _688.light_pos[i].xy / float2(fast::max(length(_688.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _1284 = _688.light_pos[i].xy - world_xy;\n            float _1287 = length(_1284);\n            att = powr(fast::clamp(1.0 - (_1287 / fast::max(_688.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _688.light_color[i].w);\n            to_l = _1284 / float2(fast::max(_1287, 9.9999997473787516355514526367188e-05));\n            if (_688.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _688.light_shadow_v[i].x;\n                float param_1 = _688.light_shadow_v[i].y;\n                float2 param_2 = -_1284;\n                float param_3 = _688.light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1284;\n            att *= cookie_att(param_4, param_5, _688, fx_cookie_tex, light_smp);\n        }\n        sum += (_688.light_color[i].xyz * (att * fast::max(dot(_1238, to_l), 0.0)));\n    }\n    return (sum * _688.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_1149, _1160), fast::min(_1171, _1182))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _688)\n{\n    float2 _694 = gl_FragCoord.xy * _688.fa_target.xy;\n    float _698 = _694.y;\n    return float2(_694.x, mix(_698, 1.0 - _698, _688.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _688, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _736 = base_mode < 0.5;\n    bool _747;\n    if (!_736)\n    {\n        _747 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _747 = _736;\n    }\n    float _748;\n    if (_747)\n    {\n        _748 = shape_half.x;\n    }\n    else\n    {\n        _748 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _688), _688.fa_time.x, base_mode, float4(0.0), _748 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s)\n{\n    s.color.x = i.life;\n    s.color.y = i.life;\n    s.color.z = i.life;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _688 [[buffer(1)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> fx_emissive_tex [[texture(4)]], texture2d<float> fx_cookie_tex [[texture(5)]], texture2d<float> fx_gi_tex [[texture(6)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1681 = in.params.x > 31.5;\n    if (_1681)\n    {\n        mode -= 32.0;\n    }\n    float _1689 = mode;\n    bool _1691 = _1689 > 15.5;\n    if (_1691)\n    {\n        mode -= 16.0;\n    }\n    float _1699 = mode;\n    bool _1701 = _1699 > 7.5;\n    if (_1701)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1691)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _688, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1691)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _688, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1763 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1765 = _1763 * in.color;\n                float4 param_6 = _1765;\n                float param_7 = mode;\n                float _1772 = _1765.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _688, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), _1772);\n                if (_688.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1772;\n                    float param_9 = mode;\n                    float4 _1788 = out.frag_color;\n                    float3 _1790 = _1788.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _688, in.uv, in.world_xy, fx_cookie_tex, light_smp, in.params);\n                    out.frag_color.x = _1790.x;\n                    out.frag_color.y = _1790.y;\n                    out.frag_color.z = _1790.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1820 = length(in.uv);\n                    float _1823 = fwidth(_1820);\n                    float _1824 = fast::max(_1823, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1820) / _1824) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1820) / _1824) + 0.5, 0.0, 1.0) * fast::clamp(((_1820 - in.params.y) / _1824) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1864 = fast::clamp(1.0 - _1820, 0.0, 1.0);\n                            cov = (_1864 * _1864) * (3.0 - (2.0 * _1864));\n                        }\n                    }\n                    float3 _1873;\n                    if (_1691)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1873 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _688, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1873 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1873, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_688.fx_emit.w > 0.5)\n    {\n        float3 e = _688.fx_emit.xyz;\n        if (_688.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _688.fx_emit_uv.xy) + _688.fx_emit_uv.zw)).xyz;\n            float param_13 = _688.fx_emit.w - 2.0;\n            float3 _1928 = fa_tex_fix(param_12, param_13);\n            e *= _1928;\n        }\n        float4 _1932 = out.frag_color;\n        float3 _1934 = _1932.xyz + e;\n        out.frag_color.x = _1934.x;\n        out.frag_color.y = _1934.y;\n        out.frag_color.z = _1934.z;\n    }\n    float param_14 = mode;\n    float4 _2262 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14, gl_FragCoord, _688, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _2262 };\n    fragment0(param_15, param_16);\n    _2262 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1681)\n    {\n        float4 _1960 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _1965 = scene_rgb(param_17, in.xform);\n        float3 _1969 = mix(_1960.xyz, _1965, float3(in.color2.w));\n        out.frag_color.x = _1969.x;\n        out.frag_color.y = _1969.y;\n        out.frag_color.z = _1969.z;\n    }\n    if (_1701)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1993 = _688.fog_col.w > 0.0;\n    bool _2001;\n    if (!_1993)\n    {\n        _2001 = _688.fog_b.y > 0.0;\n    }\n    else\n    {\n        _2001 = _1993;\n    }\n    if (_2001)\n    {\n        float3 _2015 = float3(in.world_xy, in.world_z) - _688.fog_eye.xyz;\n        float _2022 = dot(_2015, _688.fog_c.xyz);\n        bool _2026 = _688.fog_c.w > 0.5;\n        float _2027;\n        if (_2026)\n        {\n            _2027 = _2022;\n        }\n        else\n        {\n            _2027 = length(_2015);\n        }\n        float _2039 = _2027 - _688.fog_b.x;\n        if (_2039 > 0.0)\n        {\n            float _2048 = _688.fog_col.w * _2039;\n            float tau = _2048 * _2048;\n            if (_688.fog_b.y > 0.0)\n            {\n                float _2064;\n                if (_2026)\n                {\n                    _2064 = in.world_xy.y - (_688.fog_c.y * _2022);\n                }\n                else\n                {\n                    _2064 = _688.fog_eye.y;\n                }\n                float _2085 = mix(_2064, in.world_xy.y, fast::clamp(_688.fog_b.x / _2027, 0.0, 1.0));\n                float _2089 = in.world_xy.y - _2085;\n                float _2094 = _2085 - _688.fog_b.z;\n                float _2099 = in.world_xy.y - _688.fog_b.z;\n                bool _2102 = _2094 <= 0.0;\n                bool _2103 = !_2102;\n                bool _2109;\n                if (_2103)\n                {\n                    _2109 = _688.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2109 = _2102;\n                }\n                float _2110;\n                if (_2109)\n                {\n                    _2110 = _688.fog_b.y;\n                }\n                else\n                {\n                    _2110 = _688.fog_b.y * exp(-fast::min(_688.fog_b.w * _2094, 80.0));\n                }\n                bool _2137;\n                if (_2103)\n                {\n                    _2137 = _688.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2137 = _2102;\n                }\n                float _2138;\n                if (_2137)\n                {\n                    _2138 = _688.fog_b.y * _2094;\n                }\n                else\n                {\n                    _2138 = (_688.fog_b.y * (1.0 - exp(-fast::min(_688.fog_b.w * _2094, 80.0)))) / _688.fog_b.w;\n                }\n                bool _2163 = _2099 <= 0.0;\n                bool _2170;\n                if (!_2163)\n                {\n                    _2170 = _688.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2170 = _2163;\n                }\n                float _2171;\n                if (_2170)\n                {\n                    _2171 = _688.fog_b.y * _2099;\n                }\n                else\n                {\n                    _2171 = (_688.fog_b.y * (1.0 - exp(-fast::min(_688.fog_b.w * _2099, 80.0)))) / _688.fog_b.w;\n                }\n                float _2198;\n                if (abs(_2089) < 0.001000000047497451305389404296875)\n                {\n                    _2198 = _2110;\n                }\n                else\n                {\n                    _2198 = (_2171 - _2138) / _2089;\n                }\n                tau += (_2039 * fast::max(_2198, 0.0));\n            }\n            float4 _2221 = out.frag_color;\n            float3 _2229 = mix(_2221.xyz, _688.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _2229.x;\n            out.frag_color.y = _2229.y;\n            out.frag_color.z = _2229.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "inst_name": "_688",
            "msl_buffer_n": 1
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _144 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _144;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n    float4 gi_xf;\n    float4 gi_p;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _131)\n{\n    float2 _138 = gl_FragCoord.xy * _131.fa_target.xy;\n    float _144 = _138.y;\n    return float2(_138.x, mix(_144, 1.0 - _144, _131.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _131, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _188 = base_mode < 0.5;\n    bool _199;\n    if (!_188)\n    {\n        _199 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _199 = _188;\n    }\n    float _200;\n    if (_199)\n    {\n        _200 = shape_half.x;\n    }\n    else\n    {\n        _200 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _131), _131.fa_time.x, base_mode, float4(0.0), _200 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s)\n{\n    s.color.x = i.life;\n    s.color.y = i.life;\n    s.color.z = i.life;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _131 [[buffer(1)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _234 = tex.sample(smp, in.uv);\n    float3 param = _234.xyz;\n    float param_1 = in.xform.y;\n    float3 _245 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_245, _234.w) * in.color;\n    float param_2 = 0.0;\n    float4 _300 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _131, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _300 };\n    fragment0(param_3, param_4);\n    _300 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "inst_name": "_131",
            "msl_buffer_n": 1
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
