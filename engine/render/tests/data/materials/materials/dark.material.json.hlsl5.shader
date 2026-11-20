{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5f457c7d0bc8edbcdea422ba00c093c613745eefd8db6d8c8f93fc5e235db1e8",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _260 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _260;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_267, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _378_fa_camera_pos : packoffset(c0);\n    float4 _378_fa_ambient : packoffset(c1);\n    float4 _378_fa_base_color : packoffset(c2);\n    float4 _378_fa_emissive : packoffset(c3);\n    float4 _378_fa_model_emissive : packoffset(c4);\n    float4 _378_fa_pbr : packoffset(c5);\n    float4 _378_fa_maps : packoffset(c6);\n    float4 _378_fa_fog : packoffset(c7);\n    float4 _378_fa_fog_b : packoffset(c8);\n    float4 _378_fa_fog_c : packoffset(c9);\n    float4 _378_fa_counts : packoffset(c10);\n    float4 _378_fa_env_sky : packoffset(c11);\n    float4 _378_fa_env_horizon : packoffset(c12);\n    float4 _378_fa_time : packoffset(c13);\n    float4 _378_fa_cl_vpx : packoffset(c14);\n    float4 _378_fa_cl_vpy : packoffset(c15);\n    float4 _378_fa_cl_vpw : packoffset(c16);\n    float4 _378_fa_cl_fwd : packoffset(c17);\n    float4 _378_fa_cl_grid : packoffset(c18);\n    float4 _378_fa_cl_info : packoffset(c19);\n    float4 _378_fa_layers_a : packoffset(c20);\n    float4 _378_fa_layers_b : packoffset(c21);\n    float4 _378_fa_layers_c : packoffset(c22);\n    float4 _378_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2035_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2035_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2035_fa_shadow_info[4] : packoffset(c20);\n    float4 _2035_fa_shadow_split : packoffset(c24);\n    float4 _2035_fa_shadow_cfg : packoffset(c25);\n    float4 _2035_fa_shadow_bias : packoffset(c26);\n    float4 _2035_fa_shadow_eye : packoffset(c27);\n    float4 _2035_fa_shadow_fwd : packoffset(c28);\n    float4 _2035_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1306 = _378_fa_cl_info.x < 0.0f;\n    bool _1313;\n    if (!_1306)\n    {\n        _1313 = _378_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1313 = _1306;\n    }\n    bool _1321;\n    if (!_1313)\n    {\n        _1321 = _378_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1321 = _1313;\n    }\n    bool _1328;\n    if (!_1321)\n    {\n        _1328 = _378_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1328 = _1321;\n    }\n    bool _1335;\n    if (!_1328)\n    {\n        _1335 = _378_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1335 = _1328;\n    }\n    if (_1335)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1345 = float4(world_pos, 1.0f);\n    float _1351 = dot(_378_fa_cl_vpw, _1345);\n    if (!(_1351 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1373 = float2(dot(_378_fa_cl_vpx, _1345), dot(_378_fa_cl_vpy, _1345)) / _1351.xx;\n    int _1377 = int(_378_fa_cl_grid.x);\n    int _1381 = int(_378_fa_cl_grid.y);\n    int param = (int(_378_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_378_fa_cl_fwd.xyz, world_pos) + _378_fa_cl_fwd.w, _378_fa_cl_grid.w) / _378_fa_cl_grid.w) * _378_fa_cl_grid.z)), 0, int(_378_fa_cl_info.y) - 1) * _1381) + clamp(int(floor(((_1373.y * 0.5f) + 0.5f) * _378_fa_cl_grid.y)), 0, _1381 - 1)) * _1377)) + clamp(int(floor(((_1373.x * 0.5f) + 0.5f) * _378_fa_cl_grid.x)), 0, _1377 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1457 = fa_cluster_texel(param);\n    return int2(int(_1457.x), int(_1457.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_378_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3235 = fa_cluster_lookup(param);\n    fa_cl_slot = _3235.x;\n    fa_cl_local = _3235.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3391 = fa_linear_to_srgb(param);\n        c = _3391;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3399 = fa_srgb_to_linear(param_1);\n            c = _3399;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _261;\n    if (i.front_facing)\n    {\n        _261 = i.world_normal;\n    }\n    else\n    {\n        _261 = -i.world_normal;\n    }\n    float3 _285 = normalize(i.world_tangent.xyz - (_261 * dot(_261, i.world_tangent.xyz)));\n    float3 _312 = normalize(((_285 * m.x) + ((cross(_261, _285) * i.world_tangent.w) * m.y)) + (_261 * m.z));\n    float3 _315;\n    if (i.front_facing)\n    {\n        _315 = _312;\n    }\n    else\n    {\n        _315 = -_312;\n    }\n    return _315;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _378_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3430 = fa_tex_fix(param_2, param_3);\n    float4 _4453 = base_t;\n    _4453.x = _3430.x;\n    _4453.y = _3430.y;\n    _4453.z = _3430.z;\n    base_t = _4453;\n    float4 _3444 = (_4453 * _378_fa_base_color) * i.vertex_color;\n    float3 _4318 = i.world_normal;\n    if (_378_fa_maps.z > 0.5f)\n    {\n        float param_4 = _378_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3476 = fa_tex_fix(param_6, param_7);\n        float3 _3479 = (_3476 * 2.0f) - 1.0f.xxx;\n        float2 _3484 = _3479.xy * _378_fa_maps.x;\n        float3 _4461 = _3479;\n        _4461.x = _3484.x;\n        _4461.y = _3484.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4461;\n        _4318 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _378_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3512 = fa_tex_fix(param_12, param_13);\n    float4 _4464 = mrt;\n    _4464.x = _3512.x;\n    _4464.y = _3512.y;\n    _4464.z = _3512.z;\n    mrt = _4464;\n    float4 _3540 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _378_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3540.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3551 = fa_tex_fix(param_16, param_17);\n    float param_18 = _378_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3581 = fa_tex_fix(param_20, param_21);\n    float _4323 = _378_fa_layers_a.x;\n    float _4324 = _378_fa_layers_a.y;\n    float _4327 = _378_fa_layers_a.z;\n    float _4326 = _378_fa_layers_b.w;\n    float _4329 = _378_fa_layers_c.x;\n    if (_378_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_378_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4323 *= _3551.y;\n            _4324 *= _3551.z;\n            _4326 *= _3540.w;\n        }\n        if (_378_fa_layers_c.z > 1.5f)\n        {\n            _4327 *= mrt.x;\n            _4329 *= mrt.w;\n        }\n    }\n    Surface _4348 = { _3444.xyz, _3444.w, _4318, clamp(_378_fa_pbr.x * _3512.z, 0.0f, 1.0f), clamp(_378_fa_pbr.y * _3512.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_378_fa_maps.y * (_3551.x - 1.0f)), _378_fa_emissive.xyz + (_378_fa_model_emissive.xyz * _3581), _4323, _4324, _378_fa_layers_b.xyz, _4326, _4327, _378_fa_layers_a.w, _4329, _378_fa_layers_c.y, _378_fa_layers_d.xyz };\n    return _4348;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1537 = rect.zw - rect.xy;\n    float2 _1541 = _1537 * atlas;\n    float2 _1545 = ddx * _1541;\n    float2 _1549 = ddy * _1541;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1537), clamp(0.5f * log2(max(max(dot(_1545, _1545), dot(_1549, _1549)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1582 = _378_fa_counts.y < 0.5f;\n    bool _1589;\n    if (!_1582)\n    {\n        _1589 = _378_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1589 = _1582;\n    }\n    if (_1589)\n    {\n        return;\n    }\n    float3 _1595 = ddx(world_pos);\n    float3 _1598 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1602 = fa_cluster_texel(param);\n    int _1606 = int(_1602.w);\n    if (_1606 < 1)\n    {\n        return;\n    }\n    int _1616 = int(_378_fa_counts.y + 0.5f);\n    int param_1 = _1616;\n    float4 _1620 = fa_light_texel(param_1);\n    float2 _1623 = _1620.yz;\n    int _1627 = int(_1620.w);\n    int param_2 = _1616 + 1;\n    float4 _1632 = fa_light_texel(param_2);\n    float _1633 = _1632.x;\n    int _1639 = int(_378_fa_counts.w + 0.5f) - 1;\n    int _1643 = int(_1602.z);\n    float3 _1908;\n    for (int k = 0; k < _1606; k++)\n    {\n        int _1656 = _1643 + k;\n        int param_3 = _1627 + (_1656 >> 2);\n        int _1673 = (_1616 + 2) + (int(fa_light_texel(param_3)[_1656 & 3]) * 7);\n        int param_4 = _1673 + 6;\n        float4 _1678 = fa_light_texel(param_4);\n        if (((int(_1678.w + 0.5f) >> _1639) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1673;\n        float4 _1693 = fa_light_texel(param_5);\n        int param_6 = _1673 + 1;\n        float4 _1698 = fa_light_texel(param_6);\n        int param_7 = _1673 + 2;\n        float4 _1703 = fa_light_texel(param_7);\n        float3 _1706 = _1693.xyz;\n        float _1711 = dot(_1706, world_pos) + _1693.w;\n        float3 _1713 = _1698.xyz;\n        float _1718 = dot(_1713, world_pos) + _1698.w;\n        float3 _1720 = _1703.xyz;\n        float _1725 = dot(_1720, world_pos) + _1703.w;\n        bool _1730 = abs(_1711) > 0.5f;\n        bool _1738;\n        if (!_1730)\n        {\n            _1738 = abs(_1718) > 0.5f;\n        }\n        else\n        {\n            _1738 = _1730;\n        }\n        bool _1746;\n        if (!_1738)\n        {\n            _1746 = abs(_1725) > 0.5f;\n        }\n        else\n        {\n            _1746 = _1738;\n        }\n        if (_1746)\n        {\n            continue;\n        }\n        float _1761 = clamp(dot(geo_normal, normalize(_1720)) * _1678.z, 0.0f, 1.0f);\n        if (_1761 <= 0.0f)\n        {\n            continue;\n        }\n        float _1781 = (clamp((0.5f - abs(_1725)) * 10.0f, 0.0f, 1.0f) * _1761) * _1678.x;\n        float2 _1789 = float2(_1711 + 0.5f, 0.5f - _1718);\n        float2 _1799 = float2(dot(_1706, _1595), dot(_1713, _1595));\n        float2 _1809 = float2(dot(_1706, _1598), dot(_1713, _1598));\n        int param_8 = _1673 + 5;\n        float4 _1814 = fa_light_texel(param_8);\n        int param_9 = _1673 + 3;\n        float4 _1819 = fa_light_texel(param_9);\n        int param_10 = _1673 + 4;\n        float4 _1824 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1814.xyz;\n        bool _1834 = _1819.z > _1819.x;\n        if (_1834)\n        {\n            float4 param_11 = _1819;\n            float2 param_12 = _1789;\n            float2 param_13 = _1623;\n            float2 param_14 = _1799;\n            float2 param_15 = _1809;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1633 > 0.5f) && (_1633 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1860 = fa_dc_to_linear(param_16);\n                float4 _4398 = tx;\n                _4398.x = _1860.x;\n                _4398.y = _1860.y;\n                _4398.z = _1860.z;\n                tx = _4398;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1781 * tex_a) * _1814.w, 0.0f, 1.0f).xxx);\n        if (_1824.z > _1824.x)\n        {\n            float4 param_17 = _1824;\n            float2 param_18 = _1789;\n            float2 param_19 = _1623;\n            float2 param_20 = _1799;\n            float2 param_21 = _1809;\n            float4 _1904 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1633 > 1.5f)\n            {\n                float3 param_22 = _1904.xyz;\n                float3 _1914 = fa_dc_to_srgb(param_22);\n                _1908 = _1914;\n            }\n            else\n            {\n                _1908 = _1904.xyz;\n            }\n            float3 _1923 = (_1908 * 2.0f) - 1.0f.xxx;\n            float2 _1928 = _1923.xy * _1678.y;\n            float3 _1950 = (normalize(_1706) * _1928.x) + (normalize(_1713) * _1928.y);\n            float3 _1953 = normalize(normal);\n            normal = normalize(lerp(_1953, normalize((_1953 * max(_1923.z, 0.0500000007450580596923828125f)) + (_1950 - (_1953 * dot(_1953, _1950)))), clamp(_1781 * (_1834 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_378_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3148 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3148;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_378_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _378_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_378_fa_cl_info.x) + int(_378_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_378_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _437_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _437_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _556 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _569 = (c - (ru * hx)) - p;\n        float3 _575 = ru * (2.0f * hx);\n        float _581 = max(dot(_575, _575), 9.9999999392252902907785028219223e-09f);\n        float _585 = dot(_569, _575);\n        float t = clamp((-_585) / _581, 0.0f, 1.0f);\n        if (_556)\n        {\n            float _600 = dot(r, _575);\n            float _606 = _581 - (_600 * _600);\n            if (abs(_606) > (9.9999997473787516355514526367188e-06f * _581))\n            {\n                t = clamp(((dot(r, _569) * _600) - _585) / _606, 0.0f, 1.0f);\n            }\n        }\n        return (p + _569) + (_575 * t);\n    }\n    float3 q = p;\n    float _638 = dot(r, axis);\n    bool _646;\n    if (_556)\n    {\n        _646 = abs(_638) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _646 = _556;\n    }\n    if (_646)\n    {\n        float _656 = dot(c - p, axis) / _638;\n        if (_656 > 0.0f)\n        {\n            q = p + (r * _656);\n        }\n    }\n    float3 _669 = q - c;\n    float2 xy = float2(dot(_669, ru), dot(_669, uu));\n    if (shape > 0.5f)\n    {\n        float _684 = length(xy);\n        if (_684 > hx)\n        {\n            xy *= (hx / _684);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _327 = abs(d);\n    float _329 = _327.x;\n    float _331 = _327.y;\n    bool _332 = _329 >= _331;\n    bool _340;\n    if (_332)\n    {\n        _340 = _329 >= _327.z;\n    }\n    else\n    {\n        _340 = _332;\n    }\n    int _341;\n    if (_340)\n    {\n        _341 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _356;\n        if (_331 >= _327.z)\n        {\n            _356 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _356 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _341 = _356;\n    }\n    return _341;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _476 = dot(d, right);\n    float _480 = dot(d, up);\n    float _491;\n    if (((_476 * _476) + (_480 * _480)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _491 = atan2(_480, _476) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _491 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_491 - floor(_491)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _722 = fa_light_base(param);\n    bool _726 = _378_fa_ambient.w > 4.5f;\n    int param_1 = _722;\n    float4 _730 = fa_light_texel(param_1);\n    int param_2 = _722 + 1;\n    float4 _735 = fa_light_texel(param_2);\n    float _738 = _735.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _750 = _726 && (_738 > 2.5f);\n    fa_light_is_area = _750;\n    bool _752 = _738 < 0.5f;\n    float3 l;\n    if (_752)\n    {\n        l = normalize(_730.xyz);\n        if (_726)\n        {\n            int param_3 = _722 + 6;\n            float4 _766 = fa_light_texel(param_3);\n            if (_766.z > 0.5f)\n            {\n                int param_4 = _722 + 4;\n                float4 _776 = fa_light_texel(param_4);\n                int param_5 = _722 + 5;\n                float4 _781 = fa_light_texel(param_5);\n                float2 param_6 = _766.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _776.xyz) * _776.w, (-dot(world_pos, _781.xyz)) * _781.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _811 = _730.xyz;\n        float3 _813 = _811 - world_pos;\n        float3 to_light = _813;\n        float _816 = length(_813);\n        float reach = _816;\n        bool front = true;\n        if (_750)\n        {\n            int param_8 = _722 + 7;\n            reach = max(_816 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _722 + 4;\n            float4 _840 = fa_light_texel(param_9);\n            int param_10 = _722 + 5;\n            float4 _845 = fa_light_texel(param_10);\n            int param_11 = _722 + 6;\n            float4 _850 = fa_light_texel(param_11);\n            float _851 = _850.w;\n            int param_12 = _722 + 2;\n            float3 _858 = normalize(fa_light_texel(param_12).xyz);\n            bool _860 = _851 > 1.5f;\n            bool _868;\n            if (!_860)\n            {\n                _868 = dot(_858, to_light) < 0.0f;\n            }\n            else\n            {\n                _868 = _860;\n            }\n            front = _868;\n            float3 r = 0.0f.xxx;\n            float3 _877 = _378_fa_camera_pos.xyz - world_pos;\n            bool _881 = dot(n, n) > 0.5f;\n            bool _889;\n            if (_881)\n            {\n                _889 = dot(_877, _877) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _889 = _881;\n            }\n            if (_889)\n            {\n                r = reflect(-normalize(_877), normalize(n));\n            }\n            float3 param_13 = _811;\n            float3 param_14 = _858;\n            float3 param_15 = _840.xyz;\n            float3 param_16 = _845.xyz;\n            float param_17 = _840.w;\n            float param_18 = _845.w;\n            float param_19 = _851;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _925 = length(to_light);\n        dist = _925;\n        l = to_light / max(_925, 9.9999997473787516355514526367188e-05f).xxx;\n        float _939 = reach / max(_730.w, 0.001000000047497451305389404296875f);\n        float _945 = clamp(1.0f - (_939 * _939), 0.0f, 1.0f);\n        float _947;\n        if (front)\n        {\n            _947 = _945 * _945;\n        }\n        else\n        {\n            _947 = 0.0f;\n        }\n        atten = _947;\n        bool _958 = _738 < 2.5f;\n        if ((_738 > 1.5f) && _958)\n        {\n            int param_22 = _722 + 2;\n            float4 _966 = fa_light_texel(param_22);\n            float _976 = _966.w;\n            int param_23 = _722 + 3;\n            float4 _981 = fa_light_texel(param_23);\n            float _982 = _981.x;\n            float cos_inner = _982;\n            if (_982 > 1.5f)\n            {\n                cos_inner = lerp(_976, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_976, cos_inner, dot(-l, normalize(_966.xyz)));\n        }\n        if (_726 && (_738 < 1.5f))\n        {\n            int param_24 = _722 + 6;\n            float4 _1006 = fa_light_texel(param_24);\n            if (_1006.z > 0.5f)\n            {\n                float3 _1014 = -to_light;\n                int param_25 = _722 + 4;\n                int param_26 = _722 + 5;\n                float3 _1028 = fa_light_texel(param_25).xyz;\n                float3 _1032 = fa_light_texel(param_26).xyz;\n                float3 _1041 = float3(dot(_1014, _1028), dot(_1014, _1032), dot(_1014, cross(_1028, _1032)));\n                float3 param_27 = _1041;\n                int _1045 = fa_cube_face(param_27);\n                int param_28 = _1045;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1072 = float2(dot(_1041, cross(param_29, param_30)), dot(_1041, param_30)) / max(dot(_1041, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1076 = _1045 / 3;\n                float2 param_31 = _1006.xy + (float2(float(_1045 - (_1076 * 3)), float(_1076)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1072.x), 0.5f - (0.5f * _1072.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _722 + 7;\n            float4 _1106 = fa_light_texel(param_33);\n            if (_1106.z > 0.5f)\n            {\n                int param_34 = _722 + 2;\n                int param_35 = _722 + 4;\n                int param_36 = _722 + 5;\n                float2 param_37 = _1106.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_726 && _958)\n            {\n                int param_42 = _722 + 6;\n                float4 _1153 = fa_light_texel(param_42);\n                int param_43 = _722 + 7;\n                float4 _1158 = fa_light_texel(param_43);\n                bool _1161 = _1153.z > 0.5f;\n                bool _1168;\n                if (!_1161)\n                {\n                    _1168 = _1158.z > 0.5f;\n                }\n                else\n                {\n                    _1168 = _1161;\n                }\n                if (_1168)\n                {\n                    int param_44 = _722 + 2;\n                    float4 _1175 = fa_light_texel(param_44);\n                    float3 _1179 = normalize(_1175.xyz);\n                    int param_45 = _722 + 4;\n                    float4 _1184 = fa_light_texel(param_45);\n                    int param_46 = _722 + 5;\n                    float4 _1189 = fa_light_texel(param_46);\n                    if (_1161)\n                    {\n                        float3 _1197 = -to_light;\n                        float _1204 = _1175.w;\n                        float _1220 = 0.5f / max(dot(_1197, _1179) * (sqrt(max(1.0f - (_1204 * _1204), 0.0f)) / max(_1204, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1153.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1197, _1184.xyz) * _1220), 0.5f - (dot(_1197, _1189.xyz) * _1220));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1158.z > 0.5f)\n                    {\n                        float2 param_49 = _1158.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1179;\n                        float3 param_52 = _1184.xyz;\n                        float3 param_53 = _1189.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4272 = _735.xyz * atten;\n    if (_726)\n    {\n        _4272 *= fa_light_tint;\n    }\n    int _1288;\n    if (_752)\n    {\n        _1288 = 0;\n    }\n    else\n    {\n        _1288 = ((_738 > 1.5f) && (_738 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4283 = { l, _4272, atten, 1.0f, dist, _1288 };\n    return _4283;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2025;\n    if (i == 0)\n    {\n        _2025 = _2035_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2041;\n        if (i == 1)\n        {\n            _2041 = _2035_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2049;\n            if (i == 2)\n            {\n                _2049 = _2035_fa_shadow_split.z;\n            }\n            else\n            {\n                _2049 = _2035_fa_shadow_split.w;\n            }\n            _2041 = _2049;\n        }\n        _2025 = _2041;\n    }\n    return _2025;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2082 = fa_shadow_depth(param, param_1);\n    float _2086;\n    if (conv.x < 0.5f)\n    {\n        _2086 = _2082;\n    }\n    else\n    {\n        _2086 = (conv.y * conv.z) / (conv.z - (_2082 * (conv.z - conv.y)));\n    }\n    return _2086;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2013 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2013), sin(_2013)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2132 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2141;\n        if (k < 0.0f)\n        {\n            _2141 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2141 = k;\n        }\n        float _2161 = clamp((_2141 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2132;\n            float2 _2180 = fa_shadow_vogel(param_3, param_4, param_5) * _2161;\n            float2 param_6 = uv + (_2180 * _2035_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2192 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2192 < (zr - (length(_2180) * plane)))\n            {\n                sum += _2192;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2218 = sum / cnt;\n        float _2228;\n        if (k < 0.0f)\n        {\n            _2228 = (-k) / max(_2218, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2228 = k;\n        }\n        radius = clamp(((max(zr - _2218, 0.0f) * unit) * _2228) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2250 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2250; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2250;\n        float param_11 = _2132;\n        float2 _2269 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2269 * _2035_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2269) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2250);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2311 = max(_2035_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2316 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2322 = sqrt(1.0f - (_2316 * _2316));\n    float _2329 = min(_2322 / max(_2316, 0.20000000298023223876953125f), 4.0f);\n    float _2334;\n    if (_2035_fa_shadow_bias.y > 0.0f)\n    {\n        _2334 = _2035_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2334 = 1.5f * _2035_fa_shadow_info[ci].x;\n    }\n    float4 _2359 = mul(float4(world + (n * (_2334 * _2322)), 1.0f), _2035_fa_shadow_mat[ci]);\n    float _2366 = _2359.x;\n    bool _2369 = _2366 < _2035_fa_shadow_rect[ci].x;\n    bool _2378;\n    if (!_2369)\n    {\n        _2378 = _2366 > _2035_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2378 = _2369;\n    }\n    bool _2387;\n    if (!_2378)\n    {\n        _2387 = _2359.y < _2035_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2387 = _2378;\n    }\n    bool _2396;\n    if (!_2387)\n    {\n        _2396 = _2359.y > _2035_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2396 = _2387;\n    }\n    bool _2403;\n    if (!_2396)\n    {\n        _2403 = _2359.z > 1.0f;\n    }\n    else\n    {\n        _2403 = _2396;\n    }\n    if (_2403)\n    {\n        return -1.0f;\n    }\n    float _2411;\n    if (_2035_fa_shadow_bias.x > 0.0f)\n    {\n        _2411 = _2035_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2411 = 1.5f * _2035_fa_shadow_info[ci].x;\n    }\n    float2 param = _2359.xy;\n    float4 param_1 = _2035_fa_shadow_rect[ci];\n    float param_2 = _2359.z - ((_2411 * (1.0f + (0.5f * _2329))) / _2311);\n    float param_3 = _2035_fa_shadow_info[ci].x;\n    float param_4 = _2311;\n    float param_5 = _2311 * 0.25f;\n    float param_6 = ((_2035_fa_shadow_info[ci].x * min(_2329, 3.0f)) * 0.5f) / _2311;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2035_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2035_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_378_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2789 = int(_2035_fa_shadow_cfg.x + 0.5f);\n    if (_2789 < 1)\n    {\n        return 1.0f;\n    }\n    float _2804 = dot(world - _2035_fa_shadow_eye.xyz, _2035_fa_shadow_fwd.xyz);\n    int param = _2789 - 1;\n    if (_2804 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2816 = _2789 > 1;\n    bool _2823;\n    if (_2816)\n    {\n        _2823 = _2804 > _2035_fa_shadow_split.x;\n    }\n    else\n    {\n        _2823 = _2816;\n    }\n    if (_2823)\n    {\n        ci = 1;\n    }\n    bool _2827 = _2789 > 2;\n    bool _2834;\n    if (_2827)\n    {\n        _2834 = _2804 > _2035_fa_shadow_split.y;\n    }\n    else\n    {\n        _2834 = _2827;\n    }\n    if (_2834)\n    {\n        ci = 2;\n    }\n    bool _2838 = _2789 > 3;\n    bool _2845;\n    if (_2838)\n    {\n        _2845 = _2804 > _2035_fa_shadow_split.z;\n    }\n    else\n    {\n        _2845 = _2838;\n    }\n    if (_2845)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2789)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2871 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2871;\n        if (_2871 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2035_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2896;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2896 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2896 = _2035_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2915 = _2035_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2896, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2926 = clamp((_2804 - (fa_shadow_split_at(param_7) - _2915)) / _2915, 0.0f, 1.0f);\n        if (_2926 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2789)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2947 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2947;\n                if (_2947 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2926);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2469 = _378_fa_pbr.z < 0.5f;\n    bool _2476;\n    if (!_2469)\n    {\n        _2476 = _2035_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2476 = _2469;\n    }\n    if (_2476)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2035_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2489 = fa_light_texel(param);\n    float _2490 = _2489.x;\n    if (_2490 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2499 = int(_2490 + 0.5f);\n    int param_1 = _2499;\n    float4 _2503 = fa_light_texel(param_1);\n    int param_2 = _2499 + 1;\n    float4 _2508 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2511 = _2503.y;\n    if (_2511 > 0.0f)\n    {\n        float _2528 = 1.0f - smoothstep(0.75f * _2511, _2511, length(world - _2035_fa_shadow_eye.xyz));\n        fade = _2528;\n        if (_2528 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2503.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2552 = (_2499 + 2) + (face * 6);\n    int param_4 = _2552;\n    int param_5 = _2552 + 1;\n    int param_6 = _2552 + 3;\n    float4 _2566 = fa_light_texel(param_6);\n    int param_7 = _2552 + 4;\n    float4 _2571 = fa_light_texel(param_7);\n    int param_8 = _2552 + 5;\n    float4 _2576 = fa_light_texel(param_8);\n    float _2588 = _2576.x * max(dot(_2566, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2593 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2616 = clamp(dot(n, _2566.xyz), -1.0f, 1.0f);\n    float _2635 = min(sqrt(1.0f - (_2616 * _2616)) / max(abs(dot(n, world - lpos)) / max(dot(_2566, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2638 = _2508.y;\n    float _2640;\n    if (_2638 > 0.0f)\n    {\n        _2640 = _2638;\n    }\n    else\n    {\n        _2640 = 1.5f * _2588;\n    }\n    float4 _2660 = float4(world + (n * (_2640 * sqrt(1.0f - (_2593 * _2593)))), 1.0f);\n    float _2664 = dot(_2566, _2660);\n    float _2667 = _2576.y;\n    if (_2664 < _2667)\n    {\n        return 1.0f;\n    }\n    float2 _2682 = float2(dot(fa_light_texel(param_4), _2660), dot(fa_light_texel(param_5), _2660)) / _2664.xx;\n    float _2684 = _2682.x;\n    bool _2687 = _2684 < _2571.x;\n    bool _2696;\n    if (!_2687)\n    {\n        _2696 = _2684 > _2571.z;\n    }\n    else\n    {\n        _2696 = _2687;\n    }\n    bool _2705;\n    if (!_2696)\n    {\n        _2705 = _2682.y < _2571.y;\n    }\n    else\n    {\n        _2705 = _2696;\n    }\n    bool _2714;\n    if (!_2705)\n    {\n        _2714 = _2682.y > _2571.w;\n    }\n    else\n    {\n        _2714 = _2705;\n    }\n    if (_2714)\n    {\n        return 1.0f;\n    }\n    float _2720 = _2508.x;\n    float _2722;\n    if (_2720 > 0.0f)\n    {\n        _2722 = _2720;\n    }\n    else\n    {\n        _2722 = 1.5f * _2588;\n    }\n    float2 param_9 = _2682;\n    float4 param_10 = _2571;\n    float param_11 = _2664 - (_2722 * (1.0f + (0.5f * _2635)));\n    float param_12 = _2588;\n    float param_13 = 1.0f;\n    float param_14 = _2576.z * 0.25f;\n    float param_15 = (_2588 * min(_2635, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2667, _2576.z);\n    int param_17 = int(_2503.z + 0.5f);\n    float param_18 = _2503.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3262 = fa_lm.z > 0.5f;\n    bool _3268;\n    if (_3262)\n    {\n        int param = li;\n        _3268 = fa_light_baked(param);\n    }\n    else\n    {\n        _3268 = _3262;\n    }\n    if (_3268)\n    {\n        int param_1 = li;\n        LightSample _4296 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4296;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3292 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _4298 = _3292.color;\n    float _4300 = _3292.shadow;\n    if ((_3292.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3292.direction;\n        float _3306 = fa_shadow_factor(param_5, param_6);\n        _4300 = _3306;\n        _4298 *= _3306;\n    }\n    else\n    {\n        bool _3317 = _3292.type != 0;\n        bool _3323;\n        if (_3317)\n        {\n            _3323 = _3292.attenuation > 0.0f;\n        }\n        else\n        {\n            _3323 = _3317;\n        }\n        if (_3323)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3292.direction;\n            float _3342 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4300 = _3342;\n            _4298 *= _3342;\n        }\n    }\n    LightSample _4315 = { _3292.direction, _4298, _3292.attenuation, _4300, _3292._distance, _3292.type };\n    return _4315;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2035_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2971 = int(_2035_fa_shadow_cfg.x + 0.5f);\n    float _2981 = dot(world - _2035_fa_shadow_eye.xyz, _2035_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2986 = _2971 > 0;\n    bool _2995;\n    if (_2986)\n    {\n        int param = _2971 - 1;\n        _2995 = _2981 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2995 = _2986;\n    }\n    if (_2995)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3001 = _2971 > 1;\n        bool _3008;\n        if (_3001)\n        {\n            _3008 = _2981 > _2035_fa_shadow_split.x;\n        }\n        else\n        {\n            _3008 = _3001;\n        }\n        if (_3008)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3014 = _2971 > 2;\n        bool _3021;\n        if (_3014)\n        {\n            _3021 = _2981 > _2035_fa_shadow_split.y;\n        }\n        else\n        {\n            _3021 = _3014;\n        }\n        if (_3021)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3027 = _2971 > 3;\n        bool _3034;\n        if (_3027)\n        {\n            _3034 = _2981 > _2035_fa_shadow_split.z;\n        }\n        else\n        {\n            _3034 = _3027;\n        }\n        if (_3034)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4139 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4139 = -_4139;\n    }\n    float3 _3724 = normalize(_378_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4152 = { fa_world_pos, _4139, fa_world_tangent, fa_uv, fa_vertex_color, _3724, gl_FrontFacing };\n    SurfaceInput param_1 = _4152;\n    Surface _3732 = fa_standard_surface(param_1);\n    float3 _4170 = _3732.albedo;\n    float _4171 = _3732.alpha;\n    float3 _4172 = _3732.normal;\n    float _4173 = _3732.metallic;\n    float _4174 = _3732.roughness;\n    float _4175 = _3732.occlusion;\n    float3 _4176 = _3732.emission;\n    float _4177 = _3732.clearcoat;\n    float _4178 = _3732.clearcoat_roughness;\n    float3 _4179 = _3732.sheen_color;\n    float _4180 = _3732.sheen_roughness;\n    float _4181 = _3732.anisotropy;\n    float _4182 = _3732.anisotropy_rotation;\n    float _4183 = _3732.specular;\n    float _4184 = _3732.ior;\n    float3 _4185 = _3732.specular_color;\n    SurfaceInput _4160 = { fa_world_pos, _4139, fa_world_tangent, fa_uv, fa_vertex_color, _3724, gl_FrontFacing };\n    SurfaceInput param_2 = _4160;\n    Surface param_3 = _3732;\n    surface(param_2, param_3);\n    _4170 = param_3.albedo;\n    _4171 = param_3.alpha;\n    _4172 = param_3.normal;\n    _4173 = param_3.metallic;\n    _4174 = param_3.roughness;\n    _4175 = param_3.occlusion;\n    _4176 = param_3.emission;\n    _4177 = param_3.clearcoat;\n    _4178 = param_3.clearcoat_roughness;\n    _4179 = param_3.sheen_color;\n    _4180 = param_3.sheen_roughness;\n    _4181 = param_3.anisotropy;\n    _4182 = param_3.anisotropy_rotation;\n    _4183 = param_3.specular;\n    _4184 = param_3.ior;\n    _4185 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4139;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4170 = param_6;\n    _4172 = param_7;\n    float3 result;\n    if (_378_fa_emissive.w > 0.5f)\n    {\n        result = _4170;\n    }\n    else\n    {\n        float3 _3770 = _4172;\n        float3 _3771 = normalize(_3770);\n        _4172 = _3771;\n        float3 param_8 = _3771;\n        float3 lit = (fa_indirect_diffuse(param_8) * _4170) * _4175;\n        int _3790 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3790; ln++)\n        {\n            int param_9 = ln;\n            int _3803 = fa_cl_light(param_9);\n            bool _3806 = fa_lm.z > 0.5f;\n            bool _3812;\n            if (_3806)\n            {\n                int param_10 = _3803;\n                _3812 = fa_light_baked(param_10);\n            }\n            else\n            {\n                _3812 = _3806;\n            }\n            if (_3812)\n            {\n                continue;\n            }\n            int param_11 = _3803;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _4139;\n            LightSample _3824 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput _4168 = { fa_world_pos, _4139, fa_world_tangent, fa_uv, fa_vertex_color, _3724, gl_FrontFacing };\n            SurfaceInput param_14 = _4168;\n            Surface _4251 = { _4170, _4171, _4172, _4173, _4174, _4175, _4176, _4177, _4178, _4179, _4180, _4181, _4182, _4183, _4184, _4185 };\n            Surface param_15 = _4251;\n            LightSample param_16 = _3824;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _3839 = result;\n    float3 _3840 = _3839 + _4176;\n    result = _3840;\n    float3 param_17 = _3840;\n    float3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _3849 = _378_fa_fog.w > 0.0f;\n    bool _3856;\n    if (!_3849)\n    {\n        _3856 = _378_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3856 = _3849;\n    }\n    if (_3856)\n    {\n        float3 _3865 = fa_world_pos - _378_fa_camera_pos.xyz;\n        float _3871 = dot(_3865, _378_fa_fog_c.xyz);\n        bool _3875 = _378_fa_fog_c.w > 0.5f;\n        float _3876;\n        if (_3875)\n        {\n            _3876 = _3871;\n        }\n        else\n        {\n            _3876 = length(_3865);\n        }\n        float _3888 = _3876 - _378_fa_fog_b.x;\n        if (_3888 > 0.0f)\n        {\n            float _3897 = _378_fa_fog.w * _3888;\n            float tau = _3897 * _3897;\n            if (_378_fa_fog_b.y > 0.0f)\n            {\n                float _3913;\n                if (_3875)\n                {\n                    _3913 = fa_world_pos.y - (_378_fa_fog_c.y * _3871);\n                }\n                else\n                {\n                    _3913 = _378_fa_camera_pos.y;\n                }\n                float _3934 = lerp(_3913, fa_world_pos.y, clamp(_378_fa_fog_b.x / _3876, 0.0f, 1.0f));\n                float _3938 = fa_world_pos.y - _3934;\n                float _3943 = _3934 - _378_fa_fog_b.z;\n                float _3948 = fa_world_pos.y - _378_fa_fog_b.z;\n                bool _3951 = _3943 <= 0.0f;\n                bool _3952 = !_3951;\n                bool _3958;\n                if (_3952)\n                {\n                    _3958 = _378_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3958 = _3951;\n                }\n                float _3959;\n                if (_3958)\n                {\n                    _3959 = _378_fa_fog_b.y;\n                }\n                else\n                {\n                    _3959 = _378_fa_fog_b.y * exp(-min(_378_fa_fog_b.w * _3943, 80.0f));\n                }\n                bool _3986;\n                if (_3952)\n                {\n                    _3986 = _378_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3986 = _3951;\n                }\n                float _3987;\n                if (_3986)\n                {\n                    _3987 = _378_fa_fog_b.y * _3943;\n                }\n                else\n                {\n                    _3987 = (_378_fa_fog_b.y * (1.0f - exp(-min(_378_fa_fog_b.w * _3943, 80.0f)))) / _378_fa_fog_b.w;\n                }\n                bool _4012 = _3948 <= 0.0f;\n                bool _4019;\n                if (!_4012)\n                {\n                    _4019 = _378_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4019 = _4012;\n                }\n                float _4020;\n                if (_4019)\n                {\n                    _4020 = _378_fa_fog_b.y * _3948;\n                }\n                else\n                {\n                    _4020 = (_378_fa_fog_b.y * (1.0f - exp(-min(_378_fa_fog_b.w * _3948, 80.0f)))) / _378_fa_fog_b.w;\n                }\n                float _4047;\n                if (abs(_3938) < 0.001000000047497451305389404296875f)\n                {\n                    _4047 = _3959;\n                }\n                else\n                {\n                    _4047 = (_4020 - _3987) / _3938;\n                }\n                tau += (_3888 * max(_4047, 0.0f));\n            }\n            result = lerp(result, _378_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4171);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_378",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2035",
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _381 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _381;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_388, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _378_fa_camera_pos : packoffset(c0);\n    float4 _378_fa_ambient : packoffset(c1);\n    float4 _378_fa_base_color : packoffset(c2);\n    float4 _378_fa_emissive : packoffset(c3);\n    float4 _378_fa_model_emissive : packoffset(c4);\n    float4 _378_fa_pbr : packoffset(c5);\n    float4 _378_fa_maps : packoffset(c6);\n    float4 _378_fa_fog : packoffset(c7);\n    float4 _378_fa_fog_b : packoffset(c8);\n    float4 _378_fa_fog_c : packoffset(c9);\n    float4 _378_fa_counts : packoffset(c10);\n    float4 _378_fa_env_sky : packoffset(c11);\n    float4 _378_fa_env_horizon : packoffset(c12);\n    float4 _378_fa_time : packoffset(c13);\n    float4 _378_fa_cl_vpx : packoffset(c14);\n    float4 _378_fa_cl_vpy : packoffset(c15);\n    float4 _378_fa_cl_vpw : packoffset(c16);\n    float4 _378_fa_cl_fwd : packoffset(c17);\n    float4 _378_fa_cl_grid : packoffset(c18);\n    float4 _378_fa_cl_info : packoffset(c19);\n    float4 _378_fa_layers_a : packoffset(c20);\n    float4 _378_fa_layers_b : packoffset(c21);\n    float4 _378_fa_layers_c : packoffset(c22);\n    float4 _378_fa_layers_d : packoffset(c23);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2035_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2035_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2035_fa_shadow_info[4] : packoffset(c20);\n    float4 _2035_fa_shadow_split : packoffset(c24);\n    float4 _2035_fa_shadow_cfg : packoffset(c25);\n    float4 _2035_fa_shadow_bias : packoffset(c26);\n    float4 _2035_fa_shadow_eye : packoffset(c27);\n    float4 _2035_fa_shadow_fwd : packoffset(c28);\n    float4 _2035_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1306 = _378_fa_cl_info.x < 0.0f;\n    bool _1313;\n    if (!_1306)\n    {\n        _1313 = _378_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1313 = _1306;\n    }\n    bool _1321;\n    if (!_1313)\n    {\n        _1321 = _378_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1321 = _1313;\n    }\n    bool _1328;\n    if (!_1321)\n    {\n        _1328 = _378_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1328 = _1321;\n    }\n    bool _1335;\n    if (!_1328)\n    {\n        _1335 = _378_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1335 = _1328;\n    }\n    if (_1335)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1345 = float4(world_pos, 1.0f);\n    float _1351 = dot(_378_fa_cl_vpw, _1345);\n    if (!(_1351 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1373 = float2(dot(_378_fa_cl_vpx, _1345), dot(_378_fa_cl_vpy, _1345)) / _1351.xx;\n    int _1377 = int(_378_fa_cl_grid.x);\n    int _1381 = int(_378_fa_cl_grid.y);\n    int param = (int(_378_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_378_fa_cl_fwd.xyz, world_pos) + _378_fa_cl_fwd.w, _378_fa_cl_grid.w) / _378_fa_cl_grid.w) * _378_fa_cl_grid.z)), 0, int(_378_fa_cl_info.y) - 1) * _1381) + clamp(int(floor(((_1373.y * 0.5f) + 0.5f) * _378_fa_cl_grid.y)), 0, _1381 - 1)) * _1377)) + clamp(int(floor(((_1373.x * 0.5f) + 0.5f) * _378_fa_cl_grid.x)), 0, _1377 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1457 = fa_cluster_texel(param);\n    return int2(int(_1457.x), int(_1457.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_378_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3235 = fa_cluster_lookup(param);\n    fa_cl_slot = _3235.x;\n    fa_cl_local = _3235.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3391 = fa_linear_to_srgb(param);\n        c = _3391;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3399 = fa_srgb_to_linear(param_1);\n            c = _3399;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _261;\n    if (i.front_facing)\n    {\n        _261 = i.world_normal;\n    }\n    else\n    {\n        _261 = -i.world_normal;\n    }\n    float3 _285 = normalize(i.world_tangent.xyz - (_261 * dot(_261, i.world_tangent.xyz)));\n    float3 _312 = normalize(((_285 * m.x) + ((cross(_261, _285) * i.world_tangent.w) * m.y)) + (_261 * m.z));\n    float3 _315;\n    if (i.front_facing)\n    {\n        _315 = _312;\n    }\n    else\n    {\n        _315 = -_312;\n    }\n    return _315;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _378_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3430 = fa_tex_fix(param_2, param_3);\n    float4 _4453 = base_t;\n    _4453.x = _3430.x;\n    _4453.y = _3430.y;\n    _4453.z = _3430.z;\n    base_t = _4453;\n    float4 _3444 = (_4453 * _378_fa_base_color) * i.vertex_color;\n    float3 _4318 = i.world_normal;\n    if (_378_fa_maps.z > 0.5f)\n    {\n        float param_4 = _378_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3476 = fa_tex_fix(param_6, param_7);\n        float3 _3479 = (_3476 * 2.0f) - 1.0f.xxx;\n        float2 _3484 = _3479.xy * _378_fa_maps.x;\n        float3 _4461 = _3479;\n        _4461.x = _3484.x;\n        _4461.y = _3484.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4461;\n        _4318 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _378_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3512 = fa_tex_fix(param_12, param_13);\n    float4 _4464 = mrt;\n    _4464.x = _3512.x;\n    _4464.y = _3512.y;\n    _4464.z = _3512.z;\n    mrt = _4464;\n    float4 _3540 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _378_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3540.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3551 = fa_tex_fix(param_16, param_17);\n    float param_18 = _378_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3581 = fa_tex_fix(param_20, param_21);\n    float _4323 = _378_fa_layers_a.x;\n    float _4324 = _378_fa_layers_a.y;\n    float _4327 = _378_fa_layers_a.z;\n    float _4326 = _378_fa_layers_b.w;\n    float _4329 = _378_fa_layers_c.x;\n    if (_378_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_378_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4323 *= _3551.y;\n            _4324 *= _3551.z;\n            _4326 *= _3540.w;\n        }\n        if (_378_fa_layers_c.z > 1.5f)\n        {\n            _4327 *= mrt.x;\n            _4329 *= mrt.w;\n        }\n    }\n    Surface _4348 = { _3444.xyz, _3444.w, _4318, clamp(_378_fa_pbr.x * _3512.z, 0.0f, 1.0f), clamp(_378_fa_pbr.y * _3512.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_378_fa_maps.y * (_3551.x - 1.0f)), _378_fa_emissive.xyz + (_378_fa_model_emissive.xyz * _3581), _4323, _4324, _378_fa_layers_b.xyz, _4326, _4327, _378_fa_layers_a.w, _4329, _378_fa_layers_c.y, _378_fa_layers_d.xyz };\n    return _4348;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1537 = rect.zw - rect.xy;\n    float2 _1541 = _1537 * atlas;\n    float2 _1545 = ddx * _1541;\n    float2 _1549 = ddy * _1541;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1537), clamp(0.5f * log2(max(max(dot(_1545, _1545), dot(_1549, _1549)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1582 = _378_fa_counts.y < 0.5f;\n    bool _1589;\n    if (!_1582)\n    {\n        _1589 = _378_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1589 = _1582;\n    }\n    if (_1589)\n    {\n        return;\n    }\n    float3 _1595 = ddx(world_pos);\n    float3 _1598 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1602 = fa_cluster_texel(param);\n    int _1606 = int(_1602.w);\n    if (_1606 < 1)\n    {\n        return;\n    }\n    int _1616 = int(_378_fa_counts.y + 0.5f);\n    int param_1 = _1616;\n    float4 _1620 = fa_light_texel(param_1);\n    float2 _1623 = _1620.yz;\n    int _1627 = int(_1620.w);\n    int param_2 = _1616 + 1;\n    float4 _1632 = fa_light_texel(param_2);\n    float _1633 = _1632.x;\n    int _1639 = int(_378_fa_counts.w + 0.5f) - 1;\n    int _1643 = int(_1602.z);\n    float3 _1908;\n    for (int k = 0; k < _1606; k++)\n    {\n        int _1656 = _1643 + k;\n        int param_3 = _1627 + (_1656 >> 2);\n        int _1673 = (_1616 + 2) + (int(fa_light_texel(param_3)[_1656 & 3]) * 7);\n        int param_4 = _1673 + 6;\n        float4 _1678 = fa_light_texel(param_4);\n        if (((int(_1678.w + 0.5f) >> _1639) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1673;\n        float4 _1693 = fa_light_texel(param_5);\n        int param_6 = _1673 + 1;\n        float4 _1698 = fa_light_texel(param_6);\n        int param_7 = _1673 + 2;\n        float4 _1703 = fa_light_texel(param_7);\n        float3 _1706 = _1693.xyz;\n        float _1711 = dot(_1706, world_pos) + _1693.w;\n        float3 _1713 = _1698.xyz;\n        float _1718 = dot(_1713, world_pos) + _1698.w;\n        float3 _1720 = _1703.xyz;\n        float _1725 = dot(_1720, world_pos) + _1703.w;\n        bool _1730 = abs(_1711) > 0.5f;\n        bool _1738;\n        if (!_1730)\n        {\n            _1738 = abs(_1718) > 0.5f;\n        }\n        else\n        {\n            _1738 = _1730;\n        }\n        bool _1746;\n        if (!_1738)\n        {\n            _1746 = abs(_1725) > 0.5f;\n        }\n        else\n        {\n            _1746 = _1738;\n        }\n        if (_1746)\n        {\n            continue;\n        }\n        float _1761 = clamp(dot(geo_normal, normalize(_1720)) * _1678.z, 0.0f, 1.0f);\n        if (_1761 <= 0.0f)\n        {\n            continue;\n        }\n        float _1781 = (clamp((0.5f - abs(_1725)) * 10.0f, 0.0f, 1.0f) * _1761) * _1678.x;\n        float2 _1789 = float2(_1711 + 0.5f, 0.5f - _1718);\n        float2 _1799 = float2(dot(_1706, _1595), dot(_1713, _1595));\n        float2 _1809 = float2(dot(_1706, _1598), dot(_1713, _1598));\n        int param_8 = _1673 + 5;\n        float4 _1814 = fa_light_texel(param_8);\n        int param_9 = _1673 + 3;\n        float4 _1819 = fa_light_texel(param_9);\n        int param_10 = _1673 + 4;\n        float4 _1824 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1814.xyz;\n        bool _1834 = _1819.z > _1819.x;\n        if (_1834)\n        {\n            float4 param_11 = _1819;\n            float2 param_12 = _1789;\n            float2 param_13 = _1623;\n            float2 param_14 = _1799;\n            float2 param_15 = _1809;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1633 > 0.5f) && (_1633 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1860 = fa_dc_to_linear(param_16);\n                float4 _4398 = tx;\n                _4398.x = _1860.x;\n                _4398.y = _1860.y;\n                _4398.z = _1860.z;\n                tx = _4398;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1781 * tex_a) * _1814.w, 0.0f, 1.0f).xxx);\n        if (_1824.z > _1824.x)\n        {\n            float4 param_17 = _1824;\n            float2 param_18 = _1789;\n            float2 param_19 = _1623;\n            float2 param_20 = _1799;\n            float2 param_21 = _1809;\n            float4 _1904 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1633 > 1.5f)\n            {\n                float3 param_22 = _1904.xyz;\n                float3 _1914 = fa_dc_to_srgb(param_22);\n                _1908 = _1914;\n            }\n            else\n            {\n                _1908 = _1904.xyz;\n            }\n            float3 _1923 = (_1908 * 2.0f) - 1.0f.xxx;\n            float2 _1928 = _1923.xy * _1678.y;\n            float3 _1950 = (normalize(_1706) * _1928.x) + (normalize(_1713) * _1928.y);\n            float3 _1953 = normalize(normal);\n            normal = normalize(lerp(_1953, normalize((_1953 * max(_1923.z, 0.0500000007450580596923828125f)) + (_1950 - (_1953 * dot(_1953, _1950)))), clamp(_1781 * (_1834 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_378_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3148 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3148;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_378_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _378_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_378_fa_cl_info.x) + int(_378_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_378_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _437_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _437_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _556 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _569 = (c - (ru * hx)) - p;\n        float3 _575 = ru * (2.0f * hx);\n        float _581 = max(dot(_575, _575), 9.9999999392252902907785028219223e-09f);\n        float _585 = dot(_569, _575);\n        float t = clamp((-_585) / _581, 0.0f, 1.0f);\n        if (_556)\n        {\n            float _600 = dot(r, _575);\n            float _606 = _581 - (_600 * _600);\n            if (abs(_606) > (9.9999997473787516355514526367188e-06f * _581))\n            {\n                t = clamp(((dot(r, _569) * _600) - _585) / _606, 0.0f, 1.0f);\n            }\n        }\n        return (p + _569) + (_575 * t);\n    }\n    float3 q = p;\n    float _638 = dot(r, axis);\n    bool _646;\n    if (_556)\n    {\n        _646 = abs(_638) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _646 = _556;\n    }\n    if (_646)\n    {\n        float _656 = dot(c - p, axis) / _638;\n        if (_656 > 0.0f)\n        {\n            q = p + (r * _656);\n        }\n    }\n    float3 _669 = q - c;\n    float2 xy = float2(dot(_669, ru), dot(_669, uu));\n    if (shape > 0.5f)\n    {\n        float _684 = length(xy);\n        if (_684 > hx)\n        {\n            xy *= (hx / _684);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _327 = abs(d);\n    float _329 = _327.x;\n    float _331 = _327.y;\n    bool _332 = _329 >= _331;\n    bool _340;\n    if (_332)\n    {\n        _340 = _329 >= _327.z;\n    }\n    else\n    {\n        _340 = _332;\n    }\n    int _341;\n    if (_340)\n    {\n        _341 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _356;\n        if (_331 >= _327.z)\n        {\n            _356 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _356 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _341 = _356;\n    }\n    return _341;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _476 = dot(d, right);\n    float _480 = dot(d, up);\n    float _491;\n    if (((_476 * _476) + (_480 * _480)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _491 = atan2(_480, _476) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _491 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_491 - floor(_491)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _722 = fa_light_base(param);\n    bool _726 = _378_fa_ambient.w > 4.5f;\n    int param_1 = _722;\n    float4 _730 = fa_light_texel(param_1);\n    int param_2 = _722 + 1;\n    float4 _735 = fa_light_texel(param_2);\n    float _738 = _735.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _750 = _726 && (_738 > 2.5f);\n    fa_light_is_area = _750;\n    bool _752 = _738 < 0.5f;\n    float3 l;\n    if (_752)\n    {\n        l = normalize(_730.xyz);\n        if (_726)\n        {\n            int param_3 = _722 + 6;\n            float4 _766 = fa_light_texel(param_3);\n            if (_766.z > 0.5f)\n            {\n                int param_4 = _722 + 4;\n                float4 _776 = fa_light_texel(param_4);\n                int param_5 = _722 + 5;\n                float4 _781 = fa_light_texel(param_5);\n                float2 param_6 = _766.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _776.xyz) * _776.w, (-dot(world_pos, _781.xyz)) * _781.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _811 = _730.xyz;\n        float3 _813 = _811 - world_pos;\n        float3 to_light = _813;\n        float _816 = length(_813);\n        float reach = _816;\n        bool front = true;\n        if (_750)\n        {\n            int param_8 = _722 + 7;\n            reach = max(_816 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _722 + 4;\n            float4 _840 = fa_light_texel(param_9);\n            int param_10 = _722 + 5;\n            float4 _845 = fa_light_texel(param_10);\n            int param_11 = _722 + 6;\n            float4 _850 = fa_light_texel(param_11);\n            float _851 = _850.w;\n            int param_12 = _722 + 2;\n            float3 _858 = normalize(fa_light_texel(param_12).xyz);\n            bool _860 = _851 > 1.5f;\n            bool _868;\n            if (!_860)\n            {\n                _868 = dot(_858, to_light) < 0.0f;\n            }\n            else\n            {\n                _868 = _860;\n            }\n            front = _868;\n            float3 r = 0.0f.xxx;\n            float3 _877 = _378_fa_camera_pos.xyz - world_pos;\n            bool _881 = dot(n, n) > 0.5f;\n            bool _889;\n            if (_881)\n            {\n                _889 = dot(_877, _877) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _889 = _881;\n            }\n            if (_889)\n            {\n                r = reflect(-normalize(_877), normalize(n));\n            }\n            float3 param_13 = _811;\n            float3 param_14 = _858;\n            float3 param_15 = _840.xyz;\n            float3 param_16 = _845.xyz;\n            float param_17 = _840.w;\n            float param_18 = _845.w;\n            float param_19 = _851;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _925 = length(to_light);\n        dist = _925;\n        l = to_light / max(_925, 9.9999997473787516355514526367188e-05f).xxx;\n        float _939 = reach / max(_730.w, 0.001000000047497451305389404296875f);\n        float _945 = clamp(1.0f - (_939 * _939), 0.0f, 1.0f);\n        float _947;\n        if (front)\n        {\n            _947 = _945 * _945;\n        }\n        else\n        {\n            _947 = 0.0f;\n        }\n        atten = _947;\n        bool _958 = _738 < 2.5f;\n        if ((_738 > 1.5f) && _958)\n        {\n            int param_22 = _722 + 2;\n            float4 _966 = fa_light_texel(param_22);\n            float _976 = _966.w;\n            int param_23 = _722 + 3;\n            float4 _981 = fa_light_texel(param_23);\n            float _982 = _981.x;\n            float cos_inner = _982;\n            if (_982 > 1.5f)\n            {\n                cos_inner = lerp(_976, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_976, cos_inner, dot(-l, normalize(_966.xyz)));\n        }\n        if (_726 && (_738 < 1.5f))\n        {\n            int param_24 = _722 + 6;\n            float4 _1006 = fa_light_texel(param_24);\n            if (_1006.z > 0.5f)\n            {\n                float3 _1014 = -to_light;\n                int param_25 = _722 + 4;\n                int param_26 = _722 + 5;\n                float3 _1028 = fa_light_texel(param_25).xyz;\n                float3 _1032 = fa_light_texel(param_26).xyz;\n                float3 _1041 = float3(dot(_1014, _1028), dot(_1014, _1032), dot(_1014, cross(_1028, _1032)));\n                float3 param_27 = _1041;\n                int _1045 = fa_cube_face(param_27);\n                int param_28 = _1045;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1072 = float2(dot(_1041, cross(param_29, param_30)), dot(_1041, param_30)) / max(dot(_1041, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1076 = _1045 / 3;\n                float2 param_31 = _1006.xy + (float2(float(_1045 - (_1076 * 3)), float(_1076)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1072.x), 0.5f - (0.5f * _1072.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _722 + 7;\n            float4 _1106 = fa_light_texel(param_33);\n            if (_1106.z > 0.5f)\n            {\n                int param_34 = _722 + 2;\n                int param_35 = _722 + 4;\n                int param_36 = _722 + 5;\n                float2 param_37 = _1106.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_726 && _958)\n            {\n                int param_42 = _722 + 6;\n                float4 _1153 = fa_light_texel(param_42);\n                int param_43 = _722 + 7;\n                float4 _1158 = fa_light_texel(param_43);\n                bool _1161 = _1153.z > 0.5f;\n                bool _1168;\n                if (!_1161)\n                {\n                    _1168 = _1158.z > 0.5f;\n                }\n                else\n                {\n                    _1168 = _1161;\n                }\n                if (_1168)\n                {\n                    int param_44 = _722 + 2;\n                    float4 _1175 = fa_light_texel(param_44);\n                    float3 _1179 = normalize(_1175.xyz);\n                    int param_45 = _722 + 4;\n                    float4 _1184 = fa_light_texel(param_45);\n                    int param_46 = _722 + 5;\n                    float4 _1189 = fa_light_texel(param_46);\n                    if (_1161)\n                    {\n                        float3 _1197 = -to_light;\n                        float _1204 = _1175.w;\n                        float _1220 = 0.5f / max(dot(_1197, _1179) * (sqrt(max(1.0f - (_1204 * _1204), 0.0f)) / max(_1204, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1153.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1197, _1184.xyz) * _1220), 0.5f - (dot(_1197, _1189.xyz) * _1220));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1158.z > 0.5f)\n                    {\n                        float2 param_49 = _1158.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1179;\n                        float3 param_52 = _1184.xyz;\n                        float3 param_53 = _1189.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4272 = _735.xyz * atten;\n    if (_726)\n    {\n        _4272 *= fa_light_tint;\n    }\n    int _1288;\n    if (_752)\n    {\n        _1288 = 0;\n    }\n    else\n    {\n        _1288 = ((_738 > 1.5f) && (_738 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4283 = { l, _4272, atten, 1.0f, dist, _1288 };\n    return _4283;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2025;\n    if (i == 0)\n    {\n        _2025 = _2035_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2041;\n        if (i == 1)\n        {\n            _2041 = _2035_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2049;\n            if (i == 2)\n            {\n                _2049 = _2035_fa_shadow_split.z;\n            }\n            else\n            {\n                _2049 = _2035_fa_shadow_split.w;\n            }\n            _2041 = _2049;\n        }\n        _2025 = _2041;\n    }\n    return _2025;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2082 = fa_shadow_depth(param, param_1);\n    float _2086;\n    if (conv.x < 0.5f)\n    {\n        _2086 = _2082;\n    }\n    else\n    {\n        _2086 = (conv.y * conv.z) / (conv.z - (_2082 * (conv.z - conv.y)));\n    }\n    return _2086;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2013 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2013), sin(_2013)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2132 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2141;\n        if (k < 0.0f)\n        {\n            _2141 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2141 = k;\n        }\n        float _2161 = clamp((_2141 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2132;\n            float2 _2180 = fa_shadow_vogel(param_3, param_4, param_5) * _2161;\n            float2 param_6 = uv + (_2180 * _2035_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2192 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2192 < (zr - (length(_2180) * plane)))\n            {\n                sum += _2192;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2218 = sum / cnt;\n        float _2228;\n        if (k < 0.0f)\n        {\n            _2228 = (-k) / max(_2218, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2228 = k;\n        }\n        radius = clamp(((max(zr - _2218, 0.0f) * unit) * _2228) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2250 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2250; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2250;\n        float param_11 = _2132;\n        float2 _2269 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2269 * _2035_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2269) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2250);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2311 = max(_2035_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2316 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2322 = sqrt(1.0f - (_2316 * _2316));\n    float _2329 = min(_2322 / max(_2316, 0.20000000298023223876953125f), 4.0f);\n    float _2334;\n    if (_2035_fa_shadow_bias.y > 0.0f)\n    {\n        _2334 = _2035_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2334 = 1.5f * _2035_fa_shadow_info[ci].x;\n    }\n    float4 _2359 = mul(float4(world + (n * (_2334 * _2322)), 1.0f), _2035_fa_shadow_mat[ci]);\n    float _2366 = _2359.x;\n    bool _2369 = _2366 < _2035_fa_shadow_rect[ci].x;\n    bool _2378;\n    if (!_2369)\n    {\n        _2378 = _2366 > _2035_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2378 = _2369;\n    }\n    bool _2387;\n    if (!_2378)\n    {\n        _2387 = _2359.y < _2035_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2387 = _2378;\n    }\n    bool _2396;\n    if (!_2387)\n    {\n        _2396 = _2359.y > _2035_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2396 = _2387;\n    }\n    bool _2403;\n    if (!_2396)\n    {\n        _2403 = _2359.z > 1.0f;\n    }\n    else\n    {\n        _2403 = _2396;\n    }\n    if (_2403)\n    {\n        return -1.0f;\n    }\n    float _2411;\n    if (_2035_fa_shadow_bias.x > 0.0f)\n    {\n        _2411 = _2035_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2411 = 1.5f * _2035_fa_shadow_info[ci].x;\n    }\n    float2 param = _2359.xy;\n    float4 param_1 = _2035_fa_shadow_rect[ci];\n    float param_2 = _2359.z - ((_2411 * (1.0f + (0.5f * _2329))) / _2311);\n    float param_3 = _2035_fa_shadow_info[ci].x;\n    float param_4 = _2311;\n    float param_5 = _2311 * 0.25f;\n    float param_6 = ((_2035_fa_shadow_info[ci].x * min(_2329, 3.0f)) * 0.5f) / _2311;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2035_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2035_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_378_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2789 = int(_2035_fa_shadow_cfg.x + 0.5f);\n    if (_2789 < 1)\n    {\n        return 1.0f;\n    }\n    float _2804 = dot(world - _2035_fa_shadow_eye.xyz, _2035_fa_shadow_fwd.xyz);\n    int param = _2789 - 1;\n    if (_2804 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2816 = _2789 > 1;\n    bool _2823;\n    if (_2816)\n    {\n        _2823 = _2804 > _2035_fa_shadow_split.x;\n    }\n    else\n    {\n        _2823 = _2816;\n    }\n    if (_2823)\n    {\n        ci = 1;\n    }\n    bool _2827 = _2789 > 2;\n    bool _2834;\n    if (_2827)\n    {\n        _2834 = _2804 > _2035_fa_shadow_split.y;\n    }\n    else\n    {\n        _2834 = _2827;\n    }\n    if (_2834)\n    {\n        ci = 2;\n    }\n    bool _2838 = _2789 > 3;\n    bool _2845;\n    if (_2838)\n    {\n        _2845 = _2804 > _2035_fa_shadow_split.z;\n    }\n    else\n    {\n        _2845 = _2838;\n    }\n    if (_2845)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2789)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2871 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2871;\n        if (_2871 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2035_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2896;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2896 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2896 = _2035_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2915 = _2035_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2896, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2926 = clamp((_2804 - (fa_shadow_split_at(param_7) - _2915)) / _2915, 0.0f, 1.0f);\n        if (_2926 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2789)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2947 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2947;\n                if (_2947 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2926);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2469 = _378_fa_pbr.z < 0.5f;\n    bool _2476;\n    if (!_2469)\n    {\n        _2476 = _2035_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2476 = _2469;\n    }\n    if (_2476)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2035_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2489 = fa_light_texel(param);\n    float _2490 = _2489.x;\n    if (_2490 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2499 = int(_2490 + 0.5f);\n    int param_1 = _2499;\n    float4 _2503 = fa_light_texel(param_1);\n    int param_2 = _2499 + 1;\n    float4 _2508 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2511 = _2503.y;\n    if (_2511 > 0.0f)\n    {\n        float _2528 = 1.0f - smoothstep(0.75f * _2511, _2511, length(world - _2035_fa_shadow_eye.xyz));\n        fade = _2528;\n        if (_2528 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2503.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2552 = (_2499 + 2) + (face * 6);\n    int param_4 = _2552;\n    int param_5 = _2552 + 1;\n    int param_6 = _2552 + 3;\n    float4 _2566 = fa_light_texel(param_6);\n    int param_7 = _2552 + 4;\n    float4 _2571 = fa_light_texel(param_7);\n    int param_8 = _2552 + 5;\n    float4 _2576 = fa_light_texel(param_8);\n    float _2588 = _2576.x * max(dot(_2566, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2593 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2616 = clamp(dot(n, _2566.xyz), -1.0f, 1.0f);\n    float _2635 = min(sqrt(1.0f - (_2616 * _2616)) / max(abs(dot(n, world - lpos)) / max(dot(_2566, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2638 = _2508.y;\n    float _2640;\n    if (_2638 > 0.0f)\n    {\n        _2640 = _2638;\n    }\n    else\n    {\n        _2640 = 1.5f * _2588;\n    }\n    float4 _2660 = float4(world + (n * (_2640 * sqrt(1.0f - (_2593 * _2593)))), 1.0f);\n    float _2664 = dot(_2566, _2660);\n    float _2667 = _2576.y;\n    if (_2664 < _2667)\n    {\n        return 1.0f;\n    }\n    float2 _2682 = float2(dot(fa_light_texel(param_4), _2660), dot(fa_light_texel(param_5), _2660)) / _2664.xx;\n    float _2684 = _2682.x;\n    bool _2687 = _2684 < _2571.x;\n    bool _2696;\n    if (!_2687)\n    {\n        _2696 = _2684 > _2571.z;\n    }\n    else\n    {\n        _2696 = _2687;\n    }\n    bool _2705;\n    if (!_2696)\n    {\n        _2705 = _2682.y < _2571.y;\n    }\n    else\n    {\n        _2705 = _2696;\n    }\n    bool _2714;\n    if (!_2705)\n    {\n        _2714 = _2682.y > _2571.w;\n    }\n    else\n    {\n        _2714 = _2705;\n    }\n    if (_2714)\n    {\n        return 1.0f;\n    }\n    float _2720 = _2508.x;\n    float _2722;\n    if (_2720 > 0.0f)\n    {\n        _2722 = _2720;\n    }\n    else\n    {\n        _2722 = 1.5f * _2588;\n    }\n    float2 param_9 = _2682;\n    float4 param_10 = _2571;\n    float param_11 = _2664 - (_2722 * (1.0f + (0.5f * _2635)));\n    float param_12 = _2588;\n    float param_13 = 1.0f;\n    float param_14 = _2576.z * 0.25f;\n    float param_15 = (_2588 * min(_2635, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2667, _2576.z);\n    int param_17 = int(_2503.z + 0.5f);\n    float param_18 = _2503.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3262 = fa_lm.z > 0.5f;\n    bool _3268;\n    if (_3262)\n    {\n        int param = li;\n        _3268 = fa_light_baked(param);\n    }\n    else\n    {\n        _3268 = _3262;\n    }\n    if (_3268)\n    {\n        int param_1 = li;\n        LightSample _4296 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4296;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3292 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _4298 = _3292.color;\n    float _4300 = _3292.shadow;\n    if ((_3292.type == 0) && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3292.direction;\n        float _3306 = fa_shadow_factor(param_5, param_6);\n        _4300 = _3306;\n        _4298 *= _3306;\n    }\n    else\n    {\n        bool _3317 = _3292.type != 0;\n        bool _3323;\n        if (_3317)\n        {\n            _3323 = _3292.attenuation > 0.0f;\n        }\n        else\n        {\n            _3323 = _3317;\n        }\n        if (_3323)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3292.direction;\n            float _3342 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4300 = _3342;\n            _4298 *= _3342;\n        }\n    }\n    LightSample _4315 = { _3292.direction, _4298, _3292.attenuation, _4300, _3292._distance, _3292.type };\n    return _4315;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2035_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2971 = int(_2035_fa_shadow_cfg.x + 0.5f);\n    float _2981 = dot(world - _2035_fa_shadow_eye.xyz, _2035_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2986 = _2971 > 0;\n    bool _2995;\n    if (_2986)\n    {\n        int param = _2971 - 1;\n        _2995 = _2981 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2995 = _2986;\n    }\n    if (_2995)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3001 = _2971 > 1;\n        bool _3008;\n        if (_3001)\n        {\n            _3008 = _2981 > _2035_fa_shadow_split.x;\n        }\n        else\n        {\n            _3008 = _3001;\n        }\n        if (_3008)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3014 = _2971 > 2;\n        bool _3021;\n        if (_3014)\n        {\n            _3021 = _2981 > _2035_fa_shadow_split.y;\n        }\n        else\n        {\n            _3021 = _3014;\n        }\n        if (_3021)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3027 = _2971 > 3;\n        bool _3034;\n        if (_3027)\n        {\n            _3034 = _2981 > _2035_fa_shadow_split.z;\n        }\n        else\n        {\n            _3034 = _3027;\n        }\n        if (_3034)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4139 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4139 = -_4139;\n    }\n    float3 _3724 = normalize(_378_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4152 = { fa_world_pos, _4139, fa_world_tangent, fa_uv, fa_vertex_color, _3724, gl_FrontFacing };\n    SurfaceInput param_1 = _4152;\n    Surface _3732 = fa_standard_surface(param_1);\n    float3 _4170 = _3732.albedo;\n    float _4171 = _3732.alpha;\n    float3 _4172 = _3732.normal;\n    float _4173 = _3732.metallic;\n    float _4174 = _3732.roughness;\n    float _4175 = _3732.occlusion;\n    float3 _4176 = _3732.emission;\n    float _4177 = _3732.clearcoat;\n    float _4178 = _3732.clearcoat_roughness;\n    float3 _4179 = _3732.sheen_color;\n    float _4180 = _3732.sheen_roughness;\n    float _4181 = _3732.anisotropy;\n    float _4182 = _3732.anisotropy_rotation;\n    float _4183 = _3732.specular;\n    float _4184 = _3732.ior;\n    float3 _4185 = _3732.specular_color;\n    SurfaceInput _4160 = { fa_world_pos, _4139, fa_world_tangent, fa_uv, fa_vertex_color, _3724, gl_FrontFacing };\n    SurfaceInput param_2 = _4160;\n    Surface param_3 = _3732;\n    surface(param_2, param_3);\n    _4170 = param_3.albedo;\n    _4171 = param_3.alpha;\n    _4172 = param_3.normal;\n    _4173 = param_3.metallic;\n    _4174 = param_3.roughness;\n    _4175 = param_3.occlusion;\n    _4176 = param_3.emission;\n    _4177 = param_3.clearcoat;\n    _4178 = param_3.clearcoat_roughness;\n    _4179 = param_3.sheen_color;\n    _4180 = param_3.sheen_roughness;\n    _4181 = param_3.anisotropy;\n    _4182 = param_3.anisotropy_rotation;\n    _4183 = param_3.specular;\n    _4184 = param_3.ior;\n    _4185 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4139;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4170 = param_6;\n    _4172 = param_7;\n    float3 result;\n    if (_378_fa_emissive.w > 0.5f)\n    {\n        result = _4170;\n    }\n    else\n    {\n        float3 _3770 = _4172;\n        float3 _3771 = normalize(_3770);\n        _4172 = _3771;\n        float3 param_8 = _3771;\n        float3 lit = (fa_indirect_diffuse(param_8) * _4170) * _4175;\n        int _3790 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3790; ln++)\n        {\n            int param_9 = ln;\n            int _3803 = fa_cl_light(param_9);\n            bool _3806 = fa_lm.z > 0.5f;\n            bool _3812;\n            if (_3806)\n            {\n                int param_10 = _3803;\n                _3812 = fa_light_baked(param_10);\n            }\n            else\n            {\n                _3812 = _3806;\n            }\n            if (_3812)\n            {\n                continue;\n            }\n            int param_11 = _3803;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _4139;\n            LightSample _3824 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput _4168 = { fa_world_pos, _4139, fa_world_tangent, fa_uv, fa_vertex_color, _3724, gl_FrontFacing };\n            SurfaceInput param_14 = _4168;\n            Surface _4251 = { _4170, _4171, _4172, _4173, _4174, _4175, _4176, _4177, _4178, _4179, _4180, _4181, _4182, _4183, _4184, _4185 };\n            Surface param_15 = _4251;\n            LightSample param_16 = _3824;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _3839 = result;\n    float3 _3840 = _3839 + _4176;\n    result = _3840;\n    float3 param_17 = _3840;\n    float3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _3849 = _378_fa_fog.w > 0.0f;\n    bool _3856;\n    if (!_3849)\n    {\n        _3856 = _378_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _3856 = _3849;\n    }\n    if (_3856)\n    {\n        float3 _3865 = fa_world_pos - _378_fa_camera_pos.xyz;\n        float _3871 = dot(_3865, _378_fa_fog_c.xyz);\n        bool _3875 = _378_fa_fog_c.w > 0.5f;\n        float _3876;\n        if (_3875)\n        {\n            _3876 = _3871;\n        }\n        else\n        {\n            _3876 = length(_3865);\n        }\n        float _3888 = _3876 - _378_fa_fog_b.x;\n        if (_3888 > 0.0f)\n        {\n            float _3897 = _378_fa_fog.w * _3888;\n            float tau = _3897 * _3897;\n            if (_378_fa_fog_b.y > 0.0f)\n            {\n                float _3913;\n                if (_3875)\n                {\n                    _3913 = fa_world_pos.y - (_378_fa_fog_c.y * _3871);\n                }\n                else\n                {\n                    _3913 = _378_fa_camera_pos.y;\n                }\n                float _3934 = lerp(_3913, fa_world_pos.y, clamp(_378_fa_fog_b.x / _3876, 0.0f, 1.0f));\n                float _3938 = fa_world_pos.y - _3934;\n                float _3943 = _3934 - _378_fa_fog_b.z;\n                float _3948 = fa_world_pos.y - _378_fa_fog_b.z;\n                bool _3951 = _3943 <= 0.0f;\n                bool _3952 = !_3951;\n                bool _3958;\n                if (_3952)\n                {\n                    _3958 = _378_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3958 = _3951;\n                }\n                float _3959;\n                if (_3958)\n                {\n                    _3959 = _378_fa_fog_b.y;\n                }\n                else\n                {\n                    _3959 = _378_fa_fog_b.y * exp(-min(_378_fa_fog_b.w * _3943, 80.0f));\n                }\n                bool _3986;\n                if (_3952)\n                {\n                    _3986 = _378_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _3986 = _3951;\n                }\n                float _3987;\n                if (_3986)\n                {\n                    _3987 = _378_fa_fog_b.y * _3943;\n                }\n                else\n                {\n                    _3987 = (_378_fa_fog_b.y * (1.0f - exp(-min(_378_fa_fog_b.w * _3943, 80.0f)))) / _378_fa_fog_b.w;\n                }\n                bool _4012 = _3948 <= 0.0f;\n                bool _4019;\n                if (!_4012)\n                {\n                    _4019 = _378_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4019 = _4012;\n                }\n                float _4020;\n                if (_4019)\n                {\n                    _4020 = _378_fa_fog_b.y * _3948;\n                }\n                else\n                {\n                    _4020 = (_378_fa_fog_b.y * (1.0f - exp(-min(_378_fa_fog_b.w * _3948, 80.0f)))) / _378_fa_fog_b.w;\n                }\n                float _4047;\n                if (abs(_3938) < 0.001000000047497451305389404296875f)\n                {\n                    _4047 = _3959;\n                }\n                else\n                {\n                    _4047 = (_4020 - _3987) / _3938;\n                }\n                tau += (_3888 * max(_4047, 0.0f));\n            }\n            result = lerp(result, _378_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4171);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_378",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2035",
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
          }
        ]
      }
    },
    "prepass": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _292 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _292;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0f);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    float4 _241 = (_784 * _213_fa_base_color) * i.vertex_color;\n    float3 _747 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = _213_fa_layers_a.x;\n    float _753 = _213_fa_layers_a.y;\n    float _756 = _213_fa_layers_a.z;\n    float _755 = _213_fa_layers_b.w;\n    float _758 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    Surface _777 = { _241.xyz, _241.w, _747, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _752, _753, _213_fa_layers_b.xyz, _755, _756, _213_fa_layers_a.w, _758, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _777;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _658 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _671 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _671;\n    SurfaceInput _679 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _679;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 384,
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    float4 _241 = (_784 * _213_fa_base_color) * i.vertex_color;\n    float3 _747 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = _213_fa_layers_a.x;\n    float _753 = _213_fa_layers_a.y;\n    float _756 = _213_fa_layers_a.z;\n    float _755 = _213_fa_layers_b.w;\n    float _758 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    Surface _777 = { _241.xyz, _241.w, _747, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _752, _753, _213_fa_layers_b.xyz, _755, _756, _213_fa_layers_a.w, _758, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _777;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _658 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _671 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _671;\n    SurfaceInput _679 = { fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _679;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 384,
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
