{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "f33a36e751e8501a5c7167efe23b832a4315ec133394a3a234e9f06584552465",
  "slang": "hlsl5",
  "params": [
    "lift"
  ],
  "textures": [
    "height"
  ],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float _63_lift : packoffset(c0);\n    float _63_fa_pad0 : packoffset(c0.y);\n    float _63_fa_pad1 : packoffset(c0.z);\n    float _63_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _160_fa_view_proj : packoffset(c0);\n    row_major float4x4 _160_fa_light_vp : packoffset(c4);\n    float4 _160_fa_uv_scale : packoffset(c8);\n    float4 _160_fa_time : packoffset(c9);\n    float4 _160_fa_lm_so : packoffset(c10);\n};\n\nTexture2D<float4> fa_vs_height : register(t0);\nSamplerState fa_vs_height_smp : register(s6);\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float3 fa_lm : TEXCOORD6;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _103 = cross(model[1].xyz, model[2].xyz);\n    float _108 = (dot(model[0].xyz, _103) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _298 = { mul(float4(position, 1.0f), model).xyz, (((_103 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _108, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _108), texcoord0 * _160_fa_uv_scale.xy, color, position };\n    return _298;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (fa_vs_height.SampleLevel(fa_vs_height_smp, v.uv, 0.0f).x * _63_lift);\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _200 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = mul(_200, _160_fa_light_vp);\n    gl_Position = mul(_200, _160_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _175_fa_light_pos[32] : packoffset(c0);\n    float4 _175_fa_light_color[32] : packoffset(c32);\n    float4 _175_fa_light_dir[32] : packoffset(c64);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _293_fa_camera_pos : packoffset(c0);\n    float4 _293_fa_ambient : packoffset(c1);\n    float4 _293_fa_base_color : packoffset(c2);\n    float4 _293_fa_emissive : packoffset(c3);\n    float4 _293_fa_model_emissive : packoffset(c4);\n    float4 _293_fa_pbr : packoffset(c5);\n    float4 _293_fa_maps : packoffset(c6);\n    float4 _293_fa_fog : packoffset(c7);\n    float4 _293_fa_fog_b : packoffset(c8);\n    float4 _293_fa_fog_c : packoffset(c9);\n    float4 _293_fa_counts : packoffset(c10);\n    float4 _293_fa_env_sky : packoffset(c11);\n    float4 _293_fa_env_horizon : packoffset(c12);\n    float4 _293_fa_time : packoffset(c13);\n};\n\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\nTextureCube<float4> fa_env_tex : register(t7);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t8);\nTexture2D<float4> height : register(t6);\nSamplerState height_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float3 fa_lm : TEXCOORD6;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _730 = fa_linear_to_srgb(param);\n        c = _730;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _738 = fa_srgb_to_linear(param_1);\n            c = _738;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _103;\n    if (i.front_facing)\n    {\n        _103 = i.world_normal;\n    }\n    else\n    {\n        _103 = -i.world_normal;\n    }\n    float3 _127 = normalize(i.world_tangent.xyz - (_103 * dot(_103, i.world_tangent.xyz)));\n    float3 _155 = normalize(((_127 * m.x) + ((cross(_103, _127) * i.world_tangent.w) * m.y)) + (_103 * m.z));\n    float3 _158;\n    if (i.front_facing)\n    {\n        _158 = _155;\n    }\n    else\n    {\n        _158 = -_155;\n    }\n    return _158;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _293_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _770 = fa_tex_fix(param_2, param_3);\n    float4 _1576 = base_t;\n    _1576.x = _770.x;\n    _1576.y = _770.y;\n    _1576.z = _770.z;\n    base_t = _1576;\n    float4 _784 = (_1576 * _293_fa_base_color) * i.vertex_color;\n    float3 _1544 = i.world_normal;\n    if (_293_fa_maps.z > 0.5f)\n    {\n        float param_4 = _293_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _817 = fa_tex_fix(param_6, param_7);\n        float3 _820 = (_817 * 2.0f) - 1.0f.xxx;\n        float2 _825 = _820.xy * _293_fa_maps.x;\n        float3 _1584 = _820;\n        _1584.x = _825.x;\n        _1584.y = _825.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1584;\n        _1544 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _293_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _854 = fa_tex_fix(param_12, param_13);\n    float4 _1587 = mrt;\n    _1587.x = _854.x;\n    _1587.y = _854.y;\n    _1587.z = _854.z;\n    mrt = _1587;\n    float param_14 = _293_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _893 = fa_tex_fix(param_16, param_17);\n    float param_18 = _293_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _920 = fa_tex_fix(param_20, param_21);\n    Surface _1556 = { _784.xyz, _784.w, _1544, clamp(_293_fa_pbr.x * _854.z, 0.0f, 1.0f), clamp(_293_fa_pbr.y * _854.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_293_fa_maps.y * (_893.x - 1.0f)), _293_fa_emissive.xyz + (_293_fa_model_emissive.xyz * _920) };\n    return _1556;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= lerp(0.5f, 1.0f, height.Sample(height_smp, i.uv).x);\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_293_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _293_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _186 = _175_fa_light_color[li].w < 0.5f;\n    float3 l;\n    if (_186)\n    {\n        l = normalize(_175_fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _204 = _175_fa_light_pos[li].xyz - world_pos;\n        float _206 = length(_204);\n        dist = _206;\n        l = _204 / max(_206, 9.9999997473787516355514526367188e-05f).xxx;\n        float _222 = _206 / max(_175_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n        float _228 = clamp(1.0f - (_222 * _222), 0.0f, 1.0f);\n        atten = _228 * _228;\n        if (_175_fa_light_color[li].w > 1.5f)\n        {\n            atten *= smoothstep(_175_fa_light_dir[li].w, lerp(_175_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_175_fa_light_dir[li].xyz)));\n        }\n    }\n    int _279;\n    if (_186)\n    {\n        _279 = 0;\n    }\n    else\n    {\n        _279 = (_175_fa_light_color[li].w > 1.5f) ? 2 : 1;\n    }\n    LightSample _1522 = { l, _175_fa_light_color[li].xyz * atten, atten, 1.0f, dist, _279 };\n    return _1522;\n}\n\nfloat fa_shadow_pcf(float4 coord, float3 n, float3 l)\n{\n    if (_293_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _306 = coord.xyz / coord.w.xxx;\n    float3 p = _306;\n    float2 suv = (_306.xy * 0.5f) + 0.5f.xx;\n    if (_293_fa_counts.z > 0.5f)\n    {\n        float3 _1558 = p;\n        _1558.z = (_1558.z * 0.5f) + 0.5f;\n        p = _1558;\n    }\n    else\n    {\n        float2 _1561 = suv;\n        _1561.y = 1.0f - _1561.y;\n        suv = _1561;\n    }\n    bool _334 = suv.x < 0.0f;\n    bool _341;\n    if (!_334)\n    {\n        _341 = suv.x > 1.0f;\n    }\n    else\n    {\n        _341 = _334;\n    }\n    bool _348;\n    if (!_341)\n    {\n        _348 = suv.y < 0.0f;\n    }\n    else\n    {\n        _348 = _341;\n    }\n    bool _355;\n    if (!_348)\n    {\n        _355 = suv.y > 1.0f;\n    }\n    else\n    {\n        _355 = _348;\n    }\n    bool _362;\n    if (!_355)\n    {\n        _362 = p.z > 1.0f;\n    }\n    else\n    {\n        _362 = _355;\n    }\n    if (_362)\n    {\n        return 1.0f;\n    }\n    float _377 = _293_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _377) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _293_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _638 = fa_light_sample(param, param_1);\n    float3 _1529 = _638.direction;\n    float3 _1524 = _638.color;\n    float _1531 = _638.attenuation;\n    float _1526 = _638.shadow;\n    int _1534 = _638.type;\n    if ((_1534 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _1529;\n        float _652 = fa_shadow_factor(param_2, param_3);\n        _1526 = _652;\n        _1524 = _175_fa_light_color[li].xyz * (_1531 * _652);\n    }\n    LightSample _1541 = { _1529, _1524, _1531, _1526, _638._distance, _1534 };\n    return _1541;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _574 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _577 = _574.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_577 * _577, exp2((-9.27999973297119140625f) * ndv)) * _577) + _574.y)) + _574.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_293_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _293_fa_env_horizon.w).xyz;\n    }\n    float _477 = rough * rough;\n    float _508 = 0.60000002384185791015625f * _477;\n    return lerp(lerp(_293_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_293_fa_env_horizon.xyz, _293_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _477)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _508, 0.0500000007450580596923828125f + _508, d.y).xxx), ((_293_fa_env_sky.xyz + _293_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_477 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _616 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _616.x) + _616.y.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _1449 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1449 = -_1449;\n    }\n    float3 _986 = normalize(_293_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _1462 = { fa_world_pos, _1449, fa_world_tangent, fa_uv, fa_vertex_color, _986, gl_FrontFacing };\n    SurfaceInput param = _1462;\n    Surface _991 = fa_standard_surface(param);\n    float3 _1472 = _991.albedo;\n    float _1473 = _991.alpha;\n    float3 _1474 = _991.normal;\n    float _1475 = _991.metallic;\n    float _1476 = _991.roughness;\n    float _1477 = _991.occlusion;\n    float3 _1478 = _991.emission;\n    SurfaceInput _1470 = { fa_world_pos, _1449, fa_world_tangent, fa_uv, fa_vertex_color, _986, gl_FrontFacing };\n    SurfaceInput param_1 = _1470;\n    Surface param_2 = _991;\n    surface(param_1, param_2);\n    _1472 = param_2.albedo;\n    _1473 = param_2.alpha;\n    _1474 = param_2.normal;\n    _1475 = param_2.metallic;\n    _1476 = param_2.roughness;\n    _1477 = param_2.occlusion;\n    _1478 = param_2.emission;\n    float3 result;\n    if (_293_fa_emissive.w > 0.5f)\n    {\n        result = _1472;\n    }\n    else\n    {\n        float3 _1013 = normalize(_1474);\n        float _1020 = clamp(_1475, 0.0f, 1.0f);\n        float _1024 = clamp(_1476, 0.0500000007450580596923828125f, 1.0f);\n        float _1028 = _1024 * _1024;\n        float _1032 = _1028 * _1028;\n        float _1037 = max(dot(_1013, _986), 9.9999997473787516355514526367188e-05f);\n        float3 _1043 = _1472 * (1.0f - _1020);\n        float3 _1051 = lerp(0.039999999105930328369140625f.xxx, _1472, _1020.xxx);\n        float3 param_3 = _1013;\n        float3 lit = (fa_indirect_diffuse(param_3) * _1043) * _1477;\n        int _1064 = int(_293_fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _1064)\n            {\n                break;\n            }\n            int param_4 = li;\n            float3 param_5 = fa_world_pos;\n            float3 param_6 = _1449;\n            LightSample _1088 = fa_light_shadowed(param_4, param_5, param_6);\n            float3 _1507 = _1088.direction;\n            float _1096 = max(dot(_1013, _1507), 0.0f);\n            float3 _1107 = normalize(_1507 + _986);\n            float _1112 = max(dot(_1013, _1107), 0.0f);\n            float _1125 = ((_1112 * _1112) * (_1032 - 1.0f)) + 1.0f;\n            lit += (((_1043 + (((_1051 + ((1.0f.xxx - _1051) * pow(1.0f - max(dot(_986, _1107), 0.0f), 5.0f))) * (((_1032 / ((3.1415927410125732421875f * _1125) * _1125)) * (0.5f / max(lerp((2.0f * _1096) * _1037, _1096 + _1037, _1028), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _1096))) * _175_fa_light_color[li].xyz) * (_1096 * (_1088.attenuation * _1088.shadow)));\n        }\n        float3 param_7 = _1013;\n        float3 param_8 = _986;\n        float3 param_9 = _1051;\n        float param_10 = _1024;\n        float3 _1195 = lit;\n        float3 _1196 = _1195 + (fa_sky_reflection(param_7, param_8, param_9, param_10) * _1477);\n        lit = _1196;\n        result = _1196;\n    }\n    result += _1478;\n    bool _1205 = _293_fa_fog.w > 0.0f;\n    bool _1213;\n    if (!_1205)\n    {\n        _1213 = _293_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1213 = _1205;\n    }\n    if (_1213)\n    {\n        float3 _1222 = fa_world_pos - _293_fa_camera_pos.xyz;\n        float _1229 = dot(_1222, _293_fa_fog_c.xyz);\n        bool _1233 = _293_fa_fog_c.w > 0.5f;\n        float _1234;\n        if (_1233)\n        {\n            _1234 = _1229;\n        }\n        else\n        {\n            _1234 = length(_1222);\n        }\n        float _1246 = _1234 - _293_fa_fog_b.x;\n        if (_1246 > 0.0f)\n        {\n            float _1255 = _293_fa_fog.w * _1246;\n            float tau = _1255 * _1255;\n            if (_293_fa_fog_b.y > 0.0f)\n            {\n                float _1271;\n                if (_1233)\n                {\n                    _1271 = fa_world_pos.y - (_293_fa_fog_c.y * _1229);\n                }\n                else\n                {\n                    _1271 = _293_fa_camera_pos.y;\n                }\n                float _1292 = lerp(_1271, fa_world_pos.y, clamp(_293_fa_fog_b.x / _1234, 0.0f, 1.0f));\n                float _1296 = fa_world_pos.y - _1292;\n                float _1301 = _1292 - _293_fa_fog_b.z;\n                float _1306 = fa_world_pos.y - _293_fa_fog_b.z;\n                bool _1309 = _1301 <= 0.0f;\n                bool _1310 = !_1309;\n                bool _1316;\n                if (_1310)\n                {\n                    _1316 = _293_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1316 = _1309;\n                }\n                float _1317;\n                if (_1316)\n                {\n                    _1317 = _293_fa_fog_b.y;\n                }\n                else\n                {\n                    _1317 = _293_fa_fog_b.y * exp(-min(_293_fa_fog_b.w * _1301, 80.0f));\n                }\n                bool _1344;\n                if (_1310)\n                {\n                    _1344 = _293_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1344 = _1309;\n                }\n                float _1345;\n                if (_1344)\n                {\n                    _1345 = _293_fa_fog_b.y * _1301;\n                }\n                else\n                {\n                    _1345 = (_293_fa_fog_b.y * (1.0f - exp(-min(_293_fa_fog_b.w * _1301, 80.0f)))) / _293_fa_fog_b.w;\n                }\n                bool _1370 = _1306 <= 0.0f;\n                bool _1377;\n                if (!_1370)\n                {\n                    _1377 = _293_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1377 = _1370;\n                }\n                float _1378;\n                if (_1377)\n                {\n                    _1378 = _293_fa_fog_b.y * _1306;\n                }\n                else\n                {\n                    _1378 = (_293_fa_fog_b.y * (1.0f - exp(-min(_293_fa_fog_b.w * _1306, 80.0f)))) / _293_fa_fog_b.w;\n                }\n                float _1405;\n                if (abs(_1296) < 0.001000000047497451305389404296875f)\n                {\n                    _1405 = _1317;\n                }\n                else\n                {\n                    _1405 = (_1378 - _1345) / _1296;\n                }\n                tau += (_1246 * max(_1405, 0.0f));\n            }\n            result = lerp(result, _293_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _1473);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_160",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_175",
            "hlsl_register_b_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_293",
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
          },
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "hlsl_register_t_n": 7
            }
          },
          {
            "texture": {
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "hlsl_register_t_n": 8
            }
          },
          {
            "texture": {
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 9
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
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "hlsl_register_s_n": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 10
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
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float _68_lift : packoffset(c0);\n    float _68_fa_pad0 : packoffset(c0.y);\n    float _68_fa_pad1 : packoffset(c0.z);\n    float _68_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _165_fa_view_proj : packoffset(c0);\n    row_major float4x4 _165_fa_light_vp : packoffset(c4);\n    float4 _165_fa_uv_scale : packoffset(c8);\n    float4 _165_fa_time : packoffset(c9);\n    float4 _165_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _212_fa_joint_rows[192] : packoffset(c0);\n};\n\nTexture2D<float4> fa_vs_height : register(t0);\nSamplerState fa_vs_height_smp : register(s6);\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_shadow_pos;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float3 fa_lm : TEXCOORD6;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _203 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_212_fa_joint_rows[_203] * weights[i]);\n        r1 += (_212_fa_joint_rows[_203 + 1] * weights[i]);\n        r2 += (_212_fa_joint_rows[_203 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _108 = cross(model[1].xyz, model[2].xyz);\n    float _113 = (dot(model[0].xyz, _108) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _419 = { mul(float4(position, 1.0f), model).xyz, (((_108 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _113, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _113), texcoord0 * _165_fa_uv_scale.xy, color, position };\n    return _419;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (fa_vs_height.SampleLevel(fa_vs_height_smp, v.uv, 0.0f).x * _68_lift);\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _313 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = mul(_313, _165_fa_light_vp);\n    gl_Position = mul(_313, _165_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_shadow_pos = fa_shadow_pos;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_lights : register(b2)\n{\n    float4 _175_fa_light_pos[32] : packoffset(c0);\n    float4 _175_fa_light_color[32] : packoffset(c32);\n    float4 _175_fa_light_dir[32] : packoffset(c64);\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _293_fa_camera_pos : packoffset(c0);\n    float4 _293_fa_ambient : packoffset(c1);\n    float4 _293_fa_base_color : packoffset(c2);\n    float4 _293_fa_emissive : packoffset(c3);\n    float4 _293_fa_model_emissive : packoffset(c4);\n    float4 _293_fa_pbr : packoffset(c5);\n    float4 _293_fa_maps : packoffset(c6);\n    float4 _293_fa_fog : packoffset(c7);\n    float4 _293_fa_fog_b : packoffset(c8);\n    float4 _293_fa_fog_c : packoffset(c9);\n    float4 _293_fa_counts : packoffset(c10);\n    float4 _293_fa_env_sky : packoffset(c11);\n    float4 _293_fa_env_horizon : packoffset(c12);\n    float4 _293_fa_time : packoffset(c13);\n};\n\nTexture2D<float4> fa_shadow_tex : register(t1);\nSamplerState fa_shadow_smp : register(s1);\nTextureCube<float4> fa_env_tex : register(t7);\nSamplerState fa_env_smp : register(s10);\nTextureCube<float4> fa_irr_tex : register(t8);\nTexture2D<float4> height : register(t6);\nSamplerState height_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic bool gl_FrontFacing;\nstatic float4 fa_shadow_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float4 fa_shadow_pos : TEXCOORD5;\n    float3 fa_lm : TEXCOORD6;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _730 = fa_linear_to_srgb(param);\n        c = _730;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _738 = fa_srgb_to_linear(param_1);\n            c = _738;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _103;\n    if (i.front_facing)\n    {\n        _103 = i.world_normal;\n    }\n    else\n    {\n        _103 = -i.world_normal;\n    }\n    float3 _127 = normalize(i.world_tangent.xyz - (_103 * dot(_103, i.world_tangent.xyz)));\n    float3 _155 = normalize(((_127 * m.x) + ((cross(_103, _127) * i.world_tangent.w) * m.y)) + (_103 * m.z));\n    float3 _158;\n    if (i.front_facing)\n    {\n        _158 = _155;\n    }\n    else\n    {\n        _158 = -_155;\n    }\n    return _158;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _293_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _770 = fa_tex_fix(param_2, param_3);\n    float4 _1576 = base_t;\n    _1576.x = _770.x;\n    _1576.y = _770.y;\n    _1576.z = _770.z;\n    base_t = _1576;\n    float4 _784 = (_1576 * _293_fa_base_color) * i.vertex_color;\n    float3 _1544 = i.world_normal;\n    if (_293_fa_maps.z > 0.5f)\n    {\n        float param_4 = _293_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _817 = fa_tex_fix(param_6, param_7);\n        float3 _820 = (_817 * 2.0f) - 1.0f.xxx;\n        float2 _825 = _820.xy * _293_fa_maps.x;\n        float3 _1584 = _820;\n        _1584.x = _825.x;\n        _1584.y = _825.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _1584;\n        _1544 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _293_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _854 = fa_tex_fix(param_12, param_13);\n    float4 _1587 = mrt;\n    _1587.x = _854.x;\n    _1587.y = _854.y;\n    _1587.z = _854.z;\n    mrt = _1587;\n    float param_14 = _293_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _893 = fa_tex_fix(param_16, param_17);\n    float param_18 = _293_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _920 = fa_tex_fix(param_20, param_21);\n    Surface _1556 = { _784.xyz, _784.w, _1544, clamp(_293_fa_pbr.x * _854.z, 0.0f, 1.0f), clamp(_293_fa_pbr.y * _854.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_293_fa_maps.y * (_893.x - 1.0f)), _293_fa_emissive.xyz + (_293_fa_model_emissive.xyz * _920) };\n    return _1556;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= lerp(0.5f, 1.0f, height.Sample(height_smp, i.uv).x);\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_293_fa_env_sky.w > 0.5f)\n    {\n        return fa_irr_tex.SampleLevel(fa_env_smp, n, 0.0f).xyz;\n    }\n    return _293_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nLightSample fa_light_sample(int li, float3 world_pos)\n{\n    float atten = 1.0f;\n    float dist = 0.0f;\n    bool _186 = _175_fa_light_color[li].w < 0.5f;\n    float3 l;\n    if (_186)\n    {\n        l = normalize(_175_fa_light_pos[li].xyz);\n    }\n    else\n    {\n        float3 _204 = _175_fa_light_pos[li].xyz - world_pos;\n        float _206 = length(_204);\n        dist = _206;\n        l = _204 / max(_206, 9.9999997473787516355514526367188e-05f).xxx;\n        float _222 = _206 / max(_175_fa_light_pos[li].w, 0.001000000047497451305389404296875f);\n        float _228 = clamp(1.0f - (_222 * _222), 0.0f, 1.0f);\n        atten = _228 * _228;\n        if (_175_fa_light_color[li].w > 1.5f)\n        {\n            atten *= smoothstep(_175_fa_light_dir[li].w, lerp(_175_fa_light_dir[li].w, 1.0f, 0.25f), dot(-l, normalize(_175_fa_light_dir[li].xyz)));\n        }\n    }\n    int _279;\n    if (_186)\n    {\n        _279 = 0;\n    }\n    else\n    {\n        _279 = (_175_fa_light_color[li].w > 1.5f) ? 2 : 1;\n    }\n    LightSample _1522 = { l, _175_fa_light_color[li].xyz * atten, atten, 1.0f, dist, _279 };\n    return _1522;\n}\n\nfloat fa_shadow_pcf(float4 coord, float3 n, float3 l)\n{\n    if (_293_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    float3 _306 = coord.xyz / coord.w.xxx;\n    float3 p = _306;\n    float2 suv = (_306.xy * 0.5f) + 0.5f.xx;\n    if (_293_fa_counts.z > 0.5f)\n    {\n        float3 _1558 = p;\n        _1558.z = (_1558.z * 0.5f) + 0.5f;\n        p = _1558;\n    }\n    else\n    {\n        float2 _1561 = suv;\n        _1561.y = 1.0f - _1561.y;\n        suv = _1561;\n    }\n    bool _334 = suv.x < 0.0f;\n    bool _341;\n    if (!_334)\n    {\n        _341 = suv.x > 1.0f;\n    }\n    else\n    {\n        _341 = _334;\n    }\n    bool _348;\n    if (!_341)\n    {\n        _348 = suv.y < 0.0f;\n    }\n    else\n    {\n        _348 = _341;\n    }\n    bool _355;\n    if (!_348)\n    {\n        _355 = suv.y > 1.0f;\n    }\n    else\n    {\n        _355 = _348;\n    }\n    bool _362;\n    if (!_355)\n    {\n        _362 = p.z > 1.0f;\n    }\n    else\n    {\n        _362 = _355;\n    }\n    if (_362)\n    {\n        return 1.0f;\n    }\n    float _377 = _293_fa_pbr.w * (1.0f + (2.0f * (1.0f - clamp(dot(n, l), 0.0f, 1.0f))));\n    float lit = 0.0f;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _377) <= fa_shadow_tex.SampleLevel(fa_shadow_smp, suv + (float2(float(ix), float(iy)) * _293_fa_counts.y), 0.0f).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125f;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float4 param = fa_shadow_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float3 param_1 = world_pos;\n    LightSample _638 = fa_light_sample(param, param_1);\n    float3 _1529 = _638.direction;\n    float3 _1524 = _638.color;\n    float _1531 = _638.attenuation;\n    float _1526 = _638.shadow;\n    int _1534 = _638.type;\n    if ((_1534 == 0) && (li == 0))\n    {\n        float3 param_2 = gn;\n        float3 param_3 = _1529;\n        float _652 = fa_shadow_factor(param_2, param_3);\n        _1526 = _652;\n        _1524 = _175_fa_light_color[li].xyz * (_1531 * _652);\n    }\n    LightSample _1541 = { _1529, _1524, _1531, _1526, _638._distance, _1534 };\n    return _1541;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _574 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _577 = _574.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_577 * _577, exp2((-9.27999973297119140625f) * ndv)) * _577) + _574.y)) + _574.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_293_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _293_fa_env_horizon.w).xyz;\n    }\n    float _477 = rough * rough;\n    float _508 = 0.60000002384185791015625f * _477;\n    return lerp(lerp(_293_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_293_fa_env_horizon.xyz, _293_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _477)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _508, 0.0500000007450580596923828125f + _508, d.y).xxx), ((_293_fa_env_sky.xyz + _293_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_477 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _616 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _616.x) + _616.y.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _1449 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1449 = -_1449;\n    }\n    float3 _986 = normalize(_293_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _1462 = { fa_world_pos, _1449, fa_world_tangent, fa_uv, fa_vertex_color, _986, gl_FrontFacing };\n    SurfaceInput param = _1462;\n    Surface _991 = fa_standard_surface(param);\n    float3 _1472 = _991.albedo;\n    float _1473 = _991.alpha;\n    float3 _1474 = _991.normal;\n    float _1475 = _991.metallic;\n    float _1476 = _991.roughness;\n    float _1477 = _991.occlusion;\n    float3 _1478 = _991.emission;\n    SurfaceInput _1470 = { fa_world_pos, _1449, fa_world_tangent, fa_uv, fa_vertex_color, _986, gl_FrontFacing };\n    SurfaceInput param_1 = _1470;\n    Surface param_2 = _991;\n    surface(param_1, param_2);\n    _1472 = param_2.albedo;\n    _1473 = param_2.alpha;\n    _1474 = param_2.normal;\n    _1475 = param_2.metallic;\n    _1476 = param_2.roughness;\n    _1477 = param_2.occlusion;\n    _1478 = param_2.emission;\n    float3 result;\n    if (_293_fa_emissive.w > 0.5f)\n    {\n        result = _1472;\n    }\n    else\n    {\n        float3 _1013 = normalize(_1474);\n        float _1020 = clamp(_1475, 0.0f, 1.0f);\n        float _1024 = clamp(_1476, 0.0500000007450580596923828125f, 1.0f);\n        float _1028 = _1024 * _1024;\n        float _1032 = _1028 * _1028;\n        float _1037 = max(dot(_1013, _986), 9.9999997473787516355514526367188e-05f);\n        float3 _1043 = _1472 * (1.0f - _1020);\n        float3 _1051 = lerp(0.039999999105930328369140625f.xxx, _1472, _1020.xxx);\n        float3 param_3 = _1013;\n        float3 lit = (fa_indirect_diffuse(param_3) * _1043) * _1477;\n        int _1064 = int(_293_fa_counts.x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _1064)\n            {\n                break;\n            }\n            int param_4 = li;\n            float3 param_5 = fa_world_pos;\n            float3 param_6 = _1449;\n            LightSample _1088 = fa_light_shadowed(param_4, param_5, param_6);\n            float3 _1507 = _1088.direction;\n            float _1096 = max(dot(_1013, _1507), 0.0f);\n            float3 _1107 = normalize(_1507 + _986);\n            float _1112 = max(dot(_1013, _1107), 0.0f);\n            float _1125 = ((_1112 * _1112) * (_1032 - 1.0f)) + 1.0f;\n            lit += (((_1043 + (((_1051 + ((1.0f.xxx - _1051) * pow(1.0f - max(dot(_986, _1107), 0.0f), 5.0f))) * (((_1032 / ((3.1415927410125732421875f * _1125) * _1125)) * (0.5f / max(lerp((2.0f * _1096) * _1037, _1096 + _1037, _1028), 9.9999997473787516355514526367188e-05f))) * 3.1415927410125732421875f)) * step(9.9999997473787516355514526367188e-05f, _1096))) * _175_fa_light_color[li].xyz) * (_1096 * (_1088.attenuation * _1088.shadow)));\n        }\n        float3 param_7 = _1013;\n        float3 param_8 = _986;\n        float3 param_9 = _1051;\n        float param_10 = _1024;\n        float3 _1195 = lit;\n        float3 _1196 = _1195 + (fa_sky_reflection(param_7, param_8, param_9, param_10) * _1477);\n        lit = _1196;\n        result = _1196;\n    }\n    result += _1478;\n    bool _1205 = _293_fa_fog.w > 0.0f;\n    bool _1213;\n    if (!_1205)\n    {\n        _1213 = _293_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1213 = _1205;\n    }\n    if (_1213)\n    {\n        float3 _1222 = fa_world_pos - _293_fa_camera_pos.xyz;\n        float _1229 = dot(_1222, _293_fa_fog_c.xyz);\n        bool _1233 = _293_fa_fog_c.w > 0.5f;\n        float _1234;\n        if (_1233)\n        {\n            _1234 = _1229;\n        }\n        else\n        {\n            _1234 = length(_1222);\n        }\n        float _1246 = _1234 - _293_fa_fog_b.x;\n        if (_1246 > 0.0f)\n        {\n            float _1255 = _293_fa_fog.w * _1246;\n            float tau = _1255 * _1255;\n            if (_293_fa_fog_b.y > 0.0f)\n            {\n                float _1271;\n                if (_1233)\n                {\n                    _1271 = fa_world_pos.y - (_293_fa_fog_c.y * _1229);\n                }\n                else\n                {\n                    _1271 = _293_fa_camera_pos.y;\n                }\n                float _1292 = lerp(_1271, fa_world_pos.y, clamp(_293_fa_fog_b.x / _1234, 0.0f, 1.0f));\n                float _1296 = fa_world_pos.y - _1292;\n                float _1301 = _1292 - _293_fa_fog_b.z;\n                float _1306 = fa_world_pos.y - _293_fa_fog_b.z;\n                bool _1309 = _1301 <= 0.0f;\n                bool _1310 = !_1309;\n                bool _1316;\n                if (_1310)\n                {\n                    _1316 = _293_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1316 = _1309;\n                }\n                float _1317;\n                if (_1316)\n                {\n                    _1317 = _293_fa_fog_b.y;\n                }\n                else\n                {\n                    _1317 = _293_fa_fog_b.y * exp(-min(_293_fa_fog_b.w * _1301, 80.0f));\n                }\n                bool _1344;\n                if (_1310)\n                {\n                    _1344 = _293_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1344 = _1309;\n                }\n                float _1345;\n                if (_1344)\n                {\n                    _1345 = _293_fa_fog_b.y * _1301;\n                }\n                else\n                {\n                    _1345 = (_293_fa_fog_b.y * (1.0f - exp(-min(_293_fa_fog_b.w * _1301, 80.0f)))) / _293_fa_fog_b.w;\n                }\n                bool _1370 = _1306 <= 0.0f;\n                bool _1377;\n                if (!_1370)\n                {\n                    _1377 = _293_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1377 = _1370;\n                }\n                float _1378;\n                if (_1377)\n                {\n                    _1378 = _293_fa_fog_b.y * _1306;\n                }\n                else\n                {\n                    _1378 = (_293_fa_fog_b.y * (1.0f - exp(-min(_293_fa_fog_b.w * _1306, 80.0f)))) / _293_fa_fog_b.w;\n                }\n                float _1405;\n                if (abs(_1296) < 0.001000000047497451305389404296875f)\n                {\n                    _1405 = _1317;\n                }\n                else\n                {\n                    _1405 = (_1378 - _1345) / _1296;\n                }\n                tau += (_1246 * max(_1405, 0.0f));\n            }\n            result = lerp(result, _293_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _1473);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_shadow_pos = stage_input.fa_shadow_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 176,
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_175",
            "hlsl_register_b_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_293",
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
          },
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "hlsl_register_t_n": 7
            }
          },
          {
            "texture": {
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "hlsl_register_t_n": 8
            }
          },
          {
            "texture": {
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 9
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
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering",
            "hlsl_register_s_n": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 10
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
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          }
        ]
      }
    },
    "prepass": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float _63_lift : packoffset(c0);\n    float _63_fa_pad0 : packoffset(c0.y);\n    float _63_fa_pad1 : packoffset(c0.z);\n    float _63_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _160_fa_view_proj : packoffset(c0);\n    row_major float4x4 _160_fa_light_vp : packoffset(c4);\n    float4 _160_fa_uv_scale : packoffset(c8);\n    float4 _160_fa_time : packoffset(c9);\n    float4 _160_fa_lm_so : packoffset(c10);\n};\n\nTexture2D<float4> fa_vs_height : register(t0);\nSamplerState fa_vs_height_smp : register(s6);\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _103 = cross(model[1].xyz, model[2].xyz);\n    float _108 = (dot(model[0].xyz, _103) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _325 = { mul(float4(position, 1.0f), model).xyz, (((_103 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _108, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _108), texcoord0 * _160_fa_uv_scale.xy, color, position };\n    return _325;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (fa_vs_height.SampleLevel(fa_vs_height_smp, v.uv, 0.0f).x * _63_lift);\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _204 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_204, _160_fa_light_vp).z;\n    fa_pre_r0 = float3(_160_fa_light_vp[0].x, _160_fa_light_vp[1].x, _160_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_160_fa_light_vp[0].y, _160_fa_light_vp[1].y, _160_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_160_fa_light_vp[0].z, _160_fa_light_vp[1].z, _160_fa_light_vp[2].z);\n    gl_Position = mul(_204, _160_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _229_fa_camera_pos : packoffset(c0);\n    float4 _229_fa_ambient : packoffset(c1);\n    float4 _229_fa_base_color : packoffset(c2);\n    float4 _229_fa_emissive : packoffset(c3);\n    float4 _229_fa_model_emissive : packoffset(c4);\n    float4 _229_fa_pbr : packoffset(c5);\n    float4 _229_fa_maps : packoffset(c6);\n    float4 _229_fa_fog : packoffset(c7);\n    float4 _229_fa_fog_b : packoffset(c8);\n    float4 _229_fa_fog_c : packoffset(c9);\n    float4 _229_fa_counts : packoffset(c10);\n    float4 _229_fa_env_sky : packoffset(c11);\n    float4 _229_fa_env_horizon : packoffset(c12);\n    float4 _229_fa_time : packoffset(c13);\n};\n\nTexture2D<float4> height : register(t5);\nSamplerState height_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _196 = fa_linear_to_srgb(param);\n        c = _196;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _204 = fa_srgb_to_linear(param_1);\n            c = _204;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _229_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _240 = fa_tex_fix(param_2, param_3);\n    float4 _603 = base_t;\n    _603.x = _240.x;\n    _603.y = _240.y;\n    _603.z = _240.z;\n    base_t = _603;\n    float4 _256 = (_603 * _229_fa_base_color) * i.vertex_color;\n    float3 _584 = i.world_normal;\n    if (_229_fa_maps.z > 0.5f)\n    {\n        float param_4 = _229_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _289 = fa_tex_fix(param_6, param_7);\n        float3 _293 = (_289 * 2.0f) - 1.0f.xxx;\n        float2 _298 = _293.xy * _229_fa_maps.x;\n        float3 _611 = _293;\n        _611.x = _298.x;\n        _611.y = _298.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _611;\n        _584 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _229_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _327 = fa_tex_fix(param_12, param_13);\n    float4 _614 = mrt;\n    _614.x = _327.x;\n    _614.y = _327.y;\n    _614.z = _327.z;\n    mrt = _614;\n    float param_14 = _229_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _368 = fa_tex_fix(param_16, param_17);\n    float param_18 = _229_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _395 = fa_tex_fix(param_20, param_21);\n    Surface _596 = { _256.xyz, _256.w, _584, clamp(_229_fa_pbr.x * _327.z, 0.0f, 1.0f), clamp(_229_fa_pbr.y * _327.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_229_fa_maps.y * (_368.x - 1.0f)), _229_fa_emissive.xyz + (_229_fa_model_emissive.xyz * _395) };\n    return _596;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= lerp(0.5f, 1.0f, height.Sample(height_smp, i.uv).x);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _531 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _531 = -_531;\n    }\n    float3 _441 = normalize(_229_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _544 = { fa_world_pos, _531, fa_world_tangent, fa_uv, fa_vertex_color, _441, gl_FrontFacing };\n    SurfaceInput param = _544;\n    SurfaceInput _552 = { fa_world_pos, _531, fa_world_tangent, fa_uv, fa_vertex_color, _441, gl_FrontFacing };\n    SurfaceInput param_1 = _552;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _456 = normalize(param_2.normal);\n    float3 _471 = normalize(float3(dot(fa_pre_r0, _456), dot(fa_pre_r1, _456), dot(fa_pre_r2, _456)));\n    float _483 = _471.z;\n    float2 e = _471.xy / ((abs(_471.x) + abs(_471.y)) + abs(_483)).xx;\n    if (_483 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 176,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float _68_lift : packoffset(c0);\n    float _68_fa_pad0 : packoffset(c0.y);\n    float _68_fa_pad1 : packoffset(c0.z);\n    float _68_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _165_fa_view_proj : packoffset(c0);\n    row_major float4x4 _165_fa_light_vp : packoffset(c4);\n    float4 _165_fa_uv_scale : packoffset(c8);\n    float4 _165_fa_time : packoffset(c9);\n    float4 _165_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _212_fa_joint_rows[192] : packoffset(c0);\n};\n\nTexture2D<float4> fa_vs_height : register(t0);\nSamplerState fa_vs_height_smp : register(s6);\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _203 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_212_fa_joint_rows[_203] * weights[i]);\n        r1 += (_212_fa_joint_rows[_203 + 1] * weights[i]);\n        r2 += (_212_fa_joint_rows[_203 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _108 = cross(model[1].xyz, model[2].xyz);\n    float _113 = (dot(model[0].xyz, _108) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _446 = { mul(float4(position, 1.0f), model).xyz, (((_108 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _113, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _113), texcoord0 * _165_fa_uv_scale.xy, color, position };\n    return _446;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (fa_vs_height.SampleLevel(fa_vs_height_smp, v.uv, 0.0f).x * _68_lift);\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    float4 _317 = float4(param_6.world_pos, 1.0f);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -mul(_317, _165_fa_light_vp).z;\n    fa_pre_r0 = float3(_165_fa_light_vp[0].x, _165_fa_light_vp[1].x, _165_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_165_fa_light_vp[0].y, _165_fa_light_vp[1].y, _165_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_165_fa_light_vp[0].z, _165_fa_light_vp[1].z, _165_fa_light_vp[2].z);\n    gl_Position = mul(_317, _165_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _229_fa_camera_pos : packoffset(c0);\n    float4 _229_fa_ambient : packoffset(c1);\n    float4 _229_fa_base_color : packoffset(c2);\n    float4 _229_fa_emissive : packoffset(c3);\n    float4 _229_fa_model_emissive : packoffset(c4);\n    float4 _229_fa_pbr : packoffset(c5);\n    float4 _229_fa_maps : packoffset(c6);\n    float4 _229_fa_fog : packoffset(c7);\n    float4 _229_fa_fog_b : packoffset(c8);\n    float4 _229_fa_fog_c : packoffset(c9);\n    float4 _229_fa_counts : packoffset(c10);\n    float4 _229_fa_env_sky : packoffset(c11);\n    float4 _229_fa_env_horizon : packoffset(c12);\n    float4 _229_fa_time : packoffset(c13);\n};\n\nTexture2D<float4> height : register(t5);\nSamplerState height_smp : register(s2);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _196 = fa_linear_to_srgb(param);\n        c = _196;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _204 = fa_srgb_to_linear(param_1);\n            c = _204;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _229_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _240 = fa_tex_fix(param_2, param_3);\n    float4 _603 = base_t;\n    _603.x = _240.x;\n    _603.y = _240.y;\n    _603.z = _240.z;\n    base_t = _603;\n    float4 _256 = (_603 * _229_fa_base_color) * i.vertex_color;\n    float3 _584 = i.world_normal;\n    if (_229_fa_maps.z > 0.5f)\n    {\n        float param_4 = _229_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _289 = fa_tex_fix(param_6, param_7);\n        float3 _293 = (_289 * 2.0f) - 1.0f.xxx;\n        float2 _298 = _293.xy * _229_fa_maps.x;\n        float3 _611 = _293;\n        _611.x = _298.x;\n        _611.y = _298.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _611;\n        _584 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _229_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _327 = fa_tex_fix(param_12, param_13);\n    float4 _614 = mrt;\n    _614.x = _327.x;\n    _614.y = _327.y;\n    _614.z = _327.z;\n    mrt = _614;\n    float param_14 = _229_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = fa_occlusion_tex.Sample(fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _368 = fa_tex_fix(param_16, param_17);\n    float param_18 = _229_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _395 = fa_tex_fix(param_20, param_21);\n    Surface _596 = { _256.xyz, _256.w, _584, clamp(_229_fa_pbr.x * _327.z, 0.0f, 1.0f), clamp(_229_fa_pbr.y * _327.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_229_fa_maps.y * (_368.x - 1.0f)), _229_fa_emissive.xyz + (_229_fa_model_emissive.xyz * _395) };\n    return _596;\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= lerp(0.5f, 1.0f, height.Sample(height_smp, i.uv).x);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _531 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _531 = -_531;\n    }\n    float3 _441 = normalize(_229_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _544 = { fa_world_pos, _531, fa_world_tangent, fa_uv, fa_vertex_color, _441, gl_FrontFacing };\n    SurfaceInput param = _544;\n    SurfaceInput _552 = { fa_world_pos, _531, fa_world_tangent, fa_uv, fa_vertex_color, _441, gl_FrontFacing };\n    SurfaceInput param_1 = _552;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _456 = normalize(param_2.normal);\n    float3 _471 = normalize(float3(dot(fa_pre_r0, _456), dot(fa_pre_r1, _456), dot(fa_pre_r2, _456)));\n    float _483 = _471.z;\n    float2 e = _471.xy / ((abs(_471.x) + abs(_471.y)) + abs(_483)).xx;\n    if (_483 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 176,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float _54_lift : packoffset(c0);\n    float _54_fa_pad0 : packoffset(c0.y);\n    float _54_fa_pad1 : packoffset(c0.z);\n    float _54_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _151_fa_view_proj : packoffset(c0);\n    row_major float4x4 _151_fa_light_vp : packoffset(c4);\n    float4 _151_fa_uv_scale : packoffset(c8);\n    float4 _151_fa_time : packoffset(c9);\n    float4 _151_fa_lm_so : packoffset(c10);\n};\n\nTexture2D<float4> fa_vs_height : register(t0);\nSamplerState fa_vs_height_smp : register(s6);\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float3 fa_normal : TEXCOORD5;\n    float2 fa_texcoord0 : TEXCOORD6;\n    float4 fa_tangent : TEXCOORD7;\n    float4 fa_color : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _99 = (dot(model[0].xyz, _94) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _277 = { mul(float4(position, 1.0f), model).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _99, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _99), texcoord0 * _151_fa_uv_scale.xy, color, position };\n    return _277;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (fa_vs_height.SampleLevel(fa_vs_height_smp, v.uv, 0.0f).x * _54_lift);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mul(float4(param_6.world_pos, 1.0f), _151_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
            "size": 176,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_material_vs : register(b4)\n{\n    float _59_lift : packoffset(c0);\n    float _59_fa_pad0 : packoffset(c0.y);\n    float _59_fa_pad1 : packoffset(c0.z);\n    float _59_fa_pad2 : packoffset(c0.w);\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _156_fa_view_proj : packoffset(c0);\n    row_major float4x4 _156_fa_light_vp : packoffset(c4);\n    float4 _156_fa_uv_scale : packoffset(c8);\n    float4 _156_fa_time : packoffset(c9);\n    float4 _156_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _203_fa_joint_rows[192] : packoffset(c0);\n};\n\nTexture2D<float4> fa_vs_height : register(t0);\nSamplerState fa_vs_height_smp : register(s6);\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float4 fa_inst_m0 : TEXCOORD1;\n    float4 fa_inst_m1 : TEXCOORD2;\n    float4 fa_inst_m2 : TEXCOORD3;\n    float4 fa_inst_m3 : TEXCOORD4;\n    float4 fa_joints : TEXCOORD5;\n    float4 fa_weights : TEXCOORD6;\n    float3 fa_normal : TEXCOORD7;\n    float2 fa_texcoord0 : TEXCOORD8;\n    float4 fa_tangent : TEXCOORD9;\n    float4 fa_color : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 gl_Position : SV_Position;\n};\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _194 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_203_fa_joint_rows[_194] * weights[i]);\n        r1 += (_203_fa_joint_rows[_194 + 1] * weights[i]);\n        r2 += (_203_fa_joint_rows[_194 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _104 = (dot(model[0].xyz, _99) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _398 = { mul(float4(position, 1.0f), model).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _104, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _104), texcoord0 * _156_fa_uv_scale.xy, color, position };\n    return _398;\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (fa_vs_height.SampleLevel(fa_vs_height_smp, v.uv, 0.0f).x * _59_lift);\n}\n\nvoid vert_main()\n{\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    fa_inst_begin();\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mul(float4(param_8.world_pos, 1.0f), _156_fa_light_vp);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    return stage_output;\n}\n",
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
            "size": 176,
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
