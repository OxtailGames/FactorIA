{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "08807f15fbf8385ded2b4420996b416372731eb6a03ea417de2ef212814a9452",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _260 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _260;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_267, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _427_fa_camera_pos : packoffset(c0);\n    float4 _427_fa_ambient : packoffset(c1);\n    float4 _427_fa_base_color : packoffset(c2);\n    float4 _427_fa_emissive : packoffset(c3);\n    float4 _427_fa_model_emissive : packoffset(c4);\n    float4 _427_fa_pbr : packoffset(c5);\n    float4 _427_fa_maps : packoffset(c6);\n    float4 _427_fa_fog : packoffset(c7);\n    float4 _427_fa_fog_b : packoffset(c8);\n    float4 _427_fa_fog_c : packoffset(c9);\n    float4 _427_fa_counts : packoffset(c10);\n    float4 _427_fa_env_sky : packoffset(c11);\n    float4 _427_fa_env_horizon : packoffset(c12);\n    float4 _427_fa_time : packoffset(c13);\n    float4 _427_fa_cl_vpx : packoffset(c14);\n    float4 _427_fa_cl_vpy : packoffset(c15);\n    float4 _427_fa_cl_vpw : packoffset(c16);\n    float4 _427_fa_cl_fwd : packoffset(c17);\n    float4 _427_fa_cl_grid : packoffset(c18);\n    float4 _427_fa_cl_info : packoffset(c19);\n    float4 _427_fa_layers_a : packoffset(c20);\n    float4 _427_fa_layers_b : packoffset(c21);\n    float4 _427_fa_layers_c : packoffset(c22);\n    float4 _427_fa_layers_d : packoffset(c23);\n    float4 _427_fa_ct_a : packoffset(c24);\n    float4 _427_fa_ct_b : packoffset(c25);\n    float4 _427_fa_ct_vpx : packoffset(c26);\n    float4 _427_fa_ct_vpy : packoffset(c27);\n    float4 _427_fa_ct_vpw : packoffset(c28);\n    float4 _427_fa_ct_fwd : packoffset(c29);\n    float4 _427_fa_tr_a : packoffset(c30);\n    float4 _427_fa_tr_b : packoffset(c31);\n    float4 _427_fa_probe_sh[9] : packoffset(c32);\n    float4 _427_fa_atlas : packoffset(c41);\n    float4 _427_fa_rpa_tile : packoffset(c42);\n    float4 _427_fa_rpa_pos : packoffset(c43);\n    float4 _427_fa_rpa_bx : packoffset(c44);\n    float4 _427_fa_rpa_by : packoffset(c45);\n    float4 _427_fa_rpa_bz : packoffset(c46);\n    float4 _427_fa_rpb_tile : packoffset(c47);\n    float4 _427_fa_rpb_pos : packoffset(c48);\n    float4 _427_fa_rpb_bx : packoffset(c49);\n    float4 _427_fa_rpb_by : packoffset(c50);\n    float4 _427_fa_rpb_bz : packoffset(c51);\n    float4 _427_fa_gi : packoffset(c52);\n    float4 _427_fa_gi_px : packoffset(c53);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2079_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2079_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2079_fa_shadow_info[4] : packoffset(c20);\n    float4 _2079_fa_shadow_split : packoffset(c24);\n    float4 _2079_fa_shadow_cfg : packoffset(c25);\n    float4 _2079_fa_shadow_bias : packoffset(c26);\n    float4 _2079_fa_shadow_eye : packoffset(c27);\n    float4 _2079_fa_shadow_fwd : packoffset(c28);\n    float4 _2079_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1355 = _427_fa_cl_info.x < 0.0f;\n    bool _1362;\n    if (!_1355)\n    {\n        _1362 = _427_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1362 = _1355;\n    }\n    bool _1370;\n    if (!_1362)\n    {\n        _1370 = _427_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1370 = _1362;\n    }\n    bool _1377;\n    if (!_1370)\n    {\n        _1377 = _427_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1377 = _1370;\n    }\n    bool _1384;\n    if (!_1377)\n    {\n        _1384 = _427_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1384 = _1377;\n    }\n    if (_1384)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1394 = float4(world_pos, 1.0f);\n    float _1400 = dot(_427_fa_cl_vpw, _1394);\n    if (!(_1400 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1422 = float2(dot(_427_fa_cl_vpx, _1394), dot(_427_fa_cl_vpy, _1394)) / _1400.xx;\n    int _1426 = int(_427_fa_cl_grid.x);\n    int _1430 = int(_427_fa_cl_grid.y);\n    int param = (int(_427_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_427_fa_cl_fwd.xyz, world_pos) + _427_fa_cl_fwd.w, _427_fa_cl_grid.w) / _427_fa_cl_grid.w) * _427_fa_cl_grid.z)), 0, int(_427_fa_cl_info.y) - 1) * _1430) + clamp(int(floor(((_1422.y * 0.5f) + 0.5f) * _427_fa_cl_grid.y)), 0, _1430 - 1)) * _1426)) + clamp(int(floor(((_1422.x * 0.5f) + 0.5f) * _427_fa_cl_grid.x)), 0, _1426 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1506 = fa_cluster_texel(param);\n    return int2(int(_1506.x), int(_1506.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_427_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4211 = fa_cluster_lookup(param);\n    fa_cl_slot = _4211.x;\n    fa_cl_local = _4211.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4421 = fa_linear_to_srgb(param);\n        c = _4421;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4429 = fa_srgb_to_linear(param_1);\n            c = _4429;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _309;\n    if (i.front_facing)\n    {\n        _309 = i.world_normal;\n    }\n    else\n    {\n        _309 = -i.world_normal;\n    }\n    float3 _333 = normalize(i.world_tangent.xyz - (_309 * dot(_309, i.world_tangent.xyz)));\n    float3 _360 = normalize(((_333 * m.x) + ((cross(_309, _333) * i.world_tangent.w) * m.y)) + (_309 * m.z));\n    float3 _363;\n    if (i.front_facing)\n    {\n        _363 = _360;\n    }\n    else\n    {\n        _363 = -_360;\n    }\n    return _363;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _427_fa_env_horizon.w);\n    float param = _427_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4461 = fa_tex_fix(param_2, param_3);\n    float4 _6366 = base_t;\n    _6366.x = _4461.x;\n    _6366.y = _4461.y;\n    _6366.z = _4461.z;\n    base_t = _6366;\n    float4 _4475 = (_6366 * _427_fa_base_color) * i.vertex_color;\n    float3 _6182 = i.world_normal;\n    if (_427_fa_maps.z > 0.5f)\n    {\n        float param_4 = _427_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _427_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4509 = fa_tex_fix(param_6, param_7);\n        float3 _4512 = (_4509 * 2.0f) - 1.0f.xxx;\n        float2 _4517 = _4512.xy * _427_fa_maps.x;\n        float3 _6374 = _4512;\n        _6374.x = _4517.x;\n        _6374.y = _4517.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6374;\n        _6182 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _427_fa_env_horizon.w);\n    float param_10 = _427_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4547 = fa_tex_fix(param_12, param_13);\n    float4 _6377 = mrt;\n    _6377.x = _4547.x;\n    _6377.y = _4547.y;\n    _6377.z = _4547.z;\n    mrt = _6377;\n    float4 _4577 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _427_fa_env_horizon.w);\n    float param_14 = _427_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4577.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4588 = fa_tex_fix(param_16, param_17);\n    float param_18 = _427_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _427_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4620 = fa_tex_fix(param_20, param_21);\n    float _6187 = _427_fa_layers_a.x;\n    float _6188 = _427_fa_layers_a.y;\n    float _6191 = _427_fa_layers_a.z;\n    float _6190 = _427_fa_layers_b.w;\n    float _6193 = _427_fa_layers_c.x;\n    if (_427_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_427_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6187 *= _4588.y;\n            _6188 *= _4588.z;\n            _6190 *= _4577.w;\n        }\n        if (_427_fa_layers_c.z > 1.5f)\n        {\n            _6191 *= mrt.x;\n            _6193 *= mrt.w;\n        }\n    }\n    Surface _6220 = { _4475.xyz, _4475.w, _6182, clamp(_427_fa_pbr.x * _4547.z, 0.0f, 1.0f), clamp(_427_fa_pbr.y * _4547.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_427_fa_maps.y * (_4588.x - 1.0f)), _427_fa_emissive.xyz + (_427_fa_model_emissive.xyz * _4620), _6187, _6188, _427_fa_layers_b.xyz, _6190, _6191, _427_fa_layers_a.w, _6193, _427_fa_layers_c.y, _427_fa_layers_d.xyz, _427_fa_tr_a.x, _427_fa_tr_a.y, _427_fa_tr_b.xyz, _427_fa_tr_a.z };\n    return _6220;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1586 = rect.zw - rect.xy;\n    float2 _1590 = _1586 * atlas;\n    float2 _1594 = ddx * _1590;\n    float2 _1598 = ddy * _1590;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1586), clamp(0.5f * log2(max(max(dot(_1594, _1594), dot(_1598, _1598)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1631 = _427_fa_counts.y < 0.5f;\n    bool _1638;\n    if (!_1631)\n    {\n        _1638 = _427_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1638 = _1631;\n    }\n    if (_1638)\n    {\n        return;\n    }\n    float3 _1644 = ddx(world_pos);\n    float3 _1647 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1651 = fa_cluster_texel(param);\n    int _1655 = int(_1651.w);\n    if (_1655 < 1)\n    {\n        return;\n    }\n    int _1665 = int(_427_fa_counts.y + 0.5f);\n    int param_1 = _1665;\n    float4 _1669 = fa_light_texel(param_1);\n    float2 _1672 = _1669.yz;\n    int _1676 = int(_1669.w);\n    int param_2 = _1665 + 1;\n    float4 _1681 = fa_light_texel(param_2);\n    float _1682 = _1681.x;\n    int _1688 = int(_427_fa_counts.w + 0.5f) - 1;\n    int _1692 = int(_1651.z);\n    float3 _1957;\n    for (int k = 0; k < _1655; k++)\n    {\n        int _1705 = _1692 + k;\n        int param_3 = _1676 + (_1705 >> 2);\n        int _1722 = (_1665 + 2) + (int(fa_light_texel(param_3)[_1705 & 3]) * 7);\n        int param_4 = _1722 + 6;\n        float4 _1727 = fa_light_texel(param_4);\n        if (((int(_1727.w + 0.5f) >> _1688) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1722;\n        float4 _1742 = fa_light_texel(param_5);\n        int param_6 = _1722 + 1;\n        float4 _1747 = fa_light_texel(param_6);\n        int param_7 = _1722 + 2;\n        float4 _1752 = fa_light_texel(param_7);\n        float3 _1755 = _1742.xyz;\n        float _1760 = dot(_1755, world_pos) + _1742.w;\n        float3 _1762 = _1747.xyz;\n        float _1767 = dot(_1762, world_pos) + _1747.w;\n        float3 _1769 = _1752.xyz;\n        float _1774 = dot(_1769, world_pos) + _1752.w;\n        bool _1779 = abs(_1760) > 0.5f;\n        bool _1787;\n        if (!_1779)\n        {\n            _1787 = abs(_1767) > 0.5f;\n        }\n        else\n        {\n            _1787 = _1779;\n        }\n        bool _1795;\n        if (!_1787)\n        {\n            _1795 = abs(_1774) > 0.5f;\n        }\n        else\n        {\n            _1795 = _1787;\n        }\n        if (_1795)\n        {\n            continue;\n        }\n        float _1810 = clamp(dot(geo_normal, normalize(_1769)) * _1727.z, 0.0f, 1.0f);\n        if (_1810 <= 0.0f)\n        {\n            continue;\n        }\n        float _1830 = (clamp((0.5f - abs(_1774)) * 10.0f, 0.0f, 1.0f) * _1810) * _1727.x;\n        float2 _1838 = float2(_1760 + 0.5f, 0.5f - _1767);\n        float2 _1848 = float2(dot(_1755, _1644), dot(_1762, _1644));\n        float2 _1858 = float2(dot(_1755, _1647), dot(_1762, _1647));\n        int param_8 = _1722 + 5;\n        float4 _1863 = fa_light_texel(param_8);\n        int param_9 = _1722 + 3;\n        float4 _1868 = fa_light_texel(param_9);\n        int param_10 = _1722 + 4;\n        float4 _1873 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1863.xyz;\n        bool _1883 = _1868.z > _1868.x;\n        if (_1883)\n        {\n            float4 param_11 = _1868;\n            float2 param_12 = _1838;\n            float2 param_13 = _1672;\n            float2 param_14 = _1848;\n            float2 param_15 = _1858;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1682 > 0.5f) && (_1682 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1909 = fa_dc_to_linear(param_16);\n                float4 _6270 = tx;\n                _6270.x = _1909.x;\n                _6270.y = _1909.y;\n                _6270.z = _1909.z;\n                tx = _6270;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1830 * tex_a) * _1863.w, 0.0f, 1.0f).xxx);\n        if (_1873.z > _1873.x)\n        {\n            float4 param_17 = _1873;\n            float2 param_18 = _1838;\n            float2 param_19 = _1672;\n            float2 param_20 = _1848;\n            float2 param_21 = _1858;\n            float4 _1953 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1682 > 1.5f)\n            {\n                float3 param_22 = _1953.xyz;\n                float3 _1963 = fa_dc_to_srgb(param_22);\n                _1957 = _1963;\n            }\n            else\n            {\n                _1957 = _1953.xyz;\n            }\n            float3 _1972 = (_1957 * 2.0f) - 1.0f.xxx;\n            float2 _1977 = _1972.xy * _1727.y;\n            float3 _1999 = (normalize(_1755) * _1977.x) + (normalize(_1762) * _1977.y);\n            float3 _2002 = normalize(normal);\n            normal = normalize(lerp(_2002, normalize((_2002 * max(_1972.z, 0.0500000007450580596923828125f)) + (_1999 - (_2002 * dot(_2002, _1999)))), clamp(_1830 * (_1883 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3733_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3733_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_427_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3674 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3674;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3783 = (1.0f - _427_fa_rpa_tile.w) - _427_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3789 = _427_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3783 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3789)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _427_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3783;\n            }\n        }\n        else\n        {\n            amb = _427_fa_ambient.xyz * _3783;\n        }\n    }\n    bool _3841 = _427_fa_rpa_tile.w > 0.0f;\n    if (_3841)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _427_fa_rpa_tile.xy;\n            float param_4 = _427_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _427_fa_rpa_tile.w);\n        }\n    }\n    bool _3872 = _427_fa_rpb_tile.w > 0.0f;\n    if (_3872)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _427_fa_rpb_tile.xy;\n            float param_7 = _427_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _427_fa_rpb_tile.w);\n        }\n    }\n    if ((_3789 || _3841) || _3872)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3694 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3697 = _3694.x;\n    float _3699 = _3694.z;\n    float2 e = float2(_3697, _3699);\n    if (_3694.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3699)) * ((_3697 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3697)) * ((_3699 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _4734 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _4739 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _4744 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _4749 = fa_light_texel(param_3);\n    bool _4752 = _4749.z < 0.5f;\n    bool _4760;\n    if (!_4752)\n    {\n        _4760 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _4760 = _4752;\n    }\n    if (_4760)\n    {\n        return 0.0f.xxx;\n    }\n    float _4767 = max(_4734.w, 9.9999997473787516355514526367188e-05f);\n    float3 _4770 = _4739.xyz;\n    float3 _4774 = _4734.xyz;\n    float3 _4778 = (fa_world_pos - _4774) / _4767.xxx;\n    float3 _4787 = min(_4778 + 0.5f.xxx, (_4770 - 0.5f.xxx) - _4778);\n    float _4796 = min(_4787.x, min(_4787.y, _4787.z));\n    if (!(_4796 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4811 = _4770 - 1.0f.xxx;\n    float3 _4812 = clamp(_4778, 0.0f.xxx, _4811);\n    float3 _4820 = min(floor(_4812), max(_4770 - 2.0f.xxx, 0.0f.xxx));\n    float3 _4824 = _4812 - _4820;\n    float3 _4836 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _4767));\n    int _4841 = int(_4744.y + 0.5f);\n    float _4846 = 0.3257350027561187744140625f * n.y;\n    float _4850 = 0.3257350027561187744140625f * n.z;\n    float _4854 = 0.3257350027561187744140625f * n.x;\n    float _4861 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _4868 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _4877 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _4884 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _4897 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _4904 = 8 + int(_4749.w);\n    float _4931;\n    float _4944;\n    float _4958;\n    for (int k = 0; k < _4904; k++)\n    {\n        float _4917 = float(k & 1);\n        float _4921 = float((k >> 1) & 1);\n        float _4925 = float((k >> 2) & 1);\n        if (_4917 > 0.5f)\n        {\n            _4931 = _4824.x;\n        }\n        else\n        {\n            _4931 = 1.0f - _4824.x;\n        }\n        if (_4921 > 0.5f)\n        {\n            _4944 = _4824.y;\n        }\n        else\n        {\n            _4944 = 1.0f - _4824.y;\n        }\n        if (_4925 > 0.5f)\n        {\n            _4958 = _4824.z;\n        }\n        else\n        {\n            _4958 = 1.0f - _4824.z;\n        }\n        float _4968 = (_4931 * _4944) * _4958;\n        if (!(_4968 > 0.0f))\n        {\n            continue;\n        }\n        float3 _4981 = min(_4820 + float3(_4917, _4921, _4925), _4811);\n        int _5001 = int(((_4744.x + _4981.x) + (_4739.x * (_4981.y + (_4739.y * _4981.z)))) + 0.5f);\n        float2 _5016 = float2(float(_5001 % _4841) * 10.0f, 1024.0f + (float(_5001 / _4841) * 11.0f));\n        float2 param_4 = _5016 + float2(9.5f, 10.5f);\n        float4 _5024 = fa_gi_fetch(param_4);\n        bool _5027 = _5024.y < 0.5f;\n        bool _5036;\n        if (!_5027)\n        {\n            _5036 = _5024.x > _4749.y;\n        }\n        else\n        {\n            _5036 = _5027;\n        }\n        if (_5036)\n        {\n            continue;\n        }\n        float3 _5048 = _4836 - (_4774 + (_4981 * _4767));\n        float _5051 = length(_5048);\n        float3 _5057 = _5048 / max(_5051, 9.9999997473787516355514526367188e-05f).xxx;\n        float _5067 = max(9.9999997473787516355514526367188e-05f, (dot(-_5057, n) + 1.0f) * 0.5f);\n        float w = _4968 * (_5067 * _5067);\n        float3 param_5 = _5057;\n        float2 param_6 = (_5016 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _5087 = fa_gi_fetch(param_6);\n        float _5094 = _5051 / max(_4744.z, 9.9999997473787516355514526367188e-05f);\n        float _5097 = _5087.x;\n        if (_5094 > _5097)\n        {\n            float _5110 = max(_5087.y - (_5097 * _5097), 0.0f);\n            float _5115 = _5094 - _5097;\n            float _5124 = _5110 / max(_5110 + (_5115 * _5115), 9.9999999600419720025001879548654e-13f);\n            w *= ((_5124 * _5124) * _5124);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _5016 + float2(0.5f, 10.5f);\n        float2 param_8 = _5016 + float2(1.5f, 10.5f);\n        float2 param_9 = _5016 + float2(2.5f, 10.5f);\n        float2 param_10 = _5016 + float2(3.5f, 10.5f);\n        float2 param_11 = _5016 + float2(4.5f, 10.5f);\n        float2 param_12 = _5016 + float2(5.5f, 10.5f);\n        float2 param_13 = _5016 + float2(6.5f, 10.5f);\n        float2 param_14 = _5016 + float2(7.5f, 10.5f);\n        float2 param_15 = _5016 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _4846)) + (fa_gi_fetch(param_9).xyz * _4850)) + (fa_gi_fetch(param_10).xyz * _4854)) + (fa_gi_fetch(param_11).xyz * _4861)) + (fa_gi_fetch(param_12).xyz * _4868)) + (fa_gi_fetch(param_13).xyz * _4877)) + (fa_gi_fetch(param_14).xyz * _4884)) + (fa_gi_fetch(param_15).xyz * _4897)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_4796 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _5252;\n    if (_427_fa_gi.z > 0.5f)\n    {\n        _5252 = _4749.x;\n    }\n    else\n    {\n        _5252 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_4744.w * _5252);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _5276 = normalize(_427_fa_camera_pos.xyz - fa_world_pos);\n    int _5281 = int(_427_fa_gi.x + 0.5f);\n    int _5286 = int(_427_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _5286) && (k < 8); k++)\n    {\n        int param = _5281 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _5276;\n        float3 _5311 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5316 = param_3 * left;\n        acc += (_5311 * _5316);\n        left -= _5316;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_427_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _5345 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5345;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_427_fa_gi_px.x > 0.5f)\n    {\n        float4 _5387 = float4(fa_world_pos, 1.0f);\n        float2 _5406 = float2(dot(_427_fa_ct_vpx, _5387), dot(_427_fa_ct_vpy, _5387)) / max(dot(_427_fa_ct_vpw, _5387), 9.9999997473787516355514526367188e-05f).xx;\n        float _5415;\n        if (_427_fa_ct_a.y > 0.5f)\n        {\n            _5415 = (_5406.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5415 = 0.5f - (_5406.y * 0.5f);\n        }\n        return fa_lightmap.Load(int3(clamp(int2(float2((_5406.x * 0.5f) + 0.5f, _5415) * _427_fa_ct_a.zw), int2(0, 0), int2(_427_fa_ct_a.zw) - int2(1, 1)), 0)).xyz;\n    }\n    if (_427_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _427_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_427_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return float3(0.0f, ambientColor.y, 0.0f);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_427_fa_cl_info.x) + int(_427_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_427_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4181;\n    if (fa_lm.z > 0.5f)\n    {\n        _4181 = 0.0f;\n    }\n    else\n    {\n        _4181 = 1.0f - clamp(_427_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4192 = _4181 < 1.0f;\n    bool _4198;\n    if (_4192)\n    {\n        int param = li;\n        _4198 = fa_light_baked(param);\n    }\n    else\n    {\n        _4198 = _4192;\n    }\n    return _4198 ? _4181 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _605 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _618 = (c - (ru * hx)) - p;\n        float3 _624 = ru * (2.0f * hx);\n        float _630 = max(dot(_624, _624), 9.9999999392252902907785028219223e-09f);\n        float _634 = dot(_618, _624);\n        float t = clamp((-_634) / _630, 0.0f, 1.0f);\n        if (_605)\n        {\n            float _649 = dot(r, _624);\n            float _655 = _630 - (_649 * _649);\n            if (abs(_655) > (9.9999997473787516355514526367188e-06f * _630))\n            {\n                t = clamp(((dot(r, _618) * _649) - _634) / _655, 0.0f, 1.0f);\n            }\n        }\n        return (p + _618) + (_624 * t);\n    }\n    float3 q = p;\n    float _687 = dot(r, axis);\n    bool _695;\n    if (_605)\n    {\n        _695 = abs(_687) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _695 = _605;\n    }\n    if (_695)\n    {\n        float _705 = dot(c - p, axis) / _687;\n        if (_705 > 0.0f)\n        {\n            q = p + (r * _705);\n        }\n    }\n    float3 _718 = q - c;\n    float2 xy = float2(dot(_718, ru), dot(_718, uu));\n    if (shape > 0.5f)\n    {\n        float _733 = length(xy);\n        if (_733 > hx)\n        {\n            xy *= (hx / _733);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _486_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _486_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _525 = dot(d, right);\n    float _529 = dot(d, up);\n    float _540;\n    if (((_525 * _525) + (_529 * _529)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _540 = atan2(_529, _525) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _540 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_540 - floor(_540)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _375 = abs(d);\n    float _377 = _375.x;\n    float _379 = _375.y;\n    bool _380 = _377 >= _379;\n    bool _388;\n    if (_380)\n    {\n        _388 = _377 >= _375.z;\n    }\n    else\n    {\n        _388 = _380;\n    }\n    int _389;\n    if (_388)\n    {\n        _389 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _404;\n        if (_379 >= _375.z)\n        {\n            _404 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _404 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _389 = _404;\n    }\n    return _389;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _771 = fa_light_base(param);\n    bool _775 = _427_fa_ambient.w > 4.5f;\n    int param_1 = _771;\n    float4 _779 = fa_light_texel(param_1);\n    int param_2 = _771 + 1;\n    float4 _784 = fa_light_texel(param_2);\n    float _787 = _784.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _799 = _775 && (_787 > 2.5f);\n    fa_light_is_area = _799;\n    bool _801 = _787 < 0.5f;\n    float3 l;\n    if (_801)\n    {\n        l = normalize(_779.xyz);\n        if (_775)\n        {\n            int param_3 = _771 + 6;\n            float4 _815 = fa_light_texel(param_3);\n            if (_815.z > 0.5f)\n            {\n                int param_4 = _771 + 4;\n                float4 _825 = fa_light_texel(param_4);\n                int param_5 = _771 + 5;\n                float4 _830 = fa_light_texel(param_5);\n                float2 param_6 = _815.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _825.xyz) * _825.w, (-dot(world_pos, _830.xyz)) * _830.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _860 = _779.xyz;\n        float3 _862 = _860 - world_pos;\n        float3 to_light = _862;\n        float _865 = length(_862);\n        float reach = _865;\n        bool front = true;\n        if (_799)\n        {\n            int param_8 = _771 + 7;\n            reach = max(_865 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _771 + 4;\n            float4 _889 = fa_light_texel(param_9);\n            int param_10 = _771 + 5;\n            float4 _894 = fa_light_texel(param_10);\n            int param_11 = _771 + 6;\n            float4 _899 = fa_light_texel(param_11);\n            float _900 = _899.w;\n            int param_12 = _771 + 2;\n            float3 _907 = normalize(fa_light_texel(param_12).xyz);\n            bool _909 = _900 > 1.5f;\n            bool _917;\n            if (!_909)\n            {\n                _917 = dot(_907, to_light) < 0.0f;\n            }\n            else\n            {\n                _917 = _909;\n            }\n            front = _917;\n            float3 r = 0.0f.xxx;\n            float3 _926 = _427_fa_camera_pos.xyz - world_pos;\n            bool _930 = dot(n, n) > 0.5f;\n            bool _938;\n            if (_930)\n            {\n                _938 = dot(_926, _926) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _938 = _930;\n            }\n            if (_938)\n            {\n                r = reflect(-normalize(_926), normalize(n));\n            }\n            float3 param_13 = _860;\n            float3 param_14 = _907;\n            float3 param_15 = _889.xyz;\n            float3 param_16 = _894.xyz;\n            float param_17 = _889.w;\n            float param_18 = _894.w;\n            float param_19 = _900;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _974 = length(to_light);\n        dist = _974;\n        l = to_light / max(_974, 9.9999997473787516355514526367188e-05f).xxx;\n        float _988 = reach / max(_779.w, 0.001000000047497451305389404296875f);\n        float _994 = clamp(1.0f - (_988 * _988), 0.0f, 1.0f);\n        float _996;\n        if (front)\n        {\n            _996 = _994 * _994;\n        }\n        else\n        {\n            _996 = 0.0f;\n        }\n        atten = _996;\n        bool _1007 = _787 < 2.5f;\n        if ((_787 > 1.5f) && _1007)\n        {\n            int param_22 = _771 + 2;\n            float4 _1015 = fa_light_texel(param_22);\n            float _1025 = _1015.w;\n            int param_23 = _771 + 3;\n            float4 _1030 = fa_light_texel(param_23);\n            float _1031 = _1030.x;\n            float cos_inner = _1031;\n            if (_1031 > 1.5f)\n            {\n                cos_inner = lerp(_1025, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1025, cos_inner, dot(-l, normalize(_1015.xyz)));\n        }\n        if (_775 && (_787 < 1.5f))\n        {\n            int param_24 = _771 + 6;\n            float4 _1055 = fa_light_texel(param_24);\n            if (_1055.z > 0.5f)\n            {\n                float3 _1063 = -to_light;\n                int param_25 = _771 + 4;\n                int param_26 = _771 + 5;\n                float3 _1077 = fa_light_texel(param_25).xyz;\n                float3 _1081 = fa_light_texel(param_26).xyz;\n                float3 _1090 = float3(dot(_1063, _1077), dot(_1063, _1081), dot(_1063, cross(_1077, _1081)));\n                float3 param_27 = _1090;\n                int _1094 = fa_cube_face(param_27);\n                int param_28 = _1094;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1121 = float2(dot(_1090, cross(param_29, param_30)), dot(_1090, param_30)) / max(dot(_1090, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1125 = _1094 / 3;\n                float2 param_31 = _1055.xy + (float2(float(_1094 - (_1125 * 3)), float(_1125)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1121.x), 0.5f - (0.5f * _1121.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _771 + 7;\n            float4 _1155 = fa_light_texel(param_33);\n            if (_1155.z > 0.5f)\n            {\n                int param_34 = _771 + 2;\n                int param_35 = _771 + 4;\n                int param_36 = _771 + 5;\n                float2 param_37 = _1155.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_775 && _1007)\n            {\n                int param_42 = _771 + 6;\n                float4 _1202 = fa_light_texel(param_42);\n                int param_43 = _771 + 7;\n                float4 _1207 = fa_light_texel(param_43);\n                bool _1210 = _1202.z > 0.5f;\n                bool _1217;\n                if (!_1210)\n                {\n                    _1217 = _1207.z > 0.5f;\n                }\n                else\n                {\n                    _1217 = _1210;\n                }\n                if (_1217)\n                {\n                    int param_44 = _771 + 2;\n                    float4 _1224 = fa_light_texel(param_44);\n                    float3 _1228 = normalize(_1224.xyz);\n                    int param_45 = _771 + 4;\n                    float4 _1233 = fa_light_texel(param_45);\n                    int param_46 = _771 + 5;\n                    float4 _1238 = fa_light_texel(param_46);\n                    if (_1210)\n                    {\n                        float3 _1246 = -to_light;\n                        float _1253 = _1224.w;\n                        float _1269 = 0.5f / max(dot(_1246, _1228) * (sqrt(max(1.0f - (_1253 * _1253), 0.0f)) / max(_1253, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1202.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1246, _1233.xyz) * _1269), 0.5f - (dot(_1246, _1238.xyz) * _1269));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1207.z > 0.5f)\n                    {\n                        float2 param_49 = _1207.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1228;\n                        float3 param_52 = _1233.xyz;\n                        float3 param_53 = _1238.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6136 = _784.xyz * atten;\n    if (_775)\n    {\n        _6136 *= fa_light_tint;\n    }\n    int _1337;\n    if (_801)\n    {\n        _1337 = 0;\n    }\n    else\n    {\n        _1337 = ((_787 > 1.5f) && (_787 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _6147 = { l, _6136, atten, 1.0f, dist, _1337 };\n    return _6147;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2126 = fa_shadow_depth(param, param_1);\n    float _2130;\n    if (conv.x < 0.5f)\n    {\n        _2130 = _2126;\n    }\n    else\n    {\n        _2130 = (conv.y * conv.z) / (conv.z - (_2126 * (conv.z - conv.y)));\n    }\n    return _2130;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2176 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2182 = float2(cos(_2176), sin(_2176));\n    float2 dir = _2182;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2191;\n        if (k < 0.0f)\n        {\n            _2191 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2191 = k;\n        }\n        float _2210 = clamp((_2191 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2229 = sqrt((float(i) + 0.5f) * 0.0625f) * _2210;\n            float2 param_3 = uv + (dir * (_2079_fa_shadow_bias.zw * _2229));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2243 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2243 < (zr - (_2229 * plane)))\n            {\n                sum += _2243;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2271 = sum / cnt;\n        float _2281;\n        if (k < 0.0f)\n        {\n            _2281 = (-k) / max(_2271, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2281 = k;\n        }\n        radius = clamp(((max(zr - _2271, 0.0f) * unit) * _2281) / texel_m, 1.5f, 16.0f);\n        dir = _2182;\n    }\n    float lit = 0.0f;\n    int _2307 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2307; i_1++)\n    {\n        float _2326 = sqrt((float(i_1) + 0.5f) / float(_2307)) * radius;\n        float2 param_7 = uv + (dir * (_2079_fa_shadow_bias.zw * _2326));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2326 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2307);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2531 = _427_fa_pbr.z < 0.5f;\n    bool _2538;\n    if (!_2531)\n    {\n        _2538 = _2079_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2538 = _2531;\n    }\n    if (_2538)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2079_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2551 = fa_light_texel(param);\n    float _2552 = _2551.x;\n    if (_2552 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2561 = int(_2552 + 0.5f);\n    int param_1 = _2561;\n    float4 _2565 = fa_light_texel(param_1);\n    int param_2 = _2561 + 1;\n    float4 _2570 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2573 = _2565.y;\n    if (_2573 > 0.0f)\n    {\n        float _2590 = 1.0f - smoothstep(0.75f * _2573, _2573, length(world - _2079_fa_shadow_eye.xyz));\n        fade = _2590;\n        if (_2590 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2565.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2614 = (_2561 + 2) + (face * 6);\n    int param_4 = _2614;\n    int param_5 = _2614 + 1;\n    int param_6 = _2614 + 3;\n    float4 _2628 = fa_light_texel(param_6);\n    int param_7 = _2614 + 4;\n    float4 _2633 = fa_light_texel(param_7);\n    int param_8 = _2614 + 5;\n    float4 _2638 = fa_light_texel(param_8);\n    float _2650 = _2638.x * max(dot(_2628, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2655 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2678 = clamp(dot(n, _2628.xyz), -1.0f, 1.0f);\n    float _2697 = min(sqrt(1.0f - (_2678 * _2678)) / max(abs(dot(n, world - lpos)) / max(dot(_2628, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2700 = _2570.y;\n    float _2702;\n    if (_2700 > 0.0f)\n    {\n        _2702 = _2700;\n    }\n    else\n    {\n        _2702 = 1.5f * _2650;\n    }\n    float4 _2722 = float4(world + (n * (_2702 * sqrt(1.0f - (_2655 * _2655)))), 1.0f);\n    float _2726 = dot(_2628, _2722);\n    float _2729 = _2638.y;\n    if (_2726 < _2729)\n    {\n        return 1.0f;\n    }\n    float2 _2744 = float2(dot(fa_light_texel(param_4), _2722), dot(fa_light_texel(param_5), _2722)) / _2726.xx;\n    float _2746 = _2744.x;\n    bool _2749 = _2746 < _2633.x;\n    bool _2758;\n    if (!_2749)\n    {\n        _2758 = _2746 > _2633.z;\n    }\n    else\n    {\n        _2758 = _2749;\n    }\n    bool _2767;\n    if (!_2758)\n    {\n        _2767 = _2744.y < _2633.y;\n    }\n    else\n    {\n        _2767 = _2758;\n    }\n    bool _2776;\n    if (!_2767)\n    {\n        _2776 = _2744.y > _2633.w;\n    }\n    else\n    {\n        _2776 = _2767;\n    }\n    if (_2776)\n    {\n        return 1.0f;\n    }\n    float _2782 = _2570.x;\n    float _2784;\n    if (_2782 > 0.0f)\n    {\n        _2784 = _2782;\n    }\n    else\n    {\n        _2784 = 1.5f * _2650;\n    }\n    float2 param_9 = _2744;\n    float4 param_10 = _2633;\n    float param_11 = _2726 - (_2784 * (1.0f + (0.5f * _2697)));\n    float param_12 = _2650;\n    float param_13 = 1.0f;\n    float param_14 = _2638.z * 0.25f;\n    float param_15 = (_2650 * min(_2697, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2729, _2638.z);\n    int param_17 = int(_2565.z + 0.5f);\n    float param_18 = _2565.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _3296 = _427_fa_ct_b.w > 0.5f;\n    bool _3302;\n    if (_3296)\n    {\n        _3302 = _427_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3302 = _3296;\n    }\n    bool _3308;\n    if (_3302)\n    {\n        _3308 = _2079_fa_shadow_lcfg.x > 0.5f;\n    }\n    else\n    {\n        _3308 = _3302;\n    }\n    if (_3308)\n    {\n        int param = (int(_2079_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n        float4 _3320 = fa_light_texel(param);\n        float _3321 = _3320.z;\n        if (_3321 > 0.5f)\n        {\n            float _3334 = dot(_427_fa_ct_fwd.xyz, world) + _427_fa_ct_fwd.w;\n            float _3337 = fwidth(_3334);\n            float _3341 = min(1.5f * _3337, 0.100000001490116119384765625f * _3334);\n            float4 _3347 = float4(world, 1.0f);\n            float _3352 = dot(_427_fa_ct_vpw, _3347);\n            if (_3352 > 9.9999997473787516355514526367188e-05f)\n            {\n                float2 _3369 = float2(dot(_427_fa_ct_vpx, _3347), dot(_427_fa_ct_vpy, _3347)) / _3352.xx;\n                float _3374 = (_3369.x * 0.5f) + 0.5f;\n                float _3378;\n                if (_427_fa_ct_a.y > 0.5f)\n                {\n                    _3378 = (_3369.y * 0.5f) + 0.5f;\n                }\n                else\n                {\n                    _3378 = 0.5f - (_3369.y * 0.5f);\n                }\n                bool _3394 = _3374 >= 0.0f;\n                bool _3400;\n                if (_3394)\n                {\n                    _3400 = _3374 < 1.0f;\n                }\n                else\n                {\n                    _3400 = _3394;\n                }\n                bool _3406;\n                if (_3400)\n                {\n                    _3406 = _3378 >= 0.0f;\n                }\n                else\n                {\n                    _3406 = _3400;\n                }\n                bool _3412;\n                if (_3406)\n                {\n                    _3412 = _3378 < 1.0f;\n                }\n                else\n                {\n                    _3412 = _3406;\n                }\n                if (_3412)\n                {\n                    int2 _3429 = int2(_427_fa_ct_a.zw) - int2(1, 1);\n                    int2 _3430 = clamp(int2(float2(_3374, _3378) * _427_fa_ct_a.zw), int2(0, 0), _3429);\n                    int2 _3442;\n                    int2 _3448;\n                    int2 _3455;\n                    float _3506;\n                    float _3527;\n                    for (int k = 0; k < 5; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3442 = int2(0, 0);\n                        }\n                        else\n                        {\n                            if (k == 1)\n                            {\n                                _3448 = int2(1, 0);\n                            }\n                            else\n                            {\n                                if (k == 2)\n                                {\n                                    _3455 = int2(-1, 0);\n                                }\n                                else\n                                {\n                                    bool2 _3466 = (k == 3).xx;\n                                    _3455 = int2(_3466.x ? int2(0, 1).x : int2(0, -1).x, _3466.y ? int2(0, 1).y : int2(0, -1).y);\n                                }\n                                _3448 = _3455;\n                            }\n                            _3442 = _3448;\n                        }\n                        float4 _3483 = fa_screen_tex.Load(int3(clamp(_3430 + _3442, int2(0, 0), _3429), 0));\n                        bool _3486 = _3483.w > 0.5f;\n                        bool _3500;\n                        if (_3486)\n                        {\n                            _3500 = abs(_3334 - _3483.x) <= (((0.00200000009499490261077880859375f * _3334) + 0.00999999977648258209228515625f) + _3341);\n                        }\n                        else\n                        {\n                            _3500 = _3486;\n                        }\n                        if (_3500)\n                        {\n                            if (_3321 < 1.5f)\n                            {\n                                _3506 = 1.0f;\n                            }\n                            else\n                            {\n                                _3506 = (_3321 < 2.5f) ? 256.0f : 65536.0f;\n                            }\n                            float _3523 = mod(floor(_3483.z / _3506), 256.0f) * 0.0039215688593685626983642578125f;\n                            if (_427_fa_ct_b.z > 0.5f)\n                            {\n                                int param_1 = li;\n                                float3 param_2 = lpos;\n                                float3 param_3 = world;\n                                float3 param_4 = n;\n                                float3 param_5 = l;\n                                _3527 = min(_3523, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                            }\n                            else\n                            {\n                                _3527 = _3523;\n                            }\n                            return _3527;\n                        }\n                    }\n                }\n            }\n            float _3552;\n            if (_427_fa_ct_b.z > 0.5f)\n            {\n                int param_6 = li;\n                float3 param_7 = lpos;\n                float3 param_8 = world;\n                float3 param_9 = n;\n                float3 param_10 = l;\n                _3552 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3552 = 1.0f;\n            }\n            return _3552;\n        }\n    }\n    int param_11 = li;\n    float3 param_12 = lpos;\n    float3 param_13 = world;\n    float3 param_14 = n;\n    float3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2069;\n    if (i == 0)\n    {\n        _2069 = _2079_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2085;\n        if (i == 1)\n        {\n            _2085 = _2079_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2093;\n            if (i == 2)\n            {\n                _2093 = _2079_fa_shadow_split.z;\n            }\n            else\n            {\n                _2093 = _2079_fa_shadow_split.w;\n            }\n            _2085 = _2093;\n        }\n        _2069 = _2085;\n    }\n    return _2069;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2372 = max(_2079_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2377 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2383 = sqrt(1.0f - (_2377 * _2377));\n    float _2391 = min(_2383 / max(_2377, 0.20000000298023223876953125f), 4.0f);\n    float _2396;\n    if (_2079_fa_shadow_bias.y > 0.0f)\n    {\n        _2396 = _2079_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2396 = 1.5f * _2079_fa_shadow_info[ci].x;\n    }\n    float4 _2421 = mul(float4(world + (n * (_2396 * _2383)), 1.0f), _2079_fa_shadow_mat[ci]);\n    float _2428 = _2421.x;\n    bool _2431 = _2428 < _2079_fa_shadow_rect[ci].x;\n    bool _2440;\n    if (!_2431)\n    {\n        _2440 = _2428 > _2079_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2440 = _2431;\n    }\n    bool _2449;\n    if (!_2440)\n    {\n        _2449 = _2421.y < _2079_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2449 = _2440;\n    }\n    bool _2458;\n    if (!_2449)\n    {\n        _2458 = _2421.y > _2079_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2458 = _2449;\n    }\n    bool _2465;\n    if (!_2458)\n    {\n        _2465 = _2421.z > 1.0f;\n    }\n    else\n    {\n        _2465 = _2458;\n    }\n    if (_2465)\n    {\n        return -1.0f;\n    }\n    float _2473;\n    if (_2079_fa_shadow_bias.x > 0.0f)\n    {\n        _2473 = _2079_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2473 = 1.5f * _2079_fa_shadow_info[ci].x;\n    }\n    float2 param = _2421.xy;\n    float4 param_1 = _2079_fa_shadow_rect[ci];\n    float param_2 = _2421.z - ((_2473 * (1.0f + (0.5f * _2391))) / _2372);\n    float param_3 = _2079_fa_shadow_info[ci].x;\n    float param_4 = _2372;\n    float param_5 = _2372 * 0.25f;\n    float param_6 = ((_2079_fa_shadow_info[ci].x * min(_2391, 3.0f)) * 0.5f) / _2372;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2079_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2079_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_427_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2851 = int(_2079_fa_shadow_cfg.x + 0.5f);\n    if (_2851 < 1)\n    {\n        return 1.0f;\n    }\n    float _2866 = dot(world - _2079_fa_shadow_eye.xyz, _2079_fa_shadow_fwd.xyz);\n    int param = _2851 - 1;\n    if (_2866 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2878 = _2851 > 1;\n    bool _2885;\n    if (_2878)\n    {\n        _2885 = _2866 > _2079_fa_shadow_split.x;\n    }\n    else\n    {\n        _2885 = _2878;\n    }\n    if (_2885)\n    {\n        ci = 1;\n    }\n    bool _2889 = _2851 > 2;\n    bool _2896;\n    if (_2889)\n    {\n        _2896 = _2866 > _2079_fa_shadow_split.y;\n    }\n    else\n    {\n        _2896 = _2889;\n    }\n    if (_2896)\n    {\n        ci = 2;\n    }\n    bool _2900 = _2851 > 3;\n    bool _2907;\n    if (_2900)\n    {\n        _2907 = _2866 > _2079_fa_shadow_split.z;\n    }\n    else\n    {\n        _2907 = _2900;\n    }\n    if (_2907)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _2918 = min(_2851, 4);\n    float _2959;\n    for (int c = ci; c < _2918; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2938 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _2938;\n            break;\n        }\n        if (_2938 < 0.0f)\n        {\n            continue;\n        }\n        s = _2938;\n        ci = c;\n        if (_2079_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2959 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2959 = _2079_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _2978 = _2079_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2959, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_2866 - (fa_shadow_split_at(param_7) - _2978)) / _2978, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3010;\n        if ((ci + 1) < _2851)\n        {\n            _3010 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3010 = 1.0f;\n        }\n        s = lerp(s, _3010, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    bool _3115 = _427_fa_ct_b.y > 0.5f;\n    bool _3121;\n    if (_3115)\n    {\n        _3121 = _427_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3121 = _3115;\n    }\n    if (_3121)\n    {\n        float _3135 = dot(_427_fa_ct_fwd.xyz, fa_world_pos) + _427_fa_ct_fwd.w;\n        float _3138 = fwidth(_3135);\n        float4 _3148 = float4(fa_world_pos, 1.0f);\n        float _3154 = dot(_427_fa_ct_vpw, _3148);\n        if (_3154 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _3173 = float2(dot(_427_fa_ct_vpx, _3148), dot(_427_fa_ct_vpy, _3148)) / _3154.xx;\n            float _3178 = (_3173.x * 0.5f) + 0.5f;\n            float _3182;\n            if (_427_fa_ct_a.y > 0.5f)\n            {\n                _3182 = (_3173.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _3182 = 0.5f - (_3173.y * 0.5f);\n            }\n            bool _3198 = _3178 >= 0.0f;\n            bool _3204;\n            if (_3198)\n            {\n                _3204 = _3178 < 1.0f;\n            }\n            else\n            {\n                _3204 = _3198;\n            }\n            bool _3210;\n            if (_3204)\n            {\n                _3210 = _3182 >= 0.0f;\n            }\n            else\n            {\n                _3210 = _3204;\n            }\n            bool _3216;\n            if (_3210)\n            {\n                _3216 = _3182 < 1.0f;\n            }\n            else\n            {\n                _3216 = _3210;\n            }\n            if (_3216)\n            {\n                float4 _3242 = fa_screen_tex.Load(int3(clamp(int2(float2(_3178, _3182) * _427_fa_ct_a.zw), int2(0, 0), int2(_427_fa_ct_a.zw) - int2(1, 1)), 0));\n                bool _3245 = _3242.w > 0.5f;\n                bool _3261;\n                if (_3245)\n                {\n                    _3261 = abs(_3135 - _3242.x) <= (((0.00200000009499490261077880859375f * _3135) + 0.00999999977648258209228515625f) + min(1.5f * _3138, 0.100000001490116119384765625f * _3135));\n                }\n                else\n                {\n                    _3261 = _3245;\n                }\n                if (_3261)\n                {\n                    float _3267;\n                    if (_427_fa_ct_b.z > 0.5f)\n                    {\n                        float3 param = fa_world_pos;\n                        float3 param_1 = n;\n                        float3 param_2 = l;\n                        _3267 = min(_3242.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3267 = _3242.y;\n                    }\n                    return _3267;\n                }\n            }\n        }\n    }\n    float3 param_3 = fa_world_pos;\n    float3 param_4 = n;\n    float3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3923 = _427_fa_ct_a.x < 0.5f;\n    bool _3930;\n    if (!_3923)\n    {\n        _3930 = _2079_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3930 = _3923;\n    }\n    if (_3930)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2079_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3943 = fa_light_texel(param);\n    float _3944 = _3943.y;\n    float len = _3944;\n    if (_3944 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3956 = length(world - _427_fa_camera_pos.xyz);\n    float _3965 = 1.0f - smoothstep(0.5f * _427_fa_ct_b.x, _427_fa_ct_b.x, _3956);\n    if (_3965 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3971 = len;\n    float _3974 = min(_3971, 0.89999997615814208984375f * dist);\n    len = _3974;\n    float _3980 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3956);\n    float _3985 = _3980 + (0.5f * _3974);\n    float3 _3991 = world + (gn * _3980);\n    float _3993 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4055;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4009 = (float(k) + _3993) * 0.083333335816860198974609375f;\n        float3 _4017 = _3991 + (l * (_4009 * len));\n        float4 _4023 = float4(_4017, 1.0f);\n        float _4028 = dot(_427_fa_ct_vpw, _4023);\n        if (_4028 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4046 = float2(dot(_427_fa_ct_vpx, _4023), dot(_427_fa_ct_vpy, _4023)) / _4028.xx;\n        float _4050 = _4046.x * 0.5f;\n        float _4051 = _4050 + 0.5f;\n        if (_427_fa_ct_a.y > 0.5f)\n        {\n            _4055 = (_4046.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4055 = 0.5f - (_4046.y * 0.5f);\n        }\n        bool _4071 = _4051 < 0.0f;\n        bool _4078;\n        if (!_4071)\n        {\n            _4078 = _4051 >= 1.0f;\n        }\n        else\n        {\n            _4078 = _4071;\n        }\n        bool _4085;\n        if (!_4078)\n        {\n            _4085 = _4055 < 0.0f;\n        }\n        else\n        {\n            _4085 = _4078;\n        }\n        bool _4092;\n        if (!_4085)\n        {\n            _4092 = _4055 >= 1.0f;\n        }\n        else\n        {\n            _4092 = _4085;\n        }\n        if (_4092)\n        {\n            break;\n        }\n        float4 _4116 = fa_screen_tex.Load(int3(clamp(int2(float2(_4051, _4055) * _427_fa_ct_a.zw), int2(0, 0), int2(_427_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_4116.w < 0.5f)\n        {\n            continue;\n        }\n        float _4134 = (dot(_427_fa_ct_fwd.xyz, _4017) + _427_fa_ct_fwd.w) - _4116.x;\n        if ((_4134 > _3980) && (_4134 < _3985))\n        {\n            occ = max(occ, (1.0f - (_4009 * _4009)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4051, 0.5f - _4050), min(_4055, 1.0f - _4055))));\n        }\n    }\n    return 1.0f - (occ * _3965);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4237 = fa_baked_keep(param);\n    if (_4237 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _6160 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6160;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4263 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6162 = _4263.color;\n    float _6163 = _4263.attenuation;\n    float _6164 = _4263.shadow;\n    bool _4266 = _4263.type == 0;\n    if (_4266 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4263.direction;\n        float _4277 = fa_shadow_factor(param_5, param_6);\n        _6164 = _4277;\n        _6162 *= _4277;\n    }\n    else\n    {\n        bool _4288 = _4263.type != 0;\n        bool _4294;\n        if (_4288)\n        {\n            _4294 = _6163 > 0.0f;\n        }\n        else\n        {\n            _4294 = _4288;\n        }\n        if (_4294)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4263.direction;\n            float _4313 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6164 = _4313;\n            _6162 *= _4313;\n        }\n    }\n    bool _4323 = _427_fa_ct_a.x > 0.5f;\n    bool _4329;\n    if (_4323)\n    {\n        _4329 = _6163 > 0.0f;\n    }\n    else\n    {\n        _4329 = _4323;\n    }\n    if (_4329)\n    {\n        float _4336;\n        if (_4266)\n        {\n            _4336 = 1000000000.0f;\n        }\n        else\n        {\n            _4336 = _4263._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4263.direction;\n        float param_18 = _4336;\n        float _4354 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6164 *= _4354;\n        _6162 *= _4354;\n    }\n    float _4367 = _6163;\n    float _4368 = _4367 * _4237;\n    _6163 = _4368;\n    float3 _4372 = _6162;\n    float3 _4373 = _4372 * _4237;\n    _6162 = _4373;\n    LightSample _6179 = { _4263.direction, _4373, _4368, _6164, _4263._distance, _4263.type };\n    return _6179;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2079_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3038 = int(_2079_fa_shadow_cfg.x + 0.5f);\n    float _3048 = dot(world - _2079_fa_shadow_eye.xyz, _2079_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3053 = _3038 > 0;\n    bool _3062;\n    if (_3053)\n    {\n        int param = _3038 - 1;\n        _3062 = _3048 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3062 = _3053;\n    }\n    if (_3062)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3068 = _3038 > 1;\n        bool _3075;\n        if (_3068)\n        {\n            _3075 = _3048 > _2079_fa_shadow_split.x;\n        }\n        else\n        {\n            _3075 = _3068;\n        }\n        if (_3075)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3081 = _3038 > 2;\n        bool _3088;\n        if (_3081)\n        {\n            _3088 = _3048 > _2079_fa_shadow_split.y;\n        }\n        else\n        {\n            _3088 = _3081;\n        }\n        if (_3088)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3094 = _3038 > 3;\n        bool _3101;\n        if (_3094)\n        {\n            _3101 = _3048 > _2079_fa_shadow_split.z;\n        }\n        else\n        {\n            _3101 = _3094;\n        }\n        if (_3101)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5954 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5954 = -_5954;\n    }\n    float3 _5528 = normalize(_427_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5967 = { fa_world_pos, _5954, fa_world_tangent, fa_uv, fa_vertex_color, _5528, gl_FrontFacing };\n    SurfaceInput param_1 = _5967;\n    Surface _5536 = fa_standard_surface(param_1);\n    float3 _5993 = _5536.albedo;\n    float _5994 = _5536.alpha;\n    float3 _5995 = _5536.normal;\n    float _5996 = _5536.metallic;\n    float _5997 = _5536.roughness;\n    float _5998 = _5536.occlusion;\n    float3 _5999 = _5536.emission;\n    float _6000 = _5536.clearcoat;\n    float _6001 = _5536.clearcoat_roughness;\n    float3 _6002 = _5536.sheen_color;\n    float _6003 = _5536.sheen_roughness;\n    float _6004 = _5536.anisotropy;\n    float _6005 = _5536.anisotropy_rotation;\n    float _6006 = _5536.specular;\n    float _6007 = _5536.ior;\n    float3 _6008 = _5536.specular_color;\n    float _6009 = _5536.transmission;\n    float _6010 = _5536.thickness;\n    float3 _6011 = _5536.attenuation_color;\n    float _6012 = _5536.attenuation_distance;\n    SurfaceInput _5975 = { fa_world_pos, _5954, fa_world_tangent, fa_uv, fa_vertex_color, _5528, gl_FrontFacing };\n    SurfaceInput param_2 = _5975;\n    Surface param_3 = _5536;\n    surface(param_2, param_3);\n    _5993 = param_3.albedo;\n    _5994 = param_3.alpha;\n    _5995 = param_3.normal;\n    _5996 = param_3.metallic;\n    _5997 = param_3.roughness;\n    _5998 = param_3.occlusion;\n    _5999 = param_3.emission;\n    _6000 = param_3.clearcoat;\n    _6001 = param_3.clearcoat_roughness;\n    _6002 = param_3.sheen_color;\n    _6003 = param_3.sheen_roughness;\n    _6004 = param_3.anisotropy;\n    _6005 = param_3.anisotropy_rotation;\n    _6006 = param_3.specular;\n    _6007 = param_3.ior;\n    _6008 = param_3.specular_color;\n    _6009 = param_3.transmission;\n    _6010 = param_3.thickness;\n    _6011 = param_3.attenuation_color;\n    _6012 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5954;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5993 = param_6;\n    _5995 = param_7;\n    float3 result;\n    if (_427_fa_emissive.w > 0.5f)\n    {\n        result = _5993;\n    }\n    else\n    {\n        float3 _5575 = _5995;\n        float3 _5576 = normalize(_5575);\n        _5995 = _5576;\n        float3 param_8 = _5576;\n        SurfaceInput _5983 = { fa_world_pos, _5954, fa_world_tangent, fa_uv, fa_vertex_color, _5528, gl_FrontFacing };\n        SurfaceInput param_9 = _5983;\n        Surface _6094 = { _5993, _5994, _5995, _5996, _5997, _5998, _5999, _6000, _6001, _6002, _6003, _6004, _6005, _6006, _6007, _6008, _6009, _6010, _6011, _6012 };\n        Surface param_10 = _6094;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _5595 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5595; ln++)\n        {\n            int param_12 = ln;\n            int _5608 = fa_cl_light(param_12);\n            int param_13 = _5608;\n            if (fa_baked_keep(param_13) <= 0.0f)\n            {\n                continue;\n            }\n            int param_14 = _5608;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _5954;\n            LightSample _5624 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _5991 = { fa_world_pos, _5954, fa_world_tangent, fa_uv, fa_vertex_color, _5528, gl_FrontFacing };\n            SurfaceInput param_17 = _5991;\n            Surface _6115 = { _5993, _5994, _5995, _5996, _5997, _5998, _5999, _6000, _6001, _6002, _6003, _6004, _6005, _6006, _6007, _6008, _6009, _6010, _6011, _6012 };\n            Surface param_18 = _6115;\n            LightSample param_19 = _5624;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _5639 = result;\n    float3 _5640 = _5639 + _5999;\n    result = _5640;\n    float3 param_20 = _5640;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _5649 = _427_fa_fog.w > 0.0f;\n    bool _5656;\n    if (!_5649)\n    {\n        _5656 = _427_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5656 = _5649;\n    }\n    if (_5656)\n    {\n        float3 _5665 = fa_world_pos - _427_fa_camera_pos.xyz;\n        float _5671 = dot(_5665, _427_fa_fog_c.xyz);\n        bool _5675 = _427_fa_fog_c.w > 0.5f;\n        float _5676;\n        if (_5675)\n        {\n            _5676 = _5671;\n        }\n        else\n        {\n            _5676 = length(_5665);\n        }\n        float _5688 = _5676 - _427_fa_fog_b.x;\n        if (_5688 > 0.0f)\n        {\n            float _5697 = _427_fa_fog.w * _5688;\n            float tau = _5697 * _5697;\n            if (_427_fa_fog_b.y > 0.0f)\n            {\n                float _5713;\n                if (_5675)\n                {\n                    _5713 = fa_world_pos.y - (_427_fa_fog_c.y * _5671);\n                }\n                else\n                {\n                    _5713 = _427_fa_camera_pos.y;\n                }\n                float _5734 = lerp(_5713, fa_world_pos.y, clamp(_427_fa_fog_b.x / _5676, 0.0f, 1.0f));\n                float _5738 = fa_world_pos.y - _5734;\n                float _5743 = _5734 - _427_fa_fog_b.z;\n                float _5748 = fa_world_pos.y - _427_fa_fog_b.z;\n                bool _5751 = _5743 <= 0.0f;\n                bool _5752 = !_5751;\n                bool _5758;\n                if (_5752)\n                {\n                    _5758 = _427_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5758 = _5751;\n                }\n                float _5759;\n                if (_5758)\n                {\n                    _5759 = _427_fa_fog_b.y;\n                }\n                else\n                {\n                    _5759 = _427_fa_fog_b.y * exp(-min(_427_fa_fog_b.w * _5743, 80.0f));\n                }\n                bool _5786;\n                if (_5752)\n                {\n                    _5786 = _427_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5786 = _5751;\n                }\n                float _5787;\n                if (_5786)\n                {\n                    _5787 = _427_fa_fog_b.y * _5743;\n                }\n                else\n                {\n                    _5787 = (_427_fa_fog_b.y * (1.0f - exp(-min(_427_fa_fog_b.w * _5743, 80.0f)))) / _427_fa_fog_b.w;\n                }\n                bool _5812 = _5748 <= 0.0f;\n                bool _5819;\n                if (!_5812)\n                {\n                    _5819 = _427_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5819 = _5812;\n                }\n                float _5820;\n                if (_5819)\n                {\n                    _5820 = _427_fa_fog_b.y * _5748;\n                }\n                else\n                {\n                    _5820 = (_427_fa_fog_b.y * (1.0f - exp(-min(_427_fa_fog_b.w * _5748, 80.0f)))) / _427_fa_fog_b.w;\n                }\n                float _5847;\n                if (abs(_5738) < 0.001000000047497451305389404296875f)\n                {\n                    _5847 = _5759;\n                }\n                else\n                {\n                    _5847 = (_5820 - _5787) / _5738;\n                }\n                tau += (_5688 * max(_5847, 0.0f));\n            }\n            result = lerp(result, _427_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5994);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_427",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2079",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _427_fa_camera_pos : packoffset(c0);\n    float4 _427_fa_ambient : packoffset(c1);\n    float4 _427_fa_base_color : packoffset(c2);\n    float4 _427_fa_emissive : packoffset(c3);\n    float4 _427_fa_model_emissive : packoffset(c4);\n    float4 _427_fa_pbr : packoffset(c5);\n    float4 _427_fa_maps : packoffset(c6);\n    float4 _427_fa_fog : packoffset(c7);\n    float4 _427_fa_fog_b : packoffset(c8);\n    float4 _427_fa_fog_c : packoffset(c9);\n    float4 _427_fa_counts : packoffset(c10);\n    float4 _427_fa_env_sky : packoffset(c11);\n    float4 _427_fa_env_horizon : packoffset(c12);\n    float4 _427_fa_time : packoffset(c13);\n    float4 _427_fa_cl_vpx : packoffset(c14);\n    float4 _427_fa_cl_vpy : packoffset(c15);\n    float4 _427_fa_cl_vpw : packoffset(c16);\n    float4 _427_fa_cl_fwd : packoffset(c17);\n    float4 _427_fa_cl_grid : packoffset(c18);\n    float4 _427_fa_cl_info : packoffset(c19);\n    float4 _427_fa_layers_a : packoffset(c20);\n    float4 _427_fa_layers_b : packoffset(c21);\n    float4 _427_fa_layers_c : packoffset(c22);\n    float4 _427_fa_layers_d : packoffset(c23);\n    float4 _427_fa_ct_a : packoffset(c24);\n    float4 _427_fa_ct_b : packoffset(c25);\n    float4 _427_fa_ct_vpx : packoffset(c26);\n    float4 _427_fa_ct_vpy : packoffset(c27);\n    float4 _427_fa_ct_vpw : packoffset(c28);\n    float4 _427_fa_ct_fwd : packoffset(c29);\n    float4 _427_fa_tr_a : packoffset(c30);\n    float4 _427_fa_tr_b : packoffset(c31);\n    float4 _427_fa_probe_sh[9] : packoffset(c32);\n    float4 _427_fa_atlas : packoffset(c41);\n    float4 _427_fa_rpa_tile : packoffset(c42);\n    float4 _427_fa_rpa_pos : packoffset(c43);\n    float4 _427_fa_rpa_bx : packoffset(c44);\n    float4 _427_fa_rpa_by : packoffset(c45);\n    float4 _427_fa_rpa_bz : packoffset(c46);\n    float4 _427_fa_rpb_tile : packoffset(c47);\n    float4 _427_fa_rpb_pos : packoffset(c48);\n    float4 _427_fa_rpb_bx : packoffset(c49);\n    float4 _427_fa_rpb_by : packoffset(c50);\n    float4 _427_fa_rpb_bz : packoffset(c51);\n    float4 _427_fa_gi : packoffset(c52);\n    float4 _427_fa_gi_px : packoffset(c53);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2079_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2079_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2079_fa_shadow_info[4] : packoffset(c20);\n    float4 _2079_fa_shadow_split : packoffset(c24);\n    float4 _2079_fa_shadow_cfg : packoffset(c25);\n    float4 _2079_fa_shadow_bias : packoffset(c26);\n    float4 _2079_fa_shadow_eye : packoffset(c27);\n    float4 _2079_fa_shadow_fwd : packoffset(c28);\n    float4 _2079_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1355 = _427_fa_cl_info.x < 0.0f;\n    bool _1362;\n    if (!_1355)\n    {\n        _1362 = _427_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1362 = _1355;\n    }\n    bool _1370;\n    if (!_1362)\n    {\n        _1370 = _427_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1370 = _1362;\n    }\n    bool _1377;\n    if (!_1370)\n    {\n        _1377 = _427_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1377 = _1370;\n    }\n    bool _1384;\n    if (!_1377)\n    {\n        _1384 = _427_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1384 = _1377;\n    }\n    if (_1384)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1394 = float4(world_pos, 1.0f);\n    float _1400 = dot(_427_fa_cl_vpw, _1394);\n    if (!(_1400 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1422 = float2(dot(_427_fa_cl_vpx, _1394), dot(_427_fa_cl_vpy, _1394)) / _1400.xx;\n    int _1426 = int(_427_fa_cl_grid.x);\n    int _1430 = int(_427_fa_cl_grid.y);\n    int param = (int(_427_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_427_fa_cl_fwd.xyz, world_pos) + _427_fa_cl_fwd.w, _427_fa_cl_grid.w) / _427_fa_cl_grid.w) * _427_fa_cl_grid.z)), 0, int(_427_fa_cl_info.y) - 1) * _1430) + clamp(int(floor(((_1422.y * 0.5f) + 0.5f) * _427_fa_cl_grid.y)), 0, _1430 - 1)) * _1426)) + clamp(int(floor(((_1422.x * 0.5f) + 0.5f) * _427_fa_cl_grid.x)), 0, _1426 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1506 = fa_cluster_texel(param);\n    return int2(int(_1506.x), int(_1506.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_427_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4211 = fa_cluster_lookup(param);\n    fa_cl_slot = _4211.x;\n    fa_cl_local = _4211.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4421 = fa_linear_to_srgb(param);\n        c = _4421;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4429 = fa_srgb_to_linear(param_1);\n            c = _4429;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _309;\n    if (i.front_facing)\n    {\n        _309 = i.world_normal;\n    }\n    else\n    {\n        _309 = -i.world_normal;\n    }\n    float3 _333 = normalize(i.world_tangent.xyz - (_309 * dot(_309, i.world_tangent.xyz)));\n    float3 _360 = normalize(((_333 * m.x) + ((cross(_309, _333) * i.world_tangent.w) * m.y)) + (_309 * m.z));\n    float3 _363;\n    if (i.front_facing)\n    {\n        _363 = _360;\n    }\n    else\n    {\n        _363 = -_360;\n    }\n    return _363;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _427_fa_env_horizon.w);\n    float param = _427_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4461 = fa_tex_fix(param_2, param_3);\n    float4 _6366 = base_t;\n    _6366.x = _4461.x;\n    _6366.y = _4461.y;\n    _6366.z = _4461.z;\n    base_t = _6366;\n    float4 _4475 = (_6366 * _427_fa_base_color) * i.vertex_color;\n    float3 _6182 = i.world_normal;\n    if (_427_fa_maps.z > 0.5f)\n    {\n        float param_4 = _427_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _427_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4509 = fa_tex_fix(param_6, param_7);\n        float3 _4512 = (_4509 * 2.0f) - 1.0f.xxx;\n        float2 _4517 = _4512.xy * _427_fa_maps.x;\n        float3 _6374 = _4512;\n        _6374.x = _4517.x;\n        _6374.y = _4517.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6374;\n        _6182 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _427_fa_env_horizon.w);\n    float param_10 = _427_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4547 = fa_tex_fix(param_12, param_13);\n    float4 _6377 = mrt;\n    _6377.x = _4547.x;\n    _6377.y = _4547.y;\n    _6377.z = _4547.z;\n    mrt = _6377;\n    float4 _4577 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _427_fa_env_horizon.w);\n    float param_14 = _427_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4577.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4588 = fa_tex_fix(param_16, param_17);\n    float param_18 = _427_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _427_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4620 = fa_tex_fix(param_20, param_21);\n    float _6187 = _427_fa_layers_a.x;\n    float _6188 = _427_fa_layers_a.y;\n    float _6191 = _427_fa_layers_a.z;\n    float _6190 = _427_fa_layers_b.w;\n    float _6193 = _427_fa_layers_c.x;\n    if (_427_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_427_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6187 *= _4588.y;\n            _6188 *= _4588.z;\n            _6190 *= _4577.w;\n        }\n        if (_427_fa_layers_c.z > 1.5f)\n        {\n            _6191 *= mrt.x;\n            _6193 *= mrt.w;\n        }\n    }\n    Surface _6220 = { _4475.xyz, _4475.w, _6182, clamp(_427_fa_pbr.x * _4547.z, 0.0f, 1.0f), clamp(_427_fa_pbr.y * _4547.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_427_fa_maps.y * (_4588.x - 1.0f)), _427_fa_emissive.xyz + (_427_fa_model_emissive.xyz * _4620), _6187, _6188, _427_fa_layers_b.xyz, _6190, _6191, _427_fa_layers_a.w, _6193, _427_fa_layers_c.y, _427_fa_layers_d.xyz, _427_fa_tr_a.x, _427_fa_tr_a.y, _427_fa_tr_b.xyz, _427_fa_tr_a.z };\n    return _6220;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1586 = rect.zw - rect.xy;\n    float2 _1590 = _1586 * atlas;\n    float2 _1594 = ddx * _1590;\n    float2 _1598 = ddy * _1590;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1586), clamp(0.5f * log2(max(max(dot(_1594, _1594), dot(_1598, _1598)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1631 = _427_fa_counts.y < 0.5f;\n    bool _1638;\n    if (!_1631)\n    {\n        _1638 = _427_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1638 = _1631;\n    }\n    if (_1638)\n    {\n        return;\n    }\n    float3 _1644 = ddx(world_pos);\n    float3 _1647 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1651 = fa_cluster_texel(param);\n    int _1655 = int(_1651.w);\n    if (_1655 < 1)\n    {\n        return;\n    }\n    int _1665 = int(_427_fa_counts.y + 0.5f);\n    int param_1 = _1665;\n    float4 _1669 = fa_light_texel(param_1);\n    float2 _1672 = _1669.yz;\n    int _1676 = int(_1669.w);\n    int param_2 = _1665 + 1;\n    float4 _1681 = fa_light_texel(param_2);\n    float _1682 = _1681.x;\n    int _1688 = int(_427_fa_counts.w + 0.5f) - 1;\n    int _1692 = int(_1651.z);\n    float3 _1957;\n    for (int k = 0; k < _1655; k++)\n    {\n        int _1705 = _1692 + k;\n        int param_3 = _1676 + (_1705 >> 2);\n        int _1722 = (_1665 + 2) + (int(fa_light_texel(param_3)[_1705 & 3]) * 7);\n        int param_4 = _1722 + 6;\n        float4 _1727 = fa_light_texel(param_4);\n        if (((int(_1727.w + 0.5f) >> _1688) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1722;\n        float4 _1742 = fa_light_texel(param_5);\n        int param_6 = _1722 + 1;\n        float4 _1747 = fa_light_texel(param_6);\n        int param_7 = _1722 + 2;\n        float4 _1752 = fa_light_texel(param_7);\n        float3 _1755 = _1742.xyz;\n        float _1760 = dot(_1755, world_pos) + _1742.w;\n        float3 _1762 = _1747.xyz;\n        float _1767 = dot(_1762, world_pos) + _1747.w;\n        float3 _1769 = _1752.xyz;\n        float _1774 = dot(_1769, world_pos) + _1752.w;\n        bool _1779 = abs(_1760) > 0.5f;\n        bool _1787;\n        if (!_1779)\n        {\n            _1787 = abs(_1767) > 0.5f;\n        }\n        else\n        {\n            _1787 = _1779;\n        }\n        bool _1795;\n        if (!_1787)\n        {\n            _1795 = abs(_1774) > 0.5f;\n        }\n        else\n        {\n            _1795 = _1787;\n        }\n        if (_1795)\n        {\n            continue;\n        }\n        float _1810 = clamp(dot(geo_normal, normalize(_1769)) * _1727.z, 0.0f, 1.0f);\n        if (_1810 <= 0.0f)\n        {\n            continue;\n        }\n        float _1830 = (clamp((0.5f - abs(_1774)) * 10.0f, 0.0f, 1.0f) * _1810) * _1727.x;\n        float2 _1838 = float2(_1760 + 0.5f, 0.5f - _1767);\n        float2 _1848 = float2(dot(_1755, _1644), dot(_1762, _1644));\n        float2 _1858 = float2(dot(_1755, _1647), dot(_1762, _1647));\n        int param_8 = _1722 + 5;\n        float4 _1863 = fa_light_texel(param_8);\n        int param_9 = _1722 + 3;\n        float4 _1868 = fa_light_texel(param_9);\n        int param_10 = _1722 + 4;\n        float4 _1873 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1863.xyz;\n        bool _1883 = _1868.z > _1868.x;\n        if (_1883)\n        {\n            float4 param_11 = _1868;\n            float2 param_12 = _1838;\n            float2 param_13 = _1672;\n            float2 param_14 = _1848;\n            float2 param_15 = _1858;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1682 > 0.5f) && (_1682 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1909 = fa_dc_to_linear(param_16);\n                float4 _6270 = tx;\n                _6270.x = _1909.x;\n                _6270.y = _1909.y;\n                _6270.z = _1909.z;\n                tx = _6270;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1830 * tex_a) * _1863.w, 0.0f, 1.0f).xxx);\n        if (_1873.z > _1873.x)\n        {\n            float4 param_17 = _1873;\n            float2 param_18 = _1838;\n            float2 param_19 = _1672;\n            float2 param_20 = _1848;\n            float2 param_21 = _1858;\n            float4 _1953 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1682 > 1.5f)\n            {\n                float3 param_22 = _1953.xyz;\n                float3 _1963 = fa_dc_to_srgb(param_22);\n                _1957 = _1963;\n            }\n            else\n            {\n                _1957 = _1953.xyz;\n            }\n            float3 _1972 = (_1957 * 2.0f) - 1.0f.xxx;\n            float2 _1977 = _1972.xy * _1727.y;\n            float3 _1999 = (normalize(_1755) * _1977.x) + (normalize(_1762) * _1977.y);\n            float3 _2002 = normalize(normal);\n            normal = normalize(lerp(_2002, normalize((_2002 * max(_1972.z, 0.0500000007450580596923828125f)) + (_1999 - (_2002 * dot(_2002, _1999)))), clamp(_1830 * (_1883 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3733_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3733_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_427_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3674 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3674;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3783 = (1.0f - _427_fa_rpa_tile.w) - _427_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3789 = _427_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3783 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3789)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _427_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3783;\n            }\n        }\n        else\n        {\n            amb = _427_fa_ambient.xyz * _3783;\n        }\n    }\n    bool _3841 = _427_fa_rpa_tile.w > 0.0f;\n    if (_3841)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _427_fa_rpa_tile.xy;\n            float param_4 = _427_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _427_fa_rpa_tile.w);\n        }\n    }\n    bool _3872 = _427_fa_rpb_tile.w > 0.0f;\n    if (_3872)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _427_fa_rpb_tile.xy;\n            float param_7 = _427_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _427_fa_rpb_tile.w);\n        }\n    }\n    if ((_3789 || _3841) || _3872)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3694 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3697 = _3694.x;\n    float _3699 = _3694.z;\n    float2 e = float2(_3697, _3699);\n    if (_3694.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3699)) * ((_3697 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3697)) * ((_3699 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _4734 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _4739 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _4744 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _4749 = fa_light_texel(param_3);\n    bool _4752 = _4749.z < 0.5f;\n    bool _4760;\n    if (!_4752)\n    {\n        _4760 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _4760 = _4752;\n    }\n    if (_4760)\n    {\n        return 0.0f.xxx;\n    }\n    float _4767 = max(_4734.w, 9.9999997473787516355514526367188e-05f);\n    float3 _4770 = _4739.xyz;\n    float3 _4774 = _4734.xyz;\n    float3 _4778 = (fa_world_pos - _4774) / _4767.xxx;\n    float3 _4787 = min(_4778 + 0.5f.xxx, (_4770 - 0.5f.xxx) - _4778);\n    float _4796 = min(_4787.x, min(_4787.y, _4787.z));\n    if (!(_4796 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4811 = _4770 - 1.0f.xxx;\n    float3 _4812 = clamp(_4778, 0.0f.xxx, _4811);\n    float3 _4820 = min(floor(_4812), max(_4770 - 2.0f.xxx, 0.0f.xxx));\n    float3 _4824 = _4812 - _4820;\n    float3 _4836 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _4767));\n    int _4841 = int(_4744.y + 0.5f);\n    float _4846 = 0.3257350027561187744140625f * n.y;\n    float _4850 = 0.3257350027561187744140625f * n.z;\n    float _4854 = 0.3257350027561187744140625f * n.x;\n    float _4861 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _4868 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _4877 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _4884 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _4897 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _4904 = 8 + int(_4749.w);\n    float _4931;\n    float _4944;\n    float _4958;\n    for (int k = 0; k < _4904; k++)\n    {\n        float _4917 = float(k & 1);\n        float _4921 = float((k >> 1) & 1);\n        float _4925 = float((k >> 2) & 1);\n        if (_4917 > 0.5f)\n        {\n            _4931 = _4824.x;\n        }\n        else\n        {\n            _4931 = 1.0f - _4824.x;\n        }\n        if (_4921 > 0.5f)\n        {\n            _4944 = _4824.y;\n        }\n        else\n        {\n            _4944 = 1.0f - _4824.y;\n        }\n        if (_4925 > 0.5f)\n        {\n            _4958 = _4824.z;\n        }\n        else\n        {\n            _4958 = 1.0f - _4824.z;\n        }\n        float _4968 = (_4931 * _4944) * _4958;\n        if (!(_4968 > 0.0f))\n        {\n            continue;\n        }\n        float3 _4981 = min(_4820 + float3(_4917, _4921, _4925), _4811);\n        int _5001 = int(((_4744.x + _4981.x) + (_4739.x * (_4981.y + (_4739.y * _4981.z)))) + 0.5f);\n        float2 _5016 = float2(float(_5001 % _4841) * 10.0f, 1024.0f + (float(_5001 / _4841) * 11.0f));\n        float2 param_4 = _5016 + float2(9.5f, 10.5f);\n        float4 _5024 = fa_gi_fetch(param_4);\n        bool _5027 = _5024.y < 0.5f;\n        bool _5036;\n        if (!_5027)\n        {\n            _5036 = _5024.x > _4749.y;\n        }\n        else\n        {\n            _5036 = _5027;\n        }\n        if (_5036)\n        {\n            continue;\n        }\n        float3 _5048 = _4836 - (_4774 + (_4981 * _4767));\n        float _5051 = length(_5048);\n        float3 _5057 = _5048 / max(_5051, 9.9999997473787516355514526367188e-05f).xxx;\n        float _5067 = max(9.9999997473787516355514526367188e-05f, (dot(-_5057, n) + 1.0f) * 0.5f);\n        float w = _4968 * (_5067 * _5067);\n        float3 param_5 = _5057;\n        float2 param_6 = (_5016 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _5087 = fa_gi_fetch(param_6);\n        float _5094 = _5051 / max(_4744.z, 9.9999997473787516355514526367188e-05f);\n        float _5097 = _5087.x;\n        if (_5094 > _5097)\n        {\n            float _5110 = max(_5087.y - (_5097 * _5097), 0.0f);\n            float _5115 = _5094 - _5097;\n            float _5124 = _5110 / max(_5110 + (_5115 * _5115), 9.9999999600419720025001879548654e-13f);\n            w *= ((_5124 * _5124) * _5124);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _5016 + float2(0.5f, 10.5f);\n        float2 param_8 = _5016 + float2(1.5f, 10.5f);\n        float2 param_9 = _5016 + float2(2.5f, 10.5f);\n        float2 param_10 = _5016 + float2(3.5f, 10.5f);\n        float2 param_11 = _5016 + float2(4.5f, 10.5f);\n        float2 param_12 = _5016 + float2(5.5f, 10.5f);\n        float2 param_13 = _5016 + float2(6.5f, 10.5f);\n        float2 param_14 = _5016 + float2(7.5f, 10.5f);\n        float2 param_15 = _5016 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _4846)) + (fa_gi_fetch(param_9).xyz * _4850)) + (fa_gi_fetch(param_10).xyz * _4854)) + (fa_gi_fetch(param_11).xyz * _4861)) + (fa_gi_fetch(param_12).xyz * _4868)) + (fa_gi_fetch(param_13).xyz * _4877)) + (fa_gi_fetch(param_14).xyz * _4884)) + (fa_gi_fetch(param_15).xyz * _4897)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_4796 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _5252;\n    if (_427_fa_gi.z > 0.5f)\n    {\n        _5252 = _4749.x;\n    }\n    else\n    {\n        _5252 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_4744.w * _5252);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _5276 = normalize(_427_fa_camera_pos.xyz - fa_world_pos);\n    int _5281 = int(_427_fa_gi.x + 0.5f);\n    int _5286 = int(_427_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _5286) && (k < 8); k++)\n    {\n        int param = _5281 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _5276;\n        float3 _5311 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5316 = param_3 * left;\n        acc += (_5311 * _5316);\n        left -= _5316;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_427_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _5345 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5345;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_427_fa_gi_px.x > 0.5f)\n    {\n        float4 _5387 = float4(fa_world_pos, 1.0f);\n        float2 _5406 = float2(dot(_427_fa_ct_vpx, _5387), dot(_427_fa_ct_vpy, _5387)) / max(dot(_427_fa_ct_vpw, _5387), 9.9999997473787516355514526367188e-05f).xx;\n        float _5415;\n        if (_427_fa_ct_a.y > 0.5f)\n        {\n            _5415 = (_5406.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5415 = 0.5f - (_5406.y * 0.5f);\n        }\n        return fa_lightmap.Load(int3(clamp(int2(float2((_5406.x * 0.5f) + 0.5f, _5415) * _427_fa_ct_a.zw), int2(0, 0), int2(_427_fa_ct_a.zw) - int2(1, 1)), 0)).xyz;\n    }\n    if (_427_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _427_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_427_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return float3(0.0f, ambientColor.y, 0.0f);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_427_fa_cl_info.x) + int(_427_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_427_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4181;\n    if (fa_lm.z > 0.5f)\n    {\n        _4181 = 0.0f;\n    }\n    else\n    {\n        _4181 = 1.0f - clamp(_427_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4192 = _4181 < 1.0f;\n    bool _4198;\n    if (_4192)\n    {\n        int param = li;\n        _4198 = fa_light_baked(param);\n    }\n    else\n    {\n        _4198 = _4192;\n    }\n    return _4198 ? _4181 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _605 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _618 = (c - (ru * hx)) - p;\n        float3 _624 = ru * (2.0f * hx);\n        float _630 = max(dot(_624, _624), 9.9999999392252902907785028219223e-09f);\n        float _634 = dot(_618, _624);\n        float t = clamp((-_634) / _630, 0.0f, 1.0f);\n        if (_605)\n        {\n            float _649 = dot(r, _624);\n            float _655 = _630 - (_649 * _649);\n            if (abs(_655) > (9.9999997473787516355514526367188e-06f * _630))\n            {\n                t = clamp(((dot(r, _618) * _649) - _634) / _655, 0.0f, 1.0f);\n            }\n        }\n        return (p + _618) + (_624 * t);\n    }\n    float3 q = p;\n    float _687 = dot(r, axis);\n    bool _695;\n    if (_605)\n    {\n        _695 = abs(_687) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _695 = _605;\n    }\n    if (_695)\n    {\n        float _705 = dot(c - p, axis) / _687;\n        if (_705 > 0.0f)\n        {\n            q = p + (r * _705);\n        }\n    }\n    float3 _718 = q - c;\n    float2 xy = float2(dot(_718, ru), dot(_718, uu));\n    if (shape > 0.5f)\n    {\n        float _733 = length(xy);\n        if (_733 > hx)\n        {\n            xy *= (hx / _733);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _486_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _486_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _525 = dot(d, right);\n    float _529 = dot(d, up);\n    float _540;\n    if (((_525 * _525) + (_529 * _529)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _540 = atan2(_529, _525) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _540 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_540 - floor(_540)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _375 = abs(d);\n    float _377 = _375.x;\n    float _379 = _375.y;\n    bool _380 = _377 >= _379;\n    bool _388;\n    if (_380)\n    {\n        _388 = _377 >= _375.z;\n    }\n    else\n    {\n        _388 = _380;\n    }\n    int _389;\n    if (_388)\n    {\n        _389 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _404;\n        if (_379 >= _375.z)\n        {\n            _404 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _404 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _389 = _404;\n    }\n    return _389;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _771 = fa_light_base(param);\n    bool _775 = _427_fa_ambient.w > 4.5f;\n    int param_1 = _771;\n    float4 _779 = fa_light_texel(param_1);\n    int param_2 = _771 + 1;\n    float4 _784 = fa_light_texel(param_2);\n    float _787 = _784.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _799 = _775 && (_787 > 2.5f);\n    fa_light_is_area = _799;\n    bool _801 = _787 < 0.5f;\n    float3 l;\n    if (_801)\n    {\n        l = normalize(_779.xyz);\n        if (_775)\n        {\n            int param_3 = _771 + 6;\n            float4 _815 = fa_light_texel(param_3);\n            if (_815.z > 0.5f)\n            {\n                int param_4 = _771 + 4;\n                float4 _825 = fa_light_texel(param_4);\n                int param_5 = _771 + 5;\n                float4 _830 = fa_light_texel(param_5);\n                float2 param_6 = _815.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _825.xyz) * _825.w, (-dot(world_pos, _830.xyz)) * _830.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _860 = _779.xyz;\n        float3 _862 = _860 - world_pos;\n        float3 to_light = _862;\n        float _865 = length(_862);\n        float reach = _865;\n        bool front = true;\n        if (_799)\n        {\n            int param_8 = _771 + 7;\n            reach = max(_865 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _771 + 4;\n            float4 _889 = fa_light_texel(param_9);\n            int param_10 = _771 + 5;\n            float4 _894 = fa_light_texel(param_10);\n            int param_11 = _771 + 6;\n            float4 _899 = fa_light_texel(param_11);\n            float _900 = _899.w;\n            int param_12 = _771 + 2;\n            float3 _907 = normalize(fa_light_texel(param_12).xyz);\n            bool _909 = _900 > 1.5f;\n            bool _917;\n            if (!_909)\n            {\n                _917 = dot(_907, to_light) < 0.0f;\n            }\n            else\n            {\n                _917 = _909;\n            }\n            front = _917;\n            float3 r = 0.0f.xxx;\n            float3 _926 = _427_fa_camera_pos.xyz - world_pos;\n            bool _930 = dot(n, n) > 0.5f;\n            bool _938;\n            if (_930)\n            {\n                _938 = dot(_926, _926) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _938 = _930;\n            }\n            if (_938)\n            {\n                r = reflect(-normalize(_926), normalize(n));\n            }\n            float3 param_13 = _860;\n            float3 param_14 = _907;\n            float3 param_15 = _889.xyz;\n            float3 param_16 = _894.xyz;\n            float param_17 = _889.w;\n            float param_18 = _894.w;\n            float param_19 = _900;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _974 = length(to_light);\n        dist = _974;\n        l = to_light / max(_974, 9.9999997473787516355514526367188e-05f).xxx;\n        float _988 = reach / max(_779.w, 0.001000000047497451305389404296875f);\n        float _994 = clamp(1.0f - (_988 * _988), 0.0f, 1.0f);\n        float _996;\n        if (front)\n        {\n            _996 = _994 * _994;\n        }\n        else\n        {\n            _996 = 0.0f;\n        }\n        atten = _996;\n        bool _1007 = _787 < 2.5f;\n        if ((_787 > 1.5f) && _1007)\n        {\n            int param_22 = _771 + 2;\n            float4 _1015 = fa_light_texel(param_22);\n            float _1025 = _1015.w;\n            int param_23 = _771 + 3;\n            float4 _1030 = fa_light_texel(param_23);\n            float _1031 = _1030.x;\n            float cos_inner = _1031;\n            if (_1031 > 1.5f)\n            {\n                cos_inner = lerp(_1025, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1025, cos_inner, dot(-l, normalize(_1015.xyz)));\n        }\n        if (_775 && (_787 < 1.5f))\n        {\n            int param_24 = _771 + 6;\n            float4 _1055 = fa_light_texel(param_24);\n            if (_1055.z > 0.5f)\n            {\n                float3 _1063 = -to_light;\n                int param_25 = _771 + 4;\n                int param_26 = _771 + 5;\n                float3 _1077 = fa_light_texel(param_25).xyz;\n                float3 _1081 = fa_light_texel(param_26).xyz;\n                float3 _1090 = float3(dot(_1063, _1077), dot(_1063, _1081), dot(_1063, cross(_1077, _1081)));\n                float3 param_27 = _1090;\n                int _1094 = fa_cube_face(param_27);\n                int param_28 = _1094;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1121 = float2(dot(_1090, cross(param_29, param_30)), dot(_1090, param_30)) / max(dot(_1090, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1125 = _1094 / 3;\n                float2 param_31 = _1055.xy + (float2(float(_1094 - (_1125 * 3)), float(_1125)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1121.x), 0.5f - (0.5f * _1121.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _771 + 7;\n            float4 _1155 = fa_light_texel(param_33);\n            if (_1155.z > 0.5f)\n            {\n                int param_34 = _771 + 2;\n                int param_35 = _771 + 4;\n                int param_36 = _771 + 5;\n                float2 param_37 = _1155.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_775 && _1007)\n            {\n                int param_42 = _771 + 6;\n                float4 _1202 = fa_light_texel(param_42);\n                int param_43 = _771 + 7;\n                float4 _1207 = fa_light_texel(param_43);\n                bool _1210 = _1202.z > 0.5f;\n                bool _1217;\n                if (!_1210)\n                {\n                    _1217 = _1207.z > 0.5f;\n                }\n                else\n                {\n                    _1217 = _1210;\n                }\n                if (_1217)\n                {\n                    int param_44 = _771 + 2;\n                    float4 _1224 = fa_light_texel(param_44);\n                    float3 _1228 = normalize(_1224.xyz);\n                    int param_45 = _771 + 4;\n                    float4 _1233 = fa_light_texel(param_45);\n                    int param_46 = _771 + 5;\n                    float4 _1238 = fa_light_texel(param_46);\n                    if (_1210)\n                    {\n                        float3 _1246 = -to_light;\n                        float _1253 = _1224.w;\n                        float _1269 = 0.5f / max(dot(_1246, _1228) * (sqrt(max(1.0f - (_1253 * _1253), 0.0f)) / max(_1253, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1202.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1246, _1233.xyz) * _1269), 0.5f - (dot(_1246, _1238.xyz) * _1269));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1207.z > 0.5f)\n                    {\n                        float2 param_49 = _1207.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1228;\n                        float3 param_52 = _1233.xyz;\n                        float3 param_53 = _1238.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6136 = _784.xyz * atten;\n    if (_775)\n    {\n        _6136 *= fa_light_tint;\n    }\n    int _1337;\n    if (_801)\n    {\n        _1337 = 0;\n    }\n    else\n    {\n        _1337 = ((_787 > 1.5f) && (_787 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _6147 = { l, _6136, atten, 1.0f, dist, _1337 };\n    return _6147;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2126 = fa_shadow_depth(param, param_1);\n    float _2130;\n    if (conv.x < 0.5f)\n    {\n        _2130 = _2126;\n    }\n    else\n    {\n        _2130 = (conv.y * conv.z) / (conv.z - (_2126 * (conv.z - conv.y)));\n    }\n    return _2130;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2176 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2182 = float2(cos(_2176), sin(_2176));\n    float2 dir = _2182;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2191;\n        if (k < 0.0f)\n        {\n            _2191 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2191 = k;\n        }\n        float _2210 = clamp((_2191 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2229 = sqrt((float(i) + 0.5f) * 0.0625f) * _2210;\n            float2 param_3 = uv + (dir * (_2079_fa_shadow_bias.zw * _2229));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2243 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2243 < (zr - (_2229 * plane)))\n            {\n                sum += _2243;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2271 = sum / cnt;\n        float _2281;\n        if (k < 0.0f)\n        {\n            _2281 = (-k) / max(_2271, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2281 = k;\n        }\n        radius = clamp(((max(zr - _2271, 0.0f) * unit) * _2281) / texel_m, 1.5f, 16.0f);\n        dir = _2182;\n    }\n    float lit = 0.0f;\n    int _2307 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2307; i_1++)\n    {\n        float _2326 = sqrt((float(i_1) + 0.5f) / float(_2307)) * radius;\n        float2 param_7 = uv + (dir * (_2079_fa_shadow_bias.zw * _2326));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2326 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2307);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2531 = _427_fa_pbr.z < 0.5f;\n    bool _2538;\n    if (!_2531)\n    {\n        _2538 = _2079_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2538 = _2531;\n    }\n    if (_2538)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2079_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2551 = fa_light_texel(param);\n    float _2552 = _2551.x;\n    if (_2552 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2561 = int(_2552 + 0.5f);\n    int param_1 = _2561;\n    float4 _2565 = fa_light_texel(param_1);\n    int param_2 = _2561 + 1;\n    float4 _2570 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2573 = _2565.y;\n    if (_2573 > 0.0f)\n    {\n        float _2590 = 1.0f - smoothstep(0.75f * _2573, _2573, length(world - _2079_fa_shadow_eye.xyz));\n        fade = _2590;\n        if (_2590 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2565.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2614 = (_2561 + 2) + (face * 6);\n    int param_4 = _2614;\n    int param_5 = _2614 + 1;\n    int param_6 = _2614 + 3;\n    float4 _2628 = fa_light_texel(param_6);\n    int param_7 = _2614 + 4;\n    float4 _2633 = fa_light_texel(param_7);\n    int param_8 = _2614 + 5;\n    float4 _2638 = fa_light_texel(param_8);\n    float _2650 = _2638.x * max(dot(_2628, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2655 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2678 = clamp(dot(n, _2628.xyz), -1.0f, 1.0f);\n    float _2697 = min(sqrt(1.0f - (_2678 * _2678)) / max(abs(dot(n, world - lpos)) / max(dot(_2628, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2700 = _2570.y;\n    float _2702;\n    if (_2700 > 0.0f)\n    {\n        _2702 = _2700;\n    }\n    else\n    {\n        _2702 = 1.5f * _2650;\n    }\n    float4 _2722 = float4(world + (n * (_2702 * sqrt(1.0f - (_2655 * _2655)))), 1.0f);\n    float _2726 = dot(_2628, _2722);\n    float _2729 = _2638.y;\n    if (_2726 < _2729)\n    {\n        return 1.0f;\n    }\n    float2 _2744 = float2(dot(fa_light_texel(param_4), _2722), dot(fa_light_texel(param_5), _2722)) / _2726.xx;\n    float _2746 = _2744.x;\n    bool _2749 = _2746 < _2633.x;\n    bool _2758;\n    if (!_2749)\n    {\n        _2758 = _2746 > _2633.z;\n    }\n    else\n    {\n        _2758 = _2749;\n    }\n    bool _2767;\n    if (!_2758)\n    {\n        _2767 = _2744.y < _2633.y;\n    }\n    else\n    {\n        _2767 = _2758;\n    }\n    bool _2776;\n    if (!_2767)\n    {\n        _2776 = _2744.y > _2633.w;\n    }\n    else\n    {\n        _2776 = _2767;\n    }\n    if (_2776)\n    {\n        return 1.0f;\n    }\n    float _2782 = _2570.x;\n    float _2784;\n    if (_2782 > 0.0f)\n    {\n        _2784 = _2782;\n    }\n    else\n    {\n        _2784 = 1.5f * _2650;\n    }\n    float2 param_9 = _2744;\n    float4 param_10 = _2633;\n    float param_11 = _2726 - (_2784 * (1.0f + (0.5f * _2697)));\n    float param_12 = _2650;\n    float param_13 = 1.0f;\n    float param_14 = _2638.z * 0.25f;\n    float param_15 = (_2650 * min(_2697, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2729, _2638.z);\n    int param_17 = int(_2565.z + 0.5f);\n    float param_18 = _2565.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _3296 = _427_fa_ct_b.w > 0.5f;\n    bool _3302;\n    if (_3296)\n    {\n        _3302 = _427_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3302 = _3296;\n    }\n    bool _3308;\n    if (_3302)\n    {\n        _3308 = _2079_fa_shadow_lcfg.x > 0.5f;\n    }\n    else\n    {\n        _3308 = _3302;\n    }\n    if (_3308)\n    {\n        int param = (int(_2079_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n        float4 _3320 = fa_light_texel(param);\n        float _3321 = _3320.z;\n        if (_3321 > 0.5f)\n        {\n            float _3334 = dot(_427_fa_ct_fwd.xyz, world) + _427_fa_ct_fwd.w;\n            float _3337 = fwidth(_3334);\n            float _3341 = min(1.5f * _3337, 0.100000001490116119384765625f * _3334);\n            float4 _3347 = float4(world, 1.0f);\n            float _3352 = dot(_427_fa_ct_vpw, _3347);\n            if (_3352 > 9.9999997473787516355514526367188e-05f)\n            {\n                float2 _3369 = float2(dot(_427_fa_ct_vpx, _3347), dot(_427_fa_ct_vpy, _3347)) / _3352.xx;\n                float _3374 = (_3369.x * 0.5f) + 0.5f;\n                float _3378;\n                if (_427_fa_ct_a.y > 0.5f)\n                {\n                    _3378 = (_3369.y * 0.5f) + 0.5f;\n                }\n                else\n                {\n                    _3378 = 0.5f - (_3369.y * 0.5f);\n                }\n                bool _3394 = _3374 >= 0.0f;\n                bool _3400;\n                if (_3394)\n                {\n                    _3400 = _3374 < 1.0f;\n                }\n                else\n                {\n                    _3400 = _3394;\n                }\n                bool _3406;\n                if (_3400)\n                {\n                    _3406 = _3378 >= 0.0f;\n                }\n                else\n                {\n                    _3406 = _3400;\n                }\n                bool _3412;\n                if (_3406)\n                {\n                    _3412 = _3378 < 1.0f;\n                }\n                else\n                {\n                    _3412 = _3406;\n                }\n                if (_3412)\n                {\n                    int2 _3429 = int2(_427_fa_ct_a.zw) - int2(1, 1);\n                    int2 _3430 = clamp(int2(float2(_3374, _3378) * _427_fa_ct_a.zw), int2(0, 0), _3429);\n                    int2 _3442;\n                    int2 _3448;\n                    int2 _3455;\n                    float _3506;\n                    float _3527;\n                    for (int k = 0; k < 5; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3442 = int2(0, 0);\n                        }\n                        else\n                        {\n                            if (k == 1)\n                            {\n                                _3448 = int2(1, 0);\n                            }\n                            else\n                            {\n                                if (k == 2)\n                                {\n                                    _3455 = int2(-1, 0);\n                                }\n                                else\n                                {\n                                    bool2 _3466 = (k == 3).xx;\n                                    _3455 = int2(_3466.x ? int2(0, 1).x : int2(0, -1).x, _3466.y ? int2(0, 1).y : int2(0, -1).y);\n                                }\n                                _3448 = _3455;\n                            }\n                            _3442 = _3448;\n                        }\n                        float4 _3483 = fa_screen_tex.Load(int3(clamp(_3430 + _3442, int2(0, 0), _3429), 0));\n                        bool _3486 = _3483.w > 0.5f;\n                        bool _3500;\n                        if (_3486)\n                        {\n                            _3500 = abs(_3334 - _3483.x) <= (((0.00200000009499490261077880859375f * _3334) + 0.00999999977648258209228515625f) + _3341);\n                        }\n                        else\n                        {\n                            _3500 = _3486;\n                        }\n                        if (_3500)\n                        {\n                            if (_3321 < 1.5f)\n                            {\n                                _3506 = 1.0f;\n                            }\n                            else\n                            {\n                                _3506 = (_3321 < 2.5f) ? 256.0f : 65536.0f;\n                            }\n                            float _3523 = mod(floor(_3483.z / _3506), 256.0f) * 0.0039215688593685626983642578125f;\n                            if (_427_fa_ct_b.z > 0.5f)\n                            {\n                                int param_1 = li;\n                                float3 param_2 = lpos;\n                                float3 param_3 = world;\n                                float3 param_4 = n;\n                                float3 param_5 = l;\n                                _3527 = min(_3523, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                            }\n                            else\n                            {\n                                _3527 = _3523;\n                            }\n                            return _3527;\n                        }\n                    }\n                }\n            }\n            float _3552;\n            if (_427_fa_ct_b.z > 0.5f)\n            {\n                int param_6 = li;\n                float3 param_7 = lpos;\n                float3 param_8 = world;\n                float3 param_9 = n;\n                float3 param_10 = l;\n                _3552 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3552 = 1.0f;\n            }\n            return _3552;\n        }\n    }\n    int param_11 = li;\n    float3 param_12 = lpos;\n    float3 param_13 = world;\n    float3 param_14 = n;\n    float3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2069;\n    if (i == 0)\n    {\n        _2069 = _2079_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2085;\n        if (i == 1)\n        {\n            _2085 = _2079_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2093;\n            if (i == 2)\n            {\n                _2093 = _2079_fa_shadow_split.z;\n            }\n            else\n            {\n                _2093 = _2079_fa_shadow_split.w;\n            }\n            _2085 = _2093;\n        }\n        _2069 = _2085;\n    }\n    return _2069;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2372 = max(_2079_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2377 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2383 = sqrt(1.0f - (_2377 * _2377));\n    float _2391 = min(_2383 / max(_2377, 0.20000000298023223876953125f), 4.0f);\n    float _2396;\n    if (_2079_fa_shadow_bias.y > 0.0f)\n    {\n        _2396 = _2079_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2396 = 1.5f * _2079_fa_shadow_info[ci].x;\n    }\n    float4 _2421 = mul(float4(world + (n * (_2396 * _2383)), 1.0f), _2079_fa_shadow_mat[ci]);\n    float _2428 = _2421.x;\n    bool _2431 = _2428 < _2079_fa_shadow_rect[ci].x;\n    bool _2440;\n    if (!_2431)\n    {\n        _2440 = _2428 > _2079_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2440 = _2431;\n    }\n    bool _2449;\n    if (!_2440)\n    {\n        _2449 = _2421.y < _2079_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2449 = _2440;\n    }\n    bool _2458;\n    if (!_2449)\n    {\n        _2458 = _2421.y > _2079_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2458 = _2449;\n    }\n    bool _2465;\n    if (!_2458)\n    {\n        _2465 = _2421.z > 1.0f;\n    }\n    else\n    {\n        _2465 = _2458;\n    }\n    if (_2465)\n    {\n        return -1.0f;\n    }\n    float _2473;\n    if (_2079_fa_shadow_bias.x > 0.0f)\n    {\n        _2473 = _2079_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2473 = 1.5f * _2079_fa_shadow_info[ci].x;\n    }\n    float2 param = _2421.xy;\n    float4 param_1 = _2079_fa_shadow_rect[ci];\n    float param_2 = _2421.z - ((_2473 * (1.0f + (0.5f * _2391))) / _2372);\n    float param_3 = _2079_fa_shadow_info[ci].x;\n    float param_4 = _2372;\n    float param_5 = _2372 * 0.25f;\n    float param_6 = ((_2079_fa_shadow_info[ci].x * min(_2391, 3.0f)) * 0.5f) / _2372;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2079_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2079_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_427_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2851 = int(_2079_fa_shadow_cfg.x + 0.5f);\n    if (_2851 < 1)\n    {\n        return 1.0f;\n    }\n    float _2866 = dot(world - _2079_fa_shadow_eye.xyz, _2079_fa_shadow_fwd.xyz);\n    int param = _2851 - 1;\n    if (_2866 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2878 = _2851 > 1;\n    bool _2885;\n    if (_2878)\n    {\n        _2885 = _2866 > _2079_fa_shadow_split.x;\n    }\n    else\n    {\n        _2885 = _2878;\n    }\n    if (_2885)\n    {\n        ci = 1;\n    }\n    bool _2889 = _2851 > 2;\n    bool _2896;\n    if (_2889)\n    {\n        _2896 = _2866 > _2079_fa_shadow_split.y;\n    }\n    else\n    {\n        _2896 = _2889;\n    }\n    if (_2896)\n    {\n        ci = 2;\n    }\n    bool _2900 = _2851 > 3;\n    bool _2907;\n    if (_2900)\n    {\n        _2907 = _2866 > _2079_fa_shadow_split.z;\n    }\n    else\n    {\n        _2907 = _2900;\n    }\n    if (_2907)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _2918 = min(_2851, 4);\n    float _2959;\n    for (int c = ci; c < _2918; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2938 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _2938;\n            break;\n        }\n        if (_2938 < 0.0f)\n        {\n            continue;\n        }\n        s = _2938;\n        ci = c;\n        if (_2079_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2959 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2959 = _2079_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _2978 = _2079_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2959, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_2866 - (fa_shadow_split_at(param_7) - _2978)) / _2978, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3010;\n        if ((ci + 1) < _2851)\n        {\n            _3010 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3010 = 1.0f;\n        }\n        s = lerp(s, _3010, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    bool _3115 = _427_fa_ct_b.y > 0.5f;\n    bool _3121;\n    if (_3115)\n    {\n        _3121 = _427_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3121 = _3115;\n    }\n    if (_3121)\n    {\n        float _3135 = dot(_427_fa_ct_fwd.xyz, fa_world_pos) + _427_fa_ct_fwd.w;\n        float _3138 = fwidth(_3135);\n        float4 _3148 = float4(fa_world_pos, 1.0f);\n        float _3154 = dot(_427_fa_ct_vpw, _3148);\n        if (_3154 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _3173 = float2(dot(_427_fa_ct_vpx, _3148), dot(_427_fa_ct_vpy, _3148)) / _3154.xx;\n            float _3178 = (_3173.x * 0.5f) + 0.5f;\n            float _3182;\n            if (_427_fa_ct_a.y > 0.5f)\n            {\n                _3182 = (_3173.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _3182 = 0.5f - (_3173.y * 0.5f);\n            }\n            bool _3198 = _3178 >= 0.0f;\n            bool _3204;\n            if (_3198)\n            {\n                _3204 = _3178 < 1.0f;\n            }\n            else\n            {\n                _3204 = _3198;\n            }\n            bool _3210;\n            if (_3204)\n            {\n                _3210 = _3182 >= 0.0f;\n            }\n            else\n            {\n                _3210 = _3204;\n            }\n            bool _3216;\n            if (_3210)\n            {\n                _3216 = _3182 < 1.0f;\n            }\n            else\n            {\n                _3216 = _3210;\n            }\n            if (_3216)\n            {\n                float4 _3242 = fa_screen_tex.Load(int3(clamp(int2(float2(_3178, _3182) * _427_fa_ct_a.zw), int2(0, 0), int2(_427_fa_ct_a.zw) - int2(1, 1)), 0));\n                bool _3245 = _3242.w > 0.5f;\n                bool _3261;\n                if (_3245)\n                {\n                    _3261 = abs(_3135 - _3242.x) <= (((0.00200000009499490261077880859375f * _3135) + 0.00999999977648258209228515625f) + min(1.5f * _3138, 0.100000001490116119384765625f * _3135));\n                }\n                else\n                {\n                    _3261 = _3245;\n                }\n                if (_3261)\n                {\n                    float _3267;\n                    if (_427_fa_ct_b.z > 0.5f)\n                    {\n                        float3 param = fa_world_pos;\n                        float3 param_1 = n;\n                        float3 param_2 = l;\n                        _3267 = min(_3242.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3267 = _3242.y;\n                    }\n                    return _3267;\n                }\n            }\n        }\n    }\n    float3 param_3 = fa_world_pos;\n    float3 param_4 = n;\n    float3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3923 = _427_fa_ct_a.x < 0.5f;\n    bool _3930;\n    if (!_3923)\n    {\n        _3930 = _2079_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3930 = _3923;\n    }\n    if (_3930)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2079_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3943 = fa_light_texel(param);\n    float _3944 = _3943.y;\n    float len = _3944;\n    if (_3944 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3956 = length(world - _427_fa_camera_pos.xyz);\n    float _3965 = 1.0f - smoothstep(0.5f * _427_fa_ct_b.x, _427_fa_ct_b.x, _3956);\n    if (_3965 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3971 = len;\n    float _3974 = min(_3971, 0.89999997615814208984375f * dist);\n    len = _3974;\n    float _3980 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3956);\n    float _3985 = _3980 + (0.5f * _3974);\n    float3 _3991 = world + (gn * _3980);\n    float _3993 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4055;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4009 = (float(k) + _3993) * 0.083333335816860198974609375f;\n        float3 _4017 = _3991 + (l * (_4009 * len));\n        float4 _4023 = float4(_4017, 1.0f);\n        float _4028 = dot(_427_fa_ct_vpw, _4023);\n        if (_4028 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4046 = float2(dot(_427_fa_ct_vpx, _4023), dot(_427_fa_ct_vpy, _4023)) / _4028.xx;\n        float _4050 = _4046.x * 0.5f;\n        float _4051 = _4050 + 0.5f;\n        if (_427_fa_ct_a.y > 0.5f)\n        {\n            _4055 = (_4046.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4055 = 0.5f - (_4046.y * 0.5f);\n        }\n        bool _4071 = _4051 < 0.0f;\n        bool _4078;\n        if (!_4071)\n        {\n            _4078 = _4051 >= 1.0f;\n        }\n        else\n        {\n            _4078 = _4071;\n        }\n        bool _4085;\n        if (!_4078)\n        {\n            _4085 = _4055 < 0.0f;\n        }\n        else\n        {\n            _4085 = _4078;\n        }\n        bool _4092;\n        if (!_4085)\n        {\n            _4092 = _4055 >= 1.0f;\n        }\n        else\n        {\n            _4092 = _4085;\n        }\n        if (_4092)\n        {\n            break;\n        }\n        float4 _4116 = fa_screen_tex.Load(int3(clamp(int2(float2(_4051, _4055) * _427_fa_ct_a.zw), int2(0, 0), int2(_427_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_4116.w < 0.5f)\n        {\n            continue;\n        }\n        float _4134 = (dot(_427_fa_ct_fwd.xyz, _4017) + _427_fa_ct_fwd.w) - _4116.x;\n        if ((_4134 > _3980) && (_4134 < _3985))\n        {\n            occ = max(occ, (1.0f - (_4009 * _4009)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4051, 0.5f - _4050), min(_4055, 1.0f - _4055))));\n        }\n    }\n    return 1.0f - (occ * _3965);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4237 = fa_baked_keep(param);\n    if (_4237 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _6160 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6160;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4263 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6162 = _4263.color;\n    float _6163 = _4263.attenuation;\n    float _6164 = _4263.shadow;\n    bool _4266 = _4263.type == 0;\n    if (_4266 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4263.direction;\n        float _4277 = fa_shadow_factor(param_5, param_6);\n        _6164 = _4277;\n        _6162 *= _4277;\n    }\n    else\n    {\n        bool _4288 = _4263.type != 0;\n        bool _4294;\n        if (_4288)\n        {\n            _4294 = _6163 > 0.0f;\n        }\n        else\n        {\n            _4294 = _4288;\n        }\n        if (_4294)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4263.direction;\n            float _4313 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6164 = _4313;\n            _6162 *= _4313;\n        }\n    }\n    bool _4323 = _427_fa_ct_a.x > 0.5f;\n    bool _4329;\n    if (_4323)\n    {\n        _4329 = _6163 > 0.0f;\n    }\n    else\n    {\n        _4329 = _4323;\n    }\n    if (_4329)\n    {\n        float _4336;\n        if (_4266)\n        {\n            _4336 = 1000000000.0f;\n        }\n        else\n        {\n            _4336 = _4263._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4263.direction;\n        float param_18 = _4336;\n        float _4354 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6164 *= _4354;\n        _6162 *= _4354;\n    }\n    float _4367 = _6163;\n    float _4368 = _4367 * _4237;\n    _6163 = _4368;\n    float3 _4372 = _6162;\n    float3 _4373 = _4372 * _4237;\n    _6162 = _4373;\n    LightSample _6179 = { _4263.direction, _4373, _4368, _6164, _4263._distance, _4263.type };\n    return _6179;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2079_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3038 = int(_2079_fa_shadow_cfg.x + 0.5f);\n    float _3048 = dot(world - _2079_fa_shadow_eye.xyz, _2079_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3053 = _3038 > 0;\n    bool _3062;\n    if (_3053)\n    {\n        int param = _3038 - 1;\n        _3062 = _3048 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3062 = _3053;\n    }\n    if (_3062)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3068 = _3038 > 1;\n        bool _3075;\n        if (_3068)\n        {\n            _3075 = _3048 > _2079_fa_shadow_split.x;\n        }\n        else\n        {\n            _3075 = _3068;\n        }\n        if (_3075)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3081 = _3038 > 2;\n        bool _3088;\n        if (_3081)\n        {\n            _3088 = _3048 > _2079_fa_shadow_split.y;\n        }\n        else\n        {\n            _3088 = _3081;\n        }\n        if (_3088)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3094 = _3038 > 3;\n        bool _3101;\n        if (_3094)\n        {\n            _3101 = _3048 > _2079_fa_shadow_split.z;\n        }\n        else\n        {\n            _3101 = _3094;\n        }\n        if (_3101)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5954 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5954 = -_5954;\n    }\n    float3 _5528 = normalize(_427_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5967 = { fa_world_pos, _5954, fa_world_tangent, fa_uv, fa_vertex_color, _5528, gl_FrontFacing };\n    SurfaceInput param_1 = _5967;\n    Surface _5536 = fa_standard_surface(param_1);\n    float3 _5993 = _5536.albedo;\n    float _5994 = _5536.alpha;\n    float3 _5995 = _5536.normal;\n    float _5996 = _5536.metallic;\n    float _5997 = _5536.roughness;\n    float _5998 = _5536.occlusion;\n    float3 _5999 = _5536.emission;\n    float _6000 = _5536.clearcoat;\n    float _6001 = _5536.clearcoat_roughness;\n    float3 _6002 = _5536.sheen_color;\n    float _6003 = _5536.sheen_roughness;\n    float _6004 = _5536.anisotropy;\n    float _6005 = _5536.anisotropy_rotation;\n    float _6006 = _5536.specular;\n    float _6007 = _5536.ior;\n    float3 _6008 = _5536.specular_color;\n    float _6009 = _5536.transmission;\n    float _6010 = _5536.thickness;\n    float3 _6011 = _5536.attenuation_color;\n    float _6012 = _5536.attenuation_distance;\n    SurfaceInput _5975 = { fa_world_pos, _5954, fa_world_tangent, fa_uv, fa_vertex_color, _5528, gl_FrontFacing };\n    SurfaceInput param_2 = _5975;\n    Surface param_3 = _5536;\n    surface(param_2, param_3);\n    _5993 = param_3.albedo;\n    _5994 = param_3.alpha;\n    _5995 = param_3.normal;\n    _5996 = param_3.metallic;\n    _5997 = param_3.roughness;\n    _5998 = param_3.occlusion;\n    _5999 = param_3.emission;\n    _6000 = param_3.clearcoat;\n    _6001 = param_3.clearcoat_roughness;\n    _6002 = param_3.sheen_color;\n    _6003 = param_3.sheen_roughness;\n    _6004 = param_3.anisotropy;\n    _6005 = param_3.anisotropy_rotation;\n    _6006 = param_3.specular;\n    _6007 = param_3.ior;\n    _6008 = param_3.specular_color;\n    _6009 = param_3.transmission;\n    _6010 = param_3.thickness;\n    _6011 = param_3.attenuation_color;\n    _6012 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5954;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5993 = param_6;\n    _5995 = param_7;\n    float3 result;\n    if (_427_fa_emissive.w > 0.5f)\n    {\n        result = _5993;\n    }\n    else\n    {\n        float3 _5575 = _5995;\n        float3 _5576 = normalize(_5575);\n        _5995 = _5576;\n        float3 param_8 = _5576;\n        SurfaceInput _5983 = { fa_world_pos, _5954, fa_world_tangent, fa_uv, fa_vertex_color, _5528, gl_FrontFacing };\n        SurfaceInput param_9 = _5983;\n        Surface _6094 = { _5993, _5994, _5995, _5996, _5997, _5998, _5999, _6000, _6001, _6002, _6003, _6004, _6005, _6006, _6007, _6008, _6009, _6010, _6011, _6012 };\n        Surface param_10 = _6094;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _5595 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5595; ln++)\n        {\n            int param_12 = ln;\n            int _5608 = fa_cl_light(param_12);\n            int param_13 = _5608;\n            if (fa_baked_keep(param_13) <= 0.0f)\n            {\n                continue;\n            }\n            int param_14 = _5608;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _5954;\n            LightSample _5624 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _5991 = { fa_world_pos, _5954, fa_world_tangent, fa_uv, fa_vertex_color, _5528, gl_FrontFacing };\n            SurfaceInput param_17 = _5991;\n            Surface _6115 = { _5993, _5994, _5995, _5996, _5997, _5998, _5999, _6000, _6001, _6002, _6003, _6004, _6005, _6006, _6007, _6008, _6009, _6010, _6011, _6012 };\n            Surface param_18 = _6115;\n            LightSample param_19 = _5624;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _5639 = result;\n    float3 _5640 = _5639 + _5999;\n    result = _5640;\n    float3 param_20 = _5640;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _5649 = _427_fa_fog.w > 0.0f;\n    bool _5656;\n    if (!_5649)\n    {\n        _5656 = _427_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5656 = _5649;\n    }\n    if (_5656)\n    {\n        float3 _5665 = fa_world_pos - _427_fa_camera_pos.xyz;\n        float _5671 = dot(_5665, _427_fa_fog_c.xyz);\n        bool _5675 = _427_fa_fog_c.w > 0.5f;\n        float _5676;\n        if (_5675)\n        {\n            _5676 = _5671;\n        }\n        else\n        {\n            _5676 = length(_5665);\n        }\n        float _5688 = _5676 - _427_fa_fog_b.x;\n        if (_5688 > 0.0f)\n        {\n            float _5697 = _427_fa_fog.w * _5688;\n            float tau = _5697 * _5697;\n            if (_427_fa_fog_b.y > 0.0f)\n            {\n                float _5713;\n                if (_5675)\n                {\n                    _5713 = fa_world_pos.y - (_427_fa_fog_c.y * _5671);\n                }\n                else\n                {\n                    _5713 = _427_fa_camera_pos.y;\n                }\n                float _5734 = lerp(_5713, fa_world_pos.y, clamp(_427_fa_fog_b.x / _5676, 0.0f, 1.0f));\n                float _5738 = fa_world_pos.y - _5734;\n                float _5743 = _5734 - _427_fa_fog_b.z;\n                float _5748 = fa_world_pos.y - _427_fa_fog_b.z;\n                bool _5751 = _5743 <= 0.0f;\n                bool _5752 = !_5751;\n                bool _5758;\n                if (_5752)\n                {\n                    _5758 = _427_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5758 = _5751;\n                }\n                float _5759;\n                if (_5758)\n                {\n                    _5759 = _427_fa_fog_b.y;\n                }\n                else\n                {\n                    _5759 = _427_fa_fog_b.y * exp(-min(_427_fa_fog_b.w * _5743, 80.0f));\n                }\n                bool _5786;\n                if (_5752)\n                {\n                    _5786 = _427_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5786 = _5751;\n                }\n                float _5787;\n                if (_5786)\n                {\n                    _5787 = _427_fa_fog_b.y * _5743;\n                }\n                else\n                {\n                    _5787 = (_427_fa_fog_b.y * (1.0f - exp(-min(_427_fa_fog_b.w * _5743, 80.0f)))) / _427_fa_fog_b.w;\n                }\n                bool _5812 = _5748 <= 0.0f;\n                bool _5819;\n                if (!_5812)\n                {\n                    _5819 = _427_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5819 = _5812;\n                }\n                float _5820;\n                if (_5819)\n                {\n                    _5820 = _427_fa_fog_b.y * _5748;\n                }\n                else\n                {\n                    _5820 = (_427_fa_fog_b.y * (1.0f - exp(-min(_427_fa_fog_b.w * _5748, 80.0f)))) / _427_fa_fog_b.w;\n                }\n                float _5847;\n                if (abs(_5738) < 0.001000000047497451305389404296875f)\n                {\n                    _5847 = _5759;\n                }\n                else\n                {\n                    _5847 = (_5820 - _5787) / _5738;\n                }\n                tau += (_5688 * max(_5847, 0.0f));\n            }\n            result = lerp(result, _427_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5994);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_427",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2079",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _214_fa_camera_pos : packoffset(c0);\n    float4 _214_fa_ambient : packoffset(c1);\n    float4 _214_fa_base_color : packoffset(c2);\n    float4 _214_fa_emissive : packoffset(c3);\n    float4 _214_fa_model_emissive : packoffset(c4);\n    float4 _214_fa_pbr : packoffset(c5);\n    float4 _214_fa_maps : packoffset(c6);\n    float4 _214_fa_fog : packoffset(c7);\n    float4 _214_fa_fog_b : packoffset(c8);\n    float4 _214_fa_fog_c : packoffset(c9);\n    float4 _214_fa_counts : packoffset(c10);\n    float4 _214_fa_env_sky : packoffset(c11);\n    float4 _214_fa_env_horizon : packoffset(c12);\n    float4 _214_fa_time : packoffset(c13);\n    float4 _214_fa_cl_vpx : packoffset(c14);\n    float4 _214_fa_cl_vpy : packoffset(c15);\n    float4 _214_fa_cl_vpw : packoffset(c16);\n    float4 _214_fa_cl_fwd : packoffset(c17);\n    float4 _214_fa_cl_grid : packoffset(c18);\n    float4 _214_fa_cl_info : packoffset(c19);\n    float4 _214_fa_layers_a : packoffset(c20);\n    float4 _214_fa_layers_b : packoffset(c21);\n    float4 _214_fa_layers_c : packoffset(c22);\n    float4 _214_fa_layers_d : packoffset(c23);\n    float4 _214_fa_ct_a : packoffset(c24);\n    float4 _214_fa_ct_b : packoffset(c25);\n    float4 _214_fa_ct_vpx : packoffset(c26);\n    float4 _214_fa_ct_vpy : packoffset(c27);\n    float4 _214_fa_ct_vpw : packoffset(c28);\n    float4 _214_fa_ct_fwd : packoffset(c29);\n    float4 _214_fa_tr_a : packoffset(c30);\n    float4 _214_fa_tr_b : packoffset(c31);\n    float4 _214_fa_probe_sh[9] : packoffset(c32);\n    float4 _214_fa_atlas : packoffset(c41);\n    float4 _214_fa_rpa_tile : packoffset(c42);\n    float4 _214_fa_rpa_pos : packoffset(c43);\n    float4 _214_fa_rpa_bx : packoffset(c44);\n    float4 _214_fa_rpa_by : packoffset(c45);\n    float4 _214_fa_rpa_bz : packoffset(c46);\n    float4 _214_fa_rpb_tile : packoffset(c47);\n    float4 _214_fa_rpb_pos : packoffset(c48);\n    float4 _214_fa_rpb_bx : packoffset(c49);\n    float4 _214_fa_rpb_by : packoffset(c50);\n    float4 _214_fa_rpb_bz : packoffset(c51);\n    float4 _214_fa_gi : packoffset(c52);\n    float4 _214_fa_gi_px : packoffset(c53);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float2 fa_frag_velocity;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n    float2 fa_frag_velocity : SV_Target1;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w);\n    float param = _214_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _230 = fa_tex_fix(param_2, param_3);\n    float4 _889 = base_t;\n    _889.x = _230.x;\n    _889.y = _230.y;\n    _889.z = _230.z;\n    base_t = _889;\n    float4 _246 = (_889 * _214_fa_base_color) * i.vertex_color;\n    float3 _844 = i.world_normal;\n    if (_214_fa_maps.z > 0.5f)\n    {\n        float param_4 = _214_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _282 = fa_tex_fix(param_6, param_7);\n        float3 _286 = (_282 * 2.0f) - 1.0f.xxx;\n        float2 _291 = _286.xy * _214_fa_maps.x;\n        float3 _897 = _286;\n        _897.x = _291.x;\n        _897.y = _291.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _897;\n        _844 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w);\n    float param_10 = _214_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _322 = fa_tex_fix(param_12, param_13);\n    float4 _900 = mrt;\n    _900.x = _322.x;\n    _900.y = _322.y;\n    _900.z = _322.z;\n    mrt = _900;\n    float4 _354 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w);\n    float param_14 = _214_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _214_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _398 = fa_tex_fix(param_20, param_21);\n    float _849 = _214_fa_layers_a.x;\n    float _850 = _214_fa_layers_a.y;\n    float _853 = _214_fa_layers_a.z;\n    float _852 = _214_fa_layers_b.w;\n    float _855 = _214_fa_layers_c.x;\n    if (_214_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_214_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _849 *= _366.y;\n            _850 *= _366.z;\n            _852 *= _354.w;\n        }\n        if (_214_fa_layers_c.z > 1.5f)\n        {\n            _853 *= mrt.x;\n            _855 *= mrt.w;\n        }\n    }\n    Surface _882 = { _246.xyz, _246.w, _844, clamp(_214_fa_pbr.x * _322.z, 0.0f, 1.0f), clamp(_214_fa_pbr.y * _322.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_214_fa_maps.y * (_366.x - 1.0f)), _214_fa_emissive.xyz + (_214_fa_model_emissive.xyz * _398), _849, _850, _214_fa_layers_b.xyz, _852, _853, _214_fa_layers_a.w, _855, _214_fa_layers_c.y, _214_fa_layers_d.xyz, _214_fa_tr_a.x, _214_fa_tr_a.y, _214_fa_tr_b.xyz, _214_fa_tr_a.z };\n    return _882;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _739 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _739 = -_739;\n    }\n    float3 _550 = normalize(_214_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _752 = { fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing };\n    SurfaceInput param = _752;\n    SurfaceInput _760 = { fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing };\n    SurfaceInput param_1 = _760;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _565 = normalize(param_2.normal);\n    float3 _580 = normalize(float3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    float2 e = _580.xy / ((abs(_580.x) + abs(_580.y)) + abs(_592)).xx;\n    if (_592 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n    float2 motion = 1024.0f.xx;\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06f;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06f;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((float2(fa_vel_prev.x, -fa_vel_prev.y) / fa_vel_prev.z.xx) * 0.5f) - ((float2(fa_vel_cur.x, -fa_vel_cur.y) / fa_vel_cur.z.xx) * 0.5f), (-4.0f).xx, 4.0f.xx);\n    }\n    fa_frag_velocity = motion;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    fa_vel_cur = stage_input.fa_vel_cur;\n    fa_vel_prev = stage_input.fa_vel_prev;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    stage_output.fa_frag_velocity = fa_frag_velocity;\n    return stage_output;\n}\n",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _74_fa_view_proj : packoffset(c0);\n    row_major float4x4 _74_fa_light_vp : packoffset(c4);\n    float4 _74_fa_uv_scale : packoffset(c8);\n    float4 _74_fa_time : packoffset(c9);\n    float4 _74_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _213_fa_joint_rows[192] : packoffset(c0);\n};\n\ncbuffer fa_vel_params : register(b2)\n{\n    row_major float4x4 _470_fa_vel_vp : packoffset(c0);\n    row_major float4x4 _470_fa_vel_prev_vp : packoffset(c4);\n    float4 _470_fa_vel_on : packoffset(c8);\n};\n\nTexture2D<float4> fa_prev_pal_tex : register(t0);\nSamplerState fa_prev_pal_smp : register(s11);\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float4 fa_prev_r0;\nstatic float4 fa_prev_r1;\nstatic float4 fa_prev_r2;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    float4 fa_prev_r0 : TEXCOORD11;\n    float4 fa_prev_r1 : TEXCOORD12;\n    float4 fa_prev_r2 : TEXCOORD13;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _204 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_213_fa_joint_rows[_204] * weights[i]);\n        r1 += (_213_fa_joint_rows[_204 + 1] * weights[i]);\n        r2 += (_213_fa_joint_rows[_204 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat4 fa_time_now()\n{\n    return _74_fa_time;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _113 = cross(model[1].xyz, model[2].xyz);\n    float _117 = (dot(model[0].xyz, _113) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _713 = { mul(float4(position, 1.0f), model).xyz, (((_113 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _117, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _117), texcoord0 * _74_fa_uv_scale.xy, color, position };\n    return _713;\n}\n\nfloat4x4 fa_rows_to_mat4(float4 r0, float4 r1, float4 r2)\n{\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat4 fa_prev_pal_texel(int t)\n{\n    return fa_prev_pal_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4x4 fa_prev_skin_matrix(float4 joints, float4 weights, int base)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _332 = base + (int((joints[i] * 255.0f) + 0.5f) * 3);\n        int param = _332;\n        r0 += (fa_prev_pal_texel(param) * weights[i]);\n        int param_1 = _332 + 1;\n        r1 += (fa_prev_pal_texel(param_1) * weights[i]);\n        int param_2 = _332 + 2;\n        r2 += (fa_prev_pal_texel(param_2) * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat4x4 fa_prev_model()\n{\n    float4 param = fa_prev_r0;\n    float4 param_1 = fa_prev_r1;\n    float4 param_2 = fa_prev_r2;\n    float4 param_3 = fa_joints;\n    float4 param_4 = fa_weights;\n    int param_5 = int(_470_fa_vel_on.w + 0.5f);\n    return mul(fa_prev_skin_matrix(param_3, param_4, param_5), fa_rows_to_mat4(param, param_1, param_2));\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color, bool has_prev)\n{\n    bool _475;\n    if (has_prev)\n    {\n        _475 = _470_fa_vel_on.x > 0.5f;\n    }\n    else\n    {\n        _475 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _490 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _720 = _490.world_pos;\n    float4 _501 = float4(_720, 1.0f);\n    fa_world_pos = _720;\n    fa_world_normal = _490.world_normal;\n    fa_world_tangent = _490.world_tangent;\n    fa_uv = _490.uv;\n    fa_vertex_color = _490.color;\n    fa_pre_depth = -mul(_501, _74_fa_light_vp).z;\n    fa_pre_r0 = float3(_74_fa_light_vp[0].x, _74_fa_light_vp[1].x, _74_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_74_fa_light_vp[0].y, _74_fa_light_vp[1].y, _74_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_74_fa_light_vp[0].z, _74_fa_light_vp[1].z, _74_fa_light_vp[2].z);\n    gl_Position = mul(_501, _74_fa_view_proj);\n    fa_vel_cur = float3(0.0f, 0.0f, 1.0f);\n    fa_vel_prev = 0.0f.xxx;\n    if (_475)\n    {\n        float4 _574 = float4(position, 1.0f);\n        fa_vel_cur = float3(mul(_501, _470_fa_vel_vp).xyw);\n        fa_vel_prev = float3(mul(float4((_720 + mul(_574, fa_prev_model()).xyz) - mul(_574, model).xyz, 1.0f), _470_fa_vel_prev_vp).xyw);\n    }\n}\n\nvoid vert_main()\n{\n    fa_vtime = 0.0f.xxxx;\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    bool param_8 = _470_fa_vel_on.z > 0.5f;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_prev_r0 = stage_input.fa_prev_r0;\n    fa_prev_r1 = stage_input.fa_prev_r1;\n    fa_prev_r2 = stage_input.fa_prev_r2;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    stage_output.fa_vel_cur = fa_vel_cur;\n    stage_output.fa_vel_prev = fa_vel_prev;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _214_fa_camera_pos : packoffset(c0);\n    float4 _214_fa_ambient : packoffset(c1);\n    float4 _214_fa_base_color : packoffset(c2);\n    float4 _214_fa_emissive : packoffset(c3);\n    float4 _214_fa_model_emissive : packoffset(c4);\n    float4 _214_fa_pbr : packoffset(c5);\n    float4 _214_fa_maps : packoffset(c6);\n    float4 _214_fa_fog : packoffset(c7);\n    float4 _214_fa_fog_b : packoffset(c8);\n    float4 _214_fa_fog_c : packoffset(c9);\n    float4 _214_fa_counts : packoffset(c10);\n    float4 _214_fa_env_sky : packoffset(c11);\n    float4 _214_fa_env_horizon : packoffset(c12);\n    float4 _214_fa_time : packoffset(c13);\n    float4 _214_fa_cl_vpx : packoffset(c14);\n    float4 _214_fa_cl_vpy : packoffset(c15);\n    float4 _214_fa_cl_vpw : packoffset(c16);\n    float4 _214_fa_cl_fwd : packoffset(c17);\n    float4 _214_fa_cl_grid : packoffset(c18);\n    float4 _214_fa_cl_info : packoffset(c19);\n    float4 _214_fa_layers_a : packoffset(c20);\n    float4 _214_fa_layers_b : packoffset(c21);\n    float4 _214_fa_layers_c : packoffset(c22);\n    float4 _214_fa_layers_d : packoffset(c23);\n    float4 _214_fa_ct_a : packoffset(c24);\n    float4 _214_fa_ct_b : packoffset(c25);\n    float4 _214_fa_ct_vpx : packoffset(c26);\n    float4 _214_fa_ct_vpy : packoffset(c27);\n    float4 _214_fa_ct_vpw : packoffset(c28);\n    float4 _214_fa_ct_fwd : packoffset(c29);\n    float4 _214_fa_tr_a : packoffset(c30);\n    float4 _214_fa_tr_b : packoffset(c31);\n    float4 _214_fa_probe_sh[9] : packoffset(c32);\n    float4 _214_fa_atlas : packoffset(c41);\n    float4 _214_fa_rpa_tile : packoffset(c42);\n    float4 _214_fa_rpa_pos : packoffset(c43);\n    float4 _214_fa_rpa_bx : packoffset(c44);\n    float4 _214_fa_rpa_by : packoffset(c45);\n    float4 _214_fa_rpa_bz : packoffset(c46);\n    float4 _214_fa_rpb_tile : packoffset(c47);\n    float4 _214_fa_rpb_pos : packoffset(c48);\n    float4 _214_fa_rpb_bx : packoffset(c49);\n    float4 _214_fa_rpb_by : packoffset(c50);\n    float4 _214_fa_rpb_bz : packoffset(c51);\n    float4 _214_fa_gi : packoffset(c52);\n    float4 _214_fa_gi_px : packoffset(c53);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float2 fa_frag_velocity;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n    float2 fa_frag_velocity : SV_Target1;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w);\n    float param = _214_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _230 = fa_tex_fix(param_2, param_3);\n    float4 _889 = base_t;\n    _889.x = _230.x;\n    _889.y = _230.y;\n    _889.z = _230.z;\n    base_t = _889;\n    float4 _246 = (_889 * _214_fa_base_color) * i.vertex_color;\n    float3 _844 = i.world_normal;\n    if (_214_fa_maps.z > 0.5f)\n    {\n        float param_4 = _214_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _282 = fa_tex_fix(param_6, param_7);\n        float3 _286 = (_282 * 2.0f) - 1.0f.xxx;\n        float2 _291 = _286.xy * _214_fa_maps.x;\n        float3 _897 = _286;\n        _897.x = _291.x;\n        _897.y = _291.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _897;\n        _844 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w);\n    float param_10 = _214_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _322 = fa_tex_fix(param_12, param_13);\n    float4 _900 = mrt;\n    _900.x = _322.x;\n    _900.y = _322.y;\n    _900.z = _322.z;\n    mrt = _900;\n    float4 _354 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w);\n    float param_14 = _214_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _214_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _398 = fa_tex_fix(param_20, param_21);\n    float _849 = _214_fa_layers_a.x;\n    float _850 = _214_fa_layers_a.y;\n    float _853 = _214_fa_layers_a.z;\n    float _852 = _214_fa_layers_b.w;\n    float _855 = _214_fa_layers_c.x;\n    if (_214_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_214_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _849 *= _366.y;\n            _850 *= _366.z;\n            _852 *= _354.w;\n        }\n        if (_214_fa_layers_c.z > 1.5f)\n        {\n            _853 *= mrt.x;\n            _855 *= mrt.w;\n        }\n    }\n    Surface _882 = { _246.xyz, _246.w, _844, clamp(_214_fa_pbr.x * _322.z, 0.0f, 1.0f), clamp(_214_fa_pbr.y * _322.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_214_fa_maps.y * (_366.x - 1.0f)), _214_fa_emissive.xyz + (_214_fa_model_emissive.xyz * _398), _849, _850, _214_fa_layers_b.xyz, _852, _853, _214_fa_layers_a.w, _855, _214_fa_layers_c.y, _214_fa_layers_d.xyz, _214_fa_tr_a.x, _214_fa_tr_a.y, _214_fa_tr_b.xyz, _214_fa_tr_a.z };\n    return _882;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _739 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _739 = -_739;\n    }\n    float3 _550 = normalize(_214_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _752 = { fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing };\n    SurfaceInput param = _752;\n    SurfaceInput _760 = { fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing };\n    SurfaceInput param_1 = _760;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _565 = normalize(param_2.normal);\n    float3 _580 = normalize(float3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    float2 e = _580.xy / ((abs(_580.x) + abs(_580.y)) + abs(_592)).xx;\n    if (_592 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n    float2 motion = 1024.0f.xx;\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06f;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06f;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((float2(fa_vel_prev.x, -fa_vel_prev.y) / fa_vel_prev.z.xx) * 0.5f) - ((float2(fa_vel_cur.x, -fa_vel_cur.y) / fa_vel_cur.z.xx) * 0.5f), (-4.0f).xx, 4.0f.xx);\n    }\n    fa_frag_velocity = motion;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    fa_vel_cur = stage_input.fa_vel_cur;\n    fa_vel_prev = stage_input.fa_vel_prev;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    stage_output.fa_frag_velocity = fa_frag_velocity;\n    return stage_output;\n}\n",
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
