{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "7dfc96845a84a2e1eeb941c4a325b3e44f1dd63d04807d1dd0da2d9b2c3c7186",
  "slang": "hlsl5",
  "params": [
    "dark"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _263 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _263;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_270, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _414_fa_camera_pos : packoffset(c0);\n    float4 _414_fa_ambient : packoffset(c1);\n    float4 _414_fa_base_color : packoffset(c2);\n    float4 _414_fa_emissive : packoffset(c3);\n    float4 _414_fa_model_emissive : packoffset(c4);\n    float4 _414_fa_pbr : packoffset(c5);\n    float4 _414_fa_maps : packoffset(c6);\n    float4 _414_fa_fog : packoffset(c7);\n    float4 _414_fa_fog_b : packoffset(c8);\n    float4 _414_fa_fog_c : packoffset(c9);\n    float4 _414_fa_counts : packoffset(c10);\n    float4 _414_fa_env_sky : packoffset(c11);\n    float4 _414_fa_env_horizon : packoffset(c12);\n    float4 _414_fa_time : packoffset(c13);\n    float4 _414_fa_cl_vpx : packoffset(c14);\n    float4 _414_fa_cl_vpy : packoffset(c15);\n    float4 _414_fa_cl_vpw : packoffset(c16);\n    float4 _414_fa_cl_fwd : packoffset(c17);\n    float4 _414_fa_cl_grid : packoffset(c18);\n    float4 _414_fa_cl_info : packoffset(c19);\n    float4 _414_fa_layers_a : packoffset(c20);\n    float4 _414_fa_layers_b : packoffset(c21);\n    float4 _414_fa_layers_c : packoffset(c22);\n    float4 _414_fa_layers_d : packoffset(c23);\n    float4 _414_fa_ct_a : packoffset(c24);\n    float4 _414_fa_ct_b : packoffset(c25);\n    float4 _414_fa_ct_vpx : packoffset(c26);\n    float4 _414_fa_ct_vpy : packoffset(c27);\n    float4 _414_fa_ct_vpw : packoffset(c28);\n    float4 _414_fa_ct_fwd : packoffset(c29);\n    float4 _414_fa_tr_a : packoffset(c30);\n    float4 _414_fa_tr_b : packoffset(c31);\n    float4 _414_fa_probe_sh[9] : packoffset(c32);\n    float4 _414_fa_atlas : packoffset(c41);\n    float4 _414_fa_rpa_tile : packoffset(c42);\n    float4 _414_fa_rpa_pos : packoffset(c43);\n    float4 _414_fa_rpa_bx : packoffset(c44);\n    float4 _414_fa_rpa_by : packoffset(c45);\n    float4 _414_fa_rpa_bz : packoffset(c46);\n    float4 _414_fa_rpb_tile : packoffset(c47);\n    float4 _414_fa_rpb_pos : packoffset(c48);\n    float4 _414_fa_rpb_bx : packoffset(c49);\n    float4 _414_fa_rpb_by : packoffset(c50);\n    float4 _414_fa_rpb_bz : packoffset(c51);\n    float4 _414_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2066_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2066_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2066_fa_shadow_info[4] : packoffset(c20);\n    float4 _2066_fa_shadow_split : packoffset(c24);\n    float4 _2066_fa_shadow_cfg : packoffset(c25);\n    float4 _2066_fa_shadow_bias : packoffset(c26);\n    float4 _2066_fa_shadow_eye : packoffset(c27);\n    float4 _2066_fa_shadow_fwd : packoffset(c28);\n    float4 _2066_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _4066_dark : packoffset(c0);\n    float _4066_fa_pad0 : packoffset(c0.y);\n    float _4066_fa_pad1 : packoffset(c0.z);\n    float _4066_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1342 = _414_fa_cl_info.x < 0.0f;\n    bool _1349;\n    if (!_1342)\n    {\n        _1349 = _414_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1349 = _1342;\n    }\n    bool _1357;\n    if (!_1349)\n    {\n        _1357 = _414_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1357 = _1349;\n    }\n    bool _1364;\n    if (!_1357)\n    {\n        _1364 = _414_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1364 = _1357;\n    }\n    bool _1371;\n    if (!_1364)\n    {\n        _1371 = _414_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1371 = _1364;\n    }\n    if (_1371)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1381 = float4(world_pos, 1.0f);\n    float _1387 = dot(_414_fa_cl_vpw, _1381);\n    if (!(_1387 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1409 = float2(dot(_414_fa_cl_vpx, _1381), dot(_414_fa_cl_vpy, _1381)) / _1387.xx;\n    int _1413 = int(_414_fa_cl_grid.x);\n    int _1417 = int(_414_fa_cl_grid.y);\n    int param = (int(_414_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_414_fa_cl_fwd.xyz, world_pos) + _414_fa_cl_fwd.w, _414_fa_cl_grid.w) / _414_fa_cl_grid.w) * _414_fa_cl_grid.z)), 0, int(_414_fa_cl_info.y) - 1) * _1417) + clamp(int(floor(((_1409.y * 0.5f) + 0.5f) * _414_fa_cl_grid.y)), 0, _1417 - 1)) * _1413)) + clamp(int(floor(((_1409.x * 0.5f) + 0.5f) * _414_fa_cl_grid.x)), 0, _1413 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1493 = fa_cluster_texel(param);\n    return int2(int(_1493.x), int(_1493.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_414_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3884 = fa_cluster_lookup(param);\n    fa_cl_slot = _3884.x;\n    fa_cl_local = _3884.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4115 = fa_linear_to_srgb(param);\n        c = _4115;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4123 = fa_srgb_to_linear(param_1);\n            c = _4123;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _296;\n    if (i.front_facing)\n    {\n        _296 = i.world_normal;\n    }\n    else\n    {\n        _296 = -i.world_normal;\n    }\n    float3 _320 = normalize(i.world_tangent.xyz - (_296 * dot(_296, i.world_tangent.xyz)));\n    float3 _347 = normalize(((_320 * m.x) + ((cross(_296, _320) * i.world_tangent.w) * m.y)) + (_296 * m.z));\n    float3 _350;\n    if (i.front_facing)\n    {\n        _350 = _347;\n    }\n    else\n    {\n        _350 = -_347;\n    }\n    return _350;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _414_fa_env_horizon.w);\n    float param = _414_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4155 = fa_tex_fix(param_2, param_3);\n    float4 _5945 = base_t;\n    _5945.x = _4155.x;\n    _5945.y = _4155.y;\n    _5945.z = _4155.z;\n    base_t = _5945;\n    float4 _4169 = (_5945 * _414_fa_base_color) * i.vertex_color;\n    float3 _5772 = i.world_normal;\n    if (_414_fa_maps.z > 0.5f)\n    {\n        float param_4 = _414_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _414_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4203 = fa_tex_fix(param_6, param_7);\n        float3 _4206 = (_4203 * 2.0f) - 1.0f.xxx;\n        float2 _4211 = _4206.xy * _414_fa_maps.x;\n        float3 _5953 = _4206;\n        _5953.x = _4211.x;\n        _5953.y = _4211.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5953;\n        _5772 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _414_fa_env_horizon.w);\n    float param_10 = _414_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4241 = fa_tex_fix(param_12, param_13);\n    float4 _5956 = mrt;\n    _5956.x = _4241.x;\n    _5956.y = _4241.y;\n    _5956.z = _4241.z;\n    mrt = _5956;\n    float4 _4271 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _414_fa_env_horizon.w);\n    float param_14 = _414_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4271.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4282 = fa_tex_fix(param_16, param_17);\n    float param_18 = _414_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _414_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4314 = fa_tex_fix(param_20, param_21);\n    float _5777 = _414_fa_layers_a.x;\n    float _5778 = _414_fa_layers_a.y;\n    float _5781 = _414_fa_layers_a.z;\n    float _5780 = _414_fa_layers_b.w;\n    float _5783 = _414_fa_layers_c.x;\n    if (_414_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_414_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _5777 *= _4282.y;\n            _5778 *= _4282.z;\n            _5780 *= _4271.w;\n        }\n        if (_414_fa_layers_c.z > 1.5f)\n        {\n            _5781 *= mrt.x;\n            _5783 *= mrt.w;\n        }\n    }\n    Surface _5810 = { _4169.xyz, _4169.w, _5772, clamp(_414_fa_pbr.x * _4241.z, 0.0f, 1.0f), clamp(_414_fa_pbr.y * _4241.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_414_fa_maps.y * (_4282.x - 1.0f)), _414_fa_emissive.xyz + (_414_fa_model_emissive.xyz * _4314), _5777, _5778, _414_fa_layers_b.xyz, _5780, _5781, _414_fa_layers_a.w, _5783, _414_fa_layers_c.y, _414_fa_layers_d.xyz, _414_fa_tr_a.x, _414_fa_tr_a.y, _414_fa_tr_b.xyz, _414_fa_tr_a.z };\n    return _5810;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1573 = rect.zw - rect.xy;\n    float2 _1577 = _1573 * atlas;\n    float2 _1581 = ddx * _1577;\n    float2 _1585 = ddy * _1577;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1573), clamp(0.5f * log2(max(max(dot(_1581, _1581), dot(_1585, _1585)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1618 = _414_fa_counts.y < 0.5f;\n    bool _1625;\n    if (!_1618)\n    {\n        _1625 = _414_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1625 = _1618;\n    }\n    if (_1625)\n    {\n        return;\n    }\n    float3 _1631 = ddx(world_pos);\n    float3 _1634 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1638 = fa_cluster_texel(param);\n    int _1642 = int(_1638.w);\n    if (_1642 < 1)\n    {\n        return;\n    }\n    int _1652 = int(_414_fa_counts.y + 0.5f);\n    int param_1 = _1652;\n    float4 _1656 = fa_light_texel(param_1);\n    float2 _1659 = _1656.yz;\n    int _1663 = int(_1656.w);\n    int param_2 = _1652 + 1;\n    float4 _1668 = fa_light_texel(param_2);\n    float _1669 = _1668.x;\n    int _1675 = int(_414_fa_counts.w + 0.5f) - 1;\n    int _1679 = int(_1638.z);\n    float3 _1944;\n    for (int k = 0; k < _1642; k++)\n    {\n        int _1692 = _1679 + k;\n        int param_3 = _1663 + (_1692 >> 2);\n        int _1709 = (_1652 + 2) + (int(fa_light_texel(param_3)[_1692 & 3]) * 7);\n        int param_4 = _1709 + 6;\n        float4 _1714 = fa_light_texel(param_4);\n        if (((int(_1714.w + 0.5f) >> _1675) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1709;\n        float4 _1729 = fa_light_texel(param_5);\n        int param_6 = _1709 + 1;\n        float4 _1734 = fa_light_texel(param_6);\n        int param_7 = _1709 + 2;\n        float4 _1739 = fa_light_texel(param_7);\n        float3 _1742 = _1729.xyz;\n        float _1747 = dot(_1742, world_pos) + _1729.w;\n        float3 _1749 = _1734.xyz;\n        float _1754 = dot(_1749, world_pos) + _1734.w;\n        float3 _1756 = _1739.xyz;\n        float _1761 = dot(_1756, world_pos) + _1739.w;\n        bool _1766 = abs(_1747) > 0.5f;\n        bool _1774;\n        if (!_1766)\n        {\n            _1774 = abs(_1754) > 0.5f;\n        }\n        else\n        {\n            _1774 = _1766;\n        }\n        bool _1782;\n        if (!_1774)\n        {\n            _1782 = abs(_1761) > 0.5f;\n        }\n        else\n        {\n            _1782 = _1774;\n        }\n        if (_1782)\n        {\n            continue;\n        }\n        float _1797 = clamp(dot(geo_normal, normalize(_1756)) * _1714.z, 0.0f, 1.0f);\n        if (_1797 <= 0.0f)\n        {\n            continue;\n        }\n        float _1817 = (clamp((0.5f - abs(_1761)) * 10.0f, 0.0f, 1.0f) * _1797) * _1714.x;\n        float2 _1825 = float2(_1747 + 0.5f, 0.5f - _1754);\n        float2 _1835 = float2(dot(_1742, _1631), dot(_1749, _1631));\n        float2 _1845 = float2(dot(_1742, _1634), dot(_1749, _1634));\n        int param_8 = _1709 + 5;\n        float4 _1850 = fa_light_texel(param_8);\n        int param_9 = _1709 + 3;\n        float4 _1855 = fa_light_texel(param_9);\n        int param_10 = _1709 + 4;\n        float4 _1860 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1850.xyz;\n        bool _1870 = _1855.z > _1855.x;\n        if (_1870)\n        {\n            float4 param_11 = _1855;\n            float2 param_12 = _1825;\n            float2 param_13 = _1659;\n            float2 param_14 = _1835;\n            float2 param_15 = _1845;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1669 > 0.5f) && (_1669 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1896 = fa_dc_to_linear(param_16);\n                float4 _5860 = tx;\n                _5860.x = _1896.x;\n                _5860.y = _1896.y;\n                _5860.z = _1896.z;\n                tx = _5860;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1817 * tex_a) * _1850.w, 0.0f, 1.0f).xxx);\n        if (_1860.z > _1860.x)\n        {\n            float4 param_17 = _1860;\n            float2 param_18 = _1825;\n            float2 param_19 = _1659;\n            float2 param_20 = _1835;\n            float2 param_21 = _1845;\n            float4 _1940 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1669 > 1.5f)\n            {\n                float3 param_22 = _1940.xyz;\n                float3 _1950 = fa_dc_to_srgb(param_22);\n                _1944 = _1950;\n            }\n            else\n            {\n                _1944 = _1940.xyz;\n            }\n            float3 _1959 = (_1944 * 2.0f) - 1.0f.xxx;\n            float2 _1964 = _1959.xy * _1714.y;\n            float3 _1986 = (normalize(_1742) * _1964.x) + (normalize(_1749) * _1964.y);\n            float3 _1989 = normalize(normal);\n            normal = normalize(lerp(_1989, normalize((_1989 * max(_1959.z, 0.0500000007450580596923828125f)) + (_1986 - (_1989 * dot(_1989, _1986)))), clamp(_1817 * (_1870 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3405_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3405_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_414_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3346 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3346;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3456 = (1.0f - _414_fa_rpa_tile.w) - _414_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3462 = _414_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3456 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3462)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _414_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3456;\n            }\n        }\n        else\n        {\n            amb = _414_fa_ambient.xyz * _3456;\n        }\n    }\n    bool _3514 = _414_fa_rpa_tile.w > 0.0f;\n    if (_3514)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _414_fa_rpa_tile.xy;\n            float param_4 = _414_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _414_fa_rpa_tile.w);\n        }\n    }\n    bool _3545 = _414_fa_rpb_tile.w > 0.0f;\n    if (_3545)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _414_fa_rpb_tile.xy;\n            float param_7 = _414_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _414_fa_rpb_tile.w);\n        }\n    }\n    if ((_3462 || _3514) || _3545)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3366 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3369 = _3366.x;\n    float _3371 = _3366.z;\n    float2 e = float2(_3369, _3371);\n    if (_3366.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3371)) * ((_3369 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3369)) * ((_3371 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _4428 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _4433 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _4438 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _4443 = fa_light_texel(param_3);\n    bool _4446 = _4443.z < 0.5f;\n    bool _4454;\n    if (!_4446)\n    {\n        _4454 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _4454 = _4446;\n    }\n    if (_4454)\n    {\n        return 0.0f.xxx;\n    }\n    float _4461 = max(_4428.w, 9.9999997473787516355514526367188e-05f);\n    float3 _4464 = _4433.xyz;\n    float3 _4468 = _4428.xyz;\n    float3 _4472 = (fa_world_pos - _4468) / _4461.xxx;\n    float3 _4481 = min(_4472 + 0.5f.xxx, (_4464 - 0.5f.xxx) - _4472);\n    float _4490 = min(_4481.x, min(_4481.y, _4481.z));\n    if (!(_4490 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4505 = _4464 - 1.0f.xxx;\n    float3 _4506 = clamp(_4472, 0.0f.xxx, _4505);\n    float3 _4514 = min(floor(_4506), max(_4464 - 2.0f.xxx, 0.0f.xxx));\n    float3 _4518 = _4506 - _4514;\n    float3 _4530 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _4461));\n    int _4535 = int(_4438.y + 0.5f);\n    float _4540 = 0.3257350027561187744140625f * n.y;\n    float _4544 = 0.3257350027561187744140625f * n.z;\n    float _4548 = 0.3257350027561187744140625f * n.x;\n    float _4555 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _4562 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _4571 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _4578 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _4591 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _4598 = 8 + int(_4443.w);\n    float _4625;\n    float _4638;\n    float _4652;\n    for (int k = 0; k < _4598; k++)\n    {\n        float _4611 = float(k & 1);\n        float _4615 = float((k >> 1) & 1);\n        float _4619 = float((k >> 2) & 1);\n        if (_4611 > 0.5f)\n        {\n            _4625 = _4518.x;\n        }\n        else\n        {\n            _4625 = 1.0f - _4518.x;\n        }\n        if (_4615 > 0.5f)\n        {\n            _4638 = _4518.y;\n        }\n        else\n        {\n            _4638 = 1.0f - _4518.y;\n        }\n        if (_4619 > 0.5f)\n        {\n            _4652 = _4518.z;\n        }\n        else\n        {\n            _4652 = 1.0f - _4518.z;\n        }\n        float _4662 = (_4625 * _4638) * _4652;\n        if (!(_4662 > 0.0f))\n        {\n            continue;\n        }\n        float3 _4675 = min(_4514 + float3(_4611, _4615, _4619), _4505);\n        int _4695 = int(((_4438.x + _4675.x) + (_4433.x * (_4675.y + (_4433.y * _4675.z)))) + 0.5f);\n        float2 _4710 = float2(float(_4695 % _4535) * 10.0f, 1024.0f + (float(_4695 / _4535) * 11.0f));\n        float2 param_4 = _4710 + float2(9.5f, 10.5f);\n        float4 _4718 = fa_gi_fetch(param_4);\n        bool _4721 = _4718.y < 0.5f;\n        bool _4730;\n        if (!_4721)\n        {\n            _4730 = _4718.x > _4443.y;\n        }\n        else\n        {\n            _4730 = _4721;\n        }\n        if (_4730)\n        {\n            continue;\n        }\n        float3 _4742 = _4530 - (_4468 + (_4675 * _4461));\n        float _4745 = length(_4742);\n        float3 _4751 = _4742 / max(_4745, 9.9999997473787516355514526367188e-05f).xxx;\n        float _4761 = max(9.9999997473787516355514526367188e-05f, (dot(-_4751, n) + 1.0f) * 0.5f);\n        float w = _4662 * (_4761 * _4761);\n        float3 param_5 = _4751;\n        float2 param_6 = (_4710 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _4781 = fa_gi_fetch(param_6);\n        float _4788 = _4745 / max(_4438.z, 9.9999997473787516355514526367188e-05f);\n        float _4791 = _4781.x;\n        if (_4788 > _4791)\n        {\n            float _4804 = max(_4781.y - (_4791 * _4791), 0.0f);\n            float _4809 = _4788 - _4791;\n            float _4818 = _4804 / max(_4804 + (_4809 * _4809), 9.9999999600419720025001879548654e-13f);\n            w *= ((_4818 * _4818) * _4818);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _4710 + float2(0.5f, 10.5f);\n        float2 param_8 = _4710 + float2(1.5f, 10.5f);\n        float2 param_9 = _4710 + float2(2.5f, 10.5f);\n        float2 param_10 = _4710 + float2(3.5f, 10.5f);\n        float2 param_11 = _4710 + float2(4.5f, 10.5f);\n        float2 param_12 = _4710 + float2(5.5f, 10.5f);\n        float2 param_13 = _4710 + float2(6.5f, 10.5f);\n        float2 param_14 = _4710 + float2(7.5f, 10.5f);\n        float2 param_15 = _4710 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _4540)) + (fa_gi_fetch(param_9).xyz * _4544)) + (fa_gi_fetch(param_10).xyz * _4548)) + (fa_gi_fetch(param_11).xyz * _4555)) + (fa_gi_fetch(param_12).xyz * _4562)) + (fa_gi_fetch(param_13).xyz * _4571)) + (fa_gi_fetch(param_14).xyz * _4578)) + (fa_gi_fetch(param_15).xyz * _4591)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_4490 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _4946;\n    if (_414_fa_gi.z > 0.5f)\n    {\n        _4946 = _4443.x;\n    }\n    else\n    {\n        _4946 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_4438.w * _4946);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _4970 = normalize(_414_fa_camera_pos.xyz - fa_world_pos);\n    int _4975 = int(_414_fa_gi.x + 0.5f);\n    int _4980 = int(_414_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _4980) && (k < 8); k++)\n    {\n        int param = _4975 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _4970;\n        float3 _5005 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5010 = param_3 * left;\n        acc += (_5005 * _5010);\n        left -= _5010;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_414_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _5039 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5039;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_414_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _414_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_414_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_414_fa_cl_info.x) + int(_414_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_414_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3854;\n    if (fa_lm.z > 0.5f)\n    {\n        _3854 = 0.0f;\n    }\n    else\n    {\n        _3854 = 1.0f - clamp(_414_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _3865 = _3854 < 1.0f;\n    bool _3871;\n    if (_3865)\n    {\n        int param = li;\n        _3871 = fa_light_baked(param);\n    }\n    else\n    {\n        _3871 = _3865;\n    }\n    return _3871 ? _3854 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _592 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _605 = (c - (ru * hx)) - p;\n        float3 _611 = ru * (2.0f * hx);\n        float _617 = max(dot(_611, _611), 9.9999999392252902907785028219223e-09f);\n        float _621 = dot(_605, _611);\n        float t = clamp((-_621) / _617, 0.0f, 1.0f);\n        if (_592)\n        {\n            float _636 = dot(r, _611);\n            float _642 = _617 - (_636 * _636);\n            if (abs(_642) > (9.9999997473787516355514526367188e-06f * _617))\n            {\n                t = clamp(((dot(r, _605) * _636) - _621) / _642, 0.0f, 1.0f);\n            }\n        }\n        return (p + _605) + (_611 * t);\n    }\n    float3 q = p;\n    float _674 = dot(r, axis);\n    bool _682;\n    if (_592)\n    {\n        _682 = abs(_674) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _682 = _592;\n    }\n    if (_682)\n    {\n        float _692 = dot(c - p, axis) / _674;\n        if (_692 > 0.0f)\n        {\n            q = p + (r * _692);\n        }\n    }\n    float3 _705 = q - c;\n    float2 xy = float2(dot(_705, ru), dot(_705, uu));\n    if (shape > 0.5f)\n    {\n        float _720 = length(xy);\n        if (_720 > hx)\n        {\n            xy *= (hx / _720);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _473_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _473_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _512 = dot(d, right);\n    float _516 = dot(d, up);\n    float _527;\n    if (((_512 * _512) + (_516 * _516)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _527 = atan2(_516, _512) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _527 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_527 - floor(_527)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _362 = abs(d);\n    float _364 = _362.x;\n    float _366 = _362.y;\n    bool _367 = _364 >= _366;\n    bool _375;\n    if (_367)\n    {\n        _375 = _364 >= _362.z;\n    }\n    else\n    {\n        _375 = _367;\n    }\n    int _376;\n    if (_375)\n    {\n        _376 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _391;\n        if (_366 >= _362.z)\n        {\n            _391 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _391 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _376 = _391;\n    }\n    return _376;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _758 = fa_light_base(param);\n    bool _762 = _414_fa_ambient.w > 4.5f;\n    int param_1 = _758;\n    float4 _766 = fa_light_texel(param_1);\n    int param_2 = _758 + 1;\n    float4 _771 = fa_light_texel(param_2);\n    float _774 = _771.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _786 = _762 && (_774 > 2.5f);\n    fa_light_is_area = _786;\n    bool _788 = _774 < 0.5f;\n    float3 l;\n    if (_788)\n    {\n        l = normalize(_766.xyz);\n        if (_762)\n        {\n            int param_3 = _758 + 6;\n            float4 _802 = fa_light_texel(param_3);\n            if (_802.z > 0.5f)\n            {\n                int param_4 = _758 + 4;\n                float4 _812 = fa_light_texel(param_4);\n                int param_5 = _758 + 5;\n                float4 _817 = fa_light_texel(param_5);\n                float2 param_6 = _802.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _812.xyz) * _812.w, (-dot(world_pos, _817.xyz)) * _817.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _847 = _766.xyz;\n        float3 _849 = _847 - world_pos;\n        float3 to_light = _849;\n        float _852 = length(_849);\n        float reach = _852;\n        bool front = true;\n        if (_786)\n        {\n            int param_8 = _758 + 7;\n            reach = max(_852 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _758 + 4;\n            float4 _876 = fa_light_texel(param_9);\n            int param_10 = _758 + 5;\n            float4 _881 = fa_light_texel(param_10);\n            int param_11 = _758 + 6;\n            float4 _886 = fa_light_texel(param_11);\n            float _887 = _886.w;\n            int param_12 = _758 + 2;\n            float3 _894 = normalize(fa_light_texel(param_12).xyz);\n            bool _896 = _887 > 1.5f;\n            bool _904;\n            if (!_896)\n            {\n                _904 = dot(_894, to_light) < 0.0f;\n            }\n            else\n            {\n                _904 = _896;\n            }\n            front = _904;\n            float3 r = 0.0f.xxx;\n            float3 _913 = _414_fa_camera_pos.xyz - world_pos;\n            bool _917 = dot(n, n) > 0.5f;\n            bool _925;\n            if (_917)\n            {\n                _925 = dot(_913, _913) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _925 = _917;\n            }\n            if (_925)\n            {\n                r = reflect(-normalize(_913), normalize(n));\n            }\n            float3 param_13 = _847;\n            float3 param_14 = _894;\n            float3 param_15 = _876.xyz;\n            float3 param_16 = _881.xyz;\n            float param_17 = _876.w;\n            float param_18 = _881.w;\n            float param_19 = _887;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _961 = length(to_light);\n        dist = _961;\n        l = to_light / max(_961, 9.9999997473787516355514526367188e-05f).xxx;\n        float _975 = reach / max(_766.w, 0.001000000047497451305389404296875f);\n        float _981 = clamp(1.0f - (_975 * _975), 0.0f, 1.0f);\n        float _983;\n        if (front)\n        {\n            _983 = _981 * _981;\n        }\n        else\n        {\n            _983 = 0.0f;\n        }\n        atten = _983;\n        bool _994 = _774 < 2.5f;\n        if ((_774 > 1.5f) && _994)\n        {\n            int param_22 = _758 + 2;\n            float4 _1002 = fa_light_texel(param_22);\n            float _1012 = _1002.w;\n            int param_23 = _758 + 3;\n            float4 _1017 = fa_light_texel(param_23);\n            float _1018 = _1017.x;\n            float cos_inner = _1018;\n            if (_1018 > 1.5f)\n            {\n                cos_inner = lerp(_1012, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1012, cos_inner, dot(-l, normalize(_1002.xyz)));\n        }\n        if (_762 && (_774 < 1.5f))\n        {\n            int param_24 = _758 + 6;\n            float4 _1042 = fa_light_texel(param_24);\n            if (_1042.z > 0.5f)\n            {\n                float3 _1050 = -to_light;\n                int param_25 = _758 + 4;\n                int param_26 = _758 + 5;\n                float3 _1064 = fa_light_texel(param_25).xyz;\n                float3 _1068 = fa_light_texel(param_26).xyz;\n                float3 _1077 = float3(dot(_1050, _1064), dot(_1050, _1068), dot(_1050, cross(_1064, _1068)));\n                float3 param_27 = _1077;\n                int _1081 = fa_cube_face(param_27);\n                int param_28 = _1081;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1108 = float2(dot(_1077, cross(param_29, param_30)), dot(_1077, param_30)) / max(dot(_1077, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1112 = _1081 / 3;\n                float2 param_31 = _1042.xy + (float2(float(_1081 - (_1112 * 3)), float(_1112)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1108.x), 0.5f - (0.5f * _1108.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _758 + 7;\n            float4 _1142 = fa_light_texel(param_33);\n            if (_1142.z > 0.5f)\n            {\n                int param_34 = _758 + 2;\n                int param_35 = _758 + 4;\n                int param_36 = _758 + 5;\n                float2 param_37 = _1142.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_762 && _994)\n            {\n                int param_42 = _758 + 6;\n                float4 _1189 = fa_light_texel(param_42);\n                int param_43 = _758 + 7;\n                float4 _1194 = fa_light_texel(param_43);\n                bool _1197 = _1189.z > 0.5f;\n                bool _1204;\n                if (!_1197)\n                {\n                    _1204 = _1194.z > 0.5f;\n                }\n                else\n                {\n                    _1204 = _1197;\n                }\n                if (_1204)\n                {\n                    int param_44 = _758 + 2;\n                    float4 _1211 = fa_light_texel(param_44);\n                    float3 _1215 = normalize(_1211.xyz);\n                    int param_45 = _758 + 4;\n                    float4 _1220 = fa_light_texel(param_45);\n                    int param_46 = _758 + 5;\n                    float4 _1225 = fa_light_texel(param_46);\n                    if (_1197)\n                    {\n                        float3 _1233 = -to_light;\n                        float _1240 = _1211.w;\n                        float _1256 = 0.5f / max(dot(_1233, _1215) * (sqrt(max(1.0f - (_1240 * _1240), 0.0f)) / max(_1240, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1189.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1233, _1220.xyz) * _1256), 0.5f - (dot(_1233, _1225.xyz) * _1256));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1194.z > 0.5f)\n                    {\n                        float2 param_49 = _1194.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1215;\n                        float3 param_52 = _1220.xyz;\n                        float3 param_53 = _1225.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _5726 = _771.xyz * atten;\n    if (_762)\n    {\n        _5726 *= fa_light_tint;\n    }\n    int _1324;\n    if (_788)\n    {\n        _1324 = 0;\n    }\n    else\n    {\n        _1324 = ((_774 > 1.5f) && (_774 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _5737 = { l, _5726, atten, 1.0f, dist, _1324 };\n    return _5737;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2113 = fa_shadow_depth(param, param_1);\n    float _2117;\n    if (conv.x < 0.5f)\n    {\n        _2117 = _2113;\n    }\n    else\n    {\n        _2117 = (conv.y * conv.z) / (conv.z - (_2113 * (conv.z - conv.y)));\n    }\n    return _2117;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2163 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2169 = float2(cos(_2163), sin(_2163));\n    float2 dir = _2169;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2178;\n        if (k < 0.0f)\n        {\n            _2178 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2178 = k;\n        }\n        float _2197 = clamp((_2178 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2216 = sqrt((float(i) + 0.5f) * 0.0625f) * _2197;\n            float2 param_3 = uv + (dir * (_2066_fa_shadow_bias.zw * _2216));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2230 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2230 < (zr - (_2216 * plane)))\n            {\n                sum += _2230;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2258 = sum / cnt;\n        float _2268;\n        if (k < 0.0f)\n        {\n            _2268 = (-k) / max(_2258, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2268 = k;\n        }\n        radius = clamp(((max(zr - _2258, 0.0f) * unit) * _2268) / texel_m, 1.5f, 16.0f);\n        dir = _2169;\n    }\n    float lit = 0.0f;\n    int _2294 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2294; i_1++)\n    {\n        float _2313 = sqrt((float(i_1) + 0.5f) / float(_2294)) * radius;\n        float2 param_7 = uv + (dir * (_2066_fa_shadow_bias.zw * _2313));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2313 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2294);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2518 = _414_fa_pbr.z < 0.5f;\n    bool _2525;\n    if (!_2518)\n    {\n        _2525 = _2066_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2525 = _2518;\n    }\n    if (_2525)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2066_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2538 = fa_light_texel(param);\n    float _2539 = _2538.x;\n    if (_2539 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2548 = int(_2539 + 0.5f);\n    int param_1 = _2548;\n    float4 _2552 = fa_light_texel(param_1);\n    int param_2 = _2548 + 1;\n    float4 _2557 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2560 = _2552.y;\n    if (_2560 > 0.0f)\n    {\n        float _2577 = 1.0f - smoothstep(0.75f * _2560, _2560, length(world - _2066_fa_shadow_eye.xyz));\n        fade = _2577;\n        if (_2577 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2552.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2601 = (_2548 + 2) + (face * 6);\n    int param_4 = _2601;\n    int param_5 = _2601 + 1;\n    int param_6 = _2601 + 3;\n    float4 _2615 = fa_light_texel(param_6);\n    int param_7 = _2601 + 4;\n    float4 _2620 = fa_light_texel(param_7);\n    int param_8 = _2601 + 5;\n    float4 _2625 = fa_light_texel(param_8);\n    float _2637 = _2625.x * max(dot(_2615, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2642 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2665 = clamp(dot(n, _2615.xyz), -1.0f, 1.0f);\n    float _2684 = min(sqrt(1.0f - (_2665 * _2665)) / max(abs(dot(n, world - lpos)) / max(dot(_2615, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2687 = _2557.y;\n    float _2689;\n    if (_2687 > 0.0f)\n    {\n        _2689 = _2687;\n    }\n    else\n    {\n        _2689 = 1.5f * _2637;\n    }\n    float4 _2709 = float4(world + (n * (_2689 * sqrt(1.0f - (_2642 * _2642)))), 1.0f);\n    float _2713 = dot(_2615, _2709);\n    float _2716 = _2625.y;\n    if (_2713 < _2716)\n    {\n        return 1.0f;\n    }\n    float2 _2731 = float2(dot(fa_light_texel(param_4), _2709), dot(fa_light_texel(param_5), _2709)) / _2713.xx;\n    float _2733 = _2731.x;\n    bool _2736 = _2733 < _2620.x;\n    bool _2745;\n    if (!_2736)\n    {\n        _2745 = _2733 > _2620.z;\n    }\n    else\n    {\n        _2745 = _2736;\n    }\n    bool _2754;\n    if (!_2745)\n    {\n        _2754 = _2731.y < _2620.y;\n    }\n    else\n    {\n        _2754 = _2745;\n    }\n    bool _2763;\n    if (!_2754)\n    {\n        _2763 = _2731.y > _2620.w;\n    }\n    else\n    {\n        _2763 = _2754;\n    }\n    if (_2763)\n    {\n        return 1.0f;\n    }\n    float _2769 = _2557.x;\n    float _2771;\n    if (_2769 > 0.0f)\n    {\n        _2771 = _2769;\n    }\n    else\n    {\n        _2771 = 1.5f * _2637;\n    }\n    float2 param_9 = _2731;\n    float4 param_10 = _2620;\n    float param_11 = _2713 - (_2771 * (1.0f + (0.5f * _2684)));\n    float param_12 = _2637;\n    float param_13 = 1.0f;\n    float param_14 = _2625.z * 0.25f;\n    float param_15 = (_2637 * min(_2684, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2716, _2625.z);\n    int param_17 = int(_2552.z + 0.5f);\n    float param_18 = _2552.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2056;\n    if (i == 0)\n    {\n        _2056 = _2066_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2072;\n        if (i == 1)\n        {\n            _2072 = _2066_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2080;\n            if (i == 2)\n            {\n                _2080 = _2066_fa_shadow_split.z;\n            }\n            else\n            {\n                _2080 = _2066_fa_shadow_split.w;\n            }\n            _2072 = _2080;\n        }\n        _2056 = _2072;\n    }\n    return _2056;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2359 = max(_2066_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2364 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2370 = sqrt(1.0f - (_2364 * _2364));\n    float _2378 = min(_2370 / max(_2364, 0.20000000298023223876953125f), 4.0f);\n    float _2383;\n    if (_2066_fa_shadow_bias.y > 0.0f)\n    {\n        _2383 = _2066_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2383 = 1.5f * _2066_fa_shadow_info[ci].x;\n    }\n    float4 _2408 = mul(float4(world + (n * (_2383 * _2370)), 1.0f), _2066_fa_shadow_mat[ci]);\n    float _2415 = _2408.x;\n    bool _2418 = _2415 < _2066_fa_shadow_rect[ci].x;\n    bool _2427;\n    if (!_2418)\n    {\n        _2427 = _2415 > _2066_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2427 = _2418;\n    }\n    bool _2436;\n    if (!_2427)\n    {\n        _2436 = _2408.y < _2066_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2436 = _2427;\n    }\n    bool _2445;\n    if (!_2436)\n    {\n        _2445 = _2408.y > _2066_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2445 = _2436;\n    }\n    bool _2452;\n    if (!_2445)\n    {\n        _2452 = _2408.z > 1.0f;\n    }\n    else\n    {\n        _2452 = _2445;\n    }\n    if (_2452)\n    {\n        return -1.0f;\n    }\n    float _2460;\n    if (_2066_fa_shadow_bias.x > 0.0f)\n    {\n        _2460 = _2066_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2460 = 1.5f * _2066_fa_shadow_info[ci].x;\n    }\n    float2 param = _2408.xy;\n    float4 param_1 = _2066_fa_shadow_rect[ci];\n    float param_2 = _2408.z - ((_2460 * (1.0f + (0.5f * _2378))) / _2359);\n    float param_3 = _2066_fa_shadow_info[ci].x;\n    float param_4 = _2359;\n    float param_5 = _2359 * 0.25f;\n    float param_6 = ((_2066_fa_shadow_info[ci].x * min(_2378, 3.0f)) * 0.5f) / _2359;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2066_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2066_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_414_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2838 = int(_2066_fa_shadow_cfg.x + 0.5f);\n    if (_2838 < 1)\n    {\n        return 1.0f;\n    }\n    float _2853 = dot(world - _2066_fa_shadow_eye.xyz, _2066_fa_shadow_fwd.xyz);\n    int param = _2838 - 1;\n    if (_2853 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2865 = _2838 > 1;\n    bool _2872;\n    if (_2865)\n    {\n        _2872 = _2853 > _2066_fa_shadow_split.x;\n    }\n    else\n    {\n        _2872 = _2865;\n    }\n    if (_2872)\n    {\n        ci = 1;\n    }\n    bool _2876 = _2838 > 2;\n    bool _2883;\n    if (_2876)\n    {\n        _2883 = _2853 > _2066_fa_shadow_split.y;\n    }\n    else\n    {\n        _2883 = _2876;\n    }\n    if (_2883)\n    {\n        ci = 2;\n    }\n    bool _2887 = _2838 > 3;\n    bool _2894;\n    if (_2887)\n    {\n        _2894 = _2853 > _2066_fa_shadow_split.z;\n    }\n    else\n    {\n        _2894 = _2887;\n    }\n    if (_2894)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _2905 = min(_2838, 4);\n    float _2946;\n    for (int c = ci; c < _2905; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2925 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _2925;\n            break;\n        }\n        if (_2925 < 0.0f)\n        {\n            continue;\n        }\n        s = _2925;\n        ci = c;\n        if (_2066_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2946 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2946 = _2066_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _2965 = _2066_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2946, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_2853 - (fa_shadow_split_at(param_7) - _2965)) / _2965, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _2997;\n        if ((ci + 1) < _2838)\n        {\n            _2997 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _2997 = 1.0f;\n        }\n        s = lerp(s, _2997, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    bool _3102 = _414_fa_ct_b.y > 0.5f;\n    bool _3108;\n    if (_3102)\n    {\n        _3108 = _414_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3108 = _3102;\n    }\n    if (_3108)\n    {\n        float4 _3118 = float4(fa_world_pos, 1.0f);\n        float _3124 = dot(_414_fa_ct_vpw, _3118);\n        if (_3124 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _3143 = float2(dot(_414_fa_ct_vpx, _3118), dot(_414_fa_ct_vpy, _3118)) / _3124.xx;\n            float _3148 = (_3143.x * 0.5f) + 0.5f;\n            float _3152;\n            if (_414_fa_ct_a.y > 0.5f)\n            {\n                _3152 = (_3143.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _3152 = 0.5f - (_3143.y * 0.5f);\n            }\n            bool _3168 = _3148 >= 0.0f;\n            bool _3174;\n            if (_3168)\n            {\n                _3174 = _3148 < 1.0f;\n            }\n            else\n            {\n                _3174 = _3168;\n            }\n            bool _3180;\n            if (_3174)\n            {\n                _3180 = _3152 >= 0.0f;\n            }\n            else\n            {\n                _3180 = _3174;\n            }\n            bool _3186;\n            if (_3180)\n            {\n                _3186 = _3152 < 1.0f;\n            }\n            else\n            {\n                _3186 = _3180;\n            }\n            if (_3186)\n            {\n                float4 _3212 = fa_screen_tex.Load(int3(clamp(int2(float2(_3148, _3152) * _414_fa_ct_a.zw), int2(0, 0), int2(_414_fa_ct_a.zw) - int2(1, 1)), 0));\n                float _3222 = dot(_414_fa_ct_fwd.xyz, fa_world_pos) + _414_fa_ct_fwd.w;\n                bool _3225 = _3212.w > 0.5f;\n                bool _3239;\n                if (_3225)\n                {\n                    _3239 = abs(_3222 - _3212.x) <= ((0.00200000009499490261077880859375f * _3222) + 0.00999999977648258209228515625f);\n                }\n                else\n                {\n                    _3239 = _3225;\n                }\n                if (_3239)\n                {\n                    return _3212.y;\n                }\n            }\n        }\n    }\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3596 = _414_fa_ct_a.x < 0.5f;\n    bool _3603;\n    if (!_3596)\n    {\n        _3603 = _2066_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3603 = _3596;\n    }\n    if (_3603)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2066_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3616 = fa_light_texel(param);\n    float _3617 = _3616.y;\n    float len = _3617;\n    if (_3617 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3629 = length(world - _414_fa_camera_pos.xyz);\n    float _3638 = 1.0f - smoothstep(0.5f * _414_fa_ct_b.x, _414_fa_ct_b.x, _3629);\n    if (_3638 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3644 = len;\n    float _3647 = min(_3644, 0.89999997615814208984375f * dist);\n    len = _3647;\n    float _3653 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3629);\n    float _3658 = _3653 + (0.5f * _3647);\n    float3 _3664 = world + (gn * _3653);\n    float _3666 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _3728;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3682 = (float(k) + _3666) * 0.083333335816860198974609375f;\n        float3 _3690 = _3664 + (l * (_3682 * len));\n        float4 _3696 = float4(_3690, 1.0f);\n        float _3701 = dot(_414_fa_ct_vpw, _3696);\n        if (_3701 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _3719 = float2(dot(_414_fa_ct_vpx, _3696), dot(_414_fa_ct_vpy, _3696)) / _3701.xx;\n        float _3723 = _3719.x * 0.5f;\n        float _3724 = _3723 + 0.5f;\n        if (_414_fa_ct_a.y > 0.5f)\n        {\n            _3728 = (_3719.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _3728 = 0.5f - (_3719.y * 0.5f);\n        }\n        bool _3744 = _3724 < 0.0f;\n        bool _3751;\n        if (!_3744)\n        {\n            _3751 = _3724 >= 1.0f;\n        }\n        else\n        {\n            _3751 = _3744;\n        }\n        bool _3758;\n        if (!_3751)\n        {\n            _3758 = _3728 < 0.0f;\n        }\n        else\n        {\n            _3758 = _3751;\n        }\n        bool _3765;\n        if (!_3758)\n        {\n            _3765 = _3728 >= 1.0f;\n        }\n        else\n        {\n            _3765 = _3758;\n        }\n        if (_3765)\n        {\n            break;\n        }\n        float4 _3789 = fa_screen_tex.Load(int3(clamp(int2(float2(_3724, _3728) * _414_fa_ct_a.zw), int2(0, 0), int2(_414_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_3789.w < 0.5f)\n        {\n            continue;\n        }\n        float _3807 = (dot(_414_fa_ct_fwd.xyz, _3690) + _414_fa_ct_fwd.w) - _3789.x;\n        if ((_3807 > _3653) && (_3807 < _3658))\n        {\n            occ = max(occ, (1.0f - (_3682 * _3682)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_3724, 0.5f - _3723), min(_3728, 1.0f - _3728))));\n        }\n    }\n    return 1.0f - (occ * _3638);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _3910 = fa_baked_keep(param);\n    if (_3910 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _5750 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _5750;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3936 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _5752 = _3936.color;\n    float _5753 = _3936.attenuation;\n    float _5754 = _3936.shadow;\n    bool _3939 = _3936.type == 0;\n    if (_3939 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3936.direction;\n        float _3950 = fa_shadow_factor(param_5, param_6);\n        _5754 = _3950;\n        _5752 *= _3950;\n    }\n    else\n    {\n        bool _3961 = _3936.type != 0;\n        bool _3967;\n        if (_3961)\n        {\n            _3967 = _5753 > 0.0f;\n        }\n        else\n        {\n            _3967 = _3961;\n        }\n        if (_3967)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3936.direction;\n            float _3986 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5754 = _3986;\n            _5752 *= _3986;\n        }\n    }\n    bool _3996 = _414_fa_ct_a.x > 0.5f;\n    bool _4002;\n    if (_3996)\n    {\n        _4002 = _5753 > 0.0f;\n    }\n    else\n    {\n        _4002 = _3996;\n    }\n    if (_4002)\n    {\n        float _4009;\n        if (_3939)\n        {\n            _4009 = 1000000000.0f;\n        }\n        else\n        {\n            _4009 = _3936._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3936.direction;\n        float param_18 = _4009;\n        float _4027 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5754 *= _4027;\n        _5752 *= _4027;\n    }\n    float _4040 = _5753;\n    float _4041 = _4040 * _3910;\n    _5753 = _4041;\n    float3 _4045 = _5752;\n    float3 _4046 = _4045 * _3910;\n    _5752 = _4046;\n    LightSample _5769 = { _3936.direction, _4046, _4041, _5754, _3936._distance, _3936.type };\n    return _5769;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _4060;\n    if (dot(s.normal, l.direction) > 0.5f)\n    {\n        _4060 = 1.0f;\n    }\n    else\n    {\n        _4060 = _4066_dark;\n    }\n    return (s.albedo * l.color) * _4060;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2066_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3025 = int(_2066_fa_shadow_cfg.x + 0.5f);\n    float _3035 = dot(world - _2066_fa_shadow_eye.xyz, _2066_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3040 = _3025 > 0;\n    bool _3049;\n    if (_3040)\n    {\n        int param = _3025 - 1;\n        _3049 = _3035 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3049 = _3040;\n    }\n    if (_3049)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3055 = _3025 > 1;\n        bool _3062;\n        if (_3055)\n        {\n            _3062 = _3035 > _2066_fa_shadow_split.x;\n        }\n        else\n        {\n            _3062 = _3055;\n        }\n        if (_3062)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3068 = _3025 > 2;\n        bool _3075;\n        if (_3068)\n        {\n            _3075 = _3035 > _2066_fa_shadow_split.y;\n        }\n        else\n        {\n            _3075 = _3068;\n        }\n        if (_3075)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3081 = _3025 > 3;\n        bool _3088;\n        if (_3081)\n        {\n            _3088 = _3035 > _2066_fa_shadow_split.z;\n        }\n        else\n        {\n            _3088 = _3081;\n        }\n        if (_3088)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5573 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5573 = -_5573;\n    }\n    float3 _5147 = normalize(_414_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5586 = { fa_world_pos, _5573, fa_world_tangent, fa_uv, fa_vertex_color, _5147, gl_FrontFacing };\n    SurfaceInput param_1 = _5586;\n    Surface _5155 = fa_standard_surface(param_1);\n    float3 _5604 = _5155.albedo;\n    float _5605 = _5155.alpha;\n    float3 _5606 = _5155.normal;\n    float _5607 = _5155.metallic;\n    float _5608 = _5155.roughness;\n    float _5609 = _5155.occlusion;\n    float3 _5610 = _5155.emission;\n    float _5611 = _5155.clearcoat;\n    float _5612 = _5155.clearcoat_roughness;\n    float3 _5613 = _5155.sheen_color;\n    float _5614 = _5155.sheen_roughness;\n    float _5615 = _5155.anisotropy;\n    float _5616 = _5155.anisotropy_rotation;\n    float _5617 = _5155.specular;\n    float _5618 = _5155.ior;\n    float3 _5619 = _5155.specular_color;\n    float _5620 = _5155.transmission;\n    float _5621 = _5155.thickness;\n    float3 _5622 = _5155.attenuation_color;\n    float _5623 = _5155.attenuation_distance;\n    SurfaceInput _5594 = { fa_world_pos, _5573, fa_world_tangent, fa_uv, fa_vertex_color, _5147, gl_FrontFacing };\n    SurfaceInput param_2 = _5594;\n    Surface param_3 = _5155;\n    surface(param_2, param_3);\n    _5604 = param_3.albedo;\n    _5605 = param_3.alpha;\n    _5606 = param_3.normal;\n    _5607 = param_3.metallic;\n    _5608 = param_3.roughness;\n    _5609 = param_3.occlusion;\n    _5610 = param_3.emission;\n    _5611 = param_3.clearcoat;\n    _5612 = param_3.clearcoat_roughness;\n    _5613 = param_3.sheen_color;\n    _5614 = param_3.sheen_roughness;\n    _5615 = param_3.anisotropy;\n    _5616 = param_3.anisotropy_rotation;\n    _5617 = param_3.specular;\n    _5618 = param_3.ior;\n    _5619 = param_3.specular_color;\n    _5620 = param_3.transmission;\n    _5621 = param_3.thickness;\n    _5622 = param_3.attenuation_color;\n    _5623 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5573;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5604 = param_6;\n    _5606 = param_7;\n    float3 result;\n    if (_414_fa_emissive.w > 0.5f)\n    {\n        result = _5604;\n    }\n    else\n    {\n        float3 _5194 = _5606;\n        float3 _5195 = normalize(_5194);\n        _5606 = _5195;\n        float3 param_8 = _5195;\n        float3 lit = (fa_indirect_diffuse(param_8) * _5604) * _5609;\n        int _5214 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5214; ln++)\n        {\n            int param_9 = ln;\n            int _5227 = fa_cl_light(param_9);\n            int param_10 = _5227;\n            if (fa_baked_keep(param_10) <= 0.0f)\n            {\n                continue;\n            }\n            int param_11 = _5227;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _5573;\n            LightSample _5243 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput _5602 = { fa_world_pos, _5573, fa_world_tangent, fa_uv, fa_vertex_color, _5147, gl_FrontFacing };\n            SurfaceInput param_14 = _5602;\n            Surface _5705 = { _5604, _5605, _5606, _5607, _5608, _5609, _5610, _5611, _5612, _5613, _5614, _5615, _5616, _5617, _5618, _5619, _5620, _5621, _5622, _5623 };\n            Surface param_15 = _5705;\n            LightSample param_16 = _5243;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _5258 = result;\n    float3 _5259 = _5258 + _5610;\n    result = _5259;\n    float3 param_17 = _5259;\n    float3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _5268 = _414_fa_fog.w > 0.0f;\n    bool _5275;\n    if (!_5268)\n    {\n        _5275 = _414_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5275 = _5268;\n    }\n    if (_5275)\n    {\n        float3 _5284 = fa_world_pos - _414_fa_camera_pos.xyz;\n        float _5290 = dot(_5284, _414_fa_fog_c.xyz);\n        bool _5294 = _414_fa_fog_c.w > 0.5f;\n        float _5295;\n        if (_5294)\n        {\n            _5295 = _5290;\n        }\n        else\n        {\n            _5295 = length(_5284);\n        }\n        float _5307 = _5295 - _414_fa_fog_b.x;\n        if (_5307 > 0.0f)\n        {\n            float _5316 = _414_fa_fog.w * _5307;\n            float tau = _5316 * _5316;\n            if (_414_fa_fog_b.y > 0.0f)\n            {\n                float _5332;\n                if (_5294)\n                {\n                    _5332 = fa_world_pos.y - (_414_fa_fog_c.y * _5290);\n                }\n                else\n                {\n                    _5332 = _414_fa_camera_pos.y;\n                }\n                float _5353 = lerp(_5332, fa_world_pos.y, clamp(_414_fa_fog_b.x / _5295, 0.0f, 1.0f));\n                float _5357 = fa_world_pos.y - _5353;\n                float _5362 = _5353 - _414_fa_fog_b.z;\n                float _5367 = fa_world_pos.y - _414_fa_fog_b.z;\n                bool _5370 = _5362 <= 0.0f;\n                bool _5371 = !_5370;\n                bool _5377;\n                if (_5371)\n                {\n                    _5377 = _414_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5377 = _5370;\n                }\n                float _5378;\n                if (_5377)\n                {\n                    _5378 = _414_fa_fog_b.y;\n                }\n                else\n                {\n                    _5378 = _414_fa_fog_b.y * exp(-min(_414_fa_fog_b.w * _5362, 80.0f));\n                }\n                bool _5405;\n                if (_5371)\n                {\n                    _5405 = _414_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5405 = _5370;\n                }\n                float _5406;\n                if (_5405)\n                {\n                    _5406 = _414_fa_fog_b.y * _5362;\n                }\n                else\n                {\n                    _5406 = (_414_fa_fog_b.y * (1.0f - exp(-min(_414_fa_fog_b.w * _5362, 80.0f)))) / _414_fa_fog_b.w;\n                }\n                bool _5431 = _5367 <= 0.0f;\n                bool _5438;\n                if (!_5431)\n                {\n                    _5438 = _414_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5438 = _5431;\n                }\n                float _5439;\n                if (_5438)\n                {\n                    _5439 = _414_fa_fog_b.y * _5367;\n                }\n                else\n                {\n                    _5439 = (_414_fa_fog_b.y * (1.0f - exp(-min(_414_fa_fog_b.w * _5367, 80.0f)))) / _414_fa_fog_b.w;\n                }\n                float _5466;\n                if (abs(_5357) < 0.001000000047497451305389404296875f)\n                {\n                    _5466 = _5378;\n                }\n                else\n                {\n                    _5466 = (_5439 - _5406) / _5357;\n                }\n                tau += (_5307 * max(_5466, 0.0f));\n            }\n            result = lerp(result, _414_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5605);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_414",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2066",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_4066",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _414_fa_camera_pos : packoffset(c0);\n    float4 _414_fa_ambient : packoffset(c1);\n    float4 _414_fa_base_color : packoffset(c2);\n    float4 _414_fa_emissive : packoffset(c3);\n    float4 _414_fa_model_emissive : packoffset(c4);\n    float4 _414_fa_pbr : packoffset(c5);\n    float4 _414_fa_maps : packoffset(c6);\n    float4 _414_fa_fog : packoffset(c7);\n    float4 _414_fa_fog_b : packoffset(c8);\n    float4 _414_fa_fog_c : packoffset(c9);\n    float4 _414_fa_counts : packoffset(c10);\n    float4 _414_fa_env_sky : packoffset(c11);\n    float4 _414_fa_env_horizon : packoffset(c12);\n    float4 _414_fa_time : packoffset(c13);\n    float4 _414_fa_cl_vpx : packoffset(c14);\n    float4 _414_fa_cl_vpy : packoffset(c15);\n    float4 _414_fa_cl_vpw : packoffset(c16);\n    float4 _414_fa_cl_fwd : packoffset(c17);\n    float4 _414_fa_cl_grid : packoffset(c18);\n    float4 _414_fa_cl_info : packoffset(c19);\n    float4 _414_fa_layers_a : packoffset(c20);\n    float4 _414_fa_layers_b : packoffset(c21);\n    float4 _414_fa_layers_c : packoffset(c22);\n    float4 _414_fa_layers_d : packoffset(c23);\n    float4 _414_fa_ct_a : packoffset(c24);\n    float4 _414_fa_ct_b : packoffset(c25);\n    float4 _414_fa_ct_vpx : packoffset(c26);\n    float4 _414_fa_ct_vpy : packoffset(c27);\n    float4 _414_fa_ct_vpw : packoffset(c28);\n    float4 _414_fa_ct_fwd : packoffset(c29);\n    float4 _414_fa_tr_a : packoffset(c30);\n    float4 _414_fa_tr_b : packoffset(c31);\n    float4 _414_fa_probe_sh[9] : packoffset(c32);\n    float4 _414_fa_atlas : packoffset(c41);\n    float4 _414_fa_rpa_tile : packoffset(c42);\n    float4 _414_fa_rpa_pos : packoffset(c43);\n    float4 _414_fa_rpa_bx : packoffset(c44);\n    float4 _414_fa_rpa_by : packoffset(c45);\n    float4 _414_fa_rpa_bz : packoffset(c46);\n    float4 _414_fa_rpb_tile : packoffset(c47);\n    float4 _414_fa_rpb_pos : packoffset(c48);\n    float4 _414_fa_rpb_bx : packoffset(c49);\n    float4 _414_fa_rpb_by : packoffset(c50);\n    float4 _414_fa_rpb_bz : packoffset(c51);\n    float4 _414_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2066_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2066_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2066_fa_shadow_info[4] : packoffset(c20);\n    float4 _2066_fa_shadow_split : packoffset(c24);\n    float4 _2066_fa_shadow_cfg : packoffset(c25);\n    float4 _2066_fa_shadow_bias : packoffset(c26);\n    float4 _2066_fa_shadow_eye : packoffset(c27);\n    float4 _2066_fa_shadow_fwd : packoffset(c28);\n    float4 _2066_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _4066_dark : packoffset(c0);\n    float _4066_fa_pad0 : packoffset(c0.y);\n    float _4066_fa_pad1 : packoffset(c0.z);\n    float _4066_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1342 = _414_fa_cl_info.x < 0.0f;\n    bool _1349;\n    if (!_1342)\n    {\n        _1349 = _414_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1349 = _1342;\n    }\n    bool _1357;\n    if (!_1349)\n    {\n        _1357 = _414_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1357 = _1349;\n    }\n    bool _1364;\n    if (!_1357)\n    {\n        _1364 = _414_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1364 = _1357;\n    }\n    bool _1371;\n    if (!_1364)\n    {\n        _1371 = _414_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1371 = _1364;\n    }\n    if (_1371)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1381 = float4(world_pos, 1.0f);\n    float _1387 = dot(_414_fa_cl_vpw, _1381);\n    if (!(_1387 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1409 = float2(dot(_414_fa_cl_vpx, _1381), dot(_414_fa_cl_vpy, _1381)) / _1387.xx;\n    int _1413 = int(_414_fa_cl_grid.x);\n    int _1417 = int(_414_fa_cl_grid.y);\n    int param = (int(_414_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_414_fa_cl_fwd.xyz, world_pos) + _414_fa_cl_fwd.w, _414_fa_cl_grid.w) / _414_fa_cl_grid.w) * _414_fa_cl_grid.z)), 0, int(_414_fa_cl_info.y) - 1) * _1417) + clamp(int(floor(((_1409.y * 0.5f) + 0.5f) * _414_fa_cl_grid.y)), 0, _1417 - 1)) * _1413)) + clamp(int(floor(((_1409.x * 0.5f) + 0.5f) * _414_fa_cl_grid.x)), 0, _1413 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1493 = fa_cluster_texel(param);\n    return int2(int(_1493.x), int(_1493.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_414_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3884 = fa_cluster_lookup(param);\n    fa_cl_slot = _3884.x;\n    fa_cl_local = _3884.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4115 = fa_linear_to_srgb(param);\n        c = _4115;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4123 = fa_srgb_to_linear(param_1);\n            c = _4123;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _296;\n    if (i.front_facing)\n    {\n        _296 = i.world_normal;\n    }\n    else\n    {\n        _296 = -i.world_normal;\n    }\n    float3 _320 = normalize(i.world_tangent.xyz - (_296 * dot(_296, i.world_tangent.xyz)));\n    float3 _347 = normalize(((_320 * m.x) + ((cross(_296, _320) * i.world_tangent.w) * m.y)) + (_296 * m.z));\n    float3 _350;\n    if (i.front_facing)\n    {\n        _350 = _347;\n    }\n    else\n    {\n        _350 = -_347;\n    }\n    return _350;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _414_fa_env_horizon.w);\n    float param = _414_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4155 = fa_tex_fix(param_2, param_3);\n    float4 _5945 = base_t;\n    _5945.x = _4155.x;\n    _5945.y = _4155.y;\n    _5945.z = _4155.z;\n    base_t = _5945;\n    float4 _4169 = (_5945 * _414_fa_base_color) * i.vertex_color;\n    float3 _5772 = i.world_normal;\n    if (_414_fa_maps.z > 0.5f)\n    {\n        float param_4 = _414_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _414_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4203 = fa_tex_fix(param_6, param_7);\n        float3 _4206 = (_4203 * 2.0f) - 1.0f.xxx;\n        float2 _4211 = _4206.xy * _414_fa_maps.x;\n        float3 _5953 = _4206;\n        _5953.x = _4211.x;\n        _5953.y = _4211.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5953;\n        _5772 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _414_fa_env_horizon.w);\n    float param_10 = _414_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4241 = fa_tex_fix(param_12, param_13);\n    float4 _5956 = mrt;\n    _5956.x = _4241.x;\n    _5956.y = _4241.y;\n    _5956.z = _4241.z;\n    mrt = _5956;\n    float4 _4271 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _414_fa_env_horizon.w);\n    float param_14 = _414_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4271.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4282 = fa_tex_fix(param_16, param_17);\n    float param_18 = _414_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _414_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4314 = fa_tex_fix(param_20, param_21);\n    float _5777 = _414_fa_layers_a.x;\n    float _5778 = _414_fa_layers_a.y;\n    float _5781 = _414_fa_layers_a.z;\n    float _5780 = _414_fa_layers_b.w;\n    float _5783 = _414_fa_layers_c.x;\n    if (_414_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_414_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _5777 *= _4282.y;\n            _5778 *= _4282.z;\n            _5780 *= _4271.w;\n        }\n        if (_414_fa_layers_c.z > 1.5f)\n        {\n            _5781 *= mrt.x;\n            _5783 *= mrt.w;\n        }\n    }\n    Surface _5810 = { _4169.xyz, _4169.w, _5772, clamp(_414_fa_pbr.x * _4241.z, 0.0f, 1.0f), clamp(_414_fa_pbr.y * _4241.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_414_fa_maps.y * (_4282.x - 1.0f)), _414_fa_emissive.xyz + (_414_fa_model_emissive.xyz * _4314), _5777, _5778, _414_fa_layers_b.xyz, _5780, _5781, _414_fa_layers_a.w, _5783, _414_fa_layers_c.y, _414_fa_layers_d.xyz, _414_fa_tr_a.x, _414_fa_tr_a.y, _414_fa_tr_b.xyz, _414_fa_tr_a.z };\n    return _5810;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1573 = rect.zw - rect.xy;\n    float2 _1577 = _1573 * atlas;\n    float2 _1581 = ddx * _1577;\n    float2 _1585 = ddy * _1577;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1573), clamp(0.5f * log2(max(max(dot(_1581, _1581), dot(_1585, _1585)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1618 = _414_fa_counts.y < 0.5f;\n    bool _1625;\n    if (!_1618)\n    {\n        _1625 = _414_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1625 = _1618;\n    }\n    if (_1625)\n    {\n        return;\n    }\n    float3 _1631 = ddx(world_pos);\n    float3 _1634 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1638 = fa_cluster_texel(param);\n    int _1642 = int(_1638.w);\n    if (_1642 < 1)\n    {\n        return;\n    }\n    int _1652 = int(_414_fa_counts.y + 0.5f);\n    int param_1 = _1652;\n    float4 _1656 = fa_light_texel(param_1);\n    float2 _1659 = _1656.yz;\n    int _1663 = int(_1656.w);\n    int param_2 = _1652 + 1;\n    float4 _1668 = fa_light_texel(param_2);\n    float _1669 = _1668.x;\n    int _1675 = int(_414_fa_counts.w + 0.5f) - 1;\n    int _1679 = int(_1638.z);\n    float3 _1944;\n    for (int k = 0; k < _1642; k++)\n    {\n        int _1692 = _1679 + k;\n        int param_3 = _1663 + (_1692 >> 2);\n        int _1709 = (_1652 + 2) + (int(fa_light_texel(param_3)[_1692 & 3]) * 7);\n        int param_4 = _1709 + 6;\n        float4 _1714 = fa_light_texel(param_4);\n        if (((int(_1714.w + 0.5f) >> _1675) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1709;\n        float4 _1729 = fa_light_texel(param_5);\n        int param_6 = _1709 + 1;\n        float4 _1734 = fa_light_texel(param_6);\n        int param_7 = _1709 + 2;\n        float4 _1739 = fa_light_texel(param_7);\n        float3 _1742 = _1729.xyz;\n        float _1747 = dot(_1742, world_pos) + _1729.w;\n        float3 _1749 = _1734.xyz;\n        float _1754 = dot(_1749, world_pos) + _1734.w;\n        float3 _1756 = _1739.xyz;\n        float _1761 = dot(_1756, world_pos) + _1739.w;\n        bool _1766 = abs(_1747) > 0.5f;\n        bool _1774;\n        if (!_1766)\n        {\n            _1774 = abs(_1754) > 0.5f;\n        }\n        else\n        {\n            _1774 = _1766;\n        }\n        bool _1782;\n        if (!_1774)\n        {\n            _1782 = abs(_1761) > 0.5f;\n        }\n        else\n        {\n            _1782 = _1774;\n        }\n        if (_1782)\n        {\n            continue;\n        }\n        float _1797 = clamp(dot(geo_normal, normalize(_1756)) * _1714.z, 0.0f, 1.0f);\n        if (_1797 <= 0.0f)\n        {\n            continue;\n        }\n        float _1817 = (clamp((0.5f - abs(_1761)) * 10.0f, 0.0f, 1.0f) * _1797) * _1714.x;\n        float2 _1825 = float2(_1747 + 0.5f, 0.5f - _1754);\n        float2 _1835 = float2(dot(_1742, _1631), dot(_1749, _1631));\n        float2 _1845 = float2(dot(_1742, _1634), dot(_1749, _1634));\n        int param_8 = _1709 + 5;\n        float4 _1850 = fa_light_texel(param_8);\n        int param_9 = _1709 + 3;\n        float4 _1855 = fa_light_texel(param_9);\n        int param_10 = _1709 + 4;\n        float4 _1860 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1850.xyz;\n        bool _1870 = _1855.z > _1855.x;\n        if (_1870)\n        {\n            float4 param_11 = _1855;\n            float2 param_12 = _1825;\n            float2 param_13 = _1659;\n            float2 param_14 = _1835;\n            float2 param_15 = _1845;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1669 > 0.5f) && (_1669 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1896 = fa_dc_to_linear(param_16);\n                float4 _5860 = tx;\n                _5860.x = _1896.x;\n                _5860.y = _1896.y;\n                _5860.z = _1896.z;\n                tx = _5860;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1817 * tex_a) * _1850.w, 0.0f, 1.0f).xxx);\n        if (_1860.z > _1860.x)\n        {\n            float4 param_17 = _1860;\n            float2 param_18 = _1825;\n            float2 param_19 = _1659;\n            float2 param_20 = _1835;\n            float2 param_21 = _1845;\n            float4 _1940 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1669 > 1.5f)\n            {\n                float3 param_22 = _1940.xyz;\n                float3 _1950 = fa_dc_to_srgb(param_22);\n                _1944 = _1950;\n            }\n            else\n            {\n                _1944 = _1940.xyz;\n            }\n            float3 _1959 = (_1944 * 2.0f) - 1.0f.xxx;\n            float2 _1964 = _1959.xy * _1714.y;\n            float3 _1986 = (normalize(_1742) * _1964.x) + (normalize(_1749) * _1964.y);\n            float3 _1989 = normalize(normal);\n            normal = normalize(lerp(_1989, normalize((_1989 * max(_1959.z, 0.0500000007450580596923828125f)) + (_1986 - (_1989 * dot(_1989, _1986)))), clamp(_1817 * (_1870 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3405_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3405_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_414_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3346 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3346;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3456 = (1.0f - _414_fa_rpa_tile.w) - _414_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3462 = _414_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3456 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3462)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _414_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3456;\n            }\n        }\n        else\n        {\n            amb = _414_fa_ambient.xyz * _3456;\n        }\n    }\n    bool _3514 = _414_fa_rpa_tile.w > 0.0f;\n    if (_3514)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _414_fa_rpa_tile.xy;\n            float param_4 = _414_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _414_fa_rpa_tile.w);\n        }\n    }\n    bool _3545 = _414_fa_rpb_tile.w > 0.0f;\n    if (_3545)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _414_fa_rpb_tile.xy;\n            float param_7 = _414_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _414_fa_rpb_tile.w);\n        }\n    }\n    if ((_3462 || _3514) || _3545)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3366 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3369 = _3366.x;\n    float _3371 = _3366.z;\n    float2 e = float2(_3369, _3371);\n    if (_3366.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3371)) * ((_3369 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3369)) * ((_3371 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _4428 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _4433 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _4438 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _4443 = fa_light_texel(param_3);\n    bool _4446 = _4443.z < 0.5f;\n    bool _4454;\n    if (!_4446)\n    {\n        _4454 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _4454 = _4446;\n    }\n    if (_4454)\n    {\n        return 0.0f.xxx;\n    }\n    float _4461 = max(_4428.w, 9.9999997473787516355514526367188e-05f);\n    float3 _4464 = _4433.xyz;\n    float3 _4468 = _4428.xyz;\n    float3 _4472 = (fa_world_pos - _4468) / _4461.xxx;\n    float3 _4481 = min(_4472 + 0.5f.xxx, (_4464 - 0.5f.xxx) - _4472);\n    float _4490 = min(_4481.x, min(_4481.y, _4481.z));\n    if (!(_4490 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4505 = _4464 - 1.0f.xxx;\n    float3 _4506 = clamp(_4472, 0.0f.xxx, _4505);\n    float3 _4514 = min(floor(_4506), max(_4464 - 2.0f.xxx, 0.0f.xxx));\n    float3 _4518 = _4506 - _4514;\n    float3 _4530 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _4461));\n    int _4535 = int(_4438.y + 0.5f);\n    float _4540 = 0.3257350027561187744140625f * n.y;\n    float _4544 = 0.3257350027561187744140625f * n.z;\n    float _4548 = 0.3257350027561187744140625f * n.x;\n    float _4555 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _4562 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _4571 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _4578 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _4591 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _4598 = 8 + int(_4443.w);\n    float _4625;\n    float _4638;\n    float _4652;\n    for (int k = 0; k < _4598; k++)\n    {\n        float _4611 = float(k & 1);\n        float _4615 = float((k >> 1) & 1);\n        float _4619 = float((k >> 2) & 1);\n        if (_4611 > 0.5f)\n        {\n            _4625 = _4518.x;\n        }\n        else\n        {\n            _4625 = 1.0f - _4518.x;\n        }\n        if (_4615 > 0.5f)\n        {\n            _4638 = _4518.y;\n        }\n        else\n        {\n            _4638 = 1.0f - _4518.y;\n        }\n        if (_4619 > 0.5f)\n        {\n            _4652 = _4518.z;\n        }\n        else\n        {\n            _4652 = 1.0f - _4518.z;\n        }\n        float _4662 = (_4625 * _4638) * _4652;\n        if (!(_4662 > 0.0f))\n        {\n            continue;\n        }\n        float3 _4675 = min(_4514 + float3(_4611, _4615, _4619), _4505);\n        int _4695 = int(((_4438.x + _4675.x) + (_4433.x * (_4675.y + (_4433.y * _4675.z)))) + 0.5f);\n        float2 _4710 = float2(float(_4695 % _4535) * 10.0f, 1024.0f + (float(_4695 / _4535) * 11.0f));\n        float2 param_4 = _4710 + float2(9.5f, 10.5f);\n        float4 _4718 = fa_gi_fetch(param_4);\n        bool _4721 = _4718.y < 0.5f;\n        bool _4730;\n        if (!_4721)\n        {\n            _4730 = _4718.x > _4443.y;\n        }\n        else\n        {\n            _4730 = _4721;\n        }\n        if (_4730)\n        {\n            continue;\n        }\n        float3 _4742 = _4530 - (_4468 + (_4675 * _4461));\n        float _4745 = length(_4742);\n        float3 _4751 = _4742 / max(_4745, 9.9999997473787516355514526367188e-05f).xxx;\n        float _4761 = max(9.9999997473787516355514526367188e-05f, (dot(-_4751, n) + 1.0f) * 0.5f);\n        float w = _4662 * (_4761 * _4761);\n        float3 param_5 = _4751;\n        float2 param_6 = (_4710 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _4781 = fa_gi_fetch(param_6);\n        float _4788 = _4745 / max(_4438.z, 9.9999997473787516355514526367188e-05f);\n        float _4791 = _4781.x;\n        if (_4788 > _4791)\n        {\n            float _4804 = max(_4781.y - (_4791 * _4791), 0.0f);\n            float _4809 = _4788 - _4791;\n            float _4818 = _4804 / max(_4804 + (_4809 * _4809), 9.9999999600419720025001879548654e-13f);\n            w *= ((_4818 * _4818) * _4818);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _4710 + float2(0.5f, 10.5f);\n        float2 param_8 = _4710 + float2(1.5f, 10.5f);\n        float2 param_9 = _4710 + float2(2.5f, 10.5f);\n        float2 param_10 = _4710 + float2(3.5f, 10.5f);\n        float2 param_11 = _4710 + float2(4.5f, 10.5f);\n        float2 param_12 = _4710 + float2(5.5f, 10.5f);\n        float2 param_13 = _4710 + float2(6.5f, 10.5f);\n        float2 param_14 = _4710 + float2(7.5f, 10.5f);\n        float2 param_15 = _4710 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _4540)) + (fa_gi_fetch(param_9).xyz * _4544)) + (fa_gi_fetch(param_10).xyz * _4548)) + (fa_gi_fetch(param_11).xyz * _4555)) + (fa_gi_fetch(param_12).xyz * _4562)) + (fa_gi_fetch(param_13).xyz * _4571)) + (fa_gi_fetch(param_14).xyz * _4578)) + (fa_gi_fetch(param_15).xyz * _4591)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_4490 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _4946;\n    if (_414_fa_gi.z > 0.5f)\n    {\n        _4946 = _4443.x;\n    }\n    else\n    {\n        _4946 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_4438.w * _4946);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _4970 = normalize(_414_fa_camera_pos.xyz - fa_world_pos);\n    int _4975 = int(_414_fa_gi.x + 0.5f);\n    int _4980 = int(_414_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _4980) && (k < 8); k++)\n    {\n        int param = _4975 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _4970;\n        float3 _5005 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5010 = param_3 * left;\n        acc += (_5005 * _5010);\n        left -= _5010;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_414_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _5039 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5039;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_414_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _414_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_414_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_414_fa_cl_info.x) + int(_414_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_414_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3854;\n    if (fa_lm.z > 0.5f)\n    {\n        _3854 = 0.0f;\n    }\n    else\n    {\n        _3854 = 1.0f - clamp(_414_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _3865 = _3854 < 1.0f;\n    bool _3871;\n    if (_3865)\n    {\n        int param = li;\n        _3871 = fa_light_baked(param);\n    }\n    else\n    {\n        _3871 = _3865;\n    }\n    return _3871 ? _3854 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _592 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _605 = (c - (ru * hx)) - p;\n        float3 _611 = ru * (2.0f * hx);\n        float _617 = max(dot(_611, _611), 9.9999999392252902907785028219223e-09f);\n        float _621 = dot(_605, _611);\n        float t = clamp((-_621) / _617, 0.0f, 1.0f);\n        if (_592)\n        {\n            float _636 = dot(r, _611);\n            float _642 = _617 - (_636 * _636);\n            if (abs(_642) > (9.9999997473787516355514526367188e-06f * _617))\n            {\n                t = clamp(((dot(r, _605) * _636) - _621) / _642, 0.0f, 1.0f);\n            }\n        }\n        return (p + _605) + (_611 * t);\n    }\n    float3 q = p;\n    float _674 = dot(r, axis);\n    bool _682;\n    if (_592)\n    {\n        _682 = abs(_674) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _682 = _592;\n    }\n    if (_682)\n    {\n        float _692 = dot(c - p, axis) / _674;\n        if (_692 > 0.0f)\n        {\n            q = p + (r * _692);\n        }\n    }\n    float3 _705 = q - c;\n    float2 xy = float2(dot(_705, ru), dot(_705, uu));\n    if (shape > 0.5f)\n    {\n        float _720 = length(xy);\n        if (_720 > hx)\n        {\n            xy *= (hx / _720);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _473_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _473_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _512 = dot(d, right);\n    float _516 = dot(d, up);\n    float _527;\n    if (((_512 * _512) + (_516 * _516)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _527 = atan2(_516, _512) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _527 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_527 - floor(_527)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _362 = abs(d);\n    float _364 = _362.x;\n    float _366 = _362.y;\n    bool _367 = _364 >= _366;\n    bool _375;\n    if (_367)\n    {\n        _375 = _364 >= _362.z;\n    }\n    else\n    {\n        _375 = _367;\n    }\n    int _376;\n    if (_375)\n    {\n        _376 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _391;\n        if (_366 >= _362.z)\n        {\n            _391 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _391 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _376 = _391;\n    }\n    return _376;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _758 = fa_light_base(param);\n    bool _762 = _414_fa_ambient.w > 4.5f;\n    int param_1 = _758;\n    float4 _766 = fa_light_texel(param_1);\n    int param_2 = _758 + 1;\n    float4 _771 = fa_light_texel(param_2);\n    float _774 = _771.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _786 = _762 && (_774 > 2.5f);\n    fa_light_is_area = _786;\n    bool _788 = _774 < 0.5f;\n    float3 l;\n    if (_788)\n    {\n        l = normalize(_766.xyz);\n        if (_762)\n        {\n            int param_3 = _758 + 6;\n            float4 _802 = fa_light_texel(param_3);\n            if (_802.z > 0.5f)\n            {\n                int param_4 = _758 + 4;\n                float4 _812 = fa_light_texel(param_4);\n                int param_5 = _758 + 5;\n                float4 _817 = fa_light_texel(param_5);\n                float2 param_6 = _802.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _812.xyz) * _812.w, (-dot(world_pos, _817.xyz)) * _817.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _847 = _766.xyz;\n        float3 _849 = _847 - world_pos;\n        float3 to_light = _849;\n        float _852 = length(_849);\n        float reach = _852;\n        bool front = true;\n        if (_786)\n        {\n            int param_8 = _758 + 7;\n            reach = max(_852 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _758 + 4;\n            float4 _876 = fa_light_texel(param_9);\n            int param_10 = _758 + 5;\n            float4 _881 = fa_light_texel(param_10);\n            int param_11 = _758 + 6;\n            float4 _886 = fa_light_texel(param_11);\n            float _887 = _886.w;\n            int param_12 = _758 + 2;\n            float3 _894 = normalize(fa_light_texel(param_12).xyz);\n            bool _896 = _887 > 1.5f;\n            bool _904;\n            if (!_896)\n            {\n                _904 = dot(_894, to_light) < 0.0f;\n            }\n            else\n            {\n                _904 = _896;\n            }\n            front = _904;\n            float3 r = 0.0f.xxx;\n            float3 _913 = _414_fa_camera_pos.xyz - world_pos;\n            bool _917 = dot(n, n) > 0.5f;\n            bool _925;\n            if (_917)\n            {\n                _925 = dot(_913, _913) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _925 = _917;\n            }\n            if (_925)\n            {\n                r = reflect(-normalize(_913), normalize(n));\n            }\n            float3 param_13 = _847;\n            float3 param_14 = _894;\n            float3 param_15 = _876.xyz;\n            float3 param_16 = _881.xyz;\n            float param_17 = _876.w;\n            float param_18 = _881.w;\n            float param_19 = _887;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _961 = length(to_light);\n        dist = _961;\n        l = to_light / max(_961, 9.9999997473787516355514526367188e-05f).xxx;\n        float _975 = reach / max(_766.w, 0.001000000047497451305389404296875f);\n        float _981 = clamp(1.0f - (_975 * _975), 0.0f, 1.0f);\n        float _983;\n        if (front)\n        {\n            _983 = _981 * _981;\n        }\n        else\n        {\n            _983 = 0.0f;\n        }\n        atten = _983;\n        bool _994 = _774 < 2.5f;\n        if ((_774 > 1.5f) && _994)\n        {\n            int param_22 = _758 + 2;\n            float4 _1002 = fa_light_texel(param_22);\n            float _1012 = _1002.w;\n            int param_23 = _758 + 3;\n            float4 _1017 = fa_light_texel(param_23);\n            float _1018 = _1017.x;\n            float cos_inner = _1018;\n            if (_1018 > 1.5f)\n            {\n                cos_inner = lerp(_1012, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1012, cos_inner, dot(-l, normalize(_1002.xyz)));\n        }\n        if (_762 && (_774 < 1.5f))\n        {\n            int param_24 = _758 + 6;\n            float4 _1042 = fa_light_texel(param_24);\n            if (_1042.z > 0.5f)\n            {\n                float3 _1050 = -to_light;\n                int param_25 = _758 + 4;\n                int param_26 = _758 + 5;\n                float3 _1064 = fa_light_texel(param_25).xyz;\n                float3 _1068 = fa_light_texel(param_26).xyz;\n                float3 _1077 = float3(dot(_1050, _1064), dot(_1050, _1068), dot(_1050, cross(_1064, _1068)));\n                float3 param_27 = _1077;\n                int _1081 = fa_cube_face(param_27);\n                int param_28 = _1081;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1108 = float2(dot(_1077, cross(param_29, param_30)), dot(_1077, param_30)) / max(dot(_1077, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1112 = _1081 / 3;\n                float2 param_31 = _1042.xy + (float2(float(_1081 - (_1112 * 3)), float(_1112)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1108.x), 0.5f - (0.5f * _1108.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _758 + 7;\n            float4 _1142 = fa_light_texel(param_33);\n            if (_1142.z > 0.5f)\n            {\n                int param_34 = _758 + 2;\n                int param_35 = _758 + 4;\n                int param_36 = _758 + 5;\n                float2 param_37 = _1142.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_762 && _994)\n            {\n                int param_42 = _758 + 6;\n                float4 _1189 = fa_light_texel(param_42);\n                int param_43 = _758 + 7;\n                float4 _1194 = fa_light_texel(param_43);\n                bool _1197 = _1189.z > 0.5f;\n                bool _1204;\n                if (!_1197)\n                {\n                    _1204 = _1194.z > 0.5f;\n                }\n                else\n                {\n                    _1204 = _1197;\n                }\n                if (_1204)\n                {\n                    int param_44 = _758 + 2;\n                    float4 _1211 = fa_light_texel(param_44);\n                    float3 _1215 = normalize(_1211.xyz);\n                    int param_45 = _758 + 4;\n                    float4 _1220 = fa_light_texel(param_45);\n                    int param_46 = _758 + 5;\n                    float4 _1225 = fa_light_texel(param_46);\n                    if (_1197)\n                    {\n                        float3 _1233 = -to_light;\n                        float _1240 = _1211.w;\n                        float _1256 = 0.5f / max(dot(_1233, _1215) * (sqrt(max(1.0f - (_1240 * _1240), 0.0f)) / max(_1240, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1189.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1233, _1220.xyz) * _1256), 0.5f - (dot(_1233, _1225.xyz) * _1256));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1194.z > 0.5f)\n                    {\n                        float2 param_49 = _1194.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1215;\n                        float3 param_52 = _1220.xyz;\n                        float3 param_53 = _1225.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _5726 = _771.xyz * atten;\n    if (_762)\n    {\n        _5726 *= fa_light_tint;\n    }\n    int _1324;\n    if (_788)\n    {\n        _1324 = 0;\n    }\n    else\n    {\n        _1324 = ((_774 > 1.5f) && (_774 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _5737 = { l, _5726, atten, 1.0f, dist, _1324 };\n    return _5737;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2113 = fa_shadow_depth(param, param_1);\n    float _2117;\n    if (conv.x < 0.5f)\n    {\n        _2117 = _2113;\n    }\n    else\n    {\n        _2117 = (conv.y * conv.z) / (conv.z - (_2113 * (conv.z - conv.y)));\n    }\n    return _2117;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2163 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2169 = float2(cos(_2163), sin(_2163));\n    float2 dir = _2169;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2178;\n        if (k < 0.0f)\n        {\n            _2178 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2178 = k;\n        }\n        float _2197 = clamp((_2178 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2216 = sqrt((float(i) + 0.5f) * 0.0625f) * _2197;\n            float2 param_3 = uv + (dir * (_2066_fa_shadow_bias.zw * _2216));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2230 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2230 < (zr - (_2216 * plane)))\n            {\n                sum += _2230;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2258 = sum / cnt;\n        float _2268;\n        if (k < 0.0f)\n        {\n            _2268 = (-k) / max(_2258, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2268 = k;\n        }\n        radius = clamp(((max(zr - _2258, 0.0f) * unit) * _2268) / texel_m, 1.5f, 16.0f);\n        dir = _2169;\n    }\n    float lit = 0.0f;\n    int _2294 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2294; i_1++)\n    {\n        float _2313 = sqrt((float(i_1) + 0.5f) / float(_2294)) * radius;\n        float2 param_7 = uv + (dir * (_2066_fa_shadow_bias.zw * _2313));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2313 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2294);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2518 = _414_fa_pbr.z < 0.5f;\n    bool _2525;\n    if (!_2518)\n    {\n        _2525 = _2066_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2525 = _2518;\n    }\n    if (_2525)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2066_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2538 = fa_light_texel(param);\n    float _2539 = _2538.x;\n    if (_2539 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2548 = int(_2539 + 0.5f);\n    int param_1 = _2548;\n    float4 _2552 = fa_light_texel(param_1);\n    int param_2 = _2548 + 1;\n    float4 _2557 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2560 = _2552.y;\n    if (_2560 > 0.0f)\n    {\n        float _2577 = 1.0f - smoothstep(0.75f * _2560, _2560, length(world - _2066_fa_shadow_eye.xyz));\n        fade = _2577;\n        if (_2577 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2552.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2601 = (_2548 + 2) + (face * 6);\n    int param_4 = _2601;\n    int param_5 = _2601 + 1;\n    int param_6 = _2601 + 3;\n    float4 _2615 = fa_light_texel(param_6);\n    int param_7 = _2601 + 4;\n    float4 _2620 = fa_light_texel(param_7);\n    int param_8 = _2601 + 5;\n    float4 _2625 = fa_light_texel(param_8);\n    float _2637 = _2625.x * max(dot(_2615, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2642 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2665 = clamp(dot(n, _2615.xyz), -1.0f, 1.0f);\n    float _2684 = min(sqrt(1.0f - (_2665 * _2665)) / max(abs(dot(n, world - lpos)) / max(dot(_2615, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2687 = _2557.y;\n    float _2689;\n    if (_2687 > 0.0f)\n    {\n        _2689 = _2687;\n    }\n    else\n    {\n        _2689 = 1.5f * _2637;\n    }\n    float4 _2709 = float4(world + (n * (_2689 * sqrt(1.0f - (_2642 * _2642)))), 1.0f);\n    float _2713 = dot(_2615, _2709);\n    float _2716 = _2625.y;\n    if (_2713 < _2716)\n    {\n        return 1.0f;\n    }\n    float2 _2731 = float2(dot(fa_light_texel(param_4), _2709), dot(fa_light_texel(param_5), _2709)) / _2713.xx;\n    float _2733 = _2731.x;\n    bool _2736 = _2733 < _2620.x;\n    bool _2745;\n    if (!_2736)\n    {\n        _2745 = _2733 > _2620.z;\n    }\n    else\n    {\n        _2745 = _2736;\n    }\n    bool _2754;\n    if (!_2745)\n    {\n        _2754 = _2731.y < _2620.y;\n    }\n    else\n    {\n        _2754 = _2745;\n    }\n    bool _2763;\n    if (!_2754)\n    {\n        _2763 = _2731.y > _2620.w;\n    }\n    else\n    {\n        _2763 = _2754;\n    }\n    if (_2763)\n    {\n        return 1.0f;\n    }\n    float _2769 = _2557.x;\n    float _2771;\n    if (_2769 > 0.0f)\n    {\n        _2771 = _2769;\n    }\n    else\n    {\n        _2771 = 1.5f * _2637;\n    }\n    float2 param_9 = _2731;\n    float4 param_10 = _2620;\n    float param_11 = _2713 - (_2771 * (1.0f + (0.5f * _2684)));\n    float param_12 = _2637;\n    float param_13 = 1.0f;\n    float param_14 = _2625.z * 0.25f;\n    float param_15 = (_2637 * min(_2684, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2716, _2625.z);\n    int param_17 = int(_2552.z + 0.5f);\n    float param_18 = _2552.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2056;\n    if (i == 0)\n    {\n        _2056 = _2066_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2072;\n        if (i == 1)\n        {\n            _2072 = _2066_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2080;\n            if (i == 2)\n            {\n                _2080 = _2066_fa_shadow_split.z;\n            }\n            else\n            {\n                _2080 = _2066_fa_shadow_split.w;\n            }\n            _2072 = _2080;\n        }\n        _2056 = _2072;\n    }\n    return _2056;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2359 = max(_2066_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2364 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2370 = sqrt(1.0f - (_2364 * _2364));\n    float _2378 = min(_2370 / max(_2364, 0.20000000298023223876953125f), 4.0f);\n    float _2383;\n    if (_2066_fa_shadow_bias.y > 0.0f)\n    {\n        _2383 = _2066_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2383 = 1.5f * _2066_fa_shadow_info[ci].x;\n    }\n    float4 _2408 = mul(float4(world + (n * (_2383 * _2370)), 1.0f), _2066_fa_shadow_mat[ci]);\n    float _2415 = _2408.x;\n    bool _2418 = _2415 < _2066_fa_shadow_rect[ci].x;\n    bool _2427;\n    if (!_2418)\n    {\n        _2427 = _2415 > _2066_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2427 = _2418;\n    }\n    bool _2436;\n    if (!_2427)\n    {\n        _2436 = _2408.y < _2066_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2436 = _2427;\n    }\n    bool _2445;\n    if (!_2436)\n    {\n        _2445 = _2408.y > _2066_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2445 = _2436;\n    }\n    bool _2452;\n    if (!_2445)\n    {\n        _2452 = _2408.z > 1.0f;\n    }\n    else\n    {\n        _2452 = _2445;\n    }\n    if (_2452)\n    {\n        return -1.0f;\n    }\n    float _2460;\n    if (_2066_fa_shadow_bias.x > 0.0f)\n    {\n        _2460 = _2066_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2460 = 1.5f * _2066_fa_shadow_info[ci].x;\n    }\n    float2 param = _2408.xy;\n    float4 param_1 = _2066_fa_shadow_rect[ci];\n    float param_2 = _2408.z - ((_2460 * (1.0f + (0.5f * _2378))) / _2359);\n    float param_3 = _2066_fa_shadow_info[ci].x;\n    float param_4 = _2359;\n    float param_5 = _2359 * 0.25f;\n    float param_6 = ((_2066_fa_shadow_info[ci].x * min(_2378, 3.0f)) * 0.5f) / _2359;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2066_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2066_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_414_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2838 = int(_2066_fa_shadow_cfg.x + 0.5f);\n    if (_2838 < 1)\n    {\n        return 1.0f;\n    }\n    float _2853 = dot(world - _2066_fa_shadow_eye.xyz, _2066_fa_shadow_fwd.xyz);\n    int param = _2838 - 1;\n    if (_2853 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2865 = _2838 > 1;\n    bool _2872;\n    if (_2865)\n    {\n        _2872 = _2853 > _2066_fa_shadow_split.x;\n    }\n    else\n    {\n        _2872 = _2865;\n    }\n    if (_2872)\n    {\n        ci = 1;\n    }\n    bool _2876 = _2838 > 2;\n    bool _2883;\n    if (_2876)\n    {\n        _2883 = _2853 > _2066_fa_shadow_split.y;\n    }\n    else\n    {\n        _2883 = _2876;\n    }\n    if (_2883)\n    {\n        ci = 2;\n    }\n    bool _2887 = _2838 > 3;\n    bool _2894;\n    if (_2887)\n    {\n        _2894 = _2853 > _2066_fa_shadow_split.z;\n    }\n    else\n    {\n        _2894 = _2887;\n    }\n    if (_2894)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _2905 = min(_2838, 4);\n    float _2946;\n    for (int c = ci; c < _2905; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2925 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _2925;\n            break;\n        }\n        if (_2925 < 0.0f)\n        {\n            continue;\n        }\n        s = _2925;\n        ci = c;\n        if (_2066_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2946 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2946 = _2066_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _2965 = _2066_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2946, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_2853 - (fa_shadow_split_at(param_7) - _2965)) / _2965, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _2997;\n        if ((ci + 1) < _2838)\n        {\n            _2997 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _2997 = 1.0f;\n        }\n        s = lerp(s, _2997, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    bool _3102 = _414_fa_ct_b.y > 0.5f;\n    bool _3108;\n    if (_3102)\n    {\n        _3108 = _414_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3108 = _3102;\n    }\n    if (_3108)\n    {\n        float4 _3118 = float4(fa_world_pos, 1.0f);\n        float _3124 = dot(_414_fa_ct_vpw, _3118);\n        if (_3124 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _3143 = float2(dot(_414_fa_ct_vpx, _3118), dot(_414_fa_ct_vpy, _3118)) / _3124.xx;\n            float _3148 = (_3143.x * 0.5f) + 0.5f;\n            float _3152;\n            if (_414_fa_ct_a.y > 0.5f)\n            {\n                _3152 = (_3143.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _3152 = 0.5f - (_3143.y * 0.5f);\n            }\n            bool _3168 = _3148 >= 0.0f;\n            bool _3174;\n            if (_3168)\n            {\n                _3174 = _3148 < 1.0f;\n            }\n            else\n            {\n                _3174 = _3168;\n            }\n            bool _3180;\n            if (_3174)\n            {\n                _3180 = _3152 >= 0.0f;\n            }\n            else\n            {\n                _3180 = _3174;\n            }\n            bool _3186;\n            if (_3180)\n            {\n                _3186 = _3152 < 1.0f;\n            }\n            else\n            {\n                _3186 = _3180;\n            }\n            if (_3186)\n            {\n                float4 _3212 = fa_screen_tex.Load(int3(clamp(int2(float2(_3148, _3152) * _414_fa_ct_a.zw), int2(0, 0), int2(_414_fa_ct_a.zw) - int2(1, 1)), 0));\n                float _3222 = dot(_414_fa_ct_fwd.xyz, fa_world_pos) + _414_fa_ct_fwd.w;\n                bool _3225 = _3212.w > 0.5f;\n                bool _3239;\n                if (_3225)\n                {\n                    _3239 = abs(_3222 - _3212.x) <= ((0.00200000009499490261077880859375f * _3222) + 0.00999999977648258209228515625f);\n                }\n                else\n                {\n                    _3239 = _3225;\n                }\n                if (_3239)\n                {\n                    return _3212.y;\n                }\n            }\n        }\n    }\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3596 = _414_fa_ct_a.x < 0.5f;\n    bool _3603;\n    if (!_3596)\n    {\n        _3603 = _2066_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3603 = _3596;\n    }\n    if (_3603)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2066_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3616 = fa_light_texel(param);\n    float _3617 = _3616.y;\n    float len = _3617;\n    if (_3617 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3629 = length(world - _414_fa_camera_pos.xyz);\n    float _3638 = 1.0f - smoothstep(0.5f * _414_fa_ct_b.x, _414_fa_ct_b.x, _3629);\n    if (_3638 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3644 = len;\n    float _3647 = min(_3644, 0.89999997615814208984375f * dist);\n    len = _3647;\n    float _3653 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3629);\n    float _3658 = _3653 + (0.5f * _3647);\n    float3 _3664 = world + (gn * _3653);\n    float _3666 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _3728;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3682 = (float(k) + _3666) * 0.083333335816860198974609375f;\n        float3 _3690 = _3664 + (l * (_3682 * len));\n        float4 _3696 = float4(_3690, 1.0f);\n        float _3701 = dot(_414_fa_ct_vpw, _3696);\n        if (_3701 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _3719 = float2(dot(_414_fa_ct_vpx, _3696), dot(_414_fa_ct_vpy, _3696)) / _3701.xx;\n        float _3723 = _3719.x * 0.5f;\n        float _3724 = _3723 + 0.5f;\n        if (_414_fa_ct_a.y > 0.5f)\n        {\n            _3728 = (_3719.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _3728 = 0.5f - (_3719.y * 0.5f);\n        }\n        bool _3744 = _3724 < 0.0f;\n        bool _3751;\n        if (!_3744)\n        {\n            _3751 = _3724 >= 1.0f;\n        }\n        else\n        {\n            _3751 = _3744;\n        }\n        bool _3758;\n        if (!_3751)\n        {\n            _3758 = _3728 < 0.0f;\n        }\n        else\n        {\n            _3758 = _3751;\n        }\n        bool _3765;\n        if (!_3758)\n        {\n            _3765 = _3728 >= 1.0f;\n        }\n        else\n        {\n            _3765 = _3758;\n        }\n        if (_3765)\n        {\n            break;\n        }\n        float4 _3789 = fa_screen_tex.Load(int3(clamp(int2(float2(_3724, _3728) * _414_fa_ct_a.zw), int2(0, 0), int2(_414_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_3789.w < 0.5f)\n        {\n            continue;\n        }\n        float _3807 = (dot(_414_fa_ct_fwd.xyz, _3690) + _414_fa_ct_fwd.w) - _3789.x;\n        if ((_3807 > _3653) && (_3807 < _3658))\n        {\n            occ = max(occ, (1.0f - (_3682 * _3682)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_3724, 0.5f - _3723), min(_3728, 1.0f - _3728))));\n        }\n    }\n    return 1.0f - (occ * _3638);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _3910 = fa_baked_keep(param);\n    if (_3910 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _5750 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _5750;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3936 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _5752 = _3936.color;\n    float _5753 = _3936.attenuation;\n    float _5754 = _3936.shadow;\n    bool _3939 = _3936.type == 0;\n    if (_3939 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3936.direction;\n        float _3950 = fa_shadow_factor(param_5, param_6);\n        _5754 = _3950;\n        _5752 *= _3950;\n    }\n    else\n    {\n        bool _3961 = _3936.type != 0;\n        bool _3967;\n        if (_3961)\n        {\n            _3967 = _5753 > 0.0f;\n        }\n        else\n        {\n            _3967 = _3961;\n        }\n        if (_3967)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3936.direction;\n            float _3986 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5754 = _3986;\n            _5752 *= _3986;\n        }\n    }\n    bool _3996 = _414_fa_ct_a.x > 0.5f;\n    bool _4002;\n    if (_3996)\n    {\n        _4002 = _5753 > 0.0f;\n    }\n    else\n    {\n        _4002 = _3996;\n    }\n    if (_4002)\n    {\n        float _4009;\n        if (_3939)\n        {\n            _4009 = 1000000000.0f;\n        }\n        else\n        {\n            _4009 = _3936._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3936.direction;\n        float param_18 = _4009;\n        float _4027 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5754 *= _4027;\n        _5752 *= _4027;\n    }\n    float _4040 = _5753;\n    float _4041 = _4040 * _3910;\n    _5753 = _4041;\n    float3 _4045 = _5752;\n    float3 _4046 = _4045 * _3910;\n    _5752 = _4046;\n    LightSample _5769 = { _3936.direction, _4046, _4041, _5754, _3936._distance, _3936.type };\n    return _5769;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _4060;\n    if (dot(s.normal, l.direction) > 0.5f)\n    {\n        _4060 = 1.0f;\n    }\n    else\n    {\n        _4060 = _4066_dark;\n    }\n    return (s.albedo * l.color) * _4060;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2066_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3025 = int(_2066_fa_shadow_cfg.x + 0.5f);\n    float _3035 = dot(world - _2066_fa_shadow_eye.xyz, _2066_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3040 = _3025 > 0;\n    bool _3049;\n    if (_3040)\n    {\n        int param = _3025 - 1;\n        _3049 = _3035 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3049 = _3040;\n    }\n    if (_3049)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3055 = _3025 > 1;\n        bool _3062;\n        if (_3055)\n        {\n            _3062 = _3035 > _2066_fa_shadow_split.x;\n        }\n        else\n        {\n            _3062 = _3055;\n        }\n        if (_3062)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3068 = _3025 > 2;\n        bool _3075;\n        if (_3068)\n        {\n            _3075 = _3035 > _2066_fa_shadow_split.y;\n        }\n        else\n        {\n            _3075 = _3068;\n        }\n        if (_3075)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3081 = _3025 > 3;\n        bool _3088;\n        if (_3081)\n        {\n            _3088 = _3035 > _2066_fa_shadow_split.z;\n        }\n        else\n        {\n            _3088 = _3081;\n        }\n        if (_3088)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5573 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5573 = -_5573;\n    }\n    float3 _5147 = normalize(_414_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5586 = { fa_world_pos, _5573, fa_world_tangent, fa_uv, fa_vertex_color, _5147, gl_FrontFacing };\n    SurfaceInput param_1 = _5586;\n    Surface _5155 = fa_standard_surface(param_1);\n    float3 _5604 = _5155.albedo;\n    float _5605 = _5155.alpha;\n    float3 _5606 = _5155.normal;\n    float _5607 = _5155.metallic;\n    float _5608 = _5155.roughness;\n    float _5609 = _5155.occlusion;\n    float3 _5610 = _5155.emission;\n    float _5611 = _5155.clearcoat;\n    float _5612 = _5155.clearcoat_roughness;\n    float3 _5613 = _5155.sheen_color;\n    float _5614 = _5155.sheen_roughness;\n    float _5615 = _5155.anisotropy;\n    float _5616 = _5155.anisotropy_rotation;\n    float _5617 = _5155.specular;\n    float _5618 = _5155.ior;\n    float3 _5619 = _5155.specular_color;\n    float _5620 = _5155.transmission;\n    float _5621 = _5155.thickness;\n    float3 _5622 = _5155.attenuation_color;\n    float _5623 = _5155.attenuation_distance;\n    SurfaceInput _5594 = { fa_world_pos, _5573, fa_world_tangent, fa_uv, fa_vertex_color, _5147, gl_FrontFacing };\n    SurfaceInput param_2 = _5594;\n    Surface param_3 = _5155;\n    surface(param_2, param_3);\n    _5604 = param_3.albedo;\n    _5605 = param_3.alpha;\n    _5606 = param_3.normal;\n    _5607 = param_3.metallic;\n    _5608 = param_3.roughness;\n    _5609 = param_3.occlusion;\n    _5610 = param_3.emission;\n    _5611 = param_3.clearcoat;\n    _5612 = param_3.clearcoat_roughness;\n    _5613 = param_3.sheen_color;\n    _5614 = param_3.sheen_roughness;\n    _5615 = param_3.anisotropy;\n    _5616 = param_3.anisotropy_rotation;\n    _5617 = param_3.specular;\n    _5618 = param_3.ior;\n    _5619 = param_3.specular_color;\n    _5620 = param_3.transmission;\n    _5621 = param_3.thickness;\n    _5622 = param_3.attenuation_color;\n    _5623 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5573;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5604 = param_6;\n    _5606 = param_7;\n    float3 result;\n    if (_414_fa_emissive.w > 0.5f)\n    {\n        result = _5604;\n    }\n    else\n    {\n        float3 _5194 = _5606;\n        float3 _5195 = normalize(_5194);\n        _5606 = _5195;\n        float3 param_8 = _5195;\n        float3 lit = (fa_indirect_diffuse(param_8) * _5604) * _5609;\n        int _5214 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5214; ln++)\n        {\n            int param_9 = ln;\n            int _5227 = fa_cl_light(param_9);\n            int param_10 = _5227;\n            if (fa_baked_keep(param_10) <= 0.0f)\n            {\n                continue;\n            }\n            int param_11 = _5227;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _5573;\n            LightSample _5243 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput _5602 = { fa_world_pos, _5573, fa_world_tangent, fa_uv, fa_vertex_color, _5147, gl_FrontFacing };\n            SurfaceInput param_14 = _5602;\n            Surface _5705 = { _5604, _5605, _5606, _5607, _5608, _5609, _5610, _5611, _5612, _5613, _5614, _5615, _5616, _5617, _5618, _5619, _5620, _5621, _5622, _5623 };\n            Surface param_15 = _5705;\n            LightSample param_16 = _5243;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _5258 = result;\n    float3 _5259 = _5258 + _5610;\n    result = _5259;\n    float3 param_17 = _5259;\n    float3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _5268 = _414_fa_fog.w > 0.0f;\n    bool _5275;\n    if (!_5268)\n    {\n        _5275 = _414_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5275 = _5268;\n    }\n    if (_5275)\n    {\n        float3 _5284 = fa_world_pos - _414_fa_camera_pos.xyz;\n        float _5290 = dot(_5284, _414_fa_fog_c.xyz);\n        bool _5294 = _414_fa_fog_c.w > 0.5f;\n        float _5295;\n        if (_5294)\n        {\n            _5295 = _5290;\n        }\n        else\n        {\n            _5295 = length(_5284);\n        }\n        float _5307 = _5295 - _414_fa_fog_b.x;\n        if (_5307 > 0.0f)\n        {\n            float _5316 = _414_fa_fog.w * _5307;\n            float tau = _5316 * _5316;\n            if (_414_fa_fog_b.y > 0.0f)\n            {\n                float _5332;\n                if (_5294)\n                {\n                    _5332 = fa_world_pos.y - (_414_fa_fog_c.y * _5290);\n                }\n                else\n                {\n                    _5332 = _414_fa_camera_pos.y;\n                }\n                float _5353 = lerp(_5332, fa_world_pos.y, clamp(_414_fa_fog_b.x / _5295, 0.0f, 1.0f));\n                float _5357 = fa_world_pos.y - _5353;\n                float _5362 = _5353 - _414_fa_fog_b.z;\n                float _5367 = fa_world_pos.y - _414_fa_fog_b.z;\n                bool _5370 = _5362 <= 0.0f;\n                bool _5371 = !_5370;\n                bool _5377;\n                if (_5371)\n                {\n                    _5377 = _414_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5377 = _5370;\n                }\n                float _5378;\n                if (_5377)\n                {\n                    _5378 = _414_fa_fog_b.y;\n                }\n                else\n                {\n                    _5378 = _414_fa_fog_b.y * exp(-min(_414_fa_fog_b.w * _5362, 80.0f));\n                }\n                bool _5405;\n                if (_5371)\n                {\n                    _5405 = _414_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5405 = _5370;\n                }\n                float _5406;\n                if (_5405)\n                {\n                    _5406 = _414_fa_fog_b.y * _5362;\n                }\n                else\n                {\n                    _5406 = (_414_fa_fog_b.y * (1.0f - exp(-min(_414_fa_fog_b.w * _5362, 80.0f)))) / _414_fa_fog_b.w;\n                }\n                bool _5431 = _5367 <= 0.0f;\n                bool _5438;\n                if (!_5431)\n                {\n                    _5438 = _414_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5438 = _5431;\n                }\n                float _5439;\n                if (_5438)\n                {\n                    _5439 = _414_fa_fog_b.y * _5367;\n                }\n                else\n                {\n                    _5439 = (_414_fa_fog_b.y * (1.0f - exp(-min(_414_fa_fog_b.w * _5367, 80.0f)))) / _414_fa_fog_b.w;\n                }\n                float _5466;\n                if (abs(_5357) < 0.001000000047497451305389404296875f)\n                {\n                    _5466 = _5378;\n                }\n                else\n                {\n                    _5466 = (_5439 - _5406) / _5357;\n                }\n                tau += (_5307 * max(_5466, 0.0f));\n            }\n            result = lerp(result, _414_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5605);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_414",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2066",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_4066",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _57_fa_view_proj : packoffset(c0);\n    row_major float4x4 _57_fa_light_vp : packoffset(c4);\n    float4 _57_fa_uv_scale : packoffset(c8);\n    float4 _57_fa_time : packoffset(c9);\n    float4 _57_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_vel_params : register(b2)\n{\n    row_major float4x4 _225_fa_vel_vp : packoffset(c0);\n    row_major float4x4 _225_fa_vel_prev_vp : packoffset(c4);\n    float4 _225_fa_vel_on : packoffset(c8);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float4 fa_prev_r0;\nstatic float4 fa_prev_r1;\nstatic float4 fa_prev_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_prev_r0 : TEXCOORD9;\n    float4 fa_prev_r1 : TEXCOORD10;\n    float4 fa_prev_r2 : TEXCOORD11;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4 fa_time_now()\n{\n    return _57_fa_time;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _97 = cross(model[1].xyz, model[2].xyz);\n    float _101 = (dot(model[0].xyz, _97) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _451 = { mul(float4(position, 1.0f), model).xyz, (((_97 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _101, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _101), texcoord0 * _57_fa_uv_scale.xy, color, position };\n    return _451;\n}\n\nfloat4x4 fa_rows_to_mat4(float4 r0, float4 r1, float4 r2)\n{\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat4x4 fa_prev_model()\n{\n    float4 param = fa_prev_r0;\n    float4 param_1 = fa_prev_r1;\n    float4 param_2 = fa_prev_r2;\n    return fa_rows_to_mat4(param, param_1, param_2);\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color, bool has_prev)\n{\n    bool _231;\n    if (has_prev)\n    {\n        _231 = _225_fa_vel_on.x > 0.5f;\n    }\n    else\n    {\n        _231 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _246 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _458 = _246.world_pos;\n    float4 _257 = float4(_458, 1.0f);\n    fa_world_pos = _458;\n    fa_world_normal = _246.world_normal;\n    fa_world_tangent = _246.world_tangent;\n    fa_uv = _246.uv;\n    fa_vertex_color = _246.color;\n    fa_pre_depth = -mul(_257, _57_fa_light_vp).z;\n    fa_pre_r0 = float3(_57_fa_light_vp[0].x, _57_fa_light_vp[1].x, _57_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_57_fa_light_vp[0].y, _57_fa_light_vp[1].y, _57_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_57_fa_light_vp[0].z, _57_fa_light_vp[1].z, _57_fa_light_vp[2].z);\n    gl_Position = mul(_257, _57_fa_view_proj);\n    fa_vel_cur = float3(0.0f, 0.0f, 1.0f);\n    fa_vel_prev = 0.0f.xxx;\n    if (_231)\n    {\n        float4 _330 = float4(position, 1.0f);\n        fa_vel_cur = float3(mul(_257, _225_fa_vel_vp).xyw);\n        fa_vel_prev = float3(mul(float4((_458 + mul(_330, fa_prev_model()).xyz) - mul(_330, model).xyz, 1.0f), _225_fa_vel_prev_vp).xyw);\n    }\n}\n\nvoid vert_main()\n{\n    fa_vtime = 0.0f.xxxx;\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    bool param_6 = true;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_prev_r0 = stage_input.fa_prev_r0;\n    fa_prev_r1 = stage_input.fa_prev_r1;\n    fa_prev_r2 = stage_input.fa_prev_r2;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    stage_output.fa_vel_cur = fa_vel_cur;\n    stage_output.fa_vel_prev = fa_vel_prev;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _214_fa_camera_pos : packoffset(c0);\n    float4 _214_fa_ambient : packoffset(c1);\n    float4 _214_fa_base_color : packoffset(c2);\n    float4 _214_fa_emissive : packoffset(c3);\n    float4 _214_fa_model_emissive : packoffset(c4);\n    float4 _214_fa_pbr : packoffset(c5);\n    float4 _214_fa_maps : packoffset(c6);\n    float4 _214_fa_fog : packoffset(c7);\n    float4 _214_fa_fog_b : packoffset(c8);\n    float4 _214_fa_fog_c : packoffset(c9);\n    float4 _214_fa_counts : packoffset(c10);\n    float4 _214_fa_env_sky : packoffset(c11);\n    float4 _214_fa_env_horizon : packoffset(c12);\n    float4 _214_fa_time : packoffset(c13);\n    float4 _214_fa_cl_vpx : packoffset(c14);\n    float4 _214_fa_cl_vpy : packoffset(c15);\n    float4 _214_fa_cl_vpw : packoffset(c16);\n    float4 _214_fa_cl_fwd : packoffset(c17);\n    float4 _214_fa_cl_grid : packoffset(c18);\n    float4 _214_fa_cl_info : packoffset(c19);\n    float4 _214_fa_layers_a : packoffset(c20);\n    float4 _214_fa_layers_b : packoffset(c21);\n    float4 _214_fa_layers_c : packoffset(c22);\n    float4 _214_fa_layers_d : packoffset(c23);\n    float4 _214_fa_ct_a : packoffset(c24);\n    float4 _214_fa_ct_b : packoffset(c25);\n    float4 _214_fa_ct_vpx : packoffset(c26);\n    float4 _214_fa_ct_vpy : packoffset(c27);\n    float4 _214_fa_ct_vpw : packoffset(c28);\n    float4 _214_fa_ct_fwd : packoffset(c29);\n    float4 _214_fa_tr_a : packoffset(c30);\n    float4 _214_fa_tr_b : packoffset(c31);\n    float4 _214_fa_probe_sh[9] : packoffset(c32);\n    float4 _214_fa_atlas : packoffset(c41);\n    float4 _214_fa_rpa_tile : packoffset(c42);\n    float4 _214_fa_rpa_pos : packoffset(c43);\n    float4 _214_fa_rpa_bx : packoffset(c44);\n    float4 _214_fa_rpa_by : packoffset(c45);\n    float4 _214_fa_rpa_bz : packoffset(c46);\n    float4 _214_fa_rpb_tile : packoffset(c47);\n    float4 _214_fa_rpb_pos : packoffset(c48);\n    float4 _214_fa_rpb_bx : packoffset(c49);\n    float4 _214_fa_rpb_by : packoffset(c50);\n    float4 _214_fa_rpb_bz : packoffset(c51);\n    float4 _214_fa_gi : packoffset(c52);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float2 fa_frag_velocity;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n    float2 fa_frag_velocity : SV_Target1;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w);\n    float param = _214_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _230 = fa_tex_fix(param_2, param_3);\n    float4 _892 = base_t;\n    _892.x = _230.x;\n    _892.y = _230.y;\n    _892.z = _230.z;\n    base_t = _892;\n    float4 _246 = (_892 * _214_fa_base_color) * i.vertex_color;\n    float3 _847 = i.world_normal;\n    if (_214_fa_maps.z > 0.5f)\n    {\n        float param_4 = _214_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _282 = fa_tex_fix(param_6, param_7);\n        float3 _286 = (_282 * 2.0f) - 1.0f.xxx;\n        float2 _291 = _286.xy * _214_fa_maps.x;\n        float3 _900 = _286;\n        _900.x = _291.x;\n        _900.y = _291.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _900;\n        _847 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w);\n    float param_10 = _214_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _322 = fa_tex_fix(param_12, param_13);\n    float4 _903 = mrt;\n    _903.x = _322.x;\n    _903.y = _322.y;\n    _903.z = _322.z;\n    mrt = _903;\n    float4 _354 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w);\n    float param_14 = _214_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _214_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _398 = fa_tex_fix(param_20, param_21);\n    float _852 = _214_fa_layers_a.x;\n    float _853 = _214_fa_layers_a.y;\n    float _856 = _214_fa_layers_a.z;\n    float _855 = _214_fa_layers_b.w;\n    float _858 = _214_fa_layers_c.x;\n    if (_214_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_214_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _852 *= _366.y;\n            _853 *= _366.z;\n            _855 *= _354.w;\n        }\n        if (_214_fa_layers_c.z > 1.5f)\n        {\n            _856 *= mrt.x;\n            _858 *= mrt.w;\n        }\n    }\n    Surface _885 = { _246.xyz, _246.w, _847, clamp(_214_fa_pbr.x * _322.z, 0.0f, 1.0f), clamp(_214_fa_pbr.y * _322.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_214_fa_maps.y * (_366.x - 1.0f)), _214_fa_emissive.xyz + (_214_fa_model_emissive.xyz * _398), _852, _853, _214_fa_layers_b.xyz, _855, _856, _214_fa_layers_a.w, _858, _214_fa_layers_c.y, _214_fa_layers_d.xyz, _214_fa_tr_a.x, _214_fa_tr_a.y, _214_fa_tr_b.xyz, _214_fa_tr_a.z };\n    return _885;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _742 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _742 = -_742;\n    }\n    float3 _550 = normalize(_214_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _755 = { fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing };\n    SurfaceInput param = _755;\n    SurfaceInput _763 = { fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing };\n    SurfaceInput param_1 = _763;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _565 = normalize(param_2.normal);\n    float3 _580 = normalize(float3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    float2 e = _580.xy / ((abs(_580.x) + abs(_580.y)) + abs(_592)).xx;\n    if (_592 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n    float2 motion = 1024.0f.xx;\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06f;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06f;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((float2(fa_vel_prev.x, -fa_vel_prev.y) / fa_vel_prev.z.xx) * 0.5f) - ((float2(fa_vel_cur.x, -fa_vel_cur.y) / fa_vel_cur.z.xx) * 0.5f), (-4.0f).xx, 4.0f.xx);\n    }\n    fa_frag_velocity = motion;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    fa_vel_cur = stage_input.fa_vel_cur;\n    fa_vel_prev = stage_input.fa_vel_prev;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    stage_output.fa_frag_velocity = fa_frag_velocity;\n    return stage_output;\n}\n",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _74_fa_view_proj : packoffset(c0);\n    row_major float4x4 _74_fa_light_vp : packoffset(c4);\n    float4 _74_fa_uv_scale : packoffset(c8);\n    float4 _74_fa_time : packoffset(c9);\n    float4 _74_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _213_fa_joint_rows[192] : packoffset(c0);\n};\n\ncbuffer fa_vel_params : register(b2)\n{\n    row_major float4x4 _470_fa_vel_vp : packoffset(c0);\n    row_major float4x4 _470_fa_vel_prev_vp : packoffset(c4);\n    float4 _470_fa_vel_on : packoffset(c8);\n};\n\nTexture2D<float4> fa_prev_pal_tex : register(t0);\nSamplerState fa_prev_pal_smp : register(s11);\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float4 fa_prev_r0;\nstatic float4 fa_prev_r1;\nstatic float4 fa_prev_r2;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n    float4 fa_prev_r0 : TEXCOORD11;\n    float4 fa_prev_r1 : TEXCOORD12;\n    float4 fa_prev_r2 : TEXCOORD13;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _204 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_213_fa_joint_rows[_204] * weights[i]);\n        r1 += (_213_fa_joint_rows[_204 + 1] * weights[i]);\n        r2 += (_213_fa_joint_rows[_204 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat4 fa_time_now()\n{\n    return _74_fa_time;\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _113 = cross(model[1].xyz, model[2].xyz);\n    float _117 = (dot(model[0].xyz, _113) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _716 = { mul(float4(position, 1.0f), model).xyz, (((_113 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _117, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _117), texcoord0 * _74_fa_uv_scale.xy, color, position };\n    return _716;\n}\n\nfloat4x4 fa_rows_to_mat4(float4 r0, float4 r1, float4 r2)\n{\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat4 fa_prev_pal_texel(int t)\n{\n    return fa_prev_pal_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4x4 fa_prev_skin_matrix(float4 joints, float4 weights, int base)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _332 = base + (int((joints[i] * 255.0f) + 0.5f) * 3);\n        int param = _332;\n        r0 += (fa_prev_pal_texel(param) * weights[i]);\n        int param_1 = _332 + 1;\n        r1 += (fa_prev_pal_texel(param_1) * weights[i]);\n        int param_2 = _332 + 2;\n        r2 += (fa_prev_pal_texel(param_2) * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nfloat4x4 fa_prev_model()\n{\n    float4 param = fa_prev_r0;\n    float4 param_1 = fa_prev_r1;\n    float4 param_2 = fa_prev_r2;\n    float4 param_3 = fa_joints;\n    float4 param_4 = fa_weights;\n    int param_5 = int(_470_fa_vel_on.w + 0.5f);\n    return mul(fa_prev_skin_matrix(param_3, param_4, param_5), fa_rows_to_mat4(param, param_1, param_2));\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color, bool has_prev)\n{\n    bool _475;\n    if (has_prev)\n    {\n        _475 = _470_fa_vel_on.x > 0.5f;\n    }\n    else\n    {\n        _475 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _490 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _723 = _490.world_pos;\n    float4 _501 = float4(_723, 1.0f);\n    fa_world_pos = _723;\n    fa_world_normal = _490.world_normal;\n    fa_world_tangent = _490.world_tangent;\n    fa_uv = _490.uv;\n    fa_vertex_color = _490.color;\n    fa_pre_depth = -mul(_501, _74_fa_light_vp).z;\n    fa_pre_r0 = float3(_74_fa_light_vp[0].x, _74_fa_light_vp[1].x, _74_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_74_fa_light_vp[0].y, _74_fa_light_vp[1].y, _74_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_74_fa_light_vp[0].z, _74_fa_light_vp[1].z, _74_fa_light_vp[2].z);\n    gl_Position = mul(_501, _74_fa_view_proj);\n    fa_vel_cur = float3(0.0f, 0.0f, 1.0f);\n    fa_vel_prev = 0.0f.xxx;\n    if (_475)\n    {\n        float4 _574 = float4(position, 1.0f);\n        fa_vel_cur = float3(mul(_501, _470_fa_vel_vp).xyw);\n        fa_vel_prev = float3(mul(float4((_723 + mul(_574, fa_prev_model()).xyz) - mul(_574, model).xyz, 1.0f), _470_fa_vel_prev_vp).xyw);\n    }\n}\n\nvoid vert_main()\n{\n    fa_vtime = 0.0f.xxxx;\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    bool param_8 = _470_fa_vel_on.z > 0.5f;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_prev_r0 = stage_input.fa_prev_r0;\n    fa_prev_r1 = stage_input.fa_prev_r1;\n    fa_prev_r2 = stage_input.fa_prev_r2;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    stage_output.fa_vel_cur = fa_vel_cur;\n    stage_output.fa_vel_prev = fa_vel_prev;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _214_fa_camera_pos : packoffset(c0);\n    float4 _214_fa_ambient : packoffset(c1);\n    float4 _214_fa_base_color : packoffset(c2);\n    float4 _214_fa_emissive : packoffset(c3);\n    float4 _214_fa_model_emissive : packoffset(c4);\n    float4 _214_fa_pbr : packoffset(c5);\n    float4 _214_fa_maps : packoffset(c6);\n    float4 _214_fa_fog : packoffset(c7);\n    float4 _214_fa_fog_b : packoffset(c8);\n    float4 _214_fa_fog_c : packoffset(c9);\n    float4 _214_fa_counts : packoffset(c10);\n    float4 _214_fa_env_sky : packoffset(c11);\n    float4 _214_fa_env_horizon : packoffset(c12);\n    float4 _214_fa_time : packoffset(c13);\n    float4 _214_fa_cl_vpx : packoffset(c14);\n    float4 _214_fa_cl_vpy : packoffset(c15);\n    float4 _214_fa_cl_vpw : packoffset(c16);\n    float4 _214_fa_cl_fwd : packoffset(c17);\n    float4 _214_fa_cl_grid : packoffset(c18);\n    float4 _214_fa_cl_info : packoffset(c19);\n    float4 _214_fa_layers_a : packoffset(c20);\n    float4 _214_fa_layers_b : packoffset(c21);\n    float4 _214_fa_layers_c : packoffset(c22);\n    float4 _214_fa_layers_d : packoffset(c23);\n    float4 _214_fa_ct_a : packoffset(c24);\n    float4 _214_fa_ct_b : packoffset(c25);\n    float4 _214_fa_ct_vpx : packoffset(c26);\n    float4 _214_fa_ct_vpy : packoffset(c27);\n    float4 _214_fa_ct_vpw : packoffset(c28);\n    float4 _214_fa_ct_fwd : packoffset(c29);\n    float4 _214_fa_tr_a : packoffset(c30);\n    float4 _214_fa_tr_b : packoffset(c31);\n    float4 _214_fa_probe_sh[9] : packoffset(c32);\n    float4 _214_fa_atlas : packoffset(c41);\n    float4 _214_fa_rpa_tile : packoffset(c42);\n    float4 _214_fa_rpa_pos : packoffset(c43);\n    float4 _214_fa_rpa_bx : packoffset(c44);\n    float4 _214_fa_rpa_by : packoffset(c45);\n    float4 _214_fa_rpa_bz : packoffset(c46);\n    float4 _214_fa_rpb_tile : packoffset(c47);\n    float4 _214_fa_rpb_pos : packoffset(c48);\n    float4 _214_fa_rpb_bx : packoffset(c49);\n    float4 _214_fa_rpb_by : packoffset(c50);\n    float4 _214_fa_rpb_bz : packoffset(c51);\n    float4 _214_fa_gi : packoffset(c52);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\nstatic float3 fa_vel_cur;\nstatic float3 fa_vel_prev;\nstatic float2 fa_frag_velocity;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float3 fa_vel_cur : TEXCOORD9;\n    float3 fa_vel_prev : TEXCOORD10;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n    float2 fa_frag_velocity : SV_Target1;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w);\n    float param = _214_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _230 = fa_tex_fix(param_2, param_3);\n    float4 _892 = base_t;\n    _892.x = _230.x;\n    _892.y = _230.y;\n    _892.z = _230.z;\n    base_t = _892;\n    float4 _246 = (_892 * _214_fa_base_color) * i.vertex_color;\n    float3 _847 = i.world_normal;\n    if (_214_fa_maps.z > 0.5f)\n    {\n        float param_4 = _214_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _282 = fa_tex_fix(param_6, param_7);\n        float3 _286 = (_282 * 2.0f) - 1.0f.xxx;\n        float2 _291 = _286.xy * _214_fa_maps.x;\n        float3 _900 = _286;\n        _900.x = _291.x;\n        _900.y = _291.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _900;\n        _847 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w);\n    float param_10 = _214_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _322 = fa_tex_fix(param_12, param_13);\n    float4 _903 = mrt;\n    _903.x = _322.x;\n    _903.y = _322.y;\n    _903.z = _322.z;\n    mrt = _903;\n    float4 _354 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w);\n    float param_14 = _214_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = _214_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _214_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _398 = fa_tex_fix(param_20, param_21);\n    float _852 = _214_fa_layers_a.x;\n    float _853 = _214_fa_layers_a.y;\n    float _856 = _214_fa_layers_a.z;\n    float _855 = _214_fa_layers_b.w;\n    float _858 = _214_fa_layers_c.x;\n    if (_214_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_214_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _852 *= _366.y;\n            _853 *= _366.z;\n            _855 *= _354.w;\n        }\n        if (_214_fa_layers_c.z > 1.5f)\n        {\n            _856 *= mrt.x;\n            _858 *= mrt.w;\n        }\n    }\n    Surface _885 = { _246.xyz, _246.w, _847, clamp(_214_fa_pbr.x * _322.z, 0.0f, 1.0f), clamp(_214_fa_pbr.y * _322.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_214_fa_maps.y * (_366.x - 1.0f)), _214_fa_emissive.xyz + (_214_fa_model_emissive.xyz * _398), _852, _853, _214_fa_layers_b.xyz, _855, _856, _214_fa_layers_a.w, _858, _214_fa_layers_c.y, _214_fa_layers_d.xyz, _214_fa_tr_a.x, _214_fa_tr_a.y, _214_fa_tr_b.xyz, _214_fa_tr_a.z };\n    return _885;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _742 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _742 = -_742;\n    }\n    float3 _550 = normalize(_214_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _755 = { fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing };\n    SurfaceInput param = _755;\n    SurfaceInput _763 = { fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing };\n    SurfaceInput param_1 = _763;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _565 = normalize(param_2.normal);\n    float3 _580 = normalize(float3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    float2 e = _580.xy / ((abs(_580.x) + abs(_580.y)) + abs(_592)).xx;\n    if (_592 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n    float2 motion = 1024.0f.xx;\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06f;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06f;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((float2(fa_vel_prev.x, -fa_vel_prev.y) / fa_vel_prev.z.xx) * 0.5f) - ((float2(fa_vel_cur.x, -fa_vel_cur.y) / fa_vel_cur.z.xx) * 0.5f), (-4.0f).xx, 4.0f.xx);\n    }\n    fa_frag_velocity = motion;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    fa_vel_cur = stage_input.fa_vel_cur;\n    fa_vel_prev = stage_input.fa_vel_prev;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    stage_output.fa_frag_velocity = fa_frag_velocity;\n    return stage_output;\n}\n",
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
