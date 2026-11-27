{
  "format": "factoria.shader/1",
  "engine": "0.39.0",
  "template": "d75bc1c2988d2355d3b6c4618a7c68ff76094f3e9d32765c88b7244d10541da4",
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
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _686_lit : packoffset(c0);\n    float4 _686_ambient : packoffset(c1);\n    float4 _686_normal_uv : packoffset(c2);\n    float4 _686_flat_ambient : packoffset(c3);\n    float4 _686_light_map : packoffset(c4);\n    float4 _686_light_pos[16] : packoffset(c5);\n    float4 _686_light_color[16] : packoffset(c21);\n    float4 _686_light_shadow_v[16] : packoffset(c37);\n    float4 _686_fog_col : packoffset(c53);\n    float4 _686_fog_b : packoffset(c54);\n    float4 _686_fog_c : packoffset(c55);\n    float4 _686_fog_eye : packoffset(c56);\n    float4 _686_fa_time : packoffset(c57);\n    float4 _686_fa_target : packoffset(c58);\n    float4 _686_fx_emit : packoffset(c59);\n    float4 _686_fx_emit_uv : packoffset(c60);\n    float4 _686_fx_rim : packoffset(c61);\n    float4 _686_fx_rim_uv : packoffset(c62);\n    float4 _686_light_cookie[16] : packoffset(c63);\n    float4 _686_light_cookie_xf[16] : packoffset(c79);\n    float4 _686_fa_scene : packoffset(c95);\n    float4 _686_fa_world_uv[3] : packoffset(c96);\n    float4 _686_gi_xf : packoffset(c99);\n    float4 _686_gi_p : packoffset(c100);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _804_reflection : packoffset(c0);\n    float _804_fa_pad0 : packoffset(c0.y);\n    float _804_fa_pad1 : packoffset(c0.z);\n    float _804_fa_pad2 : packoffset(c0.w);\n    float _804_refraction : packoffset(c1);\n    float _804_fa_pad3 : packoffset(c1.y);\n    float _804_fa_pad4 : packoffset(c1.z);\n    float _804_fa_pad5 : packoffset(c1.w);\n    float2 _804_size : packoffset(c2);\n    float _804_fa_pad6 : packoffset(c2.z);\n    float _804_fa_pad7 : packoffset(c2.w);\n    float _804_strength : packoffset(c3);\n    float _804_fa_pad8 : packoffset(c3.y);\n    float _804_fa_pad9 : packoffset(c3.z);\n    float _804_fa_pad10 : packoffset(c3.w);\n    float4 _804_tint : packoffset(c4);\n    float _804_waveAmplitude : packoffset(c5);\n    float _804_fa_pad11 : packoffset(c5.y);\n    float _804_fa_pad12 : packoffset(c5.z);\n    float _804_fa_pad13 : packoffset(c5.w);\n    float _804_waveLength : packoffset(c6);\n    float _804_fa_pad14 : packoffset(c6.y);\n    float _804_fa_pad15 : packoffset(c6.z);\n    float _804_fa_pad16 : packoffset(c6.w);\n    float _804_waveSpeed : packoffset(c7);\n    float _804_fa_pad17 : packoffset(c7.y);\n    float _804_fa_pad18 : packoffset(c7.z);\n    float _804_fa_pad19 : packoffset(c7.w);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> fa_scene_tex : register(t7);\nSamplerState light_smp : register(s1);\nTexture2D<float4> fx_cookie_tex : register(t5);\nTexture2D<float4> fx_gi_tex : register(t6);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nTexture2D<float4> fx_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _628 = fa_linear_to_srgb(param);\n        c = _628;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _636 = fa_srgb_to_linear(param_1);\n            c = _636;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _647 = tex.Sample(smp, p);\n    float3 param = _647.xyz;\n    float param_1 = xform.y;\n    float3 _657 = fa_tex_fix(param, param_1);\n    return float4(_657, _647.w);\n}\n\nfloat3 gi_irradiance()\n{\n    float2 _909 = (world_xy * _686_gi_xf.xy) + _686_gi_xf.zw;\n    float4 _916 = fx_gi_tex.SampleLevel(light_smp, _909, 0.0f);\n    float _920 = _909.x;\n    bool _921 = _920 >= 0.0f;\n    bool _927;\n    if (_921)\n    {\n        _927 = _909.y >= 0.0f;\n    }\n    else\n    {\n        _927 = _921;\n    }\n    bool _933;\n    if (_927)\n    {\n        _933 = _920 <= 1.0f;\n    }\n    else\n    {\n        _933 = _927;\n    }\n    bool _939;\n    if (_933)\n    {\n        _939 = _909.y <= 1.0f;\n    }\n    else\n    {\n        _939 = _933;\n    }\n    bool _947;\n    if (_939)\n    {\n        _947 = _916.w > 0.0199999995529651641845703125f;\n    }\n    else\n    {\n        _947 = _939;\n    }\n    float3 _948;\n    if (_947)\n    {\n        _948 = (_916.xyz / _916.w.xxx) * _686_gi_p.x;\n    }\n    else\n    {\n        _948 = 0.0f.xxx;\n    }\n    return _948;\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _137 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_137.x * 255.0f) + 0.5f) * 256.0f) + floor((_137.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _240 = floor(tt);\n    float _250 = _240 - (1024.0f * floor(_240 * 0.0009765625f));\n    float _253 = _250 + 1.0f;\n    float i1 = _253;\n    if (_253 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _250;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5f, 0.0f, 1.0f), tt - _240);\n}\n\nfloat light_shadow_soft(float v, float size, float2 d, float radius)\n{\n    float _290 = length(d);\n    float result = 1.0f;\n    if (_290 >= 9.9999997473787516355514526367188e-05f)\n    {\n        float _301 = atan2(d.y, d.x);\n        float a = _301;\n        float _304;\n        if (_301 < 0.0f)\n        {\n            _304 = a + 6.283185482025146484375f;\n        }\n        else\n        {\n            _304 = a;\n        }\n        a = _304;\n        float _314 = _304 * 162.9746551513671875f;\n        float _323 = min((size * 10.0f) / _290, 0.699999988079071044921875f) * 162.9746551513671875f;\n        float sum = 0.0f;\n        float n = 0.0f;\n        for (int k = 0; k < 12; k++)\n        {\n            float _349 = floor(_314 + ((((float(k) + 0.5f) * 0.16666667163372039794921875f) - 1.0f) * _323));\n            float param = v;\n            float param_1 = _349 - (1024.0f * floor(_349 * 0.0009765625f));\n            float _363 = shadow_texel(param, param_1) * radius;\n            if (_363 < _290)\n            {\n                sum += _363;\n                n += 1.0f;\n            }\n        }\n        if (n > 0.5f)\n        {\n            float _395 = min(size * ((1.0f / max(sum / n, 1.0f)) - (1.0f / _290)), 0.699999988079071044921875f) * 162.9746551513671875f;\n            float acc = 0.0f;\n            float wsum = 0.0f;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _413 = ((float(k_1) + 0.5f) * 0.125f) - 1.0f;\n                float _419 = 1.0f - (0.800000011920928955078125f * abs(_413));\n                float param_2 = v;\n                float param_3 = _314 + (_413 * _395);\n                float param_4 = _290;\n                float param_5 = radius;\n                acc += (_419 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _419;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _161 = length(d);\n    if (_161 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _175 = atan2(d.y, d.x);\n    float a = _175;\n    float _178;\n    if (_175 < 0.0f)\n    {\n        _178 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _178 = a;\n    }\n    a = _178;\n    float _190 = _178 * 162.9746551513671875f;\n    float _195 = min(floor(_190), 1023.0f);\n    float _202 = _195 + 1.0f;\n    float i1 = _202;\n    if (_202 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _195;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _161) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _161) + 0.5f, 0.0f, 1.0f), _190 - _195);\n}\n\nfloat light_shadow_sized(float v, float size, float2 d, float radius)\n{\n    float r = 1.0f;\n    if (size > 0.0f)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nfloat3 cookie_coord(float4 cell, float4 xf, float2 off)\n{\n    float2 _500 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _504 = _500.x + 0.5f;\n    float2 c = float2(_504, 0.5f - _500.y);\n    bool _512 = _504 >= 0.0f;\n    bool _518;\n    if (_512)\n    {\n        _518 = c.x <= 1.0f;\n    }\n    else\n    {\n        _518 = _512;\n    }\n    bool _524;\n    if (_518)\n    {\n        _524 = c.y >= 0.0f;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    bool _530;\n    if (_524)\n    {\n        _530 = c.y <= 1.0f;\n    }\n    else\n    {\n        _530 = _524;\n    }\n    float2 _532 = c;\n    float2 _537 = clamp(_532, 0.001953125f.xx, 0.998046875f.xx);\n    c = _537;\n    return float3(cell.x + (_537.x * cell.w), cell.y + (_537.y * cell.z), float(_530));\n}\n\nfloat cookie_value(float4 t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125f, 0.715200006961822509765625f, 0.072200000286102294921875f)) * t.w;\n}\n\nfloat cookie_att(int i, float2 d)\n{\n    if (_686_light_cookie[i].w == 0.0f)\n    {\n        return 1.0f;\n    }\n    float4 param = _686_light_cookie[i];\n    float4 param_1 = _686_light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _884 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.SampleLevel(light_smp, _884.xy, 0.0f);\n    return cookie_value(param_3) * _884.z;\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _970 = _686_lit.y > 0.5f;\n    if (_970)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _686_normal_uv.xy) + _686_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _994 = fa_tex_fix(param, param_1);\n        float3 _998 = (_994 * 2.0f) - 1.0f.xxx;\n        float _1005 = cos(params.y);\n        float _1007 = sin(params.y);\n        n = normalize(float3((float2(_1005, _1007) * _998.x) + ((float2(-_1007, _1005) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _998.y), max(_998.z, 0.0500000007450580596923828125f)));\n    }\n    bool _1041 = !_970;\n    bool _1047;\n    if (_1041)\n    {\n        _1047 = _686_lit.z > 0.5f;\n    }\n    else\n    {\n        _1047 = _1041;\n    }\n    float3 _1050;\n    if (_1047)\n    {\n        _1050 = _686_flat_ambient.xyz;\n    }\n    else\n    {\n        _1050 = _686_ambient.xyz;\n    }\n    float3 total = _1050;\n    if (_686_gi_p.x > 0.0f)\n    {\n        total += gi_irradiance();\n    }\n    bool _1075;\n    if (_1047)\n    {\n        _1075 = _686_lit.z < 1.5f;\n    }\n    else\n    {\n        _1075 = _1047;\n    }\n    if (_1075)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _686_light_map.xy, 0.0f).xyz * _686_light_map.z);\n    }\n    float3 l;\n    float _1202;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1112;\n        if (!_1047)\n        {\n            _1112 = float(i) >= _686_lit.x;\n        }\n        else\n        {\n            _1112 = _1047;\n        }\n        if (_1112)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_686_light_pos[i].w < 0.0f)\n        {\n            l = _686_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _1138 = _686_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_1138) / max(_686_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _686_light_color[i].w);\n            float3 _1158 = float3(_1138, _686_light_pos[i].z);\n            l = _1158 / max(length(_1158), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_686_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _686_light_shadow_v[i].x;\n                float param_3 = _686_light_shadow_v[i].y;\n                float2 param_4 = -_1138;\n                float param_5 = _686_light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            float2 param_7 = -_1138;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_970)\n        {\n            _1202 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _1202 = 1.0f;\n        }\n        total += (_686_light_color[i].xyz * (att * _1202));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _673 = fa_srgb_to_linear(param);\n        c = _673;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _1452 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _1456 = uv * _1452;\n    float _1462 = _1452.x;\n    float _1464 = _1452.y;\n    float _1466 = clamp(shape_rs.x, 0.0f, min(_1462, _1464));\n    float2 _1477 = (abs(_1456) - _1452) + _1466.xx;\n    float d = (length(max(_1477, 0.0f.xx)) + min(max(_1477.x, _1477.y), 0.0f)) - _1466;\n    float ax = params.y;\n    bool _1498 = params.y > 15.0f;\n    if (_1498)\n    {\n        ax -= 20.0f;\n    }\n    float _1509;\n    if (ax <= (-1.5f))\n    {\n        _1509 = (-2.0f) - ax;\n    }\n    else\n    {\n        _1509 = 0.0f;\n    }\n    if (_1509 > 0.0f)\n    {\n        float _1523 = _1509 * 0.5f;\n        d = abs(d + _1523) - _1523;\n    }\n    float _1531 = fwidth(d);\n    float _1532 = max(_1531, 9.9999997473787516355514526367188e-05f);\n    float _1542 = clamp(0.5f - (d / max(shape_rs.y, _1532)), 0.0f, 1.0f);\n    float _1547;\n    if (shape_rs.y > _1532)\n    {\n        _1547 = (_1542 * _1542) * (3.0f - (2.0f * _1542));\n    }\n    else\n    {\n        _1547 = _1542;\n    }\n    float4 c = color;\n    bool _1569 = (_1509 <= 0.0f) && (ax > (-0.5f));\n    if (_1569)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1584 = cos(ax);\n            float _1586 = sin(ax);\n            g = ((dot(_1456, float2(_1584, _1586)) / max((abs(_1584) * _1462) + (abs(_1586) * _1464), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_1498)\n        {\n            float4 _1629 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _1629;\n            float3 param = _1629.xyz;\n            float param_1 = xform.y;\n            float3 _1636 = fa_tex_fix(param, param_1);\n            float4 _2431 = c;\n            _2431.x = _1636.x;\n            _2431.y = _1636.y;\n            _2431.z = _1636.z;\n            c = _2431;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1648 = scene_rgb(param_2);\n            float4 _1673 = lerp(float4(color.xyz * color.w, color.w), float4(_1648 * color2.w, color2.w), g.xxxx);\n            float _1675 = _1673.w;\n            float3 _1678;\n            if (_1675 > 9.9999997473787516355514526367188e-06f)\n            {\n                _1678 = _1673.xyz / _1675.xxx;\n            }\n            else\n            {\n                _1678 = color.xyz;\n            }\n            c = float4(_1678, _1675);\n        }\n    }\n    float4 _2440 = c;\n    _2440.w = _2440.w * _1547;\n    c = _2440;\n    if (_1569 || (shape_rs.y > 0.0f))\n    {\n        float _1719 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1728 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1728 + (_1719 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1734 = fa_srgb_to_linear(param_4);\n            float4 _2443 = c;\n            _2443.x = _1734.x;\n            _2443.y = _1734.y;\n            _2443.z = _1734.z;\n            c = _2443;\n        }\n        else\n        {\n            float4 _1744 = c;\n            float3 _1747 = _1744.xyz + (_1719 * 0.0039215688593685626983642578125f).xxx;\n            float4 _2450 = _1744;\n            _2450.x = _1747.x;\n            _2450.y = _1747.y;\n            _2450.z = _1747.z;\n            c = _2450;\n        }\n        float4 _2455 = c;\n        _2455.w = clamp(_2455.w + ((_1719 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _2455.w)), 0.0f, 1.0f);\n        c = _2455;\n    }\n    return c;\n}\n\nfloat3 rim_color(float a0, float mode)\n{\n    float2 _1239 = float2(_686_fx_rim_uv.x, 0.0f);\n    float4 _1241 = tex.Sample(smp, uv - _1239);\n    float _1242 = _1241.w;\n    float4 _1252 = tex.Sample(smp, uv + _1239);\n    float _1253 = _1252.w;\n    float2 _1261 = float2(0.0f, _686_fx_rim_uv.y);\n    float4 _1263 = tex.Sample(smp, uv - _1261);\n    float _1264 = _1263.w;\n    float4 _1274 = tex.Sample(smp, uv + _1261);\n    float _1275 = _1274.w;\n    float _1290 = _1242 - _1253;\n    float _1293 = _1275 - _1264;\n    float _1303 = cos(params.y);\n    float _1305 = sin(params.y);\n    float2 _1331 = ((float2(_1303, _1305) * _1290) + ((float2(-_1305, _1303) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _1293)) / max(length(float2(_1290, _1293)), 9.9999997473787516355514526367188e-05f).xx;\n    float3 sum = 0.0f.xxx;\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _686_lit.x)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_686_light_pos[i].w < 0.0f)\n        {\n            to_l = _686_light_pos[i].xy / max(length(_686_light_pos[i].xy), 9.9999997473787516355514526367188e-05f).xx;\n        }\n        else\n        {\n            float2 _1377 = _686_light_pos[i].xy - world_xy;\n            float _1380 = length(_1377);\n            att = pow(clamp(1.0f - (_1380 / max(_686_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _686_light_color[i].w);\n            to_l = _1377 / max(_1380, 9.9999997473787516355514526367188e-05f).xx;\n            if (_686_light_shadow_v[i].x >= 0.0f)\n            {\n                float param = _686_light_shadow_v[i].x;\n                float param_1 = _686_light_shadow_v[i].y;\n                float2 param_2 = -_1377;\n                float param_3 = _686_light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1377;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (_686_light_color[i].xyz * (att * max(dot(_1331, to_l), 0.0f)));\n    }\n    return (sum * _686_fx_rim.xyz) * (a0 * (1.0f - min(min(_1242, _1253), min(_1264, _1275))));\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _737 = gl_FragCoord.xy * _686_fa_target.xy;\n    float _741 = _737.y;\n    return float2(_737.x, lerp(_741, 1.0f - _741, _686_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _777 = base_mode < 0.5f;\n    bool _788;\n    if (!_777)\n    {\n        _788 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _788 = _777;\n    }\n    float _789;\n    if (_788)\n    {\n        _789 = shape_half.x;\n    }\n    else\n    {\n        _789 = 0.0f;\n    }\n    QuadInput _2371 = { uv, color, world_xy, fa_screen_uv(), _686_fa_time.x, base_mode, 0.0f.xxxx, _789 };\n    return _2371;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_scene_color(float2 uv_1)\n{\n    if (_686_fa_scene.x <= 0.0f)\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _706 = (uv_1 * _686_fa_scene.xy) + _686_fa_scene.zw;\n    float _708 = _706.y;\n    _706.y = lerp(_708, 1.0f - _708, _686_fa_target.z);\n    return fa_scene_tex.SampleLevel(light_smp, clamp(_706, 0.0f.xx, 1.0f.xx), 0.0f);\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float2 param = i.screen_uv + (float2(_804_refraction + _804_strength, 0.0f) * _686_fa_target.xy);\n    s.color = float4(lerp(fa_scene_color(param).xyz, _804_tint.xyz, _804_tint.w.xxx), 1.0f);\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1774 = params.x > 31.5f;\n    if (_1774)\n    {\n        mode -= 32.0f;\n    }\n    float _1782 = mode;\n    bool _1784 = _1782 > 15.5f;\n    if (_1784)\n    {\n        mode -= 16.0f;\n    }\n    float _1792 = mode;\n    bool _1794 = _1792 > 7.5f;\n    if (_1794)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1784)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1784)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1856 = tex_color(param_5);\n                float4 _1858 = _1856 * color;\n                float4 param_6 = _1858;\n                float param_7 = mode;\n                float _1865 = _1858.w;\n                frag_color = float4(lit_color(param_6, param_7), _1865);\n                if (_686_fx_rim.w > 0.5f)\n                {\n                    float param_8 = _1865;\n                    float param_9 = mode;\n                    float4 _1881 = frag_color;\n                    float3 _1883 = _1881.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1883.x;\n                    frag_color.y = _1883.y;\n                    frag_color.z = _1883.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1913 = length(uv);\n                    float _1916 = fwidth(_1913);\n                    float _1917 = max(_1916, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1913) / _1917) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1913) / _1917) + 0.5f, 0.0f, 1.0f) * clamp(((_1913 - params.y) / _1917) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1957 = clamp(1.0f - _1913, 0.0f, 1.0f);\n                            cov = (_1957 * _1957) * (3.0f - (2.0f * _1957));\n                        }\n                    }\n                    float3 _1966;\n                    if (_1784)\n                    {\n                        float4 param_10 = color;\n                        float param_11 = 5.0f;\n                        _1966 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1966 = color.xyz;\n                    }\n                    frag_color = float4(_1966, color.w * cov);\n                }\n            }\n        }\n    }\n    if (_686_fx_emit.w > 0.5f)\n    {\n        float3 e = _686_fx_emit.xyz;\n        if (_686_fx_emit.w > 1.5f)\n        {\n            float3 param_12 = fx_emissive_tex.Sample(smp, (uv * _686_fx_emit_uv.xy) + _686_fx_emit_uv.zw).xyz;\n            float param_13 = _686_fx_emit.w - 2.0f;\n            float3 _2020 = fa_tex_fix(param_12, param_13);\n            e *= _2020;\n        }\n        float4 _2024 = frag_color;\n        float3 _2026 = _2024.xyz + e;\n        frag_color.x = _2026.x;\n        frag_color.y = _2026.y;\n        frag_color.z = _2026.z;\n    }\n    float param_14 = mode;\n    float4 _2351 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface _2353 = { _2351 };\n    QuadSurface param_16 = _2353;\n    fragment(param_15, param_16);\n    _2351 = param_16.color;\n    frag_color = param_16.color;\n    if (_1774)\n    {\n        float4 _2052 = frag_color;\n        float3 param_17 = color2.xyz;\n        float3 _2057 = scene_rgb(param_17);\n        float3 _2061 = lerp(_2052.xyz, _2057, color2.w.xxx);\n        frag_color.x = _2061.x;\n        frag_color.y = _2061.y;\n        frag_color.z = _2061.z;\n    }\n    if (_1794)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _2084 = _686_fog_col.w > 0.0f;\n    bool _2092;\n    if (!_2084)\n    {\n        _2092 = _686_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2092 = _2084;\n    }\n    if (_2092)\n    {\n        float3 _2105 = float3(world_xy, world_z) - _686_fog_eye.xyz;\n        float _2112 = dot(_2105, _686_fog_c.xyz);\n        bool _2116 = _686_fog_c.w > 0.5f;\n        float _2117;\n        if (_2116)\n        {\n            _2117 = _2112;\n        }\n        else\n        {\n            _2117 = length(_2105);\n        }\n        float _2129 = _2117 - _686_fog_b.x;\n        if (_2129 > 0.0f)\n        {\n            float _2138 = _686_fog_col.w * _2129;\n            float tau = _2138 * _2138;\n            if (_686_fog_b.y > 0.0f)\n            {\n                float _2154;\n                if (_2116)\n                {\n                    _2154 = world_xy.y - (_686_fog_c.y * _2112);\n                }\n                else\n                {\n                    _2154 = _686_fog_eye.y;\n                }\n                float _2175 = lerp(_2154, world_xy.y, clamp(_686_fog_b.x / _2117, 0.0f, 1.0f));\n                float _2179 = world_xy.y - _2175;\n                float _2184 = _2175 - _686_fog_b.z;\n                float _2189 = world_xy.y - _686_fog_b.z;\n                bool _2192 = _2184 <= 0.0f;\n                bool _2193 = !_2192;\n                bool _2199;\n                if (_2193)\n                {\n                    _2199 = _686_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2199 = _2192;\n                }\n                float _2200;\n                if (_2199)\n                {\n                    _2200 = _686_fog_b.y;\n                }\n                else\n                {\n                    _2200 = _686_fog_b.y * exp(-min(_686_fog_b.w * _2184, 80.0f));\n                }\n                bool _2227;\n                if (_2193)\n                {\n                    _2227 = _686_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2227 = _2192;\n                }\n                float _2228;\n                if (_2227)\n                {\n                    _2228 = _686_fog_b.y * _2184;\n                }\n                else\n                {\n                    _2228 = (_686_fog_b.y * (1.0f - exp(-min(_686_fog_b.w * _2184, 80.0f)))) / _686_fog_b.w;\n                }\n                bool _2253 = _2189 <= 0.0f;\n                bool _2260;\n                if (!_2253)\n                {\n                    _2260 = _686_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2260 = _2253;\n                }\n                float _2261;\n                if (_2260)\n                {\n                    _2261 = _686_fog_b.y * _2189;\n                }\n                else\n                {\n                    _2261 = (_686_fog_b.y * (1.0f - exp(-min(_686_fog_b.w * _2189, 80.0f)))) / _686_fog_b.w;\n                }\n                float _2288;\n                if (abs(_2179) < 0.001000000047497451305389404296875f)\n                {\n                    _2288 = _2200;\n                }\n                else\n                {\n                    _2288 = (_2261 - _2228) / _2179;\n                }\n                tau += (_2129 * max(_2288, 0.0f));\n            }\n            float4 _2311 = frag_color;\n            float3 _2319 = lerp(_2311.xyz, _686_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _2319.x;\n            frag_color.y = _2319.y;\n            frag_color.z = _2319.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 128,
            "struct_name": "fa_material",
            "inst_name": "_804",
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
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _130_lit : packoffset(c0);\n    float4 _130_ambient : packoffset(c1);\n    float4 _130_normal_uv : packoffset(c2);\n    float4 _130_flat_ambient : packoffset(c3);\n    float4 _130_light_map : packoffset(c4);\n    float4 _130_light_pos[16] : packoffset(c5);\n    float4 _130_light_color[16] : packoffset(c21);\n    float4 _130_light_shadow_v[16] : packoffset(c37);\n    float4 _130_fog_col : packoffset(c53);\n    float4 _130_fog_b : packoffset(c54);\n    float4 _130_fog_c : packoffset(c55);\n    float4 _130_fog_eye : packoffset(c56);\n    float4 _130_fa_time : packoffset(c57);\n    float4 _130_fa_target : packoffset(c58);\n    float4 _130_fx_emit : packoffset(c59);\n    float4 _130_fx_emit_uv : packoffset(c60);\n    float4 _130_fx_rim : packoffset(c61);\n    float4 _130_fx_rim_uv : packoffset(c62);\n    float4 _130_light_cookie[16] : packoffset(c63);\n    float4 _130_light_cookie_xf[16] : packoffset(c79);\n    float4 _130_fa_scene : packoffset(c95);\n    float4 _130_fa_world_uv[3] : packoffset(c96);\n    float4 _130_gi_xf : packoffset(c99);\n    float4 _130_gi_p : packoffset(c100);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _263_reflection : packoffset(c0);\n    float _263_fa_pad0 : packoffset(c0.y);\n    float _263_fa_pad1 : packoffset(c0.z);\n    float _263_fa_pad2 : packoffset(c0.w);\n    float _263_refraction : packoffset(c1);\n    float _263_fa_pad3 : packoffset(c1.y);\n    float _263_fa_pad4 : packoffset(c1.z);\n    float _263_fa_pad5 : packoffset(c1.w);\n    float2 _263_size : packoffset(c2);\n    float _263_fa_pad6 : packoffset(c2.z);\n    float _263_fa_pad7 : packoffset(c2.w);\n    float _263_strength : packoffset(c3);\n    float _263_fa_pad8 : packoffset(c3.y);\n    float _263_fa_pad9 : packoffset(c3.z);\n    float _263_fa_pad10 : packoffset(c3.w);\n    float4 _263_tint : packoffset(c4);\n    float _263_waveAmplitude : packoffset(c5);\n    float _263_fa_pad11 : packoffset(c5.y);\n    float _263_fa_pad12 : packoffset(c5.z);\n    float _263_fa_pad13 : packoffset(c5.w);\n    float _263_waveLength : packoffset(c6);\n    float _263_fa_pad14 : packoffset(c6.y);\n    float _263_fa_pad15 : packoffset(c6.z);\n    float _263_fa_pad16 : packoffset(c6.w);\n    float _263_waveSpeed : packoffset(c7);\n    float _263_fa_pad17 : packoffset(c7.y);\n    float _263_fa_pad18 : packoffset(c7.z);\n    float _263_fa_pad19 : packoffset(c7.w);\n};\n\nTexture2D<float4> fa_scene_tex : register(t1);\nSamplerState light_smp : register(s1);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 frag_color;\nstatic float3 xform;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _106 = fa_linear_to_srgb(param);\n        c = _106;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _115 = fa_srgb_to_linear(param_1);\n            c = _115;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _191 = gl_FragCoord.xy * _130_fa_target.xy;\n    float _195 = _191.y;\n    return float2(_191.x, lerp(_195, 1.0f - _195, _130_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _235 = base_mode < 0.5f;\n    bool _246;\n    if (!_235)\n    {\n        _246 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _246 = _235;\n    }\n    float _247;\n    if (_246)\n    {\n        _247 = shape_half.x;\n    }\n    else\n    {\n        _247 = 0.0f;\n    }\n    QuadInput _414 = { uv, color, world_xy, fa_screen_uv(), _130_fa_time.x, base_mode, 0.0f.xxxx, _247 };\n    return _414;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_scene_color(float2 uv_1)\n{\n    if (_130_fa_scene.x <= 0.0f)\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _152 = (uv_1 * _130_fa_scene.xy) + _130_fa_scene.zw;\n    float _155 = _152.y;\n    _152.y = lerp(_155, 1.0f - _155, _130_fa_target.z);\n    return fa_scene_tex.SampleLevel(light_smp, clamp(_152, 0.0f.xx, 1.0f.xx), 0.0f);\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float2 param = i.screen_uv + (float2(_263_refraction + _263_strength, 0.0f) * _130_fa_target.xy);\n    s.color = float4(lerp(fa_scene_color(param).xyz, _263_tint.xyz, _263_tint.w.xxx), 1.0f);\n}\n\nvoid frag_main()\n{\n    float4 _330 = tex.Sample(smp, uv);\n    float3 param = _330.xyz;\n    float param_1 = xform.y;\n    float3 _341 = fa_tex_fix(param, param_1);\n    frag_color = float4(_341, _330.w) * color;\n    float param_2 = 0.0f;\n    float4 _394 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _396 = { _394 };\n    QuadSurface param_4 = _396;\n    fragment(param_3, param_4);\n    _394 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    xform = stage_input.xform;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 128,
            "struct_name": "fa_material",
            "inst_name": "_263",
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
