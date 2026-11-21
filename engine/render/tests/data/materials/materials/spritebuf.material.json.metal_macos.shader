{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "8dda08c124964ccb7d15a0a3238fb4669d4ca9ef375995bc9768b79891bfc837",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "buffers": [
    {
      "name": "points",
      "binding": 0,
      "stride": 32,
      "access": "read",
      "fields": [
        {
          "name": "pos",
          "type": "vec4",
          "offset": 0
        },
        {
          "name": "tint",
          "type": "vec4",
          "offset": 16
        }
      ]
    }
  ],
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    int fa_inst_index_v [[user(locn9)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread QuadVertex& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex)\n{\n    float3 _68 = v.world_pos;\n    float2 _76 = fa_vs_points.data[int(gl_InstanceIndex)].pos.xy + (_68.xy * fa_vs_points.data[int(gl_InstanceIndex)].pos.w);\n    v.world_pos.x = _76.x;\n    v.world_pos.y = _76.y;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _105 [[buffer(0)]], const device fa_vs_points_buf& fa_vs_points [[buffer(8)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    out.fa_inst_index_v = int(gl_InstanceIndex);\n    float3 _178 = in.position;\n    float2 _179 = in.texcoord0;\n    float4 _180 = in.color0;\n    if (_105.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _117 = fa_srgb_to_linear(param);\n        float4 _192 = _180;\n        _192.x = _117.x;\n        _192.y = _117.y;\n        _192.z = _117.z;\n        _180 = _192;\n    }\n    QuadVertex param_1 = QuadVertex{ _178, _179, _180 };\n    vertex0(param_1, fa_vs_points, gl_InstanceIndex);\n    _178 = param_1.world_pos;\n    _179 = param_1.uv;\n    _180 = param_1.color;\n    out.gl_Position = _105.view_proj * float4(param_1.world_pos, 1.0);\n    out.uv = param_1.uv;\n    out.color = param_1.color;\n    out.xform = _105.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = param_1.world_pos.xy;\n    out.world_z = param_1.world_pos.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    int fa_inst_index_v [[user(locn9)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _622 = fa_linear_to_srgb(param);\n        c = _622;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _630 = fa_srgb_to_linear(param_1);\n            c = _630;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _641 = tex.sample(smp, p);\n    float3 param = _641.xyz;\n    float param_1 = xform.y;\n    float3 _651 = fa_tex_fix(param, param_1);\n    return float4(_651, _641.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _131 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_131.x * 255.0) + 0.5) * 256.0) + floor((_131.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_tap(thread const float& v, thread const float& tt, thread const float& dist, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _234 = floor(tt);\n    float _244 = _234 - (1024.0 * floor(_234 * 0.0009765625));\n    float _247 = _244 + 1.0;\n    float i1 = _247;\n    if (_247 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _244;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), tt - _234);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_soft(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _284 = length(d);\n    float result = 1.0;\n    if (_284 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _295 = precise::atan2(d.y, d.x);\n        float a = _295;\n        float _298;\n        if (_295 < 0.0)\n        {\n            _298 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _298 = a;\n        }\n        a = _298;\n        float _308 = _298 * 162.9746551513671875;\n        float _317 = fast::min((size * 10.0) / _284, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _343 = floor(_308 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _317));\n            float param = v;\n            float param_1 = _343 - (1024.0 * floor(_343 * 0.0009765625));\n            float _357 = shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius;\n            if (_357 < _284)\n            {\n                sum += _357;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _389 = fast::min(size * ((1.0 / fast::max(sum / n, 1.0)) - (1.0 / _284)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _407 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _413 = 1.0 - (0.800000011920928955078125 * abs(_407));\n                float param_2 = v;\n                float param_3 = _308 + (_407 * _389);\n                float param_4 = _284;\n                float param_5 = radius;\n                acc += (_413 * light_shadow_tap(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp));\n                wsum += _413;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _155 = length(d);\n    if (_155 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _169 = precise::atan2(d.y, d.x);\n    float a = _169;\n    float _172;\n    if (_169 < 0.0)\n    {\n        _172 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _172 = a;\n    }\n    a = _172;\n    float _184 = _172 * 162.9746551513671875;\n    float _189 = fast::min(floor(_184), 1023.0);\n    float _196 = _189 + 1.0;\n    float i1 = _196;\n    if (_196 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _189;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _155) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _155) + 0.5, 0.0, 1.0), _184 - _189);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_sized(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6, shadow_tex, shadow_smp);\n    }\n    return r;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _494 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _498 = _494.x + 0.5;\n    float2 c = float2(_498, 0.5 - _494.y);\n    bool _506 = _498 >= 0.0;\n    bool _512;\n    if (_506)\n    {\n        _512 = c.x <= 1.0;\n    }\n    else\n    {\n        _512 = _506;\n    }\n    bool _518;\n    if (_512)\n    {\n        _518 = c.y >= 0.0;\n    }\n    else\n    {\n        _518 = _512;\n    }\n    bool _524;\n    if (_518)\n    {\n        _524 = c.y <= 1.0;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    float2 _526 = c;\n    float2 _531 = fast::clamp(_526, float2(0.001953125), float2(0.998046875));\n    c = _531;\n    return float3(cell.x + (_531.x * cell.w), cell.y + (_531.y * cell.z), float(_524));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _685, texture2d<float> fx_cookie_tex, sampler light_smp)\n{\n    if (_685.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _685.light_cookie[i];\n    float4 param_1 = _685.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _795 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _795.xy, level(0.0));\n    return cookie_value(param_3) * _795.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _685, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _817 = _685.lit.y > 0.5;\n    if (_817)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _685.normal_uv.xy) + _685.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _841 = fa_tex_fix(param, param_1);\n        float3 _845 = (_841 * 2.0) - float3(1.0);\n        float _852 = cos(params.y);\n        float _854 = sin(params.y);\n        n = fast::normalize(float3((float2(_852, _854) * _845.x) + ((float2(-_854, _852) * ((mode > 5.5) ? (-1.0) : 1.0)) * _845.y), fast::max(_845.z, 0.0500000007450580596923828125)));\n    }\n    bool _888 = !_817;\n    bool _894;\n    if (_888)\n    {\n        _894 = _685.lit.z > 0.5;\n    }\n    else\n    {\n        _894 = _888;\n    }\n    float3 _897;\n    if (_894)\n    {\n        _897 = _685.flat_ambient.xyz;\n    }\n    else\n    {\n        _897 = _685.ambient.xyz;\n    }\n    float3 total = _897;\n    bool _914;\n    if (_894)\n    {\n        _914 = _685.lit.z < 1.5;\n    }\n    else\n    {\n        _914 = _894;\n    }\n    if (_914)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _685.light_map.xy), level(0.0)).xyz * _685.light_map.z);\n    }\n    float3 l;\n    float _1041;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _951;\n        if (!_894)\n        {\n            _951 = float(i) >= _685.lit.x;\n        }\n        else\n        {\n            _951 = _894;\n        }\n        if (_951)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_685.light_pos[i].w < 0.0)\n        {\n            l = _685.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _977 = _685.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_977) / fast::max(_685.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _685.light_color[i].w);\n            float3 _997 = float3(_977, _685.light_pos[i].z);\n            l = _997 / float3(fast::max(length(_997), 9.9999997473787516355514526367188e-05));\n            if (_685.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _685.light_shadow_v[i].x;\n                float param_3 = _685.light_shadow_v[i].y;\n                float2 param_4 = -_977;\n                float param_5 = _685.light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp);\n            }\n            int param_6 = i;\n            float2 param_7 = -_977;\n            att *= cookie_att(param_6, param_7, _685, fx_cookie_tex, light_smp);\n        }\n        if (_817)\n        {\n            _1041 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _1041 = 1.0;\n        }\n        total += (_685.light_color[i].xyz * (att * _1041));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _667 = fa_srgb_to_linear(param);\n        c = _667;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1291 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1295 = uv * _1291;\n    float _1301 = _1291.x;\n    float _1303 = _1291.y;\n    float _1305 = fast::clamp(shape_rs.x, 0.0, fast::min(_1301, _1303));\n    float2 _1316 = (abs(_1295) - _1291) + float2(_1305);\n    float d = (length(fast::max(_1316, float2(0.0))) + fast::min(fast::max(_1316.x, _1316.y), 0.0)) - _1305;\n    float ax = params.y;\n    bool _1337 = params.y > 15.0;\n    if (_1337)\n    {\n        ax -= 20.0;\n    }\n    float _1348;\n    if (ax <= (-1.5))\n    {\n        _1348 = (-2.0) - ax;\n    }\n    else\n    {\n        _1348 = 0.0;\n    }\n    if (_1348 > 0.0)\n    {\n        float _1362 = _1348 * 0.5;\n        d = abs(d + _1362) - _1362;\n    }\n    float _1370 = fwidth(d);\n    float _1371 = fast::max(_1370, 9.9999997473787516355514526367188e-05);\n    float _1381 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1371)), 0.0, 1.0);\n    float _1386;\n    if (shape_rs.y > _1371)\n    {\n        _1386 = (_1381 * _1381) * (3.0 - (2.0 * _1381));\n    }\n    else\n    {\n        _1386 = _1381;\n    }\n    float4 c = color;\n    bool _1408 = (_1348 <= 0.0) && (ax > (-0.5));\n    if (_1408)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1423 = cos(ax);\n            float _1425 = sin(ax);\n            g = ((dot(_1295, float2(_1423, _1425)) / fast::max((abs(_1423) * _1301) + (abs(_1425) * _1303), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1337)\n        {\n            float4 _1468 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1468;\n            float3 param = _1468.xyz;\n            float param_1 = xform.y;\n            float3 _1475 = fa_tex_fix(param, param_1);\n            float4 _2264 = c;\n            _2264.x = _1475.x;\n            _2264.y = _1475.y;\n            _2264.z = _1475.z;\n            c = _2264;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1487 = scene_rgb(param_2, xform);\n            float4 _1512 = mix(float4(color.xyz * color.w, color.w), float4(_1487 * color2.w, color2.w), float4(g));\n            float _1514 = _1512.w;\n            float3 _1517;\n            if (_1514 > 9.9999997473787516355514526367188e-06)\n            {\n                _1517 = _1512.xyz / float3(_1514);\n            }\n            else\n            {\n                _1517 = color.xyz;\n            }\n            c = float4(_1517, _1514);\n        }\n    }\n    float4 _2273 = c;\n    _2273.w = _2273.w * _1386;\n    c = _2273;\n    if (_1408 || (shape_rs.y > 0.0))\n    {\n        float _1558 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1567 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1567 + float3(_1558 * 0.0039215688593685626983642578125);\n            float3 _1573 = fa_srgb_to_linear(param_4);\n            float4 _2276 = c;\n            _2276.x = _1573.x;\n            _2276.y = _1573.y;\n            _2276.z = _1573.z;\n            c = _2276;\n        }\n        else\n        {\n            float4 _1583 = c;\n            float3 _1586 = _1583.xyz + float3(_1558 * 0.0039215688593685626983642578125);\n            float4 _2283 = _1583;\n            _2283.x = _1586.x;\n            _2283.y = _1586.y;\n            _2283.z = _1586.z;\n            c = _2283;\n        }\n        float4 _2288 = c;\n        _2288.w = fast::clamp(_2288.w + ((_1558 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2288.w)), 0.0, 1.0);\n        c = _2288;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _685, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, thread float2& params)\n{\n    float2 _1078 = float2(_685.fx_rim_uv.x, 0.0);\n    float4 _1080 = tex.sample(smp, (uv - _1078));\n    float _1081 = _1080.w;\n    float4 _1091 = tex.sample(smp, (uv + _1078));\n    float _1092 = _1091.w;\n    float2 _1100 = float2(0.0, _685.fx_rim_uv.y);\n    float4 _1102 = tex.sample(smp, (uv - _1100));\n    float _1103 = _1102.w;\n    float4 _1113 = tex.sample(smp, (uv + _1100));\n    float _1114 = _1113.w;\n    float _1129 = _1081 - _1092;\n    float _1132 = _1114 - _1103;\n    float _1142 = cos(params.y);\n    float _1144 = sin(params.y);\n    float2 _1170 = ((float2(_1142, _1144) * _1129) + ((float2(-_1144, _1142) * ((mode > 5.5) ? (-1.0) : 1.0)) * _1132)) / float2(fast::max(length(float2(_1129, _1132)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _685.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_685.light_pos[i].w < 0.0)\n        {\n            to_l = _685.light_pos[i].xy / float2(fast::max(length(_685.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _1216 = _685.light_pos[i].xy - world_xy;\n            float _1219 = length(_1216);\n            att = powr(fast::clamp(1.0 - (_1219 / fast::max(_685.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _685.light_color[i].w);\n            to_l = _1216 / float2(fast::max(_1219, 9.9999997473787516355514526367188e-05));\n            if (_685.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _685.light_shadow_v[i].x;\n                float param_1 = _685.light_shadow_v[i].y;\n                float2 param_2 = -_1216;\n                float param_3 = _685.light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1216;\n            att *= cookie_att(param_4, param_5, _685, fx_cookie_tex, light_smp);\n        }\n        sum += (_685.light_color[i].xyz * (att * fast::max(dot(_1170, to_l), 0.0)));\n    }\n    return (sum * _685.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_1081, _1092), fast::min(_1103, _1114))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _685)\n{\n    float2 _691 = gl_FragCoord.xy * _685.fa_target.xy;\n    float _695 = _691.y;\n    return float2(_691.x, mix(_695, 1.0 - _695, _685.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _685, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _733 = base_mode < 0.5;\n    bool _744;\n    if (!_733)\n    {\n        _744 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _744 = _733;\n    }\n    float _745;\n    if (_744)\n    {\n        _745 = shape_half.x;\n    }\n    else\n    {\n        _745 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _685), _685.fa_time.x, base_mode, float4(0.0), _745 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, const device fa_points_buf& points, thread int& fa_inst_index_v)\n{\n    s.color.x = points.data[fa_inst_index_v].tint.x;\n    s.color.y = points.data[fa_inst_index_v].tint.y;\n    s.color.z = points.data[fa_inst_index_v].tint.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _685 [[buffer(1)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> fx_emissive_tex [[texture(4)]], texture2d<float> fx_cookie_tex [[texture(5)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1613 = in.params.x > 31.5;\n    if (_1613)\n    {\n        mode -= 32.0;\n    }\n    float _1621 = mode;\n    bool _1623 = _1621 > 15.5;\n    if (_1623)\n    {\n        mode -= 16.0;\n    }\n    float _1631 = mode;\n    bool _1633 = _1631 > 7.5;\n    if (_1633)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1623)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _685, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1623)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _685, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1695 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1697 = _1695 * in.color;\n                float4 param_6 = _1697;\n                float param_7 = mode;\n                float _1704 = _1697.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _685, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), _1704);\n                if (_685.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1704;\n                    float param_9 = mode;\n                    float4 _1720 = out.frag_color;\n                    float3 _1722 = _1720.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _685, in.uv, in.world_xy, fx_cookie_tex, light_smp, in.params);\n                    out.frag_color.x = _1722.x;\n                    out.frag_color.y = _1722.y;\n                    out.frag_color.z = _1722.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1752 = length(in.uv);\n                    float _1755 = fwidth(_1752);\n                    float _1756 = fast::max(_1755, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1752) / _1756) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1752) / _1756) + 0.5, 0.0, 1.0) * fast::clamp(((_1752 - in.params.y) / _1756) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1796 = fast::clamp(1.0 - _1752, 0.0, 1.0);\n                            cov = (_1796 * _1796) * (3.0 - (2.0 * _1796));\n                        }\n                    }\n                    float3 _1805;\n                    if (_1623)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1805 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _685, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1805 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1805, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_685.fx_emit.w > 0.5)\n    {\n        float3 e = _685.fx_emit.xyz;\n        if (_685.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _685.fx_emit_uv.xy) + _685.fx_emit_uv.zw)).xyz;\n            float param_13 = _685.fx_emit.w - 2.0;\n            float3 _1860 = fa_tex_fix(param_12, param_13);\n            e *= _1860;\n        }\n        float4 _1864 = out.frag_color;\n        float3 _1866 = _1864.xyz + e;\n        out.frag_color.x = _1866.x;\n        out.frag_color.y = _1866.y;\n        out.frag_color.z = _1866.z;\n    }\n    float param_14 = mode;\n    float4 _2194 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14, gl_FragCoord, _685, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _2194 };\n    fragment0(param_15, param_16, points, in.fa_inst_index_v);\n    _2194 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1613)\n    {\n        float4 _1892 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _1897 = scene_rgb(param_17, in.xform);\n        float3 _1901 = mix(_1892.xyz, _1897, float3(in.color2.w));\n        out.frag_color.x = _1901.x;\n        out.frag_color.y = _1901.y;\n        out.frag_color.z = _1901.z;\n    }\n    if (_1633)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1925 = _685.fog_col.w > 0.0;\n    bool _1933;\n    if (!_1925)\n    {\n        _1933 = _685.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1933 = _1925;\n    }\n    if (_1933)\n    {\n        float3 _1947 = float3(in.world_xy, in.world_z) - _685.fog_eye.xyz;\n        float _1954 = dot(_1947, _685.fog_c.xyz);\n        bool _1958 = _685.fog_c.w > 0.5;\n        float _1959;\n        if (_1958)\n        {\n            _1959 = _1954;\n        }\n        else\n        {\n            _1959 = length(_1947);\n        }\n        float _1971 = _1959 - _685.fog_b.x;\n        if (_1971 > 0.0)\n        {\n            float _1980 = _685.fog_col.w * _1971;\n            float tau = _1980 * _1980;\n            if (_685.fog_b.y > 0.0)\n            {\n                float _1996;\n                if (_1958)\n                {\n                    _1996 = in.world_xy.y - (_685.fog_c.y * _1954);\n                }\n                else\n                {\n                    _1996 = _685.fog_eye.y;\n                }\n                float _2017 = mix(_1996, in.world_xy.y, fast::clamp(_685.fog_b.x / _1959, 0.0, 1.0));\n                float _2021 = in.world_xy.y - _2017;\n                float _2026 = _2017 - _685.fog_b.z;\n                float _2031 = in.world_xy.y - _685.fog_b.z;\n                bool _2034 = _2026 <= 0.0;\n                bool _2035 = !_2034;\n                bool _2041;\n                if (_2035)\n                {\n                    _2041 = _685.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2041 = _2034;\n                }\n                float _2042;\n                if (_2041)\n                {\n                    _2042 = _685.fog_b.y;\n                }\n                else\n                {\n                    _2042 = _685.fog_b.y * exp(-fast::min(_685.fog_b.w * _2026, 80.0));\n                }\n                bool _2069;\n                if (_2035)\n                {\n                    _2069 = _685.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2069 = _2034;\n                }\n                float _2070;\n                if (_2069)\n                {\n                    _2070 = _685.fog_b.y * _2026;\n                }\n                else\n                {\n                    _2070 = (_685.fog_b.y * (1.0 - exp(-fast::min(_685.fog_b.w * _2026, 80.0)))) / _685.fog_b.w;\n                }\n                bool _2095 = _2031 <= 0.0;\n                bool _2102;\n                if (!_2095)\n                {\n                    _2102 = _685.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2102 = _2095;\n                }\n                float _2103;\n                if (_2102)\n                {\n                    _2103 = _685.fog_b.y * _2031;\n                }\n                else\n                {\n                    _2103 = (_685.fog_b.y * (1.0 - exp(-fast::min(_685.fog_b.w * _2031, 80.0)))) / _685.fog_b.w;\n                }\n                float _2130;\n                if (abs(_2021) < 0.001000000047497451305389404296875)\n                {\n                    _2130 = _2042;\n                }\n                else\n                {\n                    _2130 = (_2103 - _2070) / _2021;\n                }\n                tau += (_1971 * fast::max(_2130, 0.0));\n            }\n            float4 _2153 = out.frag_color;\n            float3 _2161 = mix(_2153.xyz, _685.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _2161.x;\n            out.frag_color.y = _2161.y;\n            out.frag_color.z = _2161.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "inst_name": "_105",
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
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 8
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 8
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    int fa_inst_index_v [[user(locn9)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread QuadVertex& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex)\n{\n    float3 _68 = v.world_pos;\n    float2 _76 = fa_vs_points.data[int(gl_InstanceIndex)].pos.xy + (_68.xy * fa_vs_points.data[int(gl_InstanceIndex)].pos.w);\n    v.world_pos.x = _76.x;\n    v.world_pos.y = _76.y;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _105 [[buffer(0)]], const device fa_vs_points_buf& fa_vs_points [[buffer(8)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    out.fa_inst_index_v = int(gl_InstanceIndex);\n    float3 _178 = in.position;\n    float2 _179 = in.texcoord0;\n    float4 _180 = in.color0;\n    if (_105.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _117 = fa_srgb_to_linear(param);\n        float4 _192 = _180;\n        _192.x = _117.x;\n        _192.y = _117.y;\n        _192.z = _117.z;\n        _180 = _192;\n    }\n    QuadVertex param_1 = QuadVertex{ _178, _179, _180 };\n    vertex0(param_1, fa_vs_points, gl_InstanceIndex);\n    _178 = param_1.world_pos;\n    _179 = param_1.uv;\n    _180 = param_1.color;\n    out.gl_Position = _105.view_proj * float4(param_1.world_pos, 1.0);\n    out.uv = param_1.uv;\n    out.color = param_1.color;\n    out.xform = _105.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = param_1.world_pos.xy;\n    out.world_z = param_1.world_pos.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n    int fa_inst_index_v [[user(locn9)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _131)\n{\n    float2 _138 = gl_FragCoord.xy * _131.fa_target.xy;\n    float _144 = _138.y;\n    return float2(_138.x, mix(_144, 1.0 - _144, _131.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _131, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _188 = base_mode < 0.5;\n    bool _199;\n    if (!_188)\n    {\n        _199 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _199 = _188;\n    }\n    float _200;\n    if (_199)\n    {\n        _200 = shape_half.x;\n    }\n    else\n    {\n        _200 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _131), _131.fa_time.x, base_mode, float4(0.0), _200 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, const device fa_points_buf& points, thread int& fa_inst_index_v)\n{\n    s.color.x = points.data[fa_inst_index_v].tint.x;\n    s.color.y = points.data[fa_inst_index_v].tint.y;\n    s.color.z = points.data[fa_inst_index_v].tint.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _131 [[buffer(1)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _242 = tex.sample(smp, in.uv);\n    float3 param = _242.xyz;\n    float param_1 = in.xform.y;\n    float3 _253 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_253, _242.w) * in.color;\n    float param_2 = 0.0;\n    float4 _308 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _131, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _308 };\n    fragment0(param_3, param_4, points, in.fa_inst_index_v);\n    _308 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "inst_name": "_105",
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
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 8
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 8
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
