{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "d75bc1c2988d2355d3b6c4618a7c68ff76094f3e9d32765c88b7244d10541da4",
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
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _686_lit : packoffset(c0);\n    float4 _686_ambient : packoffset(c1);\n    float4 _686_normal_uv : packoffset(c2);\n    float4 _686_flat_ambient : packoffset(c3);\n    float4 _686_light_map : packoffset(c4);\n    float4 _686_light_pos[16] : packoffset(c5);\n    float4 _686_light_color[16] : packoffset(c21);\n    float4 _686_light_shadow_v[16] : packoffset(c37);\n    float4 _686_fog_col : packoffset(c53);\n    float4 _686_fog_b : packoffset(c54);\n    float4 _686_fog_c : packoffset(c55);\n    float4 _686_fog_eye : packoffset(c56);\n    float4 _686_fa_time : packoffset(c57);\n    float4 _686_fa_target : packoffset(c58);\n    float4 _686_fx_emit : packoffset(c59);\n    float4 _686_fx_emit_uv : packoffset(c60);\n    float4 _686_fx_rim : packoffset(c61);\n    float4 _686_fx_rim_uv : packoffset(c62);\n    float4 _686_light_cookie[16] : packoffset(c63);\n    float4 _686_light_cookie_xf[16] : packoffset(c79);\n    float4 _686_fa_scene : packoffset(c95);\n    float4 _686_fa_world_uv[3] : packoffset(c96);\n    float4 _686_gi_xf : packoffset(c99);\n    float4 _686_gi_p : packoffset(c100);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _806_amount : packoffset(c0);\n    float _806_fa_pad0 : packoffset(c0.y);\n    float _806_fa_pad1 : packoffset(c0.z);\n    float _806_fa_pad2 : packoffset(c0.w);\n    float _806_dx : packoffset(c1);\n    float _806_fa_pad3 : packoffset(c1.y);\n    float _806_fa_pad4 : packoffset(c1.z);\n    float _806_fa_pad5 : packoffset(c1.w);\n    float _806_dy : packoffset(c2);\n    float _806_fa_pad6 : packoffset(c2.y);\n    float _806_fa_pad7 : packoffset(c2.z);\n    float _806_fa_pad8 : packoffset(c2.w);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> fa_scene_tex : register(t7);\nSamplerState light_smp : register(s1);\nTexture2D<float4> fx_cookie_tex : register(t5);\nTexture2D<float4> fx_gi_tex : register(t6);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nTexture2D<float4> fx_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _628 = fa_linear_to_srgb(param);\n        c = _628;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _636 = fa_srgb_to_linear(param_1);\n            c = _636;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _647 = tex.Sample(smp, p);\n    float3 param = _647.xyz;\n    float param_1 = xform.y;\n    float3 _657 = fa_tex_fix(param, param_1);\n    return float4(_657, _647.w);\n}\n\nfloat3 gi_irradiance()\n{\n    float2 _878 = (world_xy * _686_gi_xf.xy) + _686_gi_xf.zw;\n    float4 _885 = fx_gi_tex.SampleLevel(light_smp, _878, 0.0f);\n    float _889 = _878.x;\n    bool _890 = _889 >= 0.0f;\n    bool _896;\n    if (_890)\n    {\n        _896 = _878.y >= 0.0f;\n    }\n    else\n    {\n        _896 = _890;\n    }\n    bool _902;\n    if (_896)\n    {\n        _902 = _889 <= 1.0f;\n    }\n    else\n    {\n        _902 = _896;\n    }\n    bool _908;\n    if (_902)\n    {\n        _908 = _878.y <= 1.0f;\n    }\n    else\n    {\n        _908 = _902;\n    }\n    bool _916;\n    if (_908)\n    {\n        _916 = _885.w > 0.0199999995529651641845703125f;\n    }\n    else\n    {\n        _916 = _908;\n    }\n    float3 _917;\n    if (_916)\n    {\n        _917 = (_885.xyz / _885.w.xxx) * _686_gi_p.x;\n    }\n    else\n    {\n        _917 = 0.0f.xxx;\n    }\n    return _917;\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _137 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_137.x * 255.0f) + 0.5f) * 256.0f) + floor((_137.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _240 = floor(tt);\n    float _250 = _240 - (1024.0f * floor(_240 * 0.0009765625f));\n    float _253 = _250 + 1.0f;\n    float i1 = _253;\n    if (_253 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _250;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5f, 0.0f, 1.0f), tt - _240);\n}\n\nfloat light_shadow_soft(float v, float size, float2 d, float radius)\n{\n    float _290 = length(d);\n    float result = 1.0f;\n    if (_290 >= 9.9999997473787516355514526367188e-05f)\n    {\n        float _301 = atan2(d.y, d.x);\n        float a = _301;\n        float _304;\n        if (_301 < 0.0f)\n        {\n            _304 = a + 6.283185482025146484375f;\n        }\n        else\n        {\n            _304 = a;\n        }\n        a = _304;\n        float _314 = _304 * 162.9746551513671875f;\n        float _323 = min((size * 10.0f) / _290, 0.699999988079071044921875f) * 162.9746551513671875f;\n        float sum = 0.0f;\n        float n = 0.0f;\n        for (int k = 0; k < 12; k++)\n        {\n            float _349 = floor(_314 + ((((float(k) + 0.5f) * 0.16666667163372039794921875f) - 1.0f) * _323));\n            float param = v;\n            float param_1 = _349 - (1024.0f * floor(_349 * 0.0009765625f));\n            float _363 = shadow_texel(param, param_1) * radius;\n            if (_363 < _290)\n            {\n                sum += _363;\n                n += 1.0f;\n            }\n        }\n        if (n > 0.5f)\n        {\n            float _395 = min(size * ((1.0f / max(sum / n, 1.0f)) - (1.0f / _290)), 0.699999988079071044921875f) * 162.9746551513671875f;\n            float acc = 0.0f;\n            float wsum = 0.0f;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _413 = ((float(k_1) + 0.5f) * 0.125f) - 1.0f;\n                float _419 = 1.0f - (0.800000011920928955078125f * abs(_413));\n                float param_2 = v;\n                float param_3 = _314 + (_413 * _395);\n                float param_4 = _290;\n                float param_5 = radius;\n                acc += (_419 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _419;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _161 = length(d);\n    if (_161 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _175 = atan2(d.y, d.x);\n    float a = _175;\n    float _178;\n    if (_175 < 0.0f)\n    {\n        _178 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _178 = a;\n    }\n    a = _178;\n    float _190 = _178 * 162.9746551513671875f;\n    float _195 = min(floor(_190), 1023.0f);\n    float _202 = _195 + 1.0f;\n    float i1 = _202;\n    if (_202 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _195;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _161) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _161) + 0.5f, 0.0f, 1.0f), _190 - _195);\n}\n\nfloat light_shadow_sized(float v, float size, float2 d, float radius)\n{\n    float r = 1.0f;\n    if (size > 0.0f)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nfloat3 cookie_coord(float4 cell, float4 xf, float2 off)\n{\n    float2 _500 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _504 = _500.x + 0.5f;\n    float2 c = float2(_504, 0.5f - _500.y);\n    bool _512 = _504 >= 0.0f;\n    bool _518;\n    if (_512)\n    {\n        _518 = c.x <= 1.0f;\n    }\n    else\n    {\n        _518 = _512;\n    }\n    bool _524;\n    if (_518)\n    {\n        _524 = c.y >= 0.0f;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    bool _530;\n    if (_524)\n    {\n        _530 = c.y <= 1.0f;\n    }\n    else\n    {\n        _530 = _524;\n    }\n    float2 _532 = c;\n    float2 _537 = clamp(_532, 0.001953125f.xx, 0.998046875f.xx);\n    c = _537;\n    return float3(cell.x + (_537.x * cell.w), cell.y + (_537.y * cell.z), float(_530));\n}\n\nfloat cookie_value(float4 t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125f, 0.715200006961822509765625f, 0.072200000286102294921875f)) * t.w;\n}\n\nfloat cookie_att(int i, float2 d)\n{\n    if (_686_light_cookie[i].w == 0.0f)\n    {\n        return 1.0f;\n    }\n    float4 param = _686_light_cookie[i];\n    float4 param_1 = _686_light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _853 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.SampleLevel(light_smp, _853.xy, 0.0f);\n    return cookie_value(param_3) * _853.z;\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _939 = _686_lit.y > 0.5f;\n    if (_939)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _686_normal_uv.xy) + _686_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _963 = fa_tex_fix(param, param_1);\n        float3 _967 = (_963 * 2.0f) - 1.0f.xxx;\n        float _974 = cos(params.y);\n        float _976 = sin(params.y);\n        n = normalize(float3((float2(_974, _976) * _967.x) + ((float2(-_976, _974) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _967.y), max(_967.z, 0.0500000007450580596923828125f)));\n    }\n    bool _1010 = !_939;\n    bool _1016;\n    if (_1010)\n    {\n        _1016 = _686_lit.z > 0.5f;\n    }\n    else\n    {\n        _1016 = _1010;\n    }\n    float3 _1019;\n    if (_1016)\n    {\n        _1019 = _686_flat_ambient.xyz;\n    }\n    else\n    {\n        _1019 = _686_ambient.xyz;\n    }\n    float3 total = _1019;\n    if (_686_gi_p.x > 0.0f)\n    {\n        total += gi_irradiance();\n    }\n    bool _1044;\n    if (_1016)\n    {\n        _1044 = _686_lit.z < 1.5f;\n    }\n    else\n    {\n        _1044 = _1016;\n    }\n    if (_1044)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _686_light_map.xy, 0.0f).xyz * _686_light_map.z);\n    }\n    float3 l;\n    float _1171;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1081;\n        if (!_1016)\n        {\n            _1081 = float(i) >= _686_lit.x;\n        }\n        else\n        {\n            _1081 = _1016;\n        }\n        if (_1081)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_686_light_pos[i].w < 0.0f)\n        {\n            l = _686_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _1107 = _686_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_1107) / max(_686_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _686_light_color[i].w);\n            float3 _1127 = float3(_1107, _686_light_pos[i].z);\n            l = _1127 / max(length(_1127), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_686_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _686_light_shadow_v[i].x;\n                float param_3 = _686_light_shadow_v[i].y;\n                float2 param_4 = -_1107;\n                float param_5 = _686_light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            float2 param_7 = -_1107;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_939)\n        {\n            _1171 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _1171 = 1.0f;\n        }\n        total += (_686_light_color[i].xyz * (att * _1171));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _673 = fa_srgb_to_linear(param);\n        c = _673;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _1421 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _1425 = uv * _1421;\n    float _1431 = _1421.x;\n    float _1433 = _1421.y;\n    float _1435 = clamp(shape_rs.x, 0.0f, min(_1431, _1433));\n    float2 _1446 = (abs(_1425) - _1421) + _1435.xx;\n    float d = (length(max(_1446, 0.0f.xx)) + min(max(_1446.x, _1446.y), 0.0f)) - _1435;\n    float ax = params.y;\n    bool _1467 = params.y > 15.0f;\n    if (_1467)\n    {\n        ax -= 20.0f;\n    }\n    float _1478;\n    if (ax <= (-1.5f))\n    {\n        _1478 = (-2.0f) - ax;\n    }\n    else\n    {\n        _1478 = 0.0f;\n    }\n    if (_1478 > 0.0f)\n    {\n        float _1492 = _1478 * 0.5f;\n        d = abs(d + _1492) - _1492;\n    }\n    float _1500 = fwidth(d);\n    float _1501 = max(_1500, 9.9999997473787516355514526367188e-05f);\n    float _1511 = clamp(0.5f - (d / max(shape_rs.y, _1501)), 0.0f, 1.0f);\n    float _1516;\n    if (shape_rs.y > _1501)\n    {\n        _1516 = (_1511 * _1511) * (3.0f - (2.0f * _1511));\n    }\n    else\n    {\n        _1516 = _1511;\n    }\n    float4 c = color;\n    bool _1538 = (_1478 <= 0.0f) && (ax > (-0.5f));\n    if (_1538)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1553 = cos(ax);\n            float _1555 = sin(ax);\n            g = ((dot(_1425, float2(_1553, _1555)) / max((abs(_1553) * _1431) + (abs(_1555) * _1433), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_1467)\n        {\n            float4 _1598 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _1598;\n            float3 param = _1598.xyz;\n            float param_1 = xform.y;\n            float3 _1605 = fa_tex_fix(param, param_1);\n            float4 _2402 = c;\n            _2402.x = _1605.x;\n            _2402.y = _1605.y;\n            _2402.z = _1605.z;\n            c = _2402;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1617 = scene_rgb(param_2);\n            float4 _1642 = lerp(float4(color.xyz * color.w, color.w), float4(_1617 * color2.w, color2.w), g.xxxx);\n            float _1644 = _1642.w;\n            float3 _1647;\n            if (_1644 > 9.9999997473787516355514526367188e-06f)\n            {\n                _1647 = _1642.xyz / _1644.xxx;\n            }\n            else\n            {\n                _1647 = color.xyz;\n            }\n            c = float4(_1647, _1644);\n        }\n    }\n    float4 _2411 = c;\n    _2411.w = _2411.w * _1516;\n    c = _2411;\n    if (_1538 || (shape_rs.y > 0.0f))\n    {\n        float _1688 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1697 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1697 + (_1688 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1703 = fa_srgb_to_linear(param_4);\n            float4 _2414 = c;\n            _2414.x = _1703.x;\n            _2414.y = _1703.y;\n            _2414.z = _1703.z;\n            c = _2414;\n        }\n        else\n        {\n            float4 _1713 = c;\n            float3 _1716 = _1713.xyz + (_1688 * 0.0039215688593685626983642578125f).xxx;\n            float4 _2421 = _1713;\n            _2421.x = _1716.x;\n            _2421.y = _1716.y;\n            _2421.z = _1716.z;\n            c = _2421;\n        }\n        float4 _2426 = c;\n        _2426.w = clamp(_2426.w + ((_1688 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _2426.w)), 0.0f, 1.0f);\n        c = _2426;\n    }\n    return c;\n}\n\nfloat3 rim_color(float a0, float mode)\n{\n    float2 _1208 = float2(_686_fx_rim_uv.x, 0.0f);\n    float4 _1210 = tex.Sample(smp, uv - _1208);\n    float _1211 = _1210.w;\n    float4 _1221 = tex.Sample(smp, uv + _1208);\n    float _1222 = _1221.w;\n    float2 _1230 = float2(0.0f, _686_fx_rim_uv.y);\n    float4 _1232 = tex.Sample(smp, uv - _1230);\n    float _1233 = _1232.w;\n    float4 _1243 = tex.Sample(smp, uv + _1230);\n    float _1244 = _1243.w;\n    float _1259 = _1211 - _1222;\n    float _1262 = _1244 - _1233;\n    float _1272 = cos(params.y);\n    float _1274 = sin(params.y);\n    float2 _1300 = ((float2(_1272, _1274) * _1259) + ((float2(-_1274, _1272) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _1262)) / max(length(float2(_1259, _1262)), 9.9999997473787516355514526367188e-05f).xx;\n    float3 sum = 0.0f.xxx;\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _686_lit.x)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_686_light_pos[i].w < 0.0f)\n        {\n            to_l = _686_light_pos[i].xy / max(length(_686_light_pos[i].xy), 9.9999997473787516355514526367188e-05f).xx;\n        }\n        else\n        {\n            float2 _1346 = _686_light_pos[i].xy - world_xy;\n            float _1349 = length(_1346);\n            att = pow(clamp(1.0f - (_1349 / max(_686_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _686_light_color[i].w);\n            to_l = _1346 / max(_1349, 9.9999997473787516355514526367188e-05f).xx;\n            if (_686_light_shadow_v[i].x >= 0.0f)\n            {\n                float param = _686_light_shadow_v[i].x;\n                float param_1 = _686_light_shadow_v[i].y;\n                float2 param_2 = -_1346;\n                float param_3 = _686_light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1346;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (_686_light_color[i].xyz * (att * max(dot(_1300, to_l), 0.0f)));\n    }\n    return (sum * _686_fx_rim.xyz) * (a0 * (1.0f - min(min(_1211, _1222), min(_1233, _1244))));\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _737 = gl_FragCoord.xy * _686_fa_target.xy;\n    float _741 = _737.y;\n    return float2(_737.x, lerp(_741, 1.0f - _741, _686_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _777 = base_mode < 0.5f;\n    bool _788;\n    if (!_777)\n    {\n        _788 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _788 = _777;\n    }\n    float _789;\n    if (_788)\n    {\n        _789 = shape_half.x;\n    }\n    else\n    {\n        _789 = 0.0f;\n    }\n    QuadInput _2342 = { uv, color, world_xy, fa_screen_uv(), _686_fa_time.x, base_mode, 0.0f.xxxx, _789 };\n    return _2342;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_scene_color(float2 uv_1)\n{\n    if (_686_fa_scene.x <= 0.0f)\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _706 = (uv_1 * _686_fa_scene.xy) + _686_fa_scene.zw;\n    float _708 = _706.y;\n    _706.y = lerp(_708, 1.0f - _708, _686_fa_target.z);\n    return fa_scene_tex.SampleLevel(light_smp, clamp(_706, 0.0f.xx, 1.0f.xx), 0.0f);\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float2 param = i.screen_uv + float2(_806_dx, _806_dy);\n    s.color = float4(lerp(s.color.xyz, fa_scene_color(param).xyz, _806_amount.xxx), s.color.w);\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1743 = params.x > 31.5f;\n    if (_1743)\n    {\n        mode -= 32.0f;\n    }\n    float _1751 = mode;\n    bool _1753 = _1751 > 15.5f;\n    if (_1753)\n    {\n        mode -= 16.0f;\n    }\n    float _1761 = mode;\n    bool _1763 = _1761 > 7.5f;\n    if (_1763)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1753)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1753)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1825 = tex_color(param_5);\n                float4 _1827 = _1825 * color;\n                float4 param_6 = _1827;\n                float param_7 = mode;\n                float _1834 = _1827.w;\n                frag_color = float4(lit_color(param_6, param_7), _1834);\n                if (_686_fx_rim.w > 0.5f)\n                {\n                    float param_8 = _1834;\n                    float param_9 = mode;\n                    float4 _1850 = frag_color;\n                    float3 _1852 = _1850.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1852.x;\n                    frag_color.y = _1852.y;\n                    frag_color.z = _1852.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1882 = length(uv);\n                    float _1885 = fwidth(_1882);\n                    float _1886 = max(_1885, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1882) / _1886) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1882) / _1886) + 0.5f, 0.0f, 1.0f) * clamp(((_1882 - params.y) / _1886) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1926 = clamp(1.0f - _1882, 0.0f, 1.0f);\n                            cov = (_1926 * _1926) * (3.0f - (2.0f * _1926));\n                        }\n                    }\n                    float3 _1935;\n                    if (_1753)\n                    {\n                        float4 param_10 = color;\n                        float param_11 = 5.0f;\n                        _1935 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1935 = color.xyz;\n                    }\n                    frag_color = float4(_1935, color.w * cov);\n                }\n            }\n        }\n    }\n    if (_686_fx_emit.w > 0.5f)\n    {\n        float3 e = _686_fx_emit.xyz;\n        if (_686_fx_emit.w > 1.5f)\n        {\n            float3 param_12 = fx_emissive_tex.Sample(smp, (uv * _686_fx_emit_uv.xy) + _686_fx_emit_uv.zw).xyz;\n            float param_13 = _686_fx_emit.w - 2.0f;\n            float3 _1990 = fa_tex_fix(param_12, param_13);\n            e *= _1990;\n        }\n        float4 _1994 = frag_color;\n        float3 _1996 = _1994.xyz + e;\n        frag_color.x = _1996.x;\n        frag_color.y = _1996.y;\n        frag_color.z = _1996.z;\n    }\n    float param_14 = mode;\n    float4 _2322 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface _2324 = { _2322 };\n    QuadSurface param_16 = _2324;\n    fragment(param_15, param_16);\n    _2322 = param_16.color;\n    frag_color = param_16.color;\n    if (_1743)\n    {\n        float4 _2022 = frag_color;\n        float3 param_17 = color2.xyz;\n        float3 _2027 = scene_rgb(param_17);\n        float3 _2031 = lerp(_2022.xyz, _2027, color2.w.xxx);\n        frag_color.x = _2031.x;\n        frag_color.y = _2031.y;\n        frag_color.z = _2031.z;\n    }\n    if (_1763)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _2054 = _686_fog_col.w > 0.0f;\n    bool _2062;\n    if (!_2054)\n    {\n        _2062 = _686_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2062 = _2054;\n    }\n    if (_2062)\n    {\n        float3 _2076 = float3(world_xy, world_z) - _686_fog_eye.xyz;\n        float _2083 = dot(_2076, _686_fog_c.xyz);\n        bool _2087 = _686_fog_c.w > 0.5f;\n        float _2088;\n        if (_2087)\n        {\n            _2088 = _2083;\n        }\n        else\n        {\n            _2088 = length(_2076);\n        }\n        float _2100 = _2088 - _686_fog_b.x;\n        if (_2100 > 0.0f)\n        {\n            float _2109 = _686_fog_col.w * _2100;\n            float tau = _2109 * _2109;\n            if (_686_fog_b.y > 0.0f)\n            {\n                float _2125;\n                if (_2087)\n                {\n                    _2125 = world_xy.y - (_686_fog_c.y * _2083);\n                }\n                else\n                {\n                    _2125 = _686_fog_eye.y;\n                }\n                float _2146 = lerp(_2125, world_xy.y, clamp(_686_fog_b.x / _2088, 0.0f, 1.0f));\n                float _2150 = world_xy.y - _2146;\n                float _2155 = _2146 - _686_fog_b.z;\n                float _2160 = world_xy.y - _686_fog_b.z;\n                bool _2163 = _2155 <= 0.0f;\n                bool _2164 = !_2163;\n                bool _2170;\n                if (_2164)\n                {\n                    _2170 = _686_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2170 = _2163;\n                }\n                float _2171;\n                if (_2170)\n                {\n                    _2171 = _686_fog_b.y;\n                }\n                else\n                {\n                    _2171 = _686_fog_b.y * exp(-min(_686_fog_b.w * _2155, 80.0f));\n                }\n                bool _2198;\n                if (_2164)\n                {\n                    _2198 = _686_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2198 = _2163;\n                }\n                float _2199;\n                if (_2198)\n                {\n                    _2199 = _686_fog_b.y * _2155;\n                }\n                else\n                {\n                    _2199 = (_686_fog_b.y * (1.0f - exp(-min(_686_fog_b.w * _2155, 80.0f)))) / _686_fog_b.w;\n                }\n                bool _2224 = _2160 <= 0.0f;\n                bool _2231;\n                if (!_2224)\n                {\n                    _2231 = _686_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2231 = _2224;\n                }\n                float _2232;\n                if (_2231)\n                {\n                    _2232 = _686_fog_b.y * _2160;\n                }\n                else\n                {\n                    _2232 = (_686_fog_b.y * (1.0f - exp(-min(_686_fog_b.w * _2160, 80.0f)))) / _686_fog_b.w;\n                }\n                float _2259;\n                if (abs(_2150) < 0.001000000047497451305389404296875f)\n                {\n                    _2259 = _2171;\n                }\n                else\n                {\n                    _2259 = (_2232 - _2199) / _2150;\n                }\n                tau += (_2100 * max(_2259, 0.0f));\n            }\n            float4 _2282 = frag_color;\n            float3 _2290 = lerp(_2282.xyz, _686_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _2290.x;\n            frag_color.y = _2290.y;\n            frag_color.z = _2290.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 1616,
            "struct_name": "quad_fs_params",
            "inst_name": "_686",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 48,
            "struct_name": "fa_material",
            "inst_name": "_806",
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
          },
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fx_gi_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 6
            }
          },
          {
            "texture": {
              "slot": 15,
              "stage": "fragment",
              "name": "fa_scene_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 7
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
            "name": "fx_gi_tex_light_smp",
            "view_name": "fx_gi_tex",
            "sampler_name": "light_smp",
            "view_slot": 14,
            "sampler_slot": 1
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
            "name": "fx_cookie_tex_light_smp",
            "view_name": "fx_cookie_tex",
            "sampler_name": "light_smp",
            "view_slot": 13,
            "sampler_slot": 1
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fx_emissive_tex_smp",
            "view_name": "fx_emissive_tex",
            "sampler_name": "smp",
            "view_slot": 12,
            "sampler_slot": 0
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_scene_tex_light_smp",
            "view_name": "fa_scene_tex",
            "sampler_name": "light_smp",
            "view_slot": 15,
            "sampler_slot": 1
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _147 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _147;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _130_lit : packoffset(c0);\n    float4 _130_ambient : packoffset(c1);\n    float4 _130_normal_uv : packoffset(c2);\n    float4 _130_flat_ambient : packoffset(c3);\n    float4 _130_light_map : packoffset(c4);\n    float4 _130_light_pos[16] : packoffset(c5);\n    float4 _130_light_color[16] : packoffset(c21);\n    float4 _130_light_shadow_v[16] : packoffset(c37);\n    float4 _130_fog_col : packoffset(c53);\n    float4 _130_fog_b : packoffset(c54);\n    float4 _130_fog_c : packoffset(c55);\n    float4 _130_fog_eye : packoffset(c56);\n    float4 _130_fa_time : packoffset(c57);\n    float4 _130_fa_target : packoffset(c58);\n    float4 _130_fx_emit : packoffset(c59);\n    float4 _130_fx_emit_uv : packoffset(c60);\n    float4 _130_fx_rim : packoffset(c61);\n    float4 _130_fx_rim_uv : packoffset(c62);\n    float4 _130_light_cookie[16] : packoffset(c63);\n    float4 _130_light_cookie_xf[16] : packoffset(c79);\n    float4 _130_fa_scene : packoffset(c95);\n    float4 _130_fa_world_uv[3] : packoffset(c96);\n    float4 _130_gi_xf : packoffset(c99);\n    float4 _130_gi_p : packoffset(c100);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _265_amount : packoffset(c0);\n    float _265_fa_pad0 : packoffset(c0.y);\n    float _265_fa_pad1 : packoffset(c0.z);\n    float _265_fa_pad2 : packoffset(c0.w);\n    float _265_dx : packoffset(c1);\n    float _265_fa_pad3 : packoffset(c1.y);\n    float _265_fa_pad4 : packoffset(c1.z);\n    float _265_fa_pad5 : packoffset(c1.w);\n    float _265_dy : packoffset(c2);\n    float _265_fa_pad6 : packoffset(c2.y);\n    float _265_fa_pad7 : packoffset(c2.z);\n    float _265_fa_pad8 : packoffset(c2.w);\n};\n\nTexture2D<float4> fa_scene_tex : register(t1);\nSamplerState light_smp : register(s1);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 frag_color;\nstatic float3 xform;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _106 = fa_linear_to_srgb(param);\n        c = _106;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _115 = fa_srgb_to_linear(param_1);\n            c = _115;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _191 = gl_FragCoord.xy * _130_fa_target.xy;\n    float _195 = _191.y;\n    return float2(_191.x, lerp(_195, 1.0f - _195, _130_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _235 = base_mode < 0.5f;\n    bool _246;\n    if (!_235)\n    {\n        _246 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _246 = _235;\n    }\n    float _247;\n    if (_246)\n    {\n        _247 = shape_half.x;\n    }\n    else\n    {\n        _247 = 0.0f;\n    }\n    QuadInput _382 = { uv, color, world_xy, fa_screen_uv(), _130_fa_time.x, base_mode, 0.0f.xxxx, _247 };\n    return _382;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_scene_color(float2 uv_1)\n{\n    if (_130_fa_scene.x <= 0.0f)\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _152 = (uv_1 * _130_fa_scene.xy) + _130_fa_scene.zw;\n    float _155 = _152.y;\n    _152.y = lerp(_155, 1.0f - _155, _130_fa_target.z);\n    return fa_scene_tex.SampleLevel(light_smp, clamp(_152, 0.0f.xx, 1.0f.xx), 0.0f);\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float2 param = i.screen_uv + float2(_265_dx, _265_dy);\n    s.color = float4(lerp(s.color.xyz, fa_scene_color(param).xyz, _265_amount.xxx), s.color.w);\n}\n\nvoid frag_main()\n{\n    float4 _298 = tex.Sample(smp, uv);\n    float3 param = _298.xyz;\n    float param_1 = xform.y;\n    float3 _309 = fa_tex_fix(param, param_1);\n    frag_color = float4(_309, _298.w) * color;\n    float param_2 = 0.0f;\n    float4 _362 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _364 = { _362 };\n    QuadSurface param_4 = _364;\n    fragment(param_3, param_4);\n    _362 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    xform = stage_input.xform;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 1616,
            "struct_name": "quad_fs_params",
            "inst_name": "_130",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 48,
            "struct_name": "fa_material",
            "inst_name": "_265",
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
              "slot": 15,
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
            "view_slot": 15,
            "sampler_slot": 1
          }
        ]
      }
    }
  }
}
