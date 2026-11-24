{
  "format": "factoria.shader/1",
  "engine": "0.35.2",
  "template": "d75bc1c2988d2355d3b6c4618a7c68ff76094f3e9d32765c88b7244d10541da4",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _144 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _144;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _688_lit : packoffset(c0);\n    float4 _688_ambient : packoffset(c1);\n    float4 _688_normal_uv : packoffset(c2);\n    float4 _688_flat_ambient : packoffset(c3);\n    float4 _688_light_map : packoffset(c4);\n    float4 _688_light_pos[16] : packoffset(c5);\n    float4 _688_light_color[16] : packoffset(c21);\n    float4 _688_light_shadow_v[16] : packoffset(c37);\n    float4 _688_fog_col : packoffset(c53);\n    float4 _688_fog_b : packoffset(c54);\n    float4 _688_fog_c : packoffset(c55);\n    float4 _688_fog_eye : packoffset(c56);\n    float4 _688_fa_time : packoffset(c57);\n    float4 _688_fa_target : packoffset(c58);\n    float4 _688_fx_emit : packoffset(c59);\n    float4 _688_fx_emit_uv : packoffset(c60);\n    float4 _688_fx_rim : packoffset(c61);\n    float4 _688_fx_rim_uv : packoffset(c62);\n    float4 _688_light_cookie[16] : packoffset(c63);\n    float4 _688_light_cookie_xf[16] : packoffset(c79);\n    float4 _688_fa_scene : packoffset(c95);\n    float4 _688_fa_world_uv[3] : packoffset(c96);\n    float4 _688_gi_xf : packoffset(c99);\n    float4 _688_gi_p : packoffset(c100);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> fx_cookie_tex : register(t5);\nSamplerState light_smp : register(s1);\nTexture2D<float4> fx_gi_tex : register(t6);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nTexture2D<float4> fx_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _625 = fa_linear_to_srgb(param);\n        c = _625;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _633 = fa_srgb_to_linear(param_1);\n            c = _633;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _644 = tex.Sample(smp, p);\n    float3 param = _644.xyz;\n    float param_1 = xform.y;\n    float3 _654 = fa_tex_fix(param, param_1);\n    return float4(_654, _644.w);\n}\n\nfloat3 gi_irradiance()\n{\n    float2 _819 = (world_xy * _688_gi_xf.xy) + _688_gi_xf.zw;\n    float4 _826 = fx_gi_tex.SampleLevel(light_smp, _819, 0.0f);\n    float _830 = _819.x;\n    bool _831 = _830 >= 0.0f;\n    bool _837;\n    if (_831)\n    {\n        _837 = _819.y >= 0.0f;\n    }\n    else\n    {\n        _837 = _831;\n    }\n    bool _843;\n    if (_837)\n    {\n        _843 = _830 <= 1.0f;\n    }\n    else\n    {\n        _843 = _837;\n    }\n    bool _849;\n    if (_843)\n    {\n        _849 = _819.y <= 1.0f;\n    }\n    else\n    {\n        _849 = _843;\n    }\n    bool _857;\n    if (_849)\n    {\n        _857 = _826.w > 0.0199999995529651641845703125f;\n    }\n    else\n    {\n        _857 = _849;\n    }\n    float3 _858;\n    if (_857)\n    {\n        _858 = (_826.xyz / _826.w.xxx) * _688_gi_p.x;\n    }\n    else\n    {\n        _858 = 0.0f.xxx;\n    }\n    return _858;\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _134 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_134.x * 255.0f) + 0.5f) * 256.0f) + floor((_134.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _237 = floor(tt);\n    float _247 = _237 - (1024.0f * floor(_237 * 0.0009765625f));\n    float _250 = _247 + 1.0f;\n    float i1 = _250;\n    if (_250 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _247;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5f, 0.0f, 1.0f), tt - _237);\n}\n\nfloat light_shadow_soft(float v, float size, float2 d, float radius)\n{\n    float _287 = length(d);\n    float result = 1.0f;\n    if (_287 >= 9.9999997473787516355514526367188e-05f)\n    {\n        float _298 = atan2(d.y, d.x);\n        float a = _298;\n        float _301;\n        if (_298 < 0.0f)\n        {\n            _301 = a + 6.283185482025146484375f;\n        }\n        else\n        {\n            _301 = a;\n        }\n        a = _301;\n        float _311 = _301 * 162.9746551513671875f;\n        float _320 = min((size * 10.0f) / _287, 0.699999988079071044921875f) * 162.9746551513671875f;\n        float sum = 0.0f;\n        float n = 0.0f;\n        for (int k = 0; k < 12; k++)\n        {\n            float _346 = floor(_311 + ((((float(k) + 0.5f) * 0.16666667163372039794921875f) - 1.0f) * _320));\n            float param = v;\n            float param_1 = _346 - (1024.0f * floor(_346 * 0.0009765625f));\n            float _360 = shadow_texel(param, param_1) * radius;\n            if (_360 < _287)\n            {\n                sum += _360;\n                n += 1.0f;\n            }\n        }\n        if (n > 0.5f)\n        {\n            float _392 = min(size * ((1.0f / max(sum / n, 1.0f)) - (1.0f / _287)), 0.699999988079071044921875f) * 162.9746551513671875f;\n            float acc = 0.0f;\n            float wsum = 0.0f;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _410 = ((float(k_1) + 0.5f) * 0.125f) - 1.0f;\n                float _416 = 1.0f - (0.800000011920928955078125f * abs(_410));\n                float param_2 = v;\n                float param_3 = _311 + (_410 * _392);\n                float param_4 = _287;\n                float param_5 = radius;\n                acc += (_416 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _416;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _158 = length(d);\n    if (_158 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _172 = atan2(d.y, d.x);\n    float a = _172;\n    float _175;\n    if (_172 < 0.0f)\n    {\n        _175 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _175 = a;\n    }\n    a = _175;\n    float _187 = _175 * 162.9746551513671875f;\n    float _192 = min(floor(_187), 1023.0f);\n    float _199 = _192 + 1.0f;\n    float i1 = _199;\n    if (_199 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _192;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _158) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _158) + 0.5f, 0.0f, 1.0f), _187 - _192);\n}\n\nfloat light_shadow_sized(float v, float size, float2 d, float radius)\n{\n    float r = 1.0f;\n    if (size > 0.0f)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nfloat3 cookie_coord(float4 cell, float4 xf, float2 off)\n{\n    float2 _497 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _501 = _497.x + 0.5f;\n    float2 c = float2(_501, 0.5f - _497.y);\n    bool _509 = _501 >= 0.0f;\n    bool _515;\n    if (_509)\n    {\n        _515 = c.x <= 1.0f;\n    }\n    else\n    {\n        _515 = _509;\n    }\n    bool _521;\n    if (_515)\n    {\n        _521 = c.y >= 0.0f;\n    }\n    else\n    {\n        _521 = _515;\n    }\n    bool _527;\n    if (_521)\n    {\n        _527 = c.y <= 1.0f;\n    }\n    else\n    {\n        _527 = _521;\n    }\n    float2 _529 = c;\n    float2 _534 = clamp(_529, 0.001953125f.xx, 0.998046875f.xx);\n    c = _534;\n    return float3(cell.x + (_534.x * cell.w), cell.y + (_534.y * cell.z), float(_527));\n}\n\nfloat cookie_value(float4 t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125f, 0.715200006961822509765625f, 0.072200000286102294921875f)) * t.w;\n}\n\nfloat cookie_att(int i, float2 d)\n{\n    if (_688_light_cookie[i].w == 0.0f)\n    {\n        return 1.0f;\n    }\n    float4 param = _688_light_cookie[i];\n    float4 param_1 = _688_light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _793 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.SampleLevel(light_smp, _793.xy, 0.0f);\n    return cookie_value(param_3) * _793.z;\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _880 = _688_lit.y > 0.5f;\n    if (_880)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _688_normal_uv.xy) + _688_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _904 = fa_tex_fix(param, param_1);\n        float3 _908 = (_904 * 2.0f) - 1.0f.xxx;\n        float _915 = cos(params.y);\n        float _917 = sin(params.y);\n        n = normalize(float3((float2(_915, _917) * _908.x) + ((float2(-_917, _915) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _908.y), max(_908.z, 0.0500000007450580596923828125f)));\n    }\n    bool _951 = !_880;\n    bool _957;\n    if (_951)\n    {\n        _957 = _688_lit.z > 0.5f;\n    }\n    else\n    {\n        _957 = _951;\n    }\n    float3 _960;\n    if (_957)\n    {\n        _960 = _688_flat_ambient.xyz;\n    }\n    else\n    {\n        _960 = _688_ambient.xyz;\n    }\n    float3 total = _960;\n    if (_688_gi_p.x > 0.0f)\n    {\n        total += gi_irradiance();\n    }\n    bool _985;\n    if (_957)\n    {\n        _985 = _688_lit.z < 1.5f;\n    }\n    else\n    {\n        _985 = _957;\n    }\n    if (_985)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _688_light_map.xy, 0.0f).xyz * _688_light_map.z);\n    }\n    float3 l;\n    float _1112;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1022;\n        if (!_957)\n        {\n            _1022 = float(i) >= _688_lit.x;\n        }\n        else\n        {\n            _1022 = _957;\n        }\n        if (_1022)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_688_light_pos[i].w < 0.0f)\n        {\n            l = _688_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _1048 = _688_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_1048) / max(_688_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _688_light_color[i].w);\n            float3 _1068 = float3(_1048, _688_light_pos[i].z);\n            l = _1068 / max(length(_1068), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_688_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _688_light_shadow_v[i].x;\n                float param_3 = _688_light_shadow_v[i].y;\n                float2 param_4 = -_1048;\n                float param_5 = _688_light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            float2 param_7 = -_1048;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_880)\n        {\n            _1112 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _1112 = 1.0f;\n        }\n        total += (_688_light_color[i].xyz * (att * _1112));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _670 = fa_srgb_to_linear(param);\n        c = _670;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _1362 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _1366 = uv * _1362;\n    float _1372 = _1362.x;\n    float _1374 = _1362.y;\n    float _1376 = clamp(shape_rs.x, 0.0f, min(_1372, _1374));\n    float2 _1387 = (abs(_1366) - _1362) + _1376.xx;\n    float d = (length(max(_1387, 0.0f.xx)) + min(max(_1387.x, _1387.y), 0.0f)) - _1376;\n    float ax = params.y;\n    bool _1408 = params.y > 15.0f;\n    if (_1408)\n    {\n        ax -= 20.0f;\n    }\n    float _1419;\n    if (ax <= (-1.5f))\n    {\n        _1419 = (-2.0f) - ax;\n    }\n    else\n    {\n        _1419 = 0.0f;\n    }\n    if (_1419 > 0.0f)\n    {\n        float _1433 = _1419 * 0.5f;\n        d = abs(d + _1433) - _1433;\n    }\n    float _1441 = fwidth(d);\n    float _1442 = max(_1441, 9.9999997473787516355514526367188e-05f);\n    float _1452 = clamp(0.5f - (d / max(shape_rs.y, _1442)), 0.0f, 1.0f);\n    float _1457;\n    if (shape_rs.y > _1442)\n    {\n        _1457 = (_1452 * _1452) * (3.0f - (2.0f * _1452));\n    }\n    else\n    {\n        _1457 = _1452;\n    }\n    float4 c = color;\n    bool _1479 = (_1419 <= 0.0f) && (ax > (-0.5f));\n    if (_1479)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1494 = cos(ax);\n            float _1496 = sin(ax);\n            g = ((dot(_1366, float2(_1494, _1496)) / max((abs(_1494) * _1372) + (abs(_1496) * _1374), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_1408)\n        {\n            float4 _1539 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _1539;\n            float3 param = _1539.xyz;\n            float param_1 = xform.y;\n            float3 _1546 = fa_tex_fix(param, param_1);\n            float4 _2341 = c;\n            _2341.x = _1546.x;\n            _2341.y = _1546.y;\n            _2341.z = _1546.z;\n            c = _2341;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1558 = scene_rgb(param_2);\n            float4 _1583 = lerp(float4(color.xyz * color.w, color.w), float4(_1558 * color2.w, color2.w), g.xxxx);\n            float _1585 = _1583.w;\n            float3 _1588;\n            if (_1585 > 9.9999997473787516355514526367188e-06f)\n            {\n                _1588 = _1583.xyz / _1585.xxx;\n            }\n            else\n            {\n                _1588 = color.xyz;\n            }\n            c = float4(_1588, _1585);\n        }\n    }\n    float4 _2350 = c;\n    _2350.w = _2350.w * _1457;\n    c = _2350;\n    if (_1479 || (shape_rs.y > 0.0f))\n    {\n        float _1629 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1638 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1638 + (_1629 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1644 = fa_srgb_to_linear(param_4);\n            float4 _2353 = c;\n            _2353.x = _1644.x;\n            _2353.y = _1644.y;\n            _2353.z = _1644.z;\n            c = _2353;\n        }\n        else\n        {\n            float4 _1654 = c;\n            float3 _1657 = _1654.xyz + (_1629 * 0.0039215688593685626983642578125f).xxx;\n            float4 _2360 = _1654;\n            _2360.x = _1657.x;\n            _2360.y = _1657.y;\n            _2360.z = _1657.z;\n            c = _2360;\n        }\n        float4 _2365 = c;\n        _2365.w = clamp(_2365.w + ((_1629 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _2365.w)), 0.0f, 1.0f);\n        c = _2365;\n    }\n    return c;\n}\n\nfloat3 rim_color(float a0, float mode)\n{\n    float2 _1149 = float2(_688_fx_rim_uv.x, 0.0f);\n    float4 _1151 = tex.Sample(smp, uv - _1149);\n    float _1152 = _1151.w;\n    float4 _1162 = tex.Sample(smp, uv + _1149);\n    float _1163 = _1162.w;\n    float2 _1171 = float2(0.0f, _688_fx_rim_uv.y);\n    float4 _1173 = tex.Sample(smp, uv - _1171);\n    float _1174 = _1173.w;\n    float4 _1184 = tex.Sample(smp, uv + _1171);\n    float _1185 = _1184.w;\n    float _1200 = _1152 - _1163;\n    float _1203 = _1185 - _1174;\n    float _1213 = cos(params.y);\n    float _1215 = sin(params.y);\n    float2 _1241 = ((float2(_1213, _1215) * _1200) + ((float2(-_1215, _1213) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _1203)) / max(length(float2(_1200, _1203)), 9.9999997473787516355514526367188e-05f).xx;\n    float3 sum = 0.0f.xxx;\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _688_lit.x)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_688_light_pos[i].w < 0.0f)\n        {\n            to_l = _688_light_pos[i].xy / max(length(_688_light_pos[i].xy), 9.9999997473787516355514526367188e-05f).xx;\n        }\n        else\n        {\n            float2 _1287 = _688_light_pos[i].xy - world_xy;\n            float _1290 = length(_1287);\n            att = pow(clamp(1.0f - (_1290 / max(_688_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _688_light_color[i].w);\n            to_l = _1287 / max(_1290, 9.9999997473787516355514526367188e-05f).xx;\n            if (_688_light_shadow_v[i].x >= 0.0f)\n            {\n                float param = _688_light_shadow_v[i].x;\n                float param_1 = _688_light_shadow_v[i].y;\n                float2 param_2 = -_1287;\n                float param_3 = _688_light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1287;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (_688_light_color[i].xyz * (att * max(dot(_1241, to_l), 0.0f)));\n    }\n    return (sum * _688_fx_rim.xyz) * (a0 * (1.0f - min(min(_1152, _1163), min(_1174, _1185))));\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _694 = gl_FragCoord.xy * _688_fa_target.xy;\n    float _698 = _694.y;\n    return float2(_694.x, lerp(_698, 1.0f - _698, _688_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _736 = base_mode < 0.5f;\n    bool _747;\n    if (!_736)\n    {\n        _747 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _747 = _736;\n    }\n    float _748;\n    if (_747)\n    {\n        _748 = shape_half.x;\n    }\n    else\n    {\n        _748 = 0.0f;\n    }\n    QuadInput _2285 = { uv, color, world_xy, fa_screen_uv(), _688_fa_time.x, base_mode, 0.0f.xxxx, _748 };\n    return _2285;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = clamp(i.time * 0.25f, 0.0f, 1.0f);\n    s.color.y = 0.0f;\n    s.color.z = 0.0f;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1684 = params.x > 31.5f;\n    if (_1684)\n    {\n        mode -= 32.0f;\n    }\n    float _1692 = mode;\n    bool _1694 = _1692 > 15.5f;\n    if (_1694)\n    {\n        mode -= 16.0f;\n    }\n    float _1702 = mode;\n    bool _1704 = _1702 > 7.5f;\n    if (_1704)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1694)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1694)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1766 = tex_color(param_5);\n                float4 _1768 = _1766 * color;\n                float4 param_6 = _1768;\n                float param_7 = mode;\n                float _1775 = _1768.w;\n                frag_color = float4(lit_color(param_6, param_7), _1775);\n                if (_688_fx_rim.w > 0.5f)\n                {\n                    float param_8 = _1775;\n                    float param_9 = mode;\n                    float4 _1791 = frag_color;\n                    float3 _1793 = _1791.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1793.x;\n                    frag_color.y = _1793.y;\n                    frag_color.z = _1793.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1823 = length(uv);\n                    float _1826 = fwidth(_1823);\n                    float _1827 = max(_1826, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1823) / _1827) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1823) / _1827) + 0.5f, 0.0f, 1.0f) * clamp(((_1823 - params.y) / _1827) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1867 = clamp(1.0f - _1823, 0.0f, 1.0f);\n                            cov = (_1867 * _1867) * (3.0f - (2.0f * _1867));\n                        }\n                    }\n                    float3 _1876;\n                    if (_1694)\n                    {\n                        float4 param_10 = color;\n                        float param_11 = 5.0f;\n                        _1876 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1876 = color.xyz;\n                    }\n                    frag_color = float4(_1876, color.w * cov);\n                }\n            }\n        }\n    }\n    if (_688_fx_emit.w > 0.5f)\n    {\n        float3 e = _688_fx_emit.xyz;\n        if (_688_fx_emit.w > 1.5f)\n        {\n            float3 param_12 = fx_emissive_tex.Sample(smp, (uv * _688_fx_emit_uv.xy) + _688_fx_emit_uv.zw).xyz;\n            float param_13 = _688_fx_emit.w - 2.0f;\n            float3 _1931 = fa_tex_fix(param_12, param_13);\n            e *= _1931;\n        }\n        float4 _1935 = frag_color;\n        float3 _1937 = _1935.xyz + e;\n        frag_color.x = _1937.x;\n        frag_color.y = _1937.y;\n        frag_color.z = _1937.z;\n    }\n    float param_14 = mode;\n    float4 _2265 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface _2267 = { _2265 };\n    QuadSurface param_16 = _2267;\n    fragment(param_15, param_16);\n    _2265 = param_16.color;\n    frag_color = param_16.color;\n    if (_1684)\n    {\n        float4 _1963 = frag_color;\n        float3 param_17 = color2.xyz;\n        float3 _1968 = scene_rgb(param_17);\n        float3 _1972 = lerp(_1963.xyz, _1968, color2.w.xxx);\n        frag_color.x = _1972.x;\n        frag_color.y = _1972.y;\n        frag_color.z = _1972.z;\n    }\n    if (_1704)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1996 = _688_fog_col.w > 0.0f;\n    bool _2004;\n    if (!_1996)\n    {\n        _2004 = _688_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2004 = _1996;\n    }\n    if (_2004)\n    {\n        float3 _2018 = float3(world_xy, world_z) - _688_fog_eye.xyz;\n        float _2025 = dot(_2018, _688_fog_c.xyz);\n        bool _2029 = _688_fog_c.w > 0.5f;\n        float _2030;\n        if (_2029)\n        {\n            _2030 = _2025;\n        }\n        else\n        {\n            _2030 = length(_2018);\n        }\n        float _2042 = _2030 - _688_fog_b.x;\n        if (_2042 > 0.0f)\n        {\n            float _2051 = _688_fog_col.w * _2042;\n            float tau = _2051 * _2051;\n            if (_688_fog_b.y > 0.0f)\n            {\n                float _2067;\n                if (_2029)\n                {\n                    _2067 = world_xy.y - (_688_fog_c.y * _2025);\n                }\n                else\n                {\n                    _2067 = _688_fog_eye.y;\n                }\n                float _2088 = lerp(_2067, world_xy.y, clamp(_688_fog_b.x / _2030, 0.0f, 1.0f));\n                float _2092 = world_xy.y - _2088;\n                float _2097 = _2088 - _688_fog_b.z;\n                float _2102 = world_xy.y - _688_fog_b.z;\n                bool _2105 = _2097 <= 0.0f;\n                bool _2106 = !_2105;\n                bool _2112;\n                if (_2106)\n                {\n                    _2112 = _688_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2112 = _2105;\n                }\n                float _2113;\n                if (_2112)\n                {\n                    _2113 = _688_fog_b.y;\n                }\n                else\n                {\n                    _2113 = _688_fog_b.y * exp(-min(_688_fog_b.w * _2097, 80.0f));\n                }\n                bool _2140;\n                if (_2106)\n                {\n                    _2140 = _688_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2140 = _2105;\n                }\n                float _2141;\n                if (_2140)\n                {\n                    _2141 = _688_fog_b.y * _2097;\n                }\n                else\n                {\n                    _2141 = (_688_fog_b.y * (1.0f - exp(-min(_688_fog_b.w * _2097, 80.0f)))) / _688_fog_b.w;\n                }\n                bool _2166 = _2102 <= 0.0f;\n                bool _2173;\n                if (!_2166)\n                {\n                    _2173 = _688_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2173 = _2166;\n                }\n                float _2174;\n                if (_2173)\n                {\n                    _2174 = _688_fog_b.y * _2102;\n                }\n                else\n                {\n                    _2174 = (_688_fog_b.y * (1.0f - exp(-min(_688_fog_b.w * _2102, 80.0f)))) / _688_fog_b.w;\n                }\n                float _2201;\n                if (abs(_2092) < 0.001000000047497451305389404296875f)\n                {\n                    _2201 = _2113;\n                }\n                else\n                {\n                    _2201 = (_2174 - _2141) / _2092;\n                }\n                tau += (_2042 * max(_2201, 0.0f));\n            }\n            float4 _2224 = frag_color;\n            float3 _2232 = lerp(_2224.xyz, _688_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _2232.x;\n            frag_color.y = _2232.y;\n            frag_color.z = _2232.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_688",
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
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _144 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _144;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _131_lit : packoffset(c0);\n    float4 _131_ambient : packoffset(c1);\n    float4 _131_normal_uv : packoffset(c2);\n    float4 _131_flat_ambient : packoffset(c3);\n    float4 _131_light_map : packoffset(c4);\n    float4 _131_light_pos[16] : packoffset(c5);\n    float4 _131_light_color[16] : packoffset(c21);\n    float4 _131_light_shadow_v[16] : packoffset(c37);\n    float4 _131_fog_col : packoffset(c53);\n    float4 _131_fog_b : packoffset(c54);\n    float4 _131_fog_c : packoffset(c55);\n    float4 _131_fog_eye : packoffset(c56);\n    float4 _131_fa_time : packoffset(c57);\n    float4 _131_fa_target : packoffset(c58);\n    float4 _131_fx_emit : packoffset(c59);\n    float4 _131_fx_emit_uv : packoffset(c60);\n    float4 _131_fx_rim : packoffset(c61);\n    float4 _131_fx_rim_uv : packoffset(c62);\n    float4 _131_light_cookie[16] : packoffset(c63);\n    float4 _131_light_cookie_xf[16] : packoffset(c79);\n    float4 _131_fa_scene : packoffset(c95);\n    float4 _131_fa_world_uv[3] : packoffset(c96);\n    float4 _131_gi_xf : packoffset(c99);\n    float4 _131_gi_p : packoffset(c100);\n};\n\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 frag_color;\nstatic float3 xform;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _138 = gl_FragCoord.xy * _131_fa_target.xy;\n    float _144 = _138.y;\n    return float2(_138.x, lerp(_144, 1.0f - _144, _131_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _188 = base_mode < 0.5f;\n    bool _199;\n    if (!_188)\n    {\n        _199 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _199 = _188;\n    }\n    float _200;\n    if (_199)\n    {\n        _200 = shape_half.x;\n    }\n    else\n    {\n        _200 = 0.0f;\n    }\n    QuadInput _323 = { uv, color, world_xy, fa_screen_uv(), _131_fa_time.x, base_mode, 0.0f.xxxx, _200 };\n    return _323;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = clamp(i.time * 0.25f, 0.0f, 1.0f);\n    s.color.y = 0.0f;\n    s.color.z = 0.0f;\n}\n\nvoid frag_main()\n{\n    float4 _237 = tex.Sample(smp, uv);\n    float3 param = _237.xyz;\n    float param_1 = xform.y;\n    float3 _248 = fa_tex_fix(param, param_1);\n    frag_color = float4(_248, _237.w) * color;\n    float param_2 = 0.0f;\n    float4 _303 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _305 = { _303 };\n    QuadSurface param_4 = _305;\n    fragment(param_3, param_4);\n    _303 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    xform = stage_input.xform;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
