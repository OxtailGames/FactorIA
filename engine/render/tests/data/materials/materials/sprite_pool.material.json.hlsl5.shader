{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "92b6737b88986088c23ec149effb731593899af4f139a1a2f6aa207cd28c4169",
  "slang": "hlsl5",
  "params": [
    "reflection",
    "refraction",
    "size",
    "strength",
    "tint",
    "waveAmplitude",
    "waveLength",
    "waveSpeed"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _147 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _147;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _307_lit : packoffset(c0);\n    float4 _307_ambient : packoffset(c1);\n    float4 _307_normal_uv : packoffset(c2);\n    float4 _307_flat_ambient : packoffset(c3);\n    float4 _307_light_map : packoffset(c4);\n    float4 _307_light_pos[16] : packoffset(c5);\n    float4 _307_light_color[16] : packoffset(c21);\n    float4 _307_light_shadow_v[16] : packoffset(c37);\n    float4 _307_fog_col : packoffset(c53);\n    float4 _307_fog_b : packoffset(c54);\n    float4 _307_fog_c : packoffset(c55);\n    float4 _307_fog_eye : packoffset(c56);\n    float4 _307_fa_time : packoffset(c57);\n    float4 _307_fa_target : packoffset(c58);\n    float4 _307_fa_scene : packoffset(c59);\n    float4 _307_fa_world_uv[3] : packoffset(c60);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _430_reflection : packoffset(c0);\n    float _430_fa_pad0 : packoffset(c0.y);\n    float _430_fa_pad1 : packoffset(c0.z);\n    float _430_fa_pad2 : packoffset(c0.w);\n    float _430_refraction : packoffset(c1);\n    float _430_fa_pad3 : packoffset(c1.y);\n    float _430_fa_pad4 : packoffset(c1.z);\n    float _430_fa_pad5 : packoffset(c1.w);\n    float2 _430_size : packoffset(c2);\n    float _430_fa_pad6 : packoffset(c2.z);\n    float _430_fa_pad7 : packoffset(c2.w);\n    float _430_strength : packoffset(c3);\n    float _430_fa_pad8 : packoffset(c3.y);\n    float _430_fa_pad9 : packoffset(c3.z);\n    float _430_fa_pad10 : packoffset(c3.w);\n    float4 _430_tint : packoffset(c4);\n    float _430_waveAmplitude : packoffset(c5);\n    float _430_fa_pad11 : packoffset(c5.y);\n    float _430_fa_pad12 : packoffset(c5.z);\n    float _430_fa_pad13 : packoffset(c5.w);\n    float _430_waveLength : packoffset(c6);\n    float _430_fa_pad14 : packoffset(c6.y);\n    float _430_fa_pad15 : packoffset(c6.z);\n    float _430_fa_pad16 : packoffset(c6.w);\n    float _430_waveSpeed : packoffset(c7);\n    float _430_fa_pad17 : packoffset(c7.y);\n    float _430_fa_pad18 : packoffset(c7.z);\n    float _430_fa_pad19 : packoffset(c7.w);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> fa_scene_tex : register(t4);\nSamplerState light_smp : register(s1);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _250 = fa_linear_to_srgb(param);\n        c = _250;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _258 = fa_srgb_to_linear(param_1);\n            c = _258;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _269 = tex.Sample(smp, p);\n    float3 param = _269.xyz;\n    float param_1 = xform.y;\n    float3 _279 = fa_tex_fix(param, param_1);\n    return float4(_279, _269.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _92 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_92.x * 255.0f) + 0.5f) * 256.0f) + floor((_92.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _116 = length(d);\n    if (_116 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _130 = atan2(d.y, d.x);\n    float a = _130;\n    float _133;\n    if (_130 < 0.0f)\n    {\n        _133 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _133 = a;\n    }\n    a = _133;\n    float _145 = _133 * 162.9746551513671875f;\n    float _150 = min(floor(_145), 1023.0f);\n    float _157 = _150 + 1.0f;\n    float i1 = _157;\n    if (_157 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _150;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _116) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _116) + 0.5f, 0.0f, 1.0f), _145 - _150);\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _497 = _307_lit.y > 0.5f;\n    if (_497)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _307_normal_uv.xy) + _307_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _521 = fa_tex_fix(param, param_1);\n        float3 _525 = (_521 * 2.0f) - 1.0f.xxx;\n        float _532 = cos(params.y);\n        float _534 = sin(params.y);\n        n = normalize(float3((float2(_532, _534) * _525.x) + ((float2(-_534, _532) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _525.y), max(_525.z, 0.0500000007450580596923828125f)));\n    }\n    bool _568 = !_497;\n    bool _574;\n    if (_568)\n    {\n        _574 = _307_lit.z > 0.5f;\n    }\n    else\n    {\n        _574 = _568;\n    }\n    float3 _577;\n    if (_574)\n    {\n        _577 = _307_flat_ambient.xyz;\n    }\n    else\n    {\n        _577 = _307_ambient.xyz;\n    }\n    float3 total = _577;\n    bool _594;\n    if (_574)\n    {\n        _594 = _307_lit.z < 1.5f;\n    }\n    else\n    {\n        _594 = _574;\n    }\n    if (_594)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _307_light_map.xy, 0.0f).xyz * _307_light_map.z);\n    }\n    float3 l;\n    float _710;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _632;\n        if (!_574)\n        {\n            _632 = float(i) >= _307_lit.x;\n        }\n        else\n        {\n            _632 = _574;\n        }\n        if (_632)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_307_light_pos[i].w < 0.0f)\n        {\n            l = _307_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _658 = _307_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_658) / max(_307_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _307_light_color[i].w);\n            float3 _678 = float3(_658, _307_light_pos[i].z);\n            l = _678 / max(length(_678), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_307_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _307_light_shadow_v[i].x;\n                float2 param_3 = -_658;\n                float param_4 = _307_light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_497)\n        {\n            _710 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _710 = 1.0f;\n        }\n        total += (_307_light_color[i].xyz * (att * _710));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _296 = fa_srgb_to_linear(param);\n        c = _296;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _738 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _742 = uv * _738;\n    float _748 = _738.x;\n    float _750 = _738.y;\n    float _752 = clamp(shape_rs.x, 0.0f, min(_748, _750));\n    float2 _763 = (abs(_742) - _738) + _752.xx;\n    float d = (length(max(_763, 0.0f.xx)) + min(max(_763.x, _763.y), 0.0f)) - _752;\n    float ax = params.y;\n    bool _784 = params.y > 15.0f;\n    if (_784)\n    {\n        ax -= 20.0f;\n    }\n    float _795;\n    if (ax <= (-1.5f))\n    {\n        _795 = (-2.0f) - ax;\n    }\n    else\n    {\n        _795 = 0.0f;\n    }\n    if (_795 > 0.0f)\n    {\n        float _809 = _795 * 0.5f;\n        d = abs(d + _809) - _809;\n    }\n    float _817 = fwidth(d);\n    float _818 = max(_817, 9.9999997473787516355514526367188e-05f);\n    float _828 = clamp(0.5f - (d / max(shape_rs.y, _818)), 0.0f, 1.0f);\n    float _833;\n    if (shape_rs.y > _818)\n    {\n        _833 = (_828 * _828) * (3.0f - (2.0f * _828));\n    }\n    else\n    {\n        _833 = _828;\n    }\n    float4 c = color;\n    bool _855 = (_795 <= 0.0f) && (ax > (-0.5f));\n    if (_855)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _870 = cos(ax);\n            float _872 = sin(ax);\n            g = ((dot(_742, float2(_870, _872)) / max((abs(_870) * _748) + (abs(_872) * _750), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_784)\n        {\n            float4 _915 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _915;\n            float3 param = _915.xyz;\n            float param_1 = xform.y;\n            float3 _922 = fa_tex_fix(param, param_1);\n            float4 _1620 = c;\n            _1620.x = _922.x;\n            _1620.y = _922.y;\n            _1620.z = _922.z;\n            c = _1620;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _934 = scene_rgb(param_2);\n            float4 _959 = lerp(float4(color.xyz * color.w, color.w), float4(_934 * color2.w, color2.w), g.xxxx);\n            float _961 = _959.w;\n            float3 _964;\n            if (_961 > 9.9999997473787516355514526367188e-06f)\n            {\n                _964 = _959.xyz / _961.xxx;\n            }\n            else\n            {\n                _964 = color.xyz;\n            }\n            c = float4(_964, _961);\n        }\n    }\n    float4 _1629 = c;\n    _1629.w = _1629.w * _833;\n    c = _1629;\n    if (_855 || (shape_rs.y > 0.0f))\n    {\n        float _1005 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1014 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1014 + (_1005 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1020 = fa_srgb_to_linear(param_4);\n            float4 _1632 = c;\n            _1632.x = _1020.x;\n            _1632.y = _1020.y;\n            _1632.z = _1020.z;\n            c = _1632;\n        }\n        else\n        {\n            float4 _1030 = c;\n            float3 _1033 = _1030.xyz + (_1005 * 0.0039215688593685626983642578125f).xxx;\n            float4 _1639 = _1030;\n            _1639.x = _1033.x;\n            _1639.y = _1033.y;\n            _1639.z = _1033.z;\n            c = _1639;\n        }\n        float4 _1644 = c;\n        _1644.w = clamp(_1644.w + ((_1005 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _1644.w)), 0.0f, 1.0f);\n        c = _1644;\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _360 = gl_FragCoord.xy * _307_fa_target.xy;\n    float _364 = _360.y;\n    return float2(_360.x, lerp(_364, 1.0f - _364, _307_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _403 = base_mode < 0.5f;\n    bool _414;\n    if (!_403)\n    {\n        _414 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _414 = _403;\n    }\n    float _415;\n    if (_414)\n    {\n        _415 = shape_half.x;\n    }\n    else\n    {\n        _415 = 0.0f;\n    }\n    QuadInput _1589 = { uv, color, world_xy, fa_screen_uv(), _307_fa_time.x, base_mode, 0.0f.xxxx, _415 };\n    return _1589;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_scene_color(float2 uv_1)\n{\n    if (_307_fa_scene.x <= 0.0f)\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _328 = (uv_1 * _307_fa_scene.xy) + _307_fa_scene.zw;\n    float _330 = _328.y;\n    _328.y = lerp(_330, 1.0f - _330, _307_fa_target.z);\n    return fa_scene_tex.SampleLevel(light_smp, clamp(_328, 0.0f.xx, 1.0f.xx), 0.0f);\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float2 param = i.screen_uv + (float2(_430_refraction + _430_strength, 0.0f) * _307_fa_target.xy);\n    s.color = float4(lerp(fa_scene_color(param).xyz, _430_tint.xyz, _430_tint.w.xxx), 1.0f);\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1060 = params.x > 31.5f;\n    if (_1060)\n    {\n        mode -= 32.0f;\n    }\n    float _1068 = mode;\n    bool _1070 = _1068 > 15.5f;\n    if (_1070)\n    {\n        mode -= 16.0f;\n    }\n    float _1078 = mode;\n    bool _1080 = _1078 > 7.5f;\n    if (_1080)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1070)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1070)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1144 = tex_color(param_5) * color;\n                float4 param_6 = _1144;\n                float param_7 = mode;\n                frag_color = float4(lit_color(param_6, param_7), _1144.w);\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1179 = length(uv);\n                    float _1182 = fwidth(_1179);\n                    float _1183 = max(_1182, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1179) / _1183) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1179) / _1183) + 0.5f, 0.0f, 1.0f) * clamp(((_1179 - params.y) / _1183) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1223 = clamp(1.0f - _1179, 0.0f, 1.0f);\n                            cov = (_1223 * _1223) * (3.0f - (2.0f * _1223));\n                        }\n                    }\n                    float3 _1232;\n                    if (_1070)\n                    {\n                        float4 param_8 = color;\n                        float param_9 = 5.0f;\n                        _1232 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1232 = color.xyz;\n                    }\n                    frag_color = float4(_1232, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1569 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface _1571 = { _1569 };\n    QuadSurface param_12 = _1571;\n    fragment(param_11, param_12);\n    _1569 = param_12.color;\n    frag_color = param_12.color;\n    if (_1060)\n    {\n        float4 _1270 = frag_color;\n        float3 param_13 = color2.xyz;\n        float3 _1275 = scene_rgb(param_13);\n        float3 _1279 = lerp(_1270.xyz, _1275, color2.w.xxx);\n        frag_color.x = _1279.x;\n        frag_color.y = _1279.y;\n        frag_color.z = _1279.z;\n    }\n    if (_1080)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1302 = _307_fog_col.w > 0.0f;\n    bool _1310;\n    if (!_1302)\n    {\n        _1310 = _307_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1310 = _1302;\n    }\n    if (_1310)\n    {\n        float3 _1323 = float3(world_xy, world_z) - _307_fog_eye.xyz;\n        float _1330 = dot(_1323, _307_fog_c.xyz);\n        bool _1334 = _307_fog_c.w > 0.5f;\n        float _1335;\n        if (_1334)\n        {\n            _1335 = _1330;\n        }\n        else\n        {\n            _1335 = length(_1323);\n        }\n        float _1347 = _1335 - _307_fog_b.x;\n        if (_1347 > 0.0f)\n        {\n            float _1356 = _307_fog_col.w * _1347;\n            float tau = _1356 * _1356;\n            if (_307_fog_b.y > 0.0f)\n            {\n                float _1372;\n                if (_1334)\n                {\n                    _1372 = world_xy.y - (_307_fog_c.y * _1330);\n                }\n                else\n                {\n                    _1372 = _307_fog_eye.y;\n                }\n                float _1393 = lerp(_1372, world_xy.y, clamp(_307_fog_b.x / _1335, 0.0f, 1.0f));\n                float _1397 = world_xy.y - _1393;\n                float _1402 = _1393 - _307_fog_b.z;\n                float _1407 = world_xy.y - _307_fog_b.z;\n                bool _1410 = _1402 <= 0.0f;\n                bool _1411 = !_1410;\n                bool _1417;\n                if (_1411)\n                {\n                    _1417 = _307_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1417 = _1410;\n                }\n                float _1418;\n                if (_1417)\n                {\n                    _1418 = _307_fog_b.y;\n                }\n                else\n                {\n                    _1418 = _307_fog_b.y * exp(-min(_307_fog_b.w * _1402, 80.0f));\n                }\n                bool _1445;\n                if (_1411)\n                {\n                    _1445 = _307_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1445 = _1410;\n                }\n                float _1446;\n                if (_1445)\n                {\n                    _1446 = _307_fog_b.y * _1402;\n                }\n                else\n                {\n                    _1446 = (_307_fog_b.y * (1.0f - exp(-min(_307_fog_b.w * _1402, 80.0f)))) / _307_fog_b.w;\n                }\n                bool _1471 = _1407 <= 0.0f;\n                bool _1478;\n                if (!_1471)\n                {\n                    _1478 = _307_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1478 = _1471;\n                }\n                float _1479;\n                if (_1478)\n                {\n                    _1479 = _307_fog_b.y * _1407;\n                }\n                else\n                {\n                    _1479 = (_307_fog_b.y * (1.0f - exp(-min(_307_fog_b.w * _1407, 80.0f)))) / _307_fog_b.w;\n                }\n                float _1506;\n                if (abs(_1397) < 0.001000000047497451305389404296875f)\n                {\n                    _1506 = _1418;\n                }\n                else\n                {\n                    _1506 = (_1479 - _1446) / _1397;\n                }\n                tau += (_1347 * max(_1506, 0.0f));\n            }\n            float4 _1529 = frag_color;\n            float3 _1537 = lerp(_1529.xyz, _307_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _1537.x;\n            frag_color.y = _1537.y;\n            frag_color.z = _1537.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 128,
            "struct_name": "fa_material",
            "inst_name": "_430",
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
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _128_lit : packoffset(c0);\n    float4 _128_ambient : packoffset(c1);\n    float4 _128_normal_uv : packoffset(c2);\n    float4 _128_flat_ambient : packoffset(c3);\n    float4 _128_light_map : packoffset(c4);\n    float4 _128_light_pos[16] : packoffset(c5);\n    float4 _128_light_color[16] : packoffset(c21);\n    float4 _128_light_shadow_v[16] : packoffset(c37);\n    float4 _128_fog_col : packoffset(c53);\n    float4 _128_fog_b : packoffset(c54);\n    float4 _128_fog_c : packoffset(c55);\n    float4 _128_fog_eye : packoffset(c56);\n    float4 _128_fa_time : packoffset(c57);\n    float4 _128_fa_target : packoffset(c58);\n    float4 _128_fa_scene : packoffset(c59);\n    float4 _128_fa_world_uv[3] : packoffset(c60);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _261_reflection : packoffset(c0);\n    float _261_fa_pad0 : packoffset(c0.y);\n    float _261_fa_pad1 : packoffset(c0.z);\n    float _261_fa_pad2 : packoffset(c0.w);\n    float _261_refraction : packoffset(c1);\n    float _261_fa_pad3 : packoffset(c1.y);\n    float _261_fa_pad4 : packoffset(c1.z);\n    float _261_fa_pad5 : packoffset(c1.w);\n    float2 _261_size : packoffset(c2);\n    float _261_fa_pad6 : packoffset(c2.z);\n    float _261_fa_pad7 : packoffset(c2.w);\n    float _261_strength : packoffset(c3);\n    float _261_fa_pad8 : packoffset(c3.y);\n    float _261_fa_pad9 : packoffset(c3.z);\n    float _261_fa_pad10 : packoffset(c3.w);\n    float4 _261_tint : packoffset(c4);\n    float _261_waveAmplitude : packoffset(c5);\n    float _261_fa_pad11 : packoffset(c5.y);\n    float _261_fa_pad12 : packoffset(c5.z);\n    float _261_fa_pad13 : packoffset(c5.w);\n    float _261_waveLength : packoffset(c6);\n    float _261_fa_pad14 : packoffset(c6.y);\n    float _261_fa_pad15 : packoffset(c6.z);\n    float _261_fa_pad16 : packoffset(c6.w);\n    float _261_waveSpeed : packoffset(c7);\n    float _261_fa_pad17 : packoffset(c7.y);\n    float _261_fa_pad18 : packoffset(c7.z);\n    float _261_fa_pad19 : packoffset(c7.w);\n};\n\nTexture2D<float4> fa_scene_tex : register(t1);\nSamplerState light_smp : register(s1);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 frag_color;\nstatic float3 xform;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _106 = fa_linear_to_srgb(param);\n        c = _106;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _115 = fa_srgb_to_linear(param_1);\n            c = _115;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _189 = gl_FragCoord.xy * _128_fa_target.xy;\n    float _193 = _189.y;\n    return float2(_189.x, lerp(_193, 1.0f - _193, _128_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _233 = base_mode < 0.5f;\n    bool _244;\n    if (!_233)\n    {\n        _244 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _244 = _233;\n    }\n    float _245;\n    if (_244)\n    {\n        _245 = shape_half.x;\n    }\n    else\n    {\n        _245 = 0.0f;\n    }\n    QuadInput _413 = { uv, color, world_xy, fa_screen_uv(), _128_fa_time.x, base_mode, 0.0f.xxxx, _245 };\n    return _413;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_scene_color(float2 uv_1)\n{\n    if (_128_fa_scene.x <= 0.0f)\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _150 = (uv_1 * _128_fa_scene.xy) + _128_fa_scene.zw;\n    float _153 = _150.y;\n    _150.y = lerp(_153, 1.0f - _153, _128_fa_target.z);\n    return fa_scene_tex.SampleLevel(light_smp, clamp(_150, 0.0f.xx, 1.0f.xx), 0.0f);\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float2 param = i.screen_uv + (float2(_261_refraction + _261_strength, 0.0f) * _128_fa_target.xy);\n    s.color = float4(lerp(fa_scene_color(param).xyz, _261_tint.xyz, _261_tint.w.xxx), 1.0f);\n}\n\nvoid frag_main()\n{\n    float4 _329 = tex.Sample(smp, uv);\n    float3 param = _329.xyz;\n    float param_1 = xform.y;\n    float3 _340 = fa_tex_fix(param, param_1);\n    frag_color = float4(_340, _329.w) * color;\n    float param_2 = 0.0f;\n    float4 _393 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _395 = { _393 };\n    QuadSurface param_4 = _395;\n    fragment(param_3, param_4);\n    _393 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    xform = stage_input.xform;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 128,
            "struct_name": "fa_material",
            "inst_name": "_261",
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
