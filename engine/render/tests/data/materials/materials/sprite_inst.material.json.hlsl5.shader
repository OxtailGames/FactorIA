{
  "format": "factoria.shader/1",
  "engine": "0.35.2",
  "template": "d75bc1c2988d2355d3b6c4618a7c68ff76094f3e9d32765c88b7244d10541da4",
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
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _702_lit : packoffset(c0);\n    float4 _702_ambient : packoffset(c1);\n    float4 _702_normal_uv : packoffset(c2);\n    float4 _702_flat_ambient : packoffset(c3);\n    float4 _702_light_map : packoffset(c4);\n    float4 _702_light_pos[16] : packoffset(c5);\n    float4 _702_light_color[16] : packoffset(c21);\n    float4 _702_light_shadow_v[16] : packoffset(c37);\n    float4 _702_fog_col : packoffset(c53);\n    float4 _702_fog_b : packoffset(c54);\n    float4 _702_fog_c : packoffset(c55);\n    float4 _702_fog_eye : packoffset(c56);\n    float4 _702_fa_time : packoffset(c57);\n    float4 _702_fa_target : packoffset(c58);\n    float4 _702_fx_emit : packoffset(c59);\n    float4 _702_fx_emit_uv : packoffset(c60);\n    float4 _702_fx_rim : packoffset(c61);\n    float4 _702_fx_rim_uv : packoffset(c62);\n    float4 _702_light_cookie[16] : packoffset(c63);\n    float4 _702_light_cookie_xf[16] : packoffset(c79);\n    float4 _702_fa_scene : packoffset(c95);\n    float4 _702_fa_world_uv[3] : packoffset(c96);\n    float4 _702_gi_xf : packoffset(c99);\n    float4 _702_gi_p : packoffset(c100);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _787_boost : packoffset(c0);\n    float _787_fa_pad0 : packoffset(c0.y);\n    float _787_fa_pad1 : packoffset(c0.z);\n    float _787_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> fx_cookie_tex : register(t5);\nSamplerState light_smp : register(s1);\nTexture2D<float4> fx_gi_tex : register(t6);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nTexture2D<float4> fx_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation float4 fa_inst_v0 : TEXCOORD9;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD10;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nstatic float shift;\nstatic float4 tint;\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _634 = fa_linear_to_srgb(param);\n        c = _634;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _642 = fa_srgb_to_linear(param_1);\n            c = _642;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _653 = tex.Sample(smp, p);\n    float3 param = _653.xyz;\n    float param_1 = xform.y;\n    float3 _663 = fa_tex_fix(param, param_1);\n    return float4(_663, _653.w);\n}\n\nfloat3 gi_irradiance()\n{\n    float2 _852 = (world_xy * _702_gi_xf.xy) + _702_gi_xf.zw;\n    float4 _859 = fx_gi_tex.SampleLevel(light_smp, _852, 0.0f);\n    float _863 = _852.x;\n    bool _864 = _863 >= 0.0f;\n    bool _870;\n    if (_864)\n    {\n        _870 = _852.y >= 0.0f;\n    }\n    else\n    {\n        _870 = _864;\n    }\n    bool _876;\n    if (_870)\n    {\n        _876 = _863 <= 1.0f;\n    }\n    else\n    {\n        _876 = _870;\n    }\n    bool _882;\n    if (_876)\n    {\n        _882 = _852.y <= 1.0f;\n    }\n    else\n    {\n        _882 = _876;\n    }\n    bool _890;\n    if (_882)\n    {\n        _890 = _859.w > 0.0199999995529651641845703125f;\n    }\n    else\n    {\n        _890 = _882;\n    }\n    float3 _891;\n    if (_890)\n    {\n        _891 = (_859.xyz / _859.w.xxx) * _702_gi_p.x;\n    }\n    else\n    {\n        _891 = 0.0f.xxx;\n    }\n    return _891;\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _143 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_143.x * 255.0f) + 0.5f) * 256.0f) + floor((_143.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _246 = floor(tt);\n    float _256 = _246 - (1024.0f * floor(_246 * 0.0009765625f));\n    float _259 = _256 + 1.0f;\n    float i1 = _259;\n    if (_259 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _256;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5f, 0.0f, 1.0f), tt - _246);\n}\n\nfloat light_shadow_soft(float v, float size, float2 d, float radius)\n{\n    float _296 = length(d);\n    float result = 1.0f;\n    if (_296 >= 9.9999997473787516355514526367188e-05f)\n    {\n        float _307 = atan2(d.y, d.x);\n        float a = _307;\n        float _310;\n        if (_307 < 0.0f)\n        {\n            _310 = a + 6.283185482025146484375f;\n        }\n        else\n        {\n            _310 = a;\n        }\n        a = _310;\n        float _320 = _310 * 162.9746551513671875f;\n        float _329 = min((size * 10.0f) / _296, 0.699999988079071044921875f) * 162.9746551513671875f;\n        float sum = 0.0f;\n        float n = 0.0f;\n        for (int k = 0; k < 12; k++)\n        {\n            float _355 = floor(_320 + ((((float(k) + 0.5f) * 0.16666667163372039794921875f) - 1.0f) * _329));\n            float param = v;\n            float param_1 = _355 - (1024.0f * floor(_355 * 0.0009765625f));\n            float _369 = shadow_texel(param, param_1) * radius;\n            if (_369 < _296)\n            {\n                sum += _369;\n                n += 1.0f;\n            }\n        }\n        if (n > 0.5f)\n        {\n            float _401 = min(size * ((1.0f / max(sum / n, 1.0f)) - (1.0f / _296)), 0.699999988079071044921875f) * 162.9746551513671875f;\n            float acc = 0.0f;\n            float wsum = 0.0f;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _419 = ((float(k_1) + 0.5f) * 0.125f) - 1.0f;\n                float _425 = 1.0f - (0.800000011920928955078125f * abs(_419));\n                float param_2 = v;\n                float param_3 = _320 + (_419 * _401);\n                float param_4 = _296;\n                float param_5 = radius;\n                acc += (_425 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _425;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _167 = length(d);\n    if (_167 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _181 = atan2(d.y, d.x);\n    float a = _181;\n    float _184;\n    if (_181 < 0.0f)\n    {\n        _184 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _184 = a;\n    }\n    a = _184;\n    float _196 = _184 * 162.9746551513671875f;\n    float _201 = min(floor(_196), 1023.0f);\n    float _208 = _201 + 1.0f;\n    float i1 = _208;\n    if (_208 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _201;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _167) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _167) + 0.5f, 0.0f, 1.0f), _196 - _201);\n}\n\nfloat light_shadow_sized(float v, float size, float2 d, float radius)\n{\n    float r = 1.0f;\n    if (size > 0.0f)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nfloat3 cookie_coord(float4 cell, float4 xf, float2 off)\n{\n    float2 _506 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _510 = _506.x + 0.5f;\n    float2 c = float2(_510, 0.5f - _506.y);\n    bool _518 = _510 >= 0.0f;\n    bool _524;\n    if (_518)\n    {\n        _524 = c.x <= 1.0f;\n    }\n    else\n    {\n        _524 = _518;\n    }\n    bool _530;\n    if (_524)\n    {\n        _530 = c.y >= 0.0f;\n    }\n    else\n    {\n        _530 = _524;\n    }\n    bool _536;\n    if (_530)\n    {\n        _536 = c.y <= 1.0f;\n    }\n    else\n    {\n        _536 = _530;\n    }\n    float2 _538 = c;\n    float2 _543 = clamp(_538, 0.001953125f.xx, 0.998046875f.xx);\n    c = _543;\n    return float3(cell.x + (_543.x * cell.w), cell.y + (_543.y * cell.z), float(_536));\n}\n\nfloat cookie_value(float4 t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125f, 0.715200006961822509765625f, 0.072200000286102294921875f)) * t.w;\n}\n\nfloat cookie_att(int i, float2 d)\n{\n    if (_702_light_cookie[i].w == 0.0f)\n    {\n        return 1.0f;\n    }\n    float4 param = _702_light_cookie[i];\n    float4 param_1 = _702_light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _826 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.SampleLevel(light_smp, _826.xy, 0.0f);\n    return cookie_value(param_3) * _826.z;\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _913 = _702_lit.y > 0.5f;\n    if (_913)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _702_normal_uv.xy) + _702_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _937 = fa_tex_fix(param, param_1);\n        float3 _941 = (_937 * 2.0f) - 1.0f.xxx;\n        float _948 = cos(params.y);\n        float _950 = sin(params.y);\n        n = normalize(float3((float2(_948, _950) * _941.x) + ((float2(-_950, _948) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _941.y), max(_941.z, 0.0500000007450580596923828125f)));\n    }\n    bool _984 = !_913;\n    bool _990;\n    if (_984)\n    {\n        _990 = _702_lit.z > 0.5f;\n    }\n    else\n    {\n        _990 = _984;\n    }\n    float3 _993;\n    if (_990)\n    {\n        _993 = _702_flat_ambient.xyz;\n    }\n    else\n    {\n        _993 = _702_ambient.xyz;\n    }\n    float3 total = _993;\n    if (_702_gi_p.x > 0.0f)\n    {\n        total += gi_irradiance();\n    }\n    bool _1018;\n    if (_990)\n    {\n        _1018 = _702_lit.z < 1.5f;\n    }\n    else\n    {\n        _1018 = _990;\n    }\n    if (_1018)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _702_light_map.xy, 0.0f).xyz * _702_light_map.z);\n    }\n    float3 l;\n    float _1145;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _1055;\n        if (!_990)\n        {\n            _1055 = float(i) >= _702_lit.x;\n        }\n        else\n        {\n            _1055 = _990;\n        }\n        if (_1055)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_702_light_pos[i].w < 0.0f)\n        {\n            l = _702_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _1081 = _702_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_1081) / max(_702_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _702_light_color[i].w);\n            float3 _1101 = float3(_1081, _702_light_pos[i].z);\n            l = _1101 / max(length(_1101), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_702_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _702_light_shadow_v[i].x;\n                float param_3 = _702_light_shadow_v[i].y;\n                float2 param_4 = -_1081;\n                float param_5 = _702_light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n            int param_6 = i;\n            float2 param_7 = -_1081;\n            att *= cookie_att(param_6, param_7);\n        }\n        if (_913)\n        {\n            _1145 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _1145 = 1.0f;\n        }\n        total += (_702_light_color[i].xyz * (att * _1145));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _679 = fa_srgb_to_linear(param);\n        c = _679;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _1395 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _1399 = uv * _1395;\n    float _1405 = _1395.x;\n    float _1407 = _1395.y;\n    float _1409 = clamp(shape_rs.x, 0.0f, min(_1405, _1407));\n    float2 _1420 = (abs(_1399) - _1395) + _1409.xx;\n    float d = (length(max(_1420, 0.0f.xx)) + min(max(_1420.x, _1420.y), 0.0f)) - _1409;\n    float ax = params.y;\n    bool _1441 = params.y > 15.0f;\n    if (_1441)\n    {\n        ax -= 20.0f;\n    }\n    float _1452;\n    if (ax <= (-1.5f))\n    {\n        _1452 = (-2.0f) - ax;\n    }\n    else\n    {\n        _1452 = 0.0f;\n    }\n    if (_1452 > 0.0f)\n    {\n        float _1466 = _1452 * 0.5f;\n        d = abs(d + _1466) - _1466;\n    }\n    float _1474 = fwidth(d);\n    float _1475 = max(_1474, 9.9999997473787516355514526367188e-05f);\n    float _1485 = clamp(0.5f - (d / max(shape_rs.y, _1475)), 0.0f, 1.0f);\n    float _1490;\n    if (shape_rs.y > _1475)\n    {\n        _1490 = (_1485 * _1485) * (3.0f - (2.0f * _1485));\n    }\n    else\n    {\n        _1490 = _1485;\n    }\n    float4 c = color;\n    bool _1512 = (_1452 <= 0.0f) && (ax > (-0.5f));\n    if (_1512)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1527 = cos(ax);\n            float _1529 = sin(ax);\n            g = ((dot(_1399, float2(_1527, _1529)) / max((abs(_1527) * _1405) + (abs(_1529) * _1407), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_1441)\n        {\n            float4 _1572 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _1572;\n            float3 param = _1572.xyz;\n            float param_1 = xform.y;\n            float3 _1579 = fa_tex_fix(param, param_1);\n            float4 _2374 = c;\n            _2374.x = _1579.x;\n            _2374.y = _1579.y;\n            _2374.z = _1579.z;\n            c = _2374;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1591 = scene_rgb(param_2);\n            float4 _1616 = lerp(float4(color.xyz * color.w, color.w), float4(_1591 * color2.w, color2.w), g.xxxx);\n            float _1618 = _1616.w;\n            float3 _1621;\n            if (_1618 > 9.9999997473787516355514526367188e-06f)\n            {\n                _1621 = _1616.xyz / _1618.xxx;\n            }\n            else\n            {\n                _1621 = color.xyz;\n            }\n            c = float4(_1621, _1618);\n        }\n    }\n    float4 _2383 = c;\n    _2383.w = _2383.w * _1490;\n    c = _2383;\n    if (_1512 || (shape_rs.y > 0.0f))\n    {\n        float _1662 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1671 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1671 + (_1662 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1677 = fa_srgb_to_linear(param_4);\n            float4 _2386 = c;\n            _2386.x = _1677.x;\n            _2386.y = _1677.y;\n            _2386.z = _1677.z;\n            c = _2386;\n        }\n        else\n        {\n            float4 _1687 = c;\n            float3 _1690 = _1687.xyz + (_1662 * 0.0039215688593685626983642578125f).xxx;\n            float4 _2393 = _1687;\n            _2393.x = _1690.x;\n            _2393.y = _1690.y;\n            _2393.z = _1690.z;\n            c = _2393;\n        }\n        float4 _2398 = c;\n        _2398.w = clamp(_2398.w + ((_1662 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _2398.w)), 0.0f, 1.0f);\n        c = _2398;\n    }\n    return c;\n}\n\nfloat3 rim_color(float a0, float mode)\n{\n    float2 _1182 = float2(_702_fx_rim_uv.x, 0.0f);\n    float4 _1184 = tex.Sample(smp, uv - _1182);\n    float _1185 = _1184.w;\n    float4 _1195 = tex.Sample(smp, uv + _1182);\n    float _1196 = _1195.w;\n    float2 _1204 = float2(0.0f, _702_fx_rim_uv.y);\n    float4 _1206 = tex.Sample(smp, uv - _1204);\n    float _1207 = _1206.w;\n    float4 _1217 = tex.Sample(smp, uv + _1204);\n    float _1218 = _1217.w;\n    float _1233 = _1185 - _1196;\n    float _1236 = _1218 - _1207;\n    float _1246 = cos(params.y);\n    float _1248 = sin(params.y);\n    float2 _1274 = ((float2(_1246, _1248) * _1233) + ((float2(-_1248, _1246) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _1236)) / max(length(float2(_1233, _1236)), 9.9999997473787516355514526367188e-05f).xx;\n    float3 sum = 0.0f.xxx;\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _702_lit.x)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_702_light_pos[i].w < 0.0f)\n        {\n            to_l = _702_light_pos[i].xy / max(length(_702_light_pos[i].xy), 9.9999997473787516355514526367188e-05f).xx;\n        }\n        else\n        {\n            float2 _1320 = _702_light_pos[i].xy - world_xy;\n            float _1323 = length(_1320);\n            att = pow(clamp(1.0f - (_1323 / max(_702_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _702_light_color[i].w);\n            to_l = _1320 / max(_1323, 9.9999997473787516355514526367188e-05f).xx;\n            if (_702_light_shadow_v[i].x >= 0.0f)\n            {\n                float param = _702_light_shadow_v[i].x;\n                float param_1 = _702_light_shadow_v[i].y;\n                float2 param_2 = -_1320;\n                float param_3 = _702_light_pos[i].w;\n                att *= light_shadow_sized(param, param_1, param_2, param_3);\n            }\n            int param_4 = i;\n            float2 param_5 = -_1320;\n            att *= cookie_att(param_4, param_5);\n        }\n        sum += (_702_light_color[i].xyz * (att * max(dot(_1274, to_l), 0.0f)));\n    }\n    return (sum * _702_fx_rim.xyz) * (a0 * (1.0f - min(min(_1185, _1196), min(_1207, _1218))));\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _708 = gl_FragCoord.xy * _702_fa_target.xy;\n    float _712 = _708.y;\n    return float2(_708.x, lerp(_712, 1.0f - _712, _702_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _750 = base_mode < 0.5f;\n    bool _761;\n    if (!_750)\n    {\n        _761 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _761 = _750;\n    }\n    float _762;\n    if (_761)\n    {\n        _762 = shape_half.x;\n    }\n    else\n    {\n        _762 = 0.0f;\n    }\n    QuadInput _2318 = { uv, color, world_xy, fa_screen_uv(), _702_fa_time.x, base_mode, 0.0f.xxxx, _762 };\n    return _2318;\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _685 = scene_rgb(param);\n    return _685;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = tint.xyz;\n    float3 _790 = fa_scene_rgb(param) * _787_boost;\n    s.color.x = _790.x;\n    s.color.y = _790.y;\n    s.color.z = _790.z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1717 = params.x > 31.5f;\n    if (_1717)\n    {\n        mode -= 32.0f;\n    }\n    float _1725 = mode;\n    bool _1727 = _1725 > 15.5f;\n    if (_1727)\n    {\n        mode -= 16.0f;\n    }\n    float _1735 = mode;\n    bool _1737 = _1735 > 7.5f;\n    if (_1737)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1727)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1727)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1799 = tex_color(param_5);\n                float4 _1801 = _1799 * color;\n                float4 param_6 = _1801;\n                float param_7 = mode;\n                float _1808 = _1801.w;\n                frag_color = float4(lit_color(param_6, param_7), _1808);\n                if (_702_fx_rim.w > 0.5f)\n                {\n                    float param_8 = _1808;\n                    float param_9 = mode;\n                    float4 _1824 = frag_color;\n                    float3 _1826 = _1824.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1826.x;\n                    frag_color.y = _1826.y;\n                    frag_color.z = _1826.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1856 = length(uv);\n                    float _1859 = fwidth(_1856);\n                    float _1860 = max(_1859, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1856) / _1860) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1856) / _1860) + 0.5f, 0.0f, 1.0f) * clamp(((_1856 - params.y) / _1860) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1900 = clamp(1.0f - _1856, 0.0f, 1.0f);\n                            cov = (_1900 * _1900) * (3.0f - (2.0f * _1900));\n                        }\n                    }\n                    float3 _1909;\n                    if (_1727)\n                    {\n                        float4 param_10 = color;\n                        float param_11 = 5.0f;\n                        _1909 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1909 = color.xyz;\n                    }\n                    frag_color = float4(_1909, color.w * cov);\n                }\n            }\n        }\n    }\n    if (_702_fx_emit.w > 0.5f)\n    {\n        float3 e = _702_fx_emit.xyz;\n        if (_702_fx_emit.w > 1.5f)\n        {\n            float3 param_12 = fx_emissive_tex.Sample(smp, (uv * _702_fx_emit_uv.xy) + _702_fx_emit_uv.zw).xyz;\n            float param_13 = _702_fx_emit.w - 2.0f;\n            float3 _1964 = fa_tex_fix(param_12, param_13);\n            e *= _1964;\n        }\n        float4 _1968 = frag_color;\n        float3 _1970 = _1968.xyz + e;\n        frag_color.x = _1970.x;\n        frag_color.y = _1970.y;\n        frag_color.z = _1970.z;\n    }\n    float param_14 = mode;\n    float4 _2298 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface _2300 = { _2298 };\n    QuadSurface param_16 = _2300;\n    fragment(param_15, param_16);\n    _2298 = param_16.color;\n    frag_color = param_16.color;\n    if (_1717)\n    {\n        float4 _1996 = frag_color;\n        float3 param_17 = color2.xyz;\n        float3 _2001 = scene_rgb(param_17);\n        float3 _2005 = lerp(_1996.xyz, _2001, color2.w.xxx);\n        frag_color.x = _2005.x;\n        frag_color.y = _2005.y;\n        frag_color.z = _2005.z;\n    }\n    if (_1737)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _2029 = _702_fog_col.w > 0.0f;\n    bool _2037;\n    if (!_2029)\n    {\n        _2037 = _702_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _2037 = _2029;\n    }\n    if (_2037)\n    {\n        float3 _2051 = float3(world_xy, world_z) - _702_fog_eye.xyz;\n        float _2058 = dot(_2051, _702_fog_c.xyz);\n        bool _2062 = _702_fog_c.w > 0.5f;\n        float _2063;\n        if (_2062)\n        {\n            _2063 = _2058;\n        }\n        else\n        {\n            _2063 = length(_2051);\n        }\n        float _2075 = _2063 - _702_fog_b.x;\n        if (_2075 > 0.0f)\n        {\n            float _2084 = _702_fog_col.w * _2075;\n            float tau = _2084 * _2084;\n            if (_702_fog_b.y > 0.0f)\n            {\n                float _2100;\n                if (_2062)\n                {\n                    _2100 = world_xy.y - (_702_fog_c.y * _2058);\n                }\n                else\n                {\n                    _2100 = _702_fog_eye.y;\n                }\n                float _2121 = lerp(_2100, world_xy.y, clamp(_702_fog_b.x / _2063, 0.0f, 1.0f));\n                float _2125 = world_xy.y - _2121;\n                float _2130 = _2121 - _702_fog_b.z;\n                float _2135 = world_xy.y - _702_fog_b.z;\n                bool _2138 = _2130 <= 0.0f;\n                bool _2139 = !_2138;\n                bool _2145;\n                if (_2139)\n                {\n                    _2145 = _702_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2145 = _2138;\n                }\n                float _2146;\n                if (_2145)\n                {\n                    _2146 = _702_fog_b.y;\n                }\n                else\n                {\n                    _2146 = _702_fog_b.y * exp(-min(_702_fog_b.w * _2130, 80.0f));\n                }\n                bool _2173;\n                if (_2139)\n                {\n                    _2173 = _702_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2173 = _2138;\n                }\n                float _2174;\n                if (_2173)\n                {\n                    _2174 = _702_fog_b.y * _2130;\n                }\n                else\n                {\n                    _2174 = (_702_fog_b.y * (1.0f - exp(-min(_702_fog_b.w * _2130, 80.0f)))) / _702_fog_b.w;\n                }\n                bool _2199 = _2135 <= 0.0f;\n                bool _2206;\n                if (!_2199)\n                {\n                    _2206 = _702_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _2206 = _2199;\n                }\n                float _2207;\n                if (_2206)\n                {\n                    _2207 = _702_fog_b.y * _2135;\n                }\n                else\n                {\n                    _2207 = (_702_fog_b.y * (1.0f - exp(-min(_702_fog_b.w * _2135, 80.0f)))) / _702_fog_b.w;\n                }\n                float _2234;\n                if (abs(_2125) < 0.001000000047497451305389404296875f)\n                {\n                    _2234 = _2146;\n                }\n                else\n                {\n                    _2234 = (_2207 - _2174) / _2125;\n                }\n                tau += (_2075 * max(_2234, 0.0f));\n            }\n            float4 _2257 = frag_color;\n            float3 _2265 = lerp(_2257.xyz, _702_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _2265.x;\n            frag_color.y = _2265.y;\n            frag_color.z = _2265.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 1616,
            "struct_name": "quad_fs_params",
            "inst_name": "_702",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_787",
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
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _164_lit : packoffset(c0);\n    float4 _164_ambient : packoffset(c1);\n    float4 _164_normal_uv : packoffset(c2);\n    float4 _164_flat_ambient : packoffset(c3);\n    float4 _164_light_map : packoffset(c4);\n    float4 _164_light_pos[16] : packoffset(c5);\n    float4 _164_light_color[16] : packoffset(c21);\n    float4 _164_light_shadow_v[16] : packoffset(c37);\n    float4 _164_fog_col : packoffset(c53);\n    float4 _164_fog_b : packoffset(c54);\n    float4 _164_fog_c : packoffset(c55);\n    float4 _164_fog_eye : packoffset(c56);\n    float4 _164_fa_time : packoffset(c57);\n    float4 _164_fa_target : packoffset(c58);\n    float4 _164_fx_emit : packoffset(c59);\n    float4 _164_fx_emit_uv : packoffset(c60);\n    float4 _164_fx_rim : packoffset(c61);\n    float4 _164_fx_rim_uv : packoffset(c62);\n    float4 _164_light_cookie[16] : packoffset(c63);\n    float4 _164_light_cookie_xf[16] : packoffset(c79);\n    float4 _164_fa_scene : packoffset(c95);\n    float4 _164_fa_world_uv[3] : packoffset(c96);\n    float4 _164_gi_xf : packoffset(c99);\n    float4 _164_gi_p : packoffset(c100);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _256_boost : packoffset(c0);\n    float _256_fa_pad0 : packoffset(c0.y);\n    float _256_fa_pad1 : packoffset(c0.z);\n    float _256_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 frag_color;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation float4 fa_inst_v0 : TEXCOORD9;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD10;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nstatic float shift;\nstatic float4 tint;\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _114 = fa_linear_to_srgb(param);\n        c = _114;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _123 = fa_srgb_to_linear(param_1);\n            c = _123;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _171 = gl_FragCoord.xy * _164_fa_target.xy;\n    float _176 = _171.y;\n    return float2(_171.x, lerp(_176, 1.0f - _176, _164_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _219 = base_mode < 0.5f;\n    bool _230;\n    if (!_219)\n    {\n        _230 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _230 = _219;\n    }\n    float _231;\n    if (_230)\n    {\n        _231 = shape_half.x;\n    }\n    else\n    {\n        _231 = 0.0f;\n    }\n    QuadInput _370 = { uv, color, world_xy, fa_screen_uv(), _164_fa_time.x, base_mode, 0.0f.xxxx, _231 };\n    return _370;\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _139 = fa_srgb_to_linear(param);\n        c = _139;\n    }\n    return c;\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _145 = scene_rgb(param);\n    return _145;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = tint.xyz;\n    float3 _259 = fa_scene_rgb(param) * _256_boost;\n    s.color.x = _259.x;\n    s.color.y = _259.y;\n    s.color.z = _259.z;\n}\n\nvoid frag_main()\n{\n    float4 _286 = tex.Sample(smp, uv);\n    float3 param = _286.xyz;\n    float param_1 = xform.y;\n    float3 _295 = fa_tex_fix(param, param_1);\n    frag_color = float4(_295, _286.w) * color;\n    float param_2 = 0.0f;\n    float4 _350 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _352 = { _350 };\n    QuadSurface param_4 = _352;\n    fragment(param_3, param_4);\n    _350 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 1616,
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
