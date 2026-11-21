{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "fbbf992817153618419584ba1a09ecc1936ec122cdfee21008275f9dd823a10f",
  "slang": "hlsl5",
  "params": [],
  "textures": [
    "mask"
  ],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _150 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _155 = _150;\n        _155.x = _82.x;\n        _155.y = _82.y;\n        _155.z = _82.z;\n        _150 = _155;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _150;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _308_lit : packoffset(c0);\n    float4 _308_ambient : packoffset(c1);\n    float4 _308_normal_uv : packoffset(c2);\n    float4 _308_flat_ambient : packoffset(c3);\n    float4 _308_light_map : packoffset(c4);\n    float4 _308_light_pos[16] : packoffset(c5);\n    float4 _308_light_color[16] : packoffset(c21);\n    float4 _308_light_shadow_v[16] : packoffset(c37);\n    float4 _308_fog_col : packoffset(c53);\n    float4 _308_fog_b : packoffset(c54);\n    float4 _308_fog_c : packoffset(c55);\n    float4 _308_fog_eye : packoffset(c56);\n    float4 _308_fa_time : packoffset(c57);\n    float4 _308_fa_target : packoffset(c58);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> mask : register(t4);\nSamplerState mask_smp : register(s3);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nSamplerState light_smp : register(s1);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _247 = fa_linear_to_srgb(param);\n        c = _247;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _255 = fa_srgb_to_linear(param_1);\n            c = _255;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _266 = tex.Sample(smp, p);\n    float3 param = _266.xyz;\n    float param_1 = xform.y;\n    float3 _276 = fa_tex_fix(param, param_1);\n    return float4(_276, _266.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _89 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_89.x * 255.0f) + 0.5f) * 256.0f) + floor((_89.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _113 = length(d);\n    if (_113 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _127 = atan2(d.y, d.x);\n    float a = _127;\n    float _130;\n    if (_127 < 0.0f)\n    {\n        _130 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _130 = a;\n    }\n    a = _130;\n    float _142 = _130 * 162.9746551513671875f;\n    float _147 = min(floor(_142), 1023.0f);\n    float _154 = _147 + 1.0f;\n    float i1 = _154;\n    if (_154 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _147;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _113) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _113) + 0.5f, 0.0f, 1.0f), _142 - _147);\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _406 = _308_lit.y > 0.5f;\n    if (_406)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _308_normal_uv.xy) + _308_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _430 = fa_tex_fix(param, param_1);\n        float3 _434 = (_430 * 2.0f) - 1.0f.xxx;\n        float _441 = cos(params.y);\n        float _443 = sin(params.y);\n        n = normalize(float3((float2(_441, _443) * _434.x) + ((float2(-_443, _441) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _434.y), max(_434.z, 0.0500000007450580596923828125f)));\n    }\n    bool _476 = !_406;\n    bool _482;\n    if (_476)\n    {\n        _482 = _308_lit.z > 0.5f;\n    }\n    else\n    {\n        _482 = _476;\n    }\n    float3 _485;\n    if (_482)\n    {\n        _485 = _308_flat_ambient.xyz;\n    }\n    else\n    {\n        _485 = _308_ambient.xyz;\n    }\n    float3 total = _485;\n    bool _502;\n    if (_482)\n    {\n        _502 = _308_lit.z < 1.5f;\n    }\n    else\n    {\n        _502 = _482;\n    }\n    if (_502)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _308_light_map.xy, 0.0f).xyz * _308_light_map.z);\n    }\n    float3 l;\n    float _620;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _542;\n        if (!_482)\n        {\n            _542 = float(i) >= _308_lit.x;\n        }\n        else\n        {\n            _542 = _482;\n        }\n        if (_542)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_308_light_pos[i].w < 0.0f)\n        {\n            l = _308_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _568 = _308_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_568) / max(_308_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _308_light_color[i].w);\n            float3 _588 = float3(_568, _308_light_pos[i].z);\n            l = _588 / max(length(_588), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_308_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _308_light_shadow_v[i].x;\n                float2 param_3 = -_568;\n                float param_4 = _308_light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_406)\n        {\n            _620 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _620 = 1.0f;\n        }\n        total += (_308_light_color[i].xyz * (att * _620));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _293 = fa_srgb_to_linear(param);\n        c = _293;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _648 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _652 = uv * _648;\n    float _658 = _648.x;\n    float _660 = _648.y;\n    float _662 = clamp(shape_rs.x, 0.0f, min(_658, _660));\n    float2 _673 = (abs(_652) - _648) + _662.xx;\n    float d = (length(max(_673, 0.0f.xx)) + min(max(_673.x, _673.y), 0.0f)) - _662;\n    float ax = params.y;\n    bool _694 = params.y > 15.0f;\n    if (_694)\n    {\n        ax -= 20.0f;\n    }\n    float _705;\n    if (ax <= (-1.5f))\n    {\n        _705 = (-2.0f) - ax;\n    }\n    else\n    {\n        _705 = 0.0f;\n    }\n    if (_705 > 0.0f)\n    {\n        float _719 = _705 * 0.5f;\n        d = abs(d + _719) - _719;\n    }\n    float _727 = fwidth(d);\n    float _728 = max(_727, 9.9999997473787516355514526367188e-05f);\n    float _738 = clamp(0.5f - (d / max(shape_rs.y, _728)), 0.0f, 1.0f);\n    float _743;\n    if (shape_rs.y > _728)\n    {\n        _743 = (_738 * _738) * (3.0f - (2.0f * _738));\n    }\n    else\n    {\n        _743 = _738;\n    }\n    float4 c = color;\n    bool _765 = (_705 <= 0.0f) && (ax > (-0.5f));\n    if (_765)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _780 = cos(ax);\n            float _782 = sin(ax);\n            g = ((dot(_652, float2(_780, _782)) / max((abs(_780) * _658) + (abs(_782) * _660), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_694)\n        {\n            float4 _825 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _825;\n            float3 param = _825.xyz;\n            float param_1 = xform.y;\n            float3 _832 = fa_tex_fix(param, param_1);\n            float4 _1528 = c;\n            _1528.x = _832.x;\n            _1528.y = _832.y;\n            _1528.z = _832.z;\n            c = _1528;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _844 = scene_rgb(param_2);\n            float4 _869 = lerp(float4(color.xyz * color.w, color.w), float4(_844 * color2.w, color2.w), g.xxxx);\n            float _871 = _869.w;\n            float3 _874;\n            if (_871 > 9.9999997473787516355514526367188e-06f)\n            {\n                _874 = _869.xyz / _871.xxx;\n            }\n            else\n            {\n                _874 = color.xyz;\n            }\n            c = float4(_874, _871);\n        }\n    }\n    float4 _1537 = c;\n    _1537.w = _1537.w * _743;\n    c = _1537;\n    if (_765 || (shape_rs.y > 0.0f))\n    {\n        float _915 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _924 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _924 + (_915 * 0.0039215688593685626983642578125f).xxx;\n            float3 _930 = fa_srgb_to_linear(param_4);\n            float4 _1540 = c;\n            _1540.x = _930.x;\n            _1540.y = _930.y;\n            _1540.z = _930.z;\n            c = _1540;\n        }\n        else\n        {\n            float4 _940 = c;\n            float3 _943 = _940.xyz + (_915 * 0.0039215688593685626983642578125f).xxx;\n            float4 _1547 = _940;\n            _1547.x = _943.x;\n            _1547.y = _943.y;\n            _1547.z = _943.z;\n            c = _1547;\n        }\n        float4 _1552 = c;\n        _1552.w = clamp(_1552.w + ((_915 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _1552.w)), 0.0f, 1.0f);\n        c = _1552;\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _315 = gl_FragCoord.xy * _308_fa_target.xy;\n    float _319 = _315.y;\n    return float2(_315.x, lerp(_319, 1.0f - _319, _308_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _361 = base_mode < 0.5f;\n    bool _372;\n    if (!_361)\n    {\n        _372 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _372 = _361;\n    }\n    float _373;\n    if (_372)\n    {\n        _373 = shape_half.x;\n    }\n    else\n    {\n        _373 = 0.0f;\n    }\n    QuadInput _1501 = { uv, color, world_xy, fa_screen_uv(), _308_fa_time.x, base_mode, 0.0f.xxxx, _373 };\n    return _1501;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float4 _392 = mask.Sample(mask_smp, 0.0500000007450580596923828125f.xx);\n    s.color.x = _392.x;\n    s.color.y = _392.y;\n    s.color.z = _392.z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _970 = params.x > 31.5f;\n    if (_970)\n    {\n        mode -= 32.0f;\n    }\n    float _978 = mode;\n    bool _980 = _978 > 15.5f;\n    if (_980)\n    {\n        mode -= 16.0f;\n    }\n    float _988 = mode;\n    bool _990 = _988 > 7.5f;\n    if (_990)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_980)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_980)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1054 = tex_color(param_5) * color;\n                float4 param_6 = _1054;\n                float param_7 = mode;\n                frag_color = float4(lit_color(param_6, param_7), _1054.w);\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1089 = length(uv);\n                    float _1092 = fwidth(_1089);\n                    float _1093 = max(_1092, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1089) / _1093) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1089) / _1093) + 0.5f, 0.0f, 1.0f) * clamp(((_1089 - params.y) / _1093) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1133 = clamp(1.0f - _1089, 0.0f, 1.0f);\n                            cov = (_1133 * _1133) * (3.0f - (2.0f * _1133));\n                        }\n                    }\n                    float3 _1142;\n                    if (_980)\n                    {\n                        float4 param_8 = color;\n                        float param_9 = 5.0f;\n                        _1142 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1142 = color.xyz;\n                    }\n                    frag_color = float4(_1142, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1481 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface _1483 = { _1481 };\n    QuadSurface param_12 = _1483;\n    fragment(param_11, param_12);\n    _1481 = param_12.color;\n    frag_color = param_12.color;\n    if (_970)\n    {\n        float4 _1180 = frag_color;\n        float3 param_13 = color2.xyz;\n        float3 _1185 = scene_rgb(param_13);\n        float3 _1189 = lerp(_1180.xyz, _1185, color2.w.xxx);\n        frag_color.x = _1189.x;\n        frag_color.y = _1189.y;\n        frag_color.z = _1189.z;\n    }\n    if (_990)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1213 = _308_fog_col.w > 0.0f;\n    bool _1221;\n    if (!_1213)\n    {\n        _1221 = _308_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1221 = _1213;\n    }\n    if (_1221)\n    {\n        float3 _1235 = float3(world_xy, world_z) - _308_fog_eye.xyz;\n        float _1242 = dot(_1235, _308_fog_c.xyz);\n        bool _1246 = _308_fog_c.w > 0.5f;\n        float _1247;\n        if (_1246)\n        {\n            _1247 = _1242;\n        }\n        else\n        {\n            _1247 = length(_1235);\n        }\n        float _1259 = _1247 - _308_fog_b.x;\n        if (_1259 > 0.0f)\n        {\n            float _1268 = _308_fog_col.w * _1259;\n            float tau = _1268 * _1268;\n            if (_308_fog_b.y > 0.0f)\n            {\n                float _1284;\n                if (_1246)\n                {\n                    _1284 = world_xy.y - (_308_fog_c.y * _1242);\n                }\n                else\n                {\n                    _1284 = _308_fog_eye.y;\n                }\n                float _1305 = lerp(_1284, world_xy.y, clamp(_308_fog_b.x / _1247, 0.0f, 1.0f));\n                float _1309 = world_xy.y - _1305;\n                float _1314 = _1305 - _308_fog_b.z;\n                float _1319 = world_xy.y - _308_fog_b.z;\n                bool _1322 = _1314 <= 0.0f;\n                bool _1323 = !_1322;\n                bool _1329;\n                if (_1323)\n                {\n                    _1329 = _308_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1329 = _1322;\n                }\n                float _1330;\n                if (_1329)\n                {\n                    _1330 = _308_fog_b.y;\n                }\n                else\n                {\n                    _1330 = _308_fog_b.y * exp(-min(_308_fog_b.w * _1314, 80.0f));\n                }\n                bool _1357;\n                if (_1323)\n                {\n                    _1357 = _308_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1357 = _1322;\n                }\n                float _1358;\n                if (_1357)\n                {\n                    _1358 = _308_fog_b.y * _1314;\n                }\n                else\n                {\n                    _1358 = (_308_fog_b.y * (1.0f - exp(-min(_308_fog_b.w * _1314, 80.0f)))) / _308_fog_b.w;\n                }\n                bool _1383 = _1319 <= 0.0f;\n                bool _1390;\n                if (!_1383)\n                {\n                    _1390 = _308_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1390 = _1383;\n                }\n                float _1391;\n                if (_1390)\n                {\n                    _1391 = _308_fog_b.y * _1319;\n                }\n                else\n                {\n                    _1391 = (_308_fog_b.y * (1.0f - exp(-min(_308_fog_b.w * _1319, 80.0f)))) / _308_fog_b.w;\n                }\n                float _1418;\n                if (abs(_1309) < 0.001000000047497451305389404296875f)\n                {\n                    _1418 = _1330;\n                }\n                else\n                {\n                    _1418 = (_1391 - _1358) / _1309;\n                }\n                tau += (_1259 * max(_1418, 0.0f));\n            }\n            float4 _1441 = frag_color;\n            float3 _1449 = lerp(_1441.xyz, _308_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _1449.x;\n            frag_color.y = _1449.y;\n            frag_color.z = _1449.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _150 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _155 = _150;\n        _155.x = _82.x;\n        _155.y = _82.y;\n        _155.z = _82.z;\n        _150 = _155;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _150;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _127_lit : packoffset(c0);\n    float4 _127_ambient : packoffset(c1);\n    float4 _127_normal_uv : packoffset(c2);\n    float4 _127_flat_ambient : packoffset(c3);\n    float4 _127_light_map : packoffset(c4);\n    float4 _127_light_pos[16] : packoffset(c5);\n    float4 _127_light_color[16] : packoffset(c21);\n    float4 _127_light_shadow_v[16] : packoffset(c37);\n    float4 _127_fog_col : packoffset(c53);\n    float4 _127_fog_b : packoffset(c54);\n    float4 _127_fog_c : packoffset(c55);\n    float4 _127_fog_eye : packoffset(c56);\n    float4 _127_fa_time : packoffset(c57);\n    float4 _127_fa_target : packoffset(c58);\n};\n\nTexture2D<float4> mask : register(t1);\nSamplerState mask_smp : register(s3);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 frag_color;\nstatic float3 xform;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _134 = gl_FragCoord.xy * _127_fa_target.xy;\n    float _140 = _134.y;\n    return float2(_134.x, lerp(_140, 1.0f - _140, _127_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _184 = base_mode < 0.5f;\n    bool _195;\n    if (!_184)\n    {\n        _195 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _195 = _184;\n    }\n    float _196;\n    if (_195)\n    {\n        _196 = shape_half.x;\n    }\n    else\n    {\n        _196 = 0.0f;\n    }\n    QuadInput _321 = { uv, color, world_xy, fa_screen_uv(), _127_fa_time.x, base_mode, 0.0f.xxxx, _196 };\n    return _321;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float4 _221 = mask.Sample(mask_smp, 0.0500000007450580596923828125f.xx);\n    s.color.x = _221.x;\n    s.color.y = _221.y;\n    s.color.z = _221.z;\n}\n\nvoid frag_main()\n{\n    float4 _236 = tex.Sample(smp, uv);\n    float3 param = _236.xyz;\n    float param_1 = xform.y;\n    float3 _247 = fa_tex_fix(param, param_1);\n    frag_color = float4(_247, _236.w) * color;\n    float param_2 = 0.0f;\n    float4 _301 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _303 = { _301 };\n    QuadSurface param_4 = _303;\n    fragment(param_3, param_4);\n    _301 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    xform = stage_input.xform;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
          }
        ],
        "samplers": [
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
