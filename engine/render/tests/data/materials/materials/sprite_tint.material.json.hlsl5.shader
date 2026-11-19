{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "ed7d6aa4bb6587a53460bdad882f96cecc84c68276eec459c73c25f578a29fd8",
  "slang": "hlsl5",
  "params": [
    "tint"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _147 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _147;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _314_lit : packoffset(c0);\n    float4 _314_ambient : packoffset(c1);\n    float4 _314_normal_uv : packoffset(c2);\n    float4 _314_flat_ambient : packoffset(c3);\n    float4 _314_light_map : packoffset(c4);\n    float4 _314_light_pos[16] : packoffset(c5);\n    float4 _314_light_color[16] : packoffset(c21);\n    float4 _314_light_shadow_v[16] : packoffset(c37);\n    float4 _314_fog_col : packoffset(c53);\n    float4 _314_fog_b : packoffset(c54);\n    float4 _314_fog_c : packoffset(c55);\n    float4 _314_fog_eye : packoffset(c56);\n    float4 _314_fa_time : packoffset(c57);\n    float4 _314_fa_target : packoffset(c58);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _370_tint : packoffset(c0);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nSamplerState light_smp : register(s1);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 params;\nstatic float2 shape_half;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _248 = fa_linear_to_srgb(param);\n        c = _248;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _256 = fa_srgb_to_linear(param_1);\n            c = _256;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _267 = tex.Sample(smp, p);\n    float3 param = _267.xyz;\n    float param_1 = xform.y;\n    float3 _277 = fa_tex_fix(param, param_1);\n    return float4(_277, _267.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _90 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_90.x * 255.0f) + 0.5f) * 256.0f) + floor((_90.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _114 = length(d);\n    if (_114 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _128 = atan2(d.y, d.x);\n    float a = _128;\n    float _131;\n    if (_128 < 0.0f)\n    {\n        _131 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _131 = a;\n    }\n    a = _131;\n    float _143 = _131 * 162.9746551513671875f;\n    float _148 = min(floor(_143), 1023.0f);\n    float _155 = _148 + 1.0f;\n    float i1 = _155;\n    if (_155 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _148;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _114) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _114) + 0.5f, 0.0f, 1.0f), _143 - _148);\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _392 = _314_lit.y > 0.5f;\n    if (_392)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _314_normal_uv.xy) + _314_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _416 = fa_tex_fix(param, param_1);\n        float3 _420 = (_416 * 2.0f) - 1.0f.xxx;\n        float _427 = cos(params.y);\n        float _429 = sin(params.y);\n        n = normalize(float3((float2(_427, _429) * _420.x) + ((float2(-_429, _427) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _420.y), max(_420.z, 0.0500000007450580596923828125f)));\n    }\n    bool _463 = !_392;\n    bool _469;\n    if (_463)\n    {\n        _469 = _314_lit.z > 0.5f;\n    }\n    else\n    {\n        _469 = _463;\n    }\n    float3 _472;\n    if (_469)\n    {\n        _472 = _314_flat_ambient.xyz;\n    }\n    else\n    {\n        _472 = _314_ambient.xyz;\n    }\n    float3 total = _472;\n    bool _489;\n    if (_469)\n    {\n        _489 = _314_lit.z < 1.5f;\n    }\n    else\n    {\n        _489 = _469;\n    }\n    if (_489)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _314_light_map.xy, 0.0f).xyz * _314_light_map.z);\n    }\n    float3 l;\n    float _608;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _529;\n        if (!_469)\n        {\n            _529 = float(i) >= _314_lit.x;\n        }\n        else\n        {\n            _529 = _469;\n        }\n        if (_529)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_314_light_pos[i].w < 0.0f)\n        {\n            l = _314_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _555 = _314_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_555) / max(_314_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _314_light_color[i].w);\n            float3 _575 = float3(_555, _314_light_pos[i].z);\n            l = _575 / max(length(_575), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_314_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _314_light_shadow_v[i].x;\n                float2 param_3 = -_555;\n                float param_4 = _314_light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_392)\n        {\n            _608 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _608 = 1.0f;\n        }\n        total += (_314_light_color[i].xyz * (att * _608));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _294 = fa_srgb_to_linear(param);\n        c = _294;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _637 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _641 = uv * _637;\n    float _647 = _637.x;\n    float _649 = _637.y;\n    float _651 = clamp(shape_rs.x, 0.0f, min(_647, _649));\n    float2 _662 = (abs(_641) - _637) + _651.xx;\n    float d = (length(max(_662, 0.0f.xx)) + min(max(_662.x, _662.y), 0.0f)) - _651;\n    float ax = params.y;\n    bool _683 = params.y > 15.0f;\n    if (_683)\n    {\n        ax -= 20.0f;\n    }\n    float _694;\n    if (ax <= (-1.5f))\n    {\n        _694 = (-2.0f) - ax;\n    }\n    else\n    {\n        _694 = 0.0f;\n    }\n    if (_694 > 0.0f)\n    {\n        float _708 = _694 * 0.5f;\n        d = abs(d + _708) - _708;\n    }\n    float _716 = fwidth(d);\n    float _717 = max(_716, 9.9999997473787516355514526367188e-05f);\n    float _727 = clamp(0.5f - (d / max(shape_rs.y, _717)), 0.0f, 1.0f);\n    float _732;\n    if (shape_rs.y > _717)\n    {\n        _732 = (_727 * _727) * (3.0f - (2.0f * _727));\n    }\n    else\n    {\n        _732 = _727;\n    }\n    float4 c = color;\n    bool _754 = (_694 <= 0.0f) && (ax > (-0.5f));\n    if (_754)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _769 = cos(ax);\n            float _771 = sin(ax);\n            g = ((dot(_641, float2(_769, _771)) / max((abs(_769) * _647) + (abs(_771) * _649), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_683)\n        {\n            float4 _814 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _814;\n            float3 param = _814.xyz;\n            float param_1 = xform.y;\n            float3 _821 = fa_tex_fix(param, param_1);\n            float4 _1513 = c;\n            _1513.x = _821.x;\n            _1513.y = _821.y;\n            _1513.z = _821.z;\n            c = _1513;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _833 = scene_rgb(param_2);\n            float4 _858 = lerp(float4(color.xyz * color.w, color.w), float4(_833 * color2.w, color2.w), g.xxxx);\n            float _860 = _858.w;\n            float3 _863;\n            if (_860 > 9.9999997473787516355514526367188e-06f)\n            {\n                _863 = _858.xyz / _860.xxx;\n            }\n            else\n            {\n                _863 = color.xyz;\n            }\n            c = float4(_863, _860);\n        }\n    }\n    float4 _1522 = c;\n    _1522.w = _1522.w * _732;\n    c = _1522;\n    if (_754 || (shape_rs.y > 0.0f))\n    {\n        float _904 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _913 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _913 + (_904 * 0.0039215688593685626983642578125f).xxx;\n            float3 _919 = fa_srgb_to_linear(param_4);\n            float4 _1525 = c;\n            _1525.x = _919.x;\n            _1525.y = _919.y;\n            _1525.z = _919.z;\n            c = _1525;\n        }\n        else\n        {\n            float4 _929 = c;\n            float3 _932 = _929.xyz + (_904 * 0.0039215688593685626983642578125f).xxx;\n            float4 _1532 = _929;\n            _1532.x = _932.x;\n            _1532.y = _932.y;\n            _1532.z = _932.z;\n            c = _1532;\n        }\n        float4 _1537 = c;\n        _1537.w = clamp(_1537.w + ((_904 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _1537.w)), 0.0f, 1.0f);\n        c = _1537;\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _321 = gl_FragCoord.xy * _314_fa_target.xy;\n    float _325 = _321.y;\n    return float2(_321.x, lerp(_325, 1.0f - _325, _314_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    QuadInput _1486 = { uv, color, world_xy, fa_screen_uv(), _314_fa_time.x, base_mode, 0.0f.xxxx };\n    return _1486;\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _300 = scene_rgb(param);\n    return _300;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = _370_tint.xyz;\n    float4 _377 = s.color;\n    float3 _379 = _377.xyz * fa_scene_rgb(param);\n    s.color.x = _379.x;\n    s.color.y = _379.y;\n    s.color.z = _379.z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _959 = params.x > 31.5f;\n    if (_959)\n    {\n        mode -= 32.0f;\n    }\n    float _967 = mode;\n    bool _969 = _967 > 15.5f;\n    if (_969)\n    {\n        mode -= 16.0f;\n    }\n    float _977 = mode;\n    bool _979 = _977 > 7.5f;\n    if (_979)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_969)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_969)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1043 = tex_color(param_5) * color;\n                float4 param_6 = _1043;\n                float param_7 = mode;\n                frag_color = float4(lit_color(param_6, param_7), _1043.w);\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1079 = length(uv);\n                    float _1082 = fwidth(_1079);\n                    float _1083 = max(_1082, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1079) / _1083) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1079) / _1083) + 0.5f, 0.0f, 1.0f) * clamp(((_1079 - params.y) / _1083) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1124 = clamp(1.0f - _1079, 0.0f, 1.0f);\n                            cov = (_1124 * _1124) * (3.0f - (2.0f * _1124));\n                        }\n                    }\n                    float3 _1133;\n                    if (_969)\n                    {\n                        float4 param_8 = color;\n                        float param_9 = 5.0f;\n                        _1133 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1133 = color.xyz;\n                    }\n                    frag_color = float4(_1133, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface _1470 = { frag_color };\n    QuadSurface param_12 = _1470;\n    fragment(param_11, param_12);\n    frag_color = param_12.color;\n    if (_959)\n    {\n        float4 _1170 = frag_color;\n        float3 param_13 = color2.xyz;\n        float3 _1175 = scene_rgb(param_13);\n        float3 _1179 = lerp(_1170.xyz, _1175, color2.w.xxx);\n        frag_color.x = _1179.x;\n        frag_color.y = _1179.y;\n        frag_color.z = _1179.z;\n    }\n    if (_979)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1203 = _314_fog_col.w > 0.0f;\n    bool _1211;\n    if (!_1203)\n    {\n        _1211 = _314_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1211 = _1203;\n    }\n    if (_1211)\n    {\n        float3 _1225 = float3(world_xy, world_z) - _314_fog_eye.xyz;\n        float _1232 = dot(_1225, _314_fog_c.xyz);\n        bool _1236 = _314_fog_c.w > 0.5f;\n        float _1237;\n        if (_1236)\n        {\n            _1237 = _1232;\n        }\n        else\n        {\n            _1237 = length(_1225);\n        }\n        float _1249 = _1237 - _314_fog_b.x;\n        if (_1249 > 0.0f)\n        {\n            float _1258 = _314_fog_col.w * _1249;\n            float tau = _1258 * _1258;\n            if (_314_fog_b.y > 0.0f)\n            {\n                float _1274;\n                if (_1236)\n                {\n                    _1274 = world_xy.y - (_314_fog_c.y * _1232);\n                }\n                else\n                {\n                    _1274 = _314_fog_eye.y;\n                }\n                float _1295 = lerp(_1274, world_xy.y, clamp(_314_fog_b.x / _1237, 0.0f, 1.0f));\n                float _1299 = world_xy.y - _1295;\n                float _1304 = _1295 - _314_fog_b.z;\n                float _1309 = world_xy.y - _314_fog_b.z;\n                bool _1312 = _1304 <= 0.0f;\n                bool _1313 = !_1312;\n                bool _1319;\n                if (_1313)\n                {\n                    _1319 = _314_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1319 = _1312;\n                }\n                float _1320;\n                if (_1319)\n                {\n                    _1320 = _314_fog_b.y;\n                }\n                else\n                {\n                    _1320 = _314_fog_b.y * exp(-min(_314_fog_b.w * _1304, 80.0f));\n                }\n                bool _1347;\n                if (_1313)\n                {\n                    _1347 = _314_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1347 = _1312;\n                }\n                float _1348;\n                if (_1347)\n                {\n                    _1348 = _314_fog_b.y * _1304;\n                }\n                else\n                {\n                    _1348 = (_314_fog_b.y * (1.0f - exp(-min(_314_fog_b.w * _1304, 80.0f)))) / _314_fog_b.w;\n                }\n                bool _1373 = _1309 <= 0.0f;\n                bool _1380;\n                if (!_1373)\n                {\n                    _1380 = _314_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1380 = _1373;\n                }\n                float _1381;\n                if (_1380)\n                {\n                    _1381 = _314_fog_b.y * _1309;\n                }\n                else\n                {\n                    _1381 = (_314_fog_b.y * (1.0f - exp(-min(_314_fog_b.w * _1309, 80.0f)))) / _314_fog_b.w;\n                }\n                float _1408;\n                if (abs(_1299) < 0.001000000047497451305389404296875f)\n                {\n                    _1408 = _1320;\n                }\n                else\n                {\n                    _1408 = (_1381 - _1348) / _1299;\n                }\n                tau += (_1249 * max(_1408, 0.0f));\n            }\n            float4 _1431 = frag_color;\n            float3 _1439 = lerp(_1431.xyz, _314_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _1439.x;\n            frag_color.y = _1439.y;\n            frag_color.z = _1439.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    params = stage_input.params;\n    shape_half = stage_input.shape_half;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_314",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_370",
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
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _151_lit : packoffset(c0);\n    float4 _151_ambient : packoffset(c1);\n    float4 _151_normal_uv : packoffset(c2);\n    float4 _151_flat_ambient : packoffset(c3);\n    float4 _151_light_map : packoffset(c4);\n    float4 _151_light_pos[16] : packoffset(c5);\n    float4 _151_light_color[16] : packoffset(c21);\n    float4 _151_light_shadow_v[16] : packoffset(c37);\n    float4 _151_fog_col : packoffset(c53);\n    float4 _151_fog_b : packoffset(c54);\n    float4 _151_fog_c : packoffset(c55);\n    float4 _151_fog_eye : packoffset(c56);\n    float4 _151_fa_time : packoffset(c57);\n    float4 _151_fa_target : packoffset(c58);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _210_tint : packoffset(c0);\n};\n\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float4 frag_color;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_half;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _105 = fa_linear_to_srgb(param);\n        c = _105;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _114 = fa_srgb_to_linear(param_1);\n            c = _114;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _158 = gl_FragCoord.xy * _151_fa_target.xy;\n    float _163 = _158.y;\n    return float2(_158.x, lerp(_163, 1.0f - _163, _151_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    QuadInput _316 = { uv, color, world_xy, fa_screen_uv(), _151_fa_time.x, base_mode, 0.0f.xxxx };\n    return _316;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _130 = fa_srgb_to_linear(param);\n        c = _130;\n    }\n    return c;\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _136 = scene_rgb(param);\n    return _136;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = _210_tint.xyz;\n    float4 _217 = s.color;\n    float3 _219 = _217.xyz * fa_scene_rgb(param);\n    s.color.x = _219.x;\n    s.color.y = _219.y;\n    s.color.z = _219.z;\n}\n\nvoid frag_main()\n{\n    float4 _238 = tex.Sample(smp, uv);\n    float3 param = _238.xyz;\n    float param_1 = xform.y;\n    float3 _247 = fa_tex_fix(param, param_1);\n    frag_color = float4(_247, _238.w) * color;\n    float param_2 = 0.0f;\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _300 = { frag_color };\n    QuadSurface param_4 = _300;\n    fragment(param_3, param_4);\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_half = stage_input.shape_half;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_151",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_210",
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
