{
  "format": "factoria.shader/1",
  "engine": "0.39.0",
  "template": "d75bc1c2988d2355d3b6c4618a7c68ff76094f3e9d32765c88b7244d10541da4",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "buffers": [
    {
      "name": "points",
      "binding": 0,
      "stride": 32,
      "access": "read",
      "fields": [
        {
          "name": "pos",
          "type": "vec4",
          "offset": 0
        },
        {
          "name": "tint",
          "type": "vec4",
          "offset": 16
        }
      ]
    }
  ],
  "programs": {
    "quad": {
      "vs": "struct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t0);\ncbuffer vs_params : register(b0)\n{\n    row_major float4x4 _105_view_proj : packoffset(c0);\n    float4 _105_cspace : packoffset(c4);\n    float4 _105_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic int fa_inst_index_v;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation int fa_inst_index_v : TEXCOORD9;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    float3 _68 = v.world_pos;\n    float2 _76 = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xy + (_68.xy * asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w);\n    v.world_pos.x = _76.x;\n    v.world_pos.y = _76.y;\n}\n\nvoid vert_main()\n{\n    fa_inst_index_v = gl_InstanceIndex;\n    float3 _178 = position;\n    float2 _179 = texcoord0;\n    float4 _180 = color0;\n    if (_105_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _117 = fa_srgb_to_linear(param);\n        float4 _192 = _180;\n        _192.x = _117.x;\n        _192.y = _117.y;\n        _192.z = _117.z;\n        _180 = _192;\n    }\n    QuadVertex _187 = { _178, _179, _180 };\n    QuadVertex param_1 = _187;\n    vertex(param_1);\n    _178 = param_1.world_pos;\n    _179 = param_1.uv;\n    _180 = param_1.color;\n    gl_Position = mul(float4(param_1.world_pos, 1.0f), _105_view_proj);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = _105_cspace.xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_inst_index_v = fa_inst_index_v;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _688_lit : packoffset(c0);\n    float4 _688_ambient : packoffset(c1);\n    float4 _688_normal_uv : packoffset(c2);\n    float4 _688_flat_ambient : packoffset(c3);\n    float4 _688_light_map : packoffset(c4);\n    float4 _688_light_pos[16] : packoffset(c5);\n    float4 _688_light_color[16] : packoffset(c21);\n    float4 _688_light_shadow_v[16] : packoffset(c37);\n    float4 _688_fog_col : packoffset(c53);\n    float4 _688_fog_b : packoffset(c54);\n    float4 _688_fog_c : packoffset(c55);\n    float4 _688_fog_eye : packoffset(c56);\n    float4 _688_fa_time : packoffset(c57);\n    float4 _688_fa_target : packoffset(c58);\n    float4 _688_fx_emit : packoffset(c59);\n    float4 _688_fx_emit_uv : packoffset(c60);\n    float4 _688_fx_rim : packoffset(c61);\n    float4 _688_fx_rim_uv : packoffset(c62);\n    float4 _688_light_cookie[16] : packoffset(c63);\n    float4 _688_light_cookie_xf[16] : packoffset(c79);\n    float4 _688_fa_scene : packoffset(c95);\n    float4 _688_fa_world_uv[3] : packoffset(c96);\n    float4 _688_gi_xf : packoffset(c99);\n    float4 _688_gi_p : packoffset(c100);\n};\n\nByteAddressBuffer points : register(t7);\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> fx_cookie_tex : register(t5);\nSamplerState light_smp : register(s1);\nTexture2D<float4> fx_gi_tex : register(t6);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nTexture2D<float4> fx_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic int fa_inst_index_v;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation int fa_inst_index_v : TEXCOORD9;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _625 = fa_linear_to_srgb(param);\n        c = _625;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _633 = fa_srgb_to_linear(param_1);\n            c = _633;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _644 = tex.Sample(smp, p);\n    float3 param = _644.xyz;\n    float param_1 = xform.y;\n    float3 _654 = fa_tex_fix(param, param_1);\n    return float4(_654, _644.w);\n}\n\nfloat3 gi_irradiance()\n{\n    float2 _824 = (world_xy * _688_gi_xf.xy) + _688_gi_xf.zw;\n    float4 _831 = fx_gi_tex.SampleLevel(light_smp, _824, 0.0f);\n    float _835 = _824.x;\n    bool _836 = _835 >= 0.0f;\n    bool _842;\n    if (_836)\n    {\n        _842 = _824.y >= 0.0f;\n    }\n    else\n    {\n        _842 = _836;\n    }\n    bool _848;\n    if (_842)\n    {\n        _848 = _835 <= 1.0f;\n    }\n    else\n    {\n        _848 = _842;\n    }\n    bool _854;\n    if (_848)\n    {\n        _854 = _824.y <= 1.0f;\n    }\n    else\n    {\n        _854 = _848;\n    }\n    bool _862;\n    if (_854)\n    {\n        _862 = _831.w > 0.0199999995529651641845703125f;\n    }\n    else\n    {\n        _862 = _854;\n    }\n    float3 _863;\n    if (_862)\n    {\n        _863 = (_831.xyz / _831.w.xxx) * _688_gi_p.x;\n    }\n    else\n    {\n        _863 = 0.0f.xxx;\n    }\n    return _863;\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _134 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_134.x * 255.0f) + 0.5f) * 256.0f) + floor((_134.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _237 = floor(tt);\n    float _247 = _237 - (1024.0f * floor(_237 * 0.0009765625f));\n    float _250 = _247 + 1.0f;\n    float i1 = _250;\n    if (_250 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _247;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5f, 0.0f, 1.0f), tt - _237);\n}\n\nfloat light_shadow_soft(float v, float size, float2 d, float radius)\n{\n    float _287 = length(d);\n    float result = 1.0f;\n    if (_287 >= 9.9999997473787516355514526367188e-05f)\n    {\n        float _298 = atan2(d.y, d.x);\n        float a = _298;\n        float _301;\n        if (_298 < 0.0f)\n        {\n            _301 = a + 6.283185482025146484375f;\n        }\n        else\n        {\n            _301 = a;\n        }\n        a = _301;\n        float _311 = _301 * 162.9746551513671875f;\n        float _320 = min((size * 10.0f) / _287, 0.699999988079071044921875f) * 162.9746551513671875f;\n        float sum = 0.0f;\n        float n = 0.0f;\n        for (int k = 0; k < 12; k++)\n        {\n            float _346 = floor(_311 + ((((float(k) + 0.5f) * 0.16666667163372039794921875f) - 1.0f) * _320));\n            float param = v;\n            float param_1 = _346 - (1024.0f * floor(_346 * 0.0009765625f));\n            float _360 = shadow_texel(param, param_1) * radius;\n            if (_360 < _287)\n            {\n                sum += _360;\n                n += 1.0f;\n            }\n        }\n        if (n > 0.5f)\n        {\n            float _392 = min(size * ((1.0f / max(sum / n, 1.0f)) - (1.0f / _287)), 0.699999988079071044921875f) * 162.9746551513671875f;\n            float acc = 0.0f;\n            float wsum = 0.0f;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _410 = ((float(k_1) + 0.5f) * 0.125f) - 1.0f;\n                float _416 = 1.0f - (0.800000011920928955078125f * abs(_410));\n                float param_2 = v;\n                float param_3 = _311 + (_410 * _392);\n                float param_4 = _287;\n                float param_5 = radius;\n                acc += (_416 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _416;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _158 = length(d);\n    if (_158 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _172 = atan2(d.y, d.x);\n    float a = _172;\n    float _175;\n    if (_172 < 0.0f)\n    {\n        _175 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _175 = a;\n    }\n    a = _175;\n    float _187 = _175 * 162.9746551513671875f;\n    float _192 = min(floor(_187), 1023.0f);\n    float _199 = _192 + 1.0f;\n    float i1 = _199;\n    if (_199 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _192;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _158) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _158) + 0.5f, 0.0f, 1.0f), _187 - _192);\n}\n\nfloat light_shadow_sized(float v, float size, float2 d, float radius)\n{\n    float r = 1.0f;\n    if (size > 0.0f)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nfloat3 cookie_coord(float4 cell, float4 xf, float2 off)\n{\n    float2 _497 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _501 = _497.x + 0.5f;\n    float2 c = float2(_501, 0.5f - _497.y);\n    bool _509 = _501 >= 0.0f;\n    bool _515;\n    if (_509)\n    {\n        _515 = c.x <= 1.0f;\n    }\n    else\n    {\n        _515 = _509;\n    }\n    bool _521;\n    if (_515)\n    {\n        _521 = c.y >= 0.0f;\n    }\n    else\n    {\n        _521 = _515;\n    }\n    bool _527;\n    if (_521)\n    {\n        _527 = c.y <= 1.0f;\n    }\n    else\n    {\n        _527 = _521;\n    }\n    float2 _529 = c;\n    float2 _534 = clamp(_529, 0.001953125f.xx, 0.998046875f.xx);\n    c = _534;\n    return float3(cell.x + (_534.x * cell.w), cell.y + (_534.y * cell.z), float(_527));\n}\n\nfloat cookie_value(float4 t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125f, 0.715200006961822509765625f, 0.072200000286102294921875f)) * t.w;\n}\n\nfloat cookie_att(int i, float2 d)\n{\n    if (_688_light_cookie[i].w == 0.0f)\n    {\n        return 1.0f;\n    }\n    float4 param = _688_light_cookie[i];\n    float4 param_1 = _688_light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _798 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.SampleLevel(light_smp, _798.xy, 0.0f);\n    return cookie_value(param_3) * _798.z;\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _885 = _688_lit.y > 0.5f;\n    if (_885)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _688_normal_uv.xy) + _688_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _909 = fa_tex_fix(param, param_1);\n        float3 _913 = (_909 * 2.0f) - 1.0f.xxx;\n        float _920 = cos(params.y);\n        float _922 = sin(params.y);\n        n = normalize(float3((float2(_920, _922) * _913.x) + ((float2(-_922, _920) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _913.y), max(_913.z, 0.0500000007450580596923828125f)));\n    }\n    bool _956 = !_885;\n    bool _962;\n    if (_956)\n    {\n        _962 = _688_lit.z > 0.5f;\n    }\n    else\n    {\n        _962 = _956;\n    }\n    float3 _965;\n    if (_962)\n    {\n        _965 = _688_flat_ambient.xyz;\n    }\n    else\n    {\n        _965 = _688_ambient.xyz;\n    }\n    float3 total = _965;\n    if (_688_gi_p.x > 0.0f)\n    {\n        total += gi_irradiance();\n    }\n    bool _990;\n    if (_962)\n    {\n        _990 = _688_lit.z < 1.5f;\n    }\n    else\n    {\n        _990 = _962;\n    }\n    if (_990)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _688_light_map.xy, 0.0f).xyz * _688_light_map.z);\n    }\n    float3 l;\n    float _1117;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1027;\n        if (!_962)\n        {\n            _1027 = float(i) >= _688_lit.x;\n        }\n        else\n        {\n            _1027 = _962;\n        }\n        if (_1027)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_688_light_pos[i].w < 0.0f)\n        {\n            l = _688_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _1053 = _688_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_1053) / max(_688_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _688_light_color[i].w);\n            float3 _1073 = float3(_1053, _688_light_pos[i].z);\n            l = _1073 / max(length(_1073), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_688_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _688_light_shadow_v[i].x;\n                float param_3 = _688_light_shadow_v[i].y;\n                float2 param_4 = -_1053;\n                float param_5 = _688_light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            float2 param_7 = -_1053;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_885)\n        {\n            _1117 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _1117 = 1.0f;\n        }\n        total += (_688_light_color[i].xyz * (att * _1117));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _670 = fa_srgb_to_linear(param);\n        c = _670;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _1367 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _1371 = uv * _1367;\n    float _1377 = _1367.x;\n    float _1379 = _1367.y;\n    float _1381 = clamp(shape_rs.x, 0.0f, min(_1377, _1379));\n    float2 _1392 = (abs(_1371) - _1367) + _1381.xx;\n    float d = (length(max(_1392, 0.0f.xx)) + min(max(_1392.x, _1392.y), 0.0f)) - _1381;\n    float ax = params.y;\n    bool _1413 = params.y > 15.0f;\n    if (_1413)\n    {\n        ax -= 20.0f;\n    }\n    float _1424;\n    if (ax <= (-1.5f))\n    {\n        _1424 = (-2.0f) - ax;\n    }\n    else\n    {\n        _1424 = 0.0f;\n    }\n    if (_1424 > 0.0f)\n    {\n        float _1438 = _1424 * 0.5f;\n        d = abs(d + _1438) - _1438;\n    }\n    float _1446 = fwidth(d);\n    float _1447 = max(_1446, 9.9999997473787516355514526367188e-05f);\n    float _1457 = clamp(0.5f - (d / max(shape_rs.y, _1447)), 0.0f, 1.0f);\n    float _1462;\n    if (shape_rs.y > _1447)\n    {\n        _1462 = (_1457 * _1457) * (3.0f - (2.0f * _1457));\n    }\n    else\n    {\n        _1462 = _1457;\n    }\n    float4 c = color;\n    bool _1484 = (_1424 <= 0.0f) && (ax > (-0.5f));\n    if (_1484)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1499 = cos(ax);\n            float _1501 = sin(ax);\n            g = ((dot(_1371, float2(_1499, _1501)) / max((abs(_1499) * _1377) + (abs(_1501) * _1379), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_1413)\n        {\n            float4 _1544 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _1544;\n            float3 param = _1544.xyz;\n            float param_1 = xform.y;\n            float3 _1551 = fa_tex_fix(param, param_1);\n            float4 _2346 = c;\n            _2346.x = _1551.x;\n            _2346.y = _1551.y;\n            _2346.z = _1551.z;\n            c = _2346;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1563 = scene_rgb(param_2);\n            float4 _1588 = lerp(float4(color.xyz * color.w, color.w), float4(_1563 * color2.w, color2.w), g.xxxx);\n            float _1590 = _1588.w;\n            float3 _1593;\n            if (_1590 > 9.9999997473787516355514526367188e-06f)\n            {\n                _1593 = _1588.xyz / _1590.xxx;\n            }\n            else\n            {\n                _1593 = color.xyz;\n            }\n            c = float4(_1593, _1590);\n        }\n    }\n    float4 _2355 = c;\n    _2355.w = _2355.w * _1462;\n    c = _2355;\n    if (_1484 || (shape_rs.y > 0.0f))\n    {\n        float _1634 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1643 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1643 + (_1634 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1649 = fa_srgb_to_linear(param_4);\n            float4 _2358 = c;\n            _2358.x = _1649.x;\n            _2358.y = _1649.y;\n            _2358.z = _1649.z;\n            c = _2358;\n        }\n        else\n        {\n            float4 _1659 = c;\n            float3 _1662 = _1659.xyz + (_1634 * 0.0039215688593685626983642578125f).xxx;\n            float4 _2365 = _1659;\n            _2365.x = _1662.x;\n            _2365.y = _1662.y;\n            _2365.z = _1662.z;\n            c = _2365;\n        }\n        float4 _2370 = c;\n        _2370.w = clamp(_2370.w + ((_1634 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _2370.w)), 0.0f, 1.0f);\n        c = _2370;\n    }\n    return c;\n}\n\nfloat3 rim_color(float a0, float mode)\n{\n    float2 _1154 = float2(_688_fx_rim_uv.x, 0.0f);\n    float4 _1156 = tex.Sample(smp, uv - _1154);\n    float _1157 = _1156.w;\n    float4 _1167 = tex.Sample(smp, uv + _1154);\n    float _1168 = _1167.w;\n    float2 _1176 = float2(0.0f, _688_fx_rim_uv.y);\n    float4 _1178 = tex.Sample(smp, uv - _1176);\n    float _1179 = _1178.w;\n    float4 _1189 = tex.Sample(smp, uv + _1176);\n    float _1190 = _1189.w;\n    float _1205 = _1157 - _1168;\n    float _1208 = _1190 - _1179;\n    float _1218 = cos(params.y);\n    float _1220 = sin(params.y);\n    float2 _1246 = ((float2(_1218, _1220) * _1205) + ((float2(-_1220, _1218) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _1208)) / max(length(float2(_1205, _1208)), 9.9999997473787516355514526367188e-05f).xx;\n    float3 sum = 0.0f.xxx;\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _688_lit.x)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_688_light_pos[i].w < 0.0f)\n        {\n            to_l = _688_light_pos[i].xy / max(length(_688_light_pos[i].xy), 9.9999997473787516355514526367188e-05f).xx;\n        }\n        else\n        {\n            float2 _1292 = _688_light_pos[i].xy - world_xy;\n            float _1295 = length(_1292);\n            att = pow(clamp(1.0f - (_1295 / max(_688_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _688_light_color[i].w);\n            to_l = _1292 / max(_1295, 9.9999997473787516355514526367188e-05f).xx;\n            if (_688_light_shadow_v[i].x >= 0.0f)\n            {\n                float param = _688_light_shadow_v[i].x;\n                float param_1 = _688_light_shadow_v[i].y;\n                float2 param_2 = -_1292;\n                float param_3 = _688_light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1292;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (_688_light_color[i].xyz * (att * max(dot(_1246, to_l), 0.0f)));\n    }\n    return (sum * _688_fx_rim.xyz) * (a0 * (1.0f - min(min(_1157, _1168), min(_1179, _1190))));\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _694 = gl_FragCoord.xy * _688_fa_target.xy;\n    float _698 = _694.y;\n    return float2(_694.x, lerp(_698, 1.0f - _698, _688_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _736 = base_mode < 0.5f;\n    bool _747;\n    if (!_736)\n    {\n        _747 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _747 = _736;\n    }\n    float _748;\n    if (_747)\n    {\n        _748 = shape_half.x;\n    }\n    else\n    {\n        _748 = 0.0f;\n    }\n    QuadInput _2290 = { uv, color, world_xy, fa_screen_uv(), _688_fa_time.x, base_mode, 0.0f.xxxx, _748 };\n    return _2290;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = asfloat(points.Load4(fa_inst_index_v * 32 + 16)).x;\n    s.color.y = asfloat(points.Load4(fa_inst_index_v * 32 + 16)).y;\n    s.color.z = asfloat(points.Load4(fa_inst_index_v * 32 + 16)).z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1689 = params.x > 31.5f;\n    if (_1689)\n    {\n        mode -= 32.0f;\n    }\n    float _1697 = mode;\n    bool _1699 = _1697 > 15.5f;\n    if (_1699)\n    {\n        mode -= 16.0f;\n    }\n    float _1707 = mode;\n    bool _1709 = _1707 > 7.5f;\n    if (_1709)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1699)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1699)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1771 = tex_color(param_5);\n                float4 _1773 = _1771 * color;\n                float4 param_6 = _1773;\n                float param_7 = mode;\n                float _1780 = _1773.w;\n                frag_color = float4(lit_color(param_6, param_7), _1780);\n                if (_688_fx_rim.w > 0.5f)\n                {\n                    float param_8 = _1780;\n                    float param_9 = mode;\n                    float4 _1796 = frag_color;\n                    float3 _1798 = _1796.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1798.x;\n                    frag_color.y = _1798.y;\n                    frag_color.z = _1798.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1828 = length(uv);\n                    float _1831 = fwidth(_1828);\n                    float _1832 = max(_1831, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1828) / _1832) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1828) / _1832) + 0.5f, 0.0f, 1.0f) * clamp(((_1828 - params.y) / _1832) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1872 = clamp(1.0f - _1828, 0.0f, 1.0f);\n                            cov = (_1872 * _1872) * (3.0f - (2.0f * _1872));\n                        }\n                    }\n                    float3 _1881;\n                    if (_1699)\n                    {\n                        float4 param_10 = color;\n                        float param_11 = 5.0f;\n                        _1881 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1881 = color.xyz;\n                    }\n                    frag_color = float4(_1881, color.w * cov);\n                }\n            }\n        }\n    }\n    if (_688_fx_emit.w > 0.5f)\n    {\n        float3 e = _688_fx_emit.xyz;\n        if (_688_fx_emit.w > 1.5f)\n        {\n            float3 param_12 = fx_emissive_tex.Sample(smp, (uv * _688_fx_emit_uv.xy) + _688_fx_emit_uv.zw).xyz;\n            float param_13 = _688_fx_emit.w - 2.0f;\n            float3 _1936 = fa_tex_fix(param_12, param_13);\n            e *= _1936;\n        }\n        float4 _1940 = frag_color;\n        float3 _1942 = _1940.xyz + e;\n        frag_color.x = _1942.x;\n        frag_color.y = _1942.y;\n        frag_color.z = _1942.z;\n    }\n    float param_14 = mode;\n    float4 _2270 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface _2272 = { _2270 };\n    QuadSurface param_16 = _2272;\n    fragment(param_15, param_16);\n    _2270 = param_16.color;\n    frag_color = param_16.color;\n    if (_1689)\n    {\n        float4 _1968 = frag_color;\n        float3 param_17 = color2.xyz;\n        float3 _1973 = scene_rgb(param_17);\n        float3 _1977 = lerp(_1968.xyz, _1973, color2.w.xxx);\n        frag_color.x = _1977.x;\n        frag_color.y = _1977.y;\n        frag_color.z = _1977.z;\n    }\n    if (_1709)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _2001 = _688_fog_col.w > 0.0f;\n    bool _2009;\n    if (!_2001)\n    {\n        _2009 = _688_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2009 = _2001;\n    }\n    if (_2009)\n    {\n        float3 _2023 = float3(world_xy, world_z) - _688_fog_eye.xyz;\n        float _2030 = dot(_2023, _688_fog_c.xyz);\n        bool _2034 = _688_fog_c.w > 0.5f;\n        float _2035;\n        if (_2034)\n        {\n            _2035 = _2030;\n        }\n        else\n        {\n            _2035 = length(_2023);\n        }\n        float _2047 = _2035 - _688_fog_b.x;\n        if (_2047 > 0.0f)\n        {\n            float _2056 = _688_fog_col.w * _2047;\n            float tau = _2056 * _2056;\n            if (_688_fog_b.y > 0.0f)\n            {\n                float _2072;\n                if (_2034)\n                {\n                    _2072 = world_xy.y - (_688_fog_c.y * _2030);\n                }\n                else\n                {\n                    _2072 = _688_fog_eye.y;\n                }\n                float _2093 = lerp(_2072, world_xy.y, clamp(_688_fog_b.x / _2035, 0.0f, 1.0f));\n                float _2097 = world_xy.y - _2093;\n                float _2102 = _2093 - _688_fog_b.z;\n                float _2107 = world_xy.y - _688_fog_b.z;\n                bool _2110 = _2102 <= 0.0f;\n                bool _2111 = !_2110;\n                bool _2117;\n                if (_2111)\n                {\n                    _2117 = _688_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2117 = _2110;\n                }\n                float _2118;\n                if (_2117)\n                {\n                    _2118 = _688_fog_b.y;\n                }\n                else\n                {\n                    _2118 = _688_fog_b.y * exp(-min(_688_fog_b.w * _2102, 80.0f));\n                }\n                bool _2145;\n                if (_2111)\n                {\n                    _2145 = _688_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2145 = _2110;\n                }\n                float _2146;\n                if (_2145)\n                {\n                    _2146 = _688_fog_b.y * _2102;\n                }\n                else\n                {\n                    _2146 = (_688_fog_b.y * (1.0f - exp(-min(_688_fog_b.w * _2102, 80.0f)))) / _688_fog_b.w;\n                }\n                bool _2171 = _2107 <= 0.0f;\n                bool _2178;\n                if (!_2171)\n                {\n                    _2178 = _688_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2178 = _2171;\n                }\n                float _2179;\n                if (_2178)\n                {\n                    _2179 = _688_fog_b.y * _2107;\n                }\n                else\n                {\n                    _2179 = (_688_fog_b.y * (1.0f - exp(-min(_688_fog_b.w * _2107, 80.0f)))) / _688_fog_b.w;\n                }\n                float _2206;\n                if (abs(_2097) < 0.001000000047497451305389404296875f)\n                {\n                    _2206 = _2118;\n                }\n                else\n                {\n                    _2206 = (_2179 - _2146) / _2097;\n                }\n                tau += (_2047 * max(_2206, 0.0f));\n            }\n            float4 _2229 = frag_color;\n            float3 _2237 = lerp(_2229.xyz, _688_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _2237.x;\n            frag_color.y = _2237.y;\n            frag_color.z = _2237.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    fa_inst_index_v = stage_input.fa_inst_index_v;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_105",
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
          },
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
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
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "struct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t0);\ncbuffer vs_params : register(b0)\n{\n    row_major float4x4 _105_view_proj : packoffset(c0);\n    float4 _105_cspace : packoffset(c4);\n    float4 _105_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic int fa_inst_index_v;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation int fa_inst_index_v : TEXCOORD9;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    float3 _68 = v.world_pos;\n    float2 _76 = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xy + (_68.xy * asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w);\n    v.world_pos.x = _76.x;\n    v.world_pos.y = _76.y;\n}\n\nvoid vert_main()\n{\n    fa_inst_index_v = gl_InstanceIndex;\n    float3 _178 = position;\n    float2 _179 = texcoord0;\n    float4 _180 = color0;\n    if (_105_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _117 = fa_srgb_to_linear(param);\n        float4 _192 = _180;\n        _192.x = _117.x;\n        _192.y = _117.y;\n        _192.z = _117.z;\n        _180 = _192;\n    }\n    QuadVertex _187 = { _178, _179, _180 };\n    QuadVertex param_1 = _187;\n    vertex(param_1);\n    _178 = param_1.world_pos;\n    _179 = param_1.uv;\n    _180 = param_1.color;\n    gl_Position = mul(float4(param_1.world_pos, 1.0f), _105_view_proj);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = _105_cspace.xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_inst_index_v = fa_inst_index_v;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _131_lit : packoffset(c0);\n    float4 _131_ambient : packoffset(c1);\n    float4 _131_normal_uv : packoffset(c2);\n    float4 _131_flat_ambient : packoffset(c3);\n    float4 _131_light_map : packoffset(c4);\n    float4 _131_light_pos[16] : packoffset(c5);\n    float4 _131_light_color[16] : packoffset(c21);\n    float4 _131_light_shadow_v[16] : packoffset(c37);\n    float4 _131_fog_col : packoffset(c53);\n    float4 _131_fog_b : packoffset(c54);\n    float4 _131_fog_c : packoffset(c55);\n    float4 _131_fog_eye : packoffset(c56);\n    float4 _131_fa_time : packoffset(c57);\n    float4 _131_fa_target : packoffset(c58);\n    float4 _131_fx_emit : packoffset(c59);\n    float4 _131_fx_emit_uv : packoffset(c60);\n    float4 _131_fx_rim : packoffset(c61);\n    float4 _131_fx_rim_uv : packoffset(c62);\n    float4 _131_light_cookie[16] : packoffset(c63);\n    float4 _131_light_cookie_xf[16] : packoffset(c79);\n    float4 _131_fa_scene : packoffset(c95);\n    float4 _131_fa_world_uv[3] : packoffset(c96);\n    float4 _131_gi_xf : packoffset(c99);\n    float4 _131_gi_p : packoffset(c100);\n};\n\nByteAddressBuffer points : register(t1);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic int fa_inst_index_v;\nstatic float4 frag_color;\nstatic float3 xform;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation int fa_inst_index_v : TEXCOORD9;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _138 = gl_FragCoord.xy * _131_fa_target.xy;\n    float _144 = _138.y;\n    return float2(_138.x, lerp(_144, 1.0f - _144, _131_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _188 = base_mode < 0.5f;\n    bool _199;\n    if (!_188)\n    {\n        _199 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _199 = _188;\n    }\n    float _200;\n    if (_199)\n    {\n        _200 = shape_half.x;\n    }\n    else\n    {\n        _200 = 0.0f;\n    }\n    QuadInput _328 = { uv, color, world_xy, fa_screen_uv(), _131_fa_time.x, base_mode, 0.0f.xxxx, _200 };\n    return _328;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = asfloat(points.Load4(fa_inst_index_v * 32 + 16)).x;\n    s.color.y = asfloat(points.Load4(fa_inst_index_v * 32 + 16)).y;\n    s.color.z = asfloat(points.Load4(fa_inst_index_v * 32 + 16)).z;\n}\n\nvoid frag_main()\n{\n    float4 _242 = tex.Sample(smp, uv);\n    float3 param = _242.xyz;\n    float param_1 = xform.y;\n    float3 _253 = fa_tex_fix(param, param_1);\n    frag_color = float4(_253, _242.w) * color;\n    float param_2 = 0.0f;\n    float4 _308 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _310 = { _308 };\n    QuadSurface param_4 = _310;\n    fragment(param_3, param_4);\n    _308 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    fa_inst_index_v = stage_input.fa_inst_index_v;\n    xform = stage_input.xform;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_105",
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
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 1
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
