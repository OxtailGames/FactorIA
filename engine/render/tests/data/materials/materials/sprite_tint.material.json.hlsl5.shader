{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "92b6737b88986088c23ec149effb731593899af4f139a1a2f6aa207cd28c4169",
  "slang": "hlsl5",
  "params": [
    "tint"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _147 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _147;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _317_lit : packoffset(c0);\n    float4 _317_ambient : packoffset(c1);\n    float4 _317_normal_uv : packoffset(c2);\n    float4 _317_flat_ambient : packoffset(c3);\n    float4 _317_light_map : packoffset(c4);\n    float4 _317_light_pos[16] : packoffset(c5);\n    float4 _317_light_color[16] : packoffset(c21);\n    float4 _317_light_shadow_v[16] : packoffset(c37);\n    float4 _317_fog_col : packoffset(c53);\n    float4 _317_fog_b : packoffset(c54);\n    float4 _317_fog_c : packoffset(c55);\n    float4 _317_fog_eye : packoffset(c56);\n    float4 _317_fa_time : packoffset(c57);\n    float4 _317_fa_target : packoffset(c58);\n    float4 _317_fa_scene : packoffset(c59);\n    float4 _317_fa_world_uv[3] : packoffset(c60);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _396_tint : packoffset(c0);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nSamplerState light_smp : register(s1);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _250 = fa_linear_to_srgb(param);\n        c = _250;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _258 = fa_srgb_to_linear(param_1);\n            c = _258;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _269 = tex.Sample(smp, p);\n    float3 param = _269.xyz;\n    float param_1 = xform.y;\n    float3 _279 = fa_tex_fix(param, param_1);\n    return float4(_279, _269.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _92 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_92.x * 255.0f) + 0.5f) * 256.0f) + floor((_92.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _116 = length(d);\n    if (_116 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _130 = atan2(d.y, d.x);\n    float a = _130;\n    float _133;\n    if (_130 < 0.0f)\n    {\n        _133 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _133 = a;\n    }\n    a = _133;\n    float _145 = _133 * 162.9746551513671875f;\n    float _150 = min(floor(_145), 1023.0f);\n    float _157 = _150 + 1.0f;\n    float i1 = _157;\n    if (_157 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _150;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _116) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _116) + 0.5f, 0.0f, 1.0f), _145 - _150);\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _418 = _317_lit.y > 0.5f;\n    if (_418)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _317_normal_uv.xy) + _317_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _442 = fa_tex_fix(param, param_1);\n        float3 _446 = (_442 * 2.0f) - 1.0f.xxx;\n        float _453 = cos(params.y);\n        float _455 = sin(params.y);\n        n = normalize(float3((float2(_453, _455) * _446.x) + ((float2(-_455, _453) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _446.y), max(_446.z, 0.0500000007450580596923828125f)));\n    }\n    bool _489 = !_418;\n    bool _495;\n    if (_489)\n    {\n        _495 = _317_lit.z > 0.5f;\n    }\n    else\n    {\n        _495 = _489;\n    }\n    float3 _498;\n    if (_495)\n    {\n        _498 = _317_flat_ambient.xyz;\n    }\n    else\n    {\n        _498 = _317_ambient.xyz;\n    }\n    float3 total = _498;\n    bool _515;\n    if (_495)\n    {\n        _515 = _317_lit.z < 1.5f;\n    }\n    else\n    {\n        _515 = _495;\n    }\n    if (_515)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _317_light_map.xy, 0.0f).xyz * _317_light_map.z);\n    }\n    float3 l;\n    float _633;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _555;\n        if (!_495)\n        {\n            _555 = float(i) >= _317_lit.x;\n        }\n        else\n        {\n            _555 = _495;\n        }\n        if (_555)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_317_light_pos[i].w < 0.0f)\n        {\n            l = _317_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _581 = _317_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_581) / max(_317_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _317_light_color[i].w);\n            float3 _601 = float3(_581, _317_light_pos[i].z);\n            l = _601 / max(length(_601), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_317_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _317_light_shadow_v[i].x;\n                float2 param_3 = -_581;\n                float param_4 = _317_light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_418)\n        {\n            _633 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _633 = 1.0f;\n        }\n        total += (_317_light_color[i].xyz * (att * _633));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _296 = fa_srgb_to_linear(param);\n        c = _296;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _661 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _665 = uv * _661;\n    float _671 = _661.x;\n    float _673 = _661.y;\n    float _675 = clamp(shape_rs.x, 0.0f, min(_671, _673));\n    float2 _686 = (abs(_665) - _661) + _675.xx;\n    float d = (length(max(_686, 0.0f.xx)) + min(max(_686.x, _686.y), 0.0f)) - _675;\n    float ax = params.y;\n    bool _707 = params.y > 15.0f;\n    if (_707)\n    {\n        ax -= 20.0f;\n    }\n    float _718;\n    if (ax <= (-1.5f))\n    {\n        _718 = (-2.0f) - ax;\n    }\n    else\n    {\n        _718 = 0.0f;\n    }\n    if (_718 > 0.0f)\n    {\n        float _732 = _718 * 0.5f;\n        d = abs(d + _732) - _732;\n    }\n    float _740 = fwidth(d);\n    float _741 = max(_740, 9.9999997473787516355514526367188e-05f);\n    float _751 = clamp(0.5f - (d / max(shape_rs.y, _741)), 0.0f, 1.0f);\n    float _756;\n    if (shape_rs.y > _741)\n    {\n        _756 = (_751 * _751) * (3.0f - (2.0f * _751));\n    }\n    else\n    {\n        _756 = _751;\n    }\n    float4 c = color;\n    bool _778 = (_718 <= 0.0f) && (ax > (-0.5f));\n    if (_778)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _793 = cos(ax);\n            float _795 = sin(ax);\n            g = ((dot(_665, float2(_793, _795)) / max((abs(_793) * _671) + (abs(_795) * _673), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_707)\n        {\n            float4 _838 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _838;\n            float3 param = _838.xyz;\n            float param_1 = xform.y;\n            float3 _845 = fa_tex_fix(param, param_1);\n            float4 _1542 = c;\n            _1542.x = _845.x;\n            _1542.y = _845.y;\n            _1542.z = _845.z;\n            c = _1542;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _857 = scene_rgb(param_2);\n            float4 _882 = lerp(float4(color.xyz * color.w, color.w), float4(_857 * color2.w, color2.w), g.xxxx);\n            float _884 = _882.w;\n            float3 _887;\n            if (_884 > 9.9999997473787516355514526367188e-06f)\n            {\n                _887 = _882.xyz / _884.xxx;\n            }\n            else\n            {\n                _887 = color.xyz;\n            }\n            c = float4(_887, _884);\n        }\n    }\n    float4 _1551 = c;\n    _1551.w = _1551.w * _756;\n    c = _1551;\n    if (_778 || (shape_rs.y > 0.0f))\n    {\n        float _928 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _937 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _937 + (_928 * 0.0039215688593685626983642578125f).xxx;\n            float3 _943 = fa_srgb_to_linear(param_4);\n            float4 _1554 = c;\n            _1554.x = _943.x;\n            _1554.y = _943.y;\n            _1554.z = _943.z;\n            c = _1554;\n        }\n        else\n        {\n            float4 _953 = c;\n            float3 _956 = _953.xyz + (_928 * 0.0039215688593685626983642578125f).xxx;\n            float4 _1561 = _953;\n            _1561.x = _956.x;\n            _1561.y = _956.y;\n            _1561.z = _956.z;\n            c = _1561;\n        }\n        float4 _1566 = c;\n        _1566.w = clamp(_1566.w + ((_928 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _1566.w)), 0.0f, 1.0f);\n        c = _1566;\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _324 = gl_FragCoord.xy * _317_fa_target.xy;\n    float _328 = _324.y;\n    return float2(_324.x, lerp(_328, 1.0f - _328, _317_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _370 = base_mode < 0.5f;\n    bool _381;\n    if (!_370)\n    {\n        _381 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _381 = _370;\n    }\n    float _382;\n    if (_381)\n    {\n        _382 = shape_half.x;\n    }\n    else\n    {\n        _382 = 0.0f;\n    }\n    QuadInput _1515 = { uv, color, world_xy, fa_screen_uv(), _317_fa_time.x, base_mode, 0.0f.xxxx, _382 };\n    return _1515;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _302 = scene_rgb(param);\n    return _302;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = _396_tint.xyz;\n    float4 _403 = s.color;\n    float3 _405 = _403.xyz * fa_scene_rgb(param);\n    s.color.x = _405.x;\n    s.color.y = _405.y;\n    s.color.z = _405.z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _983 = params.x > 31.5f;\n    if (_983)\n    {\n        mode -= 32.0f;\n    }\n    float _991 = mode;\n    bool _993 = _991 > 15.5f;\n    if (_993)\n    {\n        mode -= 16.0f;\n    }\n    float _1001 = mode;\n    bool _1003 = _1001 > 7.5f;\n    if (_1003)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_993)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_993)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1067 = tex_color(param_5) * color;\n                float4 param_6 = _1067;\n                float param_7 = mode;\n                frag_color = float4(lit_color(param_6, param_7), _1067.w);\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1102 = length(uv);\n                    float _1105 = fwidth(_1102);\n                    float _1106 = max(_1105, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1102) / _1106) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1102) / _1106) + 0.5f, 0.0f, 1.0f) * clamp(((_1102 - params.y) / _1106) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1146 = clamp(1.0f - _1102, 0.0f, 1.0f);\n                            cov = (_1146 * _1146) * (3.0f - (2.0f * _1146));\n                        }\n                    }\n                    float3 _1155;\n                    if (_993)\n                    {\n                        float4 param_8 = color;\n                        float param_9 = 5.0f;\n                        _1155 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1155 = color.xyz;\n                    }\n                    frag_color = float4(_1155, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1495 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface _1497 = { _1495 };\n    QuadSurface param_12 = _1497;\n    fragment(param_11, param_12);\n    _1495 = param_12.color;\n    frag_color = param_12.color;\n    if (_983)\n    {\n        float4 _1193 = frag_color;\n        float3 param_13 = color2.xyz;\n        float3 _1198 = scene_rgb(param_13);\n        float3 _1202 = lerp(_1193.xyz, _1198, color2.w.xxx);\n        frag_color.x = _1202.x;\n        frag_color.y = _1202.y;\n        frag_color.z = _1202.z;\n    }\n    if (_1003)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1226 = _317_fog_col.w > 0.0f;\n    bool _1234;\n    if (!_1226)\n    {\n        _1234 = _317_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1234 = _1226;\n    }\n    if (_1234)\n    {\n        float3 _1248 = float3(world_xy, world_z) - _317_fog_eye.xyz;\n        float _1255 = dot(_1248, _317_fog_c.xyz);\n        bool _1259 = _317_fog_c.w > 0.5f;\n        float _1260;\n        if (_1259)\n        {\n            _1260 = _1255;\n        }\n        else\n        {\n            _1260 = length(_1248);\n        }\n        float _1272 = _1260 - _317_fog_b.x;\n        if (_1272 > 0.0f)\n        {\n            float _1281 = _317_fog_col.w * _1272;\n            float tau = _1281 * _1281;\n            if (_317_fog_b.y > 0.0f)\n            {\n                float _1297;\n                if (_1259)\n                {\n                    _1297 = world_xy.y - (_317_fog_c.y * _1255);\n                }\n                else\n                {\n                    _1297 = _317_fog_eye.y;\n                }\n                float _1318 = lerp(_1297, world_xy.y, clamp(_317_fog_b.x / _1260, 0.0f, 1.0f));\n                float _1322 = world_xy.y - _1318;\n                float _1327 = _1318 - _317_fog_b.z;\n                float _1332 = world_xy.y - _317_fog_b.z;\n                bool _1335 = _1327 <= 0.0f;\n                bool _1336 = !_1335;\n                bool _1342;\n                if (_1336)\n                {\n                    _1342 = _317_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1342 = _1335;\n                }\n                float _1343;\n                if (_1342)\n                {\n                    _1343 = _317_fog_b.y;\n                }\n                else\n                {\n                    _1343 = _317_fog_b.y * exp(-min(_317_fog_b.w * _1327, 80.0f));\n                }\n                bool _1370;\n                if (_1336)\n                {\n                    _1370 = _317_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1370 = _1335;\n                }\n                float _1371;\n                if (_1370)\n                {\n                    _1371 = _317_fog_b.y * _1327;\n                }\n                else\n                {\n                    _1371 = (_317_fog_b.y * (1.0f - exp(-min(_317_fog_b.w * _1327, 80.0f)))) / _317_fog_b.w;\n                }\n                bool _1396 = _1332 <= 0.0f;\n                bool _1403;\n                if (!_1396)\n                {\n                    _1403 = _317_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1403 = _1396;\n                }\n                float _1404;\n                if (_1403)\n                {\n                    _1404 = _317_fog_b.y * _1332;\n                }\n                else\n                {\n                    _1404 = (_317_fog_b.y * (1.0f - exp(-min(_317_fog_b.w * _1332, 80.0f)))) / _317_fog_b.w;\n                }\n                float _1431;\n                if (abs(_1322) < 0.001000000047497451305389404296875f)\n                {\n                    _1431 = _1343;\n                }\n                else\n                {\n                    _1431 = (_1404 - _1371) / _1322;\n                }\n                tau += (_1272 * max(_1431, 0.0f));\n            }\n            float4 _1454 = frag_color;\n            float3 _1462 = lerp(_1454.xyz, _317_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _1462.x;\n            frag_color.y = _1462.y;\n            frag_color.z = _1462.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_317",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_396",
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
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _155_lit : packoffset(c0);\n    float4 _155_ambient : packoffset(c1);\n    float4 _155_normal_uv : packoffset(c2);\n    float4 _155_flat_ambient : packoffset(c3);\n    float4 _155_light_map : packoffset(c4);\n    float4 _155_light_pos[16] : packoffset(c5);\n    float4 _155_light_color[16] : packoffset(c21);\n    float4 _155_light_shadow_v[16] : packoffset(c37);\n    float4 _155_fog_col : packoffset(c53);\n    float4 _155_fog_b : packoffset(c54);\n    float4 _155_fog_c : packoffset(c55);\n    float4 _155_fog_eye : packoffset(c56);\n    float4 _155_fa_time : packoffset(c57);\n    float4 _155_fa_target : packoffset(c58);\n    float4 _155_fa_scene : packoffset(c59);\n    float4 _155_fa_world_uv[3] : packoffset(c60);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _237_tint : packoffset(c0);\n};\n\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 frag_color;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _107 = fa_linear_to_srgb(param);\n        c = _107;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _116 = fa_srgb_to_linear(param_1);\n            c = _116;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _162 = gl_FragCoord.xy * _155_fa_target.xy;\n    float _167 = _162.y;\n    return float2(_162.x, lerp(_167, 1.0f - _167, _155_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _211 = base_mode < 0.5f;\n    bool _222;\n    if (!_211)\n    {\n        _222 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _222 = _211;\n    }\n    float _223;\n    if (_222)\n    {\n        _223 = shape_half.x;\n    }\n    else\n    {\n        _223 = 0.0f;\n    }\n    QuadInput _349 = { uv, color, world_xy, fa_screen_uv(), _155_fa_time.x, base_mode, 0.0f.xxxx, _223 };\n    return _349;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _132 = fa_srgb_to_linear(param);\n        c = _132;\n    }\n    return c;\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _138 = scene_rgb(param);\n    return _138;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = _237_tint.xyz;\n    float4 _244 = s.color;\n    float3 _246 = _244.xyz * fa_scene_rgb(param);\n    s.color.x = _246.x;\n    s.color.y = _246.y;\n    s.color.z = _246.z;\n}\n\nvoid frag_main()\n{\n    float4 _265 = tex.Sample(smp, uv);\n    float3 param = _265.xyz;\n    float param_1 = xform.y;\n    float3 _274 = fa_tex_fix(param, param_1);\n    frag_color = float4(_274, _265.w) * color;\n    float param_2 = 0.0f;\n    float4 _329 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _331 = { _329 };\n    QuadSurface param_4 = _331;\n    fragment(param_3, param_4);\n    _329 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_155",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_237",
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
