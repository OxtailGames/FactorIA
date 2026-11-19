{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "2079829332065ce3783c961c08db454e84df9f84c8284a005fa67df5d2d143e6",
  "slang": "hlsl5",
  "params": [],
  "textures": [
    "mask"
  ],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "struct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\ncbuffer vs_params : register(b0)\n{\n    row_major float4x4 _96_view_proj : packoffset(c0);\n    float4 _96_cspace : packoffset(c4);\n    float4 _96_fa_time : packoffset(c5);\n};\n\nTexture2D<float4> fa_vs_mask : register(t0);\nSamplerState fa_vs_mask_smp : register(s7);\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += (fa_vs_mask.SampleLevel(fa_vs_mask_smp, float2(0.4000000059604644775390625f, 0.0500000007450580596923828125f), 0.0f).x * 40.0f);\n}\n\nvoid vert_main()\n{\n    float3 _171 = position;\n    float2 _172 = texcoord0;\n    float4 _173 = color0;\n    if (_96_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _108 = fa_srgb_to_linear(param);\n        float4 _185 = _173;\n        _185.x = _108.x;\n        _185.y = _108.y;\n        _185.z = _108.z;\n        _173 = _185;\n    }\n    QuadVertex _180 = { _171, _172, _173 };\n    QuadVertex param_1 = _180;\n    vertex(param_1);\n    _171 = param_1.world_pos;\n    _172 = param_1.uv;\n    _173 = param_1.color;\n    gl_Position = mul(float4(param_1.world_pos, 1.0f), _96_view_proj);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = _96_cspace.xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _308_lit : packoffset(c0);\n    float4 _308_ambient : packoffset(c1);\n    float4 _308_normal_uv : packoffset(c2);\n    float4 _308_flat_ambient : packoffset(c3);\n    float4 _308_light_map : packoffset(c4);\n    float4 _308_light_pos[16] : packoffset(c5);\n    float4 _308_light_color[16] : packoffset(c21);\n    float4 _308_light_shadow_v[16] : packoffset(c37);\n    float4 _308_fog_col : packoffset(c53);\n    float4 _308_fog_b : packoffset(c54);\n    float4 _308_fog_c : packoffset(c55);\n    float4 _308_fog_eye : packoffset(c56);\n    float4 _308_fa_time : packoffset(c57);\n    float4 _308_fa_target : packoffset(c58);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> mask : register(t4);\nSamplerState mask_smp : register(s3);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nSamplerState light_smp : register(s1);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _247 = fa_linear_to_srgb(param);\n        c = _247;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _255 = fa_srgb_to_linear(param_1);\n            c = _255;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _266 = tex.Sample(smp, p);\n    float3 param = _266.xyz;\n    float param_1 = xform.y;\n    float3 _276 = fa_tex_fix(param, param_1);\n    return float4(_276, _266.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _89 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_89.x * 255.0f) + 0.5f) * 256.0f) + floor((_89.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _113 = length(d);\n    if (_113 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _127 = atan2(d.y, d.x);\n    float a = _127;\n    float _130;\n    if (_127 < 0.0f)\n    {\n        _130 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _130 = a;\n    }\n    a = _130;\n    float _142 = _130 * 162.9746551513671875f;\n    float _147 = min(floor(_142), 1023.0f);\n    float _154 = _147 + 1.0f;\n    float i1 = _154;\n    if (_154 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _147;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _113) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _113) + 0.5f, 0.0f, 1.0f), _142 - _147);\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _407 = _308_lit.y > 0.5f;\n    if (_407)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _308_normal_uv.xy) + _308_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _431 = fa_tex_fix(param, param_1);\n        float3 _435 = (_431 * 2.0f) - 1.0f.xxx;\n        float _442 = cos(params.y);\n        float _444 = sin(params.y);\n        n = normalize(float3((float2(_442, _444) * _435.x) + ((float2(-_444, _442) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _435.y), max(_435.z, 0.0500000007450580596923828125f)));\n    }\n    bool _477 = !_407;\n    bool _483;\n    if (_477)\n    {\n        _483 = _308_lit.z > 0.5f;\n    }\n    else\n    {\n        _483 = _477;\n    }\n    float3 _486;\n    if (_483)\n    {\n        _486 = _308_flat_ambient.xyz;\n    }\n    else\n    {\n        _486 = _308_ambient.xyz;\n    }\n    float3 total = _486;\n    bool _503;\n    if (_483)\n    {\n        _503 = _308_lit.z < 1.5f;\n    }\n    else\n    {\n        _503 = _483;\n    }\n    if (_503)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _308_light_map.xy, 0.0f).xyz * _308_light_map.z);\n    }\n    float3 l;\n    float _621;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _543;\n        if (!_483)\n        {\n            _543 = float(i) >= _308_lit.x;\n        }\n        else\n        {\n            _543 = _483;\n        }\n        if (_543)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_308_light_pos[i].w < 0.0f)\n        {\n            l = _308_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _569 = _308_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_569) / max(_308_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _308_light_color[i].w);\n            float3 _589 = float3(_569, _308_light_pos[i].z);\n            l = _589 / max(length(_589), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_308_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _308_light_shadow_v[i].x;\n                float2 param_3 = -_569;\n                float param_4 = _308_light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_407)\n        {\n            _621 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _621 = 1.0f;\n        }\n        total += (_308_light_color[i].xyz * (att * _621));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _293 = fa_srgb_to_linear(param);\n        c = _293;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _649 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _653 = uv * _649;\n    float _659 = _649.x;\n    float _661 = _649.y;\n    float _663 = clamp(shape_rs.x, 0.0f, min(_659, _661));\n    float2 _674 = (abs(_653) - _649) + _663.xx;\n    float d = (length(max(_674, 0.0f.xx)) + min(max(_674.x, _674.y), 0.0f)) - _663;\n    float ax = params.y;\n    bool _695 = params.y > 15.0f;\n    if (_695)\n    {\n        ax -= 20.0f;\n    }\n    float _706;\n    if (ax <= (-1.5f))\n    {\n        _706 = (-2.0f) - ax;\n    }\n    else\n    {\n        _706 = 0.0f;\n    }\n    if (_706 > 0.0f)\n    {\n        float _720 = _706 * 0.5f;\n        d = abs(d + _720) - _720;\n    }\n    float _728 = fwidth(d);\n    float _729 = max(_728, 9.9999997473787516355514526367188e-05f);\n    float _739 = clamp(0.5f - (d / max(shape_rs.y, _729)), 0.0f, 1.0f);\n    float _744;\n    if (shape_rs.y > _729)\n    {\n        _744 = (_739 * _739) * (3.0f - (2.0f * _739));\n    }\n    else\n    {\n        _744 = _739;\n    }\n    float4 c = color;\n    bool _766 = (_706 <= 0.0f) && (ax > (-0.5f));\n    if (_766)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _781 = cos(ax);\n            float _783 = sin(ax);\n            g = ((dot(_653, float2(_781, _783)) / max((abs(_781) * _659) + (abs(_783) * _661), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_695)\n        {\n            float4 _826 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _826;\n            float3 param = _826.xyz;\n            float param_1 = xform.y;\n            float3 _833 = fa_tex_fix(param, param_1);\n            float4 _1529 = c;\n            _1529.x = _833.x;\n            _1529.y = _833.y;\n            _1529.z = _833.z;\n            c = _1529;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _845 = scene_rgb(param_2);\n            float4 _870 = lerp(float4(color.xyz * color.w, color.w), float4(_845 * color2.w, color2.w), g.xxxx);\n            float _872 = _870.w;\n            float3 _875;\n            if (_872 > 9.9999997473787516355514526367188e-06f)\n            {\n                _875 = _870.xyz / _872.xxx;\n            }\n            else\n            {\n                _875 = color.xyz;\n            }\n            c = float4(_875, _872);\n        }\n    }\n    float4 _1538 = c;\n    _1538.w = _1538.w * _744;\n    c = _1538;\n    if (_766 || (shape_rs.y > 0.0f))\n    {\n        float _916 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _925 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _925 + (_916 * 0.0039215688593685626983642578125f).xxx;\n            float3 _931 = fa_srgb_to_linear(param_4);\n            float4 _1541 = c;\n            _1541.x = _931.x;\n            _1541.y = _931.y;\n            _1541.z = _931.z;\n            c = _1541;\n        }\n        else\n        {\n            float4 _941 = c;\n            float3 _944 = _941.xyz + (_916 * 0.0039215688593685626983642578125f).xxx;\n            float4 _1548 = _941;\n            _1548.x = _944.x;\n            _1548.y = _944.y;\n            _1548.z = _944.z;\n            c = _1548;\n        }\n        float4 _1553 = c;\n        _1553.w = clamp(_1553.w + ((_916 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _1553.w)), 0.0f, 1.0f);\n        c = _1553;\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _315 = gl_FragCoord.xy * _308_fa_target.xy;\n    float _319 = _315.y;\n    return float2(_315.x, lerp(_319, 1.0f - _319, _308_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _361 = base_mode < 0.5f;\n    bool _372;\n    if (!_361)\n    {\n        _372 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _372 = _361;\n    }\n    float _373;\n    if (_372)\n    {\n        _373 = shape_half.x;\n    }\n    else\n    {\n        _373 = 0.0f;\n    }\n    QuadInput _1502 = { uv, color, world_xy, fa_screen_uv(), _308_fa_time.x, base_mode, 0.0f.xxxx, _373 };\n    return _1502;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float4 _393 = mask.Sample(mask_smp, float2(0.4000000059604644775390625f, 0.0500000007450580596923828125f));\n    s.color.x = _393.x;\n    s.color.y = _393.y;\n    s.color.z = _393.z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _971 = params.x > 31.5f;\n    if (_971)\n    {\n        mode -= 32.0f;\n    }\n    float _979 = mode;\n    bool _981 = _979 > 15.5f;\n    if (_981)\n    {\n        mode -= 16.0f;\n    }\n    float _989 = mode;\n    bool _991 = _989 > 7.5f;\n    if (_991)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_981)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_981)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1055 = tex_color(param_5) * color;\n                float4 param_6 = _1055;\n                float param_7 = mode;\n                frag_color = float4(lit_color(param_6, param_7), _1055.w);\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1090 = length(uv);\n                    float _1093 = fwidth(_1090);\n                    float _1094 = max(_1093, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1090) / _1094) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1090) / _1094) + 0.5f, 0.0f, 1.0f) * clamp(((_1090 - params.y) / _1094) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1134 = clamp(1.0f - _1090, 0.0f, 1.0f);\n                            cov = (_1134 * _1134) * (3.0f - (2.0f * _1134));\n                        }\n                    }\n                    float3 _1143;\n                    if (_981)\n                    {\n                        float4 param_8 = color;\n                        float param_9 = 5.0f;\n                        _1143 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1143 = color.xyz;\n                    }\n                    frag_color = float4(_1143, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1482 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface _1484 = { _1482 };\n    QuadSurface param_12 = _1484;\n    fragment(param_11, param_12);\n    _1482 = param_12.color;\n    frag_color = param_12.color;\n    if (_971)\n    {\n        float4 _1181 = frag_color;\n        float3 param_13 = color2.xyz;\n        float3 _1186 = scene_rgb(param_13);\n        float3 _1190 = lerp(_1181.xyz, _1186, color2.w.xxx);\n        frag_color.x = _1190.x;\n        frag_color.y = _1190.y;\n        frag_color.z = _1190.z;\n    }\n    if (_991)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1214 = _308_fog_col.w > 0.0f;\n    bool _1222;\n    if (!_1214)\n    {\n        _1222 = _308_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1222 = _1214;\n    }\n    if (_1222)\n    {\n        float3 _1236 = float3(world_xy, world_z) - _308_fog_eye.xyz;\n        float _1243 = dot(_1236, _308_fog_c.xyz);\n        bool _1247 = _308_fog_c.w > 0.5f;\n        float _1248;\n        if (_1247)\n        {\n            _1248 = _1243;\n        }\n        else\n        {\n            _1248 = length(_1236);\n        }\n        float _1260 = _1248 - _308_fog_b.x;\n        if (_1260 > 0.0f)\n        {\n            float _1269 = _308_fog_col.w * _1260;\n            float tau = _1269 * _1269;\n            if (_308_fog_b.y > 0.0f)\n            {\n                float _1285;\n                if (_1247)\n                {\n                    _1285 = world_xy.y - (_308_fog_c.y * _1243);\n                }\n                else\n                {\n                    _1285 = _308_fog_eye.y;\n                }\n                float _1306 = lerp(_1285, world_xy.y, clamp(_308_fog_b.x / _1248, 0.0f, 1.0f));\n                float _1310 = world_xy.y - _1306;\n                float _1315 = _1306 - _308_fog_b.z;\n                float _1320 = world_xy.y - _308_fog_b.z;\n                bool _1323 = _1315 <= 0.0f;\n                bool _1324 = !_1323;\n                bool _1330;\n                if (_1324)\n                {\n                    _1330 = _308_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1330 = _1323;\n                }\n                float _1331;\n                if (_1330)\n                {\n                    _1331 = _308_fog_b.y;\n                }\n                else\n                {\n                    _1331 = _308_fog_b.y * exp(-min(_308_fog_b.w * _1315, 80.0f));\n                }\n                bool _1358;\n                if (_1324)\n                {\n                    _1358 = _308_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1358 = _1323;\n                }\n                float _1359;\n                if (_1358)\n                {\n                    _1359 = _308_fog_b.y * _1315;\n                }\n                else\n                {\n                    _1359 = (_308_fog_b.y * (1.0f - exp(-min(_308_fog_b.w * _1315, 80.0f)))) / _308_fog_b.w;\n                }\n                bool _1384 = _1320 <= 0.0f;\n                bool _1391;\n                if (!_1384)\n                {\n                    _1391 = _308_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1391 = _1384;\n                }\n                float _1392;\n                if (_1391)\n                {\n                    _1392 = _308_fog_b.y * _1320;\n                }\n                else\n                {\n                    _1392 = (_308_fog_b.y * (1.0f - exp(-min(_308_fog_b.w * _1320, 80.0f)))) / _308_fog_b.w;\n                }\n                float _1419;\n                if (abs(_1310) < 0.001000000047497451305389404296875f)\n                {\n                    _1419 = _1331;\n                }\n                else\n                {\n                    _1419 = (_1392 - _1359) / _1310;\n                }\n                tau += (_1260 * max(_1419, 0.0f));\n            }\n            float4 _1442 = frag_color;\n            float3 _1450 = lerp(_1442.xyz, _308_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _1450.x;\n            frag_color.y = _1450.y;\n            frag_color.z = _1450.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_96",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_308",
            "hlsl_register_b_n": 1
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
              "slot": 4,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 4
            }
          },
          {
            "texture": {
              "slot": 8,
              "stage": "vertex",
              "name": "fa_vs_mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 7,
            "stage": "vertex",
            "name": "fa_vs_mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 7
          },
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
            "slot": 3,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 3
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
            "stage": "vertex",
            "name": "fa_vs_mask_fa_vs_mask_smp",
            "view_name": "fa_vs_mask",
            "sampler_name": "fa_vs_mask_smp",
            "view_slot": 8,
            "sampler_slot": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "tex_smp",
            "view_name": "tex",
            "sampler_name": "smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "normal_tex_smp",
            "view_name": "normal_tex",
            "sampler_name": "smp",
            "view_slot": 1,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "light_tex_light_smp",
            "view_name": "light_tex",
            "sampler_name": "light_smp",
            "view_slot": 2,
            "sampler_slot": 1
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "shadow_tex_shadow_smp",
            "view_name": "shadow_tex",
            "sampler_name": "shadow_smp",
            "view_slot": 3,
            "sampler_slot": 2
          },
          {
            "slot": 5,
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
      "vs": "struct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\ncbuffer vs_params : register(b0)\n{\n    row_major float4x4 _96_view_proj : packoffset(c0);\n    float4 _96_cspace : packoffset(c4);\n    float4 _96_fa_time : packoffset(c5);\n};\n\nTexture2D<float4> fa_vs_mask : register(t0);\nSamplerState fa_vs_mask_smp : register(s7);\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += (fa_vs_mask.SampleLevel(fa_vs_mask_smp, float2(0.4000000059604644775390625f, 0.0500000007450580596923828125f), 0.0f).x * 40.0f);\n}\n\nvoid vert_main()\n{\n    float3 _171 = position;\n    float2 _172 = texcoord0;\n    float4 _173 = color0;\n    if (_96_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _108 = fa_srgb_to_linear(param);\n        float4 _185 = _173;\n        _185.x = _108.x;\n        _185.y = _108.y;\n        _185.z = _108.z;\n        _173 = _185;\n    }\n    QuadVertex _180 = { _171, _172, _173 };\n    QuadVertex param_1 = _180;\n    vertex(param_1);\n    _171 = param_1.world_pos;\n    _172 = param_1.uv;\n    _173 = param_1.color;\n    gl_Position = mul(float4(param_1.world_pos, 1.0f), _96_view_proj);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = _96_cspace.xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _127_lit : packoffset(c0);\n    float4 _127_ambient : packoffset(c1);\n    float4 _127_normal_uv : packoffset(c2);\n    float4 _127_flat_ambient : packoffset(c3);\n    float4 _127_light_map : packoffset(c4);\n    float4 _127_light_pos[16] : packoffset(c5);\n    float4 _127_light_color[16] : packoffset(c21);\n    float4 _127_light_shadow_v[16] : packoffset(c37);\n    float4 _127_fog_col : packoffset(c53);\n    float4 _127_fog_b : packoffset(c54);\n    float4 _127_fog_c : packoffset(c55);\n    float4 _127_fog_eye : packoffset(c56);\n    float4 _127_fa_time : packoffset(c57);\n    float4 _127_fa_target : packoffset(c58);\n};\n\nTexture2D<float4> mask : register(t1);\nSamplerState mask_smp : register(s3);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 frag_color;\nstatic float3 xform;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _134 = gl_FragCoord.xy * _127_fa_target.xy;\n    float _140 = _134.y;\n    return float2(_134.x, lerp(_140, 1.0f - _140, _127_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _184 = base_mode < 0.5f;\n    bool _195;\n    if (!_184)\n    {\n        _195 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _195 = _184;\n    }\n    float _196;\n    if (_195)\n    {\n        _196 = shape_half.x;\n    }\n    else\n    {\n        _196 = 0.0f;\n    }\n    QuadInput _322 = { uv, color, world_xy, fa_screen_uv(), _127_fa_time.x, base_mode, 0.0f.xxxx, _196 };\n    return _322;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float4 _222 = mask.Sample(mask_smp, float2(0.4000000059604644775390625f, 0.0500000007450580596923828125f));\n    s.color.x = _222.x;\n    s.color.y = _222.y;\n    s.color.z = _222.z;\n}\n\nvoid frag_main()\n{\n    float4 _237 = tex.Sample(smp, uv);\n    float3 param = _237.xyz;\n    float param_1 = xform.y;\n    float3 _248 = fa_tex_fix(param, param_1);\n    frag_color = float4(_248, _237.w) * color;\n    float param_2 = 0.0f;\n    float4 _302 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _304 = { _302 };\n    QuadSurface param_4 = _304;\n    fragment(param_3, param_4);\n    _302 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    xform = stage_input.xform;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_96",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_127",
            "hlsl_register_b_n": 1
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
              "slot": 4,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 1
            }
          },
          {
            "texture": {
              "slot": 8,
              "stage": "vertex",
              "name": "fa_vs_mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 7,
            "stage": "vertex",
            "name": "fa_vs_mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 7
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 3
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
            "stage": "vertex",
            "name": "fa_vs_mask_fa_vs_mask_smp",
            "view_name": "fa_vs_mask",
            "sampler_name": "fa_vs_mask_smp",
            "view_slot": 8,
            "sampler_slot": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "tex_smp",
            "view_name": "tex",
            "sampler_name": "smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 2,
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
