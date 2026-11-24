{
  "format": "factoria.shader/1",
  "engine": "0.35.2",
  "template": "0a04a5afef1ce53f95928caf6e8228a1e115e768384a8aa99d9ce155633dd5a3",
  "slang": "hlsl5",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _263 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _263;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_270, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3890[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _6327 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _468_fa_camera_pos : packoffset(c0);\n    float4 _468_fa_ambient : packoffset(c1);\n    float4 _468_fa_base_color : packoffset(c2);\n    float4 _468_fa_emissive : packoffset(c3);\n    float4 _468_fa_model_emissive : packoffset(c4);\n    float4 _468_fa_pbr : packoffset(c5);\n    float4 _468_fa_maps : packoffset(c6);\n    float4 _468_fa_fog : packoffset(c7);\n    float4 _468_fa_fog_b : packoffset(c8);\n    float4 _468_fa_fog_c : packoffset(c9);\n    float4 _468_fa_counts : packoffset(c10);\n    float4 _468_fa_env_sky : packoffset(c11);\n    float4 _468_fa_env_horizon : packoffset(c12);\n    float4 _468_fa_time : packoffset(c13);\n    float4 _468_fa_cl_vpx : packoffset(c14);\n    float4 _468_fa_cl_vpy : packoffset(c15);\n    float4 _468_fa_cl_vpw : packoffset(c16);\n    float4 _468_fa_cl_fwd : packoffset(c17);\n    float4 _468_fa_cl_grid : packoffset(c18);\n    float4 _468_fa_cl_info : packoffset(c19);\n    float4 _468_fa_layers_a : packoffset(c20);\n    float4 _468_fa_layers_b : packoffset(c21);\n    float4 _468_fa_layers_c : packoffset(c22);\n    float4 _468_fa_layers_d : packoffset(c23);\n    float4 _468_fa_ct_a : packoffset(c24);\n    float4 _468_fa_ct_b : packoffset(c25);\n    float4 _468_fa_ct_vpx : packoffset(c26);\n    float4 _468_fa_ct_vpy : packoffset(c27);\n    float4 _468_fa_ct_vpw : packoffset(c28);\n    float4 _468_fa_ct_fwd : packoffset(c29);\n    float4 _468_fa_tr_a : packoffset(c30);\n    float4 _468_fa_tr_b : packoffset(c31);\n    float4 _468_fa_probe_sh[9] : packoffset(c32);\n    float4 _468_fa_atlas : packoffset(c41);\n    float4 _468_fa_rpa_tile : packoffset(c42);\n    float4 _468_fa_rpa_pos : packoffset(c43);\n    float4 _468_fa_rpa_bx : packoffset(c44);\n    float4 _468_fa_rpa_by : packoffset(c45);\n    float4 _468_fa_rpa_bz : packoffset(c46);\n    float4 _468_fa_rpb_tile : packoffset(c47);\n    float4 _468_fa_rpb_pos : packoffset(c48);\n    float4 _468_fa_rpb_bx : packoffset(c49);\n    float4 _468_fa_rpb_by : packoffset(c50);\n    float4 _468_fa_rpb_bz : packoffset(c51);\n    float4 _468_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2121_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2121_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2121_fa_shadow_info[4] : packoffset(c20);\n    float4 _2121_fa_shadow_split : packoffset(c24);\n    float4 _2121_fa_shadow_cfg : packoffset(c25);\n    float4 _2121_fa_shadow_bias : packoffset(c26);\n    float4 _2121_fa_shadow_eye : packoffset(c27);\n    float4 _2121_fa_shadow_fwd : packoffset(c28);\n    float4 _2121_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _5040_dark : packoffset(c0);\n    float _5040_fa_pad0 : packoffset(c0.y);\n    float _5040_fa_pad1 : packoffset(c0.z);\n    float _5040_fa_pad2 : packoffset(c0.w);\n    float _5040_skyAmount : packoffset(c1);\n    float _5040_fa_pad3 : packoffset(c1.y);\n    float _5040_fa_pad4 : packoffset(c1.z);\n    float _5040_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t9);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_screen_tex : register(t10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1397 = _468_fa_cl_info.x < 0.0f;\n    bool _1404;\n    if (!_1397)\n    {\n        _1404 = _468_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1404 = _1397;\n    }\n    bool _1412;\n    if (!_1404)\n    {\n        _1412 = _468_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1412 = _1404;\n    }\n    bool _1419;\n    if (!_1412)\n    {\n        _1419 = _468_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1419 = _1412;\n    }\n    bool _1426;\n    if (!_1419)\n    {\n        _1426 = _468_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1426 = _1419;\n    }\n    if (_1426)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1436 = float4(world_pos, 1.0f);\n    float _1442 = dot(_468_fa_cl_vpw, _1436);\n    if (!(_1442 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1464 = float2(dot(_468_fa_cl_vpx, _1436), dot(_468_fa_cl_vpy, _1436)) / _1442.xx;\n    int _1468 = int(_468_fa_cl_grid.x);\n    int _1472 = int(_468_fa_cl_grid.y);\n    int param = (int(_468_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_468_fa_cl_fwd.xyz, world_pos) + _468_fa_cl_fwd.w, _468_fa_cl_grid.w) / _468_fa_cl_grid.w) * _468_fa_cl_grid.z)), 0, int(_468_fa_cl_info.y) - 1) * _1472) + clamp(int(floor(((_1464.y * 0.5f) + 0.5f) * _468_fa_cl_grid.y)), 0, _1472 - 1)) * _1468)) + clamp(int(floor(((_1464.x * 0.5f) + 0.5f) * _468_fa_cl_grid.x)), 0, _1468 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1548 = fa_cluster_texel(param);\n    return int2(int(_1548.x), int(_1548.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_468_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4724 = fa_cluster_lookup(param);\n    fa_cl_slot = _4724.x;\n    fa_cl_local = _4724.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5101 = fa_linear_to_srgb(param);\n        c = _5101;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5109 = fa_srgb_to_linear(param_1);\n            c = _5109;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _348;\n    if (i.front_facing)\n    {\n        _348 = i.world_normal;\n    }\n    else\n    {\n        _348 = -i.world_normal;\n    }\n    float3 _372 = normalize(i.world_tangent.xyz - (_348 * dot(_348, i.world_tangent.xyz)));\n    float3 _400 = normalize(((_372 * m.x) + ((cross(_348, _372) * i.world_tangent.w) * m.y)) + (_348 * m.z));\n    float3 _403;\n    if (i.front_facing)\n    {\n        _403 = _400;\n    }\n    else\n    {\n        _403 = -_400;\n    }\n    return _403;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _468_fa_env_horizon.w);\n    float param = _468_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5142 = fa_tex_fix(param_2, param_3);\n    float4 _6289 = base_t;\n    _6289.x = _5142.x;\n    _6289.y = _5142.y;\n    _6289.z = _5142.z;\n    base_t = _6289;\n    float4 _5156 = (_6289 * _468_fa_base_color) * i.vertex_color;\n    float3 _6095 = i.world_normal;\n    if (_468_fa_maps.z > 0.5f)\n    {\n        float param_4 = _468_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _468_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5190 = fa_tex_fix(param_6, param_7);\n        float3 _5193 = (_5190 * 2.0f) - 1.0f.xxx;\n        float2 _5198 = _5193.xy * _468_fa_maps.x;\n        float3 _6297 = _5193;\n        _6297.x = _5198.x;\n        _6297.y = _5198.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6297;\n        _6095 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _468_fa_env_horizon.w);\n    float param_10 = _468_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _5228 = fa_tex_fix(param_12, param_13);\n    float4 _6300 = mrt;\n    _6300.x = _5228.x;\n    _6300.y = _5228.y;\n    _6300.z = _5228.z;\n    mrt = _6300;\n    float4 _5258 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _468_fa_env_horizon.w);\n    float param_14 = _468_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _5258.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _5269 = fa_tex_fix(param_16, param_17);\n    float param_18 = _468_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _468_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _5301 = fa_tex_fix(param_20, param_21);\n    float _6100 = _468_fa_layers_a.x;\n    float _6101 = _468_fa_layers_a.y;\n    float _6104 = _468_fa_layers_a.z;\n    float _6103 = _468_fa_layers_b.w;\n    float _6106 = _468_fa_layers_c.x;\n    if (_468_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_468_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6100 *= _5269.y;\n            _6101 *= _5269.z;\n            _6103 *= _5258.w;\n        }\n        if (_468_fa_layers_c.z > 1.5f)\n        {\n            _6104 *= mrt.x;\n            _6106 *= mrt.w;\n        }\n    }\n    Surface _6133 = { _5156.xyz, _5156.w, _6095, clamp(_468_fa_pbr.x * _5228.z, 0.0f, 1.0f), clamp(_468_fa_pbr.y * _5228.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_468_fa_maps.y * (_5269.x - 1.0f)), _468_fa_emissive.xyz + (_468_fa_model_emissive.xyz * _5301), _6100, _6101, _468_fa_layers_b.xyz, _6103, _6104, _468_fa_layers_a.w, _6106, _468_fa_layers_c.y, _468_fa_layers_d.xyz, _468_fa_tr_a.x, _468_fa_tr_a.y, _468_fa_tr_b.xyz, _468_fa_tr_a.z };\n    return _6133;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1628 = rect.zw - rect.xy;\n    float2 _1632 = _1628 * atlas;\n    float2 _1636 = ddx * _1632;\n    float2 _1640 = ddy * _1632;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1628), clamp(0.5f * log2(max(max(dot(_1636, _1636), dot(_1640, _1640)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1673 = _468_fa_counts.y < 0.5f;\n    bool _1680;\n    if (!_1673)\n    {\n        _1680 = _468_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1680 = _1673;\n    }\n    if (_1680)\n    {\n        return;\n    }\n    float3 _1686 = ddx(world_pos);\n    float3 _1689 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1693 = fa_cluster_texel(param);\n    int _1697 = int(_1693.w);\n    if (_1697 < 1)\n    {\n        return;\n    }\n    int _1707 = int(_468_fa_counts.y + 0.5f);\n    int param_1 = _1707;\n    float4 _1711 = fa_light_texel(param_1);\n    float2 _1714 = _1711.yz;\n    int _1718 = int(_1711.w);\n    int param_2 = _1707 + 1;\n    float4 _1723 = fa_light_texel(param_2);\n    float _1724 = _1723.x;\n    int _1730 = int(_468_fa_counts.w + 0.5f) - 1;\n    int _1734 = int(_1693.z);\n    float3 _1999;\n    for (int k = 0; k < _1697; k++)\n    {\n        int _1747 = _1734 + k;\n        int param_3 = _1718 + (_1747 >> 2);\n        int _1764 = (_1707 + 2) + (int(fa_light_texel(param_3)[_1747 & 3]) * 7);\n        int param_4 = _1764 + 6;\n        float4 _1769 = fa_light_texel(param_4);\n        if (((int(_1769.w + 0.5f) >> _1730) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1764;\n        float4 _1784 = fa_light_texel(param_5);\n        int param_6 = _1764 + 1;\n        float4 _1789 = fa_light_texel(param_6);\n        int param_7 = _1764 + 2;\n        float4 _1794 = fa_light_texel(param_7);\n        float3 _1797 = _1784.xyz;\n        float _1802 = dot(_1797, world_pos) + _1784.w;\n        float3 _1804 = _1789.xyz;\n        float _1809 = dot(_1804, world_pos) + _1789.w;\n        float3 _1811 = _1794.xyz;\n        float _1816 = dot(_1811, world_pos) + _1794.w;\n        bool _1821 = abs(_1802) > 0.5f;\n        bool _1829;\n        if (!_1821)\n        {\n            _1829 = abs(_1809) > 0.5f;\n        }\n        else\n        {\n            _1829 = _1821;\n        }\n        bool _1837;\n        if (!_1829)\n        {\n            _1837 = abs(_1816) > 0.5f;\n        }\n        else\n        {\n            _1837 = _1829;\n        }\n        if (_1837)\n        {\n            continue;\n        }\n        float _1852 = clamp(dot(geo_normal, normalize(_1811)) * _1769.z, 0.0f, 1.0f);\n        if (_1852 <= 0.0f)\n        {\n            continue;\n        }\n        float _1872 = (clamp((0.5f - abs(_1816)) * 10.0f, 0.0f, 1.0f) * _1852) * _1769.x;\n        float2 _1880 = float2(_1802 + 0.5f, 0.5f - _1809);\n        float2 _1890 = float2(dot(_1797, _1686), dot(_1804, _1686));\n        float2 _1900 = float2(dot(_1797, _1689), dot(_1804, _1689));\n        int param_8 = _1764 + 5;\n        float4 _1905 = fa_light_texel(param_8);\n        int param_9 = _1764 + 3;\n        float4 _1910 = fa_light_texel(param_9);\n        int param_10 = _1764 + 4;\n        float4 _1915 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1905.xyz;\n        bool _1925 = _1910.z > _1910.x;\n        if (_1925)\n        {\n            float4 param_11 = _1910;\n            float2 param_12 = _1880;\n            float2 param_13 = _1714;\n            float2 param_14 = _1890;\n            float2 param_15 = _1900;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1724 > 0.5f) && (_1724 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1951 = fa_dc_to_linear(param_16);\n                float4 _6183 = tx;\n                _6183.x = _1951.x;\n                _6183.y = _1951.y;\n                _6183.z = _1951.z;\n                tx = _6183;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1872 * tex_a) * _1905.w, 0.0f, 1.0f).xxx);\n        if (_1915.z > _1915.x)\n        {\n            float4 param_17 = _1915;\n            float2 param_18 = _1880;\n            float2 param_19 = _1714;\n            float2 param_20 = _1890;\n            float2 param_21 = _1900;\n            float4 _1995 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1724 > 1.5f)\n            {\n                float3 param_22 = _1995.xyz;\n                float3 _2005 = fa_dc_to_srgb(param_22);\n                _1999 = _2005;\n            }\n            else\n            {\n                _1999 = _1995.xyz;\n            }\n            float3 _2014 = (_1999 * 2.0f) - 1.0f.xxx;\n            float2 _2019 = _2014.xy * _1769.y;\n            float3 _2041 = (normalize(_1797) * _2019.x) + (normalize(_1804) * _2019.y);\n            float3 _2044 = normalize(normal);\n            normal = normalize(lerp(_2044, normalize((_2044 * max(_2014.z, 0.0500000007450580596923828125f)) + (_2041 - (_2044 * dot(_2044, _2041)))), clamp(_1872 * (_1925 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _6327;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_468_fa_cl_info.x) + int(_468_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_468_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4694;\n    if (fa_lm.z > 0.5f)\n    {\n        _4694 = 0.0f;\n    }\n    else\n    {\n        _4694 = 1.0f - clamp(_468_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4705 = _4694 < 1.0f;\n    bool _4711;\n    if (_4705)\n    {\n        int param = li;\n        _4711 = fa_light_baked(param);\n    }\n    else\n    {\n        _4711 = _4705;\n    }\n    return _4711 ? _4694 : 1.0f;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _646 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _659 = (c - (ru * hx)) - p;\n        float3 _665 = ru * (2.0f * hx);\n        float _671 = max(dot(_665, _665), 9.9999999392252902907785028219223e-09f);\n        float _675 = dot(_659, _665);\n        float t = clamp((-_675) / _671, 0.0f, 1.0f);\n        if (_646)\n        {\n            float _690 = dot(r, _665);\n            float _696 = _671 - (_690 * _690);\n            if (abs(_696) > (9.9999997473787516355514526367188e-06f * _671))\n            {\n                t = clamp(((dot(r, _659) * _690) - _675) / _696, 0.0f, 1.0f);\n            }\n        }\n        return (p + _659) + (_665 * t);\n    }\n    float3 q = p;\n    float _728 = dot(r, axis);\n    bool _736;\n    if (_646)\n    {\n        _736 = abs(_728) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _736 = _646;\n    }\n    if (_736)\n    {\n        float _746 = dot(c - p, axis) / _728;\n        if (_746 > 0.0f)\n        {\n            q = p + (r * _746);\n        }\n    }\n    float3 _759 = q - c;\n    float2 xy = float2(dot(_759, ru), dot(_759, uu));\n    if (shape > 0.5f)\n    {\n        float _774 = length(xy);\n        if (_774 > hx)\n        {\n            xy *= (hx / _774);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _527_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _527_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _566 = dot(d, right);\n    float _570 = dot(d, up);\n    float _581;\n    if (((_566 * _566) + (_570 * _570)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _581 = atan2(_570, _566) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _581 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_581 - floor(_581)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _415 = abs(d);\n    float _417 = _415.x;\n    float _419 = _415.y;\n    bool _420 = _417 >= _419;\n    bool _428;\n    if (_420)\n    {\n        _428 = _417 >= _415.z;\n    }\n    else\n    {\n        _428 = _420;\n    }\n    int _429;\n    if (_428)\n    {\n        _429 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _444;\n        if (_419 >= _415.z)\n        {\n            _444 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _444 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _429 = _444;\n    }\n    return _429;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _812 = fa_light_base(param);\n    bool _816 = _468_fa_ambient.w > 4.5f;\n    int param_1 = _812;\n    float4 _820 = fa_light_texel(param_1);\n    int param_2 = _812 + 1;\n    float4 _825 = fa_light_texel(param_2);\n    float _828 = _825.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _840 = _816 && (_828 > 2.5f);\n    fa_light_is_area = _840;\n    bool _842 = _828 < 0.5f;\n    float3 l;\n    if (_842)\n    {\n        l = normalize(_820.xyz);\n        if (_816)\n        {\n            int param_3 = _812 + 6;\n            float4 _856 = fa_light_texel(param_3);\n            if (_856.z > 0.5f)\n            {\n                int param_4 = _812 + 4;\n                float4 _866 = fa_light_texel(param_4);\n                int param_5 = _812 + 5;\n                float4 _871 = fa_light_texel(param_5);\n                float2 param_6 = _856.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _866.xyz) * _866.w, (-dot(world_pos, _871.xyz)) * _871.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _901 = _820.xyz;\n        float3 _903 = _901 - world_pos;\n        float3 to_light = _903;\n        float _906 = length(_903);\n        float reach = _906;\n        bool front = true;\n        if (_840)\n        {\n            int param_8 = _812 + 7;\n            reach = max(_906 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _812 + 4;\n            float4 _930 = fa_light_texel(param_9);\n            int param_10 = _812 + 5;\n            float4 _935 = fa_light_texel(param_10);\n            int param_11 = _812 + 6;\n            float4 _940 = fa_light_texel(param_11);\n            float _941 = _940.w;\n            int param_12 = _812 + 2;\n            float3 _948 = normalize(fa_light_texel(param_12).xyz);\n            bool _950 = _941 > 1.5f;\n            bool _958;\n            if (!_950)\n            {\n                _958 = dot(_948, to_light) < 0.0f;\n            }\n            else\n            {\n                _958 = _950;\n            }\n            front = _958;\n            float3 r = 0.0f.xxx;\n            float3 _967 = _468_fa_camera_pos.xyz - world_pos;\n            bool _971 = dot(n, n) > 0.5f;\n            bool _979;\n            if (_971)\n            {\n                _979 = dot(_967, _967) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _979 = _971;\n            }\n            if (_979)\n            {\n                r = reflect(-normalize(_967), normalize(n));\n            }\n            float3 param_13 = _901;\n            float3 param_14 = _948;\n            float3 param_15 = _930.xyz;\n            float3 param_16 = _935.xyz;\n            float param_17 = _930.w;\n            float param_18 = _935.w;\n            float param_19 = _941;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1015 = length(to_light);\n        dist = _1015;\n        l = to_light / max(_1015, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1029 = reach / max(_820.w, 0.001000000047497451305389404296875f);\n        float _1035 = clamp(1.0f - (_1029 * _1029), 0.0f, 1.0f);\n        float _1037;\n        if (front)\n        {\n            _1037 = _1035 * _1035;\n        }\n        else\n        {\n            _1037 = 0.0f;\n        }\n        atten = _1037;\n        bool _1048 = _828 < 2.5f;\n        if ((_828 > 1.5f) && _1048)\n        {\n            int param_22 = _812 + 2;\n            float4 _1056 = fa_light_texel(param_22);\n            float _1066 = _1056.w;\n            int param_23 = _812 + 3;\n            float4 _1071 = fa_light_texel(param_23);\n            float _1072 = _1071.x;\n            float cos_inner = _1072;\n            if (_1072 > 1.5f)\n            {\n                cos_inner = lerp(_1066, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1066, cos_inner, dot(-l, normalize(_1056.xyz)));\n        }\n        if (_816 && (_828 < 1.5f))\n        {\n            int param_24 = _812 + 6;\n            float4 _1096 = fa_light_texel(param_24);\n            if (_1096.z > 0.5f)\n            {\n                float3 _1104 = -to_light;\n                int param_25 = _812 + 4;\n                int param_26 = _812 + 5;\n                float3 _1118 = fa_light_texel(param_25).xyz;\n                float3 _1122 = fa_light_texel(param_26).xyz;\n                float3 _1131 = float3(dot(_1104, _1118), dot(_1104, _1122), dot(_1104, cross(_1118, _1122)));\n                float3 param_27 = _1131;\n                int _1135 = fa_cube_face(param_27);\n                int param_28 = _1135;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1162 = float2(dot(_1131, cross(param_29, param_30)), dot(_1131, param_30)) / max(dot(_1131, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1166 = _1135 / 3;\n                float2 param_31 = _1096.xy + (float2(float(_1135 - (_1166 * 3)), float(_1166)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1162.x), 0.5f - (0.5f * _1162.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _812 + 7;\n            float4 _1196 = fa_light_texel(param_33);\n            if (_1196.z > 0.5f)\n            {\n                int param_34 = _812 + 2;\n                int param_35 = _812 + 4;\n                int param_36 = _812 + 5;\n                float2 param_37 = _1196.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_816 && _1048)\n            {\n                int param_42 = _812 + 6;\n                float4 _1243 = fa_light_texel(param_42);\n                int param_43 = _812 + 7;\n                float4 _1248 = fa_light_texel(param_43);\n                bool _1251 = _1243.z > 0.5f;\n                bool _1258;\n                if (!_1251)\n                {\n                    _1258 = _1248.z > 0.5f;\n                }\n                else\n                {\n                    _1258 = _1251;\n                }\n                if (_1258)\n                {\n                    int param_44 = _812 + 2;\n                    float4 _1265 = fa_light_texel(param_44);\n                    float3 _1269 = normalize(_1265.xyz);\n                    int param_45 = _812 + 4;\n                    float4 _1274 = fa_light_texel(param_45);\n                    int param_46 = _812 + 5;\n                    float4 _1279 = fa_light_texel(param_46);\n                    if (_1251)\n                    {\n                        float3 _1287 = -to_light;\n                        float _1294 = _1265.w;\n                        float _1310 = 0.5f / max(dot(_1287, _1269) * (sqrt(max(1.0f - (_1294 * _1294), 0.0f)) / max(_1294, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1243.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1287, _1274.xyz) * _1310), 0.5f - (dot(_1287, _1279.xyz) * _1310));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1248.z > 0.5f)\n                    {\n                        float2 param_49 = _1248.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1269;\n                        float3 param_52 = _1274.xyz;\n                        float3 param_53 = _1279.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _5901 = _825.xyz * atten;\n    if (_816)\n    {\n        _5901 *= fa_light_tint;\n    }\n    int _1379;\n    if (_842)\n    {\n        _1379 = 0;\n    }\n    else\n    {\n        _1379 = ((_828 > 1.5f) && (_828 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _5912 = { l, _5901, atten, 1.0f, dist, _1379 };\n    return _5912;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4923 = n < 0;\n    bool _4930;\n    if (!_4923)\n    {\n        _4930 = n >= fa_light_count();\n    }\n    else\n    {\n        _4930 = _4923;\n    }\n    if (_4930)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4938 = fa_cl_light(param);\n    int param_1 = _4938;\n    float _4942 = fa_baked_keep(param_1);\n    if (_4942 <= 0.0f)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4938;\n    float3 param_3 = i.world_pos;\n    float3 param_4 = i.world_normal;\n    LightSample _4958 = fa_light_sample_n(param_2, param_3, param_4);\n    LightSample _6083 = { _4958.direction, _4958.color * _4942, _4958.attenuation * _4942, _4958.shadow, _4958._distance, _4958.type };\n    return _6083;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2168 = fa_shadow_depth(param, param_1);\n    float _2172;\n    if (conv.x < 0.5f)\n    {\n        _2172 = _2168;\n    }\n    else\n    {\n        _2172 = (conv.y * conv.z) / (conv.z - (_2168 * (conv.z - conv.y)));\n    }\n    return _2172;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2218 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2224 = float2(cos(_2218), sin(_2218));\n    float2 dir = _2224;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2233;\n        if (k < 0.0f)\n        {\n            _2233 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2233 = k;\n        }\n        float _2252 = clamp((_2233 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2271 = sqrt((float(i) + 0.5f) * 0.0625f) * _2252;\n            float2 param_3 = uv + (dir * (_2121_fa_shadow_bias.zw * _2271));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2285 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2285 < (zr - (_2271 * plane)))\n            {\n                sum += _2285;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2313 = sum / cnt;\n        float _2323;\n        if (k < 0.0f)\n        {\n            _2323 = (-k) / max(_2313, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2323 = k;\n        }\n        radius = clamp(((max(zr - _2313, 0.0f) * unit) * _2323) / texel_m, 1.5f, 16.0f);\n        dir = _2224;\n    }\n    float lit = 0.0f;\n    int _2349 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2349; i_1++)\n    {\n        float _2368 = sqrt((float(i_1) + 0.5f) / float(_2349)) * radius;\n        float2 param_7 = uv + (dir * (_2121_fa_shadow_bias.zw * _2368));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2368 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2349);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2573 = _468_fa_pbr.z < 0.5f;\n    bool _2580;\n    if (!_2573)\n    {\n        _2580 = _2121_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2580 = _2573;\n    }\n    if (_2580)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2121_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2593 = fa_light_texel(param);\n    float _2594 = _2593.x;\n    if (_2594 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2603 = int(_2594 + 0.5f);\n    int param_1 = _2603;\n    float4 _2607 = fa_light_texel(param_1);\n    int param_2 = _2603 + 1;\n    float4 _2612 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2615 = _2607.y;\n    if (_2615 > 0.0f)\n    {\n        float _2632 = 1.0f - smoothstep(0.75f * _2615, _2615, length(world - _2121_fa_shadow_eye.xyz));\n        fade = _2632;\n        if (_2632 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2607.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2656 = (_2603 + 2) + (face * 6);\n    int param_4 = _2656;\n    int param_5 = _2656 + 1;\n    int param_6 = _2656 + 3;\n    float4 _2670 = fa_light_texel(param_6);\n    int param_7 = _2656 + 4;\n    float4 _2675 = fa_light_texel(param_7);\n    int param_8 = _2656 + 5;\n    float4 _2680 = fa_light_texel(param_8);\n    float _2692 = _2680.x * max(dot(_2670, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2697 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2720 = clamp(dot(n, _2670.xyz), -1.0f, 1.0f);\n    float _2739 = min(sqrt(1.0f - (_2720 * _2720)) / max(abs(dot(n, world - lpos)) / max(dot(_2670, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2742 = _2612.y;\n    float _2744;\n    if (_2742 > 0.0f)\n    {\n        _2744 = _2742;\n    }\n    else\n    {\n        _2744 = 1.5f * _2692;\n    }\n    float4 _2764 = float4(world + (n * (_2744 * sqrt(1.0f - (_2697 * _2697)))), 1.0f);\n    float _2768 = dot(_2670, _2764);\n    float _2771 = _2680.y;\n    if (_2768 < _2771)\n    {\n        return 1.0f;\n    }\n    float2 _2786 = float2(dot(fa_light_texel(param_4), _2764), dot(fa_light_texel(param_5), _2764)) / _2768.xx;\n    float _2788 = _2786.x;\n    bool _2791 = _2788 < _2675.x;\n    bool _2800;\n    if (!_2791)\n    {\n        _2800 = _2788 > _2675.z;\n    }\n    else\n    {\n        _2800 = _2791;\n    }\n    bool _2809;\n    if (!_2800)\n    {\n        _2809 = _2786.y < _2675.y;\n    }\n    else\n    {\n        _2809 = _2800;\n    }\n    bool _2818;\n    if (!_2809)\n    {\n        _2818 = _2786.y > _2675.w;\n    }\n    else\n    {\n        _2818 = _2809;\n    }\n    if (_2818)\n    {\n        return 1.0f;\n    }\n    float _2824 = _2612.x;\n    float _2826;\n    if (_2824 > 0.0f)\n    {\n        _2826 = _2824;\n    }\n    else\n    {\n        _2826 = 1.5f * _2692;\n    }\n    float2 param_9 = _2786;\n    float4 param_10 = _2675;\n    float param_11 = _2768 - (_2826 * (1.0f + (0.5f * _2739)));\n    float param_12 = _2692;\n    float param_13 = 1.0f;\n    float param_14 = _2680.z * 0.25f;\n    float param_15 = (_2692 * min(_2739, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2771, _2680.z);\n    int param_17 = int(_2607.z + 0.5f);\n    float param_18 = _2607.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2111;\n    if (i == 0)\n    {\n        _2111 = _2121_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2127;\n        if (i == 1)\n        {\n            _2127 = _2121_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2135;\n            if (i == 2)\n            {\n                _2135 = _2121_fa_shadow_split.z;\n            }\n            else\n            {\n                _2135 = _2121_fa_shadow_split.w;\n            }\n            _2127 = _2135;\n        }\n        _2111 = _2127;\n    }\n    return _2111;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2414 = max(_2121_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2419 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2425 = sqrt(1.0f - (_2419 * _2419));\n    float _2433 = min(_2425 / max(_2419, 0.20000000298023223876953125f), 4.0f);\n    float _2438;\n    if (_2121_fa_shadow_bias.y > 0.0f)\n    {\n        _2438 = _2121_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2438 = 1.5f * _2121_fa_shadow_info[ci].x;\n    }\n    float4 _2463 = mul(float4(world + (n * (_2438 * _2425)), 1.0f), _2121_fa_shadow_mat[ci]);\n    float _2470 = _2463.x;\n    bool _2473 = _2470 < _2121_fa_shadow_rect[ci].x;\n    bool _2482;\n    if (!_2473)\n    {\n        _2482 = _2470 > _2121_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2482 = _2473;\n    }\n    bool _2491;\n    if (!_2482)\n    {\n        _2491 = _2463.y < _2121_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2491 = _2482;\n    }\n    bool _2500;\n    if (!_2491)\n    {\n        _2500 = _2463.y > _2121_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2500 = _2491;\n    }\n    bool _2507;\n    if (!_2500)\n    {\n        _2507 = _2463.z > 1.0f;\n    }\n    else\n    {\n        _2507 = _2500;\n    }\n    if (_2507)\n    {\n        return -1.0f;\n    }\n    float _2515;\n    if (_2121_fa_shadow_bias.x > 0.0f)\n    {\n        _2515 = _2121_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2515 = 1.5f * _2121_fa_shadow_info[ci].x;\n    }\n    float2 param = _2463.xy;\n    float4 param_1 = _2121_fa_shadow_rect[ci];\n    float param_2 = _2463.z - ((_2515 * (1.0f + (0.5f * _2433))) / _2414);\n    float param_3 = _2121_fa_shadow_info[ci].x;\n    float param_4 = _2414;\n    float param_5 = _2414 * 0.25f;\n    float param_6 = ((_2121_fa_shadow_info[ci].x * min(_2433, 3.0f)) * 0.5f) / _2414;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2121_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2121_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_468_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2893 = int(_2121_fa_shadow_cfg.x + 0.5f);\n    if (_2893 < 1)\n    {\n        return 1.0f;\n    }\n    float _2908 = dot(world - _2121_fa_shadow_eye.xyz, _2121_fa_shadow_fwd.xyz);\n    int param = _2893 - 1;\n    if (_2908 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2920 = _2893 > 1;\n    bool _2927;\n    if (_2920)\n    {\n        _2927 = _2908 > _2121_fa_shadow_split.x;\n    }\n    else\n    {\n        _2927 = _2920;\n    }\n    if (_2927)\n    {\n        ci = 1;\n    }\n    bool _2931 = _2893 > 2;\n    bool _2938;\n    if (_2931)\n    {\n        _2938 = _2908 > _2121_fa_shadow_split.y;\n    }\n    else\n    {\n        _2938 = _2931;\n    }\n    if (_2938)\n    {\n        ci = 2;\n    }\n    bool _2942 = _2893 > 3;\n    bool _2949;\n    if (_2942)\n    {\n        _2949 = _2908 > _2121_fa_shadow_split.z;\n    }\n    else\n    {\n        _2949 = _2942;\n    }\n    if (_2949)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _2960 = min(_2893, 4);\n    float _3001;\n    for (int c = ci; c < _2960; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2980 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _2980;\n            break;\n        }\n        if (_2980 < 0.0f)\n        {\n            continue;\n        }\n        s = _2980;\n        ci = c;\n        if (_2121_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3001 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3001 = _2121_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _3020 = _2121_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3001, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_2908 - (fa_shadow_split_at(param_7) - _3020)) / _3020, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3052;\n        if ((ci + 1) < _2893)\n        {\n            _3052 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3052 = 1.0f;\n        }\n        s = lerp(s, _3052, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4430 = _468_fa_ct_a.x < 0.5f;\n    bool _4437;\n    if (!_4430)\n    {\n        _4437 = _2121_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4437 = _4430;\n    }\n    if (_4437)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2121_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4450 = fa_light_texel(param);\n    float _4451 = _4450.y;\n    float len = _4451;\n    if (_4451 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4463 = length(world - _468_fa_camera_pos.xyz);\n    float _4473 = 1.0f - smoothstep(0.5f * _468_fa_ct_b.x, _468_fa_ct_b.x, _4463);\n    if (_4473 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4479 = len;\n    float _4482 = min(_4479, 0.89999997615814208984375f * dist);\n    len = _4482;\n    float _4487 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4463);\n    float _4492 = _4487 + (0.5f * _4482);\n    float3 _4498 = world + (gn * _4487);\n    float _4500 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4564;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4515 = (float(k) + _4500) * 0.083333335816860198974609375f;\n        float3 _4523 = _4498 + (l * (_4515 * len));\n        float4 _4529 = float4(_4523, 1.0f);\n        float _4535 = dot(_468_fa_ct_vpw, _4529);\n        if (_4535 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4555 = float2(dot(_468_fa_ct_vpx, _4529), dot(_468_fa_ct_vpy, _4529)) / _4535.xx;\n        float _4559 = _4555.x * 0.5f;\n        float _4560 = _4559 + 0.5f;\n        if (_468_fa_ct_a.y > 0.5f)\n        {\n            _4564 = (_4555.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4564 = 0.5f - (_4555.y * 0.5f);\n        }\n        bool _4580 = _4560 < 0.0f;\n        bool _4587;\n        if (!_4580)\n        {\n            _4587 = _4560 >= 1.0f;\n        }\n        else\n        {\n            _4587 = _4580;\n        }\n        bool _4594;\n        if (!_4587)\n        {\n            _4594 = _4564 < 0.0f;\n        }\n        else\n        {\n            _4594 = _4587;\n        }\n        bool _4601;\n        if (!_4594)\n        {\n            _4601 = _4564 >= 1.0f;\n        }\n        else\n        {\n            _4601 = _4594;\n        }\n        if (_4601)\n        {\n            break;\n        }\n        float4 _4628 = fa_screen_tex.Load(int3(clamp(int2(float2(_4560, _4564) * _468_fa_ct_a.zw), int2(0, 0), int2(_468_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_4628.w < 0.5f)\n        {\n            continue;\n        }\n        float _4647 = (dot(_468_fa_ct_fwd.xyz, _4523) + _468_fa_ct_fwd.w) - _4628.x;\n        if ((_4647 > _4487) && (_4647 < _4492))\n        {\n            occ = max(occ, (1.0f - (_4515 * _4515)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4560, 0.5f - _4559), min(_4564, 1.0f - _4564))));\n        }\n    }\n    return 1.0f - (occ * _4473);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4750 = fa_baked_keep(param);\n    if (_4750 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _6045 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6045;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4776 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6047 = _4776.color;\n    float _6048 = _4776.attenuation;\n    float _6049 = _4776.shadow;\n    bool _4779 = _4776.type == 0;\n    if (_4779 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4776.direction;\n        float _4790 = fa_shadow_factor(param_5, param_6);\n        _6049 = _4790;\n        _6047 *= _4790;\n    }\n    else\n    {\n        bool _4801 = _4776.type != 0;\n        bool _4807;\n        if (_4801)\n        {\n            _4807 = _6048 > 0.0f;\n        }\n        else\n        {\n            _4807 = _4801;\n        }\n        if (_4807)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4776.direction;\n            float _4826 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6049 = _4826;\n            _6047 *= _4826;\n        }\n    }\n    bool _4836 = _468_fa_ct_a.x > 0.5f;\n    bool _4842;\n    if (_4836)\n    {\n        _4842 = _6048 > 0.0f;\n    }\n    else\n    {\n        _4842 = _4836;\n    }\n    if (_4842)\n    {\n        float _4849;\n        if (_4779)\n        {\n            _4849 = 1000000000.0f;\n        }\n        else\n        {\n            _4849 = _4776._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4776.direction;\n        float param_18 = _4849;\n        float _4867 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6049 *= _4867;\n        _6047 *= _4867;\n    }\n    float _4880 = _6048;\n    float _4881 = _4880 * _4750;\n    _6048 = _4881;\n    float3 _4885 = _6047;\n    float3 _4886 = _4885 * _4750;\n    _6047 = _4886;\n    LightSample _6064 = { _4776.direction, _4886, _4881, _6049, _4776._distance, _4776.type };\n    return _6064;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4897 = n < 0;\n    bool _4904;\n    if (!_4897)\n    {\n        _4904 = n >= fa_light_count();\n    }\n    else\n    {\n        _4904 = _4897;\n    }\n    if (_4904)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    LightSample _4919 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4919;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3815 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3823 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3826 = int(_3815);\n    int _3829 = int(_3823);\n    float _3839 = _3823 - float(_3829);\n    int _3895 = (_3826 * 9) + _3829;\n    int _3915 = ((_3826 + 1) * 9) + _3829;\n    return lerp(lerp(_3890[_3895], _3890[_3895 + 1], _3839), lerp(_3890[_3915], _3890[_3915 + 1], _3839), _3815 - float(_3826));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _5913 = false;\n    float _5914 = 1.0f;\n    float _5915 = 1.0f;\n    float _5916 = 1.0f;\n    float _5917 = 0.0f;\n    float _5918 = 0.0f;\n    float _5919 = 0.0f;\n    float _5920 = 0.0f;\n    float _5922 = 1.0f;\n    bool _5923 = false;\n    float3 _5924 = 0.0f.xxx;\n    float _5925 = 1.0f;\n    float _5926 = 1.0f;\n    float _5927 = 1.0f;\n    float _5928 = 0.0f;\n    float _5929 = 0.0f;\n    float3 _5930 = float3(1.0f, 0.0f, 0.0f);\n    float3 _5931 = float3(0.0f, 0.0f, 1.0f);\n    float _5932 = 1.0f;\n    float _5933 = 1.0f;\n    float _3966 = clamp(s.specular, 0.0f, 1.0f);\n    float _3970 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3975 = (_3966 != 1.0f) || (_3970 != 1.5f);\n    bool _3984;\n    if (!_3975)\n    {\n        _3984 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3984 = _3975;\n    }\n    if (_3984)\n    {\n        float _3992 = (_3970 - 1.0f) / (_3970 + 1.0f);\n        f0 = lerp(min((_3992 * _3992).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3966, s.albedo, metallic.xxx);\n        _5914 = lerp(_3966, 1.0f, metallic);\n        _5913 = true;\n    }\n    float _4019 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4019 > 0.0f)\n    {\n        float _4027 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _5917 = _4019;\n        _5918 = _4027;\n        float _4034 = _4027 * _4027;\n        _5919 = _4034;\n        _5920 = _4034 * _4034;\n        float _4046 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _5922 = _4046;\n        _5915 = 1.0f - (_4019 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _4046, 0.0f, 1.0f), 5.0f))));\n        _5913 = true;\n    }\n    float3 _4065 = max(s.sheen_color, 0.0f.xxx);\n    float _4074 = max(_4065.x, max(_4065.y, _4065.z));\n    if (_4074 > 0.0f)\n    {\n        float _4082 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _5923 = true;\n        _5924 = _4065;\n        _5925 = _4082;\n        _5926 = _4082 * _4082;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _4082;\n        float _4099 = fa_sheen_albedo(param, param_1);\n        _5928 = _4099;\n        _5927 = 1.0f - min(_4074 * _4099, 1.0f);\n        _5913 = true;\n    }\n    _5916 = _5915 * _5927;\n    float _4118 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_4118 != 0.0f)\n    {\n        float3 _4133 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _4133;\n        if (dot(_4133, _4133) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _4145 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_4145.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _4145.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _4145.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _4149 = t;\n        float3 _4150 = normalize(_4149);\n        t = _4150;\n        float3 _4175 = normalize((_4150 * cos(s.anisotropy_rotation)) + ((cross(n, _4150) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _5930 = _4175;\n        _5931 = cross(n, _4175);\n        float _4185 = roughness * roughness;\n        float _4191 = lerp(_4185, 1.0f, _4118 * _4118);\n        bool _4193 = _4118 > 0.0f;\n        _5932 = _4193 ? _4191 : _4185;\n        _5933 = _4193 ? _4185 : _4191;\n        _5929 = _4118;\n        _5913 = true;\n    }\n    FaLayers _5955 = { _5913, _5914, _5915, _5916, _5917, _5918, _5919, _5920, i.world_normal, _5922, _5923, _5924, _5925, _5926, _5927, _5928, _5929, _5930, _5931, _5932, _5933 };\n    return _5955;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3747 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3750 = _3747.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3750 * _3750, exp2((-9.27999973297119140625f) * ndv)) * _3750) + _3747.y)) + _3747.zw;\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3182 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3185 = _3182.x;\n    float _3187 = _3182.z;\n    float2 e = float2(_3185, _3187);\n    if (_3182.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3187)) * ((_3185 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3185)) * ((_3187 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3221_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3221_dummy_parameter)));\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _3234;\n    if (lv == 0)\n    {\n        _3234 = 0.0f;\n    }\n    else\n    {\n        _3234 = res + 2.0f;\n    }\n    float _3244;\n    if (lv == 0)\n    {\n        _3244 = 0.0f;\n    }\n    else\n    {\n        _3244 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_3234, _3244)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _3290;\n    if (res > 64.5f)\n    {\n        _3290 = 5.0f;\n    }\n    else\n    {\n        _3290 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _3305 = clamp(rough, 0.0f, 1.0f) * (_3290 - 1.0f);\n    int _3312 = int(min(floor(_3305), _3290 - 2.0f));\n    float _3317 = _3305 - float(_3312);\n    float3 param = d;\n    float2 _3321 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3312;\n    float2 param_4 = _3321;\n    float3 _3331 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3317 < 0.00200000009499490261077880859375f)\n    {\n        return _3331;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3312 + 1;\n    float2 param_8 = _3321;\n    return lerp(_3331, fa_probe_level(param_5, param_6, param_7, param_8), _3317.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _3369 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3376 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3383 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3389 = dot(bx.xyz, d);\n    float _3393 = dot(by.xyz, d);\n    float _3397 = dot(bz.xyz, d);\n    float _3403;\n    if (_3389 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3403 = (1.0f - _3369) / _3389;\n    }\n    else\n    {\n        float _3417;\n        if (_3389 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3417 = ((-1.0f) - _3369) / _3389;\n        }\n        else\n        {\n            _3417 = 1000000015047466219876688855040.0f;\n        }\n        _3403 = _3417;\n    }\n    float tx = _3403;\n    float _3434;\n    if (_3393 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3434 = (1.0f - _3376) / _3393;\n    }\n    else\n    {\n        float _3447;\n        if (_3393 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3447 = ((-1.0f) - _3376) / _3393;\n        }\n        else\n        {\n            _3447 = 1000000015047466219876688855040.0f;\n        }\n        _3434 = _3447;\n    }\n    float ty = _3434;\n    float _3463;\n    if (_3397 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3463 = (1.0f - _3383) / _3397;\n    }\n    else\n    {\n        float _3476;\n        if (_3397 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3476 = ((-1.0f) - _3383) / _3397;\n        }\n        else\n        {\n            _3476 = 1000000015047466219876688855040.0f;\n        }\n        _3463 = _3476;\n    }\n    float _3488 = tx;\n    float _3491 = (_3488 > 0.0f) ? _3488 : 1000000015047466219876688855040.0f;\n    tx = _3491;\n    float _3492 = ty;\n    float _3495 = (_3492 > 0.0f) ? _3492 : 1000000015047466219876688855040.0f;\n    ty = _3495;\n    float _3505 = min(_3491, min(_3495, (_3463 > 0.0f) ? _3463 : 1000000015047466219876688855040.0f));\n    if (_3505 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _3521 = (fa_world_pos + (d * _3505)) - posw.xyz;\n    float3 _3526;\n    if (dot(_3521, _3521) > 1.0000000133514319600180897396058e-10f)\n    {\n        _3526 = normalize(_3521);\n    }\n    else\n    {\n        _3526 = d;\n    }\n    return _3526;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _3572 = (1.0f - _468_fa_rpa_tile.w) - _468_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_3572 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_468_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _468_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3602 = rough * rough;\n            float _3633 = 0.60000002384185791015625f * _3602;\n            base = lerp(lerp(_468_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_468_fa_env_horizon.xyz, _468_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3602)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3633, 0.0500000007450580596923828125f + _3633, d.y).xxx), ((_468_fa_env_sky.xyz + _468_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3602 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _3572;\n    }\n    if (_468_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _468_fa_rpa_tile;\n        float4 param_5 = _468_fa_rpa_pos;\n        float4 param_6 = _468_fa_rpa_bx;\n        float4 param_7 = _468_fa_rpa_by;\n        float4 param_8 = _468_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _3692 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3692 * _468_fa_rpa_tile.w);\n    }\n    if (_468_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _468_fa_rpb_tile;\n        float4 param_12 = _468_fa_rpb_pos;\n        float4 param_13 = _468_fa_rpb_bx;\n        float4 param_14 = _468_fa_rpb_by;\n        float4 param_15 = _468_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _3724 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3724 * _468_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness, float occlusion)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4226;\n        if (L.aniso >= 0.0f)\n        {\n            _4226 = L.b;\n        }\n        else\n        {\n            _4226 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4226, v), _4226), (abs(L.aniso) * smoothstep(0.0f, 0.25f, roughness)).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4262 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4262.x) + (L.f90.xxx * _4262.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4320 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4320.x) + _4320.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3789 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3789.x) + _3789.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4359 = clamp(s.metallic, 0.0f, 1.0f);\n    float _4363 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _4370 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _4359.xxx);\n    float3 f0 = _4370;\n    float3 _4374 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _4374;\n    float3 param_3 = i.view_dir;\n    float param_4 = _4359;\n    float param_5 = _4363;\n    float3 param_6 = _4370;\n    FaLayers _4391 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4391.on)\n    {\n        FaLayers param_7 = _4391;\n        float3 param_8 = _4374;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _4363;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    float3 param_13 = _4374;\n    float3 param_14 = i.view_dir;\n    float3 param_15 = f0;\n    float param_16 = _4363;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _4989 = fa_light_unshadowed(param, param_1);\n        float _4997 = dot(_4989.color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_4997 > bestPower)\n        {\n            bestPower = _4997;\n            best = n;\n        }\n    }\n    float3 lit = (_468_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _5026 = fa_light(param_2, param_3);\n        float _5034;\n        if (dot(s.normal, _5026.direction) > 0.5f)\n        {\n            _5034 = 1.0f;\n        }\n        else\n        {\n            _5034 = _5040_dark;\n        }\n        lit += ((s.albedo * _5026.color) * _5034);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _5040_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2121_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3080 = int(_2121_fa_shadow_cfg.x + 0.5f);\n    float _3090 = dot(world - _2121_fa_shadow_eye.xyz, _2121_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3095 = _3080 > 0;\n    bool _3104;\n    if (_3095)\n    {\n        int param = _3080 - 1;\n        _3104 = _3090 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3104 = _3095;\n    }\n    if (_3104)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3110 = _3080 > 1;\n        bool _3117;\n        if (_3110)\n        {\n            _3117 = _3090 > _2121_fa_shadow_split.x;\n        }\n        else\n        {\n            _3117 = _3110;\n        }\n        if (_3117)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3123 = _3080 > 2;\n        bool _3130;\n        if (_3123)\n        {\n            _3130 = _3090 > _2121_fa_shadow_split.y;\n        }\n        else\n        {\n            _3130 = _3123;\n        }\n        if (_3130)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3136 = _3080 > 3;\n        bool _3143;\n        if (_3136)\n        {\n            _3143 = _3090 > _2121_fa_shadow_split.z;\n        }\n        else\n        {\n            _3143 = _3136;\n        }\n        if (_3143)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5767 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5767 = -_5767;\n    }\n    float3 _5437 = normalize(_468_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5780 = { fa_world_pos, _5767, fa_world_tangent, fa_uv, fa_vertex_color, _5437, gl_FrontFacing };\n    SurfaceInput param_1 = _5780;\n    Surface _5445 = fa_standard_surface(param_1);\n    float3 _5798 = _5445.albedo;\n    float _5799 = _5445.alpha;\n    float3 _5800 = _5445.normal;\n    float _5801 = _5445.metallic;\n    float _5802 = _5445.roughness;\n    float _5803 = _5445.occlusion;\n    float3 _5804 = _5445.emission;\n    float _5805 = _5445.clearcoat;\n    float _5806 = _5445.clearcoat_roughness;\n    float3 _5807 = _5445.sheen_color;\n    float _5808 = _5445.sheen_roughness;\n    float _5809 = _5445.anisotropy;\n    float _5810 = _5445.anisotropy_rotation;\n    float _5811 = _5445.specular;\n    float _5812 = _5445.ior;\n    float3 _5813 = _5445.specular_color;\n    float _5814 = _5445.transmission;\n    float _5815 = _5445.thickness;\n    float3 _5816 = _5445.attenuation_color;\n    float _5817 = _5445.attenuation_distance;\n    SurfaceInput _5788 = { fa_world_pos, _5767, fa_world_tangent, fa_uv, fa_vertex_color, _5437, gl_FrontFacing };\n    SurfaceInput param_2 = _5788;\n    Surface param_3 = _5445;\n    surface(param_2, param_3);\n    _5798 = param_3.albedo;\n    _5799 = param_3.alpha;\n    _5800 = param_3.normal;\n    _5801 = param_3.metallic;\n    _5802 = param_3.roughness;\n    _5803 = param_3.occlusion;\n    _5804 = param_3.emission;\n    _5805 = param_3.clearcoat;\n    _5806 = param_3.clearcoat_roughness;\n    _5807 = param_3.sheen_color;\n    _5808 = param_3.sheen_roughness;\n    _5809 = param_3.anisotropy;\n    _5810 = param_3.anisotropy_rotation;\n    _5811 = param_3.specular;\n    _5812 = param_3.ior;\n    _5813 = param_3.specular_color;\n    _5814 = param_3.transmission;\n    _5815 = param_3.thickness;\n    _5816 = param_3.attenuation_color;\n    _5817 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5767;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5798 = param_6;\n    _5800 = param_7;\n    float3 result;\n    if (_468_fa_emissive.w > 0.5f)\n    {\n        result = _5798;\n    }\n    else\n    {\n        float3 _5484 = _5800;\n        float3 _5485 = normalize(_5484);\n        _5800 = _5485;\n        SurfaceInput _5796 = { fa_world_pos, _5767, fa_world_tangent, fa_uv, fa_vertex_color, _5437, gl_FrontFacing };\n        SurfaceInput param_8 = _5796;\n        Surface _5899 = { _5798, _5799, _5485, _5801, _5802, _5803, _5804, _5805, _5806, _5807, _5808, _5809, _5810, _5811, _5812, _5813, _5814, _5815, _5816, _5817 };\n        Surface param_9 = _5899;\n        float3 _5496 = lighting(param_8, param_9);\n        result = _5496;\n    }\n    float3 _5500 = result;\n    float3 _5501 = _5500 + _5804;\n    result = _5501;\n    float3 param_10 = _5501;\n    float3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _5510 = _468_fa_fog.w > 0.0f;\n    bool _5517;\n    if (!_5510)\n    {\n        _5517 = _468_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5517 = _5510;\n    }\n    if (_5517)\n    {\n        float3 _5526 = fa_world_pos - _468_fa_camera_pos.xyz;\n        float _5532 = dot(_5526, _468_fa_fog_c.xyz);\n        bool _5536 = _468_fa_fog_c.w > 0.5f;\n        float _5537;\n        if (_5536)\n        {\n            _5537 = _5532;\n        }\n        else\n        {\n            _5537 = length(_5526);\n        }\n        float _5549 = _5537 - _468_fa_fog_b.x;\n        if (_5549 > 0.0f)\n        {\n            float _5558 = _468_fa_fog.w * _5549;\n            float tau = _5558 * _5558;\n            if (_468_fa_fog_b.y > 0.0f)\n            {\n                float _5574;\n                if (_5536)\n                {\n                    _5574 = fa_world_pos.y - (_468_fa_fog_c.y * _5532);\n                }\n                else\n                {\n                    _5574 = _468_fa_camera_pos.y;\n                }\n                float _5595 = lerp(_5574, fa_world_pos.y, clamp(_468_fa_fog_b.x / _5537, 0.0f, 1.0f));\n                float _5599 = fa_world_pos.y - _5595;\n                float _5604 = _5595 - _468_fa_fog_b.z;\n                float _5609 = fa_world_pos.y - _468_fa_fog_b.z;\n                bool _5612 = _5604 <= 0.0f;\n                bool _5613 = !_5612;\n                bool _5619;\n                if (_5613)\n                {\n                    _5619 = _468_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5619 = _5612;\n                }\n                float _5620;\n                if (_5619)\n                {\n                    _5620 = _468_fa_fog_b.y;\n                }\n                else\n                {\n                    _5620 = _468_fa_fog_b.y * exp(-min(_468_fa_fog_b.w * _5604, 80.0f));\n                }\n                bool _5647;\n                if (_5613)\n                {\n                    _5647 = _468_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5647 = _5612;\n                }\n                float _5648;\n                if (_5647)\n                {\n                    _5648 = _468_fa_fog_b.y * _5604;\n                }\n                else\n                {\n                    _5648 = (_468_fa_fog_b.y * (1.0f - exp(-min(_468_fa_fog_b.w * _5604, 80.0f)))) / _468_fa_fog_b.w;\n                }\n                bool _5673 = _5609 <= 0.0f;\n                bool _5680;\n                if (!_5673)\n                {\n                    _5680 = _468_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5680 = _5673;\n                }\n                float _5681;\n                if (_5680)\n                {\n                    _5681 = _468_fa_fog_b.y * _5609;\n                }\n                else\n                {\n                    _5681 = (_468_fa_fog_b.y * (1.0f - exp(-min(_468_fa_fog_b.w * _5609, 80.0f)))) / _468_fa_fog_b.w;\n                }\n                float _5708;\n                if (abs(_5599) < 0.001000000047497451305389404296875f)\n                {\n                    _5708 = _5620;\n                }\n                else\n                {\n                    _5708 = (_5681 - _5648) / _5599;\n                }\n                tau += (_5549 * max(_5708, 0.0f));\n            }\n            result = lerp(result, _468_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5799);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_5040",
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
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3890[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _6327 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _468_fa_camera_pos : packoffset(c0);\n    float4 _468_fa_ambient : packoffset(c1);\n    float4 _468_fa_base_color : packoffset(c2);\n    float4 _468_fa_emissive : packoffset(c3);\n    float4 _468_fa_model_emissive : packoffset(c4);\n    float4 _468_fa_pbr : packoffset(c5);\n    float4 _468_fa_maps : packoffset(c6);\n    float4 _468_fa_fog : packoffset(c7);\n    float4 _468_fa_fog_b : packoffset(c8);\n    float4 _468_fa_fog_c : packoffset(c9);\n    float4 _468_fa_counts : packoffset(c10);\n    float4 _468_fa_env_sky : packoffset(c11);\n    float4 _468_fa_env_horizon : packoffset(c12);\n    float4 _468_fa_time : packoffset(c13);\n    float4 _468_fa_cl_vpx : packoffset(c14);\n    float4 _468_fa_cl_vpy : packoffset(c15);\n    float4 _468_fa_cl_vpw : packoffset(c16);\n    float4 _468_fa_cl_fwd : packoffset(c17);\n    float4 _468_fa_cl_grid : packoffset(c18);\n    float4 _468_fa_cl_info : packoffset(c19);\n    float4 _468_fa_layers_a : packoffset(c20);\n    float4 _468_fa_layers_b : packoffset(c21);\n    float4 _468_fa_layers_c : packoffset(c22);\n    float4 _468_fa_layers_d : packoffset(c23);\n    float4 _468_fa_ct_a : packoffset(c24);\n    float4 _468_fa_ct_b : packoffset(c25);\n    float4 _468_fa_ct_vpx : packoffset(c26);\n    float4 _468_fa_ct_vpy : packoffset(c27);\n    float4 _468_fa_ct_vpw : packoffset(c28);\n    float4 _468_fa_ct_fwd : packoffset(c29);\n    float4 _468_fa_tr_a : packoffset(c30);\n    float4 _468_fa_tr_b : packoffset(c31);\n    float4 _468_fa_probe_sh[9] : packoffset(c32);\n    float4 _468_fa_atlas : packoffset(c41);\n    float4 _468_fa_rpa_tile : packoffset(c42);\n    float4 _468_fa_rpa_pos : packoffset(c43);\n    float4 _468_fa_rpa_bx : packoffset(c44);\n    float4 _468_fa_rpa_by : packoffset(c45);\n    float4 _468_fa_rpa_bz : packoffset(c46);\n    float4 _468_fa_rpb_tile : packoffset(c47);\n    float4 _468_fa_rpb_pos : packoffset(c48);\n    float4 _468_fa_rpb_bx : packoffset(c49);\n    float4 _468_fa_rpb_by : packoffset(c50);\n    float4 _468_fa_rpb_bz : packoffset(c51);\n    float4 _468_fa_gi : packoffset(c52);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2121_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2121_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2121_fa_shadow_info[4] : packoffset(c20);\n    float4 _2121_fa_shadow_split : packoffset(c24);\n    float4 _2121_fa_shadow_cfg : packoffset(c25);\n    float4 _2121_fa_shadow_bias : packoffset(c26);\n    float4 _2121_fa_shadow_eye : packoffset(c27);\n    float4 _2121_fa_shadow_fwd : packoffset(c28);\n    float4 _2121_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _5040_dark : packoffset(c0);\n    float _5040_fa_pad0 : packoffset(c0.y);\n    float _5040_fa_pad1 : packoffset(c0.z);\n    float _5040_fa_pad2 : packoffset(c0.w);\n    float _5040_skyAmount : packoffset(c1);\n    float _5040_fa_pad3 : packoffset(c1.y);\n    float _5040_fa_pad4 : packoffset(c1.z);\n    float _5040_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t9);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTexture2D<float4> fa_probe_atlas : register(t6);\nTexture2D<float4> fa_screen_tex : register(t10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1397 = _468_fa_cl_info.x < 0.0f;\n    bool _1404;\n    if (!_1397)\n    {\n        _1404 = _468_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1404 = _1397;\n    }\n    bool _1412;\n    if (!_1404)\n    {\n        _1412 = _468_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1412 = _1404;\n    }\n    bool _1419;\n    if (!_1412)\n    {\n        _1419 = _468_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1419 = _1412;\n    }\n    bool _1426;\n    if (!_1419)\n    {\n        _1426 = _468_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1426 = _1419;\n    }\n    if (_1426)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1436 = float4(world_pos, 1.0f);\n    float _1442 = dot(_468_fa_cl_vpw, _1436);\n    if (!(_1442 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1464 = float2(dot(_468_fa_cl_vpx, _1436), dot(_468_fa_cl_vpy, _1436)) / _1442.xx;\n    int _1468 = int(_468_fa_cl_grid.x);\n    int _1472 = int(_468_fa_cl_grid.y);\n    int param = (int(_468_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_468_fa_cl_fwd.xyz, world_pos) + _468_fa_cl_fwd.w, _468_fa_cl_grid.w) / _468_fa_cl_grid.w) * _468_fa_cl_grid.z)), 0, int(_468_fa_cl_info.y) - 1) * _1472) + clamp(int(floor(((_1464.y * 0.5f) + 0.5f) * _468_fa_cl_grid.y)), 0, _1472 - 1)) * _1468)) + clamp(int(floor(((_1464.x * 0.5f) + 0.5f) * _468_fa_cl_grid.x)), 0, _1468 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1548 = fa_cluster_texel(param);\n    return int2(int(_1548.x), int(_1548.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_468_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4724 = fa_cluster_lookup(param);\n    fa_cl_slot = _4724.x;\n    fa_cl_local = _4724.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _5101 = fa_linear_to_srgb(param);\n        c = _5101;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _5109 = fa_srgb_to_linear(param_1);\n            c = _5109;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _348;\n    if (i.front_facing)\n    {\n        _348 = i.world_normal;\n    }\n    else\n    {\n        _348 = -i.world_normal;\n    }\n    float3 _372 = normalize(i.world_tangent.xyz - (_348 * dot(_348, i.world_tangent.xyz)));\n    float3 _400 = normalize(((_372 * m.x) + ((cross(_348, _372) * i.world_tangent.w) * m.y)) + (_348 * m.z));\n    float3 _403;\n    if (i.front_facing)\n    {\n        _403 = _400;\n    }\n    else\n    {\n        _403 = -_400;\n    }\n    return _403;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.SampleBias(fa_smp, i.uv, _468_fa_env_horizon.w);\n    float param = _468_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _5142 = fa_tex_fix(param_2, param_3);\n    float4 _6289 = base_t;\n    _6289.x = _5142.x;\n    _6289.y = _5142.y;\n    _6289.z = _5142.z;\n    base_t = _6289;\n    float4 _5156 = (_6289 * _468_fa_base_color) * i.vertex_color;\n    float3 _6095 = i.world_normal;\n    if (_468_fa_maps.z > 0.5f)\n    {\n        float param_4 = _468_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.SampleBias(fa_smp, i.uv, _468_fa_env_horizon.w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _5190 = fa_tex_fix(param_6, param_7);\n        float3 _5193 = (_5190 * 2.0f) - 1.0f.xxx;\n        float2 _5198 = _5193.xy * _468_fa_maps.x;\n        float3 _6297 = _5193;\n        _6297.x = _5198.x;\n        _6297.y = _5198.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _6297;\n        _6095 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.SampleBias(fa_smp, i.uv, _468_fa_env_horizon.w);\n    float param_10 = _468_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _5228 = fa_tex_fix(param_12, param_13);\n    float4 _6300 = mrt;\n    _6300.x = _5228.x;\n    _6300.y = _5228.y;\n    _6300.z = _5228.z;\n    mrt = _6300;\n    float4 _5258 = fa_occlusion_tex.SampleBias(fa_smp, i.uv, _468_fa_env_horizon.w);\n    float param_14 = _468_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _5258.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _5269 = fa_tex_fix(param_16, param_17);\n    float param_18 = _468_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.SampleBias(fa_smp, i.uv, _468_fa_env_horizon.w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _5301 = fa_tex_fix(param_20, param_21);\n    float _6100 = _468_fa_layers_a.x;\n    float _6101 = _468_fa_layers_a.y;\n    float _6104 = _468_fa_layers_a.z;\n    float _6103 = _468_fa_layers_b.w;\n    float _6106 = _468_fa_layers_c.x;\n    if (_468_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_468_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _6100 *= _5269.y;\n            _6101 *= _5269.z;\n            _6103 *= _5258.w;\n        }\n        if (_468_fa_layers_c.z > 1.5f)\n        {\n            _6104 *= mrt.x;\n            _6106 *= mrt.w;\n        }\n    }\n    Surface _6133 = { _5156.xyz, _5156.w, _6095, clamp(_468_fa_pbr.x * _5228.z, 0.0f, 1.0f), clamp(_468_fa_pbr.y * _5228.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_468_fa_maps.y * (_5269.x - 1.0f)), _468_fa_emissive.xyz + (_468_fa_model_emissive.xyz * _5301), _6100, _6101, _468_fa_layers_b.xyz, _6103, _6104, _468_fa_layers_a.w, _6106, _468_fa_layers_c.y, _468_fa_layers_d.xyz, _468_fa_tr_a.x, _468_fa_tr_a.y, _468_fa_tr_b.xyz, _468_fa_tr_a.z };\n    return _6133;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1628 = rect.zw - rect.xy;\n    float2 _1632 = _1628 * atlas;\n    float2 _1636 = ddx * _1632;\n    float2 _1640 = ddy * _1632;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1628), clamp(0.5f * log2(max(max(dot(_1636, _1636), dot(_1640, _1640)), 9.9999999392252902907785028219223e-09f)), 0.0f, 3.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1673 = _468_fa_counts.y < 0.5f;\n    bool _1680;\n    if (!_1673)\n    {\n        _1680 = _468_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1680 = _1673;\n    }\n    if (_1680)\n    {\n        return;\n    }\n    float3 _1686 = ddx(world_pos);\n    float3 _1689 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1693 = fa_cluster_texel(param);\n    int _1697 = int(_1693.w);\n    if (_1697 < 1)\n    {\n        return;\n    }\n    int _1707 = int(_468_fa_counts.y + 0.5f);\n    int param_1 = _1707;\n    float4 _1711 = fa_light_texel(param_1);\n    float2 _1714 = _1711.yz;\n    int _1718 = int(_1711.w);\n    int param_2 = _1707 + 1;\n    float4 _1723 = fa_light_texel(param_2);\n    float _1724 = _1723.x;\n    int _1730 = int(_468_fa_counts.w + 0.5f) - 1;\n    int _1734 = int(_1693.z);\n    float3 _1999;\n    for (int k = 0; k < _1697; k++)\n    {\n        int _1747 = _1734 + k;\n        int param_3 = _1718 + (_1747 >> 2);\n        int _1764 = (_1707 + 2) + (int(fa_light_texel(param_3)[_1747 & 3]) * 7);\n        int param_4 = _1764 + 6;\n        float4 _1769 = fa_light_texel(param_4);\n        if (((int(_1769.w + 0.5f) >> _1730) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1764;\n        float4 _1784 = fa_light_texel(param_5);\n        int param_6 = _1764 + 1;\n        float4 _1789 = fa_light_texel(param_6);\n        int param_7 = _1764 + 2;\n        float4 _1794 = fa_light_texel(param_7);\n        float3 _1797 = _1784.xyz;\n        float _1802 = dot(_1797, world_pos) + _1784.w;\n        float3 _1804 = _1789.xyz;\n        float _1809 = dot(_1804, world_pos) + _1789.w;\n        float3 _1811 = _1794.xyz;\n        float _1816 = dot(_1811, world_pos) + _1794.w;\n        bool _1821 = abs(_1802) > 0.5f;\n        bool _1829;\n        if (!_1821)\n        {\n            _1829 = abs(_1809) > 0.5f;\n        }\n        else\n        {\n            _1829 = _1821;\n        }\n        bool _1837;\n        if (!_1829)\n        {\n            _1837 = abs(_1816) > 0.5f;\n        }\n        else\n        {\n            _1837 = _1829;\n        }\n        if (_1837)\n        {\n            continue;\n        }\n        float _1852 = clamp(dot(geo_normal, normalize(_1811)) * _1769.z, 0.0f, 1.0f);\n        if (_1852 <= 0.0f)\n        {\n            continue;\n        }\n        float _1872 = (clamp((0.5f - abs(_1816)) * 10.0f, 0.0f, 1.0f) * _1852) * _1769.x;\n        float2 _1880 = float2(_1802 + 0.5f, 0.5f - _1809);\n        float2 _1890 = float2(dot(_1797, _1686), dot(_1804, _1686));\n        float2 _1900 = float2(dot(_1797, _1689), dot(_1804, _1689));\n        int param_8 = _1764 + 5;\n        float4 _1905 = fa_light_texel(param_8);\n        int param_9 = _1764 + 3;\n        float4 _1910 = fa_light_texel(param_9);\n        int param_10 = _1764 + 4;\n        float4 _1915 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1905.xyz;\n        bool _1925 = _1910.z > _1910.x;\n        if (_1925)\n        {\n            float4 param_11 = _1910;\n            float2 param_12 = _1880;\n            float2 param_13 = _1714;\n            float2 param_14 = _1890;\n            float2 param_15 = _1900;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1724 > 0.5f) && (_1724 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1951 = fa_dc_to_linear(param_16);\n                float4 _6183 = tx;\n                _6183.x = _1951.x;\n                _6183.y = _1951.y;\n                _6183.z = _1951.z;\n                tx = _6183;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1872 * tex_a) * _1905.w, 0.0f, 1.0f).xxx);\n        if (_1915.z > _1915.x)\n        {\n            float4 param_17 = _1915;\n            float2 param_18 = _1880;\n            float2 param_19 = _1714;\n            float2 param_20 = _1890;\n            float2 param_21 = _1900;\n            float4 _1995 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1724 > 1.5f)\n            {\n                float3 param_22 = _1995.xyz;\n                float3 _2005 = fa_dc_to_srgb(param_22);\n                _1999 = _2005;\n            }\n            else\n            {\n                _1999 = _1995.xyz;\n            }\n            float3 _2014 = (_1999 * 2.0f) - 1.0f.xxx;\n            float2 _2019 = _2014.xy * _1769.y;\n            float3 _2041 = (normalize(_1797) * _2019.x) + (normalize(_1804) * _2019.y);\n            float3 _2044 = normalize(normal);\n            normal = normalize(lerp(_2044, normalize((_2044 * max(_2014.z, 0.0500000007450580596923828125f)) + (_2041 - (_2044 * dot(_2044, _2041)))), clamp(_1872 * (_1925 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _6327;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_468_fa_cl_info.x) + int(_468_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_468_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4694;\n    if (fa_lm.z > 0.5f)\n    {\n        _4694 = 0.0f;\n    }\n    else\n    {\n        _4694 = 1.0f - clamp(_468_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4705 = _4694 < 1.0f;\n    bool _4711;\n    if (_4705)\n    {\n        int param = li;\n        _4711 = fa_light_baked(param);\n    }\n    else\n    {\n        _4711 = _4705;\n    }\n    return _4711 ? _4694 : 1.0f;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _646 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _659 = (c - (ru * hx)) - p;\n        float3 _665 = ru * (2.0f * hx);\n        float _671 = max(dot(_665, _665), 9.9999999392252902907785028219223e-09f);\n        float _675 = dot(_659, _665);\n        float t = clamp((-_675) / _671, 0.0f, 1.0f);\n        if (_646)\n        {\n            float _690 = dot(r, _665);\n            float _696 = _671 - (_690 * _690);\n            if (abs(_696) > (9.9999997473787516355514526367188e-06f * _671))\n            {\n                t = clamp(((dot(r, _659) * _690) - _675) / _696, 0.0f, 1.0f);\n            }\n        }\n        return (p + _659) + (_665 * t);\n    }\n    float3 q = p;\n    float _728 = dot(r, axis);\n    bool _736;\n    if (_646)\n    {\n        _736 = abs(_728) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _736 = _646;\n    }\n    if (_736)\n    {\n        float _746 = dot(c - p, axis) / _728;\n        if (_746 > 0.0f)\n        {\n            q = p + (r * _746);\n        }\n    }\n    float3 _759 = q - c;\n    float2 xy = float2(dot(_759, ru), dot(_759, uu));\n    if (shape > 0.5f)\n    {\n        float _774 = length(xy);\n        if (_774 > hx)\n        {\n            xy *= (hx / _774);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _527_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _527_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _566 = dot(d, right);\n    float _570 = dot(d, up);\n    float _581;\n    if (((_566 * _566) + (_570 * _570)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _581 = atan2(_570, _566) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _581 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_581 - floor(_581)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _415 = abs(d);\n    float _417 = _415.x;\n    float _419 = _415.y;\n    bool _420 = _417 >= _419;\n    bool _428;\n    if (_420)\n    {\n        _428 = _417 >= _415.z;\n    }\n    else\n    {\n        _428 = _420;\n    }\n    int _429;\n    if (_428)\n    {\n        _429 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _444;\n        if (_419 >= _415.z)\n        {\n            _444 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _444 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _429 = _444;\n    }\n    return _429;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _812 = fa_light_base(param);\n    bool _816 = _468_fa_ambient.w > 4.5f;\n    int param_1 = _812;\n    float4 _820 = fa_light_texel(param_1);\n    int param_2 = _812 + 1;\n    float4 _825 = fa_light_texel(param_2);\n    float _828 = _825.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _840 = _816 && (_828 > 2.5f);\n    fa_light_is_area = _840;\n    bool _842 = _828 < 0.5f;\n    float3 l;\n    if (_842)\n    {\n        l = normalize(_820.xyz);\n        if (_816)\n        {\n            int param_3 = _812 + 6;\n            float4 _856 = fa_light_texel(param_3);\n            if (_856.z > 0.5f)\n            {\n                int param_4 = _812 + 4;\n                float4 _866 = fa_light_texel(param_4);\n                int param_5 = _812 + 5;\n                float4 _871 = fa_light_texel(param_5);\n                float2 param_6 = _856.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _866.xyz) * _866.w, (-dot(world_pos, _871.xyz)) * _871.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _901 = _820.xyz;\n        float3 _903 = _901 - world_pos;\n        float3 to_light = _903;\n        float _906 = length(_903);\n        float reach = _906;\n        bool front = true;\n        if (_840)\n        {\n            int param_8 = _812 + 7;\n            reach = max(_906 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _812 + 4;\n            float4 _930 = fa_light_texel(param_9);\n            int param_10 = _812 + 5;\n            float4 _935 = fa_light_texel(param_10);\n            int param_11 = _812 + 6;\n            float4 _940 = fa_light_texel(param_11);\n            float _941 = _940.w;\n            int param_12 = _812 + 2;\n            float3 _948 = normalize(fa_light_texel(param_12).xyz);\n            bool _950 = _941 > 1.5f;\n            bool _958;\n            if (!_950)\n            {\n                _958 = dot(_948, to_light) < 0.0f;\n            }\n            else\n            {\n                _958 = _950;\n            }\n            front = _958;\n            float3 r = 0.0f.xxx;\n            float3 _967 = _468_fa_camera_pos.xyz - world_pos;\n            bool _971 = dot(n, n) > 0.5f;\n            bool _979;\n            if (_971)\n            {\n                _979 = dot(_967, _967) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _979 = _971;\n            }\n            if (_979)\n            {\n                r = reflect(-normalize(_967), normalize(n));\n            }\n            float3 param_13 = _901;\n            float3 param_14 = _948;\n            float3 param_15 = _930.xyz;\n            float3 param_16 = _935.xyz;\n            float param_17 = _930.w;\n            float param_18 = _935.w;\n            float param_19 = _941;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1015 = length(to_light);\n        dist = _1015;\n        l = to_light / max(_1015, 9.9999997473787516355514526367188e-05f).xxx;\n        float _1029 = reach / max(_820.w, 0.001000000047497451305389404296875f);\n        float _1035 = clamp(1.0f - (_1029 * _1029), 0.0f, 1.0f);\n        float _1037;\n        if (front)\n        {\n            _1037 = _1035 * _1035;\n        }\n        else\n        {\n            _1037 = 0.0f;\n        }\n        atten = _1037;\n        bool _1048 = _828 < 2.5f;\n        if ((_828 > 1.5f) && _1048)\n        {\n            int param_22 = _812 + 2;\n            float4 _1056 = fa_light_texel(param_22);\n            float _1066 = _1056.w;\n            int param_23 = _812 + 3;\n            float4 _1071 = fa_light_texel(param_23);\n            float _1072 = _1071.x;\n            float cos_inner = _1072;\n            if (_1072 > 1.5f)\n            {\n                cos_inner = lerp(_1066, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1066, cos_inner, dot(-l, normalize(_1056.xyz)));\n        }\n        if (_816 && (_828 < 1.5f))\n        {\n            int param_24 = _812 + 6;\n            float4 _1096 = fa_light_texel(param_24);\n            if (_1096.z > 0.5f)\n            {\n                float3 _1104 = -to_light;\n                int param_25 = _812 + 4;\n                int param_26 = _812 + 5;\n                float3 _1118 = fa_light_texel(param_25).xyz;\n                float3 _1122 = fa_light_texel(param_26).xyz;\n                float3 _1131 = float3(dot(_1104, _1118), dot(_1104, _1122), dot(_1104, cross(_1118, _1122)));\n                float3 param_27 = _1131;\n                int _1135 = fa_cube_face(param_27);\n                int param_28 = _1135;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1162 = float2(dot(_1131, cross(param_29, param_30)), dot(_1131, param_30)) / max(dot(_1131, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1166 = _1135 / 3;\n                float2 param_31 = _1096.xy + (float2(float(_1135 - (_1166 * 3)), float(_1166)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1162.x), 0.5f - (0.5f * _1162.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _812 + 7;\n            float4 _1196 = fa_light_texel(param_33);\n            if (_1196.z > 0.5f)\n            {\n                int param_34 = _812 + 2;\n                int param_35 = _812 + 4;\n                int param_36 = _812 + 5;\n                float2 param_37 = _1196.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_816 && _1048)\n            {\n                int param_42 = _812 + 6;\n                float4 _1243 = fa_light_texel(param_42);\n                int param_43 = _812 + 7;\n                float4 _1248 = fa_light_texel(param_43);\n                bool _1251 = _1243.z > 0.5f;\n                bool _1258;\n                if (!_1251)\n                {\n                    _1258 = _1248.z > 0.5f;\n                }\n                else\n                {\n                    _1258 = _1251;\n                }\n                if (_1258)\n                {\n                    int param_44 = _812 + 2;\n                    float4 _1265 = fa_light_texel(param_44);\n                    float3 _1269 = normalize(_1265.xyz);\n                    int param_45 = _812 + 4;\n                    float4 _1274 = fa_light_texel(param_45);\n                    int param_46 = _812 + 5;\n                    float4 _1279 = fa_light_texel(param_46);\n                    if (_1251)\n                    {\n                        float3 _1287 = -to_light;\n                        float _1294 = _1265.w;\n                        float _1310 = 0.5f / max(dot(_1287, _1269) * (sqrt(max(1.0f - (_1294 * _1294), 0.0f)) / max(_1294, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1243.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1287, _1274.xyz) * _1310), 0.5f - (dot(_1287, _1279.xyz) * _1310));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1248.z > 0.5f)\n                    {\n                        float2 param_49 = _1248.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1269;\n                        float3 param_52 = _1274.xyz;\n                        float3 param_53 = _1279.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _5901 = _825.xyz * atten;\n    if (_816)\n    {\n        _5901 *= fa_light_tint;\n    }\n    int _1379;\n    if (_842)\n    {\n        _1379 = 0;\n    }\n    else\n    {\n        _1379 = ((_828 > 1.5f) && (_828 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _5912 = { l, _5901, atten, 1.0f, dist, _1379 };\n    return _5912;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4923 = n < 0;\n    bool _4930;\n    if (!_4923)\n    {\n        _4930 = n >= fa_light_count();\n    }\n    else\n    {\n        _4930 = _4923;\n    }\n    if (_4930)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4938 = fa_cl_light(param);\n    int param_1 = _4938;\n    float _4942 = fa_baked_keep(param_1);\n    if (_4942 <= 0.0f)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4938;\n    float3 param_3 = i.world_pos;\n    float3 param_4 = i.world_normal;\n    LightSample _4958 = fa_light_sample_n(param_2, param_3, param_4);\n    LightSample _6083 = { _4958.direction, _4958.color * _4942, _4958.attenuation * _4942, _4958.shadow, _4958._distance, _4958.type };\n    return _6083;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2168 = fa_shadow_depth(param, param_1);\n    float _2172;\n    if (conv.x < 0.5f)\n    {\n        _2172 = _2168;\n    }\n    else\n    {\n        _2172 = (conv.y * conv.z) / (conv.z - (_2168 * (conv.z - conv.y)));\n    }\n    return _2172;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel_turn(float2 d)\n{\n    return float2((d.x * (-0.737368881702423095703125f)) - (d.y * 0.675490319728851318359375f), (d.y * (-0.737368881702423095703125f)) + (d.x * 0.675490319728851318359375f));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2218 = fa_shadow_noise() * 6.283185482025146484375f;\n    float2 _2224 = float2(cos(_2218), sin(_2218));\n    float2 dir = _2224;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2233;\n        if (k < 0.0f)\n        {\n            _2233 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2233 = k;\n        }\n        float _2252 = clamp((_2233 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2271 = sqrt((float(i) + 0.5f) * 0.0625f) * _2252;\n            float2 param_3 = uv + (dir * (_2121_fa_shadow_bias.zw * _2271));\n            float4 param_4 = rect;\n            float3 param_5 = conv;\n            float _2285 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2285 < (zr - (_2271 * plane)))\n            {\n                sum += _2285;\n                cnt += 1.0f;\n            }\n            float2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2313 = sum / cnt;\n        float _2323;\n        if (k < 0.0f)\n        {\n            _2323 = (-k) / max(_2313, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2323 = k;\n        }\n        radius = clamp(((max(zr - _2313, 0.0f) * unit) * _2323) / texel_m, 1.5f, 16.0f);\n        dir = _2224;\n    }\n    float lit = 0.0f;\n    int _2349 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2349; i_1++)\n    {\n        float _2368 = sqrt((float(i_1) + 0.5f) / float(_2349)) * radius;\n        float2 param_7 = uv + (dir * (_2121_fa_shadow_bias.zw * _2368));\n        float4 param_8 = rect;\n        float3 param_9 = conv;\n        lit += float((zr - (_2368 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        float2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2349);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2573 = _468_fa_pbr.z < 0.5f;\n    bool _2580;\n    if (!_2573)\n    {\n        _2580 = _2121_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2580 = _2573;\n    }\n    if (_2580)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2121_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2593 = fa_light_texel(param);\n    float _2594 = _2593.x;\n    if (_2594 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2603 = int(_2594 + 0.5f);\n    int param_1 = _2603;\n    float4 _2607 = fa_light_texel(param_1);\n    int param_2 = _2603 + 1;\n    float4 _2612 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2615 = _2607.y;\n    if (_2615 > 0.0f)\n    {\n        float _2632 = 1.0f - smoothstep(0.75f * _2615, _2615, length(world - _2121_fa_shadow_eye.xyz));\n        fade = _2632;\n        if (_2632 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2607.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2656 = (_2603 + 2) + (face * 6);\n    int param_4 = _2656;\n    int param_5 = _2656 + 1;\n    int param_6 = _2656 + 3;\n    float4 _2670 = fa_light_texel(param_6);\n    int param_7 = _2656 + 4;\n    float4 _2675 = fa_light_texel(param_7);\n    int param_8 = _2656 + 5;\n    float4 _2680 = fa_light_texel(param_8);\n    float _2692 = _2680.x * max(dot(_2670, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2697 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2720 = clamp(dot(n, _2670.xyz), -1.0f, 1.0f);\n    float _2739 = min(sqrt(1.0f - (_2720 * _2720)) / max(abs(dot(n, world - lpos)) / max(dot(_2670, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2742 = _2612.y;\n    float _2744;\n    if (_2742 > 0.0f)\n    {\n        _2744 = _2742;\n    }\n    else\n    {\n        _2744 = 1.5f * _2692;\n    }\n    float4 _2764 = float4(world + (n * (_2744 * sqrt(1.0f - (_2697 * _2697)))), 1.0f);\n    float _2768 = dot(_2670, _2764);\n    float _2771 = _2680.y;\n    if (_2768 < _2771)\n    {\n        return 1.0f;\n    }\n    float2 _2786 = float2(dot(fa_light_texel(param_4), _2764), dot(fa_light_texel(param_5), _2764)) / _2768.xx;\n    float _2788 = _2786.x;\n    bool _2791 = _2788 < _2675.x;\n    bool _2800;\n    if (!_2791)\n    {\n        _2800 = _2788 > _2675.z;\n    }\n    else\n    {\n        _2800 = _2791;\n    }\n    bool _2809;\n    if (!_2800)\n    {\n        _2809 = _2786.y < _2675.y;\n    }\n    else\n    {\n        _2809 = _2800;\n    }\n    bool _2818;\n    if (!_2809)\n    {\n        _2818 = _2786.y > _2675.w;\n    }\n    else\n    {\n        _2818 = _2809;\n    }\n    if (_2818)\n    {\n        return 1.0f;\n    }\n    float _2824 = _2612.x;\n    float _2826;\n    if (_2824 > 0.0f)\n    {\n        _2826 = _2824;\n    }\n    else\n    {\n        _2826 = 1.5f * _2692;\n    }\n    float2 param_9 = _2786;\n    float4 param_10 = _2675;\n    float param_11 = _2768 - (_2826 * (1.0f + (0.5f * _2739)));\n    float param_12 = _2692;\n    float param_13 = 1.0f;\n    float param_14 = _2680.z * 0.25f;\n    float param_15 = (_2692 * min(_2739, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2771, _2680.z);\n    int param_17 = int(_2607.z + 0.5f);\n    float param_18 = _2607.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2111;\n    if (i == 0)\n    {\n        _2111 = _2121_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2127;\n        if (i == 1)\n        {\n            _2127 = _2121_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2135;\n            if (i == 2)\n            {\n                _2135 = _2121_fa_shadow_split.z;\n            }\n            else\n            {\n                _2135 = _2121_fa_shadow_split.w;\n            }\n            _2127 = _2135;\n        }\n        _2111 = _2127;\n    }\n    return _2111;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2414 = max(_2121_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2419 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2425 = sqrt(1.0f - (_2419 * _2419));\n    float _2433 = min(_2425 / max(_2419, 0.20000000298023223876953125f), 4.0f);\n    float _2438;\n    if (_2121_fa_shadow_bias.y > 0.0f)\n    {\n        _2438 = _2121_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2438 = 1.5f * _2121_fa_shadow_info[ci].x;\n    }\n    float4 _2463 = mul(float4(world + (n * (_2438 * _2425)), 1.0f), _2121_fa_shadow_mat[ci]);\n    float _2470 = _2463.x;\n    bool _2473 = _2470 < _2121_fa_shadow_rect[ci].x;\n    bool _2482;\n    if (!_2473)\n    {\n        _2482 = _2470 > _2121_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2482 = _2473;\n    }\n    bool _2491;\n    if (!_2482)\n    {\n        _2491 = _2463.y < _2121_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2491 = _2482;\n    }\n    bool _2500;\n    if (!_2491)\n    {\n        _2500 = _2463.y > _2121_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2500 = _2491;\n    }\n    bool _2507;\n    if (!_2500)\n    {\n        _2507 = _2463.z > 1.0f;\n    }\n    else\n    {\n        _2507 = _2500;\n    }\n    if (_2507)\n    {\n        return -1.0f;\n    }\n    float _2515;\n    if (_2121_fa_shadow_bias.x > 0.0f)\n    {\n        _2515 = _2121_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2515 = 1.5f * _2121_fa_shadow_info[ci].x;\n    }\n    float2 param = _2463.xy;\n    float4 param_1 = _2121_fa_shadow_rect[ci];\n    float param_2 = _2463.z - ((_2515 * (1.0f + (0.5f * _2433))) / _2414);\n    float param_3 = _2121_fa_shadow_info[ci].x;\n    float param_4 = _2414;\n    float param_5 = _2414 * 0.25f;\n    float param_6 = ((_2121_fa_shadow_info[ci].x * min(_2433, 3.0f)) * 0.5f) / _2414;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2121_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2121_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_468_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2893 = int(_2121_fa_shadow_cfg.x + 0.5f);\n    if (_2893 < 1)\n    {\n        return 1.0f;\n    }\n    float _2908 = dot(world - _2121_fa_shadow_eye.xyz, _2121_fa_shadow_fwd.xyz);\n    int param = _2893 - 1;\n    if (_2908 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2920 = _2893 > 1;\n    bool _2927;\n    if (_2920)\n    {\n        _2927 = _2908 > _2121_fa_shadow_split.x;\n    }\n    else\n    {\n        _2927 = _2920;\n    }\n    if (_2927)\n    {\n        ci = 1;\n    }\n    bool _2931 = _2893 > 2;\n    bool _2938;\n    if (_2931)\n    {\n        _2938 = _2908 > _2121_fa_shadow_split.y;\n    }\n    else\n    {\n        _2938 = _2931;\n    }\n    if (_2938)\n    {\n        ci = 2;\n    }\n    bool _2942 = _2893 > 3;\n    bool _2949;\n    if (_2942)\n    {\n        _2949 = _2908 > _2121_fa_shadow_split.z;\n    }\n    else\n    {\n        _2949 = _2942;\n    }\n    if (_2949)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    float s2 = -1.0f;\n    float t = 0.0f;\n    int _2960 = min(_2893, 4);\n    float _3001;\n    for (int c = ci; c < _2960; c++)\n    {\n        int param_1 = c;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2980 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0f)\n        {\n            s2 = _2980;\n            break;\n        }\n        if (_2980 < 0.0f)\n        {\n            continue;\n        }\n        s = _2980;\n        ci = c;\n        if (_2121_fa_shadow_cfg.y > 0.0f)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3001 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3001 = _2121_fa_shadow_fwd.w;\n            }\n            int param_6 = ci;\n            float _3020 = _2121_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _3001, 9.9999997473787516355514526367188e-05f);\n            int param_7 = ci;\n            t = clamp((_2908 - (fa_shadow_split_at(param_7) - _3020)) / _3020, 0.0f, 1.0f);\n        }\n        if (t <= 0.0f)\n        {\n            break;\n        }\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (t > 0.0f)\n    {\n        float _3052;\n        if ((ci + 1) < _2893)\n        {\n            _3052 = (s2 < 0.0f) ? s : s2;\n        }\n        else\n        {\n            _3052 = 1.0f;\n        }\n        s = lerp(s, _3052, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _4430 = _468_fa_ct_a.x < 0.5f;\n    bool _4437;\n    if (!_4430)\n    {\n        _4437 = _2121_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _4437 = _4430;\n    }\n    if (_4437)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2121_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _4450 = fa_light_texel(param);\n    float _4451 = _4450.y;\n    float len = _4451;\n    if (_4451 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4463 = length(world - _468_fa_camera_pos.xyz);\n    float _4473 = 1.0f - smoothstep(0.5f * _468_fa_ct_b.x, _468_fa_ct_b.x, _4463);\n    if (_4473 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _4479 = len;\n    float _4482 = min(_4479, 0.89999997615814208984375f * dist);\n    len = _4482;\n    float _4487 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _4463);\n    float _4492 = _4487 + (0.5f * _4482);\n    float3 _4498 = world + (gn * _4487);\n    float _4500 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4564;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4515 = (float(k) + _4500) * 0.083333335816860198974609375f;\n        float3 _4523 = _4498 + (l * (_4515 * len));\n        float4 _4529 = float4(_4523, 1.0f);\n        float _4535 = dot(_468_fa_ct_vpw, _4529);\n        if (_4535 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4555 = float2(dot(_468_fa_ct_vpx, _4529), dot(_468_fa_ct_vpy, _4529)) / _4535.xx;\n        float _4559 = _4555.x * 0.5f;\n        float _4560 = _4559 + 0.5f;\n        if (_468_fa_ct_a.y > 0.5f)\n        {\n            _4564 = (_4555.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4564 = 0.5f - (_4555.y * 0.5f);\n        }\n        bool _4580 = _4560 < 0.0f;\n        bool _4587;\n        if (!_4580)\n        {\n            _4587 = _4560 >= 1.0f;\n        }\n        else\n        {\n            _4587 = _4580;\n        }\n        bool _4594;\n        if (!_4587)\n        {\n            _4594 = _4564 < 0.0f;\n        }\n        else\n        {\n            _4594 = _4587;\n        }\n        bool _4601;\n        if (!_4594)\n        {\n            _4601 = _4564 >= 1.0f;\n        }\n        else\n        {\n            _4601 = _4594;\n        }\n        if (_4601)\n        {\n            break;\n        }\n        float4 _4628 = fa_screen_tex.Load(int3(clamp(int2(float2(_4560, _4564) * _468_fa_ct_a.zw), int2(0, 0), int2(_468_fa_ct_a.zw) - int2(1, 1)), 0));\n        if (_4628.w < 0.5f)\n        {\n            continue;\n        }\n        float _4647 = (dot(_468_fa_ct_fwd.xyz, _4523) + _468_fa_ct_fwd.w) - _4628.x;\n        if ((_4647 > _4487) && (_4647 < _4492))\n        {\n            occ = max(occ, (1.0f - (_4515 * _4515)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4560, 0.5f - _4559), min(_4564, 1.0f - _4564))));\n        }\n    }\n    return 1.0f - (occ * _4473);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4750 = fa_baked_keep(param);\n    if (_4750 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _6045 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _6045;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4776 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _6047 = _4776.color;\n    float _6048 = _4776.attenuation;\n    float _6049 = _4776.shadow;\n    bool _4779 = _4776.type == 0;\n    if (_4779 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4776.direction;\n        float _4790 = fa_shadow_factor(param_5, param_6);\n        _6049 = _4790;\n        _6047 *= _4790;\n    }\n    else\n    {\n        bool _4801 = _4776.type != 0;\n        bool _4807;\n        if (_4801)\n        {\n            _4807 = _6048 > 0.0f;\n        }\n        else\n        {\n            _4807 = _4801;\n        }\n        if (_4807)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4776.direction;\n            float _4826 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6049 = _4826;\n            _6047 *= _4826;\n        }\n    }\n    bool _4836 = _468_fa_ct_a.x > 0.5f;\n    bool _4842;\n    if (_4836)\n    {\n        _4842 = _6048 > 0.0f;\n    }\n    else\n    {\n        _4842 = _4836;\n    }\n    if (_4842)\n    {\n        float _4849;\n        if (_4779)\n        {\n            _4849 = 1000000000.0f;\n        }\n        else\n        {\n            _4849 = _4776._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4776.direction;\n        float param_18 = _4849;\n        float _4867 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6049 *= _4867;\n        _6047 *= _4867;\n    }\n    float _4880 = _6048;\n    float _4881 = _4880 * _4750;\n    _6048 = _4881;\n    float3 _4885 = _6047;\n    float3 _4886 = _4885 * _4750;\n    _6047 = _4886;\n    LightSample _6064 = { _4776.direction, _4886, _4881, _6049, _4776._distance, _4776.type };\n    return _6064;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4897 = n < 0;\n    bool _4904;\n    if (!_4897)\n    {\n        _4904 = n >= fa_light_count();\n    }\n    else\n    {\n        _4904 = _4897;\n    }\n    if (_4904)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    LightSample _4919 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4919;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3815 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3823 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3826 = int(_3815);\n    int _3829 = int(_3823);\n    float _3839 = _3823 - float(_3829);\n    int _3895 = (_3826 * 9) + _3829;\n    int _3915 = ((_3826 + 1) * 9) + _3829;\n    return lerp(lerp(_3890[_3895], _3890[_3895 + 1], _3839), lerp(_3890[_3915], _3890[_3915 + 1], _3839), _3815 - float(_3826));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _5913 = false;\n    float _5914 = 1.0f;\n    float _5915 = 1.0f;\n    float _5916 = 1.0f;\n    float _5917 = 0.0f;\n    float _5918 = 0.0f;\n    float _5919 = 0.0f;\n    float _5920 = 0.0f;\n    float _5922 = 1.0f;\n    bool _5923 = false;\n    float3 _5924 = 0.0f.xxx;\n    float _5925 = 1.0f;\n    float _5926 = 1.0f;\n    float _5927 = 1.0f;\n    float _5928 = 0.0f;\n    float _5929 = 0.0f;\n    float3 _5930 = float3(1.0f, 0.0f, 0.0f);\n    float3 _5931 = float3(0.0f, 0.0f, 1.0f);\n    float _5932 = 1.0f;\n    float _5933 = 1.0f;\n    float _3966 = clamp(s.specular, 0.0f, 1.0f);\n    float _3970 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3975 = (_3966 != 1.0f) || (_3970 != 1.5f);\n    bool _3984;\n    if (!_3975)\n    {\n        _3984 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3984 = _3975;\n    }\n    if (_3984)\n    {\n        float _3992 = (_3970 - 1.0f) / (_3970 + 1.0f);\n        f0 = lerp(min((_3992 * _3992).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3966, s.albedo, metallic.xxx);\n        _5914 = lerp(_3966, 1.0f, metallic);\n        _5913 = true;\n    }\n    float _4019 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_4019 > 0.0f)\n    {\n        float _4027 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _5917 = _4019;\n        _5918 = _4027;\n        float _4034 = _4027 * _4027;\n        _5919 = _4034;\n        _5920 = _4034 * _4034;\n        float _4046 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _5922 = _4046;\n        _5915 = 1.0f - (_4019 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _4046, 0.0f, 1.0f), 5.0f))));\n        _5913 = true;\n    }\n    float3 _4065 = max(s.sheen_color, 0.0f.xxx);\n    float _4074 = max(_4065.x, max(_4065.y, _4065.z));\n    if (_4074 > 0.0f)\n    {\n        float _4082 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _5923 = true;\n        _5924 = _4065;\n        _5925 = _4082;\n        _5926 = _4082 * _4082;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _4082;\n        float _4099 = fa_sheen_albedo(param, param_1);\n        _5928 = _4099;\n        _5927 = 1.0f - min(_4074 * _4099, 1.0f);\n        _5913 = true;\n    }\n    _5916 = _5915 * _5927;\n    float _4118 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_4118 != 0.0f)\n    {\n        float3 _4133 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _4133;\n        if (dot(_4133, _4133) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _4145 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_4145.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _4145.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _4145.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _4149 = t;\n        float3 _4150 = normalize(_4149);\n        t = _4150;\n        float3 _4175 = normalize((_4150 * cos(s.anisotropy_rotation)) + ((cross(n, _4150) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _5930 = _4175;\n        _5931 = cross(n, _4175);\n        float _4185 = roughness * roughness;\n        float _4191 = lerp(_4185, 1.0f, _4118 * _4118);\n        bool _4193 = _4118 > 0.0f;\n        _5932 = _4193 ? _4191 : _4185;\n        _5933 = _4193 ? _4185 : _4191;\n        _5929 = _4118;\n        _5913 = true;\n    }\n    FaLayers _5955 = { _5913, _5914, _5915, _5916, _5917, _5918, _5919, _5920, i.world_normal, _5922, _5923, _5924, _5925, _5926, _5927, _5928, _5929, _5930, _5931, _5932, _5933 };\n    return _5955;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3747 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3750 = _3747.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3750 * _3750, exp2((-9.27999973297119140625f) * ndv)) * _3750) + _3747.y)) + _3747.zw;\n}\n\nfloat2 fa_oct_encode(float3 d)\n{\n    float3 _3182 = d / max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13f).xxx;\n    float _3185 = _3182.x;\n    float _3187 = _3182.z;\n    float2 e = float2(_3185, _3187);\n    if (_3182.y < 0.0f)\n    {\n        e = float2((1.0f - abs(_3187)) * ((_3185 < 0.0f) ? (-1.0f) : 1.0f), (1.0f - abs(_3185)) * ((_3187 < 0.0f) ? (-1.0f) : 1.0f));\n    }\n    return e;\n}\n\nfloat2 fa_atlas_size()\n{\n    uint _3221_dummy_parameter;\n    return float2(int2(spvTextureSize(fa_probe_atlas, uint(0), _3221_dummy_parameter)));\n}\n\nfloat3 fa_probe_level(float2 origin, float res, int lv, float2 e)\n{\n    float _3234;\n    if (lv == 0)\n    {\n        _3234 = 0.0f;\n    }\n    else\n    {\n        _3234 = res + 2.0f;\n    }\n    float _3244;\n    if (lv == 0)\n    {\n        _3244 = 0.0f;\n    }\n    else\n    {\n        _3244 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0f * float(lv - 1));\n    }\n    return fa_probe_atlas.SampleLevel(fa_env_smp, (((origin + float2(_3234, _3244)) + 1.0f.xx) + (((e * 0.5f) + 0.5f.xx) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0f).xyz;\n}\n\nfloat3 fa_probe_radiance(float2 origin, float res, float3 d, float rough)\n{\n    float _3290;\n    if (res > 64.5f)\n    {\n        _3290 = 5.0f;\n    }\n    else\n    {\n        _3290 = (res > 32.5f) ? 4.0f : 3.0f;\n    }\n    float _3305 = clamp(rough, 0.0f, 1.0f) * (_3290 - 1.0f);\n    int _3312 = int(min(floor(_3305), _3290 - 2.0f));\n    float _3317 = _3305 - float(_3312);\n    float3 param = d;\n    float2 _3321 = fa_oct_encode(param);\n    float2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3312;\n    float2 param_4 = _3321;\n    float3 _3331 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3317 < 0.00200000009499490261077880859375f)\n    {\n        return _3331;\n    }\n    float2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3312 + 1;\n    float2 param_8 = _3321;\n    return lerp(_3331, fa_probe_level(param_5, param_6, param_7, param_8), _3317.xxx);\n}\n\nfloat3 fa_probe_box_dir(float3 d, float4 posw, float4 bx, float4 by, float4 bz)\n{\n    if (posw.w < 0.5f)\n    {\n        return d;\n    }\n    float _3369 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3376 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3383 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3389 = dot(bx.xyz, d);\n    float _3393 = dot(by.xyz, d);\n    float _3397 = dot(bz.xyz, d);\n    float _3403;\n    if (_3389 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3403 = (1.0f - _3369) / _3389;\n    }\n    else\n    {\n        float _3417;\n        if (_3389 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3417 = ((-1.0f) - _3369) / _3389;\n        }\n        else\n        {\n            _3417 = 1000000015047466219876688855040.0f;\n        }\n        _3403 = _3417;\n    }\n    float tx = _3403;\n    float _3434;\n    if (_3393 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3434 = (1.0f - _3376) / _3393;\n    }\n    else\n    {\n        float _3447;\n        if (_3393 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3447 = ((-1.0f) - _3376) / _3393;\n        }\n        else\n        {\n            _3447 = 1000000015047466219876688855040.0f;\n        }\n        _3434 = _3447;\n    }\n    float ty = _3434;\n    float _3463;\n    if (_3397 > 9.9999999747524270787835121154785e-07f)\n    {\n        _3463 = (1.0f - _3383) / _3397;\n    }\n    else\n    {\n        float _3476;\n        if (_3397 < (-9.9999999747524270787835121154785e-07f))\n        {\n            _3476 = ((-1.0f) - _3383) / _3397;\n        }\n        else\n        {\n            _3476 = 1000000015047466219876688855040.0f;\n        }\n        _3463 = _3476;\n    }\n    float _3488 = tx;\n    float _3491 = (_3488 > 0.0f) ? _3488 : 1000000015047466219876688855040.0f;\n    tx = _3491;\n    float _3492 = ty;\n    float _3495 = (_3492 > 0.0f) ? _3492 : 1000000015047466219876688855040.0f;\n    ty = _3495;\n    float _3505 = min(_3491, min(_3495, (_3463 > 0.0f) ? _3463 : 1000000015047466219876688855040.0f));\n    if (_3505 > 100000001504746621987668885504.0f)\n    {\n        return d;\n    }\n    float3 _3521 = (fa_world_pos + (d * _3505)) - posw.xyz;\n    float3 _3526;\n    if (dot(_3521, _3521) > 1.0000000133514319600180897396058e-10f)\n    {\n        _3526 = normalize(_3521);\n    }\n    else\n    {\n        _3526 = d;\n    }\n    return _3526;\n}\n\nfloat3 fa_probe_environment(float4 tile, float4 posw, float4 bx, float4 by, float4 bz, inout float3 d, float rough)\n{\n    float3 param = d;\n    float4 param_1 = posw;\n    float4 param_2 = bx;\n    float4 param_3 = by;\n    float4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    float2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    float3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    float _3572 = (1.0f - _468_fa_rpa_tile.w) - _468_fa_rpb_tile.w;\n    float3 outc = 0.0f.xxx;\n    if (_3572 > 0.0005000000237487256526947021484375f)\n    {\n        float3 base;\n        if (_468_fa_env_sky.w > 0.5f)\n        {\n            float2 param = _468_fa_atlas.zw;\n            float param_1 = 128.0f;\n            float3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3602 = rough * rough;\n            float _3633 = 0.60000002384185791015625f * _3602;\n            base = lerp(lerp(_468_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_468_fa_env_horizon.xyz, _468_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3602)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3633, 0.0500000007450580596923828125f + _3633, d.y).xxx), ((_468_fa_env_sky.xyz + _468_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3602 * 0.60000002384185791015625f).xxx);\n        }\n        outc = base * _3572;\n    }\n    if (_468_fa_rpa_tile.w > 0.0f)\n    {\n        float4 param_4 = _468_fa_rpa_tile;\n        float4 param_5 = _468_fa_rpa_pos;\n        float4 param_6 = _468_fa_rpa_bx;\n        float4 param_7 = _468_fa_rpa_by;\n        float4 param_8 = _468_fa_rpa_bz;\n        float3 param_9 = d;\n        float param_10 = rough;\n        float3 _3692 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3692 * _468_fa_rpa_tile.w);\n    }\n    if (_468_fa_rpb_tile.w > 0.0f)\n    {\n        float4 param_11 = _468_fa_rpb_tile;\n        float4 param_12 = _468_fa_rpb_pos;\n        float4 param_13 = _468_fa_rpb_bx;\n        float4 param_14 = _468_fa_rpb_by;\n        float4 param_15 = _468_fa_rpb_bz;\n        float3 param_16 = d;\n        float param_17 = rough;\n        float3 _3724 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3724 * _468_fa_rpb_tile.w);\n    }\n    return outc;\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness, float occlusion)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _4226;\n        if (L.aniso >= 0.0f)\n        {\n            _4226 = L.b;\n        }\n        else\n        {\n            _4226 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_4226, v), _4226), (abs(L.aniso) * smoothstep(0.0f, 0.25f, roughness)).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _4262 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _4262.x) + (L.f90.xxx * _4262.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _4320 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _4320.x) + _4320.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3789 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3789.x) + _3789.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4359 = clamp(s.metallic, 0.0f, 1.0f);\n    float _4363 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _4370 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _4359.xxx);\n    float3 f0 = _4370;\n    float3 _4374 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _4374;\n    float3 param_3 = i.view_dir;\n    float param_4 = _4359;\n    float param_5 = _4363;\n    float3 param_6 = _4370;\n    FaLayers _4391 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4391.on)\n    {\n        FaLayers param_7 = _4391;\n        float3 param_8 = _4374;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _4363;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    float3 param_13 = _4374;\n    float3 param_14 = i.view_dir;\n    float3 param_15 = f0;\n    float param_16 = _4363;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _4989 = fa_light_unshadowed(param, param_1);\n        float _4997 = dot(_4989.color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_4997 > bestPower)\n        {\n            bestPower = _4997;\n            best = n;\n        }\n    }\n    float3 lit = (_468_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _5026 = fa_light(param_2, param_3);\n        float _5034;\n        if (dot(s.normal, _5026.direction) > 0.5f)\n        {\n            _5034 = 1.0f;\n        }\n        else\n        {\n            _5034 = _5040_dark;\n        }\n        lit += ((s.albedo * _5026.color) * _5034);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _5040_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2121_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3080 = int(_2121_fa_shadow_cfg.x + 0.5f);\n    float _3090 = dot(world - _2121_fa_shadow_eye.xyz, _2121_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3095 = _3080 > 0;\n    bool _3104;\n    if (_3095)\n    {\n        int param = _3080 - 1;\n        _3104 = _3090 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3104 = _3095;\n    }\n    if (_3104)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3110 = _3080 > 1;\n        bool _3117;\n        if (_3110)\n        {\n            _3117 = _3090 > _2121_fa_shadow_split.x;\n        }\n        else\n        {\n            _3117 = _3110;\n        }\n        if (_3117)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3123 = _3080 > 2;\n        bool _3130;\n        if (_3123)\n        {\n            _3130 = _3090 > _2121_fa_shadow_split.y;\n        }\n        else\n        {\n            _3130 = _3123;\n        }\n        if (_3130)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3136 = _3080 > 3;\n        bool _3143;\n        if (_3136)\n        {\n            _3143 = _3090 > _2121_fa_shadow_split.z;\n        }\n        else\n        {\n            _3143 = _3136;\n        }\n        if (_3143)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5767 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5767 = -_5767;\n    }\n    float3 _5437 = normalize(_468_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5780 = { fa_world_pos, _5767, fa_world_tangent, fa_uv, fa_vertex_color, _5437, gl_FrontFacing };\n    SurfaceInput param_1 = _5780;\n    Surface _5445 = fa_standard_surface(param_1);\n    float3 _5798 = _5445.albedo;\n    float _5799 = _5445.alpha;\n    float3 _5800 = _5445.normal;\n    float _5801 = _5445.metallic;\n    float _5802 = _5445.roughness;\n    float _5803 = _5445.occlusion;\n    float3 _5804 = _5445.emission;\n    float _5805 = _5445.clearcoat;\n    float _5806 = _5445.clearcoat_roughness;\n    float3 _5807 = _5445.sheen_color;\n    float _5808 = _5445.sheen_roughness;\n    float _5809 = _5445.anisotropy;\n    float _5810 = _5445.anisotropy_rotation;\n    float _5811 = _5445.specular;\n    float _5812 = _5445.ior;\n    float3 _5813 = _5445.specular_color;\n    float _5814 = _5445.transmission;\n    float _5815 = _5445.thickness;\n    float3 _5816 = _5445.attenuation_color;\n    float _5817 = _5445.attenuation_distance;\n    SurfaceInput _5788 = { fa_world_pos, _5767, fa_world_tangent, fa_uv, fa_vertex_color, _5437, gl_FrontFacing };\n    SurfaceInput param_2 = _5788;\n    Surface param_3 = _5445;\n    surface(param_2, param_3);\n    _5798 = param_3.albedo;\n    _5799 = param_3.alpha;\n    _5800 = param_3.normal;\n    _5801 = param_3.metallic;\n    _5802 = param_3.roughness;\n    _5803 = param_3.occlusion;\n    _5804 = param_3.emission;\n    _5805 = param_3.clearcoat;\n    _5806 = param_3.clearcoat_roughness;\n    _5807 = param_3.sheen_color;\n    _5808 = param_3.sheen_roughness;\n    _5809 = param_3.anisotropy;\n    _5810 = param_3.anisotropy_rotation;\n    _5811 = param_3.specular;\n    _5812 = param_3.ior;\n    _5813 = param_3.specular_color;\n    _5814 = param_3.transmission;\n    _5815 = param_3.thickness;\n    _5816 = param_3.attenuation_color;\n    _5817 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5767;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5798 = param_6;\n    _5800 = param_7;\n    float3 result;\n    if (_468_fa_emissive.w > 0.5f)\n    {\n        result = _5798;\n    }\n    else\n    {\n        float3 _5484 = _5800;\n        float3 _5485 = normalize(_5484);\n        _5800 = _5485;\n        SurfaceInput _5796 = { fa_world_pos, _5767, fa_world_tangent, fa_uv, fa_vertex_color, _5437, gl_FrontFacing };\n        SurfaceInput param_8 = _5796;\n        Surface _5899 = { _5798, _5799, _5485, _5801, _5802, _5803, _5804, _5805, _5806, _5807, _5808, _5809, _5810, _5811, _5812, _5813, _5814, _5815, _5816, _5817 };\n        Surface param_9 = _5899;\n        float3 _5496 = lighting(param_8, param_9);\n        result = _5496;\n    }\n    float3 _5500 = result;\n    float3 _5501 = _5500 + _5804;\n    result = _5501;\n    float3 param_10 = _5501;\n    float3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _5510 = _468_fa_fog.w > 0.0f;\n    bool _5517;\n    if (!_5510)\n    {\n        _5517 = _468_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _5517 = _5510;\n    }\n    if (_5517)\n    {\n        float3 _5526 = fa_world_pos - _468_fa_camera_pos.xyz;\n        float _5532 = dot(_5526, _468_fa_fog_c.xyz);\n        bool _5536 = _468_fa_fog_c.w > 0.5f;\n        float _5537;\n        if (_5536)\n        {\n            _5537 = _5532;\n        }\n        else\n        {\n            _5537 = length(_5526);\n        }\n        float _5549 = _5537 - _468_fa_fog_b.x;\n        if (_5549 > 0.0f)\n        {\n            float _5558 = _468_fa_fog.w * _5549;\n            float tau = _5558 * _5558;\n            if (_468_fa_fog_b.y > 0.0f)\n            {\n                float _5574;\n                if (_5536)\n                {\n                    _5574 = fa_world_pos.y - (_468_fa_fog_c.y * _5532);\n                }\n                else\n                {\n                    _5574 = _468_fa_camera_pos.y;\n                }\n                float _5595 = lerp(_5574, fa_world_pos.y, clamp(_468_fa_fog_b.x / _5537, 0.0f, 1.0f));\n                float _5599 = fa_world_pos.y - _5595;\n                float _5604 = _5595 - _468_fa_fog_b.z;\n                float _5609 = fa_world_pos.y - _468_fa_fog_b.z;\n                bool _5612 = _5604 <= 0.0f;\n                bool _5613 = !_5612;\n                bool _5619;\n                if (_5613)\n                {\n                    _5619 = _468_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5619 = _5612;\n                }\n                float _5620;\n                if (_5619)\n                {\n                    _5620 = _468_fa_fog_b.y;\n                }\n                else\n                {\n                    _5620 = _468_fa_fog_b.y * exp(-min(_468_fa_fog_b.w * _5604, 80.0f));\n                }\n                bool _5647;\n                if (_5613)\n                {\n                    _5647 = _468_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5647 = _5612;\n                }\n                float _5648;\n                if (_5647)\n                {\n                    _5648 = _468_fa_fog_b.y * _5604;\n                }\n                else\n                {\n                    _5648 = (_468_fa_fog_b.y * (1.0f - exp(-min(_468_fa_fog_b.w * _5604, 80.0f)))) / _468_fa_fog_b.w;\n                }\n                bool _5673 = _5609 <= 0.0f;\n                bool _5680;\n                if (!_5673)\n                {\n                    _5680 = _468_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5680 = _5673;\n                }\n                float _5681;\n                if (_5680)\n                {\n                    _5681 = _468_fa_fog_b.y * _5609;\n                }\n                else\n                {\n                    _5681 = (_468_fa_fog_b.y * (1.0f - exp(-min(_468_fa_fog_b.w * _5609, 80.0f)))) / _468_fa_fog_b.w;\n                }\n                float _5708;\n                if (abs(_5599) < 0.001000000047497451305389404296875f)\n                {\n                    _5708 = _5620;\n                }\n                else\n                {\n                    _5708 = (_5681 - _5648) / _5599;\n                }\n                tau += (_5549 * max(_5708, 0.0f));\n            }\n            result = lerp(result, _468_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5799);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_5040",
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
