{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "697e453f860a2a28a0896192c358aed0e2c58205047183915510875223b187a6",
  "slang": "hlsl5",
  "params": [
    "lift"
  ],
  "textures": [
    "height"
  ],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float _63_lift : packoffset(c0);\n    float _63_fa_pad0 : packoffset(c0.y);\n    float _63_fa_pad1 : packoffset(c0.z);\n    float _63_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _160_fa_view_proj : packoffset(c0);\n    row_major float4x4 _160_fa_light_vp : packoffset(c4);\n    float4 _160_fa_uv_scale : packoffset(c8);\n    float4 _160_fa_time : packoffset(c9);\n};\n\nTexture2D<float4> fa_vs_height : register(t0);\nSamplerState fa_vs_height_smp : register(s6);\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _103 = cross(model[1].xyz, model[2].xyz);\n    float _108 = (dot(model[0].xyz, _103) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _296 = { mul(float4(position, 1.0f), model).xyz, (((_103 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _108, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _108), texcoord0 * _160_fa_uv_scale.xy, color, position };\n    return _296;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (fa_vs_height.SampleLevel(fa_vs_height_smp, v.uv, 0.0f).x * _63_lift);\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _200 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = mul(_200, _160_fa_light_vp);\n    gl_Position = mul(_200, _160_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _243_fa_camera_pos : packoffset(c0);\n    float4 _243_fa_ambient : packoffset(c1);\n    float4 _243_fa_base_color : packoffset(c2);\n    float4 _243_fa_emissive : packoffset(c3);\n    float4 _243_fa_model_emissive : packoffset(c4);\n    float4 _243_fa_pbr : packoffset(c5);\n    float4 _243_fa_maps : packoffset(c6);\n    float4 _243_fa_fog : packoffset(c7);\n    float4 _243_fa_fog_b : packoffset(c8);\n    float4 _243_fa_fog_c : packoffset(c9);\n    float4 _243_fa_counts : packoffset(c10);\n    float4 _243_fa_env_sky : packoffset(c11);\n    float4 _243_fa_env_horizon : packoffset(c12);\n    float4 _243_fa_time : packoffset(c13);\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _808_fa_light_pos[32] : packoffset(c0);\n    float4 _808_fa_light_color[32] : packoffset(c32);\n    float4 _808_fa_light_dir[32] : packoffset(c64);\n};\n\nTexture2D<float4> height : register(t6);\nSamplerState height_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _210 = fa_linear_to_srgb(param);\n        c = _210;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _218 = fa_srgb_to_linear(param_1);\n            c = _218;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _70;\n    if (i.front_facing)\n    {\n        _70 = i.world_normal;\n    }\n    else\n    {\n        _70 = -i.world_normal;\n    }\n    float3 _95 = normalize(i.world_tangent.xyz - (_70 * dot(_70, i.world_tangent.xyz)));\n    float3 _123 = normalize(((_95 * m.x) + ((cross(_70, _95) * i.world_tangent.w) * m.y)) + (_70 * m.z));\n    float3 _126;\n    if (i.front_facing)\n    {\n        _126 = _123;\n    }\n    else\n    {\n        _126 = -_123;\n    }\n    return _126;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _243_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _254 = fa_tex_fix(param_2, param_3);\n    float4 _1337 = base_t;\n    _1337.x = _254.x;\n    _1337.y = _254.y;\n    _1337.z = _254.z;\n    base_t = _1337;\n    float4 _270 = (_1337 * _243_fa_base_color) * i.vertex_color;\n    float3 _1321 = i.world_normal;\n    if (_243_fa_maps.z > 0.5f)\n    {\n        float param_4 = _243_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _303 = fa_tex_fix(param_6, param_7);\n        float3 _307 = (_303 * 2.0f) - 1.0f.xxx;\n        float2 _312 = _307.xy * _243_fa_maps.x;\n        float3 _1345 = _307;\n        _1345.x = _312.x;\n        _1345.y = _312.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1345;\n        _1321 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _243_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _341 = fa_tex_fix(param_12, param_13);\n    float4 _1348 = mrt;\n    _1348.x = _341.x;\n    _1348.y = _341.y;\n    _1348.z = _341.z;\n    mrt = _1348;\n    float param_14 = _243_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _382 = fa_tex_fix(param_16, param_17);\n    float param_18 = _243_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _409 = fa_tex_fix(param_20, param_21);\n    Surface _1333 = { _270.xyz, _270.w, _1321, clamp(_243_fa_pbr.x * _341.z, 0.0f, 1.0f), clamp(_243_fa_pbr.y * _341.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_243_fa_maps.y * (_382.x - 1.0f)), _243_fa_emissive.xyz + (_243_fa_model_emissive.xyz * _409) };\n    return _1333;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= lerp(0.5f, 1.0f, height.Sample(height_smp, i.uv).x);\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    if (_243_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _431 = fa_shadow_pos.xyz / fa_shadow_pos.w.xxx;\n    float3 p = _431;\n    float2 suv = (_431.xy * 0.5f) + 0.5f.xx;\n    if (_243_fa_counts.z > 0.5f)\n    {\n        float3 _1356 = p;\n        _1356.z = (_1356.z * 0.5f) + 0.5f;\n        p = _1356;\n    }\n    else\n    {\n        float2 _1359 = suv;\n        _1359.y = 1.0f - _1359.y;\n        suv = _1359;\n    }\n    bool _458 = suv.x < 0.0f;\n    bool _465;\n    if (!_458)\n    {\n        _465 = suv.x > 1.0f;\n    }\n    else\n    {\n        _465 = _458;\n    }\n    bool _472;\n    if (!_465)\n    {\n        _472 = suv.y < 0.0f;\n    }\n    else\n    {\n        _472 = _465;\n    }\n    bool _479;\n    if (!_472)\n    {\n        _479 = suv.y > 1.0f;\n    }\n    else\n    {\n        _479 = _472;\n    }\n    bool _486;\n    if (!_479)\n    {\n        _486 = p.z > 1.0f;\n    }\n    else\n    {\n        _486 = _479;\n    }\n    if (_486)\n    {\n        return 1.0f;\n    }\n    float _500 = _243_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _500) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _243_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _641 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _644 = _641.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_644 * _644, exp2((-9.27999973297119140625f) * ndv)) * _644) + _641.y)) + _641.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _561 = rough * rough;\n    float _594 = 0.60000002384185791015625f * _561;\n    return lerp(lerp(_243_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_243_fa_env_horizon.xyz, _243_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _561)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _594, 0.0500000007450580596923828125f + _594, d.y).xxx), ((_243_fa_env_sky.xyz + _243_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_561 * 0.60000002384185791015625f).xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _1267 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1267 = -_1267;\n    }\n    float3 _706 = normalize(_243_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _1280 = { fa_world_pos, _1267, fa_world_tangent, fa_uv, fa_vertex_color, _706, gl_FrontFacing };\n    SurfaceInput param = _1280;\n    Surface _711 = fa_standard_surface(param);\n    float3 _1290 = _711.albedo;\n    float _1291 = _711.alpha;\n    float3 _1292 = _711.normal;\n    float _1293 = _711.metallic;\n    float _1294 = _711.roughness;\n    float _1295 = _711.occlusion;\n    float3 _1296 = _711.emission;\n    SurfaceInput _1288 = { fa_world_pos, _1267, fa_world_tangent, fa_uv, fa_vertex_color, _706, gl_FrontFacing };\n    SurfaceInput param_1 = _1288;\n    Surface param_2 = _711;\n    surface(param_1, param_2);\n    _1290 = param_2.albedo;\n    _1291 = param_2.alpha;\n    _1292 = param_2.normal;\n    _1293 = param_2.metallic;\n    _1294 = param_2.roughness;\n    _1295 = param_2.occlusion;\n    _1296 = param_2.emission;\n    float3 result;\n    if (_243_fa_emissive.w > 0.5f)\n    {\n        result = _1290;\n    }\n    else\n    {\n        float3 _733 = normalize(_1292);\n        float _740 = clamp(_1293, 0.0f, 1.0f);\n        float _744 = clamp(_1294, 0.0500000007450580596923828125f, 1.0f);\n        float _748 = _744 * _744;\n        float _752 = _748 * _748;\n        float _758 = max(dot(_733, _706), 9.9999997473787516355514526367188e-05f);\n        float3 _764 = _1290 * (1.0f - _740);\n        float3 _772 = lerp(0.039999999105930328369140625f.xxx, _1290, _740.xxx);\n        float3 lit = (_243_fa_ambient.xyz * _764) * _1295;\n        int _785 = int(_243_fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _785)\n            {\n                break;\n            }\n            float atten = 1.0f;\n            bool _815 = _808_fa_light_color[li].w < 0.5f;\n            if (_815)\n            {\n                l = normalize(_808_fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _832 = _808_fa_light_pos[li].xyz - fa_world_pos;\n                float _834 = length(_832);\n                l = _832 / max(_834, 9.9999997473787516355514526367188e-05f).xxx;\n                float _849 = _834 / max(_808_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n                float _855 = clamp(1.0f - (_849 * _849), 0.0f, 1.0f);\n                atten = _855 * _855;\n                if (_808_fa_light_color[li].w > 1.5f)\n                {\n                    atten *= smoothstep(_808_fa_light_dir[li].w, lerp(_808_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_808_fa_light_dir[li].xyz)));\n                }\n            }\n            float shadow = 1.0f;\n            if (_815 && (li == 0))\n            {\n                float3 param_3 = _1267;\n                float3 param_4 = l;\n                shadow = fa_shadow_factor(param_3, param_4);\n            }\n            float _901 = max(dot(_733, l), 0.0f);\n            float _903 = atten;\n            float _904 = _903 * shadow;\n            atten = _904;\n            float3 _909 = normalize(l + _706);\n            float _914 = max(dot(_733, _909), 0.0f);\n            float _927 = ((_914 * _914) * (_752 - 1.0f)) + 1.0f;\n            lit += (((_764 + (((_772 + ((1.0f.xxx - _772) * pow(1.0f - max(dot(_706, _909), 0.0f), 5.0f))) * (((_752 / ((3.1415927410125732421875f * _927) * _927)) * (0.5f / max(lerp((2.0f * _901) * _758, _901 + _758, _748), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _901))) * _808_fa_light_color[li].xyz) * (_901 * _904));\n        }\n        float param_5 = _744;\n        float param_6 = _758;\n        float2 _995 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_706, _733);\n        float param_8 = _744;\n        float3 _1013 = lit;\n        float3 _1014 = _1013 + ((fa_environment(param_7, param_8) * ((_772 * _995.x) + _995.y.xxx)) * _1295);\n        lit = _1014;\n        result = _1014;\n    }\n    result += _1296;\n    bool _1023 = _243_fa_fog.w > 0.0f;\n    bool _1031;\n    if (!_1023)\n    {\n        _1031 = _243_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1031 = _1023;\n    }\n    if (_1031)\n    {\n        float3 _1040 = fa_world_pos - _243_fa_camera_pos.xyz;\n        float _1047 = dot(_1040, _243_fa_fog_c.xyz);\n        bool _1051 = _243_fa_fog_c.w > 0.5f;\n        float _1052;\n        if (_1051)\n        {\n            _1052 = _1047;\n        }\n        else\n        {\n            _1052 = length(_1040);\n        }\n        float _1064 = _1052 - _243_fa_fog_b.x;\n        if (_1064 > 0.0f)\n        {\n            float _1073 = _243_fa_fog.w * _1064;\n            float tau = _1073 * _1073;\n            if (_243_fa_fog_b.y > 0.0f)\n            {\n                float _1089;\n                if (_1051)\n                {\n                    _1089 = fa_world_pos.y - (_243_fa_fog_c.y * _1047);\n                }\n                else\n                {\n                    _1089 = _243_fa_camera_pos.y;\n                }\n                float _1110 = lerp(_1089, fa_world_pos.y, clamp(_243_fa_fog_b.x / _1052, 0.0f, 1.0f));\n                float _1114 = fa_world_pos.y - _1110;\n                float _1119 = _1110 - _243_fa_fog_b.z;\n                float _1124 = fa_world_pos.y - _243_fa_fog_b.z;\n                bool _1127 = _1119 <= 0.0f;\n                bool _1128 = !_1127;\n                bool _1134;\n                if (_1128)\n                {\n                    _1134 = _243_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1134 = _1127;\n                }\n                float _1135;\n                if (_1134)\n                {\n                    _1135 = _243_fa_fog_b.y;\n                }\n                else\n                {\n                    _1135 = _243_fa_fog_b.y * exp(-min(_243_fa_fog_b.w * _1119, 80.0f));\n                }\n                bool _1162;\n                if (_1128)\n                {\n                    _1162 = _243_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1162 = _1127;\n                }\n                float _1163;\n                if (_1162)\n                {\n                    _1163 = _243_fa_fog_b.y * _1119;\n                }\n                else\n                {\n                    _1163 = (_243_fa_fog_b.y * (1.0f - exp(-min(_243_fa_fog_b.w * _1119, 80.0f)))) / _243_fa_fog_b.w;\n                }\n                bool _1188 = _1124 <= 0.0f;\n                bool _1195;\n                if (!_1188)\n                {\n                    _1195 = _243_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1195 = _1188;\n                }\n                float _1196;\n                if (_1195)\n                {\n                    _1196 = _243_fa_fog_b.y * _1124;\n                }\n                else\n                {\n                    _1196 = (_243_fa_fog_b.y * (1.0f - exp(-min(_243_fa_fog_b.w * _1124, 80.0f)))) / _243_fa_fog_b.w;\n                }\n                float _1223;\n                if (abs(_1114) < 0.001000000047497451305389404296875f)\n                {\n                    _1223 = _1135;\n                }\n                else\n                {\n                    _1223 = (_1196 - _1163) / _1114;\n                }\n                tau += (_1064 * max(_1223, 0.0f));\n            }\n            result = lerp(result, _243_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _1291);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_63",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_160",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_243",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_808",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 6
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 6
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
          },
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
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2
          },
          {
            "slot": 7,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float _68_lift : packoffset(c0);\n    float _68_fa_pad0 : packoffset(c0.y);\n    float _68_fa_pad1 : packoffset(c0.z);\n    float _68_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _165_fa_view_proj : packoffset(c0);\n    row_major float4x4 _165_fa_light_vp : packoffset(c4);\n    float4 _165_fa_uv_scale : packoffset(c8);\n    float4 _165_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _212_fa_joint_rows[192] : packoffset(c0);\n};\n\nTexture2D<float4> fa_vs_height : register(t0);\nSamplerState fa_vs_height_smp : register(s6);\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _203 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_212_fa_joint_rows[_203] * weights[i]);\n        r1 += (_212_fa_joint_rows[_203 + 1] * weights[i]);\n        r2 += (_212_fa_joint_rows[_203 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _108 = cross(model[1].xyz, model[2].xyz);\n    float _113 = (dot(model[0].xyz, _108) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _417 = { mul(float4(position, 1.0f), model).xyz, (((_108 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _113, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _113), texcoord0 * _165_fa_uv_scale.xy, color, position };\n    return _417;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (fa_vs_height.SampleLevel(fa_vs_height_smp, v.uv, 0.0f).x * _68_lift);\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _313 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = mul(_313, _165_fa_light_vp);\n    gl_Position = mul(_313, _165_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _243_fa_camera_pos : packoffset(c0);\n    float4 _243_fa_ambient : packoffset(c1);\n    float4 _243_fa_base_color : packoffset(c2);\n    float4 _243_fa_emissive : packoffset(c3);\n    float4 _243_fa_model_emissive : packoffset(c4);\n    float4 _243_fa_pbr : packoffset(c5);\n    float4 _243_fa_maps : packoffset(c6);\n    float4 _243_fa_fog : packoffset(c7);\n    float4 _243_fa_fog_b : packoffset(c8);\n    float4 _243_fa_fog_c : packoffset(c9);\n    float4 _243_fa_counts : packoffset(c10);\n    float4 _243_fa_env_sky : packoffset(c11);\n    float4 _243_fa_env_horizon : packoffset(c12);\n    float4 _243_fa_time : packoffset(c13);\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _808_fa_light_pos[32] : packoffset(c0);\n    float4 _808_fa_light_color[32] : packoffset(c32);\n    float4 _808_fa_light_dir[32] : packoffset(c64);\n};\n\nTexture2D<float4> height : register(t6);\nSamplerState height_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _210 = fa_linear_to_srgb(param);\n        c = _210;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _218 = fa_srgb_to_linear(param_1);\n            c = _218;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _70;\n    if (i.front_facing)\n    {\n        _70 = i.world_normal;\n    }\n    else\n    {\n        _70 = -i.world_normal;\n    }\n    float3 _95 = normalize(i.world_tangent.xyz - (_70 * dot(_70, i.world_tangent.xyz)));\n    float3 _123 = normalize(((_95 * m.x) + ((cross(_70, _95) * i.world_tangent.w) * m.y)) + (_70 * m.z));\n    float3 _126;\n    if (i.front_facing)\n    {\n        _126 = _123;\n    }\n    else\n    {\n        _126 = -_123;\n    }\n    return _126;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _243_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _254 = fa_tex_fix(param_2, param_3);\n    float4 _1337 = base_t;\n    _1337.x = _254.x;\n    _1337.y = _254.y;\n    _1337.z = _254.z;\n    base_t = _1337;\n    float4 _270 = (_1337 * _243_fa_base_color) * i.vertex_color;\n    float3 _1321 = i.world_normal;\n    if (_243_fa_maps.z > 0.5f)\n    {\n        float param_4 = _243_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _303 = fa_tex_fix(param_6, param_7);\n        float3 _307 = (_303 * 2.0f) - 1.0f.xxx;\n        float2 _312 = _307.xy * _243_fa_maps.x;\n        float3 _1345 = _307;\n        _1345.x = _312.x;\n        _1345.y = _312.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1345;\n        _1321 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _243_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _341 = fa_tex_fix(param_12, param_13);\n    float4 _1348 = mrt;\n    _1348.x = _341.x;\n    _1348.y = _341.y;\n    _1348.z = _341.z;\n    mrt = _1348;\n    float param_14 = _243_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _382 = fa_tex_fix(param_16, param_17);\n    float param_18 = _243_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _409 = fa_tex_fix(param_20, param_21);\n    Surface _1333 = { _270.xyz, _270.w, _1321, clamp(_243_fa_pbr.x * _341.z, 0.0f, 1.0f), clamp(_243_fa_pbr.y * _341.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_243_fa_maps.y * (_382.x - 1.0f)), _243_fa_emissive.xyz + (_243_fa_model_emissive.xyz * _409) };\n    return _1333;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= lerp(0.5f, 1.0f, height.Sample(height_smp, i.uv).x);\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    if (_243_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _431 = fa_shadow_pos.xyz / fa_shadow_pos.w.xxx;\n    float3 p = _431;\n    float2 suv = (_431.xy * 0.5f) + 0.5f.xx;\n    if (_243_fa_counts.z > 0.5f)\n    {\n        float3 _1356 = p;\n        _1356.z = (_1356.z * 0.5f) + 0.5f;\n        p = _1356;\n    }\n    else\n    {\n        float2 _1359 = suv;\n        _1359.y = 1.0f - _1359.y;\n        suv = _1359;\n    }\n    bool _458 = suv.x < 0.0f;\n    bool _465;\n    if (!_458)\n    {\n        _465 = suv.x > 1.0f;\n    }\n    else\n    {\n        _465 = _458;\n    }\n    bool _472;\n    if (!_465)\n    {\n        _472 = suv.y < 0.0f;\n    }\n    else\n    {\n        _472 = _465;\n    }\n    bool _479;\n    if (!_472)\n    {\n        _479 = suv.y > 1.0f;\n    }\n    else\n    {\n        _479 = _472;\n    }\n    bool _486;\n    if (!_479)\n    {\n        _486 = p.z > 1.0f;\n    }\n    else\n    {\n        _486 = _479;\n    }\n    if (_486)\n    {\n        return 1.0f;\n    }\n    float _500 = _243_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _500) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _243_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _641 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _644 = _641.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_644 * _644, exp2((-9.27999973297119140625f) * ndv)) * _644) + _641.y)) + _641.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _561 = rough * rough;\n    float _594 = 0.60000002384185791015625f * _561;\n    return lerp(lerp(_243_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_243_fa_env_horizon.xyz, _243_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _561)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _594, 0.0500000007450580596923828125f + _594, d.y).xxx), ((_243_fa_env_sky.xyz + _243_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_561 * 0.60000002384185791015625f).xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _1267 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1267 = -_1267;\n    }\n    float3 _706 = normalize(_243_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _1280 = { fa_world_pos, _1267, fa_world_tangent, fa_uv, fa_vertex_color, _706, gl_FrontFacing };\n    SurfaceInput param = _1280;\n    Surface _711 = fa_standard_surface(param);\n    float3 _1290 = _711.albedo;\n    float _1291 = _711.alpha;\n    float3 _1292 = _711.normal;\n    float _1293 = _711.metallic;\n    float _1294 = _711.roughness;\n    float _1295 = _711.occlusion;\n    float3 _1296 = _711.emission;\n    SurfaceInput _1288 = { fa_world_pos, _1267, fa_world_tangent, fa_uv, fa_vertex_color, _706, gl_FrontFacing };\n    SurfaceInput param_1 = _1288;\n    Surface param_2 = _711;\n    surface(param_1, param_2);\n    _1290 = param_2.albedo;\n    _1291 = param_2.alpha;\n    _1292 = param_2.normal;\n    _1293 = param_2.metallic;\n    _1294 = param_2.roughness;\n    _1295 = param_2.occlusion;\n    _1296 = param_2.emission;\n    float3 result;\n    if (_243_fa_emissive.w > 0.5f)\n    {\n        result = _1290;\n    }\n    else\n    {\n        float3 _733 = normalize(_1292);\n        float _740 = clamp(_1293, 0.0f, 1.0f);\n        float _744 = clamp(_1294, 0.0500000007450580596923828125f, 1.0f);\n        float _748 = _744 * _744;\n        float _752 = _748 * _748;\n        float _758 = max(dot(_733, _706), 9.9999997473787516355514526367188e-05f);\n        float3 _764 = _1290 * (1.0f - _740);\n        float3 _772 = lerp(0.039999999105930328369140625f.xxx, _1290, _740.xxx);\n        float3 lit = (_243_fa_ambient.xyz * _764) * _1295;\n        int _785 = int(_243_fa_counts.x);\n        float3 l;\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _785)\n            {\n                break;\n            }\n            float atten = 1.0f;\n            bool _815 = _808_fa_light_color[li].w < 0.5f;\n            if (_815)\n            {\n                l = normalize(_808_fa_light_pos[li].xyz);\n            }\n            else\n            {\n                float3 _832 = _808_fa_light_pos[li].xyz - fa_world_pos;\n                float _834 = length(_832);\n                l = _832 / max(_834, 9.9999997473787516355514526367188e-05f).xxx;\n                float _849 = _834 / max(_808_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n                float _855 = clamp(1.0f - (_849 * _849), 0.0f, 1.0f);\n                atten = _855 * _855;\n                if (_808_fa_light_color[li].w > 1.5f)\n                {\n                    atten *= smoothstep(_808_fa_light_dir[li].w, lerp(_808_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_808_fa_light_dir[li].xyz)));\n                }\n            }\n            float shadow = 1.0f;\n            if (_815 && (li == 0))\n            {\n                float3 param_3 = _1267;\n                float3 param_4 = l;\n                shadow = fa_shadow_factor(param_3, param_4);\n            }\n            float _901 = max(dot(_733, l), 0.0f);\n            float _903 = atten;\n            float _904 = _903 * shadow;\n            atten = _904;\n            float3 _909 = normalize(l + _706);\n            float _914 = max(dot(_733, _909), 0.0f);\n            float _927 = ((_914 * _914) * (_752 - 1.0f)) + 1.0f;\n            lit += (((_764 + (((_772 + ((1.0f.xxx - _772) * pow(1.0f - max(dot(_706, _909), 0.0f), 5.0f))) * (((_752 / ((3.1415927410125732421875f * _927) * _927)) * (0.5f / max(lerp((2.0f * _901) * _758, _901 + _758, _748), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _901))) * _808_fa_light_color[li].xyz) * (_901 * _904));\n        }\n        float param_5 = _744;\n        float param_6 = _758;\n        float2 _995 = fa_env_brdf(param_5, param_6);\n        float3 param_7 = reflect(-_706, _733);\n        float param_8 = _744;\n        float3 _1013 = lit;\n        float3 _1014 = _1013 + ((fa_environment(param_7, param_8) * ((_772 * _995.x) + _995.y.xxx)) * _1295);\n        lit = _1014;\n        result = _1014;\n    }\n    result += _1296;\n    bool _1023 = _243_fa_fog.w > 0.0f;\n    bool _1031;\n    if (!_1023)\n    {\n        _1031 = _243_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1031 = _1023;\n    }\n    if (_1031)\n    {\n        float3 _1040 = fa_world_pos - _243_fa_camera_pos.xyz;\n        float _1047 = dot(_1040, _243_fa_fog_c.xyz);\n        bool _1051 = _243_fa_fog_c.w > 0.5f;\n        float _1052;\n        if (_1051)\n        {\n            _1052 = _1047;\n        }\n        else\n        {\n            _1052 = length(_1040);\n        }\n        float _1064 = _1052 - _243_fa_fog_b.x;\n        if (_1064 > 0.0f)\n        {\n            float _1073 = _243_fa_fog.w * _1064;\n            float tau = _1073 * _1073;\n            if (_243_fa_fog_b.y > 0.0f)\n            {\n                float _1089;\n                if (_1051)\n                {\n                    _1089 = fa_world_pos.y - (_243_fa_fog_c.y * _1047);\n                }\n                else\n                {\n                    _1089 = _243_fa_camera_pos.y;\n                }\n                float _1110 = lerp(_1089, fa_world_pos.y, clamp(_243_fa_fog_b.x / _1052, 0.0f, 1.0f));\n                float _1114 = fa_world_pos.y - _1110;\n                float _1119 = _1110 - _243_fa_fog_b.z;\n                float _1124 = fa_world_pos.y - _243_fa_fog_b.z;\n                bool _1127 = _1119 <= 0.0f;\n                bool _1128 = !_1127;\n                bool _1134;\n                if (_1128)\n                {\n                    _1134 = _243_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1134 = _1127;\n                }\n                float _1135;\n                if (_1134)\n                {\n                    _1135 = _243_fa_fog_b.y;\n                }\n                else\n                {\n                    _1135 = _243_fa_fog_b.y * exp(-min(_243_fa_fog_b.w * _1119, 80.0f));\n                }\n                bool _1162;\n                if (_1128)\n                {\n                    _1162 = _243_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1162 = _1127;\n                }\n                float _1163;\n                if (_1162)\n                {\n                    _1163 = _243_fa_fog_b.y * _1119;\n                }\n                else\n                {\n                    _1163 = (_243_fa_fog_b.y * (1.0f - exp(-min(_243_fa_fog_b.w * _1119, 80.0f)))) / _243_fa_fog_b.w;\n                }\n                bool _1188 = _1124 <= 0.0f;\n                bool _1195;\n                if (!_1188)\n                {\n                    _1195 = _243_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1195 = _1188;\n                }\n                float _1196;\n                if (_1195)\n                {\n                    _1196 = _243_fa_fog_b.y * _1124;\n                }\n                else\n                {\n                    _1196 = (_243_fa_fog_b.y * (1.0f - exp(-min(_243_fa_fog_b.w * _1124, 80.0f)))) / _243_fa_fog_b.w;\n                }\n                float _1223;\n                if (abs(_1114) < 0.001000000047497451305389404296875f)\n                {\n                    _1223 = _1135;\n                }\n                else\n                {\n                    _1223 = (_1196 - _1163) / _1114;\n                }\n                tau += (_1064 * max(_1223, 0.0f));\n            }\n            result = lerp(result, _243_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _1291);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_68",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_165",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_212",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_243",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_808",
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
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 6
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 6
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
          },
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
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2
          },
          {
            "slot": 7,
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
    "prepass": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float _63_lift : packoffset(c0);\n    float _63_fa_pad0 : packoffset(c0.y);\n    float _63_fa_pad1 : packoffset(c0.z);\n    float _63_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _160_fa_view_proj : packoffset(c0);\n    row_major float4x4 _160_fa_light_vp : packoffset(c4);\n    float4 _160_fa_uv_scale : packoffset(c8);\n    float4 _160_fa_time : packoffset(c9);\n};\n\nTexture2D<float4> fa_vs_height : register(t0);\nSamplerState fa_vs_height_smp : register(s6);\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _103 = cross(model[1].xyz, model[2].xyz);\n    float _108 = (dot(model[0].xyz, _103) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _325 = { mul(float4(position, 1.0f), model).xyz, (((_103 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _108, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _108), texcoord0 * _160_fa_uv_scale.xy, color, position };\n    return _325;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (fa_vs_height.SampleLevel(fa_vs_height_smp, v.uv, 0.0f).x * _63_lift);\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _204 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_204, _160_fa_light_vp).z;\n    fa_pre_r0 = float3(_160_fa_light_vp[0].x, _160_fa_light_vp[1].x, _160_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_160_fa_light_vp[0].y, _160_fa_light_vp[1].y, _160_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_160_fa_light_vp[0].z, _160_fa_light_vp[1].z, _160_fa_light_vp[2].z);\n    gl_Position = mul(_204, _160_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _229_fa_camera_pos : packoffset(c0);\n    float4 _229_fa_ambient : packoffset(c1);\n    float4 _229_fa_base_color : packoffset(c2);\n    float4 _229_fa_emissive : packoffset(c3);\n    float4 _229_fa_model_emissive : packoffset(c4);\n    float4 _229_fa_pbr : packoffset(c5);\n    float4 _229_fa_maps : packoffset(c6);\n    float4 _229_fa_fog : packoffset(c7);\n    float4 _229_fa_fog_b : packoffset(c8);\n    float4 _229_fa_fog_c : packoffset(c9);\n    float4 _229_fa_counts : packoffset(c10);\n    float4 _229_fa_env_sky : packoffset(c11);\n    float4 _229_fa_env_horizon : packoffset(c12);\n    float4 _229_fa_time : packoffset(c13);\n};\n\nTexture2D<float4> height : register(t5);\nSamplerState height_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _196 = fa_linear_to_srgb(param);\n        c = _196;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _204 = fa_srgb_to_linear(param_1);\n            c = _204;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _229_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _240 = fa_tex_fix(param_2, param_3);\n    float4 _598 = base_t;\n    _598.x = _240.x;\n    _598.y = _240.y;\n    _598.z = _240.z;\n    base_t = _598;\n    float4 _256 = (_598 * _229_fa_base_color) * i.vertex_color;\n    float3 _579 = i.world_normal;\n    if (_229_fa_maps.z > 0.5f)\n    {\n        float param_4 = _229_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _289 = fa_tex_fix(param_6, param_7);\n        float3 _293 = (_289 * 2.0f) - 1.0f.xxx;\n        float2 _298 = _293.xy * _229_fa_maps.x;\n        float3 _606 = _293;\n        _606.x = _298.x;\n        _606.y = _298.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _606;\n        _579 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _229_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _327 = fa_tex_fix(param_12, param_13);\n    float4 _609 = mrt;\n    _609.x = _327.x;\n    _609.y = _327.y;\n    _609.z = _327.z;\n    mrt = _609;\n    float param_14 = _229_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _368 = fa_tex_fix(param_16, param_17);\n    float param_18 = _229_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _395 = fa_tex_fix(param_20, param_21);\n    Surface _591 = { _256.xyz, _256.w, _579, clamp(_229_fa_pbr.x * _327.z, 0.0f, 1.0f), clamp(_229_fa_pbr.y * _327.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_229_fa_maps.y * (_368.x - 1.0f)), _229_fa_emissive.xyz + (_229_fa_model_emissive.xyz * _395) };\n    return _591;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= lerp(0.5f, 1.0f, height.Sample(height_smp, i.uv).x);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _526 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _526 = -_526;\n    }\n    float3 _441 = normalize(_229_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _539 = { fa_world_pos, _526, fa_world_tangent, fa_uv, fa_vertex_color, _441, gl_FrontFacing };\n    SurfaceInput param = _539;\n    SurfaceInput _547 = { fa_world_pos, _526, fa_world_tangent, fa_uv, fa_vertex_color, _441, gl_FrontFacing };\n    SurfaceInput param_1 = _547;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _456 = normalize(param_2.normal);\n    float3 _471 = normalize(float3(dot(fa_pre_r0, _456), dot(fa_pre_r1, _456), dot(fa_pre_r2, _456)));\n    float _483 = _471.z;\n    float2 e = _471.xy / ((abs(_471.x) + abs(_471.y)) + abs(_483)).xx;\n    if (_483 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_63",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_160",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_229",
            "hlsl_register_b_n": 1
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
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 1
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
              "hlsl_register_t_n": 2
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
              "hlsl_register_t_n": 3
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
              "hlsl_register_t_n": 4
            }
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 6
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float _68_lift : packoffset(c0);\n    float _68_fa_pad0 : packoffset(c0.y);\n    float _68_fa_pad1 : packoffset(c0.z);\n    float _68_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _165_fa_view_proj : packoffset(c0);\n    row_major float4x4 _165_fa_light_vp : packoffset(c4);\n    float4 _165_fa_uv_scale : packoffset(c8);\n    float4 _165_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _212_fa_joint_rows[192] : packoffset(c0);\n};\n\nTexture2D<float4> fa_vs_height : register(t0);\nSamplerState fa_vs_height_smp : register(s6);\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _203 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_212_fa_joint_rows[_203] * weights[i]);\n        r1 += (_212_fa_joint_rows[_203 + 1] * weights[i]);\n        r2 += (_212_fa_joint_rows[_203 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _108 = cross(model[1].xyz, model[2].xyz);\n    float _113 = (dot(model[0].xyz, _108) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _446 = { mul(float4(position, 1.0f), model).xyz, (((_108 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _113, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _113), texcoord0 * _165_fa_uv_scale.xy, color, position };\n    return _446;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (fa_vs_height.SampleLevel(fa_vs_height_smp, v.uv, 0.0f).x * _68_lift);\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _317 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_317, _165_fa_light_vp).z;\n    fa_pre_r0 = float3(_165_fa_light_vp[0].x, _165_fa_light_vp[1].x, _165_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_165_fa_light_vp[0].y, _165_fa_light_vp[1].y, _165_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_165_fa_light_vp[0].z, _165_fa_light_vp[1].z, _165_fa_light_vp[2].z);\n    gl_Position = mul(_317, _165_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _229_fa_camera_pos : packoffset(c0);\n    float4 _229_fa_ambient : packoffset(c1);\n    float4 _229_fa_base_color : packoffset(c2);\n    float4 _229_fa_emissive : packoffset(c3);\n    float4 _229_fa_model_emissive : packoffset(c4);\n    float4 _229_fa_pbr : packoffset(c5);\n    float4 _229_fa_maps : packoffset(c6);\n    float4 _229_fa_fog : packoffset(c7);\n    float4 _229_fa_fog_b : packoffset(c8);\n    float4 _229_fa_fog_c : packoffset(c9);\n    float4 _229_fa_counts : packoffset(c10);\n    float4 _229_fa_env_sky : packoffset(c11);\n    float4 _229_fa_env_horizon : packoffset(c12);\n    float4 _229_fa_time : packoffset(c13);\n};\n\nTexture2D<float4> height : register(t5);\nSamplerState height_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _196 = fa_linear_to_srgb(param);\n        c = _196;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _204 = fa_srgb_to_linear(param_1);\n            c = _204;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _229_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _240 = fa_tex_fix(param_2, param_3);\n    float4 _598 = base_t;\n    _598.x = _240.x;\n    _598.y = _240.y;\n    _598.z = _240.z;\n    base_t = _598;\n    float4 _256 = (_598 * _229_fa_base_color) * i.vertex_color;\n    float3 _579 = i.world_normal;\n    if (_229_fa_maps.z > 0.5f)\n    {\n        float param_4 = _229_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _289 = fa_tex_fix(param_6, param_7);\n        float3 _293 = (_289 * 2.0f) - 1.0f.xxx;\n        float2 _298 = _293.xy * _229_fa_maps.x;\n        float3 _606 = _293;\n        _606.x = _298.x;\n        _606.y = _298.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _606;\n        _579 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _229_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _327 = fa_tex_fix(param_12, param_13);\n    float4 _609 = mrt;\n    _609.x = _327.x;\n    _609.y = _327.y;\n    _609.z = _327.z;\n    mrt = _609;\n    float param_14 = _229_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _368 = fa_tex_fix(param_16, param_17);\n    float param_18 = _229_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _395 = fa_tex_fix(param_20, param_21);\n    Surface _591 = { _256.xyz, _256.w, _579, clamp(_229_fa_pbr.x * _327.z, 0.0f, 1.0f), clamp(_229_fa_pbr.y * _327.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_229_fa_maps.y * (_368.x - 1.0f)), _229_fa_emissive.xyz + (_229_fa_model_emissive.xyz * _395) };\n    return _591;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= lerp(0.5f, 1.0f, height.Sample(height_smp, i.uv).x);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _526 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _526 = -_526;\n    }\n    float3 _441 = normalize(_229_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _539 = { fa_world_pos, _526, fa_world_tangent, fa_uv, fa_vertex_color, _441, gl_FrontFacing };\n    SurfaceInput param = _539;\n    SurfaceInput _547 = { fa_world_pos, _526, fa_world_tangent, fa_uv, fa_vertex_color, _441, gl_FrontFacing };\n    SurfaceInput param_1 = _547;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _456 = normalize(param_2.normal);\n    float3 _471 = normalize(float3(dot(fa_pre_r0, _456), dot(fa_pre_r1, _456), dot(fa_pre_r2, _456)));\n    float _483 = _471.z;\n    float2 e = _471.xy / ((abs(_471.x) + abs(_471.y)) + abs(_483)).xx;\n    if (_483 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_68",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_165",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_212",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_229",
            "hlsl_register_b_n": 1
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
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 1
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
              "hlsl_register_t_n": 2
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
              "hlsl_register_t_n": 3
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
              "hlsl_register_t_n": 4
            }
          },
          {
            "texture": {
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 6
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2
          }
        ]
      }
    },
    "shadow": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float _54_lift : packoffset(c0);\n    float _54_fa_pad0 : packoffset(c0.y);\n    float _54_fa_pad1 : packoffset(c0.z);\n    float _54_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _151_fa_view_proj : packoffset(c0);\n    row_major float4x4 _151_fa_light_vp : packoffset(c4);\n    float4 _151_fa_uv_scale : packoffset(c8);\n    float4 _151_fa_time : packoffset(c9);\n};\n\nTexture2D<float4> fa_vs_height : register(t0);\nSamplerState fa_vs_height_smp : register(s6);\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _99 = (dot(model[0].xyz, _94) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _277 = { mul(float4(position, 1.0f), model).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _99, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _99), texcoord0 * _151_fa_uv_scale.xy, color, position };\n    return _277;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (fa_vs_height.SampleLevel(fa_vs_height_smp, v.uv, 0.0f).x * _54_lift);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _151_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
      "fs": "static float4 gl_FragCoord;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nvoid frag_main()\n{\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "type": "vec4",
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
            "type": "vec3",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_54",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_151",
            "hlsl_register_b_n": 0
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 6
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float _59_lift : packoffset(c0);\n    float _59_fa_pad0 : packoffset(c0.y);\n    float _59_fa_pad1 : packoffset(c0.z);\n    float _59_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _156_fa_view_proj : packoffset(c0);\n    row_major float4x4 _156_fa_light_vp : packoffset(c4);\n    float4 _156_fa_uv_scale : packoffset(c8);\n    float4 _156_fa_time : packoffset(c9);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _203_fa_joint_rows[192] : packoffset(c0);\n};\n\nTexture2D<float4> fa_vs_height : register(t0);\nSamplerState fa_vs_height_smp : register(s6);\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _194 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_203_fa_joint_rows[_194] * weights[i]);\n        r1 += (_203_fa_joint_rows[_194 + 1] * weights[i]);\n        r2 += (_203_fa_joint_rows[_194 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _104 = (dot(model[0].xyz, _99) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _398 = { mul(float4(position, 1.0f), model).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _104, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _104), texcoord0 * _156_fa_uv_scale.xy, color, position };\n    return _398;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (fa_vs_height.SampleLevel(fa_vs_height_smp, v.uv, 0.0f).x * _59_lift);\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mul(float4(param_8.world_pos, 1.0f), _156_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
      "fs": "static float4 gl_FragCoord;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nvoid frag_main()\n{\n    fa_frag_color = float4(gl_FragCoord.z, 0.0f, 0.0f, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "type": "vec4",
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
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 7
          },
          {
            "slot": 8,
            "type": "vec2",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_59",
            "hlsl_register_b_n": 4
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_156",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_203",
            "hlsl_register_b_n": 3
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 6
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6
          }
        ]
      }
    }
  }
}
