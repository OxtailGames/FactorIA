{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "ed7d6aa4bb6587a53460bdad882f96cecc84c68276eec459c73c25f578a29fd8",
  "slang": "metal_macos",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _144 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _144;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _245 = fa_linear_to_srgb(param);\n        c = _245;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _253 = fa_srgb_to_linear(param_1);\n            c = _253;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _264 = tex.sample(smp, p);\n    float3 param = _264.xyz;\n    float param_1 = xform.y;\n    float3 _274 = fa_tex_fix(param, param_1);\n    return float4(_274, _264.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _87 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_87.x * 255.0) + 0.5) * 256.0) + floor((_87.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _111 = length(d);\n    if (_111 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _125 = precise::atan2(d.y, d.x);\n    float a = _125;\n    float _128;\n    if (_125 < 0.0)\n    {\n        _128 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _128 = a;\n    }\n    a = _128;\n    float _140 = _128 * 162.9746551513671875;\n    float _145 = fast::min(floor(_140), 1023.0);\n    float _152 = _145 + 1.0;\n    float i1 = _152;\n    if (_152 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _145;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _111) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _111) + 0.5, 0.0, 1.0), _140 - _145);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _306, thread float2& uv, thread float2& world_xy, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex, sampler light_smp)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _378 = _306.lit.y > 0.5;\n    if (_378)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _306.normal_uv.xy) + _306.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _402 = fa_tex_fix(param, param_1);\n        float3 _406 = (_402 * 2.0) - float3(1.0);\n        float _413 = cos(params.y);\n        float _415 = sin(params.y);\n        n = fast::normalize(float3((float2(_413, _415) * _406.x) + ((float2(-_415, _413) * ((mode > 5.5) ? (-1.0) : 1.0)) * _406.y), fast::max(_406.z, 0.0500000007450580596923828125)));\n    }\n    bool _449 = !_378;\n    bool _455;\n    if (_449)\n    {\n        _455 = _306.lit.z > 0.5;\n    }\n    else\n    {\n        _455 = _449;\n    }\n    float3 _458;\n    if (_455)\n    {\n        _458 = _306.flat_ambient.xyz;\n    }\n    else\n    {\n        _458 = _306.ambient.xyz;\n    }\n    float3 total = _458;\n    bool _475;\n    if (_455)\n    {\n        _475 = _306.lit.z < 1.5;\n    }\n    else\n    {\n        _475 = _455;\n    }\n    if (_475)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _306.light_map.xy), level(0.0)).xyz * _306.light_map.z);\n    }\n    float3 l;\n    float _594;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _515;\n        if (!_455)\n        {\n            _515 = float(i) >= _306.lit.x;\n        }\n        else\n        {\n            _515 = _455;\n        }\n        if (_515)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_306.light_pos[i].w < 0.0)\n        {\n            l = _306.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _541 = _306.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_541) / fast::max(_306.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _306.light_color[i].w);\n            float3 _561 = float3(_541, _306.light_pos[i].z);\n            l = _561 / float3(fast::max(length(_561), 9.9999997473787516355514526367188e-05));\n            if (_306.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _306.light_shadow_v[i].x;\n                float2 param_3 = -_541;\n                float param_4 = _306.light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4, shadow_tex, shadow_smp);\n            }\n        }\n        if (_378)\n        {\n            _594 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _594 = 1.0;\n        }\n        total += (_306.light_color[i].xyz * (att * _594));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _291 = fa_srgb_to_linear(param);\n        c = _291;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& params, thread float2& shape_half, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _623 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _627 = uv * _623;\n    float _633 = _623.x;\n    float _635 = _623.y;\n    float _637 = fast::clamp(shape_rs.x, 0.0, fast::min(_633, _635));\n    float2 _648 = (abs(_627) - _623) + float2(_637);\n    float d = (length(fast::max(_648, float2(0.0))) + fast::min(fast::max(_648.x, _648.y), 0.0)) - _637;\n    float ax = params.y;\n    bool _669 = params.y > 15.0;\n    if (_669)\n    {\n        ax -= 20.0;\n    }\n    float _680;\n    if (ax <= (-1.5))\n    {\n        _680 = (-2.0) - ax;\n    }\n    else\n    {\n        _680 = 0.0;\n    }\n    if (_680 > 0.0)\n    {\n        float _694 = _680 * 0.5;\n        d = abs(d + _694) - _694;\n    }\n    float _702 = fwidth(d);\n    float _703 = fast::max(_702, 9.9999997473787516355514526367188e-05);\n    float _713 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _703)), 0.0, 1.0);\n    float _718;\n    if (shape_rs.y > _703)\n    {\n        _718 = (_713 * _713) * (3.0 - (2.0 * _713));\n    }\n    else\n    {\n        _718 = _713;\n    }\n    float4 c = color;\n    bool _740 = (_680 <= 0.0) && (ax > (-0.5));\n    if (_740)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _755 = cos(ax);\n            float _757 = sin(ax);\n            g = ((dot(_627, float2(_755, _757)) / fast::max((abs(_755) * _633) + (abs(_757) * _635), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_669)\n        {\n            float4 _800 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _800;\n            float3 param = _800.xyz;\n            float param_1 = xform.y;\n            float3 _807 = fa_tex_fix(param, param_1);\n            float4 _1499 = c;\n            _1499.x = _807.x;\n            _1499.y = _807.y;\n            _1499.z = _807.z;\n            c = _1499;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _819 = scene_rgb(param_2, xform);\n            float4 _844 = mix(float4(color.xyz * color.w, color.w), float4(_819 * color2.w, color2.w), float4(g));\n            float _846 = _844.w;\n            float3 _849;\n            if (_846 > 9.9999997473787516355514526367188e-06)\n            {\n                _849 = _844.xyz / float3(_846);\n            }\n            else\n            {\n                _849 = color.xyz;\n            }\n            c = float4(_849, _846);\n        }\n    }\n    float4 _1508 = c;\n    _1508.w = _1508.w * _718;\n    c = _1508;\n    if (_740 || (shape_rs.y > 0.0))\n    {\n        float _890 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _899 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _899 + float3(_890 * 0.0039215688593685626983642578125);\n            float3 _905 = fa_srgb_to_linear(param_4);\n            float4 _1511 = c;\n            _1511.x = _905.x;\n            _1511.y = _905.y;\n            _1511.z = _905.z;\n            c = _1511;\n        }\n        else\n        {\n            float4 _915 = c;\n            float3 _918 = _915.xyz + float3(_890 * 0.0039215688593685626983642578125);\n            float4 _1518 = _915;\n            _1518.x = _918.x;\n            _1518.y = _918.y;\n            _1518.z = _918.z;\n            c = _1518;\n        }\n        float4 _1523 = c;\n        _1523.w = fast::clamp(_1523.w + ((_890 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1523.w)), 0.0, 1.0);\n        c = _1523;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _306)\n{\n    float2 _313 = gl_FragCoord.xy * _306.fa_target.xy;\n    float _317 = _313.y;\n    return float2(_313.x, mix(_317, 1.0 - _317, _306.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _306, thread float2& uv, thread float4& color, thread float2& world_xy)\n{\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _306), _306.fa_time.x, base_mode, float4(0.0) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s)\n{\n    s.color.x = fast::clamp(i.time * 0.25, 0.0, 1.0);\n    s.color.y = 0.0;\n    s.color.z = 0.0;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _306 [[buffer(1)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _945 = in.params.x > 31.5;\n    if (_945)\n    {\n        mode -= 32.0;\n    }\n    float _953 = mode;\n    bool _955 = _953 > 15.5;\n    if (_955)\n    {\n        mode -= 16.0;\n    }\n    float _963 = mode;\n    bool _965 = _963 > 7.5;\n    if (_965)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_955)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _306, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.params, in.shape_half, in.shape_rs, in.color2);\n            if (_955)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _306, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1029 = tex_color(param_5, tex, smp, in.xform) * in.color;\n                float4 param_6 = _1029;\n                float param_7 = mode;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _306, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), _1029.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1065 = length(in.uv);\n                    float _1068 = fwidth(_1065);\n                    float _1069 = fast::max(_1068, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1065) / _1069) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1065) / _1069) + 0.5, 0.0, 1.0) * fast::clamp(((_1065 - in.params.y) / _1069) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1110 = fast::clamp(1.0 - _1065, 0.0, 1.0);\n                            cov = (_1110 * _1110) * (3.0 - (2.0 * _1110));\n                        }\n                    }\n                    float3 _1119;\n                    if (_955)\n                    {\n                        float4 param_8 = in.color;\n                        float param_9 = 5.0;\n                        _1119 = lit_color(param_8, param_9, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _306, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp);\n                    }\n                    else\n                    {\n                        _1119 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1119, in.color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    QuadInput param_11 = fa_quad_input(param_10, gl_FragCoord, _306, in.uv, in.color, in.world_xy);\n    QuadSurface param_12 = QuadSurface{ out.frag_color };\n    fragment0(param_11, param_12);\n    out.frag_color = param_12.color;\n    if (_945)\n    {\n        float4 _1156 = out.frag_color;\n        float3 param_13 = in.color2.xyz;\n        float3 _1161 = scene_rgb(param_13, in.xform);\n        float3 _1165 = mix(_1156.xyz, _1161, float3(in.color2.w));\n        out.frag_color.x = _1165.x;\n        out.frag_color.y = _1165.y;\n        out.frag_color.z = _1165.z;\n    }\n    if (_965)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1189 = _306.fog_col.w > 0.0;\n    bool _1197;\n    if (!_1189)\n    {\n        _1197 = _306.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1197 = _1189;\n    }\n    if (_1197)\n    {\n        float3 _1211 = float3(in.world_xy, in.world_z) - _306.fog_eye.xyz;\n        float _1218 = dot(_1211, _306.fog_c.xyz);\n        bool _1222 = _306.fog_c.w > 0.5;\n        float _1223;\n        if (_1222)\n        {\n            _1223 = _1218;\n        }\n        else\n        {\n            _1223 = length(_1211);\n        }\n        float _1235 = _1223 - _306.fog_b.x;\n        if (_1235 > 0.0)\n        {\n            float _1244 = _306.fog_col.w * _1235;\n            float tau = _1244 * _1244;\n            if (_306.fog_b.y > 0.0)\n            {\n                float _1260;\n                if (_1222)\n                {\n                    _1260 = in.world_xy.y - (_306.fog_c.y * _1218);\n                }\n                else\n                {\n                    _1260 = _306.fog_eye.y;\n                }\n                float _1281 = mix(_1260, in.world_xy.y, fast::clamp(_306.fog_b.x / _1223, 0.0, 1.0));\n                float _1285 = in.world_xy.y - _1281;\n                float _1290 = _1281 - _306.fog_b.z;\n                float _1295 = in.world_xy.y - _306.fog_b.z;\n                bool _1298 = _1290 <= 0.0;\n                bool _1299 = !_1298;\n                bool _1305;\n                if (_1299)\n                {\n                    _1305 = _306.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1305 = _1298;\n                }\n                float _1306;\n                if (_1305)\n                {\n                    _1306 = _306.fog_b.y;\n                }\n                else\n                {\n                    _1306 = _306.fog_b.y * exp(-fast::min(_306.fog_b.w * _1290, 80.0));\n                }\n                bool _1333;\n                if (_1299)\n                {\n                    _1333 = _306.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1333 = _1298;\n                }\n                float _1334;\n                if (_1333)\n                {\n                    _1334 = _306.fog_b.y * _1290;\n                }\n                else\n                {\n                    _1334 = (_306.fog_b.y * (1.0 - exp(-fast::min(_306.fog_b.w * _1290, 80.0)))) / _306.fog_b.w;\n                }\n                bool _1359 = _1295 <= 0.0;\n                bool _1366;\n                if (!_1359)\n                {\n                    _1366 = _306.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1366 = _1359;\n                }\n                float _1367;\n                if (_1366)\n                {\n                    _1367 = _306.fog_b.y * _1295;\n                }\n                else\n                {\n                    _1367 = (_306.fog_b.y * (1.0 - exp(-fast::min(_306.fog_b.w * _1295, 80.0)))) / _306.fog_b.w;\n                }\n                float _1394;\n                if (abs(_1285) < 0.001000000047497451305389404296875)\n                {\n                    _1394 = _1306;\n                }\n                else\n                {\n                    _1394 = (_1367 - _1334) / _1285;\n                }\n                tau += (_1235 * fast::max(_1394, 0.0));\n            }\n            float4 _1417 = out.frag_color;\n            float3 _1425 = mix(_1417.xyz, _306.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _1425.x;\n            out.frag_color.y = _1425.y;\n            out.frag_color.z = _1425.z;\n        }\n    }\n    return out;\n}\n\n",
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
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _144 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _144;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _99 = fa_linear_to_srgb(param);\n        c = _99;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _108 = fa_srgb_to_linear(param_1);\n            c = _108;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _125)\n{\n    float2 _132 = gl_FragCoord.xy * _125.fa_target.xy;\n    float _138 = _132.y;\n    return float2(_132.x, mix(_138, 1.0 - _138, _125.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _125, thread float2& uv, thread float4& color, thread float2& world_xy)\n{\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _125), _125.fa_time.x, base_mode, float4(0.0) };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s)\n{\n    s.color.x = fast::clamp(i.time * 0.25, 0.0, 1.0);\n    s.color.y = 0.0;\n    s.color.z = 0.0;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _125 [[buffer(1)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _207 = tex.sample(smp, in.uv);\n    float3 param = _207.xyz;\n    float param_1 = in.xform.y;\n    float3 _219 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_219, _207.w) * in.color;\n    float param_2 = 0.0;\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _125, in.uv, in.color, in.world_xy);\n    QuadSurface param_4 = QuadSurface{ out.frag_color };\n    fragment0(param_3, param_4);\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
