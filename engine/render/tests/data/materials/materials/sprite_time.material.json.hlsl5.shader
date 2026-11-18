{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "ed7d6aa4bb6587a53460bdad882f96cecc84c68276eec459c73c25f578a29fd8",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _144 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _144;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _306_lit : packoffset(c0);\n    float4 _306_ambient : packoffset(c1);\n    float4 _306_normal_uv : packoffset(c2);\n    float4 _306_flat_ambient : packoffset(c3);\n    float4 _306_light_map : packoffset(c4);\n    float4 _306_light_pos[16] : packoffset(c5);\n    float4 _306_light_color[16] : packoffset(c21);\n    float4 _306_light_shadow_v[16] : packoffset(c37);\n    float4 _306_fog_col : packoffset(c53);\n    float4 _306_fog_b : packoffset(c54);\n    float4 _306_fog_c : packoffset(c55);\n    float4 _306_fog_eye : packoffset(c56);\n    float4 _306_fa_time : packoffset(c57);\n    float4 _306_fa_target : packoffset(c58);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nSamplerState light_smp : register(s1);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 params;\nstatic float2 shape_half;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _245 = fa_linear_to_srgb(param);\n        c = _245;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _253 = fa_srgb_to_linear(param_1);\n            c = _253;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _264 = tex.Sample(smp, p);\n    float3 param = _264.xyz;\n    float param_1 = xform.y;\n    float3 _274 = fa_tex_fix(param, param_1);\n    return float4(_274, _264.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _87 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_87.x * 255.0f) + 0.5f) * 256.0f) + floor((_87.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _111 = length(d);\n    if (_111 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _125 = atan2(d.y, d.x);\n    float a = _125;\n    float _128;\n    if (_125 < 0.0f)\n    {\n        _128 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _128 = a;\n    }\n    a = _128;\n    float _140 = _128 * 162.9746551513671875f;\n    float _145 = min(floor(_140), 1023.0f);\n    float _152 = _145 + 1.0f;\n    float i1 = _152;\n    if (_152 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _145;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _111) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _111) + 0.5f, 0.0f, 1.0f), _140 - _145);\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _378 = _306_lit.y > 0.5f;\n    if (_378)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _306_normal_uv.xy) + _306_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _402 = fa_tex_fix(param, param_1);\n        float3 _406 = (_402 * 2.0f) - 1.0f.xxx;\n        float _413 = cos(params.y);\n        float _415 = sin(params.y);\n        n = normalize(float3((float2(_413, _415) * _406.x) + ((float2(-_415, _413) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _406.y), max(_406.z, 0.0500000007450580596923828125f)));\n    }\n    bool _449 = !_378;\n    bool _455;\n    if (_449)\n    {\n        _455 = _306_lit.z > 0.5f;\n    }\n    else\n    {\n        _455 = _449;\n    }\n    float3 _458;\n    if (_455)\n    {\n        _458 = _306_flat_ambient.xyz;\n    }\n    else\n    {\n        _458 = _306_ambient.xyz;\n    }\n    float3 total = _458;\n    bool _475;\n    if (_455)\n    {\n        _475 = _306_lit.z < 1.5f;\n    }\n    else\n    {\n        _475 = _455;\n    }\n    if (_475)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _306_light_map.xy, 0.0f).xyz * _306_light_map.z);\n    }\n    float3 l;\n    float _594;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _515;\n        if (!_455)\n        {\n            _515 = float(i) >= _306_lit.x;\n        }\n        else\n        {\n            _515 = _455;\n        }\n        if (_515)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_306_light_pos[i].w < 0.0f)\n        {\n            l = _306_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _541 = _306_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_541) / max(_306_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _306_light_color[i].w);\n            float3 _561 = float3(_541, _306_light_pos[i].z);\n            l = _561 / max(length(_561), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_306_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _306_light_shadow_v[i].x;\n                float2 param_3 = -_541;\n                float param_4 = _306_light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_378)\n        {\n            _594 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _594 = 1.0f;\n        }\n        total += (_306_light_color[i].xyz * (att * _594));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _291 = fa_srgb_to_linear(param);\n        c = _291;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _623 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _627 = uv * _623;\n    float _633 = _623.x;\n    float _635 = _623.y;\n    float _637 = clamp(shape_rs.x, 0.0f, min(_633, _635));\n    float2 _648 = (abs(_627) - _623) + _637.xx;\n    float d = (length(max(_648, 0.0f.xx)) + min(max(_648.x, _648.y), 0.0f)) - _637;\n    float ax = params.y;\n    bool _669 = params.y > 15.0f;\n    if (_669)\n    {\n        ax -= 20.0f;\n    }\n    float _680;\n    if (ax <= (-1.5f))\n    {\n        _680 = (-2.0f) - ax;\n    }\n    else\n    {\n        _680 = 0.0f;\n    }\n    if (_680 > 0.0f)\n    {\n        float _694 = _680 * 0.5f;\n        d = abs(d + _694) - _694;\n    }\n    float _702 = fwidth(d);\n    float _703 = max(_702, 9.9999997473787516355514526367188e-05f);\n    float _713 = clamp(0.5f - (d / max(shape_rs.y, _703)), 0.0f, 1.0f);\n    float _718;\n    if (shape_rs.y > _703)\n    {\n        _718 = (_713 * _713) * (3.0f - (2.0f * _713));\n    }\n    else\n    {\n        _718 = _713;\n    }\n    float4 c = color;\n    bool _740 = (_680 <= 0.0f) && (ax > (-0.5f));\n    if (_740)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _755 = cos(ax);\n            float _757 = sin(ax);\n            g = ((dot(_627, float2(_755, _757)) / max((abs(_755) * _633) + (abs(_757) * _635), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_669)\n        {\n            float4 _800 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _800;\n            float3 param = _800.xyz;\n            float param_1 = xform.y;\n            float3 _807 = fa_tex_fix(param, param_1);\n            float4 _1499 = c;\n            _1499.x = _807.x;\n            _1499.y = _807.y;\n            _1499.z = _807.z;\n            c = _1499;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _819 = scene_rgb(param_2);\n            float4 _844 = lerp(float4(color.xyz * color.w, color.w), float4(_819 * color2.w, color2.w), g.xxxx);\n            float _846 = _844.w;\n            float3 _849;\n            if (_846 > 9.9999997473787516355514526367188e-06f)\n            {\n                _849 = _844.xyz / _846.xxx;\n            }\n            else\n            {\n                _849 = color.xyz;\n            }\n            c = float4(_849, _846);\n        }\n    }\n    float4 _1508 = c;\n    _1508.w = _1508.w * _718;\n    c = _1508;\n    if (_740 || (shape_rs.y > 0.0f))\n    {\n        float _890 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _899 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _899 + (_890 * 0.0039215688593685626983642578125f).xxx;\n            float3 _905 = fa_srgb_to_linear(param_4);\n            float4 _1511 = c;\n            _1511.x = _905.x;\n            _1511.y = _905.y;\n            _1511.z = _905.z;\n            c = _1511;\n        }\n        else\n        {\n            float4 _915 = c;\n            float3 _918 = _915.xyz + (_890 * 0.0039215688593685626983642578125f).xxx;\n            float4 _1518 = _915;\n            _1518.x = _918.x;\n            _1518.y = _918.y;\n            _1518.z = _918.z;\n            c = _1518;\n        }\n        float4 _1523 = c;\n        _1523.w = clamp(_1523.w + ((_890 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _1523.w)), 0.0f, 1.0f);\n        c = _1523;\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _313 = gl_FragCoord.xy * _306_fa_target.xy;\n    float _317 = _313.y;\n    return float2(_313.x, lerp(_317, 1.0f - _317, _306_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    QuadInput _1472 = { uv, color, world_xy, fa_screen_uv(), _306_fa_time.x, base_mode, 0.0f.xxxx };\n    return _1472;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = clamp(i.time * 0.25f, 0.0f, 1.0f);\n    s.color.y = 0.0f;\n    s.color.z = 0.0f;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _945 = params.x > 31.5f;\n    if (_945)\n    {\n        mode -= 32.0f;\n    }\n    float _953 = mode;\n    bool _955 = _953 > 15.5f;\n    if (_955)\n    {\n        mode -= 16.0f;\n    }\n    float _963 = mode;\n    bool _965 = _963 > 7.5f;\n    if (_965)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_955)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_955)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1029 = tex_color(param_5) * color;\n                float4 param_6 = _1029;\n                float param_7 = mode;\n                frag_color = float4(lit_color(param_6, param_7), _1029.w);\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1065 = length(uv);\n                    float _1068 = fwidth(_1065);\n                    float _1069 = max(_1068, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1065) / _1069) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1065) / _1069) + 0.5f, 0.0f, 1.0f) * clamp(((_1065 - params.y) / _1069) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1110 = clamp(1.0f - _1065, 0.0f, 1.0f);\n                            cov = (_1110 * _1110) * (3.0f - (2.0f * _1110));\n                        }\n                    }\n                    float3 _1119;\n                    if (_955)\n                    {\n                        float4 param_8 = color;\n                        float param_9 = 5.0f;\n                        _1119 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1119 = color.xyz;\n                    }\n                    frag_color = float4(_1119, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface _1456 = { frag_color };\n    QuadSurface param_12 = _1456;\n    fragment(param_11, param_12);\n    frag_color = param_12.color;\n    if (_945)\n    {\n        float4 _1156 = frag_color;\n        float3 param_13 = color2.xyz;\n        float3 _1161 = scene_rgb(param_13);\n        float3 _1165 = lerp(_1156.xyz, _1161, color2.w.xxx);\n        frag_color.x = _1165.x;\n        frag_color.y = _1165.y;\n        frag_color.z = _1165.z;\n    }\n    if (_965)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1189 = _306_fog_col.w > 0.0f;\n    bool _1197;\n    if (!_1189)\n    {\n        _1197 = _306_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1197 = _1189;\n    }\n    if (_1197)\n    {\n        float3 _1211 = float3(world_xy, world_z) - _306_fog_eye.xyz;\n        float _1218 = dot(_1211, _306_fog_c.xyz);\n        bool _1222 = _306_fog_c.w > 0.5f;\n        float _1223;\n        if (_1222)\n        {\n            _1223 = _1218;\n        }\n        else\n        {\n            _1223 = length(_1211);\n        }\n        float _1235 = _1223 - _306_fog_b.x;\n        if (_1235 > 0.0f)\n        {\n            float _1244 = _306_fog_col.w * _1235;\n            float tau = _1244 * _1244;\n            if (_306_fog_b.y > 0.0f)\n            {\n                float _1260;\n                if (_1222)\n                {\n                    _1260 = world_xy.y - (_306_fog_c.y * _1218);\n                }\n                else\n                {\n                    _1260 = _306_fog_eye.y;\n                }\n                float _1281 = lerp(_1260, world_xy.y, clamp(_306_fog_b.x / _1223, 0.0f, 1.0f));\n                float _1285 = world_xy.y - _1281;\n                float _1290 = _1281 - _306_fog_b.z;\n                float _1295 = world_xy.y - _306_fog_b.z;\n                bool _1298 = _1290 <= 0.0f;\n                bool _1299 = !_1298;\n                bool _1305;\n                if (_1299)\n                {\n                    _1305 = _306_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1305 = _1298;\n                }\n                float _1306;\n                if (_1305)\n                {\n                    _1306 = _306_fog_b.y;\n                }\n                else\n                {\n                    _1306 = _306_fog_b.y * exp(-min(_306_fog_b.w * _1290, 80.0f));\n                }\n                bool _1333;\n                if (_1299)\n                {\n                    _1333 = _306_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1333 = _1298;\n                }\n                float _1334;\n                if (_1333)\n                {\n                    _1334 = _306_fog_b.y * _1290;\n                }\n                else\n                {\n                    _1334 = (_306_fog_b.y * (1.0f - exp(-min(_306_fog_b.w * _1290, 80.0f)))) / _306_fog_b.w;\n                }\n                bool _1359 = _1295 <= 0.0f;\n                bool _1366;\n                if (!_1359)\n                {\n                    _1366 = _306_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1366 = _1359;\n                }\n                float _1367;\n                if (_1366)\n                {\n                    _1367 = _306_fog_b.y * _1295;\n                }\n                else\n                {\n                    _1367 = (_306_fog_b.y * (1.0f - exp(-min(_306_fog_b.w * _1295, 80.0f)))) / _306_fog_b.w;\n                }\n                float _1394;\n                if (abs(_1285) < 0.001000000047497451305389404296875f)\n                {\n                    _1394 = _1306;\n                }\n                else\n                {\n                    _1394 = (_1367 - _1334) / _1285;\n                }\n                tau += (_1235 * max(_1394, 0.0f));\n            }\n            float4 _1417 = frag_color;\n            float3 _1425 = lerp(_1417.xyz, _306_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _1425.x;\n            frag_color.y = _1425.y;\n            frag_color.z = _1425.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    params = stage_input.params;\n    shape_half = stage_input.shape_half;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_306",
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
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _144 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _144;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _125_lit : packoffset(c0);\n    float4 _125_ambient : packoffset(c1);\n    float4 _125_normal_uv : packoffset(c2);\n    float4 _125_flat_ambient : packoffset(c3);\n    float4 _125_light_map : packoffset(c4);\n    float4 _125_light_pos[16] : packoffset(c5);\n    float4 _125_light_color[16] : packoffset(c21);\n    float4 _125_light_shadow_v[16] : packoffset(c37);\n    float4 _125_fog_col : packoffset(c53);\n    float4 _125_fog_b : packoffset(c54);\n    float4 _125_fog_c : packoffset(c55);\n    float4 _125_fog_eye : packoffset(c56);\n    float4 _125_fa_time : packoffset(c57);\n    float4 _125_fa_target : packoffset(c58);\n};\n\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float4 frag_color;\nstatic float3 xform;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_half;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _99 = fa_linear_to_srgb(param);\n        c = _99;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _108 = fa_srgb_to_linear(param_1);\n            c = _108;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _132 = gl_FragCoord.xy * _125_fa_target.xy;\n    float _138 = _132.y;\n    return float2(_132.x, lerp(_138, 1.0f - _138, _125_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    QuadInput _288 = { uv, color, world_xy, fa_screen_uv(), _125_fa_time.x, base_mode, 0.0f.xxxx };\n    return _288;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = clamp(i.time * 0.25f, 0.0f, 1.0f);\n    s.color.y = 0.0f;\n    s.color.z = 0.0f;\n}\n\nvoid frag_main()\n{\n    float4 _207 = tex.Sample(smp, uv);\n    float3 param = _207.xyz;\n    float param_1 = xform.y;\n    float3 _219 = fa_tex_fix(param, param_1);\n    frag_color = float4(_219, _207.w) * color;\n    float param_2 = 0.0f;\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _272 = { frag_color };\n    QuadSurface param_4 = _272;\n    fragment(param_3, param_4);\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    xform = stage_input.xform;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_half = stage_input.shape_half;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_125",
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
