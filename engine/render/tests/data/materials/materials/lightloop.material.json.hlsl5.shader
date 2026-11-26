{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "d1200774cea097b39827c1b4e04c78590627c6e19a8743dd5b2416938bbf252b",
  "slang": "hlsl5",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _263 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _263;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_270, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _4060[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _6500 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _468_fa_camera_pos : packoffset(c0);\n    float4 _468_fa_ambient : packoffset(c1);\n    float4 _468_fa_base_color : packoffset(c2);\n    float4 _468_fa_emissive : packoffset(c3);\n    float4 _468_fa_model_emissive : packoffset(c4);\n    float4 _468_fa_pbr : packoffset(c5);\n    float4 _468_fa_maps : packoffset(c6);\n    float4 _468_fa_fog : packoffset(c7);\n    float4 _468_fa_fog_b : packoffset(c8);\n    float4 _468_fa_fog_c : packoffset(c9);\n    float4 _468_fa_counts : packoffset(c10);\n    float4 _468_fa_env_sky : packoffset(c11);\n    float4 _468_fa_env_horizon : packoffset(c12);\n    float4 _468_fa_time : packoffset(c13);\n    float4 _468_fa_cl_vpx : packoffset(c14);\n    float4 _468_fa_cl_vpy : packoffset(c15);\n    float4 _468_fa_cl_vpw : packoffset(c16);\n    float4 _468_fa_cl_fwd : packoffset(c17);\n    float4 _468_fa_cl_grid : packoffset(c18);\n    float4 _468_fa_cl_info : packoffset(c19);\n    float4 _468_fa_layers_a : packoffset(c20);\n    float4 _468_fa_layers_b : packoffset(c21);\n    float4 _468_fa_layers_c : packoffset(c22);\n    float4 _468_fa_layers_d : packoffset(c23);\n    float4 _468_fa_ct_a : packoffset(c24);\n    float4 _468_fa_ct_b : packoffset(c25);\n    float4 _468_fa_ct_vpx : packoffset(c26);\n    float4 _468_fa_ct_vpy : packoffset(c27);\n    float4 _468_fa_ct_vpw : packoffset(c28);\n    float4 _468_fa_ct_fwd : packoffset(c29);\n    float4 _468_fa_tr_a : packoffset(c30);\n    float4 _468_fa_tr_b : packoffset(c31);\n    float4 _468_fa_probe_sh[9] : packoffset(c32);\n    float4 _468_fa_atlas : packoffset(c41);\n    float4 _468_fa_rpa_tile : packoffset(c42);\n    float4 _468_fa_rpa_pos : packoffset(c43);\n    float4 _468_fa_rpa_bx : packoffset(c44);\n    float4 _468_fa_rpa_by : packoffset(c45);\n    float4 _468_fa_rpa_bz : packoffset(c46);\n    float4 _468_fa_rpb_tile : packoffset(c47);\n    float4 _468_fa_rpb_pos : packoffset(c48);\n    float4 _468_fa_rpb_bx : packoffset(c49);\n    float4 _468_fa_rpb_by : packoffset(c50);\n    float4 _468_fa_rpb_bz : packoffset(c51);\n    float4 _468_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2121_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2121_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2121_fa_shadow_info[4] : packoffset(c20);\n    float4 _2121_fa_shadow_split : packoffset(c24);\n    float4 _2121_fa_shadow_cfg : packoffset(c25);\n    float4 _2121_fa_shadow_bias : packoffset(c26);\n    float4 _2121_fa_shadow_eye : packoffset(c27);\n    float4 _2121_fa_shadow_fwd : packoffset(c28);\n    float4 _2121_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _5202_dark : packoffset(c0);\n    float _5202_fa_pad0 : packoffset(c0.y);\n    float _5202_fa_pad1 : packoffset(c0.z);\n    float _5202_fa_pad2 : packoffset(c0.w);\n    float _5202_skyAmount : packoffset(c1);\n    float _5202_fa_pad3 : packoffset(c1.y);\n    float _5202_fa_pad4 : packoffset(c1.z);\n    float _5202_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t9);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_screen_tex : register(t10);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1397 = _468_fa_cl_info.x < 0.0f;\n    bool _1404;\n    if (!_1397)\n    {\n        _1404 = _468_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1404 = _1397;\n    }\n    bool _1412;\n    if (!_1404)\n    {\n        _1412 = _468_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1412 = _1404;\n    }\n    bool _1419;\n    if (!_1412)\n    {\n        _1419 = _468_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1419 = _1412;\n    }\n    bool _1426;\n    if (!_1419)\n    {\n        _1426 = _468_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1426 = _1419;\n    }\n    if (_1426)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1436 = float4(world_pos, 1.0f);\n    float _1442 = dot(_468_fa_cl_vpw, _1436);\n    if (!(_1442 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1464 = float2(dot(_468_fa_cl_vpx, _1436), dot(_468_fa_cl_vpy, _1436)) / _1442.xx;\n    int _1468 = int(_468_fa_cl_grid.x);\n    int _1472 = int(_468_fa_cl_grid.y);\n    int param = (int(_468_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_468_fa_cl_fwd.xyz, world_pos) + _468_fa_cl_fwd.w, _468_fa_cl_grid.w) / _468_fa_cl_grid.w) * _468_fa_cl_grid.z)), 0, int(_468_fa_cl_info.y) - 1) * _1472) + clamp(int(floor(((_1464.y * 0.5f) + 0.5f) * _468_fa_cl_grid.y)), 0, _1472 - 1)) * _1468)) + clamp(int(floor(((_1464.x * 0.5f) + 0.5f) * _468_fa_cl_grid.x)), 0, _1468 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1548 = fa_cluster_texel(param);\n    return int2(int(_1548.x), int(_1548.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_468_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4886 = fa_cluster_lookup(param);\n    fa_cl_slot = _4886.x;\n    fa_cl_local = _4886.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5263 = fa_linear_to_srgb(param);\n        c = _5263;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5271 = fa_srgb_to_linear(param_1);\n            c = _5271;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _348;\n    if (i.front_facing)\n    {\n        _348 = i.world_normal;\n    }\n    else\n    {\n        _348 = -i.world_normal;\n    }\n    float3 _372 = normalize(i.world_tangent.xyz - (_348 * dot(_348, i.world_tangent.xyz)));\n    float3 _400 = normalize(((_372 * m.x) + ((cross(_348, _372) * i.world_tangent.w) * m.y)) + (_348 * m.z));\n    float3 _403;\n    if (i.front_facing)\n    {\n        _403 = _400;\n    }\n    else\n    {\n        _403 = -_400;\n    }\n    return _403;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _468_fa_env_horizon.w);\n    float param = _468_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5303 = fa_tex_fix(param_2, param_3);\n    float4 _6461 = base_t;\n    _6461.x = _5303.x;\n    _6461.y = _5303.y;\n    _6461.z = _5303.z;\n    base_t = _6461;\n    float4 _5317 = (_6461 * _468_fa_base_color) * i.vertex_color;\n    float3 _6256 = i.world_normal;\n    if (_468_fa_maps.z > 0.5f)\n    {\n        float param_4 = _468_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _468_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5351 = fa_tex_fix(param_6, param_7);\n        float3 _5354 = (_5351 * 2.0f) - 1.0f.xxx;\n        float2 _5359 = _5354.xy * _468_fa_maps.x;\n        float3 _6469 = _5354;\n        _6469.x = _5359.x;\n        _6469.y = _5359.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6469;\n        _6256 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _468_fa_env_horizon.w);\n    float param_10 = _468_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _5389 = fa_tex_fix(param_12, param_13);\n    float4 _6472 = mrt;\n    _6472.x = _5389.x;\n    _6472.y = _5389.y;\n    _6472.z = _5389.z;\n    mrt = _6472;\n    float4 _5419 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _468_fa_env_horizon.w);\n    float param_14 = _468_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _5419.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _5430 = fa_tex_fix(param_16, param_17);\n    float param_18 = _468_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _468_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _5462 = fa_tex_fix(param_20, param_21);\n    float _6261 = _468_fa_layers_a.x;\n    float _6262 = _468_fa_layers_a.y;\n    float _6265 = _468_fa_layers_a.z;\n    float _6264 = _468_fa_layers_b.w;\n    float _6267 = _468_fa_layers_c.x;\n    if (_468_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_468_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6261 *= _5430.y;\n            _6262 *= _5430.z;\n            _6264 *= _5419.w;\n        }\n        if (_468_fa_layers_c.z > 1.5f)\n        {\n            _6265 *= mrt.x;\n            _6267 *= mrt.w;\n        }\n    }\n    Surface _6294 = { _5317.xyz, _5317.w, _6256, clamp(_468_fa_pbr.x * _5389.z, 0.0f, 1.0f), clamp(_468_fa_pbr.y * _5389.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_468_fa_maps.y * (_5430.x - 1.0f)), _468_fa_emissive.xyz + (_468_fa_model_emissive.xyz * _5462), _6261, _6262, _468_fa_layers_b.xyz, _6264, _6265, _468_fa_layers_a.w, _6267, _468_fa_layers_c.y, _468_fa_layers_d.xyz, _468_fa_tr_a.x, _468_fa_tr_a.y, _468_fa_tr_b.xyz, _468_fa_tr_a.z };\n    return _6294;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1628 = rect.zw - rect.xy;\n    float2 _1632 = _1628 * atlas;\n    float2 _1636 = ddx * _1632;\n    float2 _1640 = ddy * _1632;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1628), clamp(0.5f * log2(max(max(dot(_1636, _1636), dot(_1640, _1640)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1673 = _468_fa_counts.y < 0.5f;\n    bool _1680;\n    if (!_1673)\n    {\n        _1680 = _468_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1680 = _1673;\n    }\n    if (_1680)\n    {\n        return;\n    }\n    float3 _1686 = ddx(world_pos);\n    float3 _1689 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1693 = fa_cluster_texel(param);\n    int _1697 = int(_1693.w);\n    if (_1697 < 1)\n    {\n        return;\n    }\n    int _1707 = int(_468_fa_counts.y + 0.5f);\n    int param_1 = _1707;\n    float4 _1711 = fa_light_texel(param_1);\n    float2 _1714 = _1711.yz;\n    int _1718 = int(_1711.w);\n    int param_2 = _1707 + 1;\n    float4 _1723 = fa_light_texel(param_2);\n    float _1724 = _1723.x;\n    int _1730 = int(_468_fa_counts.w + 0.5f) - 1;\n    int _1734 = int(_1693.z);\n    float3 _1999;\n    for (int k = 0; k < _1697; k++)\n    {\n        int _1747 = _1734 + k;\n        int param_3 = _1718 + (_1747 >> 2);\n        int _1764 = (_1707 + 2) + (int(fa_light_texel(param_3)[_1747 & 3]) * 7);\n        int param_4 = _1764 + 6;\n        float4 _1769 = fa_light_texel(param_4);\n        if (((int(_1769.w + 0.5f) >> _1730) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1764;\n        float4 _1784 = fa_light_texel(param_5);\n        int param_6 = _1764 + 1;\n        float4 _1789 = fa_light_texel(param_6);\n        int param_7 = _1764 + 2;\n        float4 _1794 = fa_light_texel(param_7);\n        float3 _1797 = _1784.xyz;\n        float _1802 = dot(_1797, world_pos) + _1784.w;\n        float3 _1804 = _1789.xyz;\n        float _1809 = dot(_1804, world_pos) + _1789.w;\n        float3 _1811 = _1794.xyz;\n        float _1816 = dot(_1811, world_pos) + _1794.w;\n        bool _1821 = abs(_1802) > 0.5f;\n        bool _1829;\n        if (!_1821)\n        {\n            _1829 = abs(_1809) > 0.5f;\n        }\n        else\n        {\n            _1829 = _1821;\n        }\n        bool _1837;\n        if (!_1829)\n        {\n            _1837 = abs(_1816) > 0.5f;\n        }\n        else\n        {\n            _1837 = _1829;\n        }\n        if (_1837)\n        {\n            continue;\n        }\n        float _1852 = clamp(dot(geo_normal, normalize(_1811)) * _1769.z, 0.0f, 1.0f);\n        if (_1852 <= 0.0f)\n        {\n            continue;\n        }\n        float _1872 = (clamp((0.5f - abs(_1816)) * 10.0f, 0.0f, 1.0f) * _1852) * _1769.x;\n        float2 _1880 = float2(_1802 + 0.5f, 0.5f - _1809);\n        float2 _1890 = float2(dot(_1797, _1686), dot(_1804, _1686));\n        float2 _1900 = float2(dot(_1797, _1689), dot(_1804, _1689));\n        int param_8 = _1764 + 5;\n        float4 _1905 = fa_light_texel(param_8);\n        int param_9 = _1764 + 3;\n        float4 _1910 = fa_light_texel(param_9);\n        int param_10 = _1764 + 4;\n        float4 _1915 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1905.xyz;\n        bool _1925 = _1910.z > _1910.x;\n        if (_1925)\n        {\n            float4 param_11 = _1910;\n            float2 param_12 = _1880;\n            float2 param_13 = _1714;\n            float2 param_14 = _1890;\n            float2 param_15 = _1900;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1724 > 0.5f) && (_1724 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1951 = fa_dc_to_linear(param_16);\n                float4 _6344 = tx;\n                _6344.x = _1951.x;\n                _6344.y = _1951.y;\n                _6344.z = _1951.z;\n                tx = _6344;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1872 * tex_a) * _1905.w, 0.0f, 1.0f).xxx);\n        if (_1915.z > _1915.x)\n        {\n            float4 param_17 = _1915;\n            float2 param_18 = _1880;\n            float2 param_19 = _1714;\n            float2 param_20 = _1890;\n            float2 param_21 = _1900;\n            float4 _1995 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1724 > 1.5f)\n            {\n                float3 param_22 = _1995.xyz;\n                float3 _2005 = fa_dc_to_srgb(param_22);\n                _1999 = _2005;\n            }\n            else\n            {\n                _1999 = _1995.xyz;\n            }\n            float3 _2014 = (_1999 * 2.0f) - 1.0f.xxx;\n            float2 _2019 = _2014.xy * _1769.y;\n            float3 _2041 = (normalize(_1797) * _2019.x) + (normalize(_1804) * _2019.y);\n            float3 _2044 = normalize(normal);\n            normal = normalize(lerp(_2044, normalize((_2044 * max(_2014.z, 0.0500000007450580596923828125f)) + (_2041 - (_2044 * dot(_2044, _2041)))), clamp(_1872 * (_1925 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _6500;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_468_fa_cl_info.x) + int(_468_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_468_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4856;\n    if (fa_lm.z > 0.5f)\n    {\n        _4856 = 0.0f;\n    }\n    else\n    {\n        _4856 = 1.0f - clamp(_468_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4867 = _4856 < 1.0f;\n    bool _4873;\n    if (_4867)\n    {\n        int param = li;\n        _4873 = fa_light_baked(param);\n    }\n    else\n    {\n        _4873 = _4867;\n    }\n    return _4873 ? _4856 : 1.0f;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _646 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _659 = (c - (ru * hx)) - p;\n        float3 _665 = ru * (2.0f * hx);\n        float _671 = max(dot(_665, _665), 9.9999999392252902907785028219223e-09f);\n        float _675 = dot(_659, _665);\n        float t = clamp((-_675) / _671, 0.0f, 1.0f);\n        if (_646)\n        {\n            float _690 = dot(r, _665);\n            float _696 = _671 - (_690 * _690);\n            if (abs(_696) > (9.9999997473787516355514526367188e-06f * _671))\n            {\n                t = clamp(((dot(r, _659) * _690) - _675) / _696, 0.0f, 1.0f);\n            }\n        }\n        return (p + _659) + (_665 * t);\n    }\n    float3 q = p;\n    float _728 = dot(r, axis);\n    bool _736;\n    if (_646)\n    {\n        _736 = abs(_728) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _736 = _646;\n    }\n    if (_736)\n    {\n        float _746 = dot(c - p, axis) / _728;\n        if (_746 > 0.0f)\n        {\n            q = p + (r * _746);\n        }\n    }\n    float3 _759 = q - c;\n    float2 xy = float2(dot(_759, ru), dot(_759, uu));\n    if (shape > 0.5f)\n    {\n        float _774 = length(xy);\n        if (_774 > hx)\n        {\n            xy *= (hx / _774);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _527_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _527_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _566 = dot(d, right);\n    float _570 = dot(d, up);\n    float _581;\n    if (((_566 * _566) + (_570 * _570)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _581 = atan2(_570, _566) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _581 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_581 - floor(_581)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _415 = abs(d);\n    float _417 = _415.x;\n    float _419 = _415.y;\n    bool _420 = _417 >= _419;\n    bool _428;\n    if (_420)\n    {\n        _428 = _417 >= _415.z;\n    }\n    else\n    {\n        _428 = _420;\n    }\n    int _429;\n    if (_428)\n    {\n        _429 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _444;\n        if (_419 >= _415.z)\n        {\n            _444 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _444 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _429 = _444;\n    }\n    return _429;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _812 = fa_light_base(param);\n    bool _816 = _468_fa_ambient.w > 4.5f;\n    int param_1 = _812;\n    float4 _820 = fa_light_texel(param_1);\n    int param_2 = _812 + 1;\n    float4 _825 = fa_light_texel(param_2);\n    float _828 = _825.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _840 = _816 && (_828 > 2.5f);\n    fa_light_is_area = _840;\n    bool _842 = _828 < 0.5f;\n    float3 l;\n    if (_842)\n    {\n        l = normalize(_820.xyz);\n        if (_816)\n        {\n            int param_3 = _812 + 6;\n            float4 _856 = fa_light_texel(param_3);\n            if (_856.z > 0.5f)\n            {\n                int param_4 = _812 + 4;\n                float4 _866 = fa_light_texel(param_4);\n                int param_5 = _812 + 5;\n                float4 _871 = fa_light_texel(param_5);\n                float2 param_6 = _856.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _866.xyz) * _866.w, (-dot(world_pos, _871.xyz)) * _871.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _901 = _820.xyz;\n        float3 _903 = _901 - world_pos;\n        float3 to_light = _903;\n        float _906 = length(_903);\n        float reach = _906;\n        bool front = true;\n        if (_840)\n        {\n            int param_8 = _812 + 7;\n            reach = max(_906 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _812 + 4;\n            float4 _930 = fa_light_texel(param_9);\n            int param_10 = _812 + 5;\n            float4 _935 = fa_light_texel(param_10);\n            int param_11 = _812 + 6;\n            float4 _940 = fa_light_texel(param_11);\n            float _941 = _940.w;\n            int param_12 = _812 + 2;\n            float3 _948 = normalize(fa_light_texel(param_12).xyz);\n            bool _950 = _941 > 1.5f;\n            bool _958;\n            if (!_950)\n            {\n                _958 = dot(_948, to_light) < 0.0f;\n            }\n            else\n            {\n                _958 = _950;\n            }\n            front = _958;\n            float3 r = 0.0f.xxx;\n            float3 _967 = _468_fa_camera_pos.xyz - world_pos;\n            bool _971 = dot(n, n) > 0.5f;\n            bool _979;\n            if (_971)\n            {\n                _979 = dot(_967, _967) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _979 = _971;\n            }\n            if (_979)\n            {\n                r = reflect(-normalize(_967), normalize(n));\n            }\n            float3 param_13 = _901;\n            float3 param_14 = _948;\n            float3 param_15 = _930.xyz;\n            float3 param_16 = _935.xyz;\n            float param_17 = _930.w;\n            float param_18 = _935.w;\n            float param_19 = _941;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1015 = length(to_light);\n        dist = _1015;\n        l = to_light / max(_1015, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1029 = reach / max(_820.w, 0.001000000047497451305389404296875f);\n        float _1035 = clamp(1.0f - (_1029 * _1029), 0.0f, 1.0f);\n        float _1037;\n        if (front)\n        {\n            _1037 = _1035 * _1035;\n        }\n        else\n        {\n            _1037 = 0.0f;\n        }\n        atten = _1037;\n        bool _1048 = _828 < 2.5f;\n        if ((_828 > 1.5f) && _1048)\n        {\n            int param_22 = _812 + 2;\n            float4 _1056 = fa_light_texel(param_22);\n            float _1066 = _1056.w;\n            int param_23 = _812 + 3;\n            float4 _1071 = fa_light_texel(param_23);\n            float _1072 = _1071.x;\n            float cos_inner = _1072;\n            if (_1072 > 1.5f)\n            {\n                cos_inner = lerp(_1066, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1066, cos_inner, dot(-l, normalize(_1056.xyz)));\n        }\n        if (_816 && (_828 < 1.5f))\n        {\n            int param_24 = _812 + 6;\n            float4 _1096 = fa_light_texel(param_24);\n            if (_1096.z > 0.5f)\n            {\n                float3 _1104 = -to_light;\n                int param_25 = _812 + 4;\n                int param_26 = _812 + 5;\n                float3 _1118 = fa_light_texel(param_25).xyz;\n                float3 _1122 = fa_light_texel(param_26).xyz;\n                float3 _1131 = float3(dot(_1104, _1118), dot(_1104, _1122), dot(_1104, cross(_1118, _1122)));\n                float3 param_27 = _1131;\n                int _1135 = fa_cube_face(param_27);\n                int param_28 = _1135;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1162 = float2(dot(_1131, cross(param_29, param_30)), dot(_1131, param_30)) / max(dot(_1131, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1166 = _1135 / 3;\n                float2 param_31 = _1096.xy + (float2(float(_1135 - (_1166 * 3)), float(_1166)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1162.x), 0.5f - (0.5f * _1162.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _812 + 7;\n            float4 _1196 = fa_light_texel(param_33);\n            if (_1196.z > 0.5f)\n            {\n                int param_34 = _812 + 2;\n                int param_35 = _812 + 4;\n                int param_36 = _812 + 5;\n                float2 param_37 = _1196.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_816 && _1048)\n            {\n                int param_42 = _812 + 6;\n                float4 _1243 = fa_light_texel(param_42);\n                int param_43 = _812 + 7;\n                float4 _1248 = fa_light_texel(param_43);\n                bool _1251 = _1243.z > 0.5f;\n                bool _1258;\n                if (!_1251)\n                {\n                    _1258 = _1248.z > 0.5f;\n                }\n                else\n                {\n                    _1258 = _1251;\n                }\n                if (_1258)\n                {\n                    int param_44 = _812 + 2;\n                    float4 _1265 = fa_light_texel(param_44);\n                    float3 _1269 = normalize(_1265.xyz);\n                    int param_45 = _812 + 4;\n                    float4 _1274 = fa_light_texel(param_45);\n                    int param_46 = _812 + 5;\n                    float4 _1279 = fa_light_texel(param_46);\n                    if (_1251)\n                    {\n                        float3 _1287 = -to_light;\n                        float _1294 = _1265.w;\n                        float _1310 = 0.5f / max(dot(_1287, _1269) * (sqrt(max(1.0f - (_1294 * _1294), 0.0f)) / max(_1294, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1243.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1287, _1274.xyz) * _1310), 0.5f - (dot(_1287, _1279.xyz) * _1310));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1248.z > 0.5f)\n                    {\n                        float2 param_49 = _1248.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1269;\n                        float3 param_52 = _1274.xyz;\n                        float3 param_53 = _1279.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6062 = _825.xyz * atten;\n    if (_816)\n    {\n        _6062 *= fa_light_tint;\n    }\n    int _1379;\n    if (_842)\n    {\n        _1379 = 0;\n    }\n    else\n    {\n        _1379 = ((_828 > 1.5f) && (_828 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _6073 = { l, _6062, atten, 1.0f, dist, _1379 };\n    return _6073;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _5085 = n < 0;\n    bool _5092;\n    if (!_5085)\n    {\n        _5092 = n >= fa_light_count();\n    }\n    else\n    {\n        _5092 = _5085;\n    }\n    if (_5092)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _5100 = fa_cl_light(param);\n    int param_1 = _5100;\n    float _5104 = fa_baked_keep(param_1);\n    if (_5104 <= 0.0f)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _5100;\n    float3 param_3 = i.world_pos;\n    float3 param_4 = i.world_normal;\n    LightSample _5120 = fa_light_sample_n(param_2, param_3, param_4);\n    LightSample _6244 = { _5120.direction, _5120.color * _5104, _5120.attenuation * _5104, _5120.shadow, _5120._distance, _5120.type };\n    return _6244;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2168 = fa_shadow_depth(param, param_1);\n    float _2172;\n    if (conv.x < 0.5f)\n    {\n        _2172 = _2168;\n    }\n    else\n    {\n        _2172 = (conv.y * conv.z) / (conv.z - (_2168 * (conv.z - conv.y)));\n    }\n    return _2172;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2218 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2224 = float2(cos(_2218), sin(_2218));\n    float2 dir = _2224;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2233;\n        if (k < 0.0f)\n        {\n            _2233 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2233 = k;\n        }\n        float _2252 = clamp((_2233 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2271 = sqrt((float(i) + 0.5f) * 0.0625f) * _2252;\n            float2 param_3 = uv + (dir * (_2121_fa_shadow_bias.zw * _2271));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2285 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2285 < (zr - (_2271 * plane)))\n            {\n                sum += _2285;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2313 = sum / cnt;\n        float _2323;\n        if (k < 0.0f)\n        {\n            _2323 = (-k) / max(_2313, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2323 = k;\n        }\n        radius = clamp(((max(zr - _2313, 0.0f) * unit) * _2323) / texel_m, 1.5f, 16.0f);\n        dir = _2224;\n    }\n    float lit = 0.0f;\n    int _2349 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2349; i_1++)\n    {\n        float _2368 = sqrt((float(i_1) + 0.5f) / float(_2349)) * radius;\n        float2 param_7 = uv + (dir * (_2121_fa_shadow_bias.zw * _2368));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2368 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2349);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2573 = _468_fa_pbr.z < 0.5f;\n    bool _2580;\n    if (!_2573)\n    {\n        _2580 = _2121_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2580 = _2573;\n    }\n    if (_2580)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2121_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2593 = fa_light_texel(param);\n    float _2594 = _2593.x;\n    if (_2594 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2603 = int(_2594 + 0.5f);\n    int param_1 = _2603;\n    float4 _2607 = fa_light_texel(param_1);\n    int param_2 = _2603 + 1;\n    float4 _2612 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2615 = _2607.y;\n    if (_2615 > 0.0f)\n    {\n        float _2632 = 1.0f - smoothstep(0.75f * _2615, _2615, length(world - _2121_fa_shadow_eye.xyz));\n        fade = _2632;\n        if (_2632 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2607.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2656 = (_2603 + 2) + (face * 6);\n    int param_4 = _2656;\n    int param_5 = _2656 + 1;\n    int param_6 = _2656 + 3;\n    float4 _2670 = fa_light_texel(param_6);\n    int param_7 = _2656 + 4;\n    float4 _2675 = fa_light_texel(param_7);\n    int param_8 = _2656 + 5;\n    float4 _2680 = fa_light_texel(param_8);\n    float _2692 = _2680.x * max(dot(_2670, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2697 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2720 = clamp(dot(n, _2670.xyz), -1.0f, 1.0f);\n    float _2739 = min(sqrt(1.0f - (_2720 * _2720)) / max(abs(dot(n, world - lpos)) / max(dot(_2670, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2742 = _2612.y;\n    float _2744;\n    if (_2742 > 0.0f)\n    {\n        _2744 = _2742;\n    }\n    else\n    {\n        _2744 = 1.5f * _2692;\n    }\n    float4 _2764 = float4(world + (n * (_2744 * sqrt(1.0f - (_2697 * _2697)))), 1.0f);\n    float _2768 = dot(_2670, _2764);\n    float _2771 = _2680.y;\n    if (_2768 < _2771)\n    {\n        return 1.0f;\n    }\n    float2 _2786 = float2(dot(fa_light_texel(param_4), _2764), dot(fa_light_texel(param_5), _2764)) / _2768.xx;\n    float _2788 = _2786.x;\n    bool _2791 = _2788 < _2675.x;\n    bool _2800;\n    if (!_2791)\n    {\n        _2800 = _2788 > _2675.z;\n    }\n    else\n    {\n        _2800 = _2791;\n    }\n    bool _2809;\n    if (!_2800)\n    {\n        _2809 = _2786.y < _2675.y;\n    }\n    else\n    {\n        _2809 = _2800;\n    }\n    bool _2818;\n    if (!_2809)\n    {\n        _2818 = _2786.y > _2675.w;\n    }\n    else\n    {\n        _2818 = _2809;\n    }\n    if (_2818)\n    {\n        return 1.0f;\n    }\n    float _2824 = _2612.x;\n    float _2826;\n    if (_2824 > 0.0f)\n    {\n        _2826 = _2824;\n    }\n    else\n    {\n        _2826 = 1.5f * _2692;\n    }\n    float2 param_9 = _2786;\n    float4 param_10 = _2675;\n    float param_11 = _2768 - (_2826 * (1.0f + (0.5f * _2739)));\n    float param_12 = _2692;\n    float param_13 = 1.0f;\n    float param_14 = _2680.z * 0.25f;\n    float param_15 = (_2692 * min(_2739, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2771, _2680.z);\n    int param_17 = int(_2607.z + 0.5f);\n    float param_18 = _2607.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2111;\n    if (i == 0)\n    {\n        _2111 = _2121_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2127;\n        if (i == 1)\n        {\n            _2127 = _2121_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2135;\n            if (i == 2)\n            {\n                _2135 = _2121_fa_shadow_split.z;\n            }\n            else\n            {\n                _2135 = _2121_fa_shadow_split.w;\n            }\n            _2127 = _2135;\n        }\n        _2111 = _2127;\n    }\n    return _2111;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2414 = max(_2121_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2419 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2425 = sqrt(1.0f - (_2419 * _2419));\n    float _2433 = min(_2425 / max(_2419, 0.20000000298023223876953125f), 4.0f);\n    float _2438;\n    if (_2121_fa_shadow_bias.y > 0.0f)\n    {\n        _2438 = _2121_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2438 = 1.5f * _2121_fa_shadow_info[ci].x;\n    }\n    float4 _2463 = mul(float4(world + (n * (_2438 * _2425)), 1.0f), _2121_fa_shadow_mat[ci]);\n    float _2470 = _2463.x;\n    bool _2473 = _2470 < _2121_fa_shadow_rect[ci].x;\n    bool _2482;\n    if (!_2473)\n    {\n        _2482 = _2470 > _2121_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2482 = _2473;\n    }\n    bool _2491;\n    if (!_2482)\n    {\n        _2491 = _2463.y < _2121_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2491 = _2482;\n    }\n    bool _2500;\n    if (!_2491)\n    {\n        _2500 = _2463.y > _2121_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2500 = _2491;\n    }\n    bool _2507;\n    if (!_2500)\n    {\n        _2507 = _2463.z > 1.0f;\n    }\n    else\n    {\n        _2507 = _2500;\n    }\n    if (_2507)\n    {\n        return -1.0f;\n    }\n    float _2515;\n    if (_2121_fa_shadow_bias.x > 0.0f)\n    {\n        _2515 = _2121_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2515 = 1.5f * _2121_fa_shadow_info[ci].x;\n    }\n    float2 param = _2463.xy;\n    float4 param_1 = _2121_fa_shadow_rect[ci];\n    float param_2 = _2463.z - ((_2515 * (1.0f + (0.5f * _2433))) / _2414);\n    float param_3 = _2121_fa_shadow_info[ci].x;\n    float param_4 = _2414;\n    float param_5 = _2414 * 0.25f;\n    float param_6 = ((_2121_fa_shadow_info[ci].x * min(_2433, 3.0f)) * 0.5f) / _2414;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2121_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2121_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_468_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2893 = int(_2121_fa_shadow_cfg.x + 0.5f);\n    if (_2893 < 1)\n    {\n        return 1.0f;\n    }\n    float _2908 = dot(world - _2121_fa_shadow_eye.xyz, _2121_fa_shadow_fwd.xyz);\n    int param = _2893 - 1;\n    if (_2908 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2920 = _2893 > 1;\n    bool _2927;\n    if (_2920)\n    {\n        _2927 = _2908 > _2121_fa_shadow_split.x;\n    }\n    else\n    {\n        _2927 = _2920;\n    }\n    if (_2927)\n    {\n        ci = 1;\n    }\n    bool _2931 = _2893 > 2;\n    bool _2938;\n    if (_2931)\n    {\n        _2938 = _2908 > _2121_fa_shadow_split.y;\n    }\n    else\n    {\n        _2938 = _2931;\n    }\n    if (_2938)\n    {\n        ci = 2;\n    }\n    bool _2942 = _2893 > 3;\n    bool _2949;\n    if (_2942)\n    {\n        _2949 = _2908 > _2121_fa_shadow_split.z;\n    }\n    else\n    {\n        _2949 = _2942;\n    }\n    if (_2949)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _2960 = min(_2893, 4);\n    float _3001;\n    for (int c = ci; c < _2960; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2980 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _2980;\n            break;\n        }\n        if (_2980 < 0.0f)\n        {\n            continue;\n        }\n        s = _2980;\n        ci = c;\n        if (_2121_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3001 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3001 = _2121_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _3020 = _2121_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3001, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_2908 - (fa_shadow_split_at(param_7) - _3020)) / _3020, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3052;\n        if ((ci + 1) < _2893)\n        {\n            _3052 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3052 = 1.0f;\n        }\n        s = lerp(s, _3052, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    bool _3157 = _468_fa_ct_b.y > 0.5f;\n    bool _3163;\n    if (_3157)\n    {\n        _3163 = _468_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3163 = _3157;\n    }\n    if (_3163)\n    {\n        float _3177 = dot(_468_fa_ct_fwd.xyz, fa_world_pos) + _468_fa_ct_fwd.w;\n        float _3180 = fwidth(_3177);\n        float4 _3190 = float4(fa_world_pos, 1.0f);\n        float _3196 = dot(_468_fa_ct_vpw, _3190);\n        if (_3196 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _3215 = float2(dot(_468_fa_ct_vpx, _3190), dot(_468_fa_ct_vpy, _3190)) / _3196.xx;\n            float _3220 = (_3215.x * 0.5f) + 0.5f;\n            float _3224;\n            if (_468_fa_ct_a.y > 0.5f)\n            {\n                _3224 = (_3215.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _3224 = 0.5f - (_3215.y * 0.5f);\n            }\n            bool _3240 = _3220 >= 0.0f;\n            bool _3246;\n            if (_3240)\n            {\n                _3246 = _3220 < 1.0f;\n            }\n            else\n            {\n                _3246 = _3240;\n            }\n            bool _3252;\n            if (_3246)\n            {\n                _3252 = _3224 >= 0.0f;\n            }\n            else\n            {\n                _3252 = _3246;\n            }\n            bool _3258;\n            if (_3252)\n            {\n                _3258 = _3224 < 1.0f;\n            }\n            else\n            {\n                _3258 = _3252;\n            }\n            if (_3258)\n            {\n                float4 _3284 = fa_screen_tex.Load(int3(clamp(int2(float2(_3220, _3224) * _468_fa_ct_a.zw), int2(0, 0), int2(_468_fa_ct_a.zw) - int2(1, 1)), 0));\n                bool _3287 = _3284.w > 0.5f;\n                bool _3303;\n                if (_3287)\n                {\n                    _3303 = abs(_3177 - _3284.x) <= (((0.00200000009499490261077880859375f * _3177) + 0.00999999977648258209228515625f) + min(1.5f * _3180, 0.100000001490116119384765625f * _3177));\n                }\n                else\n                {\n                    _3303 = _3287;\n                }\n                if (_3303)\n                {\n                    float _3309;\n                    if (_468_fa_ct_b.z > 0.5f)\n                    {\n                        float3 param = fa_world_pos;\n                        float3 param_1 = n;\n                        float3 param_2 = l;\n                        _3309 = min(_3284.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3309 = _3284.y;\n                    }\n                    return _3309;\n                }\n            }\n        }\n    }\n    float3 param_3 = fa_world_pos;\n    float3 param_4 = n;\n    float3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4600 = _468_fa_ct_a.x < 0.5f;\n    bool _4607;\n    if (!_4600)\n    {\n        _4607 = _2121_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4607 = _4600;\n    }\n    if (_4607)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2121_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4620 = fa_light_texel(param);\n    float _4621 = _4620.y;\n    float len = _4621;\n    if (_4621 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4633 = length(world - _468_fa_camera_pos.xyz);\n    float _4642 = 1.0f - smoothstep(0.5f * _468_fa_ct_b.x, _468_fa_ct_b.x, _4633);\n    if (_4642 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4648 = len;\n    float _4651 = min(_4648, 0.89999997615814208984375f * dist);\n    len = _4651;\n    float _4656 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4633);\n    float _4661 = _4656 + (0.5f * _4651);\n    float3 _4667 = world + (gn * _4656);\n    float _4669 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4730;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4684 = (float(k) + _4669) * 0.083333335816860198974609375f;\n        float3 _4692 = _4667 + (l * (_4684 * len));\n        float4 _4698 = float4(_4692, 1.0f);\n        float _4703 = dot(_468_fa_ct_vpw, _4698);\n        if (_4703 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4721 = float2(dot(_468_fa_ct_vpx, _4698), dot(_468_fa_ct_vpy, _4698)) / _4703.xx;\n        float _4725 = _4721.x * 0.5f;\n        float _4726 = _4725 + 0.5f;\n        if (_468_fa_ct_a.y > 0.5f)\n        {\n            _4730 = (_4721.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4730 = 0.5f - (_4721.y * 0.5f);\n        }\n        bool _4746 = _4726 < 0.0f;\n        bool _4753;\n        if (!_4746)\n        {\n            _4753 = _4726 >= 1.0f;\n        }\n        else\n        {\n            _4753 = _4746;\n        }\n        bool _4760;\n        if (!_4753)\n        {\n            _4760 = _4730 < 0.0f;\n        }\n        else\n        {\n            _4760 = _4753;\n        }\n        bool _4767;\n        if (!_4760)\n        {\n            _4767 = _4730 >= 1.0f;\n        }\n        else\n        {\n            _4767 = _4760;\n        }\n        if (_4767)\n        {\n            break;\n        }\n        float4 _4791 = fa_screen_tex.Load(int3(clamp(int2(float2(_4726, _4730) * _468_fa_ct_a.zw), int2(0, 0), int2(_468_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_4791.w < 0.5f)\n        {\n            continue;\n        }\n        float _4809 = (dot(_468_fa_ct_fwd.xyz, _4692) + _468_fa_ct_fwd.w) - _4791.x;\n        if ((_4809 > _4656) && (_4809 < _4661))\n        {\n            occ = max(occ, (1.0f - (_4684 * _4684)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4726, 0.5f - _4725), min(_4730, 1.0f - _4730))));\n        }\n    }\n    return 1.0f - (occ * _4642);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4912 = fa_baked_keep(param);\n    if (_4912 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _6206 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6206;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4938 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6208 = _4938.color;\n    float _6209 = _4938.attenuation;\n    float _6210 = _4938.shadow;\n    bool _4941 = _4938.type == 0;\n    if (_4941 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4938.direction;\n        float _4952 = fa_shadow_factor(param_5, param_6);\n        _6210 = _4952;\n        _6208 *= _4952;\n    }\n    else\n    {\n        bool _4963 = _4938.type != 0;\n        bool _4969;\n        if (_4963)\n        {\n            _4969 = _6209 > 0.0f;\n        }\n        else\n        {\n            _4969 = _4963;\n        }\n        if (_4969)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4938.direction;\n            float _4988 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6210 = _4988;\n            _6208 *= _4988;\n        }\n    }\n    bool _4998 = _468_fa_ct_a.x > 0.5f;\n    bool _5004;\n    if (_4998)\n    {\n        _5004 = _6209 > 0.0f;\n    }\n    else\n    {\n        _5004 = _4998;\n    }\n    if (_5004)\n    {\n        float _5011;\n        if (_4941)\n        {\n            _5011 = 1000000000.0f;\n        }\n        else\n        {\n            _5011 = _4938._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4938.direction;\n        float param_18 = _5011;\n        float _5029 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6210 *= _5029;\n        _6208 *= _5029;\n    }\n    float _5042 = _6209;\n    float _5043 = _5042 * _4912;\n    _6209 = _5043;\n    float3 _5047 = _6208;\n    float3 _5048 = _5047 * _4912;\n    _6208 = _5048;\n    LightSample _6225 = { _4938.direction, _5048, _5043, _6210, _4938._distance, _4938.type };\n    return _6225;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _5059 = n < 0;\n    bool _5066;\n    if (!_5059)\n    {\n        _5066 = n >= fa_light_count();\n    }\n    else\n    {\n        _5066 = _5059;\n    }\n    if (_5066)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    LightSample _5081 = fa_light_shadowed(param_1, param_2, param_3);\n    return _5081;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3985 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3993 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3996 = int(_3985);\n    int _3999 = int(_3993);\n    float _4009 = _3993 - float(_3999);\n    int _4065 = (_3996 * 9) + _3999;\n    int _4085 = ((_3996 + 1) * 9) + _3999;\n    return lerp(lerp(_4060[_4065], _4060[_4065 + 1], _4009), lerp(_4060[_4085], _4060[_4085 + 1], _4009), _3985 - float(_3996));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _6074 = false;\n    float _6075 = 1.0f;\n    float _6076 = 1.0f;\n    float _6077 = 1.0f;\n    float _6078 = 0.0f;\n    float _6079 = 0.0f;\n    float _6080 = 0.0f;\n    float _6081 = 0.0f;\n    float _6083 = 1.0f;\n    bool _6084 = false;\n    float3 _6085 = 0.0f.xxx;\n    float _6086 = 1.0f;\n    float _6087 = 1.0f;\n    float _6088 = 1.0f;\n    float _6089 = 0.0f;\n    float _6090 = 0.0f;\n    float3 _6091 = float3(1.0f, 0.0f, 0.0f);\n    float3 _6092 = float3(0.0f, 0.0f, 1.0f);\n    float _6093 = 1.0f;\n    float _6094 = 1.0f;\n    float _4136 = clamp(s.specular, 0.0f, 1.0f);\n    float _4140 = clamp(s.ior, 1.0f, 3.0f);\n    bool _4145 = (_4136 != 1.0f) || (_4140 != 1.5f);\n    bool _4154;\n    if (!_4145)\n    {\n        _4154 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _4154 = _4145;\n    }\n    if (_4154)\n    {\n        float _4162 = (_4140 - 1.0f) / (_4140 + 1.0f);\n        f0 = lerp(min((_4162 * _4162).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _4136, s.albedo, metallic.xxx);\n        _6075 = lerp(_4136, 1.0f, metallic);\n        _6074 = true;\n    }\n    float _4189 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4189 > 0.0f)\n    {\n        float _4197 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _6078 = _4189;\n        _6079 = _4197;\n        float _4204 = _4197 * _4197;\n        _6080 = _4204;\n        _6081 = _4204 * _4204;\n        float _4216 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _6083 = _4216;\n        _6076 = 1.0f - (_4189 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _4216, 0.0f, 1.0f), 5.0f))));\n        _6074 = true;\n    }\n    float3 _4235 = max(s.sheen_color, 0.0f.xxx);\n    float _4244 = max(_4235.x, max(_4235.y, _4235.z));\n    if (_4244 > 0.0f)\n    {\n        float _4252 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _6084 = true;\n        _6085 = _4235;\n        _6086 = _4252;\n        _6087 = _4252 * _4252;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _4252;\n        float _4269 = fa_sheen_albedo(param, param_1);\n        _6089 = _4269;\n        _6088 = 1.0f - min(_4244 * _4269, 1.0f);\n        _6074 = true;\n    }\n    _6077 = _6076 * _6088;\n    float _4288 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_4288 != 0.0f)\n    {\n        float3 _4303 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _4303;\n        if (dot(_4303, _4303) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _4315 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_4315.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _4315.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _4315.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _4319 = t;\n        float3 _4320 = normalize(_4319);\n        t = _4320;\n        float3 _4345 = normalize((_4320 * cos(s.anisotropy_rotation)) + ((cross(n, _4320) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _6091 = _4345;\n        _6092 = cross(n, _4345);\n        float _4355 = roughness * roughness;\n        float _4361 = lerp(_4355, 1.0f, _4288 * _4288);\n        bool _4363 = _4288 > 0.0f;\n        _6093 = _4363 ? _4361 : _4355;\n        _6094 = _4363 ? _4355 : _4361;\n        _6090 = _4288;\n        _6074 = true;\n    }\n    FaLayers _6116 = { _6074, _6075, _6076, _6077, _6078, _6079, _6080, _6081, i.world_normal, _6083, _6084, _6085, _6086, _6087, _6088, _6089, _6090, _6091, _6092, _6093, _6094 };\n    return _6116;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3917 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3920 = _3917.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3920 * _3920, exp2((-9.27999973297119140625f) * ndv)) * _3920) + _3917.y)) + _3917.zw;\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3353 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3356 = _3353.x;\n    float _3358 = _3353.z;\n    float2 e = float2(_3356, _3358);\n    if (_3353.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3358)) * ((_3356 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3356)) * ((_3358 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3392_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3392_dummy_parameter)));\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _3405;\n    if (lv == 0)\n    {\n        _3405 = 0.0f;\n    }\n    else\n    {\n        _3405 = res + 2.0f;\n    }\n    float _3415;\n    if (lv == 0)\n    {\n        _3415 = 0.0f;\n    }\n    else\n    {\n        _3415 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_3405, _3415)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _3461;\n    if (res > 64.5f)\n    {\n        _3461 = 5.0f;\n    }\n    else\n    {\n        _3461 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _3476 = clamp(rough, 0.0f, 1.0f) * (_3461 - 1.0f);\n    int _3483 = int(min(floor(_3476), _3461 - 2.0f));\n    float _3488 = _3476 - float(_3483);\n    float3 param = d;\n    float2 _3492 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3483;\n    float2 param_4 = _3492;\n    float3 _3502 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3488 < 0.00200000009499490261077880859375f)\n    {\n        return _3502;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3483 + 1;\n    float2 param_8 = _3492;\n    return lerp(_3502, fa_probe_level(param_5, param_6, param_7, param_8), _3488.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _3539 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3546 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3553 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3559 = dot(bx.xyz, d);\n    float _3563 = dot(by.xyz, d);\n    float _3567 = dot(bz.xyz, d);\n    float _3573;\n    if (_3559 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3573 = (1.0f - _3539) / _3559;\n    }\n    else\n    {\n        float _3587;\n        if (_3559 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3587 = ((-1.0f) - _3539) / _3559;\n        }\n        else\n        {\n            _3587 = 1000000015047466219876688855040.0f;\n        }\n        _3573 = _3587;\n    }\n    float tx = _3573;\n    float _3604;\n    if (_3563 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3604 = (1.0f - _3546) / _3563;\n    }\n    else\n    {\n        float _3617;\n        if (_3563 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3617 = ((-1.0f) - _3546) / _3563;\n        }\n        else\n        {\n            _3617 = 1000000015047466219876688855040.0f;\n        }\n        _3604 = _3617;\n    }\n    float ty = _3604;\n    float _3633;\n    if (_3567 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3633 = (1.0f - _3553) / _3567;\n    }\n    else\n    {\n        float _3646;\n        if (_3567 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3646 = ((-1.0f) - _3553) / _3567;\n        }\n        else\n        {\n            _3646 = 1000000015047466219876688855040.0f;\n        }\n        _3633 = _3646;\n    }\n    float _3658 = tx;\n    float _3661 = (_3658 > 0.0f) ? _3658 : 1000000015047466219876688855040.0f;\n    tx = _3661;\n    float _3662 = ty;\n    float _3665 = (_3662 > 0.0f) ? _3662 : 1000000015047466219876688855040.0f;\n    ty = _3665;\n    float _3675 = min(_3661, min(_3665, (_3633 > 0.0f) ? _3633 : 1000000015047466219876688855040.0f));\n    if (_3675 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _3691 = (fa_world_pos + (d * _3675)) - posw.xyz;\n    float3 _3696;\n    if (dot(_3691, _3691) > 1.0000000133514319600180897396058e-10f)\n    {\n        _3696 = normalize(_3691);\n    }\n    else\n    {\n        _3696 = d;\n    }\n    return _3696;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _3742 = (1.0f - _468_fa_rpa_tile.w) - _468_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_3742 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_468_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _468_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3772 = rough * rough;\n            float _3803 = 0.60000002384185791015625f * _3772;\n            base = lerp(lerp(_468_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_468_fa_env_horizon.xyz, _468_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3772)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3803, 0.0500000007450580596923828125f + _3803, d.y).xxx), ((_468_fa_env_sky.xyz + _468_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3772 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _3742;\n    }\n    if (_468_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _468_fa_rpa_tile;\n        float4 param_5 = _468_fa_rpa_pos;\n        float4 param_6 = _468_fa_rpa_bx;\n        float4 param_7 = _468_fa_rpa_by;\n        float4 param_8 = _468_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _3862 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3862 * _468_fa_rpa_tile.w);\n    }\n    if (_468_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _468_fa_rpb_tile;\n        float4 param_12 = _468_fa_rpb_pos;\n        float4 param_13 = _468_fa_rpb_bx;\n        float4 param_14 = _468_fa_rpb_by;\n        float4 param_15 = _468_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _3894 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3894 * _468_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness, float occlusion)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4396;\n        if (L.aniso >= 0.0f)\n        {\n            _4396 = L.b;\n        }\n        else\n        {\n            _4396 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4396, v), _4396), (abs(L.aniso) * smoothstep(0.0f, 0.25f, roughness)).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4432 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4432.x) + (L.f90.xxx * _4432.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4490 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4490.x) + _4490.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3959 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3959.x) + _3959.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4529 = clamp(s.metallic, 0.0f, 1.0f);\n    float _4533 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _4540 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _4529.xxx);\n    float3 f0 = _4540;\n    float3 _4544 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _4544;\n    float3 param_3 = i.view_dir;\n    float param_4 = _4529;\n    float param_5 = _4533;\n    float3 param_6 = _4540;\n    FaLayers _4561 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4561.on)\n    {\n        FaLayers param_7 = _4561;\n        float3 param_8 = _4544;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _4533;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    float3 param_13 = _4544;\n    float3 param_14 = i.view_dir;\n    float3 param_15 = f0;\n    float param_16 = _4533;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _5151 = fa_light_unshadowed(param, param_1);\n        float _5159 = dot(_5151.color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_5159 > bestPower)\n        {\n            bestPower = _5159;\n            best = n;\n        }\n    }\n    float3 lit = (_468_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _5188 = fa_light(param_2, param_3);\n        float _5196;\n        if (dot(s.normal, _5188.direction) > 0.5f)\n        {\n            _5196 = 1.0f;\n        }\n        else\n        {\n            _5196 = _5202_dark;\n        }\n        lit += ((s.albedo * _5188.color) * _5196);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _5202_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2121_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3080 = int(_2121_fa_shadow_cfg.x + 0.5f);\n    float _3090 = dot(world - _2121_fa_shadow_eye.xyz, _2121_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3095 = _3080 > 0;\n    bool _3104;\n    if (_3095)\n    {\n        int param = _3080 - 1;\n        _3104 = _3090 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3104 = _3095;\n    }\n    if (_3104)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3110 = _3080 > 1;\n        bool _3117;\n        if (_3110)\n        {\n            _3117 = _3090 > _2121_fa_shadow_split.x;\n        }\n        else\n        {\n            _3117 = _3110;\n        }\n        if (_3117)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3123 = _3080 > 2;\n        bool _3130;\n        if (_3123)\n        {\n            _3130 = _3090 > _2121_fa_shadow_split.y;\n        }\n        else\n        {\n            _3130 = _3123;\n        }\n        if (_3130)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3136 = _3080 > 3;\n        bool _3143;\n        if (_3136)\n        {\n            _3143 = _3090 > _2121_fa_shadow_split.z;\n        }\n        else\n        {\n            _3143 = _3136;\n        }\n        if (_3143)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5928 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5928 = -_5928;\n    }\n    float3 _5598 = normalize(_468_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5941 = { fa_world_pos, _5928, fa_world_tangent, fa_uv, fa_vertex_color, _5598, gl_FrontFacing };\n    SurfaceInput param_1 = _5941;\n    Surface _5606 = fa_standard_surface(param_1);\n    float3 _5959 = _5606.albedo;\n    float _5960 = _5606.alpha;\n    float3 _5961 = _5606.normal;\n    float _5962 = _5606.metallic;\n    float _5963 = _5606.roughness;\n    float _5964 = _5606.occlusion;\n    float3 _5965 = _5606.emission;\n    float _5966 = _5606.clearcoat;\n    float _5967 = _5606.clearcoat_roughness;\n    float3 _5968 = _5606.sheen_color;\n    float _5969 = _5606.sheen_roughness;\n    float _5970 = _5606.anisotropy;\n    float _5971 = _5606.anisotropy_rotation;\n    float _5972 = _5606.specular;\n    float _5973 = _5606.ior;\n    float3 _5974 = _5606.specular_color;\n    float _5975 = _5606.transmission;\n    float _5976 = _5606.thickness;\n    float3 _5977 = _5606.attenuation_color;\n    float _5978 = _5606.attenuation_distance;\n    SurfaceInput _5949 = { fa_world_pos, _5928, fa_world_tangent, fa_uv, fa_vertex_color, _5598, gl_FrontFacing };\n    SurfaceInput param_2 = _5949;\n    Surface param_3 = _5606;\n    surface(param_2, param_3);\n    _5959 = param_3.albedo;\n    _5960 = param_3.alpha;\n    _5961 = param_3.normal;\n    _5962 = param_3.metallic;\n    _5963 = param_3.roughness;\n    _5964 = param_3.occlusion;\n    _5965 = param_3.emission;\n    _5966 = param_3.clearcoat;\n    _5967 = param_3.clearcoat_roughness;\n    _5968 = param_3.sheen_color;\n    _5969 = param_3.sheen_roughness;\n    _5970 = param_3.anisotropy;\n    _5971 = param_3.anisotropy_rotation;\n    _5972 = param_3.specular;\n    _5973 = param_3.ior;\n    _5974 = param_3.specular_color;\n    _5975 = param_3.transmission;\n    _5976 = param_3.thickness;\n    _5977 = param_3.attenuation_color;\n    _5978 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5928;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5959 = param_6;\n    _5961 = param_7;\n    float3 result;\n    if (_468_fa_emissive.w > 0.5f)\n    {\n        result = _5959;\n    }\n    else\n    {\n        float3 _5645 = _5961;\n        float3 _5646 = normalize(_5645);\n        _5961 = _5646;\n        SurfaceInput _5957 = { fa_world_pos, _5928, fa_world_tangent, fa_uv, fa_vertex_color, _5598, gl_FrontFacing };\n        SurfaceInput param_8 = _5957;\n        Surface _6060 = { _5959, _5960, _5646, _5962, _5963, _5964, _5965, _5966, _5967, _5968, _5969, _5970, _5971, _5972, _5973, _5974, _5975, _5976, _5977, _5978 };\n        Surface param_9 = _6060;\n        float3 _5657 = lighting(param_8, param_9);\n        result = _5657;\n    }\n    float3 _5661 = result;\n    float3 _5662 = _5661 + _5965;\n    result = _5662;\n    float3 param_10 = _5662;\n    float3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _5671 = _468_fa_fog.w > 0.0f;\n    bool _5678;\n    if (!_5671)\n    {\n        _5678 = _468_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5678 = _5671;\n    }\n    if (_5678)\n    {\n        float3 _5687 = fa_world_pos - _468_fa_camera_pos.xyz;\n        float _5693 = dot(_5687, _468_fa_fog_c.xyz);\n        bool _5697 = _468_fa_fog_c.w > 0.5f;\n        float _5698;\n        if (_5697)\n        {\n            _5698 = _5693;\n        }\n        else\n        {\n            _5698 = length(_5687);\n        }\n        float _5710 = _5698 - _468_fa_fog_b.x;\n        if (_5710 > 0.0f)\n        {\n            float _5719 = _468_fa_fog.w * _5710;\n            float tau = _5719 * _5719;\n            if (_468_fa_fog_b.y > 0.0f)\n            {\n                float _5735;\n                if (_5697)\n                {\n                    _5735 = fa_world_pos.y - (_468_fa_fog_c.y * _5693);\n                }\n                else\n                {\n                    _5735 = _468_fa_camera_pos.y;\n                }\n                float _5756 = lerp(_5735, fa_world_pos.y, clamp(_468_fa_fog_b.x / _5698, 0.0f, 1.0f));\n                float _5760 = fa_world_pos.y - _5756;\n                float _5765 = _5756 - _468_fa_fog_b.z;\n                float _5770 = fa_world_pos.y - _468_fa_fog_b.z;\n                bool _5773 = _5765 <= 0.0f;\n                bool _5774 = !_5773;\n                bool _5780;\n                if (_5774)\n                {\n                    _5780 = _468_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5780 = _5773;\n                }\n                float _5781;\n                if (_5780)\n                {\n                    _5781 = _468_fa_fog_b.y;\n                }\n                else\n                {\n                    _5781 = _468_fa_fog_b.y * exp(-min(_468_fa_fog_b.w * _5765, 80.0f));\n                }\n                bool _5808;\n                if (_5774)\n                {\n                    _5808 = _468_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5808 = _5773;\n                }\n                float _5809;\n                if (_5808)\n                {\n                    _5809 = _468_fa_fog_b.y * _5765;\n                }\n                else\n                {\n                    _5809 = (_468_fa_fog_b.y * (1.0f - exp(-min(_468_fa_fog_b.w * _5765, 80.0f)))) / _468_fa_fog_b.w;\n                }\n                bool _5834 = _5770 <= 0.0f;\n                bool _5841;\n                if (!_5834)\n                {\n                    _5841 = _468_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5841 = _5834;\n                }\n                float _5842;\n                if (_5841)\n                {\n                    _5842 = _468_fa_fog_b.y * _5770;\n                }\n                else\n                {\n                    _5842 = (_468_fa_fog_b.y * (1.0f - exp(-min(_468_fa_fog_b.w * _5770, 80.0f)))) / _468_fa_fog_b.w;\n                }\n                float _5869;\n                if (abs(_5760) < 0.001000000047497451305389404296875f)\n                {\n                    _5869 = _5781;\n                }\n                else\n                {\n                    _5869 = (_5842 - _5809) / _5760;\n                }\n                tau += (_5710 * max(_5869, 0.0f));\n            }\n            result = lerp(result, _468_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5960);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_468",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2121",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_5202",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _4060[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _6500 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _468_fa_camera_pos : packoffset(c0);\n    float4 _468_fa_ambient : packoffset(c1);\n    float4 _468_fa_base_color : packoffset(c2);\n    float4 _468_fa_emissive : packoffset(c3);\n    float4 _468_fa_model_emissive : packoffset(c4);\n    float4 _468_fa_pbr : packoffset(c5);\n    float4 _468_fa_maps : packoffset(c6);\n    float4 _468_fa_fog : packoffset(c7);\n    float4 _468_fa_fog_b : packoffset(c8);\n    float4 _468_fa_fog_c : packoffset(c9);\n    float4 _468_fa_counts : packoffset(c10);\n    float4 _468_fa_env_sky : packoffset(c11);\n    float4 _468_fa_env_horizon : packoffset(c12);\n    float4 _468_fa_time : packoffset(c13);\n    float4 _468_fa_cl_vpx : packoffset(c14);\n    float4 _468_fa_cl_vpy : packoffset(c15);\n    float4 _468_fa_cl_vpw : packoffset(c16);\n    float4 _468_fa_cl_fwd : packoffset(c17);\n    float4 _468_fa_cl_grid : packoffset(c18);\n    float4 _468_fa_cl_info : packoffset(c19);\n    float4 _468_fa_layers_a : packoffset(c20);\n    float4 _468_fa_layers_b : packoffset(c21);\n    float4 _468_fa_layers_c : packoffset(c22);\n    float4 _468_fa_layers_d : packoffset(c23);\n    float4 _468_fa_ct_a : packoffset(c24);\n    float4 _468_fa_ct_b : packoffset(c25);\n    float4 _468_fa_ct_vpx : packoffset(c26);\n    float4 _468_fa_ct_vpy : packoffset(c27);\n    float4 _468_fa_ct_vpw : packoffset(c28);\n    float4 _468_fa_ct_fwd : packoffset(c29);\n    float4 _468_fa_tr_a : packoffset(c30);\n    float4 _468_fa_tr_b : packoffset(c31);\n    float4 _468_fa_probe_sh[9] : packoffset(c32);\n    float4 _468_fa_atlas : packoffset(c41);\n    float4 _468_fa_rpa_tile : packoffset(c42);\n    float4 _468_fa_rpa_pos : packoffset(c43);\n    float4 _468_fa_rpa_bx : packoffset(c44);\n    float4 _468_fa_rpa_by : packoffset(c45);\n    float4 _468_fa_rpa_bz : packoffset(c46);\n    float4 _468_fa_rpb_tile : packoffset(c47);\n    float4 _468_fa_rpb_pos : packoffset(c48);\n    float4 _468_fa_rpb_bx : packoffset(c49);\n    float4 _468_fa_rpb_by : packoffset(c50);\n    float4 _468_fa_rpb_bz : packoffset(c51);\n    float4 _468_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2121_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2121_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2121_fa_shadow_info[4] : packoffset(c20);\n    float4 _2121_fa_shadow_split : packoffset(c24);\n    float4 _2121_fa_shadow_cfg : packoffset(c25);\n    float4 _2121_fa_shadow_bias : packoffset(c26);\n    float4 _2121_fa_shadow_eye : packoffset(c27);\n    float4 _2121_fa_shadow_fwd : packoffset(c28);\n    float4 _2121_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _5202_dark : packoffset(c0);\n    float _5202_fa_pad0 : packoffset(c0.y);\n    float _5202_fa_pad1 : packoffset(c0.z);\n    float _5202_fa_pad2 : packoffset(c0.w);\n    float _5202_skyAmount : packoffset(c1);\n    float _5202_fa_pad3 : packoffset(c1.y);\n    float _5202_fa_pad4 : packoffset(c1.z);\n    float _5202_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t9);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_screen_tex : register(t10);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1397 = _468_fa_cl_info.x < 0.0f;\n    bool _1404;\n    if (!_1397)\n    {\n        _1404 = _468_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1404 = _1397;\n    }\n    bool _1412;\n    if (!_1404)\n    {\n        _1412 = _468_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1412 = _1404;\n    }\n    bool _1419;\n    if (!_1412)\n    {\n        _1419 = _468_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1419 = _1412;\n    }\n    bool _1426;\n    if (!_1419)\n    {\n        _1426 = _468_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1426 = _1419;\n    }\n    if (_1426)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1436 = float4(world_pos, 1.0f);\n    float _1442 = dot(_468_fa_cl_vpw, _1436);\n    if (!(_1442 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1464 = float2(dot(_468_fa_cl_vpx, _1436), dot(_468_fa_cl_vpy, _1436)) / _1442.xx;\n    int _1468 = int(_468_fa_cl_grid.x);\n    int _1472 = int(_468_fa_cl_grid.y);\n    int param = (int(_468_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_468_fa_cl_fwd.xyz, world_pos) + _468_fa_cl_fwd.w, _468_fa_cl_grid.w) / _468_fa_cl_grid.w) * _468_fa_cl_grid.z)), 0, int(_468_fa_cl_info.y) - 1) * _1472) + clamp(int(floor(((_1464.y * 0.5f) + 0.5f) * _468_fa_cl_grid.y)), 0, _1472 - 1)) * _1468)) + clamp(int(floor(((_1464.x * 0.5f) + 0.5f) * _468_fa_cl_grid.x)), 0, _1468 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1548 = fa_cluster_texel(param);\n    return int2(int(_1548.x), int(_1548.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_468_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4886 = fa_cluster_lookup(param);\n    fa_cl_slot = _4886.x;\n    fa_cl_local = _4886.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5263 = fa_linear_to_srgb(param);\n        c = _5263;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5271 = fa_srgb_to_linear(param_1);\n            c = _5271;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _348;\n    if (i.front_facing)\n    {\n        _348 = i.world_normal;\n    }\n    else\n    {\n        _348 = -i.world_normal;\n    }\n    float3 _372 = normalize(i.world_tangent.xyz - (_348 * dot(_348, i.world_tangent.xyz)));\n    float3 _400 = normalize(((_372 * m.x) + ((cross(_348, _372) * i.world_tangent.w) * m.y)) + (_348 * m.z));\n    float3 _403;\n    if (i.front_facing)\n    {\n        _403 = _400;\n    }\n    else\n    {\n        _403 = -_400;\n    }\n    return _403;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _468_fa_env_horizon.w);\n    float param = _468_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5303 = fa_tex_fix(param_2, param_3);\n    float4 _6461 = base_t;\n    _6461.x = _5303.x;\n    _6461.y = _5303.y;\n    _6461.z = _5303.z;\n    base_t = _6461;\n    float4 _5317 = (_6461 * _468_fa_base_color) * i.vertex_color;\n    float3 _6256 = i.world_normal;\n    if (_468_fa_maps.z > 0.5f)\n    {\n        float param_4 = _468_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _468_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5351 = fa_tex_fix(param_6, param_7);\n        float3 _5354 = (_5351 * 2.0f) - 1.0f.xxx;\n        float2 _5359 = _5354.xy * _468_fa_maps.x;\n        float3 _6469 = _5354;\n        _6469.x = _5359.x;\n        _6469.y = _5359.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6469;\n        _6256 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _468_fa_env_horizon.w);\n    float param_10 = _468_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _5389 = fa_tex_fix(param_12, param_13);\n    float4 _6472 = mrt;\n    _6472.x = _5389.x;\n    _6472.y = _5389.y;\n    _6472.z = _5389.z;\n    mrt = _6472;\n    float4 _5419 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _468_fa_env_horizon.w);\n    float param_14 = _468_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _5419.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _5430 = fa_tex_fix(param_16, param_17);\n    float param_18 = _468_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _468_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _5462 = fa_tex_fix(param_20, param_21);\n    float _6261 = _468_fa_layers_a.x;\n    float _6262 = _468_fa_layers_a.y;\n    float _6265 = _468_fa_layers_a.z;\n    float _6264 = _468_fa_layers_b.w;\n    float _6267 = _468_fa_layers_c.x;\n    if (_468_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_468_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6261 *= _5430.y;\n            _6262 *= _5430.z;\n            _6264 *= _5419.w;\n        }\n        if (_468_fa_layers_c.z > 1.5f)\n        {\n            _6265 *= mrt.x;\n            _6267 *= mrt.w;\n        }\n    }\n    Surface _6294 = { _5317.xyz, _5317.w, _6256, clamp(_468_fa_pbr.x * _5389.z, 0.0f, 1.0f), clamp(_468_fa_pbr.y * _5389.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_468_fa_maps.y * (_5430.x - 1.0f)), _468_fa_emissive.xyz + (_468_fa_model_emissive.xyz * _5462), _6261, _6262, _468_fa_layers_b.xyz, _6264, _6265, _468_fa_layers_a.w, _6267, _468_fa_layers_c.y, _468_fa_layers_d.xyz, _468_fa_tr_a.x, _468_fa_tr_a.y, _468_fa_tr_b.xyz, _468_fa_tr_a.z };\n    return _6294;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1628 = rect.zw - rect.xy;\n    float2 _1632 = _1628 * atlas;\n    float2 _1636 = ddx * _1632;\n    float2 _1640 = ddy * _1632;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1628), clamp(0.5f * log2(max(max(dot(_1636, _1636), dot(_1640, _1640)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1673 = _468_fa_counts.y < 0.5f;\n    bool _1680;\n    if (!_1673)\n    {\n        _1680 = _468_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1680 = _1673;\n    }\n    if (_1680)\n    {\n        return;\n    }\n    float3 _1686 = ddx(world_pos);\n    float3 _1689 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1693 = fa_cluster_texel(param);\n    int _1697 = int(_1693.w);\n    if (_1697 < 1)\n    {\n        return;\n    }\n    int _1707 = int(_468_fa_counts.y + 0.5f);\n    int param_1 = _1707;\n    float4 _1711 = fa_light_texel(param_1);\n    float2 _1714 = _1711.yz;\n    int _1718 = int(_1711.w);\n    int param_2 = _1707 + 1;\n    float4 _1723 = fa_light_texel(param_2);\n    float _1724 = _1723.x;\n    int _1730 = int(_468_fa_counts.w + 0.5f) - 1;\n    int _1734 = int(_1693.z);\n    float3 _1999;\n    for (int k = 0; k < _1697; k++)\n    {\n        int _1747 = _1734 + k;\n        int param_3 = _1718 + (_1747 >> 2);\n        int _1764 = (_1707 + 2) + (int(fa_light_texel(param_3)[_1747 & 3]) * 7);\n        int param_4 = _1764 + 6;\n        float4 _1769 = fa_light_texel(param_4);\n        if (((int(_1769.w + 0.5f) >> _1730) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1764;\n        float4 _1784 = fa_light_texel(param_5);\n        int param_6 = _1764 + 1;\n        float4 _1789 = fa_light_texel(param_6);\n        int param_7 = _1764 + 2;\n        float4 _1794 = fa_light_texel(param_7);\n        float3 _1797 = _1784.xyz;\n        float _1802 = dot(_1797, world_pos) + _1784.w;\n        float3 _1804 = _1789.xyz;\n        float _1809 = dot(_1804, world_pos) + _1789.w;\n        float3 _1811 = _1794.xyz;\n        float _1816 = dot(_1811, world_pos) + _1794.w;\n        bool _1821 = abs(_1802) > 0.5f;\n        bool _1829;\n        if (!_1821)\n        {\n            _1829 = abs(_1809) > 0.5f;\n        }\n        else\n        {\n            _1829 = _1821;\n        }\n        bool _1837;\n        if (!_1829)\n        {\n            _1837 = abs(_1816) > 0.5f;\n        }\n        else\n        {\n            _1837 = _1829;\n        }\n        if (_1837)\n        {\n            continue;\n        }\n        float _1852 = clamp(dot(geo_normal, normalize(_1811)) * _1769.z, 0.0f, 1.0f);\n        if (_1852 <= 0.0f)\n        {\n            continue;\n        }\n        float _1872 = (clamp((0.5f - abs(_1816)) * 10.0f, 0.0f, 1.0f) * _1852) * _1769.x;\n        float2 _1880 = float2(_1802 + 0.5f, 0.5f - _1809);\n        float2 _1890 = float2(dot(_1797, _1686), dot(_1804, _1686));\n        float2 _1900 = float2(dot(_1797, _1689), dot(_1804, _1689));\n        int param_8 = _1764 + 5;\n        float4 _1905 = fa_light_texel(param_8);\n        int param_9 = _1764 + 3;\n        float4 _1910 = fa_light_texel(param_9);\n        int param_10 = _1764 + 4;\n        float4 _1915 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1905.xyz;\n        bool _1925 = _1910.z > _1910.x;\n        if (_1925)\n        {\n            float4 param_11 = _1910;\n            float2 param_12 = _1880;\n            float2 param_13 = _1714;\n            float2 param_14 = _1890;\n            float2 param_15 = _1900;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1724 > 0.5f) && (_1724 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1951 = fa_dc_to_linear(param_16);\n                float4 _6344 = tx;\n                _6344.x = _1951.x;\n                _6344.y = _1951.y;\n                _6344.z = _1951.z;\n                tx = _6344;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1872 * tex_a) * _1905.w, 0.0f, 1.0f).xxx);\n        if (_1915.z > _1915.x)\n        {\n            float4 param_17 = _1915;\n            float2 param_18 = _1880;\n            float2 param_19 = _1714;\n            float2 param_20 = _1890;\n            float2 param_21 = _1900;\n            float4 _1995 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1724 > 1.5f)\n            {\n                float3 param_22 = _1995.xyz;\n                float3 _2005 = fa_dc_to_srgb(param_22);\n                _1999 = _2005;\n            }\n            else\n            {\n                _1999 = _1995.xyz;\n            }\n            float3 _2014 = (_1999 * 2.0f) - 1.0f.xxx;\n            float2 _2019 = _2014.xy * _1769.y;\n            float3 _2041 = (normalize(_1797) * _2019.x) + (normalize(_1804) * _2019.y);\n            float3 _2044 = normalize(normal);\n            normal = normalize(lerp(_2044, normalize((_2044 * max(_2014.z, 0.0500000007450580596923828125f)) + (_2041 - (_2044 * dot(_2044, _2041)))), clamp(_1872 * (_1925 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _6500;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_468_fa_cl_info.x) + int(_468_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_468_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4856;\n    if (fa_lm.z > 0.5f)\n    {\n        _4856 = 0.0f;\n    }\n    else\n    {\n        _4856 = 1.0f - clamp(_468_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4867 = _4856 < 1.0f;\n    bool _4873;\n    if (_4867)\n    {\n        int param = li;\n        _4873 = fa_light_baked(param);\n    }\n    else\n    {\n        _4873 = _4867;\n    }\n    return _4873 ? _4856 : 1.0f;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _646 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _659 = (c - (ru * hx)) - p;\n        float3 _665 = ru * (2.0f * hx);\n        float _671 = max(dot(_665, _665), 9.9999999392252902907785028219223e-09f);\n        float _675 = dot(_659, _665);\n        float t = clamp((-_675) / _671, 0.0f, 1.0f);\n        if (_646)\n        {\n            float _690 = dot(r, _665);\n            float _696 = _671 - (_690 * _690);\n            if (abs(_696) > (9.9999997473787516355514526367188e-06f * _671))\n            {\n                t = clamp(((dot(r, _659) * _690) - _675) / _696, 0.0f, 1.0f);\n            }\n        }\n        return (p + _659) + (_665 * t);\n    }\n    float3 q = p;\n    float _728 = dot(r, axis);\n    bool _736;\n    if (_646)\n    {\n        _736 = abs(_728) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _736 = _646;\n    }\n    if (_736)\n    {\n        float _746 = dot(c - p, axis) / _728;\n        if (_746 > 0.0f)\n        {\n            q = p + (r * _746);\n        }\n    }\n    float3 _759 = q - c;\n    float2 xy = float2(dot(_759, ru), dot(_759, uu));\n    if (shape > 0.5f)\n    {\n        float _774 = length(xy);\n        if (_774 > hx)\n        {\n            xy *= (hx / _774);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _527_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _527_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _566 = dot(d, right);\n    float _570 = dot(d, up);\n    float _581;\n    if (((_566 * _566) + (_570 * _570)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _581 = atan2(_570, _566) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _581 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_581 - floor(_581)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _415 = abs(d);\n    float _417 = _415.x;\n    float _419 = _415.y;\n    bool _420 = _417 >= _419;\n    bool _428;\n    if (_420)\n    {\n        _428 = _417 >= _415.z;\n    }\n    else\n    {\n        _428 = _420;\n    }\n    int _429;\n    if (_428)\n    {\n        _429 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _444;\n        if (_419 >= _415.z)\n        {\n            _444 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _444 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _429 = _444;\n    }\n    return _429;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _812 = fa_light_base(param);\n    bool _816 = _468_fa_ambient.w > 4.5f;\n    int param_1 = _812;\n    float4 _820 = fa_light_texel(param_1);\n    int param_2 = _812 + 1;\n    float4 _825 = fa_light_texel(param_2);\n    float _828 = _825.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _840 = _816 && (_828 > 2.5f);\n    fa_light_is_area = _840;\n    bool _842 = _828 < 0.5f;\n    float3 l;\n    if (_842)\n    {\n        l = normalize(_820.xyz);\n        if (_816)\n        {\n            int param_3 = _812 + 6;\n            float4 _856 = fa_light_texel(param_3);\n            if (_856.z > 0.5f)\n            {\n                int param_4 = _812 + 4;\n                float4 _866 = fa_light_texel(param_4);\n                int param_5 = _812 + 5;\n                float4 _871 = fa_light_texel(param_5);\n                float2 param_6 = _856.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _866.xyz) * _866.w, (-dot(world_pos, _871.xyz)) * _871.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _901 = _820.xyz;\n        float3 _903 = _901 - world_pos;\n        float3 to_light = _903;\n        float _906 = length(_903);\n        float reach = _906;\n        bool front = true;\n        if (_840)\n        {\n            int param_8 = _812 + 7;\n            reach = max(_906 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _812 + 4;\n            float4 _930 = fa_light_texel(param_9);\n            int param_10 = _812 + 5;\n            float4 _935 = fa_light_texel(param_10);\n            int param_11 = _812 + 6;\n            float4 _940 = fa_light_texel(param_11);\n            float _941 = _940.w;\n            int param_12 = _812 + 2;\n            float3 _948 = normalize(fa_light_texel(param_12).xyz);\n            bool _950 = _941 > 1.5f;\n            bool _958;\n            if (!_950)\n            {\n                _958 = dot(_948, to_light) < 0.0f;\n            }\n            else\n            {\n                _958 = _950;\n            }\n            front = _958;\n            float3 r = 0.0f.xxx;\n            float3 _967 = _468_fa_camera_pos.xyz - world_pos;\n            bool _971 = dot(n, n) > 0.5f;\n            bool _979;\n            if (_971)\n            {\n                _979 = dot(_967, _967) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _979 = _971;\n            }\n            if (_979)\n            {\n                r = reflect(-normalize(_967), normalize(n));\n            }\n            float3 param_13 = _901;\n            float3 param_14 = _948;\n            float3 param_15 = _930.xyz;\n            float3 param_16 = _935.xyz;\n            float param_17 = _930.w;\n            float param_18 = _935.w;\n            float param_19 = _941;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1015 = length(to_light);\n        dist = _1015;\n        l = to_light / max(_1015, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1029 = reach / max(_820.w, 0.001000000047497451305389404296875f);\n        float _1035 = clamp(1.0f - (_1029 * _1029), 0.0f, 1.0f);\n        float _1037;\n        if (front)\n        {\n            _1037 = _1035 * _1035;\n        }\n        else\n        {\n            _1037 = 0.0f;\n        }\n        atten = _1037;\n        bool _1048 = _828 < 2.5f;\n        if ((_828 > 1.5f) && _1048)\n        {\n            int param_22 = _812 + 2;\n            float4 _1056 = fa_light_texel(param_22);\n            float _1066 = _1056.w;\n            int param_23 = _812 + 3;\n            float4 _1071 = fa_light_texel(param_23);\n            float _1072 = _1071.x;\n            float cos_inner = _1072;\n            if (_1072 > 1.5f)\n            {\n                cos_inner = lerp(_1066, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1066, cos_inner, dot(-l, normalize(_1056.xyz)));\n        }\n        if (_816 && (_828 < 1.5f))\n        {\n            int param_24 = _812 + 6;\n            float4 _1096 = fa_light_texel(param_24);\n            if (_1096.z > 0.5f)\n            {\n                float3 _1104 = -to_light;\n                int param_25 = _812 + 4;\n                int param_26 = _812 + 5;\n                float3 _1118 = fa_light_texel(param_25).xyz;\n                float3 _1122 = fa_light_texel(param_26).xyz;\n                float3 _1131 = float3(dot(_1104, _1118), dot(_1104, _1122), dot(_1104, cross(_1118, _1122)));\n                float3 param_27 = _1131;\n                int _1135 = fa_cube_face(param_27);\n                int param_28 = _1135;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1162 = float2(dot(_1131, cross(param_29, param_30)), dot(_1131, param_30)) / max(dot(_1131, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1166 = _1135 / 3;\n                float2 param_31 = _1096.xy + (float2(float(_1135 - (_1166 * 3)), float(_1166)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1162.x), 0.5f - (0.5f * _1162.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _812 + 7;\n            float4 _1196 = fa_light_texel(param_33);\n            if (_1196.z > 0.5f)\n            {\n                int param_34 = _812 + 2;\n                int param_35 = _812 + 4;\n                int param_36 = _812 + 5;\n                float2 param_37 = _1196.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_816 && _1048)\n            {\n                int param_42 = _812 + 6;\n                float4 _1243 = fa_light_texel(param_42);\n                int param_43 = _812 + 7;\n                float4 _1248 = fa_light_texel(param_43);\n                bool _1251 = _1243.z > 0.5f;\n                bool _1258;\n                if (!_1251)\n                {\n                    _1258 = _1248.z > 0.5f;\n                }\n                else\n                {\n                    _1258 = _1251;\n                }\n                if (_1258)\n                {\n                    int param_44 = _812 + 2;\n                    float4 _1265 = fa_light_texel(param_44);\n                    float3 _1269 = normalize(_1265.xyz);\n                    int param_45 = _812 + 4;\n                    float4 _1274 = fa_light_texel(param_45);\n                    int param_46 = _812 + 5;\n                    float4 _1279 = fa_light_texel(param_46);\n                    if (_1251)\n                    {\n                        float3 _1287 = -to_light;\n                        float _1294 = _1265.w;\n                        float _1310 = 0.5f / max(dot(_1287, _1269) * (sqrt(max(1.0f - (_1294 * _1294), 0.0f)) / max(_1294, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1243.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1287, _1274.xyz) * _1310), 0.5f - (dot(_1287, _1279.xyz) * _1310));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1248.z > 0.5f)\n                    {\n                        float2 param_49 = _1248.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1269;\n                        float3 param_52 = _1274.xyz;\n                        float3 param_53 = _1279.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _6062 = _825.xyz * atten;\n    if (_816)\n    {\n        _6062 *= fa_light_tint;\n    }\n    int _1379;\n    if (_842)\n    {\n        _1379 = 0;\n    }\n    else\n    {\n        _1379 = ((_828 > 1.5f) && (_828 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _6073 = { l, _6062, atten, 1.0f, dist, _1379 };\n    return _6073;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _5085 = n < 0;\n    bool _5092;\n    if (!_5085)\n    {\n        _5092 = n >= fa_light_count();\n    }\n    else\n    {\n        _5092 = _5085;\n    }\n    if (_5092)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _5100 = fa_cl_light(param);\n    int param_1 = _5100;\n    float _5104 = fa_baked_keep(param_1);\n    if (_5104 <= 0.0f)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _5100;\n    float3 param_3 = i.world_pos;\n    float3 param_4 = i.world_normal;\n    LightSample _5120 = fa_light_sample_n(param_2, param_3, param_4);\n    LightSample _6244 = { _5120.direction, _5120.color * _5104, _5120.attenuation * _5104, _5120.shadow, _5120._distance, _5120.type };\n    return _6244;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2168 = fa_shadow_depth(param, param_1);\n    float _2172;\n    if (conv.x < 0.5f)\n    {\n        _2172 = _2168;\n    }\n    else\n    {\n        _2172 = (conv.y * conv.z) / (conv.z - (_2168 * (conv.z - conv.y)));\n    }\n    return _2172;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2218 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2224 = float2(cos(_2218), sin(_2218));\n    float2 dir = _2224;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2233;\n        if (k < 0.0f)\n        {\n            _2233 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2233 = k;\n        }\n        float _2252 = clamp((_2233 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2271 = sqrt((float(i) + 0.5f) * 0.0625f) * _2252;\n            float2 param_3 = uv + (dir * (_2121_fa_shadow_bias.zw * _2271));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2285 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2285 < (zr - (_2271 * plane)))\n            {\n                sum += _2285;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2313 = sum / cnt;\n        float _2323;\n        if (k < 0.0f)\n        {\n            _2323 = (-k) / max(_2313, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2323 = k;\n        }\n        radius = clamp(((max(zr - _2313, 0.0f) * unit) * _2323) / texel_m, 1.5f, 16.0f);\n        dir = _2224;\n    }\n    float lit = 0.0f;\n    int _2349 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2349; i_1++)\n    {\n        float _2368 = sqrt((float(i_1) + 0.5f) / float(_2349)) * radius;\n        float2 param_7 = uv + (dir * (_2121_fa_shadow_bias.zw * _2368));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2368 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2349);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2573 = _468_fa_pbr.z < 0.5f;\n    bool _2580;\n    if (!_2573)\n    {\n        _2580 = _2121_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2580 = _2573;\n    }\n    if (_2580)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2121_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2593 = fa_light_texel(param);\n    float _2594 = _2593.x;\n    if (_2594 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2603 = int(_2594 + 0.5f);\n    int param_1 = _2603;\n    float4 _2607 = fa_light_texel(param_1);\n    int param_2 = _2603 + 1;\n    float4 _2612 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2615 = _2607.y;\n    if (_2615 > 0.0f)\n    {\n        float _2632 = 1.0f - smoothstep(0.75f * _2615, _2615, length(world - _2121_fa_shadow_eye.xyz));\n        fade = _2632;\n        if (_2632 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2607.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2656 = (_2603 + 2) + (face * 6);\n    int param_4 = _2656;\n    int param_5 = _2656 + 1;\n    int param_6 = _2656 + 3;\n    float4 _2670 = fa_light_texel(param_6);\n    int param_7 = _2656 + 4;\n    float4 _2675 = fa_light_texel(param_7);\n    int param_8 = _2656 + 5;\n    float4 _2680 = fa_light_texel(param_8);\n    float _2692 = _2680.x * max(dot(_2670, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2697 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2720 = clamp(dot(n, _2670.xyz), -1.0f, 1.0f);\n    float _2739 = min(sqrt(1.0f - (_2720 * _2720)) / max(abs(dot(n, world - lpos)) / max(dot(_2670, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2742 = _2612.y;\n    float _2744;\n    if (_2742 > 0.0f)\n    {\n        _2744 = _2742;\n    }\n    else\n    {\n        _2744 = 1.5f * _2692;\n    }\n    float4 _2764 = float4(world + (n * (_2744 * sqrt(1.0f - (_2697 * _2697)))), 1.0f);\n    float _2768 = dot(_2670, _2764);\n    float _2771 = _2680.y;\n    if (_2768 < _2771)\n    {\n        return 1.0f;\n    }\n    float2 _2786 = float2(dot(fa_light_texel(param_4), _2764), dot(fa_light_texel(param_5), _2764)) / _2768.xx;\n    float _2788 = _2786.x;\n    bool _2791 = _2788 < _2675.x;\n    bool _2800;\n    if (!_2791)\n    {\n        _2800 = _2788 > _2675.z;\n    }\n    else\n    {\n        _2800 = _2791;\n    }\n    bool _2809;\n    if (!_2800)\n    {\n        _2809 = _2786.y < _2675.y;\n    }\n    else\n    {\n        _2809 = _2800;\n    }\n    bool _2818;\n    if (!_2809)\n    {\n        _2818 = _2786.y > _2675.w;\n    }\n    else\n    {\n        _2818 = _2809;\n    }\n    if (_2818)\n    {\n        return 1.0f;\n    }\n    float _2824 = _2612.x;\n    float _2826;\n    if (_2824 > 0.0f)\n    {\n        _2826 = _2824;\n    }\n    else\n    {\n        _2826 = 1.5f * _2692;\n    }\n    float2 param_9 = _2786;\n    float4 param_10 = _2675;\n    float param_11 = _2768 - (_2826 * (1.0f + (0.5f * _2739)));\n    float param_12 = _2692;\n    float param_13 = 1.0f;\n    float param_14 = _2680.z * 0.25f;\n    float param_15 = (_2692 * min(_2739, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2771, _2680.z);\n    int param_17 = int(_2607.z + 0.5f);\n    float param_18 = _2607.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2111;\n    if (i == 0)\n    {\n        _2111 = _2121_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2127;\n        if (i == 1)\n        {\n            _2127 = _2121_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2135;\n            if (i == 2)\n            {\n                _2135 = _2121_fa_shadow_split.z;\n            }\n            else\n            {\n                _2135 = _2121_fa_shadow_split.w;\n            }\n            _2127 = _2135;\n        }\n        _2111 = _2127;\n    }\n    return _2111;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2414 = max(_2121_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2419 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2425 = sqrt(1.0f - (_2419 * _2419));\n    float _2433 = min(_2425 / max(_2419, 0.20000000298023223876953125f), 4.0f);\n    float _2438;\n    if (_2121_fa_shadow_bias.y > 0.0f)\n    {\n        _2438 = _2121_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2438 = 1.5f * _2121_fa_shadow_info[ci].x;\n    }\n    float4 _2463 = mul(float4(world + (n * (_2438 * _2425)), 1.0f), _2121_fa_shadow_mat[ci]);\n    float _2470 = _2463.x;\n    bool _2473 = _2470 < _2121_fa_shadow_rect[ci].x;\n    bool _2482;\n    if (!_2473)\n    {\n        _2482 = _2470 > _2121_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2482 = _2473;\n    }\n    bool _2491;\n    if (!_2482)\n    {\n        _2491 = _2463.y < _2121_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2491 = _2482;\n    }\n    bool _2500;\n    if (!_2491)\n    {\n        _2500 = _2463.y > _2121_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2500 = _2491;\n    }\n    bool _2507;\n    if (!_2500)\n    {\n        _2507 = _2463.z > 1.0f;\n    }\n    else\n    {\n        _2507 = _2500;\n    }\n    if (_2507)\n    {\n        return -1.0f;\n    }\n    float _2515;\n    if (_2121_fa_shadow_bias.x > 0.0f)\n    {\n        _2515 = _2121_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2515 = 1.5f * _2121_fa_shadow_info[ci].x;\n    }\n    float2 param = _2463.xy;\n    float4 param_1 = _2121_fa_shadow_rect[ci];\n    float param_2 = _2463.z - ((_2515 * (1.0f + (0.5f * _2433))) / _2414);\n    float param_3 = _2121_fa_shadow_info[ci].x;\n    float param_4 = _2414;\n    float param_5 = _2414 * 0.25f;\n    float param_6 = ((_2121_fa_shadow_info[ci].x * min(_2433, 3.0f)) * 0.5f) / _2414;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2121_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2121_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_468_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2893 = int(_2121_fa_shadow_cfg.x + 0.5f);\n    if (_2893 < 1)\n    {\n        return 1.0f;\n    }\n    float _2908 = dot(world - _2121_fa_shadow_eye.xyz, _2121_fa_shadow_fwd.xyz);\n    int param = _2893 - 1;\n    if (_2908 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2920 = _2893 > 1;\n    bool _2927;\n    if (_2920)\n    {\n        _2927 = _2908 > _2121_fa_shadow_split.x;\n    }\n    else\n    {\n        _2927 = _2920;\n    }\n    if (_2927)\n    {\n        ci = 1;\n    }\n    bool _2931 = _2893 > 2;\n    bool _2938;\n    if (_2931)\n    {\n        _2938 = _2908 > _2121_fa_shadow_split.y;\n    }\n    else\n    {\n        _2938 = _2931;\n    }\n    if (_2938)\n    {\n        ci = 2;\n    }\n    bool _2942 = _2893 > 3;\n    bool _2949;\n    if (_2942)\n    {\n        _2949 = _2908 > _2121_fa_shadow_split.z;\n    }\n    else\n    {\n        _2949 = _2942;\n    }\n    if (_2949)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _2960 = min(_2893, 4);\n    float _3001;\n    for (int c = ci; c < _2960; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2980 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _2980;\n            break;\n        }\n        if (_2980 < 0.0f)\n        {\n            continue;\n        }\n        s = _2980;\n        ci = c;\n        if (_2121_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3001 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3001 = _2121_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _3020 = _2121_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3001, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_2908 - (fa_shadow_split_at(param_7) - _3020)) / _3020, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3052;\n        if ((ci + 1) < _2893)\n        {\n            _3052 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3052 = 1.0f;\n        }\n        s = lerp(s, _3052, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    bool _3157 = _468_fa_ct_b.y > 0.5f;\n    bool _3163;\n    if (_3157)\n    {\n        _3163 = _468_fa_pbr.z > 0.5f;\n    }\n    else\n    {\n        _3163 = _3157;\n    }\n    if (_3163)\n    {\n        float _3177 = dot(_468_fa_ct_fwd.xyz, fa_world_pos) + _468_fa_ct_fwd.w;\n        float _3180 = fwidth(_3177);\n        float4 _3190 = float4(fa_world_pos, 1.0f);\n        float _3196 = dot(_468_fa_ct_vpw, _3190);\n        if (_3196 > 9.9999997473787516355514526367188e-05f)\n        {\n            float2 _3215 = float2(dot(_468_fa_ct_vpx, _3190), dot(_468_fa_ct_vpy, _3190)) / _3196.xx;\n            float _3220 = (_3215.x * 0.5f) + 0.5f;\n            float _3224;\n            if (_468_fa_ct_a.y > 0.5f)\n            {\n                _3224 = (_3215.y * 0.5f) + 0.5f;\n            }\n            else\n            {\n                _3224 = 0.5f - (_3215.y * 0.5f);\n            }\n            bool _3240 = _3220 >= 0.0f;\n            bool _3246;\n            if (_3240)\n            {\n                _3246 = _3220 < 1.0f;\n            }\n            else\n            {\n                _3246 = _3240;\n            }\n            bool _3252;\n            if (_3246)\n            {\n                _3252 = _3224 >= 0.0f;\n            }\n            else\n            {\n                _3252 = _3246;\n            }\n            bool _3258;\n            if (_3252)\n            {\n                _3258 = _3224 < 1.0f;\n            }\n            else\n            {\n                _3258 = _3252;\n            }\n            if (_3258)\n            {\n                float4 _3284 = fa_screen_tex.Load(int3(clamp(int2(float2(_3220, _3224) * _468_fa_ct_a.zw), int2(0, 0), int2(_468_fa_ct_a.zw) - int2(1, 1)), 0));\n                bool _3287 = _3284.w > 0.5f;\n                bool _3303;\n                if (_3287)\n                {\n                    _3303 = abs(_3177 - _3284.x) <= (((0.00200000009499490261077880859375f * _3177) + 0.00999999977648258209228515625f) + min(1.5f * _3180, 0.100000001490116119384765625f * _3177));\n                }\n                else\n                {\n                    _3303 = _3287;\n                }\n                if (_3303)\n                {\n                    float _3309;\n                    if (_468_fa_ct_b.z > 0.5f)\n                    {\n                        float3 param = fa_world_pos;\n                        float3 param_1 = n;\n                        float3 param_2 = l;\n                        _3309 = min(_3284.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3309 = _3284.y;\n                    }\n                    return _3309;\n                }\n            }\n        }\n    }\n    float3 param_3 = fa_world_pos;\n    float3 param_4 = n;\n    float3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4600 = _468_fa_ct_a.x < 0.5f;\n    bool _4607;\n    if (!_4600)\n    {\n        _4607 = _2121_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4607 = _4600;\n    }\n    if (_4607)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2121_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4620 = fa_light_texel(param);\n    float _4621 = _4620.y;\n    float len = _4621;\n    if (_4621 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4633 = length(world - _468_fa_camera_pos.xyz);\n    float _4642 = 1.0f - smoothstep(0.5f * _468_fa_ct_b.x, _468_fa_ct_b.x, _4633);\n    if (_4642 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4648 = len;\n    float _4651 = min(_4648, 0.89999997615814208984375f * dist);\n    len = _4651;\n    float _4656 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4633);\n    float _4661 = _4656 + (0.5f * _4651);\n    float3 _4667 = world + (gn * _4656);\n    float _4669 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4730;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4684 = (float(k) + _4669) * 0.083333335816860198974609375f;\n        float3 _4692 = _4667 + (l * (_4684 * len));\n        float4 _4698 = float4(_4692, 1.0f);\n        float _4703 = dot(_468_fa_ct_vpw, _4698);\n        if (_4703 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4721 = float2(dot(_468_fa_ct_vpx, _4698), dot(_468_fa_ct_vpy, _4698)) / _4703.xx;\n        float _4725 = _4721.x * 0.5f;\n        float _4726 = _4725 + 0.5f;\n        if (_468_fa_ct_a.y > 0.5f)\n        {\n            _4730 = (_4721.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4730 = 0.5f - (_4721.y * 0.5f);\n        }\n        bool _4746 = _4726 < 0.0f;\n        bool _4753;\n        if (!_4746)\n        {\n            _4753 = _4726 >= 1.0f;\n        }\n        else\n        {\n            _4753 = _4746;\n        }\n        bool _4760;\n        if (!_4753)\n        {\n            _4760 = _4730 < 0.0f;\n        }\n        else\n        {\n            _4760 = _4753;\n        }\n        bool _4767;\n        if (!_4760)\n        {\n            _4767 = _4730 >= 1.0f;\n        }\n        else\n        {\n            _4767 = _4760;\n        }\n        if (_4767)\n        {\n            break;\n        }\n        float4 _4791 = fa_screen_tex.Load(int3(clamp(int2(float2(_4726, _4730) * _468_fa_ct_a.zw), int2(0, 0), int2(_468_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_4791.w < 0.5f)\n        {\n            continue;\n        }\n        float _4809 = (dot(_468_fa_ct_fwd.xyz, _4692) + _468_fa_ct_fwd.w) - _4791.x;\n        if ((_4809 > _4656) && (_4809 < _4661))\n        {\n            occ = max(occ, (1.0f - (_4684 * _4684)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4726, 0.5f - _4725), min(_4730, 1.0f - _4730))));\n        }\n    }\n    return 1.0f - (occ * _4642);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4912 = fa_baked_keep(param);\n    if (_4912 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _6206 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6206;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4938 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6208 = _4938.color;\n    float _6209 = _4938.attenuation;\n    float _6210 = _4938.shadow;\n    bool _4941 = _4938.type == 0;\n    if (_4941 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4938.direction;\n        float _4952 = fa_shadow_factor(param_5, param_6);\n        _6210 = _4952;\n        _6208 *= _4952;\n    }\n    else\n    {\n        bool _4963 = _4938.type != 0;\n        bool _4969;\n        if (_4963)\n        {\n            _4969 = _6209 > 0.0f;\n        }\n        else\n        {\n            _4969 = _4963;\n        }\n        if (_4969)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4938.direction;\n            float _4988 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6210 = _4988;\n            _6208 *= _4988;\n        }\n    }\n    bool _4998 = _468_fa_ct_a.x > 0.5f;\n    bool _5004;\n    if (_4998)\n    {\n        _5004 = _6209 > 0.0f;\n    }\n    else\n    {\n        _5004 = _4998;\n    }\n    if (_5004)\n    {\n        float _5011;\n        if (_4941)\n        {\n            _5011 = 1000000000.0f;\n        }\n        else\n        {\n            _5011 = _4938._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4938.direction;\n        float param_18 = _5011;\n        float _5029 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6210 *= _5029;\n        _6208 *= _5029;\n    }\n    float _5042 = _6209;\n    float _5043 = _5042 * _4912;\n    _6209 = _5043;\n    float3 _5047 = _6208;\n    float3 _5048 = _5047 * _4912;\n    _6208 = _5048;\n    LightSample _6225 = { _4938.direction, _5048, _5043, _6210, _4938._distance, _4938.type };\n    return _6225;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _5059 = n < 0;\n    bool _5066;\n    if (!_5059)\n    {\n        _5066 = n >= fa_light_count();\n    }\n    else\n    {\n        _5066 = _5059;\n    }\n    if (_5066)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    LightSample _5081 = fa_light_shadowed(param_1, param_2, param_3);\n    return _5081;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3985 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3993 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3996 = int(_3985);\n    int _3999 = int(_3993);\n    float _4009 = _3993 - float(_3999);\n    int _4065 = (_3996 * 9) + _3999;\n    int _4085 = ((_3996 + 1) * 9) + _3999;\n    return lerp(lerp(_4060[_4065], _4060[_4065 + 1], _4009), lerp(_4060[_4085], _4060[_4085 + 1], _4009), _3985 - float(_3996));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _6074 = false;\n    float _6075 = 1.0f;\n    float _6076 = 1.0f;\n    float _6077 = 1.0f;\n    float _6078 = 0.0f;\n    float _6079 = 0.0f;\n    float _6080 = 0.0f;\n    float _6081 = 0.0f;\n    float _6083 = 1.0f;\n    bool _6084 = false;\n    float3 _6085 = 0.0f.xxx;\n    float _6086 = 1.0f;\n    float _6087 = 1.0f;\n    float _6088 = 1.0f;\n    float _6089 = 0.0f;\n    float _6090 = 0.0f;\n    float3 _6091 = float3(1.0f, 0.0f, 0.0f);\n    float3 _6092 = float3(0.0f, 0.0f, 1.0f);\n    float _6093 = 1.0f;\n    float _6094 = 1.0f;\n    float _4136 = clamp(s.specular, 0.0f, 1.0f);\n    float _4140 = clamp(s.ior, 1.0f, 3.0f);\n    bool _4145 = (_4136 != 1.0f) || (_4140 != 1.5f);\n    bool _4154;\n    if (!_4145)\n    {\n        _4154 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _4154 = _4145;\n    }\n    if (_4154)\n    {\n        float _4162 = (_4140 - 1.0f) / (_4140 + 1.0f);\n        f0 = lerp(min((_4162 * _4162).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _4136, s.albedo, metallic.xxx);\n        _6075 = lerp(_4136, 1.0f, metallic);\n        _6074 = true;\n    }\n    float _4189 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4189 > 0.0f)\n    {\n        float _4197 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _6078 = _4189;\n        _6079 = _4197;\n        float _4204 = _4197 * _4197;\n        _6080 = _4204;\n        _6081 = _4204 * _4204;\n        float _4216 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _6083 = _4216;\n        _6076 = 1.0f - (_4189 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _4216, 0.0f, 1.0f), 5.0f))));\n        _6074 = true;\n    }\n    float3 _4235 = max(s.sheen_color, 0.0f.xxx);\n    float _4244 = max(_4235.x, max(_4235.y, _4235.z));\n    if (_4244 > 0.0f)\n    {\n        float _4252 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _6084 = true;\n        _6085 = _4235;\n        _6086 = _4252;\n        _6087 = _4252 * _4252;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _4252;\n        float _4269 = fa_sheen_albedo(param, param_1);\n        _6089 = _4269;\n        _6088 = 1.0f - min(_4244 * _4269, 1.0f);\n        _6074 = true;\n    }\n    _6077 = _6076 * _6088;\n    float _4288 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_4288 != 0.0f)\n    {\n        float3 _4303 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _4303;\n        if (dot(_4303, _4303) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _4315 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_4315.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _4315.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _4315.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _4319 = t;\n        float3 _4320 = normalize(_4319);\n        t = _4320;\n        float3 _4345 = normalize((_4320 * cos(s.anisotropy_rotation)) + ((cross(n, _4320) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _6091 = _4345;\n        _6092 = cross(n, _4345);\n        float _4355 = roughness * roughness;\n        float _4361 = lerp(_4355, 1.0f, _4288 * _4288);\n        bool _4363 = _4288 > 0.0f;\n        _6093 = _4363 ? _4361 : _4355;\n        _6094 = _4363 ? _4355 : _4361;\n        _6090 = _4288;\n        _6074 = true;\n    }\n    FaLayers _6116 = { _6074, _6075, _6076, _6077, _6078, _6079, _6080, _6081, i.world_normal, _6083, _6084, _6085, _6086, _6087, _6088, _6089, _6090, _6091, _6092, _6093, _6094 };\n    return _6116;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3917 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3920 = _3917.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3920 * _3920, exp2((-9.27999973297119140625f) * ndv)) * _3920) + _3917.y)) + _3917.zw;\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3353 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3356 = _3353.x;\n    float _3358 = _3353.z;\n    float2 e = float2(_3356, _3358);\n    if (_3353.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3358)) * ((_3356 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3356)) * ((_3358 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3392_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3392_dummy_parameter)));\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _3405;\n    if (lv == 0)\n    {\n        _3405 = 0.0f;\n    }\n    else\n    {\n        _3405 = res + 2.0f;\n    }\n    float _3415;\n    if (lv == 0)\n    {\n        _3415 = 0.0f;\n    }\n    else\n    {\n        _3415 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_3405, _3415)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _3461;\n    if (res > 64.5f)\n    {\n        _3461 = 5.0f;\n    }\n    else\n    {\n        _3461 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _3476 = clamp(rough, 0.0f, 1.0f) * (_3461 - 1.0f);\n    int _3483 = int(min(floor(_3476), _3461 - 2.0f));\n    float _3488 = _3476 - float(_3483);\n    float3 param = d;\n    float2 _3492 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3483;\n    float2 param_4 = _3492;\n    float3 _3502 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3488 < 0.00200000009499490261077880859375f)\n    {\n        return _3502;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3483 + 1;\n    float2 param_8 = _3492;\n    return lerp(_3502, fa_probe_level(param_5, param_6, param_7, param_8), _3488.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _3539 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3546 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3553 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3559 = dot(bx.xyz, d);\n    float _3563 = dot(by.xyz, d);\n    float _3567 = dot(bz.xyz, d);\n    float _3573;\n    if (_3559 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3573 = (1.0f - _3539) / _3559;\n    }\n    else\n    {\n        float _3587;\n        if (_3559 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3587 = ((-1.0f) - _3539) / _3559;\n        }\n        else\n        {\n            _3587 = 1000000015047466219876688855040.0f;\n        }\n        _3573 = _3587;\n    }\n    float tx = _3573;\n    float _3604;\n    if (_3563 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3604 = (1.0f - _3546) / _3563;\n    }\n    else\n    {\n        float _3617;\n        if (_3563 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3617 = ((-1.0f) - _3546) / _3563;\n        }\n        else\n        {\n            _3617 = 1000000015047466219876688855040.0f;\n        }\n        _3604 = _3617;\n    }\n    float ty = _3604;\n    float _3633;\n    if (_3567 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3633 = (1.0f - _3553) / _3567;\n    }\n    else\n    {\n        float _3646;\n        if (_3567 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3646 = ((-1.0f) - _3553) / _3567;\n        }\n        else\n        {\n            _3646 = 1000000015047466219876688855040.0f;\n        }\n        _3633 = _3646;\n    }\n    float _3658 = tx;\n    float _3661 = (_3658 > 0.0f) ? _3658 : 1000000015047466219876688855040.0f;\n    tx = _3661;\n    float _3662 = ty;\n    float _3665 = (_3662 > 0.0f) ? _3662 : 1000000015047466219876688855040.0f;\n    ty = _3665;\n    float _3675 = min(_3661, min(_3665, (_3633 > 0.0f) ? _3633 : 1000000015047466219876688855040.0f));\n    if (_3675 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _3691 = (fa_world_pos + (d * _3675)) - posw.xyz;\n    float3 _3696;\n    if (dot(_3691, _3691) > 1.0000000133514319600180897396058e-10f)\n    {\n        _3696 = normalize(_3691);\n    }\n    else\n    {\n        _3696 = d;\n    }\n    return _3696;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _3742 = (1.0f - _468_fa_rpa_tile.w) - _468_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_3742 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_468_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _468_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3772 = rough * rough;\n            float _3803 = 0.60000002384185791015625f * _3772;\n            base = lerp(lerp(_468_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_468_fa_env_horizon.xyz, _468_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3772)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3803, 0.0500000007450580596923828125f + _3803, d.y).xxx), ((_468_fa_env_sky.xyz + _468_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3772 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _3742;\n    }\n    if (_468_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _468_fa_rpa_tile;\n        float4 param_5 = _468_fa_rpa_pos;\n        float4 param_6 = _468_fa_rpa_bx;\n        float4 param_7 = _468_fa_rpa_by;\n        float4 param_8 = _468_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _3862 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3862 * _468_fa_rpa_tile.w);\n    }\n    if (_468_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _468_fa_rpb_tile;\n        float4 param_12 = _468_fa_rpb_pos;\n        float4 param_13 = _468_fa_rpb_bx;\n        float4 param_14 = _468_fa_rpb_by;\n        float4 param_15 = _468_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _3894 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3894 * _468_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness, float occlusion)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4396;\n        if (L.aniso >= 0.0f)\n        {\n            _4396 = L.b;\n        }\n        else\n        {\n            _4396 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4396, v), _4396), (abs(L.aniso) * smoothstep(0.0f, 0.25f, roughness)).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4432 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4432.x) + (L.f90.xxx * _4432.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4490 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4490.x) + _4490.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3959 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3959.x) + _3959.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4529 = clamp(s.metallic, 0.0f, 1.0f);\n    float _4533 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _4540 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _4529.xxx);\n    float3 f0 = _4540;\n    float3 _4544 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _4544;\n    float3 param_3 = i.view_dir;\n    float param_4 = _4529;\n    float param_5 = _4533;\n    float3 param_6 = _4540;\n    FaLayers _4561 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4561.on)\n    {\n        FaLayers param_7 = _4561;\n        float3 param_8 = _4544;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _4533;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    float3 param_13 = _4544;\n    float3 param_14 = i.view_dir;\n    float3 param_15 = f0;\n    float param_16 = _4533;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _5151 = fa_light_unshadowed(param, param_1);\n        float _5159 = dot(_5151.color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_5159 > bestPower)\n        {\n            bestPower = _5159;\n            best = n;\n        }\n    }\n    float3 lit = (_468_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _5188 = fa_light(param_2, param_3);\n        float _5196;\n        if (dot(s.normal, _5188.direction) > 0.5f)\n        {\n            _5196 = 1.0f;\n        }\n        else\n        {\n            _5196 = _5202_dark;\n        }\n        lit += ((s.albedo * _5188.color) * _5196);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _5202_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2121_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3080 = int(_2121_fa_shadow_cfg.x + 0.5f);\n    float _3090 = dot(world - _2121_fa_shadow_eye.xyz, _2121_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3095 = _3080 > 0;\n    bool _3104;\n    if (_3095)\n    {\n        int param = _3080 - 1;\n        _3104 = _3090 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3104 = _3095;\n    }\n    if (_3104)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3110 = _3080 > 1;\n        bool _3117;\n        if (_3110)\n        {\n            _3117 = _3090 > _2121_fa_shadow_split.x;\n        }\n        else\n        {\n            _3117 = _3110;\n        }\n        if (_3117)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3123 = _3080 > 2;\n        bool _3130;\n        if (_3123)\n        {\n            _3130 = _3090 > _2121_fa_shadow_split.y;\n        }\n        else\n        {\n            _3130 = _3123;\n        }\n        if (_3130)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3136 = _3080 > 3;\n        bool _3143;\n        if (_3136)\n        {\n            _3143 = _3090 > _2121_fa_shadow_split.z;\n        }\n        else\n        {\n            _3143 = _3136;\n        }\n        if (_3143)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5928 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5928 = -_5928;\n    }\n    float3 _5598 = normalize(_468_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5941 = { fa_world_pos, _5928, fa_world_tangent, fa_uv, fa_vertex_color, _5598, gl_FrontFacing };\n    SurfaceInput param_1 = _5941;\n    Surface _5606 = fa_standard_surface(param_1);\n    float3 _5959 = _5606.albedo;\n    float _5960 = _5606.alpha;\n    float3 _5961 = _5606.normal;\n    float _5962 = _5606.metallic;\n    float _5963 = _5606.roughness;\n    float _5964 = _5606.occlusion;\n    float3 _5965 = _5606.emission;\n    float _5966 = _5606.clearcoat;\n    float _5967 = _5606.clearcoat_roughness;\n    float3 _5968 = _5606.sheen_color;\n    float _5969 = _5606.sheen_roughness;\n    float _5970 = _5606.anisotropy;\n    float _5971 = _5606.anisotropy_rotation;\n    float _5972 = _5606.specular;\n    float _5973 = _5606.ior;\n    float3 _5974 = _5606.specular_color;\n    float _5975 = _5606.transmission;\n    float _5976 = _5606.thickness;\n    float3 _5977 = _5606.attenuation_color;\n    float _5978 = _5606.attenuation_distance;\n    SurfaceInput _5949 = { fa_world_pos, _5928, fa_world_tangent, fa_uv, fa_vertex_color, _5598, gl_FrontFacing };\n    SurfaceInput param_2 = _5949;\n    Surface param_3 = _5606;\n    surface(param_2, param_3);\n    _5959 = param_3.albedo;\n    _5960 = param_3.alpha;\n    _5961 = param_3.normal;\n    _5962 = param_3.metallic;\n    _5963 = param_3.roughness;\n    _5964 = param_3.occlusion;\n    _5965 = param_3.emission;\n    _5966 = param_3.clearcoat;\n    _5967 = param_3.clearcoat_roughness;\n    _5968 = param_3.sheen_color;\n    _5969 = param_3.sheen_roughness;\n    _5970 = param_3.anisotropy;\n    _5971 = param_3.anisotropy_rotation;\n    _5972 = param_3.specular;\n    _5973 = param_3.ior;\n    _5974 = param_3.specular_color;\n    _5975 = param_3.transmission;\n    _5976 = param_3.thickness;\n    _5977 = param_3.attenuation_color;\n    _5978 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5928;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5959 = param_6;\n    _5961 = param_7;\n    float3 result;\n    if (_468_fa_emissive.w > 0.5f)\n    {\n        result = _5959;\n    }\n    else\n    {\n        float3 _5645 = _5961;\n        float3 _5646 = normalize(_5645);\n        _5961 = _5646;\n        SurfaceInput _5957 = { fa_world_pos, _5928, fa_world_tangent, fa_uv, fa_vertex_color, _5598, gl_FrontFacing };\n        SurfaceInput param_8 = _5957;\n        Surface _6060 = { _5959, _5960, _5646, _5962, _5963, _5964, _5965, _5966, _5967, _5968, _5969, _5970, _5971, _5972, _5973, _5974, _5975, _5976, _5977, _5978 };\n        Surface param_9 = _6060;\n        float3 _5657 = lighting(param_8, param_9);\n        result = _5657;\n    }\n    float3 _5661 = result;\n    float3 _5662 = _5661 + _5965;\n    result = _5662;\n    float3 param_10 = _5662;\n    float3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _5671 = _468_fa_fog.w > 0.0f;\n    bool _5678;\n    if (!_5671)\n    {\n        _5678 = _468_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5678 = _5671;\n    }\n    if (_5678)\n    {\n        float3 _5687 = fa_world_pos - _468_fa_camera_pos.xyz;\n        float _5693 = dot(_5687, _468_fa_fog_c.xyz);\n        bool _5697 = _468_fa_fog_c.w > 0.5f;\n        float _5698;\n        if (_5697)\n        {\n            _5698 = _5693;\n        }\n        else\n        {\n            _5698 = length(_5687);\n        }\n        float _5710 = _5698 - _468_fa_fog_b.x;\n        if (_5710 > 0.0f)\n        {\n            float _5719 = _468_fa_fog.w * _5710;\n            float tau = _5719 * _5719;\n            if (_468_fa_fog_b.y > 0.0f)\n            {\n                float _5735;\n                if (_5697)\n                {\n                    _5735 = fa_world_pos.y - (_468_fa_fog_c.y * _5693);\n                }\n                else\n                {\n                    _5735 = _468_fa_camera_pos.y;\n                }\n                float _5756 = lerp(_5735, fa_world_pos.y, clamp(_468_fa_fog_b.x / _5698, 0.0f, 1.0f));\n                float _5760 = fa_world_pos.y - _5756;\n                float _5765 = _5756 - _468_fa_fog_b.z;\n                float _5770 = fa_world_pos.y - _468_fa_fog_b.z;\n                bool _5773 = _5765 <= 0.0f;\n                bool _5774 = !_5773;\n                bool _5780;\n                if (_5774)\n                {\n                    _5780 = _468_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5780 = _5773;\n                }\n                float _5781;\n                if (_5780)\n                {\n                    _5781 = _468_fa_fog_b.y;\n                }\n                else\n                {\n                    _5781 = _468_fa_fog_b.y * exp(-min(_468_fa_fog_b.w * _5765, 80.0f));\n                }\n                bool _5808;\n                if (_5774)\n                {\n                    _5808 = _468_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5808 = _5773;\n                }\n                float _5809;\n                if (_5808)\n                {\n                    _5809 = _468_fa_fog_b.y * _5765;\n                }\n                else\n                {\n                    _5809 = (_468_fa_fog_b.y * (1.0f - exp(-min(_468_fa_fog_b.w * _5765, 80.0f)))) / _468_fa_fog_b.w;\n                }\n                bool _5834 = _5770 <= 0.0f;\n                bool _5841;\n                if (!_5834)\n                {\n                    _5841 = _468_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5841 = _5834;\n                }\n                float _5842;\n                if (_5841)\n                {\n                    _5842 = _468_fa_fog_b.y * _5770;\n                }\n                else\n                {\n                    _5842 = (_468_fa_fog_b.y * (1.0f - exp(-min(_468_fa_fog_b.w * _5770, 80.0f)))) / _468_fa_fog_b.w;\n                }\n                float _5869;\n                if (abs(_5760) < 0.001000000047497451305389404296875f)\n                {\n                    _5869 = _5781;\n                }\n                else\n                {\n                    _5869 = (_5842 - _5809) / _5760;\n                }\n                tau += (_5710 * max(_5869, 0.0f));\n            }\n            result = lerp(result, _468_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5960);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_468",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2121",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_5202",
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
