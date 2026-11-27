{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "4f7d190a643df7eea422f9bce37d2bb8920145f92f7e586baf62c54f579868ea",
  "slang": "hlsl5",
  "params": [
    "dark"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _263 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _263;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_270, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _423_fa_camera_pos : packoffset(c0);\n    float4 _423_fa_ambient : packoffset(c1);\n    float4 _423_fa_base_color : packoffset(c2);\n    float4 _423_fa_emissive : packoffset(c3);\n    float4 _423_fa_model_emissive : packoffset(c4);\n    float4 _423_fa_pbr : packoffset(c5);\n    float4 _423_fa_maps : packoffset(c6);\n    float4 _423_fa_fog : packoffset(c7);\n    float4 _423_fa_fog_b : packoffset(c8);\n    float4 _423_fa_fog_c : packoffset(c9);\n    float4 _423_fa_counts : packoffset(c10);\n    float4 _423_fa_env_sky : packoffset(c11);\n    float4 _423_fa_env_horizon : packoffset(c12);\n    float4 _423_fa_time : packoffset(c13);\n    float4 _423_fa_cl_vpx : packoffset(c14);\n    float4 _423_fa_cl_vpy : packoffset(c15);\n    float4 _423_fa_cl_vpw : packoffset(c16);\n    float4 _423_fa_cl_fwd : packoffset(c17);\n    float4 _423_fa_cl_grid : packoffset(c18);\n    float4 _423_fa_cl_info : packoffset(c19);\n    float4 _423_fa_layers_a : packoffset(c20);\n    float4 _423_fa_layers_b : packoffset(c21);\n    float4 _423_fa_layers_c : packoffset(c22);\n    float4 _423_fa_layers_d : packoffset(c23);\n    float4 _423_fa_ct_a : packoffset(c24);\n    float4 _423_fa_ct_b : packoffset(c25);\n    float4 _423_fa_ct_vpx : packoffset(c26);\n    float4 _423_fa_ct_vpy : packoffset(c27);\n    float4 _423_fa_ct_vpw : packoffset(c28);\n    float4 _423_fa_ct_fwd : packoffset(c29);\n    float4 _423_fa_tr_a : packoffset(c30);\n    float4 _423_fa_tr_b : packoffset(c31);\n    float4 _423_fa_probe_sh[9] : packoffset(c32);\n    float4 _423_fa_atlas : packoffset(c41);\n    float4 _423_fa_rpa_tile : packoffset(c42);\n    float4 _423_fa_rpa_pos : packoffset(c43);\n    float4 _423_fa_rpa_bx : packoffset(c44);\n    float4 _423_fa_rpa_by : packoffset(c45);\n    float4 _423_fa_rpa_bz : packoffset(c46);\n    float4 _423_fa_rpb_tile : packoffset(c47);\n    float4 _423_fa_rpb_pos : packoffset(c48);\n    float4 _423_fa_rpb_bx : packoffset(c49);\n    float4 _423_fa_rpb_by : packoffset(c50);\n    float4 _423_fa_rpb_bz : packoffset(c51);\n    float4 _423_fa_gi : packoffset(c52);\n    float4 _423_fa_gi_px : packoffset(c53);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2075_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2075_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2075_fa_shadow_info[4] : packoffset(c20);\n    float4 _2075_fa_shadow_split : packoffset(c24);\n    float4 _2075_fa_shadow_cfg : packoffset(c25);\n    float4 _2075_fa_shadow_bias : packoffset(c26);\n    float4 _2075_fa_shadow_eye : packoffset(c27);\n    float4 _2075_fa_shadow_fwd : packoffset(c28);\n    float4 _2075_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _4413_dark : packoffset(c0);\n    float _4413_fa_pad0 : packoffset(c0.y);\n    float _4413_fa_pad1 : packoffset(c0.z);\n    float _4413_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float fa_rt_slope;\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1351 = _423_fa_cl_info.x < 0.0f;\n    bool _1358;\n    if (!_1351)\n    {\n        _1358 = _423_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1358 = _1351;\n    }\n    bool _1366;\n    if (!_1358)\n    {\n        _1366 = _423_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1366 = _1358;\n    }\n    bool _1373;\n    if (!_1366)\n    {\n        _1373 = _423_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1373 = _1366;\n    }\n    bool _1380;\n    if (!_1373)\n    {\n        _1380 = _423_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1380 = _1373;\n    }\n    if (_1380)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1390 = float4(world_pos, 1.0f);\n    float _1396 = dot(_423_fa_cl_vpw, _1390);\n    if (!(_1396 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1418 = float2(dot(_423_fa_cl_vpx, _1390), dot(_423_fa_cl_vpy, _1390)) / _1396.xx;\n    int _1422 = int(_423_fa_cl_grid.x);\n    int _1426 = int(_423_fa_cl_grid.y);\n    int param = (int(_423_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_423_fa_cl_fwd.xyz, world_pos) + _423_fa_cl_fwd.w, _423_fa_cl_grid.w) / _423_fa_cl_grid.w) * _423_fa_cl_grid.z)), 0, int(_423_fa_cl_info.y) - 1) * _1426) + clamp(int(floor(((_1418.y * 0.5f) + 0.5f) * _423_fa_cl_grid.y)), 0, _1426 - 1)) * _1422)) + clamp(int(floor(((_1418.x * 0.5f) + 0.5f) * _423_fa_cl_grid.x)), 0, _1422 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1502 = fa_cluster_texel(param);\n    return int2(int(_1502.x), int(_1502.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    float _4202 = dot(_423_fa_ct_fwd.xyz, world_pos) + _423_fa_ct_fwd.w;\n    float _4205 = fwidth(_4202);\n    bool _4208 = _423_fa_ct_b.y > 0.5f;\n    bool _4215;\n    if (!_4208)\n    {\n        _4215 = _423_fa_ct_b.w > 0.5f;\n    }\n    else\n    {\n        _4215 = _4208;\n    }\n    if (_4215)\n    {\n        fa_rt_slope = min(1.5f * _4205, 0.100000001490116119384765625f * _4202);\n    }\n    fa_cl_ndir = int(_423_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4231 = fa_cluster_lookup(param);\n    fa_cl_slot = _4231.x;\n    fa_cl_local = _4231.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4462 = fa_linear_to_srgb(param);\n        c = _4462;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4470 = fa_srgb_to_linear(param_1);\n            c = _4470;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _306;\n    if (i.front_facing)\n    {\n        _306 = i.world_normal;\n    }\n    else\n    {\n        _306 = -i.world_normal;\n    }\n    float3 _330 = normalize(i.world_tangent.xyz - (_306 * dot(_306, i.world_tangent.xyz)));\n    float3 _357 = normalize(((_330 * m.x) + ((cross(_306, _330) * i.world_tangent.w) * m.y)) + (_306 * m.z));\n    float3 _360;\n    if (i.front_facing)\n    {\n        _360 = _357;\n    }\n    else\n    {\n        _360 = -_357;\n    }\n    return _360;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _423_fa_env_horizon.w);\n    float param = _423_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4502 = fa_tex_fix(param_2, param_3);\n    float4 _6378 = base_t;\n    _6378.x = _4502.x;\n    _6378.y = _4502.y;\n    _6378.z = _4502.z;\n    base_t = _6378;\n    float4 _4516 = (_6378 * _423_fa_base_color) * i.vertex_color;\n    float3 _6194 = i.world_normal;\n    if (_423_fa_maps.z > 0.5f)\n    {\n        float param_4 = _423_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _423_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4550 = fa_tex_fix(param_6, param_7);\n        float3 _4553 = (_4550 * 2.0f) - 1.0f.xxx;\n        float2 _4558 = _4553.xy * _423_fa_maps.x;\n        float3 _6386 = _4553;\n        _6386.x = _4558.x;\n        _6386.y = _4558.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6386;\n        _6194 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _423_fa_env_horizon.w);\n    float param_10 = _423_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4588 = fa_tex_fix(param_12, param_13);\n    float4 _6389 = mrt;\n    _6389.x = _4588.x;\n    _6389.y = _4588.y;\n    _6389.z = _4588.z;\n    mrt = _6389;\n    float4 _4618 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _423_fa_env_horizon.w);\n    float param_14 = _423_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4618.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4629 = fa_tex_fix(param_16, param_17);\n    float param_18 = _423_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _423_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4661 = fa_tex_fix(param_20, param_21);\n    float _6199 = _423_fa_layers_a.x;\n    float _6200 = _423_fa_layers_a.y;\n    float _6203 = _423_fa_layers_a.z;\n    float _6202 = _423_fa_layers_b.w;\n    float _6205 = _423_fa_layers_c.x;\n    if (_423_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_423_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6199 *= _4629.y;\n            _6200 *= _4629.z;\n            _6202 *= _4618.w;\n        }\n        if (_423_fa_layers_c.z > 1.5f)\n        {\n            _6203 *= mrt.x;\n            _6205 *= mrt.w;\n        }\n    }\n    Surface _6232 = { _4516.xyz, _4516.w, _6194, clamp(_423_fa_pbr.x * _4588.z, 0.0f, 1.0f), clamp(_423_fa_pbr.y * _4588.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_423_fa_maps.y * (_4629.x - 1.0f)), _423_fa_emissive.xyz + (_423_fa_model_emissive.xyz * _4661), _6199, _6200, _423_fa_layers_b.xyz, _6202, _6203, _423_fa_layers_a.w, _6205, _423_fa_layers_c.y, _423_fa_layers_d.xyz, _423_fa_tr_a.x, _423_fa_tr_a.y, _423_fa_tr_b.xyz, _423_fa_tr_a.z };\n    return _6232;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1582 = rect.zw - rect.xy;\n    float2 _1586 = _1582 * atlas;\n    float2 _1590 = ddx * _1586;\n    float2 _1594 = ddy * _1586;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1582), clamp(0.5f * log2(max(max(dot(_1590, _1590), dot(_1594, _1594)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1627 = _423_fa_counts.y < 0.5f;\n    bool _1634;\n    if (!_1627)\n    {\n        _1634 = _423_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1634 = _1627;\n    }\n    if (_1634)\n    {\n        return;\n    }\n    float3 _1640 = ddx(world_pos);\n    float3 _1643 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1647 = fa_cluster_texel(param);\n    int _1651 = int(_1647.w);\n    if (_1651 < 1)\n    {\n        return;\n    }\n    int _1661 = int(_423_fa_counts.y + 0.5f);\n    int param_1 = _1661;\n    float4 _1665 = fa_light_texel(param_1);\n    float2 _1668 = _1665.yz;\n    int _1672 = int(_1665.w);\n    int param_2 = _1661 + 1;\n    float4 _1677 = fa_light_texel(param_2);\n    float _1678 = _1677.x;\n    int _1684 = int(_423_fa_counts.w + 0.5f) - 1;\n    int _1688 = int(_1647.z);\n    float3 _1953;\n    for (int k = 0; k < _1651; k++)\n    {\n        int _1701 = _1688 + k;\n        int param_3 = _1672 + (_1701 >> 2);\n        int _1718 = (_1661 + 2) + (int(fa_light_texel(param_3)[_1701 & 3]) * 7);\n        int param_4 = _1718 + 6;\n        float4 _1723 = fa_light_texel(param_4);\n        if (((int(_1723.w + 0.5f) >> _1684) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1718;\n        float4 _1738 = fa_light_texel(param_5);\n        int param_6 = _1718 + 1;\n        float4 _1743 = fa_light_texel(param_6);\n        int param_7 = _1718 + 2;\n        float4 _1748 = fa_light_texel(param_7);\n        float3 _1751 = _1738.xyz;\n        float _1756 = dot(_1751, world_pos) + _1738.w;\n        float3 _1758 = _1743.xyz;\n        float _1763 = dot(_1758, world_pos) + _1743.w;\n        float3 _1765 = _1748.xyz;\n        float _1770 = dot(_1765, world_pos) + _1748.w;\n        bool _1775 = abs(_1756) > 0.5f;\n        bool _1783;\n        if (!_1775)\n        {\n            _1783 = abs(_1763) > 0.5f;\n        }\n        else\n        {\n            _1783 = _1775;\n        }\n        bool _1791;\n        if (!_1783)\n        {\n            _1791 = abs(_1770) > 0.5f;\n        }\n        else\n        {\n            _1791 = _1783;\n        }\n        if (_1791)\n        {\n            continue;\n        }\n        float _1806 = clamp(dot(geo_normal, normalize(_1765)) * _1723.z, 0.0f, 1.0f);\n        if (_1806 <= 0.0f)\n        {\n            continue;\n        }\n        float _1826 = (clamp((0.5f - abs(_1770)) * 10.0f, 0.0f, 1.0f) * _1806) * _1723.x;\n        float2 _1834 = float2(_1756 + 0.5f, 0.5f - _1763);\n        float2 _1844 = float2(dot(_1751, _1640), dot(_1758, _1640));\n        float2 _1854 = float2(dot(_1751, _1643), dot(_1758, _1643));\n        int param_8 = _1718 + 5;\n        float4 _1859 = fa_light_texel(param_8);\n        int param_9 = _1718 + 3;\n        float4 _1864 = fa_light_texel(param_9);\n        int param_10 = _1718 + 4;\n        float4 _1869 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1859.xyz;\n        bool _1879 = _1864.z > _1864.x;\n        if (_1879)\n        {\n            float4 param_11 = _1864;\n            float2 param_12 = _1834;\n            float2 param_13 = _1668;\n            float2 param_14 = _1844;\n            float2 param_15 = _1854;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1678 > 0.5f) && (_1678 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1905 = fa_dc_to_linear(param_16);\n                float4 _6282 = tx;\n                _6282.x = _1905.x;\n                _6282.y = _1905.y;\n                _6282.z = _1905.z;\n                tx = _6282;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1826 * tex_a) * _1859.w, 0.0f, 1.0f).xxx);\n        if (_1869.z > _1869.x)\n        {\n            float4 param_17 = _1869;\n            float2 param_18 = _1834;\n            float2 param_19 = _1668;\n            float2 param_20 = _1844;\n            float2 param_21 = _1854;\n            float4 _1949 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1678 > 1.5f)\n            {\n                float3 param_22 = _1949.xyz;\n                float3 _1959 = fa_dc_to_srgb(param_22);\n                _1953 = _1959;\n            }\n            else\n            {\n                _1953 = _1949.xyz;\n            }\n            float3 _1968 = (_1953 * 2.0f) - 1.0f.xxx;\n            float2 _1973 = _1968.xy * _1723.y;\n            float3 _1995 = (normalize(_1751) * _1973.x) + (normalize(_1758) * _1973.y);\n            float3 _1998 = normalize(normal);\n            normal = normalize(lerp(_1998, normalize((_1998 * max(_1968.z, 0.0500000007450580596923828125f)) + (_1995 - (_1998 * dot(_1998, _1995)))), clamp(_1826 * (_1879 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3725_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3725_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_423_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3666 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3666;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3775 = (1.0f - _423_fa_rpa_tile.w) - _423_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3781 = _423_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3775 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3781)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _423_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3775;\n            }\n        }\n        else\n        {\n            amb = _423_fa_ambient.xyz * _3775;\n        }\n    }\n    bool _3832 = _423_fa_rpa_tile.w > 0.0f;\n    if (_3832)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _423_fa_rpa_tile.xy;\n            float param_4 = _423_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _423_fa_rpa_tile.w);\n        }\n    }\n    bool _3863 = _423_fa_rpb_tile.w > 0.0f;\n    if (_3863)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _423_fa_rpb_tile.xy;\n            float param_7 = _423_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _423_fa_rpb_tile.w);\n        }\n    }\n    if ((_3781 || _3832) || _3863)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3686 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3689 = _3686.x;\n    float _3691 = _3686.z;\n    float2 e = float2(_3689, _3691);\n    if (_3686.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3691)) * ((_3689 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3689)) * ((_3691 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _4775 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _4780 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _4785 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _4790 = fa_light_texel(param_3);\n    bool _4793 = _4790.z < 0.5f;\n    bool _4801;\n    if (!_4793)\n    {\n        _4801 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _4801 = _4793;\n    }\n    if (_4801)\n    {\n        return 0.0f.xxx;\n    }\n    float _4808 = max(_4775.w, 9.9999997473787516355514526367188e-05f);\n    float3 _4811 = _4780.xyz;\n    float3 _4815 = _4775.xyz;\n    float3 _4819 = (fa_world_pos - _4815) / _4808.xxx;\n    float3 _4828 = min(_4819 + 0.5f.xxx, (_4811 - 0.5f.xxx) - _4819);\n    float _4837 = min(_4828.x, min(_4828.y, _4828.z));\n    if (!(_4837 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4852 = _4811 - 1.0f.xxx;\n    float3 _4853 = clamp(_4819, 0.0f.xxx, _4852);\n    float3 _4861 = min(floor(_4853), max(_4811 - 2.0f.xxx, 0.0f.xxx));\n    float3 _4865 = _4853 - _4861;\n    float3 _4877 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _4808));\n    int _4882 = int(_4785.y + 0.5f);\n    float _4887 = 0.3257350027561187744140625f * n.y;\n    float _4891 = 0.3257350027561187744140625f * n.z;\n    float _4895 = 0.3257350027561187744140625f * n.x;\n    float _4902 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _4909 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _4918 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _4925 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _4938 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _4945 = 8 + int(_4790.w);\n    float _4972;\n    float _4985;\n    float _4999;\n    for (int k = 0; k < _4945; k++)\n    {\n        float _4958 = float(k & 1);\n        float _4962 = float((k >> 1) & 1);\n        float _4966 = float((k >> 2) & 1);\n        if (_4958 > 0.5f)\n        {\n            _4972 = _4865.x;\n        }\n        else\n        {\n            _4972 = 1.0f - _4865.x;\n        }\n        if (_4962 > 0.5f)\n        {\n            _4985 = _4865.y;\n        }\n        else\n        {\n            _4985 = 1.0f - _4865.y;\n        }\n        if (_4966 > 0.5f)\n        {\n            _4999 = _4865.z;\n        }\n        else\n        {\n            _4999 = 1.0f - _4865.z;\n        }\n        float _5009 = (_4972 * _4985) * _4999;\n        if (!(_5009 > 0.0f))\n        {\n            continue;\n        }\n        float3 _5022 = min(_4861 + float3(_4958, _4962, _4966), _4852);\n        int _5042 = int(((_4785.x + _5022.x) + (_4780.x * (_5022.y + (_4780.y * _5022.z)))) + 0.5f);\n        float2 _5057 = float2(float(_5042 % _4882) * 10.0f, 1024.0f + (float(_5042 / _4882) * 11.0f));\n        float2 param_4 = _5057 + float2(9.5f, 10.5f);\n        float4 _5065 = fa_gi_fetch(param_4);\n        bool _5068 = _5065.y < 0.5f;\n        bool _5077;\n        if (!_5068)\n        {\n            _5077 = _5065.x > _4790.y;\n        }\n        else\n        {\n            _5077 = _5068;\n        }\n        if (_5077)\n        {\n            continue;\n        }\n        float3 _5089 = _4877 - (_4815 + (_5022 * _4808));\n        float _5092 = length(_5089);\n        float3 _5098 = _5089 / max(_5092, 9.9999997473787516355514526367188e-05f).xxx;\n        float _5108 = max(9.9999997473787516355514526367188e-05f, (dot(-_5098, n) + 1.0f) * 0.5f);\n        float w = _5009 * (_5108 * _5108);\n        float3 param_5 = _5098;\n        float2 param_6 = (_5057 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _5128 = fa_gi_fetch(param_6);\n        float _5135 = _5092 / max(_4785.z, 9.9999997473787516355514526367188e-05f);\n        float _5138 = _5128.x;\n        if (_5135 > _5138)\n        {\n            float _5151 = max(_5128.y - (_5138 * _5138), 0.0f);\n            float _5156 = _5135 - _5138;\n            float _5165 = _5151 / max(_5151 + (_5156 * _5156), 9.9999999600419720025001879548654e-13f);\n            w *= ((_5165 * _5165) * _5165);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _5057 + float2(0.5f, 10.5f);\n        float2 param_8 = _5057 + float2(1.5f, 10.5f);\n        float2 param_9 = _5057 + float2(2.5f, 10.5f);\n        float2 param_10 = _5057 + float2(3.5f, 10.5f);\n        float2 param_11 = _5057 + float2(4.5f, 10.5f);\n        float2 param_12 = _5057 + float2(5.5f, 10.5f);\n        float2 param_13 = _5057 + float2(6.5f, 10.5f);\n        float2 param_14 = _5057 + float2(7.5f, 10.5f);\n        float2 param_15 = _5057 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _4887)) + (fa_gi_fetch(param_9).xyz * _4891)) + (fa_gi_fetch(param_10).xyz * _4895)) + (fa_gi_fetch(param_11).xyz * _4902)) + (fa_gi_fetch(param_12).xyz * _4909)) + (fa_gi_fetch(param_13).xyz * _4918)) + (fa_gi_fetch(param_14).xyz * _4925)) + (fa_gi_fetch(param_15).xyz * _4938)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_4837 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _5293;\n    if (_423_fa_gi.z > 0.5f)\n    {\n        _5293 = _4790.x;\n    }\n    else\n    {\n        _5293 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_4785.w * _5293);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _5317 = normalize(_423_fa_camera_pos.xyz - fa_world_pos);\n    int _5322 = int(_423_fa_gi.x + 0.5f);\n    int _5327 = int(_423_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _5327) && (k < 8); k++)\n    {\n        int param = _5322 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _5317;\n        float3 _5352 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5357 = param_3 * left;\n        acc += (_5352 * _5357);\n        left -= _5357;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_423_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _5386 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5386;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_423_fa_gi_px.x > 0.5f)\n    {\n        float4 _5428 = float4(fa_world_pos, 1.0f);\n        float2 _5447 = float2(dot(_423_fa_ct_vpx, _5428), dot(_423_fa_ct_vpy, _5428)) / max(dot(_423_fa_ct_vpw, _5428), 9.9999997473787516355514526367188e-05f).xx;\n        float _5456;\n        if (_423_fa_ct_a.y > 0.5f)\n        {\n            _5456 = (_5447.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5456 = 0.5f - (_5447.y * 0.5f);\n        }\n        return fa_lightmap.Load(int3(clamp(int2(float2((_5447.x * 0.5f) + 0.5f, _5456) * _423_fa_ct_a.zw), int2(0, 0), int2(_423_fa_ct_a.zw) - int2(1, 1)), 0)).xyz;\n    }\n    if (_423_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _423_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_423_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_423_fa_cl_info.x) + int(_423_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_423_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4172;\n    if (fa_lm.z > 0.5f)\n    {\n        _4172 = 0.0f;\n    }\n    else\n    {\n        _4172 = 1.0f - clamp(_423_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4183 = _4172 < 1.0f;\n    bool _4189;\n    if (_4183)\n    {\n        int param = li;\n        _4189 = fa_light_baked(param);\n    }\n    else\n    {\n        _4189 = _4183;\n    }\n    return _4189 ? _4172 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _601 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _614 = (c - (ru * hx)) - p;\n        float3 _620 = ru * (2.0f * hx);\n        float _626 = max(dot(_620, _620), 9.9999999392252902907785028219223e-09f);\n        float _630 = dot(_614, _620);\n        float t = clamp((-_630) / _626, 0.0f, 1.0f);\n        if (_601)\n        {\n            float _645 = dot(r, _620);\n            float _651 = _626 - (_645 * _645);\n            if (abs(_651) > (9.9999997473787516355514526367188e-06f * _626))\n            {\n                t = clamp(((dot(r, _614) * _645) - _630) / _651, 0.0f, 1.0f);\n            }\n        }\n        return (p + _614) + (_620 * t);\n    }\n    float3 q = p;\n    float _683 = dot(r, axis);\n    bool _691;\n    if (_601)\n    {\n        _691 = abs(_683) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _691 = _601;\n    }\n    if (_691)\n    {\n        float _701 = dot(c - p, axis) / _683;\n        if (_701 > 0.0f)\n        {\n            q = p + (r * _701);\n        }\n    }\n    float3 _714 = q - c;\n    float2 xy = float2(dot(_714, ru), dot(_714, uu));\n    if (shape > 0.5f)\n    {\n        float _729 = length(xy);\n        if (_729 > hx)\n        {\n            xy *= (hx / _729);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _482_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _482_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _521 = dot(d, right);\n    float _525 = dot(d, up);\n    float _536;\n    if (((_521 * _521) + (_525 * _525)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _536 = atan2(_525, _521) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _536 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_536 - floor(_536)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _372 = abs(d);\n    float _374 = _372.x;\n    float _376 = _372.y;\n    bool _377 = _374 >= _376;\n    bool _385;\n    if (_377)\n    {\n        _385 = _374 >= _372.z;\n    }\n    else\n    {\n        _385 = _377;\n    }\n    int _386;\n    if (_385)\n    {\n        _386 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _400;\n        if (_376 >= _372.z)\n        {\n            _400 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _400 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _386 = _400;\n    }\n    return _386;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _767 = fa_light_base(param);\n    bool _771 = _423_fa_ambient.w > 4.5f;\n    int param_1 = _767;\n    float4 _775 = fa_light_texel(param_1);\n    int param_2 = _767 + 1;\n    float4 _780 = fa_light_texel(param_2);\n    float _783 = _780.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _795 = _771 && (_783 > 2.5f);\n    fa_light_is_area = _795;\n    bool _797 = _783 < 0.5f;\n    float3 l;\n    if (_797)\n    {\n        l = normalize(_775.xyz);\n        if (_771)\n        {\n            int param_3 = _767 + 6;\n            float4 _811 = fa_light_texel(param_3);\n            if (_811.z > 0.5f)\n            {\n                int param_4 = _767 + 4;\n                float4 _821 = fa_light_texel(param_4);\n                int param_5 = _767 + 5;\n                float4 _826 = fa_light_texel(param_5);\n                float2 param_6 = _811.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _821.xyz) * _821.w, (-dot(world_pos, _826.xyz)) * _826.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _856 = _775.xyz;\n        float3 _858 = _856 - world_pos;\n        float3 to_light = _858;\n        float _861 = length(_858);\n        float reach = _861;\n        bool front = true;\n        if (_795)\n        {\n            int param_8 = _767 + 7;\n            reach = max(_861 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _767 + 4;\n            float4 _885 = fa_light_texel(param_9);\n            int param_10 = _767 + 5;\n            float4 _890 = fa_light_texel(param_10);\n            int param_11 = _767 + 6;\n            float4 _895 = fa_light_texel(param_11);\n            float _896 = _895.w;\n            int param_12 = _767 + 2;\n            float3 _903 = normalize(fa_light_texel(param_12).xyz);\n            bool _905 = _896 > 1.5f;\n            bool _913;\n            if (!_905)\n            {\n                _913 = dot(_903, to_light) < 0.0f;\n            }\n            else\n            {\n                _913 = _905;\n            }\n            front = _913;\n            float3 r = 0.0f.xxx;\n            float3 _922 = _423_fa_camera_pos.xyz - world_pos;\n            bool _926 = dot(n, n) > 0.5f;\n            bool _934;\n            if (_926)\n            {\n                _934 = dot(_922, _922) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _934 = _926;\n            }\n            if (_934)\n            {\n                r = reflect(-normalize(_922), normalize(n));\n            }\n            float3 param_13 = _856;\n            float3 param_14 = _903;\n            float3 param_15 = _885.xyz;\n            float3 param_16 = _890.xyz;\n            float param_17 = _885.w;\n            float param_18 = _890.w;\n            float param_19 = _896;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _970 = length(to_light);\n        dist = _970;\n        l = to_light / max(_970, 9.9999997473787516355514526367188e-05f).xxx;\n        float _984 = reach / max(_775.w, 0.001000000047497451305389404296875f);\n        float _990 = clamp(1.0f - (_984 * _984), 0.0f, 1.0f);\n        float _992;\n        if (front)\n        {\n            _992 = _990 * _990;\n        }\n        else\n        {\n            _992 = 0.0f;\n        }\n        atten = _992;\n        bool _1003 = _783 < 2.5f;\n        if ((_783 > 1.5f) && _1003)\n        {\n            int param_22 = _767 + 2;\n            float4 _1011 = fa_light_texel(param_22);\n            float _1021 = _1011.w;\n            int param_23 = _767 + 3;\n            float4 _1026 = fa_light_texel(param_23);\n            float _1027 = _1026.x;\n            float cos_inner = _1027;\n            if (_1027 > 1.5f)\n            {\n                cos_inner = lerp(_1021, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1021, cos_inner, dot(-l, normalize(_1011.xyz)));\n        }\n        if (_771 && (_783 < 1.5f))\n        {\n            int param_24 = _767 + 6;\n            float4 _1051 = fa_light_texel(param_24);\n            if (_1051.z > 0.5f)\n            {\n                float3 _1059 = -to_light;\n                int param_25 = _767 + 4;\n                int param_26 = _767 + 5;\n                float3 _1073 = fa_light_texel(param_25).xyz;\n                float3 _1077 = fa_light_texel(param_26).xyz;\n                float3 _1086 = float3(dot(_1059, _1073), dot(_1059, _1077), dot(_1059, cross(_1073, _1077)));\n                float3 param_27 = _1086;\n                int _1090 = fa_cube_face(param_27);\n                int param_28 = _1090;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1117 = float2(dot(_1086, cross(param_29, param_30)), dot(_1086, param_30)) / max(dot(_1086, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1121 = _1090 / 3;\n                float2 param_31 = _1051.xy + (float2(float(_1090 - (_1121 * 3)), float(_1121)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1117.x), 0.5f - (0.5f * _1117.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _767 + 7;\n            float4 _1151 = fa_light_texel(param_33);\n            if (_1151.z > 0.5f)\n            {\n                int param_34 = _767 + 2;\n                int param_35 = _767 + 4;\n                int param_36 = _767 + 5;\n                float2 param_37 = _1151.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_771 && _1003)\n            {\n                int param_42 = _767 + 6;\n                float4 _1198 = fa_light_texel(param_42);\n                int param_43 = _767 + 7;\n                float4 _1203 = fa_light_texel(param_43);\n                bool _1206 = _1198.z > 0.5f;\n                bool _1213;\n                if (!_1206)\n                {\n                    _1213 = _1203.z > 0.5f;\n                }\n                else\n                {\n                    _1213 = _1206;\n                }\n                if (_1213)\n                {\n                    int param_44 = _767 + 2;\n                    float4 _1220 = fa_light_texel(param_44);\n                    float3 _1224 = normalize(_1220.xyz);\n                    int param_45 = _767 + 4;\n                    float4 _1229 = fa_light_texel(param_45);\n                    int param_46 = _767 + 5;\n                    float4 _1234 = fa_light_texel(param_46);\n                    if (_1206)\n                    {\n                        float3 _1242 = -to_light;\n                        float _1249 = _1220.w;\n                        float _1265 = 0.5f / max(dot(_1242, _1224) * (sqrt(max(1.0f - (_1249 * _1249), 0.0f)) / max(_1249, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1198.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1242, _1229.xyz) * _1265), 0.5f - (dot(_1242, _1234.xyz) * _1265));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1203.z > 0.5f)\n                    {\n                        float2 param_49 = _1203.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1224;\n                        float3 param_52 = _1229.xyz;\n                        float3 param_53 = _1234.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6148 = _780.xyz * atten;\n    if (_771)\n    {\n        _6148 *= fa_light_tint;\n    }\n    int _1333;\n    if (_797)\n    {\n        _1333 = 0;\n    }\n    else\n    {\n        _1333 = ((_783 > 1.5f) && (_783 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _6159 = { l, _6148, atten, 1.0f, dist, _1333 };\n    return _6159;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2122 = fa_shadow_depth(param, param_1);\n    float _2126;\n    if (conv.x < 0.5f)\n    {\n        _2126 = _2122;\n    }\n    else\n    {\n        _2126 = (conv.y * conv.z) / (conv.z - (_2122 * (conv.z - conv.y)));\n    }\n    return _2126;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2172 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2178 = float2(cos(_2172), sin(_2172));\n    float2 dir = _2178;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2187;\n        if (k < 0.0f)\n        {\n            _2187 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2187 = k;\n        }\n        float _2206 = clamp((_2187 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2225 = sqrt((float(i) + 0.5f) * 0.0625f) * _2206;\n            float2 param_3 = uv + (dir * (_2075_fa_shadow_bias.zw * _2225));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2239 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2239 < (zr - (_2225 * plane)))\n            {\n                sum += _2239;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2267 = sum / cnt;\n        float _2277;\n        if (k < 0.0f)\n        {\n            _2277 = (-k) / max(_2267, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2277 = k;\n        }\n        radius = clamp(((max(zr - _2267, 0.0f) * unit) * _2277) / texel_m, 1.5f, 16.0f);\n        dir = _2178;\n    }\n    float lit = 0.0f;\n    int _2303 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2303; i_1++)\n    {\n        float _2322 = sqrt((float(i_1) + 0.5f) / float(_2303)) * radius;\n        float2 param_7 = uv + (dir * (_2075_fa_shadow_bias.zw * _2322));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2322 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2303);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2527 = _423_fa_pbr.z < 0.5f;\n    bool _2534;\n    if (!_2527)\n    {\n        _2534 = _2075_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2534 = _2527;\n    }\n    if (_2534)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2075_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2547 = fa_light_texel(param);\n    float _2548 = _2547.x;\n    if (_2548 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2557 = int(_2548 + 0.5f);\n    int param_1 = _2557;\n    float4 _2561 = fa_light_texel(param_1);\n    int param_2 = _2557 + 1;\n    float4 _2566 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2569 = _2561.y;\n    if (_2569 > 0.0f)\n    {\n        float _2586 = 1.0f - smoothstep(0.75f * _2569, _2569, length(world - _2075_fa_shadow_eye.xyz));\n        fade = _2586;\n        if (_2586 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2561.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2610 = (_2557 + 2) + (face * 6);\n    int param_4 = _2610;\n    int param_5 = _2610 + 1;\n    int param_6 = _2610 + 3;\n    float4 _2624 = fa_light_texel(param_6);\n    int param_7 = _2610 + 4;\n    float4 _2629 = fa_light_texel(param_7);\n    int param_8 = _2610 + 5;\n    float4 _2634 = fa_light_texel(param_8);\n    float _2646 = _2634.x * max(dot(_2624, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2651 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2674 = clamp(dot(n, _2624.xyz), -1.0f, 1.0f);\n    float _2693 = min(sqrt(1.0f - (_2674 * _2674)) / max(abs(dot(n, world - lpos)) / max(dot(_2624, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2696 = _2566.y;\n    float _2698;\n    if (_2696 > 0.0f)\n    {\n        _2698 = _2696;\n    }\n    else\n    {\n        _2698 = 1.5f * _2646;\n    }\n    float4 _2718 = float4(world + (n * (_2698 * sqrt(1.0f - (_2651 * _2651)))), 1.0f);\n    float _2722 = dot(_2624, _2718);\n    float _2725 = _2634.y;\n    if (_2722 < _2725)\n    {\n        return 1.0f;\n    }\n    float2 _2740 = float2(dot(fa_light_texel(param_4), _2718), dot(fa_light_texel(param_5), _2718)) / _2722.xx;\n    float _2742 = _2740.x;\n    bool _2745 = _2742 < _2629.x;\n    bool _2754;\n    if (!_2745)\n    {\n        _2754 = _2742 > _2629.z;\n    }\n    else\n    {\n        _2754 = _2745;\n    }\n    bool _2763;\n    if (!_2754)\n    {\n        _2763 = _2740.y < _2629.y;\n    }\n    else\n    {\n        _2763 = _2754;\n    }\n    bool _2772;\n    if (!_2763)\n    {\n        _2772 = _2740.y > _2629.w;\n    }\n    else\n    {\n        _2772 = _2763;\n    }\n    if (_2772)\n    {\n        return 1.0f;\n    }\n    float _2778 = _2566.x;\n    float _2780;\n    if (_2778 > 0.0f)\n    {\n        _2780 = _2778;\n    }\n    else\n    {\n        _2780 = 1.5f * _2646;\n    }\n    float2 param_9 = _2740;\n    float4 param_10 = _2629;\n    float param_11 = _2722 - (_2780 * (1.0f + (0.5f * _2693)));\n    float param_12 = _2646;\n    float param_13 = 1.0f;\n    float param_14 = _2634.z * 0.25f;\n    float param_15 = (_2646 * min(_2693, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2725, _2634.z);\n    int param_17 = int(_2561.z + 0.5f);\n    float param_18 = _2561.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _3287 = _423_fa_ct_b.w > 0.5f;\n    bool _3293;\n    if (_3287)\n    {\n        _3293 = _423_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3293 = _3287;\n    }\n    bool _3299;\n    if (_3293)\n    {\n        _3299 = _2075_fa_shadow_lcfg.x > 0.5f;\n    }\n    else\n    {\n        _3299 = _3293;\n    }\n    if (_3299)\n    {\n        int param = (int(_2075_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n        float4 _3311 = fa_light_texel(param);\n        float _3312 = _3311.z;\n        if (_3312 > 0.5f)\n        {\n            float _3325 = dot(_423_fa_ct_fwd.xyz, world) + _423_fa_ct_fwd.w;\n            float _3331 = ((0.00200000009499490261077880859375f * _3325) + 0.00999999977648258209228515625f) + fa_rt_slope;\n            float4 _3337 = float4(world, 1.0f);\n            float _3342 = dot(_423_fa_ct_vpw, _3337);\n            if (_3342 > 9.9999997473787516355514526367188e-05f)\n            {\n                float2 _3359 = float2(dot(_423_fa_ct_vpx, _3337), dot(_423_fa_ct_vpy, _3337)) / _3342.xx;\n                float _3364 = (_3359.x * 0.5f) + 0.5f;\n                float _3368;\n                if (_423_fa_ct_a.y > 0.5f)\n                {\n                    _3368 = (_3359.y * 0.5f) + 0.5f;\n                }\n                else\n                {\n                    _3368 = 0.5f - (_3359.y * 0.5f);\n                }\n                bool _3384 = _3364 >= 0.0f;\n                bool _3390;\n                if (_3384)\n                {\n                    _3390 = _3364 < 1.0f;\n                }\n                else\n                {\n                    _3390 = _3384;\n                }\n                bool _3396;\n                if (_3390)\n                {\n                    _3396 = _3368 >= 0.0f;\n                }\n                else\n                {\n                    _3396 = _3390;\n                }\n                bool _3402;\n                if (_3396)\n                {\n                    _3402 = _3368 < 1.0f;\n                }\n                else\n                {\n                    _3402 = _3396;\n                }\n                if (_3402)\n                {\n                    int2 _3419 = int2(_423_fa_ct_a.zw) - int2(1, 1);\n                    int2 _3420 = clamp(int2(float2(_3364, _3368) * _423_fa_ct_a.zw), int2(0, 0), _3419);\n                    float _3424;\n                    if (_3312 < 1.5f)\n                    {\n                        _3424 = 1.0f;\n                    }\n                    else\n                    {\n                        _3424 = (_3312 < 2.5f) ? 256.0f : 65536.0f;\n                    }\n                    float best = 2.0f;\n                    int _3446;\n                    int _3452;\n                    for (int k = 0; k < 9; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3446 = 4;\n                        }\n                        else\n                        {\n                            if (k <= 4)\n                            {\n                                _3452 = k - 1;\n                            }\n                            else\n                            {\n                                _3452 = k;\n                            }\n                            _3446 = _3452;\n                        }\n                        float4 _3481 = fa_screen_tex.Load(int3(clamp(_3420 + int2((_3446 % 3) - 1, (_3446 / 3) - 1), int2(0, 0), _3419), 0));\n                        bool _3484 = _3481.w > 0.5f;\n                        bool _3494;\n                        if (_3484)\n                        {\n                            _3494 = abs(_3325 - _3481.x) <= _3331;\n                        }\n                        else\n                        {\n                            _3494 = _3484;\n                        }\n                        if (_3494)\n                        {\n                            best = min(best, mod(floor(_3481.z / _3424), 256.0f) * 0.0039215688593685626983642578125f);\n                            if (k == 0)\n                            {\n                                break;\n                            }\n                        }\n                    }\n                    if (best <= 1.0f)\n                    {\n                        float _3521;\n                        if (_423_fa_ct_b.z > 0.5f)\n                        {\n                            int param_1 = li;\n                            float3 param_2 = lpos;\n                            float3 param_3 = world;\n                            float3 param_4 = n;\n                            float3 param_5 = l;\n                            _3521 = min(best, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                        }\n                        else\n                        {\n                            _3521 = best;\n                        }\n                        return _3521;\n                    }\n                }\n            }\n            float _3544;\n            if (_423_fa_ct_b.z > 0.5f)\n            {\n                int param_6 = li;\n                float3 param_7 = lpos;\n                float3 param_8 = world;\n                float3 param_9 = n;\n                float3 param_10 = l;\n                _3544 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3544 = 1.0f;\n            }\n            return _3544;\n        }\n    }\n    int param_11 = li;\n    float3 param_12 = lpos;\n    float3 param_13 = world;\n    float3 param_14 = n;\n    float3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2065;\n    if (i == 0)\n    {\n        _2065 = _2075_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2081;\n        if (i == 1)\n        {\n            _2081 = _2075_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2089;\n            if (i == 2)\n            {\n                _2089 = _2075_fa_shadow_split.z;\n            }\n            else\n            {\n                _2089 = _2075_fa_shadow_split.w;\n            }\n            _2081 = _2089;\n        }\n        _2065 = _2081;\n    }\n    return _2065;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2368 = max(_2075_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2373 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2379 = sqrt(1.0f - (_2373 * _2373));\n    float _2387 = min(_2379 / max(_2373, 0.20000000298023223876953125f), 4.0f);\n    float _2392;\n    if (_2075_fa_shadow_bias.y > 0.0f)\n    {\n        _2392 = _2075_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2392 = 1.5f * _2075_fa_shadow_info[ci].x;\n    }\n    float4 _2417 = mul(float4(world + (n * (_2392 * _2379)), 1.0f), _2075_fa_shadow_mat[ci]);\n    float _2424 = _2417.x;\n    bool _2427 = _2424 < _2075_fa_shadow_rect[ci].x;\n    bool _2436;\n    if (!_2427)\n    {\n        _2436 = _2424 > _2075_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2436 = _2427;\n    }\n    bool _2445;\n    if (!_2436)\n    {\n        _2445 = _2417.y < _2075_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2445 = _2436;\n    }\n    bool _2454;\n    if (!_2445)\n    {\n        _2454 = _2417.y > _2075_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2454 = _2445;\n    }\n    bool _2461;\n    if (!_2454)\n    {\n        _2461 = _2417.z > 1.0f;\n    }\n    else\n    {\n        _2461 = _2454;\n    }\n    if (_2461)\n    {\n        return -1.0f;\n    }\n    float _2469;\n    if (_2075_fa_shadow_bias.x > 0.0f)\n    {\n        _2469 = _2075_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2469 = 1.5f * _2075_fa_shadow_info[ci].x;\n    }\n    float2 param = _2417.xy;\n    float4 param_1 = _2075_fa_shadow_rect[ci];\n    float param_2 = _2417.z - ((_2469 * (1.0f + (0.5f * _2387))) / _2368);\n    float param_3 = _2075_fa_shadow_info[ci].x;\n    float param_4 = _2368;\n    float param_5 = _2368 * 0.25f;\n    float param_6 = ((_2075_fa_shadow_info[ci].x * min(_2387, 3.0f)) * 0.5f) / _2368;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2075_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2075_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_423_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2847 = int(_2075_fa_shadow_cfg.x + 0.5f);\n    if (_2847 < 1)\n    {\n        return 1.0f;\n    }\n    float _2862 = dot(world - _2075_fa_shadow_eye.xyz, _2075_fa_shadow_fwd.xyz);\n    int param = _2847 - 1;\n    if (_2862 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2874 = _2847 > 1;\n    bool _2881;\n    if (_2874)\n    {\n        _2881 = _2862 > _2075_fa_shadow_split.x;\n    }\n    else\n    {\n        _2881 = _2874;\n    }\n    if (_2881)\n    {\n        ci = 1;\n    }\n    bool _2885 = _2847 > 2;\n    bool _2892;\n    if (_2885)\n    {\n        _2892 = _2862 > _2075_fa_shadow_split.y;\n    }\n    else\n    {\n        _2892 = _2885;\n    }\n    if (_2892)\n    {\n        ci = 2;\n    }\n    bool _2896 = _2847 > 3;\n    bool _2903;\n    if (_2896)\n    {\n        _2903 = _2862 > _2075_fa_shadow_split.z;\n    }\n    else\n    {\n        _2903 = _2896;\n    }\n    if (_2903)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _2914 = min(_2847, 4);\n    float _2955;\n    for (int c = ci; c < _2914; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2934 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _2934;\n            break;\n        }\n        if (_2934 < 0.0f)\n        {\n            continue;\n        }\n        s = _2934;\n        ci = c;\n        if (_2075_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2955 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2955 = _2075_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _2974 = _2075_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2955, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_2862 - (fa_shadow_split_at(param_7) - _2974)) / _2974, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3006;\n        if ((ci + 1) < _2847)\n        {\n            _3006 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3006 = 1.0f;\n        }\n        s = lerp(s, _3006, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    bool _3111 = _423_fa_ct_b.y > 0.5f;\n    bool _3117;\n    if (_3111)\n    {\n        _3117 = _423_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3117 = _3111;\n    }\n    if (_3117)\n    {\n        float _3131 = dot(_423_fa_ct_fwd.xyz, fa_world_pos) + _423_fa_ct_fwd.w;\n        float4 _3139 = float4(fa_world_pos, 1.0f);\n        float _3145 = dot(_423_fa_ct_vpw, _3139);\n        if (_3145 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _3164 = float2(dot(_423_fa_ct_vpx, _3139), dot(_423_fa_ct_vpy, _3139)) / _3145.xx;\n            float _3169 = (_3164.x * 0.5f) + 0.5f;\n            float _3173;\n            if (_423_fa_ct_a.y > 0.5f)\n            {\n                _3173 = (_3164.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _3173 = 0.5f - (_3164.y * 0.5f);\n            }\n            bool _3189 = _3169 >= 0.0f;\n            bool _3195;\n            if (_3189)\n            {\n                _3195 = _3169 < 1.0f;\n            }\n            else\n            {\n                _3195 = _3189;\n            }\n            bool _3201;\n            if (_3195)\n            {\n                _3201 = _3173 >= 0.0f;\n            }\n            else\n            {\n                _3201 = _3195;\n            }\n            bool _3207;\n            if (_3201)\n            {\n                _3207 = _3173 < 1.0f;\n            }\n            else\n            {\n                _3207 = _3201;\n            }\n            if (_3207)\n            {\n                float4 _3233 = fa_screen_tex.Load(int3(clamp(int2(float2(_3169, _3173) * _423_fa_ct_a.zw), int2(0, 0), int2(_423_fa_ct_a.zw) - int2(1, 1)), 0));\n                bool _3236 = _3233.w > 0.5f;\n                bool _3252;\n                if (_3236)\n                {\n                    _3252 = abs(_3131 - _3233.x) <= (((0.00200000009499490261077880859375f * _3131) + 0.00999999977648258209228515625f) + fa_rt_slope);\n                }\n                else\n                {\n                    _3252 = _3236;\n                }\n                if (_3252)\n                {\n                    float _3258;\n                    if (_423_fa_ct_b.z > 0.5f)\n                    {\n                        float3 param = fa_world_pos;\n                        float3 param_1 = n;\n                        float3 param_2 = l;\n                        _3258 = min(_3233.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3258 = _3233.y;\n                    }\n                    return _3258;\n                }\n            }\n        }\n    }\n    float3 param_3 = fa_world_pos;\n    float3 param_4 = n;\n    float3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3914 = _423_fa_ct_a.x < 0.5f;\n    bool _3921;\n    if (!_3914)\n    {\n        _3921 = _2075_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3921 = _3914;\n    }\n    if (_3921)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2075_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3934 = fa_light_texel(param);\n    float _3935 = _3934.y;\n    float len = _3935;\n    if (_3935 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3947 = length(world - _423_fa_camera_pos.xyz);\n    float _3956 = 1.0f - smoothstep(0.5f * _423_fa_ct_b.x, _423_fa_ct_b.x, _3947);\n    if (_3956 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3962 = len;\n    float _3965 = min(_3962, 0.89999997615814208984375f * dist);\n    len = _3965;\n    float _3971 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3947);\n    float _3976 = _3971 + (0.5f * _3965);\n    float3 _3982 = world + (gn * _3971);\n    float _3984 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4046;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4000 = (float(k) + _3984) * 0.083333335816860198974609375f;\n        float3 _4008 = _3982 + (l * (_4000 * len));\n        float4 _4014 = float4(_4008, 1.0f);\n        float _4019 = dot(_423_fa_ct_vpw, _4014);\n        if (_4019 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4037 = float2(dot(_423_fa_ct_vpx, _4014), dot(_423_fa_ct_vpy, _4014)) / _4019.xx;\n        float _4041 = _4037.x * 0.5f;\n        float _4042 = _4041 + 0.5f;\n        if (_423_fa_ct_a.y > 0.5f)\n        {\n            _4046 = (_4037.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4046 = 0.5f - (_4037.y * 0.5f);\n        }\n        bool _4062 = _4042 < 0.0f;\n        bool _4069;\n        if (!_4062)\n        {\n            _4069 = _4042 >= 1.0f;\n        }\n        else\n        {\n            _4069 = _4062;\n        }\n        bool _4076;\n        if (!_4069)\n        {\n            _4076 = _4046 < 0.0f;\n        }\n        else\n        {\n            _4076 = _4069;\n        }\n        bool _4083;\n        if (!_4076)\n        {\n            _4083 = _4046 >= 1.0f;\n        }\n        else\n        {\n            _4083 = _4076;\n        }\n        if (_4083)\n        {\n            break;\n        }\n        float4 _4107 = fa_screen_tex.Load(int3(clamp(int2(float2(_4042, _4046) * _423_fa_ct_a.zw), int2(0, 0), int2(_423_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_4107.w < 0.5f)\n        {\n            continue;\n        }\n        float _4125 = (dot(_423_fa_ct_fwd.xyz, _4008) + _423_fa_ct_fwd.w) - _4107.x;\n        if ((_4125 > _3971) && (_4125 < _3976))\n        {\n            occ = max(occ, (1.0f - (_4000 * _4000)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4042, 0.5f - _4041), min(_4046, 1.0f - _4046))));\n        }\n    }\n    return 1.0f - (occ * _3956);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4257 = fa_baked_keep(param);\n    if (_4257 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _6172 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6172;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4283 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6174 = _4283.color;\n    float _6175 = _4283.attenuation;\n    float _6176 = _4283.shadow;\n    bool _4286 = _4283.type == 0;\n    if (_4286 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4283.direction;\n        float _4297 = fa_shadow_factor(param_5, param_6);\n        _6176 = _4297;\n        _6174 *= _4297;\n    }\n    else\n    {\n        bool _4308 = _4283.type != 0;\n        bool _4314;\n        if (_4308)\n        {\n            _4314 = _6175 > 0.0f;\n        }\n        else\n        {\n            _4314 = _4308;\n        }\n        if (_4314)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4283.direction;\n            float _4333 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6176 = _4333;\n            _6174 *= _4333;\n        }\n    }\n    bool _4343 = _423_fa_ct_a.x > 0.5f;\n    bool _4349;\n    if (_4343)\n    {\n        _4349 = _6175 > 0.0f;\n    }\n    else\n    {\n        _4349 = _4343;\n    }\n    if (_4349)\n    {\n        float _4356;\n        if (_4286)\n        {\n            _4356 = 1000000000.0f;\n        }\n        else\n        {\n            _4356 = _4283._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4283.direction;\n        float param_18 = _4356;\n        float _4374 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6176 *= _4374;\n        _6174 *= _4374;\n    }\n    float _4387 = _6175;\n    float _4388 = _4387 * _4257;\n    _6175 = _4388;\n    float3 _4392 = _6174;\n    float3 _4393 = _4392 * _4257;\n    _6174 = _4393;\n    LightSample _6191 = { _4283.direction, _4393, _4388, _6176, _4283._distance, _4283.type };\n    return _6191;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _4407;\n    if (dot(s.normal, l.direction) > 0.5f)\n    {\n        _4407 = 1.0f;\n    }\n    else\n    {\n        _4407 = _4413_dark;\n    }\n    return (s.albedo * l.color) * _4407;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2075_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3034 = int(_2075_fa_shadow_cfg.x + 0.5f);\n    float _3044 = dot(world - _2075_fa_shadow_eye.xyz, _2075_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3049 = _3034 > 0;\n    bool _3058;\n    if (_3049)\n    {\n        int param = _3034 - 1;\n        _3058 = _3044 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3058 = _3049;\n    }\n    if (_3058)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3064 = _3034 > 1;\n        bool _3071;\n        if (_3064)\n        {\n            _3071 = _3044 > _2075_fa_shadow_split.x;\n        }\n        else\n        {\n            _3071 = _3064;\n        }\n        if (_3071)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3077 = _3034 > 2;\n        bool _3084;\n        if (_3077)\n        {\n            _3084 = _3044 > _2075_fa_shadow_split.y;\n        }\n        else\n        {\n            _3084 = _3077;\n        }\n        if (_3084)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3090 = _3034 > 3;\n        bool _3097;\n        if (_3090)\n        {\n            _3097 = _3044 > _2075_fa_shadow_split.z;\n        }\n        else\n        {\n            _3097 = _3090;\n        }\n        if (_3097)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_rt_slope = 0.0f;\n    fa_inst_load();\n    float3 _5995 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5995 = -_5995;\n    }\n    float3 _5569 = normalize(_423_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _6008 = { fa_world_pos, _5995, fa_world_tangent, fa_uv, fa_vertex_color, _5569, gl_FrontFacing };\n    SurfaceInput param_1 = _6008;\n    Surface _5577 = fa_standard_surface(param_1);\n    float3 _6026 = _5577.albedo;\n    float _6027 = _5577.alpha;\n    float3 _6028 = _5577.normal;\n    float _6029 = _5577.metallic;\n    float _6030 = _5577.roughness;\n    float _6031 = _5577.occlusion;\n    float3 _6032 = _5577.emission;\n    float _6033 = _5577.clearcoat;\n    float _6034 = _5577.clearcoat_roughness;\n    float3 _6035 = _5577.sheen_color;\n    float _6036 = _5577.sheen_roughness;\n    float _6037 = _5577.anisotropy;\n    float _6038 = _5577.anisotropy_rotation;\n    float _6039 = _5577.specular;\n    float _6040 = _5577.ior;\n    float3 _6041 = _5577.specular_color;\n    float _6042 = _5577.transmission;\n    float _6043 = _5577.thickness;\n    float3 _6044 = _5577.attenuation_color;\n    float _6045 = _5577.attenuation_distance;\n    SurfaceInput _6016 = { fa_world_pos, _5995, fa_world_tangent, fa_uv, fa_vertex_color, _5569, gl_FrontFacing };\n    SurfaceInput param_2 = _6016;\n    Surface param_3 = _5577;\n    surface(param_2, param_3);\n    _6026 = param_3.albedo;\n    _6027 = param_3.alpha;\n    _6028 = param_3.normal;\n    _6029 = param_3.metallic;\n    _6030 = param_3.roughness;\n    _6031 = param_3.occlusion;\n    _6032 = param_3.emission;\n    _6033 = param_3.clearcoat;\n    _6034 = param_3.clearcoat_roughness;\n    _6035 = param_3.sheen_color;\n    _6036 = param_3.sheen_roughness;\n    _6037 = param_3.anisotropy;\n    _6038 = param_3.anisotropy_rotation;\n    _6039 = param_3.specular;\n    _6040 = param_3.ior;\n    _6041 = param_3.specular_color;\n    _6042 = param_3.transmission;\n    _6043 = param_3.thickness;\n    _6044 = param_3.attenuation_color;\n    _6045 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5995;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6026 = param_6;\n    _6028 = param_7;\n    float3 result;\n    if (_423_fa_emissive.w > 0.5f)\n    {\n        result = _6026;\n    }\n    else\n    {\n        float3 _5616 = _6028;\n        float3 _5617 = normalize(_5616);\n        _6028 = _5617;\n        float3 param_8 = _5617;\n        float3 lit = (fa_indirect_diffuse(param_8) * _6026) * _6031;\n        int _5636 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5636; ln++)\n        {\n            int param_9 = ln;\n            int _5649 = fa_cl_light(param_9);\n            int param_10 = _5649;\n            if (fa_baked_keep(param_10) <= 0.0f)\n            {\n                continue;\n            }\n            int param_11 = _5649;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _5995;\n            LightSample _5665 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput _6024 = { fa_world_pos, _5995, fa_world_tangent, fa_uv, fa_vertex_color, _5569, gl_FrontFacing };\n            SurfaceInput param_14 = _6024;\n            Surface _6127 = { _6026, _6027, _6028, _6029, _6030, _6031, _6032, _6033, _6034, _6035, _6036, _6037, _6038, _6039, _6040, _6041, _6042, _6043, _6044, _6045 };\n            Surface param_15 = _6127;\n            LightSample param_16 = _5665;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _5680 = result;\n    float3 _5681 = _5680 + _6032;\n    result = _5681;\n    float3 param_17 = _5681;\n    float3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _5690 = _423_fa_fog.w > 0.0f;\n    bool _5697;\n    if (!_5690)\n    {\n        _5697 = _423_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5697 = _5690;\n    }\n    if (_5697)\n    {\n        float3 _5706 = fa_world_pos - _423_fa_camera_pos.xyz;\n        float _5712 = dot(_5706, _423_fa_fog_c.xyz);\n        bool _5716 = _423_fa_fog_c.w > 0.5f;\n        float _5717;\n        if (_5716)\n        {\n            _5717 = _5712;\n        }\n        else\n        {\n            _5717 = length(_5706);\n        }\n        float _5729 = _5717 - _423_fa_fog_b.x;\n        if (_5729 > 0.0f)\n        {\n            float _5738 = _423_fa_fog.w * _5729;\n            float tau = _5738 * _5738;\n            if (_423_fa_fog_b.y > 0.0f)\n            {\n                float _5754;\n                if (_5716)\n                {\n                    _5754 = fa_world_pos.y - (_423_fa_fog_c.y * _5712);\n                }\n                else\n                {\n                    _5754 = _423_fa_camera_pos.y;\n                }\n                float _5775 = lerp(_5754, fa_world_pos.y, clamp(_423_fa_fog_b.x / _5717, 0.0f, 1.0f));\n                float _5779 = fa_world_pos.y - _5775;\n                float _5784 = _5775 - _423_fa_fog_b.z;\n                float _5789 = fa_world_pos.y - _423_fa_fog_b.z;\n                bool _5792 = _5784 <= 0.0f;\n                bool _5793 = !_5792;\n                bool _5799;\n                if (_5793)\n                {\n                    _5799 = _423_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5799 = _5792;\n                }\n                float _5800;\n                if (_5799)\n                {\n                    _5800 = _423_fa_fog_b.y;\n                }\n                else\n                {\n                    _5800 = _423_fa_fog_b.y * exp(-min(_423_fa_fog_b.w * _5784, 80.0f));\n                }\n                bool _5827;\n                if (_5793)\n                {\n                    _5827 = _423_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5827 = _5792;\n                }\n                float _5828;\n                if (_5827)\n                {\n                    _5828 = _423_fa_fog_b.y * _5784;\n                }\n                else\n                {\n                    _5828 = (_423_fa_fog_b.y * (1.0f - exp(-min(_423_fa_fog_b.w * _5784, 80.0f)))) / _423_fa_fog_b.w;\n                }\n                bool _5853 = _5789 <= 0.0f;\n                bool _5860;\n                if (!_5853)\n                {\n                    _5860 = _423_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5860 = _5853;\n                }\n                float _5861;\n                if (_5860)\n                {\n                    _5861 = _423_fa_fog_b.y * _5789;\n                }\n                else\n                {\n                    _5861 = (_423_fa_fog_b.y * (1.0f - exp(-min(_423_fa_fog_b.w * _5789, 80.0f)))) / _423_fa_fog_b.w;\n                }\n                float _5888;\n                if (abs(_5779) < 0.001000000047497451305389404296875f)\n                {\n                    _5888 = _5800;\n                }\n                else\n                {\n                    _5888 = (_5861 - _5828) / _5779;\n                }\n                tau += (_5729 * max(_5888, 0.0f));\n            }\n            result = lerp(result, _423_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _6027);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_423",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2075",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_4413",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _423_fa_camera_pos : packoffset(c0);\n    float4 _423_fa_ambient : packoffset(c1);\n    float4 _423_fa_base_color : packoffset(c2);\n    float4 _423_fa_emissive : packoffset(c3);\n    float4 _423_fa_model_emissive : packoffset(c4);\n    float4 _423_fa_pbr : packoffset(c5);\n    float4 _423_fa_maps : packoffset(c6);\n    float4 _423_fa_fog : packoffset(c7);\n    float4 _423_fa_fog_b : packoffset(c8);\n    float4 _423_fa_fog_c : packoffset(c9);\n    float4 _423_fa_counts : packoffset(c10);\n    float4 _423_fa_env_sky : packoffset(c11);\n    float4 _423_fa_env_horizon : packoffset(c12);\n    float4 _423_fa_time : packoffset(c13);\n    float4 _423_fa_cl_vpx : packoffset(c14);\n    float4 _423_fa_cl_vpy : packoffset(c15);\n    float4 _423_fa_cl_vpw : packoffset(c16);\n    float4 _423_fa_cl_fwd : packoffset(c17);\n    float4 _423_fa_cl_grid : packoffset(c18);\n    float4 _423_fa_cl_info : packoffset(c19);\n    float4 _423_fa_layers_a : packoffset(c20);\n    float4 _423_fa_layers_b : packoffset(c21);\n    float4 _423_fa_layers_c : packoffset(c22);\n    float4 _423_fa_layers_d : packoffset(c23);\n    float4 _423_fa_ct_a : packoffset(c24);\n    float4 _423_fa_ct_b : packoffset(c25);\n    float4 _423_fa_ct_vpx : packoffset(c26);\n    float4 _423_fa_ct_vpy : packoffset(c27);\n    float4 _423_fa_ct_vpw : packoffset(c28);\n    float4 _423_fa_ct_fwd : packoffset(c29);\n    float4 _423_fa_tr_a : packoffset(c30);\n    float4 _423_fa_tr_b : packoffset(c31);\n    float4 _423_fa_probe_sh[9] : packoffset(c32);\n    float4 _423_fa_atlas : packoffset(c41);\n    float4 _423_fa_rpa_tile : packoffset(c42);\n    float4 _423_fa_rpa_pos : packoffset(c43);\n    float4 _423_fa_rpa_bx : packoffset(c44);\n    float4 _423_fa_rpa_by : packoffset(c45);\n    float4 _423_fa_rpa_bz : packoffset(c46);\n    float4 _423_fa_rpb_tile : packoffset(c47);\n    float4 _423_fa_rpb_pos : packoffset(c48);\n    float4 _423_fa_rpb_bx : packoffset(c49);\n    float4 _423_fa_rpb_by : packoffset(c50);\n    float4 _423_fa_rpb_bz : packoffset(c51);\n    float4 _423_fa_gi : packoffset(c52);\n    float4 _423_fa_gi_px : packoffset(c53);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2075_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2075_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2075_fa_shadow_info[4] : packoffset(c20);\n    float4 _2075_fa_shadow_split : packoffset(c24);\n    float4 _2075_fa_shadow_cfg : packoffset(c25);\n    float4 _2075_fa_shadow_bias : packoffset(c26);\n    float4 _2075_fa_shadow_eye : packoffset(c27);\n    float4 _2075_fa_shadow_fwd : packoffset(c28);\n    float4 _2075_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _4413_dark : packoffset(c0);\n    float _4413_fa_pad0 : packoffset(c0.y);\n    float _4413_fa_pad1 : packoffset(c0.z);\n    float _4413_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float fa_rt_slope;\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1351 = _423_fa_cl_info.x < 0.0f;\n    bool _1358;\n    if (!_1351)\n    {\n        _1358 = _423_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1358 = _1351;\n    }\n    bool _1366;\n    if (!_1358)\n    {\n        _1366 = _423_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1366 = _1358;\n    }\n    bool _1373;\n    if (!_1366)\n    {\n        _1373 = _423_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1373 = _1366;\n    }\n    bool _1380;\n    if (!_1373)\n    {\n        _1380 = _423_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1380 = _1373;\n    }\n    if (_1380)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1390 = float4(world_pos, 1.0f);\n    float _1396 = dot(_423_fa_cl_vpw, _1390);\n    if (!(_1396 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1418 = float2(dot(_423_fa_cl_vpx, _1390), dot(_423_fa_cl_vpy, _1390)) / _1396.xx;\n    int _1422 = int(_423_fa_cl_grid.x);\n    int _1426 = int(_423_fa_cl_grid.y);\n    int param = (int(_423_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_423_fa_cl_fwd.xyz, world_pos) + _423_fa_cl_fwd.w, _423_fa_cl_grid.w) / _423_fa_cl_grid.w) * _423_fa_cl_grid.z)), 0, int(_423_fa_cl_info.y) - 1) * _1426) + clamp(int(floor(((_1418.y * 0.5f) + 0.5f) * _423_fa_cl_grid.y)), 0, _1426 - 1)) * _1422)) + clamp(int(floor(((_1418.x * 0.5f) + 0.5f) * _423_fa_cl_grid.x)), 0, _1422 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1502 = fa_cluster_texel(param);\n    return int2(int(_1502.x), int(_1502.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    float _4202 = dot(_423_fa_ct_fwd.xyz, world_pos) + _423_fa_ct_fwd.w;\n    float _4205 = fwidth(_4202);\n    bool _4208 = _423_fa_ct_b.y > 0.5f;\n    bool _4215;\n    if (!_4208)\n    {\n        _4215 = _423_fa_ct_b.w > 0.5f;\n    }\n    else\n    {\n        _4215 = _4208;\n    }\n    if (_4215)\n    {\n        fa_rt_slope = min(1.5f * _4205, 0.100000001490116119384765625f * _4202);\n    }\n    fa_cl_ndir = int(_423_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4231 = fa_cluster_lookup(param);\n    fa_cl_slot = _4231.x;\n    fa_cl_local = _4231.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4462 = fa_linear_to_srgb(param);\n        c = _4462;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4470 = fa_srgb_to_linear(param_1);\n            c = _4470;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _306;\n    if (i.front_facing)\n    {\n        _306 = i.world_normal;\n    }\n    else\n    {\n        _306 = -i.world_normal;\n    }\n    float3 _330 = normalize(i.world_tangent.xyz - (_306 * dot(_306, i.world_tangent.xyz)));\n    float3 _357 = normalize(((_330 * m.x) + ((cross(_306, _330) * i.world_tangent.w) * m.y)) + (_306 * m.z));\n    float3 _360;\n    if (i.front_facing)\n    {\n        _360 = _357;\n    }\n    else\n    {\n        _360 = -_357;\n    }\n    return _360;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _423_fa_env_horizon.w);\n    float param = _423_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4502 = fa_tex_fix(param_2, param_3);\n    float4 _6378 = base_t;\n    _6378.x = _4502.x;\n    _6378.y = _4502.y;\n    _6378.z = _4502.z;\n    base_t = _6378;\n    float4 _4516 = (_6378 * _423_fa_base_color) * i.vertex_color;\n    float3 _6194 = i.world_normal;\n    if (_423_fa_maps.z > 0.5f)\n    {\n        float param_4 = _423_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _423_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4550 = fa_tex_fix(param_6, param_7);\n        float3 _4553 = (_4550 * 2.0f) - 1.0f.xxx;\n        float2 _4558 = _4553.xy * _423_fa_maps.x;\n        float3 _6386 = _4553;\n        _6386.x = _4558.x;\n        _6386.y = _4558.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6386;\n        _6194 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _423_fa_env_horizon.w);\n    float param_10 = _423_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4588 = fa_tex_fix(param_12, param_13);\n    float4 _6389 = mrt;\n    _6389.x = _4588.x;\n    _6389.y = _4588.y;\n    _6389.z = _4588.z;\n    mrt = _6389;\n    float4 _4618 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _423_fa_env_horizon.w);\n    float param_14 = _423_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4618.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4629 = fa_tex_fix(param_16, param_17);\n    float param_18 = _423_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _423_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4661 = fa_tex_fix(param_20, param_21);\n    float _6199 = _423_fa_layers_a.x;\n    float _6200 = _423_fa_layers_a.y;\n    float _6203 = _423_fa_layers_a.z;\n    float _6202 = _423_fa_layers_b.w;\n    float _6205 = _423_fa_layers_c.x;\n    if (_423_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_423_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6199 *= _4629.y;\n            _6200 *= _4629.z;\n            _6202 *= _4618.w;\n        }\n        if (_423_fa_layers_c.z > 1.5f)\n        {\n            _6203 *= mrt.x;\n            _6205 *= mrt.w;\n        }\n    }\n    Surface _6232 = { _4516.xyz, _4516.w, _6194, clamp(_423_fa_pbr.x * _4588.z, 0.0f, 1.0f), clamp(_423_fa_pbr.y * _4588.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_423_fa_maps.y * (_4629.x - 1.0f)), _423_fa_emissive.xyz + (_423_fa_model_emissive.xyz * _4661), _6199, _6200, _423_fa_layers_b.xyz, _6202, _6203, _423_fa_layers_a.w, _6205, _423_fa_layers_c.y, _423_fa_layers_d.xyz, _423_fa_tr_a.x, _423_fa_tr_a.y, _423_fa_tr_b.xyz, _423_fa_tr_a.z };\n    return _6232;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1582 = rect.zw - rect.xy;\n    float2 _1586 = _1582 * atlas;\n    float2 _1590 = ddx * _1586;\n    float2 _1594 = ddy * _1586;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1582), clamp(0.5f * log2(max(max(dot(_1590, _1590), dot(_1594, _1594)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1627 = _423_fa_counts.y < 0.5f;\n    bool _1634;\n    if (!_1627)\n    {\n        _1634 = _423_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1634 = _1627;\n    }\n    if (_1634)\n    {\n        return;\n    }\n    float3 _1640 = ddx(world_pos);\n    float3 _1643 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1647 = fa_cluster_texel(param);\n    int _1651 = int(_1647.w);\n    if (_1651 < 1)\n    {\n        return;\n    }\n    int _1661 = int(_423_fa_counts.y + 0.5f);\n    int param_1 = _1661;\n    float4 _1665 = fa_light_texel(param_1);\n    float2 _1668 = _1665.yz;\n    int _1672 = int(_1665.w);\n    int param_2 = _1661 + 1;\n    float4 _1677 = fa_light_texel(param_2);\n    float _1678 = _1677.x;\n    int _1684 = int(_423_fa_counts.w + 0.5f) - 1;\n    int _1688 = int(_1647.z);\n    float3 _1953;\n    for (int k = 0; k < _1651; k++)\n    {\n        int _1701 = _1688 + k;\n        int param_3 = _1672 + (_1701 >> 2);\n        int _1718 = (_1661 + 2) + (int(fa_light_texel(param_3)[_1701 & 3]) * 7);\n        int param_4 = _1718 + 6;\n        float4 _1723 = fa_light_texel(param_4);\n        if (((int(_1723.w + 0.5f) >> _1684) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1718;\n        float4 _1738 = fa_light_texel(param_5);\n        int param_6 = _1718 + 1;\n        float4 _1743 = fa_light_texel(param_6);\n        int param_7 = _1718 + 2;\n        float4 _1748 = fa_light_texel(param_7);\n        float3 _1751 = _1738.xyz;\n        float _1756 = dot(_1751, world_pos) + _1738.w;\n        float3 _1758 = _1743.xyz;\n        float _1763 = dot(_1758, world_pos) + _1743.w;\n        float3 _1765 = _1748.xyz;\n        float _1770 = dot(_1765, world_pos) + _1748.w;\n        bool _1775 = abs(_1756) > 0.5f;\n        bool _1783;\n        if (!_1775)\n        {\n            _1783 = abs(_1763) > 0.5f;\n        }\n        else\n        {\n            _1783 = _1775;\n        }\n        bool _1791;\n        if (!_1783)\n        {\n            _1791 = abs(_1770) > 0.5f;\n        }\n        else\n        {\n            _1791 = _1783;\n        }\n        if (_1791)\n        {\n            continue;\n        }\n        float _1806 = clamp(dot(geo_normal, normalize(_1765)) * _1723.z, 0.0f, 1.0f);\n        if (_1806 <= 0.0f)\n        {\n            continue;\n        }\n        float _1826 = (clamp((0.5f - abs(_1770)) * 10.0f, 0.0f, 1.0f) * _1806) * _1723.x;\n        float2 _1834 = float2(_1756 + 0.5f, 0.5f - _1763);\n        float2 _1844 = float2(dot(_1751, _1640), dot(_1758, _1640));\n        float2 _1854 = float2(dot(_1751, _1643), dot(_1758, _1643));\n        int param_8 = _1718 + 5;\n        float4 _1859 = fa_light_texel(param_8);\n        int param_9 = _1718 + 3;\n        float4 _1864 = fa_light_texel(param_9);\n        int param_10 = _1718 + 4;\n        float4 _1869 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1859.xyz;\n        bool _1879 = _1864.z > _1864.x;\n        if (_1879)\n        {\n            float4 param_11 = _1864;\n            float2 param_12 = _1834;\n            float2 param_13 = _1668;\n            float2 param_14 = _1844;\n            float2 param_15 = _1854;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1678 > 0.5f) && (_1678 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1905 = fa_dc_to_linear(param_16);\n                float4 _6282 = tx;\n                _6282.x = _1905.x;\n                _6282.y = _1905.y;\n                _6282.z = _1905.z;\n                tx = _6282;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1826 * tex_a) * _1859.w, 0.0f, 1.0f).xxx);\n        if (_1869.z > _1869.x)\n        {\n            float4 param_17 = _1869;\n            float2 param_18 = _1834;\n            float2 param_19 = _1668;\n            float2 param_20 = _1844;\n            float2 param_21 = _1854;\n            float4 _1949 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1678 > 1.5f)\n            {\n                float3 param_22 = _1949.xyz;\n                float3 _1959 = fa_dc_to_srgb(param_22);\n                _1953 = _1959;\n            }\n            else\n            {\n                _1953 = _1949.xyz;\n            }\n            float3 _1968 = (_1953 * 2.0f) - 1.0f.xxx;\n            float2 _1973 = _1968.xy * _1723.y;\n            float3 _1995 = (normalize(_1751) * _1973.x) + (normalize(_1758) * _1973.y);\n            float3 _1998 = normalize(normal);\n            normal = normalize(lerp(_1998, normalize((_1998 * max(_1968.z, 0.0500000007450580596923828125f)) + (_1995 - (_1998 * dot(_1998, _1995)))), clamp(_1826 * (_1879 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3725_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3725_dummy_parameter)));\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_423_fa_atlas.y > 0.5f)\n    {\n        v = ((v * 255.0f) - 128.0f.xxx) * 0.03149606287479400634765625f;\n    }\n    return v;\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3666 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3666;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3775 = (1.0f - _423_fa_rpa_tile.w) - _423_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3781 = _423_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3775 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3781)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _423_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3775;\n            }\n        }\n        else\n        {\n            amb = _423_fa_ambient.xyz * _3775;\n        }\n    }\n    bool _3832 = _423_fa_rpa_tile.w > 0.0f;\n    if (_3832)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _423_fa_rpa_tile.xy;\n            float param_4 = _423_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _423_fa_rpa_tile.w);\n        }\n    }\n    bool _3863 = _423_fa_rpb_tile.w > 0.0f;\n    if (_3863)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _423_fa_rpb_tile.xy;\n            float param_7 = _423_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _423_fa_rpb_tile.w);\n        }\n    }\n    if ((_3781 || _3832) || _3863)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3686 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3689 = _3686.x;\n    float _3691 = _3686.z;\n    float2 e = float2(_3689, _3691);\n    if (_3686.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3691)) * ((_3689 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3689)) * ((_3691 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _4775 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _4780 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _4785 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _4790 = fa_light_texel(param_3);\n    bool _4793 = _4790.z < 0.5f;\n    bool _4801;\n    if (!_4793)\n    {\n        _4801 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _4801 = _4793;\n    }\n    if (_4801)\n    {\n        return 0.0f.xxx;\n    }\n    float _4808 = max(_4775.w, 9.9999997473787516355514526367188e-05f);\n    float3 _4811 = _4780.xyz;\n    float3 _4815 = _4775.xyz;\n    float3 _4819 = (fa_world_pos - _4815) / _4808.xxx;\n    float3 _4828 = min(_4819 + 0.5f.xxx, (_4811 - 0.5f.xxx) - _4819);\n    float _4837 = min(_4828.x, min(_4828.y, _4828.z));\n    if (!(_4837 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4852 = _4811 - 1.0f.xxx;\n    float3 _4853 = clamp(_4819, 0.0f.xxx, _4852);\n    float3 _4861 = min(floor(_4853), max(_4811 - 2.0f.xxx, 0.0f.xxx));\n    float3 _4865 = _4853 - _4861;\n    float3 _4877 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _4808));\n    int _4882 = int(_4785.y + 0.5f);\n    float _4887 = 0.3257350027561187744140625f * n.y;\n    float _4891 = 0.3257350027561187744140625f * n.z;\n    float _4895 = 0.3257350027561187744140625f * n.x;\n    float _4902 = (0.2731371223926544189453125f * n.x) * n.y;\n    float _4909 = (0.2731371223926544189453125f * n.y) * n.z;\n    float _4918 = 0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f);\n    float _4925 = (0.2731371223926544189453125f * n.x) * n.z;\n    float _4938 = 0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y));\n    float3 acc = 0.0f.xxx;\n    float wsum = 0.0f;\n    int _4945 = 8 + int(_4790.w);\n    float _4972;\n    float _4985;\n    float _4999;\n    for (int k = 0; k < _4945; k++)\n    {\n        float _4958 = float(k & 1);\n        float _4962 = float((k >> 1) & 1);\n        float _4966 = float((k >> 2) & 1);\n        if (_4958 > 0.5f)\n        {\n            _4972 = _4865.x;\n        }\n        else\n        {\n            _4972 = 1.0f - _4865.x;\n        }\n        if (_4962 > 0.5f)\n        {\n            _4985 = _4865.y;\n        }\n        else\n        {\n            _4985 = 1.0f - _4865.y;\n        }\n        if (_4966 > 0.5f)\n        {\n            _4999 = _4865.z;\n        }\n        else\n        {\n            _4999 = 1.0f - _4865.z;\n        }\n        float _5009 = (_4972 * _4985) * _4999;\n        if (!(_5009 > 0.0f))\n        {\n            continue;\n        }\n        float3 _5022 = min(_4861 + float3(_4958, _4962, _4966), _4852);\n        int _5042 = int(((_4785.x + _5022.x) + (_4780.x * (_5022.y + (_4780.y * _5022.z)))) + 0.5f);\n        float2 _5057 = float2(float(_5042 % _4882) * 10.0f, 1024.0f + (float(_5042 / _4882) * 11.0f));\n        float2 param_4 = _5057 + float2(9.5f, 10.5f);\n        float4 _5065 = fa_gi_fetch(param_4);\n        bool _5068 = _5065.y < 0.5f;\n        bool _5077;\n        if (!_5068)\n        {\n            _5077 = _5065.x > _4790.y;\n        }\n        else\n        {\n            _5077 = _5068;\n        }\n        if (_5077)\n        {\n            continue;\n        }\n        float3 _5089 = _4877 - (_4815 + (_5022 * _4808));\n        float _5092 = length(_5089);\n        float3 _5098 = _5089 / max(_5092, 9.9999997473787516355514526367188e-05f).xxx;\n        float _5108 = max(9.9999997473787516355514526367188e-05f, (dot(-_5098, n) + 1.0f) * 0.5f);\n        float w = _5009 * (_5108 * _5108);\n        float3 param_5 = _5098;\n        float2 param_6 = (_5057 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _5128 = fa_gi_fetch(param_6);\n        float _5135 = _5092 / max(_4785.z, 9.9999997473787516355514526367188e-05f);\n        float _5138 = _5128.x;\n        if (_5135 > _5138)\n        {\n            float _5151 = max(_5128.y - (_5138 * _5138), 0.0f);\n            float _5156 = _5135 - _5138;\n            float _5165 = _5151 / max(_5151 + (_5156 * _5156), 9.9999999600419720025001879548654e-13f);\n            w *= ((_5165 * _5165) * _5165);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        float2 param_7 = _5057 + float2(0.5f, 10.5f);\n        float2 param_8 = _5057 + float2(1.5f, 10.5f);\n        float2 param_9 = _5057 + float2(2.5f, 10.5f);\n        float2 param_10 = _5057 + float2(3.5f, 10.5f);\n        float2 param_11 = _5057 + float2(4.5f, 10.5f);\n        float2 param_12 = _5057 + float2(5.5f, 10.5f);\n        float2 param_13 = _5057 + float2(6.5f, 10.5f);\n        float2 param_14 = _5057 + float2(7.5f, 10.5f);\n        float2 param_15 = _5057 + float2(8.5f, 10.5f);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375f) + (fa_gi_fetch(param_8).xyz * _4887)) + (fa_gi_fetch(param_9).xyz * _4891)) + (fa_gi_fetch(param_10).xyz * _4895)) + (fa_gi_fetch(param_11).xyz * _4902)) + (fa_gi_fetch(param_12).xyz * _4909)) + (fa_gi_fetch(param_13).xyz * _4918)) + (fa_gi_fetch(param_14).xyz * _4925)) + (fa_gi_fetch(param_15).xyz * _4938)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_4837 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _5293;\n    if (_423_fa_gi.z > 0.5f)\n    {\n        _5293 = _4790.x;\n    }\n    else\n    {\n        _5293 = 1.0f;\n    }\n    return max(acc / wsum.xxx, 0.0f.xxx) * (_4785.w * _5293);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _5317 = normalize(_423_fa_camera_pos.xyz - fa_world_pos);\n    int _5322 = int(_423_fa_gi.x + 0.5f);\n    int _5327 = int(_423_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _5327) && (k < 8); k++)\n    {\n        int param = _5322 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _5317;\n        float3 _5352 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _5357 = param_3 * left;\n        acc += (_5352 * _5357);\n        left -= _5357;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    float3 gi = 0.0f.xxx;\n    float left = 1.0f;\n    if (_423_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _5386 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _5386;\n    }\n    if (left <= 0.0f)\n    {\n        return gi;\n    }\n    float3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_423_fa_gi_px.x > 0.5f)\n    {\n        float4 _5428 = float4(fa_world_pos, 1.0f);\n        float2 _5447 = float2(dot(_423_fa_ct_vpx, _5428), dot(_423_fa_ct_vpy, _5428)) / max(dot(_423_fa_ct_vpw, _5428), 9.9999997473787516355514526367188e-05f).xx;\n        float _5456;\n        if (_423_fa_ct_a.y > 0.5f)\n        {\n            _5456 = (_5447.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _5456 = 0.5f - (_5447.y * 0.5f);\n        }\n        return fa_lightmap.Load(int3(clamp(int2(float2((_5447.x * 0.5f) + 0.5f, _5456) * _423_fa_ct_a.zw), int2(0, 0), int2(_423_fa_ct_a.zw) - int2(1, 1)), 0)).xyz;\n    }\n    if (_423_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _423_fa_probe_sh[k].xyz;\n        }\n        float3 param = n;\n        float3 param_1[9] = c;\n        float3 param_2 = n;\n        return lerp(fa_ambient_light(param), fa_sh_eval(param_1, param_2), clamp(_423_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_423_fa_cl_info.x) + int(_423_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_423_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4172;\n    if (fa_lm.z > 0.5f)\n    {\n        _4172 = 0.0f;\n    }\n    else\n    {\n        _4172 = 1.0f - clamp(_423_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4183 = _4172 < 1.0f;\n    bool _4189;\n    if (_4183)\n    {\n        int param = li;\n        _4189 = fa_light_baked(param);\n    }\n    else\n    {\n        _4189 = _4183;\n    }\n    return _4189 ? _4172 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _601 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _614 = (c - (ru * hx)) - p;\n        float3 _620 = ru * (2.0f * hx);\n        float _626 = max(dot(_620, _620), 9.9999999392252902907785028219223e-09f);\n        float _630 = dot(_614, _620);\n        float t = clamp((-_630) / _626, 0.0f, 1.0f);\n        if (_601)\n        {\n            float _645 = dot(r, _620);\n            float _651 = _626 - (_645 * _645);\n            if (abs(_651) > (9.9999997473787516355514526367188e-06f * _626))\n            {\n                t = clamp(((dot(r, _614) * _645) - _630) / _651, 0.0f, 1.0f);\n            }\n        }\n        return (p + _614) + (_620 * t);\n    }\n    float3 q = p;\n    float _683 = dot(r, axis);\n    bool _691;\n    if (_601)\n    {\n        _691 = abs(_683) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _691 = _601;\n    }\n    if (_691)\n    {\n        float _701 = dot(c - p, axis) / _683;\n        if (_701 > 0.0f)\n        {\n            q = p + (r * _701);\n        }\n    }\n    float3 _714 = q - c;\n    float2 xy = float2(dot(_714, ru), dot(_714, uu));\n    if (shape > 0.5f)\n    {\n        float _729 = length(xy);\n        if (_729 > hx)\n        {\n            xy *= (hx / _729);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _482_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _482_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _521 = dot(d, right);\n    float _525 = dot(d, up);\n    float _536;\n    if (((_521 * _521) + (_525 * _525)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _536 = atan2(_525, _521) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _536 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_536 - floor(_536)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _372 = abs(d);\n    float _374 = _372.x;\n    float _376 = _372.y;\n    bool _377 = _374 >= _376;\n    bool _385;\n    if (_377)\n    {\n        _385 = _374 >= _372.z;\n    }\n    else\n    {\n        _385 = _377;\n    }\n    int _386;\n    if (_385)\n    {\n        _386 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _400;\n        if (_376 >= _372.z)\n        {\n            _400 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _400 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _386 = _400;\n    }\n    return _386;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _767 = fa_light_base(param);\n    bool _771 = _423_fa_ambient.w > 4.5f;\n    int param_1 = _767;\n    float4 _775 = fa_light_texel(param_1);\n    int param_2 = _767 + 1;\n    float4 _780 = fa_light_texel(param_2);\n    float _783 = _780.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _795 = _771 && (_783 > 2.5f);\n    fa_light_is_area = _795;\n    bool _797 = _783 < 0.5f;\n    float3 l;\n    if (_797)\n    {\n        l = normalize(_775.xyz);\n        if (_771)\n        {\n            int param_3 = _767 + 6;\n            float4 _811 = fa_light_texel(param_3);\n            if (_811.z > 0.5f)\n            {\n                int param_4 = _767 + 4;\n                float4 _821 = fa_light_texel(param_4);\n                int param_5 = _767 + 5;\n                float4 _826 = fa_light_texel(param_5);\n                float2 param_6 = _811.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _821.xyz) * _821.w, (-dot(world_pos, _826.xyz)) * _826.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _856 = _775.xyz;\n        float3 _858 = _856 - world_pos;\n        float3 to_light = _858;\n        float _861 = length(_858);\n        float reach = _861;\n        bool front = true;\n        if (_795)\n        {\n            int param_8 = _767 + 7;\n            reach = max(_861 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _767 + 4;\n            float4 _885 = fa_light_texel(param_9);\n            int param_10 = _767 + 5;\n            float4 _890 = fa_light_texel(param_10);\n            int param_11 = _767 + 6;\n            float4 _895 = fa_light_texel(param_11);\n            float _896 = _895.w;\n            int param_12 = _767 + 2;\n            float3 _903 = normalize(fa_light_texel(param_12).xyz);\n            bool _905 = _896 > 1.5f;\n            bool _913;\n            if (!_905)\n            {\n                _913 = dot(_903, to_light) < 0.0f;\n            }\n            else\n            {\n                _913 = _905;\n            }\n            front = _913;\n            float3 r = 0.0f.xxx;\n            float3 _922 = _423_fa_camera_pos.xyz - world_pos;\n            bool _926 = dot(n, n) > 0.5f;\n            bool _934;\n            if (_926)\n            {\n                _934 = dot(_922, _922) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _934 = _926;\n            }\n            if (_934)\n            {\n                r = reflect(-normalize(_922), normalize(n));\n            }\n            float3 param_13 = _856;\n            float3 param_14 = _903;\n            float3 param_15 = _885.xyz;\n            float3 param_16 = _890.xyz;\n            float param_17 = _885.w;\n            float param_18 = _890.w;\n            float param_19 = _896;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _970 = length(to_light);\n        dist = _970;\n        l = to_light / max(_970, 9.9999997473787516355514526367188e-05f).xxx;\n        float _984 = reach / max(_775.w, 0.001000000047497451305389404296875f);\n        float _990 = clamp(1.0f - (_984 * _984), 0.0f, 1.0f);\n        float _992;\n        if (front)\n        {\n            _992 = _990 * _990;\n        }\n        else\n        {\n            _992 = 0.0f;\n        }\n        atten = _992;\n        bool _1003 = _783 < 2.5f;\n        if ((_783 > 1.5f) && _1003)\n        {\n            int param_22 = _767 + 2;\n            float4 _1011 = fa_light_texel(param_22);\n            float _1021 = _1011.w;\n            int param_23 = _767 + 3;\n            float4 _1026 = fa_light_texel(param_23);\n            float _1027 = _1026.x;\n            float cos_inner = _1027;\n            if (_1027 > 1.5f)\n            {\n                cos_inner = lerp(_1021, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1021, cos_inner, dot(-l, normalize(_1011.xyz)));\n        }\n        if (_771 && (_783 < 1.5f))\n        {\n            int param_24 = _767 + 6;\n            float4 _1051 = fa_light_texel(param_24);\n            if (_1051.z > 0.5f)\n            {\n                float3 _1059 = -to_light;\n                int param_25 = _767 + 4;\n                int param_26 = _767 + 5;\n                float3 _1073 = fa_light_texel(param_25).xyz;\n                float3 _1077 = fa_light_texel(param_26).xyz;\n                float3 _1086 = float3(dot(_1059, _1073), dot(_1059, _1077), dot(_1059, cross(_1073, _1077)));\n                float3 param_27 = _1086;\n                int _1090 = fa_cube_face(param_27);\n                int param_28 = _1090;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1117 = float2(dot(_1086, cross(param_29, param_30)), dot(_1086, param_30)) / max(dot(_1086, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1121 = _1090 / 3;\n                float2 param_31 = _1051.xy + (float2(float(_1090 - (_1121 * 3)), float(_1121)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1117.x), 0.5f - (0.5f * _1117.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _767 + 7;\n            float4 _1151 = fa_light_texel(param_33);\n            if (_1151.z > 0.5f)\n            {\n                int param_34 = _767 + 2;\n                int param_35 = _767 + 4;\n                int param_36 = _767 + 5;\n                float2 param_37 = _1151.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_771 && _1003)\n            {\n                int param_42 = _767 + 6;\n                float4 _1198 = fa_light_texel(param_42);\n                int param_43 = _767 + 7;\n                float4 _1203 = fa_light_texel(param_43);\n                bool _1206 = _1198.z > 0.5f;\n                bool _1213;\n                if (!_1206)\n                {\n                    _1213 = _1203.z > 0.5f;\n                }\n                else\n                {\n                    _1213 = _1206;\n                }\n                if (_1213)\n                {\n                    int param_44 = _767 + 2;\n                    float4 _1220 = fa_light_texel(param_44);\n                    float3 _1224 = normalize(_1220.xyz);\n                    int param_45 = _767 + 4;\n                    float4 _1229 = fa_light_texel(param_45);\n                    int param_46 = _767 + 5;\n                    float4 _1234 = fa_light_texel(param_46);\n                    if (_1206)\n                    {\n                        float3 _1242 = -to_light;\n                        float _1249 = _1220.w;\n                        float _1265 = 0.5f / max(dot(_1242, _1224) * (sqrt(max(1.0f - (_1249 * _1249), 0.0f)) / max(_1249, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1198.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1242, _1229.xyz) * _1265), 0.5f - (dot(_1242, _1234.xyz) * _1265));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1203.z > 0.5f)\n                    {\n                        float2 param_49 = _1203.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1224;\n                        float3 param_52 = _1229.xyz;\n                        float3 param_53 = _1234.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6148 = _780.xyz * atten;\n    if (_771)\n    {\n        _6148 *= fa_light_tint;\n    }\n    int _1333;\n    if (_797)\n    {\n        _1333 = 0;\n    }\n    else\n    {\n        _1333 = ((_783 > 1.5f) && (_783 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _6159 = { l, _6148, atten, 1.0f, dist, _1333 };\n    return _6159;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2122 = fa_shadow_depth(param, param_1);\n    float _2126;\n    if (conv.x < 0.5f)\n    {\n        _2126 = _2122;\n    }\n    else\n    {\n        _2126 = (conv.y * conv.z) / (conv.z - (_2122 * (conv.z - conv.y)));\n    }\n    return _2126;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2172 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2178 = float2(cos(_2172), sin(_2172));\n    float2 dir = _2178;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2187;\n        if (k < 0.0f)\n        {\n            _2187 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2187 = k;\n        }\n        float _2206 = clamp((_2187 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2225 = sqrt((float(i) + 0.5f) * 0.0625f) * _2206;\n            float2 param_3 = uv + (dir * (_2075_fa_shadow_bias.zw * _2225));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2239 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2239 < (zr - (_2225 * plane)))\n            {\n                sum += _2239;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2267 = sum / cnt;\n        float _2277;\n        if (k < 0.0f)\n        {\n            _2277 = (-k) / max(_2267, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2277 = k;\n        }\n        radius = clamp(((max(zr - _2267, 0.0f) * unit) * _2277) / texel_m, 1.5f, 16.0f);\n        dir = _2178;\n    }\n    float lit = 0.0f;\n    int _2303 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2303; i_1++)\n    {\n        float _2322 = sqrt((float(i_1) + 0.5f) / float(_2303)) * radius;\n        float2 param_7 = uv + (dir * (_2075_fa_shadow_bias.zw * _2322));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2322 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2303);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2527 = _423_fa_pbr.z < 0.5f;\n    bool _2534;\n    if (!_2527)\n    {\n        _2534 = _2075_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2534 = _2527;\n    }\n    if (_2534)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2075_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2547 = fa_light_texel(param);\n    float _2548 = _2547.x;\n    if (_2548 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2557 = int(_2548 + 0.5f);\n    int param_1 = _2557;\n    float4 _2561 = fa_light_texel(param_1);\n    int param_2 = _2557 + 1;\n    float4 _2566 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2569 = _2561.y;\n    if (_2569 > 0.0f)\n    {\n        float _2586 = 1.0f - smoothstep(0.75f * _2569, _2569, length(world - _2075_fa_shadow_eye.xyz));\n        fade = _2586;\n        if (_2586 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2561.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2610 = (_2557 + 2) + (face * 6);\n    int param_4 = _2610;\n    int param_5 = _2610 + 1;\n    int param_6 = _2610 + 3;\n    float4 _2624 = fa_light_texel(param_6);\n    int param_7 = _2610 + 4;\n    float4 _2629 = fa_light_texel(param_7);\n    int param_8 = _2610 + 5;\n    float4 _2634 = fa_light_texel(param_8);\n    float _2646 = _2634.x * max(dot(_2624, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2651 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2674 = clamp(dot(n, _2624.xyz), -1.0f, 1.0f);\n    float _2693 = min(sqrt(1.0f - (_2674 * _2674)) / max(abs(dot(n, world - lpos)) / max(dot(_2624, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2696 = _2566.y;\n    float _2698;\n    if (_2696 > 0.0f)\n    {\n        _2698 = _2696;\n    }\n    else\n    {\n        _2698 = 1.5f * _2646;\n    }\n    float4 _2718 = float4(world + (n * (_2698 * sqrt(1.0f - (_2651 * _2651)))), 1.0f);\n    float _2722 = dot(_2624, _2718);\n    float _2725 = _2634.y;\n    if (_2722 < _2725)\n    {\n        return 1.0f;\n    }\n    float2 _2740 = float2(dot(fa_light_texel(param_4), _2718), dot(fa_light_texel(param_5), _2718)) / _2722.xx;\n    float _2742 = _2740.x;\n    bool _2745 = _2742 < _2629.x;\n    bool _2754;\n    if (!_2745)\n    {\n        _2754 = _2742 > _2629.z;\n    }\n    else\n    {\n        _2754 = _2745;\n    }\n    bool _2763;\n    if (!_2754)\n    {\n        _2763 = _2740.y < _2629.y;\n    }\n    else\n    {\n        _2763 = _2754;\n    }\n    bool _2772;\n    if (!_2763)\n    {\n        _2772 = _2740.y > _2629.w;\n    }\n    else\n    {\n        _2772 = _2763;\n    }\n    if (_2772)\n    {\n        return 1.0f;\n    }\n    float _2778 = _2566.x;\n    float _2780;\n    if (_2778 > 0.0f)\n    {\n        _2780 = _2778;\n    }\n    else\n    {\n        _2780 = 1.5f * _2646;\n    }\n    float2 param_9 = _2740;\n    float4 param_10 = _2629;\n    float param_11 = _2722 - (_2780 * (1.0f + (0.5f * _2693)));\n    float param_12 = _2646;\n    float param_13 = 1.0f;\n    float param_14 = _2634.z * 0.25f;\n    float param_15 = (_2646 * min(_2693, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2725, _2634.z);\n    int param_17 = int(_2561.z + 0.5f);\n    float param_18 = _2561.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _3287 = _423_fa_ct_b.w > 0.5f;\n    bool _3293;\n    if (_3287)\n    {\n        _3293 = _423_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3293 = _3287;\n    }\n    bool _3299;\n    if (_3293)\n    {\n        _3299 = _2075_fa_shadow_lcfg.x > 0.5f;\n    }\n    else\n    {\n        _3299 = _3293;\n    }\n    if (_3299)\n    {\n        int param = (int(_2075_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n        float4 _3311 = fa_light_texel(param);\n        float _3312 = _3311.z;\n        if (_3312 > 0.5f)\n        {\n            float _3325 = dot(_423_fa_ct_fwd.xyz, world) + _423_fa_ct_fwd.w;\n            float _3331 = ((0.00200000009499490261077880859375f * _3325) + 0.00999999977648258209228515625f) + fa_rt_slope;\n            float4 _3337 = float4(world, 1.0f);\n            float _3342 = dot(_423_fa_ct_vpw, _3337);\n            if (_3342 > 9.9999997473787516355514526367188e-05f)\n            {\n                float2 _3359 = float2(dot(_423_fa_ct_vpx, _3337), dot(_423_fa_ct_vpy, _3337)) / _3342.xx;\n                float _3364 = (_3359.x * 0.5f) + 0.5f;\n                float _3368;\n                if (_423_fa_ct_a.y > 0.5f)\n                {\n                    _3368 = (_3359.y * 0.5f) + 0.5f;\n                }\n                else\n                {\n                    _3368 = 0.5f - (_3359.y * 0.5f);\n                }\n                bool _3384 = _3364 >= 0.0f;\n                bool _3390;\n                if (_3384)\n                {\n                    _3390 = _3364 < 1.0f;\n                }\n                else\n                {\n                    _3390 = _3384;\n                }\n                bool _3396;\n                if (_3390)\n                {\n                    _3396 = _3368 >= 0.0f;\n                }\n                else\n                {\n                    _3396 = _3390;\n                }\n                bool _3402;\n                if (_3396)\n                {\n                    _3402 = _3368 < 1.0f;\n                }\n                else\n                {\n                    _3402 = _3396;\n                }\n                if (_3402)\n                {\n                    int2 _3419 = int2(_423_fa_ct_a.zw) - int2(1, 1);\n                    int2 _3420 = clamp(int2(float2(_3364, _3368) * _423_fa_ct_a.zw), int2(0, 0), _3419);\n                    float _3424;\n                    if (_3312 < 1.5f)\n                    {\n                        _3424 = 1.0f;\n                    }\n                    else\n                    {\n                        _3424 = (_3312 < 2.5f) ? 256.0f : 65536.0f;\n                    }\n                    float best = 2.0f;\n                    int _3446;\n                    int _3452;\n                    for (int k = 0; k < 9; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3446 = 4;\n                        }\n                        else\n                        {\n                            if (k <= 4)\n                            {\n                                _3452 = k - 1;\n                            }\n                            else\n                            {\n                                _3452 = k;\n                            }\n                            _3446 = _3452;\n                        }\n                        float4 _3481 = fa_screen_tex.Load(int3(clamp(_3420 + int2((_3446 % 3) - 1, (_3446 / 3) - 1), int2(0, 0), _3419), 0));\n                        bool _3484 = _3481.w > 0.5f;\n                        bool _3494;\n                        if (_3484)\n                        {\n                            _3494 = abs(_3325 - _3481.x) <= _3331;\n                        }\n                        else\n                        {\n                            _3494 = _3484;\n                        }\n                        if (_3494)\n                        {\n                            best = min(best, mod(floor(_3481.z / _3424), 256.0f) * 0.0039215688593685626983642578125f);\n                            if (k == 0)\n                            {\n                                break;\n                            }\n                        }\n                    }\n                    if (best <= 1.0f)\n                    {\n                        float _3521;\n                        if (_423_fa_ct_b.z > 0.5f)\n                        {\n                            int param_1 = li;\n                            float3 param_2 = lpos;\n                            float3 param_3 = world;\n                            float3 param_4 = n;\n                            float3 param_5 = l;\n                            _3521 = min(best, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                        }\n                        else\n                        {\n                            _3521 = best;\n                        }\n                        return _3521;\n                    }\n                }\n            }\n            float _3544;\n            if (_423_fa_ct_b.z > 0.5f)\n            {\n                int param_6 = li;\n                float3 param_7 = lpos;\n                float3 param_8 = world;\n                float3 param_9 = n;\n                float3 param_10 = l;\n                _3544 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3544 = 1.0f;\n            }\n            return _3544;\n        }\n    }\n    int param_11 = li;\n    float3 param_12 = lpos;\n    float3 param_13 = world;\n    float3 param_14 = n;\n    float3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2065;\n    if (i == 0)\n    {\n        _2065 = _2075_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2081;\n        if (i == 1)\n        {\n            _2081 = _2075_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2089;\n            if (i == 2)\n            {\n                _2089 = _2075_fa_shadow_split.z;\n            }\n            else\n            {\n                _2089 = _2075_fa_shadow_split.w;\n            }\n            _2081 = _2089;\n        }\n        _2065 = _2081;\n    }\n    return _2065;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2368 = max(_2075_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2373 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2379 = sqrt(1.0f - (_2373 * _2373));\n    float _2387 = min(_2379 / max(_2373, 0.20000000298023223876953125f), 4.0f);\n    float _2392;\n    if (_2075_fa_shadow_bias.y > 0.0f)\n    {\n        _2392 = _2075_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2392 = 1.5f * _2075_fa_shadow_info[ci].x;\n    }\n    float4 _2417 = mul(float4(world + (n * (_2392 * _2379)), 1.0f), _2075_fa_shadow_mat[ci]);\n    float _2424 = _2417.x;\n    bool _2427 = _2424 < _2075_fa_shadow_rect[ci].x;\n    bool _2436;\n    if (!_2427)\n    {\n        _2436 = _2424 > _2075_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2436 = _2427;\n    }\n    bool _2445;\n    if (!_2436)\n    {\n        _2445 = _2417.y < _2075_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2445 = _2436;\n    }\n    bool _2454;\n    if (!_2445)\n    {\n        _2454 = _2417.y > _2075_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2454 = _2445;\n    }\n    bool _2461;\n    if (!_2454)\n    {\n        _2461 = _2417.z > 1.0f;\n    }\n    else\n    {\n        _2461 = _2454;\n    }\n    if (_2461)\n    {\n        return -1.0f;\n    }\n    float _2469;\n    if (_2075_fa_shadow_bias.x > 0.0f)\n    {\n        _2469 = _2075_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2469 = 1.5f * _2075_fa_shadow_info[ci].x;\n    }\n    float2 param = _2417.xy;\n    float4 param_1 = _2075_fa_shadow_rect[ci];\n    float param_2 = _2417.z - ((_2469 * (1.0f + (0.5f * _2387))) / _2368);\n    float param_3 = _2075_fa_shadow_info[ci].x;\n    float param_4 = _2368;\n    float param_5 = _2368 * 0.25f;\n    float param_6 = ((_2075_fa_shadow_info[ci].x * min(_2387, 3.0f)) * 0.5f) / _2368;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2075_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2075_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_423_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2847 = int(_2075_fa_shadow_cfg.x + 0.5f);\n    if (_2847 < 1)\n    {\n        return 1.0f;\n    }\n    float _2862 = dot(world - _2075_fa_shadow_eye.xyz, _2075_fa_shadow_fwd.xyz);\n    int param = _2847 - 1;\n    if (_2862 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2874 = _2847 > 1;\n    bool _2881;\n    if (_2874)\n    {\n        _2881 = _2862 > _2075_fa_shadow_split.x;\n    }\n    else\n    {\n        _2881 = _2874;\n    }\n    if (_2881)\n    {\n        ci = 1;\n    }\n    bool _2885 = _2847 > 2;\n    bool _2892;\n    if (_2885)\n    {\n        _2892 = _2862 > _2075_fa_shadow_split.y;\n    }\n    else\n    {\n        _2892 = _2885;\n    }\n    if (_2892)\n    {\n        ci = 2;\n    }\n    bool _2896 = _2847 > 3;\n    bool _2903;\n    if (_2896)\n    {\n        _2903 = _2862 > _2075_fa_shadow_split.z;\n    }\n    else\n    {\n        _2903 = _2896;\n    }\n    if (_2903)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _2914 = min(_2847, 4);\n    float _2955;\n    for (int c = ci; c < _2914; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2934 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _2934;\n            break;\n        }\n        if (_2934 < 0.0f)\n        {\n            continue;\n        }\n        s = _2934;\n        ci = c;\n        if (_2075_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2955 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2955 = _2075_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _2974 = _2075_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2955, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_2862 - (fa_shadow_split_at(param_7) - _2974)) / _2974, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3006;\n        if ((ci + 1) < _2847)\n        {\n            _3006 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3006 = 1.0f;\n        }\n        s = lerp(s, _3006, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    bool _3111 = _423_fa_ct_b.y > 0.5f;\n    bool _3117;\n    if (_3111)\n    {\n        _3117 = _423_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3117 = _3111;\n    }\n    if (_3117)\n    {\n        float _3131 = dot(_423_fa_ct_fwd.xyz, fa_world_pos) + _423_fa_ct_fwd.w;\n        float4 _3139 = float4(fa_world_pos, 1.0f);\n        float _3145 = dot(_423_fa_ct_vpw, _3139);\n        if (_3145 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _3164 = float2(dot(_423_fa_ct_vpx, _3139), dot(_423_fa_ct_vpy, _3139)) / _3145.xx;\n            float _3169 = (_3164.x * 0.5f) + 0.5f;\n            float _3173;\n            if (_423_fa_ct_a.y > 0.5f)\n            {\n                _3173 = (_3164.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _3173 = 0.5f - (_3164.y * 0.5f);\n            }\n            bool _3189 = _3169 >= 0.0f;\n            bool _3195;\n            if (_3189)\n            {\n                _3195 = _3169 < 1.0f;\n            }\n            else\n            {\n                _3195 = _3189;\n            }\n            bool _3201;\n            if (_3195)\n            {\n                _3201 = _3173 >= 0.0f;\n            }\n            else\n            {\n                _3201 = _3195;\n            }\n            bool _3207;\n            if (_3201)\n            {\n                _3207 = _3173 < 1.0f;\n            }\n            else\n            {\n                _3207 = _3201;\n            }\n            if (_3207)\n            {\n                float4 _3233 = fa_screen_tex.Load(int3(clamp(int2(float2(_3169, _3173) * _423_fa_ct_a.zw), int2(0, 0), int2(_423_fa_ct_a.zw) - int2(1, 1)), 0));\n                bool _3236 = _3233.w > 0.5f;\n                bool _3252;\n                if (_3236)\n                {\n                    _3252 = abs(_3131 - _3233.x) <= (((0.00200000009499490261077880859375f * _3131) + 0.00999999977648258209228515625f) + fa_rt_slope);\n                }\n                else\n                {\n                    _3252 = _3236;\n                }\n                if (_3252)\n                {\n                    float _3258;\n                    if (_423_fa_ct_b.z > 0.5f)\n                    {\n                        float3 param = fa_world_pos;\n                        float3 param_1 = n;\n                        float3 param_2 = l;\n                        _3258 = min(_3233.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3258 = _3233.y;\n                    }\n                    return _3258;\n                }\n            }\n        }\n    }\n    float3 param_3 = fa_world_pos;\n    float3 param_4 = n;\n    float3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3914 = _423_fa_ct_a.x < 0.5f;\n    bool _3921;\n    if (!_3914)\n    {\n        _3921 = _2075_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3921 = _3914;\n    }\n    if (_3921)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2075_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3934 = fa_light_texel(param);\n    float _3935 = _3934.y;\n    float len = _3935;\n    if (_3935 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3947 = length(world - _423_fa_camera_pos.xyz);\n    float _3956 = 1.0f - smoothstep(0.5f * _423_fa_ct_b.x, _423_fa_ct_b.x, _3947);\n    if (_3956 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3962 = len;\n    float _3965 = min(_3962, 0.89999997615814208984375f * dist);\n    len = _3965;\n    float _3971 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3947);\n    float _3976 = _3971 + (0.5f * _3965);\n    float3 _3982 = world + (gn * _3971);\n    float _3984 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4046;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4000 = (float(k) + _3984) * 0.083333335816860198974609375f;\n        float3 _4008 = _3982 + (l * (_4000 * len));\n        float4 _4014 = float4(_4008, 1.0f);\n        float _4019 = dot(_423_fa_ct_vpw, _4014);\n        if (_4019 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4037 = float2(dot(_423_fa_ct_vpx, _4014), dot(_423_fa_ct_vpy, _4014)) / _4019.xx;\n        float _4041 = _4037.x * 0.5f;\n        float _4042 = _4041 + 0.5f;\n        if (_423_fa_ct_a.y > 0.5f)\n        {\n            _4046 = (_4037.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4046 = 0.5f - (_4037.y * 0.5f);\n        }\n        bool _4062 = _4042 < 0.0f;\n        bool _4069;\n        if (!_4062)\n        {\n            _4069 = _4042 >= 1.0f;\n        }\n        else\n        {\n            _4069 = _4062;\n        }\n        bool _4076;\n        if (!_4069)\n        {\n            _4076 = _4046 < 0.0f;\n        }\n        else\n        {\n            _4076 = _4069;\n        }\n        bool _4083;\n        if (!_4076)\n        {\n            _4083 = _4046 >= 1.0f;\n        }\n        else\n        {\n            _4083 = _4076;\n        }\n        if (_4083)\n        {\n            break;\n        }\n        float4 _4107 = fa_screen_tex.Load(int3(clamp(int2(float2(_4042, _4046) * _423_fa_ct_a.zw), int2(0, 0), int2(_423_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_4107.w < 0.5f)\n        {\n            continue;\n        }\n        float _4125 = (dot(_423_fa_ct_fwd.xyz, _4008) + _423_fa_ct_fwd.w) - _4107.x;\n        if ((_4125 > _3971) && (_4125 < _3976))\n        {\n            occ = max(occ, (1.0f - (_4000 * _4000)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4042, 0.5f - _4041), min(_4046, 1.0f - _4046))));\n        }\n    }\n    return 1.0f - (occ * _3956);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4257 = fa_baked_keep(param);\n    if (_4257 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _6172 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6172;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4283 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6174 = _4283.color;\n    float _6175 = _4283.attenuation;\n    float _6176 = _4283.shadow;\n    bool _4286 = _4283.type == 0;\n    if (_4286 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4283.direction;\n        float _4297 = fa_shadow_factor(param_5, param_6);\n        _6176 = _4297;\n        _6174 *= _4297;\n    }\n    else\n    {\n        bool _4308 = _4283.type != 0;\n        bool _4314;\n        if (_4308)\n        {\n            _4314 = _6175 > 0.0f;\n        }\n        else\n        {\n            _4314 = _4308;\n        }\n        if (_4314)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4283.direction;\n            float _4333 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6176 = _4333;\n            _6174 *= _4333;\n        }\n    }\n    bool _4343 = _423_fa_ct_a.x > 0.5f;\n    bool _4349;\n    if (_4343)\n    {\n        _4349 = _6175 > 0.0f;\n    }\n    else\n    {\n        _4349 = _4343;\n    }\n    if (_4349)\n    {\n        float _4356;\n        if (_4286)\n        {\n            _4356 = 1000000000.0f;\n        }\n        else\n        {\n            _4356 = _4283._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4283.direction;\n        float param_18 = _4356;\n        float _4374 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6176 *= _4374;\n        _6174 *= _4374;\n    }\n    float _4387 = _6175;\n    float _4388 = _4387 * _4257;\n    _6175 = _4388;\n    float3 _4392 = _6174;\n    float3 _4393 = _4392 * _4257;\n    _6174 = _4393;\n    LightSample _6191 = { _4283.direction, _4393, _4388, _6176, _4283._distance, _4283.type };\n    return _6191;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _4407;\n    if (dot(s.normal, l.direction) > 0.5f)\n    {\n        _4407 = 1.0f;\n    }\n    else\n    {\n        _4407 = _4413_dark;\n    }\n    return (s.albedo * l.color) * _4407;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2075_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3034 = int(_2075_fa_shadow_cfg.x + 0.5f);\n    float _3044 = dot(world - _2075_fa_shadow_eye.xyz, _2075_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3049 = _3034 > 0;\n    bool _3058;\n    if (_3049)\n    {\n        int param = _3034 - 1;\n        _3058 = _3044 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3058 = _3049;\n    }\n    if (_3058)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3064 = _3034 > 1;\n        bool _3071;\n        if (_3064)\n        {\n            _3071 = _3044 > _2075_fa_shadow_split.x;\n        }\n        else\n        {\n            _3071 = _3064;\n        }\n        if (_3071)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3077 = _3034 > 2;\n        bool _3084;\n        if (_3077)\n        {\n            _3084 = _3044 > _2075_fa_shadow_split.y;\n        }\n        else\n        {\n            _3084 = _3077;\n        }\n        if (_3084)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3090 = _3034 > 3;\n        bool _3097;\n        if (_3090)\n        {\n            _3097 = _3044 > _2075_fa_shadow_split.z;\n        }\n        else\n        {\n            _3097 = _3090;\n        }\n        if (_3097)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_rt_slope = 0.0f;\n    fa_inst_load();\n    float3 _5995 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5995 = -_5995;\n    }\n    float3 _5569 = normalize(_423_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _6008 = { fa_world_pos, _5995, fa_world_tangent, fa_uv, fa_vertex_color, _5569, gl_FrontFacing };\n    SurfaceInput param_1 = _6008;\n    Surface _5577 = fa_standard_surface(param_1);\n    float3 _6026 = _5577.albedo;\n    float _6027 = _5577.alpha;\n    float3 _6028 = _5577.normal;\n    float _6029 = _5577.metallic;\n    float _6030 = _5577.roughness;\n    float _6031 = _5577.occlusion;\n    float3 _6032 = _5577.emission;\n    float _6033 = _5577.clearcoat;\n    float _6034 = _5577.clearcoat_roughness;\n    float3 _6035 = _5577.sheen_color;\n    float _6036 = _5577.sheen_roughness;\n    float _6037 = _5577.anisotropy;\n    float _6038 = _5577.anisotropy_rotation;\n    float _6039 = _5577.specular;\n    float _6040 = _5577.ior;\n    float3 _6041 = _5577.specular_color;\n    float _6042 = _5577.transmission;\n    float _6043 = _5577.thickness;\n    float3 _6044 = _5577.attenuation_color;\n    float _6045 = _5577.attenuation_distance;\n    SurfaceInput _6016 = { fa_world_pos, _5995, fa_world_tangent, fa_uv, fa_vertex_color, _5569, gl_FrontFacing };\n    SurfaceInput param_2 = _6016;\n    Surface param_3 = _5577;\n    surface(param_2, param_3);\n    _6026 = param_3.albedo;\n    _6027 = param_3.alpha;\n    _6028 = param_3.normal;\n    _6029 = param_3.metallic;\n    _6030 = param_3.roughness;\n    _6031 = param_3.occlusion;\n    _6032 = param_3.emission;\n    _6033 = param_3.clearcoat;\n    _6034 = param_3.clearcoat_roughness;\n    _6035 = param_3.sheen_color;\n    _6036 = param_3.sheen_roughness;\n    _6037 = param_3.anisotropy;\n    _6038 = param_3.anisotropy_rotation;\n    _6039 = param_3.specular;\n    _6040 = param_3.ior;\n    _6041 = param_3.specular_color;\n    _6042 = param_3.transmission;\n    _6043 = param_3.thickness;\n    _6044 = param_3.attenuation_color;\n    _6045 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5995;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6026 = param_6;\n    _6028 = param_7;\n    float3 result;\n    if (_423_fa_emissive.w > 0.5f)\n    {\n        result = _6026;\n    }\n    else\n    {\n        float3 _5616 = _6028;\n        float3 _5617 = normalize(_5616);\n        _6028 = _5617;\n        float3 param_8 = _5617;\n        float3 lit = (fa_indirect_diffuse(param_8) * _6026) * _6031;\n        int _5636 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5636; ln++)\n        {\n            int param_9 = ln;\n            int _5649 = fa_cl_light(param_9);\n            int param_10 = _5649;\n            if (fa_baked_keep(param_10) <= 0.0f)\n            {\n                continue;\n            }\n            int param_11 = _5649;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _5995;\n            LightSample _5665 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput _6024 = { fa_world_pos, _5995, fa_world_tangent, fa_uv, fa_vertex_color, _5569, gl_FrontFacing };\n            SurfaceInput param_14 = _6024;\n            Surface _6127 = { _6026, _6027, _6028, _6029, _6030, _6031, _6032, _6033, _6034, _6035, _6036, _6037, _6038, _6039, _6040, _6041, _6042, _6043, _6044, _6045 };\n            Surface param_15 = _6127;\n            LightSample param_16 = _5665;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _5680 = result;\n    float3 _5681 = _5680 + _6032;\n    result = _5681;\n    float3 param_17 = _5681;\n    float3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _5690 = _423_fa_fog.w > 0.0f;\n    bool _5697;\n    if (!_5690)\n    {\n        _5697 = _423_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5697 = _5690;\n    }\n    if (_5697)\n    {\n        float3 _5706 = fa_world_pos - _423_fa_camera_pos.xyz;\n        float _5712 = dot(_5706, _423_fa_fog_c.xyz);\n        bool _5716 = _423_fa_fog_c.w > 0.5f;\n        float _5717;\n        if (_5716)\n        {\n            _5717 = _5712;\n        }\n        else\n        {\n            _5717 = length(_5706);\n        }\n        float _5729 = _5717 - _423_fa_fog_b.x;\n        if (_5729 > 0.0f)\n        {\n            float _5738 = _423_fa_fog.w * _5729;\n            float tau = _5738 * _5738;\n            if (_423_fa_fog_b.y > 0.0f)\n            {\n                float _5754;\n                if (_5716)\n                {\n                    _5754 = fa_world_pos.y - (_423_fa_fog_c.y * _5712);\n                }\n                else\n                {\n                    _5754 = _423_fa_camera_pos.y;\n                }\n                float _5775 = lerp(_5754, fa_world_pos.y, clamp(_423_fa_fog_b.x / _5717, 0.0f, 1.0f));\n                float _5779 = fa_world_pos.y - _5775;\n                float _5784 = _5775 - _423_fa_fog_b.z;\n                float _5789 = fa_world_pos.y - _423_fa_fog_b.z;\n                bool _5792 = _5784 <= 0.0f;\n                bool _5793 = !_5792;\n                bool _5799;\n                if (_5793)\n                {\n                    _5799 = _423_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5799 = _5792;\n                }\n                float _5800;\n                if (_5799)\n                {\n                    _5800 = _423_fa_fog_b.y;\n                }\n                else\n                {\n                    _5800 = _423_fa_fog_b.y * exp(-min(_423_fa_fog_b.w * _5784, 80.0f));\n                }\n                bool _5827;\n                if (_5793)\n                {\n                    _5827 = _423_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5827 = _5792;\n                }\n                float _5828;\n                if (_5827)\n                {\n                    _5828 = _423_fa_fog_b.y * _5784;\n                }\n                else\n                {\n                    _5828 = (_423_fa_fog_b.y * (1.0f - exp(-min(_423_fa_fog_b.w * _5784, 80.0f)))) / _423_fa_fog_b.w;\n                }\n                bool _5853 = _5789 <= 0.0f;\n                bool _5860;\n                if (!_5853)\n                {\n                    _5860 = _423_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5860 = _5853;\n                }\n                float _5861;\n                if (_5860)\n                {\n                    _5861 = _423_fa_fog_b.y * _5789;\n                }\n                else\n                {\n                    _5861 = (_423_fa_fog_b.y * (1.0f - exp(-min(_423_fa_fog_b.w * _5789, 80.0f)))) / _423_fa_fog_b.w;\n                }\n                float _5888;\n                if (abs(_5779) < 0.001000000047497451305389404296875f)\n                {\n                    _5888 = _5800;\n                }\n                else\n                {\n                    _5888 = (_5861 - _5828) / _5779;\n                }\n                tau += (_5729 * max(_5888, 0.0f));\n            }\n            result = lerp(result, _423_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _6027);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_423",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2075",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_4413",
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
