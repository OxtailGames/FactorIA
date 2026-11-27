{
  "format": "factoria.shader/1",
  "engine": "0.39.0",
  "template": "d75bc1c2988d2355d3b6c4618a7c68ff76094f3e9d32765c88b7244d10541da4",
  "slang": "hlsl5",
  "params": [
    "tint"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _147 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _147;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _696_lit : packoffset(c0);\n    float4 _696_ambient : packoffset(c1);\n    float4 _696_normal_uv : packoffset(c2);\n    float4 _696_flat_ambient : packoffset(c3);\n    float4 _696_light_map : packoffset(c4);\n    float4 _696_light_pos[16] : packoffset(c5);\n    float4 _696_light_color[16] : packoffset(c21);\n    float4 _696_light_shadow_v[16] : packoffset(c37);\n    float4 _696_fog_col : packoffset(c53);\n    float4 _696_fog_b : packoffset(c54);\n    float4 _696_fog_c : packoffset(c55);\n    float4 _696_fog_eye : packoffset(c56);\n    float4 _696_fa_time : packoffset(c57);\n    float4 _696_fa_target : packoffset(c58);\n    float4 _696_fx_emit : packoffset(c59);\n    float4 _696_fx_emit_uv : packoffset(c60);\n    float4 _696_fx_rim : packoffset(c61);\n    float4 _696_fx_rim_uv : packoffset(c62);\n    float4 _696_light_cookie[16] : packoffset(c63);\n    float4 _696_light_cookie_xf[16] : packoffset(c79);\n    float4 _696_fa_scene : packoffset(c95);\n    float4 _696_fa_world_uv[3] : packoffset(c96);\n    float4 _696_gi_xf : packoffset(c99);\n    float4 _696_gi_p : packoffset(c100);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _770_tint : packoffset(c0);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> fx_cookie_tex : register(t5);\nSamplerState light_smp : register(s1);\nTexture2D<float4> fx_gi_tex : register(t6);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nTexture2D<float4> fx_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _628 = fa_linear_to_srgb(param);\n        c = _628;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _636 = fa_srgb_to_linear(param_1);\n            c = _636;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _647 = tex.Sample(smp, p);\n    float3 param = _647.xyz;\n    float param_1 = xform.y;\n    float3 _657 = fa_tex_fix(param, param_1);\n    return float4(_657, _647.w);\n}\n\nfloat3 gi_irradiance()\n{\n    float2 _833 = (world_xy * _696_gi_xf.xy) + _696_gi_xf.zw;\n    float4 _840 = fx_gi_tex.SampleLevel(light_smp, _833, 0.0f);\n    float _844 = _833.x;\n    bool _845 = _844 >= 0.0f;\n    bool _851;\n    if (_845)\n    {\n        _851 = _833.y >= 0.0f;\n    }\n    else\n    {\n        _851 = _845;\n    }\n    bool _857;\n    if (_851)\n    {\n        _857 = _844 <= 1.0f;\n    }\n    else\n    {\n        _857 = _851;\n    }\n    bool _863;\n    if (_857)\n    {\n        _863 = _833.y <= 1.0f;\n    }\n    else\n    {\n        _863 = _857;\n    }\n    bool _871;\n    if (_863)\n    {\n        _871 = _840.w > 0.0199999995529651641845703125f;\n    }\n    else\n    {\n        _871 = _863;\n    }\n    float3 _872;\n    if (_871)\n    {\n        _872 = (_840.xyz / _840.w.xxx) * _696_gi_p.x;\n    }\n    else\n    {\n        _872 = 0.0f.xxx;\n    }\n    return _872;\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _137 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_137.x * 255.0f) + 0.5f) * 256.0f) + floor((_137.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _240 = floor(tt);\n    float _250 = _240 - (1024.0f * floor(_240 * 0.0009765625f));\n    float _253 = _250 + 1.0f;\n    float i1 = _253;\n    if (_253 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _250;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5f, 0.0f, 1.0f), tt - _240);\n}\n\nfloat light_shadow_soft(float v, float size, float2 d, float radius)\n{\n    float _290 = length(d);\n    float result = 1.0f;\n    if (_290 >= 9.9999997473787516355514526367188e-05f)\n    {\n        float _301 = atan2(d.y, d.x);\n        float a = _301;\n        float _304;\n        if (_301 < 0.0f)\n        {\n            _304 = a + 6.283185482025146484375f;\n        }\n        else\n        {\n            _304 = a;\n        }\n        a = _304;\n        float _314 = _304 * 162.9746551513671875f;\n        float _323 = min((size * 10.0f) / _290, 0.699999988079071044921875f) * 162.9746551513671875f;\n        float sum = 0.0f;\n        float n = 0.0f;\n        for (int k = 0; k < 12; k++)\n        {\n            float _349 = floor(_314 + ((((float(k) + 0.5f) * 0.16666667163372039794921875f) - 1.0f) * _323));\n            float param = v;\n            float param_1 = _349 - (1024.0f * floor(_349 * 0.0009765625f));\n            float _363 = shadow_texel(param, param_1) * radius;\n            if (_363 < _290)\n            {\n                sum += _363;\n                n += 1.0f;\n            }\n        }\n        if (n > 0.5f)\n        {\n            float _395 = min(size * ((1.0f / max(sum / n, 1.0f)) - (1.0f / _290)), 0.699999988079071044921875f) * 162.9746551513671875f;\n            float acc = 0.0f;\n            float wsum = 0.0f;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _413 = ((float(k_1) + 0.5f) * 0.125f) - 1.0f;\n                float _419 = 1.0f - (0.800000011920928955078125f * abs(_413));\n                float param_2 = v;\n                float param_3 = _314 + (_413 * _395);\n                float param_4 = _290;\n                float param_5 = radius;\n                acc += (_419 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _419;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _161 = length(d);\n    if (_161 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _175 = atan2(d.y, d.x);\n    float a = _175;\n    float _178;\n    if (_175 < 0.0f)\n    {\n        _178 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _178 = a;\n    }\n    a = _178;\n    float _190 = _178 * 162.9746551513671875f;\n    float _195 = min(floor(_190), 1023.0f);\n    float _202 = _195 + 1.0f;\n    float i1 = _202;\n    if (_202 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _195;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _161) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _161) + 0.5f, 0.0f, 1.0f), _190 - _195);\n}\n\nfloat light_shadow_sized(float v, float size, float2 d, float radius)\n{\n    float r = 1.0f;\n    if (size > 0.0f)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nfloat3 cookie_coord(float4 cell, float4 xf, float2 off)\n{\n    float2 _500 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _504 = _500.x + 0.5f;\n    float2 c = float2(_504, 0.5f - _500.y);\n    bool _512 = _504 >= 0.0f;\n    bool _518;\n    if (_512)\n    {\n        _518 = c.x <= 1.0f;\n    }\n    else\n    {\n        _518 = _512;\n    }\n    bool _524;\n    if (_518)\n    {\n        _524 = c.y >= 0.0f;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    bool _530;\n    if (_524)\n    {\n        _530 = c.y <= 1.0f;\n    }\n    else\n    {\n        _530 = _524;\n    }\n    float2 _532 = c;\n    float2 _537 = clamp(_532, 0.001953125f.xx, 0.998046875f.xx);\n    c = _537;\n    return float3(cell.x + (_537.x * cell.w), cell.y + (_537.y * cell.z), float(_530));\n}\n\nfloat cookie_value(float4 t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125f, 0.715200006961822509765625f, 0.072200000286102294921875f)) * t.w;\n}\n\nfloat cookie_att(int i, float2 d)\n{\n    if (_696_light_cookie[i].w == 0.0f)\n    {\n        return 1.0f;\n    }\n    float4 param = _696_light_cookie[i];\n    float4 param_1 = _696_light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _807 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.SampleLevel(light_smp, _807.xy, 0.0f);\n    return cookie_value(param_3) * _807.z;\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _894 = _696_lit.y > 0.5f;\n    if (_894)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _696_normal_uv.xy) + _696_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _918 = fa_tex_fix(param, param_1);\n        float3 _922 = (_918 * 2.0f) - 1.0f.xxx;\n        float _929 = cos(params.y);\n        float _931 = sin(params.y);\n        n = normalize(float3((float2(_929, _931) * _922.x) + ((float2(-_931, _929) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _922.y), max(_922.z, 0.0500000007450580596923828125f)));\n    }\n    bool _965 = !_894;\n    bool _971;\n    if (_965)\n    {\n        _971 = _696_lit.z > 0.5f;\n    }\n    else\n    {\n        _971 = _965;\n    }\n    float3 _974;\n    if (_971)\n    {\n        _974 = _696_flat_ambient.xyz;\n    }\n    else\n    {\n        _974 = _696_ambient.xyz;\n    }\n    float3 total = _974;\n    if (_696_gi_p.x > 0.0f)\n    {\n        total += gi_irradiance();\n    }\n    bool _999;\n    if (_971)\n    {\n        _999 = _696_lit.z < 1.5f;\n    }\n    else\n    {\n        _999 = _971;\n    }\n    if (_999)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _696_light_map.xy, 0.0f).xyz * _696_light_map.z);\n    }\n    float3 l;\n    float _1126;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1036;\n        if (!_971)\n        {\n            _1036 = float(i) >= _696_lit.x;\n        }\n        else\n        {\n            _1036 = _971;\n        }\n        if (_1036)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_696_light_pos[i].w < 0.0f)\n        {\n            l = _696_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _1062 = _696_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_1062) / max(_696_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _696_light_color[i].w);\n            float3 _1082 = float3(_1062, _696_light_pos[i].z);\n            l = _1082 / max(length(_1082), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_696_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _696_light_shadow_v[i].x;\n                float param_3 = _696_light_shadow_v[i].y;\n                float2 param_4 = -_1062;\n                float param_5 = _696_light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            float2 param_7 = -_1062;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_894)\n        {\n            _1126 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _1126 = 1.0f;\n        }\n        total += (_696_light_color[i].xyz * (att * _1126));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _673 = fa_srgb_to_linear(param);\n        c = _673;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _1376 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _1380 = uv * _1376;\n    float _1386 = _1376.x;\n    float _1388 = _1376.y;\n    float _1390 = clamp(shape_rs.x, 0.0f, min(_1386, _1388));\n    float2 _1401 = (abs(_1380) - _1376) + _1390.xx;\n    float d = (length(max(_1401, 0.0f.xx)) + min(max(_1401.x, _1401.y), 0.0f)) - _1390;\n    float ax = params.y;\n    bool _1422 = params.y > 15.0f;\n    if (_1422)\n    {\n        ax -= 20.0f;\n    }\n    float _1433;\n    if (ax <= (-1.5f))\n    {\n        _1433 = (-2.0f) - ax;\n    }\n    else\n    {\n        _1433 = 0.0f;\n    }\n    if (_1433 > 0.0f)\n    {\n        float _1447 = _1433 * 0.5f;\n        d = abs(d + _1447) - _1447;\n    }\n    float _1455 = fwidth(d);\n    float _1456 = max(_1455, 9.9999997473787516355514526367188e-05f);\n    float _1466 = clamp(0.5f - (d / max(shape_rs.y, _1456)), 0.0f, 1.0f);\n    float _1471;\n    if (shape_rs.y > _1456)\n    {\n        _1471 = (_1466 * _1466) * (3.0f - (2.0f * _1466));\n    }\n    else\n    {\n        _1471 = _1466;\n    }\n    float4 c = color;\n    bool _1493 = (_1433 <= 0.0f) && (ax > (-0.5f));\n    if (_1493)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1508 = cos(ax);\n            float _1510 = sin(ax);\n            g = ((dot(_1380, float2(_1508, _1510)) / max((abs(_1508) * _1386) + (abs(_1510) * _1388), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_1422)\n        {\n            float4 _1553 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _1553;\n            float3 param = _1553.xyz;\n            float param_1 = xform.y;\n            float3 _1560 = fa_tex_fix(param, param_1);\n            float4 _2355 = c;\n            _2355.x = _1560.x;\n            _2355.y = _1560.y;\n            _2355.z = _1560.z;\n            c = _2355;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1572 = scene_rgb(param_2);\n            float4 _1597 = lerp(float4(color.xyz * color.w, color.w), float4(_1572 * color2.w, color2.w), g.xxxx);\n            float _1599 = _1597.w;\n            float3 _1602;\n            if (_1599 > 9.9999997473787516355514526367188e-06f)\n            {\n                _1602 = _1597.xyz / _1599.xxx;\n            }\n            else\n            {\n                _1602 = color.xyz;\n            }\n            c = float4(_1602, _1599);\n        }\n    }\n    float4 _2364 = c;\n    _2364.w = _2364.w * _1471;\n    c = _2364;\n    if (_1493 || (shape_rs.y > 0.0f))\n    {\n        float _1643 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1652 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1652 + (_1643 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1658 = fa_srgb_to_linear(param_4);\n            float4 _2367 = c;\n            _2367.x = _1658.x;\n            _2367.y = _1658.y;\n            _2367.z = _1658.z;\n            c = _2367;\n        }\n        else\n        {\n            float4 _1668 = c;\n            float3 _1671 = _1668.xyz + (_1643 * 0.0039215688593685626983642578125f).xxx;\n            float4 _2374 = _1668;\n            _2374.x = _1671.x;\n            _2374.y = _1671.y;\n            _2374.z = _1671.z;\n            c = _2374;\n        }\n        float4 _2379 = c;\n        _2379.w = clamp(_2379.w + ((_1643 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _2379.w)), 0.0f, 1.0f);\n        c = _2379;\n    }\n    return c;\n}\n\nfloat3 rim_color(float a0, float mode)\n{\n    float2 _1163 = float2(_696_fx_rim_uv.x, 0.0f);\n    float4 _1165 = tex.Sample(smp, uv - _1163);\n    float _1166 = _1165.w;\n    float4 _1176 = tex.Sample(smp, uv + _1163);\n    float _1177 = _1176.w;\n    float2 _1185 = float2(0.0f, _696_fx_rim_uv.y);\n    float4 _1187 = tex.Sample(smp, uv - _1185);\n    float _1188 = _1187.w;\n    float4 _1198 = tex.Sample(smp, uv + _1185);\n    float _1199 = _1198.w;\n    float _1214 = _1166 - _1177;\n    float _1217 = _1199 - _1188;\n    float _1227 = cos(params.y);\n    float _1229 = sin(params.y);\n    float2 _1255 = ((float2(_1227, _1229) * _1214) + ((float2(-_1229, _1227) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _1217)) / max(length(float2(_1214, _1217)), 9.9999997473787516355514526367188e-05f).xx;\n    float3 sum = 0.0f.xxx;\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _696_lit.x)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_696_light_pos[i].w < 0.0f)\n        {\n            to_l = _696_light_pos[i].xy / max(length(_696_light_pos[i].xy), 9.9999997473787516355514526367188e-05f).xx;\n        }\n        else\n        {\n            float2 _1301 = _696_light_pos[i].xy - world_xy;\n            float _1304 = length(_1301);\n            att = pow(clamp(1.0f - (_1304 / max(_696_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _696_light_color[i].w);\n            to_l = _1301 / max(_1304, 9.9999997473787516355514526367188e-05f).xx;\n            if (_696_light_shadow_v[i].x >= 0.0f)\n            {\n                float param = _696_light_shadow_v[i].x;\n                float param_1 = _696_light_shadow_v[i].y;\n                float2 param_2 = -_1301;\n                float param_3 = _696_light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1301;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (_696_light_color[i].xyz * (att * max(dot(_1255, to_l), 0.0f)));\n    }\n    return (sum * _696_fx_rim.xyz) * (a0 * (1.0f - min(min(_1166, _1177), min(_1188, _1199))));\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _702 = gl_FragCoord.xy * _696_fa_target.xy;\n    float _706 = _702.y;\n    return float2(_702.x, lerp(_706, 1.0f - _706, _696_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _744 = base_mode < 0.5f;\n    bool _755;\n    if (!_744)\n    {\n        _755 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _755 = _744;\n    }\n    float _756;\n    if (_755)\n    {\n        _756 = shape_half.x;\n    }\n    else\n    {\n        _756 = 0.0f;\n    }\n    QuadInput _2299 = { uv, color, world_xy, fa_screen_uv(), _696_fa_time.x, base_mode, 0.0f.xxxx, _756 };\n    return _2299;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _679 = scene_rgb(param);\n    return _679;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = _770_tint.xyz;\n    float4 _777 = s.color;\n    float3 _779 = _777.xyz * fa_scene_rgb(param);\n    s.color.x = _779.x;\n    s.color.y = _779.y;\n    s.color.z = _779.z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1698 = params.x > 31.5f;\n    if (_1698)\n    {\n        mode -= 32.0f;\n    }\n    float _1706 = mode;\n    bool _1708 = _1706 > 15.5f;\n    if (_1708)\n    {\n        mode -= 16.0f;\n    }\n    float _1716 = mode;\n    bool _1718 = _1716 > 7.5f;\n    if (_1718)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1708)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1708)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1780 = tex_color(param_5);\n                float4 _1782 = _1780 * color;\n                float4 param_6 = _1782;\n                float param_7 = mode;\n                float _1789 = _1782.w;\n                frag_color = float4(lit_color(param_6, param_7), _1789);\n                if (_696_fx_rim.w > 0.5f)\n                {\n                    float param_8 = _1789;\n                    float param_9 = mode;\n                    float4 _1805 = frag_color;\n                    float3 _1807 = _1805.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1807.x;\n                    frag_color.y = _1807.y;\n                    frag_color.z = _1807.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1837 = length(uv);\n                    float _1840 = fwidth(_1837);\n                    float _1841 = max(_1840, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1837) / _1841) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1837) / _1841) + 0.5f, 0.0f, 1.0f) * clamp(((_1837 - params.y) / _1841) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1881 = clamp(1.0f - _1837, 0.0f, 1.0f);\n                            cov = (_1881 * _1881) * (3.0f - (2.0f * _1881));\n                        }\n                    }\n                    float3 _1890;\n                    if (_1708)\n                    {\n                        float4 param_10 = color;\n                        float param_11 = 5.0f;\n                        _1890 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1890 = color.xyz;\n                    }\n                    frag_color = float4(_1890, color.w * cov);\n                }\n            }\n        }\n    }\n    if (_696_fx_emit.w > 0.5f)\n    {\n        float3 e = _696_fx_emit.xyz;\n        if (_696_fx_emit.w > 1.5f)\n        {\n            float3 param_12 = fx_emissive_tex.Sample(smp, (uv * _696_fx_emit_uv.xy) + _696_fx_emit_uv.zw).xyz;\n            float param_13 = _696_fx_emit.w - 2.0f;\n            float3 _1945 = fa_tex_fix(param_12, param_13);\n            e *= _1945;\n        }\n        float4 _1949 = frag_color;\n        float3 _1951 = _1949.xyz + e;\n        frag_color.x = _1951.x;\n        frag_color.y = _1951.y;\n        frag_color.z = _1951.z;\n    }\n    float param_14 = mode;\n    float4 _2279 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface _2281 = { _2279 };\n    QuadSurface param_16 = _2281;\n    fragment(param_15, param_16);\n    _2279 = param_16.color;\n    frag_color = param_16.color;\n    if (_1698)\n    {\n        float4 _1977 = frag_color;\n        float3 param_17 = color2.xyz;\n        float3 _1982 = scene_rgb(param_17);\n        float3 _1986 = lerp(_1977.xyz, _1982, color2.w.xxx);\n        frag_color.x = _1986.x;\n        frag_color.y = _1986.y;\n        frag_color.z = _1986.z;\n    }\n    if (_1718)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _2010 = _696_fog_col.w > 0.0f;\n    bool _2018;\n    if (!_2010)\n    {\n        _2018 = _696_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2018 = _2010;\n    }\n    if (_2018)\n    {\n        float3 _2032 = float3(world_xy, world_z) - _696_fog_eye.xyz;\n        float _2039 = dot(_2032, _696_fog_c.xyz);\n        bool _2043 = _696_fog_c.w > 0.5f;\n        float _2044;\n        if (_2043)\n        {\n            _2044 = _2039;\n        }\n        else\n        {\n            _2044 = length(_2032);\n        }\n        float _2056 = _2044 - _696_fog_b.x;\n        if (_2056 > 0.0f)\n        {\n            float _2065 = _696_fog_col.w * _2056;\n            float tau = _2065 * _2065;\n            if (_696_fog_b.y > 0.0f)\n            {\n                float _2081;\n                if (_2043)\n                {\n                    _2081 = world_xy.y - (_696_fog_c.y * _2039);\n                }\n                else\n                {\n                    _2081 = _696_fog_eye.y;\n                }\n                float _2102 = lerp(_2081, world_xy.y, clamp(_696_fog_b.x / _2044, 0.0f, 1.0f));\n                float _2106 = world_xy.y - _2102;\n                float _2111 = _2102 - _696_fog_b.z;\n                float _2116 = world_xy.y - _696_fog_b.z;\n                bool _2119 = _2111 <= 0.0f;\n                bool _2120 = !_2119;\n                bool _2126;\n                if (_2120)\n                {\n                    _2126 = _696_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2126 = _2119;\n                }\n                float _2127;\n                if (_2126)\n                {\n                    _2127 = _696_fog_b.y;\n                }\n                else\n                {\n                    _2127 = _696_fog_b.y * exp(-min(_696_fog_b.w * _2111, 80.0f));\n                }\n                bool _2154;\n                if (_2120)\n                {\n                    _2154 = _696_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2154 = _2119;\n                }\n                float _2155;\n                if (_2154)\n                {\n                    _2155 = _696_fog_b.y * _2111;\n                }\n                else\n                {\n                    _2155 = (_696_fog_b.y * (1.0f - exp(-min(_696_fog_b.w * _2111, 80.0f)))) / _696_fog_b.w;\n                }\n                bool _2180 = _2116 <= 0.0f;\n                bool _2187;\n                if (!_2180)\n                {\n                    _2187 = _696_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2187 = _2180;\n                }\n                float _2188;\n                if (_2187)\n                {\n                    _2188 = _696_fog_b.y * _2116;\n                }\n                else\n                {\n                    _2188 = (_696_fog_b.y * (1.0f - exp(-min(_696_fog_b.w * _2116, 80.0f)))) / _696_fog_b.w;\n                }\n                float _2215;\n                if (abs(_2106) < 0.001000000047497451305389404296875f)\n                {\n                    _2215 = _2127;\n                }\n                else\n                {\n                    _2215 = (_2188 - _2155) / _2106;\n                }\n                tau += (_2056 * max(_2215, 0.0f));\n            }\n            float4 _2238 = frag_color;\n            float3 _2246 = lerp(_2238.xyz, _696_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _2246.x;\n            frag_color.y = _2246.y;\n            frag_color.z = _2246.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_696",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_770",
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
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _147 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _147;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _157_lit : packoffset(c0);\n    float4 _157_ambient : packoffset(c1);\n    float4 _157_normal_uv : packoffset(c2);\n    float4 _157_flat_ambient : packoffset(c3);\n    float4 _157_light_map : packoffset(c4);\n    float4 _157_light_pos[16] : packoffset(c5);\n    float4 _157_light_color[16] : packoffset(c21);\n    float4 _157_light_shadow_v[16] : packoffset(c37);\n    float4 _157_fog_col : packoffset(c53);\n    float4 _157_fog_b : packoffset(c54);\n    float4 _157_fog_c : packoffset(c55);\n    float4 _157_fog_eye : packoffset(c56);\n    float4 _157_fa_time : packoffset(c57);\n    float4 _157_fa_target : packoffset(c58);\n    float4 _157_fx_emit : packoffset(c59);\n    float4 _157_fx_emit_uv : packoffset(c60);\n    float4 _157_fx_rim : packoffset(c61);\n    float4 _157_fx_rim_uv : packoffset(c62);\n    float4 _157_light_cookie[16] : packoffset(c63);\n    float4 _157_light_cookie_xf[16] : packoffset(c79);\n    float4 _157_fa_scene : packoffset(c95);\n    float4 _157_fa_world_uv[3] : packoffset(c96);\n    float4 _157_gi_xf : packoffset(c99);\n    float4 _157_gi_p : packoffset(c100);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _239_tint : packoffset(c0);\n};\n\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 frag_color;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _107 = fa_linear_to_srgb(param);\n        c = _107;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _116 = fa_srgb_to_linear(param_1);\n            c = _116;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _164 = gl_FragCoord.xy * _157_fa_target.xy;\n    float _169 = _164.y;\n    return float2(_164.x, lerp(_169, 1.0f - _169, _157_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _213 = base_mode < 0.5f;\n    bool _224;\n    if (!_213)\n    {\n        _224 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _224 = _213;\n    }\n    float _225;\n    if (_224)\n    {\n        _225 = shape_half.x;\n    }\n    else\n    {\n        _225 = 0.0f;\n    }\n    QuadInput _351 = { uv, color, world_xy, fa_screen_uv(), _157_fa_time.x, base_mode, 0.0f.xxxx, _225 };\n    return _351;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _132 = fa_srgb_to_linear(param);\n        c = _132;\n    }\n    return c;\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _138 = scene_rgb(param);\n    return _138;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = _239_tint.xyz;\n    float4 _246 = s.color;\n    float3 _248 = _246.xyz * fa_scene_rgb(param);\n    s.color.x = _248.x;\n    s.color.y = _248.y;\n    s.color.z = _248.z;\n}\n\nvoid frag_main()\n{\n    float4 _267 = tex.Sample(smp, uv);\n    float3 param = _267.xyz;\n    float param_1 = xform.y;\n    float3 _276 = fa_tex_fix(param, param_1);\n    frag_color = float4(_276, _267.w) * color;\n    float param_2 = 0.0f;\n    float4 _331 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _333 = { _331 };\n    QuadSurface param_4 = _333;\n    fragment(param_3, param_4);\n    _331 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_157",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_239",
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
