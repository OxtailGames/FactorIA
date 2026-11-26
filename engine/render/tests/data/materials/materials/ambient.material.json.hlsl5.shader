{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "7dfc96845a84a2e1eeb941c4a325b3e44f1dd63d04807d1dd0da2d9b2c3c7186",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _260 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _260;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_267, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _420_fa_camera_pos : packoffset(c0);\n    float4 _420_fa_ambient : packoffset(c1);\n    float4 _420_fa_base_color : packoffset(c2);\n    float4 _420_fa_emissive : packoffset(c3);\n    float4 _420_fa_model_emissive : packoffset(c4);\n    float4 _420_fa_pbr : packoffset(c5);\n    float4 _420_fa_maps : packoffset(c6);\n    float4 _420_fa_fog : packoffset(c7);\n    float4 _420_fa_fog_b : packoffset(c8);\n    float4 _420_fa_fog_c : packoffset(c9);\n    float4 _420_fa_counts : packoffset(c10);\n    float4 _420_fa_env_sky : packoffset(c11);\n    float4 _420_fa_env_horizon : packoffset(c12);\n    float4 _420_fa_time : packoffset(c13);\n    float4 _420_fa_cl_vpx : packoffset(c14);\n    float4 _420_fa_cl_vpy : packoffset(c15);\n    float4 _420_fa_cl_vpw : packoffset(c16);\n    float4 _420_fa_cl_fwd : packoffset(c17);\n    float4 _420_fa_cl_grid : packoffset(c18);\n    float4 _420_fa_cl_info : packoffset(c19);\n    float4 _420_fa_layers_a : packoffset(c20);\n    float4 _420_fa_layers_b : packoffset(c21);\n    float4 _420_fa_layers_c : packoffset(c22);\n    float4 _420_fa_layers_d : packoffset(c23);\n    float4 _420_fa_ct_a : packoffset(c24);\n    float4 _420_fa_ct_b : packoffset(c25);\n    float4 _420_fa_ct_vpx : packoffset(c26);\n    float4 _420_fa_ct_vpy : packoffset(c27);\n    float4 _420_fa_ct_vpw : packoffset(c28);\n    float4 _420_fa_ct_fwd : packoffset(c29);\n    float4 _420_fa_tr_a : packoffset(c30);\n    float4 _420_fa_tr_b : packoffset(c31);\n    float4 _420_fa_probe_sh[9] : packoffset(c32);\n    float4 _420_fa_atlas : packoffset(c41);\n    float4 _420_fa_rpa_tile : packoffset(c42);\n    float4 _420_fa_rpa_pos : packoffset(c43);\n    float4 _420_fa_rpa_bx : packoffset(c44);\n    float4 _420_fa_rpa_by : packoffset(c45);\n    float4 _420_fa_rpa_bz : packoffset(c46);\n    float4 _420_fa_rpb_tile : packoffset(c47);\n    float4 _420_fa_rpb_pos : packoffset(c48);\n    float4 _420_fa_rpb_bx : packoffset(c49);\n    float4 _420_fa_rpb_by : packoffset(c50);\n    float4 _420_fa_rpb_bz : packoffset(c51);\n    float4 _420_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2072_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2072_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2072_fa_shadow_info[4] : packoffset(c20);\n    float4 _2072_fa_shadow_split : packoffset(c24);\n    float4 _2072_fa_shadow_cfg : packoffset(c25);\n    float4 _2072_fa_shadow_bias : packoffset(c26);\n    float4 _2072_fa_shadow_eye : packoffset(c27);\n    float4 _2072_fa_shadow_fwd : packoffset(c28);\n    float4 _2072_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1348 = _420_fa_cl_info.x < 0.0f;\n    bool _1355;\n    if (!_1348)\n    {\n        _1355 = _420_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1355 = _1348;\n    }\n    bool _1363;\n    if (!_1355)\n    {\n        _1363 = _420_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1363 = _1355;\n    }\n    bool _1370;\n    if (!_1363)\n    {\n        _1370 = _420_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1370 = _1363;\n    }\n    bool _1377;\n    if (!_1370)\n    {\n        _1377 = _420_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1377 = _1370;\n    }\n    if (_1377)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1387 = float4(world_pos, 1.0f);\n    float _1393 = dot(_420_fa_cl_vpw, _1387);\n    if (!(_1393 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1415 = float2(dot(_420_fa_cl_vpx, _1387), dot(_420_fa_cl_vpy, _1387)) / _1393.xx;\n    int _1419 = int(_420_fa_cl_grid.x);\n    int _1423 = int(_420_fa_cl_grid.y);\n    int param = (int(_420_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_420_fa_cl_fwd.xyz, world_pos) + _420_fa_cl_fwd.w, _420_fa_cl_grid.w) / _420_fa_cl_grid.w) * _420_fa_cl_grid.z)), 0, int(_420_fa_cl_info.y) - 1) * _1423) + clamp(int(floor(((_1415.y * 0.5f) + 0.5f) * _420_fa_cl_grid.y)), 0, _1423 - 1)) * _1419)) + clamp(int(floor(((_1415.x * 0.5f) + 0.5f) * _420_fa_cl_grid.x)), 0, _1419 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1499 = fa_cluster_texel(param);\n    return int2(int(_1499.x), int(_1499.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_420_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3890 = fa_cluster_lookup(param);\n    fa_cl_slot = _3890.x;\n    fa_cl_local = _3890.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4100 = fa_linear_to_srgb(param);\n        c = _4100;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4108 = fa_srgb_to_linear(param_1);\n            c = _4108;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _302;\n    if (i.front_facing)\n    {\n        _302 = i.world_normal;\n    }\n    else\n    {\n        _302 = -i.world_normal;\n    }\n    float3 _326 = normalize(i.world_tangent.xyz - (_302 * dot(_302, i.world_tangent.xyz)));\n    float3 _353 = normalize(((_326 * m.x) + ((cross(_302, _326) * i.world_tangent.w) * m.y)) + (_302 * m.z));\n    float3 _356;\n    if (i.front_facing)\n    {\n        _356 = _353;\n    }\n    else\n    {\n        _356 = -_353;\n    }\n    return _356;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _420_fa_env_horizon.w);\n    float param = _420_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4140 = fa_tex_fix(param_2, param_3);\n    float4 _5959 = base_t;\n    _5959.x = _4140.x;\n    _5959.y = _4140.y;\n    _5959.z = _4140.z;\n    base_t = _5959;\n    float4 _4154 = (_5959 * _420_fa_base_color) * i.vertex_color;\n    float3 _5786 = i.world_normal;\n    if (_420_fa_maps.z > 0.5f)\n    {\n        float param_4 = _420_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _420_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4188 = fa_tex_fix(param_6, param_7);\n        float3 _4191 = (_4188 * 2.0f) - 1.0f.xxx;\n        float2 _4196 = _4191.xy * _420_fa_maps.x;\n        float3 _5967 = _4191;\n        _5967.x = _4196.x;\n        _5967.y = _4196.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5967;\n        _5786 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _420_fa_env_horizon.w);\n    float param_10 = _420_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4226 = fa_tex_fix(param_12, param_13);\n    float4 _5970 = mrt;\n    _5970.x = _4226.x;\n    _5970.y = _4226.y;\n    _5970.z = _4226.z;\n    mrt = _5970;\n    float4 _4256 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _420_fa_env_horizon.w);\n    float param_14 = _420_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4256.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4267 = fa_tex_fix(param_16, param_17);\n    float param_18 = _420_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _420_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4299 = fa_tex_fix(param_20, param_21);\n    float _5791 = _420_fa_layers_a.x;\n    float _5792 = _420_fa_layers_a.y;\n    float _5795 = _420_fa_layers_a.z;\n    float _5794 = _420_fa_layers_b.w;\n    float _5797 = _420_fa_layers_c.x;\n    if (_420_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_420_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _5791 *= _4267.y;\n            _5792 *= _4267.z;\n            _5794 *= _4256.w;\n        }\n        if (_420_fa_layers_c.z > 1.5f)\n        {\n            _5795 *= mrt.x;\n            _5797 *= mrt.w;\n        }\n    }\n    Surface _5824 = { _4154.xyz, _4154.w, _5786, clamp(_420_fa_pbr.x * _4226.z, 0.0f, 1.0f), clamp(_420_fa_pbr.y * _4226.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_420_fa_maps.y * (_4267.x - 1.0f)), _420_fa_emissive.xyz + (_420_fa_model_emissive.xyz * _4299), _5791, _5792, _420_fa_layers_b.xyz, _5794, _5795, _420_fa_layers_a.w, _5797, _420_fa_layers_c.y, _420_fa_layers_d.xyz, _420_fa_tr_a.x, _420_fa_tr_a.y, _420_fa_tr_b.xyz, _420_fa_tr_a.z };\n    return _5824;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1579 = rect.zw - rect.xy;\n    float2 _1583 = _1579 * atlas;\n    float2 _1587 = ddx * _1583;\n    float2 _1591 = ddy * _1583;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1579), clamp(0.5f * log2(max(max(dot(_1587, _1587), dot(_1591, _1591)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1624 = _420_fa_counts.y < 0.5f;\n    bool _1631;\n    if (!_1624)\n    {\n        _1631 = _420_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1631 = _1624;\n    }\n    if (_1631)\n    {\n        return;\n    }\n    float3 _1637 = ddx(world_pos);\n    float3 _1640 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1644 = fa_cluster_texel(param);\n    int _1648 = int(_1644.w);\n    if (_1648 < 1)\n    {\n        return;\n    }\n    int _1658 = int(_420_fa_counts.y + 0.5f);\n    int param_1 = _1658;\n    float4 _1662 = fa_light_texel(param_1);\n    float2 _1665 = _1662.yz;\n    int _1669 = int(_1662.w);\n    int param_2 = _1658 + 1;\n    float4 _1674 = fa_light_texel(param_2);\n    float _1675 = _1674.x;\n    int _1681 = int(_420_fa_counts.w + 0.5f) - 1;\n    int _1685 = int(_1644.z);\n    float3 _1950;\n    for (int k = 0; k < _1648; k++)\n    {\n        int _1698 = _1685 + k;\n        int param_3 = _1669 + (_1698 >> 2);\n        int _1715 = (_1658 + 2) + (int(fa_light_texel(param_3)[_1698 & 3]) * 7);\n        int param_4 = _1715 + 6;\n        float4 _1720 = fa_light_texel(param_4);\n        if (((int(_1720.w + 0.5f) >> _1681) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1715;\n        float4 _1735 = fa_light_texel(param_5);\n        int param_6 = _1715 + 1;\n        float4 _1740 = fa_light_texel(param_6);\n        int param_7 = _1715 + 2;\n        float4 _1745 = fa_light_texel(param_7);\n        float3 _1748 = _1735.xyz;\n        float _1753 = dot(_1748, world_pos) + _1735.w;\n        float3 _1755 = _1740.xyz;\n        float _1760 = dot(_1755, world_pos) + _1740.w;\n        float3 _1762 = _1745.xyz;\n        float _1767 = dot(_1762, world_pos) + _1745.w;\n        bool _1772 = abs(_1753) > 0.5f;\n        bool _1780;\n        if (!_1772)\n        {\n            _1780 = abs(_1760) > 0.5f;\n        }\n        else\n        {\n            _1780 = _1772;\n        }\n        bool _1788;\n        if (!_1780)\n        {\n            _1788 = abs(_1767) > 0.5f;\n        }\n        else\n        {\n            _1788 = _1780;\n        }\n        if (_1788)\n        {\n            continue;\n        }\n        float _1803 = clamp(dot(geo_normal, normalize(_1762)) * _1720.z, 0.0f, 1.0f);\n        if (_1803 <= 0.0f)\n        {\n            continue;\n        }\n        float _1823 = (clamp((0.5f - abs(_1767)) * 10.0f, 0.0f, 1.0f) * _1803) * _1720.x;\n        float2 _1831 = float2(_1753 + 0.5f, 0.5f - _1760);\n        float2 _1841 = float2(dot(_1748, _1637), dot(_1755, _1637));\n        float2 _1851 = float2(dot(_1748, _1640), dot(_1755, _1640));\n        int param_8 = _1715 + 5;\n        float4 _1856 = fa_light_texel(param_8);\n        int param_9 = _1715 + 3;\n        float4 _1861 = fa_light_texel(param_9);\n        int param_10 = _1715 + 4;\n        float4 _1866 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1856.xyz;\n        bool _1876 = _1861.z > _1861.x;\n        if (_1876)\n        {\n            float4 param_11 = _1861;\n            float2 param_12 = _1831;\n            float2 param_13 = _1665;\n            float2 param_14 = _1841;\n            float2 param_15 = _1851;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1675 > 0.5f) && (_1675 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1902 = fa_dc_to_linear(param_16);\n                float4 _5874 = tx;\n                _5874.x = _1902.x;\n                _5874.y = _1902.y;\n                _5874.z = _1902.z;\n                tx = _5874;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1823 * tex_a) * _1856.w, 0.0f, 1.0f).xxx);\n        if (_1866.z > _1866.x)\n        {\n            float4 param_17 = _1866;\n            float2 param_18 = _1831;\n            float2 param_19 = _1665;\n            float2 param_20 = _1841;\n            float2 param_21 = _1851;\n            float4 _1946 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1675 > 1.5f)\n            {\n                float3 param_22 = _1946.xyz;\n                float3 _1956 = fa_dc_to_srgb(param_22);\n                _1950 = _1956;\n            }\n            else\n            {\n                _1950 = _1946.xyz;\n            }\n            float3 _1965 = (_1950 * 2.0f) - 1.0f.xxx;\n            float2 _1970 = _1965.xy * _1720.y;\n            float3 _1992 = (normalize(_1748) * _1970.x) + (normalize(_1755) * _1970.y);\n            float3 _1995 = normalize(normal);\n            normal = normalize(lerp(_1995, normalize((_1995 * max(_1965.z, 0.0500000007450580596923828125f)) + (_1992 - (_1995 * dot(_1995, _1992)))), clamp(_1823 * (_1876 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3411_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3411_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_420_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3352 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3352;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3462 = (1.0f - _420_fa_rpa_tile.w) - _420_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3468 = _420_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3462 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3468)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _420_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3462;\n            }\n        }\n        else\n        {\n            amb = _420_fa_ambient.xyz * _3462;\n        }\n    }\n    bool _3520 = _420_fa_rpa_tile.w > 0.0f;\n    if (_3520)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _420_fa_rpa_tile.xy;\n            float param_4 = _420_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _420_fa_rpa_tile.w);\n        }\n    }\n    bool _3551 = _420_fa_rpb_tile.w > 0.0f;\n    if (_3551)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _420_fa_rpb_tile.xy;\n            float param_7 = _420_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _420_fa_rpb_tile.w);\n        }\n    }\n    if ((_3468 || _3520) || _3551)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3372 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3375 = _3372.x;\n    float _3377 = _3372.z;\n    float2 e = float2(_3375, _3377);\n    if (_3372.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3377)) * ((_3375 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3375)) * ((_3377 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _4413 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _4418 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _4423 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _4428 = fa_light_texel(param_3);\n    bool _4431 = _4428.z < 0.5f;\n    bool _4439;\n    if (!_4431)\n    {\n        _4439 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _4439 = _4431;\n    }\n    if (_4439)\n    {\n        return 0.0f.xxx;\n    }\n    float _4446 = max(_4413.w, 9.9999997473787516355514526367188e-05f);\n    float3 _4449 = _4418.xyz;\n    float3 _4453 = _4413.xyz;\n    float3 _4457 = (fa_world_pos - _4453) / _4446.xxx;\n    float3 _4466 = min(_4457 + 0.5f.xxx, (_4449 - 0.5f.xxx) - _4457);\n    float _4475 = min(_4466.x, min(_4466.y, _4466.z));\n    if (!(_4475 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4490 = _4449 - 1.0f.xxx;\n    float3 _4491 = clamp(_4457, 0.0f.xxx, _4490);\n    float3 _4499 = min(floor(_4491), max(_4449 - 2.0f.xxx, 0.0f.xxx));\n    float3 _4503 = _4491 - _4499;\n    float3 _4515 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _4446));\n    int _4520 = int(_4423.y + 0.5f);\n    float _4525 = 0.3257350027561187744140625f * n.y;\n    float _4529 = 0.3257350027561187744140625f * n.z;\n    float _4533 = 0.3257350027561187744140625f * n.x;\n    float _4540 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _4547 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _4556 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _4563 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _4576 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _4583 = 8 + int(_4428.w);\n    float _4610;\n    float _4623;\n    float _4637;\n    for (int k = 0; k < _4583; k++)\n    {\n        float _4596 = float(k & 1);\n        float _4600 = float((k >> 1) & 1);\n        float _4604 = float((k >> 2) & 1);\n        if (_4596 > 0.5f)\n        {\n            _4610 = _4503.x;\n        }\n        else\n        {\n            _4610 = 1.0f - _4503.x;\n        }\n        if (_4600 > 0.5f)\n        {\n            _4623 = _4503.y;\n        }\n        else\n        {\n            _4623 = 1.0f - _4503.y;\n        }\n        if (_4604 > 0.5f)\n        {\n            _4637 = _4503.z;\n        }\n        else\n        {\n            _4637 = 1.0f - _4503.z;\n        }\n        float _4647 = (_4610 * _4623) * _4637;\n        if (!(_4647 > 0.0f))\n        {\n            continue;\n        }\n        float3 _4660 = min(_4499 + float3(_4596, _4600, _4604), _4490);\n        int _4680 = int(((_4423.x + _4660.x) + (_4418.x * (_4660.y + (_4418.y * _4660.z)))) + 0.5f);\n        float2 _4695 = float2(float(_4680 % _4520) * 10.0f, 1024.0f + (float(_4680 / _4520) * 11.0f));\n        float2 param_4 = _4695 + float2(9.5f, 10.5f);\n        float4 _4703 = fa_gi_fetch(param_4);\n        bool _4706 = _4703.y < 0.5f;\n        bool _4715;\n        if (!_4706)\n        {\n            _4715 = _4703.x > _4428.y;\n        }\n        else\n        {\n            _4715 = _4706;\n        }\n        if (_4715)\n        {\n            continue;\n        }\n        float3 _4727 = _4515 - (_4453 + (_4660 * _4446));\n        float _4730 = length(_4727);\n        float3 _4736 = _4727 / max(_4730, 9.9999997473787516355514526367188e-05f).xxx;\n        float _4746 = max(9.9999997473787516355514526367188e-05f, (dot(-_4736, n) + 1.0f) * 0.5f);\n        float w = _4647 * (_4746 * _4746);\n        float3 param_5 = _4736;\n        float2 param_6 = (_4695 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _4766 = fa_gi_fetch(param_6);\n        float _4773 = _4730 / max(_4423.z, 9.9999997473787516355514526367188e-05f);\n        float _4776 = _4766.x;\n        if (_4773 > _4776)\n        {\n            float _4789 = max(_4766.y - (_4776 * _4776), 0.0f);\n            float _4794 = _4773 - _4776;\n            float _4803 = _4789 / max(_4789 + (_4794 * _4794), 9.9999999600419720025001879548654e-13f);\n            w *= ((_4803 * _4803) * _4803);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _4695 + float2(0.5f, 10.5f);\n        float2 param_8 = _4695 + float2(1.5f, 10.5f);\n        float2 param_9 = _4695 + float2(2.5f, 10.5f);\n        float2 param_10 = _4695 + float2(3.5f, 10.5f);\n        float2 param_11 = _4695 + float2(4.5f, 10.5f);\n        float2 param_12 = _4695 + float2(5.5f, 10.5f);\n        float2 param_13 = _4695 + float2(6.5f, 10.5f);\n        float2 param_14 = _4695 + float2(7.5f, 10.5f);\n        float2 param_15 = _4695 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _4525)) + (fa_gi_fetch(param_9).xyz * _4529)) + (fa_gi_fetch(param_10).xyz * _4533)) + (fa_gi_fetch(param_11).xyz * _4540)) + (fa_gi_fetch(param_12).xyz * _4547)) + (fa_gi_fetch(param_13).xyz * _4556)) + (fa_gi_fetch(param_14).xyz * _4563)) + (fa_gi_fetch(param_15).xyz * _4576)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_4475 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _4931;\n    if (_420_fa_gi.z > 0.5f)\n    {\n        _4931 = _4428.x;\n    }\n    else\n    {\n        _4931 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_4423.w * _4931);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _4955 = normalize(_420_fa_camera_pos.xyz - fa_world_pos);\n    int _4960 = int(_420_fa_gi.x + 0.5f);\n    int _4965 = int(_420_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _4965) && (k < 8); k++)\n    {\n        int param = _4960 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _4955;\n        float3 _4990 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _4995 = param_3 * left;\n        acc += (_4990 * _4995);\n        left -= _4995;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_420_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _5024 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5024;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_420_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _420_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_420_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return float3(0.0f, ambientColor.y, 0.0f);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_420_fa_cl_info.x) + int(_420_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_420_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3860;\n    if (fa_lm.z > 0.5f)\n    {\n        _3860 = 0.0f;\n    }\n    else\n    {\n        _3860 = 1.0f - clamp(_420_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _3871 = _3860 < 1.0f;\n    bool _3877;\n    if (_3871)\n    {\n        int param = li;\n        _3877 = fa_light_baked(param);\n    }\n    else\n    {\n        _3877 = _3871;\n    }\n    return _3877 ? _3860 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _598 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _611 = (c - (ru * hx)) - p;\n        float3 _617 = ru * (2.0f * hx);\n        float _623 = max(dot(_617, _617), 9.9999999392252902907785028219223e-09f);\n        float _627 = dot(_611, _617);\n        float t = clamp((-_627) / _623, 0.0f, 1.0f);\n        if (_598)\n        {\n            float _642 = dot(r, _617);\n            float _648 = _623 - (_642 * _642);\n            if (abs(_648) > (9.9999997473787516355514526367188e-06f * _623))\n            {\n                t = clamp(((dot(r, _611) * _642) - _627) / _648, 0.0f, 1.0f);\n            }\n        }\n        return (p + _611) + (_617 * t);\n    }\n    float3 q = p;\n    float _680 = dot(r, axis);\n    bool _688;\n    if (_598)\n    {\n        _688 = abs(_680) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _688 = _598;\n    }\n    if (_688)\n    {\n        float _698 = dot(c - p, axis) / _680;\n        if (_698 > 0.0f)\n        {\n            q = p + (r * _698);\n        }\n    }\n    float3 _711 = q - c;\n    float2 xy = float2(dot(_711, ru), dot(_711, uu));\n    if (shape > 0.5f)\n    {\n        float _726 = length(xy);\n        if (_726 > hx)\n        {\n            xy *= (hx / _726);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _479_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _479_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _518 = dot(d, right);\n    float _522 = dot(d, up);\n    float _533;\n    if (((_518 * _518) + (_522 * _522)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _533 = atan2(_522, _518) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _533 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_533 - floor(_533)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _368 = abs(d);\n    float _370 = _368.x;\n    float _372 = _368.y;\n    bool _373 = _370 >= _372;\n    bool _381;\n    if (_373)\n    {\n        _381 = _370 >= _368.z;\n    }\n    else\n    {\n        _381 = _373;\n    }\n    int _382;\n    if (_381)\n    {\n        _382 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _397;\n        if (_372 >= _368.z)\n        {\n            _397 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _397 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _382 = _397;\n    }\n    return _382;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _764 = fa_light_base(param);\n    bool _768 = _420_fa_ambient.w > 4.5f;\n    int param_1 = _764;\n    float4 _772 = fa_light_texel(param_1);\n    int param_2 = _764 + 1;\n    float4 _777 = fa_light_texel(param_2);\n    float _780 = _777.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _792 = _768 && (_780 > 2.5f);\n    fa_light_is_area = _792;\n    bool _794 = _780 < 0.5f;\n    float3 l;\n    if (_794)\n    {\n        l = normalize(_772.xyz);\n        if (_768)\n        {\n            int param_3 = _764 + 6;\n            float4 _808 = fa_light_texel(param_3);\n            if (_808.z > 0.5f)\n            {\n                int param_4 = _764 + 4;\n                float4 _818 = fa_light_texel(param_4);\n                int param_5 = _764 + 5;\n                float4 _823 = fa_light_texel(param_5);\n                float2 param_6 = _808.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _818.xyz) * _818.w, (-dot(world_pos, _823.xyz)) * _823.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _853 = _772.xyz;\n        float3 _855 = _853 - world_pos;\n        float3 to_light = _855;\n        float _858 = length(_855);\n        float reach = _858;\n        bool front = true;\n        if (_792)\n        {\n            int param_8 = _764 + 7;\n            reach = max(_858 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _764 + 4;\n            float4 _882 = fa_light_texel(param_9);\n            int param_10 = _764 + 5;\n            float4 _887 = fa_light_texel(param_10);\n            int param_11 = _764 + 6;\n            float4 _892 = fa_light_texel(param_11);\n            float _893 = _892.w;\n            int param_12 = _764 + 2;\n            float3 _900 = normalize(fa_light_texel(param_12).xyz);\n            bool _902 = _893 > 1.5f;\n            bool _910;\n            if (!_902)\n            {\n                _910 = dot(_900, to_light) < 0.0f;\n            }\n            else\n            {\n                _910 = _902;\n            }\n            front = _910;\n            float3 r = 0.0f.xxx;\n            float3 _919 = _420_fa_camera_pos.xyz - world_pos;\n            bool _923 = dot(n, n) > 0.5f;\n            bool _931;\n            if (_923)\n            {\n                _931 = dot(_919, _919) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _931 = _923;\n            }\n            if (_931)\n            {\n                r = reflect(-normalize(_919), normalize(n));\n            }\n            float3 param_13 = _853;\n            float3 param_14 = _900;\n            float3 param_15 = _882.xyz;\n            float3 param_16 = _887.xyz;\n            float param_17 = _882.w;\n            float param_18 = _887.w;\n            float param_19 = _893;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _967 = length(to_light);\n        dist = _967;\n        l = to_light / max(_967, 9.9999997473787516355514526367188e-05f).xxx;\n        float _981 = reach / max(_772.w, 0.001000000047497451305389404296875f);\n        float _987 = clamp(1.0f - (_981 * _981), 0.0f, 1.0f);\n        float _989;\n        if (front)\n        {\n            _989 = _987 * _987;\n        }\n        else\n        {\n            _989 = 0.0f;\n        }\n        atten = _989;\n        bool _1000 = _780 < 2.5f;\n        if ((_780 > 1.5f) && _1000)\n        {\n            int param_22 = _764 + 2;\n            float4 _1008 = fa_light_texel(param_22);\n            float _1018 = _1008.w;\n            int param_23 = _764 + 3;\n            float4 _1023 = fa_light_texel(param_23);\n            float _1024 = _1023.x;\n            float cos_inner = _1024;\n            if (_1024 > 1.5f)\n            {\n                cos_inner = lerp(_1018, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1018, cos_inner, dot(-l, normalize(_1008.xyz)));\n        }\n        if (_768 && (_780 < 1.5f))\n        {\n            int param_24 = _764 + 6;\n            float4 _1048 = fa_light_texel(param_24);\n            if (_1048.z > 0.5f)\n            {\n                float3 _1056 = -to_light;\n                int param_25 = _764 + 4;\n                int param_26 = _764 + 5;\n                float3 _1070 = fa_light_texel(param_25).xyz;\n                float3 _1074 = fa_light_texel(param_26).xyz;\n                float3 _1083 = float3(dot(_1056, _1070), dot(_1056, _1074), dot(_1056, cross(_1070, _1074)));\n                float3 param_27 = _1083;\n                int _1087 = fa_cube_face(param_27);\n                int param_28 = _1087;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1114 = float2(dot(_1083, cross(param_29, param_30)), dot(_1083, param_30)) / max(dot(_1083, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1118 = _1087 / 3;\n                float2 param_31 = _1048.xy + (float2(float(_1087 - (_1118 * 3)), float(_1118)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1114.x), 0.5f - (0.5f * _1114.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _764 + 7;\n            float4 _1148 = fa_light_texel(param_33);\n            if (_1148.z > 0.5f)\n            {\n                int param_34 = _764 + 2;\n                int param_35 = _764 + 4;\n                int param_36 = _764 + 5;\n                float2 param_37 = _1148.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_768 && _1000)\n            {\n                int param_42 = _764 + 6;\n                float4 _1195 = fa_light_texel(param_42);\n                int param_43 = _764 + 7;\n                float4 _1200 = fa_light_texel(param_43);\n                bool _1203 = _1195.z > 0.5f;\n                bool _1210;\n                if (!_1203)\n                {\n                    _1210 = _1200.z > 0.5f;\n                }\n                else\n                {\n                    _1210 = _1203;\n                }\n                if (_1210)\n                {\n                    int param_44 = _764 + 2;\n                    float4 _1217 = fa_light_texel(param_44);\n                    float3 _1221 = normalize(_1217.xyz);\n                    int param_45 = _764 + 4;\n                    float4 _1226 = fa_light_texel(param_45);\n                    int param_46 = _764 + 5;\n                    float4 _1231 = fa_light_texel(param_46);\n                    if (_1203)\n                    {\n                        float3 _1239 = -to_light;\n                        float _1246 = _1217.w;\n                        float _1262 = 0.5f / max(dot(_1239, _1221) * (sqrt(max(1.0f - (_1246 * _1246), 0.0f)) / max(_1246, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1195.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1239, _1226.xyz) * _1262), 0.5f - (dot(_1239, _1231.xyz) * _1262));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1200.z > 0.5f)\n                    {\n                        float2 param_49 = _1200.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1221;\n                        float3 param_52 = _1226.xyz;\n                        float3 param_53 = _1231.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _5740 = _777.xyz * atten;\n    if (_768)\n    {\n        _5740 *= fa_light_tint;\n    }\n    int _1330;\n    if (_794)\n    {\n        _1330 = 0;\n    }\n    else\n    {\n        _1330 = ((_780 > 1.5f) && (_780 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _5751 = { l, _5740, atten, 1.0f, dist, _1330 };\n    return _5751;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2119 = fa_shadow_depth(param, param_1);\n    float _2123;\n    if (conv.x < 0.5f)\n    {\n        _2123 = _2119;\n    }\n    else\n    {\n        _2123 = (conv.y * conv.z) / (conv.z - (_2119 * (conv.z - conv.y)));\n    }\n    return _2123;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2169 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2175 = float2(cos(_2169), sin(_2169));\n    float2 dir = _2175;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2184;\n        if (k < 0.0f)\n        {\n            _2184 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2184 = k;\n        }\n        float _2203 = clamp((_2184 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2222 = sqrt((float(i) + 0.5f) * 0.0625f) * _2203;\n            float2 param_3 = uv + (dir * (_2072_fa_shadow_bias.zw * _2222));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2236 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2236 < (zr - (_2222 * plane)))\n            {\n                sum += _2236;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2264 = sum / cnt;\n        float _2274;\n        if (k < 0.0f)\n        {\n            _2274 = (-k) / max(_2264, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2274 = k;\n        }\n        radius = clamp(((max(zr - _2264, 0.0f) * unit) * _2274) / texel_m, 1.5f, 16.0f);\n        dir = _2175;\n    }\n    float lit = 0.0f;\n    int _2300 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2300; i_1++)\n    {\n        float _2319 = sqrt((float(i_1) + 0.5f) / float(_2300)) * radius;\n        float2 param_7 = uv + (dir * (_2072_fa_shadow_bias.zw * _2319));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2319 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2300);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2524 = _420_fa_pbr.z < 0.5f;\n    bool _2531;\n    if (!_2524)\n    {\n        _2531 = _2072_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2531 = _2524;\n    }\n    if (_2531)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2072_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2544 = fa_light_texel(param);\n    float _2545 = _2544.x;\n    if (_2545 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2554 = int(_2545 + 0.5f);\n    int param_1 = _2554;\n    float4 _2558 = fa_light_texel(param_1);\n    int param_2 = _2554 + 1;\n    float4 _2563 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2566 = _2558.y;\n    if (_2566 > 0.0f)\n    {\n        float _2583 = 1.0f - smoothstep(0.75f * _2566, _2566, length(world - _2072_fa_shadow_eye.xyz));\n        fade = _2583;\n        if (_2583 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2558.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2607 = (_2554 + 2) + (face * 6);\n    int param_4 = _2607;\n    int param_5 = _2607 + 1;\n    int param_6 = _2607 + 3;\n    float4 _2621 = fa_light_texel(param_6);\n    int param_7 = _2607 + 4;\n    float4 _2626 = fa_light_texel(param_7);\n    int param_8 = _2607 + 5;\n    float4 _2631 = fa_light_texel(param_8);\n    float _2643 = _2631.x * max(dot(_2621, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2648 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2671 = clamp(dot(n, _2621.xyz), -1.0f, 1.0f);\n    float _2690 = min(sqrt(1.0f - (_2671 * _2671)) / max(abs(dot(n, world - lpos)) / max(dot(_2621, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2693 = _2563.y;\n    float _2695;\n    if (_2693 > 0.0f)\n    {\n        _2695 = _2693;\n    }\n    else\n    {\n        _2695 = 1.5f * _2643;\n    }\n    float4 _2715 = float4(world + (n * (_2695 * sqrt(1.0f - (_2648 * _2648)))), 1.0f);\n    float _2719 = dot(_2621, _2715);\n    float _2722 = _2631.y;\n    if (_2719 < _2722)\n    {\n        return 1.0f;\n    }\n    float2 _2737 = float2(dot(fa_light_texel(param_4), _2715), dot(fa_light_texel(param_5), _2715)) / _2719.xx;\n    float _2739 = _2737.x;\n    bool _2742 = _2739 < _2626.x;\n    bool _2751;\n    if (!_2742)\n    {\n        _2751 = _2739 > _2626.z;\n    }\n    else\n    {\n        _2751 = _2742;\n    }\n    bool _2760;\n    if (!_2751)\n    {\n        _2760 = _2737.y < _2626.y;\n    }\n    else\n    {\n        _2760 = _2751;\n    }\n    bool _2769;\n    if (!_2760)\n    {\n        _2769 = _2737.y > _2626.w;\n    }\n    else\n    {\n        _2769 = _2760;\n    }\n    if (_2769)\n    {\n        return 1.0f;\n    }\n    float _2775 = _2563.x;\n    float _2777;\n    if (_2775 > 0.0f)\n    {\n        _2777 = _2775;\n    }\n    else\n    {\n        _2777 = 1.5f * _2643;\n    }\n    float2 param_9 = _2737;\n    float4 param_10 = _2626;\n    float param_11 = _2719 - (_2777 * (1.0f + (0.5f * _2690)));\n    float param_12 = _2643;\n    float param_13 = 1.0f;\n    float param_14 = _2631.z * 0.25f;\n    float param_15 = (_2643 * min(_2690, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2722, _2631.z);\n    int param_17 = int(_2558.z + 0.5f);\n    float param_18 = _2558.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2062;\n    if (i == 0)\n    {\n        _2062 = _2072_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2078;\n        if (i == 1)\n        {\n            _2078 = _2072_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2086;\n            if (i == 2)\n            {\n                _2086 = _2072_fa_shadow_split.z;\n            }\n            else\n            {\n                _2086 = _2072_fa_shadow_split.w;\n            }\n            _2078 = _2086;\n        }\n        _2062 = _2078;\n    }\n    return _2062;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2365 = max(_2072_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2370 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2376 = sqrt(1.0f - (_2370 * _2370));\n    float _2384 = min(_2376 / max(_2370, 0.20000000298023223876953125f), 4.0f);\n    float _2389;\n    if (_2072_fa_shadow_bias.y > 0.0f)\n    {\n        _2389 = _2072_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2389 = 1.5f * _2072_fa_shadow_info[ci].x;\n    }\n    float4 _2414 = mul(float4(world + (n * (_2389 * _2376)), 1.0f), _2072_fa_shadow_mat[ci]);\n    float _2421 = _2414.x;\n    bool _2424 = _2421 < _2072_fa_shadow_rect[ci].x;\n    bool _2433;\n    if (!_2424)\n    {\n        _2433 = _2421 > _2072_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2433 = _2424;\n    }\n    bool _2442;\n    if (!_2433)\n    {\n        _2442 = _2414.y < _2072_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2442 = _2433;\n    }\n    bool _2451;\n    if (!_2442)\n    {\n        _2451 = _2414.y > _2072_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2451 = _2442;\n    }\n    bool _2458;\n    if (!_2451)\n    {\n        _2458 = _2414.z > 1.0f;\n    }\n    else\n    {\n        _2458 = _2451;\n    }\n    if (_2458)\n    {\n        return -1.0f;\n    }\n    float _2466;\n    if (_2072_fa_shadow_bias.x > 0.0f)\n    {\n        _2466 = _2072_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2466 = 1.5f * _2072_fa_shadow_info[ci].x;\n    }\n    float2 param = _2414.xy;\n    float4 param_1 = _2072_fa_shadow_rect[ci];\n    float param_2 = _2414.z - ((_2466 * (1.0f + (0.5f * _2384))) / _2365);\n    float param_3 = _2072_fa_shadow_info[ci].x;\n    float param_4 = _2365;\n    float param_5 = _2365 * 0.25f;\n    float param_6 = ((_2072_fa_shadow_info[ci].x * min(_2384, 3.0f)) * 0.5f) / _2365;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2072_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2072_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_420_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2844 = int(_2072_fa_shadow_cfg.x + 0.5f);\n    if (_2844 < 1)\n    {\n        return 1.0f;\n    }\n    float _2859 = dot(world - _2072_fa_shadow_eye.xyz, _2072_fa_shadow_fwd.xyz);\n    int param = _2844 - 1;\n    if (_2859 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2871 = _2844 > 1;\n    bool _2878;\n    if (_2871)\n    {\n        _2878 = _2859 > _2072_fa_shadow_split.x;\n    }\n    else\n    {\n        _2878 = _2871;\n    }\n    if (_2878)\n    {\n        ci = 1;\n    }\n    bool _2882 = _2844 > 2;\n    bool _2889;\n    if (_2882)\n    {\n        _2889 = _2859 > _2072_fa_shadow_split.y;\n    }\n    else\n    {\n        _2889 = _2882;\n    }\n    if (_2889)\n    {\n        ci = 2;\n    }\n    bool _2893 = _2844 > 3;\n    bool _2900;\n    if (_2893)\n    {\n        _2900 = _2859 > _2072_fa_shadow_split.z;\n    }\n    else\n    {\n        _2900 = _2893;\n    }\n    if (_2900)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _2911 = min(_2844, 4);\n    float _2952;\n    for (int c = ci; c < _2911; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2931 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _2931;\n            break;\n        }\n        if (_2931 < 0.0f)\n        {\n            continue;\n        }\n        s = _2931;\n        ci = c;\n        if (_2072_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2952 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2952 = _2072_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _2971 = _2072_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2952, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_2859 - (fa_shadow_split_at(param_7) - _2971)) / _2971, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3003;\n        if ((ci + 1) < _2844)\n        {\n            _3003 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3003 = 1.0f;\n        }\n        s = lerp(s, _3003, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    bool _3108 = _420_fa_ct_b.y > 0.5f;\n    bool _3114;\n    if (_3108)\n    {\n        _3114 = _420_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3114 = _3108;\n    }\n    if (_3114)\n    {\n        float4 _3124 = float4(fa_world_pos, 1.0f);\n        float _3130 = dot(_420_fa_ct_vpw, _3124);\n        if (_3130 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _3149 = float2(dot(_420_fa_ct_vpx, _3124), dot(_420_fa_ct_vpy, _3124)) / _3130.xx;\n            float _3154 = (_3149.x * 0.5f) + 0.5f;\n            float _3158;\n            if (_420_fa_ct_a.y > 0.5f)\n            {\n                _3158 = (_3149.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _3158 = 0.5f - (_3149.y * 0.5f);\n            }\n            bool _3174 = _3154 >= 0.0f;\n            bool _3180;\n            if (_3174)\n            {\n                _3180 = _3154 < 1.0f;\n            }\n            else\n            {\n                _3180 = _3174;\n            }\n            bool _3186;\n            if (_3180)\n            {\n                _3186 = _3158 >= 0.0f;\n            }\n            else\n            {\n                _3186 = _3180;\n            }\n            bool _3192;\n            if (_3186)\n            {\n                _3192 = _3158 < 1.0f;\n            }\n            else\n            {\n                _3192 = _3186;\n            }\n            if (_3192)\n            {\n                float4 _3218 = fa_screen_tex.Load(int3(clamp(int2(float2(_3154, _3158) * _420_fa_ct_a.zw), int2(0, 0), int2(_420_fa_ct_a.zw) - int2(1, 1)), 0));\n                float _3228 = dot(_420_fa_ct_fwd.xyz, fa_world_pos) + _420_fa_ct_fwd.w;\n                bool _3231 = _3218.w > 0.5f;\n                bool _3245;\n                if (_3231)\n                {\n                    _3245 = abs(_3228 - _3218.x) <= ((0.00200000009499490261077880859375f * _3228) + 0.00999999977648258209228515625f);\n                }\n                else\n                {\n                    _3245 = _3231;\n                }\n                if (_3245)\n                {\n                    return _3218.y;\n                }\n            }\n        }\n    }\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3602 = _420_fa_ct_a.x < 0.5f;\n    bool _3609;\n    if (!_3602)\n    {\n        _3609 = _2072_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3609 = _3602;\n    }\n    if (_3609)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2072_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3622 = fa_light_texel(param);\n    float _3623 = _3622.y;\n    float len = _3623;\n    if (_3623 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3635 = length(world - _420_fa_camera_pos.xyz);\n    float _3644 = 1.0f - smoothstep(0.5f * _420_fa_ct_b.x, _420_fa_ct_b.x, _3635);\n    if (_3644 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3650 = len;\n    float _3653 = min(_3650, 0.89999997615814208984375f * dist);\n    len = _3653;\n    float _3659 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3635);\n    float _3664 = _3659 + (0.5f * _3653);\n    float3 _3670 = world + (gn * _3659);\n    float _3672 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _3734;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3688 = (float(k) + _3672) * 0.083333335816860198974609375f;\n        float3 _3696 = _3670 + (l * (_3688 * len));\n        float4 _3702 = float4(_3696, 1.0f);\n        float _3707 = dot(_420_fa_ct_vpw, _3702);\n        if (_3707 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _3725 = float2(dot(_420_fa_ct_vpx, _3702), dot(_420_fa_ct_vpy, _3702)) / _3707.xx;\n        float _3729 = _3725.x * 0.5f;\n        float _3730 = _3729 + 0.5f;\n        if (_420_fa_ct_a.y > 0.5f)\n        {\n            _3734 = (_3725.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _3734 = 0.5f - (_3725.y * 0.5f);\n        }\n        bool _3750 = _3730 < 0.0f;\n        bool _3757;\n        if (!_3750)\n        {\n            _3757 = _3730 >= 1.0f;\n        }\n        else\n        {\n            _3757 = _3750;\n        }\n        bool _3764;\n        if (!_3757)\n        {\n            _3764 = _3734 < 0.0f;\n        }\n        else\n        {\n            _3764 = _3757;\n        }\n        bool _3771;\n        if (!_3764)\n        {\n            _3771 = _3734 >= 1.0f;\n        }\n        else\n        {\n            _3771 = _3764;\n        }\n        if (_3771)\n        {\n            break;\n        }\n        float4 _3795 = fa_screen_tex.Load(int3(clamp(int2(float2(_3730, _3734) * _420_fa_ct_a.zw), int2(0, 0), int2(_420_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_3795.w < 0.5f)\n        {\n            continue;\n        }\n        float _3813 = (dot(_420_fa_ct_fwd.xyz, _3696) + _420_fa_ct_fwd.w) - _3795.x;\n        if ((_3813 > _3659) && (_3813 < _3664))\n        {\n            occ = max(occ, (1.0f - (_3688 * _3688)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_3730, 0.5f - _3729), min(_3734, 1.0f - _3734))));\n        }\n    }\n    return 1.0f - (occ * _3644);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _3916 = fa_baked_keep(param);\n    if (_3916 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _5764 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _5764;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3942 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _5766 = _3942.color;\n    float _5767 = _3942.attenuation;\n    float _5768 = _3942.shadow;\n    bool _3945 = _3942.type == 0;\n    if (_3945 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3942.direction;\n        float _3956 = fa_shadow_factor(param_5, param_6);\n        _5768 = _3956;\n        _5766 *= _3956;\n    }\n    else\n    {\n        bool _3967 = _3942.type != 0;\n        bool _3973;\n        if (_3967)\n        {\n            _3973 = _5767 > 0.0f;\n        }\n        else\n        {\n            _3973 = _3967;\n        }\n        if (_3973)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3942.direction;\n            float _3992 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5768 = _3992;\n            _5766 *= _3992;\n        }\n    }\n    bool _4002 = _420_fa_ct_a.x > 0.5f;\n    bool _4008;\n    if (_4002)\n    {\n        _4008 = _5767 > 0.0f;\n    }\n    else\n    {\n        _4008 = _4002;\n    }\n    if (_4008)\n    {\n        float _4015;\n        if (_3945)\n        {\n            _4015 = 1000000000.0f;\n        }\n        else\n        {\n            _4015 = _3942._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3942.direction;\n        float param_18 = _4015;\n        float _4033 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5768 *= _4033;\n        _5766 *= _4033;\n    }\n    float _4046 = _5767;\n    float _4047 = _4046 * _3916;\n    _5767 = _4047;\n    float3 _4051 = _5766;\n    float3 _4052 = _4051 * _3916;\n    _5766 = _4052;\n    LightSample _5783 = { _3942.direction, _4052, _4047, _5768, _3942._distance, _3942.type };\n    return _5783;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2072_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3031 = int(_2072_fa_shadow_cfg.x + 0.5f);\n    float _3041 = dot(world - _2072_fa_shadow_eye.xyz, _2072_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3046 = _3031 > 0;\n    bool _3055;\n    if (_3046)\n    {\n        int param = _3031 - 1;\n        _3055 = _3041 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3055 = _3046;\n    }\n    if (_3055)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3061 = _3031 > 1;\n        bool _3068;\n        if (_3061)\n        {\n            _3068 = _3041 > _2072_fa_shadow_split.x;\n        }\n        else\n        {\n            _3068 = _3061;\n        }\n        if (_3068)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3074 = _3031 > 2;\n        bool _3081;\n        if (_3074)\n        {\n            _3081 = _3041 > _2072_fa_shadow_split.y;\n        }\n        else\n        {\n            _3081 = _3074;\n        }\n        if (_3081)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3087 = _3031 > 3;\n        bool _3094;\n        if (_3087)\n        {\n            _3094 = _3041 > _2072_fa_shadow_split.z;\n        }\n        else\n        {\n            _3094 = _3087;\n        }\n        if (_3094)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5558 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5558 = -_5558;\n    }\n    float3 _5132 = normalize(_420_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5571 = { fa_world_pos, _5558, fa_world_tangent, fa_uv, fa_vertex_color, _5132, gl_FrontFacing };\n    SurfaceInput param_1 = _5571;\n    Surface _5140 = fa_standard_surface(param_1);\n    float3 _5597 = _5140.albedo;\n    float _5598 = _5140.alpha;\n    float3 _5599 = _5140.normal;\n    float _5600 = _5140.metallic;\n    float _5601 = _5140.roughness;\n    float _5602 = _5140.occlusion;\n    float3 _5603 = _5140.emission;\n    float _5604 = _5140.clearcoat;\n    float _5605 = _5140.clearcoat_roughness;\n    float3 _5606 = _5140.sheen_color;\n    float _5607 = _5140.sheen_roughness;\n    float _5608 = _5140.anisotropy;\n    float _5609 = _5140.anisotropy_rotation;\n    float _5610 = _5140.specular;\n    float _5611 = _5140.ior;\n    float3 _5612 = _5140.specular_color;\n    float _5613 = _5140.transmission;\n    float _5614 = _5140.thickness;\n    float3 _5615 = _5140.attenuation_color;\n    float _5616 = _5140.attenuation_distance;\n    SurfaceInput _5579 = { fa_world_pos, _5558, fa_world_tangent, fa_uv, fa_vertex_color, _5132, gl_FrontFacing };\n    SurfaceInput param_2 = _5579;\n    Surface param_3 = _5140;\n    surface(param_2, param_3);\n    _5597 = param_3.albedo;\n    _5598 = param_3.alpha;\n    _5599 = param_3.normal;\n    _5600 = param_3.metallic;\n    _5601 = param_3.roughness;\n    _5602 = param_3.occlusion;\n    _5603 = param_3.emission;\n    _5604 = param_3.clearcoat;\n    _5605 = param_3.clearcoat_roughness;\n    _5606 = param_3.sheen_color;\n    _5607 = param_3.sheen_roughness;\n    _5608 = param_3.anisotropy;\n    _5609 = param_3.anisotropy_rotation;\n    _5610 = param_3.specular;\n    _5611 = param_3.ior;\n    _5612 = param_3.specular_color;\n    _5613 = param_3.transmission;\n    _5614 = param_3.thickness;\n    _5615 = param_3.attenuation_color;\n    _5616 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5558;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5597 = param_6;\n    _5599 = param_7;\n    float3 result;\n    if (_420_fa_emissive.w > 0.5f)\n    {\n        result = _5597;\n    }\n    else\n    {\n        float3 _5179 = _5599;\n        float3 _5180 = normalize(_5179);\n        _5599 = _5180;\n        float3 param_8 = _5180;\n        SurfaceInput _5587 = { fa_world_pos, _5558, fa_world_tangent, fa_uv, fa_vertex_color, _5132, gl_FrontFacing };\n        SurfaceInput param_9 = _5587;\n        Surface _5698 = { _5597, _5598, _5599, _5600, _5601, _5602, _5603, _5604, _5605, _5606, _5607, _5608, _5609, _5610, _5611, _5612, _5613, _5614, _5615, _5616 };\n        Surface param_10 = _5698;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _5199 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5199; ln++)\n        {\n            int param_12 = ln;\n            int _5212 = fa_cl_light(param_12);\n            int param_13 = _5212;\n            if (fa_baked_keep(param_13) <= 0.0f)\n            {\n                continue;\n            }\n            int param_14 = _5212;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _5558;\n            LightSample _5228 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _5595 = { fa_world_pos, _5558, fa_world_tangent, fa_uv, fa_vertex_color, _5132, gl_FrontFacing };\n            SurfaceInput param_17 = _5595;\n            Surface _5719 = { _5597, _5598, _5599, _5600, _5601, _5602, _5603, _5604, _5605, _5606, _5607, _5608, _5609, _5610, _5611, _5612, _5613, _5614, _5615, _5616 };\n            Surface param_18 = _5719;\n            LightSample param_19 = _5228;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _5243 = result;\n    float3 _5244 = _5243 + _5603;\n    result = _5244;\n    float3 param_20 = _5244;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _5253 = _420_fa_fog.w > 0.0f;\n    bool _5260;\n    if (!_5253)\n    {\n        _5260 = _420_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5260 = _5253;\n    }\n    if (_5260)\n    {\n        float3 _5269 = fa_world_pos - _420_fa_camera_pos.xyz;\n        float _5275 = dot(_5269, _420_fa_fog_c.xyz);\n        bool _5279 = _420_fa_fog_c.w > 0.5f;\n        float _5280;\n        if (_5279)\n        {\n            _5280 = _5275;\n        }\n        else\n        {\n            _5280 = length(_5269);\n        }\n        float _5292 = _5280 - _420_fa_fog_b.x;\n        if (_5292 > 0.0f)\n        {\n            float _5301 = _420_fa_fog.w * _5292;\n            float tau = _5301 * _5301;\n            if (_420_fa_fog_b.y > 0.0f)\n            {\n                float _5317;\n                if (_5279)\n                {\n                    _5317 = fa_world_pos.y - (_420_fa_fog_c.y * _5275);\n                }\n                else\n                {\n                    _5317 = _420_fa_camera_pos.y;\n                }\n                float _5338 = lerp(_5317, fa_world_pos.y, clamp(_420_fa_fog_b.x / _5280, 0.0f, 1.0f));\n                float _5342 = fa_world_pos.y - _5338;\n                float _5347 = _5338 - _420_fa_fog_b.z;\n                float _5352 = fa_world_pos.y - _420_fa_fog_b.z;\n                bool _5355 = _5347 <= 0.0f;\n                bool _5356 = !_5355;\n                bool _5362;\n                if (_5356)\n                {\n                    _5362 = _420_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5362 = _5355;\n                }\n                float _5363;\n                if (_5362)\n                {\n                    _5363 = _420_fa_fog_b.y;\n                }\n                else\n                {\n                    _5363 = _420_fa_fog_b.y * exp(-min(_420_fa_fog_b.w * _5347, 80.0f));\n                }\n                bool _5390;\n                if (_5356)\n                {\n                    _5390 = _420_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5390 = _5355;\n                }\n                float _5391;\n                if (_5390)\n                {\n                    _5391 = _420_fa_fog_b.y * _5347;\n                }\n                else\n                {\n                    _5391 = (_420_fa_fog_b.y * (1.0f - exp(-min(_420_fa_fog_b.w * _5347, 80.0f)))) / _420_fa_fog_b.w;\n                }\n                bool _5416 = _5352 <= 0.0f;\n                bool _5423;\n                if (!_5416)\n                {\n                    _5423 = _420_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5423 = _5416;\n                }\n                float _5424;\n                if (_5423)\n                {\n                    _5424 = _420_fa_fog_b.y * _5352;\n                }\n                else\n                {\n                    _5424 = (_420_fa_fog_b.y * (1.0f - exp(-min(_420_fa_fog_b.w * _5352, 80.0f)))) / _420_fa_fog_b.w;\n                }\n                float _5451;\n                if (abs(_5342) < 0.001000000047497451305389404296875f)\n                {\n                    _5451 = _5363;\n                }\n                else\n                {\n                    _5451 = (_5424 - _5391) / _5342;\n                }\n                tau += (_5292 * max(_5451, 0.0f));\n            }\n            result = lerp(result, _420_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5598);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_420",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2072",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _420_fa_camera_pos : packoffset(c0);\n    float4 _420_fa_ambient : packoffset(c1);\n    float4 _420_fa_base_color : packoffset(c2);\n    float4 _420_fa_emissive : packoffset(c3);\n    float4 _420_fa_model_emissive : packoffset(c4);\n    float4 _420_fa_pbr : packoffset(c5);\n    float4 _420_fa_maps : packoffset(c6);\n    float4 _420_fa_fog : packoffset(c7);\n    float4 _420_fa_fog_b : packoffset(c8);\n    float4 _420_fa_fog_c : packoffset(c9);\n    float4 _420_fa_counts : packoffset(c10);\n    float4 _420_fa_env_sky : packoffset(c11);\n    float4 _420_fa_env_horizon : packoffset(c12);\n    float4 _420_fa_time : packoffset(c13);\n    float4 _420_fa_cl_vpx : packoffset(c14);\n    float4 _420_fa_cl_vpy : packoffset(c15);\n    float4 _420_fa_cl_vpw : packoffset(c16);\n    float4 _420_fa_cl_fwd : packoffset(c17);\n    float4 _420_fa_cl_grid : packoffset(c18);\n    float4 _420_fa_cl_info : packoffset(c19);\n    float4 _420_fa_layers_a : packoffset(c20);\n    float4 _420_fa_layers_b : packoffset(c21);\n    float4 _420_fa_layers_c : packoffset(c22);\n    float4 _420_fa_layers_d : packoffset(c23);\n    float4 _420_fa_ct_a : packoffset(c24);\n    float4 _420_fa_ct_b : packoffset(c25);\n    float4 _420_fa_ct_vpx : packoffset(c26);\n    float4 _420_fa_ct_vpy : packoffset(c27);\n    float4 _420_fa_ct_vpw : packoffset(c28);\n    float4 _420_fa_ct_fwd : packoffset(c29);\n    float4 _420_fa_tr_a : packoffset(c30);\n    float4 _420_fa_tr_b : packoffset(c31);\n    float4 _420_fa_probe_sh[9] : packoffset(c32);\n    float4 _420_fa_atlas : packoffset(c41);\n    float4 _420_fa_rpa_tile : packoffset(c42);\n    float4 _420_fa_rpa_pos : packoffset(c43);\n    float4 _420_fa_rpa_bx : packoffset(c44);\n    float4 _420_fa_rpa_by : packoffset(c45);\n    float4 _420_fa_rpa_bz : packoffset(c46);\n    float4 _420_fa_rpb_tile : packoffset(c47);\n    float4 _420_fa_rpb_pos : packoffset(c48);\n    float4 _420_fa_rpb_bx : packoffset(c49);\n    float4 _420_fa_rpb_by : packoffset(c50);\n    float4 _420_fa_rpb_bz : packoffset(c51);\n    float4 _420_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2072_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2072_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2072_fa_shadow_info[4] : packoffset(c20);\n    float4 _2072_fa_shadow_split : packoffset(c24);\n    float4 _2072_fa_shadow_cfg : packoffset(c25);\n    float4 _2072_fa_shadow_bias : packoffset(c26);\n    float4 _2072_fa_shadow_eye : packoffset(c27);\n    float4 _2072_fa_shadow_fwd : packoffset(c28);\n    float4 _2072_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1348 = _420_fa_cl_info.x < 0.0f;\n    bool _1355;\n    if (!_1348)\n    {\n        _1355 = _420_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1355 = _1348;\n    }\n    bool _1363;\n    if (!_1355)\n    {\n        _1363 = _420_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1363 = _1355;\n    }\n    bool _1370;\n    if (!_1363)\n    {\n        _1370 = _420_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1370 = _1363;\n    }\n    bool _1377;\n    if (!_1370)\n    {\n        _1377 = _420_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1377 = _1370;\n    }\n    if (_1377)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1387 = float4(world_pos, 1.0f);\n    float _1393 = dot(_420_fa_cl_vpw, _1387);\n    if (!(_1393 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1415 = float2(dot(_420_fa_cl_vpx, _1387), dot(_420_fa_cl_vpy, _1387)) / _1393.xx;\n    int _1419 = int(_420_fa_cl_grid.x);\n    int _1423 = int(_420_fa_cl_grid.y);\n    int param = (int(_420_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_420_fa_cl_fwd.xyz, world_pos) + _420_fa_cl_fwd.w, _420_fa_cl_grid.w) / _420_fa_cl_grid.w) * _420_fa_cl_grid.z)), 0, int(_420_fa_cl_info.y) - 1) * _1423) + clamp(int(floor(((_1415.y * 0.5f) + 0.5f) * _420_fa_cl_grid.y)), 0, _1423 - 1)) * _1419)) + clamp(int(floor(((_1415.x * 0.5f) + 0.5f) * _420_fa_cl_grid.x)), 0, _1419 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1499 = fa_cluster_texel(param);\n    return int2(int(_1499.x), int(_1499.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_420_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3890 = fa_cluster_lookup(param);\n    fa_cl_slot = _3890.x;\n    fa_cl_local = _3890.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4100 = fa_linear_to_srgb(param);\n        c = _4100;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4108 = fa_srgb_to_linear(param_1);\n            c = _4108;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _302;\n    if (i.front_facing)\n    {\n        _302 = i.world_normal;\n    }\n    else\n    {\n        _302 = -i.world_normal;\n    }\n    float3 _326 = normalize(i.world_tangent.xyz - (_302 * dot(_302, i.world_tangent.xyz)));\n    float3 _353 = normalize(((_326 * m.x) + ((cross(_302, _326) * i.world_tangent.w) * m.y)) + (_302 * m.z));\n    float3 _356;\n    if (i.front_facing)\n    {\n        _356 = _353;\n    }\n    else\n    {\n        _356 = -_353;\n    }\n    return _356;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _420_fa_env_horizon.w);\n    float param = _420_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4140 = fa_tex_fix(param_2, param_3);\n    float4 _5959 = base_t;\n    _5959.x = _4140.x;\n    _5959.y = _4140.y;\n    _5959.z = _4140.z;\n    base_t = _5959;\n    float4 _4154 = (_5959 * _420_fa_base_color) * i.vertex_color;\n    float3 _5786 = i.world_normal;\n    if (_420_fa_maps.z > 0.5f)\n    {\n        float param_4 = _420_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _420_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4188 = fa_tex_fix(param_6, param_7);\n        float3 _4191 = (_4188 * 2.0f) - 1.0f.xxx;\n        float2 _4196 = _4191.xy * _420_fa_maps.x;\n        float3 _5967 = _4191;\n        _5967.x = _4196.x;\n        _5967.y = _4196.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5967;\n        _5786 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _420_fa_env_horizon.w);\n    float param_10 = _420_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4226 = fa_tex_fix(param_12, param_13);\n    float4 _5970 = mrt;\n    _5970.x = _4226.x;\n    _5970.y = _4226.y;\n    _5970.z = _4226.z;\n    mrt = _5970;\n    float4 _4256 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _420_fa_env_horizon.w);\n    float param_14 = _420_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4256.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4267 = fa_tex_fix(param_16, param_17);\n    float param_18 = _420_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _420_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4299 = fa_tex_fix(param_20, param_21);\n    float _5791 = _420_fa_layers_a.x;\n    float _5792 = _420_fa_layers_a.y;\n    float _5795 = _420_fa_layers_a.z;\n    float _5794 = _420_fa_layers_b.w;\n    float _5797 = _420_fa_layers_c.x;\n    if (_420_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_420_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _5791 *= _4267.y;\n            _5792 *= _4267.z;\n            _5794 *= _4256.w;\n        }\n        if (_420_fa_layers_c.z > 1.5f)\n        {\n            _5795 *= mrt.x;\n            _5797 *= mrt.w;\n        }\n    }\n    Surface _5824 = { _4154.xyz, _4154.w, _5786, clamp(_420_fa_pbr.x * _4226.z, 0.0f, 1.0f), clamp(_420_fa_pbr.y * _4226.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_420_fa_maps.y * (_4267.x - 1.0f)), _420_fa_emissive.xyz + (_420_fa_model_emissive.xyz * _4299), _5791, _5792, _420_fa_layers_b.xyz, _5794, _5795, _420_fa_layers_a.w, _5797, _420_fa_layers_c.y, _420_fa_layers_d.xyz, _420_fa_tr_a.x, _420_fa_tr_a.y, _420_fa_tr_b.xyz, _420_fa_tr_a.z };\n    return _5824;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1579 = rect.zw - rect.xy;\n    float2 _1583 = _1579 * atlas;\n    float2 _1587 = ddx * _1583;\n    float2 _1591 = ddy * _1583;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1579), clamp(0.5f * log2(max(max(dot(_1587, _1587), dot(_1591, _1591)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1624 = _420_fa_counts.y < 0.5f;\n    bool _1631;\n    if (!_1624)\n    {\n        _1631 = _420_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1631 = _1624;\n    }\n    if (_1631)\n    {\n        return;\n    }\n    float3 _1637 = ddx(world_pos);\n    float3 _1640 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1644 = fa_cluster_texel(param);\n    int _1648 = int(_1644.w);\n    if (_1648 < 1)\n    {\n        return;\n    }\n    int _1658 = int(_420_fa_counts.y + 0.5f);\n    int param_1 = _1658;\n    float4 _1662 = fa_light_texel(param_1);\n    float2 _1665 = _1662.yz;\n    int _1669 = int(_1662.w);\n    int param_2 = _1658 + 1;\n    float4 _1674 = fa_light_texel(param_2);\n    float _1675 = _1674.x;\n    int _1681 = int(_420_fa_counts.w + 0.5f) - 1;\n    int _1685 = int(_1644.z);\n    float3 _1950;\n    for (int k = 0; k < _1648; k++)\n    {\n        int _1698 = _1685 + k;\n        int param_3 = _1669 + (_1698 >> 2);\n        int _1715 = (_1658 + 2) + (int(fa_light_texel(param_3)[_1698 & 3]) * 7);\n        int param_4 = _1715 + 6;\n        float4 _1720 = fa_light_texel(param_4);\n        if (((int(_1720.w + 0.5f) >> _1681) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1715;\n        float4 _1735 = fa_light_texel(param_5);\n        int param_6 = _1715 + 1;\n        float4 _1740 = fa_light_texel(param_6);\n        int param_7 = _1715 + 2;\n        float4 _1745 = fa_light_texel(param_7);\n        float3 _1748 = _1735.xyz;\n        float _1753 = dot(_1748, world_pos) + _1735.w;\n        float3 _1755 = _1740.xyz;\n        float _1760 = dot(_1755, world_pos) + _1740.w;\n        float3 _1762 = _1745.xyz;\n        float _1767 = dot(_1762, world_pos) + _1745.w;\n        bool _1772 = abs(_1753) > 0.5f;\n        bool _1780;\n        if (!_1772)\n        {\n            _1780 = abs(_1760) > 0.5f;\n        }\n        else\n        {\n            _1780 = _1772;\n        }\n        bool _1788;\n        if (!_1780)\n        {\n            _1788 = abs(_1767) > 0.5f;\n        }\n        else\n        {\n            _1788 = _1780;\n        }\n        if (_1788)\n        {\n            continue;\n        }\n        float _1803 = clamp(dot(geo_normal, normalize(_1762)) * _1720.z, 0.0f, 1.0f);\n        if (_1803 <= 0.0f)\n        {\n            continue;\n        }\n        float _1823 = (clamp((0.5f - abs(_1767)) * 10.0f, 0.0f, 1.0f) * _1803) * _1720.x;\n        float2 _1831 = float2(_1753 + 0.5f, 0.5f - _1760);\n        float2 _1841 = float2(dot(_1748, _1637), dot(_1755, _1637));\n        float2 _1851 = float2(dot(_1748, _1640), dot(_1755, _1640));\n        int param_8 = _1715 + 5;\n        float4 _1856 = fa_light_texel(param_8);\n        int param_9 = _1715 + 3;\n        float4 _1861 = fa_light_texel(param_9);\n        int param_10 = _1715 + 4;\n        float4 _1866 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1856.xyz;\n        bool _1876 = _1861.z > _1861.x;\n        if (_1876)\n        {\n            float4 param_11 = _1861;\n            float2 param_12 = _1831;\n            float2 param_13 = _1665;\n            float2 param_14 = _1841;\n            float2 param_15 = _1851;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1675 > 0.5f) && (_1675 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1902 = fa_dc_to_linear(param_16);\n                float4 _5874 = tx;\n                _5874.x = _1902.x;\n                _5874.y = _1902.y;\n                _5874.z = _1902.z;\n                tx = _5874;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1823 * tex_a) * _1856.w, 0.0f, 1.0f).xxx);\n        if (_1866.z > _1866.x)\n        {\n            float4 param_17 = _1866;\n            float2 param_18 = _1831;\n            float2 param_19 = _1665;\n            float2 param_20 = _1841;\n            float2 param_21 = _1851;\n            float4 _1946 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1675 > 1.5f)\n            {\n                float3 param_22 = _1946.xyz;\n                float3 _1956 = fa_dc_to_srgb(param_22);\n                _1950 = _1956;\n            }\n            else\n            {\n                _1950 = _1946.xyz;\n            }\n            float3 _1965 = (_1950 * 2.0f) - 1.0f.xxx;\n            float2 _1970 = _1965.xy * _1720.y;\n            float3 _1992 = (normalize(_1748) * _1970.x) + (normalize(_1755) * _1970.y);\n            float3 _1995 = normalize(normal);\n            normal = normalize(lerp(_1995, normalize((_1995 * max(_1965.z, 0.0500000007450580596923828125f)) + (_1992 - (_1995 * dot(_1995, _1992)))), clamp(_1823 * (_1876 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3411_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3411_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_420_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3352 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3352;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3462 = (1.0f - _420_fa_rpa_tile.w) - _420_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3468 = _420_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3462 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3468)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _420_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3462;\n            }\n        }\n        else\n        {\n            amb = _420_fa_ambient.xyz * _3462;\n        }\n    }\n    bool _3520 = _420_fa_rpa_tile.w > 0.0f;\n    if (_3520)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _420_fa_rpa_tile.xy;\n            float param_4 = _420_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _420_fa_rpa_tile.w);\n        }\n    }\n    bool _3551 = _420_fa_rpb_tile.w > 0.0f;\n    if (_3551)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _420_fa_rpb_tile.xy;\n            float param_7 = _420_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _420_fa_rpb_tile.w);\n        }\n    }\n    if ((_3468 || _3520) || _3551)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3372 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3375 = _3372.x;\n    float _3377 = _3372.z;\n    float2 e = float2(_3375, _3377);\n    if (_3372.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3377)) * ((_3375 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3375)) * ((_3377 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _4413 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _4418 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _4423 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _4428 = fa_light_texel(param_3);\n    bool _4431 = _4428.z < 0.5f;\n    bool _4439;\n    if (!_4431)\n    {\n        _4439 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _4439 = _4431;\n    }\n    if (_4439)\n    {\n        return 0.0f.xxx;\n    }\n    float _4446 = max(_4413.w, 9.9999997473787516355514526367188e-05f);\n    float3 _4449 = _4418.xyz;\n    float3 _4453 = _4413.xyz;\n    float3 _4457 = (fa_world_pos - _4453) / _4446.xxx;\n    float3 _4466 = min(_4457 + 0.5f.xxx, (_4449 - 0.5f.xxx) - _4457);\n    float _4475 = min(_4466.x, min(_4466.y, _4466.z));\n    if (!(_4475 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4490 = _4449 - 1.0f.xxx;\n    float3 _4491 = clamp(_4457, 0.0f.xxx, _4490);\n    float3 _4499 = min(floor(_4491), max(_4449 - 2.0f.xxx, 0.0f.xxx));\n    float3 _4503 = _4491 - _4499;\n    float3 _4515 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _4446));\n    int _4520 = int(_4423.y + 0.5f);\n    float _4525 = 0.3257350027561187744140625f * n.y;\n    float _4529 = 0.3257350027561187744140625f * n.z;\n    float _4533 = 0.3257350027561187744140625f * n.x;\n    float _4540 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _4547 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _4556 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _4563 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _4576 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _4583 = 8 + int(_4428.w);\n    float _4610;\n    float _4623;\n    float _4637;\n    for (int k = 0; k < _4583; k++)\n    {\n        float _4596 = float(k & 1);\n        float _4600 = float((k >> 1) & 1);\n        float _4604 = float((k >> 2) & 1);\n        if (_4596 > 0.5f)\n        {\n            _4610 = _4503.x;\n        }\n        else\n        {\n            _4610 = 1.0f - _4503.x;\n        }\n        if (_4600 > 0.5f)\n        {\n            _4623 = _4503.y;\n        }\n        else\n        {\n            _4623 = 1.0f - _4503.y;\n        }\n        if (_4604 > 0.5f)\n        {\n            _4637 = _4503.z;\n        }\n        else\n        {\n            _4637 = 1.0f - _4503.z;\n        }\n        float _4647 = (_4610 * _4623) * _4637;\n        if (!(_4647 > 0.0f))\n        {\n            continue;\n        }\n        float3 _4660 = min(_4499 + float3(_4596, _4600, _4604), _4490);\n        int _4680 = int(((_4423.x + _4660.x) + (_4418.x * (_4660.y + (_4418.y * _4660.z)))) + 0.5f);\n        float2 _4695 = float2(float(_4680 % _4520) * 10.0f, 1024.0f + (float(_4680 / _4520) * 11.0f));\n        float2 param_4 = _4695 + float2(9.5f, 10.5f);\n        float4 _4703 = fa_gi_fetch(param_4);\n        bool _4706 = _4703.y < 0.5f;\n        bool _4715;\n        if (!_4706)\n        {\n            _4715 = _4703.x > _4428.y;\n        }\n        else\n        {\n            _4715 = _4706;\n        }\n        if (_4715)\n        {\n            continue;\n        }\n        float3 _4727 = _4515 - (_4453 + (_4660 * _4446));\n        float _4730 = length(_4727);\n        float3 _4736 = _4727 / max(_4730, 9.9999997473787516355514526367188e-05f).xxx;\n        float _4746 = max(9.9999997473787516355514526367188e-05f, (dot(-_4736, n) + 1.0f) * 0.5f);\n        float w = _4647 * (_4746 * _4746);\n        float3 param_5 = _4736;\n        float2 param_6 = (_4695 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _4766 = fa_gi_fetch(param_6);\n        float _4773 = _4730 / max(_4423.z, 9.9999997473787516355514526367188e-05f);\n        float _4776 = _4766.x;\n        if (_4773 > _4776)\n        {\n            float _4789 = max(_4766.y - (_4776 * _4776), 0.0f);\n            float _4794 = _4773 - _4776;\n            float _4803 = _4789 / max(_4789 + (_4794 * _4794), 9.9999999600419720025001879548654e-13f);\n            w *= ((_4803 * _4803) * _4803);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _4695 + float2(0.5f, 10.5f);\n        float2 param_8 = _4695 + float2(1.5f, 10.5f);\n        float2 param_9 = _4695 + float2(2.5f, 10.5f);\n        float2 param_10 = _4695 + float2(3.5f, 10.5f);\n        float2 param_11 = _4695 + float2(4.5f, 10.5f);\n        float2 param_12 = _4695 + float2(5.5f, 10.5f);\n        float2 param_13 = _4695 + float2(6.5f, 10.5f);\n        float2 param_14 = _4695 + float2(7.5f, 10.5f);\n        float2 param_15 = _4695 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _4525)) + (fa_gi_fetch(param_9).xyz * _4529)) + (fa_gi_fetch(param_10).xyz * _4533)) + (fa_gi_fetch(param_11).xyz * _4540)) + (fa_gi_fetch(param_12).xyz * _4547)) + (fa_gi_fetch(param_13).xyz * _4556)) + (fa_gi_fetch(param_14).xyz * _4563)) + (fa_gi_fetch(param_15).xyz * _4576)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_4475 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _4931;\n    if (_420_fa_gi.z > 0.5f)\n    {\n        _4931 = _4428.x;\n    }\n    else\n    {\n        _4931 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_4423.w * _4931);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _4955 = normalize(_420_fa_camera_pos.xyz - fa_world_pos);\n    int _4960 = int(_420_fa_gi.x + 0.5f);\n    int _4965 = int(_420_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _4965) && (k < 8); k++)\n    {\n        int param = _4960 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _4955;\n        float3 _4990 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _4995 = param_3 * left;\n        acc += (_4990 * _4995);\n        left -= _4995;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_420_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _5024 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5024;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_420_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _420_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_420_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return float3(0.0f, ambientColor.y, 0.0f);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_420_fa_cl_info.x) + int(_420_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_420_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3860;\n    if (fa_lm.z > 0.5f)\n    {\n        _3860 = 0.0f;\n    }\n    else\n    {\n        _3860 = 1.0f - clamp(_420_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _3871 = _3860 < 1.0f;\n    bool _3877;\n    if (_3871)\n    {\n        int param = li;\n        _3877 = fa_light_baked(param);\n    }\n    else\n    {\n        _3877 = _3871;\n    }\n    return _3877 ? _3860 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _598 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _611 = (c - (ru * hx)) - p;\n        float3 _617 = ru * (2.0f * hx);\n        float _623 = max(dot(_617, _617), 9.9999999392252902907785028219223e-09f);\n        float _627 = dot(_611, _617);\n        float t = clamp((-_627) / _623, 0.0f, 1.0f);\n        if (_598)\n        {\n            float _642 = dot(r, _617);\n            float _648 = _623 - (_642 * _642);\n            if (abs(_648) > (9.9999997473787516355514526367188e-06f * _623))\n            {\n                t = clamp(((dot(r, _611) * _642) - _627) / _648, 0.0f, 1.0f);\n            }\n        }\n        return (p + _611) + (_617 * t);\n    }\n    float3 q = p;\n    float _680 = dot(r, axis);\n    bool _688;\n    if (_598)\n    {\n        _688 = abs(_680) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _688 = _598;\n    }\n    if (_688)\n    {\n        float _698 = dot(c - p, axis) / _680;\n        if (_698 > 0.0f)\n        {\n            q = p + (r * _698);\n        }\n    }\n    float3 _711 = q - c;\n    float2 xy = float2(dot(_711, ru), dot(_711, uu));\n    if (shape > 0.5f)\n    {\n        float _726 = length(xy);\n        if (_726 > hx)\n        {\n            xy *= (hx / _726);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _479_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _479_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _518 = dot(d, right);\n    float _522 = dot(d, up);\n    float _533;\n    if (((_518 * _518) + (_522 * _522)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _533 = atan2(_522, _518) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _533 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_533 - floor(_533)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _368 = abs(d);\n    float _370 = _368.x;\n    float _372 = _368.y;\n    bool _373 = _370 >= _372;\n    bool _381;\n    if (_373)\n    {\n        _381 = _370 >= _368.z;\n    }\n    else\n    {\n        _381 = _373;\n    }\n    int _382;\n    if (_381)\n    {\n        _382 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _397;\n        if (_372 >= _368.z)\n        {\n            _397 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _397 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _382 = _397;\n    }\n    return _382;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _764 = fa_light_base(param);\n    bool _768 = _420_fa_ambient.w > 4.5f;\n    int param_1 = _764;\n    float4 _772 = fa_light_texel(param_1);\n    int param_2 = _764 + 1;\n    float4 _777 = fa_light_texel(param_2);\n    float _780 = _777.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _792 = _768 && (_780 > 2.5f);\n    fa_light_is_area = _792;\n    bool _794 = _780 < 0.5f;\n    float3 l;\n    if (_794)\n    {\n        l = normalize(_772.xyz);\n        if (_768)\n        {\n            int param_3 = _764 + 6;\n            float4 _808 = fa_light_texel(param_3);\n            if (_808.z > 0.5f)\n            {\n                int param_4 = _764 + 4;\n                float4 _818 = fa_light_texel(param_4);\n                int param_5 = _764 + 5;\n                float4 _823 = fa_light_texel(param_5);\n                float2 param_6 = _808.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _818.xyz) * _818.w, (-dot(world_pos, _823.xyz)) * _823.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _853 = _772.xyz;\n        float3 _855 = _853 - world_pos;\n        float3 to_light = _855;\n        float _858 = length(_855);\n        float reach = _858;\n        bool front = true;\n        if (_792)\n        {\n            int param_8 = _764 + 7;\n            reach = max(_858 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _764 + 4;\n            float4 _882 = fa_light_texel(param_9);\n            int param_10 = _764 + 5;\n            float4 _887 = fa_light_texel(param_10);\n            int param_11 = _764 + 6;\n            float4 _892 = fa_light_texel(param_11);\n            float _893 = _892.w;\n            int param_12 = _764 + 2;\n            float3 _900 = normalize(fa_light_texel(param_12).xyz);\n            bool _902 = _893 > 1.5f;\n            bool _910;\n            if (!_902)\n            {\n                _910 = dot(_900, to_light) < 0.0f;\n            }\n            else\n            {\n                _910 = _902;\n            }\n            front = _910;\n            float3 r = 0.0f.xxx;\n            float3 _919 = _420_fa_camera_pos.xyz - world_pos;\n            bool _923 = dot(n, n) > 0.5f;\n            bool _931;\n            if (_923)\n            {\n                _931 = dot(_919, _919) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _931 = _923;\n            }\n            if (_931)\n            {\n                r = reflect(-normalize(_919), normalize(n));\n            }\n            float3 param_13 = _853;\n            float3 param_14 = _900;\n            float3 param_15 = _882.xyz;\n            float3 param_16 = _887.xyz;\n            float param_17 = _882.w;\n            float param_18 = _887.w;\n            float param_19 = _893;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _967 = length(to_light);\n        dist = _967;\n        l = to_light / max(_967, 9.9999997473787516355514526367188e-05f).xxx;\n        float _981 = reach / max(_772.w, 0.001000000047497451305389404296875f);\n        float _987 = clamp(1.0f - (_981 * _981), 0.0f, 1.0f);\n        float _989;\n        if (front)\n        {\n            _989 = _987 * _987;\n        }\n        else\n        {\n            _989 = 0.0f;\n        }\n        atten = _989;\n        bool _1000 = _780 < 2.5f;\n        if ((_780 > 1.5f) && _1000)\n        {\n            int param_22 = _764 + 2;\n            float4 _1008 = fa_light_texel(param_22);\n            float _1018 = _1008.w;\n            int param_23 = _764 + 3;\n            float4 _1023 = fa_light_texel(param_23);\n            float _1024 = _1023.x;\n            float cos_inner = _1024;\n            if (_1024 > 1.5f)\n            {\n                cos_inner = lerp(_1018, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1018, cos_inner, dot(-l, normalize(_1008.xyz)));\n        }\n        if (_768 && (_780 < 1.5f))\n        {\n            int param_24 = _764 + 6;\n            float4 _1048 = fa_light_texel(param_24);\n            if (_1048.z > 0.5f)\n            {\n                float3 _1056 = -to_light;\n                int param_25 = _764 + 4;\n                int param_26 = _764 + 5;\n                float3 _1070 = fa_light_texel(param_25).xyz;\n                float3 _1074 = fa_light_texel(param_26).xyz;\n                float3 _1083 = float3(dot(_1056, _1070), dot(_1056, _1074), dot(_1056, cross(_1070, _1074)));\n                float3 param_27 = _1083;\n                int _1087 = fa_cube_face(param_27);\n                int param_28 = _1087;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1114 = float2(dot(_1083, cross(param_29, param_30)), dot(_1083, param_30)) / max(dot(_1083, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1118 = _1087 / 3;\n                float2 param_31 = _1048.xy + (float2(float(_1087 - (_1118 * 3)), float(_1118)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1114.x), 0.5f - (0.5f * _1114.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _764 + 7;\n            float4 _1148 = fa_light_texel(param_33);\n            if (_1148.z > 0.5f)\n            {\n                int param_34 = _764 + 2;\n                int param_35 = _764 + 4;\n                int param_36 = _764 + 5;\n                float2 param_37 = _1148.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_768 && _1000)\n            {\n                int param_42 = _764 + 6;\n                float4 _1195 = fa_light_texel(param_42);\n                int param_43 = _764 + 7;\n                float4 _1200 = fa_light_texel(param_43);\n                bool _1203 = _1195.z > 0.5f;\n                bool _1210;\n                if (!_1203)\n                {\n                    _1210 = _1200.z > 0.5f;\n                }\n                else\n                {\n                    _1210 = _1203;\n                }\n                if (_1210)\n                {\n                    int param_44 = _764 + 2;\n                    float4 _1217 = fa_light_texel(param_44);\n                    float3 _1221 = normalize(_1217.xyz);\n                    int param_45 = _764 + 4;\n                    float4 _1226 = fa_light_texel(param_45);\n                    int param_46 = _764 + 5;\n                    float4 _1231 = fa_light_texel(param_46);\n                    if (_1203)\n                    {\n                        float3 _1239 = -to_light;\n                        float _1246 = _1217.w;\n                        float _1262 = 0.5f / max(dot(_1239, _1221) * (sqrt(max(1.0f - (_1246 * _1246), 0.0f)) / max(_1246, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1195.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1239, _1226.xyz) * _1262), 0.5f - (dot(_1239, _1231.xyz) * _1262));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1200.z > 0.5f)\n                    {\n                        float2 param_49 = _1200.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1221;\n                        float3 param_52 = _1226.xyz;\n                        float3 param_53 = _1231.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _5740 = _777.xyz * atten;\n    if (_768)\n    {\n        _5740 *= fa_light_tint;\n    }\n    int _1330;\n    if (_794)\n    {\n        _1330 = 0;\n    }\n    else\n    {\n        _1330 = ((_780 > 1.5f) && (_780 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _5751 = { l, _5740, atten, 1.0f, dist, _1330 };\n    return _5751;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2119 = fa_shadow_depth(param, param_1);\n    float _2123;\n    if (conv.x < 0.5f)\n    {\n        _2123 = _2119;\n    }\n    else\n    {\n        _2123 = (conv.y * conv.z) / (conv.z - (_2119 * (conv.z - conv.y)));\n    }\n    return _2123;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2169 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2175 = float2(cos(_2169), sin(_2169));\n    float2 dir = _2175;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2184;\n        if (k < 0.0f)\n        {\n            _2184 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2184 = k;\n        }\n        float _2203 = clamp((_2184 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2222 = sqrt((float(i) + 0.5f) * 0.0625f) * _2203;\n            float2 param_3 = uv + (dir * (_2072_fa_shadow_bias.zw * _2222));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2236 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2236 < (zr - (_2222 * plane)))\n            {\n                sum += _2236;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2264 = sum / cnt;\n        float _2274;\n        if (k < 0.0f)\n        {\n            _2274 = (-k) / max(_2264, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2274 = k;\n        }\n        radius = clamp(((max(zr - _2264, 0.0f) * unit) * _2274) / texel_m, 1.5f, 16.0f);\n        dir = _2175;\n    }\n    float lit = 0.0f;\n    int _2300 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2300; i_1++)\n    {\n        float _2319 = sqrt((float(i_1) + 0.5f) / float(_2300)) * radius;\n        float2 param_7 = uv + (dir * (_2072_fa_shadow_bias.zw * _2319));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2319 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2300);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2524 = _420_fa_pbr.z < 0.5f;\n    bool _2531;\n    if (!_2524)\n    {\n        _2531 = _2072_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2531 = _2524;\n    }\n    if (_2531)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2072_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2544 = fa_light_texel(param);\n    float _2545 = _2544.x;\n    if (_2545 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2554 = int(_2545 + 0.5f);\n    int param_1 = _2554;\n    float4 _2558 = fa_light_texel(param_1);\n    int param_2 = _2554 + 1;\n    float4 _2563 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2566 = _2558.y;\n    if (_2566 > 0.0f)\n    {\n        float _2583 = 1.0f - smoothstep(0.75f * _2566, _2566, length(world - _2072_fa_shadow_eye.xyz));\n        fade = _2583;\n        if (_2583 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2558.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2607 = (_2554 + 2) + (face * 6);\n    int param_4 = _2607;\n    int param_5 = _2607 + 1;\n    int param_6 = _2607 + 3;\n    float4 _2621 = fa_light_texel(param_6);\n    int param_7 = _2607 + 4;\n    float4 _2626 = fa_light_texel(param_7);\n    int param_8 = _2607 + 5;\n    float4 _2631 = fa_light_texel(param_8);\n    float _2643 = _2631.x * max(dot(_2621, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2648 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2671 = clamp(dot(n, _2621.xyz), -1.0f, 1.0f);\n    float _2690 = min(sqrt(1.0f - (_2671 * _2671)) / max(abs(dot(n, world - lpos)) / max(dot(_2621, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2693 = _2563.y;\n    float _2695;\n    if (_2693 > 0.0f)\n    {\n        _2695 = _2693;\n    }\n    else\n    {\n        _2695 = 1.5f * _2643;\n    }\n    float4 _2715 = float4(world + (n * (_2695 * sqrt(1.0f - (_2648 * _2648)))), 1.0f);\n    float _2719 = dot(_2621, _2715);\n    float _2722 = _2631.y;\n    if (_2719 < _2722)\n    {\n        return 1.0f;\n    }\n    float2 _2737 = float2(dot(fa_light_texel(param_4), _2715), dot(fa_light_texel(param_5), _2715)) / _2719.xx;\n    float _2739 = _2737.x;\n    bool _2742 = _2739 < _2626.x;\n    bool _2751;\n    if (!_2742)\n    {\n        _2751 = _2739 > _2626.z;\n    }\n    else\n    {\n        _2751 = _2742;\n    }\n    bool _2760;\n    if (!_2751)\n    {\n        _2760 = _2737.y < _2626.y;\n    }\n    else\n    {\n        _2760 = _2751;\n    }\n    bool _2769;\n    if (!_2760)\n    {\n        _2769 = _2737.y > _2626.w;\n    }\n    else\n    {\n        _2769 = _2760;\n    }\n    if (_2769)\n    {\n        return 1.0f;\n    }\n    float _2775 = _2563.x;\n    float _2777;\n    if (_2775 > 0.0f)\n    {\n        _2777 = _2775;\n    }\n    else\n    {\n        _2777 = 1.5f * _2643;\n    }\n    float2 param_9 = _2737;\n    float4 param_10 = _2626;\n    float param_11 = _2719 - (_2777 * (1.0f + (0.5f * _2690)));\n    float param_12 = _2643;\n    float param_13 = 1.0f;\n    float param_14 = _2631.z * 0.25f;\n    float param_15 = (_2643 * min(_2690, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2722, _2631.z);\n    int param_17 = int(_2558.z + 0.5f);\n    float param_18 = _2558.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2062;\n    if (i == 0)\n    {\n        _2062 = _2072_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2078;\n        if (i == 1)\n        {\n            _2078 = _2072_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2086;\n            if (i == 2)\n            {\n                _2086 = _2072_fa_shadow_split.z;\n            }\n            else\n            {\n                _2086 = _2072_fa_shadow_split.w;\n            }\n            _2078 = _2086;\n        }\n        _2062 = _2078;\n    }\n    return _2062;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2365 = max(_2072_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2370 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2376 = sqrt(1.0f - (_2370 * _2370));\n    float _2384 = min(_2376 / max(_2370, 0.20000000298023223876953125f), 4.0f);\n    float _2389;\n    if (_2072_fa_shadow_bias.y > 0.0f)\n    {\n        _2389 = _2072_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2389 = 1.5f * _2072_fa_shadow_info[ci].x;\n    }\n    float4 _2414 = mul(float4(world + (n * (_2389 * _2376)), 1.0f), _2072_fa_shadow_mat[ci]);\n    float _2421 = _2414.x;\n    bool _2424 = _2421 < _2072_fa_shadow_rect[ci].x;\n    bool _2433;\n    if (!_2424)\n    {\n        _2433 = _2421 > _2072_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2433 = _2424;\n    }\n    bool _2442;\n    if (!_2433)\n    {\n        _2442 = _2414.y < _2072_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2442 = _2433;\n    }\n    bool _2451;\n    if (!_2442)\n    {\n        _2451 = _2414.y > _2072_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2451 = _2442;\n    }\n    bool _2458;\n    if (!_2451)\n    {\n        _2458 = _2414.z > 1.0f;\n    }\n    else\n    {\n        _2458 = _2451;\n    }\n    if (_2458)\n    {\n        return -1.0f;\n    }\n    float _2466;\n    if (_2072_fa_shadow_bias.x > 0.0f)\n    {\n        _2466 = _2072_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2466 = 1.5f * _2072_fa_shadow_info[ci].x;\n    }\n    float2 param = _2414.xy;\n    float4 param_1 = _2072_fa_shadow_rect[ci];\n    float param_2 = _2414.z - ((_2466 * (1.0f + (0.5f * _2384))) / _2365);\n    float param_3 = _2072_fa_shadow_info[ci].x;\n    float param_4 = _2365;\n    float param_5 = _2365 * 0.25f;\n    float param_6 = ((_2072_fa_shadow_info[ci].x * min(_2384, 3.0f)) * 0.5f) / _2365;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2072_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2072_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_420_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2844 = int(_2072_fa_shadow_cfg.x + 0.5f);\n    if (_2844 < 1)\n    {\n        return 1.0f;\n    }\n    float _2859 = dot(world - _2072_fa_shadow_eye.xyz, _2072_fa_shadow_fwd.xyz);\n    int param = _2844 - 1;\n    if (_2859 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2871 = _2844 > 1;\n    bool _2878;\n    if (_2871)\n    {\n        _2878 = _2859 > _2072_fa_shadow_split.x;\n    }\n    else\n    {\n        _2878 = _2871;\n    }\n    if (_2878)\n    {\n        ci = 1;\n    }\n    bool _2882 = _2844 > 2;\n    bool _2889;\n    if (_2882)\n    {\n        _2889 = _2859 > _2072_fa_shadow_split.y;\n    }\n    else\n    {\n        _2889 = _2882;\n    }\n    if (_2889)\n    {\n        ci = 2;\n    }\n    bool _2893 = _2844 > 3;\n    bool _2900;\n    if (_2893)\n    {\n        _2900 = _2859 > _2072_fa_shadow_split.z;\n    }\n    else\n    {\n        _2900 = _2893;\n    }\n    if (_2900)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _2911 = min(_2844, 4);\n    float _2952;\n    for (int c = ci; c < _2911; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2931 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _2931;\n            break;\n        }\n        if (_2931 < 0.0f)\n        {\n            continue;\n        }\n        s = _2931;\n        ci = c;\n        if (_2072_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2952 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2952 = _2072_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _2971 = _2072_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2952, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_2859 - (fa_shadow_split_at(param_7) - _2971)) / _2971, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3003;\n        if ((ci + 1) < _2844)\n        {\n            _3003 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3003 = 1.0f;\n        }\n        s = lerp(s, _3003, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    bool _3108 = _420_fa_ct_b.y > 0.5f;\n    bool _3114;\n    if (_3108)\n    {\n        _3114 = _420_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3114 = _3108;\n    }\n    if (_3114)\n    {\n        float4 _3124 = float4(fa_world_pos, 1.0f);\n        float _3130 = dot(_420_fa_ct_vpw, _3124);\n        if (_3130 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _3149 = float2(dot(_420_fa_ct_vpx, _3124), dot(_420_fa_ct_vpy, _3124)) / _3130.xx;\n            float _3154 = (_3149.x * 0.5f) + 0.5f;\n            float _3158;\n            if (_420_fa_ct_a.y > 0.5f)\n            {\n                _3158 = (_3149.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _3158 = 0.5f - (_3149.y * 0.5f);\n            }\n            bool _3174 = _3154 >= 0.0f;\n            bool _3180;\n            if (_3174)\n            {\n                _3180 = _3154 < 1.0f;\n            }\n            else\n            {\n                _3180 = _3174;\n            }\n            bool _3186;\n            if (_3180)\n            {\n                _3186 = _3158 >= 0.0f;\n            }\n            else\n            {\n                _3186 = _3180;\n            }\n            bool _3192;\n            if (_3186)\n            {\n                _3192 = _3158 < 1.0f;\n            }\n            else\n            {\n                _3192 = _3186;\n            }\n            if (_3192)\n            {\n                float4 _3218 = fa_screen_tex.Load(int3(clamp(int2(float2(_3154, _3158) * _420_fa_ct_a.zw), int2(0, 0), int2(_420_fa_ct_a.zw) - int2(1, 1)), 0));\n                float _3228 = dot(_420_fa_ct_fwd.xyz, fa_world_pos) + _420_fa_ct_fwd.w;\n                bool _3231 = _3218.w > 0.5f;\n                bool _3245;\n                if (_3231)\n                {\n                    _3245 = abs(_3228 - _3218.x) <= ((0.00200000009499490261077880859375f * _3228) + 0.00999999977648258209228515625f);\n                }\n                else\n                {\n                    _3245 = _3231;\n                }\n                if (_3245)\n                {\n                    return _3218.y;\n                }\n            }\n        }\n    }\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3602 = _420_fa_ct_a.x < 0.5f;\n    bool _3609;\n    if (!_3602)\n    {\n        _3609 = _2072_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3609 = _3602;\n    }\n    if (_3609)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2072_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3622 = fa_light_texel(param);\n    float _3623 = _3622.y;\n    float len = _3623;\n    if (_3623 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3635 = length(world - _420_fa_camera_pos.xyz);\n    float _3644 = 1.0f - smoothstep(0.5f * _420_fa_ct_b.x, _420_fa_ct_b.x, _3635);\n    if (_3644 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3650 = len;\n    float _3653 = min(_3650, 0.89999997615814208984375f * dist);\n    len = _3653;\n    float _3659 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3635);\n    float _3664 = _3659 + (0.5f * _3653);\n    float3 _3670 = world + (gn * _3659);\n    float _3672 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _3734;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3688 = (float(k) + _3672) * 0.083333335816860198974609375f;\n        float3 _3696 = _3670 + (l * (_3688 * len));\n        float4 _3702 = float4(_3696, 1.0f);\n        float _3707 = dot(_420_fa_ct_vpw, _3702);\n        if (_3707 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _3725 = float2(dot(_420_fa_ct_vpx, _3702), dot(_420_fa_ct_vpy, _3702)) / _3707.xx;\n        float _3729 = _3725.x * 0.5f;\n        float _3730 = _3729 + 0.5f;\n        if (_420_fa_ct_a.y > 0.5f)\n        {\n            _3734 = (_3725.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _3734 = 0.5f - (_3725.y * 0.5f);\n        }\n        bool _3750 = _3730 < 0.0f;\n        bool _3757;\n        if (!_3750)\n        {\n            _3757 = _3730 >= 1.0f;\n        }\n        else\n        {\n            _3757 = _3750;\n        }\n        bool _3764;\n        if (!_3757)\n        {\n            _3764 = _3734 < 0.0f;\n        }\n        else\n        {\n            _3764 = _3757;\n        }\n        bool _3771;\n        if (!_3764)\n        {\n            _3771 = _3734 >= 1.0f;\n        }\n        else\n        {\n            _3771 = _3764;\n        }\n        if (_3771)\n        {\n            break;\n        }\n        float4 _3795 = fa_screen_tex.Load(int3(clamp(int2(float2(_3730, _3734) * _420_fa_ct_a.zw), int2(0, 0), int2(_420_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_3795.w < 0.5f)\n        {\n            continue;\n        }\n        float _3813 = (dot(_420_fa_ct_fwd.xyz, _3696) + _420_fa_ct_fwd.w) - _3795.x;\n        if ((_3813 > _3659) && (_3813 < _3664))\n        {\n            occ = max(occ, (1.0f - (_3688 * _3688)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_3730, 0.5f - _3729), min(_3734, 1.0f - _3734))));\n        }\n    }\n    return 1.0f - (occ * _3644);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _3916 = fa_baked_keep(param);\n    if (_3916 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _5764 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _5764;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3942 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _5766 = _3942.color;\n    float _5767 = _3942.attenuation;\n    float _5768 = _3942.shadow;\n    bool _3945 = _3942.type == 0;\n    if (_3945 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3942.direction;\n        float _3956 = fa_shadow_factor(param_5, param_6);\n        _5768 = _3956;\n        _5766 *= _3956;\n    }\n    else\n    {\n        bool _3967 = _3942.type != 0;\n        bool _3973;\n        if (_3967)\n        {\n            _3973 = _5767 > 0.0f;\n        }\n        else\n        {\n            _3973 = _3967;\n        }\n        if (_3973)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3942.direction;\n            float _3992 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5768 = _3992;\n            _5766 *= _3992;\n        }\n    }\n    bool _4002 = _420_fa_ct_a.x > 0.5f;\n    bool _4008;\n    if (_4002)\n    {\n        _4008 = _5767 > 0.0f;\n    }\n    else\n    {\n        _4008 = _4002;\n    }\n    if (_4008)\n    {\n        float _4015;\n        if (_3945)\n        {\n            _4015 = 1000000000.0f;\n        }\n        else\n        {\n            _4015 = _3942._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3942.direction;\n        float param_18 = _4015;\n        float _4033 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5768 *= _4033;\n        _5766 *= _4033;\n    }\n    float _4046 = _5767;\n    float _4047 = _4046 * _3916;\n    _5767 = _4047;\n    float3 _4051 = _5766;\n    float3 _4052 = _4051 * _3916;\n    _5766 = _4052;\n    LightSample _5783 = { _3942.direction, _4052, _4047, _5768, _3942._distance, _3942.type };\n    return _5783;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2072_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3031 = int(_2072_fa_shadow_cfg.x + 0.5f);\n    float _3041 = dot(world - _2072_fa_shadow_eye.xyz, _2072_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3046 = _3031 > 0;\n    bool _3055;\n    if (_3046)\n    {\n        int param = _3031 - 1;\n        _3055 = _3041 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3055 = _3046;\n    }\n    if (_3055)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3061 = _3031 > 1;\n        bool _3068;\n        if (_3061)\n        {\n            _3068 = _3041 > _2072_fa_shadow_split.x;\n        }\n        else\n        {\n            _3068 = _3061;\n        }\n        if (_3068)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3074 = _3031 > 2;\n        bool _3081;\n        if (_3074)\n        {\n            _3081 = _3041 > _2072_fa_shadow_split.y;\n        }\n        else\n        {\n            _3081 = _3074;\n        }\n        if (_3081)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3087 = _3031 > 3;\n        bool _3094;\n        if (_3087)\n        {\n            _3094 = _3041 > _2072_fa_shadow_split.z;\n        }\n        else\n        {\n            _3094 = _3087;\n        }\n        if (_3094)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5558 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5558 = -_5558;\n    }\n    float3 _5132 = normalize(_420_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5571 = { fa_world_pos, _5558, fa_world_tangent, fa_uv, fa_vertex_color, _5132, gl_FrontFacing };\n    SurfaceInput param_1 = _5571;\n    Surface _5140 = fa_standard_surface(param_1);\n    float3 _5597 = _5140.albedo;\n    float _5598 = _5140.alpha;\n    float3 _5599 = _5140.normal;\n    float _5600 = _5140.metallic;\n    float _5601 = _5140.roughness;\n    float _5602 = _5140.occlusion;\n    float3 _5603 = _5140.emission;\n    float _5604 = _5140.clearcoat;\n    float _5605 = _5140.clearcoat_roughness;\n    float3 _5606 = _5140.sheen_color;\n    float _5607 = _5140.sheen_roughness;\n    float _5608 = _5140.anisotropy;\n    float _5609 = _5140.anisotropy_rotation;\n    float _5610 = _5140.specular;\n    float _5611 = _5140.ior;\n    float3 _5612 = _5140.specular_color;\n    float _5613 = _5140.transmission;\n    float _5614 = _5140.thickness;\n    float3 _5615 = _5140.attenuation_color;\n    float _5616 = _5140.attenuation_distance;\n    SurfaceInput _5579 = { fa_world_pos, _5558, fa_world_tangent, fa_uv, fa_vertex_color, _5132, gl_FrontFacing };\n    SurfaceInput param_2 = _5579;\n    Surface param_3 = _5140;\n    surface(param_2, param_3);\n    _5597 = param_3.albedo;\n    _5598 = param_3.alpha;\n    _5599 = param_3.normal;\n    _5600 = param_3.metallic;\n    _5601 = param_3.roughness;\n    _5602 = param_3.occlusion;\n    _5603 = param_3.emission;\n    _5604 = param_3.clearcoat;\n    _5605 = param_3.clearcoat_roughness;\n    _5606 = param_3.sheen_color;\n    _5607 = param_3.sheen_roughness;\n    _5608 = param_3.anisotropy;\n    _5609 = param_3.anisotropy_rotation;\n    _5610 = param_3.specular;\n    _5611 = param_3.ior;\n    _5612 = param_3.specular_color;\n    _5613 = param_3.transmission;\n    _5614 = param_3.thickness;\n    _5615 = param_3.attenuation_color;\n    _5616 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5558;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5597 = param_6;\n    _5599 = param_7;\n    float3 result;\n    if (_420_fa_emissive.w > 0.5f)\n    {\n        result = _5597;\n    }\n    else\n    {\n        float3 _5179 = _5599;\n        float3 _5180 = normalize(_5179);\n        _5599 = _5180;\n        float3 param_8 = _5180;\n        SurfaceInput _5587 = { fa_world_pos, _5558, fa_world_tangent, fa_uv, fa_vertex_color, _5132, gl_FrontFacing };\n        SurfaceInput param_9 = _5587;\n        Surface _5698 = { _5597, _5598, _5599, _5600, _5601, _5602, _5603, _5604, _5605, _5606, _5607, _5608, _5609, _5610, _5611, _5612, _5613, _5614, _5615, _5616 };\n        Surface param_10 = _5698;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _5199 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5199; ln++)\n        {\n            int param_12 = ln;\n            int _5212 = fa_cl_light(param_12);\n            int param_13 = _5212;\n            if (fa_baked_keep(param_13) <= 0.0f)\n            {\n                continue;\n            }\n            int param_14 = _5212;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _5558;\n            LightSample _5228 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _5595 = { fa_world_pos, _5558, fa_world_tangent, fa_uv, fa_vertex_color, _5132, gl_FrontFacing };\n            SurfaceInput param_17 = _5595;\n            Surface _5719 = { _5597, _5598, _5599, _5600, _5601, _5602, _5603, _5604, _5605, _5606, _5607, _5608, _5609, _5610, _5611, _5612, _5613, _5614, _5615, _5616 };\n            Surface param_18 = _5719;\n            LightSample param_19 = _5228;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _5243 = result;\n    float3 _5244 = _5243 + _5603;\n    result = _5244;\n    float3 param_20 = _5244;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _5253 = _420_fa_fog.w > 0.0f;\n    bool _5260;\n    if (!_5253)\n    {\n        _5260 = _420_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5260 = _5253;\n    }\n    if (_5260)\n    {\n        float3 _5269 = fa_world_pos - _420_fa_camera_pos.xyz;\n        float _5275 = dot(_5269, _420_fa_fog_c.xyz);\n        bool _5279 = _420_fa_fog_c.w > 0.5f;\n        float _5280;\n        if (_5279)\n        {\n            _5280 = _5275;\n        }\n        else\n        {\n            _5280 = length(_5269);\n        }\n        float _5292 = _5280 - _420_fa_fog_b.x;\n        if (_5292 > 0.0f)\n        {\n            float _5301 = _420_fa_fog.w * _5292;\n            float tau = _5301 * _5301;\n            if (_420_fa_fog_b.y > 0.0f)\n            {\n                float _5317;\n                if (_5279)\n                {\n                    _5317 = fa_world_pos.y - (_420_fa_fog_c.y * _5275);\n                }\n                else\n                {\n                    _5317 = _420_fa_camera_pos.y;\n                }\n                float _5338 = lerp(_5317, fa_world_pos.y, clamp(_420_fa_fog_b.x / _5280, 0.0f, 1.0f));\n                float _5342 = fa_world_pos.y - _5338;\n                float _5347 = _5338 - _420_fa_fog_b.z;\n                float _5352 = fa_world_pos.y - _420_fa_fog_b.z;\n                bool _5355 = _5347 <= 0.0f;\n                bool _5356 = !_5355;\n                bool _5362;\n                if (_5356)\n                {\n                    _5362 = _420_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5362 = _5355;\n                }\n                float _5363;\n                if (_5362)\n                {\n                    _5363 = _420_fa_fog_b.y;\n                }\n                else\n                {\n                    _5363 = _420_fa_fog_b.y * exp(-min(_420_fa_fog_b.w * _5347, 80.0f));\n                }\n                bool _5390;\n                if (_5356)\n                {\n                    _5390 = _420_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5390 = _5355;\n                }\n                float _5391;\n                if (_5390)\n                {\n                    _5391 = _420_fa_fog_b.y * _5347;\n                }\n                else\n                {\n                    _5391 = (_420_fa_fog_b.y * (1.0f - exp(-min(_420_fa_fog_b.w * _5347, 80.0f)))) / _420_fa_fog_b.w;\n                }\n                bool _5416 = _5352 <= 0.0f;\n                bool _5423;\n                if (!_5416)\n                {\n                    _5423 = _420_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5423 = _5416;\n                }\n                float _5424;\n                if (_5423)\n                {\n                    _5424 = _420_fa_fog_b.y * _5352;\n                }\n                else\n                {\n                    _5424 = (_420_fa_fog_b.y * (1.0f - exp(-min(_420_fa_fog_b.w * _5352, 80.0f)))) / _420_fa_fog_b.w;\n                }\n                float _5451;\n                if (abs(_5342) < 0.001000000047497451305389404296875f)\n                {\n                    _5451 = _5363;\n                }\n                else\n                {\n                    _5451 = (_5424 - _5391) / _5342;\n                }\n                tau += (_5292 * max(_5451, 0.0f));\n            }\n            result = lerp(result, _420_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5598);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_420",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2072",
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
