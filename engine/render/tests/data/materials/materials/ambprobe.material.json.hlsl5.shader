{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5c7bc8cc90909f1ebab7aa9dd758cdced3d658fca63fc282b6949a210c4a3347",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _260 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _260;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_267, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _392_fa_camera_pos : packoffset(c0);\n    float4 _392_fa_ambient : packoffset(c1);\n    float4 _392_fa_base_color : packoffset(c2);\n    float4 _392_fa_emissive : packoffset(c3);\n    float4 _392_fa_model_emissive : packoffset(c4);\n    float4 _392_fa_pbr : packoffset(c5);\n    float4 _392_fa_maps : packoffset(c6);\n    float4 _392_fa_fog : packoffset(c7);\n    float4 _392_fa_fog_b : packoffset(c8);\n    float4 _392_fa_fog_c : packoffset(c9);\n    float4 _392_fa_counts : packoffset(c10);\n    float4 _392_fa_env_sky : packoffset(c11);\n    float4 _392_fa_env_horizon : packoffset(c12);\n    float4 _392_fa_time : packoffset(c13);\n    float4 _392_fa_cl_vpx : packoffset(c14);\n    float4 _392_fa_cl_vpy : packoffset(c15);\n    float4 _392_fa_cl_vpw : packoffset(c16);\n    float4 _392_fa_cl_fwd : packoffset(c17);\n    float4 _392_fa_cl_grid : packoffset(c18);\n    float4 _392_fa_cl_info : packoffset(c19);\n    float4 _392_fa_layers_a : packoffset(c20);\n    float4 _392_fa_layers_b : packoffset(c21);\n    float4 _392_fa_layers_c : packoffset(c22);\n    float4 _392_fa_layers_d : packoffset(c23);\n    float4 _392_fa_ct_a : packoffset(c24);\n    float4 _392_fa_ct_b : packoffset(c25);\n    float4 _392_fa_ct_vpx : packoffset(c26);\n    float4 _392_fa_ct_vpy : packoffset(c27);\n    float4 _392_fa_ct_vpw : packoffset(c28);\n    float4 _392_fa_ct_fwd : packoffset(c29);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2049_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2049_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2049_fa_shadow_info[4] : packoffset(c20);\n    float4 _2049_fa_shadow_split : packoffset(c24);\n    float4 _2049_fa_shadow_cfg : packoffset(c25);\n    float4 _2049_fa_shadow_bias : packoffset(c26);\n    float4 _2049_fa_shadow_eye : packoffset(c27);\n    float4 _2049_fa_shadow_fwd : packoffset(c28);\n    float4 _2049_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1320 = _392_fa_cl_info.x < 0.0f;\n    bool _1327;\n    if (!_1320)\n    {\n        _1327 = _392_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1327 = _1320;\n    }\n    bool _1335;\n    if (!_1327)\n    {\n        _1335 = _392_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1335 = _1327;\n    }\n    bool _1342;\n    if (!_1335)\n    {\n        _1342 = _392_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1342 = _1335;\n    }\n    bool _1349;\n    if (!_1342)\n    {\n        _1349 = _392_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1349 = _1342;\n    }\n    if (_1349)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1359 = float4(world_pos, 1.0f);\n    float _1365 = dot(_392_fa_cl_vpw, _1359);\n    if (!(_1365 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1387 = float2(dot(_392_fa_cl_vpx, _1359), dot(_392_fa_cl_vpy, _1359)) / _1365.xx;\n    int _1391 = int(_392_fa_cl_grid.x);\n    int _1395 = int(_392_fa_cl_grid.y);\n    int param = (int(_392_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_392_fa_cl_fwd.xyz, world_pos) + _392_fa_cl_fwd.w, _392_fa_cl_grid.w) / _392_fa_cl_grid.w) * _392_fa_cl_grid.z)), 0, int(_392_fa_cl_info.y) - 1) * _1395) + clamp(int(floor(((_1387.y * 0.5f) + 0.5f) * _392_fa_cl_grid.y)), 0, _1395 - 1)) * _1391)) + clamp(int(floor(((_1387.x * 0.5f) + 0.5f) * _392_fa_cl_grid.x)), 0, _1391 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1471 = fa_cluster_texel(param);\n    return int2(int(_1471.x), int(_1471.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_392_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3502 = fa_cluster_lookup(param);\n    fa_cl_slot = _3502.x;\n    fa_cl_local = _3502.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3705 = fa_linear_to_srgb(param);\n        c = _3705;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3713 = fa_srgb_to_linear(param_1);\n            c = _3713;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _275;\n    if (i.front_facing)\n    {\n        _275 = i.world_normal;\n    }\n    else\n    {\n        _275 = -i.world_normal;\n    }\n    float3 _299 = normalize(i.world_tangent.xyz - (_275 * dot(_275, i.world_tangent.xyz)));\n    float3 _326 = normalize(((_299 * m.x) + ((cross(_275, _299) * i.world_tangent.w) * m.y)) + (_275 * m.z));\n    float3 _329;\n    if (i.front_facing)\n    {\n        _329 = _326;\n    }\n    else\n    {\n        _329 = -_326;\n    }\n    return _329;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _392_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3744 = fa_tex_fix(param_2, param_3);\n    float4 _4803 = base_t;\n    _4803.x = _3744.x;\n    _4803.y = _3744.y;\n    _4803.z = _3744.z;\n    base_t = _4803;\n    float4 _3758 = (_4803 * _392_fa_base_color) * i.vertex_color;\n    float3 _4655 = i.world_normal;\n    if (_392_fa_maps.z > 0.5f)\n    {\n        float param_4 = _392_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3790 = fa_tex_fix(param_6, param_7);\n        float3 _3793 = (_3790 * 2.0f) - 1.0f.xxx;\n        float2 _3798 = _3793.xy * _392_fa_maps.x;\n        float3 _4811 = _3793;\n        _4811.x = _3798.x;\n        _4811.y = _3798.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4811;\n        _4655 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _392_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3826 = fa_tex_fix(param_12, param_13);\n    float4 _4814 = mrt;\n    _4814.x = _3826.x;\n    _4814.y = _3826.y;\n    _4814.z = _3826.z;\n    mrt = _4814;\n    float4 _3854 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _392_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3854.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3865 = fa_tex_fix(param_16, param_17);\n    float param_18 = _392_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3895 = fa_tex_fix(param_20, param_21);\n    float _4660 = _392_fa_layers_a.x;\n    float _4661 = _392_fa_layers_a.y;\n    float _4664 = _392_fa_layers_a.z;\n    float _4663 = _392_fa_layers_b.w;\n    float _4666 = _392_fa_layers_c.x;\n    if (_392_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_392_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4660 *= _3865.y;\n            _4661 *= _3865.z;\n            _4663 *= _3854.w;\n        }\n        if (_392_fa_layers_c.z > 1.5f)\n        {\n            _4664 *= mrt.x;\n            _4666 *= mrt.w;\n        }\n    }\n    Surface _4685 = { _3758.xyz, _3758.w, _4655, clamp(_392_fa_pbr.x * _3826.z, 0.0f, 1.0f), clamp(_392_fa_pbr.y * _3826.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_392_fa_maps.y * (_3865.x - 1.0f)), _392_fa_emissive.xyz + (_392_fa_model_emissive.xyz * _3895), _4660, _4661, _392_fa_layers_b.xyz, _4663, _4664, _392_fa_layers_a.w, _4666, _392_fa_layers_c.y, _392_fa_layers_d.xyz };\n    return _4685;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1551 = rect.zw - rect.xy;\n    float2 _1555 = _1551 * atlas;\n    float2 _1559 = ddx * _1555;\n    float2 _1563 = ddy * _1555;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1551), clamp(0.5f * log2(max(max(dot(_1559, _1559), dot(_1563, _1563)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1596 = _392_fa_counts.y < 0.5f;\n    bool _1603;\n    if (!_1596)\n    {\n        _1603 = _392_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1603 = _1596;\n    }\n    if (_1603)\n    {\n        return;\n    }\n    float3 _1609 = ddx(world_pos);\n    float3 _1612 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1616 = fa_cluster_texel(param);\n    int _1620 = int(_1616.w);\n    if (_1620 < 1)\n    {\n        return;\n    }\n    int _1630 = int(_392_fa_counts.y + 0.5f);\n    int param_1 = _1630;\n    float4 _1634 = fa_light_texel(param_1);\n    float2 _1637 = _1634.yz;\n    int _1641 = int(_1634.w);\n    int param_2 = _1630 + 1;\n    float4 _1646 = fa_light_texel(param_2);\n    float _1647 = _1646.x;\n    int _1653 = int(_392_fa_counts.w + 0.5f) - 1;\n    int _1657 = int(_1616.z);\n    float3 _1922;\n    for (int k = 0; k < _1620; k++)\n    {\n        int _1670 = _1657 + k;\n        int param_3 = _1641 + (_1670 >> 2);\n        int _1687 = (_1630 + 2) + (int(fa_light_texel(param_3)[_1670 & 3]) * 7);\n        int param_4 = _1687 + 6;\n        float4 _1692 = fa_light_texel(param_4);\n        if (((int(_1692.w + 0.5f) >> _1653) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1687;\n        float4 _1707 = fa_light_texel(param_5);\n        int param_6 = _1687 + 1;\n        float4 _1712 = fa_light_texel(param_6);\n        int param_7 = _1687 + 2;\n        float4 _1717 = fa_light_texel(param_7);\n        float3 _1720 = _1707.xyz;\n        float _1725 = dot(_1720, world_pos) + _1707.w;\n        float3 _1727 = _1712.xyz;\n        float _1732 = dot(_1727, world_pos) + _1712.w;\n        float3 _1734 = _1717.xyz;\n        float _1739 = dot(_1734, world_pos) + _1717.w;\n        bool _1744 = abs(_1725) > 0.5f;\n        bool _1752;\n        if (!_1744)\n        {\n            _1752 = abs(_1732) > 0.5f;\n        }\n        else\n        {\n            _1752 = _1744;\n        }\n        bool _1760;\n        if (!_1752)\n        {\n            _1760 = abs(_1739) > 0.5f;\n        }\n        else\n        {\n            _1760 = _1752;\n        }\n        if (_1760)\n        {\n            continue;\n        }\n        float _1775 = clamp(dot(geo_normal, normalize(_1734)) * _1692.z, 0.0f, 1.0f);\n        if (_1775 <= 0.0f)\n        {\n            continue;\n        }\n        float _1795 = (clamp((0.5f - abs(_1739)) * 10.0f, 0.0f, 1.0f) * _1775) * _1692.x;\n        float2 _1803 = float2(_1725 + 0.5f, 0.5f - _1732);\n        float2 _1813 = float2(dot(_1720, _1609), dot(_1727, _1609));\n        float2 _1823 = float2(dot(_1720, _1612), dot(_1727, _1612));\n        int param_8 = _1687 + 5;\n        float4 _1828 = fa_light_texel(param_8);\n        int param_9 = _1687 + 3;\n        float4 _1833 = fa_light_texel(param_9);\n        int param_10 = _1687 + 4;\n        float4 _1838 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1828.xyz;\n        bool _1848 = _1833.z > _1833.x;\n        if (_1848)\n        {\n            float4 param_11 = _1833;\n            float2 param_12 = _1803;\n            float2 param_13 = _1637;\n            float2 param_14 = _1813;\n            float2 param_15 = _1823;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1647 > 0.5f) && (_1647 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1874 = fa_dc_to_linear(param_16);\n                float4 _4735 = tx;\n                _4735.x = _1874.x;\n                _4735.y = _1874.y;\n                _4735.z = _1874.z;\n                tx = _4735;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1795 * tex_a) * _1828.w, 0.0f, 1.0f).xxx);\n        if (_1838.z > _1838.x)\n        {\n            float4 param_17 = _1838;\n            float2 param_18 = _1803;\n            float2 param_19 = _1637;\n            float2 param_20 = _1813;\n            float2 param_21 = _1823;\n            float4 _1918 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1647 > 1.5f)\n            {\n                float3 param_22 = _1918.xyz;\n                float3 _1928 = fa_dc_to_srgb(param_22);\n                _1922 = _1928;\n            }\n            else\n            {\n                _1922 = _1918.xyz;\n            }\n            float3 _1937 = (_1922 * 2.0f) - 1.0f.xxx;\n            float2 _1942 = _1937.xy * _1692.y;\n            float3 _1964 = (normalize(_1720) * _1942.x) + (normalize(_1727) * _1942.y);\n            float3 _1967 = normalize(normal);\n            normal = normalize(lerp(_1967, normalize((_1967 * max(_1937.z, 0.0500000007450580596923828125f)) + (_1964 - (_1967 * dot(_1967, _1964)))), clamp(_1795 * (_1848 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_392_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3162 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3162;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_392_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _392_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return ambientColor;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_392_fa_cl_info.x) + int(_392_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_392_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _451_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _451_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _570 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _583 = (c - (ru * hx)) - p;\n        float3 _589 = ru * (2.0f * hx);\n        float _595 = max(dot(_589, _589), 9.9999999392252902907785028219223e-09f);\n        float _599 = dot(_583, _589);\n        float t = clamp((-_599) / _595, 0.0f, 1.0f);\n        if (_570)\n        {\n            float _614 = dot(r, _589);\n            float _620 = _595 - (_614 * _614);\n            if (abs(_620) > (9.9999997473787516355514526367188e-06f * _595))\n            {\n                t = clamp(((dot(r, _583) * _614) - _599) / _620, 0.0f, 1.0f);\n            }\n        }\n        return (p + _583) + (_589 * t);\n    }\n    float3 q = p;\n    float _652 = dot(r, axis);\n    bool _660;\n    if (_570)\n    {\n        _660 = abs(_652) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _660 = _570;\n    }\n    if (_660)\n    {\n        float _670 = dot(c - p, axis) / _652;\n        if (_670 > 0.0f)\n        {\n            q = p + (r * _670);\n        }\n    }\n    float3 _683 = q - c;\n    float2 xy = float2(dot(_683, ru), dot(_683, uu));\n    if (shape > 0.5f)\n    {\n        float _698 = length(xy);\n        if (_698 > hx)\n        {\n            xy *= (hx / _698);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _341 = abs(d);\n    float _343 = _341.x;\n    float _345 = _341.y;\n    bool _346 = _343 >= _345;\n    bool _354;\n    if (_346)\n    {\n        _354 = _343 >= _341.z;\n    }\n    else\n    {\n        _354 = _346;\n    }\n    int _355;\n    if (_354)\n    {\n        _355 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _370;\n        if (_345 >= _341.z)\n        {\n            _370 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _370 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _355 = _370;\n    }\n    return _355;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _490 = dot(d, right);\n    float _494 = dot(d, up);\n    float _505;\n    if (((_490 * _490) + (_494 * _494)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _505 = atan2(_494, _490) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _505 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_505 - floor(_505)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _736 = fa_light_base(param);\n    bool _740 = _392_fa_ambient.w > 4.5f;\n    int param_1 = _736;\n    float4 _744 = fa_light_texel(param_1);\n    int param_2 = _736 + 1;\n    float4 _749 = fa_light_texel(param_2);\n    float _752 = _749.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _764 = _740 && (_752 > 2.5f);\n    fa_light_is_area = _764;\n    bool _766 = _752 < 0.5f;\n    float3 l;\n    if (_766)\n    {\n        l = normalize(_744.xyz);\n        if (_740)\n        {\n            int param_3 = _736 + 6;\n            float4 _780 = fa_light_texel(param_3);\n            if (_780.z > 0.5f)\n            {\n                int param_4 = _736 + 4;\n                float4 _790 = fa_light_texel(param_4);\n                int param_5 = _736 + 5;\n                float4 _795 = fa_light_texel(param_5);\n                float2 param_6 = _780.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _790.xyz) * _790.w, (-dot(world_pos, _795.xyz)) * _795.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _825 = _744.xyz;\n        float3 _827 = _825 - world_pos;\n        float3 to_light = _827;\n        float _830 = length(_827);\n        float reach = _830;\n        bool front = true;\n        if (_764)\n        {\n            int param_8 = _736 + 7;\n            reach = max(_830 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _736 + 4;\n            float4 _854 = fa_light_texel(param_9);\n            int param_10 = _736 + 5;\n            float4 _859 = fa_light_texel(param_10);\n            int param_11 = _736 + 6;\n            float4 _864 = fa_light_texel(param_11);\n            float _865 = _864.w;\n            int param_12 = _736 + 2;\n            float3 _872 = normalize(fa_light_texel(param_12).xyz);\n            bool _874 = _865 > 1.5f;\n            bool _882;\n            if (!_874)\n            {\n                _882 = dot(_872, to_light) < 0.0f;\n            }\n            else\n            {\n                _882 = _874;\n            }\n            front = _882;\n            float3 r = 0.0f.xxx;\n            float3 _891 = _392_fa_camera_pos.xyz - world_pos;\n            bool _895 = dot(n, n) > 0.5f;\n            bool _903;\n            if (_895)\n            {\n                _903 = dot(_891, _891) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _903 = _895;\n            }\n            if (_903)\n            {\n                r = reflect(-normalize(_891), normalize(n));\n            }\n            float3 param_13 = _825;\n            float3 param_14 = _872;\n            float3 param_15 = _854.xyz;\n            float3 param_16 = _859.xyz;\n            float param_17 = _854.w;\n            float param_18 = _859.w;\n            float param_19 = _865;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _939 = length(to_light);\n        dist = _939;\n        l = to_light / max(_939, 9.9999997473787516355514526367188e-05f).xxx;\n        float _953 = reach / max(_744.w, 0.001000000047497451305389404296875f);\n        float _959 = clamp(1.0f - (_953 * _953), 0.0f, 1.0f);\n        float _961;\n        if (front)\n        {\n            _961 = _959 * _959;\n        }\n        else\n        {\n            _961 = 0.0f;\n        }\n        atten = _961;\n        bool _972 = _752 < 2.5f;\n        if ((_752 > 1.5f) && _972)\n        {\n            int param_22 = _736 + 2;\n            float4 _980 = fa_light_texel(param_22);\n            float _990 = _980.w;\n            int param_23 = _736 + 3;\n            float4 _995 = fa_light_texel(param_23);\n            float _996 = _995.x;\n            float cos_inner = _996;\n            if (_996 > 1.5f)\n            {\n                cos_inner = lerp(_990, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_990, cos_inner, dot(-l, normalize(_980.xyz)));\n        }\n        if (_740 && (_752 < 1.5f))\n        {\n            int param_24 = _736 + 6;\n            float4 _1020 = fa_light_texel(param_24);\n            if (_1020.z > 0.5f)\n            {\n                float3 _1028 = -to_light;\n                int param_25 = _736 + 4;\n                int param_26 = _736 + 5;\n                float3 _1042 = fa_light_texel(param_25).xyz;\n                float3 _1046 = fa_light_texel(param_26).xyz;\n                float3 _1055 = float3(dot(_1028, _1042), dot(_1028, _1046), dot(_1028, cross(_1042, _1046)));\n                float3 param_27 = _1055;\n                int _1059 = fa_cube_face(param_27);\n                int param_28 = _1059;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1086 = float2(dot(_1055, cross(param_29, param_30)), dot(_1055, param_30)) / max(dot(_1055, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1090 = _1059 / 3;\n                float2 param_31 = _1020.xy + (float2(float(_1059 - (_1090 * 3)), float(_1090)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1086.x), 0.5f - (0.5f * _1086.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _736 + 7;\n            float4 _1120 = fa_light_texel(param_33);\n            if (_1120.z > 0.5f)\n            {\n                int param_34 = _736 + 2;\n                int param_35 = _736 + 4;\n                int param_36 = _736 + 5;\n                float2 param_37 = _1120.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_740 && _972)\n            {\n                int param_42 = _736 + 6;\n                float4 _1167 = fa_light_texel(param_42);\n                int param_43 = _736 + 7;\n                float4 _1172 = fa_light_texel(param_43);\n                bool _1175 = _1167.z > 0.5f;\n                bool _1182;\n                if (!_1175)\n                {\n                    _1182 = _1172.z > 0.5f;\n                }\n                else\n                {\n                    _1182 = _1175;\n                }\n                if (_1182)\n                {\n                    int param_44 = _736 + 2;\n                    float4 _1189 = fa_light_texel(param_44);\n                    float3 _1193 = normalize(_1189.xyz);\n                    int param_45 = _736 + 4;\n                    float4 _1198 = fa_light_texel(param_45);\n                    int param_46 = _736 + 5;\n                    float4 _1203 = fa_light_texel(param_46);\n                    if (_1175)\n                    {\n                        float3 _1211 = -to_light;\n                        float _1218 = _1189.w;\n                        float _1234 = 0.5f / max(dot(_1211, _1193) * (sqrt(max(1.0f - (_1218 * _1218), 0.0f)) / max(_1218, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1167.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1211, _1198.xyz) * _1234), 0.5f - (dot(_1211, _1203.xyz) * _1234));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1172.z > 0.5f)\n                    {\n                        float2 param_49 = _1172.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1193;\n                        float3 param_52 = _1198.xyz;\n                        float3 param_53 = _1203.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4609 = _749.xyz * atten;\n    if (_740)\n    {\n        _4609 *= fa_light_tint;\n    }\n    int _1302;\n    if (_766)\n    {\n        _1302 = 0;\n    }\n    else\n    {\n        _1302 = ((_752 > 1.5f) && (_752 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4620 = { l, _4609, atten, 1.0f, dist, _1302 };\n    return _4620;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2039;\n    if (i == 0)\n    {\n        _2039 = _2049_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2055;\n        if (i == 1)\n        {\n            _2055 = _2049_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2063;\n            if (i == 2)\n            {\n                _2063 = _2049_fa_shadow_split.z;\n            }\n            else\n            {\n                _2063 = _2049_fa_shadow_split.w;\n            }\n            _2055 = _2063;\n        }\n        _2039 = _2055;\n    }\n    return _2039;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2096 = fa_shadow_depth(param, param_1);\n    float _2100;\n    if (conv.x < 0.5f)\n    {\n        _2100 = _2096;\n    }\n    else\n    {\n        _2100 = (conv.y * conv.z) / (conv.z - (_2096 * (conv.z - conv.y)));\n    }\n    return _2100;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2027 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2027), sin(_2027)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2146 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2155;\n        if (k < 0.0f)\n        {\n            _2155 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2155 = k;\n        }\n        float _2175 = clamp((_2155 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2146;\n            float2 _2194 = fa_shadow_vogel(param_3, param_4, param_5) * _2175;\n            float2 param_6 = uv + (_2194 * _2049_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2206 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2206 < (zr - (length(_2194) * plane)))\n            {\n                sum += _2206;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2232 = sum / cnt;\n        float _2242;\n        if (k < 0.0f)\n        {\n            _2242 = (-k) / max(_2232, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2242 = k;\n        }\n        radius = clamp(((max(zr - _2232, 0.0f) * unit) * _2242) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2264 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2264; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2264;\n        float param_11 = _2146;\n        float2 _2283 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2283 * _2049_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2283) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2264);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2325 = max(_2049_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2330 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2336 = sqrt(1.0f - (_2330 * _2330));\n    float _2343 = min(_2336 / max(_2330, 0.20000000298023223876953125f), 4.0f);\n    float _2348;\n    if (_2049_fa_shadow_bias.y > 0.0f)\n    {\n        _2348 = _2049_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2348 = 1.5f * _2049_fa_shadow_info[ci].x;\n    }\n    float4 _2373 = mul(float4(world + (n * (_2348 * _2336)), 1.0f), _2049_fa_shadow_mat[ci]);\n    float _2380 = _2373.x;\n    bool _2383 = _2380 < _2049_fa_shadow_rect[ci].x;\n    bool _2392;\n    if (!_2383)\n    {\n        _2392 = _2380 > _2049_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2392 = _2383;\n    }\n    bool _2401;\n    if (!_2392)\n    {\n        _2401 = _2373.y < _2049_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2401 = _2392;\n    }\n    bool _2410;\n    if (!_2401)\n    {\n        _2410 = _2373.y > _2049_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2410 = _2401;\n    }\n    bool _2417;\n    if (!_2410)\n    {\n        _2417 = _2373.z > 1.0f;\n    }\n    else\n    {\n        _2417 = _2410;\n    }\n    if (_2417)\n    {\n        return -1.0f;\n    }\n    float _2425;\n    if (_2049_fa_shadow_bias.x > 0.0f)\n    {\n        _2425 = _2049_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2425 = 1.5f * _2049_fa_shadow_info[ci].x;\n    }\n    float2 param = _2373.xy;\n    float4 param_1 = _2049_fa_shadow_rect[ci];\n    float param_2 = _2373.z - ((_2425 * (1.0f + (0.5f * _2343))) / _2325);\n    float param_3 = _2049_fa_shadow_info[ci].x;\n    float param_4 = _2325;\n    float param_5 = _2325 * 0.25f;\n    float param_6 = ((_2049_fa_shadow_info[ci].x * min(_2343, 3.0f)) * 0.5f) / _2325;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2049_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2049_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_392_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2803 = int(_2049_fa_shadow_cfg.x + 0.5f);\n    if (_2803 < 1)\n    {\n        return 1.0f;\n    }\n    float _2818 = dot(world - _2049_fa_shadow_eye.xyz, _2049_fa_shadow_fwd.xyz);\n    int param = _2803 - 1;\n    if (_2818 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2830 = _2803 > 1;\n    bool _2837;\n    if (_2830)\n    {\n        _2837 = _2818 > _2049_fa_shadow_split.x;\n    }\n    else\n    {\n        _2837 = _2830;\n    }\n    if (_2837)\n    {\n        ci = 1;\n    }\n    bool _2841 = _2803 > 2;\n    bool _2848;\n    if (_2841)\n    {\n        _2848 = _2818 > _2049_fa_shadow_split.y;\n    }\n    else\n    {\n        _2848 = _2841;\n    }\n    if (_2848)\n    {\n        ci = 2;\n    }\n    bool _2852 = _2803 > 3;\n    bool _2859;\n    if (_2852)\n    {\n        _2859 = _2818 > _2049_fa_shadow_split.z;\n    }\n    else\n    {\n        _2859 = _2852;\n    }\n    if (_2859)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2803)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2885 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2885;\n        if (_2885 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2049_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2910;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2910 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2910 = _2049_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2929 = _2049_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2910, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2940 = clamp((_2818 - (fa_shadow_split_at(param_7) - _2929)) / _2929, 0.0f, 1.0f);\n        if (_2940 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2803)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2961 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2961;\n                if (_2961 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2940);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2483 = _392_fa_pbr.z < 0.5f;\n    bool _2490;\n    if (!_2483)\n    {\n        _2490 = _2049_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2490 = _2483;\n    }\n    if (_2490)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2049_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2503 = fa_light_texel(param);\n    float _2504 = _2503.x;\n    if (_2504 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2513 = int(_2504 + 0.5f);\n    int param_1 = _2513;\n    float4 _2517 = fa_light_texel(param_1);\n    int param_2 = _2513 + 1;\n    float4 _2522 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2525 = _2517.y;\n    if (_2525 > 0.0f)\n    {\n        float _2542 = 1.0f - smoothstep(0.75f * _2525, _2525, length(world - _2049_fa_shadow_eye.xyz));\n        fade = _2542;\n        if (_2542 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2517.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2566 = (_2513 + 2) + (face * 6);\n    int param_4 = _2566;\n    int param_5 = _2566 + 1;\n    int param_6 = _2566 + 3;\n    float4 _2580 = fa_light_texel(param_6);\n    int param_7 = _2566 + 4;\n    float4 _2585 = fa_light_texel(param_7);\n    int param_8 = _2566 + 5;\n    float4 _2590 = fa_light_texel(param_8);\n    float _2602 = _2590.x * max(dot(_2580, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2607 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2630 = clamp(dot(n, _2580.xyz), -1.0f, 1.0f);\n    float _2649 = min(sqrt(1.0f - (_2630 * _2630)) / max(abs(dot(n, world - lpos)) / max(dot(_2580, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2652 = _2522.y;\n    float _2654;\n    if (_2652 > 0.0f)\n    {\n        _2654 = _2652;\n    }\n    else\n    {\n        _2654 = 1.5f * _2602;\n    }\n    float4 _2674 = float4(world + (n * (_2654 * sqrt(1.0f - (_2607 * _2607)))), 1.0f);\n    float _2678 = dot(_2580, _2674);\n    float _2681 = _2590.y;\n    if (_2678 < _2681)\n    {\n        return 1.0f;\n    }\n    float2 _2696 = float2(dot(fa_light_texel(param_4), _2674), dot(fa_light_texel(param_5), _2674)) / _2678.xx;\n    float _2698 = _2696.x;\n    bool _2701 = _2698 < _2585.x;\n    bool _2710;\n    if (!_2701)\n    {\n        _2710 = _2698 > _2585.z;\n    }\n    else\n    {\n        _2710 = _2701;\n    }\n    bool _2719;\n    if (!_2710)\n    {\n        _2719 = _2696.y < _2585.y;\n    }\n    else\n    {\n        _2719 = _2710;\n    }\n    bool _2728;\n    if (!_2719)\n    {\n        _2728 = _2696.y > _2585.w;\n    }\n    else\n    {\n        _2728 = _2719;\n    }\n    if (_2728)\n    {\n        return 1.0f;\n    }\n    float _2734 = _2522.x;\n    float _2736;\n    if (_2734 > 0.0f)\n    {\n        _2736 = _2734;\n    }\n    else\n    {\n        _2736 = 1.5f * _2602;\n    }\n    float2 param_9 = _2696;\n    float4 param_10 = _2585;\n    float param_11 = _2678 - (_2736 * (1.0f + (0.5f * _2649)));\n    float param_12 = _2602;\n    float param_13 = 1.0f;\n    float param_14 = _2590.z * 0.25f;\n    float param_15 = (_2602 * min(_2649, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2681, _2590.z);\n    int param_17 = int(_2517.z + 0.5f);\n    float param_18 = _2517.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3242 = _392_fa_ct_a.x < 0.5f;\n    bool _3249;\n    if (!_3242)\n    {\n        _3249 = _2049_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3249 = _3242;\n    }\n    if (_3249)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2049_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3262 = fa_light_texel(param);\n    float _3263 = _3262.y;\n    float len = _3263;\n    if (_3263 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3275 = length(world - _392_fa_camera_pos.xyz);\n    float _3285 = 1.0f - smoothstep(0.5f * _392_fa_ct_b.x, _392_fa_ct_b.x, _3275);\n    if (_3285 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3291 = len;\n    float _3294 = min(_3291, 0.89999997615814208984375f * dist);\n    len = _3294;\n    float _3300 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3275);\n    float _3305 = _3300 + (0.5f * _3294);\n    float3 _3311 = world + (gn * _3300);\n    float _3313 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _3378;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3329 = (float(k) + _3313) * 0.083333335816860198974609375f;\n        float3 _3337 = _3311 + (l * (_3329 * len));\n        float4 _3343 = float4(_3337, 1.0f);\n        float _3349 = dot(_392_fa_ct_vpw, _3343);\n        if (_3349 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _3369 = float2(dot(_392_fa_ct_vpx, _3343), dot(_392_fa_ct_vpy, _3343)) / _3349.xx;\n        float _3373 = _3369.x * 0.5f;\n        float _3374 = _3373 + 0.5f;\n        if (_392_fa_ct_a.y > 0.5f)\n        {\n            _3378 = (_3369.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _3378 = 0.5f - (_3369.y * 0.5f);\n        }\n        bool _3394 = _3374 < 0.0f;\n        bool _3401;\n        if (!_3394)\n        {\n            _3401 = _3374 >= 1.0f;\n        }\n        else\n        {\n            _3401 = _3394;\n        }\n        bool _3408;\n        if (!_3401)\n        {\n            _3408 = _3378 < 0.0f;\n        }\n        else\n        {\n            _3408 = _3401;\n        }\n        bool _3415;\n        if (!_3408)\n        {\n            _3415 = _3378 >= 1.0f;\n        }\n        else\n        {\n            _3415 = _3408;\n        }\n        if (_3415)\n        {\n            break;\n        }\n        float4 _3434 = fa_screen_tex.Load(int3(int2(float2(_3374, _3378) * _392_fa_ct_a.zw), 0));\n        if (_3434.w < 0.5f)\n        {\n            continue;\n        }\n        float _3453 = (dot(_392_fa_ct_fwd.xyz, _3337) + _392_fa_ct_fwd.w) - _3434.x;\n        if ((_3453 > _3300) && (_3453 < _3305))\n        {\n            occ = max(occ, (1.0f - (_3329 * _3329)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_3374, 0.5f - _3373), min(_3378, 1.0f - _3378))));\n        }\n    }\n    return 1.0f - (occ * _3285);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3529 = fa_lm.z > 0.5f;\n    bool _3535;\n    if (_3529)\n    {\n        int param = li;\n        _3535 = fa_light_baked(param);\n    }\n    else\n    {\n        _3535 = _3529;\n    }\n    if (_3535)\n    {\n        int param_1 = li;\n        LightSample _4633 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4633;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3559 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _4635 = _3559.color;\n    float _4637 = _3559.shadow;\n    bool _3562 = _3559.type == 0;\n    if (_3562 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3559.direction;\n        float _3573 = fa_shadow_factor(param_5, param_6);\n        _4637 = _3573;\n        _4635 *= _3573;\n    }\n    else\n    {\n        bool _3584 = _3559.type != 0;\n        bool _3590;\n        if (_3584)\n        {\n            _3590 = _3559.attenuation > 0.0f;\n        }\n        else\n        {\n            _3590 = _3584;\n        }\n        if (_3590)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3559.direction;\n            float _3609 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4637 = _3609;\n            _4635 *= _3609;\n        }\n    }\n    bool _3619 = _392_fa_ct_a.x > 0.5f;\n    bool _3625;\n    if (_3619)\n    {\n        _3625 = _3559.attenuation > 0.0f;\n    }\n    else\n    {\n        _3625 = _3619;\n    }\n    if (_3625)\n    {\n        float _3632;\n        if (_3562)\n        {\n            _3632 = 1000000000.0f;\n        }\n        else\n        {\n            _3632 = _3559._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3559.direction;\n        float param_18 = _3632;\n        float _3650 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _4637 *= _3650;\n        _4635 *= _3650;\n    }\n    LightSample _4652 = { _3559.direction, _4635, _3559.attenuation, _4637, _3559._distance, _3559.type };\n    return _4652;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2049_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2985 = int(_2049_fa_shadow_cfg.x + 0.5f);\n    float _2995 = dot(world - _2049_fa_shadow_eye.xyz, _2049_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3000 = _2985 > 0;\n    bool _3009;\n    if (_3000)\n    {\n        int param = _2985 - 1;\n        _3009 = _2995 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3009 = _3000;\n    }\n    if (_3009)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3015 = _2985 > 1;\n        bool _3022;\n        if (_3015)\n        {\n            _3022 = _2995 > _2049_fa_shadow_split.x;\n        }\n        else\n        {\n            _3022 = _3015;\n        }\n        if (_3022)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3028 = _2985 > 2;\n        bool _3035;\n        if (_3028)\n        {\n            _3035 = _2995 > _2049_fa_shadow_split.y;\n        }\n        else\n        {\n            _3035 = _3028;\n        }\n        if (_3035)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3041 = _2985 > 3;\n        bool _3048;\n        if (_3041)\n        {\n            _3048 = _2995 > _2049_fa_shadow_split.z;\n        }\n        else\n        {\n            _3048 = _3041;\n        }\n        if (_3048)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4451 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4451 = -_4451;\n    }\n    float3 _4037 = normalize(_392_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4464 = { fa_world_pos, _4451, fa_world_tangent, fa_uv, fa_vertex_color, _4037, gl_FrontFacing };\n    SurfaceInput param_1 = _4464;\n    Surface _4045 = fa_standard_surface(param_1);\n    float3 _4490 = _4045.albedo;\n    float _4491 = _4045.alpha;\n    float3 _4492 = _4045.normal;\n    float _4493 = _4045.metallic;\n    float _4494 = _4045.roughness;\n    float _4495 = _4045.occlusion;\n    float3 _4496 = _4045.emission;\n    float _4497 = _4045.clearcoat;\n    float _4498 = _4045.clearcoat_roughness;\n    float3 _4499 = _4045.sheen_color;\n    float _4500 = _4045.sheen_roughness;\n    float _4501 = _4045.anisotropy;\n    float _4502 = _4045.anisotropy_rotation;\n    float _4503 = _4045.specular;\n    float _4504 = _4045.ior;\n    float3 _4505 = _4045.specular_color;\n    SurfaceInput _4472 = { fa_world_pos, _4451, fa_world_tangent, fa_uv, fa_vertex_color, _4037, gl_FrontFacing };\n    SurfaceInput param_2 = _4472;\n    Surface param_3 = _4045;\n    surface(param_2, param_3);\n    _4490 = param_3.albedo;\n    _4491 = param_3.alpha;\n    _4492 = param_3.normal;\n    _4493 = param_3.metallic;\n    _4494 = param_3.roughness;\n    _4495 = param_3.occlusion;\n    _4496 = param_3.emission;\n    _4497 = param_3.clearcoat;\n    _4498 = param_3.clearcoat_roughness;\n    _4499 = param_3.sheen_color;\n    _4500 = param_3.sheen_roughness;\n    _4501 = param_3.anisotropy;\n    _4502 = param_3.anisotropy_rotation;\n    _4503 = param_3.specular;\n    _4504 = param_3.ior;\n    _4505 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4451;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4490 = param_6;\n    _4492 = param_7;\n    float3 result;\n    if (_392_fa_emissive.w > 0.5f)\n    {\n        result = _4490;\n    }\n    else\n    {\n        float3 _4083 = _4492;\n        float3 _4084 = normalize(_4083);\n        _4492 = _4084;\n        float3 param_8 = _4084;\n        SurfaceInput _4480 = { fa_world_pos, _4451, fa_world_tangent, fa_uv, fa_vertex_color, _4037, gl_FrontFacing };\n        SurfaceInput param_9 = _4480;\n        Surface _4571 = { _4490, _4491, _4492, _4493, _4494, _4495, _4496, _4497, _4498, _4499, _4500, _4501, _4502, _4503, _4504, _4505 };\n        Surface param_10 = _4571;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _4103 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4103; ln++)\n        {\n            int param_12 = ln;\n            int _4116 = fa_cl_light(param_12);\n            bool _4119 = fa_lm.z > 0.5f;\n            bool _4125;\n            if (_4119)\n            {\n                int param_13 = _4116;\n                _4125 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _4125 = _4119;\n            }\n            if (_4125)\n            {\n                continue;\n            }\n            int param_14 = _4116;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _4451;\n            LightSample _4137 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _4488 = { fa_world_pos, _4451, fa_world_tangent, fa_uv, fa_vertex_color, _4037, gl_FrontFacing };\n            SurfaceInput param_17 = _4488;\n            Surface _4588 = { _4490, _4491, _4492, _4493, _4494, _4495, _4496, _4497, _4498, _4499, _4500, _4501, _4502, _4503, _4504, _4505 };\n            Surface param_18 = _4588;\n            LightSample param_19 = _4137;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _4152 = result;\n    float3 _4153 = _4152 + _4496;\n    result = _4153;\n    float3 param_20 = _4153;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _4162 = _392_fa_fog.w > 0.0f;\n    bool _4169;\n    if (!_4162)\n    {\n        _4169 = _392_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4169 = _4162;\n    }\n    if (_4169)\n    {\n        float3 _4178 = fa_world_pos - _392_fa_camera_pos.xyz;\n        float _4184 = dot(_4178, _392_fa_fog_c.xyz);\n        bool _4188 = _392_fa_fog_c.w > 0.5f;\n        float _4189;\n        if (_4188)\n        {\n            _4189 = _4184;\n        }\n        else\n        {\n            _4189 = length(_4178);\n        }\n        float _4201 = _4189 - _392_fa_fog_b.x;\n        if (_4201 > 0.0f)\n        {\n            float _4210 = _392_fa_fog.w * _4201;\n            float tau = _4210 * _4210;\n            if (_392_fa_fog_b.y > 0.0f)\n            {\n                float _4226;\n                if (_4188)\n                {\n                    _4226 = fa_world_pos.y - (_392_fa_fog_c.y * _4184);\n                }\n                else\n                {\n                    _4226 = _392_fa_camera_pos.y;\n                }\n                float _4247 = lerp(_4226, fa_world_pos.y, clamp(_392_fa_fog_b.x / _4189, 0.0f, 1.0f));\n                float _4251 = fa_world_pos.y - _4247;\n                float _4256 = _4247 - _392_fa_fog_b.z;\n                float _4261 = fa_world_pos.y - _392_fa_fog_b.z;\n                bool _4264 = _4256 <= 0.0f;\n                bool _4265 = !_4264;\n                bool _4271;\n                if (_4265)\n                {\n                    _4271 = _392_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4271 = _4264;\n                }\n                float _4272;\n                if (_4271)\n                {\n                    _4272 = _392_fa_fog_b.y;\n                }\n                else\n                {\n                    _4272 = _392_fa_fog_b.y * exp(-min(_392_fa_fog_b.w * _4256, 80.0f));\n                }\n                bool _4299;\n                if (_4265)\n                {\n                    _4299 = _392_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4299 = _4264;\n                }\n                float _4300;\n                if (_4299)\n                {\n                    _4300 = _392_fa_fog_b.y * _4256;\n                }\n                else\n                {\n                    _4300 = (_392_fa_fog_b.y * (1.0f - exp(-min(_392_fa_fog_b.w * _4256, 80.0f)))) / _392_fa_fog_b.w;\n                }\n                bool _4325 = _4261 <= 0.0f;\n                bool _4332;\n                if (!_4325)\n                {\n                    _4332 = _392_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4332 = _4325;\n                }\n                float _4333;\n                if (_4332)\n                {\n                    _4333 = _392_fa_fog_b.y * _4261;\n                }\n                else\n                {\n                    _4333 = (_392_fa_fog_b.y * (1.0f - exp(-min(_392_fa_fog_b.w * _4261, 80.0f)))) / _392_fa_fog_b.w;\n                }\n                float _4360;\n                if (abs(_4251) < 0.001000000047497451305389404296875f)\n                {\n                    _4360 = _4272;\n                }\n                else\n                {\n                    _4360 = (_4333 - _4300) / _4251;\n                }\n                tau += (_4201 * max(_4360, 0.0f));\n            }\n            result = lerp(result, _392_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4491);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_392",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2049",
            "hlsl_register_b_n": 7
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
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "hlsl_register_t_n": 6
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 7
            }
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
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
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 10
            }
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 11
            }
          }
        ],
        "samplers": [
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
            "stage": "fragment",
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1
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
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _381 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _381;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_388, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _392_fa_camera_pos : packoffset(c0);\n    float4 _392_fa_ambient : packoffset(c1);\n    float4 _392_fa_base_color : packoffset(c2);\n    float4 _392_fa_emissive : packoffset(c3);\n    float4 _392_fa_model_emissive : packoffset(c4);\n    float4 _392_fa_pbr : packoffset(c5);\n    float4 _392_fa_maps : packoffset(c6);\n    float4 _392_fa_fog : packoffset(c7);\n    float4 _392_fa_fog_b : packoffset(c8);\n    float4 _392_fa_fog_c : packoffset(c9);\n    float4 _392_fa_counts : packoffset(c10);\n    float4 _392_fa_env_sky : packoffset(c11);\n    float4 _392_fa_env_horizon : packoffset(c12);\n    float4 _392_fa_time : packoffset(c13);\n    float4 _392_fa_cl_vpx : packoffset(c14);\n    float4 _392_fa_cl_vpy : packoffset(c15);\n    float4 _392_fa_cl_vpw : packoffset(c16);\n    float4 _392_fa_cl_fwd : packoffset(c17);\n    float4 _392_fa_cl_grid : packoffset(c18);\n    float4 _392_fa_cl_info : packoffset(c19);\n    float4 _392_fa_layers_a : packoffset(c20);\n    float4 _392_fa_layers_b : packoffset(c21);\n    float4 _392_fa_layers_c : packoffset(c22);\n    float4 _392_fa_layers_d : packoffset(c23);\n    float4 _392_fa_ct_a : packoffset(c24);\n    float4 _392_fa_ct_b : packoffset(c25);\n    float4 _392_fa_ct_vpx : packoffset(c26);\n    float4 _392_fa_ct_vpy : packoffset(c27);\n    float4 _392_fa_ct_vpw : packoffset(c28);\n    float4 _392_fa_ct_fwd : packoffset(c29);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2049_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2049_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2049_fa_shadow_info[4] : packoffset(c20);\n    float4 _2049_fa_shadow_split : packoffset(c24);\n    float4 _2049_fa_shadow_cfg : packoffset(c25);\n    float4 _2049_fa_shadow_bias : packoffset(c26);\n    float4 _2049_fa_shadow_eye : packoffset(c27);\n    float4 _2049_fa_shadow_fwd : packoffset(c28);\n    float4 _2049_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1320 = _392_fa_cl_info.x < 0.0f;\n    bool _1327;\n    if (!_1320)\n    {\n        _1327 = _392_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1327 = _1320;\n    }\n    bool _1335;\n    if (!_1327)\n    {\n        _1335 = _392_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1335 = _1327;\n    }\n    bool _1342;\n    if (!_1335)\n    {\n        _1342 = _392_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1342 = _1335;\n    }\n    bool _1349;\n    if (!_1342)\n    {\n        _1349 = _392_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1349 = _1342;\n    }\n    if (_1349)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1359 = float4(world_pos, 1.0f);\n    float _1365 = dot(_392_fa_cl_vpw, _1359);\n    if (!(_1365 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1387 = float2(dot(_392_fa_cl_vpx, _1359), dot(_392_fa_cl_vpy, _1359)) / _1365.xx;\n    int _1391 = int(_392_fa_cl_grid.x);\n    int _1395 = int(_392_fa_cl_grid.y);\n    int param = (int(_392_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_392_fa_cl_fwd.xyz, world_pos) + _392_fa_cl_fwd.w, _392_fa_cl_grid.w) / _392_fa_cl_grid.w) * _392_fa_cl_grid.z)), 0, int(_392_fa_cl_info.y) - 1) * _1395) + clamp(int(floor(((_1387.y * 0.5f) + 0.5f) * _392_fa_cl_grid.y)), 0, _1395 - 1)) * _1391)) + clamp(int(floor(((_1387.x * 0.5f) + 0.5f) * _392_fa_cl_grid.x)), 0, _1391 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1471 = fa_cluster_texel(param);\n    return int2(int(_1471.x), int(_1471.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_392_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3502 = fa_cluster_lookup(param);\n    fa_cl_slot = _3502.x;\n    fa_cl_local = _3502.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3705 = fa_linear_to_srgb(param);\n        c = _3705;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3713 = fa_srgb_to_linear(param_1);\n            c = _3713;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _275;\n    if (i.front_facing)\n    {\n        _275 = i.world_normal;\n    }\n    else\n    {\n        _275 = -i.world_normal;\n    }\n    float3 _299 = normalize(i.world_tangent.xyz - (_275 * dot(_275, i.world_tangent.xyz)));\n    float3 _326 = normalize(((_299 * m.x) + ((cross(_275, _299) * i.world_tangent.w) * m.y)) + (_275 * m.z));\n    float3 _329;\n    if (i.front_facing)\n    {\n        _329 = _326;\n    }\n    else\n    {\n        _329 = -_326;\n    }\n    return _329;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _392_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3744 = fa_tex_fix(param_2, param_3);\n    float4 _4803 = base_t;\n    _4803.x = _3744.x;\n    _4803.y = _3744.y;\n    _4803.z = _3744.z;\n    base_t = _4803;\n    float4 _3758 = (_4803 * _392_fa_base_color) * i.vertex_color;\n    float3 _4655 = i.world_normal;\n    if (_392_fa_maps.z > 0.5f)\n    {\n        float param_4 = _392_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3790 = fa_tex_fix(param_6, param_7);\n        float3 _3793 = (_3790 * 2.0f) - 1.0f.xxx;\n        float2 _3798 = _3793.xy * _392_fa_maps.x;\n        float3 _4811 = _3793;\n        _4811.x = _3798.x;\n        _4811.y = _3798.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4811;\n        _4655 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _392_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3826 = fa_tex_fix(param_12, param_13);\n    float4 _4814 = mrt;\n    _4814.x = _3826.x;\n    _4814.y = _3826.y;\n    _4814.z = _3826.z;\n    mrt = _4814;\n    float4 _3854 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _392_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3854.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3865 = fa_tex_fix(param_16, param_17);\n    float param_18 = _392_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3895 = fa_tex_fix(param_20, param_21);\n    float _4660 = _392_fa_layers_a.x;\n    float _4661 = _392_fa_layers_a.y;\n    float _4664 = _392_fa_layers_a.z;\n    float _4663 = _392_fa_layers_b.w;\n    float _4666 = _392_fa_layers_c.x;\n    if (_392_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_392_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4660 *= _3865.y;\n            _4661 *= _3865.z;\n            _4663 *= _3854.w;\n        }\n        if (_392_fa_layers_c.z > 1.5f)\n        {\n            _4664 *= mrt.x;\n            _4666 *= mrt.w;\n        }\n    }\n    Surface _4685 = { _3758.xyz, _3758.w, _4655, clamp(_392_fa_pbr.x * _3826.z, 0.0f, 1.0f), clamp(_392_fa_pbr.y * _3826.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_392_fa_maps.y * (_3865.x - 1.0f)), _392_fa_emissive.xyz + (_392_fa_model_emissive.xyz * _3895), _4660, _4661, _392_fa_layers_b.xyz, _4663, _4664, _392_fa_layers_a.w, _4666, _392_fa_layers_c.y, _392_fa_layers_d.xyz };\n    return _4685;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1551 = rect.zw - rect.xy;\n    float2 _1555 = _1551 * atlas;\n    float2 _1559 = ddx * _1555;\n    float2 _1563 = ddy * _1555;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1551), clamp(0.5f * log2(max(max(dot(_1559, _1559), dot(_1563, _1563)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1596 = _392_fa_counts.y < 0.5f;\n    bool _1603;\n    if (!_1596)\n    {\n        _1603 = _392_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1603 = _1596;\n    }\n    if (_1603)\n    {\n        return;\n    }\n    float3 _1609 = ddx(world_pos);\n    float3 _1612 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1616 = fa_cluster_texel(param);\n    int _1620 = int(_1616.w);\n    if (_1620 < 1)\n    {\n        return;\n    }\n    int _1630 = int(_392_fa_counts.y + 0.5f);\n    int param_1 = _1630;\n    float4 _1634 = fa_light_texel(param_1);\n    float2 _1637 = _1634.yz;\n    int _1641 = int(_1634.w);\n    int param_2 = _1630 + 1;\n    float4 _1646 = fa_light_texel(param_2);\n    float _1647 = _1646.x;\n    int _1653 = int(_392_fa_counts.w + 0.5f) - 1;\n    int _1657 = int(_1616.z);\n    float3 _1922;\n    for (int k = 0; k < _1620; k++)\n    {\n        int _1670 = _1657 + k;\n        int param_3 = _1641 + (_1670 >> 2);\n        int _1687 = (_1630 + 2) + (int(fa_light_texel(param_3)[_1670 & 3]) * 7);\n        int param_4 = _1687 + 6;\n        float4 _1692 = fa_light_texel(param_4);\n        if (((int(_1692.w + 0.5f) >> _1653) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1687;\n        float4 _1707 = fa_light_texel(param_5);\n        int param_6 = _1687 + 1;\n        float4 _1712 = fa_light_texel(param_6);\n        int param_7 = _1687 + 2;\n        float4 _1717 = fa_light_texel(param_7);\n        float3 _1720 = _1707.xyz;\n        float _1725 = dot(_1720, world_pos) + _1707.w;\n        float3 _1727 = _1712.xyz;\n        float _1732 = dot(_1727, world_pos) + _1712.w;\n        float3 _1734 = _1717.xyz;\n        float _1739 = dot(_1734, world_pos) + _1717.w;\n        bool _1744 = abs(_1725) > 0.5f;\n        bool _1752;\n        if (!_1744)\n        {\n            _1752 = abs(_1732) > 0.5f;\n        }\n        else\n        {\n            _1752 = _1744;\n        }\n        bool _1760;\n        if (!_1752)\n        {\n            _1760 = abs(_1739) > 0.5f;\n        }\n        else\n        {\n            _1760 = _1752;\n        }\n        if (_1760)\n        {\n            continue;\n        }\n        float _1775 = clamp(dot(geo_normal, normalize(_1734)) * _1692.z, 0.0f, 1.0f);\n        if (_1775 <= 0.0f)\n        {\n            continue;\n        }\n        float _1795 = (clamp((0.5f - abs(_1739)) * 10.0f, 0.0f, 1.0f) * _1775) * _1692.x;\n        float2 _1803 = float2(_1725 + 0.5f, 0.5f - _1732);\n        float2 _1813 = float2(dot(_1720, _1609), dot(_1727, _1609));\n        float2 _1823 = float2(dot(_1720, _1612), dot(_1727, _1612));\n        int param_8 = _1687 + 5;\n        float4 _1828 = fa_light_texel(param_8);\n        int param_9 = _1687 + 3;\n        float4 _1833 = fa_light_texel(param_9);\n        int param_10 = _1687 + 4;\n        float4 _1838 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1828.xyz;\n        bool _1848 = _1833.z > _1833.x;\n        if (_1848)\n        {\n            float4 param_11 = _1833;\n            float2 param_12 = _1803;\n            float2 param_13 = _1637;\n            float2 param_14 = _1813;\n            float2 param_15 = _1823;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1647 > 0.5f) && (_1647 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1874 = fa_dc_to_linear(param_16);\n                float4 _4735 = tx;\n                _4735.x = _1874.x;\n                _4735.y = _1874.y;\n                _4735.z = _1874.z;\n                tx = _4735;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1795 * tex_a) * _1828.w, 0.0f, 1.0f).xxx);\n        if (_1838.z > _1838.x)\n        {\n            float4 param_17 = _1838;\n            float2 param_18 = _1803;\n            float2 param_19 = _1637;\n            float2 param_20 = _1813;\n            float2 param_21 = _1823;\n            float4 _1918 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1647 > 1.5f)\n            {\n                float3 param_22 = _1918.xyz;\n                float3 _1928 = fa_dc_to_srgb(param_22);\n                _1922 = _1928;\n            }\n            else\n            {\n                _1922 = _1918.xyz;\n            }\n            float3 _1937 = (_1922 * 2.0f) - 1.0f.xxx;\n            float2 _1942 = _1937.xy * _1692.y;\n            float3 _1964 = (normalize(_1720) * _1942.x) + (normalize(_1727) * _1942.y);\n            float3 _1967 = normalize(normal);\n            normal = normalize(lerp(_1967, normalize((_1967 * max(_1937.z, 0.0500000007450580596923828125f)) + (_1964 - (_1967 * dot(_1967, _1964)))), clamp(_1795 * (_1848 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_392_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3162 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3162;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_392_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _392_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return ambientColor;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_392_fa_cl_info.x) + int(_392_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_392_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _451_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _451_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _570 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _583 = (c - (ru * hx)) - p;\n        float3 _589 = ru * (2.0f * hx);\n        float _595 = max(dot(_589, _589), 9.9999999392252902907785028219223e-09f);\n        float _599 = dot(_583, _589);\n        float t = clamp((-_599) / _595, 0.0f, 1.0f);\n        if (_570)\n        {\n            float _614 = dot(r, _589);\n            float _620 = _595 - (_614 * _614);\n            if (abs(_620) > (9.9999997473787516355514526367188e-06f * _595))\n            {\n                t = clamp(((dot(r, _583) * _614) - _599) / _620, 0.0f, 1.0f);\n            }\n        }\n        return (p + _583) + (_589 * t);\n    }\n    float3 q = p;\n    float _652 = dot(r, axis);\n    bool _660;\n    if (_570)\n    {\n        _660 = abs(_652) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _660 = _570;\n    }\n    if (_660)\n    {\n        float _670 = dot(c - p, axis) / _652;\n        if (_670 > 0.0f)\n        {\n            q = p + (r * _670);\n        }\n    }\n    float3 _683 = q - c;\n    float2 xy = float2(dot(_683, ru), dot(_683, uu));\n    if (shape > 0.5f)\n    {\n        float _698 = length(xy);\n        if (_698 > hx)\n        {\n            xy *= (hx / _698);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _341 = abs(d);\n    float _343 = _341.x;\n    float _345 = _341.y;\n    bool _346 = _343 >= _345;\n    bool _354;\n    if (_346)\n    {\n        _354 = _343 >= _341.z;\n    }\n    else\n    {\n        _354 = _346;\n    }\n    int _355;\n    if (_354)\n    {\n        _355 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _370;\n        if (_345 >= _341.z)\n        {\n            _370 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _370 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _355 = _370;\n    }\n    return _355;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _490 = dot(d, right);\n    float _494 = dot(d, up);\n    float _505;\n    if (((_490 * _490) + (_494 * _494)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _505 = atan2(_494, _490) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _505 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_505 - floor(_505)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _736 = fa_light_base(param);\n    bool _740 = _392_fa_ambient.w > 4.5f;\n    int param_1 = _736;\n    float4 _744 = fa_light_texel(param_1);\n    int param_2 = _736 + 1;\n    float4 _749 = fa_light_texel(param_2);\n    float _752 = _749.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _764 = _740 && (_752 > 2.5f);\n    fa_light_is_area = _764;\n    bool _766 = _752 < 0.5f;\n    float3 l;\n    if (_766)\n    {\n        l = normalize(_744.xyz);\n        if (_740)\n        {\n            int param_3 = _736 + 6;\n            float4 _780 = fa_light_texel(param_3);\n            if (_780.z > 0.5f)\n            {\n                int param_4 = _736 + 4;\n                float4 _790 = fa_light_texel(param_4);\n                int param_5 = _736 + 5;\n                float4 _795 = fa_light_texel(param_5);\n                float2 param_6 = _780.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _790.xyz) * _790.w, (-dot(world_pos, _795.xyz)) * _795.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _825 = _744.xyz;\n        float3 _827 = _825 - world_pos;\n        float3 to_light = _827;\n        float _830 = length(_827);\n        float reach = _830;\n        bool front = true;\n        if (_764)\n        {\n            int param_8 = _736 + 7;\n            reach = max(_830 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _736 + 4;\n            float4 _854 = fa_light_texel(param_9);\n            int param_10 = _736 + 5;\n            float4 _859 = fa_light_texel(param_10);\n            int param_11 = _736 + 6;\n            float4 _864 = fa_light_texel(param_11);\n            float _865 = _864.w;\n            int param_12 = _736 + 2;\n            float3 _872 = normalize(fa_light_texel(param_12).xyz);\n            bool _874 = _865 > 1.5f;\n            bool _882;\n            if (!_874)\n            {\n                _882 = dot(_872, to_light) < 0.0f;\n            }\n            else\n            {\n                _882 = _874;\n            }\n            front = _882;\n            float3 r = 0.0f.xxx;\n            float3 _891 = _392_fa_camera_pos.xyz - world_pos;\n            bool _895 = dot(n, n) > 0.5f;\n            bool _903;\n            if (_895)\n            {\n                _903 = dot(_891, _891) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _903 = _895;\n            }\n            if (_903)\n            {\n                r = reflect(-normalize(_891), normalize(n));\n            }\n            float3 param_13 = _825;\n            float3 param_14 = _872;\n            float3 param_15 = _854.xyz;\n            float3 param_16 = _859.xyz;\n            float param_17 = _854.w;\n            float param_18 = _859.w;\n            float param_19 = _865;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _939 = length(to_light);\n        dist = _939;\n        l = to_light / max(_939, 9.9999997473787516355514526367188e-05f).xxx;\n        float _953 = reach / max(_744.w, 0.001000000047497451305389404296875f);\n        float _959 = clamp(1.0f - (_953 * _953), 0.0f, 1.0f);\n        float _961;\n        if (front)\n        {\n            _961 = _959 * _959;\n        }\n        else\n        {\n            _961 = 0.0f;\n        }\n        atten = _961;\n        bool _972 = _752 < 2.5f;\n        if ((_752 > 1.5f) && _972)\n        {\n            int param_22 = _736 + 2;\n            float4 _980 = fa_light_texel(param_22);\n            float _990 = _980.w;\n            int param_23 = _736 + 3;\n            float4 _995 = fa_light_texel(param_23);\n            float _996 = _995.x;\n            float cos_inner = _996;\n            if (_996 > 1.5f)\n            {\n                cos_inner = lerp(_990, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_990, cos_inner, dot(-l, normalize(_980.xyz)));\n        }\n        if (_740 && (_752 < 1.5f))\n        {\n            int param_24 = _736 + 6;\n            float4 _1020 = fa_light_texel(param_24);\n            if (_1020.z > 0.5f)\n            {\n                float3 _1028 = -to_light;\n                int param_25 = _736 + 4;\n                int param_26 = _736 + 5;\n                float3 _1042 = fa_light_texel(param_25).xyz;\n                float3 _1046 = fa_light_texel(param_26).xyz;\n                float3 _1055 = float3(dot(_1028, _1042), dot(_1028, _1046), dot(_1028, cross(_1042, _1046)));\n                float3 param_27 = _1055;\n                int _1059 = fa_cube_face(param_27);\n                int param_28 = _1059;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1086 = float2(dot(_1055, cross(param_29, param_30)), dot(_1055, param_30)) / max(dot(_1055, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1090 = _1059 / 3;\n                float2 param_31 = _1020.xy + (float2(float(_1059 - (_1090 * 3)), float(_1090)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1086.x), 0.5f - (0.5f * _1086.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _736 + 7;\n            float4 _1120 = fa_light_texel(param_33);\n            if (_1120.z > 0.5f)\n            {\n                int param_34 = _736 + 2;\n                int param_35 = _736 + 4;\n                int param_36 = _736 + 5;\n                float2 param_37 = _1120.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_740 && _972)\n            {\n                int param_42 = _736 + 6;\n                float4 _1167 = fa_light_texel(param_42);\n                int param_43 = _736 + 7;\n                float4 _1172 = fa_light_texel(param_43);\n                bool _1175 = _1167.z > 0.5f;\n                bool _1182;\n                if (!_1175)\n                {\n                    _1182 = _1172.z > 0.5f;\n                }\n                else\n                {\n                    _1182 = _1175;\n                }\n                if (_1182)\n                {\n                    int param_44 = _736 + 2;\n                    float4 _1189 = fa_light_texel(param_44);\n                    float3 _1193 = normalize(_1189.xyz);\n                    int param_45 = _736 + 4;\n                    float4 _1198 = fa_light_texel(param_45);\n                    int param_46 = _736 + 5;\n                    float4 _1203 = fa_light_texel(param_46);\n                    if (_1175)\n                    {\n                        float3 _1211 = -to_light;\n                        float _1218 = _1189.w;\n                        float _1234 = 0.5f / max(dot(_1211, _1193) * (sqrt(max(1.0f - (_1218 * _1218), 0.0f)) / max(_1218, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1167.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1211, _1198.xyz) * _1234), 0.5f - (dot(_1211, _1203.xyz) * _1234));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1172.z > 0.5f)\n                    {\n                        float2 param_49 = _1172.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1193;\n                        float3 param_52 = _1198.xyz;\n                        float3 param_53 = _1203.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4609 = _749.xyz * atten;\n    if (_740)\n    {\n        _4609 *= fa_light_tint;\n    }\n    int _1302;\n    if (_766)\n    {\n        _1302 = 0;\n    }\n    else\n    {\n        _1302 = ((_752 > 1.5f) && (_752 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4620 = { l, _4609, atten, 1.0f, dist, _1302 };\n    return _4620;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2039;\n    if (i == 0)\n    {\n        _2039 = _2049_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2055;\n        if (i == 1)\n        {\n            _2055 = _2049_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2063;\n            if (i == 2)\n            {\n                _2063 = _2049_fa_shadow_split.z;\n            }\n            else\n            {\n                _2063 = _2049_fa_shadow_split.w;\n            }\n            _2055 = _2063;\n        }\n        _2039 = _2055;\n    }\n    return _2039;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2096 = fa_shadow_depth(param, param_1);\n    float _2100;\n    if (conv.x < 0.5f)\n    {\n        _2100 = _2096;\n    }\n    else\n    {\n        _2100 = (conv.y * conv.z) / (conv.z - (_2096 * (conv.z - conv.y)));\n    }\n    return _2100;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2027 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2027), sin(_2027)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2146 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2155;\n        if (k < 0.0f)\n        {\n            _2155 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2155 = k;\n        }\n        float _2175 = clamp((_2155 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2146;\n            float2 _2194 = fa_shadow_vogel(param_3, param_4, param_5) * _2175;\n            float2 param_6 = uv + (_2194 * _2049_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2206 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2206 < (zr - (length(_2194) * plane)))\n            {\n                sum += _2206;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2232 = sum / cnt;\n        float _2242;\n        if (k < 0.0f)\n        {\n            _2242 = (-k) / max(_2232, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2242 = k;\n        }\n        radius = clamp(((max(zr - _2232, 0.0f) * unit) * _2242) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2264 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2264; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2264;\n        float param_11 = _2146;\n        float2 _2283 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2283 * _2049_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2283) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2264);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2325 = max(_2049_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2330 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2336 = sqrt(1.0f - (_2330 * _2330));\n    float _2343 = min(_2336 / max(_2330, 0.20000000298023223876953125f), 4.0f);\n    float _2348;\n    if (_2049_fa_shadow_bias.y > 0.0f)\n    {\n        _2348 = _2049_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2348 = 1.5f * _2049_fa_shadow_info[ci].x;\n    }\n    float4 _2373 = mul(float4(world + (n * (_2348 * _2336)), 1.0f), _2049_fa_shadow_mat[ci]);\n    float _2380 = _2373.x;\n    bool _2383 = _2380 < _2049_fa_shadow_rect[ci].x;\n    bool _2392;\n    if (!_2383)\n    {\n        _2392 = _2380 > _2049_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2392 = _2383;\n    }\n    bool _2401;\n    if (!_2392)\n    {\n        _2401 = _2373.y < _2049_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2401 = _2392;\n    }\n    bool _2410;\n    if (!_2401)\n    {\n        _2410 = _2373.y > _2049_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2410 = _2401;\n    }\n    bool _2417;\n    if (!_2410)\n    {\n        _2417 = _2373.z > 1.0f;\n    }\n    else\n    {\n        _2417 = _2410;\n    }\n    if (_2417)\n    {\n        return -1.0f;\n    }\n    float _2425;\n    if (_2049_fa_shadow_bias.x > 0.0f)\n    {\n        _2425 = _2049_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2425 = 1.5f * _2049_fa_shadow_info[ci].x;\n    }\n    float2 param = _2373.xy;\n    float4 param_1 = _2049_fa_shadow_rect[ci];\n    float param_2 = _2373.z - ((_2425 * (1.0f + (0.5f * _2343))) / _2325);\n    float param_3 = _2049_fa_shadow_info[ci].x;\n    float param_4 = _2325;\n    float param_5 = _2325 * 0.25f;\n    float param_6 = ((_2049_fa_shadow_info[ci].x * min(_2343, 3.0f)) * 0.5f) / _2325;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2049_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2049_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_392_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2803 = int(_2049_fa_shadow_cfg.x + 0.5f);\n    if (_2803 < 1)\n    {\n        return 1.0f;\n    }\n    float _2818 = dot(world - _2049_fa_shadow_eye.xyz, _2049_fa_shadow_fwd.xyz);\n    int param = _2803 - 1;\n    if (_2818 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2830 = _2803 > 1;\n    bool _2837;\n    if (_2830)\n    {\n        _2837 = _2818 > _2049_fa_shadow_split.x;\n    }\n    else\n    {\n        _2837 = _2830;\n    }\n    if (_2837)\n    {\n        ci = 1;\n    }\n    bool _2841 = _2803 > 2;\n    bool _2848;\n    if (_2841)\n    {\n        _2848 = _2818 > _2049_fa_shadow_split.y;\n    }\n    else\n    {\n        _2848 = _2841;\n    }\n    if (_2848)\n    {\n        ci = 2;\n    }\n    bool _2852 = _2803 > 3;\n    bool _2859;\n    if (_2852)\n    {\n        _2859 = _2818 > _2049_fa_shadow_split.z;\n    }\n    else\n    {\n        _2859 = _2852;\n    }\n    if (_2859)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2803)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2885 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2885;\n        if (_2885 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2049_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2910;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2910 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2910 = _2049_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2929 = _2049_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2910, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2940 = clamp((_2818 - (fa_shadow_split_at(param_7) - _2929)) / _2929, 0.0f, 1.0f);\n        if (_2940 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2803)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2961 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2961;\n                if (_2961 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2940);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2483 = _392_fa_pbr.z < 0.5f;\n    bool _2490;\n    if (!_2483)\n    {\n        _2490 = _2049_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2490 = _2483;\n    }\n    if (_2490)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2049_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2503 = fa_light_texel(param);\n    float _2504 = _2503.x;\n    if (_2504 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2513 = int(_2504 + 0.5f);\n    int param_1 = _2513;\n    float4 _2517 = fa_light_texel(param_1);\n    int param_2 = _2513 + 1;\n    float4 _2522 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2525 = _2517.y;\n    if (_2525 > 0.0f)\n    {\n        float _2542 = 1.0f - smoothstep(0.75f * _2525, _2525, length(world - _2049_fa_shadow_eye.xyz));\n        fade = _2542;\n        if (_2542 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2517.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2566 = (_2513 + 2) + (face * 6);\n    int param_4 = _2566;\n    int param_5 = _2566 + 1;\n    int param_6 = _2566 + 3;\n    float4 _2580 = fa_light_texel(param_6);\n    int param_7 = _2566 + 4;\n    float4 _2585 = fa_light_texel(param_7);\n    int param_8 = _2566 + 5;\n    float4 _2590 = fa_light_texel(param_8);\n    float _2602 = _2590.x * max(dot(_2580, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2607 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2630 = clamp(dot(n, _2580.xyz), -1.0f, 1.0f);\n    float _2649 = min(sqrt(1.0f - (_2630 * _2630)) / max(abs(dot(n, world - lpos)) / max(dot(_2580, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2652 = _2522.y;\n    float _2654;\n    if (_2652 > 0.0f)\n    {\n        _2654 = _2652;\n    }\n    else\n    {\n        _2654 = 1.5f * _2602;\n    }\n    float4 _2674 = float4(world + (n * (_2654 * sqrt(1.0f - (_2607 * _2607)))), 1.0f);\n    float _2678 = dot(_2580, _2674);\n    float _2681 = _2590.y;\n    if (_2678 < _2681)\n    {\n        return 1.0f;\n    }\n    float2 _2696 = float2(dot(fa_light_texel(param_4), _2674), dot(fa_light_texel(param_5), _2674)) / _2678.xx;\n    float _2698 = _2696.x;\n    bool _2701 = _2698 < _2585.x;\n    bool _2710;\n    if (!_2701)\n    {\n        _2710 = _2698 > _2585.z;\n    }\n    else\n    {\n        _2710 = _2701;\n    }\n    bool _2719;\n    if (!_2710)\n    {\n        _2719 = _2696.y < _2585.y;\n    }\n    else\n    {\n        _2719 = _2710;\n    }\n    bool _2728;\n    if (!_2719)\n    {\n        _2728 = _2696.y > _2585.w;\n    }\n    else\n    {\n        _2728 = _2719;\n    }\n    if (_2728)\n    {\n        return 1.0f;\n    }\n    float _2734 = _2522.x;\n    float _2736;\n    if (_2734 > 0.0f)\n    {\n        _2736 = _2734;\n    }\n    else\n    {\n        _2736 = 1.5f * _2602;\n    }\n    float2 param_9 = _2696;\n    float4 param_10 = _2585;\n    float param_11 = _2678 - (_2736 * (1.0f + (0.5f * _2649)));\n    float param_12 = _2602;\n    float param_13 = 1.0f;\n    float param_14 = _2590.z * 0.25f;\n    float param_15 = (_2602 * min(_2649, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2681, _2590.z);\n    int param_17 = int(_2517.z + 0.5f);\n    float param_18 = _2517.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3242 = _392_fa_ct_a.x < 0.5f;\n    bool _3249;\n    if (!_3242)\n    {\n        _3249 = _2049_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3249 = _3242;\n    }\n    if (_3249)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2049_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3262 = fa_light_texel(param);\n    float _3263 = _3262.y;\n    float len = _3263;\n    if (_3263 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3275 = length(world - _392_fa_camera_pos.xyz);\n    float _3285 = 1.0f - smoothstep(0.5f * _392_fa_ct_b.x, _392_fa_ct_b.x, _3275);\n    if (_3285 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3291 = len;\n    float _3294 = min(_3291, 0.89999997615814208984375f * dist);\n    len = _3294;\n    float _3300 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3275);\n    float _3305 = _3300 + (0.5f * _3294);\n    float3 _3311 = world + (gn * _3300);\n    float _3313 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _3378;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3329 = (float(k) + _3313) * 0.083333335816860198974609375f;\n        float3 _3337 = _3311 + (l * (_3329 * len));\n        float4 _3343 = float4(_3337, 1.0f);\n        float _3349 = dot(_392_fa_ct_vpw, _3343);\n        if (_3349 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _3369 = float2(dot(_392_fa_ct_vpx, _3343), dot(_392_fa_ct_vpy, _3343)) / _3349.xx;\n        float _3373 = _3369.x * 0.5f;\n        float _3374 = _3373 + 0.5f;\n        if (_392_fa_ct_a.y > 0.5f)\n        {\n            _3378 = (_3369.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _3378 = 0.5f - (_3369.y * 0.5f);\n        }\n        bool _3394 = _3374 < 0.0f;\n        bool _3401;\n        if (!_3394)\n        {\n            _3401 = _3374 >= 1.0f;\n        }\n        else\n        {\n            _3401 = _3394;\n        }\n        bool _3408;\n        if (!_3401)\n        {\n            _3408 = _3378 < 0.0f;\n        }\n        else\n        {\n            _3408 = _3401;\n        }\n        bool _3415;\n        if (!_3408)\n        {\n            _3415 = _3378 >= 1.0f;\n        }\n        else\n        {\n            _3415 = _3408;\n        }\n        if (_3415)\n        {\n            break;\n        }\n        float4 _3434 = fa_screen_tex.Load(int3(int2(float2(_3374, _3378) * _392_fa_ct_a.zw), 0));\n        if (_3434.w < 0.5f)\n        {\n            continue;\n        }\n        float _3453 = (dot(_392_fa_ct_fwd.xyz, _3337) + _392_fa_ct_fwd.w) - _3434.x;\n        if ((_3453 > _3300) && (_3453 < _3305))\n        {\n            occ = max(occ, (1.0f - (_3329 * _3329)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_3374, 0.5f - _3373), min(_3378, 1.0f - _3378))));\n        }\n    }\n    return 1.0f - (occ * _3285);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3529 = fa_lm.z > 0.5f;\n    bool _3535;\n    if (_3529)\n    {\n        int param = li;\n        _3535 = fa_light_baked(param);\n    }\n    else\n    {\n        _3535 = _3529;\n    }\n    if (_3535)\n    {\n        int param_1 = li;\n        LightSample _4633 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4633;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3559 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _4635 = _3559.color;\n    float _4637 = _3559.shadow;\n    bool _3562 = _3559.type == 0;\n    if (_3562 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3559.direction;\n        float _3573 = fa_shadow_factor(param_5, param_6);\n        _4637 = _3573;\n        _4635 *= _3573;\n    }\n    else\n    {\n        bool _3584 = _3559.type != 0;\n        bool _3590;\n        if (_3584)\n        {\n            _3590 = _3559.attenuation > 0.0f;\n        }\n        else\n        {\n            _3590 = _3584;\n        }\n        if (_3590)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3559.direction;\n            float _3609 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4637 = _3609;\n            _4635 *= _3609;\n        }\n    }\n    bool _3619 = _392_fa_ct_a.x > 0.5f;\n    bool _3625;\n    if (_3619)\n    {\n        _3625 = _3559.attenuation > 0.0f;\n    }\n    else\n    {\n        _3625 = _3619;\n    }\n    if (_3625)\n    {\n        float _3632;\n        if (_3562)\n        {\n            _3632 = 1000000000.0f;\n        }\n        else\n        {\n            _3632 = _3559._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3559.direction;\n        float param_18 = _3632;\n        float _3650 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _4637 *= _3650;\n        _4635 *= _3650;\n    }\n    LightSample _4652 = { _3559.direction, _4635, _3559.attenuation, _4637, _3559._distance, _3559.type };\n    return _4652;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2049_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2985 = int(_2049_fa_shadow_cfg.x + 0.5f);\n    float _2995 = dot(world - _2049_fa_shadow_eye.xyz, _2049_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3000 = _2985 > 0;\n    bool _3009;\n    if (_3000)\n    {\n        int param = _2985 - 1;\n        _3009 = _2995 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3009 = _3000;\n    }\n    if (_3009)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3015 = _2985 > 1;\n        bool _3022;\n        if (_3015)\n        {\n            _3022 = _2995 > _2049_fa_shadow_split.x;\n        }\n        else\n        {\n            _3022 = _3015;\n        }\n        if (_3022)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3028 = _2985 > 2;\n        bool _3035;\n        if (_3028)\n        {\n            _3035 = _2995 > _2049_fa_shadow_split.y;\n        }\n        else\n        {\n            _3035 = _3028;\n        }\n        if (_3035)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3041 = _2985 > 3;\n        bool _3048;\n        if (_3041)\n        {\n            _3048 = _2995 > _2049_fa_shadow_split.z;\n        }\n        else\n        {\n            _3048 = _3041;\n        }\n        if (_3048)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4451 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4451 = -_4451;\n    }\n    float3 _4037 = normalize(_392_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4464 = { fa_world_pos, _4451, fa_world_tangent, fa_uv, fa_vertex_color, _4037, gl_FrontFacing };\n    SurfaceInput param_1 = _4464;\n    Surface _4045 = fa_standard_surface(param_1);\n    float3 _4490 = _4045.albedo;\n    float _4491 = _4045.alpha;\n    float3 _4492 = _4045.normal;\n    float _4493 = _4045.metallic;\n    float _4494 = _4045.roughness;\n    float _4495 = _4045.occlusion;\n    float3 _4496 = _4045.emission;\n    float _4497 = _4045.clearcoat;\n    float _4498 = _4045.clearcoat_roughness;\n    float3 _4499 = _4045.sheen_color;\n    float _4500 = _4045.sheen_roughness;\n    float _4501 = _4045.anisotropy;\n    float _4502 = _4045.anisotropy_rotation;\n    float _4503 = _4045.specular;\n    float _4504 = _4045.ior;\n    float3 _4505 = _4045.specular_color;\n    SurfaceInput _4472 = { fa_world_pos, _4451, fa_world_tangent, fa_uv, fa_vertex_color, _4037, gl_FrontFacing };\n    SurfaceInput param_2 = _4472;\n    Surface param_3 = _4045;\n    surface(param_2, param_3);\n    _4490 = param_3.albedo;\n    _4491 = param_3.alpha;\n    _4492 = param_3.normal;\n    _4493 = param_3.metallic;\n    _4494 = param_3.roughness;\n    _4495 = param_3.occlusion;\n    _4496 = param_3.emission;\n    _4497 = param_3.clearcoat;\n    _4498 = param_3.clearcoat_roughness;\n    _4499 = param_3.sheen_color;\n    _4500 = param_3.sheen_roughness;\n    _4501 = param_3.anisotropy;\n    _4502 = param_3.anisotropy_rotation;\n    _4503 = param_3.specular;\n    _4504 = param_3.ior;\n    _4505 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4451;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4490 = param_6;\n    _4492 = param_7;\n    float3 result;\n    if (_392_fa_emissive.w > 0.5f)\n    {\n        result = _4490;\n    }\n    else\n    {\n        float3 _4083 = _4492;\n        float3 _4084 = normalize(_4083);\n        _4492 = _4084;\n        float3 param_8 = _4084;\n        SurfaceInput _4480 = { fa_world_pos, _4451, fa_world_tangent, fa_uv, fa_vertex_color, _4037, gl_FrontFacing };\n        SurfaceInput param_9 = _4480;\n        Surface _4571 = { _4490, _4491, _4492, _4493, _4494, _4495, _4496, _4497, _4498, _4499, _4500, _4501, _4502, _4503, _4504, _4505 };\n        Surface param_10 = _4571;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _4103 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4103; ln++)\n        {\n            int param_12 = ln;\n            int _4116 = fa_cl_light(param_12);\n            bool _4119 = fa_lm.z > 0.5f;\n            bool _4125;\n            if (_4119)\n            {\n                int param_13 = _4116;\n                _4125 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _4125 = _4119;\n            }\n            if (_4125)\n            {\n                continue;\n            }\n            int param_14 = _4116;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _4451;\n            LightSample _4137 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _4488 = { fa_world_pos, _4451, fa_world_tangent, fa_uv, fa_vertex_color, _4037, gl_FrontFacing };\n            SurfaceInput param_17 = _4488;\n            Surface _4588 = { _4490, _4491, _4492, _4493, _4494, _4495, _4496, _4497, _4498, _4499, _4500, _4501, _4502, _4503, _4504, _4505 };\n            Surface param_18 = _4588;\n            LightSample param_19 = _4137;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _4152 = result;\n    float3 _4153 = _4152 + _4496;\n    result = _4153;\n    float3 param_20 = _4153;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _4162 = _392_fa_fog.w > 0.0f;\n    bool _4169;\n    if (!_4162)\n    {\n        _4169 = _392_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4169 = _4162;\n    }\n    if (_4169)\n    {\n        float3 _4178 = fa_world_pos - _392_fa_camera_pos.xyz;\n        float _4184 = dot(_4178, _392_fa_fog_c.xyz);\n        bool _4188 = _392_fa_fog_c.w > 0.5f;\n        float _4189;\n        if (_4188)\n        {\n            _4189 = _4184;\n        }\n        else\n        {\n            _4189 = length(_4178);\n        }\n        float _4201 = _4189 - _392_fa_fog_b.x;\n        if (_4201 > 0.0f)\n        {\n            float _4210 = _392_fa_fog.w * _4201;\n            float tau = _4210 * _4210;\n            if (_392_fa_fog_b.y > 0.0f)\n            {\n                float _4226;\n                if (_4188)\n                {\n                    _4226 = fa_world_pos.y - (_392_fa_fog_c.y * _4184);\n                }\n                else\n                {\n                    _4226 = _392_fa_camera_pos.y;\n                }\n                float _4247 = lerp(_4226, fa_world_pos.y, clamp(_392_fa_fog_b.x / _4189, 0.0f, 1.0f));\n                float _4251 = fa_world_pos.y - _4247;\n                float _4256 = _4247 - _392_fa_fog_b.z;\n                float _4261 = fa_world_pos.y - _392_fa_fog_b.z;\n                bool _4264 = _4256 <= 0.0f;\n                bool _4265 = !_4264;\n                bool _4271;\n                if (_4265)\n                {\n                    _4271 = _392_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4271 = _4264;\n                }\n                float _4272;\n                if (_4271)\n                {\n                    _4272 = _392_fa_fog_b.y;\n                }\n                else\n                {\n                    _4272 = _392_fa_fog_b.y * exp(-min(_392_fa_fog_b.w * _4256, 80.0f));\n                }\n                bool _4299;\n                if (_4265)\n                {\n                    _4299 = _392_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4299 = _4264;\n                }\n                float _4300;\n                if (_4299)\n                {\n                    _4300 = _392_fa_fog_b.y * _4256;\n                }\n                else\n                {\n                    _4300 = (_392_fa_fog_b.y * (1.0f - exp(-min(_392_fa_fog_b.w * _4256, 80.0f)))) / _392_fa_fog_b.w;\n                }\n                bool _4325 = _4261 <= 0.0f;\n                bool _4332;\n                if (!_4325)\n                {\n                    _4332 = _392_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4332 = _4325;\n                }\n                float _4333;\n                if (_4332)\n                {\n                    _4333 = _392_fa_fog_b.y * _4261;\n                }\n                else\n                {\n                    _4333 = (_392_fa_fog_b.y * (1.0f - exp(-min(_392_fa_fog_b.w * _4261, 80.0f)))) / _392_fa_fog_b.w;\n                }\n                float _4360;\n                if (abs(_4251) < 0.001000000047497451305389404296875f)\n                {\n                    _4360 = _4272;\n                }\n                else\n                {\n                    _4360 = (_4333 - _4300) / _4251;\n                }\n                tau += (_4201 * max(_4360, 0.0f));\n            }\n            result = lerp(result, _392_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4491);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_183",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_392",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2049",
            "hlsl_register_b_n": 7
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
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float",
              "hlsl_register_t_n": 6
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 7
            }
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
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
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 10
            }
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 11
            }
          }
        ],
        "samplers": [
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
            "stage": "fragment",
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1
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
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1
          }
        ]
      }
    },
    "prepass": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _292 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _292;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0f);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n    float4 _213_fa_ct_a : packoffset(c24);\n    float4 _213_fa_ct_b : packoffset(c25);\n    float4 _213_fa_ct_vpx : packoffset(c26);\n    float4 _213_fa_ct_vpy : packoffset(c27);\n    float4 _213_fa_ct_vpw : packoffset(c28);\n    float4 _213_fa_ct_fwd : packoffset(c29);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _785 = base_t;\n    _785.x = _225.x;\n    _785.y = _225.y;\n    _785.z = _225.z;\n    base_t = _785;\n    float4 _241 = (_785 * _213_fa_base_color) * i.vertex_color;\n    float3 _748 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _793 = _279;\n        _793.x = _284.x;\n        _793.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _796 = mrt;\n    _796.x = _313.x;\n    _796.y = _313.y;\n    _796.z = _313.z;\n    mrt = _796;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _753 = _213_fa_layers_a.x;\n    float _754 = _213_fa_layers_a.y;\n    float _757 = _213_fa_layers_a.z;\n    float _756 = _213_fa_layers_b.w;\n    float _759 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _753 *= _355.y;\n            _754 *= _355.z;\n            _756 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    Surface _778 = { _241.xyz, _241.w, _748, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _753, _754, _213_fa_layers_b.xyz, _756, _757, _213_fa_layers_a.w, _759, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _778;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _659 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _672 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _672;\n    SurfaceInput _680 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _680;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
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
          }
        ],
        "samplers": [
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
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _413 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _413;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _420 = _273.world_pos;\n    float4 _284 = float4(_420, 1.0f);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n    float4 _213_fa_ct_a : packoffset(c24);\n    float4 _213_fa_ct_b : packoffset(c25);\n    float4 _213_fa_ct_vpx : packoffset(c26);\n    float4 _213_fa_ct_vpy : packoffset(c27);\n    float4 _213_fa_ct_vpw : packoffset(c28);\n    float4 _213_fa_ct_fwd : packoffset(c29);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _785 = base_t;\n    _785.x = _225.x;\n    _785.y = _225.y;\n    _785.z = _225.z;\n    base_t = _785;\n    float4 _241 = (_785 * _213_fa_base_color) * i.vertex_color;\n    float3 _748 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _793 = _279;\n        _793.x = _284.x;\n        _793.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _796 = mrt;\n    _796.x = _313.x;\n    _796.y = _313.y;\n    _796.z = _313.z;\n    mrt = _796;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _753 = _213_fa_layers_a.x;\n    float _754 = _213_fa_layers_a.y;\n    float _757 = _213_fa_layers_a.z;\n    float _756 = _213_fa_layers_b.w;\n    float _759 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _753 *= _355.y;\n            _754 *= _355.z;\n            _756 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    Surface _778 = { _241.xyz, _241.w, _748, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _753, _754, _213_fa_layers_b.xyz, _756, _757, _213_fa_layers_a.w, _759, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _778;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _659 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _672 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _672;\n    SurfaceInput _680 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _680;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_183",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
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
          }
        ],
        "samplers": [
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
          }
        ]
      }
    }
  }
}
