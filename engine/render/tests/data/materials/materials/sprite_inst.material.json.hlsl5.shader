{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "c463ccd1917be78236231aa4aa6bc7a9036af5c2e4c419a950fb6e8c51e433a6",
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
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _701_lit : packoffset(c0);\n    float4 _701_ambient : packoffset(c1);\n    float4 _701_normal_uv : packoffset(c2);\n    float4 _701_flat_ambient : packoffset(c3);\n    float4 _701_light_map : packoffset(c4);\n    float4 _701_light_pos[16] : packoffset(c5);\n    float4 _701_light_color[16] : packoffset(c21);\n    float4 _701_light_shadow_v[16] : packoffset(c37);\n    float4 _701_fog_col : packoffset(c53);\n    float4 _701_fog_b : packoffset(c54);\n    float4 _701_fog_c : packoffset(c55);\n    float4 _701_fog_eye : packoffset(c56);\n    float4 _701_fa_time : packoffset(c57);\n    float4 _701_fa_target : packoffset(c58);\n    float4 _701_fx_emit : packoffset(c59);\n    float4 _701_fx_emit_uv : packoffset(c60);\n    float4 _701_fx_rim : packoffset(c61);\n    float4 _701_fx_rim_uv : packoffset(c62);\n    float4 _701_light_cookie[16] : packoffset(c63);\n    float4 _701_light_cookie_xf[16] : packoffset(c79);\n    float4 _701_gi_xf : packoffset(c95);\n    float4 _701_gi_p : packoffset(c96);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _786_boost : packoffset(c0);\n    float _786_fa_pad0 : packoffset(c0.y);\n    float _786_fa_pad1 : packoffset(c0.z);\n    float _786_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> fx_cookie_tex : register(t5);\nSamplerState light_smp : register(s1);\nTexture2D<float4> fx_gi_tex : register(t6);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nTexture2D<float4> fx_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation float4 fa_inst_v0 : TEXCOORD9;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD10;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nstatic float shift;\nstatic float4 tint;\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _634 = fa_linear_to_srgb(param);\n        c = _634;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _642 = fa_srgb_to_linear(param_1);\n            c = _642;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _653 = tex.Sample(smp, p);\n    float3 param = _653.xyz;\n    float param_1 = xform.y;\n    float3 _663 = fa_tex_fix(param, param_1);\n    return float4(_663, _653.w);\n}\n\nfloat3 gi_irradiance()\n{\n    float2 _851 = (world_xy * _701_gi_xf.xy) + _701_gi_xf.zw;\n    float4 _858 = fx_gi_tex.SampleLevel(light_smp, _851, 0.0f);\n    float _862 = _851.x;\n    bool _863 = _862 >= 0.0f;\n    bool _869;\n    if (_863)\n    {\n        _869 = _851.y >= 0.0f;\n    }\n    else\n    {\n        _869 = _863;\n    }\n    bool _875;\n    if (_869)\n    {\n        _875 = _862 <= 1.0f;\n    }\n    else\n    {\n        _875 = _869;\n    }\n    bool _881;\n    if (_875)\n    {\n        _881 = _851.y <= 1.0f;\n    }\n    else\n    {\n        _881 = _875;\n    }\n    bool _889;\n    if (_881)\n    {\n        _889 = _858.w > 0.0199999995529651641845703125f;\n    }\n    else\n    {\n        _889 = _881;\n    }\n    float3 _890;\n    if (_889)\n    {\n        _890 = (_858.xyz / _858.w.xxx) * _701_gi_p.x;\n    }\n    else\n    {\n        _890 = 0.0f.xxx;\n    }\n    return _890;\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _143 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_143.x * 255.0f) + 0.5f) * 256.0f) + floor((_143.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _246 = floor(tt);\n    float _256 = _246 - (1024.0f * floor(_246 * 0.0009765625f));\n    float _259 = _256 + 1.0f;\n    float i1 = _259;\n    if (_259 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _256;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5f, 0.0f, 1.0f), tt - _246);\n}\n\nfloat light_shadow_soft(float v, float size, float2 d, float radius)\n{\n    float _296 = length(d);\n    float result = 1.0f;\n    if (_296 >= 9.9999997473787516355514526367188e-05f)\n    {\n        float _307 = atan2(d.y, d.x);\n        float a = _307;\n        float _310;\n        if (_307 < 0.0f)\n        {\n            _310 = a + 6.283185482025146484375f;\n        }\n        else\n        {\n            _310 = a;\n        }\n        a = _310;\n        float _320 = _310 * 162.9746551513671875f;\n        float _329 = min((size * 10.0f) / _296, 0.699999988079071044921875f) * 162.9746551513671875f;\n        float sum = 0.0f;\n        float n = 0.0f;\n        for (int k = 0; k < 12; k++)\n        {\n            float _355 = floor(_320 + ((((float(k) + 0.5f) * 0.16666667163372039794921875f) - 1.0f) * _329));\n            float param = v;\n            float param_1 = _355 - (1024.0f * floor(_355 * 0.0009765625f));\n            float _369 = shadow_texel(param, param_1) * radius;\n            if (_369 < _296)\n            {\n                sum += _369;\n                n += 1.0f;\n            }\n        }\n        if (n > 0.5f)\n        {\n            float _401 = min(size * ((1.0f / max(sum / n, 1.0f)) - (1.0f / _296)), 0.699999988079071044921875f) * 162.9746551513671875f;\n            float acc = 0.0f;\n            float wsum = 0.0f;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _419 = ((float(k_1) + 0.5f) * 0.125f) - 1.0f;\n                float _425 = 1.0f - (0.800000011920928955078125f * abs(_419));\n                float param_2 = v;\n                float param_3 = _320 + (_419 * _401);\n                float param_4 = _296;\n                float param_5 = radius;\n                acc += (_425 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _425;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _167 = length(d);\n    if (_167 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _181 = atan2(d.y, d.x);\n    float a = _181;\n    float _184;\n    if (_181 < 0.0f)\n    {\n        _184 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _184 = a;\n    }\n    a = _184;\n    float _196 = _184 * 162.9746551513671875f;\n    float _201 = min(floor(_196), 1023.0f);\n    float _208 = _201 + 1.0f;\n    float i1 = _208;\n    if (_208 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _201;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _167) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _167) + 0.5f, 0.0f, 1.0f), _196 - _201);\n}\n\nfloat light_shadow_sized(float v, float size, float2 d, float radius)\n{\n    float r = 1.0f;\n    if (size > 0.0f)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nfloat3 cookie_coord(float4 cell, float4 xf, float2 off)\n{\n    float2 _506 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _510 = _506.x + 0.5f;\n    float2 c = float2(_510, 0.5f - _506.y);\n    bool _518 = _510 >= 0.0f;\n    bool _524;\n    if (_518)\n    {\n        _524 = c.x <= 1.0f;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    bool _530;\n    if (_524)\n    {\n        _530 = c.y >= 0.0f;\n    }\n    else\n    {\n        _530 = _524;\n    }\n    bool _536;\n    if (_530)\n    {\n        _536 = c.y <= 1.0f;\n    }\n    else\n    {\n        _536 = _530;\n    }\n    float2 _538 = c;\n    float2 _543 = clamp(_538, 0.001953125f.xx, 0.998046875f.xx);\n    c = _543;\n    return float3(cell.x + (_543.x * cell.w), cell.y + (_543.y * cell.z), float(_536));\n}\n\nfloat cookie_value(float4 t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125f, 0.715200006961822509765625f, 0.072200000286102294921875f)) * t.w;\n}\n\nfloat cookie_att(int i, float2 d)\n{\n    if (_701_light_cookie[i].w == 0.0f)\n    {\n        return 1.0f;\n    }\n    float4 param = _701_light_cookie[i];\n    float4 param_1 = _701_light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _825 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.SampleLevel(light_smp, _825.xy, 0.0f);\n    return cookie_value(param_3) * _825.z;\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _912 = _701_lit.y > 0.5f;\n    if (_912)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _701_normal_uv.xy) + _701_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _936 = fa_tex_fix(param, param_1);\n        float3 _940 = (_936 * 2.0f) - 1.0f.xxx;\n        float _947 = cos(params.y);\n        float _949 = sin(params.y);\n        n = normalize(float3((float2(_947, _949) * _940.x) + ((float2(-_949, _947) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _940.y), max(_940.z, 0.0500000007450580596923828125f)));\n    }\n    bool _983 = !_912;\n    bool _989;\n    if (_983)\n    {\n        _989 = _701_lit.z > 0.5f;\n    }\n    else\n    {\n        _989 = _983;\n    }\n    float3 _992;\n    if (_989)\n    {\n        _992 = _701_flat_ambient.xyz;\n    }\n    else\n    {\n        _992 = _701_ambient.xyz;\n    }\n    float3 total = _992;\n    if (_701_gi_p.x > 0.0f)\n    {\n        total += gi_irradiance();\n    }\n    bool _1017;\n    if (_989)\n    {\n        _1017 = _701_lit.z < 1.5f;\n    }\n    else\n    {\n        _1017 = _989;\n    }\n    if (_1017)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _701_light_map.xy, 0.0f).xyz * _701_light_map.z);\n    }\n    float3 l;\n    float _1144;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1054;\n        if (!_989)\n        {\n            _1054 = float(i) >= _701_lit.x;\n        }\n        else\n        {\n            _1054 = _989;\n        }\n        if (_1054)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_701_light_pos[i].w < 0.0f)\n        {\n            l = _701_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _1080 = _701_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_1080) / max(_701_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _701_light_color[i].w);\n            float3 _1100 = float3(_1080, _701_light_pos[i].z);\n            l = _1100 / max(length(_1100), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_701_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _701_light_shadow_v[i].x;\n                float param_3 = _701_light_shadow_v[i].y;\n                float2 param_4 = -_1080;\n                float param_5 = _701_light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            float2 param_7 = -_1080;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_912)\n        {\n            _1144 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _1144 = 1.0f;\n        }\n        total += (_701_light_color[i].xyz * (att * _1144));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _679 = fa_srgb_to_linear(param);\n        c = _679;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _1394 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _1398 = uv * _1394;\n    float _1404 = _1394.x;\n    float _1406 = _1394.y;\n    float _1408 = clamp(shape_rs.x, 0.0f, min(_1404, _1406));\n    float2 _1419 = (abs(_1398) - _1394) + _1408.xx;\n    float d = (length(max(_1419, 0.0f.xx)) + min(max(_1419.x, _1419.y), 0.0f)) - _1408;\n    float ax = params.y;\n    bool _1440 = params.y > 15.0f;\n    if (_1440)\n    {\n        ax -= 20.0f;\n    }\n    float _1451;\n    if (ax <= (-1.5f))\n    {\n        _1451 = (-2.0f) - ax;\n    }\n    else\n    {\n        _1451 = 0.0f;\n    }\n    if (_1451 > 0.0f)\n    {\n        float _1465 = _1451 * 0.5f;\n        d = abs(d + _1465) - _1465;\n    }\n    float _1473 = fwidth(d);\n    float _1474 = max(_1473, 9.9999997473787516355514526367188e-05f);\n    float _1484 = clamp(0.5f - (d / max(shape_rs.y, _1474)), 0.0f, 1.0f);\n    float _1489;\n    if (shape_rs.y > _1474)\n    {\n        _1489 = (_1484 * _1484) * (3.0f - (2.0f * _1484));\n    }\n    else\n    {\n        _1489 = _1484;\n    }\n    float4 c = color;\n    bool _1511 = (_1451 <= 0.0f) && (ax > (-0.5f));\n    if (_1511)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1526 = cos(ax);\n            float _1528 = sin(ax);\n            g = ((dot(_1398, float2(_1526, _1528)) / max((abs(_1526) * _1404) + (abs(_1528) * _1406), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_1440)\n        {\n            float4 _1571 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _1571;\n            float3 param = _1571.xyz;\n            float param_1 = xform.y;\n            float3 _1578 = fa_tex_fix(param, param_1);\n            float4 _2372 = c;\n            _2372.x = _1578.x;\n            _2372.y = _1578.y;\n            _2372.z = _1578.z;\n            c = _2372;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1590 = scene_rgb(param_2);\n            float4 _1615 = lerp(float4(color.xyz * color.w, color.w), float4(_1590 * color2.w, color2.w), g.xxxx);\n            float _1617 = _1615.w;\n            float3 _1620;\n            if (_1617 > 9.9999997473787516355514526367188e-06f)\n            {\n                _1620 = _1615.xyz / _1617.xxx;\n            }\n            else\n            {\n                _1620 = color.xyz;\n            }\n            c = float4(_1620, _1617);\n        }\n    }\n    float4 _2381 = c;\n    _2381.w = _2381.w * _1489;\n    c = _2381;\n    if (_1511 || (shape_rs.y > 0.0f))\n    {\n        float _1661 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1670 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1670 + (_1661 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1676 = fa_srgb_to_linear(param_4);\n            float4 _2384 = c;\n            _2384.x = _1676.x;\n            _2384.y = _1676.y;\n            _2384.z = _1676.z;\n            c = _2384;\n        }\n        else\n        {\n            float4 _1686 = c;\n            float3 _1689 = _1686.xyz + (_1661 * 0.0039215688593685626983642578125f).xxx;\n            float4 _2391 = _1686;\n            _2391.x = _1689.x;\n            _2391.y = _1689.y;\n            _2391.z = _1689.z;\n            c = _2391;\n        }\n        float4 _2396 = c;\n        _2396.w = clamp(_2396.w + ((_1661 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _2396.w)), 0.0f, 1.0f);\n        c = _2396;\n    }\n    return c;\n}\n\nfloat3 rim_color(float a0, float mode)\n{\n    float2 _1181 = float2(_701_fx_rim_uv.x, 0.0f);\n    float4 _1183 = tex.Sample(smp, uv - _1181);\n    float _1184 = _1183.w;\n    float4 _1194 = tex.Sample(smp, uv + _1181);\n    float _1195 = _1194.w;\n    float2 _1203 = float2(0.0f, _701_fx_rim_uv.y);\n    float4 _1205 = tex.Sample(smp, uv - _1203);\n    float _1206 = _1205.w;\n    float4 _1216 = tex.Sample(smp, uv + _1203);\n    float _1217 = _1216.w;\n    float _1232 = _1184 - _1195;\n    float _1235 = _1217 - _1206;\n    float _1245 = cos(params.y);\n    float _1247 = sin(params.y);\n    float2 _1273 = ((float2(_1245, _1247) * _1232) + ((float2(-_1247, _1245) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _1235)) / max(length(float2(_1232, _1235)), 9.9999997473787516355514526367188e-05f).xx;\n    float3 sum = 0.0f.xxx;\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _701_lit.x)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_701_light_pos[i].w < 0.0f)\n        {\n            to_l = _701_light_pos[i].xy / max(length(_701_light_pos[i].xy), 9.9999997473787516355514526367188e-05f).xx;\n        }\n        else\n        {\n            float2 _1319 = _701_light_pos[i].xy - world_xy;\n            float _1322 = length(_1319);\n            att = pow(clamp(1.0f - (_1322 / max(_701_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _701_light_color[i].w);\n            to_l = _1319 / max(_1322, 9.9999997473787516355514526367188e-05f).xx;\n            if (_701_light_shadow_v[i].x >= 0.0f)\n            {\n                float param = _701_light_shadow_v[i].x;\n                float param_1 = _701_light_shadow_v[i].y;\n                float2 param_2 = -_1319;\n                float param_3 = _701_light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1319;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (_701_light_color[i].xyz * (att * max(dot(_1273, to_l), 0.0f)));\n    }\n    return (sum * _701_fx_rim.xyz) * (a0 * (1.0f - min(min(_1184, _1195), min(_1206, _1217))));\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _707 = gl_FragCoord.xy * _701_fa_target.xy;\n    float _711 = _707.y;\n    return float2(_707.x, lerp(_711, 1.0f - _711, _701_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _749 = base_mode < 0.5f;\n    bool _760;\n    if (!_749)\n    {\n        _760 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _760 = _749;\n    }\n    float _761;\n    if (_760)\n    {\n        _761 = shape_half.x;\n    }\n    else\n    {\n        _761 = 0.0f;\n    }\n    QuadInput _2316 = { uv, color, world_xy, fa_screen_uv(), _701_fa_time.x, base_mode, 0.0f.xxxx, _761 };\n    return _2316;\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _685 = scene_rgb(param);\n    return _685;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = tint.xyz;\n    float3 _789 = fa_scene_rgb(param) * _786_boost;\n    s.color.x = _789.x;\n    s.color.y = _789.y;\n    s.color.z = _789.z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1716 = params.x > 31.5f;\n    if (_1716)\n    {\n        mode -= 32.0f;\n    }\n    float _1724 = mode;\n    bool _1726 = _1724 > 15.5f;\n    if (_1726)\n    {\n        mode -= 16.0f;\n    }\n    float _1734 = mode;\n    bool _1736 = _1734 > 7.5f;\n    if (_1736)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1726)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1726)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1798 = tex_color(param_5);\n                float4 _1800 = _1798 * color;\n                float4 param_6 = _1800;\n                float param_7 = mode;\n                float _1807 = _1800.w;\n                frag_color = float4(lit_color(param_6, param_7), _1807);\n                if (_701_fx_rim.w > 0.5f)\n                {\n                    float param_8 = _1807;\n                    float param_9 = mode;\n                    float4 _1823 = frag_color;\n                    float3 _1825 = _1823.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1825.x;\n                    frag_color.y = _1825.y;\n                    frag_color.z = _1825.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1855 = length(uv);\n                    float _1858 = fwidth(_1855);\n                    float _1859 = max(_1858, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1855) / _1859) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1855) / _1859) + 0.5f, 0.0f, 1.0f) * clamp(((_1855 - params.y) / _1859) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1899 = clamp(1.0f - _1855, 0.0f, 1.0f);\n                            cov = (_1899 * _1899) * (3.0f - (2.0f * _1899));\n                        }\n                    }\n                    float3 _1908;\n                    if (_1726)\n                    {\n                        float4 param_10 = color;\n                        float param_11 = 5.0f;\n                        _1908 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1908 = color.xyz;\n                    }\n                    frag_color = float4(_1908, color.w * cov);\n                }\n            }\n        }\n    }\n    if (_701_fx_emit.w > 0.5f)\n    {\n        float3 e = _701_fx_emit.xyz;\n        if (_701_fx_emit.w > 1.5f)\n        {\n            float3 param_12 = fx_emissive_tex.Sample(smp, (uv * _701_fx_emit_uv.xy) + _701_fx_emit_uv.zw).xyz;\n            float param_13 = _701_fx_emit.w - 2.0f;\n            float3 _1963 = fa_tex_fix(param_12, param_13);\n            e *= _1963;\n        }\n        float4 _1967 = frag_color;\n        float3 _1969 = _1967.xyz + e;\n        frag_color.x = _1969.x;\n        frag_color.y = _1969.y;\n        frag_color.z = _1969.z;\n    }\n    float param_14 = mode;\n    float4 _2296 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface _2298 = { _2296 };\n    QuadSurface param_16 = _2298;\n    fragment(param_15, param_16);\n    _2296 = param_16.color;\n    frag_color = param_16.color;\n    if (_1716)\n    {\n        float4 _1995 = frag_color;\n        float3 param_17 = color2.xyz;\n        float3 _2000 = scene_rgb(param_17);\n        float3 _2004 = lerp(_1995.xyz, _2000, color2.w.xxx);\n        frag_color.x = _2004.x;\n        frag_color.y = _2004.y;\n        frag_color.z = _2004.z;\n    }\n    if (_1736)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _2028 = _701_fog_col.w > 0.0f;\n    bool _2036;\n    if (!_2028)\n    {\n        _2036 = _701_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2036 = _2028;\n    }\n    if (_2036)\n    {\n        float3 _2050 = float3(world_xy, world_z) - _701_fog_eye.xyz;\n        float _2057 = dot(_2050, _701_fog_c.xyz);\n        bool _2061 = _701_fog_c.w > 0.5f;\n        float _2062;\n        if (_2061)\n        {\n            _2062 = _2057;\n        }\n        else\n        {\n            _2062 = length(_2050);\n        }\n        float _2074 = _2062 - _701_fog_b.x;\n        if (_2074 > 0.0f)\n        {\n            float _2083 = _701_fog_col.w * _2074;\n            float tau = _2083 * _2083;\n            if (_701_fog_b.y > 0.0f)\n            {\n                float _2099;\n                if (_2061)\n                {\n                    _2099 = world_xy.y - (_701_fog_c.y * _2057);\n                }\n                else\n                {\n                    _2099 = _701_fog_eye.y;\n                }\n                float _2120 = lerp(_2099, world_xy.y, clamp(_701_fog_b.x / _2062, 0.0f, 1.0f));\n                float _2124 = world_xy.y - _2120;\n                float _2129 = _2120 - _701_fog_b.z;\n                float _2134 = world_xy.y - _701_fog_b.z;\n                bool _2137 = _2129 <= 0.0f;\n                bool _2138 = !_2137;\n                bool _2144;\n                if (_2138)\n                {\n                    _2144 = _701_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2144 = _2137;\n                }\n                float _2145;\n                if (_2144)\n                {\n                    _2145 = _701_fog_b.y;\n                }\n                else\n                {\n                    _2145 = _701_fog_b.y * exp(-min(_701_fog_b.w * _2129, 80.0f));\n                }\n                bool _2172;\n                if (_2138)\n                {\n                    _2172 = _701_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2172 = _2137;\n                }\n                float _2173;\n                if (_2172)\n                {\n                    _2173 = _701_fog_b.y * _2129;\n                }\n                else\n                {\n                    _2173 = (_701_fog_b.y * (1.0f - exp(-min(_701_fog_b.w * _2129, 80.0f)))) / _701_fog_b.w;\n                }\n                bool _2198 = _2134 <= 0.0f;\n                bool _2205;\n                if (!_2198)\n                {\n                    _2205 = _701_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2205 = _2198;\n                }\n                float _2206;\n                if (_2205)\n                {\n                    _2206 = _701_fog_b.y * _2134;\n                }\n                else\n                {\n                    _2206 = (_701_fog_b.y * (1.0f - exp(-min(_701_fog_b.w * _2134, 80.0f)))) / _701_fog_b.w;\n                }\n                float _2233;\n                if (abs(_2124) < 0.001000000047497451305389404296875f)\n                {\n                    _2233 = _2145;\n                }\n                else\n                {\n                    _2233 = (_2206 - _2173) / _2124;\n                }\n                tau += (_2074 * max(_2233, 0.0f));\n            }\n            float4 _2256 = frag_color;\n            float3 _2264 = lerp(_2256.xyz, _701_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _2264.x;\n            frag_color.y = _2264.y;\n            frag_color.z = _2264.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 1552,
            "struct_name": "quad_fs_params",
            "inst_name": "_701",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_786",
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
      "vs": "struct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\ncbuffer vs_params : register(b0)\n{\n    row_major float4x4 _107_view_proj : packoffset(c0);\n    float4 _107_cspace : packoffset(c4);\n    float4 _107_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n    float4 fa_inst_d0 : TEXCOORD7;\n    float4 fa_inst_d1 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation float4 fa_inst_v0 : TEXCOORD9;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float shift;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += shift;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n    float3 _184 = position;\n    float2 _185 = texcoord0;\n    float4 _186 = color0;\n    if (_107_cspace.x > 0.5f)\n    {\n        float3 param_3 = color0.xyz;\n        float3 _119 = fa_srgb_to_linear(param_3);\n        float4 _198 = _186;\n        _198.x = _119.x;\n        _198.y = _119.y;\n        _198.z = _119.z;\n        _186 = _198;\n    }\n    QuadVertex _193 = { _184, _185, _186 };\n    QuadVertex param_4 = _193;\n    vertex(param_4);\n    _184 = param_4.world_pos;\n    _185 = param_4.uv;\n    _186 = param_4.color;\n    gl_Position = mul(float4(param_4.world_pos, 1.0f), _107_view_proj);\n    uv = param_4.uv;\n    color = param_4.color;\n    xform = _107_cspace.xyz;\n    params = params0;\n    world_xy = param_4.world_pos.xy;\n    world_z = param_4.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _162_lit : packoffset(c0);\n    float4 _162_ambient : packoffset(c1);\n    float4 _162_normal_uv : packoffset(c2);\n    float4 _162_flat_ambient : packoffset(c3);\n    float4 _162_light_map : packoffset(c4);\n    float4 _162_light_pos[16] : packoffset(c5);\n    float4 _162_light_color[16] : packoffset(c21);\n    float4 _162_light_shadow_v[16] : packoffset(c37);\n    float4 _162_fog_col : packoffset(c53);\n    float4 _162_fog_b : packoffset(c54);\n    float4 _162_fog_c : packoffset(c55);\n    float4 _162_fog_eye : packoffset(c56);\n    float4 _162_fa_time : packoffset(c57);\n    float4 _162_fa_target : packoffset(c58);\n    float4 _162_fx_emit : packoffset(c59);\n    float4 _162_fx_emit_uv : packoffset(c60);\n    float4 _162_fx_rim : packoffset(c61);\n    float4 _162_fx_rim_uv : packoffset(c62);\n    float4 _162_light_cookie[16] : packoffset(c63);\n    float4 _162_light_cookie_xf[16] : packoffset(c79);\n    float4 _162_gi_xf : packoffset(c95);\n    float4 _162_gi_p : packoffset(c96);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _254_boost : packoffset(c0);\n    float _254_fa_pad0 : packoffset(c0.y);\n    float _254_fa_pad1 : packoffset(c0.z);\n    float _254_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 frag_color;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation float4 fa_inst_v0 : TEXCOORD9;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD10;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nstatic float shift;\nstatic float4 tint;\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _114 = fa_linear_to_srgb(param);\n        c = _114;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _123 = fa_srgb_to_linear(param_1);\n            c = _123;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _169 = gl_FragCoord.xy * _162_fa_target.xy;\n    float _174 = _169.y;\n    return float2(_169.x, lerp(_174, 1.0f - _174, _162_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _217 = base_mode < 0.5f;\n    bool _228;\n    if (!_217)\n    {\n        _228 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _228 = _217;\n    }\n    float _229;\n    if (_228)\n    {\n        _229 = shape_half.x;\n    }\n    else\n    {\n        _229 = 0.0f;\n    }\n    QuadInput _367 = { uv, color, world_xy, fa_screen_uv(), _162_fa_time.x, base_mode, 0.0f.xxxx, _229 };\n    return _367;\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _139 = fa_srgb_to_linear(param);\n        c = _139;\n    }\n    return c;\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _145 = scene_rgb(param);\n    return _145;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = tint.xyz;\n    float3 _257 = fa_scene_rgb(param) * _254_boost;\n    s.color.x = _257.x;\n    s.color.y = _257.y;\n    s.color.z = _257.z;\n}\n\nvoid frag_main()\n{\n    float4 _284 = tex.Sample(smp, uv);\n    float3 param = _284.xyz;\n    float param_1 = xform.y;\n    float3 _293 = fa_tex_fix(param, param_1);\n    frag_color = float4(_293, _284.w) * color;\n    float param_2 = 0.0f;\n    float4 _347 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _349 = { _347 };\n    QuadSurface param_4 = _349;\n    fragment(param_3, param_4);\n    _347 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 1552,
            "struct_name": "quad_fs_params",
            "inst_name": "_162",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_254",
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
