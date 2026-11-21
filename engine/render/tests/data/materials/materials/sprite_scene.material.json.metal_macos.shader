{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "92b6737b88986088c23ec149effb731593899af4f139a1a2f6aa207cd28c4169",
  "slang": "metal_macos",
  "params": [
    "amount",
    "dx",
    "dy"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _147 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _147;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n};\n\nstruct fa_material\n{\n    float amount;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float dx;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n    float dy;\n    float fa_pad6;\n    float fa_pad7;\n    float fa_pad8;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _250 = fa_linear_to_srgb(param);\n        c = _250;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _258 = fa_srgb_to_linear(param_1);\n            c = _258;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 tex_color(thread const float2& p, texture2d<float> tex, sampler smp, thread float3& xform)\n{\n    float4 _269 = tex.sample(smp, p);\n    float3 param = _269.xyz;\n    float param_1 = xform.y;\n    float3 _279 = fa_tex_fix(param, param_1);\n    return float4(_279, _269.w);\n}\n\nstatic inline __attribute__((always_inline))\nfloat shadow_texel(thread const float& v, thread const float& i, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float4 _92 = shadow_tex.sample(shadow_smp, float2((i + 0.5) * 0.0009765625, v), level(0.0));\n    return ((floor((_92.x * 255.0) + 0.5) * 256.0) + floor((_92.y * 255.0) + 0.5)) * 1.525902189314365386962890625e-05;\n}\n\nstatic inline __attribute__((always_inline))\nfloat light_shadow(thread const float& v, thread const float2& d, thread const float& radius, texture2d<float> shadow_tex, sampler shadow_smp)\n{\n    float _116 = length(d);\n    if (_116 < 9.9999997473787516355514526367188e-05)\n    {\n        return 1.0;\n    }\n    float _130 = precise::atan2(d.y, d.x);\n    float a = _130;\n    float _133;\n    if (_130 < 0.0)\n    {\n        _133 = a + 6.283185482025146484375;\n    }\n    else\n    {\n        _133 = a;\n    }\n    a = _133;\n    float _145 = _133 * 162.9746551513671875;\n    float _150 = fast::min(floor(_145), 1023.0);\n    float _157 = _150 + 1.0;\n    float i1 = _157;\n    if (_157 > 1023.5)\n    {\n        i1 = 0.0;\n    }\n    float param = v;\n    float param_1 = _150;\n    float param_2 = v;\n    float param_3 = i1;\n    return mix(fast::clamp(((shadow_texel(param, param_1, shadow_tex, shadow_smp) * radius) - _116) + 0.5, 0.0, 1.0), fast::clamp(((shadow_texel(param_2, param_3, shadow_tex, shadow_smp) * radius) - _116) + 0.5, 0.0, 1.0), _145 - _150);\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 lit_color(thread const float4& base, thread const float& mode, texture2d<float> shadow_tex, sampler shadow_smp, sampler smp, thread float3& xform, constant quad_fs_params& _307, sampler light_smp, thread float4& gl_FragCoord, thread float2& uv, thread float2& world_xy, texture2d<float> normal_tex, thread float2& params, texture2d<float> light_tex)\n{\n    float3 n = float3(0.0, 0.0, 1.0);\n    bool _464 = _307.lit.y > 0.5;\n    if (_464)\n    {\n        float3 param = normal_tex.sample(smp, ((uv * _307.normal_uv.xy) + _307.normal_uv.zw)).xyz;\n        float param_1 = xform.z;\n        float3 _488 = fa_tex_fix(param, param_1);\n        float3 _492 = (_488 * 2.0) - float3(1.0);\n        float _499 = cos(params.y);\n        float _501 = sin(params.y);\n        n = fast::normalize(float3((float2(_499, _501) * _492.x) + ((float2(-_501, _499) * ((mode > 5.5) ? (-1.0) : 1.0)) * _492.y), fast::max(_492.z, 0.0500000007450580596923828125)));\n    }\n    bool _535 = !_464;\n    bool _541;\n    if (_535)\n    {\n        _541 = _307.lit.z > 0.5;\n    }\n    else\n    {\n        _541 = _535;\n    }\n    float3 _544;\n    if (_541)\n    {\n        _544 = _307.flat_ambient.xyz;\n    }\n    else\n    {\n        _544 = _307.ambient.xyz;\n    }\n    float3 total = _544;\n    bool _561;\n    if (_541)\n    {\n        _561 = _307.lit.z < 1.5;\n    }\n    else\n    {\n        _561 = _541;\n    }\n    if (_561)\n    {\n        total += (light_tex.sample(light_smp, (gl_FragCoord.xy * _307.light_map.xy), level(0.0)).xyz * _307.light_map.z);\n    }\n    float3 l;\n    float _678;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _600;\n        if (!_541)\n        {\n            _600 = float(i) >= _307.lit.x;\n        }\n        else\n        {\n            _600 = _541;\n        }\n        if (_600)\n        {\n            break;\n        }\n        float att = 1.0;\n        if (_307.light_pos[i].w < 0.0)\n        {\n            l = _307.light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _626 = _307.light_pos[i].xy - world_xy;\n            att = powr(fast::clamp(1.0 - (length(_626) / fast::max(_307.light_pos[i].w, 0.001000000047497451305389404296875)), 0.0, 1.0), _307.light_color[i].w);\n            float3 _646 = float3(_626, _307.light_pos[i].z);\n            l = _646 / float3(fast::max(length(_646), 9.9999997473787516355514526367188e-05));\n            if (_307.light_shadow_v[i].x >= 0.0)\n            {\n                float param_2 = _307.light_shadow_v[i].x;\n                float2 param_3 = -_626;\n                float param_4 = _307.light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4, shadow_tex, shadow_smp);\n            }\n        }\n        if (_464)\n        {\n            _678 = fast::max(dot(n, l), 0.0);\n        }\n        else\n        {\n            _678 = 1.0;\n        }\n        total += (_307.light_color[i].xyz * (att * _678));\n    }\n    return base.xyz * total;\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 scene_rgb(thread float3& c, thread float3& xform)\n{\n    if (xform.x > 0.5)\n    {\n        float3 param = c;\n        float3 _296 = fa_srgb_to_linear(param);\n        c = _296;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 shape_color(texture2d<float> tex, sampler smp, thread float3& xform, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& shape_half, thread float2& params, thread float2& shape_rs, thread float4& color2)\n{\n    float2 _706 = fast::max(shape_half, float2(9.9999997473787516355514526367188e-05));\n    float2 _710 = uv * _706;\n    float _716 = _706.x;\n    float _718 = _706.y;\n    float _720 = fast::clamp(shape_rs.x, 0.0, fast::min(_716, _718));\n    float2 _731 = (abs(_710) - _706) + float2(_720);\n    float d = (length(fast::max(_731, float2(0.0))) + fast::min(fast::max(_731.x, _731.y), 0.0)) - _720;\n    float ax = params.y;\n    bool _752 = params.y > 15.0;\n    if (_752)\n    {\n        ax -= 20.0;\n    }\n    float _763;\n    if (ax <= (-1.5))\n    {\n        _763 = (-2.0) - ax;\n    }\n    else\n    {\n        _763 = 0.0;\n    }\n    if (_763 > 0.0)\n    {\n        float _777 = _763 * 0.5;\n        d = abs(d + _777) - _777;\n    }\n    float _785 = fwidth(d);\n    float _786 = fast::max(_785, 9.9999997473787516355514526367188e-05);\n    float _796 = fast::clamp(0.5 - (d / fast::max(shape_rs.y, _786)), 0.0, 1.0);\n    float _801;\n    if (shape_rs.y > _786)\n    {\n        _801 = (_796 * _796) * (3.0 - (2.0 * _796));\n    }\n    else\n    {\n        _801 = _796;\n    }\n    float4 c = color;\n    bool _823 = (_763 <= 0.0) && (ax > (-0.5));\n    if (_823)\n    {\n        float g;\n        if (ax > 7.0)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _838 = cos(ax);\n            float _840 = sin(ax);\n            g = ((dot(_710, float2(_838, _840)) / fast::max((abs(_838) * _716) + (abs(_840) * _718), 9.9999997473787516355514526367188e-05)) * 0.5) + 0.5;\n        }\n        g = fast::clamp(g, 0.0, 1.0);\n        if (_752)\n        {\n            float4 _883 = tex.sample(smp, float2((0.5 + (g * 255.0)) * 0.00390625, (floor((color2.x * 255.0) + 0.5) + 0.5) * 0.00390625), level(0.0));\n            c = _883;\n            float3 param = _883.xyz;\n            float param_1 = xform.y;\n            float3 _890 = fa_tex_fix(param, param_1);\n            float4 _1589 = c;\n            _1589.x = _890.x;\n            _1589.y = _890.y;\n            _1589.z = _890.z;\n            c = _1589;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _902 = scene_rgb(param_2, xform);\n            float4 _927 = mix(float4(color.xyz * color.w, color.w), float4(_902 * color2.w, color2.w), float4(g));\n            float _929 = _927.w;\n            float3 _932;\n            if (_929 > 9.9999997473787516355514526367188e-06)\n            {\n                _932 = _927.xyz / float3(_929);\n            }\n            else\n            {\n                _932 = color.xyz;\n            }\n            c = float4(_932, _929);\n        }\n    }\n    float4 _1598 = c;\n    _1598.w = _1598.w * _801;\n    c = _1598;\n    if (_823 || (shape_rs.y > 0.0))\n    {\n        float _973 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375, 0.005837149918079376220703125)))) - 0.5;\n        if (xform.x > 0.5)\n        {\n            float3 param_3 = c.xyz;\n            float3 _982 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _982 + float3(_973 * 0.0039215688593685626983642578125);\n            float3 _988 = fa_srgb_to_linear(param_4);\n            float4 _1601 = c;\n            _1601.x = _988.x;\n            _1601.y = _988.y;\n            _1601.z = _988.z;\n            c = _1601;\n        }\n        else\n        {\n            float4 _998 = c;\n            float3 _1001 = _998.xyz + float3(_973 * 0.0039215688593685626983642578125);\n            float4 _1608 = _998;\n            _1608.x = _1001.x;\n            _1608.y = _1001.y;\n            _1608.z = _1001.z;\n            c = _1608;\n        }\n        float4 _1613 = c;\n        _1613.w = fast::clamp(_1613.w + ((_973 * 0.0039215688593685626983642578125) * step(0.001000000047497451305389404296875, _1613.w)), 0.0, 1.0);\n        c = _1613;\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(constant quad_fs_params& _307, thread float4& gl_FragCoord)\n{\n    float2 _360 = gl_FragCoord.xy * _307.fa_target.xy;\n    float _364 = _360.y;\n    return float2(_360.x, mix(_364, 1.0 - _364, _307.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, constant quad_fs_params& _307, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _403 = base_mode < 0.5;\n    bool _414;\n    if (!_403)\n    {\n        _414 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _414 = _403;\n    }\n    float _415;\n    if (_414)\n    {\n        _415 = shape_half.x;\n    }\n    else\n    {\n        _415 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(_307, gl_FragCoord), _307.fa_time.x, base_mode, float4(0.0), _415 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_scene_color(thread const float2& uv, constant quad_fs_params& _307, texture2d<float> fa_scene_tex, sampler light_smp)\n{\n    if (_307.fa_scene.x <= 0.0)\n    {\n        return float4(0.0);\n    }\n    float2 _328 = (uv * _307.fa_scene.xy) + _307.fa_scene.zw;\n    float _330 = _328.y;\n    _328.y = mix(_330, 1.0 - _330, _307.fa_target.z);\n    return fa_scene_tex.sample(light_smp, fast::clamp(_328, float2(0.0), float2(1.0)), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, constant quad_fs_params& _307, texture2d<float> fa_scene_tex, sampler light_smp, constant fa_material& _432)\n{\n    float2 param = i.screen_uv + float2(_432.dx, _432.dy);\n    s.color = float4(mix(s.color.xyz, fa_scene_color(param, _307, fa_scene_tex, light_smp).xyz, float3(_432.amount)), s.color.w);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _307 [[buffer(1)]], constant fa_material& _432 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> normal_tex [[texture(1)]], texture2d<float> light_tex [[texture(2)]], texture2d<float> shadow_tex [[texture(3)]], texture2d<float> fa_scene_tex [[texture(4)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], sampler shadow_smp [[sampler(2)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float mode = in.params.x;\n    bool _1028 = in.params.x > 31.5;\n    if (_1028)\n    {\n        mode -= 32.0;\n    }\n    float _1036 = mode;\n    bool _1038 = _1036 > 15.5;\n    if (_1038)\n    {\n        mode -= 16.0;\n    }\n    float _1046 = mode;\n    bool _1048 = _1046 > 7.5;\n    if (_1048)\n    {\n        mode -= 8.0;\n    }\n    if (mode < 0.5)\n    {\n        float2 param = in.uv;\n        out.frag_color = tex_color(param, tex, smp, in.xform) * in.color;\n        if (_1038)\n        {\n            float4 param_1 = out.frag_color;\n            float param_2 = 5.0;\n            out.frag_color = float4(lit_color(param_1, param_2, shadow_tex, shadow_smp, smp, in.xform, _307, light_smp, gl_FragCoord, in.uv, in.world_xy, normal_tex, in.params, light_tex), out.frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5)\n        {\n            out.frag_color = shape_color(tex, smp, in.xform, gl_FragCoord, in.uv, in.color, in.shape_half, in.params, in.shape_rs, in.color2);\n            if (_1038)\n            {\n                float4 param_3 = out.frag_color;\n                float param_4 = 5.0;\n                out.frag_color = float4(lit_color(param_3, param_4, shadow_tex, shadow_smp, smp, in.xform, _307, light_smp, gl_FragCoord, in.uv, in.world_xy, normal_tex, in.params, light_tex), out.frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5)\n            {\n                float2 param_5 = in.uv;\n                float4 _1112 = tex_color(param_5, tex, smp, in.xform) * in.color;\n                float4 param_6 = _1112;\n                float param_7 = mode;\n                out.frag_color = float4(lit_color(param_6, param_7, shadow_tex, shadow_smp, smp, in.xform, _307, light_smp, gl_FragCoord, in.uv, in.world_xy, normal_tex, in.params, light_tex), _1112.w);\n            }\n            else\n            {\n                if (mode > 3.5)\n                {\n                    out.frag_color = float4(in.color.xyz, in.color.w * tex.sample(smp, in.uv).x);\n                }\n                else\n                {\n                    float _1147 = length(in.uv);\n                    float _1150 = fwidth(_1147);\n                    float _1151 = fast::max(_1150, 9.9999997473787516355514526367188e-05);\n                    float cov;\n                    if (mode < 1.5)\n                    {\n                        cov = fast::clamp(((1.0 - _1147) / _1151) + 0.5, 0.0, 1.0);\n                    }\n                    else\n                    {\n                        if (mode < 2.5)\n                        {\n                            cov = fast::clamp(((1.0 - _1147) / _1151) + 0.5, 0.0, 1.0) * fast::clamp(((_1147 - in.params.y) / _1151) + 0.5, 0.0, 1.0);\n                        }\n                        else\n                        {\n                            float _1191 = fast::clamp(1.0 - _1147, 0.0, 1.0);\n                            cov = (_1191 * _1191) * (3.0 - (2.0 * _1191));\n                        }\n                    }\n                    float3 _1200;\n                    if (_1038)\n                    {\n                        float4 param_8 = in.color;\n                        float param_9 = 5.0;\n                        _1200 = lit_color(param_8, param_9, shadow_tex, shadow_smp, smp, in.xform, _307, light_smp, gl_FragCoord, in.uv, in.world_xy, normal_tex, in.params, light_tex);\n                    }\n                    else\n                    {\n                        _1200 = in.color.xyz;\n                    }\n                    out.frag_color = float4(_1200, in.color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1538 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10, _307, gl_FragCoord, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_12 = QuadSurface{ _1538 };\n    fragment0(param_11, param_12, _307, fa_scene_tex, light_smp, _432);\n    _1538 = param_12.color;\n    out.frag_color = param_12.color;\n    if (_1028)\n    {\n        float4 _1238 = out.frag_color;\n        float3 param_13 = in.color2.xyz;\n        float3 _1243 = scene_rgb(param_13, in.xform);\n        float3 _1247 = mix(_1238.xyz, _1243, float3(in.color2.w));\n        out.frag_color.x = _1247.x;\n        out.frag_color.y = _1247.y;\n        out.frag_color.z = _1247.z;\n    }\n    if (_1048)\n    {\n        out.frag_color = float4(mix(float3(1.0), out.frag_color.xyz, float3(out.frag_color.w)), 1.0);\n    }\n    bool _1270 = _307.fog_col.w > 0.0;\n    bool _1278;\n    if (!_1270)\n    {\n        _1278 = _307.fog_b.y > 0.0;\n    }\n    else\n    {\n        _1278 = _1270;\n    }\n    if (_1278)\n    {\n        float3 _1292 = float3(in.world_xy, in.world_z) - _307.fog_eye.xyz;\n        float _1299 = dot(_1292, _307.fog_c.xyz);\n        bool _1303 = _307.fog_c.w > 0.5;\n        float _1304;\n        if (_1303)\n        {\n            _1304 = _1299;\n        }\n        else\n        {\n            _1304 = length(_1292);\n        }\n        float _1316 = _1304 - _307.fog_b.x;\n        if (_1316 > 0.0)\n        {\n            float _1325 = _307.fog_col.w * _1316;\n            float tau = _1325 * _1325;\n            if (_307.fog_b.y > 0.0)\n            {\n                float _1341;\n                if (_1303)\n                {\n                    _1341 = in.world_xy.y - (_307.fog_c.y * _1299);\n                }\n                else\n                {\n                    _1341 = _307.fog_eye.y;\n                }\n                float _1362 = mix(_1341, in.world_xy.y, fast::clamp(_307.fog_b.x / _1304, 0.0, 1.0));\n                float _1366 = in.world_xy.y - _1362;\n                float _1371 = _1362 - _307.fog_b.z;\n                float _1376 = in.world_xy.y - _307.fog_b.z;\n                bool _1379 = _1371 <= 0.0;\n                bool _1380 = !_1379;\n                bool _1386;\n                if (_1380)\n                {\n                    _1386 = _307.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1386 = _1379;\n                }\n                float _1387;\n                if (_1386)\n                {\n                    _1387 = _307.fog_b.y;\n                }\n                else\n                {\n                    _1387 = _307.fog_b.y * exp(-fast::min(_307.fog_b.w * _1371, 80.0));\n                }\n                bool _1414;\n                if (_1380)\n                {\n                    _1414 = _307.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1414 = _1379;\n                }\n                float _1415;\n                if (_1414)\n                {\n                    _1415 = _307.fog_b.y * _1371;\n                }\n                else\n                {\n                    _1415 = (_307.fog_b.y * (1.0 - exp(-fast::min(_307.fog_b.w * _1371, 80.0)))) / _307.fog_b.w;\n                }\n                bool _1440 = _1376 <= 0.0;\n                bool _1447;\n                if (!_1440)\n                {\n                    _1447 = _307.fog_b.w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1447 = _1440;\n                }\n                float _1448;\n                if (_1447)\n                {\n                    _1448 = _307.fog_b.y * _1376;\n                }\n                else\n                {\n                    _1448 = (_307.fog_b.y * (1.0 - exp(-fast::min(_307.fog_b.w * _1376, 80.0)))) / _307.fog_b.w;\n                }\n                float _1475;\n                if (abs(_1366) < 0.001000000047497451305389404296875)\n                {\n                    _1475 = _1387;\n                }\n                else\n                {\n                    _1475 = (_1448 - _1415) / _1366;\n                }\n                tau += (_1316 * fast::max(_1475, 0.0));\n            }\n            float4 _1498 = out.frag_color;\n            float3 _1506 = mix(_1498.xyz, _307.fog_col.xyz, float3(fast::clamp(1.0 - exp(-fast::clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n            out.frag_color.x = _1506.x;\n            out.frag_color.y = _1506.y;\n            out.frag_color.z = _1506.z;\n        }\n    }\n    return out;\n}\n\n",
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
            "inst_name": "_307",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 48,
            "struct_name": "fa_material",
            "inst_name": "_432",
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
              "name": "fa_scene_tex",
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
            "name": "fa_scene_tex_light_smp",
            "view_name": "fa_scene_tex",
            "sampler_name": "light_smp",
            "view_slot": 12,
            "sampler_slot": 1
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct vs_params\n{\n    float4x4 view_proj;\n    float4 cspace;\n    float4 fa_time;\n};\n\nstruct main0_out\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 params [[user(locn2)]];\n    float2 world_xy [[user(locn3)]];\n    float4 color2 [[user(locn4)]];\n    float2 shape_half [[user(locn5)]];\n    float2 shape_rs [[user(locn6)]];\n    float3 xform [[user(locn7)]];\n    float world_z [[user(locn8)]];\n    float4 gl_Position [[position]];\n};\n\nstruct main0_in\n{\n    float3 position [[attribute(0)]];\n    float2 texcoord0 [[attribute(1)]];\n    float4 color0 [[attribute(2)]];\n    float2 params0 [[attribute(3)]];\n    float4 color2_0 [[attribute(4)]];\n    float2 shape_half0 [[attribute(5)]];\n    float2 shape_rs0 [[attribute(6)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nvertex main0_out main0(main0_in in [[stage_in]], constant vs_params& _68 [[buffer(0)]])\n{\n    main0_out out = {};\n    float4 _147 = in.color0;\n    if (_68.cspace.x > 0.5)\n    {\n        float3 param = in.color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    out.gl_Position = _68.view_proj * float4(in.position, 1.0);\n    out.uv = in.texcoord0;\n    out.color = _147;\n    out.xform = _68.cspace.xyz;\n    out.params = in.params0;\n    out.world_xy = in.position.xy;\n    out.world_z = in.position.z;\n    out.color2 = in.color2_0;\n    out.shape_half = in.shape_half0;\n    out.shape_rs = in.shape_rs0;\n    return out;\n}\n\n",
      "fs": "#pragma clang diagnostic ignored \"-Wmissing-prototypes\"\n\n#include <metal_stdlib>\n#include <simd/simd.h>\n\nusing namespace metal;\n\nstruct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct quad_fs_params\n{\n    float4 lit;\n    float4 ambient;\n    float4 normal_uv;\n    float4 flat_ambient;\n    float4 light_map;\n    float4 light_pos[16];\n    float4 light_color[16];\n    float4 light_shadow_v[16];\n    float4 fog_col;\n    float4 fog_b;\n    float4 fog_c;\n    float4 fog_eye;\n    float4 fa_time;\n    float4 fa_target;\n    float4 fa_scene;\n    float4 fa_world_uv[3];\n};\n\nstruct fa_material\n{\n    float amount;\n    float fa_pad0;\n    float fa_pad1;\n    float fa_pad2;\n    float dx;\n    float fa_pad3;\n    float fa_pad4;\n    float fa_pad5;\n    float dy;\n    float fa_pad6;\n    float fa_pad7;\n    float fa_pad8;\n};\n\nstruct main0_out\n{\n    float4 frag_color [[color(0)]];\n};\n\nstruct main0_in\n{\n    float2 uv [[user(locn0)]];\n    float4 color [[user(locn1)]];\n    float2 world_xy [[user(locn3)]];\n    float2 shape_half [[user(locn5)]];\n    float3 xform [[user(locn7)]];\n};\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_linear_to_srgb(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix((powr(c, float3(0.4166666567325592041015625)) * 1.05499994754791259765625) - float3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, float3(0.003130800090730190277099609375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_srgb_to_linear(thread float3& c)\n{\n    c = fast::max(c, float3(0.0));\n    return mix(powr((c + float3(0.054999999701976776123046875)) * float3(0.947867333889007568359375), float3(2.400000095367431640625)), c * float3(0.077399380505084991455078125), step(c, float3(0.040449999272823333740234375)));\n}\n\nstatic inline __attribute__((always_inline))\nfloat3 fa_tex_fix(thread float3& c, thread const float& mode)\n{\n    if (mode > 1.5)\n    {\n        float3 param = c;\n        float3 _106 = fa_linear_to_srgb(param);\n        c = _106;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            float3 param_1 = c;\n            float3 _115 = fa_srgb_to_linear(param_1);\n            c = _115;\n        }\n    }\n    return c;\n}\n\nstatic inline __attribute__((always_inline))\nfloat2 fa_screen_uv(constant quad_fs_params& _128, thread float4& gl_FragCoord)\n{\n    float2 _189 = gl_FragCoord.xy * _128.fa_target.xy;\n    float _193 = _189.y;\n    return float2(_189.x, mix(_193, 1.0 - _193, _128.fa_target.z));\n}\n\nstatic inline __attribute__((always_inline))\nQuadInput fa_quad_input(thread const float& base_mode, constant quad_fs_params& _128, thread float4& gl_FragCoord, thread float2& uv, thread float4& color, thread float2& world_xy, thread float2& shape_half)\n{\n    bool _233 = base_mode < 0.5;\n    bool _244;\n    if (!_233)\n    {\n        _244 = (base_mode > 2.5) && (base_mode < 3.5);\n    }\n    else\n    {\n        _244 = _233;\n    }\n    float _245;\n    if (_244)\n    {\n        _245 = shape_half.x;\n    }\n    else\n    {\n        _245 = 0.0;\n    }\n    return QuadInput{ uv, color, world_xy, fa_screen_uv(_128, gl_FragCoord), _128.fa_time.x, base_mode, float4(0.0), _245 };\n}\n\nstatic inline __attribute__((always_inline))\nvoid fa_inst_load()\n{\n}\n\nstatic inline __attribute__((always_inline))\nfloat4 fa_scene_color(thread const float2& uv, constant quad_fs_params& _128, texture2d<float> fa_scene_tex, sampler light_smp)\n{\n    if (_128.fa_scene.x <= 0.0)\n    {\n        return float4(0.0);\n    }\n    float2 _150 = (uv * _128.fa_scene.xy) + _128.fa_scene.zw;\n    float _153 = _150.y;\n    _150.y = mix(_153, 1.0 - _153, _128.fa_target.z);\n    return fa_scene_tex.sample(light_smp, fast::clamp(_150, float2(0.0), float2(1.0)), level(0.0));\n}\n\nstatic inline __attribute__((always_inline))\nvoid fragment0(thread const QuadInput& i, thread QuadSurface& s, constant quad_fs_params& _128, texture2d<float> fa_scene_tex, sampler light_smp, constant fa_material& _263)\n{\n    float2 param = i.screen_uv + float2(_263.dx, _263.dy);\n    s.color = float4(mix(s.color.xyz, fa_scene_color(param, _128, fa_scene_tex, light_smp).xyz, float3(_263.amount)), s.color.w);\n}\n\nfragment main0_out main0(main0_in in [[stage_in]], constant quad_fs_params& _128 [[buffer(1)]], constant fa_material& _263 [[buffer(5)]], texture2d<float> tex [[texture(0)]], texture2d<float> fa_scene_tex [[texture(1)]], sampler smp [[sampler(0)]], sampler light_smp [[sampler(1)]], float4 gl_FragCoord [[position]])\n{\n    main0_out out = {};\n    float4 _296 = tex.sample(smp, in.uv);\n    float3 param = _296.xyz;\n    float param_1 = in.xform.y;\n    float3 _307 = fa_tex_fix(param, param_1);\n    out.frag_color = float4(_307, _296.w) * in.color;\n    float param_2 = 0.0;\n    float4 _360 = out.frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2, _128, gl_FragCoord, in.uv, in.color, in.world_xy, in.shape_half);\n    QuadSurface param_4 = QuadSurface{ _360 };\n    fragment0(param_3, param_4, _128, fa_scene_tex, light_smp, _263);\n    _360 = param_4.color;\n    out.frag_color = param_4.color;\n    return out;\n}\n\n",
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
            "inst_name": "_128",
            "msl_buffer_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 48,
            "struct_name": "fa_material",
            "inst_name": "_263",
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
              "slot": 12,
              "stage": "fragment",
              "name": "fa_scene_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "msl_texture_n": 1
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "light_smp",
            "sampler_type": "filtering",
            "msl_sampler_n": 1
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
            "name": "fa_scene_tex_light_smp",
            "view_name": "fa_scene_tex",
            "sampler_name": "light_smp",
            "view_slot": 12,
            "sampler_slot": 1
          }
        ]
      }
    }
  }
}
