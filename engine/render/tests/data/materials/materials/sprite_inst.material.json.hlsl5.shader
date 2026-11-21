{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "8dda08c124964ccb7d15a0a3238fb4669d4ca9ef375995bc9768b79891bfc837",
  "slang": "hlsl5",
  "params": [
    "boost"
  ],
  "textures": [],
  "kind": "sprite",
  "instanced": [
    {
      "name": "shift",
      "vec4": 0,
      "offset": 0,
      "components": 1
    },
    {
      "name": "tint",
      "vec4": 1,
      "offset": 0,
      "components": 4
    }
  ],
  "instanceVec4": 2,
  "programs": {
    "quad": {
      "vs": "struct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\ncbuffer vs_params : register(b0)\n{\n    row_major float4x4 _107_view_proj : packoffset(c0);\n    float4 _107_cspace : packoffset(c4);\n    float4 _107_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n    float4 fa_inst_d0 : TEXCOORD7;\n    float4 fa_inst_d1 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation float4 fa_inst_v0 : TEXCOORD9;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float shift;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += shift;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n    float3 _184 = position;\n    float2 _185 = texcoord0;\n    float4 _186 = color0;\n    if (_107_cspace.x > 0.5f)\n    {\n        float3 param_3 = color0.xyz;\n        float3 _119 = fa_srgb_to_linear(param_3);\n        float4 _198 = _186;\n        _198.x = _119.x;\n        _198.y = _119.y;\n        _198.z = _119.z;\n        _186 = _198;\n    }\n    QuadVertex _193 = { _184, _185, _186 };\n    QuadVertex param_4 = _193;\n    vertex(param_4);\n    _184 = param_4.world_pos;\n    _185 = param_4.uv;\n    _186 = param_4.color;\n    gl_Position = mul(float4(param_4.world_pos, 1.0f), _107_view_proj);\n    uv = param_4.uv;\n    color = param_4.color;\n    xform = _107_cspace.xyz;\n    params = params0;\n    world_xy = param_4.world_pos.xy;\n    world_z = param_4.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _699_lit : packoffset(c0);\n    float4 _699_ambient : packoffset(c1);\n    float4 _699_normal_uv : packoffset(c2);\n    float4 _699_flat_ambient : packoffset(c3);\n    float4 _699_light_map : packoffset(c4);\n    float4 _699_light_pos[16] : packoffset(c5);\n    float4 _699_light_color[16] : packoffset(c21);\n    float4 _699_light_shadow_v[16] : packoffset(c37);\n    float4 _699_fog_col : packoffset(c53);\n    float4 _699_fog_b : packoffset(c54);\n    float4 _699_fog_c : packoffset(c55);\n    float4 _699_fog_eye : packoffset(c56);\n    float4 _699_fa_time : packoffset(c57);\n    float4 _699_fa_target : packoffset(c58);\n    float4 _699_fx_emit : packoffset(c59);\n    float4 _699_fx_emit_uv : packoffset(c60);\n    float4 _699_fx_rim : packoffset(c61);\n    float4 _699_fx_rim_uv : packoffset(c62);\n    float4 _699_light_cookie[16] : packoffset(c63);\n    float4 _699_light_cookie_xf[16] : packoffset(c79);\n    float4 _699_fa_scene : packoffset(c95);\n    float4 _699_fa_world_uv[3] : packoffset(c96);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _784_boost : packoffset(c0);\n    float _784_fa_pad0 : packoffset(c0.y);\n    float _784_fa_pad1 : packoffset(c0.z);\n    float _784_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> fx_cookie_tex : register(t5);\nSamplerState light_smp : register(s1);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nTexture2D<float4> fx_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation float4 fa_inst_v0 : TEXCOORD9;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD10;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nstatic float shift;\nstatic float4 tint;\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _631 = fa_linear_to_srgb(param);\n        c = _631;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _639 = fa_srgb_to_linear(param_1);\n            c = _639;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _650 = tex.Sample(smp, p);\n    float3 param = _650.xyz;\n    float param_1 = xform.y;\n    float3 _660 = fa_tex_fix(param, param_1);\n    return float4(_660, _650.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _140 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_140.x * 255.0f) + 0.5f) * 256.0f) + floor((_140.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _243 = floor(tt);\n    float _253 = _243 - (1024.0f * floor(_243 * 0.0009765625f));\n    float _256 = _253 + 1.0f;\n    float i1 = _256;\n    if (_256 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _253;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5f, 0.0f, 1.0f), tt - _243);\n}\n\nfloat light_shadow_soft(float v, float size, float2 d, float radius)\n{\n    float _293 = length(d);\n    float result = 1.0f;\n    if (_293 >= 9.9999997473787516355514526367188e-05f)\n    {\n        float _304 = atan2(d.y, d.x);\n        float a = _304;\n        float _307;\n        if (_304 < 0.0f)\n        {\n            _307 = a + 6.283185482025146484375f;\n        }\n        else\n        {\n            _307 = a;\n        }\n        a = _307;\n        float _317 = _307 * 162.9746551513671875f;\n        float _326 = min((size * 10.0f) / _293, 0.699999988079071044921875f) * 162.9746551513671875f;\n        float sum = 0.0f;\n        float n = 0.0f;\n        for (int k = 0; k < 12; k++)\n        {\n            float _352 = floor(_317 + ((((float(k) + 0.5f) * 0.16666667163372039794921875f) - 1.0f) * _326));\n            float param = v;\n            float param_1 = _352 - (1024.0f * floor(_352 * 0.0009765625f));\n            float _366 = shadow_texel(param, param_1) * radius;\n            if (_366 < _293)\n            {\n                sum += _366;\n                n += 1.0f;\n            }\n        }\n        if (n > 0.5f)\n        {\n            float _398 = min(size * ((1.0f / max(sum / n, 1.0f)) - (1.0f / _293)), 0.699999988079071044921875f) * 162.9746551513671875f;\n            float acc = 0.0f;\n            float wsum = 0.0f;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _416 = ((float(k_1) + 0.5f) * 0.125f) - 1.0f;\n                float _422 = 1.0f - (0.800000011920928955078125f * abs(_416));\n                float param_2 = v;\n                float param_3 = _317 + (_416 * _398);\n                float param_4 = _293;\n                float param_5 = radius;\n                acc += (_422 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _422;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _164 = length(d);\n    if (_164 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _178 = atan2(d.y, d.x);\n    float a = _178;\n    float _181;\n    if (_178 < 0.0f)\n    {\n        _181 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _181 = a;\n    }\n    a = _181;\n    float _193 = _181 * 162.9746551513671875f;\n    float _198 = min(floor(_193), 1023.0f);\n    float _205 = _198 + 1.0f;\n    float i1 = _205;\n    if (_205 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _198;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _164) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _164) + 0.5f, 0.0f, 1.0f), _193 - _198);\n}\n\nfloat light_shadow_sized(float v, float size, float2 d, float radius)\n{\n    float r = 1.0f;\n    if (size > 0.0f)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nfloat3 cookie_coord(float4 cell, float4 xf, float2 off)\n{\n    float2 _503 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _507 = _503.x + 0.5f;\n    float2 c = float2(_507, 0.5f - _503.y);\n    bool _515 = _507 >= 0.0f;\n    bool _521;\n    if (_515)\n    {\n        _521 = c.x <= 1.0f;\n    }\n    else\n    {\n        _521 = _515;\n    }\n    bool _527;\n    if (_521)\n    {\n        _527 = c.y >= 0.0f;\n    }\n    else\n    {\n        _527 = _521;\n    }\n    bool _533;\n    if (_527)\n    {\n        _533 = c.y <= 1.0f;\n    }\n    else\n    {\n        _533 = _527;\n    }\n    float2 _535 = c;\n    float2 _540 = clamp(_535, 0.001953125f.xx, 0.998046875f.xx);\n    c = _540;\n    return float3(cell.x + (_540.x * cell.w), cell.y + (_540.y * cell.z), float(_533));\n}\n\nfloat cookie_value(float4 t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125f, 0.715200006961822509765625f, 0.072200000286102294921875f)) * t.w;\n}\n\nfloat cookie_att(int i, float2 d)\n{\n    if (_699_light_cookie[i].w == 0.0f)\n    {\n        return 1.0f;\n    }\n    float4 param = _699_light_cookie[i];\n    float4 param_1 = _699_light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _823 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.SampleLevel(light_smp, _823.xy, 0.0f);\n    return cookie_value(param_3) * _823.z;\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _845 = _699_lit.y > 0.5f;\n    if (_845)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _699_normal_uv.xy) + _699_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _869 = fa_tex_fix(param, param_1);\n        float3 _873 = (_869 * 2.0f) - 1.0f.xxx;\n        float _880 = cos(params.y);\n        float _882 = sin(params.y);\n        n = normalize(float3((float2(_880, _882) * _873.x) + ((float2(-_882, _880) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _873.y), max(_873.z, 0.0500000007450580596923828125f)));\n    }\n    bool _916 = !_845;\n    bool _922;\n    if (_916)\n    {\n        _922 = _699_lit.z > 0.5f;\n    }\n    else\n    {\n        _922 = _916;\n    }\n    float3 _925;\n    if (_922)\n    {\n        _925 = _699_flat_ambient.xyz;\n    }\n    else\n    {\n        _925 = _699_ambient.xyz;\n    }\n    float3 total = _925;\n    bool _942;\n    if (_922)\n    {\n        _942 = _699_lit.z < 1.5f;\n    }\n    else\n    {\n        _942 = _922;\n    }\n    if (_942)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _699_light_map.xy, 0.0f).xyz * _699_light_map.z);\n    }\n    float3 l;\n    float _1069;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _979;\n        if (!_922)\n        {\n            _979 = float(i) >= _699_lit.x;\n        }\n        else\n        {\n            _979 = _922;\n        }\n        if (_979)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_699_light_pos[i].w < 0.0f)\n        {\n            l = _699_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _1005 = _699_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_1005) / max(_699_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _699_light_color[i].w);\n            float3 _1025 = float3(_1005, _699_light_pos[i].z);\n            l = _1025 / max(length(_1025), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_699_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _699_light_shadow_v[i].x;\n                float param_3 = _699_light_shadow_v[i].y;\n                float2 param_4 = -_1005;\n                float param_5 = _699_light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            float2 param_7 = -_1005;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_845)\n        {\n            _1069 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _1069 = 1.0f;\n        }\n        total += (_699_light_color[i].xyz * (att * _1069));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _676 = fa_srgb_to_linear(param);\n        c = _676;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _1319 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _1323 = uv * _1319;\n    float _1329 = _1319.x;\n    float _1331 = _1319.y;\n    float _1333 = clamp(shape_rs.x, 0.0f, min(_1329, _1331));\n    float2 _1344 = (abs(_1323) - _1319) + _1333.xx;\n    float d = (length(max(_1344, 0.0f.xx)) + min(max(_1344.x, _1344.y), 0.0f)) - _1333;\n    float ax = params.y;\n    bool _1365 = params.y > 15.0f;\n    if (_1365)\n    {\n        ax -= 20.0f;\n    }\n    float _1376;\n    if (ax <= (-1.5f))\n    {\n        _1376 = (-2.0f) - ax;\n    }\n    else\n    {\n        _1376 = 0.0f;\n    }\n    if (_1376 > 0.0f)\n    {\n        float _1390 = _1376 * 0.5f;\n        d = abs(d + _1390) - _1390;\n    }\n    float _1398 = fwidth(d);\n    float _1399 = max(_1398, 9.9999997473787516355514526367188e-05f);\n    float _1409 = clamp(0.5f - (d / max(shape_rs.y, _1399)), 0.0f, 1.0f);\n    float _1414;\n    if (shape_rs.y > _1399)\n    {\n        _1414 = (_1409 * _1409) * (3.0f - (2.0f * _1409));\n    }\n    else\n    {\n        _1414 = _1409;\n    }\n    float4 c = color;\n    bool _1436 = (_1376 <= 0.0f) && (ax > (-0.5f));\n    if (_1436)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1451 = cos(ax);\n            float _1453 = sin(ax);\n            g = ((dot(_1323, float2(_1451, _1453)) / max((abs(_1451) * _1329) + (abs(_1453) * _1331), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_1365)\n        {\n            float4 _1496 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _1496;\n            float3 param = _1496.xyz;\n            float param_1 = xform.y;\n            float3 _1503 = fa_tex_fix(param, param_1);\n            float4 _2292 = c;\n            _2292.x = _1503.x;\n            _2292.y = _1503.y;\n            _2292.z = _1503.z;\n            c = _2292;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1515 = scene_rgb(param_2);\n            float4 _1540 = lerp(float4(color.xyz * color.w, color.w), float4(_1515 * color2.w, color2.w), g.xxxx);\n            float _1542 = _1540.w;\n            float3 _1545;\n            if (_1542 > 9.9999997473787516355514526367188e-06f)\n            {\n                _1545 = _1540.xyz / _1542.xxx;\n            }\n            else\n            {\n                _1545 = color.xyz;\n            }\n            c = float4(_1545, _1542);\n        }\n    }\n    float4 _2301 = c;\n    _2301.w = _2301.w * _1414;\n    c = _2301;\n    if (_1436 || (shape_rs.y > 0.0f))\n    {\n        float _1586 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1595 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1595 + (_1586 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1601 = fa_srgb_to_linear(param_4);\n            float4 _2304 = c;\n            _2304.x = _1601.x;\n            _2304.y = _1601.y;\n            _2304.z = _1601.z;\n            c = _2304;\n        }\n        else\n        {\n            float4 _1611 = c;\n            float3 _1614 = _1611.xyz + (_1586 * 0.0039215688593685626983642578125f).xxx;\n            float4 _2311 = _1611;\n            _2311.x = _1614.x;\n            _2311.y = _1614.y;\n            _2311.z = _1614.z;\n            c = _2311;\n        }\n        float4 _2316 = c;\n        _2316.w = clamp(_2316.w + ((_1586 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _2316.w)), 0.0f, 1.0f);\n        c = _2316;\n    }\n    return c;\n}\n\nfloat3 rim_color(float a0, float mode)\n{\n    float2 _1106 = float2(_699_fx_rim_uv.x, 0.0f);\n    float4 _1108 = tex.Sample(smp, uv - _1106);\n    float _1109 = _1108.w;\n    float4 _1119 = tex.Sample(smp, uv + _1106);\n    float _1120 = _1119.w;\n    float2 _1128 = float2(0.0f, _699_fx_rim_uv.y);\n    float4 _1130 = tex.Sample(smp, uv - _1128);\n    float _1131 = _1130.w;\n    float4 _1141 = tex.Sample(smp, uv + _1128);\n    float _1142 = _1141.w;\n    float _1157 = _1109 - _1120;\n    float _1160 = _1142 - _1131;\n    float _1170 = cos(params.y);\n    float _1172 = sin(params.y);\n    float2 _1198 = ((float2(_1170, _1172) * _1157) + ((float2(-_1172, _1170) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _1160)) / max(length(float2(_1157, _1160)), 9.9999997473787516355514526367188e-05f).xx;\n    float3 sum = 0.0f.xxx;\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _699_lit.x)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_699_light_pos[i].w < 0.0f)\n        {\n            to_l = _699_light_pos[i].xy / max(length(_699_light_pos[i].xy), 9.9999997473787516355514526367188e-05f).xx;\n        }\n        else\n        {\n            float2 _1244 = _699_light_pos[i].xy - world_xy;\n            float _1247 = length(_1244);\n            att = pow(clamp(1.0f - (_1247 / max(_699_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _699_light_color[i].w);\n            to_l = _1244 / max(_1247, 9.9999997473787516355514526367188e-05f).xx;\n            if (_699_light_shadow_v[i].x >= 0.0f)\n            {\n                float param = _699_light_shadow_v[i].x;\n                float param_1 = _699_light_shadow_v[i].y;\n                float2 param_2 = -_1244;\n                float param_3 = _699_light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1244;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (_699_light_color[i].xyz * (att * max(dot(_1198, to_l), 0.0f)));\n    }\n    return (sum * _699_fx_rim.xyz) * (a0 * (1.0f - min(min(_1109, _1120), min(_1131, _1142))));\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _705 = gl_FragCoord.xy * _699_fa_target.xy;\n    float _709 = _705.y;\n    return float2(_705.x, lerp(_709, 1.0f - _709, _699_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _747 = base_mode < 0.5f;\n    bool _758;\n    if (!_747)\n    {\n        _758 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _758 = _747;\n    }\n    float _759;\n    if (_758)\n    {\n        _759 = shape_half.x;\n    }\n    else\n    {\n        _759 = 0.0f;\n    }\n    QuadInput _2242 = { uv, color, world_xy, fa_screen_uv(), _699_fa_time.x, base_mode, 0.0f.xxxx, _759 };\n    return _2242;\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _682 = scene_rgb(param);\n    return _682;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = tint.xyz;\n    float3 _787 = fa_scene_rgb(param) * _784_boost;\n    s.color.x = _787.x;\n    s.color.y = _787.y;\n    s.color.z = _787.z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1641 = params.x > 31.5f;\n    if (_1641)\n    {\n        mode -= 32.0f;\n    }\n    float _1649 = mode;\n    bool _1651 = _1649 > 15.5f;\n    if (_1651)\n    {\n        mode -= 16.0f;\n    }\n    float _1659 = mode;\n    bool _1661 = _1659 > 7.5f;\n    if (_1661)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1651)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1651)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1723 = tex_color(param_5);\n                float4 _1725 = _1723 * color;\n                float4 param_6 = _1725;\n                float param_7 = mode;\n                float _1732 = _1725.w;\n                frag_color = float4(lit_color(param_6, param_7), _1732);\n                if (_699_fx_rim.w > 0.5f)\n                {\n                    float param_8 = _1732;\n                    float param_9 = mode;\n                    float4 _1748 = frag_color;\n                    float3 _1750 = _1748.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1750.x;\n                    frag_color.y = _1750.y;\n                    frag_color.z = _1750.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1780 = length(uv);\n                    float _1783 = fwidth(_1780);\n                    float _1784 = max(_1783, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1780) / _1784) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1780) / _1784) + 0.5f, 0.0f, 1.0f) * clamp(((_1780 - params.y) / _1784) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1824 = clamp(1.0f - _1780, 0.0f, 1.0f);\n                            cov = (_1824 * _1824) * (3.0f - (2.0f * _1824));\n                        }\n                    }\n                    float3 _1833;\n                    if (_1651)\n                    {\n                        float4 param_10 = color;\n                        float param_11 = 5.0f;\n                        _1833 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1833 = color.xyz;\n                    }\n                    frag_color = float4(_1833, color.w * cov);\n                }\n            }\n        }\n    }\n    if (_699_fx_emit.w > 0.5f)\n    {\n        float3 e = _699_fx_emit.xyz;\n        if (_699_fx_emit.w > 1.5f)\n        {\n            float3 param_12 = fx_emissive_tex.Sample(smp, (uv * _699_fx_emit_uv.xy) + _699_fx_emit_uv.zw).xyz;\n            float param_13 = _699_fx_emit.w - 2.0f;\n            float3 _1888 = fa_tex_fix(param_12, param_13);\n            e *= _1888;\n        }\n        float4 _1892 = frag_color;\n        float3 _1894 = _1892.xyz + e;\n        frag_color.x = _1894.x;\n        frag_color.y = _1894.y;\n        frag_color.z = _1894.z;\n    }\n    float param_14 = mode;\n    float4 _2222 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface _2224 = { _2222 };\n    QuadSurface param_16 = _2224;\n    fragment(param_15, param_16);\n    _2222 = param_16.color;\n    frag_color = param_16.color;\n    if (_1641)\n    {\n        float4 _1920 = frag_color;\n        float3 param_17 = color2.xyz;\n        float3 _1925 = scene_rgb(param_17);\n        float3 _1929 = lerp(_1920.xyz, _1925, color2.w.xxx);\n        frag_color.x = _1929.x;\n        frag_color.y = _1929.y;\n        frag_color.z = _1929.z;\n    }\n    if (_1661)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1953 = _699_fog_col.w > 0.0f;\n    bool _1961;\n    if (!_1953)\n    {\n        _1961 = _699_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1961 = _1953;\n    }\n    if (_1961)\n    {\n        float3 _1975 = float3(world_xy, world_z) - _699_fog_eye.xyz;\n        float _1982 = dot(_1975, _699_fog_c.xyz);\n        bool _1986 = _699_fog_c.w > 0.5f;\n        float _1987;\n        if (_1986)\n        {\n            _1987 = _1982;\n        }\n        else\n        {\n            _1987 = length(_1975);\n        }\n        float _1999 = _1987 - _699_fog_b.x;\n        if (_1999 > 0.0f)\n        {\n            float _2008 = _699_fog_col.w * _1999;\n            float tau = _2008 * _2008;\n            if (_699_fog_b.y > 0.0f)\n            {\n                float _2024;\n                if (_1986)\n                {\n                    _2024 = world_xy.y - (_699_fog_c.y * _1982);\n                }\n                else\n                {\n                    _2024 = _699_fog_eye.y;\n                }\n                float _2045 = lerp(_2024, world_xy.y, clamp(_699_fog_b.x / _1987, 0.0f, 1.0f));\n                float _2049 = world_xy.y - _2045;\n                float _2054 = _2045 - _699_fog_b.z;\n                float _2059 = world_xy.y - _699_fog_b.z;\n                bool _2062 = _2054 <= 0.0f;\n                bool _2063 = !_2062;\n                bool _2069;\n                if (_2063)\n                {\n                    _2069 = _699_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2069 = _2062;\n                }\n                float _2070;\n                if (_2069)\n                {\n                    _2070 = _699_fog_b.y;\n                }\n                else\n                {\n                    _2070 = _699_fog_b.y * exp(-min(_699_fog_b.w * _2054, 80.0f));\n                }\n                bool _2097;\n                if (_2063)\n                {\n                    _2097 = _699_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2097 = _2062;\n                }\n                float _2098;\n                if (_2097)\n                {\n                    _2098 = _699_fog_b.y * _2054;\n                }\n                else\n                {\n                    _2098 = (_699_fog_b.y * (1.0f - exp(-min(_699_fog_b.w * _2054, 80.0f)))) / _699_fog_b.w;\n                }\n                bool _2123 = _2059 <= 0.0f;\n                bool _2130;\n                if (!_2123)\n                {\n                    _2130 = _699_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2130 = _2123;\n                }\n                float _2131;\n                if (_2130)\n                {\n                    _2131 = _699_fog_b.y * _2059;\n                }\n                else\n                {\n                    _2131 = (_699_fog_b.y * (1.0f - exp(-min(_699_fog_b.w * _2059, 80.0f)))) / _699_fog_b.w;\n                }\n                float _2158;\n                if (abs(_2049) < 0.001000000047497451305389404296875f)\n                {\n                    _2158 = _2070;\n                }\n                else\n                {\n                    _2158 = (_2131 - _2098) / _2049;\n                }\n                tau += (_1999 * max(_2158, 0.0f));\n            }\n            float4 _2181 = frag_color;\n            float3 _2189 = lerp(_2181.xyz, _699_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _2189.x;\n            frag_color.y = _2189.y;\n            frag_color.z = _2189.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 7
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 8
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_107",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 1584,
            "struct_name": "quad_fs_params",
            "inst_name": "_699",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_784",
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
      "vs": "struct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\ncbuffer vs_params : register(b0)\n{\n    row_major float4x4 _107_view_proj : packoffset(c0);\n    float4 _107_cspace : packoffset(c4);\n    float4 _107_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n    float4 fa_inst_d0 : TEXCOORD7;\n    float4 fa_inst_d1 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation float4 fa_inst_v0 : TEXCOORD9;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float shift;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += shift;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n    float3 _184 = position;\n    float2 _185 = texcoord0;\n    float4 _186 = color0;\n    if (_107_cspace.x > 0.5f)\n    {\n        float3 param_3 = color0.xyz;\n        float3 _119 = fa_srgb_to_linear(param_3);\n        float4 _198 = _186;\n        _198.x = _119.x;\n        _198.y = _119.y;\n        _198.z = _119.z;\n        _186 = _198;\n    }\n    QuadVertex _193 = { _184, _185, _186 };\n    QuadVertex param_4 = _193;\n    vertex(param_4);\n    _184 = param_4.world_pos;\n    _185 = param_4.uv;\n    _186 = param_4.color;\n    gl_Position = mul(float4(param_4.world_pos, 1.0f), _107_view_proj);\n    uv = param_4.uv;\n    color = param_4.color;\n    xform = _107_cspace.xyz;\n    params = params0;\n    world_xy = param_4.world_pos.xy;\n    world_z = param_4.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _164_lit : packoffset(c0);\n    float4 _164_ambient : packoffset(c1);\n    float4 _164_normal_uv : packoffset(c2);\n    float4 _164_flat_ambient : packoffset(c3);\n    float4 _164_light_map : packoffset(c4);\n    float4 _164_light_pos[16] : packoffset(c5);\n    float4 _164_light_color[16] : packoffset(c21);\n    float4 _164_light_shadow_v[16] : packoffset(c37);\n    float4 _164_fog_col : packoffset(c53);\n    float4 _164_fog_b : packoffset(c54);\n    float4 _164_fog_c : packoffset(c55);\n    float4 _164_fog_eye : packoffset(c56);\n    float4 _164_fa_time : packoffset(c57);\n    float4 _164_fa_target : packoffset(c58);\n    float4 _164_fx_emit : packoffset(c59);\n    float4 _164_fx_emit_uv : packoffset(c60);\n    float4 _164_fx_rim : packoffset(c61);\n    float4 _164_fx_rim_uv : packoffset(c62);\n    float4 _164_light_cookie[16] : packoffset(c63);\n    float4 _164_light_cookie_xf[16] : packoffset(c79);\n    float4 _164_fa_scene : packoffset(c95);\n    float4 _164_fa_world_uv[3] : packoffset(c96);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _256_boost : packoffset(c0);\n    float _256_fa_pad0 : packoffset(c0.y);\n    float _256_fa_pad1 : packoffset(c0.z);\n    float _256_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 frag_color;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation float4 fa_inst_v0 : TEXCOORD9;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD10;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nstatic float shift;\nstatic float4 tint;\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _114 = fa_linear_to_srgb(param);\n        c = _114;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _123 = fa_srgb_to_linear(param_1);\n            c = _123;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _171 = gl_FragCoord.xy * _164_fa_target.xy;\n    float _176 = _171.y;\n    return float2(_171.x, lerp(_176, 1.0f - _176, _164_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _219 = base_mode < 0.5f;\n    bool _230;\n    if (!_219)\n    {\n        _230 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _230 = _219;\n    }\n    float _231;\n    if (_230)\n    {\n        _231 = shape_half.x;\n    }\n    else\n    {\n        _231 = 0.0f;\n    }\n    QuadInput _370 = { uv, color, world_xy, fa_screen_uv(), _164_fa_time.x, base_mode, 0.0f.xxxx, _231 };\n    return _370;\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _139 = fa_srgb_to_linear(param);\n        c = _139;\n    }\n    return c;\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _145 = scene_rgb(param);\n    return _145;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = tint.xyz;\n    float3 _259 = fa_scene_rgb(param) * _256_boost;\n    s.color.x = _259.x;\n    s.color.y = _259.y;\n    s.color.z = _259.z;\n}\n\nvoid frag_main()\n{\n    float4 _286 = tex.Sample(smp, uv);\n    float3 param = _286.xyz;\n    float param_1 = xform.y;\n    float3 _295 = fa_tex_fix(param, param_1);\n    frag_color = float4(_295, _286.w) * color;\n    float param_2 = 0.0f;\n    float4 _350 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _352 = { _350 };\n    QuadSurface param_4 = _352;\n    fragment(param_3, param_4);\n    _350 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 7
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 8
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_107",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 1584,
            "struct_name": "quad_fs_params",
            "inst_name": "_164",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_256",
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
