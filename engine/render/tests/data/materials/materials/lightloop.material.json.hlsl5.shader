{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "4155841b00106f1351e36fe7e96d502ece90660dd797ea3c7df876d511a0f129",
  "slang": "hlsl5",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _263 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _263;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mul(float4(_270, 1.0f), _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3354[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _5741 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _430_fa_camera_pos : packoffset(c0);\n    float4 _430_fa_ambient : packoffset(c1);\n    float4 _430_fa_base_color : packoffset(c2);\n    float4 _430_fa_emissive : packoffset(c3);\n    float4 _430_fa_model_emissive : packoffset(c4);\n    float4 _430_fa_pbr : packoffset(c5);\n    float4 _430_fa_maps : packoffset(c6);\n    float4 _430_fa_fog : packoffset(c7);\n    float4 _430_fa_fog_b : packoffset(c8);\n    float4 _430_fa_fog_c : packoffset(c9);\n    float4 _430_fa_counts : packoffset(c10);\n    float4 _430_fa_env_sky : packoffset(c11);\n    float4 _430_fa_env_horizon : packoffset(c12);\n    float4 _430_fa_time : packoffset(c13);\n    float4 _430_fa_cl_vpx : packoffset(c14);\n    float4 _430_fa_cl_vpy : packoffset(c15);\n    float4 _430_fa_cl_vpw : packoffset(c16);\n    float4 _430_fa_cl_fwd : packoffset(c17);\n    float4 _430_fa_cl_grid : packoffset(c18);\n    float4 _430_fa_cl_info : packoffset(c19);\n    float4 _430_fa_layers_a : packoffset(c20);\n    float4 _430_fa_layers_b : packoffset(c21);\n    float4 _430_fa_layers_c : packoffset(c22);\n    float4 _430_fa_layers_d : packoffset(c23);\n    float4 _430_fa_ct_a : packoffset(c24);\n    float4 _430_fa_ct_b : packoffset(c25);\n    float4 _430_fa_ct_vpx : packoffset(c26);\n    float4 _430_fa_ct_vpy : packoffset(c27);\n    float4 _430_fa_ct_vpw : packoffset(c28);\n    float4 _430_fa_ct_fwd : packoffset(c29);\n    float4 _430_fa_tr_a : packoffset(c30);\n    float4 _430_fa_tr_b : packoffset(c31);\n    float4 _430_fa_probe_sh[9] : packoffset(c32);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2088_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2088_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2088_fa_shadow_info[4] : packoffset(c20);\n    float4 _2088_fa_shadow_split : packoffset(c24);\n    float4 _2088_fa_shadow_cfg : packoffset(c25);\n    float4 _2088_fa_shadow_bias : packoffset(c26);\n    float4 _2088_fa_shadow_eye : packoffset(c27);\n    float4 _2088_fa_shadow_fwd : packoffset(c28);\n    float4 _2088_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _4491_dark : packoffset(c0);\n    float _4491_fa_pad0 : packoffset(c0.y);\n    float _4491_fa_pad1 : packoffset(c0.z);\n    float _4491_fa_pad2 : packoffset(c0.w);\n    float _4491_skyAmount : packoffset(c1);\n    float _4491_fa_pad3 : packoffset(c1.y);\n    float _4491_fa_pad4 : packoffset(c1.z);\n    float _4491_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t9);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_screen_tex : register(t10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1359 = _430_fa_cl_info.x < 0.0f;\n    bool _1366;\n    if (!_1359)\n    {\n        _1366 = _430_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1366 = _1359;\n    }\n    bool _1374;\n    if (!_1366)\n    {\n        _1374 = _430_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1374 = _1366;\n    }\n    bool _1381;\n    if (!_1374)\n    {\n        _1381 = _430_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1381 = _1374;\n    }\n    bool _1388;\n    if (!_1381)\n    {\n        _1388 = _430_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1388 = _1381;\n    }\n    if (_1388)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1398 = float4(world_pos, 1.0f);\n    float _1404 = dot(_430_fa_cl_vpw, _1398);\n    if (!(_1404 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1426 = float2(dot(_430_fa_cl_vpx, _1398), dot(_430_fa_cl_vpy, _1398)) / _1404.xx;\n    int _1430 = int(_430_fa_cl_grid.x);\n    int _1434 = int(_430_fa_cl_grid.y);\n    int param = (int(_430_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_430_fa_cl_fwd.xyz, world_pos) + _430_fa_cl_fwd.w, _430_fa_cl_grid.w) / _430_fa_cl_grid.w) * _430_fa_cl_grid.z)), 0, int(_430_fa_cl_info.y) - 1) * _1434) + clamp(int(floor(((_1426.y * 0.5f) + 0.5f) * _430_fa_cl_grid.y)), 0, _1434 - 1)) * _1430)) + clamp(int(floor(((_1426.x * 0.5f) + 0.5f) * _430_fa_cl_grid.x)), 0, _1430 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1510 = fa_cluster_texel(param);\n    return int2(int(_1510.x), int(_1510.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_430_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4175 = fa_cluster_lookup(param);\n    fa_cl_slot = _4175.x;\n    fa_cl_local = _4175.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4552 = fa_linear_to_srgb(param);\n        c = _4552;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4560 = fa_srgb_to_linear(param_1);\n            c = _4560;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _310;\n    if (i.front_facing)\n    {\n        _310 = i.world_normal;\n    }\n    else\n    {\n        _310 = -i.world_normal;\n    }\n    float3 _334 = normalize(i.world_tangent.xyz - (_310 * dot(_310, i.world_tangent.xyz)));\n    float3 _362 = normalize(((_334 * m.x) + ((cross(_310, _334) * i.world_tangent.w) * m.y)) + (_310 * m.z));\n    float3 _365;\n    if (i.front_facing)\n    {\n        _365 = _362;\n    }\n    else\n    {\n        _365 = -_362;\n    }\n    return _365;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _430_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4591 = fa_tex_fix(param_2, param_3);\n    float4 _5704 = base_t;\n    _5704.x = _4591.x;\n    _5704.y = _4591.y;\n    _5704.z = _4591.z;\n    base_t = _5704;\n    float4 _4605 = (_5704 * _430_fa_base_color) * i.vertex_color;\n    float3 _5535 = i.world_normal;\n    if (_430_fa_maps.z > 0.5f)\n    {\n        float param_4 = _430_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4637 = fa_tex_fix(param_6, param_7);\n        float3 _4640 = (_4637 * 2.0f) - 1.0f.xxx;\n        float2 _4645 = _4640.xy * _430_fa_maps.x;\n        float3 _5712 = _4640;\n        _5712.x = _4645.x;\n        _5712.y = _4645.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5712;\n        _5535 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _430_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4673 = fa_tex_fix(param_12, param_13);\n    float4 _5715 = mrt;\n    _5715.x = _4673.x;\n    _5715.y = _4673.y;\n    _5715.z = _4673.z;\n    mrt = _5715;\n    float4 _4701 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _430_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4701.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4712 = fa_tex_fix(param_16, param_17);\n    float param_18 = _430_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4742 = fa_tex_fix(param_20, param_21);\n    float _5540 = _430_fa_layers_a.x;\n    float _5541 = _430_fa_layers_a.y;\n    float _5544 = _430_fa_layers_a.z;\n    float _5543 = _430_fa_layers_b.w;\n    float _5546 = _430_fa_layers_c.x;\n    if (_430_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_430_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _5540 *= _4712.y;\n            _5541 *= _4712.z;\n            _5543 *= _4701.w;\n        }\n        if (_430_fa_layers_c.z > 1.5f)\n        {\n            _5544 *= mrt.x;\n            _5546 *= mrt.w;\n        }\n    }\n    Surface _5573 = { _4605.xyz, _4605.w, _5535, clamp(_430_fa_pbr.x * _4673.z, 0.0f, 1.0f), clamp(_430_fa_pbr.y * _4673.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_430_fa_maps.y * (_4712.x - 1.0f)), _430_fa_emissive.xyz + (_430_fa_model_emissive.xyz * _4742), _5540, _5541, _430_fa_layers_b.xyz, _5543, _5544, _430_fa_layers_a.w, _5546, _430_fa_layers_c.y, _430_fa_layers_d.xyz, _430_fa_tr_a.x, _430_fa_tr_a.y, _430_fa_tr_b.xyz, _430_fa_tr_a.z };\n    return _5573;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1590 = rect.zw - rect.xy;\n    float2 _1594 = _1590 * atlas;\n    float2 _1598 = ddx * _1594;\n    float2 _1602 = ddy * _1594;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1590), clamp(0.5f * log2(max(max(dot(_1598, _1598), dot(_1602, _1602)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1635 = _430_fa_counts.y < 0.5f;\n    bool _1642;\n    if (!_1635)\n    {\n        _1642 = _430_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1642 = _1635;\n    }\n    if (_1642)\n    {\n        return;\n    }\n    float3 _1648 = ddx(world_pos);\n    float3 _1651 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1655 = fa_cluster_texel(param);\n    int _1659 = int(_1655.w);\n    if (_1659 < 1)\n    {\n        return;\n    }\n    int _1669 = int(_430_fa_counts.y + 0.5f);\n    int param_1 = _1669;\n    float4 _1673 = fa_light_texel(param_1);\n    float2 _1676 = _1673.yz;\n    int _1680 = int(_1673.w);\n    int param_2 = _1669 + 1;\n    float4 _1685 = fa_light_texel(param_2);\n    float _1686 = _1685.x;\n    int _1692 = int(_430_fa_counts.w + 0.5f) - 1;\n    int _1696 = int(_1655.z);\n    float3 _1961;\n    for (int k = 0; k < _1659; k++)\n    {\n        int _1709 = _1696 + k;\n        int param_3 = _1680 + (_1709 >> 2);\n        int _1726 = (_1669 + 2) + (int(fa_light_texel(param_3)[_1709 & 3]) * 7);\n        int param_4 = _1726 + 6;\n        float4 _1731 = fa_light_texel(param_4);\n        if (((int(_1731.w + 0.5f) >> _1692) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1726;\n        float4 _1746 = fa_light_texel(param_5);\n        int param_6 = _1726 + 1;\n        float4 _1751 = fa_light_texel(param_6);\n        int param_7 = _1726 + 2;\n        float4 _1756 = fa_light_texel(param_7);\n        float3 _1759 = _1746.xyz;\n        float _1764 = dot(_1759, world_pos) + _1746.w;\n        float3 _1766 = _1751.xyz;\n        float _1771 = dot(_1766, world_pos) + _1751.w;\n        float3 _1773 = _1756.xyz;\n        float _1778 = dot(_1773, world_pos) + _1756.w;\n        bool _1783 = abs(_1764) > 0.5f;\n        bool _1791;\n        if (!_1783)\n        {\n            _1791 = abs(_1771) > 0.5f;\n        }\n        else\n        {\n            _1791 = _1783;\n        }\n        bool _1799;\n        if (!_1791)\n        {\n            _1799 = abs(_1778) > 0.5f;\n        }\n        else\n        {\n            _1799 = _1791;\n        }\n        if (_1799)\n        {\n            continue;\n        }\n        float _1814 = clamp(dot(geo_normal, normalize(_1773)) * _1731.z, 0.0f, 1.0f);\n        if (_1814 <= 0.0f)\n        {\n            continue;\n        }\n        float _1834 = (clamp((0.5f - abs(_1778)) * 10.0f, 0.0f, 1.0f) * _1814) * _1731.x;\n        float2 _1842 = float2(_1764 + 0.5f, 0.5f - _1771);\n        float2 _1852 = float2(dot(_1759, _1648), dot(_1766, _1648));\n        float2 _1862 = float2(dot(_1759, _1651), dot(_1766, _1651));\n        int param_8 = _1726 + 5;\n        float4 _1867 = fa_light_texel(param_8);\n        int param_9 = _1726 + 3;\n        float4 _1872 = fa_light_texel(param_9);\n        int param_10 = _1726 + 4;\n        float4 _1877 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1867.xyz;\n        bool _1887 = _1872.z > _1872.x;\n        if (_1887)\n        {\n            float4 param_11 = _1872;\n            float2 param_12 = _1842;\n            float2 param_13 = _1676;\n            float2 param_14 = _1852;\n            float2 param_15 = _1862;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1686 > 0.5f) && (_1686 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1913 = fa_dc_to_linear(param_16);\n                float4 _5623 = tx;\n                _5623.x = _1913.x;\n                _5623.y = _1913.y;\n                _5623.z = _1913.z;\n                tx = _5623;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1834 * tex_a) * _1867.w, 0.0f, 1.0f).xxx);\n        if (_1877.z > _1877.x)\n        {\n            float4 param_17 = _1877;\n            float2 param_18 = _1842;\n            float2 param_19 = _1676;\n            float2 param_20 = _1852;\n            float2 param_21 = _1862;\n            float4 _1957 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1686 > 1.5f)\n            {\n                float3 param_22 = _1957.xyz;\n                float3 _1967 = fa_dc_to_srgb(param_22);\n                _1961 = _1967;\n            }\n            else\n            {\n                _1961 = _1957.xyz;\n            }\n            float3 _1976 = (_1961 * 2.0f) - 1.0f.xxx;\n            float2 _1981 = _1976.xy * _1731.y;\n            float3 _2003 = (normalize(_1759) * _1981.x) + (normalize(_1766) * _1981.y);\n            float3 _2006 = normalize(normal);\n            normal = normalize(lerp(_2006, normalize((_2006 * max(_1976.z, 0.0500000007450580596923828125f)) + (_2003 - (_2006 * dot(_2006, _2003)))), clamp(_1834 * (_1887 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _5741;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_430_fa_cl_info.x) + int(_430_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_430_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4145;\n    if (fa_lm.z > 0.5f)\n    {\n        _4145 = 0.0f;\n    }\n    else\n    {\n        _4145 = 1.0f - clamp(_430_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4156 = _4145 < 1.0f;\n    bool _4162;\n    if (_4156)\n    {\n        int param = li;\n        _4162 = fa_light_baked(param);\n    }\n    else\n    {\n        _4162 = _4156;\n    }\n    return _4162 ? _4145 : 1.0f;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _608 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _621 = (c - (ru * hx)) - p;\n        float3 _627 = ru * (2.0f * hx);\n        float _633 = max(dot(_627, _627), 9.9999999392252902907785028219223e-09f);\n        float _637 = dot(_621, _627);\n        float t = clamp((-_637) / _633, 0.0f, 1.0f);\n        if (_608)\n        {\n            float _652 = dot(r, _627);\n            float _658 = _633 - (_652 * _652);\n            if (abs(_658) > (9.9999997473787516355514526367188e-06f * _633))\n            {\n                t = clamp(((dot(r, _621) * _652) - _637) / _658, 0.0f, 1.0f);\n            }\n        }\n        return (p + _621) + (_627 * t);\n    }\n    float3 q = p;\n    float _690 = dot(r, axis);\n    bool _698;\n    if (_608)\n    {\n        _698 = abs(_690) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _698 = _608;\n    }\n    if (_698)\n    {\n        float _708 = dot(c - p, axis) / _690;\n        if (_708 > 0.0f)\n        {\n            q = p + (r * _708);\n        }\n    }\n    float3 _721 = q - c;\n    float2 xy = float2(dot(_721, ru), dot(_721, uu));\n    if (shape > 0.5f)\n    {\n        float _736 = length(xy);\n        if (_736 > hx)\n        {\n            xy *= (hx / _736);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _489_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _489_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _528 = dot(d, right);\n    float _532 = dot(d, up);\n    float _543;\n    if (((_528 * _528) + (_532 * _532)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _543 = atan2(_532, _528) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _543 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_543 - floor(_543)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _377 = abs(d);\n    float _379 = _377.x;\n    float _381 = _377.y;\n    bool _382 = _379 >= _381;\n    bool _390;\n    if (_382)\n    {\n        _390 = _379 >= _377.z;\n    }\n    else\n    {\n        _390 = _382;\n    }\n    int _391;\n    if (_390)\n    {\n        _391 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _406;\n        if (_381 >= _377.z)\n        {\n            _406 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _406 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _391 = _406;\n    }\n    return _391;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _774 = fa_light_base(param);\n    bool _778 = _430_fa_ambient.w > 4.5f;\n    int param_1 = _774;\n    float4 _782 = fa_light_texel(param_1);\n    int param_2 = _774 + 1;\n    float4 _787 = fa_light_texel(param_2);\n    float _790 = _787.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _802 = _778 && (_790 > 2.5f);\n    fa_light_is_area = _802;\n    bool _804 = _790 < 0.5f;\n    float3 l;\n    if (_804)\n    {\n        l = normalize(_782.xyz);\n        if (_778)\n        {\n            int param_3 = _774 + 6;\n            float4 _818 = fa_light_texel(param_3);\n            if (_818.z > 0.5f)\n            {\n                int param_4 = _774 + 4;\n                float4 _828 = fa_light_texel(param_4);\n                int param_5 = _774 + 5;\n                float4 _833 = fa_light_texel(param_5);\n                float2 param_6 = _818.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _828.xyz) * _828.w, (-dot(world_pos, _833.xyz)) * _833.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _863 = _782.xyz;\n        float3 _865 = _863 - world_pos;\n        float3 to_light = _865;\n        float _868 = length(_865);\n        float reach = _868;\n        bool front = true;\n        if (_802)\n        {\n            int param_8 = _774 + 7;\n            reach = max(_868 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _774 + 4;\n            float4 _892 = fa_light_texel(param_9);\n            int param_10 = _774 + 5;\n            float4 _897 = fa_light_texel(param_10);\n            int param_11 = _774 + 6;\n            float4 _902 = fa_light_texel(param_11);\n            float _903 = _902.w;\n            int param_12 = _774 + 2;\n            float3 _910 = normalize(fa_light_texel(param_12).xyz);\n            bool _912 = _903 > 1.5f;\n            bool _920;\n            if (!_912)\n            {\n                _920 = dot(_910, to_light) < 0.0f;\n            }\n            else\n            {\n                _920 = _912;\n            }\n            front = _920;\n            float3 r = 0.0f.xxx;\n            float3 _929 = _430_fa_camera_pos.xyz - world_pos;\n            bool _933 = dot(n, n) > 0.5f;\n            bool _941;\n            if (_933)\n            {\n                _941 = dot(_929, _929) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _941 = _933;\n            }\n            if (_941)\n            {\n                r = reflect(-normalize(_929), normalize(n));\n            }\n            float3 param_13 = _863;\n            float3 param_14 = _910;\n            float3 param_15 = _892.xyz;\n            float3 param_16 = _897.xyz;\n            float param_17 = _892.w;\n            float param_18 = _897.w;\n            float param_19 = _903;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _977 = length(to_light);\n        dist = _977;\n        l = to_light / max(_977, 9.9999997473787516355514526367188e-05f).xxx;\n        float _991 = reach / max(_782.w, 0.001000000047497451305389404296875f);\n        float _997 = clamp(1.0f - (_991 * _991), 0.0f, 1.0f);\n        float _999;\n        if (front)\n        {\n            _999 = _997 * _997;\n        }\n        else\n        {\n            _999 = 0.0f;\n        }\n        atten = _999;\n        bool _1010 = _790 < 2.5f;\n        if ((_790 > 1.5f) && _1010)\n        {\n            int param_22 = _774 + 2;\n            float4 _1018 = fa_light_texel(param_22);\n            float _1028 = _1018.w;\n            int param_23 = _774 + 3;\n            float4 _1033 = fa_light_texel(param_23);\n            float _1034 = _1033.x;\n            float cos_inner = _1034;\n            if (_1034 > 1.5f)\n            {\n                cos_inner = lerp(_1028, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1028, cos_inner, dot(-l, normalize(_1018.xyz)));\n        }\n        if (_778 && (_790 < 1.5f))\n        {\n            int param_24 = _774 + 6;\n            float4 _1058 = fa_light_texel(param_24);\n            if (_1058.z > 0.5f)\n            {\n                float3 _1066 = -to_light;\n                int param_25 = _774 + 4;\n                int param_26 = _774 + 5;\n                float3 _1080 = fa_light_texel(param_25).xyz;\n                float3 _1084 = fa_light_texel(param_26).xyz;\n                float3 _1093 = float3(dot(_1066, _1080), dot(_1066, _1084), dot(_1066, cross(_1080, _1084)));\n                float3 param_27 = _1093;\n                int _1097 = fa_cube_face(param_27);\n                int param_28 = _1097;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1124 = float2(dot(_1093, cross(param_29, param_30)), dot(_1093, param_30)) / max(dot(_1093, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1128 = _1097 / 3;\n                float2 param_31 = _1058.xy + (float2(float(_1097 - (_1128 * 3)), float(_1128)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1124.x), 0.5f - (0.5f * _1124.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _774 + 7;\n            float4 _1158 = fa_light_texel(param_33);\n            if (_1158.z > 0.5f)\n            {\n                int param_34 = _774 + 2;\n                int param_35 = _774 + 4;\n                int param_36 = _774 + 5;\n                float2 param_37 = _1158.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_778 && _1010)\n            {\n                int param_42 = _774 + 6;\n                float4 _1205 = fa_light_texel(param_42);\n                int param_43 = _774 + 7;\n                float4 _1210 = fa_light_texel(param_43);\n                bool _1213 = _1205.z > 0.5f;\n                bool _1220;\n                if (!_1213)\n                {\n                    _1220 = _1210.z > 0.5f;\n                }\n                else\n                {\n                    _1220 = _1213;\n                }\n                if (_1220)\n                {\n                    int param_44 = _774 + 2;\n                    float4 _1227 = fa_light_texel(param_44);\n                    float3 _1231 = normalize(_1227.xyz);\n                    int param_45 = _774 + 4;\n                    float4 _1236 = fa_light_texel(param_45);\n                    int param_46 = _774 + 5;\n                    float4 _1241 = fa_light_texel(param_46);\n                    if (_1213)\n                    {\n                        float3 _1249 = -to_light;\n                        float _1256 = _1227.w;\n                        float _1272 = 0.5f / max(dot(_1249, _1231) * (sqrt(max(1.0f - (_1256 * _1256), 0.0f)) / max(_1256, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1205.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1249, _1236.xyz) * _1272), 0.5f - (dot(_1249, _1241.xyz) * _1272));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1210.z > 0.5f)\n                    {\n                        float2 param_49 = _1210.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1231;\n                        float3 param_52 = _1236.xyz;\n                        float3 param_53 = _1241.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _5341 = _787.xyz * atten;\n    if (_778)\n    {\n        _5341 *= fa_light_tint;\n    }\n    int _1341;\n    if (_804)\n    {\n        _1341 = 0;\n    }\n    else\n    {\n        _1341 = ((_790 > 1.5f) && (_790 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _5352 = { l, _5341, atten, 1.0f, dist, _1341 };\n    return _5352;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4374 = n < 0;\n    bool _4381;\n    if (!_4374)\n    {\n        _4381 = n >= fa_light_count();\n    }\n    else\n    {\n        _4381 = _4374;\n    }\n    if (_4381)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4389 = fa_cl_light(param);\n    int param_1 = _4389;\n    float _4393 = fa_baked_keep(param_1);\n    if (_4393 <= 0.0f)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4389;\n    float3 param_3 = i.world_pos;\n    float3 param_4 = i.world_normal;\n    LightSample _4409 = fa_light_sample_n(param_2, param_3, param_4);\n    LightSample _5523 = { _4409.direction, _4409.color * _4393, _4409.attenuation * _4393, _4409.shadow, _4409._distance, _4409.type };\n    return _5523;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2135 = fa_shadow_depth(param, param_1);\n    float _2139;\n    if (conv.x < 0.5f)\n    {\n        _2139 = _2135;\n    }\n    else\n    {\n        _2139 = (conv.y * conv.z) / (conv.z - (_2135 * (conv.z - conv.y)));\n    }\n    return _2139;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2066 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2066), sin(_2066)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2185 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2194;\n        if (k < 0.0f)\n        {\n            _2194 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2194 = k;\n        }\n        float _2214 = clamp((_2194 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2185;\n            float2 _2233 = fa_shadow_vogel(param_3, param_4, param_5) * _2214;\n            float2 param_6 = uv + (_2233 * _2088_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2245 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2245 < (zr - (length(_2233) * plane)))\n            {\n                sum += _2245;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2271 = sum / cnt;\n        float _2281;\n        if (k < 0.0f)\n        {\n            _2281 = (-k) / max(_2271, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2281 = k;\n        }\n        radius = clamp(((max(zr - _2271, 0.0f) * unit) * _2281) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2303 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2303; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2303;\n        float param_11 = _2185;\n        float2 _2322 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2322 * _2088_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2322) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2303);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2522 = _430_fa_pbr.z < 0.5f;\n    bool _2529;\n    if (!_2522)\n    {\n        _2529 = _2088_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2529 = _2522;\n    }\n    if (_2529)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2088_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2542 = fa_light_texel(param);\n    float _2543 = _2542.x;\n    if (_2543 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2552 = int(_2543 + 0.5f);\n    int param_1 = _2552;\n    float4 _2556 = fa_light_texel(param_1);\n    int param_2 = _2552 + 1;\n    float4 _2561 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2564 = _2556.y;\n    if (_2564 > 0.0f)\n    {\n        float _2581 = 1.0f - smoothstep(0.75f * _2564, _2564, length(world - _2088_fa_shadow_eye.xyz));\n        fade = _2581;\n        if (_2581 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2556.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2605 = (_2552 + 2) + (face * 6);\n    int param_4 = _2605;\n    int param_5 = _2605 + 1;\n    int param_6 = _2605 + 3;\n    float4 _2619 = fa_light_texel(param_6);\n    int param_7 = _2605 + 4;\n    float4 _2624 = fa_light_texel(param_7);\n    int param_8 = _2605 + 5;\n    float4 _2629 = fa_light_texel(param_8);\n    float _2641 = _2629.x * max(dot(_2619, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2646 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2669 = clamp(dot(n, _2619.xyz), -1.0f, 1.0f);\n    float _2688 = min(sqrt(1.0f - (_2669 * _2669)) / max(abs(dot(n, world - lpos)) / max(dot(_2619, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2691 = _2561.y;\n    float _2693;\n    if (_2691 > 0.0f)\n    {\n        _2693 = _2691;\n    }\n    else\n    {\n        _2693 = 1.5f * _2641;\n    }\n    float4 _2713 = float4(world + (n * (_2693 * sqrt(1.0f - (_2646 * _2646)))), 1.0f);\n    float _2717 = dot(_2619, _2713);\n    float _2720 = _2629.y;\n    if (_2717 < _2720)\n    {\n        return 1.0f;\n    }\n    float2 _2735 = float2(dot(fa_light_texel(param_4), _2713), dot(fa_light_texel(param_5), _2713)) / _2717.xx;\n    float _2737 = _2735.x;\n    bool _2740 = _2737 < _2624.x;\n    bool _2749;\n    if (!_2740)\n    {\n        _2749 = _2737 > _2624.z;\n    }\n    else\n    {\n        _2749 = _2740;\n    }\n    bool _2758;\n    if (!_2749)\n    {\n        _2758 = _2735.y < _2624.y;\n    }\n    else\n    {\n        _2758 = _2749;\n    }\n    bool _2767;\n    if (!_2758)\n    {\n        _2767 = _2735.y > _2624.w;\n    }\n    else\n    {\n        _2767 = _2758;\n    }\n    if (_2767)\n    {\n        return 1.0f;\n    }\n    float _2773 = _2561.x;\n    float _2775;\n    if (_2773 > 0.0f)\n    {\n        _2775 = _2773;\n    }\n    else\n    {\n        _2775 = 1.5f * _2641;\n    }\n    float2 param_9 = _2735;\n    float4 param_10 = _2624;\n    float param_11 = _2717 - (_2775 * (1.0f + (0.5f * _2688)));\n    float param_12 = _2641;\n    float param_13 = 1.0f;\n    float param_14 = _2629.z * 0.25f;\n    float param_15 = (_2641 * min(_2688, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2720, _2629.z);\n    int param_17 = int(_2556.z + 0.5f);\n    float param_18 = _2556.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2078;\n    if (i == 0)\n    {\n        _2078 = _2088_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2094;\n        if (i == 1)\n        {\n            _2094 = _2088_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2102;\n            if (i == 2)\n            {\n                _2102 = _2088_fa_shadow_split.z;\n            }\n            else\n            {\n                _2102 = _2088_fa_shadow_split.w;\n            }\n            _2094 = _2102;\n        }\n        _2078 = _2094;\n    }\n    return _2078;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2364 = max(_2088_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2369 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2375 = sqrt(1.0f - (_2369 * _2369));\n    float _2382 = min(_2375 / max(_2369, 0.20000000298023223876953125f), 4.0f);\n    float _2387;\n    if (_2088_fa_shadow_bias.y > 0.0f)\n    {\n        _2387 = _2088_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2387 = 1.5f * _2088_fa_shadow_info[ci].x;\n    }\n    float4 _2412 = mul(float4(world + (n * (_2387 * _2375)), 1.0f), _2088_fa_shadow_mat[ci]);\n    float _2419 = _2412.x;\n    bool _2422 = _2419 < _2088_fa_shadow_rect[ci].x;\n    bool _2431;\n    if (!_2422)\n    {\n        _2431 = _2419 > _2088_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2431 = _2422;\n    }\n    bool _2440;\n    if (!_2431)\n    {\n        _2440 = _2412.y < _2088_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2440 = _2431;\n    }\n    bool _2449;\n    if (!_2440)\n    {\n        _2449 = _2412.y > _2088_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2449 = _2440;\n    }\n    bool _2456;\n    if (!_2449)\n    {\n        _2456 = _2412.z > 1.0f;\n    }\n    else\n    {\n        _2456 = _2449;\n    }\n    if (_2456)\n    {\n        return -1.0f;\n    }\n    float _2464;\n    if (_2088_fa_shadow_bias.x > 0.0f)\n    {\n        _2464 = _2088_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2464 = 1.5f * _2088_fa_shadow_info[ci].x;\n    }\n    float2 param = _2412.xy;\n    float4 param_1 = _2088_fa_shadow_rect[ci];\n    float param_2 = _2412.z - ((_2464 * (1.0f + (0.5f * _2382))) / _2364);\n    float param_3 = _2088_fa_shadow_info[ci].x;\n    float param_4 = _2364;\n    float param_5 = _2364 * 0.25f;\n    float param_6 = ((_2088_fa_shadow_info[ci].x * min(_2382, 3.0f)) * 0.5f) / _2364;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2088_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2088_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_430_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2842 = int(_2088_fa_shadow_cfg.x + 0.5f);\n    if (_2842 < 1)\n    {\n        return 1.0f;\n    }\n    float _2857 = dot(world - _2088_fa_shadow_eye.xyz, _2088_fa_shadow_fwd.xyz);\n    int param = _2842 - 1;\n    if (_2857 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2869 = _2842 > 1;\n    bool _2876;\n    if (_2869)\n    {\n        _2876 = _2857 > _2088_fa_shadow_split.x;\n    }\n    else\n    {\n        _2876 = _2869;\n    }\n    if (_2876)\n    {\n        ci = 1;\n    }\n    bool _2880 = _2842 > 2;\n    bool _2887;\n    if (_2880)\n    {\n        _2887 = _2857 > _2088_fa_shadow_split.y;\n    }\n    else\n    {\n        _2887 = _2880;\n    }\n    if (_2887)\n    {\n        ci = 2;\n    }\n    bool _2891 = _2842 > 3;\n    bool _2898;\n    if (_2891)\n    {\n        _2898 = _2857 > _2088_fa_shadow_split.z;\n    }\n    else\n    {\n        _2898 = _2891;\n    }\n    if (_2898)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2842)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2924 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2924;\n        if (_2924 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2088_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2949;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2949 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2949 = _2088_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2968 = _2088_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2949, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2979 = clamp((_2857 - (fa_shadow_split_at(param_7) - _2968)) / _2968, 0.0f, 1.0f);\n        if (_2979 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2842)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3000 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3000;\n                if (_3000 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2979);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3889 = _430_fa_ct_a.x < 0.5f;\n    bool _3896;\n    if (!_3889)\n    {\n        _3896 = _2088_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3896 = _3889;\n    }\n    if (_3896)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2088_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3909 = fa_light_texel(param);\n    float _3910 = _3909.y;\n    float len = _3910;\n    if (_3910 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3922 = length(world - _430_fa_camera_pos.xyz);\n    float _3932 = 1.0f - smoothstep(0.5f * _430_fa_ct_b.x, _430_fa_ct_b.x, _3922);\n    if (_3932 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3938 = len;\n    float _3941 = min(_3938, 0.89999997615814208984375f * dist);\n    len = _3941;\n    float _3946 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3922);\n    float _3951 = _3946 + (0.5f * _3941);\n    float3 _3957 = world + (gn * _3946);\n    float _3959 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4023;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3974 = (float(k) + _3959) * 0.083333335816860198974609375f;\n        float3 _3982 = _3957 + (l * (_3974 * len));\n        float4 _3988 = float4(_3982, 1.0f);\n        float _3994 = dot(_430_fa_ct_vpw, _3988);\n        if (_3994 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4014 = float2(dot(_430_fa_ct_vpx, _3988), dot(_430_fa_ct_vpy, _3988)) / _3994.xx;\n        float _4018 = _4014.x * 0.5f;\n        float _4019 = _4018 + 0.5f;\n        if (_430_fa_ct_a.y > 0.5f)\n        {\n            _4023 = (_4014.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4023 = 0.5f - (_4014.y * 0.5f);\n        }\n        bool _4039 = _4019 < 0.0f;\n        bool _4046;\n        if (!_4039)\n        {\n            _4046 = _4019 >= 1.0f;\n        }\n        else\n        {\n            _4046 = _4039;\n        }\n        bool _4053;\n        if (!_4046)\n        {\n            _4053 = _4023 < 0.0f;\n        }\n        else\n        {\n            _4053 = _4046;\n        }\n        bool _4060;\n        if (!_4053)\n        {\n            _4060 = _4023 >= 1.0f;\n        }\n        else\n        {\n            _4060 = _4053;\n        }\n        if (_4060)\n        {\n            break;\n        }\n        float4 _4079 = fa_screen_tex.Load(int3(int2(float2(_4019, _4023) * _430_fa_ct_a.zw), 0));\n        if (_4079.w < 0.5f)\n        {\n            continue;\n        }\n        float _4098 = (dot(_430_fa_ct_fwd.xyz, _3982) + _430_fa_ct_fwd.w) - _4079.x;\n        if ((_4098 > _3946) && (_4098 < _3951))\n        {\n            occ = max(occ, (1.0f - (_3974 * _3974)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4019, 0.5f - _4018), min(_4023, 1.0f - _4023))));\n        }\n    }\n    return 1.0f - (occ * _3932);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4201 = fa_baked_keep(param);\n    if (_4201 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _5485 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _5485;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4227 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _5487 = _4227.color;\n    float _5488 = _4227.attenuation;\n    float _5489 = _4227.shadow;\n    bool _4230 = _4227.type == 0;\n    if (_4230 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4227.direction;\n        float _4241 = fa_shadow_factor(param_5, param_6);\n        _5489 = _4241;\n        _5487 *= _4241;\n    }\n    else\n    {\n        bool _4252 = _4227.type != 0;\n        bool _4258;\n        if (_4252)\n        {\n            _4258 = _5488 > 0.0f;\n        }\n        else\n        {\n            _4258 = _4252;\n        }\n        if (_4258)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4227.direction;\n            float _4277 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5489 = _4277;\n            _5487 *= _4277;\n        }\n    }\n    bool _4287 = _430_fa_ct_a.x > 0.5f;\n    bool _4293;\n    if (_4287)\n    {\n        _4293 = _5488 > 0.0f;\n    }\n    else\n    {\n        _4293 = _4287;\n    }\n    if (_4293)\n    {\n        float _4300;\n        if (_4230)\n        {\n            _4300 = 1000000000.0f;\n        }\n        else\n        {\n            _4300 = _4227._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4227.direction;\n        float param_18 = _4300;\n        float _4318 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5489 *= _4318;\n        _5487 *= _4318;\n    }\n    float _4331 = _5488;\n    float _4332 = _4331 * _4201;\n    _5488 = _4332;\n    float3 _4336 = _5487;\n    float3 _4337 = _4336 * _4201;\n    _5487 = _4337;\n    LightSample _5504 = { _4227.direction, _4337, _4332, _5489, _4227._distance, _4227.type };\n    return _5504;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4348 = n < 0;\n    bool _4355;\n    if (!_4348)\n    {\n        _4355 = n >= fa_light_count();\n    }\n    else\n    {\n        _4355 = _4348;\n    }\n    if (_4355)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    LightSample _4370 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4370;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3279 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3287 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3290 = int(_3279);\n    int _3293 = int(_3287);\n    float _3303 = _3287 - float(_3293);\n    int _3359 = (_3290 * 9) + _3293;\n    int _3379 = ((_3290 + 1) * 9) + _3293;\n    return lerp(lerp(_3354[_3359], _3354[_3359 + 1], _3303), lerp(_3354[_3379], _3354[_3379 + 1], _3303), _3279 - float(_3290));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _5353 = false;\n    float _5354 = 1.0f;\n    float _5355 = 1.0f;\n    float _5356 = 1.0f;\n    float _5357 = 0.0f;\n    float _5358 = 0.0f;\n    float _5359 = 0.0f;\n    float _5360 = 0.0f;\n    float _5362 = 1.0f;\n    bool _5363 = false;\n    float3 _5364 = 0.0f.xxx;\n    float _5365 = 1.0f;\n    float _5366 = 1.0f;\n    float _5367 = 1.0f;\n    float _5368 = 0.0f;\n    float _5369 = 0.0f;\n    float3 _5370 = float3(1.0f, 0.0f, 0.0f);\n    float3 _5371 = float3(0.0f, 0.0f, 1.0f);\n    float _5372 = 1.0f;\n    float _5373 = 1.0f;\n    float _3430 = clamp(s.specular, 0.0f, 1.0f);\n    float _3434 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3439 = (_3430 != 1.0f) || (_3434 != 1.5f);\n    bool _3448;\n    if (!_3439)\n    {\n        _3448 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3448 = _3439;\n    }\n    if (_3448)\n    {\n        float _3456 = (_3434 - 1.0f) / (_3434 + 1.0f);\n        f0 = lerp(min((_3456 * _3456).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3430, s.albedo, metallic.xxx);\n        _5354 = lerp(_3430, 1.0f, metallic);\n        _5353 = true;\n    }\n    float _3483 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3483 > 0.0f)\n    {\n        float _3491 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _5357 = _3483;\n        _5358 = _3491;\n        float _3498 = _3491 * _3491;\n        _5359 = _3498;\n        _5360 = _3498 * _3498;\n        float _3510 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _5362 = _3510;\n        _5355 = 1.0f - (_3483 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3510, 0.0f, 1.0f), 5.0f))));\n        _5353 = true;\n    }\n    float3 _3530 = max(s.sheen_color, 0.0f.xxx);\n    float _3539 = max(_3530.x, max(_3530.y, _3530.z));\n    if (_3539 > 0.0f)\n    {\n        float _3547 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _5363 = true;\n        _5364 = _3530;\n        _5365 = _3547;\n        _5366 = _3547 * _3547;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3547;\n        float _3564 = fa_sheen_albedo(param, param_1);\n        _5368 = _3564;\n        _5367 = 1.0f - min(_3539 * _3564, 1.0f);\n        _5353 = true;\n    }\n    _5356 = _5355 * _5367;\n    float _3583 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3583 != 0.0f)\n    {\n        float3 _3598 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3598;\n        if (dot(_3598, _3598) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3610 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3610.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3610.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3610.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3614 = t;\n        float3 _3615 = normalize(_3614);\n        t = _3615;\n        float3 _3640 = normalize((_3615 * cos(s.anisotropy_rotation)) + ((cross(n, _3615) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _5370 = _3640;\n        _5371 = cross(n, _3640);\n        float _3650 = roughness * roughness;\n        float _3656 = lerp(_3650, 1.0f, _3583 * _3583);\n        bool _3658 = _3583 > 0.0f;\n        _5372 = _3658 ? _3656 : _3650;\n        _5373 = _3658 ? _3650 : _3656;\n        _5369 = _3583;\n        _5353 = true;\n    }\n    FaLayers _5395 = { _5353, _5354, _5355, _5356, _5357, _5358, _5359, _5360, i.world_normal, _5362, _5363, _5364, _5365, _5366, _5367, _5368, _5369, _5370, _5371, _5372, _5373 };\n    return _5395;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3211 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3214 = _3211.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3214 * _3214, exp2((-9.27999973297119140625f) * ndv)) * _3214) + _3211.y)) + _3211.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_430_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _430_fa_env_horizon.w).xyz;\n    }\n    float _3135 = rough * rough;\n    float _3165 = 0.60000002384185791015625f * _3135;\n    return lerp(lerp(_430_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_430_fa_env_horizon.xyz, _430_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3135)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3165, 0.0500000007450580596923828125f + _3165, d.y).xxx), ((_430_fa_env_sky.xyz + _430_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3135 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3691;\n        if (L.aniso >= 0.0f)\n        {\n            _3691 = L.b;\n        }\n        else\n        {\n            _3691 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3691, v), _3691), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3724 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3724.x) + (L.f90.xxx * _3724.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3779 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3779.x) + _3779.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3253 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3253.x) + _3253.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3818 = clamp(s.metallic, 0.0f, 1.0f);\n    float _3822 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _3829 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _3818.xxx);\n    float3 f0 = _3829;\n    float3 _3833 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3833;\n    float3 param_3 = i.view_dir;\n    float param_4 = _3818;\n    float param_5 = _3822;\n    float3 param_6 = _3829;\n    FaLayers _3850 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3850.on)\n    {\n        FaLayers param_7 = _3850;\n        float3 param_8 = _3833;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3822;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _3833;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3822;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _4440 = fa_light_unshadowed(param, param_1);\n        float _4448 = dot(_4440.color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_4448 > bestPower)\n        {\n            bestPower = _4448;\n            best = n;\n        }\n    }\n    float3 lit = (_430_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _4477 = fa_light(param_2, param_3);\n        float _4485;\n        if (dot(s.normal, _4477.direction) > 0.5f)\n        {\n            _4485 = 1.0f;\n        }\n        else\n        {\n            _4485 = _4491_dark;\n        }\n        lit += ((s.albedo * _4477.color) * _4485);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _4491_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2088_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3024 = int(_2088_fa_shadow_cfg.x + 0.5f);\n    float _3034 = dot(world - _2088_fa_shadow_eye.xyz, _2088_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3039 = _3024 > 0;\n    bool _3048;\n    if (_3039)\n    {\n        int param = _3024 - 1;\n        _3048 = _3034 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3048 = _3039;\n    }\n    if (_3048)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3054 = _3024 > 1;\n        bool _3061;\n        if (_3054)\n        {\n            _3061 = _3034 > _2088_fa_shadow_split.x;\n        }\n        else\n        {\n            _3061 = _3054;\n        }\n        if (_3061)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3067 = _3024 > 2;\n        bool _3074;\n        if (_3067)\n        {\n            _3074 = _3034 > _2088_fa_shadow_split.y;\n        }\n        else\n        {\n            _3074 = _3067;\n        }\n        if (_3074)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3080 = _3024 > 3;\n        bool _3087;\n        if (_3080)\n        {\n            _3087 = _3034 > _2088_fa_shadow_split.z;\n        }\n        else\n        {\n            _3087 = _3080;\n        }\n        if (_3087)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5207 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5207 = -_5207;\n    }\n    float3 _4878 = normalize(_430_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5220 = { fa_world_pos, _5207, fa_world_tangent, fa_uv, fa_vertex_color, _4878, gl_FrontFacing };\n    SurfaceInput param_1 = _5220;\n    Surface _4886 = fa_standard_surface(param_1);\n    float3 _5238 = _4886.albedo;\n    float _5239 = _4886.alpha;\n    float3 _5240 = _4886.normal;\n    float _5241 = _4886.metallic;\n    float _5242 = _4886.roughness;\n    float _5243 = _4886.occlusion;\n    float3 _5244 = _4886.emission;\n    float _5245 = _4886.clearcoat;\n    float _5246 = _4886.clearcoat_roughness;\n    float3 _5247 = _4886.sheen_color;\n    float _5248 = _4886.sheen_roughness;\n    float _5249 = _4886.anisotropy;\n    float _5250 = _4886.anisotropy_rotation;\n    float _5251 = _4886.specular;\n    float _5252 = _4886.ior;\n    float3 _5253 = _4886.specular_color;\n    float _5254 = _4886.transmission;\n    float _5255 = _4886.thickness;\n    float3 _5256 = _4886.attenuation_color;\n    float _5257 = _4886.attenuation_distance;\n    SurfaceInput _5228 = { fa_world_pos, _5207, fa_world_tangent, fa_uv, fa_vertex_color, _4878, gl_FrontFacing };\n    SurfaceInput param_2 = _5228;\n    Surface param_3 = _4886;\n    surface(param_2, param_3);\n    _5238 = param_3.albedo;\n    _5239 = param_3.alpha;\n    _5240 = param_3.normal;\n    _5241 = param_3.metallic;\n    _5242 = param_3.roughness;\n    _5243 = param_3.occlusion;\n    _5244 = param_3.emission;\n    _5245 = param_3.clearcoat;\n    _5246 = param_3.clearcoat_roughness;\n    _5247 = param_3.sheen_color;\n    _5248 = param_3.sheen_roughness;\n    _5249 = param_3.anisotropy;\n    _5250 = param_3.anisotropy_rotation;\n    _5251 = param_3.specular;\n    _5252 = param_3.ior;\n    _5253 = param_3.specular_color;\n    _5254 = param_3.transmission;\n    _5255 = param_3.thickness;\n    _5256 = param_3.attenuation_color;\n    _5257 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5207;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5238 = param_6;\n    _5240 = param_7;\n    float3 result;\n    if (_430_fa_emissive.w > 0.5f)\n    {\n        result = _5238;\n    }\n    else\n    {\n        float3 _4925 = _5240;\n        float3 _4926 = normalize(_4925);\n        _5240 = _4926;\n        SurfaceInput _5236 = { fa_world_pos, _5207, fa_world_tangent, fa_uv, fa_vertex_color, _4878, gl_FrontFacing };\n        SurfaceInput param_8 = _5236;\n        Surface _5339 = { _5238, _5239, _4926, _5241, _5242, _5243, _5244, _5245, _5246, _5247, _5248, _5249, _5250, _5251, _5252, _5253, _5254, _5255, _5256, _5257 };\n        Surface param_9 = _5339;\n        float3 _4937 = lighting(param_8, param_9);\n        result = _4937;\n    }\n    float3 _4941 = result;\n    float3 _4942 = _4941 + _5244;\n    result = _4942;\n    float3 param_10 = _4942;\n    float3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _4951 = _430_fa_fog.w > 0.0f;\n    bool _4958;\n    if (!_4951)\n    {\n        _4958 = _430_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4958 = _4951;\n    }\n    if (_4958)\n    {\n        float3 _4967 = fa_world_pos - _430_fa_camera_pos.xyz;\n        float _4973 = dot(_4967, _430_fa_fog_c.xyz);\n        bool _4977 = _430_fa_fog_c.w > 0.5f;\n        float _4978;\n        if (_4977)\n        {\n            _4978 = _4973;\n        }\n        else\n        {\n            _4978 = length(_4967);\n        }\n        float _4990 = _4978 - _430_fa_fog_b.x;\n        if (_4990 > 0.0f)\n        {\n            float _4999 = _430_fa_fog.w * _4990;\n            float tau = _4999 * _4999;\n            if (_430_fa_fog_b.y > 0.0f)\n            {\n                float _5015;\n                if (_4977)\n                {\n                    _5015 = fa_world_pos.y - (_430_fa_fog_c.y * _4973);\n                }\n                else\n                {\n                    _5015 = _430_fa_camera_pos.y;\n                }\n                float _5036 = lerp(_5015, fa_world_pos.y, clamp(_430_fa_fog_b.x / _4978, 0.0f, 1.0f));\n                float _5040 = fa_world_pos.y - _5036;\n                float _5045 = _5036 - _430_fa_fog_b.z;\n                float _5050 = fa_world_pos.y - _430_fa_fog_b.z;\n                bool _5053 = _5045 <= 0.0f;\n                bool _5054 = !_5053;\n                bool _5060;\n                if (_5054)\n                {\n                    _5060 = _430_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5060 = _5053;\n                }\n                float _5061;\n                if (_5060)\n                {\n                    _5061 = _430_fa_fog_b.y;\n                }\n                else\n                {\n                    _5061 = _430_fa_fog_b.y * exp(-min(_430_fa_fog_b.w * _5045, 80.0f));\n                }\n                bool _5088;\n                if (_5054)\n                {\n                    _5088 = _430_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5088 = _5053;\n                }\n                float _5089;\n                if (_5088)\n                {\n                    _5089 = _430_fa_fog_b.y * _5045;\n                }\n                else\n                {\n                    _5089 = (_430_fa_fog_b.y * (1.0f - exp(-min(_430_fa_fog_b.w * _5045, 80.0f)))) / _430_fa_fog_b.w;\n                }\n                bool _5114 = _5050 <= 0.0f;\n                bool _5121;\n                if (!_5114)\n                {\n                    _5121 = _430_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5121 = _5114;\n                }\n                float _5122;\n                if (_5121)\n                {\n                    _5122 = _430_fa_fog_b.y * _5050;\n                }\n                else\n                {\n                    _5122 = (_430_fa_fog_b.y * (1.0f - exp(-min(_430_fa_fog_b.w * _5050, 80.0f)))) / _430_fa_fog_b.w;\n                }\n                float _5149;\n                if (abs(_5040) < 0.001000000047497451305389404296875f)\n                {\n                    _5149 = _5061;\n                }\n                else\n                {\n                    _5149 = (_5122 - _5089) / _5040;\n                }\n                tau += (_4990 * max(_5149, 0.0f));\n            }\n            result = lerp(result, _430_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5239);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 656,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_430",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2088",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_4491",
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
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\nstatic float3 fa_lm;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _384 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _384;\n}\n\nvoid fa_shade_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mul(float4(_391, 1.0f), _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = 0.0f.xxx;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_lm = fa_lm;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    float3 direction;\n    float3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    float3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    float3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    float3 t;\n    float3 b;\n    float at;\n    float ab;\n};\n\nstatic const float _3354[63] = { 1.0f, 1.0f, 1.0f, 0.4790000021457672119140625f, 0.11699999868869781494140625f, 0.01200000010430812835693359375f, 0.0f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.578000009059906005859375f, 0.19300000369548797607421875f, 0.0350000001490116119384765625f, 0.0030000000260770320892333984375f, 0.0f, 0.0f, 1.0f, 1.0f, 1.0f, 0.6740000247955322265625f, 0.3459999859333038330078125f, 0.1319999992847442626953125f, 0.032999999821186065673828125f, 0.0040000001899898052215576171875f, 0.0f, 0.971000015735626220703125f, 0.954999983310699462890625f, 0.828999996185302734375f, 0.63999998569488525390625f, 0.42599999904632568359375f, 0.24500000476837158203125f, 0.115000002086162567138671875f, 0.037000000476837158203125f, 0.0030000000260770320892333984375f, 0.7469999790191650390625f, 0.737999975681304931640625f, 0.670000016689300537109375f, 0.563000023365020751953125f, 0.4309999942779541015625f, 0.3039999902248382568359375f, 0.1940000057220458984375f, 0.1019999980926513671875f, 0.0309999994933605194091796875f, 0.614000022411346435546875f, 0.609000027179718017578125f, 0.566999971866607666015625f, 0.499000012874603271484375f, 0.412000000476837158203125f, 0.32400000095367431640625f, 0.240999996662139892578125f, 0.162000000476837158203125f, 0.087999999523162841796875f, 0.538999974727630615234375f, 0.535000026226043701171875f, 0.505999982357025146484375f, 0.4569999873638153076171875f, 0.393999993801116943359375f, 0.328999996185302734375f, 0.2660000026226043701171875f, 0.203999996185302734375f, 0.14200000464916229248046875f };\nstatic const LightSample _5741 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, 0 };\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _430_fa_camera_pos : packoffset(c0);\n    float4 _430_fa_ambient : packoffset(c1);\n    float4 _430_fa_base_color : packoffset(c2);\n    float4 _430_fa_emissive : packoffset(c3);\n    float4 _430_fa_model_emissive : packoffset(c4);\n    float4 _430_fa_pbr : packoffset(c5);\n    float4 _430_fa_maps : packoffset(c6);\n    float4 _430_fa_fog : packoffset(c7);\n    float4 _430_fa_fog_b : packoffset(c8);\n    float4 _430_fa_fog_c : packoffset(c9);\n    float4 _430_fa_counts : packoffset(c10);\n    float4 _430_fa_env_sky : packoffset(c11);\n    float4 _430_fa_env_horizon : packoffset(c12);\n    float4 _430_fa_time : packoffset(c13);\n    float4 _430_fa_cl_vpx : packoffset(c14);\n    float4 _430_fa_cl_vpy : packoffset(c15);\n    float4 _430_fa_cl_vpw : packoffset(c16);\n    float4 _430_fa_cl_fwd : packoffset(c17);\n    float4 _430_fa_cl_grid : packoffset(c18);\n    float4 _430_fa_cl_info : packoffset(c19);\n    float4 _430_fa_layers_a : packoffset(c20);\n    float4 _430_fa_layers_b : packoffset(c21);\n    float4 _430_fa_layers_c : packoffset(c22);\n    float4 _430_fa_layers_d : packoffset(c23);\n    float4 _430_fa_ct_a : packoffset(c24);\n    float4 _430_fa_ct_b : packoffset(c25);\n    float4 _430_fa_ct_vpx : packoffset(c26);\n    float4 _430_fa_ct_vpy : packoffset(c27);\n    float4 _430_fa_ct_vpw : packoffset(c28);\n    float4 _430_fa_ct_fwd : packoffset(c29);\n    float4 _430_fa_tr_a : packoffset(c30);\n    float4 _430_fa_tr_b : packoffset(c31);\n    float4 _430_fa_probe_sh[9] : packoffset(c32);\n};\n\ncbuffer fa_shadows : register(b7)\n{\n    row_major float4x4 _2088_fa_shadow_mat[4] : packoffset(c0);\n    float4 _2088_fa_shadow_rect[4] : packoffset(c16);\n    float4 _2088_fa_shadow_info[4] : packoffset(c20);\n    float4 _2088_fa_shadow_split : packoffset(c24);\n    float4 _2088_fa_shadow_cfg : packoffset(c25);\n    float4 _2088_fa_shadow_bias : packoffset(c26);\n    float4 _2088_fa_shadow_eye : packoffset(c27);\n    float4 _2088_fa_shadow_fwd : packoffset(c28);\n    float4 _2088_fa_shadow_lcfg : packoffset(c29);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _4491_dark : packoffset(c0);\n    float _4491_fa_pad0 : packoffset(c0.y);\n    float _4491_fa_pad1 : packoffset(c0.z);\n    float _4491_fa_pad2 : packoffset(c0.w);\n    float _4491_skyAmount : packoffset(c1);\n    float _4491_fa_pad3 : packoffset(c1.y);\n    float _4491_fa_pad4 : packoffset(c1.z);\n    float _4491_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> fa_light_tex : register(t7);\nSamplerState fa_shadow_smp : register(s1);\nTexture2D<float4> fa_light_atlas : register(t8);\nSamplerState fa_env_smp : register(s10);\nTexture2D<float4> fa_decal_tex : register(t9);\nTexture2D<float4> fa_shadow_tex : register(t1);\nTextureCube<float4> fa_env_tex : register(t6);\nTexture2D<float4> fa_screen_tex : register(t10);\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t2);\nTexture2D<float4> fa_mr_tex : register(t3);\nTexture2D<float4> fa_occlusion_tex : register(t4);\nTexture2D<float4> fa_emissive_tex : register(t5);\n\nstatic float4 gl_FragCoord;\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_lm;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float4 fa_frag_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float3 fa_lm : TEXCOORD5;\n    float4 gl_FragCoord : SV_Position;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nstatic float3 fa_light_tint;\nstatic bool fa_light_is_area;\nstatic int fa_cl_ndir;\nstatic int fa_cl_slot;\nstatic int fa_cl_local;\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nuint2 spvTextureSize(Texture2D<float4> Tex, uint Level, out uint Param)\n{\n    uint2 ret;\n    Tex.GetDimensions(Level, ret.x, ret.y, Param);\n    return ret;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat4 fa_light_texel(int t)\n{\n    return fa_light_tex.Load(int3(int2(t & 1023, t >> 10), 0));\n}\n\nfloat4 fa_cluster_texel(float3 world_pos)\n{\n    bool _1359 = _430_fa_cl_info.x < 0.0f;\n    bool _1366;\n    if (!_1359)\n    {\n        _1366 = _430_fa_cl_info.w < 1.0f;\n    }\n    else\n    {\n        _1366 = _1359;\n    }\n    bool _1374;\n    if (!_1366)\n    {\n        _1374 = _430_fa_cl_grid.x < 1.0f;\n    }\n    else\n    {\n        _1374 = _1366;\n    }\n    bool _1381;\n    if (!_1374)\n    {\n        _1381 = _430_fa_cl_grid.y < 1.0f;\n    }\n    else\n    {\n        _1381 = _1374;\n    }\n    bool _1388;\n    if (!_1381)\n    {\n        _1388 = _430_fa_cl_info.y < 1.0f;\n    }\n    else\n    {\n        _1388 = _1381;\n    }\n    if (_1388)\n    {\n        return 0.0f.xxxx;\n    }\n    float4 _1398 = float4(world_pos, 1.0f);\n    float _1404 = dot(_430_fa_cl_vpw, _1398);\n    if (!(_1404 > 9.9999999747524270787835121154785e-07f))\n    {\n        return 0.0f.xxxx;\n    }\n    float2 _1426 = float2(dot(_430_fa_cl_vpx, _1398), dot(_430_fa_cl_vpy, _1398)) / _1404.xx;\n    int _1430 = int(_430_fa_cl_grid.x);\n    int _1434 = int(_430_fa_cl_grid.y);\n    int param = (int(_430_fa_cl_info.x) + (((clamp(int(floor(log2(max(dot(_430_fa_cl_fwd.xyz, world_pos) + _430_fa_cl_fwd.w, _430_fa_cl_grid.w) / _430_fa_cl_grid.w) * _430_fa_cl_grid.z)), 0, int(_430_fa_cl_info.y) - 1) * _1434) + clamp(int(floor(((_1426.y * 0.5f) + 0.5f) * _430_fa_cl_grid.y)), 0, _1434 - 1)) * _1430)) + clamp(int(floor(((_1426.x * 0.5f) + 0.5f) * _430_fa_cl_grid.x)), 0, _1430 - 1);\n    return fa_light_texel(param);\n}\n\nint2 fa_cluster_lookup(float3 world_pos)\n{\n    float3 param = world_pos;\n    float4 _1510 = fa_cluster_texel(param);\n    return int2(int(_1510.x), int(_1510.y));\n}\n\nvoid fa_cluster_begin(float3 world_pos)\n{\n    fa_cl_ndir = int(_430_fa_cl_info.z);\n    float3 param = world_pos;\n    int2 _4175 = fa_cluster_lookup(param);\n    fa_cl_slot = _4175.x;\n    fa_cl_local = _4175.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _4552 = fa_linear_to_srgb(param);\n        c = _4552;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _4560 = fa_srgb_to_linear(param_1);\n            c = _4560;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _310;\n    if (i.front_facing)\n    {\n        _310 = i.world_normal;\n    }\n    else\n    {\n        _310 = -i.world_normal;\n    }\n    float3 _334 = normalize(i.world_tangent.xyz - (_310 * dot(_310, i.world_tangent.xyz)));\n    float3 _362 = normalize(((_334 * m.x) + ((cross(_310, _334) * i.world_tangent.w) * m.y)) + (_310 * m.z));\n    float3 _365;\n    if (i.front_facing)\n    {\n        _365 = _362;\n    }\n    else\n    {\n        _365 = -_362;\n    }\n    return _365;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _430_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _4591 = fa_tex_fix(param_2, param_3);\n    float4 _5704 = base_t;\n    _5704.x = _4591.x;\n    _5704.y = _4591.y;\n    _5704.z = _4591.z;\n    base_t = _5704;\n    float4 _4605 = (_5704 * _430_fa_base_color) * i.vertex_color;\n    float3 _5535 = i.world_normal;\n    if (_430_fa_maps.z > 0.5f)\n    {\n        float param_4 = _430_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _4637 = fa_tex_fix(param_6, param_7);\n        float3 _4640 = (_4637 * 2.0f) - 1.0f.xxx;\n        float2 _4645 = _4640.xy * _430_fa_maps.x;\n        float3 _5712 = _4640;\n        _5712.x = _4645.x;\n        _5712.y = _4645.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _5712;\n        _5535 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _430_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _4673 = fa_tex_fix(param_12, param_13);\n    float4 _5715 = mrt;\n    _5715.x = _4673.x;\n    _5715.y = _4673.y;\n    _5715.z = _4673.z;\n    mrt = _5715;\n    float4 _4701 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _430_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _4701.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _4712 = fa_tex_fix(param_16, param_17);\n    float param_18 = _430_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _4742 = fa_tex_fix(param_20, param_21);\n    float _5540 = _430_fa_layers_a.x;\n    float _5541 = _430_fa_layers_a.y;\n    float _5544 = _430_fa_layers_a.z;\n    float _5543 = _430_fa_layers_b.w;\n    float _5546 = _430_fa_layers_c.x;\n    if (_430_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_430_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _5540 *= _4712.y;\n            _5541 *= _4712.z;\n            _5543 *= _4701.w;\n        }\n        if (_430_fa_layers_c.z > 1.5f)\n        {\n            _5544 *= mrt.x;\n            _5546 *= mrt.w;\n        }\n    }\n    Surface _5573 = { _4605.xyz, _4605.w, _5535, clamp(_430_fa_pbr.x * _4673.z, 0.0f, 1.0f), clamp(_430_fa_pbr.y * _4673.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_430_fa_maps.y * (_4712.x - 1.0f)), _430_fa_emissive.xyz + (_430_fa_model_emissive.xyz * _4742), _5540, _5541, _430_fa_layers_b.xyz, _5543, _5544, _430_fa_layers_a.w, _5546, _430_fa_layers_c.y, _430_fa_layers_d.xyz, _430_fa_tr_a.x, _430_fa_tr_a.y, _430_fa_tr_b.xyz, _430_fa_tr_a.z };\n    return _5573;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat4 fa_decal_tile(float4 rect, float2 uv, float2 atlas, float2 ddx, float2 ddy)\n{\n    float2 _1590 = rect.zw - rect.xy;\n    float2 _1594 = _1590 * atlas;\n    float2 _1598 = ddx * _1594;\n    float2 _1602 = ddy * _1594;\n    return fa_decal_tex.SampleLevel(fa_env_smp, rect.xy + (clamp(uv, 0.0f.xx, 1.0f.xx) * _1590), clamp(0.5f * log2(max(max(dot(_1598, _1598), dot(_1602, _1602)), 9.9999999392252902907785028219223e-09f)), 0.0f, 4.0f));\n}\n\nfloat3 fa_dc_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_dc_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nvoid fa_apply_decals(float3 world_pos, float3 geo_normal, inout float3 albedo, inout float3 normal)\n{\n    bool _1635 = _430_fa_counts.y < 0.5f;\n    bool _1642;\n    if (!_1635)\n    {\n        _1642 = _430_fa_counts.w < 0.5f;\n    }\n    else\n    {\n        _1642 = _1635;\n    }\n    if (_1642)\n    {\n        return;\n    }\n    float3 _1648 = ddx(world_pos);\n    float3 _1651 = ddy(world_pos);\n    float3 param = world_pos;\n    float4 _1655 = fa_cluster_texel(param);\n    int _1659 = int(_1655.w);\n    if (_1659 < 1)\n    {\n        return;\n    }\n    int _1669 = int(_430_fa_counts.y + 0.5f);\n    int param_1 = _1669;\n    float4 _1673 = fa_light_texel(param_1);\n    float2 _1676 = _1673.yz;\n    int _1680 = int(_1673.w);\n    int param_2 = _1669 + 1;\n    float4 _1685 = fa_light_texel(param_2);\n    float _1686 = _1685.x;\n    int _1692 = int(_430_fa_counts.w + 0.5f) - 1;\n    int _1696 = int(_1655.z);\n    float3 _1961;\n    for (int k = 0; k < _1659; k++)\n    {\n        int _1709 = _1696 + k;\n        int param_3 = _1680 + (_1709 >> 2);\n        int _1726 = (_1669 + 2) + (int(fa_light_texel(param_3)[_1709 & 3]) * 7);\n        int param_4 = _1726 + 6;\n        float4 _1731 = fa_light_texel(param_4);\n        if (((int(_1731.w + 0.5f) >> _1692) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1726;\n        float4 _1746 = fa_light_texel(param_5);\n        int param_6 = _1726 + 1;\n        float4 _1751 = fa_light_texel(param_6);\n        int param_7 = _1726 + 2;\n        float4 _1756 = fa_light_texel(param_7);\n        float3 _1759 = _1746.xyz;\n        float _1764 = dot(_1759, world_pos) + _1746.w;\n        float3 _1766 = _1751.xyz;\n        float _1771 = dot(_1766, world_pos) + _1751.w;\n        float3 _1773 = _1756.xyz;\n        float _1778 = dot(_1773, world_pos) + _1756.w;\n        bool _1783 = abs(_1764) > 0.5f;\n        bool _1791;\n        if (!_1783)\n        {\n            _1791 = abs(_1771) > 0.5f;\n        }\n        else\n        {\n            _1791 = _1783;\n        }\n        bool _1799;\n        if (!_1791)\n        {\n            _1799 = abs(_1778) > 0.5f;\n        }\n        else\n        {\n            _1799 = _1791;\n        }\n        if (_1799)\n        {\n            continue;\n        }\n        float _1814 = clamp(dot(geo_normal, normalize(_1773)) * _1731.z, 0.0f, 1.0f);\n        if (_1814 <= 0.0f)\n        {\n            continue;\n        }\n        float _1834 = (clamp((0.5f - abs(_1778)) * 10.0f, 0.0f, 1.0f) * _1814) * _1731.x;\n        float2 _1842 = float2(_1764 + 0.5f, 0.5f - _1771);\n        float2 _1852 = float2(dot(_1759, _1648), dot(_1766, _1648));\n        float2 _1862 = float2(dot(_1759, _1651), dot(_1766, _1651));\n        int param_8 = _1726 + 5;\n        float4 _1867 = fa_light_texel(param_8);\n        int param_9 = _1726 + 3;\n        float4 _1872 = fa_light_texel(param_9);\n        int param_10 = _1726 + 4;\n        float4 _1877 = fa_light_texel(param_10);\n        float tex_a = 1.0f;\n        float3 col = _1867.xyz;\n        bool _1887 = _1872.z > _1872.x;\n        if (_1887)\n        {\n            float4 param_11 = _1872;\n            float2 param_12 = _1842;\n            float2 param_13 = _1676;\n            float2 param_14 = _1852;\n            float2 param_15 = _1862;\n            float4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1686 > 0.5f) && (_1686 < 1.5f))\n            {\n                float3 param_16 = tx.xyz;\n                float3 _1913 = fa_dc_to_linear(param_16);\n                float4 _5623 = tx;\n                _5623.x = _1913.x;\n                _5623.y = _1913.y;\n                _5623.z = _1913.z;\n                tx = _5623;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = lerp(albedo, col, clamp((_1834 * tex_a) * _1867.w, 0.0f, 1.0f).xxx);\n        if (_1877.z > _1877.x)\n        {\n            float4 param_17 = _1877;\n            float2 param_18 = _1842;\n            float2 param_19 = _1676;\n            float2 param_20 = _1852;\n            float2 param_21 = _1862;\n            float4 _1957 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1686 > 1.5f)\n            {\n                float3 param_22 = _1957.xyz;\n                float3 _1967 = fa_dc_to_srgb(param_22);\n                _1961 = _1967;\n            }\n            else\n            {\n                _1961 = _1957.xyz;\n            }\n            float3 _1976 = (_1961 * 2.0f) - 1.0f.xxx;\n            float2 _1981 = _1976.xy * _1731.y;\n            float3 _2003 = (normalize(_1759) * _1981.x) + (normalize(_1766) * _1981.y);\n            float3 _2006 = normalize(normal);\n            normal = normalize(lerp(_2006, normalize((_2006 * max(_1976.z, 0.0500000007450580596923828125f)) + (_2003 - (_2006 * dot(_2006, _2003)))), clamp(_1834 * (_1887 ? tex_a : 1.0f), 0.0f, 1.0f).xxx));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return _5741;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(_430_fa_cl_info.x) + int(_430_fa_cl_info.w)) + ((slot + n) >> 2);\n    float4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((_430_fa_ambient.w > 4.5f) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5f;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4145;\n    if (fa_lm.z > 0.5f)\n    {\n        _4145 = 0.0f;\n    }\n    else\n    {\n        _4145 = 1.0f - clamp(_430_fa_probe_sh[0].w, 0.0f, 1.0f);\n    }\n    bool _4156 = _4145 < 1.0f;\n    bool _4162;\n    if (_4156)\n    {\n        int param = li;\n        _4162 = fa_light_baked(param);\n    }\n    else\n    {\n        _4162 = _4156;\n    }\n    return _4162 ? _4145 : 1.0f;\n}\n\nfloat3 fa_area_point(float3 c, float3 axis, float3 ru, float3 uu, float hx, float hy, float shape, float3 p, float3 r)\n{\n    bool _608 = dot(r, r) > 0.5f;\n    if (shape > 1.5f)\n    {\n        float3 _621 = (c - (ru * hx)) - p;\n        float3 _627 = ru * (2.0f * hx);\n        float _633 = max(dot(_627, _627), 9.9999999392252902907785028219223e-09f);\n        float _637 = dot(_621, _627);\n        float t = clamp((-_637) / _633, 0.0f, 1.0f);\n        if (_608)\n        {\n            float _652 = dot(r, _627);\n            float _658 = _633 - (_652 * _652);\n            if (abs(_658) > (9.9999997473787516355514526367188e-06f * _633))\n            {\n                t = clamp(((dot(r, _621) * _652) - _637) / _658, 0.0f, 1.0f);\n            }\n        }\n        return (p + _621) + (_627 * t);\n    }\n    float3 q = p;\n    float _690 = dot(r, axis);\n    bool _698;\n    if (_608)\n    {\n        _698 = abs(_690) > 9.9999997473787516355514526367188e-05f;\n    }\n    else\n    {\n        _698 = _608;\n    }\n    if (_698)\n    {\n        float _708 = dot(c - p, axis) / _690;\n        if (_708 > 0.0f)\n        {\n            q = p + (r * _708);\n        }\n    }\n    float3 _721 = q - c;\n    float2 xy = float2(dot(_721, ru), dot(_721, uu));\n    if (shape > 0.5f)\n    {\n        float _736 = length(xy);\n        if (_736 > hx)\n        {\n            xy *= (hx / _736);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, float2(-hx, -hy), float2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nfloat4 fa_atlas_fetch(float2 texel)\n{\n    uint _489_dummy_parameter;\n    return fa_light_atlas.SampleLevel(fa_env_smp, texel / float2(int2(spvTextureSize(fa_light_atlas, uint(0), _489_dummy_parameter))), 0.0f);\n}\n\nfloat3 fa_cookie_sample(float2 tile_origin, float2 uv)\n{\n    float2 param = (tile_origin + 1.0f.xx) + (clamp(uv, 0.0f.xx, 1.0f.xx) * 254.0f);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(float2 tile_origin, float3 d, float3 axis, float3 right, float3 up)\n{\n    float _528 = dot(d, right);\n    float _532 = dot(d, up);\n    float _543;\n    if (((_528 * _528) + (_532 * _532)) > 1.0000000133514319600180897396058e-10f)\n    {\n        _543 = atan2(_532, _528) * 0.15915493667125701904296875f;\n    }\n    else\n    {\n        _543 = 0.0f;\n    }\n    float2 param = tile_origin + float2(1.0f + ((_543 - floor(_543)) * 64.0f), 1.0f + (acos(clamp(dot(d, axis), -1.0f, 1.0f)) * 10.18591594696044921875f));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(float3 d)\n{\n    float3 _377 = abs(d);\n    float _379 = _377.x;\n    float _381 = _377.y;\n    bool _382 = _379 >= _381;\n    bool _390;\n    if (_382)\n    {\n        _390 = _379 >= _377.z;\n    }\n    else\n    {\n        _390 = _382;\n    }\n    int _391;\n    if (_390)\n    {\n        _391 = (d.x > 0.0f) ? 0 : 1;\n    }\n    else\n    {\n        int _406;\n        if (_381 >= _377.z)\n        {\n            _406 = (d.y > 0.0f) ? 2 : 3;\n        }\n        else\n        {\n            _406 = (d.z > 0.0f) ? 4 : 5;\n        }\n        _391 = _406;\n    }\n    return _391;\n}\n\nvoid fa_cube_face_basis(int f, out float3 fwd, out float3 up)\n{\n    if (f == 0)\n    {\n        fwd = float3(1.0f, 0.0f, 0.0f);\n        up = float3(0.0f, 1.0f, 0.0f);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = float3(-1.0f, 0.0f, 0.0f);\n            up = float3(0.0f, 1.0f, 0.0f);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = float3(0.0f, 1.0f, 0.0f);\n                up = float3(0.0f, 0.0f, 1.0f);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = float3(0.0f, -1.0f, 0.0f);\n                    up = float3(0.0f, 0.0f, -1.0f);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = float3(0.0f, 0.0f, 1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                    else\n                    {\n                        fwd = float3(0.0f, 0.0f, -1.0f);\n                        up = float3(0.0f, 1.0f, 0.0f);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, float3 world_pos, float3 n)\n{\n    int param = li;\n    int _774 = fa_light_base(param);\n    bool _778 = _430_fa_ambient.w > 4.5f;\n    int param_1 = _774;\n    float4 _782 = fa_light_texel(param_1);\n    int param_2 = _774 + 1;\n    float4 _787 = fa_light_texel(param_2);\n    float _790 = _787.w;\n    float atten = 1.0f;\n    float dist = 0.0f;\n    fa_light_tint = 1.0f.xxx;\n    bool _802 = _778 && (_790 > 2.5f);\n    fa_light_is_area = _802;\n    bool _804 = _790 < 0.5f;\n    float3 l;\n    if (_804)\n    {\n        l = normalize(_782.xyz);\n        if (_778)\n        {\n            int param_3 = _774 + 6;\n            float4 _818 = fa_light_texel(param_3);\n            if (_818.z > 0.5f)\n            {\n                int param_4 = _774 + 4;\n                float4 _828 = fa_light_texel(param_4);\n                int param_5 = _774 + 5;\n                float4 _833 = fa_light_texel(param_5);\n                float2 param_6 = _818.xy;\n                float2 param_7 = frac(float2(dot(world_pos, _828.xyz) * _828.w, (-dot(world_pos, _833.xyz)) * _833.w) + 0.5f.xx);\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        float3 _863 = _782.xyz;\n        float3 _865 = _863 - world_pos;\n        float3 to_light = _865;\n        float _868 = length(_865);\n        float reach = _868;\n        bool front = true;\n        if (_802)\n        {\n            int param_8 = _774 + 7;\n            reach = max(_868 - fa_light_texel(param_8).w, 0.0f);\n            int param_9 = _774 + 4;\n            float4 _892 = fa_light_texel(param_9);\n            int param_10 = _774 + 5;\n            float4 _897 = fa_light_texel(param_10);\n            int param_11 = _774 + 6;\n            float4 _902 = fa_light_texel(param_11);\n            float _903 = _902.w;\n            int param_12 = _774 + 2;\n            float3 _910 = normalize(fa_light_texel(param_12).xyz);\n            bool _912 = _903 > 1.5f;\n            bool _920;\n            if (!_912)\n            {\n                _920 = dot(_910, to_light) < 0.0f;\n            }\n            else\n            {\n                _920 = _912;\n            }\n            front = _920;\n            float3 r = 0.0f.xxx;\n            float3 _929 = _430_fa_camera_pos.xyz - world_pos;\n            bool _933 = dot(n, n) > 0.5f;\n            bool _941;\n            if (_933)\n            {\n                _941 = dot(_929, _929) > 9.9999999600419720025001879548654e-13f;\n            }\n            else\n            {\n                _941 = _933;\n            }\n            if (_941)\n            {\n                r = reflect(-normalize(_929), normalize(n));\n            }\n            float3 param_13 = _863;\n            float3 param_14 = _910;\n            float3 param_15 = _892.xyz;\n            float3 param_16 = _897.xyz;\n            float param_17 = _892.w;\n            float param_18 = _897.w;\n            float param_19 = _903;\n            float3 param_20 = world_pos;\n            float3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _977 = length(to_light);\n        dist = _977;\n        l = to_light / max(_977, 9.9999997473787516355514526367188e-05f).xxx;\n        float _991 = reach / max(_782.w, 0.001000000047497451305389404296875f);\n        float _997 = clamp(1.0f - (_991 * _991), 0.0f, 1.0f);\n        float _999;\n        if (front)\n        {\n            _999 = _997 * _997;\n        }\n        else\n        {\n            _999 = 0.0f;\n        }\n        atten = _999;\n        bool _1010 = _790 < 2.5f;\n        if ((_790 > 1.5f) && _1010)\n        {\n            int param_22 = _774 + 2;\n            float4 _1018 = fa_light_texel(param_22);\n            float _1028 = _1018.w;\n            int param_23 = _774 + 3;\n            float4 _1033 = fa_light_texel(param_23);\n            float _1034 = _1033.x;\n            float cos_inner = _1034;\n            if (_1034 > 1.5f)\n            {\n                cos_inner = lerp(_1028, 1.0f, 0.25f);\n            }\n            atten *= smoothstep(_1028, cos_inner, dot(-l, normalize(_1018.xyz)));\n        }\n        if (_778 && (_790 < 1.5f))\n        {\n            int param_24 = _774 + 6;\n            float4 _1058 = fa_light_texel(param_24);\n            if (_1058.z > 0.5f)\n            {\n                float3 _1066 = -to_light;\n                int param_25 = _774 + 4;\n                int param_26 = _774 + 5;\n                float3 _1080 = fa_light_texel(param_25).xyz;\n                float3 _1084 = fa_light_texel(param_26).xyz;\n                float3 _1093 = float3(dot(_1066, _1080), dot(_1066, _1084), dot(_1066, cross(_1080, _1084)));\n                float3 param_27 = _1093;\n                int _1097 = fa_cube_face(param_27);\n                int param_28 = _1097;\n                float3 param_29;\n                float3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                float2 _1124 = float2(dot(_1093, cross(param_29, param_30)), dot(_1093, param_30)) / max(dot(_1093, param_29), 9.9999997473787516355514526367188e-05f).xx;\n                int _1128 = _1097 / 3;\n                float2 param_31 = _1058.xy + (float2(float(_1097 - (_1128 * 3)), float(_1128)) * 256.0f);\n                float2 param_32 = float2(0.5f + (0.5f * _1124.x), 0.5f - (0.5f * _1124.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _774 + 7;\n            float4 _1158 = fa_light_texel(param_33);\n            if (_1158.z > 0.5f)\n            {\n                int param_34 = _774 + 2;\n                int param_35 = _774 + 4;\n                int param_36 = _774 + 5;\n                float2 param_37 = _1158.xy;\n                float3 param_38 = -l;\n                float3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                float3 param_40 = fa_light_texel(param_35).xyz;\n                float3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_778 && _1010)\n            {\n                int param_42 = _774 + 6;\n                float4 _1205 = fa_light_texel(param_42);\n                int param_43 = _774 + 7;\n                float4 _1210 = fa_light_texel(param_43);\n                bool _1213 = _1205.z > 0.5f;\n                bool _1220;\n                if (!_1213)\n                {\n                    _1220 = _1210.z > 0.5f;\n                }\n                else\n                {\n                    _1220 = _1213;\n                }\n                if (_1220)\n                {\n                    int param_44 = _774 + 2;\n                    float4 _1227 = fa_light_texel(param_44);\n                    float3 _1231 = normalize(_1227.xyz);\n                    int param_45 = _774 + 4;\n                    float4 _1236 = fa_light_texel(param_45);\n                    int param_46 = _774 + 5;\n                    float4 _1241 = fa_light_texel(param_46);\n                    if (_1213)\n                    {\n                        float3 _1249 = -to_light;\n                        float _1256 = _1227.w;\n                        float _1272 = 0.5f / max(dot(_1249, _1231) * (sqrt(max(1.0f - (_1256 * _1256), 0.0f)) / max(_1256, 0.001000000047497451305389404296875f)), 9.9999997473787516355514526367188e-05f);\n                        float2 param_47 = _1205.xy;\n                        float2 param_48 = float2(0.5f + (dot(_1249, _1236.xyz) * _1272), 0.5f - (dot(_1249, _1241.xyz) * _1272));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1210.z > 0.5f)\n                    {\n                        float2 param_49 = _1210.xy;\n                        float3 param_50 = -l;\n                        float3 param_51 = _1231;\n                        float3 param_52 = _1236.xyz;\n                        float3 param_53 = _1241.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    float3 _5341 = _787.xyz * atten;\n    if (_778)\n    {\n        _5341 *= fa_light_tint;\n    }\n    int _1341;\n    if (_804)\n    {\n        _1341 = 0;\n    }\n    else\n    {\n        _1341 = ((_790 > 1.5f) && (_790 < 2.5f)) ? 2 : 1;\n    }\n    LightSample _5352 = { l, _5341, atten, 1.0f, dist, _1341 };\n    return _5352;\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4374 = n < 0;\n    bool _4381;\n    if (!_4374)\n    {\n        _4381 = n >= fa_light_count();\n    }\n    else\n    {\n        _4381 = _4374;\n    }\n    if (_4381)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4389 = fa_cl_light(param);\n    int param_1 = _4389;\n    float _4393 = fa_baked_keep(param_1);\n    if (_4393 <= 0.0f)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4389;\n    float3 param_3 = i.world_pos;\n    float3 param_4 = i.world_normal;\n    LightSample _4409 = fa_light_sample_n(param_2, param_3, param_4);\n    LightSample _5523 = { _4409.direction, _4409.color * _4393, _4409.attenuation * _4393, _4409.shadow, _4409._distance, _4409.type };\n    return _5523;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout float2 uv, float4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return fa_shadow_tex.SampleLevel(fa_shadow_smp, uv, 0.0f).x;\n}\n\nfloat fa_shadow_fetch(float2 uv, float4 rect, float3 conv)\n{\n    float2 param = uv;\n    float4 param_1 = rect;\n    float _2135 = fa_shadow_depth(param, param_1);\n    float _2139;\n    if (conv.x < 0.5f)\n    {\n        _2139 = _2135;\n    }\n    else\n    {\n        _2139 = (conv.y * conv.z) / (conv.z - (_2135 * (conv.z - conv.y)));\n    }\n    return _2139;\n}\n\nfloat fa_shadow_noise()\n{\n    return frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f))));\n}\n\nfloat2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2066 = (float(k) * 2.3999631404876708984375f) + phi;\n    return float2(cos(_2066), sin(_2066)) * sqrt((float(k) + 0.5f) / float(n));\n}\n\nfloat fa_shadow_filter(float2 uv, float4 rect, float zr, float texel_m, float unit, float reach, float plane, float3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        float2 param = uv;\n        float4 param_1 = rect;\n        float3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2185 = fa_shadow_noise() * 6.283185482025146484375f;\n    float radius = 1.5f;\n    if (mode == 2)\n    {\n        float _2194;\n        if (k < 0.0f)\n        {\n            _2194 = (-k) / max(zr, 0.100000001490116119384765625f);\n        }\n        else\n        {\n            _2194 = k;\n        }\n        float _2214 = clamp((_2194 * reach) / texel_m, 3.0f, 12.0f);\n        float sum = 0.0f;\n        float cnt = 0.0f;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2185;\n            float2 _2233 = fa_shadow_vogel(param_3, param_4, param_5) * _2214;\n            float2 param_6 = uv + (_2233 * _2088_fa_shadow_bias.zw);\n            float4 param_7 = rect;\n            float3 param_8 = conv;\n            float _2245 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2245 < (zr - (length(_2233) * plane)))\n            {\n                sum += _2245;\n                cnt += 1.0f;\n            }\n        }\n        if (cnt < 0.5f)\n        {\n            return 1.0f;\n        }\n        float _2271 = sum / cnt;\n        float _2281;\n        if (k < 0.0f)\n        {\n            _2281 = (-k) / max(_2271, 0.0500000007450580596923828125f);\n        }\n        else\n        {\n            _2281 = k;\n        }\n        radius = clamp(((max(zr - _2271, 0.0f) * unit) * _2281) / texel_m, 1.5f, 16.0f);\n    }\n    float lit = 0.0f;\n    int _2303 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2303; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2303;\n        float param_11 = _2185;\n        float2 _2322 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        float2 param_12 = uv + (_2322 * _2088_fa_shadow_bias.zw);\n        float4 param_13 = rect;\n        float3 param_14 = conv;\n        lit += float((zr - (length(_2322) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2303);\n}\n\nfloat fa_shadow_local(int li, float3 lpos, float3 world, float3 n, float3 l)\n{\n    bool _2522 = _430_fa_pbr.z < 0.5f;\n    bool _2529;\n    if (!_2522)\n    {\n        _2529 = _2088_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _2529 = _2522;\n    }\n    if (_2529)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2088_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _2542 = fa_light_texel(param);\n    float _2543 = _2542.x;\n    if (_2543 < 0.0f)\n    {\n        return 1.0f;\n    }\n    int _2552 = int(_2543 + 0.5f);\n    int param_1 = _2552;\n    float4 _2556 = fa_light_texel(param_1);\n    int param_2 = _2552 + 1;\n    float4 _2561 = fa_light_texel(param_2);\n    float fade = 1.0f;\n    float _2564 = _2556.y;\n    if (_2564 > 0.0f)\n    {\n        float _2581 = 1.0f - smoothstep(0.75f * _2564, _2564, length(world - _2088_fa_shadow_eye.xyz));\n        fade = _2581;\n        if (_2581 <= 0.0f)\n        {\n            return 1.0f;\n        }\n    }\n    int face = 0;\n    if (_2556.x > 1.5f)\n    {\n        float3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2605 = (_2552 + 2) + (face * 6);\n    int param_4 = _2605;\n    int param_5 = _2605 + 1;\n    int param_6 = _2605 + 3;\n    float4 _2619 = fa_light_texel(param_6);\n    int param_7 = _2605 + 4;\n    float4 _2624 = fa_light_texel(param_7);\n    int param_8 = _2605 + 5;\n    float4 _2629 = fa_light_texel(param_8);\n    float _2641 = _2629.x * max(dot(_2619, float4(world, 1.0f)), 0.001000000047497451305389404296875f);\n    float _2646 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2669 = clamp(dot(n, _2619.xyz), -1.0f, 1.0f);\n    float _2688 = min(sqrt(1.0f - (_2669 * _2669)) / max(abs(dot(n, world - lpos)) / max(dot(_2619, float4(world, 1.0f)), 0.001000000047497451305389404296875f), 0.20000000298023223876953125f), 4.0f);\n    float _2691 = _2561.y;\n    float _2693;\n    if (_2691 > 0.0f)\n    {\n        _2693 = _2691;\n    }\n    else\n    {\n        _2693 = 1.5f * _2641;\n    }\n    float4 _2713 = float4(world + (n * (_2693 * sqrt(1.0f - (_2646 * _2646)))), 1.0f);\n    float _2717 = dot(_2619, _2713);\n    float _2720 = _2629.y;\n    if (_2717 < _2720)\n    {\n        return 1.0f;\n    }\n    float2 _2735 = float2(dot(fa_light_texel(param_4), _2713), dot(fa_light_texel(param_5), _2713)) / _2717.xx;\n    float _2737 = _2735.x;\n    bool _2740 = _2737 < _2624.x;\n    bool _2749;\n    if (!_2740)\n    {\n        _2749 = _2737 > _2624.z;\n    }\n    else\n    {\n        _2749 = _2740;\n    }\n    bool _2758;\n    if (!_2749)\n    {\n        _2758 = _2735.y < _2624.y;\n    }\n    else\n    {\n        _2758 = _2749;\n    }\n    bool _2767;\n    if (!_2758)\n    {\n        _2767 = _2735.y > _2624.w;\n    }\n    else\n    {\n        _2767 = _2758;\n    }\n    if (_2767)\n    {\n        return 1.0f;\n    }\n    float _2773 = _2561.x;\n    float _2775;\n    if (_2773 > 0.0f)\n    {\n        _2775 = _2773;\n    }\n    else\n    {\n        _2775 = 1.5f * _2641;\n    }\n    float2 param_9 = _2735;\n    float4 param_10 = _2624;\n    float param_11 = _2717 - (_2775 * (1.0f + (0.5f * _2688)));\n    float param_12 = _2641;\n    float param_13 = 1.0f;\n    float param_14 = _2629.z * 0.25f;\n    float param_15 = (_2641 * min(_2688, 3.0f)) * 0.5f;\n    float3 param_16 = float3(1.0f, _2720, _2629.z);\n    int param_17 = int(_2556.z + 0.5f);\n    float param_18 = _2556.w;\n    return lerp(1.0f, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2078;\n    if (i == 0)\n    {\n        _2078 = _2088_fa_shadow_split.x;\n    }\n    else\n    {\n        float _2094;\n        if (i == 1)\n        {\n            _2094 = _2088_fa_shadow_split.y;\n        }\n        else\n        {\n            float _2102;\n            if (i == 2)\n            {\n                _2102 = _2088_fa_shadow_split.z;\n            }\n            else\n            {\n                _2102 = _2088_fa_shadow_split.w;\n            }\n            _2094 = _2102;\n        }\n        _2078 = _2094;\n    }\n    return _2078;\n}\n\nfloat fa_shadow_cascade(int ci, float3 world, float3 n, float3 l)\n{\n    float _2364 = max(_2088_fa_shadow_info[ci].y, 0.001000000047497451305389404296875f);\n    float _2369 = clamp(dot(n, l), 0.0f, 1.0f);\n    float _2375 = sqrt(1.0f - (_2369 * _2369));\n    float _2382 = min(_2375 / max(_2369, 0.20000000298023223876953125f), 4.0f);\n    float _2387;\n    if (_2088_fa_shadow_bias.y > 0.0f)\n    {\n        _2387 = _2088_fa_shadow_bias.y;\n    }\n    else\n    {\n        _2387 = 1.5f * _2088_fa_shadow_info[ci].x;\n    }\n    float4 _2412 = mul(float4(world + (n * (_2387 * _2375)), 1.0f), _2088_fa_shadow_mat[ci]);\n    float _2419 = _2412.x;\n    bool _2422 = _2419 < _2088_fa_shadow_rect[ci].x;\n    bool _2431;\n    if (!_2422)\n    {\n        _2431 = _2419 > _2088_fa_shadow_rect[ci].z;\n    }\n    else\n    {\n        _2431 = _2422;\n    }\n    bool _2440;\n    if (!_2431)\n    {\n        _2440 = _2412.y < _2088_fa_shadow_rect[ci].y;\n    }\n    else\n    {\n        _2440 = _2431;\n    }\n    bool _2449;\n    if (!_2440)\n    {\n        _2449 = _2412.y > _2088_fa_shadow_rect[ci].w;\n    }\n    else\n    {\n        _2449 = _2440;\n    }\n    bool _2456;\n    if (!_2449)\n    {\n        _2456 = _2412.z > 1.0f;\n    }\n    else\n    {\n        _2456 = _2449;\n    }\n    if (_2456)\n    {\n        return -1.0f;\n    }\n    float _2464;\n    if (_2088_fa_shadow_bias.x > 0.0f)\n    {\n        _2464 = _2088_fa_shadow_bias.x;\n    }\n    else\n    {\n        _2464 = 1.5f * _2088_fa_shadow_info[ci].x;\n    }\n    float2 param = _2412.xy;\n    float4 param_1 = _2088_fa_shadow_rect[ci];\n    float param_2 = _2412.z - ((_2464 * (1.0f + (0.5f * _2382))) / _2364);\n    float param_3 = _2088_fa_shadow_info[ci].x;\n    float param_4 = _2364;\n    float param_5 = _2364 * 0.25f;\n    float param_6 = ((_2088_fa_shadow_info[ci].x * min(_2382, 3.0f)) * 0.5f) / _2364;\n    float3 param_7 = 0.0f.xxx;\n    int param_8 = int(_2088_fa_shadow_cfg.z + 0.5f);\n    float param_9 = _2088_fa_shadow_cfg.w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(float3 world, float3 n, float3 l)\n{\n    if (_430_fa_pbr.z < 0.5f)\n    {\n        return 1.0f;\n    }\n    int _2842 = int(_2088_fa_shadow_cfg.x + 0.5f);\n    if (_2842 < 1)\n    {\n        return 1.0f;\n    }\n    float _2857 = dot(world - _2088_fa_shadow_eye.xyz, _2088_fa_shadow_fwd.xyz);\n    int param = _2842 - 1;\n    if (_2857 > fa_shadow_split_at(param))\n    {\n        return 1.0f;\n    }\n    int ci = 0;\n    bool _2869 = _2842 > 1;\n    bool _2876;\n    if (_2869)\n    {\n        _2876 = _2857 > _2088_fa_shadow_split.x;\n    }\n    else\n    {\n        _2876 = _2869;\n    }\n    if (_2876)\n    {\n        ci = 1;\n    }\n    bool _2880 = _2842 > 2;\n    bool _2887;\n    if (_2880)\n    {\n        _2887 = _2857 > _2088_fa_shadow_split.y;\n    }\n    else\n    {\n        _2887 = _2880;\n    }\n    if (_2887)\n    {\n        ci = 2;\n    }\n    bool _2891 = _2842 > 3;\n    bool _2898;\n    if (_2891)\n    {\n        _2898 = _2857 > _2088_fa_shadow_split.z;\n    }\n    else\n    {\n        _2898 = _2891;\n    }\n    if (_2898)\n    {\n        ci = 3;\n    }\n    float s = -1.0f;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2842)\n        {\n            break;\n        }\n        int param_1 = ci;\n        float3 param_2 = world;\n        float3 param_3 = n;\n        float3 param_4 = l;\n        float _2924 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2924;\n        if (_2924 >= 0.0f)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0f)\n    {\n        return 1.0f;\n    }\n    if (_2088_fa_shadow_cfg.y > 0.0f)\n    {\n        float _2949;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2949 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2949 = _2088_fa_shadow_fwd.w;\n        }\n        int param_6 = ci;\n        float _2968 = _2088_fa_shadow_cfg.y * max(fa_shadow_split_at(param_6) - _2949, 9.9999997473787516355514526367188e-05f);\n        int param_7 = ci;\n        float _2979 = clamp((_2857 - (fa_shadow_split_at(param_7) - _2968)) / _2968, 0.0f, 1.0f);\n        if (_2979 > 0.0f)\n        {\n            float s2 = 1.0f;\n            if ((ci + 1) < _2842)\n            {\n                int param_8 = ci + 1;\n                float3 param_9 = world;\n                float3 param_10 = n;\n                float3 param_11 = l;\n                float _3000 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3000;\n                if (_3000 < 0.0f)\n                {\n                    s2 = s;\n                }\n            }\n            s = lerp(s, s2, _2979);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(float3 n, float3 l)\n{\n    float3 param = fa_world_pos;\n    float3 param_1 = n;\n    float3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, float3 world, float3 gn, float3 l, float dist)\n{\n    bool _3889 = _430_fa_ct_a.x < 0.5f;\n    bool _3896;\n    if (!_3889)\n    {\n        _3896 = _2088_fa_shadow_lcfg.x < 0.5f;\n    }\n    else\n    {\n        _3896 = _3889;\n    }\n    if (_3896)\n    {\n        return 1.0f;\n    }\n    int param = (int(_2088_fa_shadow_lcfg.x + 0.5f) - 1) + li;\n    float4 _3909 = fa_light_texel(param);\n    float _3910 = _3909.y;\n    float len = _3910;\n    if (_3910 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3922 = length(world - _430_fa_camera_pos.xyz);\n    float _3932 = 1.0f - smoothstep(0.5f * _430_fa_ct_b.x, _430_fa_ct_b.x, _3922);\n    if (_3932 <= 0.0f)\n    {\n        return 1.0f;\n    }\n    float _3938 = len;\n    float _3941 = min(_3938, 0.89999997615814208984375f * dist);\n    len = _3941;\n    float _3946 = 0.004999999888241291046142578125f + (0.0030000000260770320892333984375f * _3922);\n    float _3951 = _3946 + (0.5f * _3941);\n    float3 _3957 = world + (gn * _3946);\n    float _3959 = fa_shadow_noise();\n    float occ = 0.0f;\n    float _4023;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3974 = (float(k) + _3959) * 0.083333335816860198974609375f;\n        float3 _3982 = _3957 + (l * (_3974 * len));\n        float4 _3988 = float4(_3982, 1.0f);\n        float _3994 = dot(_430_fa_ct_vpw, _3988);\n        if (_3994 < 9.9999997473787516355514526367188e-05f)\n        {\n            break;\n        }\n        float2 _4014 = float2(dot(_430_fa_ct_vpx, _3988), dot(_430_fa_ct_vpy, _3988)) / _3994.xx;\n        float _4018 = _4014.x * 0.5f;\n        float _4019 = _4018 + 0.5f;\n        if (_430_fa_ct_a.y > 0.5f)\n        {\n            _4023 = (_4014.y * 0.5f) + 0.5f;\n        }\n        else\n        {\n            _4023 = 0.5f - (_4014.y * 0.5f);\n        }\n        bool _4039 = _4019 < 0.0f;\n        bool _4046;\n        if (!_4039)\n        {\n            _4046 = _4019 >= 1.0f;\n        }\n        else\n        {\n            _4046 = _4039;\n        }\n        bool _4053;\n        if (!_4046)\n        {\n            _4053 = _4023 < 0.0f;\n        }\n        else\n        {\n            _4053 = _4046;\n        }\n        bool _4060;\n        if (!_4053)\n        {\n            _4060 = _4023 >= 1.0f;\n        }\n        else\n        {\n            _4060 = _4053;\n        }\n        if (_4060)\n        {\n            break;\n        }\n        float4 _4079 = fa_screen_tex.Load(int3(int2(float2(_4019, _4023) * _430_fa_ct_a.zw), 0));\n        if (_4079.w < 0.5f)\n        {\n            continue;\n        }\n        float _4098 = (dot(_430_fa_ct_fwd.xyz, _3982) + _430_fa_ct_fwd.w) - _4079.x;\n        if ((_4098 > _3946) && (_4098 < _3951))\n        {\n            occ = max(occ, (1.0f - (_3974 * _3974)) * smoothstep(0.0f, 0.0500000007450580596923828125f, min(min(_4019, 0.5f - _4018), min(_4023, 1.0f - _4023))));\n        }\n    }\n    return 1.0f - (occ * _3932);\n}\n\nLightSample fa_light_shadowed(int li, float3 world_pos, float3 gn)\n{\n    int param = li;\n    float _4201 = fa_baked_keep(param);\n    if (_4201 <= 0.0f)\n    {\n        int param_1 = li;\n        LightSample _5485 = { float3(0.0f, 1.0f, 0.0f), 0.0f.xxx, 0.0f, 1.0f, 0.0f, int(fa_light_type(param_1) + 0.5f) };\n        return _5485;\n    }\n    int param_2 = li;\n    float3 param_3 = world_pos;\n    float3 param_4 = gn;\n    LightSample _4227 = fa_light_sample_n(param_2, param_3, param_4);\n    float3 _5487 = _4227.color;\n    float _5488 = _4227.attenuation;\n    float _5489 = _4227.shadow;\n    bool _4230 = _4227.type == 0;\n    if (_4230 && (li == 0))\n    {\n        float3 param_5 = gn;\n        float3 param_6 = _4227.direction;\n        float _4241 = fa_shadow_factor(param_5, param_6);\n        _5489 = _4241;\n        _5487 *= _4241;\n    }\n    else\n    {\n        bool _4252 = _4227.type != 0;\n        bool _4258;\n        if (_4252)\n        {\n            _4258 = _5488 > 0.0f;\n        }\n        else\n        {\n            _4258 = _4252;\n        }\n        if (_4258)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            float3 param_10 = fa_light_texel(param_8).xyz;\n            float3 param_11 = world_pos;\n            float3 param_12 = gn;\n            float3 param_13 = _4227.direction;\n            float _4277 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5489 = _4277;\n            _5487 *= _4277;\n        }\n    }\n    bool _4287 = _430_fa_ct_a.x > 0.5f;\n    bool _4293;\n    if (_4287)\n    {\n        _4293 = _5488 > 0.0f;\n    }\n    else\n    {\n        _4293 = _4287;\n    }\n    if (_4293)\n    {\n        float _4300;\n        if (_4230)\n        {\n            _4300 = 1000000000.0f;\n        }\n        else\n        {\n            _4300 = _4227._distance;\n        }\n        int param_14 = li;\n        float3 param_15 = world_pos;\n        float3 param_16 = gn;\n        float3 param_17 = _4227.direction;\n        float param_18 = _4300;\n        float _4318 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5489 *= _4318;\n        _5487 *= _4318;\n    }\n    float _4331 = _5488;\n    float _4332 = _4331 * _4201;\n    _5488 = _4332;\n    float3 _4336 = _5487;\n    float3 _4337 = _4336 * _4201;\n    _5487 = _4337;\n    LightSample _5504 = { _4227.direction, _4337, _4332, _5489, _4227._distance, _4227.type };\n    return _5504;\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4348 = n < 0;\n    bool _4355;\n    if (!_4348)\n    {\n        _4355 = n >= fa_light_count();\n    }\n    else\n    {\n        _4355 = _4348;\n    }\n    if (_4355)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    float3 param_2 = i.world_pos;\n    float3 param_3 = i.world_normal;\n    LightSample _4370 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4370;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3279 = min(sqrt(max(rough - 0.100000001490116119384765625f, 0.0f) * 1.111111164093017578125f) * 6.0f, 5.999000072479248046875f);\n    float _3287 = min(sqrt(clamp(ndv, 0.0f, 1.0f)) * 8.0f, 7.999000072479248046875f);\n    int _3290 = int(_3279);\n    int _3293 = int(_3287);\n    float _3303 = _3287 - float(_3293);\n    int _3359 = (_3290 * 9) + _3293;\n    int _3379 = ((_3290 + 1) * 9) + _3293;\n    return lerp(lerp(_3354[_3359], _3354[_3359 + 1], _3303), lerp(_3354[_3379], _3354[_3379 + 1], _3303), _3279 - float(_3290));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, float3 n, float3 v, float metallic, float roughness, inout float3 f0)\n{\n    bool _5353 = false;\n    float _5354 = 1.0f;\n    float _5355 = 1.0f;\n    float _5356 = 1.0f;\n    float _5357 = 0.0f;\n    float _5358 = 0.0f;\n    float _5359 = 0.0f;\n    float _5360 = 0.0f;\n    float _5362 = 1.0f;\n    bool _5363 = false;\n    float3 _5364 = 0.0f.xxx;\n    float _5365 = 1.0f;\n    float _5366 = 1.0f;\n    float _5367 = 1.0f;\n    float _5368 = 0.0f;\n    float _5369 = 0.0f;\n    float3 _5370 = float3(1.0f, 0.0f, 0.0f);\n    float3 _5371 = float3(0.0f, 0.0f, 1.0f);\n    float _5372 = 1.0f;\n    float _5373 = 1.0f;\n    float _3430 = clamp(s.specular, 0.0f, 1.0f);\n    float _3434 = clamp(s.ior, 1.0f, 3.0f);\n    bool _3439 = (_3430 != 1.0f) || (_3434 != 1.5f);\n    bool _3448;\n    if (!_3439)\n    {\n        _3448 = any(bool3(s.specular_color.x != 1.0f.xxx.x, s.specular_color.y != 1.0f.xxx.y, s.specular_color.z != 1.0f.xxx.z));\n    }\n    else\n    {\n        _3448 = _3439;\n    }\n    if (_3448)\n    {\n        float _3456 = (_3434 - 1.0f) / (_3434 + 1.0f);\n        f0 = lerp(min((_3456 * _3456).xxx * max(s.specular_color, 0.0f.xxx), 1.0f.xxx) * _3430, s.albedo, metallic.xxx);\n        _5354 = lerp(_3430, 1.0f, metallic);\n        _5353 = true;\n    }\n    float _3483 = clamp(s.clearcoat, 0.0f, 1.0f);\n    if (_3483 > 0.0f)\n    {\n        float _3491 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125f, 1.0f);\n        _5357 = _3483;\n        _5358 = _3491;\n        float _3498 = _3491 * _3491;\n        _5359 = _3498;\n        _5360 = _3498 * _3498;\n        float _3510 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05f);\n        _5362 = _3510;\n        _5355 = 1.0f - (_3483 * (0.039999999105930328369140625f + (0.959999978542327880859375f * pow(clamp(1.0f - _3510, 0.0f, 1.0f), 5.0f))));\n        _5353 = true;\n    }\n    float3 _3530 = max(s.sheen_color, 0.0f.xxx);\n    float _3539 = max(_3530.x, max(_3530.y, _3530.z));\n    if (_3539 > 0.0f)\n    {\n        float _3547 = clamp(s.sheen_roughness, 0.100000001490116119384765625f, 1.0f);\n        _5363 = true;\n        _5364 = _3530;\n        _5365 = _3547;\n        _5366 = _3547 * _3547;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n        float param_1 = _3547;\n        float _3564 = fa_sheen_albedo(param, param_1);\n        _5368 = _3564;\n        _5367 = 1.0f - min(_3539 * _3564, 1.0f);\n        _5353 = true;\n    }\n    _5356 = _5355 * _5367;\n    float _3583 = clamp(s.anisotropy, -1.0f, 1.0f);\n    if (_3583 != 0.0f)\n    {\n        float3 _3598 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        float3 t = _3598;\n        if (dot(_3598, _3598) < 9.9999999392252902907785028219223e-09f)\n        {\n            bool3 _3610 = (abs(n.y) < 0.9900000095367431640625f).xxx;\n            t = cross(float3(_3610.x ? float3(0.0f, 1.0f, 0.0f).x : float3(1.0f, 0.0f, 0.0f).x, _3610.y ? float3(0.0f, 1.0f, 0.0f).y : float3(1.0f, 0.0f, 0.0f).y, _3610.z ? float3(0.0f, 1.0f, 0.0f).z : float3(1.0f, 0.0f, 0.0f).z), n);\n        }\n        float3 _3614 = t;\n        float3 _3615 = normalize(_3614);\n        t = _3615;\n        float3 _3640 = normalize((_3615 * cos(s.anisotropy_rotation)) + ((cross(n, _3615) * ((i.world_tangent.w < 0.0f) ? (-1.0f) : 1.0f)) * sin(s.anisotropy_rotation)));\n        _5370 = _3640;\n        _5371 = cross(n, _3640);\n        float _3650 = roughness * roughness;\n        float _3656 = lerp(_3650, 1.0f, _3583 * _3583);\n        bool _3658 = _3583 > 0.0f;\n        _5372 = _3658 ? _3656 : _3650;\n        _5373 = _3658 ? _3650 : _3656;\n        _5369 = _3583;\n        _5353 = true;\n    }\n    FaLayers _5395 = { _5353, _5354, _5355, _5356, _5357, _5358, _5359, _5360, i.world_normal, _5362, _5363, _5364, _5365, _5366, _5367, _5368, _5369, _5370, _5371, _5372, _5373 };\n    return _5395;\n}\n\nfloat2 fa_env_brdf(float rough, float ndv)\n{\n    float4 _3211 = (float4(-1.0f, -0.0274999998509883880615234375f, -0.572000026702880859375f, 0.02199999988079071044921875f) * rough) + float4(1.0f, 0.0425000004470348358154296875f, 1.03999996185302734375f, -0.039999999105930328369140625f);\n    float _3214 = _3211.x;\n    return (float2(-1.03999996185302734375f, 1.03999996185302734375f) * ((min(_3214 * _3214, exp2((-9.27999973297119140625f) * ndv)) * _3214) + _3211.y)) + _3211.zw;\n}\n\nfloat3 fa_environment(float3 d, float rough)\n{\n    if (_430_fa_env_sky.w > 0.5f)\n    {\n        return fa_env_tex.SampleLevel(fa_env_smp, d, clamp(rough, 0.0f, 1.0f) * _430_fa_env_horizon.w).xyz;\n    }\n    float _3135 = rough * rough;\n    float _3165 = 0.60000002384185791015625f * _3135;\n    return lerp(lerp(_430_fa_env_horizon.xyz * 0.550000011920928955078125f, lerp(_430_fa_env_horizon.xyz, _430_fa_env_sky.xyz, pow(clamp(d.y * (1.0f - (0.699999988079071044921875f * _3135)), 0.0f, 1.0f), 0.550000011920928955078125f).xxx), smoothstep((-0.0500000007450580596923828125f) - _3165, 0.0500000007450580596923828125f + _3165, d.y).xxx), ((_430_fa_env_sky.xyz + _430_fa_env_horizon.xyz) * 0.5f) * 0.800000011920928955078125f, (_3135 * 0.60000002384185791015625f).xxx);\n}\n\nfloat3 fa_layers_ibl(FaLayers L, float3 n, float3 v, float3 f0, float roughness)\n{\n    float3 rn = n;\n    if (L.aniso != 0.0f)\n    {\n        float3 _3691;\n        if (L.aniso >= 0.0f)\n        {\n            _3691 = L.b;\n        }\n        else\n        {\n            _3691 = L.t;\n        }\n        rn = normalize(lerp(n, cross(cross(_3691, v), _3691), abs(L.aniso).xxx));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3724 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    float3 result = (fa_environment(param_2, param_3) * ((f0 * _3724.x) + (L.f90.xxx * _3724.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        float3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0f)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        float2 _3779 = fa_env_brdf(param_6, param_7);\n        float3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625f * _3779.x) + _3779.y)));\n    }\n    return result;\n}\n\nfloat3 fa_sky_reflection(float3 n, float3 v, float3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05f);\n    float2 _3253 = fa_env_brdf(param, param_1);\n    float3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3253.x) + _3253.y.xxx);\n}\n\nfloat3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3818 = clamp(s.metallic, 0.0f, 1.0f);\n    float _3822 = clamp(s.roughness, 0.0500000007450580596923828125f, 1.0f);\n    float3 _3829 = lerp(0.039999999105930328369140625f.xxx, s.albedo, _3818.xxx);\n    float3 f0 = _3829;\n    float3 _3833 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    float3 param_2 = _3833;\n    float3 param_3 = i.view_dir;\n    float param_4 = _3818;\n    float param_5 = _3822;\n    float3 param_6 = _3829;\n    FaLayers _3850 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3850.on)\n    {\n        FaLayers param_7 = _3850;\n        float3 param_8 = _3833;\n        float3 param_9 = i.view_dir;\n        float3 param_10 = f0;\n        float param_11 = _3822;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    float3 param_12 = _3833;\n    float3 param_13 = i.view_dir;\n    float3 param_14 = f0;\n    float param_15 = _3822;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nfloat3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0f;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _4440 = fa_light_unshadowed(param, param_1);\n        float _4448 = dot(_4440.color, float3(0.2989999949932098388671875f, 0.58700001239776611328125f, 0.114000000059604644775390625f));\n        if (_4448 > bestPower)\n        {\n            bestPower = _4448;\n            best = n;\n        }\n    }\n    float3 lit = (_430_fa_ambient.xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _4477 = fa_light(param_2, param_3);\n        float _4485;\n        if (dot(s.normal, _4477.direction) > 0.5f)\n        {\n            _4485 = 1.0f;\n        }\n        else\n        {\n            _4485 = _4491_dark;\n        }\n        lit += ((s.albedo * _4477.color) * _4485);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * _4491_skyAmount);\n}\n\nfloat3 fa_shadow_debug(float3 color, float3 world)\n{\n    if (_2088_fa_shadow_eye.w < 0.5f)\n    {\n        return color;\n    }\n    int _3024 = int(_2088_fa_shadow_cfg.x + 0.5f);\n    float _3034 = dot(world - _2088_fa_shadow_eye.xyz, _2088_fa_shadow_fwd.xyz);\n    float3 tint = 0.3499999940395355224609375f.xxx;\n    bool _3039 = _3024 > 0;\n    bool _3048;\n    if (_3039)\n    {\n        int param = _3024 - 1;\n        _3048 = _3034 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3048 = _3039;\n    }\n    if (_3048)\n    {\n        tint = float3(1.0f, 0.1500000059604644775390625f, 0.100000001490116119384765625f);\n        bool _3054 = _3024 > 1;\n        bool _3061;\n        if (_3054)\n        {\n            _3061 = _3034 > _2088_fa_shadow_split.x;\n        }\n        else\n        {\n            _3061 = _3054;\n        }\n        if (_3061)\n        {\n            tint = float3(0.100000001490116119384765625f, 0.89999997615814208984375f, 0.20000000298023223876953125f);\n        }\n        bool _3067 = _3024 > 2;\n        bool _3074;\n        if (_3067)\n        {\n            _3074 = _3034 > _2088_fa_shadow_split.y;\n        }\n        else\n        {\n            _3074 = _3067;\n        }\n        if (_3074)\n        {\n            tint = float3(0.1500000059604644775390625f, 0.300000011920928955078125f, 1.0f);\n        }\n        bool _3080 = _3024 > 3;\n        bool _3087;\n        if (_3080)\n        {\n            _3087 = _3034 > _2088_fa_shadow_split.z;\n        }\n        else\n        {\n            _3087 = _3080;\n        }\n        if (_3087)\n        {\n            tint = float3(1.0f, 0.89999997615814208984375f, 0.100000001490116119384765625f);\n        }\n    }\n    return lerp(color, tint, 0.550000011920928955078125f.xxx);\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _5207 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5207 = -_5207;\n    }\n    float3 _4878 = normalize(_430_fa_camera_pos.xyz - fa_world_pos);\n    float3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput _5220 = { fa_world_pos, _5207, fa_world_tangent, fa_uv, fa_vertex_color, _4878, gl_FrontFacing };\n    SurfaceInput param_1 = _5220;\n    Surface _4886 = fa_standard_surface(param_1);\n    float3 _5238 = _4886.albedo;\n    float _5239 = _4886.alpha;\n    float3 _5240 = _4886.normal;\n    float _5241 = _4886.metallic;\n    float _5242 = _4886.roughness;\n    float _5243 = _4886.occlusion;\n    float3 _5244 = _4886.emission;\n    float _5245 = _4886.clearcoat;\n    float _5246 = _4886.clearcoat_roughness;\n    float3 _5247 = _4886.sheen_color;\n    float _5248 = _4886.sheen_roughness;\n    float _5249 = _4886.anisotropy;\n    float _5250 = _4886.anisotropy_rotation;\n    float _5251 = _4886.specular;\n    float _5252 = _4886.ior;\n    float3 _5253 = _4886.specular_color;\n    float _5254 = _4886.transmission;\n    float _5255 = _4886.thickness;\n    float3 _5256 = _4886.attenuation_color;\n    float _5257 = _4886.attenuation_distance;\n    SurfaceInput _5228 = { fa_world_pos, _5207, fa_world_tangent, fa_uv, fa_vertex_color, _4878, gl_FrontFacing };\n    SurfaceInput param_2 = _5228;\n    Surface param_3 = _4886;\n    surface(param_2, param_3);\n    _5238 = param_3.albedo;\n    _5239 = param_3.alpha;\n    _5240 = param_3.normal;\n    _5241 = param_3.metallic;\n    _5242 = param_3.roughness;\n    _5243 = param_3.occlusion;\n    _5244 = param_3.emission;\n    _5245 = param_3.clearcoat;\n    _5246 = param_3.clearcoat_roughness;\n    _5247 = param_3.sheen_color;\n    _5248 = param_3.sheen_roughness;\n    _5249 = param_3.anisotropy;\n    _5250 = param_3.anisotropy_rotation;\n    _5251 = param_3.specular;\n    _5252 = param_3.ior;\n    _5253 = param_3.specular_color;\n    _5254 = param_3.transmission;\n    _5255 = param_3.thickness;\n    _5256 = param_3.attenuation_color;\n    _5257 = param_3.attenuation_distance;\n    float3 param_4 = fa_world_pos;\n    float3 param_5 = _5207;\n    float3 param_6 = param_3.albedo;\n    float3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5238 = param_6;\n    _5240 = param_7;\n    float3 result;\n    if (_430_fa_emissive.w > 0.5f)\n    {\n        result = _5238;\n    }\n    else\n    {\n        float3 _4925 = _5240;\n        float3 _4926 = normalize(_4925);\n        _5240 = _4926;\n        SurfaceInput _5236 = { fa_world_pos, _5207, fa_world_tangent, fa_uv, fa_vertex_color, _4878, gl_FrontFacing };\n        SurfaceInput param_8 = _5236;\n        Surface _5339 = { _5238, _5239, _4926, _5241, _5242, _5243, _5244, _5245, _5246, _5247, _5248, _5249, _5250, _5251, _5252, _5253, _5254, _5255, _5256, _5257 };\n        Surface param_9 = _5339;\n        float3 _4937 = lighting(param_8, param_9);\n        result = _4937;\n    }\n    float3 _4941 = result;\n    float3 _4942 = _4941 + _5244;\n    result = _4942;\n    float3 param_10 = _4942;\n    float3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _4951 = _430_fa_fog.w > 0.0f;\n    bool _4958;\n    if (!_4951)\n    {\n        _4958 = _430_fa_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _4958 = _4951;\n    }\n    if (_4958)\n    {\n        float3 _4967 = fa_world_pos - _430_fa_camera_pos.xyz;\n        float _4973 = dot(_4967, _430_fa_fog_c.xyz);\n        bool _4977 = _430_fa_fog_c.w > 0.5f;\n        float _4978;\n        if (_4977)\n        {\n            _4978 = _4973;\n        }\n        else\n        {\n            _4978 = length(_4967);\n        }\n        float _4990 = _4978 - _430_fa_fog_b.x;\n        if (_4990 > 0.0f)\n        {\n            float _4999 = _430_fa_fog.w * _4990;\n            float tau = _4999 * _4999;\n            if (_430_fa_fog_b.y > 0.0f)\n            {\n                float _5015;\n                if (_4977)\n                {\n                    _5015 = fa_world_pos.y - (_430_fa_fog_c.y * _4973);\n                }\n                else\n                {\n                    _5015 = _430_fa_camera_pos.y;\n                }\n                float _5036 = lerp(_5015, fa_world_pos.y, clamp(_430_fa_fog_b.x / _4978, 0.0f, 1.0f));\n                float _5040 = fa_world_pos.y - _5036;\n                float _5045 = _5036 - _430_fa_fog_b.z;\n                float _5050 = fa_world_pos.y - _430_fa_fog_b.z;\n                bool _5053 = _5045 <= 0.0f;\n                bool _5054 = !_5053;\n                bool _5060;\n                if (_5054)\n                {\n                    _5060 = _430_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5060 = _5053;\n                }\n                float _5061;\n                if (_5060)\n                {\n                    _5061 = _430_fa_fog_b.y;\n                }\n                else\n                {\n                    _5061 = _430_fa_fog_b.y * exp(-min(_430_fa_fog_b.w * _5045, 80.0f));\n                }\n                bool _5088;\n                if (_5054)\n                {\n                    _5088 = _430_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5088 = _5053;\n                }\n                float _5089;\n                if (_5088)\n                {\n                    _5089 = _430_fa_fog_b.y * _5045;\n                }\n                else\n                {\n                    _5089 = (_430_fa_fog_b.y * (1.0f - exp(-min(_430_fa_fog_b.w * _5045, 80.0f)))) / _430_fa_fog_b.w;\n                }\n                bool _5114 = _5050 <= 0.0f;\n                bool _5121;\n                if (!_5114)\n                {\n                    _5121 = _430_fa_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _5121 = _5114;\n                }\n                float _5122;\n                if (_5121)\n                {\n                    _5122 = _430_fa_fog_b.y * _5050;\n                }\n                else\n                {\n                    _5122 = (_430_fa_fog_b.y * (1.0f - exp(-min(_430_fa_fog_b.w * _5050, 80.0f)))) / _430_fa_fog_b.w;\n                }\n                float _5149;\n                if (abs(_5040) < 0.001000000047497451305389404296875f)\n                {\n                    _5149 = _5061;\n                }\n                else\n                {\n                    _5149 = (_5122 - _5089) / _5040;\n                }\n                tau += (_4990 * max(_5149, 0.0f));\n            }\n            result = lerp(result, _430_fa_fog.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n        }\n    }\n    fa_frag_color = float4(result, _5239);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_lm = stage_input.fa_lm;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 656,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_430",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2088",
            "hlsl_register_b_n": 7
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_4491",
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
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10
          }
        ]
      }
    },
    "prepass": {
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _131_fa_view_proj : packoffset(c0);\n    row_major float4x4 _131_fa_light_vp : packoffset(c4);\n    float4 _131_fa_uv_scale : packoffset(c8);\n    float4 _131_fa_time : packoffset(c9);\n    float4 _131_fa_lm_so : packoffset(c10);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _295 = { mul(float4(position, 1.0f), model).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * _131_fa_uv_scale.xy, color, position };\n    return _295;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _302 = _160.world_pos;\n    float4 _171 = float4(_302, 1.0f);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -mul(_171, _131_fa_light_vp).z;\n    fa_pre_r0 = float3(_131_fa_light_vp[0].x, _131_fa_light_vp[1].x, _131_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_131_fa_light_vp[0].y, _131_fa_light_vp[1].y, _131_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_131_fa_light_vp[0].z, _131_fa_light_vp[1].z, _131_fa_light_vp[2].z);\n    gl_Position = mul(_171, _131_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4x4 param = float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    float3 param_1 = fa_position;\n    float3 param_2 = fa_normal;\n    float4 param_3 = fa_tangent;\n    float2 param_4 = fa_texcoord0;\n    float4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _215_fa_camera_pos : packoffset(c0);\n    float4 _215_fa_ambient : packoffset(c1);\n    float4 _215_fa_base_color : packoffset(c2);\n    float4 _215_fa_emissive : packoffset(c3);\n    float4 _215_fa_model_emissive : packoffset(c4);\n    float4 _215_fa_pbr : packoffset(c5);\n    float4 _215_fa_maps : packoffset(c6);\n    float4 _215_fa_fog : packoffset(c7);\n    float4 _215_fa_fog_b : packoffset(c8);\n    float4 _215_fa_fog_c : packoffset(c9);\n    float4 _215_fa_counts : packoffset(c10);\n    float4 _215_fa_env_sky : packoffset(c11);\n    float4 _215_fa_env_horizon : packoffset(c12);\n    float4 _215_fa_time : packoffset(c13);\n    float4 _215_fa_cl_vpx : packoffset(c14);\n    float4 _215_fa_cl_vpy : packoffset(c15);\n    float4 _215_fa_cl_vpw : packoffset(c16);\n    float4 _215_fa_cl_fwd : packoffset(c17);\n    float4 _215_fa_cl_grid : packoffset(c18);\n    float4 _215_fa_cl_info : packoffset(c19);\n    float4 _215_fa_layers_a : packoffset(c20);\n    float4 _215_fa_layers_b : packoffset(c21);\n    float4 _215_fa_layers_c : packoffset(c22);\n    float4 _215_fa_layers_d : packoffset(c23);\n    float4 _215_fa_ct_a : packoffset(c24);\n    float4 _215_fa_ct_b : packoffset(c25);\n    float4 _215_fa_ct_vpx : packoffset(c26);\n    float4 _215_fa_ct_vpy : packoffset(c27);\n    float4 _215_fa_ct_vpw : packoffset(c28);\n    float4 _215_fa_ct_fwd : packoffset(c29);\n    float4 _215_fa_tr_a : packoffset(c30);\n    float4 _215_fa_tr_b : packoffset(c31);\n    float4 _215_fa_probe_sh[9] : packoffset(c32);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _215_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _227 = fa_tex_fix(param_2, param_3);\n    float4 _833 = base_t;\n    _833.x = _227.x;\n    _833.y = _227.y;\n    _833.z = _227.z;\n    base_t = _833;\n    float4 _243 = (_833 * _215_fa_base_color) * i.vertex_color;\n    float3 _788 = i.world_normal;\n    if (_215_fa_maps.z > 0.5f)\n    {\n        float param_4 = _215_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _277 = fa_tex_fix(param_6, param_7);\n        float3 _281 = (_277 * 2.0f) - 1.0f.xxx;\n        float2 _286 = _281.xy * _215_fa_maps.x;\n        float3 _841 = _281;\n        _841.x = _286.x;\n        _841.y = _286.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _841;\n        _788 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _215_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _315 = fa_tex_fix(param_12, param_13);\n    float4 _844 = mrt;\n    _844.x = _315.x;\n    _844.y = _315.y;\n    _844.z = _315.z;\n    mrt = _844;\n    float4 _345 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _215_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = _215_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _387 = fa_tex_fix(param_20, param_21);\n    float _793 = _215_fa_layers_a.x;\n    float _794 = _215_fa_layers_a.y;\n    float _797 = _215_fa_layers_a.z;\n    float _796 = _215_fa_layers_b.w;\n    float _799 = _215_fa_layers_c.x;\n    if (_215_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_215_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _793 *= _357.y;\n            _794 *= _357.z;\n            _796 *= _345.w;\n        }\n        if (_215_fa_layers_c.z > 1.5f)\n        {\n            _797 *= mrt.x;\n            _799 *= mrt.w;\n        }\n    }\n    Surface _826 = { _243.xyz, _243.w, _788, clamp(_215_fa_pbr.x * _315.z, 0.0f, 1.0f), clamp(_215_fa_pbr.y * _315.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_215_fa_maps.y * (_357.x - 1.0f)), _215_fa_emissive.xyz + (_215_fa_model_emissive.xyz * _387), _793, _794, _215_fa_layers_b.xyz, _796, _797, _215_fa_layers_a.w, _799, _215_fa_layers_c.y, _215_fa_layers_d.xyz, _215_fa_tr_a.x, _215_fa_tr_a.y, _215_fa_tr_b.xyz, _215_fa_tr_a.z };\n    return _826;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _683 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _683 = -_683;\n    }\n    float3 _540 = normalize(_215_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _696 = { fa_world_pos, _683, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing };\n    SurfaceInput param = _696;\n    SurfaceInput _704 = { fa_world_pos, _683, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing };\n    SurfaceInput param_1 = _704;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _555 = normalize(param_2.normal);\n    float3 _570 = normalize(float3(dot(fa_pre_r0, _555), dot(fa_pre_r1, _555), dot(fa_pre_r2, _555)));\n    float _582 = _570.z;\n    float2 e = _570.xy / ((abs(_570.x) + abs(_570.y)) + abs(_582)).xx;\n    if (_582 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 656,
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
      "vs": "struct VertexData\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 color;\n    float3 object_pos;\n};\n\ncbuffer fa_mesh_vs_params : register(b0)\n{\n    row_major float4x4 _136_fa_view_proj : packoffset(c0);\n    row_major float4x4 _136_fa_light_vp : packoffset(c4);\n    float4 _136_fa_uv_scale : packoffset(c8);\n    float4 _136_fa_time : packoffset(c9);\n    float4 _136_fa_lm_so : packoffset(c10);\n};\n\ncbuffer fa_skin : register(b3)\n{\n    float4 _183_fa_joint_rows[192] : packoffset(c0);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float fa_pre_depth;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_inst_m0;\nstatic float4 fa_inst_m1;\nstatic float4 fa_inst_m2;\nstatic float4 fa_inst_m3;\nstatic float4 fa_joints;\nstatic float4 fa_weights;\nstatic float3 fa_position;\nstatic float3 fa_normal;\nstatic float4 fa_tangent;\nstatic float2 fa_texcoord0;\nstatic float4 fa_color;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_position : TEXCOORD0;\n    float3 fa_normal : TEXCOORD1;\n    float2 fa_texcoord0 : TEXCOORD2;\n    float4 fa_tangent : TEXCOORD3;\n    float4 fa_color : TEXCOORD4;\n    float4 fa_inst_m0 : TEXCOORD5;\n    float4 fa_inst_m1 : TEXCOORD6;\n    float4 fa_inst_m2 : TEXCOORD7;\n    float4 fa_inst_m3 : TEXCOORD8;\n    float4 fa_joints : TEXCOORD9;\n    float4 fa_weights : TEXCOORD10;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nvoid fa_inst_begin()\n{\n}\n\nfloat4x4 fa_skin_matrix(float4 joints, float4 weights)\n{\n    float4 r0 = 0.0f.xxxx;\n    float4 r1 = 0.0f.xxxx;\n    float4 r2 = 0.0f.xxxx;\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0f) + 0.5f) * 3;\n        r0 += (_183_fa_joint_rows[_174] * weights[i]);\n        r1 += (_183_fa_joint_rows[_174 + 1] * weights[i]);\n        r2 += (_183_fa_joint_rows[_174 + 2] * weights[i]);\n    }\n    return float4x4(float4(r0.x, r1.x, r2.x, 0.0f), float4(r0.y, r1.y, r2.y, 0.0f), float4(r0.z, r1.z, r2.z, 0.0f), float4(r0.w, r1.w, r2.w, 1.0f));\n}\n\nVertexData fa_vertex_data(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0f) ? (-1.0f) : 1.0f;\n    VertexData _416 = { mul(float4(position, 1.0f), model).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, float4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * _136_fa_uv_scale.xy, color, position };\n    return _416;\n}\n\nvoid fa_prepass_vertex(float4x4 model, float3 position, float3 normal, float4 tangent, float2 texcoord0, float4 color)\n{\n    float4x4 param = model;\n    float3 param_1 = position;\n    float3 param_2 = normal;\n    float4 param_3 = tangent;\n    float2 param_4 = texcoord0;\n    float4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    float3 _423 = _273.world_pos;\n    float4 _284 = float4(_423, 1.0f);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -mul(_284, _136_fa_light_vp).z;\n    fa_pre_r0 = float3(_136_fa_light_vp[0].x, _136_fa_light_vp[1].x, _136_fa_light_vp[2].x);\n    fa_pre_r1 = float3(_136_fa_light_vp[0].y, _136_fa_light_vp[1].y, _136_fa_light_vp[2].y);\n    fa_pre_r2 = float3(_136_fa_light_vp[0].z, _136_fa_light_vp[1].z, _136_fa_light_vp[2].z);\n    gl_Position = mul(_284, _136_fa_view_proj);\n}\n\nvoid vert_main()\n{\n    fa_inst_begin();\n    float4 param = fa_joints;\n    float4 param_1 = fa_weights;\n    float4x4 param_2 = mul(fa_skin_matrix(param, param_1), float4x4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3));\n    float3 param_3 = fa_position;\n    float3 param_4 = fa_normal;\n    float4 param_5 = fa_tangent;\n    float2 param_6 = fa_texcoord0;\n    float4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_m0 = stage_input.fa_inst_m0;\n    fa_inst_m1 = stage_input.fa_inst_m1;\n    fa_inst_m2 = stage_input.fa_inst_m2;\n    fa_inst_m3 = stage_input.fa_inst_m3;\n    fa_joints = stage_input.fa_joints;\n    fa_weights = stage_input.fa_weights;\n    fa_position = stage_input.fa_position;\n    fa_normal = stage_input.fa_normal;\n    fa_tangent = stage_input.fa_tangent;\n    fa_texcoord0 = stage_input.fa_texcoord0;\n    fa_color = stage_input.fa_color;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_world_pos = fa_world_pos;\n    stage_output.fa_world_normal = fa_world_normal;\n    stage_output.fa_world_tangent = fa_world_tangent;\n    stage_output.fa_uv = fa_uv;\n    stage_output.fa_vertex_color = fa_vertex_color;\n    stage_output.fa_pre_depth = fa_pre_depth;\n    stage_output.fa_pre_r0 = fa_pre_r0;\n    stage_output.fa_pre_r1 = fa_pre_r1;\n    stage_output.fa_pre_r2 = fa_pre_r2;\n    return stage_output;\n}\n",
      "fs": "struct SurfaceInput\n{\n    float3 world_pos;\n    float3 world_normal;\n    float4 world_tangent;\n    float2 uv;\n    float4 vertex_color;\n    float3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    float3 albedo;\n    float alpha;\n    float3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    float3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    float3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    float3 specular_color;\n    float transmission;\n    float thickness;\n    float3 attenuation_color;\n    float attenuation_distance;\n};\n\ncbuffer fa_mesh_fs_params : register(b1)\n{\n    float4 _215_fa_camera_pos : packoffset(c0);\n    float4 _215_fa_ambient : packoffset(c1);\n    float4 _215_fa_base_color : packoffset(c2);\n    float4 _215_fa_emissive : packoffset(c3);\n    float4 _215_fa_model_emissive : packoffset(c4);\n    float4 _215_fa_pbr : packoffset(c5);\n    float4 _215_fa_maps : packoffset(c6);\n    float4 _215_fa_fog : packoffset(c7);\n    float4 _215_fa_fog_b : packoffset(c8);\n    float4 _215_fa_fog_c : packoffset(c9);\n    float4 _215_fa_counts : packoffset(c10);\n    float4 _215_fa_env_sky : packoffset(c11);\n    float4 _215_fa_env_horizon : packoffset(c12);\n    float4 _215_fa_time : packoffset(c13);\n    float4 _215_fa_cl_vpx : packoffset(c14);\n    float4 _215_fa_cl_vpy : packoffset(c15);\n    float4 _215_fa_cl_vpw : packoffset(c16);\n    float4 _215_fa_cl_fwd : packoffset(c17);\n    float4 _215_fa_cl_grid : packoffset(c18);\n    float4 _215_fa_cl_info : packoffset(c19);\n    float4 _215_fa_layers_a : packoffset(c20);\n    float4 _215_fa_layers_b : packoffset(c21);\n    float4 _215_fa_layers_c : packoffset(c22);\n    float4 _215_fa_layers_d : packoffset(c23);\n    float4 _215_fa_ct_a : packoffset(c24);\n    float4 _215_fa_ct_b : packoffset(c25);\n    float4 _215_fa_ct_vpx : packoffset(c26);\n    float4 _215_fa_ct_vpy : packoffset(c27);\n    float4 _215_fa_ct_vpw : packoffset(c28);\n    float4 _215_fa_ct_fwd : packoffset(c29);\n    float4 _215_fa_tr_a : packoffset(c30);\n    float4 _215_fa_tr_b : packoffset(c31);\n    float4 _215_fa_probe_sh[9] : packoffset(c32);\n};\n\nTexture2D<float4> fa_tex : register(t0);\nSamplerState fa_smp : register(s0);\nTexture2D<float4> fa_normal_tex : register(t1);\nTexture2D<float4> fa_mr_tex : register(t2);\nTexture2D<float4> fa_occlusion_tex : register(t3);\nTexture2D<float4> fa_emissive_tex : register(t4);\n\nstatic bool gl_FrontFacing;\nstatic float3 fa_world_pos;\nstatic float3 fa_world_normal;\nstatic float4 fa_world_tangent;\nstatic float2 fa_uv;\nstatic float4 fa_vertex_color;\nstatic float3 fa_pre_r0;\nstatic float3 fa_pre_r1;\nstatic float3 fa_pre_r2;\nstatic float4 fa_frag_color;\nstatic float fa_pre_depth;\n\nstruct SPIRV_Cross_Input\n{\n    float3 fa_world_pos : TEXCOORD0;\n    float3 fa_world_normal : TEXCOORD1;\n    float4 fa_world_tangent : TEXCOORD2;\n    float2 fa_uv : TEXCOORD3;\n    float4 fa_vertex_color : TEXCOORD4;\n    float fa_pre_depth : TEXCOORD5;\n    float3 fa_pre_r0 : TEXCOORD6;\n    float3 fa_pre_r1 : TEXCOORD7;\n    float3 fa_pre_r2 : TEXCOORD8;\n    bool gl_FrontFacing : SV_IsFrontFace;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 fa_frag_color : SV_Target0;\n};\n\nfloat mod(float x, float y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat2 mod(float2 x, float2 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat3 mod(float3 x, float3 y)\n{\n    return x - y * floor(x / y);\n}\n\nfloat4 mod(float4 x, float4 y)\n{\n    return x - y * floor(x / y);\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625f), 4.0f);\n}\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nfloat3 fa_tangent_normal(SurfaceInput i, float3 m)\n{\n    float3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    float3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    float3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    float3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    float4 base_t = fa_tex.Sample(fa_smp, i.uv);\n    float param = _215_fa_maps.w;\n    float param_1 = 1.0f;\n    float3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    float3 _227 = fa_tex_fix(param_2, param_3);\n    float4 _833 = base_t;\n    _833.x = _227.x;\n    _833.y = _227.y;\n    _833.z = _227.z;\n    base_t = _833;\n    float4 _243 = (_833 * _215_fa_base_color) * i.vertex_color;\n    float3 _788 = i.world_normal;\n    if (_215_fa_maps.z > 0.5f)\n    {\n        float param_4 = _215_fa_maps.w;\n        float param_5 = 16.0f;\n        float3 param_6 = fa_normal_tex.Sample(fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        float3 _277 = fa_tex_fix(param_6, param_7);\n        float3 _281 = (_277 * 2.0f) - 1.0f.xxx;\n        float2 _286 = _281.xy * _215_fa_maps.x;\n        float3 _841 = _281;\n        _841.x = _286.x;\n        _841.y = _286.y;\n        SurfaceInput param_8 = i;\n        float3 param_9 = _841;\n        _788 = fa_tangent_normal(param_8, param_9);\n    }\n    float4 mrt = fa_mr_tex.Sample(fa_smp, i.uv);\n    float param_10 = _215_fa_maps.w;\n    float param_11 = 64.0f;\n    float3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    float3 _315 = fa_tex_fix(param_12, param_13);\n    float4 _844 = mrt;\n    _844.x = _315.x;\n    _844.y = _315.y;\n    _844.z = _315.z;\n    mrt = _844;\n    float4 _345 = fa_occlusion_tex.Sample(fa_smp, i.uv);\n    float param_14 = _215_fa_maps.w;\n    float param_15 = 256.0f;\n    float3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    float3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = _215_fa_maps.w;\n    float param_19 = 4.0f;\n    float3 param_20 = fa_emissive_tex.Sample(fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    float3 _387 = fa_tex_fix(param_20, param_21);\n    float _793 = _215_fa_layers_a.x;\n    float _794 = _215_fa_layers_a.y;\n    float _797 = _215_fa_layers_a.z;\n    float _796 = _215_fa_layers_b.w;\n    float _799 = _215_fa_layers_c.x;\n    if (_215_fa_layers_c.z > 0.5f)\n    {\n        if (mod(_215_fa_layers_c.z, 2.0f) > 0.5f)\n        {\n            _793 *= _357.y;\n            _794 *= _357.z;\n            _796 *= _345.w;\n        }\n        if (_215_fa_layers_c.z > 1.5f)\n        {\n            _797 *= mrt.x;\n            _799 *= mrt.w;\n        }\n    }\n    Surface _826 = { _243.xyz, _243.w, _788, clamp(_215_fa_pbr.x * _315.z, 0.0f, 1.0f), clamp(_215_fa_pbr.y * _315.y, 0.0500000007450580596923828125f, 1.0f), 1.0f + (_215_fa_maps.y * (_357.x - 1.0f)), _215_fa_emissive.xyz + (_215_fa_model_emissive.xyz * _387), _793, _794, _215_fa_layers_b.xyz, _796, _797, _215_fa_layers_a.w, _799, _215_fa_layers_c.y, _215_fa_layers_d.xyz, _215_fa_tr_a.x, _215_fa_tr_a.y, _215_fa_tr_b.xyz, _215_fa_tr_a.z };\n    return _826;\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid frag_main()\n{\n    fa_inst_load();\n    float3 _683 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _683 = -_683;\n    }\n    float3 _540 = normalize(_215_fa_camera_pos.xyz - fa_world_pos);\n    SurfaceInput _696 = { fa_world_pos, _683, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing };\n    SurfaceInput param = _696;\n    SurfaceInput _704 = { fa_world_pos, _683, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing };\n    SurfaceInput param_1 = _704;\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    float3 _555 = normalize(param_2.normal);\n    float3 _570 = normalize(float3(dot(fa_pre_r0, _555), dot(fa_pre_r1, _555), dot(fa_pre_r2, _555)));\n    float _582 = _570.z;\n    float2 e = _570.xy / ((abs(_570.x) + abs(_570.y)) + abs(_582)).xx;\n    if (_582 < 0.0f)\n    {\n        e = (1.0f.xx - abs(e.yx)) * float2((e.x >= 0.0f) ? 1.0f : (-1.0f), (e.y >= 0.0f) ? 1.0f : (-1.0f));\n    }\n    fa_frag_color = float4(min(fa_pre_depth, 60000.0f), e, 1.0f);\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FrontFacing = stage_input.gl_FrontFacing;\n    fa_world_pos = stage_input.fa_world_pos;\n    fa_world_normal = stage_input.fa_world_normal;\n    fa_world_tangent = stage_input.fa_world_tangent;\n    fa_uv = stage_input.fa_uv;\n    fa_vertex_color = stage_input.fa_vertex_color;\n    fa_pre_r0 = stage_input.fa_pre_r0;\n    fa_pre_r1 = stage_input.fa_pre_r1;\n    fa_pre_r2 = stage_input.fa_pre_r2;\n    fa_pre_depth = stage_input.fa_pre_depth;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.fa_frag_color = fa_frag_color;\n    return stage_output;\n}\n",
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
            "size": 656,
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
