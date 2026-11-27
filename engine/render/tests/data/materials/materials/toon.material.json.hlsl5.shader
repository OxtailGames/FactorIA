{
  "format": "factoria.shader/1",
  "engine": "0.39.0",
  "template": "4694fb4be9bed2a7c5475af904870ae4995eb283e1c27e15e0192dfe0c2b2256",
  "slang": "hlsl5",
  "params": [
    "dark"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _263 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _263;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_270, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _433_fa_camera_pos : packoffset(c0);\n    float4 _433_fa_ambient : packoffset(c1);\n    float4 _433_fa_base_color : packoffset(c2);\n    float4 _433_fa_emissive : packoffset(c3);\n    float4 _433_fa_model_emissive : packoffset(c4);\n    float4 _433_fa_pbr : packoffset(c5);\n    float4 _433_fa_maps : packoffset(c6);\n    float4 _433_fa_fog : packoffset(c7);\n    float4 _433_fa_fog_b : packoffset(c8);\n    float4 _433_fa_fog_c : packoffset(c9);\n    float4 _433_fa_counts : packoffset(c10);\n    float4 _433_fa_env_sky : packoffset(c11);\n    float4 _433_fa_env_horizon : packoffset(c12);\n    float4 _433_fa_time : packoffset(c13);\n    float4 _433_fa_cl_vpx : packoffset(c14);\n    float4 _433_fa_cl_vpy : packoffset(c15);\n    float4 _433_fa_cl_vpw : packoffset(c16);\n    float4 _433_fa_cl_fwd : packoffset(c17);\n    float4 _433_fa_cl_grid : packoffset(c18);\n    float4 _433_fa_cl_info : packoffset(c19);\n    float4 _433_fa_layers_a : packoffset(c20);\n    float4 _433_fa_layers_b : packoffset(c21);\n    float4 _433_fa_layers_c : packoffset(c22);\n    float4 _433_fa_layers_d : packoffset(c23);\n    float4 _433_fa_ct_a : packoffset(c24);\n    float4 _433_fa_ct_b : packoffset(c25);\n    float4 _433_fa_ct_vpx : packoffset(c26);\n    float4 _433_fa_ct_vpy : packoffset(c27);\n    float4 _433_fa_ct_vpw : packoffset(c28);\n    float4 _433_fa_ct_fwd : packoffset(c29);\n    float4 _433_fa_tr_a : packoffset(c30);\n    float4 _433_fa_tr_b : packoffset(c31);\n    float4 _433_fa_probe_sh[9] : packoffset(c32);\n    float4 _433_fa_atlas : packoffset(c41);\n    float4 _433_fa_rpa_tile : packoffset(c42);\n    float4 _433_fa_rpa_pos : packoffset(c43);\n    float4 _433_fa_rpa_bx : packoffset(c44);\n    float4 _433_fa_rpa_by : packoffset(c45);\n    float4 _433_fa_rpa_bz : packoffset(c46);\n    float4 _433_fa_rpb_tile : packoffset(c47);\n    float4 _433_fa_rpb_pos : packoffset(c48);\n    float4 _433_fa_rpb_bx : packoffset(c49);\n    float4 _433_fa_rpb_by : packoffset(c50);\n    float4 _433_fa_rpb_bz : packoffset(c51);\n    float4 _433_fa_gi : packoffset(c52);\n    float4 _433_fa_gi_px : packoffset(c53);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2085_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2085_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2085_fa_shadow_info[4] : packoffset(c20);\n    float4 _2085_fa_shadow_split : packoffset(c24);\n    float4 _2085_fa_shadow_cfg : packoffset(c25);\n    float4 _2085_fa_shadow_bias : packoffset(c26);\n    float4 _2085_fa_shadow_eye : packoffset(c27);\n    float4 _2085_fa_shadow_fwd : packoffset(c28);\n    float4 _2085_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _4533_dark : packoffset(c0);\n    float _4533_fa_pad0 : packoffset(c0.y);\n    float _4533_fa_pad1 : packoffset(c0.z);\n    float _4533_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float fa_rt_slope;\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1361 = _433_fa_cl_info.x < 0.0f;\n    bool _1368;\n    if (!_1361)\n    {\n        _1368 = _433_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1368 = _1361;\n    }\n    bool _1376;\n    if (!_1368)\n    {\n        _1376 = _433_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1376 = _1368;\n    }\n    bool _1383;\n    if (!_1376)\n    {\n        _1383 = _433_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1383 = _1376;\n    }\n    bool _1390;\n    if (!_1383)\n    {\n        _1390 = _433_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1390 = _1383;\n    }\n    if (_1390)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1400 = float4(world_pos, 1.0f);\n    float _1406 = dot(_433_fa_cl_vpw, _1400);\n    if (!(_1406 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1428 = float2(dot(_433_fa_cl_vpx, _1400), dot(_433_fa_cl_vpy, _1400)) / _1406.xx;\n    int _1432 = int(_433_fa_cl_grid.x);\n    int _1436 = int(_433_fa_cl_grid.y);\n    int param = (int(_433_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_433_fa_cl_fwd.xyz, world_pos) + _433_fa_cl_fwd.w, _433_fa_cl_grid.w) / _433_fa_cl_grid.w) * _433_fa_cl_grid.z)), 0, int(_433_fa_cl_info.y) - 1) * _1436) + clamp(int(floor(((_1428.y * 0.5f) + 0.5f) * _433_fa_cl_grid.y)), 0, _1436 - 1)) * _1432)) + clamp(int(floor(((_1428.x * 0.5f) + 0.5f) * _433_fa_cl_grid.x)), 0, _1432 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1512 = fa_cluster_texel(param);\n    return int2(int(_1512.x), int(_1512.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    float _4322 = dot(_433_fa_ct_fwd.xyz, world_pos) + _433_fa_ct_fwd.w;\n    float _4325 = fwidth(_4322);\n    bool _4328 = _433_fa_ct_b.y > 0.5f;\n    bool _4335;\n    if (!_4328)\n    {\n        _4335 = _433_fa_ct_b.w > 0.5f;\n    }\n    else\n    {\n        _4335 = _4328;\n    }\n    if (_4335)\n    {\n        fa_rt_slope = min(1.5f * _4325, 0.100000001490116119384765625f * _4322);\n    }\n    fa_cl_ndir = int(_433_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4351 = fa_cluster_lookup(param);\n    fa_cl_slot = _4351.x;\n    fa_cl_local = _4351.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4582 = fa_linear_to_srgb(param);\n        c = _4582;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4590 = fa_srgb_to_linear(param_1);\n            c = _4590;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _316;\n    if (i.front_facing)\n    {\n        _316 = i.world_normal;\n    }\n    else\n    {\n        _316 = -i.world_normal;\n    }\n    float3 _340 = normalize(i.world_tangent.xyz - (_316 * dot(_316, i.world_tangent.xyz)));\n    float3 _367 = normalize(((_340 * m.x) + ((cross(_316, _340) * i.world_tangent.w) * m.y)) + (_316 * m.z));\n    float3 _370;\n    if (i.front_facing)\n    {\n        _370 = _367;\n    }\n    else\n    {\n        _370 = -_367;\n    }\n    return _370;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _433_fa_env_horizon.w);\n    float param = _433_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4622 = fa_tex_fix(param_2, param_3);\n    float4 _6501 = base_t;\n    _6501.x = _4622.x;\n    _6501.y = _4622.y;\n    _6501.z = _4622.z;\n    base_t = _6501;\n    float4 _4636 = (_6501 * _433_fa_base_color) * i.vertex_color;\n    float3 _6314 = i.world_normal;\n    if (_433_fa_maps.z > 0.5f)\n    {\n        float param_4 = _433_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _433_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4670 = fa_tex_fix(param_6, param_7);\n        float3 _4673 = (_4670 * 2.0f) - 1.0f.xxx;\n        float2 _4678 = _4673.xy * _433_fa_maps.x;\n        float3 _6509 = _4673;\n        _6509.x = _4678.x;\n        _6509.y = _4678.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6509;\n        _6314 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _433_fa_env_horizon.w);\n    float param_10 = _433_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4708 = fa_tex_fix(param_12, param_13);\n    float4 _6512 = mrt;\n    _6512.x = _4708.x;\n    _6512.y = _4708.y;\n    _6512.z = _4708.z;\n    mrt = _6512;\n    float4 _4738 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _433_fa_env_horizon.w);\n    float param_14 = _433_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4738.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4749 = fa_tex_fix(param_16, param_17);\n    float param_18 = _433_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _433_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4781 = fa_tex_fix(param_20, param_21);\n    float _6319 = _433_fa_layers_a.x;\n    float _6320 = _433_fa_layers_a.y;\n    float _6323 = _433_fa_layers_a.z;\n    float _6322 = _433_fa_layers_b.w;\n    float _6325 = _433_fa_layers_c.x;\n    if (_433_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_433_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6319 *= _4749.y;\n            _6320 *= _4749.z;\n            _6322 *= _4738.w;\n        }\n        if (_433_fa_layers_c.z > 1.5f)\n        {\n            _6323 *= mrt.x;\n            _6325 *= mrt.w;\n        }\n    }\n    Surface _6352 = { _4636.xyz, _4636.w, _6314, clamp(_433_fa_pbr.x * _4708.z, 0.0f, 1.0f), clamp(_433_fa_pbr.y * _4708.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_433_fa_maps.y * (_4749.x - 1.0f)), _433_fa_emissive.xyz + (_433_fa_model_emissive.xyz * _4781), _6319, _6320, _433_fa_layers_b.xyz, _6322, _6323, _433_fa_layers_a.w, _6325, _433_fa_layers_c.y, _433_fa_layers_d.xyz, _433_fa_tr_a.x, _433_fa_tr_a.y, _433_fa_tr_b.xyz, _433_fa_tr_a.z };\n    return _6352;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1592 = rect.zw - rect.xy;\n    float2 _1596 = _1592 * atlas;\n    float2 _1600 = ddx * _1596;\n    float2 _1604 = ddy * _1596;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1592), clamp(0.5f * log2(max(max(dot(_1600, _1600), dot(_1604, _1604)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1637 = _433_fa_counts.y < 0.5f;\n    bool _1644;\n    if (!_1637)\n    {\n        _1644 = _433_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1644 = _1637;\n    }\n    if (_1644)\n    {\n        return;\n    }\n    float3 _1650 = ddx(world_pos);\n    float3 _1653 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1657 = fa_cluster_texel(param);\n    int _1661 = int(_1657.w);\n    if (_1661 < 1)\n    {\n        return;\n    }\n    int _1671 = int(_433_fa_counts.y + 0.5f);\n    int param_1 = _1671;\n    float4 _1675 = fa_light_texel(param_1);\n    float2 _1678 = _1675.yz;\n    int _1682 = int(_1675.w);\n    int param_2 = _1671 + 1;\n    float4 _1687 = fa_light_texel(param_2);\n    float _1688 = _1687.x;\n    int _1694 = int(_433_fa_counts.w + 0.5f) - 1;\n    int _1698 = int(_1657.z);\n    float3 _1963;\n    for (int k = 0; k < _1661; k++)\n    {\n        int _1711 = _1698 + k;\n        int param_3 = _1682 + (_1711 >> 2);\n        int _1728 = (_1671 + 2) + (int(fa_light_texel(param_3)[_1711 & 3]) * 7);\n        int param_4 = _1728 + 6;\n        float4 _1733 = fa_light_texel(param_4);\n        if (((int(_1733.w + 0.5f) >> _1694) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1728;\n        float4 _1748 = fa_light_texel(param_5);\n        int param_6 = _1728 + 1;\n        float4 _1753 = fa_light_texel(param_6);\n        int param_7 = _1728 + 2;\n        float4 _1758 = fa_light_texel(param_7);\n        float3 _1761 = _1748.xyz;\n        float _1766 = dot(_1761, world_pos) + _1748.w;\n        float3 _1768 = _1753.xyz;\n        float _1773 = dot(_1768, world_pos) + _1753.w;\n        float3 _1775 = _1758.xyz;\n        float _1780 = dot(_1775, world_pos) + _1758.w;\n        bool _1785 = abs(_1766) > 0.5f;\n        bool _1793;\n        if (!_1785)\n        {\n            _1793 = abs(_1773) > 0.5f;\n        }\n        else\n        {\n            _1793 = _1785;\n        }\n        bool _1801;\n        if (!_1793)\n        {\n            _1801 = abs(_1780) > 0.5f;\n        }\n        else\n        {\n            _1801 = _1793;\n        }\n        if (_1801)\n        {\n            continue;\n        }\n        float _1816 = clamp(dot(geo_normal, normalize(_1775)) * _1733.z, 0.0f, 1.0f);\n        if (_1816 <= 0.0f)\n        {\n            continue;\n        }\n        float _1836 = (clamp((0.5f - abs(_1780)) * 10.0f, 0.0f, 1.0f) * _1816) * _1733.x;\n        float2 _1844 = float2(_1766 + 0.5f, 0.5f - _1773);\n        float2 _1854 = float2(dot(_1761, _1650), dot(_1768, _1650));\n        float2 _1864 = float2(dot(_1761, _1653), dot(_1768, _1653));\n        int param_8 = _1728 + 5;\n        float4 _1869 = fa_light_texel(param_8);\n        int param_9 = _1728 + 3;\n        float4 _1874 = fa_light_texel(param_9);\n        int param_10 = _1728 + 4;\n        float4 _1879 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1869.xyz;\n        bool _1889 = _1874.z > _1874.x;\n        if (_1889)\n        {\n            float4 param_11 = _1874;\n            float2 param_12 = _1844;\n            float2 param_13 = _1678;\n            float2 param_14 = _1854;\n            float2 param_15 = _1864;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1688 > 0.5f) && (_1688 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1915 = fa_dc_to_linear(param_16);\n                float4 _6402 = tx;\n                _6402.x = _1915.x;\n                _6402.y = _1915.y;\n                _6402.z = _1915.z;\n                tx = _6402;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1836 * tex_a) * _1869.w, 0.0f, 1.0f).xxx);\n        if (_1879.z > _1879.x)\n        {\n            float4 param_17 = _1879;\n            float2 param_18 = _1844;\n            float2 param_19 = _1678;\n            float2 param_20 = _1854;\n            float2 param_21 = _1864;\n            float4 _1959 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1688 > 1.5f)\n            {\n                float3 param_22 = _1959.xyz;\n                float3 _1969 = fa_dc_to_srgb(param_22);\n                _1963 = _1969;\n            }\n            else\n            {\n                _1963 = _1959.xyz;\n            }\n            float3 _1978 = (_1963 * 2.0f) - 1.0f.xxx;\n            float2 _1983 = _1978.xy * _1733.y;\n            float3 _2005 = (normalize(_1761) * _1983.x) + (normalize(_1768) * _1983.y);\n            float3 _2008 = normalize(normal);\n            normal = normalize(lerp(_2008, normalize((_2008 * max(_1978.z, 0.0500000007450580596923828125f)) + (_2005 - (_2008 * dot(_2008, _2005)))), clamp(_1836 * (_1889 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3844_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3844_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_433_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3785 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3785;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3894 = (1.0f - _433_fa_rpa_tile.w) - _433_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3900 = _433_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3894 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3900)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _433_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3894;\n            }\n        }\n        else\n        {\n            amb = _433_fa_ambient.xyz * _3894;\n        }\n    }\n    bool _3952 = _433_fa_rpa_tile.w > 0.0f;\n    if (_3952)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _433_fa_rpa_tile.xy;\n            float param_4 = _433_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _433_fa_rpa_tile.w);\n        }\n    }\n    bool _3983 = _433_fa_rpb_tile.w > 0.0f;\n    if (_3983)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _433_fa_rpb_tile.xy;\n            float param_7 = _433_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _433_fa_rpb_tile.w);\n        }\n    }\n    if ((_3900 || _3952) || _3983)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3805 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3808 = _3805.x;\n    float _3810 = _3805.z;\n    float2 e = float2(_3808, _3810);\n    if (_3805.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3810)) * ((_3808 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3808)) * ((_3810 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _4895 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _4900 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _4905 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _4910 = fa_light_texel(param_3);\n    bool _4913 = _4910.z < 0.5f;\n    bool _4921;\n    if (!_4913)\n    {\n        _4921 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _4921 = _4913;\n    }\n    if (_4921)\n    {\n        return 0.0f.xxx;\n    }\n    float _4928 = max(_4895.w, 9.9999997473787516355514526367188e-05f);\n    float3 _4931 = _4900.xyz;\n    float3 _4935 = _4895.xyz;\n    float3 _4939 = (fa_world_pos - _4935) / _4928.xxx;\n    float3 _4948 = min(_4939 + 0.5f.xxx, (_4931 - 0.5f.xxx) - _4939);\n    float _4957 = min(_4948.x, min(_4948.y, _4948.z));\n    if (!(_4957 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4972 = _4931 - 1.0f.xxx;\n    float3 _4973 = clamp(_4939, 0.0f.xxx, _4972);\n    float3 _4981 = min(floor(_4973), max(_4931 - 2.0f.xxx, 0.0f.xxx));\n    float3 _4985 = _4973 - _4981;\n    float3 _4997 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _4928));\n    int _5002 = int(_4905.y + 0.5f);\n    float _5007 = 0.3257350027561187744140625f * n.y;\n    float _5011 = 0.3257350027561187744140625f * n.z;\n    float _5015 = 0.3257350027561187744140625f * n.x;\n    float _5022 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _5029 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _5038 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _5045 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _5058 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _5065 = 8 + int(_4910.w);\n    float _5092;\n    float _5105;\n    float _5119;\n    for (int k = 0; k < _5065; k++)\n    {\n        float _5078 = float(k & 1);\n        float _5082 = float((k >> 1) & 1);\n        float _5086 = float((k >> 2) & 1);\n        if (_5078 > 0.5f)\n        {\n            _5092 = _4985.x;\n        }\n        else\n        {\n            _5092 = 1.0f - _4985.x;\n        }\n        if (_5082 > 0.5f)\n        {\n            _5105 = _4985.y;\n        }\n        else\n        {\n            _5105 = 1.0f - _4985.y;\n        }\n        if (_5086 > 0.5f)\n        {\n            _5119 = _4985.z;\n        }\n        else\n        {\n            _5119 = 1.0f - _4985.z;\n        }\n        float _5129 = (_5092 * _5105) * _5119;\n        if (!(_5129 > 0.0f))\n        {\n            continue;\n        }\n        float3 _5142 = min(_4981 + float3(_5078, _5082, _5086), _4972);\n        int _5162 = int(((_4905.x + _5142.x) + (_4900.x * (_5142.y + (_4900.y * _5142.z)))) + 0.5f);\n        float2 _5177 = float2(float(_5162 % _5002) * 10.0f, 1024.0f + (float(_5162 / _5002) * 11.0f));\n        float2 param_4 = _5177 + float2(9.5f, 10.5f);\n        float4 _5185 = fa_gi_fetch(param_4);\n        bool _5188 = _5185.y < 0.5f;\n        bool _5197;\n        if (!_5188)\n        {\n            _5197 = _5185.x > _4910.y;\n        }\n        else\n        {\n            _5197 = _5188;\n        }\n        if (_5197)\n        {\n            continue;\n        }\n        float3 _5209 = _4997 - (_4935 + (_5142 * _4928));\n        float _5212 = length(_5209);\n        float3 _5218 = _5209 / max(_5212, 9.9999997473787516355514526367188e-05f).xxx;\n        float _5228 = max(9.9999997473787516355514526367188e-05f, (dot(-_5218, n) + 1.0f) * 0.5f);\n        float w = _5129 * (_5228 * _5228);\n        float3 param_5 = _5218;\n        float2 param_6 = (_5177 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _5248 = fa_gi_fetch(param_6);\n        float _5255 = _5212 / max(_4905.z, 9.9999997473787516355514526367188e-05f);\n        float _5258 = _5248.x;\n        if (_5255 > _5258)\n        {\n            float _5271 = max(_5248.y - (_5258 * _5258), 0.0f);\n            float _5276 = _5255 - _5258;\n            float _5285 = _5271 / max(_5271 + (_5276 * _5276), 9.9999999600419720025001879548654e-13f);\n            w *= ((_5285 * _5285) * _5285);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _5177 + float2(0.5f, 10.5f);\n        float2 param_8 = _5177 + float2(1.5f, 10.5f);\n        float2 param_9 = _5177 + float2(2.5f, 10.5f);\n        float2 param_10 = _5177 + float2(3.5f, 10.5f);\n        float2 param_11 = _5177 + float2(4.5f, 10.5f);\n        float2 param_12 = _5177 + float2(5.5f, 10.5f);\n        float2 param_13 = _5177 + float2(6.5f, 10.5f);\n        float2 param_14 = _5177 + float2(7.5f, 10.5f);\n        float2 param_15 = _5177 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _5007)) + (fa_gi_fetch(param_9).xyz * _5011)) + (fa_gi_fetch(param_10).xyz * _5015)) + (fa_gi_fetch(param_11).xyz * _5022)) + (fa_gi_fetch(param_12).xyz * _5029)) + (fa_gi_fetch(param_13).xyz * _5038)) + (fa_gi_fetch(param_14).xyz * _5045)) + (fa_gi_fetch(param_15).xyz * _5058)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_4957 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _5413;\n    if (_433_fa_gi.z > 0.5f)\n    {\n        _5413 = _4910.x;\n    }\n    else\n    {\n        _5413 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_4905.w * _5413);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _5437 = normalize(_433_fa_camera_pos.xyz - fa_world_pos);\n    int _5442 = int(_433_fa_gi.x + 0.5f);\n    int _5447 = int(_433_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _5447) && (k < 8); k++)\n    {\n        int param = _5442 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _5437;\n        float3 _5472 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5477 = param_3 * left;\n        acc += (_5472 * _5477);\n        left -= _5477;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_433_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _5506 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5506;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_433_fa_gi_px.x > 0.5f)\n    {\n        float4 _5548 = float4(fa_world_pos, 1.0f);\n        float2 _5567 = float2(dot(_433_fa_ct_vpx, _5548), dot(_433_fa_ct_vpy, _5548)) / max(dot(_433_fa_ct_vpw, _5548), 9.9999997473787516355514526367188e-05f).xx;\n        float _5576;\n        if (_433_fa_ct_a.y > 0.5f)\n        {\n            _5576 = (_5567.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5576 = 0.5f - (_5567.y * 0.5f);\n        }\n        return fa_lightmap.Load(int3(clamp(int2(float2((_5567.x * 0.5f) + 0.5f, _5576) * _433_fa_ct_a.zw), int2(0, 0), int2(_433_fa_ct_a.zw) - int2(1, 1)), 0)).xyz;\n    }\n    if (_433_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _433_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_433_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_433_fa_cl_info.x) + int(_433_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_433_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4292;\n    if (fa_lm.z > 0.5f)\n    {\n        _4292 = 0.0f;\n    }\n    else\n    {\n        _4292 = 1.0f - clamp(_433_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4303 = _4292 < 1.0f;\n    bool _4309;\n    if (_4303)\n    {\n        int param = li;\n        _4309 = fa_light_baked(param);\n    }\n    else\n    {\n        _4309 = _4303;\n    }\n    return _4309 ? _4292 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _611 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _624 = (c - (ru * hx)) - p;\n        float3 _630 = ru * (2.0f * hx);\n        float _636 = max(dot(_630, _630), 9.9999999392252902907785028219223e-09f);\n        float _640 = dot(_624, _630);\n        float t = clamp((-_640) / _636, 0.0f, 1.0f);\n        if (_611)\n        {\n            float _655 = dot(r, _630);\n            float _661 = _636 - (_655 * _655);\n            if (abs(_661) > (9.9999997473787516355514526367188e-06f * _636))\n            {\n                t = clamp(((dot(r, _624) * _655) - _640) / _661, 0.0f, 1.0f);\n            }\n        }\n        return (p + _624) + (_630 * t);\n    }\n    float3 q = p;\n    float _693 = dot(r, axis);\n    bool _701;\n    if (_611)\n    {\n        _701 = abs(_693) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _701 = _611;\n    }\n    if (_701)\n    {\n        float _711 = dot(c - p, axis) / _693;\n        if (_711 > 0.0f)\n        {\n            q = p + (r * _711);\n        }\n    }\n    float3 _724 = q - c;\n    float2 xy = float2(dot(_724, ru), dot(_724, uu));\n    if (shape > 0.5f)\n    {\n        float _739 = length(xy);\n        if (_739 > hx)\n        {\n            xy *= (hx / _739);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _492_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _492_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _531 = dot(d, right);\n    float _535 = dot(d, up);\n    float _546;\n    if (((_531 * _531) + (_535 * _535)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _546 = atan2(_535, _531) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _546 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_546 - floor(_546)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _382 = abs(d);\n    float _384 = _382.x;\n    float _386 = _382.y;\n    bool _387 = _384 >= _386;\n    bool _395;\n    if (_387)\n    {\n        _395 = _384 >= _382.z;\n    }\n    else\n    {\n        _395 = _387;\n    }\n    int _396;\n    if (_395)\n    {\n        _396 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _410;\n        if (_386 >= _382.z)\n        {\n            _410 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _410 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _396 = _410;\n    }\n    return _396;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _777 = fa_light_base(param);\n    bool _781 = _433_fa_ambient.w > 4.5f;\n    int param_1 = _777;\n    float4 _785 = fa_light_texel(param_1);\n    int param_2 = _777 + 1;\n    float4 _790 = fa_light_texel(param_2);\n    float _793 = _790.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _805 = _781 && (_793 > 2.5f);\n    fa_light_is_area = _805;\n    bool _807 = _793 < 0.5f;\n    float3 l;\n    if (_807)\n    {\n        l = normalize(_785.xyz);\n        if (_781)\n        {\n            int param_3 = _777 + 6;\n            float4 _821 = fa_light_texel(param_3);\n            if (_821.z > 0.5f)\n            {\n                int param_4 = _777 + 4;\n                float4 _831 = fa_light_texel(param_4);\n                int param_5 = _777 + 5;\n                float4 _836 = fa_light_texel(param_5);\n                float2 param_6 = _821.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _831.xyz) * _831.w, (-dot(world_pos, _836.xyz)) * _836.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _866 = _785.xyz;\n        float3 _868 = _866 - world_pos;\n        float3 to_light = _868;\n        float _871 = length(_868);\n        float reach = _871;\n        bool front = true;\n        if (_805)\n        {\n            int param_8 = _777 + 7;\n            reach = max(_871 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _777 + 4;\n            float4 _895 = fa_light_texel(param_9);\n            int param_10 = _777 + 5;\n            float4 _900 = fa_light_texel(param_10);\n            int param_11 = _777 + 6;\n            float4 _905 = fa_light_texel(param_11);\n            float _906 = _905.w;\n            int param_12 = _777 + 2;\n            float3 _913 = normalize(fa_light_texel(param_12).xyz);\n            bool _915 = _906 > 1.5f;\n            bool _923;\n            if (!_915)\n            {\n                _923 = dot(_913, to_light) < 0.0f;\n            }\n            else\n            {\n                _923 = _915;\n            }\n            front = _923;\n            float3 r = 0.0f.xxx;\n            float3 _932 = _433_fa_camera_pos.xyz - world_pos;\n            bool _936 = dot(n, n) > 0.5f;\n            bool _944;\n            if (_936)\n            {\n                _944 = dot(_932, _932) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _944 = _936;\n            }\n            if (_944)\n            {\n                r = reflect(-normalize(_932), normalize(n));\n            }\n            float3 param_13 = _866;\n            float3 param_14 = _913;\n            float3 param_15 = _895.xyz;\n            float3 param_16 = _900.xyz;\n            float param_17 = _895.w;\n            float param_18 = _900.w;\n            float param_19 = _906;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _980 = length(to_light);\n        dist = _980;\n        l = to_light / max(_980, 9.9999997473787516355514526367188e-05f).xxx;\n        float _994 = reach / max(_785.w, 0.001000000047497451305389404296875f);\n        float _1000 = clamp(1.0f - (_994 * _994), 0.0f, 1.0f);\n        float _1002;\n        if (front)\n        {\n            _1002 = _1000 * _1000;\n        }\n        else\n        {\n            _1002 = 0.0f;\n        }\n        atten = _1002;\n        bool _1013 = _793 < 2.5f;\n        if ((_793 > 1.5f) && _1013)\n        {\n            int param_22 = _777 + 2;\n            float4 _1021 = fa_light_texel(param_22);\n            float _1031 = _1021.w;\n            int param_23 = _777 + 3;\n            float4 _1036 = fa_light_texel(param_23);\n            float _1037 = _1036.x;\n            float cos_inner = _1037;\n            if (_1037 > 1.5f)\n            {\n                cos_inner = lerp(_1031, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1031, cos_inner, dot(-l, normalize(_1021.xyz)));\n        }\n        if (_781 && (_793 < 1.5f))\n        {\n            int param_24 = _777 + 6;\n            float4 _1061 = fa_light_texel(param_24);\n            if (_1061.z > 0.5f)\n            {\n                float3 _1069 = -to_light;\n                int param_25 = _777 + 4;\n                int param_26 = _777 + 5;\n                float3 _1083 = fa_light_texel(param_25).xyz;\n                float3 _1087 = fa_light_texel(param_26).xyz;\n                float3 _1096 = float3(dot(_1069, _1083), dot(_1069, _1087), dot(_1069, cross(_1083, _1087)));\n                float3 param_27 = _1096;\n                int _1100 = fa_cube_face(param_27);\n                int param_28 = _1100;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1127 = float2(dot(_1096, cross(param_29, param_30)), dot(_1096, param_30)) / max(dot(_1096, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1131 = _1100 / 3;\n                float2 param_31 = _1061.xy + (float2(float(_1100 - (_1131 * 3)), float(_1131)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1127.x), 0.5f - (0.5f * _1127.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _777 + 7;\n            float4 _1161 = fa_light_texel(param_33);\n            if (_1161.z > 0.5f)\n            {\n                int param_34 = _777 + 2;\n                int param_35 = _777 + 4;\n                int param_36 = _777 + 5;\n                float2 param_37 = _1161.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_781 && _1013)\n            {\n                int param_42 = _777 + 6;\n                float4 _1208 = fa_light_texel(param_42);\n                int param_43 = _777 + 7;\n                float4 _1213 = fa_light_texel(param_43);\n                bool _1216 = _1208.z > 0.5f;\n                bool _1223;\n                if (!_1216)\n                {\n                    _1223 = _1213.z > 0.5f;\n                }\n                else\n                {\n                    _1223 = _1216;\n                }\n                if (_1223)\n                {\n                    int param_44 = _777 + 2;\n                    float4 _1230 = fa_light_texel(param_44);\n                    float3 _1234 = normalize(_1230.xyz);\n                    int param_45 = _777 + 4;\n                    float4 _1239 = fa_light_texel(param_45);\n                    int param_46 = _777 + 5;\n                    float4 _1244 = fa_light_texel(param_46);\n                    if (_1216)\n                    {\n                        float3 _1252 = -to_light;\n                        float _1259 = _1230.w;\n                        float _1275 = 0.5f / max(dot(_1252, _1234) * (sqrt(max(1.0f - (_1259 * _1259), 0.0f)) / max(_1259, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1208.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1252, _1239.xyz) * _1275), 0.5f - (dot(_1252, _1244.xyz) * _1275));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1213.z > 0.5f)\n                    {\n                        float2 param_49 = _1213.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1234;\n                        float3 param_52 = _1239.xyz;\n                        float3 param_53 = _1244.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6268 = _790.xyz * atten;\n    if (_781)\n    {\n        _6268 *= fa_light_tint;\n    }\n    int _1343;\n    if (_807)\n    {\n        _1343 = 0;\n    }\n    else\n    {\n        _1343 = ((_793 > 1.5f) && (_793 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _6279 = { l, _6268, atten, 1.0f, dist, _1343 };\n    return _6279;\n}\n\nfloat fa_rt_local_tap(int2 p, int2 size, float d, float tol, float div, inout float best)\n{\n    float4 _3304 = fa_screen_tex.Load(int3(clamp(p, int2(0, 0), size - int2(1, 1)), 0));\n    bool _3307 = _3304.w > 0.5f;\n    bool _3317;\n    if (_3307)\n    {\n        _3317 = abs(d - _3304.x) <= tol;\n    }\n    else\n    {\n        _3317 = _3307;\n    }\n    if (_3317)\n    {\n        best = min(best, mod(floor(_3304.z / div), 256.0f) * 0.0039215688593685626983642578125f);\n    }\n    return best;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2132 = fa_shadow_depth(param, param_1);\n    float _2136;\n    if (conv.x < 0.5f)\n    {\n        _2136 = _2132;\n    }\n    else\n    {\n        _2136 = (conv.y * conv.z) / (conv.z - (_2132 * (conv.z - conv.y)));\n    }\n    return _2136;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2182 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2188 = float2(cos(_2182), sin(_2182));\n    float2 dir = _2188;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2197;\n        if (k < 0.0f)\n        {\n            _2197 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2197 = k;\n        }\n        float _2216 = clamp((_2197 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2235 = sqrt((float(i) + 0.5f) * 0.0625f) * _2216;\n            float2 param_3 = uv + (dir * (_2085_fa_shadow_bias.zw * _2235));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2249 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2249 < (zr - (_2235 * plane)))\n            {\n                sum += _2249;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2277 = sum / cnt;\n        float _2287;\n        if (k < 0.0f)\n        {\n            _2287 = (-k) / max(_2277, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2287 = k;\n        }\n        radius = clamp(((max(zr - _2277, 0.0f) * unit) * _2287) / texel_m, 1.5f, 16.0f);\n        dir = _2188;\n    }\n    float lit = 0.0f;\n    int _2313 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2313; i_1++)\n    {\n        float _2332 = sqrt((float(i_1) + 0.5f) / float(_2313)) * radius;\n        float2 param_7 = uv + (dir * (_2085_fa_shadow_bias.zw * _2332));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2332 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2313);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2537 = _433_fa_pbr.z < 0.5f;\n    bool _2544;\n    if (!_2537)\n    {\n        _2544 = _2085_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2544 = _2537;\n    }\n    if (_2544)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2085_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2557 = fa_light_texel(param);\n    float _2558 = _2557.x;\n    if (_2558 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2567 = int(_2558 + 0.5f);\n    int param_1 = _2567;\n    float4 _2571 = fa_light_texel(param_1);\n    int param_2 = _2567 + 1;\n    float4 _2576 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2579 = _2571.y;\n    if (_2579 > 0.0f)\n    {\n        float _2596 = 1.0f - smoothstep(0.75f * _2579, _2579, length(world - _2085_fa_shadow_eye.xyz));\n        fade = _2596;\n        if (_2596 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2571.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2620 = (_2567 + 2) + (face * 6);\n    int param_4 = _2620;\n    int param_5 = _2620 + 1;\n    int param_6 = _2620 + 3;\n    float4 _2634 = fa_light_texel(param_6);\n    int param_7 = _2620 + 4;\n    float4 _2639 = fa_light_texel(param_7);\n    int param_8 = _2620 + 5;\n    float4 _2644 = fa_light_texel(param_8);\n    float _2656 = _2644.x * max(dot(_2634, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2661 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2684 = clamp(dot(n, _2634.xyz), -1.0f, 1.0f);\n    float _2703 = min(sqrt(1.0f - (_2684 * _2684)) / max(abs(dot(n, world - lpos)) / max(dot(_2634, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2706 = _2576.y;\n    float _2708;\n    if (_2706 > 0.0f)\n    {\n        _2708 = _2706;\n    }\n    else\n    {\n        _2708 = 1.5f * _2656;\n    }\n    float4 _2728 = float4(world + (n * (_2708 * sqrt(1.0f - (_2661 * _2661)))), 1.0f);\n    float _2732 = dot(_2634, _2728);\n    float _2735 = _2644.y;\n    if (_2732 < _2735)\n    {\n        return 1.0f;\n    }\n    float2 _2750 = float2(dot(fa_light_texel(param_4), _2728), dot(fa_light_texel(param_5), _2728)) / _2732.xx;\n    float _2752 = _2750.x;\n    bool _2755 = _2752 < _2639.x;\n    bool _2764;\n    if (!_2755)\n    {\n        _2764 = _2752 > _2639.z;\n    }\n    else\n    {\n        _2764 = _2755;\n    }\n    bool _2773;\n    if (!_2764)\n    {\n        _2773 = _2750.y < _2639.y;\n    }\n    else\n    {\n        _2773 = _2764;\n    }\n    bool _2782;\n    if (!_2773)\n    {\n        _2782 = _2750.y > _2639.w;\n    }\n    else\n    {\n        _2782 = _2773;\n    }\n    if (_2782)\n    {\n        return 1.0f;\n    }\n    float _2788 = _2576.x;\n    float _2790;\n    if (_2788 > 0.0f)\n    {\n        _2790 = _2788;\n    }\n    else\n    {\n        _2790 = 1.5f * _2656;\n    }\n    float2 param_9 = _2750;\n    float4 param_10 = _2639;\n    float param_11 = _2732 - (_2790 * (1.0f + (0.5f * _2703)));\n    float param_12 = _2656;\n    float param_13 = 1.0f;\n    float param_14 = _2644.z * 0.25f;\n    float param_15 = (_2656 * min(_2703, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2735, _2644.z);\n    int param_17 = int(_2571.z + 0.5f);\n    float param_18 = _2571.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _3335 = _433_fa_ct_b.w > 0.5f;\n    bool _3341;\n    if (_3335)\n    {\n        _3341 = _433_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3341 = _3335;\n    }\n    bool _3347;\n    if (_3341)\n    {\n        _3347 = _2085_fa_shadow_lcfg.x > 0.5f;\n    }\n    else\n    {\n        _3347 = _3341;\n    }\n    if (_3347)\n    {\n        int param = (int(_2085_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n        float4 _3359 = fa_light_texel(param);\n        float _3360 = _3359.z;\n        if (_3360 > 0.5f)\n        {\n            float _3373 = dot(_433_fa_ct_fwd.xyz, world) + _433_fa_ct_fwd.w;\n            float _3379 = ((0.00200000009499490261077880859375f * _3373) + 0.00999999977648258209228515625f) + fa_rt_slope;\n            float4 _3385 = float4(world, 1.0f);\n            float _3390 = dot(_433_fa_ct_vpw, _3385);\n            if (_3390 > 9.9999997473787516355514526367188e-05f)\n            {\n                float2 _3407 = float2(dot(_433_fa_ct_vpx, _3385), dot(_433_fa_ct_vpy, _3385)) / _3390.xx;\n                float _3412 = (_3407.x * 0.5f) + 0.5f;\n                float _3416;\n                if (_433_fa_ct_a.y > 0.5f)\n                {\n                    _3416 = (_3407.y * 0.5f) + 0.5f;\n                }\n                else\n                {\n                    _3416 = 0.5f - (_3407.y * 0.5f);\n                }\n                bool _3432 = _3412 >= 0.0f;\n                bool _3438;\n                if (_3432)\n                {\n                    _3438 = _3412 < 1.0f;\n                }\n                else\n                {\n                    _3438 = _3432;\n                }\n                bool _3444;\n                if (_3438)\n                {\n                    _3444 = _3416 >= 0.0f;\n                }\n                else\n                {\n                    _3444 = _3438;\n                }\n                bool _3450;\n                if (_3444)\n                {\n                    _3450 = _3416 < 1.0f;\n                }\n                else\n                {\n                    _3450 = _3444;\n                }\n                if (_3450)\n                {\n                    int2 _3457 = int2(_433_fa_ct_a.zw);\n                    int2 _3468 = clamp(int2(float2(_3412, _3416) * _433_fa_ct_a.zw), int2(0, 0), _3457 - int2(1, 1));\n                    float _3472;\n                    if (_3360 < 1.5f)\n                    {\n                        _3472 = 1.0f;\n                    }\n                    else\n                    {\n                        _3472 = (_3360 < 2.5f) ? 256.0f : 65536.0f;\n                    }\n                    float best = 2.0f;\n                    float4 _3488 = fa_screen_tex.Load(int3(_3468, 0));\n                    bool _3491 = _3488.w > 0.5f;\n                    bool _3501;\n                    if (_3491)\n                    {\n                        _3501 = abs(_3373 - _3488.x) <= _3379;\n                    }\n                    else\n                    {\n                        _3501 = _3491;\n                    }\n                    if (_3501)\n                    {\n                        best = mod(floor(_3488.z / _3472), 256.0f) * 0.0039215688593685626983642578125f;\n                    }\n                    else\n                    {\n                        int2 param_1 = _3468 + int2(-1, -1);\n                        int2 param_2 = _3457;\n                        float param_3 = _3373;\n                        float param_4 = _3379;\n                        float param_5 = _3472;\n                        float param_6 = best;\n                        float _3527 = fa_rt_local_tap(param_1, param_2, param_3, param_4, param_5, param_6);\n                        best = _3527;\n                        int2 param_7 = _3468 + int2(0, -1);\n                        int2 param_8 = _3457;\n                        float param_9 = _3373;\n                        float param_10 = _3379;\n                        float param_11 = _3472;\n                        float param_12 = _3527;\n                        float _3542 = fa_rt_local_tap(param_7, param_8, param_9, param_10, param_11, param_12);\n                        best = _3542;\n                        int2 param_13 = _3468 + int2(1, -1);\n                        int2 param_14 = _3457;\n                        float param_15 = _3373;\n                        float param_16 = _3379;\n                        float param_17 = _3472;\n                        float param_18 = _3542;\n                        float _3557 = fa_rt_local_tap(param_13, param_14, param_15, param_16, param_17, param_18);\n                        best = _3557;\n                        int2 param_19 = _3468 + int2(-1, 0);\n                        int2 param_20 = _3457;\n                        float param_21 = _3373;\n                        float param_22 = _3379;\n                        float param_23 = _3472;\n                        float param_24 = _3557;\n                        float _3572 = fa_rt_local_tap(param_19, param_20, param_21, param_22, param_23, param_24);\n                        best = _3572;\n                        int2 param_25 = _3468 + int2(1, 0);\n                        int2 param_26 = _3457;\n                        float param_27 = _3373;\n                        float param_28 = _3379;\n                        float param_29 = _3472;\n                        float param_30 = _3572;\n                        float _3587 = fa_rt_local_tap(param_25, param_26, param_27, param_28, param_29, param_30);\n                        best = _3587;\n                        int2 param_31 = _3468 + int2(-1, 1);\n                        int2 param_32 = _3457;\n                        float param_33 = _3373;\n                        float param_34 = _3379;\n                        float param_35 = _3472;\n                        float param_36 = _3587;\n                        float _3602 = fa_rt_local_tap(param_31, param_32, param_33, param_34, param_35, param_36);\n                        best = _3602;\n                        int2 param_37 = _3468 + int2(0, 1);\n                        int2 param_38 = _3457;\n                        float param_39 = _3373;\n                        float param_40 = _3379;\n                        float param_41 = _3472;\n                        float param_42 = _3602;\n                        float _3617 = fa_rt_local_tap(param_37, param_38, param_39, param_40, param_41, param_42);\n                        best = _3617;\n                        int2 param_43 = _3468 + int2(1, 1);\n                        int2 param_44 = _3457;\n                        float param_45 = _3373;\n                        float param_46 = _3379;\n                        float param_47 = _3472;\n                        float param_48 = _3617;\n                        float _3632 = fa_rt_local_tap(param_43, param_44, param_45, param_46, param_47, param_48);\n                        best = _3632;\n                    }\n                    if (best <= 1.0f)\n                    {\n                        float _3640;\n                        if (_433_fa_ct_b.z > 0.5f)\n                        {\n                            int param_49 = li;\n                            float3 param_50 = lpos;\n                            float3 param_51 = world;\n                            float3 param_52 = n;\n                            float3 param_53 = l;\n                            _3640 = min(best, fa_shadow_local(param_49, param_50, param_51, param_52, param_53));\n                        }\n                        else\n                        {\n                            _3640 = best;\n                        }\n                        return _3640;\n                    }\n                }\n            }\n            float _3663;\n            if (_433_fa_ct_b.z > 0.5f)\n            {\n                int param_54 = li;\n                float3 param_55 = lpos;\n                float3 param_56 = world;\n                float3 param_57 = n;\n                float3 param_58 = l;\n                _3663 = fa_shadow_local(param_54, param_55, param_56, param_57, param_58);\n            }\n            else\n            {\n                _3663 = 1.0f;\n            }\n            return _3663;\n        }\n    }\n    int param_59 = li;\n    float3 param_60 = lpos;\n    float3 param_61 = world;\n    float3 param_62 = n;\n    float3 param_63 = l;\n    return fa_shadow_local(param_59, param_60, param_61, param_62, param_63);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2075;\n    if (i == 0)\n    {\n        _2075 = _2085_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2091;\n        if (i == 1)\n        {\n            _2091 = _2085_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2099;\n            if (i == 2)\n            {\n                _2099 = _2085_fa_shadow_split.z;\n            }\n            else\n            {\n                _2099 = _2085_fa_shadow_split.w;\n            }\n            _2091 = _2099;\n        }\n        _2075 = _2091;\n    }\n    return _2075;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2378 = max(_2085_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2383 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2389 = sqrt(1.0f - (_2383 * _2383));\n    float _2397 = min(_2389 / max(_2383, 0.20000000298023223876953125f), 4.0f);\n    float _2402;\n    if (_2085_fa_shadow_bias.y > 0.0f)\n    {\n        _2402 = _2085_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2402 = 1.5f * _2085_fa_shadow_info[ci].x;\n    }\n    float4 _2427 = mul(float4(world + (n * (_2402 * _2389)), 1.0f), _2085_fa_shadow_mat[ci]);\n    float _2434 = _2427.x;\n    bool _2437 = _2434 < _2085_fa_shadow_rect[ci].x;\n    bool _2446;\n    if (!_2437)\n    {\n        _2446 = _2434 > _2085_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2446 = _2437;\n    }\n    bool _2455;\n    if (!_2446)\n    {\n        _2455 = _2427.y < _2085_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2455 = _2446;\n    }\n    bool _2464;\n    if (!_2455)\n    {\n        _2464 = _2427.y > _2085_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2464 = _2455;\n    }\n    bool _2471;\n    if (!_2464)\n    {\n        _2471 = _2427.z > 1.0f;\n    }\n    else\n    {\n        _2471 = _2464;\n    }\n    if (_2471)\n    {\n        return -1.0f;\n    }\n    float _2479;\n    if (_2085_fa_shadow_bias.x > 0.0f)\n    {\n        _2479 = _2085_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2479 = 1.5f * _2085_fa_shadow_info[ci].x;\n    }\n    float2 param = _2427.xy;\n    float4 param_1 = _2085_fa_shadow_rect[ci];\n    float param_2 = _2427.z - ((_2479 * (1.0f + (0.5f * _2397))) / _2378);\n    float param_3 = _2085_fa_shadow_info[ci].x;\n    float param_4 = _2378;\n    float param_5 = _2378 * 0.25f;\n    float param_6 = ((_2085_fa_shadow_info[ci].x * min(_2397, 3.0f)) * 0.5f) / _2378;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2085_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2085_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_433_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2857 = int(_2085_fa_shadow_cfg.x + 0.5f);\n    if (_2857 < 1)\n    {\n        return 1.0f;\n    }\n    float _2872 = dot(world - _2085_fa_shadow_eye.xyz, _2085_fa_shadow_fwd.xyz);\n    int param = _2857 - 1;\n    if (_2872 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2884 = _2857 > 1;\n    bool _2891;\n    if (_2884)\n    {\n        _2891 = _2872 > _2085_fa_shadow_split.x;\n    }\n    else\n    {\n        _2891 = _2884;\n    }\n    if (_2891)\n    {\n        ci = 1;\n    }\n    bool _2895 = _2857 > 2;\n    bool _2902;\n    if (_2895)\n    {\n        _2902 = _2872 > _2085_fa_shadow_split.y;\n    }\n    else\n    {\n        _2902 = _2895;\n    }\n    if (_2902)\n    {\n        ci = 2;\n    }\n    bool _2906 = _2857 > 3;\n    bool _2913;\n    if (_2906)\n    {\n        _2913 = _2872 > _2085_fa_shadow_split.z;\n    }\n    else\n    {\n        _2913 = _2906;\n    }\n    if (_2913)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _2924 = min(_2857, 4);\n    float _2965;\n    for (int c = ci; c < _2924; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2944 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _2944;\n            break;\n        }\n        if (_2944 < 0.0f)\n        {\n            continue;\n        }\n        s = _2944;\n        ci = c;\n        if (_2085_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2965 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2965 = _2085_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _2984 = _2085_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2965, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_2872 - (fa_shadow_split_at(param_7) - _2984)) / _2984, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3016;\n        if ((ci + 1) < _2857)\n        {\n            _3016 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3016 = 1.0f;\n        }\n        s = lerp(s, _3016, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    bool _3121 = _433_fa_ct_b.y > 0.5f;\n    bool _3127;\n    if (_3121)\n    {\n        _3127 = _433_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3127 = _3121;\n    }\n    if (_3127)\n    {\n        float _3141 = dot(_433_fa_ct_fwd.xyz, fa_world_pos) + _433_fa_ct_fwd.w;\n        float4 _3149 = float4(fa_world_pos, 1.0f);\n        float _3155 = dot(_433_fa_ct_vpw, _3149);\n        if (_3155 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _3174 = float2(dot(_433_fa_ct_vpx, _3149), dot(_433_fa_ct_vpy, _3149)) / _3155.xx;\n            float _3179 = (_3174.x * 0.5f) + 0.5f;\n            float _3183;\n            if (_433_fa_ct_a.y > 0.5f)\n            {\n                _3183 = (_3174.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _3183 = 0.5f - (_3174.y * 0.5f);\n            }\n            bool _3199 = _3179 >= 0.0f;\n            bool _3205;\n            if (_3199)\n            {\n                _3205 = _3179 < 1.0f;\n            }\n            else\n            {\n                _3205 = _3199;\n            }\n            bool _3211;\n            if (_3205)\n            {\n                _3211 = _3183 >= 0.0f;\n            }\n            else\n            {\n                _3211 = _3205;\n            }\n            bool _3217;\n            if (_3211)\n            {\n                _3217 = _3183 < 1.0f;\n            }\n            else\n            {\n                _3217 = _3211;\n            }\n            if (_3217)\n            {\n                float4 _3242 = fa_screen_tex.Load(int3(clamp(int2(float2(_3179, _3183) * _433_fa_ct_a.zw), int2(0, 0), int2(_433_fa_ct_a.zw) - int2(1, 1)), 0));\n                bool _3245 = _3242.w > 0.5f;\n                bool _3261;\n                if (_3245)\n                {\n                    _3261 = abs(_3141 - _3242.x) <= (((0.00200000009499490261077880859375f * _3141) + 0.00999999977648258209228515625f) + fa_rt_slope);\n                }\n                else\n                {\n                    _3261 = _3245;\n                }\n                if (_3261)\n                {\n                    float _3267;\n                    if (_433_fa_ct_b.z > 0.5f)\n                    {\n                        float3 param = fa_world_pos;\n                        float3 param_1 = n;\n                        float3 param_2 = l;\n                        _3267 = min(_3242.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3267 = _3242.y;\n                    }\n                    return _3267;\n                }\n            }\n        }\n    }\n    float3 param_3 = fa_world_pos;\n    float3 param_4 = n;\n    float3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4034 = _433_fa_ct_a.x < 0.5f;\n    bool _4041;\n    if (!_4034)\n    {\n        _4041 = _2085_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4041 = _4034;\n    }\n    if (_4041)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2085_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4054 = fa_light_texel(param);\n    float _4055 = _4054.y;\n    float len = _4055;\n    if (_4055 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4067 = length(world - _433_fa_camera_pos.xyz);\n    float _4076 = 1.0f - smoothstep(0.5f * _433_fa_ct_b.x, _433_fa_ct_b.x, _4067);\n    if (_4076 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4082 = len;\n    float _4085 = min(_4082, 0.89999997615814208984375f * dist);\n    len = _4085;\n    float _4091 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4067);\n    float _4096 = _4091 + (0.5f * _4085);\n    float3 _4102 = world + (gn * _4091);\n    float _4104 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4166;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4120 = (float(k) + _4104) * 0.083333335816860198974609375f;\n        float3 _4128 = _4102 + (l * (_4120 * len));\n        float4 _4134 = float4(_4128, 1.0f);\n        float _4139 = dot(_433_fa_ct_vpw, _4134);\n        if (_4139 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4157 = float2(dot(_433_fa_ct_vpx, _4134), dot(_433_fa_ct_vpy, _4134)) / _4139.xx;\n        float _4161 = _4157.x * 0.5f;\n        float _4162 = _4161 + 0.5f;\n        if (_433_fa_ct_a.y > 0.5f)\n        {\n            _4166 = (_4157.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4166 = 0.5f - (_4157.y * 0.5f);\n        }\n        bool _4182 = _4162 < 0.0f;\n        bool _4189;\n        if (!_4182)\n        {\n            _4189 = _4162 >= 1.0f;\n        }\n        else\n        {\n            _4189 = _4182;\n        }\n        bool _4196;\n        if (!_4189)\n        {\n            _4196 = _4166 < 0.0f;\n        }\n        else\n        {\n            _4196 = _4189;\n        }\n        bool _4203;\n        if (!_4196)\n        {\n            _4203 = _4166 >= 1.0f;\n        }\n        else\n        {\n            _4203 = _4196;\n        }\n        if (_4203)\n        {\n            break;\n        }\n        float4 _4227 = fa_screen_tex.Load(int3(clamp(int2(float2(_4162, _4166) * _433_fa_ct_a.zw), int2(0, 0), int2(_433_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_4227.w < 0.5f)\n        {\n            continue;\n        }\n        float _4245 = (dot(_433_fa_ct_fwd.xyz, _4128) + _433_fa_ct_fwd.w) - _4227.x;\n        if ((_4245 > _4091) && (_4245 < _4096))\n        {\n            occ = max(occ, (1.0f - (_4120 * _4120)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4162, 0.5f - _4161), min(_4166, 1.0f - _4166))));\n        }\n    }\n    return 1.0f - (occ * _4076);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4377 = fa_baked_keep(param);\n    if (_4377 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _6292 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6292;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4403 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6294 = _4403.color;\n    float _6295 = _4403.attenuation;\n    float _6296 = _4403.shadow;\n    bool _4406 = _4403.type == 0;\n    if (_4406 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4403.direction;\n        float _4417 = fa_shadow_factor(param_5, param_6);\n        _6296 = _4417;\n        _6294 *= _4417;\n    }\n    else\n    {\n        bool _4428 = _4403.type != 0;\n        bool _4434;\n        if (_4428)\n        {\n            _4434 = _6295 > 0.0f;\n        }\n        else\n        {\n            _4434 = _4428;\n        }\n        if (_4434)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4403.direction;\n            float _4453 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6296 = _4453;\n            _6294 *= _4453;\n        }\n    }\n    bool _4463 = _433_fa_ct_a.x > 0.5f;\n    bool _4469;\n    if (_4463)\n    {\n        _4469 = _6295 > 0.0f;\n    }\n    else\n    {\n        _4469 = _4463;\n    }\n    if (_4469)\n    {\n        float _4476;\n        if (_4406)\n        {\n            _4476 = 1000000000.0f;\n        }\n        else\n        {\n            _4476 = _4403._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4403.direction;\n        float param_18 = _4476;\n        float _4494 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6296 *= _4494;\n        _6294 *= _4494;\n    }\n    float _4507 = _6295;\n    float _4508 = _4507 * _4377;\n    _6295 = _4508;\n    float3 _4512 = _6294;\n    float3 _4513 = _4512 * _4377;\n    _6294 = _4513;\n    LightSample _6311 = { _4403.direction, _4513, _4508, _6296, _4403._distance, _4403.type };\n    return _6311;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _4527;\n    if (dot(s.normal, l.direction) > 0.5f)\n    {\n        _4527 = 1.0f;\n    }\n    else\n    {\n        _4527 = _4533_dark;\n    }\n    return (s.albedo * l.color) * _4527;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2085_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3044 = int(_2085_fa_shadow_cfg.x + 0.5f);\n    float _3054 = dot(world - _2085_fa_shadow_eye.xyz, _2085_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3059 = _3044 > 0;\n    bool _3068;\n    if (_3059)\n    {\n        int param = _3044 - 1;\n        _3068 = _3054 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3068 = _3059;\n    }\n    if (_3068)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3074 = _3044 > 1;\n        bool _3081;\n        if (_3074)\n        {\n            _3081 = _3054 > _2085_fa_shadow_split.x;\n        }\n        else\n        {\n            _3081 = _3074;\n        }\n        if (_3081)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3087 = _3044 > 2;\n        bool _3094;\n        if (_3087)\n        {\n            _3094 = _3054 > _2085_fa_shadow_split.y;\n        }\n        else\n        {\n            _3094 = _3087;\n        }\n        if (_3094)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3100 = _3044 > 3;\n        bool _3107;\n        if (_3100)\n        {\n            _3107 = _3054 > _2085_fa_shadow_split.z;\n        }\n        else\n        {\n            _3107 = _3100;\n        }\n        if (_3107)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_rt_slope = 0.0f;\n    fa_inst_load();\n    float3 _6115 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6115 = -_6115;\n    }\n    float3 _5689 = normalize(_433_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _6128 = { fa_world_pos, _6115, fa_world_tangent, fa_uv, fa_vertex_color, _5689, gl_FrontFacing };\n    SurfaceInput param_1 = _6128;\n    Surface _5697 = fa_standard_surface(param_1);\n    float3 _6146 = _5697.albedo;\n    float _6147 = _5697.alpha;\n    float3 _6148 = _5697.normal;\n    float _6149 = _5697.metallic;\n    float _6150 = _5697.roughness;\n    float _6151 = _5697.occlusion;\n    float3 _6152 = _5697.emission;\n    float _6153 = _5697.clearcoat;\n    float _6154 = _5697.clearcoat_roughness;\n    float3 _6155 = _5697.sheen_color;\n    float _6156 = _5697.sheen_roughness;\n    float _6157 = _5697.anisotropy;\n    float _6158 = _5697.anisotropy_rotation;\n    float _6159 = _5697.specular;\n    float _6160 = _5697.ior;\n    float3 _6161 = _5697.specular_color;\n    float _6162 = _5697.transmission;\n    float _6163 = _5697.thickness;\n    float3 _6164 = _5697.attenuation_color;\n    float _6165 = _5697.attenuation_distance;\n    SurfaceInput _6136 = { fa_world_pos, _6115, fa_world_tangent, fa_uv, fa_vertex_color, _5689, gl_FrontFacing };\n    SurfaceInput param_2 = _6136;\n    Surface param_3 = _5697;\n    surface(param_2, param_3);\n    _6146 = param_3.albedo;\n    _6147 = param_3.alpha;\n    _6148 = param_3.normal;\n    _6149 = param_3.metallic;\n    _6150 = param_3.roughness;\n    _6151 = param_3.occlusion;\n    _6152 = param_3.emission;\n    _6153 = param_3.clearcoat;\n    _6154 = param_3.clearcoat_roughness;\n    _6155 = param_3.sheen_color;\n    _6156 = param_3.sheen_roughness;\n    _6157 = param_3.anisotropy;\n    _6158 = param_3.anisotropy_rotation;\n    _6159 = param_3.specular;\n    _6160 = param_3.ior;\n    _6161 = param_3.specular_color;\n    _6162 = param_3.transmission;\n    _6163 = param_3.thickness;\n    _6164 = param_3.attenuation_color;\n    _6165 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _6115;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6146 = param_6;\n    _6148 = param_7;\n    float3 result;\n    if (_433_fa_emissive.w > 0.5f)\n    {\n        result = _6146;\n    }\n    else\n    {\n        float3 _5736 = _6148;\n        float3 _5737 = normalize(_5736);\n        _6148 = _5737;\n        float3 param_8 = _5737;\n        float3 lit = (fa_indirect_diffuse(param_8) * _6146) * _6151;\n        int _5756 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5756; ln++)\n        {\n            int param_9 = ln;\n            int _5769 = fa_cl_light(param_9);\n            int param_10 = _5769;\n            if (fa_baked_keep(param_10) <= 0.0f)\n            {\n                continue;\n            }\n            int param_11 = _5769;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _6115;\n            LightSample _5785 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput _6144 = { fa_world_pos, _6115, fa_world_tangent, fa_uv, fa_vertex_color, _5689, gl_FrontFacing };\n            SurfaceInput param_14 = _6144;\n            Surface _6247 = { _6146, _6147, _6148, _6149, _6150, _6151, _6152, _6153, _6154, _6155, _6156, _6157, _6158, _6159, _6160, _6161, _6162, _6163, _6164, _6165 };\n            Surface param_15 = _6247;\n            LightSample param_16 = _5785;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _5800 = result;\n    float3 _5801 = _5800 + _6152;\n    result = _5801;\n    float3 param_17 = _5801;\n    float3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _5810 = _433_fa_fog.w > 0.0f;\n    bool _5817;\n    if (!_5810)\n    {\n        _5817 = _433_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5817 = _5810;\n    }\n    if (_5817)\n    {\n        float3 _5826 = fa_world_pos - _433_fa_camera_pos.xyz;\n        float _5832 = dot(_5826, _433_fa_fog_c.xyz);\n        bool _5836 = _433_fa_fog_c.w > 0.5f;\n        float _5837;\n        if (_5836)\n        {\n            _5837 = _5832;\n        }\n        else\n        {\n            _5837 = length(_5826);\n        }\n        float _5849 = _5837 - _433_fa_fog_b.x;\n        if (_5849 > 0.0f)\n        {\n            float _5858 = _433_fa_fog.w * _5849;\n            float tau = _5858 * _5858;\n            if (_433_fa_fog_b.y > 0.0f)\n            {\n                float _5874;\n                if (_5836)\n                {\n                    _5874 = fa_world_pos.y - (_433_fa_fog_c.y * _5832);\n                }\n                else\n                {\n                    _5874 = _433_fa_camera_pos.y;\n                }\n                float _5895 = lerp(_5874, fa_world_pos.y, clamp(_433_fa_fog_b.x / _5837, 0.0f, 1.0f));\n                float _5899 = fa_world_pos.y - _5895;\n                float _5904 = _5895 - _433_fa_fog_b.z;\n                float _5909 = fa_world_pos.y - _433_fa_fog_b.z;\n                bool _5912 = _5904 <= 0.0f;\n                bool _5913 = !_5912;\n                bool _5919;\n                if (_5913)\n                {\n                    _5919 = _433_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5919 = _5912;\n                }\n                float _5920;\n                if (_5919)\n                {\n                    _5920 = _433_fa_fog_b.y;\n                }\n                else\n                {\n                    _5920 = _433_fa_fog_b.y * exp(-min(_433_fa_fog_b.w * _5904, 80.0f));\n                }\n                bool _5947;\n                if (_5913)\n                {\n                    _5947 = _433_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5947 = _5912;\n                }\n                float _5948;\n                if (_5947)\n                {\n                    _5948 = _433_fa_fog_b.y * _5904;\n                }\n                else\n                {\n                    _5948 = (_433_fa_fog_b.y * (1.0f - exp(-min(_433_fa_fog_b.w * _5904, 80.0f)))) / _433_fa_fog_b.w;\n                }\n                bool _5973 = _5909 <= 0.0f;\n                bool _5980;\n                if (!_5973)\n                {\n                    _5980 = _433_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5980 = _5973;\n                }\n                float _5981;\n                if (_5980)\n                {\n                    _5981 = _433_fa_fog_b.y * _5909;\n                }\n                else\n                {\n                    _5981 = (_433_fa_fog_b.y * (1.0f - exp(-min(_433_fa_fog_b.w * _5909, 80.0f)))) / _433_fa_fog_b.w;\n                }\n                float _6008;\n                if (abs(_5899) < 0.001000000047497451305389404296875f)\n                {\n                    _6008 = _5920;\n                }\n                else\n                {\n                    _6008 = (_5981 - _5948) / _5899;\n                }\n                tau += (_5849 * max(_6008, 0.0f));\n            }\n            result = lerp(result, _433_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _6147);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_433",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2085",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_4533",
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
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
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
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
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
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1
          },
          {
            "slot": 11,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _384 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _384;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_391, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _433_fa_camera_pos : packoffset(c0);\n    float4 _433_fa_ambient : packoffset(c1);\n    float4 _433_fa_base_color : packoffset(c2);\n    float4 _433_fa_emissive : packoffset(c3);\n    float4 _433_fa_model_emissive : packoffset(c4);\n    float4 _433_fa_pbr : packoffset(c5);\n    float4 _433_fa_maps : packoffset(c6);\n    float4 _433_fa_fog : packoffset(c7);\n    float4 _433_fa_fog_b : packoffset(c8);\n    float4 _433_fa_fog_c : packoffset(c9);\n    float4 _433_fa_counts : packoffset(c10);\n    float4 _433_fa_env_sky : packoffset(c11);\n    float4 _433_fa_env_horizon : packoffset(c12);\n    float4 _433_fa_time : packoffset(c13);\n    float4 _433_fa_cl_vpx : packoffset(c14);\n    float4 _433_fa_cl_vpy : packoffset(c15);\n    float4 _433_fa_cl_vpw : packoffset(c16);\n    float4 _433_fa_cl_fwd : packoffset(c17);\n    float4 _433_fa_cl_grid : packoffset(c18);\n    float4 _433_fa_cl_info : packoffset(c19);\n    float4 _433_fa_layers_a : packoffset(c20);\n    float4 _433_fa_layers_b : packoffset(c21);\n    float4 _433_fa_layers_c : packoffset(c22);\n    float4 _433_fa_layers_d : packoffset(c23);\n    float4 _433_fa_ct_a : packoffset(c24);\n    float4 _433_fa_ct_b : packoffset(c25);\n    float4 _433_fa_ct_vpx : packoffset(c26);\n    float4 _433_fa_ct_vpy : packoffset(c27);\n    float4 _433_fa_ct_vpw : packoffset(c28);\n    float4 _433_fa_ct_fwd : packoffset(c29);\n    float4 _433_fa_tr_a : packoffset(c30);\n    float4 _433_fa_tr_b : packoffset(c31);\n    float4 _433_fa_probe_sh[9] : packoffset(c32);\n    float4 _433_fa_atlas : packoffset(c41);\n    float4 _433_fa_rpa_tile : packoffset(c42);\n    float4 _433_fa_rpa_pos : packoffset(c43);\n    float4 _433_fa_rpa_bx : packoffset(c44);\n    float4 _433_fa_rpa_by : packoffset(c45);\n    float4 _433_fa_rpa_bz : packoffset(c46);\n    float4 _433_fa_rpb_tile : packoffset(c47);\n    float4 _433_fa_rpb_pos : packoffset(c48);\n    float4 _433_fa_rpb_bx : packoffset(c49);\n    float4 _433_fa_rpb_by : packoffset(c50);\n    float4 _433_fa_rpb_bz : packoffset(c51);\n    float4 _433_fa_gi : packoffset(c52);\n    float4 _433_fa_gi_px : packoffset(c53);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2085_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2085_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2085_fa_shadow_info[4] : packoffset(c20);\n    float4 _2085_fa_shadow_split : packoffset(c24);\n    float4 _2085_fa_shadow_cfg : packoffset(c25);\n    float4 _2085_fa_shadow_bias : packoffset(c26);\n    float4 _2085_fa_shadow_eye : packoffset(c27);\n    float4 _2085_fa_shadow_fwd : packoffset(c28);\n    float4 _2085_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _4533_dark : packoffset(c0);\n    float _4533_fa_pad0 : packoffset(c0.y);\n    float _4533_fa_pad1 : packoffset(c0.z);\n    float _4533_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float fa_rt_slope;\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1361 = _433_fa_cl_info.x < 0.0f;\n    bool _1368;\n    if (!_1361)\n    {\n        _1368 = _433_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1368 = _1361;\n    }\n    bool _1376;\n    if (!_1368)\n    {\n        _1376 = _433_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1376 = _1368;\n    }\n    bool _1383;\n    if (!_1376)\n    {\n        _1383 = _433_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1383 = _1376;\n    }\n    bool _1390;\n    if (!_1383)\n    {\n        _1390 = _433_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1390 = _1383;\n    }\n    if (_1390)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1400 = float4(world_pos, 1.0f);\n    float _1406 = dot(_433_fa_cl_vpw, _1400);\n    if (!(_1406 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1428 = float2(dot(_433_fa_cl_vpx, _1400), dot(_433_fa_cl_vpy, _1400)) / _1406.xx;\n    int _1432 = int(_433_fa_cl_grid.x);\n    int _1436 = int(_433_fa_cl_grid.y);\n    int param = (int(_433_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_433_fa_cl_fwd.xyz, world_pos) + _433_fa_cl_fwd.w, _433_fa_cl_grid.w) / _433_fa_cl_grid.w) * _433_fa_cl_grid.z)), 0, int(_433_fa_cl_info.y) - 1) * _1436) + clamp(int(floor(((_1428.y * 0.5f) + 0.5f) * _433_fa_cl_grid.y)), 0, _1436 - 1)) * _1432)) + clamp(int(floor(((_1428.x * 0.5f) + 0.5f) * _433_fa_cl_grid.x)), 0, _1432 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1512 = fa_cluster_texel(param);\n    return int2(int(_1512.x), int(_1512.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    float _4322 = dot(_433_fa_ct_fwd.xyz, world_pos) + _433_fa_ct_fwd.w;\n    float _4325 = fwidth(_4322);\n    bool _4328 = _433_fa_ct_b.y > 0.5f;\n    bool _4335;\n    if (!_4328)\n    {\n        _4335 = _433_fa_ct_b.w > 0.5f;\n    }\n    else\n    {\n        _4335 = _4328;\n    }\n    if (_4335)\n    {\n        fa_rt_slope = min(1.5f * _4325, 0.100000001490116119384765625f * _4322);\n    }\n    fa_cl_ndir = int(_433_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4351 = fa_cluster_lookup(param);\n    fa_cl_slot = _4351.x;\n    fa_cl_local = _4351.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4582 = fa_linear_to_srgb(param);\n        c = _4582;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4590 = fa_srgb_to_linear(param_1);\n            c = _4590;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _316;\n    if (i.front_facing)\n    {\n        _316 = i.world_normal;\n    }\n    else\n    {\n        _316 = -i.world_normal;\n    }\n    float3 _340 = normalize(i.world_tangent.xyz - (_316 * dot(_316, i.world_tangent.xyz)));\n    float3 _367 = normalize(((_340 * m.x) + ((cross(_316, _340) * i.world_tangent.w) * m.y)) + (_316 * m.z));\n    float3 _370;\n    if (i.front_facing)\n    {\n        _370 = _367;\n    }\n    else\n    {\n        _370 = -_367;\n    }\n    return _370;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _433_fa_env_horizon.w);\n    float param = _433_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4622 = fa_tex_fix(param_2, param_3);\n    float4 _6501 = base_t;\n    _6501.x = _4622.x;\n    _6501.y = _4622.y;\n    _6501.z = _4622.z;\n    base_t = _6501;\n    float4 _4636 = (_6501 * _433_fa_base_color) * i.vertex_color;\n    float3 _6314 = i.world_normal;\n    if (_433_fa_maps.z > 0.5f)\n    {\n        float param_4 = _433_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _433_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4670 = fa_tex_fix(param_6, param_7);\n        float3 _4673 = (_4670 * 2.0f) - 1.0f.xxx;\n        float2 _4678 = _4673.xy * _433_fa_maps.x;\n        float3 _6509 = _4673;\n        _6509.x = _4678.x;\n        _6509.y = _4678.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6509;\n        _6314 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _433_fa_env_horizon.w);\n    float param_10 = _433_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4708 = fa_tex_fix(param_12, param_13);\n    float4 _6512 = mrt;\n    _6512.x = _4708.x;\n    _6512.y = _4708.y;\n    _6512.z = _4708.z;\n    mrt = _6512;\n    float4 _4738 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _433_fa_env_horizon.w);\n    float param_14 = _433_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4738.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4749 = fa_tex_fix(param_16, param_17);\n    float param_18 = _433_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _433_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4781 = fa_tex_fix(param_20, param_21);\n    float _6319 = _433_fa_layers_a.x;\n    float _6320 = _433_fa_layers_a.y;\n    float _6323 = _433_fa_layers_a.z;\n    float _6322 = _433_fa_layers_b.w;\n    float _6325 = _433_fa_layers_c.x;\n    if (_433_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_433_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6319 *= _4749.y;\n            _6320 *= _4749.z;\n            _6322 *= _4738.w;\n        }\n        if (_433_fa_layers_c.z > 1.5f)\n        {\n            _6323 *= mrt.x;\n            _6325 *= mrt.w;\n        }\n    }\n    Surface _6352 = { _4636.xyz, _4636.w, _6314, clamp(_433_fa_pbr.x * _4708.z, 0.0f, 1.0f), clamp(_433_fa_pbr.y * _4708.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_433_fa_maps.y * (_4749.x - 1.0f)), _433_fa_emissive.xyz + (_433_fa_model_emissive.xyz * _4781), _6319, _6320, _433_fa_layers_b.xyz, _6322, _6323, _433_fa_layers_a.w, _6325, _433_fa_layers_c.y, _433_fa_layers_d.xyz, _433_fa_tr_a.x, _433_fa_tr_a.y, _433_fa_tr_b.xyz, _433_fa_tr_a.z };\n    return _6352;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1592 = rect.zw - rect.xy;\n    float2 _1596 = _1592 * atlas;\n    float2 _1600 = ddx * _1596;\n    float2 _1604 = ddy * _1596;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1592), clamp(0.5f * log2(max(max(dot(_1600, _1600), dot(_1604, _1604)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1637 = _433_fa_counts.y < 0.5f;\n    bool _1644;\n    if (!_1637)\n    {\n        _1644 = _433_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1644 = _1637;\n    }\n    if (_1644)\n    {\n        return;\n    }\n    float3 _1650 = ddx(world_pos);\n    float3 _1653 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1657 = fa_cluster_texel(param);\n    int _1661 = int(_1657.w);\n    if (_1661 < 1)\n    {\n        return;\n    }\n    int _1671 = int(_433_fa_counts.y + 0.5f);\n    int param_1 = _1671;\n    float4 _1675 = fa_light_texel(param_1);\n    float2 _1678 = _1675.yz;\n    int _1682 = int(_1675.w);\n    int param_2 = _1671 + 1;\n    float4 _1687 = fa_light_texel(param_2);\n    float _1688 = _1687.x;\n    int _1694 = int(_433_fa_counts.w + 0.5f) - 1;\n    int _1698 = int(_1657.z);\n    float3 _1963;\n    for (int k = 0; k < _1661; k++)\n    {\n        int _1711 = _1698 + k;\n        int param_3 = _1682 + (_1711 >> 2);\n        int _1728 = (_1671 + 2) + (int(fa_light_texel(param_3)[_1711 & 3]) * 7);\n        int param_4 = _1728 + 6;\n        float4 _1733 = fa_light_texel(param_4);\n        if (((int(_1733.w + 0.5f) >> _1694) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1728;\n        float4 _1748 = fa_light_texel(param_5);\n        int param_6 = _1728 + 1;\n        float4 _1753 = fa_light_texel(param_6);\n        int param_7 = _1728 + 2;\n        float4 _1758 = fa_light_texel(param_7);\n        float3 _1761 = _1748.xyz;\n        float _1766 = dot(_1761, world_pos) + _1748.w;\n        float3 _1768 = _1753.xyz;\n        float _1773 = dot(_1768, world_pos) + _1753.w;\n        float3 _1775 = _1758.xyz;\n        float _1780 = dot(_1775, world_pos) + _1758.w;\n        bool _1785 = abs(_1766) > 0.5f;\n        bool _1793;\n        if (!_1785)\n        {\n            _1793 = abs(_1773) > 0.5f;\n        }\n        else\n        {\n            _1793 = _1785;\n        }\n        bool _1801;\n        if (!_1793)\n        {\n            _1801 = abs(_1780) > 0.5f;\n        }\n        else\n        {\n            _1801 = _1793;\n        }\n        if (_1801)\n        {\n            continue;\n        }\n        float _1816 = clamp(dot(geo_normal, normalize(_1775)) * _1733.z, 0.0f, 1.0f);\n        if (_1816 <= 0.0f)\n        {\n            continue;\n        }\n        float _1836 = (clamp((0.5f - abs(_1780)) * 10.0f, 0.0f, 1.0f) * _1816) * _1733.x;\n        float2 _1844 = float2(_1766 + 0.5f, 0.5f - _1773);\n        float2 _1854 = float2(dot(_1761, _1650), dot(_1768, _1650));\n        float2 _1864 = float2(dot(_1761, _1653), dot(_1768, _1653));\n        int param_8 = _1728 + 5;\n        float4 _1869 = fa_light_texel(param_8);\n        int param_9 = _1728 + 3;\n        float4 _1874 = fa_light_texel(param_9);\n        int param_10 = _1728 + 4;\n        float4 _1879 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1869.xyz;\n        bool _1889 = _1874.z > _1874.x;\n        if (_1889)\n        {\n            float4 param_11 = _1874;\n            float2 param_12 = _1844;\n            float2 param_13 = _1678;\n            float2 param_14 = _1854;\n            float2 param_15 = _1864;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1688 > 0.5f) && (_1688 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1915 = fa_dc_to_linear(param_16);\n                float4 _6402 = tx;\n                _6402.x = _1915.x;\n                _6402.y = _1915.y;\n                _6402.z = _1915.z;\n                tx = _6402;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1836 * tex_a) * _1869.w, 0.0f, 1.0f).xxx);\n        if (_1879.z > _1879.x)\n        {\n            float4 param_17 = _1879;\n            float2 param_18 = _1844;\n            float2 param_19 = _1678;\n            float2 param_20 = _1854;\n            float2 param_21 = _1864;\n            float4 _1959 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1688 > 1.5f)\n            {\n                float3 param_22 = _1959.xyz;\n                float3 _1969 = fa_dc_to_srgb(param_22);\n                _1963 = _1969;\n            }\n            else\n            {\n                _1963 = _1959.xyz;\n            }\n            float3 _1978 = (_1963 * 2.0f) - 1.0f.xxx;\n            float2 _1983 = _1978.xy * _1733.y;\n            float3 _2005 = (normalize(_1761) * _1983.x) + (normalize(_1768) * _1983.y);\n            float3 _2008 = normalize(normal);\n            normal = normalize(lerp(_2008, normalize((_2008 * max(_1978.z, 0.0500000007450580596923828125f)) + (_2005 - (_2008 * dot(_2008, _2005)))), clamp(_1836 * (_1889 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3844_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3844_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_433_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3785 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3785;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3894 = (1.0f - _433_fa_rpa_tile.w) - _433_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3900 = _433_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3894 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3900)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _433_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3894;\n            }\n        }\n        else\n        {\n            amb = _433_fa_ambient.xyz * _3894;\n        }\n    }\n    bool _3952 = _433_fa_rpa_tile.w > 0.0f;\n    if (_3952)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _433_fa_rpa_tile.xy;\n            float param_4 = _433_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _433_fa_rpa_tile.w);\n        }\n    }\n    bool _3983 = _433_fa_rpb_tile.w > 0.0f;\n    if (_3983)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _433_fa_rpb_tile.xy;\n            float param_7 = _433_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _433_fa_rpb_tile.w);\n        }\n    }\n    if ((_3900 || _3952) || _3983)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3805 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3808 = _3805.x;\n    float _3810 = _3805.z;\n    float2 e = float2(_3808, _3810);\n    if (_3805.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3810)) * ((_3808 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3808)) * ((_3810 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _4895 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _4900 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _4905 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _4910 = fa_light_texel(param_3);\n    bool _4913 = _4910.z < 0.5f;\n    bool _4921;\n    if (!_4913)\n    {\n        _4921 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _4921 = _4913;\n    }\n    if (_4921)\n    {\n        return 0.0f.xxx;\n    }\n    float _4928 = max(_4895.w, 9.9999997473787516355514526367188e-05f);\n    float3 _4931 = _4900.xyz;\n    float3 _4935 = _4895.xyz;\n    float3 _4939 = (fa_world_pos - _4935) / _4928.xxx;\n    float3 _4948 = min(_4939 + 0.5f.xxx, (_4931 - 0.5f.xxx) - _4939);\n    float _4957 = min(_4948.x, min(_4948.y, _4948.z));\n    if (!(_4957 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4972 = _4931 - 1.0f.xxx;\n    float3 _4973 = clamp(_4939, 0.0f.xxx, _4972);\n    float3 _4981 = min(floor(_4973), max(_4931 - 2.0f.xxx, 0.0f.xxx));\n    float3 _4985 = _4973 - _4981;\n    float3 _4997 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _4928));\n    int _5002 = int(_4905.y + 0.5f);\n    float _5007 = 0.3257350027561187744140625f * n.y;\n    float _5011 = 0.3257350027561187744140625f * n.z;\n    float _5015 = 0.3257350027561187744140625f * n.x;\n    float _5022 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _5029 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _5038 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _5045 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _5058 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _5065 = 8 + int(_4910.w);\n    float _5092;\n    float _5105;\n    float _5119;\n    for (int k = 0; k < _5065; k++)\n    {\n        float _5078 = float(k & 1);\n        float _5082 = float((k >> 1) & 1);\n        float _5086 = float((k >> 2) & 1);\n        if (_5078 > 0.5f)\n        {\n            _5092 = _4985.x;\n        }\n        else\n        {\n            _5092 = 1.0f - _4985.x;\n        }\n        if (_5082 > 0.5f)\n        {\n            _5105 = _4985.y;\n        }\n        else\n        {\n            _5105 = 1.0f - _4985.y;\n        }\n        if (_5086 > 0.5f)\n        {\n            _5119 = _4985.z;\n        }\n        else\n        {\n            _5119 = 1.0f - _4985.z;\n        }\n        float _5129 = (_5092 * _5105) * _5119;\n        if (!(_5129 > 0.0f))\n        {\n            continue;\n        }\n        float3 _5142 = min(_4981 + float3(_5078, _5082, _5086), _4972);\n        int _5162 = int(((_4905.x + _5142.x) + (_4900.x * (_5142.y + (_4900.y * _5142.z)))) + 0.5f);\n        float2 _5177 = float2(float(_5162 % _5002) * 10.0f, 1024.0f + (float(_5162 / _5002) * 11.0f));\n        float2 param_4 = _5177 + float2(9.5f, 10.5f);\n        float4 _5185 = fa_gi_fetch(param_4);\n        bool _5188 = _5185.y < 0.5f;\n        bool _5197;\n        if (!_5188)\n        {\n            _5197 = _5185.x > _4910.y;\n        }\n        else\n        {\n            _5197 = _5188;\n        }\n        if (_5197)\n        {\n            continue;\n        }\n        float3 _5209 = _4997 - (_4935 + (_5142 * _4928));\n        float _5212 = length(_5209);\n        float3 _5218 = _5209 / max(_5212, 9.9999997473787516355514526367188e-05f).xxx;\n        float _5228 = max(9.9999997473787516355514526367188e-05f, (dot(-_5218, n) + 1.0f) * 0.5f);\n        float w = _5129 * (_5228 * _5228);\n        float3 param_5 = _5218;\n        float2 param_6 = (_5177 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _5248 = fa_gi_fetch(param_6);\n        float _5255 = _5212 / max(_4905.z, 9.9999997473787516355514526367188e-05f);\n        float _5258 = _5248.x;\n        if (_5255 > _5258)\n        {\n            float _5271 = max(_5248.y - (_5258 * _5258), 0.0f);\n            float _5276 = _5255 - _5258;\n            float _5285 = _5271 / max(_5271 + (_5276 * _5276), 9.9999999600419720025001879548654e-13f);\n            w *= ((_5285 * _5285) * _5285);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _5177 + float2(0.5f, 10.5f);\n        float2 param_8 = _5177 + float2(1.5f, 10.5f);\n        float2 param_9 = _5177 + float2(2.5f, 10.5f);\n        float2 param_10 = _5177 + float2(3.5f, 10.5f);\n        float2 param_11 = _5177 + float2(4.5f, 10.5f);\n        float2 param_12 = _5177 + float2(5.5f, 10.5f);\n        float2 param_13 = _5177 + float2(6.5f, 10.5f);\n        float2 param_14 = _5177 + float2(7.5f, 10.5f);\n        float2 param_15 = _5177 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _5007)) + (fa_gi_fetch(param_9).xyz * _5011)) + (fa_gi_fetch(param_10).xyz * _5015)) + (fa_gi_fetch(param_11).xyz * _5022)) + (fa_gi_fetch(param_12).xyz * _5029)) + (fa_gi_fetch(param_13).xyz * _5038)) + (fa_gi_fetch(param_14).xyz * _5045)) + (fa_gi_fetch(param_15).xyz * _5058)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_4957 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _5413;\n    if (_433_fa_gi.z > 0.5f)\n    {\n        _5413 = _4910.x;\n    }\n    else\n    {\n        _5413 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_4905.w * _5413);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _5437 = normalize(_433_fa_camera_pos.xyz - fa_world_pos);\n    int _5442 = int(_433_fa_gi.x + 0.5f);\n    int _5447 = int(_433_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _5447) && (k < 8); k++)\n    {\n        int param = _5442 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _5437;\n        float3 _5472 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5477 = param_3 * left;\n        acc += (_5472 * _5477);\n        left -= _5477;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_433_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _5506 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5506;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_433_fa_gi_px.x > 0.5f)\n    {\n        float4 _5548 = float4(fa_world_pos, 1.0f);\n        float2 _5567 = float2(dot(_433_fa_ct_vpx, _5548), dot(_433_fa_ct_vpy, _5548)) / max(dot(_433_fa_ct_vpw, _5548), 9.9999997473787516355514526367188e-05f).xx;\n        float _5576;\n        if (_433_fa_ct_a.y > 0.5f)\n        {\n            _5576 = (_5567.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5576 = 0.5f - (_5567.y * 0.5f);\n        }\n        return fa_lightmap.Load(int3(clamp(int2(float2((_5567.x * 0.5f) + 0.5f, _5576) * _433_fa_ct_a.zw), int2(0, 0), int2(_433_fa_ct_a.zw) - int2(1, 1)), 0)).xyz;\n    }\n    if (_433_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _433_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_433_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_433_fa_cl_info.x) + int(_433_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_433_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4292;\n    if (fa_lm.z > 0.5f)\n    {\n        _4292 = 0.0f;\n    }\n    else\n    {\n        _4292 = 1.0f - clamp(_433_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4303 = _4292 < 1.0f;\n    bool _4309;\n    if (_4303)\n    {\n        int param = li;\n        _4309 = fa_light_baked(param);\n    }\n    else\n    {\n        _4309 = _4303;\n    }\n    return _4309 ? _4292 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _611 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _624 = (c - (ru * hx)) - p;\n        float3 _630 = ru * (2.0f * hx);\n        float _636 = max(dot(_630, _630), 9.9999999392252902907785028219223e-09f);\n        float _640 = dot(_624, _630);\n        float t = clamp((-_640) / _636, 0.0f, 1.0f);\n        if (_611)\n        {\n            float _655 = dot(r, _630);\n            float _661 = _636 - (_655 * _655);\n            if (abs(_661) > (9.9999997473787516355514526367188e-06f * _636))\n            {\n                t = clamp(((dot(r, _624) * _655) - _640) / _661, 0.0f, 1.0f);\n            }\n        }\n        return (p + _624) + (_630 * t);\n    }\n    float3 q = p;\n    float _693 = dot(r, axis);\n    bool _701;\n    if (_611)\n    {\n        _701 = abs(_693) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _701 = _611;\n    }\n    if (_701)\n    {\n        float _711 = dot(c - p, axis) / _693;\n        if (_711 > 0.0f)\n        {\n            q = p + (r * _711);\n        }\n    }\n    float3 _724 = q - c;\n    float2 xy = float2(dot(_724, ru), dot(_724, uu));\n    if (shape > 0.5f)\n    {\n        float _739 = length(xy);\n        if (_739 > hx)\n        {\n            xy *= (hx / _739);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _492_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _492_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _531 = dot(d, right);\n    float _535 = dot(d, up);\n    float _546;\n    if (((_531 * _531) + (_535 * _535)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _546 = atan2(_535, _531) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _546 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_546 - floor(_546)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _382 = abs(d);\n    float _384 = _382.x;\n    float _386 = _382.y;\n    bool _387 = _384 >= _386;\n    bool _395;\n    if (_387)\n    {\n        _395 = _384 >= _382.z;\n    }\n    else\n    {\n        _395 = _387;\n    }\n    int _396;\n    if (_395)\n    {\n        _396 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _410;\n        if (_386 >= _382.z)\n        {\n            _410 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _410 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _396 = _410;\n    }\n    return _396;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _777 = fa_light_base(param);\n    bool _781 = _433_fa_ambient.w > 4.5f;\n    int param_1 = _777;\n    float4 _785 = fa_light_texel(param_1);\n    int param_2 = _777 + 1;\n    float4 _790 = fa_light_texel(param_2);\n    float _793 = _790.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _805 = _781 && (_793 > 2.5f);\n    fa_light_is_area = _805;\n    bool _807 = _793 < 0.5f;\n    float3 l;\n    if (_807)\n    {\n        l = normalize(_785.xyz);\n        if (_781)\n        {\n            int param_3 = _777 + 6;\n            float4 _821 = fa_light_texel(param_3);\n            if (_821.z > 0.5f)\n            {\n                int param_4 = _777 + 4;\n                float4 _831 = fa_light_texel(param_4);\n                int param_5 = _777 + 5;\n                float4 _836 = fa_light_texel(param_5);\n                float2 param_6 = _821.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _831.xyz) * _831.w, (-dot(world_pos, _836.xyz)) * _836.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _866 = _785.xyz;\n        float3 _868 = _866 - world_pos;\n        float3 to_light = _868;\n        float _871 = length(_868);\n        float reach = _871;\n        bool front = true;\n        if (_805)\n        {\n            int param_8 = _777 + 7;\n            reach = max(_871 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _777 + 4;\n            float4 _895 = fa_light_texel(param_9);\n            int param_10 = _777 + 5;\n            float4 _900 = fa_light_texel(param_10);\n            int param_11 = _777 + 6;\n            float4 _905 = fa_light_texel(param_11);\n            float _906 = _905.w;\n            int param_12 = _777 + 2;\n            float3 _913 = normalize(fa_light_texel(param_12).xyz);\n            bool _915 = _906 > 1.5f;\n            bool _923;\n            if (!_915)\n            {\n                _923 = dot(_913, to_light) < 0.0f;\n            }\n            else\n            {\n                _923 = _915;\n            }\n            front = _923;\n            float3 r = 0.0f.xxx;\n            float3 _932 = _433_fa_camera_pos.xyz - world_pos;\n            bool _936 = dot(n, n) > 0.5f;\n            bool _944;\n            if (_936)\n            {\n                _944 = dot(_932, _932) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _944 = _936;\n            }\n            if (_944)\n            {\n                r = reflect(-normalize(_932), normalize(n));\n            }\n            float3 param_13 = _866;\n            float3 param_14 = _913;\n            float3 param_15 = _895.xyz;\n            float3 param_16 = _900.xyz;\n            float param_17 = _895.w;\n            float param_18 = _900.w;\n            float param_19 = _906;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _980 = length(to_light);\n        dist = _980;\n        l = to_light / max(_980, 9.9999997473787516355514526367188e-05f).xxx;\n        float _994 = reach / max(_785.w, 0.001000000047497451305389404296875f);\n        float _1000 = clamp(1.0f - (_994 * _994), 0.0f, 1.0f);\n        float _1002;\n        if (front)\n        {\n            _1002 = _1000 * _1000;\n        }\n        else\n        {\n            _1002 = 0.0f;\n        }\n        atten = _1002;\n        bool _1013 = _793 < 2.5f;\n        if ((_793 > 1.5f) && _1013)\n        {\n            int param_22 = _777 + 2;\n            float4 _1021 = fa_light_texel(param_22);\n            float _1031 = _1021.w;\n            int param_23 = _777 + 3;\n            float4 _1036 = fa_light_texel(param_23);\n            float _1037 = _1036.x;\n            float cos_inner = _1037;\n            if (_1037 > 1.5f)\n            {\n                cos_inner = lerp(_1031, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1031, cos_inner, dot(-l, normalize(_1021.xyz)));\n        }\n        if (_781 && (_793 < 1.5f))\n        {\n            int param_24 = _777 + 6;\n            float4 _1061 = fa_light_texel(param_24);\n            if (_1061.z > 0.5f)\n            {\n                float3 _1069 = -to_light;\n                int param_25 = _777 + 4;\n                int param_26 = _777 + 5;\n                float3 _1083 = fa_light_texel(param_25).xyz;\n                float3 _1087 = fa_light_texel(param_26).xyz;\n                float3 _1096 = float3(dot(_1069, _1083), dot(_1069, _1087), dot(_1069, cross(_1083, _1087)));\n                float3 param_27 = _1096;\n                int _1100 = fa_cube_face(param_27);\n                int param_28 = _1100;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1127 = float2(dot(_1096, cross(param_29, param_30)), dot(_1096, param_30)) / max(dot(_1096, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1131 = _1100 / 3;\n                float2 param_31 = _1061.xy + (float2(float(_1100 - (_1131 * 3)), float(_1131)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1127.x), 0.5f - (0.5f * _1127.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _777 + 7;\n            float4 _1161 = fa_light_texel(param_33);\n            if (_1161.z > 0.5f)\n            {\n                int param_34 = _777 + 2;\n                int param_35 = _777 + 4;\n                int param_36 = _777 + 5;\n                float2 param_37 = _1161.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_781 && _1013)\n            {\n                int param_42 = _777 + 6;\n                float4 _1208 = fa_light_texel(param_42);\n                int param_43 = _777 + 7;\n                float4 _1213 = fa_light_texel(param_43);\n                bool _1216 = _1208.z > 0.5f;\n                bool _1223;\n                if (!_1216)\n                {\n                    _1223 = _1213.z > 0.5f;\n                }\n                else\n                {\n                    _1223 = _1216;\n                }\n                if (_1223)\n                {\n                    int param_44 = _777 + 2;\n                    float4 _1230 = fa_light_texel(param_44);\n                    float3 _1234 = normalize(_1230.xyz);\n                    int param_45 = _777 + 4;\n                    float4 _1239 = fa_light_texel(param_45);\n                    int param_46 = _777 + 5;\n                    float4 _1244 = fa_light_texel(param_46);\n                    if (_1216)\n                    {\n                        float3 _1252 = -to_light;\n                        float _1259 = _1230.w;\n                        float _1275 = 0.5f / max(dot(_1252, _1234) * (sqrt(max(1.0f - (_1259 * _1259), 0.0f)) / max(_1259, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1208.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1252, _1239.xyz) * _1275), 0.5f - (dot(_1252, _1244.xyz) * _1275));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1213.z > 0.5f)\n                    {\n                        float2 param_49 = _1213.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1234;\n                        float3 param_52 = _1239.xyz;\n                        float3 param_53 = _1244.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6268 = _790.xyz * atten;\n    if (_781)\n    {\n        _6268 *= fa_light_tint;\n    }\n    int _1343;\n    if (_807)\n    {\n        _1343 = 0;\n    }\n    else\n    {\n        _1343 = ((_793 > 1.5f) && (_793 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _6279 = { l, _6268, atten, 1.0f, dist, _1343 };\n    return _6279;\n}\n\nfloat fa_rt_local_tap(int2 p, int2 size, float d, float tol, float div, inout float best)\n{\n    float4 _3304 = fa_screen_tex.Load(int3(clamp(p, int2(0, 0), size - int2(1, 1)), 0));\n    bool _3307 = _3304.w > 0.5f;\n    bool _3317;\n    if (_3307)\n    {\n        _3317 = abs(d - _3304.x) <= tol;\n    }\n    else\n    {\n        _3317 = _3307;\n    }\n    if (_3317)\n    {\n        best = min(best, mod(floor(_3304.z / div), 256.0f) * 0.0039215688593685626983642578125f);\n    }\n    return best;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2132 = fa_shadow_depth(param, param_1);\n    float _2136;\n    if (conv.x < 0.5f)\n    {\n        _2136 = _2132;\n    }\n    else\n    {\n        _2136 = (conv.y * conv.z) / (conv.z - (_2132 * (conv.z - conv.y)));\n    }\n    return _2136;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2182 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2188 = float2(cos(_2182), sin(_2182));\n    float2 dir = _2188;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2197;\n        if (k < 0.0f)\n        {\n            _2197 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2197 = k;\n        }\n        float _2216 = clamp((_2197 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2235 = sqrt((float(i) + 0.5f) * 0.0625f) * _2216;\n            float2 param_3 = uv + (dir * (_2085_fa_shadow_bias.zw * _2235));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2249 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2249 < (zr - (_2235 * plane)))\n            {\n                sum += _2249;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2277 = sum / cnt;\n        float _2287;\n        if (k < 0.0f)\n        {\n            _2287 = (-k) / max(_2277, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2287 = k;\n        }\n        radius = clamp(((max(zr - _2277, 0.0f) * unit) * _2287) / texel_m, 1.5f, 16.0f);\n        dir = _2188;\n    }\n    float lit = 0.0f;\n    int _2313 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2313; i_1++)\n    {\n        float _2332 = sqrt((float(i_1) + 0.5f) / float(_2313)) * radius;\n        float2 param_7 = uv + (dir * (_2085_fa_shadow_bias.zw * _2332));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2332 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2313);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2537 = _433_fa_pbr.z < 0.5f;\n    bool _2544;\n    if (!_2537)\n    {\n        _2544 = _2085_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2544 = _2537;\n    }\n    if (_2544)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2085_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2557 = fa_light_texel(param);\n    float _2558 = _2557.x;\n    if (_2558 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2567 = int(_2558 + 0.5f);\n    int param_1 = _2567;\n    float4 _2571 = fa_light_texel(param_1);\n    int param_2 = _2567 + 1;\n    float4 _2576 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2579 = _2571.y;\n    if (_2579 > 0.0f)\n    {\n        float _2596 = 1.0f - smoothstep(0.75f * _2579, _2579, length(world - _2085_fa_shadow_eye.xyz));\n        fade = _2596;\n        if (_2596 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2571.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2620 = (_2567 + 2) + (face * 6);\n    int param_4 = _2620;\n    int param_5 = _2620 + 1;\n    int param_6 = _2620 + 3;\n    float4 _2634 = fa_light_texel(param_6);\n    int param_7 = _2620 + 4;\n    float4 _2639 = fa_light_texel(param_7);\n    int param_8 = _2620 + 5;\n    float4 _2644 = fa_light_texel(param_8);\n    float _2656 = _2644.x * max(dot(_2634, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2661 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2684 = clamp(dot(n, _2634.xyz), -1.0f, 1.0f);\n    float _2703 = min(sqrt(1.0f - (_2684 * _2684)) / max(abs(dot(n, world - lpos)) / max(dot(_2634, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2706 = _2576.y;\n    float _2708;\n    if (_2706 > 0.0f)\n    {\n        _2708 = _2706;\n    }\n    else\n    {\n        _2708 = 1.5f * _2656;\n    }\n    float4 _2728 = float4(world + (n * (_2708 * sqrt(1.0f - (_2661 * _2661)))), 1.0f);\n    float _2732 = dot(_2634, _2728);\n    float _2735 = _2644.y;\n    if (_2732 < _2735)\n    {\n        return 1.0f;\n    }\n    float2 _2750 = float2(dot(fa_light_texel(param_4), _2728), dot(fa_light_texel(param_5), _2728)) / _2732.xx;\n    float _2752 = _2750.x;\n    bool _2755 = _2752 < _2639.x;\n    bool _2764;\n    if (!_2755)\n    {\n        _2764 = _2752 > _2639.z;\n    }\n    else\n    {\n        _2764 = _2755;\n    }\n    bool _2773;\n    if (!_2764)\n    {\n        _2773 = _2750.y < _2639.y;\n    }\n    else\n    {\n        _2773 = _2764;\n    }\n    bool _2782;\n    if (!_2773)\n    {\n        _2782 = _2750.y > _2639.w;\n    }\n    else\n    {\n        _2782 = _2773;\n    }\n    if (_2782)\n    {\n        return 1.0f;\n    }\n    float _2788 = _2576.x;\n    float _2790;\n    if (_2788 > 0.0f)\n    {\n        _2790 = _2788;\n    }\n    else\n    {\n        _2790 = 1.5f * _2656;\n    }\n    float2 param_9 = _2750;\n    float4 param_10 = _2639;\n    float param_11 = _2732 - (_2790 * (1.0f + (0.5f * _2703)));\n    float param_12 = _2656;\n    float param_13 = 1.0f;\n    float param_14 = _2644.z * 0.25f;\n    float param_15 = (_2656 * min(_2703, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2735, _2644.z);\n    int param_17 = int(_2571.z + 0.5f);\n    float param_18 = _2571.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _3335 = _433_fa_ct_b.w > 0.5f;\n    bool _3341;\n    if (_3335)\n    {\n        _3341 = _433_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3341 = _3335;\n    }\n    bool _3347;\n    if (_3341)\n    {\n        _3347 = _2085_fa_shadow_lcfg.x > 0.5f;\n    }\n    else\n    {\n        _3347 = _3341;\n    }\n    if (_3347)\n    {\n        int param = (int(_2085_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n        float4 _3359 = fa_light_texel(param);\n        float _3360 = _3359.z;\n        if (_3360 > 0.5f)\n        {\n            float _3373 = dot(_433_fa_ct_fwd.xyz, world) + _433_fa_ct_fwd.w;\n            float _3379 = ((0.00200000009499490261077880859375f * _3373) + 0.00999999977648258209228515625f) + fa_rt_slope;\n            float4 _3385 = float4(world, 1.0f);\n            float _3390 = dot(_433_fa_ct_vpw, _3385);\n            if (_3390 > 9.9999997473787516355514526367188e-05f)\n            {\n                float2 _3407 = float2(dot(_433_fa_ct_vpx, _3385), dot(_433_fa_ct_vpy, _3385)) / _3390.xx;\n                float _3412 = (_3407.x * 0.5f) + 0.5f;\n                float _3416;\n                if (_433_fa_ct_a.y > 0.5f)\n                {\n                    _3416 = (_3407.y * 0.5f) + 0.5f;\n                }\n                else\n                {\n                    _3416 = 0.5f - (_3407.y * 0.5f);\n                }\n                bool _3432 = _3412 >= 0.0f;\n                bool _3438;\n                if (_3432)\n                {\n                    _3438 = _3412 < 1.0f;\n                }\n                else\n                {\n                    _3438 = _3432;\n                }\n                bool _3444;\n                if (_3438)\n                {\n                    _3444 = _3416 >= 0.0f;\n                }\n                else\n                {\n                    _3444 = _3438;\n                }\n                bool _3450;\n                if (_3444)\n                {\n                    _3450 = _3416 < 1.0f;\n                }\n                else\n                {\n                    _3450 = _3444;\n                }\n                if (_3450)\n                {\n                    int2 _3457 = int2(_433_fa_ct_a.zw);\n                    int2 _3468 = clamp(int2(float2(_3412, _3416) * _433_fa_ct_a.zw), int2(0, 0), _3457 - int2(1, 1));\n                    float _3472;\n                    if (_3360 < 1.5f)\n                    {\n                        _3472 = 1.0f;\n                    }\n                    else\n                    {\n                        _3472 = (_3360 < 2.5f) ? 256.0f : 65536.0f;\n                    }\n                    float best = 2.0f;\n                    float4 _3488 = fa_screen_tex.Load(int3(_3468, 0));\n                    bool _3491 = _3488.w > 0.5f;\n                    bool _3501;\n                    if (_3491)\n                    {\n                        _3501 = abs(_3373 - _3488.x) <= _3379;\n                    }\n                    else\n                    {\n                        _3501 = _3491;\n                    }\n                    if (_3501)\n                    {\n                        best = mod(floor(_3488.z / _3472), 256.0f) * 0.0039215688593685626983642578125f;\n                    }\n                    else\n                    {\n                        int2 param_1 = _3468 + int2(-1, -1);\n                        int2 param_2 = _3457;\n                        float param_3 = _3373;\n                        float param_4 = _3379;\n                        float param_5 = _3472;\n                        float param_6 = best;\n                        float _3527 = fa_rt_local_tap(param_1, param_2, param_3, param_4, param_5, param_6);\n                        best = _3527;\n                        int2 param_7 = _3468 + int2(0, -1);\n                        int2 param_8 = _3457;\n                        float param_9 = _3373;\n                        float param_10 = _3379;\n                        float param_11 = _3472;\n                        float param_12 = _3527;\n                        float _3542 = fa_rt_local_tap(param_7, param_8, param_9, param_10, param_11, param_12);\n                        best = _3542;\n                        int2 param_13 = _3468 + int2(1, -1);\n                        int2 param_14 = _3457;\n                        float param_15 = _3373;\n                        float param_16 = _3379;\n                        float param_17 = _3472;\n                        float param_18 = _3542;\n                        float _3557 = fa_rt_local_tap(param_13, param_14, param_15, param_16, param_17, param_18);\n                        best = _3557;\n                        int2 param_19 = _3468 + int2(-1, 0);\n                        int2 param_20 = _3457;\n                        float param_21 = _3373;\n                        float param_22 = _3379;\n                        float param_23 = _3472;\n                        float param_24 = _3557;\n                        float _3572 = fa_rt_local_tap(param_19, param_20, param_21, param_22, param_23, param_24);\n                        best = _3572;\n                        int2 param_25 = _3468 + int2(1, 0);\n                        int2 param_26 = _3457;\n                        float param_27 = _3373;\n                        float param_28 = _3379;\n                        float param_29 = _3472;\n                        float param_30 = _3572;\n                        float _3587 = fa_rt_local_tap(param_25, param_26, param_27, param_28, param_29, param_30);\n                        best = _3587;\n                        int2 param_31 = _3468 + int2(-1, 1);\n                        int2 param_32 = _3457;\n                        float param_33 = _3373;\n                        float param_34 = _3379;\n                        float param_35 = _3472;\n                        float param_36 = _3587;\n                        float _3602 = fa_rt_local_tap(param_31, param_32, param_33, param_34, param_35, param_36);\n                        best = _3602;\n                        int2 param_37 = _3468 + int2(0, 1);\n                        int2 param_38 = _3457;\n                        float param_39 = _3373;\n                        float param_40 = _3379;\n                        float param_41 = _3472;\n                        float param_42 = _3602;\n                        float _3617 = fa_rt_local_tap(param_37, param_38, param_39, param_40, param_41, param_42);\n                        best = _3617;\n                        int2 param_43 = _3468 + int2(1, 1);\n                        int2 param_44 = _3457;\n                        float param_45 = _3373;\n                        float param_46 = _3379;\n                        float param_47 = _3472;\n                        float param_48 = _3617;\n                        float _3632 = fa_rt_local_tap(param_43, param_44, param_45, param_46, param_47, param_48);\n                        best = _3632;\n                    }\n                    if (best <= 1.0f)\n                    {\n                        float _3640;\n                        if (_433_fa_ct_b.z > 0.5f)\n                        {\n                            int param_49 = li;\n                            float3 param_50 = lpos;\n                            float3 param_51 = world;\n                            float3 param_52 = n;\n                            float3 param_53 = l;\n                            _3640 = min(best, fa_shadow_local(param_49, param_50, param_51, param_52, param_53));\n                        }\n                        else\n                        {\n                            _3640 = best;\n                        }\n                        return _3640;\n                    }\n                }\n            }\n            float _3663;\n            if (_433_fa_ct_b.z > 0.5f)\n            {\n                int param_54 = li;\n                float3 param_55 = lpos;\n                float3 param_56 = world;\n                float3 param_57 = n;\n                float3 param_58 = l;\n                _3663 = fa_shadow_local(param_54, param_55, param_56, param_57, param_58);\n            }\n            else\n            {\n                _3663 = 1.0f;\n            }\n            return _3663;\n        }\n    }\n    int param_59 = li;\n    float3 param_60 = lpos;\n    float3 param_61 = world;\n    float3 param_62 = n;\n    float3 param_63 = l;\n    return fa_shadow_local(param_59, param_60, param_61, param_62, param_63);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2075;\n    if (i == 0)\n    {\n        _2075 = _2085_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2091;\n        if (i == 1)\n        {\n            _2091 = _2085_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2099;\n            if (i == 2)\n            {\n                _2099 = _2085_fa_shadow_split.z;\n            }\n            else\n            {\n                _2099 = _2085_fa_shadow_split.w;\n            }\n            _2091 = _2099;\n        }\n        _2075 = _2091;\n    }\n    return _2075;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2378 = max(_2085_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2383 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2389 = sqrt(1.0f - (_2383 * _2383));\n    float _2397 = min(_2389 / max(_2383, 0.20000000298023223876953125f), 4.0f);\n    float _2402;\n    if (_2085_fa_shadow_bias.y > 0.0f)\n    {\n        _2402 = _2085_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2402 = 1.5f * _2085_fa_shadow_info[ci].x;\n    }\n    float4 _2427 = mul(float4(world + (n * (_2402 * _2389)), 1.0f), _2085_fa_shadow_mat[ci]);\n    float _2434 = _2427.x;\n    bool _2437 = _2434 < _2085_fa_shadow_rect[ci].x;\n    bool _2446;\n    if (!_2437)\n    {\n        _2446 = _2434 > _2085_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2446 = _2437;\n    }\n    bool _2455;\n    if (!_2446)\n    {\n        _2455 = _2427.y < _2085_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2455 = _2446;\n    }\n    bool _2464;\n    if (!_2455)\n    {\n        _2464 = _2427.y > _2085_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2464 = _2455;\n    }\n    bool _2471;\n    if (!_2464)\n    {\n        _2471 = _2427.z > 1.0f;\n    }\n    else\n    {\n        _2471 = _2464;\n    }\n    if (_2471)\n    {\n        return -1.0f;\n    }\n    float _2479;\n    if (_2085_fa_shadow_bias.x > 0.0f)\n    {\n        _2479 = _2085_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2479 = 1.5f * _2085_fa_shadow_info[ci].x;\n    }\n    float2 param = _2427.xy;\n    float4 param_1 = _2085_fa_shadow_rect[ci];\n    float param_2 = _2427.z - ((_2479 * (1.0f + (0.5f * _2397))) / _2378);\n    float param_3 = _2085_fa_shadow_info[ci].x;\n    float param_4 = _2378;\n    float param_5 = _2378 * 0.25f;\n    float param_6 = ((_2085_fa_shadow_info[ci].x * min(_2397, 3.0f)) * 0.5f) / _2378;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2085_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2085_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_433_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2857 = int(_2085_fa_shadow_cfg.x + 0.5f);\n    if (_2857 < 1)\n    {\n        return 1.0f;\n    }\n    float _2872 = dot(world - _2085_fa_shadow_eye.xyz, _2085_fa_shadow_fwd.xyz);\n    int param = _2857 - 1;\n    if (_2872 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2884 = _2857 > 1;\n    bool _2891;\n    if (_2884)\n    {\n        _2891 = _2872 > _2085_fa_shadow_split.x;\n    }\n    else\n    {\n        _2891 = _2884;\n    }\n    if (_2891)\n    {\n        ci = 1;\n    }\n    bool _2895 = _2857 > 2;\n    bool _2902;\n    if (_2895)\n    {\n        _2902 = _2872 > _2085_fa_shadow_split.y;\n    }\n    else\n    {\n        _2902 = _2895;\n    }\n    if (_2902)\n    {\n        ci = 2;\n    }\n    bool _2906 = _2857 > 3;\n    bool _2913;\n    if (_2906)\n    {\n        _2913 = _2872 > _2085_fa_shadow_split.z;\n    }\n    else\n    {\n        _2913 = _2906;\n    }\n    if (_2913)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _2924 = min(_2857, 4);\n    float _2965;\n    for (int c = ci; c < _2924; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2944 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _2944;\n            break;\n        }\n        if (_2944 < 0.0f)\n        {\n            continue;\n        }\n        s = _2944;\n        ci = c;\n        if (_2085_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2965 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2965 = _2085_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _2984 = _2085_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2965, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_2872 - (fa_shadow_split_at(param_7) - _2984)) / _2984, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3016;\n        if ((ci + 1) < _2857)\n        {\n            _3016 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3016 = 1.0f;\n        }\n        s = lerp(s, _3016, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    bool _3121 = _433_fa_ct_b.y > 0.5f;\n    bool _3127;\n    if (_3121)\n    {\n        _3127 = _433_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3127 = _3121;\n    }\n    if (_3127)\n    {\n        float _3141 = dot(_433_fa_ct_fwd.xyz, fa_world_pos) + _433_fa_ct_fwd.w;\n        float4 _3149 = float4(fa_world_pos, 1.0f);\n        float _3155 = dot(_433_fa_ct_vpw, _3149);\n        if (_3155 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _3174 = float2(dot(_433_fa_ct_vpx, _3149), dot(_433_fa_ct_vpy, _3149)) / _3155.xx;\n            float _3179 = (_3174.x * 0.5f) + 0.5f;\n            float _3183;\n            if (_433_fa_ct_a.y > 0.5f)\n            {\n                _3183 = (_3174.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _3183 = 0.5f - (_3174.y * 0.5f);\n            }\n            bool _3199 = _3179 >= 0.0f;\n            bool _3205;\n            if (_3199)\n            {\n                _3205 = _3179 < 1.0f;\n            }\n            else\n            {\n                _3205 = _3199;\n            }\n            bool _3211;\n            if (_3205)\n            {\n                _3211 = _3183 >= 0.0f;\n            }\n            else\n            {\n                _3211 = _3205;\n            }\n            bool _3217;\n            if (_3211)\n            {\n                _3217 = _3183 < 1.0f;\n            }\n            else\n            {\n                _3217 = _3211;\n            }\n            if (_3217)\n            {\n                float4 _3242 = fa_screen_tex.Load(int3(clamp(int2(float2(_3179, _3183) * _433_fa_ct_a.zw), int2(0, 0), int2(_433_fa_ct_a.zw) - int2(1, 1)), 0));\n                bool _3245 = _3242.w > 0.5f;\n                bool _3261;\n                if (_3245)\n                {\n                    _3261 = abs(_3141 - _3242.x) <= (((0.00200000009499490261077880859375f * _3141) + 0.00999999977648258209228515625f) + fa_rt_slope);\n                }\n                else\n                {\n                    _3261 = _3245;\n                }\n                if (_3261)\n                {\n                    float _3267;\n                    if (_433_fa_ct_b.z > 0.5f)\n                    {\n                        float3 param = fa_world_pos;\n                        float3 param_1 = n;\n                        float3 param_2 = l;\n                        _3267 = min(_3242.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3267 = _3242.y;\n                    }\n                    return _3267;\n                }\n            }\n        }\n    }\n    float3 param_3 = fa_world_pos;\n    float3 param_4 = n;\n    float3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4034 = _433_fa_ct_a.x < 0.5f;\n    bool _4041;\n    if (!_4034)\n    {\n        _4041 = _2085_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4041 = _4034;\n    }\n    if (_4041)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2085_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4054 = fa_light_texel(param);\n    float _4055 = _4054.y;\n    float len = _4055;\n    if (_4055 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4067 = length(world - _433_fa_camera_pos.xyz);\n    float _4076 = 1.0f - smoothstep(0.5f * _433_fa_ct_b.x, _433_fa_ct_b.x, _4067);\n    if (_4076 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4082 = len;\n    float _4085 = min(_4082, 0.89999997615814208984375f * dist);\n    len = _4085;\n    float _4091 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4067);\n    float _4096 = _4091 + (0.5f * _4085);\n    float3 _4102 = world + (gn * _4091);\n    float _4104 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4166;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4120 = (float(k) + _4104) * 0.083333335816860198974609375f;\n        float3 _4128 = _4102 + (l * (_4120 * len));\n        float4 _4134 = float4(_4128, 1.0f);\n        float _4139 = dot(_433_fa_ct_vpw, _4134);\n        if (_4139 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4157 = float2(dot(_433_fa_ct_vpx, _4134), dot(_433_fa_ct_vpy, _4134)) / _4139.xx;\n        float _4161 = _4157.x * 0.5f;\n        float _4162 = _4161 + 0.5f;\n        if (_433_fa_ct_a.y > 0.5f)\n        {\n            _4166 = (_4157.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4166 = 0.5f - (_4157.y * 0.5f);\n        }\n        bool _4182 = _4162 < 0.0f;\n        bool _4189;\n        if (!_4182)\n        {\n            _4189 = _4162 >= 1.0f;\n        }\n        else\n        {\n            _4189 = _4182;\n        }\n        bool _4196;\n        if (!_4189)\n        {\n            _4196 = _4166 < 0.0f;\n        }\n        else\n        {\n            _4196 = _4189;\n        }\n        bool _4203;\n        if (!_4196)\n        {\n            _4203 = _4166 >= 1.0f;\n        }\n        else\n        {\n            _4203 = _4196;\n        }\n        if (_4203)\n        {\n            break;\n        }\n        float4 _4227 = fa_screen_tex.Load(int3(clamp(int2(float2(_4162, _4166) * _433_fa_ct_a.zw), int2(0, 0), int2(_433_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_4227.w < 0.5f)\n        {\n            continue;\n        }\n        float _4245 = (dot(_433_fa_ct_fwd.xyz, _4128) + _433_fa_ct_fwd.w) - _4227.x;\n        if ((_4245 > _4091) && (_4245 < _4096))\n        {\n            occ = max(occ, (1.0f - (_4120 * _4120)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4162, 0.5f - _4161), min(_4166, 1.0f - _4166))));\n        }\n    }\n    return 1.0f - (occ * _4076);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4377 = fa_baked_keep(param);\n    if (_4377 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _6292 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6292;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4403 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6294 = _4403.color;\n    float _6295 = _4403.attenuation;\n    float _6296 = _4403.shadow;\n    bool _4406 = _4403.type == 0;\n    if (_4406 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4403.direction;\n        float _4417 = fa_shadow_factor(param_5, param_6);\n        _6296 = _4417;\n        _6294 *= _4417;\n    }\n    else\n    {\n        bool _4428 = _4403.type != 0;\n        bool _4434;\n        if (_4428)\n        {\n            _4434 = _6295 > 0.0f;\n        }\n        else\n        {\n            _4434 = _4428;\n        }\n        if (_4434)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4403.direction;\n            float _4453 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6296 = _4453;\n            _6294 *= _4453;\n        }\n    }\n    bool _4463 = _433_fa_ct_a.x > 0.5f;\n    bool _4469;\n    if (_4463)\n    {\n        _4469 = _6295 > 0.0f;\n    }\n    else\n    {\n        _4469 = _4463;\n    }\n    if (_4469)\n    {\n        float _4476;\n        if (_4406)\n        {\n            _4476 = 1000000000.0f;\n        }\n        else\n        {\n            _4476 = _4403._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4403.direction;\n        float param_18 = _4476;\n        float _4494 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6296 *= _4494;\n        _6294 *= _4494;\n    }\n    float _4507 = _6295;\n    float _4508 = _4507 * _4377;\n    _6295 = _4508;\n    float3 _4512 = _6294;\n    float3 _4513 = _4512 * _4377;\n    _6294 = _4513;\n    LightSample _6311 = { _4403.direction, _4513, _4508, _6296, _4403._distance, _4403.type };\n    return _6311;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _4527;\n    if (dot(s.normal, l.direction) > 0.5f)\n    {\n        _4527 = 1.0f;\n    }\n    else\n    {\n        _4527 = _4533_dark;\n    }\n    return (s.albedo * l.color) * _4527;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2085_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3044 = int(_2085_fa_shadow_cfg.x + 0.5f);\n    float _3054 = dot(world - _2085_fa_shadow_eye.xyz, _2085_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3059 = _3044 > 0;\n    bool _3068;\n    if (_3059)\n    {\n        int param = _3044 - 1;\n        _3068 = _3054 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3068 = _3059;\n    }\n    if (_3068)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3074 = _3044 > 1;\n        bool _3081;\n        if (_3074)\n        {\n            _3081 = _3054 > _2085_fa_shadow_split.x;\n        }\n        else\n        {\n            _3081 = _3074;\n        }\n        if (_3081)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3087 = _3044 > 2;\n        bool _3094;\n        if (_3087)\n        {\n            _3094 = _3054 > _2085_fa_shadow_split.y;\n        }\n        else\n        {\n            _3094 = _3087;\n        }\n        if (_3094)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3100 = _3044 > 3;\n        bool _3107;\n        if (_3100)\n        {\n            _3107 = _3054 > _2085_fa_shadow_split.z;\n        }\n        else\n        {\n            _3107 = _3100;\n        }\n        if (_3107)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_rt_slope = 0.0f;\n    fa_inst_load();\n    float3 _6115 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6115 = -_6115;\n    }\n    float3 _5689 = normalize(_433_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _6128 = { fa_world_pos, _6115, fa_world_tangent, fa_uv, fa_vertex_color, _5689, gl_FrontFacing };\n    SurfaceInput param_1 = _6128;\n    Surface _5697 = fa_standard_surface(param_1);\n    float3 _6146 = _5697.albedo;\n    float _6147 = _5697.alpha;\n    float3 _6148 = _5697.normal;\n    float _6149 = _5697.metallic;\n    float _6150 = _5697.roughness;\n    float _6151 = _5697.occlusion;\n    float3 _6152 = _5697.emission;\n    float _6153 = _5697.clearcoat;\n    float _6154 = _5697.clearcoat_roughness;\n    float3 _6155 = _5697.sheen_color;\n    float _6156 = _5697.sheen_roughness;\n    float _6157 = _5697.anisotropy;\n    float _6158 = _5697.anisotropy_rotation;\n    float _6159 = _5697.specular;\n    float _6160 = _5697.ior;\n    float3 _6161 = _5697.specular_color;\n    float _6162 = _5697.transmission;\n    float _6163 = _5697.thickness;\n    float3 _6164 = _5697.attenuation_color;\n    float _6165 = _5697.attenuation_distance;\n    SurfaceInput _6136 = { fa_world_pos, _6115, fa_world_tangent, fa_uv, fa_vertex_color, _5689, gl_FrontFacing };\n    SurfaceInput param_2 = _6136;\n    Surface param_3 = _5697;\n    surface(param_2, param_3);\n    _6146 = param_3.albedo;\n    _6147 = param_3.alpha;\n    _6148 = param_3.normal;\n    _6149 = param_3.metallic;\n    _6150 = param_3.roughness;\n    _6151 = param_3.occlusion;\n    _6152 = param_3.emission;\n    _6153 = param_3.clearcoat;\n    _6154 = param_3.clearcoat_roughness;\n    _6155 = param_3.sheen_color;\n    _6156 = param_3.sheen_roughness;\n    _6157 = param_3.anisotropy;\n    _6158 = param_3.anisotropy_rotation;\n    _6159 = param_3.specular;\n    _6160 = param_3.ior;\n    _6161 = param_3.specular_color;\n    _6162 = param_3.transmission;\n    _6163 = param_3.thickness;\n    _6164 = param_3.attenuation_color;\n    _6165 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _6115;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6146 = param_6;\n    _6148 = param_7;\n    float3 result;\n    if (_433_fa_emissive.w > 0.5f)\n    {\n        result = _6146;\n    }\n    else\n    {\n        float3 _5736 = _6148;\n        float3 _5737 = normalize(_5736);\n        _6148 = _5737;\n        float3 param_8 = _5737;\n        float3 lit = (fa_indirect_diffuse(param_8) * _6146) * _6151;\n        int _5756 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5756; ln++)\n        {\n            int param_9 = ln;\n            int _5769 = fa_cl_light(param_9);\n            int param_10 = _5769;\n            if (fa_baked_keep(param_10) <= 0.0f)\n            {\n                continue;\n            }\n            int param_11 = _5769;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _6115;\n            LightSample _5785 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput _6144 = { fa_world_pos, _6115, fa_world_tangent, fa_uv, fa_vertex_color, _5689, gl_FrontFacing };\n            SurfaceInput param_14 = _6144;\n            Surface _6247 = { _6146, _6147, _6148, _6149, _6150, _6151, _6152, _6153, _6154, _6155, _6156, _6157, _6158, _6159, _6160, _6161, _6162, _6163, _6164, _6165 };\n            Surface param_15 = _6247;\n            LightSample param_16 = _5785;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _5800 = result;\n    float3 _5801 = _5800 + _6152;\n    result = _5801;\n    float3 param_17 = _5801;\n    float3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _5810 = _433_fa_fog.w > 0.0f;\n    bool _5817;\n    if (!_5810)\n    {\n        _5817 = _433_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5817 = _5810;\n    }\n    if (_5817)\n    {\n        float3 _5826 = fa_world_pos - _433_fa_camera_pos.xyz;\n        float _5832 = dot(_5826, _433_fa_fog_c.xyz);\n        bool _5836 = _433_fa_fog_c.w > 0.5f;\n        float _5837;\n        if (_5836)\n        {\n            _5837 = _5832;\n        }\n        else\n        {\n            _5837 = length(_5826);\n        }\n        float _5849 = _5837 - _433_fa_fog_b.x;\n        if (_5849 > 0.0f)\n        {\n            float _5858 = _433_fa_fog.w * _5849;\n            float tau = _5858 * _5858;\n            if (_433_fa_fog_b.y > 0.0f)\n            {\n                float _5874;\n                if (_5836)\n                {\n                    _5874 = fa_world_pos.y - (_433_fa_fog_c.y * _5832);\n                }\n                else\n                {\n                    _5874 = _433_fa_camera_pos.y;\n                }\n                float _5895 = lerp(_5874, fa_world_pos.y, clamp(_433_fa_fog_b.x / _5837, 0.0f, 1.0f));\n                float _5899 = fa_world_pos.y - _5895;\n                float _5904 = _5895 - _433_fa_fog_b.z;\n                float _5909 = fa_world_pos.y - _433_fa_fog_b.z;\n                bool _5912 = _5904 <= 0.0f;\n                bool _5913 = !_5912;\n                bool _5919;\n                if (_5913)\n                {\n                    _5919 = _433_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5919 = _5912;\n                }\n                float _5920;\n                if (_5919)\n                {\n                    _5920 = _433_fa_fog_b.y;\n                }\n                else\n                {\n                    _5920 = _433_fa_fog_b.y * exp(-min(_433_fa_fog_b.w * _5904, 80.0f));\n                }\n                bool _5947;\n                if (_5913)\n                {\n                    _5947 = _433_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5947 = _5912;\n                }\n                float _5948;\n                if (_5947)\n                {\n                    _5948 = _433_fa_fog_b.y * _5904;\n                }\n                else\n                {\n                    _5948 = (_433_fa_fog_b.y * (1.0f - exp(-min(_433_fa_fog_b.w * _5904, 80.0f)))) / _433_fa_fog_b.w;\n                }\n                bool _5973 = _5909 <= 0.0f;\n                bool _5980;\n                if (!_5973)\n                {\n                    _5980 = _433_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5980 = _5973;\n                }\n                float _5981;\n                if (_5980)\n                {\n                    _5981 = _433_fa_fog_b.y * _5909;\n                }\n                else\n                {\n                    _5981 = (_433_fa_fog_b.y * (1.0f - exp(-min(_433_fa_fog_b.w * _5909, 80.0f)))) / _433_fa_fog_b.w;\n                }\n                float _6008;\n                if (abs(_5899) < 0.001000000047497451305389404296875f)\n                {\n                    _6008 = _5920;\n                }\n                else\n                {\n                    _6008 = (_5981 - _5948) / _5899;\n                }\n                tau += (_5849 * max(_6008, 0.0f));\n            }\n            result = lerp(result, _433_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _6147);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_433",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2085",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_4533",
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
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
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
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
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
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1
          },
          {
            "slot": 11,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _57_fa_view_proj : packoffset(c0);\n    row_major float4x4 _57_fa_light_vp : packoffset(c4);\n    float4 _57_fa_uv_scale : packoffset(c8);\n    float4 _57_fa_time : packoffset(c9);\n    float4 _57_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_vel_params : register(b2)\n{\n    row_major float4x4 _225_fa_vel_vp : packoffset(c0);\n    row_major float4x4 _225_fa_vel_prev_vp : packoffset(c4);\n    float4 _225_fa_vel_on : packoffset(c8);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float4 fa_prev_r0;\nstatic float4 fa_prev_r1;\nstatic float4 fa_prev_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_prev_r0 : TEXCOORD9;\n    float4 fa_prev_r1 : TEXCOORD10;\n    float4 fa_prev_r2 : TEXCOORD11;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4 fa_time_now()\n{\n    return _57_fa_time;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _97 = cross(model[1].xyz, model[2].xyz);\n    float _101 = (dot(model[0].xyz, _97) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _451 = { mul(float4(position, 1.0f), model).xyz, (((_97 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _101, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _101), texcoord0 * _57_fa_uv_scale.xy, color, position };\n    return _451;\n}\n\nfloat4x4 fa_rows_to_mat4(float4 r0, float4 r1, float4 r2)\n{\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat4x4 fa_prev_model()\n{\n    float4 param = fa_prev_r0;\n    float4 param_1 = fa_prev_r1;\n    float4 param_2 = fa_prev_r2;\n    return fa_rows_to_mat4(param, param_1, param_2);\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color, bool has_prev)\n{\n    bool _231;\n    if (has_prev)\n    {\n        _231 = _225_fa_vel_on.x > 0.5f;\n    }\n    else\n    {\n        _231 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _246 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _458 = _246.world_pos;\n    float4 _257 = float4(_458, 1.0f);\n    fa_world_pos = _458;\n    fa_world_normal = _246.world_normal;\n    fa_world_tangent = _246.world_tangent;\n    fa_uv = _246.uv;\n    fa_vertex_color = _246.color;\n    fa_pre_depth = -mul(_257, _57_fa_light_vp).z;\n    fa_pre_r0 = float3(_57_fa_light_vp[0].x, _57_fa_light_vp[1].x, _57_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_57_fa_light_vp[0].y, _57_fa_light_vp[1].y, _57_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_57_fa_light_vp[0].z, _57_fa_light_vp[1].z, _57_fa_light_vp[2].z);\n    gl_Position = mul(_257, _57_fa_view_proj);\n    fa_vel_cur = float3(0.0f, 0.0f, 1.0f);\n    fa_vel_prev = 0.0f.xxx;\n    if (_231)\n    {\n        float4 _330 = float4(position, 1.0f);\n        fa_vel_cur = float3(mul(_257, _225_fa_vel_vp).xyw);\n        fa_vel_prev = float3(mul(float4((_458 + mul(_330, fa_prev_model()).xyz) - mul(_330, model).xyz, 1.0f), _225_fa_vel_prev_vp).xyw);\n    }\n}\n\nvoid vert_main()\n{\n    fa_vtime = 0.0f.xxxx;\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    bool param_6 = true;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_prev_r0 = stage_input.fa_prev_r0;\n    fa_prev_r1 = stage_input.fa_prev_r1;\n    fa_prev_r2 = stage_input.fa_prev_r2;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    stage_output.fa_vel_cur = fa_vel_cur;\n    stage_output.fa_vel_prev = fa_vel_prev;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _214_fa_camera_pos : packoffset(c0);\n    float4 _214_fa_ambient : packoffset(c1);\n    float4 _214_fa_base_color : packoffset(c2);\n    float4 _214_fa_emissive : packoffset(c3);\n    float4 _214_fa_model_emissive : packoffset(c4);\n    float4 _214_fa_pbr : packoffset(c5);\n    float4 _214_fa_maps : packoffset(c6);\n    float4 _214_fa_fog : packoffset(c7);\n    float4 _214_fa_fog_b : packoffset(c8);\n    float4 _214_fa_fog_c : packoffset(c9);\n    float4 _214_fa_counts : packoffset(c10);\n    float4 _214_fa_env_sky : packoffset(c11);\n    float4 _214_fa_env_horizon : packoffset(c12);\n    float4 _214_fa_time : packoffset(c13);\n    float4 _214_fa_cl_vpx : packoffset(c14);\n    float4 _214_fa_cl_vpy : packoffset(c15);\n    float4 _214_fa_cl_vpw : packoffset(c16);\n    float4 _214_fa_cl_fwd : packoffset(c17);\n    float4 _214_fa_cl_grid : packoffset(c18);\n    float4 _214_fa_cl_info : packoffset(c19);\n    float4 _214_fa_layers_a : packoffset(c20);\n    float4 _214_fa_layers_b : packoffset(c21);\n    float4 _214_fa_layers_c : packoffset(c22);\n    float4 _214_fa_layers_d : packoffset(c23);\n    float4 _214_fa_ct_a : packoffset(c24);\n    float4 _214_fa_ct_b : packoffset(c25);\n    float4 _214_fa_ct_vpx : packoffset(c26);\n    float4 _214_fa_ct_vpy : packoffset(c27);\n    float4 _214_fa_ct_vpw : packoffset(c28);\n    float4 _214_fa_ct_fwd : packoffset(c29);\n    float4 _214_fa_tr_a : packoffset(c30);\n    float4 _214_fa_tr_b : packoffset(c31);\n    float4 _214_fa_probe_sh[9] : packoffset(c32);\n    float4 _214_fa_atlas : packoffset(c41);\n    float4 _214_fa_rpa_tile : packoffset(c42);\n    float4 _214_fa_rpa_pos : packoffset(c43);\n    float4 _214_fa_rpa_bx : packoffset(c44);\n    float4 _214_fa_rpa_by : packoffset(c45);\n    float4 _214_fa_rpa_bz : packoffset(c46);\n    float4 _214_fa_rpb_tile : packoffset(c47);\n    float4 _214_fa_rpb_pos : packoffset(c48);\n    float4 _214_fa_rpb_bx : packoffset(c49);\n    float4 _214_fa_rpb_by : packoffset(c50);\n    float4 _214_fa_rpb_bz : packoffset(c51);\n    float4 _214_fa_gi : packoffset(c52);\n    float4 _214_fa_gi_px : packoffset(c53);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float2 fa_frag_velocity;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n    float2 fa_frag_velocity : SV_Target1;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w);\n    float param = _214_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _230 = fa_tex_fix(param_2, param_3);\n    float4 _892 = base_t;\n    _892.x = _230.x;\n    _892.y = _230.y;\n    _892.z = _230.z;\n    base_t = _892;\n    float4 _246 = (_892 * _214_fa_base_color) * i.vertex_color;\n    float3 _847 = i.world_normal;\n    if (_214_fa_maps.z > 0.5f)\n    {\n        float param_4 = _214_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _282 = fa_tex_fix(param_6, param_7);\n        float3 _286 = (_282 * 2.0f) - 1.0f.xxx;\n        float2 _291 = _286.xy * _214_fa_maps.x;\n        float3 _900 = _286;\n        _900.x = _291.x;\n        _900.y = _291.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _900;\n        _847 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w);\n    float param_10 = _214_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _322 = fa_tex_fix(param_12, param_13);\n    float4 _903 = mrt;\n    _903.x = _322.x;\n    _903.y = _322.y;\n    _903.z = _322.z;\n    mrt = _903;\n    float4 _354 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w);\n    float param_14 = _214_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _214_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _398 = fa_tex_fix(param_20, param_21);\n    float _852 = _214_fa_layers_a.x;\n    float _853 = _214_fa_layers_a.y;\n    float _856 = _214_fa_layers_a.z;\n    float _855 = _214_fa_layers_b.w;\n    float _858 = _214_fa_layers_c.x;\n    if (_214_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_214_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _852 *= _366.y;\n            _853 *= _366.z;\n            _855 *= _354.w;\n        }\n        if (_214_fa_layers_c.z > 1.5f)\n        {\n            _856 *= mrt.x;\n            _858 *= mrt.w;\n        }\n    }\n    Surface _885 = { _246.xyz, _246.w, _847, clamp(_214_fa_pbr.x * _322.z, 0.0f, 1.0f), clamp(_214_fa_pbr.y * _322.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_214_fa_maps.y * (_366.x - 1.0f)), _214_fa_emissive.xyz + (_214_fa_model_emissive.xyz * _398), _852, _853, _214_fa_layers_b.xyz, _855, _856, _214_fa_layers_a.w, _858, _214_fa_layers_c.y, _214_fa_layers_d.xyz, _214_fa_tr_a.x, _214_fa_tr_a.y, _214_fa_tr_b.xyz, _214_fa_tr_a.z };\n    return _885;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _742 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _742 = -_742;\n    }\n    float3 _550 = normalize(_214_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _755 = { fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing };\n    SurfaceInput param = _755;\n    SurfaceInput _763 = { fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing };\n    SurfaceInput param_1 = _763;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _565 = normalize(param_2.normal);\n    float3 _580 = normalize(float3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    float2 e = _580.xy / ((abs(_580.x) + abs(_580.y)) + abs(_592)).xx;\n    if (_592 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n    float2 motion = 1024.0f.xx;\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06f;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06f;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((float2(fa_vel_prev.x, -fa_vel_prev.y) / fa_vel_prev.z.xx) * 0.5f) - ((float2(fa_vel_cur.x, -fa_vel_cur.y) / fa_vel_cur.z.xx) * 0.5f), (-4.0f).xx, 4.0f.xx);\n    }\n    fa_frag_velocity = motion;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    fa_vel_cur = stage_input.fa_vel_cur;\n    fa_vel_prev = stage_input.fa_vel_prev;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    stage_output.fa_frag_velocity = fa_frag_velocity;\n    return stage_output;\n}\n",
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
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 11
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_57",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 2,
            "stage": "vertex",
            "size": 144,
            "struct_name": "fa_vel_params",
            "inst_name": "_225",
            "hlsl_register_b_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_214",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _74_fa_view_proj : packoffset(c0);\n    row_major float4x4 _74_fa_light_vp : packoffset(c4);\n    float4 _74_fa_uv_scale : packoffset(c8);\n    float4 _74_fa_time : packoffset(c9);\n    float4 _74_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _213_fa_joint_rows[192] : packoffset(c0);\n};\n\ncbuffer fa_vel_params : register(b2)\n{\n    row_major float4x4 _470_fa_vel_vp : packoffset(c0);\n    row_major float4x4 _470_fa_vel_prev_vp : packoffset(c4);\n    float4 _470_fa_vel_on : packoffset(c8);\n};\n\nTexture2D<float4> fa_prev_pal_tex : register(t0);\nSamplerState fa_prev_pal_smp : register(s11);\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float4 fa_prev_r0;\nstatic float4 fa_prev_r1;\nstatic float4 fa_prev_r2;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    float4 fa_prev_r0 : TEXCOORD11;\n    float4 fa_prev_r1 : TEXCOORD12;\n    float4 fa_prev_r2 : TEXCOORD13;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _204 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_213_fa_joint_rows[_204] * weights[i]);\n        r1 += (_213_fa_joint_rows[_204 + 1] * weights[i]);\n        r2 += (_213_fa_joint_rows[_204 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat4 fa_time_now()\n{\n    return _74_fa_time;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _113 = cross(model[1].xyz, model[2].xyz);\n    float _117 = (dot(model[0].xyz, _113) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _716 = { mul(float4(position, 1.0f), model).xyz, (((_113 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _117, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _117), texcoord0 * _74_fa_uv_scale.xy, color, position };\n    return _716;\n}\n\nfloat4x4 fa_rows_to_mat4(float4 r0, float4 r1, float4 r2)\n{\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat4 fa_prev_pal_texel(int t)\n{\n    return fa_prev_pal_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4x4 fa_prev_skin_matrix(float4 joints, float4 weights, int base)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _332 = base + (int((joints[i] * 255.0f) + 0.5f) * 3);\n        int param = _332;\n        r0 += (fa_prev_pal_texel(param) * weights[i]);\n        int param_1 = _332 + 1;\n        r1 += (fa_prev_pal_texel(param_1) * weights[i]);\n        int param_2 = _332 + 2;\n        r2 += (fa_prev_pal_texel(param_2) * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat4x4 fa_prev_model()\n{\n    float4 param = fa_prev_r0;\n    float4 param_1 = fa_prev_r1;\n    float4 param_2 = fa_prev_r2;\n    float4 param_3 = fa_joints;\n    float4 param_4 = fa_weights;\n    int param_5 = int(_470_fa_vel_on.w + 0.5f);\n    return mul(fa_prev_skin_matrix(param_3, param_4, param_5), fa_rows_to_mat4(param, param_1, param_2));\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color, bool has_prev)\n{\n    bool _475;\n    if (has_prev)\n    {\n        _475 = _470_fa_vel_on.x > 0.5f;\n    }\n    else\n    {\n        _475 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _490 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _723 = _490.world_pos;\n    float4 _501 = float4(_723, 1.0f);\n    fa_world_pos = _723;\n    fa_world_normal = _490.world_normal;\n    fa_world_tangent = _490.world_tangent;\n    fa_uv = _490.uv;\n    fa_vertex_color = _490.color;\n    fa_pre_depth = -mul(_501, _74_fa_light_vp).z;\n    fa_pre_r0 = float3(_74_fa_light_vp[0].x, _74_fa_light_vp[1].x, _74_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_74_fa_light_vp[0].y, _74_fa_light_vp[1].y, _74_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_74_fa_light_vp[0].z, _74_fa_light_vp[1].z, _74_fa_light_vp[2].z);\n    gl_Position = mul(_501, _74_fa_view_proj);\n    fa_vel_cur = float3(0.0f, 0.0f, 1.0f);\n    fa_vel_prev = 0.0f.xxx;\n    if (_475)\n    {\n        float4 _574 = float4(position, 1.0f);\n        fa_vel_cur = float3(mul(_501, _470_fa_vel_vp).xyw);\n        fa_vel_prev = float3(mul(float4((_723 + mul(_574, fa_prev_model()).xyz) - mul(_574, model).xyz, 1.0f), _470_fa_vel_prev_vp).xyw);\n    }\n}\n\nvoid vert_main()\n{\n    fa_vtime = 0.0f.xxxx;\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    bool param_8 = _470_fa_vel_on.z > 0.5f;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_prev_r0 = stage_input.fa_prev_r0;\n    fa_prev_r1 = stage_input.fa_prev_r1;\n    fa_prev_r2 = stage_input.fa_prev_r2;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    stage_output.fa_vel_cur = fa_vel_cur;\n    stage_output.fa_vel_prev = fa_vel_prev;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _214_fa_camera_pos : packoffset(c0);\n    float4 _214_fa_ambient : packoffset(c1);\n    float4 _214_fa_base_color : packoffset(c2);\n    float4 _214_fa_emissive : packoffset(c3);\n    float4 _214_fa_model_emissive : packoffset(c4);\n    float4 _214_fa_pbr : packoffset(c5);\n    float4 _214_fa_maps : packoffset(c6);\n    float4 _214_fa_fog : packoffset(c7);\n    float4 _214_fa_fog_b : packoffset(c8);\n    float4 _214_fa_fog_c : packoffset(c9);\n    float4 _214_fa_counts : packoffset(c10);\n    float4 _214_fa_env_sky : packoffset(c11);\n    float4 _214_fa_env_horizon : packoffset(c12);\n    float4 _214_fa_time : packoffset(c13);\n    float4 _214_fa_cl_vpx : packoffset(c14);\n    float4 _214_fa_cl_vpy : packoffset(c15);\n    float4 _214_fa_cl_vpw : packoffset(c16);\n    float4 _214_fa_cl_fwd : packoffset(c17);\n    float4 _214_fa_cl_grid : packoffset(c18);\n    float4 _214_fa_cl_info : packoffset(c19);\n    float4 _214_fa_layers_a : packoffset(c20);\n    float4 _214_fa_layers_b : packoffset(c21);\n    float4 _214_fa_layers_c : packoffset(c22);\n    float4 _214_fa_layers_d : packoffset(c23);\n    float4 _214_fa_ct_a : packoffset(c24);\n    float4 _214_fa_ct_b : packoffset(c25);\n    float4 _214_fa_ct_vpx : packoffset(c26);\n    float4 _214_fa_ct_vpy : packoffset(c27);\n    float4 _214_fa_ct_vpw : packoffset(c28);\n    float4 _214_fa_ct_fwd : packoffset(c29);\n    float4 _214_fa_tr_a : packoffset(c30);\n    float4 _214_fa_tr_b : packoffset(c31);\n    float4 _214_fa_probe_sh[9] : packoffset(c32);\n    float4 _214_fa_atlas : packoffset(c41);\n    float4 _214_fa_rpa_tile : packoffset(c42);\n    float4 _214_fa_rpa_pos : packoffset(c43);\n    float4 _214_fa_rpa_bx : packoffset(c44);\n    float4 _214_fa_rpa_by : packoffset(c45);\n    float4 _214_fa_rpa_bz : packoffset(c46);\n    float4 _214_fa_rpb_tile : packoffset(c47);\n    float4 _214_fa_rpb_pos : packoffset(c48);\n    float4 _214_fa_rpb_bx : packoffset(c49);\n    float4 _214_fa_rpb_by : packoffset(c50);\n    float4 _214_fa_rpb_bz : packoffset(c51);\n    float4 _214_fa_gi : packoffset(c52);\n    float4 _214_fa_gi_px : packoffset(c53);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float2 fa_frag_velocity;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n    float2 fa_frag_velocity : SV_Target1;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w);\n    float param = _214_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _230 = fa_tex_fix(param_2, param_3);\n    float4 _892 = base_t;\n    _892.x = _230.x;\n    _892.y = _230.y;\n    _892.z = _230.z;\n    base_t = _892;\n    float4 _246 = (_892 * _214_fa_base_color) * i.vertex_color;\n    float3 _847 = i.world_normal;\n    if (_214_fa_maps.z > 0.5f)\n    {\n        float param_4 = _214_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _282 = fa_tex_fix(param_6, param_7);\n        float3 _286 = (_282 * 2.0f) - 1.0f.xxx;\n        float2 _291 = _286.xy * _214_fa_maps.x;\n        float3 _900 = _286;\n        _900.x = _291.x;\n        _900.y = _291.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _900;\n        _847 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w);\n    float param_10 = _214_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _322 = fa_tex_fix(param_12, param_13);\n    float4 _903 = mrt;\n    _903.x = _322.x;\n    _903.y = _322.y;\n    _903.z = _322.z;\n    mrt = _903;\n    float4 _354 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w);\n    float param_14 = _214_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _214_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _398 = fa_tex_fix(param_20, param_21);\n    float _852 = _214_fa_layers_a.x;\n    float _853 = _214_fa_layers_a.y;\n    float _856 = _214_fa_layers_a.z;\n    float _855 = _214_fa_layers_b.w;\n    float _858 = _214_fa_layers_c.x;\n    if (_214_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_214_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _852 *= _366.y;\n            _853 *= _366.z;\n            _855 *= _354.w;\n        }\n        if (_214_fa_layers_c.z > 1.5f)\n        {\n            _856 *= mrt.x;\n            _858 *= mrt.w;\n        }\n    }\n    Surface _885 = { _246.xyz, _246.w, _847, clamp(_214_fa_pbr.x * _322.z, 0.0f, 1.0f), clamp(_214_fa_pbr.y * _322.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_214_fa_maps.y * (_366.x - 1.0f)), _214_fa_emissive.xyz + (_214_fa_model_emissive.xyz * _398), _852, _853, _214_fa_layers_b.xyz, _855, _856, _214_fa_layers_a.w, _858, _214_fa_layers_c.y, _214_fa_layers_d.xyz, _214_fa_tr_a.x, _214_fa_tr_a.y, _214_fa_tr_b.xyz, _214_fa_tr_a.z };\n    return _885;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _742 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _742 = -_742;\n    }\n    float3 _550 = normalize(_214_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _755 = { fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing };\n    SurfaceInput param = _755;\n    SurfaceInput _763 = { fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing };\n    SurfaceInput param_1 = _763;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _565 = normalize(param_2.normal);\n    float3 _580 = normalize(float3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    float2 e = _580.xy / ((abs(_580.x) + abs(_580.y)) + abs(_592)).xx;\n    if (_592 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n    float2 motion = 1024.0f.xx;\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06f;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06f;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((float2(fa_vel_prev.x, -fa_vel_prev.y) / fa_vel_prev.z.xx) * 0.5f) - ((float2(fa_vel_cur.x, -fa_vel_cur.y) / fa_vel_cur.z.xx) * 0.5f), (-4.0f).xx, 4.0f.xx);\n    }\n    fa_frag_velocity = motion;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    fa_vel_cur = stage_input.fa_vel_cur;\n    fa_vel_prev = stage_input.fa_vel_prev;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    stage_output.fa_frag_velocity = fa_frag_velocity;\n    return stage_output;\n}\n",
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
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 11
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 12
          },
          {
            "slot": 13,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 13
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_74",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_213",
            "hlsl_register_b_n": 3
          },
          {
            "slot": 2,
            "stage": "vertex",
            "size": 144,
            "struct_name": "fa_vel_params",
            "inst_name": "_470",
            "hlsl_register_b_n": 2
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_214",
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
              "slot": 29,
              "stage": "vertex",
              "name": "fa_prev_pal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 11,
            "stage": "vertex",
            "name": "fa_prev_pal_smp",
            "sampler_type": "nonfiltering",
            "hlsl_register_s_n": 11
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
            "name": "fa_prev_pal_tex_fa_prev_pal_smp",
            "view_name": "fa_prev_pal_tex",
            "sampler_name": "fa_prev_pal_smp",
            "view_slot": 29,
            "sampler_slot": 11
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
          }
        ]
      }
    }
  }
}
