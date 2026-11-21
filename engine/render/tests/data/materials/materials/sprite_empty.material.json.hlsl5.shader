{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "c463ccd1917be78236231aa4aa6bc7a9036af5c2e4c419a950fb6e8c51e433a6",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _144 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _144;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _687_lit : packoffset(c0);\n    float4 _687_ambient : packoffset(c1);\n    float4 _687_normal_uv : packoffset(c2);\n    float4 _687_flat_ambient : packoffset(c3);\n    float4 _687_light_map : packoffset(c4);\n    float4 _687_light_pos[16] : packoffset(c5);\n    float4 _687_light_color[16] : packoffset(c21);\n    float4 _687_light_shadow_v[16] : packoffset(c37);\n    float4 _687_fog_col : packoffset(c53);\n    float4 _687_fog_b : packoffset(c54);\n    float4 _687_fog_c : packoffset(c55);\n    float4 _687_fog_eye : packoffset(c56);\n    float4 _687_fa_time : packoffset(c57);\n    float4 _687_fa_target : packoffset(c58);\n    float4 _687_fx_emit : packoffset(c59);\n    float4 _687_fx_emit_uv : packoffset(c60);\n    float4 _687_fx_rim : packoffset(c61);\n    float4 _687_fx_rim_uv : packoffset(c62);\n    float4 _687_light_cookie[16] : packoffset(c63);\n    float4 _687_light_cookie_xf[16] : packoffset(c79);\n    float4 _687_gi_xf : packoffset(c95);\n    float4 _687_gi_p : packoffset(c96);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> fx_cookie_tex : register(t5);\nSamplerState light_smp : register(s1);\nTexture2D<float4> fx_gi_tex : register(t6);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nTexture2D<float4> fx_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _625 = fa_linear_to_srgb(param);\n        c = _625;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _633 = fa_srgb_to_linear(param_1);\n            c = _633;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _644 = tex.Sample(smp, p);\n    float3 param = _644.xyz;\n    float param_1 = xform.y;\n    float3 _654 = fa_tex_fix(param, param_1);\n    return float4(_654, _644.w);\n}\n\nfloat3 gi_irradiance()\n{\n    float2 _806 = (world_xy * _687_gi_xf.xy) + _687_gi_xf.zw;\n    float4 _813 = fx_gi_tex.SampleLevel(light_smp, _806, 0.0f);\n    float _817 = _806.x;\n    bool _818 = _817 >= 0.0f;\n    bool _824;\n    if (_818)\n    {\n        _824 = _806.y >= 0.0f;\n    }\n    else\n    {\n        _824 = _818;\n    }\n    bool _830;\n    if (_824)\n    {\n        _830 = _817 <= 1.0f;\n    }\n    else\n    {\n        _830 = _824;\n    }\n    bool _836;\n    if (_830)\n    {\n        _836 = _806.y <= 1.0f;\n    }\n    else\n    {\n        _836 = _830;\n    }\n    bool _844;\n    if (_836)\n    {\n        _844 = _813.w > 0.0199999995529651641845703125f;\n    }\n    else\n    {\n        _844 = _836;\n    }\n    float3 _845;\n    if (_844)\n    {\n        _845 = (_813.xyz / _813.w.xxx) * _687_gi_p.x;\n    }\n    else\n    {\n        _845 = 0.0f.xxx;\n    }\n    return _845;\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _134 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_134.x * 255.0f) + 0.5f) * 256.0f) + floor((_134.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _237 = floor(tt);\n    float _247 = _237 - (1024.0f * floor(_237 * 0.0009765625f));\n    float _250 = _247 + 1.0f;\n    float i1 = _250;\n    if (_250 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _247;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5f, 0.0f, 1.0f), tt - _237);\n}\n\nfloat light_shadow_soft(float v, float size, float2 d, float radius)\n{\n    float _287 = length(d);\n    float result = 1.0f;\n    if (_287 >= 9.9999997473787516355514526367188e-05f)\n    {\n        float _298 = atan2(d.y, d.x);\n        float a = _298;\n        float _301;\n        if (_298 < 0.0f)\n        {\n            _301 = a + 6.283185482025146484375f;\n        }\n        else\n        {\n            _301 = a;\n        }\n        a = _301;\n        float _311 = _301 * 162.9746551513671875f;\n        float _320 = min((size * 10.0f) / _287, 0.699999988079071044921875f) * 162.9746551513671875f;\n        float sum = 0.0f;\n        float n = 0.0f;\n        for (int k = 0; k < 12; k++)\n        {\n            float _346 = floor(_311 + ((((float(k) + 0.5f) * 0.16666667163372039794921875f) - 1.0f) * _320));\n            float param = v;\n            float param_1 = _346 - (1024.0f * floor(_346 * 0.0009765625f));\n            float _360 = shadow_texel(param, param_1) * radius;\n            if (_360 < _287)\n            {\n                sum += _360;\n                n += 1.0f;\n            }\n        }\n        if (n > 0.5f)\n        {\n            float _392 = min(size * ((1.0f / max(sum / n, 1.0f)) - (1.0f / _287)), 0.699999988079071044921875f) * 162.9746551513671875f;\n            float acc = 0.0f;\n            float wsum = 0.0f;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _410 = ((float(k_1) + 0.5f) * 0.125f) - 1.0f;\n                float _416 = 1.0f - (0.800000011920928955078125f * abs(_410));\n                float param_2 = v;\n                float param_3 = _311 + (_410 * _392);\n                float param_4 = _287;\n                float param_5 = radius;\n                acc += (_416 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _416;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _158 = length(d);\n    if (_158 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _172 = atan2(d.y, d.x);\n    float a = _172;\n    float _175;\n    if (_172 < 0.0f)\n    {\n        _175 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _175 = a;\n    }\n    a = _175;\n    float _187 = _175 * 162.9746551513671875f;\n    float _192 = min(floor(_187), 1023.0f);\n    float _199 = _192 + 1.0f;\n    float i1 = _199;\n    if (_199 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _192;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _158) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _158) + 0.5f, 0.0f, 1.0f), _187 - _192);\n}\n\nfloat light_shadow_sized(float v, float size, float2 d, float radius)\n{\n    float r = 1.0f;\n    if (size > 0.0f)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nfloat3 cookie_coord(float4 cell, float4 xf, float2 off)\n{\n    float2 _497 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _501 = _497.x + 0.5f;\n    float2 c = float2(_501, 0.5f - _497.y);\n    bool _509 = _501 >= 0.0f;\n    bool _515;\n    if (_509)\n    {\n        _515 = c.x <= 1.0f;\n    }\n    else\n    {\n        _515 = _509;\n    }\n    bool _521;\n    if (_515)\n    {\n        _521 = c.y >= 0.0f;\n    }\n    else\n    {\n        _521 = _515;\n    }\n    bool _527;\n    if (_521)\n    {\n        _527 = c.y <= 1.0f;\n    }\n    else\n    {\n        _527 = _521;\n    }\n    float2 _529 = c;\n    float2 _534 = clamp(_529, 0.001953125f.xx, 0.998046875f.xx);\n    c = _534;\n    return float3(cell.x + (_534.x * cell.w), cell.y + (_534.y * cell.z), float(_527));\n}\n\nfloat cookie_value(float4 t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125f, 0.715200006961822509765625f, 0.072200000286102294921875f)) * t.w;\n}\n\nfloat cookie_att(int i, float2 d)\n{\n    if (_687_light_cookie[i].w == 0.0f)\n    {\n        return 1.0f;\n    }\n    float4 param = _687_light_cookie[i];\n    float4 param_1 = _687_light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _780 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.SampleLevel(light_smp, _780.xy, 0.0f);\n    return cookie_value(param_3) * _780.z;\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _867 = _687_lit.y > 0.5f;\n    if (_867)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _687_normal_uv.xy) + _687_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _891 = fa_tex_fix(param, param_1);\n        float3 _895 = (_891 * 2.0f) - 1.0f.xxx;\n        float _902 = cos(params.y);\n        float _904 = sin(params.y);\n        n = normalize(float3((float2(_902, _904) * _895.x) + ((float2(-_904, _902) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _895.y), max(_895.z, 0.0500000007450580596923828125f)));\n    }\n    bool _938 = !_867;\n    bool _944;\n    if (_938)\n    {\n        _944 = _687_lit.z > 0.5f;\n    }\n    else\n    {\n        _944 = _938;\n    }\n    float3 _947;\n    if (_944)\n    {\n        _947 = _687_flat_ambient.xyz;\n    }\n    else\n    {\n        _947 = _687_ambient.xyz;\n    }\n    float3 total = _947;\n    if (_687_gi_p.x > 0.0f)\n    {\n        total += gi_irradiance();\n    }\n    bool _972;\n    if (_944)\n    {\n        _972 = _687_lit.z < 1.5f;\n    }\n    else\n    {\n        _972 = _944;\n    }\n    if (_972)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _687_light_map.xy, 0.0f).xyz * _687_light_map.z);\n    }\n    float3 l;\n    float _1099;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1009;\n        if (!_944)\n        {\n            _1009 = float(i) >= _687_lit.x;\n        }\n        else\n        {\n            _1009 = _944;\n        }\n        if (_1009)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_687_light_pos[i].w < 0.0f)\n        {\n            l = _687_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _1035 = _687_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_1035) / max(_687_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _687_light_color[i].w);\n            float3 _1055 = float3(_1035, _687_light_pos[i].z);\n            l = _1055 / max(length(_1055), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_687_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _687_light_shadow_v[i].x;\n                float param_3 = _687_light_shadow_v[i].y;\n                float2 param_4 = -_1035;\n                float param_5 = _687_light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            float2 param_7 = -_1035;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_867)\n        {\n            _1099 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _1099 = 1.0f;\n        }\n        total += (_687_light_color[i].xyz * (att * _1099));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _670 = fa_srgb_to_linear(param);\n        c = _670;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _1349 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _1353 = uv * _1349;\n    float _1359 = _1349.x;\n    float _1361 = _1349.y;\n    float _1363 = clamp(shape_rs.x, 0.0f, min(_1359, _1361));\n    float2 _1374 = (abs(_1353) - _1349) + _1363.xx;\n    float d = (length(max(_1374, 0.0f.xx)) + min(max(_1374.x, _1374.y), 0.0f)) - _1363;\n    float ax = params.y;\n    bool _1395 = params.y > 15.0f;\n    if (_1395)\n    {\n        ax -= 20.0f;\n    }\n    float _1406;\n    if (ax <= (-1.5f))\n    {\n        _1406 = (-2.0f) - ax;\n    }\n    else\n    {\n        _1406 = 0.0f;\n    }\n    if (_1406 > 0.0f)\n    {\n        float _1420 = _1406 * 0.5f;\n        d = abs(d + _1420) - _1420;\n    }\n    float _1428 = fwidth(d);\n    float _1429 = max(_1428, 9.9999997473787516355514526367188e-05f);\n    float _1439 = clamp(0.5f - (d / max(shape_rs.y, _1429)), 0.0f, 1.0f);\n    float _1444;\n    if (shape_rs.y > _1429)\n    {\n        _1444 = (_1439 * _1439) * (3.0f - (2.0f * _1439));\n    }\n    else\n    {\n        _1444 = _1439;\n    }\n    float4 c = color;\n    bool _1466 = (_1406 <= 0.0f) && (ax > (-0.5f));\n    if (_1466)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1481 = cos(ax);\n            float _1483 = sin(ax);\n            g = ((dot(_1353, float2(_1481, _1483)) / max((abs(_1481) * _1359) + (abs(_1483) * _1361), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_1395)\n        {\n            float4 _1526 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _1526;\n            float3 param = _1526.xyz;\n            float param_1 = xform.y;\n            float3 _1533 = fa_tex_fix(param, param_1);\n            float4 _2327 = c;\n            _2327.x = _1533.x;\n            _2327.y = _1533.y;\n            _2327.z = _1533.z;\n            c = _2327;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1545 = scene_rgb(param_2);\n            float4 _1570 = lerp(float4(color.xyz * color.w, color.w), float4(_1545 * color2.w, color2.w), g.xxxx);\n            float _1572 = _1570.w;\n            float3 _1575;\n            if (_1572 > 9.9999997473787516355514526367188e-06f)\n            {\n                _1575 = _1570.xyz / _1572.xxx;\n            }\n            else\n            {\n                _1575 = color.xyz;\n            }\n            c = float4(_1575, _1572);\n        }\n    }\n    float4 _2336 = c;\n    _2336.w = _2336.w * _1444;\n    c = _2336;\n    if (_1466 || (shape_rs.y > 0.0f))\n    {\n        float _1616 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1625 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1625 + (_1616 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1631 = fa_srgb_to_linear(param_4);\n            float4 _2339 = c;\n            _2339.x = _1631.x;\n            _2339.y = _1631.y;\n            _2339.z = _1631.z;\n            c = _2339;\n        }\n        else\n        {\n            float4 _1641 = c;\n            float3 _1644 = _1641.xyz + (_1616 * 0.0039215688593685626983642578125f).xxx;\n            float4 _2346 = _1641;\n            _2346.x = _1644.x;\n            _2346.y = _1644.y;\n            _2346.z = _1644.z;\n            c = _2346;\n        }\n        float4 _2351 = c;\n        _2351.w = clamp(_2351.w + ((_1616 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _2351.w)), 0.0f, 1.0f);\n        c = _2351;\n    }\n    return c;\n}\n\nfloat3 rim_color(float a0, float mode)\n{\n    float2 _1136 = float2(_687_fx_rim_uv.x, 0.0f);\n    float4 _1138 = tex.Sample(smp, uv - _1136);\n    float _1139 = _1138.w;\n    float4 _1149 = tex.Sample(smp, uv + _1136);\n    float _1150 = _1149.w;\n    float2 _1158 = float2(0.0f, _687_fx_rim_uv.y);\n    float4 _1160 = tex.Sample(smp, uv - _1158);\n    float _1161 = _1160.w;\n    float4 _1171 = tex.Sample(smp, uv + _1158);\n    float _1172 = _1171.w;\n    float _1187 = _1139 - _1150;\n    float _1190 = _1172 - _1161;\n    float _1200 = cos(params.y);\n    float _1202 = sin(params.y);\n    float2 _1228 = ((float2(_1200, _1202) * _1187) + ((float2(-_1202, _1200) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _1190)) / max(length(float2(_1187, _1190)), 9.9999997473787516355514526367188e-05f).xx;\n    float3 sum = 0.0f.xxx;\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _687_lit.x)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_687_light_pos[i].w < 0.0f)\n        {\n            to_l = _687_light_pos[i].xy / max(length(_687_light_pos[i].xy), 9.9999997473787516355514526367188e-05f).xx;\n        }\n        else\n        {\n            float2 _1274 = _687_light_pos[i].xy - world_xy;\n            float _1277 = length(_1274);\n            att = pow(clamp(1.0f - (_1277 / max(_687_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _687_light_color[i].w);\n            to_l = _1274 / max(_1277, 9.9999997473787516355514526367188e-05f).xx;\n            if (_687_light_shadow_v[i].x >= 0.0f)\n            {\n                float param = _687_light_shadow_v[i].x;\n                float param_1 = _687_light_shadow_v[i].y;\n                float2 param_2 = -_1274;\n                float param_3 = _687_light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1274;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (_687_light_color[i].xyz * (att * max(dot(_1228, to_l), 0.0f)));\n    }\n    return (sum * _687_fx_rim.xyz) * (a0 * (1.0f - min(min(_1139, _1150), min(_1161, _1172))));\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _693 = gl_FragCoord.xy * _687_fa_target.xy;\n    float _697 = _693.y;\n    return float2(_693.x, lerp(_697, 1.0f - _697, _687_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _735 = base_mode < 0.5f;\n    bool _746;\n    if (!_735)\n    {\n        _746 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _746 = _735;\n    }\n    float _747;\n    if (_746)\n    {\n        _747 = shape_half.x;\n    }\n    else\n    {\n        _747 = 0.0f;\n    }\n    QuadInput _2271 = { uv, color, world_xy, fa_screen_uv(), _687_fa_time.x, base_mode, 0.0f.xxxx, _747 };\n    return _2271;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, QuadSurface s)\n{\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1671 = params.x > 31.5f;\n    if (_1671)\n    {\n        mode -= 32.0f;\n    }\n    float _1679 = mode;\n    bool _1681 = _1679 > 15.5f;\n    if (_1681)\n    {\n        mode -= 16.0f;\n    }\n    float _1689 = mode;\n    bool _1691 = _1689 > 7.5f;\n    if (_1691)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1681)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1681)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1753 = tex_color(param_5);\n                float4 _1755 = _1753 * color;\n                float4 param_6 = _1755;\n                float param_7 = mode;\n                float _1762 = _1755.w;\n                frag_color = float4(lit_color(param_6, param_7), _1762);\n                if (_687_fx_rim.w > 0.5f)\n                {\n                    float param_8 = _1762;\n                    float param_9 = mode;\n                    float4 _1778 = frag_color;\n                    float3 _1780 = _1778.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1780.x;\n                    frag_color.y = _1780.y;\n                    frag_color.z = _1780.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1810 = length(uv);\n                    float _1813 = fwidth(_1810);\n                    float _1814 = max(_1813, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1810) / _1814) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1810) / _1814) + 0.5f, 0.0f, 1.0f) * clamp(((_1810 - params.y) / _1814) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1854 = clamp(1.0f - _1810, 0.0f, 1.0f);\n                            cov = (_1854 * _1854) * (3.0f - (2.0f * _1854));\n                        }\n                    }\n                    float3 _1863;\n                    if (_1681)\n                    {\n                        float4 param_10 = color;\n                        float param_11 = 5.0f;\n                        _1863 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1863 = color.xyz;\n                    }\n                    frag_color = float4(_1863, color.w * cov);\n                }\n            }\n        }\n    }\n    if (_687_fx_emit.w > 0.5f)\n    {\n        float3 e = _687_fx_emit.xyz;\n        if (_687_fx_emit.w > 1.5f)\n        {\n            float3 param_12 = fx_emissive_tex.Sample(smp, (uv * _687_fx_emit_uv.xy) + _687_fx_emit_uv.zw).xyz;\n            float param_13 = _687_fx_emit.w - 2.0f;\n            float3 _1918 = fa_tex_fix(param_12, param_13);\n            e *= _1918;\n        }\n        float4 _1922 = frag_color;\n        float3 _1924 = _1922.xyz + e;\n        frag_color.x = _1924.x;\n        frag_color.y = _1924.y;\n        frag_color.z = _1924.z;\n    }\n    float param_14 = mode;\n    float4 _2251 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface _2253 = { _2251 };\n    QuadSurface param_16 = _2253;\n    fragment(param_15, param_16);\n    _2251 = param_16.color;\n    frag_color = param_16.color;\n    if (_1671)\n    {\n        float4 _1950 = frag_color;\n        float3 param_17 = color2.xyz;\n        float3 _1955 = scene_rgb(param_17);\n        float3 _1959 = lerp(_1950.xyz, _1955, color2.w.xxx);\n        frag_color.x = _1959.x;\n        frag_color.y = _1959.y;\n        frag_color.z = _1959.z;\n    }\n    if (_1691)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1983 = _687_fog_col.w > 0.0f;\n    bool _1991;\n    if (!_1983)\n    {\n        _1991 = _687_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1991 = _1983;\n    }\n    if (_1991)\n    {\n        float3 _2005 = float3(world_xy, world_z) - _687_fog_eye.xyz;\n        float _2012 = dot(_2005, _687_fog_c.xyz);\n        bool _2016 = _687_fog_c.w > 0.5f;\n        float _2017;\n        if (_2016)\n        {\n            _2017 = _2012;\n        }\n        else\n        {\n            _2017 = length(_2005);\n        }\n        float _2029 = _2017 - _687_fog_b.x;\n        if (_2029 > 0.0f)\n        {\n            float _2038 = _687_fog_col.w * _2029;\n            float tau = _2038 * _2038;\n            if (_687_fog_b.y > 0.0f)\n            {\n                float _2054;\n                if (_2016)\n                {\n                    _2054 = world_xy.y - (_687_fog_c.y * _2012);\n                }\n                else\n                {\n                    _2054 = _687_fog_eye.y;\n                }\n                float _2075 = lerp(_2054, world_xy.y, clamp(_687_fog_b.x / _2017, 0.0f, 1.0f));\n                float _2079 = world_xy.y - _2075;\n                float _2084 = _2075 - _687_fog_b.z;\n                float _2089 = world_xy.y - _687_fog_b.z;\n                bool _2092 = _2084 <= 0.0f;\n                bool _2093 = !_2092;\n                bool _2099;\n                if (_2093)\n                {\n                    _2099 = _687_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2099 = _2092;\n                }\n                float _2100;\n                if (_2099)\n                {\n                    _2100 = _687_fog_b.y;\n                }\n                else\n                {\n                    _2100 = _687_fog_b.y * exp(-min(_687_fog_b.w * _2084, 80.0f));\n                }\n                bool _2127;\n                if (_2093)\n                {\n                    _2127 = _687_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2127 = _2092;\n                }\n                float _2128;\n                if (_2127)\n                {\n                    _2128 = _687_fog_b.y * _2084;\n                }\n                else\n                {\n                    _2128 = (_687_fog_b.y * (1.0f - exp(-min(_687_fog_b.w * _2084, 80.0f)))) / _687_fog_b.w;\n                }\n                bool _2153 = _2089 <= 0.0f;\n                bool _2160;\n                if (!_2153)\n                {\n                    _2160 = _687_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2160 = _2153;\n                }\n                float _2161;\n                if (_2160)\n                {\n                    _2161 = _687_fog_b.y * _2089;\n                }\n                else\n                {\n                    _2161 = (_687_fog_b.y * (1.0f - exp(-min(_687_fog_b.w * _2089, 80.0f)))) / _687_fog_b.w;\n                }\n                float _2188;\n                if (abs(_2079) < 0.001000000047497451305389404296875f)\n                {\n                    _2188 = _2100;\n                }\n                else\n                {\n                    _2188 = (_2161 - _2128) / _2079;\n                }\n                tau += (_2029 * max(_2188, 0.0f));\n            }\n            float4 _2211 = frag_color;\n            float3 _2219 = lerp(_2211.xyz, _687_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _2219.x;\n            frag_color.y = _2219.y;\n            frag_color.z = _2219.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _129_lit : packoffset(c0);\n    float4 _129_ambient : packoffset(c1);\n    float4 _129_normal_uv : packoffset(c2);\n    float4 _129_flat_ambient : packoffset(c3);\n    float4 _129_light_map : packoffset(c4);\n    float4 _129_light_pos[16] : packoffset(c5);\n    float4 _129_light_color[16] : packoffset(c21);\n    float4 _129_light_shadow_v[16] : packoffset(c37);\n    float4 _129_fog_col : packoffset(c53);\n    float4 _129_fog_b : packoffset(c54);\n    float4 _129_fog_c : packoffset(c55);\n    float4 _129_fog_eye : packoffset(c56);\n    float4 _129_fa_time : packoffset(c57);\n    float4 _129_fa_target : packoffset(c58);\n    float4 _129_fx_emit : packoffset(c59);\n    float4 _129_fx_emit_uv : packoffset(c60);\n    float4 _129_fx_rim : packoffset(c61);\n    float4 _129_fx_rim_uv : packoffset(c62);\n    float4 _129_light_cookie[16] : packoffset(c63);\n    float4 _129_light_cookie_xf[16] : packoffset(c79);\n    float4 _129_gi_xf : packoffset(c95);\n    float4 _129_gi_p : packoffset(c96);\n};\n\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 frag_color;\nstatic float3 xform;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _136 = gl_FragCoord.xy * _129_fa_target.xy;\n    float _142 = _136.y;\n    return float2(_136.x, lerp(_142, 1.0f - _142, _129_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _186 = base_mode < 0.5f;\n    bool _197;\n    if (!_186)\n    {\n        _197 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _197 = _186;\n    }\n    float _198;\n    if (_197)\n    {\n        _198 = shape_half.x;\n    }\n    else\n    {\n        _198 = 0.0f;\n    }\n    QuadInput _308 = { uv, color, world_xy, fa_screen_uv(), _129_fa_time.x, base_mode, 0.0f.xxxx, _198 };\n    return _308;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, QuadSurface s)\n{\n}\n\nvoid frag_main()\n{\n    float4 _223 = tex.Sample(smp, uv);\n    float3 param = _223.xyz;\n    float param_1 = xform.y;\n    float3 _234 = fa_tex_fix(param, param_1);\n    frag_color = float4(_234, _223.w) * color;\n    float param_2 = 0.0f;\n    float4 _288 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _290 = { _288 };\n    QuadSurface param_4 = _290;\n    fragment(param_3, param_4);\n    _288 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    xform = stage_input.xform;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
