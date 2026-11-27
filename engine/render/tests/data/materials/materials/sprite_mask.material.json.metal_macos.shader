{
  "format": "factoria.shader/1",
  "engine": "0.39.0",
  "template": "d75bc1c2988d2355d3b6c4618a7c68ff76094f3e9d32765c88b7244d10541da4",
  "slang": "metal_macos",
  "params": [],
  "textures": [
    "mask"
  ],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _150 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _155 = _150;\n        _155.x = _82.x;\n        _155.y = _82.y;\n        _155.z = _82.z;\n        _150 = _155;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _150;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n    float4 gi_xf;\n    float4 gi_p;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _625 = fa_linear_to_srgb(param);\n        c = _625;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _633 = fa_srgb_to_linear(param_1);\n            c = _633;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _644 = tex.sample(smp, p);\n    float3 param = _644.xyz;\n    float param_1 = xform.y;\n    float3 _654 = fa_tex_fix(param, param_1);\n    return float4(_654, _644.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 gi_irradiance(constant quad_fs_params& _688, thread float2& world_xy, sampler light_smp, texture2d<float> fx_gi_tex)\n{\n    float2 _822 = (world_xy * _688.gi_xf.xy) + _688.gi_xf.zw;\n    float4 _829 = fx_gi_tex.sample(light_smp, _822, level(0.0));\n    float _833 = _822.x;\n    bool _834 = _833 >= 0.0;\n    bool _840;\n    if (_834)\n    {\n        _840 = _822.y >= 0.0;\n    }\n    else\n    {\n        _840 = _834;\n    }\n    bool _846;\n    if (_840)\n    {\n        _846 = _833 <= 1.0;\n    }\n    else\n    {\n        _846 = _840;\n    }\n    bool _852;\n    if (_846)\n    {\n        _852 = _822.y <= 1.0;\n    }\n    else\n    {\n        _852 = _846;\n    }\n    bool _860;\n    if (_852)\n    {\n        _860 = _829.w > 0.0199999995529651641845703125;\n    }\n    else\n    {\n        _860 = _852;\n    }\n    float3 _861;\n    if (_860)\n    {\n        _861 = (_829.xyz / float3(_829.w)) * _688.gi_p.x;\n    }\n    else\n    {\n        _861 = float3(0.0);\n    }\n    return _861;\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _134 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_134.x * 255.0) + 0.5) * 256.0) + floor((_134.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_tap(thread const float& v, thread const float& tt, thread const float& dist, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _237 = floor(tt);\n    float _247 = _237 - (1024.0 * floor(_237 * 0.0009765625));\n    float _250 = _247 + 1.0;\n    float i1 = _250;\n    if (_250 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _247;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), tt - _237);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_soft(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _287 = length(d);\n    float result = 1.0;\n    if (_287 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _298 = precise::atan2(d.y, d.x);\n        float a = _298;\n        float _301;\n        if (_298 < 0.0)\n        {\n            _301 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _301 = a;\n        }\n        a = _301;\n        float _311 = _301 * 162.9746551513671875;\n        float _320 = fast::min((size * 10.0) / _287, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _346 = floor(_311 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _320));\n            float param = v;\n            float param_1 = _346 - (1024.0 * floor(_346 * 0.0009765625));\n            float _360 = shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius;\n            if (_360 < _287)\n            {\n                sum += _360;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _392 = fast::min(size * ((1.0 / fast::max(sum / n, 1.0)) - (1.0 / _287)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _410 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _416 = 1.0 - (0.800000011920928955078125 * abs(_410));\n                float param_2 = v;\n                float param_3 = _311 + (_410 * _392);\n                float param_4 = _287;\n                float param_5 = radius;\n                acc += (_416 * light_shadow_tap(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp));\n                wsum += _416;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _158 = length(d);\n    if (_158 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _172 = precise::atan2(d.y, d.x);\n    float a = _172;\n    float _175;\n    if (_172 < 0.0)\n    {\n        _175 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _175 = a;\n    }\n    a = _175;\n    float _187 = _175 * 162.9746551513671875;\n    float _192 = fast::min(floor(_187), 1023.0);\n    float _199 = _192 + 1.0;\n    float i1 = _199;\n    if (_199 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _192;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _158) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _158) + 0.5, 0.0, 1.0), _187 - _192);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_sized(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6, shadow_tex, shadow_smp);\n    }\n    return r;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _497 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _501 = _497.x + 0.5;\n    float2 c = float2(_501, 0.5 - _497.y);\n    bool _509 = _501 >= 0.0;\n    bool _515;\n    if (_509)\n    {\n        _515 = c.x <= 1.0;\n    }\n    else\n    {\n        _515 = _509;\n    }\n    bool _521;\n    if (_515)\n    {\n        _521 = c.y >= 0.0;\n    }\n    else\n    {\n        _521 = _515;\n    }\n    bool _527;\n    if (_521)\n    {\n        _527 = c.y <= 1.0;\n    }\n    else\n    {\n        _527 = _521;\n    }\n    float2 _529 = c;\n    float2 _534 = fast::clamp(_529, float2(0.001953125), float2(0.998046875));\n    c = _534;\n    return float3(cell.x + (_534.x * cell.w), cell.y + (_534.y * cell.z), float(_527));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _688, texture2d<float> fx_cookie_tex, sampler light_smp)\n{\n    if (_688.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _688.light_cookie[i];\n    float4 param_1 = _688.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _796 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _796.xy, level(0.0));\n    return cookie_value(param_3) * _796.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _688, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, texture2d<float> fx_gi_tex, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _883 = _688.lit.y > 0.5;\n    if (_883)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _688.normal_uv.xy) + _688.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _907 = fa_tex_fix(param, param_1);\n        float3 _911 = (_907 * 2.0) - float3(1.0);\n        float _918 = cos(params.y);\n        float _920 = sin(params.y);\n        n = fast::normalize(float3((float2(_918, _920) * _911.x) + ((float2(-_920, _918) * ((mode > 5.5) ? (-1.0) : 1.0)) * _911.y), fast::max(_911.z, 0.0500000007450580596923828125)));\n    }\n    bool _953 = !_883;\n    bool _959;\n    if (_953)\n    {\n        _959 = _688.lit.z > 0.5;\n    }\n    else\n    {\n        _959 = _953;\n    }\n    float3 _962;\n    if (_959)\n    {\n        _962 = _688.flat_ambient.xyz;\n    }\n    else\n    {\n        _962 = _688.ambient.xyz;\n    }\n    float3 total = _962;\n    if (_688.gi_p.x > 0.0)\n    {\n        total += gi_irradiance(_688, world_xy, light_smp, fx_gi_tex);\n    }\n    bool _987;\n    if (_959)\n    {\n        _987 = _688.lit.z < 1.5;\n    }\n    else\n    {\n        _987 = _959;\n    }\n    if (_987)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _688.light_map.xy), level(0.0)).xyz * _688.light_map.z);\n    }\n    float3 l;\n    float _1114;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1024;\n        if (!_959)\n        {\n            _1024 = float(i) >= _688.lit.x;\n        }\n        else\n        {\n            _1024 = _959;\n        }\n        if (_1024)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_688.light_pos[i].w < 0.0)\n        {\n            l = _688.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _1050 = _688.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_1050) / fast::max(_688.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _688.light_color[i].w);\n            float3 _1070 = float3(_1050, _688.light_pos[i].z);\n            l = _1070 / float3(fast::max(length(_1070), 9.9999997473787516355514526367188e-05));\n            if (_688.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _688.light_shadow_v[i].x;\n                float param_3 = _688.light_shadow_v[i].y;\n                float2 param_4 = -_1050;\n                float param_5 = _688.light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp);\n            }\n            int param_6 = i;\n            float2 param_7 = -_1050;\n            att *= cookie_att(param_6, param_7, _688, fx_cookie_tex, light_smp);\n        }\n        if (_883)\n        {\n            _1114 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1114 = 1.0;\n        }\n        total += (_688.light_color[i].xyz * (att * _1114));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _670 = fa_srgb_to_linear(param);\n        c = _670;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1364 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1368 = uv * _1364;\n    float _1374 = _1364.x;\n    float _1376 = _1364.y;\n    float _1378 = fast::clamp(shape_rs.x, 0.0, fast::min(_1374, _1376));\n    float2 _1389 = (abs(_1368) - _1364) + float2(_1378);\n    float d = (length(fast::max(_1389, float2(0.0))) + fast::min(fast::max(_1389.x, _1389.y), 0.0)) - _1378;\n    float ax = params.y;\n    bool _1410 = params.y > 15.0;\n    if (_1410)\n    {\n        ax -= 20.0;\n    }\n    float _1421;\n    if (ax <= (-1.5))\n    {\n        _1421 = (-2.0) - ax;\n    }\n    else\n    {\n        _1421 = 0.0;\n    }\n    if (_1421 > 0.0)\n    {\n        float _1435 = _1421 * 0.5;\n        d = abs(d + _1435) - _1435;\n    }\n    float _1443 = fwidth(d);\n    float _1444 = fast::max(_1443, 9.9999997473787516355514526367188e-05);\n    float _1454 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1444)), 0.0, 1.0);\n    float _1459;\n    if (shape_rs.y > _1444)\n    {\n        _1459 = (_1454 * _1454) * (3.0 - (2.0 * _1454));\n    }\n    else\n    {\n        _1459 = _1454;\n    }\n    float4 c = color;\n    bool _1481 = (_1421 <= 0.0) && (ax > (-0.5));\n    if (_1481)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1496 = cos(ax);\n            float _1498 = sin(ax);\n            g = ((dot(_1368, float2(_1496, _1498)) / fast::max((abs(_1496) * _1374) + (abs(_1498) * _1376), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1410)\n        {\n            float4 _1541 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1541;\n            float3 param = _1541.xyz;\n            float param_1 = xform.y;\n            float3 _1548 = fa_tex_fix(param, param_1);\n            float4 _2343 = c;\n            _2343.x = _1548.x;\n            _2343.y = _1548.y;\n            _2343.z = _1548.z;\n            c = _2343;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1560 = scene_rgb(param_2, xform);\n            float4 _1585 = mix(float4(color.xyz * color.w, color.w), float4(_1560 * color2.w, color2.w), float4(g));\n            float _1587 = _1585.w;\n            float3 _1590;\n            if (_1587 > 9.9999997473787516355514526367188e-06)\n            {\n                _1590 = _1585.xyz / float3(_1587);\n            }\n            else\n            {\n                _1590 = color.xyz;\n            }\n            c = float4(_1590, _1587);\n        }\n    }\n    float4 _2352 = c;\n    _2352.w = _2352.w * _1459;\n    c = _2352;\n    if (_1481 || (shape_rs.y > 0.0))\n    {\n        float _1631 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1640 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1640 + float3(_1631 * 0.0039215688593685626983642578125);\n            float3 _1646 = fa_srgb_to_linear(param_4);\n            float4 _2355 = c;\n            _2355.x = _1646.x;\n            _2355.y = _1646.y;\n            _2355.z = _1646.z;\n            c = _2355;\n        }\n        else\n        {\n            float4 _1656 = c;\n            float3 _1659 = _1656.xyz + float3(_1631 * 0.0039215688593685626983642578125);\n            float4 _2362 = _1656;\n            _2362.x = _1659.x;\n            _2362.y = _1659.y;\n            _2362.z = _1659.z;\n            c = _2362;\n        }\n        float4 _2367 = c;\n        _2367.w = fast::clamp(_2367.w + ((_1631 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2367.w)), 0.0, 1.0);\n        c = _2367;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _688, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, thread float2& params)\n{\n    float2 _1151 = float2(_688.fx_rim_uv.x, 0.0);\n    float4 _1153 = tex.sample(smp, (uv - _1151));\n    float _1154 = _1153.w;\n    float4 _1164 = tex.sample(smp, (uv + _1151));\n    float _1165 = _1164.w;\n    float2 _1173 = float2(0.0, _688.fx_rim_uv.y);\n    float4 _1175 = tex.sample(smp, (uv - _1173));\n    float _1176 = _1175.w;\n    float4 _1186 = tex.sample(smp, (uv + _1173));\n    float _1187 = _1186.w;\n    float _1202 = _1154 - _1165;\n    float _1205 = _1187 - _1176;\n    float _1215 = cos(params.y);\n    float _1217 = sin(params.y);\n    float2 _1243 = ((float2(_1215, _1217) * _1202) + ((float2(-_1217, _1215) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1205)) / float2(fast::max(length(float2(_1202, _1205)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _688.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_688.light_pos[i].w < 0.0)\n        {\n            to_l = _688.light_pos[i].xy / float2(fast::max(length(_688.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _1289 = _688.light_pos[i].xy - world_xy;\n            float _1292 = length(_1289);\n            att = powr(fast::clamp(1.0 - (_1292 / fast::max(_688.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _688.light_color[i].w);\n            to_l = _1289 / float2(fast::max(_1292, 9.9999997473787516355514526367188e-05));\n            if (_688.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _688.light_shadow_v[i].x;\n                float param_1 = _688.light_shadow_v[i].y;\n                float2 param_2 = -_1289;\n                float param_3 = _688.light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1289;\n            att *= cookie_att(param_4, param_5, _688, fx_cookie_tex, light_smp);\n        }\n        sum += (_688.light_color[i].xyz * (att * fast::max(dot(_1243, to_l), 0.0)));\n    }\n    return (sum * _688.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_1154, _1165), fast::min(_1176, _1187))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _688)\n{\n    float2 _694 = gl_FragCoord.xy * _688.fa_target.xy;\n    float _698 = _694.y;\n    return float2(_694.x, mix(_698, 1.0 - _698, _688.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _688, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _736 = base_mode < 0.5;\n    bool _747;\n    if (!_736)\n    {\n        _747 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _747 = _736;\n    }\n    float _748;\n    if (_747)\n    {\n        _748 = shape_half.x;\n    }\n    else\n    {\n        _748 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _688), _688.fa_time.x, base_mode, float4(0.0), _748 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, texture2d<float> mask, sampler mask_smp)\n{\n    float4 _767 = mask.sample(mask_smp, float2(0.0500000007450580596923828125));\n    s.color.x = _767.x;\n    s.color.y = _767.y;\n    s.color.z = _767.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _688 [[buffer(1)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> mask [[texture(4)]], texture2d<float> fx_emissive_tex [[texture(5)]], texture2d<float> fx_cookie_tex [[texture(6)]], texture2d<float> fx_gi_tex [[texture(7)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], sampler mask_smp [[sampler(3)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1686 = in.params.x > 31.5;\n    if (_1686)\n    {\n        mode -= 32.0;\n    }\n    float _1694 = mode;\n    bool _1696 = _1694 > 15.5;\n    if (_1696)\n    {\n        mode -= 16.0;\n    }\n    float _1704 = mode;\n    bool _1706 = _1704 > 7.5;\n    if (_1706)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1696)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _688, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1696)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _688, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1768 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1770 = _1768 * in.color;\n                float4 param_6 = _1770;\n                float param_7 = mode;\n                float _1777 = _1770.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _688, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), _1777);\n                if (_688.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1777;\n                    float param_9 = mode;\n                    float4 _1793 = out.frag_color;\n                    float3 _1795 = _1793.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _688, in.uv, in.world_xy, fx_cookie_tex, light_smp, in.params);\n                    out.frag_color.x = _1795.x;\n                    out.frag_color.y = _1795.y;\n                    out.frag_color.z = _1795.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1825 = length(in.uv);\n                    float _1828 = fwidth(_1825);\n                    float _1829 = fast::max(_1828, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1825) / _1829) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1825) / _1829) + 0.5, 0.0, 1.0) * fast::clamp(((_1825 - in.params.y) / _1829) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1869 = fast::clamp(1.0 - _1825, 0.0, 1.0);\n                            cov = (_1869 * _1869) * (3.0 - (2.0 * _1869));\n                        }\n                    }\n                    float3 _1878;\n                    if (_1696)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1878 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _688, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1878 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1878, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_688.fx_emit.w > 0.5)\n    {\n        float3 e = _688.fx_emit.xyz;\n        if (_688.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _688.fx_emit_uv.xy) + _688.fx_emit_uv.zw)).xyz;\n            float param_13 = _688.fx_emit.w - 2.0;\n            float3 _1933 = fa_tex_fix(param_12, param_13);\n            e *= _1933;\n        }\n        float4 _1937 = out.frag_color;\n        float3 _1939 = _1937.xyz + e;\n        out.frag_color.x = _1939.x;\n        out.frag_color.y = _1939.y;\n        out.frag_color.z = _1939.z;\n    }\n    float param_14 = mode;\n    float4 _2267 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14, gl_FragCoord, _688, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _2267 };\n    fragment0(param_15, param_16, mask, mask_smp);\n    _2267 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1686)\n    {\n        float4 _1965 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _1970 = scene_rgb(param_17, in.xform);\n        float3 _1974 = mix(_1965.xyz, _1970, float3(in.color2.w));\n        out.frag_color.x = _1974.x;\n        out.frag_color.y = _1974.y;\n        out.frag_color.z = _1974.z;\n    }\n    if (_1706)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1998 = _688.fog_col.w > 0.0;\n    bool _2006;\n    if (!_1998)\n    {\n        _2006 = _688.fog_b.y > 0.0;\n    }\n    else\n    {\n        _2006 = _1998;\n    }\n    if (_2006)\n    {\n        float3 _2020 = float3(in.world_xy, in.world_z) - _688.fog_eye.xyz;\n        float _2027 = dot(_2020, _688.fog_c.xyz);\n        bool _2031 = _688.fog_c.w > 0.5;\n        float _2032;\n        if (_2031)\n        {\n            _2032 = _2027;\n        }\n        else\n        {\n            _2032 = length(_2020);\n        }\n        float _2044 = _2032 - _688.fog_b.x;\n        if (_2044 > 0.0)\n        {\n            float _2053 = _688.fog_col.w * _2044;\n            float tau = _2053 * _2053;\n            if (_688.fog_b.y > 0.0)\n            {\n                float _2069;\n                if (_2031)\n                {\n                    _2069 = in.world_xy.y - (_688.fog_c.y * _2027);\n                }\n                else\n                {\n                    _2069 = _688.fog_eye.y;\n                }\n                float _2090 = mix(_2069, in.world_xy.y, fast::clamp(_688.fog_b.x / _2032, 0.0, 1.0));\n                float _2094 = in.world_xy.y - _2090;\n                float _2099 = _2090 - _688.fog_b.z;\n                float _2104 = in.world_xy.y - _688.fog_b.z;\n                bool _2107 = _2099 <= 0.0;\n                bool _2108 = !_2107;\n                bool _2114;\n                if (_2108)\n                {\n                    _2114 = _688.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2114 = _2107;\n                }\n                float _2115;\n                if (_2114)\n                {\n                    _2115 = _688.fog_b.y;\n                }\n                else\n                {\n                    _2115 = _688.fog_b.y * exp(-fast::min(_688.fog_b.w * _2099, 80.0));\n                }\n                bool _2142;\n                if (_2108)\n                {\n                    _2142 = _688.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2142 = _2107;\n                }\n                float _2143;\n                if (_2142)\n                {\n                    _2143 = _688.fog_b.y * _2099;\n                }\n                else\n                {\n                    _2143 = (_688.fog_b.y * (1.0 - exp(-fast::min(_688.fog_b.w * _2099, 80.0)))) / _688.fog_b.w;\n                }\n                bool _2168 = _2104 <= 0.0;\n                bool _2175;\n                if (!_2168)\n                {\n                    _2175 = _688.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2175 = _2168;\n                }\n                float _2176;\n                if (_2175)\n                {\n                    _2176 = _688.fog_b.y * _2104;\n                }\n                else\n                {\n                    _2176 = (_688.fog_b.y * (1.0 - exp(-fast::min(_688.fog_b.w * _2104, 80.0)))) / _688.fog_b.w;\n                }\n                float _2203;\n                if (abs(_2094) < 0.001000000047497451305389404296875)\n                {\n                    _2203 = _2115;\n                }\n                else\n                {\n                    _2203 = (_2176 - _2143) / _2094;\n                }\n                tau += (_2044 * fast::max(_2203, 0.0));\n            }\n            float4 _2226 = out.frag_color;\n            float3 _2234 = mix(_2226.xyz, _688.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _2234.x;\n            out.frag_color.y = _2234.y;\n            out.frag_color.z = _2234.z;\n        }\n    }\n    return out;\n}\n\n",
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
              "slot": 4,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 4
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
              "msl_texture_n": 5
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
              "msl_texture_n": 6
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
            "slot": 3,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 3
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 4,
            "sampler_slot": 3
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _150 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _155 = _150;\n        _155.x = _82.x;\n        _155.y = _82.y;\n        _155.z = _82.z;\n        _150 = _155;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _150;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n    float4 gi_xf;\n    float4 gi_p;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _131)\n{\n    float2 _138 = gl_FragCoord.xy * _131.fa_target.xy;\n    float _144 = _138.y;\n    return float2(_138.x, mix(_144, 1.0 - _144, _131.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _131, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _188 = base_mode < 0.5;\n    bool _199;\n    if (!_188)\n    {\n        _199 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _199 = _188;\n    }\n    float _200;\n    if (_199)\n    {\n        _200 = shape_half.x;\n    }\n    else\n    {\n        _200 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _131), _131.fa_time.x, base_mode, float4(0.0), _200 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, texture2d<float> mask, sampler mask_smp)\n{\n    float4 _225 = mask.sample(mask_smp, float2(0.0500000007450580596923828125));\n    s.color.x = _225.x;\n    s.color.y = _225.y;\n    s.color.z = _225.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _131 [[buffer(1)]], texture2d<float> tex [[texture(0)]], texture2d<float> mask [[texture(1)]], sampler smp [[sampler(0)]], sampler mask_smp [[sampler(3)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _240 = tex.sample(smp, in.uv);\n    float3 param = _240.xyz;\n    float param_1 = in.xform.y;\n    float3 _251 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_251, _240.w) * in.color;\n    float param_2 = 0.0;\n    float4 _306 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _131, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _306 };\n    fragment0(param_3, param_4, mask, mask_smp);\n    _306 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 1
            }
          }
        ],
        "samplers": [
          {
            "slot": 3,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 3
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 4,
            "sampler_slot": 3
          }
        ]
      }
    }
  }
}
