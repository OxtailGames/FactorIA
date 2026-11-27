{
  "format": "factoria.shader/1",
  "engine": "0.39.0",
  "template": "4694fb4be9bed2a7c5475af904870ae4995eb283e1c27e15e0192dfe0c2b2256",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _260 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _260;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_267, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _439_fa_camera_pos : packoffset(c0);\n    float4 _439_fa_ambient : packoffset(c1);\n    float4 _439_fa_base_color : packoffset(c2);\n    float4 _439_fa_emissive : packoffset(c3);\n    float4 _439_fa_model_emissive : packoffset(c4);\n    float4 _439_fa_pbr : packoffset(c5);\n    float4 _439_fa_maps : packoffset(c6);\n    float4 _439_fa_fog : packoffset(c7);\n    float4 _439_fa_fog_b : packoffset(c8);\n    float4 _439_fa_fog_c : packoffset(c9);\n    float4 _439_fa_counts : packoffset(c10);\n    float4 _439_fa_env_sky : packoffset(c11);\n    float4 _439_fa_env_horizon : packoffset(c12);\n    float4 _439_fa_time : packoffset(c13);\n    float4 _439_fa_cl_vpx : packoffset(c14);\n    float4 _439_fa_cl_vpy : packoffset(c15);\n    float4 _439_fa_cl_vpw : packoffset(c16);\n    float4 _439_fa_cl_fwd : packoffset(c17);\n    float4 _439_fa_cl_grid : packoffset(c18);\n    float4 _439_fa_cl_info : packoffset(c19);\n    float4 _439_fa_layers_a : packoffset(c20);\n    float4 _439_fa_layers_b : packoffset(c21);\n    float4 _439_fa_layers_c : packoffset(c22);\n    float4 _439_fa_layers_d : packoffset(c23);\n    float4 _439_fa_ct_a : packoffset(c24);\n    float4 _439_fa_ct_b : packoffset(c25);\n    float4 _439_fa_ct_vpx : packoffset(c26);\n    float4 _439_fa_ct_vpy : packoffset(c27);\n    float4 _439_fa_ct_vpw : packoffset(c28);\n    float4 _439_fa_ct_fwd : packoffset(c29);\n    float4 _439_fa_tr_a : packoffset(c30);\n    float4 _439_fa_tr_b : packoffset(c31);\n    float4 _439_fa_probe_sh[9] : packoffset(c32);\n    float4 _439_fa_atlas : packoffset(c41);\n    float4 _439_fa_rpa_tile : packoffset(c42);\n    float4 _439_fa_rpa_pos : packoffset(c43);\n    float4 _439_fa_rpa_bx : packoffset(c44);\n    float4 _439_fa_rpa_by : packoffset(c45);\n    float4 _439_fa_rpa_bz : packoffset(c46);\n    float4 _439_fa_rpb_tile : packoffset(c47);\n    float4 _439_fa_rpb_pos : packoffset(c48);\n    float4 _439_fa_rpb_bx : packoffset(c49);\n    float4 _439_fa_rpb_by : packoffset(c50);\n    float4 _439_fa_rpb_bz : packoffset(c51);\n    float4 _439_fa_gi : packoffset(c52);\n    float4 _439_fa_gi_px : packoffset(c53);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2091_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2091_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2091_fa_shadow_info[4] : packoffset(c20);\n    float4 _2091_fa_shadow_split : packoffset(c24);\n    float4 _2091_fa_shadow_cfg : packoffset(c25);\n    float4 _2091_fa_shadow_bias : packoffset(c26);\n    float4 _2091_fa_shadow_eye : packoffset(c27);\n    float4 _2091_fa_shadow_fwd : packoffset(c28);\n    float4 _2091_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float fa_rt_slope;\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1367 = _439_fa_cl_info.x < 0.0f;\n    bool _1374;\n    if (!_1367)\n    {\n        _1374 = _439_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1374 = _1367;\n    }\n    bool _1382;\n    if (!_1374)\n    {\n        _1382 = _439_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1382 = _1374;\n    }\n    bool _1389;\n    if (!_1382)\n    {\n        _1389 = _439_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1389 = _1382;\n    }\n    bool _1396;\n    if (!_1389)\n    {\n        _1396 = _439_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1396 = _1389;\n    }\n    if (_1396)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1406 = float4(world_pos, 1.0f);\n    float _1412 = dot(_439_fa_cl_vpw, _1406);\n    if (!(_1412 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1434 = float2(dot(_439_fa_cl_vpx, _1406), dot(_439_fa_cl_vpy, _1406)) / _1412.xx;\n    int _1438 = int(_439_fa_cl_grid.x);\n    int _1442 = int(_439_fa_cl_grid.y);\n    int param = (int(_439_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_439_fa_cl_fwd.xyz, world_pos) + _439_fa_cl_fwd.w, _439_fa_cl_grid.w) / _439_fa_cl_grid.w) * _439_fa_cl_grid.z)), 0, int(_439_fa_cl_info.y) - 1) * _1442) + clamp(int(floor(((_1434.y * 0.5f) + 0.5f) * _439_fa_cl_grid.y)), 0, _1442 - 1)) * _1438)) + clamp(int(floor(((_1434.x * 0.5f) + 0.5f) * _439_fa_cl_grid.x)), 0, _1438 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1518 = fa_cluster_texel(param);\n    return int2(int(_1518.x), int(_1518.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    float _4328 = dot(_439_fa_ct_fwd.xyz, world_pos) + _439_fa_ct_fwd.w;\n    float _4331 = fwidth(_4328);\n    bool _4334 = _439_fa_ct_b.y > 0.5f;\n    bool _4341;\n    if (!_4334)\n    {\n        _4341 = _439_fa_ct_b.w > 0.5f;\n    }\n    else\n    {\n        _4341 = _4334;\n    }\n    if (_4341)\n    {\n        fa_rt_slope = min(1.5f * _4331, 0.100000001490116119384765625f * _4328);\n    }\n    fa_cl_ndir = int(_439_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4357 = fa_cluster_lookup(param);\n    fa_cl_slot = _4357.x;\n    fa_cl_local = _4357.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4567 = fa_linear_to_srgb(param);\n        c = _4567;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4575 = fa_srgb_to_linear(param_1);\n            c = _4575;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _322;\n    if (i.front_facing)\n    {\n        _322 = i.world_normal;\n    }\n    else\n    {\n        _322 = -i.world_normal;\n    }\n    float3 _346 = normalize(i.world_tangent.xyz - (_322 * dot(_322, i.world_tangent.xyz)));\n    float3 _373 = normalize(((_346 * m.x) + ((cross(_322, _346) * i.world_tangent.w) * m.y)) + (_322 * m.z));\n    float3 _376;\n    if (i.front_facing)\n    {\n        _376 = _373;\n    }\n    else\n    {\n        _376 = -_373;\n    }\n    return _376;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _439_fa_env_horizon.w);\n    float param = _439_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4607 = fa_tex_fix(param_2, param_3);\n    float4 _6515 = base_t;\n    _6515.x = _4607.x;\n    _6515.y = _4607.y;\n    _6515.z = _4607.z;\n    base_t = _6515;\n    float4 _4621 = (_6515 * _439_fa_base_color) * i.vertex_color;\n    float3 _6328 = i.world_normal;\n    if (_439_fa_maps.z > 0.5f)\n    {\n        float param_4 = _439_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _439_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4655 = fa_tex_fix(param_6, param_7);\n        float3 _4658 = (_4655 * 2.0f) - 1.0f.xxx;\n        float2 _4663 = _4658.xy * _439_fa_maps.x;\n        float3 _6523 = _4658;\n        _6523.x = _4663.x;\n        _6523.y = _4663.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6523;\n        _6328 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _439_fa_env_horizon.w);\n    float param_10 = _439_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4693 = fa_tex_fix(param_12, param_13);\n    float4 _6526 = mrt;\n    _6526.x = _4693.x;\n    _6526.y = _4693.y;\n    _6526.z = _4693.z;\n    mrt = _6526;\n    float4 _4723 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _439_fa_env_horizon.w);\n    float param_14 = _439_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4723.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4734 = fa_tex_fix(param_16, param_17);\n    float param_18 = _439_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _439_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4766 = fa_tex_fix(param_20, param_21);\n    float _6333 = _439_fa_layers_a.x;\n    float _6334 = _439_fa_layers_a.y;\n    float _6337 = _439_fa_layers_a.z;\n    float _6336 = _439_fa_layers_b.w;\n    float _6339 = _439_fa_layers_c.x;\n    if (_439_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_439_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6333 *= _4734.y;\n            _6334 *= _4734.z;\n            _6336 *= _4723.w;\n        }\n        if (_439_fa_layers_c.z > 1.5f)\n        {\n            _6337 *= mrt.x;\n            _6339 *= mrt.w;\n        }\n    }\n    Surface _6366 = { _4621.xyz, _4621.w, _6328, clamp(_439_fa_pbr.x * _4693.z, 0.0f, 1.0f), clamp(_439_fa_pbr.y * _4693.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_439_fa_maps.y * (_4734.x - 1.0f)), _439_fa_emissive.xyz + (_439_fa_model_emissive.xyz * _4766), _6333, _6334, _439_fa_layers_b.xyz, _6336, _6337, _439_fa_layers_a.w, _6339, _439_fa_layers_c.y, _439_fa_layers_d.xyz, _439_fa_tr_a.x, _439_fa_tr_a.y, _439_fa_tr_b.xyz, _439_fa_tr_a.z };\n    return _6366;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1598 = rect.zw - rect.xy;\n    float2 _1602 = _1598 * atlas;\n    float2 _1606 = ddx * _1602;\n    float2 _1610 = ddy * _1602;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1598), clamp(0.5f * log2(max(max(dot(_1606, _1606), dot(_1610, _1610)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1643 = _439_fa_counts.y < 0.5f;\n    bool _1650;\n    if (!_1643)\n    {\n        _1650 = _439_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1650 = _1643;\n    }\n    if (_1650)\n    {\n        return;\n    }\n    float3 _1656 = ddx(world_pos);\n    float3 _1659 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1663 = fa_cluster_texel(param);\n    int _1667 = int(_1663.w);\n    if (_1667 < 1)\n    {\n        return;\n    }\n    int _1677 = int(_439_fa_counts.y + 0.5f);\n    int param_1 = _1677;\n    float4 _1681 = fa_light_texel(param_1);\n    float2 _1684 = _1681.yz;\n    int _1688 = int(_1681.w);\n    int param_2 = _1677 + 1;\n    float4 _1693 = fa_light_texel(param_2);\n    float _1694 = _1693.x;\n    int _1700 = int(_439_fa_counts.w + 0.5f) - 1;\n    int _1704 = int(_1663.z);\n    float3 _1969;\n    for (int k = 0; k < _1667; k++)\n    {\n        int _1717 = _1704 + k;\n        int param_3 = _1688 + (_1717 >> 2);\n        int _1734 = (_1677 + 2) + (int(fa_light_texel(param_3)[_1717 & 3]) * 7);\n        int param_4 = _1734 + 6;\n        float4 _1739 = fa_light_texel(param_4);\n        if (((int(_1739.w + 0.5f) >> _1700) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1734;\n        float4 _1754 = fa_light_texel(param_5);\n        int param_6 = _1734 + 1;\n        float4 _1759 = fa_light_texel(param_6);\n        int param_7 = _1734 + 2;\n        float4 _1764 = fa_light_texel(param_7);\n        float3 _1767 = _1754.xyz;\n        float _1772 = dot(_1767, world_pos) + _1754.w;\n        float3 _1774 = _1759.xyz;\n        float _1779 = dot(_1774, world_pos) + _1759.w;\n        float3 _1781 = _1764.xyz;\n        float _1786 = dot(_1781, world_pos) + _1764.w;\n        bool _1791 = abs(_1772) > 0.5f;\n        bool _1799;\n        if (!_1791)\n        {\n            _1799 = abs(_1779) > 0.5f;\n        }\n        else\n        {\n            _1799 = _1791;\n        }\n        bool _1807;\n        if (!_1799)\n        {\n            _1807 = abs(_1786) > 0.5f;\n        }\n        else\n        {\n            _1807 = _1799;\n        }\n        if (_1807)\n        {\n            continue;\n        }\n        float _1822 = clamp(dot(geo_normal, normalize(_1781)) * _1739.z, 0.0f, 1.0f);\n        if (_1822 <= 0.0f)\n        {\n            continue;\n        }\n        float _1842 = (clamp((0.5f - abs(_1786)) * 10.0f, 0.0f, 1.0f) * _1822) * _1739.x;\n        float2 _1850 = float2(_1772 + 0.5f, 0.5f - _1779);\n        float2 _1860 = float2(dot(_1767, _1656), dot(_1774, _1656));\n        float2 _1870 = float2(dot(_1767, _1659), dot(_1774, _1659));\n        int param_8 = _1734 + 5;\n        float4 _1875 = fa_light_texel(param_8);\n        int param_9 = _1734 + 3;\n        float4 _1880 = fa_light_texel(param_9);\n        int param_10 = _1734 + 4;\n        float4 _1885 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1875.xyz;\n        bool _1895 = _1880.z > _1880.x;\n        if (_1895)\n        {\n            float4 param_11 = _1880;\n            float2 param_12 = _1850;\n            float2 param_13 = _1684;\n            float2 param_14 = _1860;\n            float2 param_15 = _1870;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1694 > 0.5f) && (_1694 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1921 = fa_dc_to_linear(param_16);\n                float4 _6416 = tx;\n                _6416.x = _1921.x;\n                _6416.y = _1921.y;\n                _6416.z = _1921.z;\n                tx = _6416;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1842 * tex_a) * _1875.w, 0.0f, 1.0f).xxx);\n        if (_1885.z > _1885.x)\n        {\n            float4 param_17 = _1885;\n            float2 param_18 = _1850;\n            float2 param_19 = _1684;\n            float2 param_20 = _1860;\n            float2 param_21 = _1870;\n            float4 _1965 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1694 > 1.5f)\n            {\n                float3 param_22 = _1965.xyz;\n                float3 _1975 = fa_dc_to_srgb(param_22);\n                _1969 = _1975;\n            }\n            else\n            {\n                _1969 = _1965.xyz;\n            }\n            float3 _1984 = (_1969 * 2.0f) - 1.0f.xxx;\n            float2 _1989 = _1984.xy * _1739.y;\n            float3 _2011 = (normalize(_1767) * _1989.x) + (normalize(_1774) * _1989.y);\n            float3 _2014 = normalize(normal);\n            normal = normalize(lerp(_2014, normalize((_2014 * max(_1984.z, 0.0500000007450580596923828125f)) + (_2011 - (_2014 * dot(_2014, _2011)))), clamp(_1842 * (_1895 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3850_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3850_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_439_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3791 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3791;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3900 = (1.0f - _439_fa_rpa_tile.w) - _439_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3906 = _439_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3900 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3906)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _439_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3900;\n            }\n        }\n        else\n        {\n            amb = _439_fa_ambient.xyz * _3900;\n        }\n    }\n    bool _3958 = _439_fa_rpa_tile.w > 0.0f;\n    if (_3958)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _439_fa_rpa_tile.xy;\n            float param_4 = _439_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _439_fa_rpa_tile.w);\n        }\n    }\n    bool _3989 = _439_fa_rpb_tile.w > 0.0f;\n    if (_3989)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _439_fa_rpb_tile.xy;\n            float param_7 = _439_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _439_fa_rpb_tile.w);\n        }\n    }\n    if ((_3906 || _3958) || _3989)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3811 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3814 = _3811.x;\n    float _3816 = _3811.z;\n    float2 e = float2(_3814, _3816);\n    if (_3811.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3816)) * ((_3814 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3814)) * ((_3816 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _4880 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _4885 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _4890 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _4895 = fa_light_texel(param_3);\n    bool _4898 = _4895.z < 0.5f;\n    bool _4906;\n    if (!_4898)\n    {\n        _4906 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _4906 = _4898;\n    }\n    if (_4906)\n    {\n        return 0.0f.xxx;\n    }\n    float _4913 = max(_4880.w, 9.9999997473787516355514526367188e-05f);\n    float3 _4916 = _4885.xyz;\n    float3 _4920 = _4880.xyz;\n    float3 _4924 = (fa_world_pos - _4920) / _4913.xxx;\n    float3 _4933 = min(_4924 + 0.5f.xxx, (_4916 - 0.5f.xxx) - _4924);\n    float _4942 = min(_4933.x, min(_4933.y, _4933.z));\n    if (!(_4942 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4957 = _4916 - 1.0f.xxx;\n    float3 _4958 = clamp(_4924, 0.0f.xxx, _4957);\n    float3 _4966 = min(floor(_4958), max(_4916 - 2.0f.xxx, 0.0f.xxx));\n    float3 _4970 = _4958 - _4966;\n    float3 _4982 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _4913));\n    int _4987 = int(_4890.y + 0.5f);\n    float _4992 = 0.3257350027561187744140625f * n.y;\n    float _4996 = 0.3257350027561187744140625f * n.z;\n    float _5000 = 0.3257350027561187744140625f * n.x;\n    float _5007 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _5014 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _5023 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _5030 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _5043 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _5050 = 8 + int(_4895.w);\n    float _5077;\n    float _5090;\n    float _5104;\n    for (int k = 0; k < _5050; k++)\n    {\n        float _5063 = float(k & 1);\n        float _5067 = float((k >> 1) & 1);\n        float _5071 = float((k >> 2) & 1);\n        if (_5063 > 0.5f)\n        {\n            _5077 = _4970.x;\n        }\n        else\n        {\n            _5077 = 1.0f - _4970.x;\n        }\n        if (_5067 > 0.5f)\n        {\n            _5090 = _4970.y;\n        }\n        else\n        {\n            _5090 = 1.0f - _4970.y;\n        }\n        if (_5071 > 0.5f)\n        {\n            _5104 = _4970.z;\n        }\n        else\n        {\n            _5104 = 1.0f - _4970.z;\n        }\n        float _5114 = (_5077 * _5090) * _5104;\n        if (!(_5114 > 0.0f))\n        {\n            continue;\n        }\n        float3 _5127 = min(_4966 + float3(_5063, _5067, _5071), _4957);\n        int _5147 = int(((_4890.x + _5127.x) + (_4885.x * (_5127.y + (_4885.y * _5127.z)))) + 0.5f);\n        float2 _5162 = float2(float(_5147 % _4987) * 10.0f, 1024.0f + (float(_5147 / _4987) * 11.0f));\n        float2 param_4 = _5162 + float2(9.5f, 10.5f);\n        float4 _5170 = fa_gi_fetch(param_4);\n        bool _5173 = _5170.y < 0.5f;\n        bool _5182;\n        if (!_5173)\n        {\n            _5182 = _5170.x > _4895.y;\n        }\n        else\n        {\n            _5182 = _5173;\n        }\n        if (_5182)\n        {\n            continue;\n        }\n        float3 _5194 = _4982 - (_4920 + (_5127 * _4913));\n        float _5197 = length(_5194);\n        float3 _5203 = _5194 / max(_5197, 9.9999997473787516355514526367188e-05f).xxx;\n        float _5213 = max(9.9999997473787516355514526367188e-05f, (dot(-_5203, n) + 1.0f) * 0.5f);\n        float w = _5114 * (_5213 * _5213);\n        float3 param_5 = _5203;\n        float2 param_6 = (_5162 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _5233 = fa_gi_fetch(param_6);\n        float _5240 = _5197 / max(_4890.z, 9.9999997473787516355514526367188e-05f);\n        float _5243 = _5233.x;\n        if (_5240 > _5243)\n        {\n            float _5256 = max(_5233.y - (_5243 * _5243), 0.0f);\n            float _5261 = _5240 - _5243;\n            float _5270 = _5256 / max(_5256 + (_5261 * _5261), 9.9999999600419720025001879548654e-13f);\n            w *= ((_5270 * _5270) * _5270);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _5162 + float2(0.5f, 10.5f);\n        float2 param_8 = _5162 + float2(1.5f, 10.5f);\n        float2 param_9 = _5162 + float2(2.5f, 10.5f);\n        float2 param_10 = _5162 + float2(3.5f, 10.5f);\n        float2 param_11 = _5162 + float2(4.5f, 10.5f);\n        float2 param_12 = _5162 + float2(5.5f, 10.5f);\n        float2 param_13 = _5162 + float2(6.5f, 10.5f);\n        float2 param_14 = _5162 + float2(7.5f, 10.5f);\n        float2 param_15 = _5162 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _4992)) + (fa_gi_fetch(param_9).xyz * _4996)) + (fa_gi_fetch(param_10).xyz * _5000)) + (fa_gi_fetch(param_11).xyz * _5007)) + (fa_gi_fetch(param_12).xyz * _5014)) + (fa_gi_fetch(param_13).xyz * _5023)) + (fa_gi_fetch(param_14).xyz * _5030)) + (fa_gi_fetch(param_15).xyz * _5043)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_4942 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _5398;\n    if (_439_fa_gi.z > 0.5f)\n    {\n        _5398 = _4895.x;\n    }\n    else\n    {\n        _5398 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_4890.w * _5398);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _5422 = normalize(_439_fa_camera_pos.xyz - fa_world_pos);\n    int _5427 = int(_439_fa_gi.x + 0.5f);\n    int _5432 = int(_439_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _5432) && (k < 8); k++)\n    {\n        int param = _5427 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _5422;\n        float3 _5457 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5462 = param_3 * left;\n        acc += (_5457 * _5462);\n        left -= _5462;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_439_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _5491 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5491;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_439_fa_gi_px.x > 0.5f)\n    {\n        float4 _5533 = float4(fa_world_pos, 1.0f);\n        float2 _5552 = float2(dot(_439_fa_ct_vpx, _5533), dot(_439_fa_ct_vpy, _5533)) / max(dot(_439_fa_ct_vpw, _5533), 9.9999997473787516355514526367188e-05f).xx;\n        float _5561;\n        if (_439_fa_ct_a.y > 0.5f)\n        {\n            _5561 = (_5552.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5561 = 0.5f - (_5552.y * 0.5f);\n        }\n        return fa_lightmap.Load(int3(clamp(int2(float2((_5552.x * 0.5f) + 0.5f, _5561) * _439_fa_ct_a.zw), int2(0, 0), int2(_439_fa_ct_a.zw) - int2(1, 1)), 0)).xyz;\n    }\n    if (_439_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _439_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_439_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return float3(0.0f, ambientColor.y, 0.0f);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_439_fa_cl_info.x) + int(_439_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_439_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4298;\n    if (fa_lm.z > 0.5f)\n    {\n        _4298 = 0.0f;\n    }\n    else\n    {\n        _4298 = 1.0f - clamp(_439_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4309 = _4298 < 1.0f;\n    bool _4315;\n    if (_4309)\n    {\n        int param = li;\n        _4315 = fa_light_baked(param);\n    }\n    else\n    {\n        _4315 = _4309;\n    }\n    return _4315 ? _4298 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _617 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _630 = (c - (ru * hx)) - p;\n        float3 _636 = ru * (2.0f * hx);\n        float _642 = max(dot(_636, _636), 9.9999999392252902907785028219223e-09f);\n        float _646 = dot(_630, _636);\n        float t = clamp((-_646) / _642, 0.0f, 1.0f);\n        if (_617)\n        {\n            float _661 = dot(r, _636);\n            float _667 = _642 - (_661 * _661);\n            if (abs(_667) > (9.9999997473787516355514526367188e-06f * _642))\n            {\n                t = clamp(((dot(r, _630) * _661) - _646) / _667, 0.0f, 1.0f);\n            }\n        }\n        return (p + _630) + (_636 * t);\n    }\n    float3 q = p;\n    float _699 = dot(r, axis);\n    bool _707;\n    if (_617)\n    {\n        _707 = abs(_699) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _707 = _617;\n    }\n    if (_707)\n    {\n        float _717 = dot(c - p, axis) / _699;\n        if (_717 > 0.0f)\n        {\n            q = p + (r * _717);\n        }\n    }\n    float3 _730 = q - c;\n    float2 xy = float2(dot(_730, ru), dot(_730, uu));\n    if (shape > 0.5f)\n    {\n        float _745 = length(xy);\n        if (_745 > hx)\n        {\n            xy *= (hx / _745);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _498_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _498_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _537 = dot(d, right);\n    float _541 = dot(d, up);\n    float _552;\n    if (((_537 * _537) + (_541 * _541)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _552 = atan2(_541, _537) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _552 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_552 - floor(_552)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _388 = abs(d);\n    float _390 = _388.x;\n    float _392 = _388.y;\n    bool _393 = _390 >= _392;\n    bool _401;\n    if (_393)\n    {\n        _401 = _390 >= _388.z;\n    }\n    else\n    {\n        _401 = _393;\n    }\n    int _402;\n    if (_401)\n    {\n        _402 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _416;\n        if (_392 >= _388.z)\n        {\n            _416 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _416 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _402 = _416;\n    }\n    return _402;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _783 = fa_light_base(param);\n    bool _787 = _439_fa_ambient.w > 4.5f;\n    int param_1 = _783;\n    float4 _791 = fa_light_texel(param_1);\n    int param_2 = _783 + 1;\n    float4 _796 = fa_light_texel(param_2);\n    float _799 = _796.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _811 = _787 && (_799 > 2.5f);\n    fa_light_is_area = _811;\n    bool _813 = _799 < 0.5f;\n    float3 l;\n    if (_813)\n    {\n        l = normalize(_791.xyz);\n        if (_787)\n        {\n            int param_3 = _783 + 6;\n            float4 _827 = fa_light_texel(param_3);\n            if (_827.z > 0.5f)\n            {\n                int param_4 = _783 + 4;\n                float4 _837 = fa_light_texel(param_4);\n                int param_5 = _783 + 5;\n                float4 _842 = fa_light_texel(param_5);\n                float2 param_6 = _827.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _837.xyz) * _837.w, (-dot(world_pos, _842.xyz)) * _842.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _872 = _791.xyz;\n        float3 _874 = _872 - world_pos;\n        float3 to_light = _874;\n        float _877 = length(_874);\n        float reach = _877;\n        bool front = true;\n        if (_811)\n        {\n            int param_8 = _783 + 7;\n            reach = max(_877 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _783 + 4;\n            float4 _901 = fa_light_texel(param_9);\n            int param_10 = _783 + 5;\n            float4 _906 = fa_light_texel(param_10);\n            int param_11 = _783 + 6;\n            float4 _911 = fa_light_texel(param_11);\n            float _912 = _911.w;\n            int param_12 = _783 + 2;\n            float3 _919 = normalize(fa_light_texel(param_12).xyz);\n            bool _921 = _912 > 1.5f;\n            bool _929;\n            if (!_921)\n            {\n                _929 = dot(_919, to_light) < 0.0f;\n            }\n            else\n            {\n                _929 = _921;\n            }\n            front = _929;\n            float3 r = 0.0f.xxx;\n            float3 _938 = _439_fa_camera_pos.xyz - world_pos;\n            bool _942 = dot(n, n) > 0.5f;\n            bool _950;\n            if (_942)\n            {\n                _950 = dot(_938, _938) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _950 = _942;\n            }\n            if (_950)\n            {\n                r = reflect(-normalize(_938), normalize(n));\n            }\n            float3 param_13 = _872;\n            float3 param_14 = _919;\n            float3 param_15 = _901.xyz;\n            float3 param_16 = _906.xyz;\n            float param_17 = _901.w;\n            float param_18 = _906.w;\n            float param_19 = _912;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _986 = length(to_light);\n        dist = _986;\n        l = to_light / max(_986, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1000 = reach / max(_791.w, 0.001000000047497451305389404296875f);\n        float _1006 = clamp(1.0f - (_1000 * _1000), 0.0f, 1.0f);\n        float _1008;\n        if (front)\n        {\n            _1008 = _1006 * _1006;\n        }\n        else\n        {\n            _1008 = 0.0f;\n        }\n        atten = _1008;\n        bool _1019 = _799 < 2.5f;\n        if ((_799 > 1.5f) && _1019)\n        {\n            int param_22 = _783 + 2;\n            float4 _1027 = fa_light_texel(param_22);\n            float _1037 = _1027.w;\n            int param_23 = _783 + 3;\n            float4 _1042 = fa_light_texel(param_23);\n            float _1043 = _1042.x;\n            float cos_inner = _1043;\n            if (_1043 > 1.5f)\n            {\n                cos_inner = lerp(_1037, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1037, cos_inner, dot(-l, normalize(_1027.xyz)));\n        }\n        if (_787 && (_799 < 1.5f))\n        {\n            int param_24 = _783 + 6;\n            float4 _1067 = fa_light_texel(param_24);\n            if (_1067.z > 0.5f)\n            {\n                float3 _1075 = -to_light;\n                int param_25 = _783 + 4;\n                int param_26 = _783 + 5;\n                float3 _1089 = fa_light_texel(param_25).xyz;\n                float3 _1093 = fa_light_texel(param_26).xyz;\n                float3 _1102 = float3(dot(_1075, _1089), dot(_1075, _1093), dot(_1075, cross(_1089, _1093)));\n                float3 param_27 = _1102;\n                int _1106 = fa_cube_face(param_27);\n                int param_28 = _1106;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1133 = float2(dot(_1102, cross(param_29, param_30)), dot(_1102, param_30)) / max(dot(_1102, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1137 = _1106 / 3;\n                float2 param_31 = _1067.xy + (float2(float(_1106 - (_1137 * 3)), float(_1137)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1133.x), 0.5f - (0.5f * _1133.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _783 + 7;\n            float4 _1167 = fa_light_texel(param_33);\n            if (_1167.z > 0.5f)\n            {\n                int param_34 = _783 + 2;\n                int param_35 = _783 + 4;\n                int param_36 = _783 + 5;\n                float2 param_37 = _1167.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_787 && _1019)\n            {\n                int param_42 = _783 + 6;\n                float4 _1214 = fa_light_texel(param_42);\n                int param_43 = _783 + 7;\n                float4 _1219 = fa_light_texel(param_43);\n                bool _1222 = _1214.z > 0.5f;\n                bool _1229;\n                if (!_1222)\n                {\n                    _1229 = _1219.z > 0.5f;\n                }\n                else\n                {\n                    _1229 = _1222;\n                }\n                if (_1229)\n                {\n                    int param_44 = _783 + 2;\n                    float4 _1236 = fa_light_texel(param_44);\n                    float3 _1240 = normalize(_1236.xyz);\n                    int param_45 = _783 + 4;\n                    float4 _1245 = fa_light_texel(param_45);\n                    int param_46 = _783 + 5;\n                    float4 _1250 = fa_light_texel(param_46);\n                    if (_1222)\n                    {\n                        float3 _1258 = -to_light;\n                        float _1265 = _1236.w;\n                        float _1281 = 0.5f / max(dot(_1258, _1240) * (sqrt(max(1.0f - (_1265 * _1265), 0.0f)) / max(_1265, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1214.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1258, _1245.xyz) * _1281), 0.5f - (dot(_1258, _1250.xyz) * _1281));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1219.z > 0.5f)\n                    {\n                        float2 param_49 = _1219.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1240;\n                        float3 param_52 = _1245.xyz;\n                        float3 param_53 = _1250.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6282 = _796.xyz * atten;\n    if (_787)\n    {\n        _6282 *= fa_light_tint;\n    }\n    int _1349;\n    if (_813)\n    {\n        _1349 = 0;\n    }\n    else\n    {\n        _1349 = ((_799 > 1.5f) && (_799 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _6293 = { l, _6282, atten, 1.0f, dist, _1349 };\n    return _6293;\n}\n\nfloat fa_rt_local_tap(int2 p, int2 size, float d, float tol, float div, inout float best)\n{\n    float4 _3310 = fa_screen_tex.Load(int3(clamp(p, int2(0, 0), size - int2(1, 1)), 0));\n    bool _3313 = _3310.w > 0.5f;\n    bool _3323;\n    if (_3313)\n    {\n        _3323 = abs(d - _3310.x) <= tol;\n    }\n    else\n    {\n        _3323 = _3313;\n    }\n    if (_3323)\n    {\n        best = min(best, mod(floor(_3310.z / div), 256.0f) * 0.0039215688593685626983642578125f);\n    }\n    return best;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2138 = fa_shadow_depth(param, param_1);\n    float _2142;\n    if (conv.x < 0.5f)\n    {\n        _2142 = _2138;\n    }\n    else\n    {\n        _2142 = (conv.y * conv.z) / (conv.z - (_2138 * (conv.z - conv.y)));\n    }\n    return _2142;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2188 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2194 = float2(cos(_2188), sin(_2188));\n    float2 dir = _2194;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2203;\n        if (k < 0.0f)\n        {\n            _2203 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2203 = k;\n        }\n        float _2222 = clamp((_2203 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2241 = sqrt((float(i) + 0.5f) * 0.0625f) * _2222;\n            float2 param_3 = uv + (dir * (_2091_fa_shadow_bias.zw * _2241));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2255 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2255 < (zr - (_2241 * plane)))\n            {\n                sum += _2255;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2283 = sum / cnt;\n        float _2293;\n        if (k < 0.0f)\n        {\n            _2293 = (-k) / max(_2283, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2293 = k;\n        }\n        radius = clamp(((max(zr - _2283, 0.0f) * unit) * _2293) / texel_m, 1.5f, 16.0f);\n        dir = _2194;\n    }\n    float lit = 0.0f;\n    int _2319 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2319; i_1++)\n    {\n        float _2338 = sqrt((float(i_1) + 0.5f) / float(_2319)) * radius;\n        float2 param_7 = uv + (dir * (_2091_fa_shadow_bias.zw * _2338));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2338 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2319);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2543 = _439_fa_pbr.z < 0.5f;\n    bool _2550;\n    if (!_2543)\n    {\n        _2550 = _2091_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2550 = _2543;\n    }\n    if (_2550)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2091_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2563 = fa_light_texel(param);\n    float _2564 = _2563.x;\n    if (_2564 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2573 = int(_2564 + 0.5f);\n    int param_1 = _2573;\n    float4 _2577 = fa_light_texel(param_1);\n    int param_2 = _2573 + 1;\n    float4 _2582 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2585 = _2577.y;\n    if (_2585 > 0.0f)\n    {\n        float _2602 = 1.0f - smoothstep(0.75f * _2585, _2585, length(world - _2091_fa_shadow_eye.xyz));\n        fade = _2602;\n        if (_2602 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2577.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2626 = (_2573 + 2) + (face * 6);\n    int param_4 = _2626;\n    int param_5 = _2626 + 1;\n    int param_6 = _2626 + 3;\n    float4 _2640 = fa_light_texel(param_6);\n    int param_7 = _2626 + 4;\n    float4 _2645 = fa_light_texel(param_7);\n    int param_8 = _2626 + 5;\n    float4 _2650 = fa_light_texel(param_8);\n    float _2662 = _2650.x * max(dot(_2640, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2667 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2690 = clamp(dot(n, _2640.xyz), -1.0f, 1.0f);\n    float _2709 = min(sqrt(1.0f - (_2690 * _2690)) / max(abs(dot(n, world - lpos)) / max(dot(_2640, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2712 = _2582.y;\n    float _2714;\n    if (_2712 > 0.0f)\n    {\n        _2714 = _2712;\n    }\n    else\n    {\n        _2714 = 1.5f * _2662;\n    }\n    float4 _2734 = float4(world + (n * (_2714 * sqrt(1.0f - (_2667 * _2667)))), 1.0f);\n    float _2738 = dot(_2640, _2734);\n    float _2741 = _2650.y;\n    if (_2738 < _2741)\n    {\n        return 1.0f;\n    }\n    float2 _2756 = float2(dot(fa_light_texel(param_4), _2734), dot(fa_light_texel(param_5), _2734)) / _2738.xx;\n    float _2758 = _2756.x;\n    bool _2761 = _2758 < _2645.x;\n    bool _2770;\n    if (!_2761)\n    {\n        _2770 = _2758 > _2645.z;\n    }\n    else\n    {\n        _2770 = _2761;\n    }\n    bool _2779;\n    if (!_2770)\n    {\n        _2779 = _2756.y < _2645.y;\n    }\n    else\n    {\n        _2779 = _2770;\n    }\n    bool _2788;\n    if (!_2779)\n    {\n        _2788 = _2756.y > _2645.w;\n    }\n    else\n    {\n        _2788 = _2779;\n    }\n    if (_2788)\n    {\n        return 1.0f;\n    }\n    float _2794 = _2582.x;\n    float _2796;\n    if (_2794 > 0.0f)\n    {\n        _2796 = _2794;\n    }\n    else\n    {\n        _2796 = 1.5f * _2662;\n    }\n    float2 param_9 = _2756;\n    float4 param_10 = _2645;\n    float param_11 = _2738 - (_2796 * (1.0f + (0.5f * _2709)));\n    float param_12 = _2662;\n    float param_13 = 1.0f;\n    float param_14 = _2650.z * 0.25f;\n    float param_15 = (_2662 * min(_2709, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2741, _2650.z);\n    int param_17 = int(_2577.z + 0.5f);\n    float param_18 = _2577.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _3341 = _439_fa_ct_b.w > 0.5f;\n    bool _3347;\n    if (_3341)\n    {\n        _3347 = _439_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3347 = _3341;\n    }\n    bool _3353;\n    if (_3347)\n    {\n        _3353 = _2091_fa_shadow_lcfg.x > 0.5f;\n    }\n    else\n    {\n        _3353 = _3347;\n    }\n    if (_3353)\n    {\n        int param = (int(_2091_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n        float4 _3365 = fa_light_texel(param);\n        float _3366 = _3365.z;\n        if (_3366 > 0.5f)\n        {\n            float _3379 = dot(_439_fa_ct_fwd.xyz, world) + _439_fa_ct_fwd.w;\n            float _3385 = ((0.00200000009499490261077880859375f * _3379) + 0.00999999977648258209228515625f) + fa_rt_slope;\n            float4 _3391 = float4(world, 1.0f);\n            float _3396 = dot(_439_fa_ct_vpw, _3391);\n            if (_3396 > 9.9999997473787516355514526367188e-05f)\n            {\n                float2 _3413 = float2(dot(_439_fa_ct_vpx, _3391), dot(_439_fa_ct_vpy, _3391)) / _3396.xx;\n                float _3418 = (_3413.x * 0.5f) + 0.5f;\n                float _3422;\n                if (_439_fa_ct_a.y > 0.5f)\n                {\n                    _3422 = (_3413.y * 0.5f) + 0.5f;\n                }\n                else\n                {\n                    _3422 = 0.5f - (_3413.y * 0.5f);\n                }\n                bool _3438 = _3418 >= 0.0f;\n                bool _3444;\n                if (_3438)\n                {\n                    _3444 = _3418 < 1.0f;\n                }\n                else\n                {\n                    _3444 = _3438;\n                }\n                bool _3450;\n                if (_3444)\n                {\n                    _3450 = _3422 >= 0.0f;\n                }\n                else\n                {\n                    _3450 = _3444;\n                }\n                bool _3456;\n                if (_3450)\n                {\n                    _3456 = _3422 < 1.0f;\n                }\n                else\n                {\n                    _3456 = _3450;\n                }\n                if (_3456)\n                {\n                    int2 _3463 = int2(_439_fa_ct_a.zw);\n                    int2 _3474 = clamp(int2(float2(_3418, _3422) * _439_fa_ct_a.zw), int2(0, 0), _3463 - int2(1, 1));\n                    float _3478;\n                    if (_3366 < 1.5f)\n                    {\n                        _3478 = 1.0f;\n                    }\n                    else\n                    {\n                        _3478 = (_3366 < 2.5f) ? 256.0f : 65536.0f;\n                    }\n                    float best = 2.0f;\n                    float4 _3494 = fa_screen_tex.Load(int3(_3474, 0));\n                    bool _3497 = _3494.w > 0.5f;\n                    bool _3507;\n                    if (_3497)\n                    {\n                        _3507 = abs(_3379 - _3494.x) <= _3385;\n                    }\n                    else\n                    {\n                        _3507 = _3497;\n                    }\n                    if (_3507)\n                    {\n                        best = mod(floor(_3494.z / _3478), 256.0f) * 0.0039215688593685626983642578125f;\n                    }\n                    else\n                    {\n                        int2 param_1 = _3474 + int2(-1, -1);\n                        int2 param_2 = _3463;\n                        float param_3 = _3379;\n                        float param_4 = _3385;\n                        float param_5 = _3478;\n                        float param_6 = best;\n                        float _3533 = fa_rt_local_tap(param_1, param_2, param_3, param_4, param_5, param_6);\n                        best = _3533;\n                        int2 param_7 = _3474 + int2(0, -1);\n                        int2 param_8 = _3463;\n                        float param_9 = _3379;\n                        float param_10 = _3385;\n                        float param_11 = _3478;\n                        float param_12 = _3533;\n                        float _3548 = fa_rt_local_tap(param_7, param_8, param_9, param_10, param_11, param_12);\n                        best = _3548;\n                        int2 param_13 = _3474 + int2(1, -1);\n                        int2 param_14 = _3463;\n                        float param_15 = _3379;\n                        float param_16 = _3385;\n                        float param_17 = _3478;\n                        float param_18 = _3548;\n                        float _3563 = fa_rt_local_tap(param_13, param_14, param_15, param_16, param_17, param_18);\n                        best = _3563;\n                        int2 param_19 = _3474 + int2(-1, 0);\n                        int2 param_20 = _3463;\n                        float param_21 = _3379;\n                        float param_22 = _3385;\n                        float param_23 = _3478;\n                        float param_24 = _3563;\n                        float _3578 = fa_rt_local_tap(param_19, param_20, param_21, param_22, param_23, param_24);\n                        best = _3578;\n                        int2 param_25 = _3474 + int2(1, 0);\n                        int2 param_26 = _3463;\n                        float param_27 = _3379;\n                        float param_28 = _3385;\n                        float param_29 = _3478;\n                        float param_30 = _3578;\n                        float _3593 = fa_rt_local_tap(param_25, param_26, param_27, param_28, param_29, param_30);\n                        best = _3593;\n                        int2 param_31 = _3474 + int2(-1, 1);\n                        int2 param_32 = _3463;\n                        float param_33 = _3379;\n                        float param_34 = _3385;\n                        float param_35 = _3478;\n                        float param_36 = _3593;\n                        float _3608 = fa_rt_local_tap(param_31, param_32, param_33, param_34, param_35, param_36);\n                        best = _3608;\n                        int2 param_37 = _3474 + int2(0, 1);\n                        int2 param_38 = _3463;\n                        float param_39 = _3379;\n                        float param_40 = _3385;\n                        float param_41 = _3478;\n                        float param_42 = _3608;\n                        float _3623 = fa_rt_local_tap(param_37, param_38, param_39, param_40, param_41, param_42);\n                        best = _3623;\n                        int2 param_43 = _3474 + int2(1, 1);\n                        int2 param_44 = _3463;\n                        float param_45 = _3379;\n                        float param_46 = _3385;\n                        float param_47 = _3478;\n                        float param_48 = _3623;\n                        float _3638 = fa_rt_local_tap(param_43, param_44, param_45, param_46, param_47, param_48);\n                        best = _3638;\n                    }\n                    if (best <= 1.0f)\n                    {\n                        float _3646;\n                        if (_439_fa_ct_b.z > 0.5f)\n                        {\n                            int param_49 = li;\n                            float3 param_50 = lpos;\n                            float3 param_51 = world;\n                            float3 param_52 = n;\n                            float3 param_53 = l;\n                            _3646 = min(best, fa_shadow_local(param_49, param_50, param_51, param_52, param_53));\n                        }\n                        else\n                        {\n                            _3646 = best;\n                        }\n                        return _3646;\n                    }\n                }\n            }\n            float _3669;\n            if (_439_fa_ct_b.z > 0.5f)\n            {\n                int param_54 = li;\n                float3 param_55 = lpos;\n                float3 param_56 = world;\n                float3 param_57 = n;\n                float3 param_58 = l;\n                _3669 = fa_shadow_local(param_54, param_55, param_56, param_57, param_58);\n            }\n            else\n            {\n                _3669 = 1.0f;\n            }\n            return _3669;\n        }\n    }\n    int param_59 = li;\n    float3 param_60 = lpos;\n    float3 param_61 = world;\n    float3 param_62 = n;\n    float3 param_63 = l;\n    return fa_shadow_local(param_59, param_60, param_61, param_62, param_63);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2081;\n    if (i == 0)\n    {\n        _2081 = _2091_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2097;\n        if (i == 1)\n        {\n            _2097 = _2091_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2105;\n            if (i == 2)\n            {\n                _2105 = _2091_fa_shadow_split.z;\n            }\n            else\n            {\n                _2105 = _2091_fa_shadow_split.w;\n            }\n            _2097 = _2105;\n        }\n        _2081 = _2097;\n    }\n    return _2081;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2384 = max(_2091_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2389 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2395 = sqrt(1.0f - (_2389 * _2389));\n    float _2403 = min(_2395 / max(_2389, 0.20000000298023223876953125f), 4.0f);\n    float _2408;\n    if (_2091_fa_shadow_bias.y > 0.0f)\n    {\n        _2408 = _2091_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2408 = 1.5f * _2091_fa_shadow_info[ci].x;\n    }\n    float4 _2433 = mul(float4(world + (n * (_2408 * _2395)), 1.0f), _2091_fa_shadow_mat[ci]);\n    float _2440 = _2433.x;\n    bool _2443 = _2440 < _2091_fa_shadow_rect[ci].x;\n    bool _2452;\n    if (!_2443)\n    {\n        _2452 = _2440 > _2091_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2452 = _2443;\n    }\n    bool _2461;\n    if (!_2452)\n    {\n        _2461 = _2433.y < _2091_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2461 = _2452;\n    }\n    bool _2470;\n    if (!_2461)\n    {\n        _2470 = _2433.y > _2091_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2470 = _2461;\n    }\n    bool _2477;\n    if (!_2470)\n    {\n        _2477 = _2433.z > 1.0f;\n    }\n    else\n    {\n        _2477 = _2470;\n    }\n    if (_2477)\n    {\n        return -1.0f;\n    }\n    float _2485;\n    if (_2091_fa_shadow_bias.x > 0.0f)\n    {\n        _2485 = _2091_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2485 = 1.5f * _2091_fa_shadow_info[ci].x;\n    }\n    float2 param = _2433.xy;\n    float4 param_1 = _2091_fa_shadow_rect[ci];\n    float param_2 = _2433.z - ((_2485 * (1.0f + (0.5f * _2403))) / _2384);\n    float param_3 = _2091_fa_shadow_info[ci].x;\n    float param_4 = _2384;\n    float param_5 = _2384 * 0.25f;\n    float param_6 = ((_2091_fa_shadow_info[ci].x * min(_2403, 3.0f)) * 0.5f) / _2384;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2091_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2091_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_439_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2863 = int(_2091_fa_shadow_cfg.x + 0.5f);\n    if (_2863 < 1)\n    {\n        return 1.0f;\n    }\n    float _2878 = dot(world - _2091_fa_shadow_eye.xyz, _2091_fa_shadow_fwd.xyz);\n    int param = _2863 - 1;\n    if (_2878 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2890 = _2863 > 1;\n    bool _2897;\n    if (_2890)\n    {\n        _2897 = _2878 > _2091_fa_shadow_split.x;\n    }\n    else\n    {\n        _2897 = _2890;\n    }\n    if (_2897)\n    {\n        ci = 1;\n    }\n    bool _2901 = _2863 > 2;\n    bool _2908;\n    if (_2901)\n    {\n        _2908 = _2878 > _2091_fa_shadow_split.y;\n    }\n    else\n    {\n        _2908 = _2901;\n    }\n    if (_2908)\n    {\n        ci = 2;\n    }\n    bool _2912 = _2863 > 3;\n    bool _2919;\n    if (_2912)\n    {\n        _2919 = _2878 > _2091_fa_shadow_split.z;\n    }\n    else\n    {\n        _2919 = _2912;\n    }\n    if (_2919)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _2930 = min(_2863, 4);\n    float _2971;\n    for (int c = ci; c < _2930; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2950 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _2950;\n            break;\n        }\n        if (_2950 < 0.0f)\n        {\n            continue;\n        }\n        s = _2950;\n        ci = c;\n        if (_2091_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2971 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2971 = _2091_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _2990 = _2091_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2971, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_2878 - (fa_shadow_split_at(param_7) - _2990)) / _2990, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3022;\n        if ((ci + 1) < _2863)\n        {\n            _3022 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3022 = 1.0f;\n        }\n        s = lerp(s, _3022, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    bool _3127 = _439_fa_ct_b.y > 0.5f;\n    bool _3133;\n    if (_3127)\n    {\n        _3133 = _439_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3133 = _3127;\n    }\n    if (_3133)\n    {\n        float _3147 = dot(_439_fa_ct_fwd.xyz, fa_world_pos) + _439_fa_ct_fwd.w;\n        float4 _3155 = float4(fa_world_pos, 1.0f);\n        float _3161 = dot(_439_fa_ct_vpw, _3155);\n        if (_3161 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _3180 = float2(dot(_439_fa_ct_vpx, _3155), dot(_439_fa_ct_vpy, _3155)) / _3161.xx;\n            float _3185 = (_3180.x * 0.5f) + 0.5f;\n            float _3189;\n            if (_439_fa_ct_a.y > 0.5f)\n            {\n                _3189 = (_3180.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _3189 = 0.5f - (_3180.y * 0.5f);\n            }\n            bool _3205 = _3185 >= 0.0f;\n            bool _3211;\n            if (_3205)\n            {\n                _3211 = _3185 < 1.0f;\n            }\n            else\n            {\n                _3211 = _3205;\n            }\n            bool _3217;\n            if (_3211)\n            {\n                _3217 = _3189 >= 0.0f;\n            }\n            else\n            {\n                _3217 = _3211;\n            }\n            bool _3223;\n            if (_3217)\n            {\n                _3223 = _3189 < 1.0f;\n            }\n            else\n            {\n                _3223 = _3217;\n            }\n            if (_3223)\n            {\n                float4 _3248 = fa_screen_tex.Load(int3(clamp(int2(float2(_3185, _3189) * _439_fa_ct_a.zw), int2(0, 0), int2(_439_fa_ct_a.zw) - int2(1, 1)), 0));\n                bool _3251 = _3248.w > 0.5f;\n                bool _3267;\n                if (_3251)\n                {\n                    _3267 = abs(_3147 - _3248.x) <= (((0.00200000009499490261077880859375f * _3147) + 0.00999999977648258209228515625f) + fa_rt_slope);\n                }\n                else\n                {\n                    _3267 = _3251;\n                }\n                if (_3267)\n                {\n                    float _3273;\n                    if (_439_fa_ct_b.z > 0.5f)\n                    {\n                        float3 param = fa_world_pos;\n                        float3 param_1 = n;\n                        float3 param_2 = l;\n                        _3273 = min(_3248.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3273 = _3248.y;\n                    }\n                    return _3273;\n                }\n            }\n        }\n    }\n    float3 param_3 = fa_world_pos;\n    float3 param_4 = n;\n    float3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4040 = _439_fa_ct_a.x < 0.5f;\n    bool _4047;\n    if (!_4040)\n    {\n        _4047 = _2091_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4047 = _4040;\n    }\n    if (_4047)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2091_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4060 = fa_light_texel(param);\n    float _4061 = _4060.y;\n    float len = _4061;\n    if (_4061 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4073 = length(world - _439_fa_camera_pos.xyz);\n    float _4082 = 1.0f - smoothstep(0.5f * _439_fa_ct_b.x, _439_fa_ct_b.x, _4073);\n    if (_4082 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4088 = len;\n    float _4091 = min(_4088, 0.89999997615814208984375f * dist);\n    len = _4091;\n    float _4097 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4073);\n    float _4102 = _4097 + (0.5f * _4091);\n    float3 _4108 = world + (gn * _4097);\n    float _4110 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4172;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4126 = (float(k) + _4110) * 0.083333335816860198974609375f;\n        float3 _4134 = _4108 + (l * (_4126 * len));\n        float4 _4140 = float4(_4134, 1.0f);\n        float _4145 = dot(_439_fa_ct_vpw, _4140);\n        if (_4145 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4163 = float2(dot(_439_fa_ct_vpx, _4140), dot(_439_fa_ct_vpy, _4140)) / _4145.xx;\n        float _4167 = _4163.x * 0.5f;\n        float _4168 = _4167 + 0.5f;\n        if (_439_fa_ct_a.y > 0.5f)\n        {\n            _4172 = (_4163.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4172 = 0.5f - (_4163.y * 0.5f);\n        }\n        bool _4188 = _4168 < 0.0f;\n        bool _4195;\n        if (!_4188)\n        {\n            _4195 = _4168 >= 1.0f;\n        }\n        else\n        {\n            _4195 = _4188;\n        }\n        bool _4202;\n        if (!_4195)\n        {\n            _4202 = _4172 < 0.0f;\n        }\n        else\n        {\n            _4202 = _4195;\n        }\n        bool _4209;\n        if (!_4202)\n        {\n            _4209 = _4172 >= 1.0f;\n        }\n        else\n        {\n            _4209 = _4202;\n        }\n        if (_4209)\n        {\n            break;\n        }\n        float4 _4233 = fa_screen_tex.Load(int3(clamp(int2(float2(_4168, _4172) * _439_fa_ct_a.zw), int2(0, 0), int2(_439_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_4233.w < 0.5f)\n        {\n            continue;\n        }\n        float _4251 = (dot(_439_fa_ct_fwd.xyz, _4134) + _439_fa_ct_fwd.w) - _4233.x;\n        if ((_4251 > _4097) && (_4251 < _4102))\n        {\n            occ = max(occ, (1.0f - (_4126 * _4126)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4168, 0.5f - _4167), min(_4172, 1.0f - _4172))));\n        }\n    }\n    return 1.0f - (occ * _4082);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4383 = fa_baked_keep(param);\n    if (_4383 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _6306 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6306;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4409 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6308 = _4409.color;\n    float _6309 = _4409.attenuation;\n    float _6310 = _4409.shadow;\n    bool _4412 = _4409.type == 0;\n    if (_4412 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4409.direction;\n        float _4423 = fa_shadow_factor(param_5, param_6);\n        _6310 = _4423;\n        _6308 *= _4423;\n    }\n    else\n    {\n        bool _4434 = _4409.type != 0;\n        bool _4440;\n        if (_4434)\n        {\n            _4440 = _6309 > 0.0f;\n        }\n        else\n        {\n            _4440 = _4434;\n        }\n        if (_4440)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4409.direction;\n            float _4459 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6310 = _4459;\n            _6308 *= _4459;\n        }\n    }\n    bool _4469 = _439_fa_ct_a.x > 0.5f;\n    bool _4475;\n    if (_4469)\n    {\n        _4475 = _6309 > 0.0f;\n    }\n    else\n    {\n        _4475 = _4469;\n    }\n    if (_4475)\n    {\n        float _4482;\n        if (_4412)\n        {\n            _4482 = 1000000000.0f;\n        }\n        else\n        {\n            _4482 = _4409._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4409.direction;\n        float param_18 = _4482;\n        float _4500 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6310 *= _4500;\n        _6308 *= _4500;\n    }\n    float _4513 = _6309;\n    float _4514 = _4513 * _4383;\n    _6309 = _4514;\n    float3 _4518 = _6308;\n    float3 _4519 = _4518 * _4383;\n    _6308 = _4519;\n    LightSample _6325 = { _4409.direction, _4519, _4514, _6310, _4409._distance, _4409.type };\n    return _6325;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2091_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3050 = int(_2091_fa_shadow_cfg.x + 0.5f);\n    float _3060 = dot(world - _2091_fa_shadow_eye.xyz, _2091_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3065 = _3050 > 0;\n    bool _3074;\n    if (_3065)\n    {\n        int param = _3050 - 1;\n        _3074 = _3060 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3074 = _3065;\n    }\n    if (_3074)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3080 = _3050 > 1;\n        bool _3087;\n        if (_3080)\n        {\n            _3087 = _3060 > _2091_fa_shadow_split.x;\n        }\n        else\n        {\n            _3087 = _3080;\n        }\n        if (_3087)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3093 = _3050 > 2;\n        bool _3100;\n        if (_3093)\n        {\n            _3100 = _3060 > _2091_fa_shadow_split.y;\n        }\n        else\n        {\n            _3100 = _3093;\n        }\n        if (_3100)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3106 = _3050 > 3;\n        bool _3113;\n        if (_3106)\n        {\n            _3113 = _3060 > _2091_fa_shadow_split.z;\n        }\n        else\n        {\n            _3113 = _3106;\n        }\n        if (_3113)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_rt_slope = 0.0f;\n    fa_inst_load();\n    float3 _6100 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6100 = -_6100;\n    }\n    float3 _5674 = normalize(_439_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _6113 = { fa_world_pos, _6100, fa_world_tangent, fa_uv, fa_vertex_color, _5674, gl_FrontFacing };\n    SurfaceInput param_1 = _6113;\n    Surface _5682 = fa_standard_surface(param_1);\n    float3 _6139 = _5682.albedo;\n    float _6140 = _5682.alpha;\n    float3 _6141 = _5682.normal;\n    float _6142 = _5682.metallic;\n    float _6143 = _5682.roughness;\n    float _6144 = _5682.occlusion;\n    float3 _6145 = _5682.emission;\n    float _6146 = _5682.clearcoat;\n    float _6147 = _5682.clearcoat_roughness;\n    float3 _6148 = _5682.sheen_color;\n    float _6149 = _5682.sheen_roughness;\n    float _6150 = _5682.anisotropy;\n    float _6151 = _5682.anisotropy_rotation;\n    float _6152 = _5682.specular;\n    float _6153 = _5682.ior;\n    float3 _6154 = _5682.specular_color;\n    float _6155 = _5682.transmission;\n    float _6156 = _5682.thickness;\n    float3 _6157 = _5682.attenuation_color;\n    float _6158 = _5682.attenuation_distance;\n    SurfaceInput _6121 = { fa_world_pos, _6100, fa_world_tangent, fa_uv, fa_vertex_color, _5674, gl_FrontFacing };\n    SurfaceInput param_2 = _6121;\n    Surface param_3 = _5682;\n    surface(param_2, param_3);\n    _6139 = param_3.albedo;\n    _6140 = param_3.alpha;\n    _6141 = param_3.normal;\n    _6142 = param_3.metallic;\n    _6143 = param_3.roughness;\n    _6144 = param_3.occlusion;\n    _6145 = param_3.emission;\n    _6146 = param_3.clearcoat;\n    _6147 = param_3.clearcoat_roughness;\n    _6148 = param_3.sheen_color;\n    _6149 = param_3.sheen_roughness;\n    _6150 = param_3.anisotropy;\n    _6151 = param_3.anisotropy_rotation;\n    _6152 = param_3.specular;\n    _6153 = param_3.ior;\n    _6154 = param_3.specular_color;\n    _6155 = param_3.transmission;\n    _6156 = param_3.thickness;\n    _6157 = param_3.attenuation_color;\n    _6158 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _6100;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6139 = param_6;\n    _6141 = param_7;\n    float3 result;\n    if (_439_fa_emissive.w > 0.5f)\n    {\n        result = _6139;\n    }\n    else\n    {\n        float3 _5721 = _6141;\n        float3 _5722 = normalize(_5721);\n        _6141 = _5722;\n        float3 param_8 = _5722;\n        SurfaceInput _6129 = { fa_world_pos, _6100, fa_world_tangent, fa_uv, fa_vertex_color, _5674, gl_FrontFacing };\n        SurfaceInput param_9 = _6129;\n        Surface _6240 = { _6139, _6140, _6141, _6142, _6143, _6144, _6145, _6146, _6147, _6148, _6149, _6150, _6151, _6152, _6153, _6154, _6155, _6156, _6157, _6158 };\n        Surface param_10 = _6240;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _5741 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5741; ln++)\n        {\n            int param_12 = ln;\n            int _5754 = fa_cl_light(param_12);\n            int param_13 = _5754;\n            if (fa_baked_keep(param_13) <= 0.0f)\n            {\n                continue;\n            }\n            int param_14 = _5754;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _6100;\n            LightSample _5770 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _6137 = { fa_world_pos, _6100, fa_world_tangent, fa_uv, fa_vertex_color, _5674, gl_FrontFacing };\n            SurfaceInput param_17 = _6137;\n            Surface _6261 = { _6139, _6140, _6141, _6142, _6143, _6144, _6145, _6146, _6147, _6148, _6149, _6150, _6151, _6152, _6153, _6154, _6155, _6156, _6157, _6158 };\n            Surface param_18 = _6261;\n            LightSample param_19 = _5770;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _5785 = result;\n    float3 _5786 = _5785 + _6145;\n    result = _5786;\n    float3 param_20 = _5786;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _5795 = _439_fa_fog.w > 0.0f;\n    bool _5802;\n    if (!_5795)\n    {\n        _5802 = _439_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5802 = _5795;\n    }\n    if (_5802)\n    {\n        float3 _5811 = fa_world_pos - _439_fa_camera_pos.xyz;\n        float _5817 = dot(_5811, _439_fa_fog_c.xyz);\n        bool _5821 = _439_fa_fog_c.w > 0.5f;\n        float _5822;\n        if (_5821)\n        {\n            _5822 = _5817;\n        }\n        else\n        {\n            _5822 = length(_5811);\n        }\n        float _5834 = _5822 - _439_fa_fog_b.x;\n        if (_5834 > 0.0f)\n        {\n            float _5843 = _439_fa_fog.w * _5834;\n            float tau = _5843 * _5843;\n            if (_439_fa_fog_b.y > 0.0f)\n            {\n                float _5859;\n                if (_5821)\n                {\n                    _5859 = fa_world_pos.y - (_439_fa_fog_c.y * _5817);\n                }\n                else\n                {\n                    _5859 = _439_fa_camera_pos.y;\n                }\n                float _5880 = lerp(_5859, fa_world_pos.y, clamp(_439_fa_fog_b.x / _5822, 0.0f, 1.0f));\n                float _5884 = fa_world_pos.y - _5880;\n                float _5889 = _5880 - _439_fa_fog_b.z;\n                float _5894 = fa_world_pos.y - _439_fa_fog_b.z;\n                bool _5897 = _5889 <= 0.0f;\n                bool _5898 = !_5897;\n                bool _5904;\n                if (_5898)\n                {\n                    _5904 = _439_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5904 = _5897;\n                }\n                float _5905;\n                if (_5904)\n                {\n                    _5905 = _439_fa_fog_b.y;\n                }\n                else\n                {\n                    _5905 = _439_fa_fog_b.y * exp(-min(_439_fa_fog_b.w * _5889, 80.0f));\n                }\n                bool _5932;\n                if (_5898)\n                {\n                    _5932 = _439_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5932 = _5897;\n                }\n                float _5933;\n                if (_5932)\n                {\n                    _5933 = _439_fa_fog_b.y * _5889;\n                }\n                else\n                {\n                    _5933 = (_439_fa_fog_b.y * (1.0f - exp(-min(_439_fa_fog_b.w * _5889, 80.0f)))) / _439_fa_fog_b.w;\n                }\n                bool _5958 = _5894 <= 0.0f;\n                bool _5965;\n                if (!_5958)\n                {\n                    _5965 = _439_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5965 = _5958;\n                }\n                float _5966;\n                if (_5965)\n                {\n                    _5966 = _439_fa_fog_b.y * _5894;\n                }\n                else\n                {\n                    _5966 = (_439_fa_fog_b.y * (1.0f - exp(-min(_439_fa_fog_b.w * _5894, 80.0f)))) / _439_fa_fog_b.w;\n                }\n                float _5993;\n                if (abs(_5884) < 0.001000000047497451305389404296875f)\n                {\n                    _5993 = _5905;\n                }\n                else\n                {\n                    _5993 = (_5966 - _5933) / _5884;\n                }\n                tau += (_5834 * max(_5993, 0.0f));\n            }\n            result = lerp(result, _439_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _6140);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_439",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2091",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _439_fa_camera_pos : packoffset(c0);\n    float4 _439_fa_ambient : packoffset(c1);\n    float4 _439_fa_base_color : packoffset(c2);\n    float4 _439_fa_emissive : packoffset(c3);\n    float4 _439_fa_model_emissive : packoffset(c4);\n    float4 _439_fa_pbr : packoffset(c5);\n    float4 _439_fa_maps : packoffset(c6);\n    float4 _439_fa_fog : packoffset(c7);\n    float4 _439_fa_fog_b : packoffset(c8);\n    float4 _439_fa_fog_c : packoffset(c9);\n    float4 _439_fa_counts : packoffset(c10);\n    float4 _439_fa_env_sky : packoffset(c11);\n    float4 _439_fa_env_horizon : packoffset(c12);\n    float4 _439_fa_time : packoffset(c13);\n    float4 _439_fa_cl_vpx : packoffset(c14);\n    float4 _439_fa_cl_vpy : packoffset(c15);\n    float4 _439_fa_cl_vpw : packoffset(c16);\n    float4 _439_fa_cl_fwd : packoffset(c17);\n    float4 _439_fa_cl_grid : packoffset(c18);\n    float4 _439_fa_cl_info : packoffset(c19);\n    float4 _439_fa_layers_a : packoffset(c20);\n    float4 _439_fa_layers_b : packoffset(c21);\n    float4 _439_fa_layers_c : packoffset(c22);\n    float4 _439_fa_layers_d : packoffset(c23);\n    float4 _439_fa_ct_a : packoffset(c24);\n    float4 _439_fa_ct_b : packoffset(c25);\n    float4 _439_fa_ct_vpx : packoffset(c26);\n    float4 _439_fa_ct_vpy : packoffset(c27);\n    float4 _439_fa_ct_vpw : packoffset(c28);\n    float4 _439_fa_ct_fwd : packoffset(c29);\n    float4 _439_fa_tr_a : packoffset(c30);\n    float4 _439_fa_tr_b : packoffset(c31);\n    float4 _439_fa_probe_sh[9] : packoffset(c32);\n    float4 _439_fa_atlas : packoffset(c41);\n    float4 _439_fa_rpa_tile : packoffset(c42);\n    float4 _439_fa_rpa_pos : packoffset(c43);\n    float4 _439_fa_rpa_bx : packoffset(c44);\n    float4 _439_fa_rpa_by : packoffset(c45);\n    float4 _439_fa_rpa_bz : packoffset(c46);\n    float4 _439_fa_rpb_tile : packoffset(c47);\n    float4 _439_fa_rpb_pos : packoffset(c48);\n    float4 _439_fa_rpb_bx : packoffset(c49);\n    float4 _439_fa_rpb_by : packoffset(c50);\n    float4 _439_fa_rpb_bz : packoffset(c51);\n    float4 _439_fa_gi : packoffset(c52);\n    float4 _439_fa_gi_px : packoffset(c53);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2091_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2091_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2091_fa_shadow_info[4] : packoffset(c20);\n    float4 _2091_fa_shadow_split : packoffset(c24);\n    float4 _2091_fa_shadow_cfg : packoffset(c25);\n    float4 _2091_fa_shadow_bias : packoffset(c26);\n    float4 _2091_fa_shadow_eye : packoffset(c27);\n    float4 _2091_fa_shadow_fwd : packoffset(c28);\n    float4 _2091_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float fa_rt_slope;\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1367 = _439_fa_cl_info.x < 0.0f;\n    bool _1374;\n    if (!_1367)\n    {\n        _1374 = _439_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1374 = _1367;\n    }\n    bool _1382;\n    if (!_1374)\n    {\n        _1382 = _439_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1382 = _1374;\n    }\n    bool _1389;\n    if (!_1382)\n    {\n        _1389 = _439_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1389 = _1382;\n    }\n    bool _1396;\n    if (!_1389)\n    {\n        _1396 = _439_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1396 = _1389;\n    }\n    if (_1396)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1406 = float4(world_pos, 1.0f);\n    float _1412 = dot(_439_fa_cl_vpw, _1406);\n    if (!(_1412 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1434 = float2(dot(_439_fa_cl_vpx, _1406), dot(_439_fa_cl_vpy, _1406)) / _1412.xx;\n    int _1438 = int(_439_fa_cl_grid.x);\n    int _1442 = int(_439_fa_cl_grid.y);\n    int param = (int(_439_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_439_fa_cl_fwd.xyz, world_pos) + _439_fa_cl_fwd.w, _439_fa_cl_grid.w) / _439_fa_cl_grid.w) * _439_fa_cl_grid.z)), 0, int(_439_fa_cl_info.y) - 1) * _1442) + clamp(int(floor(((_1434.y * 0.5f) + 0.5f) * _439_fa_cl_grid.y)), 0, _1442 - 1)) * _1438)) + clamp(int(floor(((_1434.x * 0.5f) + 0.5f) * _439_fa_cl_grid.x)), 0, _1438 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1518 = fa_cluster_texel(param);\n    return int2(int(_1518.x), int(_1518.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    float _4328 = dot(_439_fa_ct_fwd.xyz, world_pos) + _439_fa_ct_fwd.w;\n    float _4331 = fwidth(_4328);\n    bool _4334 = _439_fa_ct_b.y > 0.5f;\n    bool _4341;\n    if (!_4334)\n    {\n        _4341 = _439_fa_ct_b.w > 0.5f;\n    }\n    else\n    {\n        _4341 = _4334;\n    }\n    if (_4341)\n    {\n        fa_rt_slope = min(1.5f * _4331, 0.100000001490116119384765625f * _4328);\n    }\n    fa_cl_ndir = int(_439_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4357 = fa_cluster_lookup(param);\n    fa_cl_slot = _4357.x;\n    fa_cl_local = _4357.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4567 = fa_linear_to_srgb(param);\n        c = _4567;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4575 = fa_srgb_to_linear(param_1);\n            c = _4575;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _322;\n    if (i.front_facing)\n    {\n        _322 = i.world_normal;\n    }\n    else\n    {\n        _322 = -i.world_normal;\n    }\n    float3 _346 = normalize(i.world_tangent.xyz - (_322 * dot(_322, i.world_tangent.xyz)));\n    float3 _373 = normalize(((_346 * m.x) + ((cross(_322, _346) * i.world_tangent.w) * m.y)) + (_322 * m.z));\n    float3 _376;\n    if (i.front_facing)\n    {\n        _376 = _373;\n    }\n    else\n    {\n        _376 = -_373;\n    }\n    return _376;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _439_fa_env_horizon.w);\n    float param = _439_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4607 = fa_tex_fix(param_2, param_3);\n    float4 _6515 = base_t;\n    _6515.x = _4607.x;\n    _6515.y = _4607.y;\n    _6515.z = _4607.z;\n    base_t = _6515;\n    float4 _4621 = (_6515 * _439_fa_base_color) * i.vertex_color;\n    float3 _6328 = i.world_normal;\n    if (_439_fa_maps.z > 0.5f)\n    {\n        float param_4 = _439_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _439_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4655 = fa_tex_fix(param_6, param_7);\n        float3 _4658 = (_4655 * 2.0f) - 1.0f.xxx;\n        float2 _4663 = _4658.xy * _439_fa_maps.x;\n        float3 _6523 = _4658;\n        _6523.x = _4663.x;\n        _6523.y = _4663.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6523;\n        _6328 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _439_fa_env_horizon.w);\n    float param_10 = _439_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4693 = fa_tex_fix(param_12, param_13);\n    float4 _6526 = mrt;\n    _6526.x = _4693.x;\n    _6526.y = _4693.y;\n    _6526.z = _4693.z;\n    mrt = _6526;\n    float4 _4723 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _439_fa_env_horizon.w);\n    float param_14 = _439_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4723.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4734 = fa_tex_fix(param_16, param_17);\n    float param_18 = _439_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _439_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4766 = fa_tex_fix(param_20, param_21);\n    float _6333 = _439_fa_layers_a.x;\n    float _6334 = _439_fa_layers_a.y;\n    float _6337 = _439_fa_layers_a.z;\n    float _6336 = _439_fa_layers_b.w;\n    float _6339 = _439_fa_layers_c.x;\n    if (_439_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_439_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6333 *= _4734.y;\n            _6334 *= _4734.z;\n            _6336 *= _4723.w;\n        }\n        if (_439_fa_layers_c.z > 1.5f)\n        {\n            _6337 *= mrt.x;\n            _6339 *= mrt.w;\n        }\n    }\n    Surface _6366 = { _4621.xyz, _4621.w, _6328, clamp(_439_fa_pbr.x * _4693.z, 0.0f, 1.0f), clamp(_439_fa_pbr.y * _4693.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_439_fa_maps.y * (_4734.x - 1.0f)), _439_fa_emissive.xyz + (_439_fa_model_emissive.xyz * _4766), _6333, _6334, _439_fa_layers_b.xyz, _6336, _6337, _439_fa_layers_a.w, _6339, _439_fa_layers_c.y, _439_fa_layers_d.xyz, _439_fa_tr_a.x, _439_fa_tr_a.y, _439_fa_tr_b.xyz, _439_fa_tr_a.z };\n    return _6366;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1598 = rect.zw - rect.xy;\n    float2 _1602 = _1598 * atlas;\n    float2 _1606 = ddx * _1602;\n    float2 _1610 = ddy * _1602;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1598), clamp(0.5f * log2(max(max(dot(_1606, _1606), dot(_1610, _1610)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1643 = _439_fa_counts.y < 0.5f;\n    bool _1650;\n    if (!_1643)\n    {\n        _1650 = _439_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1650 = _1643;\n    }\n    if (_1650)\n    {\n        return;\n    }\n    float3 _1656 = ddx(world_pos);\n    float3 _1659 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1663 = fa_cluster_texel(param);\n    int _1667 = int(_1663.w);\n    if (_1667 < 1)\n    {\n        return;\n    }\n    int _1677 = int(_439_fa_counts.y + 0.5f);\n    int param_1 = _1677;\n    float4 _1681 = fa_light_texel(param_1);\n    float2 _1684 = _1681.yz;\n    int _1688 = int(_1681.w);\n    int param_2 = _1677 + 1;\n    float4 _1693 = fa_light_texel(param_2);\n    float _1694 = _1693.x;\n    int _1700 = int(_439_fa_counts.w + 0.5f) - 1;\n    int _1704 = int(_1663.z);\n    float3 _1969;\n    for (int k = 0; k < _1667; k++)\n    {\n        int _1717 = _1704 + k;\n        int param_3 = _1688 + (_1717 >> 2);\n        int _1734 = (_1677 + 2) + (int(fa_light_texel(param_3)[_1717 & 3]) * 7);\n        int param_4 = _1734 + 6;\n        float4 _1739 = fa_light_texel(param_4);\n        if (((int(_1739.w + 0.5f) >> _1700) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1734;\n        float4 _1754 = fa_light_texel(param_5);\n        int param_6 = _1734 + 1;\n        float4 _1759 = fa_light_texel(param_6);\n        int param_7 = _1734 + 2;\n        float4 _1764 = fa_light_texel(param_7);\n        float3 _1767 = _1754.xyz;\n        float _1772 = dot(_1767, world_pos) + _1754.w;\n        float3 _1774 = _1759.xyz;\n        float _1779 = dot(_1774, world_pos) + _1759.w;\n        float3 _1781 = _1764.xyz;\n        float _1786 = dot(_1781, world_pos) + _1764.w;\n        bool _1791 = abs(_1772) > 0.5f;\n        bool _1799;\n        if (!_1791)\n        {\n            _1799 = abs(_1779) > 0.5f;\n        }\n        else\n        {\n            _1799 = _1791;\n        }\n        bool _1807;\n        if (!_1799)\n        {\n            _1807 = abs(_1786) > 0.5f;\n        }\n        else\n        {\n            _1807 = _1799;\n        }\n        if (_1807)\n        {\n            continue;\n        }\n        float _1822 = clamp(dot(geo_normal, normalize(_1781)) * _1739.z, 0.0f, 1.0f);\n        if (_1822 <= 0.0f)\n        {\n            continue;\n        }\n        float _1842 = (clamp((0.5f - abs(_1786)) * 10.0f, 0.0f, 1.0f) * _1822) * _1739.x;\n        float2 _1850 = float2(_1772 + 0.5f, 0.5f - _1779);\n        float2 _1860 = float2(dot(_1767, _1656), dot(_1774, _1656));\n        float2 _1870 = float2(dot(_1767, _1659), dot(_1774, _1659));\n        int param_8 = _1734 + 5;\n        float4 _1875 = fa_light_texel(param_8);\n        int param_9 = _1734 + 3;\n        float4 _1880 = fa_light_texel(param_9);\n        int param_10 = _1734 + 4;\n        float4 _1885 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1875.xyz;\n        bool _1895 = _1880.z > _1880.x;\n        if (_1895)\n        {\n            float4 param_11 = _1880;\n            float2 param_12 = _1850;\n            float2 param_13 = _1684;\n            float2 param_14 = _1860;\n            float2 param_15 = _1870;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1694 > 0.5f) && (_1694 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1921 = fa_dc_to_linear(param_16);\n                float4 _6416 = tx;\n                _6416.x = _1921.x;\n                _6416.y = _1921.y;\n                _6416.z = _1921.z;\n                tx = _6416;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1842 * tex_a) * _1875.w, 0.0f, 1.0f).xxx);\n        if (_1885.z > _1885.x)\n        {\n            float4 param_17 = _1885;\n            float2 param_18 = _1850;\n            float2 param_19 = _1684;\n            float2 param_20 = _1860;\n            float2 param_21 = _1870;\n            float4 _1965 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1694 > 1.5f)\n            {\n                float3 param_22 = _1965.xyz;\n                float3 _1975 = fa_dc_to_srgb(param_22);\n                _1969 = _1975;\n            }\n            else\n            {\n                _1969 = _1965.xyz;\n            }\n            float3 _1984 = (_1969 * 2.0f) - 1.0f.xxx;\n            float2 _1989 = _1984.xy * _1739.y;\n            float3 _2011 = (normalize(_1767) * _1989.x) + (normalize(_1774) * _1989.y);\n            float3 _2014 = normalize(normal);\n            normal = normalize(lerp(_2014, normalize((_2014 * max(_1984.z, 0.0500000007450580596923828125f)) + (_2011 - (_2014 * dot(_2014, _2011)))), clamp(_1842 * (_1895 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3850_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3850_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_439_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3791 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3791;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3900 = (1.0f - _439_fa_rpa_tile.w) - _439_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3906 = _439_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3900 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3906)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _439_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3900;\n            }\n        }\n        else\n        {\n            amb = _439_fa_ambient.xyz * _3900;\n        }\n    }\n    bool _3958 = _439_fa_rpa_tile.w > 0.0f;\n    if (_3958)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _439_fa_rpa_tile.xy;\n            float param_4 = _439_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _439_fa_rpa_tile.w);\n        }\n    }\n    bool _3989 = _439_fa_rpb_tile.w > 0.0f;\n    if (_3989)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _439_fa_rpb_tile.xy;\n            float param_7 = _439_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _439_fa_rpb_tile.w);\n        }\n    }\n    if ((_3906 || _3958) || _3989)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3811 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3814 = _3811.x;\n    float _3816 = _3811.z;\n    float2 e = float2(_3814, _3816);\n    if (_3811.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3816)) * ((_3814 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3814)) * ((_3816 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _4880 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _4885 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _4890 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _4895 = fa_light_texel(param_3);\n    bool _4898 = _4895.z < 0.5f;\n    bool _4906;\n    if (!_4898)\n    {\n        _4906 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _4906 = _4898;\n    }\n    if (_4906)\n    {\n        return 0.0f.xxx;\n    }\n    float _4913 = max(_4880.w, 9.9999997473787516355514526367188e-05f);\n    float3 _4916 = _4885.xyz;\n    float3 _4920 = _4880.xyz;\n    float3 _4924 = (fa_world_pos - _4920) / _4913.xxx;\n    float3 _4933 = min(_4924 + 0.5f.xxx, (_4916 - 0.5f.xxx) - _4924);\n    float _4942 = min(_4933.x, min(_4933.y, _4933.z));\n    if (!(_4942 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4957 = _4916 - 1.0f.xxx;\n    float3 _4958 = clamp(_4924, 0.0f.xxx, _4957);\n    float3 _4966 = min(floor(_4958), max(_4916 - 2.0f.xxx, 0.0f.xxx));\n    float3 _4970 = _4958 - _4966;\n    float3 _4982 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _4913));\n    int _4987 = int(_4890.y + 0.5f);\n    float _4992 = 0.3257350027561187744140625f * n.y;\n    float _4996 = 0.3257350027561187744140625f * n.z;\n    float _5000 = 0.3257350027561187744140625f * n.x;\n    float _5007 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _5014 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _5023 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _5030 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _5043 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _5050 = 8 + int(_4895.w);\n    float _5077;\n    float _5090;\n    float _5104;\n    for (int k = 0; k < _5050; k++)\n    {\n        float _5063 = float(k & 1);\n        float _5067 = float((k >> 1) & 1);\n        float _5071 = float((k >> 2) & 1);\n        if (_5063 > 0.5f)\n        {\n            _5077 = _4970.x;\n        }\n        else\n        {\n            _5077 = 1.0f - _4970.x;\n        }\n        if (_5067 > 0.5f)\n        {\n            _5090 = _4970.y;\n        }\n        else\n        {\n            _5090 = 1.0f - _4970.y;\n        }\n        if (_5071 > 0.5f)\n        {\n            _5104 = _4970.z;\n        }\n        else\n        {\n            _5104 = 1.0f - _4970.z;\n        }\n        float _5114 = (_5077 * _5090) * _5104;\n        if (!(_5114 > 0.0f))\n        {\n            continue;\n        }\n        float3 _5127 = min(_4966 + float3(_5063, _5067, _5071), _4957);\n        int _5147 = int(((_4890.x + _5127.x) + (_4885.x * (_5127.y + (_4885.y * _5127.z)))) + 0.5f);\n        float2 _5162 = float2(float(_5147 % _4987) * 10.0f, 1024.0f + (float(_5147 / _4987) * 11.0f));\n        float2 param_4 = _5162 + float2(9.5f, 10.5f);\n        float4 _5170 = fa_gi_fetch(param_4);\n        bool _5173 = _5170.y < 0.5f;\n        bool _5182;\n        if (!_5173)\n        {\n            _5182 = _5170.x > _4895.y;\n        }\n        else\n        {\n            _5182 = _5173;\n        }\n        if (_5182)\n        {\n            continue;\n        }\n        float3 _5194 = _4982 - (_4920 + (_5127 * _4913));\n        float _5197 = length(_5194);\n        float3 _5203 = _5194 / max(_5197, 9.9999997473787516355514526367188e-05f).xxx;\n        float _5213 = max(9.9999997473787516355514526367188e-05f, (dot(-_5203, n) + 1.0f) * 0.5f);\n        float w = _5114 * (_5213 * _5213);\n        float3 param_5 = _5203;\n        float2 param_6 = (_5162 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _5233 = fa_gi_fetch(param_6);\n        float _5240 = _5197 / max(_4890.z, 9.9999997473787516355514526367188e-05f);\n        float _5243 = _5233.x;\n        if (_5240 > _5243)\n        {\n            float _5256 = max(_5233.y - (_5243 * _5243), 0.0f);\n            float _5261 = _5240 - _5243;\n            float _5270 = _5256 / max(_5256 + (_5261 * _5261), 9.9999999600419720025001879548654e-13f);\n            w *= ((_5270 * _5270) * _5270);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _5162 + float2(0.5f, 10.5f);\n        float2 param_8 = _5162 + float2(1.5f, 10.5f);\n        float2 param_9 = _5162 + float2(2.5f, 10.5f);\n        float2 param_10 = _5162 + float2(3.5f, 10.5f);\n        float2 param_11 = _5162 + float2(4.5f, 10.5f);\n        float2 param_12 = _5162 + float2(5.5f, 10.5f);\n        float2 param_13 = _5162 + float2(6.5f, 10.5f);\n        float2 param_14 = _5162 + float2(7.5f, 10.5f);\n        float2 param_15 = _5162 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _4992)) + (fa_gi_fetch(param_9).xyz * _4996)) + (fa_gi_fetch(param_10).xyz * _5000)) + (fa_gi_fetch(param_11).xyz * _5007)) + (fa_gi_fetch(param_12).xyz * _5014)) + (fa_gi_fetch(param_13).xyz * _5023)) + (fa_gi_fetch(param_14).xyz * _5030)) + (fa_gi_fetch(param_15).xyz * _5043)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_4942 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _5398;\n    if (_439_fa_gi.z > 0.5f)\n    {\n        _5398 = _4895.x;\n    }\n    else\n    {\n        _5398 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_4890.w * _5398);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _5422 = normalize(_439_fa_camera_pos.xyz - fa_world_pos);\n    int _5427 = int(_439_fa_gi.x + 0.5f);\n    int _5432 = int(_439_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _5432) && (k < 8); k++)\n    {\n        int param = _5427 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _5422;\n        float3 _5457 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5462 = param_3 * left;\n        acc += (_5457 * _5462);\n        left -= _5462;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_439_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _5491 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5491;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_439_fa_gi_px.x > 0.5f)\n    {\n        float4 _5533 = float4(fa_world_pos, 1.0f);\n        float2 _5552 = float2(dot(_439_fa_ct_vpx, _5533), dot(_439_fa_ct_vpy, _5533)) / max(dot(_439_fa_ct_vpw, _5533), 9.9999997473787516355514526367188e-05f).xx;\n        float _5561;\n        if (_439_fa_ct_a.y > 0.5f)\n        {\n            _5561 = (_5552.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5561 = 0.5f - (_5552.y * 0.5f);\n        }\n        return fa_lightmap.Load(int3(clamp(int2(float2((_5552.x * 0.5f) + 0.5f, _5561) * _439_fa_ct_a.zw), int2(0, 0), int2(_439_fa_ct_a.zw) - int2(1, 1)), 0)).xyz;\n    }\n    if (_439_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _439_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_439_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nfloat3 ambient(SurfaceInput i, Surface s, float3 ambientColor)\n{\n    return float3(0.0f, ambientColor.y, 0.0f);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_439_fa_cl_info.x) + int(_439_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_439_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4298;\n    if (fa_lm.z > 0.5f)\n    {\n        _4298 = 0.0f;\n    }\n    else\n    {\n        _4298 = 1.0f - clamp(_439_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4309 = _4298 < 1.0f;\n    bool _4315;\n    if (_4309)\n    {\n        int param = li;\n        _4315 = fa_light_baked(param);\n    }\n    else\n    {\n        _4315 = _4309;\n    }\n    return _4315 ? _4298 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _617 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _630 = (c - (ru * hx)) - p;\n        float3 _636 = ru * (2.0f * hx);\n        float _642 = max(dot(_636, _636), 9.9999999392252902907785028219223e-09f);\n        float _646 = dot(_630, _636);\n        float t = clamp((-_646) / _642, 0.0f, 1.0f);\n        if (_617)\n        {\n            float _661 = dot(r, _636);\n            float _667 = _642 - (_661 * _661);\n            if (abs(_667) > (9.9999997473787516355514526367188e-06f * _642))\n            {\n                t = clamp(((dot(r, _630) * _661) - _646) / _667, 0.0f, 1.0f);\n            }\n        }\n        return (p + _630) + (_636 * t);\n    }\n    float3 q = p;\n    float _699 = dot(r, axis);\n    bool _707;\n    if (_617)\n    {\n        _707 = abs(_699) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _707 = _617;\n    }\n    if (_707)\n    {\n        float _717 = dot(c - p, axis) / _699;\n        if (_717 > 0.0f)\n        {\n            q = p + (r * _717);\n        }\n    }\n    float3 _730 = q - c;\n    float2 xy = float2(dot(_730, ru), dot(_730, uu));\n    if (shape > 0.5f)\n    {\n        float _745 = length(xy);\n        if (_745 > hx)\n        {\n            xy *= (hx / _745);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _498_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _498_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _537 = dot(d, right);\n    float _541 = dot(d, up);\n    float _552;\n    if (((_537 * _537) + (_541 * _541)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _552 = atan2(_541, _537) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _552 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_552 - floor(_552)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _388 = abs(d);\n    float _390 = _388.x;\n    float _392 = _388.y;\n    bool _393 = _390 >= _392;\n    bool _401;\n    if (_393)\n    {\n        _401 = _390 >= _388.z;\n    }\n    else\n    {\n        _401 = _393;\n    }\n    int _402;\n    if (_401)\n    {\n        _402 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _416;\n        if (_392 >= _388.z)\n        {\n            _416 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _416 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _402 = _416;\n    }\n    return _402;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _783 = fa_light_base(param);\n    bool _787 = _439_fa_ambient.w > 4.5f;\n    int param_1 = _783;\n    float4 _791 = fa_light_texel(param_1);\n    int param_2 = _783 + 1;\n    float4 _796 = fa_light_texel(param_2);\n    float _799 = _796.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _811 = _787 && (_799 > 2.5f);\n    fa_light_is_area = _811;\n    bool _813 = _799 < 0.5f;\n    float3 l;\n    if (_813)\n    {\n        l = normalize(_791.xyz);\n        if (_787)\n        {\n            int param_3 = _783 + 6;\n            float4 _827 = fa_light_texel(param_3);\n            if (_827.z > 0.5f)\n            {\n                int param_4 = _783 + 4;\n                float4 _837 = fa_light_texel(param_4);\n                int param_5 = _783 + 5;\n                float4 _842 = fa_light_texel(param_5);\n                float2 param_6 = _827.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _837.xyz) * _837.w, (-dot(world_pos, _842.xyz)) * _842.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _872 = _791.xyz;\n        float3 _874 = _872 - world_pos;\n        float3 to_light = _874;\n        float _877 = length(_874);\n        float reach = _877;\n        bool front = true;\n        if (_811)\n        {\n            int param_8 = _783 + 7;\n            reach = max(_877 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _783 + 4;\n            float4 _901 = fa_light_texel(param_9);\n            int param_10 = _783 + 5;\n            float4 _906 = fa_light_texel(param_10);\n            int param_11 = _783 + 6;\n            float4 _911 = fa_light_texel(param_11);\n            float _912 = _911.w;\n            int param_12 = _783 + 2;\n            float3 _919 = normalize(fa_light_texel(param_12).xyz);\n            bool _921 = _912 > 1.5f;\n            bool _929;\n            if (!_921)\n            {\n                _929 = dot(_919, to_light) < 0.0f;\n            }\n            else\n            {\n                _929 = _921;\n            }\n            front = _929;\n            float3 r = 0.0f.xxx;\n            float3 _938 = _439_fa_camera_pos.xyz - world_pos;\n            bool _942 = dot(n, n) > 0.5f;\n            bool _950;\n            if (_942)\n            {\n                _950 = dot(_938, _938) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _950 = _942;\n            }\n            if (_950)\n            {\n                r = reflect(-normalize(_938), normalize(n));\n            }\n            float3 param_13 = _872;\n            float3 param_14 = _919;\n            float3 param_15 = _901.xyz;\n            float3 param_16 = _906.xyz;\n            float param_17 = _901.w;\n            float param_18 = _906.w;\n            float param_19 = _912;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _986 = length(to_light);\n        dist = _986;\n        l = to_light / max(_986, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1000 = reach / max(_791.w, 0.001000000047497451305389404296875f);\n        float _1006 = clamp(1.0f - (_1000 * _1000), 0.0f, 1.0f);\n        float _1008;\n        if (front)\n        {\n            _1008 = _1006 * _1006;\n        }\n        else\n        {\n            _1008 = 0.0f;\n        }\n        atten = _1008;\n        bool _1019 = _799 < 2.5f;\n        if ((_799 > 1.5f) && _1019)\n        {\n            int param_22 = _783 + 2;\n            float4 _1027 = fa_light_texel(param_22);\n            float _1037 = _1027.w;\n            int param_23 = _783 + 3;\n            float4 _1042 = fa_light_texel(param_23);\n            float _1043 = _1042.x;\n            float cos_inner = _1043;\n            if (_1043 > 1.5f)\n            {\n                cos_inner = lerp(_1037, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1037, cos_inner, dot(-l, normalize(_1027.xyz)));\n        }\n        if (_787 && (_799 < 1.5f))\n        {\n            int param_24 = _783 + 6;\n            float4 _1067 = fa_light_texel(param_24);\n            if (_1067.z > 0.5f)\n            {\n                float3 _1075 = -to_light;\n                int param_25 = _783 + 4;\n                int param_26 = _783 + 5;\n                float3 _1089 = fa_light_texel(param_25).xyz;\n                float3 _1093 = fa_light_texel(param_26).xyz;\n                float3 _1102 = float3(dot(_1075, _1089), dot(_1075, _1093), dot(_1075, cross(_1089, _1093)));\n                float3 param_27 = _1102;\n                int _1106 = fa_cube_face(param_27);\n                int param_28 = _1106;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1133 = float2(dot(_1102, cross(param_29, param_30)), dot(_1102, param_30)) / max(dot(_1102, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1137 = _1106 / 3;\n                float2 param_31 = _1067.xy + (float2(float(_1106 - (_1137 * 3)), float(_1137)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1133.x), 0.5f - (0.5f * _1133.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _783 + 7;\n            float4 _1167 = fa_light_texel(param_33);\n            if (_1167.z > 0.5f)\n            {\n                int param_34 = _783 + 2;\n                int param_35 = _783 + 4;\n                int param_36 = _783 + 5;\n                float2 param_37 = _1167.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_787 && _1019)\n            {\n                int param_42 = _783 + 6;\n                float4 _1214 = fa_light_texel(param_42);\n                int param_43 = _783 + 7;\n                float4 _1219 = fa_light_texel(param_43);\n                bool _1222 = _1214.z > 0.5f;\n                bool _1229;\n                if (!_1222)\n                {\n                    _1229 = _1219.z > 0.5f;\n                }\n                else\n                {\n                    _1229 = _1222;\n                }\n                if (_1229)\n                {\n                    int param_44 = _783 + 2;\n                    float4 _1236 = fa_light_texel(param_44);\n                    float3 _1240 = normalize(_1236.xyz);\n                    int param_45 = _783 + 4;\n                    float4 _1245 = fa_light_texel(param_45);\n                    int param_46 = _783 + 5;\n                    float4 _1250 = fa_light_texel(param_46);\n                    if (_1222)\n                    {\n                        float3 _1258 = -to_light;\n                        float _1265 = _1236.w;\n                        float _1281 = 0.5f / max(dot(_1258, _1240) * (sqrt(max(1.0f - (_1265 * _1265), 0.0f)) / max(_1265, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1214.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1258, _1245.xyz) * _1281), 0.5f - (dot(_1258, _1250.xyz) * _1281));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1219.z > 0.5f)\n                    {\n                        float2 param_49 = _1219.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1240;\n                        float3 param_52 = _1245.xyz;\n                        float3 param_53 = _1250.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6282 = _796.xyz * atten;\n    if (_787)\n    {\n        _6282 *= fa_light_tint;\n    }\n    int _1349;\n    if (_813)\n    {\n        _1349 = 0;\n    }\n    else\n    {\n        _1349 = ((_799 > 1.5f) && (_799 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _6293 = { l, _6282, atten, 1.0f, dist, _1349 };\n    return _6293;\n}\n\nfloat fa_rt_local_tap(int2 p, int2 size, float d, float tol, float div, inout float best)\n{\n    float4 _3310 = fa_screen_tex.Load(int3(clamp(p, int2(0, 0), size - int2(1, 1)), 0));\n    bool _3313 = _3310.w > 0.5f;\n    bool _3323;\n    if (_3313)\n    {\n        _3323 = abs(d - _3310.x) <= tol;\n    }\n    else\n    {\n        _3323 = _3313;\n    }\n    if (_3323)\n    {\n        best = min(best, mod(floor(_3310.z / div), 256.0f) * 0.0039215688593685626983642578125f);\n    }\n    return best;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2138 = fa_shadow_depth(param, param_1);\n    float _2142;\n    if (conv.x < 0.5f)\n    {\n        _2142 = _2138;\n    }\n    else\n    {\n        _2142 = (conv.y * conv.z) / (conv.z - (_2138 * (conv.z - conv.y)));\n    }\n    return _2142;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2188 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2194 = float2(cos(_2188), sin(_2188));\n    float2 dir = _2194;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2203;\n        if (k < 0.0f)\n        {\n            _2203 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2203 = k;\n        }\n        float _2222 = clamp((_2203 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2241 = sqrt((float(i) + 0.5f) * 0.0625f) * _2222;\n            float2 param_3 = uv + (dir * (_2091_fa_shadow_bias.zw * _2241));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2255 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2255 < (zr - (_2241 * plane)))\n            {\n                sum += _2255;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2283 = sum / cnt;\n        float _2293;\n        if (k < 0.0f)\n        {\n            _2293 = (-k) / max(_2283, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2293 = k;\n        }\n        radius = clamp(((max(zr - _2283, 0.0f) * unit) * _2293) / texel_m, 1.5f, 16.0f);\n        dir = _2194;\n    }\n    float lit = 0.0f;\n    int _2319 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2319; i_1++)\n    {\n        float _2338 = sqrt((float(i_1) + 0.5f) / float(_2319)) * radius;\n        float2 param_7 = uv + (dir * (_2091_fa_shadow_bias.zw * _2338));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2338 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2319);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2543 = _439_fa_pbr.z < 0.5f;\n    bool _2550;\n    if (!_2543)\n    {\n        _2550 = _2091_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2550 = _2543;\n    }\n    if (_2550)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2091_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2563 = fa_light_texel(param);\n    float _2564 = _2563.x;\n    if (_2564 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2573 = int(_2564 + 0.5f);\n    int param_1 = _2573;\n    float4 _2577 = fa_light_texel(param_1);\n    int param_2 = _2573 + 1;\n    float4 _2582 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2585 = _2577.y;\n    if (_2585 > 0.0f)\n    {\n        float _2602 = 1.0f - smoothstep(0.75f * _2585, _2585, length(world - _2091_fa_shadow_eye.xyz));\n        fade = _2602;\n        if (_2602 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2577.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2626 = (_2573 + 2) + (face * 6);\n    int param_4 = _2626;\n    int param_5 = _2626 + 1;\n    int param_6 = _2626 + 3;\n    float4 _2640 = fa_light_texel(param_6);\n    int param_7 = _2626 + 4;\n    float4 _2645 = fa_light_texel(param_7);\n    int param_8 = _2626 + 5;\n    float4 _2650 = fa_light_texel(param_8);\n    float _2662 = _2650.x * max(dot(_2640, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2667 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2690 = clamp(dot(n, _2640.xyz), -1.0f, 1.0f);\n    float _2709 = min(sqrt(1.0f - (_2690 * _2690)) / max(abs(dot(n, world - lpos)) / max(dot(_2640, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2712 = _2582.y;\n    float _2714;\n    if (_2712 > 0.0f)\n    {\n        _2714 = _2712;\n    }\n    else\n    {\n        _2714 = 1.5f * _2662;\n    }\n    float4 _2734 = float4(world + (n * (_2714 * sqrt(1.0f - (_2667 * _2667)))), 1.0f);\n    float _2738 = dot(_2640, _2734);\n    float _2741 = _2650.y;\n    if (_2738 < _2741)\n    {\n        return 1.0f;\n    }\n    float2 _2756 = float2(dot(fa_light_texel(param_4), _2734), dot(fa_light_texel(param_5), _2734)) / _2738.xx;\n    float _2758 = _2756.x;\n    bool _2761 = _2758 < _2645.x;\n    bool _2770;\n    if (!_2761)\n    {\n        _2770 = _2758 > _2645.z;\n    }\n    else\n    {\n        _2770 = _2761;\n    }\n    bool _2779;\n    if (!_2770)\n    {\n        _2779 = _2756.y < _2645.y;\n    }\n    else\n    {\n        _2779 = _2770;\n    }\n    bool _2788;\n    if (!_2779)\n    {\n        _2788 = _2756.y > _2645.w;\n    }\n    else\n    {\n        _2788 = _2779;\n    }\n    if (_2788)\n    {\n        return 1.0f;\n    }\n    float _2794 = _2582.x;\n    float _2796;\n    if (_2794 > 0.0f)\n    {\n        _2796 = _2794;\n    }\n    else\n    {\n        _2796 = 1.5f * _2662;\n    }\n    float2 param_9 = _2756;\n    float4 param_10 = _2645;\n    float param_11 = _2738 - (_2796 * (1.0f + (0.5f * _2709)));\n    float param_12 = _2662;\n    float param_13 = 1.0f;\n    float param_14 = _2650.z * 0.25f;\n    float param_15 = (_2662 * min(_2709, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2741, _2650.z);\n    int param_17 = int(_2577.z + 0.5f);\n    float param_18 = _2577.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _3341 = _439_fa_ct_b.w > 0.5f;\n    bool _3347;\n    if (_3341)\n    {\n        _3347 = _439_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3347 = _3341;\n    }\n    bool _3353;\n    if (_3347)\n    {\n        _3353 = _2091_fa_shadow_lcfg.x > 0.5f;\n    }\n    else\n    {\n        _3353 = _3347;\n    }\n    if (_3353)\n    {\n        int param = (int(_2091_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n        float4 _3365 = fa_light_texel(param);\n        float _3366 = _3365.z;\n        if (_3366 > 0.5f)\n        {\n            float _3379 = dot(_439_fa_ct_fwd.xyz, world) + _439_fa_ct_fwd.w;\n            float _3385 = ((0.00200000009499490261077880859375f * _3379) + 0.00999999977648258209228515625f) + fa_rt_slope;\n            float4 _3391 = float4(world, 1.0f);\n            float _3396 = dot(_439_fa_ct_vpw, _3391);\n            if (_3396 > 9.9999997473787516355514526367188e-05f)\n            {\n                float2 _3413 = float2(dot(_439_fa_ct_vpx, _3391), dot(_439_fa_ct_vpy, _3391)) / _3396.xx;\n                float _3418 = (_3413.x * 0.5f) + 0.5f;\n                float _3422;\n                if (_439_fa_ct_a.y > 0.5f)\n                {\n                    _3422 = (_3413.y * 0.5f) + 0.5f;\n                }\n                else\n                {\n                    _3422 = 0.5f - (_3413.y * 0.5f);\n                }\n                bool _3438 = _3418 >= 0.0f;\n                bool _3444;\n                if (_3438)\n                {\n                    _3444 = _3418 < 1.0f;\n                }\n                else\n                {\n                    _3444 = _3438;\n                }\n                bool _3450;\n                if (_3444)\n                {\n                    _3450 = _3422 >= 0.0f;\n                }\n                else\n                {\n                    _3450 = _3444;\n                }\n                bool _3456;\n                if (_3450)\n                {\n                    _3456 = _3422 < 1.0f;\n                }\n                else\n                {\n                    _3456 = _3450;\n                }\n                if (_3456)\n                {\n                    int2 _3463 = int2(_439_fa_ct_a.zw);\n                    int2 _3474 = clamp(int2(float2(_3418, _3422) * _439_fa_ct_a.zw), int2(0, 0), _3463 - int2(1, 1));\n                    float _3478;\n                    if (_3366 < 1.5f)\n                    {\n                        _3478 = 1.0f;\n                    }\n                    else\n                    {\n                        _3478 = (_3366 < 2.5f) ? 256.0f : 65536.0f;\n                    }\n                    float best = 2.0f;\n                    float4 _3494 = fa_screen_tex.Load(int3(_3474, 0));\n                    bool _3497 = _3494.w > 0.5f;\n                    bool _3507;\n                    if (_3497)\n                    {\n                        _3507 = abs(_3379 - _3494.x) <= _3385;\n                    }\n                    else\n                    {\n                        _3507 = _3497;\n                    }\n                    if (_3507)\n                    {\n                        best = mod(floor(_3494.z / _3478), 256.0f) * 0.0039215688593685626983642578125f;\n                    }\n                    else\n                    {\n                        int2 param_1 = _3474 + int2(-1, -1);\n                        int2 param_2 = _3463;\n                        float param_3 = _3379;\n                        float param_4 = _3385;\n                        float param_5 = _3478;\n                        float param_6 = best;\n                        float _3533 = fa_rt_local_tap(param_1, param_2, param_3, param_4, param_5, param_6);\n                        best = _3533;\n                        int2 param_7 = _3474 + int2(0, -1);\n                        int2 param_8 = _3463;\n                        float param_9 = _3379;\n                        float param_10 = _3385;\n                        float param_11 = _3478;\n                        float param_12 = _3533;\n                        float _3548 = fa_rt_local_tap(param_7, param_8, param_9, param_10, param_11, param_12);\n                        best = _3548;\n                        int2 param_13 = _3474 + int2(1, -1);\n                        int2 param_14 = _3463;\n                        float param_15 = _3379;\n                        float param_16 = _3385;\n                        float param_17 = _3478;\n                        float param_18 = _3548;\n                        float _3563 = fa_rt_local_tap(param_13, param_14, param_15, param_16, param_17, param_18);\n                        best = _3563;\n                        int2 param_19 = _3474 + int2(-1, 0);\n                        int2 param_20 = _3463;\n                        float param_21 = _3379;\n                        float param_22 = _3385;\n                        float param_23 = _3478;\n                        float param_24 = _3563;\n                        float _3578 = fa_rt_local_tap(param_19, param_20, param_21, param_22, param_23, param_24);\n                        best = _3578;\n                        int2 param_25 = _3474 + int2(1, 0);\n                        int2 param_26 = _3463;\n                        float param_27 = _3379;\n                        float param_28 = _3385;\n                        float param_29 = _3478;\n                        float param_30 = _3578;\n                        float _3593 = fa_rt_local_tap(param_25, param_26, param_27, param_28, param_29, param_30);\n                        best = _3593;\n                        int2 param_31 = _3474 + int2(-1, 1);\n                        int2 param_32 = _3463;\n                        float param_33 = _3379;\n                        float param_34 = _3385;\n                        float param_35 = _3478;\n                        float param_36 = _3593;\n                        float _3608 = fa_rt_local_tap(param_31, param_32, param_33, param_34, param_35, param_36);\n                        best = _3608;\n                        int2 param_37 = _3474 + int2(0, 1);\n                        int2 param_38 = _3463;\n                        float param_39 = _3379;\n                        float param_40 = _3385;\n                        float param_41 = _3478;\n                        float param_42 = _3608;\n                        float _3623 = fa_rt_local_tap(param_37, param_38, param_39, param_40, param_41, param_42);\n                        best = _3623;\n                        int2 param_43 = _3474 + int2(1, 1);\n                        int2 param_44 = _3463;\n                        float param_45 = _3379;\n                        float param_46 = _3385;\n                        float param_47 = _3478;\n                        float param_48 = _3623;\n                        float _3638 = fa_rt_local_tap(param_43, param_44, param_45, param_46, param_47, param_48);\n                        best = _3638;\n                    }\n                    if (best <= 1.0f)\n                    {\n                        float _3646;\n                        if (_439_fa_ct_b.z > 0.5f)\n                        {\n                            int param_49 = li;\n                            float3 param_50 = lpos;\n                            float3 param_51 = world;\n                            float3 param_52 = n;\n                            float3 param_53 = l;\n                            _3646 = min(best, fa_shadow_local(param_49, param_50, param_51, param_52, param_53));\n                        }\n                        else\n                        {\n                            _3646 = best;\n                        }\n                        return _3646;\n                    }\n                }\n            }\n            float _3669;\n            if (_439_fa_ct_b.z > 0.5f)\n            {\n                int param_54 = li;\n                float3 param_55 = lpos;\n                float3 param_56 = world;\n                float3 param_57 = n;\n                float3 param_58 = l;\n                _3669 = fa_shadow_local(param_54, param_55, param_56, param_57, param_58);\n            }\n            else\n            {\n                _3669 = 1.0f;\n            }\n            return _3669;\n        }\n    }\n    int param_59 = li;\n    float3 param_60 = lpos;\n    float3 param_61 = world;\n    float3 param_62 = n;\n    float3 param_63 = l;\n    return fa_shadow_local(param_59, param_60, param_61, param_62, param_63);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2081;\n    if (i == 0)\n    {\n        _2081 = _2091_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2097;\n        if (i == 1)\n        {\n            _2097 = _2091_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2105;\n            if (i == 2)\n            {\n                _2105 = _2091_fa_shadow_split.z;\n            }\n            else\n            {\n                _2105 = _2091_fa_shadow_split.w;\n            }\n            _2097 = _2105;\n        }\n        _2081 = _2097;\n    }\n    return _2081;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2384 = max(_2091_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2389 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2395 = sqrt(1.0f - (_2389 * _2389));\n    float _2403 = min(_2395 / max(_2389, 0.20000000298023223876953125f), 4.0f);\n    float _2408;\n    if (_2091_fa_shadow_bias.y > 0.0f)\n    {\n        _2408 = _2091_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2408 = 1.5f * _2091_fa_shadow_info[ci].x;\n    }\n    float4 _2433 = mul(float4(world + (n * (_2408 * _2395)), 1.0f), _2091_fa_shadow_mat[ci]);\n    float _2440 = _2433.x;\n    bool _2443 = _2440 < _2091_fa_shadow_rect[ci].x;\n    bool _2452;\n    if (!_2443)\n    {\n        _2452 = _2440 > _2091_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2452 = _2443;\n    }\n    bool _2461;\n    if (!_2452)\n    {\n        _2461 = _2433.y < _2091_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2461 = _2452;\n    }\n    bool _2470;\n    if (!_2461)\n    {\n        _2470 = _2433.y > _2091_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2470 = _2461;\n    }\n    bool _2477;\n    if (!_2470)\n    {\n        _2477 = _2433.z > 1.0f;\n    }\n    else\n    {\n        _2477 = _2470;\n    }\n    if (_2477)\n    {\n        return -1.0f;\n    }\n    float _2485;\n    if (_2091_fa_shadow_bias.x > 0.0f)\n    {\n        _2485 = _2091_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2485 = 1.5f * _2091_fa_shadow_info[ci].x;\n    }\n    float2 param = _2433.xy;\n    float4 param_1 = _2091_fa_shadow_rect[ci];\n    float param_2 = _2433.z - ((_2485 * (1.0f + (0.5f * _2403))) / _2384);\n    float param_3 = _2091_fa_shadow_info[ci].x;\n    float param_4 = _2384;\n    float param_5 = _2384 * 0.25f;\n    float param_6 = ((_2091_fa_shadow_info[ci].x * min(_2403, 3.0f)) * 0.5f) / _2384;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2091_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2091_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_439_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2863 = int(_2091_fa_shadow_cfg.x + 0.5f);\n    if (_2863 < 1)\n    {\n        return 1.0f;\n    }\n    float _2878 = dot(world - _2091_fa_shadow_eye.xyz, _2091_fa_shadow_fwd.xyz);\n    int param = _2863 - 1;\n    if (_2878 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2890 = _2863 > 1;\n    bool _2897;\n    if (_2890)\n    {\n        _2897 = _2878 > _2091_fa_shadow_split.x;\n    }\n    else\n    {\n        _2897 = _2890;\n    }\n    if (_2897)\n    {\n        ci = 1;\n    }\n    bool _2901 = _2863 > 2;\n    bool _2908;\n    if (_2901)\n    {\n        _2908 = _2878 > _2091_fa_shadow_split.y;\n    }\n    else\n    {\n        _2908 = _2901;\n    }\n    if (_2908)\n    {\n        ci = 2;\n    }\n    bool _2912 = _2863 > 3;\n    bool _2919;\n    if (_2912)\n    {\n        _2919 = _2878 > _2091_fa_shadow_split.z;\n    }\n    else\n    {\n        _2919 = _2912;\n    }\n    if (_2919)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _2930 = min(_2863, 4);\n    float _2971;\n    for (int c = ci; c < _2930; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2950 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _2950;\n            break;\n        }\n        if (_2950 < 0.0f)\n        {\n            continue;\n        }\n        s = _2950;\n        ci = c;\n        if (_2091_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2971 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2971 = _2091_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _2990 = _2091_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2971, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_2878 - (fa_shadow_split_at(param_7) - _2990)) / _2990, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3022;\n        if ((ci + 1) < _2863)\n        {\n            _3022 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3022 = 1.0f;\n        }\n        s = lerp(s, _3022, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    bool _3127 = _439_fa_ct_b.y > 0.5f;\n    bool _3133;\n    if (_3127)\n    {\n        _3133 = _439_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3133 = _3127;\n    }\n    if (_3133)\n    {\n        float _3147 = dot(_439_fa_ct_fwd.xyz, fa_world_pos) + _439_fa_ct_fwd.w;\n        float4 _3155 = float4(fa_world_pos, 1.0f);\n        float _3161 = dot(_439_fa_ct_vpw, _3155);\n        if (_3161 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _3180 = float2(dot(_439_fa_ct_vpx, _3155), dot(_439_fa_ct_vpy, _3155)) / _3161.xx;\n            float _3185 = (_3180.x * 0.5f) + 0.5f;\n            float _3189;\n            if (_439_fa_ct_a.y > 0.5f)\n            {\n                _3189 = (_3180.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _3189 = 0.5f - (_3180.y * 0.5f);\n            }\n            bool _3205 = _3185 >= 0.0f;\n            bool _3211;\n            if (_3205)\n            {\n                _3211 = _3185 < 1.0f;\n            }\n            else\n            {\n                _3211 = _3205;\n            }\n            bool _3217;\n            if (_3211)\n            {\n                _3217 = _3189 >= 0.0f;\n            }\n            else\n            {\n                _3217 = _3211;\n            }\n            bool _3223;\n            if (_3217)\n            {\n                _3223 = _3189 < 1.0f;\n            }\n            else\n            {\n                _3223 = _3217;\n            }\n            if (_3223)\n            {\n                float4 _3248 = fa_screen_tex.Load(int3(clamp(int2(float2(_3185, _3189) * _439_fa_ct_a.zw), int2(0, 0), int2(_439_fa_ct_a.zw) - int2(1, 1)), 0));\n                bool _3251 = _3248.w > 0.5f;\n                bool _3267;\n                if (_3251)\n                {\n                    _3267 = abs(_3147 - _3248.x) <= (((0.00200000009499490261077880859375f * _3147) + 0.00999999977648258209228515625f) + fa_rt_slope);\n                }\n                else\n                {\n                    _3267 = _3251;\n                }\n                if (_3267)\n                {\n                    float _3273;\n                    if (_439_fa_ct_b.z > 0.5f)\n                    {\n                        float3 param = fa_world_pos;\n                        float3 param_1 = n;\n                        float3 param_2 = l;\n                        _3273 = min(_3248.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3273 = _3248.y;\n                    }\n                    return _3273;\n                }\n            }\n        }\n    }\n    float3 param_3 = fa_world_pos;\n    float3 param_4 = n;\n    float3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4040 = _439_fa_ct_a.x < 0.5f;\n    bool _4047;\n    if (!_4040)\n    {\n        _4047 = _2091_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4047 = _4040;\n    }\n    if (_4047)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2091_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4060 = fa_light_texel(param);\n    float _4061 = _4060.y;\n    float len = _4061;\n    if (_4061 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4073 = length(world - _439_fa_camera_pos.xyz);\n    float _4082 = 1.0f - smoothstep(0.5f * _439_fa_ct_b.x, _439_fa_ct_b.x, _4073);\n    if (_4082 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4088 = len;\n    float _4091 = min(_4088, 0.89999997615814208984375f * dist);\n    len = _4091;\n    float _4097 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4073);\n    float _4102 = _4097 + (0.5f * _4091);\n    float3 _4108 = world + (gn * _4097);\n    float _4110 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4172;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4126 = (float(k) + _4110) * 0.083333335816860198974609375f;\n        float3 _4134 = _4108 + (l * (_4126 * len));\n        float4 _4140 = float4(_4134, 1.0f);\n        float _4145 = dot(_439_fa_ct_vpw, _4140);\n        if (_4145 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4163 = float2(dot(_439_fa_ct_vpx, _4140), dot(_439_fa_ct_vpy, _4140)) / _4145.xx;\n        float _4167 = _4163.x * 0.5f;\n        float _4168 = _4167 + 0.5f;\n        if (_439_fa_ct_a.y > 0.5f)\n        {\n            _4172 = (_4163.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4172 = 0.5f - (_4163.y * 0.5f);\n        }\n        bool _4188 = _4168 < 0.0f;\n        bool _4195;\n        if (!_4188)\n        {\n            _4195 = _4168 >= 1.0f;\n        }\n        else\n        {\n            _4195 = _4188;\n        }\n        bool _4202;\n        if (!_4195)\n        {\n            _4202 = _4172 < 0.0f;\n        }\n        else\n        {\n            _4202 = _4195;\n        }\n        bool _4209;\n        if (!_4202)\n        {\n            _4209 = _4172 >= 1.0f;\n        }\n        else\n        {\n            _4209 = _4202;\n        }\n        if (_4209)\n        {\n            break;\n        }\n        float4 _4233 = fa_screen_tex.Load(int3(clamp(int2(float2(_4168, _4172) * _439_fa_ct_a.zw), int2(0, 0), int2(_439_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_4233.w < 0.5f)\n        {\n            continue;\n        }\n        float _4251 = (dot(_439_fa_ct_fwd.xyz, _4134) + _439_fa_ct_fwd.w) - _4233.x;\n        if ((_4251 > _4097) && (_4251 < _4102))\n        {\n            occ = max(occ, (1.0f - (_4126 * _4126)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4168, 0.5f - _4167), min(_4172, 1.0f - _4172))));\n        }\n    }\n    return 1.0f - (occ * _4082);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4383 = fa_baked_keep(param);\n    if (_4383 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _6306 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6306;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4409 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6308 = _4409.color;\n    float _6309 = _4409.attenuation;\n    float _6310 = _4409.shadow;\n    bool _4412 = _4409.type == 0;\n    if (_4412 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4409.direction;\n        float _4423 = fa_shadow_factor(param_5, param_6);\n        _6310 = _4423;\n        _6308 *= _4423;\n    }\n    else\n    {\n        bool _4434 = _4409.type != 0;\n        bool _4440;\n        if (_4434)\n        {\n            _4440 = _6309 > 0.0f;\n        }\n        else\n        {\n            _4440 = _4434;\n        }\n        if (_4440)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4409.direction;\n            float _4459 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6310 = _4459;\n            _6308 *= _4459;\n        }\n    }\n    bool _4469 = _439_fa_ct_a.x > 0.5f;\n    bool _4475;\n    if (_4469)\n    {\n        _4475 = _6309 > 0.0f;\n    }\n    else\n    {\n        _4475 = _4469;\n    }\n    if (_4475)\n    {\n        float _4482;\n        if (_4412)\n        {\n            _4482 = 1000000000.0f;\n        }\n        else\n        {\n            _4482 = _4409._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4409.direction;\n        float param_18 = _4482;\n        float _4500 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6310 *= _4500;\n        _6308 *= _4500;\n    }\n    float _4513 = _6309;\n    float _4514 = _4513 * _4383;\n    _6309 = _4514;\n    float3 _4518 = _6308;\n    float3 _4519 = _4518 * _4383;\n    _6308 = _4519;\n    LightSample _6325 = { _4409.direction, _4519, _4514, _6310, _4409._distance, _4409.type };\n    return _6325;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2091_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3050 = int(_2091_fa_shadow_cfg.x + 0.5f);\n    float _3060 = dot(world - _2091_fa_shadow_eye.xyz, _2091_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3065 = _3050 > 0;\n    bool _3074;\n    if (_3065)\n    {\n        int param = _3050 - 1;\n        _3074 = _3060 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3074 = _3065;\n    }\n    if (_3074)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3080 = _3050 > 1;\n        bool _3087;\n        if (_3080)\n        {\n            _3087 = _3060 > _2091_fa_shadow_split.x;\n        }\n        else\n        {\n            _3087 = _3080;\n        }\n        if (_3087)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3093 = _3050 > 2;\n        bool _3100;\n        if (_3093)\n        {\n            _3100 = _3060 > _2091_fa_shadow_split.y;\n        }\n        else\n        {\n            _3100 = _3093;\n        }\n        if (_3100)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3106 = _3050 > 3;\n        bool _3113;\n        if (_3106)\n        {\n            _3113 = _3060 > _2091_fa_shadow_split.z;\n        }\n        else\n        {\n            _3113 = _3106;\n        }\n        if (_3113)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_rt_slope = 0.0f;\n    fa_inst_load();\n    float3 _6100 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6100 = -_6100;\n    }\n    float3 _5674 = normalize(_439_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _6113 = { fa_world_pos, _6100, fa_world_tangent, fa_uv, fa_vertex_color, _5674, gl_FrontFacing };\n    SurfaceInput param_1 = _6113;\n    Surface _5682 = fa_standard_surface(param_1);\n    float3 _6139 = _5682.albedo;\n    float _6140 = _5682.alpha;\n    float3 _6141 = _5682.normal;\n    float _6142 = _5682.metallic;\n    float _6143 = _5682.roughness;\n    float _6144 = _5682.occlusion;\n    float3 _6145 = _5682.emission;\n    float _6146 = _5682.clearcoat;\n    float _6147 = _5682.clearcoat_roughness;\n    float3 _6148 = _5682.sheen_color;\n    float _6149 = _5682.sheen_roughness;\n    float _6150 = _5682.anisotropy;\n    float _6151 = _5682.anisotropy_rotation;\n    float _6152 = _5682.specular;\n    float _6153 = _5682.ior;\n    float3 _6154 = _5682.specular_color;\n    float _6155 = _5682.transmission;\n    float _6156 = _5682.thickness;\n    float3 _6157 = _5682.attenuation_color;\n    float _6158 = _5682.attenuation_distance;\n    SurfaceInput _6121 = { fa_world_pos, _6100, fa_world_tangent, fa_uv, fa_vertex_color, _5674, gl_FrontFacing };\n    SurfaceInput param_2 = _6121;\n    Surface param_3 = _5682;\n    surface(param_2, param_3);\n    _6139 = param_3.albedo;\n    _6140 = param_3.alpha;\n    _6141 = param_3.normal;\n    _6142 = param_3.metallic;\n    _6143 = param_3.roughness;\n    _6144 = param_3.occlusion;\n    _6145 = param_3.emission;\n    _6146 = param_3.clearcoat;\n    _6147 = param_3.clearcoat_roughness;\n    _6148 = param_3.sheen_color;\n    _6149 = param_3.sheen_roughness;\n    _6150 = param_3.anisotropy;\n    _6151 = param_3.anisotropy_rotation;\n    _6152 = param_3.specular;\n    _6153 = param_3.ior;\n    _6154 = param_3.specular_color;\n    _6155 = param_3.transmission;\n    _6156 = param_3.thickness;\n    _6157 = param_3.attenuation_color;\n    _6158 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _6100;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6139 = param_6;\n    _6141 = param_7;\n    float3 result;\n    if (_439_fa_emissive.w > 0.5f)\n    {\n        result = _6139;\n    }\n    else\n    {\n        float3 _5721 = _6141;\n        float3 _5722 = normalize(_5721);\n        _6141 = _5722;\n        float3 param_8 = _5722;\n        SurfaceInput _6129 = { fa_world_pos, _6100, fa_world_tangent, fa_uv, fa_vertex_color, _5674, gl_FrontFacing };\n        SurfaceInput param_9 = _6129;\n        Surface _6240 = { _6139, _6140, _6141, _6142, _6143, _6144, _6145, _6146, _6147, _6148, _6149, _6150, _6151, _6152, _6153, _6154, _6155, _6156, _6157, _6158 };\n        Surface param_10 = _6240;\n        float3 param_11 = fa_indirect_diffuse(param_8);\n        float3 lit = ambient(param_9, param_10, param_11);\n        int _5741 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5741; ln++)\n        {\n            int param_12 = ln;\n            int _5754 = fa_cl_light(param_12);\n            int param_13 = _5754;\n            if (fa_baked_keep(param_13) <= 0.0f)\n            {\n                continue;\n            }\n            int param_14 = _5754;\n            float3 param_15 = fa_world_pos;\n            float3 param_16 = _6100;\n            LightSample _5770 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput _6137 = { fa_world_pos, _6100, fa_world_tangent, fa_uv, fa_vertex_color, _5674, gl_FrontFacing };\n            SurfaceInput param_17 = _6137;\n            Surface _6261 = { _6139, _6140, _6141, _6142, _6143, _6144, _6145, _6146, _6147, _6148, _6149, _6150, _6151, _6152, _6153, _6154, _6155, _6156, _6157, _6158 };\n            Surface param_18 = _6261;\n            LightSample param_19 = _5770;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    float3 _5785 = result;\n    float3 _5786 = _5785 + _6145;\n    result = _5786;\n    float3 param_20 = _5786;\n    float3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _5795 = _439_fa_fog.w > 0.0f;\n    bool _5802;\n    if (!_5795)\n    {\n        _5802 = _439_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5802 = _5795;\n    }\n    if (_5802)\n    {\n        float3 _5811 = fa_world_pos - _439_fa_camera_pos.xyz;\n        float _5817 = dot(_5811, _439_fa_fog_c.xyz);\n        bool _5821 = _439_fa_fog_c.w > 0.5f;\n        float _5822;\n        if (_5821)\n        {\n            _5822 = _5817;\n        }\n        else\n        {\n            _5822 = length(_5811);\n        }\n        float _5834 = _5822 - _439_fa_fog_b.x;\n        if (_5834 > 0.0f)\n        {\n            float _5843 = _439_fa_fog.w * _5834;\n            float tau = _5843 * _5843;\n            if (_439_fa_fog_b.y > 0.0f)\n            {\n                float _5859;\n                if (_5821)\n                {\n                    _5859 = fa_world_pos.y - (_439_fa_fog_c.y * _5817);\n                }\n                else\n                {\n                    _5859 = _439_fa_camera_pos.y;\n                }\n                float _5880 = lerp(_5859, fa_world_pos.y, clamp(_439_fa_fog_b.x / _5822, 0.0f, 1.0f));\n                float _5884 = fa_world_pos.y - _5880;\n                float _5889 = _5880 - _439_fa_fog_b.z;\n                float _5894 = fa_world_pos.y - _439_fa_fog_b.z;\n                bool _5897 = _5889 <= 0.0f;\n                bool _5898 = !_5897;\n                bool _5904;\n                if (_5898)\n                {\n                    _5904 = _439_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5904 = _5897;\n                }\n                float _5905;\n                if (_5904)\n                {\n                    _5905 = _439_fa_fog_b.y;\n                }\n                else\n                {\n                    _5905 = _439_fa_fog_b.y * exp(-min(_439_fa_fog_b.w * _5889, 80.0f));\n                }\n                bool _5932;\n                if (_5898)\n                {\n                    _5932 = _439_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5932 = _5897;\n                }\n                float _5933;\n                if (_5932)\n                {\n                    _5933 = _439_fa_fog_b.y * _5889;\n                }\n                else\n                {\n                    _5933 = (_439_fa_fog_b.y * (1.0f - exp(-min(_439_fa_fog_b.w * _5889, 80.0f)))) / _439_fa_fog_b.w;\n                }\n                bool _5958 = _5894 <= 0.0f;\n                bool _5965;\n                if (!_5958)\n                {\n                    _5965 = _439_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5965 = _5958;\n                }\n                float _5966;\n                if (_5965)\n                {\n                    _5966 = _439_fa_fog_b.y * _5894;\n                }\n                else\n                {\n                    _5966 = (_439_fa_fog_b.y * (1.0f - exp(-min(_439_fa_fog_b.w * _5894, 80.0f)))) / _439_fa_fog_b.w;\n                }\n                float _5993;\n                if (abs(_5884) < 0.001000000047497451305389404296875f)\n                {\n                    _5993 = _5905;\n                }\n                else\n                {\n                    _5993 = (_5966 - _5933) / _5884;\n                }\n                tau += (_5834 * max(_5993, 0.0f));\n            }\n            result = lerp(result, _439_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _6140);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_439",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2091",
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
