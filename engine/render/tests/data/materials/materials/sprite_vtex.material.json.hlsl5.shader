{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "d75bc1c2988d2355d3b6c4618a7c68ff76094f3e9d32765c88b7244d10541da4",
  "slang": "hlsl5",
  "params": [],
  "textures": [
    "mask"
  ],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "struct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\ncbuffer vs_params : register(b0)\n{\n    row_major float4x4 _96_view_proj : packoffset(c0);\n    float4 _96_cspace : packoffset(c4);\n    float4 _96_fa_time : packoffset(c5);\n};\n\nTexture2D<float4> fa_vs_mask : register(t0);\nSamplerState fa_vs_mask_smp : register(s7);\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += (fa_vs_mask.SampleLevel(fa_vs_mask_smp, float2(0.4000000059604644775390625f, 0.0500000007450580596923828125f), 0.0f).x * 40.0f);\n}\n\nvoid vert_main()\n{\n    float3 _171 = position;\n    float2 _172 = texcoord0;\n    float4 _173 = color0;\n    if (_96_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _108 = fa_srgb_to_linear(param);\n        float4 _185 = _173;\n        _185.x = _108.x;\n        _185.y = _108.y;\n        _185.z = _108.z;\n        _173 = _185;\n    }\n    QuadVertex _180 = { _171, _172, _173 };\n    QuadVertex param_1 = _180;\n    vertex(param_1);\n    _171 = param_1.world_pos;\n    _172 = param_1.uv;\n    _173 = param_1.color;\n    gl_Position = mul(float4(param_1.world_pos, 1.0f), _96_view_proj);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = _96_cspace.xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _688_lit : packoffset(c0);\n    float4 _688_ambient : packoffset(c1);\n    float4 _688_normal_uv : packoffset(c2);\n    float4 _688_flat_ambient : packoffset(c3);\n    float4 _688_light_map : packoffset(c4);\n    float4 _688_light_pos[16] : packoffset(c5);\n    float4 _688_light_color[16] : packoffset(c21);\n    float4 _688_light_shadow_v[16] : packoffset(c37);\n    float4 _688_fog_col : packoffset(c53);\n    float4 _688_fog_b : packoffset(c54);\n    float4 _688_fog_c : packoffset(c55);\n    float4 _688_fog_eye : packoffset(c56);\n    float4 _688_fa_time : packoffset(c57);\n    float4 _688_fa_target : packoffset(c58);\n    float4 _688_fx_emit : packoffset(c59);\n    float4 _688_fx_emit_uv : packoffset(c60);\n    float4 _688_fx_rim : packoffset(c61);\n    float4 _688_fx_rim_uv : packoffset(c62);\n    float4 _688_light_cookie[16] : packoffset(c63);\n    float4 _688_light_cookie_xf[16] : packoffset(c79);\n    float4 _688_fa_scene : packoffset(c95);\n    float4 _688_fa_world_uv[3] : packoffset(c96);\n    float4 _688_gi_xf : packoffset(c99);\n    float4 _688_gi_p : packoffset(c100);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> mask : register(t4);\nSamplerState mask_smp : register(s3);\nTexture2D<float4> fx_cookie_tex : register(t6);\nSamplerState light_smp : register(s1);\nTexture2D<float4> fx_gi_tex : register(t7);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nTexture2D<float4> fx_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _625 = fa_linear_to_srgb(param);\n        c = _625;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _633 = fa_srgb_to_linear(param_1);\n            c = _633;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _644 = tex.Sample(smp, p);\n    float3 param = _644.xyz;\n    float param_1 = xform.y;\n    float3 _654 = fa_tex_fix(param, param_1);\n    return float4(_654, _644.w);\n}\n\nfloat3 gi_irradiance()\n{\n    float2 _823 = (world_xy * _688_gi_xf.xy) + _688_gi_xf.zw;\n    float4 _830 = fx_gi_tex.SampleLevel(light_smp, _823, 0.0f);\n    float _834 = _823.x;\n    bool _835 = _834 >= 0.0f;\n    bool _841;\n    if (_835)\n    {\n        _841 = _823.y >= 0.0f;\n    }\n    else\n    {\n        _841 = _835;\n    }\n    bool _847;\n    if (_841)\n    {\n        _847 = _834 <= 1.0f;\n    }\n    else\n    {\n        _847 = _841;\n    }\n    bool _853;\n    if (_847)\n    {\n        _853 = _823.y <= 1.0f;\n    }\n    else\n    {\n        _853 = _847;\n    }\n    bool _861;\n    if (_853)\n    {\n        _861 = _830.w > 0.0199999995529651641845703125f;\n    }\n    else\n    {\n        _861 = _853;\n    }\n    float3 _862;\n    if (_861)\n    {\n        _862 = (_830.xyz / _830.w.xxx) * _688_gi_p.x;\n    }\n    else\n    {\n        _862 = 0.0f.xxx;\n    }\n    return _862;\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _134 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_134.x * 255.0f) + 0.5f) * 256.0f) + floor((_134.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _237 = floor(tt);\n    float _247 = _237 - (1024.0f * floor(_237 * 0.0009765625f));\n    float _250 = _247 + 1.0f;\n    float i1 = _250;\n    if (_250 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _247;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5f, 0.0f, 1.0f), tt - _237);\n}\n\nfloat light_shadow_soft(float v, float size, float2 d, float radius)\n{\n    float _287 = length(d);\n    float result = 1.0f;\n    if (_287 >= 9.9999997473787516355514526367188e-05f)\n    {\n        float _298 = atan2(d.y, d.x);\n        float a = _298;\n        float _301;\n        if (_298 < 0.0f)\n        {\n            _301 = a + 6.283185482025146484375f;\n        }\n        else\n        {\n            _301 = a;\n        }\n        a = _301;\n        float _311 = _301 * 162.9746551513671875f;\n        float _320 = min((size * 10.0f) / _287, 0.699999988079071044921875f) * 162.9746551513671875f;\n        float sum = 0.0f;\n        float n = 0.0f;\n        for (int k = 0; k < 12; k++)\n        {\n            float _346 = floor(_311 + ((((float(k) + 0.5f) * 0.16666667163372039794921875f) - 1.0f) * _320));\n            float param = v;\n            float param_1 = _346 - (1024.0f * floor(_346 * 0.0009765625f));\n            float _360 = shadow_texel(param, param_1) * radius;\n            if (_360 < _287)\n            {\n                sum += _360;\n                n += 1.0f;\n            }\n        }\n        if (n > 0.5f)\n        {\n            float _392 = min(size * ((1.0f / max(sum / n, 1.0f)) - (1.0f / _287)), 0.699999988079071044921875f) * 162.9746551513671875f;\n            float acc = 0.0f;\n            float wsum = 0.0f;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _410 = ((float(k_1) + 0.5f) * 0.125f) - 1.0f;\n                float _416 = 1.0f - (0.800000011920928955078125f * abs(_410));\n                float param_2 = v;\n                float param_3 = _311 + (_410 * _392);\n                float param_4 = _287;\n                float param_5 = radius;\n                acc += (_416 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _416;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _158 = length(d);\n    if (_158 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _172 = atan2(d.y, d.x);\n    float a = _172;\n    float _175;\n    if (_172 < 0.0f)\n    {\n        _175 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _175 = a;\n    }\n    a = _175;\n    float _187 = _175 * 162.9746551513671875f;\n    float _192 = min(floor(_187), 1023.0f);\n    float _199 = _192 + 1.0f;\n    float i1 = _199;\n    if (_199 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _192;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _158) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _158) + 0.5f, 0.0f, 1.0f), _187 - _192);\n}\n\nfloat light_shadow_sized(float v, float size, float2 d, float radius)\n{\n    float r = 1.0f;\n    if (size > 0.0f)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nfloat3 cookie_coord(float4 cell, float4 xf, float2 off)\n{\n    float2 _497 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _501 = _497.x + 0.5f;\n    float2 c = float2(_501, 0.5f - _497.y);\n    bool _509 = _501 >= 0.0f;\n    bool _515;\n    if (_509)\n    {\n        _515 = c.x <= 1.0f;\n    }\n    else\n    {\n        _515 = _509;\n    }\n    bool _521;\n    if (_515)\n    {\n        _521 = c.y >= 0.0f;\n    }\n    else\n    {\n        _521 = _515;\n    }\n    bool _527;\n    if (_521)\n    {\n        _527 = c.y <= 1.0f;\n    }\n    else\n    {\n        _527 = _521;\n    }\n    float2 _529 = c;\n    float2 _534 = clamp(_529, 0.001953125f.xx, 0.998046875f.xx);\n    c = _534;\n    return float3(cell.x + (_534.x * cell.w), cell.y + (_534.y * cell.z), float(_527));\n}\n\nfloat cookie_value(float4 t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125f, 0.715200006961822509765625f, 0.072200000286102294921875f)) * t.w;\n}\n\nfloat cookie_att(int i, float2 d)\n{\n    if (_688_light_cookie[i].w == 0.0f)\n    {\n        return 1.0f;\n    }\n    float4 param = _688_light_cookie[i];\n    float4 param_1 = _688_light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _797 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.SampleLevel(light_smp, _797.xy, 0.0f);\n    return cookie_value(param_3) * _797.z;\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _884 = _688_lit.y > 0.5f;\n    if (_884)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _688_normal_uv.xy) + _688_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _908 = fa_tex_fix(param, param_1);\n        float3 _912 = (_908 * 2.0f) - 1.0f.xxx;\n        float _919 = cos(params.y);\n        float _921 = sin(params.y);\n        n = normalize(float3((float2(_919, _921) * _912.x) + ((float2(-_921, _919) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _912.y), max(_912.z, 0.0500000007450580596923828125f)));\n    }\n    bool _954 = !_884;\n    bool _960;\n    if (_954)\n    {\n        _960 = _688_lit.z > 0.5f;\n    }\n    else\n    {\n        _960 = _954;\n    }\n    float3 _963;\n    if (_960)\n    {\n        _963 = _688_flat_ambient.xyz;\n    }\n    else\n    {\n        _963 = _688_ambient.xyz;\n    }\n    float3 total = _963;\n    if (_688_gi_p.x > 0.0f)\n    {\n        total += gi_irradiance();\n    }\n    bool _988;\n    if (_960)\n    {\n        _988 = _688_lit.z < 1.5f;\n    }\n    else\n    {\n        _988 = _960;\n    }\n    if (_988)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _688_light_map.xy, 0.0f).xyz * _688_light_map.z);\n    }\n    float3 l;\n    float _1115;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1025;\n        if (!_960)\n        {\n            _1025 = float(i) >= _688_lit.x;\n        }\n        else\n        {\n            _1025 = _960;\n        }\n        if (_1025)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_688_light_pos[i].w < 0.0f)\n        {\n            l = _688_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _1051 = _688_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_1051) / max(_688_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _688_light_color[i].w);\n            float3 _1071 = float3(_1051, _688_light_pos[i].z);\n            l = _1071 / max(length(_1071), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_688_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _688_light_shadow_v[i].x;\n                float param_3 = _688_light_shadow_v[i].y;\n                float2 param_4 = -_1051;\n                float param_5 = _688_light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            float2 param_7 = -_1051;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_884)\n        {\n            _1115 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _1115 = 1.0f;\n        }\n        total += (_688_light_color[i].xyz * (att * _1115));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _670 = fa_srgb_to_linear(param);\n        c = _670;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _1365 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _1369 = uv * _1365;\n    float _1375 = _1365.x;\n    float _1377 = _1365.y;\n    float _1379 = clamp(shape_rs.x, 0.0f, min(_1375, _1377));\n    float2 _1390 = (abs(_1369) - _1365) + _1379.xx;\n    float d = (length(max(_1390, 0.0f.xx)) + min(max(_1390.x, _1390.y), 0.0f)) - _1379;\n    float ax = params.y;\n    bool _1411 = params.y > 15.0f;\n    if (_1411)\n    {\n        ax -= 20.0f;\n    }\n    float _1422;\n    if (ax <= (-1.5f))\n    {\n        _1422 = (-2.0f) - ax;\n    }\n    else\n    {\n        _1422 = 0.0f;\n    }\n    if (_1422 > 0.0f)\n    {\n        float _1436 = _1422 * 0.5f;\n        d = abs(d + _1436) - _1436;\n    }\n    float _1444 = fwidth(d);\n    float _1445 = max(_1444, 9.9999997473787516355514526367188e-05f);\n    float _1455 = clamp(0.5f - (d / max(shape_rs.y, _1445)), 0.0f, 1.0f);\n    float _1460;\n    if (shape_rs.y > _1445)\n    {\n        _1460 = (_1455 * _1455) * (3.0f - (2.0f * _1455));\n    }\n    else\n    {\n        _1460 = _1455;\n    }\n    float4 c = color;\n    bool _1482 = (_1422 <= 0.0f) && (ax > (-0.5f));\n    if (_1482)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1497 = cos(ax);\n            float _1499 = sin(ax);\n            g = ((dot(_1369, float2(_1497, _1499)) / max((abs(_1497) * _1375) + (abs(_1499) * _1377), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_1411)\n        {\n            float4 _1542 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _1542;\n            float3 param = _1542.xyz;\n            float param_1 = xform.y;\n            float3 _1549 = fa_tex_fix(param, param_1);\n            float4 _2344 = c;\n            _2344.x = _1549.x;\n            _2344.y = _1549.y;\n            _2344.z = _1549.z;\n            c = _2344;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1561 = scene_rgb(param_2);\n            float4 _1586 = lerp(float4(color.xyz * color.w, color.w), float4(_1561 * color2.w, color2.w), g.xxxx);\n            float _1588 = _1586.w;\n            float3 _1591;\n            if (_1588 > 9.9999997473787516355514526367188e-06f)\n            {\n                _1591 = _1586.xyz / _1588.xxx;\n            }\n            else\n            {\n                _1591 = color.xyz;\n            }\n            c = float4(_1591, _1588);\n        }\n    }\n    float4 _2353 = c;\n    _2353.w = _2353.w * _1460;\n    c = _2353;\n    if (_1482 || (shape_rs.y > 0.0f))\n    {\n        float _1632 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1641 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1641 + (_1632 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1647 = fa_srgb_to_linear(param_4);\n            float4 _2356 = c;\n            _2356.x = _1647.x;\n            _2356.y = _1647.y;\n            _2356.z = _1647.z;\n            c = _2356;\n        }\n        else\n        {\n            float4 _1657 = c;\n            float3 _1660 = _1657.xyz + (_1632 * 0.0039215688593685626983642578125f).xxx;\n            float4 _2363 = _1657;\n            _2363.x = _1660.x;\n            _2363.y = _1660.y;\n            _2363.z = _1660.z;\n            c = _2363;\n        }\n        float4 _2368 = c;\n        _2368.w = clamp(_2368.w + ((_1632 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _2368.w)), 0.0f, 1.0f);\n        c = _2368;\n    }\n    return c;\n}\n\nfloat3 rim_color(float a0, float mode)\n{\n    float2 _1152 = float2(_688_fx_rim_uv.x, 0.0f);\n    float4 _1154 = tex.Sample(smp, uv - _1152);\n    float _1155 = _1154.w;\n    float4 _1165 = tex.Sample(smp, uv + _1152);\n    float _1166 = _1165.w;\n    float2 _1174 = float2(0.0f, _688_fx_rim_uv.y);\n    float4 _1176 = tex.Sample(smp, uv - _1174);\n    float _1177 = _1176.w;\n    float4 _1187 = tex.Sample(smp, uv + _1174);\n    float _1188 = _1187.w;\n    float _1203 = _1155 - _1166;\n    float _1206 = _1188 - _1177;\n    float _1216 = cos(params.y);\n    float _1218 = sin(params.y);\n    float2 _1244 = ((float2(_1216, _1218) * _1203) + ((float2(-_1218, _1216) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _1206)) / max(length(float2(_1203, _1206)), 9.9999997473787516355514526367188e-05f).xx;\n    float3 sum = 0.0f.xxx;\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _688_lit.x)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_688_light_pos[i].w < 0.0f)\n        {\n            to_l = _688_light_pos[i].xy / max(length(_688_light_pos[i].xy), 9.9999997473787516355514526367188e-05f).xx;\n        }\n        else\n        {\n            float2 _1290 = _688_light_pos[i].xy - world_xy;\n            float _1293 = length(_1290);\n            att = pow(clamp(1.0f - (_1293 / max(_688_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _688_light_color[i].w);\n            to_l = _1290 / max(_1293, 9.9999997473787516355514526367188e-05f).xx;\n            if (_688_light_shadow_v[i].x >= 0.0f)\n            {\n                float param = _688_light_shadow_v[i].x;\n                float param_1 = _688_light_shadow_v[i].y;\n                float2 param_2 = -_1290;\n                float param_3 = _688_light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1290;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (_688_light_color[i].xyz * (att * max(dot(_1244, to_l), 0.0f)));\n    }\n    return (sum * _688_fx_rim.xyz) * (a0 * (1.0f - min(min(_1155, _1166), min(_1177, _1188))));\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _694 = gl_FragCoord.xy * _688_fa_target.xy;\n    float _698 = _694.y;\n    return float2(_694.x, lerp(_698, 1.0f - _698, _688_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _736 = base_mode < 0.5f;\n    bool _747;\n    if (!_736)\n    {\n        _747 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _747 = _736;\n    }\n    float _748;\n    if (_747)\n    {\n        _748 = shape_half.x;\n    }\n    else\n    {\n        _748 = 0.0f;\n    }\n    QuadInput _2288 = { uv, color, world_xy, fa_screen_uv(), _688_fa_time.x, base_mode, 0.0f.xxxx, _748 };\n    return _2288;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float4 _768 = mask.Sample(mask_smp, float2(0.4000000059604644775390625f, 0.0500000007450580596923828125f));\n    s.color.x = _768.x;\n    s.color.y = _768.y;\n    s.color.z = _768.z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1687 = params.x > 31.5f;\n    if (_1687)\n    {\n        mode -= 32.0f;\n    }\n    float _1695 = mode;\n    bool _1697 = _1695 > 15.5f;\n    if (_1697)\n    {\n        mode -= 16.0f;\n    }\n    float _1705 = mode;\n    bool _1707 = _1705 > 7.5f;\n    if (_1707)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1697)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1697)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1769 = tex_color(param_5);\n                float4 _1771 = _1769 * color;\n                float4 param_6 = _1771;\n                float param_7 = mode;\n                float _1778 = _1771.w;\n                frag_color = float4(lit_color(param_6, param_7), _1778);\n                if (_688_fx_rim.w > 0.5f)\n                {\n                    float param_8 = _1778;\n                    float param_9 = mode;\n                    float4 _1794 = frag_color;\n                    float3 _1796 = _1794.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1796.x;\n                    frag_color.y = _1796.y;\n                    frag_color.z = _1796.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1826 = length(uv);\n                    float _1829 = fwidth(_1826);\n                    float _1830 = max(_1829, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1826) / _1830) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1826) / _1830) + 0.5f, 0.0f, 1.0f) * clamp(((_1826 - params.y) / _1830) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1870 = clamp(1.0f - _1826, 0.0f, 1.0f);\n                            cov = (_1870 * _1870) * (3.0f - (2.0f * _1870));\n                        }\n                    }\n                    float3 _1879;\n                    if (_1697)\n                    {\n                        float4 param_10 = color;\n                        float param_11 = 5.0f;\n                        _1879 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1879 = color.xyz;\n                    }\n                    frag_color = float4(_1879, color.w * cov);\n                }\n            }\n        }\n    }\n    if (_688_fx_emit.w > 0.5f)\n    {\n        float3 e = _688_fx_emit.xyz;\n        if (_688_fx_emit.w > 1.5f)\n        {\n            float3 param_12 = fx_emissive_tex.Sample(smp, (uv * _688_fx_emit_uv.xy) + _688_fx_emit_uv.zw).xyz;\n            float param_13 = _688_fx_emit.w - 2.0f;\n            float3 _1934 = fa_tex_fix(param_12, param_13);\n            e *= _1934;\n        }\n        float4 _1938 = frag_color;\n        float3 _1940 = _1938.xyz + e;\n        frag_color.x = _1940.x;\n        frag_color.y = _1940.y;\n        frag_color.z = _1940.z;\n    }\n    float param_14 = mode;\n    float4 _2268 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface _2270 = { _2268 };\n    QuadSurface param_16 = _2270;\n    fragment(param_15, param_16);\n    _2268 = param_16.color;\n    frag_color = param_16.color;\n    if (_1687)\n    {\n        float4 _1966 = frag_color;\n        float3 param_17 = color2.xyz;\n        float3 _1971 = scene_rgb(param_17);\n        float3 _1975 = lerp(_1966.xyz, _1971, color2.w.xxx);\n        frag_color.x = _1975.x;\n        frag_color.y = _1975.y;\n        frag_color.z = _1975.z;\n    }\n    if (_1707)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1999 = _688_fog_col.w > 0.0f;\n    bool _2007;\n    if (!_1999)\n    {\n        _2007 = _688_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2007 = _1999;\n    }\n    if (_2007)\n    {\n        float3 _2021 = float3(world_xy, world_z) - _688_fog_eye.xyz;\n        float _2028 = dot(_2021, _688_fog_c.xyz);\n        bool _2032 = _688_fog_c.w > 0.5f;\n        float _2033;\n        if (_2032)\n        {\n            _2033 = _2028;\n        }\n        else\n        {\n            _2033 = length(_2021);\n        }\n        float _2045 = _2033 - _688_fog_b.x;\n        if (_2045 > 0.0f)\n        {\n            float _2054 = _688_fog_col.w * _2045;\n            float tau = _2054 * _2054;\n            if (_688_fog_b.y > 0.0f)\n            {\n                float _2070;\n                if (_2032)\n                {\n                    _2070 = world_xy.y - (_688_fog_c.y * _2028);\n                }\n                else\n                {\n                    _2070 = _688_fog_eye.y;\n                }\n                float _2091 = lerp(_2070, world_xy.y, clamp(_688_fog_b.x / _2033, 0.0f, 1.0f));\n                float _2095 = world_xy.y - _2091;\n                float _2100 = _2091 - _688_fog_b.z;\n                float _2105 = world_xy.y - _688_fog_b.z;\n                bool _2108 = _2100 <= 0.0f;\n                bool _2109 = !_2108;\n                bool _2115;\n                if (_2109)\n                {\n                    _2115 = _688_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2115 = _2108;\n                }\n                float _2116;\n                if (_2115)\n                {\n                    _2116 = _688_fog_b.y;\n                }\n                else\n                {\n                    _2116 = _688_fog_b.y * exp(-min(_688_fog_b.w * _2100, 80.0f));\n                }\n                bool _2143;\n                if (_2109)\n                {\n                    _2143 = _688_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2143 = _2108;\n                }\n                float _2144;\n                if (_2143)\n                {\n                    _2144 = _688_fog_b.y * _2100;\n                }\n                else\n                {\n                    _2144 = (_688_fog_b.y * (1.0f - exp(-min(_688_fog_b.w * _2100, 80.0f)))) / _688_fog_b.w;\n                }\n                bool _2169 = _2105 <= 0.0f;\n                bool _2176;\n                if (!_2169)\n                {\n                    _2176 = _688_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2176 = _2169;\n                }\n                float _2177;\n                if (_2176)\n                {\n                    _2177 = _688_fog_b.y * _2105;\n                }\n                else\n                {\n                    _2177 = (_688_fog_b.y * (1.0f - exp(-min(_688_fog_b.w * _2105, 80.0f)))) / _688_fog_b.w;\n                }\n                float _2204;\n                if (abs(_2095) < 0.001000000047497451305389404296875f)\n                {\n                    _2204 = _2116;\n                }\n                else\n                {\n                    _2204 = (_2177 - _2144) / _2095;\n                }\n                tau += (_2045 * max(_2204, 0.0f));\n            }\n            float4 _2227 = frag_color;\n            float3 _2235 = lerp(_2227.xyz, _688_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _2235.x;\n            frag_color.y = _2235.y;\n            frag_color.z = _2235.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_96",
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
              "slot": 8,
              "stage": "vertex",
              "name": "fa_vs_mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
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
            "slot": 7,
            "stage": "vertex",
            "name": "fa_vs_mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 7
          },
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
            "stage": "vertex",
            "name": "fa_vs_mask_fa_vs_mask_smp",
            "view_name": "fa_vs_mask",
            "sampler_name": "fa_vs_mask_smp",
            "view_slot": 8,
            "sampler_slot": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "tex_smp",
            "view_name": "tex",
            "sampler_name": "smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "normal_tex_smp",
            "view_name": "normal_tex",
            "sampler_name": "smp",
            "view_slot": 1,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fx_gi_tex_light_smp",
            "view_name": "fx_gi_tex",
            "sampler_name": "light_smp",
            "view_slot": 14,
            "sampler_slot": 1
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "light_tex_light_smp",
            "view_name": "light_tex",
            "sampler_name": "light_smp",
            "view_slot": 2,
            "sampler_slot": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "shadow_tex_shadow_smp",
            "view_name": "shadow_tex",
            "sampler_name": "shadow_smp",
            "view_slot": 3,
            "sampler_slot": 2
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fx_cookie_tex_light_smp",
            "view_name": "fx_cookie_tex",
            "sampler_name": "light_smp",
            "view_slot": 13,
            "sampler_slot": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fx_emissive_tex_smp",
            "view_name": "fx_emissive_tex",
            "sampler_name": "smp",
            "view_slot": 12,
            "sampler_slot": 0
          },
          {
            "slot": 8,
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
      "vs": "struct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\ncbuffer vs_params : register(b0)\n{\n    row_major float4x4 _96_view_proj : packoffset(c0);\n    float4 _96_cspace : packoffset(c4);\n    float4 _96_fa_time : packoffset(c5);\n};\n\nTexture2D<float4> fa_vs_mask : register(t0);\nSamplerState fa_vs_mask_smp : register(s7);\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += (fa_vs_mask.SampleLevel(fa_vs_mask_smp, float2(0.4000000059604644775390625f, 0.0500000007450580596923828125f), 0.0f).x * 40.0f);\n}\n\nvoid vert_main()\n{\n    float3 _171 = position;\n    float2 _172 = texcoord0;\n    float4 _173 = color0;\n    if (_96_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _108 = fa_srgb_to_linear(param);\n        float4 _185 = _173;\n        _185.x = _108.x;\n        _185.y = _108.y;\n        _185.z = _108.z;\n        _173 = _185;\n    }\n    QuadVertex _180 = { _171, _172, _173 };\n    QuadVertex param_1 = _180;\n    vertex(param_1);\n    _171 = param_1.world_pos;\n    _172 = param_1.uv;\n    _173 = param_1.color;\n    gl_Position = mul(float4(param_1.world_pos, 1.0f), _96_view_proj);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = _96_cspace.xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _131_lit : packoffset(c0);\n    float4 _131_ambient : packoffset(c1);\n    float4 _131_normal_uv : packoffset(c2);\n    float4 _131_flat_ambient : packoffset(c3);\n    float4 _131_light_map : packoffset(c4);\n    float4 _131_light_pos[16] : packoffset(c5);\n    float4 _131_light_color[16] : packoffset(c21);\n    float4 _131_light_shadow_v[16] : packoffset(c37);\n    float4 _131_fog_col : packoffset(c53);\n    float4 _131_fog_b : packoffset(c54);\n    float4 _131_fog_c : packoffset(c55);\n    float4 _131_fog_eye : packoffset(c56);\n    float4 _131_fa_time : packoffset(c57);\n    float4 _131_fa_target : packoffset(c58);\n    float4 _131_fx_emit : packoffset(c59);\n    float4 _131_fx_emit_uv : packoffset(c60);\n    float4 _131_fx_rim : packoffset(c61);\n    float4 _131_fx_rim_uv : packoffset(c62);\n    float4 _131_light_cookie[16] : packoffset(c63);\n    float4 _131_light_cookie_xf[16] : packoffset(c79);\n    float4 _131_fa_scene : packoffset(c95);\n    float4 _131_fa_world_uv[3] : packoffset(c96);\n    float4 _131_gi_xf : packoffset(c99);\n    float4 _131_gi_p : packoffset(c100);\n};\n\nTexture2D<float4> mask : register(t1);\nSamplerState mask_smp : register(s3);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 frag_color;\nstatic float3 xform;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _138 = gl_FragCoord.xy * _131_fa_target.xy;\n    float _144 = _138.y;\n    return float2(_138.x, lerp(_144, 1.0f - _144, _131_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _188 = base_mode < 0.5f;\n    bool _199;\n    if (!_188)\n    {\n        _199 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _199 = _188;\n    }\n    float _200;\n    if (_199)\n    {\n        _200 = shape_half.x;\n    }\n    else\n    {\n        _200 = 0.0f;\n    }\n    QuadInput _327 = { uv, color, world_xy, fa_screen_uv(), _131_fa_time.x, base_mode, 0.0f.xxxx, _200 };\n    return _327;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float4 _226 = mask.Sample(mask_smp, float2(0.4000000059604644775390625f, 0.0500000007450580596923828125f));\n    s.color.x = _226.x;\n    s.color.y = _226.y;\n    s.color.z = _226.z;\n}\n\nvoid frag_main()\n{\n    float4 _241 = tex.Sample(smp, uv);\n    float3 param = _241.xyz;\n    float param_1 = xform.y;\n    float3 _252 = fa_tex_fix(param, param_1);\n    frag_color = float4(_252, _241.w) * color;\n    float param_2 = 0.0f;\n    float4 _307 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _309 = { _307 };\n    QuadSurface param_4 = _309;\n    fragment(param_3, param_4);\n    _307 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    xform = stage_input.xform;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_96",
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
          },
          {
            "texture": {
              "slot": 8,
              "stage": "vertex",
              "name": "fa_vs_mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 7,
            "stage": "vertex",
            "name": "fa_vs_mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 7
          },
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
            "stage": "vertex",
            "name": "fa_vs_mask_fa_vs_mask_smp",
            "view_name": "fa_vs_mask",
            "sampler_name": "fa_vs_mask_smp",
            "view_slot": 8,
            "sampler_slot": 7
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "tex_smp",
            "view_name": "tex",
            "sampler_name": "smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 2,
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
