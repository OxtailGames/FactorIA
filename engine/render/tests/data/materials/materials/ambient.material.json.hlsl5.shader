{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "4f7d190a643df7eea422f9bce37d2bb8920145f92f7e586baf62c54f579868ea",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _260 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _260;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_267, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _429_fa_camera_pos : packoffset(c0);\n    float4 _429_fa_ambient : packoffset(c1);\n    float4 _429_fa_base_color : packoffset(c2);\n    float4 _429_fa_emissive : packoffset(c3);\n    float4 _429_fa_model_emissive : packoffset(c4);\n    float4 _429_fa_pbr : packoffset(c5);\n    float4 _429_fa_maps : packoffset(c6);\n    float4 _429_fa_fog : packoffset(c7);\n    float4 _429_fa_fog_b : packoffset(c8);\n    float4 _429_fa_fog_c : packoffset(c9);\n    float4 _429_fa_counts : packoffset(c10);\n    float4 _429_fa_env_sky : packoffset(c11);\n    float4 _429_fa_env_horizon : packoffset(c12);\n    float4 _429_fa_time : packoffset(c13);\n    float4 _429_fa_cl_vpx : packoffset(c14);\n    float4 _429_fa_cl_vpy : packoffset(c15);\n    float4 _429_fa_cl_vpw : packoffset(c16);\n    float4 _429_fa_cl_fwd : packoffset(c17);\n    float4 _429_fa_cl_grid : packoffset(c18);\n    float4 _429_fa_cl_info : packoffset(c19);\n    float4 _429_fa_layers_a : packoffset(c20);\n    float4 _429_fa_layers_b : packoffset(c21);\n    float4 _429_fa_layers_c : packoffset(c22);\n    float4 _429_fa_layers_d : packoffset(c23);\n    float4 _429_fa_ct_a : packoffset(c24);\n    float4 _429_fa_ct_b : packoffset(c25);\n    float4 _429_fa_ct_vpx : packoffset(c26);\n    float4 _429_fa_ct_vpy : packoffset(c27);\n    float4 _429_fa_ct_vpw : packoffset(c28);\n    float4 _429_fa_ct_fwd : packoffset(c29);\n    float4 _429_fa_tr_a : packoffset(c30);\n    float4 _429_fa_tr_b : packoffset(c31);\n    float4 _429_fa_probe_sh[9] : packoffset(c32);\n    float4 _429_fa_atlas : packoffset(c41);\n    float4 _429_fa_rpa_tile : packoffset(c42);\n    float4 _429_fa_rpa_pos : packoffset(c43);\n    float4 _429_fa_rpa_bx : packoffset(c44);\n    float4 _429_fa_rpa_by : packoffset(c45);\n    float4 _429_fa_rpa_bz : packoffset(c46);\n    float4 _429_fa_rpb_tile : packoffset(c47);\n    float4 _429_fa_rpb_pos : packoffset(c48);\n    float4 _429_fa_rpb_bx : packoffset(c49);\n    float4 _429_fa_rpb_by : packoffset(c50);\n    float4 _429_fa_rpb_bz : packoffset(c51);\n    float4 _429_fa_gi : packoffset(c52);\n    float4 _429_fa_gi_px : packoffset(c53);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2081_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2081_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2081_fa_shadow_info[4] : packoffset(c20);\n    float4 _2081_fa_shadow_split : packoffset(c24);\n    float4 _2081_fa_shadow_cfg : packoffset(c25);\n    float4 _2081_fa_shadow_bias : packoffset(c26);\n    float4 _2081_fa_shadow_eye : packoffset(c27);\n    float4 _2081_fa_shadow_fwd : packoffset(c28);\n    float4 _2081_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float fa_rt_slope;\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1357 = _429_fa_cl_info.x < 0.0f;\n    bool _1364;\n    if (!_1357)\n    {\n        _1364 = _429_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1364 = _1357;\n    }\n    bool _1372;\n    if (!_1364)\n    {\n        _1372 = _429_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1372 = _1364;\n    }\n    bool _1379;\n    if (!_1372)\n    {\n        _1379 = _429_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1379 = _1372;\n    }\n    bool _1386;\n    if (!_1379)\n    {\n        _1386 = _429_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1386 = _1379;\n    }\n    if (_1386)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1396 = float4(world_pos, 1.0f);\n    float _1402 = dot(_429_fa_cl_vpw, _1396);\n    if (!(_1402 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1424 = float2(dot(_429_fa_cl_vpx, _1396), dot(_429_fa_cl_vpy, _1396)) / _1402.xx;\n    int _1428 = int(_429_fa_cl_grid.x);\n    int _1432 = int(_429_fa_cl_grid.y);\n    int param = (int(_429_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_429_fa_cl_fwd.xyz, world_pos) + _429_fa_cl_fwd.w, _429_fa_cl_grid.w) / _429_fa_cl_grid.w) * _429_fa_cl_grid.z)), 0, int(_429_fa_cl_info.y) - 1) * _1432) + clamp(int(floor(((_1424.y * 0.5f) + 0.5f) * _429_fa_cl_grid.y)), 0, _1432 - 1)) * _1428)) + clamp(int(floor(((_1424.x * 0.5f) + 0.5f) * _429_fa_cl_grid.x)), 0, _1428 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1508 = fa_cluster_texel(param);\n    return int2(int(_1508.x), int(_1508.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    float _4208 = dot(_429_fa_ct_fwd.xyz, world_pos) + _429_fa_ct_fwd.w;\n    float _4211 = fwidth(_4208);\n    bool _4214 = _429_fa_ct_b.y > 0.5f;\n    bool _4221;\n    if (!_4214)\n    {\n        _4221 = _429_fa_ct_b.w > 0.5f;\n    }\n    else\n    {\n        _4221 = _4214;\n    }\n    if (_4221)\n    {\n        fa_rt_slope = min(1.5f * _4211, 0.100000001490116119384765625f * _4208);\n    }\n    fa_cl_ndir = int(_429_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4237 = fa_cluster_lookup(param);\n    fa_cl_slot = _4237.x;\n    fa_cl_local = _4237.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4447 = fa_linear_to_srgb(param);\n        c = _4447;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4455 = fa_srgb_to_linear(param_1);\n            c = _4455;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _312;\n    if (i.front_facing)\n    {\n        _312 = i.world_normal;\n    }\n    else\n    {\n        _312 = -i.world_normal;\n    }\n    float3 _336 = normalize(i.world_tangent.xyz - (_312 * dot(_312, i.world_tangent.xyz)));\n    float3 _363 = normalize(((_336 * m.x) + ((cross(_312, _336) * i.world_tangent.w) * m.y)) + (_312 * m.z));\n    float3 _366;\n    if (i.front_facing)\n    {\n        _366 = _363;\n    }\n    else\n    {\n        _366 = -_363;\n    }\n    return _366;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _429_fa_env_horizon.w);\n    float param = _429_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4487 = fa_tex_fix(param_2, param_3);\n    float4 _6392 = base_t;\n    _6392.x = _4487.x;\n    _6392.y = _4487.y;\n    _6392.z = _4487.z;\n    base_t = _6392;\n    float4 _4501 = (_6392 * _429_fa_base_color) * i.vertex_color;\n    float3 _6208 = i.world_normal;\n    if (_429_fa_maps.z > 0.5f)\n    {\n        float param_4 = _429_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _429_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4535 = fa_tex_fix(param_6, param_7);\n        float3 _4538 = (_4535 * 2.0f) - 1.0f.xxx;\n        float2 _4543 = _4538.xy * _429_fa_maps.x;\n        float3 _6400 = _4538;\n        _6400.x = _4543.x;\n        _6400.y = _4543.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6400;\n        _6208 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _429_fa_env_horizon.w);\n    float param_10 = _429_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4573 = fa_tex_fix(param_12, param_13);\n    float4 _6403 = mrt;\n    _6403.x = _4573.x;\n    _6403.y = _4573.y;\n    _6403.z = _4573.z;\n    mrt = _6403;\n    float4 _4603 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _429_fa_env_horizon.w);\n    float param_14 = _429_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4603.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4614 = fa_tex_fix(param_16, param_17);\n    float param_18 = _429_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _429_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4646 = fa_tex_fix(param_20, param_21);\n    float _6213 = _429_fa_layers_a.x;\n    float _6214 = _429_fa_layers_a.y;\n    float _6217 = _429_fa_layers_a.z;\n    float _6216 = _429_fa_layers_b.w;\n    float _6219 = _429_fa_layers_c.x;\n    if (_429_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_429_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6213 *= _4614.y;\n            _6214 *= _4614.z;\n            _6216 *= _4603.w;\n        }\n        if (_429_fa_layers_c.z > 1.5f)\n        {\n            _6217 *= mrt.x;\n            _6219 *= mrt.w;\n        }\n    }\n    Surface _6246 = { _4501.xyz, _4501.w, _6208, clamp(_429_fa_pbr.x * _4573.z, 0.0f, 1.0f), clamp(_429_fa_pbr.y * _4573.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_429_fa_maps.y * (_4614.x - 1.0f)), _429_fa_emissive.xyz + (_429_fa_model_emissive.xyz * _4646), _6213, _6214, _429_fa_layers_b.xyz, _6216, _6217, _429_fa_layers_a.w, _6219, _429_fa_layers_c.y, _429_fa_layers_d.xyz, _429_fa_tr_a.x, _429_fa_tr_a.y, _429_fa_tr_b.xyz, _429_fa_tr_a.z };\n    return _6246;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1588 = rect.zw - rect.xy;\n    float2 _1592 = _1588 * atlas;\n    float2 _1596 = ddx * _1592;\n    float2 _1600 = ddy * _1592;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1588), clamp(0.5f * log2(max(max(dot(_1596, _1596), dot(_1600, _1600)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1633 = _429_fa_counts.y < 0.5f;\n    bool _1640;\n    if (!_1633)\n    {\n        _1640 = _429_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1640 = _1633;\n    }\n    if (_1640)\n    {\n        return;\n    }\n    float3 _1646 = ddx(world_pos);\n    float3 _1649 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1653 = fa_cluster_texel(param);\n    int _1657 = int(_1653.w);\n    if (_1657 < 1)\n    {\n        return;\n    }\n    int _1667 = int(_429_fa_counts.y + 0.5f);\n    int param_1 = _1667;\n    float4 _1671 = fa_light_texel(param_1);\n    float2 _1674 = _1671.yz;\n    int _1678 = int(_1671.w);\n    int param_2 = _1667 + 1;\n    float4 _1683 = fa_light_texel(param_2);\n    float _1684 = _1683.x;\n    int _1690 = int(_429_fa_counts.w + 0.5f) - 1;\n    int _1694 = int(_1653.z);\n    float3 _1959;\n    for (int k = 0; k < _1657; k++)\n    {\n        int _1707 = _1694 + k;\n        int param_3 = _1678 + (_1707 >> 2);\n        int _1724 = (_1667 + 2) + (int(fa_light_texel(param_3)[_1707 & 3]) * 7);\n        int param_4 = _1724 + 6;\n        float4 _1729 = fa_light_texel(param_4);\n        if (((int(_1729.w + 0.5f) >> _1690) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1724;\n        float4 _1744 = fa_light_texel(param_5);\n        int param_6 = _1724 + 1;\n        float4 _1749 = fa_light_texel(param_6);\n        int param_7 = _1724 + 2;\n        float4 _1754 = fa_light_texel(param_7);\n        float3 _1757 = _1744.xyz;\n        float _1762 = dot(_1757, world_pos) + _1744.w;\n        float3 _1764 = _1749.xyz;\n        float _1769 = dot(_1764, world_pos) + _1749.w;\n        float3 _1771 = _1754.xyz;\n        float _1776 = dot(_1771, world_pos) + _1754.w;\n        bool _1781 = abs(_1762) > 0.5f;\n        bool _1789;\n        if (!_1781)\n        {\n            _1789 = abs(_1769) > 0.5f;\n        }\n        else\n        {\n            _1789 = _1781;\n        }\n        bool _1797;\n        if (!_1789)\n        {\n            _1797 = abs(_1776) > 0.5f;\n        }\n        else\n        {\n            _1797 = _1789;\n        }\n        if (_1797)\n        {\n            continue;\n        }\n        float _1812 = clamp(dot(geo_normal, normalize(_1771)) * _1729.z, 0.0f, 1.0f);\n        if (_1812 <= 0.0f)\n        {\n            continue;\n        }\n        float _1832 = (clamp((0.5f - abs(_1776)) * 10.0f, 0.0f, 1.0f) * _1812) * _1729.x;\n        float2 _1840 = float2(_1762 + 0.5f, 0.5f - _1769);\n        float2 _1850 = float2(dot(_1757, _1646), dot(_1764, _1646));\n        float2 _1860 = float2(dot(_1757, _1649), dot(_1764, _1649));\n        int param_8 = _1724 + 5;\n        float4 _1865 = fa_light_texel(param_8);\n        int param_9 = _1724 + 3;\n        float4 _1870 = fa_light_texel(param_9);\n        int param_10 = _1724 + 4;\n        float4 _1875 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1865.xyz;\n        bool _1885 = _1870.z > _1870.x;\n        if (_1885)\n        {\n            float4 param_11 = _1870;\n            float2 param_12 = _1840;\n            float2 param_13 = _1674;\n            float2 param_14 = _1850;\n            float2 param_15 = _1860;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1684 > 0.5f) && (_1684 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1911 = fa_dc_to_linear(param_16);\n                float4 _6296 = tx;\n                _6296.x = _1911.x;\n                _6296.y = _1911.y;\n                _6296.z = _1911.z;\n                tx = _6296;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1832 * tex_a) * _1865.w, 0.0f, 1.0f).xxx);\n        if (_1875.z > _1875.x)\n        {\n            float4 param_17 = _1875;\n            float2 param_18 = _1840;\n            float2 param_19 = _1674;\n            float2 param_20 = _1850;\n            float2 param_21 = _1860;\n            float4 _1955 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1684 > 1.5f)\n            {\n                float3 param_22 = _1955.xyz;\n                float3 _1965 = fa_dc_to_srgb(param_22);\n                _1959 = _1965;\n            }\n            else\n            {\n                _1959 = _1955.xyz;\n            }\n            float3 _1974 = (_1959 * 2.0f) - 1.0f.xxx;\n            float2 _1979 = _1974.xy * _1729.y;\n            float3 _2001 = (normalize(_1757) * _1979.x) + (normalize(_1764) * _1979.y);\n            float3 _2004 = normalize(normal);\n            normal = normalize(lerp(_2004, normalize((_2004 * max(_1974.z, 0.0500000007450580596923828125f)) + (_2001 - (_2004 * dot(_2004, _2001)))), clamp(_1832 * (_1885 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3731_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3731_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_429_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3672 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3672;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3781 = (1.0f - _429_fa_rpa_tile.w) - _429_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3787 = _429_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3781 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3787)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _429_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3781;\n            }\n        }\n        else\n        {\n            amb = _429_fa_ambient.xyz * _3781;\n        }\n    }\n    bool _3838 = _429_fa_rpa_tile.w > 0.0f;\n    if (_3838)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _429_fa_rpa_tile.xy;\n            float param_4 = _429_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _429_fa_rpa_tile.w);\n        }\n    }\n    bool _3869 = _429_fa_rpb_tile.w > 0.0f;\n    if (_3869)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _429_fa_rpb_tile.xy;\n            float param_7 = _429_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _429_fa_rpb_tile.w);\n        }\n    }\n    if ((_3787 || _3838) || _3869)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3692 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3695 = _3692.x;\n    float _3697 = _3692.z;\n    float2 e = float2(_3695, _3697);\n    if (_3692.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3697)) * ((_3695 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3695)) * ((_3697 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _4760 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _4765 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _4770 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _4775 = fa_light_texel(param_3);\n    bool _4778 = _4775.z < 0.5f;\n    bool _4786;\n    if (!_4778)\n    {\n        _4786 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _4786 = _4778;\n    }\n    if (_4786)\n    {\n        return 0.0f.xxx;\n    }\n    float _4793 = max(_4760.w, 9.9999997473787516355514526367188e-05f);\n    float3 _4796 = _4765.xyz;\n    float3 _4800 = _4760.xyz;\n    float3 _4804 = (fa_world_pos - _4800) / _4793.xxx;\n    float3 _4813 = min(_4804 + 0.5f.xxx, (_4796 - 0.5f.xxx) - _4804);\n    float _4822 = min(_4813.x, min(_4813.y, _4813.z));\n    if (!(_4822 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4837 = _4796 - 1.0f.xxx;\n    float3 _4838 = clamp(_4804, 0.0f.xxx, _4837);\n    float3 _4846 = min(floor(_4838), max(_4796 - 2.0f.xxx, 0.0f.xxx));\n    float3 _4850 = _4838 - _4846;\n    float3 _4862 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _4793));\n    int _4867 = int(_4770.y + 0.5f);\n    float _4872 = 0.3257350027561187744140625f * n.y;\n    float _4876 = 0.3257350027561187744140625f * n.z;\n    float _4880 = 0.3257350027561187744140625f * n.x;\n    float _4887 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _4894 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _4903 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _4910 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _4923 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _4930 = 8 + int(_4775.w);\n    float _4957;\n    float _4970;\n    float _4984;\n    for (int k = 0; k < _4930; k++)\n    {\n        float _4943 = float(k & 1);\n        float _4947 = float((k >> 1) & 1);\n        float _4951 = float((k >> 2) & 1);\n        if (_4943 > 0.5f)\n        {\n            _4957 = _4850.x;\n        }\n        else\n        {\n            _4957 = 1.0f - _4850.x;\n        }\n        if (_4947 > 0.5f)\n        {\n            _4970 = _4850.y;\n        }\n        else\n        {\n            _4970 = 1.0f - _4850.y;\n        }\n        if (_4951 > 0.5f)\n        {\n            _4984 = _4850.z;\n        }\n        else\n        {\n            _4984 = 1.0f - _4850.z;\n        }\n        float _4994 = (_4957 * _4970) * _4984;\n        if (!(_4994 > 0.0f))\n        {\n            continue;\n        }\n        float3 _5007 = min(_4846 + float3(_4943, _4947, _4951), _4837);\n        int _5027 = int(((_4770.x + _5007.x) + (_4765.x * (_5007.y + (_4765.y * _5007.z)))) + 0.5f);\n        float2 _5042 = float2(float(_5027 % _4867) * 10.0f, 1024.0f + (float(_5027 / _4867) * 11.0f));\n        float2 param_4 = _5042 + float2(9.5f, 10.5f);\n        float4 _5050 = fa_gi_fetch(param_4);\n        bool _5053 = _5050.y < 0.5f;\n        bool _5062;\n        if (!_5053)\n        {\n            _5062 = _5050.x > _4775.y;\n        }\n        else\n        {\n            _5062 = _5053;\n        }\n        if (_5062)\n        {\n            continue;\n        }\n        float3 _5074 = _4862 - (_4800 + (_5007 * _4793));\n        float _5077 = length(_5074);\n        float3 _5083 = _5074 / max(_5077, 9.9999997473787516355514526367188e-05f).xxx;\n        float _5093 = max(9.9999997473787516355514526367188e-05f, (dot(-_5083, n) + 1.0f) * 0.5f);\n        float w = _4994 * (_5093 * _5093);\n        float3 param_5 = _5083;\n        float2 param_6 = (_5042 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _5113 = fa_gi_fetch(param_6);\n        float _5120 = _5077 / max(_4770.z, 9.9999997473787516355514526367188e-05f);\n        float _5123 = _5113.x;\n        if (_5120 > _5123)\n        {\n            float _5136 = max(_5113.y - (_5123 * _5123), 0.0f);\n            float _5141 = _5120 - _5123;\n            float _5150 = _5136 / max(_5136 + (_5141 * _5141), 9.9999999600419720025001879548654e-13f);\n            w *= ((_5150 * _5150) * _5150);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _5042 + float2(0.5f, 10.5f);\n        float2 param_8 = _5042 + float2(1.5f, 10.5f);\n        float2 param_9 = _5042 + float2(2.5f, 10.5f);\n        float2 param_10 = _5042 + float2(3.5f, 10.5f);\n        float2 param_11 = _5042 + float2(4.5f, 10.5f);\n        float2 param_12 = _5042 + float2(5.5f, 10.5f);\n        float2 param_13 = _5042 + float2(6.5f, 10.5f);\n        float2 param_14 = _5042 + float2(7.5f, 10.5f);\n        float2 param_15 = _5042 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _4872)) + (fa_gi_fetch(param_9).xyz * _4876)) + (fa_gi_fetch(param_10).xyz * _4880)) + (fa_gi_fetch(param_11).xyz * _4887)) + (fa_gi_fetch(param_12).xyz * _4894)) + (fa_gi_fetch(param_13).xyz * _4903)) + (fa_gi_fetch(param_14).xyz * _4910)) + (fa_gi_fetch(param_15).xyz * _4923)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_4822 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _5278;\n    if (_429_fa_gi.z > 0.5f)\n    {\n        _5278 = _4775.x;\n    }\n    else\n    {\n        _5278 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_4770.w * _5278);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _5302 = normalize(_429_fa_camera_pos.xyz - fa_world_pos);\n    int _5307 = int(_429_fa_gi.x + 0.5f);\n    int _5312 = int(_429_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _5312) && (k < 8); k++)\n    {\n        int param = _5307 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _5302;\n        float3 _5337 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5342 = param_3 * left;\n        acc += (_5337 * _5342);\n        left -= _5342;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_429_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _5371 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5371;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_429_fa_gi_px.x > 0.5f)\n    {\n        float4 _5413 = float4(fa_world_pos, 1.0f);\n        float2 _5432 = float2(dot(_429_fa_ct_vpx, _5413), dot(_429_fa_ct_vpy, _5413)) / max(dot(_429_fa_ct_vpw, _5413), 9.9999997473787516355514526367188e-05f).xx;\n        float _5441;\n        if (_429_fa_ct_a.y > 0.5f)\n        {\n            _5441 = (_5432.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5441 = 0.5f - (_5432.y * 0.5f);\n        }\n        return fa_lightmap.Load(int3(clamp(int2(float2((_5432.x * 0.5f) + 0.5f, _5441) * _429_fa_ct_a.zw), int2(0, 0), int2(_429_fa_ct_a.zw) - int2(1, 1)), 0)).xyz;\n    }\n    if (_429_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _429_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_429_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return float3(0.0f, ambientColor.y, 0.0f);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_429_fa_cl_info.x) + int(_429_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_429_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4178;\n    if (fa_lm.z > 0.5f)\n    {\n        _4178 = 0.0f;\n    }\n    else\n    {\n        _4178 = 1.0f - clamp(_429_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4189 = _4178 < 1.0f;\n    bool _4195;\n    if (_4189)\n    {\n        int param = li;\n        _4195 = fa_light_baked(param);\n    }\n    else\n    {\n        _4195 = _4189;\n    }\n    return _4195 ? _4178 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _607 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _620 = (c - (ru * hx)) - p;\n        float3 _626 = ru * (2.0f * hx);\n        float _632 = max(dot(_626, _626), 9.9999999392252902907785028219223e-09f);\n        float _636 = dot(_620, _626);\n        float t = clamp((-_636) / _632, 0.0f, 1.0f);\n        if (_607)\n        {\n            float _651 = dot(r, _626);\n            float _657 = _632 - (_651 * _651);\n            if (abs(_657) > (9.9999997473787516355514526367188e-06f * _632))\n            {\n                t = clamp(((dot(r, _620) * _651) - _636) / _657, 0.0f, 1.0f);\n            }\n        }\n        return (p + _620) + (_626 * t);\n    }\n    float3 q = p;\n    float _689 = dot(r, axis);\n    bool _697;\n    if (_607)\n    {\n        _697 = abs(_689) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _697 = _607;\n    }\n    if (_697)\n    {\n        float _707 = dot(c - p, axis) / _689;\n        if (_707 > 0.0f)\n        {\n            q = p + (r * _707);\n        }\n    }\n    float3 _720 = q - c;\n    float2 xy = float2(dot(_720, ru), dot(_720, uu));\n    if (shape > 0.5f)\n    {\n        float _735 = length(xy);\n        if (_735 > hx)\n        {\n            xy *= (hx / _735);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _488_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _488_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _527 = dot(d, right);\n    float _531 = dot(d, up);\n    float _542;\n    if (((_527 * _527) + (_531 * _531)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _542 = atan2(_531, _527) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _542 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_542 - floor(_542)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _378 = abs(d);\n    float _380 = _378.x;\n    float _382 = _378.y;\n    bool _383 = _380 >= _382;\n    bool _391;\n    if (_383)\n    {\n        _391 = _380 >= _378.z;\n    }\n    else\n    {\n        _391 = _383;\n    }\n    int _392;\n    if (_391)\n    {\n        _392 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _406;\n        if (_382 >= _378.z)\n        {\n            _406 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _406 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _392 = _406;\n    }\n    return _392;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _773 = fa_light_base(param);\n    bool _777 = _429_fa_ambient.w > 4.5f;\n    int param_1 = _773;\n    float4 _781 = fa_light_texel(param_1);\n    int param_2 = _773 + 1;\n    float4 _786 = fa_light_texel(param_2);\n    float _789 = _786.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _801 = _777 && (_789 > 2.5f);\n    fa_light_is_area = _801;\n    bool _803 = _789 < 0.5f;\n    float3 l;\n    if (_803)\n    {\n        l = normalize(_781.xyz);\n        if (_777)\n        {\n            int param_3 = _773 + 6;\n            float4 _817 = fa_light_texel(param_3);\n            if (_817.z > 0.5f)\n            {\n                int param_4 = _773 + 4;\n                float4 _827 = fa_light_texel(param_4);\n                int param_5 = _773 + 5;\n                float4 _832 = fa_light_texel(param_5);\n                float2 param_6 = _817.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _827.xyz) * _827.w, (-dot(world_pos, _832.xyz)) * _832.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _862 = _781.xyz;\n        float3 _864 = _862 - world_pos;\n        float3 to_light = _864;\n        float _867 = length(_864);\n        float reach = _867;\n        bool front = true;\n        if (_801)\n        {\n            int param_8 = _773 + 7;\n            reach = max(_867 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _773 + 4;\n            float4 _891 = fa_light_texel(param_9);\n            int param_10 = _773 + 5;\n            float4 _896 = fa_light_texel(param_10);\n            int param_11 = _773 + 6;\n            float4 _901 = fa_light_texel(param_11);\n            float _902 = _901.w;\n            int param_12 = _773 + 2;\n            float3 _909 = normalize(fa_light_texel(param_12).xyz);\n            bool _911 = _902 > 1.5f;\n            bool _919;\n            if (!_911)\n            {\n                _919 = dot(_909, to_light) < 0.0f;\n            }\n            else\n            {\n                _919 = _911;\n            }\n            front = _919;\n            float3 r = 0.0f.xxx;\n            float3 _928 = _429_fa_camera_pos.xyz - world_pos;\n            bool _932 = dot(n, n) > 0.5f;\n            bool _940;\n            if (_932)\n            {\n                _940 = dot(_928, _928) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _940 = _932;\n            }\n            if (_940)\n            {\n                r = reflect(-normalize(_928), normalize(n));\n            }\n            float3 param_13 = _862;\n            float3 param_14 = _909;\n            float3 param_15 = _891.xyz;\n            float3 param_16 = _896.xyz;\n            float param_17 = _891.w;\n            float param_18 = _896.w;\n            float param_19 = _902;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _976 = length(to_light);\n        dist = _976;\n        l = to_light / max(_976, 9.9999997473787516355514526367188e-05f).xxx;\n        float _990 = reach / max(_781.w, 0.001000000047497451305389404296875f);\n        float _996 = clamp(1.0f - (_990 * _990), 0.0f, 1.0f);\n        float _998;\n        if (front)\n        {\n            _998 = _996 * _996;\n        }\n        else\n        {\n            _998 = 0.0f;\n        }\n        atten = _998;\n        bool _1009 = _789 < 2.5f;\n        if ((_789 > 1.5f) && _1009)\n        {\n            int param_22 = _773 + 2;\n            float4 _1017 = fa_light_texel(param_22);\n            float _1027 = _1017.w;\n            int param_23 = _773 + 3;\n            float4 _1032 = fa_light_texel(param_23);\n            float _1033 = _1032.x;\n            float cos_inner = _1033;\n            if (_1033 > 1.5f)\n            {\n                cos_inner = lerp(_1027, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1027, cos_inner, dot(-l, normalize(_1017.xyz)));\n        }\n        if (_777 && (_789 < 1.5f))\n        {\n            int param_24 = _773 + 6;\n            float4 _1057 = fa_light_texel(param_24);\n            if (_1057.z > 0.5f)\n            {\n                float3 _1065 = -to_light;\n                int param_25 = _773 + 4;\n                int param_26 = _773 + 5;\n                float3 _1079 = fa_light_texel(param_25).xyz;\n                float3 _1083 = fa_light_texel(param_26).xyz;\n                float3 _1092 = float3(dot(_1065, _1079), dot(_1065, _1083), dot(_1065, cross(_1079, _1083)));\n                float3 param_27 = _1092;\n                int _1096 = fa_cube_face(param_27);\n                int param_28 = _1096;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1123 = float2(dot(_1092, cross(param_29, param_30)), dot(_1092, param_30)) / max(dot(_1092, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1127 = _1096 / 3;\n                float2 param_31 = _1057.xy + (float2(float(_1096 - (_1127 * 3)), float(_1127)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1123.x), 0.5f - (0.5f * _1123.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _773 + 7;\n            float4 _1157 = fa_light_texel(param_33);\n            if (_1157.z > 0.5f)\n            {\n                int param_34 = _773 + 2;\n                int param_35 = _773 + 4;\n                int param_36 = _773 + 5;\n                float2 param_37 = _1157.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_777 && _1009)\n            {\n                int param_42 = _773 + 6;\n                float4 _1204 = fa_light_texel(param_42);\n                int param_43 = _773 + 7;\n                float4 _1209 = fa_light_texel(param_43);\n                bool _1212 = _1204.z > 0.5f;\n                bool _1219;\n                if (!_1212)\n                {\n                    _1219 = _1209.z > 0.5f;\n                }\n                else\n                {\n                    _1219 = _1212;\n                }\n                if (_1219)\n                {\n                    int param_44 = _773 + 2;\n                    float4 _1226 = fa_light_texel(param_44);\n                    float3 _1230 = normalize(_1226.xyz);\n                    int param_45 = _773 + 4;\n                    float4 _1235 = fa_light_texel(param_45);\n                    int param_46 = _773 + 5;\n                    float4 _1240 = fa_light_texel(param_46);\n                    if (_1212)\n                    {\n                        float3 _1248 = -to_light;\n                        float _1255 = _1226.w;\n                        float _1271 = 0.5f / max(dot(_1248, _1230) * (sqrt(max(1.0f - (_1255 * _1255), 0.0f)) / max(_1255, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1204.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1248, _1235.xyz) * _1271), 0.5f - (dot(_1248, _1240.xyz) * _1271));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1209.z > 0.5f)\n                    {\n                        float2 param_49 = _1209.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1230;\n                        float3 param_52 = _1235.xyz;\n                        float3 param_53 = _1240.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6162 = _786.xyz * atten;\n    if (_777)\n    {\n        _6162 *= fa_light_tint;\n    }\n    int _1339;\n    if (_803)\n    {\n        _1339 = 0;\n    }\n    else\n    {\n        _1339 = ((_789 > 1.5f) && (_789 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _6173 = { l, _6162, atten, 1.0f, dist, _1339 };\n    return _6173;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2128 = fa_shadow_depth(param, param_1);\n    float _2132;\n    if (conv.x < 0.5f)\n    {\n        _2132 = _2128;\n    }\n    else\n    {\n        _2132 = (conv.y * conv.z) / (conv.z - (_2128 * (conv.z - conv.y)));\n    }\n    return _2132;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2178 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2184 = float2(cos(_2178), sin(_2178));\n    float2 dir = _2184;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2193;\n        if (k < 0.0f)\n        {\n            _2193 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2193 = k;\n        }\n        float _2212 = clamp((_2193 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2231 = sqrt((float(i) + 0.5f) * 0.0625f) * _2212;\n            float2 param_3 = uv + (dir * (_2081_fa_shadow_bias.zw * _2231));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2245 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2245 < (zr - (_2231 * plane)))\n            {\n                sum += _2245;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2273 = sum / cnt;\n        float _2283;\n        if (k < 0.0f)\n        {\n            _2283 = (-k) / max(_2273, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2283 = k;\n        }\n        radius = clamp(((max(zr - _2273, 0.0f) * unit) * _2283) / texel_m, 1.5f, 16.0f);\n        dir = _2184;\n    }\n    float lit = 0.0f;\n    int _2309 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2309; i_1++)\n    {\n        float _2328 = sqrt((float(i_1) + 0.5f) / float(_2309)) * radius;\n        float2 param_7 = uv + (dir * (_2081_fa_shadow_bias.zw * _2328));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2328 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2309);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2533 = _429_fa_pbr.z < 0.5f;\n    bool _2540;\n    if (!_2533)\n    {\n        _2540 = _2081_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2540 = _2533;\n    }\n    if (_2540)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2081_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2553 = fa_light_texel(param);\n    float _2554 = _2553.x;\n    if (_2554 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2563 = int(_2554 + 0.5f);\n    int param_1 = _2563;\n    float4 _2567 = fa_light_texel(param_1);\n    int param_2 = _2563 + 1;\n    float4 _2572 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2575 = _2567.y;\n    if (_2575 > 0.0f)\n    {\n        float _2592 = 1.0f - smoothstep(0.75f * _2575, _2575, length(world - _2081_fa_shadow_eye.xyz));\n        fade = _2592;\n        if (_2592 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2567.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2616 = (_2563 + 2) + (face * 6);\n    int param_4 = _2616;\n    int param_5 = _2616 + 1;\n    int param_6 = _2616 + 3;\n    float4 _2630 = fa_light_texel(param_6);\n    int param_7 = _2616 + 4;\n    float4 _2635 = fa_light_texel(param_7);\n    int param_8 = _2616 + 5;\n    float4 _2640 = fa_light_texel(param_8);\n    float _2652 = _2640.x * max(dot(_2630, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2657 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2680 = clamp(dot(n, _2630.xyz), -1.0f, 1.0f);\n    float _2699 = min(sqrt(1.0f - (_2680 * _2680)) / max(abs(dot(n, world - lpos)) / max(dot(_2630, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2702 = _2572.y;\n    float _2704;\n    if (_2702 > 0.0f)\n    {\n        _2704 = _2702;\n    }\n    else\n    {\n        _2704 = 1.5f * _2652;\n    }\n    float4 _2724 = float4(world + (n * (_2704 * sqrt(1.0f - (_2657 * _2657)))), 1.0f);\n    float _2728 = dot(_2630, _2724);\n    float _2731 = _2640.y;\n    if (_2728 < _2731)\n    {\n        return 1.0f;\n    }\n    float2 _2746 = float2(dot(fa_light_texel(param_4), _2724), dot(fa_light_texel(param_5), _2724)) / _2728.xx;\n    float _2748 = _2746.x;\n    bool _2751 = _2748 < _2635.x;\n    bool _2760;\n    if (!_2751)\n    {\n        _2760 = _2748 > _2635.z;\n    }\n    else\n    {\n        _2760 = _2751;\n    }\n    bool _2769;\n    if (!_2760)\n    {\n        _2769 = _2746.y < _2635.y;\n    }\n    else\n    {\n        _2769 = _2760;\n    }\n    bool _2778;\n    if (!_2769)\n    {\n        _2778 = _2746.y > _2635.w;\n    }\n    else\n    {\n        _2778 = _2769;\n    }\n    if (_2778)\n    {\n        return 1.0f;\n    }\n    float _2784 = _2572.x;\n    float _2786;\n    if (_2784 > 0.0f)\n    {\n        _2786 = _2784;\n    }\n    else\n    {\n        _2786 = 1.5f * _2652;\n    }\n    float2 param_9 = _2746;\n    float4 param_10 = _2635;\n    float param_11 = _2728 - (_2786 * (1.0f + (0.5f * _2699)));\n    float param_12 = _2652;\n    float param_13 = 1.0f;\n    float param_14 = _2640.z * 0.25f;\n    float param_15 = (_2652 * min(_2699, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2731, _2640.z);\n    int param_17 = int(_2567.z + 0.5f);\n    float param_18 = _2567.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _3293 = _429_fa_ct_b.w > 0.5f;\n    bool _3299;\n    if (_3293)\n    {\n        _3299 = _429_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3299 = _3293;\n    }\n    bool _3305;\n    if (_3299)\n    {\n        _3305 = _2081_fa_shadow_lcfg.x > 0.5f;\n    }\n    else\n    {\n        _3305 = _3299;\n    }\n    if (_3305)\n    {\n        int param = (int(_2081_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n        float4 _3317 = fa_light_texel(param);\n        float _3318 = _3317.z;\n        if (_3318 > 0.5f)\n        {\n            float _3331 = dot(_429_fa_ct_fwd.xyz, world) + _429_fa_ct_fwd.w;\n            float _3337 = ((0.00200000009499490261077880859375f * _3331) + 0.00999999977648258209228515625f) + fa_rt_slope;\n            float4 _3343 = float4(world, 1.0f);\n            float _3348 = dot(_429_fa_ct_vpw, _3343);\n            if (_3348 > 9.9999997473787516355514526367188e-05f)\n            {\n                float2 _3365 = float2(dot(_429_fa_ct_vpx, _3343), dot(_429_fa_ct_vpy, _3343)) / _3348.xx;\n                float _3370 = (_3365.x * 0.5f) + 0.5f;\n                float _3374;\n                if (_429_fa_ct_a.y > 0.5f)\n                {\n                    _3374 = (_3365.y * 0.5f) + 0.5f;\n                }\n                else\n                {\n                    _3374 = 0.5f - (_3365.y * 0.5f);\n                }\n                bool _3390 = _3370 >= 0.0f;\n                bool _3396;\n                if (_3390)\n                {\n                    _3396 = _3370 < 1.0f;\n                }\n                else\n                {\n                    _3396 = _3390;\n                }\n                bool _3402;\n                if (_3396)\n                {\n                    _3402 = _3374 >= 0.0f;\n                }\n                else\n                {\n                    _3402 = _3396;\n                }\n                bool _3408;\n                if (_3402)\n                {\n                    _3408 = _3374 < 1.0f;\n                }\n                else\n                {\n                    _3408 = _3402;\n                }\n                if (_3408)\n                {\n                    int2 _3425 = int2(_429_fa_ct_a.zw) - int2(1, 1);\n                    int2 _3426 = clamp(int2(float2(_3370, _3374) * _429_fa_ct_a.zw), int2(0, 0), _3425);\n                    float _3430;\n                    if (_3318 < 1.5f)\n                    {\n                        _3430 = 1.0f;\n                    }\n                    else\n                    {\n                        _3430 = (_3318 < 2.5f) ? 256.0f : 65536.0f;\n                    }\n                    float best = 2.0f;\n                    int _3452;\n                    int _3458;\n                    for (int k = 0; k < 9; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3452 = 4;\n                        }\n                        else\n                        {\n                            if (k <= 4)\n                            {\n                                _3458 = k - 1;\n                            }\n                            else\n                            {\n                                _3458 = k;\n                            }\n                            _3452 = _3458;\n                        }\n                        float4 _3487 = fa_screen_tex.Load(int3(clamp(_3426 + int2((_3452 % 3) - 1, (_3452 / 3) - 1), int2(0, 0), _3425), 0));\n                        bool _3490 = _3487.w > 0.5f;\n                        bool _3500;\n                        if (_3490)\n                        {\n                            _3500 = abs(_3331 - _3487.x) <= _3337;\n                        }\n                        else\n                        {\n                            _3500 = _3490;\n                        }\n                        if (_3500)\n                        {\n                            best = min(best, mod(floor(_3487.z / _3430), 256.0f) * 0.0039215688593685626983642578125f);\n                            if (k == 0)\n                            {\n                                break;\n                            }\n                        }\n                    }\n                    if (best <= 1.0f)\n                    {\n                        float _3527;\n                        if (_429_fa_ct_b.z > 0.5f)\n                        {\n                            int param_1 = li;\n                            float3 param_2 = lpos;\n                            float3 param_3 = world;\n                            float3 param_4 = n;\n                            float3 param_5 = l;\n                            _3527 = min(best, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                        }\n                        else\n                        {\n                            _3527 = best;\n                        }\n                        return _3527;\n                    }\n                }\n            }\n            float _3550;\n            if (_429_fa_ct_b.z > 0.5f)\n            {\n                int param_6 = li;\n                float3 param_7 = lpos;\n                float3 param_8 = world;\n                float3 param_9 = n;\n                float3 param_10 = l;\n                _3550 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3550 = 1.0f;\n            }\n            return _3550;\n        }\n    }\n    int param_11 = li;\n    float3 param_12 = lpos;\n    float3 param_13 = world;\n    float3 param_14 = n;\n    float3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2071;\n    if (i == 0)\n    {\n        _2071 = _2081_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2087;\n        if (i == 1)\n        {\n            _2087 = _2081_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2095;\n            if (i == 2)\n            {\n                _2095 = _2081_fa_shadow_split.z;\n            }\n            else\n            {\n                _2095 = _2081_fa_shadow_split.w;\n            }\n            _2087 = _2095;\n        }\n        _2071 = _2087;\n    }\n    return _2071;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2374 = max(_2081_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2379 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2385 = sqrt(1.0f - (_2379 * _2379));\n    float _2393 = min(_2385 / max(_2379, 0.20000000298023223876953125f), 4.0f);\n    float _2398;\n    if (_2081_fa_shadow_bias.y > 0.0f)\n    {\n        _2398 = _2081_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2398 = 1.5f * _2081_fa_shadow_info[ci].x;\n    }\n    float4 _2423 = mul(float4(world + (n * (_2398 * _2385)), 1.0f), _2081_fa_shadow_mat[ci]);\n    float _2430 = _2423.x;\n    bool _2433 = _2430 < _2081_fa_shadow_rect[ci].x;\n    bool _2442;\n    if (!_2433)\n    {\n        _2442 = _2430 > _2081_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2442 = _2433;\n    }\n    bool _2451;\n    if (!_2442)\n    {\n        _2451 = _2423.y < _2081_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2451 = _2442;\n    }\n    bool _2460;\n    if (!_2451)\n    {\n        _2460 = _2423.y > _2081_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2460 = _2451;\n    }\n    bool _2467;\n    if (!_2460)\n    {\n        _2467 = _2423.z > 1.0f;\n    }\n    else\n    {\n        _2467 = _2460;\n    }\n    if (_2467)\n    {\n        return -1.0f;\n    }\n    float _2475;\n    if (_2081_fa_shadow_bias.x > 0.0f)\n    {\n        _2475 = _2081_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2475 = 1.5f * _2081_fa_shadow_info[ci].x;\n    }\n    float2 param = _2423.xy;\n    float4 param_1 = _2081_fa_shadow_rect[ci];\n    float param_2 = _2423.z - ((_2475 * (1.0f + (0.5f * _2393))) / _2374);\n    float param_3 = _2081_fa_shadow_info[ci].x;\n    float param_4 = _2374;\n    float param_5 = _2374 * 0.25f;\n    float param_6 = ((_2081_fa_shadow_info[ci].x * min(_2393, 3.0f)) * 0.5f) / _2374;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2081_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2081_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_429_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2853 = int(_2081_fa_shadow_cfg.x + 0.5f);\n    if (_2853 < 1)\n    {\n        return 1.0f;\n    }\n    float _2868 = dot(world - _2081_fa_shadow_eye.xyz, _2081_fa_shadow_fwd.xyz);\n    int param = _2853 - 1;\n    if (_2868 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2880 = _2853 > 1;\n    bool _2887;\n    if (_2880)\n    {\n        _2887 = _2868 > _2081_fa_shadow_split.x;\n    }\n    else\n    {\n        _2887 = _2880;\n    }\n    if (_2887)\n    {\n        ci = 1;\n    }\n    bool _2891 = _2853 > 2;\n    bool _2898;\n    if (_2891)\n    {\n        _2898 = _2868 > _2081_fa_shadow_split.y;\n    }\n    else\n    {\n        _2898 = _2891;\n    }\n    if (_2898)\n    {\n        ci = 2;\n    }\n    bool _2902 = _2853 > 3;\n    bool _2909;\n    if (_2902)\n    {\n        _2909 = _2868 > _2081_fa_shadow_split.z;\n    }\n    else\n    {\n        _2909 = _2902;\n    }\n    if (_2909)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _2920 = min(_2853, 4);\n    float _2961;\n    for (int c = ci; c < _2920; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2940 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _2940;\n            break;\n        }\n        if (_2940 < 0.0f)\n        {\n            continue;\n        }\n        s = _2940;\n        ci = c;\n        if (_2081_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2961 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2961 = _2081_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _2980 = _2081_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2961, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_2868 - (fa_shadow_split_at(param_7) - _2980)) / _2980, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3012;\n        if ((ci + 1) < _2853)\n        {\n            _3012 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3012 = 1.0f;\n        }\n        s = lerp(s, _3012, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    bool _3117 = _429_fa_ct_b.y > 0.5f;\n    bool _3123;\n    if (_3117)\n    {\n        _3123 = _429_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3123 = _3117;\n    }\n    if (_3123)\n    {\n        float _3137 = dot(_429_fa_ct_fwd.xyz, fa_world_pos) + _429_fa_ct_fwd.w;\n        float4 _3145 = float4(fa_world_pos, 1.0f);\n        float _3151 = dot(_429_fa_ct_vpw, _3145);\n        if (_3151 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _3170 = float2(dot(_429_fa_ct_vpx, _3145), dot(_429_fa_ct_vpy, _3145)) / _3151.xx;\n            float _3175 = (_3170.x * 0.5f) + 0.5f;\n            float _3179;\n            if (_429_fa_ct_a.y > 0.5f)\n            {\n                _3179 = (_3170.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _3179 = 0.5f - (_3170.y * 0.5f);\n            }\n            bool _3195 = _3175 >= 0.0f;\n            bool _3201;\n            if (_3195)\n            {\n                _3201 = _3175 < 1.0f;\n            }\n            else\n            {\n                _3201 = _3195;\n            }\n            bool _3207;\n            if (_3201)\n            {\n                _3207 = _3179 >= 0.0f;\n            }\n            else\n            {\n                _3207 = _3201;\n            }\n            bool _3213;\n            if (_3207)\n            {\n                _3213 = _3179 < 1.0f;\n            }\n            else\n            {\n                _3213 = _3207;\n            }\n            if (_3213)\n            {\n                float4 _3239 = fa_screen_tex.Load(int3(clamp(int2(float2(_3175, _3179) * _429_fa_ct_a.zw), int2(0, 0), int2(_429_fa_ct_a.zw) - int2(1, 1)), 0));\n                bool _3242 = _3239.w > 0.5f;\n                bool _3258;\n                if (_3242)\n                {\n                    _3258 = abs(_3137 - _3239.x) <= (((0.00200000009499490261077880859375f * _3137) + 0.00999999977648258209228515625f) + fa_rt_slope);\n                }\n                else\n                {\n                    _3258 = _3242;\n                }\n                if (_3258)\n                {\n                    float _3264;\n                    if (_429_fa_ct_b.z > 0.5f)\n                    {\n                        float3 param = fa_world_pos;\n                        float3 param_1 = n;\n                        float3 param_2 = l;\n                        _3264 = min(_3239.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3264 = _3239.y;\n                    }\n                    return _3264;\n                }\n            }\n        }\n    }\n    float3 param_3 = fa_world_pos;\n    float3 param_4 = n;\n    float3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3920 = _429_fa_ct_a.x < 0.5f;\n    bool _3927;\n    if (!_3920)\n    {\n        _3927 = _2081_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3927 = _3920;\n    }\n    if (_3927)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2081_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3940 = fa_light_texel(param);\n    float _3941 = _3940.y;\n    float len = _3941;\n    if (_3941 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3953 = length(world - _429_fa_camera_pos.xyz);\n    float _3962 = 1.0f - smoothstep(0.5f * _429_fa_ct_b.x, _429_fa_ct_b.x, _3953);\n    if (_3962 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3968 = len;\n    float _3971 = min(_3968, 0.89999997615814208984375f * dist);\n    len = _3971;\n    float _3977 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3953);\n    float _3982 = _3977 + (0.5f * _3971);\n    float3 _3988 = world + (gn * _3977);\n    float _3990 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4052;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4006 = (float(k) + _3990) * 0.083333335816860198974609375f;\n        float3 _4014 = _3988 + (l * (_4006 * len));\n        float4 _4020 = float4(_4014, 1.0f);\n        float _4025 = dot(_429_fa_ct_vpw, _4020);\n        if (_4025 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4043 = float2(dot(_429_fa_ct_vpx, _4020), dot(_429_fa_ct_vpy, _4020)) / _4025.xx;\n        float _4047 = _4043.x * 0.5f;\n        float _4048 = _4047 + 0.5f;\n        if (_429_fa_ct_a.y > 0.5f)\n        {\n            _4052 = (_4043.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4052 = 0.5f - (_4043.y * 0.5f);\n        }\n        bool _4068 = _4048 < 0.0f;\n        bool _4075;\n        if (!_4068)\n        {\n            _4075 = _4048 >= 1.0f;\n        }\n        else\n        {\n            _4075 = _4068;\n        }\n        bool _4082;\n        if (!_4075)\n        {\n            _4082 = _4052 < 0.0f;\n        }\n        else\n        {\n            _4082 = _4075;\n        }\n        bool _4089;\n        if (!_4082)\n        {\n            _4089 = _4052 >= 1.0f;\n        }\n        else\n        {\n            _4089 = _4082;\n        }\n        if (_4089)\n        {\n            break;\n        }\n        float4 _4113 = fa_screen_tex.Load(int3(clamp(int2(float2(_4048, _4052) * _429_fa_ct_a.zw), int2(0, 0), int2(_429_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_4113.w < 0.5f)\n        {\n            continue;\n        }\n        float _4131 = (dot(_429_fa_ct_fwd.xyz, _4014) + _429_fa_ct_fwd.w) - _4113.x;\n        if ((_4131 > _3977) && (_4131 < _3982))\n        {\n            occ = max(occ, (1.0f - (_4006 * _4006)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4048, 0.5f - _4047), min(_4052, 1.0f - _4052))));\n        }\n    }\n    return 1.0f - (occ * _3962);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4263 = fa_baked_keep(param);\n    if (_4263 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _6186 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6186;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4289 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6188 = _4289.color;\n    float _6189 = _4289.attenuation;\n    float _6190 = _4289.shadow;\n    bool _4292 = _4289.type == 0;\n    if (_4292 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4289.direction;\n        float _4303 = fa_shadow_factor(param_5, param_6);\n        _6190 = _4303;\n        _6188 *= _4303;\n    }\n    else\n    {\n        bool _4314 = _4289.type != 0;\n        bool _4320;\n        if (_4314)\n        {\n            _4320 = _6189 > 0.0f;\n        }\n        else\n        {\n            _4320 = _4314;\n        }\n        if (_4320)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4289.direction;\n            float _4339 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6190 = _4339;\n            _6188 *= _4339;\n        }\n    }\n    bool _4349 = _429_fa_ct_a.x > 0.5f;\n    bool _4355;\n    if (_4349)\n    {\n        _4355 = _6189 > 0.0f;\n    }\n    else\n    {\n        _4355 = _4349;\n    }\n    if (_4355)\n    {\n        float _4362;\n        if (_4292)\n        {\n            _4362 = 1000000000.0f;\n        }\n        else\n        {\n            _4362 = _4289._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4289.direction;\n        float param_18 = _4362;\n        float _4380 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6190 *= _4380;\n        _6188 *= _4380;\n    }\n    float _4393 = _6189;\n    float _4394 = _4393 * _4263;\n    _6189 = _4394;\n    float3 _4398 = _6188;\n    float3 _4399 = _4398 * _4263;\n    _6188 = _4399;\n    LightSample _6205 = { _4289.direction, _4399, _4394, _6190, _4289._distance, _4289.type };\n    return _6205;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2081_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3040 = int(_2081_fa_shadow_cfg.x + 0.5f);\n    float _3050 = dot(world - _2081_fa_shadow_eye.xyz, _2081_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3055 = _3040 > 0;\n    bool _3064;\n    if (_3055)\n    {\n        int param = _3040 - 1;\n        _3064 = _3050 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3064 = _3055;\n    }\n    if (_3064)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3070 = _3040 > 1;\n        bool _3077;\n        if (_3070)\n        {\n            _3077 = _3050 > _2081_fa_shadow_split.x;\n        }\n        else\n        {\n            _3077 = _3070;\n        }\n        if (_3077)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3083 = _3040 > 2;\n        bool _3090;\n        if (_3083)\n        {\n            _3090 = _3050 > _2081_fa_shadow_split.y;\n        }\n        else\n        {\n            _3090 = _3083;\n        }\n        if (_3090)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3096 = _3040 > 3;\n        bool _3103;\n        if (_3096)\n        {\n            _3103 = _3050 > _2081_fa_shadow_split.z;\n        }\n        else\n        {\n            _3103 = _3096;\n        }\n        if (_3103)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_rt_slope = 0.0f;\n    fa_inst_load();\n    float3 _5980 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5980 = -_5980;\n    }\n    float3 _5554 = normalize(_429_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5993 = { fa_world_pos, _5980, fa_world_tangent, fa_uv, fa_vertex_color, _5554, gl_FrontFacing };\n    SurfaceInput param_1 = _5993;\n    Surface _5562 = fa_standard_surface(param_1);\n    float3 _6019 = _5562.albedo;\n    float _6020 = _5562.alpha;\n    float3 _6021 = _5562.normal;\n    float _6022 = _5562.metallic;\n    float _6023 = _5562.roughness;\n    float _6024 = _5562.occlusion;\n    float3 _6025 = _5562.emission;\n    float _6026 = _5562.clearcoat;\n    float _6027 = _5562.clearcoat_roughness;\n    float3 _6028 = _5562.sheen_color;\n    float _6029 = _5562.sheen_roughness;\n    float _6030 = _5562.anisotropy;\n    float _6031 = _5562.anisotropy_rotation;\n    float _6032 = _5562.specular;\n    float _6033 = _5562.ior;\n    float3 _6034 = _5562.specular_color;\n    float _6035 = _5562.transmission;\n    float _6036 = _5562.thickness;\n    float3 _6037 = _5562.attenuation_color;\n    float _6038 = _5562.attenuation_distance;\n    SurfaceInput _6001 = { fa_world_pos, _5980, fa_world_tangent, fa_uv, fa_vertex_color, _5554, gl_FrontFacing };\n    SurfaceInput param_2 = _6001;\n    Surface param_3 = _5562;\n    surface(param_2, param_3);\n    _6019 = param_3.albedo;\n    _6020 = param_3.alpha;\n    _6021 = param_3.normal;\n    _6022 = param_3.metallic;\n    _6023 = param_3.roughness;\n    _6024 = param_3.occlusion;\n    _6025 = param_3.emission;\n    _6026 = param_3.clearcoat;\n    _6027 = param_3.clearcoat_roughness;\n    _6028 = param_3.sheen_color;\n    _6029 = param_3.sheen_roughness;\n    _6030 = param_3.anisotropy;\n    _6031 = param_3.anisotropy_rotation;\n    _6032 = param_3.specular;\n    _6033 = param_3.ior;\n    _6034 = param_3.specular_color;\n    _6035 = param_3.transmission;\n    _6036 = param_3.thickness;\n    _6037 = param_3.attenuation_color;\n    _6038 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5980;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6019 = param_6;\n    _6021 = param_7;\n    float3 result;\n    if (_429_fa_emissive.w > 0.5f)\n    {\n        result = _6019;\n    }\n    else\n    {\n        float3 _5601 = _6021;\n        float3 _5602 = normalize(_5601);\n        _6021 = _5602;\n        float3 param_8 = _5602;\n        SurfaceInput _6009 = { fa_world_pos, _5980, fa_world_tangent, fa_uv, fa_vertex_color, _5554, gl_FrontFacing };\n        SurfaceInput param_9 = _6009;\n        Surface _6120 = { _6019, _6020, _6021, _6022, _6023, _6024, _6025, _6026, _6027, _6028, _6029, _6030, _6031, _6032, _6033, _6034, _6035, _6036, _6037, _6038 };\n        Surface param_10 = _6120;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _5621 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5621; ln++)\n        {\n            int param_12 = ln;\n            int _5634 = fa_cl_light(param_12);\n            int param_13 = _5634;\n            if (fa_baked_keep(param_13) <= 0.0f)\n            {\n                continue;\n            }\n            int param_14 = _5634;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _5980;\n            LightSample _5650 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _6017 = { fa_world_pos, _5980, fa_world_tangent, fa_uv, fa_vertex_color, _5554, gl_FrontFacing };\n            SurfaceInput param_17 = _6017;\n            Surface _6141 = { _6019, _6020, _6021, _6022, _6023, _6024, _6025, _6026, _6027, _6028, _6029, _6030, _6031, _6032, _6033, _6034, _6035, _6036, _6037, _6038 };\n            Surface param_18 = _6141;\n            LightSample param_19 = _5650;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _5665 = result;\n    float3 _5666 = _5665 + _6025;\n    result = _5666;\n    float3 param_20 = _5666;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _5675 = _429_fa_fog.w > 0.0f;\n    bool _5682;\n    if (!_5675)\n    {\n        _5682 = _429_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5682 = _5675;\n    }\n    if (_5682)\n    {\n        float3 _5691 = fa_world_pos - _429_fa_camera_pos.xyz;\n        float _5697 = dot(_5691, _429_fa_fog_c.xyz);\n        bool _5701 = _429_fa_fog_c.w > 0.5f;\n        float _5702;\n        if (_5701)\n        {\n            _5702 = _5697;\n        }\n        else\n        {\n            _5702 = length(_5691);\n        }\n        float _5714 = _5702 - _429_fa_fog_b.x;\n        if (_5714 > 0.0f)\n        {\n            float _5723 = _429_fa_fog.w * _5714;\n            float tau = _5723 * _5723;\n            if (_429_fa_fog_b.y > 0.0f)\n            {\n                float _5739;\n                if (_5701)\n                {\n                    _5739 = fa_world_pos.y - (_429_fa_fog_c.y * _5697);\n                }\n                else\n                {\n                    _5739 = _429_fa_camera_pos.y;\n                }\n                float _5760 = lerp(_5739, fa_world_pos.y, clamp(_429_fa_fog_b.x / _5702, 0.0f, 1.0f));\n                float _5764 = fa_world_pos.y - _5760;\n                float _5769 = _5760 - _429_fa_fog_b.z;\n                float _5774 = fa_world_pos.y - _429_fa_fog_b.z;\n                bool _5777 = _5769 <= 0.0f;\n                bool _5778 = !_5777;\n                bool _5784;\n                if (_5778)\n                {\n                    _5784 = _429_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5784 = _5777;\n                }\n                float _5785;\n                if (_5784)\n                {\n                    _5785 = _429_fa_fog_b.y;\n                }\n                else\n                {\n                    _5785 = _429_fa_fog_b.y * exp(-min(_429_fa_fog_b.w * _5769, 80.0f));\n                }\n                bool _5812;\n                if (_5778)\n                {\n                    _5812 = _429_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5812 = _5777;\n                }\n                float _5813;\n                if (_5812)\n                {\n                    _5813 = _429_fa_fog_b.y * _5769;\n                }\n                else\n                {\n                    _5813 = (_429_fa_fog_b.y * (1.0f - exp(-min(_429_fa_fog_b.w * _5769, 80.0f)))) / _429_fa_fog_b.w;\n                }\n                bool _5838 = _5774 <= 0.0f;\n                bool _5845;\n                if (!_5838)\n                {\n                    _5845 = _429_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5845 = _5838;\n                }\n                float _5846;\n                if (_5845)\n                {\n                    _5846 = _429_fa_fog_b.y * _5774;\n                }\n                else\n                {\n                    _5846 = (_429_fa_fog_b.y * (1.0f - exp(-min(_429_fa_fog_b.w * _5774, 80.0f)))) / _429_fa_fog_b.w;\n                }\n                float _5873;\n                if (abs(_5764) < 0.001000000047497451305389404296875f)\n                {\n                    _5873 = _5785;\n                }\n                else\n                {\n                    _5873 = (_5846 - _5813) / _5764;\n                }\n                tau += (_5714 * max(_5873, 0.0f));\n            }\n            result = lerp(result, _429_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _6020);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_429",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2081",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _429_fa_camera_pos : packoffset(c0);\n    float4 _429_fa_ambient : packoffset(c1);\n    float4 _429_fa_base_color : packoffset(c2);\n    float4 _429_fa_emissive : packoffset(c3);\n    float4 _429_fa_model_emissive : packoffset(c4);\n    float4 _429_fa_pbr : packoffset(c5);\n    float4 _429_fa_maps : packoffset(c6);\n    float4 _429_fa_fog : packoffset(c7);\n    float4 _429_fa_fog_b : packoffset(c8);\n    float4 _429_fa_fog_c : packoffset(c9);\n    float4 _429_fa_counts : packoffset(c10);\n    float4 _429_fa_env_sky : packoffset(c11);\n    float4 _429_fa_env_horizon : packoffset(c12);\n    float4 _429_fa_time : packoffset(c13);\n    float4 _429_fa_cl_vpx : packoffset(c14);\n    float4 _429_fa_cl_vpy : packoffset(c15);\n    float4 _429_fa_cl_vpw : packoffset(c16);\n    float4 _429_fa_cl_fwd : packoffset(c17);\n    float4 _429_fa_cl_grid : packoffset(c18);\n    float4 _429_fa_cl_info : packoffset(c19);\n    float4 _429_fa_layers_a : packoffset(c20);\n    float4 _429_fa_layers_b : packoffset(c21);\n    float4 _429_fa_layers_c : packoffset(c22);\n    float4 _429_fa_layers_d : packoffset(c23);\n    float4 _429_fa_ct_a : packoffset(c24);\n    float4 _429_fa_ct_b : packoffset(c25);\n    float4 _429_fa_ct_vpx : packoffset(c26);\n    float4 _429_fa_ct_vpy : packoffset(c27);\n    float4 _429_fa_ct_vpw : packoffset(c28);\n    float4 _429_fa_ct_fwd : packoffset(c29);\n    float4 _429_fa_tr_a : packoffset(c30);\n    float4 _429_fa_tr_b : packoffset(c31);\n    float4 _429_fa_probe_sh[9] : packoffset(c32);\n    float4 _429_fa_atlas : packoffset(c41);\n    float4 _429_fa_rpa_tile : packoffset(c42);\n    float4 _429_fa_rpa_pos : packoffset(c43);\n    float4 _429_fa_rpa_bx : packoffset(c44);\n    float4 _429_fa_rpa_by : packoffset(c45);\n    float4 _429_fa_rpa_bz : packoffset(c46);\n    float4 _429_fa_rpb_tile : packoffset(c47);\n    float4 _429_fa_rpb_pos : packoffset(c48);\n    float4 _429_fa_rpb_bx : packoffset(c49);\n    float4 _429_fa_rpb_by : packoffset(c50);\n    float4 _429_fa_rpb_bz : packoffset(c51);\n    float4 _429_fa_gi : packoffset(c52);\n    float4 _429_fa_gi_px : packoffset(c53);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2081_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2081_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2081_fa_shadow_info[4] : packoffset(c20);\n    float4 _2081_fa_shadow_split : packoffset(c24);\n    float4 _2081_fa_shadow_cfg : packoffset(c25);\n    float4 _2081_fa_shadow_bias : packoffset(c26);\n    float4 _2081_fa_shadow_eye : packoffset(c27);\n    float4 _2081_fa_shadow_fwd : packoffset(c28);\n    float4 _2081_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float fa_rt_slope;\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1357 = _429_fa_cl_info.x < 0.0f;\n    bool _1364;\n    if (!_1357)\n    {\n        _1364 = _429_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1364 = _1357;\n    }\n    bool _1372;\n    if (!_1364)\n    {\n        _1372 = _429_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1372 = _1364;\n    }\n    bool _1379;\n    if (!_1372)\n    {\n        _1379 = _429_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1379 = _1372;\n    }\n    bool _1386;\n    if (!_1379)\n    {\n        _1386 = _429_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1386 = _1379;\n    }\n    if (_1386)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1396 = float4(world_pos, 1.0f);\n    float _1402 = dot(_429_fa_cl_vpw, _1396);\n    if (!(_1402 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1424 = float2(dot(_429_fa_cl_vpx, _1396), dot(_429_fa_cl_vpy, _1396)) / _1402.xx;\n    int _1428 = int(_429_fa_cl_grid.x);\n    int _1432 = int(_429_fa_cl_grid.y);\n    int param = (int(_429_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_429_fa_cl_fwd.xyz, world_pos) + _429_fa_cl_fwd.w, _429_fa_cl_grid.w) / _429_fa_cl_grid.w) * _429_fa_cl_grid.z)), 0, int(_429_fa_cl_info.y) - 1) * _1432) + clamp(int(floor(((_1424.y * 0.5f) + 0.5f) * _429_fa_cl_grid.y)), 0, _1432 - 1)) * _1428)) + clamp(int(floor(((_1424.x * 0.5f) + 0.5f) * _429_fa_cl_grid.x)), 0, _1428 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1508 = fa_cluster_texel(param);\n    return int2(int(_1508.x), int(_1508.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    float _4208 = dot(_429_fa_ct_fwd.xyz, world_pos) + _429_fa_ct_fwd.w;\n    float _4211 = fwidth(_4208);\n    bool _4214 = _429_fa_ct_b.y > 0.5f;\n    bool _4221;\n    if (!_4214)\n    {\n        _4221 = _429_fa_ct_b.w > 0.5f;\n    }\n    else\n    {\n        _4221 = _4214;\n    }\n    if (_4221)\n    {\n        fa_rt_slope = min(1.5f * _4211, 0.100000001490116119384765625f * _4208);\n    }\n    fa_cl_ndir = int(_429_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4237 = fa_cluster_lookup(param);\n    fa_cl_slot = _4237.x;\n    fa_cl_local = _4237.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4447 = fa_linear_to_srgb(param);\n        c = _4447;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4455 = fa_srgb_to_linear(param_1);\n            c = _4455;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _312;\n    if (i.front_facing)\n    {\n        _312 = i.world_normal;\n    }\n    else\n    {\n        _312 = -i.world_normal;\n    }\n    float3 _336 = normalize(i.world_tangent.xyz - (_312 * dot(_312, i.world_tangent.xyz)));\n    float3 _363 = normalize(((_336 * m.x) + ((cross(_312, _336) * i.world_tangent.w) * m.y)) + (_312 * m.z));\n    float3 _366;\n    if (i.front_facing)\n    {\n        _366 = _363;\n    }\n    else\n    {\n        _366 = -_363;\n    }\n    return _366;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _429_fa_env_horizon.w);\n    float param = _429_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4487 = fa_tex_fix(param_2, param_3);\n    float4 _6392 = base_t;\n    _6392.x = _4487.x;\n    _6392.y = _4487.y;\n    _6392.z = _4487.z;\n    base_t = _6392;\n    float4 _4501 = (_6392 * _429_fa_base_color) * i.vertex_color;\n    float3 _6208 = i.world_normal;\n    if (_429_fa_maps.z > 0.5f)\n    {\n        float param_4 = _429_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _429_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4535 = fa_tex_fix(param_6, param_7);\n        float3 _4538 = (_4535 * 2.0f) - 1.0f.xxx;\n        float2 _4543 = _4538.xy * _429_fa_maps.x;\n        float3 _6400 = _4538;\n        _6400.x = _4543.x;\n        _6400.y = _4543.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6400;\n        _6208 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _429_fa_env_horizon.w);\n    float param_10 = _429_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4573 = fa_tex_fix(param_12, param_13);\n    float4 _6403 = mrt;\n    _6403.x = _4573.x;\n    _6403.y = _4573.y;\n    _6403.z = _4573.z;\n    mrt = _6403;\n    float4 _4603 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _429_fa_env_horizon.w);\n    float param_14 = _429_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4603.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4614 = fa_tex_fix(param_16, param_17);\n    float param_18 = _429_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _429_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4646 = fa_tex_fix(param_20, param_21);\n    float _6213 = _429_fa_layers_a.x;\n    float _6214 = _429_fa_layers_a.y;\n    float _6217 = _429_fa_layers_a.z;\n    float _6216 = _429_fa_layers_b.w;\n    float _6219 = _429_fa_layers_c.x;\n    if (_429_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_429_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6213 *= _4614.y;\n            _6214 *= _4614.z;\n            _6216 *= _4603.w;\n        }\n        if (_429_fa_layers_c.z > 1.5f)\n        {\n            _6217 *= mrt.x;\n            _6219 *= mrt.w;\n        }\n    }\n    Surface _6246 = { _4501.xyz, _4501.w, _6208, clamp(_429_fa_pbr.x * _4573.z, 0.0f, 1.0f), clamp(_429_fa_pbr.y * _4573.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_429_fa_maps.y * (_4614.x - 1.0f)), _429_fa_emissive.xyz + (_429_fa_model_emissive.xyz * _4646), _6213, _6214, _429_fa_layers_b.xyz, _6216, _6217, _429_fa_layers_a.w, _6219, _429_fa_layers_c.y, _429_fa_layers_d.xyz, _429_fa_tr_a.x, _429_fa_tr_a.y, _429_fa_tr_b.xyz, _429_fa_tr_a.z };\n    return _6246;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1588 = rect.zw - rect.xy;\n    float2 _1592 = _1588 * atlas;\n    float2 _1596 = ddx * _1592;\n    float2 _1600 = ddy * _1592;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1588), clamp(0.5f * log2(max(max(dot(_1596, _1596), dot(_1600, _1600)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1633 = _429_fa_counts.y < 0.5f;\n    bool _1640;\n    if (!_1633)\n    {\n        _1640 = _429_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1640 = _1633;\n    }\n    if (_1640)\n    {\n        return;\n    }\n    float3 _1646 = ddx(world_pos);\n    float3 _1649 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1653 = fa_cluster_texel(param);\n    int _1657 = int(_1653.w);\n    if (_1657 < 1)\n    {\n        return;\n    }\n    int _1667 = int(_429_fa_counts.y + 0.5f);\n    int param_1 = _1667;\n    float4 _1671 = fa_light_texel(param_1);\n    float2 _1674 = _1671.yz;\n    int _1678 = int(_1671.w);\n    int param_2 = _1667 + 1;\n    float4 _1683 = fa_light_texel(param_2);\n    float _1684 = _1683.x;\n    int _1690 = int(_429_fa_counts.w + 0.5f) - 1;\n    int _1694 = int(_1653.z);\n    float3 _1959;\n    for (int k = 0; k < _1657; k++)\n    {\n        int _1707 = _1694 + k;\n        int param_3 = _1678 + (_1707 >> 2);\n        int _1724 = (_1667 + 2) + (int(fa_light_texel(param_3)[_1707 & 3]) * 7);\n        int param_4 = _1724 + 6;\n        float4 _1729 = fa_light_texel(param_4);\n        if (((int(_1729.w + 0.5f) >> _1690) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1724;\n        float4 _1744 = fa_light_texel(param_5);\n        int param_6 = _1724 + 1;\n        float4 _1749 = fa_light_texel(param_6);\n        int param_7 = _1724 + 2;\n        float4 _1754 = fa_light_texel(param_7);\n        float3 _1757 = _1744.xyz;\n        float _1762 = dot(_1757, world_pos) + _1744.w;\n        float3 _1764 = _1749.xyz;\n        float _1769 = dot(_1764, world_pos) + _1749.w;\n        float3 _1771 = _1754.xyz;\n        float _1776 = dot(_1771, world_pos) + _1754.w;\n        bool _1781 = abs(_1762) > 0.5f;\n        bool _1789;\n        if (!_1781)\n        {\n            _1789 = abs(_1769) > 0.5f;\n        }\n        else\n        {\n            _1789 = _1781;\n        }\n        bool _1797;\n        if (!_1789)\n        {\n            _1797 = abs(_1776) > 0.5f;\n        }\n        else\n        {\n            _1797 = _1789;\n        }\n        if (_1797)\n        {\n            continue;\n        }\n        float _1812 = clamp(dot(geo_normal, normalize(_1771)) * _1729.z, 0.0f, 1.0f);\n        if (_1812 <= 0.0f)\n        {\n            continue;\n        }\n        float _1832 = (clamp((0.5f - abs(_1776)) * 10.0f, 0.0f, 1.0f) * _1812) * _1729.x;\n        float2 _1840 = float2(_1762 + 0.5f, 0.5f - _1769);\n        float2 _1850 = float2(dot(_1757, _1646), dot(_1764, _1646));\n        float2 _1860 = float2(dot(_1757, _1649), dot(_1764, _1649));\n        int param_8 = _1724 + 5;\n        float4 _1865 = fa_light_texel(param_8);\n        int param_9 = _1724 + 3;\n        float4 _1870 = fa_light_texel(param_9);\n        int param_10 = _1724 + 4;\n        float4 _1875 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1865.xyz;\n        bool _1885 = _1870.z > _1870.x;\n        if (_1885)\n        {\n            float4 param_11 = _1870;\n            float2 param_12 = _1840;\n            float2 param_13 = _1674;\n            float2 param_14 = _1850;\n            float2 param_15 = _1860;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1684 > 0.5f) && (_1684 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1911 = fa_dc_to_linear(param_16);\n                float4 _6296 = tx;\n                _6296.x = _1911.x;\n                _6296.y = _1911.y;\n                _6296.z = _1911.z;\n                tx = _6296;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1832 * tex_a) * _1865.w, 0.0f, 1.0f).xxx);\n        if (_1875.z > _1875.x)\n        {\n            float4 param_17 = _1875;\n            float2 param_18 = _1840;\n            float2 param_19 = _1674;\n            float2 param_20 = _1850;\n            float2 param_21 = _1860;\n            float4 _1955 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1684 > 1.5f)\n            {\n                float3 param_22 = _1955.xyz;\n                float3 _1965 = fa_dc_to_srgb(param_22);\n                _1959 = _1965;\n            }\n            else\n            {\n                _1959 = _1955.xyz;\n            }\n            float3 _1974 = (_1959 * 2.0f) - 1.0f.xxx;\n            float2 _1979 = _1974.xy * _1729.y;\n            float3 _2001 = (normalize(_1757) * _1979.x) + (normalize(_1764) * _1979.y);\n            float3 _2004 = normalize(normal);\n            normal = normalize(lerp(_2004, normalize((_2004 * max(_1974.z, 0.0500000007450580596923828125f)) + (_2001 - (_2004 * dot(_2004, _2001)))), clamp(_1832 * (_1885 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3731_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3731_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_429_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3672 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3672;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3781 = (1.0f - _429_fa_rpa_tile.w) - _429_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3787 = _429_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3781 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3787)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _429_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3781;\n            }\n        }\n        else\n        {\n            amb = _429_fa_ambient.xyz * _3781;\n        }\n    }\n    bool _3838 = _429_fa_rpa_tile.w > 0.0f;\n    if (_3838)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _429_fa_rpa_tile.xy;\n            float param_4 = _429_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _429_fa_rpa_tile.w);\n        }\n    }\n    bool _3869 = _429_fa_rpb_tile.w > 0.0f;\n    if (_3869)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _429_fa_rpb_tile.xy;\n            float param_7 = _429_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _429_fa_rpb_tile.w);\n        }\n    }\n    if ((_3787 || _3838) || _3869)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3692 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3695 = _3692.x;\n    float _3697 = _3692.z;\n    float2 e = float2(_3695, _3697);\n    if (_3692.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3697)) * ((_3695 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3695)) * ((_3697 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _4760 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _4765 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _4770 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _4775 = fa_light_texel(param_3);\n    bool _4778 = _4775.z < 0.5f;\n    bool _4786;\n    if (!_4778)\n    {\n        _4786 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _4786 = _4778;\n    }\n    if (_4786)\n    {\n        return 0.0f.xxx;\n    }\n    float _4793 = max(_4760.w, 9.9999997473787516355514526367188e-05f);\n    float3 _4796 = _4765.xyz;\n    float3 _4800 = _4760.xyz;\n    float3 _4804 = (fa_world_pos - _4800) / _4793.xxx;\n    float3 _4813 = min(_4804 + 0.5f.xxx, (_4796 - 0.5f.xxx) - _4804);\n    float _4822 = min(_4813.x, min(_4813.y, _4813.z));\n    if (!(_4822 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4837 = _4796 - 1.0f.xxx;\n    float3 _4838 = clamp(_4804, 0.0f.xxx, _4837);\n    float3 _4846 = min(floor(_4838), max(_4796 - 2.0f.xxx, 0.0f.xxx));\n    float3 _4850 = _4838 - _4846;\n    float3 _4862 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _4793));\n    int _4867 = int(_4770.y + 0.5f);\n    float _4872 = 0.3257350027561187744140625f * n.y;\n    float _4876 = 0.3257350027561187744140625f * n.z;\n    float _4880 = 0.3257350027561187744140625f * n.x;\n    float _4887 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _4894 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _4903 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _4910 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _4923 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _4930 = 8 + int(_4775.w);\n    float _4957;\n    float _4970;\n    float _4984;\n    for (int k = 0; k < _4930; k++)\n    {\n        float _4943 = float(k & 1);\n        float _4947 = float((k >> 1) & 1);\n        float _4951 = float((k >> 2) & 1);\n        if (_4943 > 0.5f)\n        {\n            _4957 = _4850.x;\n        }\n        else\n        {\n            _4957 = 1.0f - _4850.x;\n        }\n        if (_4947 > 0.5f)\n        {\n            _4970 = _4850.y;\n        }\n        else\n        {\n            _4970 = 1.0f - _4850.y;\n        }\n        if (_4951 > 0.5f)\n        {\n            _4984 = _4850.z;\n        }\n        else\n        {\n            _4984 = 1.0f - _4850.z;\n        }\n        float _4994 = (_4957 * _4970) * _4984;\n        if (!(_4994 > 0.0f))\n        {\n            continue;\n        }\n        float3 _5007 = min(_4846 + float3(_4943, _4947, _4951), _4837);\n        int _5027 = int(((_4770.x + _5007.x) + (_4765.x * (_5007.y + (_4765.y * _5007.z)))) + 0.5f);\n        float2 _5042 = float2(float(_5027 % _4867) * 10.0f, 1024.0f + (float(_5027 / _4867) * 11.0f));\n        float2 param_4 = _5042 + float2(9.5f, 10.5f);\n        float4 _5050 = fa_gi_fetch(param_4);\n        bool _5053 = _5050.y < 0.5f;\n        bool _5062;\n        if (!_5053)\n        {\n            _5062 = _5050.x > _4775.y;\n        }\n        else\n        {\n            _5062 = _5053;\n        }\n        if (_5062)\n        {\n            continue;\n        }\n        float3 _5074 = _4862 - (_4800 + (_5007 * _4793));\n        float _5077 = length(_5074);\n        float3 _5083 = _5074 / max(_5077, 9.9999997473787516355514526367188e-05f).xxx;\n        float _5093 = max(9.9999997473787516355514526367188e-05f, (dot(-_5083, n) + 1.0f) * 0.5f);\n        float w = _4994 * (_5093 * _5093);\n        float3 param_5 = _5083;\n        float2 param_6 = (_5042 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _5113 = fa_gi_fetch(param_6);\n        float _5120 = _5077 / max(_4770.z, 9.9999997473787516355514526367188e-05f);\n        float _5123 = _5113.x;\n        if (_5120 > _5123)\n        {\n            float _5136 = max(_5113.y - (_5123 * _5123), 0.0f);\n            float _5141 = _5120 - _5123;\n            float _5150 = _5136 / max(_5136 + (_5141 * _5141), 9.9999999600419720025001879548654e-13f);\n            w *= ((_5150 * _5150) * _5150);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _5042 + float2(0.5f, 10.5f);\n        float2 param_8 = _5042 + float2(1.5f, 10.5f);\n        float2 param_9 = _5042 + float2(2.5f, 10.5f);\n        float2 param_10 = _5042 + float2(3.5f, 10.5f);\n        float2 param_11 = _5042 + float2(4.5f, 10.5f);\n        float2 param_12 = _5042 + float2(5.5f, 10.5f);\n        float2 param_13 = _5042 + float2(6.5f, 10.5f);\n        float2 param_14 = _5042 + float2(7.5f, 10.5f);\n        float2 param_15 = _5042 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _4872)) + (fa_gi_fetch(param_9).xyz * _4876)) + (fa_gi_fetch(param_10).xyz * _4880)) + (fa_gi_fetch(param_11).xyz * _4887)) + (fa_gi_fetch(param_12).xyz * _4894)) + (fa_gi_fetch(param_13).xyz * _4903)) + (fa_gi_fetch(param_14).xyz * _4910)) + (fa_gi_fetch(param_15).xyz * _4923)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_4822 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _5278;\n    if (_429_fa_gi.z > 0.5f)\n    {\n        _5278 = _4775.x;\n    }\n    else\n    {\n        _5278 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_4770.w * _5278);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _5302 = normalize(_429_fa_camera_pos.xyz - fa_world_pos);\n    int _5307 = int(_429_fa_gi.x + 0.5f);\n    int _5312 = int(_429_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _5312) && (k < 8); k++)\n    {\n        int param = _5307 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _5302;\n        float3 _5337 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5342 = param_3 * left;\n        acc += (_5337 * _5342);\n        left -= _5342;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_429_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _5371 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5371;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_429_fa_gi_px.x > 0.5f)\n    {\n        float4 _5413 = float4(fa_world_pos, 1.0f);\n        float2 _5432 = float2(dot(_429_fa_ct_vpx, _5413), dot(_429_fa_ct_vpy, _5413)) / max(dot(_429_fa_ct_vpw, _5413), 9.9999997473787516355514526367188e-05f).xx;\n        float _5441;\n        if (_429_fa_ct_a.y > 0.5f)\n        {\n            _5441 = (_5432.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5441 = 0.5f - (_5432.y * 0.5f);\n        }\n        return fa_lightmap.Load(int3(clamp(int2(float2((_5432.x * 0.5f) + 0.5f, _5441) * _429_fa_ct_a.zw), int2(0, 0), int2(_429_fa_ct_a.zw) - int2(1, 1)), 0)).xyz;\n    }\n    if (_429_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _429_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_429_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return float3(0.0f, ambientColor.y, 0.0f);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_429_fa_cl_info.x) + int(_429_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_429_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4178;\n    if (fa_lm.z > 0.5f)\n    {\n        _4178 = 0.0f;\n    }\n    else\n    {\n        _4178 = 1.0f - clamp(_429_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4189 = _4178 < 1.0f;\n    bool _4195;\n    if (_4189)\n    {\n        int param = li;\n        _4195 = fa_light_baked(param);\n    }\n    else\n    {\n        _4195 = _4189;\n    }\n    return _4195 ? _4178 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _607 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _620 = (c - (ru * hx)) - p;\n        float3 _626 = ru * (2.0f * hx);\n        float _632 = max(dot(_626, _626), 9.9999999392252902907785028219223e-09f);\n        float _636 = dot(_620, _626);\n        float t = clamp((-_636) / _632, 0.0f, 1.0f);\n        if (_607)\n        {\n            float _651 = dot(r, _626);\n            float _657 = _632 - (_651 * _651);\n            if (abs(_657) > (9.9999997473787516355514526367188e-06f * _632))\n            {\n                t = clamp(((dot(r, _620) * _651) - _636) / _657, 0.0f, 1.0f);\n            }\n        }\n        return (p + _620) + (_626 * t);\n    }\n    float3 q = p;\n    float _689 = dot(r, axis);\n    bool _697;\n    if (_607)\n    {\n        _697 = abs(_689) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _697 = _607;\n    }\n    if (_697)\n    {\n        float _707 = dot(c - p, axis) / _689;\n        if (_707 > 0.0f)\n        {\n            q = p + (r * _707);\n        }\n    }\n    float3 _720 = q - c;\n    float2 xy = float2(dot(_720, ru), dot(_720, uu));\n    if (shape > 0.5f)\n    {\n        float _735 = length(xy);\n        if (_735 > hx)\n        {\n            xy *= (hx / _735);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _488_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _488_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _527 = dot(d, right);\n    float _531 = dot(d, up);\n    float _542;\n    if (((_527 * _527) + (_531 * _531)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _542 = atan2(_531, _527) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _542 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_542 - floor(_542)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _378 = abs(d);\n    float _380 = _378.x;\n    float _382 = _378.y;\n    bool _383 = _380 >= _382;\n    bool _391;\n    if (_383)\n    {\n        _391 = _380 >= _378.z;\n    }\n    else\n    {\n        _391 = _383;\n    }\n    int _392;\n    if (_391)\n    {\n        _392 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _406;\n        if (_382 >= _378.z)\n        {\n            _406 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _406 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _392 = _406;\n    }\n    return _392;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _773 = fa_light_base(param);\n    bool _777 = _429_fa_ambient.w > 4.5f;\n    int param_1 = _773;\n    float4 _781 = fa_light_texel(param_1);\n    int param_2 = _773 + 1;\n    float4 _786 = fa_light_texel(param_2);\n    float _789 = _786.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _801 = _777 && (_789 > 2.5f);\n    fa_light_is_area = _801;\n    bool _803 = _789 < 0.5f;\n    float3 l;\n    if (_803)\n    {\n        l = normalize(_781.xyz);\n        if (_777)\n        {\n            int param_3 = _773 + 6;\n            float4 _817 = fa_light_texel(param_3);\n            if (_817.z > 0.5f)\n            {\n                int param_4 = _773 + 4;\n                float4 _827 = fa_light_texel(param_4);\n                int param_5 = _773 + 5;\n                float4 _832 = fa_light_texel(param_5);\n                float2 param_6 = _817.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _827.xyz) * _827.w, (-dot(world_pos, _832.xyz)) * _832.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _862 = _781.xyz;\n        float3 _864 = _862 - world_pos;\n        float3 to_light = _864;\n        float _867 = length(_864);\n        float reach = _867;\n        bool front = true;\n        if (_801)\n        {\n            int param_8 = _773 + 7;\n            reach = max(_867 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _773 + 4;\n            float4 _891 = fa_light_texel(param_9);\n            int param_10 = _773 + 5;\n            float4 _896 = fa_light_texel(param_10);\n            int param_11 = _773 + 6;\n            float4 _901 = fa_light_texel(param_11);\n            float _902 = _901.w;\n            int param_12 = _773 + 2;\n            float3 _909 = normalize(fa_light_texel(param_12).xyz);\n            bool _911 = _902 > 1.5f;\n            bool _919;\n            if (!_911)\n            {\n                _919 = dot(_909, to_light) < 0.0f;\n            }\n            else\n            {\n                _919 = _911;\n            }\n            front = _919;\n            float3 r = 0.0f.xxx;\n            float3 _928 = _429_fa_camera_pos.xyz - world_pos;\n            bool _932 = dot(n, n) > 0.5f;\n            bool _940;\n            if (_932)\n            {\n                _940 = dot(_928, _928) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _940 = _932;\n            }\n            if (_940)\n            {\n                r = reflect(-normalize(_928), normalize(n));\n            }\n            float3 param_13 = _862;\n            float3 param_14 = _909;\n            float3 param_15 = _891.xyz;\n            float3 param_16 = _896.xyz;\n            float param_17 = _891.w;\n            float param_18 = _896.w;\n            float param_19 = _902;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _976 = length(to_light);\n        dist = _976;\n        l = to_light / max(_976, 9.9999997473787516355514526367188e-05f).xxx;\n        float _990 = reach / max(_781.w, 0.001000000047497451305389404296875f);\n        float _996 = clamp(1.0f - (_990 * _990), 0.0f, 1.0f);\n        float _998;\n        if (front)\n        {\n            _998 = _996 * _996;\n        }\n        else\n        {\n            _998 = 0.0f;\n        }\n        atten = _998;\n        bool _1009 = _789 < 2.5f;\n        if ((_789 > 1.5f) && _1009)\n        {\n            int param_22 = _773 + 2;\n            float4 _1017 = fa_light_texel(param_22);\n            float _1027 = _1017.w;\n            int param_23 = _773 + 3;\n            float4 _1032 = fa_light_texel(param_23);\n            float _1033 = _1032.x;\n            float cos_inner = _1033;\n            if (_1033 > 1.5f)\n            {\n                cos_inner = lerp(_1027, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1027, cos_inner, dot(-l, normalize(_1017.xyz)));\n        }\n        if (_777 && (_789 < 1.5f))\n        {\n            int param_24 = _773 + 6;\n            float4 _1057 = fa_light_texel(param_24);\n            if (_1057.z > 0.5f)\n            {\n                float3 _1065 = -to_light;\n                int param_25 = _773 + 4;\n                int param_26 = _773 + 5;\n                float3 _1079 = fa_light_texel(param_25).xyz;\n                float3 _1083 = fa_light_texel(param_26).xyz;\n                float3 _1092 = float3(dot(_1065, _1079), dot(_1065, _1083), dot(_1065, cross(_1079, _1083)));\n                float3 param_27 = _1092;\n                int _1096 = fa_cube_face(param_27);\n                int param_28 = _1096;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1123 = float2(dot(_1092, cross(param_29, param_30)), dot(_1092, param_30)) / max(dot(_1092, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1127 = _1096 / 3;\n                float2 param_31 = _1057.xy + (float2(float(_1096 - (_1127 * 3)), float(_1127)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1123.x), 0.5f - (0.5f * _1123.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _773 + 7;\n            float4 _1157 = fa_light_texel(param_33);\n            if (_1157.z > 0.5f)\n            {\n                int param_34 = _773 + 2;\n                int param_35 = _773 + 4;\n                int param_36 = _773 + 5;\n                float2 param_37 = _1157.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_777 && _1009)\n            {\n                int param_42 = _773 + 6;\n                float4 _1204 = fa_light_texel(param_42);\n                int param_43 = _773 + 7;\n                float4 _1209 = fa_light_texel(param_43);\n                bool _1212 = _1204.z > 0.5f;\n                bool _1219;\n                if (!_1212)\n                {\n                    _1219 = _1209.z > 0.5f;\n                }\n                else\n                {\n                    _1219 = _1212;\n                }\n                if (_1219)\n                {\n                    int param_44 = _773 + 2;\n                    float4 _1226 = fa_light_texel(param_44);\n                    float3 _1230 = normalize(_1226.xyz);\n                    int param_45 = _773 + 4;\n                    float4 _1235 = fa_light_texel(param_45);\n                    int param_46 = _773 + 5;\n                    float4 _1240 = fa_light_texel(param_46);\n                    if (_1212)\n                    {\n                        float3 _1248 = -to_light;\n                        float _1255 = _1226.w;\n                        float _1271 = 0.5f / max(dot(_1248, _1230) * (sqrt(max(1.0f - (_1255 * _1255), 0.0f)) / max(_1255, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1204.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1248, _1235.xyz) * _1271), 0.5f - (dot(_1248, _1240.xyz) * _1271));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1209.z > 0.5f)\n                    {\n                        float2 param_49 = _1209.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1230;\n                        float3 param_52 = _1235.xyz;\n                        float3 param_53 = _1240.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6162 = _786.xyz * atten;\n    if (_777)\n    {\n        _6162 *= fa_light_tint;\n    }\n    int _1339;\n    if (_803)\n    {\n        _1339 = 0;\n    }\n    else\n    {\n        _1339 = ((_789 > 1.5f) && (_789 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _6173 = { l, _6162, atten, 1.0f, dist, _1339 };\n    return _6173;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2128 = fa_shadow_depth(param, param_1);\n    float _2132;\n    if (conv.x < 0.5f)\n    {\n        _2132 = _2128;\n    }\n    else\n    {\n        _2132 = (conv.y * conv.z) / (conv.z - (_2128 * (conv.z - conv.y)));\n    }\n    return _2132;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2178 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2184 = float2(cos(_2178), sin(_2178));\n    float2 dir = _2184;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2193;\n        if (k < 0.0f)\n        {\n            _2193 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2193 = k;\n        }\n        float _2212 = clamp((_2193 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2231 = sqrt((float(i) + 0.5f) * 0.0625f) * _2212;\n            float2 param_3 = uv + (dir * (_2081_fa_shadow_bias.zw * _2231));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2245 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2245 < (zr - (_2231 * plane)))\n            {\n                sum += _2245;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2273 = sum / cnt;\n        float _2283;\n        if (k < 0.0f)\n        {\n            _2283 = (-k) / max(_2273, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2283 = k;\n        }\n        radius = clamp(((max(zr - _2273, 0.0f) * unit) * _2283) / texel_m, 1.5f, 16.0f);\n        dir = _2184;\n    }\n    float lit = 0.0f;\n    int _2309 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2309; i_1++)\n    {\n        float _2328 = sqrt((float(i_1) + 0.5f) / float(_2309)) * radius;\n        float2 param_7 = uv + (dir * (_2081_fa_shadow_bias.zw * _2328));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2328 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2309);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2533 = _429_fa_pbr.z < 0.5f;\n    bool _2540;\n    if (!_2533)\n    {\n        _2540 = _2081_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2540 = _2533;\n    }\n    if (_2540)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2081_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2553 = fa_light_texel(param);\n    float _2554 = _2553.x;\n    if (_2554 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2563 = int(_2554 + 0.5f);\n    int param_1 = _2563;\n    float4 _2567 = fa_light_texel(param_1);\n    int param_2 = _2563 + 1;\n    float4 _2572 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2575 = _2567.y;\n    if (_2575 > 0.0f)\n    {\n        float _2592 = 1.0f - smoothstep(0.75f * _2575, _2575, length(world - _2081_fa_shadow_eye.xyz));\n        fade = _2592;\n        if (_2592 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2567.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2616 = (_2563 + 2) + (face * 6);\n    int param_4 = _2616;\n    int param_5 = _2616 + 1;\n    int param_6 = _2616 + 3;\n    float4 _2630 = fa_light_texel(param_6);\n    int param_7 = _2616 + 4;\n    float4 _2635 = fa_light_texel(param_7);\n    int param_8 = _2616 + 5;\n    float4 _2640 = fa_light_texel(param_8);\n    float _2652 = _2640.x * max(dot(_2630, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2657 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2680 = clamp(dot(n, _2630.xyz), -1.0f, 1.0f);\n    float _2699 = min(sqrt(1.0f - (_2680 * _2680)) / max(abs(dot(n, world - lpos)) / max(dot(_2630, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2702 = _2572.y;\n    float _2704;\n    if (_2702 > 0.0f)\n    {\n        _2704 = _2702;\n    }\n    else\n    {\n        _2704 = 1.5f * _2652;\n    }\n    float4 _2724 = float4(world + (n * (_2704 * sqrt(1.0f - (_2657 * _2657)))), 1.0f);\n    float _2728 = dot(_2630, _2724);\n    float _2731 = _2640.y;\n    if (_2728 < _2731)\n    {\n        return 1.0f;\n    }\n    float2 _2746 = float2(dot(fa_light_texel(param_4), _2724), dot(fa_light_texel(param_5), _2724)) / _2728.xx;\n    float _2748 = _2746.x;\n    bool _2751 = _2748 < _2635.x;\n    bool _2760;\n    if (!_2751)\n    {\n        _2760 = _2748 > _2635.z;\n    }\n    else\n    {\n        _2760 = _2751;\n    }\n    bool _2769;\n    if (!_2760)\n    {\n        _2769 = _2746.y < _2635.y;\n    }\n    else\n    {\n        _2769 = _2760;\n    }\n    bool _2778;\n    if (!_2769)\n    {\n        _2778 = _2746.y > _2635.w;\n    }\n    else\n    {\n        _2778 = _2769;\n    }\n    if (_2778)\n    {\n        return 1.0f;\n    }\n    float _2784 = _2572.x;\n    float _2786;\n    if (_2784 > 0.0f)\n    {\n        _2786 = _2784;\n    }\n    else\n    {\n        _2786 = 1.5f * _2652;\n    }\n    float2 param_9 = _2746;\n    float4 param_10 = _2635;\n    float param_11 = _2728 - (_2786 * (1.0f + (0.5f * _2699)));\n    float param_12 = _2652;\n    float param_13 = 1.0f;\n    float param_14 = _2640.z * 0.25f;\n    float param_15 = (_2652 * min(_2699, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2731, _2640.z);\n    int param_17 = int(_2567.z + 0.5f);\n    float param_18 = _2567.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _3293 = _429_fa_ct_b.w > 0.5f;\n    bool _3299;\n    if (_3293)\n    {\n        _3299 = _429_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3299 = _3293;\n    }\n    bool _3305;\n    if (_3299)\n    {\n        _3305 = _2081_fa_shadow_lcfg.x > 0.5f;\n    }\n    else\n    {\n        _3305 = _3299;\n    }\n    if (_3305)\n    {\n        int param = (int(_2081_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n        float4 _3317 = fa_light_texel(param);\n        float _3318 = _3317.z;\n        if (_3318 > 0.5f)\n        {\n            float _3331 = dot(_429_fa_ct_fwd.xyz, world) + _429_fa_ct_fwd.w;\n            float _3337 = ((0.00200000009499490261077880859375f * _3331) + 0.00999999977648258209228515625f) + fa_rt_slope;\n            float4 _3343 = float4(world, 1.0f);\n            float _3348 = dot(_429_fa_ct_vpw, _3343);\n            if (_3348 > 9.9999997473787516355514526367188e-05f)\n            {\n                float2 _3365 = float2(dot(_429_fa_ct_vpx, _3343), dot(_429_fa_ct_vpy, _3343)) / _3348.xx;\n                float _3370 = (_3365.x * 0.5f) + 0.5f;\n                float _3374;\n                if (_429_fa_ct_a.y > 0.5f)\n                {\n                    _3374 = (_3365.y * 0.5f) + 0.5f;\n                }\n                else\n                {\n                    _3374 = 0.5f - (_3365.y * 0.5f);\n                }\n                bool _3390 = _3370 >= 0.0f;\n                bool _3396;\n                if (_3390)\n                {\n                    _3396 = _3370 < 1.0f;\n                }\n                else\n                {\n                    _3396 = _3390;\n                }\n                bool _3402;\n                if (_3396)\n                {\n                    _3402 = _3374 >= 0.0f;\n                }\n                else\n                {\n                    _3402 = _3396;\n                }\n                bool _3408;\n                if (_3402)\n                {\n                    _3408 = _3374 < 1.0f;\n                }\n                else\n                {\n                    _3408 = _3402;\n                }\n                if (_3408)\n                {\n                    int2 _3425 = int2(_429_fa_ct_a.zw) - int2(1, 1);\n                    int2 _3426 = clamp(int2(float2(_3370, _3374) * _429_fa_ct_a.zw), int2(0, 0), _3425);\n                    float _3430;\n                    if (_3318 < 1.5f)\n                    {\n                        _3430 = 1.0f;\n                    }\n                    else\n                    {\n                        _3430 = (_3318 < 2.5f) ? 256.0f : 65536.0f;\n                    }\n                    float best = 2.0f;\n                    int _3452;\n                    int _3458;\n                    for (int k = 0; k < 9; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3452 = 4;\n                        }\n                        else\n                        {\n                            if (k <= 4)\n                            {\n                                _3458 = k - 1;\n                            }\n                            else\n                            {\n                                _3458 = k;\n                            }\n                            _3452 = _3458;\n                        }\n                        float4 _3487 = fa_screen_tex.Load(int3(clamp(_3426 + int2((_3452 % 3) - 1, (_3452 / 3) - 1), int2(0, 0), _3425), 0));\n                        bool _3490 = _3487.w > 0.5f;\n                        bool _3500;\n                        if (_3490)\n                        {\n                            _3500 = abs(_3331 - _3487.x) <= _3337;\n                        }\n                        else\n                        {\n                            _3500 = _3490;\n                        }\n                        if (_3500)\n                        {\n                            best = min(best, mod(floor(_3487.z / _3430), 256.0f) * 0.0039215688593685626983642578125f);\n                            if (k == 0)\n                            {\n                                break;\n                            }\n                        }\n                    }\n                    if (best <= 1.0f)\n                    {\n                        float _3527;\n                        if (_429_fa_ct_b.z > 0.5f)\n                        {\n                            int param_1 = li;\n                            float3 param_2 = lpos;\n                            float3 param_3 = world;\n                            float3 param_4 = n;\n                            float3 param_5 = l;\n                            _3527 = min(best, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                        }\n                        else\n                        {\n                            _3527 = best;\n                        }\n                        return _3527;\n                    }\n                }\n            }\n            float _3550;\n            if (_429_fa_ct_b.z > 0.5f)\n            {\n                int param_6 = li;\n                float3 param_7 = lpos;\n                float3 param_8 = world;\n                float3 param_9 = n;\n                float3 param_10 = l;\n                _3550 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3550 = 1.0f;\n            }\n            return _3550;\n        }\n    }\n    int param_11 = li;\n    float3 param_12 = lpos;\n    float3 param_13 = world;\n    float3 param_14 = n;\n    float3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2071;\n    if (i == 0)\n    {\n        _2071 = _2081_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2087;\n        if (i == 1)\n        {\n            _2087 = _2081_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2095;\n            if (i == 2)\n            {\n                _2095 = _2081_fa_shadow_split.z;\n            }\n            else\n            {\n                _2095 = _2081_fa_shadow_split.w;\n            }\n            _2087 = _2095;\n        }\n        _2071 = _2087;\n    }\n    return _2071;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2374 = max(_2081_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2379 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2385 = sqrt(1.0f - (_2379 * _2379));\n    float _2393 = min(_2385 / max(_2379, 0.20000000298023223876953125f), 4.0f);\n    float _2398;\n    if (_2081_fa_shadow_bias.y > 0.0f)\n    {\n        _2398 = _2081_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2398 = 1.5f * _2081_fa_shadow_info[ci].x;\n    }\n    float4 _2423 = mul(float4(world + (n * (_2398 * _2385)), 1.0f), _2081_fa_shadow_mat[ci]);\n    float _2430 = _2423.x;\n    bool _2433 = _2430 < _2081_fa_shadow_rect[ci].x;\n    bool _2442;\n    if (!_2433)\n    {\n        _2442 = _2430 > _2081_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2442 = _2433;\n    }\n    bool _2451;\n    if (!_2442)\n    {\n        _2451 = _2423.y < _2081_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2451 = _2442;\n    }\n    bool _2460;\n    if (!_2451)\n    {\n        _2460 = _2423.y > _2081_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2460 = _2451;\n    }\n    bool _2467;\n    if (!_2460)\n    {\n        _2467 = _2423.z > 1.0f;\n    }\n    else\n    {\n        _2467 = _2460;\n    }\n    if (_2467)\n    {\n        return -1.0f;\n    }\n    float _2475;\n    if (_2081_fa_shadow_bias.x > 0.0f)\n    {\n        _2475 = _2081_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2475 = 1.5f * _2081_fa_shadow_info[ci].x;\n    }\n    float2 param = _2423.xy;\n    float4 param_1 = _2081_fa_shadow_rect[ci];\n    float param_2 = _2423.z - ((_2475 * (1.0f + (0.5f * _2393))) / _2374);\n    float param_3 = _2081_fa_shadow_info[ci].x;\n    float param_4 = _2374;\n    float param_5 = _2374 * 0.25f;\n    float param_6 = ((_2081_fa_shadow_info[ci].x * min(_2393, 3.0f)) * 0.5f) / _2374;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2081_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2081_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_429_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2853 = int(_2081_fa_shadow_cfg.x + 0.5f);\n    if (_2853 < 1)\n    {\n        return 1.0f;\n    }\n    float _2868 = dot(world - _2081_fa_shadow_eye.xyz, _2081_fa_shadow_fwd.xyz);\n    int param = _2853 - 1;\n    if (_2868 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2880 = _2853 > 1;\n    bool _2887;\n    if (_2880)\n    {\n        _2887 = _2868 > _2081_fa_shadow_split.x;\n    }\n    else\n    {\n        _2887 = _2880;\n    }\n    if (_2887)\n    {\n        ci = 1;\n    }\n    bool _2891 = _2853 > 2;\n    bool _2898;\n    if (_2891)\n    {\n        _2898 = _2868 > _2081_fa_shadow_split.y;\n    }\n    else\n    {\n        _2898 = _2891;\n    }\n    if (_2898)\n    {\n        ci = 2;\n    }\n    bool _2902 = _2853 > 3;\n    bool _2909;\n    if (_2902)\n    {\n        _2909 = _2868 > _2081_fa_shadow_split.z;\n    }\n    else\n    {\n        _2909 = _2902;\n    }\n    if (_2909)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _2920 = min(_2853, 4);\n    float _2961;\n    for (int c = ci; c < _2920; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2940 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _2940;\n            break;\n        }\n        if (_2940 < 0.0f)\n        {\n            continue;\n        }\n        s = _2940;\n        ci = c;\n        if (_2081_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2961 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2961 = _2081_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _2980 = _2081_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2961, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_2868 - (fa_shadow_split_at(param_7) - _2980)) / _2980, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3012;\n        if ((ci + 1) < _2853)\n        {\n            _3012 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3012 = 1.0f;\n        }\n        s = lerp(s, _3012, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    bool _3117 = _429_fa_ct_b.y > 0.5f;\n    bool _3123;\n    if (_3117)\n    {\n        _3123 = _429_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3123 = _3117;\n    }\n    if (_3123)\n    {\n        float _3137 = dot(_429_fa_ct_fwd.xyz, fa_world_pos) + _429_fa_ct_fwd.w;\n        float4 _3145 = float4(fa_world_pos, 1.0f);\n        float _3151 = dot(_429_fa_ct_vpw, _3145);\n        if (_3151 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _3170 = float2(dot(_429_fa_ct_vpx, _3145), dot(_429_fa_ct_vpy, _3145)) / _3151.xx;\n            float _3175 = (_3170.x * 0.5f) + 0.5f;\n            float _3179;\n            if (_429_fa_ct_a.y > 0.5f)\n            {\n                _3179 = (_3170.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _3179 = 0.5f - (_3170.y * 0.5f);\n            }\n            bool _3195 = _3175 >= 0.0f;\n            bool _3201;\n            if (_3195)\n            {\n                _3201 = _3175 < 1.0f;\n            }\n            else\n            {\n                _3201 = _3195;\n            }\n            bool _3207;\n            if (_3201)\n            {\n                _3207 = _3179 >= 0.0f;\n            }\n            else\n            {\n                _3207 = _3201;\n            }\n            bool _3213;\n            if (_3207)\n            {\n                _3213 = _3179 < 1.0f;\n            }\n            else\n            {\n                _3213 = _3207;\n            }\n            if (_3213)\n            {\n                float4 _3239 = fa_screen_tex.Load(int3(clamp(int2(float2(_3175, _3179) * _429_fa_ct_a.zw), int2(0, 0), int2(_429_fa_ct_a.zw) - int2(1, 1)), 0));\n                bool _3242 = _3239.w > 0.5f;\n                bool _3258;\n                if (_3242)\n                {\n                    _3258 = abs(_3137 - _3239.x) <= (((0.00200000009499490261077880859375f * _3137) + 0.00999999977648258209228515625f) + fa_rt_slope);\n                }\n                else\n                {\n                    _3258 = _3242;\n                }\n                if (_3258)\n                {\n                    float _3264;\n                    if (_429_fa_ct_b.z > 0.5f)\n                    {\n                        float3 param = fa_world_pos;\n                        float3 param_1 = n;\n                        float3 param_2 = l;\n                        _3264 = min(_3239.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3264 = _3239.y;\n                    }\n                    return _3264;\n                }\n            }\n        }\n    }\n    float3 param_3 = fa_world_pos;\n    float3 param_4 = n;\n    float3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3920 = _429_fa_ct_a.x < 0.5f;\n    bool _3927;\n    if (!_3920)\n    {\n        _3927 = _2081_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3927 = _3920;\n    }\n    if (_3927)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2081_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3940 = fa_light_texel(param);\n    float _3941 = _3940.y;\n    float len = _3941;\n    if (_3941 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3953 = length(world - _429_fa_camera_pos.xyz);\n    float _3962 = 1.0f - smoothstep(0.5f * _429_fa_ct_b.x, _429_fa_ct_b.x, _3953);\n    if (_3962 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3968 = len;\n    float _3971 = min(_3968, 0.89999997615814208984375f * dist);\n    len = _3971;\n    float _3977 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3953);\n    float _3982 = _3977 + (0.5f * _3971);\n    float3 _3988 = world + (gn * _3977);\n    float _3990 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4052;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4006 = (float(k) + _3990) * 0.083333335816860198974609375f;\n        float3 _4014 = _3988 + (l * (_4006 * len));\n        float4 _4020 = float4(_4014, 1.0f);\n        float _4025 = dot(_429_fa_ct_vpw, _4020);\n        if (_4025 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4043 = float2(dot(_429_fa_ct_vpx, _4020), dot(_429_fa_ct_vpy, _4020)) / _4025.xx;\n        float _4047 = _4043.x * 0.5f;\n        float _4048 = _4047 + 0.5f;\n        if (_429_fa_ct_a.y > 0.5f)\n        {\n            _4052 = (_4043.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4052 = 0.5f - (_4043.y * 0.5f);\n        }\n        bool _4068 = _4048 < 0.0f;\n        bool _4075;\n        if (!_4068)\n        {\n            _4075 = _4048 >= 1.0f;\n        }\n        else\n        {\n            _4075 = _4068;\n        }\n        bool _4082;\n        if (!_4075)\n        {\n            _4082 = _4052 < 0.0f;\n        }\n        else\n        {\n            _4082 = _4075;\n        }\n        bool _4089;\n        if (!_4082)\n        {\n            _4089 = _4052 >= 1.0f;\n        }\n        else\n        {\n            _4089 = _4082;\n        }\n        if (_4089)\n        {\n            break;\n        }\n        float4 _4113 = fa_screen_tex.Load(int3(clamp(int2(float2(_4048, _4052) * _429_fa_ct_a.zw), int2(0, 0), int2(_429_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_4113.w < 0.5f)\n        {\n            continue;\n        }\n        float _4131 = (dot(_429_fa_ct_fwd.xyz, _4014) + _429_fa_ct_fwd.w) - _4113.x;\n        if ((_4131 > _3977) && (_4131 < _3982))\n        {\n            occ = max(occ, (1.0f - (_4006 * _4006)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4048, 0.5f - _4047), min(_4052, 1.0f - _4052))));\n        }\n    }\n    return 1.0f - (occ * _3962);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4263 = fa_baked_keep(param);\n    if (_4263 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _6186 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6186;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4289 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6188 = _4289.color;\n    float _6189 = _4289.attenuation;\n    float _6190 = _4289.shadow;\n    bool _4292 = _4289.type == 0;\n    if (_4292 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4289.direction;\n        float _4303 = fa_shadow_factor(param_5, param_6);\n        _6190 = _4303;\n        _6188 *= _4303;\n    }\n    else\n    {\n        bool _4314 = _4289.type != 0;\n        bool _4320;\n        if (_4314)\n        {\n            _4320 = _6189 > 0.0f;\n        }\n        else\n        {\n            _4320 = _4314;\n        }\n        if (_4320)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4289.direction;\n            float _4339 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6190 = _4339;\n            _6188 *= _4339;\n        }\n    }\n    bool _4349 = _429_fa_ct_a.x > 0.5f;\n    bool _4355;\n    if (_4349)\n    {\n        _4355 = _6189 > 0.0f;\n    }\n    else\n    {\n        _4355 = _4349;\n    }\n    if (_4355)\n    {\n        float _4362;\n        if (_4292)\n        {\n            _4362 = 1000000000.0f;\n        }\n        else\n        {\n            _4362 = _4289._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4289.direction;\n        float param_18 = _4362;\n        float _4380 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6190 *= _4380;\n        _6188 *= _4380;\n    }\n    float _4393 = _6189;\n    float _4394 = _4393 * _4263;\n    _6189 = _4394;\n    float3 _4398 = _6188;\n    float3 _4399 = _4398 * _4263;\n    _6188 = _4399;\n    LightSample _6205 = { _4289.direction, _4399, _4394, _6190, _4289._distance, _4289.type };\n    return _6205;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2081_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3040 = int(_2081_fa_shadow_cfg.x + 0.5f);\n    float _3050 = dot(world - _2081_fa_shadow_eye.xyz, _2081_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3055 = _3040 > 0;\n    bool _3064;\n    if (_3055)\n    {\n        int param = _3040 - 1;\n        _3064 = _3050 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3064 = _3055;\n    }\n    if (_3064)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3070 = _3040 > 1;\n        bool _3077;\n        if (_3070)\n        {\n            _3077 = _3050 > _2081_fa_shadow_split.x;\n        }\n        else\n        {\n            _3077 = _3070;\n        }\n        if (_3077)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3083 = _3040 > 2;\n        bool _3090;\n        if (_3083)\n        {\n            _3090 = _3050 > _2081_fa_shadow_split.y;\n        }\n        else\n        {\n            _3090 = _3083;\n        }\n        if (_3090)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3096 = _3040 > 3;\n        bool _3103;\n        if (_3096)\n        {\n            _3103 = _3050 > _2081_fa_shadow_split.z;\n        }\n        else\n        {\n            _3103 = _3096;\n        }\n        if (_3103)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_rt_slope = 0.0f;\n    fa_inst_load();\n    float3 _5980 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5980 = -_5980;\n    }\n    float3 _5554 = normalize(_429_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5993 = { fa_world_pos, _5980, fa_world_tangent, fa_uv, fa_vertex_color, _5554, gl_FrontFacing };\n    SurfaceInput param_1 = _5993;\n    Surface _5562 = fa_standard_surface(param_1);\n    float3 _6019 = _5562.albedo;\n    float _6020 = _5562.alpha;\n    float3 _6021 = _5562.normal;\n    float _6022 = _5562.metallic;\n    float _6023 = _5562.roughness;\n    float _6024 = _5562.occlusion;\n    float3 _6025 = _5562.emission;\n    float _6026 = _5562.clearcoat;\n    float _6027 = _5562.clearcoat_roughness;\n    float3 _6028 = _5562.sheen_color;\n    float _6029 = _5562.sheen_roughness;\n    float _6030 = _5562.anisotropy;\n    float _6031 = _5562.anisotropy_rotation;\n    float _6032 = _5562.specular;\n    float _6033 = _5562.ior;\n    float3 _6034 = _5562.specular_color;\n    float _6035 = _5562.transmission;\n    float _6036 = _5562.thickness;\n    float3 _6037 = _5562.attenuation_color;\n    float _6038 = _5562.attenuation_distance;\n    SurfaceInput _6001 = { fa_world_pos, _5980, fa_world_tangent, fa_uv, fa_vertex_color, _5554, gl_FrontFacing };\n    SurfaceInput param_2 = _6001;\n    Surface param_3 = _5562;\n    surface(param_2, param_3);\n    _6019 = param_3.albedo;\n    _6020 = param_3.alpha;\n    _6021 = param_3.normal;\n    _6022 = param_3.metallic;\n    _6023 = param_3.roughness;\n    _6024 = param_3.occlusion;\n    _6025 = param_3.emission;\n    _6026 = param_3.clearcoat;\n    _6027 = param_3.clearcoat_roughness;\n    _6028 = param_3.sheen_color;\n    _6029 = param_3.sheen_roughness;\n    _6030 = param_3.anisotropy;\n    _6031 = param_3.anisotropy_rotation;\n    _6032 = param_3.specular;\n    _6033 = param_3.ior;\n    _6034 = param_3.specular_color;\n    _6035 = param_3.transmission;\n    _6036 = param_3.thickness;\n    _6037 = param_3.attenuation_color;\n    _6038 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5980;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6019 = param_6;\n    _6021 = param_7;\n    float3 result;\n    if (_429_fa_emissive.w > 0.5f)\n    {\n        result = _6019;\n    }\n    else\n    {\n        float3 _5601 = _6021;\n        float3 _5602 = normalize(_5601);\n        _6021 = _5602;\n        float3 param_8 = _5602;\n        SurfaceInput _6009 = { fa_world_pos, _5980, fa_world_tangent, fa_uv, fa_vertex_color, _5554, gl_FrontFacing };\n        SurfaceInput param_9 = _6009;\n        Surface _6120 = { _6019, _6020, _6021, _6022, _6023, _6024, _6025, _6026, _6027, _6028, _6029, _6030, _6031, _6032, _6033, _6034, _6035, _6036, _6037, _6038 };\n        Surface param_10 = _6120;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _5621 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5621; ln++)\n        {\n            int param_12 = ln;\n            int _5634 = fa_cl_light(param_12);\n            int param_13 = _5634;\n            if (fa_baked_keep(param_13) <= 0.0f)\n            {\n                continue;\n            }\n            int param_14 = _5634;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _5980;\n            LightSample _5650 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _6017 = { fa_world_pos, _5980, fa_world_tangent, fa_uv, fa_vertex_color, _5554, gl_FrontFacing };\n            SurfaceInput param_17 = _6017;\n            Surface _6141 = { _6019, _6020, _6021, _6022, _6023, _6024, _6025, _6026, _6027, _6028, _6029, _6030, _6031, _6032, _6033, _6034, _6035, _6036, _6037, _6038 };\n            Surface param_18 = _6141;\n            LightSample param_19 = _5650;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _5665 = result;\n    float3 _5666 = _5665 + _6025;\n    result = _5666;\n    float3 param_20 = _5666;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _5675 = _429_fa_fog.w > 0.0f;\n    bool _5682;\n    if (!_5675)\n    {\n        _5682 = _429_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5682 = _5675;\n    }\n    if (_5682)\n    {\n        float3 _5691 = fa_world_pos - _429_fa_camera_pos.xyz;\n        float _5697 = dot(_5691, _429_fa_fog_c.xyz);\n        bool _5701 = _429_fa_fog_c.w > 0.5f;\n        float _5702;\n        if (_5701)\n        {\n            _5702 = _5697;\n        }\n        else\n        {\n            _5702 = length(_5691);\n        }\n        float _5714 = _5702 - _429_fa_fog_b.x;\n        if (_5714 > 0.0f)\n        {\n            float _5723 = _429_fa_fog.w * _5714;\n            float tau = _5723 * _5723;\n            if (_429_fa_fog_b.y > 0.0f)\n            {\n                float _5739;\n                if (_5701)\n                {\n                    _5739 = fa_world_pos.y - (_429_fa_fog_c.y * _5697);\n                }\n                else\n                {\n                    _5739 = _429_fa_camera_pos.y;\n                }\n                float _5760 = lerp(_5739, fa_world_pos.y, clamp(_429_fa_fog_b.x / _5702, 0.0f, 1.0f));\n                float _5764 = fa_world_pos.y - _5760;\n                float _5769 = _5760 - _429_fa_fog_b.z;\n                float _5774 = fa_world_pos.y - _429_fa_fog_b.z;\n                bool _5777 = _5769 <= 0.0f;\n                bool _5778 = !_5777;\n                bool _5784;\n                if (_5778)\n                {\n                    _5784 = _429_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5784 = _5777;\n                }\n                float _5785;\n                if (_5784)\n                {\n                    _5785 = _429_fa_fog_b.y;\n                }\n                else\n                {\n                    _5785 = _429_fa_fog_b.y * exp(-min(_429_fa_fog_b.w * _5769, 80.0f));\n                }\n                bool _5812;\n                if (_5778)\n                {\n                    _5812 = _429_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5812 = _5777;\n                }\n                float _5813;\n                if (_5812)\n                {\n                    _5813 = _429_fa_fog_b.y * _5769;\n                }\n                else\n                {\n                    _5813 = (_429_fa_fog_b.y * (1.0f - exp(-min(_429_fa_fog_b.w * _5769, 80.0f)))) / _429_fa_fog_b.w;\n                }\n                bool _5838 = _5774 <= 0.0f;\n                bool _5845;\n                if (!_5838)\n                {\n                    _5845 = _429_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5845 = _5838;\n                }\n                float _5846;\n                if (_5845)\n                {\n                    _5846 = _429_fa_fog_b.y * _5774;\n                }\n                else\n                {\n                    _5846 = (_429_fa_fog_b.y * (1.0f - exp(-min(_429_fa_fog_b.w * _5774, 80.0f)))) / _429_fa_fog_b.w;\n                }\n                float _5873;\n                if (abs(_5764) < 0.001000000047497451305389404296875f)\n                {\n                    _5873 = _5785;\n                }\n                else\n                {\n                    _5873 = (_5846 - _5813) / _5764;\n                }\n                tau += (_5714 * max(_5873, 0.0f));\n            }\n            result = lerp(result, _429_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _6020);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_429",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2081",
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
