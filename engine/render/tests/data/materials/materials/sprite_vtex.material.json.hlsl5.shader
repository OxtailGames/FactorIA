{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "8dda08c124964ccb7d15a0a3238fb4669d4ca9ef375995bc9768b79891bfc837",
  "slang": "hlsl5",
  "params": [],
  "textures": [
    "mask"
  ],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "struct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\ncbuffer vs_params : register(b0)\n{\n    row_major float4x4 _96_view_proj : packoffset(c0);\n    float4 _96_cspace : packoffset(c4);\n    float4 _96_fa_time : packoffset(c5);\n};\n\nTexture2D<float4> fa_vs_mask : register(t0);\nSamplerState fa_vs_mask_smp : register(s7);\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += (fa_vs_mask.SampleLevel(fa_vs_mask_smp, float2(0.4000000059604644775390625f, 0.0500000007450580596923828125f), 0.0f).x * 40.0f);\n}\n\nvoid vert_main()\n{\n    float3 _171 = position;\n    float2 _172 = texcoord0;\n    float4 _173 = color0;\n    if (_96_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _108 = fa_srgb_to_linear(param);\n        float4 _185 = _173;\n        _185.x = _108.x;\n        _185.y = _108.y;\n        _185.z = _108.z;\n        _173 = _185;\n    }\n    QuadVertex _180 = { _171, _172, _173 };\n    QuadVertex param_1 = _180;\n    vertex(param_1);\n    _171 = param_1.world_pos;\n    _172 = param_1.uv;\n    _173 = param_1.color;\n    gl_Position = mul(float4(param_1.world_pos, 1.0f), _96_view_proj);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = _96_cspace.xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _685_lit : packoffset(c0);\n    float4 _685_ambient : packoffset(c1);\n    float4 _685_normal_uv : packoffset(c2);\n    float4 _685_flat_ambient : packoffset(c3);\n    float4 _685_light_map : packoffset(c4);\n    float4 _685_light_pos[16] : packoffset(c5);\n    float4 _685_light_color[16] : packoffset(c21);\n    float4 _685_light_shadow_v[16] : packoffset(c37);\n    float4 _685_fog_col : packoffset(c53);\n    float4 _685_fog_b : packoffset(c54);\n    float4 _685_fog_c : packoffset(c55);\n    float4 _685_fog_eye : packoffset(c56);\n    float4 _685_fa_time : packoffset(c57);\n    float4 _685_fa_target : packoffset(c58);\n    float4 _685_fx_emit : packoffset(c59);\n    float4 _685_fx_emit_uv : packoffset(c60);\n    float4 _685_fx_rim : packoffset(c61);\n    float4 _685_fx_rim_uv : packoffset(c62);\n    float4 _685_light_cookie[16] : packoffset(c63);\n    float4 _685_light_cookie_xf[16] : packoffset(c79);\n    float4 _685_fa_scene : packoffset(c95);\n    float4 _685_fa_world_uv[3] : packoffset(c96);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> mask : register(t4);\nSamplerState mask_smp : register(s3);\nTexture2D<float4> fx_cookie_tex : register(t6);\nSamplerState light_smp : register(s1);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nTexture2D<float4> fx_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _622 = fa_linear_to_srgb(param);\n        c = _622;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _630 = fa_srgb_to_linear(param_1);\n            c = _630;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _641 = tex.Sample(smp, p);\n    float3 param = _641.xyz;\n    float param_1 = xform.y;\n    float3 _651 = fa_tex_fix(param, param_1);\n    return float4(_651, _641.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _131 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_131.x * 255.0f) + 0.5f) * 256.0f) + floor((_131.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _234 = floor(tt);\n    float _244 = _234 - (1024.0f * floor(_234 * 0.0009765625f));\n    float _247 = _244 + 1.0f;\n    float i1 = _247;\n    if (_247 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _244;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5f, 0.0f, 1.0f), tt - _234);\n}\n\nfloat light_shadow_soft(float v, float size, float2 d, float radius)\n{\n    float _284 = length(d);\n    float result = 1.0f;\n    if (_284 >= 9.9999997473787516355514526367188e-05f)\n    {\n        float _295 = atan2(d.y, d.x);\n        float a = _295;\n        float _298;\n        if (_295 < 0.0f)\n        {\n            _298 = a + 6.283185482025146484375f;\n        }\n        else\n        {\n            _298 = a;\n        }\n        a = _298;\n        float _308 = _298 * 162.9746551513671875f;\n        float _317 = min((size * 10.0f) / _284, 0.699999988079071044921875f) * 162.9746551513671875f;\n        float sum = 0.0f;\n        float n = 0.0f;\n        for (int k = 0; k < 12; k++)\n        {\n            float _343 = floor(_308 + ((((float(k) + 0.5f) * 0.16666667163372039794921875f) - 1.0f) * _317));\n            float param = v;\n            float param_1 = _343 - (1024.0f * floor(_343 * 0.0009765625f));\n            float _357 = shadow_texel(param, param_1) * radius;\n            if (_357 < _284)\n            {\n                sum += _357;\n                n += 1.0f;\n            }\n        }\n        if (n > 0.5f)\n        {\n            float _389 = min(size * ((1.0f / max(sum / n, 1.0f)) - (1.0f / _284)), 0.699999988079071044921875f) * 162.9746551513671875f;\n            float acc = 0.0f;\n            float wsum = 0.0f;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _407 = ((float(k_1) + 0.5f) * 0.125f) - 1.0f;\n                float _413 = 1.0f - (0.800000011920928955078125f * abs(_407));\n                float param_2 = v;\n                float param_3 = _308 + (_407 * _389);\n                float param_4 = _284;\n                float param_5 = radius;\n                acc += (_413 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _413;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _155 = length(d);\n    if (_155 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _169 = atan2(d.y, d.x);\n    float a = _169;\n    float _172;\n    if (_169 < 0.0f)\n    {\n        _172 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _172 = a;\n    }\n    a = _172;\n    float _184 = _172 * 162.9746551513671875f;\n    float _189 = min(floor(_184), 1023.0f);\n    float _196 = _189 + 1.0f;\n    float i1 = _196;\n    if (_196 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _189;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _155) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _155) + 0.5f, 0.0f, 1.0f), _184 - _189);\n}\n\nfloat light_shadow_sized(float v, float size, float2 d, float radius)\n{\n    float r = 1.0f;\n    if (size > 0.0f)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nfloat3 cookie_coord(float4 cell, float4 xf, float2 off)\n{\n    float2 _494 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _498 = _494.x + 0.5f;\n    float2 c = float2(_498, 0.5f - _494.y);\n    bool _506 = _498 >= 0.0f;\n    bool _512;\n    if (_506)\n    {\n        _512 = c.x <= 1.0f;\n    }\n    else\n    {\n        _512 = _506;\n    }\n    bool _518;\n    if (_512)\n    {\n        _518 = c.y >= 0.0f;\n    }\n    else\n    {\n        _518 = _512;\n    }\n    bool _524;\n    if (_518)\n    {\n        _524 = c.y <= 1.0f;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    float2 _526 = c;\n    float2 _531 = clamp(_526, 0.001953125f.xx, 0.998046875f.xx);\n    c = _531;\n    return float3(cell.x + (_531.x * cell.w), cell.y + (_531.y * cell.z), float(_524));\n}\n\nfloat cookie_value(float4 t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125f, 0.715200006961822509765625f, 0.072200000286102294921875f)) * t.w;\n}\n\nfloat cookie_att(int i, float2 d)\n{\n    if (_685_light_cookie[i].w == 0.0f)\n    {\n        return 1.0f;\n    }\n    float4 param = _685_light_cookie[i];\n    float4 param_1 = _685_light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _794 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.SampleLevel(light_smp, _794.xy, 0.0f);\n    return cookie_value(param_3) * _794.z;\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _816 = _685_lit.y > 0.5f;\n    if (_816)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _685_normal_uv.xy) + _685_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _840 = fa_tex_fix(param, param_1);\n        float3 _844 = (_840 * 2.0f) - 1.0f.xxx;\n        float _851 = cos(params.y);\n        float _853 = sin(params.y);\n        n = normalize(float3((float2(_851, _853) * _844.x) + ((float2(-_853, _851) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _844.y), max(_844.z, 0.0500000007450580596923828125f)));\n    }\n    bool _886 = !_816;\n    bool _892;\n    if (_886)\n    {\n        _892 = _685_lit.z > 0.5f;\n    }\n    else\n    {\n        _892 = _886;\n    }\n    float3 _895;\n    if (_892)\n    {\n        _895 = _685_flat_ambient.xyz;\n    }\n    else\n    {\n        _895 = _685_ambient.xyz;\n    }\n    float3 total = _895;\n    bool _912;\n    if (_892)\n    {\n        _912 = _685_lit.z < 1.5f;\n    }\n    else\n    {\n        _912 = _892;\n    }\n    if (_912)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _685_light_map.xy, 0.0f).xyz * _685_light_map.z);\n    }\n    float3 l;\n    float _1039;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _949;\n        if (!_892)\n        {\n            _949 = float(i) >= _685_lit.x;\n        }\n        else\n        {\n            _949 = _892;\n        }\n        if (_949)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_685_light_pos[i].w < 0.0f)\n        {\n            l = _685_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _975 = _685_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_975) / max(_685_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _685_light_color[i].w);\n            float3 _995 = float3(_975, _685_light_pos[i].z);\n            l = _995 / max(length(_995), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_685_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _685_light_shadow_v[i].x;\n                float param_3 = _685_light_shadow_v[i].y;\n                float2 param_4 = -_975;\n                float param_5 = _685_light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            float2 param_7 = -_975;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_816)\n        {\n            _1039 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _1039 = 1.0f;\n        }\n        total += (_685_light_color[i].xyz * (att * _1039));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _667 = fa_srgb_to_linear(param);\n        c = _667;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _1289 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _1293 = uv * _1289;\n    float _1299 = _1289.x;\n    float _1301 = _1289.y;\n    float _1303 = clamp(shape_rs.x, 0.0f, min(_1299, _1301));\n    float2 _1314 = (abs(_1293) - _1289) + _1303.xx;\n    float d = (length(max(_1314, 0.0f.xx)) + min(max(_1314.x, _1314.y), 0.0f)) - _1303;\n    float ax = params.y;\n    bool _1335 = params.y > 15.0f;\n    if (_1335)\n    {\n        ax -= 20.0f;\n    }\n    float _1346;\n    if (ax <= (-1.5f))\n    {\n        _1346 = (-2.0f) - ax;\n    }\n    else\n    {\n        _1346 = 0.0f;\n    }\n    if (_1346 > 0.0f)\n    {\n        float _1360 = _1346 * 0.5f;\n        d = abs(d + _1360) - _1360;\n    }\n    float _1368 = fwidth(d);\n    float _1369 = max(_1368, 9.9999997473787516355514526367188e-05f);\n    float _1379 = clamp(0.5f - (d / max(shape_rs.y, _1369)), 0.0f, 1.0f);\n    float _1384;\n    if (shape_rs.y > _1369)\n    {\n        _1384 = (_1379 * _1379) * (3.0f - (2.0f * _1379));\n    }\n    else\n    {\n        _1384 = _1379;\n    }\n    float4 c = color;\n    bool _1406 = (_1346 <= 0.0f) && (ax > (-0.5f));\n    if (_1406)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1421 = cos(ax);\n            float _1423 = sin(ax);\n            g = ((dot(_1293, float2(_1421, _1423)) / max((abs(_1421) * _1299) + (abs(_1423) * _1301), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_1335)\n        {\n            float4 _1466 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _1466;\n            float3 param = _1466.xyz;\n            float param_1 = xform.y;\n            float3 _1473 = fa_tex_fix(param, param_1);\n            float4 _2262 = c;\n            _2262.x = _1473.x;\n            _2262.y = _1473.y;\n            _2262.z = _1473.z;\n            c = _2262;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1485 = scene_rgb(param_2);\n            float4 _1510 = lerp(float4(color.xyz * color.w, color.w), float4(_1485 * color2.w, color2.w), g.xxxx);\n            float _1512 = _1510.w;\n            float3 _1515;\n            if (_1512 > 9.9999997473787516355514526367188e-06f)\n            {\n                _1515 = _1510.xyz / _1512.xxx;\n            }\n            else\n            {\n                _1515 = color.xyz;\n            }\n            c = float4(_1515, _1512);\n        }\n    }\n    float4 _2271 = c;\n    _2271.w = _2271.w * _1384;\n    c = _2271;\n    if (_1406 || (shape_rs.y > 0.0f))\n    {\n        float _1556 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1565 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1565 + (_1556 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1571 = fa_srgb_to_linear(param_4);\n            float4 _2274 = c;\n            _2274.x = _1571.x;\n            _2274.y = _1571.y;\n            _2274.z = _1571.z;\n            c = _2274;\n        }\n        else\n        {\n            float4 _1581 = c;\n            float3 _1584 = _1581.xyz + (_1556 * 0.0039215688593685626983642578125f).xxx;\n            float4 _2281 = _1581;\n            _2281.x = _1584.x;\n            _2281.y = _1584.y;\n            _2281.z = _1584.z;\n            c = _2281;\n        }\n        float4 _2286 = c;\n        _2286.w = clamp(_2286.w + ((_1556 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _2286.w)), 0.0f, 1.0f);\n        c = _2286;\n    }\n    return c;\n}\n\nfloat3 rim_color(float a0, float mode)\n{\n    float2 _1076 = float2(_685_fx_rim_uv.x, 0.0f);\n    float4 _1078 = tex.Sample(smp, uv - _1076);\n    float _1079 = _1078.w;\n    float4 _1089 = tex.Sample(smp, uv + _1076);\n    float _1090 = _1089.w;\n    float2 _1098 = float2(0.0f, _685_fx_rim_uv.y);\n    float4 _1100 = tex.Sample(smp, uv - _1098);\n    float _1101 = _1100.w;\n    float4 _1111 = tex.Sample(smp, uv + _1098);\n    float _1112 = _1111.w;\n    float _1127 = _1079 - _1090;\n    float _1130 = _1112 - _1101;\n    float _1140 = cos(params.y);\n    float _1142 = sin(params.y);\n    float2 _1168 = ((float2(_1140, _1142) * _1127) + ((float2(-_1142, _1140) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _1130)) / max(length(float2(_1127, _1130)), 9.9999997473787516355514526367188e-05f).xx;\n    float3 sum = 0.0f.xxx;\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _685_lit.x)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_685_light_pos[i].w < 0.0f)\n        {\n            to_l = _685_light_pos[i].xy / max(length(_685_light_pos[i].xy), 9.9999997473787516355514526367188e-05f).xx;\n        }\n        else\n        {\n            float2 _1214 = _685_light_pos[i].xy - world_xy;\n            float _1217 = length(_1214);\n            att = pow(clamp(1.0f - (_1217 / max(_685_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _685_light_color[i].w);\n            to_l = _1214 / max(_1217, 9.9999997473787516355514526367188e-05f).xx;\n            if (_685_light_shadow_v[i].x >= 0.0f)\n            {\n                float param = _685_light_shadow_v[i].x;\n                float param_1 = _685_light_shadow_v[i].y;\n                float2 param_2 = -_1214;\n                float param_3 = _685_light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1214;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (_685_light_color[i].xyz * (att * max(dot(_1168, to_l), 0.0f)));\n    }\n    return (sum * _685_fx_rim.xyz) * (a0 * (1.0f - min(min(_1079, _1090), min(_1101, _1112))));\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _691 = gl_FragCoord.xy * _685_fa_target.xy;\n    float _695 = _691.y;\n    return float2(_691.x, lerp(_695, 1.0f - _695, _685_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _733 = base_mode < 0.5f;\n    bool _744;\n    if (!_733)\n    {\n        _744 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _744 = _733;\n    }\n    float _745;\n    if (_744)\n    {\n        _745 = shape_half.x;\n    }\n    else\n    {\n        _745 = 0.0f;\n    }\n    QuadInput _2212 = { uv, color, world_xy, fa_screen_uv(), _685_fa_time.x, base_mode, 0.0f.xxxx, _745 };\n    return _2212;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float4 _765 = mask.Sample(mask_smp, float2(0.4000000059604644775390625f, 0.0500000007450580596923828125f));\n    s.color.x = _765.x;\n    s.color.y = _765.y;\n    s.color.z = _765.z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1611 = params.x > 31.5f;\n    if (_1611)\n    {\n        mode -= 32.0f;\n    }\n    float _1619 = mode;\n    bool _1621 = _1619 > 15.5f;\n    if (_1621)\n    {\n        mode -= 16.0f;\n    }\n    float _1629 = mode;\n    bool _1631 = _1629 > 7.5f;\n    if (_1631)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1621)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1621)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1693 = tex_color(param_5);\n                float4 _1695 = _1693 * color;\n                float4 param_6 = _1695;\n                float param_7 = mode;\n                float _1702 = _1695.w;\n                frag_color = float4(lit_color(param_6, param_7), _1702);\n                if (_685_fx_rim.w > 0.5f)\n                {\n                    float param_8 = _1702;\n                    float param_9 = mode;\n                    float4 _1718 = frag_color;\n                    float3 _1720 = _1718.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1720.x;\n                    frag_color.y = _1720.y;\n                    frag_color.z = _1720.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1750 = length(uv);\n                    float _1753 = fwidth(_1750);\n                    float _1754 = max(_1753, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1750) / _1754) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1750) / _1754) + 0.5f, 0.0f, 1.0f) * clamp(((_1750 - params.y) / _1754) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1794 = clamp(1.0f - _1750, 0.0f, 1.0f);\n                            cov = (_1794 * _1794) * (3.0f - (2.0f * _1794));\n                        }\n                    }\n                    float3 _1803;\n                    if (_1621)\n                    {\n                        float4 param_10 = color;\n                        float param_11 = 5.0f;\n                        _1803 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1803 = color.xyz;\n                    }\n                    frag_color = float4(_1803, color.w * cov);\n                }\n            }\n        }\n    }\n    if (_685_fx_emit.w > 0.5f)\n    {\n        float3 e = _685_fx_emit.xyz;\n        if (_685_fx_emit.w > 1.5f)\n        {\n            float3 param_12 = fx_emissive_tex.Sample(smp, (uv * _685_fx_emit_uv.xy) + _685_fx_emit_uv.zw).xyz;\n            float param_13 = _685_fx_emit.w - 2.0f;\n            float3 _1858 = fa_tex_fix(param_12, param_13);\n            e *= _1858;\n        }\n        float4 _1862 = frag_color;\n        float3 _1864 = _1862.xyz + e;\n        frag_color.x = _1864.x;\n        frag_color.y = _1864.y;\n        frag_color.z = _1864.z;\n    }\n    float param_14 = mode;\n    float4 _2192 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface _2194 = { _2192 };\n    QuadSurface param_16 = _2194;\n    fragment(param_15, param_16);\n    _2192 = param_16.color;\n    frag_color = param_16.color;\n    if (_1611)\n    {\n        float4 _1890 = frag_color;\n        float3 param_17 = color2.xyz;\n        float3 _1895 = scene_rgb(param_17);\n        float3 _1899 = lerp(_1890.xyz, _1895, color2.w.xxx);\n        frag_color.x = _1899.x;\n        frag_color.y = _1899.y;\n        frag_color.z = _1899.z;\n    }\n    if (_1631)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1923 = _685_fog_col.w > 0.0f;\n    bool _1931;\n    if (!_1923)\n    {\n        _1931 = _685_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1931 = _1923;\n    }\n    if (_1931)\n    {\n        float3 _1945 = float3(world_xy, world_z) - _685_fog_eye.xyz;\n        float _1952 = dot(_1945, _685_fog_c.xyz);\n        bool _1956 = _685_fog_c.w > 0.5f;\n        float _1957;\n        if (_1956)\n        {\n            _1957 = _1952;\n        }\n        else\n        {\n            _1957 = length(_1945);\n        }\n        float _1969 = _1957 - _685_fog_b.x;\n        if (_1969 > 0.0f)\n        {\n            float _1978 = _685_fog_col.w * _1969;\n            float tau = _1978 * _1978;\n            if (_685_fog_b.y > 0.0f)\n            {\n                float _1994;\n                if (_1956)\n                {\n                    _1994 = world_xy.y - (_685_fog_c.y * _1952);\n                }\n                else\n                {\n                    _1994 = _685_fog_eye.y;\n                }\n                float _2015 = lerp(_1994, world_xy.y, clamp(_685_fog_b.x / _1957, 0.0f, 1.0f));\n                float _2019 = world_xy.y - _2015;\n                float _2024 = _2015 - _685_fog_b.z;\n                float _2029 = world_xy.y - _685_fog_b.z;\n                bool _2032 = _2024 <= 0.0f;\n                bool _2033 = !_2032;\n                bool _2039;\n                if (_2033)\n                {\n                    _2039 = _685_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2039 = _2032;\n                }\n                float _2040;\n                if (_2039)\n                {\n                    _2040 = _685_fog_b.y;\n                }\n                else\n                {\n                    _2040 = _685_fog_b.y * exp(-min(_685_fog_b.w * _2024, 80.0f));\n                }\n                bool _2067;\n                if (_2033)\n                {\n                    _2067 = _685_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2067 = _2032;\n                }\n                float _2068;\n                if (_2067)\n                {\n                    _2068 = _685_fog_b.y * _2024;\n                }\n                else\n                {\n                    _2068 = (_685_fog_b.y * (1.0f - exp(-min(_685_fog_b.w * _2024, 80.0f)))) / _685_fog_b.w;\n                }\n                bool _2093 = _2029 <= 0.0f;\n                bool _2100;\n                if (!_2093)\n                {\n                    _2100 = _685_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2100 = _2093;\n                }\n                float _2101;\n                if (_2100)\n                {\n                    _2101 = _685_fog_b.y * _2029;\n                }\n                else\n                {\n                    _2101 = (_685_fog_b.y * (1.0f - exp(-min(_685_fog_b.w * _2029, 80.0f)))) / _685_fog_b.w;\n                }\n                float _2128;\n                if (abs(_2019) < 0.001000000047497451305389404296875f)\n                {\n                    _2128 = _2040;\n                }\n                else\n                {\n                    _2128 = (_2101 - _2068) / _2019;\n                }\n                tau += (_1969 * max(_2128, 0.0f));\n            }\n            float4 _2151 = frag_color;\n            float3 _2159 = lerp(_2151.xyz, _685_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _2159.x;\n            frag_color.y = _2159.y;\n            frag_color.z = _2159.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 1584,
            "struct_name": "quad_fs_params",
            "inst_name": "_685",
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
      "vs": "struct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\ncbuffer vs_params : register(b0)\n{\n    row_major float4x4 _96_view_proj : packoffset(c0);\n    float4 _96_cspace : packoffset(c4);\n    float4 _96_fa_time : packoffset(c5);\n};\n\nTexture2D<float4> fa_vs_mask : register(t0);\nSamplerState fa_vs_mask_smp : register(s7);\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += (fa_vs_mask.SampleLevel(fa_vs_mask_smp, float2(0.4000000059604644775390625f, 0.0500000007450580596923828125f), 0.0f).x * 40.0f);\n}\n\nvoid vert_main()\n{\n    float3 _171 = position;\n    float2 _172 = texcoord0;\n    float4 _173 = color0;\n    if (_96_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _108 = fa_srgb_to_linear(param);\n        float4 _185 = _173;\n        _185.x = _108.x;\n        _185.y = _108.y;\n        _185.z = _108.z;\n        _173 = _185;\n    }\n    QuadVertex _180 = { _171, _172, _173 };\n    QuadVertex param_1 = _180;\n    vertex(param_1);\n    _171 = param_1.world_pos;\n    _172 = param_1.uv;\n    _173 = param_1.color;\n    gl_Position = mul(float4(param_1.world_pos, 1.0f), _96_view_proj);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = _96_cspace.xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _131_lit : packoffset(c0);\n    float4 _131_ambient : packoffset(c1);\n    float4 _131_normal_uv : packoffset(c2);\n    float4 _131_flat_ambient : packoffset(c3);\n    float4 _131_light_map : packoffset(c4);\n    float4 _131_light_pos[16] : packoffset(c5);\n    float4 _131_light_color[16] : packoffset(c21);\n    float4 _131_light_shadow_v[16] : packoffset(c37);\n    float4 _131_fog_col : packoffset(c53);\n    float4 _131_fog_b : packoffset(c54);\n    float4 _131_fog_c : packoffset(c55);\n    float4 _131_fog_eye : packoffset(c56);\n    float4 _131_fa_time : packoffset(c57);\n    float4 _131_fa_target : packoffset(c58);\n    float4 _131_fx_emit : packoffset(c59);\n    float4 _131_fx_emit_uv : packoffset(c60);\n    float4 _131_fx_rim : packoffset(c61);\n    float4 _131_fx_rim_uv : packoffset(c62);\n    float4 _131_light_cookie[16] : packoffset(c63);\n    float4 _131_light_cookie_xf[16] : packoffset(c79);\n    float4 _131_fa_scene : packoffset(c95);\n    float4 _131_fa_world_uv[3] : packoffset(c96);\n};\n\nTexture2D<float4> mask : register(t1);\nSamplerState mask_smp : register(s3);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 frag_color;\nstatic float3 xform;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _138 = gl_FragCoord.xy * _131_fa_target.xy;\n    float _144 = _138.y;\n    return float2(_138.x, lerp(_144, 1.0f - _144, _131_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _188 = base_mode < 0.5f;\n    bool _199;\n    if (!_188)\n    {\n        _199 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _199 = _188;\n    }\n    float _200;\n    if (_199)\n    {\n        _200 = shape_half.x;\n    }\n    else\n    {\n        _200 = 0.0f;\n    }\n    QuadInput _327 = { uv, color, world_xy, fa_screen_uv(), _131_fa_time.x, base_mode, 0.0f.xxxx, _200 };\n    return _327;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float4 _226 = mask.Sample(mask_smp, float2(0.4000000059604644775390625f, 0.0500000007450580596923828125f));\n    s.color.x = _226.x;\n    s.color.y = _226.y;\n    s.color.z = _226.z;\n}\n\nvoid frag_main()\n{\n    float4 _241 = tex.Sample(smp, uv);\n    float3 param = _241.xyz;\n    float param_1 = xform.y;\n    float3 _252 = fa_tex_fix(param, param_1);\n    frag_color = float4(_252, _241.w) * color;\n    float param_2 = 0.0f;\n    float4 _307 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _309 = { _307 };\n    QuadSurface param_4 = _309;\n    fragment(param_3, param_4);\n    _307 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    xform = stage_input.xform;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 1584,
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
