{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5c7bc8cc90909f1ebab7aa9dd758cdced3d658fca63fc282b6949a210c4a3347",
  "slang": "hlsl5",
  "params": [
    "dark"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _263 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _263;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_270, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _386_fa_camera_pos : packoffset(c0);\n    float4 _386_fa_ambient : packoffset(c1);\n    float4 _386_fa_base_color : packoffset(c2);\n    float4 _386_fa_emissive : packoffset(c3);\n    float4 _386_fa_model_emissive : packoffset(c4);\n    float4 _386_fa_pbr : packoffset(c5);\n    float4 _386_fa_maps : packoffset(c6);\n    float4 _386_fa_fog : packoffset(c7);\n    float4 _386_fa_fog_b : packoffset(c8);\n    float4 _386_fa_fog_c : packoffset(c9);\n    float4 _386_fa_counts : packoffset(c10);\n    float4 _386_fa_env_sky : packoffset(c11);\n    float4 _386_fa_env_horizon : packoffset(c12);\n    float4 _386_fa_time : packoffset(c13);\n    float4 _386_fa_cl_vpx : packoffset(c14);\n    float4 _386_fa_cl_vpy : packoffset(c15);\n    float4 _386_fa_cl_vpw : packoffset(c16);\n    float4 _386_fa_cl_fwd : packoffset(c17);\n    float4 _386_fa_cl_grid : packoffset(c18);\n    float4 _386_fa_cl_info : packoffset(c19);\n    float4 _386_fa_layers_a : packoffset(c20);\n    float4 _386_fa_layers_b : packoffset(c21);\n    float4 _386_fa_layers_c : packoffset(c22);\n    float4 _386_fa_layers_d : packoffset(c23);\n    float4 _386_fa_ct_a : packoffset(c24);\n    float4 _386_fa_ct_b : packoffset(c25);\n    float4 _386_fa_ct_vpx : packoffset(c26);\n    float4 _386_fa_ct_vpy : packoffset(c27);\n    float4 _386_fa_ct_vpw : packoffset(c28);\n    float4 _386_fa_ct_fwd : packoffset(c29);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2043_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2043_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2043_fa_shadow_info[4] : packoffset(c20);\n    float4 _2043_fa_shadow_split : packoffset(c24);\n    float4 _2043_fa_shadow_cfg : packoffset(c25);\n    float4 _2043_fa_shadow_bias : packoffset(c26);\n    float4 _2043_fa_shadow_eye : packoffset(c27);\n    float4 _2043_fa_shadow_fwd : packoffset(c28);\n    float4 _2043_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _3673_dark : packoffset(c0);\n    float _3673_fa_pad0 : packoffset(c0.y);\n    float _3673_fa_pad1 : packoffset(c0.z);\n    float _3673_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1314 = _386_fa_cl_info.x < 0.0f;\n    bool _1321;\n    if (!_1314)\n    {\n        _1321 = _386_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1321 = _1314;\n    }\n    bool _1329;\n    if (!_1321)\n    {\n        _1329 = _386_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1329 = _1321;\n    }\n    bool _1336;\n    if (!_1329)\n    {\n        _1336 = _386_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1336 = _1329;\n    }\n    bool _1343;\n    if (!_1336)\n    {\n        _1343 = _386_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1343 = _1336;\n    }\n    if (_1343)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1353 = float4(world_pos, 1.0f);\n    float _1359 = dot(_386_fa_cl_vpw, _1353);\n    if (!(_1359 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1381 = float2(dot(_386_fa_cl_vpx, _1353), dot(_386_fa_cl_vpy, _1353)) / _1359.xx;\n    int _1385 = int(_386_fa_cl_grid.x);\n    int _1389 = int(_386_fa_cl_grid.y);\n    int param = (int(_386_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_386_fa_cl_fwd.xyz, world_pos) + _386_fa_cl_fwd.w, _386_fa_cl_grid.w) / _386_fa_cl_grid.w) * _386_fa_cl_grid.z)), 0, int(_386_fa_cl_info.y) - 1) * _1389) + clamp(int(floor(((_1381.y * 0.5f) + 0.5f) * _386_fa_cl_grid.y)), 0, _1389 - 1)) * _1385)) + clamp(int(floor(((_1381.x * 0.5f) + 0.5f) * _386_fa_cl_grid.x)), 0, _1385 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1465 = fa_cluster_texel(param);\n    return int2(int(_1465.x), int(_1465.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_386_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3496 = fa_cluster_lookup(param);\n    fa_cl_slot = _3496.x;\n    fa_cl_local = _3496.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3722 = fa_linear_to_srgb(param);\n        c = _3722;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3730 = fa_srgb_to_linear(param_1);\n            c = _3730;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _269;\n    if (i.front_facing)\n    {\n        _269 = i.world_normal;\n    }\n    else\n    {\n        _269 = -i.world_normal;\n    }\n    float3 _293 = normalize(i.world_tangent.xyz - (_269 * dot(_269, i.world_tangent.xyz)));\n    float3 _320 = normalize(((_293 * m.x) + ((cross(_269, _293) * i.world_tangent.w) * m.y)) + (_269 * m.z));\n    float3 _323;\n    if (i.front_facing)\n    {\n        _323 = _320;\n    }\n    else\n    {\n        _323 = -_320;\n    }\n    return _323;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _386_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3761 = fa_tex_fix(param_2, param_3);\n    float4 _4795 = base_t;\n    _4795.x = _3761.x;\n    _4795.y = _3761.y;\n    _4795.z = _3761.z;\n    base_t = _4795;\n    float4 _3775 = (_4795 * _386_fa_base_color) * i.vertex_color;\n    float3 _4647 = i.world_normal;\n    if (_386_fa_maps.z > 0.5f)\n    {\n        float param_4 = _386_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3807 = fa_tex_fix(param_6, param_7);\n        float3 _3810 = (_3807 * 2.0f) - 1.0f.xxx;\n        float2 _3815 = _3810.xy * _386_fa_maps.x;\n        float3 _4803 = _3810;\n        _4803.x = _3815.x;\n        _4803.y = _3815.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4803;\n        _4647 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _386_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3843 = fa_tex_fix(param_12, param_13);\n    float4 _4806 = mrt;\n    _4806.x = _3843.x;\n    _4806.y = _3843.y;\n    _4806.z = _3843.z;\n    mrt = _4806;\n    float4 _3871 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _386_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3871.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3882 = fa_tex_fix(param_16, param_17);\n    float param_18 = _386_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3912 = fa_tex_fix(param_20, param_21);\n    float _4652 = _386_fa_layers_a.x;\n    float _4653 = _386_fa_layers_a.y;\n    float _4656 = _386_fa_layers_a.z;\n    float _4655 = _386_fa_layers_b.w;\n    float _4658 = _386_fa_layers_c.x;\n    if (_386_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_386_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4652 *= _3882.y;\n            _4653 *= _3882.z;\n            _4655 *= _3871.w;\n        }\n        if (_386_fa_layers_c.z > 1.5f)\n        {\n            _4656 *= mrt.x;\n            _4658 *= mrt.w;\n        }\n    }\n    Surface _4677 = { _3775.xyz, _3775.w, _4647, clamp(_386_fa_pbr.x * _3843.z, 0.0f, 1.0f), clamp(_386_fa_pbr.y * _3843.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_386_fa_maps.y * (_3882.x - 1.0f)), _386_fa_emissive.xyz + (_386_fa_model_emissive.xyz * _3912), _4652, _4653, _386_fa_layers_b.xyz, _4655, _4656, _386_fa_layers_a.w, _4658, _386_fa_layers_c.y, _386_fa_layers_d.xyz };\n    return _4677;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1545 = rect.zw - rect.xy;\n    float2 _1549 = _1545 * atlas;\n    float2 _1553 = ddx * _1549;\n    float2 _1557 = ddy * _1549;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1545), clamp(0.5f * log2(max(max(dot(_1553, _1553), dot(_1557, _1557)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1590 = _386_fa_counts.y < 0.5f;\n    bool _1597;\n    if (!_1590)\n    {\n        _1597 = _386_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1597 = _1590;\n    }\n    if (_1597)\n    {\n        return;\n    }\n    float3 _1603 = ddx(world_pos);\n    float3 _1606 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1610 = fa_cluster_texel(param);\n    int _1614 = int(_1610.w);\n    if (_1614 < 1)\n    {\n        return;\n    }\n    int _1624 = int(_386_fa_counts.y + 0.5f);\n    int param_1 = _1624;\n    float4 _1628 = fa_light_texel(param_1);\n    float2 _1631 = _1628.yz;\n    int _1635 = int(_1628.w);\n    int param_2 = _1624 + 1;\n    float4 _1640 = fa_light_texel(param_2);\n    float _1641 = _1640.x;\n    int _1647 = int(_386_fa_counts.w + 0.5f) - 1;\n    int _1651 = int(_1610.z);\n    float3 _1916;\n    for (int k = 0; k < _1614; k++)\n    {\n        int _1664 = _1651 + k;\n        int param_3 = _1635 + (_1664 >> 2);\n        int _1681 = (_1624 + 2) + (int(fa_light_texel(param_3)[_1664 & 3]) * 7);\n        int param_4 = _1681 + 6;\n        float4 _1686 = fa_light_texel(param_4);\n        if (((int(_1686.w + 0.5f) >> _1647) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1681;\n        float4 _1701 = fa_light_texel(param_5);\n        int param_6 = _1681 + 1;\n        float4 _1706 = fa_light_texel(param_6);\n        int param_7 = _1681 + 2;\n        float4 _1711 = fa_light_texel(param_7);\n        float3 _1714 = _1701.xyz;\n        float _1719 = dot(_1714, world_pos) + _1701.w;\n        float3 _1721 = _1706.xyz;\n        float _1726 = dot(_1721, world_pos) + _1706.w;\n        float3 _1728 = _1711.xyz;\n        float _1733 = dot(_1728, world_pos) + _1711.w;\n        bool _1738 = abs(_1719) > 0.5f;\n        bool _1746;\n        if (!_1738)\n        {\n            _1746 = abs(_1726) > 0.5f;\n        }\n        else\n        {\n            _1746 = _1738;\n        }\n        bool _1754;\n        if (!_1746)\n        {\n            _1754 = abs(_1733) > 0.5f;\n        }\n        else\n        {\n            _1754 = _1746;\n        }\n        if (_1754)\n        {\n            continue;\n        }\n        float _1769 = clamp(dot(geo_normal, normalize(_1728)) * _1686.z, 0.0f, 1.0f);\n        if (_1769 <= 0.0f)\n        {\n            continue;\n        }\n        float _1789 = (clamp((0.5f - abs(_1733)) * 10.0f, 0.0f, 1.0f) * _1769) * _1686.x;\n        float2 _1797 = float2(_1719 + 0.5f, 0.5f - _1726);\n        float2 _1807 = float2(dot(_1714, _1603), dot(_1721, _1603));\n        float2 _1817 = float2(dot(_1714, _1606), dot(_1721, _1606));\n        int param_8 = _1681 + 5;\n        float4 _1822 = fa_light_texel(param_8);\n        int param_9 = _1681 + 3;\n        float4 _1827 = fa_light_texel(param_9);\n        int param_10 = _1681 + 4;\n        float4 _1832 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1822.xyz;\n        bool _1842 = _1827.z > _1827.x;\n        if (_1842)\n        {\n            float4 param_11 = _1827;\n            float2 param_12 = _1797;\n            float2 param_13 = _1631;\n            float2 param_14 = _1807;\n            float2 param_15 = _1817;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1641 > 0.5f) && (_1641 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1868 = fa_dc_to_linear(param_16);\n                float4 _4727 = tx;\n                _4727.x = _1868.x;\n                _4727.y = _1868.y;\n                _4727.z = _1868.z;\n                tx = _4727;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1789 * tex_a) * _1822.w, 0.0f, 1.0f).xxx);\n        if (_1832.z > _1832.x)\n        {\n            float4 param_17 = _1832;\n            float2 param_18 = _1797;\n            float2 param_19 = _1631;\n            float2 param_20 = _1807;\n            float2 param_21 = _1817;\n            float4 _1912 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1641 > 1.5f)\n            {\n                float3 param_22 = _1912.xyz;\n                float3 _1922 = fa_dc_to_srgb(param_22);\n                _1916 = _1922;\n            }\n            else\n            {\n                _1916 = _1912.xyz;\n            }\n            float3 _1931 = (_1916 * 2.0f) - 1.0f.xxx;\n            float2 _1936 = _1931.xy * _1686.y;\n            float3 _1958 = (normalize(_1714) * _1936.x) + (normalize(_1721) * _1936.y);\n            float3 _1961 = normalize(normal);\n            normal = normalize(lerp(_1961, normalize((_1961 * max(_1931.z, 0.0500000007450580596923828125f)) + (_1958 - (_1961 * dot(_1961, _1958)))), clamp(_1789 * (_1842 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_386_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3156 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3156;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_386_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _386_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_386_fa_cl_info.x) + int(_386_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_386_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _445_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _445_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _564 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _577 = (c - (ru * hx)) - p;\n        float3 _583 = ru * (2.0f * hx);\n        float _589 = max(dot(_583, _583), 9.9999999392252902907785028219223e-09f);\n        float _593 = dot(_577, _583);\n        float t = clamp((-_593) / _589, 0.0f, 1.0f);\n        if (_564)\n        {\n            float _608 = dot(r, _583);\n            float _614 = _589 - (_608 * _608);\n            if (abs(_614) > (9.9999997473787516355514526367188e-06f * _589))\n            {\n                t = clamp(((dot(r, _577) * _608) - _593) / _614, 0.0f, 1.0f);\n            }\n        }\n        return (p + _577) + (_583 * t);\n    }\n    float3 q = p;\n    float _646 = dot(r, axis);\n    bool _654;\n    if (_564)\n    {\n        _654 = abs(_646) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _654 = _564;\n    }\n    if (_654)\n    {\n        float _664 = dot(c - p, axis) / _646;\n        if (_664 > 0.0f)\n        {\n            q = p + (r * _664);\n        }\n    }\n    float3 _677 = q - c;\n    float2 xy = float2(dot(_677, ru), dot(_677, uu));\n    if (shape > 0.5f)\n    {\n        float _692 = length(xy);\n        if (_692 > hx)\n        {\n            xy *= (hx / _692);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _335 = abs(d);\n    float _337 = _335.x;\n    float _339 = _335.y;\n    bool _340 = _337 >= _339;\n    bool _348;\n    if (_340)\n    {\n        _348 = _337 >= _335.z;\n    }\n    else\n    {\n        _348 = _340;\n    }\n    int _349;\n    if (_348)\n    {\n        _349 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _364;\n        if (_339 >= _335.z)\n        {\n            _364 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _364 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _349 = _364;\n    }\n    return _349;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _484 = dot(d, right);\n    float _488 = dot(d, up);\n    float _499;\n    if (((_484 * _484) + (_488 * _488)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _499 = atan2(_488, _484) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _499 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_499 - floor(_499)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _730 = fa_light_base(param);\n    bool _734 = _386_fa_ambient.w > 4.5f;\n    int param_1 = _730;\n    float4 _738 = fa_light_texel(param_1);\n    int param_2 = _730 + 1;\n    float4 _743 = fa_light_texel(param_2);\n    float _746 = _743.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _758 = _734 && (_746 > 2.5f);\n    fa_light_is_area = _758;\n    bool _760 = _746 < 0.5f;\n    float3 l;\n    if (_760)\n    {\n        l = normalize(_738.xyz);\n        if (_734)\n        {\n            int param_3 = _730 + 6;\n            float4 _774 = fa_light_texel(param_3);\n            if (_774.z > 0.5f)\n            {\n                int param_4 = _730 + 4;\n                float4 _784 = fa_light_texel(param_4);\n                int param_5 = _730 + 5;\n                float4 _789 = fa_light_texel(param_5);\n                float2 param_6 = _774.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _784.xyz) * _784.w, (-dot(world_pos, _789.xyz)) * _789.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _819 = _738.xyz;\n        float3 _821 = _819 - world_pos;\n        float3 to_light = _821;\n        float _824 = length(_821);\n        float reach = _824;\n        bool front = true;\n        if (_758)\n        {\n            int param_8 = _730 + 7;\n            reach = max(_824 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _730 + 4;\n            float4 _848 = fa_light_texel(param_9);\n            int param_10 = _730 + 5;\n            float4 _853 = fa_light_texel(param_10);\n            int param_11 = _730 + 6;\n            float4 _858 = fa_light_texel(param_11);\n            float _859 = _858.w;\n            int param_12 = _730 + 2;\n            float3 _866 = normalize(fa_light_texel(param_12).xyz);\n            bool _868 = _859 > 1.5f;\n            bool _876;\n            if (!_868)\n            {\n                _876 = dot(_866, to_light) < 0.0f;\n            }\n            else\n            {\n                _876 = _868;\n            }\n            front = _876;\n            float3 r = 0.0f.xxx;\n            float3 _885 = _386_fa_camera_pos.xyz - world_pos;\n            bool _889 = dot(n, n) > 0.5f;\n            bool _897;\n            if (_889)\n            {\n                _897 = dot(_885, _885) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _897 = _889;\n            }\n            if (_897)\n            {\n                r = reflect(-normalize(_885), normalize(n));\n            }\n            float3 param_13 = _819;\n            float3 param_14 = _866;\n            float3 param_15 = _848.xyz;\n            float3 param_16 = _853.xyz;\n            float param_17 = _848.w;\n            float param_18 = _853.w;\n            float param_19 = _859;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _933 = length(to_light);\n        dist = _933;\n        l = to_light / max(_933, 9.9999997473787516355514526367188e-05f).xxx;\n        float _947 = reach / max(_738.w, 0.001000000047497451305389404296875f);\n        float _953 = clamp(1.0f - (_947 * _947), 0.0f, 1.0f);\n        float _955;\n        if (front)\n        {\n            _955 = _953 * _953;\n        }\n        else\n        {\n            _955 = 0.0f;\n        }\n        atten = _955;\n        bool _966 = _746 < 2.5f;\n        if ((_746 > 1.5f) && _966)\n        {\n            int param_22 = _730 + 2;\n            float4 _974 = fa_light_texel(param_22);\n            float _984 = _974.w;\n            int param_23 = _730 + 3;\n            float4 _989 = fa_light_texel(param_23);\n            float _990 = _989.x;\n            float cos_inner = _990;\n            if (_990 > 1.5f)\n            {\n                cos_inner = lerp(_984, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_984, cos_inner, dot(-l, normalize(_974.xyz)));\n        }\n        if (_734 && (_746 < 1.5f))\n        {\n            int param_24 = _730 + 6;\n            float4 _1014 = fa_light_texel(param_24);\n            if (_1014.z > 0.5f)\n            {\n                float3 _1022 = -to_light;\n                int param_25 = _730 + 4;\n                int param_26 = _730 + 5;\n                float3 _1036 = fa_light_texel(param_25).xyz;\n                float3 _1040 = fa_light_texel(param_26).xyz;\n                float3 _1049 = float3(dot(_1022, _1036), dot(_1022, _1040), dot(_1022, cross(_1036, _1040)));\n                float3 param_27 = _1049;\n                int _1053 = fa_cube_face(param_27);\n                int param_28 = _1053;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1080 = float2(dot(_1049, cross(param_29, param_30)), dot(_1049, param_30)) / max(dot(_1049, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1084 = _1053 / 3;\n                float2 param_31 = _1014.xy + (float2(float(_1053 - (_1084 * 3)), float(_1084)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1080.x), 0.5f - (0.5f * _1080.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _730 + 7;\n            float4 _1114 = fa_light_texel(param_33);\n            if (_1114.z > 0.5f)\n            {\n                int param_34 = _730 + 2;\n                int param_35 = _730 + 4;\n                int param_36 = _730 + 5;\n                float2 param_37 = _1114.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_734 && _966)\n            {\n                int param_42 = _730 + 6;\n                float4 _1161 = fa_light_texel(param_42);\n                int param_43 = _730 + 7;\n                float4 _1166 = fa_light_texel(param_43);\n                bool _1169 = _1161.z > 0.5f;\n                bool _1176;\n                if (!_1169)\n                {\n                    _1176 = _1166.z > 0.5f;\n                }\n                else\n                {\n                    _1176 = _1169;\n                }\n                if (_1176)\n                {\n                    int param_44 = _730 + 2;\n                    float4 _1183 = fa_light_texel(param_44);\n                    float3 _1187 = normalize(_1183.xyz);\n                    int param_45 = _730 + 4;\n                    float4 _1192 = fa_light_texel(param_45);\n                    int param_46 = _730 + 5;\n                    float4 _1197 = fa_light_texel(param_46);\n                    if (_1169)\n                    {\n                        float3 _1205 = -to_light;\n                        float _1212 = _1183.w;\n                        float _1228 = 0.5f / max(dot(_1205, _1187) * (sqrt(max(1.0f - (_1212 * _1212), 0.0f)) / max(_1212, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1161.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1205, _1192.xyz) * _1228), 0.5f - (dot(_1205, _1197.xyz) * _1228));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1166.z > 0.5f)\n                    {\n                        float2 param_49 = _1166.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1187;\n                        float3 param_52 = _1192.xyz;\n                        float3 param_53 = _1197.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4601 = _743.xyz * atten;\n    if (_734)\n    {\n        _4601 *= fa_light_tint;\n    }\n    int _1296;\n    if (_760)\n    {\n        _1296 = 0;\n    }\n    else\n    {\n        _1296 = ((_746 > 1.5f) && (_746 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4612 = { l, _4601, atten, 1.0f, dist, _1296 };\n    return _4612;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2033;\n    if (i == 0)\n    {\n        _2033 = _2043_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2049;\n        if (i == 1)\n        {\n            _2049 = _2043_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2057;\n            if (i == 2)\n            {\n                _2057 = _2043_fa_shadow_split.z;\n            }\n            else\n            {\n                _2057 = _2043_fa_shadow_split.w;\n            }\n            _2049 = _2057;\n        }\n        _2033 = _2049;\n    }\n    return _2033;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2090 = fa_shadow_depth(param, param_1);\n    float _2094;\n    if (conv.x < 0.5f)\n    {\n        _2094 = _2090;\n    }\n    else\n    {\n        _2094 = (conv.y * conv.z) / (conv.z - (_2090 * (conv.z - conv.y)));\n    }\n    return _2094;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2021 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2021), sin(_2021)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2140 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2149;\n        if (k < 0.0f)\n        {\n            _2149 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2149 = k;\n        }\n        float _2169 = clamp((_2149 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2140;\n            float2 _2188 = fa_shadow_vogel(param_3, param_4, param_5) * _2169;\n            float2 param_6 = uv + (_2188 * _2043_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2200 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2200 < (zr - (length(_2188) * plane)))\n            {\n                sum += _2200;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2226 = sum / cnt;\n        float _2236;\n        if (k < 0.0f)\n        {\n            _2236 = (-k) / max(_2226, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2236 = k;\n        }\n        radius = clamp(((max(zr - _2226, 0.0f) * unit) * _2236) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2258 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2258; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2258;\n        float param_11 = _2140;\n        float2 _2277 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2277 * _2043_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2277) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2258);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2319 = max(_2043_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2324 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2330 = sqrt(1.0f - (_2324 * _2324));\n    float _2337 = min(_2330 / max(_2324, 0.20000000298023223876953125f), 4.0f);\n    float _2342;\n    if (_2043_fa_shadow_bias.y > 0.0f)\n    {\n        _2342 = _2043_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2342 = 1.5f * _2043_fa_shadow_info[ci].x;\n    }\n    float4 _2367 = mul(float4(world + (n * (_2342 * _2330)), 1.0f), _2043_fa_shadow_mat[ci]);\n    float _2374 = _2367.x;\n    bool _2377 = _2374 < _2043_fa_shadow_rect[ci].x;\n    bool _2386;\n    if (!_2377)\n    {\n        _2386 = _2374 > _2043_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2386 = _2377;\n    }\n    bool _2395;\n    if (!_2386)\n    {\n        _2395 = _2367.y < _2043_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2395 = _2386;\n    }\n    bool _2404;\n    if (!_2395)\n    {\n        _2404 = _2367.y > _2043_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2404 = _2395;\n    }\n    bool _2411;\n    if (!_2404)\n    {\n        _2411 = _2367.z > 1.0f;\n    }\n    else\n    {\n        _2411 = _2404;\n    }\n    if (_2411)\n    {\n        return -1.0f;\n    }\n    float _2419;\n    if (_2043_fa_shadow_bias.x > 0.0f)\n    {\n        _2419 = _2043_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2419 = 1.5f * _2043_fa_shadow_info[ci].x;\n    }\n    float2 param = _2367.xy;\n    float4 param_1 = _2043_fa_shadow_rect[ci];\n    float param_2 = _2367.z - ((_2419 * (1.0f + (0.5f * _2337))) / _2319);\n    float param_3 = _2043_fa_shadow_info[ci].x;\n    float param_4 = _2319;\n    float param_5 = _2319 * 0.25f;\n    float param_6 = ((_2043_fa_shadow_info[ci].x * min(_2337, 3.0f)) * 0.5f) / _2319;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2043_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2043_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_386_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2797 = int(_2043_fa_shadow_cfg.x + 0.5f);\n    if (_2797 < 1)\n    {\n        return 1.0f;\n    }\n    float _2812 = dot(world - _2043_fa_shadow_eye.xyz, _2043_fa_shadow_fwd.xyz);\n    int param = _2797 - 1;\n    if (_2812 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2824 = _2797 > 1;\n    bool _2831;\n    if (_2824)\n    {\n        _2831 = _2812 > _2043_fa_shadow_split.x;\n    }\n    else\n    {\n        _2831 = _2824;\n    }\n    if (_2831)\n    {\n        ci = 1;\n    }\n    bool _2835 = _2797 > 2;\n    bool _2842;\n    if (_2835)\n    {\n        _2842 = _2812 > _2043_fa_shadow_split.y;\n    }\n    else\n    {\n        _2842 = _2835;\n    }\n    if (_2842)\n    {\n        ci = 2;\n    }\n    bool _2846 = _2797 > 3;\n    bool _2853;\n    if (_2846)\n    {\n        _2853 = _2812 > _2043_fa_shadow_split.z;\n    }\n    else\n    {\n        _2853 = _2846;\n    }\n    if (_2853)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2797)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2879 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2879;\n        if (_2879 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2043_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2904;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2904 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2904 = _2043_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2923 = _2043_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2904, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2934 = clamp((_2812 - (fa_shadow_split_at(param_7) - _2923)) / _2923, 0.0f, 1.0f);\n        if (_2934 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2797)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2955 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2955;\n                if (_2955 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2934);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2477 = _386_fa_pbr.z < 0.5f;\n    bool _2484;\n    if (!_2477)\n    {\n        _2484 = _2043_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2484 = _2477;\n    }\n    if (_2484)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2043_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2497 = fa_light_texel(param);\n    float _2498 = _2497.x;\n    if (_2498 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2507 = int(_2498 + 0.5f);\n    int param_1 = _2507;\n    float4 _2511 = fa_light_texel(param_1);\n    int param_2 = _2507 + 1;\n    float4 _2516 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2519 = _2511.y;\n    if (_2519 > 0.0f)\n    {\n        float _2536 = 1.0f - smoothstep(0.75f * _2519, _2519, length(world - _2043_fa_shadow_eye.xyz));\n        fade = _2536;\n        if (_2536 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2511.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2560 = (_2507 + 2) + (face * 6);\n    int param_4 = _2560;\n    int param_5 = _2560 + 1;\n    int param_6 = _2560 + 3;\n    float4 _2574 = fa_light_texel(param_6);\n    int param_7 = _2560 + 4;\n    float4 _2579 = fa_light_texel(param_7);\n    int param_8 = _2560 + 5;\n    float4 _2584 = fa_light_texel(param_8);\n    float _2596 = _2584.x * max(dot(_2574, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2601 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2624 = clamp(dot(n, _2574.xyz), -1.0f, 1.0f);\n    float _2643 = min(sqrt(1.0f - (_2624 * _2624)) / max(abs(dot(n, world - lpos)) / max(dot(_2574, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2646 = _2516.y;\n    float _2648;\n    if (_2646 > 0.0f)\n    {\n        _2648 = _2646;\n    }\n    else\n    {\n        _2648 = 1.5f * _2596;\n    }\n    float4 _2668 = float4(world + (n * (_2648 * sqrt(1.0f - (_2601 * _2601)))), 1.0f);\n    float _2672 = dot(_2574, _2668);\n    float _2675 = _2584.y;\n    if (_2672 < _2675)\n    {\n        return 1.0f;\n    }\n    float2 _2690 = float2(dot(fa_light_texel(param_4), _2668), dot(fa_light_texel(param_5), _2668)) / _2672.xx;\n    float _2692 = _2690.x;\n    bool _2695 = _2692 < _2579.x;\n    bool _2704;\n    if (!_2695)\n    {\n        _2704 = _2692 > _2579.z;\n    }\n    else\n    {\n        _2704 = _2695;\n    }\n    bool _2713;\n    if (!_2704)\n    {\n        _2713 = _2690.y < _2579.y;\n    }\n    else\n    {\n        _2713 = _2704;\n    }\n    bool _2722;\n    if (!_2713)\n    {\n        _2722 = _2690.y > _2579.w;\n    }\n    else\n    {\n        _2722 = _2713;\n    }\n    if (_2722)\n    {\n        return 1.0f;\n    }\n    float _2728 = _2516.x;\n    float _2730;\n    if (_2728 > 0.0f)\n    {\n        _2730 = _2728;\n    }\n    else\n    {\n        _2730 = 1.5f * _2596;\n    }\n    float2 param_9 = _2690;\n    float4 param_10 = _2579;\n    float param_11 = _2672 - (_2730 * (1.0f + (0.5f * _2643)));\n    float param_12 = _2596;\n    float param_13 = 1.0f;\n    float param_14 = _2584.z * 0.25f;\n    float param_15 = (_2596 * min(_2643, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2675, _2584.z);\n    int param_17 = int(_2511.z + 0.5f);\n    float param_18 = _2511.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3236 = _386_fa_ct_a.x < 0.5f;\n    bool _3243;\n    if (!_3236)\n    {\n        _3243 = _2043_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3243 = _3236;\n    }\n    if (_3243)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2043_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3256 = fa_light_texel(param);\n    float _3257 = _3256.y;\n    float len = _3257;\n    if (_3257 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3269 = length(world - _386_fa_camera_pos.xyz);\n    float _3279 = 1.0f - smoothstep(0.5f * _386_fa_ct_b.x, _386_fa_ct_b.x, _3269);\n    if (_3279 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3285 = len;\n    float _3288 = min(_3285, 0.89999997615814208984375f * dist);\n    len = _3288;\n    float _3294 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3269);\n    float _3299 = _3294 + (0.5f * _3288);\n    float3 _3305 = world + (gn * _3294);\n    float _3307 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _3372;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3323 = (float(k) + _3307) * 0.083333335816860198974609375f;\n        float3 _3331 = _3305 + (l * (_3323 * len));\n        float4 _3337 = float4(_3331, 1.0f);\n        float _3343 = dot(_386_fa_ct_vpw, _3337);\n        if (_3343 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _3363 = float2(dot(_386_fa_ct_vpx, _3337), dot(_386_fa_ct_vpy, _3337)) / _3343.xx;\n        float _3367 = _3363.x * 0.5f;\n        float _3368 = _3367 + 0.5f;\n        if (_386_fa_ct_a.y > 0.5f)\n        {\n            _3372 = (_3363.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _3372 = 0.5f - (_3363.y * 0.5f);\n        }\n        bool _3388 = _3368 < 0.0f;\n        bool _3395;\n        if (!_3388)\n        {\n            _3395 = _3368 >= 1.0f;\n        }\n        else\n        {\n            _3395 = _3388;\n        }\n        bool _3402;\n        if (!_3395)\n        {\n            _3402 = _3372 < 0.0f;\n        }\n        else\n        {\n            _3402 = _3395;\n        }\n        bool _3409;\n        if (!_3402)\n        {\n            _3409 = _3372 >= 1.0f;\n        }\n        else\n        {\n            _3409 = _3402;\n        }\n        if (_3409)\n        {\n            break;\n        }\n        float4 _3428 = fa_screen_tex.Load(int3(int2(float2(_3368, _3372) * _386_fa_ct_a.zw), 0));\n        if (_3428.w < 0.5f)\n        {\n            continue;\n        }\n        float _3447 = (dot(_386_fa_ct_fwd.xyz, _3331) + _386_fa_ct_fwd.w) - _3428.x;\n        if ((_3447 > _3294) && (_3447 < _3299))\n        {\n            occ = max(occ, (1.0f - (_3323 * _3323)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_3368, 0.5f - _3367), min(_3372, 1.0f - _3372))));\n        }\n    }\n    return 1.0f - (occ * _3279);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3523 = fa_lm.z > 0.5f;\n    bool _3529;\n    if (_3523)\n    {\n        int param = li;\n        _3529 = fa_light_baked(param);\n    }\n    else\n    {\n        _3529 = _3523;\n    }\n    if (_3529)\n    {\n        int param_1 = li;\n        LightSample _4625 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4625;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3553 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _4627 = _3553.color;\n    float _4629 = _3553.shadow;\n    bool _3556 = _3553.type == 0;\n    if (_3556 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3553.direction;\n        float _3567 = fa_shadow_factor(param_5, param_6);\n        _4629 = _3567;\n        _4627 *= _3567;\n    }\n    else\n    {\n        bool _3578 = _3553.type != 0;\n        bool _3584;\n        if (_3578)\n        {\n            _3584 = _3553.attenuation > 0.0f;\n        }\n        else\n        {\n            _3584 = _3578;\n        }\n        if (_3584)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3553.direction;\n            float _3603 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4629 = _3603;\n            _4627 *= _3603;\n        }\n    }\n    bool _3613 = _386_fa_ct_a.x > 0.5f;\n    bool _3619;\n    if (_3613)\n    {\n        _3619 = _3553.attenuation > 0.0f;\n    }\n    else\n    {\n        _3619 = _3613;\n    }\n    if (_3619)\n    {\n        float _3626;\n        if (_3556)\n        {\n            _3626 = 1000000000.0f;\n        }\n        else\n        {\n            _3626 = _3553._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3553.direction;\n        float param_18 = _3626;\n        float _3644 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _4629 *= _3644;\n        _4627 *= _3644;\n    }\n    LightSample _4644 = { _3553.direction, _4627, _3553.attenuation, _4629, _3553._distance, _3553.type };\n    return _4644;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _3667;\n    if (dot(s.normal, l.direction) > 0.5f)\n    {\n        _3667 = 1.0f;\n    }\n    else\n    {\n        _3667 = _3673_dark;\n    }\n    return (s.albedo * l.color) * _3667;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2043_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2979 = int(_2043_fa_shadow_cfg.x + 0.5f);\n    float _2989 = dot(world - _2043_fa_shadow_eye.xyz, _2043_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2994 = _2979 > 0;\n    bool _3003;\n    if (_2994)\n    {\n        int param = _2979 - 1;\n        _3003 = _2989 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3003 = _2994;\n    }\n    if (_3003)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3009 = _2979 > 1;\n        bool _3016;\n        if (_3009)\n        {\n            _3016 = _2989 > _2043_fa_shadow_split.x;\n        }\n        else\n        {\n            _3016 = _3009;\n        }\n        if (_3016)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3022 = _2979 > 2;\n        bool _3029;\n        if (_3022)\n        {\n            _3029 = _2989 > _2043_fa_shadow_split.y;\n        }\n        else\n        {\n            _3029 = _3022;\n        }\n        if (_3029)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3035 = _2979 > 3;\n        bool _3042;\n        if (_3035)\n        {\n            _3042 = _2989 > _2043_fa_shadow_split.z;\n        }\n        else\n        {\n            _3042 = _3035;\n        }\n        if (_3042)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4468 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4468 = -_4468;\n    }\n    float3 _4054 = normalize(_386_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4481 = { fa_world_pos, _4468, fa_world_tangent, fa_uv, fa_vertex_color, _4054, gl_FrontFacing };\n    SurfaceInput param_1 = _4481;\n    Surface _4062 = fa_standard_surface(param_1);\n    float3 _4499 = _4062.albedo;\n    float _4500 = _4062.alpha;\n    float3 _4501 = _4062.normal;\n    float _4502 = _4062.metallic;\n    float _4503 = _4062.roughness;\n    float _4504 = _4062.occlusion;\n    float3 _4505 = _4062.emission;\n    float _4506 = _4062.clearcoat;\n    float _4507 = _4062.clearcoat_roughness;\n    float3 _4508 = _4062.sheen_color;\n    float _4509 = _4062.sheen_roughness;\n    float _4510 = _4062.anisotropy;\n    float _4511 = _4062.anisotropy_rotation;\n    float _4512 = _4062.specular;\n    float _4513 = _4062.ior;\n    float3 _4514 = _4062.specular_color;\n    SurfaceInput _4489 = { fa_world_pos, _4468, fa_world_tangent, fa_uv, fa_vertex_color, _4054, gl_FrontFacing };\n    SurfaceInput param_2 = _4489;\n    Surface param_3 = _4062;\n    surface(param_2, param_3);\n    _4499 = param_3.albedo;\n    _4500 = param_3.alpha;\n    _4501 = param_3.normal;\n    _4502 = param_3.metallic;\n    _4503 = param_3.roughness;\n    _4504 = param_3.occlusion;\n    _4505 = param_3.emission;\n    _4506 = param_3.clearcoat;\n    _4507 = param_3.clearcoat_roughness;\n    _4508 = param_3.sheen_color;\n    _4509 = param_3.sheen_roughness;\n    _4510 = param_3.anisotropy;\n    _4511 = param_3.anisotropy_rotation;\n    _4512 = param_3.specular;\n    _4513 = param_3.ior;\n    _4514 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4468;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4499 = param_6;\n    _4501 = param_7;\n    float3 result;\n    if (_386_fa_emissive.w > 0.5f)\n    {\n        result = _4499;\n    }\n    else\n    {\n        float3 _4100 = _4501;\n        float3 _4101 = normalize(_4100);\n        _4501 = _4101;\n        float3 param_8 = _4101;\n        float3 lit = (fa_indirect_diffuse(param_8) * _4499) * _4504;\n        int _4120 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4120; ln++)\n        {\n            int param_9 = ln;\n            int _4133 = fa_cl_light(param_9);\n            bool _4136 = fa_lm.z > 0.5f;\n            bool _4142;\n            if (_4136)\n            {\n                int param_10 = _4133;\n                _4142 = fa_light_baked(param_10);\n            }\n            else\n            {\n                _4142 = _4136;\n            }\n            if (_4142)\n            {\n                continue;\n            }\n            int param_11 = _4133;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _4468;\n            LightSample _4154 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput _4497 = { fa_world_pos, _4468, fa_world_tangent, fa_uv, fa_vertex_color, _4054, gl_FrontFacing };\n            SurfaceInput param_14 = _4497;\n            Surface _4580 = { _4499, _4500, _4501, _4502, _4503, _4504, _4505, _4506, _4507, _4508, _4509, _4510, _4511, _4512, _4513, _4514 };\n            Surface param_15 = _4580;\n            LightSample param_16 = _4154;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _4169 = result;\n    float3 _4170 = _4169 + _4505;\n    result = _4170;\n    float3 param_17 = _4170;\n    float3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _4179 = _386_fa_fog.w > 0.0f;\n    bool _4186;\n    if (!_4179)\n    {\n        _4186 = _386_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4186 = _4179;\n    }\n    if (_4186)\n    {\n        float3 _4195 = fa_world_pos - _386_fa_camera_pos.xyz;\n        float _4201 = dot(_4195, _386_fa_fog_c.xyz);\n        bool _4205 = _386_fa_fog_c.w > 0.5f;\n        float _4206;\n        if (_4205)\n        {\n            _4206 = _4201;\n        }\n        else\n        {\n            _4206 = length(_4195);\n        }\n        float _4218 = _4206 - _386_fa_fog_b.x;\n        if (_4218 > 0.0f)\n        {\n            float _4227 = _386_fa_fog.w * _4218;\n            float tau = _4227 * _4227;\n            if (_386_fa_fog_b.y > 0.0f)\n            {\n                float _4243;\n                if (_4205)\n                {\n                    _4243 = fa_world_pos.y - (_386_fa_fog_c.y * _4201);\n                }\n                else\n                {\n                    _4243 = _386_fa_camera_pos.y;\n                }\n                float _4264 = lerp(_4243, fa_world_pos.y, clamp(_386_fa_fog_b.x / _4206, 0.0f, 1.0f));\n                float _4268 = fa_world_pos.y - _4264;\n                float _4273 = _4264 - _386_fa_fog_b.z;\n                float _4278 = fa_world_pos.y - _386_fa_fog_b.z;\n                bool _4281 = _4273 <= 0.0f;\n                bool _4282 = !_4281;\n                bool _4288;\n                if (_4282)\n                {\n                    _4288 = _386_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4288 = _4281;\n                }\n                float _4289;\n                if (_4288)\n                {\n                    _4289 = _386_fa_fog_b.y;\n                }\n                else\n                {\n                    _4289 = _386_fa_fog_b.y * exp(-min(_386_fa_fog_b.w * _4273, 80.0f));\n                }\n                bool _4316;\n                if (_4282)\n                {\n                    _4316 = _386_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4316 = _4281;\n                }\n                float _4317;\n                if (_4316)\n                {\n                    _4317 = _386_fa_fog_b.y * _4273;\n                }\n                else\n                {\n                    _4317 = (_386_fa_fog_b.y * (1.0f - exp(-min(_386_fa_fog_b.w * _4273, 80.0f)))) / _386_fa_fog_b.w;\n                }\n                bool _4342 = _4278 <= 0.0f;\n                bool _4349;\n                if (!_4342)\n                {\n                    _4349 = _386_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4349 = _4342;\n                }\n                float _4350;\n                if (_4349)\n                {\n                    _4350 = _386_fa_fog_b.y * _4278;\n                }\n                else\n                {\n                    _4350 = (_386_fa_fog_b.y * (1.0f - exp(-min(_386_fa_fog_b.w * _4278, 80.0f)))) / _386_fa_fog_b.w;\n                }\n                float _4377;\n                if (abs(_4268) < 0.001000000047497451305389404296875f)\n                {\n                    _4377 = _4289;\n                }\n                else\n                {\n                    _4377 = (_4350 - _4317) / _4268;\n                }\n                tau += (_4218 * max(_4377, 0.0f));\n            }\n            result = lerp(result, _386_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4500);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_386",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2043",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3673",
            "hlsl_register_b_n": 5
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _384 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _384;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_391, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _386_fa_camera_pos : packoffset(c0);\n    float4 _386_fa_ambient : packoffset(c1);\n    float4 _386_fa_base_color : packoffset(c2);\n    float4 _386_fa_emissive : packoffset(c3);\n    float4 _386_fa_model_emissive : packoffset(c4);\n    float4 _386_fa_pbr : packoffset(c5);\n    float4 _386_fa_maps : packoffset(c6);\n    float4 _386_fa_fog : packoffset(c7);\n    float4 _386_fa_fog_b : packoffset(c8);\n    float4 _386_fa_fog_c : packoffset(c9);\n    float4 _386_fa_counts : packoffset(c10);\n    float4 _386_fa_env_sky : packoffset(c11);\n    float4 _386_fa_env_horizon : packoffset(c12);\n    float4 _386_fa_time : packoffset(c13);\n    float4 _386_fa_cl_vpx : packoffset(c14);\n    float4 _386_fa_cl_vpy : packoffset(c15);\n    float4 _386_fa_cl_vpw : packoffset(c16);\n    float4 _386_fa_cl_fwd : packoffset(c17);\n    float4 _386_fa_cl_grid : packoffset(c18);\n    float4 _386_fa_cl_info : packoffset(c19);\n    float4 _386_fa_layers_a : packoffset(c20);\n    float4 _386_fa_layers_b : packoffset(c21);\n    float4 _386_fa_layers_c : packoffset(c22);\n    float4 _386_fa_layers_d : packoffset(c23);\n    float4 _386_fa_ct_a : packoffset(c24);\n    float4 _386_fa_ct_b : packoffset(c25);\n    float4 _386_fa_ct_vpx : packoffset(c26);\n    float4 _386_fa_ct_vpy : packoffset(c27);\n    float4 _386_fa_ct_vpw : packoffset(c28);\n    float4 _386_fa_ct_fwd : packoffset(c29);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2043_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2043_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2043_fa_shadow_info[4] : packoffset(c20);\n    float4 _2043_fa_shadow_split : packoffset(c24);\n    float4 _2043_fa_shadow_cfg : packoffset(c25);\n    float4 _2043_fa_shadow_bias : packoffset(c26);\n    float4 _2043_fa_shadow_eye : packoffset(c27);\n    float4 _2043_fa_shadow_fwd : packoffset(c28);\n    float4 _2043_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _3673_dark : packoffset(c0);\n    float _3673_fa_pad0 : packoffset(c0.y);\n    float _3673_fa_pad1 : packoffset(c0.z);\n    float _3673_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1314 = _386_fa_cl_info.x < 0.0f;\n    bool _1321;\n    if (!_1314)\n    {\n        _1321 = _386_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1321 = _1314;\n    }\n    bool _1329;\n    if (!_1321)\n    {\n        _1329 = _386_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1329 = _1321;\n    }\n    bool _1336;\n    if (!_1329)\n    {\n        _1336 = _386_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1336 = _1329;\n    }\n    bool _1343;\n    if (!_1336)\n    {\n        _1343 = _386_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1343 = _1336;\n    }\n    if (_1343)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1353 = float4(world_pos, 1.0f);\n    float _1359 = dot(_386_fa_cl_vpw, _1353);\n    if (!(_1359 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1381 = float2(dot(_386_fa_cl_vpx, _1353), dot(_386_fa_cl_vpy, _1353)) / _1359.xx;\n    int _1385 = int(_386_fa_cl_grid.x);\n    int _1389 = int(_386_fa_cl_grid.y);\n    int param = (int(_386_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_386_fa_cl_fwd.xyz, world_pos) + _386_fa_cl_fwd.w, _386_fa_cl_grid.w) / _386_fa_cl_grid.w) * _386_fa_cl_grid.z)), 0, int(_386_fa_cl_info.y) - 1) * _1389) + clamp(int(floor(((_1381.y * 0.5f) + 0.5f) * _386_fa_cl_grid.y)), 0, _1389 - 1)) * _1385)) + clamp(int(floor(((_1381.x * 0.5f) + 0.5f) * _386_fa_cl_grid.x)), 0, _1385 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1465 = fa_cluster_texel(param);\n    return int2(int(_1465.x), int(_1465.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_386_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3496 = fa_cluster_lookup(param);\n    fa_cl_slot = _3496.x;\n    fa_cl_local = _3496.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3722 = fa_linear_to_srgb(param);\n        c = _3722;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3730 = fa_srgb_to_linear(param_1);\n            c = _3730;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _269;\n    if (i.front_facing)\n    {\n        _269 = i.world_normal;\n    }\n    else\n    {\n        _269 = -i.world_normal;\n    }\n    float3 _293 = normalize(i.world_tangent.xyz - (_269 * dot(_269, i.world_tangent.xyz)));\n    float3 _320 = normalize(((_293 * m.x) + ((cross(_269, _293) * i.world_tangent.w) * m.y)) + (_269 * m.z));\n    float3 _323;\n    if (i.front_facing)\n    {\n        _323 = _320;\n    }\n    else\n    {\n        _323 = -_320;\n    }\n    return _323;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _386_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3761 = fa_tex_fix(param_2, param_3);\n    float4 _4795 = base_t;\n    _4795.x = _3761.x;\n    _4795.y = _3761.y;\n    _4795.z = _3761.z;\n    base_t = _4795;\n    float4 _3775 = (_4795 * _386_fa_base_color) * i.vertex_color;\n    float3 _4647 = i.world_normal;\n    if (_386_fa_maps.z > 0.5f)\n    {\n        float param_4 = _386_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3807 = fa_tex_fix(param_6, param_7);\n        float3 _3810 = (_3807 * 2.0f) - 1.0f.xxx;\n        float2 _3815 = _3810.xy * _386_fa_maps.x;\n        float3 _4803 = _3810;\n        _4803.x = _3815.x;\n        _4803.y = _3815.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4803;\n        _4647 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _386_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3843 = fa_tex_fix(param_12, param_13);\n    float4 _4806 = mrt;\n    _4806.x = _3843.x;\n    _4806.y = _3843.y;\n    _4806.z = _3843.z;\n    mrt = _4806;\n    float4 _3871 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _386_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _3871.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _3882 = fa_tex_fix(param_16, param_17);\n    float param_18 = _386_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _3912 = fa_tex_fix(param_20, param_21);\n    float _4652 = _386_fa_layers_a.x;\n    float _4653 = _386_fa_layers_a.y;\n    float _4656 = _386_fa_layers_a.z;\n    float _4655 = _386_fa_layers_b.w;\n    float _4658 = _386_fa_layers_c.x;\n    if (_386_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_386_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4652 *= _3882.y;\n            _4653 *= _3882.z;\n            _4655 *= _3871.w;\n        }\n        if (_386_fa_layers_c.z > 1.5f)\n        {\n            _4656 *= mrt.x;\n            _4658 *= mrt.w;\n        }\n    }\n    Surface _4677 = { _3775.xyz, _3775.w, _4647, clamp(_386_fa_pbr.x * _3843.z, 0.0f, 1.0f), clamp(_386_fa_pbr.y * _3843.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_386_fa_maps.y * (_3882.x - 1.0f)), _386_fa_emissive.xyz + (_386_fa_model_emissive.xyz * _3912), _4652, _4653, _386_fa_layers_b.xyz, _4655, _4656, _386_fa_layers_a.w, _4658, _386_fa_layers_c.y, _386_fa_layers_d.xyz };\n    return _4677;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1545 = rect.zw - rect.xy;\n    float2 _1549 = _1545 * atlas;\n    float2 _1553 = ddx * _1549;\n    float2 _1557 = ddy * _1549;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1545), clamp(0.5f * log2(max(max(dot(_1553, _1553), dot(_1557, _1557)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1590 = _386_fa_counts.y < 0.5f;\n    bool _1597;\n    if (!_1590)\n    {\n        _1597 = _386_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1597 = _1590;\n    }\n    if (_1597)\n    {\n        return;\n    }\n    float3 _1603 = ddx(world_pos);\n    float3 _1606 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1610 = fa_cluster_texel(param);\n    int _1614 = int(_1610.w);\n    if (_1614 < 1)\n    {\n        return;\n    }\n    int _1624 = int(_386_fa_counts.y + 0.5f);\n    int param_1 = _1624;\n    float4 _1628 = fa_light_texel(param_1);\n    float2 _1631 = _1628.yz;\n    int _1635 = int(_1628.w);\n    int param_2 = _1624 + 1;\n    float4 _1640 = fa_light_texel(param_2);\n    float _1641 = _1640.x;\n    int _1647 = int(_386_fa_counts.w + 0.5f) - 1;\n    int _1651 = int(_1610.z);\n    float3 _1916;\n    for (int k = 0; k < _1614; k++)\n    {\n        int _1664 = _1651 + k;\n        int param_3 = _1635 + (_1664 >> 2);\n        int _1681 = (_1624 + 2) + (int(fa_light_texel(param_3)[_1664 & 3]) * 7);\n        int param_4 = _1681 + 6;\n        float4 _1686 = fa_light_texel(param_4);\n        if (((int(_1686.w + 0.5f) >> _1647) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1681;\n        float4 _1701 = fa_light_texel(param_5);\n        int param_6 = _1681 + 1;\n        float4 _1706 = fa_light_texel(param_6);\n        int param_7 = _1681 + 2;\n        float4 _1711 = fa_light_texel(param_7);\n        float3 _1714 = _1701.xyz;\n        float _1719 = dot(_1714, world_pos) + _1701.w;\n        float3 _1721 = _1706.xyz;\n        float _1726 = dot(_1721, world_pos) + _1706.w;\n        float3 _1728 = _1711.xyz;\n        float _1733 = dot(_1728, world_pos) + _1711.w;\n        bool _1738 = abs(_1719) > 0.5f;\n        bool _1746;\n        if (!_1738)\n        {\n            _1746 = abs(_1726) > 0.5f;\n        }\n        else\n        {\n            _1746 = _1738;\n        }\n        bool _1754;\n        if (!_1746)\n        {\n            _1754 = abs(_1733) > 0.5f;\n        }\n        else\n        {\n            _1754 = _1746;\n        }\n        if (_1754)\n        {\n            continue;\n        }\n        float _1769 = clamp(dot(geo_normal, normalize(_1728)) * _1686.z, 0.0f, 1.0f);\n        if (_1769 <= 0.0f)\n        {\n            continue;\n        }\n        float _1789 = (clamp((0.5f - abs(_1733)) * 10.0f, 0.0f, 1.0f) * _1769) * _1686.x;\n        float2 _1797 = float2(_1719 + 0.5f, 0.5f - _1726);\n        float2 _1807 = float2(dot(_1714, _1603), dot(_1721, _1603));\n        float2 _1817 = float2(dot(_1714, _1606), dot(_1721, _1606));\n        int param_8 = _1681 + 5;\n        float4 _1822 = fa_light_texel(param_8);\n        int param_9 = _1681 + 3;\n        float4 _1827 = fa_light_texel(param_9);\n        int param_10 = _1681 + 4;\n        float4 _1832 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1822.xyz;\n        bool _1842 = _1827.z > _1827.x;\n        if (_1842)\n        {\n            float4 param_11 = _1827;\n            float2 param_12 = _1797;\n            float2 param_13 = _1631;\n            float2 param_14 = _1807;\n            float2 param_15 = _1817;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1641 > 0.5f) && (_1641 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1868 = fa_dc_to_linear(param_16);\n                float4 _4727 = tx;\n                _4727.x = _1868.x;\n                _4727.y = _1868.y;\n                _4727.z = _1868.z;\n                tx = _4727;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1789 * tex_a) * _1822.w, 0.0f, 1.0f).xxx);\n        if (_1832.z > _1832.x)\n        {\n            float4 param_17 = _1832;\n            float2 param_18 = _1797;\n            float2 param_19 = _1631;\n            float2 param_20 = _1807;\n            float2 param_21 = _1817;\n            float4 _1912 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1641 > 1.5f)\n            {\n                float3 param_22 = _1912.xyz;\n                float3 _1922 = fa_dc_to_srgb(param_22);\n                _1916 = _1922;\n            }\n            else\n            {\n                _1916 = _1912.xyz;\n            }\n            float3 _1931 = (_1916 * 2.0f) - 1.0f.xxx;\n            float2 _1936 = _1931.xy * _1686.y;\n            float3 _1958 = (normalize(_1714) * _1936.x) + (normalize(_1721) * _1936.y);\n            float3 _1961 = normalize(normal);\n            normal = normalize(lerp(_1961, normalize((_1961 * max(_1931.z, 0.0500000007450580596923828125f)) + (_1958 - (_1961 * dot(_1961, _1958)))), clamp(_1789 * (_1842 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_sky_sh_coef(int k)\n{\n    float3 v = fa_env_tex.SampleLevel(fa_env_smp, float3(1.0f, 1.0f - (float((2 * (k >> 2)) + 1) * 0.25f), 1.0f - (float((2 * (k & 3)) + 1) * 0.25f)), 5.0f).xyz;\n    if (_386_fa_env_sky.w > 1.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3156 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3156;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    if (_386_fa_env_sky.w > 0.5f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return _386_fa_ambient.xyz;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    float3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_386_fa_cl_info.x) + int(_386_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_386_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _445_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _445_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _564 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _577 = (c - (ru * hx)) - p;\n        float3 _583 = ru * (2.0f * hx);\n        float _589 = max(dot(_583, _583), 9.9999999392252902907785028219223e-09f);\n        float _593 = dot(_577, _583);\n        float t = clamp((-_593) / _589, 0.0f, 1.0f);\n        if (_564)\n        {\n            float _608 = dot(r, _583);\n            float _614 = _589 - (_608 * _608);\n            if (abs(_614) > (9.9999997473787516355514526367188e-06f * _589))\n            {\n                t = clamp(((dot(r, _577) * _608) - _593) / _614, 0.0f, 1.0f);\n            }\n        }\n        return (p + _577) + (_583 * t);\n    }\n    float3 q = p;\n    float _646 = dot(r, axis);\n    bool _654;\n    if (_564)\n    {\n        _654 = abs(_646) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _654 = _564;\n    }\n    if (_654)\n    {\n        float _664 = dot(c - p, axis) / _646;\n        if (_664 > 0.0f)\n        {\n            q = p + (r * _664);\n        }\n    }\n    float3 _677 = q - c;\n    float2 xy = float2(dot(_677, ru), dot(_677, uu));\n    if (shape > 0.5f)\n    {\n        float _692 = length(xy);\n        if (_692 > hx)\n        {\n            xy *= (hx / _692);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _335 = abs(d);\n    float _337 = _335.x;\n    float _339 = _335.y;\n    bool _340 = _337 >= _339;\n    bool _348;\n    if (_340)\n    {\n        _348 = _337 >= _335.z;\n    }\n    else\n    {\n        _348 = _340;\n    }\n    int _349;\n    if (_348)\n    {\n        _349 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _364;\n        if (_339 >= _335.z)\n        {\n            _364 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _364 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _349 = _364;\n    }\n    return _349;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _484 = dot(d, right);\n    float _488 = dot(d, up);\n    float _499;\n    if (((_484 * _484) + (_488 * _488)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _499 = atan2(_488, _484) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _499 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_499 - floor(_499)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _730 = fa_light_base(param);\n    bool _734 = _386_fa_ambient.w > 4.5f;\n    int param_1 = _730;\n    float4 _738 = fa_light_texel(param_1);\n    int param_2 = _730 + 1;\n    float4 _743 = fa_light_texel(param_2);\n    float _746 = _743.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _758 = _734 && (_746 > 2.5f);\n    fa_light_is_area = _758;\n    bool _760 = _746 < 0.5f;\n    float3 l;\n    if (_760)\n    {\n        l = normalize(_738.xyz);\n        if (_734)\n        {\n            int param_3 = _730 + 6;\n            float4 _774 = fa_light_texel(param_3);\n            if (_774.z > 0.5f)\n            {\n                int param_4 = _730 + 4;\n                float4 _784 = fa_light_texel(param_4);\n                int param_5 = _730 + 5;\n                float4 _789 = fa_light_texel(param_5);\n                float2 param_6 = _774.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _784.xyz) * _784.w, (-dot(world_pos, _789.xyz)) * _789.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _819 = _738.xyz;\n        float3 _821 = _819 - world_pos;\n        float3 to_light = _821;\n        float _824 = length(_821);\n        float reach = _824;\n        bool front = true;\n        if (_758)\n        {\n            int param_8 = _730 + 7;\n            reach = max(_824 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _730 + 4;\n            float4 _848 = fa_light_texel(param_9);\n            int param_10 = _730 + 5;\n            float4 _853 = fa_light_texel(param_10);\n            int param_11 = _730 + 6;\n            float4 _858 = fa_light_texel(param_11);\n            float _859 = _858.w;\n            int param_12 = _730 + 2;\n            float3 _866 = normalize(fa_light_texel(param_12).xyz);\n            bool _868 = _859 > 1.5f;\n            bool _876;\n            if (!_868)\n            {\n                _876 = dot(_866, to_light) < 0.0f;\n            }\n            else\n            {\n                _876 = _868;\n            }\n            front = _876;\n            float3 r = 0.0f.xxx;\n            float3 _885 = _386_fa_camera_pos.xyz - world_pos;\n            bool _889 = dot(n, n) > 0.5f;\n            bool _897;\n            if (_889)\n            {\n                _897 = dot(_885, _885) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _897 = _889;\n            }\n            if (_897)\n            {\n                r = reflect(-normalize(_885), normalize(n));\n            }\n            float3 param_13 = _819;\n            float3 param_14 = _866;\n            float3 param_15 = _848.xyz;\n            float3 param_16 = _853.xyz;\n            float param_17 = _848.w;\n            float param_18 = _853.w;\n            float param_19 = _859;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _933 = length(to_light);\n        dist = _933;\n        l = to_light / max(_933, 9.9999997473787516355514526367188e-05f).xxx;\n        float _947 = reach / max(_738.w, 0.001000000047497451305389404296875f);\n        float _953 = clamp(1.0f - (_947 * _947), 0.0f, 1.0f);\n        float _955;\n        if (front)\n        {\n            _955 = _953 * _953;\n        }\n        else\n        {\n            _955 = 0.0f;\n        }\n        atten = _955;\n        bool _966 = _746 < 2.5f;\n        if ((_746 > 1.5f) && _966)\n        {\n            int param_22 = _730 + 2;\n            float4 _974 = fa_light_texel(param_22);\n            float _984 = _974.w;\n            int param_23 = _730 + 3;\n            float4 _989 = fa_light_texel(param_23);\n            float _990 = _989.x;\n            float cos_inner = _990;\n            if (_990 > 1.5f)\n            {\n                cos_inner = lerp(_984, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_984, cos_inner, dot(-l, normalize(_974.xyz)));\n        }\n        if (_734 && (_746 < 1.5f))\n        {\n            int param_24 = _730 + 6;\n            float4 _1014 = fa_light_texel(param_24);\n            if (_1014.z > 0.5f)\n            {\n                float3 _1022 = -to_light;\n                int param_25 = _730 + 4;\n                int param_26 = _730 + 5;\n                float3 _1036 = fa_light_texel(param_25).xyz;\n                float3 _1040 = fa_light_texel(param_26).xyz;\n                float3 _1049 = float3(dot(_1022, _1036), dot(_1022, _1040), dot(_1022, cross(_1036, _1040)));\n                float3 param_27 = _1049;\n                int _1053 = fa_cube_face(param_27);\n                int param_28 = _1053;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1080 = float2(dot(_1049, cross(param_29, param_30)), dot(_1049, param_30)) / max(dot(_1049, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1084 = _1053 / 3;\n                float2 param_31 = _1014.xy + (float2(float(_1053 - (_1084 * 3)), float(_1084)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1080.x), 0.5f - (0.5f * _1080.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _730 + 7;\n            float4 _1114 = fa_light_texel(param_33);\n            if (_1114.z > 0.5f)\n            {\n                int param_34 = _730 + 2;\n                int param_35 = _730 + 4;\n                int param_36 = _730 + 5;\n                float2 param_37 = _1114.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_734 && _966)\n            {\n                int param_42 = _730 + 6;\n                float4 _1161 = fa_light_texel(param_42);\n                int param_43 = _730 + 7;\n                float4 _1166 = fa_light_texel(param_43);\n                bool _1169 = _1161.z > 0.5f;\n                bool _1176;\n                if (!_1169)\n                {\n                    _1176 = _1166.z > 0.5f;\n                }\n                else\n                {\n                    _1176 = _1169;\n                }\n                if (_1176)\n                {\n                    int param_44 = _730 + 2;\n                    float4 _1183 = fa_light_texel(param_44);\n                    float3 _1187 = normalize(_1183.xyz);\n                    int param_45 = _730 + 4;\n                    float4 _1192 = fa_light_texel(param_45);\n                    int param_46 = _730 + 5;\n                    float4 _1197 = fa_light_texel(param_46);\n                    if (_1169)\n                    {\n                        float3 _1205 = -to_light;\n                        float _1212 = _1183.w;\n                        float _1228 = 0.5f / max(dot(_1205, _1187) * (sqrt(max(1.0f - (_1212 * _1212), 0.0f)) / max(_1212, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1161.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1205, _1192.xyz) * _1228), 0.5f - (dot(_1205, _1197.xyz) * _1228));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1166.z > 0.5f)\n                    {\n                        float2 param_49 = _1166.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1187;\n                        float3 param_52 = _1192.xyz;\n                        float3 param_53 = _1197.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4601 = _743.xyz * atten;\n    if (_734)\n    {\n        _4601 *= fa_light_tint;\n    }\n    int _1296;\n    if (_760)\n    {\n        _1296 = 0;\n    }\n    else\n    {\n        _1296 = ((_746 > 1.5f) && (_746 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4612 = { l, _4601, atten, 1.0f, dist, _1296 };\n    return _4612;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2033;\n    if (i == 0)\n    {\n        _2033 = _2043_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2049;\n        if (i == 1)\n        {\n            _2049 = _2043_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2057;\n            if (i == 2)\n            {\n                _2057 = _2043_fa_shadow_split.z;\n            }\n            else\n            {\n                _2057 = _2043_fa_shadow_split.w;\n            }\n            _2049 = _2057;\n        }\n        _2033 = _2049;\n    }\n    return _2033;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2090 = fa_shadow_depth(param, param_1);\n    float _2094;\n    if (conv.x < 0.5f)\n    {\n        _2094 = _2090;\n    }\n    else\n    {\n        _2094 = (conv.y * conv.z) / (conv.z - (_2090 * (conv.z - conv.y)));\n    }\n    return _2094;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2021 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2021), sin(_2021)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2140 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2149;\n        if (k < 0.0f)\n        {\n            _2149 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2149 = k;\n        }\n        float _2169 = clamp((_2149 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2140;\n            float2 _2188 = fa_shadow_vogel(param_3, param_4, param_5) * _2169;\n            float2 param_6 = uv + (_2188 * _2043_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2200 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2200 < (zr - (length(_2188) * plane)))\n            {\n                sum += _2200;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2226 = sum / cnt;\n        float _2236;\n        if (k < 0.0f)\n        {\n            _2236 = (-k) / max(_2226, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2236 = k;\n        }\n        radius = clamp(((max(zr - _2226, 0.0f) * unit) * _2236) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2258 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2258; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2258;\n        float param_11 = _2140;\n        float2 _2277 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2277 * _2043_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2277) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2258);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2319 = max(_2043_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2324 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2330 = sqrt(1.0f - (_2324 * _2324));\n    float _2337 = min(_2330 / max(_2324, 0.20000000298023223876953125f), 4.0f);\n    float _2342;\n    if (_2043_fa_shadow_bias.y > 0.0f)\n    {\n        _2342 = _2043_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2342 = 1.5f * _2043_fa_shadow_info[ci].x;\n    }\n    float4 _2367 = mul(float4(world + (n * (_2342 * _2330)), 1.0f), _2043_fa_shadow_mat[ci]);\n    float _2374 = _2367.x;\n    bool _2377 = _2374 < _2043_fa_shadow_rect[ci].x;\n    bool _2386;\n    if (!_2377)\n    {\n        _2386 = _2374 > _2043_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2386 = _2377;\n    }\n    bool _2395;\n    if (!_2386)\n    {\n        _2395 = _2367.y < _2043_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2395 = _2386;\n    }\n    bool _2404;\n    if (!_2395)\n    {\n        _2404 = _2367.y > _2043_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2404 = _2395;\n    }\n    bool _2411;\n    if (!_2404)\n    {\n        _2411 = _2367.z > 1.0f;\n    }\n    else\n    {\n        _2411 = _2404;\n    }\n    if (_2411)\n    {\n        return -1.0f;\n    }\n    float _2419;\n    if (_2043_fa_shadow_bias.x > 0.0f)\n    {\n        _2419 = _2043_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2419 = 1.5f * _2043_fa_shadow_info[ci].x;\n    }\n    float2 param = _2367.xy;\n    float4 param_1 = _2043_fa_shadow_rect[ci];\n    float param_2 = _2367.z - ((_2419 * (1.0f + (0.5f * _2337))) / _2319);\n    float param_3 = _2043_fa_shadow_info[ci].x;\n    float param_4 = _2319;\n    float param_5 = _2319 * 0.25f;\n    float param_6 = ((_2043_fa_shadow_info[ci].x * min(_2337, 3.0f)) * 0.5f) / _2319;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2043_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2043_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_386_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2797 = int(_2043_fa_shadow_cfg.x + 0.5f);\n    if (_2797 < 1)\n    {\n        return 1.0f;\n    }\n    float _2812 = dot(world - _2043_fa_shadow_eye.xyz, _2043_fa_shadow_fwd.xyz);\n    int param = _2797 - 1;\n    if (_2812 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2824 = _2797 > 1;\n    bool _2831;\n    if (_2824)\n    {\n        _2831 = _2812 > _2043_fa_shadow_split.x;\n    }\n    else\n    {\n        _2831 = _2824;\n    }\n    if (_2831)\n    {\n        ci = 1;\n    }\n    bool _2835 = _2797 > 2;\n    bool _2842;\n    if (_2835)\n    {\n        _2842 = _2812 > _2043_fa_shadow_split.y;\n    }\n    else\n    {\n        _2842 = _2835;\n    }\n    if (_2842)\n    {\n        ci = 2;\n    }\n    bool _2846 = _2797 > 3;\n    bool _2853;\n    if (_2846)\n    {\n        _2853 = _2812 > _2043_fa_shadow_split.z;\n    }\n    else\n    {\n        _2853 = _2846;\n    }\n    if (_2853)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2797)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2879 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2879;\n        if (_2879 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2043_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2904;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2904 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2904 = _2043_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2923 = _2043_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2904, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2934 = clamp((_2812 - (fa_shadow_split_at(param_7) - _2923)) / _2923, 0.0f, 1.0f);\n        if (_2934 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2797)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2955 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2955;\n                if (_2955 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2934);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2477 = _386_fa_pbr.z < 0.5f;\n    bool _2484;\n    if (!_2477)\n    {\n        _2484 = _2043_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2484 = _2477;\n    }\n    if (_2484)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2043_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2497 = fa_light_texel(param);\n    float _2498 = _2497.x;\n    if (_2498 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2507 = int(_2498 + 0.5f);\n    int param_1 = _2507;\n    float4 _2511 = fa_light_texel(param_1);\n    int param_2 = _2507 + 1;\n    float4 _2516 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2519 = _2511.y;\n    if (_2519 > 0.0f)\n    {\n        float _2536 = 1.0f - smoothstep(0.75f * _2519, _2519, length(world - _2043_fa_shadow_eye.xyz));\n        fade = _2536;\n        if (_2536 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2511.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2560 = (_2507 + 2) + (face * 6);\n    int param_4 = _2560;\n    int param_5 = _2560 + 1;\n    int param_6 = _2560 + 3;\n    float4 _2574 = fa_light_texel(param_6);\n    int param_7 = _2560 + 4;\n    float4 _2579 = fa_light_texel(param_7);\n    int param_8 = _2560 + 5;\n    float4 _2584 = fa_light_texel(param_8);\n    float _2596 = _2584.x * max(dot(_2574, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2601 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2624 = clamp(dot(n, _2574.xyz), -1.0f, 1.0f);\n    float _2643 = min(sqrt(1.0f - (_2624 * _2624)) / max(abs(dot(n, world - lpos)) / max(dot(_2574, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2646 = _2516.y;\n    float _2648;\n    if (_2646 > 0.0f)\n    {\n        _2648 = _2646;\n    }\n    else\n    {\n        _2648 = 1.5f * _2596;\n    }\n    float4 _2668 = float4(world + (n * (_2648 * sqrt(1.0f - (_2601 * _2601)))), 1.0f);\n    float _2672 = dot(_2574, _2668);\n    float _2675 = _2584.y;\n    if (_2672 < _2675)\n    {\n        return 1.0f;\n    }\n    float2 _2690 = float2(dot(fa_light_texel(param_4), _2668), dot(fa_light_texel(param_5), _2668)) / _2672.xx;\n    float _2692 = _2690.x;\n    bool _2695 = _2692 < _2579.x;\n    bool _2704;\n    if (!_2695)\n    {\n        _2704 = _2692 > _2579.z;\n    }\n    else\n    {\n        _2704 = _2695;\n    }\n    bool _2713;\n    if (!_2704)\n    {\n        _2713 = _2690.y < _2579.y;\n    }\n    else\n    {\n        _2713 = _2704;\n    }\n    bool _2722;\n    if (!_2713)\n    {\n        _2722 = _2690.y > _2579.w;\n    }\n    else\n    {\n        _2722 = _2713;\n    }\n    if (_2722)\n    {\n        return 1.0f;\n    }\n    float _2728 = _2516.x;\n    float _2730;\n    if (_2728 > 0.0f)\n    {\n        _2730 = _2728;\n    }\n    else\n    {\n        _2730 = 1.5f * _2596;\n    }\n    float2 param_9 = _2690;\n    float4 param_10 = _2579;\n    float param_11 = _2672 - (_2730 * (1.0f + (0.5f * _2643)));\n    float param_12 = _2596;\n    float param_13 = 1.0f;\n    float param_14 = _2584.z * 0.25f;\n    float param_15 = (_2596 * min(_2643, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2675, _2584.z);\n    int param_17 = int(_2511.z + 0.5f);\n    float param_18 = _2511.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3236 = _386_fa_ct_a.x < 0.5f;\n    bool _3243;\n    if (!_3236)\n    {\n        _3243 = _2043_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3243 = _3236;\n    }\n    if (_3243)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2043_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3256 = fa_light_texel(param);\n    float _3257 = _3256.y;\n    float len = _3257;\n    if (_3257 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3269 = length(world - _386_fa_camera_pos.xyz);\n    float _3279 = 1.0f - smoothstep(0.5f * _386_fa_ct_b.x, _386_fa_ct_b.x, _3269);\n    if (_3279 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3285 = len;\n    float _3288 = min(_3285, 0.89999997615814208984375f * dist);\n    len = _3288;\n    float _3294 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3269);\n    float _3299 = _3294 + (0.5f * _3288);\n    float3 _3305 = world + (gn * _3294);\n    float _3307 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _3372;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3323 = (float(k) + _3307) * 0.083333335816860198974609375f;\n        float3 _3331 = _3305 + (l * (_3323 * len));\n        float4 _3337 = float4(_3331, 1.0f);\n        float _3343 = dot(_386_fa_ct_vpw, _3337);\n        if (_3343 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _3363 = float2(dot(_386_fa_ct_vpx, _3337), dot(_386_fa_ct_vpy, _3337)) / _3343.xx;\n        float _3367 = _3363.x * 0.5f;\n        float _3368 = _3367 + 0.5f;\n        if (_386_fa_ct_a.y > 0.5f)\n        {\n            _3372 = (_3363.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _3372 = 0.5f - (_3363.y * 0.5f);\n        }\n        bool _3388 = _3368 < 0.0f;\n        bool _3395;\n        if (!_3388)\n        {\n            _3395 = _3368 >= 1.0f;\n        }\n        else\n        {\n            _3395 = _3388;\n        }\n        bool _3402;\n        if (!_3395)\n        {\n            _3402 = _3372 < 0.0f;\n        }\n        else\n        {\n            _3402 = _3395;\n        }\n        bool _3409;\n        if (!_3402)\n        {\n            _3409 = _3372 >= 1.0f;\n        }\n        else\n        {\n            _3409 = _3402;\n        }\n        if (_3409)\n        {\n            break;\n        }\n        float4 _3428 = fa_screen_tex.Load(int3(int2(float2(_3368, _3372) * _386_fa_ct_a.zw), 0));\n        if (_3428.w < 0.5f)\n        {\n            continue;\n        }\n        float _3447 = (dot(_386_fa_ct_fwd.xyz, _3331) + _386_fa_ct_fwd.w) - _3428.x;\n        if ((_3447 > _3294) && (_3447 < _3299))\n        {\n            occ = max(occ, (1.0f - (_3323 * _3323)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_3368, 0.5f - _3367), min(_3372, 1.0f - _3372))));\n        }\n    }\n    return 1.0f - (occ * _3279);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    bool _3523 = fa_lm.z > 0.5f;\n    bool _3529;\n    if (_3523)\n    {\n        int param = li;\n        _3529 = fa_light_baked(param);\n    }\n    else\n    {\n        _3529 = _3523;\n    }\n    if (_3529)\n    {\n        int param_1 = li;\n        LightSample _4625 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4625;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3553 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _4627 = _3553.color;\n    float _4629 = _3553.shadow;\n    bool _3556 = _3553.type == 0;\n    if (_3556 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3553.direction;\n        float _3567 = fa_shadow_factor(param_5, param_6);\n        _4629 = _3567;\n        _4627 *= _3567;\n    }\n    else\n    {\n        bool _3578 = _3553.type != 0;\n        bool _3584;\n        if (_3578)\n        {\n            _3584 = _3553.attenuation > 0.0f;\n        }\n        else\n        {\n            _3584 = _3578;\n        }\n        if (_3584)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3553.direction;\n            float _3603 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4629 = _3603;\n            _4627 *= _3603;\n        }\n    }\n    bool _3613 = _386_fa_ct_a.x > 0.5f;\n    bool _3619;\n    if (_3613)\n    {\n        _3619 = _3553.attenuation > 0.0f;\n    }\n    else\n    {\n        _3619 = _3613;\n    }\n    if (_3619)\n    {\n        float _3626;\n        if (_3556)\n        {\n            _3626 = 1000000000.0f;\n        }\n        else\n        {\n            _3626 = _3553._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3553.direction;\n        float param_18 = _3626;\n        float _3644 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _4629 *= _3644;\n        _4627 *= _3644;\n    }\n    LightSample _4644 = { _3553.direction, _4627, _3553.attenuation, _4629, _3553._distance, _3553.type };\n    return _4644;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _3667;\n    if (dot(s.normal, l.direction) > 0.5f)\n    {\n        _3667 = 1.0f;\n    }\n    else\n    {\n        _3667 = _3673_dark;\n    }\n    return (s.albedo * l.color) * _3667;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2043_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2979 = int(_2043_fa_shadow_cfg.x + 0.5f);\n    float _2989 = dot(world - _2043_fa_shadow_eye.xyz, _2043_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _2994 = _2979 > 0;\n    bool _3003;\n    if (_2994)\n    {\n        int param = _2979 - 1;\n        _3003 = _2989 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3003 = _2994;\n    }\n    if (_3003)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3009 = _2979 > 1;\n        bool _3016;\n        if (_3009)\n        {\n            _3016 = _2989 > _2043_fa_shadow_split.x;\n        }\n        else\n        {\n            _3016 = _3009;\n        }\n        if (_3016)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3022 = _2979 > 2;\n        bool _3029;\n        if (_3022)\n        {\n            _3029 = _2989 > _2043_fa_shadow_split.y;\n        }\n        else\n        {\n            _3029 = _3022;\n        }\n        if (_3029)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3035 = _2979 > 3;\n        bool _3042;\n        if (_3035)\n        {\n            _3042 = _2989 > _2043_fa_shadow_split.z;\n        }\n        else\n        {\n            _3042 = _3035;\n        }\n        if (_3042)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4468 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4468 = -_4468;\n    }\n    float3 _4054 = normalize(_386_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4481 = { fa_world_pos, _4468, fa_world_tangent, fa_uv, fa_vertex_color, _4054, gl_FrontFacing };\n    SurfaceInput param_1 = _4481;\n    Surface _4062 = fa_standard_surface(param_1);\n    float3 _4499 = _4062.albedo;\n    float _4500 = _4062.alpha;\n    float3 _4501 = _4062.normal;\n    float _4502 = _4062.metallic;\n    float _4503 = _4062.roughness;\n    float _4504 = _4062.occlusion;\n    float3 _4505 = _4062.emission;\n    float _4506 = _4062.clearcoat;\n    float _4507 = _4062.clearcoat_roughness;\n    float3 _4508 = _4062.sheen_color;\n    float _4509 = _4062.sheen_roughness;\n    float _4510 = _4062.anisotropy;\n    float _4511 = _4062.anisotropy_rotation;\n    float _4512 = _4062.specular;\n    float _4513 = _4062.ior;\n    float3 _4514 = _4062.specular_color;\n    SurfaceInput _4489 = { fa_world_pos, _4468, fa_world_tangent, fa_uv, fa_vertex_color, _4054, gl_FrontFacing };\n    SurfaceInput param_2 = _4489;\n    Surface param_3 = _4062;\n    surface(param_2, param_3);\n    _4499 = param_3.albedo;\n    _4500 = param_3.alpha;\n    _4501 = param_3.normal;\n    _4502 = param_3.metallic;\n    _4503 = param_3.roughness;\n    _4504 = param_3.occlusion;\n    _4505 = param_3.emission;\n    _4506 = param_3.clearcoat;\n    _4507 = param_3.clearcoat_roughness;\n    _4508 = param_3.sheen_color;\n    _4509 = param_3.sheen_roughness;\n    _4510 = param_3.anisotropy;\n    _4511 = param_3.anisotropy_rotation;\n    _4512 = param_3.specular;\n    _4513 = param_3.ior;\n    _4514 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4468;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4499 = param_6;\n    _4501 = param_7;\n    float3 result;\n    if (_386_fa_emissive.w > 0.5f)\n    {\n        result = _4499;\n    }\n    else\n    {\n        float3 _4100 = _4501;\n        float3 _4101 = normalize(_4100);\n        _4501 = _4101;\n        float3 param_8 = _4101;\n        float3 lit = (fa_indirect_diffuse(param_8) * _4499) * _4504;\n        int _4120 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4120; ln++)\n        {\n            int param_9 = ln;\n            int _4133 = fa_cl_light(param_9);\n            bool _4136 = fa_lm.z > 0.5f;\n            bool _4142;\n            if (_4136)\n            {\n                int param_10 = _4133;\n                _4142 = fa_light_baked(param_10);\n            }\n            else\n            {\n                _4142 = _4136;\n            }\n            if (_4142)\n            {\n                continue;\n            }\n            int param_11 = _4133;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _4468;\n            LightSample _4154 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput _4497 = { fa_world_pos, _4468, fa_world_tangent, fa_uv, fa_vertex_color, _4054, gl_FrontFacing };\n            SurfaceInput param_14 = _4497;\n            Surface _4580 = { _4499, _4500, _4501, _4502, _4503, _4504, _4505, _4506, _4507, _4508, _4509, _4510, _4511, _4512, _4513, _4514 };\n            Surface param_15 = _4580;\n            LightSample param_16 = _4154;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _4169 = result;\n    float3 _4170 = _4169 + _4505;\n    result = _4170;\n    float3 param_17 = _4170;\n    float3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _4179 = _386_fa_fog.w > 0.0f;\n    bool _4186;\n    if (!_4179)\n    {\n        _4186 = _386_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4186 = _4179;\n    }\n    if (_4186)\n    {\n        float3 _4195 = fa_world_pos - _386_fa_camera_pos.xyz;\n        float _4201 = dot(_4195, _386_fa_fog_c.xyz);\n        bool _4205 = _386_fa_fog_c.w > 0.5f;\n        float _4206;\n        if (_4205)\n        {\n            _4206 = _4201;\n        }\n        else\n        {\n            _4206 = length(_4195);\n        }\n        float _4218 = _4206 - _386_fa_fog_b.x;\n        if (_4218 > 0.0f)\n        {\n            float _4227 = _386_fa_fog.w * _4218;\n            float tau = _4227 * _4227;\n            if (_386_fa_fog_b.y > 0.0f)\n            {\n                float _4243;\n                if (_4205)\n                {\n                    _4243 = fa_world_pos.y - (_386_fa_fog_c.y * _4201);\n                }\n                else\n                {\n                    _4243 = _386_fa_camera_pos.y;\n                }\n                float _4264 = lerp(_4243, fa_world_pos.y, clamp(_386_fa_fog_b.x / _4206, 0.0f, 1.0f));\n                float _4268 = fa_world_pos.y - _4264;\n                float _4273 = _4264 - _386_fa_fog_b.z;\n                float _4278 = fa_world_pos.y - _386_fa_fog_b.z;\n                bool _4281 = _4273 <= 0.0f;\n                bool _4282 = !_4281;\n                bool _4288;\n                if (_4282)\n                {\n                    _4288 = _386_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4288 = _4281;\n                }\n                float _4289;\n                if (_4288)\n                {\n                    _4289 = _386_fa_fog_b.y;\n                }\n                else\n                {\n                    _4289 = _386_fa_fog_b.y * exp(-min(_386_fa_fog_b.w * _4273, 80.0f));\n                }\n                bool _4316;\n                if (_4282)\n                {\n                    _4316 = _386_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4316 = _4281;\n                }\n                float _4317;\n                if (_4316)\n                {\n                    _4317 = _386_fa_fog_b.y * _4273;\n                }\n                else\n                {\n                    _4317 = (_386_fa_fog_b.y * (1.0f - exp(-min(_386_fa_fog_b.w * _4273, 80.0f)))) / _386_fa_fog_b.w;\n                }\n                bool _4342 = _4278 <= 0.0f;\n                bool _4349;\n                if (!_4342)\n                {\n                    _4349 = _386_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4349 = _4342;\n                }\n                float _4350;\n                if (_4349)\n                {\n                    _4350 = _386_fa_fog_b.y * _4278;\n                }\n                else\n                {\n                    _4350 = (_386_fa_fog_b.y * (1.0f - exp(-min(_386_fa_fog_b.w * _4278, 80.0f)))) / _386_fa_fog_b.w;\n                }\n                float _4377;\n                if (abs(_4268) < 0.001000000047497451305389404296875f)\n                {\n                    _4377 = _4289;\n                }\n                else\n                {\n                    _4377 = (_4350 - _4317) / _4268;\n                }\n                tau += (_4218 * max(_4377, 0.0f));\n            }\n            result = lerp(result, _386_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4500);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_386",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2043",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_3673",
            "hlsl_register_b_n": 5
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _295 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _295;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0f);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n    float4 _213_fa_ct_a : packoffset(c24);\n    float4 _213_fa_ct_b : packoffset(c25);\n    float4 _213_fa_ct_vpx : packoffset(c26);\n    float4 _213_fa_ct_vpy : packoffset(c27);\n    float4 _213_fa_ct_vpw : packoffset(c28);\n    float4 _213_fa_ct_fwd : packoffset(c29);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _788 = base_t;\n    _788.x = _225.x;\n    _788.y = _225.y;\n    _788.z = _225.z;\n    base_t = _788;\n    float4 _241 = (_788 * _213_fa_base_color) * i.vertex_color;\n    float3 _751 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _796 = _279;\n        _796.x = _284.x;\n        _796.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _796;\n        _751 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _799 = mrt;\n    _799.x = _313.x;\n    _799.y = _313.y;\n    _799.z = _313.z;\n    mrt = _799;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _756 = _213_fa_layers_a.x;\n    float _757 = _213_fa_layers_a.y;\n    float _760 = _213_fa_layers_a.z;\n    float _759 = _213_fa_layers_b.w;\n    float _762 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _756 *= _355.y;\n            _757 *= _355.z;\n            _759 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _760 *= mrt.x;\n            _762 *= mrt.w;\n        }\n    }\n    Surface _781 = { _241.xyz, _241.w, _751, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _756, _757, _213_fa_layers_b.xyz, _759, _760, _213_fa_layers_a.w, _762, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _781;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _662 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _662 = -_662;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _675 = { fa_world_pos, _662, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _675;\n    SurfaceInput _683 = { fa_world_pos, _662, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _683;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _416 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _416;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _423 = _273.world_pos;\n    float4 _284 = float4(_423, 1.0f);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _213_fa_camera_pos : packoffset(c0);\n    float4 _213_fa_ambient : packoffset(c1);\n    float4 _213_fa_base_color : packoffset(c2);\n    float4 _213_fa_emissive : packoffset(c3);\n    float4 _213_fa_model_emissive : packoffset(c4);\n    float4 _213_fa_pbr : packoffset(c5);\n    float4 _213_fa_maps : packoffset(c6);\n    float4 _213_fa_fog : packoffset(c7);\n    float4 _213_fa_fog_b : packoffset(c8);\n    float4 _213_fa_fog_c : packoffset(c9);\n    float4 _213_fa_counts : packoffset(c10);\n    float4 _213_fa_env_sky : packoffset(c11);\n    float4 _213_fa_env_horizon : packoffset(c12);\n    float4 _213_fa_time : packoffset(c13);\n    float4 _213_fa_cl_vpx : packoffset(c14);\n    float4 _213_fa_cl_vpy : packoffset(c15);\n    float4 _213_fa_cl_vpw : packoffset(c16);\n    float4 _213_fa_cl_fwd : packoffset(c17);\n    float4 _213_fa_cl_grid : packoffset(c18);\n    float4 _213_fa_cl_info : packoffset(c19);\n    float4 _213_fa_layers_a : packoffset(c20);\n    float4 _213_fa_layers_b : packoffset(c21);\n    float4 _213_fa_layers_c : packoffset(c22);\n    float4 _213_fa_layers_d : packoffset(c23);\n    float4 _213_fa_ct_a : packoffset(c24);\n    float4 _213_fa_ct_b : packoffset(c25);\n    float4 _213_fa_ct_vpx : packoffset(c26);\n    float4 _213_fa_ct_vpy : packoffset(c27);\n    float4 _213_fa_ct_vpw : packoffset(c28);\n    float4 _213_fa_ct_fwd : packoffset(c29);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _213_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _225 = fa_tex_fix(param_2, param_3);\n    float4 _788 = base_t;\n    _788.x = _225.x;\n    _788.y = _225.y;\n    _788.z = _225.z;\n    base_t = _788;\n    float4 _241 = (_788 * _213_fa_base_color) * i.vertex_color;\n    float3 _751 = i.world_normal;\n    if (_213_fa_maps.z > 0.5f)\n    {\n        float param_4 = _213_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _275 = fa_tex_fix(param_6, param_7);\n        float3 _279 = (_275 * 2.0f) - 1.0f.xxx;\n        float2 _284 = _279.xy * _213_fa_maps.x;\n        float3 _796 = _279;\n        _796.x = _284.x;\n        _796.y = _284.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _796;\n        _751 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _213_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _313 = fa_tex_fix(param_12, param_13);\n    float4 _799 = mrt;\n    _799.x = _313.x;\n    _799.y = _313.y;\n    _799.z = _313.z;\n    mrt = _799;\n    float4 _343 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _213_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = _213_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _385 = fa_tex_fix(param_20, param_21);\n    float _756 = _213_fa_layers_a.x;\n    float _757 = _213_fa_layers_a.y;\n    float _760 = _213_fa_layers_a.z;\n    float _759 = _213_fa_layers_b.w;\n    float _762 = _213_fa_layers_c.x;\n    if (_213_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_213_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _756 *= _355.y;\n            _757 *= _355.z;\n            _759 *= _343.w;\n        }\n        if (_213_fa_layers_c.z > 1.5f)\n        {\n            _760 *= mrt.x;\n            _762 *= mrt.w;\n        }\n    }\n    Surface _781 = { _241.xyz, _241.w, _751, clamp(_213_fa_pbr.x * _313.z, 0.0f, 1.0f), clamp(_213_fa_pbr.y * _313.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_213_fa_maps.y * (_355.x - 1.0f)), _213_fa_emissive.xyz + (_213_fa_model_emissive.xyz * _385), _756, _757, _213_fa_layers_b.xyz, _759, _760, _213_fa_layers_a.w, _762, _213_fa_layers_c.y, _213_fa_layers_d.xyz };\n    return _781;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _662 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _662 = -_662;\n    }\n    float3 _519 = normalize(_213_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _675 = { fa_world_pos, _662, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param = _675;\n    SurfaceInput _683 = { fa_world_pos, _662, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing };\n    SurfaceInput param_1 = _683;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _534 = normalize(param_2.normal);\n    float3 _549 = normalize(float3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    float2 e = _549.xy / ((abs(_549.x) + abs(_549.y)) + abs(_561)).xx;\n    if (_561 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
