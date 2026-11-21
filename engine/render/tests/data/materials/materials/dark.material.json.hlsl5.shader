{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "4a8331d4c52f4add9385ad09f3cee754aeec6a52a5c8c810972e182590f5426b",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _260 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _260;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_267, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _416_fa_camera_pos : packoffset(c0);\n    float4 _416_fa_ambient : packoffset(c1);\n    float4 _416_fa_base_color : packoffset(c2);\n    float4 _416_fa_emissive : packoffset(c3);\n    float4 _416_fa_model_emissive : packoffset(c4);\n    float4 _416_fa_pbr : packoffset(c5);\n    float4 _416_fa_maps : packoffset(c6);\n    float4 _416_fa_fog : packoffset(c7);\n    float4 _416_fa_fog_b : packoffset(c8);\n    float4 _416_fa_fog_c : packoffset(c9);\n    float4 _416_fa_counts : packoffset(c10);\n    float4 _416_fa_env_sky : packoffset(c11);\n    float4 _416_fa_env_horizon : packoffset(c12);\n    float4 _416_fa_time : packoffset(c13);\n    float4 _416_fa_cl_vpx : packoffset(c14);\n    float4 _416_fa_cl_vpy : packoffset(c15);\n    float4 _416_fa_cl_vpw : packoffset(c16);\n    float4 _416_fa_cl_fwd : packoffset(c17);\n    float4 _416_fa_cl_grid : packoffset(c18);\n    float4 _416_fa_cl_info : packoffset(c19);\n    float4 _416_fa_layers_a : packoffset(c20);\n    float4 _416_fa_layers_b : packoffset(c21);\n    float4 _416_fa_layers_c : packoffset(c22);\n    float4 _416_fa_layers_d : packoffset(c23);\n    float4 _416_fa_ct_a : packoffset(c24);\n    float4 _416_fa_ct_b : packoffset(c25);\n    float4 _416_fa_ct_vpx : packoffset(c26);\n    float4 _416_fa_ct_vpy : packoffset(c27);\n    float4 _416_fa_ct_vpw : packoffset(c28);\n    float4 _416_fa_ct_fwd : packoffset(c29);\n    float4 _416_fa_tr_a : packoffset(c30);\n    float4 _416_fa_tr_b : packoffset(c31);\n    float4 _416_fa_probe_sh[9] : packoffset(c32);\n    float4 _416_fa_atlas : packoffset(c41);\n    float4 _416_fa_rpa_tile : packoffset(c42);\n    float4 _416_fa_rpa_pos : packoffset(c43);\n    float4 _416_fa_rpa_bx : packoffset(c44);\n    float4 _416_fa_rpa_by : packoffset(c45);\n    float4 _416_fa_rpa_bz : packoffset(c46);\n    float4 _416_fa_rpb_tile : packoffset(c47);\n    float4 _416_fa_rpb_pos : packoffset(c48);\n    float4 _416_fa_rpb_bx : packoffset(c49);\n    float4 _416_fa_rpb_by : packoffset(c50);\n    float4 _416_fa_rpb_bz : packoffset(c51);\n    float4 _416_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2073_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2073_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2073_fa_shadow_info[4] : packoffset(c20);\n    float4 _2073_fa_shadow_split : packoffset(c24);\n    float4 _2073_fa_shadow_cfg : packoffset(c25);\n    float4 _2073_fa_shadow_bias : packoffset(c26);\n    float4 _2073_fa_shadow_eye : packoffset(c27);\n    float4 _2073_fa_shadow_fwd : packoffset(c28);\n    float4 _2073_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1344 = _416_fa_cl_info.x < 0.0f;\n    bool _1351;\n    if (!_1344)\n    {\n        _1351 = _416_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1351 = _1344;\n    }\n    bool _1359;\n    if (!_1351)\n    {\n        _1359 = _416_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1359 = _1351;\n    }\n    bool _1366;\n    if (!_1359)\n    {\n        _1366 = _416_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1366 = _1359;\n    }\n    bool _1373;\n    if (!_1366)\n    {\n        _1373 = _416_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1373 = _1366;\n    }\n    if (_1373)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1383 = float4(world_pos, 1.0f);\n    float _1389 = dot(_416_fa_cl_vpw, _1383);\n    if (!(_1389 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1411 = float2(dot(_416_fa_cl_vpx, _1383), dot(_416_fa_cl_vpy, _1383)) / _1389.xx;\n    int _1415 = int(_416_fa_cl_grid.x);\n    int _1419 = int(_416_fa_cl_grid.y);\n    int param = (int(_416_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_416_fa_cl_fwd.xyz, world_pos) + _416_fa_cl_fwd.w, _416_fa_cl_grid.w) / _416_fa_cl_grid.w) * _416_fa_cl_grid.z)), 0, int(_416_fa_cl_info.y) - 1) * _1419) + clamp(int(floor(((_1411.y * 0.5f) + 0.5f) * _416_fa_cl_grid.y)), 0, _1419 - 1)) * _1415)) + clamp(int(floor(((_1411.x * 0.5f) + 0.5f) * _416_fa_cl_grid.x)), 0, _1415 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1495 = fa_cluster_texel(param);\n    return int2(int(_1495.x), int(_1495.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_416_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3722 = fa_cluster_lookup(param);\n    fa_cl_slot = _3722.x;\n    fa_cl_local = _3722.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3927 = fa_linear_to_srgb(param);\n        c = _3927;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3935 = fa_srgb_to_linear(param_1);\n            c = _3935;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _298;\n    if (i.front_facing)\n    {\n        _298 = i.world_normal;\n    }\n    else\n    {\n        _298 = -i.world_normal;\n    }\n    float3 _322 = normalize(i.world_tangent.xyz - (_298 * dot(_298, i.world_tangent.xyz)));\n    float3 _349 = normalize(((_322 * m.x) + ((cross(_298, _322) * i.world_tangent.w) * m.y)) + (_298 * m.z));\n    float3 _352;\n    if (i.front_facing)\n    {\n        _352 = _349;\n    }\n    else\n    {\n        _352 = -_349;\n    }\n    return _352;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _416_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3966 = fa_tex_fix(param_2, param_3);\n    float4 _5670 = base_t;\n    _5670.x = _3966.x;\n    _5670.y = _3966.y;\n    _5670.z = _3966.z;\n    base_t = _5670;\n    float4 _3980 = (_5670 * _416_fa_base_color) * i.vertex_color;\n    float3 _5507 = i.world_normal;\n    if (_416_fa_maps.z > 0.5f)\n    {\n        float param_4 = _416_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4012 = fa_tex_fix(param_6, param_7);\n        float3 _4015 = (_4012 * 2.0f) - 1.0f.xxx;\n        float2 _4020 = _4015.xy * _416_fa_maps.x;\n        float3 _5678 = _4015;\n        _5678.x = _4020.x;\n        _5678.y = _4020.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5678;\n        _5507 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _416_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4048 = fa_tex_fix(param_12, param_13);\n    float4 _5681 = mrt;\n    _5681.x = _4048.x;\n    _5681.y = _4048.y;\n    _5681.z = _4048.z;\n    mrt = _5681;\n    float4 _4076 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _416_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4076.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4087 = fa_tex_fix(param_16, param_17);\n    float param_18 = _416_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4117 = fa_tex_fix(param_20, param_21);\n    float _5512 = _416_fa_layers_a.x;\n    float _5513 = _416_fa_layers_a.y;\n    float _5516 = _416_fa_layers_a.z;\n    float _5515 = _416_fa_layers_b.w;\n    float _5518 = _416_fa_layers_c.x;\n    if (_416_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_416_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _5512 *= _4087.y;\n            _5513 *= _4087.z;\n            _5515 *= _4076.w;\n        }\n        if (_416_fa_layers_c.z > 1.5f)\n        {\n            _5516 *= mrt.x;\n            _5518 *= mrt.w;\n        }\n    }\n    Surface _5545 = { _3980.xyz, _3980.w, _5507, clamp(_416_fa_pbr.x * _4048.z, 0.0f, 1.0f), clamp(_416_fa_pbr.y * _4048.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_416_fa_maps.y * (_4087.x - 1.0f)), _416_fa_emissive.xyz + (_416_fa_model_emissive.xyz * _4117), _5512, _5513, _416_fa_layers_b.xyz, _5515, _5516, _416_fa_layers_a.w, _5518, _416_fa_layers_c.y, _416_fa_layers_d.xyz, _416_fa_tr_a.x, _416_fa_tr_a.y, _416_fa_tr_b.xyz, _416_fa_tr_a.z };\n    return _5545;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1575 = rect.zw - rect.xy;\n    float2 _1579 = _1575 * atlas;\n    float2 _1583 = ddx * _1579;\n    float2 _1587 = ddy * _1579;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1575), clamp(0.5f * log2(max(max(dot(_1583, _1583), dot(_1587, _1587)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1620 = _416_fa_counts.y < 0.5f;\n    bool _1627;\n    if (!_1620)\n    {\n        _1627 = _416_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1627 = _1620;\n    }\n    if (_1627)\n    {\n        return;\n    }\n    float3 _1633 = ddx(world_pos);\n    float3 _1636 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1640 = fa_cluster_texel(param);\n    int _1644 = int(_1640.w);\n    if (_1644 < 1)\n    {\n        return;\n    }\n    int _1654 = int(_416_fa_counts.y + 0.5f);\n    int param_1 = _1654;\n    float4 _1658 = fa_light_texel(param_1);\n    float2 _1661 = _1658.yz;\n    int _1665 = int(_1658.w);\n    int param_2 = _1654 + 1;\n    float4 _1670 = fa_light_texel(param_2);\n    float _1671 = _1670.x;\n    int _1677 = int(_416_fa_counts.w + 0.5f) - 1;\n    int _1681 = int(_1640.z);\n    float3 _1946;\n    for (int k = 0; k < _1644; k++)\n    {\n        int _1694 = _1681 + k;\n        int param_3 = _1665 + (_1694 >> 2);\n        int _1711 = (_1654 + 2) + (int(fa_light_texel(param_3)[_1694 & 3]) * 7);\n        int param_4 = _1711 + 6;\n        float4 _1716 = fa_light_texel(param_4);\n        if (((int(_1716.w + 0.5f) >> _1677) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1711;\n        float4 _1731 = fa_light_texel(param_5);\n        int param_6 = _1711 + 1;\n        float4 _1736 = fa_light_texel(param_6);\n        int param_7 = _1711 + 2;\n        float4 _1741 = fa_light_texel(param_7);\n        float3 _1744 = _1731.xyz;\n        float _1749 = dot(_1744, world_pos) + _1731.w;\n        float3 _1751 = _1736.xyz;\n        float _1756 = dot(_1751, world_pos) + _1736.w;\n        float3 _1758 = _1741.xyz;\n        float _1763 = dot(_1758, world_pos) + _1741.w;\n        bool _1768 = abs(_1749) > 0.5f;\n        bool _1776;\n        if (!_1768)\n        {\n            _1776 = abs(_1756) > 0.5f;\n        }\n        else\n        {\n            _1776 = _1768;\n        }\n        bool _1784;\n        if (!_1776)\n        {\n            _1784 = abs(_1763) > 0.5f;\n        }\n        else\n        {\n            _1784 = _1776;\n        }\n        if (_1784)\n        {\n            continue;\n        }\n        float _1799 = clamp(dot(geo_normal, normalize(_1758)) * _1716.z, 0.0f, 1.0f);\n        if (_1799 <= 0.0f)\n        {\n            continue;\n        }\n        float _1819 = (clamp((0.5f - abs(_1763)) * 10.0f, 0.0f, 1.0f) * _1799) * _1716.x;\n        float2 _1827 = float2(_1749 + 0.5f, 0.5f - _1756);\n        float2 _1837 = float2(dot(_1744, _1633), dot(_1751, _1633));\n        float2 _1847 = float2(dot(_1744, _1636), dot(_1751, _1636));\n        int param_8 = _1711 + 5;\n        float4 _1852 = fa_light_texel(param_8);\n        int param_9 = _1711 + 3;\n        float4 _1857 = fa_light_texel(param_9);\n        int param_10 = _1711 + 4;\n        float4 _1862 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1852.xyz;\n        bool _1872 = _1857.z > _1857.x;\n        if (_1872)\n        {\n            float4 param_11 = _1857;\n            float2 param_12 = _1827;\n            float2 param_13 = _1661;\n            float2 param_14 = _1837;\n            float2 param_15 = _1847;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1671 > 0.5f) && (_1671 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1898 = fa_dc_to_linear(param_16);\n                float4 _5595 = tx;\n                _5595.x = _1898.x;\n                _5595.y = _1898.y;\n                _5595.z = _1898.z;\n                tx = _5595;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1819 * tex_a) * _1852.w, 0.0f, 1.0f).xxx);\n        if (_1862.z > _1862.x)\n        {\n            float4 param_17 = _1862;\n            float2 param_18 = _1827;\n            float2 param_19 = _1661;\n            float2 param_20 = _1837;\n            float2 param_21 = _1847;\n            float4 _1942 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1671 > 1.5f)\n            {\n                float3 param_22 = _1942.xyz;\n                float3 _1952 = fa_dc_to_srgb(param_22);\n                _1946 = _1952;\n            }\n            else\n            {\n                _1946 = _1942.xyz;\n            }\n            float3 _1961 = (_1946 * 2.0f) - 1.0f.xxx;\n            float2 _1966 = _1961.xy * _1716.y;\n            float3 _1988 = (normalize(_1744) * _1966.x) + (normalize(_1751) * _1966.y);\n            float3 _1991 = normalize(normal);\n            normal = normalize(lerp(_1991, normalize((_1991 * max(_1961.z, 0.0500000007450580596923828125f)) + (_1988 - (_1991 * dot(_1991, _1988)))), clamp(_1819 * (_1872 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3186 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3186;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3245_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3245_dummy_parameter)));\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3206 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3209 = _3206.x;\n    float _3211 = _3206.z;\n    float2 e = float2(_3209, _3211);\n    if (_3206.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3211)) * ((_3209 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3209)) * ((_3211 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _4231 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _4236 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _4241 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _4246 = fa_light_texel(param_3);\n    bool _4249 = _4246.z < 0.5f;\n    bool _4257;\n    if (!_4249)\n    {\n        _4257 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _4257 = _4249;\n    }\n    if (_4257)\n    {\n        return 0.0f.xxx;\n    }\n    float _4264 = max(_4231.w, 9.9999997473787516355514526367188e-05f);\n    float3 _4267 = _4236.xyz;\n    float3 _4271 = _4231.xyz;\n    float3 _4275 = (fa_world_pos - _4271) / _4264.xxx;\n    float3 _4284 = min(_4275 + 0.5f.xxx, (_4267 - 0.5f.xxx) - _4275);\n    float _4293 = min(_4284.x, min(_4284.y, _4284.z));\n    if (!(_4293 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4308 = _4267 - 1.0f.xxx;\n    float3 _4309 = clamp(_4275, 0.0f.xxx, _4308);\n    float3 _4317 = min(floor(_4309), max(_4267 - 2.0f.xxx, 0.0f.xxx));\n    float3 _4321 = _4309 - _4317;\n    float3 _4333 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _4264));\n    int _4338 = int(_4241.y + 0.5f);\n    float3 sh[9];\n    for (int k = 0; k < 9; k++)\n    {\n        sh[k] = 0.0f.xxx;\n    }\n    float wsum = 0.0f;\n    int _4356 = int(_4246.w);\n    int _4357 = 8 + _4356;\n    int _4362 = 9 + _4356;\n    float _4389;\n    float _4402;\n    float _4416;\n    for (int k_1 = 0; k_1 < _4357; k_1++)\n    {\n        float _4375 = float(k_1 & 1);\n        float _4379 = float((k_1 >> 1) & 1);\n        float _4383 = float((k_1 >> 2) & 1);\n        if (_4375 > 0.5f)\n        {\n            _4389 = _4321.x;\n        }\n        else\n        {\n            _4389 = 1.0f - _4321.x;\n        }\n        if (_4379 > 0.5f)\n        {\n            _4402 = _4321.y;\n        }\n        else\n        {\n            _4402 = 1.0f - _4321.y;\n        }\n        if (_4383 > 0.5f)\n        {\n            _4416 = _4321.z;\n        }\n        else\n        {\n            _4416 = 1.0f - _4321.z;\n        }\n        float _4426 = (_4389 * _4402) * _4416;\n        if (!(_4426 > 0.0f))\n        {\n            continue;\n        }\n        float3 _4439 = min(_4317 + float3(_4375, _4379, _4383), _4308);\n        int _4459 = int(((_4241.x + _4439.x) + (_4236.x * (_4439.y + (_4236.y * _4439.z)))) + 0.5f);\n        float2 _4474 = float2(float(_4459 % _4338) * 10.0f, 1024.0f + (float(_4459 / _4338) * 11.0f));\n        float2 param_4 = _4474 + float2(9.5f, 10.5f);\n        float4 _4482 = fa_gi_fetch(param_4);\n        bool _4485 = _4482.y < 0.5f;\n        bool _4494;\n        if (!_4485)\n        {\n            _4494 = _4482.x > _4246.y;\n        }\n        else\n        {\n            _4494 = _4485;\n        }\n        if (_4494)\n        {\n            continue;\n        }\n        float3 _4506 = _4333 - (_4271 + (_4439 * _4264));\n        float _4509 = length(_4506);\n        float3 _4515 = _4506 / max(_4509, 9.9999997473787516355514526367188e-05f).xxx;\n        float _4525 = max(9.9999997473787516355514526367188e-05f, (dot(-_4515, n) + 1.0f) * 0.5f);\n        float w = _4426 * (_4525 * _4525);\n        float3 param_5 = _4515;\n        float2 param_6 = (_4474 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _4544 = fa_gi_fetch(param_6);\n        float _4551 = _4509 / max(_4241.z, 9.9999997473787516355514526367188e-05f);\n        float _4554 = _4544.x;\n        if (_4551 > _4554)\n        {\n            float _4567 = max(_4544.y - (_4554 * _4554), 0.0f);\n            float _4572 = _4551 - _4554;\n            float _4581 = _4567 / max(_4567 + (_4572 * _4572), 9.9999999600419720025001879548654e-13f);\n            w *= ((_4581 * _4581) * _4581);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        for (int c = 0; c < _4362; c++)\n        {\n            float2 param_7 = _4474 + float2(float(c) + 0.5f, 10.5f);\n            sh[c] += (fa_gi_fetch(param_7).xyz * w);\n        }\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    for (int c_1 = 0; c_1 < 9; c_1++)\n    {\n        sh[c_1] /= wsum.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_4293 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _4662;\n    if (_416_fa_gi.z > 0.5f)\n    {\n        _4662 = _4246.x;\n    }\n    else\n    {\n        _4662 = 1.0f;\n    }\n    float3 param_8[9] = sh;\n    float3 param_9 = n;\n    return fa_sh_eval(param_8, param_9) * (_4241.w * _4662);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _4686 = normalize(_416_fa_camera_pos.xyz - fa_world_pos);\n    int _4691 = int(_416_fa_gi.x + 0.5f);\n    int _4696 = int(_416_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _4696) && (k < 8); k++)\n    {\n        int param = _4691 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _4686;\n        float3 _4721 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _4726 = param_3 * left;\n        acc += (_4721 * _4726);\n        left -= _4726;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_416_fa_atlas.y > 0.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3293 = (1.0f - _416_fa_rpa_tile.w) - _416_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3299 = _416_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3293 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3299)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _416_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3293;\n            }\n        }\n        else\n        {\n            amb = _416_fa_ambient.xyz * _3293;\n        }\n    }\n    bool _3352 = _416_fa_rpa_tile.w > 0.0f;\n    if (_3352)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _416_fa_rpa_tile.xy;\n            float param_4 = _416_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _416_fa_rpa_tile.w);\n        }\n    }\n    bool _3383 = _416_fa_rpb_tile.w > 0.0f;\n    if (_3383)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _416_fa_rpb_tile.xy;\n            float param_7 = _416_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _416_fa_rpb_tile.w);\n        }\n    }\n    if ((_3299 || _3352) || _3383)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    if (_416_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _4755 = fa_gi_light(param, param_1);\n        if (param_1 < 0.999000012874603271484375f)\n        {\n            float3 _4764;\n            if (param_1 > 0.0f)\n            {\n                float3 param_2 = n;\n                _4764 = _4755 + (fa_ambient_light(param_2) * param_1);\n            }\n            else\n            {\n                _4764 = _4755;\n            }\n            return _4764;\n        }\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_416_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _416_fa_probe_sh[k].xyz;\n        }\n        float3 param[9] = c;\n        float3 param_1 = n;\n        float3 _4826 = fa_sh_eval(param, param_1);\n        if (_416_fa_probe_sh[0].w >= 1.0f)\n        {\n            return _4826;\n        }\n        float3 param_2 = n;\n        return lerp(fa_realtime_or_ambient(param_2), _4826, clamp(_416_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_416_fa_cl_info.x) + int(_416_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_416_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3692;\n    if (fa_lm.z > 0.5f)\n    {\n        _3692 = 0.0f;\n    }\n    else\n    {\n        _3692 = 1.0f - clamp(_416_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _3703 = _3692 < 1.0f;\n    bool _3709;\n    if (_3703)\n    {\n        int param = li;\n        _3709 = fa_light_baked(param);\n    }\n    else\n    {\n        _3709 = _3703;\n    }\n    return _3709 ? _3692 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _594 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _607 = (c - (ru * hx)) - p;\n        float3 _613 = ru * (2.0f * hx);\n        float _619 = max(dot(_613, _613), 9.9999999392252902907785028219223e-09f);\n        float _623 = dot(_607, _613);\n        float t = clamp((-_623) / _619, 0.0f, 1.0f);\n        if (_594)\n        {\n            float _638 = dot(r, _613);\n            float _644 = _619 - (_638 * _638);\n            if (abs(_644) > (9.9999997473787516355514526367188e-06f * _619))\n            {\n                t = clamp(((dot(r, _607) * _638) - _623) / _644, 0.0f, 1.0f);\n            }\n        }\n        return (p + _607) + (_613 * t);\n    }\n    float3 q = p;\n    float _676 = dot(r, axis);\n    bool _684;\n    if (_594)\n    {\n        _684 = abs(_676) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _684 = _594;\n    }\n    if (_684)\n    {\n        float _694 = dot(c - p, axis) / _676;\n        if (_694 > 0.0f)\n        {\n            q = p + (r * _694);\n        }\n    }\n    float3 _707 = q - c;\n    float2 xy = float2(dot(_707, ru), dot(_707, uu));\n    if (shape > 0.5f)\n    {\n        float _722 = length(xy);\n        if (_722 > hx)\n        {\n            xy *= (hx / _722);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _475_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _475_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _514 = dot(d, right);\n    float _518 = dot(d, up);\n    float _529;\n    if (((_514 * _514) + (_518 * _518)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _529 = atan2(_518, _514) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _529 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_529 - floor(_529)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _364 = abs(d);\n    float _366 = _364.x;\n    float _368 = _364.y;\n    bool _369 = _366 >= _368;\n    bool _377;\n    if (_369)\n    {\n        _377 = _366 >= _364.z;\n    }\n    else\n    {\n        _377 = _369;\n    }\n    int _378;\n    if (_377)\n    {\n        _378 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _393;\n        if (_368 >= _364.z)\n        {\n            _393 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _393 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _378 = _393;\n    }\n    return _378;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _760 = fa_light_base(param);\n    bool _764 = _416_fa_ambient.w > 4.5f;\n    int param_1 = _760;\n    float4 _768 = fa_light_texel(param_1);\n    int param_2 = _760 + 1;\n    float4 _773 = fa_light_texel(param_2);\n    float _776 = _773.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _788 = _764 && (_776 > 2.5f);\n    fa_light_is_area = _788;\n    bool _790 = _776 < 0.5f;\n    float3 l;\n    if (_790)\n    {\n        l = normalize(_768.xyz);\n        if (_764)\n        {\n            int param_3 = _760 + 6;\n            float4 _804 = fa_light_texel(param_3);\n            if (_804.z > 0.5f)\n            {\n                int param_4 = _760 + 4;\n                float4 _814 = fa_light_texel(param_4);\n                int param_5 = _760 + 5;\n                float4 _819 = fa_light_texel(param_5);\n                float2 param_6 = _804.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _814.xyz) * _814.w, (-dot(world_pos, _819.xyz)) * _819.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _849 = _768.xyz;\n        float3 _851 = _849 - world_pos;\n        float3 to_light = _851;\n        float _854 = length(_851);\n        float reach = _854;\n        bool front = true;\n        if (_788)\n        {\n            int param_8 = _760 + 7;\n            reach = max(_854 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _760 + 4;\n            float4 _878 = fa_light_texel(param_9);\n            int param_10 = _760 + 5;\n            float4 _883 = fa_light_texel(param_10);\n            int param_11 = _760 + 6;\n            float4 _888 = fa_light_texel(param_11);\n            float _889 = _888.w;\n            int param_12 = _760 + 2;\n            float3 _896 = normalize(fa_light_texel(param_12).xyz);\n            bool _898 = _889 > 1.5f;\n            bool _906;\n            if (!_898)\n            {\n                _906 = dot(_896, to_light) < 0.0f;\n            }\n            else\n            {\n                _906 = _898;\n            }\n            front = _906;\n            float3 r = 0.0f.xxx;\n            float3 _915 = _416_fa_camera_pos.xyz - world_pos;\n            bool _919 = dot(n, n) > 0.5f;\n            bool _927;\n            if (_919)\n            {\n                _927 = dot(_915, _915) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _927 = _919;\n            }\n            if (_927)\n            {\n                r = reflect(-normalize(_915), normalize(n));\n            }\n            float3 param_13 = _849;\n            float3 param_14 = _896;\n            float3 param_15 = _878.xyz;\n            float3 param_16 = _883.xyz;\n            float param_17 = _878.w;\n            float param_18 = _883.w;\n            float param_19 = _889;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _963 = length(to_light);\n        dist = _963;\n        l = to_light / max(_963, 9.9999997473787516355514526367188e-05f).xxx;\n        float _977 = reach / max(_768.w, 0.001000000047497451305389404296875f);\n        float _983 = clamp(1.0f - (_977 * _977), 0.0f, 1.0f);\n        float _985;\n        if (front)\n        {\n            _985 = _983 * _983;\n        }\n        else\n        {\n            _985 = 0.0f;\n        }\n        atten = _985;\n        bool _996 = _776 < 2.5f;\n        if ((_776 > 1.5f) && _996)\n        {\n            int param_22 = _760 + 2;\n            float4 _1004 = fa_light_texel(param_22);\n            float _1014 = _1004.w;\n            int param_23 = _760 + 3;\n            float4 _1019 = fa_light_texel(param_23);\n            float _1020 = _1019.x;\n            float cos_inner = _1020;\n            if (_1020 > 1.5f)\n            {\n                cos_inner = lerp(_1014, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1014, cos_inner, dot(-l, normalize(_1004.xyz)));\n        }\n        if (_764 && (_776 < 1.5f))\n        {\n            int param_24 = _760 + 6;\n            float4 _1044 = fa_light_texel(param_24);\n            if (_1044.z > 0.5f)\n            {\n                float3 _1052 = -to_light;\n                int param_25 = _760 + 4;\n                int param_26 = _760 + 5;\n                float3 _1066 = fa_light_texel(param_25).xyz;\n                float3 _1070 = fa_light_texel(param_26).xyz;\n                float3 _1079 = float3(dot(_1052, _1066), dot(_1052, _1070), dot(_1052, cross(_1066, _1070)));\n                float3 param_27 = _1079;\n                int _1083 = fa_cube_face(param_27);\n                int param_28 = _1083;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1110 = float2(dot(_1079, cross(param_29, param_30)), dot(_1079, param_30)) / max(dot(_1079, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1114 = _1083 / 3;\n                float2 param_31 = _1044.xy + (float2(float(_1083 - (_1114 * 3)), float(_1114)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1110.x), 0.5f - (0.5f * _1110.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _760 + 7;\n            float4 _1144 = fa_light_texel(param_33);\n            if (_1144.z > 0.5f)\n            {\n                int param_34 = _760 + 2;\n                int param_35 = _760 + 4;\n                int param_36 = _760 + 5;\n                float2 param_37 = _1144.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_764 && _996)\n            {\n                int param_42 = _760 + 6;\n                float4 _1191 = fa_light_texel(param_42);\n                int param_43 = _760 + 7;\n                float4 _1196 = fa_light_texel(param_43);\n                bool _1199 = _1191.z > 0.5f;\n                bool _1206;\n                if (!_1199)\n                {\n                    _1206 = _1196.z > 0.5f;\n                }\n                else\n                {\n                    _1206 = _1199;\n                }\n                if (_1206)\n                {\n                    int param_44 = _760 + 2;\n                    float4 _1213 = fa_light_texel(param_44);\n                    float3 _1217 = normalize(_1213.xyz);\n                    int param_45 = _760 + 4;\n                    float4 _1222 = fa_light_texel(param_45);\n                    int param_46 = _760 + 5;\n                    float4 _1227 = fa_light_texel(param_46);\n                    if (_1199)\n                    {\n                        float3 _1235 = -to_light;\n                        float _1242 = _1213.w;\n                        float _1258 = 0.5f / max(dot(_1235, _1217) * (sqrt(max(1.0f - (_1242 * _1242), 0.0f)) / max(_1242, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1191.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1235, _1222.xyz) * _1258), 0.5f - (dot(_1235, _1227.xyz) * _1258));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1196.z > 0.5f)\n                    {\n                        float2 param_49 = _1196.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1217;\n                        float3 param_52 = _1222.xyz;\n                        float3 param_53 = _1227.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _5461 = _773.xyz * atten;\n    if (_764)\n    {\n        _5461 *= fa_light_tint;\n    }\n    int _1326;\n    if (_790)\n    {\n        _1326 = 0;\n    }\n    else\n    {\n        _1326 = ((_776 > 1.5f) && (_776 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _5472 = { l, _5461, atten, 1.0f, dist, _1326 };\n    return _5472;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2120 = fa_shadow_depth(param, param_1);\n    float _2124;\n    if (conv.x < 0.5f)\n    {\n        _2124 = _2120;\n    }\n    else\n    {\n        _2124 = (conv.y * conv.z) / (conv.z - (_2120 * (conv.z - conv.y)));\n    }\n    return _2124;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2051 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2051), sin(_2051)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2170 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2179;\n        if (k < 0.0f)\n        {\n            _2179 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2179 = k;\n        }\n        float _2199 = clamp((_2179 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2170;\n            float2 _2218 = fa_shadow_vogel(param_3, param_4, param_5) * _2199;\n            float2 param_6 = uv + (_2218 * _2073_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2230 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2230 < (zr - (length(_2218) * plane)))\n            {\n                sum += _2230;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2256 = sum / cnt;\n        float _2266;\n        if (k < 0.0f)\n        {\n            _2266 = (-k) / max(_2256, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2266 = k;\n        }\n        radius = clamp(((max(zr - _2256, 0.0f) * unit) * _2266) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2288 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2288; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2288;\n        float param_11 = _2170;\n        float2 _2307 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2307 * _2073_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2307) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2288);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2507 = _416_fa_pbr.z < 0.5f;\n    bool _2514;\n    if (!_2507)\n    {\n        _2514 = _2073_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2514 = _2507;\n    }\n    if (_2514)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2073_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2527 = fa_light_texel(param);\n    float _2528 = _2527.x;\n    if (_2528 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2537 = int(_2528 + 0.5f);\n    int param_1 = _2537;\n    float4 _2541 = fa_light_texel(param_1);\n    int param_2 = _2537 + 1;\n    float4 _2546 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2549 = _2541.y;\n    if (_2549 > 0.0f)\n    {\n        float _2566 = 1.0f - smoothstep(0.75f * _2549, _2549, length(world - _2073_fa_shadow_eye.xyz));\n        fade = _2566;\n        if (_2566 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2541.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2590 = (_2537 + 2) + (face * 6);\n    int param_4 = _2590;\n    int param_5 = _2590 + 1;\n    int param_6 = _2590 + 3;\n    float4 _2604 = fa_light_texel(param_6);\n    int param_7 = _2590 + 4;\n    float4 _2609 = fa_light_texel(param_7);\n    int param_8 = _2590 + 5;\n    float4 _2614 = fa_light_texel(param_8);\n    float _2626 = _2614.x * max(dot(_2604, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2631 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2654 = clamp(dot(n, _2604.xyz), -1.0f, 1.0f);\n    float _2673 = min(sqrt(1.0f - (_2654 * _2654)) / max(abs(dot(n, world - lpos)) / max(dot(_2604, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2676 = _2546.y;\n    float _2678;\n    if (_2676 > 0.0f)\n    {\n        _2678 = _2676;\n    }\n    else\n    {\n        _2678 = 1.5f * _2626;\n    }\n    float4 _2698 = float4(world + (n * (_2678 * sqrt(1.0f - (_2631 * _2631)))), 1.0f);\n    float _2702 = dot(_2604, _2698);\n    float _2705 = _2614.y;\n    if (_2702 < _2705)\n    {\n        return 1.0f;\n    }\n    float2 _2720 = float2(dot(fa_light_texel(param_4), _2698), dot(fa_light_texel(param_5), _2698)) / _2702.xx;\n    float _2722 = _2720.x;\n    bool _2725 = _2722 < _2609.x;\n    bool _2734;\n    if (!_2725)\n    {\n        _2734 = _2722 > _2609.z;\n    }\n    else\n    {\n        _2734 = _2725;\n    }\n    bool _2743;\n    if (!_2734)\n    {\n        _2743 = _2720.y < _2609.y;\n    }\n    else\n    {\n        _2743 = _2734;\n    }\n    bool _2752;\n    if (!_2743)\n    {\n        _2752 = _2720.y > _2609.w;\n    }\n    else\n    {\n        _2752 = _2743;\n    }\n    if (_2752)\n    {\n        return 1.0f;\n    }\n    float _2758 = _2546.x;\n    float _2760;\n    if (_2758 > 0.0f)\n    {\n        _2760 = _2758;\n    }\n    else\n    {\n        _2760 = 1.5f * _2626;\n    }\n    float2 param_9 = _2720;\n    float4 param_10 = _2609;\n    float param_11 = _2702 - (_2760 * (1.0f + (0.5f * _2673)));\n    float param_12 = _2626;\n    float param_13 = 1.0f;\n    float param_14 = _2614.z * 0.25f;\n    float param_15 = (_2626 * min(_2673, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2705, _2614.z);\n    int param_17 = int(_2541.z + 0.5f);\n    float param_18 = _2541.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2063;\n    if (i == 0)\n    {\n        _2063 = _2073_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2079;\n        if (i == 1)\n        {\n            _2079 = _2073_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2087;\n            if (i == 2)\n            {\n                _2087 = _2073_fa_shadow_split.z;\n            }\n            else\n            {\n                _2087 = _2073_fa_shadow_split.w;\n            }\n            _2079 = _2087;\n        }\n        _2063 = _2079;\n    }\n    return _2063;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2349 = max(_2073_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2354 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2360 = sqrt(1.0f - (_2354 * _2354));\n    float _2367 = min(_2360 / max(_2354, 0.20000000298023223876953125f), 4.0f);\n    float _2372;\n    if (_2073_fa_shadow_bias.y > 0.0f)\n    {\n        _2372 = _2073_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2372 = 1.5f * _2073_fa_shadow_info[ci].x;\n    }\n    float4 _2397 = mul(float4(world + (n * (_2372 * _2360)), 1.0f), _2073_fa_shadow_mat[ci]);\n    float _2404 = _2397.x;\n    bool _2407 = _2404 < _2073_fa_shadow_rect[ci].x;\n    bool _2416;\n    if (!_2407)\n    {\n        _2416 = _2404 > _2073_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2416 = _2407;\n    }\n    bool _2425;\n    if (!_2416)\n    {\n        _2425 = _2397.y < _2073_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2425 = _2416;\n    }\n    bool _2434;\n    if (!_2425)\n    {\n        _2434 = _2397.y > _2073_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2434 = _2425;\n    }\n    bool _2441;\n    if (!_2434)\n    {\n        _2441 = _2397.z > 1.0f;\n    }\n    else\n    {\n        _2441 = _2434;\n    }\n    if (_2441)\n    {\n        return -1.0f;\n    }\n    float _2449;\n    if (_2073_fa_shadow_bias.x > 0.0f)\n    {\n        _2449 = _2073_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2449 = 1.5f * _2073_fa_shadow_info[ci].x;\n    }\n    float2 param = _2397.xy;\n    float4 param_1 = _2073_fa_shadow_rect[ci];\n    float param_2 = _2397.z - ((_2449 * (1.0f + (0.5f * _2367))) / _2349);\n    float param_3 = _2073_fa_shadow_info[ci].x;\n    float param_4 = _2349;\n    float param_5 = _2349 * 0.25f;\n    float param_6 = ((_2073_fa_shadow_info[ci].x * min(_2367, 3.0f)) * 0.5f) / _2349;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2073_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2073_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_416_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2827 = int(_2073_fa_shadow_cfg.x + 0.5f);\n    if (_2827 < 1)\n    {\n        return 1.0f;\n    }\n    float _2842 = dot(world - _2073_fa_shadow_eye.xyz, _2073_fa_shadow_fwd.xyz);\n    int param = _2827 - 1;\n    if (_2842 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2854 = _2827 > 1;\n    bool _2861;\n    if (_2854)\n    {\n        _2861 = _2842 > _2073_fa_shadow_split.x;\n    }\n    else\n    {\n        _2861 = _2854;\n    }\n    if (_2861)\n    {\n        ci = 1;\n    }\n    bool _2865 = _2827 > 2;\n    bool _2872;\n    if (_2865)\n    {\n        _2872 = _2842 > _2073_fa_shadow_split.y;\n    }\n    else\n    {\n        _2872 = _2865;\n    }\n    if (_2872)\n    {\n        ci = 2;\n    }\n    bool _2876 = _2827 > 3;\n    bool _2883;\n    if (_2876)\n    {\n        _2883 = _2842 > _2073_fa_shadow_split.z;\n    }\n    else\n    {\n        _2883 = _2876;\n    }\n    if (_2883)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2827)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2909 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2909;\n        if (_2909 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2073_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2934;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2934 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2934 = _2073_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2953 = _2073_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2934, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2964 = clamp((_2842 - (fa_shadow_split_at(param_7) - _2953)) / _2953, 0.0f, 1.0f);\n        if (_2964 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2827)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2985 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2985;\n                if (_2985 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2964);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3434 = _416_fa_ct_a.x < 0.5f;\n    bool _3441;\n    if (!_3434)\n    {\n        _3441 = _2073_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3441 = _3434;\n    }\n    if (_3441)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2073_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3454 = fa_light_texel(param);\n    float _3455 = _3454.y;\n    float len = _3455;\n    if (_3455 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3467 = length(world - _416_fa_camera_pos.xyz);\n    float _3477 = 1.0f - smoothstep(0.5f * _416_fa_ct_b.x, _416_fa_ct_b.x, _3467);\n    if (_3477 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3483 = len;\n    float _3486 = min(_3483, 0.89999997615814208984375f * dist);\n    len = _3486;\n    float _3492 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3467);\n    float _3497 = _3492 + (0.5f * _3486);\n    float3 _3503 = world + (gn * _3492);\n    float _3505 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _3570;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3521 = (float(k) + _3505) * 0.083333335816860198974609375f;\n        float3 _3529 = _3503 + (l * (_3521 * len));\n        float4 _3535 = float4(_3529, 1.0f);\n        float _3541 = dot(_416_fa_ct_vpw, _3535);\n        if (_3541 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _3561 = float2(dot(_416_fa_ct_vpx, _3535), dot(_416_fa_ct_vpy, _3535)) / _3541.xx;\n        float _3565 = _3561.x * 0.5f;\n        float _3566 = _3565 + 0.5f;\n        if (_416_fa_ct_a.y > 0.5f)\n        {\n            _3570 = (_3561.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _3570 = 0.5f - (_3561.y * 0.5f);\n        }\n        bool _3586 = _3566 < 0.0f;\n        bool _3593;\n        if (!_3586)\n        {\n            _3593 = _3566 >= 1.0f;\n        }\n        else\n        {\n            _3593 = _3586;\n        }\n        bool _3600;\n        if (!_3593)\n        {\n            _3600 = _3570 < 0.0f;\n        }\n        else\n        {\n            _3600 = _3593;\n        }\n        bool _3607;\n        if (!_3600)\n        {\n            _3607 = _3570 >= 1.0f;\n        }\n        else\n        {\n            _3607 = _3600;\n        }\n        if (_3607)\n        {\n            break;\n        }\n        float4 _3626 = fa_screen_tex.Load(int3(int2(float2(_3566, _3570) * _416_fa_ct_a.zw), 0));\n        if (_3626.w < 0.5f)\n        {\n            continue;\n        }\n        float _3645 = (dot(_416_fa_ct_fwd.xyz, _3529) + _416_fa_ct_fwd.w) - _3626.x;\n        if ((_3645 > _3492) && (_3645 < _3497))\n        {\n            occ = max(occ, (1.0f - (_3521 * _3521)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_3566, 0.5f - _3565), min(_3570, 1.0f - _3570))));\n        }\n    }\n    return 1.0f - (occ * _3477);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _3748 = fa_baked_keep(param);\n    if (_3748 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _5485 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _5485;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3774 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _5487 = _3774.color;\n    float _5488 = _3774.attenuation;\n    float _5489 = _3774.shadow;\n    bool _3777 = _3774.type == 0;\n    if (_3777 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3774.direction;\n        float _3788 = fa_shadow_factor(param_5, param_6);\n        _5489 = _3788;\n        _5487 *= _3788;\n    }\n    else\n    {\n        bool _3799 = _3774.type != 0;\n        bool _3805;\n        if (_3799)\n        {\n            _3805 = _5488 > 0.0f;\n        }\n        else\n        {\n            _3805 = _3799;\n        }\n        if (_3805)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3774.direction;\n            float _3824 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5489 = _3824;\n            _5487 *= _3824;\n        }\n    }\n    bool _3834 = _416_fa_ct_a.x > 0.5f;\n    bool _3840;\n    if (_3834)\n    {\n        _3840 = _5488 > 0.0f;\n    }\n    else\n    {\n        _3840 = _3834;\n    }\n    if (_3840)\n    {\n        float _3847;\n        if (_3777)\n        {\n            _3847 = 1000000000.0f;\n        }\n        else\n        {\n            _3847 = _3774._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3774.direction;\n        float param_18 = _3847;\n        float _3865 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5489 *= _3865;\n        _5487 *= _3865;\n    }\n    float _3878 = _5488;\n    float _3879 = _3878 * _3748;\n    _5488 = _3879;\n    float3 _3883 = _5487;\n    float3 _3884 = _3883 * _3748;\n    _5487 = _3884;\n    LightSample _5504 = { _3774.direction, _3884, _3879, _5489, _3774._distance, _3774.type };\n    return _5504;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2073_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3009 = int(_2073_fa_shadow_cfg.x + 0.5f);\n    float _3019 = dot(world - _2073_fa_shadow_eye.xyz, _2073_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3024 = _3009 > 0;\n    bool _3033;\n    if (_3024)\n    {\n        int param = _3009 - 1;\n        _3033 = _3019 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3033 = _3024;\n    }\n    if (_3033)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3039 = _3009 > 1;\n        bool _3046;\n        if (_3039)\n        {\n            _3046 = _3019 > _2073_fa_shadow_split.x;\n        }\n        else\n        {\n            _3046 = _3039;\n        }\n        if (_3046)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3052 = _3009 > 2;\n        bool _3059;\n        if (_3052)\n        {\n            _3059 = _3019 > _2073_fa_shadow_split.y;\n        }\n        else\n        {\n            _3059 = _3052;\n        }\n        if (_3059)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3065 = _3009 > 3;\n        bool _3072;\n        if (_3065)\n        {\n            _3072 = _3019 > _2073_fa_shadow_split.z;\n        }\n        else\n        {\n            _3072 = _3065;\n        }\n        if (_3072)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5308 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5308 = -_5308;\n    }\n    float3 _4883 = normalize(_416_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5321 = { fa_world_pos, _5308, fa_world_tangent, fa_uv, fa_vertex_color, _4883, gl_FrontFacing };\n    SurfaceInput param_1 = _5321;\n    Surface _4891 = fa_standard_surface(param_1);\n    float3 _5339 = _4891.albedo;\n    float _5340 = _4891.alpha;\n    float3 _5341 = _4891.normal;\n    float _5342 = _4891.metallic;\n    float _5343 = _4891.roughness;\n    float _5344 = _4891.occlusion;\n    float3 _5345 = _4891.emission;\n    float _5346 = _4891.clearcoat;\n    float _5347 = _4891.clearcoat_roughness;\n    float3 _5348 = _4891.sheen_color;\n    float _5349 = _4891.sheen_roughness;\n    float _5350 = _4891.anisotropy;\n    float _5351 = _4891.anisotropy_rotation;\n    float _5352 = _4891.specular;\n    float _5353 = _4891.ior;\n    float3 _5354 = _4891.specular_color;\n    float _5355 = _4891.transmission;\n    float _5356 = _4891.thickness;\n    float3 _5357 = _4891.attenuation_color;\n    float _5358 = _4891.attenuation_distance;\n    SurfaceInput _5329 = { fa_world_pos, _5308, fa_world_tangent, fa_uv, fa_vertex_color, _4883, gl_FrontFacing };\n    SurfaceInput param_2 = _5329;\n    Surface param_3 = _4891;\n    surface(param_2, param_3);\n    _5339 = param_3.albedo;\n    _5340 = param_3.alpha;\n    _5341 = param_3.normal;\n    _5342 = param_3.metallic;\n    _5343 = param_3.roughness;\n    _5344 = param_3.occlusion;\n    _5345 = param_3.emission;\n    _5346 = param_3.clearcoat;\n    _5347 = param_3.clearcoat_roughness;\n    _5348 = param_3.sheen_color;\n    _5349 = param_3.sheen_roughness;\n    _5350 = param_3.anisotropy;\n    _5351 = param_3.anisotropy_rotation;\n    _5352 = param_3.specular;\n    _5353 = param_3.ior;\n    _5354 = param_3.specular_color;\n    _5355 = param_3.transmission;\n    _5356 = param_3.thickness;\n    _5357 = param_3.attenuation_color;\n    _5358 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5308;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5339 = param_6;\n    _5341 = param_7;\n    float3 result;\n    if (_416_fa_emissive.w > 0.5f)\n    {\n        result = _5339;\n    }\n    else\n    {\n        float3 _4930 = _5341;\n        float3 _4931 = normalize(_4930);\n        _5341 = _4931;\n        float3 param_8 = _4931;\n        float3 lit = (fa_indirect_diffuse(param_8) * _5339) * _5344;\n        int _4950 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4950; ln++)\n        {\n            int param_9 = ln;\n            int _4963 = fa_cl_light(param_9);\n            int param_10 = _4963;\n            if (fa_baked_keep(param_10) <= 0.0f)\n            {\n                continue;\n            }\n            int param_11 = _4963;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _5308;\n            LightSample _4979 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput _5337 = { fa_world_pos, _5308, fa_world_tangent, fa_uv, fa_vertex_color, _4883, gl_FrontFacing };\n            SurfaceInput param_14 = _5337;\n            Surface _5440 = { _5339, _5340, _5341, _5342, _5343, _5344, _5345, _5346, _5347, _5348, _5349, _5350, _5351, _5352, _5353, _5354, _5355, _5356, _5357, _5358 };\n            Surface param_15 = _5440;\n            LightSample param_16 = _4979;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _4994 = result;\n    float3 _4995 = _4994 + _5345;\n    result = _4995;\n    float3 param_17 = _4995;\n    float3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _5004 = _416_fa_fog.w > 0.0f;\n    bool _5011;\n    if (!_5004)\n    {\n        _5011 = _416_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5011 = _5004;\n    }\n    if (_5011)\n    {\n        float3 _5020 = fa_world_pos - _416_fa_camera_pos.xyz;\n        float _5026 = dot(_5020, _416_fa_fog_c.xyz);\n        bool _5030 = _416_fa_fog_c.w > 0.5f;\n        float _5031;\n        if (_5030)\n        {\n            _5031 = _5026;\n        }\n        else\n        {\n            _5031 = length(_5020);\n        }\n        float _5043 = _5031 - _416_fa_fog_b.x;\n        if (_5043 > 0.0f)\n        {\n            float _5052 = _416_fa_fog.w * _5043;\n            float tau = _5052 * _5052;\n            if (_416_fa_fog_b.y > 0.0f)\n            {\n                float _5068;\n                if (_5030)\n                {\n                    _5068 = fa_world_pos.y - (_416_fa_fog_c.y * _5026);\n                }\n                else\n                {\n                    _5068 = _416_fa_camera_pos.y;\n                }\n                float _5089 = lerp(_5068, fa_world_pos.y, clamp(_416_fa_fog_b.x / _5031, 0.0f, 1.0f));\n                float _5093 = fa_world_pos.y - _5089;\n                float _5098 = _5089 - _416_fa_fog_b.z;\n                float _5103 = fa_world_pos.y - _416_fa_fog_b.z;\n                bool _5106 = _5098 <= 0.0f;\n                bool _5107 = !_5106;\n                bool _5113;\n                if (_5107)\n                {\n                    _5113 = _416_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5113 = _5106;\n                }\n                float _5114;\n                if (_5113)\n                {\n                    _5114 = _416_fa_fog_b.y;\n                }\n                else\n                {\n                    _5114 = _416_fa_fog_b.y * exp(-min(_416_fa_fog_b.w * _5098, 80.0f));\n                }\n                bool _5141;\n                if (_5107)\n                {\n                    _5141 = _416_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5141 = _5106;\n                }\n                float _5142;\n                if (_5141)\n                {\n                    _5142 = _416_fa_fog_b.y * _5098;\n                }\n                else\n                {\n                    _5142 = (_416_fa_fog_b.y * (1.0f - exp(-min(_416_fa_fog_b.w * _5098, 80.0f)))) / _416_fa_fog_b.w;\n                }\n                bool _5167 = _5103 <= 0.0f;\n                bool _5174;\n                if (!_5167)\n                {\n                    _5174 = _416_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5174 = _5167;\n                }\n                float _5175;\n                if (_5174)\n                {\n                    _5175 = _416_fa_fog_b.y * _5103;\n                }\n                else\n                {\n                    _5175 = (_416_fa_fog_b.y * (1.0f - exp(-min(_416_fa_fog_b.w * _5103, 80.0f)))) / _416_fa_fog_b.w;\n                }\n                float _5202;\n                if (abs(_5093) < 0.001000000047497451305389404296875f)\n                {\n                    _5202 = _5114;\n                }\n                else\n                {\n                    _5202 = (_5175 - _5142) / _5093;\n                }\n                tau += (_5043 * max(_5202, 0.0f));\n            }\n            result = lerp(result, _416_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5340);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_416",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _416_fa_camera_pos : packoffset(c0);\n    float4 _416_fa_ambient : packoffset(c1);\n    float4 _416_fa_base_color : packoffset(c2);\n    float4 _416_fa_emissive : packoffset(c3);\n    float4 _416_fa_model_emissive : packoffset(c4);\n    float4 _416_fa_pbr : packoffset(c5);\n    float4 _416_fa_maps : packoffset(c6);\n    float4 _416_fa_fog : packoffset(c7);\n    float4 _416_fa_fog_b : packoffset(c8);\n    float4 _416_fa_fog_c : packoffset(c9);\n    float4 _416_fa_counts : packoffset(c10);\n    float4 _416_fa_env_sky : packoffset(c11);\n    float4 _416_fa_env_horizon : packoffset(c12);\n    float4 _416_fa_time : packoffset(c13);\n    float4 _416_fa_cl_vpx : packoffset(c14);\n    float4 _416_fa_cl_vpy : packoffset(c15);\n    float4 _416_fa_cl_vpw : packoffset(c16);\n    float4 _416_fa_cl_fwd : packoffset(c17);\n    float4 _416_fa_cl_grid : packoffset(c18);\n    float4 _416_fa_cl_info : packoffset(c19);\n    float4 _416_fa_layers_a : packoffset(c20);\n    float4 _416_fa_layers_b : packoffset(c21);\n    float4 _416_fa_layers_c : packoffset(c22);\n    float4 _416_fa_layers_d : packoffset(c23);\n    float4 _416_fa_ct_a : packoffset(c24);\n    float4 _416_fa_ct_b : packoffset(c25);\n    float4 _416_fa_ct_vpx : packoffset(c26);\n    float4 _416_fa_ct_vpy : packoffset(c27);\n    float4 _416_fa_ct_vpw : packoffset(c28);\n    float4 _416_fa_ct_fwd : packoffset(c29);\n    float4 _416_fa_tr_a : packoffset(c30);\n    float4 _416_fa_tr_b : packoffset(c31);\n    float4 _416_fa_probe_sh[9] : packoffset(c32);\n    float4 _416_fa_atlas : packoffset(c41);\n    float4 _416_fa_rpa_tile : packoffset(c42);\n    float4 _416_fa_rpa_pos : packoffset(c43);\n    float4 _416_fa_rpa_bx : packoffset(c44);\n    float4 _416_fa_rpa_by : packoffset(c45);\n    float4 _416_fa_rpa_bz : packoffset(c46);\n    float4 _416_fa_rpb_tile : packoffset(c47);\n    float4 _416_fa_rpb_pos : packoffset(c48);\n    float4 _416_fa_rpb_bx : packoffset(c49);\n    float4 _416_fa_rpb_by : packoffset(c50);\n    float4 _416_fa_rpb_bz : packoffset(c51);\n    float4 _416_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2073_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2073_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2073_fa_shadow_info[4] : packoffset(c20);\n    float4 _2073_fa_shadow_split : packoffset(c24);\n    float4 _2073_fa_shadow_cfg : packoffset(c25);\n    float4 _2073_fa_shadow_bias : packoffset(c26);\n    float4 _2073_fa_shadow_eye : packoffset(c27);\n    float4 _2073_fa_shadow_fwd : packoffset(c28);\n    float4 _2073_fa_shadow_lcfg : packoffset(c29);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t10);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_screen_tex : register(t11);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\nTexture2D<float4> fa_lightmap : register(t9);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1344 = _416_fa_cl_info.x < 0.0f;\n    bool _1351;\n    if (!_1344)\n    {\n        _1351 = _416_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1351 = _1344;\n    }\n    bool _1359;\n    if (!_1351)\n    {\n        _1359 = _416_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1359 = _1351;\n    }\n    bool _1366;\n    if (!_1359)\n    {\n        _1366 = _416_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1366 = _1359;\n    }\n    bool _1373;\n    if (!_1366)\n    {\n        _1373 = _416_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1373 = _1366;\n    }\n    if (_1373)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1383 = float4(world_pos, 1.0f);\n    float _1389 = dot(_416_fa_cl_vpw, _1383);\n    if (!(_1389 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1411 = float2(dot(_416_fa_cl_vpx, _1383), dot(_416_fa_cl_vpy, _1383)) / _1389.xx;\n    int _1415 = int(_416_fa_cl_grid.x);\n    int _1419 = int(_416_fa_cl_grid.y);\n    int param = (int(_416_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_416_fa_cl_fwd.xyz, world_pos) + _416_fa_cl_fwd.w, _416_fa_cl_grid.w) / _416_fa_cl_grid.w) * _416_fa_cl_grid.z)), 0, int(_416_fa_cl_info.y) - 1) * _1419) + clamp(int(floor(((_1411.y * 0.5f) + 0.5f) * _416_fa_cl_grid.y)), 0, _1419 - 1)) * _1415)) + clamp(int(floor(((_1411.x * 0.5f) + 0.5f) * _416_fa_cl_grid.x)), 0, _1415 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1495 = fa_cluster_texel(param);\n    return int2(int(_1495.x), int(_1495.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_416_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _3722 = fa_cluster_lookup(param);\n    fa_cl_slot = _3722.x;\n    fa_cl_local = _3722.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _3927 = fa_linear_to_srgb(param);\n        c = _3927;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _3935 = fa_srgb_to_linear(param_1);\n            c = _3935;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _298;\n    if (i.front_facing)\n    {\n        _298 = i.world_normal;\n    }\n    else\n    {\n        _298 = -i.world_normal;\n    }\n    float3 _322 = normalize(i.world_tangent.xyz - (_298 * dot(_298, i.world_tangent.xyz)));\n    float3 _349 = normalize(((_322 * m.x) + ((cross(_298, _322) * i.world_tangent.w) * m.y)) + (_298 * m.z));\n    float3 _352;\n    if (i.front_facing)\n    {\n        _352 = _349;\n    }\n    else\n    {\n        _352 = -_349;\n    }\n    return _352;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _416_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _3966 = fa_tex_fix(param_2, param_3);\n    float4 _5670 = base_t;\n    _5670.x = _3966.x;\n    _5670.y = _3966.y;\n    _5670.z = _3966.z;\n    base_t = _5670;\n    float4 _3980 = (_5670 * _416_fa_base_color) * i.vertex_color;\n    float3 _5507 = i.world_normal;\n    if (_416_fa_maps.z > 0.5f)\n    {\n        float param_4 = _416_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4012 = fa_tex_fix(param_6, param_7);\n        float3 _4015 = (_4012 * 2.0f) - 1.0f.xxx;\n        float2 _4020 = _4015.xy * _416_fa_maps.x;\n        float3 _5678 = _4015;\n        _5678.x = _4020.x;\n        _5678.y = _4020.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5678;\n        _5507 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _416_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4048 = fa_tex_fix(param_12, param_13);\n    float4 _5681 = mrt;\n    _5681.x = _4048.x;\n    _5681.y = _4048.y;\n    _5681.z = _4048.z;\n    mrt = _5681;\n    float4 _4076 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _416_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4076.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4087 = fa_tex_fix(param_16, param_17);\n    float param_18 = _416_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4117 = fa_tex_fix(param_20, param_21);\n    float _5512 = _416_fa_layers_a.x;\n    float _5513 = _416_fa_layers_a.y;\n    float _5516 = _416_fa_layers_a.z;\n    float _5515 = _416_fa_layers_b.w;\n    float _5518 = _416_fa_layers_c.x;\n    if (_416_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_416_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _5512 *= _4087.y;\n            _5513 *= _4087.z;\n            _5515 *= _4076.w;\n        }\n        if (_416_fa_layers_c.z > 1.5f)\n        {\n            _5516 *= mrt.x;\n            _5518 *= mrt.w;\n        }\n    }\n    Surface _5545 = { _3980.xyz, _3980.w, _5507, clamp(_416_fa_pbr.x * _4048.z, 0.0f, 1.0f), clamp(_416_fa_pbr.y * _4048.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_416_fa_maps.y * (_4087.x - 1.0f)), _416_fa_emissive.xyz + (_416_fa_model_emissive.xyz * _4117), _5512, _5513, _416_fa_layers_b.xyz, _5515, _5516, _416_fa_layers_a.w, _5518, _416_fa_layers_c.y, _416_fa_layers_d.xyz, _416_fa_tr_a.x, _416_fa_tr_a.y, _416_fa_tr_b.xyz, _416_fa_tr_a.z };\n    return _5545;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1575 = rect.zw - rect.xy;\n    float2 _1579 = _1575 * atlas;\n    float2 _1583 = ddx * _1579;\n    float2 _1587 = ddy * _1579;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1575), clamp(0.5f * log2(max(max(dot(_1583, _1583), dot(_1587, _1587)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1620 = _416_fa_counts.y < 0.5f;\n    bool _1627;\n    if (!_1620)\n    {\n        _1627 = _416_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1627 = _1620;\n    }\n    if (_1627)\n    {\n        return;\n    }\n    float3 _1633 = ddx(world_pos);\n    float3 _1636 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1640 = fa_cluster_texel(param);\n    int _1644 = int(_1640.w);\n    if (_1644 < 1)\n    {\n        return;\n    }\n    int _1654 = int(_416_fa_counts.y + 0.5f);\n    int param_1 = _1654;\n    float4 _1658 = fa_light_texel(param_1);\n    float2 _1661 = _1658.yz;\n    int _1665 = int(_1658.w);\n    int param_2 = _1654 + 1;\n    float4 _1670 = fa_light_texel(param_2);\n    float _1671 = _1670.x;\n    int _1677 = int(_416_fa_counts.w + 0.5f) - 1;\n    int _1681 = int(_1640.z);\n    float3 _1946;\n    for (int k = 0; k < _1644; k++)\n    {\n        int _1694 = _1681 + k;\n        int param_3 = _1665 + (_1694 >> 2);\n        int _1711 = (_1654 + 2) + (int(fa_light_texel(param_3)[_1694 & 3]) * 7);\n        int param_4 = _1711 + 6;\n        float4 _1716 = fa_light_texel(param_4);\n        if (((int(_1716.w + 0.5f) >> _1677) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1711;\n        float4 _1731 = fa_light_texel(param_5);\n        int param_6 = _1711 + 1;\n        float4 _1736 = fa_light_texel(param_6);\n        int param_7 = _1711 + 2;\n        float4 _1741 = fa_light_texel(param_7);\n        float3 _1744 = _1731.xyz;\n        float _1749 = dot(_1744, world_pos) + _1731.w;\n        float3 _1751 = _1736.xyz;\n        float _1756 = dot(_1751, world_pos) + _1736.w;\n        float3 _1758 = _1741.xyz;\n        float _1763 = dot(_1758, world_pos) + _1741.w;\n        bool _1768 = abs(_1749) > 0.5f;\n        bool _1776;\n        if (!_1768)\n        {\n            _1776 = abs(_1756) > 0.5f;\n        }\n        else\n        {\n            _1776 = _1768;\n        }\n        bool _1784;\n        if (!_1776)\n        {\n            _1784 = abs(_1763) > 0.5f;\n        }\n        else\n        {\n            _1784 = _1776;\n        }\n        if (_1784)\n        {\n            continue;\n        }\n        float _1799 = clamp(dot(geo_normal, normalize(_1758)) * _1716.z, 0.0f, 1.0f);\n        if (_1799 <= 0.0f)\n        {\n            continue;\n        }\n        float _1819 = (clamp((0.5f - abs(_1763)) * 10.0f, 0.0f, 1.0f) * _1799) * _1716.x;\n        float2 _1827 = float2(_1749 + 0.5f, 0.5f - _1756);\n        float2 _1837 = float2(dot(_1744, _1633), dot(_1751, _1633));\n        float2 _1847 = float2(dot(_1744, _1636), dot(_1751, _1636));\n        int param_8 = _1711 + 5;\n        float4 _1852 = fa_light_texel(param_8);\n        int param_9 = _1711 + 3;\n        float4 _1857 = fa_light_texel(param_9);\n        int param_10 = _1711 + 4;\n        float4 _1862 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1852.xyz;\n        bool _1872 = _1857.z > _1857.x;\n        if (_1872)\n        {\n            float4 param_11 = _1857;\n            float2 param_12 = _1827;\n            float2 param_13 = _1661;\n            float2 param_14 = _1837;\n            float2 param_15 = _1847;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1671 > 0.5f) && (_1671 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1898 = fa_dc_to_linear(param_16);\n                float4 _5595 = tx;\n                _5595.x = _1898.x;\n                _5595.y = _1898.y;\n                _5595.z = _1898.z;\n                tx = _5595;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1819 * tex_a) * _1852.w, 0.0f, 1.0f).xxx);\n        if (_1862.z > _1862.x)\n        {\n            float4 param_17 = _1862;\n            float2 param_18 = _1827;\n            float2 param_19 = _1661;\n            float2 param_20 = _1837;\n            float2 param_21 = _1847;\n            float4 _1942 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1671 > 1.5f)\n            {\n                float3 param_22 = _1942.xyz;\n                float3 _1952 = fa_dc_to_srgb(param_22);\n                _1946 = _1952;\n            }\n            else\n            {\n                _1946 = _1942.xyz;\n            }\n            float3 _1961 = (_1946 * 2.0f) - 1.0f.xxx;\n            float2 _1966 = _1961.xy * _1716.y;\n            float3 _1988 = (normalize(_1744) * _1966.x) + (normalize(_1751) * _1966.y);\n            float3 _1991 = normalize(normal);\n            normal = normalize(lerp(_1991, normalize((_1991 * max(_1961.z, 0.0500000007450580596923828125f)) + (_1988 - (_1991 * dot(_1991, _1988)))), clamp(_1819 * (_1872 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nfloat3 fa_sh_eval(float3 c[9], float3 n)\n{\n    float3 _3186 = max((((c[0] * 0.2820948064327239990234375f) + (((c[1] * (0.3257350027561187744140625f * n.y)) + (c[2] * (0.3257350027561187744140625f * n.z))) + (c[3] * (0.3257350027561187744140625f * n.x)))) + (((c[4] * ((0.2731371223926544189453125f * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125f * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125f * (((3.0f * n.z) * n.z) - 1.0f))))) + ((c[7] * ((0.2731371223926544189453125f * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625f * ((n.x * n.x) - (n.y * n.y))))), 0.0f.xxx);\n    return _3186;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3245_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3245_dummy_parameter)));\n}\n\nfloat4 fa_gi_fetch(float2 texel)\n{\n    return fa_probe_atlas.SampleLevel(fa_env_smp, texel / fa_atlas_size(), 0.0f);\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3206 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3209 = _3206.x;\n    float _3211 = _3206.z;\n    float2 e = float2(_3209, _3211);\n    if (_3206.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3211)) * ((_3209 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3209)) * ((_3211 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat3 fa_gi_grid(int rec, float3 n, float3 v, out float cover)\n{\n    cover = 0.0f;\n    int param = rec;\n    float4 _4231 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    float4 _4236 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    float4 _4241 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    float4 _4246 = fa_light_texel(param_3);\n    bool _4249 = _4246.z < 0.5f;\n    bool _4257;\n    if (!_4249)\n    {\n        _4257 = fa_atlas_size().y < 1155.0f;\n    }\n    else\n    {\n        _4257 = _4249;\n    }\n    if (_4257)\n    {\n        return 0.0f.xxx;\n    }\n    float _4264 = max(_4231.w, 9.9999997473787516355514526367188e-05f);\n    float3 _4267 = _4236.xyz;\n    float3 _4271 = _4231.xyz;\n    float3 _4275 = (fa_world_pos - _4271) / _4264.xxx;\n    float3 _4284 = min(_4275 + 0.5f.xxx, (_4267 - 0.5f.xxx) - _4275);\n    float _4293 = min(_4284.x, min(_4284.y, _4284.z));\n    if (!(_4293 > 0.0f))\n    {\n        return 0.0f.xxx;\n    }\n    float3 _4308 = _4267 - 1.0f.xxx;\n    float3 _4309 = clamp(_4275, 0.0f.xxx, _4308);\n    float3 _4317 = min(floor(_4309), max(_4267 - 2.0f.xxx, 0.0f.xxx));\n    float3 _4321 = _4309 - _4317;\n    float3 _4333 = fa_world_pos + (((n * 0.800000011920928955078125f) + (v * 0.20000000298023223876953125f)) * (0.20000000298023223876953125f * _4264));\n    int _4338 = int(_4241.y + 0.5f);\n    float3 sh[9];\n    for (int k = 0; k < 9; k++)\n    {\n        sh[k] = 0.0f.xxx;\n    }\n    float wsum = 0.0f;\n    int _4356 = int(_4246.w);\n    int _4357 = 8 + _4356;\n    int _4362 = 9 + _4356;\n    float _4389;\n    float _4402;\n    float _4416;\n    for (int k_1 = 0; k_1 < _4357; k_1++)\n    {\n        float _4375 = float(k_1 & 1);\n        float _4379 = float((k_1 >> 1) & 1);\n        float _4383 = float((k_1 >> 2) & 1);\n        if (_4375 > 0.5f)\n        {\n            _4389 = _4321.x;\n        }\n        else\n        {\n            _4389 = 1.0f - _4321.x;\n        }\n        if (_4379 > 0.5f)\n        {\n            _4402 = _4321.y;\n        }\n        else\n        {\n            _4402 = 1.0f - _4321.y;\n        }\n        if (_4383 > 0.5f)\n        {\n            _4416 = _4321.z;\n        }\n        else\n        {\n            _4416 = 1.0f - _4321.z;\n        }\n        float _4426 = (_4389 * _4402) * _4416;\n        if (!(_4426 > 0.0f))\n        {\n            continue;\n        }\n        float3 _4439 = min(_4317 + float3(_4375, _4379, _4383), _4308);\n        int _4459 = int(((_4241.x + _4439.x) + (_4236.x * (_4439.y + (_4236.y * _4439.z)))) + 0.5f);\n        float2 _4474 = float2(float(_4459 % _4338) * 10.0f, 1024.0f + (float(_4459 / _4338) * 11.0f));\n        float2 param_4 = _4474 + float2(9.5f, 10.5f);\n        float4 _4482 = fa_gi_fetch(param_4);\n        bool _4485 = _4482.y < 0.5f;\n        bool _4494;\n        if (!_4485)\n        {\n            _4494 = _4482.x > _4246.y;\n        }\n        else\n        {\n            _4494 = _4485;\n        }\n        if (_4494)\n        {\n            continue;\n        }\n        float3 _4506 = _4333 - (_4271 + (_4439 * _4264));\n        float _4509 = length(_4506);\n        float3 _4515 = _4506 / max(_4509, 9.9999997473787516355514526367188e-05f).xxx;\n        float _4525 = max(9.9999997473787516355514526367188e-05f, (dot(-_4515, n) + 1.0f) * 0.5f);\n        float w = _4426 * (_4525 * _4525);\n        float3 param_5 = _4515;\n        float2 param_6 = (_4474 + 1.0f.xx) + (((fa_oct_encode(param_5) * 0.5f) + 0.5f.xx) * 8.0f);\n        float4 _4544 = fa_gi_fetch(param_6);\n        float _4551 = _4509 / max(_4241.z, 9.9999997473787516355514526367188e-05f);\n        float _4554 = _4544.x;\n        if (_4551 > _4554)\n        {\n            float _4567 = max(_4544.y - (_4554 * _4554), 0.0f);\n            float _4572 = _4551 - _4554;\n            float _4581 = _4567 / max(_4567 + (_4572 * _4572), 9.9999999600419720025001879548654e-13f);\n            w *= ((_4581 * _4581) * _4581);\n        }\n        if (!(w > 0.0f))\n        {\n            continue;\n        }\n        for (int c = 0; c < _4362; c++)\n        {\n            float2 param_7 = _4474 + float2(float(c) + 0.5f, 10.5f);\n            sh[c] += (fa_gi_fetch(param_7).xyz * w);\n        }\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06f))\n    {\n        return 0.0f.xxx;\n    }\n    for (int c_1 = 0; c_1 < 9; c_1++)\n    {\n        sh[c_1] /= wsum.xxx;\n    }\n    cover = smoothstep(0.0f, 1.0f, clamp(_4293 * 2.0f, 0.0f, 1.0f)) * smoothstep(0.0f, 0.0199999995529651641845703125f, wsum);\n    float _4662;\n    if (_416_fa_gi.z > 0.5f)\n    {\n        _4662 = _4246.x;\n    }\n    else\n    {\n        _4662 = 1.0f;\n    }\n    float3 param_8[9] = sh;\n    float3 param_9 = n;\n    return fa_sh_eval(param_8, param_9) * (_4241.w * _4662);\n}\n\nfloat3 fa_gi_light(float3 n, inout float left)\n{\n    left = 1.0f;\n    float3 acc = 0.0f.xxx;\n    float3 _4686 = normalize(_416_fa_camera_pos.xyz - fa_world_pos);\n    int _4691 = int(_416_fa_gi.x + 0.5f);\n    int _4696 = int(_416_fa_gi.y + 0.5f);\n    float param_3;\n    for (int k = 0; (k < _4696) && (k < 8); k++)\n    {\n        int param = _4691 + (4 * k);\n        float3 param_1 = n;\n        float3 param_2 = _4686;\n        float3 _4721 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _4726 = param_3 * left;\n        acc += (_4721 * _4726);\n        left -= _4726;\n        if (left < 0.001000000047497451305389404296875f)\n        {\n            left = 0.0f;\n            break;\n        }\n    }\n    return acc;\n}\n\nfloat3 fa_probe_sh_coef(float2 origin, float res, int k)\n{\n    float3 v = fa_probe_atlas.SampleLevel(fa_env_smp, (origin + float2(float(k) + 0.5f, res + 2.5f)) / fa_atlas_size(), 0.0f).xyz;\n    if (_416_fa_atlas.y > 0.5f)\n    {\n        v = (v - 0.5f.xxx) * 8.0f;\n    }\n    return v;\n}\n\nfloat3 fa_ambient_light(float3 n)\n{\n    float _3293 = (1.0f - _416_fa_rpa_tile.w) - _416_fa_rpb_tile.w;\n    float3 amb = 0.0f.xxx;\n    bool _3299 = _416_fa_env_sky.w > 0.5f;\n    float3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = 0.0f.xxx;\n    }\n    if (_3293 > 0.0005000000237487256526947021484375f)\n    {\n        if (_3299)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                float2 param = _416_fa_atlas.zw;\n                float param_1 = 128.0f;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3293;\n            }\n        }\n        else\n        {\n            amb = _416_fa_ambient.xyz * _3293;\n        }\n    }\n    bool _3352 = _416_fa_rpa_tile.w > 0.0f;\n    if (_3352)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            float2 param_3 = _416_fa_rpa_tile.xy;\n            float param_4 = _416_fa_rpa_tile.z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * _416_fa_rpa_tile.w);\n        }\n    }\n    bool _3383 = _416_fa_rpb_tile.w > 0.0f;\n    if (_3383)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            float2 param_6 = _416_fa_rpb_tile.xy;\n            float param_7 = _416_fa_rpb_tile.z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * _416_fa_rpb_tile.w);\n        }\n    }\n    if ((_3299 || _3352) || _3383)\n    {\n        float3 param_9[9] = c;\n        float3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nfloat3 fa_realtime_or_ambient(float3 n)\n{\n    if (_416_fa_gi.y > 0.5f)\n    {\n        float3 param = n;\n        float param_1;\n        float3 _4755 = fa_gi_light(param, param_1);\n        if (param_1 < 0.999000012874603271484375f)\n        {\n            float3 _4764;\n            if (param_1 > 0.0f)\n            {\n                float3 param_2 = n;\n                _4764 = _4755 + (fa_ambient_light(param_2) * param_1);\n            }\n            else\n            {\n                _4764 = _4755;\n            }\n            return _4764;\n        }\n    }\n    float3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nfloat3 fa_indirect_diffuse(float3 n)\n{\n    if (fa_lm.z > 0.5f)\n    {\n        return fa_lightmap.SampleLevel(fa_env_smp, fa_lm.xy, 0.0f).xyz;\n    }\n    if (_416_fa_probe_sh[0].w > 0.0f)\n    {\n        float3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = _416_fa_probe_sh[k].xyz;\n        }\n        float3 param[9] = c;\n        float3 param_1 = n;\n        float3 _4826 = fa_sh_eval(param, param_1);\n        if (_416_fa_probe_sh[0].w >= 1.0f)\n        {\n            return _4826;\n        }\n        float3 param_2 = n;\n        return lerp(fa_realtime_or_ambient(param_2), _4826, clamp(_416_fa_probe_sh[0].w, 0.0f, 1.0f).xxx);\n    }\n    float3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_416_fa_cl_info.x) + int(_416_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_416_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3692;\n    if (fa_lm.z > 0.5f)\n    {\n        _3692 = 0.0f;\n    }\n    else\n    {\n        _3692 = 1.0f - clamp(_416_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _3703 = _3692 < 1.0f;\n    bool _3709;\n    if (_3703)\n    {\n        int param = li;\n        _3709 = fa_light_baked(param);\n    }\n    else\n    {\n        _3709 = _3703;\n    }\n    return _3709 ? _3692 : 1.0f;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _594 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _607 = (c - (ru * hx)) - p;\n        float3 _613 = ru * (2.0f * hx);\n        float _619 = max(dot(_613, _613), 9.9999999392252902907785028219223e-09f);\n        float _623 = dot(_607, _613);\n        float t = clamp((-_623) / _619, 0.0f, 1.0f);\n        if (_594)\n        {\n            float _638 = dot(r, _613);\n            float _644 = _619 - (_638 * _638);\n            if (abs(_644) > (9.9999997473787516355514526367188e-06f * _619))\n            {\n                t = clamp(((dot(r, _607) * _638) - _623) / _644, 0.0f, 1.0f);\n            }\n        }\n        return (p + _607) + (_613 * t);\n    }\n    float3 q = p;\n    float _676 = dot(r, axis);\n    bool _684;\n    if (_594)\n    {\n        _684 = abs(_676) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _684 = _594;\n    }\n    if (_684)\n    {\n        float _694 = dot(c - p, axis) / _676;\n        if (_694 > 0.0f)\n        {\n            q = p + (r * _694);\n        }\n    }\n    float3 _707 = q - c;\n    float2 xy = float2(dot(_707, ru), dot(_707, uu));\n    if (shape > 0.5f)\n    {\n        float _722 = length(xy);\n        if (_722 > hx)\n        {\n            xy *= (hx / _722);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _475_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _475_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _514 = dot(d, right);\n    float _518 = dot(d, up);\n    float _529;\n    if (((_514 * _514) + (_518 * _518)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _529 = atan2(_518, _514) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _529 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_529 - floor(_529)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _364 = abs(d);\n    float _366 = _364.x;\n    float _368 = _364.y;\n    bool _369 = _366 >= _368;\n    bool _377;\n    if (_369)\n    {\n        _377 = _366 >= _364.z;\n    }\n    else\n    {\n        _377 = _369;\n    }\n    int _378;\n    if (_377)\n    {\n        _378 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _393;\n        if (_368 >= _364.z)\n        {\n            _393 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _393 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _378 = _393;\n    }\n    return _378;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _760 = fa_light_base(param);\n    bool _764 = _416_fa_ambient.w > 4.5f;\n    int param_1 = _760;\n    float4 _768 = fa_light_texel(param_1);\n    int param_2 = _760 + 1;\n    float4 _773 = fa_light_texel(param_2);\n    float _776 = _773.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _788 = _764 && (_776 > 2.5f);\n    fa_light_is_area = _788;\n    bool _790 = _776 < 0.5f;\n    float3 l;\n    if (_790)\n    {\n        l = normalize(_768.xyz);\n        if (_764)\n        {\n            int param_3 = _760 + 6;\n            float4 _804 = fa_light_texel(param_3);\n            if (_804.z > 0.5f)\n            {\n                int param_4 = _760 + 4;\n                float4 _814 = fa_light_texel(param_4);\n                int param_5 = _760 + 5;\n                float4 _819 = fa_light_texel(param_5);\n                float2 param_6 = _804.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _814.xyz) * _814.w, (-dot(world_pos, _819.xyz)) * _819.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _849 = _768.xyz;\n        float3 _851 = _849 - world_pos;\n        float3 to_light = _851;\n        float _854 = length(_851);\n        float reach = _854;\n        bool front = true;\n        if (_788)\n        {\n            int param_8 = _760 + 7;\n            reach = max(_854 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _760 + 4;\n            float4 _878 = fa_light_texel(param_9);\n            int param_10 = _760 + 5;\n            float4 _883 = fa_light_texel(param_10);\n            int param_11 = _760 + 6;\n            float4 _888 = fa_light_texel(param_11);\n            float _889 = _888.w;\n            int param_12 = _760 + 2;\n            float3 _896 = normalize(fa_light_texel(param_12).xyz);\n            bool _898 = _889 > 1.5f;\n            bool _906;\n            if (!_898)\n            {\n                _906 = dot(_896, to_light) < 0.0f;\n            }\n            else\n            {\n                _906 = _898;\n            }\n            front = _906;\n            float3 r = 0.0f.xxx;\n            float3 _915 = _416_fa_camera_pos.xyz - world_pos;\n            bool _919 = dot(n, n) > 0.5f;\n            bool _927;\n            if (_919)\n            {\n                _927 = dot(_915, _915) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _927 = _919;\n            }\n            if (_927)\n            {\n                r = reflect(-normalize(_915), normalize(n));\n            }\n            float3 param_13 = _849;\n            float3 param_14 = _896;\n            float3 param_15 = _878.xyz;\n            float3 param_16 = _883.xyz;\n            float param_17 = _878.w;\n            float param_18 = _883.w;\n            float param_19 = _889;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _963 = length(to_light);\n        dist = _963;\n        l = to_light / max(_963, 9.9999997473787516355514526367188e-05f).xxx;\n        float _977 = reach / max(_768.w, 0.001000000047497451305389404296875f);\n        float _983 = clamp(1.0f - (_977 * _977), 0.0f, 1.0f);\n        float _985;\n        if (front)\n        {\n            _985 = _983 * _983;\n        }\n        else\n        {\n            _985 = 0.0f;\n        }\n        atten = _985;\n        bool _996 = _776 < 2.5f;\n        if ((_776 > 1.5f) && _996)\n        {\n            int param_22 = _760 + 2;\n            float4 _1004 = fa_light_texel(param_22);\n            float _1014 = _1004.w;\n            int param_23 = _760 + 3;\n            float4 _1019 = fa_light_texel(param_23);\n            float _1020 = _1019.x;\n            float cos_inner = _1020;\n            if (_1020 > 1.5f)\n            {\n                cos_inner = lerp(_1014, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1014, cos_inner, dot(-l, normalize(_1004.xyz)));\n        }\n        if (_764 && (_776 < 1.5f))\n        {\n            int param_24 = _760 + 6;\n            float4 _1044 = fa_light_texel(param_24);\n            if (_1044.z > 0.5f)\n            {\n                float3 _1052 = -to_light;\n                int param_25 = _760 + 4;\n                int param_26 = _760 + 5;\n                float3 _1066 = fa_light_texel(param_25).xyz;\n                float3 _1070 = fa_light_texel(param_26).xyz;\n                float3 _1079 = float3(dot(_1052, _1066), dot(_1052, _1070), dot(_1052, cross(_1066, _1070)));\n                float3 param_27 = _1079;\n                int _1083 = fa_cube_face(param_27);\n                int param_28 = _1083;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1110 = float2(dot(_1079, cross(param_29, param_30)), dot(_1079, param_30)) / max(dot(_1079, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1114 = _1083 / 3;\n                float2 param_31 = _1044.xy + (float2(float(_1083 - (_1114 * 3)), float(_1114)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1110.x), 0.5f - (0.5f * _1110.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _760 + 7;\n            float4 _1144 = fa_light_texel(param_33);\n            if (_1144.z > 0.5f)\n            {\n                int param_34 = _760 + 2;\n                int param_35 = _760 + 4;\n                int param_36 = _760 + 5;\n                float2 param_37 = _1144.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_764 && _996)\n            {\n                int param_42 = _760 + 6;\n                float4 _1191 = fa_light_texel(param_42);\n                int param_43 = _760 + 7;\n                float4 _1196 = fa_light_texel(param_43);\n                bool _1199 = _1191.z > 0.5f;\n                bool _1206;\n                if (!_1199)\n                {\n                    _1206 = _1196.z > 0.5f;\n                }\n                else\n                {\n                    _1206 = _1199;\n                }\n                if (_1206)\n                {\n                    int param_44 = _760 + 2;\n                    float4 _1213 = fa_light_texel(param_44);\n                    float3 _1217 = normalize(_1213.xyz);\n                    int param_45 = _760 + 4;\n                    float4 _1222 = fa_light_texel(param_45);\n                    int param_46 = _760 + 5;\n                    float4 _1227 = fa_light_texel(param_46);\n                    if (_1199)\n                    {\n                        float3 _1235 = -to_light;\n                        float _1242 = _1213.w;\n                        float _1258 = 0.5f / max(dot(_1235, _1217) * (sqrt(max(1.0f - (_1242 * _1242), 0.0f)) / max(_1242, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1191.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1235, _1222.xyz) * _1258), 0.5f - (dot(_1235, _1227.xyz) * _1258));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1196.z > 0.5f)\n                    {\n                        float2 param_49 = _1196.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1217;\n                        float3 param_52 = _1222.xyz;\n                        float3 param_53 = _1227.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _5461 = _773.xyz * atten;\n    if (_764)\n    {\n        _5461 *= fa_light_tint;\n    }\n    int _1326;\n    if (_790)\n    {\n        _1326 = 0;\n    }\n    else\n    {\n        _1326 = ((_776 > 1.5f) && (_776 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _5472 = { l, _5461, atten, 1.0f, dist, _1326 };\n    return _5472;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2120 = fa_shadow_depth(param, param_1);\n    float _2124;\n    if (conv.x < 0.5f)\n    {\n        _2124 = _2120;\n    }\n    else\n    {\n        _2124 = (conv.y * conv.z) / (conv.z - (_2120 * (conv.z - conv.y)));\n    }\n    return _2124;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2051 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2051), sin(_2051)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2170 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2179;\n        if (k < 0.0f)\n        {\n            _2179 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2179 = k;\n        }\n        float _2199 = clamp((_2179 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2170;\n            float2 _2218 = fa_shadow_vogel(param_3, param_4, param_5) * _2199;\n            float2 param_6 = uv + (_2218 * _2073_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2230 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2230 < (zr - (length(_2218) * plane)))\n            {\n                sum += _2230;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2256 = sum / cnt;\n        float _2266;\n        if (k < 0.0f)\n        {\n            _2266 = (-k) / max(_2256, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2266 = k;\n        }\n        radius = clamp(((max(zr - _2256, 0.0f) * unit) * _2266) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2288 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2288; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2288;\n        float param_11 = _2170;\n        float2 _2307 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2307 * _2073_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2307) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2288);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2507 = _416_fa_pbr.z < 0.5f;\n    bool _2514;\n    if (!_2507)\n    {\n        _2514 = _2073_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2514 = _2507;\n    }\n    if (_2514)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2073_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2527 = fa_light_texel(param);\n    float _2528 = _2527.x;\n    if (_2528 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2537 = int(_2528 + 0.5f);\n    int param_1 = _2537;\n    float4 _2541 = fa_light_texel(param_1);\n    int param_2 = _2537 + 1;\n    float4 _2546 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2549 = _2541.y;\n    if (_2549 > 0.0f)\n    {\n        float _2566 = 1.0f - smoothstep(0.75f * _2549, _2549, length(world - _2073_fa_shadow_eye.xyz));\n        fade = _2566;\n        if (_2566 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2541.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2590 = (_2537 + 2) + (face * 6);\n    int param_4 = _2590;\n    int param_5 = _2590 + 1;\n    int param_6 = _2590 + 3;\n    float4 _2604 = fa_light_texel(param_6);\n    int param_7 = _2590 + 4;\n    float4 _2609 = fa_light_texel(param_7);\n    int param_8 = _2590 + 5;\n    float4 _2614 = fa_light_texel(param_8);\n    float _2626 = _2614.x * max(dot(_2604, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2631 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2654 = clamp(dot(n, _2604.xyz), -1.0f, 1.0f);\n    float _2673 = min(sqrt(1.0f - (_2654 * _2654)) / max(abs(dot(n, world - lpos)) / max(dot(_2604, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2676 = _2546.y;\n    float _2678;\n    if (_2676 > 0.0f)\n    {\n        _2678 = _2676;\n    }\n    else\n    {\n        _2678 = 1.5f * _2626;\n    }\n    float4 _2698 = float4(world + (n * (_2678 * sqrt(1.0f - (_2631 * _2631)))), 1.0f);\n    float _2702 = dot(_2604, _2698);\n    float _2705 = _2614.y;\n    if (_2702 < _2705)\n    {\n        return 1.0f;\n    }\n    float2 _2720 = float2(dot(fa_light_texel(param_4), _2698), dot(fa_light_texel(param_5), _2698)) / _2702.xx;\n    float _2722 = _2720.x;\n    bool _2725 = _2722 < _2609.x;\n    bool _2734;\n    if (!_2725)\n    {\n        _2734 = _2722 > _2609.z;\n    }\n    else\n    {\n        _2734 = _2725;\n    }\n    bool _2743;\n    if (!_2734)\n    {\n        _2743 = _2720.y < _2609.y;\n    }\n    else\n    {\n        _2743 = _2734;\n    }\n    bool _2752;\n    if (!_2743)\n    {\n        _2752 = _2720.y > _2609.w;\n    }\n    else\n    {\n        _2752 = _2743;\n    }\n    if (_2752)\n    {\n        return 1.0f;\n    }\n    float _2758 = _2546.x;\n    float _2760;\n    if (_2758 > 0.0f)\n    {\n        _2760 = _2758;\n    }\n    else\n    {\n        _2760 = 1.5f * _2626;\n    }\n    float2 param_9 = _2720;\n    float4 param_10 = _2609;\n    float param_11 = _2702 - (_2760 * (1.0f + (0.5f * _2673)));\n    float param_12 = _2626;\n    float param_13 = 1.0f;\n    float param_14 = _2614.z * 0.25f;\n    float param_15 = (_2626 * min(_2673, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2705, _2614.z);\n    int param_17 = int(_2541.z + 0.5f);\n    float param_18 = _2541.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2063;\n    if (i == 0)\n    {\n        _2063 = _2073_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2079;\n        if (i == 1)\n        {\n            _2079 = _2073_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2087;\n            if (i == 2)\n            {\n                _2087 = _2073_fa_shadow_split.z;\n            }\n            else\n            {\n                _2087 = _2073_fa_shadow_split.w;\n            }\n            _2079 = _2087;\n        }\n        _2063 = _2079;\n    }\n    return _2063;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2349 = max(_2073_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2354 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2360 = sqrt(1.0f - (_2354 * _2354));\n    float _2367 = min(_2360 / max(_2354, 0.20000000298023223876953125f), 4.0f);\n    float _2372;\n    if (_2073_fa_shadow_bias.y > 0.0f)\n    {\n        _2372 = _2073_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2372 = 1.5f * _2073_fa_shadow_info[ci].x;\n    }\n    float4 _2397 = mul(float4(world + (n * (_2372 * _2360)), 1.0f), _2073_fa_shadow_mat[ci]);\n    float _2404 = _2397.x;\n    bool _2407 = _2404 < _2073_fa_shadow_rect[ci].x;\n    bool _2416;\n    if (!_2407)\n    {\n        _2416 = _2404 > _2073_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2416 = _2407;\n    }\n    bool _2425;\n    if (!_2416)\n    {\n        _2425 = _2397.y < _2073_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2425 = _2416;\n    }\n    bool _2434;\n    if (!_2425)\n    {\n        _2434 = _2397.y > _2073_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2434 = _2425;\n    }\n    bool _2441;\n    if (!_2434)\n    {\n        _2441 = _2397.z > 1.0f;\n    }\n    else\n    {\n        _2441 = _2434;\n    }\n    if (_2441)\n    {\n        return -1.0f;\n    }\n    float _2449;\n    if (_2073_fa_shadow_bias.x > 0.0f)\n    {\n        _2449 = _2073_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2449 = 1.5f * _2073_fa_shadow_info[ci].x;\n    }\n    float2 param = _2397.xy;\n    float4 param_1 = _2073_fa_shadow_rect[ci];\n    float param_2 = _2397.z - ((_2449 * (1.0f + (0.5f * _2367))) / _2349);\n    float param_3 = _2073_fa_shadow_info[ci].x;\n    float param_4 = _2349;\n    float param_5 = _2349 * 0.25f;\n    float param_6 = ((_2073_fa_shadow_info[ci].x * min(_2367, 3.0f)) * 0.5f) / _2349;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2073_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2073_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_416_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2827 = int(_2073_fa_shadow_cfg.x + 0.5f);\n    if (_2827 < 1)\n    {\n        return 1.0f;\n    }\n    float _2842 = dot(world - _2073_fa_shadow_eye.xyz, _2073_fa_shadow_fwd.xyz);\n    int param = _2827 - 1;\n    if (_2842 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2854 = _2827 > 1;\n    bool _2861;\n    if (_2854)\n    {\n        _2861 = _2842 > _2073_fa_shadow_split.x;\n    }\n    else\n    {\n        _2861 = _2854;\n    }\n    if (_2861)\n    {\n        ci = 1;\n    }\n    bool _2865 = _2827 > 2;\n    bool _2872;\n    if (_2865)\n    {\n        _2872 = _2842 > _2073_fa_shadow_split.y;\n    }\n    else\n    {\n        _2872 = _2865;\n    }\n    if (_2872)\n    {\n        ci = 2;\n    }\n    bool _2876 = _2827 > 3;\n    bool _2883;\n    if (_2876)\n    {\n        _2883 = _2842 > _2073_fa_shadow_split.z;\n    }\n    else\n    {\n        _2883 = _2876;\n    }\n    if (_2883)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2827)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2909 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2909;\n        if (_2909 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2073_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2934;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2934 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2934 = _2073_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2953 = _2073_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2934, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2964 = clamp((_2842 - (fa_shadow_split_at(param_7) - _2953)) / _2953, 0.0f, 1.0f);\n        if (_2964 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2827)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _2985 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2985;\n                if (_2985 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2964);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3434 = _416_fa_ct_a.x < 0.5f;\n    bool _3441;\n    if (!_3434)\n    {\n        _3441 = _2073_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3441 = _3434;\n    }\n    if (_3441)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2073_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3454 = fa_light_texel(param);\n    float _3455 = _3454.y;\n    float len = _3455;\n    if (_3455 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3467 = length(world - _416_fa_camera_pos.xyz);\n    float _3477 = 1.0f - smoothstep(0.5f * _416_fa_ct_b.x, _416_fa_ct_b.x, _3467);\n    if (_3477 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3483 = len;\n    float _3486 = min(_3483, 0.89999997615814208984375f * dist);\n    len = _3486;\n    float _3492 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3467);\n    float _3497 = _3492 + (0.5f * _3486);\n    float3 _3503 = world + (gn * _3492);\n    float _3505 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _3570;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3521 = (float(k) + _3505) * 0.083333335816860198974609375f;\n        float3 _3529 = _3503 + (l * (_3521 * len));\n        float4 _3535 = float4(_3529, 1.0f);\n        float _3541 = dot(_416_fa_ct_vpw, _3535);\n        if (_3541 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _3561 = float2(dot(_416_fa_ct_vpx, _3535), dot(_416_fa_ct_vpy, _3535)) / _3541.xx;\n        float _3565 = _3561.x * 0.5f;\n        float _3566 = _3565 + 0.5f;\n        if (_416_fa_ct_a.y > 0.5f)\n        {\n            _3570 = (_3561.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _3570 = 0.5f - (_3561.y * 0.5f);\n        }\n        bool _3586 = _3566 < 0.0f;\n        bool _3593;\n        if (!_3586)\n        {\n            _3593 = _3566 >= 1.0f;\n        }\n        else\n        {\n            _3593 = _3586;\n        }\n        bool _3600;\n        if (!_3593)\n        {\n            _3600 = _3570 < 0.0f;\n        }\n        else\n        {\n            _3600 = _3593;\n        }\n        bool _3607;\n        if (!_3600)\n        {\n            _3607 = _3570 >= 1.0f;\n        }\n        else\n        {\n            _3607 = _3600;\n        }\n        if (_3607)\n        {\n            break;\n        }\n        float4 _3626 = fa_screen_tex.Load(int3(int2(float2(_3566, _3570) * _416_fa_ct_a.zw), 0));\n        if (_3626.w < 0.5f)\n        {\n            continue;\n        }\n        float _3645 = (dot(_416_fa_ct_fwd.xyz, _3529) + _416_fa_ct_fwd.w) - _3626.x;\n        if ((_3645 > _3492) && (_3645 < _3497))\n        {\n            occ = max(occ, (1.0f - (_3521 * _3521)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_3566, 0.5f - _3565), min(_3570, 1.0f - _3570))));\n        }\n    }\n    return 1.0f - (occ * _3477);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _3748 = fa_baked_keep(param);\n    if (_3748 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _5485 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _5485;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _3774 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _5487 = _3774.color;\n    float _5488 = _3774.attenuation;\n    float _5489 = _3774.shadow;\n    bool _3777 = _3774.type == 0;\n    if (_3777 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _3774.direction;\n        float _3788 = fa_shadow_factor(param_5, param_6);\n        _5489 = _3788;\n        _5487 *= _3788;\n    }\n    else\n    {\n        bool _3799 = _3774.type != 0;\n        bool _3805;\n        if (_3799)\n        {\n            _3805 = _5488 > 0.0f;\n        }\n        else\n        {\n            _3805 = _3799;\n        }\n        if (_3805)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _3774.direction;\n            float _3824 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5489 = _3824;\n            _5487 *= _3824;\n        }\n    }\n    bool _3834 = _416_fa_ct_a.x > 0.5f;\n    bool _3840;\n    if (_3834)\n    {\n        _3840 = _5488 > 0.0f;\n    }\n    else\n    {\n        _3840 = _3834;\n    }\n    if (_3840)\n    {\n        float _3847;\n        if (_3777)\n        {\n            _3847 = 1000000000.0f;\n        }\n        else\n        {\n            _3847 = _3774._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _3774.direction;\n        float param_18 = _3847;\n        float _3865 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5489 *= _3865;\n        _5487 *= _3865;\n    }\n    float _3878 = _5488;\n    float _3879 = _3878 * _3748;\n    _5488 = _3879;\n    float3 _3883 = _5487;\n    float3 _3884 = _3883 * _3748;\n    _5487 = _3884;\n    LightSample _5504 = { _3774.direction, _3884, _3879, _5489, _3774._distance, _3774.type };\n    return _5504;\n}\n\nfloat3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return 0.0f.xxx;\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2073_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3009 = int(_2073_fa_shadow_cfg.x + 0.5f);\n    float _3019 = dot(world - _2073_fa_shadow_eye.xyz, _2073_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3024 = _3009 > 0;\n    bool _3033;\n    if (_3024)\n    {\n        int param = _3009 - 1;\n        _3033 = _3019 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3033 = _3024;\n    }\n    if (_3033)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3039 = _3009 > 1;\n        bool _3046;\n        if (_3039)\n        {\n            _3046 = _3019 > _2073_fa_shadow_split.x;\n        }\n        else\n        {\n            _3046 = _3039;\n        }\n        if (_3046)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3052 = _3009 > 2;\n        bool _3059;\n        if (_3052)\n        {\n            _3059 = _3019 > _2073_fa_shadow_split.y;\n        }\n        else\n        {\n            _3059 = _3052;\n        }\n        if (_3059)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3065 = _3009 > 3;\n        bool _3072;\n        if (_3065)\n        {\n            _3072 = _3019 > _2073_fa_shadow_split.z;\n        }\n        else\n        {\n            _3072 = _3065;\n        }\n        if (_3072)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5308 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5308 = -_5308;\n    }\n    float3 _4883 = normalize(_416_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5321 = { fa_world_pos, _5308, fa_world_tangent, fa_uv, fa_vertex_color, _4883, gl_FrontFacing };\n    SurfaceInput param_1 = _5321;\n    Surface _4891 = fa_standard_surface(param_1);\n    float3 _5339 = _4891.albedo;\n    float _5340 = _4891.alpha;\n    float3 _5341 = _4891.normal;\n    float _5342 = _4891.metallic;\n    float _5343 = _4891.roughness;\n    float _5344 = _4891.occlusion;\n    float3 _5345 = _4891.emission;\n    float _5346 = _4891.clearcoat;\n    float _5347 = _4891.clearcoat_roughness;\n    float3 _5348 = _4891.sheen_color;\n    float _5349 = _4891.sheen_roughness;\n    float _5350 = _4891.anisotropy;\n    float _5351 = _4891.anisotropy_rotation;\n    float _5352 = _4891.specular;\n    float _5353 = _4891.ior;\n    float3 _5354 = _4891.specular_color;\n    float _5355 = _4891.transmission;\n    float _5356 = _4891.thickness;\n    float3 _5357 = _4891.attenuation_color;\n    float _5358 = _4891.attenuation_distance;\n    SurfaceInput _5329 = { fa_world_pos, _5308, fa_world_tangent, fa_uv, fa_vertex_color, _4883, gl_FrontFacing };\n    SurfaceInput param_2 = _5329;\n    Surface param_3 = _4891;\n    surface(param_2, param_3);\n    _5339 = param_3.albedo;\n    _5340 = param_3.alpha;\n    _5341 = param_3.normal;\n    _5342 = param_3.metallic;\n    _5343 = param_3.roughness;\n    _5344 = param_3.occlusion;\n    _5345 = param_3.emission;\n    _5346 = param_3.clearcoat;\n    _5347 = param_3.clearcoat_roughness;\n    _5348 = param_3.sheen_color;\n    _5349 = param_3.sheen_roughness;\n    _5350 = param_3.anisotropy;\n    _5351 = param_3.anisotropy_rotation;\n    _5352 = param_3.specular;\n    _5353 = param_3.ior;\n    _5354 = param_3.specular_color;\n    _5355 = param_3.transmission;\n    _5356 = param_3.thickness;\n    _5357 = param_3.attenuation_color;\n    _5358 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5308;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5339 = param_6;\n    _5341 = param_7;\n    float3 result;\n    if (_416_fa_emissive.w > 0.5f)\n    {\n        result = _5339;\n    }\n    else\n    {\n        float3 _4930 = _5341;\n        float3 _4931 = normalize(_4930);\n        _5341 = _4931;\n        float3 param_8 = _4931;\n        float3 lit = (fa_indirect_diffuse(param_8) * _5339) * _5344;\n        int _4950 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4950; ln++)\n        {\n            int param_9 = ln;\n            int _4963 = fa_cl_light(param_9);\n            int param_10 = _4963;\n            if (fa_baked_keep(param_10) <= 0.0f)\n            {\n                continue;\n            }\n            int param_11 = _4963;\n            float3 param_12 = fa_world_pos;\n            float3 param_13 = _5308;\n            LightSample _4979 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput _5337 = { fa_world_pos, _5308, fa_world_tangent, fa_uv, fa_vertex_color, _4883, gl_FrontFacing };\n            SurfaceInput param_14 = _5337;\n            Surface _5440 = { _5339, _5340, _5341, _5342, _5343, _5344, _5345, _5346, _5347, _5348, _5349, _5350, _5351, _5352, _5353, _5354, _5355, _5356, _5357, _5358 };\n            Surface param_15 = _5440;\n            LightSample param_16 = _4979;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    float3 _4994 = result;\n    float3 _4995 = _4994 + _5345;\n    result = _4995;\n    float3 param_17 = _4995;\n    float3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _5004 = _416_fa_fog.w > 0.0f;\n    bool _5011;\n    if (!_5004)\n    {\n        _5011 = _416_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5011 = _5004;\n    }\n    if (_5011)\n    {\n        float3 _5020 = fa_world_pos - _416_fa_camera_pos.xyz;\n        float _5026 = dot(_5020, _416_fa_fog_c.xyz);\n        bool _5030 = _416_fa_fog_c.w > 0.5f;\n        float _5031;\n        if (_5030)\n        {\n            _5031 = _5026;\n        }\n        else\n        {\n            _5031 = length(_5020);\n        }\n        float _5043 = _5031 - _416_fa_fog_b.x;\n        if (_5043 > 0.0f)\n        {\n            float _5052 = _416_fa_fog.w * _5043;\n            float tau = _5052 * _5052;\n            if (_416_fa_fog_b.y > 0.0f)\n            {\n                float _5068;\n                if (_5030)\n                {\n                    _5068 = fa_world_pos.y - (_416_fa_fog_c.y * _5026);\n                }\n                else\n                {\n                    _5068 = _416_fa_camera_pos.y;\n                }\n                float _5089 = lerp(_5068, fa_world_pos.y, clamp(_416_fa_fog_b.x / _5031, 0.0f, 1.0f));\n                float _5093 = fa_world_pos.y - _5089;\n                float _5098 = _5089 - _416_fa_fog_b.z;\n                float _5103 = fa_world_pos.y - _416_fa_fog_b.z;\n                bool _5106 = _5098 <= 0.0f;\n                bool _5107 = !_5106;\n                bool _5113;\n                if (_5107)\n                {\n                    _5113 = _416_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5113 = _5106;\n                }\n                float _5114;\n                if (_5113)\n                {\n                    _5114 = _416_fa_fog_b.y;\n                }\n                else\n                {\n                    _5114 = _416_fa_fog_b.y * exp(-min(_416_fa_fog_b.w * _5098, 80.0f));\n                }\n                bool _5141;\n                if (_5107)\n                {\n                    _5141 = _416_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5141 = _5106;\n                }\n                float _5142;\n                if (_5141)\n                {\n                    _5142 = _416_fa_fog_b.y * _5098;\n                }\n                else\n                {\n                    _5142 = (_416_fa_fog_b.y * (1.0f - exp(-min(_416_fa_fog_b.w * _5098, 80.0f)))) / _416_fa_fog_b.w;\n                }\n                bool _5167 = _5103 <= 0.0f;\n                bool _5174;\n                if (!_5167)\n                {\n                    _5174 = _416_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5174 = _5167;\n                }\n                float _5175;\n                if (_5174)\n                {\n                    _5175 = _416_fa_fog_b.y * _5103;\n                }\n                else\n                {\n                    _5175 = (_416_fa_fog_b.y * (1.0f - exp(-min(_416_fa_fog_b.w * _5103, 80.0f)))) / _416_fa_fog_b.w;\n                }\n                float _5202;\n                if (abs(_5093) < 0.001000000047497451305389404296875f)\n                {\n                    _5202 = _5114;\n                }\n                else\n                {\n                    _5202 = (_5175 - _5142) / _5093;\n                }\n                tau += (_5043 * max(_5202, 0.0f));\n            }\n            result = lerp(result, _416_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5340);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_416",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _215_fa_camera_pos : packoffset(c0);\n    float4 _215_fa_ambient : packoffset(c1);\n    float4 _215_fa_base_color : packoffset(c2);\n    float4 _215_fa_emissive : packoffset(c3);\n    float4 _215_fa_model_emissive : packoffset(c4);\n    float4 _215_fa_pbr : packoffset(c5);\n    float4 _215_fa_maps : packoffset(c6);\n    float4 _215_fa_fog : packoffset(c7);\n    float4 _215_fa_fog_b : packoffset(c8);\n    float4 _215_fa_fog_c : packoffset(c9);\n    float4 _215_fa_counts : packoffset(c10);\n    float4 _215_fa_env_sky : packoffset(c11);\n    float4 _215_fa_env_horizon : packoffset(c12);\n    float4 _215_fa_time : packoffset(c13);\n    float4 _215_fa_cl_vpx : packoffset(c14);\n    float4 _215_fa_cl_vpy : packoffset(c15);\n    float4 _215_fa_cl_vpw : packoffset(c16);\n    float4 _215_fa_cl_fwd : packoffset(c17);\n    float4 _215_fa_cl_grid : packoffset(c18);\n    float4 _215_fa_cl_info : packoffset(c19);\n    float4 _215_fa_layers_a : packoffset(c20);\n    float4 _215_fa_layers_b : packoffset(c21);\n    float4 _215_fa_layers_c : packoffset(c22);\n    float4 _215_fa_layers_d : packoffset(c23);\n    float4 _215_fa_ct_a : packoffset(c24);\n    float4 _215_fa_ct_b : packoffset(c25);\n    float4 _215_fa_ct_vpx : packoffset(c26);\n    float4 _215_fa_ct_vpy : packoffset(c27);\n    float4 _215_fa_ct_vpw : packoffset(c28);\n    float4 _215_fa_ct_fwd : packoffset(c29);\n    float4 _215_fa_tr_a : packoffset(c30);\n    float4 _215_fa_tr_b : packoffset(c31);\n    float4 _215_fa_probe_sh[9] : packoffset(c32);\n    float4 _215_fa_atlas : packoffset(c41);\n    float4 _215_fa_rpa_tile : packoffset(c42);\n    float4 _215_fa_rpa_pos : packoffset(c43);\n    float4 _215_fa_rpa_bx : packoffset(c44);\n    float4 _215_fa_rpa_by : packoffset(c45);\n    float4 _215_fa_rpa_bz : packoffset(c46);\n    float4 _215_fa_rpb_tile : packoffset(c47);\n    float4 _215_fa_rpb_pos : packoffset(c48);\n    float4 _215_fa_rpb_bx : packoffset(c49);\n    float4 _215_fa_rpb_by : packoffset(c50);\n    float4 _215_fa_rpb_bz : packoffset(c51);\n    float4 _215_fa_gi : packoffset(c52);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _215_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _227 = fa_tex_fix(param_2, param_3);\n    float4 _828 = base_t;\n    _828.x = _227.x;\n    _828.y = _227.y;\n    _828.z = _227.z;\n    base_t = _828;\n    float4 _243 = (_828 * _215_fa_base_color) * i.vertex_color;\n    float3 _783 = i.world_normal;\n    if (_215_fa_maps.z > 0.5f)\n    {\n        float param_4 = _215_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _277 = fa_tex_fix(param_6, param_7);\n        float3 _281 = (_277 * 2.0f) - 1.0f.xxx;\n        float2 _286 = _281.xy * _215_fa_maps.x;\n        float3 _836 = _281;\n        _836.x = _286.x;\n        _836.y = _286.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _836;\n        _783 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _215_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _315 = fa_tex_fix(param_12, param_13);\n    float4 _839 = mrt;\n    _839.x = _315.x;\n    _839.y = _315.y;\n    _839.z = _315.z;\n    mrt = _839;\n    float4 _345 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _215_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = _215_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _387 = fa_tex_fix(param_20, param_21);\n    float _788 = _215_fa_layers_a.x;\n    float _789 = _215_fa_layers_a.y;\n    float _792 = _215_fa_layers_a.z;\n    float _791 = _215_fa_layers_b.w;\n    float _794 = _215_fa_layers_c.x;\n    if (_215_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_215_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _788 *= _357.y;\n            _789 *= _357.z;\n            _791 *= _345.w;\n        }\n        if (_215_fa_layers_c.z > 1.5f)\n        {\n            _792 *= mrt.x;\n            _794 *= mrt.w;\n        }\n    }\n    Surface _821 = { _243.xyz, _243.w, _783, clamp(_215_fa_pbr.x * _315.z, 0.0f, 1.0f), clamp(_215_fa_pbr.y * _315.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_215_fa_maps.y * (_357.x - 1.0f)), _215_fa_emissive.xyz + (_215_fa_model_emissive.xyz * _387), _788, _789, _215_fa_layers_b.xyz, _791, _792, _215_fa_layers_a.w, _794, _215_fa_layers_c.y, _215_fa_layers_d.xyz, _215_fa_tr_a.x, _215_fa_tr_a.y, _215_fa_tr_b.xyz, _215_fa_tr_a.z };\n    return _821;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _678 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _678 = -_678;\n    }\n    float3 _540 = normalize(_215_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _691 = { fa_world_pos, _678, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing };\n    SurfaceInput param = _691;\n    SurfaceInput _699 = { fa_world_pos, _678, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing };\n    SurfaceInput param_1 = _699;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _555 = normalize(param_2.normal);\n    float3 _570 = normalize(float3(dot(fa_pre_r0, _555), dot(fa_pre_r1, _555), dot(fa_pre_r2, _555)));\n    float _582 = _570.z;\n    float2 e = _570.xy / ((abs(_570.x) + abs(_570.y)) + abs(_582)).xx;\n    if (_582 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _215_fa_camera_pos : packoffset(c0);\n    float4 _215_fa_ambient : packoffset(c1);\n    float4 _215_fa_base_color : packoffset(c2);\n    float4 _215_fa_emissive : packoffset(c3);\n    float4 _215_fa_model_emissive : packoffset(c4);\n    float4 _215_fa_pbr : packoffset(c5);\n    float4 _215_fa_maps : packoffset(c6);\n    float4 _215_fa_fog : packoffset(c7);\n    float4 _215_fa_fog_b : packoffset(c8);\n    float4 _215_fa_fog_c : packoffset(c9);\n    float4 _215_fa_counts : packoffset(c10);\n    float4 _215_fa_env_sky : packoffset(c11);\n    float4 _215_fa_env_horizon : packoffset(c12);\n    float4 _215_fa_time : packoffset(c13);\n    float4 _215_fa_cl_vpx : packoffset(c14);\n    float4 _215_fa_cl_vpy : packoffset(c15);\n    float4 _215_fa_cl_vpw : packoffset(c16);\n    float4 _215_fa_cl_fwd : packoffset(c17);\n    float4 _215_fa_cl_grid : packoffset(c18);\n    float4 _215_fa_cl_info : packoffset(c19);\n    float4 _215_fa_layers_a : packoffset(c20);\n    float4 _215_fa_layers_b : packoffset(c21);\n    float4 _215_fa_layers_c : packoffset(c22);\n    float4 _215_fa_layers_d : packoffset(c23);\n    float4 _215_fa_ct_a : packoffset(c24);\n    float4 _215_fa_ct_b : packoffset(c25);\n    float4 _215_fa_ct_vpx : packoffset(c26);\n    float4 _215_fa_ct_vpy : packoffset(c27);\n    float4 _215_fa_ct_vpw : packoffset(c28);\n    float4 _215_fa_ct_fwd : packoffset(c29);\n    float4 _215_fa_tr_a : packoffset(c30);\n    float4 _215_fa_tr_b : packoffset(c31);\n    float4 _215_fa_probe_sh[9] : packoffset(c32);\n    float4 _215_fa_atlas : packoffset(c41);\n    float4 _215_fa_rpa_tile : packoffset(c42);\n    float4 _215_fa_rpa_pos : packoffset(c43);\n    float4 _215_fa_rpa_bx : packoffset(c44);\n    float4 _215_fa_rpa_by : packoffset(c45);\n    float4 _215_fa_rpa_bz : packoffset(c46);\n    float4 _215_fa_rpb_tile : packoffset(c47);\n    float4 _215_fa_rpb_pos : packoffset(c48);\n    float4 _215_fa_rpb_bx : packoffset(c49);\n    float4 _215_fa_rpb_by : packoffset(c50);\n    float4 _215_fa_rpb_bz : packoffset(c51);\n    float4 _215_fa_gi : packoffset(c52);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _215_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _227 = fa_tex_fix(param_2, param_3);\n    float4 _828 = base_t;\n    _828.x = _227.x;\n    _828.y = _227.y;\n    _828.z = _227.z;\n    base_t = _828;\n    float4 _243 = (_828 * _215_fa_base_color) * i.vertex_color;\n    float3 _783 = i.world_normal;\n    if (_215_fa_maps.z > 0.5f)\n    {\n        float param_4 = _215_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _277 = fa_tex_fix(param_6, param_7);\n        float3 _281 = (_277 * 2.0f) - 1.0f.xxx;\n        float2 _286 = _281.xy * _215_fa_maps.x;\n        float3 _836 = _281;\n        _836.x = _286.x;\n        _836.y = _286.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _836;\n        _783 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _215_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _315 = fa_tex_fix(param_12, param_13);\n    float4 _839 = mrt;\n    _839.x = _315.x;\n    _839.y = _315.y;\n    _839.z = _315.z;\n    mrt = _839;\n    float4 _345 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _215_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = _215_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _387 = fa_tex_fix(param_20, param_21);\n    float _788 = _215_fa_layers_a.x;\n    float _789 = _215_fa_layers_a.y;\n    float _792 = _215_fa_layers_a.z;\n    float _791 = _215_fa_layers_b.w;\n    float _794 = _215_fa_layers_c.x;\n    if (_215_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_215_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _788 *= _357.y;\n            _789 *= _357.z;\n            _791 *= _345.w;\n        }\n        if (_215_fa_layers_c.z > 1.5f)\n        {\n            _792 *= mrt.x;\n            _794 *= mrt.w;\n        }\n    }\n    Surface _821 = { _243.xyz, _243.w, _783, clamp(_215_fa_pbr.x * _315.z, 0.0f, 1.0f), clamp(_215_fa_pbr.y * _315.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_215_fa_maps.y * (_357.x - 1.0f)), _215_fa_emissive.xyz + (_215_fa_model_emissive.xyz * _387), _788, _789, _215_fa_layers_b.xyz, _791, _792, _215_fa_layers_a.w, _794, _215_fa_layers_c.y, _215_fa_layers_d.xyz, _215_fa_tr_a.x, _215_fa_tr_a.y, _215_fa_tr_b.xyz, _215_fa_tr_a.z };\n    return _821;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _678 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _678 = -_678;\n    }\n    float3 _540 = normalize(_215_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _691 = { fa_world_pos, _678, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing };\n    SurfaceInput param = _691;\n    SurfaceInput _699 = { fa_world_pos, _678, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing };\n    SurfaceInput param_1 = _699;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _555 = normalize(param_2.normal);\n    float3 _570 = normalize(float3(dot(fa_pre_r0, _555), dot(fa_pre_r1, _555), dot(fa_pre_r2, _555)));\n    float _582 = _570.z;\n    float2 e = _570.xy / ((abs(_570.x) + abs(_570.y)) + abs(_582)).xx;\n    if (_582 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
