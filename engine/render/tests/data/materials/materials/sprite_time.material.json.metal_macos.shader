{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "c463ccd1917be78236231aa4aa6bc7a9036af5c2e4c419a950fb6e8c51e433a6",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _144 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _144;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 gi_xf;\n    float4 gi_p;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _625 = fa_linear_to_srgb(param);\n        c = _625;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _633 = fa_srgb_to_linear(param_1);\n            c = _633;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _644 = tex.sample(smp, p);\n    float3 param = _644.xyz;\n    float param_1 = xform.y;\n    float3 _654 = fa_tex_fix(param, param_1);\n    return float4(_654, _644.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 gi_irradiance(constant quad_fs_params& _687, thread float2& world_xy, sampler light_smp, texture2d<float> fx_gi_tex)\n{\n    float2 _818 = (world_xy * _687.gi_xf.xy) + _687.gi_xf.zw;\n    float4 _825 = fx_gi_tex.sample(light_smp, _818, level(0.0));\n    float _829 = _818.x;\n    bool _830 = _829 >= 0.0;\n    bool _836;\n    if (_830)\n    {\n        _836 = _818.y >= 0.0;\n    }\n    else\n    {\n        _836 = _830;\n    }\n    bool _842;\n    if (_836)\n    {\n        _842 = _829 <= 1.0;\n    }\n    else\n    {\n        _842 = _836;\n    }\n    bool _848;\n    if (_842)\n    {\n        _848 = _818.y <= 1.0;\n    }\n    else\n    {\n        _848 = _842;\n    }\n    bool _856;\n    if (_848)\n    {\n        _856 = _825.w > 0.0199999995529651641845703125;\n    }\n    else\n    {\n        _856 = _848;\n    }\n    float3 _857;\n    if (_856)\n    {\n        _857 = (_825.xyz / float3(_825.w)) * _687.gi_p.x;\n    }\n    else\n    {\n        _857 = float3(0.0);\n    }\n    return _857;\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _134 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_134.x * 255.0) + 0.5) * 256.0) + floor((_134.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_tap(thread const float& v, thread const float& tt, thread const float& dist, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _237 = floor(tt);\n    float _247 = _237 - (1024.0 * floor(_237 * 0.0009765625));\n    float _250 = _247 + 1.0;\n    float i1 = _250;\n    if (_250 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _247;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), tt - _237);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_soft(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _287 = length(d);\n    float result = 1.0;\n    if (_287 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _298 = precise::atan2(d.y, d.x);\n        float a = _298;\n        float _301;\n        if (_298 < 0.0)\n        {\n            _301 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _301 = a;\n        }\n        a = _301;\n        float _311 = _301 * 162.9746551513671875;\n        float _320 = fast::min((size * 10.0) / _287, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _346 = floor(_311 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _320));\n            float param = v;\n            float param_1 = _346 - (1024.0 * floor(_346 * 0.0009765625));\n            float _360 = shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius;\n            if (_360 < _287)\n            {\n                sum += _360;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _392 = fast::min(size * ((1.0 / fast::max(sum / n, 1.0)) - (1.0 / _287)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _410 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _416 = 1.0 - (0.800000011920928955078125 * abs(_410));\n                float param_2 = v;\n                float param_3 = _311 + (_410 * _392);\n                float param_4 = _287;\n                float param_5 = radius;\n                acc += (_416 * light_shadow_tap(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp));\n                wsum += _416;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _158 = length(d);\n    if (_158 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _172 = precise::atan2(d.y, d.x);\n    float a = _172;\n    float _175;\n    if (_172 < 0.0)\n    {\n        _175 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _175 = a;\n    }\n    a = _175;\n    float _187 = _175 * 162.9746551513671875;\n    float _192 = fast::min(floor(_187), 1023.0);\n    float _199 = _192 + 1.0;\n    float i1 = _199;\n    if (_199 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _192;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _158) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _158) + 0.5, 0.0, 1.0), _187 - _192);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_sized(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6, shadow_tex, shadow_smp);\n    }\n    return r;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _497 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _501 = _497.x + 0.5;\n    float2 c = float2(_501, 0.5 - _497.y);\n    bool _509 = _501 >= 0.0;\n    bool _515;\n    if (_509)\n    {\n        _515 = c.x <= 1.0;\n    }\n    else\n    {\n        _515 = _509;\n    }\n    bool _521;\n    if (_515)\n    {\n        _521 = c.y >= 0.0;\n    }\n    else\n    {\n        _521 = _515;\n    }\n    bool _527;\n    if (_521)\n    {\n        _527 = c.y <= 1.0;\n    }\n    else\n    {\n        _527 = _521;\n    }\n    float2 _529 = c;\n    float2 _534 = fast::clamp(_529, float2(0.001953125), float2(0.998046875));\n    c = _534;\n    return float3(cell.x + (_534.x * cell.w), cell.y + (_534.y * cell.z), float(_527));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _687, texture2d<float> fx_cookie_tex, sampler light_smp)\n{\n    if (_687.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _687.light_cookie[i];\n    float4 param_1 = _687.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _792 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _792.xy, level(0.0));\n    return cookie_value(param_3) * _792.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _687, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, texture2d<float> fx_gi_tex, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _879 = _687.lit.y > 0.5;\n    if (_879)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _687.normal_uv.xy) + _687.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _903 = fa_tex_fix(param, param_1);\n        float3 _907 = (_903 * 2.0) - float3(1.0);\n        float _914 = cos(params.y);\n        float _916 = sin(params.y);\n        n = fast::normalize(float3((float2(_914, _916) * _907.x) + ((float2(-_916, _914) * ((mode > 5.5) ? (-1.0) : 1.0)) * _907.y), fast::max(_907.z, 0.0500000007450580596923828125)));\n    }\n    bool _950 = !_879;\n    bool _956;\n    if (_950)\n    {\n        _956 = _687.lit.z > 0.5;\n    }\n    else\n    {\n        _956 = _950;\n    }\n    float3 _959;\n    if (_956)\n    {\n        _959 = _687.flat_ambient.xyz;\n    }\n    else\n    {\n        _959 = _687.ambient.xyz;\n    }\n    float3 total = _959;\n    if (_687.gi_p.x > 0.0)\n    {\n        total += gi_irradiance(_687, world_xy, light_smp, fx_gi_tex);\n    }\n    bool _984;\n    if (_956)\n    {\n        _984 = _687.lit.z < 1.5;\n    }\n    else\n    {\n        _984 = _956;\n    }\n    if (_984)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _687.light_map.xy), level(0.0)).xyz * _687.light_map.z);\n    }\n    float3 l;\n    float _1111;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1021;\n        if (!_956)\n        {\n            _1021 = float(i) >= _687.lit.x;\n        }\n        else\n        {\n            _1021 = _956;\n        }\n        if (_1021)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_687.light_pos[i].w < 0.0)\n        {\n            l = _687.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _1047 = _687.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_1047) / fast::max(_687.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _687.light_color[i].w);\n            float3 _1067 = float3(_1047, _687.light_pos[i].z);\n            l = _1067 / float3(fast::max(length(_1067), 9.9999997473787516355514526367188e-05));\n            if (_687.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _687.light_shadow_v[i].x;\n                float param_3 = _687.light_shadow_v[i].y;\n                float2 param_4 = -_1047;\n                float param_5 = _687.light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp);\n            }\n            int param_6 = i;\n            float2 param_7 = -_1047;\n            att *= cookie_att(param_6, param_7, _687, fx_cookie_tex, light_smp);\n        }\n        if (_879)\n        {\n            _1111 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1111 = 1.0;\n        }\n        total += (_687.light_color[i].xyz * (att * _1111));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _670 = fa_srgb_to_linear(param);\n        c = _670;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1361 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1365 = uv * _1361;\n    float _1371 = _1361.x;\n    float _1373 = _1361.y;\n    float _1375 = fast::clamp(shape_rs.x, 0.0, fast::min(_1371, _1373));\n    float2 _1386 = (abs(_1365) - _1361) + float2(_1375);\n    float d = (length(fast::max(_1386, float2(0.0))) + fast::min(fast::max(_1386.x, _1386.y), 0.0)) - _1375;\n    float ax = params.y;\n    bool _1407 = params.y > 15.0;\n    if (_1407)\n    {\n        ax -= 20.0;\n    }\n    float _1418;\n    if (ax <= (-1.5))\n    {\n        _1418 = (-2.0) - ax;\n    }\n    else\n    {\n        _1418 = 0.0;\n    }\n    if (_1418 > 0.0)\n    {\n        float _1432 = _1418 * 0.5;\n        d = abs(d + _1432) - _1432;\n    }\n    float _1440 = fwidth(d);\n    float _1441 = fast::max(_1440, 9.9999997473787516355514526367188e-05);\n    float _1451 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1441)), 0.0, 1.0);\n    float _1456;\n    if (shape_rs.y > _1441)\n    {\n        _1456 = (_1451 * _1451) * (3.0 - (2.0 * _1451));\n    }\n    else\n    {\n        _1456 = _1451;\n    }\n    float4 c = color;\n    bool _1478 = (_1418 <= 0.0) && (ax > (-0.5));\n    if (_1478)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1493 = cos(ax);\n            float _1495 = sin(ax);\n            g = ((dot(_1365, float2(_1493, _1495)) / fast::max((abs(_1493) * _1371) + (abs(_1495) * _1373), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1407)\n        {\n            float4 _1538 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1538;\n            float3 param = _1538.xyz;\n            float param_1 = xform.y;\n            float3 _1545 = fa_tex_fix(param, param_1);\n            float4 _2339 = c;\n            _2339.x = _1545.x;\n            _2339.y = _1545.y;\n            _2339.z = _1545.z;\n            c = _2339;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1557 = scene_rgb(param_2, xform);\n            float4 _1582 = mix(float4(color.xyz * color.w, color.w), float4(_1557 * color2.w, color2.w), float4(g));\n            float _1584 = _1582.w;\n            float3 _1587;\n            if (_1584 > 9.9999997473787516355514526367188e-06)\n            {\n                _1587 = _1582.xyz / float3(_1584);\n            }\n            else\n            {\n                _1587 = color.xyz;\n            }\n            c = float4(_1587, _1584);\n        }\n    }\n    float4 _2348 = c;\n    _2348.w = _2348.w * _1456;\n    c = _2348;\n    if (_1478 || (shape_rs.y > 0.0))\n    {\n        float _1628 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1637 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1637 + float3(_1628 * 0.0039215688593685626983642578125);\n            float3 _1643 = fa_srgb_to_linear(param_4);\n            float4 _2351 = c;\n            _2351.x = _1643.x;\n            _2351.y = _1643.y;\n            _2351.z = _1643.z;\n            c = _2351;\n        }\n        else\n        {\n            float4 _1653 = c;\n            float3 _1656 = _1653.xyz + float3(_1628 * 0.0039215688593685626983642578125);\n            float4 _2358 = _1653;\n            _2358.x = _1656.x;\n            _2358.y = _1656.y;\n            _2358.z = _1656.z;\n            c = _2358;\n        }\n        float4 _2363 = c;\n        _2363.w = fast::clamp(_2363.w + ((_1628 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2363.w)), 0.0, 1.0);\n        c = _2363;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _687, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, thread float2& params)\n{\n    float2 _1148 = float2(_687.fx_rim_uv.x, 0.0);\n    float4 _1150 = tex.sample(smp, (uv - _1148));\n    float _1151 = _1150.w;\n    float4 _1161 = tex.sample(smp, (uv + _1148));\n    float _1162 = _1161.w;\n    float2 _1170 = float2(0.0, _687.fx_rim_uv.y);\n    float4 _1172 = tex.sample(smp, (uv - _1170));\n    float _1173 = _1172.w;\n    float4 _1183 = tex.sample(smp, (uv + _1170));\n    float _1184 = _1183.w;\n    float _1199 = _1151 - _1162;\n    float _1202 = _1184 - _1173;\n    float _1212 = cos(params.y);\n    float _1214 = sin(params.y);\n    float2 _1240 = ((float2(_1212, _1214) * _1199) + ((float2(-_1214, _1212) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1202)) / float2(fast::max(length(float2(_1199, _1202)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _687.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_687.light_pos[i].w < 0.0)\n        {\n            to_l = _687.light_pos[i].xy / float2(fast::max(length(_687.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _1286 = _687.light_pos[i].xy - world_xy;\n            float _1289 = length(_1286);\n            att = powr(fast::clamp(1.0 - (_1289 / fast::max(_687.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _687.light_color[i].w);\n            to_l = _1286 / float2(fast::max(_1289, 9.9999997473787516355514526367188e-05));\n            if (_687.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _687.light_shadow_v[i].x;\n                float param_1 = _687.light_shadow_v[i].y;\n                float2 param_2 = -_1286;\n                float param_3 = _687.light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1286;\n            att *= cookie_att(param_4, param_5, _687, fx_cookie_tex, light_smp);\n        }\n        sum += (_687.light_color[i].xyz * (att * fast::max(dot(_1240, to_l), 0.0)));\n    }\n    return (sum * _687.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_1151, _1162), fast::min(_1173, _1184))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _687)\n{\n    float2 _693 = gl_FragCoord.xy * _687.fa_target.xy;\n    float _697 = _693.y;\n    return float2(_693.x, mix(_697, 1.0 - _697, _687.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _687, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _735 = base_mode < 0.5;\n    bool _746;\n    if (!_735)\n    {\n        _746 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _746 = _735;\n    }\n    float _747;\n    if (_746)\n    {\n        _747 = shape_half.x;\n    }\n    else\n    {\n        _747 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _687), _687.fa_time.x, base_mode, float4(0.0), _747 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s)\n{\n    s.color.x = fast::clamp(i.time * 0.25, 0.0, 1.0);\n    s.color.y = 0.0;\n    s.color.z = 0.0;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _687 [[buffer(1)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> fx_emissive_tex [[texture(4)]], texture2d<float> fx_cookie_tex [[texture(5)]], texture2d<float> fx_gi_tex [[texture(6)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1683 = in.params.x > 31.5;\n    if (_1683)\n    {\n        mode -= 32.0;\n    }\n    float _1691 = mode;\n    bool _1693 = _1691 > 15.5;\n    if (_1693)\n    {\n        mode -= 16.0;\n    }\n    float _1701 = mode;\n    bool _1703 = _1701 > 7.5;\n    if (_1703)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1693)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _687, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1693)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _687, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1765 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1767 = _1765 * in.color;\n                float4 param_6 = _1767;\n                float param_7 = mode;\n                float _1774 = _1767.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _687, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex), _1774);\n                if (_687.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1774;\n                    float param_9 = mode;\n                    float4 _1790 = out.frag_color;\n                    float3 _1792 = _1790.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _687, in.uv, in.world_xy, fx_cookie_tex, light_smp, in.params);\n                    out.frag_color.x = _1792.x;\n                    out.frag_color.y = _1792.y;\n                    out.frag_color.z = _1792.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1822 = length(in.uv);\n                    float _1825 = fwidth(_1822);\n                    float _1826 = fast::max(_1825, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1822) / _1826) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1822) / _1826) + 0.5, 0.0, 1.0) * fast::clamp(((_1822 - in.params.y) / _1826) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1866 = fast::clamp(1.0 - _1822, 0.0, 1.0);\n                            cov = (_1866 * _1866) * (3.0 - (2.0 * _1866));\n                        }\n                    }\n                    float3 _1875;\n                    if (_1693)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1875 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _687, in.uv, in.world_xy, fx_cookie_tex, light_smp, fx_gi_tex, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1875 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1875, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_687.fx_emit.w > 0.5)\n    {\n        float3 e = _687.fx_emit.xyz;\n        if (_687.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _687.fx_emit_uv.xy) + _687.fx_emit_uv.zw)).xyz;\n            float param_13 = _687.fx_emit.w - 2.0;\n            float3 _1930 = fa_tex_fix(param_12, param_13);\n            e *= _1930;\n        }\n        float4 _1934 = out.frag_color;\n        float3 _1936 = _1934.xyz + e;\n        out.frag_color.x = _1936.x;\n        out.frag_color.y = _1936.y;\n        out.frag_color.z = _1936.z;\n    }\n    float param_14 = mode;\n    float4 _2263 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14, gl_FragCoord, _687, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _2263 };\n    fragment0(param_15, param_16);\n    _2263 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1683)\n    {\n        float4 _1962 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _1967 = scene_rgb(param_17, in.xform);\n        float3 _1971 = mix(_1962.xyz, _1967, float3(in.color2.w));\n        out.frag_color.x = _1971.x;\n        out.frag_color.y = _1971.y;\n        out.frag_color.z = _1971.z;\n    }\n    if (_1703)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1995 = _687.fog_col.w > 0.0;\n    bool _2003;\n    if (!_1995)\n    {\n        _2003 = _687.fog_b.y > 0.0;\n    }\n    else\n    {\n        _2003 = _1995;\n    }\n    if (_2003)\n    {\n        float3 _2017 = float3(in.world_xy, in.world_z) - _687.fog_eye.xyz;\n        float _2024 = dot(_2017, _687.fog_c.xyz);\n        bool _2028 = _687.fog_c.w > 0.5;\n        float _2029;\n        if (_2028)\n        {\n            _2029 = _2024;\n        }\n        else\n        {\n            _2029 = length(_2017);\n        }\n        float _2041 = _2029 - _687.fog_b.x;\n        if (_2041 > 0.0)\n        {\n            float _2050 = _687.fog_col.w * _2041;\n            float tau = _2050 * _2050;\n            if (_687.fog_b.y > 0.0)\n            {\n                float _2066;\n                if (_2028)\n                {\n                    _2066 = in.world_xy.y - (_687.fog_c.y * _2024);\n                }\n                else\n                {\n                    _2066 = _687.fog_eye.y;\n                }\n                float _2087 = mix(_2066, in.world_xy.y, fast::clamp(_687.fog_b.x / _2029, 0.0, 1.0));\n                float _2091 = in.world_xy.y - _2087;\n                float _2096 = _2087 - _687.fog_b.z;\n                float _2101 = in.world_xy.y - _687.fog_b.z;\n                bool _2104 = _2096 <= 0.0;\n                bool _2105 = !_2104;\n                bool _2111;\n                if (_2105)\n                {\n                    _2111 = _687.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2111 = _2104;\n                }\n                float _2112;\n                if (_2111)\n                {\n                    _2112 = _687.fog_b.y;\n                }\n                else\n                {\n                    _2112 = _687.fog_b.y * exp(-fast::min(_687.fog_b.w * _2096, 80.0));\n                }\n                bool _2139;\n                if (_2105)\n                {\n                    _2139 = _687.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2139 = _2104;\n                }\n                float _2140;\n                if (_2139)\n                {\n                    _2140 = _687.fog_b.y * _2096;\n                }\n                else\n                {\n                    _2140 = (_687.fog_b.y * (1.0 - exp(-fast::min(_687.fog_b.w * _2096, 80.0)))) / _687.fog_b.w;\n                }\n                bool _2165 = _2101 <= 0.0;\n                bool _2172;\n                if (!_2165)\n                {\n                    _2172 = _687.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2172 = _2165;\n                }\n                float _2173;\n                if (_2172)\n                {\n                    _2173 = _687.fog_b.y * _2101;\n                }\n                else\n                {\n                    _2173 = (_687.fog_b.y * (1.0 - exp(-fast::min(_687.fog_b.w * _2101, 80.0)))) / _687.fog_b.w;\n                }\n                float _2200;\n                if (abs(_2091) < 0.001000000047497451305389404296875)\n                {\n                    _2200 = _2112;\n                }\n                else\n                {\n                    _2200 = (_2173 - _2140) / _2091;\n                }\n                tau += (_2041 * fast::max(_2200, 0.0));\n            }\n            float4 _2223 = out.frag_color;\n            float3 _2231 = mix(_2223.xyz, _687.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _2231.x;\n            out.frag_color.y = _2231.y;\n            out.frag_color.z = _2231.z;\n        }\n    }\n    return out;\n}\n\n",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 gi_xf;\n    float4 gi_p;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _129)\n{\n    float2 _136 = gl_FragCoord.xy * _129.fa_target.xy;\n    float _142 = _136.y;\n    return float2(_136.x, mix(_142, 1.0 - _142, _129.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _129, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _186 = base_mode < 0.5;\n    bool _197;\n    if (!_186)\n    {\n        _197 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _197 = _186;\n    }\n    float _198;\n    if (_197)\n    {\n        _198 = shape_half.x;\n    }\n    else\n    {\n        _198 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _129), _129.fa_time.x, base_mode, float4(0.0), _198 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s)\n{\n    s.color.x = fast::clamp(i.time * 0.25, 0.0, 1.0);\n    s.color.y = 0.0;\n    s.color.z = 0.0;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _129 [[buffer(1)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _235 = tex.sample(smp, in.uv);\n    float3 param = _235.xyz;\n    float param_1 = in.xform.y;\n    float3 _246 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_246, _235.w) * in.color;\n    float param_2 = 0.0;\n    float4 _300 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _129, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _300 };\n    fragment0(param_3, param_4);\n    _300 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
