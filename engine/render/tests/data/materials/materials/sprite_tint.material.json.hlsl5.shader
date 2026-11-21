{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "dbae68a2cd91807fd7df084cee13eb559f2382809eb1ac9d2df2d325d7943acc",
  "slang": "hlsl5",
  "params": [
    "tint"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _147 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _147;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _437_lit : packoffset(c0);\n    float4 _437_ambient : packoffset(c1);\n    float4 _437_normal_uv : packoffset(c2);\n    float4 _437_flat_ambient : packoffset(c3);\n    float4 _437_light_map : packoffset(c4);\n    float4 _437_light_pos[16] : packoffset(c5);\n    float4 _437_light_color[16] : packoffset(c21);\n    float4 _437_light_shadow_v[16] : packoffset(c37);\n    float4 _437_fog_col : packoffset(c53);\n    float4 _437_fog_b : packoffset(c54);\n    float4 _437_fog_c : packoffset(c55);\n    float4 _437_fog_eye : packoffset(c56);\n    float4 _437_fa_time : packoffset(c57);\n    float4 _437_fa_target : packoffset(c58);\n    float4 _437_fx_emit : packoffset(c59);\n    float4 _437_fx_emit_uv : packoffset(c60);\n    float4 _437_fx_rim : packoffset(c61);\n    float4 _437_fx_rim_uv : packoffset(c62);\n    float4 _437_light_cookie[16] : packoffset(c63);\n    float4 _437_light_cookie_xf[16] : packoffset(c79);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _514_tint : packoffset(c0);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> fx_cookie_tex : register(t5);\nSamplerState light_smp : register(s1);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nTexture2D<float4> fx_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _370 = fa_linear_to_srgb(param);\n        c = _370;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _378 = fa_srgb_to_linear(param_1);\n            c = _378;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _389 = tex.Sample(smp, p);\n    float3 param = _389.xyz;\n    float param_1 = xform.y;\n    float3 _399 = fa_tex_fix(param, param_1);\n    return float4(_399, _389.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _114 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_114.x * 255.0f) + 0.5f) * 256.0f) + floor((_114.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _138 = length(d);\n    if (_138 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _152 = atan2(d.y, d.x);\n    float a = _152;\n    float _155;\n    if (_152 < 0.0f)\n    {\n        _155 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _155 = a;\n    }\n    a = _155;\n    float _167 = _155 * 162.9746551513671875f;\n    float _172 = min(floor(_167), 1023.0f);\n    float _179 = _172 + 1.0f;\n    float i1 = _179;\n    if (_179 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _172;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _138) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _138) + 0.5f, 0.0f, 1.0f), _167 - _172);\n}\n\nfloat3 cookie_coord(float4 cell, float4 xf, float2 off)\n{\n    float2 _242 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _246 = _242.x + 0.5f;\n    float2 c = float2(_246, 0.5f - _242.y);\n    bool _254 = _246 >= 0.0f;\n    bool _260;\n    if (_254)\n    {\n        _260 = c.x <= 1.0f;\n    }\n    else\n    {\n        _260 = _254;\n    }\n    bool _266;\n    if (_260)\n    {\n        _266 = c.y >= 0.0f;\n    }\n    else\n    {\n        _266 = _260;\n    }\n    bool _272;\n    if (_266)\n    {\n        _272 = c.y <= 1.0f;\n    }\n    else\n    {\n        _272 = _266;\n    }\n    float2 _274 = c;\n    float2 _279 = clamp(_274, 0.001953125f.xx, 0.998046875f.xx);\n    c = _279;\n    return float3(cell.x + (_279.x * cell.w), cell.y + (_279.y * cell.z), float(_272));\n}\n\nfloat cookie_value(float4 t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125f, 0.715200006961822509765625f, 0.072200000286102294921875f)) * t.w;\n}\n\nfloat cookie_att(int i, float2 d)\n{\n    if (_437_light_cookie[i].w == 0.0f)\n    {\n        return 1.0f;\n    }\n    float4 param = _437_light_cookie[i];\n    float4 param_1 = _437_light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _551 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.SampleLevel(light_smp, _551.xy, 0.0f);\n    return cookie_value(param_3) * _551.z;\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _573 = _437_lit.y > 0.5f;\n    if (_573)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _437_normal_uv.xy) + _437_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _597 = fa_tex_fix(param, param_1);\n        float3 _601 = (_597 * 2.0f) - 1.0f.xxx;\n        float _608 = cos(params.y);\n        float _610 = sin(params.y);\n        n = normalize(float3((float2(_608, _610) * _601.x) + ((float2(-_610, _608) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _601.y), max(_601.z, 0.0500000007450580596923828125f)));\n    }\n    bool _644 = !_573;\n    bool _650;\n    if (_644)\n    {\n        _650 = _437_lit.z > 0.5f;\n    }\n    else\n    {\n        _650 = _644;\n    }\n    float3 _653;\n    if (_650)\n    {\n        _653 = _437_flat_ambient.xyz;\n    }\n    else\n    {\n        _653 = _437_ambient.xyz;\n    }\n    float3 total = _653;\n    bool _670;\n    if (_650)\n    {\n        _670 = _437_lit.z < 1.5f;\n    }\n    else\n    {\n        _670 = _650;\n    }\n    if (_670)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _437_light_map.xy, 0.0f).xyz * _437_light_map.z);\n    }\n    float3 l;\n    float _794;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _708;\n        if (!_650)\n        {\n            _708 = float(i) >= _437_lit.x;\n        }\n        else\n        {\n            _708 = _650;\n        }\n        if (_708)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_437_light_pos[i].w < 0.0f)\n        {\n            l = _437_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _734 = _437_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_734) / max(_437_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _437_light_color[i].w);\n            float3 _754 = float3(_734, _437_light_pos[i].z);\n            l = _754 / max(length(_754), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_437_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _437_light_shadow_v[i].x;\n                float2 param_3 = -_734;\n                float param_4 = _437_light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n            int param_5 = i;\n            float2 param_6 = -_734;\n            att *= cookie_att(param_5, param_6);\n        }\n        if (_573)\n        {\n            _794 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _794 = 1.0f;\n        }\n        total += (_437_light_color[i].xyz * (att * _794));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _415 = fa_srgb_to_linear(param);\n        c = _415;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _1040 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _1044 = uv * _1040;\n    float _1050 = _1040.x;\n    float _1052 = _1040.y;\n    float _1054 = clamp(shape_rs.x, 0.0f, min(_1050, _1052));\n    float2 _1065 = (abs(_1044) - _1040) + _1054.xx;\n    float d = (length(max(_1065, 0.0f.xx)) + min(max(_1065.x, _1065.y), 0.0f)) - _1054;\n    float ax = params.y;\n    bool _1086 = params.y > 15.0f;\n    if (_1086)\n    {\n        ax -= 20.0f;\n    }\n    float _1097;\n    if (ax <= (-1.5f))\n    {\n        _1097 = (-2.0f) - ax;\n    }\n    else\n    {\n        _1097 = 0.0f;\n    }\n    if (_1097 > 0.0f)\n    {\n        float _1111 = _1097 * 0.5f;\n        d = abs(d + _1111) - _1111;\n    }\n    float _1119 = fwidth(d);\n    float _1120 = max(_1119, 9.9999997473787516355514526367188e-05f);\n    float _1130 = clamp(0.5f - (d / max(shape_rs.y, _1120)), 0.0f, 1.0f);\n    float _1135;\n    if (shape_rs.y > _1120)\n    {\n        _1135 = (_1130 * _1130) * (3.0f - (2.0f * _1130));\n    }\n    else\n    {\n        _1135 = _1130;\n    }\n    float4 c = color;\n    bool _1157 = (_1097 <= 0.0f) && (ax > (-0.5f));\n    if (_1157)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1172 = cos(ax);\n            float _1174 = sin(ax);\n            g = ((dot(_1044, float2(_1172, _1174)) / max((abs(_1172) * _1050) + (abs(_1174) * _1052), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_1086)\n        {\n            float4 _1217 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _1217;\n            float3 param = _1217.xyz;\n            float param_1 = xform.y;\n            float3 _1224 = fa_tex_fix(param, param_1);\n            float4 _2012 = c;\n            _2012.x = _1224.x;\n            _2012.y = _1224.y;\n            _2012.z = _1224.z;\n            c = _2012;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1236 = scene_rgb(param_2);\n            float4 _1261 = lerp(float4(color.xyz * color.w, color.w), float4(_1236 * color2.w, color2.w), g.xxxx);\n            float _1263 = _1261.w;\n            float3 _1266;\n            if (_1263 > 9.9999997473787516355514526367188e-06f)\n            {\n                _1266 = _1261.xyz / _1263.xxx;\n            }\n            else\n            {\n                _1266 = color.xyz;\n            }\n            c = float4(_1266, _1263);\n        }\n    }\n    float4 _2021 = c;\n    _2021.w = _2021.w * _1135;\n    c = _2021;\n    if (_1157 || (shape_rs.y > 0.0f))\n    {\n        float _1307 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1316 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1316 + (_1307 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1322 = fa_srgb_to_linear(param_4);\n            float4 _2024 = c;\n            _2024.x = _1322.x;\n            _2024.y = _1322.y;\n            _2024.z = _1322.z;\n            c = _2024;\n        }\n        else\n        {\n            float4 _1332 = c;\n            float3 _1335 = _1332.xyz + (_1307 * 0.0039215688593685626983642578125f).xxx;\n            float4 _2031 = _1332;\n            _2031.x = _1335.x;\n            _2031.y = _1335.y;\n            _2031.z = _1335.z;\n            c = _2031;\n        }\n        float4 _2036 = c;\n        _2036.w = clamp(_2036.w + ((_1307 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _2036.w)), 0.0f, 1.0f);\n        c = _2036;\n    }\n    return c;\n}\n\nfloat3 rim_color(float a0, float mode)\n{\n    float2 _831 = float2(_437_fx_rim_uv.x, 0.0f);\n    float4 _833 = tex.Sample(smp, uv - _831);\n    float _834 = _833.w;\n    float4 _844 = tex.Sample(smp, uv + _831);\n    float _845 = _844.w;\n    float2 _853 = float2(0.0f, _437_fx_rim_uv.y);\n    float4 _855 = tex.Sample(smp, uv - _853);\n    float _856 = _855.w;\n    float4 _866 = tex.Sample(smp, uv + _853);\n    float _867 = _866.w;\n    float _882 = _834 - _845;\n    float _885 = _867 - _856;\n    float _895 = cos(params.y);\n    float _897 = sin(params.y);\n    float2 _923 = ((float2(_895, _897) * _882) + ((float2(-_897, _895) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _885)) / max(length(float2(_882, _885)), 9.9999997473787516355514526367188e-05f).xx;\n    float3 sum = 0.0f.xxx;\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _437_lit.x)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_437_light_pos[i].w < 0.0f)\n        {\n            to_l = _437_light_pos[i].xy / max(length(_437_light_pos[i].xy), 9.9999997473787516355514526367188e-05f).xx;\n        }\n        else\n        {\n            float2 _969 = _437_light_pos[i].xy - world_xy;\n            float _972 = length(_969);\n            att = pow(clamp(1.0f - (_972 / max(_437_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _437_light_color[i].w);\n            to_l = _969 / max(_972, 9.9999997473787516355514526367188e-05f).xx;\n            if (_437_light_shadow_v[i].x >= 0.0f)\n            {\n                float param = _437_light_shadow_v[i].x;\n                float2 param_1 = -_969;\n                float param_2 = _437_light_pos[i].w;\n                att *= light_shadow(param, param_1, param_2);\n            }\n            int param_3 = i;\n            float2 param_4 = -_969;\n            att *= cookie_att(param_3, param_4);\n        }\n        sum += (_437_light_color[i].xyz * (att * max(dot(_923, to_l), 0.0f)));\n    }\n    return (sum * _437_fx_rim.xyz) * (a0 * (1.0f - min(min(_834, _845), min(_856, _867))));\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _443 = gl_FragCoord.xy * _437_fa_target.xy;\n    float _447 = _443.y;\n    return float2(_443.x, lerp(_447, 1.0f - _447, _437_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _488 = base_mode < 0.5f;\n    bool _499;\n    if (!_488)\n    {\n        _499 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _499 = _488;\n    }\n    float _500;\n    if (_499)\n    {\n        _500 = shape_half.x;\n    }\n    else\n    {\n        _500 = 0.0f;\n    }\n    QuadInput _1962 = { uv, color, world_xy, fa_screen_uv(), _437_fa_time.x, base_mode, 0.0f.xxxx, _500 };\n    return _1962;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _421 = scene_rgb(param);\n    return _421;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = _514_tint.xyz;\n    float4 _521 = s.color;\n    float3 _523 = _521.xyz * fa_scene_rgb(param);\n    s.color.x = _523.x;\n    s.color.y = _523.y;\n    s.color.z = _523.z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1362 = params.x > 31.5f;\n    if (_1362)\n    {\n        mode -= 32.0f;\n    }\n    float _1370 = mode;\n    bool _1372 = _1370 > 15.5f;\n    if (_1372)\n    {\n        mode -= 16.0f;\n    }\n    float _1380 = mode;\n    bool _1382 = _1380 > 7.5f;\n    if (_1382)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1372)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1372)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1444 = tex_color(param_5);\n                float4 _1446 = _1444 * color;\n                float4 param_6 = _1446;\n                float param_7 = mode;\n                float _1453 = _1446.w;\n                frag_color = float4(lit_color(param_6, param_7), _1453);\n                if (_437_fx_rim.w > 0.5f)\n                {\n                    float param_8 = _1453;\n                    float param_9 = mode;\n                    float4 _1469 = frag_color;\n                    float3 _1471 = _1469.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1471.x;\n                    frag_color.y = _1471.y;\n                    frag_color.z = _1471.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1501 = length(uv);\n                    float _1504 = fwidth(_1501);\n                    float _1505 = max(_1504, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1501) / _1505) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1501) / _1505) + 0.5f, 0.0f, 1.0f) * clamp(((_1501 - params.y) / _1505) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1545 = clamp(1.0f - _1501, 0.0f, 1.0f);\n                            cov = (_1545 * _1545) * (3.0f - (2.0f * _1545));\n                        }\n                    }\n                    float3 _1554;\n                    if (_1372)\n                    {\n                        float4 param_10 = color;\n                        float param_11 = 5.0f;\n                        _1554 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1554 = color.xyz;\n                    }\n                    frag_color = float4(_1554, color.w * cov);\n                }\n            }\n        }\n    }\n    if (_437_fx_emit.w > 0.5f)\n    {\n        float3 e = _437_fx_emit.xyz;\n        if (_437_fx_emit.w > 1.5f)\n        {\n            float3 param_12 = fx_emissive_tex.Sample(smp, (uv * _437_fx_emit_uv.xy) + _437_fx_emit_uv.zw).xyz;\n            float param_13 = _437_fx_emit.w - 2.0f;\n            float3 _1609 = fa_tex_fix(param_12, param_13);\n            e *= _1609;\n        }\n        float4 _1613 = frag_color;\n        float3 _1615 = _1613.xyz + e;\n        frag_color.x = _1615.x;\n        frag_color.y = _1615.y;\n        frag_color.z = _1615.z;\n    }\n    float param_14 = mode;\n    float4 _1942 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface _1944 = { _1942 };\n    QuadSurface param_16 = _1944;\n    fragment(param_15, param_16);\n    _1942 = param_16.color;\n    frag_color = param_16.color;\n    if (_1362)\n    {\n        float4 _1641 = frag_color;\n        float3 param_17 = color2.xyz;\n        float3 _1646 = scene_rgb(param_17);\n        float3 _1650 = lerp(_1641.xyz, _1646, color2.w.xxx);\n        frag_color.x = _1650.x;\n        frag_color.y = _1650.y;\n        frag_color.z = _1650.z;\n    }\n    if (_1382)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1674 = _437_fog_col.w > 0.0f;\n    bool _1682;\n    if (!_1674)\n    {\n        _1682 = _437_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1682 = _1674;\n    }\n    if (_1682)\n    {\n        float3 _1696 = float3(world_xy, world_z) - _437_fog_eye.xyz;\n        float _1703 = dot(_1696, _437_fog_c.xyz);\n        bool _1707 = _437_fog_c.w > 0.5f;\n        float _1708;\n        if (_1707)\n        {\n            _1708 = _1703;\n        }\n        else\n        {\n            _1708 = length(_1696);\n        }\n        float _1720 = _1708 - _437_fog_b.x;\n        if (_1720 > 0.0f)\n        {\n            float _1729 = _437_fog_col.w * _1720;\n            float tau = _1729 * _1729;\n            if (_437_fog_b.y > 0.0f)\n            {\n                float _1745;\n                if (_1707)\n                {\n                    _1745 = world_xy.y - (_437_fog_c.y * _1703);\n                }\n                else\n                {\n                    _1745 = _437_fog_eye.y;\n                }\n                float _1766 = lerp(_1745, world_xy.y, clamp(_437_fog_b.x / _1708, 0.0f, 1.0f));\n                float _1770 = world_xy.y - _1766;\n                float _1775 = _1766 - _437_fog_b.z;\n                float _1780 = world_xy.y - _437_fog_b.z;\n                bool _1783 = _1775 <= 0.0f;\n                bool _1784 = !_1783;\n                bool _1790;\n                if (_1784)\n                {\n                    _1790 = _437_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1790 = _1783;\n                }\n                float _1791;\n                if (_1790)\n                {\n                    _1791 = _437_fog_b.y;\n                }\n                else\n                {\n                    _1791 = _437_fog_b.y * exp(-min(_437_fog_b.w * _1775, 80.0f));\n                }\n                bool _1818;\n                if (_1784)\n                {\n                    _1818 = _437_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1818 = _1783;\n                }\n                float _1819;\n                if (_1818)\n                {\n                    _1819 = _437_fog_b.y * _1775;\n                }\n                else\n                {\n                    _1819 = (_437_fog_b.y * (1.0f - exp(-min(_437_fog_b.w * _1775, 80.0f)))) / _437_fog_b.w;\n                }\n                bool _1844 = _1780 <= 0.0f;\n                bool _1851;\n                if (!_1844)\n                {\n                    _1851 = _437_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1851 = _1844;\n                }\n                float _1852;\n                if (_1851)\n                {\n                    _1852 = _437_fog_b.y * _1780;\n                }\n                else\n                {\n                    _1852 = (_437_fog_b.y * (1.0f - exp(-min(_437_fog_b.w * _1780, 80.0f)))) / _437_fog_b.w;\n                }\n                float _1879;\n                if (abs(_1770) < 0.001000000047497451305389404296875f)\n                {\n                    _1879 = _1791;\n                }\n                else\n                {\n                    _1879 = (_1852 - _1819) / _1770;\n                }\n                tau += (_1720 * max(_1879, 0.0f));\n            }\n            float4 _1902 = frag_color;\n            float3 _1910 = lerp(_1902.xyz, _437_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _1910.x;\n            frag_color.y = _1910.y;\n            frag_color.z = _1910.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 1520,
            "struct_name": "quad_fs_params",
            "inst_name": "_437",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_514",
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
              "name": "fx_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 4
            }
          },
          {
            "texture": {
              "slot": 13,
              "stage": "fragment",
              "name": "fx_cookie_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
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
            "name": "fx_cookie_tex_light_smp",
            "view_name": "fx_cookie_tex",
            "sampler_name": "light_smp",
            "view_slot": 13,
            "sampler_slot": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fx_emissive_tex_smp",
            "view_name": "fx_emissive_tex",
            "sampler_name": "smp",
            "view_slot": 12,
            "sampler_slot": 0
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _147 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _147;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _155_lit : packoffset(c0);\n    float4 _155_ambient : packoffset(c1);\n    float4 _155_normal_uv : packoffset(c2);\n    float4 _155_flat_ambient : packoffset(c3);\n    float4 _155_light_map : packoffset(c4);\n    float4 _155_light_pos[16] : packoffset(c5);\n    float4 _155_light_color[16] : packoffset(c21);\n    float4 _155_light_shadow_v[16] : packoffset(c37);\n    float4 _155_fog_col : packoffset(c53);\n    float4 _155_fog_b : packoffset(c54);\n    float4 _155_fog_c : packoffset(c55);\n    float4 _155_fog_eye : packoffset(c56);\n    float4 _155_fa_time : packoffset(c57);\n    float4 _155_fa_target : packoffset(c58);\n    float4 _155_fx_emit : packoffset(c59);\n    float4 _155_fx_emit_uv : packoffset(c60);\n    float4 _155_fx_rim : packoffset(c61);\n    float4 _155_fx_rim_uv : packoffset(c62);\n    float4 _155_light_cookie[16] : packoffset(c63);\n    float4 _155_light_cookie_xf[16] : packoffset(c79);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _237_tint : packoffset(c0);\n};\n\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 frag_color;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _107 = fa_linear_to_srgb(param);\n        c = _107;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _116 = fa_srgb_to_linear(param_1);\n            c = _116;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _162 = gl_FragCoord.xy * _155_fa_target.xy;\n    float _167 = _162.y;\n    return float2(_162.x, lerp(_167, 1.0f - _167, _155_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _211 = base_mode < 0.5f;\n    bool _222;\n    if (!_211)\n    {\n        _222 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _222 = _211;\n    }\n    float _223;\n    if (_222)\n    {\n        _223 = shape_half.x;\n    }\n    else\n    {\n        _223 = 0.0f;\n    }\n    QuadInput _348 = { uv, color, world_xy, fa_screen_uv(), _155_fa_time.x, base_mode, 0.0f.xxxx, _223 };\n    return _348;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _132 = fa_srgb_to_linear(param);\n        c = _132;\n    }\n    return c;\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _138 = scene_rgb(param);\n    return _138;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = _237_tint.xyz;\n    float4 _244 = s.color;\n    float3 _246 = _244.xyz * fa_scene_rgb(param);\n    s.color.x = _246.x;\n    s.color.y = _246.y;\n    s.color.z = _246.z;\n}\n\nvoid frag_main()\n{\n    float4 _265 = tex.Sample(smp, uv);\n    float3 param = _265.xyz;\n    float param_1 = xform.y;\n    float3 _274 = fa_tex_fix(param, param_1);\n    frag_color = float4(_274, _265.w) * color;\n    float param_2 = 0.0f;\n    float4 _328 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _330 = { _328 };\n    QuadSurface param_4 = _330;\n    fragment(param_3, param_4);\n    _328 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 1520,
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
