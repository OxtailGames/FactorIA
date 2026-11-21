{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "c463ccd1917be78236231aa4aa6bc7a9036af5c2e4c419a950fb6e8c51e433a6",
  "slang": "hlsl5",
  "params": [],
  "textures": [
    "mask"
  ],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _150 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _155 = _150;\n        _155.x = _82.x;\n        _155.y = _82.y;\n        _155.z = _82.z;\n        _150 = _155;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _150;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _687_lit : packoffset(c0);\n    float4 _687_ambient : packoffset(c1);\n    float4 _687_normal_uv : packoffset(c2);\n    float4 _687_flat_ambient : packoffset(c3);\n    float4 _687_light_map : packoffset(c4);\n    float4 _687_light_pos[16] : packoffset(c5);\n    float4 _687_light_color[16] : packoffset(c21);\n    float4 _687_light_shadow_v[16] : packoffset(c37);\n    float4 _687_fog_col : packoffset(c53);\n    float4 _687_fog_b : packoffset(c54);\n    float4 _687_fog_c : packoffset(c55);\n    float4 _687_fog_eye : packoffset(c56);\n    float4 _687_fa_time : packoffset(c57);\n    float4 _687_fa_target : packoffset(c58);\n    float4 _687_fx_emit : packoffset(c59);\n    float4 _687_fx_emit_uv : packoffset(c60);\n    float4 _687_fx_rim : packoffset(c61);\n    float4 _687_fx_rim_uv : packoffset(c62);\n    float4 _687_light_cookie[16] : packoffset(c63);\n    float4 _687_light_cookie_xf[16] : packoffset(c79);\n    float4 _687_gi_xf : packoffset(c95);\n    float4 _687_gi_p : packoffset(c96);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> mask : register(t4);\nSamplerState mask_smp : register(s3);\nTexture2D<float4> fx_cookie_tex : register(t6);\nSamplerState light_smp : register(s1);\nTexture2D<float4> fx_gi_tex : register(t7);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nTexture2D<float4> fx_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _625 = fa_linear_to_srgb(param);\n        c = _625;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _633 = fa_srgb_to_linear(param_1);\n            c = _633;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _644 = tex.Sample(smp, p);\n    float3 param = _644.xyz;\n    float param_1 = xform.y;\n    float3 _654 = fa_tex_fix(param, param_1);\n    return float4(_654, _644.w);\n}\n\nfloat3 gi_irradiance()\n{\n    float2 _821 = (world_xy * _687_gi_xf.xy) + _687_gi_xf.zw;\n    float4 _828 = fx_gi_tex.SampleLevel(light_smp, _821, 0.0f);\n    float _832 = _821.x;\n    bool _833 = _832 >= 0.0f;\n    bool _839;\n    if (_833)\n    {\n        _839 = _821.y >= 0.0f;\n    }\n    else\n    {\n        _839 = _833;\n    }\n    bool _845;\n    if (_839)\n    {\n        _845 = _832 <= 1.0f;\n    }\n    else\n    {\n        _845 = _839;\n    }\n    bool _851;\n    if (_845)\n    {\n        _851 = _821.y <= 1.0f;\n    }\n    else\n    {\n        _851 = _845;\n    }\n    bool _859;\n    if (_851)\n    {\n        _859 = _828.w > 0.0199999995529651641845703125f;\n    }\n    else\n    {\n        _859 = _851;\n    }\n    float3 _860;\n    if (_859)\n    {\n        _860 = (_828.xyz / _828.w.xxx) * _687_gi_p.x;\n    }\n    else\n    {\n        _860 = 0.0f.xxx;\n    }\n    return _860;\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _134 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_134.x * 255.0f) + 0.5f) * 256.0f) + floor((_134.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _237 = floor(tt);\n    float _247 = _237 - (1024.0f * floor(_237 * 0.0009765625f));\n    float _250 = _247 + 1.0f;\n    float i1 = _250;\n    if (_250 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _247;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5f, 0.0f, 1.0f), tt - _237);\n}\n\nfloat light_shadow_soft(float v, float size, float2 d, float radius)\n{\n    float _287 = length(d);\n    float result = 1.0f;\n    if (_287 >= 9.9999997473787516355514526367188e-05f)\n    {\n        float _298 = atan2(d.y, d.x);\n        float a = _298;\n        float _301;\n        if (_298 < 0.0f)\n        {\n            _301 = a + 6.283185482025146484375f;\n        }\n        else\n        {\n            _301 = a;\n        }\n        a = _301;\n        float _311 = _301 * 162.9746551513671875f;\n        float _320 = min((size * 10.0f) / _287, 0.699999988079071044921875f) * 162.9746551513671875f;\n        float sum = 0.0f;\n        float n = 0.0f;\n        for (int k = 0; k < 12; k++)\n        {\n            float _346 = floor(_311 + ((((float(k) + 0.5f) * 0.16666667163372039794921875f) - 1.0f) * _320));\n            float param = v;\n            float param_1 = _346 - (1024.0f * floor(_346 * 0.0009765625f));\n            float _360 = shadow_texel(param, param_1) * radius;\n            if (_360 < _287)\n            {\n                sum += _360;\n                n += 1.0f;\n            }\n        }\n        if (n > 0.5f)\n        {\n            float _392 = min(size * ((1.0f / max(sum / n, 1.0f)) - (1.0f / _287)), 0.699999988079071044921875f) * 162.9746551513671875f;\n            float acc = 0.0f;\n            float wsum = 0.0f;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _410 = ((float(k_1) + 0.5f) * 0.125f) - 1.0f;\n                float _416 = 1.0f - (0.800000011920928955078125f * abs(_410));\n                float param_2 = v;\n                float param_3 = _311 + (_410 * _392);\n                float param_4 = _287;\n                float param_5 = radius;\n                acc += (_416 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _416;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _158 = length(d);\n    if (_158 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _172 = atan2(d.y, d.x);\n    float a = _172;\n    float _175;\n    if (_172 < 0.0f)\n    {\n        _175 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _175 = a;\n    }\n    a = _175;\n    float _187 = _175 * 162.9746551513671875f;\n    float _192 = min(floor(_187), 1023.0f);\n    float _199 = _192 + 1.0f;\n    float i1 = _199;\n    if (_199 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _192;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _158) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _158) + 0.5f, 0.0f, 1.0f), _187 - _192);\n}\n\nfloat light_shadow_sized(float v, float size, float2 d, float radius)\n{\n    float r = 1.0f;\n    if (size > 0.0f)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nfloat3 cookie_coord(float4 cell, float4 xf, float2 off)\n{\n    float2 _497 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _501 = _497.x + 0.5f;\n    float2 c = float2(_501, 0.5f - _497.y);\n    bool _509 = _501 >= 0.0f;\n    bool _515;\n    if (_509)\n    {\n        _515 = c.x <= 1.0f;\n    }\n    else\n    {\n        _515 = _509;\n    }\n    bool _521;\n    if (_515)\n    {\n        _521 = c.y >= 0.0f;\n    }\n    else\n    {\n        _521 = _515;\n    }\n    bool _527;\n    if (_521)\n    {\n        _527 = c.y <= 1.0f;\n    }\n    else\n    {\n        _527 = _521;\n    }\n    float2 _529 = c;\n    float2 _534 = clamp(_529, 0.001953125f.xx, 0.998046875f.xx);\n    c = _534;\n    return float3(cell.x + (_534.x * cell.w), cell.y + (_534.y * cell.z), float(_527));\n}\n\nfloat cookie_value(float4 t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125f, 0.715200006961822509765625f, 0.072200000286102294921875f)) * t.w;\n}\n\nfloat cookie_att(int i, float2 d)\n{\n    if (_687_light_cookie[i].w == 0.0f)\n    {\n        return 1.0f;\n    }\n    float4 param = _687_light_cookie[i];\n    float4 param_1 = _687_light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _795 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.SampleLevel(light_smp, _795.xy, 0.0f);\n    return cookie_value(param_3) * _795.z;\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _882 = _687_lit.y > 0.5f;\n    if (_882)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _687_normal_uv.xy) + _687_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _906 = fa_tex_fix(param, param_1);\n        float3 _910 = (_906 * 2.0f) - 1.0f.xxx;\n        float _917 = cos(params.y);\n        float _919 = sin(params.y);\n        n = normalize(float3((float2(_917, _919) * _910.x) + ((float2(-_919, _917) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _910.y), max(_910.z, 0.0500000007450580596923828125f)));\n    }\n    bool _952 = !_882;\n    bool _958;\n    if (_952)\n    {\n        _958 = _687_lit.z > 0.5f;\n    }\n    else\n    {\n        _958 = _952;\n    }\n    float3 _961;\n    if (_958)\n    {\n        _961 = _687_flat_ambient.xyz;\n    }\n    else\n    {\n        _961 = _687_ambient.xyz;\n    }\n    float3 total = _961;\n    if (_687_gi_p.x > 0.0f)\n    {\n        total += gi_irradiance();\n    }\n    bool _986;\n    if (_958)\n    {\n        _986 = _687_lit.z < 1.5f;\n    }\n    else\n    {\n        _986 = _958;\n    }\n    if (_986)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _687_light_map.xy, 0.0f).xyz * _687_light_map.z);\n    }\n    float3 l;\n    float _1113;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1023;\n        if (!_958)\n        {\n            _1023 = float(i) >= _687_lit.x;\n        }\n        else\n        {\n            _1023 = _958;\n        }\n        if (_1023)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_687_light_pos[i].w < 0.0f)\n        {\n            l = _687_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _1049 = _687_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_1049) / max(_687_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _687_light_color[i].w);\n            float3 _1069 = float3(_1049, _687_light_pos[i].z);\n            l = _1069 / max(length(_1069), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_687_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _687_light_shadow_v[i].x;\n                float param_3 = _687_light_shadow_v[i].y;\n                float2 param_4 = -_1049;\n                float param_5 = _687_light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            float2 param_7 = -_1049;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_882)\n        {\n            _1113 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _1113 = 1.0f;\n        }\n        total += (_687_light_color[i].xyz * (att * _1113));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _670 = fa_srgb_to_linear(param);\n        c = _670;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _1363 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _1367 = uv * _1363;\n    float _1373 = _1363.x;\n    float _1375 = _1363.y;\n    float _1377 = clamp(shape_rs.x, 0.0f, min(_1373, _1375));\n    float2 _1388 = (abs(_1367) - _1363) + _1377.xx;\n    float d = (length(max(_1388, 0.0f.xx)) + min(max(_1388.x, _1388.y), 0.0f)) - _1377;\n    float ax = params.y;\n    bool _1409 = params.y > 15.0f;\n    if (_1409)\n    {\n        ax -= 20.0f;\n    }\n    float _1420;\n    if (ax <= (-1.5f))\n    {\n        _1420 = (-2.0f) - ax;\n    }\n    else\n    {\n        _1420 = 0.0f;\n    }\n    if (_1420 > 0.0f)\n    {\n        float _1434 = _1420 * 0.5f;\n        d = abs(d + _1434) - _1434;\n    }\n    float _1442 = fwidth(d);\n    float _1443 = max(_1442, 9.9999997473787516355514526367188e-05f);\n    float _1453 = clamp(0.5f - (d / max(shape_rs.y, _1443)), 0.0f, 1.0f);\n    float _1458;\n    if (shape_rs.y > _1443)\n    {\n        _1458 = (_1453 * _1453) * (3.0f - (2.0f * _1453));\n    }\n    else\n    {\n        _1458 = _1453;\n    }\n    float4 c = color;\n    bool _1480 = (_1420 <= 0.0f) && (ax > (-0.5f));\n    if (_1480)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1495 = cos(ax);\n            float _1497 = sin(ax);\n            g = ((dot(_1367, float2(_1495, _1497)) / max((abs(_1495) * _1373) + (abs(_1497) * _1375), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_1409)\n        {\n            float4 _1540 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _1540;\n            float3 param = _1540.xyz;\n            float param_1 = xform.y;\n            float3 _1547 = fa_tex_fix(param, param_1);\n            float4 _2341 = c;\n            _2341.x = _1547.x;\n            _2341.y = _1547.y;\n            _2341.z = _1547.z;\n            c = _2341;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1559 = scene_rgb(param_2);\n            float4 _1584 = lerp(float4(color.xyz * color.w, color.w), float4(_1559 * color2.w, color2.w), g.xxxx);\n            float _1586 = _1584.w;\n            float3 _1589;\n            if (_1586 > 9.9999997473787516355514526367188e-06f)\n            {\n                _1589 = _1584.xyz / _1586.xxx;\n            }\n            else\n            {\n                _1589 = color.xyz;\n            }\n            c = float4(_1589, _1586);\n        }\n    }\n    float4 _2350 = c;\n    _2350.w = _2350.w * _1458;\n    c = _2350;\n    if (_1480 || (shape_rs.y > 0.0f))\n    {\n        float _1630 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1639 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1639 + (_1630 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1645 = fa_srgb_to_linear(param_4);\n            float4 _2353 = c;\n            _2353.x = _1645.x;\n            _2353.y = _1645.y;\n            _2353.z = _1645.z;\n            c = _2353;\n        }\n        else\n        {\n            float4 _1655 = c;\n            float3 _1658 = _1655.xyz + (_1630 * 0.0039215688593685626983642578125f).xxx;\n            float4 _2360 = _1655;\n            _2360.x = _1658.x;\n            _2360.y = _1658.y;\n            _2360.z = _1658.z;\n            c = _2360;\n        }\n        float4 _2365 = c;\n        _2365.w = clamp(_2365.w + ((_1630 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _2365.w)), 0.0f, 1.0f);\n        c = _2365;\n    }\n    return c;\n}\n\nfloat3 rim_color(float a0, float mode)\n{\n    float2 _1150 = float2(_687_fx_rim_uv.x, 0.0f);\n    float4 _1152 = tex.Sample(smp, uv - _1150);\n    float _1153 = _1152.w;\n    float4 _1163 = tex.Sample(smp, uv + _1150);\n    float _1164 = _1163.w;\n    float2 _1172 = float2(0.0f, _687_fx_rim_uv.y);\n    float4 _1174 = tex.Sample(smp, uv - _1172);\n    float _1175 = _1174.w;\n    float4 _1185 = tex.Sample(smp, uv + _1172);\n    float _1186 = _1185.w;\n    float _1201 = _1153 - _1164;\n    float _1204 = _1186 - _1175;\n    float _1214 = cos(params.y);\n    float _1216 = sin(params.y);\n    float2 _1242 = ((float2(_1214, _1216) * _1201) + ((float2(-_1216, _1214) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _1204)) / max(length(float2(_1201, _1204)), 9.9999997473787516355514526367188e-05f).xx;\n    float3 sum = 0.0f.xxx;\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _687_lit.x)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_687_light_pos[i].w < 0.0f)\n        {\n            to_l = _687_light_pos[i].xy / max(length(_687_light_pos[i].xy), 9.9999997473787516355514526367188e-05f).xx;\n        }\n        else\n        {\n            float2 _1288 = _687_light_pos[i].xy - world_xy;\n            float _1291 = length(_1288);\n            att = pow(clamp(1.0f - (_1291 / max(_687_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _687_light_color[i].w);\n            to_l = _1288 / max(_1291, 9.9999997473787516355514526367188e-05f).xx;\n            if (_687_light_shadow_v[i].x >= 0.0f)\n            {\n                float param = _687_light_shadow_v[i].x;\n                float param_1 = _687_light_shadow_v[i].y;\n                float2 param_2 = -_1288;\n                float param_3 = _687_light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1288;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (_687_light_color[i].xyz * (att * max(dot(_1242, to_l), 0.0f)));\n    }\n    return (sum * _687_fx_rim.xyz) * (a0 * (1.0f - min(min(_1153, _1164), min(_1175, _1186))));\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _693 = gl_FragCoord.xy * _687_fa_target.xy;\n    float _697 = _693.y;\n    return float2(_693.x, lerp(_697, 1.0f - _697, _687_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _735 = base_mode < 0.5f;\n    bool _746;\n    if (!_735)\n    {\n        _746 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _746 = _735;\n    }\n    float _747;\n    if (_746)\n    {\n        _747 = shape_half.x;\n    }\n    else\n    {\n        _747 = 0.0f;\n    }\n    QuadInput _2285 = { uv, color, world_xy, fa_screen_uv(), _687_fa_time.x, base_mode, 0.0f.xxxx, _747 };\n    return _2285;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float4 _766 = mask.Sample(mask_smp, 0.0500000007450580596923828125f.xx);\n    s.color.x = _766.x;\n    s.color.y = _766.y;\n    s.color.z = _766.z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1685 = params.x > 31.5f;\n    if (_1685)\n    {\n        mode -= 32.0f;\n    }\n    float _1693 = mode;\n    bool _1695 = _1693 > 15.5f;\n    if (_1695)\n    {\n        mode -= 16.0f;\n    }\n    float _1703 = mode;\n    bool _1705 = _1703 > 7.5f;\n    if (_1705)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1695)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1695)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1767 = tex_color(param_5);\n                float4 _1769 = _1767 * color;\n                float4 param_6 = _1769;\n                float param_7 = mode;\n                float _1776 = _1769.w;\n                frag_color = float4(lit_color(param_6, param_7), _1776);\n                if (_687_fx_rim.w > 0.5f)\n                {\n                    float param_8 = _1776;\n                    float param_9 = mode;\n                    float4 _1792 = frag_color;\n                    float3 _1794 = _1792.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1794.x;\n                    frag_color.y = _1794.y;\n                    frag_color.z = _1794.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1824 = length(uv);\n                    float _1827 = fwidth(_1824);\n                    float _1828 = max(_1827, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1824) / _1828) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1824) / _1828) + 0.5f, 0.0f, 1.0f) * clamp(((_1824 - params.y) / _1828) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1868 = clamp(1.0f - _1824, 0.0f, 1.0f);\n                            cov = (_1868 * _1868) * (3.0f - (2.0f * _1868));\n                        }\n                    }\n                    float3 _1877;\n                    if (_1695)\n                    {\n                        float4 param_10 = color;\n                        float param_11 = 5.0f;\n                        _1877 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1877 = color.xyz;\n                    }\n                    frag_color = float4(_1877, color.w * cov);\n                }\n            }\n        }\n    }\n    if (_687_fx_emit.w > 0.5f)\n    {\n        float3 e = _687_fx_emit.xyz;\n        if (_687_fx_emit.w > 1.5f)\n        {\n            float3 param_12 = fx_emissive_tex.Sample(smp, (uv * _687_fx_emit_uv.xy) + _687_fx_emit_uv.zw).xyz;\n            float param_13 = _687_fx_emit.w - 2.0f;\n            float3 _1932 = fa_tex_fix(param_12, param_13);\n            e *= _1932;\n        }\n        float4 _1936 = frag_color;\n        float3 _1938 = _1936.xyz + e;\n        frag_color.x = _1938.x;\n        frag_color.y = _1938.y;\n        frag_color.z = _1938.z;\n    }\n    float param_14 = mode;\n    float4 _2265 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface _2267 = { _2265 };\n    QuadSurface param_16 = _2267;\n    fragment(param_15, param_16);\n    _2265 = param_16.color;\n    frag_color = param_16.color;\n    if (_1685)\n    {\n        float4 _1964 = frag_color;\n        float3 param_17 = color2.xyz;\n        float3 _1969 = scene_rgb(param_17);\n        float3 _1973 = lerp(_1964.xyz, _1969, color2.w.xxx);\n        frag_color.x = _1973.x;\n        frag_color.y = _1973.y;\n        frag_color.z = _1973.z;\n    }\n    if (_1705)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1997 = _687_fog_col.w > 0.0f;\n    bool _2005;\n    if (!_1997)\n    {\n        _2005 = _687_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2005 = _1997;\n    }\n    if (_2005)\n    {\n        float3 _2019 = float3(world_xy, world_z) - _687_fog_eye.xyz;\n        float _2026 = dot(_2019, _687_fog_c.xyz);\n        bool _2030 = _687_fog_c.w > 0.5f;\n        float _2031;\n        if (_2030)\n        {\n            _2031 = _2026;\n        }\n        else\n        {\n            _2031 = length(_2019);\n        }\n        float _2043 = _2031 - _687_fog_b.x;\n        if (_2043 > 0.0f)\n        {\n            float _2052 = _687_fog_col.w * _2043;\n            float tau = _2052 * _2052;\n            if (_687_fog_b.y > 0.0f)\n            {\n                float _2068;\n                if (_2030)\n                {\n                    _2068 = world_xy.y - (_687_fog_c.y * _2026);\n                }\n                else\n                {\n                    _2068 = _687_fog_eye.y;\n                }\n                float _2089 = lerp(_2068, world_xy.y, clamp(_687_fog_b.x / _2031, 0.0f, 1.0f));\n                float _2093 = world_xy.y - _2089;\n                float _2098 = _2089 - _687_fog_b.z;\n                float _2103 = world_xy.y - _687_fog_b.z;\n                bool _2106 = _2098 <= 0.0f;\n                bool _2107 = !_2106;\n                bool _2113;\n                if (_2107)\n                {\n                    _2113 = _687_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2113 = _2106;\n                }\n                float _2114;\n                if (_2113)\n                {\n                    _2114 = _687_fog_b.y;\n                }\n                else\n                {\n                    _2114 = _687_fog_b.y * exp(-min(_687_fog_b.w * _2098, 80.0f));\n                }\n                bool _2141;\n                if (_2107)\n                {\n                    _2141 = _687_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2141 = _2106;\n                }\n                float _2142;\n                if (_2141)\n                {\n                    _2142 = _687_fog_b.y * _2098;\n                }\n                else\n                {\n                    _2142 = (_687_fog_b.y * (1.0f - exp(-min(_687_fog_b.w * _2098, 80.0f)))) / _687_fog_b.w;\n                }\n                bool _2167 = _2103 <= 0.0f;\n                bool _2174;\n                if (!_2167)\n                {\n                    _2174 = _687_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2174 = _2167;\n                }\n                float _2175;\n                if (_2174)\n                {\n                    _2175 = _687_fog_b.y * _2103;\n                }\n                else\n                {\n                    _2175 = (_687_fog_b.y * (1.0f - exp(-min(_687_fog_b.w * _2103, 80.0f)))) / _687_fog_b.w;\n                }\n                float _2202;\n                if (abs(_2093) < 0.001000000047497451305389404296875f)\n                {\n                    _2202 = _2114;\n                }\n                else\n                {\n                    _2202 = (_2175 - _2142) / _2093;\n                }\n                tau += (_2043 * max(_2202, 0.0f));\n            }\n            float4 _2225 = frag_color;\n            float3 _2233 = lerp(_2225.xyz, _687_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _2233.x;\n            frag_color.y = _2233.y;\n            frag_color.z = _2233.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 1552,
            "struct_name": "quad_fs_params",
            "inst_name": "_687",
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
              "slot": 12,
              "stage": "fragment",
              "name": "fx_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
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
              "hlsl_register_t_n": 6
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
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _129_lit : packoffset(c0);\n    float4 _129_ambient : packoffset(c1);\n    float4 _129_normal_uv : packoffset(c2);\n    float4 _129_flat_ambient : packoffset(c3);\n    float4 _129_light_map : packoffset(c4);\n    float4 _129_light_pos[16] : packoffset(c5);\n    float4 _129_light_color[16] : packoffset(c21);\n    float4 _129_light_shadow_v[16] : packoffset(c37);\n    float4 _129_fog_col : packoffset(c53);\n    float4 _129_fog_b : packoffset(c54);\n    float4 _129_fog_c : packoffset(c55);\n    float4 _129_fog_eye : packoffset(c56);\n    float4 _129_fa_time : packoffset(c57);\n    float4 _129_fa_target : packoffset(c58);\n    float4 _129_fx_emit : packoffset(c59);\n    float4 _129_fx_emit_uv : packoffset(c60);\n    float4 _129_fx_rim : packoffset(c61);\n    float4 _129_fx_rim_uv : packoffset(c62);\n    float4 _129_light_cookie[16] : packoffset(c63);\n    float4 _129_light_cookie_xf[16] : packoffset(c79);\n    float4 _129_gi_xf : packoffset(c95);\n    float4 _129_gi_p : packoffset(c96);\n};\n\nTexture2D<float4> mask : register(t1);\nSamplerState mask_smp : register(s3);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 frag_color;\nstatic float3 xform;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _136 = gl_FragCoord.xy * _129_fa_target.xy;\n    float _142 = _136.y;\n    return float2(_136.x, lerp(_142, 1.0f - _142, _129_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _186 = base_mode < 0.5f;\n    bool _197;\n    if (!_186)\n    {\n        _197 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _197 = _186;\n    }\n    float _198;\n    if (_197)\n    {\n        _198 = shape_half.x;\n    }\n    else\n    {\n        _198 = 0.0f;\n    }\n    QuadInput _323 = { uv, color, world_xy, fa_screen_uv(), _129_fa_time.x, base_mode, 0.0f.xxxx, _198 };\n    return _323;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float4 _223 = mask.Sample(mask_smp, 0.0500000007450580596923828125f.xx);\n    s.color.x = _223.x;\n    s.color.y = _223.y;\n    s.color.z = _223.z;\n}\n\nvoid frag_main()\n{\n    float4 _238 = tex.Sample(smp, uv);\n    float3 param = _238.xyz;\n    float param_1 = xform.y;\n    float3 _249 = fa_tex_fix(param, param_1);\n    frag_color = float4(_249, _238.w) * color;\n    float param_2 = 0.0f;\n    float4 _303 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _305 = { _303 };\n    QuadSurface param_4 = _305;\n    fragment(param_3, param_4);\n    _303 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    xform = stage_input.xform;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 1552,
            "struct_name": "quad_fs_params",
            "inst_name": "_129",
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
