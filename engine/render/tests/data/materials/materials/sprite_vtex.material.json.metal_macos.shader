{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "dbae68a2cd91807fd7df084cee13eb559f2382809eb1ac9d2df2d325d7943acc",
  "slang": "metal_macos",
  "params": [],
  "textures": [
    "mask"
  ],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread QuadVertex& v, texture2d<float> fa_vs_mask, sampler fa_vs_mask_smp)\n{\n    v.world_pos.x += (fa_vs_mask.sample(fa_vs_mask_smp, float2(0.4000000059604644775390625, 0.0500000007450580596923828125), level(0.0)).x * 40.0);\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _96 [[buffer(0)]], texture2d<float> fa_vs_mask [[texture(0)]], sampler fa_vs_mask_smp [[sampler(7)]])\n{\n    main0_out out = {};\n    float3 _171 = in.position;\n    float2 _172 = in.texcoord0;\n    float4 _173 = in.color0;\n    if (_96.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _108 = fa_srgb_to_linear(param);\n        float4 _185 = _173;\n        _185.x = _108.x;\n        _185.y = _108.y;\n        _185.z = _108.z;\n        _173 = _185;\n    }\n    QuadVertex param_1 = QuadVertex{ _171, _172, _173 };\n    vertex0(param_1, fa_vs_mask, fa_vs_mask_smp);\n    _171 = param_1.world_pos;\n    _172 = param_1.uv;\n    _173 = param_1.color;\n    out.gl_Position = _96.view_proj * float4(param_1.world_pos, 1.0);\n    out.uv = param_1.uv;\n    out.color = param_1.color;\n    out.xform = _96.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = param_1.world_pos.xy;\n    out.world_z = param_1.world_pos.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _367 = fa_linear_to_srgb(param);\n        c = _367;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _375 = fa_srgb_to_linear(param_1);\n            c = _375;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _386 = tex.sample(smp, p);\n    float3 param = _386.xyz;\n    float param_1 = xform.y;\n    float3 _396 = fa_tex_fix(param, param_1);\n    return float4(_396, _386.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _111 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_111.x * 255.0) + 0.5) * 256.0) + floor((_111.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _135 = length(d);\n    if (_135 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _149 = precise::atan2(d.y, d.x);\n    float a = _149;\n    float _152;\n    if (_149 < 0.0)\n    {\n        _152 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _152 = a;\n    }\n    a = _152;\n    float _164 = _152 * 162.9746551513671875;\n    float _169 = fast::min(floor(_164), 1023.0);\n    float _176 = _169 + 1.0;\n    float i1 = _176;\n    if (_176 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _169;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _135) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _135) + 0.5, 0.0, 1.0), _164 - _169);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _239 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _243 = _239.x + 0.5;\n    float2 c = float2(_243, 0.5 - _239.y);\n    bool _251 = _243 >= 0.0;\n    bool _257;\n    if (_251)\n    {\n        _257 = c.x <= 1.0;\n    }\n    else\n    {\n        _257 = _251;\n    }\n    bool _263;\n    if (_257)\n    {\n        _263 = c.y >= 0.0;\n    }\n    else\n    {\n        _263 = _257;\n    }\n    bool _269;\n    if (_263)\n    {\n        _269 = c.y <= 1.0;\n    }\n    else\n    {\n        _269 = _263;\n    }\n    float2 _271 = c;\n    float2 _276 = fast::clamp(_271, float2(0.001953125), float2(0.998046875));\n    c = _276;\n    return float3(cell.x + (_276.x * cell.w), cell.y + (_276.y * cell.z), float(_269));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _429, texture2d<float> fx_cookie_tex, sampler light_smp)\n{\n    if (_429.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _429.light_cookie[i];\n    float4 param_1 = _429.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _541 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _541.xy, level(0.0));\n    return cookie_value(param_3) * _541.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _429, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _563 = _429.lit.y > 0.5;\n    if (_563)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _429.normal_uv.xy) + _429.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _587 = fa_tex_fix(param, param_1);\n        float3 _591 = (_587 * 2.0) - float3(1.0);\n        float _598 = cos(params.y);\n        float _600 = sin(params.y);\n        n = fast::normalize(float3((float2(_598, _600) * _591.x) + ((float2(-_600, _598) * ((mode > 5.5) ? (-1.0) : 1.0)) * _591.y), fast::max(_591.z, 0.0500000007450580596923828125)));\n    }\n    bool _633 = !_563;\n    bool _639;\n    if (_633)\n    {\n        _639 = _429.lit.z > 0.5;\n    }\n    else\n    {\n        _639 = _633;\n    }\n    float3 _642;\n    if (_639)\n    {\n        _642 = _429.flat_ambient.xyz;\n    }\n    else\n    {\n        _642 = _429.ambient.xyz;\n    }\n    float3 total = _642;\n    bool _659;\n    if (_639)\n    {\n        _659 = _429.lit.z < 1.5;\n    }\n    else\n    {\n        _659 = _639;\n    }\n    if (_659)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _429.light_map.xy), level(0.0)).xyz * _429.light_map.z);\n    }\n    float3 l;\n    float _783;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _697;\n        if (!_639)\n        {\n            _697 = float(i) >= _429.lit.x;\n        }\n        else\n        {\n            _697 = _639;\n        }\n        if (_697)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_429.light_pos[i].w < 0.0)\n        {\n            l = _429.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _723 = _429.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_723) / fast::max(_429.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _429.light_color[i].w);\n            float3 _743 = float3(_723, _429.light_pos[i].z);\n            l = _743 / float3(fast::max(length(_743), 9.9999997473787516355514526367188e-05));\n            if (_429.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _429.light_shadow_v[i].x;\n                float2 param_3 = -_723;\n                float param_4 = _429.light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4, shadow_tex, shadow_smp);\n            }\n            int param_5 = i;\n            float2 param_6 = -_723;\n            att *= cookie_att(param_5, param_6, _429, fx_cookie_tex, light_smp);\n        }\n        if (_563)\n        {\n            _783 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _783 = 1.0;\n        }\n        total += (_429.light_color[i].xyz * (att * _783));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _412 = fa_srgb_to_linear(param);\n        c = _412;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1029 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1033 = uv * _1029;\n    float _1039 = _1029.x;\n    float _1041 = _1029.y;\n    float _1043 = fast::clamp(shape_rs.x, 0.0, fast::min(_1039, _1041));\n    float2 _1054 = (abs(_1033) - _1029) + float2(_1043);\n    float d = (length(fast::max(_1054, float2(0.0))) + fast::min(fast::max(_1054.x, _1054.y), 0.0)) - _1043;\n    float ax = params.y;\n    bool _1075 = params.y > 15.0;\n    if (_1075)\n    {\n        ax -= 20.0;\n    }\n    float _1086;\n    if (ax <= (-1.5))\n    {\n        _1086 = (-2.0) - ax;\n    }\n    else\n    {\n        _1086 = 0.0;\n    }\n    if (_1086 > 0.0)\n    {\n        float _1100 = _1086 * 0.5;\n        d = abs(d + _1100) - _1100;\n    }\n    float _1108 = fwidth(d);\n    float _1109 = fast::max(_1108, 9.9999997473787516355514526367188e-05);\n    float _1119 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1109)), 0.0, 1.0);\n    float _1124;\n    if (shape_rs.y > _1109)\n    {\n        _1124 = (_1119 * _1119) * (3.0 - (2.0 * _1119));\n    }\n    else\n    {\n        _1124 = _1119;\n    }\n    float4 c = color;\n    bool _1146 = (_1086 <= 0.0) && (ax > (-0.5));\n    if (_1146)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1161 = cos(ax);\n            float _1163 = sin(ax);\n            g = ((dot(_1033, float2(_1161, _1163)) / fast::max((abs(_1161) * _1039) + (abs(_1163) * _1041), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1075)\n        {\n            float4 _1206 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1206;\n            float3 param = _1206.xyz;\n            float param_1 = xform.y;\n            float3 _1213 = fa_tex_fix(param, param_1);\n            float4 _2001 = c;\n            _2001.x = _1213.x;\n            _2001.y = _1213.y;\n            _2001.z = _1213.z;\n            c = _2001;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1225 = scene_rgb(param_2, xform);\n            float4 _1250 = mix(float4(color.xyz * color.w, color.w), float4(_1225 * color2.w, color2.w), float4(g));\n            float _1252 = _1250.w;\n            float3 _1255;\n            if (_1252 > 9.9999997473787516355514526367188e-06)\n            {\n                _1255 = _1250.xyz / float3(_1252);\n            }\n            else\n            {\n                _1255 = color.xyz;\n            }\n            c = float4(_1255, _1252);\n        }\n    }\n    float4 _2010 = c;\n    _2010.w = _2010.w * _1124;\n    c = _2010;\n    if (_1146 || (shape_rs.y > 0.0))\n    {\n        float _1296 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1305 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1305 + float3(_1296 * 0.0039215688593685626983642578125);\n            float3 _1311 = fa_srgb_to_linear(param_4);\n            float4 _2013 = c;\n            _2013.x = _1311.x;\n            _2013.y = _1311.y;\n            _2013.z = _1311.z;\n            c = _2013;\n        }\n        else\n        {\n            float4 _1321 = c;\n            float3 _1324 = _1321.xyz + float3(_1296 * 0.0039215688593685626983642578125);\n            float4 _2020 = _1321;\n            _2020.x = _1324.x;\n            _2020.y = _1324.y;\n            _2020.z = _1324.z;\n            c = _2020;\n        }\n        float4 _2025 = c;\n        _2025.w = fast::clamp(_2025.w + ((_1296 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2025.w)), 0.0, 1.0);\n        c = _2025;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _429, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, thread float2& params)\n{\n    float2 _820 = float2(_429.fx_rim_uv.x, 0.0);\n    float4 _822 = tex.sample(smp, (uv - _820));\n    float _823 = _822.w;\n    float4 _833 = tex.sample(smp, (uv + _820));\n    float _834 = _833.w;\n    float2 _842 = float2(0.0, _429.fx_rim_uv.y);\n    float4 _844 = tex.sample(smp, (uv - _842));\n    float _845 = _844.w;\n    float4 _855 = tex.sample(smp, (uv + _842));\n    float _856 = _855.w;\n    float _871 = _823 - _834;\n    float _874 = _856 - _845;\n    float _884 = cos(params.y);\n    float _886 = sin(params.y);\n    float2 _912 = ((float2(_884, _886) * _871) + ((float2(-_886, _884) * ((mode > 5.5) ? (-1.0) : 1.0)) * _874)) / float2(fast::max(length(float2(_871, _874)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _429.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_429.light_pos[i].w < 0.0)\n        {\n            to_l = _429.light_pos[i].xy / float2(fast::max(length(_429.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _958 = _429.light_pos[i].xy - world_xy;\n            float _961 = length(_958);\n            att = powr(fast::clamp(1.0 - (_961 / fast::max(_429.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _429.light_color[i].w);\n            to_l = _958 / float2(fast::max(_961, 9.9999997473787516355514526367188e-05));\n            if (_429.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _429.light_shadow_v[i].x;\n                float2 param_1 = -_958;\n                float param_2 = _429.light_pos[i].w;\n                att *= light_shadow(param, param_1, param_2, shadow_tex, shadow_smp);\n            }\n            int param_3 = i;\n            float2 param_4 = -_958;\n            att *= cookie_att(param_3, param_4, _429, fx_cookie_tex, light_smp);\n        }\n        sum += (_429.light_color[i].xyz * (att * fast::max(dot(_912, to_l), 0.0)));\n    }\n    return (sum * _429.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_823, _834), fast::min(_845, _856))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _429)\n{\n    float2 _435 = gl_FragCoord.xy * _429.fa_target.xy;\n    float _439 = _435.y;\n    return float2(_435.x, mix(_439, 1.0 - _439, _429.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _429, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _480 = base_mode < 0.5;\n    bool _491;\n    if (!_480)\n    {\n        _491 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _491 = _480;\n    }\n    float _492;\n    if (_491)\n    {\n        _492 = shape_half.x;\n    }\n    else\n    {\n        _492 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _429), _429.fa_time.x, base_mode, float4(0.0), _492 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, texture2d<float> mask, sampler mask_smp)\n{\n    float4 _512 = mask.sample(mask_smp, float2(0.4000000059604644775390625, 0.0500000007450580596923828125));\n    s.color.x = _512.x;\n    s.color.y = _512.y;\n    s.color.z = _512.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _429 [[buffer(1)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> mask [[texture(4)]], texture2d<float> fx_emissive_tex [[texture(5)]], texture2d<float> fx_cookie_tex [[texture(6)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], sampler mask_smp [[sampler(3)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1351 = in.params.x > 31.5;\n    if (_1351)\n    {\n        mode -= 32.0;\n    }\n    float _1359 = mode;\n    bool _1361 = _1359 > 15.5;\n    if (_1361)\n    {\n        mode -= 16.0;\n    }\n    float _1369 = mode;\n    bool _1371 = _1369 > 7.5;\n    if (_1371)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1361)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _429, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1361)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _429, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1433 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1435 = _1433 * in.color;\n                float4 param_6 = _1435;\n                float param_7 = mode;\n                float _1442 = _1435.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _429, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), _1442);\n                if (_429.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1442;\n                    float param_9 = mode;\n                    float4 _1458 = out.frag_color;\n                    float3 _1460 = _1458.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _429, in.uv, in.world_xy, fx_cookie_tex, light_smp, in.params);\n                    out.frag_color.x = _1460.x;\n                    out.frag_color.y = _1460.y;\n                    out.frag_color.z = _1460.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1490 = length(in.uv);\n                    float _1493 = fwidth(_1490);\n                    float _1494 = fast::max(_1493, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1490) / _1494) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1490) / _1494) + 0.5, 0.0, 1.0) * fast::clamp(((_1490 - in.params.y) / _1494) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1534 = fast::clamp(1.0 - _1490, 0.0, 1.0);\n                            cov = (_1534 * _1534) * (3.0 - (2.0 * _1534));\n                        }\n                    }\n                    float3 _1543;\n                    if (_1361)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1543 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _429, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1543 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1543, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_429.fx_emit.w > 0.5)\n    {\n        float3 e = _429.fx_emit.xyz;\n        if (_429.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _429.fx_emit_uv.xy) + _429.fx_emit_uv.zw)).xyz;\n            float param_13 = _429.fx_emit.w - 2.0;\n            float3 _1598 = fa_tex_fix(param_12, param_13);\n            e *= _1598;\n        }\n        float4 _1602 = out.frag_color;\n        float3 _1604 = _1602.xyz + e;\n        out.frag_color.x = _1604.x;\n        out.frag_color.y = _1604.y;\n        out.frag_color.z = _1604.z;\n    }\n    float param_14 = mode;\n    float4 _1931 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14, gl_FragCoord, _429, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _1931 };\n    fragment0(param_15, param_16, mask, mask_smp);\n    _1931 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1351)\n    {\n        float4 _1630 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _1635 = scene_rgb(param_17, in.xform);\n        float3 _1639 = mix(_1630.xyz, _1635, float3(in.color2.w));\n        out.frag_color.x = _1639.x;\n        out.frag_color.y = _1639.y;\n        out.frag_color.z = _1639.z;\n    }\n    if (_1371)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1663 = _429.fog_col.w > 0.0;\n    bool _1671;\n    if (!_1663)\n    {\n        _1671 = _429.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1671 = _1663;\n    }\n    if (_1671)\n    {\n        float3 _1685 = float3(in.world_xy, in.world_z) - _429.fog_eye.xyz;\n        float _1692 = dot(_1685, _429.fog_c.xyz);\n        bool _1696 = _429.fog_c.w > 0.5;\n        float _1697;\n        if (_1696)\n        {\n            _1697 = _1692;\n        }\n        else\n        {\n            _1697 = length(_1685);\n        }\n        float _1709 = _1697 - _429.fog_b.x;\n        if (_1709 > 0.0)\n        {\n            float _1718 = _429.fog_col.w * _1709;\n            float tau = _1718 * _1718;\n            if (_429.fog_b.y > 0.0)\n            {\n                float _1734;\n                if (_1696)\n                {\n                    _1734 = in.world_xy.y - (_429.fog_c.y * _1692);\n                }\n                else\n                {\n                    _1734 = _429.fog_eye.y;\n                }\n                float _1755 = mix(_1734, in.world_xy.y, fast::clamp(_429.fog_b.x / _1697, 0.0, 1.0));\n                float _1759 = in.world_xy.y - _1755;\n                float _1764 = _1755 - _429.fog_b.z;\n                float _1769 = in.world_xy.y - _429.fog_b.z;\n                bool _1772 = _1764 <= 0.0;\n                bool _1773 = !_1772;\n                bool _1779;\n                if (_1773)\n                {\n                    _1779 = _429.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1779 = _1772;\n                }\n                float _1780;\n                if (_1779)\n                {\n                    _1780 = _429.fog_b.y;\n                }\n                else\n                {\n                    _1780 = _429.fog_b.y * exp(-fast::min(_429.fog_b.w * _1764, 80.0));\n                }\n                bool _1807;\n                if (_1773)\n                {\n                    _1807 = _429.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1807 = _1772;\n                }\n                float _1808;\n                if (_1807)\n                {\n                    _1808 = _429.fog_b.y * _1764;\n                }\n                else\n                {\n                    _1808 = (_429.fog_b.y * (1.0 - exp(-fast::min(_429.fog_b.w * _1764, 80.0)))) / _429.fog_b.w;\n                }\n                bool _1833 = _1769 <= 0.0;\n                bool _1840;\n                if (!_1833)\n                {\n                    _1840 = _429.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1840 = _1833;\n                }\n                float _1841;\n                if (_1840)\n                {\n                    _1841 = _429.fog_b.y * _1769;\n                }\n                else\n                {\n                    _1841 = (_429.fog_b.y * (1.0 - exp(-fast::min(_429.fog_b.w * _1769, 80.0)))) / _429.fog_b.w;\n                }\n                float _1868;\n                if (abs(_1759) < 0.001000000047497451305389404296875)\n                {\n                    _1868 = _1780;\n                }\n                else\n                {\n                    _1868 = (_1841 - _1808) / _1759;\n                }\n                tau += (_1709 * fast::max(_1868, 0.0));\n            }\n            float4 _1891 = out.frag_color;\n            float3 _1899 = mix(_1891.xyz, _429.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _1899.x;\n            out.frag_color.y = _1899.y;\n            out.frag_color.z = _1899.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "size": 1520,
            "struct_name": "quad_fs_params",
            "inst_name": "_429",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _129)\n{\n    float2 _136 = gl_FragCoord.xy * _129.fa_target.xy;\n    float _142 = _136.y;\n    return float2(_136.x, mix(_142, 1.0 - _142, _129.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _129, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _186 = base_mode < 0.5;\n    bool _197;\n    if (!_186)\n    {\n        _197 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _197 = _186;\n    }\n    float _198;\n    if (_197)\n    {\n        _198 = shape_half.x;\n    }\n    else\n    {\n        _198 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _129), _129.fa_time.x, base_mode, float4(0.0), _198 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, texture2d<float> mask, sampler mask_smp)\n{\n    float4 _224 = mask.sample(mask_smp, float2(0.4000000059604644775390625, 0.0500000007450580596923828125));\n    s.color.x = _224.x;\n    s.color.y = _224.y;\n    s.color.z = _224.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _129 [[buffer(1)]], texture2d<float> tex [[texture(0)]], texture2d<float> mask [[texture(1)]], sampler smp [[sampler(0)]], sampler mask_smp [[sampler(3)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _239 = tex.sample(smp, in.uv);\n    float3 param = _239.xyz;\n    float param_1 = in.xform.y;\n    float3 _250 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_250, _239.w) * in.color;\n    float param_2 = 0.0;\n    float4 _304 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _129, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _304 };\n    fragment0(param_3, param_4, mask, mask_smp);\n    _304 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "size": 1520,
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
