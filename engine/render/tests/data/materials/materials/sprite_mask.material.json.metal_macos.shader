{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "ed7d6aa4bb6587a53460bdad882f96cecc84c68276eec459c73c25f578a29fd8",
  "slang": "metal_macos",
  "params": [],
  "textures": [
    "mask"
  ],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _150 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _155 = _150;\n        _155.x = _82.x;\n        _155.y = _82.y;\n        _155.z = _82.z;\n        _150 = _155;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _150;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _245 = fa_linear_to_srgb(param);\n        c = _245;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _253 = fa_srgb_to_linear(param_1);\n            c = _253;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _264 = tex.sample(smp, p);\n    float3 param = _264.xyz;\n    float param_1 = xform.y;\n    float3 _274 = fa_tex_fix(param, param_1);\n    return float4(_274, _264.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _87 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_87.x * 255.0) + 0.5) * 256.0) + floor((_87.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _111 = length(d);\n    if (_111 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _125 = precise::atan2(d.y, d.x);\n    float a = _125;\n    float _128;\n    if (_125 < 0.0)\n    {\n        _128 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _128 = a;\n    }\n    a = _128;\n    float _140 = _128 * 162.9746551513671875;\n    float _145 = fast::min(floor(_140), 1023.0);\n    float _152 = _145 + 1.0;\n    float i1 = _152;\n    if (_152 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _145;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _111) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _111) + 0.5, 0.0, 1.0), _140 - _145);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _306, thread float2& uv, thread float2& world_xy, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex, sampler light_smp)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _381 = _306.lit.y > 0.5;\n    if (_381)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _306.normal_uv.xy) + _306.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _405 = fa_tex_fix(param, param_1);\n        float3 _409 = (_405 * 2.0) - float3(1.0);\n        float _416 = cos(params.y);\n        float _418 = sin(params.y);\n        n = fast::normalize(float3((float2(_416, _418) * _409.x) + ((float2(-_418, _416) * ((mode > 5.5) ? (-1.0) : 1.0)) * _409.y), fast::max(_409.z, 0.0500000007450580596923828125)));\n    }\n    bool _451 = !_381;\n    bool _457;\n    if (_451)\n    {\n        _457 = _306.lit.z > 0.5;\n    }\n    else\n    {\n        _457 = _451;\n    }\n    float3 _460;\n    if (_457)\n    {\n        _460 = _306.flat_ambient.xyz;\n    }\n    else\n    {\n        _460 = _306.ambient.xyz;\n    }\n    float3 total = _460;\n    bool _477;\n    if (_457)\n    {\n        _477 = _306.lit.z < 1.5;\n    }\n    else\n    {\n        _477 = _457;\n    }\n    if (_477)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _306.light_map.xy), level(0.0)).xyz * _306.light_map.z);\n    }\n    float3 l;\n    float _596;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _517;\n        if (!_457)\n        {\n            _517 = float(i) >= _306.lit.x;\n        }\n        else\n        {\n            _517 = _457;\n        }\n        if (_517)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_306.light_pos[i].w < 0.0)\n        {\n            l = _306.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _543 = _306.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_543) / fast::max(_306.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _306.light_color[i].w);\n            float3 _563 = float3(_543, _306.light_pos[i].z);\n            l = _563 / float3(fast::max(length(_563), 9.9999997473787516355514526367188e-05));\n            if (_306.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _306.light_shadow_v[i].x;\n                float2 param_3 = -_543;\n                float param_4 = _306.light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4, shadow_tex, shadow_smp);\n            }\n        }\n        if (_381)\n        {\n            _596 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _596 = 1.0;\n        }\n        total += (_306.light_color[i].xyz * (att * _596));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _291 = fa_srgb_to_linear(param);\n        c = _291;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& params, thread float2& shape_half, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _625 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _629 = uv * _625;\n    float _635 = _625.x;\n    float _637 = _625.y;\n    float _639 = fast::clamp(shape_rs.x, 0.0, fast::min(_635, _637));\n    float2 _650 = (abs(_629) - _625) + float2(_639);\n    float d = (length(fast::max(_650, float2(0.0))) + fast::min(fast::max(_650.x, _650.y), 0.0)) - _639;\n    float ax = params.y;\n    bool _671 = params.y > 15.0;\n    if (_671)\n    {\n        ax -= 20.0;\n    }\n    float _682;\n    if (ax <= (-1.5))\n    {\n        _682 = (-2.0) - ax;\n    }\n    else\n    {\n        _682 = 0.0;\n    }\n    if (_682 > 0.0)\n    {\n        float _696 = _682 * 0.5;\n        d = abs(d + _696) - _696;\n    }\n    float _704 = fwidth(d);\n    float _705 = fast::max(_704, 9.9999997473787516355514526367188e-05);\n    float _715 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _705)), 0.0, 1.0);\n    float _720;\n    if (shape_rs.y > _705)\n    {\n        _720 = (_715 * _715) * (3.0 - (2.0 * _715));\n    }\n    else\n    {\n        _720 = _715;\n    }\n    float4 c = color;\n    bool _742 = (_682 <= 0.0) && (ax > (-0.5));\n    if (_742)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _757 = cos(ax);\n            float _759 = sin(ax);\n            g = ((dot(_629, float2(_757, _759)) / fast::max((abs(_757) * _635) + (abs(_759) * _637), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_671)\n        {\n            float4 _802 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _802;\n            float3 param = _802.xyz;\n            float param_1 = xform.y;\n            float3 _809 = fa_tex_fix(param, param_1);\n            float4 _1501 = c;\n            _1501.x = _809.x;\n            _1501.y = _809.y;\n            _1501.z = _809.z;\n            c = _1501;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _821 = scene_rgb(param_2, xform);\n            float4 _846 = mix(float4(color.xyz * color.w, color.w), float4(_821 * color2.w, color2.w), float4(g));\n            float _848 = _846.w;\n            float3 _851;\n            if (_848 > 9.9999997473787516355514526367188e-06)\n            {\n                _851 = _846.xyz / float3(_848);\n            }\n            else\n            {\n                _851 = color.xyz;\n            }\n            c = float4(_851, _848);\n        }\n    }\n    float4 _1510 = c;\n    _1510.w = _1510.w * _720;\n    c = _1510;\n    if (_742 || (shape_rs.y > 0.0))\n    {\n        float _892 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _901 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _901 + float3(_892 * 0.0039215688593685626983642578125);\n            float3 _907 = fa_srgb_to_linear(param_4);\n            float4 _1513 = c;\n            _1513.x = _907.x;\n            _1513.y = _907.y;\n            _1513.z = _907.z;\n            c = _1513;\n        }\n        else\n        {\n            float4 _917 = c;\n            float3 _920 = _917.xyz + float3(_892 * 0.0039215688593685626983642578125);\n            float4 _1520 = _917;\n            _1520.x = _920.x;\n            _1520.y = _920.y;\n            _1520.z = _920.z;\n            c = _1520;\n        }\n        float4 _1525 = c;\n        _1525.w = fast::clamp(_1525.w + ((_892 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1525.w)), 0.0, 1.0);\n        c = _1525;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _306)\n{\n    float2 _313 = gl_FragCoord.xy * _306.fa_target.xy;\n    float _317 = _313.y;\n    return float2(_313.x, mix(_317, 1.0 - _317, _306.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _306, thread float2& uv, thread float4& color, thread float2& world_xy)\n{\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _306), _306.fa_time.x, base_mode, float4(0.0) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, texture2d<float> mask, sampler mask_smp)\n{\n    float4 _367 = mask.sample(mask_smp, float2(0.0500000007450580596923828125));\n    s.color.x = _367.x;\n    s.color.y = _367.y;\n    s.color.z = _367.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _306 [[buffer(1)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> mask [[texture(4)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], sampler mask_smp [[sampler(3)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _947 = in.params.x > 31.5;\n    if (_947)\n    {\n        mode -= 32.0;\n    }\n    float _955 = mode;\n    bool _957 = _955 > 15.5;\n    if (_957)\n    {\n        mode -= 16.0;\n    }\n    float _965 = mode;\n    bool _967 = _965 > 7.5;\n    if (_967)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_957)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _306, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.params, in.shape_half, in.shape_rs, in.color2);\n            if (_957)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _306, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1031 = tex_color(param_5, tex, smp, in.xform) * in.color;\n                float4 param_6 = _1031;\n                float param_7 = mode;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _306, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), _1031.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1067 = length(in.uv);\n                    float _1070 = fwidth(_1067);\n                    float _1071 = fast::max(_1070, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1067) / _1071) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1067) / _1071) + 0.5, 0.0, 1.0) * fast::clamp(((_1067 - in.params.y) / _1071) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1112 = fast::clamp(1.0 - _1067, 0.0, 1.0);\n                            cov = (_1112 * _1112) * (3.0 - (2.0 * _1112));\n                        }\n                    }\n                    float3 _1121;\n                    if (_957)\n                    {\n                        float4 param_8 = in.color;\n                        float param_9 = 5.0;\n                        _1121 = lit_color(param_8, param_9, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _306, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp);\n                    }\n                    else\n                    {\n                        _1121 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1121, in.color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    QuadInput param_11 = fa_quad_input(param_10, gl_FragCoord, _306, in.uv, in.color, in.world_xy);\n    QuadSurface param_12 = QuadSurface{ out.frag_color };\n    fragment0(param_11, param_12, mask, mask_smp);\n    out.frag_color = param_12.color;\n    if (_947)\n    {\n        float4 _1158 = out.frag_color;\n        float3 param_13 = in.color2.xyz;\n        float3 _1163 = scene_rgb(param_13, in.xform);\n        float3 _1167 = mix(_1158.xyz, _1163, float3(in.color2.w));\n        out.frag_color.x = _1167.x;\n        out.frag_color.y = _1167.y;\n        out.frag_color.z = _1167.z;\n    }\n    if (_967)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1191 = _306.fog_col.w > 0.0;\n    bool _1199;\n    if (!_1191)\n    {\n        _1199 = _306.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1199 = _1191;\n    }\n    if (_1199)\n    {\n        float3 _1213 = float3(in.world_xy, in.world_z) - _306.fog_eye.xyz;\n        float _1220 = dot(_1213, _306.fog_c.xyz);\n        bool _1224 = _306.fog_c.w > 0.5;\n        float _1225;\n        if (_1224)\n        {\n            _1225 = _1220;\n        }\n        else\n        {\n            _1225 = length(_1213);\n        }\n        float _1237 = _1225 - _306.fog_b.x;\n        if (_1237 > 0.0)\n        {\n            float _1246 = _306.fog_col.w * _1237;\n            float tau = _1246 * _1246;\n            if (_306.fog_b.y > 0.0)\n            {\n                float _1262;\n                if (_1224)\n                {\n                    _1262 = in.world_xy.y - (_306.fog_c.y * _1220);\n                }\n                else\n                {\n                    _1262 = _306.fog_eye.y;\n                }\n                float _1283 = mix(_1262, in.world_xy.y, fast::clamp(_306.fog_b.x / _1225, 0.0, 1.0));\n                float _1287 = in.world_xy.y - _1283;\n                float _1292 = _1283 - _306.fog_b.z;\n                float _1297 = in.world_xy.y - _306.fog_b.z;\n                bool _1300 = _1292 <= 0.0;\n                bool _1301 = !_1300;\n                bool _1307;\n                if (_1301)\n                {\n                    _1307 = _306.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1307 = _1300;\n                }\n                float _1308;\n                if (_1307)\n                {\n                    _1308 = _306.fog_b.y;\n                }\n                else\n                {\n                    _1308 = _306.fog_b.y * exp(-fast::min(_306.fog_b.w * _1292, 80.0));\n                }\n                bool _1335;\n                if (_1301)\n                {\n                    _1335 = _306.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1335 = _1300;\n                }\n                float _1336;\n                if (_1335)\n                {\n                    _1336 = _306.fog_b.y * _1292;\n                }\n                else\n                {\n                    _1336 = (_306.fog_b.y * (1.0 - exp(-fast::min(_306.fog_b.w * _1292, 80.0)))) / _306.fog_b.w;\n                }\n                bool _1361 = _1297 <= 0.0;\n                bool _1368;\n                if (!_1361)\n                {\n                    _1368 = _306.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1368 = _1361;\n                }\n                float _1369;\n                if (_1368)\n                {\n                    _1369 = _306.fog_b.y * _1297;\n                }\n                else\n                {\n                    _1369 = (_306.fog_b.y * (1.0 - exp(-fast::min(_306.fog_b.w * _1297, 80.0)))) / _306.fog_b.w;\n                }\n                float _1396;\n                if (abs(_1287) < 0.001000000047497451305389404296875)\n                {\n                    _1396 = _1308;\n                }\n                else\n                {\n                    _1396 = (_1369 - _1336) / _1287;\n                }\n                tau += (_1237 * fast::max(_1396, 0.0));\n            }\n            float4 _1419 = out.frag_color;\n            float3 _1427 = mix(_1419.xyz, _306.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _1427.x;\n            out.frag_color.y = _1427.y;\n            out.frag_color.z = _1427.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "inst_name": "_306",
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
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _99 = fa_linear_to_srgb(param);\n        c = _99;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _108 = fa_srgb_to_linear(param_1);\n            c = _108;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _125)\n{\n    float2 _132 = gl_FragCoord.xy * _125.fa_target.xy;\n    float _138 = _132.y;\n    return float2(_132.x, mix(_138, 1.0 - _138, _125.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _125, thread float2& uv, thread float4& color, thread float2& world_xy)\n{\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _125), _125.fa_time.x, base_mode, float4(0.0) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, texture2d<float> mask, sampler mask_smp)\n{\n    float4 _195 = mask.sample(mask_smp, float2(0.0500000007450580596923828125));\n    s.color.x = _195.x;\n    s.color.y = _195.y;\n    s.color.z = _195.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _125 [[buffer(1)]], texture2d<float> tex [[texture(0)]], texture2d<float> mask [[texture(1)]], sampler smp [[sampler(0)]], sampler mask_smp [[sampler(3)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _210 = tex.sample(smp, in.uv);\n    float3 param = _210.xyz;\n    float param_1 = in.xform.y;\n    float3 _222 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_222, _210.w) * in.color;\n    float param_2 = 0.0;\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _125, in.uv, in.color, in.world_xy);\n    QuadSurface param_4 = QuadSurface{ out.frag_color };\n    fragment0(param_3, param_4, mask, mask_smp);\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "inst_name": "_125",
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
