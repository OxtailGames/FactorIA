{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "c463ccd1917be78236231aa4aa6bc7a9036af5c2e4c419a950fb6e8c51e433a6",
  "slang": "hlsl5",
  "params": [
    "tint"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _147 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _147;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _695_lit : packoffset(c0);\n    float4 _695_ambient : packoffset(c1);\n    float4 _695_normal_uv : packoffset(c2);\n    float4 _695_flat_ambient : packoffset(c3);\n    float4 _695_light_map : packoffset(c4);\n    float4 _695_light_pos[16] : packoffset(c5);\n    float4 _695_light_color[16] : packoffset(c21);\n    float4 _695_light_shadow_v[16] : packoffset(c37);\n    float4 _695_fog_col : packoffset(c53);\n    float4 _695_fog_b : packoffset(c54);\n    float4 _695_fog_c : packoffset(c55);\n    float4 _695_fog_eye : packoffset(c56);\n    float4 _695_fa_time : packoffset(c57);\n    float4 _695_fa_target : packoffset(c58);\n    float4 _695_fx_emit : packoffset(c59);\n    float4 _695_fx_emit_uv : packoffset(c60);\n    float4 _695_fx_rim : packoffset(c61);\n    float4 _695_fx_rim_uv : packoffset(c62);\n    float4 _695_light_cookie[16] : packoffset(c63);\n    float4 _695_light_cookie_xf[16] : packoffset(c79);\n    float4 _695_gi_xf : packoffset(c95);\n    float4 _695_gi_p : packoffset(c96);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _769_tint : packoffset(c0);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> fx_cookie_tex : register(t5);\nSamplerState light_smp : register(s1);\nTexture2D<float4> fx_gi_tex : register(t6);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nTexture2D<float4> fx_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _628 = fa_linear_to_srgb(param);\n        c = _628;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _636 = fa_srgb_to_linear(param_1);\n            c = _636;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _647 = tex.Sample(smp, p);\n    float3 param = _647.xyz;\n    float param_1 = xform.y;\n    float3 _657 = fa_tex_fix(param, param_1);\n    return float4(_657, _647.w);\n}\n\nfloat3 gi_irradiance()\n{\n    float2 _832 = (world_xy * _695_gi_xf.xy) + _695_gi_xf.zw;\n    float4 _839 = fx_gi_tex.SampleLevel(light_smp, _832, 0.0f);\n    float _843 = _832.x;\n    bool _844 = _843 >= 0.0f;\n    bool _850;\n    if (_844)\n    {\n        _850 = _832.y >= 0.0f;\n    }\n    else\n    {\n        _850 = _844;\n    }\n    bool _856;\n    if (_850)\n    {\n        _856 = _843 <= 1.0f;\n    }\n    else\n    {\n        _856 = _850;\n    }\n    bool _862;\n    if (_856)\n    {\n        _862 = _832.y <= 1.0f;\n    }\n    else\n    {\n        _862 = _856;\n    }\n    bool _870;\n    if (_862)\n    {\n        _870 = _839.w > 0.0199999995529651641845703125f;\n    }\n    else\n    {\n        _870 = _862;\n    }\n    float3 _871;\n    if (_870)\n    {\n        _871 = (_839.xyz / _839.w.xxx) * _695_gi_p.x;\n    }\n    else\n    {\n        _871 = 0.0f.xxx;\n    }\n    return _871;\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _137 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_137.x * 255.0f) + 0.5f) * 256.0f) + floor((_137.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _240 = floor(tt);\n    float _250 = _240 - (1024.0f * floor(_240 * 0.0009765625f));\n    float _253 = _250 + 1.0f;\n    float i1 = _253;\n    if (_253 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _250;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5f, 0.0f, 1.0f), tt - _240);\n}\n\nfloat light_shadow_soft(float v, float size, float2 d, float radius)\n{\n    float _290 = length(d);\n    float result = 1.0f;\n    if (_290 >= 9.9999997473787516355514526367188e-05f)\n    {\n        float _301 = atan2(d.y, d.x);\n        float a = _301;\n        float _304;\n        if (_301 < 0.0f)\n        {\n            _304 = a + 6.283185482025146484375f;\n        }\n        else\n        {\n            _304 = a;\n        }\n        a = _304;\n        float _314 = _304 * 162.9746551513671875f;\n        float _323 = min((size * 10.0f) / _290, 0.699999988079071044921875f) * 162.9746551513671875f;\n        float sum = 0.0f;\n        float n = 0.0f;\n        for (int k = 0; k < 12; k++)\n        {\n            float _349 = floor(_314 + ((((float(k) + 0.5f) * 0.16666667163372039794921875f) - 1.0f) * _323));\n            float param = v;\n            float param_1 = _349 - (1024.0f * floor(_349 * 0.0009765625f));\n            float _363 = shadow_texel(param, param_1) * radius;\n            if (_363 < _290)\n            {\n                sum += _363;\n                n += 1.0f;\n            }\n        }\n        if (n > 0.5f)\n        {\n            float _395 = min(size * ((1.0f / max(sum / n, 1.0f)) - (1.0f / _290)), 0.699999988079071044921875f) * 162.9746551513671875f;\n            float acc = 0.0f;\n            float wsum = 0.0f;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _413 = ((float(k_1) + 0.5f) * 0.125f) - 1.0f;\n                float _419 = 1.0f - (0.800000011920928955078125f * abs(_413));\n                float param_2 = v;\n                float param_3 = _314 + (_413 * _395);\n                float param_4 = _290;\n                float param_5 = radius;\n                acc += (_419 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _419;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _161 = length(d);\n    if (_161 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _175 = atan2(d.y, d.x);\n    float a = _175;\n    float _178;\n    if (_175 < 0.0f)\n    {\n        _178 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _178 = a;\n    }\n    a = _178;\n    float _190 = _178 * 162.9746551513671875f;\n    float _195 = min(floor(_190), 1023.0f);\n    float _202 = _195 + 1.0f;\n    float i1 = _202;\n    if (_202 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _195;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _161) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _161) + 0.5f, 0.0f, 1.0f), _190 - _195);\n}\n\nfloat light_shadow_sized(float v, float size, float2 d, float radius)\n{\n    float r = 1.0f;\n    if (size > 0.0f)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nfloat3 cookie_coord(float4 cell, float4 xf, float2 off)\n{\n    float2 _500 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _504 = _500.x + 0.5f;\n    float2 c = float2(_504, 0.5f - _500.y);\n    bool _512 = _504 >= 0.0f;\n    bool _518;\n    if (_512)\n    {\n        _518 = c.x <= 1.0f;\n    }\n    else\n    {\n        _518 = _512;\n    }\n    bool _524;\n    if (_518)\n    {\n        _524 = c.y >= 0.0f;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    bool _530;\n    if (_524)\n    {\n        _530 = c.y <= 1.0f;\n    }\n    else\n    {\n        _530 = _524;\n    }\n    float2 _532 = c;\n    float2 _537 = clamp(_532, 0.001953125f.xx, 0.998046875f.xx);\n    c = _537;\n    return float3(cell.x + (_537.x * cell.w), cell.y + (_537.y * cell.z), float(_530));\n}\n\nfloat cookie_value(float4 t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125f, 0.715200006961822509765625f, 0.072200000286102294921875f)) * t.w;\n}\n\nfloat cookie_att(int i, float2 d)\n{\n    if (_695_light_cookie[i].w == 0.0f)\n    {\n        return 1.0f;\n    }\n    float4 param = _695_light_cookie[i];\n    float4 param_1 = _695_light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _806 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.SampleLevel(light_smp, _806.xy, 0.0f);\n    return cookie_value(param_3) * _806.z;\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _893 = _695_lit.y > 0.5f;\n    if (_893)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _695_normal_uv.xy) + _695_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _917 = fa_tex_fix(param, param_1);\n        float3 _921 = (_917 * 2.0f) - 1.0f.xxx;\n        float _928 = cos(params.y);\n        float _930 = sin(params.y);\n        n = normalize(float3((float2(_928, _930) * _921.x) + ((float2(-_930, _928) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _921.y), max(_921.z, 0.0500000007450580596923828125f)));\n    }\n    bool _964 = !_893;\n    bool _970;\n    if (_964)\n    {\n        _970 = _695_lit.z > 0.5f;\n    }\n    else\n    {\n        _970 = _964;\n    }\n    float3 _973;\n    if (_970)\n    {\n        _973 = _695_flat_ambient.xyz;\n    }\n    else\n    {\n        _973 = _695_ambient.xyz;\n    }\n    float3 total = _973;\n    if (_695_gi_p.x > 0.0f)\n    {\n        total += gi_irradiance();\n    }\n    bool _998;\n    if (_970)\n    {\n        _998 = _695_lit.z < 1.5f;\n    }\n    else\n    {\n        _998 = _970;\n    }\n    if (_998)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _695_light_map.xy, 0.0f).xyz * _695_light_map.z);\n    }\n    float3 l;\n    float _1125;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1035;\n        if (!_970)\n        {\n            _1035 = float(i) >= _695_lit.x;\n        }\n        else\n        {\n            _1035 = _970;\n        }\n        if (_1035)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_695_light_pos[i].w < 0.0f)\n        {\n            l = _695_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _1061 = _695_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_1061) / max(_695_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _695_light_color[i].w);\n            float3 _1081 = float3(_1061, _695_light_pos[i].z);\n            l = _1081 / max(length(_1081), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_695_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _695_light_shadow_v[i].x;\n                float param_3 = _695_light_shadow_v[i].y;\n                float2 param_4 = -_1061;\n                float param_5 = _695_light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            float2 param_7 = -_1061;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_893)\n        {\n            _1125 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _1125 = 1.0f;\n        }\n        total += (_695_light_color[i].xyz * (att * _1125));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _673 = fa_srgb_to_linear(param);\n        c = _673;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _1375 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _1379 = uv * _1375;\n    float _1385 = _1375.x;\n    float _1387 = _1375.y;\n    float _1389 = clamp(shape_rs.x, 0.0f, min(_1385, _1387));\n    float2 _1400 = (abs(_1379) - _1375) + _1389.xx;\n    float d = (length(max(_1400, 0.0f.xx)) + min(max(_1400.x, _1400.y), 0.0f)) - _1389;\n    float ax = params.y;\n    bool _1421 = params.y > 15.0f;\n    if (_1421)\n    {\n        ax -= 20.0f;\n    }\n    float _1432;\n    if (ax <= (-1.5f))\n    {\n        _1432 = (-2.0f) - ax;\n    }\n    else\n    {\n        _1432 = 0.0f;\n    }\n    if (_1432 > 0.0f)\n    {\n        float _1446 = _1432 * 0.5f;\n        d = abs(d + _1446) - _1446;\n    }\n    float _1454 = fwidth(d);\n    float _1455 = max(_1454, 9.9999997473787516355514526367188e-05f);\n    float _1465 = clamp(0.5f - (d / max(shape_rs.y, _1455)), 0.0f, 1.0f);\n    float _1470;\n    if (shape_rs.y > _1455)\n    {\n        _1470 = (_1465 * _1465) * (3.0f - (2.0f * _1465));\n    }\n    else\n    {\n        _1470 = _1465;\n    }\n    float4 c = color;\n    bool _1492 = (_1432 <= 0.0f) && (ax > (-0.5f));\n    if (_1492)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1507 = cos(ax);\n            float _1509 = sin(ax);\n            g = ((dot(_1379, float2(_1507, _1509)) / max((abs(_1507) * _1385) + (abs(_1509) * _1387), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_1421)\n        {\n            float4 _1552 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _1552;\n            float3 param = _1552.xyz;\n            float param_1 = xform.y;\n            float3 _1559 = fa_tex_fix(param, param_1);\n            float4 _2353 = c;\n            _2353.x = _1559.x;\n            _2353.y = _1559.y;\n            _2353.z = _1559.z;\n            c = _2353;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1571 = scene_rgb(param_2);\n            float4 _1596 = lerp(float4(color.xyz * color.w, color.w), float4(_1571 * color2.w, color2.w), g.xxxx);\n            float _1598 = _1596.w;\n            float3 _1601;\n            if (_1598 > 9.9999997473787516355514526367188e-06f)\n            {\n                _1601 = _1596.xyz / _1598.xxx;\n            }\n            else\n            {\n                _1601 = color.xyz;\n            }\n            c = float4(_1601, _1598);\n        }\n    }\n    float4 _2362 = c;\n    _2362.w = _2362.w * _1470;\n    c = _2362;\n    if (_1492 || (shape_rs.y > 0.0f))\n    {\n        float _1642 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1651 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1651 + (_1642 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1657 = fa_srgb_to_linear(param_4);\n            float4 _2365 = c;\n            _2365.x = _1657.x;\n            _2365.y = _1657.y;\n            _2365.z = _1657.z;\n            c = _2365;\n        }\n        else\n        {\n            float4 _1667 = c;\n            float3 _1670 = _1667.xyz + (_1642 * 0.0039215688593685626983642578125f).xxx;\n            float4 _2372 = _1667;\n            _2372.x = _1670.x;\n            _2372.y = _1670.y;\n            _2372.z = _1670.z;\n            c = _2372;\n        }\n        float4 _2377 = c;\n        _2377.w = clamp(_2377.w + ((_1642 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _2377.w)), 0.0f, 1.0f);\n        c = _2377;\n    }\n    return c;\n}\n\nfloat3 rim_color(float a0, float mode)\n{\n    float2 _1162 = float2(_695_fx_rim_uv.x, 0.0f);\n    float4 _1164 = tex.Sample(smp, uv - _1162);\n    float _1165 = _1164.w;\n    float4 _1175 = tex.Sample(smp, uv + _1162);\n    float _1176 = _1175.w;\n    float2 _1184 = float2(0.0f, _695_fx_rim_uv.y);\n    float4 _1186 = tex.Sample(smp, uv - _1184);\n    float _1187 = _1186.w;\n    float4 _1197 = tex.Sample(smp, uv + _1184);\n    float _1198 = _1197.w;\n    float _1213 = _1165 - _1176;\n    float _1216 = _1198 - _1187;\n    float _1226 = cos(params.y);\n    float _1228 = sin(params.y);\n    float2 _1254 = ((float2(_1226, _1228) * _1213) + ((float2(-_1228, _1226) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _1216)) / max(length(float2(_1213, _1216)), 9.9999997473787516355514526367188e-05f).xx;\n    float3 sum = 0.0f.xxx;\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _695_lit.x)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_695_light_pos[i].w < 0.0f)\n        {\n            to_l = _695_light_pos[i].xy / max(length(_695_light_pos[i].xy), 9.9999997473787516355514526367188e-05f).xx;\n        }\n        else\n        {\n            float2 _1300 = _695_light_pos[i].xy - world_xy;\n            float _1303 = length(_1300);\n            att = pow(clamp(1.0f - (_1303 / max(_695_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _695_light_color[i].w);\n            to_l = _1300 / max(_1303, 9.9999997473787516355514526367188e-05f).xx;\n            if (_695_light_shadow_v[i].x >= 0.0f)\n            {\n                float param = _695_light_shadow_v[i].x;\n                float param_1 = _695_light_shadow_v[i].y;\n                float2 param_2 = -_1300;\n                float param_3 = _695_light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1300;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (_695_light_color[i].xyz * (att * max(dot(_1254, to_l), 0.0f)));\n    }\n    return (sum * _695_fx_rim.xyz) * (a0 * (1.0f - min(min(_1165, _1176), min(_1187, _1198))));\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _701 = gl_FragCoord.xy * _695_fa_target.xy;\n    float _705 = _701.y;\n    return float2(_701.x, lerp(_705, 1.0f - _705, _695_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _743 = base_mode < 0.5f;\n    bool _754;\n    if (!_743)\n    {\n        _754 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _754 = _743;\n    }\n    float _755;\n    if (_754)\n    {\n        _755 = shape_half.x;\n    }\n    else\n    {\n        _755 = 0.0f;\n    }\n    QuadInput _2297 = { uv, color, world_xy, fa_screen_uv(), _695_fa_time.x, base_mode, 0.0f.xxxx, _755 };\n    return _2297;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _679 = scene_rgb(param);\n    return _679;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = _769_tint.xyz;\n    float4 _776 = s.color;\n    float3 _778 = _776.xyz * fa_scene_rgb(param);\n    s.color.x = _778.x;\n    s.color.y = _778.y;\n    s.color.z = _778.z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1697 = params.x > 31.5f;\n    if (_1697)\n    {\n        mode -= 32.0f;\n    }\n    float _1705 = mode;\n    bool _1707 = _1705 > 15.5f;\n    if (_1707)\n    {\n        mode -= 16.0f;\n    }\n    float _1715 = mode;\n    bool _1717 = _1715 > 7.5f;\n    if (_1717)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1707)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1707)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1779 = tex_color(param_5);\n                float4 _1781 = _1779 * color;\n                float4 param_6 = _1781;\n                float param_7 = mode;\n                float _1788 = _1781.w;\n                frag_color = float4(lit_color(param_6, param_7), _1788);\n                if (_695_fx_rim.w > 0.5f)\n                {\n                    float param_8 = _1788;\n                    float param_9 = mode;\n                    float4 _1804 = frag_color;\n                    float3 _1806 = _1804.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1806.x;\n                    frag_color.y = _1806.y;\n                    frag_color.z = _1806.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1836 = length(uv);\n                    float _1839 = fwidth(_1836);\n                    float _1840 = max(_1839, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1836) / _1840) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1836) / _1840) + 0.5f, 0.0f, 1.0f) * clamp(((_1836 - params.y) / _1840) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1880 = clamp(1.0f - _1836, 0.0f, 1.0f);\n                            cov = (_1880 * _1880) * (3.0f - (2.0f * _1880));\n                        }\n                    }\n                    float3 _1889;\n                    if (_1707)\n                    {\n                        float4 param_10 = color;\n                        float param_11 = 5.0f;\n                        _1889 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1889 = color.xyz;\n                    }\n                    frag_color = float4(_1889, color.w * cov);\n                }\n            }\n        }\n    }\n    if (_695_fx_emit.w > 0.5f)\n    {\n        float3 e = _695_fx_emit.xyz;\n        if (_695_fx_emit.w > 1.5f)\n        {\n            float3 param_12 = fx_emissive_tex.Sample(smp, (uv * _695_fx_emit_uv.xy) + _695_fx_emit_uv.zw).xyz;\n            float param_13 = _695_fx_emit.w - 2.0f;\n            float3 _1944 = fa_tex_fix(param_12, param_13);\n            e *= _1944;\n        }\n        float4 _1948 = frag_color;\n        float3 _1950 = _1948.xyz + e;\n        frag_color.x = _1950.x;\n        frag_color.y = _1950.y;\n        frag_color.z = _1950.z;\n    }\n    float param_14 = mode;\n    float4 _2277 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface _2279 = { _2277 };\n    QuadSurface param_16 = _2279;\n    fragment(param_15, param_16);\n    _2277 = param_16.color;\n    frag_color = param_16.color;\n    if (_1697)\n    {\n        float4 _1976 = frag_color;\n        float3 param_17 = color2.xyz;\n        float3 _1981 = scene_rgb(param_17);\n        float3 _1985 = lerp(_1976.xyz, _1981, color2.w.xxx);\n        frag_color.x = _1985.x;\n        frag_color.y = _1985.y;\n        frag_color.z = _1985.z;\n    }\n    if (_1717)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _2009 = _695_fog_col.w > 0.0f;\n    bool _2017;\n    if (!_2009)\n    {\n        _2017 = _695_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2017 = _2009;\n    }\n    if (_2017)\n    {\n        float3 _2031 = float3(world_xy, world_z) - _695_fog_eye.xyz;\n        float _2038 = dot(_2031, _695_fog_c.xyz);\n        bool _2042 = _695_fog_c.w > 0.5f;\n        float _2043;\n        if (_2042)\n        {\n            _2043 = _2038;\n        }\n        else\n        {\n            _2043 = length(_2031);\n        }\n        float _2055 = _2043 - _695_fog_b.x;\n        if (_2055 > 0.0f)\n        {\n            float _2064 = _695_fog_col.w * _2055;\n            float tau = _2064 * _2064;\n            if (_695_fog_b.y > 0.0f)\n            {\n                float _2080;\n                if (_2042)\n                {\n                    _2080 = world_xy.y - (_695_fog_c.y * _2038);\n                }\n                else\n                {\n                    _2080 = _695_fog_eye.y;\n                }\n                float _2101 = lerp(_2080, world_xy.y, clamp(_695_fog_b.x / _2043, 0.0f, 1.0f));\n                float _2105 = world_xy.y - _2101;\n                float _2110 = _2101 - _695_fog_b.z;\n                float _2115 = world_xy.y - _695_fog_b.z;\n                bool _2118 = _2110 <= 0.0f;\n                bool _2119 = !_2118;\n                bool _2125;\n                if (_2119)\n                {\n                    _2125 = _695_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2125 = _2118;\n                }\n                float _2126;\n                if (_2125)\n                {\n                    _2126 = _695_fog_b.y;\n                }\n                else\n                {\n                    _2126 = _695_fog_b.y * exp(-min(_695_fog_b.w * _2110, 80.0f));\n                }\n                bool _2153;\n                if (_2119)\n                {\n                    _2153 = _695_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2153 = _2118;\n                }\n                float _2154;\n                if (_2153)\n                {\n                    _2154 = _695_fog_b.y * _2110;\n                }\n                else\n                {\n                    _2154 = (_695_fog_b.y * (1.0f - exp(-min(_695_fog_b.w * _2110, 80.0f)))) / _695_fog_b.w;\n                }\n                bool _2179 = _2115 <= 0.0f;\n                bool _2186;\n                if (!_2179)\n                {\n                    _2186 = _695_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2186 = _2179;\n                }\n                float _2187;\n                if (_2186)\n                {\n                    _2187 = _695_fog_b.y * _2115;\n                }\n                else\n                {\n                    _2187 = (_695_fog_b.y * (1.0f - exp(-min(_695_fog_b.w * _2115, 80.0f)))) / _695_fog_b.w;\n                }\n                float _2214;\n                if (abs(_2105) < 0.001000000047497451305389404296875f)\n                {\n                    _2214 = _2126;\n                }\n                else\n                {\n                    _2214 = (_2187 - _2154) / _2105;\n                }\n                tau += (_2055 * max(_2214, 0.0f));\n            }\n            float4 _2237 = frag_color;\n            float3 _2245 = lerp(_2237.xyz, _695_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _2245.x;\n            frag_color.y = _2245.y;\n            frag_color.z = _2245.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_695",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_769",
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
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _155_lit : packoffset(c0);\n    float4 _155_ambient : packoffset(c1);\n    float4 _155_normal_uv : packoffset(c2);\n    float4 _155_flat_ambient : packoffset(c3);\n    float4 _155_light_map : packoffset(c4);\n    float4 _155_light_pos[16] : packoffset(c5);\n    float4 _155_light_color[16] : packoffset(c21);\n    float4 _155_light_shadow_v[16] : packoffset(c37);\n    float4 _155_fog_col : packoffset(c53);\n    float4 _155_fog_b : packoffset(c54);\n    float4 _155_fog_c : packoffset(c55);\n    float4 _155_fog_eye : packoffset(c56);\n    float4 _155_fa_time : packoffset(c57);\n    float4 _155_fa_target : packoffset(c58);\n    float4 _155_fx_emit : packoffset(c59);\n    float4 _155_fx_emit_uv : packoffset(c60);\n    float4 _155_fx_rim : packoffset(c61);\n    float4 _155_fx_rim_uv : packoffset(c62);\n    float4 _155_light_cookie[16] : packoffset(c63);\n    float4 _155_light_cookie_xf[16] : packoffset(c79);\n    float4 _155_gi_xf : packoffset(c95);\n    float4 _155_gi_p : packoffset(c96);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _237_tint : packoffset(c0);\n};\n\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 frag_color;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _107 = fa_linear_to_srgb(param);\n        c = _107;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _116 = fa_srgb_to_linear(param_1);\n            c = _116;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _162 = gl_FragCoord.xy * _155_fa_target.xy;\n    float _167 = _162.y;\n    return float2(_162.x, lerp(_167, 1.0f - _167, _155_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _211 = base_mode < 0.5f;\n    bool _222;\n    if (!_211)\n    {\n        _222 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _222 = _211;\n    }\n    float _223;\n    if (_222)\n    {\n        _223 = shape_half.x;\n    }\n    else\n    {\n        _223 = 0.0f;\n    }\n    QuadInput _348 = { uv, color, world_xy, fa_screen_uv(), _155_fa_time.x, base_mode, 0.0f.xxxx, _223 };\n    return _348;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _132 = fa_srgb_to_linear(param);\n        c = _132;\n    }\n    return c;\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _138 = scene_rgb(param);\n    return _138;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = _237_tint.xyz;\n    float4 _244 = s.color;\n    float3 _246 = _244.xyz * fa_scene_rgb(param);\n    s.color.x = _246.x;\n    s.color.y = _246.y;\n    s.color.z = _246.z;\n}\n\nvoid frag_main()\n{\n    float4 _265 = tex.Sample(smp, uv);\n    float3 param = _265.xyz;\n    float param_1 = xform.y;\n    float3 _274 = fa_tex_fix(param, param_1);\n    frag_color = float4(_274, _265.w) * color;\n    float param_2 = 0.0f;\n    float4 _328 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _330 = { _328 };\n    QuadSurface param_4 = _330;\n    fragment(param_3, param_4);\n    _328 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
