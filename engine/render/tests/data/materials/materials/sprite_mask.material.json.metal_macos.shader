{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "c1e79074f2aeaac8a4969a5266649c9c9bd6dddadcf288d2b3f256eda8e982d0",
  "slang": "metal_macos",
  "params": [],
  "textures": [
    "mask"
  ],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _150 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _155 = _150;\n        _155.x = _82.x;\n        _155.y = _82.y;\n        _155.z = _82.z;\n        _150 = _155;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _150;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _504 = fa_linear_to_srgb(param);\n        c = _504;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _512 = fa_srgb_to_linear(param_1);\n            c = _512;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _523 = tex.sample(smp, p);\n    float3 param = _523.xyz;\n    float param_1 = xform.y;\n    float3 _533 = fa_tex_fix(param, param_1);\n    return float4(_533, _523.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _109 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_109.x * 255.0) + 0.5) * 256.0) + floor((_109.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_tap(thread const float& v, thread const float& tt, thread const float& dist, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _212 = floor(tt);\n    float _222 = _212 - (1024.0 * floor(_212 * 0.0009765625));\n    float _225 = _222 + 1.0;\n    float i1 = _225;\n    if (_225 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _222;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - dist) + 0.5, 0.0, 1.0), tt - _212);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_soft(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _262 = length(d);\n    float result = 1.0;\n    if (_262 >= 9.9999997473787516355514526367188e-05)\n    {\n        float _273 = precise::atan2(d.y, d.x);\n        float a = _273;\n        float _276;\n        if (_273 < 0.0)\n        {\n            _276 = a + 6.283185482025146484375;\n        }\n        else\n        {\n            _276 = a;\n        }\n        a = _276;\n        float _286 = _276 * 162.9746551513671875;\n        float _295 = fast::min((size * 10.0) / _262, 0.699999988079071044921875) * 162.9746551513671875;\n        float sum = 0.0;\n        float n = 0.0;\n        for (int k = 0; k < 12; k++)\n        {\n            float _323 = floor(_286 + ((((float(k) + 0.5) * 0.16666667163372039794921875) - 1.0) * _295));\n            float param = v;\n            float param_1 = _323 - (1024.0 * floor(_323 * 0.0009765625));\n            float _337 = shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius;\n            if (_337 < _262)\n            {\n                sum += _337;\n                n += 1.0;\n            }\n        }\n        if (n > 0.5)\n        {\n            float _369 = fast::min(size * ((1.0 / fast::max(sum / n, 1.0)) - (1.0 / _262)), 0.699999988079071044921875) * 162.9746551513671875;\n            float acc = 0.0;\n            float wsum = 0.0;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _387 = ((float(k_1) + 0.5) * 0.125) - 1.0;\n                float _393 = 1.0 - (0.800000011920928955078125 * abs(_387));\n                float param_2 = v;\n                float param_3 = _286 + (_387 * _369);\n                float param_4 = _262;\n                float param_5 = radius;\n                acc += (_393 * light_shadow_tap(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp));\n                wsum += _393;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _133 = length(d);\n    if (_133 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _147 = precise::atan2(d.y, d.x);\n    float a = _147;\n    float _150;\n    if (_147 < 0.0)\n    {\n        _150 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _150 = a;\n    }\n    a = _150;\n    float _162 = _150 * 162.9746551513671875;\n    float _167 = fast::min(floor(_162), 1023.0);\n    float _174 = _167 + 1.0;\n    float i1 = _174;\n    if (_174 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _167;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _133) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _133) + 0.5, 0.0, 1.0), _162 - _167);\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow_sized(thread const float& v, thread const float& size, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float r = 1.0;\n    if (size > 0.0)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3, shadow_tex, shadow_smp);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6, shadow_tex, shadow_smp);\n    }\n    return r;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _565, thread float2& uv, thread float2& world_xy, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex, sampler light_smp)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _659 = _565.lit.y > 0.5;\n    if (_659)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _565.normal_uv.xy) + _565.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _683 = fa_tex_fix(param, param_1);\n        float3 _687 = (_683 * 2.0) - float3(1.0);\n        float _694 = cos(params.y);\n        float _696 = sin(params.y);\n        n = fast::normalize(float3((float2(_694, _696) * _687.x) + ((float2(-_696, _694) * ((mode > 5.5) ? (-1.0) : 1.0)) * _687.y), fast::max(_687.z, 0.0500000007450580596923828125)));\n    }\n    bool _729 = !_659;\n    bool _735;\n    if (_729)\n    {\n        _735 = _565.lit.z > 0.5;\n    }\n    else\n    {\n        _735 = _729;\n    }\n    float3 _738;\n    if (_735)\n    {\n        _738 = _565.flat_ambient.xyz;\n    }\n    else\n    {\n        _738 = _565.ambient.xyz;\n    }\n    float3 total = _738;\n    bool _755;\n    if (_735)\n    {\n        _755 = _565.lit.z < 1.5;\n    }\n    else\n    {\n        _755 = _735;\n    }\n    if (_755)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _565.light_map.xy), level(0.0)).xyz * _565.light_map.z);\n    }\n    float3 l;\n    float _875;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _793;\n        if (!_735)\n        {\n            _793 = float(i) >= _565.lit.x;\n        }\n        else\n        {\n            _793 = _735;\n        }\n        if (_793)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_565.light_pos[i].w < 0.0)\n        {\n            l = _565.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _819 = _565.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_819) / fast::max(_565.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _565.light_color[i].w);\n            float3 _839 = float3(_819, _565.light_pos[i].z);\n            l = _839 / float3(fast::max(length(_839), 9.9999997473787516355514526367188e-05));\n            if (_565.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _565.light_shadow_v[i].x;\n                float param_3 = _565.light_shadow_v[i].y;\n                float2 param_4 = -_819;\n                float param_5 = _565.light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5, shadow_tex, shadow_smp);\n            }\n        }\n        if (_659)\n        {\n            _875 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _875 = 1.0;\n        }\n        total += (_565.light_color[i].xyz * (att * _875));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _550 = fa_srgb_to_linear(param);\n        c = _550;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _903 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _907 = uv * _903;\n    float _913 = _903.x;\n    float _915 = _903.y;\n    float _917 = fast::clamp(shape_rs.x, 0.0, fast::min(_913, _915));\n    float2 _928 = (abs(_907) - _903) + float2(_917);\n    float d = (length(fast::max(_928, float2(0.0))) + fast::min(fast::max(_928.x, _928.y), 0.0)) - _917;\n    float ax = params.y;\n    bool _949 = params.y > 15.0;\n    if (_949)\n    {\n        ax -= 20.0;\n    }\n    float _960;\n    if (ax <= (-1.5))\n    {\n        _960 = (-2.0) - ax;\n    }\n    else\n    {\n        _960 = 0.0;\n    }\n    if (_960 > 0.0)\n    {\n        float _974 = _960 * 0.5;\n        d = abs(d + _974) - _974;\n    }\n    float _982 = fwidth(d);\n    float _983 = fast::max(_982, 9.9999997473787516355514526367188e-05);\n    float _993 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _983)), 0.0, 1.0);\n    float _998;\n    if (shape_rs.y > _983)\n    {\n        _998 = (_993 * _993) * (3.0 - (2.0 * _993));\n    }\n    else\n    {\n        _998 = _993;\n    }\n    float4 c = color;\n    bool _1020 = (_960 <= 0.0) && (ax > (-0.5));\n    if (_1020)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1035 = cos(ax);\n            float _1037 = sin(ax);\n            g = ((dot(_907, float2(_1035, _1037)) / fast::max((abs(_1035) * _913) + (abs(_1037) * _915), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_949)\n        {\n            float4 _1080 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _1080;\n            float3 param = _1080.xyz;\n            float param_1 = xform.y;\n            float3 _1087 = fa_tex_fix(param, param_1);\n            float4 _1783 = c;\n            _1783.x = _1087.x;\n            _1783.y = _1087.y;\n            _1783.z = _1087.z;\n            c = _1783;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1099 = scene_rgb(param_2, xform);\n            float4 _1124 = mix(float4(color.xyz * color.w, color.w), float4(_1099 * color2.w, color2.w), float4(g));\n            float _1126 = _1124.w;\n            float3 _1129;\n            if (_1126 > 9.9999997473787516355514526367188e-06)\n            {\n                _1129 = _1124.xyz / float3(_1126);\n            }\n            else\n            {\n                _1129 = color.xyz;\n            }\n            c = float4(_1129, _1126);\n        }\n    }\n    float4 _1792 = c;\n    _1792.w = _1792.w * _998;\n    c = _1792;\n    if (_1020 || (shape_rs.y > 0.0))\n    {\n        float _1170 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1179 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1179 + float3(_1170 * 0.0039215688593685626983642578125);\n            float3 _1185 = fa_srgb_to_linear(param_4);\n            float4 _1795 = c;\n            _1795.x = _1185.x;\n            _1795.y = _1185.y;\n            _1795.z = _1185.z;\n            c = _1795;\n        }\n        else\n        {\n            float4 _1195 = c;\n            float3 _1198 = _1195.xyz + float3(_1170 * 0.0039215688593685626983642578125);\n            float4 _1802 = _1195;\n            _1802.x = _1198.x;\n            _1802.y = _1198.y;\n            _1802.z = _1198.z;\n            c = _1802;\n        }\n        float4 _1807 = c;\n        _1807.w = fast::clamp(_1807.w + ((_1170 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1807.w)), 0.0, 1.0);\n        c = _1807;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _565)\n{\n    float2 _571 = gl_FragCoord.xy * _565.fa_target.xy;\n    float _575 = _571.y;\n    return float2(_571.x, mix(_575, 1.0 - _575, _565.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _565, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _614 = base_mode < 0.5;\n    bool _625;\n    if (!_614)\n    {\n        _625 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _625 = _614;\n    }\n    float _626;\n    if (_625)\n    {\n        _626 = shape_half.x;\n    }\n    else\n    {\n        _626 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _565), _565.fa_time.x, base_mode, float4(0.0), _626 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, texture2d<float> mask, sampler mask_smp)\n{\n    float4 _645 = mask.sample(mask_smp, float2(0.0500000007450580596923828125));\n    s.color.x = _645.x;\n    s.color.y = _645.y;\n    s.color.z = _645.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _565 [[buffer(1)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> mask [[texture(4)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], sampler mask_smp [[sampler(3)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1225 = in.params.x > 31.5;\n    if (_1225)\n    {\n        mode -= 32.0;\n    }\n    float _1233 = mode;\n    bool _1235 = _1233 > 15.5;\n    if (_1235)\n    {\n        mode -= 16.0;\n    }\n    float _1243 = mode;\n    bool _1245 = _1243 > 7.5;\n    if (_1245)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1235)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _565, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1235)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _565, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1309 = tex_color(param_5, tex, smp, in.xform) * in.color;\n                float4 param_6 = _1309;\n                float param_7 = mode;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _565, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), _1309.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1344 = length(in.uv);\n                    float _1347 = fwidth(_1344);\n                    float _1348 = fast::max(_1347, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1344) / _1348) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1344) / _1348) + 0.5, 0.0, 1.0) * fast::clamp(((_1344 - in.params.y) / _1348) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1388 = fast::clamp(1.0 - _1344, 0.0, 1.0);\n                            cov = (_1388 * _1388) * (3.0 - (2.0 * _1388));\n                        }\n                    }\n                    float3 _1397;\n                    if (_1235)\n                    {\n                        float4 param_8 = in.color;\n                        float param_9 = 5.0;\n                        _1397 = lit_color(param_8, param_9, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _565, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp);\n                    }\n                    else\n                    {\n                        _1397 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1397, in.color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1736 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10, gl_FragCoord, _565, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_12 = QuadSurface{ _1736 };\n    fragment0(param_11, param_12, mask, mask_smp);\n    _1736 = param_12.color;\n    out.frag_color = param_12.color;\n    if (_1225)\n    {\n        float4 _1435 = out.frag_color;\n        float3 param_13 = in.color2.xyz;\n        float3 _1440 = scene_rgb(param_13, in.xform);\n        float3 _1444 = mix(_1435.xyz, _1440, float3(in.color2.w));\n        out.frag_color.x = _1444.x;\n        out.frag_color.y = _1444.y;\n        out.frag_color.z = _1444.z;\n    }\n    if (_1245)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1468 = _565.fog_col.w > 0.0;\n    bool _1476;\n    if (!_1468)\n    {\n        _1476 = _565.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1476 = _1468;\n    }\n    if (_1476)\n    {\n        float3 _1490 = float3(in.world_xy, in.world_z) - _565.fog_eye.xyz;\n        float _1497 = dot(_1490, _565.fog_c.xyz);\n        bool _1501 = _565.fog_c.w > 0.5;\n        float _1502;\n        if (_1501)\n        {\n            _1502 = _1497;\n        }\n        else\n        {\n            _1502 = length(_1490);\n        }\n        float _1514 = _1502 - _565.fog_b.x;\n        if (_1514 > 0.0)\n        {\n            float _1523 = _565.fog_col.w * _1514;\n            float tau = _1523 * _1523;\n            if (_565.fog_b.y > 0.0)\n            {\n                float _1539;\n                if (_1501)\n                {\n                    _1539 = in.world_xy.y - (_565.fog_c.y * _1497);\n                }\n                else\n                {\n                    _1539 = _565.fog_eye.y;\n                }\n                float _1560 = mix(_1539, in.world_xy.y, fast::clamp(_565.fog_b.x / _1502, 0.0, 1.0));\n                float _1564 = in.world_xy.y - _1560;\n                float _1569 = _1560 - _565.fog_b.z;\n                float _1574 = in.world_xy.y - _565.fog_b.z;\n                bool _1577 = _1569 <= 0.0;\n                bool _1578 = !_1577;\n                bool _1584;\n                if (_1578)\n                {\n                    _1584 = _565.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1584 = _1577;\n                }\n                float _1585;\n                if (_1584)\n                {\n                    _1585 = _565.fog_b.y;\n                }\n                else\n                {\n                    _1585 = _565.fog_b.y * exp(-fast::min(_565.fog_b.w * _1569, 80.0));\n                }\n                bool _1612;\n                if (_1578)\n                {\n                    _1612 = _565.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1612 = _1577;\n                }\n                float _1613;\n                if (_1612)\n                {\n                    _1613 = _565.fog_b.y * _1569;\n                }\n                else\n                {\n                    _1613 = (_565.fog_b.y * (1.0 - exp(-fast::min(_565.fog_b.w * _1569, 80.0)))) / _565.fog_b.w;\n                }\n                bool _1638 = _1574 <= 0.0;\n                bool _1645;\n                if (!_1638)\n                {\n                    _1645 = _565.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1645 = _1638;\n                }\n                float _1646;\n                if (_1645)\n                {\n                    _1646 = _565.fog_b.y * _1574;\n                }\n                else\n                {\n                    _1646 = (_565.fog_b.y * (1.0 - exp(-fast::min(_565.fog_b.w * _1574, 80.0)))) / _565.fog_b.w;\n                }\n                float _1673;\n                if (abs(_1564) < 0.001000000047497451305389404296875)\n                {\n                    _1673 = _1585;\n                }\n                else\n                {\n                    _1673 = (_1646 - _1613) / _1564;\n                }\n                tau += (_1514 * fast::max(_1673, 0.0));\n            }\n            float4 _1696 = out.frag_color;\n            float3 _1704 = mix(_1696.xyz, _565.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _1704.x;\n            out.frag_color.y = _1704.y;\n            out.frag_color.z = _1704.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_565",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _127)\n{\n    float2 _134 = gl_FragCoord.xy * _127.fa_target.xy;\n    float _140 = _134.y;\n    return float2(_134.x, mix(_140, 1.0 - _140, _127.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _127, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _184 = base_mode < 0.5;\n    bool _195;\n    if (!_184)\n    {\n        _195 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _195 = _184;\n    }\n    float _196;\n    if (_195)\n    {\n        _196 = shape_half.x;\n    }\n    else\n    {\n        _196 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _127), _127.fa_time.x, base_mode, float4(0.0), _196 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, texture2d<float> mask, sampler mask_smp)\n{\n    float4 _221 = mask.sample(mask_smp, float2(0.0500000007450580596923828125));\n    s.color.x = _221.x;\n    s.color.y = _221.y;\n    s.color.z = _221.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _127 [[buffer(1)]], texture2d<float> tex [[texture(0)]], texture2d<float> mask [[texture(1)]], sampler smp [[sampler(0)]], sampler mask_smp [[sampler(3)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _236 = tex.sample(smp, in.uv);\n    float3 param = _236.xyz;\n    float param_1 = in.xform.y;\n    float3 _247 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_247, _236.w) * in.color;\n    float param_2 = 0.0;\n    float4 _301 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _127, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _301 };\n    fragment0(param_3, param_4, mask, mask_smp);\n    _301 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_127",
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
