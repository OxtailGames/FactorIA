{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "92b6737b88986088c23ec149effb731593899af4f139a1a2f6aa207cd28c4169",
  "slang": "hlsl5",
  "params": [
    "amount",
    "dx",
    "dy"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _147 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _147;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _307_lit : packoffset(c0);\n    float4 _307_ambient : packoffset(c1);\n    float4 _307_normal_uv : packoffset(c2);\n    float4 _307_flat_ambient : packoffset(c3);\n    float4 _307_light_map : packoffset(c4);\n    float4 _307_light_pos[16] : packoffset(c5);\n    float4 _307_light_color[16] : packoffset(c21);\n    float4 _307_light_shadow_v[16] : packoffset(c37);\n    float4 _307_fog_col : packoffset(c53);\n    float4 _307_fog_b : packoffset(c54);\n    float4 _307_fog_c : packoffset(c55);\n    float4 _307_fog_eye : packoffset(c56);\n    float4 _307_fa_time : packoffset(c57);\n    float4 _307_fa_target : packoffset(c58);\n    float4 _307_fa_scene : packoffset(c59);\n    float4 _307_fa_world_uv[3] : packoffset(c60);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _432_amount : packoffset(c0);\n    float _432_fa_pad0 : packoffset(c0.y);\n    float _432_fa_pad1 : packoffset(c0.z);\n    float _432_fa_pad2 : packoffset(c0.w);\n    float _432_dx : packoffset(c1);\n    float _432_fa_pad3 : packoffset(c1.y);\n    float _432_fa_pad4 : packoffset(c1.z);\n    float _432_fa_pad5 : packoffset(c1.w);\n    float _432_dy : packoffset(c2);\n    float _432_fa_pad6 : packoffset(c2.y);\n    float _432_fa_pad7 : packoffset(c2.z);\n    float _432_fa_pad8 : packoffset(c2.w);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> fa_scene_tex : register(t4);\nSamplerState light_smp : register(s1);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _250 = fa_linear_to_srgb(param);\n        c = _250;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _258 = fa_srgb_to_linear(param_1);\n            c = _258;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _269 = tex.Sample(smp, p);\n    float3 param = _269.xyz;\n    float param_1 = xform.y;\n    float3 _279 = fa_tex_fix(param, param_1);\n    return float4(_279, _269.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _92 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_92.x * 255.0f) + 0.5f) * 256.0f) + floor((_92.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _116 = length(d);\n    if (_116 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _130 = atan2(d.y, d.x);\n    float a = _130;\n    float _133;\n    if (_130 < 0.0f)\n    {\n        _133 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _133 = a;\n    }\n    a = _133;\n    float _145 = _133 * 162.9746551513671875f;\n    float _150 = min(floor(_145), 1023.0f);\n    float _157 = _150 + 1.0f;\n    float i1 = _157;\n    if (_157 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _150;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _116) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _116) + 0.5f, 0.0f, 1.0f), _145 - _150);\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _464 = _307_lit.y > 0.5f;\n    if (_464)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _307_normal_uv.xy) + _307_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _488 = fa_tex_fix(param, param_1);\n        float3 _492 = (_488 * 2.0f) - 1.0f.xxx;\n        float _499 = cos(params.y);\n        float _501 = sin(params.y);\n        n = normalize(float3((float2(_499, _501) * _492.x) + ((float2(-_501, _499) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _492.y), max(_492.z, 0.0500000007450580596923828125f)));\n    }\n    bool _535 = !_464;\n    bool _541;\n    if (_535)\n    {\n        _541 = _307_lit.z > 0.5f;\n    }\n    else\n    {\n        _541 = _535;\n    }\n    float3 _544;\n    if (_541)\n    {\n        _544 = _307_flat_ambient.xyz;\n    }\n    else\n    {\n        _544 = _307_ambient.xyz;\n    }\n    float3 total = _544;\n    bool _561;\n    if (_541)\n    {\n        _561 = _307_lit.z < 1.5f;\n    }\n    else\n    {\n        _561 = _541;\n    }\n    if (_561)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _307_light_map.xy, 0.0f).xyz * _307_light_map.z);\n    }\n    float3 l;\n    float _678;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _600;\n        if (!_541)\n        {\n            _600 = float(i) >= _307_lit.x;\n        }\n        else\n        {\n            _600 = _541;\n        }\n        if (_600)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_307_light_pos[i].w < 0.0f)\n        {\n            l = _307_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _626 = _307_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_626) / max(_307_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _307_light_color[i].w);\n            float3 _646 = float3(_626, _307_light_pos[i].z);\n            l = _646 / max(length(_646), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_307_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _307_light_shadow_v[i].x;\n                float2 param_3 = -_626;\n                float param_4 = _307_light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_464)\n        {\n            _678 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _678 = 1.0f;\n        }\n        total += (_307_light_color[i].xyz * (att * _678));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _296 = fa_srgb_to_linear(param);\n        c = _296;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _706 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _710 = uv * _706;\n    float _716 = _706.x;\n    float _718 = _706.y;\n    float _720 = clamp(shape_rs.x, 0.0f, min(_716, _718));\n    float2 _731 = (abs(_710) - _706) + _720.xx;\n    float d = (length(max(_731, 0.0f.xx)) + min(max(_731.x, _731.y), 0.0f)) - _720;\n    float ax = params.y;\n    bool _752 = params.y > 15.0f;\n    if (_752)\n    {\n        ax -= 20.0f;\n    }\n    float _763;\n    if (ax <= (-1.5f))\n    {\n        _763 = (-2.0f) - ax;\n    }\n    else\n    {\n        _763 = 0.0f;\n    }\n    if (_763 > 0.0f)\n    {\n        float _777 = _763 * 0.5f;\n        d = abs(d + _777) - _777;\n    }\n    float _785 = fwidth(d);\n    float _786 = max(_785, 9.9999997473787516355514526367188e-05f);\n    float _796 = clamp(0.5f - (d / max(shape_rs.y, _786)), 0.0f, 1.0f);\n    float _801;\n    if (shape_rs.y > _786)\n    {\n        _801 = (_796 * _796) * (3.0f - (2.0f * _796));\n    }\n    else\n    {\n        _801 = _796;\n    }\n    float4 c = color;\n    bool _823 = (_763 <= 0.0f) && (ax > (-0.5f));\n    if (_823)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _838 = cos(ax);\n            float _840 = sin(ax);\n            g = ((dot(_710, float2(_838, _840)) / max((abs(_838) * _716) + (abs(_840) * _718), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_752)\n        {\n            float4 _883 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _883;\n            float3 param = _883.xyz;\n            float param_1 = xform.y;\n            float3 _890 = fa_tex_fix(param, param_1);\n            float4 _1589 = c;\n            _1589.x = _890.x;\n            _1589.y = _890.y;\n            _1589.z = _890.z;\n            c = _1589;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _902 = scene_rgb(param_2);\n            float4 _927 = lerp(float4(color.xyz * color.w, color.w), float4(_902 * color2.w, color2.w), g.xxxx);\n            float _929 = _927.w;\n            float3 _932;\n            if (_929 > 9.9999997473787516355514526367188e-06f)\n            {\n                _932 = _927.xyz / _929.xxx;\n            }\n            else\n            {\n                _932 = color.xyz;\n            }\n            c = float4(_932, _929);\n        }\n    }\n    float4 _1598 = c;\n    _1598.w = _1598.w * _801;\n    c = _1598;\n    if (_823 || (shape_rs.y > 0.0f))\n    {\n        float _973 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _982 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _982 + (_973 * 0.0039215688593685626983642578125f).xxx;\n            float3 _988 = fa_srgb_to_linear(param_4);\n            float4 _1601 = c;\n            _1601.x = _988.x;\n            _1601.y = _988.y;\n            _1601.z = _988.z;\n            c = _1601;\n        }\n        else\n        {\n            float4 _998 = c;\n            float3 _1001 = _998.xyz + (_973 * 0.0039215688593685626983642578125f).xxx;\n            float4 _1608 = _998;\n            _1608.x = _1001.x;\n            _1608.y = _1001.y;\n            _1608.z = _1001.z;\n            c = _1608;\n        }\n        float4 _1613 = c;\n        _1613.w = clamp(_1613.w + ((_973 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _1613.w)), 0.0f, 1.0f);\n        c = _1613;\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _360 = gl_FragCoord.xy * _307_fa_target.xy;\n    float _364 = _360.y;\n    return float2(_360.x, lerp(_364, 1.0f - _364, _307_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _403 = base_mode < 0.5f;\n    bool _414;\n    if (!_403)\n    {\n        _414 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _414 = _403;\n    }\n    float _415;\n    if (_414)\n    {\n        _415 = shape_half.x;\n    }\n    else\n    {\n        _415 = 0.0f;\n    }\n    QuadInput _1558 = { uv, color, world_xy, fa_screen_uv(), _307_fa_time.x, base_mode, 0.0f.xxxx, _415 };\n    return _1558;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_scene_color(float2 uv_1)\n{\n    if (_307_fa_scene.x <= 0.0f)\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _328 = (uv_1 * _307_fa_scene.xy) + _307_fa_scene.zw;\n    float _330 = _328.y;\n    _328.y = lerp(_330, 1.0f - _330, _307_fa_target.z);\n    return fa_scene_tex.SampleLevel(light_smp, clamp(_328, 0.0f.xx, 1.0f.xx), 0.0f);\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float2 param = i.screen_uv + float2(_432_dx, _432_dy);\n    s.color = float4(lerp(s.color.xyz, fa_scene_color(param).xyz, _432_amount.xxx), s.color.w);\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1028 = params.x > 31.5f;\n    if (_1028)\n    {\n        mode -= 32.0f;\n    }\n    float _1036 = mode;\n    bool _1038 = _1036 > 15.5f;\n    if (_1038)\n    {\n        mode -= 16.0f;\n    }\n    float _1046 = mode;\n    bool _1048 = _1046 > 7.5f;\n    if (_1048)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1038)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1038)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1112 = tex_color(param_5) * color;\n                float4 param_6 = _1112;\n                float param_7 = mode;\n                frag_color = float4(lit_color(param_6, param_7), _1112.w);\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1147 = length(uv);\n                    float _1150 = fwidth(_1147);\n                    float _1151 = max(_1150, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1147) / _1151) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1147) / _1151) + 0.5f, 0.0f, 1.0f) * clamp(((_1147 - params.y) / _1151) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1191 = clamp(1.0f - _1147, 0.0f, 1.0f);\n                            cov = (_1191 * _1191) * (3.0f - (2.0f * _1191));\n                        }\n                    }\n                    float3 _1200;\n                    if (_1038)\n                    {\n                        float4 param_8 = color;\n                        float param_9 = 5.0f;\n                        _1200 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1200 = color.xyz;\n                    }\n                    frag_color = float4(_1200, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1538 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface _1540 = { _1538 };\n    QuadSurface param_12 = _1540;\n    fragment(param_11, param_12);\n    _1538 = param_12.color;\n    frag_color = param_12.color;\n    if (_1028)\n    {\n        float4 _1238 = frag_color;\n        float3 param_13 = color2.xyz;\n        float3 _1243 = scene_rgb(param_13);\n        float3 _1247 = lerp(_1238.xyz, _1243, color2.w.xxx);\n        frag_color.x = _1247.x;\n        frag_color.y = _1247.y;\n        frag_color.z = _1247.z;\n    }\n    if (_1048)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1270 = _307_fog_col.w > 0.0f;\n    bool _1278;\n    if (!_1270)\n    {\n        _1278 = _307_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1278 = _1270;\n    }\n    if (_1278)\n    {\n        float3 _1292 = float3(world_xy, world_z) - _307_fog_eye.xyz;\n        float _1299 = dot(_1292, _307_fog_c.xyz);\n        bool _1303 = _307_fog_c.w > 0.5f;\n        float _1304;\n        if (_1303)\n        {\n            _1304 = _1299;\n        }\n        else\n        {\n            _1304 = length(_1292);\n        }\n        float _1316 = _1304 - _307_fog_b.x;\n        if (_1316 > 0.0f)\n        {\n            float _1325 = _307_fog_col.w * _1316;\n            float tau = _1325 * _1325;\n            if (_307_fog_b.y > 0.0f)\n            {\n                float _1341;\n                if (_1303)\n                {\n                    _1341 = world_xy.y - (_307_fog_c.y * _1299);\n                }\n                else\n                {\n                    _1341 = _307_fog_eye.y;\n                }\n                float _1362 = lerp(_1341, world_xy.y, clamp(_307_fog_b.x / _1304, 0.0f, 1.0f));\n                float _1366 = world_xy.y - _1362;\n                float _1371 = _1362 - _307_fog_b.z;\n                float _1376 = world_xy.y - _307_fog_b.z;\n                bool _1379 = _1371 <= 0.0f;\n                bool _1380 = !_1379;\n                bool _1386;\n                if (_1380)\n                {\n                    _1386 = _307_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1386 = _1379;\n                }\n                float _1387;\n                if (_1386)\n                {\n                    _1387 = _307_fog_b.y;\n                }\n                else\n                {\n                    _1387 = _307_fog_b.y * exp(-min(_307_fog_b.w * _1371, 80.0f));\n                }\n                bool _1414;\n                if (_1380)\n                {\n                    _1414 = _307_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1414 = _1379;\n                }\n                float _1415;\n                if (_1414)\n                {\n                    _1415 = _307_fog_b.y * _1371;\n                }\n                else\n                {\n                    _1415 = (_307_fog_b.y * (1.0f - exp(-min(_307_fog_b.w * _1371, 80.0f)))) / _307_fog_b.w;\n                }\n                bool _1440 = _1376 <= 0.0f;\n                bool _1447;\n                if (!_1440)\n                {\n                    _1447 = _307_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1447 = _1440;\n                }\n                float _1448;\n                if (_1447)\n                {\n                    _1448 = _307_fog_b.y * _1376;\n                }\n                else\n                {\n                    _1448 = (_307_fog_b.y * (1.0f - exp(-min(_307_fog_b.w * _1376, 80.0f)))) / _307_fog_b.w;\n                }\n                float _1475;\n                if (abs(_1366) < 0.001000000047497451305389404296875f)\n                {\n                    _1475 = _1387;\n                }\n                else\n                {\n                    _1475 = (_1448 - _1415) / _1366;\n                }\n                tau += (_1316 * max(_1475, 0.0f));\n            }\n            float4 _1498 = frag_color;\n            float3 _1506 = lerp(_1498.xyz, _307_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _1506.x;\n            frag_color.y = _1506.y;\n            frag_color.z = _1506.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main",
          "d3d11_target": "vs_5_0"
        },
        "fragment_func": {
          "entry_point": "main",
          "d3d11_target": "ps_5_0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 0
          },
          {
            "slot": 1,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 2
          },
          {
            "slot": 3,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 3
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 4
          },
          {
            "slot": 5,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 5
          },
          {
            "slot": 6,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 6
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_68",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 1008,
            "struct_name": "quad_fs_params",
            "inst_name": "_307",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 48,
            "struct_name": "fa_material",
            "inst_name": "_432",
            "hlsl_register_b_n": 5
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
              "hlsl_register_t_n": 0
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
              "hlsl_register_t_n": 1
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
              "hlsl_register_t_n": 2
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
              "hlsl_register_t_n": 3
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
              "hlsl_register_t_n": 4
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "shadow_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "light_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 1
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
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _147 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _147;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _128_lit : packoffset(c0);\n    float4 _128_ambient : packoffset(c1);\n    float4 _128_normal_uv : packoffset(c2);\n    float4 _128_flat_ambient : packoffset(c3);\n    float4 _128_light_map : packoffset(c4);\n    float4 _128_light_pos[16] : packoffset(c5);\n    float4 _128_light_color[16] : packoffset(c21);\n    float4 _128_light_shadow_v[16] : packoffset(c37);\n    float4 _128_fog_col : packoffset(c53);\n    float4 _128_fog_b : packoffset(c54);\n    float4 _128_fog_c : packoffset(c55);\n    float4 _128_fog_eye : packoffset(c56);\n    float4 _128_fa_time : packoffset(c57);\n    float4 _128_fa_target : packoffset(c58);\n    float4 _128_fa_scene : packoffset(c59);\n    float4 _128_fa_world_uv[3] : packoffset(c60);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _263_amount : packoffset(c0);\n    float _263_fa_pad0 : packoffset(c0.y);\n    float _263_fa_pad1 : packoffset(c0.z);\n    float _263_fa_pad2 : packoffset(c0.w);\n    float _263_dx : packoffset(c1);\n    float _263_fa_pad3 : packoffset(c1.y);\n    float _263_fa_pad4 : packoffset(c1.z);\n    float _263_fa_pad5 : packoffset(c1.w);\n    float _263_dy : packoffset(c2);\n    float _263_fa_pad6 : packoffset(c2.y);\n    float _263_fa_pad7 : packoffset(c2.z);\n    float _263_fa_pad8 : packoffset(c2.w);\n};\n\nTexture2D<float4> fa_scene_tex : register(t1);\nSamplerState light_smp : register(s1);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 frag_color;\nstatic float3 xform;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _106 = fa_linear_to_srgb(param);\n        c = _106;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _115 = fa_srgb_to_linear(param_1);\n            c = _115;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _189 = gl_FragCoord.xy * _128_fa_target.xy;\n    float _193 = _189.y;\n    return float2(_189.x, lerp(_193, 1.0f - _193, _128_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _233 = base_mode < 0.5f;\n    bool _244;\n    if (!_233)\n    {\n        _244 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _244 = _233;\n    }\n    float _245;\n    if (_244)\n    {\n        _245 = shape_half.x;\n    }\n    else\n    {\n        _245 = 0.0f;\n    }\n    QuadInput _380 = { uv, color, world_xy, fa_screen_uv(), _128_fa_time.x, base_mode, 0.0f.xxxx, _245 };\n    return _380;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_scene_color(float2 uv_1)\n{\n    if (_128_fa_scene.x <= 0.0f)\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _150 = (uv_1 * _128_fa_scene.xy) + _128_fa_scene.zw;\n    float _153 = _150.y;\n    _150.y = lerp(_153, 1.0f - _153, _128_fa_target.z);\n    return fa_scene_tex.SampleLevel(light_smp, clamp(_150, 0.0f.xx, 1.0f.xx), 0.0f);\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float2 param = i.screen_uv + float2(_263_dx, _263_dy);\n    s.color = float4(lerp(s.color.xyz, fa_scene_color(param).xyz, _263_amount.xxx), s.color.w);\n}\n\nvoid frag_main()\n{\n    float4 _296 = tex.Sample(smp, uv);\n    float3 param = _296.xyz;\n    float param_1 = xform.y;\n    float3 _307 = fa_tex_fix(param, param_1);\n    frag_color = float4(_307, _296.w) * color;\n    float param_2 = 0.0f;\n    float4 _360 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _362 = { _360 };\n    QuadSurface param_4 = _362;\n    fragment(param_3, param_4);\n    _360 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    xform = stage_input.xform;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main",
          "d3d11_target": "vs_5_0"
        },
        "fragment_func": {
          "entry_point": "main",
          "d3d11_target": "ps_5_0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 0
          },
          {
            "slot": 1,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 2
          },
          {
            "slot": 3,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 3
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 4
          },
          {
            "slot": 5,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 5
          },
          {
            "slot": 6,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 6
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_68",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 1008,
            "struct_name": "quad_fs_params",
            "inst_name": "_128",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 48,
            "struct_name": "fa_material",
            "inst_name": "_263",
            "hlsl_register_b_n": 5
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
              "hlsl_register_t_n": 0
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
              "hlsl_register_t_n": 1
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "light_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 1
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
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
