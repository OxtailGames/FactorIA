{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "8dda08c124964ccb7d15a0a3238fb4669d4ca9ef375995bc9768b79891bfc837",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _144 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _144;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _685_lit : packoffset(c0);\n    float4 _685_ambient : packoffset(c1);\n    float4 _685_normal_uv : packoffset(c2);\n    float4 _685_flat_ambient : packoffset(c3);\n    float4 _685_light_map : packoffset(c4);\n    float4 _685_light_pos[16] : packoffset(c5);\n    float4 _685_light_color[16] : packoffset(c21);\n    float4 _685_light_shadow_v[16] : packoffset(c37);\n    float4 _685_fog_col : packoffset(c53);\n    float4 _685_fog_b : packoffset(c54);\n    float4 _685_fog_c : packoffset(c55);\n    float4 _685_fog_eye : packoffset(c56);\n    float4 _685_fa_time : packoffset(c57);\n    float4 _685_fa_target : packoffset(c58);\n    float4 _685_fx_emit : packoffset(c59);\n    float4 _685_fx_emit_uv : packoffset(c60);\n    float4 _685_fx_rim : packoffset(c61);\n    float4 _685_fx_rim_uv : packoffset(c62);\n    float4 _685_light_cookie[16] : packoffset(c63);\n    float4 _685_light_cookie_xf[16] : packoffset(c79);\n    float4 _685_fa_scene : packoffset(c95);\n    float4 _685_fa_world_uv[3] : packoffset(c96);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> fx_cookie_tex : register(t5);\nSamplerState light_smp : register(s1);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nTexture2D<float4> fx_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _622 = fa_linear_to_srgb(param);\n        c = _622;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _630 = fa_srgb_to_linear(param_1);\n            c = _630;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _641 = tex.Sample(smp, p);\n    float3 param = _641.xyz;\n    float param_1 = xform.y;\n    float3 _651 = fa_tex_fix(param, param_1);\n    return float4(_651, _641.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _131 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_131.x * 255.0f) + 0.5f) * 256.0f) + floor((_131.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _234 = floor(tt);\n    float _244 = _234 - (1024.0f * floor(_234 * 0.0009765625f));\n    float _247 = _244 + 1.0f;\n    float i1 = _247;\n    if (_247 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _244;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5f, 0.0f, 1.0f), tt - _234);\n}\n\nfloat light_shadow_soft(float v, float size, float2 d, float radius)\n{\n    float _284 = length(d);\n    float result = 1.0f;\n    if (_284 >= 9.9999997473787516355514526367188e-05f)\n    {\n        float _295 = atan2(d.y, d.x);\n        float a = _295;\n        float _298;\n        if (_295 < 0.0f)\n        {\n            _298 = a + 6.283185482025146484375f;\n        }\n        else\n        {\n            _298 = a;\n        }\n        a = _298;\n        float _308 = _298 * 162.9746551513671875f;\n        float _317 = min((size * 10.0f) / _284, 0.699999988079071044921875f) * 162.9746551513671875f;\n        float sum = 0.0f;\n        float n = 0.0f;\n        for (int k = 0; k < 12; k++)\n        {\n            float _343 = floor(_308 + ((((float(k) + 0.5f) * 0.16666667163372039794921875f) - 1.0f) * _317));\n            float param = v;\n            float param_1 = _343 - (1024.0f * floor(_343 * 0.0009765625f));\n            float _357 = shadow_texel(param, param_1) * radius;\n            if (_357 < _284)\n            {\n                sum += _357;\n                n += 1.0f;\n            }\n        }\n        if (n > 0.5f)\n        {\n            float _389 = min(size * ((1.0f / max(sum / n, 1.0f)) - (1.0f / _284)), 0.699999988079071044921875f) * 162.9746551513671875f;\n            float acc = 0.0f;\n            float wsum = 0.0f;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _407 = ((float(k_1) + 0.5f) * 0.125f) - 1.0f;\n                float _413 = 1.0f - (0.800000011920928955078125f * abs(_407));\n                float param_2 = v;\n                float param_3 = _308 + (_407 * _389);\n                float param_4 = _284;\n                float param_5 = radius;\n                acc += (_413 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _413;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _155 = length(d);\n    if (_155 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _169 = atan2(d.y, d.x);\n    float a = _169;\n    float _172;\n    if (_169 < 0.0f)\n    {\n        _172 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _172 = a;\n    }\n    a = _172;\n    float _184 = _172 * 162.9746551513671875f;\n    float _189 = min(floor(_184), 1023.0f);\n    float _196 = _189 + 1.0f;\n    float i1 = _196;\n    if (_196 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _189;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _155) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _155) + 0.5f, 0.0f, 1.0f), _184 - _189);\n}\n\nfloat light_shadow_sized(float v, float size, float2 d, float radius)\n{\n    float r = 1.0f;\n    if (size > 0.0f)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nfloat3 cookie_coord(float4 cell, float4 xf, float2 off)\n{\n    float2 _494 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _498 = _494.x + 0.5f;\n    float2 c = float2(_498, 0.5f - _494.y);\n    bool _506 = _498 >= 0.0f;\n    bool _512;\n    if (_506)\n    {\n        _512 = c.x <= 1.0f;\n    }\n    else\n    {\n        _512 = _506;\n    }\n    bool _518;\n    if (_512)\n    {\n        _518 = c.y >= 0.0f;\n    }\n    else\n    {\n        _518 = _512;\n    }\n    bool _524;\n    if (_518)\n    {\n        _524 = c.y <= 1.0f;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    float2 _526 = c;\n    float2 _531 = clamp(_526, 0.001953125f.xx, 0.998046875f.xx);\n    c = _531;\n    return float3(cell.x + (_531.x * cell.w), cell.y + (_531.y * cell.z), float(_524));\n}\n\nfloat cookie_value(float4 t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125f, 0.715200006961822509765625f, 0.072200000286102294921875f)) * t.w;\n}\n\nfloat cookie_att(int i, float2 d)\n{\n    if (_685_light_cookie[i].w == 0.0f)\n    {\n        return 1.0f;\n    }\n    float4 param = _685_light_cookie[i];\n    float4 param_1 = _685_light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _787 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.SampleLevel(light_smp, _787.xy, 0.0f);\n    return cookie_value(param_3) * _787.z;\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _809 = _685_lit.y > 0.5f;\n    if (_809)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _685_normal_uv.xy) + _685_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _833 = fa_tex_fix(param, param_1);\n        float3 _837 = (_833 * 2.0f) - 1.0f.xxx;\n        float _844 = cos(params.y);\n        float _846 = sin(params.y);\n        n = normalize(float3((float2(_844, _846) * _837.x) + ((float2(-_846, _844) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _837.y), max(_837.z, 0.0500000007450580596923828125f)));\n    }\n    bool _880 = !_809;\n    bool _886;\n    if (_880)\n    {\n        _886 = _685_lit.z > 0.5f;\n    }\n    else\n    {\n        _886 = _880;\n    }\n    float3 _889;\n    if (_886)\n    {\n        _889 = _685_flat_ambient.xyz;\n    }\n    else\n    {\n        _889 = _685_ambient.xyz;\n    }\n    float3 total = _889;\n    bool _906;\n    if (_886)\n    {\n        _906 = _685_lit.z < 1.5f;\n    }\n    else\n    {\n        _906 = _886;\n    }\n    if (_906)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _685_light_map.xy, 0.0f).xyz * _685_light_map.z);\n    }\n    float3 l;\n    float _1033;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _943;\n        if (!_886)\n        {\n            _943 = float(i) >= _685_lit.x;\n        }\n        else\n        {\n            _943 = _886;\n        }\n        if (_943)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_685_light_pos[i].w < 0.0f)\n        {\n            l = _685_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _969 = _685_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_969) / max(_685_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _685_light_color[i].w);\n            float3 _989 = float3(_969, _685_light_pos[i].z);\n            l = _989 / max(length(_989), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_685_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _685_light_shadow_v[i].x;\n                float param_3 = _685_light_shadow_v[i].y;\n                float2 param_4 = -_969;\n                float param_5 = _685_light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            float2 param_7 = -_969;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_809)\n        {\n            _1033 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _1033 = 1.0f;\n        }\n        total += (_685_light_color[i].xyz * (att * _1033));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _667 = fa_srgb_to_linear(param);\n        c = _667;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _1283 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _1287 = uv * _1283;\n    float _1293 = _1283.x;\n    float _1295 = _1283.y;\n    float _1297 = clamp(shape_rs.x, 0.0f, min(_1293, _1295));\n    float2 _1308 = (abs(_1287) - _1283) + _1297.xx;\n    float d = (length(max(_1308, 0.0f.xx)) + min(max(_1308.x, _1308.y), 0.0f)) - _1297;\n    float ax = params.y;\n    bool _1329 = params.y > 15.0f;\n    if (_1329)\n    {\n        ax -= 20.0f;\n    }\n    float _1340;\n    if (ax <= (-1.5f))\n    {\n        _1340 = (-2.0f) - ax;\n    }\n    else\n    {\n        _1340 = 0.0f;\n    }\n    if (_1340 > 0.0f)\n    {\n        float _1354 = _1340 * 0.5f;\n        d = abs(d + _1354) - _1354;\n    }\n    float _1362 = fwidth(d);\n    float _1363 = max(_1362, 9.9999997473787516355514526367188e-05f);\n    float _1373 = clamp(0.5f - (d / max(shape_rs.y, _1363)), 0.0f, 1.0f);\n    float _1378;\n    if (shape_rs.y > _1363)\n    {\n        _1378 = (_1373 * _1373) * (3.0f - (2.0f * _1373));\n    }\n    else\n    {\n        _1378 = _1373;\n    }\n    float4 c = color;\n    bool _1400 = (_1340 <= 0.0f) && (ax > (-0.5f));\n    if (_1400)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1415 = cos(ax);\n            float _1417 = sin(ax);\n            g = ((dot(_1287, float2(_1415, _1417)) / max((abs(_1415) * _1293) + (abs(_1417) * _1295), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_1329)\n        {\n            float4 _1460 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _1460;\n            float3 param = _1460.xyz;\n            float param_1 = xform.y;\n            float3 _1467 = fa_tex_fix(param, param_1);\n            float4 _2256 = c;\n            _2256.x = _1467.x;\n            _2256.y = _1467.y;\n            _2256.z = _1467.z;\n            c = _2256;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1479 = scene_rgb(param_2);\n            float4 _1504 = lerp(float4(color.xyz * color.w, color.w), float4(_1479 * color2.w, color2.w), g.xxxx);\n            float _1506 = _1504.w;\n            float3 _1509;\n            if (_1506 > 9.9999997473787516355514526367188e-06f)\n            {\n                _1509 = _1504.xyz / _1506.xxx;\n            }\n            else\n            {\n                _1509 = color.xyz;\n            }\n            c = float4(_1509, _1506);\n        }\n    }\n    float4 _2265 = c;\n    _2265.w = _2265.w * _1378;\n    c = _2265;\n    if (_1400 || (shape_rs.y > 0.0f))\n    {\n        float _1550 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1559 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1559 + (_1550 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1565 = fa_srgb_to_linear(param_4);\n            float4 _2268 = c;\n            _2268.x = _1565.x;\n            _2268.y = _1565.y;\n            _2268.z = _1565.z;\n            c = _2268;\n        }\n        else\n        {\n            float4 _1575 = c;\n            float3 _1578 = _1575.xyz + (_1550 * 0.0039215688593685626983642578125f).xxx;\n            float4 _2275 = _1575;\n            _2275.x = _1578.x;\n            _2275.y = _1578.y;\n            _2275.z = _1578.z;\n            c = _2275;\n        }\n        float4 _2280 = c;\n        _2280.w = clamp(_2280.w + ((_1550 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _2280.w)), 0.0f, 1.0f);\n        c = _2280;\n    }\n    return c;\n}\n\nfloat3 rim_color(float a0, float mode)\n{\n    float2 _1070 = float2(_685_fx_rim_uv.x, 0.0f);\n    float4 _1072 = tex.Sample(smp, uv - _1070);\n    float _1073 = _1072.w;\n    float4 _1083 = tex.Sample(smp, uv + _1070);\n    float _1084 = _1083.w;\n    float2 _1092 = float2(0.0f, _685_fx_rim_uv.y);\n    float4 _1094 = tex.Sample(smp, uv - _1092);\n    float _1095 = _1094.w;\n    float4 _1105 = tex.Sample(smp, uv + _1092);\n    float _1106 = _1105.w;\n    float _1121 = _1073 - _1084;\n    float _1124 = _1106 - _1095;\n    float _1134 = cos(params.y);\n    float _1136 = sin(params.y);\n    float2 _1162 = ((float2(_1134, _1136) * _1121) + ((float2(-_1136, _1134) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _1124)) / max(length(float2(_1121, _1124)), 9.9999997473787516355514526367188e-05f).xx;\n    float3 sum = 0.0f.xxx;\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _685_lit.x)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_685_light_pos[i].w < 0.0f)\n        {\n            to_l = _685_light_pos[i].xy / max(length(_685_light_pos[i].xy), 9.9999997473787516355514526367188e-05f).xx;\n        }\n        else\n        {\n            float2 _1208 = _685_light_pos[i].xy - world_xy;\n            float _1211 = length(_1208);\n            att = pow(clamp(1.0f - (_1211 / max(_685_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _685_light_color[i].w);\n            to_l = _1208 / max(_1211, 9.9999997473787516355514526367188e-05f).xx;\n            if (_685_light_shadow_v[i].x >= 0.0f)\n            {\n                float param = _685_light_shadow_v[i].x;\n                float param_1 = _685_light_shadow_v[i].y;\n                float2 param_2 = -_1208;\n                float param_3 = _685_light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1208;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (_685_light_color[i].xyz * (att * max(dot(_1162, to_l), 0.0f)));\n    }\n    return (sum * _685_fx_rim.xyz) * (a0 * (1.0f - min(min(_1073, _1084), min(_1095, _1106))));\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _691 = gl_FragCoord.xy * _685_fa_target.xy;\n    float _695 = _691.y;\n    return float2(_691.x, lerp(_695, 1.0f - _695, _685_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _733 = base_mode < 0.5f;\n    bool _744;\n    if (!_733)\n    {\n        _744 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _744 = _733;\n    }\n    float _745;\n    if (_744)\n    {\n        _745 = shape_half.x;\n    }\n    else\n    {\n        _745 = 0.0f;\n    }\n    QuadInput _2206 = { uv, color, world_xy, fa_screen_uv(), _685_fa_time.x, base_mode, 0.0f.xxxx, _745 };\n    return _2206;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = i.life;\n    s.color.y = i.life;\n    s.color.z = i.life;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1605 = params.x > 31.5f;\n    if (_1605)\n    {\n        mode -= 32.0f;\n    }\n    float _1613 = mode;\n    bool _1615 = _1613 > 15.5f;\n    if (_1615)\n    {\n        mode -= 16.0f;\n    }\n    float _1623 = mode;\n    bool _1625 = _1623 > 7.5f;\n    if (_1625)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1615)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1615)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1687 = tex_color(param_5);\n                float4 _1689 = _1687 * color;\n                float4 param_6 = _1689;\n                float param_7 = mode;\n                float _1696 = _1689.w;\n                frag_color = float4(lit_color(param_6, param_7), _1696);\n                if (_685_fx_rim.w > 0.5f)\n                {\n                    float param_8 = _1696;\n                    float param_9 = mode;\n                    float4 _1712 = frag_color;\n                    float3 _1714 = _1712.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1714.x;\n                    frag_color.y = _1714.y;\n                    frag_color.z = _1714.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1744 = length(uv);\n                    float _1747 = fwidth(_1744);\n                    float _1748 = max(_1747, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1744) / _1748) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1744) / _1748) + 0.5f, 0.0f, 1.0f) * clamp(((_1744 - params.y) / _1748) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1788 = clamp(1.0f - _1744, 0.0f, 1.0f);\n                            cov = (_1788 * _1788) * (3.0f - (2.0f * _1788));\n                        }\n                    }\n                    float3 _1797;\n                    if (_1615)\n                    {\n                        float4 param_10 = color;\n                        float param_11 = 5.0f;\n                        _1797 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1797 = color.xyz;\n                    }\n                    frag_color = float4(_1797, color.w * cov);\n                }\n            }\n        }\n    }\n    if (_685_fx_emit.w > 0.5f)\n    {\n        float3 e = _685_fx_emit.xyz;\n        if (_685_fx_emit.w > 1.5f)\n        {\n            float3 param_12 = fx_emissive_tex.Sample(smp, (uv * _685_fx_emit_uv.xy) + _685_fx_emit_uv.zw).xyz;\n            float param_13 = _685_fx_emit.w - 2.0f;\n            float3 _1852 = fa_tex_fix(param_12, param_13);\n            e *= _1852;\n        }\n        float4 _1856 = frag_color;\n        float3 _1858 = _1856.xyz + e;\n        frag_color.x = _1858.x;\n        frag_color.y = _1858.y;\n        frag_color.z = _1858.z;\n    }\n    float param_14 = mode;\n    float4 _2186 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface _2188 = { _2186 };\n    QuadSurface param_16 = _2188;\n    fragment(param_15, param_16);\n    _2186 = param_16.color;\n    frag_color = param_16.color;\n    if (_1605)\n    {\n        float4 _1884 = frag_color;\n        float3 param_17 = color2.xyz;\n        float3 _1889 = scene_rgb(param_17);\n        float3 _1893 = lerp(_1884.xyz, _1889, color2.w.xxx);\n        frag_color.x = _1893.x;\n        frag_color.y = _1893.y;\n        frag_color.z = _1893.z;\n    }\n    if (_1625)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1917 = _685_fog_col.w > 0.0f;\n    bool _1925;\n    if (!_1917)\n    {\n        _1925 = _685_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1925 = _1917;\n    }\n    if (_1925)\n    {\n        float3 _1939 = float3(world_xy, world_z) - _685_fog_eye.xyz;\n        float _1946 = dot(_1939, _685_fog_c.xyz);\n        bool _1950 = _685_fog_c.w > 0.5f;\n        float _1951;\n        if (_1950)\n        {\n            _1951 = _1946;\n        }\n        else\n        {\n            _1951 = length(_1939);\n        }\n        float _1963 = _1951 - _685_fog_b.x;\n        if (_1963 > 0.0f)\n        {\n            float _1972 = _685_fog_col.w * _1963;\n            float tau = _1972 * _1972;\n            if (_685_fog_b.y > 0.0f)\n            {\n                float _1988;\n                if (_1950)\n                {\n                    _1988 = world_xy.y - (_685_fog_c.y * _1946);\n                }\n                else\n                {\n                    _1988 = _685_fog_eye.y;\n                }\n                float _2009 = lerp(_1988, world_xy.y, clamp(_685_fog_b.x / _1951, 0.0f, 1.0f));\n                float _2013 = world_xy.y - _2009;\n                float _2018 = _2009 - _685_fog_b.z;\n                float _2023 = world_xy.y - _685_fog_b.z;\n                bool _2026 = _2018 <= 0.0f;\n                bool _2027 = !_2026;\n                bool _2033;\n                if (_2027)\n                {\n                    _2033 = _685_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2033 = _2026;\n                }\n                float _2034;\n                if (_2033)\n                {\n                    _2034 = _685_fog_b.y;\n                }\n                else\n                {\n                    _2034 = _685_fog_b.y * exp(-min(_685_fog_b.w * _2018, 80.0f));\n                }\n                bool _2061;\n                if (_2027)\n                {\n                    _2061 = _685_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2061 = _2026;\n                }\n                float _2062;\n                if (_2061)\n                {\n                    _2062 = _685_fog_b.y * _2018;\n                }\n                else\n                {\n                    _2062 = (_685_fog_b.y * (1.0f - exp(-min(_685_fog_b.w * _2018, 80.0f)))) / _685_fog_b.w;\n                }\n                bool _2087 = _2023 <= 0.0f;\n                bool _2094;\n                if (!_2087)\n                {\n                    _2094 = _685_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2094 = _2087;\n                }\n                float _2095;\n                if (_2094)\n                {\n                    _2095 = _685_fog_b.y * _2023;\n                }\n                else\n                {\n                    _2095 = (_685_fog_b.y * (1.0f - exp(-min(_685_fog_b.w * _2023, 80.0f)))) / _685_fog_b.w;\n                }\n                float _2122;\n                if (abs(_2013) < 0.001000000047497451305389404296875f)\n                {\n                    _2122 = _2034;\n                }\n                else\n                {\n                    _2122 = (_2095 - _2062) / _2013;\n                }\n                tau += (_1963 * max(_2122, 0.0f));\n            }\n            float4 _2145 = frag_color;\n            float3 _2153 = lerp(_2145.xyz, _685_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _2153.x;\n            frag_color.y = _2153.y;\n            frag_color.z = _2153.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 1584,
            "struct_name": "quad_fs_params",
            "inst_name": "_685",
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
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _144 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _144;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _131_lit : packoffset(c0);\n    float4 _131_ambient : packoffset(c1);\n    float4 _131_normal_uv : packoffset(c2);\n    float4 _131_flat_ambient : packoffset(c3);\n    float4 _131_light_map : packoffset(c4);\n    float4 _131_light_pos[16] : packoffset(c5);\n    float4 _131_light_color[16] : packoffset(c21);\n    float4 _131_light_shadow_v[16] : packoffset(c37);\n    float4 _131_fog_col : packoffset(c53);\n    float4 _131_fog_b : packoffset(c54);\n    float4 _131_fog_c : packoffset(c55);\n    float4 _131_fog_eye : packoffset(c56);\n    float4 _131_fa_time : packoffset(c57);\n    float4 _131_fa_target : packoffset(c58);\n    float4 _131_fx_emit : packoffset(c59);\n    float4 _131_fx_emit_uv : packoffset(c60);\n    float4 _131_fx_rim : packoffset(c61);\n    float4 _131_fx_rim_uv : packoffset(c62);\n    float4 _131_light_cookie[16] : packoffset(c63);\n    float4 _131_light_cookie_xf[16] : packoffset(c79);\n    float4 _131_fa_scene : packoffset(c95);\n    float4 _131_fa_world_uv[3] : packoffset(c96);\n};\n\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 frag_color;\nstatic float3 xform;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _138 = gl_FragCoord.xy * _131_fa_target.xy;\n    float _144 = _138.y;\n    return float2(_138.x, lerp(_144, 1.0f - _144, _131_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _188 = base_mode < 0.5f;\n    bool _199;\n    if (!_188)\n    {\n        _199 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _199 = _188;\n    }\n    float _200;\n    if (_199)\n    {\n        _200 = shape_half.x;\n    }\n    else\n    {\n        _200 = 0.0f;\n    }\n    QuadInput _320 = { uv, color, world_xy, fa_screen_uv(), _131_fa_time.x, base_mode, 0.0f.xxxx, _200 };\n    return _320;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = i.life;\n    s.color.y = i.life;\n    s.color.z = i.life;\n}\n\nvoid frag_main()\n{\n    float4 _234 = tex.Sample(smp, uv);\n    float3 param = _234.xyz;\n    float param_1 = xform.y;\n    float3 _245 = fa_tex_fix(param, param_1);\n    frag_color = float4(_245, _234.w) * color;\n    float param_2 = 0.0f;\n    float4 _300 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _302 = { _300 };\n    QuadSurface param_4 = _302;\n    fragment(param_3, param_4);\n    _300 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    xform = stage_input.xform;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 1584,
            "struct_name": "quad_fs_params",
            "inst_name": "_131",
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
