{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "92b6737b88986088c23ec149effb731593899af4f139a1a2f6aa207cd28c4169",
  "slang": "metal_macos",
  "params": [
    "tint"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _147 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _147;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n};\n\nstruct fa_material\n{\n    float4 tint;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _250 = fa_linear_to_srgb(param);\n        c = _250;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _258 = fa_srgb_to_linear(param_1);\n            c = _258;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _269 = tex.sample(smp, p);\n    float3 param = _269.xyz;\n    float param_1 = xform.y;\n    float3 _279 = fa_tex_fix(param, param_1);\n    return float4(_279, _269.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _92 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_92.x * 255.0) + 0.5) * 256.0) + floor((_92.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _116 = length(d);\n    if (_116 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _130 = precise::atan2(d.y, d.x);\n    float a = _130;\n    float _133;\n    if (_130 < 0.0)\n    {\n        _133 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _133 = a;\n    }\n    a = _133;\n    float _145 = _133 * 162.9746551513671875;\n    float _150 = fast::min(floor(_145), 1023.0);\n    float _157 = _150 + 1.0;\n    float i1 = _157;\n    if (_157 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _150;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _116) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _116) + 0.5, 0.0, 1.0), _145 - _150);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, thread float4& gl_FragCoord, constant quad_fs_params& _317, thread float2& uv, thread float2& world_xy, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex, sampler light_smp)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _418 = _317.lit.y > 0.5;\n    if (_418)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _317.normal_uv.xy) + _317.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _442 = fa_tex_fix(param, param_1);\n        float3 _446 = (_442 * 2.0) - float3(1.0);\n        float _453 = cos(params.y);\n        float _455 = sin(params.y);\n        n = fast::normalize(float3((float2(_453, _455) * _446.x) + ((float2(-_455, _453) * ((mode > 5.5) ? (-1.0) : 1.0)) * _446.y), fast::max(_446.z, 0.0500000007450580596923828125)));\n    }\n    bool _489 = !_418;\n    bool _495;\n    if (_489)\n    {\n        _495 = _317.lit.z > 0.5;\n    }\n    else\n    {\n        _495 = _489;\n    }\n    float3 _498;\n    if (_495)\n    {\n        _498 = _317.flat_ambient.xyz;\n    }\n    else\n    {\n        _498 = _317.ambient.xyz;\n    }\n    float3 total = _498;\n    bool _515;\n    if (_495)\n    {\n        _515 = _317.lit.z < 1.5;\n    }\n    else\n    {\n        _515 = _495;\n    }\n    if (_515)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _317.light_map.xy), level(0.0)).xyz * _317.light_map.z);\n    }\n    float3 l;\n    float _633;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _555;\n        if (!_495)\n        {\n            _555 = float(i) >= _317.lit.x;\n        }\n        else\n        {\n            _555 = _495;\n        }\n        if (_555)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_317.light_pos[i].w < 0.0)\n        {\n            l = _317.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _581 = _317.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_581) / fast::max(_317.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _317.light_color[i].w);\n            float3 _601 = float3(_581, _317.light_pos[i].z);\n            l = _601 / float3(fast::max(length(_601), 9.9999997473787516355514526367188e-05));\n            if (_317.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _317.light_shadow_v[i].x;\n                float2 param_3 = -_581;\n                float param_4 = _317.light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4, shadow_tex, shadow_smp);\n            }\n        }\n        if (_418)\n        {\n            _633 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _633 = 1.0;\n        }\n        total += (_317.light_color[i].xyz * (att * _633));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _296 = fa_srgb_to_linear(param);\n        c = _296;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _661 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _665 = uv * _661;\n    float _671 = _661.x;\n    float _673 = _661.y;\n    float _675 = fast::clamp(shape_rs.x, 0.0, fast::min(_671, _673));\n    float2 _686 = (abs(_665) - _661) + float2(_675);\n    float d = (length(fast::max(_686, float2(0.0))) + fast::min(fast::max(_686.x, _686.y), 0.0)) - _675;\n    float ax = params.y;\n    bool _707 = params.y > 15.0;\n    if (_707)\n    {\n        ax -= 20.0;\n    }\n    float _718;\n    if (ax <= (-1.5))\n    {\n        _718 = (-2.0) - ax;\n    }\n    else\n    {\n        _718 = 0.0;\n    }\n    if (_718 > 0.0)\n    {\n        float _732 = _718 * 0.5;\n        d = abs(d + _732) - _732;\n    }\n    float _740 = fwidth(d);\n    float _741 = fast::max(_740, 9.9999997473787516355514526367188e-05);\n    float _751 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _741)), 0.0, 1.0);\n    float _756;\n    if (shape_rs.y > _741)\n    {\n        _756 = (_751 * _751) * (3.0 - (2.0 * _751));\n    }\n    else\n    {\n        _756 = _751;\n    }\n    float4 c = color;\n    bool _778 = (_718 <= 0.0) && (ax > (-0.5));\n    if (_778)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _793 = cos(ax);\n            float _795 = sin(ax);\n            g = ((dot(_665, float2(_793, _795)) / fast::max((abs(_793) * _671) + (abs(_795) * _673), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_707)\n        {\n            float4 _838 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _838;\n            float3 param = _838.xyz;\n            float param_1 = xform.y;\n            float3 _845 = fa_tex_fix(param, param_1);\n            float4 _1542 = c;\n            _1542.x = _845.x;\n            _1542.y = _845.y;\n            _1542.z = _845.z;\n            c = _1542;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _857 = scene_rgb(param_2, xform);\n            float4 _882 = mix(float4(color.xyz * color.w, color.w), float4(_857 * color2.w, color2.w), float4(g));\n            float _884 = _882.w;\n            float3 _887;\n            if (_884 > 9.9999997473787516355514526367188e-06)\n            {\n                _887 = _882.xyz / float3(_884);\n            }\n            else\n            {\n                _887 = color.xyz;\n            }\n            c = float4(_887, _884);\n        }\n    }\n    float4 _1551 = c;\n    _1551.w = _1551.w * _756;\n    c = _1551;\n    if (_778 || (shape_rs.y > 0.0))\n    {\n        float _928 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _937 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _937 + float3(_928 * 0.0039215688593685626983642578125);\n            float3 _943 = fa_srgb_to_linear(param_4);\n            float4 _1554 = c;\n            _1554.x = _943.x;\n            _1554.y = _943.y;\n            _1554.z = _943.z;\n            c = _1554;\n        }\n        else\n        {\n            float4 _953 = c;\n            float3 _956 = _953.xyz + float3(_928 * 0.0039215688593685626983642578125);\n            float4 _1561 = _953;\n            _1561.x = _956.x;\n            _1561.y = _956.y;\n            _1561.z = _956.z;\n            c = _1561;\n        }\n        float4 _1566 = c;\n        _1566.w = fast::clamp(_1566.w + ((_928 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1566.w)), 0.0, 1.0);\n        c = _1566;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _317)\n{\n    float2 _324 = gl_FragCoord.xy * _317.fa_target.xy;\n    float _328 = _324.y;\n    return float2(_324.x, mix(_328, 1.0 - _328, _317.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _317, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _370 = base_mode < 0.5;\n    bool _381;\n    if (!_370)\n    {\n        _381 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _381 = _370;\n    }\n    float _382;\n    if (_381)\n    {\n        _382 = shape_half.x;\n    }\n    else\n    {\n        _382 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _317), _317.fa_time.x, base_mode, float4(0.0), _382 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _302 = scene_rgb(param, xform);\n    return _302;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, constant fa_material& _396)\n{\n    float3 param = _396.tint.xyz;\n    float4 _403 = s.color;\n    float3 _405 = _403.xyz * fa_scene_rgb(param, xform);\n    s.color.x = _405.x;\n    s.color.y = _405.y;\n    s.color.z = _405.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _317 [[buffer(1)]], constant fa_material& _396 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _983 = in.params.x > 31.5;\n    if (_983)\n    {\n        mode -= 32.0;\n    }\n    float _991 = mode;\n    bool _993 = _991 > 15.5;\n    if (_993)\n    {\n        mode -= 16.0;\n    }\n    float _1001 = mode;\n    bool _1003 = _1001 > 7.5;\n    if (_1003)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_993)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _317, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_993)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _317, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1067 = tex_color(param_5, tex, smp, in.xform) * in.color;\n                float4 param_6 = _1067;\n                float param_7 = mode;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _317, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp), _1067.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1102 = length(in.uv);\n                    float _1105 = fwidth(_1102);\n                    float _1106 = fast::max(_1105, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1102) / _1106) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1102) / _1106) + 0.5, 0.0, 1.0) * fast::clamp(((_1102 - in.params.y) / _1106) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1146 = fast::clamp(1.0 - _1102, 0.0, 1.0);\n                            cov = (_1146 * _1146) * (3.0 - (2.0 * _1146));\n                        }\n                    }\n                    float3 _1155;\n                    if (_993)\n                    {\n                        float4 param_8 = in.color;\n                        float param_9 = 5.0;\n                        _1155 = lit_color(param_8, param_9, shadow_tex, shadow_smp, smp, in.xform, gl_FragCoord, _317, in.uv, in.world_xy, normal_tex, in.params, light_tex, light_smp);\n                    }\n                    else\n                    {\n                        _1155 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1155, in.color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1495 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10, gl_FragCoord, _317, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_12 = QuadSurface{ _1495 };\n    fragment0(param_11, param_12, in.xform, _396);\n    _1495 = param_12.color;\n    out.frag_color = param_12.color;\n    if (_983)\n    {\n        float4 _1193 = out.frag_color;\n        float3 param_13 = in.color2.xyz;\n        float3 _1198 = scene_rgb(param_13, in.xform);\n        float3 _1202 = mix(_1193.xyz, _1198, float3(in.color2.w));\n        out.frag_color.x = _1202.x;\n        out.frag_color.y = _1202.y;\n        out.frag_color.z = _1202.z;\n    }\n    if (_1003)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1226 = _317.fog_col.w > 0.0;\n    bool _1234;\n    if (!_1226)\n    {\n        _1234 = _317.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1234 = _1226;\n    }\n    if (_1234)\n    {\n        float3 _1248 = float3(in.world_xy, in.world_z) - _317.fog_eye.xyz;\n        float _1255 = dot(_1248, _317.fog_c.xyz);\n        bool _1259 = _317.fog_c.w > 0.5;\n        float _1260;\n        if (_1259)\n        {\n            _1260 = _1255;\n        }\n        else\n        {\n            _1260 = length(_1248);\n        }\n        float _1272 = _1260 - _317.fog_b.x;\n        if (_1272 > 0.0)\n        {\n            float _1281 = _317.fog_col.w * _1272;\n            float tau = _1281 * _1281;\n            if (_317.fog_b.y > 0.0)\n            {\n                float _1297;\n                if (_1259)\n                {\n                    _1297 = in.world_xy.y - (_317.fog_c.y * _1255);\n                }\n                else\n                {\n                    _1297 = _317.fog_eye.y;\n                }\n                float _1318 = mix(_1297, in.world_xy.y, fast::clamp(_317.fog_b.x / _1260, 0.0, 1.0));\n                float _1322 = in.world_xy.y - _1318;\n                float _1327 = _1318 - _317.fog_b.z;\n                float _1332 = in.world_xy.y - _317.fog_b.z;\n                bool _1335 = _1327 <= 0.0;\n                bool _1336 = !_1335;\n                bool _1342;\n                if (_1336)\n                {\n                    _1342 = _317.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1342 = _1335;\n                }\n                float _1343;\n                if (_1342)\n                {\n                    _1343 = _317.fog_b.y;\n                }\n                else\n                {\n                    _1343 = _317.fog_b.y * exp(-fast::min(_317.fog_b.w * _1327, 80.0));\n                }\n                bool _1370;\n                if (_1336)\n                {\n                    _1370 = _317.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1370 = _1335;\n                }\n                float _1371;\n                if (_1370)\n                {\n                    _1371 = _317.fog_b.y * _1327;\n                }\n                else\n                {\n                    _1371 = (_317.fog_b.y * (1.0 - exp(-fast::min(_317.fog_b.w * _1327, 80.0)))) / _317.fog_b.w;\n                }\n                bool _1396 = _1332 <= 0.0;\n                bool _1403;\n                if (!_1396)\n                {\n                    _1403 = _317.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1403 = _1396;\n                }\n                float _1404;\n                if (_1403)\n                {\n                    _1404 = _317.fog_b.y * _1332;\n                }\n                else\n                {\n                    _1404 = (_317.fog_b.y * (1.0 - exp(-fast::min(_317.fog_b.w * _1332, 80.0)))) / _317.fog_b.w;\n                }\n                float _1431;\n                if (abs(_1322) < 0.001000000047497451305389404296875)\n                {\n                    _1431 = _1343;\n                }\n                else\n                {\n                    _1431 = (_1404 - _1371) / _1322;\n                }\n                tau += (_1272 * fast::max(_1431, 0.0));\n            }\n            float4 _1454 = out.frag_color;\n            float3 _1462 = mix(_1454.xyz, _317.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _1462.x;\n            out.frag_color.y = _1462.y;\n            out.frag_color.z = _1462.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "size": 1008,
            "struct_name": "quad_fs_params",
            "inst_name": "_317",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_396",
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
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _147 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _147;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n};\n\nstruct fa_material\n{\n    float4 tint;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _107 = fa_linear_to_srgb(param);\n        c = _107;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _116 = fa_srgb_to_linear(param_1);\n            c = _116;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(thread float4& gl_FragCoord, constant quad_fs_params& _155)\n{\n    float2 _162 = gl_FragCoord.xy * _155.fa_target.xy;\n    float _167 = _162.y;\n    return float2(_162.x, mix(_167, 1.0 - _167, _155.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, thread float4& gl_FragCoord, constant quad_fs_params& _155, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _211 = base_mode < 0.5;\n    bool _222;\n    if (!_211)\n    {\n        _222 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _222 = _211;\n    }\n    float _223;\n    if (_222)\n    {\n        _223 = shape_half.x;\n    }\n    else\n    {\n        _223 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(gl_FragCoord, _155), _155.fa_time.x, base_mode, float4(0.0), _223 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _132 = fa_srgb_to_linear(param);\n        c = _132;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_scene_rgb(thread const float3& c, thread float3& xform)\n{\n    float3 param = c;\n    float3 _138 = scene_rgb(param, xform);\n    return _138;\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, thread float3& xform, constant fa_material& _237)\n{\n    float3 param = _237.tint.xyz;\n    float4 _244 = s.color;\n    float3 _246 = _244.xyz * fa_scene_rgb(param, xform);\n    s.color.x = _246.x;\n    s.color.y = _246.y;\n    s.color.z = _246.z;\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _155 [[buffer(1)]], constant fa_material& _237 [[buffer(5)]], texture2d<float> tex [[texture(0)]], sampler smp [[sampler(0)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _265 = tex.sample(smp, in.uv);\n    float3 param = _265.xyz;\n    float param_1 = in.xform.y;\n    float3 _274 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_274, _265.w) * in.color;\n    float param_2 = 0.0;\n    float4 _329 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, gl_FragCoord, _155, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _329 };\n    fragment0(param_3, param_4, in.xform, _237);\n    _329 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "size": 1008,
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
