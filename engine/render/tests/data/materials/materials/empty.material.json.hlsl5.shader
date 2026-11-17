{
  "format": "factoria.shader/1",
  "engine": "0.30.1",
  "template": "b5ef3e931c5673e3120cb224375a6b96104a5da86f18b53f68e85e69e4b04423",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _129_fa_view_proj : packoffset(c0);\n    row_major float4x4 _129_fa_light_vp : packoffset(c4);\n    float4 _129_fa_uv_scale : packoffset(c8);\n    float4 _129_fa_time : packoffset(c9);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _67 = cross(model[1].xyz, model[2].xyz);\n    float _73 = (dot(model[0].xyz, _67) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _260 = { mul(float4(position, 1.0f), model).xyz, (((_67 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _73, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _73), texcoord0 * _129_fa_uv_scale.xy, color, position };\n    return _260;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _158 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _267 = _158.world_pos;\n    float4 _165 = float4(_267, 1.0f);\n    fa_world_pos = _267;\n    fa_world_normal = _158.world_normal;\n    fa_world_tangent = _158.world_tangent;\n    fa_uv = _158.uv;\n    fa_vertex_color = _158.color;\n    fa_shadow_pos = mul(_165, _129_fa_light_vp);\n    gl_Position = mul(_165, _129_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _230_fa_camera_pos : packoffset(c0);\n    float4 _230_fa_ambient : packoffset(c1);\n    float4 _230_fa_base_color : packoffset(c2);\n    float4 _230_fa_emissive : packoffset(c3);\n    float4 _230_fa_model_emissive : packoffset(c4);\n    float4 _230_fa_pbr : packoffset(c5);\n    float4 _230_fa_maps : packoffset(c6);\n    float4 _230_fa_fog : packoffset(c7);\n    float4 _230_fa_counts : packoffset(c8);\n    float4 _230_fa_env_sky : packoffset(c9);\n    float4 _230_fa_env_horizon : packoffset(c10);\n    float4 _230_fa_time : packoffset(c11);\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _796_fa_light_pos[32] : packoffset(c0);\n    float4 _796_fa_light_color[32] : packoffset(c32);\n    float4 _796_fa_light_dir[32] : packoffset(c64);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(float3 c, float mode)\n{\n    float3 _180;\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _185 = fa_linear_to_srgb(param);\n        _180 = _185;\n    }\n    else\n    {\n        float3 _190;\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _195 = fa_srgb_to_linear(param_1);\n            _190 = _195;\n        }\n        else\n        {\n            _190 = c;\n        }\n        _180 = _190;\n    }\n    return _180;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _68;\n    if (i.front_facing)\n    {\n        _68 = i.world_normal;\n    }\n    else\n    {\n        _68 = -i.world_normal;\n    }\n    float3 _93 = normalize(i.world_tangent.xyz - (_68 * dot(_68, i.world_tangent.xyz)));\n    float3 _121 = normalize(((_93 * m.x) + ((cross(_68, _93) * i.world_tangent.w) * m.y)) + (_68 * m.z));\n    float3 _124;\n    if (i.front_facing)\n    {\n        _124 = _121;\n    }\n    else\n    {\n        _124 = -_121;\n    }\n    return _124;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _230_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _242 = fa_tex_fix(param_2, param_3);\n    float4 _1119 = base_t;\n    _1119.x = _242.x;\n    _1119.y = _242.y;\n    _1119.z = _242.z;\n    base_t = _1119;\n    float4 _258 = (_1119 * _230_fa_base_color) * i.vertex_color;\n    float3 _1104 = i.world_normal;\n    if (_230_fa_maps.z > 0.5f)\n    {\n        float param_4 = _230_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _296 = (fa_tex_fix(param_6, param_7) * 2.0f) - 1.0f.xxx;\n        float2 _301 = _296.xy * _230_fa_maps.x;\n        float3 _1127 = _296;\n        _1127.x = _301.x;\n        _1127.y = _301.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1127;\n        _1104 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _230_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _330 = fa_tex_fix(param_12, param_13);\n    float4 _1130 = mrt;\n    _1130.x = _330.x;\n    float _334 = _330.y;\n    _1130.y = _334;\n    float _336 = _330.z;\n    _1130.z = _336;\n    mrt = _1130;\n    float param_14 = _230_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float param_18 = _230_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    Surface _1116 = { _258.xyz, _258.w, _1104, clamp(_230_fa_pbr.x * _336, 0.0f, 1.0f), clamp(_230_fa_pbr.y * _334, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_230_fa_maps.y * (fa_tex_fix(param_16, param_17).x - 1.0f)), _230_fa_emissive.xyz + (_230_fa_model_emissive.xyz * fa_tex_fix(param_20, param_21)) };\n    return _1116;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    if (_230_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _420 = fa_shadow_pos.xyz / fa_shadow_pos.w.xxx;\n    float3 p = _420;\n    float2 suv = (_420.xy * 0.5f) + 0.5f.xx;\n    if (_230_fa_counts.z > 0.5f)\n    {\n        float3 _1138 = p;\n        _1138.z = (_1138.z * 0.5f) + 0.5f;\n        p = _1138;\n    }\n    else\n    {\n        float2 _1141 = suv;\n        _1141.y = 1.0f - _1141.y;\n        suv = _1141;\n    }\n    bool _447 = suv.x < 0.0f;\n    bool _454;\n    if (!_447)\n    {\n        _454 = suv.x > 1.0f;\n    }\n    else\n    {\n        _454 = _447;\n    }\n    bool _461;\n    if (!_454)\n    {\n        _461 = suv.y < 0.0f;\n    }\n    else\n    {\n        _461 = _454;\n    }\n    bool _468;\n    if (!_461)\n    {\n        _468 = suv.y > 1.0f;\n    }\n    else\n    {\n        _468 = _461;\n    }\n    bool _475;\n    if (!_468)\n    {\n        _475 = p.z > 1.0f;\n    }\n    else\n    {\n        _475 = _468;\n    }\n    if (_475)\n    {\n        return 1.0f;\n    }\n    float _489 = _230_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _489) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _230_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _630 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _633 = _630.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_633 * _633, exp2((-9.27999973297119140625f) * ndv)) * _633) + _630.y)) + _630.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _550 = rough * rough;\n    float _583 = 0.60000002384185791015625f * _550;\n    return lerp(lerp(_230_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_230_fa_env_horizon.xyz, _230_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _550)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _583, 0.0500000007450580596923828125f + _583, d.y).xxx), ((_230_fa_env_sky.xyz + _230_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_550 * 0.60000002384185791015625f).xxx);\n}\n\nvoid frag_main()\n{\n    float3 _1051 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1051 = -_1051;\n    }\n    float3 _693 = _230_fa_camera_pos.xyz - fa_world_pos;\n    float3 _694 = normalize(_693);\n    SurfaceInput _1064 = { fa_world_pos, _1051, fa_world_tangent, fa_uv, fa_vertex_color, _694, gl_FrontFacing };\n    SurfaceInput param = _1064;\n    Surface _699 = fa_standard_surface(param);\n    float3 _1073 = _699.albedo;\n    float _1074 = _699.alpha;\n    float3 _1075 = _699.normal;\n    float _1076 = _699.metallic;\n    float _1077 = _699.roughness;\n    float _1078 = _699.occlusion;\n    float3 _1079 = _699.emission;\n    SurfaceInput _1072 = { fa_world_pos, _1051, fa_world_tangent, fa_uv, fa_vertex_color, _694, gl_FrontFacing };\n    SurfaceInput param_1 = _1072;\n    Surface param_2 = _699;\n    surface(param_1, param_2);\n    _1073 = param_2.albedo;\n    _1074 = param_2.alpha;\n    _1075 = param_2.normal;\n    _1076 = param_2.metallic;\n    _1077 = param_2.roughness;\n    _1078 = param_2.occlusion;\n    _1079 = param_2.emission;\n    float3 result;\n    if (_230_fa_emissive.w > 0.5f)\n    {\n        result = _1073;\n    }\n    else\n    {\n        float3 _721 = normalize(_1075);\n        float _728 = clamp(_1076, 0.0f, 1.0f);\n        float _732 = clamp(_1077, 0.0500000007450580596923828125f, 1.0f);\n        float _736 = _732 * _732;\n        float _740 = _736 * _736;\n        float _746 = max(dot(_721, _694), 9.9999997473787516355514526367188e-05f);\n        float3 _752 = _1073 * (1.0f - _728);\n        float3 _760 = lerp(0.039999999105930328369140625f.xxx, _1073, _728.xxx);\n        float3 lit = (_230_fa_ambient.xyz * _752) * _1078;\n        int _773 = int(_230_fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _773)\n            {\n                break;\n            }\n            float atten = 1.0f;\n            bool _802 = _796_fa_light_color[li].w < 0.5f;\n            if (_802)\n            {\n                l = normalize(_796_fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _819 = _796_fa_light_pos[li].xyz - fa_world_pos;\n                float _822 = length(_819);\n                l = _819 / max(_822, 9.9999997473787516355514526367188e-05f).xxx;\n                float _837 = _822 / max(_796_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n                float _843 = clamp(1.0f - (_837 * _837), 0.0f, 1.0f);\n                atten = _843 * _843;\n                if (_796_fa_light_color[li].w > 1.5f)\n                {\n                    atten *= smoothstep(_796_fa_light_dir[li].w, lerp(_796_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_796_fa_light_dir[li].xyz)));\n                }\n            }\n            float _876 = max(dot(_721, l), 0.0f);\n            if (_802 && (li == 0))\n            {\n                float3 param_3 = _1051;\n                float3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4);\n            }\n            float3 _895 = normalize(l + _694);\n            float _900 = max(dot(_721, _895), 0.0f);\n            float _913 = ((_900 * _900) * (_740 - 1.0f)) + 1.0f;\n            lit += (((_752 + (((_760 + ((1.0f.xxx - _760) * pow(1.0f - max(dot(_694, _895), 0.0f), 5.0f))) * (((_740 / ((3.1415927410125732421875f * _913) * _913)) * (0.5f / max(lerp((2.0f * _876) * _746, _876 + _746, _736), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _876))) * _796_fa_light_color[li].xyz) * (_876 * atten));\n        }\n        float param_5 = _732;\n        float param_6 = _746;\n        float2 _981 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_694, _721);\n        float param_8 = _732;\n        float3 _999 = lit;\n        float3 _1000 = _999 + ((fa_environment(param_7, param_8) * ((_760 * _981.x) + _981.y.xxx)) * _1078);\n        lit = _1000;\n        result = _1000;\n    }\n    result += _1079;\n    if (_230_fa_fog.w > 0.0f)\n    {\n        float _1024 = _230_fa_fog.w * length(_693);\n        result = lerp(result, _230_fa_fog.xyz, clamp(1.0f - exp((-_1024) * _1024), 0.0f, 1.0f).xxx);\n    }\n    fa_frag_color = float4(result, _1074);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 2
          },
          {
            "slot": 3,
            "type": "vec4",
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
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 5
          },
          {
            "slot": 6,
            "type": "vec4",
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
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_129",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_230",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_796",
            "hlsl_register_b_n": 2
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
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
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 1
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
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
              "name": "fa_mr_tex",
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
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 4
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "hlsl_register_s_n": 1
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _134_fa_view_proj : packoffset(c0);\n    row_major float4x4 _134_fa_light_vp : packoffset(c4);\n    float4 _134_fa_uv_scale : packoffset(c8);\n    float4 _134_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _181_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _172 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_181_fa_joint_rows[_172] * weights[i]);\n        r1 += (_181_fa_joint_rows[_172 + 1] * weights[i]);\n        r2 += (_181_fa_joint_rows[_172 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _72 = cross(model[1].xyz, model[2].xyz);\n    float _78 = (dot(model[0].xyz, _72) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _381 = { mul(float4(position, 1.0f), model).xyz, (((_72 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _78, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _78), texcoord0 * _134_fa_uv_scale.xy, color, position };\n    return _381;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _271 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _388 = _271.world_pos;\n    float4 _278 = float4(_388, 1.0f);\n    fa_world_pos = _388;\n    fa_world_normal = _271.world_normal;\n    fa_world_tangent = _271.world_tangent;\n    fa_uv = _271.uv;\n    fa_vertex_color = _271.color;\n    fa_shadow_pos = mul(_278, _134_fa_light_vp);\n    gl_Position = mul(_278, _134_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _230_fa_camera_pos : packoffset(c0);\n    float4 _230_fa_ambient : packoffset(c1);\n    float4 _230_fa_base_color : packoffset(c2);\n    float4 _230_fa_emissive : packoffset(c3);\n    float4 _230_fa_model_emissive : packoffset(c4);\n    float4 _230_fa_pbr : packoffset(c5);\n    float4 _230_fa_maps : packoffset(c6);\n    float4 _230_fa_fog : packoffset(c7);\n    float4 _230_fa_counts : packoffset(c8);\n    float4 _230_fa_env_sky : packoffset(c9);\n    float4 _230_fa_env_horizon : packoffset(c10);\n    float4 _230_fa_time : packoffset(c11);\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _796_fa_light_pos[32] : packoffset(c0);\n    float4 _796_fa_light_color[32] : packoffset(c32);\n    float4 _796_fa_light_dir[32] : packoffset(c64);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(float3 c, float mode)\n{\n    float3 _180;\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _185 = fa_linear_to_srgb(param);\n        _180 = _185;\n    }\n    else\n    {\n        float3 _190;\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _195 = fa_srgb_to_linear(param_1);\n            _190 = _195;\n        }\n        else\n        {\n            _190 = c;\n        }\n        _180 = _190;\n    }\n    return _180;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _68;\n    if (i.front_facing)\n    {\n        _68 = i.world_normal;\n    }\n    else\n    {\n        _68 = -i.world_normal;\n    }\n    float3 _93 = normalize(i.world_tangent.xyz - (_68 * dot(_68, i.world_tangent.xyz)));\n    float3 _121 = normalize(((_93 * m.x) + ((cross(_68, _93) * i.world_tangent.w) * m.y)) + (_68 * m.z));\n    float3 _124;\n    if (i.front_facing)\n    {\n        _124 = _121;\n    }\n    else\n    {\n        _124 = -_121;\n    }\n    return _124;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _230_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _242 = fa_tex_fix(param_2, param_3);\n    float4 _1119 = base_t;\n    _1119.x = _242.x;\n    _1119.y = _242.y;\n    _1119.z = _242.z;\n    base_t = _1119;\n    float4 _258 = (_1119 * _230_fa_base_color) * i.vertex_color;\n    float3 _1104 = i.world_normal;\n    if (_230_fa_maps.z > 0.5f)\n    {\n        float param_4 = _230_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _296 = (fa_tex_fix(param_6, param_7) * 2.0f) - 1.0f.xxx;\n        float2 _301 = _296.xy * _230_fa_maps.x;\n        float3 _1127 = _296;\n        _1127.x = _301.x;\n        _1127.y = _301.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1127;\n        _1104 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _230_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _330 = fa_tex_fix(param_12, param_13);\n    float4 _1130 = mrt;\n    _1130.x = _330.x;\n    float _334 = _330.y;\n    _1130.y = _334;\n    float _336 = _330.z;\n    _1130.z = _336;\n    mrt = _1130;\n    float param_14 = _230_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float param_18 = _230_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    Surface _1116 = { _258.xyz, _258.w, _1104, clamp(_230_fa_pbr.x * _336, 0.0f, 1.0f), clamp(_230_fa_pbr.y * _334, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_230_fa_maps.y * (fa_tex_fix(param_16, param_17).x - 1.0f)), _230_fa_emissive.xyz + (_230_fa_model_emissive.xyz * fa_tex_fix(param_20, param_21)) };\n    return _1116;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    if (_230_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _420 = fa_shadow_pos.xyz / fa_shadow_pos.w.xxx;\n    float3 p = _420;\n    float2 suv = (_420.xy * 0.5f) + 0.5f.xx;\n    if (_230_fa_counts.z > 0.5f)\n    {\n        float3 _1138 = p;\n        _1138.z = (_1138.z * 0.5f) + 0.5f;\n        p = _1138;\n    }\n    else\n    {\n        float2 _1141 = suv;\n        _1141.y = 1.0f - _1141.y;\n        suv = _1141;\n    }\n    bool _447 = suv.x < 0.0f;\n    bool _454;\n    if (!_447)\n    {\n        _454 = suv.x > 1.0f;\n    }\n    else\n    {\n        _454 = _447;\n    }\n    bool _461;\n    if (!_454)\n    {\n        _461 = suv.y < 0.0f;\n    }\n    else\n    {\n        _461 = _454;\n    }\n    bool _468;\n    if (!_461)\n    {\n        _468 = suv.y > 1.0f;\n    }\n    else\n    {\n        _468 = _461;\n    }\n    bool _475;\n    if (!_468)\n    {\n        _475 = p.z > 1.0f;\n    }\n    else\n    {\n        _475 = _468;\n    }\n    if (_475)\n    {\n        return 1.0f;\n    }\n    float _489 = _230_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _489) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _230_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _630 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _633 = _630.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_633 * _633, exp2((-9.27999973297119140625f) * ndv)) * _633) + _630.y)) + _630.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _550 = rough * rough;\n    float _583 = 0.60000002384185791015625f * _550;\n    return lerp(lerp(_230_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_230_fa_env_horizon.xyz, _230_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _550)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _583, 0.0500000007450580596923828125f + _583, d.y).xxx), ((_230_fa_env_sky.xyz + _230_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_550 * 0.60000002384185791015625f).xxx);\n}\n\nvoid frag_main()\n{\n    float3 _1051 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1051 = -_1051;\n    }\n    float3 _693 = _230_fa_camera_pos.xyz - fa_world_pos;\n    float3 _694 = normalize(_693);\n    SurfaceInput _1064 = { fa_world_pos, _1051, fa_world_tangent, fa_uv, fa_vertex_color, _694, gl_FrontFacing };\n    SurfaceInput param = _1064;\n    Surface _699 = fa_standard_surface(param);\n    float3 _1073 = _699.albedo;\n    float _1074 = _699.alpha;\n    float3 _1075 = _699.normal;\n    float _1076 = _699.metallic;\n    float _1077 = _699.roughness;\n    float _1078 = _699.occlusion;\n    float3 _1079 = _699.emission;\n    SurfaceInput _1072 = { fa_world_pos, _1051, fa_world_tangent, fa_uv, fa_vertex_color, _694, gl_FrontFacing };\n    SurfaceInput param_1 = _1072;\n    Surface param_2 = _699;\n    surface(param_1, param_2);\n    _1073 = param_2.albedo;\n    _1074 = param_2.alpha;\n    _1075 = param_2.normal;\n    _1076 = param_2.metallic;\n    _1077 = param_2.roughness;\n    _1078 = param_2.occlusion;\n    _1079 = param_2.emission;\n    float3 result;\n    if (_230_fa_emissive.w > 0.5f)\n    {\n        result = _1073;\n    }\n    else\n    {\n        float3 _721 = normalize(_1075);\n        float _728 = clamp(_1076, 0.0f, 1.0f);\n        float _732 = clamp(_1077, 0.0500000007450580596923828125f, 1.0f);\n        float _736 = _732 * _732;\n        float _740 = _736 * _736;\n        float _746 = max(dot(_721, _694), 9.9999997473787516355514526367188e-05f);\n        float3 _752 = _1073 * (1.0f - _728);\n        float3 _760 = lerp(0.039999999105930328369140625f.xxx, _1073, _728.xxx);\n        float3 lit = (_230_fa_ambient.xyz * _752) * _1078;\n        int _773 = int(_230_fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _773)\n            {\n                break;\n            }\n            float atten = 1.0f;\n            bool _802 = _796_fa_light_color[li].w < 0.5f;\n            if (_802)\n            {\n                l = normalize(_796_fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _819 = _796_fa_light_pos[li].xyz - fa_world_pos;\n                float _822 = length(_819);\n                l = _819 / max(_822, 9.9999997473787516355514526367188e-05f).xxx;\n                float _837 = _822 / max(_796_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n                float _843 = clamp(1.0f - (_837 * _837), 0.0f, 1.0f);\n                atten = _843 * _843;\n                if (_796_fa_light_color[li].w > 1.5f)\n                {\n                    atten *= smoothstep(_796_fa_light_dir[li].w, lerp(_796_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_796_fa_light_dir[li].xyz)));\n                }\n            }\n            float _876 = max(dot(_721, l), 0.0f);\n            if (_802 && (li == 0))\n            {\n                float3 param_3 = _1051;\n                float3 param_4 = l;\n                atten *= fa_shadow_factor(param_3, param_4);\n            }\n            float3 _895 = normalize(l + _694);\n            float _900 = max(dot(_721, _895), 0.0f);\n            float _913 = ((_900 * _900) * (_740 - 1.0f)) + 1.0f;\n            lit += (((_752 + (((_760 + ((1.0f.xxx - _760) * pow(1.0f - max(dot(_694, _895), 0.0f), 5.0f))) * (((_740 / ((3.1415927410125732421875f * _913) * _913)) * (0.5f / max(lerp((2.0f * _876) * _746, _876 + _746, _736), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _876))) * _796_fa_light_color[li].xyz) * (_876 * atten));\n        }\n        float param_5 = _732;\n        float param_6 = _746;\n        float2 _981 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_694, _721);\n        float param_8 = _732;\n        float3 _999 = lit;\n        float3 _1000 = _999 + ((fa_environment(param_7, param_8) * ((_760 * _981.x) + _981.y.xxx)) * _1078);\n        lit = _1000;\n        result = _1000;\n    }\n    result += _1079;\n    if (_230_fa_fog.w > 0.0f)\n    {\n        float _1024 = _230_fa_fog.w * length(_693);\n        result = lerp(result, _230_fa_fog.xyz, clamp(1.0f - exp((-_1024) * _1024), 0.0f, 1.0f).xxx);\n    }\n    fa_frag_color = float4(result, _1074);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 2
          },
          {
            "slot": 3,
            "type": "vec4",
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
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 5
          },
          {
            "slot": 6,
            "type": "vec4",
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
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 9
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 10
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_134",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_181",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 192,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_230",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_796",
            "hlsl_register_b_n": 2
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
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
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 1
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
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
              "name": "fa_mr_tex",
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
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 4
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "hlsl_register_s_n": 1
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          }
        ]
      }
    }
  }
}
