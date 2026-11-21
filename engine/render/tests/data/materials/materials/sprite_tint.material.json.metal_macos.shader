{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "b6702e732a018d02616e2cc30236fe0da222b416419f1c736db600933d8ca4e3",
  "slang": "metal_macos",
  "params": [
    "tint"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _147 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _147;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n};\n\nstruct fa_material\n{\n    float4 tint;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _625 = fa_linear_to_srgb(param);\n        c = _625;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _633 = fa_srgb_to_linear(param_1);\n            c = _633;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _644 = tex.sample(smp, p);\n    float3 param = _644.xyz;\n    float param_1 = xform.y;\n    float3 _654 = fa_tex_fix(param, param_1);\n    return float4(_654, _644.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _134 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_134.x * 255.0) + 0.5) * 256.0) + floor((_134.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_tap(thread const float& v, thread const float& tt, thread const float& dist, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _237 = floor(tt);\n    float _247 = _237 - (1024.0 * floor(_237 * 0.0009765625));\n    float _250 = _247 + 1.0;\n    float i1 = _250;\n    if (_250 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _247;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), tt - _237);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_soft(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _287 = length(d);\n    float result = 1.0;\n    if (_287 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _298 = precise::atan2(d.y, d.x);\n        float a = _298;\n        float _301;\n        if (_298 < 0.0)\n        {\n            _301 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _301 = a;\n        }\n        a = _301;\n        float _311 = _301 * 162.9746551513671875;\n        float _320 = fast::min((size * 10.0) / _287, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _346 = floor(_311 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _320));\n            float param = v;\n            float param_1 = _346 - (1024.0 * floor(_346 * 0.0009765625));\n            float _360 = shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius;\n            if (_360 < _287)\n            {\n                sum += _360;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _392 = fast::min(size * ((1.0 / fast::max(sum / n, 1.0)) - (1.0 / _287)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _410 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _416 = 1.0 - (0.800000011920928955078125 * abs(_410));\n                float param_2 = v;\n                float param_3 = _311 + (_410 * _392);\n                float param_4 = _287;\n                float param_5 = radius;\n                acc += (_416 * light_shadow_tap(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp));\n                wsum += _416;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _158 = length(d);\n    if (_158 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _172 = precise::atan2(d.y, d.x);\n    float a = _172;\n    float _175;\n    if (_172 < 0.0)\n    {\n        _175 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _175 = a;\n    }\n    a = _175;\n    float _187 = _175 * 162.9746551513671875;\n    float _192 = fast::min(floor(_187), 1023.0);\n    float _199 = _192 + 1.0;\n    float i1 = _199;\n    if (_199 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _192;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _158) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _158) + 0.5, 0.0, 1.0), _187 - _192);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_sized(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6, shadow_tex, shadow_smp);\n    }\n    return r;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _497 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _501 = _497.x + 0.5;\n    float2 c = float2(_501, 0.5 - _497.y);\n    bool _509 = _501 >= 0.0;\n    bool _515;\n    if (_509)\n    {\n        _515 = c.x <= 1.0;\n    }\n    else\n    {\n        _515 = _509;\n    }\n    bool _521;\n    if (_515)\n    {\n        _521 = c.y >= 0.0;\n    }\n    else\n    {\n        _521 = _515;\n    }\n    bool _527;\n    if (_521)\n    {\n        _527 = c.y <= 1.0;\n    }\n    else\n    {\n        _527 = _521;\n    }\n    float2 _529 = c;\n    float2 _534 = fast::clamp(_529, float2(0.001953125), float2(0.998046875));\n    c = _534;\n    return float3(cell.x + (_534.x * cell.w), cell.y + (_534.y * cell.z), float(_527));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _692, texture2d<float> fx_cookie_tex, sampler light_smp)\n{\n    if (_692.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _692.light_cookie[i];\n    float4 param_1 = _692.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _803 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _803.xy, level(0.0));\n    return cookie_value(param_3) * _803.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _692, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _825 = _692.lit.y > 0.5;\n    if (_825)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _692.normal_uv.xy) + _692.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _849 = fa_tex_fix(param, param_1);\n        float3 _853 = (_849 * 2.0) - float3(1.0);\n        float _860 = cos(params.y);\n        float _862 = sin(params.y);\n        n = fast::normalize(float3((float2(_860, _862) * _853.x) + ((float2(-_862, _860) * ((mode > 5.5) ? (-1.0) : 1.0)) * _853.y), fast::max(_853.z, 0.0500000007450580596923828125)));\n    }\n    bool _896 = !_825;\n    bool _902;\n    if (_896)\n    {\n        _902 = _692.lit.z > 0.5;\n    }\n    else\n    {\n        _902 = _896;\n    }\n    float3 _905;\n    if (_902)\n    {\n        _905 = _692.flat_ambient.xyz;\n    }\n    else\n    {\n        _905 = _692.ambient.xyz;\n    }\n    float3 total = _905;\n    bool _922;\n    if (_902)\n    {\n        _922 = _692.lit.z < 1.5;\n    }\n    else\n    {\n        _922 = _902;\n    }\n    if (_922)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _692.light_map.xy), level(0.0)).xyz * _692.light_map.z);\n    }\n    float3 l;\n    float _1049;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _959;\n        if (!_902)\n        {\n            _959 = float(i) >= _692.lit.x;\n        }\n        else\n        {\n            _959 = _902;\n        }\n        if (_959)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_692.light_pos[i].w < 0.0)\n        {\n            l = _692.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _985 = _692.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_985) / fast::max(_692.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _692.light_color[i].w);\n            float3 _1005 = float3(_985, _692.light_pos[i].z);\n            l = _1005 / float3(fast::max(length(_1005), 9.9999997473787516355514526367188e-05));\n            if (_692.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _692.light_shadow_v[i].x;\n                float param_3 = _692.light_shadow_v[i].y;\n                float2 param_4 = -_985;\n                float param_5 = _692.light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp);\n            }\n            int param_6 = i;\n            float2 param_7 = -_985;\n            att *= cookie_att(param_6, param_7, _692, fx_cookie_tex, light_smp);\n        }\n        if (_825)\n        {\n            _1049 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1049 = 1.0;\n        }\n        total += (_692.light_color[i].xyz * (att * _1049));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _670 = fa_srgb_to_linear(param);\n        c = _670;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1299 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1303 = uv * _1299;\n    float _1309 = _1299.x;\n    float _1311 = _1299.y;\n    float _1313 = fast::clamp(shape_rs.x, 0.0, fast::min(_1309, _1311));\n    float2 _1324 = (abs(_1303) - _1299) + float2(_1313);\n    float d = (length(fast::max(_1324, float2(0.0))) + fast::min(fast::max(_1324.x, _1324.y), 0.0)) - _1313;\n    float ax = params.y;\n    bool _1345 = params.y > 15.0;\n    if (_1345)\n    {\n        ax -= 20.0;\n    }\n    float _1356;\n    if (ax <= (-1.5))\n    {\n        _1356 = (-2.0) - ax;\n    }\n    else\n    {\n        _1356 = 0.0;\n    }\n    if (_1356 > 0.0)\n    {\n        float _1370 = _1356 * 0.5;\n        d = abs(d + _1370) - _1370;\n    }\n    float _1378 = fwidth(d);\n    float _1379 = fast::max(_1378, 9.9999997473787516355514526367188e-05);\n    float _1389 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1379)), 0.0, 1.0);\n    float _1394;\n    if (shape_rs.y > _1379)\n    {\n        _1394 = (_1389 * _1389) * (3.0 - (2.0 * _1389));\n    }\n    else\n    {\n        _1394 = _1389;\n    }\n    float4 c = color;\n    bool _1416 = (_1356 <= 0.0) && (ax > (-0.5));\n    if (_1416)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1431 = cos(ax);\n            float _1433 = sin(ax);\n            g = ((dot(_1303, float2(_1431, _1433)) / fast::max((abs(_1431) * _1309) + (abs(_1433) * _1311), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1345)\n        {\n            float4 _1476 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1476;\n            float3 param = _1476.xyz;\n            float param_1 = xform.y;\n            float3 _1483 = fa_tex_fix(param, param_1);\n            float4 _2271 = c;\n            _2271.x = _1483.x;\n            _2271.y = _1483.y;\n            _2271.z = _1483.z;\n            c = _2271;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1495 = scene_rgb(param_2, xform);\n            float4 _1520 = mix(float4(color.xyz * color.w, color.w), float4(_1495 * color2.w, color2.w), float4(g));\n            float _1522 = _1520.w;\n            float3 _1525;\n            if (_1522 > 9.9999997473787516355514526367188e-06)\n            {\n                _1525 = _1520.xyz / float3(_1522);\n            }\n            else\n            {\n                _1525 = color.xyz;\n            }\n            c = float4(_1525, _1522);\n        }\n    }\n    float4 _2280 = c;\n    _2280.w = _2280.w * _1394;\n    c = _2280;\n    if (_1416 || (shape_rs.y > 0.0))\n    {\n        float _1566 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1575 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1575 + float3(_1566 * 0.0039215688593685626983642578125);\n            float3 _1581 = fa_srgb_to_linear(param_4);\n            float4 _2283 = c;\n            _2283.x = _1581.x;\n            _2283.y = _1581.y;\n            _2283.z = _1581.z;\n            c = _2283;\n        }\n        else\n        {\n            float4 _1591 = c;\n            float3 _1594 = _1591.xyz + float3(_1566 * 0.0039215688593685626983642578125);\n            float4 _2290 = _1591;\n            _2290.x = _1594.x;\n            _2290.y = _1594.y;\n            _2290.z = _1594.z;\n            c = _2290;\n        }\n        float4 _2295 = c;\n        _2295.w = fast::clamp(_2295.w + ((_1566 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2295.w)), 0.0, 1.0);\n        c = _2295;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _692, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, thread float2& params)\n{\n    float2 _1086 = float2(_692.fx_rim_uv.x, 0.0);\n    float4 _1088 = tex.sample(smp, (uv - _1086));\n    float _1089 = _1088.w;\n    float4 _1099 = tex.sample(smp, (uv + _1086));\n    float _1100 = _1099.w;\n    float2 _1108 = float2(0.0, _692.fx_rim_uv.y);\n    float4 _1110 = tex.sample(smp, (uv - _1108));\n    float _1111 = _1110.w;\n    float4 _1121 = tex.sample(smp, (uv + _1108));\n    float _1122 = _1121.w;\n    float _1137 = _1089 - _1100;\n    float _1140 = _1122 - _1111;\n    float _1150 = cos(params.y);\n    float _1152 = sin(params.y);\n    float2 _1178 = ((float2(_1150, _1152) * _1137) + ((float2(-_1152, _1150) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1140)) / float2(fast::max(length(float2(_1137, _1140)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _692.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_692.light_pos[i].w < 0.0)\n        {\n            to_l = _692.light_pos[i].xy / float2(fast::max(length(_692.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _1224 = _692.light_pos[i].xy - world_xy;\n            float _1227 = length(_1224);\n            att = powr(fast::clamp(1.0 - (_1227 / fast::max(_692.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _692.light_color[i].w);\n            to_l = _1224 / float2(fast::max(_1227, 9.9999997473787516355514526367188e-05));\n            if (_692.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _692.light_shadow_v[i].x;\n                float param_1 = _692.light_shadow_v[i].y;\n                float2 param_2 = -_1224;\n                float param_3 = _692.light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1224;\n            att *= cookie_att(param_4, param_5, _692, fx_cookie_tex, light_smp);\n        }\n        sum += (_692.light_color[i].xyz * (att * fast::max(dot(_1178, to_l), 0.0)));\n    }\n    return (sum * _692.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_1089, _1100), fast::min(_1111, _1122))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _692)\n{\n    float2 _698 = gl_FragCoord.xy * _692.fa_target.xy;\n    float _702 = _698.y;\n    return float2(_698.x, mix(_702, 1.0 - _702, _692.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _692, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _740 = base_mode < 0.5;\n    bool _751;\n    if (!_740)\n    {\n        _751 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _751 = _740;\n    }\n    float _752;\n    if (_751)\n    {\n        _752 = shape_half.x;\n    }\n    else\n    {\n        _752 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _692), _692.fa_time.x, base_mode, float4(0.0), _752 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _676 = scene_rgb(param, xform);\n    return _676;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, constant fa_material& _766)\n{\n    float3 param = _766.tint.xyz;\n    float4 _773 = s.color;\n    float3 _775 = _773.xyz * fa_scene_rgb(param, xform);\n    s.color.x = _775.x;\n    s.color.y = _775.y;\n    s.color.z = _775.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _692 [[buffer(1)]], constant fa_material& _766 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> fx_emissive_tex [[texture(4)]], texture2d<float> fx_cookie_tex [[texture(5)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1621 = in.params.x > 31.5;\n    if (_1621)\n    {\n        mode -= 32.0;\n    }\n    float _1629 = mode;\n    bool _1631 = _1629 > 15.5;\n    if (_1631)\n    {\n        mode -= 16.0;\n    }\n    float _1639 = mode;\n    bool _1641 = _1639 > 7.5;\n    if (_1641)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1631)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _692, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1631)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _692, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1703 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1705 = _1703 * in.color;\n                float4 param_6 = _1705;\n                float param_7 = mode;\n                float _1712 = _1705.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _692, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), _1712);\n                if (_692.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1712;\n                    float param_9 = mode;\n                    float4 _1728 = out.frag_color;\n                    float3 _1730 = _1728.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _692, in.uv, in.world_xy, fx_cookie_tex, light_smp, in.params);\n                    out.frag_color.x = _1730.x;\n                    out.frag_color.y = _1730.y;\n                    out.frag_color.z = _1730.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1760 = length(in.uv);\n                    float _1763 = fwidth(_1760);\n                    float _1764 = fast::max(_1763, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1760) / _1764) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1760) / _1764) + 0.5, 0.0, 1.0) * fast::clamp(((_1760 - in.params.y) / _1764) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1804 = fast::clamp(1.0 - _1760, 0.0, 1.0);\n                            cov = (_1804 * _1804) * (3.0 - (2.0 * _1804));\n                        }\n                    }\n                    float3 _1813;\n                    if (_1631)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1813 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _692, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1813 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1813, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_692.fx_emit.w > 0.5)\n    {\n        float3 e = _692.fx_emit.xyz;\n        if (_692.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _692.fx_emit_uv.xy) + _692.fx_emit_uv.zw)).xyz;\n            float param_13 = _692.fx_emit.w - 2.0;\n            float3 _1868 = fa_tex_fix(param_12, param_13);\n            e *= _1868;\n        }\n        float4 _1872 = out.frag_color;\n        float3 _1874 = _1872.xyz + e;\n        out.frag_color.x = _1874.x;\n        out.frag_color.y = _1874.y;\n        out.frag_color.z = _1874.z;\n    }\n    float param_14 = mode;\n    float4 _2201 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14, gl_FragCoord, _692, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _2201 };\n    fragment0(param_15, param_16, in.xform, _766);\n    _2201 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1621)\n    {\n        float4 _1900 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _1905 = scene_rgb(param_17, in.xform);\n        float3 _1909 = mix(_1900.xyz, _1905, float3(in.color2.w));\n        out.frag_color.x = _1909.x;\n        out.frag_color.y = _1909.y;\n        out.frag_color.z = _1909.z;\n    }\n    if (_1641)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1933 = _692.fog_col.w > 0.0;\n    bool _1941;\n    if (!_1933)\n    {\n        _1941 = _692.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1941 = _1933;\n    }\n    if (_1941)\n    {\n        float3 _1955 = float3(in.world_xy, in.world_z) - _692.fog_eye.xyz;\n        float _1962 = dot(_1955, _692.fog_c.xyz);\n        bool _1966 = _692.fog_c.w > 0.5;\n        float _1967;\n        if (_1966)\n        {\n            _1967 = _1962;\n        }\n        else\n        {\n            _1967 = length(_1955);\n        }\n        float _1979 = _1967 - _692.fog_b.x;\n        if (_1979 > 0.0)\n        {\n            float _1988 = _692.fog_col.w * _1979;\n            float tau = _1988 * _1988;\n            if (_692.fog_b.y > 0.0)\n            {\n                float _2004;\n                if (_1966)\n                {\n                    _2004 = in.world_xy.y - (_692.fog_c.y * _1962);\n                }\n                else\n                {\n                    _2004 = _692.fog_eye.y;\n                }\n                float _2025 = mix(_2004, in.world_xy.y, fast::clamp(_692.fog_b.x / _1967, 0.0, 1.0));\n                float _2029 = in.world_xy.y - _2025;\n                float _2034 = _2025 - _692.fog_b.z;\n                float _2039 = in.world_xy.y - _692.fog_b.z;\n                bool _2042 = _2034 <= 0.0;\n                bool _2043 = !_2042;\n                bool _2049;\n                if (_2043)\n                {\n                    _2049 = _692.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2049 = _2042;\n                }\n                float _2050;\n                if (_2049)\n                {\n                    _2050 = _692.fog_b.y;\n                }\n                else\n                {\n                    _2050 = _692.fog_b.y * exp(-fast::min(_692.fog_b.w * _2034, 80.0));\n                }\n                bool _2077;\n                if (_2043)\n                {\n                    _2077 = _692.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2077 = _2042;\n                }\n                float _2078;\n                if (_2077)\n                {\n                    _2078 = _692.fog_b.y * _2034;\n                }\n                else\n                {\n                    _2078 = (_692.fog_b.y * (1.0 - exp(-fast::min(_692.fog_b.w * _2034, 80.0)))) / _692.fog_b.w;\n                }\n                bool _2103 = _2039 <= 0.0;\n                bool _2110;\n                if (!_2103)\n                {\n                    _2110 = _692.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2110 = _2103;\n                }\n                float _2111;\n                if (_2110)\n                {\n                    _2111 = _692.fog_b.y * _2039;\n                }\n                else\n                {\n                    _2111 = (_692.fog_b.y * (1.0 - exp(-fast::min(_692.fog_b.w * _2039, 80.0)))) / _692.fog_b.w;\n                }\n                float _2138;\n                if (abs(_2029) < 0.001000000047497451305389404296875)\n                {\n                    _2138 = _2050;\n                }\n                else\n                {\n                    _2138 = (_2111 - _2078) / _2029;\n                }\n                tau += (_1979 * fast::max(_2138, 0.0));\n            }\n            float4 _2161 = out.frag_color;\n            float3 _2169 = mix(_2161.xyz, _692.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _2169.x;\n            out.frag_color.y = _2169.y;\n            out.frag_color.z = _2169.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "size": 1520,
            "struct_name": "quad_fs_params",
            "inst_name": "_692",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_766",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n};\n\nstruct fa_material\n{\n    float4 tint;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _107 = fa_linear_to_srgb(param);\n        c = _107;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _116 = fa_srgb_to_linear(param_1);\n            c = _116;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _155)\n{\n    float2 _162 = gl_FragCoord.xy * _155.fa_target.xy;\n    float _167 = _162.y;\n    return float2(_162.x, mix(_167, 1.0 - _167, _155.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _155, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _211 = base_mode < 0.5;\n    bool _222;\n    if (!_211)\n    {\n        _222 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _222 = _211;\n    }\n    float _223;\n    if (_222)\n    {\n        _223 = shape_half.x;\n    }\n    else\n    {\n        _223 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _155), _155.fa_time.x, base_mode, float4(0.0), _223 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _132 = fa_srgb_to_linear(param);\n        c = _132;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _138 = scene_rgb(param, xform);\n    return _138;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, constant fa_material& _237)\n{\n    float3 param = _237.tint.xyz;\n    float4 _244 = s.color;\n    float3 _246 = _244.xyz * fa_scene_rgb(param, xform);\n    s.color.x = _246.x;\n    s.color.y = _246.y;\n    s.color.z = _246.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _155 [[buffer(1)]], constant fa_material& _237 [[buffer(5)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _265 = tex.sample(smp, in.uv);\n    float3 param = _265.xyz;\n    float param_1 = in.xform.y;\n    float3 _274 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_274, _265.w) * in.color;\n    float param_2 = 0.0;\n    float4 _328 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _155, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _328 };\n    fragment0(param_3, param_4, in.xform, _237);\n    _328 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "size": 1520,
            "struct_name": "quad_fs_params",
            "inst_name": "_155",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_237",
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
