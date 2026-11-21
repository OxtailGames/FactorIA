{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "dbae68a2cd91807fd7df084cee13eb559f2382809eb1ac9d2df2d325d7943acc",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "buffers": [
    {
      "name": "extra",
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
    },
    {
      "name": "points",
      "binding": 1,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_extra_buf\n{\n    extra_item data[1];\n};\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    int fa_inst_index_v [[user(locn9)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread QuadVertex& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, const device fa_vs_extra_buf& fa_vs_extra)\n{\n    float3 _86 = v.world_pos;\n    float2 _93 = fa_vs_points.data[int(gl_InstanceIndex)].pos.xy + ((_86.xy * fa_vs_points.data[int(gl_InstanceIndex)].pos.w) * ((((device float*)&fa_vs_extra.data[int(gl_InstanceIndex)].pos)[3u] < (-1.0)) ? 0.0 : 1.0));\n    v.world_pos.x = _93.x;\n    v.world_pos.y = _93.y;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _122 [[buffer(0)]], const device fa_vs_extra_buf& fa_vs_extra [[buffer(8)]], const device fa_vs_points_buf& fa_vs_points [[buffer(9)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    out.fa_inst_index_v = int(gl_InstanceIndex);\n    float3 _192 = in.position;\n    float2 _193 = in.texcoord0;\n    float4 _194 = in.color0;\n    if (_122.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _132 = fa_srgb_to_linear(param);\n        float4 _206 = _194;\n        _206.x = _132.x;\n        _206.y = _132.y;\n        _206.z = _132.z;\n        _194 = _206;\n    }\n    QuadVertex param_1 = QuadVertex{ _192, _193, _194 };\n    vertex0(param_1, fa_vs_points, gl_InstanceIndex, fa_vs_extra);\n    _192 = param_1.world_pos;\n    _193 = param_1.uv;\n    _194 = param_1.color;\n    out.gl_Position = _122.view_proj * float4(param_1.world_pos, 1.0);\n    out.uv = param_1.uv;\n    out.color = param_1.color;\n    out.xform = _122.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = param_1.world_pos.xy;\n    out.world_z = param_1.world_pos.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    int fa_inst_index_v [[user(locn9)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _367 = fa_linear_to_srgb(param);\n        c = _367;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _375 = fa_srgb_to_linear(param_1);\n            c = _375;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _386 = tex.sample(smp, p);\n    float3 param = _386.xyz;\n    float param_1 = xform.y;\n    float3 _396 = fa_tex_fix(param, param_1);\n    return float4(_396, _386.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _111 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_111.x * 255.0) + 0.5) * 256.0) + floor((_111.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _135 = length(d);\n    if (_135 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _149 = precise::atan2(d.y, d.x);\n    float a = _149;\n    float _152;\n    if (_149 < 0.0)\n    {\n        _152 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _152 = a;\n    }\n    a = _152;\n    float _164 = _152 * 162.9746551513671875;\n    float _169 = fast::min(floor(_164), 1023.0);\n    float _176 = _169 + 1.0;\n    float i1 = _176;\n    if (_176 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _169;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _135) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _135) + 0.5, 0.0, 1.0), _164 - _169);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _239 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _243 = _239.x + 0.5;\n    float2 c = float2(_243, 0.5 - _239.y);\n    bool _251 = _243 >= 0.0;\n    bool _257;\n    if (_251)\n    {\n        _257 = c.x <= 1.0;\n    }\n    else\n    {\n        _257 = _251;\n    }\n    bool _263;\n    if (_257)\n    {\n        _263 = c.y >= 0.0;\n    }\n    else\n    {\n        _263 = _257;\n    }\n    bool _269;\n    if (_263)\n    {\n        _269 = c.y <= 1.0;\n    }\n    else\n    {\n        _269 = _263;\n    }\n    float2 _271 = c;\n    float2 _276 = fast::clamp(_271, float2(0.001953125), float2(0.998046875));\n    c = _276;\n    return float3(cell.x + (_276.x * cell.w), cell.y + (_276.y * cell.z), float(_269));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _429, texture2d<float> fx_cookie_tex, sampler light_smp)\n{\n    if (_429.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _429.light_cookie[i];\n    float4 param_1 = _429.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _542 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _542.xy, level(0.0));\n    return cookie_value(param_3) * _542.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _429, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _564 = _429.lit.y > 0.5;\n    if (_564)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _429.normal_uv.xy) + _429.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _588 = fa_tex_fix(param, param_1);\n        float3 _592 = (_588 * 2.0) - float3(1.0);\n        float _599 = cos(params.y);\n        float _601 = sin(params.y);\n        n = fast::normalize(float3((float2(_599, _601) * _592.x) + ((float2(-_601, _599) * ((mode > 5.5) ? (-1.0) : 1.0)) * _592.y), fast::max(_592.z, 0.0500000007450580596923828125)));\n    }\n    bool _635 = !_564;\n    bool _641;\n    if (_635)\n    {\n        _641 = _429.lit.z > 0.5;\n    }\n    else\n    {\n        _641 = _635;\n    }\n    float3 _644;\n    if (_641)\n    {\n        _644 = _429.flat_ambient.xyz;\n    }\n    else\n    {\n        _644 = _429.ambient.xyz;\n    }\n    float3 total = _644;\n    bool _661;\n    if (_641)\n    {\n        _661 = _429.lit.z < 1.5;\n    }\n    else\n    {\n        _661 = _641;\n    }\n    if (_661)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _429.light_map.xy), level(0.0)).xyz * _429.light_map.z);\n    }\n    float3 l;\n    float _785;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _699;\n        if (!_641)\n        {\n            _699 = float(i) >= _429.lit.x;\n        }\n        else\n        {\n            _699 = _641;\n        }\n        if (_699)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_429.light_pos[i].w < 0.0)\n        {\n            l = _429.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _725 = _429.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_725) / fast::max(_429.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _429.light_color[i].w);\n            float3 _745 = float3(_725, _429.light_pos[i].z);\n            l = _745 / float3(fast::max(length(_745), 9.9999997473787516355514526367188e-05));\n            if (_429.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _429.light_shadow_v[i].x;\n                float2 param_3 = -_725;\n                float param_4 = _429.light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4, shadow_tex, shadow_smp);\n            }\n            int param_5 = i;\n            float2 param_6 = -_725;\n            att *= cookie_att(param_5, param_6, _429, fx_cookie_tex, light_smp);\n        }\n        if (_564)\n        {\n            _785 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _785 = 1.0;\n        }\n        total += (_429.light_color[i].xyz * (att * _785));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _412 = fa_srgb_to_linear(param);\n        c = _412;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1031 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1035 = uv * _1031;\n    float _1041 = _1031.x;\n    float _1043 = _1031.y;\n    float _1045 = fast::clamp(shape_rs.x, 0.0, fast::min(_1041, _1043));\n    float2 _1056 = (abs(_1035) - _1031) + float2(_1045);\n    float d = (length(fast::max(_1056, float2(0.0))) + fast::min(fast::max(_1056.x, _1056.y), 0.0)) - _1045;\n    float ax = params.y;\n    bool _1077 = params.y > 15.0;\n    if (_1077)\n    {\n        ax -= 20.0;\n    }\n    float _1088;\n    if (ax <= (-1.5))\n    {\n        _1088 = (-2.0) - ax;\n    }\n    else\n    {\n        _1088 = 0.0;\n    }\n    if (_1088 > 0.0)\n    {\n        float _1102 = _1088 * 0.5;\n        d = abs(d + _1102) - _1102;\n    }\n    float _1110 = fwidth(d);\n    float _1111 = fast::max(_1110, 9.9999997473787516355514526367188e-05);\n    float _1121 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1111)), 0.0, 1.0);\n    float _1126;\n    if (shape_rs.y > _1111)\n    {\n        _1126 = (_1121 * _1121) * (3.0 - (2.0 * _1121));\n    }\n    else\n    {\n        _1126 = _1121;\n    }\n    float4 c = color;\n    bool _1148 = (_1088 <= 0.0) && (ax > (-0.5));\n    if (_1148)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1163 = cos(ax);\n            float _1165 = sin(ax);\n            g = ((dot(_1035, float2(_1163, _1165)) / fast::max((abs(_1163) * _1041) + (abs(_1165) * _1043), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1077)\n        {\n            float4 _1208 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1208;\n            float3 param = _1208.xyz;\n            float param_1 = xform.y;\n            float3 _1215 = fa_tex_fix(param, param_1);\n            float4 _2008 = c;\n            _2008.x = _1215.x;\n            _2008.y = _1215.y;\n            _2008.z = _1215.z;\n            c = _2008;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1227 = scene_rgb(param_2, xform);\n            float4 _1252 = mix(float4(color.xyz * color.w, color.w), float4(_1227 * color2.w, color2.w), float4(g));\n            float _1254 = _1252.w;\n            float3 _1257;\n            if (_1254 > 9.9999997473787516355514526367188e-06)\n            {\n                _1257 = _1252.xyz / float3(_1254);\n            }\n            else\n            {\n                _1257 = color.xyz;\n            }\n            c = float4(_1257, _1254);\n        }\n    }\n    float4 _2017 = c;\n    _2017.w = _2017.w * _1126;\n    c = _2017;\n    if (_1148 || (shape_rs.y > 0.0))\n    {\n        float _1298 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1307 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1307 + float3(_1298 * 0.0039215688593685626983642578125);\n            float3 _1313 = fa_srgb_to_linear(param_4);\n            float4 _2020 = c;\n            _2020.x = _1313.x;\n            _2020.y = _1313.y;\n            _2020.z = _1313.z;\n            c = _2020;\n        }\n        else\n        {\n            float4 _1323 = c;\n            float3 _1326 = _1323.xyz + float3(_1298 * 0.0039215688593685626983642578125);\n            float4 _2027 = _1323;\n            _2027.x = _1326.x;\n            _2027.y = _1326.y;\n            _2027.z = _1326.z;\n            c = _2027;\n        }\n        float4 _2032 = c;\n        _2032.w = fast::clamp(_2032.w + ((_1298 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2032.w)), 0.0, 1.0);\n        c = _2032;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _429, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, thread float2& params)\n{\n    float2 _822 = float2(_429.fx_rim_uv.x, 0.0);\n    float4 _824 = tex.sample(smp, (uv - _822));\n    float _825 = _824.w;\n    float4 _835 = tex.sample(smp, (uv + _822));\n    float _836 = _835.w;\n    float2 _844 = float2(0.0, _429.fx_rim_uv.y);\n    float4 _846 = tex.sample(smp, (uv - _844));\n    float _847 = _846.w;\n    float4 _857 = tex.sample(smp, (uv + _844));\n    float _858 = _857.w;\n    float _873 = _825 - _836;\n    float _876 = _858 - _847;\n    float _886 = cos(params.y);\n    float _888 = sin(params.y);\n    float2 _914 = ((float2(_886, _888) * _873) + ((float2(-_888, _886) * ((mode > 5.5) ? (-1.0) : 1.0)) * _876)) / float2(fast::max(length(float2(_873, _876)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _429.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_429.light_pos[i].w < 0.0)\n        {\n            to_l = _429.light_pos[i].xy / float2(fast::max(length(_429.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _960 = _429.light_pos[i].xy - world_xy;\n            float _963 = length(_960);\n            att = powr(fast::clamp(1.0 - (_963 / fast::max(_429.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _429.light_color[i].w);\n            to_l = _960 / float2(fast::max(_963, 9.9999997473787516355514526367188e-05));\n            if (_429.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _429.light_shadow_v[i].x;\n                float2 param_1 = -_960;\n                float param_2 = _429.light_pos[i].w;\n                att *= light_shadow(param, param_1, param_2, shadow_tex, shadow_smp);\n            }\n            int param_3 = i;\n            float2 param_4 = -_960;\n            att *= cookie_att(param_3, param_4, _429, fx_cookie_tex, light_smp);\n        }\n        sum += (_429.light_color[i].xyz * (att * fast::max(dot(_914, to_l), 0.0)));\n    }\n    return (sum * _429.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_825, _836), fast::min(_847, _858))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _429)\n{\n    float2 _435 = gl_FragCoord.xy * _429.fa_target.xy;\n    float _439 = _435.y;\n    return float2(_435.x, mix(_439, 1.0 - _439, _429.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _429, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _480 = base_mode < 0.5;\n    bool _491;\n    if (!_480)\n    {\n        _491 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _491 = _480;\n    }\n    float _492;\n    if (_491)\n    {\n        _492 = shape_half.x;\n    }\n    else\n    {\n        _492 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _429), _429.fa_time.x, base_mode, float4(0.0), _492 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, const device fa_points_buf& points, thread int& fa_inst_index_v)\n{\n    s.color.x = points.data[fa_inst_index_v].tint.x;\n    s.color.y = points.data[fa_inst_index_v].tint.y;\n    s.color.z = points.data[fa_inst_index_v].tint.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _429 [[buffer(1)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> fx_emissive_tex [[texture(4)]], texture2d<float> fx_cookie_tex [[texture(5)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1353 = in.params.x > 31.5;\n    if (_1353)\n    {\n        mode -= 32.0;\n    }\n    float _1361 = mode;\n    bool _1363 = _1361 > 15.5;\n    if (_1363)\n    {\n        mode -= 16.0;\n    }\n    float _1371 = mode;\n    bool _1373 = _1371 > 7.5;\n    if (_1373)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1363)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _429, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1363)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _429, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1435 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1437 = _1435 * in.color;\n                float4 param_6 = _1437;\n                float param_7 = mode;\n                float _1444 = _1437.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _429, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), _1444);\n                if (_429.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1444;\n                    float param_9 = mode;\n                    float4 _1460 = out.frag_color;\n                    float3 _1462 = _1460.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _429, in.uv, in.world_xy, fx_cookie_tex, light_smp, in.params);\n                    out.frag_color.x = _1462.x;\n                    out.frag_color.y = _1462.y;\n                    out.frag_color.z = _1462.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1492 = length(in.uv);\n                    float _1495 = fwidth(_1492);\n                    float _1496 = fast::max(_1495, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1492) / _1496) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1492) / _1496) + 0.5, 0.0, 1.0) * fast::clamp(((_1492 - in.params.y) / _1496) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1536 = fast::clamp(1.0 - _1492, 0.0, 1.0);\n                            cov = (_1536 * _1536) * (3.0 - (2.0 * _1536));\n                        }\n                    }\n                    float3 _1545;\n                    if (_1363)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1545 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _429, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1545 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1545, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_429.fx_emit.w > 0.5)\n    {\n        float3 e = _429.fx_emit.xyz;\n        if (_429.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _429.fx_emit_uv.xy) + _429.fx_emit_uv.zw)).xyz;\n            float param_13 = _429.fx_emit.w - 2.0;\n            float3 _1600 = fa_tex_fix(param_12, param_13);\n            e *= _1600;\n        }\n        float4 _1604 = out.frag_color;\n        float3 _1606 = _1604.xyz + e;\n        out.frag_color.x = _1606.x;\n        out.frag_color.y = _1606.y;\n        out.frag_color.z = _1606.z;\n    }\n    float param_14 = mode;\n    float4 _1938 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14, gl_FragCoord, _429, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _1938 };\n    fragment0(param_15, param_16, points, in.fa_inst_index_v);\n    _1938 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1353)\n    {\n        float4 _1632 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _1637 = scene_rgb(param_17, in.xform);\n        float3 _1641 = mix(_1632.xyz, _1637, float3(in.color2.w));\n        out.frag_color.x = _1641.x;\n        out.frag_color.y = _1641.y;\n        out.frag_color.z = _1641.z;\n    }\n    if (_1373)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1665 = _429.fog_col.w > 0.0;\n    bool _1673;\n    if (!_1665)\n    {\n        _1673 = _429.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1673 = _1665;\n    }\n    if (_1673)\n    {\n        float3 _1687 = float3(in.world_xy, in.world_z) - _429.fog_eye.xyz;\n        float _1694 = dot(_1687, _429.fog_c.xyz);\n        bool _1698 = _429.fog_c.w > 0.5;\n        float _1699;\n        if (_1698)\n        {\n            _1699 = _1694;\n        }\n        else\n        {\n            _1699 = length(_1687);\n        }\n        float _1711 = _1699 - _429.fog_b.x;\n        if (_1711 > 0.0)\n        {\n            float _1720 = _429.fog_col.w * _1711;\n            float tau = _1720 * _1720;\n            if (_429.fog_b.y > 0.0)\n            {\n                float _1736;\n                if (_1698)\n                {\n                    _1736 = in.world_xy.y - (_429.fog_c.y * _1694);\n                }\n                else\n                {\n                    _1736 = _429.fog_eye.y;\n                }\n                float _1757 = mix(_1736, in.world_xy.y, fast::clamp(_429.fog_b.x / _1699, 0.0, 1.0));\n                float _1761 = in.world_xy.y - _1757;\n                float _1766 = _1757 - _429.fog_b.z;\n                float _1771 = in.world_xy.y - _429.fog_b.z;\n                bool _1774 = _1766 <= 0.0;\n                bool _1775 = !_1774;\n                bool _1781;\n                if (_1775)\n                {\n                    _1781 = _429.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1781 = _1774;\n                }\n                float _1782;\n                if (_1781)\n                {\n                    _1782 = _429.fog_b.y;\n                }\n                else\n                {\n                    _1782 = _429.fog_b.y * exp(-fast::min(_429.fog_b.w * _1766, 80.0));\n                }\n                bool _1809;\n                if (_1775)\n                {\n                    _1809 = _429.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1809 = _1774;\n                }\n                float _1810;\n                if (_1809)\n                {\n                    _1810 = _429.fog_b.y * _1766;\n                }\n                else\n                {\n                    _1810 = (_429.fog_b.y * (1.0 - exp(-fast::min(_429.fog_b.w * _1766, 80.0)))) / _429.fog_b.w;\n                }\n                bool _1835 = _1771 <= 0.0;\n                bool _1842;\n                if (!_1835)\n                {\n                    _1842 = _429.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1842 = _1835;\n                }\n                float _1843;\n                if (_1842)\n                {\n                    _1843 = _429.fog_b.y * _1771;\n                }\n                else\n                {\n                    _1843 = (_429.fog_b.y * (1.0 - exp(-fast::min(_429.fog_b.w * _1771, 80.0)))) / _429.fog_b.w;\n                }\n                float _1870;\n                if (abs(_1761) < 0.001000000047497451305389404296875)\n                {\n                    _1870 = _1782;\n                }\n                else\n                {\n                    _1870 = (_1843 - _1810) / _1761;\n                }\n                tau += (_1711 * fast::max(_1870, 0.0));\n            }\n            float4 _1893 = out.frag_color;\n            float3 _1901 = mix(_1893.xyz, _429.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _1901.x;\n            out.frag_color.y = _1901.y;\n            out.frag_color.z = _1901.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "inst_name": "_122",
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
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "msl_buffer_n": 8
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 9
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_points_buf\n{\n    points_item data[1];\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_vs_extra_buf\n{\n    extra_item data[1];\n};\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    int fa_inst_index_v [[user(locn9)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread QuadVertex& v, const device fa_vs_points_buf& fa_vs_points, thread uint& gl_InstanceIndex, const device fa_vs_extra_buf& fa_vs_extra)\n{\n    float3 _86 = v.world_pos;\n    float2 _93 = fa_vs_points.data[int(gl_InstanceIndex)].pos.xy + ((_86.xy * fa_vs_points.data[int(gl_InstanceIndex)].pos.w) * ((((device float*)&fa_vs_extra.data[int(gl_InstanceIndex)].pos)[3u] < (-1.0)) ? 0.0 : 1.0));\n    v.world_pos.x = _93.x;\n    v.world_pos.y = _93.y;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _122 [[buffer(0)]], const device fa_vs_extra_buf& fa_vs_extra [[buffer(8)]], const device fa_vs_points_buf& fa_vs_points [[buffer(9)]], uint gl_InstanceIndex [[instance_id]])\n{\n    main0_out out = {};\n    out.fa_inst_index_v = int(gl_InstanceIndex);\n    float3 _192 = in.position;\n    float2 _193 = in.texcoord0;\n    float4 _194 = in.color0;\n    if (_122.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _132 = fa_srgb_to_linear(param);\n        float4 _206 = _194;\n        _206.x = _132.x;\n        _206.y = _132.y;\n        _206.z = _132.z;\n        _194 = _206;\n    }\n    QuadVertex param_1 = QuadVertex{ _192, _193, _194 };\n    vertex0(param_1, fa_vs_points, gl_InstanceIndex, fa_vs_extra);\n    _192 = param_1.world_pos;\n    _193 = param_1.uv;\n    _194 = param_1.color;\n    out.gl_Position = _122.view_proj * float4(param_1.world_pos, 1.0);\n    out.uv = param_1.uv;\n    out.color = param_1.color;\n    out.xform = _122.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = param_1.world_pos.xy;\n    out.world_z = param_1.world_pos.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct fa_points_buf\n{\n    points_item data[1];\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n    int fa_inst_index_v [[user(locn9)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _129)\n{\n    float2 _136 = gl_FragCoord.xy * _129.fa_target.xy;\n    float _142 = _136.y;\n    return float2(_136.x, mix(_142, 1.0 - _142, _129.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _129, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _186 = base_mode < 0.5;\n    bool _197;\n    if (!_186)\n    {\n        _197 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _197 = _186;\n    }\n    float _198;\n    if (_197)\n    {\n        _198 = shape_half.x;\n    }\n    else\n    {\n        _198 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _129), _129.fa_time.x, base_mode, float4(0.0), _198 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, const device fa_points_buf& points, thread int& fa_inst_index_v)\n{\n    s.color.x = points.data[fa_inst_index_v].tint.x;\n    s.color.y = points.data[fa_inst_index_v].tint.y;\n    s.color.z = points.data[fa_inst_index_v].tint.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _129 [[buffer(1)]], const device fa_points_buf& points [[buffer(8)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _240 = tex.sample(smp, in.uv);\n    float3 param = _240.xyz;\n    float param_1 = in.xform.y;\n    float3 _251 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_251, _240.w) * in.color;\n    float param_2 = 0.0;\n    float4 _310 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _129, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _310 };\n    fragment0(param_3, param_4, points, in.fa_inst_index_v);\n    _310 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "inst_name": "_122",
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
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "msl_buffer_n": 8
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "msl_buffer_n": 9
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
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
