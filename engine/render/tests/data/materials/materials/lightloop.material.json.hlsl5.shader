{
  "format": "factoria.shader/1",
  "engine": "0.34.0",
  "template": "d5ad4ba00a2086cd5c3d6440d2be629e3ce9b0f8ede644c9a19112677c2fea28",
  "slang": "hlsl5",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _263 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _263;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_270, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3924[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _6352 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _420_fa_camera_pos : packoffset(c0);\n    float4 _420_fa_ambient : packoffset(c1);\n    float4 _420_fa_base_color : packoffset(c2);\n    float4 _420_fa_emissive : packoffset(c3);\n    float4 _420_fa_model_emissive : packoffset(c4);\n    float4 _420_fa_pbr : packoffset(c5);\n    float4 _420_fa_maps : packoffset(c6);\n    float4 _420_fa_fog : packoffset(c7);\n    float4 _420_fa_fog_b : packoffset(c8);\n    float4 _420_fa_fog_c : packoffset(c9);\n    float4 _420_fa_counts : packoffset(c10);\n    float4 _420_fa_env_sky : packoffset(c11);\n    float4 _420_fa_env_horizon : packoffset(c12);\n    float4 _420_fa_time : packoffset(c13);\n    float4 _420_fa_cl_vpx : packoffset(c14);\n    float4 _420_fa_cl_vpy : packoffset(c15);\n    float4 _420_fa_cl_vpw : packoffset(c16);\n    float4 _420_fa_cl_fwd : packoffset(c17);\n    float4 _420_fa_cl_grid : packoffset(c18);\n    float4 _420_fa_cl_info : packoffset(c19);\n    float4 _420_fa_layers_a : packoffset(c20);\n    float4 _420_fa_layers_b : packoffset(c21);\n    float4 _420_fa_layers_c : packoffset(c22);\n    float4 _420_fa_layers_d : packoffset(c23);\n    float4 _420_fa_ct_a : packoffset(c24);\n    float4 _420_fa_ct_b : packoffset(c25);\n    float4 _420_fa_ct_vpx : packoffset(c26);\n    float4 _420_fa_ct_vpy : packoffset(c27);\n    float4 _420_fa_ct_vpw : packoffset(c28);\n    float4 _420_fa_ct_fwd : packoffset(c29);\n    float4 _420_fa_tr_a : packoffset(c30);\n    float4 _420_fa_tr_b : packoffset(c31);\n    float4 _420_fa_probe_sh[9] : packoffset(c32);\n    float4 _420_fa_atlas : packoffset(c41);\n    float4 _420_fa_rpa_tile : packoffset(c42);\n    float4 _420_fa_rpa_pos : packoffset(c43);\n    float4 _420_fa_rpa_bx : packoffset(c44);\n    float4 _420_fa_rpa_by : packoffset(c45);\n    float4 _420_fa_rpa_bz : packoffset(c46);\n    float4 _420_fa_rpb_tile : packoffset(c47);\n    float4 _420_fa_rpb_pos : packoffset(c48);\n    float4 _420_fa_rpb_bx : packoffset(c49);\n    float4 _420_fa_rpb_by : packoffset(c50);\n    float4 _420_fa_rpb_bz : packoffset(c51);\n    float4 _420_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2155_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2155_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2155_fa_shadow_info[4] : packoffset(c20);\n    float4 _2155_fa_shadow_split : packoffset(c24);\n    float4 _2155_fa_shadow_cfg : packoffset(c25);\n    float4 _2155_fa_shadow_bias : packoffset(c26);\n    float4 _2155_fa_shadow_eye : packoffset(c27);\n    float4 _2155_fa_shadow_fwd : packoffset(c28);\n    float4 _2155_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _5074_dark : packoffset(c0);\n    float _5074_fa_pad0 : packoffset(c0.y);\n    float _5074_fa_pad1 : packoffset(c0.z);\n    float _5074_fa_pad2 : packoffset(c0.w);\n    float _5074_skyAmount : packoffset(c1);\n    float _5074_fa_pad3 : packoffset(c1.y);\n    float _5074_fa_pad4 : packoffset(c1.z);\n    float _5074_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t9);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_screen_tex : register(t10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1437 = _420_fa_cl_info.x < 0.0f;\n    bool _1444;\n    if (!_1437)\n    {\n        _1444 = _420_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1444 = _1437;\n    }\n    bool _1452;\n    if (!_1444)\n    {\n        _1452 = _420_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1452 = _1444;\n    }\n    bool _1459;\n    if (!_1452)\n    {\n        _1459 = _420_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1459 = _1452;\n    }\n    bool _1466;\n    if (!_1459)\n    {\n        _1466 = _420_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1466 = _1459;\n    }\n    if (_1466)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1476 = float4(world_pos, 1.0f);\n    float _1482 = dot(_420_fa_cl_vpw, _1476);\n    if (!(_1482 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1504 = float2(dot(_420_fa_cl_vpx, _1476), dot(_420_fa_cl_vpy, _1476)) / _1482.xx;\n    int _1508 = int(_420_fa_cl_grid.x);\n    int _1512 = int(_420_fa_cl_grid.y);\n    int param = (int(_420_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_420_fa_cl_fwd.xyz, world_pos) + _420_fa_cl_fwd.w, _420_fa_cl_grid.w) / _420_fa_cl_grid.w) * _420_fa_cl_grid.z)), 0, int(_420_fa_cl_info.y) - 1) * _1512) + clamp(int(floor(((_1504.y * 0.5f) + 0.5f) * _420_fa_cl_grid.y)), 0, _1512 - 1)) * _1508)) + clamp(int(floor(((_1504.x * 0.5f) + 0.5f) * _420_fa_cl_grid.x)), 0, _1508 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1588 = fa_cluster_texel(param);\n    return int2(int(_1588.x), int(_1588.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_420_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4758 = fa_cluster_lookup(param);\n    fa_cl_slot = _4758.x;\n    fa_cl_local = _4758.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5135 = fa_linear_to_srgb(param);\n        c = _5135;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5143 = fa_srgb_to_linear(param_1);\n            c = _5143;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _350;\n    if (i.front_facing)\n    {\n        _350 = i.world_normal;\n    }\n    else\n    {\n        _350 = -i.world_normal;\n    }\n    float3 _374 = normalize(i.world_tangent.xyz - (_350 * dot(_350, i.world_tangent.xyz)));\n    float3 _402 = normalize(((_374 * m.x) + ((cross(_350, _374) * i.world_tangent.w) * m.y)) + (_350 * m.z));\n    float3 _405;\n    if (i.front_facing)\n    {\n        _405 = _402;\n    }\n    else\n    {\n        _405 = -_402;\n    }\n    return _405;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _420_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5174 = fa_tex_fix(param_2, param_3);\n    float4 _6314 = base_t;\n    _6314.x = _5174.x;\n    _6314.y = _5174.y;\n    _6314.z = _5174.z;\n    base_t = _6314;\n    float4 _5188 = (_6314 * _420_fa_base_color) * i.vertex_color;\n    float3 _6120 = i.world_normal;\n    if (_420_fa_maps.z > 0.5f)\n    {\n        float param_4 = _420_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5220 = fa_tex_fix(param_6, param_7);\n        float3 _5223 = (_5220 * 2.0f) - 1.0f.xxx;\n        float2 _5228 = _5223.xy * _420_fa_maps.x;\n        float3 _6322 = _5223;\n        _6322.x = _5228.x;\n        _6322.y = _5228.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6322;\n        _6120 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _420_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _5256 = fa_tex_fix(param_12, param_13);\n    float4 _6325 = mrt;\n    _6325.x = _5256.x;\n    _6325.y = _5256.y;\n    _6325.z = _5256.z;\n    mrt = _6325;\n    float4 _5284 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _420_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _5284.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _5295 = fa_tex_fix(param_16, param_17);\n    float param_18 = _420_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _5325 = fa_tex_fix(param_20, param_21);\n    float _6125 = _420_fa_layers_a.x;\n    float _6126 = _420_fa_layers_a.y;\n    float _6129 = _420_fa_layers_a.z;\n    float _6128 = _420_fa_layers_b.w;\n    float _6131 = _420_fa_layers_c.x;\n    if (_420_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_420_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6125 *= _5295.y;\n            _6126 *= _5295.z;\n            _6128 *= _5284.w;\n        }\n        if (_420_fa_layers_c.z > 1.5f)\n        {\n            _6129 *= mrt.x;\n            _6131 *= mrt.w;\n        }\n    }\n    Surface _6158 = { _5188.xyz, _5188.w, _6120, clamp(_420_fa_pbr.x * _5256.z, 0.0f, 1.0f), clamp(_420_fa_pbr.y * _5256.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_420_fa_maps.y * (_5295.x - 1.0f)), _420_fa_emissive.xyz + (_420_fa_model_emissive.xyz * _5325), _6125, _6126, _420_fa_layers_b.xyz, _6128, _6129, _420_fa_layers_a.w, _6131, _420_fa_layers_c.y, _420_fa_layers_d.xyz, _420_fa_tr_a.x, _420_fa_tr_a.y, _420_fa_tr_b.xyz, _420_fa_tr_a.z };\n    return _6158;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1668 = rect.zw - rect.xy;\n    float2 _1672 = _1668 * atlas;\n    float2 _1676 = ddx * _1672;\n    float2 _1680 = ddy * _1672;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1668), clamp(0.5f * log2(max(max(dot(_1676, _1676), dot(_1680, _1680)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1713 = _420_fa_counts.y < 0.5f;\n    bool _1720;\n    if (!_1713)\n    {\n        _1720 = _420_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1720 = _1713;\n    }\n    if (_1720)\n    {\n        return;\n    }\n    float3 _1726 = ddx(world_pos);\n    float3 _1729 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1733 = fa_cluster_texel(param);\n    int _1737 = int(_1733.w);\n    if (_1737 < 1)\n    {\n        return;\n    }\n    int _1747 = int(_420_fa_counts.y + 0.5f);\n    int param_1 = _1747;\n    float4 _1751 = fa_light_texel(param_1);\n    float2 _1754 = _1751.yz;\n    int _1758 = int(_1751.w);\n    int param_2 = _1747 + 1;\n    float4 _1763 = fa_light_texel(param_2);\n    float _1764 = _1763.x;\n    int _1770 = int(_420_fa_counts.w + 0.5f) - 1;\n    int _1774 = int(_1733.z);\n    float3 _2039;\n    for (int k = 0; k < _1737; k++)\n    {\n        int _1787 = _1774 + k;\n        int param_3 = _1758 + (_1787 >> 2);\n        int _1804 = (_1747 + 2) + (int(fa_light_texel(param_3)[_1787 & 3]) * 7);\n        int param_4 = _1804 + 6;\n        float4 _1809 = fa_light_texel(param_4);\n        if (((int(_1809.w + 0.5f) >> _1770) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1804;\n        float4 _1824 = fa_light_texel(param_5);\n        int param_6 = _1804 + 1;\n        float4 _1829 = fa_light_texel(param_6);\n        int param_7 = _1804 + 2;\n        float4 _1834 = fa_light_texel(param_7);\n        float3 _1837 = _1824.xyz;\n        float _1842 = dot(_1837, world_pos) + _1824.w;\n        float3 _1844 = _1829.xyz;\n        float _1849 = dot(_1844, world_pos) + _1829.w;\n        float3 _1851 = _1834.xyz;\n        float _1856 = dot(_1851, world_pos) + _1834.w;\n        bool _1861 = abs(_1842) > 0.5f;\n        bool _1869;\n        if (!_1861)\n        {\n            _1869 = abs(_1849) > 0.5f;\n        }\n        else\n        {\n            _1869 = _1861;\n        }\n        bool _1877;\n        if (!_1869)\n        {\n            _1877 = abs(_1856) > 0.5f;\n        }\n        else\n        {\n            _1877 = _1869;\n        }\n        if (_1877)\n        {\n            continue;\n        }\n        float _1892 = clamp(dot(geo_normal, normalize(_1851)) * _1809.z, 0.0f, 1.0f);\n        if (_1892 <= 0.0f)\n        {\n            continue;\n        }\n        float _1912 = (clamp((0.5f - abs(_1856)) * 10.0f, 0.0f, 1.0f) * _1892) * _1809.x;\n        float2 _1920 = float2(_1842 + 0.5f, 0.5f - _1849);\n        float2 _1930 = float2(dot(_1837, _1726), dot(_1844, _1726));\n        float2 _1940 = float2(dot(_1837, _1729), dot(_1844, _1729));\n        int param_8 = _1804 + 5;\n        float4 _1945 = fa_light_texel(param_8);\n        int param_9 = _1804 + 3;\n        float4 _1950 = fa_light_texel(param_9);\n        int param_10 = _1804 + 4;\n        float4 _1955 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1945.xyz;\n        bool _1965 = _1950.z > _1950.x;\n        if (_1965)\n        {\n            float4 param_11 = _1950;\n            float2 param_12 = _1920;\n            float2 param_13 = _1754;\n            float2 param_14 = _1930;\n            float2 param_15 = _1940;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1764 > 0.5f) && (_1764 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1991 = fa_dc_to_linear(param_16);\n                float4 _6208 = tx;\n                _6208.x = _1991.x;\n                _6208.y = _1991.y;\n                _6208.z = _1991.z;\n                tx = _6208;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1912 * tex_a) * _1945.w, 0.0f, 1.0f).xxx);\n        if (_1955.z > _1955.x)\n        {\n            float4 param_17 = _1955;\n            float2 param_18 = _1920;\n            float2 param_19 = _1754;\n            float2 param_20 = _1930;\n            float2 param_21 = _1940;\n            float4 _2035 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1764 > 1.5f)\n            {\n                float3 param_22 = _2035.xyz;\n                float3 _2045 = fa_dc_to_srgb(param_22);\n                _2039 = _2045;\n            }\n            else\n            {\n                _2039 = _2035.xyz;\n            }\n            float3 _2054 = (_2039 * 2.0f) - 1.0f.xxx;\n            float2 _2059 = _2054.xy * _1809.y;\n            float3 _2081 = (normalize(_1837) * _2059.x) + (normalize(_1844) * _2059.y);\n            float3 _2084 = normalize(normal);\n            normal = normalize(lerp(_2084, normalize((_2084 * max(_2054.z, 0.0500000007450580596923828125f)) + (_2081 - (_2084 * dot(_2084, _2081)))), clamp(_1912 * (_1965 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (_420_fa_gi.w != 0.0f)\n    {\n        float _442 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n        bool _445;\n        if (_420_fa_gi.w > 0.0f)\n        {\n            _445 = _442 >= _420_fa_gi.w;\n        }\n        else\n        {\n            _445 = _442 < (-_420_fa_gi.w);\n        }\n        if (_445)\n        {\n            discard;\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _6352;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_420_fa_cl_info.x) + int(_420_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_420_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4728;\n    if (fa_lm.z > 0.5f)\n    {\n        _4728 = 0.0f;\n    }\n    else\n    {\n        _4728 = 1.0f - clamp(_420_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4739 = _4728 < 1.0f;\n    bool _4745;\n    if (_4739)\n    {\n        int param = li;\n        _4745 = fa_light_baked(param);\n    }\n    else\n    {\n        _4745 = _4739;\n    }\n    return _4745 ? _4728 : 1.0f;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _686 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _699 = (c - (ru * hx)) - p;\n        float3 _705 = ru * (2.0f * hx);\n        float _711 = max(dot(_705, _705), 9.9999999392252902907785028219223e-09f);\n        float _715 = dot(_699, _705);\n        float t = clamp((-_715) / _711, 0.0f, 1.0f);\n        if (_686)\n        {\n            float _730 = dot(r, _705);\n            float _736 = _711 - (_730 * _730);\n            if (abs(_736) > (9.9999997473787516355514526367188e-06f * _711))\n            {\n                t = clamp(((dot(r, _699) * _730) - _715) / _736, 0.0f, 1.0f);\n            }\n        }\n        return (p + _699) + (_705 * t);\n    }\n    float3 q = p;\n    float _768 = dot(r, axis);\n    bool _776;\n    if (_686)\n    {\n        _776 = abs(_768) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _776 = _686;\n    }\n    if (_776)\n    {\n        float _786 = dot(c - p, axis) / _768;\n        if (_786 > 0.0f)\n        {\n            q = p + (r * _786);\n        }\n    }\n    float3 _799 = q - c;\n    float2 xy = float2(dot(_799, ru), dot(_799, uu));\n    if (shape > 0.5f)\n    {\n        float _814 = length(xy);\n        if (_814 > hx)\n        {\n            xy *= (hx / _814);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _567_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _567_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _606 = dot(d, right);\n    float _610 = dot(d, up);\n    float _621;\n    if (((_606 * _606) + (_610 * _610)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _621 = atan2(_610, _606) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _621 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_621 - floor(_621)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _462 = abs(d);\n    float _464 = _462.x;\n    float _466 = _462.y;\n    bool _467 = _464 >= _466;\n    bool _475;\n    if (_467)\n    {\n        _475 = _464 >= _462.z;\n    }\n    else\n    {\n        _475 = _467;\n    }\n    int _476;\n    if (_475)\n    {\n        _476 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _490;\n        if (_466 >= _462.z)\n        {\n            _490 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _490 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _476 = _490;\n    }\n    return _476;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _852 = fa_light_base(param);\n    bool _856 = _420_fa_ambient.w > 4.5f;\n    int param_1 = _852;\n    float4 _860 = fa_light_texel(param_1);\n    int param_2 = _852 + 1;\n    float4 _865 = fa_light_texel(param_2);\n    float _868 = _865.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _880 = _856 && (_868 > 2.5f);\n    fa_light_is_area = _880;\n    bool _882 = _868 < 0.5f;\n    float3 l;\n    if (_882)\n    {\n        l = normalize(_860.xyz);\n        if (_856)\n        {\n            int param_3 = _852 + 6;\n            float4 _896 = fa_light_texel(param_3);\n            if (_896.z > 0.5f)\n            {\n                int param_4 = _852 + 4;\n                float4 _906 = fa_light_texel(param_4);\n                int param_5 = _852 + 5;\n                float4 _911 = fa_light_texel(param_5);\n                float2 param_6 = _896.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _906.xyz) * _906.w, (-dot(world_pos, _911.xyz)) * _911.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _941 = _860.xyz;\n        float3 _943 = _941 - world_pos;\n        float3 to_light = _943;\n        float _946 = length(_943);\n        float reach = _946;\n        bool front = true;\n        if (_880)\n        {\n            int param_8 = _852 + 7;\n            reach = max(_946 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _852 + 4;\n            float4 _970 = fa_light_texel(param_9);\n            int param_10 = _852 + 5;\n            float4 _975 = fa_light_texel(param_10);\n            int param_11 = _852 + 6;\n            float4 _980 = fa_light_texel(param_11);\n            float _981 = _980.w;\n            int param_12 = _852 + 2;\n            float3 _988 = normalize(fa_light_texel(param_12).xyz);\n            bool _990 = _981 > 1.5f;\n            bool _998;\n            if (!_990)\n            {\n                _998 = dot(_988, to_light) < 0.0f;\n            }\n            else\n            {\n                _998 = _990;\n            }\n            front = _998;\n            float3 r = 0.0f.xxx;\n            float3 _1007 = _420_fa_camera_pos.xyz - world_pos;\n            bool _1011 = dot(n, n) > 0.5f;\n            bool _1019;\n            if (_1011)\n            {\n                _1019 = dot(_1007, _1007) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1019 = _1011;\n            }\n            if (_1019)\n            {\n                r = reflect(-normalize(_1007), normalize(n));\n            }\n            float3 param_13 = _941;\n            float3 param_14 = _988;\n            float3 param_15 = _970.xyz;\n            float3 param_16 = _975.xyz;\n            float param_17 = _970.w;\n            float param_18 = _975.w;\n            float param_19 = _981;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1055 = length(to_light);\n        dist = _1055;\n        l = to_light / max(_1055, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1069 = reach / max(_860.w, 0.001000000047497451305389404296875f);\n        float _1075 = clamp(1.0f - (_1069 * _1069), 0.0f, 1.0f);\n        float _1077;\n        if (front)\n        {\n            _1077 = _1075 * _1075;\n        }\n        else\n        {\n            _1077 = 0.0f;\n        }\n        atten = _1077;\n        bool _1088 = _868 < 2.5f;\n        if ((_868 > 1.5f) && _1088)\n        {\n            int param_22 = _852 + 2;\n            float4 _1096 = fa_light_texel(param_22);\n            float _1106 = _1096.w;\n            int param_23 = _852 + 3;\n            float4 _1111 = fa_light_texel(param_23);\n            float _1112 = _1111.x;\n            float cos_inner = _1112;\n            if (_1112 > 1.5f)\n            {\n                cos_inner = lerp(_1106, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1106, cos_inner, dot(-l, normalize(_1096.xyz)));\n        }\n        if (_856 && (_868 < 1.5f))\n        {\n            int param_24 = _852 + 6;\n            float4 _1136 = fa_light_texel(param_24);\n            if (_1136.z > 0.5f)\n            {\n                float3 _1144 = -to_light;\n                int param_25 = _852 + 4;\n                int param_26 = _852 + 5;\n                float3 _1158 = fa_light_texel(param_25).xyz;\n                float3 _1162 = fa_light_texel(param_26).xyz;\n                float3 _1171 = float3(dot(_1144, _1158), dot(_1144, _1162), dot(_1144, cross(_1158, _1162)));\n                float3 param_27 = _1171;\n                int _1175 = fa_cube_face(param_27);\n                int param_28 = _1175;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1202 = float2(dot(_1171, cross(param_29, param_30)), dot(_1171, param_30)) / max(dot(_1171, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1206 = _1175 / 3;\n                float2 param_31 = _1136.xy + (float2(float(_1175 - (_1206 * 3)), float(_1206)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1202.x), 0.5f - (0.5f * _1202.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _852 + 7;\n            float4 _1236 = fa_light_texel(param_33);\n            if (_1236.z > 0.5f)\n            {\n                int param_34 = _852 + 2;\n                int param_35 = _852 + 4;\n                int param_36 = _852 + 5;\n                float2 param_37 = _1236.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_856 && _1088)\n            {\n                int param_42 = _852 + 6;\n                float4 _1283 = fa_light_texel(param_42);\n                int param_43 = _852 + 7;\n                float4 _1288 = fa_light_texel(param_43);\n                bool _1291 = _1283.z > 0.5f;\n                bool _1298;\n                if (!_1291)\n                {\n                    _1298 = _1288.z > 0.5f;\n                }\n                else\n                {\n                    _1298 = _1291;\n                }\n                if (_1298)\n                {\n                    int param_44 = _852 + 2;\n                    float4 _1305 = fa_light_texel(param_44);\n                    float3 _1309 = normalize(_1305.xyz);\n                    int param_45 = _852 + 4;\n                    float4 _1314 = fa_light_texel(param_45);\n                    int param_46 = _852 + 5;\n                    float4 _1319 = fa_light_texel(param_46);\n                    if (_1291)\n                    {\n                        float3 _1327 = -to_light;\n                        float _1334 = _1305.w;\n                        float _1350 = 0.5f / max(dot(_1327, _1309) * (sqrt(max(1.0f - (_1334 * _1334), 0.0f)) / max(_1334, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1283.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1327, _1314.xyz) * _1350), 0.5f - (dot(_1327, _1319.xyz) * _1350));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1288.z > 0.5f)\n                    {\n                        float2 param_49 = _1288.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1309;\n                        float3 param_52 = _1314.xyz;\n                        float3 param_53 = _1319.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _5926 = _865.xyz * atten;\n    if (_856)\n    {\n        _5926 *= fa_light_tint;\n    }\n    int _1419;\n    if (_882)\n    {\n        _1419 = 0;\n    }\n    else\n    {\n        _1419 = ((_868 > 1.5f) && (_868 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _5937 = { l, _5926, atten, 1.0f, dist, _1419 };\n    return _5937;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4957 = n < 0;\n    bool _4964;\n    if (!_4957)\n    {\n        _4964 = n >= fa_light_count();\n    }\n    else\n    {\n        _4964 = _4957;\n    }\n    if (_4964)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4972 = fa_cl_light(param);\n    int param_1 = _4972;\n    float _4976 = fa_baked_keep(param_1);\n    if (_4976 <= 0.0f)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4972;\n    float3 param_3 = i.world_pos;\n    float3 param_4 = i.world_normal;\n    LightSample _4992 = fa_light_sample_n(param_2, param_3, param_4);\n    LightSample _6108 = { _4992.direction, _4992.color * _4976, _4992.attenuation * _4976, _4992.shadow, _4992._distance, _4992.type };\n    return _6108;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2202 = fa_shadow_depth(param, param_1);\n    float _2206;\n    if (conv.x < 0.5f)\n    {\n        _2206 = _2202;\n    }\n    else\n    {\n        _2206 = (conv.y * conv.z) / (conv.z - (_2202 * (conv.z - conv.y)));\n    }\n    return _2206;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2252 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2258 = float2(cos(_2252), sin(_2252));\n    float2 dir = _2258;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2267;\n        if (k < 0.0f)\n        {\n            _2267 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2267 = k;\n        }\n        float _2286 = clamp((_2267 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2305 = sqrt((float(i) + 0.5f) * 0.0625f) * _2286;\n            float2 param_3 = uv + (dir * (_2155_fa_shadow_bias.zw * _2305));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2319 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2319 < (zr - (_2305 * plane)))\n            {\n                sum += _2319;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2347 = sum / cnt;\n        float _2357;\n        if (k < 0.0f)\n        {\n            _2357 = (-k) / max(_2347, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2357 = k;\n        }\n        radius = clamp(((max(zr - _2347, 0.0f) * unit) * _2357) / texel_m, 1.5f, 16.0f);\n        dir = _2258;\n    }\n    float lit = 0.0f;\n    int _2383 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2383; i_1++)\n    {\n        float _2402 = sqrt((float(i_1) + 0.5f) / float(_2383)) * radius;\n        float2 param_7 = uv + (dir * (_2155_fa_shadow_bias.zw * _2402));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2402 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2383);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2607 = _420_fa_pbr.z < 0.5f;\n    bool _2614;\n    if (!_2607)\n    {\n        _2614 = _2155_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2614 = _2607;\n    }\n    if (_2614)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2155_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2627 = fa_light_texel(param);\n    float _2628 = _2627.x;\n    if (_2628 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2637 = int(_2628 + 0.5f);\n    int param_1 = _2637;\n    float4 _2641 = fa_light_texel(param_1);\n    int param_2 = _2637 + 1;\n    float4 _2646 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2649 = _2641.y;\n    if (_2649 > 0.0f)\n    {\n        float _2666 = 1.0f - smoothstep(0.75f * _2649, _2649, length(world - _2155_fa_shadow_eye.xyz));\n        fade = _2666;\n        if (_2666 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2641.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2690 = (_2637 + 2) + (face * 6);\n    int param_4 = _2690;\n    int param_5 = _2690 + 1;\n    int param_6 = _2690 + 3;\n    float4 _2704 = fa_light_texel(param_6);\n    int param_7 = _2690 + 4;\n    float4 _2709 = fa_light_texel(param_7);\n    int param_8 = _2690 + 5;\n    float4 _2714 = fa_light_texel(param_8);\n    float _2726 = _2714.x * max(dot(_2704, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2731 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2754 = clamp(dot(n, _2704.xyz), -1.0f, 1.0f);\n    float _2773 = min(sqrt(1.0f - (_2754 * _2754)) / max(abs(dot(n, world - lpos)) / max(dot(_2704, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2776 = _2646.y;\n    float _2778;\n    if (_2776 > 0.0f)\n    {\n        _2778 = _2776;\n    }\n    else\n    {\n        _2778 = 1.5f * _2726;\n    }\n    float4 _2798 = float4(world + (n * (_2778 * sqrt(1.0f - (_2731 * _2731)))), 1.0f);\n    float _2802 = dot(_2704, _2798);\n    float _2805 = _2714.y;\n    if (_2802 < _2805)\n    {\n        return 1.0f;\n    }\n    float2 _2820 = float2(dot(fa_light_texel(param_4), _2798), dot(fa_light_texel(param_5), _2798)) / _2802.xx;\n    float _2822 = _2820.x;\n    bool _2825 = _2822 < _2709.x;\n    bool _2834;\n    if (!_2825)\n    {\n        _2834 = _2822 > _2709.z;\n    }\n    else\n    {\n        _2834 = _2825;\n    }\n    bool _2843;\n    if (!_2834)\n    {\n        _2843 = _2820.y < _2709.y;\n    }\n    else\n    {\n        _2843 = _2834;\n    }\n    bool _2852;\n    if (!_2843)\n    {\n        _2852 = _2820.y > _2709.w;\n    }\n    else\n    {\n        _2852 = _2843;\n    }\n    if (_2852)\n    {\n        return 1.0f;\n    }\n    float _2858 = _2646.x;\n    float _2860;\n    if (_2858 > 0.0f)\n    {\n        _2860 = _2858;\n    }\n    else\n    {\n        _2860 = 1.5f * _2726;\n    }\n    float2 param_9 = _2820;\n    float4 param_10 = _2709;\n    float param_11 = _2802 - (_2860 * (1.0f + (0.5f * _2773)));\n    float param_12 = _2726;\n    float param_13 = 1.0f;\n    float param_14 = _2714.z * 0.25f;\n    float param_15 = (_2726 * min(_2773, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2805, _2714.z);\n    int param_17 = int(_2641.z + 0.5f);\n    float param_18 = _2641.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2145;\n    if (i == 0)\n    {\n        _2145 = _2155_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2161;\n        if (i == 1)\n        {\n            _2161 = _2155_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2169;\n            if (i == 2)\n            {\n                _2169 = _2155_fa_shadow_split.z;\n            }\n            else\n            {\n                _2169 = _2155_fa_shadow_split.w;\n            }\n            _2161 = _2169;\n        }\n        _2145 = _2161;\n    }\n    return _2145;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2448 = max(_2155_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2453 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2459 = sqrt(1.0f - (_2453 * _2453));\n    float _2467 = min(_2459 / max(_2453, 0.20000000298023223876953125f), 4.0f);\n    float _2472;\n    if (_2155_fa_shadow_bias.y > 0.0f)\n    {\n        _2472 = _2155_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2472 = 1.5f * _2155_fa_shadow_info[ci].x;\n    }\n    float4 _2497 = mul(float4(world + (n * (_2472 * _2459)), 1.0f), _2155_fa_shadow_mat[ci]);\n    float _2504 = _2497.x;\n    bool _2507 = _2504 < _2155_fa_shadow_rect[ci].x;\n    bool _2516;\n    if (!_2507)\n    {\n        _2516 = _2504 > _2155_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2516 = _2507;\n    }\n    bool _2525;\n    if (!_2516)\n    {\n        _2525 = _2497.y < _2155_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2525 = _2516;\n    }\n    bool _2534;\n    if (!_2525)\n    {\n        _2534 = _2497.y > _2155_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2534 = _2525;\n    }\n    bool _2541;\n    if (!_2534)\n    {\n        _2541 = _2497.z > 1.0f;\n    }\n    else\n    {\n        _2541 = _2534;\n    }\n    if (_2541)\n    {\n        return -1.0f;\n    }\n    float _2549;\n    if (_2155_fa_shadow_bias.x > 0.0f)\n    {\n        _2549 = _2155_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2549 = 1.5f * _2155_fa_shadow_info[ci].x;\n    }\n    float2 param = _2497.xy;\n    float4 param_1 = _2155_fa_shadow_rect[ci];\n    float param_2 = _2497.z - ((_2549 * (1.0f + (0.5f * _2467))) / _2448);\n    float param_3 = _2155_fa_shadow_info[ci].x;\n    float param_4 = _2448;\n    float param_5 = _2448 * 0.25f;\n    float param_6 = ((_2155_fa_shadow_info[ci].x * min(_2467, 3.0f)) * 0.5f) / _2448;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2155_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2155_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_420_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2927 = int(_2155_fa_shadow_cfg.x + 0.5f);\n    if (_2927 < 1)\n    {\n        return 1.0f;\n    }\n    float _2942 = dot(world - _2155_fa_shadow_eye.xyz, _2155_fa_shadow_fwd.xyz);\n    int param = _2927 - 1;\n    if (_2942 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2954 = _2927 > 1;\n    bool _2961;\n    if (_2954)\n    {\n        _2961 = _2942 > _2155_fa_shadow_split.x;\n    }\n    else\n    {\n        _2961 = _2954;\n    }\n    if (_2961)\n    {\n        ci = 1;\n    }\n    bool _2965 = _2927 > 2;\n    bool _2972;\n    if (_2965)\n    {\n        _2972 = _2942 > _2155_fa_shadow_split.y;\n    }\n    else\n    {\n        _2972 = _2965;\n    }\n    if (_2972)\n    {\n        ci = 2;\n    }\n    bool _2976 = _2927 > 3;\n    bool _2983;\n    if (_2976)\n    {\n        _2983 = _2942 > _2155_fa_shadow_split.z;\n    }\n    else\n    {\n        _2983 = _2976;\n    }\n    if (_2983)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _2994 = min(_2927, 4);\n    float _3035;\n    for (int c = ci; c < _2994; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3014 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _3014;\n            break;\n        }\n        if (_3014 < 0.0f)\n        {\n            continue;\n        }\n        s = _3014;\n        ci = c;\n        if (_2155_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3035 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3035 = _2155_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _3054 = _2155_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3035, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_2942 - (fa_shadow_split_at(param_7) - _3054)) / _3054, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3086;\n        if ((ci + 1) < _2927)\n        {\n            _3086 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3086 = 1.0f;\n        }\n        s = lerp(s, _3086, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4464 = _420_fa_ct_a.x < 0.5f;\n    bool _4471;\n    if (!_4464)\n    {\n        _4471 = _2155_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4471 = _4464;\n    }\n    if (_4471)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2155_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4484 = fa_light_texel(param);\n    float _4485 = _4484.y;\n    float len = _4485;\n    if (_4485 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4497 = length(world - _420_fa_camera_pos.xyz);\n    float _4507 = 1.0f - smoothstep(0.5f * _420_fa_ct_b.x, _420_fa_ct_b.x, _4497);\n    if (_4507 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4513 = len;\n    float _4516 = min(_4513, 0.89999997615814208984375f * dist);\n    len = _4516;\n    float _4521 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4497);\n    float _4526 = _4521 + (0.5f * _4516);\n    float3 _4532 = world + (gn * _4521);\n    float _4534 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4598;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4549 = (float(k) + _4534) * 0.083333335816860198974609375f;\n        float3 _4557 = _4532 + (l * (_4549 * len));\n        float4 _4563 = float4(_4557, 1.0f);\n        float _4569 = dot(_420_fa_ct_vpw, _4563);\n        if (_4569 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4589 = float2(dot(_420_fa_ct_vpx, _4563), dot(_420_fa_ct_vpy, _4563)) / _4569.xx;\n        float _4593 = _4589.x * 0.5f;\n        float _4594 = _4593 + 0.5f;\n        if (_420_fa_ct_a.y > 0.5f)\n        {\n            _4598 = (_4589.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4598 = 0.5f - (_4589.y * 0.5f);\n        }\n        bool _4614 = _4594 < 0.0f;\n        bool _4621;\n        if (!_4614)\n        {\n            _4621 = _4594 >= 1.0f;\n        }\n        else\n        {\n            _4621 = _4614;\n        }\n        bool _4628;\n        if (!_4621)\n        {\n            _4628 = _4598 < 0.0f;\n        }\n        else\n        {\n            _4628 = _4621;\n        }\n        bool _4635;\n        if (!_4628)\n        {\n            _4635 = _4598 >= 1.0f;\n        }\n        else\n        {\n            _4635 = _4628;\n        }\n        if (_4635)\n        {\n            break;\n        }\n        float4 _4662 = fa_screen_tex.Load(int3(clamp(int2(float2(_4594, _4598) * _420_fa_ct_a.zw), int2(0, 0), int2(_420_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_4662.w < 0.5f)\n        {\n            continue;\n        }\n        float _4681 = (dot(_420_fa_ct_fwd.xyz, _4557) + _420_fa_ct_fwd.w) - _4662.x;\n        if ((_4681 > _4521) && (_4681 < _4526))\n        {\n            occ = max(occ, (1.0f - (_4549 * _4549)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4594, 0.5f - _4593), min(_4598, 1.0f - _4598))));\n        }\n    }\n    return 1.0f - (occ * _4507);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4784 = fa_baked_keep(param);\n    if (_4784 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _6070 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6070;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4810 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6072 = _4810.color;\n    float _6073 = _4810.attenuation;\n    float _6074 = _4810.shadow;\n    bool _4813 = _4810.type == 0;\n    if (_4813 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4810.direction;\n        float _4824 = fa_shadow_factor(param_5, param_6);\n        _6074 = _4824;\n        _6072 *= _4824;\n    }\n    else\n    {\n        bool _4835 = _4810.type != 0;\n        bool _4841;\n        if (_4835)\n        {\n            _4841 = _6073 > 0.0f;\n        }\n        else\n        {\n            _4841 = _4835;\n        }\n        if (_4841)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4810.direction;\n            float _4860 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6074 = _4860;\n            _6072 *= _4860;\n        }\n    }\n    bool _4870 = _420_fa_ct_a.x > 0.5f;\n    bool _4876;\n    if (_4870)\n    {\n        _4876 = _6073 > 0.0f;\n    }\n    else\n    {\n        _4876 = _4870;\n    }\n    if (_4876)\n    {\n        float _4883;\n        if (_4813)\n        {\n            _4883 = 1000000000.0f;\n        }\n        else\n        {\n            _4883 = _4810._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4810.direction;\n        float param_18 = _4883;\n        float _4901 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6074 *= _4901;\n        _6072 *= _4901;\n    }\n    float _4914 = _6073;\n    float _4915 = _4914 * _4784;\n    _6073 = _4915;\n    float3 _4919 = _6072;\n    float3 _4920 = _4919 * _4784;\n    _6072 = _4920;\n    LightSample _6089 = { _4810.direction, _4920, _4915, _6074, _4810._distance, _4810.type };\n    return _6089;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4931 = n < 0;\n    bool _4938;\n    if (!_4931)\n    {\n        _4938 = n >= fa_light_count();\n    }\n    else\n    {\n        _4938 = _4931;\n    }\n    if (_4938)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    LightSample _4953 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4953;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3849 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3857 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3860 = int(_3849);\n    int _3863 = int(_3857);\n    float _3873 = _3857 - float(_3863);\n    int _3929 = (_3860 * 9) + _3863;\n    int _3949 = ((_3860 + 1) * 9) + _3863;\n    return lerp(lerp(_3924[_3929], _3924[_3929 + 1], _3873), lerp(_3924[_3949], _3924[_3949 + 1], _3873), _3849 - float(_3860));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _5938 = false;\n    float _5939 = 1.0f;\n    float _5940 = 1.0f;\n    float _5941 = 1.0f;\n    float _5942 = 0.0f;\n    float _5943 = 0.0f;\n    float _5944 = 0.0f;\n    float _5945 = 0.0f;\n    float _5947 = 1.0f;\n    bool _5948 = false;\n    float3 _5949 = 0.0f.xxx;\n    float _5950 = 1.0f;\n    float _5951 = 1.0f;\n    float _5952 = 1.0f;\n    float _5953 = 0.0f;\n    float _5954 = 0.0f;\n    float3 _5955 = float3(1.0f, 0.0f, 0.0f);\n    float3 _5956 = float3(0.0f, 0.0f, 1.0f);\n    float _5957 = 1.0f;\n    float _5958 = 1.0f;\n    float _4000 = clamp(s.specular, 0.0f, 1.0f);\n    float _4004 = clamp(s.ior, 1.0f, 3.0f);\n    bool _4009 = (_4000 != 1.0f) || (_4004 != 1.5f);\n    bool _4018;\n    if (!_4009)\n    {\n        _4018 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _4018 = _4009;\n    }\n    if (_4018)\n    {\n        float _4026 = (_4004 - 1.0f) / (_4004 + 1.0f);\n        f0 = lerp(min((_4026 * _4026).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _4000, s.albedo, metallic.xxx);\n        _5939 = lerp(_4000, 1.0f, metallic);\n        _5938 = true;\n    }\n    float _4053 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4053 > 0.0f)\n    {\n        float _4061 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _5942 = _4053;\n        _5943 = _4061;\n        float _4068 = _4061 * _4061;\n        _5944 = _4068;\n        _5945 = _4068 * _4068;\n        float _4080 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _5947 = _4080;\n        _5940 = 1.0f - (_4053 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _4080, 0.0f, 1.0f), 5.0f))));\n        _5938 = true;\n    }\n    float3 _4099 = max(s.sheen_color, 0.0f.xxx);\n    float _4108 = max(_4099.x, max(_4099.y, _4099.z));\n    if (_4108 > 0.0f)\n    {\n        float _4116 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _5948 = true;\n        _5949 = _4099;\n        _5950 = _4116;\n        _5951 = _4116 * _4116;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _4116;\n        float _4133 = fa_sheen_albedo(param, param_1);\n        _5953 = _4133;\n        _5952 = 1.0f - min(_4108 * _4133, 1.0f);\n        _5938 = true;\n    }\n    _5941 = _5940 * _5952;\n    float _4152 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_4152 != 0.0f)\n    {\n        float3 _4167 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _4167;\n        if (dot(_4167, _4167) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _4179 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_4179.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _4179.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _4179.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _4183 = t;\n        float3 _4184 = normalize(_4183);\n        t = _4184;\n        float3 _4209 = normalize((_4184 * cos(s.anisotropy_rotation)) + ((cross(n, _4184) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _5955 = _4209;\n        _5956 = cross(n, _4209);\n        float _4219 = roughness * roughness;\n        float _4225 = lerp(_4219, 1.0f, _4152 * _4152);\n        bool _4227 = _4152 > 0.0f;\n        _5957 = _4227 ? _4225 : _4219;\n        _5958 = _4227 ? _4219 : _4225;\n        _5954 = _4152;\n        _5938 = true;\n    }\n    FaLayers _5980 = { _5938, _5939, _5940, _5941, _5942, _5943, _5944, _5945, i.world_normal, _5947, _5948, _5949, _5950, _5951, _5952, _5953, _5954, _5955, _5956, _5957, _5958 };\n    return _5980;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3781 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3784 = _3781.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3784 * _3784, exp2((-9.27999973297119140625f) * ndv)) * _3784) + _3781.y)) + _3781.zw;\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3216 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3219 = _3216.x;\n    float _3221 = _3216.z;\n    float2 e = float2(_3219, _3221);\n    if (_3216.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3221)) * ((_3219 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3219)) * ((_3221 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3255_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3255_dummy_parameter)));\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _3268;\n    if (lv == 0)\n    {\n        _3268 = 0.0f;\n    }\n    else\n    {\n        _3268 = res + 2.0f;\n    }\n    float _3278;\n    if (lv == 0)\n    {\n        _3278 = 0.0f;\n    }\n    else\n    {\n        _3278 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_3268, _3278)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _3324;\n    if (res > 64.5f)\n    {\n        _3324 = 5.0f;\n    }\n    else\n    {\n        _3324 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _3339 = clamp(rough, 0.0f, 1.0f) * (_3324 - 1.0f);\n    int _3346 = int(min(floor(_3339), _3324 - 2.0f));\n    float _3351 = _3339 - float(_3346);\n    float3 param = d;\n    float2 _3355 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3346;\n    float2 param_4 = _3355;\n    float3 _3365 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3351 < 0.00200000009499490261077880859375f)\n    {\n        return _3365;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3346 + 1;\n    float2 param_8 = _3355;\n    return lerp(_3365, fa_probe_level(param_5, param_6, param_7, param_8), _3351.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _3403 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3410 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3417 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3423 = dot(bx.xyz, d);\n    float _3427 = dot(by.xyz, d);\n    float _3431 = dot(bz.xyz, d);\n    float _3437;\n    if (_3423 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3437 = (1.0f - _3403) / _3423;\n    }\n    else\n    {\n        float _3451;\n        if (_3423 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3451 = ((-1.0f) - _3403) / _3423;\n        }\n        else\n        {\n            _3451 = 1000000015047466219876688855040.0f;\n        }\n        _3437 = _3451;\n    }\n    float tx = _3437;\n    float _3468;\n    if (_3427 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3468 = (1.0f - _3410) / _3427;\n    }\n    else\n    {\n        float _3481;\n        if (_3427 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3481 = ((-1.0f) - _3410) / _3427;\n        }\n        else\n        {\n            _3481 = 1000000015047466219876688855040.0f;\n        }\n        _3468 = _3481;\n    }\n    float ty = _3468;\n    float _3497;\n    if (_3431 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3497 = (1.0f - _3417) / _3431;\n    }\n    else\n    {\n        float _3510;\n        if (_3431 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3510 = ((-1.0f) - _3417) / _3431;\n        }\n        else\n        {\n            _3510 = 1000000015047466219876688855040.0f;\n        }\n        _3497 = _3510;\n    }\n    float _3522 = tx;\n    float _3525 = (_3522 > 0.0f) ? _3522 : 1000000015047466219876688855040.0f;\n    tx = _3525;\n    float _3526 = ty;\n    float _3529 = (_3526 > 0.0f) ? _3526 : 1000000015047466219876688855040.0f;\n    ty = _3529;\n    float _3539 = min(_3525, min(_3529, (_3497 > 0.0f) ? _3497 : 1000000015047466219876688855040.0f));\n    if (_3539 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _3555 = (fa_world_pos + (d * _3539)) - posw.xyz;\n    float3 _3560;\n    if (dot(_3555, _3555) > 1.0000000133514319600180897396058e-10f)\n    {\n        _3560 = normalize(_3555);\n    }\n    else\n    {\n        _3560 = d;\n    }\n    return _3560;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _3606 = (1.0f - _420_fa_rpa_tile.w) - _420_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_3606 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_420_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _420_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3636 = rough * rough;\n            float _3667 = 0.60000002384185791015625f * _3636;\n            base = lerp(lerp(_420_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_420_fa_env_horizon.xyz, _420_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3636)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3667, 0.0500000007450580596923828125f + _3667, d.y).xxx), ((_420_fa_env_sky.xyz + _420_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3636 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _3606;\n    }\n    if (_420_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _420_fa_rpa_tile;\n        float4 param_5 = _420_fa_rpa_pos;\n        float4 param_6 = _420_fa_rpa_bx;\n        float4 param_7 = _420_fa_rpa_by;\n        float4 param_8 = _420_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _3726 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3726 * _420_fa_rpa_tile.w);\n    }\n    if (_420_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _420_fa_rpb_tile;\n        float4 param_12 = _420_fa_rpb_pos;\n        float4 param_13 = _420_fa_rpb_bx;\n        float4 param_14 = _420_fa_rpb_by;\n        float4 param_15 = _420_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _3758 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3758 * _420_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness, float occlusion)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4260;\n        if (L.aniso >= 0.0f)\n        {\n            _4260 = L.b;\n        }\n        else\n        {\n            _4260 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4260, v), _4260), (abs(L.aniso) * smoothstep(0.0f, 0.25f, roughness)).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4296 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4296.x) + (L.f90.xxx * _4296.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4354 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4354.x) + _4354.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3823 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3823.x) + _3823.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4393 = clamp(s.metallic, 0.0f, 1.0f);\n    float _4397 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _4404 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _4393.xxx);\n    float3 f0 = _4404;\n    float3 _4408 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _4408;\n    float3 param_3 = i.view_dir;\n    float param_4 = _4393;\n    float param_5 = _4397;\n    float3 param_6 = _4404;\n    FaLayers _4425 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4425.on)\n    {\n        FaLayers param_7 = _4425;\n        float3 param_8 = _4408;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _4397;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    float3 param_13 = _4408;\n    float3 param_14 = i.view_dir;\n    float3 param_15 = f0;\n    float param_16 = _4397;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _5023 = fa_light_unshadowed(param, param_1);\n        float _5031 = dot(_5023.color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_5031 > bestPower)\n        {\n            bestPower = _5031;\n            best = n;\n        }\n    }\n    float3 lit = (_420_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _5060 = fa_light(param_2, param_3);\n        float _5068;\n        if (dot(s.normal, _5060.direction) > 0.5f)\n        {\n            _5068 = 1.0f;\n        }\n        else\n        {\n            _5068 = _5074_dark;\n        }\n        lit += ((s.albedo * _5060.color) * _5068);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _5074_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2155_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3114 = int(_2155_fa_shadow_cfg.x + 0.5f);\n    float _3124 = dot(world - _2155_fa_shadow_eye.xyz, _2155_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3129 = _3114 > 0;\n    bool _3138;\n    if (_3129)\n    {\n        int param = _3114 - 1;\n        _3138 = _3124 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3138 = _3129;\n    }\n    if (_3138)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3144 = _3114 > 1;\n        bool _3151;\n        if (_3144)\n        {\n            _3151 = _3124 > _2155_fa_shadow_split.x;\n        }\n        else\n        {\n            _3151 = _3144;\n        }\n        if (_3151)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3157 = _3114 > 2;\n        bool _3164;\n        if (_3157)\n        {\n            _3164 = _3124 > _2155_fa_shadow_split.y;\n        }\n        else\n        {\n            _3164 = _3157;\n        }\n        if (_3164)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3170 = _3114 > 3;\n        bool _3177;\n        if (_3170)\n        {\n            _3177 = _3124 > _2155_fa_shadow_split.z;\n        }\n        else\n        {\n            _3177 = _3170;\n        }\n        if (_3177)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5792 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5792 = -_5792;\n    }\n    float3 _5461 = normalize(_420_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5805 = { fa_world_pos, _5792, fa_world_tangent, fa_uv, fa_vertex_color, _5461, gl_FrontFacing };\n    SurfaceInput param_1 = _5805;\n    Surface _5469 = fa_standard_surface(param_1);\n    float3 _5823 = _5469.albedo;\n    float _5824 = _5469.alpha;\n    float3 _5825 = _5469.normal;\n    float _5826 = _5469.metallic;\n    float _5827 = _5469.roughness;\n    float _5828 = _5469.occlusion;\n    float3 _5829 = _5469.emission;\n    float _5830 = _5469.clearcoat;\n    float _5831 = _5469.clearcoat_roughness;\n    float3 _5832 = _5469.sheen_color;\n    float _5833 = _5469.sheen_roughness;\n    float _5834 = _5469.anisotropy;\n    float _5835 = _5469.anisotropy_rotation;\n    float _5836 = _5469.specular;\n    float _5837 = _5469.ior;\n    float3 _5838 = _5469.specular_color;\n    float _5839 = _5469.transmission;\n    float _5840 = _5469.thickness;\n    float3 _5841 = _5469.attenuation_color;\n    float _5842 = _5469.attenuation_distance;\n    SurfaceInput _5813 = { fa_world_pos, _5792, fa_world_tangent, fa_uv, fa_vertex_color, _5461, gl_FrontFacing };\n    SurfaceInput param_2 = _5813;\n    Surface param_3 = _5469;\n    surface(param_2, param_3);\n    _5823 = param_3.albedo;\n    _5824 = param_3.alpha;\n    _5825 = param_3.normal;\n    _5826 = param_3.metallic;\n    _5827 = param_3.roughness;\n    _5828 = param_3.occlusion;\n    _5829 = param_3.emission;\n    _5830 = param_3.clearcoat;\n    _5831 = param_3.clearcoat_roughness;\n    _5832 = param_3.sheen_color;\n    _5833 = param_3.sheen_roughness;\n    _5834 = param_3.anisotropy;\n    _5835 = param_3.anisotropy_rotation;\n    _5836 = param_3.specular;\n    _5837 = param_3.ior;\n    _5838 = param_3.specular_color;\n    _5839 = param_3.transmission;\n    _5840 = param_3.thickness;\n    _5841 = param_3.attenuation_color;\n    _5842 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5792;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5823 = param_6;\n    _5825 = param_7;\n    fa_lod_dither();\n    float3 result;\n    if (_420_fa_emissive.w > 0.5f)\n    {\n        result = _5823;\n    }\n    else\n    {\n        float3 _5509 = _5825;\n        float3 _5510 = normalize(_5509);\n        _5825 = _5510;\n        SurfaceInput _5821 = { fa_world_pos, _5792, fa_world_tangent, fa_uv, fa_vertex_color, _5461, gl_FrontFacing };\n        SurfaceInput param_8 = _5821;\n        Surface _5924 = { _5823, _5824, _5510, _5826, _5827, _5828, _5829, _5830, _5831, _5832, _5833, _5834, _5835, _5836, _5837, _5838, _5839, _5840, _5841, _5842 };\n        Surface param_9 = _5924;\n        float3 _5521 = lighting(param_8, param_9);\n        result = _5521;\n    }\n    float3 _5525 = result;\n    float3 _5526 = _5525 + _5829;\n    result = _5526;\n    float3 param_10 = _5526;\n    float3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _5535 = _420_fa_fog.w > 0.0f;\n    bool _5542;\n    if (!_5535)\n    {\n        _5542 = _420_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5542 = _5535;\n    }\n    if (_5542)\n    {\n        float3 _5551 = fa_world_pos - _420_fa_camera_pos.xyz;\n        float _5557 = dot(_5551, _420_fa_fog_c.xyz);\n        bool _5561 = _420_fa_fog_c.w > 0.5f;\n        float _5562;\n        if (_5561)\n        {\n            _5562 = _5557;\n        }\n        else\n        {\n            _5562 = length(_5551);\n        }\n        float _5574 = _5562 - _420_fa_fog_b.x;\n        if (_5574 > 0.0f)\n        {\n            float _5583 = _420_fa_fog.w * _5574;\n            float tau = _5583 * _5583;\n            if (_420_fa_fog_b.y > 0.0f)\n            {\n                float _5599;\n                if (_5561)\n                {\n                    _5599 = fa_world_pos.y - (_420_fa_fog_c.y * _5557);\n                }\n                else\n                {\n                    _5599 = _420_fa_camera_pos.y;\n                }\n                float _5620 = lerp(_5599, fa_world_pos.y, clamp(_420_fa_fog_b.x / _5562, 0.0f, 1.0f));\n                float _5624 = fa_world_pos.y - _5620;\n                float _5629 = _5620 - _420_fa_fog_b.z;\n                float _5634 = fa_world_pos.y - _420_fa_fog_b.z;\n                bool _5637 = _5629 <= 0.0f;\n                bool _5638 = !_5637;\n                bool _5644;\n                if (_5638)\n                {\n                    _5644 = _420_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5644 = _5637;\n                }\n                float _5645;\n                if (_5644)\n                {\n                    _5645 = _420_fa_fog_b.y;\n                }\n                else\n                {\n                    _5645 = _420_fa_fog_b.y * exp(-min(_420_fa_fog_b.w * _5629, 80.0f));\n                }\n                bool _5672;\n                if (_5638)\n                {\n                    _5672 = _420_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5672 = _5637;\n                }\n                float _5673;\n                if (_5672)\n                {\n                    _5673 = _420_fa_fog_b.y * _5629;\n                }\n                else\n                {\n                    _5673 = (_420_fa_fog_b.y * (1.0f - exp(-min(_420_fa_fog_b.w * _5629, 80.0f)))) / _420_fa_fog_b.w;\n                }\n                bool _5698 = _5634 <= 0.0f;\n                bool _5705;\n                if (!_5698)\n                {\n                    _5705 = _420_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5705 = _5698;\n                }\n                float _5706;\n                if (_5705)\n                {\n                    _5706 = _420_fa_fog_b.y * _5634;\n                }\n                else\n                {\n                    _5706 = (_420_fa_fog_b.y * (1.0f - exp(-min(_420_fa_fog_b.w * _5634, 80.0f)))) / _420_fa_fog_b.w;\n                }\n                float _5733;\n                if (abs(_5624) < 0.001000000047497451305389404296875f)\n                {\n                    _5733 = _5645;\n                }\n                else\n                {\n                    _5733 = (_5706 - _5673) / _5624;\n                }\n                tau += (_5574 * max(_5733, 0.0f));\n            }\n            result = lerp(result, _420_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5824);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_2155",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_5074",
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
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 9
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
              "hlsl_register_t_n": 10
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _384 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _384;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_391, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3924[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _6352 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _420_fa_camera_pos : packoffset(c0);\n    float4 _420_fa_ambient : packoffset(c1);\n    float4 _420_fa_base_color : packoffset(c2);\n    float4 _420_fa_emissive : packoffset(c3);\n    float4 _420_fa_model_emissive : packoffset(c4);\n    float4 _420_fa_pbr : packoffset(c5);\n    float4 _420_fa_maps : packoffset(c6);\n    float4 _420_fa_fog : packoffset(c7);\n    float4 _420_fa_fog_b : packoffset(c8);\n    float4 _420_fa_fog_c : packoffset(c9);\n    float4 _420_fa_counts : packoffset(c10);\n    float4 _420_fa_env_sky : packoffset(c11);\n    float4 _420_fa_env_horizon : packoffset(c12);\n    float4 _420_fa_time : packoffset(c13);\n    float4 _420_fa_cl_vpx : packoffset(c14);\n    float4 _420_fa_cl_vpy : packoffset(c15);\n    float4 _420_fa_cl_vpw : packoffset(c16);\n    float4 _420_fa_cl_fwd : packoffset(c17);\n    float4 _420_fa_cl_grid : packoffset(c18);\n    float4 _420_fa_cl_info : packoffset(c19);\n    float4 _420_fa_layers_a : packoffset(c20);\n    float4 _420_fa_layers_b : packoffset(c21);\n    float4 _420_fa_layers_c : packoffset(c22);\n    float4 _420_fa_layers_d : packoffset(c23);\n    float4 _420_fa_ct_a : packoffset(c24);\n    float4 _420_fa_ct_b : packoffset(c25);\n    float4 _420_fa_ct_vpx : packoffset(c26);\n    float4 _420_fa_ct_vpy : packoffset(c27);\n    float4 _420_fa_ct_vpw : packoffset(c28);\n    float4 _420_fa_ct_fwd : packoffset(c29);\n    float4 _420_fa_tr_a : packoffset(c30);\n    float4 _420_fa_tr_b : packoffset(c31);\n    float4 _420_fa_probe_sh[9] : packoffset(c32);\n    float4 _420_fa_atlas : packoffset(c41);\n    float4 _420_fa_rpa_tile : packoffset(c42);\n    float4 _420_fa_rpa_pos : packoffset(c43);\n    float4 _420_fa_rpa_bx : packoffset(c44);\n    float4 _420_fa_rpa_by : packoffset(c45);\n    float4 _420_fa_rpa_bz : packoffset(c46);\n    float4 _420_fa_rpb_tile : packoffset(c47);\n    float4 _420_fa_rpb_pos : packoffset(c48);\n    float4 _420_fa_rpb_bx : packoffset(c49);\n    float4 _420_fa_rpb_by : packoffset(c50);\n    float4 _420_fa_rpb_bz : packoffset(c51);\n    float4 _420_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2155_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2155_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2155_fa_shadow_info[4] : packoffset(c20);\n    float4 _2155_fa_shadow_split : packoffset(c24);\n    float4 _2155_fa_shadow_cfg : packoffset(c25);\n    float4 _2155_fa_shadow_bias : packoffset(c26);\n    float4 _2155_fa_shadow_eye : packoffset(c27);\n    float4 _2155_fa_shadow_fwd : packoffset(c28);\n    float4 _2155_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _5074_dark : packoffset(c0);\n    float _5074_fa_pad0 : packoffset(c0.y);\n    float _5074_fa_pad1 : packoffset(c0.z);\n    float _5074_fa_pad2 : packoffset(c0.w);\n    float _5074_skyAmount : packoffset(c1);\n    float _5074_fa_pad3 : packoffset(c1.y);\n    float _5074_fa_pad4 : packoffset(c1.z);\n    float _5074_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t9);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_screen_tex : register(t10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1437 = _420_fa_cl_info.x < 0.0f;\n    bool _1444;\n    if (!_1437)\n    {\n        _1444 = _420_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1444 = _1437;\n    }\n    bool _1452;\n    if (!_1444)\n    {\n        _1452 = _420_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1452 = _1444;\n    }\n    bool _1459;\n    if (!_1452)\n    {\n        _1459 = _420_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1459 = _1452;\n    }\n    bool _1466;\n    if (!_1459)\n    {\n        _1466 = _420_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1466 = _1459;\n    }\n    if (_1466)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1476 = float4(world_pos, 1.0f);\n    float _1482 = dot(_420_fa_cl_vpw, _1476);\n    if (!(_1482 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1504 = float2(dot(_420_fa_cl_vpx, _1476), dot(_420_fa_cl_vpy, _1476)) / _1482.xx;\n    int _1508 = int(_420_fa_cl_grid.x);\n    int _1512 = int(_420_fa_cl_grid.y);\n    int param = (int(_420_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_420_fa_cl_fwd.xyz, world_pos) + _420_fa_cl_fwd.w, _420_fa_cl_grid.w) / _420_fa_cl_grid.w) * _420_fa_cl_grid.z)), 0, int(_420_fa_cl_info.y) - 1) * _1512) + clamp(int(floor(((_1504.y * 0.5f) + 0.5f) * _420_fa_cl_grid.y)), 0, _1512 - 1)) * _1508)) + clamp(int(floor(((_1504.x * 0.5f) + 0.5f) * _420_fa_cl_grid.x)), 0, _1508 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1588 = fa_cluster_texel(param);\n    return int2(int(_1588.x), int(_1588.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_420_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4758 = fa_cluster_lookup(param);\n    fa_cl_slot = _4758.x;\n    fa_cl_local = _4758.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5135 = fa_linear_to_srgb(param);\n        c = _5135;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5143 = fa_srgb_to_linear(param_1);\n            c = _5143;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _350;\n    if (i.front_facing)\n    {\n        _350 = i.world_normal;\n    }\n    else\n    {\n        _350 = -i.world_normal;\n    }\n    float3 _374 = normalize(i.world_tangent.xyz - (_350 * dot(_350, i.world_tangent.xyz)));\n    float3 _402 = normalize(((_374 * m.x) + ((cross(_350, _374) * i.world_tangent.w) * m.y)) + (_350 * m.z));\n    float3 _405;\n    if (i.front_facing)\n    {\n        _405 = _402;\n    }\n    else\n    {\n        _405 = -_402;\n    }\n    return _405;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _420_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5174 = fa_tex_fix(param_2, param_3);\n    float4 _6314 = base_t;\n    _6314.x = _5174.x;\n    _6314.y = _5174.y;\n    _6314.z = _5174.z;\n    base_t = _6314;\n    float4 _5188 = (_6314 * _420_fa_base_color) * i.vertex_color;\n    float3 _6120 = i.world_normal;\n    if (_420_fa_maps.z > 0.5f)\n    {\n        float param_4 = _420_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5220 = fa_tex_fix(param_6, param_7);\n        float3 _5223 = (_5220 * 2.0f) - 1.0f.xxx;\n        float2 _5228 = _5223.xy * _420_fa_maps.x;\n        float3 _6322 = _5223;\n        _6322.x = _5228.x;\n        _6322.y = _5228.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6322;\n        _6120 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _420_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _5256 = fa_tex_fix(param_12, param_13);\n    float4 _6325 = mrt;\n    _6325.x = _5256.x;\n    _6325.y = _5256.y;\n    _6325.z = _5256.z;\n    mrt = _6325;\n    float4 _5284 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _420_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _5284.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _5295 = fa_tex_fix(param_16, param_17);\n    float param_18 = _420_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _5325 = fa_tex_fix(param_20, param_21);\n    float _6125 = _420_fa_layers_a.x;\n    float _6126 = _420_fa_layers_a.y;\n    float _6129 = _420_fa_layers_a.z;\n    float _6128 = _420_fa_layers_b.w;\n    float _6131 = _420_fa_layers_c.x;\n    if (_420_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_420_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6125 *= _5295.y;\n            _6126 *= _5295.z;\n            _6128 *= _5284.w;\n        }\n        if (_420_fa_layers_c.z > 1.5f)\n        {\n            _6129 *= mrt.x;\n            _6131 *= mrt.w;\n        }\n    }\n    Surface _6158 = { _5188.xyz, _5188.w, _6120, clamp(_420_fa_pbr.x * _5256.z, 0.0f, 1.0f), clamp(_420_fa_pbr.y * _5256.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_420_fa_maps.y * (_5295.x - 1.0f)), _420_fa_emissive.xyz + (_420_fa_model_emissive.xyz * _5325), _6125, _6126, _420_fa_layers_b.xyz, _6128, _6129, _420_fa_layers_a.w, _6131, _420_fa_layers_c.y, _420_fa_layers_d.xyz, _420_fa_tr_a.x, _420_fa_tr_a.y, _420_fa_tr_b.xyz, _420_fa_tr_a.z };\n    return _6158;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1668 = rect.zw - rect.xy;\n    float2 _1672 = _1668 * atlas;\n    float2 _1676 = ddx * _1672;\n    float2 _1680 = ddy * _1672;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1668), clamp(0.5f * log2(max(max(dot(_1676, _1676), dot(_1680, _1680)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1713 = _420_fa_counts.y < 0.5f;\n    bool _1720;\n    if (!_1713)\n    {\n        _1720 = _420_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1720 = _1713;\n    }\n    if (_1720)\n    {\n        return;\n    }\n    float3 _1726 = ddx(world_pos);\n    float3 _1729 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1733 = fa_cluster_texel(param);\n    int _1737 = int(_1733.w);\n    if (_1737 < 1)\n    {\n        return;\n    }\n    int _1747 = int(_420_fa_counts.y + 0.5f);\n    int param_1 = _1747;\n    float4 _1751 = fa_light_texel(param_1);\n    float2 _1754 = _1751.yz;\n    int _1758 = int(_1751.w);\n    int param_2 = _1747 + 1;\n    float4 _1763 = fa_light_texel(param_2);\n    float _1764 = _1763.x;\n    int _1770 = int(_420_fa_counts.w + 0.5f) - 1;\n    int _1774 = int(_1733.z);\n    float3 _2039;\n    for (int k = 0; k < _1737; k++)\n    {\n        int _1787 = _1774 + k;\n        int param_3 = _1758 + (_1787 >> 2);\n        int _1804 = (_1747 + 2) + (int(fa_light_texel(param_3)[_1787 & 3]) * 7);\n        int param_4 = _1804 + 6;\n        float4 _1809 = fa_light_texel(param_4);\n        if (((int(_1809.w + 0.5f) >> _1770) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1804;\n        float4 _1824 = fa_light_texel(param_5);\n        int param_6 = _1804 + 1;\n        float4 _1829 = fa_light_texel(param_6);\n        int param_7 = _1804 + 2;\n        float4 _1834 = fa_light_texel(param_7);\n        float3 _1837 = _1824.xyz;\n        float _1842 = dot(_1837, world_pos) + _1824.w;\n        float3 _1844 = _1829.xyz;\n        float _1849 = dot(_1844, world_pos) + _1829.w;\n        float3 _1851 = _1834.xyz;\n        float _1856 = dot(_1851, world_pos) + _1834.w;\n        bool _1861 = abs(_1842) > 0.5f;\n        bool _1869;\n        if (!_1861)\n        {\n            _1869 = abs(_1849) > 0.5f;\n        }\n        else\n        {\n            _1869 = _1861;\n        }\n        bool _1877;\n        if (!_1869)\n        {\n            _1877 = abs(_1856) > 0.5f;\n        }\n        else\n        {\n            _1877 = _1869;\n        }\n        if (_1877)\n        {\n            continue;\n        }\n        float _1892 = clamp(dot(geo_normal, normalize(_1851)) * _1809.z, 0.0f, 1.0f);\n        if (_1892 <= 0.0f)\n        {\n            continue;\n        }\n        float _1912 = (clamp((0.5f - abs(_1856)) * 10.0f, 0.0f, 1.0f) * _1892) * _1809.x;\n        float2 _1920 = float2(_1842 + 0.5f, 0.5f - _1849);\n        float2 _1930 = float2(dot(_1837, _1726), dot(_1844, _1726));\n        float2 _1940 = float2(dot(_1837, _1729), dot(_1844, _1729));\n        int param_8 = _1804 + 5;\n        float4 _1945 = fa_light_texel(param_8);\n        int param_9 = _1804 + 3;\n        float4 _1950 = fa_light_texel(param_9);\n        int param_10 = _1804 + 4;\n        float4 _1955 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1945.xyz;\n        bool _1965 = _1950.z > _1950.x;\n        if (_1965)\n        {\n            float4 param_11 = _1950;\n            float2 param_12 = _1920;\n            float2 param_13 = _1754;\n            float2 param_14 = _1930;\n            float2 param_15 = _1940;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1764 > 0.5f) && (_1764 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1991 = fa_dc_to_linear(param_16);\n                float4 _6208 = tx;\n                _6208.x = _1991.x;\n                _6208.y = _1991.y;\n                _6208.z = _1991.z;\n                tx = _6208;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1912 * tex_a) * _1945.w, 0.0f, 1.0f).xxx);\n        if (_1955.z > _1955.x)\n        {\n            float4 param_17 = _1955;\n            float2 param_18 = _1920;\n            float2 param_19 = _1754;\n            float2 param_20 = _1930;\n            float2 param_21 = _1940;\n            float4 _2035 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1764 > 1.5f)\n            {\n                float3 param_22 = _2035.xyz;\n                float3 _2045 = fa_dc_to_srgb(param_22);\n                _2039 = _2045;\n            }\n            else\n            {\n                _2039 = _2035.xyz;\n            }\n            float3 _2054 = (_2039 * 2.0f) - 1.0f.xxx;\n            float2 _2059 = _2054.xy * _1809.y;\n            float3 _2081 = (normalize(_1837) * _2059.x) + (normalize(_1844) * _2059.y);\n            float3 _2084 = normalize(normal);\n            normal = normalize(lerp(_2084, normalize((_2084 * max(_2054.z, 0.0500000007450580596923828125f)) + (_2081 - (_2084 * dot(_2084, _2081)))), clamp(_1912 * (_1965 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (_420_fa_gi.w != 0.0f)\n    {\n        float _442 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n        bool _445;\n        if (_420_fa_gi.w > 0.0f)\n        {\n            _445 = _442 >= _420_fa_gi.w;\n        }\n        else\n        {\n            _445 = _442 < (-_420_fa_gi.w);\n        }\n        if (_445)\n        {\n            discard;\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _6352;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_420_fa_cl_info.x) + int(_420_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_420_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4728;\n    if (fa_lm.z > 0.5f)\n    {\n        _4728 = 0.0f;\n    }\n    else\n    {\n        _4728 = 1.0f - clamp(_420_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4739 = _4728 < 1.0f;\n    bool _4745;\n    if (_4739)\n    {\n        int param = li;\n        _4745 = fa_light_baked(param);\n    }\n    else\n    {\n        _4745 = _4739;\n    }\n    return _4745 ? _4728 : 1.0f;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _686 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _699 = (c - (ru * hx)) - p;\n        float3 _705 = ru * (2.0f * hx);\n        float _711 = max(dot(_705, _705), 9.9999999392252902907785028219223e-09f);\n        float _715 = dot(_699, _705);\n        float t = clamp((-_715) / _711, 0.0f, 1.0f);\n        if (_686)\n        {\n            float _730 = dot(r, _705);\n            float _736 = _711 - (_730 * _730);\n            if (abs(_736) > (9.9999997473787516355514526367188e-06f * _711))\n            {\n                t = clamp(((dot(r, _699) * _730) - _715) / _736, 0.0f, 1.0f);\n            }\n        }\n        return (p + _699) + (_705 * t);\n    }\n    float3 q = p;\n    float _768 = dot(r, axis);\n    bool _776;\n    if (_686)\n    {\n        _776 = abs(_768) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _776 = _686;\n    }\n    if (_776)\n    {\n        float _786 = dot(c - p, axis) / _768;\n        if (_786 > 0.0f)\n        {\n            q = p + (r * _786);\n        }\n    }\n    float3 _799 = q - c;\n    float2 xy = float2(dot(_799, ru), dot(_799, uu));\n    if (shape > 0.5f)\n    {\n        float _814 = length(xy);\n        if (_814 > hx)\n        {\n            xy *= (hx / _814);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _567_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _567_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _606 = dot(d, right);\n    float _610 = dot(d, up);\n    float _621;\n    if (((_606 * _606) + (_610 * _610)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _621 = atan2(_610, _606) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _621 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_621 - floor(_621)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _462 = abs(d);\n    float _464 = _462.x;\n    float _466 = _462.y;\n    bool _467 = _464 >= _466;\n    bool _475;\n    if (_467)\n    {\n        _475 = _464 >= _462.z;\n    }\n    else\n    {\n        _475 = _467;\n    }\n    int _476;\n    if (_475)\n    {\n        _476 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _490;\n        if (_466 >= _462.z)\n        {\n            _490 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _490 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _476 = _490;\n    }\n    return _476;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _852 = fa_light_base(param);\n    bool _856 = _420_fa_ambient.w > 4.5f;\n    int param_1 = _852;\n    float4 _860 = fa_light_texel(param_1);\n    int param_2 = _852 + 1;\n    float4 _865 = fa_light_texel(param_2);\n    float _868 = _865.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _880 = _856 && (_868 > 2.5f);\n    fa_light_is_area = _880;\n    bool _882 = _868 < 0.5f;\n    float3 l;\n    if (_882)\n    {\n        l = normalize(_860.xyz);\n        if (_856)\n        {\n            int param_3 = _852 + 6;\n            float4 _896 = fa_light_texel(param_3);\n            if (_896.z > 0.5f)\n            {\n                int param_4 = _852 + 4;\n                float4 _906 = fa_light_texel(param_4);\n                int param_5 = _852 + 5;\n                float4 _911 = fa_light_texel(param_5);\n                float2 param_6 = _896.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _906.xyz) * _906.w, (-dot(world_pos, _911.xyz)) * _911.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _941 = _860.xyz;\n        float3 _943 = _941 - world_pos;\n        float3 to_light = _943;\n        float _946 = length(_943);\n        float reach = _946;\n        bool front = true;\n        if (_880)\n        {\n            int param_8 = _852 + 7;\n            reach = max(_946 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _852 + 4;\n            float4 _970 = fa_light_texel(param_9);\n            int param_10 = _852 + 5;\n            float4 _975 = fa_light_texel(param_10);\n            int param_11 = _852 + 6;\n            float4 _980 = fa_light_texel(param_11);\n            float _981 = _980.w;\n            int param_12 = _852 + 2;\n            float3 _988 = normalize(fa_light_texel(param_12).xyz);\n            bool _990 = _981 > 1.5f;\n            bool _998;\n            if (!_990)\n            {\n                _998 = dot(_988, to_light) < 0.0f;\n            }\n            else\n            {\n                _998 = _990;\n            }\n            front = _998;\n            float3 r = 0.0f.xxx;\n            float3 _1007 = _420_fa_camera_pos.xyz - world_pos;\n            bool _1011 = dot(n, n) > 0.5f;\n            bool _1019;\n            if (_1011)\n            {\n                _1019 = dot(_1007, _1007) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _1019 = _1011;\n            }\n            if (_1019)\n            {\n                r = reflect(-normalize(_1007), normalize(n));\n            }\n            float3 param_13 = _941;\n            float3 param_14 = _988;\n            float3 param_15 = _970.xyz;\n            float3 param_16 = _975.xyz;\n            float param_17 = _970.w;\n            float param_18 = _975.w;\n            float param_19 = _981;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1055 = length(to_light);\n        dist = _1055;\n        l = to_light / max(_1055, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1069 = reach / max(_860.w, 0.001000000047497451305389404296875f);\n        float _1075 = clamp(1.0f - (_1069 * _1069), 0.0f, 1.0f);\n        float _1077;\n        if (front)\n        {\n            _1077 = _1075 * _1075;\n        }\n        else\n        {\n            _1077 = 0.0f;\n        }\n        atten = _1077;\n        bool _1088 = _868 < 2.5f;\n        if ((_868 > 1.5f) && _1088)\n        {\n            int param_22 = _852 + 2;\n            float4 _1096 = fa_light_texel(param_22);\n            float _1106 = _1096.w;\n            int param_23 = _852 + 3;\n            float4 _1111 = fa_light_texel(param_23);\n            float _1112 = _1111.x;\n            float cos_inner = _1112;\n            if (_1112 > 1.5f)\n            {\n                cos_inner = lerp(_1106, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1106, cos_inner, dot(-l, normalize(_1096.xyz)));\n        }\n        if (_856 && (_868 < 1.5f))\n        {\n            int param_24 = _852 + 6;\n            float4 _1136 = fa_light_texel(param_24);\n            if (_1136.z > 0.5f)\n            {\n                float3 _1144 = -to_light;\n                int param_25 = _852 + 4;\n                int param_26 = _852 + 5;\n                float3 _1158 = fa_light_texel(param_25).xyz;\n                float3 _1162 = fa_light_texel(param_26).xyz;\n                float3 _1171 = float3(dot(_1144, _1158), dot(_1144, _1162), dot(_1144, cross(_1158, _1162)));\n                float3 param_27 = _1171;\n                int _1175 = fa_cube_face(param_27);\n                int param_28 = _1175;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1202 = float2(dot(_1171, cross(param_29, param_30)), dot(_1171, param_30)) / max(dot(_1171, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1206 = _1175 / 3;\n                float2 param_31 = _1136.xy + (float2(float(_1175 - (_1206 * 3)), float(_1206)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1202.x), 0.5f - (0.5f * _1202.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _852 + 7;\n            float4 _1236 = fa_light_texel(param_33);\n            if (_1236.z > 0.5f)\n            {\n                int param_34 = _852 + 2;\n                int param_35 = _852 + 4;\n                int param_36 = _852 + 5;\n                float2 param_37 = _1236.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_856 && _1088)\n            {\n                int param_42 = _852 + 6;\n                float4 _1283 = fa_light_texel(param_42);\n                int param_43 = _852 + 7;\n                float4 _1288 = fa_light_texel(param_43);\n                bool _1291 = _1283.z > 0.5f;\n                bool _1298;\n                if (!_1291)\n                {\n                    _1298 = _1288.z > 0.5f;\n                }\n                else\n                {\n                    _1298 = _1291;\n                }\n                if (_1298)\n                {\n                    int param_44 = _852 + 2;\n                    float4 _1305 = fa_light_texel(param_44);\n                    float3 _1309 = normalize(_1305.xyz);\n                    int param_45 = _852 + 4;\n                    float4 _1314 = fa_light_texel(param_45);\n                    int param_46 = _852 + 5;\n                    float4 _1319 = fa_light_texel(param_46);\n                    if (_1291)\n                    {\n                        float3 _1327 = -to_light;\n                        float _1334 = _1305.w;\n                        float _1350 = 0.5f / max(dot(_1327, _1309) * (sqrt(max(1.0f - (_1334 * _1334), 0.0f)) / max(_1334, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1283.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1327, _1314.xyz) * _1350), 0.5f - (dot(_1327, _1319.xyz) * _1350));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1288.z > 0.5f)\n                    {\n                        float2 param_49 = _1288.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1309;\n                        float3 param_52 = _1314.xyz;\n                        float3 param_53 = _1319.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _5926 = _865.xyz * atten;\n    if (_856)\n    {\n        _5926 *= fa_light_tint;\n    }\n    int _1419;\n    if (_882)\n    {\n        _1419 = 0;\n    }\n    else\n    {\n        _1419 = ((_868 > 1.5f) && (_868 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _5937 = { l, _5926, atten, 1.0f, dist, _1419 };\n    return _5937;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4957 = n < 0;\n    bool _4964;\n    if (!_4957)\n    {\n        _4964 = n >= fa_light_count();\n    }\n    else\n    {\n        _4964 = _4957;\n    }\n    if (_4964)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4972 = fa_cl_light(param);\n    int param_1 = _4972;\n    float _4976 = fa_baked_keep(param_1);\n    if (_4976 <= 0.0f)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4972;\n    float3 param_3 = i.world_pos;\n    float3 param_4 = i.world_normal;\n    LightSample _4992 = fa_light_sample_n(param_2, param_3, param_4);\n    LightSample _6108 = { _4992.direction, _4992.color * _4976, _4992.attenuation * _4976, _4992.shadow, _4992._distance, _4992.type };\n    return _6108;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2202 = fa_shadow_depth(param, param_1);\n    float _2206;\n    if (conv.x < 0.5f)\n    {\n        _2206 = _2202;\n    }\n    else\n    {\n        _2206 = (conv.y * conv.z) / (conv.z - (_2202 * (conv.z - conv.y)));\n    }\n    return _2206;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2252 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2258 = float2(cos(_2252), sin(_2252));\n    float2 dir = _2258;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2267;\n        if (k < 0.0f)\n        {\n            _2267 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2267 = k;\n        }\n        float _2286 = clamp((_2267 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2305 = sqrt((float(i) + 0.5f) * 0.0625f) * _2286;\n            float2 param_3 = uv + (dir * (_2155_fa_shadow_bias.zw * _2305));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2319 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2319 < (zr - (_2305 * plane)))\n            {\n                sum += _2319;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2347 = sum / cnt;\n        float _2357;\n        if (k < 0.0f)\n        {\n            _2357 = (-k) / max(_2347, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2357 = k;\n        }\n        radius = clamp(((max(zr - _2347, 0.0f) * unit) * _2357) / texel_m, 1.5f, 16.0f);\n        dir = _2258;\n    }\n    float lit = 0.0f;\n    int _2383 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2383; i_1++)\n    {\n        float _2402 = sqrt((float(i_1) + 0.5f) / float(_2383)) * radius;\n        float2 param_7 = uv + (dir * (_2155_fa_shadow_bias.zw * _2402));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2402 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2383);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2607 = _420_fa_pbr.z < 0.5f;\n    bool _2614;\n    if (!_2607)\n    {\n        _2614 = _2155_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2614 = _2607;\n    }\n    if (_2614)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2155_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2627 = fa_light_texel(param);\n    float _2628 = _2627.x;\n    if (_2628 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2637 = int(_2628 + 0.5f);\n    int param_1 = _2637;\n    float4 _2641 = fa_light_texel(param_1);\n    int param_2 = _2637 + 1;\n    float4 _2646 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2649 = _2641.y;\n    if (_2649 > 0.0f)\n    {\n        float _2666 = 1.0f - smoothstep(0.75f * _2649, _2649, length(world - _2155_fa_shadow_eye.xyz));\n        fade = _2666;\n        if (_2666 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2641.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2690 = (_2637 + 2) + (face * 6);\n    int param_4 = _2690;\n    int param_5 = _2690 + 1;\n    int param_6 = _2690 + 3;\n    float4 _2704 = fa_light_texel(param_6);\n    int param_7 = _2690 + 4;\n    float4 _2709 = fa_light_texel(param_7);\n    int param_8 = _2690 + 5;\n    float4 _2714 = fa_light_texel(param_8);\n    float _2726 = _2714.x * max(dot(_2704, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2731 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2754 = clamp(dot(n, _2704.xyz), -1.0f, 1.0f);\n    float _2773 = min(sqrt(1.0f - (_2754 * _2754)) / max(abs(dot(n, world - lpos)) / max(dot(_2704, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2776 = _2646.y;\n    float _2778;\n    if (_2776 > 0.0f)\n    {\n        _2778 = _2776;\n    }\n    else\n    {\n        _2778 = 1.5f * _2726;\n    }\n    float4 _2798 = float4(world + (n * (_2778 * sqrt(1.0f - (_2731 * _2731)))), 1.0f);\n    float _2802 = dot(_2704, _2798);\n    float _2805 = _2714.y;\n    if (_2802 < _2805)\n    {\n        return 1.0f;\n    }\n    float2 _2820 = float2(dot(fa_light_texel(param_4), _2798), dot(fa_light_texel(param_5), _2798)) / _2802.xx;\n    float _2822 = _2820.x;\n    bool _2825 = _2822 < _2709.x;\n    bool _2834;\n    if (!_2825)\n    {\n        _2834 = _2822 > _2709.z;\n    }\n    else\n    {\n        _2834 = _2825;\n    }\n    bool _2843;\n    if (!_2834)\n    {\n        _2843 = _2820.y < _2709.y;\n    }\n    else\n    {\n        _2843 = _2834;\n    }\n    bool _2852;\n    if (!_2843)\n    {\n        _2852 = _2820.y > _2709.w;\n    }\n    else\n    {\n        _2852 = _2843;\n    }\n    if (_2852)\n    {\n        return 1.0f;\n    }\n    float _2858 = _2646.x;\n    float _2860;\n    if (_2858 > 0.0f)\n    {\n        _2860 = _2858;\n    }\n    else\n    {\n        _2860 = 1.5f * _2726;\n    }\n    float2 param_9 = _2820;\n    float4 param_10 = _2709;\n    float param_11 = _2802 - (_2860 * (1.0f + (0.5f * _2773)));\n    float param_12 = _2726;\n    float param_13 = 1.0f;\n    float param_14 = _2714.z * 0.25f;\n    float param_15 = (_2726 * min(_2773, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2805, _2714.z);\n    int param_17 = int(_2641.z + 0.5f);\n    float param_18 = _2641.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2145;\n    if (i == 0)\n    {\n        _2145 = _2155_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2161;\n        if (i == 1)\n        {\n            _2161 = _2155_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2169;\n            if (i == 2)\n            {\n                _2169 = _2155_fa_shadow_split.z;\n            }\n            else\n            {\n                _2169 = _2155_fa_shadow_split.w;\n            }\n            _2161 = _2169;\n        }\n        _2145 = _2161;\n    }\n    return _2145;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2448 = max(_2155_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2453 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2459 = sqrt(1.0f - (_2453 * _2453));\n    float _2467 = min(_2459 / max(_2453, 0.20000000298023223876953125f), 4.0f);\n    float _2472;\n    if (_2155_fa_shadow_bias.y > 0.0f)\n    {\n        _2472 = _2155_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2472 = 1.5f * _2155_fa_shadow_info[ci].x;\n    }\n    float4 _2497 = mul(float4(world + (n * (_2472 * _2459)), 1.0f), _2155_fa_shadow_mat[ci]);\n    float _2504 = _2497.x;\n    bool _2507 = _2504 < _2155_fa_shadow_rect[ci].x;\n    bool _2516;\n    if (!_2507)\n    {\n        _2516 = _2504 > _2155_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2516 = _2507;\n    }\n    bool _2525;\n    if (!_2516)\n    {\n        _2525 = _2497.y < _2155_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2525 = _2516;\n    }\n    bool _2534;\n    if (!_2525)\n    {\n        _2534 = _2497.y > _2155_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2534 = _2525;\n    }\n    bool _2541;\n    if (!_2534)\n    {\n        _2541 = _2497.z > 1.0f;\n    }\n    else\n    {\n        _2541 = _2534;\n    }\n    if (_2541)\n    {\n        return -1.0f;\n    }\n    float _2549;\n    if (_2155_fa_shadow_bias.x > 0.0f)\n    {\n        _2549 = _2155_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2549 = 1.5f * _2155_fa_shadow_info[ci].x;\n    }\n    float2 param = _2497.xy;\n    float4 param_1 = _2155_fa_shadow_rect[ci];\n    float param_2 = _2497.z - ((_2549 * (1.0f + (0.5f * _2467))) / _2448);\n    float param_3 = _2155_fa_shadow_info[ci].x;\n    float param_4 = _2448;\n    float param_5 = _2448 * 0.25f;\n    float param_6 = ((_2155_fa_shadow_info[ci].x * min(_2467, 3.0f)) * 0.5f) / _2448;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2155_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2155_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_420_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2927 = int(_2155_fa_shadow_cfg.x + 0.5f);\n    if (_2927 < 1)\n    {\n        return 1.0f;\n    }\n    float _2942 = dot(world - _2155_fa_shadow_eye.xyz, _2155_fa_shadow_fwd.xyz);\n    int param = _2927 - 1;\n    if (_2942 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2954 = _2927 > 1;\n    bool _2961;\n    if (_2954)\n    {\n        _2961 = _2942 > _2155_fa_shadow_split.x;\n    }\n    else\n    {\n        _2961 = _2954;\n    }\n    if (_2961)\n    {\n        ci = 1;\n    }\n    bool _2965 = _2927 > 2;\n    bool _2972;\n    if (_2965)\n    {\n        _2972 = _2942 > _2155_fa_shadow_split.y;\n    }\n    else\n    {\n        _2972 = _2965;\n    }\n    if (_2972)\n    {\n        ci = 2;\n    }\n    bool _2976 = _2927 > 3;\n    bool _2983;\n    if (_2976)\n    {\n        _2983 = _2942 > _2155_fa_shadow_split.z;\n    }\n    else\n    {\n        _2983 = _2976;\n    }\n    if (_2983)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _2994 = min(_2927, 4);\n    float _3035;\n    for (int c = ci; c < _2994; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _3014 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _3014;\n            break;\n        }\n        if (_3014 < 0.0f)\n        {\n            continue;\n        }\n        s = _3014;\n        ci = c;\n        if (_2155_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3035 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3035 = _2155_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _3054 = _2155_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3035, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_2942 - (fa_shadow_split_at(param_7) - _3054)) / _3054, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3086;\n        if ((ci + 1) < _2927)\n        {\n            _3086 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3086 = 1.0f;\n        }\n        s = lerp(s, _3086, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4464 = _420_fa_ct_a.x < 0.5f;\n    bool _4471;\n    if (!_4464)\n    {\n        _4471 = _2155_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4471 = _4464;\n    }\n    if (_4471)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2155_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4484 = fa_light_texel(param);\n    float _4485 = _4484.y;\n    float len = _4485;\n    if (_4485 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4497 = length(world - _420_fa_camera_pos.xyz);\n    float _4507 = 1.0f - smoothstep(0.5f * _420_fa_ct_b.x, _420_fa_ct_b.x, _4497);\n    if (_4507 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4513 = len;\n    float _4516 = min(_4513, 0.89999997615814208984375f * dist);\n    len = _4516;\n    float _4521 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4497);\n    float _4526 = _4521 + (0.5f * _4516);\n    float3 _4532 = world + (gn * _4521);\n    float _4534 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4598;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4549 = (float(k) + _4534) * 0.083333335816860198974609375f;\n        float3 _4557 = _4532 + (l * (_4549 * len));\n        float4 _4563 = float4(_4557, 1.0f);\n        float _4569 = dot(_420_fa_ct_vpw, _4563);\n        if (_4569 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4589 = float2(dot(_420_fa_ct_vpx, _4563), dot(_420_fa_ct_vpy, _4563)) / _4569.xx;\n        float _4593 = _4589.x * 0.5f;\n        float _4594 = _4593 + 0.5f;\n        if (_420_fa_ct_a.y > 0.5f)\n        {\n            _4598 = (_4589.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4598 = 0.5f - (_4589.y * 0.5f);\n        }\n        bool _4614 = _4594 < 0.0f;\n        bool _4621;\n        if (!_4614)\n        {\n            _4621 = _4594 >= 1.0f;\n        }\n        else\n        {\n            _4621 = _4614;\n        }\n        bool _4628;\n        if (!_4621)\n        {\n            _4628 = _4598 < 0.0f;\n        }\n        else\n        {\n            _4628 = _4621;\n        }\n        bool _4635;\n        if (!_4628)\n        {\n            _4635 = _4598 >= 1.0f;\n        }\n        else\n        {\n            _4635 = _4628;\n        }\n        if (_4635)\n        {\n            break;\n        }\n        float4 _4662 = fa_screen_tex.Load(int3(clamp(int2(float2(_4594, _4598) * _420_fa_ct_a.zw), int2(0, 0), int2(_420_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_4662.w < 0.5f)\n        {\n            continue;\n        }\n        float _4681 = (dot(_420_fa_ct_fwd.xyz, _4557) + _420_fa_ct_fwd.w) - _4662.x;\n        if ((_4681 > _4521) && (_4681 < _4526))\n        {\n            occ = max(occ, (1.0f - (_4549 * _4549)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4594, 0.5f - _4593), min(_4598, 1.0f - _4598))));\n        }\n    }\n    return 1.0f - (occ * _4507);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4784 = fa_baked_keep(param);\n    if (_4784 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _6070 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6070;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4810 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6072 = _4810.color;\n    float _6073 = _4810.attenuation;\n    float _6074 = _4810.shadow;\n    bool _4813 = _4810.type == 0;\n    if (_4813 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4810.direction;\n        float _4824 = fa_shadow_factor(param_5, param_6);\n        _6074 = _4824;\n        _6072 *= _4824;\n    }\n    else\n    {\n        bool _4835 = _4810.type != 0;\n        bool _4841;\n        if (_4835)\n        {\n            _4841 = _6073 > 0.0f;\n        }\n        else\n        {\n            _4841 = _4835;\n        }\n        if (_4841)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4810.direction;\n            float _4860 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6074 = _4860;\n            _6072 *= _4860;\n        }\n    }\n    bool _4870 = _420_fa_ct_a.x > 0.5f;\n    bool _4876;\n    if (_4870)\n    {\n        _4876 = _6073 > 0.0f;\n    }\n    else\n    {\n        _4876 = _4870;\n    }\n    if (_4876)\n    {\n        float _4883;\n        if (_4813)\n        {\n            _4883 = 1000000000.0f;\n        }\n        else\n        {\n            _4883 = _4810._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4810.direction;\n        float param_18 = _4883;\n        float _4901 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6074 *= _4901;\n        _6072 *= _4901;\n    }\n    float _4914 = _6073;\n    float _4915 = _4914 * _4784;\n    _6073 = _4915;\n    float3 _4919 = _6072;\n    float3 _4920 = _4919 * _4784;\n    _6072 = _4920;\n    LightSample _6089 = { _4810.direction, _4920, _4915, _6074, _4810._distance, _4810.type };\n    return _6089;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4931 = n < 0;\n    bool _4938;\n    if (!_4931)\n    {\n        _4938 = n >= fa_light_count();\n    }\n    else\n    {\n        _4938 = _4931;\n    }\n    if (_4938)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    LightSample _4953 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4953;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3849 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3857 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3860 = int(_3849);\n    int _3863 = int(_3857);\n    float _3873 = _3857 - float(_3863);\n    int _3929 = (_3860 * 9) + _3863;\n    int _3949 = ((_3860 + 1) * 9) + _3863;\n    return lerp(lerp(_3924[_3929], _3924[_3929 + 1], _3873), lerp(_3924[_3949], _3924[_3949 + 1], _3873), _3849 - float(_3860));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _5938 = false;\n    float _5939 = 1.0f;\n    float _5940 = 1.0f;\n    float _5941 = 1.0f;\n    float _5942 = 0.0f;\n    float _5943 = 0.0f;\n    float _5944 = 0.0f;\n    float _5945 = 0.0f;\n    float _5947 = 1.0f;\n    bool _5948 = false;\n    float3 _5949 = 0.0f.xxx;\n    float _5950 = 1.0f;\n    float _5951 = 1.0f;\n    float _5952 = 1.0f;\n    float _5953 = 0.0f;\n    float _5954 = 0.0f;\n    float3 _5955 = float3(1.0f, 0.0f, 0.0f);\n    float3 _5956 = float3(0.0f, 0.0f, 1.0f);\n    float _5957 = 1.0f;\n    float _5958 = 1.0f;\n    float _4000 = clamp(s.specular, 0.0f, 1.0f);\n    float _4004 = clamp(s.ior, 1.0f, 3.0f);\n    bool _4009 = (_4000 != 1.0f) || (_4004 != 1.5f);\n    bool _4018;\n    if (!_4009)\n    {\n        _4018 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _4018 = _4009;\n    }\n    if (_4018)\n    {\n        float _4026 = (_4004 - 1.0f) / (_4004 + 1.0f);\n        f0 = lerp(min((_4026 * _4026).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _4000, s.albedo, metallic.xxx);\n        _5939 = lerp(_4000, 1.0f, metallic);\n        _5938 = true;\n    }\n    float _4053 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4053 > 0.0f)\n    {\n        float _4061 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _5942 = _4053;\n        _5943 = _4061;\n        float _4068 = _4061 * _4061;\n        _5944 = _4068;\n        _5945 = _4068 * _4068;\n        float _4080 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _5947 = _4080;\n        _5940 = 1.0f - (_4053 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _4080, 0.0f, 1.0f), 5.0f))));\n        _5938 = true;\n    }\n    float3 _4099 = max(s.sheen_color, 0.0f.xxx);\n    float _4108 = max(_4099.x, max(_4099.y, _4099.z));\n    if (_4108 > 0.0f)\n    {\n        float _4116 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _5948 = true;\n        _5949 = _4099;\n        _5950 = _4116;\n        _5951 = _4116 * _4116;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _4116;\n        float _4133 = fa_sheen_albedo(param, param_1);\n        _5953 = _4133;\n        _5952 = 1.0f - min(_4108 * _4133, 1.0f);\n        _5938 = true;\n    }\n    _5941 = _5940 * _5952;\n    float _4152 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_4152 != 0.0f)\n    {\n        float3 _4167 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _4167;\n        if (dot(_4167, _4167) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _4179 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_4179.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _4179.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _4179.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _4183 = t;\n        float3 _4184 = normalize(_4183);\n        t = _4184;\n        float3 _4209 = normalize((_4184 * cos(s.anisotropy_rotation)) + ((cross(n, _4184) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _5955 = _4209;\n        _5956 = cross(n, _4209);\n        float _4219 = roughness * roughness;\n        float _4225 = lerp(_4219, 1.0f, _4152 * _4152);\n        bool _4227 = _4152 > 0.0f;\n        _5957 = _4227 ? _4225 : _4219;\n        _5958 = _4227 ? _4219 : _4225;\n        _5954 = _4152;\n        _5938 = true;\n    }\n    FaLayers _5980 = { _5938, _5939, _5940, _5941, _5942, _5943, _5944, _5945, i.world_normal, _5947, _5948, _5949, _5950, _5951, _5952, _5953, _5954, _5955, _5956, _5957, _5958 };\n    return _5980;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3781 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3784 = _3781.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3784 * _3784, exp2((-9.27999973297119140625f) * ndv)) * _3784) + _3781.y)) + _3781.zw;\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3216 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3219 = _3216.x;\n    float _3221 = _3216.z;\n    float2 e = float2(_3219, _3221);\n    if (_3216.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3221)) * ((_3219 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3219)) * ((_3221 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3255_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3255_dummy_parameter)));\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _3268;\n    if (lv == 0)\n    {\n        _3268 = 0.0f;\n    }\n    else\n    {\n        _3268 = res + 2.0f;\n    }\n    float _3278;\n    if (lv == 0)\n    {\n        _3278 = 0.0f;\n    }\n    else\n    {\n        _3278 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_3268, _3278)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _3324;\n    if (res > 64.5f)\n    {\n        _3324 = 5.0f;\n    }\n    else\n    {\n        _3324 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _3339 = clamp(rough, 0.0f, 1.0f) * (_3324 - 1.0f);\n    int _3346 = int(min(floor(_3339), _3324 - 2.0f));\n    float _3351 = _3339 - float(_3346);\n    float3 param = d;\n    float2 _3355 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3346;\n    float2 param_4 = _3355;\n    float3 _3365 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3351 < 0.00200000009499490261077880859375f)\n    {\n        return _3365;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3346 + 1;\n    float2 param_8 = _3355;\n    return lerp(_3365, fa_probe_level(param_5, param_6, param_7, param_8), _3351.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _3403 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3410 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3417 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3423 = dot(bx.xyz, d);\n    float _3427 = dot(by.xyz, d);\n    float _3431 = dot(bz.xyz, d);\n    float _3437;\n    if (_3423 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3437 = (1.0f - _3403) / _3423;\n    }\n    else\n    {\n        float _3451;\n        if (_3423 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3451 = ((-1.0f) - _3403) / _3423;\n        }\n        else\n        {\n            _3451 = 1000000015047466219876688855040.0f;\n        }\n        _3437 = _3451;\n    }\n    float tx = _3437;\n    float _3468;\n    if (_3427 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3468 = (1.0f - _3410) / _3427;\n    }\n    else\n    {\n        float _3481;\n        if (_3427 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3481 = ((-1.0f) - _3410) / _3427;\n        }\n        else\n        {\n            _3481 = 1000000015047466219876688855040.0f;\n        }\n        _3468 = _3481;\n    }\n    float ty = _3468;\n    float _3497;\n    if (_3431 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3497 = (1.0f - _3417) / _3431;\n    }\n    else\n    {\n        float _3510;\n        if (_3431 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3510 = ((-1.0f) - _3417) / _3431;\n        }\n        else\n        {\n            _3510 = 1000000015047466219876688855040.0f;\n        }\n        _3497 = _3510;\n    }\n    float _3522 = tx;\n    float _3525 = (_3522 > 0.0f) ? _3522 : 1000000015047466219876688855040.0f;\n    tx = _3525;\n    float _3526 = ty;\n    float _3529 = (_3526 > 0.0f) ? _3526 : 1000000015047466219876688855040.0f;\n    ty = _3529;\n    float _3539 = min(_3525, min(_3529, (_3497 > 0.0f) ? _3497 : 1000000015047466219876688855040.0f));\n    if (_3539 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _3555 = (fa_world_pos + (d * _3539)) - posw.xyz;\n    float3 _3560;\n    if (dot(_3555, _3555) > 1.0000000133514319600180897396058e-10f)\n    {\n        _3560 = normalize(_3555);\n    }\n    else\n    {\n        _3560 = d;\n    }\n    return _3560;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _3606 = (1.0f - _420_fa_rpa_tile.w) - _420_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_3606 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_420_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _420_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3636 = rough * rough;\n            float _3667 = 0.60000002384185791015625f * _3636;\n            base = lerp(lerp(_420_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_420_fa_env_horizon.xyz, _420_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3636)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3667, 0.0500000007450580596923828125f + _3667, d.y).xxx), ((_420_fa_env_sky.xyz + _420_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3636 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _3606;\n    }\n    if (_420_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _420_fa_rpa_tile;\n        float4 param_5 = _420_fa_rpa_pos;\n        float4 param_6 = _420_fa_rpa_bx;\n        float4 param_7 = _420_fa_rpa_by;\n        float4 param_8 = _420_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _3726 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3726 * _420_fa_rpa_tile.w);\n    }\n    if (_420_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _420_fa_rpb_tile;\n        float4 param_12 = _420_fa_rpb_pos;\n        float4 param_13 = _420_fa_rpb_bx;\n        float4 param_14 = _420_fa_rpb_by;\n        float4 param_15 = _420_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _3758 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3758 * _420_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness, float occlusion)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4260;\n        if (L.aniso >= 0.0f)\n        {\n            _4260 = L.b;\n        }\n        else\n        {\n            _4260 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4260, v), _4260), (abs(L.aniso) * smoothstep(0.0f, 0.25f, roughness)).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4296 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4296.x) + (L.f90.xxx * _4296.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4354 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4354.x) + _4354.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3823 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3823.x) + _3823.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4393 = clamp(s.metallic, 0.0f, 1.0f);\n    float _4397 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _4404 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _4393.xxx);\n    float3 f0 = _4404;\n    float3 _4408 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _4408;\n    float3 param_3 = i.view_dir;\n    float param_4 = _4393;\n    float param_5 = _4397;\n    float3 param_6 = _4404;\n    FaLayers _4425 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4425.on)\n    {\n        FaLayers param_7 = _4425;\n        float3 param_8 = _4408;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _4397;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    float3 param_13 = _4408;\n    float3 param_14 = i.view_dir;\n    float3 param_15 = f0;\n    float param_16 = _4397;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _5023 = fa_light_unshadowed(param, param_1);\n        float _5031 = dot(_5023.color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_5031 > bestPower)\n        {\n            bestPower = _5031;\n            best = n;\n        }\n    }\n    float3 lit = (_420_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _5060 = fa_light(param_2, param_3);\n        float _5068;\n        if (dot(s.normal, _5060.direction) > 0.5f)\n        {\n            _5068 = 1.0f;\n        }\n        else\n        {\n            _5068 = _5074_dark;\n        }\n        lit += ((s.albedo * _5060.color) * _5068);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _5074_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2155_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3114 = int(_2155_fa_shadow_cfg.x + 0.5f);\n    float _3124 = dot(world - _2155_fa_shadow_eye.xyz, _2155_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3129 = _3114 > 0;\n    bool _3138;\n    if (_3129)\n    {\n        int param = _3114 - 1;\n        _3138 = _3124 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3138 = _3129;\n    }\n    if (_3138)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3144 = _3114 > 1;\n        bool _3151;\n        if (_3144)\n        {\n            _3151 = _3124 > _2155_fa_shadow_split.x;\n        }\n        else\n        {\n            _3151 = _3144;\n        }\n        if (_3151)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3157 = _3114 > 2;\n        bool _3164;\n        if (_3157)\n        {\n            _3164 = _3124 > _2155_fa_shadow_split.y;\n        }\n        else\n        {\n            _3164 = _3157;\n        }\n        if (_3164)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3170 = _3114 > 3;\n        bool _3177;\n        if (_3170)\n        {\n            _3177 = _3124 > _2155_fa_shadow_split.z;\n        }\n        else\n        {\n            _3177 = _3170;\n        }\n        if (_3177)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5792 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5792 = -_5792;\n    }\n    float3 _5461 = normalize(_420_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5805 = { fa_world_pos, _5792, fa_world_tangent, fa_uv, fa_vertex_color, _5461, gl_FrontFacing };\n    SurfaceInput param_1 = _5805;\n    Surface _5469 = fa_standard_surface(param_1);\n    float3 _5823 = _5469.albedo;\n    float _5824 = _5469.alpha;\n    float3 _5825 = _5469.normal;\n    float _5826 = _5469.metallic;\n    float _5827 = _5469.roughness;\n    float _5828 = _5469.occlusion;\n    float3 _5829 = _5469.emission;\n    float _5830 = _5469.clearcoat;\n    float _5831 = _5469.clearcoat_roughness;\n    float3 _5832 = _5469.sheen_color;\n    float _5833 = _5469.sheen_roughness;\n    float _5834 = _5469.anisotropy;\n    float _5835 = _5469.anisotropy_rotation;\n    float _5836 = _5469.specular;\n    float _5837 = _5469.ior;\n    float3 _5838 = _5469.specular_color;\n    float _5839 = _5469.transmission;\n    float _5840 = _5469.thickness;\n    float3 _5841 = _5469.attenuation_color;\n    float _5842 = _5469.attenuation_distance;\n    SurfaceInput _5813 = { fa_world_pos, _5792, fa_world_tangent, fa_uv, fa_vertex_color, _5461, gl_FrontFacing };\n    SurfaceInput param_2 = _5813;\n    Surface param_3 = _5469;\n    surface(param_2, param_3);\n    _5823 = param_3.albedo;\n    _5824 = param_3.alpha;\n    _5825 = param_3.normal;\n    _5826 = param_3.metallic;\n    _5827 = param_3.roughness;\n    _5828 = param_3.occlusion;\n    _5829 = param_3.emission;\n    _5830 = param_3.clearcoat;\n    _5831 = param_3.clearcoat_roughness;\n    _5832 = param_3.sheen_color;\n    _5833 = param_3.sheen_roughness;\n    _5834 = param_3.anisotropy;\n    _5835 = param_3.anisotropy_rotation;\n    _5836 = param_3.specular;\n    _5837 = param_3.ior;\n    _5838 = param_3.specular_color;\n    _5839 = param_3.transmission;\n    _5840 = param_3.thickness;\n    _5841 = param_3.attenuation_color;\n    _5842 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5792;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5823 = param_6;\n    _5825 = param_7;\n    fa_lod_dither();\n    float3 result;\n    if (_420_fa_emissive.w > 0.5f)\n    {\n        result = _5823;\n    }\n    else\n    {\n        float3 _5509 = _5825;\n        float3 _5510 = normalize(_5509);\n        _5825 = _5510;\n        SurfaceInput _5821 = { fa_world_pos, _5792, fa_world_tangent, fa_uv, fa_vertex_color, _5461, gl_FrontFacing };\n        SurfaceInput param_8 = _5821;\n        Surface _5924 = { _5823, _5824, _5510, _5826, _5827, _5828, _5829, _5830, _5831, _5832, _5833, _5834, _5835, _5836, _5837, _5838, _5839, _5840, _5841, _5842 };\n        Surface param_9 = _5924;\n        float3 _5521 = lighting(param_8, param_9);\n        result = _5521;\n    }\n    float3 _5525 = result;\n    float3 _5526 = _5525 + _5829;\n    result = _5526;\n    float3 param_10 = _5526;\n    float3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _5535 = _420_fa_fog.w > 0.0f;\n    bool _5542;\n    if (!_5535)\n    {\n        _5542 = _420_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5542 = _5535;\n    }\n    if (_5542)\n    {\n        float3 _5551 = fa_world_pos - _420_fa_camera_pos.xyz;\n        float _5557 = dot(_5551, _420_fa_fog_c.xyz);\n        bool _5561 = _420_fa_fog_c.w > 0.5f;\n        float _5562;\n        if (_5561)\n        {\n            _5562 = _5557;\n        }\n        else\n        {\n            _5562 = length(_5551);\n        }\n        float _5574 = _5562 - _420_fa_fog_b.x;\n        if (_5574 > 0.0f)\n        {\n            float _5583 = _420_fa_fog.w * _5574;\n            float tau = _5583 * _5583;\n            if (_420_fa_fog_b.y > 0.0f)\n            {\n                float _5599;\n                if (_5561)\n                {\n                    _5599 = fa_world_pos.y - (_420_fa_fog_c.y * _5557);\n                }\n                else\n                {\n                    _5599 = _420_fa_camera_pos.y;\n                }\n                float _5620 = lerp(_5599, fa_world_pos.y, clamp(_420_fa_fog_b.x / _5562, 0.0f, 1.0f));\n                float _5624 = fa_world_pos.y - _5620;\n                float _5629 = _5620 - _420_fa_fog_b.z;\n                float _5634 = fa_world_pos.y - _420_fa_fog_b.z;\n                bool _5637 = _5629 <= 0.0f;\n                bool _5638 = !_5637;\n                bool _5644;\n                if (_5638)\n                {\n                    _5644 = _420_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5644 = _5637;\n                }\n                float _5645;\n                if (_5644)\n                {\n                    _5645 = _420_fa_fog_b.y;\n                }\n                else\n                {\n                    _5645 = _420_fa_fog_b.y * exp(-min(_420_fa_fog_b.w * _5629, 80.0f));\n                }\n                bool _5672;\n                if (_5638)\n                {\n                    _5672 = _420_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5672 = _5637;\n                }\n                float _5673;\n                if (_5672)\n                {\n                    _5673 = _420_fa_fog_b.y * _5629;\n                }\n                else\n                {\n                    _5673 = (_420_fa_fog_b.y * (1.0f - exp(-min(_420_fa_fog_b.w * _5629, 80.0f)))) / _420_fa_fog_b.w;\n                }\n                bool _5698 = _5634 <= 0.0f;\n                bool _5705;\n                if (!_5698)\n                {\n                    _5705 = _420_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5705 = _5698;\n                }\n                float _5706;\n                if (_5705)\n                {\n                    _5706 = _420_fa_fog_b.y * _5634;\n                }\n                else\n                {\n                    _5706 = (_420_fa_fog_b.y * (1.0f - exp(-min(_420_fa_fog_b.w * _5634, 80.0f)))) / _420_fa_fog_b.w;\n                }\n                float _5733;\n                if (abs(_5624) < 0.001000000047497451305389404296875f)\n                {\n                    _5733 = _5645;\n                }\n                else\n                {\n                    _5733 = (_5706 - _5673) / _5624;\n                }\n                tau += (_5574 * max(_5733, 0.0f));\n            }\n            result = lerp(result, _420_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5824);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_2155",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_5074",
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
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 9
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
              "hlsl_register_t_n": 10
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          }
        ]
      }
    },
    "prepass": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _295 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _295;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0f);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _129_fa_camera_pos : packoffset(c0);\n    float4 _129_fa_ambient : packoffset(c1);\n    float4 _129_fa_base_color : packoffset(c2);\n    float4 _129_fa_emissive : packoffset(c3);\n    float4 _129_fa_model_emissive : packoffset(c4);\n    float4 _129_fa_pbr : packoffset(c5);\n    float4 _129_fa_maps : packoffset(c6);\n    float4 _129_fa_fog : packoffset(c7);\n    float4 _129_fa_fog_b : packoffset(c8);\n    float4 _129_fa_fog_c : packoffset(c9);\n    float4 _129_fa_counts : packoffset(c10);\n    float4 _129_fa_env_sky : packoffset(c11);\n    float4 _129_fa_env_horizon : packoffset(c12);\n    float4 _129_fa_time : packoffset(c13);\n    float4 _129_fa_cl_vpx : packoffset(c14);\n    float4 _129_fa_cl_vpy : packoffset(c15);\n    float4 _129_fa_cl_vpw : packoffset(c16);\n    float4 _129_fa_cl_fwd : packoffset(c17);\n    float4 _129_fa_cl_grid : packoffset(c18);\n    float4 _129_fa_cl_info : packoffset(c19);\n    float4 _129_fa_layers_a : packoffset(c20);\n    float4 _129_fa_layers_b : packoffset(c21);\n    float4 _129_fa_layers_c : packoffset(c22);\n    float4 _129_fa_layers_d : packoffset(c23);\n    float4 _129_fa_ct_a : packoffset(c24);\n    float4 _129_fa_ct_b : packoffset(c25);\n    float4 _129_fa_ct_vpx : packoffset(c26);\n    float4 _129_fa_ct_vpy : packoffset(c27);\n    float4 _129_fa_ct_vpw : packoffset(c28);\n    float4 _129_fa_ct_fwd : packoffset(c29);\n    float4 _129_fa_tr_a : packoffset(c30);\n    float4 _129_fa_tr_b : packoffset(c31);\n    float4 _129_fa_probe_sh[9] : packoffset(c32);\n    float4 _129_fa_atlas : packoffset(c41);\n    float4 _129_fa_rpa_tile : packoffset(c42);\n    float4 _129_fa_rpa_pos : packoffset(c43);\n    float4 _129_fa_rpa_bx : packoffset(c44);\n    float4 _129_fa_rpa_by : packoffset(c45);\n    float4 _129_fa_rpa_bz : packoffset(c46);\n    float4 _129_fa_rpb_tile : packoffset(c47);\n    float4 _129_fa_rpb_pos : packoffset(c48);\n    float4 _129_fa_rpb_bx : packoffset(c49);\n    float4 _129_fa_rpb_by : packoffset(c50);\n    float4 _129_fa_rpb_bz : packoffset(c51);\n    float4 _129_fa_gi : packoffset(c52);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _218 = fa_linear_to_srgb(param);\n        c = _218;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _227 = fa_srgb_to_linear(param_1);\n            c = _227;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _58;\n    if (i.front_facing)\n    {\n        _58 = i.world_normal;\n    }\n    else\n    {\n        _58 = -i.world_normal;\n    }\n    float3 _83 = normalize(i.world_tangent.xyz - (_58 * dot(_58, i.world_tangent.xyz)));\n    float3 _111 = normalize(((_83 * m.x) + ((cross(_58, _83) * i.world_tangent.w) * m.y)) + (_58 * m.z));\n    float3 _114;\n    if (i.front_facing)\n    {\n        _114 = _111;\n    }\n    else\n    {\n        _114 = -_111;\n    }\n    return _114;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _129_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _267 = fa_tex_fix(param_2, param_3);\n    float4 _871 = base_t;\n    _871.x = _267.x;\n    _871.y = _267.y;\n    _871.z = _267.z;\n    base_t = _871;\n    float4 _283 = (_871 * _129_fa_base_color) * i.vertex_color;\n    float3 _826 = i.world_normal;\n    if (_129_fa_maps.z > 0.5f)\n    {\n        float param_4 = _129_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _317 = fa_tex_fix(param_6, param_7);\n        float3 _321 = (_317 * 2.0f) - 1.0f.xxx;\n        float2 _326 = _321.xy * _129_fa_maps.x;\n        float3 _879 = _321;\n        _879.x = _326.x;\n        _879.y = _326.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _879;\n        _826 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _129_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _355 = fa_tex_fix(param_12, param_13);\n    float4 _882 = mrt;\n    _882.x = _355.x;\n    _882.y = _355.y;\n    _882.z = _355.z;\n    mrt = _882;\n    float4 _385 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _129_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _385.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _397 = fa_tex_fix(param_16, param_17);\n    float param_18 = _129_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _427 = fa_tex_fix(param_20, param_21);\n    float _831 = _129_fa_layers_a.x;\n    float _832 = _129_fa_layers_a.y;\n    float _835 = _129_fa_layers_a.z;\n    float _834 = _129_fa_layers_b.w;\n    float _837 = _129_fa_layers_c.x;\n    if (_129_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_129_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _831 *= _397.y;\n            _832 *= _397.z;\n            _834 *= _385.w;\n        }\n        if (_129_fa_layers_c.z > 1.5f)\n        {\n            _835 *= mrt.x;\n            _837 *= mrt.w;\n        }\n    }\n    Surface _864 = { _283.xyz, _283.w, _826, clamp(_129_fa_pbr.x * _355.z, 0.0f, 1.0f), clamp(_129_fa_pbr.y * _355.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_129_fa_maps.y * (_397.x - 1.0f)), _129_fa_emissive.xyz + (_129_fa_model_emissive.xyz * _427), _831, _832, _129_fa_layers_b.xyz, _834, _835, _129_fa_layers_a.w, _837, _129_fa_layers_c.y, _129_fa_layers_d.xyz, _129_fa_tr_a.x, _129_fa_tr_a.y, _129_fa_tr_b.xyz, _129_fa_tr_a.z };\n    return _864;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid fa_lod_dither()\n{\n    if (_129_fa_gi.w != 0.0f)\n    {\n        float _151 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n        bool _154;\n        if (_129_fa_gi.w > 0.0f)\n        {\n            _154 = _151 >= _129_fa_gi.w;\n        }\n        else\n        {\n            _154 = _151 < (-_129_fa_gi.w);\n        }\n        if (_154)\n        {\n            discard;\n        }\n    }\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _721 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _721 = -_721;\n    }\n    float3 _579 = normalize(_129_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _734 = { fa_world_pos, _721, fa_world_tangent, fa_uv, fa_vertex_color, _579, gl_FrontFacing };\n    SurfaceInput param = _734;\n    Surface _584 = fa_standard_surface(param);\n    float3 _745 = _584.normal;\n    SurfaceInput _742 = { fa_world_pos, _721, fa_world_tangent, fa_uv, fa_vertex_color, _579, gl_FrontFacing };\n    SurfaceInput param_1 = _742;\n    Surface param_2 = _584;\n    surface(param_1, param_2);\n    _745 = param_2.normal;\n    fa_lod_dither();\n    float3 _595 = normalize(_745);\n    float3 _610 = normalize(float3(dot(fa_pre_r0, _595), dot(fa_pre_r1, _595), dot(fa_pre_r2, _595)));\n    float _622 = _610.z;\n    float2 e = _610.xy / ((abs(_610.x) + abs(_610.y)) + abs(_622)).xx;\n    if (_622 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_129",
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _416 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _416;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _423 = _273.world_pos;\n    float4 _284 = float4(_423, 1.0f);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _129_fa_camera_pos : packoffset(c0);\n    float4 _129_fa_ambient : packoffset(c1);\n    float4 _129_fa_base_color : packoffset(c2);\n    float4 _129_fa_emissive : packoffset(c3);\n    float4 _129_fa_model_emissive : packoffset(c4);\n    float4 _129_fa_pbr : packoffset(c5);\n    float4 _129_fa_maps : packoffset(c6);\n    float4 _129_fa_fog : packoffset(c7);\n    float4 _129_fa_fog_b : packoffset(c8);\n    float4 _129_fa_fog_c : packoffset(c9);\n    float4 _129_fa_counts : packoffset(c10);\n    float4 _129_fa_env_sky : packoffset(c11);\n    float4 _129_fa_env_horizon : packoffset(c12);\n    float4 _129_fa_time : packoffset(c13);\n    float4 _129_fa_cl_vpx : packoffset(c14);\n    float4 _129_fa_cl_vpy : packoffset(c15);\n    float4 _129_fa_cl_vpw : packoffset(c16);\n    float4 _129_fa_cl_fwd : packoffset(c17);\n    float4 _129_fa_cl_grid : packoffset(c18);\n    float4 _129_fa_cl_info : packoffset(c19);\n    float4 _129_fa_layers_a : packoffset(c20);\n    float4 _129_fa_layers_b : packoffset(c21);\n    float4 _129_fa_layers_c : packoffset(c22);\n    float4 _129_fa_layers_d : packoffset(c23);\n    float4 _129_fa_ct_a : packoffset(c24);\n    float4 _129_fa_ct_b : packoffset(c25);\n    float4 _129_fa_ct_vpx : packoffset(c26);\n    float4 _129_fa_ct_vpy : packoffset(c27);\n    float4 _129_fa_ct_vpw : packoffset(c28);\n    float4 _129_fa_ct_fwd : packoffset(c29);\n    float4 _129_fa_tr_a : packoffset(c30);\n    float4 _129_fa_tr_b : packoffset(c31);\n    float4 _129_fa_probe_sh[9] : packoffset(c32);\n    float4 _129_fa_atlas : packoffset(c41);\n    float4 _129_fa_rpa_tile : packoffset(c42);\n    float4 _129_fa_rpa_pos : packoffset(c43);\n    float4 _129_fa_rpa_bx : packoffset(c44);\n    float4 _129_fa_rpa_by : packoffset(c45);\n    float4 _129_fa_rpa_bz : packoffset(c46);\n    float4 _129_fa_rpb_tile : packoffset(c47);\n    float4 _129_fa_rpb_pos : packoffset(c48);\n    float4 _129_fa_rpb_bx : packoffset(c49);\n    float4 _129_fa_rpb_by : packoffset(c50);\n    float4 _129_fa_rpb_bz : packoffset(c51);\n    float4 _129_fa_gi : packoffset(c52);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _218 = fa_linear_to_srgb(param);\n        c = _218;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _227 = fa_srgb_to_linear(param_1);\n            c = _227;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _58;\n    if (i.front_facing)\n    {\n        _58 = i.world_normal;\n    }\n    else\n    {\n        _58 = -i.world_normal;\n    }\n    float3 _83 = normalize(i.world_tangent.xyz - (_58 * dot(_58, i.world_tangent.xyz)));\n    float3 _111 = normalize(((_83 * m.x) + ((cross(_58, _83) * i.world_tangent.w) * m.y)) + (_58 * m.z));\n    float3 _114;\n    if (i.front_facing)\n    {\n        _114 = _111;\n    }\n    else\n    {\n        _114 = -_111;\n    }\n    return _114;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _129_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _267 = fa_tex_fix(param_2, param_3);\n    float4 _871 = base_t;\n    _871.x = _267.x;\n    _871.y = _267.y;\n    _871.z = _267.z;\n    base_t = _871;\n    float4 _283 = (_871 * _129_fa_base_color) * i.vertex_color;\n    float3 _826 = i.world_normal;\n    if (_129_fa_maps.z > 0.5f)\n    {\n        float param_4 = _129_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _317 = fa_tex_fix(param_6, param_7);\n        float3 _321 = (_317 * 2.0f) - 1.0f.xxx;\n        float2 _326 = _321.xy * _129_fa_maps.x;\n        float3 _879 = _321;\n        _879.x = _326.x;\n        _879.y = _326.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _879;\n        _826 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _129_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _355 = fa_tex_fix(param_12, param_13);\n    float4 _882 = mrt;\n    _882.x = _355.x;\n    _882.y = _355.y;\n    _882.z = _355.z;\n    mrt = _882;\n    float4 _385 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _129_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _385.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _397 = fa_tex_fix(param_16, param_17);\n    float param_18 = _129_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _427 = fa_tex_fix(param_20, param_21);\n    float _831 = _129_fa_layers_a.x;\n    float _832 = _129_fa_layers_a.y;\n    float _835 = _129_fa_layers_a.z;\n    float _834 = _129_fa_layers_b.w;\n    float _837 = _129_fa_layers_c.x;\n    if (_129_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_129_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _831 *= _397.y;\n            _832 *= _397.z;\n            _834 *= _385.w;\n        }\n        if (_129_fa_layers_c.z > 1.5f)\n        {\n            _835 *= mrt.x;\n            _837 *= mrt.w;\n        }\n    }\n    Surface _864 = { _283.xyz, _283.w, _826, clamp(_129_fa_pbr.x * _355.z, 0.0f, 1.0f), clamp(_129_fa_pbr.y * _355.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_129_fa_maps.y * (_397.x - 1.0f)), _129_fa_emissive.xyz + (_129_fa_model_emissive.xyz * _427), _831, _832, _129_fa_layers_b.xyz, _834, _835, _129_fa_layers_a.w, _837, _129_fa_layers_c.y, _129_fa_layers_d.xyz, _129_fa_tr_a.x, _129_fa_tr_a.y, _129_fa_tr_b.xyz, _129_fa_tr_a.z };\n    return _864;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid fa_lod_dither()\n{\n    if (_129_fa_gi.w != 0.0f)\n    {\n        float _151 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n        bool _154;\n        if (_129_fa_gi.w > 0.0f)\n        {\n            _154 = _151 >= _129_fa_gi.w;\n        }\n        else\n        {\n            _154 = _151 < (-_129_fa_gi.w);\n        }\n        if (_154)\n        {\n            discard;\n        }\n    }\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _721 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _721 = -_721;\n    }\n    float3 _579 = normalize(_129_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _734 = { fa_world_pos, _721, fa_world_tangent, fa_uv, fa_vertex_color, _579, gl_FrontFacing };\n    SurfaceInput param = _734;\n    Surface _584 = fa_standard_surface(param);\n    float3 _745 = _584.normal;\n    SurfaceInput _742 = { fa_world_pos, _721, fa_world_tangent, fa_uv, fa_vertex_color, _579, gl_FrontFacing };\n    SurfaceInput param_1 = _742;\n    Surface param_2 = _584;\n    surface(param_1, param_2);\n    _745 = param_2.normal;\n    fa_lod_dither();\n    float3 _595 = normalize(_745);\n    float3 _610 = normalize(float3(dot(fa_pre_r0, _595), dot(fa_pre_r1, _595), dot(fa_pre_r2, _595)));\n    float _622 = _610.z;\n    float2 e = _610.xy / ((abs(_610.x) + abs(_610.y)) + abs(_622)).xx;\n    if (_622 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_129",
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
