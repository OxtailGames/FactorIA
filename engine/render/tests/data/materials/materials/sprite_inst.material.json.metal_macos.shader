{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "dbae68a2cd91807fd7df084cee13eb559f2382809eb1ac9d2df2d325d7943acc",
  "slang": "metal_macos",
  "params": [
    "boost"
  ],
  "textures": [],
  "kind": "sprite",
  "instanced": [
    {
      "name": "shift",
      "vec4": 0,
      "offset": 0,
      "components": 1
    },
    {
      "name": "tint",
      "vec4": 1,
      "offset": 0,
      "components": 4
    }
  ],
  "instanceVec4": 2,
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 fa_inst_v0 [[user(locn9)]];\n    float4 fa_inst_v1 [[user(locn10)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n    float4 fa_inst_d0 [[attribute(7)]];\n    float4 fa_inst_d1 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& shift, thread float4& tint)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread QuadVertex& v, thread float& shift)\n{\n    v.world_pos.x += shift;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _107 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_inst_d0;\n    float4 param_1 = in.fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    float shift;\n    float4 tint;\n    fa_instance_unpack(param, param_1, param_2, shift, tint);\n    out.fa_inst_v0 = in.fa_inst_d0;\n    out.fa_inst_v1 = in.fa_inst_d1;\n    float3 _184 = in.position;\n    float2 _185 = in.texcoord0;\n    float4 _186 = in.color0;\n    if (_107.cspace.x > 0.5)\n    {\n        float3 param_3 = in.color0.xyz;\n        float3 _119 = fa_srgb_to_linear(param_3);\n        float4 _198 = _186;\n        _198.x = _119.x;\n        _198.y = _119.y;\n        _198.z = _119.z;\n        _186 = _198;\n    }\n    QuadVertex param_4 = QuadVertex{ _184, _185, _186 };\n    vertex0(param_4, shift);\n    _184 = param_4.world_pos;\n    _185 = param_4.uv;\n    _186 = param_4.color;\n    out.gl_Position = _107.view_proj * float4(param_4.world_pos, 1.0);\n    out.uv = param_4.uv;\n    out.color = param_4.color;\n    out.xform = _107.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = param_4.world_pos.xy;\n    out.world_z = param_4.world_pos.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 fa_inst_v0 [[user(locn9), flat]];\n    float4 fa_inst_v1 [[user(locn10), flat]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _376 = fa_linear_to_srgb(param);\n        c = _376;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _384 = fa_srgb_to_linear(param_1);\n            c = _384;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _395 = tex.sample(smp, p);\n    float3 param = _395.xyz;\n    float param_1 = xform.y;\n    float3 _405 = fa_tex_fix(param, param_1);\n    return float4(_405, _395.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _120 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_120.x * 255.0) + 0.5) * 256.0) + floor((_120.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _144 = length(d);\n    if (_144 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _158 = precise::atan2(d.y, d.x);\n    float a = _158;\n    float _161;\n    if (_158 < 0.0)\n    {\n        _161 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _161 = a;\n    }\n    a = _161;\n    float _173 = _161 * 162.9746551513671875;\n    float _178 = fast::min(floor(_173), 1023.0);\n    float _185 = _178 + 1.0;\n    float i1 = _185;\n    if (_185 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _178;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _144) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _144) + 0.5, 0.0, 1.0), _173 - _178);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 cookie_coord(thread const float4& cell, thread const float4& xf, thread const float2& off)\n{\n    float2 _248 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _252 = _248.x + 0.5;\n    float2 c = float2(_252, 0.5 - _248.y);\n    bool _260 = _252 >= 0.0;\n    bool _266;\n    if (_260)\n    {\n        _266 = c.x <= 1.0;\n    }\n    else\n    {\n        _266 = _260;\n    }\n    bool _272;\n    if (_266)\n    {\n        _272 = c.y >= 0.0;\n    }\n    else\n    {\n        _272 = _266;\n    }\n    bool _278;\n    if (_272)\n    {\n        _278 = c.y <= 1.0;\n    }\n    else\n    {\n        _278 = _272;\n    }\n    float2 _280 = c;\n    float2 _285 = fast::clamp(_280, float2(0.001953125), float2(0.998046875));\n    c = _285;\n    return float3(cell.x + (_285.x * cell.w), cell.y + (_285.y * cell.z), float(_278));\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_value(thread const float4& t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125, 0.715200006961822509765625, 0.072200000286102294921875)) * t.w;\n}\n\nstatic inline __attribute__((always_inline))\nfloat cookie_att(thread const int& i, thread const float2& d, constant quad_fs_params& _443, texture2d<float> fx_cookie_tex, sampler light_smp)\n{\n    if (_443.light_cookie[i].w == 0.0)\n    {\n        return 1.0;\n    }\n    float4 param = _443.light_cookie[i];\n    float4 param_1 = _443.light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _570 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.sample(light_smp, _570.xy, level(0.0));\n    return cookie_value(param_3) * _570.z;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _443, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _592 = _443.lit.y > 0.5;\n    if (_592)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _443.normal_uv.xy) + _443.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _616 = fa_tex_fix(param, param_1);\n        float3 _620 = (_616 * 2.0) - float3(1.0);\n        float _627 = cos(params.y);\n        float _629 = sin(params.y);\n        n = fast::normalize(float3((float2(_627, _629) * _620.x) + ((float2(-_629, _627) * ((mode > 5.5) ? (-1.0) : 1.0)) * _620.y), fast::max(_620.z, 0.0500000007450580596923828125)));\n    }\n    bool _663 = !_592;\n    bool _669;\n    if (_663)\n    {\n        _669 = _443.lit.z > 0.5;\n    }\n    else\n    {\n        _669 = _663;\n    }\n    float3 _672;\n    if (_669)\n    {\n        _672 = _443.flat_ambient.xyz;\n    }\n    else\n    {\n        _672 = _443.ambient.xyz;\n    }\n    float3 total = _672;\n    bool _689;\n    if (_669)\n    {\n        _689 = _443.lit.z < 1.5;\n    }\n    else\n    {\n        _689 = _669;\n    }\n    if (_689)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _443.light_map.xy), level(0.0)).xyz * _443.light_map.z);\n    }\n    float3 l;\n    float _813;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _727;\n        if (!_669)\n        {\n            _727 = float(i) >= _443.lit.x;\n        }\n        else\n        {\n            _727 = _669;\n        }\n        if (_727)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_443.light_pos[i].w < 0.0)\n        {\n            l = _443.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _753 = _443.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_753) / fast::max(_443.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _443.light_color[i].w);\n            float3 _773 = float3(_753, _443.light_pos[i].z);\n            l = _773 / float3(fast::max(length(_773), 9.9999997473787516355514526367188e-05));\n            if (_443.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _443.light_shadow_v[i].x;\n                float2 param_3 = -_753;\n                float param_4 = _443.light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4, shadow_tex, shadow_smp);\n            }\n            int param_5 = i;\n            float2 param_6 = -_753;\n            att *= cookie_att(param_5, param_6, _443, fx_cookie_tex, light_smp);\n        }\n        if (_592)\n        {\n            _813 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _813 = 1.0;\n        }\n        total += (_443.light_color[i].xyz * (att * _813));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _421 = fa_srgb_to_linear(param);\n        c = _421;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _1059 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _1063 = uv * _1059;\n    float _1069 = _1059.x;\n    float _1071 = _1059.y;\n    float _1073 = fast::clamp(shape_rs.x, 0.0, fast::min(_1069, _1071));\n    float2 _1084 = (abs(_1063) - _1059) + float2(_1073);\n    float d = (length(fast::max(_1084, float2(0.0))) + fast::min(fast::max(_1084.x, _1084.y), 0.0)) - _1073;\n    float ax = params.y;\n    bool _1105 = params.y > 15.0;\n    if (_1105)\n    {\n        ax -= 20.0;\n    }\n    float _1116;\n    if (ax <= (-1.5))\n    {\n        _1116 = (-2.0) - ax;\n    }\n    else\n    {\n        _1116 = 0.0;\n    }\n    if (_1116 > 0.0)\n    {\n        float _1130 = _1116 * 0.5;\n        d = abs(d + _1130) - _1130;\n    }\n    float _1138 = fwidth(d);\n    float _1139 = fast::max(_1138, 9.9999997473787516355514526367188e-05);\n    float _1149 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _1139)), 0.0, 1.0);\n    float _1154;\n    if (shape_rs.y > _1139)\n    {\n        _1154 = (_1149 * _1149) * (3.0 - (2.0 * _1149));\n    }\n    else\n    {\n        _1154 = _1149;\n    }\n    float4 c = color;\n    bool _1176 = (_1116 <= 0.0) && (ax > (-0.5));\n    if (_1176)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1191 = cos(ax);\n            float _1193 = sin(ax);\n            g = ((dot(_1063, float2(_1191, _1193)) / fast::max((abs(_1191) * _1069) + (abs(_1193) * _1071), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_1105)\n        {\n            float4 _1236 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1236;\n            float3 param = _1236.xyz;\n            float param_1 = xform.y;\n            float3 _1243 = fa_tex_fix(param, param_1);\n            float4 _2031 = c;\n            _2031.x = _1243.x;\n            _2031.y = _1243.y;\n            _2031.z = _1243.z;\n            c = _2031;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1255 = scene_rgb(param_2, xform);\n            float4 _1280 = mix(float4(color.xyz * color.w, color.w), float4(_1255 * color2.w, color2.w), float4(g));\n            float _1282 = _1280.w;\n            float3 _1285;\n            if (_1282 > 9.9999997473787516355514526367188e-06)\n            {\n                _1285 = _1280.xyz / float3(_1282);\n            }\n            else\n            {\n                _1285 = color.xyz;\n            }\n            c = float4(_1285, _1282);\n        }\n    }\n    float4 _2040 = c;\n    _2040.w = _2040.w * _1154;\n    c = _2040;\n    if (_1176 || (shape_rs.y > 0.0))\n    {\n        float _1326 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1335 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1335 + float3(_1326 * 0.0039215688593685626983642578125);\n            float3 _1341 = fa_srgb_to_linear(param_4);\n            float4 _2043 = c;\n            _2043.x = _1341.x;\n            _2043.y = _1341.y;\n            _2043.z = _1341.z;\n            c = _2043;\n        }\n        else\n        {\n            float4 _1351 = c;\n            float3 _1354 = _1351.xyz + float3(_1326 * 0.0039215688593685626983642578125);\n            float4 _2050 = _1351;\n            _2050.x = _1354.x;\n            _2050.y = _1354.y;\n            _2050.z = _1354.z;\n            c = _2050;\n        }\n        float4 _2055 = c;\n        _2055.w = fast::clamp(_2055.w + ((_1326 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _2055.w)), 0.0, 1.0);\n        c = _2055;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 rim_color(thread const float& a0, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, texture2d<float> tex, sampler smp, constant quad_fs_params& _443, thread float2& uv, thread float2& world_xy, texture2d<float> fx_cookie_tex, sampler light_smp, thread float2& params)\n{\n    float2 _850 = float2(_443.fx_rim_uv.x, 0.0);\n    float4 _852 = tex.sample(smp, (uv - _850));\n    float _853 = _852.w;\n    float4 _863 = tex.sample(smp, (uv + _850));\n    float _864 = _863.w;\n    float2 _872 = float2(0.0, _443.fx_rim_uv.y);\n    float4 _874 = tex.sample(smp, (uv - _872));\n    float _875 = _874.w;\n    float4 _885 = tex.sample(smp, (uv + _872));\n    float _886 = _885.w;\n    float _901 = _853 - _864;\n    float _904 = _886 - _875;\n    float _914 = cos(params.y);\n    float _916 = sin(params.y);\n    float2 _942 = ((float2(_914, _916) * _901) + ((float2(-_916, _914) * ((mode > 5.5) ? (-1.0) : 1.0)) * _904)) / float2(fast::max(length(float2(_901, _904)), 9.9999997473787516355514526367188e-05));\n    float3 sum = float3(0.0);\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _443.lit.x)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_443.light_pos[i].w < 0.0)\n        {\n            to_l = _443.light_pos[i].xy / float2(fast::max(length(_443.light_pos[i].xy), 9.9999997473787516355514526367188e-05));\n        }\n        else\n        {\n            float2 _988 = _443.light_pos[i].xy - world_xy;\n            float _991 = length(_988);\n            att = powr(fast::clamp(1.0 - (_991 / fast::max(_443.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _443.light_color[i].w);\n            to_l = _988 / float2(fast::max(_991, 9.9999997473787516355514526367188e-05));\n            if (_443.light_shadow_v[i].x >= 0.0)\n            {\n                float param = _443.light_shadow_v[i].x;\n                float2 param_1 = -_988;\n                float param_2 = _443.light_pos[i].w;\n                att *= light_shadow(param, param_1, param_2, shadow_tex, shadow_smp);\n            }\n            int param_3 = i;\n            float2 param_4 = -_988;\n            att *= cookie_att(param_3, param_4, _443, fx_cookie_tex, light_smp);\n        }\n        sum += (_443.light_color[i].xyz * (att * fast::max(dot(_942, to_l), 0.0)));\n    }\n    return (sum * _443.fx_rim.xyz) * (a0 * (1.0 - fast::min(fast::min(_853, _864), fast::min(_875, _886))));\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _443)\n{\n    float2 _449 = gl_FragCoord.xy * _443.fa_target.xy;\n    float _453 = _449.y;\n    return float2(_449.x, mix(_453, 1.0 - _453, _443.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _443, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _494 = base_mode < 0.5;\n    bool _505;\n    if (!_494)\n    {\n        _505 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _505 = _494;\n    }\n    float _506;\n    if (_505)\n    {\n        _506 = shape_half.x;\n    }\n    else\n    {\n        _506 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _443), _443.fa_time.x, base_mode, float4(0.0), _506 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& shift, thread float4& tint)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& shift, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, shift, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _427 = scene_rgb(param, xform);\n    return _427;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, thread float4& tint, constant fa_material& _531)\n{\n    float3 param = tint.xyz;\n    float3 _534 = fa_scene_rgb(param, xform) * _531.boost;\n    s.color.x = _534.x;\n    s.color.y = _534.y;\n    s.color.z = _534.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _443 [[buffer(1)]], constant fa_material& _531 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> fx_emissive_tex [[texture(4)]], texture2d<float> fx_cookie_tex [[texture(5)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1381 = in.params.x > 31.5;\n    float shift;\n    float4 tint;\n    if (_1381)\n    {\n        mode -= 32.0;\n    }\n    float _1389 = mode;\n    bool _1391 = _1389 > 15.5;\n    if (_1391)\n    {\n        mode -= 16.0;\n    }\n    float _1399 = mode;\n    bool _1401 = _1399 > 7.5;\n    if (_1401)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1391)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _443, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1391)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _443, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1463 = tex_color(param_5, tex, smp, in.xform);\n                float4 _1465 = _1463 * in.color;\n                float4 param_6 = _1465;\n                float param_7 = mode;\n                float _1472 = _1465.w;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _443, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex), _1472);\n                if (_443.fx_rim.w > 0.5)\n                {\n                    float param_8 = _1472;\n                    float param_9 = mode;\n                    float4 _1488 = out.frag_color;\n                    float3 _1490 = _1488.xyz + rim_color(param_8, param_9, shadow_tex, shadow_smp, tex, smp, _443, in.uv, in.world_xy, fx_cookie_tex, light_smp, in.params);\n                    out.frag_color.x = _1490.x;\n                    out.frag_color.y = _1490.y;\n                    out.frag_color.z = _1490.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1520 = length(in.uv);\n                    float _1523 = fwidth(_1520);\n                    float _1524 = fast::max(_1523, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1520) / _1524) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1520) / _1524) + 0.5, 0.0, 1.0) * fast::clamp(((_1520 - in.params.y) / _1524) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1564 = fast::clamp(1.0 - _1520, 0.0, 1.0);\n                            cov = (_1564 * _1564) * (3.0 - (2.0 * _1564));\n                        }\n                    }\n                    float3 _1573;\n                    if (_1391)\n                    {\n                        float4 param_10 = in.color;\n                        float param_11 = 5.0;\n                        _1573 = lit_color(param_10, param_11, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _443, in.uv, in.world_xy, fx_cookie_tex, light_smp, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1573 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1573, in.color.w * cov);\n                }\n            }\n        }\n    }\n    if (_443.fx_emit.w > 0.5)\n    {\n        float3 e = _443.fx_emit.xyz;\n        if (_443.fx_emit.w > 1.5)\n        {\n            float3 param_12 = fx_emissive_tex.sample(smp, ((in.uv * _443.fx_emit_uv.xy) + _443.fx_emit_uv.zw)).xyz;\n            float param_13 = _443.fx_emit.w - 2.0;\n            float3 _1628 = fa_tex_fix(param_12, param_13);\n            e *= _1628;\n        }\n        float4 _1632 = out.frag_color;\n        float3 _1634 = _1632.xyz + e;\n        out.frag_color.x = _1634.x;\n        out.frag_color.y = _1634.y;\n        out.frag_color.z = _1634.z;\n    }\n    float param_14 = mode;\n    float4 _1961 = out.frag_color;\n    fa_inst_load(shift, tint, in.fa_inst_v0, in.fa_inst_v1);\n    QuadInput param_15 = fa_quad_input(param_14, gl_FragCoord, _443, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_16 = QuadSurface{ _1961 };\n    fragment0(param_15, param_16, in.xform, tint, _531);\n    _1961 = param_16.color;\n    out.frag_color = param_16.color;\n    if (_1381)\n    {\n        float4 _1660 = out.frag_color;\n        float3 param_17 = in.color2.xyz;\n        float3 _1665 = scene_rgb(param_17, in.xform);\n        float3 _1669 = mix(_1660.xyz, _1665, float3(in.color2.w));\n        out.frag_color.x = _1669.x;\n        out.frag_color.y = _1669.y;\n        out.frag_color.z = _1669.z;\n    }\n    if (_1401)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1693 = _443.fog_col.w > 0.0;\n    bool _1701;\n    if (!_1693)\n    {\n        _1701 = _443.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1701 = _1693;\n    }\n    if (_1701)\n    {\n        float3 _1715 = float3(in.world_xy, in.world_z) - _443.fog_eye.xyz;\n        float _1722 = dot(_1715, _443.fog_c.xyz);\n        bool _1726 = _443.fog_c.w > 0.5;\n        float _1727;\n        if (_1726)\n        {\n            _1727 = _1722;\n        }\n        else\n        {\n            _1727 = length(_1715);\n        }\n        float _1739 = _1727 - _443.fog_b.x;\n        if (_1739 > 0.0)\n        {\n            float _1748 = _443.fog_col.w * _1739;\n            float tau = _1748 * _1748;\n            if (_443.fog_b.y > 0.0)\n            {\n                float _1764;\n                if (_1726)\n                {\n                    _1764 = in.world_xy.y - (_443.fog_c.y * _1722);\n                }\n                else\n                {\n                    _1764 = _443.fog_eye.y;\n                }\n                float _1785 = mix(_1764, in.world_xy.y, fast::clamp(_443.fog_b.x / _1727, 0.0, 1.0));\n                float _1789 = in.world_xy.y - _1785;\n                float _1794 = _1785 - _443.fog_b.z;\n                float _1799 = in.world_xy.y - _443.fog_b.z;\n                bool _1802 = _1794 <= 0.0;\n                bool _1803 = !_1802;\n                bool _1809;\n                if (_1803)\n                {\n                    _1809 = _443.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1809 = _1802;\n                }\n                float _1810;\n                if (_1809)\n                {\n                    _1810 = _443.fog_b.y;\n                }\n                else\n                {\n                    _1810 = _443.fog_b.y * exp(-fast::min(_443.fog_b.w * _1794, 80.0));\n                }\n                bool _1837;\n                if (_1803)\n                {\n                    _1837 = _443.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1837 = _1802;\n                }\n                float _1838;\n                if (_1837)\n                {\n                    _1838 = _443.fog_b.y * _1794;\n                }\n                else\n                {\n                    _1838 = (_443.fog_b.y * (1.0 - exp(-fast::min(_443.fog_b.w * _1794, 80.0)))) / _443.fog_b.w;\n                }\n                bool _1863 = _1799 <= 0.0;\n                bool _1870;\n                if (!_1863)\n                {\n                    _1870 = _443.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1870 = _1863;\n                }\n                float _1871;\n                if (_1870)\n                {\n                    _1871 = _443.fog_b.y * _1799;\n                }\n                else\n                {\n                    _1871 = (_443.fog_b.y * (1.0 - exp(-fast::min(_443.fog_b.w * _1799, 80.0)))) / _443.fog_b.w;\n                }\n                float _1898;\n                if (abs(_1789) < 0.001000000047497451305389404296875)\n                {\n                    _1898 = _1810;\n                }\n                else\n                {\n                    _1898 = (_1871 - _1838) / _1789;\n                }\n                tau += (_1739 * fast::max(_1898, 0.0));\n            }\n            float4 _1921 = out.frag_color;\n            float3 _1929 = mix(_1921.xyz, _443.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _1929.x;\n            out.frag_color.y = _1929.y;\n            out.frag_color.z = _1929.z;\n        }\n    }\n    return out;\n}\n\n",
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
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_107",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 1520,
            "struct_name": "quad_fs_params",
            "inst_name": "_443",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_531",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 fa_inst_v0 [[user(locn9)]];\n    float4 fa_inst_v1 [[user(locn10)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n    float4 fa_inst_d0 [[attribute(7)]];\n    float4 fa_inst_d1 [[attribute(8)]];\n};\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& shift, thread float4& tint)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nvoid vertex0(thread QuadVertex& v, thread float& shift)\n{\n    v.world_pos.x += shift;\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _107 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 param = in.fa_inst_d0;\n    float4 param_1 = in.fa_inst_d1;\n    float4 param_2 = float4(0.0);\n    float shift;\n    float4 tint;\n    fa_instance_unpack(param, param_1, param_2, shift, tint);\n    out.fa_inst_v0 = in.fa_inst_d0;\n    out.fa_inst_v1 = in.fa_inst_d1;\n    float3 _184 = in.position;\n    float2 _185 = in.texcoord0;\n    float4 _186 = in.color0;\n    if (_107.cspace.x > 0.5)\n    {\n        float3 param_3 = in.color0.xyz;\n        float3 _119 = fa_srgb_to_linear(param_3);\n        float4 _198 = _186;\n        _198.x = _119.x;\n        _198.y = _119.y;\n        _198.z = _119.z;\n        _186 = _198;\n    }\n    QuadVertex param_4 = QuadVertex{ _184, _185, _186 };\n    vertex0(param_4, shift);\n    _184 = param_4.world_pos;\n    _185 = param_4.uv;\n    _186 = param_4.color;\n    out.gl_Position = _107.view_proj * float4(param_4.world_pos, 1.0);\n    out.uv = param_4.uv;\n    out.color = param_4.color;\n    out.xform = _107.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = param_4.world_pos.xy;\n    out.world_z = param_4.world_pos.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fx_emit;\n    float4 fx_emit_uv;\n    float4 fx_rim;\n    float4 fx_rim_uv;\n    float4 light_cookie[16];\n    float4 light_cookie_xf[16];\n};\n\nstruct fa_material\n{\n    float boost;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n    float4 fa_inst_v0 [[user(locn9), flat]];\n    float4 fa_inst_v1 [[user(locn10), flat]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _114 = fa_linear_to_srgb(param);\n        c = _114;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _123 = fa_srgb_to_linear(param_1);\n            c = _123;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _162)\n{\n    float2 _169 = gl_FragCoord.xy * _162.fa_target.xy;\n    float _174 = _169.y;\n    return float2(_169.x, mix(_174, 1.0 - _174, _162.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _162, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _217 = base_mode < 0.5;\n    bool _228;\n    if (!_217)\n    {\n        _228 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _228 = _217;\n    }\n    float _229;\n    if (_228)\n    {\n        _229 = shape_half.x;\n    }\n    else\n    {\n        _229 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _162), _162.fa_time.x, base_mode, float4(0.0), _229 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_instance_unpack(thread const float4& fa_d0, thread const float4& fa_d1, thread const float4& fa_d2, thread float& shift, thread float4& tint)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load(thread float& shift, thread float4& tint, thread float4& fa_inst_v0, thread float4& fa_inst_v1)\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = float4(0.0);\n    fa_instance_unpack(param, param_1, param_2, shift, tint);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _139 = fa_srgb_to_linear(param);\n        c = _139;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _145 = scene_rgb(param, xform);\n    return _145;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, thread float4& tint, constant fa_material& _254)\n{\n    float3 param = tint.xyz;\n    float3 _257 = fa_scene_rgb(param, xform) * _254.boost;\n    s.color.x = _257.x;\n    s.color.y = _257.y;\n    s.color.z = _257.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _162 [[buffer(1)]], constant fa_material& _254 [[buffer(5)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _284 = tex.sample(smp, in.uv);\n    float3 param = _284.xyz;\n    float param_1 = in.xform.y;\n    float3 _293 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_293, _284.w) * in.color;\n    float param_2 = 0.0;\n    float4 _347 = out.frag_color;\n    float shift;\n    float4 tint;\n    fa_inst_load(shift, tint, in.fa_inst_v0, in.fa_inst_v1);\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _162, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _347 };\n    fragment0(param_3, param_4, in.xform, tint, _254);\n    _347 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_107",
            "msl_buffer_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 1520,
            "struct_name": "quad_fs_params",
            "inst_name": "_162",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_254",
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
