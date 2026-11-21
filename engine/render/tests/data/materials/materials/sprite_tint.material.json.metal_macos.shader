{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "dbae68a2cd91807fd7df084cee13eb559f2382809eb1ac9d2df2d325d7943acc",
  "slang": "metal_macos",
  "params": [
    "tint"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _147 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _147;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n};\n\nstruct fa_material\n{\n    float4 tint;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _370 = fa_linear_to_srgb(param);\n        c = _370;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _378 = fa_srgb_to_linear(param_1);\n            c = _378;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _389 = tex.sample(smp, p);\n    float3 param = _389.xyz;\n    float param_1 = xform.y;\n    float3 _399 = fa_tex_fix(param, param_1);\n    return float4(_399, _389.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _114 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_114.x * 255.0) + 0.5) * 256.0) + floor((_114.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _138 = length(d);\n    if (_138 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _152 = precise::atan2(d.y, d.x);\n    float a = _152;\n    float _155;\n    if (_152 < 0.0)\n    {\n        _155 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _155 = a;\n    }\n    a = _155;\n    float _167 = _155 * 162.9746551513671875;\n    float _172 = fast::min(floor(_167), 1023.0);\n    float _179 = _172 + 1.0;\n    float i1 = _179;\n    if (_179 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _172;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _138) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _138) + 0.5, 0.0, 1.0), _167 - _172);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _242 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _246 = _242.x + 0.5;\n    float2 c = float2(_246, 0.5 - _242.y);\n    bool _254 = _246 >= 0.0;\n    bool _260;\n    if (_254)\n    {\n        _260 = c.x <= 1.0;\n    }\n    else\n    {\n        _260 = _254;\n    }\n    bool _266;\n    if (_260)\n    {\n        _266 = c.y >= 0.0;\n    }\n    else\n    {\n        _266 = _260;\n    }\n    bool _272;\n    if (_266)\n    {\n        _272 = c.y <= 1.0;\n    }\n    else\n    {\n        _272 = _266;\n    }\n    float2 _274 = c;\n    float2 _279 = fast::clamp(_274, float2(0.001953125), float2(0.998046875));\n    c = _279;\n    return float3(cell.x + (_279.x * cell.w), cell.y + (_279.y * cell.z), float(_272));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _437, texture2d<float> fx_cookie_tex, sampler light_smp)\n{\n    if (_437.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _437.light_cookie[i];\n    float4 param_1 = _437.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _551 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _551.xy, level(0.0));\n    return cookie_value(param_3) * _551.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _437, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _573 = _437.lit.y > 0.5;\n    if (_573)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _437.normal_uv.xy) + _437.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _597 = fa_tex_fix(param, param_1);\n        float3 _601 = (_597 * 2.0) - float3(1.0);\n        float _608 = cos(params.y);\n        float _610 = sin(params.y);\n        n = fast::normalize(float3((float2(_608, _610) * _601.x) + ((float2(-_610, _608) * ((mode > 5.5) ? (-1.0) : 1.0)) * _601.y), fast::max(_601.z, 0.0500000007450580596923828125)));\n    }\n    bool _644 = !_573;\n    bool _650;\n    if (_644)\n    {\n        _650 = _437.lit.z > 0.5;\n    }\n    else\n    {\n        _650 = _644;\n    }\n    float3 _653;\n    if (_650)\n    {\n        _653 = _437.flat_ambient.xyz;\n    }\n    else\n    {\n        _653 = _437.ambient.xyz;\n    }\n    float3 total = _653;\n    bool _670;\n    if (_650)\n    {\n        _670 = _437.lit.z < 1.5;\n    }\n    else\n    {\n        _670 = _650;\n    }\n    if (_670)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _437.light_map.xy), level(0.0)).xyz * _437.light_map.z);\n    }\n    float3 l;\n    float _794;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _708;\n        if (!_650)\n        {\n            _708 = float(i) >= _437.lit.x;\n        }\n        else\n        {\n            _708 = _650;\n        }\n        if (_708)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_437.light_pos[i].w < 0.0)\n        {\n            l = _437.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _734 = _437.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_734) / fast::max(_437.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _437.light_color[i].w);\n            float3 _754 = float3(_734, _437.light_pos[i].z);\n            l = _754 / float3(fast::max(length(_754), 9.9999997473787516355514526367188e-05));\n            if (_437.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _437.light_shadow_v[i].x;\n                float2 param_3 = -_734;\n                float param_4 = _437.light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4, shadow_tex, shadow_smp);\n            }\n            int param_5 = i;\n            float2 param_6 = -_734;\n            att *= cookie_att(param_5, param_6, _437, fx_cookie_tex, light_smp);\n        }\n        if (_573)\n        {\n            _794 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _794 = 1.0;\n        }\n        total += (_437.light_color[i].xyz * (att * _794));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _415 = fa_srgb_to_linear(param);\n        c = _415;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1040 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1044 = uv * _1040;\n    float _1050 = _1040.x;\n    float _1052 = _1040.y;\n    float _1054 = fast::clamp(shape_rs.x, 0.0, fast::min(_1050, _1052));\n    float2 _1065 = (abs(_1044) - _1040) + float2(_1054);\n    float d = (length(fast::max(_1065, float2(0.0))) + fast::min(fast::max(_1065.x, _1065.y), 0.0)) - _1054;\n    float ax = params.y;\n    bool _1086 = params.y > 15.0;\n    if (_1086)\n    {\n        ax -= 20.0;\n    }\n    float _1097;\n    if (ax <= (-1.5))\n    {\n        _1097 = (-2.0) - ax;\n    }\n    else\n    {\n        _1097 = 0.0;\n    }\n    if (_1097 > 0.0)\n    {\n        float _1111 = _1097 * 0.5;\n        d = abs(d + _1111) - _1111;\n    }\n    float _1119 = fwidth(d);\n    float _1120 = fast::max(_1119, 9.9999997473787516355514526367188e-05);\n    float _1130 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1120)), 0.0, 1.0);\n    float _1135;\n    if (shape_rs.y > _1120)\n    {\n        _1135 = (_1130 * _1130) * (3.0 - (2.0 * _1130));\n    }\n    else\n    {\n        _1135 = _1130;\n    }\n    float4 c = color;\n    bool _1157 = (_1097 <= 0.0) && (ax > (-0.5));\n    if (_1157)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1172 = cos(ax);\n            float _1174 = sin(ax);\n            g = ((dot(_1044, float2(_1172, _1174)) / fast::max((abs(_1172) * _1050) + (abs(_1174) * _1052), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1086)\n        {\n            float4 _1217 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1217;\n            float3 param = _1217.xyz;\n            float param_1 = xform.y;\n            float3 _1224 = fa_tex_fix(param, param_1);\n            float4 _2012 = c;\n            _2012.x = _1224.x;\n            _2012.y = _1224.y;\n            _2012.z = _1224.z;\n            c = _2012;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1236 = scene_rgb(param_2, xform);\n            float4 _1261 = mix(float4(color.xyz * color.w, color.w), float4(_1236 * color2.w, color2.w), float4(g));\n            float _1263 = _1261.w;\n            float3 _1266;\n            if (_1263 > 9.9999997473787516355514526367188e-06)\n            {\n                _1266 = _1261.xyz / float3(_1263);\n            }\n            else\n            {\n                _1266 = color.xyz;\n            }\n            c = float4(_1266, _1263);\n        }\n    }\n    float4 _2021 = c;\n    _2021.w = _2021.w * _1135;\n    c = _2021;\n    if (_1157 || (shape_rs.y > 0.0))\n    {\n        float _1307 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1316 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1316 + float3(_1307 * 0.0039215688593685626983642578125);\n            float3 _1322 = fa_srgb_to_linear(param_4);\n            float4 _2024 = c;\n            _2024.x = _1322.x;\n            _2024.y = _1322.y;\n            _2024.z = _1322.z;\n            c = _2024;\n        }\n        else\n        {\n            float4 _1332 = c;\n            float3 _1335 = _1332.xyz + float3(_1307 * 0.0039215688593685626983642578125);\n            float4 _2031 = _1332;\n            _2031.x = _1335.x;\n            _2031.y = _1335.y;\n            _2031.z = _1335.z;\n            c = _2031;\n        }\n        float4 _2036 = c;\n        _2036.w = fast::clamp(_2036.w + ((_1307 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2036.w)), 0.0, 1.0);\n        c = _2036;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _437, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, thread float2& params)\n{\n    float2 _831 = float2(_437.fx_rim_uv.x, 0.0);\n    float4 _833 = tex.sample(smp, (uv - _831));\n    float _834 = _833.w;\n    float4 _844 = tex.sample(smp, (uv + _831));\n    float _845 = _844.w;\n    float2 _853 = float2(0.0, _437.fx_rim_uv.y);\n    float4 _855 = tex.sample(smp, (uv - _853));\n    float _856 = _855.w;\n    float4 _866 = tex.sample(smp, (uv + _853));\n    float _867 = _866.w;\n    float _882 = _834 - _845;\n    float _885 = _867 - _856;\n    float _895 = cos(params.y);\n    float _897 = sin(params.y);\n    float2 _923 = ((float2(_895, _897) * _882) + ((float2(-_897, _895) * ((mode > 5.5) ? (-1.0) : 1.0)) * _885)) / float2(fast::max(length(float2(_882, _885)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _437.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_437.light_pos[i].w < 0.0)\n        {\n            to_l = _437.light_pos[i].xy / float2(fast::max(length(_437.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _969 = _437.light_pos[i].xy - world_xy;\n            float _972 = length(_969);\n            att = powr(fast::clamp(1.0 - (_972 / fast::max(_437.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _437.light_color[i].w);\n            to_l = _969 / float2(fast::max(_972, 9.9999997473787516355514526367188e-05));\n            if (_437.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _437.light_shadow_v[i].x;\n                float2 param_1 = -_969;\n                float param_2 = _437.light_pos[i].w;\n                att *= light_shadow(param, param_1, param_2, shadow_tex, shadow_smp);\n            }\n            int param_3 = i;\n            float2 param_4 = -_969;\n            att *= cookie_att(param_3, param_4, _437, fx_cookie_tex, light_smp);\n        }\n        sum += (_437.light_color[i].xyz * (att * fast::max(dot(_923, to_l), 0.0)));\n    }\n    return (sum * _437.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_834, _845), fast::min(_856, _867))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _437)\n{\n    float2 _443 = gl_FragCoord.xy * _437.fa_target.xy;\n    float _447 = _443.y;\n    return float2(_443.x, mix(_447, 1.0 - _447, _437.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _437, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _488 = base_mode < 0.5;\n    bool _499;\n    if (!_488)\n    {\n        _499 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _499 = _488;\n    }\n    float _500;\n    if (_499)\n    {\n        _500 = shape_half.x;\n    }\n    else\n    {\n        _500 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _437), _437.fa_time.x, base_mode, float4(0.0), _500 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _421 = scene_rgb(param, xform);\n    return _421;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, constant fa_material& _514)\n{\n    float3 param = _514.tint.xyz;\n    float4 _521 = s.color;\n    float3 _523 = _521.xyz * fa_scene_rgb(param, xform);\n    s.color.x = _523.x;\n    s.color.y = _523.y;\n    s.color.z = _523.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _437 [[buffer(1)]], constant fa_material& _514 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> fx_emissive_tex [[texture(4)]], texture2d<float> fx_cookie_tex [[texture(5)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1362 = in.params.x > 31.5;\n    if (_1362)\n    {\n        mode -= 32.0;\n    }\n    float _1370 = mode;\n    bool _1372 = _1370 > 15.5;\n    if (_1372)\n    {\n        mode -= 16.0;\n    }\n    float _1380 = mode;\n    bool _1382 = _1380 > 7.5;\n    if (_1382)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1372)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _437, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1372)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _437, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1444 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1446 = _1444 * in.color;\n                float4 param_6 = _1446;\n                float param_7 = mode;\n                float _1453 = _1446.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _437, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), _1453);\n                if (_437.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1453;\n                    float param_9 = mode;\n                    float4 _1469 = out.frag_color;\n                    float3 _1471 = _1469.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _437, in.uv, in.world_xy, fx_cookie_tex, light_smp, in.params);\n                    out.frag_color.x = _1471.x;\n                    out.frag_color.y = _1471.y;\n                    out.frag_color.z = _1471.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1501 = length(in.uv);\n                    float _1504 = fwidth(_1501);\n                    float _1505 = fast::max(_1504, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1501) / _1505) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1501) / _1505) + 0.5, 0.0, 1.0) * fast::clamp(((_1501 - in.params.y) / _1505) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1545 = fast::clamp(1.0 - _1501, 0.0, 1.0);\n                            cov = (_1545 * _1545) * (3.0 - (2.0 * _1545));\n                        }\n                    }\n                    float3 _1554;\n                    if (_1372)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1554 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _437, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1554 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1554, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_437.fx_emit.w > 0.5)\n    {\n        float3 e = _437.fx_emit.xyz;\n        if (_437.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _437.fx_emit_uv.xy) + _437.fx_emit_uv.zw)).xyz;\n            float param_13 = _437.fx_emit.w - 2.0;\n            float3 _1609 = fa_tex_fix(param_12, param_13);\n            e *= _1609;\n        }\n        float4 _1613 = out.frag_color;\n        float3 _1615 = _1613.xyz + e;\n        out.frag_color.x = _1615.x;\n        out.frag_color.y = _1615.y;\n        out.frag_color.z = _1615.z;\n    }\n    float param_14 = mode;\n    float4 _1942 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14, gl_FragCoord, _437, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _1942 };\n    fragment0(param_15, param_16, in.xform, _514);\n    _1942 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1362)\n    {\n        float4 _1641 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _1646 = scene_rgb(param_17, in.xform);\n        float3 _1650 = mix(_1641.xyz, _1646, float3(in.color2.w));\n        out.frag_color.x = _1650.x;\n        out.frag_color.y = _1650.y;\n        out.frag_color.z = _1650.z;\n    }\n    if (_1382)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1674 = _437.fog_col.w > 0.0;\n    bool _1682;\n    if (!_1674)\n    {\n        _1682 = _437.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1682 = _1674;\n    }\n    if (_1682)\n    {\n        float3 _1696 = float3(in.world_xy, in.world_z) - _437.fog_eye.xyz;\n        float _1703 = dot(_1696, _437.fog_c.xyz);\n        bool _1707 = _437.fog_c.w > 0.5;\n        float _1708;\n        if (_1707)\n        {\n            _1708 = _1703;\n        }\n        else\n        {\n            _1708 = length(_1696);\n        }\n        float _1720 = _1708 - _437.fog_b.x;\n        if (_1720 > 0.0)\n        {\n            float _1729 = _437.fog_col.w * _1720;\n            float tau = _1729 * _1729;\n            if (_437.fog_b.y > 0.0)\n            {\n                float _1745;\n                if (_1707)\n                {\n                    _1745 = in.world_xy.y - (_437.fog_c.y * _1703);\n                }\n                else\n                {\n                    _1745 = _437.fog_eye.y;\n                }\n                float _1766 = mix(_1745, in.world_xy.y, fast::clamp(_437.fog_b.x / _1708, 0.0, 1.0));\n                float _1770 = in.world_xy.y - _1766;\n                float _1775 = _1766 - _437.fog_b.z;\n                float _1780 = in.world_xy.y - _437.fog_b.z;\n                bool _1783 = _1775 <= 0.0;\n                bool _1784 = !_1783;\n                bool _1790;\n                if (_1784)\n                {\n                    _1790 = _437.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1790 = _1783;\n                }\n                float _1791;\n                if (_1790)\n                {\n                    _1791 = _437.fog_b.y;\n                }\n                else\n                {\n                    _1791 = _437.fog_b.y * exp(-fast::min(_437.fog_b.w * _1775, 80.0));\n                }\n                bool _1818;\n                if (_1784)\n                {\n                    _1818 = _437.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1818 = _1783;\n                }\n                float _1819;\n                if (_1818)\n                {\n                    _1819 = _437.fog_b.y * _1775;\n                }\n                else\n                {\n                    _1819 = (_437.fog_b.y * (1.0 - exp(-fast::min(_437.fog_b.w * _1775, 80.0)))) / _437.fog_b.w;\n                }\n                bool _1844 = _1780 <= 0.0;\n                bool _1851;\n                if (!_1844)\n                {\n                    _1851 = _437.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1851 = _1844;\n                }\n                float _1852;\n                if (_1851)\n                {\n                    _1852 = _437.fog_b.y * _1780;\n                }\n                else\n                {\n                    _1852 = (_437.fog_b.y * (1.0 - exp(-fast::min(_437.fog_b.w * _1780, 80.0)))) / _437.fog_b.w;\n                }\n                float _1879;\n                if (abs(_1770) < 0.001000000047497451305389404296875)\n                {\n                    _1879 = _1791;\n                }\n                else\n                {\n                    _1879 = (_1852 - _1819) / _1770;\n                }\n                tau += (_1720 * fast::max(_1879, 0.0));\n            }\n            float4 _1902 = out.frag_color;\n            float3 _1910 = mix(_1902.xyz, _437.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _1910.x;\n            out.frag_color.y = _1910.y;\n            out.frag_color.z = _1910.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "inst_name": "_437",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_514",
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
