{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "57cbd5df71b0000e548dcd5fbfe873bc15510a64a336f6248792368f21adbf33",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _260 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _260;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_267, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _395_fa_camera_pos : packoffset(c0);\n    float4 _395_fa_ambient : packoffset(c1);\n    float4 _395_fa_base_color : packoffset(c2);\n    float4 _395_fa_emissive : packoffset(c3);\n    float4 _395_fa_model_emissive : packoffset(c4);\n    float4 _395_fa_pbr : packoffset(c5);\n    float4 _395_fa_maps : packoffset(c6);\n    float4 _395_fa_fog : packoffset(c7);\n    float4 _395_fa_fog_b : packoffset(c8);\n    float4 _395_fa_fog_c : packoffset(c9);\n    float4 _395_fa_counts : packoffset(c10);\n    float4 _395_fa_env_sky : packoffset(c11);\n    float4 _395_fa_env_horizon : packoffset(c12);\n    float4 _395_fa_time : packoffset(c13);\n    float4 _395_fa_cl_vpx : packoffset(c14);\n    float4 _395_fa_cl_vpy : packoffset(c15);\n    float4 _395_fa_cl_vpw : packoffset(c16);\n    float4 _395_fa_cl_fwd : packoffset(c17);\n    float4 _395_fa_cl_grid : packoffset(c18);\n    float4 _395_fa_cl_info : packoffset(c19);\n    float4 _395_fa_layers_a : packoffset(c20);\n    float4 _395_fa_layers_b : packoffset(c21);\n    float4 _395_fa_layers_c : packoffset(c22);\n    float4 _395_fa_layers_d : packoffset(c23);\n    float4 _395_fa_ct_a : packoffset(c24);\n    float4 _395_fa_ct_b : packoffset(c25);\n    float4 _395_fa_ct_vpx : packoffset(c26);\n    float4 _395_fa_ct_vpy : packoffset(c27);\n    float4 _395_fa_ct_vpw : packoffset(c28);\n    float4 _395_fa_ct_fwd : packoffset(c29);\n    float4 _395_fa_probe_sh[9] : packoffset(c30);\n    float4 _395_fa_atlas : packoffset(c39);\n    float4 _395_fa_rpa_tile : packoffset(c40);\n    float4 _395_fa_rpa_pos : packoffset(c41);\n    float4 _395_fa_rpa_bx : packoffset(c42);\n    float4 _395_fa_rpa_by : packoffset(c43);\n    float4 _395_fa_rpa_bz : packoffset(c44);\n    float4 _395_fa_rpb_tile : packoffset(c45);\n    float4 _395_fa_rpb_pos : packoffset(c46);\n    float4 _395_fa_rpb_bx : packoffset(c47);\n    float4 _395_fa_rpb_by : packoffset(c48);\n    float4 _395_fa_rpb_bz : packoffset(c49);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2052_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2052_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2052_fa_shadow_info[4] : packoffset(c20);\n    float4 _2052_fa_shadow_split : packoffset(c24);\n    float4 _2052_fa_shadow_cfg : packoffset(c25);\n    float4 _2052_fa_shadow_bias : packoffset(c26);\n    float4 _2052_fa_shadow_eye : packoffset(c27);\n    float4 _2052_fa_shadow_fwd : packoffset(c28);\n    float4 _2052_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1323 = _395_fa_cl_info.x < 0.0f;\n    bool _1330;\n    if (!_1323)\n    {\n        _1330 = _395_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1330 = _1323;\n    }\n    bool _1338;\n    if (!_1330)\n    {\n        _1338 = _395_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1338 = _1330;\n    }\n    bool _1345;\n    if (!_1338)\n    {\n        _1345 = _395_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1345 = _1338;\n    }\n    bool _1352;\n    if (!_1345)\n    {\n        _1352 = _395_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1352 = _1345;\n    }\n    if (_1352)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1362 = float4(world_pos, 1.0f);\n    float _1368 = dot(_395_fa_cl_vpw, _1362);\n    if (!(_1368 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1390 = float2(dot(_395_fa_cl_vpx, _1362), dot(_395_fa_cl_vpy, _1362)) / _1368.xx;\n    int _1394 = int(_395_fa_cl_grid.x);\n    int _1398 = int(_395_fa_cl_grid.y);\n    int param = (int(_395_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_395_fa_cl_fwd.xyz, world_pos) + _395_fa_cl_fwd.w, _395_fa_cl_grid.w) / _395_fa_cl_grid.w) * _395_fa_cl_grid.z)), 0, int(_395_fa_cl_info.y) - 1) * _1398) + clamp(int(floor(((_1390.y * 0.5f) + 0.5f) * _395_fa_cl_grid.y)), 0, _1398 - 1)) * _1394)) + clamp(int(floor(((_1390.x * 0.5f) + 0.5f) * _395_fa_cl_grid.x)), 0, _1394 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1474 = fa_cluster_texel(param);\n    return int2(int(_1474.x), int(_1474.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_395_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3650 = fa_cluster_lookup(param);\n    fa_cl_slot = _3650.x;\n    fa_cl_local = _3650.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3855 = fa_linear_to_srgb(param);\n        c = _3855;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3863 = fa_srgb_to_linear(param_1);\n            c = _3863;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _277;\n    if (i.front_facing)\n    {\n        _277 = i.world_normal;\n    }\n    else\n    {\n        _277 = -i.world_normal;\n    }\n    float3 _301 = normalize(i.world_tangent.xyz - (_277 * dot(_277, i.world_tangent.xyz)));\n    float3 _328 = normalize(((_301 * m.x) + ((cross(_277, _301) * i.world_tangent.w) * m.y)) + (_277 * m.z));\n    float3 _331;\n    if (i.front_facing)\n    {\n        _331 = _328;\n    }\n    else\n    {\n        _331 = -_328;\n    }\n    return _331;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _395_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3894 = fa_tex_fix(param_2, param_3);\n    float4 _4960 = base_t;\n    _4960.x = _3894.x;\n    _4960.y = _3894.y;\n    _4960.z = _3894.z;\n    base_t = _4960;\n    float4 _3908 = (_4960 * _395_fa_base_color) * i.vertex_color;\n    float3 _4812 = i.world_normal;\n    if (_395_fa_maps.z > 0.5f)\n    {\n        float param_4 = _395_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3940 = fa_tex_fix(param_6, param_7);\n        float3 _3943 = (_3940 * 2.0f) - 1.0f.xxx;\n        float2 _3948 = _3943.xy * _395_fa_maps.x;\n        float3 _4968 = _3943;\n        _4968.x = _3948.x;\n        _4968.y = _3948.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4968;\n        _4812 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _395_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3976 = fa_tex_fix(param_12, param_13);\n    float4 _4971 = mrt;\n    _4971.x = _3976.x;\n    _4971.y = _3976.y;\n    _4971.z = _3976.z;\n    mrt = _4971;\n    float4 _4004 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _395_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4004.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4015 = fa_tex_fix(param_16, param_17);\n    float param_18 = _395_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4045 = fa_tex_fix(param_20, param_21);\n    float _4817 = _395_fa_layers_a.x;\n    float _4818 = _395_fa_layers_a.y;\n    float _4821 = _395_fa_layers_a.z;\n    float _4820 = _395_fa_layers_b.w;\n    float _4823 = _395_fa_layers_c.x;\n    if (_395_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_395_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4817 *= _4015.y;\n            _4818 *= _4015.z;\n            _4820 *= _4004.w;\n        }\n        if (_395_fa_layers_c.z > 1.5f)\n        {\n            _4821 *= mrt.x;\n            _4823 *= mrt.w;\n        }\n    }\n    Surface _4842 = { _3908.xyz, _3908.w, _4812, clamp(_395_fa_pbr.x * _3976.z, 0.0f, 1.0f), clamp(_395_fa_pbr.y * _3976.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_395_fa_maps.y * (_4015.x - 1.0f)), _395_fa_emissive.xyz + (_395_fa_model_emissive.xyz * _4045), _4817, _4818, _395_fa_layers_b.xyz, _4820, _4821, _395_fa_layers_a.w, _4823, _395_fa_layers_c.y, _395_fa_layers_d.xyz };\n    return _4842;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1554 = rect.zw - rect.xy;\n    float2 _1558 = _1554 * atlas;\n    float2 _1562 = ddx * _1558;\n    float2 _1566 = ddy * _1558;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1554), clamp(0.5f * log2(max(max(dot(_1562, _1562), dot(_1566, _1566)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1599 = _395_fa_counts.y < 0.5f;\n    bool _1606;\n    if (!_1599)\n    {\n        _1606 = _395_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1606 = _1599;\n    }\n    if (_1606)\n    {\n        return;\n    }\n    float3 _1612 = ddx(world_pos);\n    float3 _1615 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1619 = fa_cluster_texel(param);\n    int _1623 = int(_1619.w);\n    if (_1623 < 1)\n    {\n        return;\n    }\n    int _1633 = int(_395_fa_counts.y + 0.5f);\n    int param_1 = _1633;\n    float4 _1637 = fa_light_texel(param_1);\n    float2 _1640 = _1637.yz;\n    int _1644 = int(_1637.w);\n    int param_2 = _1633 + 1;\n    float4 _1649 = fa_light_texel(param_2);\n    float _1650 = _1649.x;\n    int _1656 = int(_395_fa_counts.w + 0.5f) - 1;\n    int _1660 = int(_1619.z);\n    float3 _1925;\n    for (int k = 0; k < _1623; k++)\n    {\n        int _1673 = _1660 + k;\n        int param_3 = _1644 + (_1673 >> 2);\n        int _1690 = (_1633 + 2) + (int(fa_light_texel(param_3)[_1673 & 3]) * 7);\n        int param_4 = _1690 + 6;\n        float4 _1695 = fa_light_texel(param_4);\n        if (((int(_1695.w + 0.5f) >> _1656) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1690;\n        float4 _1710 = fa_light_texel(param_5);\n        int param_6 = _1690 + 1;\n        float4 _1715 = fa_light_texel(param_6);\n        int param_7 = _1690 + 2;\n        float4 _1720 = fa_light_texel(param_7);\n        float3 _1723 = _1710.xyz;\n        float _1728 = dot(_1723, world_pos) + _1710.w;\n        float3 _1730 = _1715.xyz;\n        float _1735 = dot(_1730, world_pos) + _1715.w;\n        float3 _1737 = _1720.xyz;\n        float _1742 = dot(_1737, world_pos) + _1720.w;\n        bool _1747 = abs(_1728) > 0.5f;\n        bool _1755;\n        if (!_1747)\n        {\n            _1755 = abs(_1735) > 0.5f;\n        }\n        else\n        {\n            _1755 = _1747;\n        }\n        bool _1763;\n        if (!_1755)\n        {\n            _1763 = abs(_1742) > 0.5f;\n        }\n        else\n        {\n            _1763 = _1755;\n        }\n        if (_1763)\n        {\n            continue;\n        }\n        float _1778 = clamp(dot(geo_normal, normalize(_1737)) * _1695.z, 0.0f, 1.0f);\n        if (_1778 <= 0.0f)\n        {\n            continue;\n        }\n        float _1798 = (clamp((0.5f - abs(_1742)) * 10.0f, 0.0f, 1.0f) * _1778) * _1695.x;\n        float2 _1806 = float2(_1728 + 0.5f, 0.5f - _1735);\n        float2 _1816 = float2(dot(_1723, _1612), dot(_1730, _1612));\n        float2 _1826 = float2(dot(_1723, _1615), dot(_1730, _1615));\n        int param_8 = _1690 + 5;\n        float4 _1831 = fa_light_texel(param_8);\n        int param_9 = _1690 + 3;\n        float4 _1836 = fa_light_texel(param_9);\n        int param_10 = _1690 + 4;\n        float4 _1841 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1831.xyz;\n        bool _1851 = _1836.z > _1836.x;\n        if (_1851)\n        {\n            float4 param_11 = _1836;\n            float2 param_12 = _1806;\n            float2 param_13 = _1640;\n            float2 param_14 = _1816;\n            float2 param_15 = _1826;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1650 > 0.5f) && (_1650 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1877 = fa_dc_to_linear(param_16);\n                float4 _4892 = tx;\n                _4892.x = _1877.x;\n                _4892.y = _1877.y;\n                _4892.z = _1877.z;\n                tx = _4892;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1798 * tex_a) * _1831.w, 0.0f, 1.0f).xxx);\n        if (_1841.z > _1841.x)\n        {\n            float4 param_17 = _1841;\n            float2 param_18 = _1806;\n            float2 param_19 = _1640;\n            float2 param_20 = _1816;\n            float2 param_21 = _1826;\n            float4 _1921 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1650 > 1.5f)\n            {\n                float3 param_22 = _1921.xyz;\n                float3 _1931 = fa_dc_to_srgb(param_22);\n                _1925 = _1931;\n            }\n            else\n            {\n                _1925 = _1921.xyz;\n            }\n            float3 _1940 = (_1925 * 2.0f) - 1.0f.xxx;\n            float2 _1945 = _1940.xy * _1695.y;\n            float3 _1967 = (normalize(_1723) * _1945.x) + (normalize(_1730) * _1945.y);\n            float3 _1970 = normalize(normal);\n            normal = normalize(lerp(_1970, normalize((_1970 * max(_1940.z, 0.0500000007450580596923828125f)) + (_1967 - (_1970 * dot(_1970, _1967)))), clamp(_1798 * (_1851 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3173_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3173_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_395_fa_atlas.y > 0.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3165 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3165;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3221 = (1.0f - _395_fa_rpa_tile.w) - _395_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3227 = _395_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3221 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3227)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _395_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3221;\n            }\n        }\n        else\n        {\n            amb = _395_fa_ambient.xyz * _3221;\n        }\n    }\n    bool _3280 = _395_fa_rpa_tile.w > 0.0f;\n    if (_3280)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _395_fa_rpa_tile.xy;\n            float param_4 = _395_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _395_fa_rpa_tile.w);\n        }\n    }\n    bool _3311 = _395_fa_rpb_tile.w > 0.0f;\n    if (_3311)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _395_fa_rpb_tile.xy;\n            float param_7 = _395_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _395_fa_rpb_tile.w);\n        }\n    }\n    if ((_3227 || _3280) || _3311)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_395_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _395_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_395_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_395_fa_cl_info.x) + int(_395_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_395_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3620;\n    if (fa_lm.z > 0.5f)\n    {\n        _3620 = 0.0f;\n    }\n    else\n    {\n        _3620 = 1.0f - clamp(_395_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _3631 = _3620 < 1.0f;\n    bool _3637;\n    if (_3631)\n    {\n        int param = li;\n        _3637 = fa_light_baked(param);\n    }\n    else\n    {\n        _3637 = _3631;\n    }\n    return _3637 ? _3620 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _454_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _454_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _573 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _586 = (c - (ru * hx)) - p;\n        float3 _592 = ru * (2.0f * hx);\n        float _598 = max(dot(_592, _592), 9.9999999392252902907785028219223e-09f);\n        float _602 = dot(_586, _592);\n        float t = clamp((-_602) / _598, 0.0f, 1.0f);\n        if (_573)\n        {\n            float _617 = dot(r, _592);\n            float _623 = _598 - (_617 * _617);\n            if (abs(_623) > (9.9999997473787516355514526367188e-06f * _598))\n            {\n                t = clamp(((dot(r, _586) * _617) - _602) / _623, 0.0f, 1.0f);\n            }\n        }\n        return (p + _586) + (_592 * t);\n    }\n    float3 q = p;\n    float _655 = dot(r, axis);\n    bool _663;\n    if (_573)\n    {\n        _663 = abs(_655) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _663 = _573;\n    }\n    if (_663)\n    {\n        float _673 = dot(c - p, axis) / _655;\n        if (_673 > 0.0f)\n        {\n            q = p + (r * _673);\n        }\n    }\n    float3 _686 = q - c;\n    float2 xy = float2(dot(_686, ru), dot(_686, uu));\n    if (shape > 0.5f)\n    {\n        float _701 = length(xy);\n        if (_701 > hx)\n        {\n            xy *= (hx / _701);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _343 = abs(d);\n    float _345 = _343.x;\n    float _347 = _343.y;\n    bool _348 = _345 >= _347;\n    bool _356;\n    if (_348)\n    {\n        _356 = _345 >= _343.z;\n    }\n    else\n    {\n        _356 = _348;\n    }\n    int _357;\n    if (_356)\n    {\n        _357 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _372;\n        if (_347 >= _343.z)\n        {\n            _372 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _372 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _357 = _372;\n    }\n    return _357;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _493 = dot(d, right);\n    float _497 = dot(d, up);\n    float _508;\n    if (((_493 * _493) + (_497 * _497)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _508 = atan2(_497, _493) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _508 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_508 - floor(_508)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _739 = fa_light_base(param);\n    bool _743 = _395_fa_ambient.w > 4.5f;\n    int param_1 = _739;\n    float4 _747 = fa_light_texel(param_1);\n    int param_2 = _739 + 1;\n    float4 _752 = fa_light_texel(param_2);\n    float _755 = _752.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _767 = _743 && (_755 > 2.5f);\n    fa_light_is_area = _767;\n    bool _769 = _755 < 0.5f;\n    float3 l;\n    if (_769)\n    {\n        l = normalize(_747.xyz);\n        if (_743)\n        {\n            int param_3 = _739 + 6;\n            float4 _783 = fa_light_texel(param_3);\n            if (_783.z > 0.5f)\n            {\n                int param_4 = _739 + 4;\n                float4 _793 = fa_light_texel(param_4);\n                int param_5 = _739 + 5;\n                float4 _798 = fa_light_texel(param_5);\n                float2 param_6 = _783.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _793.xyz) * _793.w, (-dot(world_pos, _798.xyz)) * _798.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _828 = _747.xyz;\n        float3 _830 = _828 - world_pos;\n        float3 to_light = _830;\n        float _833 = length(_830);\n        float reach = _833;\n        bool front = true;\n        if (_767)\n        {\n            int param_8 = _739 + 7;\n            reach = max(_833 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _739 + 4;\n            float4 _857 = fa_light_texel(param_9);\n            int param_10 = _739 + 5;\n            float4 _862 = fa_light_texel(param_10);\n            int param_11 = _739 + 6;\n            float4 _867 = fa_light_texel(param_11);\n            float _868 = _867.w;\n            int param_12 = _739 + 2;\n            float3 _875 = normalize(fa_light_texel(param_12).xyz);\n            bool _877 = _868 > 1.5f;\n            bool _885;\n            if (!_877)\n            {\n                _885 = dot(_875, to_light) < 0.0f;\n            }\n            else\n            {\n                _885 = _877;\n            }\n            front = _885;\n            float3 r = 0.0f.xxx;\n            float3 _894 = _395_fa_camera_pos.xyz - world_pos;\n            bool _898 = dot(n, n) > 0.5f;\n            bool _906;\n            if (_898)\n            {\n                _906 = dot(_894, _894) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _906 = _898;\n            }\n            if (_906)\n            {\n                r = reflect(-normalize(_894), normalize(n));\n            }\n            float3 param_13 = _828;\n            float3 param_14 = _875;\n            float3 param_15 = _857.xyz;\n            float3 param_16 = _862.xyz;\n            float param_17 = _857.w;\n            float param_18 = _862.w;\n            float param_19 = _868;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _942 = length(to_light);\n        dist = _942;\n        l = to_light / max(_942, 9.9999997473787516355514526367188e-05f).xxx;\n        float _956 = reach / max(_747.w, 0.001000000047497451305389404296875f);\n        float _962 = clamp(1.0f - (_956 * _956), 0.0f, 1.0f);\n        float _964;\n        if (front)\n        {\n            _964 = _962 * _962;\n        }\n        else\n        {\n            _964 = 0.0f;\n        }\n        atten = _964;\n        bool _975 = _755 < 2.5f;\n        if ((_755 > 1.5f) && _975)\n        {\n            int param_22 = _739 + 2;\n            float4 _983 = fa_light_texel(param_22);\n            float _993 = _983.w;\n            int param_23 = _739 + 3;\n            float4 _998 = fa_light_texel(param_23);\n            float _999 = _998.x;\n            float cos_inner = _999;\n            if (_999 > 1.5f)\n            {\n                cos_inner = lerp(_993, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_993, cos_inner, dot(-l, normalize(_983.xyz)));\n        }\n        if (_743 && (_755 < 1.5f))\n        {\n            int param_24 = _739 + 6;\n            float4 _1023 = fa_light_texel(param_24);\n            if (_1023.z > 0.5f)\n            {\n                float3 _1031 = -to_light;\n                int param_25 = _739 + 4;\n                int param_26 = _739 + 5;\n                float3 _1045 = fa_light_texel(param_25).xyz;\n                float3 _1049 = fa_light_texel(param_26).xyz;\n                float3 _1058 = float3(dot(_1031, _1045), dot(_1031, _1049), dot(_1031, cross(_1045, _1049)));\n                float3 param_27 = _1058;\n                int _1062 = fa_cube_face(param_27);\n                int param_28 = _1062;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1089 = float2(dot(_1058, cross(param_29, param_30)), dot(_1058, param_30)) / max(dot(_1058, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1093 = _1062 / 3;\n                float2 param_31 = _1023.xy + (float2(float(_1062 - (_1093 * 3)), float(_1093)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1089.x), 0.5f - (0.5f * _1089.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _739 + 7;\n            float4 _1123 = fa_light_texel(param_33);\n            if (_1123.z > 0.5f)\n            {\n                int param_34 = _739 + 2;\n                int param_35 = _739 + 4;\n                int param_36 = _739 + 5;\n                float2 param_37 = _1123.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_743 && _975)\n            {\n                int param_42 = _739 + 6;\n                float4 _1170 = fa_light_texel(param_42);\n                int param_43 = _739 + 7;\n                float4 _1175 = fa_light_texel(param_43);\n                bool _1178 = _1170.z > 0.5f;\n                bool _1185;\n                if (!_1178)\n                {\n                    _1185 = _1175.z > 0.5f;\n                }\n                else\n                {\n                    _1185 = _1178;\n                }\n                if (_1185)\n                {\n                    int param_44 = _739 + 2;\n                    float4 _1192 = fa_light_texel(param_44);\n                    float3 _1196 = normalize(_1192.xyz);\n                    int param_45 = _739 + 4;\n                    float4 _1201 = fa_light_texel(param_45);\n                    int param_46 = _739 + 5;\n                    float4 _1206 = fa_light_texel(param_46);\n                    if (_1178)\n                    {\n                        float3 _1214 = -to_light;\n                        float _1221 = _1192.w;\n                        float _1237 = 0.5f / max(dot(_1214, _1196) * (sqrt(max(1.0f - (_1221 * _1221), 0.0f)) / max(_1221, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1170.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1214, _1201.xyz) * _1237), 0.5f - (dot(_1214, _1206.xyz) * _1237));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1175.z > 0.5f)\n                    {\n                        float2 param_49 = _1175.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1196;\n                        float3 param_52 = _1201.xyz;\n                        float3 param_53 = _1206.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4766 = _752.xyz * atten;\n    if (_743)\n    {\n        _4766 *= fa_light_tint;\n    }\n    int _1305;\n    if (_769)\n    {\n        _1305 = 0;\n    }\n    else\n    {\n        _1305 = ((_755 > 1.5f) && (_755 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4777 = { l, _4766, atten, 1.0f, dist, _1305 };\n    return _4777;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2042;\n    if (i == 0)\n    {\n        _2042 = _2052_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2058;\n        if (i == 1)\n        {\n            _2058 = _2052_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2066;\n            if (i == 2)\n            {\n                _2066 = _2052_fa_shadow_split.z;\n            }\n            else\n            {\n                _2066 = _2052_fa_shadow_split.w;\n            }\n            _2058 = _2066;\n        }\n        _2042 = _2058;\n    }\n    return _2042;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2099 = fa_shadow_depth(param, param_1);\n    float _2103;\n    if (conv.x < 0.5f)\n    {\n        _2103 = _2099;\n    }\n    else\n    {\n        _2103 = (conv.y * conv.z) / (conv.z - (_2099 * (conv.z - conv.y)));\n    }\n    return _2103;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2030 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2030), sin(_2030)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2149 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2158;\n        if (k < 0.0f)\n        {\n            _2158 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2158 = k;\n        }\n        float _2178 = clamp((_2158 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2149;\n            float2 _2197 = fa_shadow_vogel(param_3, param_4, param_5) * _2178;\n            float2 param_6 = uv + (_2197 * _2052_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2209 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2209 < (zr - (length(_2197) * plane)))\n            {\n                sum += _2209;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2235 = sum / cnt;\n        float _2245;\n        if (k < 0.0f)\n        {\n            _2245 = (-k) / max(_2235, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2245 = k;\n        }\n        radius = clamp(((max(zr - _2235, 0.0f) * unit) * _2245) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2267 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2267; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2267;\n        float param_11 = _2149;\n        float2 _2286 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2286 * _2052_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2286) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2267);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2328 = max(_2052_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2333 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2339 = sqrt(1.0f - (_2333 * _2333));\n    float _2346 = min(_2339 / max(_2333, 0.20000000298023223876953125f), 4.0f);\n    float _2351;\n    if (_2052_fa_shadow_bias.y > 0.0f)\n    {\n        _2351 = _2052_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2351 = 1.5f * _2052_fa_shadow_info[ci].x;\n    }\n    float4 _2376 = mul(float4(world + (n * (_2351 * _2339)), 1.0f), _2052_fa_shadow_mat[ci]);\n    float _2383 = _2376.x;\n    bool _2386 = _2383 < _2052_fa_shadow_rect[ci].x;\n    bool _2395;\n    if (!_2386)\n    {\n        _2395 = _2383 > _2052_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2395 = _2386;\n    }\n    bool _2404;\n    if (!_2395)\n    {\n        _2404 = _2376.y < _2052_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2404 = _2395;\n    }\n    bool _2413;\n    if (!_2404)\n    {\n        _2413 = _2376.y > _2052_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2413 = _2404;\n    }\n    bool _2420;\n    if (!_2413)\n    {\n        _2420 = _2376.z > 1.0f;\n    }\n    else\n    {\n        _2420 = _2413;\n    }\n    if (_2420)\n    {\n        return -1.0f;\n    }\n    float _2428;\n    if (_2052_fa_shadow_bias.x > 0.0f)\n    {\n        _2428 = _2052_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2428 = 1.5f * _2052_fa_shadow_info[ci].x;\n    }\n    float2 param = _2376.xy;\n    float4 param_1 = _2052_fa_shadow_rect[ci];\n    float param_2 = _2376.z - ((_2428 * (1.0f + (0.5f * _2346))) / _2328);\n    float param_3 = _2052_fa_shadow_info[ci].x;\n    float param_4 = _2328;\n    float param_5 = _2328 * 0.25f;\n    float param_6 = ((_2052_fa_shadow_info[ci].x * min(_2346, 3.0f)) * 0.5f) / _2328;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2052_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2052_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_395_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2806 = int(_2052_fa_shadow_cfg.x + 0.5f);\n    if (_2806 < 1)\n    {\n        return 1.0f;\n    }\n    float _2821 = dot(world - _2052_fa_shadow_eye.xyz, _2052_fa_shadow_fwd.xyz);\n    int param = _2806 - 1;\n    if (_2821 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2833 = _2806 > 1;\n    bool _2840;\n    if (_2833)\n    {\n        _2840 = _2821 > _2052_fa_shadow_split.x;\n    }\n    else\n    {\n        _2840 = _2833;\n    }\n    if (_2840)\n    {\n        ci = 1;\n    }\n    bool _2844 = _2806 > 2;\n    bool _2851;\n    if (_2844)\n    {\n        _2851 = _2821 > _2052_fa_shadow_split.y;\n    }\n    else\n    {\n        _2851 = _2844;\n    }\n    if (_2851)\n    {\n        ci = 2;\n    }\n    bool _2855 = _2806 > 3;\n    bool _2862;\n    if (_2855)\n    {\n        _2862 = _2821 > _2052_fa_shadow_split.z;\n    }\n    else\n    {\n        _2862 = _2855;\n    }\n    if (_2862)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2806)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2888 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2888;\n        if (_2888 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2052_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2913;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2913 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2913 = _2052_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2932 = _2052_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2913, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2943 = clamp((_2821 - (fa_shadow_split_at(param_7) - _2932)) / _2932, 0.0f, 1.0f);\n        if (_2943 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2806)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2964 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2964;\n                if (_2964 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2943);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2486 = _395_fa_pbr.z < 0.5f;\n    bool _2493;\n    if (!_2486)\n    {\n        _2493 = _2052_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2493 = _2486;\n    }\n    if (_2493)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2052_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2506 = fa_light_texel(param);\n    float _2507 = _2506.x;\n    if (_2507 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2516 = int(_2507 + 0.5f);\n    int param_1 = _2516;\n    float4 _2520 = fa_light_texel(param_1);\n    int param_2 = _2516 + 1;\n    float4 _2525 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2528 = _2520.y;\n    if (_2528 > 0.0f)\n    {\n        float _2545 = 1.0f - smoothstep(0.75f * _2528, _2528, length(world - _2052_fa_shadow_eye.xyz));\n        fade = _2545;\n        if (_2545 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2520.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2569 = (_2516 + 2) + (face * 6);\n    int param_4 = _2569;\n    int param_5 = _2569 + 1;\n    int param_6 = _2569 + 3;\n    float4 _2583 = fa_light_texel(param_6);\n    int param_7 = _2569 + 4;\n    float4 _2588 = fa_light_texel(param_7);\n    int param_8 = _2569 + 5;\n    float4 _2593 = fa_light_texel(param_8);\n    float _2605 = _2593.x * max(dot(_2583, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2610 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2633 = clamp(dot(n, _2583.xyz), -1.0f, 1.0f);\n    float _2652 = min(sqrt(1.0f - (_2633 * _2633)) / max(abs(dot(n, world - lpos)) / max(dot(_2583, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2655 = _2525.y;\n    float _2657;\n    if (_2655 > 0.0f)\n    {\n        _2657 = _2655;\n    }\n    else\n    {\n        _2657 = 1.5f * _2605;\n    }\n    float4 _2677 = float4(world + (n * (_2657 * sqrt(1.0f - (_2610 * _2610)))), 1.0f);\n    float _2681 = dot(_2583, _2677);\n    float _2684 = _2593.y;\n    if (_2681 < _2684)\n    {\n        return 1.0f;\n    }\n    float2 _2699 = float2(dot(fa_light_texel(param_4), _2677), dot(fa_light_texel(param_5), _2677)) / _2681.xx;\n    float _2701 = _2699.x;\n    bool _2704 = _2701 < _2588.x;\n    bool _2713;\n    if (!_2704)\n    {\n        _2713 = _2701 > _2588.z;\n    }\n    else\n    {\n        _2713 = _2704;\n    }\n    bool _2722;\n    if (!_2713)\n    {\n        _2722 = _2699.y < _2588.y;\n    }\n    else\n    {\n        _2722 = _2713;\n    }\n    bool _2731;\n    if (!_2722)\n    {\n        _2731 = _2699.y > _2588.w;\n    }\n    else\n    {\n        _2731 = _2722;\n    }\n    if (_2731)\n    {\n        return 1.0f;\n    }\n    float _2737 = _2525.x;\n    float _2739;\n    if (_2737 > 0.0f)\n    {\n        _2739 = _2737;\n    }\n    else\n    {\n        _2739 = 1.5f * _2605;\n    }\n    float2 param_9 = _2699;\n    float4 param_10 = _2588;\n    float param_11 = _2681 - (_2739 * (1.0f + (0.5f * _2652)));\n    float param_12 = _2605;\n    float param_13 = 1.0f;\n    float param_14 = _2593.z * 0.25f;\n    float param_15 = (_2605 * min(_2652, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2684, _2593.z);\n    int param_17 = int(_2520.z + 0.5f);\n    float param_18 = _2520.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3362 = _395_fa_ct_a.x < 0.5f;\n    bool _3369;\n    if (!_3362)\n    {\n        _3369 = _2052_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3369 = _3362;\n    }\n    if (_3369)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2052_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3382 = fa_light_texel(param);\n    float _3383 = _3382.y;\n    float len = _3383;\n    if (_3383 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3395 = length(world - _395_fa_camera_pos.xyz);\n    float _3405 = 1.0f - smoothstep(0.5f * _395_fa_ct_b.x, _395_fa_ct_b.x, _3395);\n    if (_3405 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3411 = len;\n    float _3414 = min(_3411, 0.89999997615814208984375f * dist);\n    len = _3414;\n    float _3420 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3395);\n    float _3425 = _3420 + (0.5f * _3414);\n    float3 _3431 = world + (gn * _3420);\n    float _3433 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _3498;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3449 = (float(k) + _3433) * 0.083333335816860198974609375f;\n        float3 _3457 = _3431 + (l * (_3449 * len));\n        float4 _3463 = float4(_3457, 1.0f);\n        float _3469 = dot(_395_fa_ct_vpw, _3463);\n        if (_3469 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _3489 = float2(dot(_395_fa_ct_vpx, _3463), dot(_395_fa_ct_vpy, _3463)) / _3469.xx;\n        float _3493 = _3489.x * 0.5f;\n        float _3494 = _3493 + 0.5f;\n        if (_395_fa_ct_a.y > 0.5f)\n        {\n            _3498 = (_3489.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _3498 = 0.5f - (_3489.y * 0.5f);\n        }\n        bool _3514 = _3494 < 0.0f;\n        bool _3521;\n        if (!_3514)\n        {\n            _3521 = _3494 >= 1.0f;\n        }\n        else\n        {\n            _3521 = _3514;\n        }\n        bool _3528;\n        if (!_3521)\n        {\n            _3528 = _3498 < 0.0f;\n        }\n        else\n        {\n            _3528 = _3521;\n        }\n        bool _3535;\n        if (!_3528)\n        {\n            _3535 = _3498 >= 1.0f;\n        }\n        else\n        {\n            _3535 = _3528;\n        }\n        if (_3535)\n        {\n            break;\n        }\n        float4 _3554 = fa_screen_tex.Load(int3(int2(float2(_3494, _3498) * _395_fa_ct_a.zw), 0));\n        if (_3554.w < 0.5f)\n        {\n            continue;\n        }\n        float _3573 = (dot(_395_fa_ct_fwd.xyz, _3457) + _395_fa_ct_fwd.w) - _3554.x;\n        if ((_3573 > _3420) && (_3573 < _3425))\n        {\n            occ = max(occ, (1.0f - (_3449 * _3449)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_3494, 0.5f - _3493), min(_3498, 1.0f - _3498))));\n        }\n    }\n    return 1.0f - (occ * _3405);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _3676 = fa_baked_keep(param);\n    if (_3676 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _4790 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4790;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3702 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _4792 = _3702.color;\n    float _4793 = _3702.attenuation;\n    float _4794 = _3702.shadow;\n    bool _3705 = _3702.type == 0;\n    if (_3705 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3702.direction;\n        float _3716 = fa_shadow_factor(param_5, param_6);\n        _4794 = _3716;\n        _4792 *= _3716;\n    }\n    else\n    {\n        bool _3727 = _3702.type != 0;\n        bool _3733;\n        if (_3727)\n        {\n            _3733 = _4793 > 0.0f;\n        }\n        else\n        {\n            _3733 = _3727;\n        }\n        if (_3733)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3702.direction;\n            float _3752 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4794 = _3752;\n            _4792 *= _3752;\n        }\n    }\n    bool _3762 = _395_fa_ct_a.x > 0.5f;\n    bool _3768;\n    if (_3762)\n    {\n        _3768 = _4793 > 0.0f;\n    }\n    else\n    {\n        _3768 = _3762;\n    }\n    if (_3768)\n    {\n        float _3775;\n        if (_3705)\n        {\n            _3775 = 1000000000.0f;\n        }\n        else\n        {\n            _3775 = _3702._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3702.direction;\n        float param_18 = _3775;\n        float _3793 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _4794 *= _3793;\n        _4792 *= _3793;\n    }\n    float _3806 = _4793;\n    float _3807 = _3806 * _3676;\n    _4793 = _3807;\n    float3 _3811 = _4792;\n    float3 _3812 = _3811 * _3676;\n    _4792 = _3812;\n    LightSample _4809 = { _3702.direction, _3812, _3807, _4794, _3702._distance, _3702.type };\n    return _4809;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2052_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2988 = int(_2052_fa_shadow_cfg.x + 0.5f);\n    float _2998 = dot(world - _2052_fa_shadow_eye.xyz, _2052_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3003 = _2988 > 0;\n    bool _3012;\n    if (_3003)\n    {\n        int param = _2988 - 1;\n        _3012 = _2998 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3012 = _3003;\n    }\n    if (_3012)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3018 = _2988 > 1;\n        bool _3025;\n        if (_3018)\n        {\n            _3025 = _2998 > _2052_fa_shadow_split.x;\n        }\n        else\n        {\n            _3025 = _3018;\n        }\n        if (_3025)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3031 = _2988 > 2;\n        bool _3038;\n        if (_3031)\n        {\n            _3038 = _2998 > _2052_fa_shadow_split.y;\n        }\n        else\n        {\n            _3038 = _3031;\n        }\n        if (_3038)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3044 = _2988 > 3;\n        bool _3051;\n        if (_3044)\n        {\n            _3051 = _2998 > _2052_fa_shadow_split.z;\n        }\n        else\n        {\n            _3051 = _3044;\n        }\n        if (_3051)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4633 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4633 = -_4633;\n    }\n    float3 _4224 = normalize(_395_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4646 = { fa_world_pos, _4633, fa_world_tangent, fa_uv, fa_vertex_color, _4224, gl_FrontFacing };\n    SurfaceInput param_1 = _4646;\n    Surface _4232 = fa_standard_surface(param_1);\n    float3 _4664 = _4232.albedo;\n    float _4665 = _4232.alpha;\n    float3 _4666 = _4232.normal;\n    float _4667 = _4232.metallic;\n    float _4668 = _4232.roughness;\n    float _4669 = _4232.occlusion;\n    float3 _4670 = _4232.emission;\n    float _4671 = _4232.clearcoat;\n    float _4672 = _4232.clearcoat_roughness;\n    float3 _4673 = _4232.sheen_color;\n    float _4674 = _4232.sheen_roughness;\n    float _4675 = _4232.anisotropy;\n    float _4676 = _4232.anisotropy_rotation;\n    float _4677 = _4232.specular;\n    float _4678 = _4232.ior;\n    float3 _4679 = _4232.specular_color;\n    SurfaceInput _4654 = { fa_world_pos, _4633, fa_world_tangent, fa_uv, fa_vertex_color, _4224, gl_FrontFacing };\n    SurfaceInput param_2 = _4654;\n    Surface param_3 = _4232;\n    surface(param_2, param_3);\n    _4664 = param_3.albedo;\n    _4665 = param_3.alpha;\n    _4666 = param_3.normal;\n    _4667 = param_3.metallic;\n    _4668 = param_3.roughness;\n    _4669 = param_3.occlusion;\n    _4670 = param_3.emission;\n    _4671 = param_3.clearcoat;\n    _4672 = param_3.clearcoat_roughness;\n    _4673 = param_3.sheen_color;\n    _4674 = param_3.sheen_roughness;\n    _4675 = param_3.anisotropy;\n    _4676 = param_3.anisotropy_rotation;\n    _4677 = param_3.specular;\n    _4678 = param_3.ior;\n    _4679 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4633;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4664 = param_6;\n    _4666 = param_7;\n    float3 result;\n    if (_395_fa_emissive.w > 0.5f)\n    {\n        result = _4664;\n    }\n    else\n    {\n        float3 _4270 = _4666;\n        float3 _4271 = normalize(_4270);\n        _4666 = _4271;\n        float3 param_8 = _4271;\n        float3 lit = (fa_indirect_diffuse(param_8) * _4664) * _4669;\n        int _4290 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4290; ln++)\n        {\n            int param_9 = ln;\n            int _4303 = fa_cl_light(param_9);\n            int param_10 = _4303;\n            if (fa_baked_keep(param_10) <= 0.0f)\n            {\n                continue;\n            }\n            int param_11 = _4303;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _4633;\n            LightSample _4319 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput _4662 = { fa_world_pos, _4633, fa_world_tangent, fa_uv, fa_vertex_color, _4224, gl_FrontFacing };\n            SurfaceInput param_14 = _4662;\n            Surface _4745 = { _4664, _4665, _4666, _4667, _4668, _4669, _4670, _4671, _4672, _4673, _4674, _4675, _4676, _4677, _4678, _4679 };\n            Surface param_15 = _4745;\n            LightSample param_16 = _4319;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _4334 = result;\n    float3 _4335 = _4334 + _4670;\n    result = _4335;\n    float3 param_17 = _4335;\n    float3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _4344 = _395_fa_fog.w > 0.0f;\n    bool _4351;\n    if (!_4344)\n    {\n        _4351 = _395_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4351 = _4344;\n    }\n    if (_4351)\n    {\n        float3 _4360 = fa_world_pos - _395_fa_camera_pos.xyz;\n        float _4366 = dot(_4360, _395_fa_fog_c.xyz);\n        bool _4370 = _395_fa_fog_c.w > 0.5f;\n        float _4371;\n        if (_4370)\n        {\n            _4371 = _4366;\n        }\n        else\n        {\n            _4371 = length(_4360);\n        }\n        float _4383 = _4371 - _395_fa_fog_b.x;\n        if (_4383 > 0.0f)\n        {\n            float _4392 = _395_fa_fog.w * _4383;\n            float tau = _4392 * _4392;\n            if (_395_fa_fog_b.y > 0.0f)\n            {\n                float _4408;\n                if (_4370)\n                {\n                    _4408 = fa_world_pos.y - (_395_fa_fog_c.y * _4366);\n                }\n                else\n                {\n                    _4408 = _395_fa_camera_pos.y;\n                }\n                float _4429 = lerp(_4408, fa_world_pos.y, clamp(_395_fa_fog_b.x / _4371, 0.0f, 1.0f));\n                float _4433 = fa_world_pos.y - _4429;\n                float _4438 = _4429 - _395_fa_fog_b.z;\n                float _4443 = fa_world_pos.y - _395_fa_fog_b.z;\n                bool _4446 = _4438 <= 0.0f;\n                bool _4447 = !_4446;\n                bool _4453;\n                if (_4447)\n                {\n                    _4453 = _395_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4453 = _4446;\n                }\n                float _4454;\n                if (_4453)\n                {\n                    _4454 = _395_fa_fog_b.y;\n                }\n                else\n                {\n                    _4454 = _395_fa_fog_b.y * exp(-min(_395_fa_fog_b.w * _4438, 80.0f));\n                }\n                bool _4481;\n                if (_4447)\n                {\n                    _4481 = _395_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4481 = _4446;\n                }\n                float _4482;\n                if (_4481)\n                {\n                    _4482 = _395_fa_fog_b.y * _4438;\n                }\n                else\n                {\n                    _4482 = (_395_fa_fog_b.y * (1.0f - exp(-min(_395_fa_fog_b.w * _4438, 80.0f)))) / _395_fa_fog_b.w;\n                }\n                bool _4507 = _4443 <= 0.0f;\n                bool _4514;\n                if (!_4507)\n                {\n                    _4514 = _395_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4514 = _4507;\n                }\n                float _4515;\n                if (_4514)\n                {\n                    _4515 = _395_fa_fog_b.y * _4443;\n                }\n                else\n                {\n                    _4515 = (_395_fa_fog_b.y * (1.0f - exp(-min(_395_fa_fog_b.w * _4443, 80.0f)))) / _395_fa_fog_b.w;\n                }\n                float _4542;\n                if (abs(_4433) < 0.001000000047497451305389404296875f)\n                {\n                    _4542 = _4454;\n                }\n                else\n                {\n                    _4542 = (_4515 - _4482) / _4433;\n                }\n                tau += (_4383 * max(_4542, 0.0f));\n            }\n            result = lerp(result, _395_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4665);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_395",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2052",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _395_fa_camera_pos : packoffset(c0);\n    float4 _395_fa_ambient : packoffset(c1);\n    float4 _395_fa_base_color : packoffset(c2);\n    float4 _395_fa_emissive : packoffset(c3);\n    float4 _395_fa_model_emissive : packoffset(c4);\n    float4 _395_fa_pbr : packoffset(c5);\n    float4 _395_fa_maps : packoffset(c6);\n    float4 _395_fa_fog : packoffset(c7);\n    float4 _395_fa_fog_b : packoffset(c8);\n    float4 _395_fa_fog_c : packoffset(c9);\n    float4 _395_fa_counts : packoffset(c10);\n    float4 _395_fa_env_sky : packoffset(c11);\n    float4 _395_fa_env_horizon : packoffset(c12);\n    float4 _395_fa_time : packoffset(c13);\n    float4 _395_fa_cl_vpx : packoffset(c14);\n    float4 _395_fa_cl_vpy : packoffset(c15);\n    float4 _395_fa_cl_vpw : packoffset(c16);\n    float4 _395_fa_cl_fwd : packoffset(c17);\n    float4 _395_fa_cl_grid : packoffset(c18);\n    float4 _395_fa_cl_info : packoffset(c19);\n    float4 _395_fa_layers_a : packoffset(c20);\n    float4 _395_fa_layers_b : packoffset(c21);\n    float4 _395_fa_layers_c : packoffset(c22);\n    float4 _395_fa_layers_d : packoffset(c23);\n    float4 _395_fa_ct_a : packoffset(c24);\n    float4 _395_fa_ct_b : packoffset(c25);\n    float4 _395_fa_ct_vpx : packoffset(c26);\n    float4 _395_fa_ct_vpy : packoffset(c27);\n    float4 _395_fa_ct_vpw : packoffset(c28);\n    float4 _395_fa_ct_fwd : packoffset(c29);\n    float4 _395_fa_probe_sh[9] : packoffset(c30);\n    float4 _395_fa_atlas : packoffset(c39);\n    float4 _395_fa_rpa_tile : packoffset(c40);\n    float4 _395_fa_rpa_pos : packoffset(c41);\n    float4 _395_fa_rpa_bx : packoffset(c42);\n    float4 _395_fa_rpa_by : packoffset(c43);\n    float4 _395_fa_rpa_bz : packoffset(c44);\n    float4 _395_fa_rpb_tile : packoffset(c45);\n    float4 _395_fa_rpb_pos : packoffset(c46);\n    float4 _395_fa_rpb_bx : packoffset(c47);\n    float4 _395_fa_rpb_by : packoffset(c48);\n    float4 _395_fa_rpb_bz : packoffset(c49);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2052_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2052_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2052_fa_shadow_info[4] : packoffset(c20);\n    float4 _2052_fa_shadow_split : packoffset(c24);\n    float4 _2052_fa_shadow_cfg : packoffset(c25);\n    float4 _2052_fa_shadow_bias : packoffset(c26);\n    float4 _2052_fa_shadow_eye : packoffset(c27);\n    float4 _2052_fa_shadow_fwd : packoffset(c28);\n    float4 _2052_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1323 = _395_fa_cl_info.x < 0.0f;\n    bool _1330;\n    if (!_1323)\n    {\n        _1330 = _395_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1330 = _1323;\n    }\n    bool _1338;\n    if (!_1330)\n    {\n        _1338 = _395_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1338 = _1330;\n    }\n    bool _1345;\n    if (!_1338)\n    {\n        _1345 = _395_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1345 = _1338;\n    }\n    bool _1352;\n    if (!_1345)\n    {\n        _1352 = _395_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1352 = _1345;\n    }\n    if (_1352)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1362 = float4(world_pos, 1.0f);\n    float _1368 = dot(_395_fa_cl_vpw, _1362);\n    if (!(_1368 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1390 = float2(dot(_395_fa_cl_vpx, _1362), dot(_395_fa_cl_vpy, _1362)) / _1368.xx;\n    int _1394 = int(_395_fa_cl_grid.x);\n    int _1398 = int(_395_fa_cl_grid.y);\n    int param = (int(_395_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_395_fa_cl_fwd.xyz, world_pos) + _395_fa_cl_fwd.w, _395_fa_cl_grid.w) / _395_fa_cl_grid.w) * _395_fa_cl_grid.z)), 0, int(_395_fa_cl_info.y) - 1) * _1398) + clamp(int(floor(((_1390.y * 0.5f) + 0.5f) * _395_fa_cl_grid.y)), 0, _1398 - 1)) * _1394)) + clamp(int(floor(((_1390.x * 0.5f) + 0.5f) * _395_fa_cl_grid.x)), 0, _1394 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1474 = fa_cluster_texel(param);\n    return int2(int(_1474.x), int(_1474.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_395_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3650 = fa_cluster_lookup(param);\n    fa_cl_slot = _3650.x;\n    fa_cl_local = _3650.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3855 = fa_linear_to_srgb(param);\n        c = _3855;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3863 = fa_srgb_to_linear(param_1);\n            c = _3863;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _277;\n    if (i.front_facing)\n    {\n        _277 = i.world_normal;\n    }\n    else\n    {\n        _277 = -i.world_normal;\n    }\n    float3 _301 = normalize(i.world_tangent.xyz - (_277 * dot(_277, i.world_tangent.xyz)));\n    float3 _328 = normalize(((_301 * m.x) + ((cross(_277, _301) * i.world_tangent.w) * m.y)) + (_277 * m.z));\n    float3 _331;\n    if (i.front_facing)\n    {\n        _331 = _328;\n    }\n    else\n    {\n        _331 = -_328;\n    }\n    return _331;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _395_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3894 = fa_tex_fix(param_2, param_3);\n    float4 _4960 = base_t;\n    _4960.x = _3894.x;\n    _4960.y = _3894.y;\n    _4960.z = _3894.z;\n    base_t = _4960;\n    float4 _3908 = (_4960 * _395_fa_base_color) * i.vertex_color;\n    float3 _4812 = i.world_normal;\n    if (_395_fa_maps.z > 0.5f)\n    {\n        float param_4 = _395_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _3940 = fa_tex_fix(param_6, param_7);\n        float3 _3943 = (_3940 * 2.0f) - 1.0f.xxx;\n        float2 _3948 = _3943.xy * _395_fa_maps.x;\n        float3 _4968 = _3943;\n        _4968.x = _3948.x;\n        _4968.y = _3948.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _4968;\n        _4812 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _395_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _3976 = fa_tex_fix(param_12, param_13);\n    float4 _4971 = mrt;\n    _4971.x = _3976.x;\n    _4971.y = _3976.y;\n    _4971.z = _3976.z;\n    mrt = _4971;\n    float4 _4004 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _395_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4004.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4015 = fa_tex_fix(param_16, param_17);\n    float param_18 = _395_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4045 = fa_tex_fix(param_20, param_21);\n    float _4817 = _395_fa_layers_a.x;\n    float _4818 = _395_fa_layers_a.y;\n    float _4821 = _395_fa_layers_a.z;\n    float _4820 = _395_fa_layers_b.w;\n    float _4823 = _395_fa_layers_c.x;\n    if (_395_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_395_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _4817 *= _4015.y;\n            _4818 *= _4015.z;\n            _4820 *= _4004.w;\n        }\n        if (_395_fa_layers_c.z > 1.5f)\n        {\n            _4821 *= mrt.x;\n            _4823 *= mrt.w;\n        }\n    }\n    Surface _4842 = { _3908.xyz, _3908.w, _4812, clamp(_395_fa_pbr.x * _3976.z, 0.0f, 1.0f), clamp(_395_fa_pbr.y * _3976.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_395_fa_maps.y * (_4015.x - 1.0f)), _395_fa_emissive.xyz + (_395_fa_model_emissive.xyz * _4045), _4817, _4818, _395_fa_layers_b.xyz, _4820, _4821, _395_fa_layers_a.w, _4823, _395_fa_layers_c.y, _395_fa_layers_d.xyz };\n    return _4842;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1554 = rect.zw - rect.xy;\n    float2 _1558 = _1554 * atlas;\n    float2 _1562 = ddx * _1558;\n    float2 _1566 = ddy * _1558;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1554), clamp(0.5f * log2(max(max(dot(_1562, _1562), dot(_1566, _1566)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1599 = _395_fa_counts.y < 0.5f;\n    bool _1606;\n    if (!_1599)\n    {\n        _1606 = _395_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1606 = _1599;\n    }\n    if (_1606)\n    {\n        return;\n    }\n    float3 _1612 = ddx(world_pos);\n    float3 _1615 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1619 = fa_cluster_texel(param);\n    int _1623 = int(_1619.w);\n    if (_1623 < 1)\n    {\n        return;\n    }\n    int _1633 = int(_395_fa_counts.y + 0.5f);\n    int param_1 = _1633;\n    float4 _1637 = fa_light_texel(param_1);\n    float2 _1640 = _1637.yz;\n    int _1644 = int(_1637.w);\n    int param_2 = _1633 + 1;\n    float4 _1649 = fa_light_texel(param_2);\n    float _1650 = _1649.x;\n    int _1656 = int(_395_fa_counts.w + 0.5f) - 1;\n    int _1660 = int(_1619.z);\n    float3 _1925;\n    for (int k = 0; k < _1623; k++)\n    {\n        int _1673 = _1660 + k;\n        int param_3 = _1644 + (_1673 >> 2);\n        int _1690 = (_1633 + 2) + (int(fa_light_texel(param_3)[_1673 & 3]) * 7);\n        int param_4 = _1690 + 6;\n        float4 _1695 = fa_light_texel(param_4);\n        if (((int(_1695.w + 0.5f) >> _1656) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1690;\n        float4 _1710 = fa_light_texel(param_5);\n        int param_6 = _1690 + 1;\n        float4 _1715 = fa_light_texel(param_6);\n        int param_7 = _1690 + 2;\n        float4 _1720 = fa_light_texel(param_7);\n        float3 _1723 = _1710.xyz;\n        float _1728 = dot(_1723, world_pos) + _1710.w;\n        float3 _1730 = _1715.xyz;\n        float _1735 = dot(_1730, world_pos) + _1715.w;\n        float3 _1737 = _1720.xyz;\n        float _1742 = dot(_1737, world_pos) + _1720.w;\n        bool _1747 = abs(_1728) > 0.5f;\n        bool _1755;\n        if (!_1747)\n        {\n            _1755 = abs(_1735) > 0.5f;\n        }\n        else\n        {\n            _1755 = _1747;\n        }\n        bool _1763;\n        if (!_1755)\n        {\n            _1763 = abs(_1742) > 0.5f;\n        }\n        else\n        {\n            _1763 = _1755;\n        }\n        if (_1763)\n        {\n            continue;\n        }\n        float _1778 = clamp(dot(geo_normal, normalize(_1737)) * _1695.z, 0.0f, 1.0f);\n        if (_1778 <= 0.0f)\n        {\n            continue;\n        }\n        float _1798 = (clamp((0.5f - abs(_1742)) * 10.0f, 0.0f, 1.0f) * _1778) * _1695.x;\n        float2 _1806 = float2(_1728 + 0.5f, 0.5f - _1735);\n        float2 _1816 = float2(dot(_1723, _1612), dot(_1730, _1612));\n        float2 _1826 = float2(dot(_1723, _1615), dot(_1730, _1615));\n        int param_8 = _1690 + 5;\n        float4 _1831 = fa_light_texel(param_8);\n        int param_9 = _1690 + 3;\n        float4 _1836 = fa_light_texel(param_9);\n        int param_10 = _1690 + 4;\n        float4 _1841 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1831.xyz;\n        bool _1851 = _1836.z > _1836.x;\n        if (_1851)\n        {\n            float4 param_11 = _1836;\n            float2 param_12 = _1806;\n            float2 param_13 = _1640;\n            float2 param_14 = _1816;\n            float2 param_15 = _1826;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1650 > 0.5f) && (_1650 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1877 = fa_dc_to_linear(param_16);\n                float4 _4892 = tx;\n                _4892.x = _1877.x;\n                _4892.y = _1877.y;\n                _4892.z = _1877.z;\n                tx = _4892;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1798 * tex_a) * _1831.w, 0.0f, 1.0f).xxx);\n        if (_1841.z > _1841.x)\n        {\n            float4 param_17 = _1841;\n            float2 param_18 = _1806;\n            float2 param_19 = _1640;\n            float2 param_20 = _1816;\n            float2 param_21 = _1826;\n            float4 _1921 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1650 > 1.5f)\n            {\n                float3 param_22 = _1921.xyz;\n                float3 _1931 = fa_dc_to_srgb(param_22);\n                _1925 = _1931;\n            }\n            else\n            {\n                _1925 = _1921.xyz;\n            }\n            float3 _1940 = (_1925 * 2.0f) - 1.0f.xxx;\n            float2 _1945 = _1940.xy * _1695.y;\n            float3 _1967 = (normalize(_1723) * _1945.x) + (normalize(_1730) * _1945.y);\n            float3 _1970 = normalize(normal);\n            normal = normalize(lerp(_1970, normalize((_1970 * max(_1940.z, 0.0500000007450580596923828125f)) + (_1967 - (_1970 * dot(_1970, _1967)))), clamp(_1798 * (_1851 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3173_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3173_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_395_fa_atlas.y > 0.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3165 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3165;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3221 = (1.0f - _395_fa_rpa_tile.w) - _395_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3227 = _395_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3221 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3227)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _395_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3221;\n            }\n        }\n        else\n        {\n            amb = _395_fa_ambient.xyz * _3221;\n        }\n    }\n    bool _3280 = _395_fa_rpa_tile.w > 0.0f;\n    if (_3280)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _395_fa_rpa_tile.xy;\n            float param_4 = _395_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _395_fa_rpa_tile.w);\n        }\n    }\n    bool _3311 = _395_fa_rpb_tile.w > 0.0f;\n    if (_3311)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _395_fa_rpb_tile.xy;\n            float param_7 = _395_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _395_fa_rpb_tile.w);\n        }\n    }\n    if ((_3227 || _3280) || _3311)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_395_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _395_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_395_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_395_fa_cl_info.x) + int(_395_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_395_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3620;\n    if (fa_lm.z > 0.5f)\n    {\n        _3620 = 0.0f;\n    }\n    else\n    {\n        _3620 = 1.0f - clamp(_395_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _3631 = _3620 < 1.0f;\n    bool _3637;\n    if (_3631)\n    {\n        int param = li;\n        _3637 = fa_light_baked(param);\n    }\n    else\n    {\n        _3637 = _3631;\n    }\n    return _3637 ? _3620 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _454_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _454_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _573 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _586 = (c - (ru * hx)) - p;\n        float3 _592 = ru * (2.0f * hx);\n        float _598 = max(dot(_592, _592), 9.9999999392252902907785028219223e-09f);\n        float _602 = dot(_586, _592);\n        float t = clamp((-_602) / _598, 0.0f, 1.0f);\n        if (_573)\n        {\n            float _617 = dot(r, _592);\n            float _623 = _598 - (_617 * _617);\n            if (abs(_623) > (9.9999997473787516355514526367188e-06f * _598))\n            {\n                t = clamp(((dot(r, _586) * _617) - _602) / _623, 0.0f, 1.0f);\n            }\n        }\n        return (p + _586) + (_592 * t);\n    }\n    float3 q = p;\n    float _655 = dot(r, axis);\n    bool _663;\n    if (_573)\n    {\n        _663 = abs(_655) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _663 = _573;\n    }\n    if (_663)\n    {\n        float _673 = dot(c - p, axis) / _655;\n        if (_673 > 0.0f)\n        {\n            q = p + (r * _673);\n        }\n    }\n    float3 _686 = q - c;\n    float2 xy = float2(dot(_686, ru), dot(_686, uu));\n    if (shape > 0.5f)\n    {\n        float _701 = length(xy);\n        if (_701 > hx)\n        {\n            xy *= (hx / _701);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _343 = abs(d);\n    float _345 = _343.x;\n    float _347 = _343.y;\n    bool _348 = _345 >= _347;\n    bool _356;\n    if (_348)\n    {\n        _356 = _345 >= _343.z;\n    }\n    else\n    {\n        _356 = _348;\n    }\n    int _357;\n    if (_356)\n    {\n        _357 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _372;\n        if (_347 >= _343.z)\n        {\n            _372 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _372 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _357 = _372;\n    }\n    return _357;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _493 = dot(d, right);\n    float _497 = dot(d, up);\n    float _508;\n    if (((_493 * _493) + (_497 * _497)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _508 = atan2(_497, _493) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _508 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_508 - floor(_508)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _739 = fa_light_base(param);\n    bool _743 = _395_fa_ambient.w > 4.5f;\n    int param_1 = _739;\n    float4 _747 = fa_light_texel(param_1);\n    int param_2 = _739 + 1;\n    float4 _752 = fa_light_texel(param_2);\n    float _755 = _752.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _767 = _743 && (_755 > 2.5f);\n    fa_light_is_area = _767;\n    bool _769 = _755 < 0.5f;\n    float3 l;\n    if (_769)\n    {\n        l = normalize(_747.xyz);\n        if (_743)\n        {\n            int param_3 = _739 + 6;\n            float4 _783 = fa_light_texel(param_3);\n            if (_783.z > 0.5f)\n            {\n                int param_4 = _739 + 4;\n                float4 _793 = fa_light_texel(param_4);\n                int param_5 = _739 + 5;\n                float4 _798 = fa_light_texel(param_5);\n                float2 param_6 = _783.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _793.xyz) * _793.w, (-dot(world_pos, _798.xyz)) * _798.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _828 = _747.xyz;\n        float3 _830 = _828 - world_pos;\n        float3 to_light = _830;\n        float _833 = length(_830);\n        float reach = _833;\n        bool front = true;\n        if (_767)\n        {\n            int param_8 = _739 + 7;\n            reach = max(_833 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _739 + 4;\n            float4 _857 = fa_light_texel(param_9);\n            int param_10 = _739 + 5;\n            float4 _862 = fa_light_texel(param_10);\n            int param_11 = _739 + 6;\n            float4 _867 = fa_light_texel(param_11);\n            float _868 = _867.w;\n            int param_12 = _739 + 2;\n            float3 _875 = normalize(fa_light_texel(param_12).xyz);\n            bool _877 = _868 > 1.5f;\n            bool _885;\n            if (!_877)\n            {\n                _885 = dot(_875, to_light) < 0.0f;\n            }\n            else\n            {\n                _885 = _877;\n            }\n            front = _885;\n            float3 r = 0.0f.xxx;\n            float3 _894 = _395_fa_camera_pos.xyz - world_pos;\n            bool _898 = dot(n, n) > 0.5f;\n            bool _906;\n            if (_898)\n            {\n                _906 = dot(_894, _894) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _906 = _898;\n            }\n            if (_906)\n            {\n                r = reflect(-normalize(_894), normalize(n));\n            }\n            float3 param_13 = _828;\n            float3 param_14 = _875;\n            float3 param_15 = _857.xyz;\n            float3 param_16 = _862.xyz;\n            float param_17 = _857.w;\n            float param_18 = _862.w;\n            float param_19 = _868;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _942 = length(to_light);\n        dist = _942;\n        l = to_light / max(_942, 9.9999997473787516355514526367188e-05f).xxx;\n        float _956 = reach / max(_747.w, 0.001000000047497451305389404296875f);\n        float _962 = clamp(1.0f - (_956 * _956), 0.0f, 1.0f);\n        float _964;\n        if (front)\n        {\n            _964 = _962 * _962;\n        }\n        else\n        {\n            _964 = 0.0f;\n        }\n        atten = _964;\n        bool _975 = _755 < 2.5f;\n        if ((_755 > 1.5f) && _975)\n        {\n            int param_22 = _739 + 2;\n            float4 _983 = fa_light_texel(param_22);\n            float _993 = _983.w;\n            int param_23 = _739 + 3;\n            float4 _998 = fa_light_texel(param_23);\n            float _999 = _998.x;\n            float cos_inner = _999;\n            if (_999 > 1.5f)\n            {\n                cos_inner = lerp(_993, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_993, cos_inner, dot(-l, normalize(_983.xyz)));\n        }\n        if (_743 && (_755 < 1.5f))\n        {\n            int param_24 = _739 + 6;\n            float4 _1023 = fa_light_texel(param_24);\n            if (_1023.z > 0.5f)\n            {\n                float3 _1031 = -to_light;\n                int param_25 = _739 + 4;\n                int param_26 = _739 + 5;\n                float3 _1045 = fa_light_texel(param_25).xyz;\n                float3 _1049 = fa_light_texel(param_26).xyz;\n                float3 _1058 = float3(dot(_1031, _1045), dot(_1031, _1049), dot(_1031, cross(_1045, _1049)));\n                float3 param_27 = _1058;\n                int _1062 = fa_cube_face(param_27);\n                int param_28 = _1062;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1089 = float2(dot(_1058, cross(param_29, param_30)), dot(_1058, param_30)) / max(dot(_1058, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1093 = _1062 / 3;\n                float2 param_31 = _1023.xy + (float2(float(_1062 - (_1093 * 3)), float(_1093)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1089.x), 0.5f - (0.5f * _1089.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _739 + 7;\n            float4 _1123 = fa_light_texel(param_33);\n            if (_1123.z > 0.5f)\n            {\n                int param_34 = _739 + 2;\n                int param_35 = _739 + 4;\n                int param_36 = _739 + 5;\n                float2 param_37 = _1123.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_743 && _975)\n            {\n                int param_42 = _739 + 6;\n                float4 _1170 = fa_light_texel(param_42);\n                int param_43 = _739 + 7;\n                float4 _1175 = fa_light_texel(param_43);\n                bool _1178 = _1170.z > 0.5f;\n                bool _1185;\n                if (!_1178)\n                {\n                    _1185 = _1175.z > 0.5f;\n                }\n                else\n                {\n                    _1185 = _1178;\n                }\n                if (_1185)\n                {\n                    int param_44 = _739 + 2;\n                    float4 _1192 = fa_light_texel(param_44);\n                    float3 _1196 = normalize(_1192.xyz);\n                    int param_45 = _739 + 4;\n                    float4 _1201 = fa_light_texel(param_45);\n                    int param_46 = _739 + 5;\n                    float4 _1206 = fa_light_texel(param_46);\n                    if (_1178)\n                    {\n                        float3 _1214 = -to_light;\n                        float _1221 = _1192.w;\n                        float _1237 = 0.5f / max(dot(_1214, _1196) * (sqrt(max(1.0f - (_1221 * _1221), 0.0f)) / max(_1221, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1170.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1214, _1201.xyz) * _1237), 0.5f - (dot(_1214, _1206.xyz) * _1237));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1175.z > 0.5f)\n                    {\n                        float2 param_49 = _1175.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1196;\n                        float3 param_52 = _1201.xyz;\n                        float3 param_53 = _1206.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _4766 = _752.xyz * atten;\n    if (_743)\n    {\n        _4766 *= fa_light_tint;\n    }\n    int _1305;\n    if (_769)\n    {\n        _1305 = 0;\n    }\n    else\n    {\n        _1305 = ((_755 > 1.5f) && (_755 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _4777 = { l, _4766, atten, 1.0f, dist, _1305 };\n    return _4777;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2042;\n    if (i == 0)\n    {\n        _2042 = _2052_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2058;\n        if (i == 1)\n        {\n            _2058 = _2052_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2066;\n            if (i == 2)\n            {\n                _2066 = _2052_fa_shadow_split.z;\n            }\n            else\n            {\n                _2066 = _2052_fa_shadow_split.w;\n            }\n            _2058 = _2066;\n        }\n        _2042 = _2058;\n    }\n    return _2042;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2099 = fa_shadow_depth(param, param_1);\n    float _2103;\n    if (conv.x < 0.5f)\n    {\n        _2103 = _2099;\n    }\n    else\n    {\n        _2103 = (conv.y * conv.z) / (conv.z - (_2099 * (conv.z - conv.y)));\n    }\n    return _2103;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2030 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2030), sin(_2030)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2149 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2158;\n        if (k < 0.0f)\n        {\n            _2158 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2158 = k;\n        }\n        float _2178 = clamp((_2158 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2149;\n            float2 _2197 = fa_shadow_vogel(param_3, param_4, param_5) * _2178;\n            float2 param_6 = uv + (_2197 * _2052_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2209 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2209 < (zr - (length(_2197) * plane)))\n            {\n                sum += _2209;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2235 = sum / cnt;\n        float _2245;\n        if (k < 0.0f)\n        {\n            _2245 = (-k) / max(_2235, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2245 = k;\n        }\n        radius = clamp(((max(zr - _2235, 0.0f) * unit) * _2245) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2267 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2267; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2267;\n        float param_11 = _2149;\n        float2 _2286 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2286 * _2052_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2286) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2267);\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2328 = max(_2052_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2333 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2339 = sqrt(1.0f - (_2333 * _2333));\n    float _2346 = min(_2339 / max(_2333, 0.20000000298023223876953125f), 4.0f);\n    float _2351;\n    if (_2052_fa_shadow_bias.y > 0.0f)\n    {\n        _2351 = _2052_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2351 = 1.5f * _2052_fa_shadow_info[ci].x;\n    }\n    float4 _2376 = mul(float4(world + (n * (_2351 * _2339)), 1.0f), _2052_fa_shadow_mat[ci]);\n    float _2383 = _2376.x;\n    bool _2386 = _2383 < _2052_fa_shadow_rect[ci].x;\n    bool _2395;\n    if (!_2386)\n    {\n        _2395 = _2383 > _2052_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2395 = _2386;\n    }\n    bool _2404;\n    if (!_2395)\n    {\n        _2404 = _2376.y < _2052_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2404 = _2395;\n    }\n    bool _2413;\n    if (!_2404)\n    {\n        _2413 = _2376.y > _2052_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2413 = _2404;\n    }\n    bool _2420;\n    if (!_2413)\n    {\n        _2420 = _2376.z > 1.0f;\n    }\n    else\n    {\n        _2420 = _2413;\n    }\n    if (_2420)\n    {\n        return -1.0f;\n    }\n    float _2428;\n    if (_2052_fa_shadow_bias.x > 0.0f)\n    {\n        _2428 = _2052_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2428 = 1.5f * _2052_fa_shadow_info[ci].x;\n    }\n    float2 param = _2376.xy;\n    float4 param_1 = _2052_fa_shadow_rect[ci];\n    float param_2 = _2376.z - ((_2428 * (1.0f + (0.5f * _2346))) / _2328);\n    float param_3 = _2052_fa_shadow_info[ci].x;\n    float param_4 = _2328;\n    float param_5 = _2328 * 0.25f;\n    float param_6 = ((_2052_fa_shadow_info[ci].x * min(_2346, 3.0f)) * 0.5f) / _2328;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2052_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2052_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_395_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2806 = int(_2052_fa_shadow_cfg.x + 0.5f);\n    if (_2806 < 1)\n    {\n        return 1.0f;\n    }\n    float _2821 = dot(world - _2052_fa_shadow_eye.xyz, _2052_fa_shadow_fwd.xyz);\n    int param = _2806 - 1;\n    if (_2821 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2833 = _2806 > 1;\n    bool _2840;\n    if (_2833)\n    {\n        _2840 = _2821 > _2052_fa_shadow_split.x;\n    }\n    else\n    {\n        _2840 = _2833;\n    }\n    if (_2840)\n    {\n        ci = 1;\n    }\n    bool _2844 = _2806 > 2;\n    bool _2851;\n    if (_2844)\n    {\n        _2851 = _2821 > _2052_fa_shadow_split.y;\n    }\n    else\n    {\n        _2851 = _2844;\n    }\n    if (_2851)\n    {\n        ci = 2;\n    }\n    bool _2855 = _2806 > 3;\n    bool _2862;\n    if (_2855)\n    {\n        _2862 = _2821 > _2052_fa_shadow_split.z;\n    }\n    else\n    {\n        _2862 = _2855;\n    }\n    if (_2862)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2806)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2888 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2888;\n        if (_2888 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2052_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2913;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2913 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2913 = _2052_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2932 = _2052_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2913, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2943 = clamp((_2821 - (fa_shadow_split_at(param_7) - _2932)) / _2932, 0.0f, 1.0f);\n        if (_2943 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2806)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2964 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2964;\n                if (_2964 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2943);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2486 = _395_fa_pbr.z < 0.5f;\n    bool _2493;\n    if (!_2486)\n    {\n        _2493 = _2052_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2493 = _2486;\n    }\n    if (_2493)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2052_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2506 = fa_light_texel(param);\n    float _2507 = _2506.x;\n    if (_2507 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2516 = int(_2507 + 0.5f);\n    int param_1 = _2516;\n    float4 _2520 = fa_light_texel(param_1);\n    int param_2 = _2516 + 1;\n    float4 _2525 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2528 = _2520.y;\n    if (_2528 > 0.0f)\n    {\n        float _2545 = 1.0f - smoothstep(0.75f * _2528, _2528, length(world - _2052_fa_shadow_eye.xyz));\n        fade = _2545;\n        if (_2545 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2520.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2569 = (_2516 + 2) + (face * 6);\n    int param_4 = _2569;\n    int param_5 = _2569 + 1;\n    int param_6 = _2569 + 3;\n    float4 _2583 = fa_light_texel(param_6);\n    int param_7 = _2569 + 4;\n    float4 _2588 = fa_light_texel(param_7);\n    int param_8 = _2569 + 5;\n    float4 _2593 = fa_light_texel(param_8);\n    float _2605 = _2593.x * max(dot(_2583, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2610 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2633 = clamp(dot(n, _2583.xyz), -1.0f, 1.0f);\n    float _2652 = min(sqrt(1.0f - (_2633 * _2633)) / max(abs(dot(n, world - lpos)) / max(dot(_2583, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2655 = _2525.y;\n    float _2657;\n    if (_2655 > 0.0f)\n    {\n        _2657 = _2655;\n    }\n    else\n    {\n        _2657 = 1.5f * _2605;\n    }\n    float4 _2677 = float4(world + (n * (_2657 * sqrt(1.0f - (_2610 * _2610)))), 1.0f);\n    float _2681 = dot(_2583, _2677);\n    float _2684 = _2593.y;\n    if (_2681 < _2684)\n    {\n        return 1.0f;\n    }\n    float2 _2699 = float2(dot(fa_light_texel(param_4), _2677), dot(fa_light_texel(param_5), _2677)) / _2681.xx;\n    float _2701 = _2699.x;\n    bool _2704 = _2701 < _2588.x;\n    bool _2713;\n    if (!_2704)\n    {\n        _2713 = _2701 > _2588.z;\n    }\n    else\n    {\n        _2713 = _2704;\n    }\n    bool _2722;\n    if (!_2713)\n    {\n        _2722 = _2699.y < _2588.y;\n    }\n    else\n    {\n        _2722 = _2713;\n    }\n    bool _2731;\n    if (!_2722)\n    {\n        _2731 = _2699.y > _2588.w;\n    }\n    else\n    {\n        _2731 = _2722;\n    }\n    if (_2731)\n    {\n        return 1.0f;\n    }\n    float _2737 = _2525.x;\n    float _2739;\n    if (_2737 > 0.0f)\n    {\n        _2739 = _2737;\n    }\n    else\n    {\n        _2739 = 1.5f * _2605;\n    }\n    float2 param_9 = _2699;\n    float4 param_10 = _2588;\n    float param_11 = _2681 - (_2739 * (1.0f + (0.5f * _2652)));\n    float param_12 = _2605;\n    float param_13 = 1.0f;\n    float param_14 = _2593.z * 0.25f;\n    float param_15 = (_2605 * min(_2652, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2684, _2593.z);\n    int param_17 = int(_2520.z + 0.5f);\n    float param_18 = _2520.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3362 = _395_fa_ct_a.x < 0.5f;\n    bool _3369;\n    if (!_3362)\n    {\n        _3369 = _2052_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3369 = _3362;\n    }\n    if (_3369)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2052_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3382 = fa_light_texel(param);\n    float _3383 = _3382.y;\n    float len = _3383;\n    if (_3383 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3395 = length(world - _395_fa_camera_pos.xyz);\n    float _3405 = 1.0f - smoothstep(0.5f * _395_fa_ct_b.x, _395_fa_ct_b.x, _3395);\n    if (_3405 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3411 = len;\n    float _3414 = min(_3411, 0.89999997615814208984375f * dist);\n    len = _3414;\n    float _3420 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3395);\n    float _3425 = _3420 + (0.5f * _3414);\n    float3 _3431 = world + (gn * _3420);\n    float _3433 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _3498;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3449 = (float(k) + _3433) * 0.083333335816860198974609375f;\n        float3 _3457 = _3431 + (l * (_3449 * len));\n        float4 _3463 = float4(_3457, 1.0f);\n        float _3469 = dot(_395_fa_ct_vpw, _3463);\n        if (_3469 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _3489 = float2(dot(_395_fa_ct_vpx, _3463), dot(_395_fa_ct_vpy, _3463)) / _3469.xx;\n        float _3493 = _3489.x * 0.5f;\n        float _3494 = _3493 + 0.5f;\n        if (_395_fa_ct_a.y > 0.5f)\n        {\n            _3498 = (_3489.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _3498 = 0.5f - (_3489.y * 0.5f);\n        }\n        bool _3514 = _3494 < 0.0f;\n        bool _3521;\n        if (!_3514)\n        {\n            _3521 = _3494 >= 1.0f;\n        }\n        else\n        {\n            _3521 = _3514;\n        }\n        bool _3528;\n        if (!_3521)\n        {\n            _3528 = _3498 < 0.0f;\n        }\n        else\n        {\n            _3528 = _3521;\n        }\n        bool _3535;\n        if (!_3528)\n        {\n            _3535 = _3498 >= 1.0f;\n        }\n        else\n        {\n            _3535 = _3528;\n        }\n        if (_3535)\n        {\n            break;\n        }\n        float4 _3554 = fa_screen_tex.Load(int3(int2(float2(_3494, _3498) * _395_fa_ct_a.zw), 0));\n        if (_3554.w < 0.5f)\n        {\n            continue;\n        }\n        float _3573 = (dot(_395_fa_ct_fwd.xyz, _3457) + _395_fa_ct_fwd.w) - _3554.x;\n        if ((_3573 > _3420) && (_3573 < _3425))\n        {\n            occ = max(occ, (1.0f - (_3449 * _3449)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_3494, 0.5f - _3493), min(_3498, 1.0f - _3498))));\n        }\n    }\n    return 1.0f - (occ * _3405);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _3676 = fa_baked_keep(param);\n    if (_3676 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _4790 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _4790;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3702 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _4792 = _3702.color;\n    float _4793 = _3702.attenuation;\n    float _4794 = _3702.shadow;\n    bool _3705 = _3702.type == 0;\n    if (_3705 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3702.direction;\n        float _3716 = fa_shadow_factor(param_5, param_6);\n        _4794 = _3716;\n        _4792 *= _3716;\n    }\n    else\n    {\n        bool _3727 = _3702.type != 0;\n        bool _3733;\n        if (_3727)\n        {\n            _3733 = _4793 > 0.0f;\n        }\n        else\n        {\n            _3733 = _3727;\n        }\n        if (_3733)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3702.direction;\n            float _3752 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4794 = _3752;\n            _4792 *= _3752;\n        }\n    }\n    bool _3762 = _395_fa_ct_a.x > 0.5f;\n    bool _3768;\n    if (_3762)\n    {\n        _3768 = _4793 > 0.0f;\n    }\n    else\n    {\n        _3768 = _3762;\n    }\n    if (_3768)\n    {\n        float _3775;\n        if (_3705)\n        {\n            _3775 = 1000000000.0f;\n        }\n        else\n        {\n            _3775 = _3702._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3702.direction;\n        float param_18 = _3775;\n        float _3793 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _4794 *= _3793;\n        _4792 *= _3793;\n    }\n    float _3806 = _4793;\n    float _3807 = _3806 * _3676;\n    _4793 = _3807;\n    float3 _3811 = _4792;\n    float3 _3812 = _3811 * _3676;\n    _4792 = _3812;\n    LightSample _4809 = { _3702.direction, _3812, _3807, _4794, _3702._distance, _3702.type };\n    return _4809;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2052_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _2988 = int(_2052_fa_shadow_cfg.x + 0.5f);\n    float _2998 = dot(world - _2052_fa_shadow_eye.xyz, _2052_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3003 = _2988 > 0;\n    bool _3012;\n    if (_3003)\n    {\n        int param = _2988 - 1;\n        _3012 = _2998 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3012 = _3003;\n    }\n    if (_3012)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3018 = _2988 > 1;\n        bool _3025;\n        if (_3018)\n        {\n            _3025 = _2998 > _2052_fa_shadow_split.x;\n        }\n        else\n        {\n            _3025 = _3018;\n        }\n        if (_3025)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3031 = _2988 > 2;\n        bool _3038;\n        if (_3031)\n        {\n            _3038 = _2998 > _2052_fa_shadow_split.y;\n        }\n        else\n        {\n            _3038 = _3031;\n        }\n        if (_3038)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3044 = _2988 > 3;\n        bool _3051;\n        if (_3044)\n        {\n            _3051 = _2998 > _2052_fa_shadow_split.z;\n        }\n        else\n        {\n            _3051 = _3044;\n        }\n        if (_3051)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _4633 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4633 = -_4633;\n    }\n    float3 _4224 = normalize(_395_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _4646 = { fa_world_pos, _4633, fa_world_tangent, fa_uv, fa_vertex_color, _4224, gl_FrontFacing };\n    SurfaceInput param_1 = _4646;\n    Surface _4232 = fa_standard_surface(param_1);\n    float3 _4664 = _4232.albedo;\n    float _4665 = _4232.alpha;\n    float3 _4666 = _4232.normal;\n    float _4667 = _4232.metallic;\n    float _4668 = _4232.roughness;\n    float _4669 = _4232.occlusion;\n    float3 _4670 = _4232.emission;\n    float _4671 = _4232.clearcoat;\n    float _4672 = _4232.clearcoat_roughness;\n    float3 _4673 = _4232.sheen_color;\n    float _4674 = _4232.sheen_roughness;\n    float _4675 = _4232.anisotropy;\n    float _4676 = _4232.anisotropy_rotation;\n    float _4677 = _4232.specular;\n    float _4678 = _4232.ior;\n    float3 _4679 = _4232.specular_color;\n    SurfaceInput _4654 = { fa_world_pos, _4633, fa_world_tangent, fa_uv, fa_vertex_color, _4224, gl_FrontFacing };\n    SurfaceInput param_2 = _4654;\n    Surface param_3 = _4232;\n    surface(param_2, param_3);\n    _4664 = param_3.albedo;\n    _4665 = param_3.alpha;\n    _4666 = param_3.normal;\n    _4667 = param_3.metallic;\n    _4668 = param_3.roughness;\n    _4669 = param_3.occlusion;\n    _4670 = param_3.emission;\n    _4671 = param_3.clearcoat;\n    _4672 = param_3.clearcoat_roughness;\n    _4673 = param_3.sheen_color;\n    _4674 = param_3.sheen_roughness;\n    _4675 = param_3.anisotropy;\n    _4676 = param_3.anisotropy_rotation;\n    _4677 = param_3.specular;\n    _4678 = param_3.ior;\n    _4679 = param_3.specular_color;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _4633;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4664 = param_6;\n    _4666 = param_7;\n    float3 result;\n    if (_395_fa_emissive.w > 0.5f)\n    {\n        result = _4664;\n    }\n    else\n    {\n        float3 _4270 = _4666;\n        float3 _4271 = normalize(_4270);\n        _4666 = _4271;\n        float3 param_8 = _4271;\n        float3 lit = (fa_indirect_diffuse(param_8) * _4664) * _4669;\n        int _4290 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4290; ln++)\n        {\n            int param_9 = ln;\n            int _4303 = fa_cl_light(param_9);\n            int param_10 = _4303;\n            if (fa_baked_keep(param_10) <= 0.0f)\n            {\n                continue;\n            }\n            int param_11 = _4303;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _4633;\n            LightSample _4319 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput _4662 = { fa_world_pos, _4633, fa_world_tangent, fa_uv, fa_vertex_color, _4224, gl_FrontFacing };\n            SurfaceInput param_14 = _4662;\n            Surface _4745 = { _4664, _4665, _4666, _4667, _4668, _4669, _4670, _4671, _4672, _4673, _4674, _4675, _4676, _4677, _4678, _4679 };\n            Surface param_15 = _4745;\n            LightSample param_16 = _4319;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _4334 = result;\n    float3 _4335 = _4334 + _4670;\n    result = _4335;\n    float3 param_17 = _4335;\n    float3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _4344 = _395_fa_fog.w > 0.0f;\n    bool _4351;\n    if (!_4344)\n    {\n        _4351 = _395_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4351 = _4344;\n    }\n    if (_4351)\n    {\n        float3 _4360 = fa_world_pos - _395_fa_camera_pos.xyz;\n        float _4366 = dot(_4360, _395_fa_fog_c.xyz);\n        bool _4370 = _395_fa_fog_c.w > 0.5f;\n        float _4371;\n        if (_4370)\n        {\n            _4371 = _4366;\n        }\n        else\n        {\n            _4371 = length(_4360);\n        }\n        float _4383 = _4371 - _395_fa_fog_b.x;\n        if (_4383 > 0.0f)\n        {\n            float _4392 = _395_fa_fog.w * _4383;\n            float tau = _4392 * _4392;\n            if (_395_fa_fog_b.y > 0.0f)\n            {\n                float _4408;\n                if (_4370)\n                {\n                    _4408 = fa_world_pos.y - (_395_fa_fog_c.y * _4366);\n                }\n                else\n                {\n                    _4408 = _395_fa_camera_pos.y;\n                }\n                float _4429 = lerp(_4408, fa_world_pos.y, clamp(_395_fa_fog_b.x / _4371, 0.0f, 1.0f));\n                float _4433 = fa_world_pos.y - _4429;\n                float _4438 = _4429 - _395_fa_fog_b.z;\n                float _4443 = fa_world_pos.y - _395_fa_fog_b.z;\n                bool _4446 = _4438 <= 0.0f;\n                bool _4447 = !_4446;\n                bool _4453;\n                if (_4447)\n                {\n                    _4453 = _395_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4453 = _4446;\n                }\n                float _4454;\n                if (_4453)\n                {\n                    _4454 = _395_fa_fog_b.y;\n                }\n                else\n                {\n                    _4454 = _395_fa_fog_b.y * exp(-min(_395_fa_fog_b.w * _4438, 80.0f));\n                }\n                bool _4481;\n                if (_4447)\n                {\n                    _4481 = _395_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4481 = _4446;\n                }\n                float _4482;\n                if (_4481)\n                {\n                    _4482 = _395_fa_fog_b.y * _4438;\n                }\n                else\n                {\n                    _4482 = (_395_fa_fog_b.y * (1.0f - exp(-min(_395_fa_fog_b.w * _4438, 80.0f)))) / _395_fa_fog_b.w;\n                }\n                bool _4507 = _4443 <= 0.0f;\n                bool _4514;\n                if (!_4507)\n                {\n                    _4514 = _395_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _4514 = _4507;\n                }\n                float _4515;\n                if (_4514)\n                {\n                    _4515 = _395_fa_fog_b.y * _4443;\n                }\n                else\n                {\n                    _4515 = (_395_fa_fog_b.y * (1.0f - exp(-min(_395_fa_fog_b.w * _4443, 80.0f)))) / _395_fa_fog_b.w;\n                }\n                float _4542;\n                if (abs(_4433) < 0.001000000047497451305389404296875f)\n                {\n                    _4542 = _4454;\n                }\n                else\n                {\n                    _4542 = (_4515 - _4482) / _4433;\n                }\n                tau += (_4383 * max(_4542, 0.0f));\n            }\n            result = lerp(result, _395_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _4665);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_395",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2052",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _292 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _292;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _299 = _160.world_pos;\n    float4 _171 = float4(_299, 1.0f);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _215_fa_camera_pos : packoffset(c0);\n    float4 _215_fa_ambient : packoffset(c1);\n    float4 _215_fa_base_color : packoffset(c2);\n    float4 _215_fa_emissive : packoffset(c3);\n    float4 _215_fa_model_emissive : packoffset(c4);\n    float4 _215_fa_pbr : packoffset(c5);\n    float4 _215_fa_maps : packoffset(c6);\n    float4 _215_fa_fog : packoffset(c7);\n    float4 _215_fa_fog_b : packoffset(c8);\n    float4 _215_fa_fog_c : packoffset(c9);\n    float4 _215_fa_counts : packoffset(c10);\n    float4 _215_fa_env_sky : packoffset(c11);\n    float4 _215_fa_env_horizon : packoffset(c12);\n    float4 _215_fa_time : packoffset(c13);\n    float4 _215_fa_cl_vpx : packoffset(c14);\n    float4 _215_fa_cl_vpy : packoffset(c15);\n    float4 _215_fa_cl_vpw : packoffset(c16);\n    float4 _215_fa_cl_fwd : packoffset(c17);\n    float4 _215_fa_cl_grid : packoffset(c18);\n    float4 _215_fa_cl_info : packoffset(c19);\n    float4 _215_fa_layers_a : packoffset(c20);\n    float4 _215_fa_layers_b : packoffset(c21);\n    float4 _215_fa_layers_c : packoffset(c22);\n    float4 _215_fa_layers_d : packoffset(c23);\n    float4 _215_fa_ct_a : packoffset(c24);\n    float4 _215_fa_ct_b : packoffset(c25);\n    float4 _215_fa_ct_vpx : packoffset(c26);\n    float4 _215_fa_ct_vpy : packoffset(c27);\n    float4 _215_fa_ct_vpw : packoffset(c28);\n    float4 _215_fa_ct_fwd : packoffset(c29);\n    float4 _215_fa_probe_sh[9] : packoffset(c30);\n    float4 _215_fa_atlas : packoffset(c39);\n    float4 _215_fa_rpa_tile : packoffset(c40);\n    float4 _215_fa_rpa_pos : packoffset(c41);\n    float4 _215_fa_rpa_bx : packoffset(c42);\n    float4 _215_fa_rpa_by : packoffset(c43);\n    float4 _215_fa_rpa_bz : packoffset(c44);\n    float4 _215_fa_rpb_tile : packoffset(c45);\n    float4 _215_fa_rpb_pos : packoffset(c46);\n    float4 _215_fa_rpb_bx : packoffset(c47);\n    float4 _215_fa_rpb_by : packoffset(c48);\n    float4 _215_fa_rpb_bz : packoffset(c49);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _215_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _227 = fa_tex_fix(param_2, param_3);\n    float4 _785 = base_t;\n    _785.x = _227.x;\n    _785.y = _227.y;\n    _785.z = _227.z;\n    base_t = _785;\n    float4 _243 = (_785 * _215_fa_base_color) * i.vertex_color;\n    float3 _748 = i.world_normal;\n    if (_215_fa_maps.z > 0.5f)\n    {\n        float param_4 = _215_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _277 = fa_tex_fix(param_6, param_7);\n        float3 _281 = (_277 * 2.0f) - 1.0f.xxx;\n        float2 _286 = _281.xy * _215_fa_maps.x;\n        float3 _793 = _281;\n        _793.x = _286.x;\n        _793.y = _286.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _215_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _315 = fa_tex_fix(param_12, param_13);\n    float4 _796 = mrt;\n    _796.x = _315.x;\n    _796.y = _315.y;\n    _796.z = _315.z;\n    mrt = _796;\n    float4 _345 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _215_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = _215_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _387 = fa_tex_fix(param_20, param_21);\n    float _753 = _215_fa_layers_a.x;\n    float _754 = _215_fa_layers_a.y;\n    float _757 = _215_fa_layers_a.z;\n    float _756 = _215_fa_layers_b.w;\n    float _759 = _215_fa_layers_c.x;\n    if (_215_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_215_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _753 *= _357.y;\n            _754 *= _357.z;\n            _756 *= _345.w;\n        }\n        if (_215_fa_layers_c.z > 1.5f)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    Surface _778 = { _243.xyz, _243.w, _748, clamp(_215_fa_pbr.x * _315.z, 0.0f, 1.0f), clamp(_215_fa_pbr.y * _315.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_215_fa_maps.y * (_357.x - 1.0f)), _215_fa_emissive.xyz + (_215_fa_model_emissive.xyz * _387), _753, _754, _215_fa_layers_b.xyz, _756, _757, _215_fa_layers_a.w, _759, _215_fa_layers_c.y, _215_fa_layers_d.xyz };\n    return _778;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _659 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    float3 _521 = normalize(_215_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _672 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing };\n    SurfaceInput param = _672;\n    SurfaceInput _680 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing };\n    SurfaceInput param_1 = _680;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _536 = normalize(param_2.normal);\n    float3 _551 = normalize(float3(dot(fa_pre_r0, _536), dot(fa_pre_r1, _536), dot(fa_pre_r2, _536)));\n    float _563 = _551.z;\n    float2 e = _551.xy / ((abs(_551.x) + abs(_551.y)) + abs(_563)).xx;\n    if (_563 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_215",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _215_fa_camera_pos : packoffset(c0);\n    float4 _215_fa_ambient : packoffset(c1);\n    float4 _215_fa_base_color : packoffset(c2);\n    float4 _215_fa_emissive : packoffset(c3);\n    float4 _215_fa_model_emissive : packoffset(c4);\n    float4 _215_fa_pbr : packoffset(c5);\n    float4 _215_fa_maps : packoffset(c6);\n    float4 _215_fa_fog : packoffset(c7);\n    float4 _215_fa_fog_b : packoffset(c8);\n    float4 _215_fa_fog_c : packoffset(c9);\n    float4 _215_fa_counts : packoffset(c10);\n    float4 _215_fa_env_sky : packoffset(c11);\n    float4 _215_fa_env_horizon : packoffset(c12);\n    float4 _215_fa_time : packoffset(c13);\n    float4 _215_fa_cl_vpx : packoffset(c14);\n    float4 _215_fa_cl_vpy : packoffset(c15);\n    float4 _215_fa_cl_vpw : packoffset(c16);\n    float4 _215_fa_cl_fwd : packoffset(c17);\n    float4 _215_fa_cl_grid : packoffset(c18);\n    float4 _215_fa_cl_info : packoffset(c19);\n    float4 _215_fa_layers_a : packoffset(c20);\n    float4 _215_fa_layers_b : packoffset(c21);\n    float4 _215_fa_layers_c : packoffset(c22);\n    float4 _215_fa_layers_d : packoffset(c23);\n    float4 _215_fa_ct_a : packoffset(c24);\n    float4 _215_fa_ct_b : packoffset(c25);\n    float4 _215_fa_ct_vpx : packoffset(c26);\n    float4 _215_fa_ct_vpy : packoffset(c27);\n    float4 _215_fa_ct_vpw : packoffset(c28);\n    float4 _215_fa_ct_fwd : packoffset(c29);\n    float4 _215_fa_probe_sh[9] : packoffset(c30);\n    float4 _215_fa_atlas : packoffset(c39);\n    float4 _215_fa_rpa_tile : packoffset(c40);\n    float4 _215_fa_rpa_pos : packoffset(c41);\n    float4 _215_fa_rpa_bx : packoffset(c42);\n    float4 _215_fa_rpa_by : packoffset(c43);\n    float4 _215_fa_rpa_bz : packoffset(c44);\n    float4 _215_fa_rpb_tile : packoffset(c45);\n    float4 _215_fa_rpb_pos : packoffset(c46);\n    float4 _215_fa_rpb_bx : packoffset(c47);\n    float4 _215_fa_rpb_by : packoffset(c48);\n    float4 _215_fa_rpb_bz : packoffset(c49);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _215_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _227 = fa_tex_fix(param_2, param_3);\n    float4 _785 = base_t;\n    _785.x = _227.x;\n    _785.y = _227.y;\n    _785.z = _227.z;\n    base_t = _785;\n    float4 _243 = (_785 * _215_fa_base_color) * i.vertex_color;\n    float3 _748 = i.world_normal;\n    if (_215_fa_maps.z > 0.5f)\n    {\n        float param_4 = _215_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _277 = fa_tex_fix(param_6, param_7);\n        float3 _281 = (_277 * 2.0f) - 1.0f.xxx;\n        float2 _286 = _281.xy * _215_fa_maps.x;\n        float3 _793 = _281;\n        _793.x = _286.x;\n        _793.y = _286.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _793;\n        _748 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _215_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _315 = fa_tex_fix(param_12, param_13);\n    float4 _796 = mrt;\n    _796.x = _315.x;\n    _796.y = _315.y;\n    _796.z = _315.z;\n    mrt = _796;\n    float4 _345 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _215_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = _215_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _387 = fa_tex_fix(param_20, param_21);\n    float _753 = _215_fa_layers_a.x;\n    float _754 = _215_fa_layers_a.y;\n    float _757 = _215_fa_layers_a.z;\n    float _756 = _215_fa_layers_b.w;\n    float _759 = _215_fa_layers_c.x;\n    if (_215_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_215_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _753 *= _357.y;\n            _754 *= _357.z;\n            _756 *= _345.w;\n        }\n        if (_215_fa_layers_c.z > 1.5f)\n        {\n            _757 *= mrt.x;\n            _759 *= mrt.w;\n        }\n    }\n    Surface _778 = { _243.xyz, _243.w, _748, clamp(_215_fa_pbr.x * _315.z, 0.0f, 1.0f), clamp(_215_fa_pbr.y * _315.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_215_fa_maps.y * (_357.x - 1.0f)), _215_fa_emissive.xyz + (_215_fa_model_emissive.xyz * _387), _753, _754, _215_fa_layers_b.xyz, _756, _757, _215_fa_layers_a.w, _759, _215_fa_layers_c.y, _215_fa_layers_d.xyz };\n    return _778;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _659 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _659 = -_659;\n    }\n    float3 _521 = normalize(_215_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _672 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing };\n    SurfaceInput param = _672;\n    SurfaceInput _680 = { fa_world_pos, _659, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing };\n    SurfaceInput param_1 = _680;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _536 = normalize(param_2.normal);\n    float3 _551 = normalize(float3(dot(fa_pre_r0, _536), dot(fa_pre_r1, _536), dot(fa_pre_r2, _536)));\n    float _563 = _551.z;\n    float2 e = _551.xy / ((abs(_551.x) + abs(_551.y)) + abs(_563)).xx;\n    if (_563 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_215",
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
