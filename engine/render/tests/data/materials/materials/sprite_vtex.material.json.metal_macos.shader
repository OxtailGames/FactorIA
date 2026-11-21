{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "8dda08c124964ccb7d15a0a3238fb4669d4ca9ef375995bc9768b79891bfc837",
  "slang": "metal_macos",
  "params": [],
  "textures": [
    "mask"
  ],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread QuadVertex& v, texture2d<float> fa_vs_mask, sampler fa_vs_mask_smp)\n{\n    v.world_pos.x += (fa_vs_mask.sample(fa_vs_mask_smp, float2(0.4000000059604644775390625, 0.0500000007450580596923828125), level(0.0)).x * 40.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _96 [[buffer(0)]], texture2d<float> fa_vs_mask [[texture(0)]], sampler fa_vs_mask_smp [[sampler(7)]])\n{\n    main0_out out = {};\n    float3 _171 = in.position;\n    float2 _172 = in.texcoord0;\n    float4 _173 = in.color0;\n    if (_96.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _108 = fa_srgb_to_linear(param);\n        float4 _185 = _173;\n        _185.x = _108.x;\n        _185.y = _108.y;\n        _185.z = _108.z;\n        _173 = _185;\n    }\n    QuadVertex param_1 = QuadVertex{ _171, _172, _173 };\n    vertex0(param_1, fa_vs_mask, fa_vs_mask_smp);\n    _171 = param_1.world_pos;\n    _172 = param_1.uv;\n    _173 = param_1.color;\n    out.gl_Position = _96.view_proj * float4(param_1.world_pos, 1.0);\n    out.uv = param_1.uv;\n    out.color = param_1.color;\n    out.xform = _96.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = param_1.world_pos.xy;\n    out.world_z = param_1.world_pos.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _622 = fa_linear_to_srgb(param);\n        c = _622;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _630 = fa_srgb_to_linear(param_1);\n            c = _630;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _641 = tex.sample(smp, p);\n    float3 param = _641.xyz;\n    float param_1 = xform.y;\n    float3 _651 = fa_tex_fix(param, param_1);\n    return float4(_651, _641.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _131 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_131.x * 255.0) + 0.5) * 256.0) + floor((_131.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_tap(thread const float& v, thread const float& tt, thread const float& dist, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _234 = floor(tt);\n    float _244 = _234 - (1024.0 * floor(_234 * 0.0009765625));\n    float _247 = _244 + 1.0;\n    float i1 = _247;\n    if (_247 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _244;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), tt - _234);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_soft(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _284 = length(d);\n    float result = 1.0;\n    if (_284 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _295 = precise::atan2(d.y, d.x);\n        float a = _295;\n        float _298;\n        if (_295 < 0.0)\n        {\n            _298 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _298 = a;\n        }\n        a = _298;\n        float _308 = _298 * 162.9746551513671875;\n        float _317 = fast::min((size * 10.0) / _284, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _343 = floor(_308 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _317));\n            float param = v;\n            float param_1 = _343 - (1024.0 * floor(_343 * 0.0009765625));\n            float _357 = shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius;\n            if (_357 < _284)\n            {\n                sum += _357;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _389 = fast::min(size * ((1.0 / fast::max(sum / n, 1.0)) - (1.0 / _284)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _407 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _413 = 1.0 - (0.800000011920928955078125 * abs(_407));\n                float param_2 = v;\n                float param_3 = _308 + (_407 * _389);\n                float param_4 = _284;\n                float param_5 = radius;\n                acc += (_413 * light_shadow_tap(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp));\n                wsum += _413;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _155 = length(d);\n    if (_155 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _169 = precise::atan2(d.y, d.x);\n    float a = _169;\n    float _172;\n    if (_169 < 0.0)\n    {\n        _172 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _172 = a;\n    }\n    a = _172;\n    float _184 = _172 * 162.9746551513671875;\n    float _189 = fast::min(floor(_184), 1023.0);\n    float _196 = _189 + 1.0;\n    float i1 = _196;\n    if (_196 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _189;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _155) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _155) + 0.5, 0.0, 1.0), _184 - _189);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_sized(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6, shadow_tex, shadow_smp);\n    }\n    return r;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _494 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _498 = _494.x + 0.5;\n    float2 c = float2(_498, 0.5 - _494.y);\n    bool _506 = _498 >= 0.0;\n    bool _512;\n    if (_506)\n    {\n        _512 = c.x <= 1.0;\n    }\n    else\n    {\n        _512 = _506;\n    }\n    bool _518;\n    if (_512)\n    {\n        _518 = c.y >= 0.0;\n    }\n    else\n    {\n        _518 = _512;\n    }\n    bool _524;\n    if (_518)\n    {\n        _524 = c.y <= 1.0;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    float2 _526 = c;\n    float2 _531 = fast::clamp(_526, float2(0.001953125), float2(0.998046875));\n    c = _531;\n    return float3(cell.x + (_531.x * cell.w), cell.y + (_531.y * cell.z), float(_524));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _685, texture2d<float> fx_cookie_tex, sampler light_smp)\n{\n    if (_685.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _685.light_cookie[i];\n    float4 param_1 = _685.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _794 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _794.xy, level(0.0));\n    return cookie_value(param_3) * _794.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _685, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _816 = _685.lit.y > 0.5;\n    if (_816)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _685.normal_uv.xy) + _685.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _840 = fa_tex_fix(param, param_1);\n        float3 _844 = (_840 * 2.0) - float3(1.0);\n        float _851 = cos(params.y);\n        float _853 = sin(params.y);\n        n = fast::normalize(float3((float2(_851, _853) * _844.x) + ((float2(-_853, _851) * ((mode > 5.5) ? (-1.0) : 1.0)) * _844.y), fast::max(_844.z, 0.0500000007450580596923828125)));\n    }\n    bool _886 = !_816;\n    bool _892;\n    if (_886)\n    {\n        _892 = _685.lit.z > 0.5;\n    }\n    else\n    {\n        _892 = _886;\n    }\n    float3 _895;\n    if (_892)\n    {\n        _895 = _685.flat_ambient.xyz;\n    }\n    else\n    {\n        _895 = _685.ambient.xyz;\n    }\n    float3 total = _895;\n    bool _912;\n    if (_892)\n    {\n        _912 = _685.lit.z < 1.5;\n    }\n    else\n    {\n        _912 = _892;\n    }\n    if (_912)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _685.light_map.xy), level(0.0)).xyz * _685.light_map.z);\n    }\n    float3 l;\n    float _1039;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _949;\n        if (!_892)\n        {\n            _949 = float(i) >= _685.lit.x;\n        }\n        else\n        {\n            _949 = _892;\n        }\n        if (_949)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_685.light_pos[i].w < 0.0)\n        {\n            l = _685.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _975 = _685.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_975) / fast::max(_685.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _685.light_color[i].w);\n            float3 _995 = float3(_975, _685.light_pos[i].z);\n            l = _995 / float3(fast::max(length(_995), 9.9999997473787516355514526367188e-05));\n            if (_685.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _685.light_shadow_v[i].x;\n                float param_3 = _685.light_shadow_v[i].y;\n                float2 param_4 = -_975;\n                float param_5 = _685.light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp);\n            }\n            int param_6 = i;\n            float2 param_7 = -_975;\n            att *= cookie_att(param_6, param_7, _685, fx_cookie_tex, light_smp);\n        }\n        if (_816)\n        {\n            _1039 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1039 = 1.0;\n        }\n        total += (_685.light_color[i].xyz * (att * _1039));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _667 = fa_srgb_to_linear(param);\n        c = _667;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1289 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1293 = uv * _1289;\n    float _1299 = _1289.x;\n    float _1301 = _1289.y;\n    float _1303 = fast::clamp(shape_rs.x, 0.0, fast::min(_1299, _1301));\n    float2 _1314 = (abs(_1293) - _1289) + float2(_1303);\n    float d = (length(fast::max(_1314, float2(0.0))) + fast::min(fast::max(_1314.x, _1314.y), 0.0)) - _1303;\n    float ax = params.y;\n    bool _1335 = params.y > 15.0;\n    if (_1335)\n    {\n        ax -= 20.0;\n    }\n    float _1346;\n    if (ax <= (-1.5))\n    {\n        _1346 = (-2.0) - ax;\n    }\n    else\n    {\n        _1346 = 0.0;\n    }\n    if (_1346 > 0.0)\n    {\n        float _1360 = _1346 * 0.5;\n        d = abs(d + _1360) - _1360;\n    }\n    float _1368 = fwidth(d);\n    float _1369 = fast::max(_1368, 9.9999997473787516355514526367188e-05);\n    float _1379 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1369)), 0.0, 1.0);\n    float _1384;\n    if (shape_rs.y > _1369)\n    {\n        _1384 = (_1379 * _1379) * (3.0 - (2.0 * _1379));\n    }\n    else\n    {\n        _1384 = _1379;\n    }\n    float4 c = color;\n    bool _1406 = (_1346 <= 0.0) && (ax > (-0.5));\n    if (_1406)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1421 = cos(ax);\n            float _1423 = sin(ax);\n            g = ((dot(_1293, float2(_1421, _1423)) / fast::max((abs(_1421) * _1299) + (abs(_1423) * _1301), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1335)\n        {\n            float4 _1466 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1466;\n            float3 param = _1466.xyz;\n            float param_1 = xform.y;\n            float3 _1473 = fa_tex_fix(param, param_1);\n            float4 _2262 = c;\n            _2262.x = _1473.x;\n            _2262.y = _1473.y;\n            _2262.z = _1473.z;\n            c = _2262;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1485 = scene_rgb(param_2, xform);\n            float4 _1510 = mix(float4(color.xyz * color.w, color.w), float4(_1485 * color2.w, color2.w), float4(g));\n            float _1512 = _1510.w;\n            float3 _1515;\n            if (_1512 > 9.9999997473787516355514526367188e-06)\n            {\n                _1515 = _1510.xyz / float3(_1512);\n            }\n            else\n            {\n                _1515 = color.xyz;\n            }\n            c = float4(_1515, _1512);\n        }\n    }\n    float4 _2271 = c;\n    _2271.w = _2271.w * _1384;\n    c = _2271;\n    if (_1406 || (shape_rs.y > 0.0))\n    {\n        float _1556 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1565 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1565 + float3(_1556 * 0.0039215688593685626983642578125);\n            float3 _1571 = fa_srgb_to_linear(param_4);\n            float4 _2274 = c;\n            _2274.x = _1571.x;\n            _2274.y = _1571.y;\n            _2274.z = _1571.z;\n            c = _2274;\n        }\n        else\n        {\n            float4 _1581 = c;\n            float3 _1584 = _1581.xyz + float3(_1556 * 0.0039215688593685626983642578125);\n            float4 _2281 = _1581;\n            _2281.x = _1584.x;\n            _2281.y = _1584.y;\n            _2281.z = _1584.z;\n            c = _2281;\n        }\n        float4 _2286 = c;\n        _2286.w = fast::clamp(_2286.w + ((_1556 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2286.w)), 0.0, 1.0);\n        c = _2286;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _685, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, thread float2& params)\n{\n    float2 _1076 = float2(_685.fx_rim_uv.x, 0.0);\n    float4 _1078 = tex.sample(smp, (uv - _1076));\n    float _1079 = _1078.w;\n    float4 _1089 = tex.sample(smp, (uv + _1076));\n    float _1090 = _1089.w;\n    float2 _1098 = float2(0.0, _685.fx_rim_uv.y);\n    float4 _1100 = tex.sample(smp, (uv - _1098));\n    float _1101 = _1100.w;\n    float4 _1111 = tex.sample(smp, (uv + _1098));\n    float _1112 = _1111.w;\n    float _1127 = _1079 - _1090;\n    float _1130 = _1112 - _1101;\n    float _1140 = cos(params.y);\n    float _1142 = sin(params.y);\n    float2 _1168 = ((float2(_1140, _1142) * _1127) + ((float2(-_1142, _1140) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1130)) / float2(fast::max(length(float2(_1127, _1130)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _685.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_685.light_pos[i].w < 0.0)\n        {\n            to_l = _685.light_pos[i].xy / float2(fast::max(length(_685.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _1214 = _685.light_pos[i].xy - world_xy;\n            float _1217 = length(_1214);\n            att = powr(fast::clamp(1.0 - (_1217 / fast::max(_685.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _685.light_color[i].w);\n            to_l = _1214 / float2(fast::max(_1217, 9.9999997473787516355514526367188e-05));\n            if (_685.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _685.light_shadow_v[i].x;\n                float param_1 = _685.light_shadow_v[i].y;\n                float2 param_2 = -_1214;\n                float param_3 = _685.light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1214;\n            att *= cookie_att(param_4, param_5, _685, fx_cookie_tex, light_smp);\n        }\n        sum += (_685.light_color[i].xyz * (att * fast::max(dot(_1168, to_l), 0.0)));\n    }\n    return (sum * _685.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_1079, _1090), fast::min(_1101, _1112))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _685)\n{\n    float2 _691 = gl_FragCoord.xy * _685.fa_target.xy;\n    float _695 = _691.y;\n    return float2(_691.x, mix(_695, 1.0 - _695, _685.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _685, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _733 = base_mode < 0.5;\n    bool _744;\n    if (!_733)\n    {\n        _744 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _744 = _733;\n    }\n    float _745;\n    if (_744)\n    {\n        _745 = shape_half.x;\n    }\n    else\n    {\n        _745 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _685), _685.fa_time.x, base_mode, float4(0.0), _745 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, texture2d<float> mask, sampler mask_smp)\n{\n    float4 _765 = mask.sample(mask_smp, float2(0.4000000059604644775390625, 0.0500000007450580596923828125));\n    s.color.x = _765.x;\n    s.color.y = _765.y;\n    s.color.z = _765.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _685 [[buffer(1)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> mask [[texture(4)]], texture2d<float> fx_emissive_tex [[texture(5)]], texture2d<float> fx_cookie_tex [[texture(6)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], sampler mask_smp [[sampler(3)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1611 = in.params.x > 31.5;\n    if (_1611)\n    {\n        mode -= 32.0;\n    }\n    float _1619 = mode;\n    bool _1621 = _1619 > 15.5;\n    if (_1621)\n    {\n        mode -= 16.0;\n    }\n    float _1629 = mode;\n    bool _1631 = _1629 > 7.5;\n    if (_1631)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1621)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _685, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1621)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _685, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1693 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1695 = _1693 * in.color;\n                float4 param_6 = _1695;\n                float param_7 = mode;\n                float _1702 = _1695.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _685, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), _1702);\n                if (_685.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1702;\n                    float param_9 = mode;\n                    float4 _1718 = out.frag_color;\n                    float3 _1720 = _1718.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _685, in.uv, in.world_xy, fx_cookie_tex, light_smp, in.params);\n                    out.frag_color.x = _1720.x;\n                    out.frag_color.y = _1720.y;\n                    out.frag_color.z = _1720.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1750 = length(in.uv);\n                    float _1753 = fwidth(_1750);\n                    float _1754 = fast::max(_1753, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1750) / _1754) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1750) / _1754) + 0.5, 0.0, 1.0) * fast::clamp(((_1750 - in.params.y) / _1754) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1794 = fast::clamp(1.0 - _1750, 0.0, 1.0);\n                            cov = (_1794 * _1794) * (3.0 - (2.0 * _1794));\n                        }\n                    }\n                    float3 _1803;\n                    if (_1621)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1803 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _685, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1803 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1803, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_685.fx_emit.w > 0.5)\n    {\n        float3 e = _685.fx_emit.xyz;\n        if (_685.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _685.fx_emit_uv.xy) + _685.fx_emit_uv.zw)).xyz;\n            float param_13 = _685.fx_emit.w - 2.0;\n            float3 _1858 = fa_tex_fix(param_12, param_13);\n            e *= _1858;\n        }\n        float4 _1862 = out.frag_color;\n        float3 _1864 = _1862.xyz + e;\n        out.frag_color.x = _1864.x;\n        out.frag_color.y = _1864.y;\n        out.frag_color.z = _1864.z;\n    }\n    float param_14 = mode;\n    float4 _2192 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14, gl_FragCoord, _685, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _2192 };\n    fragment0(param_15, param_16, mask, mask_smp);\n    _2192 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1611)\n    {\n        float4 _1890 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _1895 = scene_rgb(param_17, in.xform);\n        float3 _1899 = mix(_1890.xyz, _1895, float3(in.color2.w));\n        out.frag_color.x = _1899.x;\n        out.frag_color.y = _1899.y;\n        out.frag_color.z = _1899.z;\n    }\n    if (_1631)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1923 = _685.fog_col.w > 0.0;\n    bool _1931;\n    if (!_1923)\n    {\n        _1931 = _685.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1931 = _1923;\n    }\n    if (_1931)\n    {\n        float3 _1945 = float3(in.world_xy, in.world_z) - _685.fog_eye.xyz;\n        float _1952 = dot(_1945, _685.fog_c.xyz);\n        bool _1956 = _685.fog_c.w > 0.5;\n        float _1957;\n        if (_1956)\n        {\n            _1957 = _1952;\n        }\n        else\n        {\n            _1957 = length(_1945);\n        }\n        float _1969 = _1957 - _685.fog_b.x;\n        if (_1969 > 0.0)\n        {\n            float _1978 = _685.fog_col.w * _1969;\n            float tau = _1978 * _1978;\n            if (_685.fog_b.y > 0.0)\n            {\n                float _1994;\n                if (_1956)\n                {\n                    _1994 = in.world_xy.y - (_685.fog_c.y * _1952);\n                }\n                else\n                {\n                    _1994 = _685.fog_eye.y;\n                }\n                float _2015 = mix(_1994, in.world_xy.y, fast::clamp(_685.fog_b.x / _1957, 0.0, 1.0));\n                float _2019 = in.world_xy.y - _2015;\n                float _2024 = _2015 - _685.fog_b.z;\n                float _2029 = in.world_xy.y - _685.fog_b.z;\n                bool _2032 = _2024 <= 0.0;\n                bool _2033 = !_2032;\n                bool _2039;\n                if (_2033)\n                {\n                    _2039 = _685.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2039 = _2032;\n                }\n                float _2040;\n                if (_2039)\n                {\n                    _2040 = _685.fog_b.y;\n                }\n                else\n                {\n                    _2040 = _685.fog_b.y * exp(-fast::min(_685.fog_b.w * _2024, 80.0));\n                }\n                bool _2067;\n                if (_2033)\n                {\n                    _2067 = _685.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2067 = _2032;\n                }\n                float _2068;\n                if (_2067)\n                {\n                    _2068 = _685.fog_b.y * _2024;\n                }\n                else\n                {\n                    _2068 = (_685.fog_b.y * (1.0 - exp(-fast::min(_685.fog_b.w * _2024, 80.0)))) / _685.fog_b.w;\n                }\n                bool _2093 = _2029 <= 0.0;\n                bool _2100;\n                if (!_2093)\n                {\n                    _2100 = _685.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2100 = _2093;\n                }\n                float _2101;\n                if (_2100)\n                {\n                    _2101 = _685.fog_b.y * _2029;\n                }\n                else\n                {\n                    _2101 = (_685.fog_b.y * (1.0 - exp(-fast::min(_685.fog_b.w * _2029, 80.0)))) / _685.fog_b.w;\n                }\n                float _2128;\n                if (abs(_2019) < 0.001000000047497451305389404296875)\n                {\n                    _2128 = _2040;\n                }\n                else\n                {\n                    _2128 = (_2101 - _2068) / _2019;\n                }\n                tau += (_1969 * fast::max(_2128, 0.0));\n            }\n            float4 _2151 = out.frag_color;\n            float3 _2159 = mix(_2151.xyz, _685.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _2159.x;\n            out.frag_color.y = _2159.y;\n            out.frag_color.z = _2159.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "inst_name": "_96",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 1584,
            "struct_name": "quad_fs_params",
            "inst_name": "_685",
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
              "slot": 8,
              "stage": "vertex",
              "name": "fa_vs_mask",
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
          }
        ],
        "samplers": [
          {
            "slot": 7,
            "stage": "vertex",
            "name": "fa_vs_mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 7
          },
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
            "stage": "vertex",
            "name": "fa_vs_mask_fa_vs_mask_smp",
            "view_name": "fa_vs_mask",
            "sampler_name": "fa_vs_mask_smp",
            "view_slot": 8,
            "sampler_slot": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "tex_smp",
            "view_name": "tex",
            "sampler_name": "smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "normal_tex_smp",
            "view_name": "normal_tex",
            "sampler_name": "smp",
            "view_slot": 1,
            "sampler_slot": 0
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread QuadVertex& v, texture2d<float> fa_vs_mask, sampler fa_vs_mask_smp)\n{\n    v.world_pos.x += (fa_vs_mask.sample(fa_vs_mask_smp, float2(0.4000000059604644775390625, 0.0500000007450580596923828125), level(0.0)).x * 40.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _96 [[buffer(0)]], texture2d<float> fa_vs_mask [[texture(0)]], sampler fa_vs_mask_smp [[sampler(7)]])\n{\n    main0_out out = {};\n    float3 _171 = in.position;\n    float2 _172 = in.texcoord0;\n    float4 _173 = in.color0;\n    if (_96.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _108 = fa_srgb_to_linear(param);\n        float4 _185 = _173;\n        _185.x = _108.x;\n        _185.y = _108.y;\n        _185.z = _108.z;\n        _173 = _185;\n    }\n    QuadVertex param_1 = QuadVertex{ _171, _172, _173 };\n    vertex0(param_1, fa_vs_mask, fa_vs_mask_smp);\n    _171 = param_1.world_pos;\n    _172 = param_1.uv;\n    _173 = param_1.color;\n    out.gl_Position = _96.view_proj * float4(param_1.world_pos, 1.0);\n    out.uv = param_1.uv;\n    out.color = param_1.color;\n    out.xform = _96.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = param_1.world_pos.xy;\n    out.world_z = param_1.world_pos.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _131)\n{\n    float2 _138 = gl_FragCoord.xy * _131.fa_target.xy;\n    float _144 = _138.y;\n    return float2(_138.x, mix(_144, 1.0 - _144, _131.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _131, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _188 = base_mode < 0.5;\n    bool _199;\n    if (!_188)\n    {\n        _199 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _199 = _188;\n    }\n    float _200;\n    if (_199)\n    {\n        _200 = shape_half.x;\n    }\n    else\n    {\n        _200 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _131), _131.fa_time.x, base_mode, float4(0.0), _200 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, texture2d<float> mask, sampler mask_smp)\n{\n    float4 _226 = mask.sample(mask_smp, float2(0.4000000059604644775390625, 0.0500000007450580596923828125));\n    s.color.x = _226.x;\n    s.color.y = _226.y;\n    s.color.z = _226.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _131 [[buffer(1)]], texture2d<float> tex [[texture(0)]], texture2d<float> mask [[texture(1)]], sampler smp [[sampler(0)]], sampler mask_smp [[sampler(3)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _241 = tex.sample(smp, in.uv);\n    float3 param = _241.xyz;\n    float param_1 = in.xform.y;\n    float3 _252 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_252, _241.w) * in.color;\n    float param_2 = 0.0;\n    float4 _307 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _131, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _307 };\n    fragment0(param_3, param_4, mask, mask_smp);\n    _307 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "inst_name": "_96",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 1584,
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
          },
          {
            "texture": {
              "slot": 8,
              "stage": "vertex",
              "name": "fa_vs_mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 7,
            "stage": "vertex",
            "name": "fa_vs_mask_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 7
          },
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
            "stage": "vertex",
            "name": "fa_vs_mask_fa_vs_mask_smp",
            "view_name": "fa_vs_mask",
            "sampler_name": "fa_vs_mask_smp",
            "view_slot": 8,
            "sampler_slot": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "tex_smp",
            "view_name": "tex",
            "sampler_name": "smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 2,
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
