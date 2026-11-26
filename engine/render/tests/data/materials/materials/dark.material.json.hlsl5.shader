{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "f75e5e0880dc820037ae0c93c059e5f4f012f6ae7d85cbb082650e666c2ae84b",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _260 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _260;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_267, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _421_fa_camera_pos : packoffset(c0);\n    float4 _421_fa_ambient : packoffset(c1);\n    float4 _421_fa_base_color : packoffset(c2);\n    float4 _421_fa_emissive : packoffset(c3);\n    float4 _421_fa_model_emissive : packoffset(c4);\n    float4 _421_fa_pbr : packoffset(c5);\n    float4 _421_fa_maps : packoffset(c6);\n    float4 _421_fa_fog : packoffset(c7);\n    float4 _421_fa_fog_b : packoffset(c8);\n    float4 _421_fa_fog_c : packoffset(c9);\n    float4 _421_fa_counts : packoffset(c10);\n    float4 _421_fa_env_sky : packoffset(c11);\n    float4 _421_fa_env_horizon : packoffset(c12);\n    float4 _421_fa_time : packoffset(c13);\n    float4 _421_fa_cl_vpx : packoffset(c14);\n    float4 _421_fa_cl_vpy : packoffset(c15);\n    float4 _421_fa_cl_vpw : packoffset(c16);\n    float4 _421_fa_cl_fwd : packoffset(c17);\n    float4 _421_fa_cl_grid : packoffset(c18);\n    float4 _421_fa_cl_info : packoffset(c19);\n    float4 _421_fa_layers_a : packoffset(c20);\n    float4 _421_fa_layers_b : packoffset(c21);\n    float4 _421_fa_layers_c : packoffset(c22);\n    float4 _421_fa_layers_d : packoffset(c23);\n    float4 _421_fa_ct_a : packoffset(c24);\n    float4 _421_fa_ct_b : packoffset(c25);\n    float4 _421_fa_ct_vpx : packoffset(c26);\n    float4 _421_fa_ct_vpy : packoffset(c27);\n    float4 _421_fa_ct_vpw : packoffset(c28);\n    float4 _421_fa_ct_fwd : packoffset(c29);\n    float4 _421_fa_tr_a : packoffset(c30);\n    float4 _421_fa_tr_b : packoffset(c31);\n    float4 _421_fa_probe_sh[9] : packoffset(c32);\n    float4 _421_fa_atlas : packoffset(c41);\n    float4 _421_fa_rpa_tile : packoffset(c42);\n    float4 _421_fa_rpa_pos : packoffset(c43);\n    float4 _421_fa_rpa_bx : packoffset(c44);\n    float4 _421_fa_rpa_by : packoffset(c45);\n    float4 _421_fa_rpa_bz : packoffset(c46);\n    float4 _421_fa_rpb_tile : packoffset(c47);\n    float4 _421_fa_rpb_pos : packoffset(c48);\n    float4 _421_fa_rpb_bx : packoffset(c49);\n    float4 _421_fa_rpb_by : packoffset(c50);\n    float4 _421_fa_rpb_bz : packoffset(c51);\n    float4 _421_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2073_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2073_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2073_fa_shadow_info[4] : packoffset(c20);\n    float4 _2073_fa_shadow_split : packoffset(c24);\n    float4 _2073_fa_shadow_cfg : packoffset(c25);\n    float4 _2073_fa_shadow_bias : packoffset(c26);\n    float4 _2073_fa_shadow_eye : packoffset(c27);\n    float4 _2073_fa_shadow_fwd : packoffset(c28);\n    float4 _2073_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1349 = _421_fa_cl_info.x < 0.0f;\n    bool _1356;\n    if (!_1349)\n    {\n        _1356 = _421_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1356 = _1349;\n    }\n    bool _1364;\n    if (!_1356)\n    {\n        _1364 = _421_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1364 = _1356;\n    }\n    bool _1371;\n    if (!_1364)\n    {\n        _1371 = _421_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1371 = _1364;\n    }\n    bool _1378;\n    if (!_1371)\n    {\n        _1378 = _421_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1378 = _1371;\n    }\n    if (_1378)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1388 = float4(world_pos, 1.0f);\n    float _1394 = dot(_421_fa_cl_vpw, _1388);\n    if (!(_1394 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1416 = float2(dot(_421_fa_cl_vpx, _1388), dot(_421_fa_cl_vpy, _1388)) / _1394.xx;\n    int _1420 = int(_421_fa_cl_grid.x);\n    int _1424 = int(_421_fa_cl_grid.y);\n    int param = (int(_421_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_421_fa_cl_fwd.xyz, world_pos) + _421_fa_cl_fwd.w, _421_fa_cl_grid.w) / _421_fa_cl_grid.w) * _421_fa_cl_grid.z)), 0, int(_421_fa_cl_info.y) - 1) * _1424) + clamp(int(floor(((_1416.y * 0.5f) + 0.5f) * _421_fa_cl_grid.y)), 0, _1424 - 1)) * _1420)) + clamp(int(floor(((_1416.x * 0.5f) + 0.5f) * _421_fa_cl_grid.x)), 0, _1420 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1500 = fa_cluster_texel(param);\n    return int2(int(_1500.x), int(_1500.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_421_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4205 = fa_cluster_lookup(param);\n    fa_cl_slot = _4205.x;\n    fa_cl_local = _4205.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4410 = fa_linear_to_srgb(param);\n        c = _4410;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4418 = fa_srgb_to_linear(param_1);\n            c = _4418;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _303;\n    if (i.front_facing)\n    {\n        _303 = i.world_normal;\n    }\n    else\n    {\n        _303 = -i.world_normal;\n    }\n    float3 _327 = normalize(i.world_tangent.xyz - (_303 * dot(_303, i.world_tangent.xyz)));\n    float3 _354 = normalize(((_327 * m.x) + ((cross(_303, _327) * i.world_tangent.w) * m.y)) + (_303 * m.z));\n    float3 _357;\n    if (i.front_facing)\n    {\n        _357 = _354;\n    }\n    else\n    {\n        _357 = -_354;\n    }\n    return _357;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _421_fa_env_horizon.w);\n    float param = _421_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4450 = fa_tex_fix(param_2, param_3);\n    float4 _6251 = base_t;\n    _6251.x = _4450.x;\n    _6251.y = _4450.y;\n    _6251.z = _4450.z;\n    base_t = _6251;\n    float4 _4464 = (_6251 * _421_fa_base_color) * i.vertex_color;\n    float3 _6067 = i.world_normal;\n    if (_421_fa_maps.z > 0.5f)\n    {\n        float param_4 = _421_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _421_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4498 = fa_tex_fix(param_6, param_7);\n        float3 _4501 = (_4498 * 2.0f) - 1.0f.xxx;\n        float2 _4506 = _4501.xy * _421_fa_maps.x;\n        float3 _6259 = _4501;\n        _6259.x = _4506.x;\n        _6259.y = _4506.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6259;\n        _6067 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _421_fa_env_horizon.w);\n    float param_10 = _421_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4536 = fa_tex_fix(param_12, param_13);\n    float4 _6262 = mrt;\n    _6262.x = _4536.x;\n    _6262.y = _4536.y;\n    _6262.z = _4536.z;\n    mrt = _6262;\n    float4 _4566 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _421_fa_env_horizon.w);\n    float param_14 = _421_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4566.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4577 = fa_tex_fix(param_16, param_17);\n    float param_18 = _421_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _421_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4609 = fa_tex_fix(param_20, param_21);\n    float _6072 = _421_fa_layers_a.x;\n    float _6073 = _421_fa_layers_a.y;\n    float _6076 = _421_fa_layers_a.z;\n    float _6075 = _421_fa_layers_b.w;\n    float _6078 = _421_fa_layers_c.x;\n    if (_421_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_421_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6072 *= _4577.y;\n            _6073 *= _4577.z;\n            _6075 *= _4566.w;\n        }\n        if (_421_fa_layers_c.z > 1.5f)\n        {\n            _6076 *= mrt.x;\n            _6078 *= mrt.w;\n        }\n    }\n    Surface _6105 = { _4464.xyz, _4464.w, _6067, clamp(_421_fa_pbr.x * _4536.z, 0.0f, 1.0f), clamp(_421_fa_pbr.y * _4536.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_421_fa_maps.y * (_4577.x - 1.0f)), _421_fa_emissive.xyz + (_421_fa_model_emissive.xyz * _4609), _6072, _6073, _421_fa_layers_b.xyz, _6075, _6076, _421_fa_layers_a.w, _6078, _421_fa_layers_c.y, _421_fa_layers_d.xyz, _421_fa_tr_a.x, _421_fa_tr_a.y, _421_fa_tr_b.xyz, _421_fa_tr_a.z };\n    return _6105;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1580 = rect.zw - rect.xy;\n    float2 _1584 = _1580 * atlas;\n    float2 _1588 = ddx * _1584;\n    float2 _1592 = ddy * _1584;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1580), clamp(0.5f * log2(max(max(dot(_1588, _1588), dot(_1592, _1592)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1625 = _421_fa_counts.y < 0.5f;\n    bool _1632;\n    if (!_1625)\n    {\n        _1632 = _421_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1632 = _1625;\n    }\n    if (_1632)\n    {\n        return;\n    }\n    float3 _1638 = ddx(world_pos);\n    float3 _1641 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1645 = fa_cluster_texel(param);\n    int _1649 = int(_1645.w);\n    if (_1649 < 1)\n    {\n        return;\n    }\n    int _1659 = int(_421_fa_counts.y + 0.5f);\n    int param_1 = _1659;\n    float4 _1663 = fa_light_texel(param_1);\n    float2 _1666 = _1663.yz;\n    int _1670 = int(_1663.w);\n    int param_2 = _1659 + 1;\n    float4 _1675 = fa_light_texel(param_2);\n    float _1676 = _1675.x;\n    int _1682 = int(_421_fa_counts.w + 0.5f) - 1;\n    int _1686 = int(_1645.z);\n    float3 _1951;\n    for (int k = 0; k < _1649; k++)\n    {\n        int _1699 = _1686 + k;\n        int param_3 = _1670 + (_1699 >> 2);\n        int _1716 = (_1659 + 2) + (int(fa_light_texel(param_3)[_1699 & 3]) * 7);\n        int param_4 = _1716 + 6;\n        float4 _1721 = fa_light_texel(param_4);\n        if (((int(_1721.w + 0.5f) >> _1682) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1716;\n        float4 _1736 = fa_light_texel(param_5);\n        int param_6 = _1716 + 1;\n        float4 _1741 = fa_light_texel(param_6);\n        int param_7 = _1716 + 2;\n        float4 _1746 = fa_light_texel(param_7);\n        float3 _1749 = _1736.xyz;\n        float _1754 = dot(_1749, world_pos) + _1736.w;\n        float3 _1756 = _1741.xyz;\n        float _1761 = dot(_1756, world_pos) + _1741.w;\n        float3 _1763 = _1746.xyz;\n        float _1768 = dot(_1763, world_pos) + _1746.w;\n        bool _1773 = abs(_1754) > 0.5f;\n        bool _1781;\n        if (!_1773)\n        {\n            _1781 = abs(_1761) > 0.5f;\n        }\n        else\n        {\n            _1781 = _1773;\n        }\n        bool _1789;\n        if (!_1781)\n        {\n            _1789 = abs(_1768) > 0.5f;\n        }\n        else\n        {\n            _1789 = _1781;\n        }\n        if (_1789)\n        {\n            continue;\n        }\n        float _1804 = clamp(dot(geo_normal, normalize(_1763)) * _1721.z, 0.0f, 1.0f);\n        if (_1804 <= 0.0f)\n        {\n            continue;\n        }\n        float _1824 = (clamp((0.5f - abs(_1768)) * 10.0f, 0.0f, 1.0f) * _1804) * _1721.x;\n        float2 _1832 = float2(_1754 + 0.5f, 0.5f - _1761);\n        float2 _1842 = float2(dot(_1749, _1638), dot(_1756, _1638));\n        float2 _1852 = float2(dot(_1749, _1641), dot(_1756, _1641));\n        int param_8 = _1716 + 5;\n        float4 _1857 = fa_light_texel(param_8);\n        int param_9 = _1716 + 3;\n        float4 _1862 = fa_light_texel(param_9);\n        int param_10 = _1716 + 4;\n        float4 _1867 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1857.xyz;\n        bool _1877 = _1862.z > _1862.x;\n        if (_1877)\n        {\n            float4 param_11 = _1862;\n            float2 param_12 = _1832;\n            float2 param_13 = _1666;\n            float2 param_14 = _1842;\n            float2 param_15 = _1852;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1676 > 0.5f) && (_1676 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1903 = fa_dc_to_linear(param_16);\n                float4 _6155 = tx;\n                _6155.x = _1903.x;\n                _6155.y = _1903.y;\n                _6155.z = _1903.z;\n                tx = _6155;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1824 * tex_a) * _1857.w, 0.0f, 1.0f).xxx);\n        if (_1867.z > _1867.x)\n        {\n            float4 param_17 = _1867;\n            float2 param_18 = _1832;\n            float2 param_19 = _1666;\n            float2 param_20 = _1842;\n            float2 param_21 = _1852;\n            float4 _1947 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1676 > 1.5f)\n            {\n                float3 param_22 = _1947.xyz;\n                float3 _1957 = fa_dc_to_srgb(param_22);\n                _1951 = _1957;\n            }\n            else\n            {\n                _1951 = _1947.xyz;\n            }\n            float3 _1966 = (_1951 * 2.0f) - 1.0f.xxx;\n            float2 _1971 = _1966.xy * _1721.y;\n            float3 _1993 = (normalize(_1749) * _1971.x) + (normalize(_1756) * _1971.y);\n            float3 _1996 = normalize(normal);\n            normal = normalize(lerp(_1996, normalize((_1996 * max(_1966.z, 0.0500000007450580596923828125f)) + (_1993 - (_1996 * dot(_1996, _1993)))), clamp(_1824 * (_1877 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3727_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3727_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_421_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3668 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3668;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3777 = (1.0f - _421_fa_rpa_tile.w) - _421_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3783 = _421_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3777 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3783)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _421_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3777;\n            }\n        }\n        else\n        {\n            amb = _421_fa_ambient.xyz * _3777;\n        }\n    }\n    bool _3835 = _421_fa_rpa_tile.w > 0.0f;\n    if (_3835)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _421_fa_rpa_tile.xy;\n            float param_4 = _421_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _421_fa_rpa_tile.w);\n        }\n    }\n    bool _3866 = _421_fa_rpb_tile.w > 0.0f;\n    if (_3866)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _421_fa_rpb_tile.xy;\n            float param_7 = _421_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _421_fa_rpb_tile.w);\n        }\n    }\n    if ((_3783 || _3835) || _3866)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3688 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3691 = _3688.x;\n    float _3693 = _3688.z;\n    float2 e = float2(_3691, _3693);\n    if (_3688.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3693)) * ((_3691 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3691)) * ((_3693 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _4723 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _4728 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _4733 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _4738 = fa_light_texel(param_3);\n    bool _4741 = _4738.z < 0.5f;\n    bool _4749;\n    if (!_4741)\n    {\n        _4749 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _4749 = _4741;\n    }\n    if (_4749)\n    {\n        return 0.0f.xxx;\n    }\n    float _4756 = max(_4723.w, 9.9999997473787516355514526367188e-05f);\n    float3 _4759 = _4728.xyz;\n    float3 _4763 = _4723.xyz;\n    float3 _4767 = (fa_world_pos - _4763) / _4756.xxx;\n    float3 _4776 = min(_4767 + 0.5f.xxx, (_4759 - 0.5f.xxx) - _4767);\n    float _4785 = min(_4776.x, min(_4776.y, _4776.z));\n    if (!(_4785 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4800 = _4759 - 1.0f.xxx;\n    float3 _4801 = clamp(_4767, 0.0f.xxx, _4800);\n    float3 _4809 = min(floor(_4801), max(_4759 - 2.0f.xxx, 0.0f.xxx));\n    float3 _4813 = _4801 - _4809;\n    float3 _4825 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _4756));\n    int _4830 = int(_4733.y + 0.5f);\n    float _4835 = 0.3257350027561187744140625f * n.y;\n    float _4839 = 0.3257350027561187744140625f * n.z;\n    float _4843 = 0.3257350027561187744140625f * n.x;\n    float _4850 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _4857 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _4866 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _4873 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _4886 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _4893 = 8 + int(_4738.w);\n    float _4920;\n    float _4933;\n    float _4947;\n    for (int k = 0; k < _4893; k++)\n    {\n        float _4906 = float(k & 1);\n        float _4910 = float((k >> 1) & 1);\n        float _4914 = float((k >> 2) & 1);\n        if (_4906 > 0.5f)\n        {\n            _4920 = _4813.x;\n        }\n        else\n        {\n            _4920 = 1.0f - _4813.x;\n        }\n        if (_4910 > 0.5f)\n        {\n            _4933 = _4813.y;\n        }\n        else\n        {\n            _4933 = 1.0f - _4813.y;\n        }\n        if (_4914 > 0.5f)\n        {\n            _4947 = _4813.z;\n        }\n        else\n        {\n            _4947 = 1.0f - _4813.z;\n        }\n        float _4957 = (_4920 * _4933) * _4947;\n        if (!(_4957 > 0.0f))\n        {\n            continue;\n        }\n        float3 _4970 = min(_4809 + float3(_4906, _4910, _4914), _4800);\n        int _4990 = int(((_4733.x + _4970.x) + (_4728.x * (_4970.y + (_4728.y * _4970.z)))) + 0.5f);\n        float2 _5005 = float2(float(_4990 % _4830) * 10.0f, 1024.0f + (float(_4990 / _4830) * 11.0f));\n        float2 param_4 = _5005 + float2(9.5f, 10.5f);\n        float4 _5013 = fa_gi_fetch(param_4);\n        bool _5016 = _5013.y < 0.5f;\n        bool _5025;\n        if (!_5016)\n        {\n            _5025 = _5013.x > _4738.y;\n        }\n        else\n        {\n            _5025 = _5016;\n        }\n        if (_5025)\n        {\n            continue;\n        }\n        float3 _5037 = _4825 - (_4763 + (_4970 * _4756));\n        float _5040 = length(_5037);\n        float3 _5046 = _5037 / max(_5040, 9.9999997473787516355514526367188e-05f).xxx;\n        float _5056 = max(9.9999997473787516355514526367188e-05f, (dot(-_5046, n) + 1.0f) * 0.5f);\n        float w = _4957 * (_5056 * _5056);\n        float3 param_5 = _5046;\n        float2 param_6 = (_5005 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _5076 = fa_gi_fetch(param_6);\n        float _5083 = _5040 / max(_4733.z, 9.9999997473787516355514526367188e-05f);\n        float _5086 = _5076.x;\n        if (_5083 > _5086)\n        {\n            float _5099 = max(_5076.y - (_5086 * _5086), 0.0f);\n            float _5104 = _5083 - _5086;\n            float _5113 = _5099 / max(_5099 + (_5104 * _5104), 9.9999999600419720025001879548654e-13f);\n            w *= ((_5113 * _5113) * _5113);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _5005 + float2(0.5f, 10.5f);\n        float2 param_8 = _5005 + float2(1.5f, 10.5f);\n        float2 param_9 = _5005 + float2(2.5f, 10.5f);\n        float2 param_10 = _5005 + float2(3.5f, 10.5f);\n        float2 param_11 = _5005 + float2(4.5f, 10.5f);\n        float2 param_12 = _5005 + float2(5.5f, 10.5f);\n        float2 param_13 = _5005 + float2(6.5f, 10.5f);\n        float2 param_14 = _5005 + float2(7.5f, 10.5f);\n        float2 param_15 = _5005 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _4835)) + (fa_gi_fetch(param_9).xyz * _4839)) + (fa_gi_fetch(param_10).xyz * _4843)) + (fa_gi_fetch(param_11).xyz * _4850)) + (fa_gi_fetch(param_12).xyz * _4857)) + (fa_gi_fetch(param_13).xyz * _4866)) + (fa_gi_fetch(param_14).xyz * _4873)) + (fa_gi_fetch(param_15).xyz * _4886)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_4785 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _5241;\n    if (_421_fa_gi.z > 0.5f)\n    {\n        _5241 = _4738.x;\n    }\n    else\n    {\n        _5241 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_4733.w * _5241);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _5265 = normalize(_421_fa_camera_pos.xyz - fa_world_pos);\n    int _5270 = int(_421_fa_gi.x + 0.5f);\n    int _5275 = int(_421_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _5275) && (k < 8); k++)\n    {\n        int param = _5270 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _5265;\n        float3 _5300 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5305 = param_3 * left;\n        acc += (_5300 * _5305);\n        left -= _5305;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_421_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _5334 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5334;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_421_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _421_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_421_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_421_fa_cl_info.x) + int(_421_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_421_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4175;\n    if (fa_lm.z > 0.5f)\n    {\n        _4175 = 0.0f;\n    }\n    else\n    {\n        _4175 = 1.0f - clamp(_421_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4186 = _4175 < 1.0f;\n    bool _4192;\n    if (_4186)\n    {\n        int param = li;\n        _4192 = fa_light_baked(param);\n    }\n    else\n    {\n        _4192 = _4186;\n    }\n    return _4192 ? _4175 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _599 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _612 = (c - (ru * hx)) - p;\n        float3 _618 = ru * (2.0f * hx);\n        float _624 = max(dot(_618, _618), 9.9999999392252902907785028219223e-09f);\n        float _628 = dot(_612, _618);\n        float t = clamp((-_628) / _624, 0.0f, 1.0f);\n        if (_599)\n        {\n            float _643 = dot(r, _618);\n            float _649 = _624 - (_643 * _643);\n            if (abs(_649) > (9.9999997473787516355514526367188e-06f * _624))\n            {\n                t = clamp(((dot(r, _612) * _643) - _628) / _649, 0.0f, 1.0f);\n            }\n        }\n        return (p + _612) + (_618 * t);\n    }\n    float3 q = p;\n    float _681 = dot(r, axis);\n    bool _689;\n    if (_599)\n    {\n        _689 = abs(_681) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _689 = _599;\n    }\n    if (_689)\n    {\n        float _699 = dot(c - p, axis) / _681;\n        if (_699 > 0.0f)\n        {\n            q = p + (r * _699);\n        }\n    }\n    float3 _712 = q - c;\n    float2 xy = float2(dot(_712, ru), dot(_712, uu));\n    if (shape > 0.5f)\n    {\n        float _727 = length(xy);\n        if (_727 > hx)\n        {\n            xy *= (hx / _727);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _480_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _480_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _519 = dot(d, right);\n    float _523 = dot(d, up);\n    float _534;\n    if (((_519 * _519) + (_523 * _523)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _534 = atan2(_523, _519) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _534 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_534 - floor(_534)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _369 = abs(d);\n    float _371 = _369.x;\n    float _373 = _369.y;\n    bool _374 = _371 >= _373;\n    bool _382;\n    if (_374)\n    {\n        _382 = _371 >= _369.z;\n    }\n    else\n    {\n        _382 = _374;\n    }\n    int _383;\n    if (_382)\n    {\n        _383 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _398;\n        if (_373 >= _369.z)\n        {\n            _398 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _398 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _383 = _398;\n    }\n    return _383;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _765 = fa_light_base(param);\n    bool _769 = _421_fa_ambient.w > 4.5f;\n    int param_1 = _765;\n    float4 _773 = fa_light_texel(param_1);\n    int param_2 = _765 + 1;\n    float4 _778 = fa_light_texel(param_2);\n    float _781 = _778.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _793 = _769 && (_781 > 2.5f);\n    fa_light_is_area = _793;\n    bool _795 = _781 < 0.5f;\n    float3 l;\n    if (_795)\n    {\n        l = normalize(_773.xyz);\n        if (_769)\n        {\n            int param_3 = _765 + 6;\n            float4 _809 = fa_light_texel(param_3);\n            if (_809.z > 0.5f)\n            {\n                int param_4 = _765 + 4;\n                float4 _819 = fa_light_texel(param_4);\n                int param_5 = _765 + 5;\n                float4 _824 = fa_light_texel(param_5);\n                float2 param_6 = _809.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _819.xyz) * _819.w, (-dot(world_pos, _824.xyz)) * _824.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _854 = _773.xyz;\n        float3 _856 = _854 - world_pos;\n        float3 to_light = _856;\n        float _859 = length(_856);\n        float reach = _859;\n        bool front = true;\n        if (_793)\n        {\n            int param_8 = _765 + 7;\n            reach = max(_859 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _765 + 4;\n            float4 _883 = fa_light_texel(param_9);\n            int param_10 = _765 + 5;\n            float4 _888 = fa_light_texel(param_10);\n            int param_11 = _765 + 6;\n            float4 _893 = fa_light_texel(param_11);\n            float _894 = _893.w;\n            int param_12 = _765 + 2;\n            float3 _901 = normalize(fa_light_texel(param_12).xyz);\n            bool _903 = _894 > 1.5f;\n            bool _911;\n            if (!_903)\n            {\n                _911 = dot(_901, to_light) < 0.0f;\n            }\n            else\n            {\n                _911 = _903;\n            }\n            front = _911;\n            float3 r = 0.0f.xxx;\n            float3 _920 = _421_fa_camera_pos.xyz - world_pos;\n            bool _924 = dot(n, n) > 0.5f;\n            bool _932;\n            if (_924)\n            {\n                _932 = dot(_920, _920) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _932 = _924;\n            }\n            if (_932)\n            {\n                r = reflect(-normalize(_920), normalize(n));\n            }\n            float3 param_13 = _854;\n            float3 param_14 = _901;\n            float3 param_15 = _883.xyz;\n            float3 param_16 = _888.xyz;\n            float param_17 = _883.w;\n            float param_18 = _888.w;\n            float param_19 = _894;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _968 = length(to_light);\n        dist = _968;\n        l = to_light / max(_968, 9.9999997473787516355514526367188e-05f).xxx;\n        float _982 = reach / max(_773.w, 0.001000000047497451305389404296875f);\n        float _988 = clamp(1.0f - (_982 * _982), 0.0f, 1.0f);\n        float _990;\n        if (front)\n        {\n            _990 = _988 * _988;\n        }\n        else\n        {\n            _990 = 0.0f;\n        }\n        atten = _990;\n        bool _1001 = _781 < 2.5f;\n        if ((_781 > 1.5f) && _1001)\n        {\n            int param_22 = _765 + 2;\n            float4 _1009 = fa_light_texel(param_22);\n            float _1019 = _1009.w;\n            int param_23 = _765 + 3;\n            float4 _1024 = fa_light_texel(param_23);\n            float _1025 = _1024.x;\n            float cos_inner = _1025;\n            if (_1025 > 1.5f)\n            {\n                cos_inner = lerp(_1019, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1019, cos_inner, dot(-l, normalize(_1009.xyz)));\n        }\n        if (_769 && (_781 < 1.5f))\n        {\n            int param_24 = _765 + 6;\n            float4 _1049 = fa_light_texel(param_24);\n            if (_1049.z > 0.5f)\n            {\n                float3 _1057 = -to_light;\n                int param_25 = _765 + 4;\n                int param_26 = _765 + 5;\n                float3 _1071 = fa_light_texel(param_25).xyz;\n                float3 _1075 = fa_light_texel(param_26).xyz;\n                float3 _1084 = float3(dot(_1057, _1071), dot(_1057, _1075), dot(_1057, cross(_1071, _1075)));\n                float3 param_27 = _1084;\n                int _1088 = fa_cube_face(param_27);\n                int param_28 = _1088;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1115 = float2(dot(_1084, cross(param_29, param_30)), dot(_1084, param_30)) / max(dot(_1084, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1119 = _1088 / 3;\n                float2 param_31 = _1049.xy + (float2(float(_1088 - (_1119 * 3)), float(_1119)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1115.x), 0.5f - (0.5f * _1115.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _765 + 7;\n            float4 _1149 = fa_light_texel(param_33);\n            if (_1149.z > 0.5f)\n            {\n                int param_34 = _765 + 2;\n                int param_35 = _765 + 4;\n                int param_36 = _765 + 5;\n                float2 param_37 = _1149.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_769 && _1001)\n            {\n                int param_42 = _765 + 6;\n                float4 _1196 = fa_light_texel(param_42);\n                int param_43 = _765 + 7;\n                float4 _1201 = fa_light_texel(param_43);\n                bool _1204 = _1196.z > 0.5f;\n                bool _1211;\n                if (!_1204)\n                {\n                    _1211 = _1201.z > 0.5f;\n                }\n                else\n                {\n                    _1211 = _1204;\n                }\n                if (_1211)\n                {\n                    int param_44 = _765 + 2;\n                    float4 _1218 = fa_light_texel(param_44);\n                    float3 _1222 = normalize(_1218.xyz);\n                    int param_45 = _765 + 4;\n                    float4 _1227 = fa_light_texel(param_45);\n                    int param_46 = _765 + 5;\n                    float4 _1232 = fa_light_texel(param_46);\n                    if (_1204)\n                    {\n                        float3 _1240 = -to_light;\n                        float _1247 = _1218.w;\n                        float _1263 = 0.5f / max(dot(_1240, _1222) * (sqrt(max(1.0f - (_1247 * _1247), 0.0f)) / max(_1247, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1196.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1240, _1227.xyz) * _1263), 0.5f - (dot(_1240, _1232.xyz) * _1263));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1201.z > 0.5f)\n                    {\n                        float2 param_49 = _1201.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1222;\n                        float3 param_52 = _1227.xyz;\n                        float3 param_53 = _1232.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6021 = _778.xyz * atten;\n    if (_769)\n    {\n        _6021 *= fa_light_tint;\n    }\n    int _1331;\n    if (_795)\n    {\n        _1331 = 0;\n    }\n    else\n    {\n        _1331 = ((_781 > 1.5f) && (_781 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _6032 = { l, _6021, atten, 1.0f, dist, _1331 };\n    return _6032;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2120 = fa_shadow_depth(param, param_1);\n    float _2124;\n    if (conv.x < 0.5f)\n    {\n        _2124 = _2120;\n    }\n    else\n    {\n        _2124 = (conv.y * conv.z) / (conv.z - (_2120 * (conv.z - conv.y)));\n    }\n    return _2124;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2170 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2176 = float2(cos(_2170), sin(_2170));\n    float2 dir = _2176;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2185;\n        if (k < 0.0f)\n        {\n            _2185 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2185 = k;\n        }\n        float _2204 = clamp((_2185 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2223 = sqrt((float(i) + 0.5f) * 0.0625f) * _2204;\n            float2 param_3 = uv + (dir * (_2073_fa_shadow_bias.zw * _2223));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2237 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2237 < (zr - (_2223 * plane)))\n            {\n                sum += _2237;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2265 = sum / cnt;\n        float _2275;\n        if (k < 0.0f)\n        {\n            _2275 = (-k) / max(_2265, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2275 = k;\n        }\n        radius = clamp(((max(zr - _2265, 0.0f) * unit) * _2275) / texel_m, 1.5f, 16.0f);\n        dir = _2176;\n    }\n    float lit = 0.0f;\n    int _2301 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2301; i_1++)\n    {\n        float _2320 = sqrt((float(i_1) + 0.5f) / float(_2301)) * radius;\n        float2 param_7 = uv + (dir * (_2073_fa_shadow_bias.zw * _2320));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2320 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2301);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2525 = _421_fa_pbr.z < 0.5f;\n    bool _2532;\n    if (!_2525)\n    {\n        _2532 = _2073_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2532 = _2525;\n    }\n    if (_2532)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2073_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2545 = fa_light_texel(param);\n    float _2546 = _2545.x;\n    if (_2546 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2555 = int(_2546 + 0.5f);\n    int param_1 = _2555;\n    float4 _2559 = fa_light_texel(param_1);\n    int param_2 = _2555 + 1;\n    float4 _2564 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2567 = _2559.y;\n    if (_2567 > 0.0f)\n    {\n        float _2584 = 1.0f - smoothstep(0.75f * _2567, _2567, length(world - _2073_fa_shadow_eye.xyz));\n        fade = _2584;\n        if (_2584 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2559.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2608 = (_2555 + 2) + (face * 6);\n    int param_4 = _2608;\n    int param_5 = _2608 + 1;\n    int param_6 = _2608 + 3;\n    float4 _2622 = fa_light_texel(param_6);\n    int param_7 = _2608 + 4;\n    float4 _2627 = fa_light_texel(param_7);\n    int param_8 = _2608 + 5;\n    float4 _2632 = fa_light_texel(param_8);\n    float _2644 = _2632.x * max(dot(_2622, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2649 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2672 = clamp(dot(n, _2622.xyz), -1.0f, 1.0f);\n    float _2691 = min(sqrt(1.0f - (_2672 * _2672)) / max(abs(dot(n, world - lpos)) / max(dot(_2622, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2694 = _2564.y;\n    float _2696;\n    if (_2694 > 0.0f)\n    {\n        _2696 = _2694;\n    }\n    else\n    {\n        _2696 = 1.5f * _2644;\n    }\n    float4 _2716 = float4(world + (n * (_2696 * sqrt(1.0f - (_2649 * _2649)))), 1.0f);\n    float _2720 = dot(_2622, _2716);\n    float _2723 = _2632.y;\n    if (_2720 < _2723)\n    {\n        return 1.0f;\n    }\n    float2 _2738 = float2(dot(fa_light_texel(param_4), _2716), dot(fa_light_texel(param_5), _2716)) / _2720.xx;\n    float _2740 = _2738.x;\n    bool _2743 = _2740 < _2627.x;\n    bool _2752;\n    if (!_2743)\n    {\n        _2752 = _2740 > _2627.z;\n    }\n    else\n    {\n        _2752 = _2743;\n    }\n    bool _2761;\n    if (!_2752)\n    {\n        _2761 = _2738.y < _2627.y;\n    }\n    else\n    {\n        _2761 = _2752;\n    }\n    bool _2770;\n    if (!_2761)\n    {\n        _2770 = _2738.y > _2627.w;\n    }\n    else\n    {\n        _2770 = _2761;\n    }\n    if (_2770)\n    {\n        return 1.0f;\n    }\n    float _2776 = _2564.x;\n    float _2778;\n    if (_2776 > 0.0f)\n    {\n        _2778 = _2776;\n    }\n    else\n    {\n        _2778 = 1.5f * _2644;\n    }\n    float2 param_9 = _2738;\n    float4 param_10 = _2627;\n    float param_11 = _2720 - (_2778 * (1.0f + (0.5f * _2691)));\n    float param_12 = _2644;\n    float param_13 = 1.0f;\n    float param_14 = _2632.z * 0.25f;\n    float param_15 = (_2644 * min(_2691, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2723, _2632.z);\n    int param_17 = int(_2559.z + 0.5f);\n    float param_18 = _2559.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _3290 = _421_fa_ct_b.w > 0.5f;\n    bool _3296;\n    if (_3290)\n    {\n        _3296 = _421_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3296 = _3290;\n    }\n    bool _3302;\n    if (_3296)\n    {\n        _3302 = _2073_fa_shadow_lcfg.x > 0.5f;\n    }\n    else\n    {\n        _3302 = _3296;\n    }\n    if (_3302)\n    {\n        int param = (int(_2073_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n        float4 _3314 = fa_light_texel(param);\n        float _3315 = _3314.z;\n        if (_3315 > 0.5f)\n        {\n            float _3328 = dot(_421_fa_ct_fwd.xyz, world) + _421_fa_ct_fwd.w;\n            float _3331 = fwidth(_3328);\n            float _3335 = min(1.5f * _3331, 0.100000001490116119384765625f * _3328);\n            float4 _3341 = float4(world, 1.0f);\n            float _3346 = dot(_421_fa_ct_vpw, _3341);\n            if (_3346 > 9.9999997473787516355514526367188e-05f)\n            {\n                float2 _3363 = float2(dot(_421_fa_ct_vpx, _3341), dot(_421_fa_ct_vpy, _3341)) / _3346.xx;\n                float _3368 = (_3363.x * 0.5f) + 0.5f;\n                float _3372;\n                if (_421_fa_ct_a.y > 0.5f)\n                {\n                    _3372 = (_3363.y * 0.5f) + 0.5f;\n                }\n                else\n                {\n                    _3372 = 0.5f - (_3363.y * 0.5f);\n                }\n                bool _3388 = _3368 >= 0.0f;\n                bool _3394;\n                if (_3388)\n                {\n                    _3394 = _3368 < 1.0f;\n                }\n                else\n                {\n                    _3394 = _3388;\n                }\n                bool _3400;\n                if (_3394)\n                {\n                    _3400 = _3372 >= 0.0f;\n                }\n                else\n                {\n                    _3400 = _3394;\n                }\n                bool _3406;\n                if (_3400)\n                {\n                    _3406 = _3372 < 1.0f;\n                }\n                else\n                {\n                    _3406 = _3400;\n                }\n                if (_3406)\n                {\n                    int2 _3423 = int2(_421_fa_ct_a.zw) - int2(1, 1);\n                    int2 _3424 = clamp(int2(float2(_3368, _3372) * _421_fa_ct_a.zw), int2(0, 0), _3423);\n                    int2 _3436;\n                    int2 _3442;\n                    int2 _3449;\n                    float _3500;\n                    float _3521;\n                    for (int k = 0; k < 5; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3436 = int2(0, 0);\n                        }\n                        else\n                        {\n                            if (k == 1)\n                            {\n                                _3442 = int2(1, 0);\n                            }\n                            else\n                            {\n                                if (k == 2)\n                                {\n                                    _3449 = int2(-1, 0);\n                                }\n                                else\n                                {\n                                    bool2 _3460 = (k == 3).xx;\n                                    _3449 = int2(_3460.x ? int2(0, 1).x : int2(0, -1).x, _3460.y ? int2(0, 1).y : int2(0, -1).y);\n                                }\n                                _3442 = _3449;\n                            }\n                            _3436 = _3442;\n                        }\n                        float4 _3477 = fa_screen_tex.Load(int3(clamp(_3424 + _3436, int2(0, 0), _3423), 0));\n                        bool _3480 = _3477.w > 0.5f;\n                        bool _3494;\n                        if (_3480)\n                        {\n                            _3494 = abs(_3328 - _3477.x) <= (((0.00200000009499490261077880859375f * _3328) + 0.00999999977648258209228515625f) + _3335);\n                        }\n                        else\n                        {\n                            _3494 = _3480;\n                        }\n                        if (_3494)\n                        {\n                            if (_3315 < 1.5f)\n                            {\n                                _3500 = 1.0f;\n                            }\n                            else\n                            {\n                                _3500 = (_3315 < 2.5f) ? 256.0f : 65536.0f;\n                            }\n                            float _3517 = mod(floor(_3477.z / _3500), 256.0f) * 0.0039215688593685626983642578125f;\n                            if (_421_fa_ct_b.z > 0.5f)\n                            {\n                                int param_1 = li;\n                                float3 param_2 = lpos;\n                                float3 param_3 = world;\n                                float3 param_4 = n;\n                                float3 param_5 = l;\n                                _3521 = min(_3517, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                            }\n                            else\n                            {\n                                _3521 = _3517;\n                            }\n                            return _3521;\n                        }\n                    }\n                }\n            }\n            float _3546;\n            if (_421_fa_ct_b.z > 0.5f)\n            {\n                int param_6 = li;\n                float3 param_7 = lpos;\n                float3 param_8 = world;\n                float3 param_9 = n;\n                float3 param_10 = l;\n                _3546 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3546 = 1.0f;\n            }\n            return _3546;\n        }\n    }\n    int param_11 = li;\n    float3 param_12 = lpos;\n    float3 param_13 = world;\n    float3 param_14 = n;\n    float3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2063;\n    if (i == 0)\n    {\n        _2063 = _2073_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2079;\n        if (i == 1)\n        {\n            _2079 = _2073_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2087;\n            if (i == 2)\n            {\n                _2087 = _2073_fa_shadow_split.z;\n            }\n            else\n            {\n                _2087 = _2073_fa_shadow_split.w;\n            }\n            _2079 = _2087;\n        }\n        _2063 = _2079;\n    }\n    return _2063;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2366 = max(_2073_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2371 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2377 = sqrt(1.0f - (_2371 * _2371));\n    float _2385 = min(_2377 / max(_2371, 0.20000000298023223876953125f), 4.0f);\n    float _2390;\n    if (_2073_fa_shadow_bias.y > 0.0f)\n    {\n        _2390 = _2073_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2390 = 1.5f * _2073_fa_shadow_info[ci].x;\n    }\n    float4 _2415 = mul(float4(world + (n * (_2390 * _2377)), 1.0f), _2073_fa_shadow_mat[ci]);\n    float _2422 = _2415.x;\n    bool _2425 = _2422 < _2073_fa_shadow_rect[ci].x;\n    bool _2434;\n    if (!_2425)\n    {\n        _2434 = _2422 > _2073_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2434 = _2425;\n    }\n    bool _2443;\n    if (!_2434)\n    {\n        _2443 = _2415.y < _2073_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2443 = _2434;\n    }\n    bool _2452;\n    if (!_2443)\n    {\n        _2452 = _2415.y > _2073_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2452 = _2443;\n    }\n    bool _2459;\n    if (!_2452)\n    {\n        _2459 = _2415.z > 1.0f;\n    }\n    else\n    {\n        _2459 = _2452;\n    }\n    if (_2459)\n    {\n        return -1.0f;\n    }\n    float _2467;\n    if (_2073_fa_shadow_bias.x > 0.0f)\n    {\n        _2467 = _2073_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2467 = 1.5f * _2073_fa_shadow_info[ci].x;\n    }\n    float2 param = _2415.xy;\n    float4 param_1 = _2073_fa_shadow_rect[ci];\n    float param_2 = _2415.z - ((_2467 * (1.0f + (0.5f * _2385))) / _2366);\n    float param_3 = _2073_fa_shadow_info[ci].x;\n    float param_4 = _2366;\n    float param_5 = _2366 * 0.25f;\n    float param_6 = ((_2073_fa_shadow_info[ci].x * min(_2385, 3.0f)) * 0.5f) / _2366;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2073_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2073_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_421_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2845 = int(_2073_fa_shadow_cfg.x + 0.5f);\n    if (_2845 < 1)\n    {\n        return 1.0f;\n    }\n    float _2860 = dot(world - _2073_fa_shadow_eye.xyz, _2073_fa_shadow_fwd.xyz);\n    int param = _2845 - 1;\n    if (_2860 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2872 = _2845 > 1;\n    bool _2879;\n    if (_2872)\n    {\n        _2879 = _2860 > _2073_fa_shadow_split.x;\n    }\n    else\n    {\n        _2879 = _2872;\n    }\n    if (_2879)\n    {\n        ci = 1;\n    }\n    bool _2883 = _2845 > 2;\n    bool _2890;\n    if (_2883)\n    {\n        _2890 = _2860 > _2073_fa_shadow_split.y;\n    }\n    else\n    {\n        _2890 = _2883;\n    }\n    if (_2890)\n    {\n        ci = 2;\n    }\n    bool _2894 = _2845 > 3;\n    bool _2901;\n    if (_2894)\n    {\n        _2901 = _2860 > _2073_fa_shadow_split.z;\n    }\n    else\n    {\n        _2901 = _2894;\n    }\n    if (_2901)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _2912 = min(_2845, 4);\n    float _2953;\n    for (int c = ci; c < _2912; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2932 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _2932;\n            break;\n        }\n        if (_2932 < 0.0f)\n        {\n            continue;\n        }\n        s = _2932;\n        ci = c;\n        if (_2073_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2953 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2953 = _2073_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _2972 = _2073_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2953, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_2860 - (fa_shadow_split_at(param_7) - _2972)) / _2972, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3004;\n        if ((ci + 1) < _2845)\n        {\n            _3004 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3004 = 1.0f;\n        }\n        s = lerp(s, _3004, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    bool _3109 = _421_fa_ct_b.y > 0.5f;\n    bool _3115;\n    if (_3109)\n    {\n        _3115 = _421_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3115 = _3109;\n    }\n    if (_3115)\n    {\n        float _3129 = dot(_421_fa_ct_fwd.xyz, fa_world_pos) + _421_fa_ct_fwd.w;\n        float _3132 = fwidth(_3129);\n        float4 _3142 = float4(fa_world_pos, 1.0f);\n        float _3148 = dot(_421_fa_ct_vpw, _3142);\n        if (_3148 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _3167 = float2(dot(_421_fa_ct_vpx, _3142), dot(_421_fa_ct_vpy, _3142)) / _3148.xx;\n            float _3172 = (_3167.x * 0.5f) + 0.5f;\n            float _3176;\n            if (_421_fa_ct_a.y > 0.5f)\n            {\n                _3176 = (_3167.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _3176 = 0.5f - (_3167.y * 0.5f);\n            }\n            bool _3192 = _3172 >= 0.0f;\n            bool _3198;\n            if (_3192)\n            {\n                _3198 = _3172 < 1.0f;\n            }\n            else\n            {\n                _3198 = _3192;\n            }\n            bool _3204;\n            if (_3198)\n            {\n                _3204 = _3176 >= 0.0f;\n            }\n            else\n            {\n                _3204 = _3198;\n            }\n            bool _3210;\n            if (_3204)\n            {\n                _3210 = _3176 < 1.0f;\n            }\n            else\n            {\n                _3210 = _3204;\n            }\n            if (_3210)\n            {\n                float4 _3236 = fa_screen_tex.Load(int3(clamp(int2(float2(_3172, _3176) * _421_fa_ct_a.zw), int2(0, 0), int2(_421_fa_ct_a.zw) - int2(1, 1)), 0));\n                bool _3239 = _3236.w > 0.5f;\n                bool _3255;\n                if (_3239)\n                {\n                    _3255 = abs(_3129 - _3236.x) <= (((0.00200000009499490261077880859375f * _3129) + 0.00999999977648258209228515625f) + min(1.5f * _3132, 0.100000001490116119384765625f * _3129));\n                }\n                else\n                {\n                    _3255 = _3239;\n                }\n                if (_3255)\n                {\n                    float _3261;\n                    if (_421_fa_ct_b.z > 0.5f)\n                    {\n                        float3 param = fa_world_pos;\n                        float3 param_1 = n;\n                        float3 param_2 = l;\n                        _3261 = min(_3236.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3261 = _3236.y;\n                    }\n                    return _3261;\n                }\n            }\n        }\n    }\n    float3 param_3 = fa_world_pos;\n    float3 param_4 = n;\n    float3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3917 = _421_fa_ct_a.x < 0.5f;\n    bool _3924;\n    if (!_3917)\n    {\n        _3924 = _2073_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3924 = _3917;\n    }\n    if (_3924)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2073_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3937 = fa_light_texel(param);\n    float _3938 = _3937.y;\n    float len = _3938;\n    if (_3938 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3950 = length(world - _421_fa_camera_pos.xyz);\n    float _3959 = 1.0f - smoothstep(0.5f * _421_fa_ct_b.x, _421_fa_ct_b.x, _3950);\n    if (_3959 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3965 = len;\n    float _3968 = min(_3965, 0.89999997615814208984375f * dist);\n    len = _3968;\n    float _3974 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3950);\n    float _3979 = _3974 + (0.5f * _3968);\n    float3 _3985 = world + (gn * _3974);\n    float _3987 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4049;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4003 = (float(k) + _3987) * 0.083333335816860198974609375f;\n        float3 _4011 = _3985 + (l * (_4003 * len));\n        float4 _4017 = float4(_4011, 1.0f);\n        float _4022 = dot(_421_fa_ct_vpw, _4017);\n        if (_4022 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4040 = float2(dot(_421_fa_ct_vpx, _4017), dot(_421_fa_ct_vpy, _4017)) / _4022.xx;\n        float _4044 = _4040.x * 0.5f;\n        float _4045 = _4044 + 0.5f;\n        if (_421_fa_ct_a.y > 0.5f)\n        {\n            _4049 = (_4040.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4049 = 0.5f - (_4040.y * 0.5f);\n        }\n        bool _4065 = _4045 < 0.0f;\n        bool _4072;\n        if (!_4065)\n        {\n            _4072 = _4045 >= 1.0f;\n        }\n        else\n        {\n            _4072 = _4065;\n        }\n        bool _4079;\n        if (!_4072)\n        {\n            _4079 = _4049 < 0.0f;\n        }\n        else\n        {\n            _4079 = _4072;\n        }\n        bool _4086;\n        if (!_4079)\n        {\n            _4086 = _4049 >= 1.0f;\n        }\n        else\n        {\n            _4086 = _4079;\n        }\n        if (_4086)\n        {\n            break;\n        }\n        float4 _4110 = fa_screen_tex.Load(int3(clamp(int2(float2(_4045, _4049) * _421_fa_ct_a.zw), int2(0, 0), int2(_421_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_4110.w < 0.5f)\n        {\n            continue;\n        }\n        float _4128 = (dot(_421_fa_ct_fwd.xyz, _4011) + _421_fa_ct_fwd.w) - _4110.x;\n        if ((_4128 > _3974) && (_4128 < _3979))\n        {\n            occ = max(occ, (1.0f - (_4003 * _4003)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4045, 0.5f - _4044), min(_4049, 1.0f - _4049))));\n        }\n    }\n    return 1.0f - (occ * _3959);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4231 = fa_baked_keep(param);\n    if (_4231 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _6045 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6045;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4257 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6047 = _4257.color;\n    float _6048 = _4257.attenuation;\n    float _6049 = _4257.shadow;\n    bool _4260 = _4257.type == 0;\n    if (_4260 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4257.direction;\n        float _4271 = fa_shadow_factor(param_5, param_6);\n        _6049 = _4271;\n        _6047 *= _4271;\n    }\n    else\n    {\n        bool _4282 = _4257.type != 0;\n        bool _4288;\n        if (_4282)\n        {\n            _4288 = _6048 > 0.0f;\n        }\n        else\n        {\n            _4288 = _4282;\n        }\n        if (_4288)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4257.direction;\n            float _4307 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6049 = _4307;\n            _6047 *= _4307;\n        }\n    }\n    bool _4317 = _421_fa_ct_a.x > 0.5f;\n    bool _4323;\n    if (_4317)\n    {\n        _4323 = _6048 > 0.0f;\n    }\n    else\n    {\n        _4323 = _4317;\n    }\n    if (_4323)\n    {\n        float _4330;\n        if (_4260)\n        {\n            _4330 = 1000000000.0f;\n        }\n        else\n        {\n            _4330 = _4257._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4257.direction;\n        float param_18 = _4330;\n        float _4348 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6049 *= _4348;\n        _6047 *= _4348;\n    }\n    float _4361 = _6048;\n    float _4362 = _4361 * _4231;\n    _6048 = _4362;\n    float3 _4366 = _6047;\n    float3 _4367 = _4366 * _4231;\n    _6047 = _4367;\n    LightSample _6064 = { _4257.direction, _4367, _4362, _6049, _4257._distance, _4257.type };\n    return _6064;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2073_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3032 = int(_2073_fa_shadow_cfg.x + 0.5f);\n    float _3042 = dot(world - _2073_fa_shadow_eye.xyz, _2073_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3047 = _3032 > 0;\n    bool _3056;\n    if (_3047)\n    {\n        int param = _3032 - 1;\n        _3056 = _3042 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3056 = _3047;\n    }\n    if (_3056)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3062 = _3032 > 1;\n        bool _3069;\n        if (_3062)\n        {\n            _3069 = _3042 > _2073_fa_shadow_split.x;\n        }\n        else\n        {\n            _3069 = _3062;\n        }\n        if (_3069)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3075 = _3032 > 2;\n        bool _3082;\n        if (_3075)\n        {\n            _3082 = _3042 > _2073_fa_shadow_split.y;\n        }\n        else\n        {\n            _3082 = _3075;\n        }\n        if (_3082)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3088 = _3032 > 3;\n        bool _3095;\n        if (_3088)\n        {\n            _3095 = _3042 > _2073_fa_shadow_split.z;\n        }\n        else\n        {\n            _3095 = _3088;\n        }\n        if (_3095)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5868 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5868 = -_5868;\n    }\n    float3 _5442 = normalize(_421_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5881 = { fa_world_pos, _5868, fa_world_tangent, fa_uv, fa_vertex_color, _5442, gl_FrontFacing };\n    SurfaceInput param_1 = _5881;\n    Surface _5450 = fa_standard_surface(param_1);\n    float3 _5899 = _5450.albedo;\n    float _5900 = _5450.alpha;\n    float3 _5901 = _5450.normal;\n    float _5902 = _5450.metallic;\n    float _5903 = _5450.roughness;\n    float _5904 = _5450.occlusion;\n    float3 _5905 = _5450.emission;\n    float _5906 = _5450.clearcoat;\n    float _5907 = _5450.clearcoat_roughness;\n    float3 _5908 = _5450.sheen_color;\n    float _5909 = _5450.sheen_roughness;\n    float _5910 = _5450.anisotropy;\n    float _5911 = _5450.anisotropy_rotation;\n    float _5912 = _5450.specular;\n    float _5913 = _5450.ior;\n    float3 _5914 = _5450.specular_color;\n    float _5915 = _5450.transmission;\n    float _5916 = _5450.thickness;\n    float3 _5917 = _5450.attenuation_color;\n    float _5918 = _5450.attenuation_distance;\n    SurfaceInput _5889 = { fa_world_pos, _5868, fa_world_tangent, fa_uv, fa_vertex_color, _5442, gl_FrontFacing };\n    SurfaceInput param_2 = _5889;\n    Surface param_3 = _5450;\n    surface(param_2, param_3);\n    _5899 = param_3.albedo;\n    _5900 = param_3.alpha;\n    _5901 = param_3.normal;\n    _5902 = param_3.metallic;\n    _5903 = param_3.roughness;\n    _5904 = param_3.occlusion;\n    _5905 = param_3.emission;\n    _5906 = param_3.clearcoat;\n    _5907 = param_3.clearcoat_roughness;\n    _5908 = param_3.sheen_color;\n    _5909 = param_3.sheen_roughness;\n    _5910 = param_3.anisotropy;\n    _5911 = param_3.anisotropy_rotation;\n    _5912 = param_3.specular;\n    _5913 = param_3.ior;\n    _5914 = param_3.specular_color;\n    _5915 = param_3.transmission;\n    _5916 = param_3.thickness;\n    _5917 = param_3.attenuation_color;\n    _5918 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5868;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5899 = param_6;\n    _5901 = param_7;\n    float3 result;\n    if (_421_fa_emissive.w > 0.5f)\n    {\n        result = _5899;\n    }\n    else\n    {\n        float3 _5489 = _5901;\n        float3 _5490 = normalize(_5489);\n        _5901 = _5490;\n        float3 param_8 = _5490;\n        float3 lit = (fa_indirect_diffuse(param_8) * _5899) * _5904;\n        int _5509 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5509; ln++)\n        {\n            int param_9 = ln;\n            int _5522 = fa_cl_light(param_9);\n            int param_10 = _5522;\n            if (fa_baked_keep(param_10) <= 0.0f)\n            {\n                continue;\n            }\n            int param_11 = _5522;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _5868;\n            LightSample _5538 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput _5897 = { fa_world_pos, _5868, fa_world_tangent, fa_uv, fa_vertex_color, _5442, gl_FrontFacing };\n            SurfaceInput param_14 = _5897;\n            Surface _6000 = { _5899, _5900, _5901, _5902, _5903, _5904, _5905, _5906, _5907, _5908, _5909, _5910, _5911, _5912, _5913, _5914, _5915, _5916, _5917, _5918 };\n            Surface param_15 = _6000;\n            LightSample param_16 = _5538;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _5553 = result;\n    float3 _5554 = _5553 + _5905;\n    result = _5554;\n    float3 param_17 = _5554;\n    float3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _5563 = _421_fa_fog.w > 0.0f;\n    bool _5570;\n    if (!_5563)\n    {\n        _5570 = _421_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5570 = _5563;\n    }\n    if (_5570)\n    {\n        float3 _5579 = fa_world_pos - _421_fa_camera_pos.xyz;\n        float _5585 = dot(_5579, _421_fa_fog_c.xyz);\n        bool _5589 = _421_fa_fog_c.w > 0.5f;\n        float _5590;\n        if (_5589)\n        {\n            _5590 = _5585;\n        }\n        else\n        {\n            _5590 = length(_5579);\n        }\n        float _5602 = _5590 - _421_fa_fog_b.x;\n        if (_5602 > 0.0f)\n        {\n            float _5611 = _421_fa_fog.w * _5602;\n            float tau = _5611 * _5611;\n            if (_421_fa_fog_b.y > 0.0f)\n            {\n                float _5627;\n                if (_5589)\n                {\n                    _5627 = fa_world_pos.y - (_421_fa_fog_c.y * _5585);\n                }\n                else\n                {\n                    _5627 = _421_fa_camera_pos.y;\n                }\n                float _5648 = lerp(_5627, fa_world_pos.y, clamp(_421_fa_fog_b.x / _5590, 0.0f, 1.0f));\n                float _5652 = fa_world_pos.y - _5648;\n                float _5657 = _5648 - _421_fa_fog_b.z;\n                float _5662 = fa_world_pos.y - _421_fa_fog_b.z;\n                bool _5665 = _5657 <= 0.0f;\n                bool _5666 = !_5665;\n                bool _5672;\n                if (_5666)\n                {\n                    _5672 = _421_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5672 = _5665;\n                }\n                float _5673;\n                if (_5672)\n                {\n                    _5673 = _421_fa_fog_b.y;\n                }\n                else\n                {\n                    _5673 = _421_fa_fog_b.y * exp(-min(_421_fa_fog_b.w * _5657, 80.0f));\n                }\n                bool _5700;\n                if (_5666)\n                {\n                    _5700 = _421_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5700 = _5665;\n                }\n                float _5701;\n                if (_5700)\n                {\n                    _5701 = _421_fa_fog_b.y * _5657;\n                }\n                else\n                {\n                    _5701 = (_421_fa_fog_b.y * (1.0f - exp(-min(_421_fa_fog_b.w * _5657, 80.0f)))) / _421_fa_fog_b.w;\n                }\n                bool _5726 = _5662 <= 0.0f;\n                bool _5733;\n                if (!_5726)\n                {\n                    _5733 = _421_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5733 = _5726;\n                }\n                float _5734;\n                if (_5733)\n                {\n                    _5734 = _421_fa_fog_b.y * _5662;\n                }\n                else\n                {\n                    _5734 = (_421_fa_fog_b.y * (1.0f - exp(-min(_421_fa_fog_b.w * _5662, 80.0f)))) / _421_fa_fog_b.w;\n                }\n                float _5761;\n                if (abs(_5652) < 0.001000000047497451305389404296875f)\n                {\n                    _5761 = _5673;\n                }\n                else\n                {\n                    _5761 = (_5734 - _5701) / _5652;\n                }\n                tau += (_5602 * max(_5761, 0.0f));\n            }\n            result = lerp(result, _421_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5900);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_421",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2073",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _381 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _381;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_388, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _421_fa_camera_pos : packoffset(c0);\n    float4 _421_fa_ambient : packoffset(c1);\n    float4 _421_fa_base_color : packoffset(c2);\n    float4 _421_fa_emissive : packoffset(c3);\n    float4 _421_fa_model_emissive : packoffset(c4);\n    float4 _421_fa_pbr : packoffset(c5);\n    float4 _421_fa_maps : packoffset(c6);\n    float4 _421_fa_fog : packoffset(c7);\n    float4 _421_fa_fog_b : packoffset(c8);\n    float4 _421_fa_fog_c : packoffset(c9);\n    float4 _421_fa_counts : packoffset(c10);\n    float4 _421_fa_env_sky : packoffset(c11);\n    float4 _421_fa_env_horizon : packoffset(c12);\n    float4 _421_fa_time : packoffset(c13);\n    float4 _421_fa_cl_vpx : packoffset(c14);\n    float4 _421_fa_cl_vpy : packoffset(c15);\n    float4 _421_fa_cl_vpw : packoffset(c16);\n    float4 _421_fa_cl_fwd : packoffset(c17);\n    float4 _421_fa_cl_grid : packoffset(c18);\n    float4 _421_fa_cl_info : packoffset(c19);\n    float4 _421_fa_layers_a : packoffset(c20);\n    float4 _421_fa_layers_b : packoffset(c21);\n    float4 _421_fa_layers_c : packoffset(c22);\n    float4 _421_fa_layers_d : packoffset(c23);\n    float4 _421_fa_ct_a : packoffset(c24);\n    float4 _421_fa_ct_b : packoffset(c25);\n    float4 _421_fa_ct_vpx : packoffset(c26);\n    float4 _421_fa_ct_vpy : packoffset(c27);\n    float4 _421_fa_ct_vpw : packoffset(c28);\n    float4 _421_fa_ct_fwd : packoffset(c29);\n    float4 _421_fa_tr_a : packoffset(c30);\n    float4 _421_fa_tr_b : packoffset(c31);\n    float4 _421_fa_probe_sh[9] : packoffset(c32);\n    float4 _421_fa_atlas : packoffset(c41);\n    float4 _421_fa_rpa_tile : packoffset(c42);\n    float4 _421_fa_rpa_pos : packoffset(c43);\n    float4 _421_fa_rpa_bx : packoffset(c44);\n    float4 _421_fa_rpa_by : packoffset(c45);\n    float4 _421_fa_rpa_bz : packoffset(c46);\n    float4 _421_fa_rpb_tile : packoffset(c47);\n    float4 _421_fa_rpb_pos : packoffset(c48);\n    float4 _421_fa_rpb_bx : packoffset(c49);\n    float4 _421_fa_rpb_by : packoffset(c50);\n    float4 _421_fa_rpb_bz : packoffset(c51);\n    float4 _421_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2073_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2073_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2073_fa_shadow_info[4] : packoffset(c20);\n    float4 _2073_fa_shadow_split : packoffset(c24);\n    float4 _2073_fa_shadow_cfg : packoffset(c25);\n    float4 _2073_fa_shadow_bias : packoffset(c26);\n    float4 _2073_fa_shadow_eye : packoffset(c27);\n    float4 _2073_fa_shadow_fwd : packoffset(c28);\n    float4 _2073_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1349 = _421_fa_cl_info.x < 0.0f;\n    bool _1356;\n    if (!_1349)\n    {\n        _1356 = _421_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1356 = _1349;\n    }\n    bool _1364;\n    if (!_1356)\n    {\n        _1364 = _421_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1364 = _1356;\n    }\n    bool _1371;\n    if (!_1364)\n    {\n        _1371 = _421_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1371 = _1364;\n    }\n    bool _1378;\n    if (!_1371)\n    {\n        _1378 = _421_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1378 = _1371;\n    }\n    if (_1378)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1388 = float4(world_pos, 1.0f);\n    float _1394 = dot(_421_fa_cl_vpw, _1388);\n    if (!(_1394 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1416 = float2(dot(_421_fa_cl_vpx, _1388), dot(_421_fa_cl_vpy, _1388)) / _1394.xx;\n    int _1420 = int(_421_fa_cl_grid.x);\n    int _1424 = int(_421_fa_cl_grid.y);\n    int param = (int(_421_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_421_fa_cl_fwd.xyz, world_pos) + _421_fa_cl_fwd.w, _421_fa_cl_grid.w) / _421_fa_cl_grid.w) * _421_fa_cl_grid.z)), 0, int(_421_fa_cl_info.y) - 1) * _1424) + clamp(int(floor(((_1416.y * 0.5f) + 0.5f) * _421_fa_cl_grid.y)), 0, _1424 - 1)) * _1420)) + clamp(int(floor(((_1416.x * 0.5f) + 0.5f) * _421_fa_cl_grid.x)), 0, _1420 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1500 = fa_cluster_texel(param);\n    return int2(int(_1500.x), int(_1500.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_421_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4205 = fa_cluster_lookup(param);\n    fa_cl_slot = _4205.x;\n    fa_cl_local = _4205.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4410 = fa_linear_to_srgb(param);\n        c = _4410;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4418 = fa_srgb_to_linear(param_1);\n            c = _4418;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _303;\n    if (i.front_facing)\n    {\n        _303 = i.world_normal;\n    }\n    else\n    {\n        _303 = -i.world_normal;\n    }\n    float3 _327 = normalize(i.world_tangent.xyz - (_303 * dot(_303, i.world_tangent.xyz)));\n    float3 _354 = normalize(((_327 * m.x) + ((cross(_303, _327) * i.world_tangent.w) * m.y)) + (_303 * m.z));\n    float3 _357;\n    if (i.front_facing)\n    {\n        _357 = _354;\n    }\n    else\n    {\n        _357 = -_354;\n    }\n    return _357;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _421_fa_env_horizon.w);\n    float param = _421_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4450 = fa_tex_fix(param_2, param_3);\n    float4 _6251 = base_t;\n    _6251.x = _4450.x;\n    _6251.y = _4450.y;\n    _6251.z = _4450.z;\n    base_t = _6251;\n    float4 _4464 = (_6251 * _421_fa_base_color) * i.vertex_color;\n    float3 _6067 = i.world_normal;\n    if (_421_fa_maps.z > 0.5f)\n    {\n        float param_4 = _421_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _421_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4498 = fa_tex_fix(param_6, param_7);\n        float3 _4501 = (_4498 * 2.0f) - 1.0f.xxx;\n        float2 _4506 = _4501.xy * _421_fa_maps.x;\n        float3 _6259 = _4501;\n        _6259.x = _4506.x;\n        _6259.y = _4506.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6259;\n        _6067 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _421_fa_env_horizon.w);\n    float param_10 = _421_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4536 = fa_tex_fix(param_12, param_13);\n    float4 _6262 = mrt;\n    _6262.x = _4536.x;\n    _6262.y = _4536.y;\n    _6262.z = _4536.z;\n    mrt = _6262;\n    float4 _4566 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _421_fa_env_horizon.w);\n    float param_14 = _421_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4566.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4577 = fa_tex_fix(param_16, param_17);\n    float param_18 = _421_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _421_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4609 = fa_tex_fix(param_20, param_21);\n    float _6072 = _421_fa_layers_a.x;\n    float _6073 = _421_fa_layers_a.y;\n    float _6076 = _421_fa_layers_a.z;\n    float _6075 = _421_fa_layers_b.w;\n    float _6078 = _421_fa_layers_c.x;\n    if (_421_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_421_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6072 *= _4577.y;\n            _6073 *= _4577.z;\n            _6075 *= _4566.w;\n        }\n        if (_421_fa_layers_c.z > 1.5f)\n        {\n            _6076 *= mrt.x;\n            _6078 *= mrt.w;\n        }\n    }\n    Surface _6105 = { _4464.xyz, _4464.w, _6067, clamp(_421_fa_pbr.x * _4536.z, 0.0f, 1.0f), clamp(_421_fa_pbr.y * _4536.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_421_fa_maps.y * (_4577.x - 1.0f)), _421_fa_emissive.xyz + (_421_fa_model_emissive.xyz * _4609), _6072, _6073, _421_fa_layers_b.xyz, _6075, _6076, _421_fa_layers_a.w, _6078, _421_fa_layers_c.y, _421_fa_layers_d.xyz, _421_fa_tr_a.x, _421_fa_tr_a.y, _421_fa_tr_b.xyz, _421_fa_tr_a.z };\n    return _6105;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1580 = rect.zw - rect.xy;\n    float2 _1584 = _1580 * atlas;\n    float2 _1588 = ddx * _1584;\n    float2 _1592 = ddy * _1584;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1580), clamp(0.5f * log2(max(max(dot(_1588, _1588), dot(_1592, _1592)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1625 = _421_fa_counts.y < 0.5f;\n    bool _1632;\n    if (!_1625)\n    {\n        _1632 = _421_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1632 = _1625;\n    }\n    if (_1632)\n    {\n        return;\n    }\n    float3 _1638 = ddx(world_pos);\n    float3 _1641 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1645 = fa_cluster_texel(param);\n    int _1649 = int(_1645.w);\n    if (_1649 < 1)\n    {\n        return;\n    }\n    int _1659 = int(_421_fa_counts.y + 0.5f);\n    int param_1 = _1659;\n    float4 _1663 = fa_light_texel(param_1);\n    float2 _1666 = _1663.yz;\n    int _1670 = int(_1663.w);\n    int param_2 = _1659 + 1;\n    float4 _1675 = fa_light_texel(param_2);\n    float _1676 = _1675.x;\n    int _1682 = int(_421_fa_counts.w + 0.5f) - 1;\n    int _1686 = int(_1645.z);\n    float3 _1951;\n    for (int k = 0; k < _1649; k++)\n    {\n        int _1699 = _1686 + k;\n        int param_3 = _1670 + (_1699 >> 2);\n        int _1716 = (_1659 + 2) + (int(fa_light_texel(param_3)[_1699 & 3]) * 7);\n        int param_4 = _1716 + 6;\n        float4 _1721 = fa_light_texel(param_4);\n        if (((int(_1721.w + 0.5f) >> _1682) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1716;\n        float4 _1736 = fa_light_texel(param_5);\n        int param_6 = _1716 + 1;\n        float4 _1741 = fa_light_texel(param_6);\n        int param_7 = _1716 + 2;\n        float4 _1746 = fa_light_texel(param_7);\n        float3 _1749 = _1736.xyz;\n        float _1754 = dot(_1749, world_pos) + _1736.w;\n        float3 _1756 = _1741.xyz;\n        float _1761 = dot(_1756, world_pos) + _1741.w;\n        float3 _1763 = _1746.xyz;\n        float _1768 = dot(_1763, world_pos) + _1746.w;\n        bool _1773 = abs(_1754) > 0.5f;\n        bool _1781;\n        if (!_1773)\n        {\n            _1781 = abs(_1761) > 0.5f;\n        }\n        else\n        {\n            _1781 = _1773;\n        }\n        bool _1789;\n        if (!_1781)\n        {\n            _1789 = abs(_1768) > 0.5f;\n        }\n        else\n        {\n            _1789 = _1781;\n        }\n        if (_1789)\n        {\n            continue;\n        }\n        float _1804 = clamp(dot(geo_normal, normalize(_1763)) * _1721.z, 0.0f, 1.0f);\n        if (_1804 <= 0.0f)\n        {\n            continue;\n        }\n        float _1824 = (clamp((0.5f - abs(_1768)) * 10.0f, 0.0f, 1.0f) * _1804) * _1721.x;\n        float2 _1832 = float2(_1754 + 0.5f, 0.5f - _1761);\n        float2 _1842 = float2(dot(_1749, _1638), dot(_1756, _1638));\n        float2 _1852 = float2(dot(_1749, _1641), dot(_1756, _1641));\n        int param_8 = _1716 + 5;\n        float4 _1857 = fa_light_texel(param_8);\n        int param_9 = _1716 + 3;\n        float4 _1862 = fa_light_texel(param_9);\n        int param_10 = _1716 + 4;\n        float4 _1867 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1857.xyz;\n        bool _1877 = _1862.z > _1862.x;\n        if (_1877)\n        {\n            float4 param_11 = _1862;\n            float2 param_12 = _1832;\n            float2 param_13 = _1666;\n            float2 param_14 = _1842;\n            float2 param_15 = _1852;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1676 > 0.5f) && (_1676 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1903 = fa_dc_to_linear(param_16);\n                float4 _6155 = tx;\n                _6155.x = _1903.x;\n                _6155.y = _1903.y;\n                _6155.z = _1903.z;\n                tx = _6155;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1824 * tex_a) * _1857.w, 0.0f, 1.0f).xxx);\n        if (_1867.z > _1867.x)\n        {\n            float4 param_17 = _1867;\n            float2 param_18 = _1832;\n            float2 param_19 = _1666;\n            float2 param_20 = _1842;\n            float2 param_21 = _1852;\n            float4 _1947 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1676 > 1.5f)\n            {\n                float3 param_22 = _1947.xyz;\n                float3 _1957 = fa_dc_to_srgb(param_22);\n                _1951 = _1957;\n            }\n            else\n            {\n                _1951 = _1947.xyz;\n            }\n            float3 _1966 = (_1951 * 2.0f) - 1.0f.xxx;\n            float2 _1971 = _1966.xy * _1721.y;\n            float3 _1993 = (normalize(_1749) * _1971.x) + (normalize(_1756) * _1971.y);\n            float3 _1996 = normalize(normal);\n            normal = normalize(lerp(_1996, normalize((_1996 * max(_1966.z, 0.0500000007450580596923828125f)) + (_1993 - (_1996 * dot(_1996, _1993)))), clamp(_1824 * (_1877 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3727_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3727_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_421_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3668 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3668;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3777 = (1.0f - _421_fa_rpa_tile.w) - _421_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3783 = _421_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3777 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3783)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _421_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3777;\n            }\n        }\n        else\n        {\n            amb = _421_fa_ambient.xyz * _3777;\n        }\n    }\n    bool _3835 = _421_fa_rpa_tile.w > 0.0f;\n    if (_3835)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _421_fa_rpa_tile.xy;\n            float param_4 = _421_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _421_fa_rpa_tile.w);\n        }\n    }\n    bool _3866 = _421_fa_rpb_tile.w > 0.0f;\n    if (_3866)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _421_fa_rpb_tile.xy;\n            float param_7 = _421_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _421_fa_rpb_tile.w);\n        }\n    }\n    if ((_3783 || _3835) || _3866)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3688 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3691 = _3688.x;\n    float _3693 = _3688.z;\n    float2 e = float2(_3691, _3693);\n    if (_3688.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3693)) * ((_3691 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3691)) * ((_3693 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _4723 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _4728 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _4733 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _4738 = fa_light_texel(param_3);\n    bool _4741 = _4738.z < 0.5f;\n    bool _4749;\n    if (!_4741)\n    {\n        _4749 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _4749 = _4741;\n    }\n    if (_4749)\n    {\n        return 0.0f.xxx;\n    }\n    float _4756 = max(_4723.w, 9.9999997473787516355514526367188e-05f);\n    float3 _4759 = _4728.xyz;\n    float3 _4763 = _4723.xyz;\n    float3 _4767 = (fa_world_pos - _4763) / _4756.xxx;\n    float3 _4776 = min(_4767 + 0.5f.xxx, (_4759 - 0.5f.xxx) - _4767);\n    float _4785 = min(_4776.x, min(_4776.y, _4776.z));\n    if (!(_4785 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4800 = _4759 - 1.0f.xxx;\n    float3 _4801 = clamp(_4767, 0.0f.xxx, _4800);\n    float3 _4809 = min(floor(_4801), max(_4759 - 2.0f.xxx, 0.0f.xxx));\n    float3 _4813 = _4801 - _4809;\n    float3 _4825 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _4756));\n    int _4830 = int(_4733.y + 0.5f);\n    float _4835 = 0.3257350027561187744140625f * n.y;\n    float _4839 = 0.3257350027561187744140625f * n.z;\n    float _4843 = 0.3257350027561187744140625f * n.x;\n    float _4850 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _4857 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _4866 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _4873 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _4886 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _4893 = 8 + int(_4738.w);\n    float _4920;\n    float _4933;\n    float _4947;\n    for (int k = 0; k < _4893; k++)\n    {\n        float _4906 = float(k & 1);\n        float _4910 = float((k >> 1) & 1);\n        float _4914 = float((k >> 2) & 1);\n        if (_4906 > 0.5f)\n        {\n            _4920 = _4813.x;\n        }\n        else\n        {\n            _4920 = 1.0f - _4813.x;\n        }\n        if (_4910 > 0.5f)\n        {\n            _4933 = _4813.y;\n        }\n        else\n        {\n            _4933 = 1.0f - _4813.y;\n        }\n        if (_4914 > 0.5f)\n        {\n            _4947 = _4813.z;\n        }\n        else\n        {\n            _4947 = 1.0f - _4813.z;\n        }\n        float _4957 = (_4920 * _4933) * _4947;\n        if (!(_4957 > 0.0f))\n        {\n            continue;\n        }\n        float3 _4970 = min(_4809 + float3(_4906, _4910, _4914), _4800);\n        int _4990 = int(((_4733.x + _4970.x) + (_4728.x * (_4970.y + (_4728.y * _4970.z)))) + 0.5f);\n        float2 _5005 = float2(float(_4990 % _4830) * 10.0f, 1024.0f + (float(_4990 / _4830) * 11.0f));\n        float2 param_4 = _5005 + float2(9.5f, 10.5f);\n        float4 _5013 = fa_gi_fetch(param_4);\n        bool _5016 = _5013.y < 0.5f;\n        bool _5025;\n        if (!_5016)\n        {\n            _5025 = _5013.x > _4738.y;\n        }\n        else\n        {\n            _5025 = _5016;\n        }\n        if (_5025)\n        {\n            continue;\n        }\n        float3 _5037 = _4825 - (_4763 + (_4970 * _4756));\n        float _5040 = length(_5037);\n        float3 _5046 = _5037 / max(_5040, 9.9999997473787516355514526367188e-05f).xxx;\n        float _5056 = max(9.9999997473787516355514526367188e-05f, (dot(-_5046, n) + 1.0f) * 0.5f);\n        float w = _4957 * (_5056 * _5056);\n        float3 param_5 = _5046;\n        float2 param_6 = (_5005 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _5076 = fa_gi_fetch(param_6);\n        float _5083 = _5040 / max(_4733.z, 9.9999997473787516355514526367188e-05f);\n        float _5086 = _5076.x;\n        if (_5083 > _5086)\n        {\n            float _5099 = max(_5076.y - (_5086 * _5086), 0.0f);\n            float _5104 = _5083 - _5086;\n            float _5113 = _5099 / max(_5099 + (_5104 * _5104), 9.9999999600419720025001879548654e-13f);\n            w *= ((_5113 * _5113) * _5113);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _5005 + float2(0.5f, 10.5f);\n        float2 param_8 = _5005 + float2(1.5f, 10.5f);\n        float2 param_9 = _5005 + float2(2.5f, 10.5f);\n        float2 param_10 = _5005 + float2(3.5f, 10.5f);\n        float2 param_11 = _5005 + float2(4.5f, 10.5f);\n        float2 param_12 = _5005 + float2(5.5f, 10.5f);\n        float2 param_13 = _5005 + float2(6.5f, 10.5f);\n        float2 param_14 = _5005 + float2(7.5f, 10.5f);\n        float2 param_15 = _5005 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _4835)) + (fa_gi_fetch(param_9).xyz * _4839)) + (fa_gi_fetch(param_10).xyz * _4843)) + (fa_gi_fetch(param_11).xyz * _4850)) + (fa_gi_fetch(param_12).xyz * _4857)) + (fa_gi_fetch(param_13).xyz * _4866)) + (fa_gi_fetch(param_14).xyz * _4873)) + (fa_gi_fetch(param_15).xyz * _4886)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_4785 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _5241;\n    if (_421_fa_gi.z > 0.5f)\n    {\n        _5241 = _4738.x;\n    }\n    else\n    {\n        _5241 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_4733.w * _5241);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _5265 = normalize(_421_fa_camera_pos.xyz - fa_world_pos);\n    int _5270 = int(_421_fa_gi.x + 0.5f);\n    int _5275 = int(_421_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _5275) && (k < 8); k++)\n    {\n        int param = _5270 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _5265;\n        float3 _5300 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5305 = param_3 * left;\n        acc += (_5300 * _5305);\n        left -= _5305;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_421_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _5334 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5334;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_421_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _421_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_421_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_421_fa_cl_info.x) + int(_421_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_421_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4175;\n    if (fa_lm.z > 0.5f)\n    {\n        _4175 = 0.0f;\n    }\n    else\n    {\n        _4175 = 1.0f - clamp(_421_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4186 = _4175 < 1.0f;\n    bool _4192;\n    if (_4186)\n    {\n        int param = li;\n        _4192 = fa_light_baked(param);\n    }\n    else\n    {\n        _4192 = _4186;\n    }\n    return _4192 ? _4175 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _599 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _612 = (c - (ru * hx)) - p;\n        float3 _618 = ru * (2.0f * hx);\n        float _624 = max(dot(_618, _618), 9.9999999392252902907785028219223e-09f);\n        float _628 = dot(_612, _618);\n        float t = clamp((-_628) / _624, 0.0f, 1.0f);\n        if (_599)\n        {\n            float _643 = dot(r, _618);\n            float _649 = _624 - (_643 * _643);\n            if (abs(_649) > (9.9999997473787516355514526367188e-06f * _624))\n            {\n                t = clamp(((dot(r, _612) * _643) - _628) / _649, 0.0f, 1.0f);\n            }\n        }\n        return (p + _612) + (_618 * t);\n    }\n    float3 q = p;\n    float _681 = dot(r, axis);\n    bool _689;\n    if (_599)\n    {\n        _689 = abs(_681) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _689 = _599;\n    }\n    if (_689)\n    {\n        float _699 = dot(c - p, axis) / _681;\n        if (_699 > 0.0f)\n        {\n            q = p + (r * _699);\n        }\n    }\n    float3 _712 = q - c;\n    float2 xy = float2(dot(_712, ru), dot(_712, uu));\n    if (shape > 0.5f)\n    {\n        float _727 = length(xy);\n        if (_727 > hx)\n        {\n            xy *= (hx / _727);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _480_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _480_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _519 = dot(d, right);\n    float _523 = dot(d, up);\n    float _534;\n    if (((_519 * _519) + (_523 * _523)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _534 = atan2(_523, _519) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _534 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_534 - floor(_534)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _369 = abs(d);\n    float _371 = _369.x;\n    float _373 = _369.y;\n    bool _374 = _371 >= _373;\n    bool _382;\n    if (_374)\n    {\n        _382 = _371 >= _369.z;\n    }\n    else\n    {\n        _382 = _374;\n    }\n    int _383;\n    if (_382)\n    {\n        _383 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _398;\n        if (_373 >= _369.z)\n        {\n            _398 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _398 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _383 = _398;\n    }\n    return _383;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _765 = fa_light_base(param);\n    bool _769 = _421_fa_ambient.w > 4.5f;\n    int param_1 = _765;\n    float4 _773 = fa_light_texel(param_1);\n    int param_2 = _765 + 1;\n    float4 _778 = fa_light_texel(param_2);\n    float _781 = _778.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _793 = _769 && (_781 > 2.5f);\n    fa_light_is_area = _793;\n    bool _795 = _781 < 0.5f;\n    float3 l;\n    if (_795)\n    {\n        l = normalize(_773.xyz);\n        if (_769)\n        {\n            int param_3 = _765 + 6;\n            float4 _809 = fa_light_texel(param_3);\n            if (_809.z > 0.5f)\n            {\n                int param_4 = _765 + 4;\n                float4 _819 = fa_light_texel(param_4);\n                int param_5 = _765 + 5;\n                float4 _824 = fa_light_texel(param_5);\n                float2 param_6 = _809.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _819.xyz) * _819.w, (-dot(world_pos, _824.xyz)) * _824.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _854 = _773.xyz;\n        float3 _856 = _854 - world_pos;\n        float3 to_light = _856;\n        float _859 = length(_856);\n        float reach = _859;\n        bool front = true;\n        if (_793)\n        {\n            int param_8 = _765 + 7;\n            reach = max(_859 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _765 + 4;\n            float4 _883 = fa_light_texel(param_9);\n            int param_10 = _765 + 5;\n            float4 _888 = fa_light_texel(param_10);\n            int param_11 = _765 + 6;\n            float4 _893 = fa_light_texel(param_11);\n            float _894 = _893.w;\n            int param_12 = _765 + 2;\n            float3 _901 = normalize(fa_light_texel(param_12).xyz);\n            bool _903 = _894 > 1.5f;\n            bool _911;\n            if (!_903)\n            {\n                _911 = dot(_901, to_light) < 0.0f;\n            }\n            else\n            {\n                _911 = _903;\n            }\n            front = _911;\n            float3 r = 0.0f.xxx;\n            float3 _920 = _421_fa_camera_pos.xyz - world_pos;\n            bool _924 = dot(n, n) > 0.5f;\n            bool _932;\n            if (_924)\n            {\n                _932 = dot(_920, _920) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _932 = _924;\n            }\n            if (_932)\n            {\n                r = reflect(-normalize(_920), normalize(n));\n            }\n            float3 param_13 = _854;\n            float3 param_14 = _901;\n            float3 param_15 = _883.xyz;\n            float3 param_16 = _888.xyz;\n            float param_17 = _883.w;\n            float param_18 = _888.w;\n            float param_19 = _894;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _968 = length(to_light);\n        dist = _968;\n        l = to_light / max(_968, 9.9999997473787516355514526367188e-05f).xxx;\n        float _982 = reach / max(_773.w, 0.001000000047497451305389404296875f);\n        float _988 = clamp(1.0f - (_982 * _982), 0.0f, 1.0f);\n        float _990;\n        if (front)\n        {\n            _990 = _988 * _988;\n        }\n        else\n        {\n            _990 = 0.0f;\n        }\n        atten = _990;\n        bool _1001 = _781 < 2.5f;\n        if ((_781 > 1.5f) && _1001)\n        {\n            int param_22 = _765 + 2;\n            float4 _1009 = fa_light_texel(param_22);\n            float _1019 = _1009.w;\n            int param_23 = _765 + 3;\n            float4 _1024 = fa_light_texel(param_23);\n            float _1025 = _1024.x;\n            float cos_inner = _1025;\n            if (_1025 > 1.5f)\n            {\n                cos_inner = lerp(_1019, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1019, cos_inner, dot(-l, normalize(_1009.xyz)));\n        }\n        if (_769 && (_781 < 1.5f))\n        {\n            int param_24 = _765 + 6;\n            float4 _1049 = fa_light_texel(param_24);\n            if (_1049.z > 0.5f)\n            {\n                float3 _1057 = -to_light;\n                int param_25 = _765 + 4;\n                int param_26 = _765 + 5;\n                float3 _1071 = fa_light_texel(param_25).xyz;\n                float3 _1075 = fa_light_texel(param_26).xyz;\n                float3 _1084 = float3(dot(_1057, _1071), dot(_1057, _1075), dot(_1057, cross(_1071, _1075)));\n                float3 param_27 = _1084;\n                int _1088 = fa_cube_face(param_27);\n                int param_28 = _1088;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1115 = float2(dot(_1084, cross(param_29, param_30)), dot(_1084, param_30)) / max(dot(_1084, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1119 = _1088 / 3;\n                float2 param_31 = _1049.xy + (float2(float(_1088 - (_1119 * 3)), float(_1119)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1115.x), 0.5f - (0.5f * _1115.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _765 + 7;\n            float4 _1149 = fa_light_texel(param_33);\n            if (_1149.z > 0.5f)\n            {\n                int param_34 = _765 + 2;\n                int param_35 = _765 + 4;\n                int param_36 = _765 + 5;\n                float2 param_37 = _1149.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_769 && _1001)\n            {\n                int param_42 = _765 + 6;\n                float4 _1196 = fa_light_texel(param_42);\n                int param_43 = _765 + 7;\n                float4 _1201 = fa_light_texel(param_43);\n                bool _1204 = _1196.z > 0.5f;\n                bool _1211;\n                if (!_1204)\n                {\n                    _1211 = _1201.z > 0.5f;\n                }\n                else\n                {\n                    _1211 = _1204;\n                }\n                if (_1211)\n                {\n                    int param_44 = _765 + 2;\n                    float4 _1218 = fa_light_texel(param_44);\n                    float3 _1222 = normalize(_1218.xyz);\n                    int param_45 = _765 + 4;\n                    float4 _1227 = fa_light_texel(param_45);\n                    int param_46 = _765 + 5;\n                    float4 _1232 = fa_light_texel(param_46);\n                    if (_1204)\n                    {\n                        float3 _1240 = -to_light;\n                        float _1247 = _1218.w;\n                        float _1263 = 0.5f / max(dot(_1240, _1222) * (sqrt(max(1.0f - (_1247 * _1247), 0.0f)) / max(_1247, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1196.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1240, _1227.xyz) * _1263), 0.5f - (dot(_1240, _1232.xyz) * _1263));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1201.z > 0.5f)\n                    {\n                        float2 param_49 = _1201.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1222;\n                        float3 param_52 = _1227.xyz;\n                        float3 param_53 = _1232.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6021 = _778.xyz * atten;\n    if (_769)\n    {\n        _6021 *= fa_light_tint;\n    }\n    int _1331;\n    if (_795)\n    {\n        _1331 = 0;\n    }\n    else\n    {\n        _1331 = ((_781 > 1.5f) && (_781 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _6032 = { l, _6021, atten, 1.0f, dist, _1331 };\n    return _6032;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2120 = fa_shadow_depth(param, param_1);\n    float _2124;\n    if (conv.x < 0.5f)\n    {\n        _2124 = _2120;\n    }\n    else\n    {\n        _2124 = (conv.y * conv.z) / (conv.z - (_2120 * (conv.z - conv.y)));\n    }\n    return _2124;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2170 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2176 = float2(cos(_2170), sin(_2170));\n    float2 dir = _2176;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2185;\n        if (k < 0.0f)\n        {\n            _2185 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2185 = k;\n        }\n        float _2204 = clamp((_2185 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2223 = sqrt((float(i) + 0.5f) * 0.0625f) * _2204;\n            float2 param_3 = uv + (dir * (_2073_fa_shadow_bias.zw * _2223));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2237 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2237 < (zr - (_2223 * plane)))\n            {\n                sum += _2237;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2265 = sum / cnt;\n        float _2275;\n        if (k < 0.0f)\n        {\n            _2275 = (-k) / max(_2265, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2275 = k;\n        }\n        radius = clamp(((max(zr - _2265, 0.0f) * unit) * _2275) / texel_m, 1.5f, 16.0f);\n        dir = _2176;\n    }\n    float lit = 0.0f;\n    int _2301 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2301; i_1++)\n    {\n        float _2320 = sqrt((float(i_1) + 0.5f) / float(_2301)) * radius;\n        float2 param_7 = uv + (dir * (_2073_fa_shadow_bias.zw * _2320));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2320 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2301);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2525 = _421_fa_pbr.z < 0.5f;\n    bool _2532;\n    if (!_2525)\n    {\n        _2532 = _2073_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2532 = _2525;\n    }\n    if (_2532)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2073_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2545 = fa_light_texel(param);\n    float _2546 = _2545.x;\n    if (_2546 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2555 = int(_2546 + 0.5f);\n    int param_1 = _2555;\n    float4 _2559 = fa_light_texel(param_1);\n    int param_2 = _2555 + 1;\n    float4 _2564 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2567 = _2559.y;\n    if (_2567 > 0.0f)\n    {\n        float _2584 = 1.0f - smoothstep(0.75f * _2567, _2567, length(world - _2073_fa_shadow_eye.xyz));\n        fade = _2584;\n        if (_2584 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2559.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2608 = (_2555 + 2) + (face * 6);\n    int param_4 = _2608;\n    int param_5 = _2608 + 1;\n    int param_6 = _2608 + 3;\n    float4 _2622 = fa_light_texel(param_6);\n    int param_7 = _2608 + 4;\n    float4 _2627 = fa_light_texel(param_7);\n    int param_8 = _2608 + 5;\n    float4 _2632 = fa_light_texel(param_8);\n    float _2644 = _2632.x * max(dot(_2622, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2649 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2672 = clamp(dot(n, _2622.xyz), -1.0f, 1.0f);\n    float _2691 = min(sqrt(1.0f - (_2672 * _2672)) / max(abs(dot(n, world - lpos)) / max(dot(_2622, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2694 = _2564.y;\n    float _2696;\n    if (_2694 > 0.0f)\n    {\n        _2696 = _2694;\n    }\n    else\n    {\n        _2696 = 1.5f * _2644;\n    }\n    float4 _2716 = float4(world + (n * (_2696 * sqrt(1.0f - (_2649 * _2649)))), 1.0f);\n    float _2720 = dot(_2622, _2716);\n    float _2723 = _2632.y;\n    if (_2720 < _2723)\n    {\n        return 1.0f;\n    }\n    float2 _2738 = float2(dot(fa_light_texel(param_4), _2716), dot(fa_light_texel(param_5), _2716)) / _2720.xx;\n    float _2740 = _2738.x;\n    bool _2743 = _2740 < _2627.x;\n    bool _2752;\n    if (!_2743)\n    {\n        _2752 = _2740 > _2627.z;\n    }\n    else\n    {\n        _2752 = _2743;\n    }\n    bool _2761;\n    if (!_2752)\n    {\n        _2761 = _2738.y < _2627.y;\n    }\n    else\n    {\n        _2761 = _2752;\n    }\n    bool _2770;\n    if (!_2761)\n    {\n        _2770 = _2738.y > _2627.w;\n    }\n    else\n    {\n        _2770 = _2761;\n    }\n    if (_2770)\n    {\n        return 1.0f;\n    }\n    float _2776 = _2564.x;\n    float _2778;\n    if (_2776 > 0.0f)\n    {\n        _2778 = _2776;\n    }\n    else\n    {\n        _2778 = 1.5f * _2644;\n    }\n    float2 param_9 = _2738;\n    float4 param_10 = _2627;\n    float param_11 = _2720 - (_2778 * (1.0f + (0.5f * _2691)));\n    float param_12 = _2644;\n    float param_13 = 1.0f;\n    float param_14 = _2632.z * 0.25f;\n    float param_15 = (_2644 * min(_2691, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2723, _2632.z);\n    int param_17 = int(_2559.z + 0.5f);\n    float param_18 = _2559.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _3290 = _421_fa_ct_b.w > 0.5f;\n    bool _3296;\n    if (_3290)\n    {\n        _3296 = _421_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3296 = _3290;\n    }\n    bool _3302;\n    if (_3296)\n    {\n        _3302 = _2073_fa_shadow_lcfg.x > 0.5f;\n    }\n    else\n    {\n        _3302 = _3296;\n    }\n    if (_3302)\n    {\n        int param = (int(_2073_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n        float4 _3314 = fa_light_texel(param);\n        float _3315 = _3314.z;\n        if (_3315 > 0.5f)\n        {\n            float _3328 = dot(_421_fa_ct_fwd.xyz, world) + _421_fa_ct_fwd.w;\n            float _3331 = fwidth(_3328);\n            float _3335 = min(1.5f * _3331, 0.100000001490116119384765625f * _3328);\n            float4 _3341 = float4(world, 1.0f);\n            float _3346 = dot(_421_fa_ct_vpw, _3341);\n            if (_3346 > 9.9999997473787516355514526367188e-05f)\n            {\n                float2 _3363 = float2(dot(_421_fa_ct_vpx, _3341), dot(_421_fa_ct_vpy, _3341)) / _3346.xx;\n                float _3368 = (_3363.x * 0.5f) + 0.5f;\n                float _3372;\n                if (_421_fa_ct_a.y > 0.5f)\n                {\n                    _3372 = (_3363.y * 0.5f) + 0.5f;\n                }\n                else\n                {\n                    _3372 = 0.5f - (_3363.y * 0.5f);\n                }\n                bool _3388 = _3368 >= 0.0f;\n                bool _3394;\n                if (_3388)\n                {\n                    _3394 = _3368 < 1.0f;\n                }\n                else\n                {\n                    _3394 = _3388;\n                }\n                bool _3400;\n                if (_3394)\n                {\n                    _3400 = _3372 >= 0.0f;\n                }\n                else\n                {\n                    _3400 = _3394;\n                }\n                bool _3406;\n                if (_3400)\n                {\n                    _3406 = _3372 < 1.0f;\n                }\n                else\n                {\n                    _3406 = _3400;\n                }\n                if (_3406)\n                {\n                    int2 _3423 = int2(_421_fa_ct_a.zw) - int2(1, 1);\n                    int2 _3424 = clamp(int2(float2(_3368, _3372) * _421_fa_ct_a.zw), int2(0, 0), _3423);\n                    int2 _3436;\n                    int2 _3442;\n                    int2 _3449;\n                    float _3500;\n                    float _3521;\n                    for (int k = 0; k < 5; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3436 = int2(0, 0);\n                        }\n                        else\n                        {\n                            if (k == 1)\n                            {\n                                _3442 = int2(1, 0);\n                            }\n                            else\n                            {\n                                if (k == 2)\n                                {\n                                    _3449 = int2(-1, 0);\n                                }\n                                else\n                                {\n                                    bool2 _3460 = (k == 3).xx;\n                                    _3449 = int2(_3460.x ? int2(0, 1).x : int2(0, -1).x, _3460.y ? int2(0, 1).y : int2(0, -1).y);\n                                }\n                                _3442 = _3449;\n                            }\n                            _3436 = _3442;\n                        }\n                        float4 _3477 = fa_screen_tex.Load(int3(clamp(_3424 + _3436, int2(0, 0), _3423), 0));\n                        bool _3480 = _3477.w > 0.5f;\n                        bool _3494;\n                        if (_3480)\n                        {\n                            _3494 = abs(_3328 - _3477.x) <= (((0.00200000009499490261077880859375f * _3328) + 0.00999999977648258209228515625f) + _3335);\n                        }\n                        else\n                        {\n                            _3494 = _3480;\n                        }\n                        if (_3494)\n                        {\n                            if (_3315 < 1.5f)\n                            {\n                                _3500 = 1.0f;\n                            }\n                            else\n                            {\n                                _3500 = (_3315 < 2.5f) ? 256.0f : 65536.0f;\n                            }\n                            float _3517 = mod(floor(_3477.z / _3500), 256.0f) * 0.0039215688593685626983642578125f;\n                            if (_421_fa_ct_b.z > 0.5f)\n                            {\n                                int param_1 = li;\n                                float3 param_2 = lpos;\n                                float3 param_3 = world;\n                                float3 param_4 = n;\n                                float3 param_5 = l;\n                                _3521 = min(_3517, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                            }\n                            else\n                            {\n                                _3521 = _3517;\n                            }\n                            return _3521;\n                        }\n                    }\n                }\n            }\n            float _3546;\n            if (_421_fa_ct_b.z > 0.5f)\n            {\n                int param_6 = li;\n                float3 param_7 = lpos;\n                float3 param_8 = world;\n                float3 param_9 = n;\n                float3 param_10 = l;\n                _3546 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3546 = 1.0f;\n            }\n            return _3546;\n        }\n    }\n    int param_11 = li;\n    float3 param_12 = lpos;\n    float3 param_13 = world;\n    float3 param_14 = n;\n    float3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2063;\n    if (i == 0)\n    {\n        _2063 = _2073_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2079;\n        if (i == 1)\n        {\n            _2079 = _2073_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2087;\n            if (i == 2)\n            {\n                _2087 = _2073_fa_shadow_split.z;\n            }\n            else\n            {\n                _2087 = _2073_fa_shadow_split.w;\n            }\n            _2079 = _2087;\n        }\n        _2063 = _2079;\n    }\n    return _2063;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2366 = max(_2073_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2371 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2377 = sqrt(1.0f - (_2371 * _2371));\n    float _2385 = min(_2377 / max(_2371, 0.20000000298023223876953125f), 4.0f);\n    float _2390;\n    if (_2073_fa_shadow_bias.y > 0.0f)\n    {\n        _2390 = _2073_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2390 = 1.5f * _2073_fa_shadow_info[ci].x;\n    }\n    float4 _2415 = mul(float4(world + (n * (_2390 * _2377)), 1.0f), _2073_fa_shadow_mat[ci]);\n    float _2422 = _2415.x;\n    bool _2425 = _2422 < _2073_fa_shadow_rect[ci].x;\n    bool _2434;\n    if (!_2425)\n    {\n        _2434 = _2422 > _2073_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2434 = _2425;\n    }\n    bool _2443;\n    if (!_2434)\n    {\n        _2443 = _2415.y < _2073_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2443 = _2434;\n    }\n    bool _2452;\n    if (!_2443)\n    {\n        _2452 = _2415.y > _2073_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2452 = _2443;\n    }\n    bool _2459;\n    if (!_2452)\n    {\n        _2459 = _2415.z > 1.0f;\n    }\n    else\n    {\n        _2459 = _2452;\n    }\n    if (_2459)\n    {\n        return -1.0f;\n    }\n    float _2467;\n    if (_2073_fa_shadow_bias.x > 0.0f)\n    {\n        _2467 = _2073_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2467 = 1.5f * _2073_fa_shadow_info[ci].x;\n    }\n    float2 param = _2415.xy;\n    float4 param_1 = _2073_fa_shadow_rect[ci];\n    float param_2 = _2415.z - ((_2467 * (1.0f + (0.5f * _2385))) / _2366);\n    float param_3 = _2073_fa_shadow_info[ci].x;\n    float param_4 = _2366;\n    float param_5 = _2366 * 0.25f;\n    float param_6 = ((_2073_fa_shadow_info[ci].x * min(_2385, 3.0f)) * 0.5f) / _2366;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2073_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2073_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_421_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2845 = int(_2073_fa_shadow_cfg.x + 0.5f);\n    if (_2845 < 1)\n    {\n        return 1.0f;\n    }\n    float _2860 = dot(world - _2073_fa_shadow_eye.xyz, _2073_fa_shadow_fwd.xyz);\n    int param = _2845 - 1;\n    if (_2860 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2872 = _2845 > 1;\n    bool _2879;\n    if (_2872)\n    {\n        _2879 = _2860 > _2073_fa_shadow_split.x;\n    }\n    else\n    {\n        _2879 = _2872;\n    }\n    if (_2879)\n    {\n        ci = 1;\n    }\n    bool _2883 = _2845 > 2;\n    bool _2890;\n    if (_2883)\n    {\n        _2890 = _2860 > _2073_fa_shadow_split.y;\n    }\n    else\n    {\n        _2890 = _2883;\n    }\n    if (_2890)\n    {\n        ci = 2;\n    }\n    bool _2894 = _2845 > 3;\n    bool _2901;\n    if (_2894)\n    {\n        _2901 = _2860 > _2073_fa_shadow_split.z;\n    }\n    else\n    {\n        _2901 = _2894;\n    }\n    if (_2901)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _2912 = min(_2845, 4);\n    float _2953;\n    for (int c = ci; c < _2912; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2932 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _2932;\n            break;\n        }\n        if (_2932 < 0.0f)\n        {\n            continue;\n        }\n        s = _2932;\n        ci = c;\n        if (_2073_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2953 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2953 = _2073_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _2972 = _2073_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2953, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_2860 - (fa_shadow_split_at(param_7) - _2972)) / _2972, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3004;\n        if ((ci + 1) < _2845)\n        {\n            _3004 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3004 = 1.0f;\n        }\n        s = lerp(s, _3004, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    bool _3109 = _421_fa_ct_b.y > 0.5f;\n    bool _3115;\n    if (_3109)\n    {\n        _3115 = _421_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3115 = _3109;\n    }\n    if (_3115)\n    {\n        float _3129 = dot(_421_fa_ct_fwd.xyz, fa_world_pos) + _421_fa_ct_fwd.w;\n        float _3132 = fwidth(_3129);\n        float4 _3142 = float4(fa_world_pos, 1.0f);\n        float _3148 = dot(_421_fa_ct_vpw, _3142);\n        if (_3148 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _3167 = float2(dot(_421_fa_ct_vpx, _3142), dot(_421_fa_ct_vpy, _3142)) / _3148.xx;\n            float _3172 = (_3167.x * 0.5f) + 0.5f;\n            float _3176;\n            if (_421_fa_ct_a.y > 0.5f)\n            {\n                _3176 = (_3167.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _3176 = 0.5f - (_3167.y * 0.5f);\n            }\n            bool _3192 = _3172 >= 0.0f;\n            bool _3198;\n            if (_3192)\n            {\n                _3198 = _3172 < 1.0f;\n            }\n            else\n            {\n                _3198 = _3192;\n            }\n            bool _3204;\n            if (_3198)\n            {\n                _3204 = _3176 >= 0.0f;\n            }\n            else\n            {\n                _3204 = _3198;\n            }\n            bool _3210;\n            if (_3204)\n            {\n                _3210 = _3176 < 1.0f;\n            }\n            else\n            {\n                _3210 = _3204;\n            }\n            if (_3210)\n            {\n                float4 _3236 = fa_screen_tex.Load(int3(clamp(int2(float2(_3172, _3176) * _421_fa_ct_a.zw), int2(0, 0), int2(_421_fa_ct_a.zw) - int2(1, 1)), 0));\n                bool _3239 = _3236.w > 0.5f;\n                bool _3255;\n                if (_3239)\n                {\n                    _3255 = abs(_3129 - _3236.x) <= (((0.00200000009499490261077880859375f * _3129) + 0.00999999977648258209228515625f) + min(1.5f * _3132, 0.100000001490116119384765625f * _3129));\n                }\n                else\n                {\n                    _3255 = _3239;\n                }\n                if (_3255)\n                {\n                    float _3261;\n                    if (_421_fa_ct_b.z > 0.5f)\n                    {\n                        float3 param = fa_world_pos;\n                        float3 param_1 = n;\n                        float3 param_2 = l;\n                        _3261 = min(_3236.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3261 = _3236.y;\n                    }\n                    return _3261;\n                }\n            }\n        }\n    }\n    float3 param_3 = fa_world_pos;\n    float3 param_4 = n;\n    float3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3917 = _421_fa_ct_a.x < 0.5f;\n    bool _3924;\n    if (!_3917)\n    {\n        _3924 = _2073_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3924 = _3917;\n    }\n    if (_3924)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2073_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3937 = fa_light_texel(param);\n    float _3938 = _3937.y;\n    float len = _3938;\n    if (_3938 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3950 = length(world - _421_fa_camera_pos.xyz);\n    float _3959 = 1.0f - smoothstep(0.5f * _421_fa_ct_b.x, _421_fa_ct_b.x, _3950);\n    if (_3959 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3965 = len;\n    float _3968 = min(_3965, 0.89999997615814208984375f * dist);\n    len = _3968;\n    float _3974 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3950);\n    float _3979 = _3974 + (0.5f * _3968);\n    float3 _3985 = world + (gn * _3974);\n    float _3987 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4049;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4003 = (float(k) + _3987) * 0.083333335816860198974609375f;\n        float3 _4011 = _3985 + (l * (_4003 * len));\n        float4 _4017 = float4(_4011, 1.0f);\n        float _4022 = dot(_421_fa_ct_vpw, _4017);\n        if (_4022 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4040 = float2(dot(_421_fa_ct_vpx, _4017), dot(_421_fa_ct_vpy, _4017)) / _4022.xx;\n        float _4044 = _4040.x * 0.5f;\n        float _4045 = _4044 + 0.5f;\n        if (_421_fa_ct_a.y > 0.5f)\n        {\n            _4049 = (_4040.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4049 = 0.5f - (_4040.y * 0.5f);\n        }\n        bool _4065 = _4045 < 0.0f;\n        bool _4072;\n        if (!_4065)\n        {\n            _4072 = _4045 >= 1.0f;\n        }\n        else\n        {\n            _4072 = _4065;\n        }\n        bool _4079;\n        if (!_4072)\n        {\n            _4079 = _4049 < 0.0f;\n        }\n        else\n        {\n            _4079 = _4072;\n        }\n        bool _4086;\n        if (!_4079)\n        {\n            _4086 = _4049 >= 1.0f;\n        }\n        else\n        {\n            _4086 = _4079;\n        }\n        if (_4086)\n        {\n            break;\n        }\n        float4 _4110 = fa_screen_tex.Load(int3(clamp(int2(float2(_4045, _4049) * _421_fa_ct_a.zw), int2(0, 0), int2(_421_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_4110.w < 0.5f)\n        {\n            continue;\n        }\n        float _4128 = (dot(_421_fa_ct_fwd.xyz, _4011) + _421_fa_ct_fwd.w) - _4110.x;\n        if ((_4128 > _3974) && (_4128 < _3979))\n        {\n            occ = max(occ, (1.0f - (_4003 * _4003)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4045, 0.5f - _4044), min(_4049, 1.0f - _4049))));\n        }\n    }\n    return 1.0f - (occ * _3959);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4231 = fa_baked_keep(param);\n    if (_4231 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _6045 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6045;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4257 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6047 = _4257.color;\n    float _6048 = _4257.attenuation;\n    float _6049 = _4257.shadow;\n    bool _4260 = _4257.type == 0;\n    if (_4260 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4257.direction;\n        float _4271 = fa_shadow_factor(param_5, param_6);\n        _6049 = _4271;\n        _6047 *= _4271;\n    }\n    else\n    {\n        bool _4282 = _4257.type != 0;\n        bool _4288;\n        if (_4282)\n        {\n            _4288 = _6048 > 0.0f;\n        }\n        else\n        {\n            _4288 = _4282;\n        }\n        if (_4288)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4257.direction;\n            float _4307 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6049 = _4307;\n            _6047 *= _4307;\n        }\n    }\n    bool _4317 = _421_fa_ct_a.x > 0.5f;\n    bool _4323;\n    if (_4317)\n    {\n        _4323 = _6048 > 0.0f;\n    }\n    else\n    {\n        _4323 = _4317;\n    }\n    if (_4323)\n    {\n        float _4330;\n        if (_4260)\n        {\n            _4330 = 1000000000.0f;\n        }\n        else\n        {\n            _4330 = _4257._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4257.direction;\n        float param_18 = _4330;\n        float _4348 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6049 *= _4348;\n        _6047 *= _4348;\n    }\n    float _4361 = _6048;\n    float _4362 = _4361 * _4231;\n    _6048 = _4362;\n    float3 _4366 = _6047;\n    float3 _4367 = _4366 * _4231;\n    _6047 = _4367;\n    LightSample _6064 = { _4257.direction, _4367, _4362, _6049, _4257._distance, _4257.type };\n    return _6064;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2073_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3032 = int(_2073_fa_shadow_cfg.x + 0.5f);\n    float _3042 = dot(world - _2073_fa_shadow_eye.xyz, _2073_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3047 = _3032 > 0;\n    bool _3056;\n    if (_3047)\n    {\n        int param = _3032 - 1;\n        _3056 = _3042 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3056 = _3047;\n    }\n    if (_3056)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3062 = _3032 > 1;\n        bool _3069;\n        if (_3062)\n        {\n            _3069 = _3042 > _2073_fa_shadow_split.x;\n        }\n        else\n        {\n            _3069 = _3062;\n        }\n        if (_3069)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3075 = _3032 > 2;\n        bool _3082;\n        if (_3075)\n        {\n            _3082 = _3042 > _2073_fa_shadow_split.y;\n        }\n        else\n        {\n            _3082 = _3075;\n        }\n        if (_3082)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3088 = _3032 > 3;\n        bool _3095;\n        if (_3088)\n        {\n            _3095 = _3042 > _2073_fa_shadow_split.z;\n        }\n        else\n        {\n            _3095 = _3088;\n        }\n        if (_3095)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5868 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5868 = -_5868;\n    }\n    float3 _5442 = normalize(_421_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5881 = { fa_world_pos, _5868, fa_world_tangent, fa_uv, fa_vertex_color, _5442, gl_FrontFacing };\n    SurfaceInput param_1 = _5881;\n    Surface _5450 = fa_standard_surface(param_1);\n    float3 _5899 = _5450.albedo;\n    float _5900 = _5450.alpha;\n    float3 _5901 = _5450.normal;\n    float _5902 = _5450.metallic;\n    float _5903 = _5450.roughness;\n    float _5904 = _5450.occlusion;\n    float3 _5905 = _5450.emission;\n    float _5906 = _5450.clearcoat;\n    float _5907 = _5450.clearcoat_roughness;\n    float3 _5908 = _5450.sheen_color;\n    float _5909 = _5450.sheen_roughness;\n    float _5910 = _5450.anisotropy;\n    float _5911 = _5450.anisotropy_rotation;\n    float _5912 = _5450.specular;\n    float _5913 = _5450.ior;\n    float3 _5914 = _5450.specular_color;\n    float _5915 = _5450.transmission;\n    float _5916 = _5450.thickness;\n    float3 _5917 = _5450.attenuation_color;\n    float _5918 = _5450.attenuation_distance;\n    SurfaceInput _5889 = { fa_world_pos, _5868, fa_world_tangent, fa_uv, fa_vertex_color, _5442, gl_FrontFacing };\n    SurfaceInput param_2 = _5889;\n    Surface param_3 = _5450;\n    surface(param_2, param_3);\n    _5899 = param_3.albedo;\n    _5900 = param_3.alpha;\n    _5901 = param_3.normal;\n    _5902 = param_3.metallic;\n    _5903 = param_3.roughness;\n    _5904 = param_3.occlusion;\n    _5905 = param_3.emission;\n    _5906 = param_3.clearcoat;\n    _5907 = param_3.clearcoat_roughness;\n    _5908 = param_3.sheen_color;\n    _5909 = param_3.sheen_roughness;\n    _5910 = param_3.anisotropy;\n    _5911 = param_3.anisotropy_rotation;\n    _5912 = param_3.specular;\n    _5913 = param_3.ior;\n    _5914 = param_3.specular_color;\n    _5915 = param_3.transmission;\n    _5916 = param_3.thickness;\n    _5917 = param_3.attenuation_color;\n    _5918 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5868;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5899 = param_6;\n    _5901 = param_7;\n    float3 result;\n    if (_421_fa_emissive.w > 0.5f)\n    {\n        result = _5899;\n    }\n    else\n    {\n        float3 _5489 = _5901;\n        float3 _5490 = normalize(_5489);\n        _5901 = _5490;\n        float3 param_8 = _5490;\n        float3 lit = (fa_indirect_diffuse(param_8) * _5899) * _5904;\n        int _5509 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5509; ln++)\n        {\n            int param_9 = ln;\n            int _5522 = fa_cl_light(param_9);\n            int param_10 = _5522;\n            if (fa_baked_keep(param_10) <= 0.0f)\n            {\n                continue;\n            }\n            int param_11 = _5522;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _5868;\n            LightSample _5538 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput _5897 = { fa_world_pos, _5868, fa_world_tangent, fa_uv, fa_vertex_color, _5442, gl_FrontFacing };\n            SurfaceInput param_14 = _5897;\n            Surface _6000 = { _5899, _5900, _5901, _5902, _5903, _5904, _5905, _5906, _5907, _5908, _5909, _5910, _5911, _5912, _5913, _5914, _5915, _5916, _5917, _5918 };\n            Surface param_15 = _6000;\n            LightSample param_16 = _5538;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _5553 = result;\n    float3 _5554 = _5553 + _5905;\n    result = _5554;\n    float3 param_17 = _5554;\n    float3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _5563 = _421_fa_fog.w > 0.0f;\n    bool _5570;\n    if (!_5563)\n    {\n        _5570 = _421_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5570 = _5563;\n    }\n    if (_5570)\n    {\n        float3 _5579 = fa_world_pos - _421_fa_camera_pos.xyz;\n        float _5585 = dot(_5579, _421_fa_fog_c.xyz);\n        bool _5589 = _421_fa_fog_c.w > 0.5f;\n        float _5590;\n        if (_5589)\n        {\n            _5590 = _5585;\n        }\n        else\n        {\n            _5590 = length(_5579);\n        }\n        float _5602 = _5590 - _421_fa_fog_b.x;\n        if (_5602 > 0.0f)\n        {\n            float _5611 = _421_fa_fog.w * _5602;\n            float tau = _5611 * _5611;\n            if (_421_fa_fog_b.y > 0.0f)\n            {\n                float _5627;\n                if (_5589)\n                {\n                    _5627 = fa_world_pos.y - (_421_fa_fog_c.y * _5585);\n                }\n                else\n                {\n                    _5627 = _421_fa_camera_pos.y;\n                }\n                float _5648 = lerp(_5627, fa_world_pos.y, clamp(_421_fa_fog_b.x / _5590, 0.0f, 1.0f));\n                float _5652 = fa_world_pos.y - _5648;\n                float _5657 = _5648 - _421_fa_fog_b.z;\n                float _5662 = fa_world_pos.y - _421_fa_fog_b.z;\n                bool _5665 = _5657 <= 0.0f;\n                bool _5666 = !_5665;\n                bool _5672;\n                if (_5666)\n                {\n                    _5672 = _421_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5672 = _5665;\n                }\n                float _5673;\n                if (_5672)\n                {\n                    _5673 = _421_fa_fog_b.y;\n                }\n                else\n                {\n                    _5673 = _421_fa_fog_b.y * exp(-min(_421_fa_fog_b.w * _5657, 80.0f));\n                }\n                bool _5700;\n                if (_5666)\n                {\n                    _5700 = _421_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5700 = _5665;\n                }\n                float _5701;\n                if (_5700)\n                {\n                    _5701 = _421_fa_fog_b.y * _5657;\n                }\n                else\n                {\n                    _5701 = (_421_fa_fog_b.y * (1.0f - exp(-min(_421_fa_fog_b.w * _5657, 80.0f)))) / _421_fa_fog_b.w;\n                }\n                bool _5726 = _5662 <= 0.0f;\n                bool _5733;\n                if (!_5726)\n                {\n                    _5733 = _421_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5733 = _5726;\n                }\n                float _5734;\n                if (_5733)\n                {\n                    _5734 = _421_fa_fog_b.y * _5662;\n                }\n                else\n                {\n                    _5734 = (_421_fa_fog_b.y * (1.0f - exp(-min(_421_fa_fog_b.w * _5662, 80.0f)))) / _421_fa_fog_b.w;\n                }\n                float _5761;\n                if (abs(_5652) < 0.001000000047497451305389404296875f)\n                {\n                    _5761 = _5673;\n                }\n                else\n                {\n                    _5761 = (_5734 - _5701) / _5652;\n                }\n                tau += (_5602 * max(_5761, 0.0f));\n            }\n            result = lerp(result, _421_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5900);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_421",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2073",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _57_fa_view_proj : packoffset(c0);\n    row_major float4x4 _57_fa_light_vp : packoffset(c4);\n    float4 _57_fa_uv_scale : packoffset(c8);\n    float4 _57_fa_time : packoffset(c9);\n    float4 _57_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_vel_params : register(b2)\n{\n    row_major float4x4 _225_fa_vel_vp : packoffset(c0);\n    row_major float4x4 _225_fa_vel_prev_vp : packoffset(c4);\n    float4 _225_fa_vel_on : packoffset(c8);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float4 fa_prev_r0;\nstatic float4 fa_prev_r1;\nstatic float4 fa_prev_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_prev_r0 : TEXCOORD9;\n    float4 fa_prev_r1 : TEXCOORD10;\n    float4 fa_prev_r2 : TEXCOORD11;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4 fa_time_now()\n{\n    return _57_fa_time;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _97 = cross(model[1].xyz, model[2].xyz);\n    float _101 = (dot(model[0].xyz, _97) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _448 = { mul(float4(position, 1.0f), model).xyz, (((_97 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _101, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _101), texcoord0 * _57_fa_uv_scale.xy, color, position };\n    return _448;\n}\n\nfloat4x4 fa_rows_to_mat4(float4 r0, float4 r1, float4 r2)\n{\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat4x4 fa_prev_model()\n{\n    float4 param = fa_prev_r0;\n    float4 param_1 = fa_prev_r1;\n    float4 param_2 = fa_prev_r2;\n    return fa_rows_to_mat4(param, param_1, param_2);\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color, bool has_prev)\n{\n    bool _231;\n    if (has_prev)\n    {\n        _231 = _225_fa_vel_on.x > 0.5f;\n    }\n    else\n    {\n        _231 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _246 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _455 = _246.world_pos;\n    float4 _257 = float4(_455, 1.0f);\n    fa_world_pos = _455;\n    fa_world_normal = _246.world_normal;\n    fa_world_tangent = _246.world_tangent;\n    fa_uv = _246.uv;\n    fa_vertex_color = _246.color;\n    fa_pre_depth = -mul(_257, _57_fa_light_vp).z;\n    fa_pre_r0 = float3(_57_fa_light_vp[0].x, _57_fa_light_vp[1].x, _57_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_57_fa_light_vp[0].y, _57_fa_light_vp[1].y, _57_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_57_fa_light_vp[0].z, _57_fa_light_vp[1].z, _57_fa_light_vp[2].z);\n    gl_Position = mul(_257, _57_fa_view_proj);\n    fa_vel_cur = float3(0.0f, 0.0f, 1.0f);\n    fa_vel_prev = 0.0f.xxx;\n    if (_231)\n    {\n        float4 _330 = float4(position, 1.0f);\n        fa_vel_cur = float3(mul(_257, _225_fa_vel_vp).xyw);\n        fa_vel_prev = float3(mul(float4((_455 + mul(_330, fa_prev_model()).xyz) - mul(_330, model).xyz, 1.0f), _225_fa_vel_prev_vp).xyw);\n    }\n}\n\nvoid vert_main()\n{\n    fa_vtime = 0.0f.xxxx;\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    bool param_6 = true;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_prev_r0 = stage_input.fa_prev_r0;\n    fa_prev_r1 = stage_input.fa_prev_r1;\n    fa_prev_r2 = stage_input.fa_prev_r2;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    stage_output.fa_vel_cur = fa_vel_cur;\n    stage_output.fa_vel_prev = fa_vel_prev;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _214_fa_camera_pos : packoffset(c0);\n    float4 _214_fa_ambient : packoffset(c1);\n    float4 _214_fa_base_color : packoffset(c2);\n    float4 _214_fa_emissive : packoffset(c3);\n    float4 _214_fa_model_emissive : packoffset(c4);\n    float4 _214_fa_pbr : packoffset(c5);\n    float4 _214_fa_maps : packoffset(c6);\n    float4 _214_fa_fog : packoffset(c7);\n    float4 _214_fa_fog_b : packoffset(c8);\n    float4 _214_fa_fog_c : packoffset(c9);\n    float4 _214_fa_counts : packoffset(c10);\n    float4 _214_fa_env_sky : packoffset(c11);\n    float4 _214_fa_env_horizon : packoffset(c12);\n    float4 _214_fa_time : packoffset(c13);\n    float4 _214_fa_cl_vpx : packoffset(c14);\n    float4 _214_fa_cl_vpy : packoffset(c15);\n    float4 _214_fa_cl_vpw : packoffset(c16);\n    float4 _214_fa_cl_fwd : packoffset(c17);\n    float4 _214_fa_cl_grid : packoffset(c18);\n    float4 _214_fa_cl_info : packoffset(c19);\n    float4 _214_fa_layers_a : packoffset(c20);\n    float4 _214_fa_layers_b : packoffset(c21);\n    float4 _214_fa_layers_c : packoffset(c22);\n    float4 _214_fa_layers_d : packoffset(c23);\n    float4 _214_fa_ct_a : packoffset(c24);\n    float4 _214_fa_ct_b : packoffset(c25);\n    float4 _214_fa_ct_vpx : packoffset(c26);\n    float4 _214_fa_ct_vpy : packoffset(c27);\n    float4 _214_fa_ct_vpw : packoffset(c28);\n    float4 _214_fa_ct_fwd : packoffset(c29);\n    float4 _214_fa_tr_a : packoffset(c30);\n    float4 _214_fa_tr_b : packoffset(c31);\n    float4 _214_fa_probe_sh[9] : packoffset(c32);\n    float4 _214_fa_atlas : packoffset(c41);\n    float4 _214_fa_rpa_tile : packoffset(c42);\n    float4 _214_fa_rpa_pos : packoffset(c43);\n    float4 _214_fa_rpa_bx : packoffset(c44);\n    float4 _214_fa_rpa_by : packoffset(c45);\n    float4 _214_fa_rpa_bz : packoffset(c46);\n    float4 _214_fa_rpb_tile : packoffset(c47);\n    float4 _214_fa_rpb_pos : packoffset(c48);\n    float4 _214_fa_rpb_bx : packoffset(c49);\n    float4 _214_fa_rpb_by : packoffset(c50);\n    float4 _214_fa_rpb_bz : packoffset(c51);\n    float4 _214_fa_gi : packoffset(c52);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float2 fa_frag_velocity;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n    float2 fa_frag_velocity : SV_Target1;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w);\n    float param = _214_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _230 = fa_tex_fix(param_2, param_3);\n    float4 _889 = base_t;\n    _889.x = _230.x;\n    _889.y = _230.y;\n    _889.z = _230.z;\n    base_t = _889;\n    float4 _246 = (_889 * _214_fa_base_color) * i.vertex_color;\n    float3 _844 = i.world_normal;\n    if (_214_fa_maps.z > 0.5f)\n    {\n        float param_4 = _214_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _282 = fa_tex_fix(param_6, param_7);\n        float3 _286 = (_282 * 2.0f) - 1.0f.xxx;\n        float2 _291 = _286.xy * _214_fa_maps.x;\n        float3 _897 = _286;\n        _897.x = _291.x;\n        _897.y = _291.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _897;\n        _844 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w);\n    float param_10 = _214_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _322 = fa_tex_fix(param_12, param_13);\n    float4 _900 = mrt;\n    _900.x = _322.x;\n    _900.y = _322.y;\n    _900.z = _322.z;\n    mrt = _900;\n    float4 _354 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w);\n    float param_14 = _214_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _214_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _398 = fa_tex_fix(param_20, param_21);\n    float _849 = _214_fa_layers_a.x;\n    float _850 = _214_fa_layers_a.y;\n    float _853 = _214_fa_layers_a.z;\n    float _852 = _214_fa_layers_b.w;\n    float _855 = _214_fa_layers_c.x;\n    if (_214_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_214_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _849 *= _366.y;\n            _850 *= _366.z;\n            _852 *= _354.w;\n        }\n        if (_214_fa_layers_c.z > 1.5f)\n        {\n            _853 *= mrt.x;\n            _855 *= mrt.w;\n        }\n    }\n    Surface _882 = { _246.xyz, _246.w, _844, clamp(_214_fa_pbr.x * _322.z, 0.0f, 1.0f), clamp(_214_fa_pbr.y * _322.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_214_fa_maps.y * (_366.x - 1.0f)), _214_fa_emissive.xyz + (_214_fa_model_emissive.xyz * _398), _849, _850, _214_fa_layers_b.xyz, _852, _853, _214_fa_layers_a.w, _855, _214_fa_layers_c.y, _214_fa_layers_d.xyz, _214_fa_tr_a.x, _214_fa_tr_a.y, _214_fa_tr_b.xyz, _214_fa_tr_a.z };\n    return _882;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _739 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _739 = -_739;\n    }\n    float3 _550 = normalize(_214_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _752 = { fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing };\n    SurfaceInput param = _752;\n    SurfaceInput _760 = { fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing };\n    SurfaceInput param_1 = _760;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _565 = normalize(param_2.normal);\n    float3 _580 = normalize(float3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    float2 e = _580.xy / ((abs(_580.x) + abs(_580.y)) + abs(_592)).xx;\n    if (_592 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n    float2 motion = 1024.0f.xx;\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06f;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06f;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((float2(fa_vel_prev.x, -fa_vel_prev.y) / fa_vel_prev.z.xx) * 0.5f) - ((float2(fa_vel_cur.x, -fa_vel_cur.y) / fa_vel_cur.z.xx) * 0.5f), (-4.0f).xx, 4.0f.xx);\n    }\n    fa_frag_velocity = motion;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    fa_vel_cur = stage_input.fa_vel_cur;\n    fa_vel_prev = stage_input.fa_vel_prev;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    stage_output.fa_frag_velocity = fa_frag_velocity;\n    return stage_output;\n}\n",
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
            "size": 848,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _74_fa_view_proj : packoffset(c0);\n    row_major float4x4 _74_fa_light_vp : packoffset(c4);\n    float4 _74_fa_uv_scale : packoffset(c8);\n    float4 _74_fa_time : packoffset(c9);\n    float4 _74_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _213_fa_joint_rows[192] : packoffset(c0);\n};\n\ncbuffer fa_vel_params : register(b2)\n{\n    row_major float4x4 _470_fa_vel_vp : packoffset(c0);\n    row_major float4x4 _470_fa_vel_prev_vp : packoffset(c4);\n    float4 _470_fa_vel_on : packoffset(c8);\n};\n\nTexture2D<float4> fa_prev_pal_tex : register(t0);\nSamplerState fa_prev_pal_smp : register(s11);\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float4 fa_prev_r0;\nstatic float4 fa_prev_r1;\nstatic float4 fa_prev_r2;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    float4 fa_prev_r0 : TEXCOORD11;\n    float4 fa_prev_r1 : TEXCOORD12;\n    float4 fa_prev_r2 : TEXCOORD13;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _204 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_213_fa_joint_rows[_204] * weights[i]);\n        r1 += (_213_fa_joint_rows[_204 + 1] * weights[i]);\n        r2 += (_213_fa_joint_rows[_204 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat4 fa_time_now()\n{\n    return _74_fa_time;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _113 = cross(model[1].xyz, model[2].xyz);\n    float _117 = (dot(model[0].xyz, _113) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _713 = { mul(float4(position, 1.0f), model).xyz, (((_113 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _117, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _117), texcoord0 * _74_fa_uv_scale.xy, color, position };\n    return _713;\n}\n\nfloat4x4 fa_rows_to_mat4(float4 r0, float4 r1, float4 r2)\n{\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat4 fa_prev_pal_texel(int t)\n{\n    return fa_prev_pal_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4x4 fa_prev_skin_matrix(float4 joints, float4 weights, int base)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _332 = base + (int((joints[i] * 255.0f) + 0.5f) * 3);\n        int param = _332;\n        r0 += (fa_prev_pal_texel(param) * weights[i]);\n        int param_1 = _332 + 1;\n        r1 += (fa_prev_pal_texel(param_1) * weights[i]);\n        int param_2 = _332 + 2;\n        r2 += (fa_prev_pal_texel(param_2) * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat4x4 fa_prev_model()\n{\n    float4 param = fa_prev_r0;\n    float4 param_1 = fa_prev_r1;\n    float4 param_2 = fa_prev_r2;\n    float4 param_3 = fa_joints;\n    float4 param_4 = fa_weights;\n    int param_5 = int(_470_fa_vel_on.w + 0.5f);\n    return mul(fa_prev_skin_matrix(param_3, param_4, param_5), fa_rows_to_mat4(param, param_1, param_2));\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color, bool has_prev)\n{\n    bool _475;\n    if (has_prev)\n    {\n        _475 = _470_fa_vel_on.x > 0.5f;\n    }\n    else\n    {\n        _475 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _490 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _720 = _490.world_pos;\n    float4 _501 = float4(_720, 1.0f);\n    fa_world_pos = _720;\n    fa_world_normal = _490.world_normal;\n    fa_world_tangent = _490.world_tangent;\n    fa_uv = _490.uv;\n    fa_vertex_color = _490.color;\n    fa_pre_depth = -mul(_501, _74_fa_light_vp).z;\n    fa_pre_r0 = float3(_74_fa_light_vp[0].x, _74_fa_light_vp[1].x, _74_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_74_fa_light_vp[0].y, _74_fa_light_vp[1].y, _74_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_74_fa_light_vp[0].z, _74_fa_light_vp[1].z, _74_fa_light_vp[2].z);\n    gl_Position = mul(_501, _74_fa_view_proj);\n    fa_vel_cur = float3(0.0f, 0.0f, 1.0f);\n    fa_vel_prev = 0.0f.xxx;\n    if (_475)\n    {\n        float4 _574 = float4(position, 1.0f);\n        fa_vel_cur = float3(mul(_501, _470_fa_vel_vp).xyw);\n        fa_vel_prev = float3(mul(float4((_720 + mul(_574, fa_prev_model()).xyz) - mul(_574, model).xyz, 1.0f), _470_fa_vel_prev_vp).xyw);\n    }\n}\n\nvoid vert_main()\n{\n    fa_vtime = 0.0f.xxxx;\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    bool param_8 = _470_fa_vel_on.z > 0.5f;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_prev_r0 = stage_input.fa_prev_r0;\n    fa_prev_r1 = stage_input.fa_prev_r1;\n    fa_prev_r2 = stage_input.fa_prev_r2;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    stage_output.fa_vel_cur = fa_vel_cur;\n    stage_output.fa_vel_prev = fa_vel_prev;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _214_fa_camera_pos : packoffset(c0);\n    float4 _214_fa_ambient : packoffset(c1);\n    float4 _214_fa_base_color : packoffset(c2);\n    float4 _214_fa_emissive : packoffset(c3);\n    float4 _214_fa_model_emissive : packoffset(c4);\n    float4 _214_fa_pbr : packoffset(c5);\n    float4 _214_fa_maps : packoffset(c6);\n    float4 _214_fa_fog : packoffset(c7);\n    float4 _214_fa_fog_b : packoffset(c8);\n    float4 _214_fa_fog_c : packoffset(c9);\n    float4 _214_fa_counts : packoffset(c10);\n    float4 _214_fa_env_sky : packoffset(c11);\n    float4 _214_fa_env_horizon : packoffset(c12);\n    float4 _214_fa_time : packoffset(c13);\n    float4 _214_fa_cl_vpx : packoffset(c14);\n    float4 _214_fa_cl_vpy : packoffset(c15);\n    float4 _214_fa_cl_vpw : packoffset(c16);\n    float4 _214_fa_cl_fwd : packoffset(c17);\n    float4 _214_fa_cl_grid : packoffset(c18);\n    float4 _214_fa_cl_info : packoffset(c19);\n    float4 _214_fa_layers_a : packoffset(c20);\n    float4 _214_fa_layers_b : packoffset(c21);\n    float4 _214_fa_layers_c : packoffset(c22);\n    float4 _214_fa_layers_d : packoffset(c23);\n    float4 _214_fa_ct_a : packoffset(c24);\n    float4 _214_fa_ct_b : packoffset(c25);\n    float4 _214_fa_ct_vpx : packoffset(c26);\n    float4 _214_fa_ct_vpy : packoffset(c27);\n    float4 _214_fa_ct_vpw : packoffset(c28);\n    float4 _214_fa_ct_fwd : packoffset(c29);\n    float4 _214_fa_tr_a : packoffset(c30);\n    float4 _214_fa_tr_b : packoffset(c31);\n    float4 _214_fa_probe_sh[9] : packoffset(c32);\n    float4 _214_fa_atlas : packoffset(c41);\n    float4 _214_fa_rpa_tile : packoffset(c42);\n    float4 _214_fa_rpa_pos : packoffset(c43);\n    float4 _214_fa_rpa_bx : packoffset(c44);\n    float4 _214_fa_rpa_by : packoffset(c45);\n    float4 _214_fa_rpa_bz : packoffset(c46);\n    float4 _214_fa_rpb_tile : packoffset(c47);\n    float4 _214_fa_rpb_pos : packoffset(c48);\n    float4 _214_fa_rpb_bx : packoffset(c49);\n    float4 _214_fa_rpb_by : packoffset(c50);\n    float4 _214_fa_rpb_bz : packoffset(c51);\n    float4 _214_fa_gi : packoffset(c52);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float2 fa_frag_velocity;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n    float2 fa_frag_velocity : SV_Target1;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w);\n    float param = _214_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _230 = fa_tex_fix(param_2, param_3);\n    float4 _889 = base_t;\n    _889.x = _230.x;\n    _889.y = _230.y;\n    _889.z = _230.z;\n    base_t = _889;\n    float4 _246 = (_889 * _214_fa_base_color) * i.vertex_color;\n    float3 _844 = i.world_normal;\n    if (_214_fa_maps.z > 0.5f)\n    {\n        float param_4 = _214_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _282 = fa_tex_fix(param_6, param_7);\n        float3 _286 = (_282 * 2.0f) - 1.0f.xxx;\n        float2 _291 = _286.xy * _214_fa_maps.x;\n        float3 _897 = _286;\n        _897.x = _291.x;\n        _897.y = _291.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _897;\n        _844 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w);\n    float param_10 = _214_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _322 = fa_tex_fix(param_12, param_13);\n    float4 _900 = mrt;\n    _900.x = _322.x;\n    _900.y = _322.y;\n    _900.z = _322.z;\n    mrt = _900;\n    float4 _354 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w);\n    float param_14 = _214_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _214_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _398 = fa_tex_fix(param_20, param_21);\n    float _849 = _214_fa_layers_a.x;\n    float _850 = _214_fa_layers_a.y;\n    float _853 = _214_fa_layers_a.z;\n    float _852 = _214_fa_layers_b.w;\n    float _855 = _214_fa_layers_c.x;\n    if (_214_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_214_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _849 *= _366.y;\n            _850 *= _366.z;\n            _852 *= _354.w;\n        }\n        if (_214_fa_layers_c.z > 1.5f)\n        {\n            _853 *= mrt.x;\n            _855 *= mrt.w;\n        }\n    }\n    Surface _882 = { _246.xyz, _246.w, _844, clamp(_214_fa_pbr.x * _322.z, 0.0f, 1.0f), clamp(_214_fa_pbr.y * _322.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_214_fa_maps.y * (_366.x - 1.0f)), _214_fa_emissive.xyz + (_214_fa_model_emissive.xyz * _398), _849, _850, _214_fa_layers_b.xyz, _852, _853, _214_fa_layers_a.w, _855, _214_fa_layers_c.y, _214_fa_layers_d.xyz, _214_fa_tr_a.x, _214_fa_tr_a.y, _214_fa_tr_b.xyz, _214_fa_tr_a.z };\n    return _882;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _739 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _739 = -_739;\n    }\n    float3 _550 = normalize(_214_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _752 = { fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing };\n    SurfaceInput param = _752;\n    SurfaceInput _760 = { fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing };\n    SurfaceInput param_1 = _760;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _565 = normalize(param_2.normal);\n    float3 _580 = normalize(float3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    float2 e = _580.xy / ((abs(_580.x) + abs(_580.y)) + abs(_592)).xx;\n    if (_592 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n    float2 motion = 1024.0f.xx;\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06f;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06f;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((float2(fa_vel_prev.x, -fa_vel_prev.y) / fa_vel_prev.z.xx) * 0.5f) - ((float2(fa_vel_cur.x, -fa_vel_cur.y) / fa_vel_cur.z.xx) * 0.5f), (-4.0f).xx, 4.0f.xx);\n    }\n    fa_frag_velocity = motion;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    fa_vel_cur = stage_input.fa_vel_cur;\n    fa_vel_prev = stage_input.fa_vel_prev;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    stage_output.fa_frag_velocity = fa_frag_velocity;\n    return stage_output;\n}\n",
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
            "size": 848,
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
