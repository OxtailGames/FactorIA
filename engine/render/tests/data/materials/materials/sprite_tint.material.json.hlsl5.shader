{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "b6702e732a018d02616e2cc30236fe0da222b416419f1c736db600933d8ca4e3",
  "slang": "hlsl5",
  "params": [
    "tint"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _147 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _147;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _692_lit : packoffset(c0);\n    float4 _692_ambient : packoffset(c1);\n    float4 _692_normal_uv : packoffset(c2);\n    float4 _692_flat_ambient : packoffset(c3);\n    float4 _692_light_map : packoffset(c4);\n    float4 _692_light_pos[16] : packoffset(c5);\n    float4 _692_light_color[16] : packoffset(c21);\n    float4 _692_light_shadow_v[16] : packoffset(c37);\n    float4 _692_fog_col : packoffset(c53);\n    float4 _692_fog_b : packoffset(c54);\n    float4 _692_fog_c : packoffset(c55);\n    float4 _692_fog_eye : packoffset(c56);\n    float4 _692_fa_time : packoffset(c57);\n    float4 _692_fa_target : packoffset(c58);\n    float4 _692_fx_emit : packoffset(c59);\n    float4 _692_fx_emit_uv : packoffset(c60);\n    float4 _692_fx_rim : packoffset(c61);\n    float4 _692_fx_rim_uv : packoffset(c62);\n    float4 _692_light_cookie[16] : packoffset(c63);\n    float4 _692_light_cookie_xf[16] : packoffset(c79);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _766_tint : packoffset(c0);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> fx_cookie_tex : register(t5);\nSamplerState light_smp : register(s1);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nTexture2D<float4> fx_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _625 = fa_linear_to_srgb(param);\n        c = _625;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _633 = fa_srgb_to_linear(param_1);\n            c = _633;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _644 = tex.Sample(smp, p);\n    float3 param = _644.xyz;\n    float param_1 = xform.y;\n    float3 _654 = fa_tex_fix(param, param_1);\n    return float4(_654, _644.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _134 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_134.x * 255.0f) + 0.5f) * 256.0f) + floor((_134.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _237 = floor(tt);\n    float _247 = _237 - (1024.0f * floor(_237 * 0.0009765625f));\n    float _250 = _247 + 1.0f;\n    float i1 = _250;\n    if (_250 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _247;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5f, 0.0f, 1.0f), tt - _237);\n}\n\nfloat light_shadow_soft(float v, float size, float2 d, float radius)\n{\n    float _287 = length(d);\n    float result = 1.0f;\n    if (_287 >= 9.9999997473787516355514526367188e-05f)\n    {\n        float _298 = atan2(d.y, d.x);\n        float a = _298;\n        float _301;\n        if (_298 < 0.0f)\n        {\n            _301 = a + 6.283185482025146484375f;\n        }\n        else\n        {\n            _301 = a;\n        }\n        a = _301;\n        float _311 = _301 * 162.9746551513671875f;\n        float _320 = min((size * 10.0f) / _287, 0.699999988079071044921875f) * 162.9746551513671875f;\n        float sum = 0.0f;\n        float n = 0.0f;\n        for (int k = 0; k < 12; k++)\n        {\n            float _346 = floor(_311 + ((((float(k) + 0.5f) * 0.16666667163372039794921875f) - 1.0f) * _320));\n            float param = v;\n            float param_1 = _346 - (1024.0f * floor(_346 * 0.0009765625f));\n            float _360 = shadow_texel(param, param_1) * radius;\n            if (_360 < _287)\n            {\n                sum += _360;\n                n += 1.0f;\n            }\n        }\n        if (n > 0.5f)\n        {\n            float _392 = min(size * ((1.0f / max(sum / n, 1.0f)) - (1.0f / _287)), 0.699999988079071044921875f) * 162.9746551513671875f;\n            float acc = 0.0f;\n            float wsum = 0.0f;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _410 = ((float(k_1) + 0.5f) * 0.125f) - 1.0f;\n                float _416 = 1.0f - (0.800000011920928955078125f * abs(_410));\n                float param_2 = v;\n                float param_3 = _311 + (_410 * _392);\n                float param_4 = _287;\n                float param_5 = radius;\n                acc += (_416 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _416;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _158 = length(d);\n    if (_158 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _172 = atan2(d.y, d.x);\n    float a = _172;\n    float _175;\n    if (_172 < 0.0f)\n    {\n        _175 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _175 = a;\n    }\n    a = _175;\n    float _187 = _175 * 162.9746551513671875f;\n    float _192 = min(floor(_187), 1023.0f);\n    float _199 = _192 + 1.0f;\n    float i1 = _199;\n    if (_199 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _192;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _158) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _158) + 0.5f, 0.0f, 1.0f), _187 - _192);\n}\n\nfloat light_shadow_sized(float v, float size, float2 d, float radius)\n{\n    float r = 1.0f;\n    if (size > 0.0f)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nfloat3 cookie_coord(float4 cell, float4 xf, float2 off)\n{\n    float2 _497 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _501 = _497.x + 0.5f;\n    float2 c = float2(_501, 0.5f - _497.y);\n    bool _509 = _501 >= 0.0f;\n    bool _515;\n    if (_509)\n    {\n        _515 = c.x <= 1.0f;\n    }\n    else\n    {\n        _515 = _509;\n    }\n    bool _521;\n    if (_515)\n    {\n        _521 = c.y >= 0.0f;\n    }\n    else\n    {\n        _521 = _515;\n    }\n    bool _527;\n    if (_521)\n    {\n        _527 = c.y <= 1.0f;\n    }\n    else\n    {\n        _527 = _521;\n    }\n    float2 _529 = c;\n    float2 _534 = clamp(_529, 0.001953125f.xx, 0.998046875f.xx);\n    c = _534;\n    return float3(cell.x + (_534.x * cell.w), cell.y + (_534.y * cell.z), float(_527));\n}\n\nfloat cookie_value(float4 t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125f, 0.715200006961822509765625f, 0.072200000286102294921875f)) * t.w;\n}\n\nfloat cookie_att(int i, float2 d)\n{\n    if (_692_light_cookie[i].w == 0.0f)\n    {\n        return 1.0f;\n    }\n    float4 param = _692_light_cookie[i];\n    float4 param_1 = _692_light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _803 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.SampleLevel(light_smp, _803.xy, 0.0f);\n    return cookie_value(param_3) * _803.z;\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _825 = _692_lit.y > 0.5f;\n    if (_825)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _692_normal_uv.xy) + _692_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _849 = fa_tex_fix(param, param_1);\n        float3 _853 = (_849 * 2.0f) - 1.0f.xxx;\n        float _860 = cos(params.y);\n        float _862 = sin(params.y);\n        n = normalize(float3((float2(_860, _862) * _853.x) + ((float2(-_862, _860) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _853.y), max(_853.z, 0.0500000007450580596923828125f)));\n    }\n    bool _896 = !_825;\n    bool _902;\n    if (_896)\n    {\n        _902 = _692_lit.z > 0.5f;\n    }\n    else\n    {\n        _902 = _896;\n    }\n    float3 _905;\n    if (_902)\n    {\n        _905 = _692_flat_ambient.xyz;\n    }\n    else\n    {\n        _905 = _692_ambient.xyz;\n    }\n    float3 total = _905;\n    bool _922;\n    if (_902)\n    {\n        _922 = _692_lit.z < 1.5f;\n    }\n    else\n    {\n        _922 = _902;\n    }\n    if (_922)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _692_light_map.xy, 0.0f).xyz * _692_light_map.z);\n    }\n    float3 l;\n    float _1049;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _959;\n        if (!_902)\n        {\n            _959 = float(i) >= _692_lit.x;\n        }\n        else\n        {\n            _959 = _902;\n        }\n        if (_959)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_692_light_pos[i].w < 0.0f)\n        {\n            l = _692_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _985 = _692_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_985) / max(_692_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _692_light_color[i].w);\n            float3 _1005 = float3(_985, _692_light_pos[i].z);\n            l = _1005 / max(length(_1005), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_692_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _692_light_shadow_v[i].x;\n                float param_3 = _692_light_shadow_v[i].y;\n                float2 param_4 = -_985;\n                float param_5 = _692_light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            float2 param_7 = -_985;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_825)\n        {\n            _1049 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _1049 = 1.0f;\n        }\n        total += (_692_light_color[i].xyz * (att * _1049));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _670 = fa_srgb_to_linear(param);\n        c = _670;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _1299 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _1303 = uv * _1299;\n    float _1309 = _1299.x;\n    float _1311 = _1299.y;\n    float _1313 = clamp(shape_rs.x, 0.0f, min(_1309, _1311));\n    float2 _1324 = (abs(_1303) - _1299) + _1313.xx;\n    float d = (length(max(_1324, 0.0f.xx)) + min(max(_1324.x, _1324.y), 0.0f)) - _1313;\n    float ax = params.y;\n    bool _1345 = params.y > 15.0f;\n    if (_1345)\n    {\n        ax -= 20.0f;\n    }\n    float _1356;\n    if (ax <= (-1.5f))\n    {\n        _1356 = (-2.0f) - ax;\n    }\n    else\n    {\n        _1356 = 0.0f;\n    }\n    if (_1356 > 0.0f)\n    {\n        float _1370 = _1356 * 0.5f;\n        d = abs(d + _1370) - _1370;\n    }\n    float _1378 = fwidth(d);\n    float _1379 = max(_1378, 9.9999997473787516355514526367188e-05f);\n    float _1389 = clamp(0.5f - (d / max(shape_rs.y, _1379)), 0.0f, 1.0f);\n    float _1394;\n    if (shape_rs.y > _1379)\n    {\n        _1394 = (_1389 * _1389) * (3.0f - (2.0f * _1389));\n    }\n    else\n    {\n        _1394 = _1389;\n    }\n    float4 c = color;\n    bool _1416 = (_1356 <= 0.0f) && (ax > (-0.5f));\n    if (_1416)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1431 = cos(ax);\n            float _1433 = sin(ax);\n            g = ((dot(_1303, float2(_1431, _1433)) / max((abs(_1431) * _1309) + (abs(_1433) * _1311), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_1345)\n        {\n            float4 _1476 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _1476;\n            float3 param = _1476.xyz;\n            float param_1 = xform.y;\n            float3 _1483 = fa_tex_fix(param, param_1);\n            float4 _2271 = c;\n            _2271.x = _1483.x;\n            _2271.y = _1483.y;\n            _2271.z = _1483.z;\n            c = _2271;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1495 = scene_rgb(param_2);\n            float4 _1520 = lerp(float4(color.xyz * color.w, color.w), float4(_1495 * color2.w, color2.w), g.xxxx);\n            float _1522 = _1520.w;\n            float3 _1525;\n            if (_1522 > 9.9999997473787516355514526367188e-06f)\n            {\n                _1525 = _1520.xyz / _1522.xxx;\n            }\n            else\n            {\n                _1525 = color.xyz;\n            }\n            c = float4(_1525, _1522);\n        }\n    }\n    float4 _2280 = c;\n    _2280.w = _2280.w * _1394;\n    c = _2280;\n    if (_1416 || (shape_rs.y > 0.0f))\n    {\n        float _1566 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1575 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1575 + (_1566 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1581 = fa_srgb_to_linear(param_4);\n            float4 _2283 = c;\n            _2283.x = _1581.x;\n            _2283.y = _1581.y;\n            _2283.z = _1581.z;\n            c = _2283;\n        }\n        else\n        {\n            float4 _1591 = c;\n            float3 _1594 = _1591.xyz + (_1566 * 0.0039215688593685626983642578125f).xxx;\n            float4 _2290 = _1591;\n            _2290.x = _1594.x;\n            _2290.y = _1594.y;\n            _2290.z = _1594.z;\n            c = _2290;\n        }\n        float4 _2295 = c;\n        _2295.w = clamp(_2295.w + ((_1566 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _2295.w)), 0.0f, 1.0f);\n        c = _2295;\n    }\n    return c;\n}\n\nfloat3 rim_color(float a0, float mode)\n{\n    float2 _1086 = float2(_692_fx_rim_uv.x, 0.0f);\n    float4 _1088 = tex.Sample(smp, uv - _1086);\n    float _1089 = _1088.w;\n    float4 _1099 = tex.Sample(smp, uv + _1086);\n    float _1100 = _1099.w;\n    float2 _1108 = float2(0.0f, _692_fx_rim_uv.y);\n    float4 _1110 = tex.Sample(smp, uv - _1108);\n    float _1111 = _1110.w;\n    float4 _1121 = tex.Sample(smp, uv + _1108);\n    float _1122 = _1121.w;\n    float _1137 = _1089 - _1100;\n    float _1140 = _1122 - _1111;\n    float _1150 = cos(params.y);\n    float _1152 = sin(params.y);\n    float2 _1178 = ((float2(_1150, _1152) * _1137) + ((float2(-_1152, _1150) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _1140)) / max(length(float2(_1137, _1140)), 9.9999997473787516355514526367188e-05f).xx;\n    float3 sum = 0.0f.xxx;\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _692_lit.x)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_692_light_pos[i].w < 0.0f)\n        {\n            to_l = _692_light_pos[i].xy / max(length(_692_light_pos[i].xy), 9.9999997473787516355514526367188e-05f).xx;\n        }\n        else\n        {\n            float2 _1224 = _692_light_pos[i].xy - world_xy;\n            float _1227 = length(_1224);\n            att = pow(clamp(1.0f - (_1227 / max(_692_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _692_light_color[i].w);\n            to_l = _1224 / max(_1227, 9.9999997473787516355514526367188e-05f).xx;\n            if (_692_light_shadow_v[i].x >= 0.0f)\n            {\n                float param = _692_light_shadow_v[i].x;\n                float param_1 = _692_light_shadow_v[i].y;\n                float2 param_2 = -_1224;\n                float param_3 = _692_light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1224;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (_692_light_color[i].xyz * (att * max(dot(_1178, to_l), 0.0f)));\n    }\n    return (sum * _692_fx_rim.xyz) * (a0 * (1.0f - min(min(_1089, _1100), min(_1111, _1122))));\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _698 = gl_FragCoord.xy * _692_fa_target.xy;\n    float _702 = _698.y;\n    return float2(_698.x, lerp(_702, 1.0f - _702, _692_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _740 = base_mode < 0.5f;\n    bool _751;\n    if (!_740)\n    {\n        _751 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _751 = _740;\n    }\n    float _752;\n    if (_751)\n    {\n        _752 = shape_half.x;\n    }\n    else\n    {\n        _752 = 0.0f;\n    }\n    QuadInput _2221 = { uv, color, world_xy, fa_screen_uv(), _692_fa_time.x, base_mode, 0.0f.xxxx, _752 };\n    return _2221;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _676 = scene_rgb(param);\n    return _676;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = _766_tint.xyz;\n    float4 _773 = s.color;\n    float3 _775 = _773.xyz * fa_scene_rgb(param);\n    s.color.x = _775.x;\n    s.color.y = _775.y;\n    s.color.z = _775.z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1621 = params.x > 31.5f;\n    if (_1621)\n    {\n        mode -= 32.0f;\n    }\n    float _1629 = mode;\n    bool _1631 = _1629 > 15.5f;\n    if (_1631)\n    {\n        mode -= 16.0f;\n    }\n    float _1639 = mode;\n    bool _1641 = _1639 > 7.5f;\n    if (_1641)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1631)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1631)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1703 = tex_color(param_5);\n                float4 _1705 = _1703 * color;\n                float4 param_6 = _1705;\n                float param_7 = mode;\n                float _1712 = _1705.w;\n                frag_color = float4(lit_color(param_6, param_7), _1712);\n                if (_692_fx_rim.w > 0.5f)\n                {\n                    float param_8 = _1712;\n                    float param_9 = mode;\n                    float4 _1728 = frag_color;\n                    float3 _1730 = _1728.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1730.x;\n                    frag_color.y = _1730.y;\n                    frag_color.z = _1730.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1760 = length(uv);\n                    float _1763 = fwidth(_1760);\n                    float _1764 = max(_1763, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1760) / _1764) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1760) / _1764) + 0.5f, 0.0f, 1.0f) * clamp(((_1760 - params.y) / _1764) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1804 = clamp(1.0f - _1760, 0.0f, 1.0f);\n                            cov = (_1804 * _1804) * (3.0f - (2.0f * _1804));\n                        }\n                    }\n                    float3 _1813;\n                    if (_1631)\n                    {\n                        float4 param_10 = color;\n                        float param_11 = 5.0f;\n                        _1813 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1813 = color.xyz;\n                    }\n                    frag_color = float4(_1813, color.w * cov);\n                }\n            }\n        }\n    }\n    if (_692_fx_emit.w > 0.5f)\n    {\n        float3 e = _692_fx_emit.xyz;\n        if (_692_fx_emit.w > 1.5f)\n        {\n            float3 param_12 = fx_emissive_tex.Sample(smp, (uv * _692_fx_emit_uv.xy) + _692_fx_emit_uv.zw).xyz;\n            float param_13 = _692_fx_emit.w - 2.0f;\n            float3 _1868 = fa_tex_fix(param_12, param_13);\n            e *= _1868;\n        }\n        float4 _1872 = frag_color;\n        float3 _1874 = _1872.xyz + e;\n        frag_color.x = _1874.x;\n        frag_color.y = _1874.y;\n        frag_color.z = _1874.z;\n    }\n    float param_14 = mode;\n    float4 _2201 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface _2203 = { _2201 };\n    QuadSurface param_16 = _2203;\n    fragment(param_15, param_16);\n    _2201 = param_16.color;\n    frag_color = param_16.color;\n    if (_1621)\n    {\n        float4 _1900 = frag_color;\n        float3 param_17 = color2.xyz;\n        float3 _1905 = scene_rgb(param_17);\n        float3 _1909 = lerp(_1900.xyz, _1905, color2.w.xxx);\n        frag_color.x = _1909.x;\n        frag_color.y = _1909.y;\n        frag_color.z = _1909.z;\n    }\n    if (_1641)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1933 = _692_fog_col.w > 0.0f;\n    bool _1941;\n    if (!_1933)\n    {\n        _1941 = _692_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1941 = _1933;\n    }\n    if (_1941)\n    {\n        float3 _1955 = float3(world_xy, world_z) - _692_fog_eye.xyz;\n        float _1962 = dot(_1955, _692_fog_c.xyz);\n        bool _1966 = _692_fog_c.w > 0.5f;\n        float _1967;\n        if (_1966)\n        {\n            _1967 = _1962;\n        }\n        else\n        {\n            _1967 = length(_1955);\n        }\n        float _1979 = _1967 - _692_fog_b.x;\n        if (_1979 > 0.0f)\n        {\n            float _1988 = _692_fog_col.w * _1979;\n            float tau = _1988 * _1988;\n            if (_692_fog_b.y > 0.0f)\n            {\n                float _2004;\n                if (_1966)\n                {\n                    _2004 = world_xy.y - (_692_fog_c.y * _1962);\n                }\n                else\n                {\n                    _2004 = _692_fog_eye.y;\n                }\n                float _2025 = lerp(_2004, world_xy.y, clamp(_692_fog_b.x / _1967, 0.0f, 1.0f));\n                float _2029 = world_xy.y - _2025;\n                float _2034 = _2025 - _692_fog_b.z;\n                float _2039 = world_xy.y - _692_fog_b.z;\n                bool _2042 = _2034 <= 0.0f;\n                bool _2043 = !_2042;\n                bool _2049;\n                if (_2043)\n                {\n                    _2049 = _692_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2049 = _2042;\n                }\n                float _2050;\n                if (_2049)\n                {\n                    _2050 = _692_fog_b.y;\n                }\n                else\n                {\n                    _2050 = _692_fog_b.y * exp(-min(_692_fog_b.w * _2034, 80.0f));\n                }\n                bool _2077;\n                if (_2043)\n                {\n                    _2077 = _692_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2077 = _2042;\n                }\n                float _2078;\n                if (_2077)\n                {\n                    _2078 = _692_fog_b.y * _2034;\n                }\n                else\n                {\n                    _2078 = (_692_fog_b.y * (1.0f - exp(-min(_692_fog_b.w * _2034, 80.0f)))) / _692_fog_b.w;\n                }\n                bool _2103 = _2039 <= 0.0f;\n                bool _2110;\n                if (!_2103)\n                {\n                    _2110 = _692_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2110 = _2103;\n                }\n                float _2111;\n                if (_2110)\n                {\n                    _2111 = _692_fog_b.y * _2039;\n                }\n                else\n                {\n                    _2111 = (_692_fog_b.y * (1.0f - exp(-min(_692_fog_b.w * _2039, 80.0f)))) / _692_fog_b.w;\n                }\n                float _2138;\n                if (abs(_2029) < 0.001000000047497451305389404296875f)\n                {\n                    _2138 = _2050;\n                }\n                else\n                {\n                    _2138 = (_2111 - _2078) / _2029;\n                }\n                tau += (_1979 * max(_2138, 0.0f));\n            }\n            float4 _2161 = frag_color;\n            float3 _2169 = lerp(_2161.xyz, _692_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _2169.x;\n            frag_color.y = _2169.y;\n            frag_color.z = _2169.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 1520,
            "struct_name": "quad_fs_params",
            "inst_name": "_692",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_766",
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
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _155_lit : packoffset(c0);\n    float4 _155_ambient : packoffset(c1);\n    float4 _155_normal_uv : packoffset(c2);\n    float4 _155_flat_ambient : packoffset(c3);\n    float4 _155_light_map : packoffset(c4);\n    float4 _155_light_pos[16] : packoffset(c5);\n    float4 _155_light_color[16] : packoffset(c21);\n    float4 _155_light_shadow_v[16] : packoffset(c37);\n    float4 _155_fog_col : packoffset(c53);\n    float4 _155_fog_b : packoffset(c54);\n    float4 _155_fog_c : packoffset(c55);\n    float4 _155_fog_eye : packoffset(c56);\n    float4 _155_fa_time : packoffset(c57);\n    float4 _155_fa_target : packoffset(c58);\n    float4 _155_fx_emit : packoffset(c59);\n    float4 _155_fx_emit_uv : packoffset(c60);\n    float4 _155_fx_rim : packoffset(c61);\n    float4 _155_fx_rim_uv : packoffset(c62);\n    float4 _155_light_cookie[16] : packoffset(c63);\n    float4 _155_light_cookie_xf[16] : packoffset(c79);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _237_tint : packoffset(c0);\n};\n\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 frag_color;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _107 = fa_linear_to_srgb(param);\n        c = _107;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _116 = fa_srgb_to_linear(param_1);\n            c = _116;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _162 = gl_FragCoord.xy * _155_fa_target.xy;\n    float _167 = _162.y;\n    return float2(_162.x, lerp(_167, 1.0f - _167, _155_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _211 = base_mode < 0.5f;\n    bool _222;\n    if (!_211)\n    {\n        _222 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _222 = _211;\n    }\n    float _223;\n    if (_222)\n    {\n        _223 = shape_half.x;\n    }\n    else\n    {\n        _223 = 0.0f;\n    }\n    QuadInput _348 = { uv, color, world_xy, fa_screen_uv(), _155_fa_time.x, base_mode, 0.0f.xxxx, _223 };\n    return _348;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _132 = fa_srgb_to_linear(param);\n        c = _132;\n    }\n    return c;\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _138 = scene_rgb(param);\n    return _138;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = _237_tint.xyz;\n    float4 _244 = s.color;\n    float3 _246 = _244.xyz * fa_scene_rgb(param);\n    s.color.x = _246.x;\n    s.color.y = _246.y;\n    s.color.z = _246.z;\n}\n\nvoid frag_main()\n{\n    float4 _265 = tex.Sample(smp, uv);\n    float3 param = _265.xyz;\n    float param_1 = xform.y;\n    float3 _274 = fa_tex_fix(param, param_1);\n    frag_color = float4(_274, _265.w) * color;\n    float param_2 = 0.0f;\n    float4 _328 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _330 = { _328 };\n    QuadSurface param_4 = _330;\n    fragment(param_3, param_4);\n    _328 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 1520,
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
