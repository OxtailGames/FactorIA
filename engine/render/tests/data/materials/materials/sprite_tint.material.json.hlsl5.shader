{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "fbbf992817153618419584ba1a09ecc1936ec122cdfee21008275f9dd823a10f",
  "slang": "hlsl5",
  "params": [
    "tint"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _147 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _147;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _316_lit : packoffset(c0);\n    float4 _316_ambient : packoffset(c1);\n    float4 _316_normal_uv : packoffset(c2);\n    float4 _316_flat_ambient : packoffset(c3);\n    float4 _316_light_map : packoffset(c4);\n    float4 _316_light_pos[16] : packoffset(c5);\n    float4 _316_light_color[16] : packoffset(c21);\n    float4 _316_light_shadow_v[16] : packoffset(c37);\n    float4 _316_fog_col : packoffset(c53);\n    float4 _316_fog_b : packoffset(c54);\n    float4 _316_fog_c : packoffset(c55);\n    float4 _316_fog_eye : packoffset(c56);\n    float4 _316_fa_time : packoffset(c57);\n    float4 _316_fa_target : packoffset(c58);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _395_tint : packoffset(c0);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nSamplerState light_smp : register(s1);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _250 = fa_linear_to_srgb(param);\n        c = _250;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _258 = fa_srgb_to_linear(param_1);\n            c = _258;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _269 = tex.Sample(smp, p);\n    float3 param = _269.xyz;\n    float param_1 = xform.y;\n    float3 _279 = fa_tex_fix(param, param_1);\n    return float4(_279, _269.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _92 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_92.x * 255.0f) + 0.5f) * 256.0f) + floor((_92.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _116 = length(d);\n    if (_116 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _130 = atan2(d.y, d.x);\n    float a = _130;\n    float _133;\n    if (_130 < 0.0f)\n    {\n        _133 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _133 = a;\n    }\n    a = _133;\n    float _145 = _133 * 162.9746551513671875f;\n    float _150 = min(floor(_145), 1023.0f);\n    float _157 = _150 + 1.0f;\n    float i1 = _157;\n    if (_157 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _150;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _116) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _116) + 0.5f, 0.0f, 1.0f), _145 - _150);\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _417 = _316_lit.y > 0.5f;\n    if (_417)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _316_normal_uv.xy) + _316_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _441 = fa_tex_fix(param, param_1);\n        float3 _445 = (_441 * 2.0f) - 1.0f.xxx;\n        float _452 = cos(params.y);\n        float _454 = sin(params.y);\n        n = normalize(float3((float2(_452, _454) * _445.x) + ((float2(-_454, _452) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _445.y), max(_445.z, 0.0500000007450580596923828125f)));\n    }\n    bool _488 = !_417;\n    bool _494;\n    if (_488)\n    {\n        _494 = _316_lit.z > 0.5f;\n    }\n    else\n    {\n        _494 = _488;\n    }\n    float3 _497;\n    if (_494)\n    {\n        _497 = _316_flat_ambient.xyz;\n    }\n    else\n    {\n        _497 = _316_ambient.xyz;\n    }\n    float3 total = _497;\n    bool _514;\n    if (_494)\n    {\n        _514 = _316_lit.z < 1.5f;\n    }\n    else\n    {\n        _514 = _494;\n    }\n    if (_514)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _316_light_map.xy, 0.0f).xyz * _316_light_map.z);\n    }\n    float3 l;\n    float _632;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _554;\n        if (!_494)\n        {\n            _554 = float(i) >= _316_lit.x;\n        }\n        else\n        {\n            _554 = _494;\n        }\n        if (_554)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_316_light_pos[i].w < 0.0f)\n        {\n            l = _316_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _580 = _316_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_580) / max(_316_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _316_light_color[i].w);\n            float3 _600 = float3(_580, _316_light_pos[i].z);\n            l = _600 / max(length(_600), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_316_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _316_light_shadow_v[i].x;\n                float2 param_3 = -_580;\n                float param_4 = _316_light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_417)\n        {\n            _632 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _632 = 1.0f;\n        }\n        total += (_316_light_color[i].xyz * (att * _632));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _296 = fa_srgb_to_linear(param);\n        c = _296;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _660 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _664 = uv * _660;\n    float _670 = _660.x;\n    float _672 = _660.y;\n    float _674 = clamp(shape_rs.x, 0.0f, min(_670, _672));\n    float2 _685 = (abs(_664) - _660) + _674.xx;\n    float d = (length(max(_685, 0.0f.xx)) + min(max(_685.x, _685.y), 0.0f)) - _674;\n    float ax = params.y;\n    bool _706 = params.y > 15.0f;\n    if (_706)\n    {\n        ax -= 20.0f;\n    }\n    float _717;\n    if (ax <= (-1.5f))\n    {\n        _717 = (-2.0f) - ax;\n    }\n    else\n    {\n        _717 = 0.0f;\n    }\n    if (_717 > 0.0f)\n    {\n        float _731 = _717 * 0.5f;\n        d = abs(d + _731) - _731;\n    }\n    float _739 = fwidth(d);\n    float _740 = max(_739, 9.9999997473787516355514526367188e-05f);\n    float _750 = clamp(0.5f - (d / max(shape_rs.y, _740)), 0.0f, 1.0f);\n    float _755;\n    if (shape_rs.y > _740)\n    {\n        _755 = (_750 * _750) * (3.0f - (2.0f * _750));\n    }\n    else\n    {\n        _755 = _750;\n    }\n    float4 c = color;\n    bool _777 = (_717 <= 0.0f) && (ax > (-0.5f));\n    if (_777)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _792 = cos(ax);\n            float _794 = sin(ax);\n            g = ((dot(_664, float2(_792, _794)) / max((abs(_792) * _670) + (abs(_794) * _672), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_706)\n        {\n            float4 _837 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _837;\n            float3 param = _837.xyz;\n            float param_1 = xform.y;\n            float3 _844 = fa_tex_fix(param, param_1);\n            float4 _1540 = c;\n            _1540.x = _844.x;\n            _1540.y = _844.y;\n            _1540.z = _844.z;\n            c = _1540;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _856 = scene_rgb(param_2);\n            float4 _881 = lerp(float4(color.xyz * color.w, color.w), float4(_856 * color2.w, color2.w), g.xxxx);\n            float _883 = _881.w;\n            float3 _886;\n            if (_883 > 9.9999997473787516355514526367188e-06f)\n            {\n                _886 = _881.xyz / _883.xxx;\n            }\n            else\n            {\n                _886 = color.xyz;\n            }\n            c = float4(_886, _883);\n        }\n    }\n    float4 _1549 = c;\n    _1549.w = _1549.w * _755;\n    c = _1549;\n    if (_777 || (shape_rs.y > 0.0f))\n    {\n        float _927 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _936 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _936 + (_927 * 0.0039215688593685626983642578125f).xxx;\n            float3 _942 = fa_srgb_to_linear(param_4);\n            float4 _1552 = c;\n            _1552.x = _942.x;\n            _1552.y = _942.y;\n            _1552.z = _942.z;\n            c = _1552;\n        }\n        else\n        {\n            float4 _952 = c;\n            float3 _955 = _952.xyz + (_927 * 0.0039215688593685626983642578125f).xxx;\n            float4 _1559 = _952;\n            _1559.x = _955.x;\n            _1559.y = _955.y;\n            _1559.z = _955.z;\n            c = _1559;\n        }\n        float4 _1564 = c;\n        _1564.w = clamp(_1564.w + ((_927 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _1564.w)), 0.0f, 1.0f);\n        c = _1564;\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _323 = gl_FragCoord.xy * _316_fa_target.xy;\n    float _327 = _323.y;\n    return float2(_323.x, lerp(_327, 1.0f - _327, _316_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _369 = base_mode < 0.5f;\n    bool _380;\n    if (!_369)\n    {\n        _380 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _380 = _369;\n    }\n    float _381;\n    if (_380)\n    {\n        _381 = shape_half.x;\n    }\n    else\n    {\n        _381 = 0.0f;\n    }\n    QuadInput _1513 = { uv, color, world_xy, fa_screen_uv(), _316_fa_time.x, base_mode, 0.0f.xxxx, _381 };\n    return _1513;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _302 = scene_rgb(param);\n    return _302;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = _395_tint.xyz;\n    float4 _402 = s.color;\n    float3 _404 = _402.xyz * fa_scene_rgb(param);\n    s.color.x = _404.x;\n    s.color.y = _404.y;\n    s.color.z = _404.z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _982 = params.x > 31.5f;\n    if (_982)\n    {\n        mode -= 32.0f;\n    }\n    float _990 = mode;\n    bool _992 = _990 > 15.5f;\n    if (_992)\n    {\n        mode -= 16.0f;\n    }\n    float _1000 = mode;\n    bool _1002 = _1000 > 7.5f;\n    if (_1002)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_992)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_992)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1066 = tex_color(param_5) * color;\n                float4 param_6 = _1066;\n                float param_7 = mode;\n                frag_color = float4(lit_color(param_6, param_7), _1066.w);\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1101 = length(uv);\n                    float _1104 = fwidth(_1101);\n                    float _1105 = max(_1104, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1101) / _1105) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1101) / _1105) + 0.5f, 0.0f, 1.0f) * clamp(((_1101 - params.y) / _1105) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1145 = clamp(1.0f - _1101, 0.0f, 1.0f);\n                            cov = (_1145 * _1145) * (3.0f - (2.0f * _1145));\n                        }\n                    }\n                    float3 _1154;\n                    if (_992)\n                    {\n                        float4 param_8 = color;\n                        float param_9 = 5.0f;\n                        _1154 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1154 = color.xyz;\n                    }\n                    frag_color = float4(_1154, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1493 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface _1495 = { _1493 };\n    QuadSurface param_12 = _1495;\n    fragment(param_11, param_12);\n    _1493 = param_12.color;\n    frag_color = param_12.color;\n    if (_982)\n    {\n        float4 _1192 = frag_color;\n        float3 param_13 = color2.xyz;\n        float3 _1197 = scene_rgb(param_13);\n        float3 _1201 = lerp(_1192.xyz, _1197, color2.w.xxx);\n        frag_color.x = _1201.x;\n        frag_color.y = _1201.y;\n        frag_color.z = _1201.z;\n    }\n    if (_1002)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1225 = _316_fog_col.w > 0.0f;\n    bool _1233;\n    if (!_1225)\n    {\n        _1233 = _316_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1233 = _1225;\n    }\n    if (_1233)\n    {\n        float3 _1247 = float3(world_xy, world_z) - _316_fog_eye.xyz;\n        float _1254 = dot(_1247, _316_fog_c.xyz);\n        bool _1258 = _316_fog_c.w > 0.5f;\n        float _1259;\n        if (_1258)\n        {\n            _1259 = _1254;\n        }\n        else\n        {\n            _1259 = length(_1247);\n        }\n        float _1271 = _1259 - _316_fog_b.x;\n        if (_1271 > 0.0f)\n        {\n            float _1280 = _316_fog_col.w * _1271;\n            float tau = _1280 * _1280;\n            if (_316_fog_b.y > 0.0f)\n            {\n                float _1296;\n                if (_1258)\n                {\n                    _1296 = world_xy.y - (_316_fog_c.y * _1254);\n                }\n                else\n                {\n                    _1296 = _316_fog_eye.y;\n                }\n                float _1317 = lerp(_1296, world_xy.y, clamp(_316_fog_b.x / _1259, 0.0f, 1.0f));\n                float _1321 = world_xy.y - _1317;\n                float _1326 = _1317 - _316_fog_b.z;\n                float _1331 = world_xy.y - _316_fog_b.z;\n                bool _1334 = _1326 <= 0.0f;\n                bool _1335 = !_1334;\n                bool _1341;\n                if (_1335)\n                {\n                    _1341 = _316_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1341 = _1334;\n                }\n                float _1342;\n                if (_1341)\n                {\n                    _1342 = _316_fog_b.y;\n                }\n                else\n                {\n                    _1342 = _316_fog_b.y * exp(-min(_316_fog_b.w * _1326, 80.0f));\n                }\n                bool _1369;\n                if (_1335)\n                {\n                    _1369 = _316_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1369 = _1334;\n                }\n                float _1370;\n                if (_1369)\n                {\n                    _1370 = _316_fog_b.y * _1326;\n                }\n                else\n                {\n                    _1370 = (_316_fog_b.y * (1.0f - exp(-min(_316_fog_b.w * _1326, 80.0f)))) / _316_fog_b.w;\n                }\n                bool _1395 = _1331 <= 0.0f;\n                bool _1402;\n                if (!_1395)\n                {\n                    _1402 = _316_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1402 = _1395;\n                }\n                float _1403;\n                if (_1402)\n                {\n                    _1403 = _316_fog_b.y * _1331;\n                }\n                else\n                {\n                    _1403 = (_316_fog_b.y * (1.0f - exp(-min(_316_fog_b.w * _1331, 80.0f)))) / _316_fog_b.w;\n                }\n                float _1430;\n                if (abs(_1321) < 0.001000000047497451305389404296875f)\n                {\n                    _1430 = _1342;\n                }\n                else\n                {\n                    _1430 = (_1403 - _1370) / _1321;\n                }\n                tau += (_1271 * max(_1430, 0.0f));\n            }\n            float4 _1453 = frag_color;\n            float3 _1461 = lerp(_1453.xyz, _316_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _1461.x;\n            frag_color.y = _1461.y;\n            frag_color.z = _1461.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_316",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_395",
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
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _147 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _147;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _153_lit : packoffset(c0);\n    float4 _153_ambient : packoffset(c1);\n    float4 _153_normal_uv : packoffset(c2);\n    float4 _153_flat_ambient : packoffset(c3);\n    float4 _153_light_map : packoffset(c4);\n    float4 _153_light_pos[16] : packoffset(c5);\n    float4 _153_light_color[16] : packoffset(c21);\n    float4 _153_light_shadow_v[16] : packoffset(c37);\n    float4 _153_fog_col : packoffset(c53);\n    float4 _153_fog_b : packoffset(c54);\n    float4 _153_fog_c : packoffset(c55);\n    float4 _153_fog_eye : packoffset(c56);\n    float4 _153_fa_time : packoffset(c57);\n    float4 _153_fa_target : packoffset(c58);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _235_tint : packoffset(c0);\n};\n\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 frag_color;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _107 = fa_linear_to_srgb(param);\n        c = _107;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _116 = fa_srgb_to_linear(param_1);\n            c = _116;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _160 = gl_FragCoord.xy * _153_fa_target.xy;\n    float _165 = _160.y;\n    return float2(_160.x, lerp(_165, 1.0f - _165, _153_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _209 = base_mode < 0.5f;\n    bool _220;\n    if (!_209)\n    {\n        _220 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _220 = _209;\n    }\n    float _221;\n    if (_220)\n    {\n        _221 = shape_half.x;\n    }\n    else\n    {\n        _221 = 0.0f;\n    }\n    QuadInput _346 = { uv, color, world_xy, fa_screen_uv(), _153_fa_time.x, base_mode, 0.0f.xxxx, _221 };\n    return _346;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _132 = fa_srgb_to_linear(param);\n        c = _132;\n    }\n    return c;\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _138 = scene_rgb(param);\n    return _138;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = _235_tint.xyz;\n    float4 _242 = s.color;\n    float3 _244 = _242.xyz * fa_scene_rgb(param);\n    s.color.x = _244.x;\n    s.color.y = _244.y;\n    s.color.z = _244.z;\n}\n\nvoid frag_main()\n{\n    float4 _263 = tex.Sample(smp, uv);\n    float3 param = _263.xyz;\n    float param_1 = xform.y;\n    float3 _272 = fa_tex_fix(param, param_1);\n    frag_color = float4(_272, _263.w) * color;\n    float param_2 = 0.0f;\n    float4 _326 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _328 = { _326 };\n    QuadSurface param_4 = _328;\n    fragment(param_3, param_4);\n    _326 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_153",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_235",
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
          }
        ],
        "samplers": [
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
          }
        ]
      }
    }
  }
}
