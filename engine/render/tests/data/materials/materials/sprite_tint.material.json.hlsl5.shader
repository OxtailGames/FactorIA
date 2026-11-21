{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "8dda08c124964ccb7d15a0a3238fb4669d4ca9ef375995bc9768b79891bfc837",
  "slang": "hlsl5",
  "params": [
    "tint"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _147 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _147;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _693_lit : packoffset(c0);\n    float4 _693_ambient : packoffset(c1);\n    float4 _693_normal_uv : packoffset(c2);\n    float4 _693_flat_ambient : packoffset(c3);\n    float4 _693_light_map : packoffset(c4);\n    float4 _693_light_pos[16] : packoffset(c5);\n    float4 _693_light_color[16] : packoffset(c21);\n    float4 _693_light_shadow_v[16] : packoffset(c37);\n    float4 _693_fog_col : packoffset(c53);\n    float4 _693_fog_b : packoffset(c54);\n    float4 _693_fog_c : packoffset(c55);\n    float4 _693_fog_eye : packoffset(c56);\n    float4 _693_fa_time : packoffset(c57);\n    float4 _693_fa_target : packoffset(c58);\n    float4 _693_fx_emit : packoffset(c59);\n    float4 _693_fx_emit_uv : packoffset(c60);\n    float4 _693_fx_rim : packoffset(c61);\n    float4 _693_fx_rim_uv : packoffset(c62);\n    float4 _693_light_cookie[16] : packoffset(c63);\n    float4 _693_light_cookie_xf[16] : packoffset(c79);\n    float4 _693_fa_scene : packoffset(c95);\n    float4 _693_fa_world_uv[3] : packoffset(c96);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _767_tint : packoffset(c0);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> fx_cookie_tex : register(t5);\nSamplerState light_smp : register(s1);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nTexture2D<float4> fx_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _625 = fa_linear_to_srgb(param);\n        c = _625;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _633 = fa_srgb_to_linear(param_1);\n            c = _633;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _644 = tex.Sample(smp, p);\n    float3 param = _644.xyz;\n    float param_1 = xform.y;\n    float3 _654 = fa_tex_fix(param, param_1);\n    return float4(_654, _644.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _134 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_134.x * 255.0f) + 0.5f) * 256.0f) + floor((_134.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _237 = floor(tt);\n    float _247 = _237 - (1024.0f * floor(_237 * 0.0009765625f));\n    float _250 = _247 + 1.0f;\n    float i1 = _250;\n    if (_250 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _247;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5f, 0.0f, 1.0f), tt - _237);\n}\n\nfloat light_shadow_soft(float v, float size, float2 d, float radius)\n{\n    float _287 = length(d);\n    float result = 1.0f;\n    if (_287 >= 9.9999997473787516355514526367188e-05f)\n    {\n        float _298 = atan2(d.y, d.x);\n        float a = _298;\n        float _301;\n        if (_298 < 0.0f)\n        {\n            _301 = a + 6.283185482025146484375f;\n        }\n        else\n        {\n            _301 = a;\n        }\n        a = _301;\n        float _311 = _301 * 162.9746551513671875f;\n        float _320 = min((size * 10.0f) / _287, 0.699999988079071044921875f) * 162.9746551513671875f;\n        float sum = 0.0f;\n        float n = 0.0f;\n        for (int k = 0; k < 12; k++)\n        {\n            float _346 = floor(_311 + ((((float(k) + 0.5f) * 0.16666667163372039794921875f) - 1.0f) * _320));\n            float param = v;\n            float param_1 = _346 - (1024.0f * floor(_346 * 0.0009765625f));\n            float _360 = shadow_texel(param, param_1) * radius;\n            if (_360 < _287)\n            {\n                sum += _360;\n                n += 1.0f;\n            }\n        }\n        if (n > 0.5f)\n        {\n            float _392 = min(size * ((1.0f / max(sum / n, 1.0f)) - (1.0f / _287)), 0.699999988079071044921875f) * 162.9746551513671875f;\n            float acc = 0.0f;\n            float wsum = 0.0f;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _410 = ((float(k_1) + 0.5f) * 0.125f) - 1.0f;\n                float _416 = 1.0f - (0.800000011920928955078125f * abs(_410));\n                float param_2 = v;\n                float param_3 = _311 + (_410 * _392);\n                float param_4 = _287;\n                float param_5 = radius;\n                acc += (_416 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _416;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _158 = length(d);\n    if (_158 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _172 = atan2(d.y, d.x);\n    float a = _172;\n    float _175;\n    if (_172 < 0.0f)\n    {\n        _175 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _175 = a;\n    }\n    a = _175;\n    float _187 = _175 * 162.9746551513671875f;\n    float _192 = min(floor(_187), 1023.0f);\n    float _199 = _192 + 1.0f;\n    float i1 = _199;\n    if (_199 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _192;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _158) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _158) + 0.5f, 0.0f, 1.0f), _187 - _192);\n}\n\nfloat light_shadow_sized(float v, float size, float2 d, float radius)\n{\n    float r = 1.0f;\n    if (size > 0.0f)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nfloat3 cookie_coord(float4 cell, float4 xf, float2 off)\n{\n    float2 _497 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _501 = _497.x + 0.5f;\n    float2 c = float2(_501, 0.5f - _497.y);\n    bool _509 = _501 >= 0.0f;\n    bool _515;\n    if (_509)\n    {\n        _515 = c.x <= 1.0f;\n    }\n    else\n    {\n        _515 = _509;\n    }\n    bool _521;\n    if (_515)\n    {\n        _521 = c.y >= 0.0f;\n    }\n    else\n    {\n        _521 = _515;\n    }\n    bool _527;\n    if (_521)\n    {\n        _527 = c.y <= 1.0f;\n    }\n    else\n    {\n        _527 = _521;\n    }\n    float2 _529 = c;\n    float2 _534 = clamp(_529, 0.001953125f.xx, 0.998046875f.xx);\n    c = _534;\n    return float3(cell.x + (_534.x * cell.w), cell.y + (_534.y * cell.z), float(_527));\n}\n\nfloat cookie_value(float4 t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125f, 0.715200006961822509765625f, 0.072200000286102294921875f)) * t.w;\n}\n\nfloat cookie_att(int i, float2 d)\n{\n    if (_693_light_cookie[i].w == 0.0f)\n    {\n        return 1.0f;\n    }\n    float4 param = _693_light_cookie[i];\n    float4 param_1 = _693_light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _804 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.SampleLevel(light_smp, _804.xy, 0.0f);\n    return cookie_value(param_3) * _804.z;\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _826 = _693_lit.y > 0.5f;\n    if (_826)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _693_normal_uv.xy) + _693_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _850 = fa_tex_fix(param, param_1);\n        float3 _854 = (_850 * 2.0f) - 1.0f.xxx;\n        float _861 = cos(params.y);\n        float _863 = sin(params.y);\n        n = normalize(float3((float2(_861, _863) * _854.x) + ((float2(-_863, _861) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _854.y), max(_854.z, 0.0500000007450580596923828125f)));\n    }\n    bool _897 = !_826;\n    bool _903;\n    if (_897)\n    {\n        _903 = _693_lit.z > 0.5f;\n    }\n    else\n    {\n        _903 = _897;\n    }\n    float3 _906;\n    if (_903)\n    {\n        _906 = _693_flat_ambient.xyz;\n    }\n    else\n    {\n        _906 = _693_ambient.xyz;\n    }\n    float3 total = _906;\n    bool _923;\n    if (_903)\n    {\n        _923 = _693_lit.z < 1.5f;\n    }\n    else\n    {\n        _923 = _903;\n    }\n    if (_923)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _693_light_map.xy, 0.0f).xyz * _693_light_map.z);\n    }\n    float3 l;\n    float _1050;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _960;\n        if (!_903)\n        {\n            _960 = float(i) >= _693_lit.x;\n        }\n        else\n        {\n            _960 = _903;\n        }\n        if (_960)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_693_light_pos[i].w < 0.0f)\n        {\n            l = _693_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _986 = _693_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_986) / max(_693_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _693_light_color[i].w);\n            float3 _1006 = float3(_986, _693_light_pos[i].z);\n            l = _1006 / max(length(_1006), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_693_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _693_light_shadow_v[i].x;\n                float param_3 = _693_light_shadow_v[i].y;\n                float2 param_4 = -_986;\n                float param_5 = _693_light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            float2 param_7 = -_986;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_826)\n        {\n            _1050 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _1050 = 1.0f;\n        }\n        total += (_693_light_color[i].xyz * (att * _1050));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _670 = fa_srgb_to_linear(param);\n        c = _670;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _1300 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _1304 = uv * _1300;\n    float _1310 = _1300.x;\n    float _1312 = _1300.y;\n    float _1314 = clamp(shape_rs.x, 0.0f, min(_1310, _1312));\n    float2 _1325 = (abs(_1304) - _1300) + _1314.xx;\n    float d = (length(max(_1325, 0.0f.xx)) + min(max(_1325.x, _1325.y), 0.0f)) - _1314;\n    float ax = params.y;\n    bool _1346 = params.y > 15.0f;\n    if (_1346)\n    {\n        ax -= 20.0f;\n    }\n    float _1357;\n    if (ax <= (-1.5f))\n    {\n        _1357 = (-2.0f) - ax;\n    }\n    else\n    {\n        _1357 = 0.0f;\n    }\n    if (_1357 > 0.0f)\n    {\n        float _1371 = _1357 * 0.5f;\n        d = abs(d + _1371) - _1371;\n    }\n    float _1379 = fwidth(d);\n    float _1380 = max(_1379, 9.9999997473787516355514526367188e-05f);\n    float _1390 = clamp(0.5f - (d / max(shape_rs.y, _1380)), 0.0f, 1.0f);\n    float _1395;\n    if (shape_rs.y > _1380)\n    {\n        _1395 = (_1390 * _1390) * (3.0f - (2.0f * _1390));\n    }\n    else\n    {\n        _1395 = _1390;\n    }\n    float4 c = color;\n    bool _1417 = (_1357 <= 0.0f) && (ax > (-0.5f));\n    if (_1417)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1432 = cos(ax);\n            float _1434 = sin(ax);\n            g = ((dot(_1304, float2(_1432, _1434)) / max((abs(_1432) * _1310) + (abs(_1434) * _1312), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_1346)\n        {\n            float4 _1477 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _1477;\n            float3 param = _1477.xyz;\n            float param_1 = xform.y;\n            float3 _1484 = fa_tex_fix(param, param_1);\n            float4 _2273 = c;\n            _2273.x = _1484.x;\n            _2273.y = _1484.y;\n            _2273.z = _1484.z;\n            c = _2273;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1496 = scene_rgb(param_2);\n            float4 _1521 = lerp(float4(color.xyz * color.w, color.w), float4(_1496 * color2.w, color2.w), g.xxxx);\n            float _1523 = _1521.w;\n            float3 _1526;\n            if (_1523 > 9.9999997473787516355514526367188e-06f)\n            {\n                _1526 = _1521.xyz / _1523.xxx;\n            }\n            else\n            {\n                _1526 = color.xyz;\n            }\n            c = float4(_1526, _1523);\n        }\n    }\n    float4 _2282 = c;\n    _2282.w = _2282.w * _1395;\n    c = _2282;\n    if (_1417 || (shape_rs.y > 0.0f))\n    {\n        float _1567 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1576 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1576 + (_1567 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1582 = fa_srgb_to_linear(param_4);\n            float4 _2285 = c;\n            _2285.x = _1582.x;\n            _2285.y = _1582.y;\n            _2285.z = _1582.z;\n            c = _2285;\n        }\n        else\n        {\n            float4 _1592 = c;\n            float3 _1595 = _1592.xyz + (_1567 * 0.0039215688593685626983642578125f).xxx;\n            float4 _2292 = _1592;\n            _2292.x = _1595.x;\n            _2292.y = _1595.y;\n            _2292.z = _1595.z;\n            c = _2292;\n        }\n        float4 _2297 = c;\n        _2297.w = clamp(_2297.w + ((_1567 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _2297.w)), 0.0f, 1.0f);\n        c = _2297;\n    }\n    return c;\n}\n\nfloat3 rim_color(float a0, float mode)\n{\n    float2 _1087 = float2(_693_fx_rim_uv.x, 0.0f);\n    float4 _1089 = tex.Sample(smp, uv - _1087);\n    float _1090 = _1089.w;\n    float4 _1100 = tex.Sample(smp, uv + _1087);\n    float _1101 = _1100.w;\n    float2 _1109 = float2(0.0f, _693_fx_rim_uv.y);\n    float4 _1111 = tex.Sample(smp, uv - _1109);\n    float _1112 = _1111.w;\n    float4 _1122 = tex.Sample(smp, uv + _1109);\n    float _1123 = _1122.w;\n    float _1138 = _1090 - _1101;\n    float _1141 = _1123 - _1112;\n    float _1151 = cos(params.y);\n    float _1153 = sin(params.y);\n    float2 _1179 = ((float2(_1151, _1153) * _1138) + ((float2(-_1153, _1151) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _1141)) / max(length(float2(_1138, _1141)), 9.9999997473787516355514526367188e-05f).xx;\n    float3 sum = 0.0f.xxx;\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _693_lit.x)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_693_light_pos[i].w < 0.0f)\n        {\n            to_l = _693_light_pos[i].xy / max(length(_693_light_pos[i].xy), 9.9999997473787516355514526367188e-05f).xx;\n        }\n        else\n        {\n            float2 _1225 = _693_light_pos[i].xy - world_xy;\n            float _1228 = length(_1225);\n            att = pow(clamp(1.0f - (_1228 / max(_693_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _693_light_color[i].w);\n            to_l = _1225 / max(_1228, 9.9999997473787516355514526367188e-05f).xx;\n            if (_693_light_shadow_v[i].x >= 0.0f)\n            {\n                float param = _693_light_shadow_v[i].x;\n                float param_1 = _693_light_shadow_v[i].y;\n                float2 param_2 = -_1225;\n                float param_3 = _693_light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1225;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (_693_light_color[i].xyz * (att * max(dot(_1179, to_l), 0.0f)));\n    }\n    return (sum * _693_fx_rim.xyz) * (a0 * (1.0f - min(min(_1090, _1101), min(_1112, _1123))));\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _699 = gl_FragCoord.xy * _693_fa_target.xy;\n    float _703 = _699.y;\n    return float2(_699.x, lerp(_703, 1.0f - _703, _693_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _741 = base_mode < 0.5f;\n    bool _752;\n    if (!_741)\n    {\n        _752 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _752 = _741;\n    }\n    float _753;\n    if (_752)\n    {\n        _753 = shape_half.x;\n    }\n    else\n    {\n        _753 = 0.0f;\n    }\n    QuadInput _2223 = { uv, color, world_xy, fa_screen_uv(), _693_fa_time.x, base_mode, 0.0f.xxxx, _753 };\n    return _2223;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _676 = scene_rgb(param);\n    return _676;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = _767_tint.xyz;\n    float4 _774 = s.color;\n    float3 _776 = _774.xyz * fa_scene_rgb(param);\n    s.color.x = _776.x;\n    s.color.y = _776.y;\n    s.color.z = _776.z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1622 = params.x > 31.5f;\n    if (_1622)\n    {\n        mode -= 32.0f;\n    }\n    float _1630 = mode;\n    bool _1632 = _1630 > 15.5f;\n    if (_1632)\n    {\n        mode -= 16.0f;\n    }\n    float _1640 = mode;\n    bool _1642 = _1640 > 7.5f;\n    if (_1642)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1632)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1632)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1704 = tex_color(param_5);\n                float4 _1706 = _1704 * color;\n                float4 param_6 = _1706;\n                float param_7 = mode;\n                float _1713 = _1706.w;\n                frag_color = float4(lit_color(param_6, param_7), _1713);\n                if (_693_fx_rim.w > 0.5f)\n                {\n                    float param_8 = _1713;\n                    float param_9 = mode;\n                    float4 _1729 = frag_color;\n                    float3 _1731 = _1729.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1731.x;\n                    frag_color.y = _1731.y;\n                    frag_color.z = _1731.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1761 = length(uv);\n                    float _1764 = fwidth(_1761);\n                    float _1765 = max(_1764, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1761) / _1765) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1761) / _1765) + 0.5f, 0.0f, 1.0f) * clamp(((_1761 - params.y) / _1765) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1805 = clamp(1.0f - _1761, 0.0f, 1.0f);\n                            cov = (_1805 * _1805) * (3.0f - (2.0f * _1805));\n                        }\n                    }\n                    float3 _1814;\n                    if (_1632)\n                    {\n                        float4 param_10 = color;\n                        float param_11 = 5.0f;\n                        _1814 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1814 = color.xyz;\n                    }\n                    frag_color = float4(_1814, color.w * cov);\n                }\n            }\n        }\n    }\n    if (_693_fx_emit.w > 0.5f)\n    {\n        float3 e = _693_fx_emit.xyz;\n        if (_693_fx_emit.w > 1.5f)\n        {\n            float3 param_12 = fx_emissive_tex.Sample(smp, (uv * _693_fx_emit_uv.xy) + _693_fx_emit_uv.zw).xyz;\n            float param_13 = _693_fx_emit.w - 2.0f;\n            float3 _1869 = fa_tex_fix(param_12, param_13);\n            e *= _1869;\n        }\n        float4 _1873 = frag_color;\n        float3 _1875 = _1873.xyz + e;\n        frag_color.x = _1875.x;\n        frag_color.y = _1875.y;\n        frag_color.z = _1875.z;\n    }\n    float param_14 = mode;\n    float4 _2203 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface _2205 = { _2203 };\n    QuadSurface param_16 = _2205;\n    fragment(param_15, param_16);\n    _2203 = param_16.color;\n    frag_color = param_16.color;\n    if (_1622)\n    {\n        float4 _1901 = frag_color;\n        float3 param_17 = color2.xyz;\n        float3 _1906 = scene_rgb(param_17);\n        float3 _1910 = lerp(_1901.xyz, _1906, color2.w.xxx);\n        frag_color.x = _1910.x;\n        frag_color.y = _1910.y;\n        frag_color.z = _1910.z;\n    }\n    if (_1642)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1934 = _693_fog_col.w > 0.0f;\n    bool _1942;\n    if (!_1934)\n    {\n        _1942 = _693_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1942 = _1934;\n    }\n    if (_1942)\n    {\n        float3 _1956 = float3(world_xy, world_z) - _693_fog_eye.xyz;\n        float _1963 = dot(_1956, _693_fog_c.xyz);\n        bool _1967 = _693_fog_c.w > 0.5f;\n        float _1968;\n        if (_1967)\n        {\n            _1968 = _1963;\n        }\n        else\n        {\n            _1968 = length(_1956);\n        }\n        float _1980 = _1968 - _693_fog_b.x;\n        if (_1980 > 0.0f)\n        {\n            float _1989 = _693_fog_col.w * _1980;\n            float tau = _1989 * _1989;\n            if (_693_fog_b.y > 0.0f)\n            {\n                float _2005;\n                if (_1967)\n                {\n                    _2005 = world_xy.y - (_693_fog_c.y * _1963);\n                }\n                else\n                {\n                    _2005 = _693_fog_eye.y;\n                }\n                float _2026 = lerp(_2005, world_xy.y, clamp(_693_fog_b.x / _1968, 0.0f, 1.0f));\n                float _2030 = world_xy.y - _2026;\n                float _2035 = _2026 - _693_fog_b.z;\n                float _2040 = world_xy.y - _693_fog_b.z;\n                bool _2043 = _2035 <= 0.0f;\n                bool _2044 = !_2043;\n                bool _2050;\n                if (_2044)\n                {\n                    _2050 = _693_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2050 = _2043;\n                }\n                float _2051;\n                if (_2050)\n                {\n                    _2051 = _693_fog_b.y;\n                }\n                else\n                {\n                    _2051 = _693_fog_b.y * exp(-min(_693_fog_b.w * _2035, 80.0f));\n                }\n                bool _2078;\n                if (_2044)\n                {\n                    _2078 = _693_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2078 = _2043;\n                }\n                float _2079;\n                if (_2078)\n                {\n                    _2079 = _693_fog_b.y * _2035;\n                }\n                else\n                {\n                    _2079 = (_693_fog_b.y * (1.0f - exp(-min(_693_fog_b.w * _2035, 80.0f)))) / _693_fog_b.w;\n                }\n                bool _2104 = _2040 <= 0.0f;\n                bool _2111;\n                if (!_2104)\n                {\n                    _2111 = _693_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2111 = _2104;\n                }\n                float _2112;\n                if (_2111)\n                {\n                    _2112 = _693_fog_b.y * _2040;\n                }\n                else\n                {\n                    _2112 = (_693_fog_b.y * (1.0f - exp(-min(_693_fog_b.w * _2040, 80.0f)))) / _693_fog_b.w;\n                }\n                float _2139;\n                if (abs(_2030) < 0.001000000047497451305389404296875f)\n                {\n                    _2139 = _2051;\n                }\n                else\n                {\n                    _2139 = (_2112 - _2079) / _2030;\n                }\n                tau += (_1980 * max(_2139, 0.0f));\n            }\n            float4 _2162 = frag_color;\n            float3 _2170 = lerp(_2162.xyz, _693_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _2170.x;\n            frag_color.y = _2170.y;\n            frag_color.z = _2170.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 1584,
            "struct_name": "quad_fs_params",
            "inst_name": "_693",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_767",
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
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _147 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _147;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _157_lit : packoffset(c0);\n    float4 _157_ambient : packoffset(c1);\n    float4 _157_normal_uv : packoffset(c2);\n    float4 _157_flat_ambient : packoffset(c3);\n    float4 _157_light_map : packoffset(c4);\n    float4 _157_light_pos[16] : packoffset(c5);\n    float4 _157_light_color[16] : packoffset(c21);\n    float4 _157_light_shadow_v[16] : packoffset(c37);\n    float4 _157_fog_col : packoffset(c53);\n    float4 _157_fog_b : packoffset(c54);\n    float4 _157_fog_c : packoffset(c55);\n    float4 _157_fog_eye : packoffset(c56);\n    float4 _157_fa_time : packoffset(c57);\n    float4 _157_fa_target : packoffset(c58);\n    float4 _157_fx_emit : packoffset(c59);\n    float4 _157_fx_emit_uv : packoffset(c60);\n    float4 _157_fx_rim : packoffset(c61);\n    float4 _157_fx_rim_uv : packoffset(c62);\n    float4 _157_light_cookie[16] : packoffset(c63);\n    float4 _157_light_cookie_xf[16] : packoffset(c79);\n    float4 _157_fa_scene : packoffset(c95);\n    float4 _157_fa_world_uv[3] : packoffset(c96);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _239_tint : packoffset(c0);\n};\n\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 frag_color;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _107 = fa_linear_to_srgb(param);\n        c = _107;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _116 = fa_srgb_to_linear(param_1);\n            c = _116;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _164 = gl_FragCoord.xy * _157_fa_target.xy;\n    float _169 = _164.y;\n    return float2(_164.x, lerp(_169, 1.0f - _169, _157_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _213 = base_mode < 0.5f;\n    bool _224;\n    if (!_213)\n    {\n        _224 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _224 = _213;\n    }\n    float _225;\n    if (_224)\n    {\n        _225 = shape_half.x;\n    }\n    else\n    {\n        _225 = 0.0f;\n    }\n    QuadInput _351 = { uv, color, world_xy, fa_screen_uv(), _157_fa_time.x, base_mode, 0.0f.xxxx, _225 };\n    return _351;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _132 = fa_srgb_to_linear(param);\n        c = _132;\n    }\n    return c;\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _138 = scene_rgb(param);\n    return _138;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = _239_tint.xyz;\n    float4 _246 = s.color;\n    float3 _248 = _246.xyz * fa_scene_rgb(param);\n    s.color.x = _248.x;\n    s.color.y = _248.y;\n    s.color.z = _248.z;\n}\n\nvoid frag_main()\n{\n    float4 _267 = tex.Sample(smp, uv);\n    float3 param = _267.xyz;\n    float param_1 = xform.y;\n    float3 _276 = fa_tex_fix(param, param_1);\n    frag_color = float4(_276, _267.w) * color;\n    float param_2 = 0.0f;\n    float4 _331 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _333 = { _331 };\n    QuadSurface param_4 = _333;\n    fragment(param_3, param_4);\n    _331 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 1584,
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
